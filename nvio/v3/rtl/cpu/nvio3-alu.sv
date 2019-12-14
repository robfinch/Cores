// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// 59000
//
`include "nvio3-defines.sv"
`include "nvio3-config.sv"

module alu(rst, clk, ld, abort, instr, fmt, store, a, b, c, t, m, z, vl, pc, Ra, tgt, tgt2,
    csr, o, ob, done, idle, excen, exc, thrd, ptrmask, state, mem, shift,
    ol, dl, cro
`ifdef SUPPORT_BBMS 
    , pb, cbl, cbu, ro, dbl, dbu, sbl, sbu, en
`endif
    );

parameter DBW = 256;
parameter ABW = 128;
parameter BIG = 1'b1;
parameter SUP_VECTOR = 1;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter PTR = 20'hFFF01;
parameter BASE_SHIFT = 14'd0;
parameter SIMD = 1;
input rst;
input clk;
input ld;
input abort;
input [39:0] instr;
input [3:0] fmt;
input store;
input [DBW-1:0] a;
input [DBW-1:0] b;
input [DBW-1:0] c;
input [DBW-1:0] t;			// target register value
input [31:0] m;					// mask register value
input z;								// 1=zero output, 0=merge
input [7:0] vl;
input [31:0] pc;
input [5:0] Ra;
input [5:0] tgt;
input [5:0] tgt2;
input [127:0] csr;
output reg [255:0] o;
output reg [255:0] ob;
output reg done;
output reg idle;
input [4:0] excen;
output reg [7:0] exc;
input thrd;
input [127:0] ptrmask;
input [1:0] state;
input mem;
input shift;
input [1:0] ol;
input [1:0] dl;
output reg [7:0] cro;
`ifdef SUPPORT_BBMS
input [63:0] pb;
input [63:0] cbl;
input [63:0] cbu;
input [63:0] ro;
input [63:0] dbl;
input [63:0] dbu;
input [63:0] sbl;
input [63:0] sbu;
input [63:0] en;
`endif

parameter byt = 4'd0;
parameter wyde = 4'd1;
parameter tetra = 4'd2;
parameter octa = 4'd3;
parameter hexi = 4'd4;
parameter fmt256 = 4'd5;
parameter byte_para = 4'd8;
parameter wyde_para = 4'd9;
parameter tetra_para = 4'd10;
parameter octa_para = 4'd11;
parameter hexi_para = 4'd12;

integer n, x, y;
genvar g, h;

reg adrDone, adrIdle;
reg [63:0] usa;			// unsegmented address
`ifndef SUPPORT_BBMS
reg [63:0] pb = 64'h0;
`endif
reg [DBW-1:0] addro;
reg [DBW-1:0] adr;			// load / store address
reg [DBW-1:0] shift8;
reg [DBW-1:0] o1;

wire [7:0] a8 = a[7:0];
wire [15:0] a16 = a[15:0];
wire [31:0] a32 = a[31:0];
wire [7:0] b8 = b[7:0];
wire [15:0] b16 = b[15:0];
wire [31:0] b32 = b[31:0];
wire [DBW-1:0] orb = b;
wire [DBW-1:0] andb = b;
wire [DBW-1:0] bsx20 = {{60{b[19]}},b[19:0]};

wire [21:0] qimm = instr[39:18];
wire [DBW-1:0] imm = {{58{instr[39]}},instr[39:35],instr[32:16]};
wire [DBW-1:0] divq, rem;
wire divByZero;
wire [15:0] prod80, prod81, prod82, prod83, prod84, prod85, prod86, prod87;
wire [31:0] prod160, prod161, prod162, prod163;
wire [63:0] prod320, prod321;
wire [511:0] prod8;
wire [511:0] prod16;
wire [511:0] prod32;
wire [511:0] prod64;
wire [511:0] prod128;
wire [255:0] prodx8, prodx16, prodx32, prodx64, prodx128;
wire [DBW*2-1:0] prod;
wire [31:0] mult_done8, mult_idle8, div_done8, div_idle8;
wire [15:0] mult_done16, mult_idle16, div_done16, div_idle16;
wire [7:0] mult_done32, mult_idle32, div_done32, div_idle32;
wire [3:0] mult_done64, mult_idle64, div_done64, div_idle64;
wire [1:0] mult_done128, mult_idle128, div_done128, div_idle128;

wire mult_done, mult_idle, div_done, div_idle;
wire aslo;
wire [6:0] clzo128,cloo128,cpopo128;
wire [DBW-1:0] shfto128,shfto64,shfto32,shfto16,shfto8;
wire [DBW-1:0] shftho;
reg [DBW-1:0] shift9;
reg [255:0] bx;
reg [31:0] mx;
reg [31:0] zx;

function fnArgB;
input [3:0] fmt;
input [255:0] B;
case(fmt)
byte_para:	fnArgB <= {32{B[7:0]}};
wyde_para:	fnArgB <= {16{B[15:0]}};
tetra_para:	fnArgB <= {8{B[31:0]}};
octa_para:	fnArgB <= {4{B[63:0]}};
hexi_para:	fnArgB <= {2{B[127:0]}};
default:		fnArgB <= B;
endcase
endfunction

always @*
	bx <= fnArgB(fmt,b);

function IsMul;
input [39:0] isn;
casez(isn[`OPCODE])
`R2,`R2S:
  case(isn[`FUNCT6])
  `MULU,`MUL: IsMul = TRUE;
  `MULUH,`MULH: IsMul = TRUE;
  `FXMUL: IsMul = TRUE;
  default:    IsMul = FALSE;
  endcase
`MULUI,`MULI,`MULSUI:  IsMul = TRUE;
default:    IsMul = FALSE;
endcase
endfunction

function IsDivmod;
input [39:0] isn;
casez(isn[`OPCODE])
`R2,`R2S:
  case(isn[`FUNCT6])
  `DIVU,`DIV: IsDivmod = TRUE;
  `MODU,`MOD: IsDivmod = TRUE;
  default:    IsDivmod = FALSE;
  endcase
`DIVUI,`DIVI,`DIVSUI:  IsDivmod = TRUE;
default:    IsDivmod = FALSE;
endcase
endfunction

function IsSgn;
input [39:0] isn;
casez(isn[`OPCODE])
`R2,`R2S:
  case(isn[`FUNCT6])
  `MUL,`DIV,`MOD,`MULH:   IsSgn = TRUE;
  `FXMUL: IsSgn = TRUE;
  default:    IsSgn = FALSE;
  endcase
`MULI,`DIVI,`MODI:    IsSgn = TRUE;
default:    IsSgn = FALSE;
endcase
endfunction

function IsSgnus;
input [39:0] isn;
IsSgnus = FALSE;
endfunction

function IsShiftAndOp;
input [39:0] isn;
IsShiftAndOp = FALSE;
endfunction

wire [DBW-1:0] bfout,shfto;
wire [DBW-1:0] shftob;
wire [DBW-1:0] shftwo;
reg [DBW-1:0] shift10;

always @(posedge clk)
	shift9 <= shift8;
always @*
	shift10 <= shift9;
//case (instr[34:33])
//`ADD:	shift10 <= shift9 + c;
//`SUB:	shift10 <= shift9 - c;
//`AND:	shift10 <= shift9 & c;
//`OR:	shift10 <= shift9 | c;
//`XOR:	shift10 <= shift9 ^ c;
//6'h20:	shift10 <= ~shift9;		// COM
//6'h21:	shift10 <= !shift9;		// NOT
//default:	shift10 <= shift9;
//endcase

bitfield #(DBW) ubf1
(
    .inst(instr),
    .a(a),
    .b(b),
    .c(c),
    .o(bfout),
    .masko()
);

generate begin : mult128s
for (g = 0; g < 2; g = g + 1)
if (SIMD || g < 1) begin
multiplier #(128) umult128
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr)&& (fmt==hexi || fmt==hexi_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[(g+1)*128-1:g*128]),
	.b(bx[(g+1)*128-1:g*128]),
	.o(prod[(g+1)*256-1:g * 256]),
	.done(mult_done128[g]),
	.idle(mult_idle128[g])
);
assign prodx128[(g+1)*128-1:g*128] = prod128[g*256+127:g * 256];
end
end
endgenerate

generate begin : mult64s
for (g = 0; g < 4; g = g + 1)
if (SIMD || g < 1) begin
multiplier #(64) umult64
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr)&& (fmt==octa || fmt==octa_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[(g+1)*64-1:g*64]),
	.b(bx[(g+1)*64-1:g*64]),
	.o(prod64[(g+1)*128-1:g * 128]),
	.done(mult_done64[g]),
	.idle(mult_idle64[g])
);
assign prodx64[(g+1)*64-1:g*64] = prod64[g*128+63:g * 128];
end
end
endgenerate

generate begin : mult32s
for (g = 0; g < 8; g = g + 1)
if (SIMD || g < 1) begin
multiplier #(32) umult32
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (fmt==tetra || fmt==tetra_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[(g+1)*32-1:g*32]),
	.b(bx[(g+1)*32-1:g*32]),
	.o(prod32[(g+1)*64-1:g * 64]),
	.done(mult_done32[g]),
	.idle(mult_idle32[g])
);
assign prodx32[(g+1)*32-1:g*32] = prod32[g*64+31:g * 64];
end
end
endgenerate

generate begin : mult16s
for (g = 0; g < 16; g = g + 1)
if (SIMD || g < 1) begin
multiplier #(16) umult16
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (fmt==wyde || fmt==wyde_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[(g+1)*16-1:g*16]),
	.b(bx[(g+1)*16-1:g*16]),
	.o(prod16[(g+1)*32-1:g * 32]),
	.done(mult_done16[g]),
	.idle(mult_idle16[g])
);
assign prodx16[(g+1)*16-1:g*16] = prod16[g*32+15:g * 32];
end
end
endgenerate

generate begin : mult8s
for (g = 0; g < 32; g = g + 1)
if (SIMD || g < 1) begin
multiplier #(8) umult16
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (fmt==byt || fmt==byte_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[(g+1)*8-1:g*8]),
	.b(bx[(g+1)*8-1:g*8]),
	.o(prod8[(g+1)*16-1:g * 16]),
	.done(mult_done8[g]),
	.idle(mult_idle8[g])
);
assign prodx8[(g+1)*8-1:g*8] = prod8[g*16+7:g * 16];
end
end
endgenerate

divider #(DBW) udiv1
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsDivmod(instr) && (fmt==hexi || fmt==hexi_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a),
	.b(bx),
	.qo(divq),
	.ro(rem),
	.dvByZr(divByZero),
	.done(div_done),
	.idle(div_idle)
);

reg [6:0] bshift;
always @*
case (instr[`OPCODE])
`R2,`R2S:
	case(instr[`FUNCT6])
	`SHL,`ASL,`SHR,`ASR,`ROL,`ROR:
		bshift <= bx[6:0];
	default:
		bshift <= {instr[35:34],instr[22:18]};
	endcase
default:
	bshift <= 7'd0;
endcase

generate begin : ushft128s
for (g = 0; g < 2; g = g + 1)
shift128 ushft1
(
  .instr(instr),
  .a(a[(g+1)*128-1:g * 128]),
  .b(bshift),
  .res(shfto128),
  .ov()
);
end
endgenerate

generate begin : ushft64s
for (g = 0; g < 4; g = g + 1)
shift64 ushft1
(
  .instr(instr),
  .a(a[(g+1)*64-1:g * 64]),
  .b(bshift),
  .res(shfto64[(g+1)*64-1:g*64]),
  .ov()
);
end
endgenerate

generate begin : ushft32s
for (g = 0; g < 8; g = g + 1)
shift32 ushft1
(
  .instr(instr),
  .a(a[(g+1)*32-1:g * 32]),
  .b(bshift),
  .res(shfto32[(g+1)*32-1:g*32]),
  .ov()
);
end
endgenerate

generate begin : ushft16s
for (g = 0; g < 16; g = g + 1)
shift16 ushft1
(
  .instr(instr),
  .a(a[(g+1)*16-1:g * 16]),
  .b(bshift),
  .res(shfto16[(g+1)*16-1:g*16]),
  .ov()
);
end
endgenerate

generate begin : ushft8s
for (g = 0; g < 32; g = g + 1)
shift8 ushft1
(
  .instr(instr),
  .a(a[(g+1)*8-1:g * 8]),
  .b(bshift),
  .res(shfto8[(g+1)*8-1:g*8]),
  .ov()
);
end
endgenerate


cntlz128 uclz1
(
	.i(fmt[2:0]==byt   ? {120'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,a[7:0]} :
	   fmt[2:0]==wyde  ? {112'hFFFFFFFFFFFFFFFFFFFFFFFFFFFF,a[15:0]} :
	   fmt[2:0]==tetra ? { 96'hFFFFFFFFFFFFFFFFFFFFFFFF,a[31:0]} :
	   fmt[2:0]==octa  ? { 64'hFFFFFFFFFFFFFFFF,a[63:0]} : a),
	.o(clzo128)
);

cntlo128 uclo1
(
	.i(fmt==2'd0 ? a[7:0] : fmt==2'd1 ? a[15:0] : fmt==2'd2 ? a[31:0] : a),
	.o(cloo128)
);

cntpop128 ucpop1
(
	.i(fmt==2'd0 ? a[7:0] : fmt==2'd1 ? a[15:0] : fmt==2'd2 ? a[31:0] : a),
	.o(cpopo128)
);

wire [7:0] bcdaddo,bcdsubo;
wire [15:0] bcdmulo;
BCDAdd ubcd1 (1'b0,a,b,bcdaddo);
BCDSub ubcd2 (1'b0,a,b,bcdsubo);
BCDMul2 ubcd3 (a,b,bcdmulo);

wire [7:0] s8 = a[7:0] + b[7:0];
wire [15:0] s16 = a[15:0] + b[15:0];
wire [31:0] s32 = a[31:0] + b[31:0];
wire [7:0] d8 = a[7:0] - b[7:0];
wire [15:0] d16 = a[15:0] - b[15:0];
wire [31:0] d32 = a[31:0] - b[31:0];
wire [DBW-1:0] redor64 = {63'd0,|a};
wire [DBW-1:0] redor32 = {31'd0,|a[63:32],31'd0,|a[31:0]};
wire [DBW-1:0] redor16 = {15'd0,|a[63:48],15'd0,|a[47:32],15'd0,|a[31:16],15'd0,|a[15:0]};
wire [DBW-1:0] redor8 = {7'b0,|a[63:56],6'b0,|a[55:48],7'd0,|a[47:40],7'd0,|a[39:32],7'd0,
													 |a[31:24],7'd0,|a[23:16],7'd0,|a[15:8],7'd0,|a[7:0]};
wire [DBW-1:0] redand64 = {63'd0,&a};
wire [DBW-1:0] redand32 = {31'd0,&a[63:32],31'd0,&a[31:0]};
wire [DBW-1:0] redand16 = {15'd0,&a[63:48],15'd0,&a[47:32],15'd0,&a[31:16],15'd0,&a[15:0]};
wire [DBW-1:0] redand8 = {7'b0,&a[63:56],6'b0,&a[55:48],7'd0,&a[47:40],7'd0,&a[39:32],7'd0,
													 &a[31:24],7'd0,&a[23:16],7'd0,&a[15:8],7'd0,&a[7:0]};
wire [DBW-1:0] zxb10 = {54'd0,b[9:0]};
wire [DBW-1:0] sxb10 = {{54{b[9]}},b[9:0]};
wire [DBW-1:0] zxb26 = {58'd0,instr[39:32],instr[30:16]};
wire [DBW-1:0] sxb26 = {{58{instr[39]}},instr[39:32],instr[30:16]};
reg [15:0] mask;
wire [4:0] cpopom;
wire signed [DBW-1:0] as = a;
wire signed [DBW-1:0] bs = bx;
wire signed [DBW-1:0] cs = c;

wire [DBW-1:0] bmmo;
BMM ubmm1
(
	.op(1'b0),
	.a(a),
	.b(bx),
	.o(bmmo)
);

wire [9:0] bmatch;
wire [4:0] wmatch;

generate begin : bmtch
for (g = 0; g < 10; g = g + 1)
assign bmatch[g] = a[g*8+7:g*8] == b[7:0];
end
endgenerate

generate begin : wmtch
for (g = 0; g < 5; g = g + 1)
assign wmatch[g] = a[g*16+15:g*16] == b[15:0];
end
endgenerate

reg [79:0] bndxo,wndxo;

always @*
begin
	bndxo = 80'hFFFFFFFFFFFFFFFFFFFF;
	for (n = 9; n >= 0; n = n - 1)
		if (bmatch[n])
			bndxo = n;
end

always @*
begin
	wndxo = 80'hFFFFFFFFFFFFFFFFFFFF;
	for (n = 4; n >= 0; n = n - 1)
		if (wmatch[n])
			wndxo = n;
end

always @*
begin
casez(instr[`OPCODE])
`R1:
	case(instr[`FUNCT6])
	`ABS:			tskAbs(fmt,mx,zx,a,t,o);
	`CMPRSS:	tskCmprss(fmt,o);
	`V2BITS:	tskV2bits(fmt,mx,zx,a,t,o);

	`CNTLZ:     o = BIG ? {57'd0,clzo128} : 64'hCCCCCCCCCCCCCCCC;
	`CNTLO:     o = BIG ? {57'd0,cloo128} : 64'hCCCCCCCCCCCCCCCC;
	`CNTPOP:    o = BIG ? {57'd0,cpopo128} : 64'hCCCCCCCCCCCCCCCC;
	`NOT:   tskNot(fmt,mx,zx,a,t,o);
	`NEG:		tskNeg(fmt,mx,zx,a,t,o);
  `MOV:		o = a;
	`PTR:		case (instr[25:23])
					3'd0:	o = a==64'hFFF0100000000000 || a==64'h0;
					3'd1:	o = a[63:44]==20'hFFF01;
					3'd2:	o = a[63:44]==20'hFFF02;
					default:	o = 64'hDEADDEADDEADDEAD;
					endcase
	`ZXO:		o = {t[`HEXI1],64'd0,a[63:0]};
	`ZXP:		o = {t[`HEXI1],88'd0,a[39:0]};
	`ZXT:		o = {t[`HEXI1],96'd0,a[31:0]};
	`ZXC:		o = {t[`HEXI1],112'd0,a[15:0]};
	`ZXB:		o = {t[`HEXI1],120'd0,a[7:0]};
	`SXO:		o = {t[`HEXI1],{64{a[63]}},a[63:0]};
	`SXP:		o = {t[`HEXI1],{88{a[39]}},a[39:0]};
	`SXT:		o = {t[`HEXI1],{96{a[31]}},a[31:0]};
	`SXC:		o = {t[`HEXI1],{112{a[15]}},a[15:0]};
	`SXB:		o = {t[`HEXI1],{120{a[7]}},a[7:0]};
//	        5'h1C:		o[63:0] = tmem[a[9:0]];
	default:    o = {t[`HEXI1],128'hDEADDEADDEADDEADDEADDEADDEADDEAD};
	endcase

`R2,`R2S:
	casez(instr[`FUNCT6])
  `ADD:		tskAdd(fmt,mx,zx,a,bx,t,o);
  `SUB:		tskSub(fmt,mx,zx,a,bx,t,o);
  `CMP:		tskCmp(fmt,a,bx,t,o);
  `CMPU:	tskCmpu(fmt,a,bx,t,o);
  `AND:   tskAnd(fmt,mx,zx,a,bx,t,o);
  `BIT:   tskBit(fmt,a,bx,t,o);
  `OR:    tskOr(fmt,mx,zx,a,bx,t,o);
  `XOR:   tskXor(fmt,mx,zx,a,bx,t,o);
  `NAND:  tskNand(fmt,mx,zx,a,bx,t,o);
  `NOR:   tskNor(fmt,mx,zx,a,bx,t,o);
  `XNOR:  tskXnor(fmt,mx,zx,a,bx,t,o);
  `MUL,`MULU:
  				tskMul(fmt,mx,zx,t,o);
	`SEQ:		tskSeq(fmt,a,bx,o);
	`SNE:		tskSne(fmt,a,bx,o);
  `SLT:   tskSlt(fmt,a,bx,o);
  `SLTU:  tskSltu(fmt,a,bx,o);
  `SLE:   tskSle(fmt,a,bx,o);
  `SLEU:  tskSleu(fmt,a,bx,o);
  `SHLI,`ASLI,`SHRI,`ASRI,`ROLI,`RORI,
  `SHL,`ASL,`SHR,`ASR,`ROL,`ROR:
  				tskShift(fmt,mx,zx,t,o);
  `BMM:		o = BIG ? bmmo : {64{4'hC}};
  `BYTNDX:	o = bndxo;
  `WYDNDX:	o = wndxo;
  `MIN:	 	tskMin(fmt,mx,zx,a,bx,t,o);
  `MAX: 	tskMax(fmt,mx,zx,a,bx,t,o);
  default:	o = {64{4'hC}};
	endcase
`R3:
	    casez({instr[`FUNCT5],instr[6]})
	    `BCD:
	        case(instr[`INSTRUCTION_S1])
	        `BCDADD:    o = BIG ? bcdaddo :  64'hCCCCCCCCCCCCCCCC;
	        `BCDSUB:    o = BIG ? bcdsubo :  64'hCCCCCCCCCCCCCCCC;
	        `BCDMUL:    o = BIG ? bcdmulo :  64'hCCCCCCCCCCCCCCCC;
	        default:    o = 64'hDEADDEADDEADDEAD;
	        endcase
			`DIF:
				begin
					o1 = a - b;
					o = o1[DBW-1] ? -o1 : o1;
				end
	    `SEI:   o = a | instr[21:16];
	    `BMISC: o = a | instr[21:16];
	    `MUX:       for (n = 0; n < DBW; n = n + 1)
	                    o[n] = a[n] ? b[n] : c[n];
			`FXMUL:
				case(fmt)
				tetra_para:	o = {prod32[47:16] + prod32[15],prod32[47:16] + prod32[15]};
				default:		o = prod64[95:32] + prod64[31];
				endcase
			`MULF:	o = a[23:0] * b[15:0];
	    `DIVU:   o = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
	    `DIV:    o = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
	    `MODU:   o = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
	    `MOD:    o = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
	    `AVG:
	    	begin
	    		o1 = a + b + 2'd1;
	    		o = o1[79] ? {1'b1,o1[79:1]} : {1'b0,o1[79:1]};
	    	end
	    `MAJ:		o = (a & b) | (a & c) | (b & c);
	    // PTRDIF does an arithmetic shift right.
	    `PTRDIF:	
	    	begin
	    		if (BIG) begin
		    		o1 = a[43:0] - bx[43:0];
		    		o = o1[43] ? (o1 >> instr[25:23]) | ~(64'hFFFFFFFFFFFFFFFF >> instr[25:23])
		    							: (o1 >> instr[25:23]);
	    		end
	    		else
	    			o = 64'hDEADDEADDEADDEAD;
	    	end
	    default:    o = 64'hDEADDEADDEADDEAD;
	    endcase
`ADDI:	o = {t[`HEXI1],a[`HEXI0] + b[`HEXI0]};
`DIFI:
	begin
		o1 = a - b;
		o = o1[DBW-1] ? -o1 : o1;
	end
`ANDI:	o = {t[`HEXI1],a[`HEXI0] & b[`HEXI0]};
`ORI:		o = {t[`HEXI1],a[`HEXI0] | b[`HEXI0]};
`XORI:	o = {t[`HEXI1],a[`HEXI0] ^ b[`HEXI0]};
`BITI:	o = {t[`HEXI1],a[`HEXI0] & b[`HEXI0]};
`MULUI:	o = prod[DBW-1:0];
`MULI:	o = prod[DBW-1:0];
`MULFI:	begin
					o1 = a[23:0] * b[15:0];
					o = {t[`HEXI1],o1[`HEXI0]};
				end
`DIVUI:		o = divq;
`MODUI:		o = rem;
`DIVI:		o = divq;
`MODI:		o = rem;
`CSRRW:     
	case(instr[27:16])
	12'h044:	o = BIG ? (csr | {39'd0,1'b0,24'h0}) : 64'hDDDDDDDDDDDDDDDD;
	default:	o = BIG ? csr : 64'hDDDDDDDDDDDDDDDD;
	endcase
`BITFIELD:  o = BIG ? bfout : 64'hCCCCCCCCCCCCCCCC;
`BYTNDXI:	o = bndxo;
`WYDNDXI:	o = wndxo;
default:    o = 64'hDEADDEADDEADDEAD;
endcase  
end

always @*
begin
	cro = 8'h00;
	case(instr[7:0])
	`CMPI,`CMPUI:
		cro = o;
	`R2:
		case(instr[`FUNCT6])
		`CMP,`CMPU:	cro = o;
		default:
			begin		
			cro[0] = o[`HEXI0]==128'd0;
			cro[1] = o[127];
			cro[4] = o[0];
			end
		endcase
	default:
		begin		
		cro[0] = o[`HEXI0]==128'd0;
		cro[1] = o[127];
		cro[4] = o[0];
		end
	endcase
end

always @(posedge clk)
if (rst)
	adrDone <= TRUE;
else begin
	if (ld)
		adrDone <= FALSE;
	else if (mem|shift)
		adrDone <= TRUE;
end

always @(posedge clk)
if (rst)
	adrIdle <= TRUE;
else begin
	if (ld)
		adrIdle <= FALSE;
	else if (mem|shift)
		adrIdle <= TRUE;
end

always @(posedge clk)
casez(instr[`OPCODE])
`R1:
	case(instr[`FUNCT6])
	`COM:	addro = ~shift8;
	`NOT:	addro = ~|shift8;
	`NEG:	addro = -shift8;
	default:	addro = 64'hDCDCDCDCDCDCDCDC;
	endcase
`R2,`R2S:
	case(instr[`FUNCT6])
	`AND,`OR,`XOR,`NAND,`NOR,`XNOR,
	`SHL,`ASL,`SHR,`ASR,`ROL,`ROR:
		addro = shift8;
	default:	addro[63:0] = 64'hDCDCDCDCDCDCDCDC;
	endcase
default:	addro = 64'hCCCCCCCCCCCCCCCE;
endcase

reg sao_done, sao_idle;
always @(posedge clk)
if (rst) begin
	sao_done <= 1'b1;
	sao_idle <= 1'b1;
end
else begin
if (ld & IsShiftAndOp(instr) & BIG) begin
	sao_done <= 1'b0;
	sao_idle <= 1'b0;
end
else begin
	if (IsShiftAndOp(instr) & BIG) begin
		sao_done <= 1'b1;
		sao_idle <= 1'b1;
	end
end
end

// Generate done signal
always @*
if (rst)
	done <= TRUE;
else begin
	if (IsMul(instr)) begin
		case(fmt)
		byt,byte_para:	done <= mult_done8[0];
		wyde,wyde_para:	done <= mult_done16[0];
		tetra,tetra_para:	done <= mult_done32[0];
		default:	done <= mult_done;
		endcase
	end
	else if (IsDivmod(instr) & BIG)
		done <= div_done;
	else if (IsShiftAndOp(instr) & BIG)
		done <= sao_done;
	else if (shift)
		done <= adrDone;
	else
		done <= TRUE;
end

// Generate idle signal
always @*
if (rst)
	idle <= TRUE;
else begin
	if (IsMul(instr)) begin
		case(fmt)
		byt,byte_para:	idle <= mult_idle8[0];
		wyde,wyde_para:	idle <= mult_idle16[0];
		tetra,tetra_para:	idle <= mult_idle32[0];
		default:	idle <= mult_idle;
		endcase
	end
	else if (IsDivmod(instr) & BIG)
		idle <= div_idle;
	else if (IsShiftAndOp(instr) & BIG)
		idle <= sao_idle;
	else if (shift)
		idle <= adrIdle;
	else
		idle <= TRUE;
end

function fnOverflow;
input op;   // 0 = add, 1=sub
input a;
input b;
input s;
fnOverflow = (op ^ s ^ b) & (~op ^ a ^ b);
endfunction

always @*
begin
//if ((tgt[4:0]==5'd31 || tgt[4:0]==5'd30) && (o[ABW-1:0] < {sbl[50:13],13'd0} || o[ABW-1:0] > {pl[50:0],13'h1FFF}))
//    exc <= `FLT_STK;
//else
exc <= `FLT_NONE;
casez(instr[`OPCODE])
`R3:
    case(instr[`FUNCT6])
    `ADD:   exc <= (fnOverflow(0,a[79],b[79],o[79]) & excen[0] & instr[24]) ? `FLT_OFL : `FLT_NONE;
    `SUB:   exc <= (fnOverflow(1,a[79],b[79],o[79]) & excen[1] & instr[24]) ? `FLT_OFL : `FLT_NONE;
//    `ASL,`ASLI:     exc <= (BIG & aslo & excen[2]) ? `FLT_OFL : `FLT_NONE;
    `MUL:    exc <= prod[63] ? (prod[159:80] != 64'hFFFFFFFFFFFFFFFF && excen[3] ? `FLT_OFL : `FLT_NONE ):
                           (prod[127:64] != 64'd0 && excen[3] ? `FLT_OFL : `FLT_NONE);
    `FXMUL:     exc <= prod[95] ? (prod[127:96] != 32'hFFFFFFFF && excen[3] ? `FLT_OFL : `FLT_NONE ):
                           (prod[127:96] != 32'd0 && excen[3] ? `FLT_OFL : `FLT_NONE);
    `MULU:      exc <= prod[127:64] != 64'd0 && excen[3] ? `FLT_OFL : `FLT_NONE;
    `DIV,`DIVU: exc <= BIG && excen[4] & divByZero ? `FLT_DBZ : `FLT_NONE;
    `MOD,`MODU: exc <= BIG && excen[4] & divByZero ? `FLT_DBZ : `FLT_NONE;
    default:    exc <= `FLT_NONE;
    endcase
`MULI:    exc <= prod[63] ? (prod[127:64] != 64'hFFFFFFFFFFFFFFFF & excen[3] ? `FLT_OFL : `FLT_NONE):
                                    (prod[127:64] != 64'd0 & excen[3] ? `FLT_OFL : `FLT_NONE);
`DIVI: exc <= BIG & excen[4] & divByZero & instr[27] ? `FLT_DBZ : `FLT_NONE;
`MODI: exc <= BIG & excen[4] & divByZero & instr[27] ? `FLT_DBZ : `FLT_NONE;
`CSRRW:	exc <= (instr[27:21]==7'b0011011) ? `FLT_SEG : `FLT_NONE;
default:    exc <= `FLT_NONE;
endcase
end

reg [DBW:0] aa, bb;

always @(posedge clk)
begin
	aa <= shfto;
	bb <= c;
end

always @*
begin
	for (n = 0; n < 32; n = n + 1)
		mx[n] = m[n] && vl > n;
end

always @*
begin
	for (n = 0; n < 32; n = n + 1)
		zx[n] = z && vl > n;
end

task tskPtrdif;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	if (BIG) begin
		o1 = a[95:0] - bx[95:0];
		o = o1[95] ? (o1 >> {instr[23],instr[35:34]}) | ~(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >> {instr[23],instr[35:34]})
							: (o1 >> {instr[23],instr[35:34]});
	end
	else
		o = {t[`HEXI1],128'hDEADDEADDEADDEADDEADDEADDEADDEAD};
end
endtask

task tskMul;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] t;
output [DBW:0] o;
begin
  	case(fmt)
  	byt:	o = {t[`HEXI1],{120{prod8[7]}},prod8[7:0]};
  	wyde:	o = {t[`HEXI1],{112{prod16[15]}},prod16[15:0]};
  	tetra:	o = {t[`HEXI1],{96{prod32[31]}},prod32[31:0]};
  	octa:	o = {t[`HEXI1],{64{prod64[63]}},prod64[63:0]};
  	hexi:	o = {t[`HEXI1],prod128[127:0]};
  	byte_para:
  		begin
  		o[`BYTE0] = mx[0] ? prodx8[`BYTE0] : zx[0] ? 8'd0 : t[`BYTE0];
  		o[`BYTE1] = mx[1] ? prodx8[`BYTE1] : zx[1] ? 8'd0 : t[`BYTE1];
  		o[`BYTE2] = mx[2] ? prodx8[`BYTE2] : zx[2] ? 8'd0 : t[`BYTE2];
  		o[`BYTE3] = mx[3] ? prodx8[`BYTE3] : zx[3] ? 8'd0 : t[`BYTE3];
  		o[`BYTE4] = mx[4] ? prodx8[`BYTE4] : zx[4] ? 8'd0 : t[`BYTE4];
  		o[`BYTE5] = mx[5] ? prodx8[`BYTE5] : zx[5] ? 8'd0 : t[`BYTE5];
  		o[`BYTE6] = mx[6] ? prodx8[`BYTE6] : zx[6] ? 8'd0 : t[`BYTE6];
  		o[`BYTE7] = mx[7] ? prodx8[`BYTE7] : zx[7] ? 8'd0 : t[`BYTE7];
  		o[`BYTE8] = mx[8] ? prodx8[`BYTE8] : zx[8] ? 8'd0 : t[`BYTE8];
  		o[`BYTE9] = mx[9] ? prodx8[`BYTE9] : zx[9] ? 8'd0 : t[`BYTE9];
  		o[`BYTE10] = mx[10] ? prodx8[`BYTE10] : zx[10] ? 8'd0 : t[`BYTE10];
  		o[`BYTE11] = mx[11] ? prodx8[`BYTE11] : zx[11] ? 8'd0 : t[`BYTE11];
  		o[`BYTE12] = mx[12] ? prodx8[`BYTE12] : zx[12] ? 8'd0 : t[`BYTE12];
  		o[`BYTE13] = mx[13] ? prodx8[`BYTE13] : zx[13] ? 8'd0 : t[`BYTE13];
  		o[`BYTE14] = mx[14] ? prodx8[`BYTE14] : zx[14] ? 8'd0 : t[`BYTE14];
  		o[`BYTE15] = mx[15] ? prodx8[`BYTE15] : zx[15] ? 8'd0 : t[`BYTE15];
  		o[`BYTE16] = mx[16] ? prodx8[`BYTE16] : zx[16] ? 8'd0 : t[`BYTE16];
  		o[`BYTE17] = mx[17] ? prodx8[`BYTE17] : zx[17] ? 8'd0 : t[`BYTE17];
  		o[`BYTE18] = mx[18] ? prodx8[`BYTE18] : zx[18] ? 8'd0 : t[`BYTE18];
  		o[`BYTE19] = mx[19] ? prodx8[`BYTE19] : zx[19] ? 8'd0 : t[`BYTE19];
  		o[`BYTE20] = mx[20] ? prodx8[`BYTE20] : zx[20] ? 8'd0 : t[`BYTE20];
  		o[`BYTE21] = mx[21] ? prodx8[`BYTE21] : zx[21] ? 8'd0 : t[`BYTE21];
  		o[`BYTE22] = mx[22] ? prodx8[`BYTE22] : zx[22] ? 8'd0 : t[`BYTE22];
  		o[`BYTE23] = mx[23] ? prodx8[`BYTE23] : zx[23] ? 8'd0 : t[`BYTE23];
  		o[`BYTE24] = mx[24] ? prodx8[`BYTE24] : zx[24] ? 8'd0 : t[`BYTE24];
  		o[`BYTE25] = mx[25] ? prodx8[`BYTE25] : zx[25] ? 8'd0 : t[`BYTE25];
  		o[`BYTE26] = mx[26] ? prodx8[`BYTE26] : zx[26] ? 8'd0 : t[`BYTE26];
  		o[`BYTE27] = mx[27] ? prodx8[`BYTE27] : zx[27] ? 8'd0 : t[`BYTE27];
  		o[`BYTE28] = mx[28] ? prodx8[`BYTE28] : zx[28] ? 8'd0 : t[`BYTE28];
  		o[`BYTE29] = mx[29] ? prodx8[`BYTE29] : zx[29] ? 8'd0 : t[`BYTE29];
  		o[`BYTE30] = mx[30] ? prodx8[`BYTE30] : zx[30] ? 8'd0 : t[`BYTE30];
  		o[`BYTE31] = mx[31] ? prodx8[`BYTE31] : zx[31] ? 8'd0 : t[`BYTE31];
  		end
  	wyde_para:
  		begin
  		o[`WYDE0] = mx[0] ? prodx16[`WYDE0] : zx[0] ? 16'd0 : t[`WYDE0];
  		o[`WYDE1] = mx[1] ? prodx16[`WYDE1] : zx[1] ? 16'd0 : t[`WYDE1];
  		o[`WYDE2] = mx[2] ? prodx16[`WYDE2] : zx[2] ? 16'd0 : t[`WYDE2];
  		o[`WYDE3] = mx[3] ? prodx16[`WYDE3] : zx[3] ? 16'd0 : t[`WYDE3];
  		o[`WYDE4] = mx[4] ? prodx16[`WYDE4] : zx[4] ? 16'd0 : t[`WYDE4];
  		o[`WYDE5] = mx[5] ? prodx16[`WYDE5] : zx[5] ? 16'd0 : t[`WYDE5];
  		o[`WYDE6] = mx[6] ? prodx16[`WYDE6] : zx[6] ? 16'd0 : t[`WYDE6];
  		o[`WYDE7] = mx[7] ? prodx16[`WYDE7] : zx[7] ? 16'd0 : t[`WYDE7];
  		o[`WYDE8] = mx[8] ? prodx16[`WYDE8] : zx[8] ? 16'd0 : t[`WYDE8];
  		o[`WYDE9] = mx[9] ? prodx16[`WYDE9] : zx[9] ? 16'd0 : t[`WYDE9];
  		o[`WYDE10] = mx[10] ? prodx16[`WYDE10] : zx[10] ? 16'd0 : t[`WYDE10];
  		o[`WYDE11] = mx[11] ? prodx16[`WYDE11] : zx[11] ? 16'd0 : t[`WYDE11];
  		o[`WYDE12] = mx[12] ? prodx16[`WYDE12] : zx[12] ? 16'd0 : t[`WYDE12];
  		o[`WYDE13] = mx[13] ? prodx16[`WYDE13] : zx[13] ? 16'd0 : t[`WYDE13];
  		o[`WYDE14] = mx[14] ? prodx16[`WYDE14] : zx[14] ? 16'd0 : t[`WYDE14];
  		o[`WYDE15] = mx[15] ? prodx16[`WYDE15] : zx[15] ? 16'd0 : t[`WYDE15];
  		end
  	tetra_para:
  		begin
  		o[`TETRA0] = mx[0] ? prodx32[`TETRA0] : zx[0] ? 32'd0 : t[`TETRA0];
  		o[`TETRA1] = mx[1] ? prodx32[`TETRA1] : zx[1] ? 32'd0 : t[`TETRA1];
  		o[`TETRA2] = mx[2] ? prodx32[`TETRA2] : zx[2] ? 32'd0 : t[`TETRA2];
  		o[`TETRA3] = mx[3] ? prodx32[`TETRA3] : zx[3] ? 32'd0 : t[`TETRA3];
  		o[`TETRA4] = mx[4] ? prodx32[`TETRA4] : zx[4] ? 32'd0 : t[`TETRA4];
  		o[`TETRA5] = mx[5] ? prodx32[`TETRA5] : zx[5] ? 32'd0 : t[`TETRA5];
  		o[`TETRA6] = mx[6] ? prodx32[`TETRA6] : zx[6] ? 32'd0 : t[`TETRA6];
  		o[`TETRA7] = mx[7] ? prodx32[`TETRA7] : zx[7] ? 32'd0 : t[`TETRA7];
  		end
  	octa_para:
  		begin
  		o[`OCTA0] = mx[0] ? prodx64[`OCTA0] : zx[0] ? 64'd0 : t[`OCTA0];
  		o[`OCTA1] = mx[1] ? prodx64[`OCTA1] : zx[1] ? 64'd0 : t[`OCTA1];
  		o[`OCTA2] = mx[2] ? prodx64[`OCTA2] : zx[2] ? 64'd0 : t[`OCTA2];
  		o[`OCTA3] = mx[3] ? prodx64[`OCTA3] : zx[3] ? 64'd0 : t[`OCTA3];
  		end
  	hexi_para:	
  		begin
  		o[`HEXI0] = mx[0] ? prodx128[`HEXI0] : zx[0] ? 128'd0 : t[`HEXI0];
  		o[`HEXI1] = mx[1] ? prodx128[`HEXI1] : zx[1] ? 128'd0 : t[`HEXI1];
  		end
  	default:	o = prod128;
  	endcase
end
endtask

task tskShift;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] t;
output [DBW:0] o;
begin
  	case(fmt)
  	byt:	o = {t[`HEXI1],{120{1'b0}},shfto8[7:0]};
  	wyde:	o = {t[`HEXI1],{112{1'b0}},shfto16[15:0]};
  	tetra:	o = {t[`HEXI1],{96{1'b0}},shfto32[31:0]};
  	octa:	o = {t[`HEXI1],{64{1'b0}},shfto64[63:0]};
  	hexi:	o = {t[`HEXI1],shfto128[127:0]};
  	byte_para:
  		begin
  		o[`BYTE0] = mx[0] ? shfto8[`BYTE0] : zx[0] ? 8'd0 : t[`BYTE0];
  		o[`BYTE1] = mx[1] ? shfto8[`BYTE1] : zx[1] ? 8'd0 : t[`BYTE1];
  		o[`BYTE2] = mx[2] ? shfto8[`BYTE2] : zx[2] ? 8'd0 : t[`BYTE2];
  		o[`BYTE3] = mx[3] ? shfto8[`BYTE3] : zx[3] ? 8'd0 : t[`BYTE3];
  		o[`BYTE4] = mx[4] ? shfto8[`BYTE4] : zx[4] ? 8'd0 : t[`BYTE4];
  		o[`BYTE5] = mx[5] ? shfto8[`BYTE5] : zx[5] ? 8'd0 : t[`BYTE5];
  		o[`BYTE6] = mx[6] ? shfto8[`BYTE6] : zx[6] ? 8'd0 : t[`BYTE6];
  		o[`BYTE7] = mx[7] ? shfto8[`BYTE7] : zx[7] ? 8'd0 : t[`BYTE7];
  		o[`BYTE8] = mx[8] ? shfto8[`BYTE8] : zx[8] ? 8'd0 : t[`BYTE8];
  		o[`BYTE9] = mx[9] ? shfto8[`BYTE9] : zx[9] ? 8'd0 : t[`BYTE9];
  		o[`BYTE10] = mx[10] ? shfto8[`BYTE10] : zx[10] ? 8'd0 : t[`BYTE10];
  		o[`BYTE11] = mx[11] ? shfto8[`BYTE11] : zx[11] ? 8'd0 : t[`BYTE11];
  		o[`BYTE12] = mx[12] ? shfto8[`BYTE12] : zx[12] ? 8'd0 : t[`BYTE12];
  		o[`BYTE13] = mx[13] ? shfto8[`BYTE13] : zx[13] ? 8'd0 : t[`BYTE13];
  		o[`BYTE14] = mx[14] ? shfto8[`BYTE14] : zx[14] ? 8'd0 : t[`BYTE14];
  		o[`BYTE15] = mx[15] ? shfto8[`BYTE15] : zx[15] ? 8'd0 : t[`BYTE15];
  		o[`BYTE16] = mx[16] ? shfto8[`BYTE16] : zx[16] ? 8'd0 : t[`BYTE16];
  		o[`BYTE17] = mx[17] ? shfto8[`BYTE17] : zx[17] ? 8'd0 : t[`BYTE17];
  		o[`BYTE18] = mx[18] ? shfto8[`BYTE18] : zx[18] ? 8'd0 : t[`BYTE18];
  		o[`BYTE19] = mx[19] ? shfto8[`BYTE19] : zx[19] ? 8'd0 : t[`BYTE19];
  		o[`BYTE20] = mx[20] ? shfto8[`BYTE20] : zx[20] ? 8'd0 : t[`BYTE20];
  		o[`BYTE21] = mx[21] ? shfto8[`BYTE21] : zx[21] ? 8'd0 : t[`BYTE21];
  		o[`BYTE22] = mx[22] ? shfto8[`BYTE22] : zx[22] ? 8'd0 : t[`BYTE22];
  		o[`BYTE23] = mx[23] ? shfto8[`BYTE23] : zx[23] ? 8'd0 : t[`BYTE23];
  		o[`BYTE24] = mx[24] ? shfto8[`BYTE24] : zx[24] ? 8'd0 : t[`BYTE24];
  		o[`BYTE25] = mx[25] ? shfto8[`BYTE25] : zx[25] ? 8'd0 : t[`BYTE25];
  		o[`BYTE26] = mx[26] ? shfto8[`BYTE26] : zx[26] ? 8'd0 : t[`BYTE26];
  		o[`BYTE27] = mx[27] ? shfto8[`BYTE27] : zx[27] ? 8'd0 : t[`BYTE27];
  		o[`BYTE28] = mx[28] ? shfto8[`BYTE28] : zx[28] ? 8'd0 : t[`BYTE28];
  		o[`BYTE29] = mx[29] ? shfto8[`BYTE29] : zx[29] ? 8'd0 : t[`BYTE29];
  		o[`BYTE30] = mx[30] ? shfto8[`BYTE30] : zx[30] ? 8'd0 : t[`BYTE30];
  		o[`BYTE31] = mx[31] ? shfto8[`BYTE31] : zx[31] ? 8'd0 : t[`BYTE31];
  		end
  	wyde_para:
  		begin
  		o[`WYDE0] = mx[0] ? shfto16[`WYDE0] : zx[0] ? 16'd0 : t[`WYDE0];
  		o[`WYDE1] = mx[1] ? shfto16[`WYDE1] : zx[1] ? 16'd0 : t[`WYDE1];
  		o[`WYDE2] = mx[2] ? shfto16[`WYDE2] : zx[2] ? 16'd0 : t[`WYDE2];
  		o[`WYDE3] = mx[3] ? shfto16[`WYDE3] : zx[3] ? 16'd0 : t[`WYDE3];
  		o[`WYDE4] = mx[4] ? shfto16[`WYDE4] : zx[4] ? 16'd0 : t[`WYDE4];
  		o[`WYDE5] = mx[5] ? shfto16[`WYDE5] : zx[5] ? 16'd0 : t[`WYDE5];
  		o[`WYDE6] = mx[6] ? shfto16[`WYDE6] : zx[6] ? 16'd0 : t[`WYDE6];
  		o[`WYDE7] = mx[7] ? shfto16[`WYDE7] : zx[7] ? 16'd0 : t[`WYDE7];
  		o[`WYDE8] = mx[8] ? shfto16[`WYDE8] : zx[8] ? 16'd0 : t[`WYDE8];
  		o[`WYDE9] = mx[9] ? shfto16[`WYDE9] : zx[9] ? 16'd0 : t[`WYDE9];
  		o[`WYDE10] = mx[10] ? shfto16[`WYDE10] : zx[10] ? 16'd0 : t[`WYDE10];
  		o[`WYDE11] = mx[11] ? shfto16[`WYDE11] : zx[11] ? 16'd0 : t[`WYDE11];
  		o[`WYDE12] = mx[12] ? shfto16[`WYDE12] : zx[12] ? 16'd0 : t[`WYDE12];
  		o[`WYDE13] = mx[13] ? shfto16[`WYDE13] : zx[13] ? 16'd0 : t[`WYDE13];
  		o[`WYDE14] = mx[14] ? shfto16[`WYDE14] : zx[14] ? 16'd0 : t[`WYDE14];
  		o[`WYDE15] = mx[15] ? shfto16[`WYDE15] : zx[15] ? 16'd0 : t[`WYDE15];
  		end
  	tetra_para:
  		begin
  		o[`TETRA0] = mx[0] ? shfto32[`TETRA0] : zx[0] ? 32'd0 : t[`TETRA0];
  		o[`TETRA1] = mx[1] ? shfto32[`TETRA1] : zx[1] ? 32'd0 : t[`TETRA1];
  		o[`TETRA2] = mx[2] ? shfto32[`TETRA2] : zx[2] ? 32'd0 : t[`TETRA2];
  		o[`TETRA3] = mx[3] ? shfto32[`TETRA3] : zx[3] ? 32'd0 : t[`TETRA3];
  		o[`TETRA4] = mx[4] ? shfto32[`TETRA4] : zx[4] ? 32'd0 : t[`TETRA4];
  		o[`TETRA5] = mx[5] ? shfto32[`TETRA5] : zx[5] ? 32'd0 : t[`TETRA5];
  		o[`TETRA6] = mx[6] ? shfto32[`TETRA6] : zx[6] ? 32'd0 : t[`TETRA6];
  		o[`TETRA7] = mx[7] ? shfto32[`TETRA7] : zx[7] ? 32'd0 : t[`TETRA7];
  		end
  	octa_para:
  		begin
  		o[`OCTA0] = mx[0] ? shfto64[`OCTA0] : zx[0] ? 64'd0 : t[`OCTA0];
  		o[`OCTA1] = mx[1] ? shfto64[`OCTA1] : zx[1] ? 64'd0 : t[`OCTA1];
  		o[`OCTA2] = mx[2] ? shfto64[`OCTA2] : zx[2] ? 64'd0 : t[`OCTA2];
  		o[`OCTA3] = mx[3] ? shfto64[`OCTA3] : zx[3] ? 64'd0 : t[`OCTA3];
  		end
  	hexi_para:	
  		begin
  		o[`HEXI0] = mx[0] ? shfto128[`HEXI0] : zx[0] ? 128'd0 : t[`HEXI0];
  		o[`HEXI1] = mx[1] ? shfto128[`HEXI1] : zx[1] ? 128'd0 : t[`HEXI1];
  		end
  	default:	o = shfto128;
  	endcase
end
endtask

task tskAbs;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] t;
output [DBW:0] o;
begin
	o = t;
	if (BIG)
	case(fmt)
	byt:   	o[127:0] = (a[7] ? -a[7:0] : a[7:0]);
	wyde:   o[127:0] = (a[15] ? -a[15:0] : a[15:0]);
	tetra:  o[127:0] = (a[31] ? -a[31:0] : a[31:0]);
	octa:   o[127:0] = (a[63] ? -a[63:0] : a[63:0]);
	hexi:	  o[127:0] = (a[127] ? -a[127:0] : a[127:0]);
	byte_para:	;
	wyde_para:	;
	tetra_para:
		begin
			o[`TETRA0] = mx[0] ? (a[ 31] ? -a[`TETRA0] : a[`TETRA0]) : zx[0] ? 32'd0 : t[`TETRA0];
			o[`TETRA1] = mx[1] ? (a[ 63] ? -a[`TETRA1] : a[`TETRA1]) : zx[1] ? 32'd0 : t[`TETRA1];
			o[`TETRA2] = mx[2] ? (a[ 95] ? -a[`TETRA2] : a[`TETRA2]) : zx[2] ? 32'd0 : t[`TETRA2];
			o[`TETRA3] = mx[3] ? (a[127] ? -a[`TETRA3] : a[`TETRA3]) : zx[3] ? 32'd0 : t[`TETRA3];
			o[`TETRA4] = mx[4] ? (a[159] ? -a[`TETRA4] : a[`TETRA4]) : zx[4] ? 32'd0 : t[`TETRA4];
			o[`TETRA5] = mx[5] ? (a[191] ? -a[`TETRA5] : a[`TETRA5]) : zx[5] ? 32'd0 : t[`TETRA5];
			o[`TETRA6] = mx[6] ? (a[223] ? -a[`TETRA6] : a[`TETRA6]) : zx[6] ? 32'd0 : t[`TETRA6];
			o[`TETRA7] = mx[7] ? (a[255] ? -a[`TETRA7] : a[`TETRA7]) : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para:
		begin
			o[`OCTA0] = mx[0] ? (a[ 63] ? -a[`OCTA0] : a[`OCTA0]) : zx[0] ? 64'd0 : t[`OCTA0];
			o[`OCTA1] = mx[1] ? (a[127] ? -a[`OCTA1] : a[`OCTA1]) : zx[1] ? 64'd0 : t[`OCTA1];
			o[`OCTA2] = mx[2] ? (a[191] ? -a[`OCTA2] : a[`OCTA2]) : zx[2] ? 64'd0 : t[`OCTA2];
			o[`OCTA3] = mx[3] ? (a[255] ? -a[`OCTA3] : a[`OCTA3]) : zx[3] ? 64'd0 : t[`OCTA3];
		end
	hexi_para:
		begin
			o[`HEXI0] = mx[0] ? (a[127] ? -a[`HEXI0] : a[`HEXI0]) : zx[0] ? 128'd0 : t[`HEXI0];
			o[`HEXI1] = mx[1] ? (a[255] ? -a[`HEXI1] : a[`HEXI1]) : zx[1] ? 128'd0 : t[`HEXI1];
		end
	endcase
	else
		o[127:0] = {32{4'hC}};
end
endtask

task tskNeg;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] t;
output [DBW:0] o;
begin
	o = t;
	if (BIG)
	case(fmt)
	byt:   	o[127:0] = -a[7:0];
	wyde:   o[127:0] = -a[15:0];
	tetra:  o[127:0] = -a[31:0];
	octa:   o[127:0] = -a[63:0];
	hexi:	  o[127:0] = -a[127:0];
	byte_para:	;
	wyde_para:	;
	tetra_para:
		begin
			o[`TETRA0] = mx[0] ? -a[`TETRA0] : zx[0] ? 32'd0 : t[`TETRA0];
			o[`TETRA1] = mx[1] ? -a[`TETRA1] : zx[1] ? 32'd0 : t[`TETRA1];
			o[`TETRA2] = mx[2] ? -a[`TETRA2] : zx[2] ? 32'd0 : t[`TETRA2];
			o[`TETRA3] = mx[3] ? -a[`TETRA3] : zx[3] ? 32'd0 : t[`TETRA3];
			o[`TETRA4] = mx[4] ? -a[`TETRA4] : zx[4] ? 32'd0 : t[`TETRA4];
			o[`TETRA5] = mx[5] ? -a[`TETRA5] : zx[5] ? 32'd0 : t[`TETRA5];
			o[`TETRA6] = mx[6] ? -a[`TETRA6] : zx[6] ? 32'd0 : t[`TETRA6];
			o[`TETRA7] = mx[7] ? -a[`TETRA7] : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para:
		begin
			o[`OCTA0] = mx[0] ? -a[`OCTA0] : zx[0] ? 64'd0 : t[`OCTA0];
			o[`OCTA1] = mx[1] ? -a[`OCTA1] : zx[1] ? 64'd0 : t[`OCTA1];
			o[`OCTA2] = mx[2] ? -a[`OCTA2] : zx[2] ? 64'd0 : t[`OCTA2];
			o[`OCTA3] = mx[3] ? -a[`OCTA3] : zx[3] ? 64'd0 : t[`OCTA3];
		end
	hexi_para:
		begin
			o[`HEXI0] = mx[0] ? -a[`HEXI0] : zx[0] ? 128'd0 : t[`HEXI0];
			o[`HEXI1] = mx[1] ? -a[`HEXI1] : zx[1] ? 128'd0 : t[`HEXI1];
		end
	endcase
	else
		o[127:0] = {32{4'hC}};
end
endtask

task tskNot;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] t;
output [DBW:0] o;
begin
	o = t;
	if (BIG)
	case(fmt)
	byt:   	o[127:0] = a[7:0] == 8'd0;
	wyde:   o[127:0] = a[15:0] == 16'd0;
	tetra:  o[127:0] = a[31:0] == 32'd0;
	octa:   o[127:0] = a[63:0] == 64'd0;
	hexi:	  o[127:0] = a[127:0] == 128'd0;
	byte_para:	;
	wyde_para:	;
	tetra_para:
		begin
			o[`TETRA0] = mx[0] ? a[`TETRA0] == 32'd0 : zx[0] ? 32'd0 : t[`TETRA0];
			o[`TETRA1] = mx[1] ? a[`TETRA1] == 32'd0 : zx[1] ? 32'd0 : t[`TETRA1];
			o[`TETRA2] = mx[2] ? a[`TETRA2] == 32'd0 : zx[2] ? 32'd0 : t[`TETRA2];
			o[`TETRA3] = mx[3] ? a[`TETRA3] == 32'd0 : zx[3] ? 32'd0 : t[`TETRA3];
			o[`TETRA4] = mx[4] ? a[`TETRA4] == 32'd0 : zx[4] ? 32'd0 : t[`TETRA4];
			o[`TETRA5] = mx[5] ? a[`TETRA5] == 32'd0 : zx[5] ? 32'd0 : t[`TETRA5];
			o[`TETRA6] = mx[6] ? a[`TETRA6] == 32'd0 : zx[6] ? 32'd0 : t[`TETRA6];
			o[`TETRA7] = mx[7] ? a[`TETRA7] == 32'd0 : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para:
		begin
			o[`OCTA0] = mx[0] ? a[`OCTA0] == 64'd0 : zx[0] ? 64'd0 : t[`OCTA0];
			o[`OCTA1] = mx[1] ? a[`OCTA1] == 64'd0 : zx[1] ? 64'd0 : t[`OCTA1];
			o[`OCTA2] = mx[2] ? a[`OCTA2] == 64'd0 : zx[2] ? 64'd0 : t[`OCTA2];
			o[`OCTA3] = mx[3] ? a[`OCTA3] == 64'd0 : zx[3] ? 64'd0 : t[`OCTA3];
		end
	hexi_para:
		begin
			o[`HEXI0] = mx[0] ? a[`HEXI0] == 128'd0 : zx[0] ? 128'd0 : t[`HEXI0];
			o[`HEXI1] = mx[1] ? a[`HEXI1] == 128'd0 : zx[1] ? 128'd0 : t[`HEXI1];
		end
	endcase
	else
		o[127:0] = {32{4'hC}};
end
endtask

task tskAdd;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	case(fmt)
	byt:
		begin
			o[`BYTE0] = a[`BYTE0] + b[`BYTE0];
			o[127:8] = {120{o[7]}};
			o[`HEXI1] = t[`HEXI1];
		end
	wyde:
		begin
			o[`WYDE0] = a[`WYDE0] + b[`WYDE0];
			o[127:16] = {112{o[15]}};
			o[`HEXI1] = t[`HEXI1];
		end
	tetra:
		begin
			o[`TETRA0] = a[`TETRA0] + b[`TETRA0];
			o[127:32] = {96{o[31]}};
			o[`HEXI1] = t[`HEXI1];
		end
	octa:
		begin
			o[`OCTA0] = a[`OCTA0] + b[`OCTA0];
			o[127:64] = {64{o[63]}};
			o[`HEXI1] = t[`HEXI1];
		end
	hexi:
		begin
			o[`HEXI0] = a[`HEXI0] + b[`HEXI0];
			o[`HEXI1] = t[`HEXI1];
		end
	byte_para:
		begin
			o[`BYTE0] = mx[0] ? a[`BYTE0] + b[`BYTE0] : zx[0] ? 8'd0 : t[`BYTE0];
			o[`BYTE1] = mx[1] ? a[`BYTE1] + b[`BYTE1] : zx[1] ? 8'd0 : t[`BYTE1];
			o[`BYTE2] = mx[2] ? a[`BYTE2] + b[`BYTE2] : zx[2] ? 8'd0 : t[`BYTE2];
			o[`BYTE3] = mx[3] ? a[`BYTE3] + b[`BYTE3] : zx[3] ? 8'd0 : t[`BYTE3];
			o[`BYTE4] = mx[4] ? a[`BYTE4] + b[`BYTE4] : zx[4] ? 8'd0 : t[`BYTE4];
			o[`BYTE5] = mx[5] ? a[`BYTE5] + b[`BYTE5] : zx[5] ? 8'd0 : t[`BYTE5];
			o[`BYTE6] = mx[6] ? a[`BYTE6] + b[`BYTE6] : zx[6] ? 8'd0 : t[`BYTE6];
			o[`BYTE7] = mx[7] ? a[`BYTE7] + b[`BYTE7] : zx[7] ? 8'd0 : t[`BYTE7];
			o[`BYTE8] = mx[8] ? a[`BYTE8] + b[`BYTE8] : zx[8] ? 8'd0 : t[`BYTE8];
			o[`BYTE9] = mx[9] ? a[`BYTE9] + b[`BYTE9] : zx[9] ? 8'd0 : t[`BYTE9];
			o[`BYTE10] = mx[10] ? a[`BYTE10] + b[`BYTE10] : zx[10] ? 8'd0 : t[`BYTE10];
			o[`BYTE11] = mx[11] ? a[`BYTE11] + b[`BYTE11] : zx[11] ? 8'd0 : t[`BYTE11];
			o[`BYTE12] = mx[12] ? a[`BYTE12] + b[`BYTE12] : zx[12] ? 8'd0 : t[`BYTE12];
			o[`BYTE13] = mx[13] ? a[`BYTE13] + b[`BYTE13] : zx[13] ? 8'd0 : t[`BYTE13];
			o[`BYTE14] = mx[14] ? a[`BYTE14] + b[`BYTE14] : zx[14] ? 8'd0 : t[`BYTE14];
			o[`BYTE15] = mx[15] ? a[`BYTE15] + b[`BYTE15] : zx[15] ? 8'd0 : t[`BYTE15];
			o[`BYTE16] = mx[16] ? a[`BYTE16] + b[`BYTE16] : zx[16] ? 8'd0 : t[`BYTE16];
			o[`BYTE17] = mx[17] ? a[`BYTE17] + b[`BYTE17] : zx[17] ? 8'd0 : t[`BYTE17];
			o[`BYTE18] = mx[18] ? a[`BYTE18] + b[`BYTE18] : zx[18] ? 8'd0 : t[`BYTE18];
			o[`BYTE19] = mx[19] ? a[`BYTE19] + b[`BYTE19] : zx[19] ? 8'd0 : t[`BYTE19];
			o[`BYTE20] = mx[20] ? a[`BYTE20] + b[`BYTE20] : zx[20] ? 8'd0 : t[`BYTE20];
			o[`BYTE21] = mx[21] ? a[`BYTE21] + b[`BYTE21] : zx[21] ? 8'd0 : t[`BYTE21];
			o[`BYTE22] = mx[22] ? a[`BYTE22] + b[`BYTE22] : zx[22] ? 8'd0 : t[`BYTE22];
			o[`BYTE23] = mx[23] ? a[`BYTE23] + b[`BYTE23] : zx[23] ? 8'd0 : t[`BYTE23];
			o[`BYTE24] = mx[24] ? a[`BYTE24] + b[`BYTE24] : zx[24] ? 8'd0 : t[`BYTE24];
			o[`BYTE25] = mx[25] ? a[`BYTE25] + b[`BYTE25] : zx[25] ? 8'd0 : t[`BYTE25];
			o[`BYTE26] = mx[26] ? a[`BYTE26] + b[`BYTE26] : zx[26] ? 8'd0 : t[`BYTE26];
			o[`BYTE27] = mx[27] ? a[`BYTE27] + b[`BYTE27] : zx[27] ? 8'd0 : t[`BYTE27];
			o[`BYTE28] = mx[28] ? a[`BYTE28] + b[`BYTE28] : zx[28] ? 8'd0 : t[`BYTE28];
			o[`BYTE29] = mx[29] ? a[`BYTE29] + b[`BYTE29] : zx[29] ? 8'd0 : t[`BYTE29];
			o[`BYTE30] = mx[30] ? a[`BYTE30] + b[`BYTE30] : zx[30] ? 8'd0 : t[`BYTE30];
			o[`BYTE31] = mx[31] ? a[`BYTE31] + b[`BYTE31] : zx[31] ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
			o[`WYDE0] = mx[0] ? a[`WYDE0] + b[`WYDE0] : zx[0] ? 16'd0 : t[`WYDE0];
			o[`WYDE1] = mx[1] ? a[`WYDE1] + b[`WYDE1] : zx[1] ? 16'd0 : t[`WYDE1];
			o[`WYDE2] = mx[2] ? a[`WYDE2] + b[`WYDE2] : zx[2] ? 16'd0 : t[`WYDE2];
			o[`WYDE3] = mx[3] ? a[`WYDE3] + b[`WYDE3] : zx[3] ? 16'd0 : t[`WYDE3];
			o[`WYDE4] = mx[4] ? a[`WYDE4] + b[`WYDE4] : zx[4] ? 16'd0 : t[`WYDE4];
			o[`WYDE5] = mx[5] ? a[`WYDE5] + b[`WYDE5] : zx[5] ? 16'd0 : t[`WYDE5];
			o[`WYDE6] = mx[6] ? a[`WYDE6] + b[`WYDE6] : zx[6] ? 16'd0 : t[`WYDE6];
			o[`WYDE7] = mx[7] ? a[`WYDE7] + b[`WYDE7] : zx[7] ? 16'd0 : t[`WYDE7];
			o[`WYDE8] = mx[8] ? a[`WYDE8] + b[`WYDE8] : zx[8] ? 16'd0 : t[`WYDE8];
			o[`WYDE9] = mx[9] ? a[`WYDE9] + b[`WYDE9] : zx[9] ? 16'd0 : t[`WYDE9];
			o[`WYDE10] = mx[10] ? a[`WYDE10] + b[`WYDE10] : zx[10] ? 16'd0 : t[`WYDE10];
			o[`WYDE11] = mx[11] ? a[`WYDE11] + b[`WYDE11] : zx[11] ? 16'd0 : t[`WYDE11];
			o[`WYDE12] = mx[12] ? a[`WYDE12] + b[`WYDE12] : zx[12] ? 16'd0 : t[`WYDE12];
			o[`WYDE13] = mx[13] ? a[`WYDE13] + b[`WYDE13] : zx[13] ? 16'd0 : t[`WYDE13];
			o[`WYDE14] = mx[14] ? a[`WYDE14] + b[`WYDE14] : zx[14] ? 16'd0 : t[`WYDE14];
			o[`WYDE15] = mx[15] ? a[`WYDE15] + b[`WYDE15] : zx[15] ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
			o[`TETRA0] = mx[0] ? a[`TETRA0] + b[`TETRA0] : zx[0] ? 32'd0 : t[`TETRA0];
			o[`TETRA1] = mx[1] ? a[`TETRA1] + b[`TETRA1] : zx[1] ? 32'd0 : t[`TETRA1];
			o[`TETRA2] = mx[2] ? a[`TETRA2] + b[`TETRA2] : zx[2] ? 32'd0 : t[`TETRA2];
			o[`TETRA3] = mx[3] ? a[`TETRA3] + b[`TETRA3] : zx[3] ? 32'd0 : t[`TETRA3];
			o[`TETRA4] = mx[4] ? a[`TETRA4] + b[`TETRA4] : zx[4] ? 32'd0 : t[`TETRA4];
			o[`TETRA5] = mx[5] ? a[`TETRA5] + b[`TETRA5] : zx[5] ? 32'd0 : t[`TETRA5];
			o[`TETRA6] = mx[6] ? a[`TETRA6] + b[`TETRA6] : zx[6] ? 32'd0 : t[`TETRA6];
			o[`TETRA7] = mx[7] ? a[`TETRA7] + b[`TETRA7] : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para:
		begin
			o[`OCTA0] = mx[0] ? a[`OCTA0] + b[`OCTA0] : zx[0] ? 64'd0 : t[`OCTA0];
			o[`OCTA1] = mx[1] ? a[`OCTA1] + b[`OCTA1] : zx[1] ? 64'd0 : t[`OCTA1];
			o[`OCTA2] = mx[2] ? a[`OCTA2] + b[`OCTA2] : zx[2] ? 64'd0 : t[`OCTA2];
			o[`OCTA3] = mx[3] ? a[`OCTA3] + b[`OCTA3] : zx[3] ? 64'd0 : t[`OCTA3];
		end
	hexi_para:
		begin
			o[`HEXI0] = mx[0] ? a[`HEXI0] + b[`HEXI0] : zx[0] ? 128'd0 : t[`HEXI0];
			o[`HEXI1] = mx[1] ? a[`HEXI1] + b[`HEXI1] : zx[1] ? 128'd0 : t[`HEXI1];
		end
  default:
  	begin
			o[`HEXI0] = a[`HEXI0] + b[`HEXI0];
			o[`HEXI1] = a[`HEXI1] + b[`HEXI1];
  	end
  endcase
end
endtask

task tskSub;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	case(fmt)
	byt:
		begin
			o[`BYTE0] = a[`BYTE0] - b[`BYTE0];
			o[127:8] = {120{o[7]}};
			o[`HEXI1] = t[`HEXI1];
		end
	wyde:
		begin
			o[`WYDE0] = a[`WYDE0] - b[`WYDE0];
			o[127:16] = {112{o[15]}};
			o[`HEXI1] = t[`HEXI1];
		end
	tetra:
		begin
			o[`TETRA0] = a[`TETRA0] - b[`TETRA0];
			o[127:32] = {96{o[31]}};
			o[`HEXI1] = t[`HEXI1];
		end
	octa:
		begin
			o[`OCTA0] = a[`OCTA0] - b[`OCTA0];
			o[127:64] = {64{o[63]}};
			o[`HEXI1] = t[`HEXI1];
		end
	hexi:
		begin
			o[`HEXI0] = a[`HEXI0] - b[`HEXI0];
			o[`HEXI1] = t[`HEXI1];
		end
	byte_para:
		begin
			o[`BYTE0] = mx[0] ? a[`BYTE0] - b[`BYTE0] : zx[0] ? 8'd0 : t[`BYTE0];
			o[`BYTE1] = mx[1] ? a[`BYTE1] - b[`BYTE1] : zx[1] ? 8'd0 : t[`BYTE1];
			o[`BYTE2] = mx[2] ? a[`BYTE2] - b[`BYTE2] : zx[2] ? 8'd0 : t[`BYTE2];
			o[`BYTE3] = mx[3] ? a[`BYTE3] - b[`BYTE3] : zx[3] ? 8'd0 : t[`BYTE3];
			o[`BYTE4] = mx[4] ? a[`BYTE4] - b[`BYTE4] : zx[4] ? 8'd0 : t[`BYTE4];
			o[`BYTE5] = mx[5] ? a[`BYTE5] - b[`BYTE5] : zx[5] ? 8'd0 : t[`BYTE5];
			o[`BYTE6] = mx[6] ? a[`BYTE6] - b[`BYTE6] : zx[6] ? 8'd0 : t[`BYTE6];
			o[`BYTE7] = mx[7] ? a[`BYTE7] - b[`BYTE7] : zx[7] ? 8'd0 : t[`BYTE7];
			o[`BYTE8] = mx[8] ? a[`BYTE8] - b[`BYTE8] : zx[8] ? 8'd0 : t[`BYTE8];
			o[`BYTE9] = mx[9] ? a[`BYTE9] - b[`BYTE9] : zx[9] ? 8'd0 : t[`BYTE9];
			o[`BYTE10] = mx[10] ? a[`BYTE10] - b[`BYTE10] : zx[10] ? 8'd0 : t[`BYTE10];
			o[`BYTE11] = mx[11] ? a[`BYTE11] - b[`BYTE11] : zx[11] ? 8'd0 : t[`BYTE11];
			o[`BYTE12] = mx[12] ? a[`BYTE12] - b[`BYTE12] : zx[12] ? 8'd0 : t[`BYTE12];
			o[`BYTE13] = mx[13] ? a[`BYTE13] - b[`BYTE13] : zx[13] ? 8'd0 : t[`BYTE13];
			o[`BYTE14] = mx[14] ? a[`BYTE14] - b[`BYTE14] : zx[14] ? 8'd0 : t[`BYTE14];
			o[`BYTE15] = mx[15] ? a[`BYTE15] - b[`BYTE15] : zx[15] ? 8'd0 : t[`BYTE15];
			o[`BYTE16] = mx[16] ? a[`BYTE16] - b[`BYTE16] : zx[16] ? 8'd0 : t[`BYTE16];
			o[`BYTE17] = mx[17] ? a[`BYTE17] - b[`BYTE17] : zx[17] ? 8'd0 : t[`BYTE17];
			o[`BYTE18] = mx[18] ? a[`BYTE18] - b[`BYTE18] : zx[18] ? 8'd0 : t[`BYTE18];
			o[`BYTE19] = mx[19] ? a[`BYTE19] - b[`BYTE19] : zx[19] ? 8'd0 : t[`BYTE19];
			o[`BYTE20] = mx[20] ? a[`BYTE20] - b[`BYTE20] : zx[20] ? 8'd0 : t[`BYTE20];
			o[`BYTE21] = mx[21] ? a[`BYTE21] - b[`BYTE21] : zx[21] ? 8'd0 : t[`BYTE21];
			o[`BYTE22] = mx[22] ? a[`BYTE22] - b[`BYTE22] : zx[22] ? 8'd0 : t[`BYTE22];
			o[`BYTE23] = mx[23] ? a[`BYTE23] - b[`BYTE23] : zx[23] ? 8'd0 : t[`BYTE23];
			o[`BYTE24] = mx[24] ? a[`BYTE24] - b[`BYTE24] : zx[24] ? 8'd0 : t[`BYTE24];
			o[`BYTE25] = mx[25] ? a[`BYTE25] - b[`BYTE25] : zx[25] ? 8'd0 : t[`BYTE25];
			o[`BYTE26] = mx[26] ? a[`BYTE26] - b[`BYTE26] : zx[26] ? 8'd0 : t[`BYTE26];
			o[`BYTE27] = mx[27] ? a[`BYTE27] - b[`BYTE27] : zx[27] ? 8'd0 : t[`BYTE27];
			o[`BYTE28] = mx[28] ? a[`BYTE28] - b[`BYTE28] : zx[28] ? 8'd0 : t[`BYTE28];
			o[`BYTE29] = mx[29] ? a[`BYTE29] - b[`BYTE29] : zx[29] ? 8'd0 : t[`BYTE29];
			o[`BYTE30] = mx[30] ? a[`BYTE30] - b[`BYTE30] : zx[30] ? 8'd0 : t[`BYTE30];
			o[`BYTE31] = mx[31] ? a[`BYTE31] - b[`BYTE31] : zx[31] ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
			o[`WYDE0] = mx[0] ? a[`WYDE0] - b[`WYDE0] : zx[0] ? 16'd0 : t[`WYDE0];
			o[`WYDE1] = mx[1] ? a[`WYDE1] - b[`WYDE1] : zx[1] ? 16'd0 : t[`WYDE1];
			o[`WYDE2] = mx[2] ? a[`WYDE2] - b[`WYDE2] : zx[2] ? 16'd0 : t[`WYDE2];
			o[`WYDE3] = mx[3] ? a[`WYDE3] - b[`WYDE3] : zx[3] ? 16'd0 : t[`WYDE3];
			o[`WYDE4] = mx[4] ? a[`WYDE4] - b[`WYDE4] : zx[4] ? 16'd0 : t[`WYDE4];
			o[`WYDE5] = mx[5] ? a[`WYDE5] - b[`WYDE5] : zx[5] ? 16'd0 : t[`WYDE5];
			o[`WYDE6] = mx[6] ? a[`WYDE6] - b[`WYDE6] : zx[6] ? 16'd0 : t[`WYDE6];
			o[`WYDE7] = mx[7] ? a[`WYDE7] - b[`WYDE7] : zx[7] ? 16'd0 : t[`WYDE7];
			o[`WYDE8] = mx[8] ? a[`WYDE8] - b[`WYDE8] : zx[8] ? 16'd0 : t[`WYDE8];
			o[`WYDE9] = mx[9] ? a[`WYDE9] - b[`WYDE9] : zx[9] ? 16'd0 : t[`WYDE9];
			o[`WYDE10] = mx[10] ? a[`WYDE10] - b[`WYDE10] : zx[10] ? 16'd0 : t[`WYDE10];
			o[`WYDE11] = mx[11] ? a[`WYDE11] - b[`WYDE11] : zx[11] ? 16'd0 : t[`WYDE11];
			o[`WYDE12] = mx[12] ? a[`WYDE12] - b[`WYDE12] : zx[12] ? 16'd0 : t[`WYDE12];
			o[`WYDE13] = mx[13] ? a[`WYDE13] - b[`WYDE13] : zx[13] ? 16'd0 : t[`WYDE13];
			o[`WYDE14] = mx[14] ? a[`WYDE14] - b[`WYDE14] : zx[14] ? 16'd0 : t[`WYDE14];
			o[`WYDE15] = mx[15] ? a[`WYDE15] - b[`WYDE15] : zx[15] ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
			o[`TETRA0] = mx[0] ? a[`TETRA0] - b[`TETRA0] : zx[0] ? 32'd0 : t[`TETRA0];
			o[`TETRA1] = mx[1] ? a[`TETRA1] - b[`TETRA1] : zx[1] ? 32'd0 : t[`TETRA1];
			o[`TETRA2] = mx[2] ? a[`TETRA2] - b[`TETRA2] : zx[2] ? 32'd0 : t[`TETRA2];
			o[`TETRA3] = mx[3] ? a[`TETRA3] - b[`TETRA3] : zx[3] ? 32'd0 : t[`TETRA3];
			o[`TETRA4] = mx[4] ? a[`TETRA4] - b[`TETRA4] : zx[4] ? 32'd0 : t[`TETRA4];
			o[`TETRA5] = mx[5] ? a[`TETRA5] - b[`TETRA5] : zx[5] ? 32'd0 : t[`TETRA5];
			o[`TETRA6] = mx[6] ? a[`TETRA6] - b[`TETRA6] : zx[6] ? 32'd0 : t[`TETRA6];
			o[`TETRA7] = mx[7] ? a[`TETRA7] - b[`TETRA7] : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para:
		begin
			o[`OCTA0] = mx[0] ? a[`OCTA0] - b[`OCTA0] : zx[0] ? 64'd0 : t[`OCTA0];
			o[`OCTA1] = mx[1] ? a[`OCTA1] - b[`OCTA1] : zx[1] ? 64'd0 : t[`OCTA1];
			o[`OCTA2] = mx[2] ? a[`OCTA2] - b[`OCTA2] : zx[2] ? 64'd0 : t[`OCTA2];
			o[`OCTA3] = mx[3] ? a[`OCTA3] - b[`OCTA3] : zx[3] ? 64'd0 : t[`OCTA3];
		end
	hexi_para:
		begin
			o[`HEXI0] = mx[0] ? a[`HEXI0] - b[`HEXI0] : zx[0] ? 128'd0 : t[`HEXI0];
			o[`HEXI1] = mx[1] ? a[`HEXI1] - b[`HEXI1] : zx[1] ? 128'd0 : t[`HEXI1];
		end
  default:
  	begin
			o[`HEXI0] = a[`HEXI0] - b[`HEXI0];
			o[`HEXI1] = a[`HEXI1] - b[`HEXI1];
  	end
  endcase
end
endtask

task tskCmp;
input [3:0] fmt;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	case(fmt)
	byt:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = a[`BYTE0]==b[`BYTE0];
			o[1] = $signed(a[`BYTE0]) < $signed(b[`BYTE0]);
			o[2] = $signed(a[`BYTE0]) > $signed(b[`BYTE0]);
		end
	wyde:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = a[`WYDE0]==b[`WYDE0];
			o[1] = $signed(a[`WYDE0]) < $signed(b[`WYDE0]);
			o[2] = $signed(a[`WYDE0]) > $signed(b[`WYDE0]);
		end
	tetra:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = a[`TETRA0]==b[`TETRA0];
			o[1] = $signed(a[`TETRA0]) < $signed(b[`TETRA0]);
			o[2] = $signed(a[`TETRA0]) > $signed(b[`TETRA0]);
		end
	octa:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = a[`OCTA0]==b[`OCTA0];
			o[1] = $signed(a[`OCTA0]) < $signed(b[`OCTA0]);
			o[2] = $signed(a[`OCTA0]) > $signed(b[`OCTA0]);
		end
	hexi:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = a[`HEXI0]==b[`HEXI0];
			o[1] = $signed(a[`HEXI0]) < $signed(b[`HEXI0]);
			o[2] = $signed(a[`HEXI0]) > $signed(b[`HEXI0]);
		end
	default:
			o = {t[`HEXI1],128'd0};
	endcase
end
endtask

task tskCmpu;
input [3:0] fmt;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	case(fmt)
	byt:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = a[`BYTE0]==b[`BYTE0];
			o[1] = a[`BYTE0] < b[`BYTE0];
			o[2] = a[`BYTE0] > b[`BYTE0];
		end
	wyde:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = a[`WYDE0]==b[`WYDE0];
			o[1] = a[`WYDE0] < b[`WYDE0];
			o[2] = a[`WYDE0] > b[`WYDE0];
		end
	tetra:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = a[`TETRA0]==b[`TETRA0];
			o[1] = a[`TETRA0] < b[`TETRA0];
			o[2] = a[`TETRA0] > b[`TETRA0];
		end
	octa:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = a[`OCTA0]==b[`OCTA0];
			o[1] = a[`OCTA0] < b[`OCTA0];
			o[2] = a[`OCTA0] > b[`OCTA0];
		end
	hexi:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = a[`HEXI0]==b[`HEXI0];
			o[1] = a[`HEXI0] < b[`HEXI0];
			o[2] = a[`HEXI0] > b[`HEXI0];
		end
	default:
			o = {t[`HEXI1],128'd0};
	endcase
end
endtask

task tskAnd;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	case(fmt)
	byt:		o = {t[`HEXI1],120'd0,a[`BYTE0] & b[`BYTE0]};
	wyde:		o = {t[`HEXI1],112'd0,a[`WYDE0] & b[`WYDE0]};
	tetra:	o = {t[`HEXI1],96'd0,a[`TETRA0] & b[`TETRA0]};
	octa:		o = {t[`HEXI1],64'd0,a[`OCTA0] & b[`OCTA0]};
	hexi:		o = {t[`HEXI1],a[`HEXI0] & b[`HEXI0]};
	byte_para:
		begin
			o[`BYTE0] = mx[0] ? a[`BYTE0] & b[`BYTE0] : zx[0] ? 8'd0 : t[`BYTE0];
			o[`BYTE1] = mx[1] ? a[`BYTE1] & b[`BYTE1] : zx[1] ? 8'd0 : t[`BYTE1];
			o[`BYTE2] = mx[2] ? a[`BYTE2] & b[`BYTE2] : zx[2] ? 8'd0 : t[`BYTE2];
			o[`BYTE3] = mx[3] ? a[`BYTE3] & b[`BYTE3] : zx[3] ? 8'd0 : t[`BYTE3];
			o[`BYTE4] = mx[4] ? a[`BYTE4] & b[`BYTE4] : zx[4] ? 8'd0 : t[`BYTE4];
			o[`BYTE5] = mx[5] ? a[`BYTE5] & b[`BYTE5] : zx[5] ? 8'd0 : t[`BYTE5];
			o[`BYTE6] = mx[6] ? a[`BYTE6] & b[`BYTE6] : zx[6] ? 8'd0 : t[`BYTE6];
			o[`BYTE7] = mx[7] ? a[`BYTE7] & b[`BYTE7] : zx[7] ? 8'd0 : t[`BYTE7];
			o[`BYTE8] = mx[8] ? a[`BYTE8] & b[`BYTE8] : zx[8] ? 8'd0 : t[`BYTE8];
			o[`BYTE9] = mx[9] ? a[`BYTE9] & b[`BYTE9] : zx[9] ? 8'd0 : t[`BYTE9];
			o[`BYTE10] = mx[10] ? a[`BYTE10] & b[`BYTE10] : zx[10] ? 8'd0 : t[`BYTE10];
			o[`BYTE11] = mx[11] ? a[`BYTE11] & b[`BYTE11] : zx[11] ? 8'd0 : t[`BYTE11];
			o[`BYTE12] = mx[12] ? a[`BYTE12] & b[`BYTE12] : zx[12] ? 8'd0 : t[`BYTE12];
			o[`BYTE13] = mx[13] ? a[`BYTE13] & b[`BYTE13] : zx[13] ? 8'd0 : t[`BYTE13];
			o[`BYTE14] = mx[14] ? a[`BYTE14] & b[`BYTE14] : zx[14] ? 8'd0 : t[`BYTE14];
			o[`BYTE15] = mx[15] ? a[`BYTE15] & b[`BYTE15] : zx[15] ? 8'd0 : t[`BYTE15];
			o[`BYTE16] = mx[16] ? a[`BYTE16] & b[`BYTE16] : zx[16] ? 8'd0 : t[`BYTE16];
			o[`BYTE17] = mx[17] ? a[`BYTE17] & b[`BYTE17] : zx[17] ? 8'd0 : t[`BYTE17];
			o[`BYTE18] = mx[18] ? a[`BYTE18] & b[`BYTE18] : zx[18] ? 8'd0 : t[`BYTE18];
			o[`BYTE19] = mx[19] ? a[`BYTE19] & b[`BYTE19] : zx[19] ? 8'd0 : t[`BYTE19];
			o[`BYTE20] = mx[20] ? a[`BYTE20] & b[`BYTE20] : zx[20] ? 8'd0 : t[`BYTE20];
			o[`BYTE21] = mx[21] ? a[`BYTE21] & b[`BYTE21] : zx[21] ? 8'd0 : t[`BYTE21];
			o[`BYTE22] = mx[22] ? a[`BYTE22] & b[`BYTE22] : zx[22] ? 8'd0 : t[`BYTE22];
			o[`BYTE23] = mx[23] ? a[`BYTE23] & b[`BYTE23] : zx[23] ? 8'd0 : t[`BYTE23];
			o[`BYTE24] = mx[24] ? a[`BYTE24] & b[`BYTE24] : zx[24] ? 8'd0 : t[`BYTE24];
			o[`BYTE25] = mx[25] ? a[`BYTE25] & b[`BYTE25] : zx[25] ? 8'd0 : t[`BYTE25];
			o[`BYTE26] = mx[26] ? a[`BYTE26] & b[`BYTE26] : zx[26] ? 8'd0 : t[`BYTE26];
			o[`BYTE27] = mx[27] ? a[`BYTE27] & b[`BYTE27] : zx[27] ? 8'd0 : t[`BYTE27];
			o[`BYTE28] = mx[28] ? a[`BYTE28] & b[`BYTE28] : zx[28] ? 8'd0 : t[`BYTE28];
			o[`BYTE29] = mx[29] ? a[`BYTE29] & b[`BYTE29] : zx[29] ? 8'd0 : t[`BYTE29];
			o[`BYTE30] = mx[30] ? a[`BYTE30] & b[`BYTE30] : zx[30] ? 8'd0 : t[`BYTE30];
			o[`BYTE31] = mx[31] ? a[`BYTE31] & b[`BYTE31] : zx[31] ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
			o[`WYDE0] = mx[0] ? a[`WYDE0] & b[`WYDE0] : zx[0] ? 16'd0 : t[`WYDE0];
			o[`WYDE1] = mx[1] ? a[`WYDE1] & b[`WYDE1] : zx[1] ? 16'd0 : t[`WYDE1];
			o[`WYDE2] = mx[2] ? a[`WYDE2] & b[`WYDE2] : zx[2] ? 16'd0 : t[`WYDE2];
			o[`WYDE3] = mx[3] ? a[`WYDE3] & b[`WYDE3] : zx[3] ? 16'd0 : t[`WYDE3];
			o[`WYDE4] = mx[4] ? a[`WYDE4] & b[`WYDE4] : zx[4] ? 16'd0 : t[`WYDE4];
			o[`WYDE5] = mx[5] ? a[`WYDE5] & b[`WYDE5] : zx[5] ? 16'd0 : t[`WYDE5];
			o[`WYDE6] = mx[6] ? a[`WYDE6] & b[`WYDE6] : zx[6] ? 16'd0 : t[`WYDE6];
			o[`WYDE7] = mx[7] ? a[`WYDE7] & b[`WYDE7] : zx[7] ? 16'd0 : t[`WYDE7];
			o[`WYDE8] = mx[8] ? a[`WYDE8] & b[`WYDE8] : zx[8] ? 16'd0 : t[`WYDE8];
			o[`WYDE9] = mx[9] ? a[`WYDE9] & b[`WYDE9] : zx[9] ? 16'd0 : t[`WYDE9];
			o[`WYDE10] = mx[10] ? a[`WYDE10] & b[`WYDE10] : zx[10] ? 16'd0 : t[`WYDE10];
			o[`WYDE11] = mx[11] ? a[`WYDE11] & b[`WYDE11] : zx[11] ? 16'd0 : t[`WYDE11];
			o[`WYDE12] = mx[12] ? a[`WYDE12] & b[`WYDE12] : zx[12] ? 16'd0 : t[`WYDE12];
			o[`WYDE13] = mx[13] ? a[`WYDE13] & b[`WYDE13] : zx[13] ? 16'd0 : t[`WYDE13];
			o[`WYDE14] = mx[14] ? a[`WYDE14] & b[`WYDE14] : zx[14] ? 16'd0 : t[`WYDE14];
			o[`WYDE15] = mx[15] ? a[`WYDE15] & b[`WYDE15] : zx[15] ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
			o[`TETRA0] = mx[0] ? a[`TETRA0] & b[`TETRA0] : zx[0] ? 32'd0 : t[`TETRA0];
			o[`TETRA1] = mx[1] ? a[`TETRA1] & b[`TETRA1] : zx[1] ? 32'd0 : t[`TETRA1];
			o[`TETRA2] = mx[2] ? a[`TETRA2] & b[`TETRA2] : zx[2] ? 32'd0 : t[`TETRA2];
			o[`TETRA3] = mx[3] ? a[`TETRA3] & b[`TETRA3] : zx[3] ? 32'd0 : t[`TETRA3];
			o[`TETRA4] = mx[4] ? a[`TETRA4] & b[`TETRA4] : zx[4] ? 32'd0 : t[`TETRA4];
			o[`TETRA5] = mx[5] ? a[`TETRA5] & b[`TETRA5] : zx[5] ? 32'd0 : t[`TETRA5];
			o[`TETRA6] = mx[6] ? a[`TETRA6] & b[`TETRA6] : zx[6] ? 32'd0 : t[`TETRA6];
			o[`TETRA7] = mx[7] ? a[`TETRA7] & b[`TETRA7] : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para:
		begin
			o[`OCTA0] = mx[0] ? a[`OCTA0] & b[`OCTA0] : zx[0] ? 64'd0 : t[`OCTA0];
			o[`OCTA1] = mx[1] ? a[`OCTA1] & b[`OCTA1] : zx[1] ? 64'd0 : t[`OCTA1];
			o[`OCTA2] = mx[2] ? a[`OCTA2] & b[`OCTA2] : zx[2] ? 64'd0 : t[`OCTA2];
			o[`OCTA3] = mx[3] ? a[`OCTA3] & b[`OCTA3] : zx[3] ? 64'd0 : t[`OCTA3];
		end
	hexi_para:
		begin
			o[`HEXI0] = mx[0] ? a[`HEXI0] & b[`HEXI0] : zx[0] ? 128'd0 : t[`HEXI0];
			o[`HEXI1] = mx[1] ? a[`HEXI1] & b[`HEXI1] : zx[1] ? 128'd0 : t[`HEXI1];
		end
	default:
		o = a & b;
	endcase
end
endtask

task tskBit;
input [3:0] fmt;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	case(fmt)
	byt:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = (a[`BYTE0] & b[`BYTE0]) == 1'd0;
			o[1] = (a[`BYTE0] & b[`BYTE0] & 8'h80) == 8'h80;
		end
	wyde:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = (a[`WYDE0] & b[`WYDE0]) == 1'd0;
			o[1] = (a[`WYDE0] & b[`WYDE0] & 16'h8000) == 16'h8000;
		end
	tetra:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = (a[`TETRA0] & b[`TETRA0]) == 32'd0;
			o[1] = (a[`TETRA0] & b[`TETRA0] & 32'h80000000) == 32'h80000000;
		end
	octa:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = (a[`OCTA0] & b[`OCTA0]) == 64'd0;
			o[1] = (a[`OCTA0] & b[`OCTA0] & 64'h8000000000000000) == 64'h8000000000000000;
		end
	hexi:
		begin
			o = {t[`HEXI1],128'd0};
			o[0] = (a[`HEXI0] & b[`HEXI0]) ==  128'd0;
			o[1] = (a[`HEXI0] & b[`HEXI0] & 128'h80000000000000000000000000000000) == 128'h80000000000000000000000000000000;
		end
	default:
			o = {t[`HEXI1],128'd0};
	endcase
end
endtask

task tskOr;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	case(fmt)
	byt:		o = {t[`HEXI1],120'd0,a[`BYTE0] | b[`BYTE0]};
	wyde:		o = {t[`HEXI1],112'd0,a[`WYDE0] | b[`WYDE0]};
	tetra:	o = {t[`HEXI1],96'd0,a[`TETRA0] | b[`TETRA0]};
	octa:		o = {t[`HEXI1],64'd0,a[`OCTA0] | b[`OCTA0]};
	hexi:		o = {t[`HEXI1],a[`HEXI0] | b[`HEXI0]};
	byte_para:
		begin
			o[`BYTE0] = mx[0] ? a[`BYTE0] | b[`BYTE0] : zx[0] ? 8'd0 : t[`BYTE0];
			o[`BYTE1] = mx[1] ? a[`BYTE1] | b[`BYTE1] : zx[1] ? 8'd0 : t[`BYTE1];
			o[`BYTE2] = mx[2] ? a[`BYTE2] | b[`BYTE2] : zx[2] ? 8'd0 : t[`BYTE2];
			o[`BYTE3] = mx[3] ? a[`BYTE3] | b[`BYTE3] : zx[3] ? 8'd0 : t[`BYTE3];
			o[`BYTE4] = mx[4] ? a[`BYTE4] | b[`BYTE4] : zx[4] ? 8'd0 : t[`BYTE4];
			o[`BYTE5] = mx[5] ? a[`BYTE5] | b[`BYTE5] : zx[5] ? 8'd0 : t[`BYTE5];
			o[`BYTE6] = mx[6] ? a[`BYTE6] | b[`BYTE6] : zx[6] ? 8'd0 : t[`BYTE6];
			o[`BYTE7] = mx[7] ? a[`BYTE7] | b[`BYTE7] : zx[7] ? 8'd0 : t[`BYTE7];
			o[`BYTE8] = mx[8] ? a[`BYTE8] | b[`BYTE8] : zx[8] ? 8'd0 : t[`BYTE8];
			o[`BYTE9] = mx[9] ? a[`BYTE9] | b[`BYTE9] : zx[9] ? 8'd0 : t[`BYTE9];
			o[`BYTE10] = mx[10] ? a[`BYTE10] | b[`BYTE10] : zx[10] ? 8'd0 : t[`BYTE10];
			o[`BYTE11] = mx[11] ? a[`BYTE11] | b[`BYTE11] : zx[11] ? 8'd0 : t[`BYTE11];
			o[`BYTE12] = mx[12] ? a[`BYTE12] | b[`BYTE12] : zx[12] ? 8'd0 : t[`BYTE12];
			o[`BYTE13] = mx[13] ? a[`BYTE13] | b[`BYTE13] : zx[13] ? 8'd0 : t[`BYTE13];
			o[`BYTE14] = mx[14] ? a[`BYTE14] | b[`BYTE14] : zx[14] ? 8'd0 : t[`BYTE14];
			o[`BYTE15] = mx[15] ? a[`BYTE15] | b[`BYTE15] : zx[15] ? 8'd0 : t[`BYTE15];
			o[`BYTE16] = mx[16] ? a[`BYTE16] | b[`BYTE16] : zx[16] ? 8'd0 : t[`BYTE16];
			o[`BYTE17] = mx[17] ? a[`BYTE17] | b[`BYTE17] : zx[17] ? 8'd0 : t[`BYTE17];
			o[`BYTE18] = mx[18] ? a[`BYTE18] | b[`BYTE18] : zx[18] ? 8'd0 : t[`BYTE18];
			o[`BYTE19] = mx[19] ? a[`BYTE19] | b[`BYTE19] : zx[19] ? 8'd0 : t[`BYTE19];
			o[`BYTE20] = mx[20] ? a[`BYTE20] | b[`BYTE20] : zx[20] ? 8'd0 : t[`BYTE20];
			o[`BYTE21] = mx[21] ? a[`BYTE21] | b[`BYTE21] : zx[21] ? 8'd0 : t[`BYTE21];
			o[`BYTE22] = mx[22] ? a[`BYTE22] | b[`BYTE22] : zx[22] ? 8'd0 : t[`BYTE22];
			o[`BYTE23] = mx[23] ? a[`BYTE23] | b[`BYTE23] : zx[23] ? 8'd0 : t[`BYTE23];
			o[`BYTE24] = mx[24] ? a[`BYTE24] | b[`BYTE24] : zx[24] ? 8'd0 : t[`BYTE24];
			o[`BYTE25] = mx[25] ? a[`BYTE25] | b[`BYTE25] : zx[25] ? 8'd0 : t[`BYTE25];
			o[`BYTE26] = mx[26] ? a[`BYTE26] | b[`BYTE26] : zx[26] ? 8'd0 : t[`BYTE26];
			o[`BYTE27] = mx[27] ? a[`BYTE27] | b[`BYTE27] : zx[27] ? 8'd0 : t[`BYTE27];
			o[`BYTE28] = mx[28] ? a[`BYTE28] | b[`BYTE28] : zx[28] ? 8'd0 : t[`BYTE28];
			o[`BYTE29] = mx[29] ? a[`BYTE29] | b[`BYTE29] : zx[29] ? 8'd0 : t[`BYTE29];
			o[`BYTE30] = mx[30] ? a[`BYTE30] | b[`BYTE30] : zx[30] ? 8'd0 : t[`BYTE30];
			o[`BYTE31] = mx[31] ? a[`BYTE31] | b[`BYTE31] : zx[31] ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
			o[`WYDE0] = mx[0] ? a[`WYDE0] | b[`WYDE0] : zx[0] ? 16'd0 : t[`WYDE0];
			o[`WYDE1] = mx[1] ? a[`WYDE1] | b[`WYDE1] : zx[1] ? 16'd0 : t[`WYDE1];
			o[`WYDE2] = mx[2] ? a[`WYDE2] | b[`WYDE2] : zx[2] ? 16'd0 : t[`WYDE2];
			o[`WYDE3] = mx[3] ? a[`WYDE3] | b[`WYDE3] : zx[3] ? 16'd0 : t[`WYDE3];
			o[`WYDE4] = mx[4] ? a[`WYDE4] | b[`WYDE4] : zx[4] ? 16'd0 : t[`WYDE4];
			o[`WYDE5] = mx[5] ? a[`WYDE5] | b[`WYDE5] : zx[5] ? 16'd0 : t[`WYDE5];
			o[`WYDE6] = mx[6] ? a[`WYDE6] | b[`WYDE6] : zx[6] ? 16'd0 : t[`WYDE6];
			o[`WYDE7] = mx[7] ? a[`WYDE7] | b[`WYDE7] : zx[7] ? 16'd0 : t[`WYDE7];
			o[`WYDE8] = mx[8] ? a[`WYDE8] | b[`WYDE8] : zx[8] ? 16'd0 : t[`WYDE8];
			o[`WYDE9] = mx[9] ? a[`WYDE9] | b[`WYDE9] : zx[9] ? 16'd0 : t[`WYDE9];
			o[`WYDE10] = mx[10] ? a[`WYDE10] | b[`WYDE10] : zx[10] ? 16'd0 : t[`WYDE10];
			o[`WYDE11] = mx[11] ? a[`WYDE11] | b[`WYDE11] : zx[11] ? 16'd0 : t[`WYDE11];
			o[`WYDE12] = mx[12] ? a[`WYDE12] | b[`WYDE12] : zx[12] ? 16'd0 : t[`WYDE12];
			o[`WYDE13] = mx[13] ? a[`WYDE13] | b[`WYDE13] : zx[13] ? 16'd0 : t[`WYDE13];
			o[`WYDE14] = mx[14] ? a[`WYDE14] | b[`WYDE14] : zx[14] ? 16'd0 : t[`WYDE14];
			o[`WYDE15] = mx[15] ? a[`WYDE15] | b[`WYDE15] : zx[15] ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
			o[`TETRA0] = mx[0] ? a[`TETRA0] | b[`TETRA0] : zx[0] ? 32'd0 : t[`TETRA0];
			o[`TETRA1] = mx[1] ? a[`TETRA1] | b[`TETRA1] : zx[1] ? 32'd0 : t[`TETRA1];
			o[`TETRA2] = mx[2] ? a[`TETRA2] | b[`TETRA2] : zx[2] ? 32'd0 : t[`TETRA2];
			o[`TETRA3] = mx[3] ? a[`TETRA3] | b[`TETRA3] : zx[3] ? 32'd0 : t[`TETRA3];
			o[`TETRA4] = mx[4] ? a[`TETRA4] | b[`TETRA4] : zx[4] ? 32'd0 : t[`TETRA4];
			o[`TETRA5] = mx[5] ? a[`TETRA5] | b[`TETRA5] : zx[5] ? 32'd0 : t[`TETRA5];
			o[`TETRA6] = mx[6] ? a[`TETRA6] | b[`TETRA6] : zx[6] ? 32'd0 : t[`TETRA6];
			o[`TETRA7] = mx[7] ? a[`TETRA7] | b[`TETRA7] : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para:
		begin
			o[`OCTA0] = mx[0] ? a[`OCTA0] | b[`OCTA0] : zx[0] ? 64'd0 : t[`OCTA0];
			o[`OCTA1] = mx[1] ? a[`OCTA1] | b[`OCTA1] : zx[1] ? 64'd0 : t[`OCTA1];
			o[`OCTA2] = mx[2] ? a[`OCTA2] | b[`OCTA2] : zx[2] ? 64'd0 : t[`OCTA2];
			o[`OCTA3] = mx[3] ? a[`OCTA3] | b[`OCTA3] : zx[3] ? 64'd0 : t[`OCTA3];
		end
	hexi_para:
		begin
			o[`HEXI0] = mx[0] ? a[`HEXI0] | b[`HEXI0] : zx[0] ? 128'd0 : t[`HEXI0];
			o[`HEXI1] = mx[1] ? a[`HEXI1] | b[`HEXI1] : zx[1] ? 128'd0 : t[`HEXI1];
		end
	default:
		o = a | b;
	endcase
end
endtask

task tskXor;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	case(fmt)
	byt:		o = {t[`HEXI1],120'd0,a[`BYTE0] ^ b[`BYTE0]};
	wyde:		o = {t[`HEXI1],112'd0,a[`WYDE0] ^ b[`WYDE0]};
	tetra:	o = {t[`HEXI1],96'd0,a[`TETRA0] ^ b[`TETRA0]};
	octa:		o = {t[`HEXI1],64'd0,a[`OCTA0] ^ b[`OCTA0]};
	hexi:		o = {t[`HEXI1],a[`HEXI0] ^ b[`HEXI0]};
	byte_para:
		begin
			o[`BYTE0] = mx[0] ? a[`BYTE0] ^ b[`BYTE0] : zx[0] ? 8'd0 : t[`BYTE0];
			o[`BYTE1] = mx[1] ? a[`BYTE1] ^ b[`BYTE1] : zx[1] ? 8'd0 : t[`BYTE1];
			o[`BYTE2] = mx[2] ? a[`BYTE2] ^ b[`BYTE2] : zx[2] ? 8'd0 : t[`BYTE2];
			o[`BYTE3] = mx[3] ? a[`BYTE3] ^ b[`BYTE3] : zx[3] ? 8'd0 : t[`BYTE3];
			o[`BYTE4] = mx[4] ? a[`BYTE4] ^ b[`BYTE4] : zx[4] ? 8'd0 : t[`BYTE4];
			o[`BYTE5] = mx[5] ? a[`BYTE5] ^ b[`BYTE5] : zx[5] ? 8'd0 : t[`BYTE5];
			o[`BYTE6] = mx[6] ? a[`BYTE6] ^ b[`BYTE6] : zx[6] ? 8'd0 : t[`BYTE6];
			o[`BYTE7] = mx[7] ? a[`BYTE7] ^ b[`BYTE7] : zx[7] ? 8'd0 : t[`BYTE7];
			o[`BYTE8] = mx[8] ? a[`BYTE8] ^ b[`BYTE8] : zx[8] ? 8'd0 : t[`BYTE8];
			o[`BYTE9] = mx[9] ? a[`BYTE9] ^ b[`BYTE9] : zx[9] ? 8'd0 : t[`BYTE9];
			o[`BYTE10] = mx[10] ? a[`BYTE10] ^ b[`BYTE10] : zx[10] ? 8'd0 : t[`BYTE10];
			o[`BYTE11] = mx[11] ? a[`BYTE11] ^ b[`BYTE11] : zx[11] ? 8'd0 : t[`BYTE11];
			o[`BYTE12] = mx[12] ? a[`BYTE12] ^ b[`BYTE12] : zx[12] ? 8'd0 : t[`BYTE12];
			o[`BYTE13] = mx[13] ? a[`BYTE13] ^ b[`BYTE13] : zx[13] ? 8'd0 : t[`BYTE13];
			o[`BYTE14] = mx[14] ? a[`BYTE14] ^ b[`BYTE14] : zx[14] ? 8'd0 : t[`BYTE14];
			o[`BYTE15] = mx[15] ? a[`BYTE15] ^ b[`BYTE15] : zx[15] ? 8'd0 : t[`BYTE15];
			o[`BYTE16] = mx[16] ? a[`BYTE16] ^ b[`BYTE16] : zx[16] ? 8'd0 : t[`BYTE16];
			o[`BYTE17] = mx[17] ? a[`BYTE17] ^ b[`BYTE17] : zx[17] ? 8'd0 : t[`BYTE17];
			o[`BYTE18] = mx[18] ? a[`BYTE18] ^ b[`BYTE18] : zx[18] ? 8'd0 : t[`BYTE18];
			o[`BYTE19] = mx[19] ? a[`BYTE19] ^ b[`BYTE19] : zx[19] ? 8'd0 : t[`BYTE19];
			o[`BYTE20] = mx[20] ? a[`BYTE20] ^ b[`BYTE20] : zx[20] ? 8'd0 : t[`BYTE20];
			o[`BYTE21] = mx[21] ? a[`BYTE21] ^ b[`BYTE21] : zx[21] ? 8'd0 : t[`BYTE21];
			o[`BYTE22] = mx[22] ? a[`BYTE22] ^ b[`BYTE22] : zx[22] ? 8'd0 : t[`BYTE22];
			o[`BYTE23] = mx[23] ? a[`BYTE23] ^ b[`BYTE23] : zx[23] ? 8'd0 : t[`BYTE23];
			o[`BYTE24] = mx[24] ? a[`BYTE24] ^ b[`BYTE24] : zx[24] ? 8'd0 : t[`BYTE24];
			o[`BYTE25] = mx[25] ? a[`BYTE25] ^ b[`BYTE25] : zx[25] ? 8'd0 : t[`BYTE25];
			o[`BYTE26] = mx[26] ? a[`BYTE26] ^ b[`BYTE26] : zx[26] ? 8'd0 : t[`BYTE26];
			o[`BYTE27] = mx[27] ? a[`BYTE27] ^ b[`BYTE27] : zx[27] ? 8'd0 : t[`BYTE27];
			o[`BYTE28] = mx[28] ? a[`BYTE28] ^ b[`BYTE28] : zx[28] ? 8'd0 : t[`BYTE28];
			o[`BYTE29] = mx[29] ? a[`BYTE29] ^ b[`BYTE29] : zx[29] ? 8'd0 : t[`BYTE29];
			o[`BYTE30] = mx[30] ? a[`BYTE30] ^ b[`BYTE30] : zx[30] ? 8'd0 : t[`BYTE30];
			o[`BYTE31] = mx[31] ? a[`BYTE31] ^ b[`BYTE31] : zx[31] ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
			o[`WYDE0] = mx[0] ? a[`WYDE0] ^ b[`WYDE0] : zx[0] ? 16'd0 : t[`WYDE0];
			o[`WYDE1] = mx[1] ? a[`WYDE1] ^ b[`WYDE1] : zx[1] ? 16'd0 : t[`WYDE1];
			o[`WYDE2] = mx[2] ? a[`WYDE2] ^ b[`WYDE2] : zx[2] ? 16'd0 : t[`WYDE2];
			o[`WYDE3] = mx[3] ? a[`WYDE3] ^ b[`WYDE3] : zx[3] ? 16'd0 : t[`WYDE3];
			o[`WYDE4] = mx[4] ? a[`WYDE4] ^ b[`WYDE4] : zx[4] ? 16'd0 : t[`WYDE4];
			o[`WYDE5] = mx[5] ? a[`WYDE5] ^ b[`WYDE5] : zx[5] ? 16'd0 : t[`WYDE5];
			o[`WYDE6] = mx[6] ? a[`WYDE6] ^ b[`WYDE6] : zx[6] ? 16'd0 : t[`WYDE6];
			o[`WYDE7] = mx[7] ? a[`WYDE7] ^ b[`WYDE7] : zx[7] ? 16'd0 : t[`WYDE7];
			o[`WYDE8] = mx[8] ? a[`WYDE8] ^ b[`WYDE8] : zx[8] ? 16'd0 : t[`WYDE8];
			o[`WYDE9] = mx[9] ? a[`WYDE9] ^ b[`WYDE9] : zx[9] ? 16'd0 : t[`WYDE9];
			o[`WYDE10] = mx[10] ? a[`WYDE10] ^ b[`WYDE10] : zx[10] ? 16'd0 : t[`WYDE10];
			o[`WYDE11] = mx[11] ? a[`WYDE11] ^ b[`WYDE11] : zx[11] ? 16'd0 : t[`WYDE11];
			o[`WYDE12] = mx[12] ? a[`WYDE12] ^ b[`WYDE12] : zx[12] ? 16'd0 : t[`WYDE12];
			o[`WYDE13] = mx[13] ? a[`WYDE13] ^ b[`WYDE13] : zx[13] ? 16'd0 : t[`WYDE13];
			o[`WYDE14] = mx[14] ? a[`WYDE14] ^ b[`WYDE14] : zx[14] ? 16'd0 : t[`WYDE14];
			o[`WYDE15] = mx[15] ? a[`WYDE15] ^ b[`WYDE15] : zx[15] ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
			o[`TETRA0] = mx[0] ? a[`TETRA0] ^ b[`TETRA0] : zx[0] ? 32'd0 : t[`TETRA0];
			o[`TETRA1] = mx[1] ? a[`TETRA1] ^ b[`TETRA1] : zx[1] ? 32'd0 : t[`TETRA1];
			o[`TETRA2] = mx[2] ? a[`TETRA2] ^ b[`TETRA2] : zx[2] ? 32'd0 : t[`TETRA2];
			o[`TETRA3] = mx[3] ? a[`TETRA3] ^ b[`TETRA3] : zx[3] ? 32'd0 : t[`TETRA3];
			o[`TETRA4] = mx[4] ? a[`TETRA4] ^ b[`TETRA4] : zx[4] ? 32'd0 : t[`TETRA4];
			o[`TETRA5] = mx[5] ? a[`TETRA5] ^ b[`TETRA5] : zx[5] ? 32'd0 : t[`TETRA5];
			o[`TETRA6] = mx[6] ? a[`TETRA6] ^ b[`TETRA6] : zx[6] ? 32'd0 : t[`TETRA6];
			o[`TETRA7] = mx[7] ? a[`TETRA7] ^ b[`TETRA7] : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para:
		begin
			o[`OCTA0] = mx[0] ? a[`OCTA0] ^ b[`OCTA0] : zx[0] ? 64'd0 : t[`OCTA0];
			o[`OCTA1] = mx[1] ? a[`OCTA1] ^ b[`OCTA1] : zx[1] ? 64'd0 : t[`OCTA1];
			o[`OCTA2] = mx[2] ? a[`OCTA2] ^ b[`OCTA2] : zx[2] ? 64'd0 : t[`OCTA2];
			o[`OCTA3] = mx[3] ? a[`OCTA3] ^ b[`OCTA3] : zx[3] ? 64'd0 : t[`OCTA3];
		end
	hexi_para:
		begin
			o[`HEXI0] = mx[0] ? a[`HEXI0] ^ b[`HEXI0] : zx[0] ? 128'd0 : t[`HEXI0];
			o[`HEXI1] = mx[1] ? a[`HEXI1] ^ b[`HEXI1] : zx[1] ? 128'd0 : t[`HEXI1];
		end
	default:
		o = a ^ b;
	endcase
end
endtask

task tskNand;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	case(fmt)
	byt:		o = {t[`HEXI1],120'd0,~(a[`BYTE0] & b[`BYTE0])};
	wyde:		o = {t[`HEXI1],112'd0,~(a[`WYDE0] & b[`WYDE0])};
	tetra:	o = {t[`HEXI1],96'd0,~(a[`TETRA0] & b[`TETRA0])};
	octa:		o = {t[`HEXI1],64'd0,~(a[`OCTA0] & b[`OCTA0])};
	hexi:		o = {t[`HEXI1],~(a[`HEXI0] & b[`HEXI0])};
	byte_para:
		begin
		o[`BYTE0] = mx[0] ? ~(a[`BYTE0] & b[`BYTE0]) : zx[0] ? 8'd0 : t[`BYTE0];
		o[`BYTE1] = mx[1] ? ~(a[`BYTE1] & b[`BYTE1]) : zx[1] ? 8'd0 : t[`BYTE1];
		o[`BYTE2] = mx[2] ? ~(a[`BYTE2] & b[`BYTE2]) : zx[2] ? 8'd0 : t[`BYTE2];
		o[`BYTE3] = mx[3] ? ~(a[`BYTE3] & b[`BYTE3]) : zx[3] ? 8'd0 : t[`BYTE3];
		o[`BYTE4] = mx[4] ? ~(a[`BYTE4] & b[`BYTE4]) : zx[4] ? 8'd0 : t[`BYTE4];
		o[`BYTE5] = mx[5] ? ~(a[`BYTE5] & b[`BYTE5]) : zx[5] ? 8'd0 : t[`BYTE5];
		o[`BYTE6] = mx[6] ? ~(a[`BYTE6] & b[`BYTE6]) : zx[6] ? 8'd0 : t[`BYTE6];
		o[`BYTE7] = mx[7] ? ~(a[`BYTE7] & b[`BYTE7]) : zx[7] ? 8'd0 : t[`BYTE7];
		o[`BYTE8] = mx[8] ? ~(a[`BYTE8] & b[`BYTE8]) : zx[8] ? 8'd0 : t[`BYTE8];
		o[`BYTE9] = mx[9] ? ~(a[`BYTE9] & b[`BYTE9]) : zx[9] ? 8'd0 : t[`BYTE9];
		o[`BYTE10] = mx[10] ? ~(a[`BYTE10] & b[`BYTE10]) : zx[10] ? 8'd0 : t[`BYTE10];
		o[`BYTE11] = mx[11] ? ~(a[`BYTE11] & b[`BYTE11]) : zx[11] ? 8'd0 : t[`BYTE11];
		o[`BYTE12] = mx[12] ? ~(a[`BYTE12] & b[`BYTE12]) : zx[12] ? 8'd0 : t[`BYTE12];
		o[`BYTE13] = mx[13] ? ~(a[`BYTE13] & b[`BYTE13]) : zx[13] ? 8'd0 : t[`BYTE13];
		o[`BYTE14] = mx[14] ? ~(a[`BYTE14] & b[`BYTE14]) : zx[14] ? 8'd0 : t[`BYTE14];
		o[`BYTE15] = mx[15] ? ~(a[`BYTE15] & b[`BYTE15]) : zx[15] ? 8'd0 : t[`BYTE15];
		o[`BYTE16] = mx[16] ? ~(a[`BYTE16] & b[`BYTE16]) : zx[16] ? 8'd0 : t[`BYTE16];
		o[`BYTE17] = mx[17] ? ~(a[`BYTE17] & b[`BYTE17]) : zx[17] ? 8'd0 : t[`BYTE17];
		o[`BYTE18] = mx[18] ? ~(a[`BYTE18] & b[`BYTE18]) : zx[18] ? 8'd0 : t[`BYTE18];
		o[`BYTE19] = mx[19] ? ~(a[`BYTE19] & b[`BYTE19]) : zx[19] ? 8'd0 : t[`BYTE19];
		o[`BYTE20] = mx[20] ? ~(a[`BYTE20] & b[`BYTE20]) : zx[20] ? 8'd0 : t[`BYTE20];
		o[`BYTE21] = mx[21] ? ~(a[`BYTE21] & b[`BYTE21]) : zx[21] ? 8'd0 : t[`BYTE21];
		o[`BYTE22] = mx[22] ? ~(a[`BYTE22] & b[`BYTE22]) : zx[22] ? 8'd0 : t[`BYTE22];
		o[`BYTE23] = mx[23] ? ~(a[`BYTE23] & b[`BYTE23]) : zx[23] ? 8'd0 : t[`BYTE23];
		o[`BYTE24] = mx[24] ? ~(a[`BYTE24] & b[`BYTE24]) : zx[24] ? 8'd0 : t[`BYTE24];
		o[`BYTE25] = mx[25] ? ~(a[`BYTE25] & b[`BYTE25]) : zx[25] ? 8'd0 : t[`BYTE25];
		o[`BYTE26] = mx[26] ? ~(a[`BYTE26] & b[`BYTE26]) : zx[26] ? 8'd0 : t[`BYTE26];
		o[`BYTE27] = mx[27] ? ~(a[`BYTE27] & b[`BYTE27]) : zx[27] ? 8'd0 : t[`BYTE27];
		o[`BYTE28] = mx[28] ? ~(a[`BYTE28] & b[`BYTE28]) : zx[28] ? 8'd0 : t[`BYTE28];
		o[`BYTE29] = mx[29] ? ~(a[`BYTE29] & b[`BYTE29]) : zx[29] ? 8'd0 : t[`BYTE29];
		o[`BYTE30] = mx[30] ? ~(a[`BYTE30] & b[`BYTE30]) : zx[30] ? 8'd0 : t[`BYTE30];
		o[`BYTE31] = mx[31] ? ~(a[`BYTE31] & b[`BYTE31]) : zx[31] ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
		o[`WYDE0] = mx[0] ? ~(a[`WYDE0] & b[`WYDE0]) : zx[0] ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = mx[1] ? ~(a[`WYDE1] & b[`WYDE1]) : zx[1] ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = mx[2] ? ~(a[`WYDE2] & b[`WYDE2]) : zx[2] ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = mx[3] ? ~(a[`WYDE3] & b[`WYDE3]) : zx[3] ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = mx[4] ? ~(a[`WYDE4] & b[`WYDE4]) : zx[4] ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = mx[5] ? ~(a[`WYDE5] & b[`WYDE5]) : zx[5] ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = mx[6] ? ~(a[`WYDE6] & b[`WYDE6]) : zx[6] ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = mx[7] ? ~(a[`WYDE7] & b[`WYDE7]) : zx[7] ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = mx[8] ? ~(a[`WYDE8] & b[`WYDE8]) : zx[8] ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = mx[9] ? ~(a[`WYDE9] & b[`WYDE9]) : zx[9] ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = mx[10] ? ~(a[`WYDE10] & b[`WYDE10]) : zx[10] ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = mx[11] ? ~(a[`WYDE11] & b[`WYDE11]) : zx[11] ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = mx[12] ? ~(a[`WYDE12] & b[`WYDE12]) : zx[12] ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = mx[13] ? ~(a[`WYDE13] & b[`WYDE13]) : zx[13] ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = mx[14] ? ~(a[`WYDE14] & b[`WYDE14]) : zx[14] ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = mx[15] ? ~(a[`WYDE15] & b[`WYDE15]) : zx[15] ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = mx[0] ? ~(a[`TETRA0] & b[`TETRA0]) : zx[0] ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = mx[1] ? ~(a[`TETRA1] & b[`TETRA1]) : zx[1] ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = mx[2] ? ~(a[`TETRA2] & b[`TETRA2]) : zx[2] ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = mx[3] ? ~(a[`TETRA3] & b[`TETRA3]) : zx[3] ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = mx[4] ? ~(a[`TETRA4] & b[`TETRA4]) : zx[4] ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = mx[5] ? ~(a[`TETRA5] & b[`TETRA5]) : zx[5] ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = mx[6] ? ~(a[`TETRA6] & b[`TETRA6]) : zx[6] ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = mx[7] ? ~(a[`TETRA7] & b[`TETRA7]) : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = mx[0] ? ~(a[`OCTA0] & b[`OCTA0]) : zx[0] ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = mx[1] ? ~(a[`OCTA1] & b[`OCTA1]) : zx[1] ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = mx[2] ? ~(a[`OCTA2] & b[`OCTA2]) : zx[2] ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = mx[3] ? ~(a[`OCTA3] & b[`OCTA3]) : zx[3] ? 64'd0 : t[`OCTA3];
		end
hexi_para:
	begin
		o[`HEXI0] = mx[0] ? ~(a[`HEXI0] & b[`HEXI0]) : zx[0] ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = mx[1] ? ~(a[`HEXI1] & b[`HEXI1]) : zx[1] ? 128'd0 : t[`HEXI1];
		end
	default:
		o = ~(a & b);
	endcase
end
endtask

task tskNor;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	case(fmt)
	byt:		o = {t[`HEXI1],120'd0,~(a[`BYTE0] | b[`BYTE0])};
	wyde:		o = {t[`HEXI1],112'd0,~(a[`WYDE0] | b[`WYDE0])};
	tetra:	o = {t[`HEXI1],96'd0,~(a[`TETRA0] | b[`TETRA0])};
	octa:		o = {t[`HEXI1],64'd0,~(a[`OCTA0] | b[`OCTA0])};
	hexi:		o = {t[`HEXI1],~(a[`HEXI0] | b[`HEXI0])};
	byte_para:
		begin
		o[`BYTE0] = mx[0] ? ~(a[`BYTE0] | b[`BYTE0]) : zx[0] ? 8'd0 : t[`BYTE0];
		o[`BYTE1] = mx[1] ? ~(a[`BYTE1] | b[`BYTE1]) : zx[1] ? 8'd0 : t[`BYTE1];
		o[`BYTE2] = mx[2] ? ~(a[`BYTE2] | b[`BYTE2]) : zx[2] ? 8'd0 : t[`BYTE2];
		o[`BYTE3] = mx[3] ? ~(a[`BYTE3] | b[`BYTE3]) : zx[3] ? 8'd0 : t[`BYTE3];
		o[`BYTE4] = mx[4] ? ~(a[`BYTE4] | b[`BYTE4]) : zx[4] ? 8'd0 : t[`BYTE4];
		o[`BYTE5] = mx[5] ? ~(a[`BYTE5] | b[`BYTE5]) : zx[5] ? 8'd0 : t[`BYTE5];
		o[`BYTE6] = mx[6] ? ~(a[`BYTE6] | b[`BYTE6]) : zx[6] ? 8'd0 : t[`BYTE6];
		o[`BYTE7] = mx[7] ? ~(a[`BYTE7] | b[`BYTE7]) : zx[7] ? 8'd0 : t[`BYTE7];
		o[`BYTE8] = mx[8] ? ~(a[`BYTE8] | b[`BYTE8]) : zx[8] ? 8'd0 : t[`BYTE8];
		o[`BYTE9] = mx[9] ? ~(a[`BYTE9] | b[`BYTE9]) : zx[9] ? 8'd0 : t[`BYTE9];
		o[`BYTE10] = mx[10] ? ~(a[`BYTE10] | b[`BYTE10]) : zx[10] ? 8'd0 : t[`BYTE10];
		o[`BYTE11] = mx[11] ? ~(a[`BYTE11] | b[`BYTE11]) : zx[11] ? 8'd0 : t[`BYTE11];
		o[`BYTE12] = mx[12] ? ~(a[`BYTE12] | b[`BYTE12]) : zx[12] ? 8'd0 : t[`BYTE12];
		o[`BYTE13] = mx[13] ? ~(a[`BYTE13] | b[`BYTE13]) : zx[13] ? 8'd0 : t[`BYTE13];
		o[`BYTE14] = mx[14] ? ~(a[`BYTE14] | b[`BYTE14]) : zx[14] ? 8'd0 : t[`BYTE14];
		o[`BYTE15] = mx[15] ? ~(a[`BYTE15] | b[`BYTE15]) : zx[15] ? 8'd0 : t[`BYTE15];
		o[`BYTE16] = mx[16] ? ~(a[`BYTE16] | b[`BYTE16]) : zx[16] ? 8'd0 : t[`BYTE16];
		o[`BYTE17] = mx[17] ? ~(a[`BYTE17] | b[`BYTE17]) : zx[17] ? 8'd0 : t[`BYTE17];
		o[`BYTE18] = mx[18] ? ~(a[`BYTE18] | b[`BYTE18]) : zx[18] ? 8'd0 : t[`BYTE18];
		o[`BYTE19] = mx[19] ? ~(a[`BYTE19] | b[`BYTE19]) : zx[19] ? 8'd0 : t[`BYTE19];
		o[`BYTE20] = mx[20] ? ~(a[`BYTE20] | b[`BYTE20]) : zx[20] ? 8'd0 : t[`BYTE20];
		o[`BYTE21] = mx[21] ? ~(a[`BYTE21] | b[`BYTE21]) : zx[21] ? 8'd0 : t[`BYTE21];
		o[`BYTE22] = mx[22] ? ~(a[`BYTE22] | b[`BYTE22]) : zx[22] ? 8'd0 : t[`BYTE22];
		o[`BYTE23] = mx[23] ? ~(a[`BYTE23] | b[`BYTE23]) : zx[23] ? 8'd0 : t[`BYTE23];
		o[`BYTE24] = mx[24] ? ~(a[`BYTE24] | b[`BYTE24]) : zx[24] ? 8'd0 : t[`BYTE24];
		o[`BYTE25] = mx[25] ? ~(a[`BYTE25] | b[`BYTE25]) : zx[25] ? 8'd0 : t[`BYTE25];
		o[`BYTE26] = mx[26] ? ~(a[`BYTE26] | b[`BYTE26]) : zx[26] ? 8'd0 : t[`BYTE26];
		o[`BYTE27] = mx[27] ? ~(a[`BYTE27] | b[`BYTE27]) : zx[27] ? 8'd0 : t[`BYTE27];
		o[`BYTE28] = mx[28] ? ~(a[`BYTE28] | b[`BYTE28]) : zx[28] ? 8'd0 : t[`BYTE28];
		o[`BYTE29] = mx[29] ? ~(a[`BYTE29] | b[`BYTE29]) : zx[29] ? 8'd0 : t[`BYTE29];
		o[`BYTE30] = mx[30] ? ~(a[`BYTE30] | b[`BYTE30]) : zx[30] ? 8'd0 : t[`BYTE30];
		o[`BYTE31] = mx[31] ? ~(a[`BYTE31] | b[`BYTE31]) : zx[31] ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
		o[`WYDE0] = mx[0] ? ~(a[`WYDE0] | b[`WYDE0]) : zx[0] ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = mx[1] ? ~(a[`WYDE1] | b[`WYDE1]) : zx[1] ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = mx[2] ? ~(a[`WYDE2] | b[`WYDE2]) : zx[2] ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = mx[3] ? ~(a[`WYDE3] | b[`WYDE3]) : zx[3] ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = mx[4] ? ~(a[`WYDE4] | b[`WYDE4]) : zx[4] ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = mx[5] ? ~(a[`WYDE5] | b[`WYDE5]) : zx[5] ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = mx[6] ? ~(a[`WYDE6] | b[`WYDE6]) : zx[6] ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = mx[7] ? ~(a[`WYDE7] | b[`WYDE7]) : zx[7] ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = mx[8] ? ~(a[`WYDE8] | b[`WYDE8]) : zx[8] ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = mx[9] ? ~(a[`WYDE9] | b[`WYDE9]) : zx[9] ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = mx[10] ? ~(a[`WYDE10] | b[`WYDE10]) : zx[10] ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = mx[11] ? ~(a[`WYDE11] | b[`WYDE11]) : zx[11] ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = mx[12] ? ~(a[`WYDE12] | b[`WYDE12]) : zx[12] ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = mx[13] ? ~(a[`WYDE13] | b[`WYDE13]) : zx[13] ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = mx[14] ? ~(a[`WYDE14] | b[`WYDE14]) : zx[14] ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = mx[15] ? ~(a[`WYDE15] | b[`WYDE15]) : zx[15] ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = mx[0] ? ~(a[`TETRA0] | b[`TETRA0]) : zx[0] ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = mx[1] ? ~(a[`TETRA1] | b[`TETRA1]) : zx[1] ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = mx[2] ? ~(a[`TETRA2] | b[`TETRA2]) : zx[2] ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = mx[3] ? ~(a[`TETRA3] | b[`TETRA3]) : zx[3] ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = mx[4] ? ~(a[`TETRA4] | b[`TETRA4]) : zx[4] ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = mx[5] ? ~(a[`TETRA5] | b[`TETRA5]) : zx[5] ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = mx[6] ? ~(a[`TETRA6] | b[`TETRA6]) : zx[6] ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = mx[7] ? ~(a[`TETRA7] | b[`TETRA7]) : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = mx[0] ? ~(a[`OCTA0] | b[`OCTA0]) : zx[0] ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = mx[1] ? ~(a[`OCTA1] | b[`OCTA1]) : zx[1] ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = mx[2] ? ~(a[`OCTA2] | b[`OCTA2]) : zx[2] ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = mx[3] ? ~(a[`OCTA3] | b[`OCTA3]) : zx[3] ? 64'd0 : t[`OCTA3];
		end
hexi_para:
	begin
		o[`HEXI0] = mx[0] ? ~(a[`HEXI0] | b[`HEXI0]) : zx[0] ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = mx[1] ? ~(a[`HEXI1] | b[`HEXI1]) : zx[1] ? 128'd0 : t[`HEXI1];
		end
	default:
		o = ~(a | b);
	endcase
end
endtask

task tskXnor;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	case(fmt)
	byt:		o = {t[`HEXI1],120'd0,~(a[`BYTE0] ^ b[`BYTE0])};
	wyde:		o = {t[`HEXI1],112'd0,~(a[`WYDE0] ^ b[`WYDE0])};
	tetra:	o = {t[`HEXI1],96'd0,~(a[`TETRA0] ^ b[`TETRA0])};
	octa:		o = {t[`HEXI1],64'd0,~(a[`OCTA0] ^ b[`OCTA0])};
	hexi:		o = {t[`HEXI1],~(a[`HEXI0] ^ b[`HEXI0])};
	byte_para:
		begin
		o[`BYTE0] = mx[0] ? ~(a[`BYTE0] ^ b[`BYTE0]) : zx[0] ? 8'd0 : t[`BYTE0];
		o[`BYTE1] = mx[1] ? ~(a[`BYTE1] ^ b[`BYTE1]) : zx[1] ? 8'd0 : t[`BYTE1];
		o[`BYTE2] = mx[2] ? ~(a[`BYTE2] ^ b[`BYTE2]) : zx[2] ? 8'd0 : t[`BYTE2];
		o[`BYTE3] = mx[3] ? ~(a[`BYTE3] ^ b[`BYTE3]) : zx[3] ? 8'd0 : t[`BYTE3];
		o[`BYTE4] = mx[4] ? ~(a[`BYTE4] ^ b[`BYTE4]) : zx[4] ? 8'd0 : t[`BYTE4];
		o[`BYTE5] = mx[5] ? ~(a[`BYTE5] ^ b[`BYTE5]) : zx[5] ? 8'd0 : t[`BYTE5];
		o[`BYTE6] = mx[6] ? ~(a[`BYTE6] ^ b[`BYTE6]) : zx[6] ? 8'd0 : t[`BYTE6];
		o[`BYTE7] = mx[7] ? ~(a[`BYTE7] ^ b[`BYTE7]) : zx[7] ? 8'd0 : t[`BYTE7];
		o[`BYTE8] = mx[8] ? ~(a[`BYTE8] ^ b[`BYTE8]) : zx[8] ? 8'd0 : t[`BYTE8];
		o[`BYTE9] = mx[9] ? ~(a[`BYTE9] ^ b[`BYTE9]) : zx[9] ? 8'd0 : t[`BYTE9];
		o[`BYTE10] = mx[10] ? ~(a[`BYTE10] ^ b[`BYTE10]) : zx[10] ? 8'd0 : t[`BYTE10];
		o[`BYTE11] = mx[11] ? ~(a[`BYTE11] ^ b[`BYTE11]) : zx[11] ? 8'd0 : t[`BYTE11];
		o[`BYTE12] = mx[12] ? ~(a[`BYTE12] ^ b[`BYTE12]) : zx[12] ? 8'd0 : t[`BYTE12];
		o[`BYTE13] = mx[13] ? ~(a[`BYTE13] ^ b[`BYTE13]) : zx[13] ? 8'd0 : t[`BYTE13];
		o[`BYTE14] = mx[14] ? ~(a[`BYTE14] ^ b[`BYTE14]) : zx[14] ? 8'd0 : t[`BYTE14];
		o[`BYTE15] = mx[15] ? ~(a[`BYTE15] ^ b[`BYTE15]) : zx[15] ? 8'd0 : t[`BYTE15];
		o[`BYTE16] = mx[16] ? ~(a[`BYTE16] ^ b[`BYTE16]) : zx[16] ? 8'd0 : t[`BYTE16];
		o[`BYTE17] = mx[17] ? ~(a[`BYTE17] ^ b[`BYTE17]) : zx[17] ? 8'd0 : t[`BYTE17];
		o[`BYTE18] = mx[18] ? ~(a[`BYTE18] ^ b[`BYTE18]) : zx[18] ? 8'd0 : t[`BYTE18];
		o[`BYTE19] = mx[19] ? ~(a[`BYTE19] ^ b[`BYTE19]) : zx[19] ? 8'd0 : t[`BYTE19];
		o[`BYTE20] = mx[20] ? ~(a[`BYTE20] ^ b[`BYTE20]) : zx[20] ? 8'd0 : t[`BYTE20];
		o[`BYTE21] = mx[21] ? ~(a[`BYTE21] ^ b[`BYTE21]) : zx[21] ? 8'd0 : t[`BYTE21];
		o[`BYTE22] = mx[22] ? ~(a[`BYTE22] ^ b[`BYTE22]) : zx[22] ? 8'd0 : t[`BYTE22];
		o[`BYTE23] = mx[23] ? ~(a[`BYTE23] ^ b[`BYTE23]) : zx[23] ? 8'd0 : t[`BYTE23];
		o[`BYTE24] = mx[24] ? ~(a[`BYTE24] ^ b[`BYTE24]) : zx[24] ? 8'd0 : t[`BYTE24];
		o[`BYTE25] = mx[25] ? ~(a[`BYTE25] ^ b[`BYTE25]) : zx[25] ? 8'd0 : t[`BYTE25];
		o[`BYTE26] = mx[26] ? ~(a[`BYTE26] ^ b[`BYTE26]) : zx[26] ? 8'd0 : t[`BYTE26];
		o[`BYTE27] = mx[27] ? ~(a[`BYTE27] ^ b[`BYTE27]) : zx[27] ? 8'd0 : t[`BYTE27];
		o[`BYTE28] = mx[28] ? ~(a[`BYTE28] ^ b[`BYTE28]) : zx[28] ? 8'd0 : t[`BYTE28];
		o[`BYTE29] = mx[29] ? ~(a[`BYTE29] ^ b[`BYTE29]) : zx[29] ? 8'd0 : t[`BYTE29];
		o[`BYTE30] = mx[30] ? ~(a[`BYTE30] ^ b[`BYTE30]) : zx[30] ? 8'd0 : t[`BYTE30];
		o[`BYTE31] = mx[31] ? ~(a[`BYTE31] ^ b[`BYTE31]) : zx[31] ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
		o[`WYDE0] = mx[0] ? ~(a[`WYDE0] ^ b[`WYDE0]) : zx[0] ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = mx[1] ? ~(a[`WYDE1] ^ b[`WYDE1]) : zx[1] ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = mx[2] ? ~(a[`WYDE2] ^ b[`WYDE2]) : zx[2] ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = mx[3] ? ~(a[`WYDE3] ^ b[`WYDE3]) : zx[3] ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = mx[4] ? ~(a[`WYDE4] ^ b[`WYDE4]) : zx[4] ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = mx[5] ? ~(a[`WYDE5] ^ b[`WYDE5]) : zx[5] ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = mx[6] ? ~(a[`WYDE6] ^ b[`WYDE6]) : zx[6] ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = mx[7] ? ~(a[`WYDE7] ^ b[`WYDE7]) : zx[7] ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = mx[8] ? ~(a[`WYDE8] ^ b[`WYDE8]) : zx[8] ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = mx[9] ? ~(a[`WYDE9] ^ b[`WYDE9]) : zx[9] ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = mx[10] ? ~(a[`WYDE10] ^ b[`WYDE10]) : zx[10] ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = mx[11] ? ~(a[`WYDE11] ^ b[`WYDE11]) : zx[11] ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = mx[12] ? ~(a[`WYDE12] ^ b[`WYDE12]) : zx[12] ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = mx[13] ? ~(a[`WYDE13] ^ b[`WYDE13]) : zx[13] ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = mx[14] ? ~(a[`WYDE14] ^ b[`WYDE14]) : zx[14] ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = mx[15] ? ~(a[`WYDE15] ^ b[`WYDE15]) : zx[15] ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = mx[0] ? ~(a[`TETRA0] ^ b[`TETRA0]) : zx[0] ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = mx[1] ? ~(a[`TETRA1] ^ b[`TETRA1]) : zx[1] ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = mx[2] ? ~(a[`TETRA2] ^ b[`TETRA2]) : zx[2] ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = mx[3] ? ~(a[`TETRA3] ^ b[`TETRA3]) : zx[3] ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = mx[4] ? ~(a[`TETRA4] ^ b[`TETRA4]) : zx[4] ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = mx[5] ? ~(a[`TETRA5] ^ b[`TETRA5]) : zx[5] ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = mx[6] ? ~(a[`TETRA6] ^ b[`TETRA6]) : zx[6] ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = mx[7] ? ~(a[`TETRA7] ^ b[`TETRA7]) : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = mx[0] ? ~(a[`OCTA0] ^ b[`OCTA0]) : zx[0] ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = mx[1] ? ~(a[`OCTA1] ^ b[`OCTA1]) : zx[1] ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = mx[2] ? ~(a[`OCTA2] ^ b[`OCTA2]) : zx[2] ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = mx[3] ? ~(a[`OCTA3] ^ b[`OCTA3]) : zx[3] ? 64'd0 : t[`OCTA3];
		end
hexi_para:
	begin
		o[`HEXI0] = mx[0] ? ~(a[`HEXI0] ^ b[`HEXI0]) : zx[0] ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = mx[1] ? ~(a[`HEXI1] ^ b[`HEXI1]) : zx[1] ? 128'd0 : t[`HEXI1];
		end
	default:
		o = ~(a ^ b);
	endcase
end
endtask

task tskMin;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	if (BIG)
	case(fmt)
	byt:	o[`BYTE0] = $signed(a[`BYTE0]) < $signed(b[`BYTE0]) ? a[`BYTE0] : b[`BYTE0];
	wyde:	o[`WYDE0] = $signed(a[`WYDE0]) < $signed(b[`WYDE0]) ? a[`WYDE0] : b[`WYDE0];
	tetra:	o[`TETRA0] = $signed(a[`TETRA0]) < $signed(b[`TETRA0]) ? a[`TETRA0] : b[`TETRA0];
	octa:	o[`OCTA0] = $signed(a[`OCTA0]) < $signed(b[`OCTA0]) ? a[`OCTA0] : b[`OCTA0];
	hexi:	o[`HEXI0] = $signed(a[`HEXI0]) < $signed(b[`HEXI0]) ? a[`HEXI0] : b[`HEXI0];
	3'd5: o = $signed(a) < $signed(b) ? a : b;
	byte_para:
		begin
		o[`BYTE0] = mx[0] ? ($signed(a[`BYTE0]) < $signed(b[`BYTE0]) ? a[`BYTE0] : b[`BYTE0]) : zx[0] ? 8'd0 : t[`BYTE0];
		o[`BYTE1] = mx[1] ? ($signed(a[`BYTE1]) < $signed(b[`BYTE1]) ? a[`BYTE1] : b[`BYTE1]) : zx[1] ? 8'd0 : t[`BYTE1];
		o[`BYTE2] = mx[2] ? ($signed(a[`BYTE2]) < $signed(b[`BYTE2]) ? a[`BYTE2] : b[`BYTE2]) : zx[2] ? 8'd0 : t[`BYTE2];
		o[`BYTE3] = mx[3] ? ($signed(a[`BYTE3]) < $signed(b[`BYTE3]) ? a[`BYTE3] : b[`BYTE3]) : zx[3] ? 8'd0 : t[`BYTE3];
		o[`BYTE4] = mx[4] ? ($signed(a[`BYTE4]) < $signed(b[`BYTE4]) ? a[`BYTE4] : b[`BYTE4]) : zx[4] ? 8'd0 : t[`BYTE4];
		o[`BYTE5] = mx[5] ? ($signed(a[`BYTE5]) < $signed(b[`BYTE5]) ? a[`BYTE5] : b[`BYTE5]) : zx[5] ? 8'd0 : t[`BYTE5];
		o[`BYTE6] = mx[6] ? ($signed(a[`BYTE6]) < $signed(b[`BYTE6]) ? a[`BYTE6] : b[`BYTE6]) : zx[6] ? 8'd0 : t[`BYTE6];
		o[`BYTE7] = mx[7] ? ($signed(a[`BYTE7]) < $signed(b[`BYTE7]) ? a[`BYTE7] : b[`BYTE7]) : zx[7] ? 8'd0 : t[`BYTE7];
		o[`BYTE8] = mx[8] ? ($signed(a[`BYTE8]) < $signed(b[`BYTE8]) ? a[`BYTE8] : b[`BYTE8]) : zx[8] ? 8'd0 : t[`BYTE8];
		o[`BYTE9] = mx[9] ? ($signed(a[`BYTE9]) < $signed(b[`BYTE9]) ? a[`BYTE9] : b[`BYTE9]) : zx[9] ? 8'd0 : t[`BYTE9];
		o[`BYTE10] = mx[10] ? ($signed(a[`BYTE10]) < $signed(b[`BYTE10]) ? a[`BYTE10] : b[`BYTE10]) : zx[10] ? 8'd0 : t[`BYTE10];
		o[`BYTE11] = mx[11] ? ($signed(a[`BYTE11]) < $signed(b[`BYTE11]) ? a[`BYTE11] : b[`BYTE11]) : zx[11] ? 8'd0 : t[`BYTE11];
		o[`BYTE12] = mx[12] ? ($signed(a[`BYTE12]) < $signed(b[`BYTE12]) ? a[`BYTE12] : b[`BYTE12]) : zx[12] ? 8'd0 : t[`BYTE12];
		o[`BYTE13] = mx[13] ? ($signed(a[`BYTE13]) < $signed(b[`BYTE13]) ? a[`BYTE13] : b[`BYTE13]) : zx[13] ? 8'd0 : t[`BYTE13];
		o[`BYTE14] = mx[14] ? ($signed(a[`BYTE14]) < $signed(b[`BYTE14]) ? a[`BYTE14] : b[`BYTE14]) : zx[14] ? 8'd0 : t[`BYTE14];
		o[`BYTE15] = mx[15] ? ($signed(a[`BYTE15]) < $signed(b[`BYTE15]) ? a[`BYTE15] : b[`BYTE15]) : zx[15] ? 8'd0 : t[`BYTE15];
		o[`BYTE16] = mx[16] ? ($signed(a[`BYTE16]) < $signed(b[`BYTE16]) ? a[`BYTE16] : b[`BYTE16]) : zx[16] ? 8'd0 : t[`BYTE16];
		o[`BYTE17] = mx[17] ? ($signed(a[`BYTE17]) < $signed(b[`BYTE17]) ? a[`BYTE17] : b[`BYTE17]) : zx[17] ? 8'd0 : t[`BYTE17];
		o[`BYTE18] = mx[18] ? ($signed(a[`BYTE18]) < $signed(b[`BYTE18]) ? a[`BYTE18] : b[`BYTE18]) : zx[18] ? 8'd0 : t[`BYTE18];
		o[`BYTE19] = mx[19] ? ($signed(a[`BYTE19]) < $signed(b[`BYTE19]) ? a[`BYTE19] : b[`BYTE19]) : zx[19] ? 8'd0 : t[`BYTE19];
		o[`BYTE20] = mx[20] ? ($signed(a[`BYTE20]) < $signed(b[`BYTE20]) ? a[`BYTE20] : b[`BYTE20]) : zx[20] ? 8'd0 : t[`BYTE20];
		o[`BYTE21] = mx[21] ? ($signed(a[`BYTE21]) < $signed(b[`BYTE21]) ? a[`BYTE21] : b[`BYTE21]) : zx[21] ? 8'd0 : t[`BYTE21];
		o[`BYTE22] = mx[22] ? ($signed(a[`BYTE22]) < $signed(b[`BYTE22]) ? a[`BYTE22] : b[`BYTE22]) : zx[22] ? 8'd0 : t[`BYTE22];
		o[`BYTE23] = mx[23] ? ($signed(a[`BYTE23]) < $signed(b[`BYTE23]) ? a[`BYTE23] : b[`BYTE23]) : zx[23] ? 8'd0 : t[`BYTE23];
		o[`BYTE24] = mx[24] ? ($signed(a[`BYTE24]) < $signed(b[`BYTE24]) ? a[`BYTE24] : b[`BYTE24]) : zx[24] ? 8'd0 : t[`BYTE24];
		o[`BYTE25] = mx[25] ? ($signed(a[`BYTE25]) < $signed(b[`BYTE25]) ? a[`BYTE25] : b[`BYTE25]) : zx[25] ? 8'd0 : t[`BYTE25];
		o[`BYTE26] = mx[26] ? ($signed(a[`BYTE26]) < $signed(b[`BYTE26]) ? a[`BYTE26] : b[`BYTE26]) : zx[26] ? 8'd0 : t[`BYTE26];
		o[`BYTE27] = mx[27] ? ($signed(a[`BYTE27]) < $signed(b[`BYTE27]) ? a[`BYTE27] : b[`BYTE27]) : zx[27] ? 8'd0 : t[`BYTE27];
		o[`BYTE28] = mx[28] ? ($signed(a[`BYTE28]) < $signed(b[`BYTE28]) ? a[`BYTE28] : b[`BYTE28]) : zx[28] ? 8'd0 : t[`BYTE28];
		o[`BYTE29] = mx[29] ? ($signed(a[`BYTE29]) < $signed(b[`BYTE29]) ? a[`BYTE29] : b[`BYTE29]) : zx[29] ? 8'd0 : t[`BYTE29];
		o[`BYTE30] = mx[30] ? ($signed(a[`BYTE30]) < $signed(b[`BYTE30]) ? a[`BYTE30] : b[`BYTE30]) : zx[30] ? 8'd0 : t[`BYTE30];
		o[`BYTE31] = mx[31] ? ($signed(a[`BYTE31]) < $signed(b[`BYTE31]) ? a[`BYTE31] : b[`BYTE31]) : zx[31] ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
		o[`WYDE0] = mx[0] ? ($signed(a[`WYDE0]) < $signed(b[`WYDE0]) ? a[`WYDE0] : b[`WYDE0]) : zx[0] ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = mx[1] ? ($signed(a[`WYDE1]) < $signed(b[`WYDE1]) ? a[`WYDE1] : b[`WYDE1]) : zx[1] ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = mx[2] ? ($signed(a[`WYDE2]) < $signed(b[`WYDE2]) ? a[`WYDE2] : b[`WYDE2]) : zx[2] ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = mx[3] ? ($signed(a[`WYDE3]) < $signed(b[`WYDE3]) ? a[`WYDE3] : b[`WYDE3]) : zx[3] ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = mx[4] ? ($signed(a[`WYDE4]) < $signed(b[`WYDE4]) ? a[`WYDE4] : b[`WYDE4]) : zx[4] ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = mx[5] ? ($signed(a[`WYDE5]) < $signed(b[`WYDE5]) ? a[`WYDE5] : b[`WYDE5]) : zx[5] ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = mx[6] ? ($signed(a[`WYDE6]) < $signed(b[`WYDE6]) ? a[`WYDE6] : b[`WYDE6]) : zx[6] ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = mx[7] ? ($signed(a[`WYDE7]) < $signed(b[`WYDE7]) ? a[`WYDE7] : b[`WYDE7]) : zx[7] ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = mx[8] ? ($signed(a[`WYDE8]) < $signed(b[`WYDE8]) ? a[`WYDE8] : b[`WYDE8]) : zx[8] ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = mx[9] ? ($signed(a[`WYDE9]) < $signed(b[`WYDE9]) ? a[`WYDE9] : b[`WYDE9]) : zx[9] ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = mx[10] ? ($signed(a[`WYDE10]) < $signed(b[`WYDE10]) ? a[`WYDE10] : b[`WYDE10]) : zx[10] ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = mx[11] ? ($signed(a[`WYDE11]) < $signed(b[`WYDE11]) ? a[`WYDE11] : b[`WYDE11]) : zx[11] ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = mx[12] ? ($signed(a[`WYDE12]) < $signed(b[`WYDE12]) ? a[`WYDE12] : b[`WYDE12]) : zx[12] ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = mx[13] ? ($signed(a[`WYDE13]) < $signed(b[`WYDE13]) ? a[`WYDE13] : b[`WYDE13]) : zx[13] ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = mx[14] ? ($signed(a[`WYDE14]) < $signed(b[`WYDE14]) ? a[`WYDE14] : b[`WYDE14]) : zx[14] ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = mx[15] ? ($signed(a[`WYDE15]) < $signed(b[`WYDE15]) ? a[`WYDE15] : b[`WYDE15]) : zx[15] ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = mx[0] ? ($signed(a[`TETRA0]) < $signed(b[`TETRA0]) ? a[`TETRA0] : b[`TETRA0]) : zx[0] ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = mx[1] ? ($signed(a[`TETRA1]) < $signed(b[`TETRA1]) ? a[`TETRA1] : b[`TETRA1]) : zx[1] ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = mx[2] ? ($signed(a[`TETRA2]) < $signed(b[`TETRA2]) ? a[`TETRA2] : b[`TETRA2]) : zx[2] ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = mx[3] ? ($signed(a[`TETRA3]) < $signed(b[`TETRA3]) ? a[`TETRA3] : b[`TETRA3]) : zx[3] ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = mx[4] ? ($signed(a[`TETRA4]) < $signed(b[`TETRA4]) ? a[`TETRA4] : b[`TETRA4]) : zx[4] ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = mx[5] ? ($signed(a[`TETRA5]) < $signed(b[`TETRA5]) ? a[`TETRA5] : b[`TETRA5]) : zx[5] ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = mx[6] ? ($signed(a[`TETRA6]) < $signed(b[`TETRA6]) ? a[`TETRA6] : b[`TETRA6]) : zx[6] ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = mx[7] ? ($signed(a[`TETRA7]) < $signed(b[`TETRA7]) ? a[`TETRA7] : b[`TETRA7]) : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = mx[0] ? ($signed(a[`OCTA0]) < $signed(b[`OCTA0]) ? a[`OCTA0] : b[`OCTA0]) : zx[0] ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = mx[1] ? ($signed(a[`OCTA1]) < $signed(b[`OCTA1]) ? a[`OCTA1] : b[`OCTA1]) : zx[1] ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = mx[2] ? ($signed(a[`OCTA2]) < $signed(b[`OCTA2]) ? a[`OCTA2] : b[`OCTA2]) : zx[2] ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = mx[3] ? ($signed(a[`OCTA3]) < $signed(b[`OCTA3]) ? a[`OCTA3] : b[`OCTA3]) : zx[3] ? 64'd0 : t[`OCTA3];
		end
//	hexi_para:
	default:
		begin
		o[`HEXI0] = mx[0] ? ($signed(a[`HEXI0]) < $signed(b[`HEXI0]) ? a[`HEXI0] : b[`HEXI0]) : zx[0] ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = mx[1] ? ($signed(a[`HEXI1]) < $signed(b[`HEXI1]) ? a[`HEXI1] : b[`HEXI1]) : zx[1] ? 128'd0 : t[`HEXI1];
		end
	endcase
	else
		o = {64{4'hC}};
end
endtask

task tskMax;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	if (BIG)
	case(fmt)
	byt:	o[`BYTE0] = $signed(a[`BYTE0]) > $signed(b[`BYTE0]) ? a[`BYTE0] : b[`BYTE0];
	wyde:	o[`WYDE0] = $signed(a[`WYDE0]) > $signed(b[`WYDE0]) ? a[`WYDE0] : b[`WYDE0];
	tetra:	o[`TETRA0] = $signed(a[`TETRA0]) > $signed(b[`TETRA0]) ? a[`TETRA0] : b[`TETRA0];
	octa:	o[`OCTA0] = $signed(a[`OCTA0]) > $signed(b[`OCTA0]) ? a[`OCTA0] : b[`OCTA0];
	hexi:	o[`HEXI0] = $signed(a[`HEXI0]) > $signed(b[`HEXI0]) ? a[`HEXI0] : b[`HEXI0];
	3'd5: o = $signed(a) > $signed(b) ? a : b;
	byte_para:
		begin
		o[`BYTE0] = mx[0] ? ($signed(a[`BYTE0]) > $signed(b[`BYTE0]) ? a[`BYTE0] : b[`BYTE0]) : zx[0] ? 8'd0 : t[`BYTE0];
		o[`BYTE1] = mx[1] ? ($signed(a[`BYTE1]) > $signed(b[`BYTE1]) ? a[`BYTE1] : b[`BYTE1]) : zx[1] ? 8'd0 : t[`BYTE1];
		o[`BYTE2] = mx[2] ? ($signed(a[`BYTE2]) > $signed(b[`BYTE2]) ? a[`BYTE2] : b[`BYTE2]) : zx[2] ? 8'd0 : t[`BYTE2];
		o[`BYTE3] = mx[3] ? ($signed(a[`BYTE3]) > $signed(b[`BYTE3]) ? a[`BYTE3] : b[`BYTE3]) : zx[3] ? 8'd0 : t[`BYTE3];
		o[`BYTE4] = mx[4] ? ($signed(a[`BYTE4]) > $signed(b[`BYTE4]) ? a[`BYTE4] : b[`BYTE4]) : zx[4] ? 8'd0 : t[`BYTE4];
		o[`BYTE5] = mx[5] ? ($signed(a[`BYTE5]) > $signed(b[`BYTE5]) ? a[`BYTE5] : b[`BYTE5]) : zx[5] ? 8'd0 : t[`BYTE5];
		o[`BYTE6] = mx[6] ? ($signed(a[`BYTE6]) > $signed(b[`BYTE6]) ? a[`BYTE6] : b[`BYTE6]) : zx[6] ? 8'd0 : t[`BYTE6];
		o[`BYTE7] = mx[7] ? ($signed(a[`BYTE7]) > $signed(b[`BYTE7]) ? a[`BYTE7] : b[`BYTE7]) : zx[7] ? 8'd0 : t[`BYTE7];
		o[`BYTE8] = mx[8] ? ($signed(a[`BYTE8]) > $signed(b[`BYTE8]) ? a[`BYTE8] : b[`BYTE8]) : zx[8] ? 8'd0 : t[`BYTE8];
		o[`BYTE9] = mx[9] ? ($signed(a[`BYTE9]) > $signed(b[`BYTE9]) ? a[`BYTE9] : b[`BYTE9]) : zx[9] ? 8'd0 : t[`BYTE9];
		o[`BYTE10] = mx[10] ? ($signed(a[`BYTE10]) > $signed(b[`BYTE10]) ? a[`BYTE10] : b[`BYTE10]) : zx[10] ? 8'd0 : t[`BYTE10];
		o[`BYTE11] = mx[11] ? ($signed(a[`BYTE11]) > $signed(b[`BYTE11]) ? a[`BYTE11] : b[`BYTE11]) : zx[11] ? 8'd0 : t[`BYTE11];
		o[`BYTE12] = mx[12] ? ($signed(a[`BYTE12]) > $signed(b[`BYTE12]) ? a[`BYTE12] : b[`BYTE12]) : zx[12] ? 8'd0 : t[`BYTE12];
		o[`BYTE13] = mx[13] ? ($signed(a[`BYTE13]) > $signed(b[`BYTE13]) ? a[`BYTE13] : b[`BYTE13]) : zx[13] ? 8'd0 : t[`BYTE13];
		o[`BYTE14] = mx[14] ? ($signed(a[`BYTE14]) > $signed(b[`BYTE14]) ? a[`BYTE14] : b[`BYTE14]) : zx[14] ? 8'd0 : t[`BYTE14];
		o[`BYTE15] = mx[15] ? ($signed(a[`BYTE15]) > $signed(b[`BYTE15]) ? a[`BYTE15] : b[`BYTE15]) : zx[15] ? 8'd0 : t[`BYTE15];
		o[`BYTE16] = mx[16] ? ($signed(a[`BYTE16]) > $signed(b[`BYTE16]) ? a[`BYTE16] : b[`BYTE16]) : zx[16] ? 8'd0 : t[`BYTE16];
		o[`BYTE17] = mx[17] ? ($signed(a[`BYTE17]) > $signed(b[`BYTE17]) ? a[`BYTE17] : b[`BYTE17]) : zx[17] ? 8'd0 : t[`BYTE17];
		o[`BYTE18] = mx[18] ? ($signed(a[`BYTE18]) > $signed(b[`BYTE18]) ? a[`BYTE18] : b[`BYTE18]) : zx[18] ? 8'd0 : t[`BYTE18];
		o[`BYTE19] = mx[19] ? ($signed(a[`BYTE19]) > $signed(b[`BYTE19]) ? a[`BYTE19] : b[`BYTE19]) : zx[19] ? 8'd0 : t[`BYTE19];
		o[`BYTE20] = mx[20] ? ($signed(a[`BYTE20]) > $signed(b[`BYTE20]) ? a[`BYTE20] : b[`BYTE20]) : zx[20] ? 8'd0 : t[`BYTE20];
		o[`BYTE21] = mx[21] ? ($signed(a[`BYTE21]) > $signed(b[`BYTE21]) ? a[`BYTE21] : b[`BYTE21]) : zx[21] ? 8'd0 : t[`BYTE21];
		o[`BYTE22] = mx[22] ? ($signed(a[`BYTE22]) > $signed(b[`BYTE22]) ? a[`BYTE22] : b[`BYTE22]) : zx[22] ? 8'd0 : t[`BYTE22];
		o[`BYTE23] = mx[23] ? ($signed(a[`BYTE23]) > $signed(b[`BYTE23]) ? a[`BYTE23] : b[`BYTE23]) : zx[23] ? 8'd0 : t[`BYTE23];
		o[`BYTE24] = mx[24] ? ($signed(a[`BYTE24]) > $signed(b[`BYTE24]) ? a[`BYTE24] : b[`BYTE24]) : zx[24] ? 8'd0 : t[`BYTE24];
		o[`BYTE25] = mx[25] ? ($signed(a[`BYTE25]) > $signed(b[`BYTE25]) ? a[`BYTE25] : b[`BYTE25]) : zx[25] ? 8'd0 : t[`BYTE25];
		o[`BYTE26] = mx[26] ? ($signed(a[`BYTE26]) > $signed(b[`BYTE26]) ? a[`BYTE26] : b[`BYTE26]) : zx[26] ? 8'd0 : t[`BYTE26];
		o[`BYTE27] = mx[27] ? ($signed(a[`BYTE27]) > $signed(b[`BYTE27]) ? a[`BYTE27] : b[`BYTE27]) : zx[27] ? 8'd0 : t[`BYTE27];
		o[`BYTE28] = mx[28] ? ($signed(a[`BYTE28]) > $signed(b[`BYTE28]) ? a[`BYTE28] : b[`BYTE28]) : zx[28] ? 8'd0 : t[`BYTE28];
		o[`BYTE29] = mx[29] ? ($signed(a[`BYTE29]) > $signed(b[`BYTE29]) ? a[`BYTE29] : b[`BYTE29]) : zx[29] ? 8'd0 : t[`BYTE29];
		o[`BYTE30] = mx[30] ? ($signed(a[`BYTE30]) > $signed(b[`BYTE30]) ? a[`BYTE30] : b[`BYTE30]) : zx[30] ? 8'd0 : t[`BYTE30];
		o[`BYTE31] = mx[31] ? ($signed(a[`BYTE31]) > $signed(b[`BYTE31]) ? a[`BYTE31] : b[`BYTE31]) : zx[31] ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
		o[`WYDE0] = mx[0] ? ($signed(a[`WYDE0]) > $signed(b[`WYDE0]) ? a[`WYDE0] : b[`WYDE0]) : zx[0] ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = mx[1] ? ($signed(a[`WYDE1]) > $signed(b[`WYDE1]) ? a[`WYDE1] : b[`WYDE1]) : zx[1] ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = mx[2] ? ($signed(a[`WYDE2]) > $signed(b[`WYDE2]) ? a[`WYDE2] : b[`WYDE2]) : zx[2] ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = mx[3] ? ($signed(a[`WYDE3]) > $signed(b[`WYDE3]) ? a[`WYDE3] : b[`WYDE3]) : zx[3] ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = mx[4] ? ($signed(a[`WYDE4]) > $signed(b[`WYDE4]) ? a[`WYDE4] : b[`WYDE4]) : zx[4] ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = mx[5] ? ($signed(a[`WYDE5]) > $signed(b[`WYDE5]) ? a[`WYDE5] : b[`WYDE5]) : zx[5] ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = mx[6] ? ($signed(a[`WYDE6]) > $signed(b[`WYDE6]) ? a[`WYDE6] : b[`WYDE6]) : zx[6] ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = mx[7] ? ($signed(a[`WYDE7]) > $signed(b[`WYDE7]) ? a[`WYDE7] : b[`WYDE7]) : zx[7] ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = mx[8] ? ($signed(a[`WYDE8]) > $signed(b[`WYDE8]) ? a[`WYDE8] : b[`WYDE8]) : zx[8] ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = mx[9] ? ($signed(a[`WYDE9]) > $signed(b[`WYDE9]) ? a[`WYDE9] : b[`WYDE9]) : zx[9] ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = mx[10] ? ($signed(a[`WYDE10]) > $signed(b[`WYDE10]) ? a[`WYDE10] : b[`WYDE10]) : zx[10] ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = mx[11] ? ($signed(a[`WYDE11]) > $signed(b[`WYDE11]) ? a[`WYDE11] : b[`WYDE11]) : zx[11] ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = mx[12] ? ($signed(a[`WYDE12]) > $signed(b[`WYDE12]) ? a[`WYDE12] : b[`WYDE12]) : zx[12] ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = mx[13] ? ($signed(a[`WYDE13]) > $signed(b[`WYDE13]) ? a[`WYDE13] : b[`WYDE13]) : zx[13] ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = mx[14] ? ($signed(a[`WYDE14]) > $signed(b[`WYDE14]) ? a[`WYDE14] : b[`WYDE14]) : zx[14] ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = mx[15] ? ($signed(a[`WYDE15]) > $signed(b[`WYDE15]) ? a[`WYDE15] : b[`WYDE15]) : zx[15] ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = mx[0] ? ($signed(a[`TETRA0]) > $signed(b[`TETRA0]) ? a[`TETRA0] : b[`TETRA0]) : zx[0] ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = mx[1] ? ($signed(a[`TETRA1]) > $signed(b[`TETRA1]) ? a[`TETRA1] : b[`TETRA1]) : zx[1] ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = mx[2] ? ($signed(a[`TETRA2]) > $signed(b[`TETRA2]) ? a[`TETRA2] : b[`TETRA2]) : zx[2] ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = mx[3] ? ($signed(a[`TETRA3]) > $signed(b[`TETRA3]) ? a[`TETRA3] : b[`TETRA3]) : zx[3] ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = mx[4] ? ($signed(a[`TETRA4]) > $signed(b[`TETRA4]) ? a[`TETRA4] : b[`TETRA4]) : zx[4] ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = mx[5] ? ($signed(a[`TETRA5]) > $signed(b[`TETRA5]) ? a[`TETRA5] : b[`TETRA5]) : zx[5] ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = mx[6] ? ($signed(a[`TETRA6]) > $signed(b[`TETRA6]) ? a[`TETRA6] : b[`TETRA6]) : zx[6] ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = mx[7] ? ($signed(a[`TETRA7]) > $signed(b[`TETRA7]) ? a[`TETRA7] : b[`TETRA7]) : zx[7] ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = mx[0] ? ($signed(a[`OCTA0]) > $signed(b[`OCTA0]) ? a[`OCTA0] : b[`OCTA0]) : zx[0] ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = mx[1] ? ($signed(a[`OCTA1]) > $signed(b[`OCTA1]) ? a[`OCTA1] : b[`OCTA1]) : zx[1] ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = mx[2] ? ($signed(a[`OCTA2]) > $signed(b[`OCTA2]) ? a[`OCTA2] : b[`OCTA2]) : zx[2] ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = mx[3] ? ($signed(a[`OCTA3]) > $signed(b[`OCTA3]) ? a[`OCTA3] : b[`OCTA3]) : zx[3] ? 64'd0 : t[`OCTA3];
		end
//	hexi_para:
	default:
		begin
		o[`HEXI0] = mx[0] ? ($signed(a[`HEXI0]) > $signed(b[`HEXI0]) ? a[`HEXI0] : b[`HEXI0]) : zx[0] ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = mx[1] ? ($signed(a[`HEXI1]) > $signed(b[`HEXI1]) ? a[`HEXI1] : b[`HEXI1]) : zx[1] ? 128'd0 : t[`HEXI1];
		end
	endcase
	else
		o = {64{4'hC}};
end
endtask

task tskSeq;
input [3:0] fmt;
input [DBW:0] a;
input [DBW:0] b;
output [DBW:0] o;
begin
	case(fmt)
  byt:   o = $signed(a[7:0]) == $signed(b[7:0]);
  wyde:   o = $signed(a[15:0]) == $signed(b[15:0]);
  tetra:   o = $signed(a[31:0]) == $signed(b[31:0]);
  octa:		o = $signed(a[63:0]) == $signed(b[63:0]);
  hexi:   o = $signed(a[127:0]) == $signed(b[127:0]);
  byte_para:		o = {
						        	$signed(a[`BYTE31]) == $signed(b[`BYTE31]),
						        	$signed(a[`BYTE30]) == $signed(b[`BYTE30]),
						        	$signed(a[`BYTE29]) == $signed(b[`BYTE29]),
						        	$signed(a[`BYTE28]) == $signed(b[`BYTE28]),
						        	$signed(a[`BYTE27]) == $signed(b[`BYTE27]),
						        	$signed(a[`BYTE26]) == $signed(b[`BYTE26]),
						        	$signed(a[`BYTE25]) == $signed(b[`BYTE25]),
						        	$signed(a[`BYTE24]) == $signed(b[`BYTE24]),
						        	$signed(a[`BYTE23]) == $signed(b[`BYTE23]),
						        	$signed(a[`BYTE22]) == $signed(b[`BYTE22]),
						        	$signed(a[`BYTE21]) == $signed(b[`BYTE21]),
						        	$signed(a[`BYTE20]) == $signed(b[`BYTE20]),
						        	$signed(a[`BYTE19]) == $signed(b[`BYTE19]),
						        	$signed(a[`BYTE18]) == $signed(b[`BYTE18]),
						        	$signed(a[`BYTE17]) == $signed(b[`BYTE17]),
						        	$signed(a[`BYTE16]) == $signed(b[`BYTE16]),
						        	$signed(a[`BYTE15]) == $signed(b[`BYTE15]),
						        	$signed(a[`BYTE14]) == $signed(b[`BYTE14]),
						        	$signed(a[`BYTE13]) == $signed(b[`BYTE13]),
						        	$signed(a[`BYTE12]) == $signed(b[`BYTE12]),
						        	$signed(a[`BYTE11]) == $signed(b[`BYTE11]),
						        	$signed(a[`BYTE10]) == $signed(b[`BYTE10]),
						        	$signed(a[`BYTE9]) == $signed(b[`BYTE9]),
						        	$signed(a[`BYTE8]) == $signed(b[`BYTE8]),
						        	$signed(a[`BYTE7]) == $signed(b[`BYTE7]),
						        	$signed(a[`BYTE6]) == $signed(b[`BYTE6]),
						        	$signed(a[`BYTE5]) == $signed(b[`BYTE5]),
						        	$signed(a[`BYTE4]) == $signed(b[`BYTE4]),
						        	$signed(a[`BYTE3]) == $signed(b[`BYTE3]),
						        	$signed(a[`BYTE2]) == $signed(b[`BYTE2]),
						        	$signed(a[`BYTE1]) == $signed(b[`BYTE1]),
						        	$signed(a[`BYTE0]) == $signed(b[`BYTE0])
						        };
  wyde_para:		o = {
						        	$signed(a[`WYDE15]) == $signed(b[`WYDE15]),
						        	$signed(a[`WYDE14]) == $signed(b[`WYDE14]),
						        	$signed(a[`WYDE13]) == $signed(b[`WYDE13]),
						        	$signed(a[`WYDE12]) == $signed(b[`WYDE12]),
						        	$signed(a[`WYDE11]) == $signed(b[`WYDE11]),
						        	$signed(a[`WYDE10]) == $signed(b[`WYDE10]),
						        	$signed(a[`WYDE9]) == $signed(b[`WYDE9]),
						        	$signed(a[`WYDE8]) == $signed(b[`WYDE8]),
						        	$signed(a[`WYDE7]) == $signed(b[`WYDE7]),
						        	$signed(a[`WYDE6]) == $signed(b[`WYDE6]),
						        	$signed(a[`WYDE5]) == $signed(b[`WYDE5]),
						        	$signed(a[`WYDE4]) == $signed(b[`WYDE4]),
						        	$signed(a[`WYDE3]) == $signed(b[`WYDE3]),
						        	$signed(a[`WYDE2]) == $signed(b[`WYDE2]),
						        	$signed(a[`WYDE1]) == $signed(b[`WYDE1]),
						        	$signed(a[`WYDE0]) == $signed(b[`WYDE0])
						        };
  tetra_para:		o = {
					        		$signed(a[`TETRA7]) == $signed(b[`TETRA7]),
					        		$signed(a[`TETRA6]) == $signed(b[`TETRA6]),
					        		$signed(a[`TETRA5]) == $signed(b[`TETRA5]),
					        		$signed(a[`TETRA4]) == $signed(b[`TETRA4]),
					        		$signed(a[`TETRA3]) == $signed(b[`TETRA3]),
					        		$signed(a[`TETRA2]) == $signed(b[`TETRA2]),
					        		$signed(a[`TETRA1]) == $signed(b[`TETRA1]),
					        		$signed(a[`TETRA0]) == $signed(b[`TETRA0])
						        };
	octa_para:		o = {
											$signed(a[`OCTA3]) == $signed(b[`OCTA3]),
											$signed(a[`OCTA2]) == $signed(b[`OCTA2]),
											$signed(a[`OCTA1]) == $signed(b[`OCTA1]),
											$signed(a[`OCTA0]) == $signed(b[`OCTA0])
										};
	hexi_para:
								o = {
											$signed(a[`HEXI1]) == $signed(b[`HEXI1]),
											$signed(a[`HEXI0]) == $signed(b[`HEXI0])
										};
	default:		  o = a == b;
  endcase
end
endtask

task tskSne;
input [3:0] fmt;
input [255:0] a;
input [255:0] b;
output [255:0] o;
begin
	case(fmt)
  byt:   o = a[7:0] != b[7:0];
  wyde:   o = a[15:0] != b[15:0];
  tetra:   o = a[31:0] != b[31:0];
  octa:   o = a[63:0] != b[63:0];
  hexi:   o = a[127:0] != b[127:0];
  byte_para:		o = {
						        	a[`BYTE31] != b[`BYTE31],
						        	a[`BYTE30] != b[`BYTE30],
						        	a[`BYTE29] != b[`BYTE29],
						        	a[`BYTE28] != b[`BYTE28],
						        	a[`BYTE27] != b[`BYTE27],
						        	a[`BYTE26] != b[`BYTE26],
						        	a[`BYTE25] != b[`BYTE25],
						        	a[`BYTE24] != b[`BYTE24],
						        	a[`BYTE23] != b[`BYTE23],
						        	a[`BYTE22] != b[`BYTE22],
						        	a[`BYTE21] != b[`BYTE21],
						        	a[`BYTE20] != b[`BYTE20],
						        	a[`BYTE19] != b[`BYTE19],
						        	a[`BYTE18] != b[`BYTE18],
						        	a[`BYTE17] != b[`BYTE17],
						        	a[`BYTE16] != b[`BYTE16],
						        	a[`BYTE15] != b[`BYTE15],
						        	a[`BYTE14] != b[`BYTE14],
						        	a[`BYTE13] != b[`BYTE13],
						        	a[`BYTE12] != b[`BYTE12],
						        	a[`BYTE11] != b[`BYTE11],
						        	a[`BYTE10] != b[`BYTE10],
						        	a[`BYTE9] != b[`BYTE9],
						        	a[`BYTE8] != b[`BYTE8],
						        	a[`BYTE7] != b[`BYTE7],
						        	a[`BYTE6] != b[`BYTE6],
						        	a[`BYTE5] != b[`BYTE5],
						        	a[`BYTE4] != b[`BYTE4],
						        	a[`BYTE3] != b[`BYTE3],
						        	a[`BYTE2] != b[`BYTE2],
						        	a[`BYTE1] != b[`BYTE1],
						        	a[`BYTE0] != b[`BYTE0]
						        };
  wyde_para:		o = {
						        	a[`WYDE15] != b[`WYDE15],
						        	a[`WYDE14] != b[`WYDE14],
						        	a[`WYDE13] != b[`WYDE13],
						        	a[`WYDE12] != b[`WYDE12],
						        	a[`WYDE11] != b[`WYDE11],
						        	a[`WYDE10] != b[`WYDE10],
						        	a[`WYDE9] != b[`WYDE9],
						        	a[`WYDE8] != b[`WYDE8],
						        	a[`WYDE7] != b[`WYDE7],
						        	a[`WYDE6] != b[`WYDE6],
						        	a[`WYDE5] != b[`WYDE5],
						        	a[`WYDE4] != b[`WYDE4],
						        	a[`WYDE3] != b[`WYDE3],
						        	a[`WYDE2] != b[`WYDE2],
						        	a[`WYDE1] != b[`WYDE1],
						        	a[`WYDE0] != b[`WYDE0]
						        };
  tetra_para:		o = {
					        		a[`TETRA7] != b[`TETRA7],
					        		a[`TETRA6] != b[`TETRA6],
					        		a[`TETRA5] != b[`TETRA5],
					        		a[`TETRA4] != b[`TETRA4],
					        		a[`TETRA3] != b[`TETRA3],
					        		a[`TETRA2] != b[`TETRA2],
					        		a[`TETRA1] != b[`TETRA1],
					        		a[`TETRA0] != b[`TETRA0]
						        };
	octa_para:		o = {
											a[`OCTA3] != b[`OCTA3],
											a[`OCTA2] != b[`OCTA2],
											a[`OCTA1] != b[`OCTA1],
											a[`OCTA0] != b[`OCTA0]
										};
	hexi_para:		
								o = {
											a[`HEXI1] != b[`HEXI1],
											a[`HEXI0] != b[`HEXI0]
										};
	default:
		o = a != b;
  endcase
end
endtask

task tskSlt;
input [3:0] fmt;
input [255:0] a;
input [255:0] b;
output [255:0] o;
begin
	case(fmt)
  byt:   o = $signed(a[7:0]) < $signed(b[7:0]);
  wyde:   o = $signed(a[15:0]) < $signed(b[15:0]);
  tetra:   o = $signed(a[31:0]) < $signed(b[31:0]);
  octa:		o = $signed(a[63:0]) < $signed(b[63:0]);
  hexi:		o = $signed(a[127:0]) < $signed(b[127:0]);
  3'd5:   o = $signed(a) < $signed(b);
  byte_para:		o = {
						        	$signed(a[`BYTE31]) < $signed(b[`BYTE31]),
						        	$signed(a[`BYTE30]) < $signed(b[`BYTE30]),
						        	$signed(a[`BYTE29]) < $signed(b[`BYTE29]),
						        	$signed(a[`BYTE28]) < $signed(b[`BYTE28]),
						        	$signed(a[`BYTE27]) < $signed(b[`BYTE27]),
						        	$signed(a[`BYTE26]) < $signed(b[`BYTE26]),
						        	$signed(a[`BYTE25]) < $signed(b[`BYTE25]),
						        	$signed(a[`BYTE24]) < $signed(b[`BYTE24]),
						        	$signed(a[`BYTE23]) < $signed(b[`BYTE23]),
						        	$signed(a[`BYTE22]) < $signed(b[`BYTE22]),
						        	$signed(a[`BYTE21]) < $signed(b[`BYTE21]),
						        	$signed(a[`BYTE20]) < $signed(b[`BYTE20]),
						        	$signed(a[`BYTE19]) < $signed(b[`BYTE19]),
						        	$signed(a[`BYTE18]) < $signed(b[`BYTE18]),
						        	$signed(a[`BYTE17]) < $signed(b[`BYTE17]),
						        	$signed(a[`BYTE16]) < $signed(b[`BYTE16]),
						        	$signed(a[`BYTE15]) < $signed(b[`BYTE15]),
						        	$signed(a[`BYTE14]) < $signed(b[`BYTE14]),
						        	$signed(a[`BYTE13]) < $signed(b[`BYTE13]),
						        	$signed(a[`BYTE12]) < $signed(b[`BYTE12]),
						        	$signed(a[`BYTE11]) < $signed(b[`BYTE11]),
						        	$signed(a[`BYTE10]) < $signed(b[`BYTE10]),
						        	$signed(a[`BYTE9]) < $signed(b[`BYTE9]),
						        	$signed(a[`BYTE8]) < $signed(b[`BYTE8]),
						        	$signed(a[`BYTE7]) < $signed(b[`BYTE7]),
						        	$signed(a[`BYTE6]) < $signed(b[`BYTE6]),
						        	$signed(a[`BYTE5]) < $signed(b[`BYTE5]),
						        	$signed(a[`BYTE4]) < $signed(b[`BYTE4]),
						        	$signed(a[`BYTE3]) < $signed(b[`BYTE3]),
						        	$signed(a[`BYTE2]) < $signed(b[`BYTE2]),
						        	$signed(a[`BYTE1]) < $signed(b[`BYTE1]),
						        	$signed(a[`BYTE0]) < $signed(b[`BYTE0])
						        };
  wyde_para:		o = {
						        	$signed(a[`WYDE15]) < $signed(b[`WYDE15]),
						        	$signed(a[`WYDE14]) < $signed(b[`WYDE14]),
						        	$signed(a[`WYDE13]) < $signed(b[`WYDE13]),
						        	$signed(a[`WYDE12]) < $signed(b[`WYDE12]),
						        	$signed(a[`WYDE11]) < $signed(b[`WYDE11]),
						        	$signed(a[`WYDE10]) < $signed(b[`WYDE10]),
						        	$signed(a[`WYDE9]) < $signed(b[`WYDE9]),
						        	$signed(a[`WYDE8]) < $signed(b[`WYDE8]),
						        	$signed(a[`WYDE7]) < $signed(b[`WYDE7]),
						        	$signed(a[`WYDE6]) < $signed(b[`WYDE6]),
						        	$signed(a[`WYDE5]) < $signed(b[`WYDE5]),
						        	$signed(a[`WYDE4]) < $signed(b[`WYDE4]),
						        	$signed(a[`WYDE3]) < $signed(b[`WYDE3]),
						        	$signed(a[`WYDE2]) < $signed(b[`WYDE2]),
						        	$signed(a[`WYDE1]) < $signed(b[`WYDE1]),
						        	$signed(a[`WYDE0]) < $signed(b[`WYDE0])
						        };
  tetra_para:		o = {
					        		$signed(a[`TETRA7]) < $signed(b[`TETRA7]),
					        		$signed(a[`TETRA6]) < $signed(b[`TETRA6]),
					        		$signed(a[`TETRA5]) < $signed(b[`TETRA5]),
					        		$signed(a[`TETRA4]) < $signed(b[`TETRA4]),
					        		$signed(a[`TETRA3]) < $signed(b[`TETRA3]),
					        		$signed(a[`TETRA2]) < $signed(b[`TETRA2]),
					        		$signed(a[`TETRA1]) < $signed(b[`TETRA1]),
					        		$signed(a[`TETRA0]) < $signed(b[`TETRA0])
						        };
	octa_para:		o = {
											$signed(a[`OCTA3]) < $signed(b[`OCTA3]),
											$signed(a[`OCTA2]) < $signed(b[`OCTA2]),
											$signed(a[`OCTA1]) < $signed(b[`OCTA1]),
											$signed(a[`OCTA0]) < $signed(b[`OCTA0])
										};
	hexi_para:		o = {
											$signed(a[`HEXI1]) < $signed(b[`HEXI1]),
											$signed(a[`HEXI0]) < $signed(b[`HEXI0])
										};
	default:			o = $signed(a) < $signed(b);
  endcase
end
endtask

task tskSle;
input [3:0] fmt;
input [255:0] a;
input [255:0] b;
output [255:0] o;
begin
	case(fmt)
  byt:   o = $signed(a[7:0]) <= $signed(b[7:0]);
  wyde:   o = $signed(a[15:0]) <= $signed(b[15:0]);
  tetra:   o = $signed(a[31:0]) <= $signed(b[31:0]);
  octa:		o = $signed(a[63:0]) <= $signed(b[63:0]);
  hexi:		o = $signed(a[127:0]) <= $signed(b[127:0]);
  3'd5:   o = $signed(a) <= $signed(b);
  byte_para:		o = {
						        	$signed(a[`BYTE31]) <= $signed(b[`BYTE31]),
						        	$signed(a[`BYTE30]) <= $signed(b[`BYTE30]),
						        	$signed(a[`BYTE29]) <= $signed(b[`BYTE29]),
						        	$signed(a[`BYTE28]) <= $signed(b[`BYTE28]),
						        	$signed(a[`BYTE27]) <= $signed(b[`BYTE27]),
						        	$signed(a[`BYTE26]) <= $signed(b[`BYTE26]),
						        	$signed(a[`BYTE25]) <= $signed(b[`BYTE25]),
						        	$signed(a[`BYTE24]) <= $signed(b[`BYTE24]),
						        	$signed(a[`BYTE23]) <= $signed(b[`BYTE23]),
						        	$signed(a[`BYTE22]) <= $signed(b[`BYTE22]),
						        	$signed(a[`BYTE21]) <= $signed(b[`BYTE21]),
						        	$signed(a[`BYTE20]) <= $signed(b[`BYTE20]),
						        	$signed(a[`BYTE19]) <= $signed(b[`BYTE19]),
						        	$signed(a[`BYTE18]) <= $signed(b[`BYTE18]),
						        	$signed(a[`BYTE17]) <= $signed(b[`BYTE17]),
						        	$signed(a[`BYTE16]) <= $signed(b[`BYTE16]),
						        	$signed(a[`BYTE15]) <= $signed(b[`BYTE15]),
						        	$signed(a[`BYTE14]) <= $signed(b[`BYTE14]),
						        	$signed(a[`BYTE13]) <= $signed(b[`BYTE13]),
						        	$signed(a[`BYTE12]) <= $signed(b[`BYTE12]),
						        	$signed(a[`BYTE11]) <= $signed(b[`BYTE11]),
						        	$signed(a[`BYTE10]) <= $signed(b[`BYTE10]),
						        	$signed(a[`BYTE9]) <= $signed(b[`BYTE9]),
						        	$signed(a[`BYTE8]) <= $signed(b[`BYTE8]),
						        	$signed(a[`BYTE7]) <= $signed(b[`BYTE7]),
						        	$signed(a[`BYTE6]) <= $signed(b[`BYTE6]),
						        	$signed(a[`BYTE5]) <= $signed(b[`BYTE5]),
						        	$signed(a[`BYTE4]) <= $signed(b[`BYTE4]),
						        	$signed(a[`BYTE3]) <= $signed(b[`BYTE3]),
						        	$signed(a[`BYTE2]) <= $signed(b[`BYTE2]),
						        	$signed(a[`BYTE1]) <= $signed(b[`BYTE1]),
						        	$signed(a[`BYTE0]) <= $signed(b[`BYTE0])
						        };
  wyde_para:		o = {
						        	$signed(a[`WYDE15]) <= $signed(b[`WYDE15]),
						        	$signed(a[`WYDE14]) <= $signed(b[`WYDE14]),
						        	$signed(a[`WYDE13]) <= $signed(b[`WYDE13]),
						        	$signed(a[`WYDE12]) <= $signed(b[`WYDE12]),
						        	$signed(a[`WYDE11]) <= $signed(b[`WYDE11]),
						        	$signed(a[`WYDE10]) <= $signed(b[`WYDE10]),
						        	$signed(a[`WYDE9]) <= $signed(b[`WYDE9]),
						        	$signed(a[`WYDE8]) <= $signed(b[`WYDE8]),
						        	$signed(a[`WYDE7]) <= $signed(b[`WYDE7]),
						        	$signed(a[`WYDE6]) <= $signed(b[`WYDE6]),
						        	$signed(a[`WYDE5]) <= $signed(b[`WYDE5]),
						        	$signed(a[`WYDE4]) <= $signed(b[`WYDE4]),
						        	$signed(a[`WYDE3]) <= $signed(b[`WYDE3]),
						        	$signed(a[`WYDE2]) <= $signed(b[`WYDE2]),
						        	$signed(a[`WYDE1]) <= $signed(b[`WYDE1]),
						        	$signed(a[`WYDE0]) <= $signed(b[`WYDE0])
						        };
  tetra_para:		o = {
					        		$signed(a[`TETRA7]) <= $signed(b[`TETRA7]),
					        		$signed(a[`TETRA6]) <= $signed(b[`TETRA6]),
					        		$signed(a[`TETRA5]) <= $signed(b[`TETRA5]),
					        		$signed(a[`TETRA4]) <= $signed(b[`TETRA4]),
					        		$signed(a[`TETRA3]) <= $signed(b[`TETRA3]),
					        		$signed(a[`TETRA2]) <= $signed(b[`TETRA2]),
					        		$signed(a[`TETRA1]) <= $signed(b[`TETRA1]),
					        		$signed(a[`TETRA0]) <= $signed(b[`TETRA0])
						        };
	octa_para:		o = {
											$signed(a[`OCTA3]) <= $signed(b[`OCTA3]),
											$signed(a[`OCTA2]) <= $signed(b[`OCTA2]),
											$signed(a[`OCTA1]) <= $signed(b[`OCTA1]),
											$signed(a[`OCTA0]) <= $signed(b[`OCTA0])
										};
	hexi_para:		o = {
											$signed(a[`HEXI1]) <= $signed(b[`HEXI1]),
											$signed(a[`HEXI0]) <= $signed(b[`HEXI0])
										};
	default:			o = $signed(a) <= $signed(b);
  endcase
end
endtask

task tskSltu;
input [3:0] fmt;
input [255:0] a;
input [255:0] b;
output [255:0] o;
begin
	case(fmt)
  byt:   o = a[7:0] < b[7:0];
  wyde:   o = a[15:0] < b[15:0];
  tetra:   o = a[31:0] < b[31:0];
  octa:		o = a[63:0] < b[63:0];
  hexi:		o = a[127:0] <= b[127:0];
  3'd5:   o = a < b;
  byte_para:		o = {
						        	a[`BYTE31] < b[`BYTE31],
						        	a[`BYTE30] < b[`BYTE30],
						        	a[`BYTE29] < b[`BYTE29],
						        	a[`BYTE28] < b[`BYTE28],
						        	a[`BYTE27] < b[`BYTE27],
						        	a[`BYTE26] < b[`BYTE26],
						        	a[`BYTE25] < b[`BYTE25],
						        	a[`BYTE24] < b[`BYTE24],
						        	a[`BYTE23] < b[`BYTE23],
						        	a[`BYTE22] < b[`BYTE22],
						        	a[`BYTE21] < b[`BYTE21],
						        	a[`BYTE20] < b[`BYTE20],
						        	a[`BYTE19] < b[`BYTE19],
						        	a[`BYTE18] < b[`BYTE18],
						        	a[`BYTE17] < b[`BYTE17],
						        	a[`BYTE16] < b[`BYTE16],
						        	a[`BYTE15] < b[`BYTE15],
						        	a[`BYTE14] < b[`BYTE14],
						        	a[`BYTE13] < b[`BYTE13],
						        	a[`BYTE12] < b[`BYTE12],
						        	a[`BYTE11] < b[`BYTE11],
						        	a[`BYTE10] < b[`BYTE10],
						        	a[`BYTE9] < b[`BYTE9],
						        	a[`BYTE8] < b[`BYTE8],
						        	a[`BYTE7] < b[`BYTE7],
						        	a[`BYTE6] < b[`BYTE6],
						        	a[`BYTE5] < b[`BYTE5],
						        	a[`BYTE4] < b[`BYTE4],
						        	a[`BYTE3] < b[`BYTE3],
						        	a[`BYTE2] < b[`BYTE2],
						        	a[`BYTE1] < b[`BYTE1],
						        	a[`BYTE0] < b[`BYTE0]
						        };
  wyde_para:		o = {
						        	a[`WYDE15] < b[`WYDE15],
						        	a[`WYDE14] < b[`WYDE14],
						        	a[`WYDE13] < b[`WYDE13],
						        	a[`WYDE12] < b[`WYDE12],
						        	a[`WYDE11] < b[`WYDE11],
						        	a[`WYDE10] < b[`WYDE10],
						        	a[`WYDE9] < b[`WYDE9],
						        	a[`WYDE8] < b[`WYDE8],
						        	a[`WYDE7] < b[`WYDE7],
						        	a[`WYDE6] < b[`WYDE6],
						        	a[`WYDE5] < b[`WYDE5],
						        	a[`WYDE4] < b[`WYDE4],
						        	a[`WYDE3] < b[`WYDE3],
						        	a[`WYDE2] < b[`WYDE2],
						        	a[`WYDE1] < b[`WYDE1],
						        	a[`WYDE0] < b[`WYDE0]
						        };
  tetra_para:		o = {
					        		a[`TETRA7] < b[`TETRA7],
					        		a[`TETRA6] < b[`TETRA6],
					        		a[`TETRA5] < b[`TETRA5],
					        		a[`TETRA4] < b[`TETRA4],
					        		a[`TETRA3] < b[`TETRA3],
					        		a[`TETRA2] < b[`TETRA2],
					        		a[`TETRA1] < b[`TETRA1],
					        		a[`TETRA0] < b[`TETRA0]
						        };
	octa_para:		o = {
											a[`OCTA3] < b[`OCTA3],
											a[`OCTA2] < b[`OCTA2],
											a[`OCTA1] < b[`OCTA1],
											a[`OCTA0] < b[`OCTA0]
										};
	hexi_para:		o = {
											a[`HEXI1] < b[`HEXI1],
											a[`HEXI0] < b[`HEXI0]
										};
	default:		o = a < b;
  endcase
end
endtask

task tskSleu;
input [3:0] fmt;
input [255:0] a;
input [255:0] b;
output [255:0] o;
begin
	case(fmt)
  byt:   o = a[7:0] <= b[7:0];
  wyde:   o = a[15:0] <= b[15:0];
  tetra:  o = a[31:0] <= b[31:0];
  octa:   o = a[63:0] <= b[63:0];
  hexi:		o = a[127:0] <= b[127:0];
  3'd5:   o = a <= b;
  byte_para:		o = {
						        	a[`BYTE31] <= b[`BYTE31],
						        	a[`BYTE30] <= b[`BYTE30],
						        	a[`BYTE29] <= b[`BYTE29],
						        	a[`BYTE28] <= b[`BYTE28],
						        	a[`BYTE27] <= b[`BYTE27],
						        	a[`BYTE26] <= b[`BYTE26],
						        	a[`BYTE25] <= b[`BYTE25],
						        	a[`BYTE24] <= b[`BYTE24],
						        	a[`BYTE23] <= b[`BYTE23],
						        	a[`BYTE22] <= b[`BYTE22],
						        	a[`BYTE21] <= b[`BYTE21],
						        	a[`BYTE20] <= b[`BYTE20],
						        	a[`BYTE19] <= b[`BYTE19],
						        	a[`BYTE18] <= b[`BYTE18],
						        	a[`BYTE17] <= b[`BYTE17],
						        	a[`BYTE16] <= b[`BYTE16],
						        	a[`BYTE15] <= b[`BYTE15],
						        	a[`BYTE14] <= b[`BYTE14],
						        	a[`BYTE13] <= b[`BYTE13],
						        	a[`BYTE12] <= b[`BYTE12],
						        	a[`BYTE11] <= b[`BYTE11],
						        	a[`BYTE10] <= b[`BYTE10],
						        	a[`BYTE9] <= b[`BYTE9],
						        	a[`BYTE8] <= b[`BYTE8],
						        	a[`BYTE7] <= b[`BYTE7],
						        	a[`BYTE6] <= b[`BYTE6],
						        	a[`BYTE5] <= b[`BYTE5],
						        	a[`BYTE4] <= b[`BYTE4],
						        	a[`BYTE3] <= b[`BYTE3],
						        	a[`BYTE2] <= b[`BYTE2],
						        	a[`BYTE1] <= b[`BYTE1],
						        	a[`BYTE0] <= b[`BYTE0]
						        };
  wyde_para:		o = {
						        	a[`WYDE15] <= b[`WYDE15],
						        	a[`WYDE14] <= b[`WYDE14],
						        	a[`WYDE13] <= b[`WYDE13],
						        	a[`WYDE12] <= b[`WYDE12],
						        	a[`WYDE11] <= b[`WYDE11],
						        	a[`WYDE10] <= b[`WYDE10],
						        	a[`WYDE9] <= b[`WYDE9],
						        	a[`WYDE8] <= b[`WYDE8],
						        	a[`WYDE7] <= b[`WYDE7],
						        	a[`WYDE6] <= b[`WYDE6],
						        	a[`WYDE5] <= b[`WYDE5],
						        	a[`WYDE4] <= b[`WYDE4],
						        	a[`WYDE3] <= b[`WYDE3],
						        	a[`WYDE2] <= b[`WYDE2],
						        	a[`WYDE1] <= b[`WYDE1],
						        	a[`WYDE0] <= b[`WYDE0]
						        };
  tetra_para:		o = {
					        		a[`TETRA7] <= b[`TETRA7],
					        		a[`TETRA6] <= b[`TETRA6],
					        		a[`TETRA5] <= b[`TETRA5],
					        		a[`TETRA4] <= b[`TETRA4],
					        		a[`TETRA3] <= b[`TETRA3],
					        		a[`TETRA2] <= b[`TETRA2],
					        		a[`TETRA1] <= b[`TETRA1],
					        		a[`TETRA0] <= b[`TETRA0]
						        };
	octa_para:		o = {
											a[`OCTA3] <= b[`OCTA3],
											a[`OCTA2] <= b[`OCTA2],
											a[`OCTA1] <= b[`OCTA1],
											a[`OCTA0] <= b[`OCTA0]
										};
	hexi_para:		
								o = {
											a[`HEXI1] <= b[`HEXI1],
											a[`HEXI0] <= b[`HEXI0]
										};
	default:
		o = a <= b;
  endcase
end
endtask

reg [255:0] vcmp8, vcmp16, vcmp32, vcmp64, vcmp128;

generate begin : vcmprss8
	always @* 
	begin
		y = 0;
		vcmp8 = 256'd0;
		for (x = 0; x < 32; x = x + 1)
		begin
			if (mx[x] && x < vl) begin
				vcmp8[y*8+:8] = a[x*8+:8];
				y = y + 1;
			end
		end
	end
end
endgenerate

generate begin : vcmprss16
	always @* 
	begin
		y = 0;
		vcmp16 = 256'd0;
		for (x = 0; x < 16; x = x + 1)
		begin
			if (mx[x] && x < vl) begin
				vcmp16[y*16+:16] = a[x*16+:16];
				y = y + 1;
			end
		end
	end
end
endgenerate

generate begin : vcmprss32
	always @* 
	begin
		y = 0;
		vcmp32 = 256'd0;
		for (x = 0; x < 8; x = x + 1)
		begin
			if (mx[x] && x < vl) begin
				vcmp32[y*32+:32] = a[x*32+:32];
				y = y + 1;
			end
		end
	end
end
endgenerate

generate begin : vcmprss64
	always @* 
	begin
		y = 0;
		vcmp64 = 256'd0;
		for (x = 0; x < 4; x = x + 1)
		begin
			if (mx[x] && x < vl) begin
				vcmp64[y*64+:64] = a[x*64+:64];
				y = y + 1;
			end
		end
	end
end
endgenerate

generate begin : vcmprss128
	always @* 
	begin
		y = 0;
		vcmp128 = 256'd0;
		for (x = 0; x < 2; x = x + 1)
		begin
			if (mx[x] && x < vl) begin
				vcmp128[y*128+:128] = a[x*128+:128];
				y = y + 1;
			end
		end
	end
end
endgenerate


task tskCmprss;
input [3:0] fmt;
output [255:0] o;
begin
	case(fmt)
	byte_para:	o = vcmp8;
	wyde_para:	o = vcmp16;
	tetra_para:	o = vcmp32;
	octa_para:	o = vcmp64;
	hexi_para:	o = vcmp128;
	default:		o = vcmp128;
	endcase
end
endtask

task tskV2bits;
input [3:0] fmt;
input [31:0] mx;
input [31:0] zx;
input [255:0] a;
input [255:0] t;
output [255:0] o;
begin
	case(fmt)
	byte_para:	o = {
								mx[31] ? a[248] : zx[31] ? 1'b0 : t[248],
								mx[30] ? a[240] : zx[30] ? 1'b0 : t[240],
								mx[29] ? a[232] : zx[29] ? 1'b0 : t[232],
								mx[28] ? a[224] : zx[28] ? 1'b0 : t[224],
								mx[27] ? a[216] : zx[27] ? 1'b0 : t[216],
								mx[26] ? a[208] : zx[26] ? 1'b0 : t[208],
								mx[25] ? a[200] : zx[25] ? 1'b0 : t[200],
								mx[24] ? a[192] : zx[24] ? 1'b0 : t[192],
								mx[23] ? a[184] : zx[23] ? 1'b0 : t[184],
								mx[22] ? a[176] : zx[22] ? 1'b0 : t[176],
								mx[21] ? a[168] : zx[21] ? 1'b0 : t[168],
								mx[20] ? a[160] : zx[20] ? 1'b0 : t[160],
								mx[19] ? a[152] : zx[19] ? 1'b0 : t[152],
								mx[18] ? a[144] : zx[18] ? 1'b0 : t[144],
								mx[17] ? a[136] : zx[17] ? 1'b0 : t[136],
								mx[16] ? a[128] : zx[16] ? 1'b0 : t[128],
								mx[15] ? a[120] : zx[15] ? 1'b0 : t[120],
								mx[14] ? a[112] : zx[14] ? 1'b0 : t[112],
								mx[13] ? a[104] : zx[13] ? 1'b0 : t[104],
								mx[12] ? a[ 96] : zx[12] ? 1'b0 : t[ 96],
								mx[11] ? a[ 88] : zx[11] ? 1'b0 : t[ 88],
								mx[10] ? a[ 80] : zx[10] ? 1'b0 : t[ 80],
								mx[ 9] ? a[ 72] : zx[ 9] ? 1'b0 : t[ 72],
								mx[ 8] ? a[ 64] : zx[ 8] ? 1'b0 : t[ 64],
								mx[ 7] ? a[ 56] : zx[ 7] ? 1'b0 : t[ 56],
								mx[ 6] ? a[ 48] : zx[ 6] ? 1'b0 : t[ 48],
								mx[ 5] ? a[ 40] : zx[ 5] ? 1'b0 : t[ 40],
								mx[ 4] ? a[ 32] : zx[ 4] ? 1'b0 : t[ 32],
								mx[ 3] ? a[ 24] : zx[ 3] ? 1'b0 : t[ 24],
								mx[ 2] ? a[ 16] : zx[ 2] ? 1'b0 : t[ 16],
								mx[ 1] ? a[  8] : zx[ 1] ? 1'b0 : t[  8],
								mx[ 0] ? a[  0] : zx[ 0] ? 1'b0 : t[  0]
							};
	wyde_para:	o = {
								mx[15] ? a[240] : zx[15] ? 1'b0 : t[240],
								mx[14] ? a[224] : zx[14] ? 1'b0 : t[224],
								mx[13] ? a[208] : zx[13] ? 1'b0 : t[208],
								mx[12] ? a[192] : zx[12] ? 1'b0 : t[192],
								mx[11] ? a[176] : zx[11] ? 1'b0 : t[176],
								mx[10] ? a[160] : zx[10] ? 1'b0 : t[160],
								mx[ 9] ? a[144] : zx[ 9] ? 1'b0 : t[144],
								mx[ 8] ? a[128] : zx[ 8] ? 1'b0 : t[128],
								mx[ 7] ? a[112] : zx[ 7] ? 1'b0 : t[112],
								mx[ 6] ? a[ 96] : zx[ 6] ? 1'b0 : t[ 96],
								mx[ 5] ? a[ 80] : zx[ 5] ? 1'b0 : t[ 80],
								mx[ 4] ? a[ 64] : zx[ 4] ? 1'b0 : t[ 64],
								mx[ 3] ? a[ 48] : zx[ 3] ? 1'b0 : t[ 48],
								mx[ 2] ? a[ 32] : zx[ 2] ? 1'b0 : t[ 32],
								mx[ 1] ? a[ 16] : zx[ 1] ? 1'b0 : t[ 16],
								mx[ 0] ? a[  0] : zx[ 0] ? 1'b0 : t[  0]
							};
	tetra_para:	o = {
								mx[ 7] ? a[224] : zx[ 7] ? 1'b0 : t[224],
								mx[ 6] ? a[192] : zx[ 6] ? 1'b0 : t[192],
								mx[ 5] ? a[160] : zx[ 5] ? 1'b0 : t[160],
								mx[ 4] ? a[128] : zx[ 4] ? 1'b0 : t[128],
								mx[ 3] ? a[ 96] : zx[ 3] ? 1'b0 : t[ 96],
								mx[ 2] ? a[ 64] : zx[ 2] ? 1'b0 : t[ 64],
								mx[ 1] ? a[ 32] : zx[ 1] ? 1'b0 : t[ 32],
								mx[ 0] ? a[  0] : zx[ 0] ? 1'b0 : t[  0]
							};
	octa_para:	o = {
								mx[ 3] ? a[192] : zx[ 3] ? 1'b0 : t[192],
								mx[ 2] ? a[128] : zx[ 2] ? 1'b0 : t[128],
								mx[ 1] ? a[ 64] : zx[ 1] ? 1'b0 : t[ 64],
								mx[ 0] ? a[  0] : zx[ 0] ? 1'b0 : t[  0]
							};
	hexi_para:	o = {
								mx[ 1] ? a[128] : zx[ 1] ? 1'b0 : t[128],
								mx[ 0] ? a[  0] : zx[ 0] ? 1'b0 : t[  0]
							};
	default:	o = 256'd0;
	endcase
end
endtask

endmodule
