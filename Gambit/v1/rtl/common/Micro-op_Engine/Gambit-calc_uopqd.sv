// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
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
// Calc how many micro-ops to queue. Depends on the room available and the
// length of the micro-sequence.
// ============================================================================
//
module calc_uopqd(uoq_room, uopqc, uopqd);
input [3:0] uoq_room;
input [2:0] uopqc;
output reg [2:0] uopqd;

always @*
	case(uoq_room)
	4'd0:	uopqd <= 3'd0;
	4'd1:	uopqd <= uopqc > 3'd1 ? 3'd1 : uopqc;
	4'd2:	uopqd <= uopqc > 3'd2 ? 3'd2 : uopqc;
	4'd3:	uopqd <= uopqc > 3'd3 ? 3'd3 : uopqc;
	default:	uopqd <= uopqc;
	endcase

endmodule
