// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64alu.v
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
`include "FT64_defines.vh"

module FT64alu(instr, a, b, pc, csr, o);
parameter BIG = 1'b1;
input [31:0] instr;
input [63:0] a;
input [63:0] b;
input [31:0] pc;
input [63:0] csr;
output reg [63:0] o;

always @*
case(instr[`INSTRUCTION_OP])
`BRK:   o = instr[15] ? pc : pc + 32'd4;
`RR:
    case(instr[`INSTRUCTION_S2])
    `ADD: o = a + b;
    `SUB: o = a - b;
    `CMP: o = $signed(a) < $signed(b) ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
    `CMPU: o = a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
    `AND:  o = a & b;
    `OR:   o = a | b;
    `XOR:  o = a ^ b;
    `SHL,`SHLI:   o = BIG ? a << b : 64'hCCCCCCCCCCCCCCCC;
    `SHR,`SHRI:   o = BIG ? a >> b : 64'hCCCCCCCCCCCCCCCC;
    `ASR,`ASRI:   o = BIG ? (a >> b) | (a[63] ? ~(64'hFFFFFFFFFFFFFFFF >> b) : 64'd0) : 64'hCCCCCCCCCCCCCCCC;
    `SEI:       o = a | b;
    default:    o = 64'hDEADDEADDEADDEAD;
    endcase
 `Bcc:
    case(instr[`INSTRUCTION_COND])
    `BEQZ:  o = a==64'd0;
    `BNEZ:  o = a!=64'd0;
    `BLTZ:  o = a[63];
    `BGEZ:  o = ~a[63];
    default:    o = 1'b1;
    endcase
 `ADDI: o = a + b;
 `CMPI: o = $signed(a) < $signed(b) ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
 `CMPUI: o = a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
 `ANDI:  o = a & b;
 `ORI:   o = a | b;
 `XORI:  o = a ^ b;
 `JAL:   o = pc + 32'd4;
 `LBX,`LHX,`LHUX,`LWX:   o = BIG ? a + (b << instr[22:21]) : 64'hCCCCCCCCCCCCCCCC;
 `LB,`LH,`LHU,`LW,`SB,`SH,`SW:  o = a + b;
 `CSRRW:     o = BIG ? csr : 64'hCCCCCCCCCCCCCCCC;
  default:    o = 64'hDEADDEADDEADDEAD;
endcase  

endmodule
