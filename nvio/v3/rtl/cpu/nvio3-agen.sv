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

module agen(inst, a, b, c, i, offset, ma, res2, idle);
parameter AMSB = 95;
input [39:0] inst;
input [AMSB:0] a;
input [AMSB:0] b;
input [AMSB:0] c;
input [AMSB:0] i;
input [127:0] offset;
output reg [AMSB:0] ma;
output reg [AMSB:0] res2;
output idle;

assign idle = 1'b1;
reg [AMSB+1:0] cx;
reg [5:0] dx, ex;

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
case(inst[`SCALE])
3'd0:	dx <= 5'd1;
3'd1:	dx <= 5'd2;
3'd2:	dx <= 5'd4;
3'd3:	dx <= 5'd8;
3'd4:	dx <= 5'd16;
3'd7:	dx <= 5'd5;
default:	dx = 5'd1;
endcase

always @*
casez(inst[`OPCODE])
`LDB:		ex <= 6'd1;
`LDBU:	ex <= 6'd1;
`LDW:		ex <= 6'd2;
`LDWU:	ex <= 6'd2;
`LDT:		ex <= 6'd4;
`LDTU:	ex <= 6'd4;
`LDP:		ex <= 6'd5;
`LDPU:	ex <= 6'd5;
`LDO:		ex <= 6'd8;
`LDOU:	ex <= 6'd8;
`LDH:		ex <= 6'd16;
`LDHR:	ex <= 6'd16;
`LDFD:	ex <= 6'd8;
`LDFQ:	ex <= 6'd16;
`STB:		ex <= 6'd1;
`STW:		ex <= 6'd2;
`STT:		ex <= 6'd4;
`STP:		ex <= 6'd5;
`STO:		ex <= 6'd8;
`STFD:	ex <= 6'd8;
`STFQ:	ex <= 6'd16;
default:	ex <= 6'd1;
endcase

always @*
casez(inst[`OPCODE])
8'h0x,8'h1x,8'h4x,8'h5x:	// Loads
	casez(inst[`OPCODE])
	`POP:		ma <= a;
	`UNLK:	ma <= b;
	`AMO:		ma <= a;
	default:	
		case(inst[`AM])
		2'd0:		ma <= a + {{AMSB{inst[36]}},inst[36:18]} + offset;
		2'd1:		ma <= a + {{AMSB{inst[36]}},inst[36:18]} + offset;
		2'd2:		ma <= a + {{AMSB{inst[36]}},inst[36:18]} + offset - ex;
		2'd3:		
			case(inst[32:31])
			2'd0:	ma <= a + cx + {inst[36:33],inst[22:18]};
			2'd1:	ma <= a + cx + {inst[36:33],inst[22:18]};
			2'd2:	ma <= a + cx + {inst[36:33],inst[22:18]} - ex;
			default:	ma <= a + cx + {inst[36:33],inst[22:18]};
			endcase
		endcase
	endcase
8'h2x,8'h3x,8'h6x,8'h7x:	// stores
	casez(inst[`OPCODE])
	`LINK:	ma <= a - {inst[38:23],4'h0} - 8'd16;
	`PUSH:	ma <= a - {inst[`SCALE],4'h0};
	`PUSHC:	ma <= a - 8'd16;
	default:	
		case(inst[`AM])
		2'd0:		ma <= a + {{AMSB{inst[36]}},inst[36:23],inst[12:8]} + offset;
		2'd1:		ma <= a + {{AMSB{inst[36]}},inst[36:23],inst[12:8]} + offset;
		2'd2:		ma <= a + {{AMSB{inst[36]}},inst[36:23],inst[12:8]} + offset - ex;
		2'd3:
			case(inst[32:31])
			2'd0:	ma <= a + cx + {inst[36:33],inst[12:8]};
			2'd1:	ma <= a + cx + {inst[36:33],inst[12:8]};
			2'd2:	ma <= a + cx + {inst[36:33],inst[12:8]} - ex;
			default:	ma <= a + cx + {inst[36:33],inst[12:8]};
			endcase
		endcase
	endcase
default:	ma <= a + {{AMSB{inst[36]}},inst[36:18]} + offset;
endcase

always @*
casez(inst[`OPCODE])
8'h0x,8'h1x,8'h4x,8'h5x:	// Loads
	casez(inst[`OPCODE])
	`POP:		res2 <= a + 8'd16;
	`UNLK:	res2 <= b;// + inst[`FUNCT5];
	default:
		case(inst[`AM])
		2'd0:		res2 <= a;
		2'd1:		res2 <= a + ex;
		2'd2:		res2 <= a - ex;
		2'd3:		
			case(inst[32:31])
			2'd0:	res2 <= a;
			2'd1:	res2 <= a + ex;
			2'd2:	res2 <= a - ex;
			default:	res2 <= a;
			endcase
		endcase
	endcase
8'h2x,8'h3x,8'h6x,8'h7x:	// stores
	casez(inst[`OPCODE])
	`LEA:
		case(inst[`AM])
		2'd0:		res2 <= a + {{AMSB{inst[36]}},inst[36:23],inst[12:8]};
		2'd1:		res2 <= a + {{AMSB{inst[36]}},inst[36:23],inst[12:8]} + ex;
		2'd2:		res2 <= a + {{AMSB{inst[36]}},inst[36:23],inst[12:8]} - ex;
		2'd3:
			case(inst[32:31])
			2'd0:	res2 <= a + cx + {inst[36:33],inst[12:8]};
			2'd1:	res2 <= a + cx + {inst[36:33],inst[12:8]} + ex;
			2'd2:	res2 <= a + cx + {inst[36:33],inst[12:8]} - ex;
			default:	res2 <= a + cx + {inst[36:33],inst[12:8]};
			endcase
		endcase
	`LINK:	res2 <= a;
	`PUSH:	res2 <= a - {inst[`SCALE],4'h0};
	`PUSHC:	res2 <= a - 8'd16;
	default:
		case(inst[`AM])
		2'd0:		res2 <= a;
		2'd1:		res2 <= a + ex;
		2'd2:		res2 <= a - ex;
		2'd3:
			case(inst[32:31])
			2'd0:	res2 <= a;
			2'd1:	res2 <= a + ex;
			2'd2:	res2 <= a - ex;
			default:	res2 <= a;
			endcase
		endcase
	endcase
default:	res2 <= 1'd0;
endcase

endmodule
