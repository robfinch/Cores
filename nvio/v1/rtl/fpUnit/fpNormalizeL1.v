`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpNormalize.v
//    - floating point normalization unit
//    - one cycle latency
//    - parameterized FPWIDth
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
//	This unit takes a floating point number in an intermediate
// format and normalizes it. No normalization occurs
// for NaN's or infinities. The unit has a two cycle latency.
//
// The mantissa is assumed to start with two whole bits on
// the left. The remaining bits are fractional.
//
// The FPWIDth of the incoming format is reduced via a generation
// of sticky bit in place of the low order fractional bits.
//
// On an underflowed input, the incoming exponent is assumed
// to be negative. A right shift is needed.
// ============================================================================

module fpNormalize(clk, ce, under, i, o);
parameter FPWID = 128;
`include "fpSize.sv"

input clk;
input ce;
input under;
input [EX:0] i;		// expanded format input
output [FPWID+2:0] o;		// normalized output + guard, sticky and round bits, + 1 whole digit

// variables
wire so;

wire so1 = i[EX];		// sign doesn't change

// Since the there are *three* whole digits in the incoming format
// the number of whole digits needs to be reduced. If the MSB is
// set, then increment the exponent and no shift is needed.
wire [EMSB:0] xo;
wire [EMSB:0] xo1a = i[EX-1:FX+1];
wire xInf = &xo1a & !under;
wire xInf3 = &xo1a[EMSB:1] & !under;
wire incExp2 = !xInf3 & i[FX];
wire incExp1 = !xInf & i[FX-1];
wire [EMSB:0] xo1 = xo1a + (incExp2 ? 2'd2 : incExp1 ? 2'd1 : 2'd0);
wire [EMSB:0] xo2;
wire xInf1 = &xo1;

// If infinity is reached then set the mantissa to zero
// shift mantissa left by one to reduce to a single whole digit
// if there is no exponent increment
wire [FMSB+4:0] mo;
wire [FMSB+4:0] mo1 = ((xInf1 & (incExp1|incExp2))|(xInf3 & incExp2)) ? 0 :
	incExp2 ? {i[FX:FMSB+1],|i[FMSB:0]} :
	incExp1 ? {i[FX-1:FMSB],|i[FMSB-1:0]} :	// reduce mantissa size
			 {i[FX-2:FMSB-1],|i[FMSB-2:0]};		// reduce mantissa size
wire [FMSB+4:0] mo2;
wire [7:0] leadingZeros2;

generate
begin
if (FPWID <= 32) begin
cntlz32Reg clz0 (.clk(clk), .ce(ce), .i({mo1,5'b0}), .o(leadingZeros2) );
assign leadingZeros2[7:6] = 2'b00;
end
else if (FPWID<=64) begin
assign leadingZeros2[7] = 1'b0;
cntlz64Reg clz0 (.clk(clk), .ce(ce), .i({mo1,8'h0}), .o(leadingZeros2) );
end
else if (FPWID<=80) begin
assign leadingZeros2[7] = 1'b0;
cntlz80Reg clz0 (.clk(clk), .ce(ce), .i({mo1,12'b0}), .o(leadingZeros2) );
end
else if (FPWID<=84) begin
assign leadingZeros2[7] = 1'b0;
cntlz96Reg clz0 (.clk(clk), .ce(ce), .i({mo1,24'b0}), .o(leadingZeros2) );
end
else if (FPWID<=96) begin
assign leadingZeros2[7] = 1'b0;
cntlz96Reg clz0 (.clk(clk), .ce(ce), .i({mo1,12'b0}), .o(leadingZeros2) );
end
else if (FPWID<=128)
cntlz128Reg clz0 (.clk(clk), .ce(ce), .i({mo1,12'b0}), .o(leadingZeros2) );
end
endgenerate

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
wire [7:0] lshiftAmt2 = leadingZeros2 > xo2 ? xo2 : leadingZeros2;

// compute amount to shift right
// at infinity the exponent can't be incremented, so we can't shift right
// otherwise it was an underflow situation so the exponent was negative
// shift amount needs to be negated for shift register
wire [7:0] rshiftAmt2 = xInf2 ? 0 : $signed(xo2) > 0 ? 0 : ~xo2+1;//FMSB+4+xo2;	// xo2 is negative !


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
delay1 #(FMSB+5) d4(.clk(clk), .ce(ce), .i(mo1), .o(mo2) );

wire [FMSB+3:0] mo2a;
//shiftAndMask #(FMSB+4) u1 (.op({rightOrLeft2,1'b0}), .a(mo2), .b(rightOrLeft2 ? lshiftAmt2 : rshiftAmt2), .mb(6'd0), .me(FMSB+3), .o(mo2a) );

//	always @(posedge clk)
//		if (ce)
assign mo = rightOrLeft2 ? (mo2 >> rshiftAmt2) : (mo2 << lshiftAmt2);
//always @(posedge clk)
//	$display("%c xo2=%d -xo2=%d rshift=%d >%d %d", rightOrLeft2 ? "r" : "l",xo2, -xo2, rshiftAmt2,($unsigned(-xo2) > $unsigned(FMSB+3)),FMSB+3);
assign o = {so,xo,mo[FMSB+4:1]};

endmodule
	
