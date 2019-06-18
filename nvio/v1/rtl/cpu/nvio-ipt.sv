// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_ipt.v
//  - 64 bit CPU inverted page table memory management unit
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
`ifndef TRUE
`define TRUE    1'b1
`define FALSE   1'b0
`endif
`define BYPASS	1'b1

module nvio_ipt(rst, clk, pkeys_i, ol_i, bte_i, cti_i, cs_i, icl_i, cyc_i, stb_i, ack_o, we_i, sel_i, vadr_i, dat_i, dat_o,
	bte_o, cti_o, cyc_o, ack_i, we_o, sel_o, padr_o, exv_o, rdv_o, wrv_o, prv_o, page_fault);
input rst;
input clk;
input [63:0] pkeys_i;
input [1:0] ol_i;
input [1:0] bte_i;
input [2:0] cti_i;
input cs_i;
input icl_i;
input cyc_i;
input stb_i;
output reg ack_o;
input we_i;
input [15:0] sel_i;
input [63:0] vadr_i;
input [63:0] dat_i;
output reg [63:0] dat_o;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg cyc_o;
input ack_i;
output reg we_o;
output reg [15:0] sel_o;
output reg [31:0] padr_o;
output reg exv_o;
output reg rdv_o;
output reg wrv_o;
output reg prv_o;
output reg page_fault;

parameter S_IDLE = 4'd0;
parameter S_CMP1 = 4'd1;
parameter S_CMP2 = 4'd2;
parameter S_CMP3 = 4'd3;
parameter S_CMP4 = 4'd4;
parameter S_CMP5 = 4'd5;
parameter S_CMP6 = 4'd6;
parameter S_WAIT1 = 4'd7;
parameter S_ACK = 4'd8;
parameter S_RESET = 4'd9;

integer n;
wire [9:0] pkey [0:5];
assign pkey[0] = pkeys_i[9:0];
assign pkey[1] = pkeys_i[19:10];
assign pkey[2] = pkeys_i[29:20];
assign pkey[3] = pkeys_i[39:30];
assign pkey[4] = pkeys_i[49:40];
assign pkey[5] = pkeys_i[59:50];
reg [3:0] state;
reg [15:0] pt_ad;
reg upd;
reg upd_done;
reg probe, probe_done;
reg pte_last;
reg [7:0] pte_asid;
reg [3:0] pte_drwx;
reg [18:0] pte_vadr;
reg [9:0] pte_key;
reg pt_wr;
reg [41:0] pt_dati;
wire [41:0] pt_dat;

iptram uram1 (
  .clka(clk),
  .ena(1'b1),
  .wea(pt_wr),
  .addra(pt_ad),
  .dina(pt_dati),
  .douta(pt_dat)
);

wire pt_last = pt_dat[23];
wire [18:0] pt_vadr = pt_dat[22:4];
wire [7:0] pt_asid = pt_dat[31:24];
wire [3:0] pt_drwx = pt_dat[3:0];
wire [9:0] pt_key = pt_dat[41:32];

reg keymatch;
always @*
begin
keymatch = ol_i==2'b00;
for (n = 0; n < 6; n = n + 1)
	if (pt_key==pkey[n] || pt_key==10'h0)
		keymatch = 1'b1;
end

function [15:0] Hash1;
input [39:0] vadr;
begin
	Hash1 = {1'b0,vadr[37:32],vadr[21:13]};
end
endfunction

function [15:0] Hash2;
input [39:0] vadr;
begin
	Hash2 = {1'b1,vadr[37:32],vadr[21:13]};
end
endfunction

always @(posedge clk)
	case(vadr_i[5:3])
	3'd1:
		dat_o <= pt_ad;
	3'd2:
		begin
			dat_o[41:32] <= pte_key;
			dat_o[31:24] <= pte_asid;
			dat_o[23] <= pte_last;
			dat_o[2:0] <= pte_drwx[2:0];
			dat_o[7] <= pte_drwx[3];
		end
	3'd3:
		dat_o <= pte_vadr;
	default:	dat_o <= 1'b0;
	endcase

always @(posedge clk)
	bte_o <= bte_i;
always @(posedge clk)
	cti_o <= cti_i;
always @(posedge clk)
	sel_o <= sel_i;
`ifdef BYPASS
always @(posedge clk)
	pt_wr <= 1'b0;
always @(posedge clk)
	pt_ad <= 16'h0;
always @(posedge clk)
	pt_dati <= 42'h0;
always @(posedge clk)
	cyc_o <= cyc_i;
always @(posedge clk)
	we_o <= we_i;
always @(posedge clk)
	padr_o <= vadr_i[31:0];
always @(posedge clk)
	exv_o <= 1'b0;
always @(posedge clk)
	rdv_o <= 1'b0;
always @(posedge clk)
	wrv_o <= 1'b0;
always @(posedge clk)
	prv_o <= 1'b0;
always @(posedge clk)
	page_fault <= 1'b0;
always @(posedge clk)
	ack_o <= 1'b0;
`else
always @(posedge clk)
if (rst) begin
	cyc_o <= 1'b0;
	padr_o <= 32'hFFFC0100;
	ack_o <= 1'b0;
	exv_o <= 1'b0;
	rdv_o <= 1'b0;
	wrv_o <= 1'b0;
	prv_o <= 1'b0;
	pt_wr <= 1'b1;
	pt_ad <= 1'b0;
	pt_dati <= 1'b0;
	upd <= 1'b0;
	probe <= 1'b0;
	upd_done <= 1'b0;
	probe_done <= 1'b0;
	goto(S_IDLE);
end
else begin
	pt_wr <= 1'b0;
	page_fault <= 1'b0;
	ack_o <= 1'b0;
case(state)
// Clear page table ram on reset.
S_RESET:
	begin
		pt_ad <= pt_ad + 2'd1;
		if (&pt_ad) begin
			pt_wr <= 1'b0;
			state <= S_IDLE;
		end
	end
S_IDLE:
	if (cyc_i) begin
		if (cs_i & stb_i) begin
			ack_o <= 1'b1;
			case(vadr_i[5:3])
			3'd0:
				begin
					if (dat_i[0] & !upd_done) begin
						pt_ad <= Hash1({pte_asid,pte_vadr});
						upd <= 1'b1;
						goto(S_CMP1);
					end
					else if (dat_i[1] & !probe_done) begin
						pt_ad <= Hash1({pte_asid,pte_vadr});
						probe <= 1'b1;
						goto(S_CMP1);
					end
				end
			3'd2:	
				begin
					pte_key  <= dat_i[41:32];
					pte_asid <= dat_i[31:24];
					pte_last <= dat_i[22];
					pte_drwx <= {dat_i[7],dat_i[2:0]};
				end
			3'd3:
				begin
					pte_vadr <= dat_i[18:0];
				end
			endcase
		end
		else begin
			upd_done <= 1'b0;
			probe_done <= 1'b0;
			upd <= 1'b0;
			probe <= 1'b0;
			if (ol_i==2'b0) begin
				cyc_o <= 1'b1;
				we_o <= we_i;
				padr_o <= vadr_i[31:0];
				goto(S_ACK);
			end
			else begin
				// Video frame buffer ($00xxxxxx) and ROM / IO ($FFxxxxxx) regions are
				// not mapped.
				if (vadr_i[31:24]==8'hFF || vadr_i[31:24]==8'h00) begin
					cyc_o <= 1'b1;
					we_o <= we_i;
					padr_o <= vadr_i[31:0];
					goto(S_ACK);
				end
				else begin
					pt_ad <= Hash1({vadr_i[63:56],vadr_i});
					goto(S_CMP1);
				end
			end
		end
	end
	else begin
		exv_o <= 1'b0;
		rdv_o <= 1'b0;
		wrv_o <= 1'b0;
		prv_o <= 1'b0;
	end

S_CMP1:
	goto(S_CMP2);
S_CMP2:
	goto(S_CMP3);
S_CMP3:
	if (pt_drwx[2:0]==3'b0) begin
		if (upd) begin
			pte_key  <= 10'h0;
			pte_last <= 1'b0;
			pte_drwx <= 4'd0;
			pt_wr <= 1'b1;
			pt_dati <= {pte_key,pte_asid,pte_last,pte_vadr[18:0],pte_drwx};
			upd_done <= 1'b1;
			goto(S_IDLE);
		end
		else if (probe) begin
			pte_drwx <= 3'b0;
			pte_vadr <= 19'b0;
			pte_asid <= 8'b0;
			pte_last <= 1'b0;
			pte_key  <= 10'h0;
			probe_done <= 1'b1;
			goto(S_IDLE);
		end
		else begin
			page_fault <= 1'b1;
			goto(S_WAIT1);
		end
	end
	else if (pt_asid==vadr_i[63:56] && pt_vadr==vadr_i[31:13]) begin
		if (upd) begin
			if (keymatch) begin
				pte_key  <= pt_key;
				pte_last <= pt_last;
				pte_drwx <= pt_drwx;
				pt_wr <= 1'b1;
				pt_dati <= {pte_key,pt_dat[31:4],pte_drwx};
			end
			else
				prv_o <= 1'b1;
			upd_done <= 1'b1;
			goto(S_IDLE);
		end
		else if (probe) begin
			if (keymatch) begin
				pte_key  <= pt_key;
				pte_last <= pt_last;
				pte_drwx <= pt_drwx;
			end
			else
				prv_o <= 1'b1;
			probe_done <= 1'b1;
			goto(S_IDLE);
		end
		else if (~ack_i) begin
			if (keymatch) begin
				cyc_o <= 1'b1;
				we_o <= we_i & pt_drwx[1];
				if (!pt_drwx[1] & we_i)	wrv_o <= 1'b1;
				if (!pt_drwx[2] & ~we_i) rdv_o <= 1'b1;
				if (!pt_drwx[0] & icl_i) exv_o <= 1'b1;
				padr_o <= {pt_ad,vadr_i[12:0]};
			end
			else begin
				cyc_o <= 1'b1;
				we_o <= 1'b0;
				padr_o <= 32'hFFFFFFF8;
				prv_o <= 1'b1;
			end
			goto(S_ACK);
		end	
	end
	else begin
		if (upd|probe)
			pt_ad <= Hash2({pte_asid,pte_vadr});
		else
			pt_ad <= Hash2({vadr_i[63:56],vadr_i});
		goto(S_CMP4);
	end

S_CMP4:
	goto(S_CMP5);
S_CMP5:
	goto(S_CMP6);
S_CMP6:
	if (pt_drwx[2:0]==3'b0) begin
		if (upd) begin
			pte_key  <= 10'h0;
			pte_last <= 1'b0;
			pte_drwx <= 4'd0;
			pt_wr <= 1'b1;
			pt_dati <= {pte_key,pte_asid,pte_last,pte_vadr[18:0],pte_drwx};
			upd_done <= 1'b1;
			goto(S_IDLE);
		end
		else if (probe) begin
			pte_key  <= 10'h0;
			pte_drwx <= 43'b0;
			pte_vadr <= 19'b0;
			pte_asid <= 8'b0;
			pte_last <= 1'b0;
			probe_done <= 1'b1;
			goto(S_IDLE);
		end
		else begin
			page_fault <= 1'b1;
			goto(S_WAIT1);
		end
	end
	else if (pt_asid==vadr_i[63:56] && pt_vadr==vadr_i[31:13]) begin
		if (upd) begin
			if (keymatch) begin
				pte_key  <= pt_key;
				pte_last <= pt_last;
				pte_drwx <= pt_drwx;
				pt_wr <= 1'b1;
				pt_dati <= {pte_key,pt_dat[31:4],pte_drwx};
			end
			else
				prv_o <= 1'b1;
			upd_done <= 1'b1;
			goto(S_IDLE);
		end
		else if (probe) begin
			if (keymatch) begin
				pte_key  <= pt_key;
				pte_last <= pt_last;
				pte_drwx <= pt_drwx;
				probe_done <= 1'b1;
			end
			else
				prv_o <= 1'b1;
			goto(S_IDLE);
		end
		else if (~ack_i) begin
			if (keymatch) begin
				cyc_o <= 1'b1;
				we_o <= we_i & pt_drwx[1];
				if (!pt_drwx[1] & we_i)	wrv_o <= 1'b1;
				if (!pt_drwx[2] & ~we_i) rdv_o <= 1'b1;
				if (!pt_drwx[0] & icl_i) exv_o <= 1'b1;
				padr_o <= {pt_ad,vadr_i[12:0]};
			end
			else begin
				cyc_o <= 1'b1;
				we_o <= 1'b0;
				padr_o <= 32'hFFFFFFF8;
				prv_o <= 1'b1;
			end
			goto(S_ACK);
		end
	end
	else begin
		pt_ad <= {pt_ad+8'd65};
		goto(S_CMP4);
	end

// Wait a clock cycle for a page fault to register.
S_WAIT1:
	if (!ack_i)
		goto(S_IDLE);
	
S_ACK:
	if (ack_i) begin
		if (cti_i==3'b000 || cti_i==3'b111) begin
			cyc_o <= 1'b0;
			we_o <= 1'b0;
			goto(S_WAIT1);
		end
	end

endcase	
end
`endif

task goto;
input [3:0] nst;
begin
	state <= nst;
end
endtask

endmodule

