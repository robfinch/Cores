// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
module ram_ar1w1r(clk, ce, we, wa, ra, i, o);
parameter WID=8;
parameter DEP=32;
input clk;
input ce;
input we;
input [$clog2(DEP)-1:0] wa;
input [$clog2(DEP)-1:0] ra;
input [WID-1:0] i;
output [WID-1:0] o;

reg [WID-1:0] mem [0:DEP-1];

always @(posedge clk)
	if (ce & we)
		mem[wa] <= i;

assign o = mem[ra];

endmodule

