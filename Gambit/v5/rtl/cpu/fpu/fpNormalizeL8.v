`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpNormalizeL8.v
//    - floating point normalization unit
//    - eight cycle latency
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


// ----------------------------------------------------------------------------
// No Clock required
// ----------------------------------------------------------------------------
reg [EMSB:0] xo1;
reg so1;

always @*
	xo1 <= i[EX-1:FX+1];
always @*
	so1 <= i[EX];		// sign doesn't change

// ----------------------------------------------------------------------------
// Clock #1
// - Capture exponent information
// ----------------------------------------------------------------------------

always @(posedge clk)
	if (ce) xInf1a <= &xo1 & !under;
always @(posedge clk)
	if (ce) xInf1b <= &xo1[EMSB:1] & !under;
always @(posedge clk)
	if (ce) xInf1c = &xo1;

// ----------------------------------------------------------------------------
// Clock #2
// - determine exponent increment
// Since the there are *three* whole digits in the incoming format
// the number of whole digits needs to be reduced. If the MSB is
// set, then increment the exponent and no shift is needed.
// ----------------------------------------------------------------------------
wire xInf2c;
wire [EMSB:0] xo2;
delay1 u21 (.clk(clk), .ce(ce), .i(xInf1c), .o(xInf2c));
delay1 u22 (.clk(clk), .ce(ce), .i(xInf1b), .o(xInf2b));
delay1 #(EMSB+1) u23 (.clk(clk), .ce(ce), .i(xo1), .o(xo2));

always @(posedge clk)
	if (ce) incExpByTwo2 <= !xInf1b & i1[FX];
always @(posedge clk)
	if (ce) incExpByOne2 <= !xInf1a & i[FX-1];

// ----------------------------------------------------------------------------
// Clock #3
// - increment exponent
// - detect a zero mantissa
// ----------------------------------------------------------------------------

wire incExpByTwo3;
wire incExpByOne3;
wire [FX:0] i3;
delay1 u31 (.clk(clk), .ce(ce), .i(incExpByTwo2), .o(incExpByTwo3));
delay1 u32 (.clk(clk), .ce(ce), .i(incExpByOne2), .o(incExpByOne3));
delay3 #(FX+1) u33 (.clk(clk), .ce(ce), .i(i[FX:0]), .o(i3));

always @(posedge clk)
	if (ce) xo3 <= xo2 + (incExpByTwo2 ? 2'd2 : incExpByOne2 ? 2'd1 : 2'd0);

always @(posedge clk)
	if(ce) zeroMan3 <= ((xInf2c & (incExpByOne2|incExpByTwo2))|(xInf2b & incExpByTwo2));

// ----------------------------------------------------------------------------
// Clock #4
// - Shift mantissa left
// - If infinity is reached then set the mantissa to zero
//   shift mantissa left to reduce to a single whole digit
// - create sticky bit
// ----------------------------------------------------------------------------

reg [FMSB+4:0] mo4;

always @(posedge clk)
if(ce)
case({zeroMan3,incExpByTwo3,incExpByOne3})
3'b1??:	mo4 <= 1'd0;
3'b01?:	mo4 <= {i3[FX:FMSB+1],|i3[FMSB:0]};
3'b001:	mo4 <= {i3[FX-1:FMSB],|i3[FMSB-1:0]};
default:	mo4 <= {i3[FX-2:FMSB-1],|i3[FMSB-2:0]};
endcase

// ----------------------------------------------------------------------------
// Clock edge #5
// - count leading zeros
// ----------------------------------------------------------------------------
wire [7:0] leadingZeros5;
wire [EMSB:0] xo5;
wire xInf5;
delay3 #(EMSB+1) u51 (.clk(clk), .ce(ce), .i(xo2), .i(xo5));
delay3 #(1)      u52 (.clk(clk), .ce(ce), .i(xInf2c), .o(xInf5) );

generate
begin
if (FPWID <= 32) begin
cntlz32Reg clz0 (.clk(clk), .ce(ce), .i({mo4,5'b0}), .o(leadingZeros5) );
assign leadingZeros5[7:6] = 2'b00;
end
else if (FPWID<=64) begin
assign leadingZeros5[7] = 1'b0;
cntlz64Reg clz0 (.clk(clk), .ce(ce), .i({mo4,8'h0}), .o(leadingZeros5) );
end
else if (FPWID<=80) begin
assign leadingZeros5[7] = 1'b0;
cntlz80Reg clz0 (.clk(clk), .ce(ce), .i({mo4,12'b0}), .o(leadingZeros5) );
end
else if (FPWID<=84) begin
assign leadingZeros5[7] = 1'b0;
cntlz96Reg clz0 (.clk(clk), .ce(ce), .i({mo4,24'b0}), .o(leadingZeros5) );
end
else if (FPWID<=96) begin
assign leadingZeros5[7] = 1'b0;
cntlz96Reg clz0 (.clk(clk), .ce(ce), .i({mo4,12'b0}), .o(leadingZeros5) );
end
else if (FPWID<=128)
cntlz128Reg clz0 (.clk(clk), .ce(ce), .i({mo4,12'b0}), .o(leadingZeros5) );
end
endgenerate


// ----------------------------------------------------------------------------
// Clock edge #6
// - Compute how much we want to decrement exponent by
// - compute amount to shift left and right
// - at infinity the exponent can't be incremented, so we can't shift right
//   otherwise it was an underflow situation so the exponent was negative
//   shift amount needs to be negated for shift register
// If the exponent underflowed, then the shift direction must be to the
// right regardless of mantissa bits; the number is denormalized.
// Otherwise the shift direction must be to the left.
// ----------------------------------------------------------------------------
reg [7:0] lshiftAmt6;
reg [7:0] rshiftAmt6;
wire rightOrLeft6;	// 0=left,1=right
vtdl #(1) u61 (.clk(clk), .ce(ce), .a(4'd5), .d(under), .q(rightOrLeft6) );
delay1 #(EMSB+1) u62 (.clk(clk), .ce(ce), .i(xo5), .i(xo6));
delay2 #(FMSB+5) u63 (.clk(clk), .ce(ce), .i(mo4), .o(mo6) );

always @(posedge clk)
	if (ce) lshiftAmt6 <= leadingZeros5 > xo5 ? xo5 : leadingZeros5;

always @(posedge clk)
	if (ce) rshiftAmt6 <= xInf5 ? 0 : $signed(xo5) > 1'd0 ? 1'd0 : ~xo5+2'd1;	// xo2 is negative !

// ----------------------------------------------------------------------------
// Clock edge #7
// - fogure exponent
// - shift mantissa
// ----------------------------------------------------------------------------

reg [EMSB:0] xo7;
wire rightOrLeft7;
reg [FMSB+4] mo7l, mo7r;
delay1 #(EMSB+1) u71 (.clk(clk), .ce(ce), .i(rightOrLeft6), .i(rightOrLeft7));

always @(posedge clk)
if (ce)
	xo7 <= 
		xInf6 ? xo6 :					// an infinite exponent is either a NaN or infinity; no need to change
		rightOrLeft6 ? 1'd0 :	// on a right shift, the exponent was negative, it's being made to zero
		xo6 - lshiftAmt6;			// on a left shift, the exponent can't be decremented below zero

always @(posedge clk)
	if (ce) mo7r <= mo6 >> rshiftAmt6;
always @(posedge clk)
	if (ce) mo7l <= mo6 << lshiftAmt6;


// ----------------------------------------------------------------------------
// Clock edge #8
// - select mantissa
// ----------------------------------------------------------------------------

wire so;
wire [EMSB:0] xo;
vtdl #(1) u81 (.clk(clk), .ce(ce), .a(4'd6), .d(so1), .q(so) );
delay1 #(EMSB+1) u82 (.clk(clk), .ce(ce), .i(xo7), .i(xo));

always @(posedge clk)
	if (ce) mo <= rightOrLeft7 ? mo7r : mo7l;

assign o = {so,xo,mo[FMSB+4:1]};

endmodule
	
