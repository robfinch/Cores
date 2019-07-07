// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpSqrt.v
//    - floating point square root
//    - parameterized width
//    - IEEE 754 representation
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
//	Floating Point Multiplier / Divider
//
// ============================================================================

`include "fpConfig.sv"
`include "fp_defines.v"

module fpSqrt(rst, clk, ce, ld, a, o, done, sqrinf, sqrneg);
parameter FPWID = 32;
`include "fpSize.sv"
localparam pShiftAmt =
	FPWID==80 ? 48 :
	FPWID==64 ? 36 :
	FPWID==32 ? 7 : (FMSB+1-16);
input rst;
input clk;
input ce;
input ld;
input [MSB:0] a;
output reg [EX:0] o;
output done;
output sqrinf;
output sqrneg;

// registered outputs
reg sign_exe;
reg inf;
reg	overflow;
reg	underflow;

wire so;
wire [EMSB:0] xo;
wire [FX:0] mo;

// constants
wire [EMSB:0] infXp = {EMSB+1{1'b1}};	// infinite / NaN - all ones
// The following is the value for an exponent of zero, with the offset
// eg. 8'h7f for eight bit exponent, 11'h7ff for eleven bit exponent, etc.
wire [EMSB:0] bias = {1'b0,{EMSB{1'b1}}};	//2^0 exponent
// The following is a template for a quiet nan. (MSB=1)
wire [FMSB:0] qNaN  = {1'b1,{FMSB{1'b0}}};

// variables
wire [EMSB+2:0] ex1;	// sum of exponents
wire [FX:0] sqrto;

// Operands
wire sa;			// sign bit
wire [EMSB:0] xa;	// exponent bits
wire [FMSB+1:0] fracta;
wire a_dn;			// a/b is denormalized
wire az;
wire aInf;
wire aNan;
wire done1;
wire [7:0] lzcnt;
wire [MSB:0] aa;

// -----------------------------------------------------------
// - decode the input operand
// - derive basic information
// - calculate exponent
// - calculate fraction
// -----------------------------------------------------------

fpDecompReg #(FPWID) u1
(
	.clk(clk),
	.ce(ce),
	.i(a),
	.o(aa),
	.sgn(sa),
	.exp(xa),
	.fract(fracta),
	.xz(a_dn),
	.vz(az),
	.inf(aInf),
	.nan(aNan)
);

assign ex1 = xa + 8'd1;
assign so = 1'b0;				// square root of positive numbers only
assign xo = (ex1 >> 1) + (bias >> 1);	// divide by 2 cuts the bias in half, so 1/2 of it is added back in.
assign mo = aNan ? {1'b1,aa[FMSB:0],{FMSB+1{1'b0}}} : (sqrto << pShiftAmt);
assign sqrinf = aInf;
assign sqrneg = !az & so;

wire [FMSB+2:0] fracta1 = ex1[0] ? {1'b0,fracta} << 1 : {2'b0,fracta};

wire ldd;
delay1 #(1) u3 (.clk(clk), .ce(ce), .i(ld), .o(ldd));

isqrt #(FX+1) u2
(
	.rst(rst),
	.clk(clk),
	.ce(ce),
	.ld(ldd),
	.a({1'b0,fracta1,{FMSB+1{1'b0}}}),
	.o(sqrto),
	.done(done)
);

always @*
casez({aNan,sqrinf,sqrneg})
3'b1??:	o <= {sa,xa,mo};
3'b01?:	o <= {sa,1'b1,qNaN|`QSQRTINF,{FMSB+1{1'b0}}};
3'b001:	o <= {sa,1'b1,qNaN|`QSQRTNEG,{FMSB+1{1'b0}}};
default:	o <= {so,xo,mo};
endcase
	

endmodule

module fpSqrtnr(rst, clk, ce, ld, a, o, rm, done, inf, sqrinf, sqrneg);
parameter FPWID=32;
`include "fpSize.sv"

input rst;
input clk;
input ce;
input ld;
input  [MSB:0] a;
output [MSB:0] o;
input [2:0] rm;
output done;
output inf;
output sqrinf;
output sqrneg;

wire [EX:0] o1;
wire inf1;
wire [MSB+3:0] fpn0;
wire done1;

fpSqrt      #(FPWID) u1 (rst, clk, ce, ld, a, o1, done1, sqrinf, sqrneg);
fpNormalize #(FPWID) u2(.clk(clk), .ce(ce), .under_i(1'b0), .i(o1), .o(fpn0) );
fpRound  #(FPWID) u3(.clk(clk), .ce(ce), .rm(rm), .i(fpn0), .o(o) );
delay2      #(1)   u5(.clk(clk), .ce(ce), .i(inf1), .o(inf));
delay2		#(1)   u8(.clk(clk), .ce(ce), .i(done1), .o(done));
endmodule

