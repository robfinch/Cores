// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
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
`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-types.sv"

module agen(inst, IsIndexed, src1, src2, src3, ma, idle);
parameter AMSB = `AMSB;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input Instruction inst;
input IsIndexed;
input Address src1;
input Address src2;
input Address src3;
output Address ma;
output idle;

assign idle = 1'b1;

always @*
	if (IsIndexed)
		ma <= src2 + (src3 << inst.rr.padr[1:0]);
	else
		ma <= src1 + src2;


endmodule
