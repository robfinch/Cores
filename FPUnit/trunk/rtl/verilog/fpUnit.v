`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006, 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpUnit.v
//		- floating point unit
//		- parameterized width
//		- IEEE 754 representation
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
//	NaN operations
//	There are some operations the fpu performs that can
//	generate NaN's. The value of the NaN generated and
//	the cause are listed below.
//
//	NaN Value		Origin
//	31'h7FC00001	- infinity - infinity
//	31'h7FC00002	- infinity / infinity
//	31'h7FC00003	- zero / zero
//	31'h7FC00004	- infinity X zero
//	
//	Whenever the fpu encounters a NaN input, the NaN is
//	passed through to the output.
//
//	Ref: Webpack 8.2  Spartan3-4  xc3s1000-4ft256
//	2335 LUTS / 1260 slices / 43.4 MHz
//	Ref: Webpack 13.1 Spartan3e   xc3s1200e-4fg320
//	2433 LUTs / 1301 slices / 51.6 MHz
//	
//	Instr.  Cyc Lat
//	fc__	; 1  0	compare, lt le gt ge eq ne or un
//	fabs	; 1  0 	absolute value
//	fnabs	; 1  0 	negative absolute value
//	fneg	; 1  0 	negate
//	fmov	; 1  0 	move
//	fman	; 1  0 	get mantissa
//	fsign	; 1  0 	get sign
//	
//	f2i		; 1  1  convert float to integer
//	i2f		; 1  1  convert integer to float
//
//	fadd	; 1  4	addition
//	fsub	; 1  4  subtraction
//	fmul	; 1  4  multiplication
//
//	fdiv	; 16 4	division
//	
//	ftx		; 1  0  trigger fp exception
//	fcx		; 1  0  clear fp exception
//	fex		; 1  0  enable fp exception
//	fdx		; 1  0  disable fp exception
//	frm		; 1  0  set rounding mode
//	fstat	; 1  0  get status register
//
//	related integer:
//	graf	; 1  0  get random float (0,1]
//
//	xc6slx45 - Webpack 14.7
//	1915 6-LUTs
//	99.65 MHz
// ============================================================================
//

`define FCXX	2'd2
`define FADD	6'd01
`define FSUB	6'd02
`define FMUL	6'd03
`define FDIV	6'd04
`define FABS	6'd08
`define FNABS	6'd09
`define FNEG	6'd10
`define FMOV	6'd11
`define FSIGN	6'd12
`define FMAN	6'd13
`define I2F		6'd16
`define F2I		6'd17
// 32-47 = FCMP
`define FSTAT	6'd56
`define FMOVI	6'd57
`define FRM		6'd59
`define FTX		6'd60
`define FCX		6'd61
`define FEX		6'd62		// enable exceptions
`define FDX		6'd63		// disable exceptions

`define	QINFO		23'h7FC000		// info
`define	QSUBINF		31'h7FC00001	// - infinity - infinity
`define QINFDIV		31'h7FC00002	// - infinity / infinity
`define QZEROZERO	31'h7FC00003	// - zero / zero
`define QINFZERO	31'h7FC00004	// - infinity X zero


module fpUnit(rst, clk, ce, op, xrm, ld, a, b, o, zl_o, loo_o, loo_done, exception);

parameter WID = 64;
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

input rst;
input clk;
input ce;
input [5:0] op;
input [2:0] xrm;
input ld;
input [MSB:0] a;
input [MSB:0] b;
output tri [MSB:0] o;
output [MSB:0] zl_o;	// zero latency outputs
output [MSB:0] loo_o;
output loo_done;
output exception;


//------------------------------------------------------------
// constants
wire infXp = {EMSB+1{1'b1}};	// value for infinite exponent / nan

// Variables
wire divByZero;			// attempt to divide by zero
wire inf;				// result is infinite (+ or -)
wire zero;				// result is zero (+ or -)
wire ns;		// nan sign
wire nso;
wire isNan;
wire nanx;

// Decode fp operation
wire fstat 	= op==`FSTAT;	// get status
wire fdiv	= op==`FDIV;
wire ftx   	= op==`FTX;		// trigger exception
wire fcx   	= op==`FCX;		// clear exception
wire fex	= op==`FEX;		// enable exception
wire fdx	= op==`FDX;		// disable exception
wire fcxx	= op[5:4]==`FCXX;
wire frm	= op==`FRM;		// set rounding mode
wire fmovi  = op==`FMOVI;

wire subinf;
wire zerozero;
wire infzero;
wire infdiv;

// floating point control and status
reg [2:0] rm;	// rounding mode
reg inexe;		// inexact exception enable
reg dbzxe;		// divide by zero exception enable
reg underxe;	// underflow exception enable
reg overxe;		// overflow exception enable
reg invopxe;	// invalid operation exception enable

reg nsfp;		// non-standard floating point indicator

reg fractie;	// fraction inexact
reg raz;		// rounded away from zero

reg inex;		// inexact exception
reg dbzx;		// divide by zero exception
reg underx;		// underflow exception
reg overx;		// overflow exception
reg giopx;		// global invalid operation exception
reg sx;			// summary exception

reg swtx;		// software triggered exception indicator

wire gx = swtx|inex|dbzx|underx|overx|giopx;	// global exception indicator

// breakdown of invalid operation exceptions
reg cvtx;		// conversion exception
reg sqrtx;		// squareroot exception
reg NaNCmpx;	// NaN comparison exception
reg infzerox;	// multiply infinity by zero
reg zerozerox;	// division of zero by zero
reg infdivx;	// division of infinities
reg subinfx;	// subtraction of infinities
reg snanx;		// signalling nan

wire divDone;
wire pipe_ce = ce & divDone;	// divide must be done in order for pipe to clock

always @(posedge clk)
	// reset: disable and clear all exceptions and status
	if (rst) begin
		rm <= 2'b0;			// round nearest even - default rounding mode
		inex <= 1'b0;
		dbzx <= 1'b0;
		underx <= 1'b0;
		overx <= 1'b0;
		giopx <= 1'b0;
		swtx <= 1'b0;
		sx <= 1'b0;
		NaNCmpx <= 1'b0;

		inexe <= 1'b0;
		dbzxe <= 1'b0;
		underxe <= 1'b0;
		overxe <= 1'b0;
		invopxe <= 1'b0;
		
		nsfp <= 1'b0;

	end
	else if (pipe_ce) begin
		if (ftx) begin
			inex <= inex     | a[4];
			dbzx <= dbzx     | a[3];
			underx <= underx | a[2];
			overx <= overx   | a[1];
			giopx <= giopx   | a[0];
			swtx <= 1'b1;
			sx <= 1'b1;
		end
		else if (fcx) begin
			sx <= sx & !a[5];
			inex <= inex     & !a[4];
			dbzx <= dbzx     & !a[3];
			underx <= underx & !a[2];
			overx <= overx   & !a[1];
			giopx <= giopx	 & !a[0];
			// clear exception type when global invalid operation is cleared
			infdivx <= infdivx & !a[0];
			zerozerox <= zerozerox & !a[0];
			subinfx   <= subinfx   & !a[0];
			infzerox  <= infzerox  & !a[0];
			NaNCmpx   <= NaNCmpx   & !a[0];
			dbzx <= dbzx & !a[0];
			swtx <= 1'b1;
		end
		else if (fex) begin
			inexe <= inexe     | a[4];
			dbzxe <= dbzxe     | a[3];
			underxe <= underxe | a[2];
			overxe <= overxe   | a[1];
			invopxe <= invopxe | a[0];
		end
		else if (fdx) begin
			inexe <= inexe     & !a[4];
			dbzxe <= dbzxe     & !a[3];
			underxe <= underxe & !a[2];
			overxe <= overxe   & !a[1];
			invopxe <= invopxe & !a[0];
		end
		else if (frm)
			rm <= a[2:0];

		infzerox  <= infzerox  | (invopxe & infzero);
		zerozerox <= zerozerox | (invopxe & zerozero);
		subinfx   <= subinfx   | (invopxe & subinf);
		infdivx   <= infdivx   | (invopxe & infdiv);
		dbzx <= dbzx | (dbzxe & divByZero);
		NaNCmpx <= NaNCmpx | (invopxe & nanx & fcxx);	// must be a compare
		sx <= sx |
				(invopxe & nanx & fcxx) |
				(invopxe & (infzero|zerozero|subinf|infdiv)) |
				(dbzxe & divByZero);
	end

// Decompose operands into sign,exponent,mantissa
wire sa, sb;
wire [FMSB:0] ma, mb;

wire aInf, bInf;
wire aNan, bNan;
wire az, bz;
wire [2:0] rmd4;	// 1st stage delayed
wire [5:0] op1, op2;

fpZLUnit  #(WID) u6 (.op(op), .a(a), .b(b), .o(zl_o), .nanx(nanx) );
fpLOOUnit #(WID) u7 (.clk(clk), .ce(pipe_ce), .rm(xrm==3'b111 ? rm : xrm), .op(op), .a(a), .o(loo_o), .done(loo_done) );

fp_decomp #(WID) u1 (.i(a), .sgn(sa), .man(ma), .vz(az), .inf(aInf), .nan(aNan) );
fp_decomp #(WID) u2 (.i(b), .sgn(sb), .man(mb), .vz(bz), .inf(bInf), .nan(bNan) );

delay4 #(3) u3 (.clk(clk), .ce(pipe_ce), .i((xrm==3'b111)?rmd:xrm), .o(rmd4) );
delay1 #(6) u4 (.clk(clk), .ce(pipe_ce), .i(op), .o(op1) );
delay2 #(6) u5 (.clk(clk), .ce(pipe_ce), .i(op), .o(op2) );

delay5 delay5_3(.clk(clk), .ce(pipe_ce), .i(bz & !aNan & fdiv), .o(divByZero) );

// Compute NaN output sign
wire aob_nan = aNan|bNan;	// one of the operands is a nan
wire bothNan = aNan&bNan;	// both of the operands are nans

assign ns = bothNan ?
				(ma==mb ? sa & sb : ma < mb ? sb : sa) :
		 		aNan ? sa : sb;

delay5 u8(.clk(clk), .ce(ce), .i(ns), .o(nso) );
delay5 u9(.clk(clk), .ce(ce), .i(aob_nan), .o(isNan) );

wire [MSB:0] fpu_o;
wire [MSB+4:0] fpn_o;
wire [EX:0] fdiv_o;
wire [EX:0] fmul_o;
wire [EX:0] fas_o;
reg  [EX:0] fres;
wire divUnder;
wire mulUnder;
reg under;

// These units have a two clock cycle latency
fpAddsub u10(.clk(clk), .ce(pipe_ce), .rm(rm), .op(op==`FSUB), .a(a), .b(b), .o(fas_o) );
fpDiv    u11(.rst(rst), .clk(clk), .ce(ce), .ld(ld), .a(a), .b(b), .o(fdiv_o), .sign_exe(), .underflow(divUnder), .done(divDone) );
fpMul    u12(.clk(clk), .ce(pipe_ce),          .a(a), .b(b), .o(fmul_o), .sign_exe(), .inf(), .underflow(mulUnder) );

always @(op2 or mulUnder or divUnder)
	case (op2)
	`FMUL:	under <= mulUnder;
	`FDIV:	under <= divUnder;
	default:	under <= 0;
	endcase

always @(op2,fas_o,fmul_o,fdiv_o)
	case (op2)	// synopsys parallel_case full_case
	`FADD:	fres = fas_o;
	`FSUB:	fres = fas_o;
	`FMUL:	fres = fmul_o;
	`FDIV:	fres = fdiv_o;
	default:	fres = fas_o;
	endcase

// pipeline stage
// one cycle latency
fpNormalize fpn0(.clk(clk), .ce(pipe_ce), .under(under), .i(fres), .o(fpn_o) );

// pipeline stage
// one cycle latency
fpRoundReg fpr0(.clk(clk), .ce(pipe_ce), .rm(rm4), .i(fpn_o), .o(fpu_o) );

wire so = isNan?nso:fpu_o[MSB];

//fix: status should be registered
assign o = fstat ? {
	rm,
	inexe,
	dbzxe,
	underxe,
	overxe,
	invopxe,
	nsfp,

	fractie,
	raz,
	1'b0,
	so & !zero,
	!so & !zero,
	zero,
	inf,

	swtx,
	inex,
	dbzx,
	underx,
	overx,
	giopx,
	gx,
	sx,
	
	cvtx,
	sqrtx,
	NaNCmpx,
	infzerox,
	zerozerox,
	infdivx,
	subinfx,
	snanx
	} : {WID{1'bz}};
assign o = fmovi ? a : {WID{1'bz}};
assign o = !(fstat|fmovi) ? {so,fpu_o[MSB-1:0]} : {WID{1'bz}};
assign zero = fpu_o[MSB-1:0]==0;
assign inf = &fpu_o[MSB-1:FMSB+1] && fpu_o[FMSB:0]==0;
//	NaN Value		Origin
//	31'h7FC00001	- infinity - infinity
//	31'h7FC00002	- infinity / infinity
//	31'h7FC00003	- zero / zero
//	31'h7FC00004	- infinity X zero
assign subinf 	= fpu_o[MSB-1:0]=={{EMSB+1{1'b1}},1'b1,{FMSB-4{1'b0}},4'h1};	//`QSUBINF;
assign infdiv 	= fpu_o[MSB-1:0]=={{EMSB+1{1'b1}},1'b1,{FMSB-4{1'b0}},4'h2};	//`QINFDIV;
assign zerozero = fpu_o[MSB-1:0]=={{EMSB+1{1'b1}},1'b1,{FMSB-4{1'b0}},4'h3};	//`QZEROZERO;
assign infzero 	= fpu_o[MSB-1:0]=={{EMSB+1{1'b1}},1'b1,{FMSB-4{1'b0}},4'h4};	//`QINFZERO;

assign exception = gx;

endmodule

