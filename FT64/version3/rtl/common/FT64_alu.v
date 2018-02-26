// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
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
`include "FT64_defines.svh"

module FT64_alu(rst, clk, ld, abort, instr, a, b, c, imm, tgt, tgt2, ven, vm, sbl, sbu,
    csr, o, ob, done, idle, excen, exc, thrd);
parameter DBW = 64;
parameter BIG = 1'b1;
parameter SUP_VECTOR = 1;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk;
input ld;
input abort;
input [35:0] instr;
input [63:0] a;
input [63:0] b;
input [63:0] c;
input [63:0] imm;
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
input [4:0] thrd;
integer n;

wire [DBW-1:0] divq, rem;
wire divByZero;
wire [DBW*2-1:0] prod;
wire mult_done, mult_idle, div_done, div_idle;
wire aslo;
wire [6:0] clzo,cloo,cpopo;
wire [63:0] shftho;

function IsMul;
input [35:0] isn;
case(isn[`INSTRUCTION_OP])
`VECTOR:
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
input [35:0] isn;
case(isn[`INSTRUCTION_OP])
`VECTOR:
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
input [35:0] isn;
case(isn[`INSTRUCTION_OP])
`VECTOR:
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
input [35:0] isn;
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

wire [2:0] sz =
    instr[`INSTRUCTION_OP]==`VECTOR ? 2'd3 : instr[28:26];

wire [63:0] bfout,shfto;
wire [63:0] shftob;
wire [63:0] shftco;

FT64_bitfield #(DBW) ubf1
(
    .inst(instr),
    .a(a),
    .b(b),
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
wire [63:0] zxb12 = {52'd0,b[11:0]};
wire [63:0] sxb12 = {{52{b[11]}},b[11:0]};
reg [15:0] mask;
wire [4:0] cpopom;

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
case(instr[`INSTRUCTION_OP])
`VECTOR:
    if (SUP_VECTOR)
    case(instr[`INSTRUCTION_S2])
    `VABS:         o = a[63] ? -a : a;
    `VSIGN:        o = a[63] ? 64'hFFFFFFFFFFFFFFFF : a==64'd0 ? 64'd0 : 64'd1;
    `VMxx:
    	case(instr[25:23])
	    `VMAND:        o = and64;
	    `VMOR:         o = or64;
	    `VMXOR:        o = xor64;
	    `VMXNOR:       o = ~(xor64);
	    `VMPOP:        o = {57'd0,cpopo};
	    `VMFILL:       for (n = 0; n < 64; n = n + 1)
	                       o[n] = (n < a);
	                       // Change the following when VL > 16
	    `VMFIRST:      o = fsto==5'd31 ? 64'd64 : fsto;
	    `VMLAST:       o = lsto==5'd31 ? 64'd64 : lsto;
		endcase
    `VADD,`VADDS:  o = vm[ven] ? a + b : c;
    `VSUB,`VSUBS:  o = vm[ven] ? a - b : c;
    `VMUL,`VMULS:  o = vm[ven] ? prod[DBW-1:0] : c;
    `VDIV,`VDIVS:  o = BIG ? (vm[ven] ? divq : c) : 64'hCCCCCCCCCCCCCCCC;
    `VAND,`VANDS:  o = vm[ven] ? a & b : c;
    `VOR,`VORS:    o = vm[ven] ? a | b : c;
    `VXOR,`VXORS:  o = vm[ven] ? a ^ b : c;
    `VCNTPOP:      o = {57'd0,cpopo};
    `VSHLV:        o = a;   // no masking here
    `VSHRV:        o = a;
    `VCMPRSS:      o = a;
    `VCIDX:        o = a * ven;
    `VSCAN:        o = a * (cpopom==0 ? 0 : cpopom-1);
    `VSxx,`VSxxS,
    `VSxxb,`VSxxSb:
        case({instr[26],instr[20:19]})
        `VSEQ:     begin
                       o = c;    
                       o[ven] = vm[ven] ? a==b : c[ven];
                   end
        `VSNE:     begin
                       o = c;    
                       o[ven] = vm[ven] ? a!=b : c[ven];
                   end
        `VSLT:      begin
                         o = c;    
                         o[ven] = vm[ven] ? $signed(a) < $signed(b) : c[ven];
                    end
        `VSGE:      begin
                         o = c;    
                         o[ven] = vm[ven] ? $signed(a) >= $signed(b) : c[ven];
                    end
        `VSLE:      begin
                          o = c;    
                          o[ven] = vm[ven] ? $signed(a) <= $signed(b) : c[ven];
                    end
        `VSGT:      begin
                         o = c;    
                         o[ven] = vm[ven] ? $signed(a) > $signed(b) : c[ven];
                    end
        default:	o = 64'hCCCCCCCCCCCCCCCC;
        endcase
    `VSxxU,`VSxxSU,
    `VSxxUb,`VSxxSUb:
        case({instr[26],instr[20:19]})
        `VSEQ:     begin
                       o = c;    
                       o[ven] = vm[ven] ? a==b : c[ven];
                   end
        `VSNE:     begin
                       o = c;    
                       o[ven] = vm[ven] ? a!=b : c[ven];
                   end
        `VSLT:      begin
                         o = c;    
                         o[ven] = vm[ven] ? a < b : c[ven];
                    end
        `VSGE:      begin
                         o = c;    
                         o[ven] = vm[ven] ? a >= b : c[ven];
                    end
        `VSLE:      begin
                          o = c;    
                          o[ven] = vm[ven] ? a <= b : c[ven];
                    end
        `VSGT:      begin
                         o = c;    
                         o[ven] = vm[ven] ? a > b : c[ven];
                    end
        default:	o = 64'hCCCCCCCCCCCCCCCC;
        endcase
    `VBITS2V:   o = vm[ven] ? a[ven] : c;
    `V2BITS:    begin
                o = b;
                o[ven] = vm[ven] ? a[0] : b[ven];
                end
    `VSHL,`VSHR,`VASR:  o = BIG ? shfto : 64'hCCCCCCCCCCCCCCCC;
    `VXCHG:     o = vm[ven] ? b : a;
    default:	o = 64'hCCCCCCCCCCCCCCCC;
    endcase
    else
        o <= 64'hCCCCCCCCCCCCCCCC;    
`RR:
    case(instr[`INSTRUCTION_S2])
    `BCD:
        case(instr[`INSTRUCTION_S1])
        `BCDADD:    o = BIG ? bcdaddo :  64'hCCCCCCCCCCCCCCCC;
        `BCDSUB:    o = BIG ? bcdsubo :  64'hCCCCCCCCCCCCCCCC;
        `BCDMUL:    o = BIG ? bcdmulo :  64'hCCCCCCCCCCCCCCCC;
        default:    o = 64'hDEADDEADDEADDEAD;
        endcase
    `MOV:		o = a;
    `VMOV:		o = a;
    `R1:
        case(instr[`INSTRUCTION_S1])
        `CNTLZ:     o = BIG ? {57'd0,clzo} : 64'hCCCCCCCCCCCCCCCC;
        `CNTLO:     o = BIG ? {57'd0,cloo} : 64'hCCCCCCCCCCCCCCCC;
        `CNTPOP:    o = BIG ? {57'd0,cpopo} : 64'hCCCCCCCCCCCCCCCC;
        `ABS:       case(sz)
                    2'd0:   o = BIG ? (a[7] ? -a[7:0] : a[7:0]) : 64'hCCCCCCCCCCCCCCCC;
                    2'd1:   o = BIG ? (a[15] ? -a[15:0] : a[15:0]) : 64'hCCCCCCCCCCCCCCCC;
                    2'd2:   o = BIG ? (a[31] ? -a[31:0] : a[31:0]) : 64'hCCCCCCCCCCCCCCCC;
                    2'd3:   o = BIG ? (a[63] ? -a : a) : 64'hCCCCCCCCCCCCCCCC;
                    endcase
        `NOT:   case(sz)
                2'd0:   o = ~|a[7:0];
                2'd1:   o = ~|a[15:0];
                2'd2:   o = ~|a[31:0];
                2'd3:   o = ~|a[63:0];
                endcase
        `REDOR: case(sz)
                2'd0:   o = redor8;
                2'd1:   o = redor16;
                2'd2:   o = redor32;
                2'd3:   o = redor64;
                endcase
        default:    o = 64'hDEADDEADDEADDEAD;
        endcase
    `BMM:		o = BIG ? bmmo : 64'hCCCCCCCCCCCCCCCC;
    `SHIFT:     o = BIG ? shfto : 64'hCCCCCCCCCCCCCCCC;
    `SHIFTB:    o = BIG ? shftob : 64'hCCCCCCCCCCCCCCCC;
    `SHIFTC:    o = BIG ? shftco : 64'hCCCCCCCCCCCCCCCC;
    `SHIFTH:    o = BIG ? shftho : 64'hCCCCCCCCCCCCCCCC;
    `ADD:   case(sz)
    		3'd0,3'd4:
    			begin
    				o[7:0] <= a[7:0] + b[7:0];
    				o[15:8] <= a[15:8] + b[15:8];
    				o[23:16] <= a[23:16] + b[23:16];
    				o[31:24] <= a[31:24] + b[31:24];
    				o[39:32] <= a[39:32] + b[39:32];
    				o[47:40] <= a[47:40] + b[47:40];
    				o[55:48] <= a[55:48] + b[55:48];
    				o[63:56] <= a[63:56] + b[63:56];
    			end
    		3'd1,3'd5:
    			begin
    				o[15:0] <= a[15:0] + b[15:0];
    				o[31:16] <= a[31:16] + b[31:16];
    				o[47:32] <= a[47:32] + b[47:32];
    				o[63:48] <= a[63:48] + b[63:48];
    			end
    		3'd2,3'd6:
    			begin
    				o[31:0] <= a[31:0] + b[31:0];
    				o[63:32] <= a[63:32] + b[63:32];
    			end
            3'd3,3'd7:
            		o = a + b;
            endcase
    `SUB:   case(sz)
    		3'd0,3'd4:
    			begin
    				o[7:0] <= a[7:0] - b[7:0];
    				o[15:8] <= a[15:8] - b[15:8];
    				o[23:16] <= a[23:16] - b[23:16];
    				o[31:24] <= a[31:24] - b[31:24];
    				o[39:32] <= a[39:32] - b[39:32];
    				o[47:40] <= a[47:40] - b[47:40];
    				o[55:48] <= a[55:48] - b[55:48];
    				o[63:56] <= a[63:56] - b[63:56];
    			end
    		3'd1,3'd5:
    			begin
    				o[15:0] <= a[15:0] - b[15:0];
    				o[31:16] <= a[31:16] - b[31:16];
    				o[47:32] <= a[47:32] - b[47:32];
    				o[63:48] <= a[63:48] - b[63:48];
    			end
    		3'd2,3'd6:
    			begin
    				o[31:0] <= a[31:0] - b[31:0];
    				o[63:32] <= a[63:32] - b[63:32];
    			end
            3'd3,3'd7:
            		o = a - b;
            endcase
    `CMP:   case(instr[25:23])
    		3'd0,3'd1:	// CMP
	    		case(sz[1:0])
	            2'd0:   o = $signed(a[7:0]) < $signed(b[7:0]) ? 64'hFFFFFFFFFFFFFFFF : a[7:0]==b[7:0] ? 64'd0 : 64'd1;
	            2'd1:   o = $signed(a[15:0]) < $signed(b[15:0]) ? 64'hFFFFFFFFFFFFFFFF : a[15:0]==b[15:0] ? 64'd0 : 64'd1;
	            2'd2:   o = $signed(a[31:0]) < $signed(b[31:0]) ? 64'hFFFFFFFFFFFFFFFF : a[31:0]==b[31:0] ? 64'd0 : 64'd1;
	            2'd3:   o = $signed(a) < $signed(b) ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
	            endcase
	        3'd2:	// SEQ
	        	case(sz[1:0])
	        	2'd0:	o = a[7:0]==b[7:0];
	        	2'd1:	o = a[15:0]==b[15:0];
	        	2'd2:	o = a[31:0]==b[31:0];
	        	2'd3:	o = a==b;
	        	endcase
	        3'd3:	// SNE
	        	case(sz[1:0])
	        	2'd0:	o = a[7:0]!=b[7:0];
	        	2'd1:	o = a[15:0]!=b[15:0];
	        	2'd2:	o = a[31:0]!=b[31:0];
	        	2'd3:	o = a!=b;
	        	endcase
    		3'd4:	// SLT
	    		case(sz[1:0])
	            2'd0:   o = $signed(a[7:0]) < $signed(b[7:0]);
	            2'd1:   o = $signed(a[15:0]) < $signed(b[15:0]);
	            2'd2:   o = $signed(a[31:0]) < $signed(b[31:0]);
	            2'd3:   o = $signed(a) < $signed(b);
	            endcase
    		3'd5:	// SGE
	    		case(sz[1:0])
	            2'd0:   o = $signed(a[7:0]) >= $signed(b[7:0]);
	            2'd1:   o = $signed(a[15:0]) >= $signed(b[15:0]);
	            2'd2:   o = $signed(a[31:0]) >= $signed(b[31:0]);
	            2'd3:   o = $signed(a) >= $signed(b);
	            endcase
    		3'd6:	// SLE
	    		case(sz[1:0])
	            2'd0:   o = $signed(a[7:0]) <= $signed(b[7:0]);
	            2'd1:   o = $signed(a[15:0]) <= $signed(b[15:0]);
	            2'd2:   o = $signed(a[31:0]) <= $signed(b[31:0]);
	            2'd3:   o = $signed(a) <= $signed(b);
	            endcase
    		3'd7:	// SGT
	    		case(sz[1:0])
	            2'd0:   o = $signed(a[7:0]) > $signed(b[7:0]);
	            2'd1:   o = $signed(a[15:0]) > $signed(b[15:0]);
	            2'd2:   o = $signed(a[31:0]) > $signed(b[31:0]);
	            2'd3:   o = $signed(a) > $signed(b);
	            endcase
	        endcase
    `CMPU:  case(instr[25:23])
    		3'd0,3'd1:	// CMPU
	    		case(sz[1:0])
	            2'd0:   o = a[7:0] < b[7:0] ? 64'hFFFFFFFFFFFFFFFF : a[7:0]==b[7:0] ? 64'd0 : 64'd1;
	            2'd1:   o = a[15:0] < b[15:0] ? 64'hFFFFFFFFFFFFFFFF : a[15:0]==b[15:0] ? 64'd0 : 64'd1;
	            2'd2:   o = a[31:0] < b[31:0] ? 64'hFFFFFFFFFFFFFFFF : a[31:0]==b[31:0] ? 64'd0 : 64'd1;
	            2'd3:   o = a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
	            endcase
	        3'd2:	// SEQ
	        	case(sz[1:0])
	        	2'd0:	o = a[7:0]==b[7:0];
	        	2'd1:	o = a[15:0]==b[15:0];
	        	2'd2:	o = a[31:0]==b[31:0];
	        	2'd3:	o = a==b;
	        	endcase
	        3'd3:	// SNE
	        	case(sz[1:0])
	        	2'd0:	o = a[7:0]!=b[7:0];
	        	2'd1:	o = a[15:0]!=b[15:0];
	        	2'd2:	o = a[31:0]!=b[31:0];
	        	2'd3:	o = a!=b;
	        	endcase
    		3'd4:	// SLTU
	    		case(sz[1:0])
	            2'd0:   o = a[7:0] < b[7:0];
	            2'd1:   o = a[15:0] < b[15:0];
	            2'd2:   o = a[31:0] < b[31:0];
	            2'd3:   o = a < b;
	            endcase
    		3'd5:	// SGEU
	    		case(sz[1:0])
	            2'd0:   o = a[7:0] >= b[7:0];
	            2'd1:   o = a[15:0] >= b[15:0];
	            2'd2:   o = a[31:0] >= b[31:0];
	            2'd3:   o = a >= b;
	            endcase
    		3'd6:	// SLEU
	    		case(sz[1:0])
	            2'd0:   o = a[7:0] <= b[7:0];
	            2'd1:   o = a[15:0] <= b[15:0];
	            2'd2:   o = a[31:0] <= b[31:0];
	            2'd3:   o = a <= b;
	            endcase
    		3'd7:	// SGTU
	    		case(sz[1:0])
	            2'd0:   o = a[7:0] > b[7:0];
	            2'd1:   o = a[15:0] > b[15:0];
	            2'd2:   o = a[31:0] > b[31:0];
	            2'd3:   o = a > b;
	            endcase
	        endcase
    `AND:   o = and64;
    `OR:    o = or64;
    `XOR:   o = xor64;
    `NAND:  o = ~and64;
    `NOR:   o = ~or64;
    `XNOR:  o = ~xor64;
    `SEI:       o = a | instr[21:16];
    `RTI:       o = a | instr[21:16];
    `CMOVEQ:    o = (a==64'd0) ? b : c;
    `CMOVNE:    o = (a!=64'd0) ? b : c;
    `MUX:       for (n = 0; n < 64; n = n + 1)
                    o[n] <= a[n] ? b[n] : c[n];
    `MULU:      o = instr[25:24]==2'b00 ? prod[DBW-1:0] : prod[DBW*2-1:DBW];
    `MULSU:     o = instr[25:24]==2'b00 ? prod[DBW-1:0] : prod[DBW*2-1:DBW];
    `MUL:       o = instr[25:24]==2'b00 ? prod[DBW-1:0] : prod[DBW*2-1:DBW];
    `DIVMODU:   o = BIG ? (instr[25:24]==2'b00 ? divq : rem) : 64'hCCCCCCCCCCCCCCCC;
    `DIVMODSU:  o = BIG ? (instr[25:24]==2'b00 ? divq : rem) : 64'hCCCCCCCCCCCCCCCC;
    `DIVMOD:    o = BIG ? (instr[25:24]==2'b00 ? divq : rem) : 64'hCCCCCCCCCCCCCCCC;
    `LBX,`LBOX,`LBUX,`LCX,`LCOX,`LCUX,
    `LHX,`LHOX,`LHUX,`LWX,`LWRX,`SBX,`SCX,`SHX,`SWX,`SWCX:
    		   	o = BIG ? a + (b << instr[22:21]) : 64'hCCCCCCCCEEEEEEEE;
    `LVx:		o = BIG ? a + (b << instr[22:21]) : 64'hCCCCCCCCCCCCCCCC;
    `LVX,`SVX:  o = BIG ? a + (b << 2'd3) : 64'hCCCCCCCCCCCCCCCC;
    `LVWS,`SVWS:    o = BIG ? a + ({b * ven,3'b000}) : 64'hCCCCCCCCCCCCCCCC;
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
    				o = BIG ? ($signed(a) < $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
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
    				o = BIG ? ($signed(a) > $signed(b) ? a : b) : 64'hCCCCCCCCCCCCCCCC;
    			endcase
    `MAJ:		o = (a & b) | (a & c) | (b & c);
    `CHK:       o = (a >= b && a < c);
    default:    o = 64'hDEADDEADDEADDEAD;
    endcase
 `ADDI: o = a + b;
 `CMPI: o = $signed(a) < $signed(b) ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
 `CMPUI: o = a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
 `ANDI:  o = a & b;
 `ORI:   o = a | b;
 `XORI:  o = a ^ b;
 `QOPI:     case(instr[10:8])
            `QORI:
                case(instr[7:6])
                2'd0:   o = b | {48'h000000000000,imm[15:0]};
                2'd1:   o = b | {32'h00000000,imm[15:0],16'h0000};
                2'd2:   o = b | {16'h0000,imm[15:0],32'h00000000};
                2'd3:   o = b | {imm[15:0],48'h000000000000};
                endcase
            `QXORI:
                case(instr[7:6])
                2'd0:   o = b ^ {48'h000000000000,imm[15:0]};
                2'd1:   o = b ^ {32'h00000000,imm[15:0],16'h0000};
                2'd2:   o = b ^ {16'h0000,imm[15:0],32'h00000000};
                2'd3:   o = b ^ {imm[15:0],48'h000000000000};
                endcase
            `QANDI:
                case(instr[7:6])
                2'd0:   o = b & {48'hFFFFFFFFFFFF,imm[15:0]};
                2'd1:   o = b & {32'hFFFFFFFF,imm[15:0],16'hFFFF};
                2'd2:   o = b & {16'hFFFF,imm[15:0],32'hFFFFFFFF};
                2'd3:   o = b & {imm[15:0],48'hFFFFFFFFFFFF};
                endcase
             `QADDI:
                case(instr[7:6])
                2'd0:   o = b + imm;
                2'd1:   o = b + {imm,16'h0};
                2'd2:   o = b + {imm,32'h0};
                2'd3:   o = b + {imm,48'h0};
                endcase
            default:    o = 64'hDEADDEADDEADDEAD;
            endcase
 `SccI:
            case(instr[31:28])
            `SEQ:   o = a == sxb12;
            `SNE:   o = a != sxb12;
            `SLT:   o = $signed(a) < $signed(sxb12);
            `SGE:   o = $signed(a) >= $signed(sxb12);
            `SLE:   o = $signed(a) <= $signed(sxb12);
            `SGT:   o = $signed(a) > $signed(sxb12);
            `SLTU:  o = a < zxb12;
            `SGEU:  o = a >= zxb12;
            `SLEU:  o = a <= zxb12;
            `SGTU:  o = a > zxb12;
            default:    o = 64'hDEADDEADDEADDEAD;
            endcase
 `MULUI:     o = prod[DBW-1:0];
 `MULSUI:    o = prod[DBW-1:0];
 `MULI:      o = prod[DBW-1:0];
 `DIVUI:     o = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
 `DIVSUI:    o = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
 `DIVI:      o = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
 `MODUI:     o = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
 `MODSUI:    o = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
 `MODI:      o = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
 `LB,`LBO,`LBU,`LC,`LCO,`LCU,`LH,`LHO,`LHU,`LW,`LWR,
 `SB,`SC,`SH,`SW,`SWC,`CAS:  o = a + b;
 `LVx:		 o = a + sxb12;
 `LV,`SV:    o = a + b + {ven,3'b0};
 `CSRRW:     o = BIG ? csr | {thrd,24'h0} : 64'hDDDDDDDDDDDDDDDD;
 `BITFIELD:   o = BIG ? bfout : 64'hCCCCCCCCCCCCCCCC;
  default:    o = 64'hDEADDEADDEADDEAD;
endcase  

// Generate done signal
always @*
begin
    if (IsMul(instr))
        done <= mult_done;
    else if (IsDivmod(instr) & BIG)
        done <= div_done;
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
if ((tgt[5:0]==6'd63 || tgt[5:0]==6'd62) && (o[31:0] < sbl || o[31:0] > sbu))
    exc <= `FLT_STK;
else
case(instr[`INSTRUCTION_OP])
`RR:
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
`MULI,`MULSUI:    exc <= prod[63] ? (prod[127:64] != 64'hFFFFFFFFFFFFFFFF & excen[3] ? `FLT_OFL : `FLT_NONE):
                                    (prod[127:64] != 64'd0 & excen[3] ? `FLT_OFL : `FLT_NONE);
`DIVI,`DIVSUI: exc <= BIG & excen[4] & divByZero ? `FLT_DBZ : `FLT_NONE;
`MODI,`MODSUI: exc <= BIG & excen[4] & divByZero ? `FLT_DBZ : `FLT_NONE;
default:    exc <= `FLT_NONE;
endcase
end

endmodule
