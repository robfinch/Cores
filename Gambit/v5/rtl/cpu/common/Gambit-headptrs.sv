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

// Pointers to the head of the queue. The pointers increment every cycle by
// the number of instructions that were committed during the cycle.

module headptrs(rst, clk, amt, heads, ramt, rob_heads, headcnt);
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter RENTRIES = `RENTRIES;
parameter RSLOTS = `RSLOTS;
input rst;
input clk;
input [2:0] amt;
output reg [`QBITS] heads [0:IQ_ENTRIES-1];
input [2:0] ramt;
output reg [`RBITS] rob_heads [0:RENTRIES-1];
output reg [31:0] headcnt;

integer n;

always @(posedge clk)
if (rst) begin
	headcnt <= 0;
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
		heads[n] <= n;
end
else begin
	headcnt <= headcnt + amt;
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
     heads[n] <= (heads[n] + amt) % IQ_ENTRIES;
end

always @(posedge clk)
if (rst) begin
	for (n = 0; n < RENTRIES; n = n + 1)
		rob_heads[n] <= n;
end
else begin
	for (n = 0; n < RENTRIES; n = n + 1)
    rob_heads[n] <= (rob_heads[n] + ramt) % RENTRIES;
end

endmodule
