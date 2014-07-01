`include "Table888_defines.v"
`timescale 1ns / 1ps
//=============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//  
//	Table888_set.v
//  - set datapath operations
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
// Scc instructions are a form of conditional move instruction.
//
// The processor can get by without set instructions, but it boosts
// performance and reduces code size to include them.
//
// Code evaluating a true/false relational expression without set looks like:
//     cmp r1,r2,r3
//     bgt r1,lab1
//     ldi r4,#1
//     bra lab2
// lab1:
//     ldi r4,#0
// lab2:
//
// Using a single set instruction replaces the code with:
//      sle r4,r2,r3
//
// It replaces five instructions with one instruction and executes a lot
// faster.
//=============================================================================
//
module Table888_set(xIR, a, b, imm, o);
input [39:0] xIR;
input [63:0] a;
input [63:0] b;
input [63:0] imm;
output [63:0] o;
reg [63:0] o;

wire [7:0] xOpcode = xIR[7:0];
wire [7:0] xFunc = xIR[39:32];

wire eqi = a==imm;
wire lti = $signed(a) < $signed(imm);
wire ltui = a < imm;
wire eq = a==b;
wire lt = $signed(a) < $signed(b);
wire ltu = a < b;

always @(xOpcode,xFunc,eq,lt,ltu,eqi,lti,ltui)
case (xOpcode)
`RR:
	case(xFunc)
	`SEQ:	o = eq;
	`SNE:	o = !eq;
	//`SOR:	o = |(a | b);
	//`SAND:
	`SLT:	o = lt;
	`SLE:	o = lt|eq;
	`SGT:	o = !(lt|eq);
	`SGE:	o = !lt;
	`SLO:	o = ltu;
	`SLS:	o = ltu|eq;
	`SHI:	o = !(ltu|eq);
	`SHS:	o = !ltu;
	default:	o = 64'd0;
	endcase
`SEQI:	o = eqi;
`SNEI:	o = !eqi;
`SLTI:	o = lti;
`SLEI:	o = lti|eqi;
`SGTI:	o = !(lti|eqi);
`SGEI:	o = !lti;
`SLOI:	o = ltui;
`SLSI:	o = ltui|eqi;
`SHII:	o = !(ltui|eqi);
`SHSI:	o = !ltui;
default:	o = 64'd0;
endcase

endmodule
