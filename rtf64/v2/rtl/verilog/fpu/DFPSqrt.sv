// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPSqrt.v
//    - decimal floating point square root
//    - parameterized width
//    - IEEE 754 representation
//
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================

import fp::*;

module DFPSqrt(rst, clk, ce, ld, a, o, done, sqrinf, sqrneg);
parameter N=33;
localparam pShiftAmt =
	FPWID==80 ? 48 :
	FPWID==64 ? 36 :
	FPWID==32 ? 7 : (FMSB+1-16);
input rst;
input clk;
input ce;
input ld;
input [N*4+16+4-1:0] a;
output reg [(N+1)*4*2+16+4-1:0] o;
output done;
output sqrinf;
output sqrneg;

// registered outputs
reg sign_exe;
reg inf;
reg	overflow;
reg	underflow;

wire so;
wire [15:0] xo;
wire [(N+1)*4*2-1:0] mo;

// constants
wire [15:0] infXp = 16'h9999;	// infinite / NaN - all ones
// The following is a template for a quiet nan. (MSB=1)
wire [N*4-1:0] qNaN  = {4'h1,{N*4-4{1'b0}}};

// variables
wire [15:0] ex1;	// sum of exponents
wire ex1c;
wire [(N+1)*4*2-1:0] sqrto;

// Operands
wire sa;			// sign bit
wire sx;			// sign of exponent
wire [15:0] xa;	// exponent bits
wire [N*4-1:0] siga;
wire a_dn;			// a/b is denormalized
wire az;
wire aInf;
wire aNan;
wire done1;
wire [7:0] lzcnt;
wire [N*4-1:0] aa;

// -----------------------------------------------------------
// - decode the input operand
// - derive basic information
// - calculate exponent
// - calculate fraction
// -----------------------------------------------------------

DFPDecomposeReg u1
(
	.clk(clk),
	.ce(ce),
	.i(a),
	.sgn(sa),
	.sx(sx),
	.exp(xa),
	.sig(siga),
	.xz(a_dn),
	.vz(az),
	.inf(aInf),
	.nan(aNan)
);

BCDAddN #(.N(4)) u4 (.ci(1'b0), .a(xa), .b(16'h0001), .o(ex1), .co() );
BCDSRL #(.N(4)) u5 (.ci(1'b0), .i(ex1), .o(xo), .co());

assign so = 1'b0;				// square root of positive numbers only
assign mo = aNan ? {4'h1,aa[N*4-1:0],{N*4{1'b0}}} : sqrto;	//(sqrto << pShiftAmt);
assign sqrinf = aInf;
assign sqrneg = !az & so;

wire [(N+1)*4-1:0] siga1 = xa[0] ? {siga,4'h0} : {4'h0,siga};

wire ldd;
delay1 #(1) u3 (.clk(clk), .ce(ce), .i(ld), .o(ldd));

// Ensure an even number of digits are processed.
dfisqrt #((N+2)&-2) u2
(
	.rst(rst),
	.clk(clk),
	.ce(ce),
	.ld(ldd),
	.a({4'h0,siga1}),
	.o(sqrto),
	.done(done)
);

always @*
casez({aNan,sqrinf,sqrneg})
3'b1??:	o <= {1'b1,sa,1'b0,sx,xa,mo};
3'b01?:	o <= {1'b1,sa,1'b1,sx,4'h1,qNaN|4'h5,{N*4-4{1'b0}}};
3'b001:	o <= {1'b1,sa,1'b0,sx,4'h1,qNaN|4'h6,{N*4-4{1'b0}}};
default:	o <= {1'b0,1'b1,1'b0,sx,xo,mo};
endcase
	

endmodule

module DFPSqrtnr(rst, clk, ce, ld, a, o, rm, done, inf, sqrinf, sqrneg);
parameter N=33;
input rst;
input clk;
input ce;
input ld;
input  [N*4+16+4-1:0] a;
output [N*4+16+4-1:0] o;
input [2:0] rm;
output done;
output inf;
output sqrinf;
output sqrneg;

wire [(N+1)*4*2+16+4-1:0] o1;
wire inf1;
wire [N*4+16+4-1+4:0] fpn0;
wire done1;
wire done2;

DFPSqrt      #(.N(N)) u1 (rst, clk, ce, ld, a, o1, done1, sqrinf, sqrneg);
DFPNormalize #(.N(N)) u2(.clk(clk), .ce(ce), .under_i(1'b0), .i(o1), .o(fpn0) );
DFPRound     #(.N(N)) u3(.clk(clk), .ce(ce), .rm(rm), .i(fpn0), .o(o) );
delay2      #(1)   u5(.clk(clk), .ce(ce), .i(inf1), .o(inf));
delay2		#(1)   u8(.clk(clk), .ce(ce), .i(done1), .o(done2));
assign done = done1&done2;

endmodule
