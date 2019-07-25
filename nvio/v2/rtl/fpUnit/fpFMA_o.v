// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpFMA.v
//		- floating point fused multiplier + adder
//		- can issue every clock cycle
//		- parameterized FPWIDth
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
// ============================================================================

`include "fpConfig.sv"

module fpFMA (clk, ce, op, rm, a, b, c, o, under, over, inf, zero);
parameter FPWID = 32;
`include "fpSize.sv"

input clk;
input ce;
input op;		// operation 0 = add, 1 = subtract
input [2:0] rm;
input  [MSB:0] a, b, c;
output [EX:0] o;
output under;
output over;
output inf;
output zero;

// constants
wire [EMSB:0] infXp = {EMSB+1{1'b1}};	// infinite / NaN - all ones
// The following is the value for an exponent of zero, with the offset
// eg. 8'h7f for eight bit exponent, 11'h7ff for eleven bit exponent, etc.
wire [EMSB:0] bias = {1'b0,{EMSB{1'b1}}};	//2^0 exponent
// The following is a template for a quiet nan. (MSB=1)
wire [FMSB:0] qNaN  = {1'b1,{FMSB{1'b0}}};

// -----------------------------------------------------------
// Clock #1
// - decode the input operands
// - derive basic information
// -----------------------------------------------------------

wire sa1, sb1, sc1;			// sign bit
wire [EMSB:0] xa1, xb1, xc1;	// exponent bits
wire [FMSB+1:0] fracta1, fractb1, fractc1;	// includes unhidden bit
wire a_dn1, b_dn1, c_dn1;			// a/b is denormalized
wire aNan1, bNan1, cNan1;
wire az1, bz1, cz1;
wire aInf1, bInf1, cInf1;
reg op1;

fpDecompReg #(FPWID) u1a (.clk(clk), .ce(ce), .i(a), .sgn(sa1), .exp(xa1), .fract(fracta1), .xz(a_dn1), .vz(az1), .inf(aInf1), .nan(aNan1) );
fpDecompReg #(FPWID) u1b (.clk(clk), .ce(ce), .i(b), .sgn(sb1), .exp(xb1), .fract(fractb1), .xz(b_dn1), .vz(bz1), .inf(bInf1), .nan(bNan1) );
fpDecompReg #(FPWID) u1c (.clk(clk), .ce(ce), .i(c), .sgn(sc1), .exp(xc1), .fract(fractc1), .xz(c_dn1), .vz(cz1), .inf(cInf1), .nan(cNan1) );

always @(posedge clk)
	if (ce) op1 <= op;

// -----------------------------------------------------------
// Clock #2
// Compute the sum of the exponents.
// correct the exponent for denormalized operands
// adjust the sum by the exponent offset (subtract 127)
// mul: ex1 = xa + xb,	result should always be < 1ffh
// Form partial products (clocks 2 to 5)
// -----------------------------------------------------------

reg abz2;
reg [EMSB+2:0] ex2;
reg [EMSB:0] xc2;
reg realOp2;
reg xcInf2;

always @(posedge clk)
	if (ce) abz2 <= az1|bz1;
always @(posedge clk)
	if (ce) ex2 <= (xa1|a_dn1) + (xb1|b_dn1) - bias;
always @(posedge clk)
	if (ce) xc2 <= (xc1|c_dn1);
always @(posedge clk)
	if (ce) xcInf2 = &xc1;

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
always @(posedge clk)
	if (ce) realOp2 <= op1 ^ (sa1 ^ sb1) ^ sc1;


reg [FX:0] fract5;
generate
if (FPWID+`EXTRA_BITS==84) begin
reg [33:0] p00,p01,p02,p03;
reg [33:0] p10,p11,p12,p13;
reg [33:0] p20,p21,p22,p23;
reg [33:0] p30,p31,p32,p33;
reg [135:0] fract3a;
reg [135:0] fract3b;
reg [135:0] fract3c;
reg [135:0] fract3d;
reg [135:0] fract4a;
reg [135:0] fract4b;

	always @(posedge clk)
	if (ce) begin
		p00 <= fracta1[16: 0] * fractb1[16: 0];
		p01 <= fracta1[33:17] * fractb1[16: 0];
		p02 <= fracta1[50:34] * fractb1[16: 0];
		p03 <= fracta1[67:51] * fractb1[16: 0];
		
		p10 <= fracta1[16: 0] * fractb1[33:17];
		p11 <= fracta1[33:17] * fractb1[33:17];
		p12 <= fracta1[50:34] * fractb1[33:17];
		p13 <= fracta1[67:51] * fractb1[33:17];

		p20 <= fracta1[16: 0] * fractb1[50:34];
		p21 <= fracta1[33:17] * fractb1[50:34];
		p22 <= fracta1[50:34] * fractb1[50:34];
		p23 <= fracta1[67:51] * fractb1[50:34];

		p30 <= fracta1[15: 0] * fractb1[67:51];
		p31 <= fracta1[31:16] * fractb1[67:51];
		p32 <= fracta1[47:32] * fractb1[67:51];
		p33 <= fracta1[63:48] * fractb1[67:51];
	end
	always @(posedge clk)
	if (ce) begin
		fract3a <= {p33,p31,p20,p00};
		fract3b <= {p32,p12,p10,17'b0} + {p23,p03,p01,17'b0};
		fract3c <= {p22,p11,34'b0} + {p13,p02,34'b0};
		fract3d <= {p12,51'b0} + {p03,51'b0};
	end
	always @(posedge clk)
	if (ce) begin
		fract4a <= fract3a + fract3b;
		fract4b <= fract3c + fract3d;
	end		
	always @(posedge clk)
	if (ce) begin
		fract5 <= fract4a + fract4b;
	end
end
else if (FPWID+`EXTRA_BITS==80) begin
reg [31:0] p00,p01,p02,p03;
reg [31:0] p10,p11,p12,p13;
reg [31:0] p20,p21,p22,p23;
reg [31:0] p30,p31,p32,p33;
reg [127:0] fract3a;
reg [127:0] fract3b;
reg [127:0] fract3c;
reg [127:0] fract3d;
reg [127:0] fract4a;
reg [127:0] fract4b;

	always @(posedge clk)
	if (ce) begin
		p00 <= fracta1[15: 0] * fractb1[15: 0];
		p01 <= fracta1[31:16] * fractb1[15: 0];
		p02 <= fracta1[47:32] * fractb1[15: 0];
		p03 <= fracta1[63:48] * fractb1[15: 0];
		
		p10 <= fracta1[15: 0] * fractb1[31:16];
		p11 <= fracta1[31:16] * fractb1[31:16];
		p12 <= fracta1[47:32] * fractb1[31:16];
		p13 <= fracta1[63:48] * fractb1[31:16];

		p20 <= fracta1[15: 0] * fractb1[47:32];
		p21 <= fracta1[31:16] * fractb1[47:32];
		p22 <= fracta1[47:32] * fractb1[47:32];
		p23 <= fracta1[63:48] * fractb1[47:32];

		p30 <= fracta1[15: 0] * fractb1[63:48];
		p31 <= fracta1[31:16] * fractb1[63:48];
		p32 <= fracta1[47:32] * fractb1[63:48];
		p33 <= fracta1[63:48] * fractb1[63:48];
	end
	always @(posedge clk)
	if (ce) begin
		fract3a <= {p33,p31,p20,p00};
		fract3b <= {p32,p12,p10,16'b0} + {p23,p03,p01,16'b0};
		fract3c <= {p22,p11,32'b0} + {p13,p02,32'b0};
		fract3d <= {p12,48'b0} + {p03,48'b0};
	end
	always @(posedge clk)
	if (ce) begin
		fract4a <= fract3a + fract3b;
		fract4b <= fract3c + fract3d;
	end		
	always @(posedge clk)
	if (ce) begin
		fract5 <= fract4a + fract4b;
	end
end
else if (FPWID+`EXTRA_BITS==64) begin
reg [35:0] p00,p01,p02;
reg [35:0] p10,p11,p12;
reg [35:0] p20,p21,p22;
reg [71:0] fract3a;
reg [89:0] fract3b;
reg [107:0] fract3c;
reg [108:0] fract4a;
reg [108:0] fract4b;

	always @(posedge clk)
	if (ce) begin
		p00 <= fracta1[17: 0] * fractb1[17: 0];
		p01 <= fracta1[35:18] * fractb1[17: 0];
		p02 <= fracta1[52:36] * fractb1[17: 0];
		p10 <= fracta1[17: 0] * fractb1[35:18];
		p11 <= fracta1[35:18] * fractb1[35:18];
		p12 <= fracta1[52:36] * fractb1[35:18];
		p20 <= fracta1[17: 0] * fractb1[52:36];
		p21 <= fracta1[35:18] * fractb1[52:36];
		p22 <= fracta1[52:36] * fractb1[52:36];
	end
	always @(posedge clk)
	if (ce) begin
		fract3a <= {p02,p00};
		fract3b <= {p21,p10,18'b0} + {p12,p01,18'b0};
		fract3c <= {p22,p20,36'b0} + {p11,36'b0};
	end
	always @(posedge clk)
	if (ce) begin
		fract4a <= fract3a + fract3b;
		fract4b <= fract3c;
	end
	always @(posedge clk)
	if (ce) begin
		fract5 <= fract4a + fract4b;
	end
end
else if (FPWID+`EXTRA_BITS==40) begin
reg [27:0] p00,p01,p02;
reg [27:0] p10,p11,p12;
reg [27:0] p20,p21,p22;
reg [79:0] fract3a;
reg [79:0] fract3b;
reg [79:0] fract3c;
reg [79:0] fract4a;
reg [79:0] fract4b;
	always @(posedge clk)
	if (ce) begin
		p00 <= fracta1[13: 0] * fractb1[13: 0];
		p01 <= fracta1[27:14] * fractb1[13: 0];
		p02 <= fracta1[39:28] * fractb1[13: 0];
		p10 <= fracta1[13: 0] * fractb1[27:14];
		p11 <= fracta1[27:14] * fractb1[27:14];
		p12 <= fracta1[39:28] * fractb1[27:14];
		p20 <= fracta1[13: 0] * fractb1[39:28];
		p21 <= fracta1[27:14] * fractb1[39:28];
		p22 <= fracta1[39:28] * fractb1[39:28];
	end
	always @(posedge clk)
	if (ce) begin
		fract3a <= {p02,p00};
		fract3b <= {p21,p10,18'b0} + {p12,p01,18'b0};
		fract3c <= {p22,p20,36'b0} + {p11,36'b0};
	end
	always @(posedge clk)
	if (ce) begin
		fract4a <= fract3a + fract3b;
		fract4b <= fract3c;
	end
	always @(posedge clk)
	if (ce) begin
		fract5 <= fract4a + fract4b;
	end
end
else if (FPWID+`EXTRA_BITS==32) begin
reg [23:0] p00,p01,p02;
reg [23:0] p10,p11,p12;
reg [23:0] p20,p21,p22;
reg [63:0] fract3a;
reg [63:0] fract3b;
reg [63:0] fract4;

	always @(posedge clk)
	if (ce) begin
		p00 <= fracta1[11: 0] * fractb1[11: 0];
		p01 <= fracta1[23:12] * fractb1[11: 0];
		p10 <= fracta1[11: 0] * fractb1[23:12];
		p11 <= fracta1[23:12] * fractb1[23:12];
	end
	always @(posedge clk)
	if (ce) begin
		fract3a <= {p11,p00};
		fract3b <= {p01,12'b0} + {p10,12'b0};
	end
	always @(posedge clk)
	if (ce) begin
		fract4 <= fract3a + fract3b;
	end
	always @(posedge clk)
	if (ce) begin
		fract5 <= fract4;
	end
end
else begin
reg [FX:0] p00;
reg [FX:0] fract3;
reg [FX:0] fract4;
	always @(posedge clk)
    if (ce) begin
    	p00 <= fracta1 * fractb1;
    end
	always @(posedge clk)
    if (ce)
    	fract3 <= p00;
	always @(posedge clk)
    if (ce)
    	fract4 <= fract3;
	always @(posedge clk)
    if (ce)
    	fract5 <= fract4;
end
endgenerate

// -----------------------------------------------------------
// Clock #3
// Select zero exponent
// -----------------------------------------------------------

reg [EMSB+2:0] ex3;
reg [EMSB:0] xc3;
always @(posedge clk)
	if (ce) ex3 <= abz2 ? 1'd0 : ex2;
always @(posedge clk)
	if (ce) xc3 <= xc2;

// -----------------------------------------------------------
// Clock #4
// Generate partial products.
// -----------------------------------------------------------

reg [EMSB+2:0] ex4;
reg [EMSB:0] xc4;

always @(posedge clk)
	if (ce) ex4 <= ex3;
always @(posedge clk)
	if (ce) xc4 <= xc3;

// -----------------------------------------------------------
// Clock #5
// Sum partial products (above)
// compute multiplier overflow and underflow
// -----------------------------------------------------------

// Status
reg under5;
reg over5;
reg [EMSB+2:0] ex5;
reg [EMSB:0] xc5;
wire aInf5, bInf5;
wire aNan5, bNan5;
wire qNaNOut5;

always @(posedge clk)
	if (ce) under5 <= ex4[EMSB+2];
always @(posedge clk)
	if (ce) over5 <= (&ex4[EMSB:0] | ex4[EMSB+1]) & !ex4[EMSB+2];
always @(posedge clk)
	if (ce) ex5 <= ex4;
always @(posedge clk)
	if (ce) xc5 <= xc4;

delay4 u2a (.clk(clk), .ce(ce), .i(aInf1), .o(aInf5) );
delay4 u2b (.clk(clk), .ce(ce), .i(bInf1), .o(bInf5) );

// determine when a NaN is output
wire [MSB:0] a5,b5;
delay4 u5 (.clk(clk), .ce(ce), .i((aInf1&bz1)|(bInf1&az1)), .o(qNaNOut5) );
delay4 u14 (.clk(clk), .ce(ce), .i(aNan1), .o(aNan5) );
delay4 u15 (.clk(clk), .ce(ce), .i(bNan1), .o(bNan5) );
delay5 #(MSB+1) u16 (.clk(clk), .ce(ce), .i(a), .o(a5) );
delay5 #(MSB+1) u17 (.clk(clk), .ce(ce), .i(b), .o(b5) );

// -----------------------------------------------------------
// Clock #6
// - figure multiplier mantissa output
// - figure multiplier exponent output
// - correct xponent and mantissa for exceptional conditions
// -----------------------------------------------------------

reg [FX:0] mo6;
reg [EMSB+2:0] ex6;
reg [EMSB:0] xc6;
wire [FMSB+1:0] fractc6;
vtdl #(FMSB+2) u61 (.clk(clk), .ce(ce), .a(4'd4), .d(fractc1), .q(fractc6) );
delay1 u62 (.clk(clk), .ce(ce), .i(under5), .o(under6));

always @(posedge clk)
	if (ce) xc6 <= xc5;

always @(posedge clk)
	if (ce)
		casez({aNan5,bNan5,qNaNOut5,aInf5,bInf5,over5})
		6'b1?????:  mo6 <= {1'b1,1'b1,a5[FMSB-1:0],{FMSB+1{1'b0}}};
    6'b01????:  mo6 <= {1'b1,1'b1,b5[FMSB-1:0],{FMSB+1{1'b0}}};
		6'b001???:	mo6 <= {1'b1,qNaN|3'd4,{FMSB+1{1'b0}}};	// multiply inf * zero
		6'b0001??:	mo6 <= 0;	// mul inf's
		6'b00001?:	mo6 <= 0;	// mul inf's
		6'b000001:	mo6 <= 0;	// mul overflow
		default:	mo6 <= fract5;
		endcase

always @(posedge clk)
	if (ce)
		casez({qNaNOut5|aNan5|bNan5,aInf5,bInf5,over5,under5})
		5'b1????:	ex6 <= infXp;	// qNaN - infinity * zero
		5'b01???:	ex6 <= infXp;	// 'a' infinite
		5'b001??:	ex6 <= infXp;	// 'b' infinite
		5'b0001?:	ex6 <= infXp;	// result overflow
		5'b00001:	ex6 <= ex5;		//0;		// underflow
		default:	ex6 <= ex5;		// situation normal
		endcase

// -----------------------------------------------------------
// Clock #7
// - prep for addition, determine greater operand
// -----------------------------------------------------------
reg ex_gt_xc7;
reg xeq7;
reg ma_gt_mc7;
reg meq7;
wire az7, bz7, cz7;
wire realOp7;

// which has greater magnitude ? Used for sign calc
always @(posedge clk)
	if (ce) ex_gt_xc7 <= $signed(ex6) > $signed({2'b0,xc6});
always @(posedge clk)
	if (ce) xeq7 <= (ex6=={2'b0,xc6});
always @(posedge clk)
	if (ce) ma_gt_mc7 <= mo6 > {fractc6,{FMSB+1{1'b0}}};
always @(posedge clk)
	if (ce) meq7 <= mo6 == {fractc6,{FMSB+1{1'b0}}};
vtdl #(1) u71 (.clk(clk), .ce(ce), .a(4'd5), .d(az1), .q(az7));
vtdl #(1) u72 (.clk(clk), .ce(ce), .a(4'd5), .d(bz1), .q(bz7));
vtdl #(1) u73 (.clk(clk), .ce(ce), .a(4'd5), .d(cz1), .q(cz7));
vtdl #(1) u74 (.clk(clk), .ce(ce), .a(4'd4), .d(realOp2), .q(realOp7));

// -----------------------------------------------------------
// Clock #8
// - prep for addition, determine greater operand
// - determine if result will be zero
// -----------------------------------------------------------

reg a_gt_b8;
reg resZero8;
reg ex_gt_xc8;
wire [EMSB+2:0] ex8;
wire [EMSB:0] xc8;
wire xcInf8;
wire [2:0] rm8;
wire op8;
wire sa8, sc8;

delay2 #(EMSB+3) u81 (.clk(clk), .ce(ce), .i(ex6), .o(ex8));
delay2 #(EMSB+1) u82 (.clk(clk), .ce(ce), .i(xc6), .o(xc8));
vtdl #(1) u83 (.clk(clk), .ce(ce), .a(4'd5), .d(xcInf2), .q(xcInf8));
vtdl #(3) u84 (.clk(clk), .ce(ce), .a(4'd7), .d(rm), .q(rm8));
vtdl #(1) u85 (.clk(clk), .ce(ce), .a(4'd6), .d(op1), .q(op8));
vtdl #(1) u86 (.clk(clk), .ce(ce), .a(4'd6), .d(sa1 ^ sb1), .q(sa8));
vtdl #(1) u87 (.clk(clk), .ce(ce), .a(4'd6), .d(sc1), .q(sc8));

always @(posedge clk)
	if (ce) ex_gt_xc8 <= ex_gt_xc7;
always @(posedge clk)
	if (ce)
		a_gt_b8 <= ex_gt_xc7 || (xeq7 && ma_gt_mc7);

// Find out if the result will be zero.
always @(posedge clk)
	if (ce)
		resZero8 <= (realOp7 & xeq7 & meq7) ||	// subtract, same magnitude
			   ((az7 | bz7) & cz7);		// a or b zero and c zero

// -----------------------------------------------------------
// CLock #9
// Compute output exponent and sign
//
// The output exponent is the larger of the two exponents,
// unless a subtract operation is in progress and the two
// numbers are equal, in which case the exponent should be
// zero.
// -----------------------------------------------------------

reg so9;
reg [EMSB+2:0] ex9;
reg [EMSB+2:0] ex9a;
reg ex_gt_xc9;
reg [EMSB:0] xc9;
reg a_gt_c9;
wire [FX:0] mo9;
wire [FMSB+1:0] fractc9;
wire under9;
wire xeq9;

always @(posedge clk)
	if (ce) ex_gt_xc9 <= ex_gt_xc8;
always @(posedge clk)
	if (ce) a_gt_c9 <= a_gt_b8;
always @(posedge clk)
	if (ce) xc9 <= xc8;
always @(posedge clk)
	if (ce) ex9a <= ex8;

delay3 #(FX+1) u93 (.clk(clk), .ce(ce), .i(mo6), .o(mo9));
delay3 #(FMSB+2) u94 (.clk(clk), .ce(ce), .i(fractc6), .o(fractc9));
delay3 u95 (.clk(clk), .ce(ce), .i(under6), .o(under9));
delay2 u96 (.clk(clk), .ce(ce), .i(xeq7), .o(xeq9));

always @(posedge clk)
	if (ce) ex9 <= resZero8 ? 1'd0 : ex_gt_xc8 ? ex8 : {2'b0,xc8};

// Compute output sign
always @(posedge clk)
	if (ce)
	case ({resZero8,sa8,op8,sc8})	// synopsys full_case parallel_case
	4'b0000: so9 <= 0;			// + + + = +
	4'b0001: so9 <= !a_gt_b8;	// + + - = sign of larger
	4'b0010: so9 <= !a_gt_b8;	// + - + = sign of larger
	4'b0011: so9 <= 0;			// + - - = +
	4'b0100: so9 <= a_gt_b8;		// - + + = sign of larger
	4'b0101: so9 <= 1;			// - + - = -
	4'b0110: so9 <= 1;			// - - + = -
	4'b0111: so9 <= a_gt_b8;		// - - - = sign of larger
	4'b1000: so9 <= 0;			//  A +  B, sign = +
	4'b1001: so9 <= rm8==3;		//  A + -B, sign = + unless rounding down
	4'b1010: so9 <= rm8==3;		//  A -  B, sign = + unless rounding down
	4'b1011: so9 <= 0;			// +A - -B, sign = +
	4'b1100: so9 <= rm8==3;		// -A +  B, sign = + unless rounding down
	4'b1101: so9 <= 1;			// -A + -B, sign = -
	4'b1110: so9 <= 1;			// -A - +B, sign = -
	4'b1111: so9 <= rm8==3;		// -A - -B, sign = + unless rounding down
	endcase

// -----------------------------------------------------------
// Clock #10
// Compute the difference in exponents, provides shift amount
// Note that ex9a will be negative for an underflow condition
// so it's added rather than subtracted from xc9 as -(-num)
// is the same as an add. The underflow is tracked rather than
// using extra bits in the exponent.
// -----------------------------------------------------------
reg [EMSB+2:0] xdiff10;
reg [FX:0] mfs;
reg ops10;

// If the multiplier exponent was negative (underflowed) then
// the mantissa needs to be shifted right even more (until
// the exponent is zero. The total shift would be xc9-0-
// amount underflows which is xc9 + -ex9a.

always @(posedge clk)
	if (ce) xdiff10 <= ex_gt_xc9 ? ex9a - xc9
										: ex9a[EMSB+2] ? xc9 + (~ex9a+2'd1)
										: xc9 - ex9a;

// Determine which fraction to denormalize (the one with the
// smaller exponent is denormalized). If the exponents are equal
// denormalize the smaller fraction.
always @(posedge clk)
	if (ce) mfs <= 
		xeq9 ? (a_gt_c9 ? {4'b0,fractc9,{FMSB+1{1'b0}}} : mo9)
		 : ex_gt_xc9 ? {4'b0,fractc9,{FMSB+1{1'b0}}} : mo9;

always @(posedge clk)
	if (ce) ops10 <= xeq9 ? (a_gt_c9 ? 1'b1 : 1'b0)
												: (ex_gt_xc9 ? 1'b1 : 1'b0);

// -----------------------------------------------------------
// Clock #11
// Limit the size of the shifter to only bits needed.
// -----------------------------------------------------------
reg [7:0] xdif11;

always @(posedge clk)
	if (ce) xdif11 <= xdiff10 > FX+3 ? FX+3 : xdiff10;

// -----------------------------------------------------------
// Clock #12
// Determine the sticky bit
// -----------------------------------------------------------

wire sticky, sticky12;
wire [FX:0] mfs12;
wire [7:0] xdif12;

generate
begin
if (FPWID+`EXTRA_BITS==128)
    redor128 u121 (.a(xdif11), .b({mfs,2'b0}), .o(sticky) );
else if (FPWID+`EXTRA_BITS==96)
    redor96 u121 (.a(xdif11), .b({mfs,2'b0}), .o(sticky) );
else if (FPWID+`EXTRA_BITS==84)
    redor84 u121 (.a(xdif11), .b({mfs,2'b0}), .o(sticky) );
else if (FPWID+`EXTRA_BITS==80)
    redor80 u121 (.a(xdif11), .b({mfs,2'b0}), .o(sticky) );
else if (FPWID+`EXTRA_BITS==64)
    redor64 u121 (.a(xdif11), .b({mfs,2'b0}), .o(sticky) );
else if (FPWID+`EXTRA_BITS==32)
    redor32 u121 (.a(xdif11), .b({mfs,2'b0}), .o(sticky) );
end
endgenerate

// register inputs to shifter and shift
delay1 #(1)    u122(.clk(clk), .ce(ce), .i(sticky), .o(sticky12) );
delay1 #(8)    u123(.clk(clk), .ce(ce), .i(xdif11),   .o(xdif12) );
delay2 #(FX+1) u124(.clk(clk), .ce(ce), .i(mfs), .o(mfs12) );

// -----------------------------------------------------------
// Clock #13
// - denormalize operand (shift right)
// -----------------------------------------------------------
reg [FX+2:0] mfs13;
wire [FX:0] mo13;
wire ex_gt_xc13;
wire [FMSB+1:0] fractc13;
wire ops13;

delay4 #(FX+1) u131 (.clk(clk), .ce(ce), .i(mo9), .o(mo13));
delay4 u132 (.clk(clk), .ce(ce), .i(ex_gt_xc9), .o(ex_gt_xc13));
vtdl #(FMSB+2) u133 (.clk(clk), .ce(ce), .a(4'd3), .d(fractc9), .q(fractc13));
delay3 u134 (.clk(clk), .ce(ce), .i(ops10), .o(ops13));

always @(posedge clk)
	if (ce) mfs13 <= ({mfs12,2'b0} >> xdif12)|sticky12;

// -----------------------------------------------------------
// Clock #14
// Sort operands
// -----------------------------------------------------------
reg [FX+2:0] oa, ob;
wire a_gt_b14;

vtdl #(1) u141 (.clk(clk), .ce(ce), .a(4'd5), .d(a_gt_b8), .q(a_gt_b14));

always @(posedge clk)
	if (ce) oa <= ops13 ? {mo13,2'b00} : mfs13;
always @(posedge clk)
	if (ce) ob <= ops13 ? mfs13 : {fractc13,{FMSB+1{1'b0}},2'b00};

// -----------------------------------------------------------
// Clock #15
// - Sort operands
// -----------------------------------------------------------
reg [FX+2:0] oaa, obb;
wire realOp15;
wire [EMSB:0] ex15;
wire [EMSB:0] ex9c = ex9[EMSB+1] ? infXp : ex9[EMSB:0];
wire overflow15;
vtdl #(1) u151 (.clk(clk), .ce(ce), .a(4'd7), .d(realOp7), .q(realOp15));
vtdl #(EMSB+1) u152 (.clk(clk), .ce(ce), .a(4'd5), .d(ex9c), .q(ex15));
vtdl #(EMSB+1) u153 (.clk(clk), .ce(ce), .a(4'd5), .d(ex9[EMSB+1]| &ex9[EMSB:0]), .q(overflow15));

always @(posedge clk)
	if (ce) oaa <= a_gt_b14 ? oa : ob;
always @(posedge clk)
	if (ce) obb <= a_gt_b14 ? ob : oa;

// -----------------------------------------------------------
// Clock #16
// - perform add/subtract
// - addition can generate an extra bit, subtract can't go negative
// -----------------------------------------------------------
reg [FX+3:0] mab;
wire [FX:0] mo16;
wire [FMSB+1:0] fractc16;
wire Nan16;
wire cNan16;
wire aInf16, cInf16;
wire op16;
wire exinf16;

vtdl #(1) u161 (.clk(clk), .ce(ce), .a(4'd10), .d(qNaNOut5|aNan5|bNan5), .q(Nan16));
vtdl #(1) u162 (.clk(clk), .ce(ce), .a(4'd14), .d(cNan1), .q(cNan16));
vtdl #(1) u163 (.clk(clk), .ce(ce), .a(4'd9), .d(&ex6), .q(aInf16));
vtdl #(1) u164 (.clk(clk), .ce(ce), .a(4'd14), .d(cInf1), .q(cInf16));
vtdl #(1) u165 (.clk(clk), .ce(ce), .a(4'd14), .d(op1), .q(op16));
delay3 #(FX+1) u166 (.clk(clk), .ce(ce), .i(mo13), .o(mo16));
vtdl #(FMSB+2) u167 (.clk(clk), .ce(ce), .a(4'd6), .d(fractc9), .q(fractc16));
delay1 u169 (.clk(clk), .ce(ce), .i(&ex15), .o(exinf16));

always @(posedge clk)
	if (ce) mab <= realOp15 ? oaa - obb : oaa + obb;

// -----------------------------------------------------------
// Clock #17
// - adjust for Nans
// -----------------------------------------------------------
wire [EMSB:0] ex17;
reg [FX:0] mo17;
wire so17;
wire exinf17;
wire overflow17;

vtdl #(1)        u171 (.clk(clk), .ce(ce), .a(4'd7), .d(so9), .q(so17));
delay2 #(EMSB+1) u172 (.clk(clk), .ce(ce), .i(ex15), .o(ex17));
delay1 #(1) u173 (.clk(clk), .ce(ce), .i(exinf16), .o(exinf17));
delay2 u174 (.clk(clk), .ce(ce), .i(overflow15), .o(overflow17));

always @(posedge clk)
	casez({aInf16&cInf16,Nan16,cNan16,exinf16})
	4'b1???:	mo17 <= {1'b0,op16,{FMSB-1{1'b0}},op16,{FMSB{1'b0}}};	// inf +/- inf - generate QNaN on subtract, inf on add
	4'b01??:	mo17 <= {1'b0,mo16};
	4'b001?: 	mo17 <= {1'b1,1'b1,fractc16[FMSB-1:0],{FMSB+1{1'b0}}};
	4'b0001:	mo17 <= 1'd0;
	default:	mo17 <= mab[FX+3:2];		// mab has two extra lead bits and two trailing bits
	endcase

assign o = {so17,ex17,mo17};
assign zero = {ex17,mo17}==1'd0;
assign inf = exinf17;
assign under = ex17==1'd0;
assign over = overflow17;

endmodule


// Multiplier with normalization and rounding.

module fpFMAnr(clk, ce, op, rm, a, b, c, o, inf, zero, overflow, underflow, inexact);
parameter FPWID=64;
`include "fpSize.sv"

input clk;
input ce;
input op;
input [2:0] rm;
input  [MSB:0] a, b, c;
output [MSB:0] o;
output zero;
output inf;
output overflow;
output underflow;
output inexact;

wire [EX:0] fma_o;
wire fma_underflow;
wire fma_overflow;
wire norm_underflow;
wire norm_inexact;
wire sign_exe1, inf1, overflow1, underflow1;
wire [MSB+3:0] fpn0;

fpFMA #(FPWID) u1
(
	.clk(clk),
	.ce(ce),
	.op(op),
	.rm(rm),
	.a(a),
	.b(b),
	.c(c),
	.o(fma_o),
	.under(fma_underflow),
	.over(fma_overflow),
	.zero(),
	.inf()
);
fpNormalize #(FPWID) u2
(
	.clk(clk),
	.ce(ce),
	.i(fma_o),
	.o(fpn0),
	.under_i(fma_underflow),
	.under_o(norm_underflow),
	.inexact_o(norm_inexact)
);
fpRound  	#(FPWID) u3(.clk(clk), .ce(ce), .rm(rm), .i(fpn0), .o(o) );
fpDecomp	#(FPWID) u4(.i(o), .xz(), .vz(zero), .inf(inf));
vtdl						u5 (.clk(clk), .ce(ce), .a(4'd11), .d(fma_underflow), .q(underflow));
vtdl						u6 (.clk(clk), .ce(ce), .a(4'd11), .d(fma_overflow), .q(overflow));
delay3		#(1)	u7 (.clk(clk), .ce(ce), .i(norm_inexact), .o(inexact));
assign overflow = inf;

endmodule

