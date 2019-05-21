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

`define BUnit		3'd1
`define IUnit		3'd2
`define FUnit		3'd3
`define MLdUnit	3'd4
`define MStUnit	3'd5

// Branch Unit
`define Bcc			4'h0
`define BLcc		4'h1
`define BRcc		4'h2
`define NOP			4'h3
`define FBcc		4'h4
`define BEQI		4'h6
`define BNEI		4'h7
`define JAL			4'h8
`define JMP			4'h9
`define CALL		4'hA
`define RET			4'hB
`define CHKI		4'hC
`define CHK			4'hD
`define RTI			4'hE
`define BRK			4'hF
`define REX			5'h01
`define SYNC		5'h02

// Integer Operations
`define R3			6'b0001?
`define ADD			6'h04
`define CSR			6'h05
`define CMP			6'h06
`define CMPU		6'h07
`define AND			6'h08
`define OR			6'h09
`define XOR			6'h0A
`define BLEND		6'h0C
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
`define MUL			6'h20
`define MULU		6'h21
`define DIV			6'h22
`define DIVU		6'h23
`define MOD			6'h24
`define MODU		6'h25
`define MADF		6'h28
`define FXMUL		6'h30
`define ADDS1		6'h34
`define ADDS2		6'h35
`define ADDS3		6'h36
`define ANDS1		6'h38
`define ANDS2		6'h39
`define ANDS3		6'h3A
`define ORS1		6'h3C
`define ORS2		6'h3D
`define ORS3		6'h3E

// R3 Format
`define MULH		6'h00
`define MULUH		6'h01
`define ADDV		6'h02
`define SUBV		6'h03
`define SUB			6'h05
`define NAND		6'h0C
`define NOR			6'h0D
`define XNOR		6'h0E
`define MOV			6'h1A
`define CMOVNZ	6'h1B
`define MIN			6'h1C
`define MAX			6'h1D
`define PTRDIF	6'h1E
`define MUX			6'h29
`define FXDIV		6'h31
`define SHL			6'h32
`define ASL			6'h33
`define SHR			6'h34
`define ASR			6'h35
`define ROL			6'h36
`define ROR			6'h37
`define SHL			6'h38
`define ASLI		6'h39
`define SHRI		6'h3A
`define ASRI		6'h3B
`define ROLI		6'h3C
`define RORI		6'h3D
`define BMM			6'h3E

// Floating Point Operations
`define FLT2		4'h1
`define FANDI		4'h2
`define FORI		4'h3
`define FMA			4'h4
`define FMS			4'h5
`define FNMA		4'h6
`define FNMS		4'h7

`define FADD    6'h04
`define FSUB    6'h05
`define FCMP    6'h06
`define FMUL    6'h08
`define FDIV    6'h09
`define FAND		6'h0C
`define FOR			6'h0D

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
`define FSQRT		6'h1D

`define FTX     6'h20
`define FCX     6'h21
`define FEX     6'h22
`define FDX     6'h23
`define FRM     6'h24
`define FCVTDS  6'h29
`define FSYNC   6'h36

`define FSLT		6'h38
`define FSGE		6'h39
`define FSLE		6'h3A
`define FSGT		6'h3B
`define FSEQ		6'h3C
`define FSNE		6'h3D
`define FSUN		6'h3E

// Load operations
`define LDB			4'h0
`define LDC			4'h1
`define LDP			4'h2
`define LDD			4'h3
`define LDBU		4'h4
`define LDCU		4'h5
`define LDPU		4'h6
`define LDDR		4'h7
`define LDT			4'h8
`define LDO			4'h9
`define LDTU		4'hC
`define LDOU		4'hD
`define LEA			4'hE
`define MSL			4'hF

// Store Operations
`define STB			4'h0
`define STC			4'h1
`define STP			4'h2
`define STD			4'h3
`define STDC		4'h7
`define STT			4'h8
`define STO			4'h9
`define CAS			4'hA
`define PUSHC		4'hB
`define TLB			4'hC
`define PUSH		4'hD
`define CACHE		4'hE
`define MSX			4'hF



`define R2		6'h02
`define RR      6'h02
`define BCD         6'h00
`define BCDADD          5'h00
`define BCDSUB          5'h01
`define BCDMUL          5'h02
`define PCRELX		6'h02
`define AUIPC	6'h03
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
// Register / Miscellaneous (01) Ops
`define R1      	6'h01
`define CNTLZ       5'h00
`define CNTLO       5'h01
`define CNTPOP      5'h02
`define COM         5'h03
`define ABS         5'h04
`define NOT         5'h05
//`define REDOR       5'h06
`define PTR					5'h06
`define NEG         5'h07
`define ZXH					5'h08
`define ZXC					5'h09
`define ZXB					5'h0A
`define MEMDB				5'h10
`define MEMSB				5'h11
`define SYNC        5'h12
`define EXEC				5'h13
`define CHAIN_OFF		5'h14
`define CHAIN_ON		5'h15
`define SETWB				5'h16
//`define REDAND			5'h17
`define SXH					5'h18
`define SXC					5'h19
`define SXB					5'h1A
// Register-Register (02) Ops
`define RTOP				6'h00
`define BMM					6'h03
`define ADD	        6'h04
`define SUB         6'h05
`define SLT         6'h06
`define SLTU        6'h07
`define AND         6'h08
`define OR          6'h09
`define XOR         6'h0A
`define SEQ					6'h0B
`define NAND        6'h0C
`define NOR         6'h0D
`define XNOR        6'h0E
`define SHIFT31     6'h0F
`define CMP					6'h12
`define MODU				6'h14
`define MODSU				6'h15
`define MOD					6'h16
`define LEAX        6'h18
`define MUX         6'h1B
`define PTRDIF			6'h1E
`define SHIFT63     6'h1F
`define MOV					6'b01001?
`define MULUH				6'h24
`define MULSUH			6'h25
`define MULH				6'h26
`define SLE     		6'h28
`define SLEU    		6'h29
`define MULF				6'h2A
// The following two instructions are 48 bit ops
`define CMOVEZ      6'h28	
`define CMOVNZ      6'h29
`define MIN         6'h2C
`define MAX         6'h2D
`define MAJ         6'h2E
`define SHIFTR      6'h2F
`define SEI         6'h30
`define WAIT        6'h31
`define RTI         6'h32
`define RTE         6'h32
`define VMOV        6'h33
`define MOV2SEG			6'h37
`define MULU        6'h38
`define MULSU       6'h39
`define MUL         6'h3A
`define FXMUL				6'h3B
`define DIVU     		6'h3C
`define DIVSU    		6'h3D
`define DIV      		6'h3E
`define SHIFTH      6'h3F
// Root Level Ops
`define ADDI		6'h04
`define CSRRW   6'h05
`define SLTI    6'h06
`define SLTUI   6'h07
`define ANDI    6'h08
`define ORI     6'h09
`define XORI    6'h0A
`define SEQI    6'h0B
`define REX     6'h0D
`define LEA			6'h0E
`define FLOAT   6'h0F
`define FBcc		6'h10
`define BRcc		6'h11
`define BAND				3'd4
`define BOR					3'd5
//`define BXOR				3'd2
//`define BXOR				3'd6
`define BNEI		6'h12
`define JAL	    6'h18
`define CALL    6'h19
`define SGTUI		6'h1C
`define BITFIELD    6'h22
`define BFINSI			4'h4
`define BBc     6'h26
`define IBNE			2'd2
`define DBNZ			2'd3
`define LUI			6'h27
`define JMP     6'h28
`define RET     6'h29
`define MULFI		6'h2A
`define SFx			6'h2B
`define SFS			6'h2B
`define SFD			6'h2B
`define SGTI		6'h2C
`define CMPRSSD	6'h2D
`define MODI    6'h2E
`define AMO			6'h2F
`define AMO_SWAP	6'h00
`define AMO_ADD		6'h04
`define AMO_AND		6'h08
`define AMO_OR		6'h09
`define AMO_XOR		6'h0A
`define AMO_SHL		6'h0C
`define AMO_SHR		6'h0D
`define AMO_MIN		6'h1C
`define AMO_MAX		6'h1D
`define AMO_MINU	6'h1E
`define AMO_MAXU	6'h1F
`define Bcc     6'h30
`define BEQ         3'd0
`define BNE         3'd1
`define BLT         3'd2
`define BGE         3'd3
`define BNAND				3'd4
`define BNOR				3'd5
`define BLTU        3'd6
`define BGEU        3'd7
`define IVECTOR	6'h31
`define BEQI    6'h32
`define LW			6'h33
`define LWR     6'h33
`define CHK     6'h34
`define SH			6'h35
`define SW			6'h35
`define LV      6'h36
`define SV      6'h37
`define MULUI   6'h38
`define MULSUI  6'h39
`define MULI    6'h3A
`define DIVUI   6'h3C
`define NOP     6'h3D
`define DIVI    6'h3E

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
`define CSR_EPC0    12'h048
`define CSR_EPC1    12'h049
`define CSR_EPC2    12'h04A
`define CSR_EPC3    12'h04B
`define CSR_EPC4    12'h04C
`define CSR_EPC5    12'h04D
`define CSR_EPC6    12'h04E
`define CSR_EPC7    12'h04F
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
`define DRAMSLOT_BUSY2	3'b010
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

`define IB_CONST	143:80
`define IB_LN			78:76
`define IB_RD			75:71
`define IB_RS3	  70:66
`define IB_RS2		65:61
`define IB_RS1		60:56
`define IB_CMP		51
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
`define IB_SEI		15
`define IB_AQ			14
`define IB_RL			13
`define IB_JMP		12
`define IB_BR			11
`define IB_SYNC		10
`define IB_FSYNC	9
`define IB_RFW		8
`define IB_REX		4
`define IB_CHK		3
`define IB_UNIT		2:0

`define TLB			6'h3F
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
