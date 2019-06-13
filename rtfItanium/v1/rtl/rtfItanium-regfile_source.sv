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

module regfile_source(rst, clk, branchmiss, slotvd, slot_rfw,
	queuedOn,	Rd, tails, iq_latestID, iq_tgt, rf_source);
parameter AREGS = 128;
parameter QENTRIES = `QENTRIES;
parameter RENTRIES = `RENTRIES;
parameter QSLOTS = `QSLOTS;
parameter RBIT = 6;
input rst;
input clk;
input branchmiss;
input [QSLOTS-1:0] slotvd;
input [QENTRIES-1:0] slot_rfw;
input [QSLOTS-1:0] queuedOn;
input [RBIT:0] Rd [0:QSLOTS-1];
input [`QBITS] tails [0:QSLOTS-1];
input [AREGS-1:1] iq_latestID [0:QENTRIES-1];
input [RBIT:0] iq_tgt [0:QENTRIES-1];
output reg [`QBITS] rf_source [0:AREGS-1];

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
		for (n = 0; n < QENTRIES; n = n + 1)
    	if (|iq_latestID[n])
    		rf_source[ {iq_tgt[n][RBIT:0]} ] <= n[`QBITS];
	end
	else begin
		// Setting the rf valid and source
		case(slotvd)
		3'b000:	;
		3'b001:
			if (queuedOn[0]) begin
				if (slot_rfw[0])
					rf_source[Rd[0]] <= tails[0];
			end
		3'b010:
			if (queuedOn[1]) begin
				if (slot_rfw[1]) begin
					rf_source[Rd[1]] <= tails[0];
				end
			end
		3'b011:
			if (queuedOn[0]) begin
				if (slot_rfw[0])
					rf_source[Rd[0]] <= tails[0];
				if (queuedOn[1]) begin
					if (slot_rfw[1])
						rf_source[Rd[1]] <= tails[1];
				end
			end
		3'b100:
			if (queuedOn[2]) begin
				if (slot_rfw[2])
					rf_source[Rd[2]] <= tails[0];
			end
		3'b101:
			if (queuedOn[0]) begin
				if (slot_rfw[0])
					rf_source[Rd[0]] <= tails[0];
				if (queuedOn[2]) begin
					if (slot_rfw[2])
						rf_source[Rd[2]] <= tails[1];
				end
			end
		3'b110:
			if (queuedOn[1]) begin
				if (slot_rfw[1])
					rf_source[Rd[1]] <= tails[0];
				if (queuedOn[2]) begin
					if (slot_rfw[2])
						rf_source[Rd[2]] <= tails[1];
				end
			end
		3'b111:
			if (queuedOn[0]) begin
				if (slot_rfw[0])
					rf_source[Rd[0]] <= tails[0];
				if (queuedOn[1]) begin
					if (slot_rfw[1])
						rf_source[Rd[1]] <= tails[1];
					if (queuedOn[2]) begin
						if (slot_rfw[2])
							rf_source[Rd[2]] <= tails[2];
					end
				end
			end
		endcase
	end
	rf_source[0] <= {`QBIT{1'b1}};
	rf_source[64] <= {`QBIT{1'b1}};
end

endmodule
