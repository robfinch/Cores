// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpMul.v
//		- floating point multiplier
//		- three cycle latency
//		- can issue every clock cycle
//		- parameterized width
//		- IEEE 754 representation
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
//	Floating Point Multiplier / Divider
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
// ============================================================================

`include "fpConfig.sv"
`include "fpTypes.sv"

module fpMul (clk, ce, a, b, o, sign_exe, inf, overflow, underflow);
parameter FPWID = 52;
`include "fpSize.sv"

input clk;
input ce;
input  [MSB:0] a, b;
output [EX:0] o;
output sign_exe;
output inf;
output overflow;
output underflow;

Exponent xo1;		// extra bit for sign
reg [FX:0] mo1;

// constants
Exponent infXp = {EMSB+1{1'b1}};	// infinite / NaN - all ones
// The following is the value for an exponent of zero, with the offset
// eg. 8'h7f for eight bit exponent, 11'h7ff for eleven bit exponent, etc.
Exponent bias = {1'b0,{EMSB{1'b1}}};	//2^0 exponent
// The following is a template for a quiet nan. (MSB=1)
Mantissa qNaN  = {1'b1,{FMSB{1'b0}}};

// variables
wire [FX-1:0] fract1;
wire [EMSB+2:0] ex1;	// sum of exponents
wire [EMSB:0] ex2;

// Decompose the operands
wire sa, sb;			// sign bit
wire [EMSB:0] xa, xb;	// exponent bits
wire [FMSB+1:0] fracta, fractb;
wire a_dn, b_dn;			// a/b is denormalized
wire aNan, bNan, aNan1, bNan1;
wire az, bz;
wire aInf, bInf, aInf1, bInf1;
wire [(FMSB+1)*2:0] prod;

generate begin : mults
if (FPWID==80)
	mult65 um1 (.CLK(clk), .CE(ce), .A(fracta), .B(fractb), .P(fract1));
else if (FPWID==64)
	mult53 um1 (.CLK(clk), .CE(ce), .A(fracta), .B(fractb), .P(fract1));
else if (FPWID==52)
	mult41 um1 (.CLK(clk), .CE(ce), .A(fracta), .B(fractb), .P(fract1));
else if (FPWID==32)
	mult24 um1 (.CLK(clk), .CE(ce), .A(fracta), .B(fractb), .P(fract1));
else if (FPWID==16)
	mult11 um1 (.CLK(clk), .CE(ce), .A(fracta), .B(fractb), .P(fract1));
end
endgenerate

// -----------------------------------------------------------
// First clock
// - decode the input operands
// - derive basic information
// - calculate exponent
// - calculate fraction
// -----------------------------------------------------------

fpDecomp #(FPWID) u1a (.i(a), .sgn(sa), .exp(xa), .fract(fracta), .xz(a_dn), .vz(az), .inf(aInf), .nan(aNan) );
fpDecomp #(FPWID) u1b (.i(b), .sgn(sb), .exp(xb), .fract(fractb), .xz(b_dn), .vz(bz), .inf(bInf), .nan(bNan) );

// Compute the sum of the exponents.
// correct the exponent for denormalized operands
// adjust the sum by the exponent offset (subtract 127)
// mul: ex1 = xa + xb,	result should always be < 1ffh
assign ex1 = (az|bz) ? 0 : (xa|a_dn) + (xb|b_dn) - bias;


// Status
wire under1, over1;
wire under = ex1[EMSB+2];	// exponent underflow
wire over = (&ex1[EMSB:0] | ex1[EMSB+1]) & !ex1[EMSB+2];

delay2 #(EMSB+1) u3 (.clk(clk), .ce(ce), .i(ex1[EMSB:0]), .o(ex2) );
delay2 u2a (.clk(clk), .ce(ce), .i(aInf), .o(aInf1) );
delay2 u2b (.clk(clk), .ce(ce), .i(bInf), .o(bInf1) );
delay2 u6  (.clk(clk), .ce(ce), .i(under), .o(under1) );
delay2 u7  (.clk(clk), .ce(ce), .i(over), .o(over1) );

// determine when a NaN is output
wire qNaNOut;
wire [FPWID-1:0] a1,b1;
delay2 u5 (.clk(clk), .ce(ce), .i((aInf&bz)|(bInf&az)), .o(qNaNOut) );
delay2 u14 (.clk(clk), .ce(ce), .i(aNan), .o(aNan1) );
delay2 u15 (.clk(clk), .ce(ce), .i(bNan), .o(bNan1) );
delay2 #(FPWID) u16 (.clk(clk), .ce(ce), .i(a), .o(a1) );
delay2 #(FPWID) u17 (.clk(clk), .ce(ce), .i(b), .o(b1) );

// -----------------------------------------------------------
// Second clock
// - correct xponent and mantissa for exceptional conditions
// -----------------------------------------------------------

wire so1;
delay3 u8 (.clk(clk), .ce(ce), .i(sa ^ sb), .o(so1) );// two clock delay!

always @(posedge clk)
	if (ce)
		casez({qNaNOut|aNan1|bNan1,aInf1,bInf1,over1,under1})
		5'b1????:	xo1 = infXp;	// qNaN - infinity * zero
		5'b01???:	xo1 = infXp;	// 'a' infinite
		5'b001??:	xo1 = infXp;	// 'b' infinite
		5'b0001?:	xo1 = infXp;	// result overflow
		5'b00001:	xo1 = ex2[EMSB:0];//0;		// underflow
		default:	xo1 = ex2[EMSB:0];	// situation normal
		endcase

always @(posedge clk)
	if (ce)
		casez({aNan1,bNan1,qNaNOut,aInf1,bInf1,over1})
		6'b1?????:  mo1 = {1'b1,a1[FMSB:0],{FMSB+1{1'b0}}};
    6'b01????:  mo1 = {1'b1,b1[FMSB:0],{FMSB+1{1'b0}}};
		6'b001???:	mo1 = {1'b1,qNaN|3'd4,{FMSB+1{1'b0}}};	// multiply inf * zero
		6'b0001??:	mo1 = 0;	// mul inf's
		6'b00001?:	mo1 = 0;	// mul inf's
		6'b000001:	mo1 = 0;	// mul overflow
		default:	mo1 = fract1;
		endcase

delay3 u10 (.clk(clk), .ce(ce), .i(sa & sb), .o(sign_exe) );
delay1 u11 (.clk(clk), .ce(ce), .i(over1),  .o(overflow) );
delay1 u12 (.clk(clk), .ce(ce), .i(over1),  .o(inf) );
delay1 u13 (.clk(clk), .ce(ce), .i(under1), .o(underflow) );

assign o = {so1,xo1,mo1};

endmodule


// Multiplier with normalization and rounding.

module fpMulnr(clk, ce, a, b, o, rm, sign_exe, inf, overflow, underflow);
parameter FPWID=64;
`include "fpSize.sv"

input clk;
input ce;
input  [MSB:0] a, b;
output [MSB:0] o;
input [2:0] rm;
output sign_exe;
output inf;
output overflow;
output underflow;

wire [EX:0] o1;
wire sign_exe1, inf1, overflow1, underflow1;
FloatGRS fpn0;

fpMul       #(FPWID) u1 (clk, ce, a, b, o1, sign_exe1, inf1, overflow1, underflow1);
fpNormalize #(FPWID) u2(.clk(clk), .ce(ce), .under_i(underflow1), .i(o1), .o(fpn0) );
fpRound     #(FPWID) u3(.clk(clk), .ce(ce), .rm(rm), .i(fpn0), .o(o) );
delay2      #(1)   u4(.clk(clk), .ce(ce), .i(sign_exe1), .o(sign_exe));
delay2      #(1)   u5(.clk(clk), .ce(ce), .i(inf1), .o(inf));
delay2      #(1)   u6(.clk(clk), .ce(ce), .i(overflow1), .o(overflow));
delay2      #(1)   u7(.clk(clk), .ce(ce), .i(underflow1), .o(underflow));
endmodule

