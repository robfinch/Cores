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

module seqnum(rst, clk, heads, hi_amt, iq_v, iq_sn, maxsn, tosub);
parameter QENTRIES = `QENTRIES;
parameter QSLOTS = `QSLOTS;
input rst;
input clk;
input [`QBITS] heads [0:QENTRIES-1];
input [2:0] hi_amt;
input [QENTRIES-1:0] iq_v;
input [`SNBITS] iq_sn [0:QENTRIES-1];
output reg [`SNBITS] maxsn;
output [`SNBITS] tosub;

integer n, j;

// Amount subtracted from sequence numbers
function [`SNBITS] sn_dec;
input [2:0] amt;
begin
	sn_dec = 1'd0;
	for (j = 0; j < QENTRIES; j = j + 1)
		if (j < amt) begin
			if (iq_v[heads[j]])
				sn_dec = iq_sn[heads[j]];
		end
end
endfunction

assign tosub = sn_dec(hi_amt);

always @*
begin
maxsn = 1'd0;
for (n = 0; n < QENTRIES; n = n + 1)
	if (iq_sn[n] > maxsn && iq_v[n])
		maxsn = iq_sn[n];
maxsn = maxsn - tosub;
end

// The following code doesn't work very well. The idea was to try and reduce
// the amount of hardware required and improve performance. Searching the queue
// for maximum sequence number is much simpler to code, but may have a lot of
// comparators.
/*
always @(posedge clk)
if (rst) begin
	maxsn <= 1'd0;
end
else begin
	maxsn <= maxsn - tosub;
	if (!branchmiss) begin
		case({slotv[0],slotv[1],slotv[2]}&{3{phit}}&ip_mask)
		3'b000:	;
		3'b001,
		3'b010,
		3'b100:
			if (canq1)
				maxsn <= maxsn - tosub + 2'd1;
		3'b011:
			if (canq2 & !debug_on && `WAYS > 1) begin
				maxsn <= maxsn - tosub + 2'd1;
				if (slot_jc[1]|take_branch[1]) begin
					;
				end
				else if (slot_jc[2]|take_branch[2])
					maxsn <= maxsn - tosub + 2'd2;
				else
					maxsn <= maxsn - tosub + 2'd2;
			end
			else if (canq1)
				maxsn <= maxsn - tosub + 2'd1;
		3'b101:
			if (canq2 & !debug_on && `WAYS > 1) begin
				maxsn <= maxsn - tosub + 2'd1;
				if (slot_jc[0]|take_branch[0]) begin
					;
				end
				else if (slot_jc[2]|take_branch[2])
					maxsn <= maxsn - tosub + 2'd2;
				else
					maxsn <= maxsn - tosub + 2'd2;
			end
			else if (canq1)
				maxsn <= maxsn - tosub + 2'd1;
		3'b110:
			if (canq2 & !debug_on & `WAYS > 1) begin
				maxsn <= maxsn - tosub + 2'd1;
				if (slot_jc[0]|take_branch[0]) begin
					;
				end
				else if (slot_jc[1]|take_branch[1])
					maxsn <= maxsn - tosub + 2'd2;
				else
					maxsn <= maxsn - tosub + 2'd2;
			end
			else if (canq1)
				maxsn <= maxsn - tosub + 2'd1;
		3'b111:
			if (canq3 & !debug_on && `WAYS > 2) begin
				maxsn <= maxsn - tosub + 2'd1;
				if (slot_jc[0]|take_branch[0]) begin
					;
				end
				else if (slot_jc[1]|take_branch[1])
					maxsn <= maxsn - tosub + 2'd2;
				else if (slot_jc[2]|take_branch[2])
					maxsn <= maxsn - tosub + 2'd3;
				else
					maxsn <= maxsn - tosub + 2'd3;
			end
			else if (canq2 & !debug_on && `WAYS > 1) begin
				maxsn <= maxsn - tosub + 2'd1;
				if (slot_jc[0]|take_branch[0]) begin
					;
				end
				else if (slot_jc[1]|take_branch[1])
					maxsn <= maxsn - tosub + 2'd2;
				else
					maxsn <= maxsn - tosub + 2'd2;
			end
			else if (canq1)
				maxsn <= maxsn - tosub + 2'd1;
		endcase
	end
end
*/

endmodule


