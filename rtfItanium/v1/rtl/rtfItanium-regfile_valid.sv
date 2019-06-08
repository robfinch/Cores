// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
`include "rtfItanium-config.sv"
`define VAL		1'b1
`define INV		1'b0

module regfile_valid(rst, clk, phit, ip_mask, slotvd, slot_rfw, slot_jc, tails,
	livetarget, branchmiss,
	commit0_v, commit1_v, commit0_id, commit1_id, commit0_tgt, commit1_tgt,
	rf_source, iq_source, queuedCnt,
	take_branch, Rd, rf_v, debug_on);
parameter AREGS = 128;
parameter RBIT = 6;
parameter QENTRIES = `QENTRIES;
parameter QSLOTS = `QSLOTS;
parameter VAL = 1'b1;
parameter INV = 1'b0;
input rst;
input clk;
input phit;
input [QSLOTS-1:0] ip_mask;
input [QSLOTS-1:0] slotvd;
input [QSLOTS-1:0] slot_rfw;
input [QSLOTS-1:0] slot_jc;
input [`QBITS] tails [0:QSLOTS-1];
input [AREGS-1:0] livetarget;
input branchmiss;
input commit0_v;
input commit1_v;
input [`QBITS] commit0_id;
input [`QBITS] commit1_id;
input [RBIT:0] commit0_tgt;
input [RBIT:0] commit1_tgt;
input [`QBITS] rf_source [0:AREGS-1];
input [QENTRIES-1:0] iq_source;
input [QSLOTS-1:0] take_branch;
input [6:0] Rd [0:QSLOTS-1];
input [2:0] queuedCnt;
output reg [AREGS-1:0] rf_v;
input debug_on;

// The following two functions used to figure out which slot to process.
// However, the functions when used things seemed not to work.
// Find first one
function [2:0] ffo;
input [2:0] i;
casez(i)
3'b1??:  ffo <= 3'd0;
3'b01?:  ffo <= 3'd1;
3'b001:  ffo <= 3'd2;
default:    ffo <= 3'd0;
endcase
endfunction

// Find second one bit
function [2:0] fso;
input [2:0] i;
casez(i)
3'b11?:  fso <= 3'd1;
3'b011:  fso <= 3'd2;
3'b001:  fso <= 3'd0;
3'b101:	 fso <= 3'd2;
default:    fso <= 3'd0;
endcase
endfunction

integer n;
wire [2:0] pat = {slotvd[0],slotvd[1],slotvd[2]} & {3{phit}} & ip_mask;

always @(posedge clk)
if (rst) begin
  for (n = 0; n < AREGS; n = n + 1)
    rf_v[n] <= `VAL;
end
else begin

	if (branchmiss) begin
		for (n = 1; n < AREGS; n = n + 1)
			if (~livetarget[n]) begin
				rf_v[n] <= `VAL;
		end
	end

  // The source for the register file data might have changed since it was
  // placed on the commit bus. So it's needed to check that the source is
  // still as expected to validate the register.
	if (commit0_v) begin
    if (!rf_v[ {commit0_tgt[RBIT:0]} ])
      rf_v[ {commit0_tgt[RBIT:0]} ] <= rf_source[ commit0_tgt[RBIT:0] ] == commit0_id || (branchmiss && iq_source[ commit0_id[`QBITS] ]);
  end
  if (commit1_v && `NUM_CMT > 1) begin
    if (!rf_v[ {commit1_tgt[RBIT:0]} ] && !(commit0_v && (rf_source[ commit0_tgt[RBIT:0] ] == commit0_id || (branchmiss && iq_source[ commit0_id[`QBITS] ]))))
      rf_v[ {commit1_tgt[RBIT:0]} ] <= rf_source[ commit1_tgt[RBIT:0] ] == commit1_id || (branchmiss && iq_source[ commit1_id[`QBITS] ]);
  end

	if (!branchmiss)
		case(slotvd)
		3'b000:	;
		3'b100:
			if (queuedCnt==3'd1) begin
				if (slot_rfw[2])
					rf_v [Rd[2]] <= `INV;
			end
		3'b010:
			if (queuedCnt==3'd1) begin
				if (slot_rfw[1])
					rf_v [Rd[1]] <= `INV;
			end
		3'b001:
			if (queuedCnt==3'd1) begin
				if (slot_rfw[0])
					rf_v [Rd[0]] <= `INV;
			end
		3'b110:
			if (queuedCnt==3'd2) begin
				if (slot_rfw[1])
					rf_v [Rd[1]] <= `INV;
				if (!(slot_jc[1]|take_branch[1])) begin
					if (slot_rfw[2])
						rf_v [Rd[2]] <= `INV;
				end
			end
			else if (queuedCnt==3'd1) begin
				if (slot_rfw[1])
					rf_v [Rd[1]] <= `INV;
			end
		3'b101:
			if (queuedCnt==3'd2) begin
				if (slot_rfw[0])
					rf_v [Rd[0]] <= `INV;
				if (!(slot_jc[0]|take_branch[0])) begin
					if (slot_rfw[1])
						rf_v [Rd[1]] <= `INV;
				end
			end
			else if (queuedCnt==3'd1) begin
				if (slot_rfw[0])
					rf_v [Rd[0]] <= `INV;
			end
		3'b011:
			if (queuedCnt==3'd2) begin
				if (slot_rfw[0])
					rf_v [Rd[0]] <= `INV;
				if (!(slot_jc[0]|take_branch[0])) begin
					if (slot_rfw[1])
						rf_v [Rd[1]] <= `INV;
				end
			end
			else if (queuedCnt==3'd1) begin
				if (slot_rfw[0])
					rf_v [Rd[0]] <= `INV;
			end
		3'b111:
			if (queuedCnt==3'd3) begin
				if (slot_jc[0]|take_branch[0]) begin
					if (slot_rfw[0])
						rf_v [Rd[0]] <= `INV;
				end
				else if (slot_jc[1]|take_branch[1]) begin
					if (slot_rfw[0])
						rf_v [Rd[0]] <= `INV;
					if (slot_rfw[1])
						rf_v [Rd[1]] <= `INV;
				end
				else if (slot_jc[2]|take_branch[2]) begin
					if (slot_rfw[0])
						rf_v [Rd[0]] <= `INV;
					if (slot_rfw[1])
						rf_v [Rd[1]] <= `INV;
					if (slot_rfw[2])
						rf_v [Rd[2]] <= `INV;
				end
				else begin
					if (slot_rfw[0])
						rf_v [Rd[0]] <= `INV;
					if (slot_rfw[1])
						rf_v [Rd[1]] <= `INV;
					if (slot_rfw[2])
						rf_v [Rd[2]] <= `INV;
				end
			end
			else if (queuedCnt==3'd2) begin
				if (slot_rfw[0])
					rf_v [Rd[0]] <= `INV;
				if (slot_jc[0]|take_branch[0]) begin
					;
				end
				else if (slot_jc[1]|take_branch[1]) begin
					if (slot_rfw[1])
						rf_v [Rd[1]] <= `INV;
				end
				else begin
					if (slot_rfw[1])
						rf_v [Rd[1]] <= `INV;
				end
			end
			else if (queuedCnt==3'd1) begin
				if (slot_rfw[0])
					rf_v [Rd[0]] <= `INV;
			end
		endcase
	rf_v[0] <= `VAL;
	rf_v[64] <= `VAL;
end

endmodule
