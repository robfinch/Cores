/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca

	fpUnit.v
		- floating point unit
		- parameterized width
		- IEEE 754 representation

	This source code is free for use and modification for
	non-commercial or evaluation purposes, provided this
	copyright statement and disclaimer remains present in
	the file.

	If the code is modified, please state the origin and
	note that the code has been modified.

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

	This multiplier/divider handles denormalized numbers.
	The output format is of an internal expanded representation
	in preparation to be fed into a normalization unit, then
	rounding. Basically, it's the same as the regular format
	except the mantissa is doubled in size, the leading two
	bits of which are assumed to be whole bits.


	NaN operations
	There are some operations the fpu performs that can
	generate NaN's. The value of the NaN generated and
	the cause are listed below.

	NaN Value		Origin
	31'h7FC00001	- infinity - infinity
	31'h7FC00002	- infinity / infinity
	31'h7FC00003	- zero / zero
	31'h7FC00004	- infinity X zero
	
	Whenever the fpu encounters a NaN input, the NaN is
	passed through to the output.

	Ref: Webpack 8.2  Spartan3-4  xc3s1000-4ft256
	2335 LUTS / 1260 slices / 43.4 MHz
	Ref: Webpack 13.1 Spartan3e   xc3s1200e-4fg320
	2433 LUTs / 1301 slices / 51.6 MHz
	
	Instr.  Cyc Lat
	fc__	; 1  0	compare, lt le gt ge eq ne or un
	fabs	; 1  0 	absolute value
	fnabs	; 1  0 	negative absolute value
	fneg	; 1  0 	negate
	fmov	; 1  0 	move
	fman	; 1  0 	get mantissa
	fsign	; 1  0 	get sign
	
	f2i		; 1  1  convert float to integer
	i2f		; 1  1  convert integer to float

	fadd	; 1  4	addition
	fsub	; 1  4  subtraction
	fmul	; 1  4  multiplication

	fdiv	; 16 4	division
	
	ftx		; 1  0  trigger fp exception
	fcx		; 1  0  clear fp exception
	fex		; 1  0  enable fp exception
	fdx		; 1  0  disable fp exception
	frm		; 1  0  set rounding mode
	fstat	; 1  0  get status register

	related integer:
	graf	; 1  0  get random float (0,1]
	
=============================================================== */

`include "..\Thor_defines.v"

`define	QINFO		23'h7FC000		// info
`define	QSUBINF		31'h7FC00001	// - infinity - infinity
`define QINFDIV		31'h7FC00002	// - infinity / infinity
`define QZEROZERO	31'h7FC00003	// - zero / zero
`define QINFZERO	31'h7FC00004	// - infinity X zero


module fpUnit(rst, clk, ce, op, ld, a, b, o, zl_o, loo_o, loo_done, exception);

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

input rst;
input clk;
input ce;
input [7:0] op;
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
wire fcmp	= op==`FCMP;
wire frm	= op==`FRM;		// set rounding mode

wire subinf;
wire zerozero;
wire infzero;
wire infdiv;

// floating point control and status
reg [1:0] rm;	// rounding mode
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
			inex <= inex     | b[4];
			dbzx <= dbzx     | b[3];
			underx <= underx | b[2];
			overx <= overx   | b[1];
			giopx <= giopx   | b[0];
			swtx <= 1'b1;
			sx <= 1'b1;
		end
		else if (fcx) begin
			sx <= sx & !b[5];
			inex <= inex     & !b[4];
			dbzx <= dbzx     & !b[3];
			underx <= underx & !b[2];
			overx <= overx   & !b[1];
			giopx <= giopx	 & !b[0];
			// clear exception type when global invalid operation is cleared
			infdivx <= infdivx & !b[0];
			zerozerox <= zerozerox & !b[0];
			subinfx   <= subinfx   & !b[0];
			infzerox  <= infzerox  & !b[0];
			NaNCmpx   <= NaNCmpx   & !b[0];
			dbzx <= dbzx & !b[0];
			swtx <= 1'b1;
		end
		else if (fex) begin
			inexe <= inexe     | b[4];
			dbzxe <= dbzxe     | b[3];
			underxe <= underxe | b[2];
			overxe <= overxe   | b[1];
			invopxe <= invopxe | b[0];
		end
		else if (fdx) begin
			inexe <= inexe     & !b[4];
			dbzxe <= dbzxe     & !b[3];
			underxe <= underxe & !b[2];
			overxe <= overxe   & !b[1];
			invopxe <= invopxe & !b[0];
		end
		else if (frm)
			rm <= b[1:0];

		infzerox  <= infzerox  | (invopxe & infzero);
		zerozerox <= zerozerox | (invopxe & zerozero);
		subinfx   <= subinfx   | (invopxe & subinf);
		infdivx   <= infdivx   | (invopxe & infdiv);
		dbzx <= dbzx | (dbzxe & divByZero);
		NaNCmpx <= NaNCmpx | (invopxe & nanx & fcmp);	// must be a compare
		sx <= sx |
				(invopxe & nanx & fcmp) |
				(invopxe & (infzero|zerozero|subinf|infdiv)) |
				(dbzxe & divByZero);
	end

// Decompose operands into sign,exponent,mantissa
wire sa, sb;
wire [FMSB:0] ma, mb;

wire aInf, bInf;
wire aNan, bNan;
wire az, bz;
wire [1:0] rmd4;	// 1st stage delayed
wire [7:0] op1, op2;

fpZLUnit  #(WID) u6 (.op(op), .a(a), .b(b), .o(zl_o), .nanx(nanx) );
fpLOOUnit #(WID) u7 (.clk(clk), .ce(pipe_ce), .rm(rm), .op(op), .a(a), .o(loo_o), .done(loo_done) );

fp_decomp #(WID) u1 (.i(a), .sgn(sa), .man(ma), .vz(az), .inf(aInf), .nan(aNan) );
fp_decomp #(WID) u2 (.i(b), .sgn(sb), .man(mb), .vz(bz), .inf(bInf), .nan(bNan) );

delay4 #(2) u3 (.clk(clk), .ce(pipe_ce), .i(rmd), .o(rmd4) );
delay1 #(8) u4 (.clk(clk), .ce(pipe_ce), .i(op), .o(op1) );
delay2 #(8) u5 (.clk(clk), .ce(pipe_ce), .i(op), .o(op2) );

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
wire [MSB+3:0] fpn_o;
wire [EX:0] fdiv_o;
wire [EX:0] fmul_o;
wire [EX:0] fas_o;
reg  [EX:0] fres;
wire divUnder;
wire mulUnder;
reg under;

// These units have a two clock cycle latency
fpAddsub u10(.clk(clk), .ce(pipe_ce), .rm(rm), .op(op[0]), .a(a), .b(b), .o(fas_o) );
fpDiv    u11(.clk(clk), .ce(pipe_ce), .ld(ld), .a(a), .b(b), .o(fdiv_o), .sign_exe(), .underflow(divUnder), .done(divDone) );
fpMul    u12(.clk(clk), .ce(pipe_ce),          .a(a), .b(b), .o(fmul_o), .sign_exe(), .inf(), .underflow(mulUnder) );

always @(op2)
	case (op2)
	`FMUL:	under = mulUnder;
	`FDIV:	under = divUnder;
	default:	under = 0;
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
	} : 'bz;

assign o = !fstat ? {so,fpu_o[MSB-1:0]} : 'bz;
assign zero = fpu_o[MSB-1:0]==0;
assign inf = &fpu_o[MSB-1:FMSB+1] && fpu_o[FMSB:0]==0;

assign subinf 	= fpu_o[MSB-1:0]==`QSUBINF;
assign infdiv 	= fpu_o[MSB-1:0]==`QINFDIV;
assign zerozero = fpu_o[MSB-1:0]==`QZEROZERO;
assign infzero 	= fpu_o[MSB-1:0]==`QINFZERO;

assign exception = gx;

endmodule

