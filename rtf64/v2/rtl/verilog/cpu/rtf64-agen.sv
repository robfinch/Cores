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
import rtf64pkg::*;
import rtf64configpkg::*;

// Contains logic to increment address for unaligned memory accesses.

module agen(rst, clk, en, inc_ma, inst, a, c, ma, idle);
parameter AWID = 64;
localparam AMSB = AWID-1;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk;
input en;
input inc_ma;
input [31:0] inst;
input [AMSB:0] a;
input [AMSB:0] c;
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
`LDO,`LDOR,`STO,`STOC,`STPTR:  Sc = inst[28] ? 4'd3 : 4'd0;
default:  Sc = 4'd0;
endcase

always @*
  cx = c << Sc;

always @(posedge clk)
if (rst)
  ma <= {AWID{1'b0}};
else begin
  if (inc_ma)
`ifdef CPU_B128
    ma <= {ma[31:4]+2'd1,4'b00};
`endif
`ifdef CPU_B64
    ma <= {ma[31:3]+2'd1,3'b00};
`endif
`ifdef CPU_B32
    ma <= {ma[31:2]+2'd1,2'b00};
`endif
else if (en)
casez(inst[`OPCODE])
`JSR,`JSR18:
  ma <= a - 4'd8;
`RTS:
  ma <= a;
`LOAD:	// Loads
	casez(inst[`OPCODE])
	// Short form loads - sp,fp relative
	`LDBS,`LDBUS,`LDWS,`LDWUS,`LDTS,`LDTUS,`LDOS,`LDORS,
	`LEAS,`PLDOS,`FLDOS://,`LDOT:
	  ma <= a + {{AMSB{inst[22]}},inst[22:14],3'd0};
	`LDB,`LDBU,`LDW,`LDWU,`LDT,`LDTU,`LDO,`LDOR,`LDOT,
	`LEA,`PLDO,`FLDO:
	  if (inst[`AMODE])
	    ma <= a + {{AMSB{inst[29]}},inst[29:18]};
	  else
	    ma <= a + cx + {{AMSB{inst[29]}},inst[29],inst[22:18]};
	`POP:   ma <= a;
	`UNLINK:  ma <= a;
//	`AMO:		ma <= a;
	default:	;
	endcase
`STORE:	// stores
	casez(inst[`OPCODE])
	// Short form stores - sp, fp relative
	`STBS,`STWS,`STTS,`STOS,`STOCS,`STOIS,`FSTOS,`PSTOS:
	  ma <= a + {{AMSB{inst[22]}},inst[22:14],3'd0};
	`STB,`STW,`STT,`STO,`STOC,`STOT,`FSTO,`PSTO:
	  if (inst[`AMODE])
	    ma <= a + {{AMSB{inst[29]}},inst[29:18]};
	  else
	    ma <= a + cx + {{AMSB{inst[29]}},inst[29],inst[22:18]};

	`PUSHC:
		ma <= a - 8'd8;
	`PUSH:
		ma <= a - 8'd8;
  `LINK:
    ma <= a - 8'd8;

	default:	;
	endcase
`OSR2:
  case(inst[`FUNCT5])
  `CACHE: ma <= a;
  default:  ;
  endcase
default:  ;
endcase
end

endmodule
