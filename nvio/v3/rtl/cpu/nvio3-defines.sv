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

`define BYTE0		7:0
`define BYTE1		15:8
`define BYTE2		23:16
`define BYTE3		31:24
`define BYTE4		39:32
`define BYTE5		47:40
`define BYTE6		55:48
`define BYTE7		63:56
`define BYTE8		71:64
`define BYTE9		79:72
`define BYTE10	87:80
`define BYTE11	95:88
`define BYTE12	103:96
`define BYTE13	111:104
`define BYTE14	119:112
`define BYTE15	127:120
`define BYTE16	135:128
`define BYTE17	143:136
`define BYTE18	151:144
`define BYTE19	159:152
`define BYTE20	167:160
`define BYTE21	175:168
`define BYTE22	183:176
`define BYTE23	191:184
`define BYTE24	199:192
`define BYTE25	207:200
`define BYTE26	215:208
`define BYTE27	223:216
`define BYTE28	231:224
`define BYTE29	239:232
`define BYTE30	247:240
`define BYTE31	255:248

`define WYDE0		15:0
`define WYDE1		31:16
`define WYDE2		47:32
`define WYDE3		63:48
`define WYDE4		79:64
`define WYDE5		95:80
`define WYDE6		111:96
`define WYDE7		127:112
`define WYDE8		143:128
`define WYDE9		159:144
`define WYDE10	175:160
`define WYDE11	191:176
`define WYDE12	207:192
`define WYDE13	223:208
`define WYDE14	239:224
`define WYDE15	255:240

`define TETRA0	31:0
`define TETRA1	63:32
`define TETRA2	95:64
`define TETRA3	127:96
`define TETRA4	159:128
`define TETRA5	191:160
`define TETRA6	223:192
`define TETRA7	255:224

`define OCTA0		63:0
`define OCTA1		127:64
`define OCTA2		191:128
`define OCTA3		255:191

`define HEXI0		127:0
`define HEXI1		255:128

//`define Q2VECTORS   1'b1

// Branch Unit
`define BLT			5'h00
`define BGE			5'h01
`define BLE			5'h02
`define BGT			5'h03
`define BEQ			5'h04
`define BNE			5'h05
`define BCS			5'h06
`define BCC			5'h07
`define BVS			5'h08
`define BVC			5'h09
`define BUS			5'h0A
`define BUC			5'h0B

`define JSR			8'hD0
`define RTS			8'hD1
`define NOP			8'hD2
`define JRL			8'hD3
`define BRANCH	8'hD4

`define CHKI		4'hC
`define CHK			4'hD
`define BMISC		8'hDC
`define BRK			4'h0
`define PFI			4'h1
`define BMISC2	8'hDD
`define RTI			4'h0
`define REX			4'h1
`define SYNC		4'h2
`define SEI			4'h3
`define WAIT		4'h4
`define EXEC		4'h5
`define MTL			4'h6
`define MFL			4'h7
`define CRLOG		4'h8
`define CRAND			4'h8
`define CROR			4'h9
`define CRXOR			4'hA
`define CRANDC		4'hB
`define CRNAND		4'hC
`define CRNOR			4'hD
`define CRXNOR		4'hE
`define CRORC			4'hF
`define MTCR		4'hA
`define MFCR		4'hB
`define MEMDB		4'hC
`define MEMSB		4'hD


// Integer Operations
`define R3			6'b00001?
`define ADDI		8'h84
`define ANDI		6'h88
`define ORI			6'h89
`define XORI		6'h8A
`define CSRRW		8'hA5
`define CMPI		8'h98
`define CMPUI		8'h99
`define CHKI		8'h9A
`define BITI		8'h9B
`define MULIr		8'hA0
`define DIVIr		8'hA2
`define ADDIr		8'hA4
`define MODIr		8'hA6
`define ANDIr		8'hA8
`define ORIr		8'hA9
`define EORIr		8'hAA
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
`define BIT			6'h1B
`define BYTNDXI	6'h1C
`define WYDNDXI	6'h1D
`define DIFI		6'h1F
`define MULI		8'h80
`define MULUI		8'h81
`define MULSUI	8'h90
`define DIV			6'h22
`define DIVU		6'h23
`define DIVI		8'h82
`define DIVUI		8'h83
`define DIVSUI	8'h92
`define MOD			6'h24
`define MODU		6'h25
`define MODI		8'h86
`define MODUI		8'h87
`define MODSUI	8'h96
`define MADF		6'h28
`define MAJ			6'h2C
`define FXMULI	6'h30

// R1 Format
`define CNTLZ       6'h00
`define CNTLO       6'h01
`define CNTPOP      6'h02
`define COM         6'h03
`define ABS         6'h04
`define NOT         6'h05
`define SWAP				6'h13
`define V2BITS			6'h20
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
`define CMPRSS		6'h22

// R2 Format
`define MULH		6'h00
`define MULUH		6'h01
`define ADD			6'h04
`define SUB			6'h05
`define CMP			6'h06
`define CMPU		6'h07
`define MUL			6'h20
`define MULU		6'h21
`define FXMUL		6'h30

// R3 Format
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
`define FLT1		8'hE1
`define FLT2		8'hE2
`define FLT2S		8'hE8
`define FLT2I		8'hE3
`define FMA			8'hE4
`define FMS			8'hE5
`define FNMA		8'hE6
`define FNMS		8'hE7
// FLT2,FLT2S
`define FMAX		6'h02
`define FMIN		6'h03
`define FADD    6'h04
`define FSUB    6'h05
`define FCMP    6'h06
`define FCMPM		6'd07
`define FMUL    6'h08
`define FDIV    6'h09
`define FREM		6'h0A
`define FNXT		6'h0B
`define FAND		6'h0C
`define FOR			6'h0D

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

`define MEMORY	8'b0???????

// Load operations
`define LOADS		8'h0x,8'h1x,8'h4x,8'h5x
`define LDB			8'h00
`define LDW			8'h01
`define LDT			8'h02
`define LDO			8'h03
`define LDH			8'h04
`define LDHR		8'h05
`define LDP			8'h06
`define LDL			8'h07
`define LDBU		8'h08
`define LDWU		8'h09
`define LDTU		8'h0A
`define LDOU		8'h0B
`define AMO			8'h0E
`define POP			8'h0F
`define LDPU		8'h1B
`define LDST		8'h5E
`define LEA			8'h30
`define LDFS		8'h12
`define LDFD		8'h13
`define LDFQ		8'h14
//`define LDMX		6'h19
`define LDM			8'h19
`define UNLK		8'h3E
`define LOAD		8'b0?0?????

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
`define STB			8'h20
`define STW			8'h21
`define STT			8'h22
`define STO			8'h23
`define STH			8'h24
`define STHC		8'h25
`define STP			8'h26
`define STL			8'h27
`define CAS			8'h28
`define PUSH		8'h29
`define PUSHC		8'h2A
`define TLB			8'h2D
`define CACHE		8'h2E
`define STFS		8'h32
`define STFD		8'h33
`define STFQ		8'h34
`define STM			8'h3B
`define STST		8'h7E
`define LINK		8'h3D
`define STORE		8'b0?1?????


`define R2		8'h8C
`define R2S		8'h8D
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

// Floating point exceptions
`define FPX_IOP			8'd225		// invalid operation
`define FPX_DBZ			8'd226		// divide by zero
`define FPX_OVER		8'd227		// result overflowed
`define FPX_UNDER		8'd228		// result underflowed
`define FPX_INEXACT	8'd229		// inexact result
`define FPX_SWT			8'd231		// software triggered

`define OPCODE			7:0
`define AFUNCT6			40:35
`define BFUNCT4			39:36
`define FUNCT5			39:35
`define FUNCT6			28:23
`define FFUNCT5			27:23
`define CRLOGFN			31:28
`define SCALE				30:28
`define FMT4				32:29
`define FUNCT2			34:33
`define M3					39:37
`define AM					38:37
`define AMX					32:31
`define SZ3					30:28
`define RD3					10:8
`define RD2					9:8
`define RD					12:8
`define RS1					17:13
`define RS2					22:18
`define RS3					27:23
`define RS4					33:31
`define LXFUNCT5		22:18
`define SXFUNCT5		12:8

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

`define IBTOP			220
`define IB_FMT		219:216
`define IB_PFXINSN	215
`define IB_PFX		214
`define IB_RS3		213:208
`define IB_CONST	207:80
`define IB_CONST31	110:80
`define IB_CONST21	100:80
`define IB_CONST19	98:80
`define IB_LN			78:76
`define IB_RD			75:71
`define IB_RS1		61:56
`define IB_RS2		55:50
`define IB_BRCC		49
`define IB_CMP		48
`define IB_PUSH		47
`define IB_TLB		46
`define IB_VSET		44
`define IB_Z			43
`define IB_IRQ		42
`define IB_RTI		41
`define IB_BRK		40
`define IB_RTS		39
`define IB_JRL		38
`define IB_ODDBALL	37
`define IB_STORE	36
`define IB_MEMSZ	35:33
`define IB_MEM2		32
`define IB_IMM		31
`define IB_MEM    30
`define IB_POP		29
`define IB_BT     28
`define IB_ALU		27
`define IB_PUSHC	26
`define IB_FPU		25
`define IB_FC			24
`define IB_CANEX	23
`define IB_LOAD		22
`define IB_PRELOAD	21
`define IB_MEMNDX	20
`define IB_RMW		19
`define IB_MEMDB	18
`define IB_MEMSB	17
`define IB_JSR		16
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
