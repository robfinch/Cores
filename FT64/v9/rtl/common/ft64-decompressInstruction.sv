// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	ft64-decompressInstruction.sv
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
`include ".\ft64-config.sv"
`include ".\ft64-defines.sv"

module ft64_decompressInstruction(rst, clk,
	cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i,
	pc1_i, pc2_i, instr1_i, instr2_i, canq1, canq2, doq11, doq12, doq2,
	candq1, candq2, dq1, dq2, branchmiss,
	pc1_o, pc2_o, instr1_o, instr2_o);
parameter QENTRIES = `QENTRIES;
parameter DC_ENTRIES = `DC_ENTRIES;
parameter DC_TAILS = 2;
parameter DC_HEADS = 2;
parameter INST_WID = 48;
parameter IQS_QUEUED = 3'd1;
input rst;
input clk;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [13:0] adr_i;
input [INST_WID-1:0] dat_i;
input [`ABITS] pc1_i;
input [`ABITS] pc2_i;
input [INST_WID-1:0] instr1_i;
input [INST_WID-1:0] instr2_i;
output canq1;
output canq2;
input doq11;
input doq12;
input doq2;

output candq1;
output candq2;
input dq1;
input dq2;
input branchmiss;
output [`ABITS] pc1_o;
output [`ABITS] pc2_o;
output [INST_WID-1:0] instr1_o;
output [INST_WID-1:0] instr2_o;

parameter DC_INVALID = 2'd0;
parameter DC_QUEUED = 2'd1;
parameter DC_DECOMP = 2'd2;

integer n;
reg [3:0] pos1, pos2;
reg [3:0] dc_head [0:DC_HEADS-1];
reg [3:0] dc_tail [0:DC_TAILS-1];
reg [1:0] dc_state [0:DC_ENTRIES-1];
reg [`ABITS] dc_pc [0:DC_ENTRIES-1];
reg [INST_WID-1:0] dc_instr [0:DC_ENTRIES-1];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Compute room in decompression buffer
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

reg [3:0] dc_room;
always @*
begin
	dc_room = 4'd0;
	for (n = 0; n < DC_TAILS; n = n + 1)
		if (dc_state[dc_tail[n]]==DC_INVALID)
			dc_room = dc_room + 2'd1;
end

assign canq2 = dc_room >= 4'd2;
assign canq1 = dc_room >= 4'd1;
assign candq1 = dc_state[dc_head[0]] == DC_DECOMP;
assign candq2 = candq1 && dc_state[dc_head[1]] == DC_DECOMP;

assign pc1_o = dc_pc[dc_head[0]];
assign pc2_o = dc_pc[dc_head[1]];
assign instr1_o = dc_instr[dc_head[0]];
assign instr2_o = dc_instr[dc_head[1]];
wire [INST_WID-1:0] instr1, instr2;
reg [INST_WID-1:0] instr1_d, instr2_d;
assign instr1 = dc_instr[pos1];
assign instr2 = dc_instr[pos2];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

always @(posedge clk)
if (rst) begin
	for (n = 0; n < DC_ENTRIES; n = n + 1) begin
		dc_state[n] <= DC_INVALID;
		dc_pc[n] <= 1'd0;
		dc_instr[n] <= 1'd0;
	end
	for (n = 0; n < DC_TAILS; n = n + 1)
		dc_tail[n] <= n;
	for (n = 0; n < DC_HEADS; n = n + 1)
		dc_head[n] <= n;
end
else begin
	if (branchmiss) begin
		for (n = 0; n < DC_ENTRIES; n = n + 1)
			dc_state[n] <= DC_INVALID;
		for (n = 0; n < DC_TAILS; n = n + 1)
			dc_tail[n] <= n;
		for (n = 0; n < DC_HEADS; n = n + 1)
			dc_head[n] <= n;
	end
	else begin
		if (doq2) begin
			dc_pc[dc_tail[0]] <= pc1_i;
			dc_pc[dc_tail[1]] <= pc2_i;
			dc_instr[dc_tail[0]] <= instr1_i;
			dc_instr[dc_tail[1]] <= instr2_i;
			dc_tail[0] <= (dc_tail[0] + 2'd2) % DC_ENTRIES;
			dc_tail[1] <= (dc_tail[1] + 2'd2) % DC_ENTRIES;
			dc_state[0] <= DC_QUEUED;
			dc_state[1] <= DC_QUEUED;
		end
		else if (doq11) begin
			dc_pc[dc_tail[0]] <= pc1_i;
			dc_instr[dc_tail[0]] <= instr1_i;
			dc_tail[0] <= (dc_tail[0] + 2'd1) % DC_ENTRIES;
			dc_state[0] <= DC_QUEUED;
		end
		else if (doq12) begin
			dc_pc[dc_tail[0]] <= pc2_i;
			dc_instr[dc_tail[0]] <= instr2_i;
			dc_tail[0] <= (dc_tail[0] + 2'd1) % DC_ENTRIES;
			dc_state[0] <= DC_QUEUED;
		end
	end
	if (dq2) begin
		dc_state[dc_head[0]] <= DC_INVALID;
		dc_state[dc_head[1]] <= DC_INVALID;
		for (n = 0; n < DC_HEADS; n = n + 1)
			dc_head[n] <= (dc_head[n] + 2'd2) % DC_ENTRIES;
	end
	else if (dq1) begin
		dc_state[dc_head[0]] <= DC_INVALID;
		for (n = 0; n < DC_HEADS; n = n + 1)
			dc_head[n] <= (dc_head[n] + 2'd2) % DC_ENTRIES;
	end
	if (pos1 != 4'hF) begin
		dc_instr[pos1] <= instr1_d;
		dc_state[pos1] <= DC_DECOMP;
	end
	if (pos2 != 4'hF) begin
		dc_instr[pos2] <= instr2_d;
		dc_state[pos2] <= DC_DECOMP;
	end
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Select instructions to decompress.
// Searches the entire queue for instructions waiting to be decompressed. The
// search does not take into consideration which instructions are closest to
// the head of the queue as instructions can be decompressed at a rate equal
// to the queue rate there should never be more than a couple of instructions
// waiting for decompress.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

always @*
begin
	pos1 = {4{1'b1}};
	pos2 = {4{1'b1}};
	for (n = 0; n < DC_ENTRIES; n = n + 1)
		if (dc_state[n]==DC_QUEUED) begin
			if (pos1 != {4{1'b1}}) begin	// pos1 already assigned?
				if (pos2 == {4{1'b1}})			// can we assign pos2?
					pos2 = n;
			end
			else
				pos1 = n;
		end
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Table of decompressed instructions.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
assign ack_o = cs_i & cyc_i & stb_i;
`ifdef SUPPORT_DCI
reg [47:0] DecompressTable [0:2047];
reg [10:0] adr1, adr2;
always @*
	adr1 <= {cmpgrp,instr1[15:8]};
always @*
	adr2 <= {cmpgrp,instr2[15:8]};
always @(posedge clk)
	if (cs_i & cyc_i & stb_i & we_i)
		DecompressTable[adr_i[13:3]] <= dat_i[47:0];
reg [INST_WID-1:0] expand1, expand2;
always @*
	expand1 <= DecompressTable[adr1];
always @*
	expand2 <= DecompressTable[adr2];
`endif

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

wire [INST_WID-1:0] dcinstr1, dcinstr2;

ft64_iexpander uie1 (instr1[15:0],dcinstr1);
ft64_iexpander uie2 (instr2[15:0],dcinstr2);

always @*
casez(instr1[7:0])
`ifdef SUPPORT_DCI
`CMPRSSD:	instr1_d <= expand1;
`endif
8'b1???????:	instr1_d <= dcinstr1;
default:	instr1_d <= dc_instr[pos1];
endcase

always @*
casez(instr2[7:0])
`ifdef SUPPORT_DCI
`CMPRSSD:	instr2_d <= expand2;
`endif
8'b1???????:	instr2_d <= dcinstr2;
default:	instr2_d <= dc_instr[pos2];
endcase

endmodule
