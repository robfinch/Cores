/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca

	fpNormalize.v
		- floating point normalization unit
		- two cycle latency
		- parameterized width
		- IEEE 754 representation

	This source code is free for use and modification for
	non-commercial or evaluation purposes, provided this
	copyright statement and disclaimer remains present in
	the file.

	If you do modify the code, please state the origin and
	note that you have modified the code.

	NO WARRANTY.
	THIS Work, IS PROVIDEDED "AS IS" WITH NO WARRANTIES OF
	ANY KIND, WHETHER EXPRESS OR IMPLIED. The user must assume
	the entire risk of using the Work.

	IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
	ANY INCIDENTAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES
	WHATSOEVER RELATING TO THE USE OF THIS WORK, OR YOUR
	RELATIONSHIP WITH THE AUTHOR.

	IN ADDITION, IN NO EVENT DOES THE AUTHOR AUTHORIZE YOU
	TO USE THE WORK IN APPLICATIONS OR SYSTEMS WHERE THE
	WORK'S FAILURE TO PERFORM CAN REASONABLY BE EXPECTED
	TO RESULT IN A SIGNIFICANT PHYSICAL INJURY, OR IN LOSS
	OF LIFE. ANY SUCH USE BY YOU IS ENTIRELY AT YOUR OWN RISK,
	AND YOU AGREE TO HOLD THE AUTHOR AND CONTRIBUTORS HARMLESS
	FROM ANY CLAIMS OR LOSSES RELATING TO SUCH UNAUTHORIZED
	USE.


	This unit takes a floating point number in an intermediate
	format and normalizes it. No normalization occurs
	for NaN's or infinities. The unit has a two cycle latency.

	The mantissa is assumed to start with two whole bits on
	the left. The remaining bits are fractional.
	
	The width of the incoming format is reduced via a generation
	of sticky bit in place of the low order fractional bits.

	On an underflowed input, the incoming exponent is assumed
	to be negative. A right shift is needed.

	Ref: Webpack 8.2  Spartan3-4 xc3s1000-4ft256
	302 LUTs / 166 slices / 
	550 LUTs / 291 slices / 89 MHz
	163 LUTs / 93 slices / 113.6 MHz?
=============================================================== */

module fpNormalize(clk, ce, under, i, o);
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
input under;
input [EX:0] i;		// expanded format input
output [WID+2:0] o;		// normalized output + guard, sticky and round bits, + 1 whole digit

// variables
wire so;

wire so1 = i[EX];		// sign doesn't change

// Since the there are *two* whole digits in the incoming format
// the number of whole digits needs to be reduced. If the MSB is
// set, then increment the exponent and no shift is needed.
wire [EMSB:0] xo;
wire [EMSB:0] xo1a = i[EX-1:FX+1];
wire xInf = &xo1a & !under;
wire incExp1 = !xInf & i[FX];
wire [EMSB:0] xo1 = xo1a + incExp1;
wire [EMSB:0] xo2;
wire xInf1 = &xo1;

// If infinity is reached then set the mantissa to zero
wire gbit =  i[FMSB];
wire rbit =  i[FMSB-1];
wire sbit = |i[FMSB-2:0];
// shift mantissa left by one to reduce to a single whole digit
// if there is no exponent increment
wire [FMSB+3:0] mo;
wire [FMSB+3:0] mo1 = xInf1 & incExp1 ? 0 :
	incExp1 ? {i[FX:FMSB+1],gbit,rbit,sbit} :		// reduce mantissa size
			 {i[FX-1:FMSB+1],gbit,rbit,sbit,1'b0};	// reduce mantissa size
wire [FMSB+3:0] mo2;
wire [6:0] leadingZeros2;


cntlz64Reg clz0 (.clk(clk), .ce(ce), .i(mo1), .o(leadingZeros2) );

// compensate for leadingZeros delay
wire xInf2;
delay1 #(EMSB+1) d2(.clk(clk), .ce(ce), .i(xo1), .o(xo2) );
delay1 #(1)      d3(.clk(clk), .ce(ce), .i(xInf1), .o(xInf2) );

// If the exponent underflowed, then the shift direction must be to the
// right regardless of mantissa bits; the number is denormalized.
// Otherwise the shift direction must be to the left.
wire rightOrLeft2;	// 0=left,1=right
delay1 #(1) d8(.clk(clk), .ce(ce), .i(under), .o(rightOrLeft2) );

// Compute how much we want to decrement by
wire [6:0] lshiftAmt2 = leadingZeros2 > xo2 ? xo2 : leadingZeros2;

// compute amount to shift right
// at infinity the exponent can't be incremented, so we can't shift right
// otherwise it was an underflow situation so the exponent was negative
// shift amount needs to be negated for shift register
wire [6:0] rshiftAmt2 = xInf2 ? 0 : -xo2 > FMSB+3 ? FMSB+4 : FMSB+4+xo2;	// xo2 is negative !


// sign
// the output sign is the same as the input sign
delay1 #(1)      d7(.clk(clk), .ce(ce), .i(so1), .o(so) );

// exponent
//	always @(posedge clk)
//		if (ce)
assign xo =
		xInf2 ? xo2 :		// an infinite exponent is either a NaN or infinity; no need to change
		rightOrLeft2 ? 0 :	// on a right shift, the exponent was negative, it's being made to zero
		xo2 - lshiftAmt2;	// on a left shift, the exponent can't be decremented below zero

// mantissa
delay1 #(FMSB+3) d4(.clk(clk), .ce(ce), .i(mo1), .o(mo2) );

wire [FMSB+3:0] mo2a;
shiftAndMask #(FMSB+4) u1 (.op({rightOrLeft2,1'b0}), .a(mo2), .b(rightOrLeft2 ? lshiftAmt2 : rshiftAmt2), .mb(6'd0), .me(FMSB+3), .o(mo2a) );

//	always @(posedge clk)
//		if (ce)
assign mo = mo2a;//rightOrLeft2 ? mo2 >> rshiftAmt2 : mo2 << lshiftAmt2;

assign o = {so,xo,mo};

endmodule
	
