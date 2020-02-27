// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@fintron.ca
//       ||
//
//	vid_counter.v
//		generic counter
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
module vid_counter(rst, clk, ce, ld, d, q, tc);
parameter WID=12;
parameter pMaxCnt={WID{1'b1}};
input rst;
input clk;
input ce;
input ld;
input [WID:1] d;
output [WID:1] q;
reg [WID:1] q;
output tc;

assign tc = &q;

always @(posedge clk)
if (rst)
	q <= 1'b0;
else begin
	if (ld)
		q <= d;
	else if (ce & tc)
		q <= 1'b0;
	else if (ce)
		q <= q + 1'b1;
end

endmodule
