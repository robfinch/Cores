// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
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

module FT64alu(rst, clk, ld, abort, instr, a, b, c, imm, pc, csr, o, ob, done, idle, excen, exc);
parameter DBW = 64;
parameter BIG = 1'b1;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk;
input ld;
input abort;
input [31:0] instr;
input [63:0] a;
input [63:0] b;
input [63:0] c;
input [63:0] imm;
input [31:0] pc;
input [63:0] csr;
output reg [63:0] o;
output reg [63:0] ob;
output reg done;
output reg idle;
input [4:0] excen;
output reg [8:0] exc;
integer n;

wire [DBW-1:0] divq, rem;
wire divByZero;
wire [DBW*2-1:0] prod;
wire mult_done, mult_idle, div_done, div_idle;
wire aslo;
wire [6:0] clzo,cloo,cpopo;

function IsMul;
input [31:0] isn;
case(isn[`INSTRUCTION_OP])
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
input [31:0] isn;
case(isn[`INSTRUCTION_OP])
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
input [31:0] isn;
case(isn[`INSTRUCTION_OP])
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
input [31:0] isn;
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

wire [63:0] bfout,shfto;
FT64_bitfield ubf1
(
    .op(instr[24:21]),
    .a(a),
    .b(b),
    // The lower 16 bits of the immediate are the trailing bits of
    // the instruction.
    .imm({49'd0,imm[41:32],instr[15:11]}),
    .m(imm[31:16]),
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

cntlz64 uclz1
(
	.i(a),
	.o(clzo)
);

cntlo64 uclo1
(
	.i(a),
	.o(cloo)
);

cntpop64 ucpop1
(
	.i(a),
	.o(cpopo)
);

always @*
case(instr[`INSTRUCTION_OP])
`RR:
    case(instr[`INSTRUCTION_S2])
    `R1:
        case(instr[`INSTRUCTION_S1])
        `CNTLZ:     o = BIG ? {57'd0,clzo} : 64'hCCCCCCCCCCCCCCCC;
        `CNTLO:     o = BIG ? {57'd0,cloo} : 64'hCCCCCCCCCCCCCCCC;
        `CNTPOP:    o = BIG ? {57'd0,cpopo} : 64'hCCCCCCCCCCCCCCCC;
        `ABS:       o = BIG ? (a[63] ? -a : a) : 64'hCCCCCCCCCCCCCCCC;
        default:    o = 64'hDEADDEADDEADDEAD;
        endcase
    `BITFIELD:  o = BIG ? bfout : 64'hCCCCCCCCCCCCCCCC;
    `SHIFT:     o = BIG ? shfto : 64'hCCCCCCCCCCCCCCCC;
    `ADD: o = a + b;
    `SUB: o = a - b;
    `CMP: o = $signed(a) < $signed(b) ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
    `CMPU: o = a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
    `AND:  o = a & b;
    `OR:   o = a | b;
    `XOR:  o = a ^ b;
    `NAND:  o = ~(a & b);
    `NOR:   o = ~(a | b);
    `XNOR:  o = ~(a ^ b);
    `SEI:       o = a | b;
    `CMOVEQ:    o = (a==64'd0) ? b : c;
    `CMOVNE:    o = (a!=64'd0) ? b : c;
    `MUX:       for (n = 0; n < 64; n = n + 1)
                    o[n] <= a[n] ? b[n] : c[n];
    `DEMUX:     if (BIG)
                    for (n = 0; n < 64; n = n + 1)
                        o[n] <= a[n] ? 1'b0 : b[n];
                else
                    o = 64'hCCCCCCCCCCCCCCCC;
    `MULU:      o = prod[DBW-1:0];
    `MULSU:     o = prod[DBW-1:0];
    `MUL:       o = prod[DBW-1:0];
    `DIVMODU:   o = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
    `DIVMODSU:  o = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
    `DIVMOD:    o = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
    `PUSH:      o = instr[25] ? a + {{59{instr[25]}},instr[25:21]} : a;
    `POP:       o = instr[25] ? a + {{59{instr[25]}},instr[25:21]} : a;
    `UNLINK:    o = b;
    `LBX,`LHX,`LHUX,`LWX,`SBX,`SHX,`SWX:   o = BIG ? a + (b << instr[22:21]) : 64'hCCCCCCCCCCCCCCCC;
    `MIN:       o = BIG ? ((a < b && a < c) ? a : (b < c) ? b : c) : 64'hCCCCCCCCCCCCCCCC;
    `MAX:       o = BIG ? ((a > b && a > c) ? a : (b > c) ? b : c) : 64'hCCCCCCCCCCCCCCCC;
    default:    o = 64'hDEADDEADDEADDEAD;
    endcase
 `ADDI: o = a + b;
 `CMPI: o = $signed(a) < $signed(b) ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
 `CMPUI: o = a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'd0 : 64'd1;
 `ANDI:  o = a & b;
 `ORI:   o = a | b;
 `XORI:  o = a ^ b;
 `MULUI:     o = prod[DBW-1:0];
 `MULSUI:    o = prod[DBW-1:0];
 `MULI:      o = prod[DBW-1:0];
 `DIVUI:     o = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
 `DIVSUI:    o = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
 `DIVI:      o = BIG ? divq : 64'hCCCCCCCCCCCCCCCC;
 `MODUI:     o = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
 `MODSUI:    o = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
 `MODI:      o = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
 `LB,`LH,`LHU,`LW,`SB,`SH,`SW:  o = a + b;
 `CSRRW:     o = BIG ? csr : 64'hCCCCCCCCCCCCCCCC;
 `RET:       o = a;
 `LINK:      o = a - 32'd8;
  default:    o = 64'hDEADDEADDEADDEAD;
endcase  

always @*
case(instr[`INSTRUCTION_OP])
`RR:
    case(instr[`INSTRUCTION_S2])
    `MUL,`MULU,`MULSU:  ob = prod[127:64];
    `DIVMOD,`DIVMODU,`DIVMODSU:    ob = BIG ? rem : 64'hCCCCCCCCCCCCCCCC;
    `PUSH:      ob = a + {{59{instr[25]}},instr[25:21]};
    `POP:       ob = a + {{59{instr[25]}},instr[25:21]};
    `UNLINK:    ob = b + 32'd8;
    `DEMUX:     for (n = 0; n < 64; n = n + 1)
                    ob[n] <= (a[n] & BIG) ? b[n] : 1'b0;
    default:    ob = 64'hCCCCCCCCCCCCCCCC;
    endcase
`RET:       ob = a + b;
`LINK:      ob = a + b;
default:    ob = 64'hCCCCCCCCCCCCCCCC;
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
case(instr[`INSTRUCTION_OP])
`RR:
    case(instr[`INSTRUCTION_S2])
    `ADD:   exc <= (fnOverflow(0,a[63],b[63],o[63]) & excen[0]) ? `FLT_OFL : `FLT_NONE;
    `SUB:   exc <= (fnOverflow(1,a[63],b[63],o[63]) & excen[1]) ? `FLT_OFL : `FLT_NONE;
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
