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
`include "Gambit-defines.sv"

module agen(wrap, src1, src2, ma, idle);
parameter AMSB = `AMSB;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input wrap;
input [AMSB:0] src1;
input [AMSB:0] src2;
output reg [AMSB:0] ma;
output idle;

assign idle = 1'b1;

always @*
	if (wrap)
		ma <= {src1[AMSB:8],src1[7:0] + src2[7:0]};
	else
		ma <= src1 + src2;


endmodule
