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
`include "rtfItanium-defines.sv"

module agen(unit, inst, a, b, c, ma, idle);
input [2:0] unit;
input [39:0] inst;
input [79:0] a;
input [79:0] b;
input [79:0] c;
output reg [79:0] ma;
output idle;

assign idle = 1'b1;
reg [80:0] cx;

always @*
case(inst[30:28])
3'd0:	cx <= c;
3'd1:	cx <= c << 1;
3'd2:	cx <= c << 2;
3'd3:	cx <= c << 3;
3'd4:	cx <= c << 4;
3'd5:	cx <= (c << 2) + c;					// * 5
3'd6: cx <= (c << 3) + (c << 1);	// * 10
3'd7:	cx <= (c << 4) - c;					// * 15
endcase

function [5:0] mopcode;
input [39:0] ins;
mopcode = {ins[34:33],ins[9:6]};
endfunction

always @*
casez(mopcode(inst))
`LOAD:
	case(mopcode(inst))
	`AMO:	ma <= a;
	`MLX:	ma <= a + cx + inst[21:16];
	default:	ma <= a + {{60{inst[39]}},inst[39:35],inst[30:16]};
	endcase
`STORE:
	casez(mopcode(inst))
	`PUSH:	ma <= a - inst[`FUNCT5];
	`PUSHC:	ma <= a - 8'd10;
	`MSX:	ma <= a + cx + inst[5:0];
	default:	ma <= a + {{60{inst[39]}},inst[39:35],inst[30:22],inst[5:0]};
	endcase
default:	ma <= a + {{60{inst[39]}},inst[39:35],inst[30:16]};
endcase

endmodule
