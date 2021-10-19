// ============================================================================
//        __
//   \\__/ o\    (C) 2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Thor2021_pkg.sv
// For the crypto functions latency cannot depend on data operated on!
//
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================

package Thor2021_pkg;

`define QSLOTS	2		// number of simulataneously queueable instructions
`define	RSLOTS	8		// number of reorder buffer entries

parameter QSLOTS	= `QSLOTS;
parameter RSLOTS	= `RSLOTS;
parameter BitsQS	= $clog2(`QSLOTS-1);
parameter BitsRS	= $clog2(`RSLOTS-1) + 1;

parameter VALUE_SIZE = 64;

parameter TRUE  = 1'b1;
parameter FALSE = 1'b0;
parameter HIGH  = 1'b1;
parameter LOW   = 1'b0;
parameter VAL		= 1'b1;
parameter INV		= 1'b0;

parameter OM_USER		= 2'd0;
parameter OM_SUPER	= 2'd1;
parameter OM_HYPER	= 2'd2;
parameter OM_MACHINE	= 2'd3;

parameter BRK			= 8'h00;
parameter R1			= 8'h01;
parameter R2			= 8'h02;
parameter R3			= 8'h03;
parameter ADDI		= 8'h04;
parameter SUBFI		= 8'h05;
parameter MULI		= 8'h06;
parameter OSR2		= 8'h07;
parameter ANDI		= 8'h08;
parameter ORI			= 8'h09;
parameter XORI		= 8'h0A;
parameter ADCI		= 8'h0C;
parameter	SBCFI		= 8'h0D;
parameter MULUI		= 8'h0E;
parameter CSR			= 8'h0F;
parameter R1L			= 8'h11;
parameter R2L			= 8'h12;
parameter R3L			= 8'h13;
parameter ADDQI		= 8'h14;
parameter MULFI		= 8'h15;
parameter SEQI		= 8'h16;
parameter SNEI		= 8'h17;
parameter SLTI		= 8'h18;
parameter SLTIL		= 8'h19;
parameter SGTIL		= 8'h1A;
parameter SGTI		= 8'h1B;
parameter SLTUI		= 8'h1C;
parameter SLTUIL	= 8'h1D;
parameter SGTUIL	= 8'h1E;
parameter SGTUI		= 8'h1F;
parameter BRA			= 8'h20;
parameter BBC			= 8'h24;
parameter BBS			= 8'h25;
parameter BEQ			= 8'h26;
parameter BNE			= 8'h27;
parameter BLT			= 8'h28;
parameter BGE			= 8'h29;
parameter BLE			= 8'h2A;
parameter BGT			= 8'h2B;
parameter BLTU		= 8'h2C;
parameter BGEU		= 8'h2D;
parameter BLEU		= 8'h2E;
parameter BGTU		= 8'h2F;
parameter BBCL		= 8'h34;
parameter BBSL		= 8'h35;
parameter BEQL		= 8'h36;
parameter BNEL		= 8'h37;
parameter BLTL		= 8'h38;
parameter BGEL		= 8'h39;
parameter BLEL		= 8'h3A;
parameter BGTL		= 8'h3B;
parameter BLTUL		= 8'h3C;
parameter BGEUL		= 8'h3D;
parameter BLEUL		= 8'h3E;
parameter BGTUL		= 8'h3F;
parameter DIVI		= 8'h40;
parameter CPUID		= 8'h41;
parameter DIVIL		= 8'h42;
parameter MUX			= 8'h43;
parameter ADDIL		= 8'h44;
parameter CHKI		= 8'h45;
parameter MULIL		= 8'h46;
parameter SNEIL		= 8'h47;
parameter ANDIL		= 8'h48;
parameter ORIL		= 8'h49;
parameter XORIL		= 8'h4A;
parameter SEQIL		= 8'h4B;
parameter BMAPI		= 8'h4C;
parameter MULUIL	= 8'h4E;
parameter DIVUI		= 8'h4F;
parameter CMPI		= 8'h50;
parameter VM			= 8'h52;
parameter VMFILL	= 8'h53;
parameter ADDIS		= 8'h54;
parameter BYTNDXI	= 8'h55;
parameter WYDNDXI	= 8'h56;
parameter UTF21NDXI	= 8'h57;
parameter ANDIS		= 8'h58;
parameter ORIS		= 8'h59;
parameter XORIS		= 8'h5A;
parameter CMPIL		= 8'h60;
parameter F1			= 8'h61;
parameter F2			= 8'h62;
parameter F3			= 8'h63;
parameter DF1			= 8'h65;
parameter DF2			= 8'h66;
parameter DF3			= 8'h67;
parameter P1			= 8'h69;
parameter P2			= 8'h6A;
parameter P3			= 8'h6B;
parameter CMPIS		= 8'h70;
parameter F1L			= 8'h71;
parameter F2L			= 8'h72;
parameter DF1L		= 8'h75;
parameter DF2L		= 8'h76;
parameter P1L			= 8'h79;
parameter P2L			= 8'h7A;
parameter SYS			= 8'hA5;
parameter INT			= 8'hA6;
parameter MOV			= 8'hA7;
parameter BTFLD		= 8'hAA;
parameter BFINS			= 4'h0;
parameter BFFFO			= 4'h1;
parameter BFEXT			= 4'h5;
parameter BFINSI		= 4'h6;
parameter BFSET			= 4'h9;
parameter BFCHG			= 4'hA;
parameter BFCLR			= 4'hB;
parameter LDxX		= 8'hB0;
parameter STxX		= 8'hC0;
parameter NOP			= 8'hF1;
parameter RTS			= 8'hF2;
parameter RTE			= 8'hF3;
parameter BCD			= 8'hF5;
parameter SYNC		= 8'hF7;
parameter MEMSB		= 8'hF8;
parameter MEMDB		= 8'hF9;
parameter WFI			= 8'hFA;
parameter SEI			= 8'hFB;

// R3
parameter PTRDIF	= 4'h1;
parameter	CHK			= 4'h2;
parameter MUX			= 4'h4;
parameter CMOVNZ	= 4'h6;

// Cypto
parameter SM4ED		= 4'hE;
parameter SM4KS		= 4'hF;
parameter SHA256SIG0	= 7'h30;
parameter SHA256SIG1	= 7'h31;
parameter SHA256SUM0	= 7'h32;
parameter SHA256SUM1	= 7'h33;
parameter SHA512SIG0	= 7'h34;
parameter SHA512SIG1	= 7'h35;
parameter SHA512SUM0	= 7'h36;
parameter SHA512SUM1	= 7'h37;
parameter SM3P0		= 7'h38;
parameter SM3P1		= 7'h39;

// Neural Network Accelerator
parameter NNA_MFACT	= 7'h62;
parameter NNA_MTBC	= 7'h65;
parameter NNA_MTBIAS	= 7'h62;
parameter NNA_MTFB	= 7'h63;
parameter NNA_MTIN	= 7'h61;
parameter NNA_MTMC	= 7'h64;
parameter NNA_MTWT	= 7'h60;
parameter NNA_STAT	= 7'h61;
parameter NNA_TRIG	= 7'h60;

// F1
parameter FMOV	= 6'h00;
parameter I2F		= 6'h02;
parameter F2I		= 6'h03;
parameter FSQRT	= 6'h08;
parameter FRM		= 6'h14;
parameter CPYSGN= 6'h18;
parameter SGNINV= 6'h19;
parameter FABS	= 6'h20;
parameter FNABS	= 6'h21;
parameter FNEG	= 6'h22;

// F2
parameter FMIN	= 6'h02;
parameter FMAX	= 6'h03;
parameter FADD	= 6'h04;
parameter FSUB	= 6'h05;
parameter FMUL	= 6'h08;
parameter FDIV	= 6'h09;
parameter FCMP	= 6'h10;
parameter FSEQ	= 6'h11;
parameter FSLT	= 6'h12;
parameter FSLE	= 6'h13;
parameter FSNE	= 6'h14;
parameter FCMPB	= 6'h15;
parameter FSETM = 6'h16;

// F3
parameter FMA		= 4'h00;
parameter FMS		= 4'h01;
parameter FNMA	= 4'h02;
parameter FNMS	= 4'h03;


parameter MR_LOAD = 3'd0;
parameter MR_STORE = 3'd1;
parameter MR_TLB = 3'd2;
parameter MR_CACHE = 3'd3;
parameter LEA2 = 3'd4;
//parameter RTS2 = 3'd5;
parameter M_JALI	= 3'd5;
parameter M_CALL	= 3'd6;
parameter MR_LOADZ = 3'd7;		// unsigned load

parameter CSR_CAUSE	= 16'h?006;
parameter CSR_SEMA	= 16'h?00C;
parameter CSR_FSTAT	= 16'h?014;
parameter CSR_ASID	= 16'h101F;
parameter CSR_KEYS	= 16'b0001_0000_0010_00??;
parameter CSR_KEYTBL= 16'h1024;
parameter CSR_SCRATCH=16'h?041;
parameter CSR_MCR0	= 16'h3000;
parameter CSR_MHARTID = 16'h3001;
parameter CSR_TICK	= 16'h3002;
parameter CSR_MBADADDR	= 16'h3007;
parameter CSR_MTVEC = 16'b0011_0000_0011_0???;
parameter CSR_MSVEC = 16'b0011_0000_0011_1???;
parameter CSR_MPMSTACK	= 16'h3040;
parameter CSR_MSTATUS	= 16'h3044;
parameter CSR_MVSTEP= 16'h3046;
parameter CSR_MVTMP	= 16'h3047;
parameter CSR_MEIP	=	16'h3048;
parameter CSR_MECS	= 16'h3049;
parameter CSR_MPCS	= 16'h304A;
parameter CSR_DSTUFF0	= 16'h4042;
parameter CSR_DSTUFF1	= 16'h4043;
parameter CSR_DTCBPTR=16'h4050;
parameter CSR_MGDT	= 16'h3051;
parameter CSR_MLDT	= 16'h3052;
parameter CSR_DBVEC	= 16'b0100_0000_0101_1???;
parameter CSR_DSP		= 16'h4060;
parameter CSR_TIME	= 16'h?FE0;
parameter CSR_MTIME	= 16'h3FE0;

parameter FLT_NONE	= 8'h00;
parameter FLT_TLBMISS = 8'h04;
parameter FLT_IADR	= 8'h22;
parameter FLT_CHK		= 8'h27;
parameter FLT_KEY		= 8'h31;
parameter FLT_WRV		= 8'h32;
parameter FLT_RDV		= 8'h33;
parameter FLT_SGB		= 8'h34;
parameter FLT_WD		= 8'h36;
parameter FLT_UNIMP	= 8'h37;
parameter FLT_PMA		= 8'h3D;
parameter FLT_NMI		= 8'hFE;

parameter pL1CacheLines = 64;
parameter pL1LineSize = 512;
parameter pL1ICacheLines = 512;
parameter pL1ICacheLineSize = 548;
localparam pL1Imsb = $clog2(pL1ICacheLines-1)-1+6;

typedef logic [63:0]	Value;
typedef logic [31:0] Offset;
typedef logic [32-13:0] BTBTag;
typedef logic [7:0] ASID;
typedef logic [BitsRS:0] SrcId;

typedef struct packed
{
	logic [7:0] pl;
	logic ti;
	logic [22:0] ndx;
} Selector;

typedef struct packed
{
	Selector sel;
	Offset offs;
} Address;

typedef struct packed
{
	logic [31:0] pad;
	logic [10:0] imm;
	logic [5:0] Ra;
	logic [5:0] Rt;
	logic v;
	logic [7:0] opcode;
} riinst;

typedef struct packed
{
	logic [7:0] pad;
	logic [34:0] imm;
	logic [5:0] Ra;
	logic [5:0] Rt;
	logic v;
	logic [7:0] opcode;
} rilinst;

typedef struct packed
{
	logic [31:0] imm;
	logic [2:0] pad;
	logic [1:0] Tb;
	logic [5:0] Rb;
	logic [5:0] Ra;
	logic [5:0] Rt;
	logic v;
	logic [7:0] opcode;
} bmapinst;

typedef struct packed
{
	logic [31:0] pad;
	logic [6:0] func;
	logic [2:0] m;
	logic z;
	logic [5:0] Ra;
	logic [5:0] Rt;
	logic v;
	logic [7:0] opcode;
} r1inst;

typedef struct packed
{
	logic [23:0] pad;
	logic [6:0] func;
	logic [2:0] m;
	logic z;
	logic [1:0] Tb;
	logic [5:0] Rb;
	logic [5:0] Ra;
	logic [5:0] Rt;
	logic v;
	logic [7:0] opcode;
} r2inst;

typedef struct packed
{
	logic [15:0] pad;
	logic [6:0] func;
	logic [2:0] m;
	logic z;
	logic [1:0] Tc;
	logic [5:0] Rc;
	logic [1:0] Tb;
	logic [5:0] Rb;
	logic [5:0] Ra;
	logic [5:0] Rt;
	logic v;
	logic [7:0] opcode;
} r3inst;

typedef struct packed
{
	logic [47:0] pad;
	logic [4:0] cnst;
	logic [1:0] Ra;
	logic v;
	logic [7:0] opcode;
} rts_inst;
;
typedef struct packed
{
	logic [54:0] pad;
	logic v;
	logic [7:0] opcode;
} anyinst;

typedef struct packed
{
	logic [7:0] pad;
	logic [23:0] Tgthi;
	logic [2:0] Ca;
	logic [1:0] Tb;
	logic [5:0] Rb;
	logic [5:0] Ra;
	logic [1:0] Tgtlo;
	logic [1:0] Cn;
	logic [1:0] Rt;
	logic v;
	logic [7:0] opcode;
} brinst;

typedef struct packed
{
	logic [39:0] pad;
	logic [4:0] func;
	logic pad1;
	logic [2:0] Vmb;
	logic [2:0] Vma;
	logic [2:0] Vmt;
	logic v;
	logic [7:0] opcode;
} vmr2_inst;

typedef struct packed
{
	logic [31:0] pad;
	logic [2:0] seg;
	logic [7:0] disp;
	logic [5:0] Ra;
	logic [5:0] Rt;
	logic v;
	logic [7:0] opcode;
} ld_inst;

typedef struct packed
{
	logic [15:0] pad;
	logic [2:0] seg;
	logic [10:0] disp;
	logic C;
	logic [2:0] m;
	logic z;
	logic [1:0] Tb;
	logic [5:0] Rb;
	logic [5:0] Ra;
	logic [5:0] Rt;
	logic v;
	logic [7:0] opcode;
} vld_inst;

typedef struct packed
{
	logic [23:0] pad;
	logic [6:0] func;
	logic [2:0] seg;
	logic [1:0] Sc;
	logic [1:0] Tb;
	logic [5:0] Rb;
	logic [5:0] Ra;
	logic [5:0] Rt;
	logic v;
	logic [7:0] opcode;
} ldx_inst;

typedef struct packed
{
	logic [31:0] pad;
	logic [2:0] seg;
	logic [1:0] Tb;
	logic [5:0] Rb;
	logic [5:0] Ra;
	logic [5:0] disp;
	logic v;
	logic [7:0] opcode;
} st_inst;

typedef struct packed
{
	logic [15:0] pad;
	logic [5:0] func;
	logic [2:0] seg;
	logic [1:0] Sc;
	logic [1:0] Tc;
	logic [5:0] Rc;
	logic [1:0] Tb;
	logic [5:0] Rb;
	logic [5:0] Ra;
	logic [5:0] Rt;
	logic v;
	logic [7:0] opcode;
} stx_inst;

typedef struct packed
{
	logic [15:0] pad;
	logic [3:0] func;
	logic S;
	logic [5:0] Me;
	logic [1:0] Tc;
	logic [5:0] Rc;
	logic [1:0] Tb;
	logic [5:0] Rb;
	logic [5:0] Ra;
	logic [5:0] Rt;
	logic v;
	logic [7:0] opcode;
} rm_inst;

typedef union packed
{
	bmapinst bmap;
	r3inst r3;
	r2inst r2;
	r1inst r1;
	rilinst ril;
	riinst ri;
	brinst br;
	rts_inst rts;
	vmr2_inst vmr2;
	ld_inst ld;
	vld_inst vld;
	ldx_inst ldx;
	st_inst st;
	stx_inst stx;
	rm_inst rm;
	anyinst	any;
} Instruction;

typedef struct packed
{
	Instruction ir;
	Address ip;
	logic [3:0] len;
} sInstAlignOut;

typedef struct packed
{
	logic v;
	Address insadr;
	Address	tgtadr;
} BTBEntry;

typedef struct packed
{
	logic [7:0] tid;		// tran id
	logic [5:0] step;		// vector operation step
	logic wr;
	logic [2:0] func;		// function to perform
	logic [3:0] func2;	// more resolution to function
	Address adr;
	logic [127:0] dat;
	logic [15:0] sel;		// data byte select, indicates size of data (nybbles)
} MemoryRequest;	// 230

// All the fields in this structure are *output* back to the system.
typedef struct packed
{
	logic [7:0] tid;		// tran id
	logic [5:0] step;
	logic wr;
	logic v;
	logic empty;
	logic [15:0] cause;
	Address badAddr;
	logic [127:0] res;
	logic cmt;
	logic ldcs;
	logic mtsel;
} MemoryResponse;	// 228

typedef struct packed
{
	logic ASID;
	logic G;
	logic D;
	logic A;
	logic U;
	logic C;
	logic R;
	logic W;
	logic X;
	logic [19:0] vpn;
	logic [7:0] reseved;
	logic [19:0] ppn;
} TLBEntry;

typedef struct packed
{
	logic p;						// present
	logic sys;					// 1=system segment
	logic stk;					// 1=stack segment
	logic a;						// accessed
	logic c;						// 1=cachable
	logic	r;						// 1=readable
	logic w;						// 1=writable
	logic x;						// 1=executable
	logic [7:0] dpl;		// privilege level
	logic con;					// 1=conforming
	logic [2:0] u;
} SegACR;

typedef struct packed
{
	SegACR	acr;
	logic [43:0] pad_limit;
	logic [63:0] limit;
	logic [63:0] pad_base;
	logic [63:0] base;
} MemSegDesc;

typedef struct packed
{
	logic [5:0] rid;
	logic v;
	logic cmt;						// commit, clears as soon as committed
	logic cmt2;						// sticky commit, clears when entry reassigned
	logic vcmt;						// entire vector is committed.
	logic dec;						// instruction decoded
	logic out;						// instruction is out being executed
	Address ip;
	Instruction ir;
	Instruction lsm_mask;
	logic is_vec;
	logic jump;
	Address jump_tgt;
	logic [3:0] btag;			// Branch tag
	logic veins;
	logic branch;
	logic call;
	logic mem_op;
	logic lsm;
	logic exec;
	logic myst;
	logic [5:0] count;		// LDM / STM count
	logic mc;							// multi-cycle op
	logic takb;
	logic predict_taken;
	logic rfwr;
	logic ca_rfwr;				// write code address register file
	logic srfwr;					// write selector register file
	logic vrfwr;					// write vector register file
	logic vmrfwr;					// write vector mask register file
	logic [5:0] Rt;
	logic [5:0] Ra;
	logic [5:0] Rb;				// for VEX
	logic [5:0] Rc;
	logic [5:0] Rd;
	logic [5:0] Rm;
	logic Ravec;
	logic Rbvec;
	logic Rcvec;
	logic Rdvec;
	logic Rbsel;
	logic Rtsel;
	logic [5:0] pRt;			// physical Rt
	logic [5:0] step;			// vector step
	logic step_v;
	Value ia;
	Value ib;
	Value ic;
	Value id;
	logic [5:0] ia_ele;
	logic [5:0] ib_ele;
	logic [5:0] ic_ele;
	logic [5:0] id_ele;
	logic [5:0] it_ele;
	logic [127:0] imm;
	Value vmask;						// vector mask register value
	logic z;
	logic iav;
	logic ibv;
	logic icv;
	logic idv;
	logic itv;
	logic vmv;
	SrcId ias;
	SrcId ibs;
	SrcId ics;
	SrcId ids;
	logic idib;					// id comes from ia
	SrcId its;
	SrcId vms;
	Value res;
	sFPFlags fp_flags;
	logic [5:0] res_ele;
//	logic [15:0] cause;
	logic [2:0] irq_level;
	logic lockout;
	Address badAddr;
	logic wr_fu;				// write to functional unit
	logic [47:0] rob_q;
} sReorderEntry;

// Detect if a source is automatically valid
function Source1Valid;
input Instruction isn;
casez(isn.any.opcode)
// BUnit:	
BRK:	Source1Valid = TRUE;
R1:
	case(isn.r1.func)
	endcase
R2:
	case(isn.r2.func)
	endcase
R3:
	case(isn.r3.func)
	CHK:	Source1Valid = isn.r3.Ra==6'd0;
	MUX:	Source1Valid = isn.r3.Ra==6'd0;
	default:	Source1Valid = TRUE;
	endcase
ADDI,SUBFI,MULI,ANDI,ORI,XORI,ADCI,SBCFI,MULUI,CSR:
	Source1Valid = isn.ri.Ra==6'd0;
OSR2:
	case(isn.r2.func)
	RTE:	Source1Valid = isn.r2.Ra==6'd0;
	SEI:	Source1Valid = isn.r2.Ra==6'd0;
	REX:	Source1Valid = isn.r2.Ra==6'd0;
	default: Source1Valid = TRUE;
	endcase
// Branches
8'h2x:	Source1Valid = isn.br.Ra==6'd0;
8'h3x:	Source1Valid = isn.br.Ra==6'd0;
DIVI,CPUID,DIVIL,ADDIL,CHKI,MULIL,SNEIL,ANDIL,ORIL,XORIL,SEQIL,BMAPI,MULUI,DIVUI:
	Source1Valid = isn.ri.Ra==6'd0;
CMPI,ADDIS,BYTNDXI,WYDNDXI,UTF21NDXI,ANDIS,ORIS,XORIS:
	Source1Valid = isn.ri.Ra==6'd0;
VM:
	case(isn.vmr2.func)
	MFVM:	Source1Valid = TRUE;
	MFVL:	Source1Valid = FALSE;
	MTVM:	Source1Valid = isn[17:12]==6'd0;
	MTVL:	Source1Valid = isn[17:12]==6'd0;
	VMADD,VMAND,VMOR,VMXOR,VMSLL,VMSRL,VMSUB:
	:	Source1Valid = FALSE;
	VMCNTPOP,VMFIRST,VMLAST:
		Source1Valid = TRUE;
	default:	Source1Valid = TRUE;
	endcase
VMFILL:	Source1Valid = TRUE;
CMPIL:	Source1Valid = isn.ri.Ra==6'd0;
F1:
	case(isn.r1.func)
	FSYNC:		Source1Valid = TRUE;
	default:	Source1Valid = isn.r1.Ra==6'd0;
	endcase
F2:	Source1Valid = isn.r2.Ra==6'd0;
F3:	Source1Valid = isn.r3.Ra==6'd0;
DF1:
	case(isn.r1.func)
	DFSYNC:		Source1Valid = TRUE;
	default:	Source1Valid = isn.r1.Ra==6'd0;
	endcase
DF2:	Source1Valid = isn.r2.Ra==6'd0;
DF3:	Source1Valid = isn.r3.Ra==6'd0;
P1:
	case(isn.r1.func)
	PSYNC:		Source1Valid = TRUE;
	default:	Source1Valid = isn.r1.Ra==6'd0;
	endcase
P2:	Source1Valid = isn.r2.Ra==6'd0;
P3:	Source1Valid = isn.r3.Ra==6'd0;
CMPIS:	Source1Valid = isn.ri.Ra==6'd0;
F1L:
	case(isn.r1l.func)
	FSYNC:		Source1Valid = TRUE;
	default:	Source1Valid = isn.r1.Ra==6'd0;
	endcase
F2L:	Source1Valid = isn.r2.Ra==6'd0;
DF1L:
	case(isn.r1l.func)
	DFSYNC:		Source1Valid = TRUE;
	default:	Source1Valid = isn.r1.Ra==6'd0;
	endcase
DF2L:	Source1Valid = isn.r2.Ra==6'd0;
P1L:
	case(isn.r1l.func)
	PSYNC:		Source1Valid = TRUE;
	default:	Source1Valid = isn.r1.Ra==6'd0;
	endcase
P2L:	Source1Valid = isn.r2.Ra==6'd0;
8'h8x:	Source1Valid = isn.ld.Ra==6'd0;
8'h9x:	Source1Valid = isn.st.Ra==6'd0;
SYS:	Source1Valid = TRUE;
INT:	Source1Valid = TRUE;
MOV:	Source1Valid = isn.r1.Ra==6'd0;
BTFLD:	Source1Valid = isn.r1.Ra==6'd0;
LDxX:	Source1Valid = isn.ldx.Ra==6'd0;
STxX:	Source1Valid = isn.stx.Ra==6'd0;
8'hDx:Source1Valid = isn.ld.Ra==6'd0;
8'hEx:Source1Valid = isn.st.Ra==6'd0;
NOP:	Source1Valid = TRUE;
RTS:	Source1Valid = isn.rts.Ra==2'd0;
BCD:	Source1Valid = isn.r1.Ra==6'd0;
SYNC,MEMSB,MEMDB,WFI:	Source1Valid = TRUE;
SEI:	Source1Valid = isn.r1.Ra==2'd0;
default:
	Source1Valid = TRUE;
endcase
endfunction

function Source2Valid;
input Instruction isn;
casez(isn.any.opcode)
// BUnit:	
BRK:	Source2Valid = TRUE;
R1:
	case(isn.r1.func)
	endcase
R2:
	case(isn.r2.func)
	endcase
R3:
	case(isn.r3.func)
	CHK:	Source2Valid = isn.r3.Rb==6'd0 || isn.r3.Tb[1];
	MUX:	Source2Valid = isn.r3.Rb==6'd0 || isn.r3.Tb[1];
	default:	Source1Valid = TRUE;
	endcase
ADDI,SUBFI,MULI,ANDI,ORI,XORI,ADCI,SBCFI,MULUI,CSR:
	Source2Valid = TRUE;
OSR2:
	case(isn.r2.func)
	RTE:	Source2Valid = TRUE;
	SEI:	Source2Valid = TRUE;
	REX:	Source2Valid = TRUE;
	default: Source2Valid = TRUE;
	endcase
// Branches
8'h2x:	Source2Valid = isn.br.Rb==6'd0 || isn.br.Tb[1];
8'h3x:	Source2Valid = isn.br.Rb==6'd0 || isn.br.Tb[1];
DIVI,CPUID,DIVIL,ADDIL,CHKI,MULIL,SNEIL,ANDIL,ORIL,XORIL,SEQIL,BMAPI,MULUI,DIVUI:
	Source2Valid = TRUE;
CMPI,ADDIS,BYTNDXI,WYDNDXI,UTF21NDXI,ANDIS,ORIS,XORIS:
	Source2Valid = TRUE;
VM:
	case(isn.vmr2.func)
	MFVM:	Source2Valid = FALSE;
	MFVL:	Source2Valid = TRUE;
	MTVM:	Source2Valid = TRUE;
	MTVL:	Source2Valid = TRUE;
	VMADD,VMAND,VMOR,VMXOR,VMSLL,VMSRL,VMSUB:
	:	Source2Valid = FALSE;
	VMCNTPOP,VMFIRST,VMLAST:
		Source2Valid = FALSE;
	default:	Source2Valid = TRUE;
	endcase
VMFILL:	Source2Valid = TRUE;
CMPIL:	Source2Valid = TRUE;
//`FUnit:
F1:
	case(isn.r1.func)
	FSYNC:		Source2Valid = TRUE;
	default:	Source2Valid = TRUE;
	endcase
F2:	Source2Valid = isn.r2.Rb==6'd0 || isn.r2.Tb[1];
F3:	Source2Valid = isn.r3.Rb==6'd0 || isn.r3.Tb[1];
DF1:
	case(isn.r1.func)
	DFSYNC:		Source2Valid = TRUE;
	default:	Source2Valid = TRUE;
	endcase
DF2:	Source2Valid = isn.r2.Rb==6'd0 || isn.r2.Tb[1];
DF3:	Source2Valid = isn.r3.Rb==6'd0 || isn.r2.Tb[1];
P1:
	case(isn.r1.func)
	PSYNC:		Source2Valid = TRUE;
	default:	Source2Valid = TRUE;
	endcase
P2:	Source2Valid = isn.r2.Rb==6'd0 || isn.r2.Tb[1];
P3:	Source2Valid = isn.r3.Rb==6'd0 || isn.r3.Tb[1];
CMPIS:	Source2Valid = TRUE;
F1L:
	case(isn.r1l.func)
	FSYNC:		Source2Valid = TRUE;
	default:	Source2Valid = TRUE;
	endcase
F2L:	Source2Valid = isn.r2.Rb==6'd0 || isn.r2.Tb[1];
DF1L:
	case(isn.r1l.func)
	DFSYNC:		Source2Valid = TRUE;
	default:	Source2Valid = TRUE;
	endcase
DF2L:	Source2Valid = isn.r2.Rb==6'd0 || isn.r2.Tb[1];
P1L:
	case(isn.r1l.func)
	PSYNC:		Source2Valid = TRUE;
	default:	Source2Valid = TRUE;
	endcase
P2L:	Source2Valid = isn.r2.Rb==6'd0 || isn.r2.Tb[1];
8'h8x:	Source2Valid = isn.ld.v ? isn.r2.Rb==6'b0 || isn.r2.Tb[1] : TRUE;
8'h9x:	Source1Valid = isn.st.Rb==6'd0 || isn.r2.Tb[1];
SYS:	Source2Valid = TRUE;
INT:	Source2Valid = TRUE;
MOV:	Source2Valid = TRUE;
BTFLD:	
	case(isn.rm.func)
	BFINSI:	Source2Valid = TRUE;
	default:	Source2Valid = isn.r2.Rb==6'd0 || isn.r2.Tb[1];
	endcase
LDxX:	Source2Valid = isn.ldx.Rb==6'd0 || isn.ldx.Tb[1];
STxX:	Source2Valid = isn.stx.Rb==6'd0 || isn.stx.Tb[1];
8'hDx:Source2Valid = isn.ld.v ? isn.r2.Rb==6'b0 || isn.r2.Tb[1] : TRUE;
8'hEx:Source2Valid = isn.st.Rb==6'd0 || isn.r2.Tb[1];
NOP:	Source2Valid = TRUE;
RTS:	Source2Valid = TRUE;
BCD:	Source2Valid = isn.r2.Rb==6'd0 || isn.r2.Tb[1];
SYNC,MEMSB,MEMDB,WFI:	Source2Valid = TRUE;
SEI:	Source2Valid = TRUE;
default:
	Source2Valid = TRUE;
endcase
endfunction

function Source3Valid;
input Instruction isn;
casez(isn.any.opcode)
R3:
	case(isn.r3.func)
	CHK:	Source3Valid = isn.r3.Rc==6'd0 || isn.r3.Tc[1];
	MUX:	Source3Valid = isn.r3.Rc==6'd0 || isn.r3.Tc[1];
	default:	Source3Valid = TRUE;
	endcase
// Branches
8'h2x:	Source3Valid = FALSE;
8'h3x:	Source3Valid = FALSE;
F3:	Source3Valid = isn.r3.Rc==6'd0 || isn.r3.Tc[1];
DF3:	Source3Valid = isn.r3.Rc==6'd0 || isn.r2.Tc[1];
P3:	Source3Valid = isn.r3.Rc==6'd0 || isn.r3.Tc[1];
8'h9x:	Source3Valid = isn.st.v ? isn.r3.Rc==6'd0 || isn.r3.Tc[1] : TRUE;
BTFLD:	Source3Valid = isn.rm.Rc==6'd0 || isn.rm.Tc[1];
STxX:	Source3Valid = isn.stx.Rc==6'd0 || isn.stx.Tc[1];
8'hEx:Source3Valid = isn.r3.Rc==6'd0 || isn.r3.Tc[1];
default:
	Source3Valid = TRUE;
endcase
endfunction

endpackage
