// ============================================================================
//        __
//   \\__/ o\    (C) 2020-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPMultiply128.v
//		- decimal floating point multiplier
//		- parameterized width
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
//	Properties:
//	+-inf * +-inf = -+inf	(this is handled by exOver)
//	+-inf * 0     = QNaN
//	
// ============================================================================

import DFPPkg::*;

//`define DFPMUL_PARALLEL	1'b1

module DFPMultiply128(clk, ce, ld, a, b, o, sign_exe, inf, overflow, underflow, done);
localparam N=34;
localparam DELAY = 2;
input clk;
input ce;
input ld;
input  DFP128 a, b;
output DFP128UD o;
output sign_exe;
output inf;
output overflow;
output underflow;
output done;

reg [13:0] xo1;		// extra bit for sign
reg [N*4*2-1:0] mo1;

// constants
wire [13:0] infXp = 14'h2FFF;	// infinite / NaN - all ones
wire [13:0] bias = 14'h17FF;
// The following is the value for an exponent of zero, with the offset
// eg. 8'h7f for eight bit exponent, 11'h7ff for eleven bit exponent, etc.
// The following is a template for a quiet nan. (MSB=1)
wire [N*4-1:0] qNaN  = {4'h1,{104{1'b0}}};

// variables
reg [N*4*2-1:0] sig1;
wire [13:0] ex2;

DFP128U au, bu;
DFPUnpack128 u01 (a, au);
DFPUnpack128 u02 (b, bu);

// Decompose the operands
wire sa, sb;			// sign bit
wire [13:0] xa, xb;	// exponent bits
wire sxa, sxb;
wire [N*4-1:0] siga, sigb;
wire a_dn, b_dn;			// a/b is denormalized
wire aNan1, bNan1;
wire az, bz;
wire aInf1, bInf1;

assign siga = au.sig;
assign sigb = bu.sig;
assign az = au.exp==14'h0 && au.sig==136'd0;
assign bz = bu.exp==14'h0 && bu.sig==136'd0;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #1
// - decode the input operands
// - derive basic information
// - calculate exponent
// - calculate fraction
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

// -----------------------------------------------------------
// First clock
// Compute the sum of the exponents.
// -----------------------------------------------------------

wire under, over;
wire [15:0] sum_ex = au.exp + bu.exp - bias;
reg [15:0] sum_ex;
reg sx0;
wire done1;
assign under = &sum_ex[15:14];
assign over = sum_ex > 16'h2FFF;

wire [N*4*2-1:0] sigoo;
`ifdef DFPMUL_PARALLEL
BCDMul32 u1f (.a({20'h0,siga}),.b({20'h0,sigb}),.o(sigoo));
`else
dfmul #(.N(N)) u1g 
(
	.clk(clk),
	.ld(ld),
	.a(siga),
	.b(sigb),
	.p(sigoo),
	.done(done1)
);
`endif

always @(posedge clk)
  if (ce) sig1 <= sigoo[N*4*2-1:0];

// Status
wire under1, over1;

delay #(.WID(14),.DEP(DELAY)) u3 (.clk(clk), .ce(ce), .i(sum_ex[13:0]), .o(ex2) );
delay #(.WID(1),.DEP(DELAY)) u2a (.clk(clk), .ce(ce), .i(au.infinity), .o(aInf1) );
delay #(.WID(1),.DEP(DELAY)) u2b (.clk(clk), .ce(ce), .i(bu.infinity), .o(bInf1) );
delay #(.WID(1),.DEP(DELAY)) u6  (.clk(clk), .ce(ce), .i(under), .o(under1) );
delay #(.WID(1),.DEP(DELAY)) u7  (.clk(clk), .ce(ce), .i(over), .o(over1) );

// determine when a NaN is output
wire qNaNOut;
wire DFP128U a1,b1;
wire asnan, bsnan, aqnan, bqnan;
delay #(.WID(1),.DEP(DELAY)) u5 (.clk(clk), .ce(ce), .i((au.infinity&bz)|(bu.infinity&az)), .o(qNaNOut) );
delay #(.WID(1),.DEP(DELAY)) u14 (.clk(clk), .ce(ce), .i(au.nan), .o(aNan1) );
delay #(.WID(1),.DEP(DELAY)) u15 (.clk(clk), .ce(ce), .i(bu.nan), .o(bNan1) );
delay #(.WID(1),.DEP(DELAY)) u18 (.clk(clk), .ce(ce), .i(au.snan), .o(asnan) );
delay #(.WID(1),.DEP(DELAY)) u19 (.clk(clk), .ce(ce), .i(bu.snan), .o(bsnan) );
delay #(.WID(1),.DEP(DELAY)) u18a (.clk(clk), .ce(ce), .i(au.qnan), .o(aqnan) );
delay #(.WID(1),.DEP(DELAY)) u19a (.clk(clk), .ce(ce), .i(bu.qnan), .o(bqnan) );
delay #(.WID($bits(a1)),.DEP(DELAY))  u16 (.clk(clk), .ce(ce), .i(a), .o(a1) );
delay #(.WID($bits(b1)),.DEP(DELAY))  u17 (.clk(clk), .ce(ce), .i(b), .o(b1) );

// -----------------------------------------------------------
// Second clock
// - correct xponent and mantissa for exceptional conditions
// -----------------------------------------------------------

wire so1, sx1;
reg [3:0] st;
wire done1a;

delay #(.WID(1),.DEP(1)) u8 (.clk(clk), .ce(ce), .i(au.sign ^ bu.sign), .o(so1) );// two clock delay!

always @(posedge clk)
	if (ce)
		casez({qNaNOut|aNan1|bNan1,aInf1,bInf1,over1,under1})
		5'b1????:	xo1 = infXp;	// qNaN - infinity * zero
		5'b01???:	xo1 = infXp;	// 'a' infinite
		5'b001??:	xo1 = infXp;	// 'b' infinite
		5'b0001?:	xo1 = infXp;	// result overflow
		5'b00001:	xo1 = ex2[13:0];//0;		// underflow
		default:	xo1 = ex2[13:0];	// situation normal
		endcase

// Force mantissa to zero when underflow or zero exponent when not supporting denormals.
always @(posedge clk)
	if (ce)
		casez({aNan1,bNan1,qNaNOut,aInf1,bInf1,over1|under1})
		6'b1?????:  mo1 = {4'h1,a1[N*4-4-1:0],{N*4{1'b0}}};
    6'b01????:  mo1 = {4'h1,b1[N*4-4-1:0],{N*4{1'b0}}};
		6'b001???:	mo1 = {4'h1,qNaN|3'd4,{N*4{1'b0}}};	// multiply inf * zero
		6'b0001??:	mo1 = 0;	// mul inf's
		6'b00001?:	mo1 = 0;	// mul inf's
		6'b000001:	mo1 = 0;	// mul overflow
		default:	mo1 = sig1;
		endcase

delay #(.WID(1),.DEP(DELAY+1)) u10 (.clk(clk), .ce(ce), .i(sa & sb), .o(sign_exe) );
delay1 u11 (.clk(clk), .ce(ce), .i(over1),  .o(overflow) );
delay1 u12 (.clk(clk), .ce(ce), .i(over1),  .o(inf) );
delay1 u13 (.clk(clk), .ce(ce), .i(under1), .o(underflow) );
delay #(.WID(1),.DEP(3)) u18b (.clk(clk), .ce(ce), .i(done1), .o(done1a) );

assign o.nan = aNan1|bNan1|qNaNOut;
assign o.qnan = qNaNOut|aqnan|bqnan;
assign o.snan = qNaNOut ? 1'b0 : asnan|bsnan;
assign o.infinity = aInf1|bInf1|over;
assign o.sign = so1;
assign o.exp = xo1;
assign o.sig = {mo1,8'h00};
assign done = done1&done1a;

endmodule


// Multiplier with normalization and rounding.

module DFPMultiply128nr(clk, ce, ld, a, b, o, rm, sign_exe, inf, overflow, underflow, done);
localparam N=34;
input clk;
input ce;
input ld;
input  DFP128 a, b;
output DFP128 o;
input [2:0] rm;
output sign_exe;
output inf;
output overflow;
output underflow;
output done;

wire done1, done1a;
DFP128UD o1;
wire sign_exe1, inf1, overflow1, underflow1;
DFP128UN fpn0;

DFPMultiply128  u1 (clk, ce, ld, a, b, o1, sign_exe1, inf1, overflow1, underflow1, done1);
DFPNormalize128 u2(.clk(clk), .ce(ce), .under_i(underflow1), .i(o1), .o(fpn0) );
DFPRound128     u3(.clk(clk), .ce(ce), .rm(rm), .i(fpn0), .o(o) );
delay2      #(1)   u4(.clk(clk), .ce(ce), .i(sign_exe1), .o(sign_exe));
delay2      #(1)   u5(.clk(clk), .ce(ce), .i(inf1), .o(inf));
delay2      #(1)   u6(.clk(clk), .ce(ce), .i(overflow1), .o(overflow));
delay2      #(1)   u7(.clk(clk), .ce(ce), .i(underflow1), .o(underflow));
delay #(.WID(1),.DEP(12)) u10 (.clk(clk), .ce(ce), .i(done1), .o(done1a) );
assign done = done1 & done1a;

endmodule
