// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpMultiply.v
//		- floating point multiplier
//		- two cycle latency minimum (latency depends on precision)
//		- can issue every clock cycle
//		- parameterized width
//		- IEEE 754 representation
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
//
//	Floating Point Multiplier
//
//	This multiplier handles denormalized numbers.
//	The output format is of an internal expanded representation
//	in preparation to be fed into a normalization unit, then
//	rounding. Basically, it's the same as the regular format
//	except the mantissa is doubled in size, the leading two
//	bits of which are assumed to be whole bits.
//
//
//	Floating Point Multiplier
//
//	Properties:
//	+-inf * +-inf = -+inf	(this is handled by exOver)
//	+-inf * 0     = QNaN
//	
// ============================================================================

import fp::*;

module fpMultiply(clk, ce, a, b, o, sign_exe, inf, overflow, underflow);
input clk;
input ce;
input  [MSB:0] a, b;
output [EX:0] o;
output sign_exe;
output inf;
output overflow;
output underflow;
parameter DELAY =
  (FPWID == 128 ? 17 :
  FPWID == 80 ? 17 :
  FPWID == 64 ? 13 :
  FPWID == 40 ? 8 :
  FPWID == 32 ? 2 :
  FPWID == 16 ? 2 : 2);

reg [EMSB:0] xo1;		// extra bit for sign
reg [FX:0] mo1;

// constants
wire [EMSB:0] infXp = {EMSB+1{1'b1}};	// infinite / NaN - all ones
// The following is the value for an exponent of zero, with the offset
// eg. 8'h7f for eight bit exponent, 11'h7ff for eleven bit exponent, etc.
wire [EMSB:0] bias = {1'b0,{EMSB{1'b1}}};	//2^0 exponent
// The following is a template for a quiet nan. (MSB=1)
wire [FMSB:0] qNaN  = {1'b1,{FMSB{1'b0}}};

// variables
reg [FX:0] fract1,fract1a;
wire [FX:0] fracto;
wire [EMSB+2:0] ex1;	// sum of exponents
wire [EMSB  :0] ex2;

// Decompose the operands
wire sa, sb;			// sign bit
wire [EMSB:0] xa, xb;	// exponent bits
wire [FMSB+1:0] fracta, fractb;
wire a_dn, b_dn;			// a/b is denormalized
wire aNan, bNan, aNan1, bNan1;
wire az, bz;
wire aInf, bInf, aInf1, bInf1;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #1
// - decode the input operands
// - derive basic information
// - calculate exponent
// - calculate fraction
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

// -----------------------------------------------------------
// First clock
// -----------------------------------------------------------

fpDecomp u1a (.i(a), .sgn(sa), .exp(xa), .fract(fracta), .xz(a_dn), .vz(az), .inf(aInf), .nan(aNan) );
fpDecomp u1b (.i(b), .sgn(sb), .exp(xb), .fract(fractb), .xz(b_dn), .vz(bz), .inf(bInf), .nan(bNan) );

// Compute the sum of the exponents.
// correct the exponent for denormalized operands
// adjust the sum by the exponent offset (subtract 127)
// mul: ex1 = xa + xb,	result should always be < 1ffh
`ifdef SUPPORT_DENORMALS
assign ex1 = (az|bz) ? 0 : (xa|a_dn) + (xb|b_dn) - bias;
`else
assign ex1 = (az|bz) ? 0 : xa + xb - bias;
`endif

generate
if (FPWID==128) begin
  wire [255:0] fractoo;
  mult128x128 umul1 (.clk(clk), .ce(ce), .a({16'b0,fracta}), .b({16'b0,fractb}), .o(fractoo));
  always @(posedge clk)
    if (ce) fract1 <= fractoo[224:0];
end
else if (FPWID==80) begin
  wire [255:0] fractoo;
  mult128x128 umul1 (.clk(clk), .ce(ce), .a({63'd0,fracta}), .b({63'd0,fractb}), .o(fractoo));
  always @(posedge clk)
    if (ce) fract1 <= fractoo[130:0];
end
else if (FPWID==64) begin
  wire [127:0] fractoo;
  mult64x64 umul1 (.clk(clk), .ce(ce), .a({11'd0,fracta}), .b({11'd0,fractb}), .o(fractoo));
  always @(posedge clk)
    if (ce) fract1 <= fractoo[106:0];
end
else if (FPWID==40) begin
  wire [63:0] fractoo;
  mult32x32 umul1 (.clk(clk), .ce(ce), .a({3'd0,fracta}), .b({3'd0,fractb}), .o(fractoo));
  always @(posedge clk)
    if (ce) fract1 <= fractoo[58:0];
end
else if (FPWID==32) begin
  reg [23:0] p00,p11;
  always @(posedge clk)
  	if (ce) begin
  	  p00 <= fracta[23: 0] * fractb[11: 0];
  	  p11 <= fracta[23: 0] * fractb[23:12];
  		fract1 <= {p11,12'b0} + p00;
  	end
end
else begin
	always @(posedge clk)
    if (ce) begin
    	fract1a <= fracta * fractb;
      fract1 <= fract1a;
    end
end
endgenerate

// Status
wire under1, over1;
wire under = ex1[EMSB+2];	// exponent underflow
wire over = (&ex1[EMSB:0] | ex1[EMSB+1]) & !ex1[EMSB+2];

delay #(.WID(EMSB+1),.DEP(DELAY)) u3 (.clk(clk), .ce(ce), .i(ex1[EMSB:0]), .o(ex2) );
delay #(.WID(1),.DEP(DELAY)) u2a (.clk(clk), .ce(ce), .i(aInf), .o(aInf1) );
delay #(.WID(1),.DEP(DELAY)) u2b (.clk(clk), .ce(ce), .i(bInf), .o(bInf1) );
delay #(.WID(1),.DEP(DELAY)) u6  (.clk(clk), .ce(ce), .i(under), .o(under1) );
delay #(.WID(1),.DEP(DELAY)) u7  (.clk(clk), .ce(ce), .i(over), .o(over1) );

// determine when a NaN is output
wire qNaNOut;
wire [FPWID-1:0] a1,b1;
delay #(.WID(1),.DEP(DELAY)) u5 (.clk(clk), .ce(ce), .i((aInf&bz)|(bInf&az)), .o(qNaNOut) );
delay #(.WID(1),.DEP(DELAY)) u14 (.clk(clk), .ce(ce), .i(aNan), .o(aNan1) );
delay #(.WID(1),.DEP(DELAY)) u15 (.clk(clk), .ce(ce), .i(bNan), .o(bNan1) );
delay #(.WID(FPWID),.DEP(DELAY))  u16 (.clk(clk), .ce(ce), .i(a), .o(a1) );
delay #(.WID(FPWID),.DEP(DELAY))  u17 (.clk(clk), .ce(ce), .i(b), .o(b1) );

// -----------------------------------------------------------
// Second clock
// - correct xponent and mantissa for exceptional conditions
// -----------------------------------------------------------

wire so1;
delay #(.WID(1),.DEP(DELAY+1)) u8 (.clk(clk), .ce(ce), .i(sa ^ sb), .o(so1) );// two clock delay!

always @(posedge clk)
	if (ce)
		casez({qNaNOut|aNan1|bNan1,aInf1,bInf1,over1,under1})
		5'b1????:	xo1 = infXp;	// qNaN - infinity * zero
		5'b01???:	xo1 = infXp;	// 'a' infinite
		5'b001??:	xo1 = infXp;	// 'b' infinite
		5'b0001?:	xo1 = infXp;	// result overflow
		5'b00001:	xo1 = ex2[EMSB:0];//0;		// underflow
		default:	xo1 = ex2[EMSB:0];	// situation normal
		endcase

// Force mantissa to zero when underflow or zero exponent when not supporting denormals.
always @(posedge clk)
	if (ce)
`ifdef SUPPORT_DENORMALS
		casez({aNan1,bNan1,qNaNOut,aInf1,bInf1,over1})
`else
		casez({aNan1,bNan1,qNaNOut,aInf1,bInf1,over1|under1})
`endif
		6'b1?????:  mo1 = {1'b1,a1[FMSB:0],{FMSB+1{1'b0}}};
    6'b01????:  mo1 = {1'b1,b1[FMSB:0],{FMSB+1{1'b0}}};
		6'b001???:	mo1 = {1'b1,qNaN|3'd4,{FMSB+1{1'b0}}};	// multiply inf * zero
		6'b0001??:	mo1 = 0;	// mul inf's
		6'b00001?:	mo1 = 0;	// mul inf's
		6'b000001:	mo1 = 0;	// mul overflow
		default:	mo1 = fract1;
		endcase

delay #(.WID(1),.DEP(DELAY+1)) u10 (.clk(clk), .ce(ce), .i(sa & sb), .o(sign_exe) );
delay1 u11 (.clk(clk), .ce(ce), .i(over1),  .o(overflow) );
delay1 u12 (.clk(clk), .ce(ce), .i(over1),  .o(inf) );
delay1 u13 (.clk(clk), .ce(ce), .i(under1), .o(underflow) );

assign o = {so1,xo1,mo1};

endmodule


// Multiplier with normalization and rounding.

module fpMultiplynr(clk, ce, a, b, o, rm, sign_exe, inf, overflow, underflow);
input clk;
input ce;
input  [MSB:0] a, b;
output [MSB:0] o;
input [2:0] rm;
output sign_exe;
output inf;
output overflow;
output underflow;

wire [EX:0] o1;
wire sign_exe1, inf1, overflow1, underflow1;
wire [MSB+3:0] fpn0;

fpMultiply  u1 (clk, ce, a, b, o1, sign_exe1, inf1, overflow1, underflow1);
fpNormalize u2(.clk(clk), .ce(ce), .under_i(underflow1), .i(o1), .o(fpn0) );
fpRound     u3(.clk(clk), .ce(ce), .rm(rm), .i(fpn0), .o(o) );
delay2      #(1)   u4(.clk(clk), .ce(ce), .i(sign_exe1), .o(sign_exe));
delay2      #(1)   u5(.clk(clk), .ce(ce), .i(inf1), .o(inf));
delay2      #(1)   u6(.clk(clk), .ce(ce), .i(overflow1), .o(overflow));
delay2      #(1)   u7(.clk(clk), .ce(ce), .i(underflow1), .o(underflow));
endmodule
