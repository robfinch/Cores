// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_alu.v
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
`include "FT64_defines.vh"
`include "FT64_config.vh"

module FT64_alu(rst, clk, ld, abort, instr, sz, store, a, b, c, t, pc, Ra, tgt, tgt2, ven, vm,
    csr, o, ob, done, idle, excen, exc, thrd, ptrmask, state, mem, shift,
    ol, dl
`ifdef SUPPORT_BBMS 
    , pb, cbl, cbu, ro, dbl, dbu, sbl, sbu, en
`endif
    );
parameter DBW = 64;
parameter ABW = 64;
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
input [47:0] instr;
input [2:0] sz;
input store;
input [63:0] a;
input [63:0] b;
input [63:0] c;
input [63:0] t;			// target register value
input [31:0] pc;
input [11:0] Ra;
input [11:0] tgt;
input [7:0] tgt2;
input [5:0] ven;
input [15:0] vm;
input [63:0] csr;
output reg [63:0] o;
output reg [63:0] ob;
output reg done;
output reg idle;
input [4:0] excen;
output reg [8:0] exc;
input thrd;
input [63:0] ptrmask;
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
parameter char = 3'd1;
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
reg [63:0] addro;
reg [63:0] adr;			// load / store address
reg [63:0] shift8;
reg [63:0] o1;

wire [7:0] a8 = a[7:0];
wire [15:0] a16 = a[15:0];
wire [31:0] a32 = a[31:0];
wire [7:0] b8 = b[7:0];
wire [15:0] b16 = b[15:0];
wire [31:0] b32 = b[31:0];
wire [63:0] orb = instr[6] ? {34'd0,b[29:0]} : {50'd0,b[13:0]};
wire [63:0] andb = b;//((instr[6]==1'b1) ? {34'h3FFFFFFFF,b[29:0]} : {50'h3FFFFFFFFFFFF,b[13:0]});

wire [21:0] qimm = instr[39:18];
wire [63:0] imm = {{45{instr[39]}},instr[39:21]};
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
wire [63:0] shftho;
reg [63:0] shift9;

function IsLoad;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b00)
		IsLoad = !isn[31];
	else
		IsLoad = FALSE;
`LB:    IsLoad = TRUE;
`LC:    IsLoad = TRUE;
`LH:    IsLoad = TRUE;
`LW:    IsLoad = TRUE;
`LV:    IsLoad = TRUE;
default:    IsLoad = FALSE;
endcase
endfunction

function IsMul;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`IVECTOR:
  case(isn[`INSTRUCTION_S2])
  `VMUL,`VMULS:   IsMul = TRUE;
  default:    IsMul = FALSE;
  endcase
`R2:
  case(isn[`INSTRUCTION_S2])
  `MULU,`MULSU,`MUL: IsMul = TRUE;
  `MULUH,`MULSUH,`MULH: IsMul = TRUE;
  `FXMUL: IsMul = TRUE;
  default:    IsMul = FALSE;
  endcase
`MULUI,`MULI:  IsMul = TRUE;
default:    IsMul = FALSE;
endcase
endfunction

function IsDivmod;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`IVECTOR:
  case(isn[`INSTRUCTION_S2])
  `VDIV,`VDIVS:   IsDivmod = TRUE;
  default:    IsDivmod = FALSE;
  endcase
`R2:
  case(isn[`INSTRUCTION_S2])
  `DIVU,`DIVSU,`DIV: IsDivmod = TRUE;
  `MODU,`MODSU,`MOD: IsDivmod = TRUE;
  default:    IsDivmod = FALSE;
  endcase
`DIVUI,`DIVI:  IsDivmod = TRUE;
default:    IsDivmod = FALSE;
endcase
endfunction

function IsSgn;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`IVECTOR:
    case(isn[`INSTRUCTION_S2])
    `VMUL,`VMULS,`VDIV,`VDIVS:    IsSgn = TRUE;
    default:    IsSgn = FALSE;
    endcase
`R2:
  case(isn[`INSTRUCTION_S2])
  `MUL,`DIV,`MOD,`MULH:   IsSgn = TRUE;
  `FXMUL: IsSgn = TRUE;
  default:    IsSgn = FALSE;
  endcase
`MULI,`DIVI,`MODI:    IsSgn = TRUE;
default:    IsSgn = FALSE;
endcase
endfunction

function IsSgnus;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`R2:
  case(isn[`INSTRUCTION_S2])
  `MULSU,`MULSUH,`DIVSU,`MODSU:   IsSgnus = TRUE;
  default:    IsSgnus = FALSE;
  endcase
default:    IsSgnus = FALSE;
endcase
endfunction

function IsShiftAndOp;
input [47:0] isn;
if (isn[`INSTRUCTION_L2]==2'b01) begin
	case(isn[`INSTRUCTION_OP])
	`R2:
		case(isn[47:42])
		`SHIFTR:	IsShiftAndOp = TRUE;
		default:	IsShiftAndOp = FALSE;
		endcase
	default:	IsShiftAndOp = FALSE;
	endcase
end
else
	IsShiftAndOp = FALSE;
endfunction

wire [63:0] bfout,shfto;
wire [63:0] shftob;
wire [63:0] shftco;
reg [63:0] shift10;

always @(posedge clk)
	shift9 <= shift8;
always @*
case (instr[41:36])
`ADD:	shift10 <= shift9 + c;
`SUB:	shift10 <= shift9 - c;
`AND:	shift10 <= shift9 & c;
`OR:	shift10 <= shift9 | c;
`XOR:	shift10 <= shift9 ^ c;
6'h20:	shift10 <= ~shift9;		// COM
6'h21:	shift10 <= !shift9;		// NOT
default:	shift10 <= shift9;
endcase

FT64_bitfield #(DBW) ubf1
(
    .inst(instr),
    .a(a),
    .b(b),
    .c(c),
    .o(bfout),
    .masko()
);

FT64_multiplier #(DBW) umult1
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

FT64_multiplier #(32) umulth0
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

FT64_multiplier #(16) umultc0
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsMul(instr) && (sz==char || sz==char_para)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a[15:0]),
	.b(b[15:0]),
	.o(prod160),
	.done(mult_done160),
	.idle(mult_idle160)
);

FT64_multiplier #(8) umultb0
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
FT64_multiplier #(32) umulth1
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

FT64_multiplier #(16) umultc1
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

FT64_multiplier #(16) umultc2
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

FT64_multiplier #(16) umultc3
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

FT64_multiplier #(8) umultb1
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

FT64_multiplier #(8) umultb2
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

FT64_multiplier #(8) umultb3
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

FT64_multiplier #(8) umultb4
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

FT64_multiplier #(8) umultb5
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

FT64_multiplier #(8) umultb6
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

FT64_multiplier #(8) umultb7
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

FT64_divider #(DBW) udiv1
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

wire [5:0] bshift = IsShiftAndOp(instr) ? ( instr[29] ? {instr[28],instr[22:18]} : b[5:0])
																			 : (instr[31:26]==`SHIFTR ? b[5:0] : {instr[30],instr[22:18]});

FT64_shift ushft1
(
    .instr(instr),
    .a(a),
    .b(bshift),
    .res(shfto),
    .ov(aslo)
);

FT64_shifth ushfthL
(
    .instr(instr),
    .a(a[31:0]),
    .b(bshift),
    .res(shftho[31:0]),
    .ov()
);

FT64_shifth ushfthH
(
    .instr(instr),
    .a(a[63:32]),
    .b(b[63:32]),
    .res(shftho[63:32]),
    .ov()
);

FT64_shiftc ushftc0
(
    .instr(instr),
    .a(a[15:0]),
    .b(bshift),
    .res(shftco[15:0]),
    .ov()
);

FT64_shiftc ushftc1
(
    .instr(instr),
    .a(a[31:16]),
    .b(b[31:16]),
    .res(shftco[31:16]),
    .ov()
);

FT64_shiftc ushftc2
(
    .instr(instr),
    .a(a[47:32]),
    .b(b[47:32]),
    .res(shftco[47:32]),
    .ov()
);

FT64_shiftc ushftc3
(
    .instr(instr),
    .a(a[63:48]),
    .b(b[63:48]),
    .res(shftco[63:48]),
    .ov()
);

FT64_shiftb ushftb0
(
    .instr(instr),
    .a(a[7:0]),
    .b(bshift),
    .res(shftob[7:0]),
    .ov()
);

FT64_shiftb ushftb1
(
    .instr(instr),
    .a(a[15:8]),
    .b(b[15:8]),
    .res(shftob[15:8]),
    .ov()
);

FT64_shiftb ushftb2
(
    .instr(instr),
    .a(a[23:16]),
    .b(b[23:16]),
    .res(shftob[23:16]),
    .ov()
);

FT64_shiftb ushftb3
(
    .instr(instr),
    .a(a[31:24]),
    .b(b[31:24]),
    .res(shftob[31:24]),
    .ov()
);

FT64_shiftb ushftb4
(
    .instr(instr),
    .a(a[39:32]),
    .b(b[39:32]),
    .res(shftob[39:32]),
    .ov()
);

FT64_shiftb ushftb5
(
    .instr(instr),
    .a(a[47:40]),
    .b(b[47:40]),
    .res(shftob[47:40]),
    .ov()
);

FT64_shiftb ushftb6
(
    .instr(instr),
    .a(a[55:48]),
    .b(b[55:48]),
    .res(shftob[55:48]),
    .ov()
);

FT64_shiftb ushftb7
(
    .instr(instr),
    .a(a[63:56]),
    .b(b[63:56]),
    .res(shftob[63:56]),
    .ov()
);

cntlz64 uclz1
(
	.i(sz==2'd0 ? {56'hFFFFFFFFFFFFFF,a[7:0]} :
	   sz==2'd1 ? {48'hFFFFFFFFFFFF,a[15:0]} :
	   sz==2'd2 ? {32'hFFFFFFFF,a[31:0]} : a),
	.o(clzo)
);

cntlo64 uclo1
(
	.i(sz==2'd0 ? a[7:0] : sz==2'd1 ? a[15:0] : sz==2'd2 ? a[31:0] : a),
	.o(cloo)
);

cntpop64 ucpop1
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
wire [63:0] and64 = a & b;
wire [63:0] or64 = a | b;
wire [63:0] xor64 = a ^ b;
wire [63:0] redor64 = {63'd0,|a};
wire [63:0] redor32 = {31'd0,|a[63:32],31'd0,|a[31:0]};
wire [63:0] redor16 = {15'd0,|a[63:48],15'd0,|a[47:32],15'd0,|a[31:16],15'd0,|a[15:0]};
wire [63:0] redor8 = {7'b0,|a[63:56],6'b0,|a[55:48],7'd0,|a[47:40],7'd0,|a[39:32],7'd0,
													 |a[31:24],7'd0,|a[23:16],7'd0,|a[15:8],7'd0,|a[7:0]};
wire [63:0] redand64 = {63'd0,&a};
wire [63:0] redand32 = {31'd0,&a[63:32],31'd0,&a[31:0]};
wire [63:0] redand16 = {15'd0,&a[63:48],15'd0,&a[47:32],15'd0,&a[31:16],15'd0,&a[15:0]};
wire [63:0] redand8 = {7'b0,&a[63:56],6'b0,&a[55:48],7'd0,&a[47:40],7'd0,&a[39:32],7'd0,
													 &a[31:24],7'd0,&a[23:16],7'd0,&a[15:8],7'd0,&a[7:0]};
wire [63:0] zxb10 = {54'd0,b[9:0]};
wire [63:0] sxb10 = {{54{b[9]}},b[9:0]};
wire [63:0] zxb26 = {38'd0,instr[47:32],instr[27:18]};
wire [63:0] sxb26 = {{38{instr[47]}},instr[47:32],instr[27:18]};
reg [15:0] mask;
wire [4:0] cpopom;
wire signed [63:0] as = a;
wire signed [63:0] bs = b;
wire signed [63:0] cs = c;

always @*
for (n = 0; n < 16; n = n + 1)
    if (n <= ven)
        mask[n] = 1'b1;
    else
        mask[n] = 1'b0;

cntpop16 ucpop2
(
	.i(vm & mask),
	.o(cpopom)
);

wire [5:0] lsto, fsto;
ffz24 uffo1
(
    .i(~{8'h00,a[15:0]}),
    .o(lsto)
);

flz24 uflo1
(
    .i(~{8'h00,a[15:0]}),
    .o(fsto)
);

wire [DBW-1:0] bmmo;
FT64_BMM ubmm1
(
	.op(1'b0),
	.a(a),
	.b(b),
	.o(bmmo)
);

always @*
begin
case(instr[`INSTRUCTION_OP])
`IVECTOR:
    if (SUP_VECTOR)
    case(instr[`INSTRUCTION_S2])
    `VABS:         o[63:0] = a[63] ? -a : a;
    `VSIGN:        o[63:0] = a[63] ? 64'hFFFFFFFFFFFFFFFF : a==64'd0 ? 64'd0 : 64'd1;
    `VMxx:
    	case(instr[25:23])
	    `VMAND:        o[63:0] = and64;
	    `VMOR:         o[63:0] = or64;
	    `VMXOR:        o[63:0] = xor64;
	    `VMXNOR:       o[63:0] = ~(xor64);
	    `VMPOP:        o[63:0] = {57'd0,cpopo};
	    `VMFILL:       for (n = 0; n < 64; n = n + 1)
	                       o[n] = (n < a);
	                       // Change the following when VL > 16
	    `VMFIRST:      o[63:0] = fsto==5'd31 ? 64'd64 : fsto;
	    `VMLAST:       o[63:0] = lsto==5'd31 ? 64'd64 : lsto;
		endcase
    `VADD,`VADDS:  o[63:0] = vm[ven] ? a + b : c;
    `VSUB,`VSUBS:  o[63:0] = vm[ven] ? a - b : c;
    `VMUL,`VMULS:  o[63:0] = vm[ven] ? prod[DBW-1:0] : c;
    `VDIV,`VDIVS:  o[63:0] = BIG ? (vm[ven] ? divq : c) : 64'hCCCCCCCCCCCCCCCC;
    `VAND,`VANDS:  o[63:0] = vm[ven] ? a & b : c;
    `VOR,`VORS:    o[63:0] = vm[ven] ? a | b : c;
    `VXOR,`VXORS:  o[63:0] = vm[ven] ? a ^ b : c;
    `VCNTPOP:      o[63:0] = {57'd0,cpopo};
    `VSHLV:        o[63:0] = a;   // no masking here
    `VSHRV:        o[63:0] = a;
    `VCMPRSS:      o[63:0] = a;
    `VCIDX:        o[63:0] = a * ven;
    `VSCAN:        o[63:0] = a * (cpopom==0 ? 0 : cpopom-1);
    `VSxx,`VSxxS,
    `VSxxb,`VSxxSb:
        case({instr[26],instr[20:19]})
        `VSEQ:     begin
                       o[63:0] = c;    
                       o[ven] = vm[ven] ? a==b : c[ven];
                   end
        `VSNE:     begin
                       o[63:0] = c;    
                       o[ven] = vm[ven] ? a!=b : c[ven];
                   end
        `VSLT:      begin
                         o[63:0] = c;    
                         o[ven] = vm[ven] ? $signed(a) < $signed(b) : c[ven];
                    end
        `VSGE:      begin
                         o[63:0] = c;    
                         o[ven] = vm[ven] ? $signed(a) >= $signed(b) : c[ven];
                    end
        `VSLE:      begin
                          o[63:0] = c;    
                          o[ven] = vm[ven] ? $signed(a) <= $signed(b) : c[ven];
                    end
        `VSGT:      begin
                         o[63:0] = c;    
                         o[ven] = vm[ven] ? $signed(a) > $signed(b) : c[ven];
                    end
        default:	o[63:0] = 64'hCCCCCCCCCCCCCCCC;
        endcase
    `VSxxU,`VSxxSU,
    `VSxxUb,`VSxxSUb:
        case({instr[26],instr[20:19]})
        `VSEQ:     begin
                       o[63:0] = c;    
                       o[ven] = vm[ven] ? a==b : c[ven];
                   end
        `VSNE:     begin
                       o[63:0] = c;    
                       o[ven] = vm[ven] ? a!=b : c[ven];
                   end
        `VSLT:      begin
                         o[63:0] = c;    
                         o[ven] = vm[ven] ? a < b : c[ven];
                    end
        `VSGE:      begin
                         o[63:0] = c;    
                         o[ven] = vm[ven] ? a >= b : c[ven];
                    end
        `VSLE:      begin
                          o[63:0] = c;    
                          o[ven] = vm[ven] ? a <= b : c[ven];
                    end
        `VSGT:      begin
                         o[63:0] = c;    
                         o[ven] = vm[ven] ? a > b : c[ven];
                    end
        default:	o[63:0] = 64'hCCCCCCCCCCCCCCCC;
        endcase
    `VBITS2V:   o[63:0] = vm[ven] ? a[ven] : c;
    `V2BITS:    begin
                o[63:0] = b;
                o[ven] = vm[ven] ? a[0] : b[ven];
                end
    `VSHL,`VSHR,`VASR:  o[63:0] = BIG ? shfto : 64'hCCCCCCCCCCCCCCCC;
    `VXCHG:     o[63:0] = vm[ven] ? b : a;
    default:	o[63:0] = 64'hCCCCCCCCCCCCCCCC;
    endcase
    else
        o[63:0] <= 64'hCCCCCCCCCCCCCCCC;    
`R2:
	if (instr[6])
		case(instr[47:42])
		`SHIFTR:
			begin
			case(instr[35:33])
			`ASL,`ASR,`ROL,`ROR:
				case(instr[32:30])	// size
				3'd0:	shift8 = {{56{shftob[7]}},shftob[7:0]};
				3'd1:	shift8 = {{48{shftob[15]}},shftco[15:0]};
				3'd2:	shift8 = {{32{shftho[31]}},shftho[31:0]};
				3'd3,3'd7:	shift8 = shfto;
				3'd4:	shift8 = shftob;
				3'd5:	shift8 = shftco;
				3'd6:	shift8 = shftho;
				endcase
			`SHL,`SHR:
				case(instr[32:30])	// size
				3'd0:	shift8 = {56'd0,shftob[7:0]};
				3'd1:	shift8 = {48'd0,shftco[15:0]};
				3'd2:	shift8 = {32'd0,shftho[31:0]};
				3'd3,3'd7:	shift8 = shfto;
				3'd4:	shift8 = shftob;
				3'd5:	shift8 = shftco;
				3'd6:	shift8 = shftho;
				endcase
			default:	o[63:0] = 64'hDCDCDCDCDCDCDCDC;
			endcase
			case(instr[35:33])
			`ASL,`ASR,`SHL,`SHR,`ROL,`ROR:
				o[63:0] = shift10;
			default:	o[63:0] = 64'hDCDCDCDCDCDCDCDC;
			endcase
			end
		`MIN:
			case(instr[30:28])
			3'd3:
				if (as < bs && as < cs)
					o[63:0] = as;
				else if (bs < cs)
					o[63:0] = bs;
				else
					o[63:0] = cs;
	    default:	o = 64'hDEADDEADDEADDEAD;
			endcase
    `CMOVEZ:    begin
    			o = (a==64'd0) ? b : c;
    			end
    `CMOVNZ:	if (instr[41:39]==3'd4)
    				o = (a!=64'd0) ? b : {{48{instr[38]}},instr[38:23]};
    			else
    				o = (a!=64'd0) ? b : c;
    default:	o = 64'hDEADDEADDEADDEAD;
		endcase
	else
	    casez(instr[`INSTRUCTION_S2])
	    `BCD:
	        case(instr[`INSTRUCTION_S1])
	        `BCDADD:    o[63:0] = BIG ? bcdaddo :  64'hCCCCCCCCCCCCCCCC;
	        `BCDSUB:    o[63:0] = BIG ? bcdsubo :  64'hCCCCCCCCCCCCCCCC;
	        `BCDMUL:    o[63:0] = BIG ? bcdmulo :  64'hCCCCCCCCCCCCCCCC;
	        default:    o[63:0] = 64'hDEADDEADDEADDEAD;
	        endcase
	    `MOV:	begin	
	    		o[63:0] = a;
	    		end
	    `VMOV:		o[63:0] = a;
	    `R1:
	        case(instr[`INSTRUCTION_S1])
	        `CNTLZ:     o[63:0] = BIG ? {57'd0,clzo} : 64'hCCCCCCCCCCCCCCCC;
	        `CNTLO:     o[63:0] = BIG ? {57'd0,cloo} : 64'hCCCCCCCCCCCCCCCC;
	        `CNTPOP:    o[63:0] = BIG ? {57'd0,cpopo} : 64'hCCCCCCCCCCCCCCCC;
	        `ABS:       case(sz[1:0])
	                    2'd0:   o[63:0] = BIG ? (a[7] ? -a[7:0] : a[7:0]) : 64'hCCCCCCCCCCCCCCCC;
	                    2'd1:   o[63:0] = BIG ? (a[15] ? -a[15:0] : a[15:0]) : 64'hCCCCCCCCCCCCCCCC;
	                    2'd2:   o[63:0] = BIG ? (a[31] ? -a[31:0] : a[31:0]) : 64'hCCCCCCCCCCCCCCCC;
	                    2'd3:   o[63:0] = BIG ? (a[63] ? -a : a) : 64'hCCCCCCCCCCCCCCCC;
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
	        `ZXH:		o[63:0] = {32'd0,a[31:0]};
	        `ZXC:		o[63:0] = {48'd0,a[15:0]};
	        `ZXB:		o[63:0] = {56'd0,a[7:0]};
	        `SXH:		o[63:0] = {{32{a[31]}},a[31:0]};
	        `SXC:		o[63:0] = {{48{a[15]}},a[15:0]};
	        `SXB:		o[63:0] = {{56{a[7]}},a[7:0]};
//	        5'h1C:		o[63:0] = tmem[a[9:0]];
	        default:    o = 64'hDEADDEADDEADDEAD;
	        endcase
	    `BMM:		o[63:0] = BIG ? bmmo : 64'hCCCCCCCCCCCCCCCC;
	    `SHIFT31,
	    `SHIFT63:
	    	begin
	    		if (instr[25:23]==`SHL || instr[25:23]==`ASL)
	    			o = shfto;
	    		else
	    			o = BIG ? shfto : 64'hCCCCCCCCCCCCCCCC;
	    		$display("BIG=%d",BIG);
	    		if(!BIG)
	    			$stop;
	    	end
	    `SHIFTR:
	    	begin
	    		if (instr[25:23]==`SHL || instr[25:23]==`ASL)
	    			o = shfto;
	    		else
	    			o = BIG ? shfto : 64'hCCCCCCCCCCCCCCCC;
	    		$display("BIG=%d",BIG);
	    		if(!BIG)
	    			$stop;
	    	end
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
	            		o[63:0] = a + b;
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
			`SEQ:		tskSeq(instr,instr[25:23],a,b,o);
	    `SLT:   tskSlt(instr,instr[25:23],a,b,o);
	    `SLTU:  tskSltu(instr,instr[25:23],a,b,o);
	    `SLE:   tskSle(instr,instr[25:23],a,b,o);
	    `SLEU:  tskSleu(instr,instr[25:23],a,b,o);
	    `AND:   o = and64;
	    `OR:    o = or64;
	    `XOR:   o = xor64;
	    `NAND:  o = ~and64;
	    `NOR:   o = ~or64;
	    `XNOR:  o = ~xor64;
	    `SEI:   o = a | instr[21:16];
	    `RTI:   o = a | instr[21:16];
	    `MUX:       for (n = 0; n < 64; n = n + 1)
	                    o[n] <= a[n] ? b[n] : c[n];
	    `MULU,`MULSU,`MUL:
        case(sz)
        byt_para:		o[63:0] = {prod87[7:0],prod86[7:0],prod85[7:0],prod84[7:0],prod83[7:0],prod82[7:0],prod81[7:0],prod80[7:0]};
        char_para:	o[63:0] = {prod163[15:0],prod162[15:0],prod161[15:0],prod160[15:0]};
				half_para:	o[63:0] = {prod321[31:0],prod320[31:0]};
				default:		o[63:0] = prod[DBW-1:0];
				endcase
			`FXMUL:
				case(sz)
				half_para:	o = {prod321[47:16] + prod321[15],prod320[47:16] + prod320[15]};
				default:		o = prod[95:32] + prod[31];
				endcase
			`MULF:	o = a[23:0] * b[15:0];
	    `DIVU:   o[63:0] = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
	    `DIVSU:  o[63:0] = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
	    `DIV:    o[63:0] = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
	    `MODU:   o[63:0] = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
	    `MODSU:  o[63:0] = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
	    `MOD:    o[63:0] = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
			`LEAX:
					begin
						o1 = BIG ? a[43:0] + (b << instr[22:21]) : 64'hCCCCCCCCEEEEEEEE;
						o = BIG ? {20'hFFF01,o1[43:0]} : 64'hCCCCCCCCEEEEEEEE;
					//o[63:44] = PTR;
					end
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
			o[63:0] = BIG ? ($signed(a) > $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
`endif	    			
	    `MAJ:		o = (a & b) | (a & c) | (b & c);
	    `CHK:       o[63:0] = (a >= b && a < c);
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
	    default:    o[63:0] = 64'hDEADDEADDEADDEAD;
	    endcase
`MEMNDX:
	if (instr[7:6]==2'b10) begin
		if (instr[31])
			case({instr[31:28],instr[17:16]})
			`PUSH:	
				begin
					usa = a - 4'd8;
					o = {pb[50:0],13'd0} + usa;
				end
	    default:	o = 64'hDEADDEADDEADDEAD;
			endcase
		else
			o = 64'hDEADDEADDEADDEAD;
	end
	else if (instr[7:6]==2'b00) begin
		if (!instr[31])
			case({instr[31:28],instr[22:21]})
			`CACHEX,`LVX,
	    `LBX,`LBUX,`LCX,`LCUX,
	    `LVBX,`LVBUX,`LVCX,`LVCUX,`LVHX,`LVHUX,`LVWX,
	    `LHX,`LHUX,`LWX,`LWRX:
					if (BIG) begin
						usa = a + (c << instr[19:18]);
						o = {pb[50:0],BASE_SHIFT} + usa;
					end
					else
						o = 64'hCCCCCCCCEEEEEEEE;
	    `LVX,`SVX:
	    	if (BIG) begin
	    		usa = a + (c << 2'd3);
	    		o = {pb[50:0],BASE_SHIFT} + usa;
	    	end
	    	else
	    		o = 64'hCCCCCCCCCCCCCCCC;
	    `LVWS,`SVWS:
	    			if (BIG) begin    
	    				usa = a + ({c * ven,3'b000});
	    				o = {pb[50:0],BASE_SHIFT} + usa;
	    			end
	    			else
	    				o = 64'hCCCCCCCCCCCCCCCC;
	    default:	o = 64'hDEADDEADDEADDEAD;
			endcase
		else
			case({instr[31:28],instr[17:16]})
			`PUSH:	
				begin
					usa = a - 4'd8;
					o = {pb[50:0],BASE_SHIFT} + usa;
				end
	    `SBX,`SCX,`SHX,`SWX,`SWCX:
					if (BIG) begin
						usa = a + (c << instr[14:13]);
						o = {pb[50:0],BASE_SHIFT} + usa;
					end
					else
						o = 64'hCCCCCCCCEEEEEEEE;
	    `SVX:  if (BIG) begin
	    				usa = a + (c << 2'd3);
	    				o = {pb[50:0],BASE_SHIFT} + usa;
	    			end
	    			else
	    				o = 64'hCCCCCCCCCCCCCCCC;
	    `SVWS:
	    			if (BIG) begin    
	    				usa = a + ({c * ven,3'b000});
	    				o = {pb[50:0],BASE_SHIFT} + usa;
	    			end
	    			else
	    				o = 64'hCCCCCCCCCCCCCCCC;
	    default:	o = 64'hDEADDEADDEADDEAD;
			endcase
	end
	else
		o[63:0] = 64'hDEADDEADDEADDEAD;
`AUIPC:
 	begin
 		if (instr[7:6]==2'b01)
 			o[63:0] = pc + {instr[47:18],instr[12:8],29'd0};
 		else
 			o[63:0] = pc + {{16{instr[31]}},instr[31:18],instr[12:8],29'd0};
 		o[28:0] = 29'd0;
// 		o[63:44] = PTR;
 	end
`LUI:
 	begin
 		if (instr[7:6]==2'b01)
 			o = {instr[47:18],instr[12:8],29'd0};
 		else
 			o = {{16{instr[31]}},instr[31:18],instr[12:8],29'd0};
	end
`ADDI:	o = a + b;
`SEQI:	o = instr[23] ? a != b : a == b;
`SLTI:	
	begin
		o1 = $signed(a) < $signed(b);
		o = instr[23] ? (o1 || a==b) : o1;
	end
`SLTUI:
	begin
	 o1 = a < b;
	 o = instr[23] ? (o1 || a==b) : o1;
	end
`SGTI:
	begin
		o1 = $signed(a) > $signed(b);
		o = instr[23] ? (o1 || a==b) : o1;
	end
`SGTUI: 
	begin
		o1 = a > b;
		o = instr[23] ? (o1 || a==b) : o1;
	end
`ANDI:	o = a & andb;
`ORI:		o = a | orb;
`XORI:	o = a ^ orb;
`MULUI:	o = prod[DBW-1:0];
`MULI:	o = prod[DBW-1:0];
`MULFI:	o = a[23:0] * b[15:0];
`DIVUI:		o = BIG ? (instr[23] ? rem : divq) : 64'hCCCCCCCCCCCCCCCC;
`DIVI:		o = BIG ? (instr[23] ? rem : divq) : 64'hCCCCCCCCCCCCCCCC;
`MODI:		o = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
`LEA:
	begin
		o1 = a[43:0] + b[43:0];
		o = {20'hFFF01,o1[43:0]};
	end
`LB,`LC,`LH,`LW,`SB,`SH:	
	begin
		usa = a + b;
		o = {pb[50:0],BASE_SHIFT} + usa;
	end
`PUSHC:
	begin
		usa = a - 4'd8;
		o = {pb[50:0],BASE_SHIFT} + usa;
	end
`SWC,`CAS,`CACHE:
	begin
		usa = a + b;
		o = {pb[50:0],BASE_SHIFT} + usa;
	end
`LV,`SV:  
	begin
		usa = a + b + {ven,3'b0};
		o = {pb[50:0],BASE_SHIFT} + usa;
	end
`CSRRW:     
	case(instr[27:18])
	10'h044:	o = BIG ? (csr | {39'd0,thrd,24'h0}) : 64'hDDDDDDDDDDDDDDDD;
	default:	o = BIG ? csr : 64'hDDDDDDDDDDDDDDDD;
	endcase
`BITFIELD:  o = BIG ? bfout : 64'hCCCCCCCCCCCCCCCC;
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
case(instr[`INSTRUCTION_OP])
`R2:
	if (instr[`INSTRUCTION_L2]==2'b01)
		case(instr[47:42])
		`ADD,`SUB,
		`AND,`OR,`XOR,`NAND,`NOR,`XNOR,
		`SHIFTR:
			case(instr[41:36])
			`R1:
				case(instr[22:18])
				`COM:	addro[63:0] = ~shift8;
				`NOT:	addro[63:0] = ~|shift8;
				`NEG:	addro[63:0] = -shift8;
				default:	addro[63:0] = 64'hDCDCDCDCDCDCDCDC;
				endcase
			`ADD:	addro[63:0] = shift8 + c;
			`SUB:	addro[63:0] = shift8 - c;
			`AND:	addro[63:0] = shift8 & c;
			`OR:	addro[63:0] = shift8 | c;
			`XOR:	addro[63:0] = shift8 ^ c;
			default:	addro[63:0] = 64'hDCDCDCDCDCDCDCDC;
			endcase
		default:	addro[63:0] = 64'hDCDCDCDCDCDCDCDC;
		endcase
	else
	   addro = 64'hCCCCCCCCCCCCCCCE;
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
		char,char_para:	done <= mult_done160;
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
		char,char_para:	idle <= mult_idle160;
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
case(instr[`INSTRUCTION_OP])
`R2:
    case(instr[`INSTRUCTION_S2])
    `ADD:   exc <= (fnOverflow(0,a[63],b[63],o[63]) & excen[0] & instr[24]) ? `FLT_OFL : `FLT_NONE;
    `SUB:   exc <= (fnOverflow(1,a[63],b[63],o[63]) & excen[1] & instr[24]) ? `FLT_OFL : `FLT_NONE;
//    `ASL,`ASLI:     exc <= (BIG & aslo & excen[2]) ? `FLT_OFL : `FLT_NONE;
    `MUL,`MULSU:    exc <= prod[63] ? (prod[127:64] != 64'hFFFFFFFFFFFFFFFF && excen[3] ? `FLT_OFL : `FLT_NONE ):
                           (prod[127:64] != 64'd0 && excen[3] ? `FLT_OFL : `FLT_NONE);
    `FXMUL:     exc <= prod[95] ? (prod[127:96] != 32'hFFFFFFFF && excen[3] ? `FLT_OFL : `FLT_NONE ):
                           (prod[127:96] != 32'd0 && excen[3] ? `FLT_OFL : `FLT_NONE);
    `MULU:      exc <= prod[127:64] != 64'd0 && excen[3] ? `FLT_OFL : `FLT_NONE;
    `DIV,`DIVSU,`DIVU: exc <= BIG && excen[4] & divByZero ? `FLT_DBZ : `FLT_NONE;
    `MOD,`MODSU,`MODU: exc <= BIG && excen[4] & divByZero ? `FLT_DBZ : `FLT_NONE;
    default:    exc <= `FLT_NONE;
    endcase
`MULI:    exc <= prod[63] ? (prod[127:64] != 64'hFFFFFFFFFFFFFFFF & excen[3] ? `FLT_OFL : `FLT_NONE):
                                    (prod[127:64] != 64'd0 & excen[3] ? `FLT_OFL : `FLT_NONE);
`DIVI: exc <= BIG & excen[4] & divByZero & instr[27] ? `FLT_DBZ : `FLT_NONE;
`MODI: exc <= BIG & excen[4] & divByZero & instr[27] ? `FLT_DBZ : `FLT_NONE;
`CSRRW:	exc <= (instr[27:21]==7'b0011011) ? `FLT_SEG : `FLT_NONE;
`MEMNDX:
	begin
`ifdef SUPPORT_BBMS
		if ((Ra[4:0]==5'd30 || Ra[4:0]==5'd31) && (usa < {sbl[50:0],13'd0} || usa > {sbu[50:0],13'h1FF8}) && dl!=2'b00)
			exc <= `FLT_STK;
		else if (usa > {sbu[50:0],13'h1FFF} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {sbl[50:0],13'h0000} && usa > {dbu[50:0],13'h1fff} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa > {en[50:0],13'h1fff} && usa < {dbl[50:0],13'd0} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {ro[50:0],13'd0} && store && dl!=2'b00)
			exc <= `FLT_WRV;
		else
`endif
		begin
			if (instr[7:6]==2'b10) begin
				if (instr[31])
					case({instr[31:28],instr[17:16]})
					`PUSH:		exc <= |o[2:0] ? `FLT_ALN : `FLT_NONE;
			    default:	exc <= `FLT_UNIMP;
					endcase
				else
					exc <= `FLT_UNIMP;
			end
			else if (instr[7:6]==2'b00) begin
				if (!instr[31]) begin
					if (BIG) begin
						case({instr[31:28],instr[22:21]})
						`LBX,`LBUX,`LVBX,`LVBUX:	exc <= `FLT_NONE;
				    `LCX,`LCUX,`LVCX,`LVCUX:	exc <=  o[  0] ? `FLT_ALN : `FLT_NONE;
				    `LVHX,`LVHUX,`LHX,`LHUX:	exc <= |o[1:0] ? `FLT_ALN : `FLT_NONE;
				    `LWX,`LVWX,`LWRX,
						`CACHEX,`LVX:							exc <= |o[2:0] ? `FLT_ALN : `FLT_NONE;
				    `LVX,`SVX,`LVWS,`SVWS:		exc <= |o[2:0] ? `FLT_ALN : `FLT_NONE;
				    default:	exc <= `FLT_UNIMP;
						endcase
					end
					else
						exc <= `FLT_UNIMP;
				end
				else begin
					if (BIG) begin
						case({instr[31:28],instr[17:16]})
						`PUSH:	exc <= |o[2:0] ? `FLT_ALN : `FLT_NONE;
						`SBX:		exc <= `FLT_NONE;
				    `SCX:		exc <=  o[  0] ? `FLT_ALN : `FLT_NONE;
				    `SHX:		exc <= |o[1:0] ? `FLT_ALN : `FLT_NONE;
				    `SWX,`SWCX:	exc <= |o[2:0] ? `FLT_ALN : `FLT_NONE;
				    `SVX:  	exc <= |o[2:0] ? `FLT_ALN : `FLT_NONE;
				    `SVWS:	exc <= |o[2:0] ? `FLT_ALN : `FLT_NONE;
				    default:	exc <= `FLT_UNIMP;
						endcase
					end
					else
						exc <= `FLT_UNIMP;
				end
			end
			else
				exc <= `FLT_UNIMP;
		end
	end
`SB:	// SC
	begin
`ifdef SUPPORT_BBMS
		if ((Ra[4:0]==5'd30 || Ra[4:0]==5'd31) && (usa < {sbl[50:0],13'd0} || usa > {sbu[50:0],13'h1FF8}) && dl!=2'b00)
			exc <= `FLT_STK;
		else if (usa > {sbu[50:0],13'h1FFF} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {sbl[50:0],13'h0000} && usa > {dbu[50:0],13'h1fff} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa > {en[50:0],13'h1fff} && usa < {dbl[50:0],13'd0} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {ro[50:0],13'd0} && store && dl!=2'b00)
			exc <= `FLT_WRV;
`endif
		if (instr[23])	// SC
			if (o[2:0]==3'd7)
				exc <= `FLT_ALN;
	end
`SH:	// SW
	begin
`ifdef SUPPORT_BBMS
		if ((Ra[4:0]==5'd30 || Ra[4:0]==5'd31) && (usa < {sbl[50:0],13'd0} || usa > {sbu[50:0],13'h1FF8}) && dl!=2'b00)
			exc <= `FLT_STK;
		else if (usa > {sbu[50:0],13'h1FFF} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {sbl[50:0],13'h0000} && usa > {dbu[50:0],13'h1fff} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa > {en[50:0],13'h1fff} && usa < {dbl[50:0],13'd0} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {ro[50:0],13'd0} && store && dl!=2'b00)
			exc <= `FLT_WRV;
`endif
		if (instr[23]) begin	// SH
			if (o[2:0] != 3'd0)
				exc <= `FLT_ALN;
		end
		else
			if (o[2:0] >= 3'd5)
				exc <= `FLT_ALN;
	end
`ifdef SUPPORT_BBMS
`LB:
	begin
		if ((Ra[4:0]==5'd30 || Ra[4:0]==5'd31) && (usa < {sbl[50:0],13'd0} || usa > {sbu[50:0],13'h1FF8}) && dl!=2'b00)
			exc <= `FLT_STK;
		else if (usa > {sbu[50:0],13'h1FFF} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {sbl[50:0],13'h0000} && usa > {dbu[50:0],13'h1fff} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa > {en[50:0],13'h1fff} && usa < {dbl[50:0],13'd0} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {ro[50:0],13'd0} && store && dl!=2'b00)
			exc <= `FLT_WRV;
	end
`endif
`LC:	// LCU
	begin
`ifdef SUPPORT_BBMS
		if ((Ra[4:0]==5'd30 || Ra[4:0]==5'd31) && (usa < {sbl[50:0],13'd0} || usa > {sbu[50:0],13'h1FF8}) && dl!=2'b00)
			exc <= `FLT_STK;
		else if (usa > {sbu[50:0],13'h1FFF} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {sbl[50:0],13'h0000} && usa > {dbu[50:0],13'h1fff} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa > {en[50:0],13'h1fff} && usa < {dbl[50:0],13'd0} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {ro[50:0],13'd0} && store && dl!=2'b00)
			exc <= `FLT_WRV;
`endif
		if (o[2:0]==3'd7)
			exc <= `FLT_ALN;
	end
`LH:	// LHU
	begin
`ifdef SUPPORT_BBMS
		if ((Ra[4:0]==5'd30 || Ra[4:0]==5'd31) && (usa < {sbl[50:0],13'd0} || usa > {sbu[50:0],13'h1FF8}) && dl!=2'b00)
			exc <= `FLT_STK;
		else if (usa > {sbu[50:0],13'h1FFF} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {sbl[50:0],13'h0000} && usa > {dbu[50:0],13'h1fff} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa > {en[50:0],13'h1fff} && usa < {dbl[50:0],13'd0} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {ro[50:0],13'd0} && store && dl!=2'b00)
			exc <= `FLT_WRV;
`endif
		if (o[2:0] >= 3'd5)
			exc <= `FLT_ALN;
	end
`LW:	// LWR
	begin
`ifdef SUPPORT_BBMS
		if ((Ra[4:0]==5'd30 || Ra[4:0]==5'd31) && (usa < {sbl[50:0],13'd0} || usa > {sbu[50:0],13'h1FF8}) && dl!=2'b00)
			exc <= `FLT_STK;
		else if (usa > {sbu[50:0],13'h1FFF} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {sbl[50:0],13'h0000} && usa > {dbu[50:0],13'h1fff} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa > {en[50:0],13'h1fff} && usa < {dbl[50:0],13'd0} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {ro[50:0],13'd0} && store && dl!=2'b00)
			exc <= `FLT_WRV;
`endif
		if (o[2:0]!=3'd0)
			exc <= `FLT_ALN;
	end
`SWC,`CAS,`CACHE:
	begin
`ifdef SUPPORT_BBMS
		if ((Ra[4:0]==5'd30 || Ra[4:0]==5'd31) && (usa < {sbl[50:0],13'd0} || usa > {sbu[50:0],13'h1FF8}) && dl!=2'b00)
			exc <= `FLT_STK;
		else if (usa > {sbu[50:0],13'h1FFF} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {sbl[50:0],13'h0000} && usa > {dbu[50:0],13'h1fff} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa > {en[50:0],13'h1fff} && usa < {dbl[50:0],13'd0} && dl!=2'b00)
			exc <= `FLT_SGB;
		else if (usa < {ro[50:0],13'd0} && store && dl!=2'b00)
			exc <= `FLT_WRV;
		else
`endif
			exc <= o[2:0]!=3'b0 ? `FLT_ALN : `FLT_NONE;
	end
default:    exc <= `FLT_NONE;
endcase
end

reg [63:0] aa, bb;

always @(posedge clk)
begin
	aa <= shfto;
	bb <= c;
end

task tskSeq;
input [47:0] instr;
input [2:0] sz;
input [63:0] a;
input [63:0] b;
output [63:0] o;
begin
`ifdef SIMD
	case(sz[2:0])
  3'd0:   o[63:0] = $signed(a[7:0]) == $signed(b[7:0]);
  3'd1:   o[63:0] = $signed(a[15:0]) == $signed(b[15:0]);
  3'd2:   o[63:0] = $signed(a[31:0]) == $signed(b[31:0]);
  3'd3:   o[63:0] = $signed(a) == $signed(b);
  3'd4:		o[63:0] = {
					        	7'h0,$signed(a[63:56]) == $signed(b[63:56]),
					        	7'h0,$signed(a[55:48]) == $signed(b[55:48]),
					        	7'h0,$signed(a[47:40]) == $signed(b[47:40]),
					        	7'h0,$signed(a[39:32]) == $signed(b[39:32]),
					        	7'h0,$signed(a[31:24]) == $signed(b[31:24]),
					        	7'h0,$signed(a[23:16]) == $signed(b[23:16]),
					        	7'h0,$signed(a[15:8]) == $signed(b[15:8]),
					        	7'h0,$signed(a[7:0]) == $signed(b[7:0])
						        };
  3'd5:		o[63:0] = {
					        	15'h0,$signed(a[63:48]) == $signed(b[63:48]),
					        	15'h0,$signed(a[47:32]) == $signed(b[47:32]),
					        	15'h0,$signed(a[31:16]) == $signed(b[31:16]),
					        	15'h0,$signed(a[15:0]) == $signed(b[15:0])
						        };
  3'd6:		o[63:0] = {
					        	31'h0,$signed(a[63:32]) == $signed(b[63:32]),
					        	31'h0,$signed(a[31:0]) == $signed(b[31:0])
						        };
	3'd7:		o[63:0] = $signed(a[63:0]) == $signed(b[63:0]);
  endcase
`else
	o = $signed(a) == $signed(b);
`endif
end
endtask

task tskSlt;
input [47:0] instr;
input [2:0] sz;
input [63:0] a;
input [63:0] b;
output [63:0] o;
begin
`ifdef SIMD
	case(sz[2:0])
  3'd0:   o[63:0] = $signed(a[7:0]) < $signed(b[7:0]);
  3'd1:   o[63:0] = $signed(a[15:0]) < $signed(b[15:0]);
  3'd2:   o[63:0] = $signed(a[31:0]) < $signed(b[31:0]);
  3'd3:   o[63:0] = $signed(a) < $signed(b);
  3'd4:		o[63:0] = {
					        	7'h0,$signed(a[63:56]) < $signed(b[63:56]),
					        	7'h0,$signed(a[55:48]) < $signed(b[55:48]),
					        	7'h0,$signed(a[47:40]) < $signed(b[47:40]),
					        	7'h0,$signed(a[39:32]) < $signed(b[39:32]),
					        	7'h0,$signed(a[31:24]) < $signed(b[31:24]),
					        	7'h0,$signed(a[23:16]) < $signed(b[23:16]),
					        	7'h0,$signed(a[15:8]) < $signed(b[15:8]),
					        	7'h0,$signed(a[7:0]) < $signed(b[7:0])
						        };
  3'd5:		o[63:0] = {
					        	15'h0,$signed(a[63:48]) < $signed(b[63:48]),
					        	15'h0,$signed(a[47:32]) < $signed(b[47:32]),
					        	15'h0,$signed(a[31:16]) < $signed(b[31:16]),
					        	15'h0,$signed(a[15:0]) < $signed(b[15:0])
						        };
  3'd6:		o[63:0] = {
					        	31'h0,$signed(a[63:32]) < $signed(b[63:32]),
					        	31'h0,$signed(a[31:0]) < $signed(b[31:0])
						        };
	3'd7:		o[63:0] = $signed(a[63:0]) < $signed(b[63:0]);
  endcase
`else
	o[63:0] = $signed(a[63:0]) < $signed(b[63:0]);
`endif
end
endtask

task tskSle;
input [47:0] instr;
input [2:0] sz;
input [63:0] a;
input [63:0] b;
output [63:0] o;
begin
`ifdef SIMD
	case(sz[2:0])
  3'd0:   o[63:0] = $signed(a[7:0]) <= $signed(b[7:0]);
  3'd1:   o[63:0] = $signed(a[15:0]) <= $signed(b[15:0]);
  3'd2:   o[63:0] = $signed(a[31:0]) <= $signed(b[31:0]);
  3'd3:   o[63:0] = $signed(a) <= $signed(b);
  3'd4:		o[63:0] = {
					        	7'h0,$signed(a[63:56]) <= $signed(b[63:56]),
					        	7'h0,$signed(a[55:48]) <= $signed(b[55:48]),
					        	7'h0,$signed(a[47:40]) <= $signed(b[47:40]),
					        	7'h0,$signed(a[39:32]) <= $signed(b[39:32]),
					        	7'h0,$signed(a[31:24]) <= $signed(b[31:24]),
					        	7'h0,$signed(a[23:16]) <= $signed(b[23:16]),
					        	7'h0,$signed(a[15:8]) <= $signed(b[15:8]),
					        	7'h0,$signed(a[7:0]) <= $signed(b[7:0])
						        };
  3'd5:		o[63:0] = {
					        	15'h0,$signed(a[63:48]) <= $signed(b[63:48]),
					        	15'h0,$signed(a[47:32]) <= $signed(b[47:32]),
					        	15'h0,$signed(a[31:16]) <= $signed(b[31:16]),
					        	15'h0,$signed(a[15:0]) <= $signed(b[15:0])
						        };
  3'd6:		o[63:0] = {
					        	31'h0,$signed(a[63:32]) <= $signed(b[63:32]),
					        	31'h0,$signed(a[31:0]) <= $signed(b[31:0])
						        };
	3'd7:		o[63:0] = $signed(a[63:0]) <= $signed(b[63:0]);
  endcase
`else
	o = $signed(a) <= $signed(b);
`endif
end
endtask

task tskSltu;
input [47:0] instr;
input [2:0] sz;
input [63:0] a;
input [63:0] b;
output [63:0] o;
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
	3'd7,3'd3:		o = (a[63:0]) < (b[63:0]);
  endcase
`else
	o = (a) < (b);
`endif
end
endtask

task tskSleu;
input [47:0] instr;
input [2:0] sz;
input [63:0] a;
input [63:0] b;
output [63:0] o;
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
	3'd7,3'd3:		o = (a[63:0]) <= (b[63:0]);
  endcase
`else
	o[63:0] = (a[63:0]) <= (b[63:0]);
`endif
end
endtask

endmodule
