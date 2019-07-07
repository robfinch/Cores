// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpLOOUnit.v
//		- single cycle latency floating point unit
//		- parameterized FPWIDth
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

`include "fpConfig.sv"

`define FLT1   	4'h1
`define FLT2		4'h2
`define FTOI    5'h02
`define ITOF    5'h03
`define TRUNC		5'h15
`define NXTAFT	5'h0B

module fpLOOUnit
#(parameter FPWID=32)
(
	input clk,
	input ce,
	input [3:0] op4,
	input [4:0] func5,
	input [2:0] rm,
	input [FPWID-1+`EXTRA_BITS:0] a,
	input [FPWID-1+`EXTRA_BITS:0] b,
	output reg [FPWID-1+`EXTRA_BITS:0] o,
	output done
);
`include "fpSize.sv"

wire [FPWID-1:0] i2f_o;
wire [MSB:0] f2i_o;
wire [MSB:0] trunc_o;
wire [FPWID-1:0] nxtaft_o;

delay1 u1 (
    .clk(clk),
    .ce(ce),
    .i((op4==`FLT1 && (func5==`ITOF||func5==`FTOI||func5==`TRUNC))||(op4==`FLT2 && (func5==`NXTAFT))),
    .o(done) );
i2f #(FPWID)  ui2fs (.clk(clk), .ce(ce), .rm(rm), .i(a[FPWID-1+`EXTRA_BITS:`EXTRA_BITS]), .o(i2f_o) );
f2i #(FPWID)  uf2is (.clk(clk), .ce(ce), .i(a), .o(f2i_o) );
fpTrunc #(FPWID+`EXTRA_BITS) urho1 (.clk(clk), .ce(ce), .i(a), .o(trunc_o), .overflow());
fpNextAfter #(FPWID) una1 (.clk(clk), .ce(ce), .a(a[FPWID-1+`EXTRA_BITS:`EXTRA_BITS]), .b(b[FPWID-1+`EXTRA_BITS:`EXTRA_BITS]), .o(nxtaft_o));

always @*
	case (op4)
	`FLT1:
		case(func5)
		`ITOF:   o <= {i2f_o,{`EXTRA_BITS{1'b0}}};
		`FTOI:   o <= {f2i_o[MSB-`EXTRA_BITS:0],{`EXTRA_BITS{1'b0}}};
		`TRUNC:	 o <= trunc_o;
		default: o <= 0;
		endcase
	`FLT2:
		case(func5)
		`NXTAFT:	o <= {nxtaft_o,{`EXTRA_BITS{1'b0}}};
		default: o <= 0;
		endcase
	default:   o <= 0;
	endcase

endmodule
