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
//
`include "nvio3-defines.sv"
`include "nvio3-config.sv"

module alu(rst, clk, ld, abort, instr, fmt, store, a, b, c, t, m, z, pc, Ra, tgt, tgt2,
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

integer n;
genvar g;

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
if (SIMD || g < 1)
multiplier #(128) umult128
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr)&& (fmt==hexi || fmt==hexi_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[(g+1)*128-1:g*128]),
	.b(b[(g+1)*128-1:g*128]),
	.o(prod[(g+1)*256-1:g * 256]),
	.done(mult_done128[g]),
	.idle(mult_idle128[g])
);
end
endgenerate

generate begin : mult64s
for (g = 0; g < 4; g = g + 1)
if (SIMD || g < 1)
multiplier #(64) umult64
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr)&& (fmt==octa || fmt==octa_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[(g+1)*64-1:g*64]),
	.b(b[(g+1)*64-1:g*64]),
	.o(prod64[(g+1)*128-1:g * 128]),
	.done(mult_done64[g]),
	.idle(mult_idle64[g])
);
end
endgenerate

generate begin : mult32s
for (g = 0; g < 8; g = g + 1)
if (SIMD || g < 1)
multiplier #(32) umult32
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (fmt==tetra || fmt==tetra_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[(g+1)*32-1:g*32]),
	.b(b[(g+1)*32-1:g*32]),
	.o(prod32[(g+1)*64-1:g * 64]),
	.done(mult_done32[g]),
	.idle(mult_idle32[g])
);
end
endgenerate

generate begin : mult16s
for (g = 0; g < 16; g = g + 1)
if (SIMD || g < 1)
multiplier #(16) umult16
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (fmt==wyde || fmt==wyde_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[(g+1)*16-1:g*16]),
	.b(b[(g+1)*16-1:g*16]),
	.o(prod16[(g+1)*32-1:g * 32]),
	.done(mult_done16[g]),
	.idle(mult_idle16[g])
);
end
endgenerate

generate begin : mult8s
for (g = 0; g < 32; g = g + 1)
if (SIMD || g < 1)
multiplier #(8) umult16
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (fmt==byt || fmt==byte_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[(g+1)*8-1:g*8]),
	.b(b[(g+1)*8-1:g*8]),
	.o(prod8[(g+1)*16-1:g * 16]),
	.done(mult_done8[g]),
	.idle(mult_idle8[g])
);
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
	.b(b),
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
		bshift <= b[6:0];
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
wire [DBW-1:0] and64 = a & b;
wire [DBW-1:0] or64 = a | b;
wire [DBW-1:0] xor64 = a ^ b;
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
wire signed [DBW-1:0] bs = b;
wire signed [DBW-1:0] cs = c;

wire [DBW-1:0] bmmo;
BMM ubmm1
(
	.op(1'b0),
	.a(a),
	.b(b),
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
		`CNTLZ:     o = BIG ? {57'd0,clzo128} : 64'hCCCCCCCCCCCCCCCC;
		`CNTLO:     o = BIG ? {57'd0,cloo128} : 64'hCCCCCCCCCCCCCCCC;
		`CNTPOP:    o = BIG ? {57'd0,cpopo128} : 64'hCCCCCCCCCCCCCCCC;
		`ABS:       case(fmt[1:0])
								2'd0:   o = BIG ? (a[7] ? -a[7:0] : a[7:0]) : 64'hCCCCCCCCCCCCCCCC;
								2'd1:   o = BIG ? (a[15] ? -a[15:0] : a[15:0]) : 64'hCCCCCCCCCCCCCCCC;
								2'd2:   o = BIG ? (a[31] ? -a[31:0] : a[31:0]) : 64'hCCCCCCCCCCCCCCCC;
								2'd3:   o = BIG ? (a[63] ? -a : a) : 64'hCCCCCCCCCCCCCCCC;
								endcase
		`NOT:   case(fmt[1:0])
						2'd0:   o = {~|a[63:56],~|a[55:48],~|a[47:40],~|a[39:32],~|a[31:24],~|a[23:16],~|a[15:8],~|a[7:0]};
						2'd1:   o = {~|a[63:48],~|a[47:32],~|a[31:16],~|a[15:0]};
						2'd2:   o = {~|a[63:32],~|a[31:0]};
						2'd3:   o = ~|a[63:0];
						endcase
		`NEG:
						case(fmt[1:0])
						2'd0:	o = {-a[63:56],-a[55:48],-a[47:40],-a[39:32],-a[31:24],-a[23:16],-a[15:8],-a[7:0]};
						2'd1: o = {-a[63:48],-a[47:32],-a[31:16],-a[15:0]};
						2'd2:	o = {-a[63:32],-a[31:0]};
						2'd3:	o = -a;
						endcase
    `MOV:		o = a;
		`PTR:		case (instr[25:23])
						3'd0:	o = a==64'hFFF0100000000000 || a==64'h0;
						3'd1:	o = a[63:44]==20'hFFF01;
						3'd2:	o = a[63:44]==20'hFFF02;
						default:	o = 64'hDEADDEADDEADDEAD;
						endcase
//	        `REDOR: case(fmt[1:0])
//	                2'd0:   o = redor8;
//	                2'd1:   o = redor16;
//	                2'd2:   o = redor32;
//	                2'd3:   o = redor64;
//	                endcase
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
		default:    o = 64'hDEADDEADDEADDEAD;
		endcase

`R2,`R2S:
	casez(instr[`FUNCT6])
  `ADD:		tskAdd(fmt,m,z,a,b,t,o);
  `SUB:		tskSub(fmt,m,z,a,b,t,o);
  `CMP:		tskCmp(fmt,a,b,t,o);
  `CMPU:	tskCmpu(fmt,a,b,t,o);
  `AND:   tskAnd(fmt,m,z,a,b,t,o);
  `OR:    tskOr(fmt,m,z,a,b,t,o);
  `XOR:   tskXor(fmt,m,z,a,b,t,o);
  `NAND:  tskNand(fmt,m,z,a,b,t,o);
  `NOR:   tskNor(fmt,m,z,a,b,t,o);
  `XNOR:  tskXnor(fmt,m,z,a,b,t,o);
	`SEQ:		tskSeq(fmt,a,b,o);
  `SLT:   tskSlt(fmt,a,b,o);
  `SLTU:  tskSltu(fmt,a,b,o);
  `SLE:   tskSle(fmt,a,b,o);
  `SLEU:  tskSleu(fmt,a,b,o);
  `SHLI,`ASLI,`SHRI,`ASRI,`ROLI,`RORI,
  `SHL,`ASL,`SHR,`ASR,`ROL,`ROR:
  	case(fmt)
  	byt:	o = {t[`HEXI1],{120{1'b0}},shfto8[7:0]};
  	wyde:	o = {t[`HEXI1],{112{1'b0}},shfto16[15:0]};
  	tetra:	o = {t[`HEXI1],{96{1'b0}},shfto32[31:0]};
  	octa:	o = {t[`HEXI1],{64{1'b0}},shfto64[31:0]};
  	hexi:	o = {t[`HEXI1],shfto128[31:0]};
  	byte_para: 	o = shfto8;
  	wyde_para:	o = shfto16;
  	tetra_para:	o = shfto32;
  	octa_para:	o = shfto64;
  	hexi_para:	o = shfto128;
  	default:	o = shfto128;
  	endcase
  `BMM:		o = BIG ? bmmo : {64{4'hC}};
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
	                    o[n] <= a[n] ? b[n] : c[n];
	    `MULU,`MUL:
	    	begin
	        case(fmt)
	        byt:	o = prod8[15:0];
	        wyde: o = prod16[31:0];
	        tetra:	o = prod32[63:0];
	        octa:		o = prod64[127:0];
	        hexi:		o = prod128;
	        byte_para:		o = prod8;
	        wyde_para:	o = prod16;
	        tetra_para:	o = prod32;
	        octa_para:	o = prod64;
	        hexi_para:	o = prod128;
					default:		o = prod128;
					endcase
	    	end
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
	    `BYTNDX:	o = bndxo;
	    `WYDNDX:	o = wndxo;
	    `MIN: tskMin(fmt,m,z,a,b,t,o);
	    `MAX: tskMax(fmt,m,z,a,b,t,o);
	    `MAJ:		o = (a & b) | (a & c) | (b & c);
	    // PTRDIF does an arithmetic shift right.
	    `PTRDIF:	
	    	begin
	    		if (BIG) begin
		    		o1 = a[43:0] - b[43:0];
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
	cro[0] = o[`HEXI0]==128'd0;
	cro[1] = o[127];
	cro[4] = o[0];
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

task tskAdd;
input [3:0] fmt;
input [31:0] m;
input z;
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
			o[255:64] = {192{o[63]}};
			o[`HEXI1] = t[`HEXI1];
		end
	hexi:
		begin
			o[`HEXI0] = a[`HEXI0] + b[`HEXI0];
			o[`HEXI1] = t[`HEXI1];
		end
	byte_para:
		begin
			o[`BYTE0] = m[0] ? a[`BYTE0] + b[`BYTE0] : z ? 8'd0 : t[`BYTE0];
			o[`BYTE1] = m[1] ? a[`BYTE1] + b[`BYTE1] : z ? 8'd0 : t[`BYTE1];
			o[`BYTE2] = m[2] ? a[`BYTE2] + b[`BYTE2] : z ? 8'd0 : t[`BYTE2];
			o[`BYTE3] = m[3] ? a[`BYTE3] + b[`BYTE3] : z ? 8'd0 : t[`BYTE3];
			o[`BYTE4] = m[4] ? a[`BYTE4] + b[`BYTE4] : z ? 8'd0 : t[`BYTE4];
			o[`BYTE5] = m[5] ? a[`BYTE5] + b[`BYTE5] : z ? 8'd0 : t[`BYTE5];
			o[`BYTE6] = m[6] ? a[`BYTE6] + b[`BYTE6] : z ? 8'd0 : t[`BYTE6];
			o[`BYTE7] = m[7] ? a[`BYTE7] + b[`BYTE7] : z ? 8'd0 : t[`BYTE7];
			o[`BYTE8] = m[8] ? a[`BYTE8] + b[`BYTE8] : z ? 8'd0 : t[`BYTE8];
			o[`BYTE9] = m[9] ? a[`BYTE9] + b[`BYTE9] : z ? 8'd0 : t[`BYTE9];
			o[`BYTE10] = m[10] ? a[`BYTE10] + b[`BYTE10] : z ? 8'd0 : t[`BYTE10];
			o[`BYTE11] = m[11] ? a[`BYTE11] + b[`BYTE11] : z ? 8'd0 : t[`BYTE11];
			o[`BYTE12] = m[12] ? a[`BYTE12] + b[`BYTE12] : z ? 8'd0 : t[`BYTE12];
			o[`BYTE13] = m[13] ? a[`BYTE13] + b[`BYTE13] : z ? 8'd0 : t[`BYTE13];
			o[`BYTE14] = m[14] ? a[`BYTE14] + b[`BYTE14] : z ? 8'd0 : t[`BYTE14];
			o[`BYTE15] = m[15] ? a[`BYTE15] + b[`BYTE15] : z ? 8'd0 : t[`BYTE15];
			o[`BYTE16] = m[16] ? a[`BYTE16] + b[`BYTE16] : z ? 8'd0 : t[`BYTE16];
			o[`BYTE17] = m[17] ? a[`BYTE17] + b[`BYTE17] : z ? 8'd0 : t[`BYTE17];
			o[`BYTE18] = m[18] ? a[`BYTE18] + b[`BYTE18] : z ? 8'd0 : t[`BYTE18];
			o[`BYTE19] = m[19] ? a[`BYTE19] + b[`BYTE19] : z ? 8'd0 : t[`BYTE19];
			o[`BYTE20] = m[20] ? a[`BYTE20] + b[`BYTE20] : z ? 8'd0 : t[`BYTE20];
			o[`BYTE21] = m[21] ? a[`BYTE21] + b[`BYTE21] : z ? 8'd0 : t[`BYTE21];
			o[`BYTE22] = m[22] ? a[`BYTE22] + b[`BYTE22] : z ? 8'd0 : t[`BYTE22];
			o[`BYTE23] = m[23] ? a[`BYTE23] + b[`BYTE23] : z ? 8'd0 : t[`BYTE23];
			o[`BYTE24] = m[24] ? a[`BYTE24] + b[`BYTE24] : z ? 8'd0 : t[`BYTE24];
			o[`BYTE25] = m[25] ? a[`BYTE25] + b[`BYTE25] : z ? 8'd0 : t[`BYTE25];
			o[`BYTE26] = m[26] ? a[`BYTE26] + b[`BYTE26] : z ? 8'd0 : t[`BYTE26];
			o[`BYTE27] = m[27] ? a[`BYTE27] + b[`BYTE27] : z ? 8'd0 : t[`BYTE27];
			o[`BYTE28] = m[28] ? a[`BYTE28] + b[`BYTE28] : z ? 8'd0 : t[`BYTE28];
			o[`BYTE29] = m[29] ? a[`BYTE29] + b[`BYTE29] : z ? 8'd0 : t[`BYTE29];
			o[`BYTE30] = m[30] ? a[`BYTE30] + b[`BYTE30] : z ? 8'd0 : t[`BYTE30];
			o[`BYTE31] = m[31] ? a[`BYTE31] + b[`BYTE31] : z ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
			o[`WYDE0] = m[0] ? a[`WYDE0] + b[`WYDE0] : z ? 16'd0 : t[`WYDE0];
			o[`WYDE1] = m[1] ? a[`WYDE1] + b[`WYDE1] : z ? 16'd0 : t[`WYDE1];
			o[`WYDE2] = m[2] ? a[`WYDE2] + b[`WYDE2] : z ? 16'd0 : t[`WYDE2];
			o[`WYDE3] = m[3] ? a[`WYDE3] + b[`WYDE3] : z ? 16'd0 : t[`WYDE3];
			o[`WYDE4] = m[4] ? a[`WYDE4] + b[`WYDE4] : z ? 16'd0 : t[`WYDE4];
			o[`WYDE5] = m[5] ? a[`WYDE5] + b[`WYDE5] : z ? 16'd0 : t[`WYDE5];
			o[`WYDE6] = m[6] ? a[`WYDE6] + b[`WYDE6] : z ? 16'd0 : t[`WYDE6];
			o[`WYDE7] = m[7] ? a[`WYDE7] + b[`WYDE7] : z ? 16'd0 : t[`WYDE7];
			o[`WYDE8] = m[8] ? a[`WYDE8] + b[`WYDE8] : z ? 16'd0 : t[`WYDE8];
			o[`WYDE9] = m[9] ? a[`WYDE9] + b[`WYDE9] : z ? 16'd0 : t[`WYDE9];
			o[`WYDE10] = m[10] ? a[`WYDE10] + b[`WYDE10] : z ? 16'd0 : t[`WYDE10];
			o[`WYDE11] = m[11] ? a[`WYDE11] + b[`WYDE11] : z ? 16'd0 : t[`WYDE11];
			o[`WYDE12] = m[12] ? a[`WYDE12] + b[`WYDE12] : z ? 16'd0 : t[`WYDE12];
			o[`WYDE13] = m[13] ? a[`WYDE13] + b[`WYDE13] : z ? 16'd0 : t[`WYDE13];
			o[`WYDE14] = m[14] ? a[`WYDE14] + b[`WYDE14] : z ? 16'd0 : t[`WYDE14];
			o[`WYDE15] = m[15] ? a[`WYDE15] + b[`WYDE15] : z ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
			o[`TETRA0] = m[0] ? a[`TETRA0] + b[`TETRA0] : z ? 32'd0 : t[`TETRA0];
			o[`TETRA1] = m[1] ? a[`TETRA1] + b[`TETRA1] : z ? 32'd0 : t[`TETRA1];
			o[`TETRA2] = m[2] ? a[`TETRA2] + b[`TETRA2] : z ? 32'd0 : t[`TETRA2];
			o[`TETRA3] = m[3] ? a[`TETRA3] + b[`TETRA3] : z ? 32'd0 : t[`TETRA3];
			o[`TETRA4] = m[4] ? a[`TETRA4] + b[`TETRA4] : z ? 32'd0 : t[`TETRA4];
			o[`TETRA5] = m[5] ? a[`TETRA5] + b[`TETRA5] : z ? 32'd0 : t[`TETRA5];
			o[`TETRA6] = m[6] ? a[`TETRA6] + b[`TETRA6] : z ? 32'd0 : t[`TETRA6];
			o[`TETRA7] = m[7] ? a[`TETRA7] + b[`TETRA7] : z ? 32'd0 : t[`TETRA7];
		end
	octa_para:
		begin
			o[`OCTA0] = m[0] ? a[`OCTA0] + b[`OCTA0] : z ? 64'd0 : t[`OCTA0];
			o[`OCTA1] = m[1] ? a[`OCTA1] + b[`OCTA1] : z ? 64'd0 : t[`OCTA1];
			o[`OCTA2] = m[2] ? a[`OCTA2] + b[`OCTA2] : z ? 64'd0 : t[`OCTA2];
			o[`OCTA3] = m[3] ? a[`OCTA3] + b[`OCTA3] : z ? 64'd0 : t[`OCTA3];
		end
	hexi_para:
		begin
			o[`HEXI0] = m[0] ? a[`HEXI0] + b[`HEXI0] : z ? 128'd0 : t[`HEXI0];
			o[`HEXI1] = m[1] ? a[`HEXI1] + b[`HEXI1] : z ? 128'd0 : t[`HEXI1];
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
input [31:0] m;
input z;
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
			o[255:64] = {192{o[63]}};
			o[`HEXI1] = t[`HEXI1];
		end
	hexi:
		begin
			o[`HEXI0] = a[`HEXI0] - b[`HEXI0];
			o[`HEXI1] = t[`HEXI1];
		end
	byte_para:
		begin
			o[`BYTE0] = m[0] ? a[`BYTE0] - b[`BYTE0] : z ? 8'd0 : t[`BYTE0];
			o[`BYTE1] = m[1] ? a[`BYTE1] - b[`BYTE1] : z ? 8'd0 : t[`BYTE1];
			o[`BYTE2] = m[2] ? a[`BYTE2] - b[`BYTE2] : z ? 8'd0 : t[`BYTE2];
			o[`BYTE3] = m[3] ? a[`BYTE3] - b[`BYTE3] : z ? 8'd0 : t[`BYTE3];
			o[`BYTE4] = m[4] ? a[`BYTE4] - b[`BYTE4] : z ? 8'd0 : t[`BYTE4];
			o[`BYTE5] = m[5] ? a[`BYTE5] - b[`BYTE5] : z ? 8'd0 : t[`BYTE5];
			o[`BYTE6] = m[6] ? a[`BYTE6] - b[`BYTE6] : z ? 8'd0 : t[`BYTE6];
			o[`BYTE7] = m[7] ? a[`BYTE7] - b[`BYTE7] : z ? 8'd0 : t[`BYTE7];
			o[`BYTE8] = m[8] ? a[`BYTE8] - b[`BYTE8] : z ? 8'd0 : t[`BYTE8];
			o[`BYTE9] = m[9] ? a[`BYTE9] - b[`BYTE9] : z ? 8'd0 : t[`BYTE9];
			o[`BYTE10] = m[10] ? a[`BYTE10] - b[`BYTE10] : z ? 8'd0 : t[`BYTE10];
			o[`BYTE11] = m[11] ? a[`BYTE11] - b[`BYTE11] : z ? 8'd0 : t[`BYTE11];
			o[`BYTE12] = m[12] ? a[`BYTE12] - b[`BYTE12] : z ? 8'd0 : t[`BYTE12];
			o[`BYTE13] = m[13] ? a[`BYTE13] - b[`BYTE13] : z ? 8'd0 : t[`BYTE13];
			o[`BYTE14] = m[14] ? a[`BYTE14] - b[`BYTE14] : z ? 8'd0 : t[`BYTE14];
			o[`BYTE15] = m[15] ? a[`BYTE15] - b[`BYTE15] : z ? 8'd0 : t[`BYTE15];
			o[`BYTE16] = m[16] ? a[`BYTE16] - b[`BYTE16] : z ? 8'd0 : t[`BYTE16];
			o[`BYTE17] = m[17] ? a[`BYTE17] - b[`BYTE17] : z ? 8'd0 : t[`BYTE17];
			o[`BYTE18] = m[18] ? a[`BYTE18] - b[`BYTE18] : z ? 8'd0 : t[`BYTE18];
			o[`BYTE19] = m[19] ? a[`BYTE19] - b[`BYTE19] : z ? 8'd0 : t[`BYTE19];
			o[`BYTE20] = m[20] ? a[`BYTE20] - b[`BYTE20] : z ? 8'd0 : t[`BYTE20];
			o[`BYTE21] = m[21] ? a[`BYTE21] - b[`BYTE21] : z ? 8'd0 : t[`BYTE21];
			o[`BYTE22] = m[22] ? a[`BYTE22] - b[`BYTE22] : z ? 8'd0 : t[`BYTE22];
			o[`BYTE23] = m[23] ? a[`BYTE23] - b[`BYTE23] : z ? 8'd0 : t[`BYTE23];
			o[`BYTE24] = m[24] ? a[`BYTE24] - b[`BYTE24] : z ? 8'd0 : t[`BYTE24];
			o[`BYTE25] = m[25] ? a[`BYTE25] - b[`BYTE25] : z ? 8'd0 : t[`BYTE25];
			o[`BYTE26] = m[26] ? a[`BYTE26] - b[`BYTE26] : z ? 8'd0 : t[`BYTE26];
			o[`BYTE27] = m[27] ? a[`BYTE27] - b[`BYTE27] : z ? 8'd0 : t[`BYTE27];
			o[`BYTE28] = m[28] ? a[`BYTE28] - b[`BYTE28] : z ? 8'd0 : t[`BYTE28];
			o[`BYTE29] = m[29] ? a[`BYTE29] - b[`BYTE29] : z ? 8'd0 : t[`BYTE29];
			o[`BYTE30] = m[30] ? a[`BYTE30] - b[`BYTE30] : z ? 8'd0 : t[`BYTE30];
			o[`BYTE31] = m[31] ? a[`BYTE31] - b[`BYTE31] : z ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
			o[`WYDE0] = m[0] ? a[`WYDE0] - b[`WYDE0] : z ? 16'd0 : t[`WYDE0];
			o[`WYDE1] = m[1] ? a[`WYDE1] - b[`WYDE1] : z ? 16'd0 : t[`WYDE1];
			o[`WYDE2] = m[2] ? a[`WYDE2] - b[`WYDE2] : z ? 16'd0 : t[`WYDE2];
			o[`WYDE3] = m[3] ? a[`WYDE3] - b[`WYDE3] : z ? 16'd0 : t[`WYDE3];
			o[`WYDE4] = m[4] ? a[`WYDE4] - b[`WYDE4] : z ? 16'd0 : t[`WYDE4];
			o[`WYDE5] = m[5] ? a[`WYDE5] - b[`WYDE5] : z ? 16'd0 : t[`WYDE5];
			o[`WYDE6] = m[6] ? a[`WYDE6] - b[`WYDE6] : z ? 16'd0 : t[`WYDE6];
			o[`WYDE7] = m[7] ? a[`WYDE7] - b[`WYDE7] : z ? 16'd0 : t[`WYDE7];
			o[`WYDE8] = m[8] ? a[`WYDE8] - b[`WYDE8] : z ? 16'd0 : t[`WYDE8];
			o[`WYDE9] = m[9] ? a[`WYDE9] - b[`WYDE9] : z ? 16'd0 : t[`WYDE9];
			o[`WYDE10] = m[10] ? a[`WYDE10] - b[`WYDE10] : z ? 16'd0 : t[`WYDE10];
			o[`WYDE11] = m[11] ? a[`WYDE11] - b[`WYDE11] : z ? 16'd0 : t[`WYDE11];
			o[`WYDE12] = m[12] ? a[`WYDE12] - b[`WYDE12] : z ? 16'd0 : t[`WYDE12];
			o[`WYDE13] = m[13] ? a[`WYDE13] - b[`WYDE13] : z ? 16'd0 : t[`WYDE13];
			o[`WYDE14] = m[14] ? a[`WYDE14] - b[`WYDE14] : z ? 16'd0 : t[`WYDE14];
			o[`WYDE15] = m[15] ? a[`WYDE15] - b[`WYDE15] : z ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
			o[`TETRA0] = m[0] ? a[`TETRA0] - b[`TETRA0] : z ? 32'd0 : t[`TETRA0];
			o[`TETRA1] = m[1] ? a[`TETRA1] - b[`TETRA1] : z ? 32'd0 : t[`TETRA1];
			o[`TETRA2] = m[2] ? a[`TETRA2] - b[`TETRA2] : z ? 32'd0 : t[`TETRA2];
			o[`TETRA3] = m[3] ? a[`TETRA3] - b[`TETRA3] : z ? 32'd0 : t[`TETRA3];
			o[`TETRA4] = m[4] ? a[`TETRA4] - b[`TETRA4] : z ? 32'd0 : t[`TETRA4];
			o[`TETRA5] = m[5] ? a[`TETRA5] - b[`TETRA5] : z ? 32'd0 : t[`TETRA5];
			o[`TETRA6] = m[6] ? a[`TETRA6] - b[`TETRA6] : z ? 32'd0 : t[`TETRA6];
			o[`TETRA7] = m[7] ? a[`TETRA7] - b[`TETRA7] : z ? 32'd0 : t[`TETRA7];
		end
	octa_para:
		begin
			o[`OCTA0] = m[0] ? a[`OCTA0] - b[`OCTA0] : z ? 64'd0 : t[`OCTA0];
			o[`OCTA1] = m[1] ? a[`OCTA1] - b[`OCTA1] : z ? 64'd0 : t[`OCTA1];
			o[`OCTA2] = m[2] ? a[`OCTA2] - b[`OCTA2] : z ? 64'd0 : t[`OCTA2];
			o[`OCTA3] = m[3] ? a[`OCTA3] - b[`OCTA3] : z ? 64'd0 : t[`OCTA3];
		end
	hexi_para:
		begin
			o[`HEXI0] = m[0] ? a[`HEXI0] - b[`HEXI0] : z ? 128'd0 : t[`HEXI0];
			o[`HEXI1] = m[1] ? a[`HEXI1] - b[`HEXI1] : z ? 128'd0 : t[`HEXI1];
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
input [31:0] m;
input z;
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
		o[`BYTE0] = m[0] ? a[`BYTE0] & b[`BYTE0] : z ? 8'd0 : t[`BYTE0];
		o[`BYTE1] = m[1] ? a[`BYTE1] & b[`BYTE1] : z ? 8'd0 : t[`BYTE1];
		o[`BYTE2] = m[2] ? a[`BYTE2] & b[`BYTE2] : z ? 8'd0 : t[`BYTE2];
		o[`BYTE3] = m[3] ? a[`BYTE3] & b[`BYTE3] : z ? 8'd0 : t[`BYTE3];
		o[`BYTE4] = m[4] ? a[`BYTE4] & b[`BYTE4] : z ? 8'd0 : t[`BYTE4];
		o[`BYTE5] = m[5] ? a[`BYTE5] & b[`BYTE5] : z ? 8'd0 : t[`BYTE5];
		o[`BYTE6] = m[6] ? a[`BYTE6] & b[`BYTE6] : z ? 8'd0 : t[`BYTE6];
		o[`BYTE7] = m[7] ? a[`BYTE7] & b[`BYTE7] : z ? 8'd0 : t[`BYTE7];
		o[`BYTE8] = m[8] ? a[`BYTE8] & b[`BYTE8] : z ? 8'd0 : t[`BYTE8];
		o[`BYTE9] = m[9] ? a[`BYTE9] & b[`BYTE9] : z ? 8'd0 : t[`BYTE9];
		o[`BYTE10] = m[10] ? a[`BYTE10] & b[`BYTE10] : z ? 8'd0 : t[`BYTE10];
		o[`BYTE11] = m[11] ? a[`BYTE11] & b[`BYTE11] : z ? 8'd0 : t[`BYTE11];
		o[`BYTE12] = m[12] ? a[`BYTE12] & b[`BYTE12] : z ? 8'd0 : t[`BYTE12];
		o[`BYTE13] = m[13] ? a[`BYTE13] & b[`BYTE13] : z ? 8'd0 : t[`BYTE13];
		o[`BYTE14] = m[14] ? a[`BYTE14] & b[`BYTE14] : z ? 8'd0 : t[`BYTE14];
		o[`BYTE15] = m[15] ? a[`BYTE15] & b[`BYTE15] : z ? 8'd0 : t[`BYTE15];
		o[`BYTE16] = m[16] ? a[`BYTE16] & b[`BYTE16] : z ? 8'd0 : t[`BYTE16];
		o[`BYTE17] = m[17] ? a[`BYTE17] & b[`BYTE17] : z ? 8'd0 : t[`BYTE17];
		o[`BYTE18] = m[18] ? a[`BYTE18] & b[`BYTE18] : z ? 8'd0 : t[`BYTE18];
		o[`BYTE19] = m[19] ? a[`BYTE19] & b[`BYTE19] : z ? 8'd0 : t[`BYTE19];
		o[`BYTE20] = m[20] ? a[`BYTE20] & b[`BYTE20] : z ? 8'd0 : t[`BYTE20];
		o[`BYTE21] = m[21] ? a[`BYTE21] & b[`BYTE21] : z ? 8'd0 : t[`BYTE21];
		o[`BYTE22] = m[22] ? a[`BYTE22] & b[`BYTE22] : z ? 8'd0 : t[`BYTE22];
		o[`BYTE23] = m[23] ? a[`BYTE23] & b[`BYTE23] : z ? 8'd0 : t[`BYTE23];
		o[`BYTE24] = m[24] ? a[`BYTE24] & b[`BYTE24] : z ? 8'd0 : t[`BYTE24];
		o[`BYTE25] = m[25] ? a[`BYTE25] & b[`BYTE25] : z ? 8'd0 : t[`BYTE25];
		o[`BYTE26] = m[26] ? a[`BYTE26] & b[`BYTE26] : z ? 8'd0 : t[`BYTE26];
		o[`BYTE27] = m[27] ? a[`BYTE27] & b[`BYTE27] : z ? 8'd0 : t[`BYTE27];
		o[`BYTE28] = m[28] ? a[`BYTE28] & b[`BYTE28] : z ? 8'd0 : t[`BYTE28];
		o[`BYTE29] = m[29] ? a[`BYTE29] & b[`BYTE29] : z ? 8'd0 : t[`BYTE29];
		o[`BYTE30] = m[30] ? a[`BYTE30] & b[`BYTE30] : z ? 8'd0 : t[`BYTE30];
		o[`BYTE31] = m[31] ? a[`BYTE31] & b[`BYTE31] : z ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
		o[`WYDE0] = m[0] ? a[`WYDE0] & b[`WYDE0] : z ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = m[1] ? a[`WYDE1] & b[`WYDE1] : z ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = m[2] ? a[`WYDE2] & b[`WYDE2] : z ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = m[3] ? a[`WYDE3] & b[`WYDE3] : z ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = m[4] ? a[`WYDE4] & b[`WYDE4] : z ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = m[5] ? a[`WYDE5] & b[`WYDE5] : z ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = m[6] ? a[`WYDE6] & b[`WYDE6] : z ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = m[7] ? a[`WYDE7] & b[`WYDE7] : z ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = m[8] ? a[`WYDE8] & b[`WYDE8] : z ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = m[9] ? a[`WYDE9] & b[`WYDE9] : z ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = m[10] ? a[`WYDE10] & b[`WYDE10] : z ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = m[11] ? a[`WYDE11] & b[`WYDE11] : z ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = m[12] ? a[`WYDE12] & b[`WYDE12] : z ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = m[13] ? a[`WYDE13] & b[`WYDE13] : z ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = m[14] ? a[`WYDE14] & b[`WYDE14] : z ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = m[15] ? a[`WYDE15] & b[`WYDE15] : z ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = m[0] ? a[`TETRA0] & b[`TETRA0] : z ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = m[1] ? a[`TETRA1] & b[`TETRA1] : z ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = m[2] ? a[`TETRA2] & b[`TETRA2] : z ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = m[3] ? a[`TETRA3] & b[`TETRA3] : z ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = m[4] ? a[`TETRA4] & b[`TETRA4] : z ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = m[5] ? a[`TETRA5] & b[`TETRA5] : z ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = m[6] ? a[`TETRA6] & b[`TETRA6] : z ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = m[7] ? a[`TETRA7] & b[`TETRA7] : z ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = m[0] ? a[`OCTA0] & b[`OCTA0] : z ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = m[1] ? a[`OCTA1] & b[`OCTA1] : z ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = m[2] ? a[`OCTA2] & b[`OCTA2] : z ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = m[3] ? a[`OCTA3] & b[`OCTA3] : z ? 64'd0 : t[`OCTA3];
		end
hexi_para:
	begin
		o[`HEXI0] = m[0] ? a[`HEXI0] & b[`HEXI0] : z ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = m[1] ? a[`HEXI1] & b[`HEXI1] : z ? 128'd0 : t[`HEXI1];
		end
	default:
		o = a & b;
	endcase
end
endtask

task tskOr;
input [3:0] fmt;
input [31:0] m;
input z;
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
		o[`BYTE0] = m[0] ? a[`BYTE0] | b[`BYTE0] : z ? 8'd0 : t[`BYTE0];
		o[`BYTE1] = m[1] ? a[`BYTE1] | b[`BYTE1] : z ? 8'd0 : t[`BYTE1];
		o[`BYTE2] = m[2] ? a[`BYTE2] | b[`BYTE2] : z ? 8'd0 : t[`BYTE2];
		o[`BYTE3] = m[3] ? a[`BYTE3] | b[`BYTE3] : z ? 8'd0 : t[`BYTE3];
		o[`BYTE4] = m[4] ? a[`BYTE4] | b[`BYTE4] : z ? 8'd0 : t[`BYTE4];
		o[`BYTE5] = m[5] ? a[`BYTE5] | b[`BYTE5] : z ? 8'd0 : t[`BYTE5];
		o[`BYTE6] = m[6] ? a[`BYTE6] | b[`BYTE6] : z ? 8'd0 : t[`BYTE6];
		o[`BYTE7] = m[7] ? a[`BYTE7] | b[`BYTE7] : z ? 8'd0 : t[`BYTE7];
		o[`BYTE8] = m[8] ? a[`BYTE8] | b[`BYTE8] : z ? 8'd0 : t[`BYTE8];
		o[`BYTE9] = m[9] ? a[`BYTE9] | b[`BYTE9] : z ? 8'd0 : t[`BYTE9];
		o[`BYTE10] = m[10] ? a[`BYTE10] | b[`BYTE10] : z ? 8'd0 : t[`BYTE10];
		o[`BYTE11] = m[11] ? a[`BYTE11] | b[`BYTE11] : z ? 8'd0 : t[`BYTE11];
		o[`BYTE12] = m[12] ? a[`BYTE12] | b[`BYTE12] : z ? 8'd0 : t[`BYTE12];
		o[`BYTE13] = m[13] ? a[`BYTE13] | b[`BYTE13] : z ? 8'd0 : t[`BYTE13];
		o[`BYTE14] = m[14] ? a[`BYTE14] | b[`BYTE14] : z ? 8'd0 : t[`BYTE14];
		o[`BYTE15] = m[15] ? a[`BYTE15] | b[`BYTE15] : z ? 8'd0 : t[`BYTE15];
		o[`BYTE16] = m[16] ? a[`BYTE16] | b[`BYTE16] : z ? 8'd0 : t[`BYTE16];
		o[`BYTE17] = m[17] ? a[`BYTE17] | b[`BYTE17] : z ? 8'd0 : t[`BYTE17];
		o[`BYTE18] = m[18] ? a[`BYTE18] | b[`BYTE18] : z ? 8'd0 : t[`BYTE18];
		o[`BYTE19] = m[19] ? a[`BYTE19] | b[`BYTE19] : z ? 8'd0 : t[`BYTE19];
		o[`BYTE20] = m[20] ? a[`BYTE20] | b[`BYTE20] : z ? 8'd0 : t[`BYTE20];
		o[`BYTE21] = m[21] ? a[`BYTE21] | b[`BYTE21] : z ? 8'd0 : t[`BYTE21];
		o[`BYTE22] = m[22] ? a[`BYTE22] | b[`BYTE22] : z ? 8'd0 : t[`BYTE22];
		o[`BYTE23] = m[23] ? a[`BYTE23] | b[`BYTE23] : z ? 8'd0 : t[`BYTE23];
		o[`BYTE24] = m[24] ? a[`BYTE24] | b[`BYTE24] : z ? 8'd0 : t[`BYTE24];
		o[`BYTE25] = m[25] ? a[`BYTE25] | b[`BYTE25] : z ? 8'd0 : t[`BYTE25];
		o[`BYTE26] = m[26] ? a[`BYTE26] | b[`BYTE26] : z ? 8'd0 : t[`BYTE26];
		o[`BYTE27] = m[27] ? a[`BYTE27] | b[`BYTE27] : z ? 8'd0 : t[`BYTE27];
		o[`BYTE28] = m[28] ? a[`BYTE28] | b[`BYTE28] : z ? 8'd0 : t[`BYTE28];
		o[`BYTE29] = m[29] ? a[`BYTE29] | b[`BYTE29] : z ? 8'd0 : t[`BYTE29];
		o[`BYTE30] = m[30] ? a[`BYTE30] | b[`BYTE30] : z ? 8'd0 : t[`BYTE30];
		o[`BYTE31] = m[31] ? a[`BYTE31] | b[`BYTE31] : z ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
		o[`WYDE0] = m[0] ? a[`WYDE0] | b[`WYDE0] : z ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = m[1] ? a[`WYDE1] | b[`WYDE1] : z ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = m[2] ? a[`WYDE2] | b[`WYDE2] : z ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = m[3] ? a[`WYDE3] | b[`WYDE3] : z ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = m[4] ? a[`WYDE4] | b[`WYDE4] : z ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = m[5] ? a[`WYDE5] | b[`WYDE5] : z ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = m[6] ? a[`WYDE6] | b[`WYDE6] : z ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = m[7] ? a[`WYDE7] | b[`WYDE7] : z ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = m[8] ? a[`WYDE8] | b[`WYDE8] : z ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = m[9] ? a[`WYDE9] | b[`WYDE9] : z ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = m[10] ? a[`WYDE10] | b[`WYDE10] : z ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = m[11] ? a[`WYDE11] | b[`WYDE11] : z ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = m[12] ? a[`WYDE12] | b[`WYDE12] : z ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = m[13] ? a[`WYDE13] | b[`WYDE13] : z ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = m[14] ? a[`WYDE14] | b[`WYDE14] : z ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = m[15] ? a[`WYDE15] | b[`WYDE15] : z ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = m[0] ? a[`TETRA0] | b[`TETRA0] : z ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = m[1] ? a[`TETRA1] | b[`TETRA1] : z ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = m[2] ? a[`TETRA2] | b[`TETRA2] : z ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = m[3] ? a[`TETRA3] | b[`TETRA3] : z ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = m[4] ? a[`TETRA4] | b[`TETRA4] : z ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = m[5] ? a[`TETRA5] | b[`TETRA5] : z ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = m[6] ? a[`TETRA6] | b[`TETRA6] : z ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = m[7] ? a[`TETRA7] | b[`TETRA7] : z ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = m[0] ? a[`OCTA0] | b[`OCTA0] : z ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = m[1] ? a[`OCTA1] | b[`OCTA1] : z ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = m[2] ? a[`OCTA2] | b[`OCTA2] : z ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = m[3] ? a[`OCTA3] | b[`OCTA3] : z ? 64'd0 : t[`OCTA3];
		end
hexi_para:
	begin
		o[`HEXI0] = m[0] ? a[`HEXI0] | b[`HEXI0] : z ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = m[1] ? a[`HEXI1] | b[`HEXI1] : z ? 128'd0 : t[`HEXI1];
		end
	default:
		o = a | b;
	endcase
end
endtask

task tskXor;
input [3:0] fmt;
input [31:0] m;
input z;
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
		o[`BYTE0] = m[0] ? a[`BYTE0] ^ b[`BYTE0] : z ? 8'd0 : t[`BYTE0];
		o[`BYTE1] = m[1] ? a[`BYTE1] ^ b[`BYTE1] : z ? 8'd0 : t[`BYTE1];
		o[`BYTE2] = m[2] ? a[`BYTE2] ^ b[`BYTE2] : z ? 8'd0 : t[`BYTE2];
		o[`BYTE3] = m[3] ? a[`BYTE3] ^ b[`BYTE3] : z ? 8'd0 : t[`BYTE3];
		o[`BYTE4] = m[4] ? a[`BYTE4] ^ b[`BYTE4] : z ? 8'd0 : t[`BYTE4];
		o[`BYTE5] = m[5] ? a[`BYTE5] ^ b[`BYTE5] : z ? 8'd0 : t[`BYTE5];
		o[`BYTE6] = m[6] ? a[`BYTE6] ^ b[`BYTE6] : z ? 8'd0 : t[`BYTE6];
		o[`BYTE7] = m[7] ? a[`BYTE7] ^ b[`BYTE7] : z ? 8'd0 : t[`BYTE7];
		o[`BYTE8] = m[8] ? a[`BYTE8] ^ b[`BYTE8] : z ? 8'd0 : t[`BYTE8];
		o[`BYTE9] = m[9] ? a[`BYTE9] ^ b[`BYTE9] : z ? 8'd0 : t[`BYTE9];
		o[`BYTE10] = m[10] ? a[`BYTE10] ^ b[`BYTE10] : z ? 8'd0 : t[`BYTE10];
		o[`BYTE11] = m[11] ? a[`BYTE11] ^ b[`BYTE11] : z ? 8'd0 : t[`BYTE11];
		o[`BYTE12] = m[12] ? a[`BYTE12] ^ b[`BYTE12] : z ? 8'd0 : t[`BYTE12];
		o[`BYTE13] = m[13] ? a[`BYTE13] ^ b[`BYTE13] : z ? 8'd0 : t[`BYTE13];
		o[`BYTE14] = m[14] ? a[`BYTE14] ^ b[`BYTE14] : z ? 8'd0 : t[`BYTE14];
		o[`BYTE15] = m[15] ? a[`BYTE15] ^ b[`BYTE15] : z ? 8'd0 : t[`BYTE15];
		o[`BYTE16] = m[16] ? a[`BYTE16] ^ b[`BYTE16] : z ? 8'd0 : t[`BYTE16];
		o[`BYTE17] = m[17] ? a[`BYTE17] ^ b[`BYTE17] : z ? 8'd0 : t[`BYTE17];
		o[`BYTE18] = m[18] ? a[`BYTE18] ^ b[`BYTE18] : z ? 8'd0 : t[`BYTE18];
		o[`BYTE19] = m[19] ? a[`BYTE19] ^ b[`BYTE19] : z ? 8'd0 : t[`BYTE19];
		o[`BYTE20] = m[20] ? a[`BYTE20] ^ b[`BYTE20] : z ? 8'd0 : t[`BYTE20];
		o[`BYTE21] = m[21] ? a[`BYTE21] ^ b[`BYTE21] : z ? 8'd0 : t[`BYTE21];
		o[`BYTE22] = m[22] ? a[`BYTE22] ^ b[`BYTE22] : z ? 8'd0 : t[`BYTE22];
		o[`BYTE23] = m[23] ? a[`BYTE23] ^ b[`BYTE23] : z ? 8'd0 : t[`BYTE23];
		o[`BYTE24] = m[24] ? a[`BYTE24] ^ b[`BYTE24] : z ? 8'd0 : t[`BYTE24];
		o[`BYTE25] = m[25] ? a[`BYTE25] ^ b[`BYTE25] : z ? 8'd0 : t[`BYTE25];
		o[`BYTE26] = m[26] ? a[`BYTE26] ^ b[`BYTE26] : z ? 8'd0 : t[`BYTE26];
		o[`BYTE27] = m[27] ? a[`BYTE27] ^ b[`BYTE27] : z ? 8'd0 : t[`BYTE27];
		o[`BYTE28] = m[28] ? a[`BYTE28] ^ b[`BYTE28] : z ? 8'd0 : t[`BYTE28];
		o[`BYTE29] = m[29] ? a[`BYTE29] ^ b[`BYTE29] : z ? 8'd0 : t[`BYTE29];
		o[`BYTE30] = m[30] ? a[`BYTE30] ^ b[`BYTE30] : z ? 8'd0 : t[`BYTE30];
		o[`BYTE31] = m[31] ? a[`BYTE31] ^ b[`BYTE31] : z ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
		o[`WYDE0] = m[0] ? a[`WYDE0] ^ b[`WYDE0] : z ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = m[1] ? a[`WYDE1] ^ b[`WYDE1] : z ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = m[2] ? a[`WYDE2] ^ b[`WYDE2] : z ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = m[3] ? a[`WYDE3] ^ b[`WYDE3] : z ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = m[4] ? a[`WYDE4] ^ b[`WYDE4] : z ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = m[5] ? a[`WYDE5] ^ b[`WYDE5] : z ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = m[6] ? a[`WYDE6] ^ b[`WYDE6] : z ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = m[7] ? a[`WYDE7] ^ b[`WYDE7] : z ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = m[8] ? a[`WYDE8] ^ b[`WYDE8] : z ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = m[9] ? a[`WYDE9] ^ b[`WYDE9] : z ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = m[10] ? a[`WYDE10] ^ b[`WYDE10] : z ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = m[11] ? a[`WYDE11] ^ b[`WYDE11] : z ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = m[12] ? a[`WYDE12] ^ b[`WYDE12] : z ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = m[13] ? a[`WYDE13] ^ b[`WYDE13] : z ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = m[14] ? a[`WYDE14] ^ b[`WYDE14] : z ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = m[15] ? a[`WYDE15] ^ b[`WYDE15] : z ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = m[0] ? a[`TETRA0] ^ b[`TETRA0] : z ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = m[1] ? a[`TETRA1] ^ b[`TETRA1] : z ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = m[2] ? a[`TETRA2] ^ b[`TETRA2] : z ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = m[3] ? a[`TETRA3] ^ b[`TETRA3] : z ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = m[4] ? a[`TETRA4] ^ b[`TETRA4] : z ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = m[5] ? a[`TETRA5] ^ b[`TETRA5] : z ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = m[6] ? a[`TETRA6] ^ b[`TETRA6] : z ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = m[7] ? a[`TETRA7] ^ b[`TETRA7] : z ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = m[0] ? a[`OCTA0] ^ b[`OCTA0] : z ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = m[1] ? a[`OCTA1] ^ b[`OCTA1] : z ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = m[2] ? a[`OCTA2] ^ b[`OCTA2] : z ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = m[3] ? a[`OCTA3] ^ b[`OCTA3] : z ? 64'd0 : t[`OCTA3];
		end
hexi_para:
	begin
		o[`HEXI0] = m[0] ? a[`HEXI0] ^ b[`HEXI0] : z ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = m[1] ? a[`HEXI1] ^ b[`HEXI1] : z ? 128'd0 : t[`HEXI1];
		end
	default:
		o = a ^ b;
	endcase
end
endtask

task tskNand;
input [3:0] fmt;
input [31:0] m;
input z;
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
		o[`BYTE0] = m[0] ? ~(a[`BYTE0] & b[`BYTE0]) : z ? 8'd0 : t[`BYTE0];
		o[`BYTE1] = m[1] ? ~(a[`BYTE1] & b[`BYTE1]) : z ? 8'd0 : t[`BYTE1];
		o[`BYTE2] = m[2] ? ~(a[`BYTE2] & b[`BYTE2]) : z ? 8'd0 : t[`BYTE2];
		o[`BYTE3] = m[3] ? ~(a[`BYTE3] & b[`BYTE3]) : z ? 8'd0 : t[`BYTE3];
		o[`BYTE4] = m[4] ? ~(a[`BYTE4] & b[`BYTE4]) : z ? 8'd0 : t[`BYTE4];
		o[`BYTE5] = m[5] ? ~(a[`BYTE5] & b[`BYTE5]) : z ? 8'd0 : t[`BYTE5];
		o[`BYTE6] = m[6] ? ~(a[`BYTE6] & b[`BYTE6]) : z ? 8'd0 : t[`BYTE6];
		o[`BYTE7] = m[7] ? ~(a[`BYTE7] & b[`BYTE7]) : z ? 8'd0 : t[`BYTE7];
		o[`BYTE8] = m[8] ? ~(a[`BYTE8] & b[`BYTE8]) : z ? 8'd0 : t[`BYTE8];
		o[`BYTE9] = m[9] ? ~(a[`BYTE9] & b[`BYTE9]) : z ? 8'd0 : t[`BYTE9];
		o[`BYTE10] = m[10] ? ~(a[`BYTE10] & b[`BYTE10]) : z ? 8'd0 : t[`BYTE10];
		o[`BYTE11] = m[11] ? ~(a[`BYTE11] & b[`BYTE11]) : z ? 8'd0 : t[`BYTE11];
		o[`BYTE12] = m[12] ? ~(a[`BYTE12] & b[`BYTE12]) : z ? 8'd0 : t[`BYTE12];
		o[`BYTE13] = m[13] ? ~(a[`BYTE13] & b[`BYTE13]) : z ? 8'd0 : t[`BYTE13];
		o[`BYTE14] = m[14] ? ~(a[`BYTE14] & b[`BYTE14]) : z ? 8'd0 : t[`BYTE14];
		o[`BYTE15] = m[15] ? ~(a[`BYTE15] & b[`BYTE15]) : z ? 8'd0 : t[`BYTE15];
		o[`BYTE16] = m[16] ? ~(a[`BYTE16] & b[`BYTE16]) : z ? 8'd0 : t[`BYTE16];
		o[`BYTE17] = m[17] ? ~(a[`BYTE17] & b[`BYTE17]) : z ? 8'd0 : t[`BYTE17];
		o[`BYTE18] = m[18] ? ~(a[`BYTE18] & b[`BYTE18]) : z ? 8'd0 : t[`BYTE18];
		o[`BYTE19] = m[19] ? ~(a[`BYTE19] & b[`BYTE19]) : z ? 8'd0 : t[`BYTE19];
		o[`BYTE20] = m[20] ? ~(a[`BYTE20] & b[`BYTE20]) : z ? 8'd0 : t[`BYTE20];
		o[`BYTE21] = m[21] ? ~(a[`BYTE21] & b[`BYTE21]) : z ? 8'd0 : t[`BYTE21];
		o[`BYTE22] = m[22] ? ~(a[`BYTE22] & b[`BYTE22]) : z ? 8'd0 : t[`BYTE22];
		o[`BYTE23] = m[23] ? ~(a[`BYTE23] & b[`BYTE23]) : z ? 8'd0 : t[`BYTE23];
		o[`BYTE24] = m[24] ? ~(a[`BYTE24] & b[`BYTE24]) : z ? 8'd0 : t[`BYTE24];
		o[`BYTE25] = m[25] ? ~(a[`BYTE25] & b[`BYTE25]) : z ? 8'd0 : t[`BYTE25];
		o[`BYTE26] = m[26] ? ~(a[`BYTE26] & b[`BYTE26]) : z ? 8'd0 : t[`BYTE26];
		o[`BYTE27] = m[27] ? ~(a[`BYTE27] & b[`BYTE27]) : z ? 8'd0 : t[`BYTE27];
		o[`BYTE28] = m[28] ? ~(a[`BYTE28] & b[`BYTE28]) : z ? 8'd0 : t[`BYTE28];
		o[`BYTE29] = m[29] ? ~(a[`BYTE29] & b[`BYTE29]) : z ? 8'd0 : t[`BYTE29];
		o[`BYTE30] = m[30] ? ~(a[`BYTE30] & b[`BYTE30]) : z ? 8'd0 : t[`BYTE30];
		o[`BYTE31] = m[31] ? ~(a[`BYTE31] & b[`BYTE31]) : z ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
		o[`WYDE0] = m[0] ? ~(a[`WYDE0] & b[`WYDE0]) : z ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = m[1] ? ~(a[`WYDE1] & b[`WYDE1]) : z ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = m[2] ? ~(a[`WYDE2] & b[`WYDE2]) : z ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = m[3] ? ~(a[`WYDE3] & b[`WYDE3]) : z ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = m[4] ? ~(a[`WYDE4] & b[`WYDE4]) : z ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = m[5] ? ~(a[`WYDE5] & b[`WYDE5]) : z ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = m[6] ? ~(a[`WYDE6] & b[`WYDE6]) : z ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = m[7] ? ~(a[`WYDE7] & b[`WYDE7]) : z ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = m[8] ? ~(a[`WYDE8] & b[`WYDE8]) : z ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = m[9] ? ~(a[`WYDE9] & b[`WYDE9]) : z ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = m[10] ? ~(a[`WYDE10] & b[`WYDE10]) : z ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = m[11] ? ~(a[`WYDE11] & b[`WYDE11]) : z ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = m[12] ? ~(a[`WYDE12] & b[`WYDE12]) : z ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = m[13] ? ~(a[`WYDE13] & b[`WYDE13]) : z ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = m[14] ? ~(a[`WYDE14] & b[`WYDE14]) : z ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = m[15] ? ~(a[`WYDE15] & b[`WYDE15]) : z ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = m[0] ? ~(a[`TETRA0] & b[`TETRA0]) : z ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = m[1] ? ~(a[`TETRA1] & b[`TETRA1]) : z ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = m[2] ? ~(a[`TETRA2] & b[`TETRA2]) : z ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = m[3] ? ~(a[`TETRA3] & b[`TETRA3]) : z ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = m[4] ? ~(a[`TETRA4] & b[`TETRA4]) : z ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = m[5] ? ~(a[`TETRA5] & b[`TETRA5]) : z ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = m[6] ? ~(a[`TETRA6] & b[`TETRA6]) : z ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = m[7] ? ~(a[`TETRA7] & b[`TETRA7]) : z ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = m[0] ? ~(a[`OCTA0] & b[`OCTA0]) : z ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = m[1] ? ~(a[`OCTA1] & b[`OCTA1]) : z ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = m[2] ? ~(a[`OCTA2] & b[`OCTA2]) : z ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = m[3] ? ~(a[`OCTA3] & b[`OCTA3]) : z ? 64'd0 : t[`OCTA3];
		end
hexi_para:
	begin
		o[`HEXI0] = m[0] ? ~(a[`HEXI0] & b[`HEXI0]) : z ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = m[1] ? ~(a[`HEXI1] & b[`HEXI1]) : z ? 128'd0 : t[`HEXI1];
		end
	default:
		o = ~(a & b);
	endcase
end
endtask

task tskNor;
input [3:0] fmt;
input [31:0] m;
input z;
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
		o[`BYTE0] = m[0] ? ~(a[`BYTE0] | b[`BYTE0]) : z ? 8'd0 : t[`BYTE0];
		o[`BYTE1] = m[1] ? ~(a[`BYTE1] | b[`BYTE1]) : z ? 8'd0 : t[`BYTE1];
		o[`BYTE2] = m[2] ? ~(a[`BYTE2] | b[`BYTE2]) : z ? 8'd0 : t[`BYTE2];
		o[`BYTE3] = m[3] ? ~(a[`BYTE3] | b[`BYTE3]) : z ? 8'd0 : t[`BYTE3];
		o[`BYTE4] = m[4] ? ~(a[`BYTE4] | b[`BYTE4]) : z ? 8'd0 : t[`BYTE4];
		o[`BYTE5] = m[5] ? ~(a[`BYTE5] | b[`BYTE5]) : z ? 8'd0 : t[`BYTE5];
		o[`BYTE6] = m[6] ? ~(a[`BYTE6] | b[`BYTE6]) : z ? 8'd0 : t[`BYTE6];
		o[`BYTE7] = m[7] ? ~(a[`BYTE7] | b[`BYTE7]) : z ? 8'd0 : t[`BYTE7];
		o[`BYTE8] = m[8] ? ~(a[`BYTE8] | b[`BYTE8]) : z ? 8'd0 : t[`BYTE8];
		o[`BYTE9] = m[9] ? ~(a[`BYTE9] | b[`BYTE9]) : z ? 8'd0 : t[`BYTE9];
		o[`BYTE10] = m[10] ? ~(a[`BYTE10] | b[`BYTE10]) : z ? 8'd0 : t[`BYTE10];
		o[`BYTE11] = m[11] ? ~(a[`BYTE11] | b[`BYTE11]) : z ? 8'd0 : t[`BYTE11];
		o[`BYTE12] = m[12] ? ~(a[`BYTE12] | b[`BYTE12]) : z ? 8'd0 : t[`BYTE12];
		o[`BYTE13] = m[13] ? ~(a[`BYTE13] | b[`BYTE13]) : z ? 8'd0 : t[`BYTE13];
		o[`BYTE14] = m[14] ? ~(a[`BYTE14] | b[`BYTE14]) : z ? 8'd0 : t[`BYTE14];
		o[`BYTE15] = m[15] ? ~(a[`BYTE15] | b[`BYTE15]) : z ? 8'd0 : t[`BYTE15];
		o[`BYTE16] = m[16] ? ~(a[`BYTE16] | b[`BYTE16]) : z ? 8'd0 : t[`BYTE16];
		o[`BYTE17] = m[17] ? ~(a[`BYTE17] | b[`BYTE17]) : z ? 8'd0 : t[`BYTE17];
		o[`BYTE18] = m[18] ? ~(a[`BYTE18] | b[`BYTE18]) : z ? 8'd0 : t[`BYTE18];
		o[`BYTE19] = m[19] ? ~(a[`BYTE19] | b[`BYTE19]) : z ? 8'd0 : t[`BYTE19];
		o[`BYTE20] = m[20] ? ~(a[`BYTE20] | b[`BYTE20]) : z ? 8'd0 : t[`BYTE20];
		o[`BYTE21] = m[21] ? ~(a[`BYTE21] | b[`BYTE21]) : z ? 8'd0 : t[`BYTE21];
		o[`BYTE22] = m[22] ? ~(a[`BYTE22] | b[`BYTE22]) : z ? 8'd0 : t[`BYTE22];
		o[`BYTE23] = m[23] ? ~(a[`BYTE23] | b[`BYTE23]) : z ? 8'd0 : t[`BYTE23];
		o[`BYTE24] = m[24] ? ~(a[`BYTE24] | b[`BYTE24]) : z ? 8'd0 : t[`BYTE24];
		o[`BYTE25] = m[25] ? ~(a[`BYTE25] | b[`BYTE25]) : z ? 8'd0 : t[`BYTE25];
		o[`BYTE26] = m[26] ? ~(a[`BYTE26] | b[`BYTE26]) : z ? 8'd0 : t[`BYTE26];
		o[`BYTE27] = m[27] ? ~(a[`BYTE27] | b[`BYTE27]) : z ? 8'd0 : t[`BYTE27];
		o[`BYTE28] = m[28] ? ~(a[`BYTE28] | b[`BYTE28]) : z ? 8'd0 : t[`BYTE28];
		o[`BYTE29] = m[29] ? ~(a[`BYTE29] | b[`BYTE29]) : z ? 8'd0 : t[`BYTE29];
		o[`BYTE30] = m[30] ? ~(a[`BYTE30] | b[`BYTE30]) : z ? 8'd0 : t[`BYTE30];
		o[`BYTE31] = m[31] ? ~(a[`BYTE31] | b[`BYTE31]) : z ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
		o[`WYDE0] = m[0] ? ~(a[`WYDE0] | b[`WYDE0]) : z ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = m[1] ? ~(a[`WYDE1] | b[`WYDE1]) : z ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = m[2] ? ~(a[`WYDE2] | b[`WYDE2]) : z ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = m[3] ? ~(a[`WYDE3] | b[`WYDE3]) : z ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = m[4] ? ~(a[`WYDE4] | b[`WYDE4]) : z ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = m[5] ? ~(a[`WYDE5] | b[`WYDE5]) : z ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = m[6] ? ~(a[`WYDE6] | b[`WYDE6]) : z ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = m[7] ? ~(a[`WYDE7] | b[`WYDE7]) : z ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = m[8] ? ~(a[`WYDE8] | b[`WYDE8]) : z ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = m[9] ? ~(a[`WYDE9] | b[`WYDE9]) : z ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = m[10] ? ~(a[`WYDE10] | b[`WYDE10]) : z ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = m[11] ? ~(a[`WYDE11] | b[`WYDE11]) : z ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = m[12] ? ~(a[`WYDE12] | b[`WYDE12]) : z ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = m[13] ? ~(a[`WYDE13] | b[`WYDE13]) : z ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = m[14] ? ~(a[`WYDE14] | b[`WYDE14]) : z ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = m[15] ? ~(a[`WYDE15] | b[`WYDE15]) : z ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = m[0] ? ~(a[`TETRA0] | b[`TETRA0]) : z ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = m[1] ? ~(a[`TETRA1] | b[`TETRA1]) : z ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = m[2] ? ~(a[`TETRA2] | b[`TETRA2]) : z ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = m[3] ? ~(a[`TETRA3] | b[`TETRA3]) : z ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = m[4] ? ~(a[`TETRA4] | b[`TETRA4]) : z ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = m[5] ? ~(a[`TETRA5] | b[`TETRA5]) : z ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = m[6] ? ~(a[`TETRA6] | b[`TETRA6]) : z ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = m[7] ? ~(a[`TETRA7] | b[`TETRA7]) : z ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = m[0] ? ~(a[`OCTA0] | b[`OCTA0]) : z ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = m[1] ? ~(a[`OCTA1] | b[`OCTA1]) : z ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = m[2] ? ~(a[`OCTA2] | b[`OCTA2]) : z ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = m[3] ? ~(a[`OCTA3] | b[`OCTA3]) : z ? 64'd0 : t[`OCTA3];
		end
hexi_para:
	begin
		o[`HEXI0] = m[0] ? ~(a[`HEXI0] | b[`HEXI0]) : z ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = m[1] ? ~(a[`HEXI1] | b[`HEXI1]) : z ? 128'd0 : t[`HEXI1];
		end
	default:
		o = ~(a | b);
	endcase
end
endtask

task tskXnor;
input [3:0] fmt;
input [31:0] m;
input z;
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
		o[`BYTE0] = m[0] ? ~(a[`BYTE0] ^ b[`BYTE0]) : z ? 8'd0 : t[`BYTE0];
		o[`BYTE1] = m[1] ? ~(a[`BYTE1] ^ b[`BYTE1]) : z ? 8'd0 : t[`BYTE1];
		o[`BYTE2] = m[2] ? ~(a[`BYTE2] ^ b[`BYTE2]) : z ? 8'd0 : t[`BYTE2];
		o[`BYTE3] = m[3] ? ~(a[`BYTE3] ^ b[`BYTE3]) : z ? 8'd0 : t[`BYTE3];
		o[`BYTE4] = m[4] ? ~(a[`BYTE4] ^ b[`BYTE4]) : z ? 8'd0 : t[`BYTE4];
		o[`BYTE5] = m[5] ? ~(a[`BYTE5] ^ b[`BYTE5]) : z ? 8'd0 : t[`BYTE5];
		o[`BYTE6] = m[6] ? ~(a[`BYTE6] ^ b[`BYTE6]) : z ? 8'd0 : t[`BYTE6];
		o[`BYTE7] = m[7] ? ~(a[`BYTE7] ^ b[`BYTE7]) : z ? 8'd0 : t[`BYTE7];
		o[`BYTE8] = m[8] ? ~(a[`BYTE8] ^ b[`BYTE8]) : z ? 8'd0 : t[`BYTE8];
		o[`BYTE9] = m[9] ? ~(a[`BYTE9] ^ b[`BYTE9]) : z ? 8'd0 : t[`BYTE9];
		o[`BYTE10] = m[10] ? ~(a[`BYTE10] ^ b[`BYTE10]) : z ? 8'd0 : t[`BYTE10];
		o[`BYTE11] = m[11] ? ~(a[`BYTE11] ^ b[`BYTE11]) : z ? 8'd0 : t[`BYTE11];
		o[`BYTE12] = m[12] ? ~(a[`BYTE12] ^ b[`BYTE12]) : z ? 8'd0 : t[`BYTE12];
		o[`BYTE13] = m[13] ? ~(a[`BYTE13] ^ b[`BYTE13]) : z ? 8'd0 : t[`BYTE13];
		o[`BYTE14] = m[14] ? ~(a[`BYTE14] ^ b[`BYTE14]) : z ? 8'd0 : t[`BYTE14];
		o[`BYTE15] = m[15] ? ~(a[`BYTE15] ^ b[`BYTE15]) : z ? 8'd0 : t[`BYTE15];
		o[`BYTE16] = m[16] ? ~(a[`BYTE16] ^ b[`BYTE16]) : z ? 8'd0 : t[`BYTE16];
		o[`BYTE17] = m[17] ? ~(a[`BYTE17] ^ b[`BYTE17]) : z ? 8'd0 : t[`BYTE17];
		o[`BYTE18] = m[18] ? ~(a[`BYTE18] ^ b[`BYTE18]) : z ? 8'd0 : t[`BYTE18];
		o[`BYTE19] = m[19] ? ~(a[`BYTE19] ^ b[`BYTE19]) : z ? 8'd0 : t[`BYTE19];
		o[`BYTE20] = m[20] ? ~(a[`BYTE20] ^ b[`BYTE20]) : z ? 8'd0 : t[`BYTE20];
		o[`BYTE21] = m[21] ? ~(a[`BYTE21] ^ b[`BYTE21]) : z ? 8'd0 : t[`BYTE21];
		o[`BYTE22] = m[22] ? ~(a[`BYTE22] ^ b[`BYTE22]) : z ? 8'd0 : t[`BYTE22];
		o[`BYTE23] = m[23] ? ~(a[`BYTE23] ^ b[`BYTE23]) : z ? 8'd0 : t[`BYTE23];
		o[`BYTE24] = m[24] ? ~(a[`BYTE24] ^ b[`BYTE24]) : z ? 8'd0 : t[`BYTE24];
		o[`BYTE25] = m[25] ? ~(a[`BYTE25] ^ b[`BYTE25]) : z ? 8'd0 : t[`BYTE25];
		o[`BYTE26] = m[26] ? ~(a[`BYTE26] ^ b[`BYTE26]) : z ? 8'd0 : t[`BYTE26];
		o[`BYTE27] = m[27] ? ~(a[`BYTE27] ^ b[`BYTE27]) : z ? 8'd0 : t[`BYTE27];
		o[`BYTE28] = m[28] ? ~(a[`BYTE28] ^ b[`BYTE28]) : z ? 8'd0 : t[`BYTE28];
		o[`BYTE29] = m[29] ? ~(a[`BYTE29] ^ b[`BYTE29]) : z ? 8'd0 : t[`BYTE29];
		o[`BYTE30] = m[30] ? ~(a[`BYTE30] ^ b[`BYTE30]) : z ? 8'd0 : t[`BYTE30];
		o[`BYTE31] = m[31] ? ~(a[`BYTE31] ^ b[`BYTE31]) : z ? 8'd0 : t[`BYTE31];
		end
	wyde_para:
		begin
		o[`WYDE0] = m[0] ? ~(a[`WYDE0] ^ b[`WYDE0]) : z ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = m[1] ? ~(a[`WYDE1] ^ b[`WYDE1]) : z ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = m[2] ? ~(a[`WYDE2] ^ b[`WYDE2]) : z ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = m[3] ? ~(a[`WYDE3] ^ b[`WYDE3]) : z ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = m[4] ? ~(a[`WYDE4] ^ b[`WYDE4]) : z ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = m[5] ? ~(a[`WYDE5] ^ b[`WYDE5]) : z ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = m[6] ? ~(a[`WYDE6] ^ b[`WYDE6]) : z ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = m[7] ? ~(a[`WYDE7] ^ b[`WYDE7]) : z ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = m[8] ? ~(a[`WYDE8] ^ b[`WYDE8]) : z ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = m[9] ? ~(a[`WYDE9] ^ b[`WYDE9]) : z ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = m[10] ? ~(a[`WYDE10] ^ b[`WYDE10]) : z ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = m[11] ? ~(a[`WYDE11] ^ b[`WYDE11]) : z ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = m[12] ? ~(a[`WYDE12] ^ b[`WYDE12]) : z ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = m[13] ? ~(a[`WYDE13] ^ b[`WYDE13]) : z ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = m[14] ? ~(a[`WYDE14] ^ b[`WYDE14]) : z ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = m[15] ? ~(a[`WYDE15] ^ b[`WYDE15]) : z ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = m[0] ? ~(a[`TETRA0] ^ b[`TETRA0]) : z ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = m[1] ? ~(a[`TETRA1] ^ b[`TETRA1]) : z ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = m[2] ? ~(a[`TETRA2] ^ b[`TETRA2]) : z ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = m[3] ? ~(a[`TETRA3] ^ b[`TETRA3]) : z ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = m[4] ? ~(a[`TETRA4] ^ b[`TETRA4]) : z ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = m[5] ? ~(a[`TETRA5] ^ b[`TETRA5]) : z ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = m[6] ? ~(a[`TETRA6] ^ b[`TETRA6]) : z ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = m[7] ? ~(a[`TETRA7] ^ b[`TETRA7]) : z ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = m[0] ? ~(a[`OCTA0] ^ b[`OCTA0]) : z ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = m[1] ? ~(a[`OCTA1] ^ b[`OCTA1]) : z ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = m[2] ? ~(a[`OCTA2] ^ b[`OCTA2]) : z ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = m[3] ? ~(a[`OCTA3] ^ b[`OCTA3]) : z ? 64'd0 : t[`OCTA3];
		end
hexi_para:
	begin
		o[`HEXI0] = m[0] ? ~(a[`HEXI0] ^ b[`HEXI0]) : z ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = m[1] ? ~(a[`HEXI1] ^ b[`HEXI1]) : z ? 128'd0 : t[`HEXI1];
		end
	default:
		o = ~(a ^ b);
	endcase
end
endtask

task tskMin;
input [3:0] fmt;
input [31:0] m;
input z;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	if (BIG)
	case(fmt)
	3'd0:	o = BIG ? ($signed(a[7:0]) < $signed(b[7:0]) ? {{56{a[7]}},a[7:0]} : {{56{b[7]}},b[7:0]}) : 64'hCCCCCCCCCCCCCCCC;			
	3'd1:	o = BIG ? ($signed(a[15:0]) < $signed(b[15:0]) ? {{48{a[15]}},a[15:0]} : {{48{b[15]}},b[15:0]}) : 64'hCCCCCCCCCCCCCCCC;
	3'd2:	o = BIG ? ($signed(a[31:0]) < $signed(b[31:0]) ? {{32{a[31]}},a[31:0]} : {{32{b[31]}},b[31:0]}) : 64'hCCCCCCCCCCCCCCCC;
	3'd3:	o = BIG ? ($signed(a) < $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
	byte_para:
		begin
		o[7:0] = BIG ? ($signed(a[7:0]) < $signed(b[7:0]) ? a[7:0] : b[7:0]) : 64'hCCCCCCCCCCCCCCCC;
		o[15:8] = BIG ? ($signed(a[15:8]) < $signed(b[15:8]) ? a[15:8] : b[15:8]) : 64'hCCCCCCCCCCCCCCCC;
		o[23:16] = BIG ? ($signed(a[23:16]) < $signed(b[23:16]) ? a[23:16] : b[23:16]) : 64'hCCCCCCCCCCCCCCCC;
		o[31:24] = BIG ? ($signed(a[31:24]) < $signed(b[31:24]) ? a[31:24] : b[31:24]) : 64'hCCCCCCCCCCCCCCCC;
		o[39:32] = BIG ? ($signed(a[39:32]) < $signed(b[39:32]) ? a[39:32] : b[39:32]) : 64'hCCCCCCCCCCCCCCCC;
		o[47:40] = BIG ? ($signed(a[47:40]) < $signed(b[47:40]) ? a[47:40] : b[47:40]) : 64'hCCCCCCCCCCCCCCCC;
		o[55:48] = BIG ? ($signed(a[55:48]) < $signed(b[55:48]) ? a[55:48] : b[55:48]) : 64'hCCCCCCCCCCCCCCCC;
		o[63:56] = BIG ? ($signed(a[63:56]) < $signed(b[63:56]) ? a[63:56] : b[63:56]) : 64'hCCCCCCCCCCCCCCCC;
		end
	wyde_para:
		begin
		o[`WYDE0] = m[0] ? ($signed(a[`WYDE0]) < $signed(b[`WYDE0]) ? a[`WYDE0] : b[`WYDE0]) : z ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = m[1] ? ($signed(a[`WYDE1]) < $signed(b[`WYDE1]) ? a[`WYDE1] : b[`WYDE1]) : z ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = m[2] ? ($signed(a[`WYDE2]) < $signed(b[`WYDE2]) ? a[`WYDE2] : b[`WYDE2]) : z ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = m[3] ? ($signed(a[`WYDE3]) < $signed(b[`WYDE3]) ? a[`WYDE3] : b[`WYDE3]) : z ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = m[4] ? ($signed(a[`WYDE4]) < $signed(b[`WYDE4]) ? a[`WYDE4] : b[`WYDE4]) : z ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = m[5] ? ($signed(a[`WYDE5]) < $signed(b[`WYDE5]) ? a[`WYDE5] : b[`WYDE5]) : z ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = m[6] ? ($signed(a[`WYDE6]) < $signed(b[`WYDE6]) ? a[`WYDE6] : b[`WYDE6]) : z ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = m[7] ? ($signed(a[`WYDE7]) < $signed(b[`WYDE7]) ? a[`WYDE7] : b[`WYDE7]) : z ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = m[0] ? ($signed(a[`WYDE8]) < $signed(b[`WYDE8]) ? a[`WYDE8] : b[`WYDE8]) : z ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = m[1] ? ($signed(a[`WYDE9]) < $signed(b[`WYDE9]) ? a[`WYDE9] : b[`WYDE9]) : z ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = m[2] ? ($signed(a[`WYDE10]) < $signed(b[`WYDE10]) ? a[`WYDE10] : b[`WYDE10]) : z ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = m[3] ? ($signed(a[`WYDE11]) < $signed(b[`WYDE11]) ? a[`WYDE11] : b[`WYDE11]) : z ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = m[4] ? ($signed(a[`WYDE12]) < $signed(b[`WYDE12]) ? a[`WYDE12] : b[`WYDE12]) : z ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = m[5] ? ($signed(a[`WYDE13]) < $signed(b[`WYDE13]) ? a[`WYDE13] : b[`WYDE13]) : z ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = m[6] ? ($signed(a[`WYDE14]) < $signed(b[`WYDE14]) ? a[`WYDE14] : b[`WYDE14]) : z ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = m[7] ? ($signed(a[`WYDE15]) < $signed(b[`WYDE15]) ? a[`WYDE15] : b[`WYDE15]) : z ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = m[0] ? ($signed(a[`TETRA0]) < $signed(b[`TETRA0]) ? a[`TETRA0] : b[`TETRA0]) : z ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = m[1] ? ($signed(a[`TETRA1]) < $signed(b[`TETRA1]) ? a[`TETRA1] : b[`TETRA1]) : z ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = m[2] ? ($signed(a[`TETRA2]) < $signed(b[`TETRA2]) ? a[`TETRA2] : b[`TETRA2]) : z ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = m[3] ? ($signed(a[`TETRA3]) < $signed(b[`TETRA3]) ? a[`TETRA3] : b[`TETRA3]) : z ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = m[4] ? ($signed(a[`TETRA4]) < $signed(b[`TETRA4]) ? a[`TETRA4] : b[`TETRA4]) : z ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = m[5] ? ($signed(a[`TETRA5]) < $signed(b[`TETRA5]) ? a[`TETRA5] : b[`TETRA5]) : z ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = m[6] ? ($signed(a[`TETRA6]) < $signed(b[`TETRA6]) ? a[`TETRA6] : b[`TETRA6]) : z ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = m[7] ? ($signed(a[`TETRA7]) < $signed(b[`TETRA7]) ? a[`TETRA7] : b[`TETRA7]) : z ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = m[0] ? ($signed(a[`OCTA0]) < $signed(b[`OCTA0]) ? a[`OCTA0] : b[`OCTA0]) : z ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = m[1] ? ($signed(a[`OCTA1]) < $signed(b[`OCTA1]) ? a[`OCTA1] : b[`OCTA1]) : z ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = m[2] ? ($signed(a[`OCTA2]) < $signed(b[`OCTA2]) ? a[`OCTA2] : b[`OCTA2]) : z ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = m[3] ? ($signed(a[`OCTA3]) < $signed(b[`OCTA3]) ? a[`OCTA3] : b[`OCTA3]) : z ? 64'd0 : t[`OCTA3];
		end
//	hexi_para:
	default:
		begin
		o[`HEXI0] = m[0] ? ($signed(a[`HEXI0]) < $signed(b[`HEXI0]) ? a[`HEXI0] : b[`HEXI0]) : z ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = m[1] ? ($signed(a[`HEXI1]) < $signed(b[`HEXI1]) ? a[`HEXI1] : b[`HEXI1]) : z ? 128'd0 : t[`HEXI1];
		end
	endcase
	else
		o = {64{4'hC}};
end
endtask

task tskMax;
input [3:0] fmt;
input [31:0] m;
input z;
input [DBW:0] a;
input [DBW:0] b;
input [DBW:0] t;
output [DBW:0] o;
begin
	if (BIG)
	case(fmt)
	3'd0:	o = BIG ? ($signed(a[7:0]) > $signed(b[7:0]) ? {{56{a[7]}},a[7:0]} : {{56{b[7]}},b[7:0]}) : 64'hCCCCCCCCCCCCCCCC;			
	3'd1:	o = BIG ? ($signed(a[15:0]) > $signed(b[15:0]) ? {{48{a[15]}},a[15:0]} : {{48{b[15]}},b[15:0]}) : 64'hCCCCCCCCCCCCCCCC;
	3'd2:	o = BIG ? ($signed(a[31:0]) > $signed(b[31:0]) ? {{32{a[31]}},a[31:0]} : {{32{b[31]}},b[31:0]}) : 64'hCCCCCCCCCCCCCCCC;
	3'd3:	o = BIG ? ($signed(a) > $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
	byte_para:
		begin
		o[7:0] = BIG ? ($signed(a[7:0]) > $signed(b[7:0]) ? a[7:0] : b[7:0]) : 64'hCCCCCCCCCCCCCCCC;
		o[15:8] = BIG ? ($signed(a[15:8]) > $signed(b[15:8]) ? a[15:8] : b[15:8]) : 64'hCCCCCCCCCCCCCCCC;
		o[23:16] = BIG ? ($signed(a[23:16]) > $signed(b[23:16]) ? a[23:16] : b[23:16]) : 64'hCCCCCCCCCCCCCCCC;
		o[31:24] = BIG ? ($signed(a[31:24]) > $signed(b[31:24]) ? a[31:24] : b[31:24]) : 64'hCCCCCCCCCCCCCCCC;
		o[39:32] = BIG ? ($signed(a[39:32]) > $signed(b[39:32]) ? a[39:32] : b[39:32]) : 64'hCCCCCCCCCCCCCCCC;
		o[47:40] = BIG ? ($signed(a[47:40]) > $signed(b[47:40]) ? a[47:40] : b[47:40]) : 64'hCCCCCCCCCCCCCCCC;
		o[55:48] = BIG ? ($signed(a[55:48]) > $signed(b[55:48]) ? a[55:48] : b[55:48]) : 64'hCCCCCCCCCCCCCCCC;
		o[63:56] = BIG ? ($signed(a[63:56]) > $signed(b[63:56]) ? a[63:56] : b[63:56]) : 64'hCCCCCCCCCCCCCCCC;
		end
	wyde_para:
		begin
		o[`WYDE0] = m[0] ? ($signed(a[`WYDE0]) > $signed(b[`WYDE0]) ? a[`WYDE0] : b[`WYDE0]) : z ? 16'd0 : t[`WYDE0];
		o[`WYDE1] = m[1] ? ($signed(a[`WYDE1]) > $signed(b[`WYDE1]) ? a[`WYDE1] : b[`WYDE1]) : z ? 16'd0 : t[`WYDE1];
		o[`WYDE2] = m[2] ? ($signed(a[`WYDE2]) > $signed(b[`WYDE2]) ? a[`WYDE2] : b[`WYDE2]) : z ? 16'd0 : t[`WYDE2];
		o[`WYDE3] = m[3] ? ($signed(a[`WYDE3]) > $signed(b[`WYDE3]) ? a[`WYDE3] : b[`WYDE3]) : z ? 16'd0 : t[`WYDE3];
		o[`WYDE4] = m[4] ? ($signed(a[`WYDE4]) > $signed(b[`WYDE4]) ? a[`WYDE4] : b[`WYDE4]) : z ? 16'd0 : t[`WYDE4];
		o[`WYDE5] = m[5] ? ($signed(a[`WYDE5]) > $signed(b[`WYDE5]) ? a[`WYDE5] : b[`WYDE5]) : z ? 16'd0 : t[`WYDE5];
		o[`WYDE6] = m[6] ? ($signed(a[`WYDE6]) > $signed(b[`WYDE6]) ? a[`WYDE6] : b[`WYDE6]) : z ? 16'd0 : t[`WYDE6];
		o[`WYDE7] = m[7] ? ($signed(a[`WYDE7]) > $signed(b[`WYDE7]) ? a[`WYDE7] : b[`WYDE7]) : z ? 16'd0 : t[`WYDE7];
		o[`WYDE8] = m[0] ? ($signed(a[`WYDE8]) > $signed(b[`WYDE8]) ? a[`WYDE8] : b[`WYDE8]) : z ? 16'd0 : t[`WYDE8];
		o[`WYDE9] = m[1] ? ($signed(a[`WYDE9]) > $signed(b[`WYDE9]) ? a[`WYDE9] : b[`WYDE9]) : z ? 16'd0 : t[`WYDE9];
		o[`WYDE10] = m[2] ? ($signed(a[`WYDE10]) > $signed(b[`WYDE10]) ? a[`WYDE10] : b[`WYDE10]) : z ? 16'd0 : t[`WYDE10];
		o[`WYDE11] = m[3] ? ($signed(a[`WYDE11]) > $signed(b[`WYDE11]) ? a[`WYDE11] : b[`WYDE11]) : z ? 16'd0 : t[`WYDE11];
		o[`WYDE12] = m[4] ? ($signed(a[`WYDE12]) > $signed(b[`WYDE12]) ? a[`WYDE12] : b[`WYDE12]) : z ? 16'd0 : t[`WYDE12];
		o[`WYDE13] = m[5] ? ($signed(a[`WYDE13]) > $signed(b[`WYDE13]) ? a[`WYDE13] : b[`WYDE13]) : z ? 16'd0 : t[`WYDE13];
		o[`WYDE14] = m[6] ? ($signed(a[`WYDE14]) > $signed(b[`WYDE14]) ? a[`WYDE14] : b[`WYDE14]) : z ? 16'd0 : t[`WYDE14];
		o[`WYDE15] = m[7] ? ($signed(a[`WYDE15]) > $signed(b[`WYDE15]) ? a[`WYDE15] : b[`WYDE15]) : z ? 16'd0 : t[`WYDE15];
		end
	tetra_para:
		begin
		o[`TETRA0] = m[0] ? ($signed(a[`TETRA0]) > $signed(b[`TETRA0]) ? a[`TETRA0] : b[`TETRA0]) : z ? 32'd0 : t[`TETRA0];
		o[`TETRA1] = m[1] ? ($signed(a[`TETRA1]) > $signed(b[`TETRA1]) ? a[`TETRA1] : b[`TETRA1]) : z ? 32'd0 : t[`TETRA1];
		o[`TETRA2] = m[2] ? ($signed(a[`TETRA2]) > $signed(b[`TETRA2]) ? a[`TETRA2] : b[`TETRA2]) : z ? 32'd0 : t[`TETRA2];
		o[`TETRA3] = m[3] ? ($signed(a[`TETRA3]) > $signed(b[`TETRA3]) ? a[`TETRA3] : b[`TETRA3]) : z ? 32'd0 : t[`TETRA3];
		o[`TETRA4] = m[4] ? ($signed(a[`TETRA4]) > $signed(b[`TETRA4]) ? a[`TETRA4] : b[`TETRA4]) : z ? 32'd0 : t[`TETRA4];
		o[`TETRA5] = m[5] ? ($signed(a[`TETRA5]) > $signed(b[`TETRA5]) ? a[`TETRA5] : b[`TETRA5]) : z ? 32'd0 : t[`TETRA5];
		o[`TETRA6] = m[6] ? ($signed(a[`TETRA6]) > $signed(b[`TETRA6]) ? a[`TETRA6] : b[`TETRA6]) : z ? 32'd0 : t[`TETRA6];
		o[`TETRA7] = m[7] ? ($signed(a[`TETRA7]) > $signed(b[`TETRA7]) ? a[`TETRA7] : b[`TETRA7]) : z ? 32'd0 : t[`TETRA7];
		end
	octa_para: 
		begin
		o[`OCTA0] = m[0] ? ($signed(a[`OCTA0]) > $signed(b[`OCTA0]) ? a[`OCTA0] : b[`OCTA0]) : z ? 64'd0 : t[`OCTA0];
		o[`OCTA1] = m[1] ? ($signed(a[`OCTA1]) > $signed(b[`OCTA1]) ? a[`OCTA1] : b[`OCTA1]) : z ? 64'd0 : t[`OCTA1];
		o[`OCTA2] = m[2] ? ($signed(a[`OCTA2]) > $signed(b[`OCTA2]) ? a[`OCTA2] : b[`OCTA2]) : z ? 64'd0 : t[`OCTA2];
		o[`OCTA3] = m[3] ? ($signed(a[`OCTA3]) > $signed(b[`OCTA3]) ? a[`OCTA3] : b[`OCTA3]) : z ? 64'd0 : t[`OCTA3];
		end
//	hexi_para:
	default:
		begin
		o[`HEXI0] = m[0] ? ($signed(a[`HEXI0]) > $signed(b[`HEXI0]) ? a[`HEXI0] : b[`HEXI0]) : z ? 128'd0 : t[`HEXI0];
		o[`HEXI1] = m[1] ? ($signed(a[`HEXI1]) > $signed(b[`HEXI1]) ? a[`HEXI1] : b[`HEXI1]) : z ? 128'd0 : t[`HEXI1];
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
//S	hexi_para:
	default:		
								o = {
											$signed(a[`HEXI1]) == $signed(b[`HEXI1]),
											$signed(a[`HEXI0]) == $signed(b[`HEXI0])
										};
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
  3'd0:   o = $signed(a[7:0]) < $signed(b[7:0]);
  3'd1:   o = $signed(a[15:0]) < $signed(b[15:0]);
  3'd2:   o = $signed(a[31:0]) < $signed(b[31:0]);
  3'd3:   o = $signed(a) < $signed(b);
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
  3'd0:   o = $signed(a[7:0]) <= $signed(b[7:0]);
  3'd1:   o = $signed(a[15:0]) <= $signed(b[15:0]);
  3'd2:   o = $signed(a[31:0]) <= $signed(b[31:0]);
  3'd3:   o = $signed(a) <= $signed(b);
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
  3'd0:   o = a[7:0] < b[7:0];
  3'd1:   o = a[15:0] < b[15:0];
  3'd2:   o = a[31:0] < b[31:0];
  3'd3:   o = a < b;
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
  3'd0:   o = a[7:0] <= b[7:0];
  3'd1:   o = a[15:0] <= b[15:0];
  3'd2:   o = a[31:0] <= b[31:0];
  3'd3:   o = a <= b;
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
//	hexi_para:		
	default:
								o = {
											a[`HEXI1] <= b[`HEXI1],
											a[`HEXI0] <= b[`HEXI0]
										};
  endcase
end
endtask

endmodule
