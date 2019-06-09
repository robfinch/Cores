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
`include "rtfItanium-defines.sv"
`include "rtfItanium-config.sv"

module alu(rst, clk, ld, abort, instr, sz, store, a, b, c, t, pc, Ra, tgt, tgt2,
    csr, o, ob, done, idle, excen, exc, thrd, ptrmask, state, mem, shift,
    ol, dl
`ifdef SUPPORT_BBMS 
    , pb, cbl, cbu, ro, dbl, dbu, sbl, sbu, en
`endif
    );
parameter DBW = 80;
parameter ABW = 80;
parameter BIG = 1'b1;
parameter SUP_VECTOR = 1;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter PTR = 20'hFFF01;
parameter BASE_SHIFT = 13'd0;
input rst;
input clk;
input ld;
input abort;
input [39:0] instr;
input [2:0] sz;
input store;
input [DBW-1:0] a;
input [DBW-1:0] b;
input [DBW-1:0] c;
input [DBW-1:0] t;			// target register value
input [31:0] pc;
input [5:0] Ra;
input [5:0] tgt;
input [5:0] tgt2;
input [79:0] csr;
output reg [79:0] o;
output reg [79:0] ob;
output reg done;
output reg idle;
input [4:0] excen;
output reg [7:0] exc;
input thrd;
input [79:0] ptrmask;
input [1:0] state;
input mem;
input shift;
input [1:0] ol;
input [1:0] dl;
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

parameter byt = 3'd0;
parameter schar = 3'd1;
parameter half = 3'd2;
parameter word = 3'd3;
parameter byt_para = 3'd4;
parameter char_para = 3'd5;
parameter half_para = 3'd6;
parameter word_para = 3'd7;

integer n;

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
wire [DBW-1:0] imm = {{58{instr[39]}},instr[39:33],instr[30:16]};
wire [DBW-1:0] divq, rem;
wire divByZero;
wire [15:0] prod80, prod81, prod82, prod83, prod84, prod85, prod86, prod87;
wire [31:0] prod160, prod161, prod162, prod163;
wire [63:0] prod320, prod321;
wire [DBW*2-1:0] prod;
wire mult_done8, mult_idle8, div_done8, div_idle8;
wire mult_done80, mult_idle80, div_done80, div_idle80;
wire mult_done81, mult_idle81, div_done81, div_idle81;
wire mult_done82, mult_idle82, div_done82, div_idle82;
wire mult_done83, mult_idle83, div_done83, div_idle83;
wire mult_done84, mult_idle84, div_done84, div_idle84;
wire mult_done85, mult_idle85, div_done85, div_idle85;
wire mult_done86, mult_idle86, div_done86, div_idle86;
wire mult_done87, mult_idle87, div_done87, div_idle87;
wire mult_done16, mult_idle16, div_done16, div_idle16;
wire mult_done160, mult_idle160, div_done160, div_idle160;
wire mult_done161, mult_idle161, div_done161, div_idle161;
wire mult_done162, mult_idle162, div_done162, div_idle162;
wire mult_done163, mult_idle163, div_done163, div_idle163;
wire mult_done320, mult_idle320, div_done320, div_idle320;
wire mult_done321, mult_idle321, div_done321, div_idle321;
wire mult_done, mult_idle, div_done, div_idle;
wire aslo;
wire [6:0] clzo,cloo,cpopo;
wire [DBW-1:0] shftho;
reg [DBW-1:0] shift9;

function IsMul;
input [39:0] isn;
casez({isn[32:31],isn[`OPCODE4]})
`R3:
  case({isn[`FUNCT5],isn[6]})
  `MULU,`MUL: IsMul = TRUE;
  `MULUH,`MULH: IsMul = TRUE;
  `FXMUL: IsMul = TRUE;
  default:    IsMul = FALSE;
  endcase
`MULUI,`MULI:  IsMul = TRUE;
default:    IsMul = FALSE;
endcase
endfunction

function IsDivmod;
input [39:0] isn;
casez({isn[32:31],isn[`OPCODE4]})
`R3:
  case({isn[`FUNCT5],isn[6]})
  `DIVU,`DIV: IsDivmod = TRUE;
  `MODU,`MOD: IsDivmod = TRUE;
  default:    IsDivmod = FALSE;
  endcase
`DIVUI,`DIVI:  IsDivmod = TRUE;
default:    IsDivmod = FALSE;
endcase
endfunction

function IsSgn;
input [39:0] isn;
casez({isn[32:31],isn[`OPCODE4]})
`R3:
  case({isn[`FUNCT5],isn[6]})
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
wire [DBW-1:0] shftco;
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

multiplier #(DBW) umult1
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr)&& (sz==word || sz==word_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a),
	.b(b),
	.o(prod),
	.done(mult_done),
	.idle(mult_idle)
);

multiplier #(32) umulth0
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==half || sz==half_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[31:0]),
	.b(b[31:0]),
	.o(prod320),
	.done(mult_done320),
	.idle(mult_idle320)
);

multiplier #(16) umultc0
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==schar || sz==char_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[15:0]),
	.b(b[15:0]),
	.o(prod160),
	.done(mult_done160),
	.idle(mult_idle160)
);

multiplier #(8) umultb0
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==byt || sz==byt_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[7:0]),
	.b(b[7:0]),
	.o(prod80),
	.done(mult_done80),
	.idle(mult_idle80)
);

`ifdef SIMD
multiplier #(32) umulth1
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==half || sz==half_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[63:32]),
	.b(b[63:32]),
	.o(prod321),
	.done(mult_done321),
	.idle(mult_idle321)
);

multiplier #(16) umultc1
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==char_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[31:16]),
	.b(b[31:16]),
	.o(prod161),
	.done(mult_done161),
	.idle(mult_idle161)
);

multiplier #(16) umultc2
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==char_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[47:32]),
	.b(b[47:32]),
	.o(prod162),
	.done(mult_done162),
	.idle(mult_idle162)
);

multiplier #(16) umultc3
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==char_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[63:48]),
	.b(b[63:48]),
	.o(prod163),
	.done(mult_done163),
	.idle(mult_idle163)
);

multiplier #(8) umultb1
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==byt_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[15:8]),
	.b(b[15:8]),
	.o(prod81),
	.done(mult_done81),
	.idle(mult_idle81)
);

multiplier #(8) umultb2
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==byt_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[23:16]),
	.b(b[23:16]),
	.o(prod82),
	.done(mult_done82),
	.idle(mult_idle82)
);

multiplier #(8) umultb3
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==byt_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[31:24]),
	.b(b[31:24]),
	.o(prod83),
	.done(mult_done83),
	.idle(mult_idle83)
);

multiplier #(8) umultb4
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==byt_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[39:32]),
	.b(b[39:32]),
	.o(prod84),
	.done(mult_done84),
	.idle(mult_idle84)
);

multiplier #(8) umultb5
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==byt_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[47:40]),
	.b(b[47:40]),
	.o(prod85),
	.done(mult_done85),
	.idle(mult_idle85)
);

multiplier #(8) umultb6
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==byt_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[55:48]),
	.b(b[55:48]),
	.o(prod86),
	.done(mult_done86),
	.idle(mult_idle86)
);

multiplier #(8) umultb7
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==byt_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[63:56]),
	.b(b[63:56]),
	.o(prod87),
	.done(mult_done87),
	.idle(mult_idle87)
);
`endif

divider #(DBW) udiv1
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsDivmod(instr) && (sz==word || sz==word_para)),
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
case ({instr[`FUNCT5],instr[6]})
`SHL,`ASL,`SHR,`ASR,`ROL,`ROR:
	bshift <= b[6:0];
default:
	bshift <= {instr[21:16]};
endcase


shift ushft1
(
    .instr(instr),
    .a(a),
    .b(bshift),
    .res(shfto),
    .ov(aslo)
);

shifth ushfthL
(
    .instr(instr),
    .a(a[31:0]),
    .b(bshift),
    .res(shftho[31:0]),
    .ov()
);

shifth ushfthH
(
    .instr(instr),
    .a(a[63:32]),
    .b(b[63:32]),
    .res(shftho[63:32]),
    .ov()
);

shiftc ushftc0
(
    .instr(instr),
    .a(a[15:0]),
    .b(bshift),
    .res(shftco[15:0]),
    .ov()
);

shiftc ushftc1
(
    .instr(instr),
    .a(a[31:16]),
    .b(b[31:16]),
    .res(shftco[31:16]),
    .ov()
);

shiftc ushftc2
(
    .instr(instr),
    .a(a[47:32]),
    .b(b[47:32]),
    .res(shftco[47:32]),
    .ov()
);

shiftc ushftc3
(
    .instr(instr),
    .a(a[63:48]),
    .b(b[63:48]),
    .res(shftco[63:48]),
    .ov()
);

shiftb ushftb0
(
    .instr(instr),
    .a(a[7:0]),
    .b(bshift),
    .res(shftob[7:0]),
    .ov()
);

shiftb ushftb1
(
    .instr(instr),
    .a(a[15:8]),
    .b(b[15:8]),
    .res(shftob[15:8]),
    .ov()
);

shiftb ushftb2
(
    .instr(instr),
    .a(a[23:16]),
    .b(b[23:16]),
    .res(shftob[23:16]),
    .ov()
);

shiftb ushftb3
(
    .instr(instr),
    .a(a[31:24]),
    .b(b[31:24]),
    .res(shftob[31:24]),
    .ov()
);

shiftb ushftb4
(
    .instr(instr),
    .a(a[39:32]),
    .b(b[39:32]),
    .res(shftob[39:32]),
    .ov()
);

shiftb ushftb5
(
    .instr(instr),
    .a(a[47:40]),
    .b(b[47:40]),
    .res(shftob[47:40]),
    .ov()
);

shiftb ushftb6
(
    .instr(instr),
    .a(a[55:48]),
    .b(b[55:48]),
    .res(shftob[55:48]),
    .ov()
);

shiftb ushftb7
(
    .instr(instr),
    .a(a[63:56]),
    .b(b[63:56]),
    .res(shftob[63:56]),
    .ov()
);

cntlz80 uclz1
(
	.i(sz==2'd0 ? {72'hFFFFFFFFFFFFFFFFFF,a[7:0]} :
	   sz==2'd1 ? {64'hFFFFFFFFFFFFFFFF,a[15:0]} :
	   sz==2'd2 ? {48'hFFFFFFFFFFFF,a[31:0]} : a),
	.o(clzo)
);

cntlo80 uclo1
(
	.i(sz==2'd0 ? a[7:0] : sz==2'd1 ? a[15:0] : sz==2'd2 ? a[31:0] : a),
	.o(cloo)
);

cntpop80 ucpop1
(
	.i(sz==2'd0 ? a[7:0] : sz==2'd1 ? a[15:0] : sz==2'd2 ? a[31:0] : a),
	.o(cpopo)
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

genvar g;

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
casez({instr[32:31],instr[`OPCODE4]})
`R1:
		case(instr[`FUNCT5])
		`CNTLZ:     o = BIG ? {57'd0,clzo} : 64'hCCCCCCCCCCCCCCCC;
		`CNTLO:     o = BIG ? {57'd0,cloo} : 64'hCCCCCCCCCCCCCCCC;
		`CNTPOP:    o = BIG ? {57'd0,cpopo} : 64'hCCCCCCCCCCCCCCCC;
		`ABS:       case(sz[1:0])
								2'd0:   o = BIG ? (a[7] ? -a[7:0] : a[7:0]) : 64'hCCCCCCCCCCCCCCCC;
								2'd1:   o = BIG ? (a[15] ? -a[15:0] : a[15:0]) : 64'hCCCCCCCCCCCCCCCC;
								2'd2:   o = BIG ? (a[31] ? -a[31:0] : a[31:0]) : 64'hCCCCCCCCCCCCCCCC;
								2'd3:   o = BIG ? (a[63] ? -a : a) : 64'hCCCCCCCCCCCCCCCC;
								endcase
		`NOT:   case(sz[1:0])
						2'd0:   o = {~|a[63:56],~|a[55:48],~|a[47:40],~|a[39:32],~|a[31:24],~|a[23:16],~|a[15:8],~|a[7:0]};
						2'd1:   o = {~|a[63:48],~|a[47:32],~|a[31:16],~|a[15:0]};
						2'd2:   o = {~|a[63:32],~|a[31:0]};
						2'd3:   o = ~|a[63:0];
						endcase
		`NEG:
						case(sz[1:0])
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
//	        `REDOR: case(sz[1:0])
//	                2'd0:   o = redor8;
//	                2'd1:   o = redor16;
//	                2'd2:   o = redor32;
//	                2'd3:   o = redor64;
//	                endcase
		`ZXO:		o = {16'd0,a[63:0]};
		`ZXP:		o = {40'd0,a[39:0]};
		`ZXT:		o = {48'd0,a[31:0]};
		`ZXC:		o = {64'd0,a[15:0]};
		`ZXB:		o = {72'd0,a[7:0]};
		`SXO:		o = {{16{a[63]}},a[63:0]};
		`SXP:		o = {{40{a[39]}},a[39:0]};
		`SXT:		o = {{48{a[31]}},a[31:0]};
		`SXC:		o = {{64{a[15]}},a[15:0]};
		`SXB:		o = {{72{a[7]}},a[7:0]};
//	        5'h1C:		o[63:0] = tmem[a[9:0]];
		default:    o = 64'hDEADDEADDEADDEAD;
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
	    `BMM:		o = BIG ? bmmo : 64'hCCCCCCCCCCCCCCCC;
	    `SHLI,`ASLI,`SHRI,`ASRI,`ROLI,`RORI,
	    `SHL,`ASL,`SHR,`ASR,`ROL,`ROR:
	    		case(instr[`FUNCT2])
	    		2'd0:	o = shfto;
	    		2'd1:	o = shfto + c;
	    		2'd2:	o = shfto & c;
	    		2'd3:	o = shfto;
	    		endcase
	    `ADD:
`ifdef SIMD	    		
	    	case(sz)
	    		3'd0:
	    			begin
	    				o[7:0] = a[7:0] + b[7:0];
	    				o[63:8] = {56{o[7]}};
	    			end
	    		3'd1:
	    			begin
	    				o[15:0] = a[15:0] + b[15:0];
	    				o[63:16] = {48{o[15]}};
	    			end
	    		3'd2:
	    			begin
	    				o[31:0] = a[31:0] + b[31:0];
	    				o[63:32] = {32{o[31]}};
	    			end
	    		3'd4:
	    			begin
	    				o[7:0] = a[7:0] + b[7:0];
	    				o[15:8] = a[15:8] + b[15:8];
	    				o[23:16] = a[23:16] + b[23:16];
	    				o[31:24] = a[31:24] + b[31:24];
	    				o[39:32] = a[39:32] + b[39:32];
	    				o[47:40] = a[47:40] + b[47:40];
	    				o[55:48] = a[55:48] + b[55:48];
	    				o[63:56] = a[63:56] + b[63:56];
	    			end
	    		3'd5:
	    			begin
	    				o[15:0] = a[15:0] + b[15:0];
	    				o[31:16] = a[31:16] + b[31:16];
	    				o[47:32] = a[47:32] + b[47:32];
	    				o[63:48] = a[63:48] + b[63:48];
	    			end
	    		3'd6:
	    			begin
	    				o[31:0] = a[31:0] + b[31:0];
	    				o[63:32] = a[63:32] + b[63:32];
	    			end
	            default:
	            	begin
	            		o = a + b;
	            	end
	            endcase
`else
			o = a + b;	            
`endif
	    `SUB:   
`ifdef SIMD	    
	    	case(sz)
	    		3'd0:
	    			begin
	    				o[7:0] = a[7:0] - b[7:0];
	    				o[63:8] = {56{o[7]}};
	    			end
	    		3'd1:
	    			begin
	    				o[15:0] = a[15:0] - b[15:0];
	    				o[63:16] = {48{o[15]}};
	    			end
	    		3'd2:
	    			begin
	    				o[31:0] = a[31:0] - b[31:0];
	    				o[63:32] = {31{o[31]}};
	    			end
	    		3'd4:
	    			begin
	    				o[7:0] = a[7:0] - b[7:0];
	    				o[15:8] = a[15:8] - b[15:8];
	    				o[23:16] = a[23:16] - b[23:16];
	    				o[31:24] = a[31:24] - b[31:24];
	    				o[39:32] = a[39:32] - b[39:32];
	    				o[47:40] = a[47:40] - b[47:40];
	    				o[55:48] = a[55:48] - b[55:48];
	    				o[63:56] = a[63:56] - b[63:56];
	    			end
	    		3'd5:
	    			begin
	    				o[15:0] = a[15:0] - b[15:0];
	    				o[31:16] = a[31:16] - b[31:16];
	    				o[47:32] = a[47:32] - b[47:32];
	    				o[63:48] = a[63:48] - b[63:48];
	    			end
	    		3'd6:
	    			begin
	    				o[31:0] = a[31:0] - b[31:0];
	    				o[63:32] = a[63:32] - b[63:32];
	    			end
	        default:
	            	begin
	            		o = a - b;
	            	end
	            endcase
`else
			o = a - b;	            
`endif
			`DIF:
				begin
					o1 = a - b;
					o = o1[DBW-1] ? -o1 : o1;
				end
			`SEQ:		tskSeq(instr,instr[30:28],a,b,o);
	    `SLT:   tskSlt(instr,instr[30:28],a,b,o);
	    `SLTU:  tskSltu(instr,instr[30:28],a,b,o);
	    `SLE:   tskSle(instr,instr[30:28],a,b,o);
	    `SLEU:  tskSleu(instr,instr[30:28],a,b,o);
	    `AND:   o = and64;
	    `OR:    o = or64;
	    `XOR:   o = xor64;
	    `NAND:  o = ~and64;
	    `NOR:   o = ~or64;
	    `XNOR:  o = ~xor64;
	    `SEI:   o = a | instr[21:16];
	    `BMISC: o = a | instr[21:16];
	    `MUX:       for (n = 0; n < DBW; n = n + 1)
	                    o[n] <= a[n] ? b[n] : c[n];
	    `MULU,`MUL:
	    	begin
	        case(sz)
	        byt_para:		o1 = {prod87[7:0],prod86[7:0],prod85[7:0],prod84[7:0],prod83[7:0],prod82[7:0],prod81[7:0],prod80[7:0]};
	        char_para:	o1 = {prod163[15:0],prod162[15:0],prod161[15:0],prod160[15:0]};
					half_para:	o1 = {prod321[31:0],prod320[31:0]};
					default:		o1 = prod[DBW-1:0];
					endcase
	    		case(instr[`FUNCT2])
	    		2'd0:	o = o1;
	    		2'd1:	o = o1 + c;
	    		2'd2:	o = o1 & c;
	    		2'd3:	o = o1;
	    		endcase
	    	end
			`FXMUL:
				case(sz)
				half_para:	o = {prod321[47:16] + prod321[15],prod320[47:16] + prod320[15]};
				default:		o = prod[95:32] + prod[31];
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
	    `MIN: 
`ifdef SIMD
          case(sz)
    			3'd0:	o = BIG ? ($signed(a[7:0]) < $signed(b[7:0]) ? {{56{a[7]}},a[7:0]} : {{56{b[7]}},b[7:0]}) : 64'hCCCCCCCCCCCCCCCC;
	    		3'd1:	o = BIG ? ($signed(a[15:0]) < $signed(b[15:0]) ? {{48{a[15]}},a[15:0]} : {{48{b[15]}},b[15:0]}) : 64'hCCCCCCCCCCCCCCCC;
	    		3'd2:	o = BIG ? ($signed(a[31:0]) < $signed(b[31:0]) ? {{32{a[31]}},a[31:0]} : {{32{b[31]}},b[31:0]}) : 64'hCCCCCCCCCCCCCCCC;
					3'd3:	o = BIG ? ($signed(a) < $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
    			3'd4:
	    			begin
	    			o[7:0] = BIG ? ($signed(a[7:0]) < $signed(b[7:0]) ? a[7:0] : b[7:0]) : 8'hCC;
	    			o[15:8] = BIG ? ($signed(a[15:8]) < $signed(b[15:8]) ? a[15:8] : b[15:8]) : 64'hCCCCCCCCCCCCCCCC;
	    			o[23:16] = BIG ? ($signed(a[23:16]) < $signed(b[23:16]) ? a[23:16] : b[23:16]) : 64'hCCCCCCCCCCCCCCCC;
	    			o[31:24] = BIG ? ($signed(a[31:24]) < $signed(b[31:24]) ? a[31:24] : b[31:24]) : 64'hCCCCCCCCCCCCCCCC;
	    			o[39:32] = BIG ? ($signed(a[39:32]) < $signed(b[39:32]) ? a[39:32] : b[39:32]) : 64'hCCCCCCCCCCCCCCCC;
	    			o[47:40] = BIG ? ($signed(a[47:40]) < $signed(b[47:40]) ? a[47:40] : b[47:40]) : 64'hCCCCCCCCCCCCCCCC;
	    			o[55:48] = BIG ? ($signed(a[55:48]) < $signed(b[55:48]) ? a[55:48] : b[55:48]) : 64'hCCCCCCCCCCCCCCCC;
	    			o[63:56] = BIG ? ($signed(a[63:56]) < $signed(b[63:56]) ? a[63:56] : b[63:56]) : 64'hCCCCCCCCCCCCCCCC;
	    			end
	    		3'd5:
	    			begin
	    			o[15:0] = BIG ? ($signed(a[15:0]) < $signed(b[15:0]) ? a[15:0] : b[15:0]) : 64'hCCCCCCCCCCCCCCCC;
	    			o[32:16] = BIG ? ($signed(a[32:16]) < $signed(b[32:16]) ? a[32:16] : b[32:16]) : 64'hCCCCCCCCCCCCCCCC;
	    			o[47:32] = BIG ? ($signed(a[47:32]) < $signed(b[47:32]) ? a[47:32] : b[47:32]) : 64'hCCCCCCCCCCCCCCCC;
	    			o[63:48] = BIG ? ($signed(a[63:48]) < $signed(b[63:48]) ? a[63:48] : b[63:48]) : 64'hCCCCCCCCCCCCCCCC;
	    			end
	    		3'd6:
	    			begin
	    			o[31:0] = BIG ? ($signed(a[31:0]) < $signed(b[31:0]) ? a[31:0] : b[31:0]) : 64'hCCCCCCCCCCCCCCCC;
	    			o[63:32] = BIG ? ($signed(a[63:32]) < $signed(b[63:32]) ? a[63:32] : b[63:32]) : 64'hCCCCCCCCCCCCCCCC;
	    			end
					3'd7:
						begin
    				o = BIG ? ($signed(a) < $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
    				end
    			endcase
`else
				o = BIG ? ($signed(a) < $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
`endif	    			
	    `MAX: 
`ifdef SIMD     
	    			case(sz)
	    			3'd0:	o = BIG ? ($signed(a[7:0]) > $signed(b[7:0]) ? {{56{a[7]}},a[7:0]} : {{56{b[7]}},b[7:0]}) : 64'hCCCCCCCCCCCCCCCC;			
	    			3'd1:	o = BIG ? ($signed(a[15:0]) > $signed(b[15:0]) ? {{48{a[15]}},a[15:0]} : {{48{b[15]}},b[15:0]}) : 64'hCCCCCCCCCCCCCCCC;
	    			3'd2:	o = BIG ? ($signed(a[31:0]) > $signed(b[31:0]) ? {{32{a[31]}},a[31:0]} : {{32{b[31]}},b[31:0]}) : 64'hCCCCCCCCCCCCCCCC;
	    			3'd3:	o = BIG ? ($signed(a) > $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
	    			3'd4:
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
		    		3'd5:
		    			begin
		    			o[15:0] = BIG ? ($signed(a[15:0]) > $signed(b[15:0]) ? a[15:0] : b[15:0]) : 64'hCCCCCCCCCCCCCCCC;
		    			o[32:16] = BIG ? ($signed(a[32:16]) > $signed(b[32:16]) ? a[32:16] : b[32:16]) : 64'hCCCCCCCCCCCCCCCC;
		    			o[47:32] = BIG ? ($signed(a[47:32]) > $signed(b[47:32]) ? a[47:32] : b[47:32]) : 64'hCCCCCCCCCCCCCCCC;
		    			o[63:48] = BIG ? ($signed(a[63:48]) > $signed(b[63:48]) ? a[63:48] : b[63:48]) : 64'hCCCCCCCCCCCCCCCC;
		    			end
		    		3'd6:
		    			begin
		    			o[31:0] = BIG ? ($signed(a[31:0]) > $signed(b[31:0]) ? a[31:0] : b[31:0]) : 64'hCCCCCCCCCCCCCCCC;
		    			o[63:32] = BIG ? ($signed(a[63:32]) > $signed(b[63:32]) ? a[63:32] : b[63:32]) : 64'hCCCCCCCCCCCCCCCC;
		    			end
						3'd7: 
							begin
	    				o[63:0] = BIG ? ($signed(a) > $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
	    				end
	    			endcase
`else
			o = BIG ? ($signed(a) > $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
`endif	    			
	    `MAJ:		o = (a & b) | (a & c) | (b & c);
	    /*
	    `RTOP:		case(c[5:0])
	    			`RTADD:	o = a + b;
	    			`RTSUB:	o = a - b;
	    			`RTAND:	o = and64;
	    			`RTOR:	o = or64;
	    			`RTXOR:	o = xor64;
	    			`RTNAND:	o = ~and64;
	    			`RTNOR:	o = ~or64;
	    			`RTXNOR:	o = ~xor64;
	    			`RTSLT:	o = as < bs;
	    			`RTSGE:	o = as >= bs;
	    			`RTSLE: o = as <= bs;
	    			`RTSGT:	o = as > bs;
	    			`RTSEQ: o = as==bs;
	    			`RTSNE:	o = as!=bs;
	    			endcase
	    */
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
`ADDI:	o = a + b;
`DIFI:
	begin
		o1 = a - b;
		o = o1[DBW-1] ? -o1 : o1;
	end
`SEQI:	o = a == b;
`SNEI:	o = a != b;
`SLTI:	o = $signed(a) < $signed(b);
`SLEI:	o = $signed(a) <= $signed(b);
`SLTUI: o = a < b;
`SLEUI: o = a <= b;
`SGTI:	o = $signed(a) > $signed(b);
`SGEI:	o = $signed(a) >= $signed(b);
`SGTUI:	o = a > b;
`SGEUI:	o = a >= b;
`ANDI:	o = a & andb;
`ORI:		o = a | orb;
`XORI:	o = a ^ orb;
`MULUI:	o = prod[DBW-1:0];
`MULI:	o = prod[DBW-1:0];
`MULFI:	o = a[23:0] * b[15:0];
`DIVUI:		o = divq;
`MODUI:		o = rem;
`DIVI:		o = divq;
`MODI:		o = rem;
`ANDS0:		o = a & {{60{1'b1}},b[19:0]};
`ANDS1:		o = a & {{40{1'b1}},b[19:0],{20{1'b1}}};
`ANDS2:		o = a & {{20{1'b1}},b[19:0],{40{1'b1}}};
`ANDS3:		o = a & {b[19:0],{60{1'b1}}};
`ORS0:		o = a | b[19:0];
`ORS1:		o = a | (b[19:0] << 6'd20);
`ORS2:		o = a | (b[19:0] << 6'd40);
`ORS3:		o = a | (b[19:0] << 6'd60);
`ADDS0:		o = a + bsx20;
`ADDS1:		
	begin
		o1 = bsx20 << 6'd20;
		o = a + o1;
	end
`ADDS2:		o = a + (bsx20 << 6'd40);
`ADDS3:		o = a + (bsx20 << 6'd60);
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
casez({instr[32:31],instr[`OPCODE4]})
`R1:
	case(instr[21:16])
	`COM:	addro = ~shift8;
	`NOT:	addro = ~|shift8;
	`NEG:	addro = -shift8;
	default:	addro = 64'hDCDCDCDCDCDCDCDC;
	endcase
`R3:
		case({instr[`FUNCT5],instr[6]})
		`ADD,`SUB,
		`AND,`OR,`XOR,`NAND,`NOR,`XNOR,
		`SHL,`ASL,`SHR,`ASR,`ROL,`ROR:
			addro = shift8;
//			case(instr[41:36])
//			`ADD:	addro[63:0] = shift8 + c;
//			`SUB:	addro[63:0] = shift8 - c;
//			`AND:	addro[63:0] = shift8 & c;
//			`OR:	addro[63:0] = shift8 | c;
//			`XOR:	addro[63:0] = shift8 ^ c;
//			default:	addro[63:0] = 64'hDCDCDCDCDCDCDCDC;
//			endcase
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
		case(sz)
		byt,byt_para:	done <= mult_done80;
		schar,char_para:	done <= mult_done160;
		half,half_para:	done <= mult_done320;
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
		case(sz)
		byt,byt_para:	idle <= mult_idle80;
		schar,char_para:	idle <= mult_idle160;
		half,half_para:	idle <= mult_idle320;
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
casez({instr[32:31],instr[`OPCODE4]})
`R3:
    case({instr[`FUNCT5],instr[6]})
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

task tskSeq;
input [39:0] instr;
input [2:0] sz;
input [DBW:0] a;
input [DBW:0] b;
output [DBW:0] o;
begin
`ifdef SIMD
	case(sz[2:0])
  3'd0:   o = $signed(a[7:0]) == $signed(b[7:0]);
  3'd1:   o = $signed(a[15:0]) == $signed(b[15:0]);
  3'd2:   o = $signed(a[31:0]) == $signed(b[31:0]);
  3'd3:   o = $signed(a) == $signed(b);
  3'd4:		o = {
					        	7'h0,$signed(a[63:56]) == $signed(b[63:56]),
					        	7'h0,$signed(a[55:48]) == $signed(b[55:48]),
					        	7'h0,$signed(a[47:40]) == $signed(b[47:40]),
					        	7'h0,$signed(a[39:32]) == $signed(b[39:32]),
					        	7'h0,$signed(a[31:24]) == $signed(b[31:24]),
					        	7'h0,$signed(a[23:16]) == $signed(b[23:16]),
					        	7'h0,$signed(a[15:8]) == $signed(b[15:8]),
					        	7'h0,$signed(a[7:0]) == $signed(b[7:0])
						        };
  3'd5:		o = {
					        	15'h0,$signed(a[63:48]) == $signed(b[63:48]),
					        	15'h0,$signed(a[47:32]) == $signed(b[47:32]),
					        	15'h0,$signed(a[31:16]) == $signed(b[31:16]),
					        	15'h0,$signed(a[15:0]) == $signed(b[15:0])
						        };
  3'd6:		o = {
					        	31'h0,$signed(a[63:32]) == $signed(b[63:32]),
					        	31'h0,$signed(a[31:0]) == $signed(b[31:0])
						        };
	3'd7:		o = $signed(a) == $signed(b);
  endcase
`else
	o = $signed(a) == $signed(b);
`endif
end
endtask

task tskSlt;
input [39:0] instr;
input [2:0] sz;
input [79:0] a;
input [79:0] b;
output [79:0] o;
begin
`ifdef SIMD
	case(sz[2:0])
  3'd0:   o = $signed(a[7:0]) < $signed(b[7:0]);
  3'd1:   o = $signed(a[15:0]) < $signed(b[15:0]);
  3'd2:   o = $signed(a[31:0]) < $signed(b[31:0]);
  3'd3:   o = $signed(a) < $signed(b);
  3'd4:		o = {
					        	7'h0,$signed(a[63:56]) < $signed(b[63:56]),
					        	7'h0,$signed(a[55:48]) < $signed(b[55:48]),
					        	7'h0,$signed(a[47:40]) < $signed(b[47:40]),
					        	7'h0,$signed(a[39:32]) < $signed(b[39:32]),
					        	7'h0,$signed(a[31:24]) < $signed(b[31:24]),
					        	7'h0,$signed(a[23:16]) < $signed(b[23:16]),
					        	7'h0,$signed(a[15:8]) < $signed(b[15:8]),
					        	7'h0,$signed(a[7:0]) < $signed(b[7:0])
						        };
  3'd5:		o = {
					        	15'h0,$signed(a[63:48]) < $signed(b[63:48]),
					        	15'h0,$signed(a[47:32]) < $signed(b[47:32]),
					        	15'h0,$signed(a[31:16]) < $signed(b[31:16]),
					        	15'h0,$signed(a[15:0]) < $signed(b[15:0])
						        };
  3'd6:		o = {
					        	31'h0,$signed(a[63:32]) < $signed(b[63:32]),
					        	31'h0,$signed(a[31:0]) < $signed(b[31:0])
						        };
	3'd7:		o = $signed(a) < $signed(b);
  endcase
`else
	o = $signed(a) < $signed(b);
`endif
end
endtask

task tskSle;
input [39:0] instr;
input [2:0] sz;
input [79:0] a;
input [79:0] b;
output [79:0] o;
begin
`ifdef SIMD
	case(sz[2:0])
  3'd0:   o = $signed(a[7:0]) <= $signed(b[7:0]);
  3'd1:   o = $signed(a[15:0]) <= $signed(b[15:0]);
  3'd2:   o = $signed(a[31:0]) <= $signed(b[31:0]);
  3'd3:   o = $signed(a) <= $signed(b);
  3'd4:		o = {
					        	7'h0,$signed(a[63:56]) <= $signed(b[63:56]),
					        	7'h0,$signed(a[55:48]) <= $signed(b[55:48]),
					        	7'h0,$signed(a[47:40]) <= $signed(b[47:40]),
					        	7'h0,$signed(a[39:32]) <= $signed(b[39:32]),
					        	7'h0,$signed(a[31:24]) <= $signed(b[31:24]),
					        	7'h0,$signed(a[23:16]) <= $signed(b[23:16]),
					        	7'h0,$signed(a[15:8]) <= $signed(b[15:8]),
					        	7'h0,$signed(a[7:0]) <= $signed(b[7:0])
						        };
  3'd5:		o = {
					        	15'h0,$signed(a[63:48]) <= $signed(b[63:48]),
					        	15'h0,$signed(a[47:32]) <= $signed(b[47:32]),
					        	15'h0,$signed(a[31:16]) <= $signed(b[31:16]),
					        	15'h0,$signed(a[15:0]) <= $signed(b[15:0])
						        };
  3'd6:		o = {
					        	31'h0,$signed(a[63:32]) <= $signed(b[63:32]),
					        	31'h0,$signed(a[31:0]) <= $signed(b[31:0])
						        };
	3'd7:		o = $signed(a) <= $signed(b);
  endcase
`else
	o = $signed(a) <= $signed(b);
`endif
end
endtask

task tskSltu;
input [39:0] instr;
input [2:0] sz;
input [79:0] a;
input [79:0] b;
output [79:0] o;
begin
`ifdef SIMD
	case(sz[2:0])
	3'd0:		o = (a[7:0]) < (b[7:0]);
	3'd1:		o = (a[15:0]) < (b[15:0]);
	3'd2:		o = (a[31:0]) < (b[31:0]);
  3'd4:		o = {
			        	7'h0,(a[63:56]) < (b[63:56]),
			        	7'h0,(a[55:48]) < (b[55:48]),
			        	7'h0,(a[47:40]) < (b[47:40]),
			        	7'h0,(a[39:32]) < (b[39:32]),
			        	7'h0,(a[31:24]) < (b[31:24]),
			        	7'h0,(a[23:16]) < (b[23:16]),
			        	7'h0,(a[15:8]) < (b[15:8]),
			        	7'h0,(a[7:0]) < (b[7:0])
				        };
  3'd5:		o = {
		        	15'h0,(a[63:48]) < (b[63:48]),
		        	15'h0,(a[47:32]) < (b[47:32]),
		        	15'h0,(a[31:16]) < (b[31:16]),
		        	15'h0,(a[15:0]) < (b[15:0])
			        };
  3'd6:		o = {
		        	31'h0,(a[63:32]) < (b[63:32]),
		        	31'h0,(a[31:0]) < (b[31:0])
			        };
	3'd7,3'd3:		o = (a) < (b);
  endcase
`else
	o = (a) < (b);
`endif
end
endtask

task tskSleu;
input [39:0] instr;
input [2:0] sz;
input [79:0] a;
input [79:0] b;
output [79:0] o;
begin
`ifdef SIMD
	case(sz[2:0])
	3'd0:		o = (a[7:0]) <= (b[7:0]);
	3'd1:		o = (a[15:0]) <= (b[15:0]);
	3'd2:		o = (a[31:0]) <= (b[31:0]);
  3'd4:		o = {
			        	7'h0,(a[63:56]) <= (b[63:56]),
			        	7'h0,(a[55:48]) <= (b[55:48]),
			        	7'h0,(a[47:40]) <= (b[47:40]),
			        	7'h0,(a[39:32]) <= (b[39:32]),
			        	7'h0,(a[31:24]) <= (b[31:24]),
			        	7'h0,(a[23:16]) <= (b[23:16]),
			        	7'h0,(a[15:8]) <= (b[15:8]),
			        	7'h0,(a[7:0]) <= (b[7:0])
				        };
  3'd5:		o = {
		        	15'h0,(a[63:48]) <= (b[63:48]),
		        	15'h0,(a[47:32]) <= (b[47:32]),
		        	15'h0,(a[31:16]) <= (b[31:16]),
		        	15'h0,(a[15:0]) <= (b[15:0])
			        };
  3'd6:		o = {
		        	31'h0,(a[63:32]) <= (b[63:32]),
		        	31'h0,(a[31:0]) <= (b[31:0])
			        };
	3'd7,3'd3:		o = (a) <= (b);
  endcase
`else
	o = (a) <= (b);
`endif
end
endtask

endmodule
