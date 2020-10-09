// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
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
`include "rtf64-defines.sv"

module agen(inst, a, b, c, i, ma, idle);
parameter AMSB = 63;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input [63:0] inst;
input [AMSB:0] a;
input [AMSB:0] b;
input [AMSB:0] c;
input [AMSB:0] i;
output reg [AMSB:0] ma;
output idle;

assign idle = 1'b1;
reg [3:0] Sc;
reg [AMSB+1:0] cx;

always @*
case(inst[`OPCODE])
`LDB,`LDBU,`STB:  Sc = 4'd0;
`LDW,`LDWU,`STW:  Sc = inst[28] ? 4'd1 : 4'd0;
`LDT,`LDTU,`STT:  Sc = inst[28] ? 4'd2 : 4'd0;
`LDO,`LDOR,`STO,`STOC:  Sc = inst[28] ? 4'd3 : 4'd0;
default:  Sc = 4'd0;
endcase

always @*
  cx = c << Sc;

always @*
casez(inst[`OPCODE])
`LOAD:	// Loads
	casez(inst[`OPCODE])
	// Short form loads
	`LDBS,`LDBUS,`LDWS,`LDWUS,`LDTS,`LDTUS,`LDOS,`LDORS://,`LDOT,`LEA:
	  ma <= a + {{AMSB{inst[22]}},inst[22:14],3'd0};
	`LDB,`LDBU,`LDW,`LDWU,`LDT,`LDTU,`LDO,`LDOR,`LDOT:
	  if (instr[30])
	    ma <= a + {{AMSB{inst[29]}},inst[29:18]};
	  else
	    ma <= a + cx + {{AMSB{inst[29]}},inst[29],inst[22:18]};
	`POP:   ma <= a;
	`AMO:		ma <= a;
	default:	
    ma <= a + cx + {{AMSB{inst[29]}},inst[29],inst[22:18]};
	endcase
`STORE:	// stores
	casez(inst[`OPCODE])
	// Short form stores
	`STBS,`STWS,`STTS,`STOS,`STOCS:
	  ma <= a + {{AMSB{inst[22]}},inst[22:18],inst[13:8],3'd0};
	`STB,`STW,`STT,`STO,`STOC,`STOT:
	  if (instr[30])
	    ma <= a + {{AMSB{inst[29]}},inst[29:23],inst[12:8]};
	  else
	    ma <= a + cx + {{AMSB{inst[29]}},inst[29],inst[12:8]};
	`PUSHC:
		ma <= a - 8'd8;
	`PUSH:
		ma <= a - 8'd8;
	default:	
	  if (instr[30])
	    ma <= a + {{AMSB{inst[29]}},inst[29:23],inst[12:8]};
	  else
	    ma <= a + cx + {{AMSB{inst[29]}},inst[29],inst[12:8]};
	endcase
default:  ma <= a + cx + {{AMSB{inst[29]}},inst[29],inst[22:18]};
endcase


endmodule
