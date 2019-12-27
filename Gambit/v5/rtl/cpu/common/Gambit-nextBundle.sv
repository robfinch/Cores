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
`include "..\inc\Gambit-config.sv"

module next_bundle(rst, slotv, phit, next);
parameter QSLOTS = `QSLOTS;
input rst;
input [QSLOTS-1:0] slotv;
input phit;
output reg next;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

always @*
if (rst)
	next <= TRUE;
else begin
	if (slotv==2'b00 && phit)
		next <= TRUE;
	else
		next <= FALSE;
end

endmodule
