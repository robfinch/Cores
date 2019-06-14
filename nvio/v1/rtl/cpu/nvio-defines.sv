// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
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
`define ZERO		64'd0
`define HIGH        1'b1
`define LOW         1'b0
`define TRUE        1'b1
`define FALSE       1'b0
`define INV		1'b0
`define VAL		1'b1

//`define Q2VECTORS   1'b1

`define NUnit		3'd0
`define BUnit		3'd1
`define IUnit		3'd2
`define FUnit		3'd3
`define MUnit	3'd4
`define MUnit	3'd5

// Branch Unit
`define Bcc			4'h0
`define BLcc		4'h1
`define BRcc		4'h2
`define NOP			4'h3
`define FBcc		4'h4
`define BBc			4'h5
`define BEQI		4'h6
`define BNEI		4'h7
`define JAL			4'h8
`define JMP			4'h9
`define CALL		4'hA
`define RET			4'hB
`define CHKI		4'hC
`define CHK			4'hD
`define BMISC		4'hE
`define BRK			4'hF
`define RTI			5'h00
`define PFI			5'h01
`define REX			5'h01
`define SYNC		5'h02
`define SEI			5'h03
`define WAIT		5'h04
`define EXEC		5'h05

// Integer Operations
`define R3			6'b0001?
`define ANDI		6'h08
`define ORI			6'h09
`define XORI		6'h0A
`define ADD			6'h04
`define ADDI		6'h04
`define CSRRW		6'h05
`define CMP			6'h06
`define CMPU		6'h07
`define AND			6'h08
`define OR			6'h09
`define XOR			6'h0A
`define BITFIELD	6'h?B
`define BLEND		6'h0C
`define MULF		6'h0F
`define MULFI		6'h0F
`define SLT			6'h10
`define SGE			6'h11
`define SLE			6'h12
`define SGT			6'h13
`define SLTU		6'h14
`define SGEU		6'h15
`define SLEU		6'h16
`define SGTU		6'h17
`define SEQ			6'h18
`define SNE			6'h19
`define SLTI		6'h10
`define SGEI		6'h11
`define SLEI		6'h12
`define SGTI		6'h13
`define SLTUI		6'h14
`define SGEUI		6'h15
`define SLEUI		6'h16
`define SGTUI		6'h17
`define SEQI		6'h18
`define SNEI		6'h19
`define BYTNDXI	6'h1C
`define WYDNDXI	6'h1D
`define DIFI		6'h1F
`define MUL			6'h20
`define MULI		6'h20
`define MULU		6'h21
`define MULUI		6'h21
`define DIV			6'h22
`define DIVI		6'h22
`define DIVU		6'h23
`define DIVUI		6'h23
`define MOD			6'h24
`define MODI		6'h24
`define MODU		6'h25
`define MODUI		6'h25
`define MADF		6'h28
`define MAJ			6'h2C
`define FXMUL		6'h30
`define FXMULI	6'h30
`define ADDS0		6'h33
`define ADDS1		6'h34
`define ADDS2		6'h35
`define ADDS3		6'h36
`define ANDS0		6'h37
`define ANDS1		6'h38
`define ANDS2		6'h39
`define ANDS3		6'h3A
`define ORS1		6'h3C
`define ORS2		6'h3D
`define ORS3		6'h3E
`define ORS0		6'h3F

// R1 Format
`define CNTLZ       5'h00
`define CNTLO       5'h01
`define CNTPOP      5'h02
`define COM         5'h03
`define ABS         5'h04
`define NOT         5'h05
//`define REDOR       5'h06
`define PTR					5'h06
`define NEG         5'h07
`define ZXT					5'h08
`define ZXC					5'h09
`define ZXB					5'h0A
`define ZXP					5'h0B
`define ZXO					5'h0C
`define MOV					5'h10
`define EXEC				5'h13
`define SETWB				5'h16
//`define REDAND			5'h17
`define SXT					5'h18
`define SXC					5'h19
`define SXB					5'h1A
`define SXP					5'h1B
`define SXO					5'h1C

// R3 Format
`define MULH		6'h00
`define MULUH		6'h01
`define ADDV		6'h02
`define SUBV		6'h03
`define SUB			6'h05
`define NAND		6'h0C
`define NOR			6'h0D
`define XNOR		6'h0E
`define CMOVNZ	6'h1B
`define MIN			6'h1C
`define MAX			6'h1D
`define PTRDIF	6'h1E
`define DIF			6'h1F
`define BYTNDX	6'h2A
`define WYDNDX	6'h2B
`define AVG			6'h2D
`define MUX			6'h29
`define FXDIV		6'h31
`define SHL			6'h32
`define ASL			6'h33
`define SHR			6'h34
`define ASR			6'h35
`define ROL			6'h36
`define ROR			6'h37
`define SHLI		6'h38
`define ASLI		6'h39
`define SHRI		6'h3A
`define ASRI		6'h3B
`define ROLI		6'h3C
`define RORI		6'h3D
`define BMM			6'h3E

// Floating Point Operations
`define FLT1		4'h1
`define FLT2		4'h2
`define FLT3		4'h3
`define FLT1A		4'h5
`define FLT2I		4'h6
`define FLT2LI	4'hA
`define FANDI		4'hE
`define FORI		4'hF
`define FMA			5'h0
`define FMS			5'h1
`define FNMA		5'h2
`define FNMS		5'h3
`define FMAX		5'h10
`define FMIN		5'h11

`define FADD    5'h04
`define FSUB    5'h05
`define FCMP    5'h06
`define FMUL    5'h08
`define FDIV    5'h09
`define FAND		5'h0C
`define FOR			5'h0D

`define FMOV    5'h00
`define FTOI    6'h02
`define ITOF    5'h03
`define FNEG    5'h04
`define FABS    5'h05
`define FSIGN   5'h06
`define FMAN    5'h07
`define FNABS   5'h08
`define FCVTSD  5'h09
`define FCVTSQ  5'h0B
`define FSTAT   5'h0C
`define FSQRT		5'h0D

`define FTX     5'h10
`define FCX     5'h11
`define FEX     5'h12
`define FDX     5'h13
`define FRM     5'h14
`define FCVTDS  5'h19
`define FSYNC   5'h16

`define FSLT		5'h10
`define FSGE		5'h11
`define FSLE		5'h12
`define FSGT		5'h13
`define FSEQ		5'h14
`define FSNE		5'h15
`define FSUN		5'h16

// Load operations
`define LDB			6'h00
`define LDC			6'h01
`define LDP			6'h02
`define LDD			6'h03
`define LDBU		6'h04
`define LDCU		6'h05
`define LDPU		6'h06
`define LDDR		6'h07
`define LDT			6'h08
`define LDO			6'h09
`define AMO			6'h0A
`define LDTU		6'h0C
`define LDOU		6'h0D
`define LEA			6'h0E
`define MLX			6'h0F
`define LDFS		6'h10
`define LDFD		6'h11
`define LDFDP		6'h12
`define LDDP		6'h13
`define LOAD		6'b0?????
`define LDDRX		5'h07
`define LEAX		5'h0E

`define AMOSWAP		5'h00
`define AMOSWAPI	5'h01
`define AMOADD		5'h02
`define AMOADDI		5'h03
`define AMOAND		5'h04
`define AMOANDI		5'h05
`define AMOOR			5'h06
`define AMOORI		5'h07
`define AMOXOR		5'h08
`define AMOXORI		5'h09
`define AMOSHL		5'h0A
`define AMOSHLI		5'h0B
`define AMOSHR		5'h0C
`define AMOSHRI		5'h0D
`define AMOMIN		5'h0E
`define AMOMINI		5'h0F
`define AMOMAX		5'h10
`define AMOMAXI		5'h11
`define AMOMINU		5'h12
`define AMOMINUI	5'h13
`define AMOMAXU		5'h14
`define AMOMAXUI	5'h15

// Store Operations
`define STB			6'h20
`define STC			6'h21
`define STP			6'h22
`define STD			6'h23
`define STDC		6'h27
`define STT			6'h28
`define STO			6'h29
`define CAS			6'h2A
`define PUSHC		6'h?B
`define TLB			6'h2C
`define PUSH		6'h2D
`define CACHE		6'h2E
`define MSX			6'h2F
`define STFS		6'h30
`define STFD		6'h31
`define STFDP		6'h32
`define STDP		6'h33
`define STDCX		5'd07
`define CASX		5'h0A
`define CACHEX	5'h0E
`define MEMSB		5'd24
`define MEMDB		5'd25
`define STORE		6'b1?????

`define R2		6'h02
`define RR      6'h02
`define BCD         6'h00
`define BCDADD          5'h00
`define BCDSUB          5'h01
`define BCDMUL          5'h02
`define PCRELX		6'h02
`define AUIPC	6'h03
// Register / Miscellaneous (01) Ops
`define R1      	6'h01
// Register-Register (02) Ops
`define RTOP				6'h00
`define BMM					6'h3E
`define ADD	        6'h04
`define SUB         6'h05

`define PFI_INSN	40'h083FC003C0
`define NOP_INSN	40'h00000000C0

// Floating Point


`define EXR			8'h7F

`define CSR_CR0     12'h000
`define CSR_HARTID  12'h001
`define CSR_TICK    12'h002
`define CSR_PCR     12'h003
`define CSR_PMR			12'h005
`define CSR_CAUSE   12'h006
`define CSR_BADADR  12'h007
`define CSR_PCR2    12'h008
`define CSR_SCRATCH 12'h009
`define CSR_WBRCD	12'h00A
`define CSR_BADINSTR	12'h00B
`define CSR_SEMA    12'h00C
`define CSR_KEYS		12'h00E
`define CSR_TCB			12'h010
`define CSR_FSTAT   12'h014
`define CSR_DBAD0   12'h018
`define CSR_DBAD1   12'h019
`define CSR_DBAD2   12'h01A
`define CSR_DBAD3   12'h01B
`define CSR_DBCTRL  12'h01C
`define CSR_DBSTAT  12'h01D
`define CSR_CAS     12'h02C
`define CSR_TVEC    12'b0000000110???
`define CSR_IM_STACK	12'h040
`define CSR_ODL_STACK	12'h041
`define CSR_PL_STACK	12'h042
`define CSR_RS_STACK	12'h043
`define CSR_STATUS 	12'h044
`define CSR_BRS_STACK	12'h046
`define CSR_IPC0    12'h048
`define CSR_IPC1    12'h049
`define CSR_IPC2    12'h04A
`define CSR_IPC3    12'h04B
`define CSR_IPC4    12'h04C
`define CSR_IPC5    12'h04D
`define CSR_IPC6    12'h04E
`define CSR_IPC7    12'h04F
`define CSR_GOLEX0	12'h050
`define CSR_GOLEX1	12'h051
`define CSR_GOLEX2	12'h052
`define CSR_GOLEX3	12'h053
`define CSR_GOLEXVP	12'h054
`define CSR_CODEBUF 12'b0000010??????
`define CSR_TB			12'h0C0
`define CSR_CBL			12'h0C1
`define CSR_CBU			12'h0C2
`define CSR_RO			12'h0C3
`define CSR_DBL			12'h0C4
`define CSR_DBU			12'h0C5
`define CSR_SBL			12'h0C6
`define CSR_SBU			12'h0C7
`define CSR_ENU			12'h0C8
`define CSR_PREGS		12'h0F0
`define CSR_Q_CTR		12'h3C0
`define CSR_BM_CTR	12'h3C1
`define CSR_ICL_CTR	12'h3C2
`define CSR_IRQ_CTR	12'h3C3
`define CSR_BR_CTR	12'h3C4
`define CSR_TIME		12'h3E0
`define CSR_INFO    12'hFF?

`define OL_USER         2'd3
`define OL_SUPERVISOR   2'd2
`define OL_HYPERVISOR   2'd1
`define OL_MACHINE      2'd0

`define FLT_NONE    8'd00
`define FLT_IBE     8'd01
`define FLT_EXF     8'd02
`define FLT_TLB			8'd04
`define FLT_SSM     8'd32
`define FLT_DBG     8'd33
`define FLT_TGT     8'd34
`define FLT_IADR    8'd36
`define FLT_UNIMP		8'd37
`define FLT_FLT     8'd38
`define FLT_CHK     8'd39
`define FLT_DBZ     8'd40
`define FLT_OFL     8'd41
`define FLT_SEG			8'd47
`define FLT_ALN			8'd48
`define FLT_DWF     8'd50
`define FLT_DRF     8'd51
`define FLT_SGB			8'd52
`define FLT_PRIV    8'd53
`define FLT_CMT			8'd54
`define FLT_BD			8'd55
`define FLT_STK     8'd56
`define FLT_DBE     8'd60
`define FLT_STP			8'd232		// segment type
`define FLT_STZ			8'd233		// stack segment zero
`define FLT_SNP			8'd234		// segment not present

`define OPCODE4			9:6
`define FUNCT5			39:35
`define FUNCT2			34:33
`define SZ3					30:28
`define RD					5:0
`define RS1					15:10
`define RS2					21:16
`define RS3					27:22

`define INSTRUCTION_IM  31:18
`define INSTRUCTION_IML	47:18
`define INSTRUCTION_SB  31
`define INSTRUCTION_S1  22:18
`define INSTRUCTION_S2  31:26
`define INSTRUCTION_S2L	47:42
`define INSTRUCTION_COND    21:18

`define DRAMSLOT_AVAIL	3'b000
`define DRAMSLOT_BUSY		3'b001
`define DRAMSLOT_RMW		3'b010
`define DRAMSLOT_RMW2		3'b011
`define DRAMSLOT_REQBUS	3'b101
`define DRAMSLOT_HASBUS	3'b110
`define DRAMREQ_READY		3'b111

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

`define IBTOP			165
`define IB_RS3		165:160
`define IB_CONST	159:80
`define IB_LN			78:76
`define IB_RD			75:71
`define IB_RS1		61:56
`define IB_RS2		55:50
`define IB_BRCC		49
`define IB_CMP		48
`define IB_PUSH		47
`define IB_TLB		46
`define IB_SZ			45:43
`define IB_IRQ		42
`define IB_RTI		41
`define IB_BRK		40
`define IB_RET		39
`define IB_JAL		38
`define IB_ODDBALL	37
`define IB_STORE	36
`define IB_MEMSZ	35:33
`define IB_IMM		31
`define IB_MEM    30
`define IB_BT     28
`define IB_ALU		27
`define IB_FPU		25
`define IB_FC			24
`define IB_CANEX	23
`define IB_LOAD		22
`define IB_PRELOAD	21
`define IB_MEMNDX	20
`define IB_RMW		19
`define IB_MEMDB	18
`define IB_MEMSB	17
`define IB_CALL		16
`define IB_SEI		15
`define IB_AQ			14
`define IB_RL			13
`define IB_JMP		12
`define IB_BR			11
`define IB_SYNC		10
`define IB_FSYNC	9
`define IB_RFW		8
`define IB_ALU0		7
`define IB_LEA		6
`define IB_WAIT		5
`define IB_REX		4
`define IB_CHK		3
`define IB_UNIT		2:0

`define TLB_NOP			4'd0
`define TLB_P				4'd1
`define TLB_RD			4'd2
`define TLB_WR			4'd3
`define TLB_WI			4'd4
`define TLB_EN			4'd5
`define TLB_DIS			4'd6
`define TLB_RDREG		4'd7
`define TLB_WRREG		4'd8
`define TLB_INVALL	4'd9
`define TLB_RDAGE		4'd10
`define TLB_WRAGE		4'd11

`define TLBWired			4'h0
`define TLBIndex			4'h1
`define TLBRandom			4'h2
`define TLBPageSize		4'h3
`define TLBVirtPage		4'h4
`define TLBPhysPage		4'h5
`define TLBASID				4'h7
`define TLBMissAdr		4'd8
`define TLBPageTblAddr	4'd10
`define TLBPageTblCtrl	4'd11
`define TLBAFC				4'd12
`define TLBPageCount	4'd13

`define EXC_RGS		6'h00
`define BRK_RGS		6'h10
