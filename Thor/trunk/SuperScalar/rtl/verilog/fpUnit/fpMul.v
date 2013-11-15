// ===============================================================
//	(C) 2006  Robert Finch
//	All rights reserved.
//	rob@birdcomputer.ca
//
//	fpMul.v
//		- floating point multiplier
//		- two cycle latency
//		- can issue every clock cycle
//		- parameterized width
//		- IEEE 754 representation
//
//	This source code is free for use and modification for
//	non-commercial or evaluation purposes, provided this
//	copyright statement and disclaimer remains present in
//	the file.
//
//	If the code is modified, please state the origin and
//	note that the code has been modified.
//
//	NO WARRANTY.
//	THIS Work, IS PROVIDEDED "AS IS" WITH NO WARRANTIES OF
//	ANY KIND, WHETHER EXPRESS OR IMPLIED. The user must assume
//	the entire risk of using the Work.
//
//	IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
//	ANY INCIDENTAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES
//	WHATSOEVER RELATING TO THE USE OF THIS WORK, OR YOUR
//	RELATIONSHIP WITH THE AUTHOR.
//
//	IN ADDITION, IN NO EVENT DOES THE AUTHOR AUTHORIZE YOU
//	TO USE THE WORK IN APPLICATIONS OR SYSTEMS WHERE THE
//	WORK'S FAILURE TO PERFORM CAN REASONABLY BE EXPECTED
//	TO RESULT IN A SIGNIFICANT PHYSICAL INJURY, OR IN LOSS
//	OF LIFE. ANY SUCH USE BY YOU IS ENTIRELY AT YOUR OWN RISK,
//	AND YOU AGREE TO HOLD THE AUTHOR AND CONTRIBUTORS HARMLESS
//	FROM ANY CLAIMS OR LOSSES RELATING TO SUCH UNAUTHORIZED
//	USE.
//
//	This multiplier/divider handles denormalized numbers.
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
//	1 sign number
//	8 exponent
//	48 mantissa
//
//	Ref: Webpack8.1i Spartan3-4 xc3s1000-4ft256
//	174 LUTS / 113 slices / 24.7 ns
//	4 Mults
//=============================================================== */

module fpMul (clk, ce, a, b, o, sign_exe, inf, overflow, underflow);
parameter WID = 32;
localparam MSB = WID-1;
localparam EMSB = WID==80 ? 14 :
                  WID==64 ? 10 :
				  WID==52 ? 10 :
				  WID==48 ? 10 :
				  WID==44 ? 10 :
				  WID==42 ? 10 :
				  WID==40 ?  9 :
				  WID==32 ?  7 :
				  WID==24 ?  6 : 4;
localparam FMSB = WID==80 ? 63 :
                  WID==64 ? 51 :
				  WID==52 ? 39 :
				  WID==48 ? 35 :
				  WID==44 ? 31 :
				  WID==42 ? 29 :
				  WID==40 ? 28 :
				  WID==32 ? 22 :
				  WID==24 ? 15 : 9;

localparam FX = (FMSB+2)*2-1;	// the MSB of the expanded fraction
localparam EX = FX + 1 + EMSB + 1 + 1 - 1;

input clk;
input ce;
input  [WID:1] a, b;
output [EX:0] o;
output sign_exe;
output inf;
output overflow;
output underflow;

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
wire az, bz;
wire aInf, bInf, aInf1, bInf1;


// -----------------------------------------------------------
// First clock
// - decode the input operands
// - derive basic information
// - calculate exponent
// - calculate fraction
// -----------------------------------------------------------

fpDecomp #(WID) u1a (.i(a), .sgn(sa), .exp(xa), .fract(fracta), .xz(a_dn), .vz(az), .inf(aInf) );
fpDecomp #(WID) u1b (.i(b), .sgn(sb), .exp(xb), .fract(fractb), .xz(b_dn), .vz(bz), .inf(bInf) );

// Compute the sum of the exponents.
// correct the exponent for denormalized operands
// adjust the sum by the exponent offset (subtract 127)
// mul: ex1 = xa + xb,	result should always be < 1ffh
assign ex1 = (az|bz) ? 0 : (xa|a_dn) + (xb|b_dn) - bias;
generate
if (WID==64) begin
	reg [35:0] p00,p01,p02;
	reg [35:0] p10,p11,p12;
	reg [35:0] p20,p21,p22;
	always @(posedge clk)
	if (ce) begin
		p00 <= fracta[17: 0] * fractb[17: 0];
		p01 <= fracta[35:18] * fractb[17: 0];
		p02 <= fracta[52:36] * fractb[17: 0];
		p10 <= fracta[17: 0] * fractb[35:18];
		p11 <= fracta[35:18] * fractb[35:18];
		p12 <= fracta[52:36] * fractb[35:18];
		p20 <= fracta[17: 0] * fractb[52:36];
		p21 <= fracta[35:18] * fractb[52:36];
		p22 <= fracta[52:36] * fractb[52:36];
		fract1 <= 	                            {p02,36'b0} + {p01,18'b0} + p00 +
								  {p12,54'b0} + {p11,36'b0} + {p10,18'b0} +
					{p22,72'b0} + {p21,54'b0} + {p20,36'b0}
				;
	end
end
else if (WID==32) begin
	reg [35:0] p00,p01;
	reg [35:0] p10,p11;
	always @(posedge clk)
	if (ce) begin
		p00 <= fracta[17: 0] * fractb[17: 0];
		p01 <= fracta[23:18] * fractb[17: 0];
		p10 <= fracta[17: 0] * fractb[23:18];
		p11 <= fracta[23:18] * fractb[23:18];
		fract1 <= {p11,p00} + {p01,18'b0} + {p10,18'b0};
	end
end
endgenerate

// Status
wire under1, over1;
wire under = ex1[EMSB+2];	// exponent underflow
wire over = (&ex1[EMSB:0] | ex1[EMSB+1]) & !ex1[EMSB+2];

delay2 #(EMSB) u3 (.clk(clk), .ce(ce), .i(ex1[EMSB:0]), .o(ex2) );
delay2 #(FX+1) u4 (.clk(clk), .ce(ce), .i(fract1), .o(fracto) );
delay2 u2a (.clk(clk), .ce(ce), .i(aInf), .o(aInf1) );
delay2 u2b (.clk(clk), .ce(ce), .i(bInf), .o(bInf1) );
delay2 u6  (.clk(clk), .ce(ce), .i(under), .o(under1) );
delay2 u7  (.clk(clk), .ce(ce), .i(over), .o(over1) );

// determine when a NaN is output
wire qNaNOut;
delay2 u5 (.clk(clk), .ce(ce), .i((aInf&bz)|(bInf&az)), .o(qNaNOut) );


// -----------------------------------------------------------
// Second clock
// - correct xponent and mantissa for exceptional conditions
// -----------------------------------------------------------

wire so1;
delay3 u8 (.clk(clk), .ce(ce), .i(sa ^ sb), .o(so1) );// two clock delay!

always @(posedge clk)
	if (ce)
		casex({qNaNOut,aInf1,bInf1,over1,under1})
		5'b1xxxx:	xo1 = infXp;	// qNaN - infinity * zero
		5'b01xxx:	xo1 = infXp;	// 'a' infinite
		5'b001xx:	xo1 = infXp;	// 'b' infinite
		5'b0001x:	xo1 = infXp;	// result overflow
		5'b00001:	xo1 = 0;		// underflow
		default:	xo1 = ex2[EMSB:0];	// situation normal
		endcase

always @(posedge clk)
	if (ce)
		casex({qNaNOut,aInf1,bInf1,over1})
		4'b1xxx:	mo1 = {1'b0,qNaN|3'd4,{FMSB+1{1'b0}}};	// multiply inf * zero
		4'b01xx:	mo1 = 0;	// mul inf's
		4'b001x:	mo1 = 0;	// mul inf's
		4'b0001:	mo1 = 0;	// mul overflow
		default:	mo1 = fracto;
		endcase

delay3 u10 (.clk(clk), .ce(ce), .i(sa & sb), .o(sign_exe) );
delay1 u11 (.clk(clk), .ce(ce), .i(over1),  .o(overflow) );
delay1 u12 (.clk(clk), .ce(ce), .i(over1),  .o(inf) );
delay1 u13 (.clk(clk), .ce(ce), .i(under1), .o(underflow) );

assign o = {so1,xo1,mo1};

endmodule

module fpMul_tb();
reg clk;

initial begin
	clk = 0;
end
always #10 clk <= ~clk;

fpMul u1 (.clk(clk), .ce(1'b1), .a(0), .b(0), .o(o1), .sign_exe(sgnx1), .inf(inf1), .overflow(of1), .underflow(uf1));
fpMul u2 (.clk(clk), .ce(1'b1), .a(0), .b(0), .o(o1), .sign_exe(sgnx1), .inf(inf1), .overflow(of1), .underflow(uf1));

endmodule
