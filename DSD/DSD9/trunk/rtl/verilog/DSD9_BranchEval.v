`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD9_BranchEval.v
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
`define BEQ     8'h46
`define BNE     8'h47
`define BLT     8'h48
`define BGE     8'h49
`define BLE     8'h4A
`define BGT     8'h4B 
`define BLTU    8'h4C
`define BGEU    8'h4D
`define BLEU    8'h4E
`define BGTU    8'h4F 

`define BBC     8'h54
`define BBS     8'h55
`define BEQI    8'h56
`define BNEI    8'h57
`define BLTI    8'h58
`define BGEI    8'h59
`define BLEI    8'h5A
`define BGTI    8'h5B 
`define BLTUI   8'h5C
`define BGEUI   8'h5D
`define BLEUI   8'h5E
`define BGTUI   8'h5F 

module DSD9_BranchEval(xir, a, b, imm, takb);
input [39:0] xir;
input [79:0] a;
input [79:0] b;
input [79:0] imm;
output reg takb;

wire [7:0] opcode = xir[7:0];

always @(opcode or a or b or imm or xir)
case(opcode)
`BEQ:   takb <= a==b;
`BNE:   takb <= a!=b;
`BLT:   takb <= $signed(a) < $signed(b);
`BGE:   takb <= $signed(a) >= $signed(b);
`BLE:   takb <= $signed(a) <= $signed(b);
`BGT:   takb <= $signed(a) > $signed(b);
`BLTU:  takb <= a < b;
`BGEU:  takb <= a >= b;
`BLEU:  takb <= a <= b;
`BGTU:  takb <= a > b;
`BBC:   takb <= ~a[xir[20:14]];
`BBS:   takb <= a[xir[20:14]];
`BEQI:  takb <= a==imm;
`BNEI:  takb <= a!=imm;
`BLTI:  takb <= $signed(a) < $signed(imm);
`BGEI:  takb <= $signed(a) >= $signed(imm);
`BLEI:  takb <= $signed(a) <= $signed(imm);
`BGTI:  takb <= $signed(a) > $signed(imm);
`BLTUI: takb <= a < imm;
`BGEUI: takb <= a >= imm;
`BLEUI: takb <= a <= imm;
`BGTUI: takb <= a > imm;
default: takb <= 1'b0;
endcase

endmodule
