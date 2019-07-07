// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
//
//	fpUnit.v
//  - floating point unit
//  - parameterized FPWIDth
//  - IEEE 754 representation
//
//	NaN Value		Origin
// 31'h7FC00001    - infinity - infinity
// 31'h7FC00002    - infinity / infinity
// 31'h7FC00003    - zero / zero
// 31'h7FC00004    - infinity X zero
// 31'h7FC00005    - square root of infinity
// 31'h7FC00006		 - square root of negative number
//
// Whenever the fpu encounters a NaN input, the NaN is
// passed through to the output.
//
// Ref: Webpack 8.2  Spartan3-4  xc3s1000-4ft256
// 2335 LUTS / 1260 slices / 43.4 MHz
// Ref: Webpack 13.1 Spartan3e   xc3s1200e-4fg320
// 2433 LUTs / 1301 slices / 51.6 MHz
//
// Instr.  Cyc Lat
// fc__    ; 1  0    compare, lt le gt ge eq ne or un
// fabs    ; 1  0     absolute value
// fnabs    ; 1  0     negative absolute value
// fneg    ; 1  0     negate
// fmov    ; 1  0     move
// fman    ; 1  0     get mantissa
// fsign    ; 1  0     get sign
//
// f2i        ; 1  1  convert float to integer
// i2f        ; 1  1  convert integer to float
//
// fadd    ; 1  5    addition
// fsub    ; 1  5  subtraction
// fmul    ; 1  6  multiplication
//
// fdiv    ; 43 43  division
//
// ftx        ; 1  0  trigger fp exception
// fcx        ; 1  0  clear fp exception
// fex        ; 1  0  enable fp exception
// fdx        ; 1  0  disable fp exception
// frm        ; 1  0  set rounding mode
// fstat    ; 1  0  get status register
//
// related integer:
// graf    ; 1  0  get random float (0,1]
//
// ============================================================================
//
`include "fpConfig.sv"

`define TRUE    1'b1
`define FALSE   1'b0

`define VECTOR  6'h01
`define VFABS       6'h03
`define VFADD       6'h04
`define VFSUB       6'h05
`define VFSxx       6'h06
`define VFNEG       6'h16
`define VFTOI       6'h24
`define VITOF       6'h25
`define VFMUL       6'h3A
`define VFDIV       6'h3E
`define FLOAT   6'h0F
`define FLT1		4'h1
`define FLT2		4'h2
`define FLT3		4'h3
`define FLT1A		4'h5
`define FLT2LI	4'hA
`define FMA			5'h00
`define FMS			5'h01
`define FNMA		5'h02
`define FNMS		5'h03
`define FMOV    5'h00
`define FTOI    5'h02
`define ITOF    5'h03
`define FNEG    5'h04
`define FABS    5'h05
`define FSIGN   5'h06
`define FMAN    5'h07
`define FNABS   5'h08
`define FCVTSD  5'h09
//`define FCVTSQ  6'h1B
`define FSTAT   5'h0C
`define FSQRT		5'h0D
`define FTX     5'h10
`define FCX     5'h11
`define FEX     5'h12
`define FDX     5'h13
`define FRM     5'h14
`define TRUNC		5'h15
`define FCVTDS  5'h19

`define FSCALEB	5'h00
`define FADD    5'h04
`define FSUB    5'h05
`define FCMP    5'h06
`define FMUL    5'h08
`define FDIV    5'h09
`define FREM		5'h0A
`define NXTAFT	5'h0B
// FLT1A
`define FRES		5'h00

`include "fp_defines.v"

module fpUnit(rst, clk, clk4x, ce, ir, ld, a, b, c, imm, o, csr_i, status, exception, done, rm
);
parameter FPWID = 64;
`include "fpSize.sv"
localparam EMSBS = 7;
localparam FMSBS = 22;
localparam FXS = (FMSBS+2)*2-1;	// the MSB of the expanded fraction
localparam EXS = FXS + 1 + EMSBS + 1 + 1 - 1;

input rst;
input clk;
input clk4x;
input ce;
input [39:0] ir;
input ld;
input [MSB:0] a;
input [MSB:0] b;
input [MSB:0] c;
input [5:0] imm;
output tri [MSB:0] o;
input [31:0] csr_i;
output [31:0] status;
output exception;
output done;
input [2:0] rm;

reg [7:0] fpcnt;
wire rem_done;
wire rem_ld;
wire op_done = fpcnt==8'h00;
assign done = op_done & rem_done;

//------------------------------------------------------------
// constants
wire infXpq = {15{1'b1}};
wire infXp = {11{1'b1}};	// value for infinite exponent / nan
wire infXps = {8{1'b1}};

// Variables
wire divByZero;			// attempt to divide by zero
wire inf;				// result is infinite (+ or -)
wire zero;				// result is zero (+ or -)
wire ns;		// nan sign
wire nss;
wire nso;
wire nsos;
wire isNan,isNans;
wire nanx,nanxs;

wire latch_res;
wire [3:0] op4_r;
wire [5:0] func6b_r;
wire [2:0] srca;
wire [2:0] srcb;
wire [2:0] srcc;
wire [3:0] op4_i = ir[9:6];
wire [5:0] op = ir[5:0];
wire [4:0] func6b_i = ir[39:35];
wire fprem = {op4_i,func6b_i} == {`FLT2,`FREM};
wire [3:0] op4 = fprem ? op4_r : op4_i;
wire [5:0] func6b = fprem ? func6b_r : func6b_i;
wire [2:0] insn_rm = ir[30:28];
reg [FPWID-1+`EXTRA_BITS:0] res;
reg [FPWID-1+`EXTRA_BITS:0] aop, bop, cop;
always @*
case(srca)
`RES:	aop <= res;
default:	aop <= a;
endcase
always @*
case(srcb)
`RES:			bop <= res;
`POINT5:
case(FPWID)
32:	bop <= `POINT5S;
40:	bop <= `POINT5SX;
64:	bop <= `POINT5D;
80:	bop <= {`POINT5DX,{`EXTRA_BITS{1'b0}}};
endcase
default:	bop <= b;
endcase
always @*
case(srcc)
`AIN:			cop <= a;
`RES:			cop <= res;
`ZERO:
case(FPWID)
32:	cop <= `ZEROS;
40:	cop <= `ZEROSX;
64:	cop <= `ZEROD;
80:	cop <= {`ZERODX,{`EXTRA_BITS{1'b0}}};
endcase
default:	cop <= c;
endcase

wire [2:0] prec = 3'd4;//ir[25:24];

wire fstat 	= {op4,func6b} == {`FLT1,`FSTAT};	// get status
wire fdiv	= {op4,func6b} == {`FLT2,`FDIV};
wire ftx   	= {op4,func6b} == {`FLT1,`FTX};		// trigger exception
wire fcx   	= {op4,func6b} == {`FLT1,`FCX};		// clear exception
wire fex   	= {op4,func6b} == {`FLT1,`FEX};		// enable exception
wire fdx   	= {op4,func6b} == {`FLT1,`FDX};		// disable exception
wire fcmp	= {op4,func6b} == {`FLT2,`FCMP};
wire frm	= {op4,func6b} == {`FLT1,`FRM};  // set rounding mode

wire zl_op =  (op4==`FLT1 && (
                    (func6b==`FABS || func6b==`FNABS || func6b==`FMOV || func6b==`FNEG || func6b==`FSIGN || func6b==`FMAN)) ||
                    func6b==`FCMP);
wire loo_op = (op4==`FLT1 && (func6b==`ITOF || func6b==`FTOI));
wire loo_done;

wire subinf;
wire zerozero;
wire infzero;
wire infdiv;

// floating point control and status

wire inexe_i    = csr_i[28];
wire dbzxe_i    = csr_i[27];
wire underxe_i  = csr_i[26];
wire overxe_i   = csr_i[25];
wire invopxe_i  = csr_i[24];
wire fractie_i  = csr_i[22];
wire rawayz_i   = csr_i[21];
wire C_i        = csr_i[20];
wire neg_i      = csr_i[19];
wire pos_i      = csr_i[18];
wire zero_i     = csr_i[17];
wire inf_i      = csr_i[16];
wire swt_i      = csr_i[15];
wire inex_i     = csr_i[14];
wire dbzx_i     = csr_i[13];
wire underx_i   = csr_i[12];
wire overx_i    = csr_i[11];
wire giopx_i    = csr_i[10];
wire gx_i       = csr_i[9];
wire sumx_i     = csr_i[8];
wire cvt_i      = csr_i[7];
wire sqrtx_i    = csr_i[6];
wire NaNCmpx_i  = csr_i[5];
wire infzerox_i = csr_i[4];
wire zerozerox_i= csr_i[3];
wire infdivx_i  = csr_i[2];
wire subinfx_i  = csr_i[1];
wire snanx_i    = csr_i[0];
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

wire fdivs = 1'b0;
wire divDone;
wire pipe_ce = ce;// & divDone;	// divide must be done in order for pipe to clock
wire precmatch = 1'b0;//FPWID==32 ? ir[28:27]==2'b00 :
                 //FPWID==64 ? ir[28:27]==2'b01 : 1;
                 /*
                 FPWID==80 ? ir[28:27]==2'b10 :
                 ir[28:27]==2'b11;
                 */
always @(posedge clk)
	// reset: disable and clear all exceptions and status
	if (rst) begin
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

		infzerox  <= 1'b0;
		zerozerox <= 1'b0;
		subinfx   <= 1'b0;
		infdivx   <= 1'b0;

        cvtx <= 1'b0;
        sqrtx <= 1'b0;
        raz <= 1'b0;
        fractie <= 1'b0;
        snanx <= 1'b0;
	end
	else if (pipe_ce) begin
		if (ftx && precmatch) begin
			inex <= (a[4]|imm[4]);
			dbzx <= (a[3]|imm[3]);
			underx <= (a[2]|imm[2]);
			overx <= (a[1]|imm[1]);
			giopx <= (a[0]|imm[0]);
			swtx <= 1'b1;
			sx <= 1'b1;
		end

		infzerox  <= infzero & invopxe_i;
		zerozerox <= zerozero & invopxe_i;
		subinfx   <= subinf & invopxe_i;
		infdivx   <= infdiv & invopxe_i;
		dbzx <= divByZero & dbzxe_i;
		NaNCmpx <= nanx & fcmp & invopxe_i;	// must be a compare
//		sx <= sx |
//				(invopxe & nanx & fcmp) |
//				(invopxe & (infzero|zerozero|subinf|infdiv)) |
//				(dbzxe & divByZero);
	   snanx <= isNan & invopxe_i;
	end

// Decompose operands into sign,exponent,mantissa
wire sa, sb, sas, sbs;
wire [FMSB:0] ma, mb;
wire [22:0] mas, mbs;

wire aInf, bInf, aInfs, bInfs;
wire aNan, bNan, aNans, bNans;
wire az, bz, azs, bzs;
wire [2:0] rmd4;	// 1st stage delayed
wire [3:0] op2;
wire [5:0] op1;
wire [5:0] fn2;

wire [MSB:0] zld_o,lood_o;
wire [31:0] zls_o,loos_o;
wire [FPWID-1+`EXTRA_BITS:0] zlq_o, looq_o;
wire [FPWID-1+`EXTRA_BITS:0] scaleb_o;
fpZLUnit #(FPWID) u6 (.ir(ir), .op4(op4), .func5(func6b), .a(aop), .b(bop), .c(c), .o(zlq_o), .nanx(nanx) );
fpLOOUnit #(FPWID) u7 (.clk(clk), .ce(pipe_ce), .op4(op4), .func5(func6b), .rm(insn_rm==3'b111 ? rm : insn_rm), .a(aop), .b(bop), .o(looq_o), .done() );
fpScaleb u16 (.clk(clk), .ce(pipe_ce), .a(aop), .b(bop), .o(scaleb_o));

//fpLOOUnit #(32) u7s (.clk(clk), .ce(pipe_ce), .rm(rm), .op(op), .fn(fn), .a(a[31:0]), .o(loos_o), .done() );

fpDecomp #(FPWID) u1 (.i(aop), .sgn(sa), .man(ma), .vz(az), .inf(aInf), .nan(aNan) );
fpDecomp #(FPWID) u2 (.i(bop), .sgn(sb), .man(mb), .vz(bz), .inf(bInf), .nan(bNan) );
//fp_decomp #(32) u1s (.i(a[31:0]), .sgn(sas), .man(mas), .vz(azs), .inf(aInfs), .nan(aNans) );
//fp_decomp #(32) u2s (.i(b[31:0]), .sgn(sbs), .man(mbs), .vz(bzs), .inf(bInfs), .nan(bNans) );

wire [2:0] rmd = ir[30:28]==3'b111 ? rm : ir[30:28];
delay4 #(3) u3 (.clk(clk), .ce(pipe_ce), .i(rmd), .o(rmd4) );
delay1 #(6) u4 (.clk(clk), .ce(pipe_ce), .i(func6b), .o(op1) );
delay2 #(4) u5 (.clk(clk), .ce(pipe_ce), .i(op4), .o(op2) );
delay2 #(6) u5b (.clk(clk), .ce(pipe_ce), .i(func6b), .o(fn2) );

delay5 delay5_3(.clk(clk), .ce(pipe_ce), .i((bz & !aNan & fdiv)|(bzs & !aNans & fdivs)), .o(divByZero) );

// Compute NaN output sign
wire aob_nan = aNan|bNan;	// one of the operands is a nan
wire bothNan = aNan&bNan;	// both of the operands are nans
//wire aob_nans = aNans|bNans;	// one of the operands is a nan
//wire bothNans = aNans&bNans;	// both of the operands are nans

assign ns = bothNan ?
				(ma==mb ? sa & sb : ma < mb ? sb : sa) :
		 		aNan ? sa : sb;
//assign nss = bothNans ?
//                                 (mas==mbs ? sas & sbs : mas < mbs ? sbs : sas) :
//                                  aNans ? sas : sbs;

delay5 u8(.clk(clk), .ce(ce), .i(ns), .o(nso) );
delay5 u9(.clk(clk), .ce(ce), .i(aob_nan), .o(isNan) );
//delay5 u8s(.clk(clk), .ce(ce), .i(nss), .o(nsos) );
//delay5 u9s(.clk(clk), .ce(ce), .i(aob_nans), .o(isNans) );

wire [MSB:0] fpu_o;
wire [MSB+3:0] fpn_o;
wire [EX:0] fdiv_o;
wire [EX:0] fmul_o;
wire [EX:0] fas_o;
wire [EX:0] fsqrt_o;
reg  [EX:0] fres;
wire [EX:0] fma_o;
wire [31:0] fpus_o;
wire [31+3:0] fpns_o;
wire [EXS:0] fdivs_o;
wire [EXS:0] fmuls_o;
wire [EXS:0] fass_o;
wire [EXS:0] fres_o;
reg  [EXS:0] fress;
wire divUnder,divUnders;
wire mulUnder,mulUnders;
reg under,unders;
wire sqrneg;
wire fms = func6b==`FMS || func6b==`FNMS;
wire nma = func6b==`FNMA || func6b==`FNMS;
wire [FPWID-1:0] ma_aop = aop ^ (nma << FPWID-1);

fpAddsub #(FPWID) u10(.clk(clk), .ce(pipe_ce), .rm(rmd), .op(func6b[0]), .a(aop), .b(bop), .o(fas_o) );
fpDiv    #(FPWID) u11(.rst(rst), .clk(clk), .clk4x(clk4x), .ce(pipe_ce), .ld(ld|rem_ld), .a(aop), .b(bop), .o(fdiv_o), .sign_exe(), .underflow(divUnder), .done(divDone) );
fpMul    #(FPWID) u12(.clk(clk), .ce(pipe_ce),          .a(aop), .b(bop), .o(fmul_o), .sign_exe(), .inf(), .underflow(mulUnder) );
fpSqrt	 #(FPWID) u13(.rst(rst), .clk(clk4x), .ce(pipe_ce), .ld(ld), .a(aop), .o(fsqrt_o), .done(), .sqrinf(), .sqrneg(sqrneg) );
fpRes    #(FPWID) u14(.clk(clk), .ce(pipe_ce), .a(aop), .o(fres_o));
fpFMA 	 #(FPWID) u15(.clk(clk), .ce(pipe_ce), .op(fms), .rm(rmd), .a(ma_aop), .b(bop), .c(cop), .o(fma_o), .inf());

wire [4:0] rem_state;
fpRemainder ufpr1
(
	.rst(rst),
	.clk(clk),
	.ce(ce),
	.ld_i(ld),
	.ld_o(rem_ld),
	.op4_i(op4_i),
	.funct6b_i(func6b_i),
	.op4_o(op4_r),
	.funct6b_o(func6b_r),
	.op_done(op_done),
	.rem_done(rem_done),
	.srca(srca),
	.srcb(srcb),
	.srcc(srcc),
	.latch_res(latch_res),
	.state(rem_state)
);
/*
fpAddsub #(32) u10s(.clk(clk), .ce(pipe_ce), .rm(rm), .op(op[0]), .a(a[31:0]), .b(b[31:0]), .o(fass_o) );
fpDiv    #(32) u11s(.clk(clk), .ce(pipe_ce), .ld(ld), .a(a[31:0]), .b(b[31:0]), .o(fdivs_o), .sign_exe(), .underflow(divUnders), .done() );
fpMul    #(32) u12s(.clk(clk), .ce(pipe_ce),          .a(a[31:0]), .b(b[31:0]), .o(fmuls_o), .sign_exe(), .inf(), .underflow(mulUnders) );
*/
always @*
case(op2)
`FLT2,`FLT2LI:
  case (fn2)
  `FMUL:	under = mulUnder;
  `FDIV:	under = divUnder;
  default: begin under = 0; unders = 0; end
	endcase
default: begin under = 0; unders = 0; end
endcase

always @*
case(op2)
`FLT3:
	case(fn2)
	`FMA:		fres <= fma_o;
	`FMS:		fres <= fma_o;
	`FNMA:	fres <= fma_o;
	`FNMS:	fres <= fma_o;
	default:	fres <= fma_o;
	endcase
`FLT2,`FLT2LI:
  case(fn2)
  `FADD:	fres <= fas_o;
  `FSUB:	fres <= fas_o;
  `FMUL:	fres <= fmul_o;
  `FDIV:	fres <= fdiv_o;
  `FSCALEB:	fres <= scaleb_o;
  default:	begin fres <= fas_o; fress <= fass_o; end
  endcase
`FLT1:
	case(fn2)
  `FSQRT:	fres <= fsqrt_o;
  default:	begin fres <= 1'd0; fress <= 1'd0; end
  endcase
`FLT1A:
	case(fn2)
	`FRES:	fres <= fres_o;
	default:	begin fres <= 1'd0; fress <= 1'd0; end
	endcase
default:    begin fres <= fas_o; fress <= fass_o; end
endcase

// pipeline stage
// one cycle latency
fpNormalize #(FPWID) fpn0(.clk(clk), .ce(pipe_ce), .under_i(under), .under_o(), .i(fres), .o(fpn_o) );
//fpNormalize #(32) fpns(.clk(clk), .ce(pipe_ce), .under(unders), .i(fress), .o(fpns_o) );

// pipeline stage
// one cycle latency
fpRound #(FPWID) fpr0(.clk(clk), .ce(pipe_ce), .rm(rmd4), .i(fpn_o), .o(fpu_o) );
//fpRoundReg #(32) fprs(.clk(clk), .ce(pipe_ce), .rm(rm4), .i(fpns_o), .o(fpus_o) );

wire so = (isNan?nso:fpu_o[FPWID-1]);
            //single ? (isNans?nsos:fpus_o[31]): (isNan?nso:fpu_o[63]);

//fix: status should be registered
assign status = {
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
	
	1'b0,  	// cvtx
	sqrneg,	// sqrtx
	fcmp & nanx,
	infzero,
	zerozero,
	infdiv,
	subinf,
	isNan
	};

wire [MSB:0] o1 = 
    (frm|fcx|fdx|fex) ? (a|imm) :
    zl_op ? zlq_o :
    loo_op ? looq_o : 
    {so,fpu_o[MSB-1:0]};
assign zero = fpu_o[MSB-1:0]==0;
assign o = fprem ? res : o1;
always @(posedge clk)
if (rst)
	res <= 1'd0;
else begin
	if (ce & latch_res) begin
		res <= o1;
		case(rem_state)
		5'd3:	$display("DIV:   %h %h %h", o1, aop, bop);
		5'd5:	$display("TRUNC: %h %h", o1, aop);
		5'd7: $display("FNMA:  %h %h %h %h", o1, aop, bop, cop);
		
		endcase
	end
end

wire [7:0] maxdivcnt;
generate begin
if (FPWID==128) begin
    assign inf = &fpu_o[126:112] && fpu_o[111:0]==0;
    assign subinf 	= fpu_o[126:0]==`QSUBINFQ;
    assign infdiv 	= fpu_o[126:0]==`QINFDIVQ;
    assign zerozero = fpu_o[126:0]==`QZEROZEROQ;
    assign infzero 	= fpu_o[126:0]==`QINFZEROQ;
    assign maxdivcnt = 8'd128;
end
else if (FPWID==80) begin
    assign inf = &fpu_o[78:64] && fpu_o[63:0]==0;
    assign subinf 	= fpu_o[78:0]==`QSUBINFDX;
    assign infdiv 	= fpu_o[78:0]==`QINFDIVDX;
    assign zerozero = fpu_o[78:0]==`QZEROZERODX;
    assign infzero 	= fpu_o[78:0]==`QINFZERODX;
    assign maxdivcnt = 8'd80;
end
else if (FPWID==64) begin
    assign inf      = &fpu_o[62:52] && fpu_o[51:0]==0;
    assign subinf   = fpu_o[62:0]==`QSUBINFD;
    assign infdiv   = fpu_o[62:0]==`QINFDIVD;
    assign zerozero = fpu_o[62:0]==`QZEROZEROD;
    assign infzero  = fpu_o[62:0]==`QINFZEROD;
    assign maxdivcnt = 8'd64;
end
else if (FPWID==32) begin
    assign inf      = &fpu_o[30:23] && fpu_o[22:0]==0;
    assign subinf   = fpu_o[30:0]==`QSUBINFS;
    assign infdiv   = fpu_o[30:0]==`QINFDIVS;
    assign zerozero = fpu_o[30:0]==`QZEROZEROS;
    assign infzero  = fpu_o[30:0]==`QINFZEROS;
    assign maxdivcnt = 8'd32;
end
end
endgenerate

assign exception = gx;

// Generate a done signal. Latency varys depending on the instruction.
always @(posedge clk)
begin
  if (rst)
    fpcnt <= 8'h00;
  else begin
  if (ld|rem_ld)
    case(op4)
    `FLT3:
    	case(func6b)
    	`FMA:		fpcnt <= 8'd30;
    	`FMS:		fpcnt <= 8'd30;
    	`FNMA:	fpcnt <= 8'd30;
    	`FNMS:	fpcnt <= 8'd30;
    	default:	fpcnt <= 8'd00;
    	endcase
    `FLT2,`FLT2LI: 
      case(func6b)
      `FCMP:  begin fpcnt <= 8'd0; end
      `FADD:  begin fpcnt <= 8'd12; end
      `FSUB:  begin fpcnt <= 8'd12; end
      `FMUL:  begin fpcnt <= 8'd12; end
      `FDIV:  begin fpcnt <= maxdivcnt; end
      `FREM:	fpcnt <= maxdivcnt+8'd23;
      `NXTAFT: fpcnt <= 8'd1;
      `FSCALEB:	fpcnt <= 8'd2;
      default:    fpcnt <= 8'h00;
      endcase
    `FLT1:
      case(func6b)
      `FABS,`FNABS,`FNEG,`FMAN,`FMOV,`FSIGN,
      `FCVTSD,`FCVTDS:  begin fpcnt <= 8'd0; end
      `FTOI:  begin fpcnt <= 8'd1; end
      `ITOF:  begin fpcnt <= 8'd1; end
      `TRUNC:  begin fpcnt <= 8'd1; end
      `FSQRT: begin fpcnt <= maxdivcnt + 8'd8; end
      default:    fpcnt <= 8'h00;
      endcase
    `FLT1A:
    	case(func6b)
    	`FRES:	fpcnt <= 8'h03;
    	default:	fpcnt <= 8'h00;
    	endcase
    default:    fpcnt <= 8'h00;
    endcase
  else if (!op_done) begin
  	if ((op4==`FLT2||op4==`FLT2LI) && func6b==`FDIV && divDone)
  		fpcnt <= 8'h12;
  	else
    	fpcnt <= fpcnt - 1;
   end
  end
end
endmodule

