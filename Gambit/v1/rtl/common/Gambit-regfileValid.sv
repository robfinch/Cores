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
`include "Gambit-config.sv"
`define VAL		1'b1
`define INV		1'b0

module regfileValid(rst, clk, slotv, slot_rfw, tails,
	livetarget, branchmiss, rob_id,
	commit0_v, commit1_v, commit2_v,
	commit0_id, commit1_id, commit2_id,
	commit0_tgt, commit1_tgt, commit2_tgt,
	commit0_rfw, commit1_rfw, commit2_rfw,
	commit0_sr_tgts, commit1_sr_tgts, commit2_sr_tgts,
	rf_source, sr_source, iq_source, queuedOn, iq_latest_sr_ID,
	slot_sr_tgts, iq_sr_source,
	Rd, rf_v, regIsValid);
parameter AREGS = 32;
parameter RBIT = 4;
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter QSLOTS = `QSLOTS;
parameter RENTRIES = `RENTRIES;
parameter VAL = 1'b1;
parameter INV = 1'b0;
input rst;
input clk;
input [QSLOTS-1:0] slotv;
input [QSLOTS-1:0] slot_rfw;
input [`QBITS] tails [0:QSLOTS-1];
input [AREGS-1:0] livetarget;
input branchmiss;
input [`QBITS] rob_id [0:RENTRIES-1];
input commit0_v;
input commit1_v;
input commit2_v;
input [`RBITS] commit0_id;
input [`RBITS] commit1_id;
input [`RBITS] commit2_id;
input [RBIT+1:0] commit0_tgt;
input [RBIT+1:0] commit1_tgt;
input [RBIT+1:0] commit2_tgt;
input [7:0] commit0_sr_tgts;
input [7:0] commit1_sr_tgts;
input [7:0] commit2_sr_tgts;
input commit0_rfw;
input commit1_rfw;
input commit2_rfw;
input [`QBITSP1] rf_source [0:AREGS-1];
input [`QBITSP1] sr_source;
input [IQ_ENTRIES-1:0] iq_source;
input [IQ_ENTRIES-1:0] iq_sr_source;
input [RBIT+1:0] Rd [0:QSLOTS-1];
input [QSLOTS-1:0] queuedOn;
input [`QBITS] iq_latest_sr_ID;
input [7:0] slot_sr_tgts [0:QSLOTS-1];
output reg [AREGS:0] rf_v;
output reg [AREGS:0] regIsValid;	// advanced signal

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
       if (~(livetarget[n]))
     			regIsValid[n] = `VAL;
    end

		if (commit0_v && n==commit0_tgt && !rf_v[n] && commit0_rfw)
			regIsValid[n] = ((rf_source[ n ][`RBITS] == commit0_id) || (branchmiss && (iq_source[ rob_id[commit0_id] ])));
		if (commit1_v && n==commit1_tgt && !rf_v[n] && commit1_rfw)
			regIsValid[n] = ((rf_source[ n ][`RBITS] == commit1_id) || (branchmiss && (iq_source[ rob_id[commit1_id] ])));
		if (commit2_v && n==commit2_tgt && !rf_v[n] && commit2_rfw)
			regIsValid[n] = ((rf_source[ n ][`RBITS] == commit2_id) || (branchmiss && (iq_source[ rob_id[commit2_id] ])));
	end
	regIsValid[AREGS] <= rf_v[AREGS];
	if (branchmiss)
		if (iq_latest_sr_ID=={`QBIT{1'b1}})
			regIsValid[AREGS] <= `VAL;
	
	if (commit0_v && !rf_v[AREGS] && commit0_sr_tgts != 8'h00)
		regIsValid[AREGS] = ((sr_source[`RBITS] == commit0_id) || (branchmiss && (iq_sr_source[ rob_id[commit0_id] ])));
	if (commit1_v && !rf_v[AREGS] && commit1_sr_tgts != 8'h00)
		regIsValid[AREGS] = ((sr_source[`RBITS] == commit1_id) || (branchmiss && (iq_sr_source[ rob_id[commit1_id] ])));
	if (commit2_v && !rf_v[AREGS] && commit2_sr_tgts != 8'h00)
		regIsValid[AREGS] = ((sr_source[`RBITS] == commit2_id) || (branchmiss && (iq_sr_source[ rob_id[commit2_id] ])));
	regIsValid[0] = `VAL;
end


always @(posedge clk)
if (rst) begin
  for (n = 0; n <= AREGS; n = n + 1)
    rf_v[n] <= `VAL;
end
else begin

	if (branchmiss) begin
		for (n = 1; n < AREGS; n = n + 1)
			if (~(livetarget[n])) begin
				rf_v[n] <= `VAL;
		end
		if (iq_latest_sr_ID=={`QBIT{1'b1}})
			rf_v[AREGS] <= `VAL;
	end

  // The source for the register file data might have changed since it was
  // placed on the commit bus. So it's needed to check that the source is
  // still as expected to validate the register.
	if (commit0_v && commit0_rfw) begin
		$display("!rfv=%d %d",!rf_v[ commit0_tgt ], rf_v[ commit0_tgt ] );
    if (!rf_v[ commit0_tgt ]) begin
      rf_v[ commit0_tgt ] <= (rf_source[ commit0_tgt ][`RBITS] == commit0_id) || (branchmiss && (iq_source[ rob_id[commit0_id] ]));
      $display("rfv 0: %d %d %d", rf_source[ commit0_tgt][`RBITS], commit0_id, rf_source[ commit0_tgt ][`QBIT]);
    end
  end
  if (commit1_v && commit1_rfw) begin
		$display("!rfv=%d %d",!rf_v[ commit1_tgt ], rf_v[ commit1_tgt] );
    if (!rf_v[ commit1_tgt ]) begin //&& !(commit0_v && (rf_source[ commit0_tgt[RBIT:0] ] == commit0_id || (branchmiss && iq_source[ commit0_id[`QBITS] ]))))
      rf_v[ commit1_tgt ] <= (rf_source[ commit1_tgt ][`RBITS] == commit1_id) || (branchmiss && (iq_source[ rob_id[commit1_id] ]));
      $display("rfv 1: %d %d %d", rf_source[ commit0_tgt ][`RBITS], commit0_id, rf_source[ commit0_tgt ][`QBIT]);
    end
  end
  if (commit2_v && commit2_rfw) begin
		$display("!rfv=%d %d",!rf_v[ commit2_tgt ], rf_v[ commit2_tgt ] );
    if (!rf_v[ commit2_tgt ]) begin //&& !(commit0_v && (rf_source[ commit0_tgt[RBIT:0] ] == commit0_id || (branchmiss && iq_source[ commit0_id[`QBITS] ]))))
      rf_v[ commit2_tgt ] <= (rf_source[ commit2_tgt ][`RBITS] == commit2_id) || (branchmiss && (iq_source[ rob_id[commit2_id] ]));
    end
  end

	if (commit0_v && commit0_sr_tgts != 8'h00) begin
    if (!rf_v[ AREGS ]) begin
      rf_v[ AREGS ] <= (sr_source[`RBITS] == commit0_id) || (branchmiss && (iq_sr_source[ rob_id[commit0_id] ]));
    end
  end
  if (commit1_v && commit1_sr_tgts != 8'h00) begin
    if (!rf_v[ AREGS ]) begin //&& !(commit0_v && (rf_source[ commit0_tgt[RBIT:0] ] == commit0_id || (branchmiss && iq_source[ commit0_id[`QBITS] ]))))
      rf_v[ AREGS ] <= (sr_source[`RBITS] == commit1_id) || (branchmiss && (iq_sr_source[ rob_id[commit1_id] ]));
    end
  end
  if (commit2_v && commit2_sr_tgts != 8'h00) begin
    if (!rf_v[ AREGS ]) begin //&& !(commit0_v && (rf_source[ commit0_tgt[RBIT:0] ] == commit0_id || (branchmiss && iq_source[ commit0_id[`QBITS] ]))))
      rf_v[ AREGS ] <= (sr_source[`RBITS] == commit2_id) || (branchmiss && (iq_sr_source[ rob_id[commit2_id] ]));
    end
  end

	$display("slot_rfw: %h", slot_rfw);
	$display("quedon : %h", queuedOn);
	$display("slotv: %h", slotv);
	if (!branchmiss)
		case(slotv)
		3'b000:	;
		3'b001:
			if (queuedOn[0]) begin
				if (slot_rfw[0]) begin
					rf_v [Rd[0]] <= `INV;
				end
				if (slot_sr_tgts[0] != 8'h00)
					rf_v[AREGS] <= `INV;
			end
		3'b010:
			if (queuedOn[1]) begin
				if (slot_rfw[1]) begin
					rf_v [Rd[1]] <= `INV;
				end
				if (slot_sr_tgts[1] != 8'h00)
					rf_v[AREGS] <= `INV;
			end
		3'b011:
			begin
				if (queuedOn[0]) begin
					if (slot_rfw[0]) begin
						rf_v [Rd[0]] <= `INV;
					end
					if (slot_sr_tgts[0] != 8'h00)
						rf_v[AREGS] <= `INV;
				end
				if (queuedOn[1]) begin
					if (slot_rfw[1]) begin
						rf_v [Rd[1]] <= `INV;
					end
					if (slot_sr_tgts[1] != 8'h00)
						rf_v[AREGS] <= `INV;
				end
			end
		3'b100:
			if (queuedOn[2]) begin
				if (slot_rfw[2]) begin
					rf_v [Rd[2]] <= `INV;
				end
				if (slot_sr_tgts[2] != 8'h00)
					rf_v[AREGS] <= `INV;
			end
		3'b101:
			begin
				if (queuedOn[0]) begin
					if (slot_rfw[0]) begin
						rf_v [Rd[0]] <= `INV;
					end
					if (slot_sr_tgts[0] != 8'h00)
						rf_v[AREGS] <= `INV;
				end
				if (queuedOn[2]) begin
					if (slot_rfw[2]) begin
						rf_v [Rd[2]] <= `INV;
					end
					if (slot_sr_tgts[2] != 8'h00)
						rf_v[AREGS] <= `INV;
				end
			end
		3'b110:
			begin
				if (queuedOn[1]) begin
					if (slot_rfw[1]) begin
						rf_v [Rd[1]] <= `INV;
					end
					if (slot_sr_tgts[1] != 8'h00)
						rf_v[AREGS] <= `INV;
				end
				if (queuedOn[2]) begin
					if (slot_rfw[2]) begin
						rf_v [Rd[2]] <= `INV;
					end
					if (slot_sr_tgts[2] != 8'h00)
						rf_v[AREGS] <= `INV;
				end
			end
		3'b111:
			begin
				if (queuedOn[0]) begin
					if (slot_rfw[0]) begin
						$display("setting inv0:%h",Rd[0]);
						rf_v [Rd[0]] <= `INV;
					end
					if (slot_sr_tgts[0] != 8'h00)
						rf_v[AREGS] <= `INV;
				end
				if (queuedOn[1]) begin
					if (slot_rfw[1]) begin
						$display("setting inv1:%h",Rd[1]);
						rf_v [Rd[1]] <= `INV;
					end
					if (slot_sr_tgts[1] != 8'h00)
						rf_v[AREGS] <= `INV;
				end
				if (queuedOn[2]) begin
					if (slot_rfw[2]) begin
						$display("setting inv2:%h",Rd[2]);
						rf_v [Rd[2]] <= `INV;
					end
					if (slot_sr_tgts[2] != 8'h00)
						rf_v[AREGS] <= `INV;
				end
			end
		endcase
	rf_v[0] <= `VAL;
end

endmodule
