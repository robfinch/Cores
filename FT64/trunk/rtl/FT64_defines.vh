// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_defines.v
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
//`define DEBUG_LOGIC 1'b1
`define HIGH        1'b1
`define LOW         1'b0
`define TRUE        1'b1
`define FALSE       1'b0

`define ZERO		64'd0

`define BRK     6'h00
`define VECTOR  6'h01
`define VADD        6'h04
`define VSUB        6'h05
`define VSxx        6'h06
`define VSEQ            3'd0
`define VSNE            3'd1
`define VSLT            3'd2
`define VSGE            3'd3
`define VSLE            3'd4
`define VSGT            3'd5
`define VAND        6'h08
`define VOR         6'h09
`define VXOR        6'h0A
`define VADDS       6'h14
`define VSUBS       6'h15
`define VANDS       6'h18
`define VORS        6'h19
`define VXORS       6'h1A
`define RR      6'h02
`define BCD         6'h00
`define BCDADD          5'h00
`define BCDSUB          5'h01
`define BCDMUL          5'h02
`define BITFIELD    6'h02
`define SHIFT       6'h03
`define BccR    6'h03
`define SHL     4'h0
`define SHR     4'h1
`define ASL     4'h2
`define ASR     4'h3
`define ROL     4'h4
`define ROR     4'h5
`define SHLI    4'h8
`define SHRI    4'h9
`define ASLI    4'hA
`define ASRI    4'hB
`define ROLI    4'hC
`define RORI    4'hD
`define R1          6'h01
`define CNTLZ           5'h00
`define CNTLO           5'h01
`define CNTPOP          5'h02
`define ABS             5'h04
`define NOT             5'h05
`define REDOR           5'h06
`define SLT             5'h08
`define SGE             5'h09
`define SLE             5'h0A
`define SGT             5'h0B
`define ADD	        6'h04
`define SUB         6'h05
`define CMP         6'd6
`define CMPU        6'd7
`define AND         6'd8
`define OR          6'd9
`define XOR         6'h0A
`define NAND        6'h0C
`define NOR         6'h0D
`define XNOR        6'h0E
`define LHX         6'h10
`define LHUX        6'h11
`define LWX         6'h12
`define LBX         6'h13
`define SHX         6'h14
`define SBX         6'h15
`define SWX         6'h16
`define SWCX        6'h17
`define CALLR       6'h18
`define PUSH        6'h19
`define POP         6'h1A
`define UNLINK      6'h1B
`define LWRX        6'h1D
`define CACHEX      6'h1E
`define SHIFTB      6'h1F
`define LCX         6'h20
`define LCUX        6'h21
`define LBUX        6'h23
`define SCX         6'h24
`define CASX        6'h25
`define CMOVEQ      6'h28
`define CMOVNE      6'h29
`define MUX         6'h2A
`define DEMUX       6'h2B
`define MIN         6'h2C
`define MAX         6'h2D
`define XCHG        6'h2E
`define SHIFTC      6'h2F
`define SEI         6'h30
`define WAIT        6'h31
`define RTI         6'h32
`define VMOV        6'h33
`define MEMDB       6'h34
`define MEMSB       6'h35
`define SYNC        6'h36
`define MULU        6'h38
`define MULSU       6'h39
`define MUL         6'h3A
`define CHK         6'h3B
`define DIVMODU     6'h3C
`define DIVMODSU    6'h3D
`define DIVMOD      6'h3E
`define SHIFTH      6'h3F
`define ADDI	6'h04
`define CMPI    6'h06
`define CMPUI   6'h07
`define ANDI    6'h08
`define ORI     6'h09
`define XORI    6'h0A
`define FLOAT   6'h0B
`define TGT     6'h0C
`define REX     6'h0D
`define CSRRW   6'h0E
`define EXEC    6'h0F
`define LH      6'h10
`define LHU     6'h11
`define LW      6'h12
`define LB      6'h13
`define SH      6'h14
`define SB      6'h15
`define SW	    6'h16
`define SWC     6'h17
`define JAL	    6'h18
`define CALL    6'h19
`define IMML    6'h1A
`define IMMM    6'h1B
`define NOP     6'h1C
`define LWR     6'h1D
`define CACHE   6'h1E
`define LC      6'h20
`define LCU     6'h21
`define LBU     6'h23
`define SC      6'h24
`define CAS     6'h25
`define BBc     6'b10011x
`define JMP     6'h28
`define RET     6'h29
`define LINK    6'h2A
`define LCALL   6'h2B
`define MODUI   6'h2C
`define MODSUI  6'h2D
`define MODI    6'h2E
`define Bcc     6'b11000x
`define BEQ         4'd0
`define BNE         4'd1
`define BLT         4'd2
`define BGE         4'd3
`define BLTU        4'd4
`define BGEU        4'd5
`define FBEQ        4'd8
`define FBNE        4'd9
`define FBLT        4'd10
`define FBGE        4'd11
`define FBUN        4'd15
`define BEQI    6'b11001x
`define CHK     6'b11010x
`define MULUI   6'h38
`define MULSUI  6'h39
`define MULI    6'h3A
`define DIVUI   6'h3C
`define DIVSUI  6'h3D
`define DIVI    6'h3E

`define FMOV    6'h10
`define FTOI    6'h12
`define ITOF    6'h13
`define FNEG    6'h14
`define FABS    6'h15
`define FSIGN   6'h16
`define FMAN    6'h17
`define FNABS   6'h18
`define FCVTSD  6'h19
`define FCVTSQ  6'h1B
`define FSTAT   6'h1C
`define FTX     6'h20
`define FCX     6'h21
`define FEX     6'h22
`define FDX     6'h23
`define FRM     6'h24
`define FCVTDS  6'h29

`define FADD    6'h04
`define FSUB    6'h05
`define FCMP    6'h06
`define FMUL    6'h08
`define FDIV    6'h09


`define NOP_INSN    {26'd0,`NOP}

`define CSR_CR0     11'h000
`define CSR_HARTID  11'h001
`define CSR_TICK    11'h002
`define CSR_PCR     11'h003
`define CSR_CAUSE   11'h006
`define CSR_BADADR  11'h007
`define CSR_PCR2    11'h008
`define CSR_SEMA    11'h00C
`define CSR_SBL     11'h00E
`define CSR_SBU     11'h00F
`define CSR_FSTAT   11'h014
`define CSR_DBAD0   11'h018
`define CSR_DBAD1   11'h019
`define CSR_DBAD2   11'h01A
`define CSR_DBAD3   11'h01B
`define CSR_DBCTRL  11'h01C
`define CSR_DBSTAT  11'h01D
`define CSR_CAS     11'h02C
`define CSR_TVEC    11'b00000110xxx
`define CSR_EPC     11'h040
`define CSR_STATUSL 11'h044
`define CSR_STATUSH 11'h045
`define CSR_CODEBUF 11'b00010xxxxxx
`define CSR_INFO    11'b111_1111_xxxx

`define OL_USER         2'd3
`define OL_SUPERVISOR   2'd2
`define OL_HYPERVISOR   2'd1
`define OL_MACHINE      2'd0

// JALR and EXTENDED are synonyms
`define EXTEND	3'd7

// system-call subclasses:
`define SYS_NONE	3'd0
`define SYS_CALL	3'd1
`define SYS_MFSR	3'd2
`define SYS_MTSR	3'd3
`define SYS_RFU1	3'd4
`define SYS_RFU2	3'd5
`define SYS_RFU3	3'd6
`define SYS_EXC		3'd7	// doesn't need to be last, but what the heck

// exception types:
`define EXC_NONE	9'd000
`define EXC_HALT	9'd1
`define EXC_TLBMISS	9'd2
`define EXC_SIGSEGV	9'd3
`define EXC_INVALID	9'd4

`define FLT_NONE    9'd000
`define FLT_SSM     9'd480
`define FLT_DBG     9'd481
`define FLT_TGT     9'd482
`define FLT_IADR    9'd484
`define FLT_FLT     9'd486
`define FLT_CHK     9'd487
`define FLT_DBZ     9'd488
`define FLT_OFL     9'd489
`define FLT_EXF     9'd497
`define FLT_DWF     9'd498
`define FLT_DRF     9'd499
`define FLT_PRIV    9'd501
`define FLT_STK     9'd504
`define FLT_DBE     9'd508
`define FLT_IBE     9'd509

//`define INSTRUCTION_OP	15:13	// opcode
//`define INSTRUCTION_RA	12:10	// rA 
//`define INSTRUCTION_RB	9:7	// rB 
//`define INSTRUCTION_RC	2:0	// rC 
//`define INSTRUCTION_IM	6:0	// immediate (7-bit)
//`define INSTRUCTION_LI	9:0	// large unsigned immediate (10-bit, 0-extended)
//`define INSTRUCTION_SB	6	// immediate's sign bit
//`define INSTRUCTION_S1  6:4	// contains the syscall sub-class (NONE, CALL, MFSR, MTSR, EXC, etc.)
//`define INSTRUCTION_S2  3:0	// contains the sub-class identifier value

`define INSTRUCTION_OP  5:0
`define INSTRUCTION_RA  10:6
`define INSTRUCTION_RB  15:11
`define INSTRUCTION_RC  20:16
`define INSTRUCTION_RD  25:21
`define INSTRUCTION_IM  31:16
`define INSTRUCTION_SB  31
`define INSTRUCTION_S1  25:21
`define INSTRUCTION_S2  31:26
`define INSTRUCTION_COND    18:16

`define FORW_BRANCH	1'b0
`define BACK_BRANCH	1'b1

`define DRAMSLOT_AVAIL	2'b00
`define DRAMREQ_READY	2'b11

`define INV	1'b0
`define VAL	1'b1

//
// define PANIC types
//
`define PANIC_NONE		4'd0
`define PANIC_FETCHBUFBEQ	4'd1
`define PANIC_INVALIDISLOT	4'd2
`define PANIC_MEMORYRACE	4'd3
`define PANIC_IDENTICALDRAMS	4'd4
`define PANIC_OVERRUN		4'd5
`define PANIC_HALTINSTRUCTION	4'd6
`define PANIC_INVALIDMEMOP	4'd7
`define PANIC_INVALIDFBSTATE	4'd9
`define PANIC_INVALIDIQSTATE	4'd10
`define PANIC_BRANCHBACK	4'd11
`define PANIC_BADTARGETID	4'd12
