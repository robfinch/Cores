// ============================================================================
//        __
//   \\__/ o\    (C) 2015  Robert Finch, Stratford
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
//
// Thor SuperScaler
// ALU
//
// ============================================================================
//
`include "Thor_defines.v"

module Thor_P(fn, ra, rb, rt, pregs_i, pregs_o);
parameter DBW=64;
input [5:0] fn;
input [5:0] ra;
input [5:0] rb;
input [5:0] rt;
input [DBW-1:0] pregs_i;
output reg [DBW-1:0] pregs_o;

always @*
begin
pregs_o = pregs_i;
case (fn)
`PAND:  pregs_o[rt] = pregs_i[ra] & pregs_i[rb];
`POR:   pregs_o[rt] = pregs_i[ra] | pregs_i[rb];
`PEOR:  pregs_o[rt] = pregs_i[ra] ^ pregs_i[rb];
`PNAND: pregs_o[rt] = ~(pregs_i[ra] & pregs_i[rb]);
`PNOR:  pregs_o[rt] = ~(pregs_i[ra] | pregs_i[rb]);
`PENOR: pregs_o[rt] = ~(pregs_i[ra] ^ pregs_i[rb]);
`PANDC: pregs_o[rt] = pregs_i[ra] & ~pregs_i[rb];
`PORC:  pregs_o[rt] = pregs_i[ra] | ~pregs_i[rb];
default:    pregs_o = pregs_i;
endcase
end
endmodule
