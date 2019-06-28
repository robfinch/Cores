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
`include "nvio-config.sv"
`define VAL		1'b1
`define INV		1'b0

module regfileValid(rst, clk, slotvd, slot_rfw, tails,
	livetarget, livetarget2, branchmiss, rob_id,
	commit0_v, commit1_v, commit2_v, commit0_id, commit1_id, commit2_id,
	commit0_tgt, commit1_tgt, commit2_tgt,
	rf_source, iq_source, iq_source2, queuedOn,
	take_branch, Rd, Rd2, rf_v, regIsValid);
parameter AREGS = 128;
parameter RBIT = 6;
parameter QENTRIES = `QENTRIES;
parameter QSLOTS = `QSLOTS;
parameter RENTRIES = `RENTRIES;
parameter VAL = 1'b1;
parameter INV = 1'b0;
input rst;
input clk;
input [QSLOTS-1:0] slotvd;
input [QSLOTS-1:0] slot_rfw;
input [`QBITS] tails [0:QSLOTS-1];
input [AREGS-1:1] livetarget;
input [AREGS-1:1] livetarget2;
input branchmiss;
input [`QBITS] rob_id [0:RENTRIES-1];
input commit0_v;
input commit1_v;
input commit2_v;
input [`RBITS] commit0_id;
input [`RBITS] commit1_id;
input [`RBITS] commit2_id;
input [RBIT:0] commit0_tgt;
input [RBIT:0] commit1_tgt;
input [RBIT:0] commit2_tgt;
input [`QBITSP1] rf_source [0:AREGS-1];
input [QENTRIES-1:0] iq_source;
input [QENTRIES-1:0] iq_source2;
input [QSLOTS-1:0] take_branch;
input [6:0] Rd [0:QSLOTS-1];
input [6:0] Rd2 [0:QSLOTS-1];
input [QSLOTS-1:0] queuedOn;
output reg [AREGS-1:0] rf_v;
output reg [AREGS-1:0] regIsValid;	// advanced signal

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

// Detect if a given register will become valid during the current cycle.
// We want a signal that is active during the current clock cycle for the read
// through register file, which trims a cycle off register access for every
// instruction. But two different kinds of assignment statements can't be
// placed under the same always block, it's a bad practice and may not work.
// So a signal is created here with it's own always block.
always @*
begin
	for (n = 1; n < AREGS; n = n + 1)
	begin
		regIsValid[n] = rf_v[n];
		if (branchmiss) begin
       if (~(livetarget[n]|livetarget2[n]))
     			regIsValid[n] = `VAL;
    end

		if (commit0_v && n=={commit0_tgt[RBIT:0]} && !rf_v[n])
			regIsValid[n] = ((rf_source[ {commit0_tgt[RBIT:0]} ][`RBITS] == commit0_id) || (branchmiss && (iq_source[ rob_id[commit0_id] ]) | iq_source2[rob_id[commit0_id]]));
		if (commit1_v && n=={commit1_tgt[RBIT:0]} && !rf_v[n])
			regIsValid[n] = ((rf_source[ {commit1_tgt[RBIT:0]} ][`RBITS] == commit1_id) || (branchmiss && (iq_source[ rob_id[commit1_id] ]) | iq_source2[rob_id[commit1_id]]));
	end
	regIsValid[0] = `VAL;
	regIsValid[64] = `VAL;
end


always @(posedge clk)
if (rst) begin
  for (n = 0; n < AREGS; n = n + 1)
    rf_v[n] <= `VAL;
end
else begin

	if (branchmiss) begin
		for (n = 1; n < AREGS; n = n + 1)
			if (~(livetarget[n]|livetarget2[n])) begin
				rf_v[n] <= `VAL;
		end
	end

  // The source for the register file data might have changed since it was
  // placed on the commit bus. So it's needed to check that the source is
  // still as expected to validate the register.
	if (commit0_v) begin
		$display("!rfv=%d %d",!rf_v[ commit0_tgt[RBIT:0] ], rf_v[ commit0_tgt[RBIT:0] ] );
    if (!rf_v[ commit0_tgt[RBIT:0] ]) begin
      rf_v[ commit0_tgt[RBIT:0] ] <= (rf_source[ commit0_tgt[RBIT:0] ][`RBITS] == commit0_id) || (branchmiss && (iq_source[ rob_id[commit0_id] ] | iq_source2[rob_id[commit0_id]]));
      $display("rfv 0: %d %d %d", rf_source[ commit0_tgt[RBIT:0]][`RBITS], commit0_id, rf_source[ commit0_tgt[RBIT:0] ][`QBIT]);
    end
  end
  if (commit1_v) begin
		$display("!rfv=%d %d",!rf_v[ commit1_tgt[RBIT:0] ], rf_v[ commit1_tgt[RBIT:0] ] );
    if (!rf_v[ commit1_tgt[RBIT:0] ]) begin //&& !(commit0_v && (rf_source[ commit0_tgt[RBIT:0] ] == commit0_id || (branchmiss && iq_source[ commit0_id[`QBITS] ]))))
      rf_v[ commit1_tgt[RBIT:0] ] <= (rf_source[ commit1_tgt[RBIT:0] ][`RBITS] == commit1_id) || (branchmiss && (iq_source[ rob_id[commit1_id] ] | iq_source2[rob_id[commit1_id]]));
      $display("rfv 1: %d %d %d", rf_source[ commit0_tgt[RBIT:0]][`RBITS], commit0_id, rf_source[ commit0_tgt[RBIT:0] ][`QBIT]);
    end
  end

	if (!branchmiss)
		case(slotvd)
		3'b000:	;
		3'b001:
			if (queuedOn[0]) begin
				if (slot_rfw[0]) begin
					rf_v [Rd[0]] <= `INV;
					rf_v [Rd2[0]] <= `INV;
				end
			end
		3'b010:
			if (queuedOn[1]) begin
				if (slot_rfw[1]) begin
					rf_v [Rd[1]] <= `INV;
					rf_v [Rd2[1]] <= `INV;
				end
			end
		3'b011:
			if (queuedOn[0]) begin
				if (slot_rfw[0]) begin
					rf_v [Rd[0]] <= `INV;
					rf_v [Rd2[0]] <= `INV;
				end
				if (queuedOn[1]) begin
					if (slot_rfw[1]) begin
						rf_v [Rd[1]] <= `INV;
						rf_v [Rd2[1]] <= `INV;
					end
				end
			end
		3'b100:
			if (queuedOn[2]) begin
				if (slot_rfw[2]) begin
					rf_v [Rd[2]] <= `INV;
					rf_v [Rd2[2]] <= `INV;
				end
			end
		3'b101:
			if (queuedOn[0]) begin
				if (slot_rfw[0]) begin
					rf_v [Rd[0]] <= `INV;
					rf_v [Rd2[0]] <= `INV;
				end
				if (queuedOn[2]) begin
					if (slot_rfw[2]) begin
						rf_v [Rd[2]] <= `INV;
						rf_v [Rd2[2]] <= `INV;
					end
				end
			end
		3'b110:
			if (queuedOn[1]) begin
				if (slot_rfw[1]) begin
					rf_v [Rd[1]] <= `INV;
					rf_v [Rd2[1]] <= `INV;
				end
				if (queuedOn[2]) begin
					if (slot_rfw[2]) begin
						rf_v [Rd[2]] <= `INV;
						rf_v [Rd2[2]] <= `INV;
					end
				end
			end
		3'b111:
			if (queuedOn[0]) begin
				if (slot_rfw[0]) begin
					rf_v [Rd[0]] <= `INV;
					rf_v [Rd2[0]] <= `INV;
				end
				if (queuedOn[1]) begin
					if (slot_rfw[1]) begin
						rf_v [Rd[1]] <= `INV;
						rf_v [Rd2[1]] <= `INV;
					end
					if (queuedOn[2]) begin
						if (slot_rfw[2]) begin
							rf_v [Rd[2]] <= `INV;
							rf_v [Rd2[2]] <= `INV;
						end
					end
				end
			end
		endcase
	rf_v[0] <= `VAL;
	rf_v[64] <= `VAL;
end

endmodule
