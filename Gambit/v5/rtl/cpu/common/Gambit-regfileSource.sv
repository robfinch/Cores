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
// 18854
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-types.sv"
`define VAL		1'b1
`define INV		1'b0

module regfileSource(rst, clk, branchmiss, heads, slotv, slot_rfw,
	queuedOn,	rqueuedOn, iq_state, iq_rfw, Rd, rob_tails,
	iq_latestID, iq_tgt, iq_rid, rf_source);
parameter AREGS = 128;
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter RENTRIES = `RENTRIES;
parameter QSLOTS = `QSLOTS;
parameter RBIT = 5;
input rst;
input clk;
input branchmiss;
input Qid heads [0:IQ_ENTRIES-1];
input [QSLOTS-1:0] slotv;
input [IQ_ENTRIES-1:0] slot_rfw;
input [QSLOTS-1:0] queuedOn;
input [IQ_ENTRIES-1:0] rqueuedOn;
input QState iq_state [0:IQ_ENTRIES-1];
input [IQ_ENTRIES-1:0] iq_rfw;
input [RBIT+1:0] Rd [0:QSLOTS-1];
input Rid rob_tails [0:QSLOTS-1];
input [AREGS-1:0] iq_latestID [0:IQ_ENTRIES-1];
input [RBIT+1:0] iq_tgt [0:IQ_ENTRIES-1];
input Rid iq_rid [0:IQ_ENTRIES-1];
output Rid rf_source [0:AREGS-1];

integer n;

initial begin
for (n = 0; n < AREGS; n = n + 1)
	rf_source[n] = 1'b0;
end

always @(posedge clk)
if (rst) begin
  for (n = 0; n < AREGS; n = n + 1) begin
    rf_source[n] <= {`QBIT{1'b1}};
  end
end
else begin
	if (branchmiss) begin
		for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
    	if (|iq_latestID[n])
    		rf_source[ iq_tgt[n] ] <= {{`QBIT{1'b0}},iq_rid[n]};
			if (iq_rid[n] >= IQ_ENTRIES)
				$stop;
    end
	end
	else begin
		// Setting the rf valid and source
		case(slotv)
		2'b00:	;
		2'b01:
			if (queuedOn[0]) begin
				if (slot_rfw[0])
					rf_source[Rd[0]] <= {{`QBIT{1'b0}},rob_tails[0]};
			end
		2'b10:
			if (queuedOn[1]) begin
				if (slot_rfw[1])
					rf_source[Rd[1]] <= {{`QBIT{1'b0}},rob_tails[0]};
			end
		2'b11:
			if (queuedOn[0]) begin
				if (slot_rfw[0])
					rf_source[Rd[0]] <= {{`QBIT{1'b0}},rob_tails[0]};
				if (queuedOn[1]) begin
					if (slot_rfw[1])
						rf_source[Rd[1]] <= {{`QBIT{1'b0}},rob_tails[1]};
				end
			end
		endcase
		for (n = 0; n < QSLOTS; n = n + 1)
			if (rob_tails[n] >= IQ_ENTRIES)
				$stop;
		for (n = 0; n < IQ_ENTRIES; n = n + 1)
			if (iq_rid[n] >= IQ_ENTRIES)
				$stop;
	end
end

endmodule
