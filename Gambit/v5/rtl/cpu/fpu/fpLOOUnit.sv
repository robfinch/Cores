// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
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

`define FLT1   	7'h6E
`define FTOI    5'h02
`define ITOF    5'h03
`define TRUNC		5'h15

module fpLOOUnit
#(parameter FPWID=52)
(
	input clk,
	input ce,
	input Instruction ir,
	input [2:0] rm,
	input [FPWID-1:0] a,
	input [FPWID-1:0] b,
	output reg [FPWID-1:0] o,
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
    .i((ir.gen.opcode==`FLT1 && (ir.flt1.func5==`ITOF||ir.flt1.func5==`FTOI||ir.flt1.func5==`TRUNC))),
    .o(done) );
i2f #(FPWID)  ui2fs (.clk(clk), .ce(ce), .rm(rm), .i(a[FPWID-1:0]), .o(i2f_o) );
f2i #(FPWID)  uf2is (.clk(clk), .ce(ce), .i(a), .o(f2i_o) );
fpTrunc #(FPWID) urho1 (.clk(clk), .ce(ce), .i(a), .o(trunc_o), .overflow());

always @*
case (ir.gen.opcode)
`FLT1:
	case(ir.flt1.func5)
	`ITOF:   o <= {i2f_o};
	`FTOI:   o <= {f2i_o[MSB:0]};
	`TRUNC:	 o <= trunc_o;
	default: o <= 0;
	endcase
default:   o <= 0;
endcase

endmodule
