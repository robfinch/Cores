`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD7_BranchEval.v
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
//`ifndef BEQ
`define BccI    6'h02
`define BccUI   6'h03
`define Bcc     6'h12
`define BccU    6'h13

// Bcc ops
`define BEQ     3'h0
`define BNE     3'h1
`define BAND    3'h2
`define BNAND   3'h3
`define BLT     3'h4
`define BGE     3'h5
`define BLE     3'h6
`define BGT     3'h7
`define BOR     3'h2
`define BNOR    3'h3
`define BLTU    3'h4
`define BGEU    3'h5
`define BLEU    3'h6
`define BGTU    3'h7

// BccI ops
`define BEQI    3'h0
`define BNEI    3'h1
`define BANDI   3'h2
`define BNANDI  3'h3
`define BLTI    3'h4
`define BGEI    3'h5
`define BLEI    3'h6
`define BGTI    3'h7
`define BBC     3'h0
`define BBS     3'h1
`define BORI    3'h2
`define BNORI   3'h3
`define BLTUI   3'h4
`define BGEUI   3'h5
`define BLEUI   3'h6
`define BGTUI   3'h7
//`endif

module DSD7_BranchEval(xir, a, b, imm, takb);
input [31:0] xir;
input [31:0] a;
input [31:0] b;
input [31:0] imm;
output reg takb;

wire [5:0] opcode = xir[5:0];
wire [2:0] cond = xir[18:16];

always @(opcode or cond or a or b or imm)
case(opcode)
`Bcc:
    case(cond)
    `BEQ:   takb <= a==b;
    `BNE:   takb <= a!=b;
    `BAND:  takb <= (a & b)!=0;
    `BNAND: takb <= (a & b)==0;
    `BLT:   takb <= $signed(a) < $signed(b);
    `BGE:   takb <= $signed(a) >= $signed(b);
    `BLE:   takb <= $signed(a) <= $signed(b);
    `BGT:   takb <= $signed(a) > $signed(b);
    endcase
`BccU:
    case(cond)
    `BOR:   takb <= |a || |b;
    `BNOR:  takb <= ~(|a || |b);
    `BLTU:  takb <= a < b;
    `BGEU:  takb <= a >= b;
    `BLEU:  takb <= a <= b;
    `BGTU:  takb <= a > b;
    default: takb <= 1'b0;
    endcase
`BccI:
    case(cond)
    `BEQI:  takb <= a==imm;
    `BNEI:  takb <= a!=imm;
    `BANDI: takb <= |a && |imm;
    `BNANDI:    takb <= ~(|a && |imm);
    `BLTI:  takb <= $signed(a) < $signed(imm);
    `BGEI:  takb <= $signed(a) >= $signed(imm);
    `BLEI:  takb <= $signed(a) <= $signed(imm);
    `BGTI:  takb <= $signed(a) > $signed(imm);
    endcase
`BccUI:
    case(cond)
    `BBC:   takb <= ~a[imm[4:0]];
    `BBS:   takb <= a[imm[4:0]];
    `BORI:  takb <= |a || |imm;
    `BNORI: takb <= ~(|a || |imm);
    `BLTUI: takb <= a < imm;
    `BGEUI: takb <= a >= imm;
    `BLEUI: takb <= a <= imm;
    `BGTUI: takb <= a > imm;
    default: takb <= 1'b0;
    endcase
default:    takb <= 1'b0;
endcase

endmodule
