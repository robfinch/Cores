// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
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
`include "..\inc\Gambit-types.sv"
`include "fpConfig.sv"
`include "fpTypes.sv"

`define TRUE    1'b1
`define FALSE   1'b0

`define FLT1		7'h6E
`define FMOV    5'h00
`define FTOI    5'h02
`define ITOF    5'h03
`define FNEG    5'h04
`define FABS    5'h05
`define FSIGN   5'h06
`define FMAN    5'h07
`define FNABS   5'h08
//`define FCVTSQ  6'h1B
`define FSTAT   5'h0C
`define FSQRT		5'h0D
`define FTX     5'h10
`define FCX     5'h11
`define FEX     5'h12
`define FDX     5'h13
`define FRM     5'h14
`define TRUNC		5'h15

`define FADD    7'h4F
`define FSUB    7'h5F
`define FCMP    7'h7E
`define FMUL    7'h6F
`define FDIV    7'h7F

`include "fpDefines.v"

module fpUnit(big, rst, clk, clk2x, clk4x, ce, pc, ir, ld, a, b, imm, o, csr_i, status, exception, done, rm
);
parameter FPWID = `FPWID;
`include "fpSize.sv"
localparam EMSBS = 7;
localparam FMSBS = 22;
localparam FXS = (FMSBS+2)*2-1;	// the MSB of the expanded fraction
localparam EXS = FXS + 1 + EMSBS + 1 + 1 - 1;

input big;
input rst;
input clk;
input clk4x;
input clk2x;
input ce;
input Address pc;
input Instruction ir;
input ld;
input Float a;
input Float b;
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
wire op_done;
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
wire [7:0] opcode_i = ir[7:0];
wire [5:0] op = ir[5:0];
wire [4:0] func6b_i = ir[27:23];
wire [7:0] opcode = opcode_i;
wire [4:0] func6b = func6b_i;
wire [2:0] insn_rm = ir[30:28];
reg [FPWID-1:0] res;
reg [FPWID-1:0] aop, bop, cop;

// Results cache
reg [4:0] f51 [0:63];
Address pcs1 [0:63];
Float as1 [0:63];
Float rs1 [0:63];
// Results cache
reg [6:0] op72 [0:63];
Address pcs2 [0:63];
Float as2 [0:63];
Float bs2 [0:63];
Float rs2 [0:63];

wire [2:0] prec = 3'd4;//ir[25:24];

wire fstat 	= {ir.gen.opcode,ir.flt1.func5} == {`FLT1,`FSTAT};	// get status
wire fdiv	= 	{ir.gen.opcode} == `FDIV;
wire ftx   	= {ir.gen.opcode,ir.flt1.func5} == {`FLT1,`FTX};		// trigger exception
wire fcx   	= {ir.gen.opcode,ir.flt1.func5} == {`FLT1,`FCX};		// clear exception
wire fex   	= {ir.gen.opcode,ir.flt1.func5} == {`FLT1,`FEX};		// enable exception
wire fdx   	= {ir.gen.opcode,ir.flt1.func5} == {`FLT1,`FDX};		// disable exception
wire fcmp	= {ir.gen.opcode} == `FCMP;
wire frm	= {ir.gen.opcode,ir.flt1.func5} == {`FLT1,`FRM};  // set rounding mode

wire zl_op =  	 ir.gen.opcode==`FCMP
							|| ir.gen.opcode==`FSEQ
							|| ir.gen.opcode==`FSNE
							|| ir.gen.opcode==`FSLT
							|| ir.gen.opcode==`FSLE
						  || (ir.gen.opcode==`FLT1 && (
                    (ir.flt1.func5==`FABS || ir.flt1.func5==`FNABS || ir.flt1.func5==`FMOV
                     || ir.flt1.func5==`FNEG || ir.flt1.func5==`FSIGN || ir.flt1.func5==`FMAN)));
wire loo_op = (ir.gen.opcode==`FLT1 && (ir.flt1.func5==`ITOF || ir.flt1.func5==`FTOI || ir.flt1.func5==`TRUNC));
wire frsqrte_op = ir.gen.opcode==`FLT1 && ir.flt1.func5==`FRSQRTE;
wire fres_op = ir.gen.opcode==`FLT1 && ir.flt1.func5==`FRES;
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
wire [2:0] rmd6;
wire [7:0] op2;
wire [5:0] op1;
wire [5:0] fn2;
Instruction ir2;

wire [MSB:0] zld_o,lood_o;
wire [31:0] zls_o,loos_o;
wire [FPWID-1:0] zlq_o, looq_o;
wire [FPWID-1:0] scaleb_o;
fpZLUnit #(FPWID) u6 (.ir(ir), .a(a), .b(b), .o(zlq_o), .nanx(nanx) );
fpLOOUnit #(FPWID) u7 (.clk(clk), .ce(pipe_ce), .ir(ir), .rm(ir.flt1.rm==3'b111 ? rm : ir.flt1.rm), .a(a), .b(b), .o(looq_o), .done() );

//fpLOOUnit #(32) u7s (.clk(clk), .ce(pipe_ce), .rm(rm), .op(op), .fn(fn), .a(a[31:0]), .o(loos_o), .done() );

fpDecomp #(FPWID) u1 (.i(aop), .sgn(sa), .man(ma), .vz(az), .inf(aInf), .nan(aNan) );
fpDecomp #(FPWID) u2 (.i(bop), .sgn(sb), .man(mb), .vz(bz), .inf(bInf), .nan(bNan) );
//fp_decomp #(32) u1s (.i(a[31:0]), .sgn(sas), .man(mas), .vz(azs), .inf(aInfs), .nan(aNans) );
//fp_decomp #(32) u2s (.i(b[31:0]), .sgn(sbs), .man(mbs), .vz(bzs), .inf(bInfs), .nan(bNans) );

wire [2:0] rmd = ir.flt2.rm==3'b111 ? rm : ir.flt2.rm;
reg [3:0] rmdDelay;
always @*
case(ir.gen.opcode)
`FADD,`FSUB:	rmdDelay = 4'd4;
`FMUL:				rmdDelay = 4'd4;
`FDIV:				rmdDelay = 4'd15;
`FLT1:
	case(ir.flt1.func5)
	`FSQRT:			rmdDelay = 4'd15;
	default:		rmdDelay = 4'd4;
	endcase
endcase
vtdl #(.WID(3)) u3 (.clk(clk), .ce(pipe_ce), .a(rmdDelay), .d(rmd), .q(rmd6) );
delay1 #(6) u4 (.clk(clk), .ce(pipe_ce), .i(func6b), .o(op1) );
delay2 #(8) u5 (.clk(clk), .ce(pipe_ce), .i(opcode), .o(op2) );
delay2 #(6) u5b (.clk(clk), .ce(pipe_ce), .i(func6b), .o(fn2) );
delay2 #(52) u5c (.clk(clk), .ce(pipe_ce), .i(ir), .o(ir2) );
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
wire [MSB:0] frsqrte_o;
wire divUnder,divUnders;
wire mulUnder,mulUnders;
reg under,unders;
wire sqrneg;
wire frsqrte_done;
wire fres_done;

fpAddsub #(FPWID) u10(.clk(clk), .ce(pipe_ce), .rm(rmd), .op(ir.flt2.opcode[0]), .a(a), .b(b), .o(fas_o) );
fpDiv    #(FPWID) u11(.rst(rst), .clk(clk), .clk4x(clk4x), .ce(pipe_ce), .ld(ld|rem_ld), .a(a), .b(b), .o(fdiv_o), .sign_exe(), .underflow(divUnder), .done(divDone) );
fpMul    #(FPWID) u12(.clk(clk), .ce(pipe_ce), .a(a), .b(b), .o(fmul_o), .sign_exe(), .inf(), .underflow(mulUnder) );
fpSqrt	 #(FPWID) u13(.rst(rst), .clk(clk4x), .ce(pipe_ce), .ld(ld), .a(a), .o(fsqrt_o), .done(), .sqrinf(), .sqrneg(sqrneg) );
//fpRes    #(FPWID) u14(.clk(clk), .ce(pipe_ce), .a(aop), .o(fres_o));
//fpFMA 	 #(FPWID) u15(.clk(clk), .ce(pipe_ce), .op(fms), .rm(rmd), .a(ma_aop), .b(bop), .c(cop), .o(fma_o), .inf());
fpRes    #(FPWID) u14(.clk(clk), .ce(pipe_ce), .a(a), .o(fres_o));
fpRsqrte	ursqrte1 (.clk(clk), .ce(pipe_ce), .ld(ld), .a(a), .o(frsqrte_o));

wire f5done = pc==pcs1[pc[5:0]] && a==as1[pc[5:0]] && f51[pc[5:0]]==ir.flt1.func5;
wire o7done = pc==pcs2[pc[5:0]] && a==as2[pc[5:0]] && b==bs2[pc[5:0]] && op72[pc[5:0]]==ir.gen.opcode;
assign op_done = (fpcnt==8'h00) || f5done || o7done;

/*
fpAddsub #(32) u10s(.clk(clk), .ce(pipe_ce), .rm(rm), .op(op[0]), .a(a[31:0]), .b(b[31:0]), .o(fass_o) );
fpDiv    #(32) u11s(.clk(clk), .ce(pipe_ce), .ld(ld), .a(a[31:0]), .b(b[31:0]), .o(fdivs_o), .sign_exe(), .underflow(divUnders), .done() );
fpMul    #(32) u12s(.clk(clk), .ce(pipe_ce),          .a(a[31:0]), .b(b[31:0]), .o(fmuls_o), .sign_exe(), .inf(), .underflow(mulUnders) );
*/
always @*
case(ir2.gen.opcode)
`FMUL:	under = mulUnder;
`FDIV:	under = big ? divUnder : 0;
default: begin under = 0; unders = 0; end
endcase

always @*
case(ir2.gen.opcode)
`FADD:	fres <= fas_o;
`FSUB:	fres <= fas_o;
`FMUL:	fres <= fmul_o;
`FDIV:	fres <= big ? fdiv_o : 1'd0;
`FLT1:
	case(ir2.flt1.opcode)
  `FSQRT:	fres <= big ? fsqrt_o : 1'd0;
  default:	begin fres <= 1'd0; fress <= 1'd0; end
  endcase
default:    begin fres <= fas_o; fress <= fass_o; end
endcase

// pipeline stage
// eight cycle latency (double clocked)
fpNormalize #(FPWID) fpn0(.clk(clk), .ce(pipe_ce), .under_i(under), .under_o(), .i(fres), .o(fpn_o) );
//fpNormalize #(32) fpns(.clk(clk), .ce(pipe_ce), .under(unders), .i(fress), .o(fpns_o) );

// pipeline stage
// three cycle latency (double clocked)
fpRound #(FPWID) fpr0(.clk(clk), .ce(pipe_ce), .rm(rmd6), .i(fpn_o), .o(fpu_o) );
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
	big & sqrneg,	// sqrtx
	fcmp & nanx,
	infzero,
	zerozero,
	infdiv,
	subinf,
	isNan
	};

wire Float o1 = 
    (frm|fcx|fdx|fex) ? (a|imm) :
    zl_op ? zlq_o :
    big & loo_op ? looq_o : 
    f5done ? rs1[pc[5:0]] :		// cached result
    o7done ? rs2[pc[5:0]] :		// cached result
    fres_op ? fres_o :
    frsqrte_op ? frsqrte_o :	// recirpocal square root estimate doesn't go through norm and round.
    {so,fpu_o[MSB-1:0]};
assign zero = fpu_o[MSB-1:0]==0;
assign o = o1;

// update results cache
reg [7:0] pfpcnt;
always @(posedge clk)
if (rst)
	pfpcnt <= 8'h00;
else begin
	pfpcnt <= fpcnt;
	if (fpcnt==8'h00 && pfpcnt==8'h01 && ir.gen.opcode==`FLT1) begin
		f51[pc[5:0]] <= ir.flt1.func5;
		pcs1[pc[5:0]] <= pc;
		as1[pc[5:0]] <= a;
		rs1[pc[5:0]] <= o1;
	end
end
always @(posedge clk)
begin
	if (fpcnt==8'h00 && pfpcnt==8'h01 && ir.gen.opcode!=`FLT1) begin
		op72[pc[5:0]] <= ir.gen.opcode;
		pcs2[pc[5:0]] <= pc;
		as2[pc[5:0]] <= a;
		bs2[pc[5:0]] <= b;
		rs2[pc[5:0]] <= o1;
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
else if (FPWID==52) begin
    assign inf      = &fpu_o[50:40] && fpu_o[39:0]==0;
    assign subinf   = fpu_o[50:0]==`QSUBINF52;
    assign infdiv   = fpu_o[50:0]==`QINFDIV52;
    assign zerozero = fpu_o[50:0]==`QZEROZERO52;
    assign infzero  = fpu_o[50:0]==`QINFZERO52;
    assign maxdivcnt = 8'd52;
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
    case(ir.gen.opcode)
    `FCMP:  begin fpcnt <= 8'd0; end
    `FADD:  begin fpcnt <= 8'd6; end
    `FSUB:  begin fpcnt <= 8'd6; end
    `FMUL:  begin fpcnt <= 8'd7; end
    `FDIV:  begin fpcnt <= maxdivcnt; end
    `FLT1:
      case(ir.flt1.func5)
      `FABS,`FNABS,`FNEG,`FMAN,`FMOV,`FSIGN,
      `FTOI:  begin fpcnt <= 8'd3; end
      `ITOF:  begin fpcnt <= 8'd3; end
      `TRUNC:  begin fpcnt <= 8'd1; end
      `FSQRT: begin fpcnt <= maxdivcnt + 8'd8; end
      `FRSQRTE:	fpcnt <= 8'd4;
      `FRES:		fpcnt <= 8'd4;
      default:    fpcnt <= 8'h00;
      endcase
    default:    fpcnt <= 8'h00;
    endcase
  else if (!op_done) begin
  	if (big && ir.flt2.opcode==`FDIV && divDone)
  		fpcnt <= 8'h12;
  	else
    	fpcnt <= fpcnt - 1;
   end
  end
end
endmodule

