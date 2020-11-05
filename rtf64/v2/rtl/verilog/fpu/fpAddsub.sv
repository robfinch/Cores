// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpAddsub.sv
//    - floating point adder/subtracter
//    - can issue every clock cycle
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

module fpAddsub(clk, ce, rm, op, a, b, o);
input clk;		// system clock
input ce;		// core clock enable
input [2:0] rm;	// rounding mode
input op;		// operation 0 = add, 1 = subtract
input [MSB:0] a;	// operand a
input [MSB:0] b;	// operand b
output [EX:0] o;	// output


// variables
// operands sign,exponent,mantissa
wire sa, sb;
wire [EMSB:0] xa, xb;
wire [FMSB:0] ma, mb;
wire [FMSB+1:0] fracta, fractb;
wire az, bz;	// operand a,b is zero

wire adn, bdn;		// a,b denormalized ?
wire xaInf, xbInf;
wire aInf, bInf;
wire aNan, bNan;

wire [EMSB:0] xad = xa|adn;	// operand a exponent, compensated for denormalized numbers
wire [EMSB:0] xbd = xb|bdn; // operand b exponent, compensated for denormalized numbers

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #1
// - decode the input operands
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg op1;

fpDecompReg u1a (.clk(clk), .ce(ce), .i(a), .sgn(sa), .exp(xa), .man(ma), .fract(fracta), .xz(adn), .vz(az), .xinf(xaInf), .inf(aInf), .nan(aNan) );
fpDecompReg u1b (.clk(clk), .ce(ce), .i(b), .sgn(sb), .exp(xb), .man(mb), .fract(fractb), .xz(bdn), .vz(bz), .xinf(xbInf), .inf(bInf), .nan(bNan) );
always @(posedge clk)
  if (ce) op1 <= op;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #2
//
// Figure out which operation is really needed an add or subtract ?
// If the signs are the same, use the orignal op,
// otherwise flip the operation
//  a +  b = add,+
//  a + -b = sub, so of larger
// -a +  b = sub, so of larger
// -a + -b = add,-
//  a -  b = sub, so of larger
//  a - -b = add,+
// -a -  b = add,-
// -a - -b = sub, so of larger
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg realOp2;
reg op2;
reg [EMSB:0] xa2, xb2;
reg [FMSB:0] ma2, mb2;
reg az2, bz2;
reg xa_gt_xb2;
reg [FMSB+1:0] fracta2, fractb2;
reg maneq, ma_gt_mb;
reg expeq;

always @(posedge clk)
  if (ce) realOp2 = op1 ^ sa ^ sb;
always @(posedge clk)
  if (ce) op2 <= op1;
always @(posedge clk)
  if (ce) xa2 <= xad;
always @(posedge clk)
  if (ce) xb2 <= xbd;
always @(posedge clk)
  if (ce) ma2 <= ma;
always @(posedge clk)
  if (ce) mb2 <= mb;
always @(posedge clk)
  if (ce) fracta2 <= fracta;
always @(posedge clk)
  if (ce) fractb2 <= fractb;
always @(posedge clk)
  if (ce) az2 <= az;  
always @(posedge clk)
  if (ce) bz2 <= bz;  
always @(posedge clk)
  if (ce) xa_gt_xb2 <= xad > xbd;
always @(posedge clk)
  if (ce) maneq <= ma==mb;
always @(posedge clk)
  if (ce) ma_gt_mb <= ma > mb;
always @(posedge clk)
  if (ce) expeq <= xad==xbd;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #3
//
// Find out if the result will be zero.
// Determine which fraction to denormalize
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
reg [EMSB:0] xa3, xb3;
reg resZero3;
wire xaInf3, xbInf3;
reg xa_gt_xb3;
reg a_gt_b3;
reg op3;
wire sa3, sb3;
wire [2:0] rm3;
reg [FMSB+1:0] mfs3;

always @(posedge clk)
  if (ce) resZero3 <= (realOp2 & expeq & maneq) ||	// subtract, same magnitude
			   (az2 & bz2);		// both a,b zero
always @(posedge clk)
  if (ce) xa3 <= xa2;
always @(posedge clk)
  if (ce) xb3 <= xb2;
always @(posedge clk)
  if (ce) xa_gt_xb3 <= xa_gt_xb2;
always @(posedge clk)
  if (ce) a_gt_b3 <= xa_gt_xb2 | (expeq & ma_gt_mb);
always @(posedge clk)
  if (ce) op3 <= op2;
always @(posedge clk)
  if (ce) mfs3 = xa_gt_xb2 ? fractb2 : fracta2;

delay #(.WID(1), .DEP(2)) udly3a (.clk(clk), .ce(ce), .i(xaInf), .o(xaInf3));
delay #(.WID(1), .DEP(2)) udly3b (.clk(clk), .ce(ce), .i(xbInf), .o(xbInf3));
delay #(.WID(1), .DEP(2)) udly3c (.clk(clk), .ce(ce), .i(sa), .o(sa3));
delay #(.WID(1), .DEP(2)) udly3d (.clk(clk), .ce(ce), .i(sb), .o(sb3));
delay #(.WID(3), .DEP(3)) udly3e (.clk(clk), .ce(ce), .i(rm), .o(rm3));
delay #(.WID(1), .DEP(2)) udly3f (.clk(clk), .ce(ce), .i(aInf), .o(aInf3));
delay #(.WID(1), .DEP(2)) udly3g (.clk(clk), .ce(ce), .i(bInf), .o(bInf3));

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #4
//
// Compute output exponent
//
// The output exponent is the larger of the two exponents,
// unless a subtract operation is in progress and the two
// numbers are equal, in which case the exponent should be
// zero.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

reg [EMSB:0] xa4, xb4;
reg [EMSB:0] xo4;
reg xa_gt_xb4;
reg xa4,xb4;

always @(posedge clk)
  if (ce) xa4 <= xa3;
always @(posedge clk)
  if (ce) xb4 <= xb3;
always @(posedge clk)
	if (ce) xo4 <= (xaInf3&xbInf3) ? {EMSB+1{1'b1}} : resZero3 ? 0 : xa_gt_xb3 ? xa3 : xb3;
always @(posedge clk)
  if (ce) xa_gt_xb4 <= xa_gt_xb3;

// Compute output sign
reg so4;
always @*
	case ({resZero3,sa3,op3,sb3})	// synopsys full_case parallel_case
	4'b0000: so4 <= 0;			// + + + = +
	4'b0001: so4 <= !a_gt_b3;	// + + - = sign of larger
	4'b0010: so4 <= !a_gt_b3;	// + - + = sign of larger
	4'b0011: so4 <= 0;			// + - - = +
	4'b0100: so4 <= a_gt_b3;		// - + + = sign of larger
	4'b0101: so4 <= 1;			// - + - = -
	4'b0110: so4 <= 1;			// - - + = -
	4'b0111: so4 <= a_gt_b3;		// - - - = sign of larger
	4'b1000: so4 <= 0;			//  A +  B, sign = +
	4'b1001: so4 <= rm3==3'd3;		//  A + -B, sign = + unless rounding down
	4'b1010: so4 <= rm3==3'd3;		//  A -  B, sign = + unless rounding down
	4'b1011: so4 <= 0;			// +A - -B, sign = +
	4'b1100: so4 <= rm3==3'd3;		// -A +  B, sign = + unless rounding down
	4'b1101: so4 <= 1;			// -A + -B, sign = -
	4'b1110: so4 <= 1;			// -A - +B, sign = -
	4'b1111: so4 <= rm3==3'd3;		// -A - -B, sign = + unless rounding down
	endcase

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #5
//
// Compute the difference in exponents, provides shift amount
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [EMSB+1:0] xdiff5;
always @(posedge clk)
  if (ce) xdiff5 <= xa_gt_xb4 ? xa4 - xb4 : xb4 - xa4;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #6
//
// Compute the difference in exponents, provides shift amount
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// If the difference in the exponent is 128 or greater (assuming 128 bit fp or
// less) then all of the bits will be shifted out to zero. There is no need to
// keep track of a difference more than 128.
reg [7:0] xdif6;
wire [FMSB+1:0] mfs6;
always @(posedge clk)
  if (ce) xdif6 <= xdiff5 > FMSB+4 ? FMSB+4 : xdiff5;
delay #(.WID(FMSB+2), .DEP(3)) udly6a (.clk(clk), .ce(ce), .i(mfs3), .o(mfs6));

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #7
//
// Determine the sticky bit. The sticky bit is the bitwise or of all the bits
// being shifted out the right side. The sticky bit is computed here to
// reduce the number of regs required.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg sticky6;
wire sticky7;
wire [7:0] xdif7;
wire [FMSB+1:0] mfs7;
integer n;
always @* begin
	sticky6 = 1'b0;
	for (n = 0; n < FMSB+2; n = n + 1)
		if (n <= xdif6)
			sticky6 = sticky6|mfs6[n];
end

// register inputs to shifter and shift
delay1 #(1)      d16(.clk(clk), .ce(ce), .i(sticky6), .o(sticky7) );
delay1 #(8)      d15(.clk(clk), .ce(ce), .i(xdif6),   .o(xdif7) );
delay1 #(FMSB+2) d14(.clk(clk), .ce(ce), .i(mfs6),    .o(mfs7) );

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #8
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [FMSB+4:0] md8;
wire [FMSB+1:0] fracta8, fractb8;
wire xa_gt_xb8;
wire a_gt_b8;
always @(posedge clk)
  if (ce) md8 <= ({mfs7,3'b0} >> xdif7)|sticky7;

// sync control signals
delay #(.WID(1), .DEP(4)) udly8a (.clk(clk), .ce(ce), .i(xa_gt_xb4), .o(xa_gt_xb8));
delay #(.WID(1), .DEP(5)) udly8b (.clk(clk), .ce(ce), .i(a_gt_b3), .o(a_gt_b8));
delay #(.WID(FMSB+2), .DEP(6)) udly8d (.clk(clk), .ce(ce), .i(fracta2), .o(fracta8));
delay #(.WID(FMSB+2), .DEP(6)) udly8e (.clk(clk), .ce(ce), .i(fractb2), .o(fractb8));
delay #(.WID(1), .DEP(5)) udly8j (.clk(clk), .ce(ce), .i(op3), .o(op8));

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #9
// Sort operands and perform add/subtract
// addition can generate an extra bit, subtract can't go negative
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [FMSB+4:0] oa9, ob9;
reg a_gt_b9;
always @(posedge clk)
  if (ce) oa9 <= xa_gt_xb8 ? {fracta8,3'b0} : md8;
always @(posedge clk)
  if (ce) ob9 <= xa_gt_xb8 ? md8 : {fractb8,3'b0};
always @(posedge clk)
  if (ce) a_gt_b9 <= a_gt_b8;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #10
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [FMSB+4:0] oaa10;
reg [FMSB+4:0] obb10;
wire realOp10;
reg [EMSB:0] xo10;

always @(posedge clk)
  if (ce) oaa10 <= a_gt_b9 ? oa9 : ob9;
always @(posedge clk)
  if (ce) obb10 <= a_gt_b9 ? ob9 : oa9;
delay #(.WID(1), .DEP(8)) udly10a (.clk(clk), .ce(ce), .i(realOp2), .o(realOp10));
delay #(.WID(EMSB+1), .DEP(6)) udly10b (.clk(clk), .ce(ce), .i(xo4), .o(xo10));

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #11
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [FMSB+5:0] mab11;
wire [FMSB+1:0] fracta11, fractb11;
wire abInf11;
wire aNan11, bNan11;
reg xoinf11;
wire op11;

always @(posedge clk)
  if (ce) mab11 <= realOp10 ? oaa10 - obb10 : oaa10 + obb10;
delay #(.WID(1), .DEP(8)) udly11a (.clk(clk), .ce(ce), .i(aInf3&bInf3), .o(abInf11));
delay #(.WID(1), .DEP(10)) udly11c (.clk(clk), .ce(ce), .i(aNan), .o(aNan11));
delay #(.WID(1), .DEP(10)) udly11d (.clk(clk), .ce(ce), .i(bNan), .o(bNan11));
delay #(.WID(1), .DEP(3)) udly11e (.clk(clk), .ce(ce), .i(op8), .o(op11));
delay #(.WID(FMSB+2), .DEP(3)) udly11f (.clk(clk), .ce(ce), .i(fracta8), .o(fracta11));
delay #(.WID(FMSB+2), .DEP(3)) udly11g (.clk(clk), .ce(ce), .i(fractb8), .o(fractb11));

always @(posedge clk)
  if (ce) xoinf11 <= &xo10;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #12
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [FX:0] mo12;	// mantissa output

always @(posedge clk)
if (ce)
	casez({abInf11,aNan11,bNan11,xoinf11})
	4'b1???:	mo12 <= {1'b0,op11,{FMSB-1{1'b0}},op11,{FMSB{1'b0}}};	// inf +/- inf - generate QNaN on subtract, inf on add
	4'b01??:	mo12 <= {1'b0,fracta11[FMSB+1:0],{FMSB{1'b0}}};
	4'b001?: 	mo12 <= {1'b0,fractb11[FMSB+1:0],{FMSB{1'b0}}};
	4'b0001:	mo12 <= 1'd0;
	default:	mo12 <= {mab11,{FMSB-2{1'b0}}};	// mab has an extra lead bit and three trailing bits
	endcase

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #13
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
wire so;			// sign output
wire [EMSB:0] xo;	// de normalized exponent output
wire [FX:0] mo;	// mantissa output

delay #(.WID(1), .DEP(9)) udly13a (.clk(clk), .ce(ce), .i(so4), .o(so));
delay #(.WID(EMSB+1), .DEP(3)) udly13b (.clk(clk), .ce(ce), .i(xo10), .o(xo));
delay #(.WID(FX+1), .DEP(1)) u13c (.clk(clk), .ce(ce), .i(mo12), .o(mo) );

assign o = {so,xo,mo};

endmodule

module fpAddsubnr(clk, ce, rm, op, a, b, o);
input clk;		// system clock
input ce;		// core clock enable
input [2:0] rm;	// rounding mode
input op;		// operation 0 = add, 1 = subtract
input [MSB:0] a;	// operand a
input [MSB:0] b;	// operand b
output [MSB:0] o;	// output

wire [EX:0] o1;
wire [MSB+3:0] fpn0;

fpAddsub    u1 (clk, ce, rm, op, a, b, o1);
fpNormalize u2(.clk(clk), .ce(ce), .under_i(1'b0), .i(o1), .o(fpn0) );
fpRound  		u3(.clk(clk), .ce(ce), .rm(rm), .i(fpn0), .o(o) );

endmodule
