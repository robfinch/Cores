// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2018  Robert Finch, Waterloo
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
//  - parameterized width
//  - IEEE 754 representation
//
//	NaN Value		Origin
// 31'h7FC00001    - infinity - infinity
// 31'h7FC00002    - infinity / infinity
// 31'h7FC00003    - zero / zero
// 31'h7FC00004    - infinity X zero
// 31'h7FC00005    - square root of infinity
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
`define FMOV    6'h10
`define FTOI    6'h12
`define ITOF    6'h13
`define FNEG    6'h14
`define FABS    6'h15
`define FSIGN   6'h16
`define FMAN    6'h17
`define FNABS   6'h18
`define FCVTSD  6'h19
`define FCVTSQ  6'h1B
`define FSTAT   6'h1C
`define FSQRT	6'h1D
`define FTX     6'h20
`define FCX     6'h21
`define FEX     6'h22
`define FDX     6'h23
`define FRM     6'h24
`define FCVTDS  6'h29

`define FADD    6'h04
`define FSUB    6'h05
`define FCMP    6'h06
`define FMUL    6'h08
`define FDIV    6'h09

`include "fp_defines.v"

module fpUnit(rst, clk, clk4x, ce, ir, ld, a, b, imm, o, csr_i, status, exception, done, rm
);

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
localparam EMSBS = 7;
localparam FMSBS = 22;
localparam FX = (FMSB+2)*2-1;	// the MSB of the expanded fraction
localparam EX = FX + 1 + EMSB + 1 + 1 - 1;
localparam FXS = (FMSBS+2)*2-1;	// the MSB of the expanded fraction
localparam EXS = FXS + 1 + EMSBS + 1 + 1 - 1;

input rst;
input clk;
input clk4x;
input ce;
input [31:0] ir;
input ld;
input [MSB:0] a;
input [MSB:0] b;
input [5:0] imm;
output tri [MSB:0] o;
input [31:0] csr_i;
output [31:0] status;
output exception;
output done;
input [2:0] rm;

reg [7:0] fpcnt;
assign done = fpcnt==8'h00;

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

// Decode fp operation
wire [5:0] op = ir[5:0];
wire [5:0] func6b = ir[31:26];
wire [2:0] prec = 3'd4;//ir[25:24];

wire fstat 	= {op,func6b} == {`FLOAT,`FSTAT};	// get status
wire fdiv	= {op,func6b} == {`FLOAT,`FDIV};
wire ftx   	= {op,func6b} == {`FLOAT,`FTX};		// trigger exception
wire fcx   	= {op,func6b} == {`FLOAT,`FCX};		// clear exception
wire fex   	= {op,func6b} == {`FLOAT,`FEX};		// enable exception
wire fdx   	= {op,func6b} == {`FLOAT,`FDX};		// disable exception
wire fcmp	= {op,func6b} == {`FLOAT,`FCMP};
wire frm	= {op,func6b} == {`FLOAT,`FRM};  // set rounding mode

wire zl_op =  (op==`FLOAT && (
                    (func6b==`FABS || func6b==`FNABS || func6b==`FMOV || func6b==`FNEG || func6b==`FSIGN || func6b==`FMAN || func6b==`FCVTSQ)) ||
                    func6b==`FCMP);
wire loo_op = (op==`FLOAT && (func6b==`ITOF || func6b==`FTOI));
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

wire divDone;
wire pipe_ce = ce;// & divDone;	// divide must be done in order for pipe to clock
wire precmatch = 1'b0;//WID==32 ? ir[28:27]==2'b00 :
                 //WID==64 ? ir[28:27]==2'b01 : 1;
                 /*
                 WID==80 ? ir[28:27]==2'b10 :
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
wire [5:0] op1, op2;
wire [5:0] fn2;

wire [MSB:0] zld_o,lood_o;
wire [31:0] zls_o,loos_o;
wire [WID-1:0] zlq_o, looq_o;
fpZLUnit #(WID) u6 (.ir(ir), .a(a), .b(b), .o(zlq_o), .nanx(nanx) );
fpLOOUnit #(WID) u7 (.clk(clk), .ce(pipe_ce), .ir(ir), .a(a), .o(looq_o), .done() );
//fpLOOUnit #(32) u7s (.clk(clk), .ce(pipe_ce), .rm(rm), .op(op), .fn(fn), .a(a[31:0]), .o(loos_o), .done() );

fp_decomp #(WID) u1 (.i(a), .sgn(sa), .man(ma), .vz(az), .inf(aInf), .nan(aNan) );
fp_decomp #(WID) u2 (.i(b), .sgn(sb), .man(mb), .vz(bz), .inf(bInf), .nan(bNan) );
//fp_decomp #(32) u1s (.i(a[31:0]), .sgn(sas), .man(mas), .vz(azs), .inf(aInfs), .nan(aNans) );
//fp_decomp #(32) u2s (.i(b[31:0]), .sgn(sbs), .man(mbs), .vz(bzs), .inf(bInfs), .nan(bNans) );

wire [2:0] rmd = ir[26:24]==3'b111 ? rm : ir[26:24];
delay4 #(3) u3 (.clk(clk), .ce(pipe_ce), .i(rmd), .o(rmd4) );
delay1 #(6) u4 (.clk(clk), .ce(pipe_ce), .i(func6b), .o(op1) );
delay2 #(6) u5 (.clk(clk), .ce(pipe_ce), .i(func6b), .o(op2) );
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
wire [31:0] fpus_o;
wire [31+3:0] fpns_o;
wire [EXS:0] fdivs_o;
wire [EXS:0] fmuls_o;
wire [EXS:0] fass_o;
reg  [EXS:0] fress;
wire divUnder,divUnders;
wire mulUnder,mulUnders;
reg under,unders;
wire sqrneg;

fpAddsub #(WID) u10(.clk(clk), .ce(pipe_ce), .rm(rmd), .op(func6b[0]), .a(a), .b(b), .o(fas_o) );
fpDiv    #(WID) u11(.clk(clk), .clk4x(clk4x), .ce(pipe_ce), .ld(ld), .a(a), .b(b), .o(fdiv_o), .sign_exe(), .underflow(divUnder), .done(divDone) );
fpMul    #(WID) u12(.clk(clk), .ce(pipe_ce),          .a(a), .b(b), .o(fmul_o), .sign_exe(), .inf(), .underflow(mulUnder) );
fpSqrt	 #(WID) u13(.rst(rst), .clk(clk4x), .ce(pipe_ce), .ld(ld), .a(a), .o(fsqrt_o), .done(), .sqrinf(), .sqrneg(sqrneg) );
/*
fpAddsub #(32) u10s(.clk(clk), .ce(pipe_ce), .rm(rm), .op(op[0]), .a(a[31:0]), .b(b[31:0]), .o(fass_o) );
fpDiv    #(32) u11s(.clk(clk), .ce(pipe_ce), .ld(ld), .a(a[31:0]), .b(b[31:0]), .o(fdivs_o), .sign_exe(), .underflow(divUnders), .done() );
fpMul    #(32) u12s(.clk(clk), .ce(pipe_ce),          .a(a[31:0]), .b(b[31:0]), .o(fmuls_o), .sign_exe(), .inf(), .underflow(mulUnders) );
*/
always @*
case(op2)
`FLOAT:
    case (fn2)
    `FMUL:	under = mulUnder;
    `FDIV:	under = divUnder;
    default: begin under = 0; unders = 0; end
	endcase
`VECTOR:
    case (fn2)
    `VFMUL:    under = mulUnder;
    `VFDIV:    under = divUnder;
    default: begin under = 0; unders = 0; end
    endcase
default: begin under = 0; unders = 0; end
endcase

always @*
case(op2)
`FLOAT:
    case(fn2)
    `FADD:	fres <= fas_o;
    `FSUB:	fres <= fas_o;
    `FMUL:	fres <= fmul_o;
    `FDIV:	fres <= fdiv_o;
    `FSQRT:	fres <= fsqrt_o;
    default:	begin fres <= fas_o; fress <= fass_o; end
    endcase
`VECTOR:
    case(fn2)
    `VFADD:   fres <= fas_o;
    `VFSUB:   fres <= fas_o;
    `VFMUL:   fres <= fmul_o;
    `VFDIV:   fres <= fdiv_o;
    default:    begin fres <= fas_o; fress <= fass_o; end
    endcase
default:    begin fres <= fas_o; fress <= fass_o; end
endcase

// pipeline stage
// one cycle latency
fpNormalize #(WID) fpn0(.clk(clk), .ce(pipe_ce), .under(under), .i(fres), .o(fpn_o) );
//fpNormalize #(32) fpns(.clk(clk), .ce(pipe_ce), .under(unders), .i(fress), .o(fpns_o) );

// pipeline stage
// one cycle latency
fpRoundReg #(WID) fpr0(.clk(clk), .ce(pipe_ce), .rm(rmd4), .i(fpn_o), .o(fpu_o) );
//fpRoundReg #(32) fprs(.clk(clk), .ce(pipe_ce), .rm(rm4), .i(fpns_o), .o(fpus_o) );

wire so = (isNan?nso:fpu_o[WID-1]);
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

assign o = (!fstat) ?
    (frm|fcx|fdx|fex) ? (a|imm) :
    zl_op ? zlq_o :
    loo_op ? looq_o : 
    {so,fpu_o[MSB-1:0]} : 'bz;
assign zero = fpu_o[MSB-1:0]==0;

wire [7:0] maxdivcnt;
generate begin
if (WID==128) begin
    assign inf = &fpu_o[126:112] && fpu_o[111:0]==0;
    assign subinf 	= fpu_o[126:0]==`QSUBINFQ;
    assign infdiv 	= fpu_o[126:0]==`QINFDIVQ;
    assign zerozero = fpu_o[126:0]==`QZEROZEROQ;
    assign infzero 	= fpu_o[126:0]==`QINFZEROQ;
    assign maxdivcnt = 8'd64;
end
else if (WID==80) begin
    assign inf = &fpu_o[78:64] && fpu_o[63:0]==0;
    assign subinf 	= fpu_o[78:0]==`QSUBINFDX;
    assign infdiv 	= fpu_o[78:0]==`QINFDIVDX;
    assign zerozero = fpu_o[78:0]==`QZEROZERODX;
    assign infzero 	= fpu_o[78:0]==`QINFZERODX;
    assign maxdivcnt = 8'd40;
end
else if (WID==64) begin
    assign inf      = &fpu_o[62:52] && fpu_o[51:0]==0;
    assign subinf   = fpu_o[62:0]==`QSUBINFD;
    assign infdiv   = fpu_o[62:0]==`QINFDIVD;
    assign zerozero = fpu_o[62:0]==`QZEROZEROD;
    assign infzero  = fpu_o[62:0]==`QINFZEROD;
    assign maxdivcnt = 8'd32;
end
else if (WID==32) begin
    assign inf      = &fpu_o[30:23] && fpu_o[22:0]==0;
    assign subinf   = fpu_o[30:0]==`QSUBINFS;
    assign infdiv   = fpu_o[30:0]==`QINFDIVS;
    assign zerozero = fpu_o[30:0]==`QZEROZEROS;
    assign infzero  = fpu_o[30:0]==`QINFZEROS;
    assign maxdivcnt = 8'd16;
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
    if (ld)
        case(ir[5:0])
        `FLOAT: 
            case(func6b)
            `FABS,`FNABS,`FNEG,`FMAN,`FMOV,`FSIGN,
            `FCVTSD,`FCVTSQ,`FCVTDS:  begin fpcnt <= 8'd0; end
            `FTOI:  begin fpcnt <= 8'd1; end
            `ITOF:  begin fpcnt <= 8'd1; end
            `FCMP:  begin fpcnt <= 8'd0; end
            `FADD:  begin fpcnt <= 8'd6; end
            `FSUB:  begin fpcnt <= 8'd6; end
            `FMUL:  begin fpcnt <= 8'd6; end
            `FDIV:  begin fpcnt <= maxdivcnt; end
            `FSQRT: begin fpcnt <= maxdivcnt; end
            default:    fpcnt <= 8'h00;
            endcase
        `VECTOR:
            case(func6b)
            `VFNEG:  begin fpcnt <= 8'd0; end
            `VFADD:  begin fpcnt <= 8'd6; end
            `VFSUB:  begin fpcnt <= 8'd6; end
            `VFSxx:  begin fpcnt <= 8'd0; end
            `VFMUL:  begin fpcnt <= 8'd6; end
            `VFDIV:  begin fpcnt <= maxdivcnt; end
            `VFTOI:  begin fpcnt <= 8'd1; end
            `VITOF:  begin fpcnt <= 8'd1; end
            default:    fpcnt <= 8'h00;
            endcase
        default:    fpcnt <= 8'h00;
        endcase
    else if (!done)
        fpcnt <= fpcnt - 1;
    end
end
endmodule

