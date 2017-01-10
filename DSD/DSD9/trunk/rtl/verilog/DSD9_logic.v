`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD9_logic.v
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
`ifndef R2
`define R2      8'h02
`endif

`define ANDI    8'h08
`define ORI     8'h09
`define XORI    8'h0A

`define AND     8'h08
`define OR      8'h09
`define XOR     8'h0A
`define ANDC    8'h4B
`define NAND    8'h48
`define NOR     8'h49
`define XNOR    8'h4A
`define ORC     8'h4C

module DSD9_logic(xir, a, b, imm, res);
parameter DMSB=79;
input [39:0] xir;
input [DMSB:0] a;
input [DMSB:0] b;
input [DMSB:0] imm;
output [DMSB:0] res;
reg [DMSB:0] res;

wire [7:0] xopcode = xir[7:0];
wire [7:0] xfunc = xir[39:32];

always @*
case(xopcode)
`R2:
	case(xfunc)
//	`NOT:	res <= ~|a;
	`AND:	res = a & b;
	`OR:	res = a | b;
	`XOR:	res = a ^ b;
	`ANDC:  res = a & ~b;
	`NAND:	res = ~(a & b);
	`NOR:	res = ~(a | b);
	`XNOR:	res = ~(a ^ b);
	`ORC:   res = a | ~b;
	default:	res = 80'd0;
	endcase
`ANDI:	res = a & imm;
`ORI:	res = a | imm;
`XORI:	res = a ^ imm;
default:	res = 80'd0;
endcase

endmodule

