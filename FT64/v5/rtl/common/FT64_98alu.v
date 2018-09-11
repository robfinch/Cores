// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64alu.v
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

module FT64_alu(rst, clk, ld, abort, instr, a, b, c, pc, tgt, tgt2, ven, vm, sbl, sbu,
    csr, o, ob, done, idle, excen, exc, thrd, ptrmask, state, mem, shift48, pcr, pcr2);
parameter DBW = 64;
parameter BIG = 1'b1;
parameter SUP_VECTOR = 1;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter PTR = 20'hFFF01;
input rst;
input clk;
input ld;
input abort;
input [47:0] instr;
input [63:0] a;
input [63:0] b;
input [63:0] c;
input [31:0] pc;
input [11:0] tgt;
input [7:0] tgt2;
input [5:0] ven;
input [15:0] vm;
input [31:0] sbl;
input [31:0] sbu;
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
input shift48;
input [63:0] pcr;
input [63:0] pcr2;

integer n;

wire [5:0] mapno = pcr[5:0];
wire [5:0] akey = pcr[13:8];
reg adrDone, adrIdle;
reg [63:0] addro;
reg [63:0] addr8;
//reg [65535:0] tmem = 65536'd0;
wire [9:0] tmemaddr = pcr2[mapno] ? addr8[28:19] : addr8[22:13];

wire tbit = 1'b0;//|addr8[31:29] ? 1'b0 : tmem[{mapno,tmemaddr[9:0]}];
//always @(posedge clk)
//	if (instr[5:0]==`R2 && instr[31:26]==6'h01 && instr[23:18]==5'h1D)
//		tmem[{akey,a[9:0]}] <= b[0];

wire [7:0] a8 = a[7:0];
wire [15:0] a16 = a[15:0];
wire [31:0] a32 = a[31:0];
wire [7:0] b8 = b[7:0];
wire [15:0] b16 = b[15:0];
wire [31:0] b32 = b[31:0];
wire [63:0] orb = instr[6] ? {34'd0,b[29:0]} : {50'd0,b[13:0]};
wire [63:0] andb = instr[6] ? {34'h3FFFFFFFF,b[29:0]} : {50'h3FFFFFFFFFFFF,b[13:0]};

wire [21:0] qimm = instr[39:18];
wire [63:0] imm = {{45{instr[39]}},instr[39:21]};
wire [DBW-1:0] divq, rem;
wire divByZero;
wire [15:0] prod8;
wire [31:0] prod16;
wire [63:0] prod32;
wire [DBW*2-1:0] prod;
wire mult_done8, mult_idle8, div_done8, div_idle8;
wire mult_done16, mult_idle16, div_done16, div_idle16;
wire mult_done32, mult_idle32, div_done32, div_idle32;
wire mult_done, mult_idle, div_done, div_idle;
wire aslo;
wire [6:0] clzo,cloo,cpopo;
wire [63:0] shftho;
reg [34:0] addr9;

function IsMul;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`IVECTOR:
    case(isn[`INSTRUCTION_S2])
    `VMUL,`VMULS:   IsMul = TRUE;
    default:    IsMul = FALSE;
    endcase
`RR:
    case(isn[`INSTRUCTION_S2])
    `MULU,`MULSU,`MUL: IsMul = TRUE;
    default:    IsMul = FALSE;
    endcase
`MULUI,`MULSUI,`MULI:  IsMul = TRUE;
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
`RR:
    case(isn[`INSTRUCTION_S2])
    `DIVMODU,`DIVMODSU,`DIVMOD: IsDivmod = TRUE;
    default:    IsDivmod = FALSE;
    endcase
`DIVUI,`DIVSUI,`DIVI,`MODUI,`MODSUI,`MODI:  IsDivmod = TRUE;
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
`RR:
    case(isn[`INSTRUCTION_S2])
    `MUL,`DIVMOD:   IsSgn = TRUE;
    default:    IsSgn = FALSE;
    endcase
`MULI,`DIVI,`MODI:    IsSgn = TRUE;
default:    IsSgn = FALSE;
endcase
endfunction

function IsSgnus;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`RR:
    case(isn[`INSTRUCTION_S2])
    `MULSU,`DIVMODSU:   IsSgnus = TRUE;
    default:    IsSgnus = FALSE;
    endcase
`MULSUI,`DIVSUI,`MODSUI:    IsSgnus = TRUE;
default:    IsSgnus = FALSE;
endcase
endfunction

function IsShiftAndOp;
input [47:0] isn;
IsShiftAndOp = FALSE;
endfunction

wire [2:0] sz =
    instr[`INSTRUCTION_OP]==`IVECTOR ? 2'd3 : 
    instr[`INSTRUCTION_S2]==`R1 ? instr[18:16] : instr[23:21];

wire [63:0] bfout,shfto;
wire [63:0] shftob;
wire [63:0] shftco;

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
	.ld(ld && IsMul(instr)),
	.abort(abort),
	.sgn(IsSgn(instr)),
	.sgnus(IsSgnus(instr)),
	.a(a),
	.b(b),
	.o(prod),
	.done(mult_done),
	.idle(mult_idle)
);

FT64_divider #(DBW) udiv1
(
	.rst(rst),
	.clk(clk),
	.ld(ld && IsDivmod(instr)),
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

FT64_shift ushft1
(
    .instr(instr),
    .a(a),
    .b(b),
    .res(shfto),
    .ov(aslo)
);

FT64_shifth ushfthL
(
    .instr(instr),
    .a(a[31:0]),
    .b(b[31:0]),
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
    .b(b[15:0]),
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
    .b(b[7:0]),
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
wire [63:0] redor32 = {63'd0,|a[31:0]};
wire [63:0] redor16 = {63'd0,|a[15:0]};
wire [63:0] redor8 = {63'd0,|a[7:0]};
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
				3'd0:	addr8 = {{56{shftob[7]}},shftob[7:0]};
				3'd1:	addr8 = {{48{shftob[15]}},shftco[15:0]};
				3'd2:	addr8 = {{32{shftho[31]}},shftho[31:0]};
				3'd3,3'd7:	addr8 = shfto;
				3'd4:	addr8 = shftob;
				3'd5:	addr8 = shftco;
				3'd6:	addr8 = shftho;
				endcase
			`SHL,`SHR:
				case(instr[32:30])	// size
				3'd0:	addr8 = {56'd0,shftob[7:0]};
				3'd1:	addr8 = {48'd0,shftco[15:0]};
				3'd2:	addr8 = {32'd0,shftho[31:0]};
				3'd3,3'd7:	addr8 = shfto;
				3'd4:	addr8 = shftob;
				3'd5:	addr8 = shftco;
				3'd6:	addr8 = shftho;
				endcase
			default:	o[63:0] = 64'hDCDCDCDCDCDCDCDC;
			endcase
			case(instr[35:33])
			`ASL,`ASR,`SHL,`SHR,`ROL,`ROR:
				o[63:0] = addr9;
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
			endcase
		endcase
	else
	    case(instr[`INSTRUCTION_S2])
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
	        `ABS:       case(sz)
	                    2'd0:   o[63:0] = BIG ? (a[7] ? -a[7:0] : a[7:0]) : 64'hCCCCCCCCCCCCCCCC;
	                    2'd1:   o[63:0] = BIG ? (a[15] ? -a[15:0] : a[15:0]) : 64'hCCCCCCCCCCCCCCCC;
	                    2'd2:   o[63:0] = BIG ? (a[31] ? -a[31:0] : a[31:0]) : 64'hCCCCCCCCCCCCCCCC;
	                    2'd3:   o[63:0] = BIG ? (a[63] ? -a : a) : 64'hCCCCCCCCCCCCCCCC;
	                    endcase
	        `NOT:   case(sz)
	                2'd0:   o[63:0] = ~|a[7:0];
	                2'd1:   o[63:0] = ~|a[15:0];
	                2'd2:   o[63:0] = ~|a[31:0];
	                2'd3:   o[63:0] = ~|a[63:0];
	                endcase
	        `REDOR: case(sz)
	                2'd0:   o[63:0] = redor8;
	                2'd1:   o[63:0] = redor16;
	                2'd2:   o[63:0] = redor32;
	                2'd3:   o[63:0] = redor64;
	                endcase
	        `ZXH:		o[63:0] = {32'd0,a[31:0]};
	        `ZXC:		o[63:0] = {48'd0,a[15:0]};
	        `ZXB:		o[63:0] = {56'd0,a[7:0]};
	        `SXH:		o[63:0] = {{32{a[31]}},a[31:0]};
	        `SXC:		o[63:0] = {{48{a[15]}},a[15:0]};
	        `SXB:		o[63:0] = {{56{a[7]}},a[7:0]};
	        `ISPTR:		o[63:0] = a[63:44]==20'hFFF01;
	        `ISCOUNT:	o[63:0] = a[63:44]==20'hFFF02;
	        `ISNULL:	o[63:0] = a==64'd0 || a==64'hFFF0100000000000;
//	        5'h1C:		o[63:0] = tmem[a[9:0]];
	        default:    o = 64'hDEADDEADDEADDEAD;
	        endcase
	    `BMM:		o[63:0] = BIG ? bmmo : 64'hCCCCCCCCCCCCCCCC;
	    `SHIFT31:   o[63:0] = BIG ? shfto : 64'hCCCCCCCCCCCCCCCC;
	    `SHIFT63:   o[63:0] = BIG ? shfto : 64'hCCCCCCCCCCCCCCCC;
	    `SHIFTR:    o[63:0] = BIG ? shfto : 64'hCCCCCCCCCCCCCCCC;
	    `ADD:   case(sz)
	    		3'd0,3'd4:
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
	    		3'd1,3'd5:
	    			begin
	    				o[15:0] = a[15:0] + b[15:0];
	    				o[31:16] = a[31:16] + b[31:16];
	    				o[47:32] = a[47:32] + b[47:32];
	    				o[63:48] = a[63:48] + b[63:48];
	    			end
	    		3'd2,3'd6:
	    			begin
	    				o[31:0] = a[31:0] + b[31:0];
	    				o[63:32] = a[63:32] + b[63:32];
	    			end
	            3'd3,3'd7:
	            	begin
	            		o[63:0] = a + b;
	            	end
	            endcase
	    `SUB:   case(sz)
	    		3'd0,3'd4:
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
	    		3'd1,3'd5:
	    			begin
	    				o[15:0] = a[15:0] - b[15:0];
	    				o[31:16] = a[31:16] - b[31:16];
	    				o[47:32] = a[47:32] - b[47:32];
	    				o[63:48] = a[63:48] - b[63:48];
	    			end
	    		3'd2,3'd6:
	    			begin
	    				o[31:0] = a[31:0] - b[31:0];
	    				o[63:32] = a[63:32] - b[63:32];
	    			end
	            3'd3,3'd7:
	            	begin
	            		o[63:0] = a - b;
	            	end
	            endcase
	    `CMP:   tskCmp(instr,2'd3,a,b,o);
	    `CMPU:  tskCmpu(instr,2'd3,a,b,o);
	    `AND:   o[63:0] = and64;
	    `OR:    o[63:0] = or64;
	    `XOR:   o[63:0] = xor64;
	    `NAND:  o[63:0] = ~and64;
	    `NOR:   o[63:0] = ~or64;
	    `XNOR:  o[63:0] = ~xor64;
	    `SEI:       o[63:0] = a | instr[21:16];
	    `RTI:       o[63:0] = a | instr[21:16];
	    `CMOVEZ:    begin
	    			o[63:0] = (a==64'd0) ? b : c;
	    			end
	    `CMOVNZ:	if (instr[41])
	    				o[63:0] = (a!=64'd0) ? b : {{48{instr[38]}},instr[38:28],instr[22:18]};
	    			else
	    				o[63:0] = (a!=64'd0) ? b : c;
	    `MUX:       for (n = 0; n < 64; n = n + 1)
	                    o[n] <= a[n] ? b[n] : c[n];
	    `MULU:      o[63:0] = instr[25:24]==2'b00 ? prod[DBW-1:0] : prod[DBW*2-1:DBW];
	    `MULSU:     o[63:0] = instr[25:24]==2'b00 ? prod[DBW-1:0] : prod[DBW*2-1:DBW];
	    `MUL:       o[63:0] = instr[25:24]==2'b00 ? prod[DBW-1:0] : prod[DBW*2-1:DBW];
	    `DIVMODU:   o[63:0] = BIG ? (instr[25:24]==2'b00 ? divq : rem) : 64'hCCCCCCCCCCCCCCCC;
	    `DIVMODSU:  o[63:0] = BIG ? (instr[25:24]==2'b00 ? divq : rem) : 64'hCCCCCCCCCCCCCCCC;
	    `DIVMOD:    o[63:0] = BIG ? (instr[25:24]==2'b00 ? divq : rem) : 64'hCCCCCCCCCCCCCCCC;
		`LEAX:		begin
					o[63:0] = BIG ? a + (b << instr[22:21]) : 64'hCCCCCCCCEEEEEEEE;
					o[63:44] = PTR;
					end
		`LTX,`STX:	if (BIG) begin
						addr8 = a + (b << instr[22:21]);
						o[63:0] = addro;
					end
					else
						o[63:0] = 64'hCCCCCCCCEEEEEEEE;
		`LVX,
	    `LBX,`LBUX,`LCX,`LCUX,
	    `LHX,`LHUX,`LWX,`LWRX,`SBX,`SCX,`SHX,`SWX,`SWCX:
					if (BIG) begin
						addr8 = a + (b << instr[22:21]);
						o[63:0] = addro;
					end
					else
						o[63:0] = 64'hCCCCCCCCEEEEEEEE;
	    `LVX,`SVX:  if (BIG) begin
	    				addr8 = a + (b << 2'd3);
						o[63:0] = addro;
	    			end
	    			else
	    				o[63:0] = 64'hCCCCCCCCCCCCCCCC;
	    `LVWS,`SVWS:
	    			if (BIG) begin    
	    				addr8 = a + ({b * ven,3'b000});
						o[63:0] = addro;
	    			end
	    			else
	    				o[63:0] = 64'hCCCCCCCCCCCCCCCC;
	    `MIN:       case(sz)
	    			3'd0,3'd4:
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
		    		3'd1,3'd5:
		    			begin
		    			o[15:0] = BIG ? ($signed(a[15:0]) < $signed(b[15:0]) ? a[15:0] : b[15:0]) : 64'hCCCCCCCCCCCCCCCC;
		    			o[32:16] = BIG ? ($signed(a[32:16]) < $signed(b[32:16]) ? a[32:16] : b[32:16]) : 64'hCCCCCCCCCCCCCCCC;
		    			o[47:32] = BIG ? ($signed(a[47:32]) < $signed(b[47:32]) ? a[47:32] : b[47:32]) : 64'hCCCCCCCCCCCCCCCC;
		    			o[63:48] = BIG ? ($signed(a[63:48]) < $signed(b[63:48]) ? a[63:48] : b[63:48]) : 64'hCCCCCCCCCCCCCCCC;
		    			end
		    		3'd2,3'd6:
		    			begin
		    			o[31:0] = BIG ? ($signed(a[31:0]) < $signed(b[31:0]) ? a[31:0] : b[31:0]) : 64'hCCCCCCCCCCCCCCCC;
		    			o[63:32] = BIG ? ($signed(a[63:32]) < $signed(b[63:32]) ? a[63:32] : b[63:32]) : 64'hCCCCCCCCCCCCCCCC;
		    			end
					3'd3,3'd7:
						begin    			
	    				o[63:0] = BIG ? ($signed(a) < $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
	    				end
	    			endcase
	    `MAX:       case(sz)
	    			3'd0,3'd4:
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
		    		3'd1,3'd5:
		    			begin
		    			o[15:0] = BIG ? ($signed(a[15:0]) > $signed(b[15:0]) ? a[15:0] : b[15:0]) : 64'hCCCCCCCCCCCCCCCC;
		    			o[32:16] = BIG ? ($signed(a[32:16]) > $signed(b[32:16]) ? a[32:16] : b[32:16]) : 64'hCCCCCCCCCCCCCCCC;
		    			o[47:32] = BIG ? ($signed(a[47:32]) > $signed(b[47:32]) ? a[47:32] : b[47:32]) : 64'hCCCCCCCCCCCCCCCC;
		    			o[63:48] = BIG ? ($signed(a[63:48]) > $signed(b[63:48]) ? a[63:48] : b[63:48]) : 64'hCCCCCCCCCCCCCCCC;
		    			end
		    		3'd2,3'd6:
		    			begin
		    			o[31:0] = BIG ? ($signed(a[31:0]) > $signed(b[31:0]) ? a[31:0] : b[31:0]) : 64'hCCCCCCCCCCCCCCCC;
		    			o[63:32] = BIG ? ($signed(a[63:32]) > $signed(b[63:32]) ? a[63:32] : b[63:32]) : 64'hCCCCCCCCCCCCCCCC;
		    			end
					3'd3,3'd7: 
						begin   			
	    				o[63:0] = BIG ? ($signed(a) > $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
	    				end
	    			endcase
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
	    default:    o[63:0] = 64'hDEADDEADDEADDEAD;
	    endcase
`AUIPC:
 	begin
 		if (instr[7:6]==2'b01)
 			o[63:0] = pc + {instr[47:13],30'd0};
 		else
 			o[63:0] = pc + {{15{instr[31]}},instr[31:13],30'd0};
 		o[29:0] = 30'd0;
// 		o[63:44] = PTR;
 	end
`LUI:
 	begin
 		if (instr[7:6]==2'b01)
 			o[63:0] = {instr[47:13],30'd0};
 		else
 			o[63:0] = {{15{instr[31]}},instr[31:13],30'd0};
	end
`ADDI:	o[63:0] = a + b;
`CMPI:	o[63:0] = $signed(a) < $signed(b) ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
`CMPUI: o[63:0] = a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
`ANDI:	o[63:0] = a & andb;
`ORI:	o[63:0] = a | orb;
`XORI:	o[63:0] = a ^ orb;
`SccI:
 		if (instr[7:6]==2'b00)
            case(instr[`INSTRUCTION_S2])
            `SEQ:   o[63:0] = a == sxb10;
            `SNE:   o[63:0] = a != sxb10;
            `SLT:   o[63:0] = $signed(a) < $signed(sxb10);
            `SGE:   o[63:0] = $signed(a) >= $signed(sxb10);
            `SLE:   o[63:0] = $signed(a) <= $signed(sxb10);
            `SGT:   o[63:0] = $signed(a) > $signed(sxb10);
            `SLTU:  o[63:0] = a < zxb10;
            `SGEU:  o[63:0] = a >= zxb10;
            `SLEU:  o[63:0] = a <= zxb10;
            `SGTU:  o[63:0] = a > zxb10;
            `ADDPI: o[63:0] = a + zxb10;
            default:    o[63:0] = 64'hDEADDEADDEADDEAD;
            endcase
       else
            case(instr[`INSTRUCTION_S2])
            `SEQ:   o[63:0] = a == sxb26;
            `SNE:   o[63:0] = a != sxb26;
            `SLT:   o[63:0] = $signed(a) < $signed(sxb26);
            `SGE:   o[63:0] = $signed(a) >= $signed(sxb26);
            `SLE:   o[63:0] = $signed(a) <= $signed(sxb26);
            `SGT:   o[63:0] = $signed(a) > $signed(sxb26);
            `SLTU:  o[63:0] = a < zxb26;
            `SGEU:  o[63:0] = a >= zxb26;
            `SLEU:  o[63:0] = a <= zxb26;
            `SGTU:  o[63:0] = a > zxb26;
            `ADDPI: o[63:0] = a + zxb26;
            default:    o[63:0] = 64'hDEADDEADDEADDEAD;
            endcase
`MULUI:		o[63:0] = prod[DBW-1:0];
`MULSUI:	o[63:0] = prod[DBW-1:0];
`MULI:		o[63:0] = prod[DBW-1:0];
`DIVUI:		o[63:0] = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
`DIVSUI:	o[63:0] = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
`DIVI:		o[63:0] = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
`MODUI:		o[63:0] = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
`MODSUI:	o[63:0] = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
`MODI:		o[63:0] = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
`LT,`ST:
			begin
				addr8 = a + b;
				o[63:0] = addro;
			end
`LB,`LBU,`LC,`LCU,`LH,`LHO,`LHU,`LW,`LWR,
`SB,`SC,`SH,`SW,`SWC,`CAS:
			begin
				addr8 = a + b;
				o[63:0] = addro;
			end
`LVx:		begin
				addr8 = a + (instr[6] ? sxb26 : sxb10);
				o[63:0] = addro;
			end
`LV,`SV:    begin
				addr8 = a + b + {ven,3'b0};
				o[63:0] = addro;
			end
`CSRRW:     case(instr[27:18])
			10'h044:	o[63:0] = BIG ? csr | {thrd,24'h0} : 64'hDDDDDDDDDDDDDDDD;
			default:	o[63:0] = BIG ? csr : 64'hDDDDDDDDDDDDDDDD;
			endcase
`BITFIELD:  o[63:0] = BIG ? bfout : 64'hCCCCCCCCCCCCCCCC;
default:    o[63:0] = 64'hDEADDEADDEADDEAD;
endcase  
end

always @(posedge clk)
	if (ld)
		adrDone <= FALSE;
	else if (mem|shift48)
		adrDone <= TRUE;

always @(posedge clk)
case(instr[`INSTRUCTION_OP])
`R2:
	if (instr[7:6]==2'b01)
		case(instr[47:42])
		`SHIFTR:
			case(instr[41:36])
			`R1:
				case(instr[22:18])
				`COM:	addro[63:0] = ~addr8;
				`NOT:	addro[63:0] = ~|addr8;
				`NEG:	addro[63:0] = -addr8;
				default:	addro[63:0] = 64'hDCDCDCDCDCDCDCDC;
				endcase
			`ADD:	addro[63:0] = addr8 + c;
			`SUB:	addro[63:0] = addr8 - c;
			`AND:	addro[63:0] = addr8 & c;
			`OR:	addro[63:0] = addr8 | c;
			`XOR:	addro[63:0] = addr8 ^ c;
			default:	addro[63:0] = 64'hDCDCDCDCDCDCDCDC;
			endcase
		default:	addro[63:0] = 64'hDCDCDCDCDCDCDCDC;
		endcase
	else
	case(instr[31:26])
	`LTX,`STX:	if (BIG) begin
					addr9 = {addr8[31:6],9'h40} + {addr8[31:6],6'd0};
					addro[63:0] = {addr9[34:6],3'd0};
				end
				else
					addro[63:0] = 64'hCCCCCCCCEEEEEEEE;
	`LVX,
    `LBX,`LBUX,`LCX,`LCUX,
    `LHX,`LHUX,`LWX,`LWRX,`SBX,`SCX,`SHX,`SWX,`SWCX:
				if (BIG) begin
					addr9 = {addr8,3'b0} + (tbit ? addr8 : 32'd0);
					addro[63:0] = addr9[34:3];
				end
				else
					addro[63:0] = 64'hCCCCCCCCEEEEEEEE;
    `LVX,`SVX:  if (BIG) begin
					addr9 = {addr8,3'b0} + (tbit ? addr8 : 32'd0);
					addro[63:0] = addr9[34:3];
    			end
    			else
    				addro[63:0] = 64'hCCCCCCCCCCCCCCCC;
    `LVWS,`SVWS:
    			if (BIG) begin    
					addr9 = {addr8,3'b0} + (tbit ? addr8 : 32'd0);
					addro[63:0] = addr9[34:3];
    			end
    			else
    				addro[63:0] = 64'hCCCCCCCCCCCCCCCC;
	default:	addro = 64'hCCCCCCCCCCCCCCCE;
	endcase
`LB,`LBU,`LC,`LCU,`LH,`LHO,`LHU,`LW,`LWR,
`SB,`SC,`SH,`SW,`SWC,`CAS:
			begin
				addr9 = {addr8,3'b0} + (tbit ? addr8 : 32'd0);
				addro = addr9[34:3];
			end
`LVx:		begin
				addr9 = {addr8,3'b0} + (tbit ? addr8 : 32'd0);
				addro = addr9[34:3];
			end
`LV,`SV:    begin
				addr9 = {addr8,3'b0} + (tbit ? addr8 : 32'd0);
				addro = addr9[34:3];
			end
default:	addro = 64'hCCCCCCCCCCCCCCCE;
endcase

reg sao_done, sao_idle;

// Generate done signal
always @*
begin
    if (IsMul(instr))
        done <= mult_done;
    else if (IsDivmod(instr) & BIG)
        done <= div_done;
    else if (IsShiftAndOp(instr) & BIG)
    	done <= sao_done;
    else if (mem|shift48)
    	done <= adrDone;
    else
        done <= TRUE;
end

// Generate idle signal
always @*
begin
    if (IsMul(instr))
        idle <= mult_idle;
    else if (IsDivmod(instr) & BIG)
        idle <= div_idle;
    else if (IsShiftAndOp(instr) & BIG)
    	idle <= sao_idle;
    else if (mem|shift48)
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
if ((tgt[4:0]==5'd31 || tgt[4:0]==5'd30) && (o[31:0] < sbl || o[31:0] > sbu))
    exc <= `FLT_STK;
else
case(instr[`INSTRUCTION_OP])
`R2:
    case(instr[`INSTRUCTION_S2])
    `ADD:   exc <= (fnOverflow(0,a[63],b[63],o[63]) & excen[0] & instr[24]) ? `FLT_OFL : `FLT_NONE;
    `SUB:   exc <= (fnOverflow(1,a[63],b[63],o[63]) & excen[1] & instr[24]) ? `FLT_OFL : `FLT_NONE;
    `ASL,`ASLI:     exc <= (BIG & aslo & excen[2]) ? `FLT_OFL : `FLT_NONE;
    `MUL,`MULSU:    exc <= prod[63] ? (prod[127:64] != 64'hFFFFFFFFFFFFFFFF && excen[3] ? `FLT_OFL : `FLT_NONE ):
                           (prod[127:64] != 64'd0 && excen[3] ? `FLT_OFL : `FLT_NONE);
    `MULU:      exc <= prod[127:64] != 64'd0 && excen[3] ? `FLT_OFL : `FLT_NONE;
    `DIVMOD,`DIVMODSU,`DIVMODU: exc <= BIG && excen[4] & divByZero ? `FLT_DBZ : `FLT_NONE;
    default:    exc <= `FLT_NONE;
    endcase
`SccI:
    case(instr[`INSTRUCTION_S2])
	`ADDPI:		exc <= (o[63:44]!=20'hFFF01) ? `FLT_OFL : `FLT_NONE;
    default:    exc <= `FLT_NONE;
	endcase
`MULI,`MULSUI:    exc <= prod[63] ? (prod[127:64] != 64'hFFFFFFFFFFFFFFFF & excen[3] ? `FLT_OFL : `FLT_NONE):
                                    (prod[127:64] != 64'd0 & excen[3] ? `FLT_OFL : `FLT_NONE);
`DIVI,`DIVSUI: exc <= BIG & excen[4] & divByZero & instr[27] ? `FLT_DBZ : `FLT_NONE;
`MODI,`MODSUI: exc <= BIG & excen[4] & divByZero & instr[27] ? `FLT_DBZ : `FLT_NONE;
default:    exc <= `FLT_NONE;
endcase
end

reg [63:0] aa, bb;

always @(posedge clk)
begin
	aa <= shfto;
	bb <= c;
end

task tskCmp;
input [47:0] instr;
input [1:0] sz;
input [63:0] a;
input [63:0] b;
output [63:0] o;
begin
	case(instr[25:23])
	3'd0,3'd1:	// CMP
		case(sz[1:0])
        2'd0:   o[63:0] = $signed(a[7:0]) < $signed(b[7:0]) ? 64'hFFFFFFFFFFFFFFFF : a[7:0]==b[7:0] ? 64'd0 : 64'd1;
        2'd1:   o[63:0] = $signed(a[15:0]) < $signed(b[15:0]) ? 64'hFFFFFFFFFFFFFFFF : a[15:0]==b[15:0] ? 64'd0 : 64'd1;
        2'd2:   o[63:0] = $signed(a[31:0]) < $signed(b[31:0]) ? 64'hFFFFFFFFFFFFFFFF : a[31:0]==b[31:0] ? 64'd0 : 64'd1;
        2'd3:   o[63:0] = $signed(a) < $signed(b) ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
        endcase
    3'd2:	// SEQ
    	case(sz[1:0])
    	2'd0:	o[63:0] = a[7:0]==b[7:0];
    	2'd1:	o[63:0] = a[15:0]==b[15:0];
    	2'd2:	o[63:0] = a[31:0]==b[31:0];
    	2'd3:	o[63:0] = a==b;
    	endcase
    3'd3:	// SNE
    	case(sz[1:0])
    	2'd0:	o[63:0] = a[7:0]!=b[7:0];
    	2'd1:	o[63:0] = a[15:0]!=b[15:0];
    	2'd2:	o[63:0] = a[31:0]!=b[31:0];
    	2'd3:	o[63:0] = a!=b;
    	endcase
	3'd4:	// SLT
		case(sz[1:0])
        2'd0:   o[63:0] = $signed(a[7:0]) < $signed(b[7:0]);
        2'd1:   o[63:0] = $signed(a[15:0]) < $signed(b[15:0]);
        2'd2:   o[63:0] = $signed(a[31:0]) < $signed(b[31:0]);
        2'd3:   o[63:0] = $signed(a) < $signed(b);
        endcase
	3'd5:	// SGE
		case(sz[1:0])
        2'd0:   o[63:0] = $signed(a[7:0]) >= $signed(b[7:0]);
        2'd1:   o[63:0] = $signed(a[15:0]) >= $signed(b[15:0]);
        2'd2:   o[63:0] = $signed(a[31:0]) >= $signed(b[31:0]);
        2'd3:   o[63:0] = $signed(a) >= $signed(b);
        endcase
	3'd6:	// SLE
		case(sz[1:0])
        2'd0:   o[63:0] = $signed(a[7:0]) <= $signed(b[7:0]);
        2'd1:   o[63:0] = $signed(a[15:0]) <= $signed(b[15:0]);
        2'd2:   o[63:0] = $signed(a[31:0]) <= $signed(b[31:0]);
        2'd3:   o[63:0] = $signed(a) <= $signed(b);
        endcase
	3'd7:	// SGT
		case(sz[1:0])
        2'd0:   o[63:0] = $signed(a[7:0]) > $signed(b[7:0]);
        2'd1:   o[63:0] = $signed(a[15:0]) > $signed(b[15:0]);
        2'd2:   o[63:0] = $signed(a[31:0]) > $signed(b[31:0]);
        2'd3:   o[63:0] = $signed(a) > $signed(b);
        endcase
    endcase
end
endtask

task tskCmpu;
input [47:0] instr;
input [1:0] sz;
input [63:0] a;
input [63:0] b;
output [63:0] o;
begin
	case(instr[25:23])
	3'd0,3'd1:	// CMPU
		case(sz[1:0])
        2'd0:   o[63:0] = a[7:0] < b[7:0] ? 64'hFFFFFFFFFFFFFFFF : a[7:0]==b[7:0] ? 64'd0 : 64'd1;
        2'd1:   o[63:0] = a[15:0] < b[15:0] ? 64'hFFFFFFFFFFFFFFFF : a[15:0]==b[15:0] ? 64'd0 : 64'd1;
        2'd2:   o[63:0] = a[31:0] < b[31:0] ? 64'hFFFFFFFFFFFFFFFF : a[31:0]==b[31:0] ? 64'd0 : 64'd1;
        2'd3:   o[63:0] = a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
        endcase
    3'd2:	// SEQ
    	case(sz[1:0])
    	2'd0:	o[63:0] = a[7:0]==b[7:0];
    	2'd1:	o[63:0] = a[15:0]==b[15:0];
    	2'd2:	o[63:0] = a[31:0]==b[31:0];
    	2'd3:	o[63:0] = a==b;
    	endcase
    3'd3:	// SNE
    	case(sz[1:0])
    	2'd0:	o[63:0] = a[7:0]!=b[7:0];
    	2'd1:	o[63:0] = a[15:0]!=b[15:0];
    	2'd2:	o[63:0] = a[31:0]!=b[31:0];
    	2'd3:	o[63:0] = a!=b;
    	endcase
	3'd4:	// SLTU
		case(sz[1:0])
        2'd0:   o[63:0] = a[7:0] < b[7:0];
        2'd1:   o[63:0] = a[15:0] < b[15:0];
        2'd2:   o[63:0] = a[31:0] < b[31:0];
        2'd3:   o[63:0] = a < b;
        endcase
	3'd5:	// SGEU
		case(sz[1:0])
        2'd0:   o[63:0] = a[7:0] >= b[7:0];
        2'd1:   o[63:0] = a[15:0] >= b[15:0];
        2'd2:   o[63:0] = a[31:0] >= b[31:0];
        2'd3:   o[63:0] = a >= b;
        endcase
	3'd6:	// SLEU
		case(sz[1:0])
        2'd0:   o[63:0] = a[7:0] <= b[7:0];
        2'd1:   o[63:0] = a[15:0] <= b[15:0];
        2'd2:   o[63:0] = a[31:0] <= b[31:0];
        2'd3:   o[63:0] = a <= b;
        endcase
	3'd7:	// SGTU
		case(sz[1:0])
        2'd0:   o[63:0] = a[7:0] > b[7:0];
        2'd1:   o[63:0] = a[15:0] > b[15:0];
        2'd2:   o[63:0] = a[31:0] > b[31:0];
        2'd3:   o[63:0] = a > b;
        endcase
    endcase
end
endtask

endmodule
