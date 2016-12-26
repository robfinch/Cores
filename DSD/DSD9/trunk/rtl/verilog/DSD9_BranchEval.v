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

`define FBEQ    8'h36
`define FBNE    8'h37
`define FBLT    8'h38
`define FBGE    8'h39
`define FBLE    8'h3A
`define FBGT    8'h3B
`define FBOR    8'h3C
`define FBUN    8'h3D

module DSD9_BranchEval(xir, a, b, imm, takb);
parameter WID=80;
input [39:0] xir;
input [WID-1:0] a;
input [WID-1:0] b;
input [WID-1:0] imm;
output reg takb;

wire [7:0] opcode = xir[7:0];
wire [4:0] o;
wire nanx;
// make sure bit index is valid
wire [6:0] bitno1 = xir[20:14];
wire [6:0] bitno = bitno1 > 7'd79 ? 7'd0 : bitno1;

fp_cmp_unit #(WID) u1 (a, b, o, nanx);

always @(opcode or a or b or imm or xir)
case(opcode)
`BEQ:   takb = a==b;
`BNE:   takb = a!=b;
`BLT:   takb = $signed(a) < $signed(b);
`BGE:   takb = $signed(a) >= $signed(b);
`BLE:   takb = $signed(a) <= $signed(b);
`BGT:   takb = $signed(a) > $signed(b);
`BLTU:  takb = a < b;
`BGEU:  takb = a >= b;
`BLEU:  takb = a <= b;
`BGTU:  takb = a > b;
`BBC:   takb = ~a[bitno];
`BBS:   takb = a[bitno];
`BEQI:  takb = a==imm;
`BNEI:  takb = a!=imm;
`BLTI:  takb = $signed(a) < $signed(imm);
`BGEI:  takb = $signed(a) >= $signed(imm);
`BLEI:  takb = $signed(a) <= $signed(imm);
`BGTI:  takb = $signed(a) > $signed(imm);
`BLTUI: takb = a < imm;
`BGEUI: takb = a >= imm;
`BLEUI: takb = a <= imm;
`BGTUI: takb = a > imm;

`FBEQ:  takb = o[0];
`FBNE:  takb = !o[0];
`FBLT:  takb = o[1];
`FBGE:  takb = !o[1];
`FBLE:  takb = o[2];
`FBGT:  takb = !o[2];
`FBUN:  takb = o[4];
`FBOR:  takb = !o[4];
default: takb = 1'b0;
endcase

endmodule
