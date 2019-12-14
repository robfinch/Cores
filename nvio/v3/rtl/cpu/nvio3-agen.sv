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
`include "nvio3-defines.sv"

module agen(inst, a, b, c, i, base, offset, ma, idle);
parameter AMSB = 127;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input [39:0] inst;
input [AMSB:0] a;
input [AMSB:0] b;
input [AMSB:0] c;
input [AMSB:0] i;
input [AMSB:0] base;
input [127:0] offset;
output reg [AMSB:0] ma;
output idle;

assign idle = 1'b1;
reg [AMSB+1:0] cx;

always @*
case(inst[`SCALE])
3'd0:	cx <= c;
3'd1:	cx <= c << 1;
3'd2:	cx <= c << 2;
3'd3:	cx <= c << 3;
3'd4:	cx <= c << 4;
3'd7:	cx <= (c << 2) + c;					// * 5
default:	cx = c;
endcase

always @*
casez(inst[`OPCODE])
`LOAD:	// Loads
	casez(inst[`OPCODE])
	`AMO:		ma <= a;
	default:	
		case(inst[`AM])
		1'd0:	ma <= base + a + {{AMSB{inst[36]}},inst[36:18]} + offset;
		1'd1:	ma <= base + a + cx + {inst[36:33],inst[22:18]};
		endcase
	endcase
`STORE:	// stores
	casez(inst[`OPCODE])
	`LEA:
		case(inst[`AM])
		1'd0:		ma <= base + a + {{AMSB{inst[36]}},inst[36:23],inst[12:8]};
		1'd1:		ma <= base + a + cx + {inst[36:33],inst[12:8]};
		endcase
	`PUSH,`PUSHC:
		ma <= base + a - 8'd16;
	default:	
		case(inst[`AM])
		1'd0:	ma <= base + a + {{AMSB{inst[36]}},inst[36:23],inst[12:8]} + offset;
		1'd1:	ma <= base + a + cx + {inst[36:33],inst[12:8]};
		endcase
	endcase
default:	ma <= base + a + {{AMSB{inst[36]}},inst[36:18]} + offset;
endcase


endmodule
