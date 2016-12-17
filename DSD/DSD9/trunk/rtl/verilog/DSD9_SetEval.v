`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD9_SetEval.v
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
//
// ============================================================================
//
`define R2      8'h0
`define SEQ     8'h76
`define SNE     8'h77
`define SLT     8'h78
`define SGE     8'h79
`define SLE     8'h7A
`define SGT     8'h7B 
`define SLTU    8'h7C
`define SGEU    8'h7D
`define SLEU    8'h7E
`define SGTU    8'h7F 

module DSD9_SetEval(xir, a, b, imm, o);
parameter WID=80;
input [39:0] xir;
input [WID-1:0] a;
input [WID-1:0] b;
input [WID-1:0] imm;
output reg o;

wire [7:0] opcode = xir[7:0];
wire [7:0] funct = xir[39:32];

always @(opcode or funct or a or b or imm)
case(opcode)
`SEQ:   o <= a==imm;
`SNE:   o <= a!=imm;
`SLT:   o <= $signed(a) < $signed(imm);
`SGE:   o <= $signed(a) >= $signed(imm);
`SLE:   o <= $signed(a) <= $signed(imm);
`SGT:   o <= $signed(a) > $signed(imm);
`SLTU:  o <= a < imm;
`SGEU:  o <= a >= imm;
`SLEU:  o <= a <= imm;
`SGTU:  o <= a > imm;
`R2:
    case(funct)
    `SEQ:   o <= a==b;
    `SNE:   o <= a!=b;
    `SLT:   o <= $signed(a) < $signed(b);
    `SGE:   o <= $signed(a) >= $signed(b);
    `SLE:   o <= $signed(a) <= $signed(b);
    `SGT:   o <= $signed(a) > $signed(b);
    `SLTU:  o <= a < b;
    `SGEU:  o <= a >= b;
    `SLEU:  o <= a <= b;
    `SGTU:  o <= a > b;
    default:    o <= 1'b0;
    endcase
default: o <= 1'b0;
endcase

endmodule
