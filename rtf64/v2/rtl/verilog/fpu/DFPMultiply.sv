// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPMultiply.v
//		- decimal floating point multiplier
//		- can issue every clock cycle
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

//`define DFPMUL_PARALLEL	1'b1

module DFPMultiply(clk, ce, ld, a, b, o, sign_exe, inf, overflow, underflow, done);
parameter N=33;
input clk;
input ce;
input ld;
input  [N*4+16+4-1:0] a, b;
output [(N+1)*4*2+16+4-1:0] o;
output sign_exe;
output inf;
output overflow;
output underflow;
output done;
parameter DELAY =
  (FPWID == 128 ? 17 :
  FPWID == 80 ? 17 :
  FPWID == 64 ? 13 :
  FPWID == 40 ? 8 :
  FPWID == 32 ? 2 :
  FPWID == 16 ? 2 : 2);

reg [15:0] xo1;		// extra bit for sign
reg [N*4*2-1:0] mo1;

// constants
wire [15:0] infXp = 16'h9999;	// infinite / NaN - all ones
// The following is the value for an exponent of zero, with the offset
// eg. 8'h7f for eight bit exponent, 11'h7ff for eleven bit exponent, etc.
// The following is a template for a quiet nan. (MSB=1)
wire [N*4-1:0] qNaN  = {4'h1,{104{1'b0}}};

// variables
reg [N*4*2-1:0] sig1;
wire [15:0] ex2;

// Decompose the operands
wire sa, sb;			// sign bit
wire [15:0] xa, xb;	// exponent bits
wire sxa, sxb;
wire [N*4-1:0] siga, sigb;
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

reg under, over;
reg [15:0] sum_ex, sum_ex1;
reg sx0;
wire done1;

DFPDecompose u1a (.i(a), .sgn(sa), .sx(sxa), .exp(xa), .sig(siga), .xz(a_dn), .vz(az), .inf(aInf), .nan(aNan) );
DFPDecompose u1b (.i(b), .sgn(sb), .sx(sxb), .exp(xb), .sig(sigb), .xz(b_dn), .vz(bz), .inf(bInf), .nan(bNan) );

// Compute the sum of the exponents.
// Exponents are sign-magnitude.
wire [15:0] xapxb, xamxb, xbmxa;
wire xapxbc, xamxbc, xbmxac;
BCDAddN #(.N(4)) u1c (.ci(1'b0), .a(xa), .b(xb), .o(xapxb), .co(xapxbc));
BCDSubN #(.N(4)) u1d (.ci(1'b0), .a(xa), .b(xb), .o(xamxb), .co(xamxbc));
BCDSubN #(.N(4)) u1e (.ci(1'b0), .a(xb), .b(xa), .o(xbmxa), .co(xbmxac));
BCDSubN #(.N(5)) u1h (.ci(1'b0), .a(20'h10000), .b(sum_ex1), .o(sum_ex2), .co());

always @*
	case({sxa,sxb})
	2'b11:	begin sum_ex1 <= xapxb; over <= xapxbc; under <= 1'b0; sx0 <= sxa; end
	2'b01:	begin sum_ex1 <= xbmxa; over <= 1'b0; under <= 1'b0; sx0 <= ~xbmxac; end
	2'b10:	begin sum_ex1 <= xamxb; over <= 1'b0; under <= 1'b0; sx0 <= ~xamxbc; end
	2'b00:	begin sum_ex1 <= xapxb; over <= 1'b0; under <= xapxbc; sx0 <= sxa; end
	endcase

// Take nine's complement if exponent sign changed.
always @*
	if ((sxa^sxb)) begin
		if ((sxa & xamxbc) || (sxb & xbmxac))
			sum_ex <= sum_ex2;
		else
			sum_ex <= sum_ex1;
	end
	else
		sum_ex <= sum_ex1;

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

delay #(.WID(16),.DEP(DELAY)) u3 (.clk(clk), .ce(ce), .i(sum_ex), .o(ex2) );
delay #(.WID(1),.DEP(DELAY)) u2a (.clk(clk), .ce(ce), .i(aInf), .o(aInf1) );
delay #(.WID(1),.DEP(DELAY)) u2b (.clk(clk), .ce(ce), .i(bInf), .o(bInf1) );
delay #(.WID(1),.DEP(DELAY)) u6  (.clk(clk), .ce(ce), .i(under), .o(under1) );
delay #(.WID(1),.DEP(DELAY)) u7  (.clk(clk), .ce(ce), .i(over), .o(over1) );

// determine when a NaN is output
wire qNaNOut;
wire [N*4+16+4-1:0] a1,b1;
delay #(.WID(1),.DEP(DELAY)) u5 (.clk(clk), .ce(ce), .i((aInf&bz)|(bInf&az)), .o(qNaNOut) );
delay #(.WID(1),.DEP(DELAY)) u14 (.clk(clk), .ce(ce), .i(aNan), .o(aNan1) );
delay #(.WID(1),.DEP(DELAY)) u15 (.clk(clk), .ce(ce), .i(bNan), .o(bNan1) );
delay #(.WID(N*4+16+4),.DEP(DELAY))  u16 (.clk(clk), .ce(ce), .i(a), .o(a1) );
delay #(.WID(N*4+16+4),.DEP(DELAY))  u17 (.clk(clk), .ce(ce), .i(b), .o(b1) );

// -----------------------------------------------------------
// Second clock
// - correct xponent and mantissa for exceptional conditions
// -----------------------------------------------------------

wire so1, sx1;
reg [3:0] st;
wire done1a;

delay #(.WID(1),.DEP(1)) u8 (.clk(clk), .ce(ce), .i(~(sa ^ sb)), .o(so1) );// two clock delay!
delay #(.WID(1),.DEP(1)) u9 (.clk(clk), .ce(ce), .i(sx0), .o(sx1) );// two clock delay!

always @(posedge clk)
	if (ce)
		casez({qNaNOut|aNan1|bNan1,aInf1,bInf1,over1,under1})
		5'b1????:	xo1 = infXp;	// qNaN - infinity * zero
		5'b01???:	xo1 = infXp;	// 'a' infinite
		5'b001??:	xo1 = infXp;	// 'b' infinite
		5'b0001?:	xo1 = infXp;	// result overflow
		5'b00001:	xo1 = ex2[15:0];//0;		// underflow
		default:	xo1 = ex2[15:0];	// situation normal
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

always @(posedge clk)
	if (ce) begin
		st[3] <= aNan1|bNan1;
		st[2] <= so1;
		st[1] <= aInf|bInf|over;
		st[0] <= sx1;
	end

delay #(.WID(1),.DEP(DELAY+1)) u10 (.clk(clk), .ce(ce), .i(sa & sb), .o(sign_exe) );
delay1 u11 (.clk(clk), .ce(ce), .i(over1),  .o(overflow) );
delay1 u12 (.clk(clk), .ce(ce), .i(over1),  .o(inf) );
delay1 u13 (.clk(clk), .ce(ce), .i(under1), .o(underflow) );
delay #(.WID(1),.DEP(3)) u18 (.clk(clk), .ce(ce), .i(done1), .o(done1a) );

assign o = {st,xo1,mo1,8'h00};
assign done = done1&done1a;

endmodule


// Multiplier with normalization and rounding.

module DFPMultiplynr(clk, ce, ld, a, b, o, rm, sign_exe, inf, overflow, underflow, done);
parameter N=33;
input clk;
input ce;
input ld;
input  [N*4+16+4-1:0] a, b;
output [N*4+16+4-1:0] o;
input [2:0] rm;
output sign_exe;
output inf;
output overflow;
output underflow;
output done;

wire done1, done1a;
wire [(N+1)*4*2+16+4-1:0] o1;
wire sign_exe1, inf1, overflow1, underflow1;
wire [N*4+16+4-1+4:0] fpn0;

DFPMultiply  u1 (clk, ce, ld, a, b, o1, sign_exe1, inf1, overflow1, underflow1, done1);
DFPNormalize u2(.clk(clk), .ce(ce), .under_i(underflow1), .i(o1), .o(fpn0) );
DFPRound     u3(.clk(clk), .ce(ce), .rm(rm), .i(fpn0), .o(o) );
delay2      #(1)   u4(.clk(clk), .ce(ce), .i(sign_exe1), .o(sign_exe));
delay2      #(1)   u5(.clk(clk), .ce(ce), .i(inf1), .o(inf));
delay2      #(1)   u6(.clk(clk), .ce(ce), .i(overflow1), .o(overflow));
delay2      #(1)   u7(.clk(clk), .ce(ce), .i(underflow1), .o(underflow));
delay #(.WID(1),.DEP(11)) u10 (.clk(clk), .ce(ce), .i(done1), .o(done1a) );
assign done = done1 & done1a;

endmodule
