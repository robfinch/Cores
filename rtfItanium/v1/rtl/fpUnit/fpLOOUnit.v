`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpLOOUnit.v
//		- single cycle latency floating point unit
//		- parameterized width
//		- IEEE 754 representation
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
//	i2f - convert integer to floating point
//  f2i - convert floating point to integer
//
// ============================================================================

`define FLT1   	4'h1
`define FLT2		4'h2
`define FTOI    5'h02
`define ITOF    5'h03
`define TRUNC		5'h15

module fpLOOUnit
#(parameter WID=32)
(
	input clk,
	input ce,
	input [3:0] op4,
	input [4:0] func5,
	input [2:0] rm,
	input [WID-1:0] a,
	output reg [WID-1:0] o,
	output done
);
localparam MSB = WID-1;
localparam EMSB = WID==128 ? 14 :
                  WID==96 ? 14 :
                  WID==80 ? 14 :
                  WID==64 ? 10 :
				  WID==52 ? 10 :
				  WID==48 ? 11 :
				  WID==44 ? 10 :
				  WID==42 ? 10 :
				  WID==40 ?  9 :
				  WID==32 ?  7 :
				  WID==24 ?  6 : 4;
localparam FMSB = WID==128 ? 111 :
                  WID==96 ? 79 :
                  WID==80 ? 63 :
                  WID==64 ? 51 :
				  WID==52 ? 39 :
				  WID==48 ? 34 :
				  WID==44 ? 31 :
				  WID==42 ? 29 :
				  WID==40 ? 28 :
				  WID==32 ? 22 :
				  WID==24 ? 15 : 9;

wire [WID-1:0] i2f_o;
wire [WID-1:0] f2i_o;
wire [WID-1:0] trunc_o;

delay1 u1 (
    .clk(clk),
    .ce(ce),
    .i((op4==`FLT1 && (func5==`ITOF||func5==`FTOI||func5==`TRUNC))),
    .o(done) );
i2f #(WID)  ui2fs (.clk(clk), .ce(ce), .rm(rm), .i(a), .o(i2f_o) );
f2i #(WID)  uf2is (.clk(clk), .ce(ce), .i(a), .o(f2i_o) );
fpTrunc #(WID) urho1 (.clk(clk), .ce(ce), .i(a), .o(trunc_o), .overflow());

always @*
	case (op4)
	`FLT1:
		case(func5)
		`ITOF:   o <= i2f_o;
		`FTOI:   o <= f2i_o;
		`TRUNC:	 o <= trunc_o;
		default: o <= 0;
		endcase
	default:   o <= 0;
	endcase

endmodule
