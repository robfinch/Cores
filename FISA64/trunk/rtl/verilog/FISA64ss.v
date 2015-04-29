// ============================================================================
// FISA64.v
//        __
//   \\__/ o\    (C) 2015  Robert Finch, Stratford
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
// 106MHz without multiply (include as a multi-cycle path)                                                                          
// ============================================================================
//
`define TRUE	1'b1
`define FALSE	1'b0
//`define DEBUG_COP	1'b1
//`define FLOAT	1'b1

`define RR		7'h02
`define BTFLD	7'h03
`define	BFSET		3'd0
`define BFCLR		3'd1
`define BFCHG		3'd2
`define BFINS		3'd3
`define BFINSI		3'd4
`define BFEXT		3'd5
`define BFEXTU		3'd6
`define NAND		7'h00
`define NOR			7'h01
`define ENOR		7'h02
`define ADD		7'h04
`define SUB		7'h05
`define CMP		7'h06
`define MUL		7'h07
`define DIV		7'h08
`define MOD		7'h09
`define LDI		7'h0A
`define NOT			7'h0A
`define MOV			7'h0B
`define CHKI    7'h0B
`define AND		7'h0C
`define OR		7'h0D
`define EOR		7'h0E
`define SXB			7'h10
`define SXC			7'h11
`define SXH			7'h12
`define ADDU	7'h14
`define SUBU	7'h15
`define CMPU	7'h16
`define MULU	7'h17
`define DIVU	7'h18
`define MODU	7'h19
`define LDFI	7'h1A
`define CHK			7'h1A
`define MTFP	    7'h1C
`define MV2FLT		7'h1D
`define MTSPR		7'h1E
`define MFSPR		7'h1F
`define IMM10	7'b001000x
`define MOV2	7'b010000x
`define ADDQ	7'h22
`define MYST	7'h24
`define RTL		7'h27
`define FADD	7'h28
`define FSUB	7'h29
`define FCMP	7'h2A
`define FMUL	7'h2B
`define FDIV	7'h2C
`define RTS2	7'h30
`define PUSHPOP	7'h31
`define BEQS	7'h32
`define BNES	7'h33
`define LDIQ	7'h34
`define SYS		7'h35
`define PCTRL2	7'h36
`define NOP2			9'd0
`define STP2			9'd1
`define WAI2            9'd2
`define INT3			9'd3
`define CLI2			9'd4
`define SEI2			9'd5
`define RTI2			9'd6
`define RTE2			9'd7
`define RTD2			9'd8
`define RTL2	7'h37
`define BRK		7'h38
`define BSR		7'h39
`define BRA		7'h3A
`define RTS		7'h3B
`define JAL		7'h3C
`define Bcc		7'h3D
`define BEQ			3'h0
`define BNE			3'h1
`define BGT			3'h2
`define BGE			3'h3
`define BLT			3'h4
`define BLE			3'h5
`define BUN			3'h6
`define JALI	7'h3E
`define NOP		7'h3F
`define SLL			7'h30
`define SRL			7'h31
`define ROL			7'h32
`define ROR			7'h33
`define SRA			7'h34
`define CPUID		7'h36
`define PCTRL		7'h37
`define CLI				5'd0
`define SEI				5'd1
`define STP				5'd2
`define WAI             5'd3
`define EIC				5'd4
`define DIC				5'd5
`define SRI				5'd8
`define FIP				5'd10
`define RTD				5'd29
`define RTE				5'd30
`define RTI				5'd31
`define SLLI		7'h38
`define SRLI		7'h39
`define ROLI		7'h3A
`define RORI		7'h3B
`define SRAI		7'h3C
`define FENCE		7'h40
`define LB		7'h40
`define LBU		7'h41
`define LC		7'h42
`define LCU		7'h43
`define LH		7'h44
`define LHU		7'h45
`define LW		7'h46
`define LEA		7'h47
`define LBX		7'h48
`define LBUX	7'h49
`define LCX		7'h4A
`define LCUX	7'h4B
`define LHX		7'h4C
`define LHUX	7'h4D
`define LWX		7'h4E
`define LEAX	7'h4F
`define LFD		7'h51
`define PUSHF	7'h54
`define POPF	7'h55
`define POP		7'h57
`define LFDX	7'h59
`define LWAR	7'h5C
`define SUI		7'h5F
`define SB		7'h60
`define SC		7'h61
`define SH		7'h62
`define SW		7'h63
`define INC		7'h64
`define PEA		7'h65
`define PMW		7'h66
`define PUSH	7'h67
`define SBX		7'h68
`define SCX		7'h69
`define SHX		7'h6A
`define SWX		7'h6B
`define CAS		7'h6C
`define SWCR	7'h6E
`define INCX	7'h6F
`define SFD		7'h71
`define SFDX	7'h75

`define FIX2FLT		7'h60
`define FLT2FIX		7'h61
`define FMOV		7'h62
`define FNEG		7'h63
`define FABS		7'h64
`define MFFP		7'h65
`define MV2FIX		7'h66

`define IMM		7'b1111xxx

`define CR0			8'd00
`define CR3			8'd03
`define TICK		8'd04
`define CLK			8'd06
`define DBPC		8'd07
`define IPC			8'd08
`define EPC			8'd09
`define VBR			8'd10
`define BEAR		8'd11
`define VECNO		8'd12
`define MULH		8'd14
`define ISP			8'd15
`define DSP			8'd16
`define ESP			8'd17
`define FPSCR		8'd20
`define EA			8'd40
`define TAGS		8'd41
`define LOTGRP		8'd42
`define CASREG		8'd44
`define MYSTREG		8'd45
`define DBAD0		8'd50
`define DBAD1		8'd51
`define DBAD2		8'd52
`define DBAD3		8'd53
`define DBCTRL		8'd54
`define DBSTAT		8'd55
//0000_0011_1100_1110_00001111_00111000;
//03cc0f38
`define BRK_BND	{6'd0,9'd487,5'd0,5'h1E,`BRK}
`define BRK_DBZ	{6'd0,9'd488,5'd0,5'h1E,`BRK}
`define BRK_OFL	{6'd0,9'd489,5'd0,5'h1E,`BRK}
`define BRK_FLT	{6'd0,9'd493,5'd0,5'h1E,`BRK}
`define BRK_TAP	{2'b01,4'd0,9'd494,5'd0,5'h1E,`BRK}
`define BRK_SSM	{2'b01,4'd0,9'd495,5'd0,5'h1E,`BRK}
`define BRK_BPT	{2'b01,4'd0,9'd496,5'd0,5'h1E,`BRK}
`define BRK_EXF	{6'd0,9'd497,5'd0,5'h1E,`BRK}
`define BRK_DWF	{6'd0,9'd498,5'd0,5'h1E,`BRK}
`define BRK_DRF	{6'd0,9'd499,5'd0,5'h1E,`BRK}
`define BRK_PRV	{6'd0,9'd501,5'd0,5'h1E,`BRK}
`define BRK_DBE	{1'b1,5'd0,9'd508,5'd0,5'h1E,`BRK}
`define BRK_IBE	{1'b1,5'd0,9'd509,5'd0,5'h1E,`BRK}
`define BRK_NMI	{1'b1,5'd0,9'd510,5'd0,5'h1E,`BRK}
`define BRK_IRQ	{1'b1,5'd0,vect_i,5'd0,5'h1E,`BRK}

`define VAL		1'b1
`define INV		1'b0
`define ZERO	64'd0

module FISA64ss(rst, clk, );

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

integer jj;
integer kk;

reg km;	// processor is in kernel mode

reg [5:0] fetchbuf0_Ra;
reg [5:0] fetchbuf0_Rb;
reg [5:0] fetchbuf0_Rc;
reg [5:0] fetchbuf0_Rt;
reg [5:0] fetchbuf1_Ra;
reg [5:0] fetchbuf1_Rb;
reg [5:0] fetchbuf1_Rc;
reg [5:0] fetchbuf1_Rt;

reg [63:1] iqentry_livetarget[7:0];
reg [7:0] iqentry_v;
reg [7:0] iqentry_done;
reg [7:0] iqentry_out;
reg [63:0] iqentry_a0 [7:0];
reg [63:0] iqentry_a1 [7:0];
reg [63:0] iqentry_a2 [7:0];
reg [63:0] iqentry_a3 [7:0];
reg [7:0] iqentry_a0_v;
reg [7:0] iqentry_a1_v;
reg [7:0] iqentry_a2_v;
reg [3:0] iqentry_a0_s [7:0];
reg [3:0] iqentry_a1_s [7:0];
reg [3:0] iqentry_a2_s [7:0];
reg [63:0] iqentry_res [7:0];
reg [7:0] iqentry_stomp;
reg [31:0] iqentry_pc [7:0];
reg [31:0] iqentry_insn [7:0];
reg [7:0] iqentry_bt;
reg [7:0] iqentry_rfw;
reg [5:0] iqentry_tgt [7:0];
reg [3:0] iqentry_exc [7:0];
reg [7:0] iqentry_agen;
reg [63:1] iq_out[7:0];
reg [63:1] iqentry_latestID[7:0];
reg [63:1] iqentry_cumulative[7:0];
reg [7:0] iqentry_source;
reg [2:0] tail0;
reg [2:0] tail1;

reg [63:0] rf_v;
reg [3:0] rf_source[63:0];
reg [63:0] rfo0a;
reg [63:0] rfo0b;
reg [63:0] rfo0c;
reg [63:0] rfo1a;
reg [63:0] rfo1b;
reg [63:0] rfo1c;

reg [3:0] commit0_id;
reg [3:0] commit1_id;
reg commit0_v;
reg commit1_v;
reg [5:0] commit0_tgt;
reg [5:0] commit1_tgt;
reg [63:0] commit0_bus;
reg [63:0] commit1_bus;

FISA64_regfile2w4r u1
(
	.clk(clk), 
	.wr0(commit0_v),
	.wr1(commit1_v),
	.wa0(commit0_tgt),
	.wa1(commit1_tgt),
	.i0(commit0_bus),
	.i1(commit1_bus),
	.rclk(~clk),
	.ra0(fetchbuf0_Ra),
	.ra1(fetchbuf0_Rb),
	.ra2(fetchbuf0_Rc),
	.ra3(fetchbuf1_Ra),
	.ra4(fetchbuf1_Rb),
	.ra5(fetchbuf1_Rc),
	.o0(rfo0a),
	.o1(rfo0b),
	.o2(rfo0c),
	.o3(rfo1a),
	.o4(rfo1b),
	.o5(rfo1c)
);

function isImm;
input [31:0] insn;
if (insn[6:0]==`IMM)
	isImm = TRUE;
else
	isImm = FALSE;
endfunction

function isImm10;
input [31:0] insn;
if (insn[6:0]==`IMM10)
	isImm10 = TRUE;
else
	isImm10 = FALSE;
endfunction

function isLoad;
input [6:0] opcode;
case(opcode)
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LFD,`LWAR,
`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LFDX:
	isLoad = TRUE;
default: isLoad = FALSE;
endcase
endfunction

function isDramLoad;
input [31:0] insn;
case(insn[6:0])
`PUSHPOP:
	case (insn[15:12])
	4'd2,4'd3:	isDramLoad = TRUE;
	default:	isDramLoad = FALSE;
	endcase
`POP,`POPF,
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LFD,`LWAR,
`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LFDX:
	isDramLoad = TRUE;
default: isDramLoad = FALSE;
endcase
endfunction

function isStore;
input [6:0] opcode;
case(opcode)
`SB,`SC,`SH,`SW,`SFD,`SWCR,
`SBX,`SCX,`SHX,`SWX,`SFDX:
	isStore = TRUE;
default: isStore = FALSE;
endcase
endfunction

function isMem;
input [6:0] opcode;
isMem = isLoad(opcode) || isStore(opcode) || opcode==`PUSHPOP;
endcase
endfunction

// When to update the register file.
function isRFW;
input [31:0] insn;
casex(insn[6:0])
`RR:
	case(insn[31:25])
	`ADD,`ADDU,`SUB,`SUBU,`CMP,`CMPU,
	`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU,
	`AND,`OR,`EOR,`NAMD,`NOR,`ENOR,
	`ASL,`ROL,`LSR,`ROR,`ASR,`ASLI,`ROLI,`LSRI,`RORI,`ASRI,
	`SXB,`SXC,`SXH,`NOT,
	`MFSPR,
	`FIX2FLT,`FLT2FIX,`MV2FLT,`MV2FIX,`MFFP,`MTFP,`FMOV,
	`FNEG,`FABS,
	`CPUID,
		isRFW = TRUE;
	default: isRFW = FALSE;
	endcase
`BSR,`JAL,`JALI,
`MOV2,
`BTFLD,
`LDI,`LDIQ,`LDIF,`ADDQ,
`ADD,`ADDU,`SUB,`SUBU,`CMP,`CMPU,
`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU,
`AND,`OR,`EOR,
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LFD,
`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LFDX,
`LWAR,
`LEA,`LEAX,
`FADD,`FSUB,`FCMP,`FMUL,`FDIV,
`PUSHPOP:
	begin
		if (insn[15:12] < 4'h2)
			isRFW = FALSE;
		else
			isRFW = TRUE;
	end
	isRFW = TRUE;
default:	isRFW = FALSE;
endcase
endfunction

function raFP;
input [31:0] insn;
case(insn[6:0])
`RR:
	case(insn[31:25])
	`FLT2FIX,`MV2FIX,`FNEG,`FABS,`FMOV,`MFFP:
		raFP = TRUE;
	default: raFP = FALSE;
	endcase
`FADD,`FSUB,`FCMP,`FMUL,`FDIV:
	raFP = TRUE;
default: raFP = FALSE;
endfunction

function rbFP;
input [31:0] insn;
case(insn[6:0])
`FADD,`FSUB,`FCMP,`FMUL,`FDIV:
	rbFP = TRUE;
default: rbFP = FALSE;
endfunction

function rcFP;
input [31:0] insn;
case(insn[6:0])
`SFD,`SFDX:	rcFP = TRUE;
default: rcFP = FALSE;
endfunction

// Determine if an instruction is a POP instruction.
function isPop;
input [31:0] insn;
case(insn[6:0])
`POP,`POPF:	isPop = TRUE;
`PUSHPOP:
	case(insn[15:12])
	4'd2,4'd3:	isPop = TRUE;
	default: isPop = FALSE;
	endcase
default: isPop = FALSE;
endcase
endfunction

function isRts;
input [31:0] insn;
case(insn[6:0])
`RTS:	isRts = TRUE;
`RTS2:	isRts = TRUE;
default:	isRts = FALSE;
endcase
endfunction

function isRtl;
input [31:0] insn;
case(insn[6:0])
`RTL:	isRtl = TRUE;
`RTL2:	isRtl = TRUE;
default:	isRtl = FALSE;
endcase
endfunction

// Set the target register field. Some op's need this set to zero in
// order to prevent a register from being updated. Other op's use the
// target register field from the instruction.
// If in user mode then don't allow updating register #24 (the task
// register). This check must be done in the RF stage so that bypass
// multiplexers are affected as well. It cannot be done at the WB
// stage.
function [5:0] xRt;
input [31:0] ir;
input km;
casex(ir[6:0])
`RR:
	case(ir[31:25])
	`MTSPR,`FENCE,`CHK:
		xRt = 6'd0;
	`PCTRL:
		xRt = (km || ir[16:12]!=5'd24) ? {1'b0,ir[16:12]} : 6'd0;
	`FIX2FLT,`FLT2FIX,`FMOV,`FNEG,`FABS,`MTFP,`MV2FLT:
		xRt = {1'b1,ir[16:12]};
	default:	xRt = (km || ir[16:12]!=5'd24) ? {1'b0,ir[16:12]} : 6'd0;
	endcase
`BRA,`Bcc,`BEQS,`BNES,`BRK,`IMM,`IMM10,`NOP,`CHKI:
	xRt = 6'd0;
`PUSHF,`SFD,`SFDX,
`SB,`SC,`SH,`SW,`SWCR,`SBX,`SCX,`SHX,`SWX,`INC,`INCX,
`RTL,`RTL2,`PUSH,`PEA,`PMW:
	xRt = 6'd0;
`PUSHPOP:
	if (ir[15:12]<4'h2)
		xRt = 6'd0;
	else
		xRt = (km || ir[12:7]!={1'b0,5'd24}) ? ir[12:7] : 6'd0;
`BSR,`RTS,`RTS2:	xRt = 6'h1F;
`FADD,`FSUB,`FMUL,`FDIV,
`LDFI,`LFD,`LFDX,`POPF:	xRt = {1'b1,ir[16:12]};
`LDIQ,`ADDQ:	xRt = (km || ir[11:7]!=5'd24) ? {1'b0,ir[11:7]} : 6'd0;
`MOV2:	xRt = (km || {ir[0],ir[15:12]}!=5'd24) ? {1'b0,ir[0],ir[15:12]} : 6'd0;
default:	xRt = (km || ir[16:12]!=5'd24) ? {1'b0,ir[16:12]} : 6'd0;
endcase
endfunction		

// Determine when the first operand is automatically valid. Not actually that
// often as many instructions require the 'A' operand.
function sourceA_v;
input [31:0] insn;
casex(insn[6:0])
`RR:
	case(insn[31:25])
	`PCTRL:	sourceA_v = TRUE;
	default:	sourceA_v = FALSE;
	endcase
`PCTRL2:
`IMM,`IMM10,`LDIQ,`LDI,`LDIF,`NOP,`BSR,`BRA,`BRK,`SYS:
	sourceA_v = TRUE;
default: sourceA_v = FALSE;
endcase
endfunction

// Determine when the second operand is automatically valid. This occurs when
// the 'B' operand isn't needed.
function sourceB_v;
input [31:0] insn;
casex(insn[6:0])
`RR:
	case(insn[31:25])
	`PCTRL:	sourceB_v = TRUE;
	`CPUID,`MTSPR,`MFSPR,
	`SXB,`SXC,`SXH,
	`NOT,`ASLI,`ROLI,`LSRI,`RORI,`ASRI,
	`FLT2FIX,`FIX2FLT,`FMOV,`MTFP,`MFFP,`FNEG,`FABS,`MV2FLT,`MV2FIX:
			sourceB_v = TRUE;
	default:	sourceB_v = FALSE;
	endcase
`MOV2,`ADDQ,`RTL,`RTS2,`PUSHPOP,`BEQS,`BNES,`RTL2,`JAL,`Bcc,`JALI,
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LEA,`LFD,`PUSHF,`PUSH,`PEA,`PMW,`POPF,`POP,`LWAR,`INC,
`PCTRL2:
`IMM,`IMM10,`LDIQ,`LDI,`LDIF,`NOP,`BSR,`BRA,`BRK,`SYS:
	sourceB_v = TRUE;
default: sourceB_v = FALSE;
endcase
endfunction

// Determine when the third operand is automatically valid. This occurs when
// the 'C' operand isn't needed.
function sourceC_v;
input [31:0] insn;
casex(insn[6:0])
`RR:
	case(insn[31:25])
	`PCTRL:	sourceC_v = TRUE;
	`CPUID,`MTSPR,`MFSPR,
	`SXB,`SXC,`SXH,
	`NOT,`ASLI,`ROLI,`LSRI,`RORI,`ASRI,
	`FLT2FIX,`FIX2FLT,`FMOV,`MTFP,`MFFP,`FNEG,`FABS,`MV2FLT,`MV2FIX:
			sourceC_v = TRUE;
	default:	sourceC_v = FALSE;
	endcase
`PUSHPOP:
	if (insn[15:12] < 4'h2)
		sourceC_v = FALSE;
	else
		sourceC_v = TRUE;
`MOV2,`ADDQ,`RTL,`RTS2,`BEQS,`BNES,`RTL2,`JAL,`Bcc,`JALI,
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LEA,`LFD,`POPF,`POP,`LWAR,`INC,
`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LEAX,`LFDX,
`PCTRL2:
`IMM,`IMM10,`LDIQ,`LDI,`LDIF,`NOP,`BSR,`BRA,`BRK,`SYS:
	sourceC_v = TRUE;
default: sourceC_v = FALSE;
endcase
endfunction

function isBrOrJmp;
input [31:0] insn;
case(insn[6:0])
`BEQS,`BNES,`Bcc,`BSR,`BRA,`JAL,`JALI:
	isBrOrJmp = TRUE;
default:	isBrOrJmp = FALSE;
endcase
endfunction

function isBra;
input [31:0] insn;
isBra = insn[6:0]==`BRA || insn[6:0]==`BSR;
endfunction

function isBcc;
input [31:0] insn;
isBcc = insn[6:0]==`Bcc;
endfunction

function isBccs;
input [31:0] insn;
isBccs = insn[6:0]==`BEQS || insn[6:0]==`BNES;
endfunction

function isBr;
input [31:0] insn;
isBr = isBra(insn)|isBcc(insn)|isBccs(insn);
endfunction

//-----------------------------------------------------------------------------
// Evaluate branch condition, compare to zero.
//-----------------------------------------------------------------------------

function takeBr;
input [31:0] insn;
input [63:0] a;

case(insn[6:0])
`BEQS:	takeBr = ~|a;
`BNES:	takeBr =  |a;
`Bcc:
	case(insn[14:12])
	`BEQ:	takeBr = ~|a;
	`BNE:	takeBr =  |a;
	`BGT:	takeBr = (~a[63] & |a[62:0]);
	`BGE:	takeBr = ~a[63];
	`BLT:	takeBr = a[63];
	`BLE:	takeBr = (a[63] | ~|a[63:0]);
	default:	takeBr = FALSE;
	endcase
endcase
endfunction


    assign fetchbuf0_instr = (fetchbuf == 1'b0) ? fetchbufA_instr : fetchbufC_instr;
    assign fetchbuf0_v     = (fetchbuf == 1'b0) ? fetchbufA_v     : fetchbufC_v    ;
    assign fetchbuf0_pc    = (fetchbuf == 1'b0) ? fetchbufA_pc    : fetchbufC_pc   ;
    assign fetchbuf1_instr = (fetchbuf == 1'b0) ? fetchbufB_instr : fetchbufD_instr;
    assign fetchbuf1_v     = (fetchbuf == 1'b0) ? fetchbufB_v     : fetchbufD_v    ;
    assign fetchbuf1_pc    = (fetchbuf == 1'b0) ? fetchbufB_pc    : fetchbufD_pc   ;

    assign fetchbuf0_mem   = (fetchbuf == 1'b0) ? isMem(fetchbufA_instr[6:0]) : isMem(fetchbufC_instr[6:0]);
    assign fetchbuf0_jmp   = (fetchbuf == 1'b0)
				? (fetchbufA_instr[`INSTRUCTION_OP] == `BEQ || fetchbufA_instr[`INSTRUCTION_OP] == `JALR)
				: (fetchbufC_instr[`INSTRUCTION_OP] == `BEQ || fetchbufC_instr[`INSTRUCTION_OP] == `JALR);
    assign fetchbuf0_rfw   = (fetchbuf == 1'b0) ? isRFW(fetchbufA_instr) : isRFW(fetchbufC_instr);

    assign fetchbuf1_mem   = (fetchbuf == 1'b0) ? isMem(fetchbufB_instr[6:0]) : isMem(fetchbufD_instr[6:0]);

    assign fetchbuf1_jmp   = (fetchbuf == 1'b0)
				? (fetchbufB_instr[`INSTRUCTION_OP] == `BEQ || fetchbufB_instr[`INSTRUCTION_OP] == `JALR)
				: (fetchbufD_instr[`INSTRUCTION_OP] == `BEQ || fetchbufD_instr[`INSTRUCTION_OP] == `JALR);
    assign fetchbuf1_rfw   = (fetchbuf == 1'b0) ? isRFW(fetchbufB_instr) : isRFW(fetchbufD_instr);
	
	assign fetchbuf0_Ra = (isPop(fetchbuf0_instr)|isRts(fetchbuf0_instr)) ? 6'h1E : raFP(fetchbuf0_instr) ? {1'b1,fetchbuf0_instr[11:7]} : {1'b0,fetchbuf0_instr[11:7] };
	assign fetchbuf0_Rb = rbFP(fetchbuf0_instr) ? {1'b1,fetchbuf0_instr[21:17]} : {1'b0,fetchbuf0_instr[21:17] };
	assign fetchbuf0_Rc = (isPush(fetchbuf0_instr) ? 6'h1E : isRtl(fetchbuf0_instr) ? 6'h1F : {rcFP(fetchbuf0_instr),fetchbuf0_instr[16:12]};
	assign fetchbuf0_Rt = xRt(fetchbuf0_instr,km);

	assign fetchbuf1_Ra = (isPop(fetchbuf1_instr)|isRts(fetchbuf1_instr)) ? 6'h1E : raFP(fetchbuf1_instr) ? {1'b1,fetchbuf1_instr[11:7]} : {1'b0,fetchbuf1_instr[11:7] };
	assign fetchbuf1_Rb = rbFP(fetchbuf1_instr) ? {1'b1,fetchbuf1_instr[21:17]} : {1'b0,fetchbuf1_instr[21:17] };
	assign fetchbuf1_Rc = (isPush(fetchbuf1_instr) ? 6'h1E : isRtl(fetchbuf1_instr) ? 6'h1F : {rcFP(fetchbuf1_instr),fetchbuf1_instr[16:12]};
	assign fetchbuf1_Rt = xRt(fetchbuf1_instr,km);

    //
    // set branchback and backpc values ... ignore branches in fetchbuf slots not ready for enqueue yet
    //
    wire branchback0 = ({fetchbuf0_v && (fetchbuf0_opcode==`Bcc || fetchbuf0_opcode==`BEQS || fetchbuf0_opcode==`BNES) && predictTaken0});
    wire branchback1 = ({fetchbuf1_v && (fetchbuf1_opcode==`Bcc || fetchbuf1_opcode==`BEQS || fetchbuf1_opcode==`BNES) && predictTaken1});
    assign branchback = branchback0|branchback1;

	always @*
	    case (fetchbuf0_opcode)
		`BEQS:	backpc0 <= fetchbuf0_pc + {{59{fetchbuf0_instr[15]}},fetchbuf0_instr[15:12],1'b0};
		`BNES:	backpc0 <= fetchbuf0_pc + {{59{fetchbuf0_instr[15]}},fetchbuf0_instr[15:12],1'b0};
		`Bcc:	backpc0 <= fetchbuf0_pc + {{48{fetchbuf0_instr[31]}},fetchbuf0_instr[31:17],1'b0};
		default:	backpc0 <= 32'd0;
		endcase
	always @*
	    case (fetchbuf1_opcode)
		`BEQS:	backpc1 <= fetchbuf1_pc + {{59{fetchbuf1_instr[15]}},fetchbuf1_instr[15:12],1'b0};
		`BNES:	backpc1 <= fetchbuf1_pc + {{59{fetchbuf1_instr[15]}},fetchbuf1_instr[15:12],1'b0};
		`Bcc:	backpc1 <= fetchbuf1_pc + {{48{fetchbuf1_instr[31]}},fetchbuf1_instr[31:17],1'b0};
		default:	backpc1 <= 32'd0;
		endcase
		
    assign backpc = branchback0 ? backpc0 : backpc1;

    //
    // BRANCH-MISS LOGIC: livetarget
    //
    // livetarget implies that there is a not-to-be-stomped instruction that targets the register in question
    // therefore, if it is zero it implies the rf_v value should become VALID on a branchmiss
    // 
	for (jj = 1; jj < 64; jj = jj + 1)
	begin
		livetarget[jj] = 0;
		for (kk = 0; kk < 8; kk = kk + 1)
			livetarget[jj] |= iqentry_livetarget[kk][jj];
	end

	for (kk = 0; kk < 8; kk = kk + 1)
		iqentry_livetarget[kk] = {63{iqentry_v[kk]}} & {63 {~iqentry_stomp[kk]}} & iq_out[kk];


    //
    // BRANCH-MISS LOGIC: latestID
    //
    // latestID is the instruction queue ID of the newest instruction (latest) that targets
    // a particular register.  looks a lot like scheduling logic, but in reverse.
    // 
	for (kk = 0; kk < 8; kk = kk + 1)
		iqentry_latestID[kk] =  (missid == kk || ((iqentry_livetarget[kk] & iqentry_cumulative[kk+1]) == 63'd0))
				    ? iqentry_livetarget[kk] : 63'd0;
	for (kk = 0; kk < 8; kk = kk + 1)
		iqentry_cumulative[kk] = (missid == kk)
				    ? iqentry_livetarget[kk]
				    : iqentry_livetarget[kk] | iqentry_cumulative[kk+1];
		
	for (kk = 0; kk < 8; kk = kk + 1)
		iqentry_source[kk] = |iqentry_latestID[kk];


    //
    // additional logic for ISSUE
    //
    // for the moment, we look at ALU-input buffers to allow back-to-back issue of 
    // dependent instructions ... we do not, however, look ahead for DRAM requests 
    // that will become valid in the next cycle.  instead, these have to propagate
    // their results into the IQ entry directly, at which point it becomes issue-able
    //

    // note that, for all intents & purposes, iqentry_done == iqentry_agen ... no need to duplicate
	for (kk = 0; kk < 8; kk = kk + 1)
	begin
		iqentry_issue[kk] = (iqentry_v[kk] && !iqentry_out[kk] && !iqentry_agen[kk]
				&& (head0 == kk || ~|iqentry_islot[(kk-1)&7] || (iqentry_islot[(kk-1)&7] == 2'b01 && ~iqentry_issue[(kk-1)&7]))
				&& (iqentry_a0_v[kk] 
				    || (iqentry_a0_s[kk] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a0_s[kk] == alu1_sourceid && alu1_dataready))
				&& (iqentry_a1_v[kk] 
				    || (iqentry_a1_s[kk] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a1_s[kk] == alu1_sourceid && alu1_dataready))
				&& (iqentry_a2_v[kk] 
				    || (iqentry_mem[kk] & ~iqentry_agen[kk])
				    || (iqentry_a2_s[kk] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a2_s[kk] == alu1_sourceid && alu1_dataready)));
		iqentry_islot[kk] = (head0 == kk) ? 2'b00
				: (iqentry_islot[(kk-1)&7] == 2'b11) ? 2'b11
				: (iqentry_islot[(kk-1)&7] + {1'b0, iqentry_issue[(kk-1)&7]});
	end

    // 
    // additional logic for handling a branch miss (STOMP logic)
    //
    assign
		iqentry_stomp[0] = branchmiss && iqentry_v[0] && head0 != 3'd0 && (missid == 3'd7 || iqentry_stomp[7]),
	    iqentry_stomp[1] = branchmiss && iqentry_v[1] && head0 != 3'd1 && (missid == 3'd0 || iqentry_stomp[0]),
	    iqentry_stomp[2] = branchmiss && iqentry_v[2] && head0 != 3'd2 && (missid == 3'd1 || iqentry_stomp[1]),
	    iqentry_stomp[3] = branchmiss && iqentry_v[3] && head0 != 3'd3 && (missid == 3'd2 || iqentry_stomp[2]),
	    iqentry_stomp[4] = branchmiss && iqentry_v[4] && head0 != 3'd4 && (missid == 3'd3 || iqentry_stomp[3]),
	    iqentry_stomp[5] = branchmiss && iqentry_v[5] && head0 != 3'd5 && (missid == 3'd4 || iqentry_stomp[4]),
	    iqentry_stomp[6] = branchmiss && iqentry_v[6] && head0 != 3'd6 && (missid == 3'd5 || iqentry_stomp[5]),
	    iqentry_stomp[7] = branchmiss && iqentry_v[7] && head0 != 3'd7 && (missid == 3'd6 || iqentry_stomp[6]);

    //
    // EXECUTE
    //

wire [63:0] logico0;
wire [63:0] shifto0;
wire [63:0] btfldo0;

FISA64_logic u5
(
	.insn(alu0_insn),
	.a(alu0_argA),
	.b(alu0_argB),
	.imm(alu0_argI),
	.res(logico0)
);

FISA64_shift u6
(
	.insn(alu0_insn),
	.a(alu0_argA),
	.b(alu0_argB),
	.imm(alu0_argI),
	.res(shifto0)
	.rolo()
);

FISA64_bitfield u3
(
	.op(alu0_insn[31:29]),
	.a(alu0_argA),
	.b(alu0_argB),
	.imm(alu0_insn[11:7]),
	.m(alu0_insn[28:17]),
	.o(btfldo0),
	.masko()
);

wire signed [63:0] alu0_argAs = alu0_argA;
wire signed [63:0] alu0_argBs = alu0_argB;
wire signed [63:0] alu0_argIs = alu0_argI;
wire alu0_lti = alu0_argAs < alu0_argIs;
wire alu0_eqi = alu0_argA == alu0_argI;
wire alu0_ltui = alu0_argA < alu0_argI;
wire alu0_lt = alu0_argAs < alu0_argBs;
wire alu0_ltu = alu0_argA < alu0_argB;
wire alu0_eq = alu0_argA == alu0_argB;

	always @*
	casex(alu0_insn[6:0])
	`BSR:	alu0_bus <= alu0_pc + 64'd4;
	`JAL:	alu0_bus <= alu0_pc + ((wisImm&&tisImm) ? 64'd12:wopcode[6:1]==6'b001000 ? 64'd6 : wisImm ? 64'd8 : 64'd4);
	`JALI:	alu0_bus <= alu0_pc + ((wisImm&&tisImm) ? 64'd12:wopcode[6:1]==6'b001000 ? 64'd6 : wisImm ? 64'd8 : 64'd4);
	`ADD:	alu0_bus <= alu0_argA + alu0_argI;
	`ADDU:	alu0_bus <= alu0_argA + alu0_argI;
	`SUB:	alu0_bus <= alu0_argA - alu0_argI;
	`SUBU:	alu0_bus <= alu0_argA - alu0_argI;
	`CMP:	alu0_bus <= alu0_lti ? 64'hFFFFFFFFFFFFFFFF : alu0_eqi ? 64'd0 : 64'd1;
	`CMPU:	alu0_bus <= alu0_ltui ? 64'hFFFFFFFFFFFFFFFF : alu0_eqi ? 64'd0 : 64'd1;
	// need the following so bypass muxing works
	`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:
			alu0_bus <= md0_res;
	`AND,`OR,`EOR:	
			alu0_bus <= logico0;
	`LDI:	alu0_bus <= alu0_argI;
	`LDFI:	alu0_bus <= alu0_argI;
	`FADD,`FSUB,`FCMP,`FMUL,`FDIV:
			alu0_bus <= fp0_res;
	`POPF:	alu0_bus <= mem0_res;
	`LFD:	alu0_bus <= mem0_res;
	`LFDX:	alu0_bus <= mem0_res;
	`RR:
		case(alu0_insn[31:25])
		`MFSPR:
			if (km) begin
				casex(alu0_insn[24:17]|alu0_argA[7:0])
				`CR0:		alu0_bus <= cr0;
				`TICK:		alu0_bus <= tick;
				`CLK:		alu0_bus <= clk_throttle_new;
				`DBPC:		alu0_bus <= dbpc;
				`EPC:		alu0_bus <= epc;
				`IPC:		alu0_bus <= ipc;
				`VBR:		alu0_bus <= vbr;
				`BEAR:		alu0_bus <= bear;
				`VECNO:		alu0_bus <= vecno;
				`MULH:		alu0_bus <= p[127:64];
				`ISP:		alu0_bus <= isp;
				`ESP:		alu0_bus <= esp;
				`DSP:		alu0_bus <= dsp;
				`EA:		alu0_bus <= ea;
				`TAGS:		alu0_bus <= lottag;
				`LOTGRP:	alu0_bus <= {lotgrp[5],lotgrp[4],lotgrp[3],lotgrp[2],lotgrp[1],lotgrp[0]};
				`CASREG:	alu0_bus <= casreg;
				`MYSTREG:	alu0_bus <= mystreg;
				`DBCTRL:	alu0_bus <= dbctrl;
				`DBAD0:		alu0_bus <= dbad0;
				`DBAD1:		alu0_bus <= dbad1;
				`DBAD2:		alu0_bus <= dbad2;
				`DBAD3:		alu0_bus <= dbad3;
				`DBSTAT:	alu0_bus <= dbstat;
	`ifdef FLOAT
				`FPSCR:
					begin
						alu0_bus[27] <= dbl0_divide_by_zero_xe;
						alu0_bus[26] <= dbl0_underflow_xe;
						alu0_bus[25] <= dbl0_overflow_xe;
						alu0_bus[24] <= dbl0_invalid_op_xe;
						alu0_bus[19] <= dbl0_neg;
						alu0_bus[18] <= dbl0_pos;
						alu0_bus[17] <= dbl0_zero;
						alu0_bus[16] <= dbl0_nan;
						alu0_bus[13] <= dbl0_divide_by_zero_xo;
						alu0_bus[12] <= dbl0_underflow_xo;
						alu0_bus[11] <= dbl0_overflow_xo;
						alu0_bus[10] <= dbl0_invalid_op_xo;
						alu0_bus[9] <= dbl0_g_xo;
						alu0_bus[3] <= dbl0_zerozero;
						alu0_bus[2] <= dbl0_infdiv;
					end
	`endif
				default:	alu0_bus <= 64'd0;
				endcase
			end
			else begin
				casex(xir[24:17]|a[7:0])
				`MYSTREG:	alu0_bus <= mystreg;
				`MULH:		alu0_bus <= alu0_p[127:64];
				default:	alu0_bus <= 64'd0;
				endcase
			end
		`PCTRL:
			case(alu0_insn[21:17])
			`RTI:	alu0_bus <= isp;
			`RTE:	alu0_bus <= esp;
			`RTD:	alu0_bus <= dsp;
			default:	alu0_bus <= 64'd0;
			endcase
		`ADD:	alu0_bus <= alu0_argA + alu0_argB;
		`ADDU:	alu0_bus <= alu0_argA + alu0_argB;
		`SUB:	alu0_bus <= alu0_argA - alu0_argB;
		`SUBU:	alu0_bus <= alu0_argA - alu0_argB;
		`CMP:	alu0_bus <= alu0_lt ? 64'hFFFFFFFFFFFFFFFF : alu0_eq ? 64'd0 : 64'd1;
		`CMPU:	alu0_bus <= alu0_ltu ? 64'hFFFFFFFFFFFFFFFF : alu0_eq ? 64'd0 : 64'd1;
		`MUL:	alu0_bus <= md0_res;	// need the following so bypass muxing works
		`MULU:	alu0_bus <= md0_res;
		`DIV:	alu0_bus <= md0_res;
		`DIVU:	alu0_bus <= md0_res;
		`MOD:	alu0_bus <= md0_res;
		`MODU:	alu0_bus <= md0_res;
		`NOT,`AND,`OR,`EOR,`NAND,`NOR,`ENOR:
				alu0_bus <= logico0;
		`SLLI,`SLL,`SRLI,`SRL,`SRAI,`SRA,`ROL,`ROLI,`ROR,`RORI:	
				alu0_bus <= shifto0;
		`SXB:	alu0_bus <= {{56{alu0_argA[7]}},alu0_argA[7:0]};
		`SXC:	alu0_bus <= {{48{alu0_argA[15]}},alu0_argA[15:0]};
		`SXH:	alu0_bus <= {{32{alu0_argA[31]}},alu0_argA[31:0]};
		`CPUID:
			case(alu0_argA[3:0]|alu0_insn[20:17])
			4'd0:	alu0_bus <= {rack_num,box_num,board_num,chip_num,core_num};
			4'd2:	alu0_bus <= "Finitron";
			4'd3:	alu0_bus <= "";
			4'd4:	alu0_bus <= "FISA64  ";
			4'd5:	alu0_bus <= "";
			4'd8:	alu0_bus <= 1;
			default:	alu0_bus <= 64'h0;
			endcase
		`FIX2FLT,`FLT2FIX,`MV2FIX,`MV2FLT:
				alu0_bus <= fp0_res;
		`FMOV:	alu0_bus <= alu0_argA;
		`MTFP:	alu0_bus <= alu0_argA;
		`MFFP:	alu0_bus <= alu0_argA;
		`FNEG:	alu0_bus <= {^alu0_argA[63],alu0_argA[62:0]};
		`FABS:	alu0_bus <= {1'b0,alu0_argA[62:0]};
		default:	alu0_bus <= 64'd0;
		endcase
	`MOV2:	alu0_bus <= alu0_argA;
	`ADDQ:	alu0_bus <= alu0_argA + alu0_argI;
	`BTFLD:	alu0_bus <= btfldo0;
	`LEA:	alu0_bus <= alu0_argA + alu0_argI;
	`LEAX:	alu0_bus <= alu0_argA + (alu0_argB << xir[23:22]) + alu0_argI;
	`PMW:	alu0_bus <= mem0_res;
	`POP:	alu0_bus <= mem0_res;
	`PUSHPOP:	alu0_bus <= mem0_res;	// POP
	`RTS:	alu0_bus <= mem0_res;
	`RTS2:	alu0_bus <= mem0_res;
	`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWAR,`INC,`CAS,`JALI,
	`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`INCX:
			alu0_bus <= mem0_res;
	default:	alu0_bus <= 64'd0;
	endcase

wire [63:0] logico1;
wire [63:0] shifto1;
wire [63:0] btfldo1;

FISA64_logic u15
(
	.insn(alu1_insn),
	.a(alu1_argA),
	.b(alu1_argB),
	.imm(alu1_argI),
	.res(logico1)
);

FISA64_shift u16
(
	.insn(alu1_insn),
	.a(alu1_argA),
	.b(alu1_argB),
	.imm(alu1_argI),
	.res(shifto1)
	.rolo()
);

FISA64_bitfield u13
(
	.op(alu1_insn[31:29]),
	.a(alu1_argA),
	.b(alu1_argB),
	.imm(alu1_insn[11:7]),
	.m(alu1_insn[28:17]),
	.o(btfldo1),
	.masko()
);

wire signed [63:0] alu1_argAs = alu1_argA;
wire signed [63:0] alu1_argBs = alu1_argB;
wire signed [63:0] alu1_argIs = alu1_argI;
wire alu1_lti = alu1_argAs < alu1_argIs;
wire alu1_eqi = alu1_argA == alu1_argI;
wire alu1_ltui = alu1_argA < alu1_argI;
wire alu1_lt = alu1_argAs < alu1_argBs;
wire alu1_ltu = alu1_argA < alu1_argB;
wire alu1_eq = alu1_argA == alu1_argB;

	always @*
	casex(alu1_insn[6:0])
	`BSR:	alu1_bus <= alu1_pc + 64'd4;
	`JAL:	alu1_bus <= alu1_pc + ((wisImm&&tisImm) ? 64'd12:wopcode[6:1]==6'b001000 ? 64'd6 : wisImm ? 64'd8 : 64'd4);
	`JALI:	alu1_bus <= alu1_pc + ((wisImm&&tisImm) ? 64'd12:wopcode[6:1]==6'b001000 ? 64'd6 : wisImm ? 64'd8 : 64'd4);
	`ADD:	alu1_bus <= alu1_argA + alu0_argI;
	`ADDU:	alu1_bus <= alu1_argA + alu0_argI;
	`SUB:	alu1_bus <= alu1_argA - alu0_argI;
	`SUBU:	alu1_bus <= alu1_argA - alu0_argI;
	`CMP:	alu1_bus <= alu1_lti ? 64'hFFFFFFFFFFFFFFFF : alu1_eqi ? 64'd0 : 64'd1;
	`CMPU:	alu1_bus <= alu1_ltui ? 64'hFFFFFFFFFFFFFFFF : alu1_eqi ? 64'd0 : 64'd1;
	// need the following so bypass muxing works
	`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:
			alu1_bus <= md1_res;
	`AND,`OR,`EOR:	
			alu1_bus <= logico1;
	`LDI:	alu1_bus <= alu1_argI;
	`LDFI:	alu1_bus <= alu1_argI;
	`FADD,`FSUB,`FCMP,`FMUL,`FDIV:
			alu1_bus <= fp1_res;
	`POPF:	alu1_bus <= mem1_res;
	`LFD:	alu1_bus <= mem1_res;
	`LFDX:	alu1_bus <= mem1_res;
	`RR:
		case(alu1_insn[31:25])
		`MFSPR:
			if (km) begin
				casex(alu1_insn[24:17]|alu1_argA[7:0])
				`CR0:		alu1_bus <= cr0;
				`TICK:		alu1_bus <= tick;
				`CLK:		alu1_bus <= clk_throttle_new;
				`DBPC:		alu1_bus <= dbpc;
				`EPC:		alu1_bus <= epc;
				`IPC:		alu1_bus <= ipc;
				`VBR:		alu1_bus <= vbr;
				`BEAR:		alu1_bus <= bear;
				`VECNO:		alu1_bus <= vecno;
				`MULH:		alu1_bus <= p[127:64];
				`ISP:		alu1_bus <= isp;
				`ESP:		alu1_bus <= esp;
				`DSP:		alu1_bus <= dsp;
				`EA:		alu1_bus <= ea;
				`TAGS:		alu1_bus <= lottag;
				`LOTGRP:	alu1_bus <= {lotgrp[5],lotgrp[4],lotgrp[3],lotgrp[2],lotgrp[1],lotgrp[0]};
				`CASREG:	alu1_bus <= casreg;
				`MYSTREG:	alu1_bus <= mystreg;
				`DBCTRL:	alu1_bus <= dbctrl;
				`DBAD0:		alu1_bus <= dbad0;
				`DBAD1:		alu1_bus <= dbad1;
				`DBAD2:		alu1_bus <= dbad2;
				`DBAD3:		alu1_bus <= dbad3;
				`DBSTAT:	alu1_bus <= dbstat;
	`ifdef FLOAT
				`FPSCR:
					begin
						alu1_bus[27] <= dbl1_divide_by_zero_xe;
						alu1_bus[26] <= dbl1_underflow_xe;
						alu1_bus[25] <= dbl1_overflow_xe;
						alu1_bus[24] <= dbl1_invalid_op_xe;
						alu1_bus[19] <= dbl1_neg;
						alu1_bus[18] <= dbl1_pos;
						alu1_bus[17] <= dbl1_zero;
						alu1_bus[16] <= dbl1_nan;
						alu1_bus[13] <= dbl1_divide_by_zero_xo;
						alu1_bus[12] <= dbl1_underflow_xo;
						alu1_bus[11] <= dbl1_overflow_xo;
						alu1_bus[10] <= dbl1_invalid_op_xo;
						alu1_bus[9] <= dbl1_g_xo;
						alu1_bus[3] <= dbl1_zerozero;
						alu1_bus[2] <= dbl1_infdiv;
					end
	`endif
				default:	alu1_bus <= 64'd0;
				endcase
			end
			else begin
				casex(alu1_insn[24:17]|alu1_argA[7:0])
				`MYSTREG:	alu1_bus <= mystreg;
				`MULH:		alu1_bus <= alu1_p[127:64];
				default:	alu1_bus <= 64'd0;
				endcase
			end
		`PCTRL:
			case(alu1_insn[21:17])
			`RTI:	alu1_bus <= isp;
			`RTE:	alu1_bus <= esp;
			`RTD:	alu1_bus <= dsp;
			default:	alu1_bus <= 64'd0;
			endcase
		`ADD:	alu1_bus <= alu1_argA + alu1_argB;
		`ADDU:	alu1_bus <= alu1_argA + alu1_argB;
		`SUB:	alu1_bus <= alu1_argA - alu1_argB;
		`SUBU:	alu1_bus <= alu1_argA - alu1_argB;
		`CMP:	alu1_bus <= alu1_lt ? 64'hFFFFFFFFFFFFFFFF : alu1_eq ? 64'd0 : 64'd1;
		`CMPU:	alu1_bus <= alu1_ltu ? 64'hFFFFFFFFFFFFFFFF : alu1_eq ? 64'd0 : 64'd1;
		`MUL:	alu1_bus <= md1_res;	// need the following so bypass muxing works
		`MULU:	alu1_bus <= md1_res;
		`DIV:	alu1_bus <= md1_res;
		`DIVU:	alu1_bus <= md1_res;
		`MOD:	alu1_bus <= md1_res;
		`MODU:	alu1_bus <= md1_res;
		`NOT,`AND,`OR,`EOR,`NAND,`NOR,`ENOR:
				alu1_bus <= logico1;
		`SLLI,`SLL,`SRLI,`SRL,`SRAI,`SRA,`ROL,`ROLI,`ROR,`RORI:	
				alu1_bus <= shifto1;
		`SXB:	alu1_bus <= {{56{alu1_argA[7]}},alu1_argA[7:0]};
		`SXC:	alu1_bus <= {{48{alu1_argA[15]}},alu1_argA[15:0]};
		`SXH:	alu1_bus <= {{32{alu1_argA[31]}},alu1_argA[31:0]};
		`CPUID:
			case(alu1_argA[3:0]|alu1_insn[20:17])
			4'd0:	alu1_bus <= {rack_num,box_num,board_num,chip_num,core_num};
			4'd2:	alu1_bus <= "Finitron";
			4'd3:	alu1_bus <= "";
			4'd4:	alu1_bus <= "FISA64  ";
			4'd5:	alu1_bus <= "";
			4'd8:	alu1_bus <= 1;
			default:	alu1_bus <= 64'h0;
			endcase
		`FIX2FLT,`FLT2FIX,`MV2FIX,`MV2FLT:
				alu1_bus <= fp1_res;
		`FMOV:	alu1_bus <= alu1_argA;
		`MTFP:	alu1_bus <= alu1_argA;
		`MFFP:	alu1_bus <= alu1_argA;
		`FNEG:	alu1_bus <= {^alu1_argA[63],alu1_argA[62:0]};
		`FABS:	alu1_bus <= {1'b0,alu1_argA[62:0]};
		default:	alu1_bus <= 64'd0;
		endcase
	`MOV2:	alu1_bus <= alu1_argA;
	`ADDQ:	alu1_bus <= alu1_argA + alu1_argI;
	`BTFLD:	alu1_bus <= btfldo1;
	`LEA:	alu1_bus <= alu1_argA + alu1_argI;
	`LEAX:	alu1_bus <= alu1_argA + (alu1_argB << xir[23:22]) + alu1_argI;
	`PMW:	alu1_bus <= mem1_res;
	`POP:	alu1_bus <= mem1_res;
	`PUSHPOP:	alu1_bus <= mem1_res;	// POP
	`RTS:	alu1_bus <= mem1_res;
	`RTS2:	alu1_bus <= mem1_res;
	`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWAR,`INC,`CAS,`JALI,
	`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`INCX:
			alu1_bus <= mem1_res;
	default:	alu1_bus <= 64'd0;
	endcase

    assign  alu0_v = alu0_dataready,
	    alu1_v = alu1_dataready;

    assign  alu0_id = alu0_sourceid,
	    alu1_id = alu1_sourceid;

	always @*
		case(alu0_insn[6:0])
		`RTS,`RTS2:	alu0_misspc = alu0_argA;
		`RTL,`RTL2:	alu0_misspc = alu0_argC;
		`JAL:	alu0_misspc = alu0_argA + {alu0_argI,1'b0};
		`JALI:  alu0_misspc = alu0_argA;
		`BRA,`BSR:	alu0_misspc = alu0_pc + alu0_insnsz + {alu0_argI,1'b0};
		`Bcc,`BEQS,`BNES:
			if (alu0_bt)
				alu0_misspc = alu0_pc + alu0_insnsz;
			else
				alu0_misspc = alu0_pc + alu0_insnsz + {alu0_argI,1'b0};
		default:	alu0_misspc = alu0_pc + alu0_insnsz;
		endcase

	always @*
		case(alu1_insn[6:0])
		`RTS,`RTS2:	alu1_misspc = alu1_argA;
		`RTL,`RTL2:	alu1_misspc = alu1_argC;
		`JAL:	alu1_misspc = alu1_argA + {alu1_argI,1'b0};
		`JALI:  alu1_misspc = alu1_argA;
		`BRA,`BSR:	alu1_misspc = alu1_pc + alu1_insnsz + {alu1_argI,1'b0};
		`Bcc,`BEQS,`BNES:
			if (alu1_bt)
				alu1_misspc = alu1_pc + alu1_insnsz;
			else
				alu1_misspc = alu1_pc + alu1_insnsz + {alu1_argI,1'b0};
		default:	alu1_misspc = alu1_pc + alu1_insnsz;
		endcase

    assign alu0_branchmiss = alu0_dataready && (((takeBr(alu0_insn,alu0_argA) && ~alu0_bt) || (~takeBr(alu0_insn,alu0_argA) && alu0_bt)) ||
				alu0_insn[6:0]==`JAL || alu0_insn[6:0]==`JALI || isBra(alu0_insn) || isRts(alu0_insn) || isRtl(alu0_insn));
				
    assign alu1_branchmiss = alu1_dataready && (((takeBr(alu1_insn,alu1_argA) && ~alu1_bt) || (~takeBr(alu1_insn,alu1_argA) && alu1_bt)) ||
				alu1_insn[6:0]==`JAL || alu1_insn[6:0]==`JALI || isBra(alu1_insn) || isRts(alu1_insn) || isRtl(alu1_insn));

    assign  branchmiss = (alu0_branchmiss | alu1_branchmiss),
	    misspc = (alu0_branchmiss ? alu0_misspc : alu1_misspc),
	    missid = (alu0_branchmiss ? alu0_sourceid : alu1_sourceid);

   //
    // additional DRAM-enqueue logic

    assign dram_avail = (dram0 == `DRAMSLOT_AVAIL || dram1 == `DRAMSLOT_AVAIL || dram2 == `DRAMSLOT_AVAIL);

    assign  iqentry_memopsvalid[0] = (iqentry_mem[0] & iqentry_a2_v[0] & iqentry_agen[0]),
	    iqentry_memopsvalid[1] = (iqentry_mem[1] & iqentry_a2_v[1] & iqentry_agen[1]),
	    iqentry_memopsvalid[2] = (iqentry_mem[2] & iqentry_a2_v[2] & iqentry_agen[2]),
	    iqentry_memopsvalid[3] = (iqentry_mem[3] & iqentry_a2_v[3] & iqentry_agen[3]),
	    iqentry_memopsvalid[4] = (iqentry_mem[4] & iqentry_a2_v[4] & iqentry_agen[4]),
	    iqentry_memopsvalid[5] = (iqentry_mem[5] & iqentry_a2_v[5] & iqentry_agen[5]),
	    iqentry_memopsvalid[6] = (iqentry_mem[6] & iqentry_a2_v[6] & iqentry_agen[6]),
	    iqentry_memopsvalid[7] = (iqentry_mem[7] & iqentry_a2_v[7] & iqentry_agen[7]);

    assign  iqentry_memready[0] = (iqentry_v[0] & iqentry_memopsvalid[0] & ~iqentry_memissue[0] & ~iqentry_done[0] & ~iqentry_out[0] & ~iqentry_stomp[0]),
	    iqentry_memready[1] = (iqentry_v[1] & iqentry_memopsvalid[1] & ~iqentry_memissue[1] & ~iqentry_done[1] & ~iqentry_out[1] & ~iqentry_stomp[1]),
	    iqentry_memready[2] = (iqentry_v[2] & iqentry_memopsvalid[2] & ~iqentry_memissue[2] & ~iqentry_done[2] & ~iqentry_out[2] & ~iqentry_stomp[2]),
	    iqentry_memready[3] = (iqentry_v[3] & iqentry_memopsvalid[3] & ~iqentry_memissue[3] & ~iqentry_done[3] & ~iqentry_out[3] & ~iqentry_stomp[3]),
	    iqentry_memready[4] = (iqentry_v[4] & iqentry_memopsvalid[4] & ~iqentry_memissue[4] & ~iqentry_done[4] & ~iqentry_out[4] & ~iqentry_stomp[4]),
	    iqentry_memready[5] = (iqentry_v[5] & iqentry_memopsvalid[5] & ~iqentry_memissue[5] & ~iqentry_done[5] & ~iqentry_out[5] & ~iqentry_stomp[5]),
	    iqentry_memready[6] = (iqentry_v[6] & iqentry_memopsvalid[6] & ~iqentry_memissue[6] & ~iqentry_done[6] & ~iqentry_out[6] & ~iqentry_stomp[6]),
	    iqentry_memready[7] = (iqentry_v[7] & iqentry_memopsvalid[7] & ~iqentry_memissue[7] & ~iqentry_done[7] & ~iqentry_out[7] & ~iqentry_stomp[7]);

    assign outstanding_stores = (dram0 && isDramStore(dram0_insn)) || (dram1 && isDramStore(dram1_insn)) || (dram2 && isDramStore(dram2_insn));

    //
    // additional COMMIT logic
    //

    assign commit0_v = ({iqentry_v[head0], iqentry_done[head0]} == 2'b11 && ~|panic);
    assign commit1_v = ({iqentry_v[head0], iqentry_done[head0]} != 2'b10 
			&& {iqentry_v[head1], iqentry_done[head1]} == 2'b11 && ~|panic);

    assign commit0_id = {iqentry_mem[head0], head0};	// if a memory op, it has a DRAM-bus id
    assign commit1_id = {iqentry_mem[head1], head1};	// if a memory op, it has a DRAM-bus id

    assign commit0_tgt = iqentry_tgt[head0];
    assign commit1_tgt = iqentry_tgt[head1];

    assign commit0_bus = iqentry_res[head0];
    assign commit1_bus = iqentry_res[head1];


	// FETCH
	//
	// fetch two instructions from memory into the fetch buffer
	// unless either one of the buffers is still full, in which case we
	// do nothing (kinda like alpha approach)
	//
    always @(posedge clk) begin

		did_branchback <= branchback;

		if (branchmiss) begin
			$display("pc <= %h", misspc);
			pc <= misspc;
			fetchbuf <= 1'b0;
			fetchbufA_v <= 1'b0;
			fetchbufB_v <= 1'b0;
			fetchbufC_v <= 1'b0;
			fetchbufD_v <= 1'b0;
		end
		else if (take_branch) begin
			if (fetchbuf == 1'b0) begin
				case ({fetchbufA_v,fetchbufB_v,fetchbufC_v,fetchbufD_v})
				4'b0000: ;
				4'b0001: panic <= `PANIC_INVALIDFBSTATE;
				4'b0010: panic <= `PANIC_INVALIDFBSTATE;
				4'b0011: panic <= `PANIC_INVALIDFBSTATE;

				// because the first instruction has been enqueued, 
				// we must have noted this in the previous cycle.
				// therefore, pc0 and pc1 have to have been set appropriately ... so do a regular fetch
				// this looks like the following:
				//   cycle 0 - fetched a INSTR+BEQ, with fbB holding a branchback
				//   cycle 1 - enqueued fbA, waited on fbB, stalled fetch + updated pc0/pc1
				//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufB_v appropriately
				4'b0100:
					if (fetchbufB_opcode==`Bcc && predictTakenB) begin
						LD_fetchbufCD();
						fetchbufB_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else
						panic <= `PANIC_BRANCHBACK;

				4'b0101: panic <= `PANIC_INVALIDFBSTATE;
				4'b0110: panic <= `PANIC_INVALIDFBSTATE;

				// this looks like the following:
				//   cycle 0 - fetched an INSTR+BEQ, with fbB holding a branchback
				//   cycle 1 - enqueued fbA, but not fbB, recognized branchback in fbB, stalled fetch + updated pc0/pc1
				//   cycle 2 - still could not enqueue fbB, but fetched from backwards target
				//   cycle 3 - where we are now ... update fetchbufB_v appropriately
				//
				// however -- if there are backwards branches in the latter two slots, it is more complex.
				// simple solution: leave it alone and wait until we are through with the first two slots.
				4'b0111:
					if (fetchbufB_opcode==`Bcc && predictTakenB) begin
						fetchbufB_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else if (fetchbufC_opcode==`Bcc && predictTakenC) begin
						fetchbufB_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else if (fetchbufD_opcode==`Bcc && predictTakenD) begin
						fetchbufB_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else
						panic <= `PANIC_BRANCHBACK;

				// this looks like the following:
				//   cycle 0 - fetched a BEQ+INSTR, with fbA holding a branchback
				//   cycle 1 - stomped on fbB, but could not enqueue fbA, stalled fetch + updated pc0/pc1
				//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufA_v appropriately
				4'b1000:
					if (fetchbufA_opcode==`Bcc && predictTakenA) begin
						LD_fetchbufCD();
						fetchbufA_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else
						panic <= `PANIC_BRANCHBACK;

				4'b1001: panic <= `PANIC_INVALIDFBSTATE;
				4'b1010: panic <= `PANIC_INVALIDFBSTATE;

				// this looks like the following:
				//   cycle 0 - fetched a BEQ+INSTR, with fbA holding a branchback
				//   cycle 1 - stomped on fbB, but could not enqueue fbA, stalled fetch + updated pc0/pc1
				//   cycle 2 - still could not enqueue fbA, but fetched from backwards target
				//   cycle 3 - where we are now ... set fetchbufA_v appropriately
				//
				// however -- if there are backwards branches in the latter two slots, it is more complex.
				// simple solution: leave it alone and wait until we are through with the first two slots.
				4'b1011: 
					if (fetchbufA_opcode==`Bcc && predictTakenA) begin
						fetchbufA_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else if (fetchbufC_opcode==`Bcc && predictTakenC) begin
						fetchbufA_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else if (fetchbufD_opcode==`Bcc && predictTakenD) begin
						fetchbufA_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else
						panic <= `PANIC_BRANCHBACK;

				// if fbB has the branchback, can't immediately tell which of the following scenarios it is:
				//   cycle 0 - fetched a pair of instructions, one or both of which is a branchback
				//   cycle 1 - where we are now.  stomp, enqueue, and update pc0/pc1
				// or
				//   cycle 0 - fetched a INSTR+BEQ, with fbB holding a branchback
				//   cycle 1 - could not enqueue fbA or fbB, stalled fetch + updated pc0/pc1
				//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufX_v appropriately
				// if fbA has the branchback, then it is scenario 1.
				// if fbB has it: if pc0 == fbB_pc, then it is the former scenario, else it is the latter
				4'b1100:
					if (fetchbufA_opcode==`Bcc && predictTakenA) begin
						pc0 <= backpc;
						pc1 <= backpc + 1;
						fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
						fetchbufB_v <= `INV;		// stomp on it
						if (~iqentry_v[tail0])
							fetchbuf <= 1'b0;
					end
					else if (fetchbufB_opcode==`Bcc && predictTakenB) begin
						if (did_branchback) begin
							LD_fetchbufCD();
							fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
							fetchbufB_v <= iqentry_v[tail1];
							if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
								fetchbuf <= 1'b1;
						end
						else begin
							pc0 <= backpc;
							pc1 <= backpc + 1;
							fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
							fetchbufB_v <= iqentry_v[tail1];	// if it can be queued, it will
							if (~iqentry_v[tail0] & ~iqentry_v[tail1])	fetchbuf <= 1'b0;
						end
					end
					else
						panic <= `PANIC_BRANCHBACK;

				4'b1101	: panic <= `PANIC_INVALIDFBSTATE;
				4'b1110	: panic <= `PANIC_INVALIDFBSTATE;

				// this looks like the following:
				//   cycle 0 - fetched an INSTR+BEQ, with fbB holding a branchback
				//   cycle 1 - enqueued neither fbA nor fbB, recognized branchback in fbB, stalled fetch + updated pc0/pc1
				//   cycle 2 - still could not enqueue fbB, but fetched from backwards target
				//   cycle 3 - where we are now ... update fetchbufX_v appropriately
				//
				// however -- if there are backwards branches in the latter two slots, it is more complex.
				// simple solution: leave it alone and wait until we are through with the first two slots.
				4'b1111 : 
					if (fetchbufB_opcode==`Bcc && predictTakenB) begin
						fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
						fetchbufB_v <= iqentry_v[tail1];	// if it can be queued, it will
						fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
					end
					else if (fetchbufC_opcode==`Bcc && predictTakenC) begin
						// branchback is in later instructions ... do nothing
						fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
						fetchbufB_v <= iqentry_v[tail1];	// if it can be queued, it will
						fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
					end
					else if (fetchbufD_opcode==`Bcc && predictTakenD) begin
						// branchback is in later instructions ... do nothing
						fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
						fetchbufB_v <= iqentry_v[tail1];	// if it can be queued, it will
						fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
					end
					else panic <= `PANIC_BRANCHBACK;
					end
				endcase
			end
			else begin	// fetchbuf==1'b1
				case ({fetchbufC_v, fetchbufD_v, fetchbufA_v, fetchbufB_v})

				4'b0000	: ; // do nothing
				4'b0001	: panic <= `PANIC_INVALIDFBSTATE;
				4'b0010	: panic <= `PANIC_INVALIDFBSTATE;
				4'b0011	: panic <= `PANIC_INVALIDFBSTATE;	// this looks like it might be screwy fetchbuf logic

				// because the first instruction has been enqueued, 
				// we must have noted this in the previous cycle.
				// therefore, pc0 and pc1 have to have been set appropriately ... so do a regular fetch
				// this looks like the following:
				//   cycle 0 - fetched a INSTR+BEQ, with fbB holding a branchback
				//   cycle 1 - enqueued fbA, waited on fbB, stalled fetch + updated pc0/pc1
				//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufB_v appropriately
				4'b0100:
					if (fetchbufD_opcode==`Bcc && predictTakenD) begin
						LD_fetchbufAB();
						fetchbufD_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else
						panic <= `PANIC_BRANCHBACK;

				4'b0101: panic <= `PANIC_INVALIDFBSTATE;
				4'b0110: panic <= `PANIC_INVALIDFBSTATE;

				// this looks like the following:
				//   cycle 0 - fetched an INSTR+BEQ, with fbB holding a branchback
				//   cycle 1 - enqueued fbA, but not fbB, recognized branchback in fbB, stalled fetch + updated pc0/pc1
				//   cycle 2 - still could not enqueue fbB, but fetched from backwards target
				//   cycle 3 - where we are now ... update fetchbufB_v appropriately
				//
				// however -- if there are backwards branches in the latter two slots, it is more complex.
				// simple solution: leave it alone and wait until we are through with the first two slots.
				4'b0111:
					if (fetchbufD_opcode==`Bcc && predictTakenD) begin
						fetchbufD_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else if (fetchbufA_opcode==`Bcc && predictTakenA) begin
						fetchbufD_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else if (fetchbufB_opcode==`Bcc && predictTakenB) begin
						fetchbufD_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else
						panic <= `PANIC_BRANCHBACK;

				// this looks like the following:
				//   cycle 0 - fetched a BEQ+INSTR, with fbA holding a branchback
				//   cycle 1 - stomped on fbB, but could not enqueue fbA, stalled fetch + updated pc0/pc1
				//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufA_v appropriately
				4'b1000:
					if (fetchbufC_opcode==`Bcc && predictTakenC) begin
						LD_fetchbufAB();
						fetchbufC_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else
						panic <= `PANIC_BRANCHBACK;

				4'b1001: panic <= `PANIC_INVALIDFBSTATE;
				4'b1010: panic <= `PANIC_INVALIDFBSTATE;

				// this looks like the following:
				//   cycle 0 - fetched a BEQ+INSTR, with fbA holding a branchback
				//   cycle 1 - stomped on fbB, but could not enqueue fbA, stalled fetch + updated pc0/pc1
				//   cycle 2 - still could not enqueue fbA, but fetched from backwards target
				//   cycle 3 - where we are now ... set fetchbufA_v appropriately
				//
				// however -- if there are backwards branches in the latter two slots, it is more complex.
				// simple solution: leave it alone and wait until we are through with the first two slots.
				4'b1011: 
					if (fetchbufC_opcode==`Bcc && predictTakenC) begin
						fetchbufC_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else if (fetchbufA_opcode==`Bcc && predictTakenA) begin
						fetchbufC_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else if (fetchbufB_opcode==`Bcc && predictTakenB) begin
						fetchbufC_v <= iqentry_v[tail0];
						if (iqentry_v[tail0]==`INV)
							fetchbuf <= 1'b1;
					end
					else
						panic <= `PANIC_BRANCHBACK;

				// if fbB has the branchback, can't immediately tell which of the following scenarios it is:
				//   cycle 0 - fetched a pair of instructions, one or both of which is a branchback
				//   cycle 1 - where we are now.  stomp, enqueue, and update pc0/pc1
				// or
				//   cycle 0 - fetched a INSTR+BEQ, with fbB holding a branchback
				//   cycle 1 - could not enqueue fbA or fbB, stalled fetch + updated pc0/pc1
				//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufX_v appropriately
				// if fbA has the branchback, then it is scenario 1.
				// if fbB has it: if pc0 == fbB_pc, then it is the former scenario, else it is the latter
				4'b1100:
					if (fetchbufC_opcode==`Bcc && predictTakenC) begin
						pc0 <= backpc;
						pc1 <= backpc + 1;
						fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
						fetchbufD_v <= `INV;		// stomp on it
						if (~iqentry_v[tail0])
							fetchbuf <= 1'b0;
					end
					else if (fetchbufD_opcode==`Bcc && predictTakenD) begin
						if (did_branchback) begin
							LD_fetchbufAB();
							fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
							fetchbufD_v <= iqentry_v[tail1];
							if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
								fetchbuf <= 1'b1;
						end
						else begin
							pc0 <= backpc;
							pc1 <= backpc + 1;
							fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
							fetchbufD_v <= iqentry_v[tail1];	// if it can be queued, it will
							if (~iqentry_v[tail0] & ~iqentry_v[tail1])	fetchbuf <= 1'b0;
						end
					end
					else
						panic <= `PANIC_BRANCHBACK;

				4'b1101	: panic <= `PANIC_INVALIDFBSTATE;
				4'b1110	: panic <= `PANIC_INVALIDFBSTATE;

				// this looks like the following:
				//   cycle 0 - fetched an INSTR+BEQ, with fbB holding a branchback
				//   cycle 1 - enqueued neither fbA nor fbB, recognized branchback in fbB, stalled fetch + updated pc0/pc1
				//   cycle 2 - still could not enqueue fbB, but fetched from backwards target
				//   cycle 3 - where we are now ... update fetchbufX_v appropriately
				//
				// however -- if there are backwards branches in the latter two slots, it is more complex.
				// simple solution: leave it alone and wait until we are through with the first two slots.
				4'b1111 : 
					if (fetchbufD_opcode==`Bcc && predictTakenD) begin
						fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
						fetchbufD_v <= iqentry_v[tail1];	// if it can be queued, it will
						fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
					end
					else if (fetchbufA_opcode==`Bcc && predictTakenA) begin
						// branchback is in later instructions ... do nothing
						fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
						fetchbufD_v <= iqentry_v[tail1];	// if it can be queued, it will
						fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
					end
					else if (fetchbufB_opcode==`Bcc && predictTakenB) begin
						// branchback is in later instructions ... do nothing
						fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
						fetchbufD_v <= iqentry_v[tail1];	// if it can be queued, it will
						fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
					end
					else panic <= `PANIC_BRANCHBACK;
					end
				endcase
			end
		end
		// Here, we are not taking a branch
		else begin
				//
				// update fetchbufX_v and fetchbuf ... relatively simple, as
				// there are no backwards branches in the mix
				if (fetchbuf == 1'b0) case ({fetchbufA_v, fetchbufB_v, ~iqentry_v[tail0], ~iqentry_v[tail1]})
				4'b00_00 : ;	// do nothing
				4'b00_01 : panic <= `PANIC_INVALIDIQSTATE;
				4'b00_10 : ;	// do nothing
				4'b00_11 : ;	// do nothing
				4'b01_00 : ;	// do nothing
				4'b01_01 : panic <= `PANIC_INVALIDIQSTATE;

				4'b01_10,
				4'b01_11 : begin	// enqueue fbB and flip fetchbuf
					fetchbufB_v <= `INV;
					fetchbuf <= ~fetchbuf;
					end

				4'b10_00 : ;	// do nothing
				4'b10_01 : panic <= `PANIC_INVALIDIQSTATE;

				4'b10_10,
				4'b10_11 : begin	// enqueue fbA and flip fetchbuf
					fetchbufA_v <= `INV;
					fetchbuf <= ~fetchbuf;
					end

				4'b11_00 : ;	// do nothing
				4'b11_01 : panic <= `PANIC_INVALIDIQSTATE;

				4'b11_10 : begin	// enqueue fbA but leave fetchbuf
					fetchbufA_v <= `INV;
					end

				4'b11_11 : begin	// enqueue both and flip fetchbuf
					fetchbufA_v <= `INV;
					fetchbufB_v <= `INV;
					fetchbuf <= ~fetchbuf;
					end
				endcase
			else
				case ({fetchbufC_v, fetchbufD_v, ~iqentry_v[tail0], ~iqentry_v[tail1]})
				4'b00_00 : ;	// do nothing
				4'b00_01 : panic <= `PANIC_INVALIDIQSTATE;
				4'b00_10 : ;	// do nothing
				4'b00_11 : ;	// do nothing
				4'b01_00 : ;	// do nothing
				4'b01_01 : panic <= `PANIC_INVALIDIQSTATE;

				4'b01_10,
				4'b01_11 : begin	// enqueue fbD and flip fetchbuf
					fetchbufD_v <= `INV;
					fetchbuf <= ~fetchbuf;
					end

				4'b10_00 : ;	// do nothing
				4'b10_01 : panic <= `PANIC_INVALIDIQSTATE;

				4'b10_10,
				4'b10_11 : begin	// enqueue fbC and flip fetchbuf
					fetchbufC_v <= `INV;
					fetchbuf <= ~fetchbuf;
					end

				4'b11_00 : ;	// do nothing
				4'b11_01 : panic <= `PANIC_INVALIDIQSTATE;

				4'b11_10 : begin	// enqueue fbC but leave fetchbuf
					fetchbufC_v <= `INV;
					end

				4'b11_11 : begin	// enqueue both and flip fetchbuf
					fetchbufC_v <= `INV;
					fetchbufD_v <= `INV;
					fetchbuf <= ~fetchbuf;
					end
				endcase

			if (fetchbufA_v == `INV && fetchbufB_v == `INV) begin
				LD_fetchbufAB();
				// fetchbuf steering logic correction
				if (fetchbufC_v==`INV && fetchbufD_v==`INV && do_pcinc)
					fetchbuf <= 1'b0;
				$display("hit %b 1pc <= %h", do_pcinc, {pc[31:4],4'b00} + 32'd16);
			end
			else if (fetchbufC_v == `INV && fetchbufD_v == `INV) begin
				LD_fetchbufCD();
				$display("hit %b 2pc <= %h", do_pcinc, {pc[31:4],4'b00} + 32'd16);
			end
		end

		//
		// ENQUEUE
		//
		// place up to two instructions from the fetch buffer into slots in the IQ.
		//   note: they are placed in-order, and they are expected to be executed
		// 0, 1, or 2 of the fetch buffers may have valid data
		// 0, 1, or 2 slots in the instruction queue may be available.
		// if we notice that one of the instructions in the fetch buffer is a backwards branch,
		// predict it taken (set branchback/backpc and delete any instructions after it in fetchbuf)
		//

		//
		// COMMIT PHASE (register-file update only ... dequeue is elsewhere)
		//
		// look at head0 and head1 and let 'em write the register file if they are ready
		//
		// why is it happening here and not in another phase?
		// want to emulate a pass-through register file ... i.e. if we are reading
		// out of r3 while writing to r3, the value read is the value written.
		// requires BLOCKING assignments, so that we can read from rf[i] later.
		//
		if (commit0_v) begin
			if (!rf_v[ commit0_tgt ]) 
			rf_v[ commit0_tgt ] = rf_source[ commit0_tgt ] == commit0_id || (branchmiss && iqentry_source[ commit0_id[2:0] ]);
			if (commit0_tgt != 6'd0) $display("r%d <- %h", commit0_tgt, commit0_bus);
		end
		if (commit1_v) begin
			if (!rf_v[ commit1_tgt ]) 
			rf_v[ commit1_tgt ] = rf_source[ commit1_tgt ] == commit1_id || (branchmiss && iqentry_source[ commit1_id[2:0] ]);
			if (commit1_tgt != 6'd0) $display("r%d <- %h", commit1_tgt, commit1_bus);
		end

		rf_v[0] = 1;

		//
		// enqueue fetchbuf0 and fetchbuf1, but only if there is room, 
		// and ignore fetchbuf1 if fetchbuf0 has a backwards branch in it.
		//
		// also, do some instruction-decode ... set the operand_valid bits in the IQ
		// appropriately so that the DATAINCOMING stage does not have to look at the opcode
		//
		if (!branchmiss) 	// don't bother doing anything if there's been a branch miss

		case ({fetchbuf0_v, fetchbuf1_v})

			2'b00: ; // do nothing

			2'b01: if (iqentry_v[tail0] == `INV) begin

			iqentry_v    [tail0]    <=   `VAL;
			iqentry_done [tail0]    <=   `INV;
			iqentry_out  [tail0]    <=   `INV;
			iqentry_res  [tail0]    <=   `ZERO;
			iqentry_insn [tail0]    <=   fetchbuf1_insn; 
			iqentry_bt   [tail0]    <=   predictTaken1;
			iqentry_agen [tail0]    <=   `INV;
			iqentry_pc   [tail0]    <=   fetchbuf1_pc;
			iqentry_mem  [tail0]    <=   fetchbuf1_mem;
			iqentry_jmp  [tail0]    <=   fetchbuf1_jmp;
			iqentry_tgt  [tail0]    <=   fetchbuf1_Rt;
			iqentry_exc  [tail0]    <=   `EXC_NONE;
			iqentry_a0   [tail0]    <=   isBr(fetchbuf1_instr) ? fetchbuf1_pc : rfo1a;
			iqentry_a1   [tail0]    <=   rfo1b;
			iqentry_a2   [tail0]    <=   rfo1c;
			iqentry_a3   [tail0]    <=   isBcc(fetchbuf1_instr) ? {{48{fetchbuf1_instr[31]}},fetchbuf1_instr[31:17],1'b0} :
										 isBra(fetchbuf1_instr) ? {{38{fetchbuf1_instr[31]}},fetchbuf1_instr[31:7],1'b0} :
										 isBccs(fetchbuf1_instr) ? {{59{fetchbuf1_instr[15]}},fetchbuf1_instr[15:12],1'b0} :
										 isImm(iqentry_insn[(tail0-2)&7])&isImm(iqentry_insn[(tail0-1)&7]) ?
											{iqentry_insn[(tail0-2)&7][31:7],iqentry_insn[(tail0-2)&7][2:0],
											 iqentry_insn[(tail0-1)&7][31:7],iqentry_insn[(tail0-1)&7][2:0],
											 fetchbuf1_insn[31:17]} : isImm(iqentry_insn[(tail0-1)&7]) ?
											{{21{iqentry_insn[(tail0-1)&7][31]}},
											 iqentry_insn[(tail0-1)&7][31:7],iqentry_insn[(tail0-1)&7][2:0],
											 fetchbuf1_insn[31:17]} : isImm10(iqentry_insn[(tail0-1)&7]) ?
											{{39{iqentry_insn[(tail0-1)&7][15]}},iqentry_insn[(tail0-1)&7][15:7],
											 iqentry_insn[(tail0-1)&7][0],fetchbuf1_insn[31:17] :
											{{49{fetchbuf1_insn[31]}},fetchbuf1_insn[31:17]}
											;
			iqentry_a0_v [tail0]    <=  sourceA_v(fetchbuf1_instr) | rf_v[fetchbuf1_Ra];
			iqentry_a1_v [tail0]    <=  sourceB_v(fetchbuf1_instr) | rf_v[fetchbuf1_Rb];
			iqentry_a2_v [tail0]    <=  sourceC_v(fetchbuf1_instr) | rf_v[fetchbuf1_Rc];
			iqentry_a0_s [tail0]    <=   rf_source [fetchbuf1_Ra];
			iqentry_a1_s [tail0]    <=   rf_source [fetchbuf1_Rb];
			iqentry_a2_s [tail0]    <=   rf_source [fetchbuf1_Rc];
			tail0 <= tail0 + 1;
			tail1 <= tail1 + 1;
			if (fetchbuf1_Rt != 6'd0) begin
				rf_v[ fetchbuf1_Rt ] <= `INV;
				rf_source[ fetchbuf1_Rt ] <= { fetchbuf1_mem, tail0 };	// top bit indicates ALU/MEM bus
			end

			end

			2'b10: if (iqentry_v[tail0] == `INV) begin
			if (!(isBcc(fetchbuf0_instr)|isBccs(fetchbuf0_instr)) panic <= `PANIC_FETCHBUFBCC;
			if (!predictTaken0) panic <= `PANIC_FETCHBUFBCC;
			//
			// this should only happen when the first instruction is a BEQ-backwards and the IQ
			// happened to be full on the previous cycle (thus we deleted fetchbuf1 but did not
			// enqueue fetchbuf0) ... probably no need to check for LW -- sanity check, just in case
			//

			iqentry_v    [tail0]	<=	`VAL;
			iqentry_done [tail0]	<=	`INV;
			iqentry_out  [tail0]	<=	`INV;
			iqentry_res  [tail0]	<=	`ZERO;
			iqentry_insn [tail0]	<=	fetchbuf0_instr; 			// BEQ
			iqentry_bt   [tail0]    <=	`VAL;
			iqentry_agen [tail0]    <=	`INV;
			iqentry_pc   [tail0]    <=	fetchbuf0_pc;
			iqentry_mem  [tail0]    <=	fetchbuf0_mem;
			iqentry_jmp  [tail0]    <=	fetchbuf0_jmp;
			iqentry_tgt  [tail0]    <=	fetchbuf0_Rt;
			iqentry_exc  [tail0]    <=	`EXC_NONE;

			iqentry_a0   [tail0]    <=   isBr(fetchbuf0_instr) ? fetchbuf0_pc : rfo0a;
			iqentry_a1   [tail0]    <=   rfo0b;
			iqentry_a2   [tail0]    <=   rfo0c;
			iqentry_a3   [tail0]    <=   isBcc(fetchbuf0_instr) ? {{48{fetchbuf0_instr[31]}},fetchbuf0_instr[31:17],1'b0} :
										 isBra(fetchbuf0_instr) ? {{38{fetchbuf0_instr[31]}},fetchbuf0_instr[31:7],1'b0} :
										 isBccs(fetchbuf0_instr) ? {{59{fetchbuf0_instr[15]}},fetchbuf0_instr[15:12],1'b0} :
										 isImm(iqentry_insn[(tail0-2)&7])&isImm(iqentry_insn[(tail0-1)&7]) ?
											{iqentry_insn[(tail0-2)&7][31:7],iqentry_insn[(tail0-2)&7][2:0],
											 iqentry_insn[(tail0-1)&7][31:7],iqentry_insn[(tail0-1)&7][2:0],
											 fetchbuf0_insn[31:17]} : isImm(iqentry_insn[(tail0-1)&7]) ?
											{{21{iqentry_insn[(tail0-1)&7][31]}},
											 iqentry_insn[(tail0-1)&7][31:7],iqentry_insn[(tail0-1)&7][2:0],
											 fetchbuf0_insn[31:17]} : isImm10(iqentry_insn[(tail0-1)&7]) ?
											{{39{iqentry_insn[(tail0-1)&7][15]}},iqentry_insn[(tail0-1)&7][15:7],
											 iqentry_insn[(tail0-1)&7][0],fetchbuf0_insn[31:17] :
											{{49{fetchbuf0_insn[31]}},fetchbuf0_insn[31:17]}
											;
			iqentry_a0_v [tail0]    <=  sourceA_v(fetchbuf0_instr) | rf_v[fetchbuf0_Ra];
			iqentry_a1_v [tail0]    <=  sourceB_v(fetchbuf0_instr) | rf_v[fetchbuf0_Rb];
			iqentry_a2_v [tail0]    <=  sourceC_v(fetchbuf0_instr) | rf_v[fetchbuf0_Rc];
			iqentry_a0_s [tail0]    <=   rf_source [fetchbuf0_Ra];
			iqentry_a1_s [tail0]    <=   rf_source [fetchbuf0_Rb];
			iqentry_a2_s [tail0]    <=   rf_source [fetchbuf0_Rc];

			tail0 <= tail0 + 1;
			tail1 <= tail1 + 1;

			end

			2'b11: if (iqentry_v[tail0] == `INV) begin

			//
			// if the first instruction is a backwards branch, enqueue it & stomp on all following instructions
			//
			if (((isBcc(fetchbuf0_instr)|isBccs(fetchbuf0_instr)) && predictTaken0) || isBra(fetchbuf0_instr)) begin

				iqentry_v    [tail0]    <=	`VAL;
				iqentry_done [tail0]    <=	`INV;
				iqentry_out  [tail0]    <=	`INV;
				iqentry_res  [tail0]    <=	`ZERO;
				iqentry_insn [tail0]    <=	fetchbuf0_instr;
				iqentry_bt   [tail0]    <=	`VAL;
				iqentry_agen [tail0]    <=	`INV;
				iqentry_pc   [tail0]    <=	fetchbuf0_pc;
				iqentry_mem  [tail0]    <=	fetchbuf0_mem;
				iqentry_jmp  [tail0]    <=	fetchbuf0_jmp;
				iqentry_tgt  [tail0]    <=	fetchbuf0_Rt;
				iqentry_exc  [tail0]    <=	`EXC_NONE;

				iqentry_a0   [tail0]    <=   isBr(fetchbuf0_instr) ? fetchbuf0_pc : rfo0a;
				iqentry_a1   [tail0]    <=   rfo0b;
				iqentry_a2   [tail0]    <=   rfo0c;
				iqentry_a3   [tail0]    <=   isBcc(fetchbuf0_instr) ? {{48{fetchbuf0_instr[31]}},fetchbuf0_instr[31:17],1'b0} :
											 isBra(fetchbuf0_instr) ? {{38{fetchbuf0_instr[31]}},fetchbuf0_instr[31:7],1'b0} :
											 isBccs(fetchbuf0_instr) ? {{59{fetchbuf0_instr[15]}},fetchbuf0_instr[15:12],1'b0} :
											 isImm(iqentry_insn[(tail0-2)&7])&isImm(iqentry_insn[(tail0-1)&7]) ?
												{iqentry_insn[(tail0-2)&7][31:7],iqentry_insn[(tail0-2)&7][2:0],
												 iqentry_insn[(tail0-1)&7][31:7],iqentry_insn[(tail0-1)&7][2:0],
												 fetchbuf0_insn[31:17]} : isImm(iqentry_insn[(tail0-1)&7]) ?
												{{21{iqentry_insn[(tail0-1)&7][31]}},
												 iqentry_insn[(tail0-1)&7][31:7],iqentry_insn[(tail0-1)&7][2:0],
												 fetchbuf0_insn[31:17]} : isImm10(iqentry_insn[(tail0-1)&7]) ?
												{{39{iqentry_insn[(tail0-1)&7][15]}},iqentry_insn[(tail0-1)&7][15:7],
												 iqentry_insn[(tail0-1)&7][0],fetchbuf0_insn[31:17] :
												{{49{fetchbuf0_insn[31]}},fetchbuf0_insn[31:17]}
												;
				iqentry_a0_v [tail0]    <=  sourceA_v(fetchbuf0_instr) | rf_v[fetchbuf0_Ra];
				iqentry_a1_v [tail0]    <=  sourceB_v(fetchbuf0_instr) | rf_v[fetchbuf0_Rb];
				iqentry_a2_v [tail0]    <=  sourceC_v(fetchbuf0_instr) | rf_v[fetchbuf0_Rc];
				iqentry_a0_s [tail0]    <=   rf_source [fetchbuf0_Ra];
				iqentry_a1_s [tail0]    <=   rf_source [fetchbuf0_Rb];
				iqentry_a2_s [tail0]    <=   rf_source [fetchbuf0_Rc];

				tail0 <= tail0 + 1;
				tail1 <= tail1 + 1;

			end

			else begin	// fetchbuf0 doesn't contain a backwards branch
				//
				// so -- we can enqueue 1 or 2 instructions, depending on space in the IQ
				// update tail0/tail1 separately (at top)
				// update the rf_v and rf_source bits separately (at end)
				//   the problem is that if we do have two instructions, 
				//   they may interact with each other, so we have to be
				//   careful about where things point.
				//

				if (iqentry_v[tail1] == `INV) begin
				tail0 <= tail0 + 2;
				tail1 <= tail1 + 2;
				end
				else begin
				tail0 <= tail0 + 1;
				tail1 <= tail1 + 1;
				end

				//
				// enqueue the first instruction ...
				//
				iqentry_v    [tail0]    <=	`VAL;
				iqentry_done [tail0]    <=	`INV;
				iqentry_out  [tail0]    <=	`INV;
				iqentry_res  [tail0]    <=	`ZERO;
				iqentry_insn [tail0]    <=	fetchbuf0_instr;
				iqentry_bt   [tail0]    <=	`VAL;
				iqentry_agen [tail0]    <=	`INV;
				iqentry_pc   [tail0]    <=	fetchbuf0_pc;
				iqentry_mem  [tail0]    <=	fetchbuf0_mem;
				iqentry_jmp  [tail0]    <=	fetchbuf0_jmp;
				iqentry_tgt  [tail0]    <=	fetchbuf0_Rt;
				iqentry_exc  [tail0]    <=	`EXC_NONE;

				iqentry_a0   [tail0]    <=   isBr(fetchbuf0_instr) ? fetchbuf0_pc : rfo0a;
				iqentry_a1   [tail0]    <=   rfo0b;
				iqentry_a2   [tail0]    <=   rfo0c;
				iqentry_a3   [tail0]    <=   isBcc(fetchbuf0_instr) ? {{48{fetchbuf0_instr[31]}},fetchbuf0_instr[31:17],1'b0} :
											 isBra(fetchbuf0_instr) ? {{38{fetchbuf0_instr[31]}},fetchbuf0_instr[31:7],1'b0} :
											 isBccs(fetchbuf0_instr) ? {{59{fetchbuf0_instr[15]}},fetchbuf0_instr[15:12],1'b0} :
											 isImm(iqentry_insn[(tail0-2)&7])&isImm(iqentry_insn[(tail0-1)&7]) ?
												{iqentry_insn[(tail0-2)&7][31:7],iqentry_insn[(tail0-2)&7][2:0],
												 iqentry_insn[(tail0-1)&7][31:7],iqentry_insn[(tail0-1)&7][2:0],
												 fetchbuf0_insn[31:17]} : isImm(iqentry_insn[(tail0-1)&7]) ?
												{{21{iqentry_insn[(tail0-1)&7][31]}},
												 iqentry_insn[(tail0-1)&7][31:7],iqentry_insn[(tail0-1)&7][2:0],
												 fetchbuf0_insn[31:17]} : isImm10(iqentry_insn[(tail0-1)&7]) ?
												{{39{iqentry_insn[(tail0-1)&7][15]}},iqentry_insn[(tail0-1)&7][15:7],
												 iqentry_insn[(tail0-1)&7][0],fetchbuf0_insn[31:17] :
												{{49{fetchbuf0_insn[31]}},fetchbuf0_insn[31:17]}
												;
				iqentry_a0_v [tail0]    <=  sourceA_v(fetchbuf0_instr) | rf_v[fetchbuf0_Ra];
				iqentry_a1_v [tail0]    <=  sourceB_v(fetchbuf0_instr) | rf_v[fetchbuf0_Rb];
				iqentry_a2_v [tail0]    <=  sourceC_v(fetchbuf0_instr) | rf_v[fetchbuf0_Rc];
				iqentry_a0_s [tail0]    <=   rf_source [fetchbuf0_Ra];
				iqentry_a1_s [tail0]    <=   rf_source [fetchbuf0_Rb];
				iqentry_a2_s [tail0]    <=   rf_source [fetchbuf0_Rc];

				//
				// if there is room for a second instruction, enqueue it
				//
				if (iqentry_v[tail1] == `INV) begin

				iqentry_v    [tail1]    <=   `VAL;
				iqentry_done [tail1]    <=   `INV;
				iqentry_out  [tail1]    <=   `INV;
				iqentry_res  [tail1]    <=   `ZERO;
				iqentry_insn [tail1]    <=   fetchbuf1_insn; 
				iqentry_bt   [tail1]    <=   predictTaken1;
				iqentry_agen [tail1]    <=   `INV;
				iqentry_pc   [tail1]    <=   fetchbuf1_pc;
				iqentry_mem  [tail1]    <=   fetchbuf1_mem;
				iqentry_jmp  [tail1]    <=   fetchbuf1_jmp;
				iqentry_tgt  [tail1]    <=   fetchbuf1_Rt;
				iqentry_exc  [tail1]    <=   `EXC_NONE;
				iqentry_a0   [tail1]    <=   isBr(fetchbuf1_instr) ? fetchbuf1_pc : rfo1a;
				iqentry_a1   [tail1]    <=   rfo1b;
				iqentry_a2   [tail1]    <=   rfo1c;
				iqentry_a3   [tail1]    <=   isBcc(fetchbuf1_instr) ? {{48{fetchbuf1_instr[31]}},fetchbuf1_instr[31:17],1'b0} :
											 isBra(fetchbuf1_instr) ? {{38{fetchbuf1_instr[31]}},fetchbuf1_instr[31:7],1'b0} :
											 isBccs(fetchbuf1_instr) ? {{59{fetchbuf1_instr[15]}},fetchbuf1_instr[15:12],1'b0} :
											 isImm(iqentry_insn[(tail1-2)&7])&isImm(fetchbuf0_instr) ?
												{iqentry_insn[(tail1-2)&7][31:7],iqentry_insn[(tail1-2)&7][2:0],
												 fetchbuf0_instr[31:7],fetchbuf0_instr[2:0],
												 fetchbuf1_insn[31:17]} : isImm(fetchbuf0_instr) ?
												{{21{fetchbuf0_instr[31]}},
												 fetchbuf0_instr[31:7],fetchbuf0_instr[2:0],
												 fetchbuf1_insn[31:17]} : isImm10(fetchbuf0_instr) ?
												{{39{fetchbuf0_instr[15]}},fetchbuf0_instr[15:7],
												 fetchbuf0_instr[0],fetchbuf1_insn[31:17] :
												{{49{fetchbuf1_insn[31]}},fetchbuf1_insn[31:17]}
												;
				iqentry_a0_v [tail1]    <=  sourceA_v(fetchbuf1_instr) | rf_v[fetchbuf1_Ra];
				iqentry_a1_v [tail1]    <=  sourceB_v(fetchbuf1_instr) | rf_v[fetchbuf1_Rb];
				iqentry_a2_v [tail1]    <=  sourceC_v(fetchbuf1_instr) | rf_v[fetchbuf1_Rc];
				iqentry_a0_s [tail1]    <=   rf_source [fetchbuf1_Ra];
				iqentry_a1_s [tail1]    <=   rf_source [fetchbuf1_Rb];
				iqentry_a2_s [tail1]    <=   rf_source [fetchbuf1_Rc];

				// a1/a2_v and a1/a2_s values require a bit of thinking ...

				//
				// SOURCE 1 ... 
				//
				// if the argument is an immediate or not needed, we're done
				if (sourceA_v(fetchbuf1_instr)) begin
					iqentry_a0_v [tail1] <= `VAL;
					iqentry_a0_s [tail1] <= 4'd0;
				end
				// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
				else if (fetchbuf0_Rt==6'd0) begin
					iqentry_a0_v [tail1]    <=   rf_v [fetchbuf1_Ra];
					iqentry_a0_s [tail1]    <=   rf_source [fetchbuf1_Ra];
				end
				// otherwise, previous instruction does write to RF ... see if overlap
				else if (fetchbuf1_Ra != 6'd0 && fetchbuf1_Ra == fetchbuf0_Rt) begin
					// if the previous instruction is a LW, then grab result from memq, not the iq
					iqentry_a0_v [tail1]    <=   `INV;
					iqentry_a0_s [tail1]    <=   { fetchbuf0_mem, tail0 };
				end
				// if no overlap, get info from rf_v and rf_source
				else begin
					iqentry_a0_v [tail1]    <=   rf_v [fetchbuf1_Ra];
					iqentry_a0_s [tail1]    <=   rf_source [fetchbuf1_Ra];
				end

				//
				// SOURCE 2 ... 
				//
				if (sourceB_v(fetchbuf1_instr)) begin
					iqentry_a1_v [tail1] <= `VAL;
					iqentry_a1_s [tail1] <= 4'd0;
				end
				// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
				else if (fetchbuf0_Rt==6'd0) begin
					iqentry_a1_v [tail1]    <=   rf_v [fetchbuf1_Rb];
					iqentry_a1_s [tail1]    <=   rf_source [fetchbuf1_Rb];
				end
				// otherwise, previous instruction does write to RF ... see if overlap
				else if (fetchbuf1_Rb != 6'd0 && fetchbuf1_Rb == fetchbuf0_Rt) begin
					// if the previous instruction is a LW, then grab result from memq, not the iq
					iqentry_a1_v [tail1]    <=   `INV;
					iqentry_a1_s [tail1]    <=   { fetchbuf0_mem, tail0 };
				end
				// if no overlap, get info from rf_v and rf_source
				else begin
					iqentry_a1_v [tail1]    <=   rf_v [fetchbuf1_Rb];
					iqentry_a1_s [tail1]    <=   rf_source [fetchbuf1_Rb];
				end

				//
				// SOURCE 3 ... 
				//
				if (sourceC_v(fetchbuf1_instr)) begin
					iqentry_a2_v [tail1] <= `VAL;
					iqentry_a2_s [tail1] <= 4'd0;
				end
				// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
				else if (fetchbuf0_Rt==6'd0) begin
					iqentry_a2_v [tail1]    <=   rf_v [fetchbuf1_Rc];
					iqentry_a2_s [tail1]    <=   rf_source [fetchbuf1_Rc];
				end
				// otherwise, previous instruction does write to RF ... see if overlap
				else if (fetchbuf1_Rc != 6'd0 && fetchbuf1_Rc == fetchbuf0_Rt) begin
					// if the previous instruction is a LW, then grab result from memq, not the iq
					iqentry_a2_v [tail1]    <=   `INV;
					iqentry_a2_s [tail1]    <=   { fetchbuf0_mem, tail0 };
				end
				// if no overlap, get info from rf_v and rf_source
				else begin
					iqentry_a2_v [tail1]    <=   rf_v [fetchbuf1_Rc];
					iqentry_a2_s [tail1]    <=   rf_source [fetchbuf1_Rc];
				end

				//
				// if the two instructions enqueued target the same register, 
				// make sure only the second writes to rf_v and rf_source.
				// first is allowed to update rf_v and rf_source only if the
				// second has no target (BEQ or SW)
				//
				if (fetchbuf0_Rt == fetchbuf1_Rt) begin
					if (fetchbuf1_Rt != 6'd0) begin
					rf_v[ fetchbuf1_Rt ] <= `INV;
					rf_source[ fetchbuf1_Rt ] <= { fetchbuf1_mem, tail1 };
					end
					else if (fetchbuf0_Rt != 6'd0) begin
					rf_v[ fetchbuf0_Rt ] <= `INV;
					rf_source[ fetchbuf0_Rt ] <= { fetchbuf0_mem, tail0 };
					end
				end
				else begin
					if (fetchbuf0_Rt != 6'd0) begin
					rf_v[ fetchbuf0_Rt ] <= `INV;
					rf_source[ fetchbuf0_Rt ] <= { fetchbuf0_mem, tail0 };
					end
					if (fetchbuf1_Rt != 6'd0) begin
					rf_v[ fetchbuf1_Rt ] <= `INV;
					rf_source[ fetchbuf1_Rt ] <= { fetchbuf1_mem, tail1 };
					end
				end

				end	// ends the "if IQ[tail1] is available" clause
				else begin	// only first instruction was enqueued
				if (fetchbuf0_Rt != 6'd0) begin
					rf_v[ fetchbuf0_Rt ] <= `INV;
					rf_source[ fetchbuf0_Rt ] <= {fetchbuf0_mem, tail0};
				end
				end

			end	// ends the "else fetchbuf0 doesn't have a backwards branch" clause
			end
		endcase
		else begin	// if branchmiss
			for (kk = 0; kk < 8; kk = kk + 1) begin
				if (iqentry_stomp[kk] & ~iqentry_stomp[(kk-1)&7]) begin
					tail0 <= kk;
					tail1 <= (kk+1) & 7;
				end
			end
			// otherwise, it is the last instruction in the queue that has been mispredicted ... do nothing
		end

		//
		// DATAINCOMING
		//
		// wait for operand/s to appear on alu busses and puts them into 
		// the iqentry_a1 and iqentry_a2 slots (if appropriate)
		// as well as the appropriate iqentry_res slots (and setting valid bits)
		//
		//
		// put results into the appropriate instruction entries
		//
		if (alu0_v) begin
			iqentry_res	[ alu0_id[2:0] ] <= alu0_bus;
			iqentry_exc	[ alu0_id[2:0] ] <= alu0_exc;
			iqentry_done[ alu0_id[2:0] ] <= (iqentry_op[ alu0_id[2:0] ] != `LW && iqentry_op[ alu0_id[2:0] ] != `SW);
			iqentry_out	[ alu0_id[2:0] ] <= `INV;
			iqentry_agen[ alu0_id[2:0] ] <= `VAL;
		end
		if (alu1_v) begin
			iqentry_res	[ alu1_id[2:0] ] <= alu1_bus;
			iqentry_exc	[ alu1_id[2:0] ] <= alu1_exc;
			iqentry_done[ alu1_id[2:0] ] <= (iqentry_op[ alu1_id[2:0] ] != `LW && iqentry_op[ alu1_id[2:0] ] != `SW);
			iqentry_out	[ alu1_id[2:0] ] <= `INV;
			iqentry_agen[ alu1_id[2:0] ] <= `VAL;
		end
		if (dram_v && iqentry_v[ dram_id[2:0] ] && iqentry_mem[ dram_id[2:0] ] ) begin	// if data for stomped instruction, ignore
			iqentry_res	[ dram_id[2:0] ] <= dram_bus;
			iqentry_exc	[ dram_id[2:0] ] <= dram_exc;
			iqentry_done[ dram_id[2:0] ] <= `VAL;
		end

		//
		// set the IQ entry == DONE as soon as the SW is let loose to the memory system
		//
		if (dram0 == 2'd1 && dram0_op == `SW) begin
			if ((alu0_v && dram0_id[2:0] == alu0_id[2:0]) || (alu1_v && dram0_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
			iqentry_done[ dram0_id[2:0] ] <= `VAL;
			iqentry_out[ dram0_id[2:0] ] <= `INV;
		end
		if (dram1 == 2'd1 && dram1_op == `SW) begin
			if ((alu0_v && dram1_id[2:0] == alu0_id[2:0]) || (alu1_v && dram1_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
			iqentry_done[ dram1_id[2:0] ] <= `VAL;
			iqentry_out[ dram1_id[2:0] ] <= `INV;
		end
		if (dram2 == 2'd1 && dram2_op == `SW) begin
			if ((alu0_v && dram2_id[2:0] == alu0_id[2:0]) || (alu1_v && dram2_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
			iqentry_done[ dram2_id[2:0] ] <= `VAL;
			iqentry_out[ dram2_id[2:0] ] <= `INV;
		end

		//
		// see if anybody else wants the results ... look at lots of buses:
		//  - alu0_bus
		//  - alu1_bus
		//  - dram_bus
		//  - commit0_bus
		//  - commit1_bus
		//
		for (kk = 0; kk < 8; kk = kk + 1)
		begin
			if (iqentry_a0_v[kk] == `INV && iqentry_a0_s[kk] == alu0_id && iqentry_v[kk] == `VAL && alu0_v == `VAL) begin
				iqentry_a0[kk] <= alu0_bus;
				iqentry_a0_v[kk] <= `VAL;
			end
			if (iqentry_a1_v[kk] == `INV && iqentry_a1_s[kk] == alu0_id && iqentry_v[kk] == `VAL && alu0_v == `VAL) begin
				iqentry_a1[kk] <= alu0_bus;
				iqentry_a1_v[kk] <= `VAL;
			end
			if (iqentry_a2_v[kk] == `INV && iqentry_a2_s[kk] == alu0_id && iqentry_v[kk] == `VAL && alu0_v == `VAL) begin
				iqentry_a2[kk] <= alu0_bus;
				iqentry_a2_v[kk] <= `VAL;
			end

			if (iqentry_a0_v[kk] == `INV && iqentry_a0_s[kk] == alu1_id && iqentry_v[kk] == `VAL && alu1_v == `VAL) begin
				iqentry_a0[kk] <= alu1_bus;
				iqentry_a0_v[kk] <= `VAL;
			end
			if (iqentry_a1_v[kk] == `INV && iqentry_a1_s[kk] == alu1_id && iqentry_v[kk] == `VAL && alu1_v == `VAL) begin
				iqentry_a1[kk] <= alu1_bus;
				iqentry_a1_v[kk] <= `VAL;
			end
			if (iqentry_a2_v[kk] == `INV && iqentry_a2_s[kk] == alu1_id && iqentry_v[kk] == `VAL && alu1_v == `VAL) begin
				iqentry_a2[kk] <= alu1_bus;
				iqentry_a2_v[kk] <= `VAL;
			end

			if (iqentry_a0_v[kk] == `INV && iqentry_a0_s[kk] == dram_id && iqentry_v[kk] == `VAL && dram_v == `VAL) begin
				iqentry_a0[kk] <= dram_bus;
				iqentry_a0_v[kk] <= `VAL;
			end
			if (iqentry_a1_v[kk] == `INV && iqentry_a1_s[kk] == dram_id && iqentry_v[kk] == `VAL && dram_v == `VAL) begin
				iqentry_a1[kk] <= dram_bus;
				iqentry_a1_v[kk] <= `VAL;
			end
			if (iqentry_a2_v[kk] == `INV && iqentry_a2_s[kk] == dram_id && iqentry_v[kk] == `VAL && dram_v == `VAL) begin
				iqentry_a2[kk] <= dram_bus;
				iqentry_a2_v[kk] <= `VAL;
			end

			if (iqentry_a0_v[kk] == `INV && iqentry_a0_s[kk] == commit0_id && iqentry_v[kk] == `VAL && commit0_v == `VAL) begin
				iqentry_a0[kk] <= commit0_bus;
				iqentry_a0_v[kk] <= `VAL;
			end
			if (iqentry_a1_v[kk] == `INV && iqentry_a1_s[kk] == commit0_id && iqentry_v[kk] == `VAL && commit0_v == `VAL) begin
				iqentry_a1[kk] <= commit0_bus;
				iqentry_a1_v[kk] <= `VAL;
			end
			if (iqentry_a2_v[kk] == `INV && iqentry_a2_s[kk] == commit0_id && iqentry_v[kk] == `VAL && commit0_v == `VAL) begin
				iqentry_a2[kk] <= commit0_bus;
				iqentry_a2_v[kk] <= `VAL;
			end

			if (iqentry_a0_v[kk] == `INV && iqentry_a0_s[kk] == commit1_id && iqentry_v[kk] == `VAL && commit1_v == `VAL) begin
				iqentry_a0[kk] <= commit1_bus;
				iqentry_a0_v[kk] <= `VAL;
			end
			if (iqentry_a1_v[kk] == `INV && iqentry_a1_s[kk] == commit1_id && iqentry_v[kk] == `VAL && commit1_v == `VAL) begin
				iqentry_a1[kk] <= commit1_bus;
				iqentry_a1_v[kk] <= `VAL;
			end
			if (iqentry_a2_v[kk] == `INV && iqentry_a2_s[kk] == commit1_id && iqentry_v[kk] == `VAL && commit1_v == `VAL) begin
				iqentry_a2[kk] <= commit1_bus;
				iqentry_a2_v[kk] <= `VAL;
			end
		end

		//
		// ISSUE 
		//
		// determines what instructions are ready to go, then places them
		// in the various ALU queues.  
		// also invalidates instructions following a branch-miss BEQ or any JALR (STOMP logic)
		//

		alu0_dataready <= alu0_available 
					&& ((iqentry_issue[0] && iqentry_islot[0] == 2'd0 && !iqentry_stomp[0])
					 || (iqentry_issue[1] && iqentry_islot[1] == 2'd0 && !iqentry_stomp[1])
					 || (iqentry_issue[2] && iqentry_islot[2] == 2'd0 && !iqentry_stomp[2])
					 || (iqentry_issue[3] && iqentry_islot[3] == 2'd0 && !iqentry_stomp[3])
					 || (iqentry_issue[4] && iqentry_islot[4] == 2'd0 && !iqentry_stomp[4])
					 || (iqentry_issue[5] && iqentry_islot[5] == 2'd0 && !iqentry_stomp[5])
					 || (iqentry_issue[6] && iqentry_islot[6] == 2'd0 && !iqentry_stomp[6])
					 || (iqentry_issue[7] && iqentry_islot[7] == 2'd0 && !iqentry_stomp[7]));

		alu1_dataready <= alu1_available 
					&& ((iqentry_issue[0] && iqentry_islot[0] == 2'd1 && !iqentry_stomp[0])
					 || (iqentry_issue[1] && iqentry_islot[1] == 2'd1 && !iqentry_stomp[1])
					 || (iqentry_issue[2] && iqentry_islot[2] == 2'd1 && !iqentry_stomp[2])
					 || (iqentry_issue[3] && iqentry_islot[3] == 2'd1 && !iqentry_stomp[3])
					 || (iqentry_issue[4] && iqentry_islot[4] == 2'd1 && !iqentry_stomp[4])
					 || (iqentry_issue[5] && iqentry_islot[5] == 2'd1 && !iqentry_stomp[5])
					 || (iqentry_issue[6] && iqentry_islot[6] == 2'd1 && !iqentry_stomp[6])
					 || (iqentry_issue[7] && iqentry_islot[7] == 2'd1 && !iqentry_stomp[7]));


		for (kk = 0; kk <  8; kk = kk + 1)
		begin
			if (iqentry_v[kk] && iqentry_stomp[kk]) begin
				iqentry_v[kk] <= `INV;
				if (dram0_id[2:0] == kk)	dram0 <= `DRAMSLOT_AVAIL;
				if (dram1_id[2:0] == kk)	dram1 <= `DRAMSLOT_AVAIL;
				if (dram2_id[2:0] == kk)	dram2 <= `DRAMSLOT_AVAIL;
			end
			else if (iqentry_issue[kk]) begin
				case (iqentry_islot[kk]) 
				2'd0: if (alu0_available) begin
					alu0_sourceid	<= kk;
					alu0_insn	<= iqentry_insn[kk];
					alu0_bt		<= iqentry_bt[kk];
					alu0_pc		<= iqentry_pc[kk];
					alu0_argA	<= iqentry_a0_v[kk] ? iqentry_a0[kk]
								: (iqentry_a0_s[kk] == alu0_id) ? alu0_bus
								: (iqentry_a0_s[kk] == alu1_id) ? alu1_bus
								: 64'hDEADDEADDEADDEAD;
					alu0_argB	<= iqentry_a1_v[kk] ? iqentry_a1[kk]
								: (iqentry_a1_s[kk] == alu0_id) ? alu0_bus
								: (iqentry_a1_s[kk] == alu1_id) ? alu1_bus
								: 64'hDEADDEADDEADDEAD;
					alu0_argC	<= iqentry_a2_v[kk] ? iqentry_a2[kk]
								: (iqentry_a2_s[kk] == alu0_id) ? alu0_bus
								: (iqentry_a2_s[kk] == alu1_id) ? alu1_bus
								: 64'hDEADDEADDEADDEAD;
					alu0_argI	<= iqentry_a3[kk];
					end
				2'd1: if (alu1_available) begin
					alu1_sourceid	<= kk;
					alu1_insn	<= iqentry_insn[kk];
					alu1_bt		<= iqentry_bt[kk];
					alu1_pc		<= iqentry_pc[kk];
					alu1_argA	<= iqentry_a0_v[kk] ? iqentry_a0[kk]
								: (iqentry_a0_s[kk] == alu0_id) ? alu0_bus
								: (iqentry_a0_s[kk] == alu1_id) ? alu1_bus
								: 64'hDEADDEADDEADDEAD;
					alu1_argB	<= iqentry_a1_v[kk] ? iqentry_a1[kk]
								: (iqentry_a1_s[kk] == alu0_id) ? alu0_bus
								: (iqentry_a1_s[kk] == alu1_id) ? alu1_bus
								: 64'hDEADDEADDEADDEAD;
					alu1_argC	<= iqentry_a2_v[kk] ? iqentry_a2[kk]
								: (iqentry_a2_s[kk] == alu0_id) ? alu0_bus
								: (iqentry_a2_s[kk] == alu1_id) ? alu1_bus
								: 64'hDEADDEADDEADDEAD;
					alu1_argI	<= iqentry_a3[kk];
					end
				default: panic <= `PANIC_INVALIDISLOT;
				endcase
				iqentry_out[kk] <= `VAL;
				// if it is a memory operation, this is the address-generation step ... collect result into arg0
				if (iqentry_mem[kk]) begin
				iqentry_a0_v[kk] <= `INV;
				iqentry_a0_s[kk] <= kk;
				end
			end
		end //kk loop

		//
		// MEMORY
		//
		// update the memory queues and put data out on bus if appropriate
		//
		//
		// dram0, dram1, dram2 are the "state machines" that keep track
		// of three pipelined DRAM requests.  if any has the value "00", 
		// then it can accept a request (which bumps it up to the value "01"
		// at the end of the cycle).  once it hits the value "11" the request
		// is finished and the dram_bus takes the value.  if it is a store, the 
		// dram_bus value is not used, but the dram_v value along with the
		// dram_id value signals the waiting memq entry that the store is
		// completed and the instruction can commit.
		//

		if (dram0 != `DRAMSLOT_AVAIL)	dram0 <= dram0 + 2'd1;
		if (dram1 != `DRAMSLOT_AVAIL)	dram1 <= dram1 + 2'd1;
		if (dram2 != `DRAMSLOT_AVAIL)	dram2 <= dram2 + 2'd1;

		casex ({dram0, dram1, dram2})
			// not particularly portable ...
			6'b1111xx,
			6'b11xx11,
			6'bxx1111:	panic <= `PANIC_IDENTICALDRAMS;

			default: begin
			//
			// grab requests that have finished and put them on the dram_bus
			if (dram0 == `DRAMREQ_READY) begin
				dram_v <= isDramLoad(dram0_insn);
				dram_id <= dram0_id;
				dram_tgt <= dram0_tgt;
				dram_exc <= dram0_exc;
				if isDramLoad(dram0_insn) dram_bus <= m[ dram0_addr ];
				else if (dram0_op == `SW) 	m[ dram0_addr ] <= dram0_data;
				else			panic <= `PANIC_INVALIDMEMOP;
				if (dram0_op == `SW) 	$display("m[%h] <- %h", dram0_addr, dram0_data);
			end
			else if (dram1 == `DRAMREQ_READY) begin
				dram_v <= isDramLoad(dram1_insn);
				dram_id <= dram1_id;
				dram_tgt <= dram1_tgt;
				dram_exc <= dram1_exc;
				if (dram1_op == `LW) 	dram_bus <= m[ dram1_addr ];
				else if (dram1_op == `SW) 	m[ dram1_addr ] <= dram1_data;
				else			panic <= `PANIC_INVALIDMEMOP;
				if (dram1_op == `SW) 	$display("m[%h] <- %h", dram1_addr, dram1_data);
			end
			else if (dram2 == `DRAMREQ_READY) begin
				dram_v <= isDramLoad(dram2_insn);
				dram_id <= dram2_id;
				dram_tgt <= dram2_tgt;
				dram_exc <= dram2_exc;
				if (dram2_op == `LW) 	dram_bus <= m[ dram2_addr ];
				else if (dram2_op == `SW) 	m[ dram2_addr ] <= dram2_data;
				else			panic <= `PANIC_INVALIDMEMOP;
				if (dram2_op == `SW) 	$display("m[%h] <- %h", dram2_addr, dram2_data);
			end
			else begin
				dram_v <= `INV;
			end
			end
		endcase

		//
		// determine if the instructions ready to issue can, in fact, issue.
		// "ready" means that the instruction has valid operands but has not gone yet
		iqentry_memissue[ head0 ] <=	iqentry_memready[ head0 ];		// first in line ... go as soon as ready

		iqentry_memissue[ head1 ] <=	~iqentry_stomp[head1] && iqentry_memready[ head1 ]		// addr and data are valid
						&& ~iqentry_memready[head0]
						&& isDramLoad(iqentry_insn[head1])
						;

		iqentry_memissue[ head2 ] <=	~iqentry_stomp[head2] && iqentry_memready[ head2 ]		// addr and data are valid
						// ... and no preceding instruction is ready to go
						&& ~iqentry_memready[head0]
						&& ~iqentry_memready[head1] 
						&& isDramLoad(iqentry_insn[head2])
						;

		iqentry_memissue[ head3 ] <=	~iqentry_stomp[head3] && iqentry_memready[ head3 ]		// addr and data are valid
						// ... and no preceding instruction is ready to go
						&& ~iqentry_memready[head0]
						&& ~iqentry_memready[head1] 
						&& ~iqentry_memready[head2] 
						&& isDramLoad(iqentry_insn[head3])
						;

		iqentry_memissue[ head4 ] <=	~iqentry_stomp[head4] && iqentry_memready[ head4 ]		// addr and data are valid
						// ... and no preceding instruction is ready to go
						&& ~iqentry_memready[head0]
						&& ~iqentry_memready[head1] 
						&& ~iqentry_memready[head2] 
						&& ~iqentry_memready[head3] 
						&& isDramLoad(iqentry_insn[head4])
						;

		iqentry_memissue[ head5 ] <=	~iqentry_stomp[head5] && iqentry_memready[ head5 ]		// addr and data are valid
						// ... and no preceding instruction is ready to go
						&& ~iqentry_memready[head0]
						&& ~iqentry_memready[head1] 
						&& ~iqentry_memready[head2] 
						&& ~iqentry_memready[head3] 
						&& ~iqentry_memready[head4] 
						&& isDramLoad(iqentry_insn[head5])
						;

		iqentry_memissue[ head6 ] <=	~iqentry_stomp[head6] && iqentry_memready[ head6 ]		// addr and data are valid
						// ... and no preceding instruction is ready to go
						&& ~iqentry_memready[head0]
						&& ~iqentry_memready[head1] 
						&& ~iqentry_memready[head2] 
						&& ~iqentry_memready[head3] 
						&& ~iqentry_memready[head4] 
						&& ~iqentry_memready[head5] 
						&& isDramLoad(iqentry_insn[head6])
						;

		iqentry_memissue[ head7 ] <=	~iqentry_stomp[head7] && iqentry_memready[ head7 ]		// addr and data are valid
						// ... and no preceding instruction is ready to go
						&& ~iqentry_memready[head0]
						&& ~iqentry_memready[head1] 
						&& ~iqentry_memready[head2] 
						&& ~iqentry_memready[head3] 
						&& ~iqentry_memready[head4] 
						&& ~iqentry_memready[head5] 
						&& ~iqentry_memready[head6] 
						&& isDramLoad(iqentry_insn[head7])
						;

		//
		// take requests that are ready and put them into DRAM slots

		if (dram0 == `DRAMSLOT_AVAIL)	dram0_exc <= `EXC_NONE;
		if (dram1 == `DRAMSLOT_AVAIL)	dram1_exc <= `EXC_NONE;
		if (dram2 == `DRAMSLOT_AVAIL)	dram2_exc <= `EXC_NONE;

		for (kk = 0; kk < 8; kk = kk + 1)
		begin
			if (~iqentry_stomp[kk] && iqentry_memissue[kk] && iqentry_agen[kk] && ~iqentry_out[kk]) begin
				if (dram0 == `DRAMSLOT_AVAIL) begin
				dram0 		<= 2'd1;
				dram0_id 	<= { 1'b1, kk[2:0] };
				dram0_insn 	<= iqentry_insn[kk];
				dram0_tgt 	<= iqentry_tgt[kk];
				dram0_data	<= iqentry_a2[kk];
				dram0_addr	<= iqentry_a0[kk];
				iqentry_out[kk]	<= `VAL;
				end
				else if (dram1 == `DRAMSLOT_AVAIL) begin
				dram1 		<= 2'd1;
				dram1_id 	<= { 1'b1, kk[2:0] };
				dram1_op 	<= iqentry_insn[kk];
				dram1_tgt 	<= iqentry_tgt[kk];
				dram1_data	<= iqentry_a2[kk];
				dram1_addr	<= iqentry_a0[kk];
				iqentry_out[kk]	<= `VAL;
				end
				else if (dram2 == `DRAMSLOT_AVAIL) begin
				dram2 		<= 2'd1;
				dram2_id 	<= { 1'b1, kk[2:0] };
				dram2_op 	<= iqentry_op[kk];
				dram2_tgt 	<= iqentry_tgt[kk];
				dram2_data	<= iqentry_a2[kk];
				dram2_addr	<= iqentry_a1[kk];
				iqentry_out[kk]	<= `VAL;
				end
			end
		end

		//
		// COMMIT PHASE (dequeue only ... not register-file update)
		//
		// look at head0 and head1 and let 'em write to the register file if they are ready
		//

		if (~|panic)
		case ({ iqentry_v[head0],
			iqentry_done[head0],
			iqentry_v[head1],
			iqentry_done[head1] })

			// 4'b00_00	- neither valid; skip both
			// 4'b00_01	- neither valid; skip both
			// 4'b00_10	- skip head0, wait on head1
			// 4'b00_11	- skip head0, commit head1
			// 4'b01_00	- neither valid; skip both
			// 4'b01_01	- neither valid; skip both
			// 4'b01_10	- skip head0, wait on head1
			// 4'b01_11	- skip head0, commit head1
			// 4'b10_00	- wait on head0
			// 4'b10_01	- wait on head0
			// 4'b10_10	- wait on head0
			// 4'b10_11	- wait on head0
			// 4'b11_00	- commit head0, skip head1
			// 4'b11_01	- commit head0, skip head1
			// 4'b11_10	- commit head0, wait on head1
			// 4'b11_11	- commit head0, commit head1

			//
			// retire 0
			4'b10_00,
			4'b10_01,
			4'b10_10,
			4'b10_11: ;

			//
			// retire 1
			4'b00_10,
			4'b01_10,
			4'b11_10: begin
			if (iqentry_v[head0] || head0 != tail0) begin
				iqentry_v[head0] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
				head0 <= head0 + 1;
				head1 <= head1 + 1;
				head2 <= head2 + 1;
				head3 <= head3 + 1;
				head4 <= head4 + 1;
				head5 <= head5 + 1;
				head6 <= head6 + 1;
				head7 <= head7 + 1;
				if (iqentry_v[head0] && iqentry_exc[head0])	panic <= `PANIC_HALTINSTRUCTION;
				I <= I + 1;
			end
			end

			//
			// retire 2
			default: begin
			if ((iqentry_v[head0] && iqentry_v[head1]) || (head0 != tail0 && head1 != tail0)) begin
				iqentry_v[head0] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
				iqentry_v[head1] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
				head0 <= head0 + 2;
				head1 <= head1 + 2;
				head2 <= head2 + 2;
				head3 <= head3 + 2;
				head4 <= head4 + 2;
				head5 <= head5 + 2;
				head6 <= head6 + 2;
				head7 <= head7 + 2;
				if (iqentry_v[head0] && iqentry_exc[head0])	panic <= `PANIC_HALTINSTRUCTION;
				if (iqentry_v[head1] && iqentry_exc[head1])	panic <= `PANIC_HALTINSTRUCTION;
				I <= I + 2;
			end
			else if (iqentry_v[head0] || head0 != tail0) begin
				iqentry_v[head0] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
				head0 <= head0 + 1;
				head1 <= head1 + 1;
				head2 <= head2 + 1;
				head3 <= head3 + 1;
				head4 <= head4 + 1;
				head5 <= head5 + 1;
				head6 <= head6 + 1;
				head7 <= head7 + 1;
				if (iqentry_v[head0] && iqentry_exc[head0])	panic <= `PANIC_HALTINSTRUCTION;
				I <= I + 1;
			end
			end
		endcase

		$display("\n\n\n\n\n\n\n\n");
		$display("TIME %0d", $time);
		$display("%h #", pc0);

		for (i=0; i<8; i=i+1)
			$display("%d: %h %d %o #", i, rf[i], rf_v[i], rf_source[i]);

		$display("%d %h #", branchback, backpc);
		$display("%c%c A: %d %h %h #",
			45, fetchbuf?45:62, fetchbufA_v, fetchbufA_instr, fetchbufA_pc);
		$display("%c%c B: %d %h %h #",
			45, fetchbuf?45:62, fetchbufB_v, fetchbufB_instr, fetchbufB_pc);
		$display("%c%c C: %d %h %h #",
			45, fetchbuf?62:45, fetchbufC_v, fetchbufC_instr, fetchbufC_pc);
		$display("%c%c D: %d %h %h #",
			45, fetchbuf?62:45, fetchbufD_v, fetchbufD_instr, fetchbufD_pc);

		for (i=0; i<8; i=i+1) 
			$display("%c%c %d: %d %d %d %d %d %d %d %d %d %c%d 0%d %o %h %h %h %d %o %h %d %o %h #",
			(i[2:0]==head0)?72:46, (i[2:0]==tail0)?84:46, i,
			iqentry_v[i], iqentry_done[i], iqentry_out[i], iqentry_bt[i], iqentry_memissue[i], iqentry_agen[i], iqentry_issue[i],
			((i==0) ? iqentry_islot[0] : (i==1) ? iqentry_islot[1] : (i==2) ? iqentry_islot[2] : (i==3) ? iqentry_islot[3] :
			 (i==4) ? iqentry_islot[4] : (i==5) ? iqentry_islot[5] : (i==6) ? iqentry_islot[6] : iqentry_islot[7]), iqentry_stomp[i],
			((iqentry_op[i]==`BEQ || iqentry_op[i]==`JALR) ? 98 : (iqentry_op[i]==`LW || iqentry_op[i]==`SW) ? 109 : 97), 
			iqentry_op[i], iqentry_tgt[i], iqentry_exc[i], iqentry_res[i], iqentry_a0[i], iqentry_a1[i], iqentry_a1_v[i],
			iqentry_a1_s[i], iqentry_a2[i], iqentry_a2_v[i], iqentry_a2_s[i], iqentry_pc[i]);

		$display("%d %h %h %c%d %o #",
			dram0, dram0_addr, dram0_data, ((dram0_op==`BEQ || dram0_op==`JALR) ? 98 : (dram0_op==`LW || dram0_op==`SW) ? 109 : 97), 
			dram0_op, dram0_id);
		$display("%d %h %h %c%d %o #",
			dram1, dram1_addr, dram1_data, ((dram1_op==`BEQ || dram1_op==`JALR) ? 98 : (dram1_op==`LW || dram1_op==`SW) ? 109 : 97), 
			dram1_op, dram1_id);
		$display("%d %h %h %c%d %o #",
			dram2, dram2_addr, dram2_data, ((dram2_op==`BEQ || dram2_op==`JALR) ? 98 : (dram2_op==`LW || dram2_op==`SW) ? 109 : 97), 
			dram2_op, dram2_id);
		$display("%d %h %o %h #", dram_v, dram_bus, dram_id, dram_exc);

		$display("%d %h %h %h %c%d %d %o %h #",
			alu0_dataready, alu0_argI, alu0_argA, alu0_argB, 
			 ((alu0_op==`BEQ || alu0_op==`JALR) ? 98 : (alu0_op==`LW || alu0_op==`SW) ? 109 : 97),
			alu0_op, alu0_bt, alu0_sourceid, alu0_pc);
		$display("%d %h %o 0 #", alu0_v, alu0_bus, alu0_id);
		$display("%d %o %h #", alu0_branchmiss, alu0_sourceid, alu0_misspc); 

		$display("%d %h %h %h %c%d %d %o %h #",
			alu1_dataready, alu1_argI, alu1_argA, alu1_argB, 
			 ((alu1_op==`BEQ || alu1_op==`JALR) ? 98 : (alu1_op==`LW || alu1_op==`SW) ? 109 : 97),
			alu1_op, alu1_bt, alu1_sourceid, alu1_pc);
		$display("%d %h %o 0 #", alu1_v, alu1_bus, alu1_id);
		$display("%d %o %h #", alu1_branchmiss, alu1_sourceid, alu1_misspc); 

		$display("0: %d %h %o 0%d #", commit0_v, commit0_bus, commit0_id, commit0_tgt);
		$display("1: %d %h %o 0%d #", commit1_v, commit1_bus, commit1_id, commit1_tgt);

		if (|panic) begin
			$display("");
			$display("-----------------------------------------------------------------");
			$display("-----------------------------------------------------------------");
			$display("---------------     PANIC:%s     -----------------", message[panic]);
			$display("-----------------------------------------------------------------");
			$display("-----------------------------------------------------------------");
			$display("");
			$display("instructions committed: %d", I);
			$display("total execution cycles: %d", $time / 10);
			$display("");
		end
	end

endmodule

module FISA64_regfile2w4r(
	clk, wr0, wr1, wa0, wa1, i0, i1,
	rclk, ra0, ra1, ra2, ra3, ra4, ra5, o0, o1, o2, o3, o4, o5);
parameter WID=64;
input clk;
input wr0;
input wr1;
input [5:0] wa0;
input [5:0] wa1;
input [WID-1:0] i0;
input [WID-1:0] i1;
input rclk;
input [5:0] ra0;
input [5:0] ra1;
input [5:0] ra2;
input [5:0] ra3;
input [5:0] ra4;
input [5:0] ra5;
output [WID-1:0] o0;
output [WID-1:0] o1;
output [WID-1:0] o2;
output [WID-1:0] o3;
output [WID-1:0] o4;
output [WID-1:0] o5;

reg [WID-1:0] regs0 [0:63];
reg [WID-1:0] regs1 [0:63];
reg [5:0] rra0,rra1,rra2,rra3,rra4,rra5;

reg whichreg [0:63];	// tracks which register file is the valid one for a given register

assign o0 = rra0==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra0==wa1)) ? i1 :
	(wr0 && (rra0==wa0)) ? i0 :
	whichreg[rra0]==1'b0 ? regs0[rra0] : regs1[rra0];
assign o1 = rra1==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra1==wa1)) ? i1 :
	(wr0 && (rra1==wa0)) ? i0 :
	whichreg[rra1]==1'b0 ? regs0[rra1] : regs1[rra1];
assign o2 = rra2==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra2==wa1)) ? i1 :
	(wr0 && (rra2==wa0)) ? i0 :
	whichreg[rra2]==1'b0 ? regs0[rra2] : regs1[rra2];
assign o3 = rra3==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra3==wa1)) ? i1 :
	(wr0 && (rra3==wa0)) ? i0 :
	whichreg[rra3]==1'b0 ? regs0[rra3] : regs1[rra3];
assign o4 = rra4==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra4==wa1)) ? i1 :
	(wr0 && (rra4==wa0)) ? i0 :
	whichreg[rra4]==1'b0 ? regs0[rra4] : regs1[rra4];
assign o5 = rra5==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra5==wa1)) ? i1 :
	(wr0 && (rra5==wa0)) ? i0 :
	whichreg[rra5]==1'b0 ? regs0[rra5] : regs1[rra5];

always @(posedge clk)
	if (wr0)
		regs0[wa0] <= i0;

always @(posedge clk)
	if (wr1)
		regs1[wa1] <= i1;

always @(posedge rclk) rra0 <= ra0;
always @(posedge rclk) rra1 <= ra1;
always @(posedge rclk) rra2 <= ra2;
always @(posedge rclk) rra3 <= ra3;
always @(posedge rclk) rra4 <= ra4;
always @(posedge rclk) rra5 <= ra5;

always @(posedge clk)
	// writing three registers at once
	if (wr0 && wr1 && wa0==wa1)		// Two ports writing the same address
		whichreg[wa0] <= 1'b1;		// port one is the valid one
	// writing two registers
	else if (wr0 && wr1) begin
		whichreg[wa0] <= 1'b0;
		whichreg[wa1] <= 1'b1;
	end
	// writing a single register
	else if (wr0)
		whichreg[wa0] <= 1'b0;
	else if (wr1)
		whichreg[wa1] <= 1'b1;

endmodule

module FISA64_bitfield(op, a, b, imm, m, o, masko);
parameter DWIDTH=64;
input [2:0] op;
input [DWIDTH-1:0] a;
input [DWIDTH-1:0] b;
input [DWIDTH-1:0] imm;
input [15:0] m;
output [DWIDTH-1:0] o;
reg [DWIDTH-1:0] o;
output [DWIDTH-1:0] masko;

reg [DWIDTH-1:0] o1;
reg [DWIDTH-1:0] o2;

// generate mask
reg [DWIDTH-1:0] mask;
assign masko = mask;
wire [5:0] mb = m[ 5:0];
wire [5:0] me = m[11:6];
wire [5:0] ml = me-mb;		// mask length-1

integer nn,n;
always @(mb or me or nn)
	for (nn = 0; nn < DWIDTH; nn = nn + 1)
		mask[nn] <= (nn >= mb) ^ (nn <= me) ^ (me >= mb);

always @(op,mask,b,a,imm,mb)
case (op)
`BFINS: 	begin
				o2 = a << mb;
				for (n = 0; n < DWIDTH; n = n + 1) o[n] = (mask[n] ? o2[n] : b[n]);
			end
`BFINSI: 	begin
				o2 = imm << mb;
				for (n = 0; n < DWIDTH; n = n + 1) o[n] = (mask[n] ? o2[n] : b[n]);
			end
`BFSET: 	begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? 1'b1 : a[n]; end
`BFCLR: 	begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? 1'b0 : a[n]; end
`BFCHG: 	begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? ~a[n] : a[n]; end
`BFEXTU:	begin
				for (n = 0; n < DWIDTH; n = n + 1)
					o1[n] = mask[n] ? a[n] : 1'b0;
				o = o1 >> mb;
			end
`BFEXT:		begin
				for (n = 0; n < DWIDTH; n = n + 1)
					o1[n] = mask[n] ? a[n] : 1'b0;
				o2 = o1 >> mb;
				for (n = 0; n < DWIDTH; n = n + 1)
					o[n] = n > ml ? o2[ml] : o2[n];
			end
`ifdef I_SEXT
`SEXT:		begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? a[mb] : a[n]; end
`endif
default:	o = {DWIDTH{1'b0}};
endcase

endmodule

module FISA64_BranchHistory(rst, clk, advanceX, insn, pc, xpc, takb, predict_taken);
input rst;
input clk;
input advanceX;
input [31:0] insn;
input [63:0] pc;
input [63:0] xpc;
input takb;
output predict_taken;

integer n;
reg [2:0] gbl_branch_hist;
reg [1:0] branch_history_table [511:0];
// For simulation only, initialize the history table to zeros.
// In the real world we don't care.
initial begin
	for (n = 0; n < 512; n = n + 1)
		branch_history_table[n] = 0;
end
wire [8:0] bht_wa = {xpc[7:1],gbl_branch_hist[2:1]};		// write address
wire [8:0] bht_ra1 = {xpc[7:1],gbl_branch_hist[2:1]};		// read address (EX stage)
wire [8:0] bht_ra2 = {pc[7:1],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [1:0] bht_xbits = branch_history_table[bht_ra1];
wire [1:0] bht_ibits = branch_history_table[bht_ra2];
assign predict_taken = bht_ibits==2'd0 || bht_ibits==2'd1;

wire [6:0] opcode = insn[6:0];
wire isBranch = (opcode==`Bcc)||(opcode==`BEQS)||(opcode==`BNES);

// Two bit saturating counter
reg [1:0] xbits_new;
always @(takb or bht_xbits)
if (takb) begin
	if (bht_xbits != 2'd1)
		xbits_new <= bht_xbits + 2'd1;
	else
		xbits_new <= bht_xbits;
end
else begin
	if (bht_xbits != 2'd2)
		xbits_new <= bht_xbits - 2'd1;
	else
		xbits_new <= bht_xbits;
end

always @(posedge clk)
if (rst)
	gbl_branch_hist <= 3'b000;
else begin
	if (advanceX) begin
		if (isBranch) begin
			gbl_branch_hist <= {gbl_branch_hist[1:0],takb};
			branch_history_table[bht_wa] <= xbits_new;
		end
	end
end

endmodule

module FISA64_shift(insn, a, b, res, rolo);
input [31:0] insn;
input [63:0] a;
input [63:0] b;
output [63:0] res;
reg [63:0] res;
output [63:0] rolo;

wire [6:0] opcode = insn[6:0];
wire [6:0] func = insn[31:25];

wire isImm = func==`SLLI || func==`SRLI || func==`SRAI || func==`ROLI || func==`RORI;

wire [127:0] shl = {64'd0,a} << (isImm ? insn[22:17] : b[5:0]);
wire [127:0] shr = {a,64'd0} >> (isImm ? insn[22:17] : b[5:0]);

always @*
case(opcode)
`RR:
	case(func)
	`SLLI:	res <= shl[63:0];
	`SLL:	res <= shl[63:0];
	`SRLI:	res <= shr[127:64];
	`SRL:	res <= shr[127:64];
	`SRAI:	if (a[63])
				res <= (shr[127:64]) | ~(64'hFFFFFFFFFFFFFFFF >> insn[22:17]);
			else
				res <= shr[127:64];
	`SRA:	if (a[63])
				res <= (shr[127:64]) | ~(64'hFFFFFFFFFFFFFFFF >> b[5:0]);
			else
				res <= shr[127:64];
	`ROL:	res <= shl[63:0]|shl[127:64];
	`ROLI:	res <= shl[63:0]|shl[127:64];
	`ROR:	res <= shr[63:0]|shr[127:64];
	`RORI:	res <= shr[63:0]|shr[127:64];
	default:	res <= 64'd0;
	endcase
default:	res <= 64'd0;
endcase

endmodule

module FISA64_logic(insn, a, b, imm, res);
input [31:0] insn;
input [63:0] a;
input [63:0] b;
input [63:0] imm;
output [63:0] res;
reg [63:0] res;

wire [6:0] opcode = insn[6:0];
wire [6:0] func = insn[31:25];

always @*
case(opcode)
`RR:
	case(func)
	`NOT:	res <= ~|a;
	`AND:	res <= a & b;
	`OR:	res <= a | b;
	`EOR:	res <= a ^ b;
	`NAND:	res <= ~(a & b);
	`NOR:	res <= ~(a | b);
	`ENOR:	res <= ~(a ^ b);
	default:	res <= 64'd0;
	endcase
`AND:	res <= a & imm;
`OR:	res <= a | imm;
`EOR:	res <= a ^ imm;
default:	res <= 64'd0;
endcase

endmodule

// This should synthesize to a 63 bit wide ROM.
module decoder6 (num, out);
    input [5:0] num;
    output [63:1] out;
    reg [63:1] out;

    always @(num)
	case (num)
	    6'd0 :	out <= 63'h0; 
	    6'd1 :	out <= 63'h1;
	    6'd2 :	out <= 63'h2;
	    6'd3 :	out <= 63'h4;
	    6'd4 :	out <= 63'h8;
	    6'd5 :	out <= 63'h10;
	    6'd6 :	out <= 63'h20;
	    6'd7 :	out <= 63'h40;
		6'd8 :  out <= 63'h80;
		6'd9 :  out <= 63'h100;
		6'd10:	out <= 63'h200;
		6'd11:	out <= 63'h400;
		6'd12:	out <= 63'h800;
		6'd13:	out <= 63'h1000;
		6'd14:	out <= 63'h2000;
		6'd15:	out <= 63'h4000;
		6'd16:	out <= 63'h8000;
		6'd17:	out <= 63'h10000;
		6'd18:	out <= 63'h20000;
		6'd19:	out <= 63'h40000;
		6'd20:	out <= 63'h80000;
		6'd21:	out <= 63'h100000;
		6'd22:	out <= 63'h200000;
		6'd23:	out <= 63'h400000;
		6'd24:	out <= 63'h800000;
		6'd25:	out <= 63'h1000000;
		6'd26:	out <= 63'h2000000;
		6'd27:	out <= 63'h4000000;
		6'd28:	out <= 63'h8000000;
		6'd29:	out <= 63'h10000000;
		6'd30:	out <= 63'h20000000;
		6'd31:	out <= 63'h40000000;
		6'd32:	out <= 63'h80000000;
		6'd33:	out <= 63'h100000000;
		6'd34:	out <= 63'h200000000;
		6'd35:	out <= 63'h400000000;
		6'd36:	out <= 63'h800000000;
		6'd37:	out <= 63'h1000000000;
		6'd38:	out <= 63'h2000000000;
		6'd39:	out <= 63'h4000000000;
		6'd40:	out <= 63'h8000000000;
		6'd41:	out <= 63'h10000000000;
		6'd42:	out <= 63'h20000000000;
		6'd43:	out <= 63'h40000000000;
		6'd44:	out <= 63'h80000000000;
		6'd45:	out <= 63'h100000000000;
		6'd46:	out <= 63'h200000000000;
		6'd47:	out <= 63'h400000000000;
		6'd48:	out <= 63'h800000000000;
		6'd49:	out <= 63'h1000000000000;
		6'd50:	out <= 63'h2000000000000;
		6'd51:	out <= 63'h4000000000000;
		6'd52:	out <= 63'h8000000000000;
		6'd53:	out <= 63'h10000000000000;
		6'd54:	out <= 63'h20000000000000;
		6'd55:	out <= 63'h40000000000000;
		6'd56:	out <= 63'h80000000000000;
		6'd57:	out <= 63'h100000000000000;
		6'd58:	out <= 63'h200000000000000;
		6'd59:	out <= 63'h400000000000000;
		6'd60:	out <= 63'h800000000000000;
		6'd61:	out <= 63'h1000000000000000;
		6'd62:	out <= 63'h2000000000000000;
		6'd63:	out <= 63'h4000000000000000;
	endcase
endmodule
