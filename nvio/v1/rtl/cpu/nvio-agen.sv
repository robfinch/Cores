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
`include "nvio-defines.sv"

module agen(unit, inst, a, b, c, i, ma, res2, idle);
input [2:0] unit;
input [39:0] inst;
input [79:0] a;
input [79:0] b;
input [79:0] c;
input [79:0] i;
output reg [79:0] ma;
output reg [79:0] res2;
output idle;

assign idle = 1'b1;
reg [80:0] cx;
reg [4:0] dx;

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

always @*
case(inst[30:28])
3'd0:	dx <= 5'd1;
3'd1:	dx <= 5'd2;
3'd2:	dx <= 5'd4;
3'd3:	dx <= 5'd8;
3'd4:	dx <= 5'd16;
3'd5:	dx <= 5'd5;
3'd6:	dx <= 5'd10;
3'd7:	dx <= 5'd15;
endcase

function [5:0] mopcode;
input [39:0] ins;
mopcode = {ins[34:33],ins[9:6]};
endfunction

always @*
casez(mopcode(inst))
`LOAD:
	casez(mopcode(inst))
	`PUSHC:	ma <= a - 8'd10;
	`POP:		ma <= a;
	`UNLK:	ma <= b;
	`AMO:		ma <= a;
	`MLX:		ma <= a + cx + inst[21:18] - (inst[17:16]==2'd1 ? dx : 5'd0);
	default:	ma <= a + {{58{inst[39]}},inst[39:35],inst[32:16]};
	endcase
`STORE:
	casez(mopcode(inst))
	`LINK:	ma <= a - {inst[`FUNCT5],inst[32:22]} - 8'd10;
	`PUSH:	ma <= a - inst[`FUNCT5];
	`PUSHC:	ma <= a - 8'd10;
	`MSX:		ma <= a + cx + inst[5:2] - (inst[1:0]==2'd1 ? dx : 5'd0);
	default:	ma <= a + {{58{inst[39]}},inst[39:35],inst[32:22],inst[5:0]};
	endcase
default:	ma <= a + {{58{inst[39]}},inst[39:35],inst[32:16]};
endcase

always @*
casez(mopcode(inst))
`LOAD:
	casez(mopcode(inst))
	`LEA:		res2 <= a + {{58{inst[39]}},inst[39:35],inst[32:16]};
	`PUSHC:	res2 <= a - 8'd10;
	`POP:		res2 <= a + inst[`FUNCT5];
	`UNLK:	res2 <= b + inst[`FUNCT5];
	`MLX:		
		case(inst[17:16])
		2'd0:	res2 <= a;
		2'd1:	res2 <= a - dx;
 		2'd2:	res2 <= a + dx;
		2'd3:	res2 <= a + cx + inst[21:18];
		endcase
	default:	res2 <= 1'd0;
	endcase
`STORE:
	casez(mopcode(inst))
	`LINK:	res2 <= a;
	`PUSH:	res2 <= a - inst[`FUNCT5];
	`PUSHC:	res2 <= a - 8'd10;
	`MSX:
		case(inst[1:0])
		2'd0:	res2 <= a;
		2'd1:	res2 <= a - dx;
		2'd2:	res2 <= a + dx;
		2'd3:	res2 <= a + cx + inst[5:2];
		endcase
	default:	res2 <= 1'd0;
	endcase
default:	res2 <= 1'd0;
endcase

endmodule
