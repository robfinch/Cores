`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	dfpAddsub.v
//    - floating point adder/subtracter
//    - two cycle latency
//    - can issue every clock cycle
//    - parameterized width
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
// ============================================================================

module dfpAddsub(clk, ce, rm, op, a, b, o);
parameter WID = 128;
localparam MSB = WID-1;
localparam EMSB = WID==128 ? 14 :
                  WID==96 ? 14 :
                  WID==80 ? 14 :
                  WID==64 ? 10 :
				  WID==52 ? 10 :
				  WID==48 ? 10 :
				  WID==44 ? 10 :
				  WID==42 ? 10 :
				  WID==40 ?  9 :
				  WID==32 ?  7 :
				  WID==24 ?  6 : 4;
localparam FMSB = WID==128 ? 111 :
                  WID==96 ? 79 :
                  WID==80 ? 63 :
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

input clk;		// system clock
input ce;		// core clock enable
input [2:0] rm;	// rounding mode
input op;		// operation 0 = add, 1 = subtract
input [WID-1:0] a;	// operand a
input [WID-1:0] b;	// operand b
output [EX:0] o;	// output


// variables
wire so;			// sign output
wire [EMSB:0] xo;	// de normalized exponent output
reg [EMSB:0] xo1;	// de normalized exponent output
wire [FX:0] mo;	// mantissa output
reg [FX:0] mo1;	// mantissa output

assign o = {so,xo,mo};

// operands sign,exponent,mantissa
wire sa, sb;
wire [EMSB:0] xa, xb;
wire [FMSB:0] ma, mb;
wire [FMSB+1:0] fracta, fractb;
wire [FMSB+1:0] fracta1, fractb1;

// which has greater magnitude ? Used for sign calc
wire xa_gt_xb = xa > xb;
wire xa_gt_xb1;
wire a_gt_b = xa_gt_xb || (xa==xb && ma > mb);
wire a_gt_b1;
wire az, bz;	// operand a,b is zero

wire adn, bdn;		// a,b denormalized ?
wire xaInf, xbInf;
wire aInf, bInf, aInf1, bInf1;
wire aNan, bNan, aNan1, bNan1;

wire [EMSB:0] xad = xa|adn;	// operand a exponent, compensated for denormalized numbers
wire [EMSB:0] xbd = xb|bdn; // operand b exponent, compensated for denormalized numbers

fpDecomp #(WID) u1a (.i(a), .sgn(sa), .exp(xa), .man(ma), .fract(fracta), .xz(adn), .vz(az), .xinf(xaInf), .inf(aInf), .nan(aNan) );
fpDecomp #(WID) u1b (.i(b), .sgn(sb), .exp(xb), .man(mb), .fract(fractb), .xz(bdn), .vz(bz), .xinf(xbInf), .inf(bInf), .nan(bNan) );

// Figure out which operation is really needed an add or
// subtract ?
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
wire realOp = op ^ sa ^ sb;
wire realOp1;
wire op1;

// Find out if the result will be zero.
wire resZero = (realOp && xa==xb && ma==mb) ||	// subtract, same magnitude
			   (az & bz);		// both a,b zero

// Compute output exponent
//
// The output exponent is the larger of the two exponents,
// unless a subtract operation is in progress and the two
// numbers are equal, in which case the exponent should be
// zero.

always @(xaInf,xbInf,resZero,xa,xb,xa_gt_xb)
	xo1 = (xaInf&xbInf) ? xa : resZero ? 0 : xa_gt_xb ? xa : xb;

// Compute output sign
reg so1;
always @*
	case ({resZero,sa,op,sb})	// synopsys full_case parallel_case
	4'b0000: so1 <= 0;			// + + + = +
	4'b0001: so1 <= !a_gt_b;	// + + - = sign of larger
	4'b0010: so1 <= !a_gt_b;	// + - + = sign of larger
	4'b0011: so1 <= 0;			// + - - = +
	4'b0100: so1 <= a_gt_b;		// - + + = sign of larger
	4'b0101: so1 <= 1;			// - + - = -
	4'b0110: so1 <= 1;			// - - + = -
	4'b0111: so1 <= a_gt_b;		// - - - = sign of larger
	4'b1000: so1 <= 0;			//  A +  B, sign = +
	4'b1001: so1 <= rm==3;		//  A + -B, sign = + unless rounding down
	4'b1010: so1 <= rm==3;		//  A -  B, sign = + unless rounding down
	4'b1011: so1 <= 0;			// +A - -B, sign = +
	4'b1100: so1 <= rm==3;		// -A +  B, sign = + unless rounding down
	4'b1101: so1 <= 1;			// -A + -B, sign = -
	4'b1110: so1 <= 1;			// -A - +B, sign = -
	4'b1111: so1 <= rm==3;		// -A - -B, sign = + unless rounding down
	endcase

delay2 #(EMSB+1) d1(.clk(clk), .ce(ce), .i(xo1), .o(xo) );
delay2 #(1)      d2(.clk(clk), .ce(ce), .i(so1), .o(so) );

// Compute the difference in exponents, provides shift amount
wire [EMSB:0] xdiff = xa_gt_xb ? xad - xbd : xbd - xad;
wire [6:0] xdif = xdiff > FMSB+3 ? FMSB+3 : xdiff;
wire [6:0] xdif1;

// determine which fraction to denormalize
wire [FMSB+1:0] mfs = xa_gt_xb ? fractb : fracta;
wire [FMSB+1:0] mfs1;

// Determine the sticky bit
wire sticky, sticky1;
generate
begin
if (WID==128)
    redor128 u1 (.a(xdif), .b({mfs,2'b0}), .o(sticky) );
else if (WID==96)
    redor96 u1 (.a(xdif), .b({mfs,2'b0}), .o(sticky) );
else if (WID==64)
    redor64 u1 (.a(xdif), .b({mfs,2'b0}), .o(sticky) );
else if (WID==32)
    redor32 u1 (.a(xdif), .b({mfs,2'b0}), .o(sticky) );
end
endgenerate

// register inputs to shifter and shift
delay1 #(1)      d16(.clk(clk), .ce(ce), .i(sticky), .o(sticky1) );
delay1 #(7)      d15(.clk(clk), .ce(ce), .i(xdif),   .o(xdif1) );
delay1 #(FMSB+2) d14(.clk(clk), .ce(ce), .i(mfs),    .o(mfs1) );

wire [FMSB+3:0] md1 = ({mfs1,2'b0} >> xdif1)|sticky1;

// sync control signals
delay1 #(1) d4 (.clk(clk), .ce(ce), .i(xa_gt_xb), .o(xa_gt_xb1) );
delay1 #(1) d17(.clk(clk), .ce(ce), .i(a_gt_b), .o(a_gt_b1) );
delay1 #(1) d5 (.clk(clk), .ce(ce), .i(realOp), .o(realOp1) );
delay1 #(FMSB+2) d5a(.clk(clk), .ce(ce), .i(fracta), .o(fracta1) );
delay1 #(FMSB+2) d6a(.clk(clk), .ce(ce), .i(fractb), .o(fractb1) );
delay1 #(1) d7 (.clk(clk), .ce(ce), .i(aInf), .o(aInf1) );
delay1 #(1) d8 (.clk(clk), .ce(ce), .i(bInf), .o(bInf1) );
delay1 #(1) d9 (.clk(clk), .ce(ce), .i(aNan), .o(aNan1) );
delay1 #(1) d10(.clk(clk), .ce(ce), .i(bNan), .o(bNan1) );
delay1 #(1) d11(.clk(clk), .ce(ce), .i(op), .o(op1) );

// Sort operands and perform add/subtract
// addition can generate an extra bit, subtract can't go negative
wire [FMSB+3:0] oa = xa_gt_xb1 ? {fracta1,2'b0} : md1;
wire [FMSB+3:0] ob = xa_gt_xb1 ? md1 : {fractb1,2'b0};
wire [FMSB+3:0] oaa = a_gt_b1 ? oa : ob;
wire [FMSB+3:0] obb = a_gt_b1 ? ob : oa;
wire [FMSB+4:0] mab = realOp1 ? oaa - obb : oaa + obb;

always @*
	casex({aInf1&bInf1,aNan1,bNan1})
	3'b1xx:		mo1 = {1'b0,op1,{FMSB-1{1'b0}},op1,{FMSB{1'b0}}};	// inf +/- inf - generate QNaN on subtract, inf on add
	3'bx1x:		mo1 = {1'b0,fracta1[FMSB+1:0],{FMSB{1'b0}}};
	3'bxx1: 	mo1 = {1'b0,fractb1[FMSB+1:0],{FMSB{1'b0}}};
	default:	mo1 = {mab,{FMSB-1{1'b0}}};	// mab has an extra lead bit and two trailing bits
	endcase

delay1 #(FX+1) d3(.clk(clk), .ce(ce), .i(mo1), .o(mo) );

endmodule

