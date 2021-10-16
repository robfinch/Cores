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
parameter BLT			= 8'h2C;
parameter BGE			= 8'h2D;
parameter BLE			= 8'h2E;
parameter BGT			= 8'h2F;
parameter BBCL		= 8'h34;
parameter BBSL		= 8'h35;
parameter BEQL		= 8'h36;
parameter BNEL		= 8'h37;
parameter BLTL		= 8'h38;
parameter BGEL		= 8'h39;
parameter BLEL		= 8'h3A;
parameter BGTL		= 8'h3B;
parameter BLTL		= 8'h3C;
parameter BGEL		= 8'h3D;
parameter BLEL		= 8'h3E;
parameter BGTL		= 8'h3F;
parameter DIVI		= 8'h40;
parameter CPUID		= 8'h41;
parameter DIVIL		= 8'h42;
parameter MUX			= 8'h43;
parameter ADDIL		= 8'h44;
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
parameter BYTNDX	= 8'h55;
parameter WYDNDX	= 8'h56;
parameter UTF21NDX	= 8'h57;
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

// FLT1
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

// FLT2
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

// FLT3
parameter FMA		= 6'h00;
parameter FMS		= 6'h01;
parameter FNMA	= 6'h02;
parameter FNMS	= 6'h03;


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
	logic [55:0] pad;
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

typedef union packed
{
	bmapinst bmap;
	r3inst r3;
	r2inst r2;
	r1inst r1;
	rilinst ril;
	riinst ri;
	brinst br;
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
