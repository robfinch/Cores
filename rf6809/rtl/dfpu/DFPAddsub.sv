// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPAddsub.sv
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

module DFPAddsub(clk, ce, rm, op, a, b, o);
parameter N=33;
input clk;
input ce;
input [2:0] rm;
input op;
input [N*4+16+4-1:0] a;
input [N*4+16+4-1:0] b;
output [(N+1)*4*2+16+4-1:0] o;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

wire sa, sb;
wire sxa, sxb;
wire adn, bdn;
wire xainf, xbinf;
wire ainf, binf;
wire aNan, bNan;
wire [15:0] xa, xb;
wire [N*4-1:0] siga, sigb;

wire [15:0] xabdif4;
BCDSub4 ubcds1(
	.ci(1'b0),
	.a(xa_gt_xb4 ? xa4 : xb4),
	.b(xa_gt_xb4 ? xb4 : xa4),
	.o(xabdif4),
	.c(),
	.c8()
);

wire [(N+1)*4-1:0] oss10;
wire oss10c;

BCDAddN #(.N(N+1)) ubcdan1
(
	.ci(1'b0),
	.a(oaa10),
	.b(obb10),
	.o(oss10),
	.co(oss10c)
);

wire [(N+1)*4-1:0] odd10;
wire odd10c;

BCDSubN #(.N(N+1)) ubcdsn1
(
	.ci(1'b0),
	.a(oaa10),
	.b(obb10),
	.o(odd10),
	.co(odd10c)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #1
// - decode the input operands
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg op1;

DFPDecomposeReg #(.N(N)) u1a (.clk(clk), .ce(ce), .i(a), .sgn(sa), .sx(sxa), .exp(xa), .sig(siga), .xz(adn), .vz(az), .inf(aInf), .nan(aNan) );
DFPDecomposeReg #(.N(N)) u1b (.clk(clk), .ce(ce), .i(b), .sgn(sb), .sx(sxb), .exp(xb), .sig(sigb), .xz(bdn), .vz(bz), .inf(bInf), .nan(bNan) );

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
reg [15:0] xa2, xb2;
reg az2, bz2;
reg xa_gt_xb2;
reg [N*4-1:0] siga2, sigb2;
reg sigeq, siga_gt_sigb;
reg xa_gt_xb2;
reg expeq;
reg sxo2;

always @(posedge clk)
  if (ce) realOp2 = op1 ^ sa ^ sb;
always @(posedge clk)
  if (ce) op2 <= op1;
always @(posedge clk)
  if (ce) xa2 <= xa;
always @(posedge clk)
  if (ce) xb2 <= xb;
always @(posedge clk)
  if (ce) siga2 <= siga;
always @(posedge clk)
  if (ce) sigb2 <= sigb;
always @(posedge clk)
  if (ce) az2 <= az;  
always @(posedge clk)
  if (ce) bz2 <= bz;  
always @(posedge clk)
  if (ce) 
  	if (sxa & ~sxb)
  		xa_gt_xb2 <= TRUE;
  	else if (~sxa & sxb)
  		xa_gt_xb2 <= FALSE;
  	else
  		xa_gt_xb2 <= sxa ? xa > xb : xa < xb;
always @(posedge clk)
  if (ce) 
  	sxo2 <= sxa|sxb;

always @(posedge clk)
  if (ce) sigeq <= siga==sigb;
always @(posedge clk)
  if (ce) siga_gt_sigb <= siga > sigb;
always @(posedge clk)
  if (ce) expeq <= {sxa,xa}=={sxb,xb};

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #3
//
// Find out if the result will be zero.
// Determine which fraction to denormalize
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
reg [15:0] xa3, xb3;
reg resZero3;
wire xaInf3, xbInf3;
reg xa_gt_xb3;
reg a_gt_b3;
reg op3;
wire sa3, sb3;
wire [2:0] rm3;
reg [N*4-1:0] mfs3;

always @(posedge clk)
  if (ce) resZero3 <= (realOp2 & expeq & sigeq) ||	// subtract, same magnitude
			   (az2 & bz2);		// both a,b zero
always @(posedge clk)
  if (ce) xa3 <= xa2;
always @(posedge clk)
  if (ce) xb3 <= xb2;
always @(posedge clk)
  if (ce) xa_gt_xb3 <= xa_gt_xb2;
always @(posedge clk)
  if (ce) a_gt_b3 <= xa_gt_xb2 | (expeq & siga_gt_sigb);
always @(posedge clk)
  if (ce) op3 <= op2;
always @(posedge clk)
  if (ce) mfs3 = xa_gt_xb2 ? sigb2 : siga2;

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

reg [15:0] xa4, xb4;
reg [15:0] xo4;
reg xa_gt_xb4;

always @(posedge clk)
  if (ce) xa4 <= xa3;
always @(posedge clk)
  if (ce) xb4 <= xb3;
always @(posedge clk)
	if (ce) xo4 <= resZero3 ? 16'd0 : xa_gt_xb3 ? xa3 : xb3;
always @(posedge clk)
  if (ce) xa_gt_xb4 <= xa_gt_xb3;

// Compute output sign
reg so4;
always @*
	case ({resZero3,sa3,op3,sb3})	// synopsys full_case parallel_case
	4'b0000: so4 <= 0;			// - + - = -
	4'b0001: so4 <= !a_gt_b3;	// - + + = sign of larger
	4'b0010: so4 <= !a_gt_b3;	// - - - = sign of larger
	4'b0011: so4 <= 0;			// - - + = -
	4'b0100: so4 <= a_gt_b3;		// + + - = sign of larger
	4'b0101: so4 <= 1;			// + + + = +
	4'b0110: so4 <= 1;			// + - - = +
	4'b0111: so4 <= a_gt_b3;		// + - + = sign of larger
	4'b1000: so4 <= 0;			//  -A +  -B, sign = -
	4'b1001: so4 <= (rm3==3'd3);		//  -A + B, sign = + unless rounding down
	4'b1010: so4 <= (rm3==3'd3);		//  -A - -B, sign = + unless rounding down
	4'b1011: so4 <= 0;			// -A - B, sign = -
	4'b1100: so4 <= (rm3==3'd3);		// A -  B, sign = + unless rounding down
	4'b1101: so4 <= 1;			// A + B, sign = +
	4'b1110: so4 <= 1;			// A - -B, sign = +
	4'b1111: so4 <= (rm3==3'd3);		// -A - -B, sign = + unless rounding down
	endcase

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #5
//
// Compute the difference in exponents, provides shift amount
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [15:0] xdiff5;
always @(posedge clk)
  if (ce) xdiff5 <= xabdif4;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #6
//
// Compute the difference in exponents, provides shift amount
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// If the difference in the exponent is 24 or greater (assuming 24 nybble dfp or
// less) then all of the bits will be shifted out to zero. There is no need to
// keep track of a difference more than 24.
reg [11:0] xdif6;
wire [N*4-1:0] mfs6;
always @(posedge clk)
  if (ce) xdif6 <= xdiff5 > N ? N : xdiff5[7:0];
delay #(.WID(N*4), .DEP(3)) udly6a (.clk(clk), .ce(ce), .i(mfs3), .o(mfs6));

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
wire [N*4-1:0] mfs7;
wire [7:0] xdif6a = {xdif6[7:4] * 10 + xdif6[3:0],2'b00};	// Convert base then *4
integer n;
always @* begin
	sticky6 = 1'b0;
	for (n = 0; n < N*4; n = n + 4)
		if (n <= xdif6a)
			sticky6 = sticky6| mfs6[n]|mfs6[n+1]|mfs6[n+2]|mfs6[n+3];	// non-zeero nybble
end

// register inputs to shifter and shift
delay1 #(1)  d16(.clk(clk), .ce(ce), .i(sticky6), .o(sticky7) );
delay1 #(8)  d15(.clk(clk), .ce(ce), .i(xdif6a),   .o(xdif7) );
delay1 #(N*4) d14(.clk(clk), .ce(ce), .i(mfs6),    .o(mfs7) );

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #8
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [(N+1)*4-1:0] md8;
wire [N*4-1:0] siga8, sigb8;
wire xa_gt_xb8;
wire a_gt_b8;
always @(posedge clk)
  if (ce) md8 <= ({mfs7,4'b0} >> xdif7)|sticky7;	// xdif7 is a multiple of four

// sync control signals
delay #(.WID(1), .DEP(4)) udly8a (.clk(clk), .ce(ce), .i(xa_gt_xb4), .o(xa_gt_xb8));
delay #(.WID(1), .DEP(5)) udly8b (.clk(clk), .ce(ce), .i(a_gt_b3), .o(a_gt_b8));
delay #(.WID(N*4), .DEP(6)) udly8d (.clk(clk), .ce(ce), .i(siga2), .o(siga8));
delay #(.WID(N*4), .DEP(6)) udly8e (.clk(clk), .ce(ce), .i(sigb2), .o(sigb8));
delay #(.WID(1), .DEP(5)) udly8j (.clk(clk), .ce(ce), .i(op3), .o(op8));

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #9
// Sort operands and perform add/subtract
// addition can generate an extra bit, subtract can't go negative
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [(N+1)*4-1:0] oa9, ob9;
reg a_gt_b9;
always @(posedge clk)
  if (ce) oa9 <= xa_gt_xb8 ? {siga8,4'b0} : md8;
always @(posedge clk)
  if (ce) ob9 <= xa_gt_xb8 ? md8 : {sigb8,4'b0};
always @(posedge clk)
  if (ce) a_gt_b9 <= a_gt_b8;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #10
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [(N+1)*4-1:0] oaa10;
reg [(N+1)*4-1:0] obb10;
wire realOp10;
reg [15:0] xo10;

always @(posedge clk)
  if (ce) oaa10 <= a_gt_b9 ? oa9 : ob9;
always @(posedge clk)
  if (ce) obb10 <= a_gt_b9 ? ob9 : oa9;
delay #(.WID(1), .DEP(8)) udly10a (.clk(clk), .ce(ce), .i(realOp2), .o(realOp10));
delay #(.WID(16), .DEP(6)) udly10b (.clk(clk), .ce(ce), .i(xo4), .o(xo10));

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #11
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [(N+1)*4-1:0] mab11;
reg mab11c;
wire [N*4-1:0] siga11, sigb11;
wire abInf11;
wire aNan11, bNan11;
reg xoinf11;
wire op11;

always @(posedge clk)
  if (ce) mab11 <= realOp10 ? odd10 : oss10;
always @(posedge clk)
	if (ce) mab11c <= realOp10 ? odd10c : oss10c;

delay #(.WID(1), .DEP(8)) udly11a (.clk(clk), .ce(ce), .i(aInf3&bInf3), .o(abInf11));
delay #(.WID(1), .DEP(10)) udly11c (.clk(clk), .ce(ce), .i(aNan), .o(aNan11));
delay #(.WID(1), .DEP(10)) udly11d (.clk(clk), .ce(ce), .i(bNan), .o(bNan11));
delay #(.WID(1), .DEP(3)) udly11e (.clk(clk), .ce(ce), .i(op8), .o(op11));
delay #(.WID(N*4), .DEP(3)) udly11f (.clk(clk), .ce(ce), .i(siga8), .o(siga11));
delay #(.WID(N*4), .DEP(3)) udly11g (.clk(clk), .ce(ce), .i(sigb8), .o(sigb11));

always @(posedge clk)
  if (ce) xoinf11 <= xo10==16'h9999;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #12
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [(N+1)*4*2-1:0] mo12;	// mantissa output
reg [3:0] st12;
wire sxo11;
wire so11;
delay #(.WID(1), .DEP(9)) udly12a (.clk(clk), .ce(ce), .i(sxo2), .o(sxo11));
delay #(.WID(1), .DEP(7)) udly12b (.clk(clk), .ce(ce), .i(so4), .o(so11));

always @(posedge clk)
if (ce) begin
	st12[0] <= sxo11;
	st12[1] <= abInf11;
	st12[2] <= so11;
	st12[3] <= aNan11|bNan11;
end

always @(posedge clk)
if (ce)
	casez({abInf11,aNan11,bNan11,xoinf11})
	4'b1???:	// inf +/- inf - generate QNaN on subtract, inf on add
		if (op11)
			mo12 <= {4'h9,{(N+1)*4*2-4{1'd0}}};
		else
			mo12 <= {(N+1)*2{4'h9}};
	4'b01??:	mo12 <= {4'b0,siga11[107:0],{(N+1)*4{1'd0}}};
	4'b001?: 	mo12 <= {4'b0,sigb11[107:0],{(N+1)*4{1'd0}}};
	4'b0001:	mo12 <= {(N+1)*4*2{1'd0}};
	default:	mo12 <= {3'b0,mab11c,mab11,{N*4{1'd0}}};	// mab has an extra lead bit and four trailing bits
	endcase

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #13
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
wire so;			// sign output
wire [3:0] st;
wire [15:0] xo;	// de normalized exponent output
wire [(N+1)*4*2-1:0] mo;	// mantissa output

delay #(.WID(4), .DEP(1)) u13c (.clk(clk), .ce(ce), .i(st12), .o(st[3:0]) );
delay #(.WID(1), .DEP(9)) udly13a (.clk(clk), .ce(ce), .i(so4), .o(so));
delay #(.WID(16), .DEP(3)) udly13b (.clk(clk), .ce(ce), .i(xo10), .o(xo));
delay #(.WID((N+1)*4*2), .DEP(1)) u13d (.clk(clk), .ce(ce), .i(mo12), .o(mo) );

assign o = {st,xo,mo};

endmodule


module DFPAddsubnr(clk, ce, rm, op, a, b, o);
parameter N=33;
input clk;		// system clock
input ce;		// core clock enable
input [2:0] rm;	// rounding mode
input op;		// operation 0 = add, 1 = subtract
input [N*4+16+4-1:0] a;	// operand a
input [N*4+16+4-1:0] b;	// operand b
output [N*4+16+4-1:0] o;	// output

wire [(N+1)*4*2+16+4-1:0] o1;
wire [N*4+16+4-1+4:0] fpn0;

DFPAddsub    u1 (clk, ce, rm, op, a, b, o1);
DFPNormalize u2(.clk(clk), .ce(ce), .under_i(1'b0), .i(o1), .o(fpn0) );
DFPRound  	u3(.clk(clk), .ce(ce), .rm(rm), .i(fpn0), .o(o) );

endmodule
