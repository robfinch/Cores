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

module next_bundle(rst, slotv, branchmiss, canq1, canq2, canq3, phit, ip_mask, 
	next, debug_on);
parameter QSLOTS = `QSLOTS;
input rst;
input [QSLOTS-1:0] slotv;
input branchmiss;
input canq1;
input canq2;
input canq3;
input phit;
input [QSLOTS-1:0] ip_mask;
output reg next;
input debug_on;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

always @*
if (rst)
	next <= TRUE;
else begin
	if (slotv==3'b000 && phit)
		next <= TRUE;
	else
		next <= FALSE;
end

endmodule
