// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPNormalize128.sv
//    - decimal floating point normalization unit
//    - eight cycle latency
//    - parameterized width
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
// The width of the incoming format is reduced via a generation
// of sticky bit in place of the low order fractional bits.
//
// On an underflowed input, the incoming exponent is assumed
// to be negative. A right shift is needed.
// ============================================================================

import DFPPkg::*;

module DFPNormalize128(clk, ce, i, o, under_i, under_o, inexact_o);
parameter N=34;
input clk;
input ce;
input DFP128UD i;		// expanded format input
output DFP128UN o;	// normalized output + guard, sticky and round bits, + 1 whole digit
input under_i;
output under_o;
output inexact_o;

integer n;
// ----------------------------------------------------------------------------
// No Clock required
// ----------------------------------------------------------------------------
reg [13:0] xo0;
reg so0;
reg sx0;
reg nan0, qnan0, snan0;
reg inf0;

always_comb
	xo0 <= i.exp;
always_comb
	so0 <= i.sign;		// sign doesn't change
always_comb
	nan0 <= i.nan;
always_comb
	qnan0 <= i.qnan;
always_comb
	snan0 <= i.snan;
always_comb
	inf0 <= i.infinity;

// ----------------------------------------------------------------------------
// Clock #1
// - Capture exponent information
// ----------------------------------------------------------------------------
reg xInf1a, xInf1b, xInf1c;
DFP128UD i1;
always_ff @(posedge clk)
	if (ce)
		i1 <= i;

always_ff @(posedge clk)
	if (ce) xInf1a <= xo0==14'h2FFF & !under_i;
always_ff @(posedge clk)
	if (ce) xInf1b <= xo0==14'h2FFE & !under_i;
always_ff @(posedge clk)
	if (ce) xInf1c <= xo0==14'h2FFF;

// ----------------------------------------------------------------------------
// Clock #2
// - determine exponent increment
// Since the there are *three* whole digits in the incoming format
// the number of whole digits needs to be reduced. If the MSB is
// set, then increment the exponent and no shift is needed.
// ----------------------------------------------------------------------------
wire xInf2c, xInf2b;
wire [13:0] xo2;
reg incExpByOne2;
ft_delay #(.WID(1),.DEP(1)) u21 (.clk(clk), .ce(ce), .i(xInf1c), .o(xInf2c));
ft_delay #(.WID(1),.DEP(1)) u22 (.clk(clk), .ce(ce), .i(xInf1b), .o(xInf2b));
ft_delay #(.WID(14),.DEP(2)) u23 (.clk(clk), .ce(ce), .i(xo0), .o(xo2));
ft_delay #(.WID(1),.DEP(2)) u24 (.clk(clk), .ce(ce), .i(under_i), .o(under2));

always_ff @(posedge clk)
	if (ce) incExpByOne2 <= !xInf1a & |i1.sig[279:276];

// ----------------------------------------------------------------------------
// Clock #3
// - increment exponent
// - detect a zero mantissa
// ----------------------------------------------------------------------------

wire incExpByOne3;
DFP128UD i3;
reg [13:0] xo3;
reg zeroMan3;
ft_delay #(.WID(1),.DEP(1)) u32 (.clk(clk), .ce(ce), .i(incExpByOne2), .o(incExpByOne3));
ft_delay #(.WID($bits(i3)),.DEP(3)) u33 (.clk(clk), .ce(ce), .i(i), .o(i3));

wire [13:0] xo2a = xo2 + 1'd1;

always_ff @(posedge clk)
	if (ce) xo3 <= (incExpByOne2 ? xo2a : xo2);

always_ff @(posedge clk)
	if(ce) zeroMan3 <= 1'b0;

// ----------------------------------------------------------------------------
// Clock #4
// - Shift mantissa left
// - If infinity is reached then set the mantissa to zero
//   shift mantissa left to reduce to a single whole digit
// - create sticky bit
// ----------------------------------------------------------------------------

reg [(N+2)*4-1:0] mo4;
reg inexact4;

always_ff @(posedge clk)
if(ce)
casez({zeroMan3,incExpByOne3})
2'b1?:	mo4 <= 1'd0;
2'b01:	mo4 <= {i3[(N+1)*4*2-1:(N+1)*4],3'b0,|i3[(N+1)*4-1:0]};
default:	mo4 <= {i3[(N+1)*4*2-1-4:N*4],3'b0,|i3[N*4-1:0]};
endcase

always_ff @(posedge clk)
if(ce)
casez({zeroMan3,incExpByOne3})
2'b1?:	inexact4 <= 1'd0;
2'b01:	inexact4 <= |i3[(N+1)*4-1:0];
default:	inexact4 <= |i3[N*4-1:0];
endcase

// ----------------------------------------------------------------------------
// Clock edge #5
// - count leading zeros
// ----------------------------------------------------------------------------
reg [7:0] leadingZeros5;
wire [13:0] xo5;
wire xInf5;
ft_delay #(.WID(14),.DEP(2)) u51 (.clk(clk), .ce(ce), .i(xo3), .o(xo5));
ft_delay #(.WID(1),.DEP(3)) u52 (.clk(clk), .ce(ce), .i(xInf2c), .o(xInf5) );

/* Lookup table based leading zero count modules give slightly better
   performance but cases must be coded.
generate
begin
if (FPWID <= 32) begin
cntlz32Reg clz0 (.clk(clk), .ce(ce), .i({mo4,4'b0}), .o(leadingZeros5) );
assign leadingZeros5[7:6] = 2'b00;
end
else if (FPWID<=64) begin
assign leadingZeros5[7] = 1'b0;
cntlz64Reg clz0 (.clk(clk), .ce(ce), .i({mo4,7'h0}), .o(leadingZeros5) );
end
else if (FPWID<=80) begin
assign leadingZeros5[7] = 1'b0;
cntlz80Reg clz0 (.clk(clk), .ce(ce), .i({mo4,11'b0}), .o(leadingZeros5) );
end
else if (FPWID<=84) begin
assign leadingZeros5[7] = 1'b0;
cntlz96Reg clz0 (.clk(clk), .ce(ce), .i({mo4,23'b0}), .o(leadingZeros5) );
end
else if (FPWID<=96) begin
assign leadingZeros5[7] = 1'b0;
cntlz96Reg clz0 (.clk(clk), .ce(ce), .i({mo4,11'b0}), .o(leadingZeros5) );
end
else if (FPWID<=128)
cntlz128Reg clz0 (.clk(clk), .ce(ce), .i({mo4,11'b0}), .o(leadingZeros5) );
end
endgenerate
*/

// Sideways add.
// Normally there would be only one to two leading zeros. It is tempting then
// to check for only one or two. But, denormalized numbers might have more
// leading zeros. If denormals were not supported this could be made smaller
// and faster.
`ifdef SUPPORT_DENORMALS
reg [7:0] lzc;
reg got_one;
always @*
begin
  got_one = 1'b0;
  lzc = 8'h00;
  for (n = (N+2)*4-1; n >= 0; n = n - 4) begin
    if (!got_one) begin
      if (mo4[n]|mo4[n-1]|mo4[n-2]|mo4[n-3])
        got_one = 1'b1;
      else
        lzc = lzc + 1'b1;
    end
  end
end      
always_ff @(posedge clk)
  if (ce) leadingZeros5 <= lzc;
`else
wire [7:0] lead2 = mo4[(N+2)*4-1:N*4];
always_ff @(posedge clk)
if (ce)
casez(lead2)
8'b00000000:	leadingZeros5 <= 8'd2;
8'b0000????:	leadingZeros5 <= 8'd1;
default:			leadingZeros5 <= 8'd0;
endcase
`endif


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
wire xInf6;
wire [13:0] xo6;
wire [(N+2)*4-1:0] mo6;
wire zeroMan6;
vtdl #(1) u61 (.clk(clk), .ce(ce), .a(4'd5), .d(under_i), .q(rightOrLeft6) );
ft_delay #(.WID(14),.DEP(1)) u62 (.clk(clk), .ce(ce), .i(xo5), .o(xo6));
ft_delay #(.WID((N+2)*4),.DEP(2)) u63 (.clk(clk), .ce(ce), .i(mo4), .o(mo6) );
ft_delay #(.WID(1),.DEP(1)) u64 (.clk(clk), .ce(ce), .i(xInf5), .o(xInf6) );
ft_delay #(.WID(1),.DEP(3)) u65 (.clk(clk), .ce(ce),  .i(zeroMan3), .o(zeroMan6));
ft_delay #(.WID(1),.DEP(5)) u66 (.clk(clk), .ce(ce), .i(sx0), .o(sx5) );

always_ff @(posedge clk)
	if (ce) lshiftAmt6 <= {leadingZeros5 > xo5 ? xo5 : leadingZeros5,2'b0};

always_ff @(posedge clk)
	if (ce) rshiftAmt6 <= {xInf5 ? 1'd0 : $signed(xo5) > 14'd0 ? 8'd0 : ~xo5+2'd1,2'b00};	// xo2 is negative !

// ----------------------------------------------------------------------------
// Clock edge #7
// - figure exponent
// - shift mantissa
// - figure sticky bit
// ----------------------------------------------------------------------------

reg [15:0] xo7;
wire rightOrLeft7;
reg [(N+2)*4-1:0] mo7l, mo7r;
reg St6,St7;
ft_delay #(.WID(1),.DEP(1)) u71 (.clk(clk), .ce(ce), .i(rightOrLeft6), .o(rightOrLeft7));

wire [13:0] xo7d = xo6 - lshiftAmt6;

always_ff @(posedge clk)
if (ce)
	xo7 <= zeroMan6 ? xo6 :
		xInf6 ? xo6 :					// an infinite exponent is either a NaN or infinity; no need to change
		rightOrLeft6 ? 1'd0 :	// on a right shift, the exponent was negative, it's being made to zero
		xo7d;			// on a left shift, the exponent can't be decremented below zero

always_ff @(posedge clk)
	if (ce) mo7r <= mo6 >> rshiftAmt6;
always_ff @(posedge clk)
	if (ce) mo7l <= mo6 << lshiftAmt6;

// The sticky bit is set if the bits shifted out on a right shift are set.
always @*
begin
  St6 = 1'b0;
  for (n = 0; n < (N+2)*4; n = n + 1)
    if (n <= rshiftAmt6 + 1) St6 = St6|mo6[n];
end
always_ff @(posedge clk)
  if (ce) St7 <= St6;

// ----------------------------------------------------------------------------
// Clock edge #8
// - select mantissa
// ----------------------------------------------------------------------------

wire so,sxo,nano,info,qnano,snano;
wire [13:0] xo;
reg [(N+2)*4-1:0] mo;
vtdl #(1) u81 (.clk(clk), .ce(ce), .a(4'd7), .d(so0), .q(so) );
ft_delay #(.WID(14),.DEP(1)) u82 (.clk(clk), .ce(ce), .i(xo7), .o(xo));
vtdl #(.WID(1)) u83 (.clk(clk), .ce(ce), .a(4'd3), .d(inexact4), .q(inexact_o));
ft_delay #(.WID(1),.DEP(1)) u84 (.clk(clk), .ce(ce), .i(rightOrLeft7), .o(under_o));
vtdl #(1) u86 (.clk(clk), .ce(ce), .a(4'd7), .d(nan0), .q(nano) );
vtdl #(1) u87 (.clk(clk), .ce(ce), .a(4'd7), .d(qnan0), .q(qnano) );
vtdl #(1) u88 (.clk(clk), .ce(ce), .a(4'd7), .d(snan0), .q(snano) );
vtdl #(1) u89 (.clk(clk), .ce(ce), .a(4'd7), .d(inf0), .q(info) );

always_ff @(posedge clk)
	if (ce) mo <= rightOrLeft7 ? mo7r|{St7,4'b0} : mo7l;

assign o.nan = nano;
assign o.qnan = qnano;
assign o.snan = snano;
assign o.infinity = info;
assign o.sign = so;
assign o.exp = xo;
assign o.sig = mo[(N+2)*4-1:4];

endmodule
	
