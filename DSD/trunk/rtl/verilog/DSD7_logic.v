`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD7_logic.v
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
`define R2      6'h0C
`endif

`ifndef ANDI
`define ANDI    6'h08
`define ORI     6'h09
`define EORI    6'h0A

`define AND     7'h08
`define OR      7'h09
`define EOR     7'h0A
`define NAND    7'h0C
`define NOR     7'h0D
`define ENOR    7'h0E
`endif

module DSD7_logic(xir, a, b, imm, res);
input [31:0] xir;
input [31:0] a;
input [31:0] b;
input [31:0] imm;
output [31:0] res;
reg [31:0] res;

wire [5:0] xopcode = xir[5:0];
wire [5:0] xfunc = xir[31:26];

always @*
case(xopcode)
`R2:
	case(xfunc)
//	`NOT:	res <= ~|a;
	`AND:	res <= a & b;
	`OR:	res <= a | b;
	`EOR:	res <= a ^ b;
	`NAND:	res <= ~(a & b);
	`NOR:	res <= ~(a | b);
	`ENOR:	res <= ~(a ^ b);
	default:	res <= 32'd0;
	endcase
`ANDI:	res <= a & imm;
`ORI:	res <= a | imm;
`EORI:	res <= a ^ imm;
default:	res <= 32'd0;
endcase

endmodule

