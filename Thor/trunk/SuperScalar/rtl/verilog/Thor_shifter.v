// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
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
// Thor SuperScalar
// Shift logic
//
// ============================================================================
//
`include "Thor_defines.v"

module Thor_shifter(func, a, b, o);
parameter DBW=64;
input [5:0] func;
input [DBW-1:0] a;
input [DBW-1:0] b;
output reg [DBW-1:0] o;

wire [DBW*2-1:0] shlo = {{DBW{1'd0}},a} << b[5:0];
wire [DBW*2-1:0] shruo = {a,{DBW{1'b0}}} >> b[5:0];
wire signed [DBW-1:0] as = a;
wire signed [DBW-1:0] shro = as >> b[5:0];

always @(func or shlo or shro or shruo)
case(func)
`SHL,`SHLU,`SHLI,`SHLUI:
	o <= shlo[DBW-1:0];
`SHR,`SHRI:
	o <= shro;
`SHRU,`SHRUI:
	o <= shruo[DBW*2-1:DBW];
`ROL,`ROLI:
	o <= shlo[DBW*2-1:DBW]|shlo[DBW-1:0];
`ROR,`RORI:
	o <= shruo[DBW*2-1:DBW]|shruo[DBW-1:0];
default:	o <= 64'hDEADDEADDEADDEAD;
endcase

endmodule
