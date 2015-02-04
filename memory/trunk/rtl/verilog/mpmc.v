`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//
// ============================================================================
//
module mpmc(
rst_i, clk200MHz, fpga_temp,
mem_ui_clk,
cyc0, stb0, ack0, adr0, dato0,
cyc1, stb1, ack1, we1, sel1, adr1, dati1, dato1,
cyc2, stb2, ack2, we2, sel2, adr2, dati2, dato2,
cyc3, stb3, ack3, we3, sel3, adr3, dati3, dato3,
cyc4, stb4, ack4, we4, adr4, dati4, dato4,
cyc5, stb5, ack5, adr5, dato5,
ddr2_dq, ddr2_dqs_n, ddr2_dqs_p,
ddr2_addr, ddr2_ba, ddr2_ras_n, ddr2_cas_n, ddr2_we_n,
ddr2_ck_p, ddr2_ck_n, ddr2_cke, ddr2_cs_n, ddr2_dm, ddr2_odt
);
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter CMD_READ = 3'b001;
parameter CMD_WRITE = 3'b000;

parameter IDLE = 3'd1;
parameter PRESET = 3'd2;
parameter SEND_DATA = 3'd3;
parameter SET_CMD_RD = 3'd4;
parameter SET_CMD_WR = 3'd5;
parameter WAIT_NACK = 3'd6;
parameter WAIT_RD = 3'd7;

input rst_i;
input clk200MHz;
input [11:0] fpga_temp;
output mem_ui_clk;

// Channel 0 is reserved for bitmapped graphics display, which is read-only
//
input cyc0;
input stb0;
output ack0;
input [31:0] adr0;
output reg [31:0] dato0;

// Channel 1 is reserved for the cpu
input cyc1;
input stb1;
output ack1;
input we1;
input [3:0] sel1;
input [31:0] adr1;
input [31:0] dati1;
output [31:0] dato1;

// Channel 2 is reserved for the ethernet controller
input cyc2;
input stb2;
output ack2;
input we2;
input [3:0] sel2;
input [31:0] adr2;
input [31:0] dati2;
output [31:0] dato2;

// Channel 3 is reserved for the graphics controller
input cyc3;
input stb3;
output ack3;
input we3;
input [31:0] adr3;
input [15:0] dati3;
output [15:0] dato3;

// Channel 4 is reserved for the audio DMA
input cyc4;
input stb4;
output ack4;
input we4;
input [31:0] adr4;
input [15:0] dati4;
output [15:0] dato4;

// Channel 5 is reserved for sprite DMA, which is read-only
input cyc5;
input stb5;
output ack5;
input [31:0] adr5;
output reg [31:0] dato5;

inout [15:0] ddr2_dq;
inout [1:0] ddr2_dqs_p;
inout [1:0] ddr2_dqs_n;
output [12:0] ddr2_addr;
output [2:0] ddr2_ba;
output ddr2_ras_n;
output ddr2_cas_n;
output ddr2_we_n;
output ddr2_ck_p;
output ddr2_ck_n;
output ddr2_cke;
output ddr2_cs_n;
output [1:0] ddr2_dm;
output ddr2_odt;

reg [3:0] sel;
reg [31:0] adr;
reg [31:0] dato;

reg [2:0] state;
reg [2:0] ch;
reg do_wr;
reg [1:0] sreg;
reg rstn;
reg fast_read0, fast_read1, fast_read2, fast_read3, fast_read4, fast_read5;

wire cs0 = cyc0 && stb0 && adr0[31:27]==5'h0;
wire cs1 = cyc1 && stb1 && adr1[31:27]==5'h0;
wire cs2 = cyc2 && stb2 && adr2[31:27]==5'h0;
wire cs3 = cyc3 && stb3 && adr3[31:27]==5'h0;
wire cs4 = cyc4 && stb4 && adr4[31:27]==5'h0;
wire cs5 = cyc5 && stb5 && adr5[31:27]==5'h0;
wire cs_any = cs0|cs1|cs2|cs3|cs4|cs5;

reg acki0,acki1,acki2,acki3,acki4,acki5;

// Terminate the ack signal as soon as the circuit select goes away.
assign ack0 = acki0 & cs0;
assign ack1 = acki1 & cs1;
assign ack2 = acki2 & cs2;
assign ack3 = acki3 & cs3;
assign ack4 = acki4 & cs4;
assign ack5 = acki5 & cs5;

// Record of the last read address for each channel.
// Cache address tag
reg [31:0] ch0_addr;
reg [31:0] ch1_addr;
reg [31:0] ch2_addr;
reg [31:0] ch3_addr;
reg [31:0] ch4_addr;
reg [31:0] ch5_addr;

// Read data caches
reg [127:0] ch0_rd_data;
reg [127:0] ch1_rd_data;
reg [127:0] ch2_rd_data;
reg [127:0] ch3_rd_data;
reg [127:0] ch4_rd_data;
reg [127:0] ch5_rd_data;

reg [26:0] mem_addr;
wire [2:0] mem_cmd;
wire mem_en;
reg [127:0] mem_wdf_data;
reg [15:0] mem_wdf_mask;
wire mem_wdf_end;
wire mem_wdf_wren;

wire [127:0] mem_rd_data;
wire mem_rd_data_end;
wire mem_rd_data_valid;
wire mem_rdy;
wire mem_wdf_rdy;
wire mem_ui_clk;
wire mem_ui_rst;
wire calib_complete;

//------------------------------------------------------------------------
// Component Declarations
//------------------------------------------------------------------------

ddr u_ddr
(
   // Inouts
   .ddr2_dq(ddr2_dq),
   .ddr2_dqs_p(ddr2_dqs_p),
   .ddr2_dqs_n(ddr2_dqs_n),
   // Outputs
   .ddr2_addr(ddr2_addr),
   .ddr2_ba(ddr2_ba),
   .ddr2_ras_n(ddr2_ras_n),
   .ddr2_cas_n(ddr2_cas_n),
   .ddr2_we_n(ddr2_we_n),
   .ddr2_ck_p(ddr2_ck_p),
   .ddr2_ck_n(ddr2_ck_n),
   .ddr2_cke(ddr2_cke),
   .ddr2_cs_n(ddr2_cs_n),
   .ddr2_dm(ddr2_dm),
   .ddr2_odt(ddr2_odt),
   // Inputs
   .sys_clk_i(clk200MHz),
   .sys_rst(rstn),
   // user interface signals
   .app_addr(mem_addr),
   .app_cmd(mem_cmd),
   .app_en(mem_en),
   .app_wdf_data(mem_wdf_data),
   .app_wdf_end(mem_wdf_end),
   .app_wdf_mask(mem_wdf_mask),
   .app_wdf_wren(mem_wdf_wren),
   .app_rd_data(mem_rd_data),
   .app_rd_data_end(mem_rd_data_end),
   .app_rd_data_valid(mem_rd_data_valid),
   .app_rdy(mem_rdy),
   .app_wdf_rdy(mem_wdf_rdy),
   .app_sr_req(1'b0),
   .app_sr_active(),
   .app_ref_req(1'b0),
   .app_ref_ack(),
   .app_zq_req(1'b0),
   .app_zq_ack(),
   .ui_clk(mem_ui_clk),
   .ui_clk_sync_rst(mem_ui_rst),
   .device_temp_i(fpga_temp),
   .init_calib_complete(calib_complete)
);


always @(posedge clk200MHz)
begin
	sreg <= {sreg[0],rst_i};
	rstn <= ~sreg[1];
end

reg [2:0] state;
always @(posedge mem_ui_clk)
if (mem_ui_rst) begin
	state <= IDLE;
	ch0_addr <= 32'hFFFFFFFF;
	ch1_addr <= 32'hFFFFFFFF;
	ch2_addr <= 32'hFFFFFFFF;
	ch3_addr <= 32'hFFFFFFFF;
	ch4_addr <= 32'hFFFFFFFF;
	ch5_addr <= 32'hFFFFFFFF;
end
else begin
	fast_read0 = FALSE;
	fast_read1 = FALSE;
	fast_read2 = FALSE;
	fast_read3 = FALSE;
	fast_read4 = FALSE;
	fast_read5 = FALSE;
	// Fast read channels
	// All these read channels allow data to be read in parallel with another
	// access.
	// Read the data from the channel read buffer rather than issuing a memory
	// request.
	if (!we0 && cs0 && adr0[31:4]==ch0_addr[31:4]) begin
		case(adr0[3:2])
		2'd0:	dato0 <= ch0_rd_data[31:0];
		2'd1:	dato0 <= ch0_rd_data[63:32];
		2'd2:	dato0 <= ch0_rd_data[95:64];
		2'd3:	dato0 <= ch0_rd_data[127:96];
		endcase
		acki0 <= TRUE;
		fast_read0 = TRUE;
	end
	if (!we1 && cs1 && adr1[31:4]==ch1_addr[31:4]) begin
		case(adr1[3:2])
		2'd0:	dato1 <= ch1_rd_data[31:0];
		2'd1:	dato1 <= ch1_rd_data[63:32];
		2'd2:	dato1 <= ch1_rd_data[95:64];
		2'd3:	dato1 <= ch1_rd_data[127:96];
		endcase
		acki1 <= TRUE;
		fast_read1 = TRUE;
	end
	if (!we2 && cs2 && adr2[31:4]==ch2_addr[31:4]) begin
		case(adr2[3:2])
		2'd0:	dato2 <= ch2_rd_data[31:0];
		2'd1:	dato2 <= ch2_rd_data[63:32];
		2'd2:	dato2 <= ch2_rd_data[95:64];
		2'd3:	dato2 <= ch2_rd_data[127:96];
		endcase
		acki2 <= TRUE;
		fast_read2 = TRUE;
	end
	if (!we3 && cs3 && adr3[31:4]==ch3_addr[31:4]) begin
		case(adr3[3:1])
		3'd0:	dato3 <= ch3_rd_data[15:0];
		3'd1:	dato3 <= ch3_rd_data[31:16];
		3'd2:	dato3 <= ch3_rd_data[47:32];
		3'd3:	dato3 <= ch3_rd_data[63:48];
		3'd4:	dato3 <= ch3_rd_data[79:64];
		3'd5:	dato3 <= ch3_rd_data[95:80];
		3'd6:	dato3 <= ch3_rd_data[111:96];
		3'd7:	dato3 <= ch3_rd_data[127:112];
		endcase
		acki3 <= TRUE;
		fast_read3 = TRUE;
	end
	if (!we4 && cs4 && adr4[31:4]==ch4_addr[31:4]) begin
		case(adr4[3:1])
		3'd0:	dato4 <= ch4_rd_data[15:0];
		3'd1:	dato4 <= ch4_rd_data[31:16];
		3'd2:	dato4 <= ch4_rd_data[47:32];
		3'd3:	dato4 <= ch4_rd_data[63:48];
		3'd4:	dato4 <= ch4_rd_data[79:64];
		3'd5:	dato4 <= ch4_rd_data[95:80];
		3'd6:	dato4 <= ch4_rd_data[111:96];
		3'd7:	dato4 <= ch4_rd_data[127:112];
		endcase
		acki4 <= TRUE;
		fast_read4 = TRUE;
	end
	if (!we5 && cs5 && adr5[31:4]==ch5_addr[31:4]) begin
		case(adr5[3:2])
		2'd0:	dato5 <= ch5_rd_data[31:0];
		2'd1:	dato5 <= ch5_rd_data[63:32];
		2'd2:	dato5 <= ch5_rd_data[95:64];
		2'd3:	dato5 <= ch5_rd_data[127:96];
		endcase
		acki5 <= TRUE;
		fast_read5 = TRUE;
	end
	// Clear fast read ack's when deselected
	if (~cs0)
		acki0 <= FALSE;
	if (~cs1)
		acki1 <= FALSE;
	if (~cs2)
		acki2 <= FALSE;
	if (~cs3)
		acki3 <= FALSE;
	if (~cs4)
		acki4 <= FALSE;
	if (~cs5)
		acki5 <= FALSE;

case(state)
IDLE:
	if (calib_complete) begin
		do_wr <= FALSE;
		// Write cycles take priority over read cycles.
		if (cs1 & we1) begin
			// If the write address overlaps with cached read data,
			// invalidate the corresponding read cache.
			if (ch0_addr[31:4]==adr1[31:4])
				ch0_addr <= 32'hFFFFFFFF;
			if (ch1_addr[31:4]==adr1[31:4])
				ch1_addr <= 32'hFFFFFFFF;
			if (ch2_addr[31:4]==adr1[31:4])
				ch2_addr <= 32'hFFFFFFFF;
			if (ch3_addr[31:4]==adr1[31:4])
				ch3_addr <= 32'hFFFFFFFF;
			if (ch4_addr[31:4]==adr1[31:4])
				ch4_addr <= 32'hFFFFFFFF;
			if (ch5_addr[31:4]==adr1[31:4])
				ch5_addr <= 32'hFFFFFFFF;
			ch <= 3'd1;
			sel <= sel1;
			adr <= adr1;
			dati <= dati1;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs2 & we2) begin
			if (ch0_addr[31:4]==adr2[31:4])
				ch0_addr <= 32'hFFFFFFFF;
			if (ch1_addr[31:4]==adr2[31:4])
				ch1_addr <= 32'hFFFFFFFF;
			if (ch2_addr[31:4]==adr2[31:4])
				ch2_addr <= 32'hFFFFFFFF;
			if (ch3_addr[31:4]==adr2[31:4])
				ch3_addr <= 32'hFFFFFFFF;
			if (ch4_addr[31:4]==adr2[31:4])
				ch4_addr <= 32'hFFFFFFFF;
			if (ch5_addr[31:4]==adr2[31:4])
				ch5_addr <= 32'hFFFFFFFF;
			ch <= 3'd2;
			sel <= sel2;
			adr <= adr2;
			dati <= dati2;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs3 & we3) begin
			if (ch0_addr[31:4]==adr3[31:4])
				ch0_addr <= 32'hFFFFFFFF;
			if (ch1_addr[31:4]==adr3[31:4])
				ch1_addr <= 32'hFFFFFFFF;
			if (ch2_addr[31:4]==adr3[31:4])
				ch2_addr <= 32'hFFFFFFFF;
			if (ch3_addr[31:4]==adr3[31:4])
				ch3_addr <= 32'hFFFFFFFF;
			if (ch4_addr[31:4]==adr3[31:4])
				ch4_addr <= 32'hFFFFFFFF;
			if (ch5_addr[31:4]==adr3[31:4])
				ch5_addr <= 32'hFFFFFFFF;
			ch <= 3'd3;
			sel <= sel3;
			adr <= adr3;
			dati <= dati3;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs4 & we4) begin
			if (ch0_addr[31:4]==adr4[31:4])
				ch0_addr <= 32'hFFFFFFFF;
			if (ch1_addr[31:4]==adr4[31:4])
				ch1_addr <= 32'hFFFFFFFF;
			if (ch2_addr[31:4]==adr4[31:4])
				ch2_addr <= 32'hFFFFFFFF;
			if (ch3_addr[31:4]==adr4[31:4])
				ch3_addr <= 32'hFFFFFFFF;
			if (ch4_addr[31:4]==adr4[31:4])
				ch4_addr <= 32'hFFFFFFFF;
			if (ch5_addr[31:4]==adr4[31:4])
				ch5_addr <= 32'hFFFFFFFF;
			ch <= 3'd4;
			sel <= sel4;
			adr <= adr4;
			dati <= dati4;
			do_wr <= TRUE;
			state <= PRESET;
		end
		// Reads
		else if (cs0 & ~fast_read0) begin
			ch <= 3'd0;
			adr <= adr0;
			state <= PRESET;
		end
		else if (cs1 & ~fast_read1) begin
			ch <= 3'd1;
			adr <= adr1;
			state <= PRESET;
		end
		else if (cs2 & ~fast_read2) begin
			ch <= 3'd2;
			adr <= adr2;
			state <= PRESET;
		end
		else if (cs3 & ~fast_read3) begin
			ch <= 3'd3;
			adr <= adr3;
			state <= PRESET;
		end
		else if (cs4 & ~fast_read4) begin
			ch <= 3'd4;
			adr <= adr4;
			state <= PRESET;
		end
		else if (cs5 & ~fast_read5) begin
			ch <= 3'd5;
			adr <= adr5;
			state <= PRESET;
		end
	end
PRESET:
	begin
		mem_adr <= {adr[26:4],4'h0};		// common for all channels
		case(ch)
		3'd0,3'd5:
				begin
				mem_wdf_mask <= 16'hFFFF;	// ch0,5 are read-only
				mem_wdf_data <= {128{1'b1}};
				end
		3'd1,3'd2:
				begin
				case(adr[3:2])
				2'd0:	mem_wdf_mask <= {12'hFFF,~sel[3:0]};
				2'd1:	mem_wdf_mask <= {8'hFF,~sel[3:0],4'hF};
				2'd2:	mem_wdf_mask <= {4'hF,~sel[3:0],8'hFF};
				2'd3:	mem_wdf_mask <= {~sel[3:0],12'hFFF};
				endcase
				mem_wdf_data <= {4{dati}};
				end
		3'd3,3'd4:
				begin
				case(adr[3:1])
				3'd0:	mem_wdf_mask <= {14'h3FFF,~sel[1:0]};
				3'd1:	mem_wdf_mask <= {12'hFFF,~sel[1:0],2'b11};
				3'd2:	mem_wdf_mask <= {10'h3FF,~sel[1:0],4'hF};
				3'd3:	mem_wdf_mask <= {8'hFF,~sel[1:0],6'h3F};
				3'd4:	mem_wdf_mask <= {6'h3F,~sel[1:0],8'hFF};
				3'd5:	mem_wdf_mask <= {4'hF,~sel[1:0],10'h3FF};
				3'd6:	mem_wdf_mask <= {2'h3,~sel[1:0],12'hFFF};
				3'd7:	mem_wdf_mask <= {~sel[1:0],14'h3FFF};
				endcase
				mem_wdf_data <= {8{dati[15:0]}};
				end
		endcase
		if (do_wr)
			state <= SEND_DATA;
		else
			state <= SET_CMD_RD;
	end
SEND_DATA:
	if (mem_wdf_rdy == TRUE)
		state <= SET_CMD_WR;
SET_CMD_RD:
	if (mem_rdy == TRUE)
		state <= WAIT_RD;

SET_CMD_WR:
	if (mem_rdy == TRUE) begin
		case(ch)
		3'd0:	acki0 <= TRUE;
		3'd1:	acki1 <= TRUE;
		3'd2:	acki2 <= TRUE;
		3'd3:	acki3 <= TRUE;
		3'd4:	acki4 <= TRUE;
		3'd5:	acki5 <= TRUE;
		endcase
		state <= WAIT_NACK;
	end
WAIT_NACK:
	begin
		case(ch)
		3'd0:	if (!cs0) begin acki0 <= FALSE; state <= IDLE; end
		3'd1:	if (!cs1) begin acki1 <= FALSE; state <= IDLE; end
		3'd2:	if (!cs2) begin acki2 <= FALSE; state <= IDLE; end
		3'd3:	if (!cs3) begin acki3 <= FALSE; state <= IDLE; end
		3'd4:	if (!cs4) begin acki4 <= FALSE; state <= IDLE; end
		3'd5:	if (!cs5) begin acki5 <= FALSE; state <= IDLE; end
		endcase
	end

WAIT_RD:
	begin
		if (mem_rd_data_valid & mem_rd_data_end) begin
			state <= IDLE;
			case(ch)
			3'd0:
				begin
				ch0_addr <= adr0;
				ch0_rd_data <= mem_rd_data;
				end
			3'd1:
				begin
				ch1_addr <= adr1;
				ch1_rd_data <= mem_rd_data;
				end
			3'd2:
				begin
				ch2_addr <= adr2;
				ch2_rd_data <= mem_rd_data;
				end
			3'd3:
				begin
				ch3_addr <= adr3;
				ch3_rd_data <= mem_rd_data;
				end
			3'd4:
				begin
				ch4_addr <= adr4;
				ch4_rd_data <= mem_rd_data;
				end
			3'd5:
				begin
				ch5_addr <= adr5;
				ch5_rd_data <= mem_rd_data;
				end
			endcase
		end
	end
endcase
end

assign mem_wdf_wren = state==SEND_DATA;
assign mem_wdf_end = state==SEND_DATA;
assign mem_en = state==SET_CMD_RD || state==SET_CMD_WR;
assign mem_cmd = state==SET_CMD_WR ? CMD_WRITE : state==SET_CMD_RD ? CMD_READ : 3'd1;

