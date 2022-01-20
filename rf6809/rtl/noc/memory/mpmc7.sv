`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================
//
//`define RED_SCREEN	1'b1
`define CROSS0

module mpmc7(
rst_i, clk100MHz,
clk0, cyc0, stb0, ack0, we0, sel0, adr0, dati0, dato0,
clk1, cs1, cyc1, stb1, ack1, we1, sel1, adr1, dati1, dato1, sr1, cr1, rb1,
clk2, cyc2, stb2, ack2, we2, sel2, adr2, dati2, dato2,
clk3, cyc3, stb3, ack3, we3, sel3, adr3, dati3, dato3,
clk4, cyc4, stb4, ack4, we4, sel4, adr4, dati4, dato4,
clk5, cyc5, stb5, ack5, sel5, adr5, dato5, spriteno,
clk6, cyc6, stb6, ack6, we6, sel6, adr6, dati6, dato6,
clk7, cs7, cyc7, stb7, ack7, we7, sel7, adr7, dati7, dato7, sr7, cr7, rb7,
mem_ui_rst, mem_ui_clk, calib_complete,
rstn, mem_addr, mem_cmd, mem_en, mem_wdf_data, mem_wdf_end, mem_wdf_mask, mem_wdf_wren,
mem_rd_data, mem_rd_data_valid, mem_rd_data_end, mem_rdy, mem_wdf_rdy,
ch, state
);
parameter RMW = 0;
parameter NAR = 2;
parameter AMSB = 28;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter CMD_READ = 3'b001;
parameter CMD_WRITE = 3'b000;
// State machine states
parameter IDLE = 4'd0;
parameter PRESET1 = 4'd1;
parameter PRESET2 = 4'd2;
parameter SEND_DATA = 4'd3;
parameter SET_CMD_RD = 4'd4;
parameter SET_CMD_WR = 4'd5;
parameter WAIT_NACK = 4'd6;
parameter WAIT_RD = 4'd7;
parameter WRITE_TRAMP = 4'd8;	// write trampoline
parameter WRITE_TRAMP1 = 4'd9;

input rst_i;
input clk100MHz;

// Channel 0 is reserved for bitmapped graphics display.
//
parameter C0W = 128;	// Channel zero width
input clk0;
input cyc0;
input stb0;
output ack0;
input [C0W/8-1:0] sel0;
input we0;
input [31:0] adr0;
input [C0W-1:0] dati0;
output reg [C0W-1:0] dato0;
reg [C0W-1:0] dato0n;

// Channel 1 is reserved for cpu1
parameter C1W = 128;
input clk1;
input cs1;
input cyc1;
input stb1;
output ack1;
input we1;
input [C1W/8-1:0] sel1;
input [31:0] adr1;
input [C1W-1:0] dati1;
output reg [C1W-1:0] dato1;
input sr1;
input cr1;
output reg rb1;

// Channel 2 is reserved for the ethernet controller
parameter C2W = 32;
input clk2;
input cyc2;
input stb2;
output ack2;
input we2;
input [C2W/8-1:0] sel2;
input [31:0] adr2;
input [C2W-1:0] dati2;
output reg [C2W-1:0] dato2;

// Channel 3 is reserved for the audio controller
parameter C3W = 16;
input clk3;
input cyc3;
input stb3;
output ack3;
input we3;
input [C3W/8-1:0] sel3;
input [31:0] adr3;
input [C3W-1:0] dati3;
output reg [C3W-1:0] dato3;

// Channel 4 is reserved for the graphics controller
parameter C4W = 128;
input clk4;
input cyc4;
input stb4;
output ack4;
input we4;
input [C4W/8-1:0] sel4;
input [31:0] adr4;
input [C4W-1:0] dati4;
output reg [C4W-1:0] dato4;

// Channel 5 is reserved for sprite DMA, which is read-only
parameter C5W = 64;
input clk5;
input cyc5;
input stb5;
output ack5;
input [C5W/8-1:0] sel5;
input [5:0] spriteno;
input [31:0] adr5;
output reg [C5W-1:0] dato5;

// Channel 6 is reserved for the SD/MMC controller
parameter C6W = 128;
input clk6;
input cyc6;
input stb6;
output ack6;
input we6;
input [C6W/8-1:0] sel6;
input [31:0] adr6;
input [C6W-1:0] dati6;
output reg [C6W-1:0] dato6;

// Channel 7 is reserved for the cpu
parameter C7W = 16;
parameter C7R = 16;
input clk7;
input cs7;
input cyc7;
input stb7;
output ack7;
input we7;
input [C7W/8-1:0] sel7;
input [31:0] adr7;
input [C7W-1:0] dati7;
output reg [C7R-1:0] dato7;
input sr7;
input cr7;
output reg rb7;

// MIG interface signals
input mem_ui_rst;
input mem_ui_clk;
input calib_complete;
output rstn;
output [AMSB:0] mem_addr;
output reg [2:0] mem_cmd;
output reg mem_en;
output reg [127:0] mem_wdf_data;
output reg [15:0] mem_wdf_mask;
output reg mem_wdf_end;
output reg mem_wdf_wren;
input [127:0] mem_rd_data;
input mem_rd_data_valid;
input mem_rd_data_end;
input mem_rdy;
input mem_wdf_rdy;

// Debugging
output reg [3:0] ch;
output reg [3:0] state;
reg [3:0] next_state;

integer n;
integer n1;

reg [31:0] adr;
reg [127:0] dat128;
reg [15:0] wmask;
reg [127:0] rmw_data;

reg [3:0] nch;
reg do_wr;
reg [1:0] sreg;
reg rstn;
reg fast_read0, fast_read1, fast_read2, fast_read3;
reg fast_read4, fast_read5, fast_read6, fast_read7;
reg read0,read1,read2,read3;
reg read4,read5,read6,read7;
reg elevate = 1'b0;
reg [5:0] elevate_cnt = 6'h00;
reg [5:0] nack_to = 6'd0;
reg [5:0] spriteno_r;

wire cs0 = cyc0 && stb0 && adr0[31:29]==3'h0;
wire ics1 = cyc1 & stb1 & cs1;
wire cs2 = cyc2 && stb2 && adr2[31:29]==3'h0;
wire cs3 = cyc3 && stb3 && adr3[31:29]==3'h0;
wire cs4 = cyc4 && stb4 && adr4[31:29]==3'h0;
wire cs5 = cyc5 && stb5 && adr5[31:29]==3'h0;
wire cs6 = cyc6 && stb6 && adr6[31:29]==3'h0;
wire ics7 = cyc7 & stb7 & cs7;

reg acki0,acki1,acki2,acki3,acki4,acki5,acki6,acki7;

// Record of the last read address for each channel.
// Cache address tag
reg [31:0] ch0_tag;
reg [31:0] ch1_tag;
reg [31:0] ch2_tag;
reg [31:0] ch3_tag;
reg [31:0] ch4_tag;
reg [31:0] ch5_tag [0:63];	// separate address for each sprite
reg [31:0] ch6_tag;
reg [31:0] ch7_tag;

// Read data caches
reg [127:0] ch0_rd_data [0:7];
reg [127:0] ch1_rd_data;
reg [127:0] ch2_rd_data;
reg [127:0] ch3_rd_data;
reg [127:0] ch4_rd_data;
reg [127:0] ch5_rd_data [0:255];
reg [127:0] ch6_rd_data;
reg [127:0] ch7_rd_data;

reg [2:0] num_strips;
reg [2:0] req_strip_cnt;		// count of requested strips
reg [2:0] resp_strip_cnt;		// count of response strips
reg [AMSB:0] mem_addr;

reg [15:0] refcnt;				// refreshing not used, its automnatic
reg refreq;
wire refack;
reg [15:0] tocnt;					// memory access timeout counter

reg [3:0] resv_ch [0:NAR-1];
reg [31:0] resv_adr [0:NAR-1];

// For address reservation below
reg [7:0] match;
always @(posedge mem_ui_clk)
if (rst_i)
	match <= 8'h00;
else begin
	if (match >= NAR)
		match <= 8'h00;
	else
		match <= match + 8'd1;
end

// Cross clock domain signals
reg cs0xx;
reg we0xx;
reg [C0W/8-1:0] sel0xx;
reg [31:0] adr0xx;
reg [C0W-1:0] dati0xx;

reg cs1xx;
reg we1xx;
reg [15:0] sel1xx;
reg [31:0] adr1xx;
reg [127:0] dati1xx;
reg sr1xx;
reg cr1xx;

reg cs2xx;
reg we2xx;
reg [C2W/8-1:0] sel2xx;
reg [31:0] adr2xx;
reg [C2W-1:0] dati2xx;

reg cs3xx;
reg we3xx;
reg [C3W/8-1:0] sel3xx;
reg [31:0] adr3xx;
reg [C3W-1:0] dati3xx;

reg cs4xx;
reg we4xx;
reg [C4W/8-1:0] sel4xx;
reg [31:0] adr4xx;
reg [C4W-1:0] dati4xx;

reg cs5xx;
reg we5xx;
reg [C5W/8-1:0] sel5xx;
reg [31:0] adr5xx;
reg [C5W-1:0] dati5xx;
reg [5:0] spritenoxx;

reg cs6xx;
reg we6xx;
reg [C6W/8-1:0] sel6xx;
reg [31:0] adr6xx;
reg [C6W-1:0] dati6xx;

reg cs7xx;
reg we7xx;
reg [C7W/8-1:0] sel7xx;
reg [31:0] adr7xx;
reg [C7W-1:0] dati7xx;
reg sr7xx;
reg cr7xx;

reg [7:0] to_cnt;

// Terminate the ack signal as soon as the circuit select goes away.
assign ack0 = acki0 & cs0;
assign ack1 = acki1 & ics1;
assign ack2 = acki2 & cs2;
assign ack3 = acki3 & cs3;
assign ack4 = acki4 & cs4;
assign ack5 = acki5 & cs5;
assign ack6 = acki6 & cs6;
assign ack7 = acki7 & ics7;

// Used to transition state to IDLE at end of access
// We dont transition to idle until a negative edge is seen on ack
wire ne_acki0;
wire ne_acki1;
wire ne_acki2;
wire ne_acki3;
wire ne_acki4;
wire ne_acki5;
wire ne_acki6;
wire ne_acki7;
edge_det ed_acki0 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki0), .pe(), .ne(ne_acki0), .ee());
edge_det ed_acki1 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki1), .pe(), .ne(ne_acki1), .ee());
edge_det ed_acki2 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki2), .pe(), .ne(ne_acki2), .ee());
edge_det ed_acki3 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki3), .pe(), .ne(ne_acki3), .ee());
edge_det ed_acki4 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki4), .pe(), .ne(ne_acki4), .ee());
edge_det ed_acki5 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki5), .pe(), .ne(ne_acki5), .ee());
edge_det ed_acki6 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki6), .pe(), .ne(ne_acki6), .ee());
edge_det ed_acki7 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki7), .pe(), .ne(ne_acki7), .ee());

// Register signals onto mem_ui_clk domain
always @(posedge mem_ui_clk)
begin
	cs0xx <= cs0;
	we0xx <= we0;
	sel0xx <= sel0;
	adr0xx <= adr0;
	dati0xx <= dati0;
end

always @(posedge mem_ui_clk)
begin
	cs1xx <= ics1;
	we1xx <= we1;
	sel1xx <= sel1;
	adr1xx <= adr1;
	dati1xx <= dati1;
	sr1xx <= sr1;
	cr1xx <= cr1;
end

always @(posedge mem_ui_clk)
begin
	cs2xx <= cs2;
	we2xx <= we2;
	sel2xx <= sel2;
	adr2xx <= adr2;
	dati2xx <= dati2;
end

always @(posedge mem_ui_clk)
begin
	cs3xx <= cs3;
	we3xx <= we3;
	sel3xx <= sel3;
	adr3xx <= adr3;
	dati3xx <= dati3;
end

always @(posedge mem_ui_clk)
begin
	cs4xx <= cs4;
	we4xx <= we4;
	sel4xx <= sel4;
	adr4xx <= adr4;
	dati4xx <= dati4;
end

always @(posedge mem_ui_clk)
begin
	cs5xx <= cs5;
	sel5xx <= sel5;
	adr5xx <= adr5;
	spritenoxx <= spriteno;
end

always @(posedge mem_ui_clk)
begin
	cs6xx <= cs6;
	we6xx <= we6;
	sel6xx <= sel6;
	adr6xx <= adr6;
	dati6xx <= dati6;
end

always @(posedge mem_ui_clk)
begin
	cs7xx <= ics7;
	we7xx <= we7;
	sel7xx <= sel7;
	adr7xx <= adr7;
	dati7xx <= dati7;
	sr7xx <= sr7;
	cr7xx <= cr7;
end

always @(posedge clk100MHz)
begin
	sreg <= {sreg[0],rst_i};
	rstn <= ~sreg[1];
end

reg toggle;	// CPU1 / CPU0 priority toggle
reg toggle_sr;
reg [19:0] resv_to_cnt;
reg sr1x,sr7x;
reg [127:0] dati128;

// Detect cache hits on read caches
wire ch1_read = ics1 && !we1xx && cs1xx && (adr1xx[31:5]==ch1_tag[31:5]);
wire ch7_read = cs7xx && !we7xx && (adr7xx[31:4]==ch7_tag[31:4]);

always_comb
	fast_read0 = (cs0xx && !we0xx && adr0xx[31:7]==ch0_tag[31:7]);
always_comb
	fast_read1 = ch1_read;
always_comb
	fast_read2 = (!we2xx && cs2xx && adr2xx[31:4]==ch2_tag[31:4]);
always_comb
	fast_read3 = (!we3xx && cs3xx && adr3xx[31:4]==ch3_tag[31:4]);
always_comb
	fast_read4 = (!we4xx && cs4xx && adr4xx[31:4]==ch4_tag[31:4]);

// For the sprite channel, reading the 64-bits of a strip not beginning at
// a 64-byte aligned paragraph only checks for the 64 bit address adr[5:3].
// It's assumed that a 4x128-bit strips were read the by the previous access.
// It's also assumed that the strip address won't match because there's more
// than one sprite and sprite accesses are essentially random.
always_comb
	fast_read5 = (cs5xx && adr5xx[31:6] == ch5_tag[spriteno][31:6]);
always_comb
	fast_read6 = (!we6xx && cs6xx && adr6xx[31:4]==ch6_tag[31:4]);
always_comb
  fast_read7 = ch7_read;

always_comb
begin
	sr1x = FALSE;
    if (ch1_read)
        sr1x = sr1xx;
end
always_comb
begin
	sr7x = FALSE;
    if (ch7_read)
        sr7x = sr7xx;
end

// Select the channel
// This prioritizes the channel during the IDLE state.
// During an elevate cycle the channel priorities are reversed.
always_ff @(posedge mem_ui_clk)
begin
	if (elevate) begin
		if (cs7xx)
			nch <= 3'd7;
		else if (cs6xx)
			nch <= 3'd6;
		else if (cs5xx)
			nch <= 3'd5;
		else if (cs4xx)
			nch <= 3'd4;
		else if (cs3xx)
			nch <= 3'd3;
		else if (cs2xx)
			nch <= 3'd2;
		else if (cs1xx)
			nch <= 3'd1;
		else if (cs0xx)
			nch <= 3'd0;
		else
			nch <= 4'hF;
	end
	// Channel 0 read or write takes precedence
	else if (cs0xx & we0xx)
		nch <= 3'd0;
	else if (cs0xx & ~fast_read0)
		nch <= 3'd0;
	else if (cs1xx & we1xx)
		nch <= 3'd1;
	else if (cs2xx & we2xx)
		nch <= 3'd2;
	else if (cs3xx & we3xx)
		nch <= 3'd3;
	else if (cs4xx & we4xx)
		nch <= 3'd4;
	else if (cs6xx & we6xx)
		nch <= 3'd6;
	else if (cs7xx & we7xx)
		nch <= 3'd7;
	// Reads, writes detected above
	else if (cs1xx & ~fast_read1)
		nch <= 3'd1;
	else if (cs2xx & ~fast_read2)
		nch <= 3'd2;
	else if (cs3xx & ~fast_read3)
		nch <= 3'd3;
	else if (cs4xx & ~fast_read4)
		nch <= 3'd4;
	else if (cs5xx & ~fast_read5)
		nch <= 3'd5;
	else if (cs6xx & ~fast_read6)
		nch <= 3'd6;
	else if (cs7xx & ~fast_read7)
		nch <= 3'd7;
	// Nothing selected
	else
		nch <= 4'hF;
end

// This counter used to periodically reverse channel priorities to help ensure
// that a particular channel isn't permanently blocked by other higher priority
// ones.
always_ff @(posedge mem_ui_clk)
if (state==PRESET1) begin
	elevate_cnt <= elevate_cnt + 6'd1;
	elevate <= elevate_cnt == 6'd63;
end

always_ff @(posedge mem_ui_clk)
if (state==IDLE)
	ch <= nch;

// Select the address input
reg [31:0] adrx;
always_ff @(posedge mem_ui_clk)
if (state==IDLE) begin
	case(nch)
	3'd0:	if (we0xx)
				adrx <= {adr0xx[AMSB:4],4'h0};
			else
				adrx <= {adr0xx[AMSB:4],4'h0};
	3'd1:	if (we1xx)
				adrx <= {adr1xx[AMSB:4],4'h0};
			else
				adrx <= {adr1xx[AMSB:4],4'h0};
	3'd2:	adrx <= {adr2xx[AMSB:4],4'h0};
	3'd3:	adrx <= {adr3xx[AMSB:4],4'h0};
	3'd4:	adrx <= {adr4xx[AMSB:4],4'h0};
	3'd5:	adrx <= {adr5xx[AMSB:4],4'h0};
	3'd6:	adrx <= {adr6xx[AMSB:4],4'h0};
	3'd7:
		if (we7xx) 
			adrx <= {adr7xx[AMSB:1],1'h0};
		else
			adrx <= {adr7xx[AMSB:4],4'h0};
	default:	adrx <= 29'h1FFFFFF0;
	endcase
end
always_ff @(posedge mem_ui_clk)
if (mem_ui_rst)
	adr <= 29'h1FFFFFF0;
else if (state==PRESET1)
	adr <= adrx;

// Setting the write mask
reg [15:0] wmask0;
reg [15:0] wmask1;
reg [15:0] wmask2;
reg [15:0] wmask3;
reg [15:0] wmask4;
reg [15:0] wmask5;
reg [15:0] wmask6;
reg [15:0] wmask7;

always_ff @(posedge mem_ui_clk)
if (state==IDLE)
begin
	if (we0xx) begin
		if (C0W==128)
			wmask0 <= ~sel0xx;
		else if (C0W==64)
			wmask0 <= ~({8'd0,sel0xx} << {adr0xx[2],3'b0});
		else if (C0W==32)
			wmask0 <= ~({12'd0,sel0xx} << {adr0xx[2:2],2'b0});
		else if (C0W==16)
			wmask0 <= ~({14'd0,sel0xx} << {adr0xx[2:1],1'b0});
		else
			wmask0 <= ~({15'd0,sel0xx} << adr0xx[2:0]);
	end
	else
		wmask0 <= 16'h0000;
end

always_ff @(posedge mem_ui_clk)
if (state==IDLE)
	if (we1xx) begin
		if (C1W==128)
			wmask1 <= ~sel1xx;
		else if (C1W==64)
			wmask1 <= ~({8'd0,sel1xx} << {adr1xx[2],3'b0});
		else if (C1W==32)
			wmask1 <= ~({12'd0,sel1xx} << {adr1xx[2:2],2'b0});
		else if (C1W==16)
			wmask1 <= ~({14'd0,sel1xx} << {adr1xx[2:1],1'b0});
		else
			wmask1 <= ~({15'd0,sel1xx} << adr1xx[2:0]);
	end
	else
		wmask1 <= 16'hFFFF;

always_ff @(posedge mem_ui_clk)
if (state==IDLE)
	if (we2xx) begin
		if (C2W==128)
			wmask2 <= ~sel2xx;
		else if (C2W==64)
			wmask2 <= ~({8'd0,sel2xx} << {adr2xx[2],3'b0});
		else if (C2W==32)
			wmask2 <= ~({12'd0,sel2xx} << {adr2xx[2:2],2'b0});
		else if (C2W==16)
			wmask2 <= ~({14'd0,sel2xx} << {adr2xx[2:1],1'b0});
		else
			wmask2 <= ~({15'd0,sel2xx} << adr2xx[2:0]);
	end
	else
		wmask2 <= 16'hFFFF;

always_ff @(posedge mem_ui_clk)
if (state==IDLE)
	if (we3xx) begin
		if (C3W==128)
			wmask3 <= ~sel3xx;
		else if (C3W==64)
			wmask3 <= ~({8'd0,sel3xx} << {adr3xx[3],3'b0});
		else if (C3W==32)
			wmask3 <= ~({12'd0,sel3xx} << {adr3xx[3:2],2'b0});
		else if (C3W==16)
			wmask3 <= ~({14'd0,sel3xx} << {adr3xx[3:1],1'b0});
		else
			wmask3 <= ~({15'd0,sel3xx} << adr3xx[3:0]);
	end
	else
		wmask3 <= 16'hFFFF;

always_ff @(posedge mem_ui_clk)
if (state==IDLE)
	if (we4xx) begin
		if (C4W==128)
			wmask4 <= ~sel4xx;
		else if (C4W==64)
			wmask4 <= ~({8'd0,sel4xx} << {adr4xx[3],3'b0});
		else if (C4W==32)
			wmask4 <= ~({12'd0,sel4xx} << {adr4xx[3:2],2'b0});
		else if (C4W==16)
			wmask4 <= ~({14'd0,sel4xx} << {adr4xx[3:1],1'b0});
		else
			wmask4 <= ~({15'd0,sel4xx} << adr4xx[3:0]);
	end
	else
		wmask4 <= 16'hFFFF;

always_ff @(posedge mem_ui_clk)
if (state==IDLE)
	wmask5 <= 16'hFFFF;

always_ff @(posedge mem_ui_clk)
if (state==IDLE)
	if (we6xx) begin
		if (C6W==128)
			wmask6 <= ~sel6xx;
		else if (C6W==64)
			wmask6 <= ~({8'd0,sel6xx} << {adr6xx[3],3'b0});
		else if (C6W==32)
			wmask6 <= ~({12'd0,sel6xx} << {adr6xx[3:2],2'b0});
		else if (C6W==16)
			wmask6 <= ~({14'd0,sel6xx} << {adr6xx[3:1],1'b0});
		else
			wmask6 <= ~({15'd0,sel6xx} << adr6xx[3:0]);
  end
  else
  	wmask6 <= 16'hFFFF;

always_ff @(posedge mem_ui_clk)
if (state==IDLE)
	if (we7xx) begin
		if (C7W==128)
			wmask7 <= ~sel7xx;
		else if (C7W==64)
			wmask7 <= ~({8'd0,sel7xx} << {adr7xx[3],3'b0});
		else if (C7W==32)
			wmask7 <= ~({12'd0,sel7xx} << {adr7xx[3:2],2'b0});
		else if (C7W==16)
			wmask7 <= ~({14'd0,sel7xx} << {adr7xx[3:1],1'b0});
		else
			wmask7 <= ~({15'd0,sel7xx} << adr7xx[3:0]);
	end
	else
		wmask7 <= 16'hFFFF;	// read all bytes

// Setting the write data
// Repeat the data across lanes when less than 128-bit.
always_ff @(posedge mem_ui_clk)
if (state==IDLE) begin
	case(nch)
	3'd0:	dat128 <= {128/C0W{dati0xx}};
	3'd1:	dat128 <= {128/C1W{dati1xx}};
	3'd2:	dat128 <= {128/C2W{dati2xx}};
	3'd3:	dat128 <= {128/C3W{dati3xx}};
	3'd4:	dat128 <= {128/C4W{dati4xx}};
	3'd5:	;	// channel is read-only
	3'd6:	dat128 <= {128/C6W{dati6xx}};
	3'd7:	dat128 <= {128/C7W{dati7xx}};
	default:	dat128 <= {2{dati7xx}};
	endcase
end

// Setting the data value. Unlike reads there is only a single strip involved.
// Force unselected byte lanes to $FF
reg [15:0] mem_wdf_mask2;
reg [127:0] dat128x;
genvar g;
generate begin : gMemData
	for (g = 0; g < 16; g = g + 1)
		always_comb
			if (mem_wdf_mask2[g])
				dat128x[g*8+7:g*8] = 8'hFF;
			else
				dat128x[g*8+7:g*8] = dat128[g*8+7:g*8];
end
endgenerate

always_ff @(posedge mem_ui_clk)
if (mem_ui_rst)
  mem_wdf_data <= 128'd0;
else begin
	if (state==PRESET2)
		mem_wdf_data <= dat128x;
	else if (state==WRITE_TRAMP1)
		mem_wdf_data <= rmw_data;
end

generate begin : gRMW
for (g = 0; g < 16; g = g + 1) begin
	always_ff @(posedge mem_ui_clk)
	begin
		if (state==WRITE_TRAMP) begin
			if (mem_wdf_mask[g])
				rmw_data[g*8+7:g*8] <= mem_wdf_data[g*8+7:g*8];
			else
				rmw_data[g*8+7:g*8] <= mem_rd_data[g*8+7:g*8];
		end
	end
end
end
endgenerate

// Managing read cache addresses
// When to load cache address tag
reg ld_addr;
always_ff @(posedge mem_ui_clk)
	ld_addr <= (state==WAIT_RD) && mem_rd_data_valid && mem_rd_data_end
							&& resp_strip_cnt==num_strips && !do_wr;
// Check for cache clear
reg cc0,cc1,cc2,cc3,cc4,cc5,cc6,cc7;
always_ff @(posedge mem_ui_clk) cc0 <= state==IDLE && cs0xx && we0xx;
always_ff @(posedge mem_ui_clk) cc1 <= state==IDLE && cs1xx && we1xx;
always_ff @(posedge mem_ui_clk) cc2 <= state==IDLE && cs2xx && we2xx;
always_ff @(posedge mem_ui_clk) cc3 <= state==IDLE && cs3xx && we3xx;
always_ff @(posedge mem_ui_clk) cc4 <= state==IDLE && cs4xx && we4xx;
always_ff @(posedge mem_ui_clk) cc6 <= state==IDLE && cs6xx && we6xx;
always_ff @(posedge mem_ui_clk) cc7 <= state==IDLE && cs7xx && we7xx;

always_ff @(posedge mem_ui_clk)
if (mem_ui_rst) begin
	ch0_tag <= 32'hFFFFFFFF;
	ch1_tag <= 32'hFFFFFFFF;
	ch2_tag <= 32'hFFFFFFFF;
	ch3_tag <= 32'hFFFFFFFF;
	ch4_tag <= 32'hFFFFFFFF;
	for (n = 0; n < 64; n = n + 1)
		ch5_tag[n] <= 32'hFFFFFFFF;
	ch6_tag <= 32'hFFFFFFFF;
	ch7_tag <= 32'hFFFFFFFF;
end
else begin
	if (cc0) clear_tag(adr0xx);
	if (cc1) clear_tag(adr1xx);
	if (cc2) clear_tag(adr2xx);
	if (cc3) clear_tag(adr3xx);
	if (cc4) clear_tag(adr4xx);
	if (cc6) clear_tag(adr6xx);
	if (cc7) clear_tag(adr7xx);
	if (ld_addr) begin
		case(ch)
		3'd0:	ch0_tag <= {adr0xx[31:4],4'h0};
		3'd1: ch1_tag <= {adr1xx[31:4],4'h0};
		3'd2: ch2_tag <= {adr2xx[31:4],4'h0};
		3'd3: ch3_tag <= {adr3xx[31:4],4'h0};
		3'd4: ch4_tag <= {adr4xx[31:4],4'h0};
		3'd5: ch5_tag[spritenoxx] <= {adr5xx[31:4],4'h0};
		3'd6: ch6_tag <= {adr6xx[31:4],4'h0};
		3'd7: ch7_tag <= {adr7xx[31:4],4'h0};
		default:	;
		endcase
	end
end

always_ff @(posedge mem_ui_clk)
if (state==IDLE)
	spriteno_r <= spritenoxx;

// Setting burst length
always_ff @(posedge mem_ui_clk)
if (state==IDLE) begin
	num_strips <= 3'd0;
	case(nch)
	3'd0:	if (!we0xx) num_strips <= 3'd7;		//7
	3'd1:	if (!we1xx)	num_strips <= 3'd1;		//1
	3'd2:	;
	3'd3:	;
	3'd4:	;
	3'd5:	num_strips <= 3'd3;	//3
	3'd6:	;
	3'd7:	;
	default:	;
	endcase
end

// Auto-increment the request address during a read burst until the desired
// number of strips are requested.
always_ff @(posedge mem_ui_clk)
if (mem_ui_rst)
	mem_addr <= 29'h1FFFFFFF;
else begin
	if (state==PRESET2)
		mem_addr <= adr[28:0];
	else begin
		if (state==SET_CMD_RD)
		  if (mem_rdy == TRUE) begin
		    if (req_strip_cnt!=num_strips)
		      mem_addr <= mem_addr + 5'd16;
		  end
	end
end

// Setting the data mask. Values are enabled when the data mask is zero.
always_ff @(posedge mem_ui_clk)
if (mem_ui_rst)
  mem_wdf_mask2 <= 16'hFFFF;
else begin
	if (state==PRESET1)
		case(ch)
		3'd0:	mem_wdf_mask2 <= wmask0;
		3'd1:	mem_wdf_mask2 <= wmask1;
		3'd2:	mem_wdf_mask2 <= wmask2;
		3'd3:	mem_wdf_mask2 <= wmask3;
		3'd4:	mem_wdf_mask2 <= wmask4;
		3'd5:	mem_wdf_mask2 <= wmask5;
		3'd6:	mem_wdf_mask2 <= wmask6;
		3'd7:	mem_wdf_mask2 <= wmask7;
		default:	mem_wdf_mask2 <= 16'hFFFF;
		endcase
	// For RMW cycle all bytes are writtten.
	else if (state==WRITE_TRAMP1)
		mem_wdf_mask2 <= 16'h0000;
end
always_ff @(posedge mem_ui_clk)
if (mem_ui_rst)
  mem_wdf_mask <= 16'hFFFF;
else if (state==PRESET2)
	mem_wdf_mask <= mem_wdf_mask2;

// Setting output data. Force output data to zero when not selected to allow
// wire-oring the data.
always_ff @(posedge clk0)
if (cs0) begin
`ifdef RED_SCREEN
	if (C0W==128)
		dato0 <= 128'h7C007C007C007C007C007C007C007C00;
	else if (C0W==64)
		dato0 <= 64'h7C007C007C007C00;
	else
		dato0 <= 32'h7C007C00;
`else
	if (C0W==128)
		dato0 <= ch0_rd_data[adr0xx[5:4]];
	else if (C0W==64)
		case(adr0xx[3])
		1'd0:	dato0 <= ch0_rd_data[adr0xx[5:4]][63:0];
		1'd1:	dato0 <= ch0_rd_data[adr0xx[5:4]][127:64];
		endcase
	else
		case(adr0xx[3:2])
		2'd0:	dato0 <= ch0_rd_data[adr0xx[5:4]][31:0];
		2'd1:	dato0 <= ch0_rd_data[adr0xx[5:4]][63:32];
		2'd2:	dato0 <= ch0_rd_data[adr0xx[5:4]][95:64];
		2'd3:	dato0 <= ch0_rd_data[adr0xx[5:4]][127:96];
		endcase
`endif
end
else
	dato0 <= {C0W{1'b0}};

always_ff @(posedge clk1)
if (cs1) begin
	if (C1W==128)
		dato1 <= ch1_rd_data[adr1xx[4]];
	else if (C1W==64)
		case(adr1xx[3])
		1'd0:	dato1 <= ch1_rd_data[adr1xx[4]][63:0];
		1'd1:	dato1 <= ch1_rd_data[adr1xx[4]][127:64];
		endcase
	else
		case(adr1xx[3:2])
		2'd0:	dato1 <= ch1_rd_data[adr1xx[4]][31:0];
		2'd1:	dato1 <= ch1_rd_data[adr1xx[4]][63:32];
		2'd2:	dato1 <= ch1_rd_data[adr1xx[4]][95:64];
		2'd3:	dato1 <= ch1_rd_data[adr1xx[4]][127:96];
		endcase
end
else
	dato1 <= {C1W{1'b0}};

always_ff @(posedge clk2)
if (cs2) begin
	if (C2W==128)
		dato2 <= ch2_rd_data;
	else if (C2W==64)
		case(adr2xx[3])
    1'd0:    dato2 <= ch2_rd_data[ 63:0];
    1'd1:    dato2 <= ch2_rd_data[127:64];
    endcase
	else
		case(adr2xx[3:2])
    2'd0:    dato2 <= ch2_rd_data[31:0];
    2'd1:    dato2 <= ch2_rd_data[63:32];
    2'd2:    dato2 <= ch2_rd_data[95:64];
    2'd3:    dato2 <= ch2_rd_data[127:96];
    endcase
end
else
	dato2 <= {C2W{1'b0}};

always_ff @(posedge clk3)
if (cs3)
	dato3 <= ch3_rd_data >> {adr3xx[3:1],4'd0};
else
	dato3 <= 16'h0;

always_ff @(posedge clk4)
if (cs4) begin
	if (C4W==128)
		dato4 <= ch4_rd_data;
	else
		case(adr4xx[3])
		1'b0:	dato4 <= ch4_rd_data[63:0];
		1'b1:	dato4 <= ch4_rd_data[127:64];
		endcase
end
else
	dato4 <= {C4W{1'b0}};

always_ff @(posedge clk5)
if (cs5) begin
	if (C5W==128)
		dato5 <= ch5_rd_data[{spriteno_r,adr5xx[5:4]}][127: 0];
	else if (C5W==64)
		case(adr5xx[3])
		1'b0:	dato5 <= ch5_rd_data[{spriteno_r,adr5xx[5:4]}][ 63: 0];
		1'b1:	dato5 <= ch5_rd_data[{spriteno_r,adr5xx[5:4]}][127:64];
	  endcase
	else if (C5W==32)
		case(adr5xx[3:2])
		2'd0:	dato5 <= ch5_rd_data[{spriteno_r,adr5xx[5:4]}][ 31: 0];
		2'd1:	dato5 <= ch5_rd_data[{spriteno_r,adr5xx[5:4]}][ 63:32];
		2'd2:	dato5 <= ch5_rd_data[{spriteno_r,adr5xx[5:4]}][ 95:64];
		2'd3:	dato5 <= ch5_rd_data[{spriteno_r,adr5xx[5:4]}][127:96];
	  endcase
end
else
	dato5 <= {C5W{1'b0}};

always_ff @(posedge clk6)
if (cs6) begin
	if (C6W==128)
		dato6 <= ch6_rd_data;
	else if (C6W==64)
		case(adr6xx[3])
    1'd0:    dato6 <= ch6_rd_data[ 63:0];
    1'd1:    dato6 <= ch6_rd_data[127:64];
    endcase
	else
		case(adr6xx[3:2])
    2'd0:    dato6 <= ch6_rd_data[31:0];
    2'd1:    dato6 <= ch6_rd_data[63:32];
    2'd2:    dato6 <= ch6_rd_data[95:64];
    2'd3:    dato6 <= ch6_rd_data[127:96];
    endcase
end
else
	dato6 <= {C6W{1'b0}};

always_ff @(posedge clk7)
if (cs7) begin
	if (C7R==128)
		dato7 <= ch7_rd_data;
	else if (C7R==64)
		dato7 <= ch7_rd_data >> {adr7xx[3],6'h0};
	else if (C7R==32)
		dato7 <= ch7_rd_data >> {adr7xx[3:2],5'h0};
	else if (C7R==16)
		dato7 <= ch7_rd_data >> {adr7xx[3:1],4'h0};
	else
		dato7 <= ch7_rd_data >> {adr7xx[3:0],3'h0};
end
else
	dato7 <= {C7W{1'b0}};

// Setting ack output
// Ack takes place outside of a state so that reads from different read caches
// may occur at the same time.
always @(posedge mem_ui_clk)
if (rst_i|mem_ui_rst) begin
	acki0 <= FALSE;
	acki1 <= FALSE;
	acki2 <= FALSE;
	acki3 <= FALSE;
	acki4 <= FALSE;
	acki5 <= FALSE;
	acki6 <= FALSE;
	acki7 <= FALSE;
end
else begin
	// Reads: the ack doesn't happen until the data's been cached.
	if (fast_read0)
		acki0 <= TRUE;
	if (ch1_read)
		acki1 <= TRUE;
	if (!we2xx && cs2xx && adr2xx[31:4]==ch2_tag[31:4])
		acki2 <= TRUE;
	if (!we3xx && cs3xx && adr3xx[31:4]==ch3_tag[31:4])
		acki3 <= TRUE;
	if (!we4xx && cs4xx && adr4xx[31:4]==ch4_tag[31:4])
		acki4 <= TRUE;
	if (cs5xx && adr5xx[31:4]==ch5_tag[spritenoxx][31:4])
    acki5 <= TRUE;
	if (!we6xx && cs6xx && adr6xx[31:4]==ch6_tag[31:4])
		acki6 <= TRUE;
  if (fast_read7)
    acki7 <= TRUE;

	if (state==IDLE) begin
    if (cr1xx) begin
      acki1 <= TRUE;
    	for (n = 0; n < NAR; n = n + 1)
      	if ((resv_ch[n]==4'd1) && (resv_adr[n][31:4]==adr1xx[31:4]))
        	acki1 <= FALSE;
    end
//    else
//        acki1 <= FALSE;
    if (cr7xx) begin
      acki7 <= TRUE;
    	for (n = 0; n < NAR; n = n + 1)
	      if ((resv_ch[n]==4'd7) && (resv_adr[n][31:4]==adr7xx[31:4]))
	        acki7 <= FALSE;
    end
//    else
//      acki7 <= FALSE;
	end

	// Write: an ack can be sent back as soon as the write state is reached..
	if (state==SET_CMD_WR && mem_rdy == TRUE)
    case(ch)
    3'd0:   acki0 <= TRUE;
    3'd1:   acki1 <= TRUE;
    3'd2:   acki2 <= TRUE;
    3'd3:   acki3 <= TRUE;
    3'd4:   acki4 <= TRUE;
    3'd5:   acki5 <= TRUE;
    3'd6:   acki6 <= TRUE;
    3'd7:   acki7 <= TRUE;
    default:	;
    endcase

	// Clear the ack when the circuit is de-selected.
	if (!cs0) acki0 <= FALSE;
	if (!cs1 || !ics1) acki1 <= FALSE;
	if (!cs2) acki2 <= FALSE;
	if (!cs3) acki3 <= FALSE;
	if (!cs4) acki4 <= FALSE;
	if (!cs5) acki5 <= FALSE;
	if (!cs6) acki6 <= FALSE;
	if (!cs7) acki7 <= FALSE;

end

wire ne_data_valid;
edge_det ued1 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(mem_rd_data_valid), .pe(), .ne(ne_data_valid), .ee());

always_ff @(posedge mem_ui_clk)
	state <= next_state;

// State machine
always_comb
if (rst_i|mem_ui_rst)
	next_state <= IDLE;
else begin
case(state)
IDLE:
  // According to the docs there's no need to wait for calib complete.
  // Calib complete goes high in sim about 111 us.
  // Simulation setting must be set to FAST.
	//if (calib_complete)
	case(nch)
	3'd0:	next_state <= PRESET1;
	3'd1:
	    if (cr1xx) begin
        next_state <= IDLE;
	    	for (n = 0; n < NAR; n = n + 1)
        	if ((resv_ch[n]==4'd1) && (resv_adr[n][31:4]==adr1xx[31:4]))
          	next_state <= PRESET1;
	    end
	    else
        next_state <= PRESET1;
	3'd2:	next_state <= PRESET1;
	3'd3:	next_state <= PRESET1;
	3'd4:	next_state <= PRESET1;
	3'd5:	next_state <= PRESET1;
	3'd6:	next_state <= PRESET1;
	3'd7:
	    if (cr7xx) begin
        next_state <= IDLE;
	    	for (n = 0; n < NAR; n = n + 1)
	        if ((resv_ch[n]==4'd7) && (resv_adr[n][31:4]==adr7xx[31:4]))
            next_state <= PRESET1;
	    end
	    else
        next_state <= PRESET1;
	default:	;	// no channel selected -> stay in IDLE state
	endcase
PRESET1:
	next_state <= PRESET2;
PRESET2:
	if (do_wr && !RMW)
		next_state <= SEND_DATA;
	else
		next_state <= SET_CMD_RD;
SEND_DATA:
  if (mem_wdf_rdy == TRUE)
    next_state <= SET_CMD_WR;
SET_CMD_WR:
 	if (mem_rdy == TRUE)
   	next_state <= WAIT_NACK;

// There could be multiple read requests submitted before any response occurs.
// Stay in the SET_CMD_RD until all requested strips have been processed.
SET_CMD_RD:
	begin
	  if (mem_rdy == TRUE) begin
	  	if (req_strip_cnt==num_strips)
				next_state <= WAIT_RD;
		end
	  if (mem_rd_data_valid & mem_rd_data_end) begin
	  	if (resp_strip_cnt==num_strips) begin
		  	if (do_wr)
		  		next_state <= WRITE_TRAMP;
				else
					next_state <= WAIT_NACK;
			end
		end
	end
// Wait for incoming responses.
WAIT_RD:
	begin
		if (tocnt==16'd4000) begin
	  	if (do_wr)
	  		next_state <= WRITE_TRAMP;
			else
				next_state <= WAIT_NACK;
		end
	  if (mem_rd_data_valid & mem_rd_data_end) begin
	  	if (resp_strip_cnt==num_strips) begin
		  	if (do_wr)
		  		next_state <= WRITE_TRAMP;
				else
					next_state <= WAIT_NACK;
			end
		end
	end
WAIT_NACK:	;
WRITE_TRAMP:
	next_state <= WRITE_TRAMP1;
WRITE_TRAMP1:
	next_state <= SEND_DATA;

default:	next_state <= IDLE;
endcase

	case(ch)
	3'd0:	if (ne_acki0) next_state <= IDLE;
	3'd1:	if (ne_acki1) next_state <= IDLE;
	3'd2:	if (ne_acki2) next_state <= IDLE;
	3'd3:	if (ne_acki3) next_state <= IDLE;
	3'd4:	if (ne_acki4) next_state <= IDLE;
	3'd5:	if (ne_acki5) next_state <= IDLE;
	3'd6:	if (ne_acki6) next_state <= IDLE;
	3'd7:	if (ne_acki7) next_state <= IDLE;
	default:	next_state <= IDLE;
	endcase
end

always_ff @(posedge mem_ui_clk)
begin
	if (state==SET_CMD_RD)
		tocnt <= 16'd0;
	else if (state==WAIT_RD)
		tocnt <= tocnt + 2'd1;
end

always_ff @(posedge mem_ui_clk)
begin
	mem_en <= FALSE;
	if (state==SEND_DATA && mem_wdf_rdy)
		mem_en <= TRUE;
	if (state==PRESET2 && !(do_wr && !RMW))
		mem_en <= TRUE;
end

always_ff @(posedge mem_ui_clk)
begin
	mem_wdf_wren <= FALSE;
	if (state==PRESET2 && (do_wr && !RMW))
		mem_wdf_wren <= TRUE;
end

always_ff @(posedge mem_ui_clk)
begin
	mem_wdf_end <= FALSE;
	if (state==PRESET2 && (do_wr && !RMW))
		mem_wdf_end <= TRUE;
end

// Strangely, for the DDR3 the default is to have a write command value,
// overridden when a read is needed. The command is processed by the 
// SET_CMD_xx states.
always_ff @(posedge mem_ui_clk)
begin
	mem_cmd <= CMD_WRITE;
	if (state==PRESET2 && !(do_wr && !RMW))
		mem_cmd <= CMD_READ;
end

// Manage memory strip counters.
always_ff @(posedge mem_ui_clk)
if (state==IDLE)
	req_strip_cnt <= 3'd0;
else if (state==SET_CMD_RD)
  if (mem_rdy == TRUE) begin
    if (req_strip_cnt != num_strips)
      req_strip_cnt <= req_strip_cnt + 3'd1;
  end

always_ff @(posedge mem_ui_clk)
if (state==IDLE)
	resp_strip_cnt <= 3'd0;
else if (state==WAIT_RD || state==SET_CMD_RD)
	if (mem_rd_data_valid & mem_rd_data_end)
		if (resp_strip_cnt != num_strips)
    	resp_strip_cnt <= resp_strip_cnt + 3'd1;

// Update data caches with read data.
always_ff @(posedge mem_ui_clk)
begin
	if (state==WAIT_RD || state==WAIT_NACK || state==SET_CMD_RD)
		if (mem_rd_data_valid && mem_rd_data_end) begin
	    case(ch)
	    3'd0:	ch0_rd_data[resp_strip_cnt[2:0]] <= mem_rd_data;
	    3'd1:	ch1_rd_data[resp_strip_cnt[0]] <= mem_rd_data;
	    3'd2:	ch2_rd_data <= mem_rd_data;
	    3'd3:	ch3_rd_data <= mem_rd_data;
	    3'd4:	ch4_rd_data <= mem_rd_data;
	    3'd5:	ch5_rd_data[{spriteno_r,resp_strip_cnt[1:0]}] <= mem_rd_data;
	    3'd6:	ch6_rd_data <= mem_rd_data;
	    3'd7:	ch7_rd_data <= mem_rd_data;
	    default:	;
	    endcase
		end
end

// Write operation indicator
always_ff @(posedge mem_ui_clk)
begin
	if (state==IDLE) begin
		do_wr <= FALSE;
		case(nch)
		3'd0:	do_wr <= we0xx;
		3'd1:
			if (we1xx) begin
			    if (cr1xx) begin
			    	for (n = 0; n < NAR; n = n + 1)
			        if ((resv_ch[n]==4'd1) && (resv_adr[n][31:4]==adr1xx[31:4]))
		            do_wr <= TRUE;
			    end
			    else
		        do_wr <= TRUE;
			end
		3'd2:	do_wr <= we2;
		3'd3:	do_wr <= we3;
		3'd4:	do_wr <= we4;
		3'd6:	do_wr <= we6;
		3'd7:
			if (we7xx) begin
			    if (cr7xx) begin
			    	for (n = 0; n < NAR; n = n + 1)
			        if ((resv_ch[n]==4'd7) && (resv_adr[n][31:4]==adr7xx[31:4]))
		            do_wr <= TRUE;
			    end
			    else
		        do_wr <= TRUE;
			end
	    default:	;
	    endcase
	end
end

// Reservation status bit
always_ff @(posedge mem_ui_clk)
if (state==IDLE) begin
  if (cs1xx & we1xx & ~acki1) begin
    if (cr1xx) begin
      rb1 <= FALSE;
    	for (n = 0; n < NAR; n = n + 1)
	      if ((resv_ch[n]==4'd1) && (resv_adr[n][31:4]==adr1xx[31:4]))
  	      rb1 <= TRUE;
    end
  end
end

always_ff @(posedge mem_ui_clk)
if (state==IDLE) begin
  if (cs7xx & we7xx & ~acki7) begin
    if (cr7xx) begin
      rb7 <= FALSE;
    	for (n = 0; n < NAR; n = n + 1)
	      if ((resv_ch[n]==4'd7) && (resv_adr[n][31:4]==adr7xx[31:4]))
  	      rb7 <= TRUE;
    end
  end
end

// Managing address reservations
always_ff @(posedge mem_ui_clk)
if (mem_ui_rst) begin
	resv_to_cnt <= 20'd0;
	toggle <= FALSE;
	toggle_sr <= FALSE;
 	for (n = 0; n < NAR; n = n + 1)
		resv_ch[n] <= 4'hF;
end
else begin
	resv_to_cnt <= resv_to_cnt + 20'd1;

	if (sr1x & sr7x) begin
		if (toggle_sr) begin
			reserve_adr(4'h1,adr1xx);
			toggle_sr <= 1'b0;
		end
		else begin
			reserve_adr(4'h7,adr7xx);
			toggle_sr <= 1'b1;
		end
	end
	else begin
		if (sr1x)
			reserve_adr(4'h1,adr1xx);
		if (sr7x)
			reserve_adr(4'h7,adr7xx);
	end

	if (state==IDLE) begin
		if (cs1xx & we1xx & ~acki1) begin
		    toggle <= 1'b1;
		    if (cr1xx) begin
		    	for (n = 0; n < NAR; n = n + 1)
		        if ((resv_ch[n]==4'd1) && (resv_adr[n][31:4]==adr1xx[31:4]))
		            resv_ch[n] <= 4'hF;
		    end
		end
		else if (cs7xx & we7xx & ~acki7) begin
		    toggle <= 1'b1;
		    if (cr7xx) begin
		    	for (n = 0; n < NAR; n = n + 1)
		        if ((resv_ch[n]==4'd7) && (resv_adr[n][31:4]==adr7xx[31:4]))
		            resv_ch[n] <= 4'hF;
		    end
		end
		else if (!we1xx & cs1xx & ~fast_read1 & (cs7xx ? toggle : 1'b1))
			toggle <= 1'b0;
		else if (!we7xx & cs7xx & ~fast_read7)
			toggle <= 1'b1;
	end
end

// Clear the read cache tag where the cache address matches the given address.
// This is to prevent reading stale data from a cache.
task clear_tag;
input [31:0] ccadr;
begin
	if (ch0_tag[31:6]==ccadr[31:6])
		ch0_tag <= 32'hFFFFFFFF;
	if (ch1_tag[31:5]==ccadr[31:5])
		ch1_tag <= 32'hFFFFFFFF;
	if (ch2_tag[31:4]==ccadr[31:4])
		ch2_tag <= 32'hFFFFFFFF;
	if (ch3_tag[31:4]==ccadr[31:4])
		ch3_tag <= 32'hFFFFFFFF;
	if (ch4_tag[31:4]==ccadr[31:4])
		ch4_tag <= 32'hFFFFFFFF;
	// For channel5 we don't care.
	// It's possible that stale data would be read, but it's only for one video
	// frame. It's a lot of extra hardware to clear channel5 so we don't do it.
	// It is also unlikely that the sprite image data would be changing during
	// the display period.
	if (ch6_tag[31:4]==ccadr[31:4])
		ch6_tag <= 32'hFFFFFFFF;
	if (ch7_tag[31:4]==ccadr[31:4])
		ch7_tag <= 32'hFFFFFFFF;
end
endtask

integer empty_resv;
function resv_held;
input [3:0] ch;
input [31:0] adr;
begin
	resv_held = FALSE;
 	for (n = 0; n < NAR; n = n + 1)
 		if (resv_ch[n]==ch && resv_adr[n]==adr)
 			resv_held = TRUE;
end
endfunction

// Find an empty reservation bucket
always_comb
begin
	empty_resv <= -1;
 	for (n = 0; n < NAR; n = n + 1)
		if (resv_ch[n]==4'hF)
			empty_resv <= n;
end

// Two reservation buckets are allowed for. There are two (or more) CPU's in the
// system and as long as they are not trying to control the same resource (the
// same semaphore) then they should be able to set a reservation. Ideally there
// could be more reservation buckets available, but it starts to be a lot of
// hardware.
task reserve_adr;
input [3:0] ch;
input [31:0] adr;
begin
	// Ignore an attempt to reserve an address that's already reserved. The LWAR
	// instruction is usually called in a loop and we don't want it to use up
	// all address reservations.
	if (!resv_held(ch,adr)) begin
		if (empty_resv >= 0) begin
			resv_ch[empty_resv] <= ch;
			resv_adr[empty_resv] <= adr;
		end
		// Here there were no free reservation buckets, so toss one of the
		// old reservations out.
		else begin
			resv_ch[match] <= ch;
			resv_adr[match] <= adr;
		end
	end
end
endtask

endmodule


