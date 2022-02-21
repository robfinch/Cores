
package rf6809_pkg;

typedef logic [23:0] Address;
typedef logic [11:0] Data;

// Breakpoint Control Register
// One for each breakpoint address register
typedef struct packed
{
	logic hit;
	logic [2:0] pad;
	logic en;
	logic trace_en;
	logic [1:0] match_type;
	logic [3:0] amask;
} brkCtrl;

// Breakpoint match types
parameter BMT_IA = 2'd0;
parameter BMT_DS = 2'd1;
parameter BMT_LS = 2'd3;

parameter bitsPerByte =	$bits(Data);
parameter BPB = bitsPerByte;
parameter BPBM1 =	BPB-1;
parameter BPBX2M1 =	BPB*2-1;

// The following adds support for many 6309 instructions.
`define SUPPORT_6309	1
// Support BCD arithmetic mode and the decimal mode flag
`define SUPPORT_BCD		1
// Support divide operations
`define SUPPORT_DIVIDE 1

`define SUPPORT_DEBUG_REG	1

// The following allows asynchronous reads for icache updating.
// It increases the size of the core.
//`define SUPPORT_AREAD	1

// The following includes an instruction buffer when icache is
// not used.
//`define SUPPORT_IBUF	1

// The following enables support for the checkpoint interrupt.
//`define SUPPORT_CHECKPOINT

// The following enables OS components
`define SUPPORT_OS	1

`define SUPPORT_BxxDP	1

//`define EIGHTBIT	1
`define TWELVEBIT	2

`ifdef EIGHTBIT
`define LOBYTE	7:0
`define HIBYTE	15:8
`define DBLBYTE	15:0
`define TRPBYTE		23:0
`define QUADBYTE	31:0
`define BYTE1		7:0
`define BYTE2		15:8
`define BYTE3		23:16
`define BYTE4		31:24
`define BYTE5		39:32
`define BYTE6		47:40
`define QUINBYTE	39:0
`define HEXBYTE		47:0
`define SEVEN_BYTES	55:0
`define OCTABYTE	63:0
`define DBLBYTEP1	16:0
`define LOBYTEP1	8:0
`define HCBIT		3
`endif

`ifdef TWELVEBIT
`define LOBYTE	11:0
`define HIBYTE	23:12
`define DBLBYTE	23:0
`define TRPBYTE		35:0
`define QUADBYTE	47:0
`define BYTE1		11:0
`define BYTE2		23:12
`define BYTE3		35:24
`define BYTE4		47:36
`define BYTE5		59:48
`define BYTE6		71:60
`define QUINBYTE	59:0
`define HEXBYTE		71:0
`define SEVEN_BYTES	83:0
`define OCTABYTE	95:0
`define DBLBYTEP1	24:0
`define LOBYTEP1	12:0
`define HCBIT		3
`endif

`define TRUE		1'b1
`define FALSE		1'b0

`define RST_VECT	36'hFFFFFFFFC
`define NMI_VECT	36'hFFFFFFFF8
`define SWI_VECT	36'hFFFFFFFF4
`define IRQ_VECT	36'hFFFFFFFF0
`define FIRQ_VECT	36'hFFFFFFFEC
`define SWI2_VECT	36'hFFFFFFFE8
`define SWI3_VECT	36'hFFFFFFFE4
`define IOP_VECT	36'hFFFFFFFE0
`define EXV_VECT	36'hFFFFFFFDC
`define IPL6_VECT 36'hFFFFFFFD8
`define IPL5_VECT 36'hFFFFFFFD4
`define IPL4_VECT	36'hFFFFFFFD0
`define IPL3_VECT 36'hFFFFFFFCC
`define WRV_VECT 	36'hFFFFFFFC8
`define RDV_VECT	36'hFFFFFFFC4
`define DBG_VECT	36'hFFFFFFFC0
`define SYS_VECT	36'hFFFFFFFBC

`define TCB_BASE	36'hFFFFFFF30
`define RDYQO			36'hFFFFFFF28
`define RDYQI			36'b1111_1111_1111_1111_1111_1111_1111_0010_0xxx
`define MSCOUNT		36'hFFFFFFF18
`define MMU_OKEY	36'hFFFFFFF17
`define MMU_AKEY	36'hFFFFFFF16
`define CHKPOINT	36'hFFFFFFF15
`define CORENO		36'hFFFFFFF14

`define BRKCTRL3	36'hFFFFFFF13
`define BRKCTRL2	36'hFFFFFFF12
`define BRKCTRL1	36'hFFFFFFF11
`define BRKCTRL0	36'hFFFFFFF10
`define BRKAD3		36'hFFFFFFF0C
`define BRKAD2		36'hFFFFFFF08
`define BRKAD1		36'hFFFFFFF04
`define BRKAD0		36'hFFFFFFF00


`define NEG_DP		12'h000
`define OIM_DP		12'h001
`define AIM_DP		12'h002
`define COM_DP		12'h003
`define LSR_DP		12'h004
`define EIM_DP		12'h005
`define ROR_DP		12'h006
`define ASR_DP		12'h007
`define ASL_DP		12'h008
`define ROL_DP		12'h009
`define DEC_DP		12'h00A
`define TIM_DP		12'h00B
`define INC_DP		12'h00C
`define TST_DP		12'h00D
`define JMP_DP		12'h00E
`define CLR_DP		12'h00F

`define PG2			12'h010
`define PG3			12'h011
`define NOP			12'h012
`define SYNC		12'h013
`define SEXW		12'h014
`define FAR			12'h015
`define LBRA		12'h016
`define LBSR		12'h017
`define DAA			12'h019
`define ORCC		12'h01A
`define OUTER		12'h01B
`define ANDCC		12'h01C
`define SEX			12'h01D
`define EXG			12'h01E
`define TFR			12'h01F

`define BRA			12'h020
`define BRN			12'h021
`define BHI			12'h022
`define BLS			12'h023
`define BHS			12'h024
`define BLO			12'h025
`define BNE			12'h026
`define BEQ			12'h027
`define BVC			12'h028
`define BVS			12'h029
`define BPL			12'h02A
`define BMI			12'h02B
`define BGE			12'h02C
`define BLT			12'h02D
`define BGT			12'h02E
`define BLE			12'h02F

`define LEAX_NDX	12'h030
`define LEAY_NDX	12'h031
`define LEAS_NDX	12'h032
`define LEAU_NDX	12'h033
`define PSHS		12'h034
`define PULS		12'h035
`define PSHU		12'h036
`define PULU		12'h037
`define RTF			12'h038
`define RTS			12'h039
`define ABX			12'h03A
`define RTI			12'h03B
`define CWAI		12'h03C
`define MUL			12'h03D
`define SWI			12'h03F

`define NEGA		12'h040
`define COMA		12'h043
`define LSRA		12'h044
`define RORA		12'h046
`define ASRA		12'h047
`define ASLA		12'h048
`define ROLA		12'h049
`define DECA		12'h04A
`define INCA		12'h04C
`define TSTA		12'h04D
`define CLRA		12'h04F

`define NEGB		12'h050
`define COMB		12'h053
`define LSRB		12'h054
`define RORB		12'h056
`define ASRB		12'h057
`define ASLB		12'h058
`define ROLB		12'h059
`define DECB		12'h05A
`define INCB		12'h05C
`define TSTB		12'h05D
`define CLRB		12'h05F

`define NEG_NDX		12'h060
`define OIM_NDX		12'h061
`define AIM_NDX		12'h062
`define COM_NDX		12'h063
`define LSR_NDX		12'h064
`define EIM_NDX		12'h065
`define ROR_NDX		12'h066
`define ASR_NDX		12'h067
`define ASL_NDX		12'h068
`define ROL_NDX		12'h069
`define DEC_NDX		12'h06A
`define TIM_NDX		12'h06B
`define INC_NDX		12'h06C
`define TST_NDX		12'h06D
`define JMP_NDX		12'h06E
`define CLR_NDX		12'h06F

`define NEG_EXT		12'h070
`define OIM_EXT		12'h071
`define AIM_EXT		12'h072
`define COM_EXT		12'h073
`define LSR_EXT		12'h074
`define EIM_EXT		12'h075
`define ROR_EXT		12'h076
`define ASR_EXT		12'h077
`define ASL_EXT		12'h078
`define ROL_EXT		12'h079
`define DEC_EXT		12'h07A
`define TIM_EXT		12'h07B
`define INC_EXT		12'h07C
`define TST_EXT		12'h07D
`define JMP_EXT		12'h07E
`define CLR_EXT		12'h07F

`define SUBA_IMM	12'h080
`define CMPA_IMM	12'h081
`define SBCA_IMM	12'h082
`define SUBD_IMM	12'h083
`define ANDA_IMM	12'h084
`define BITA_IMM	12'h085
`define LDA_IMM		12'h086
`define EORA_IMM	12'h088
`define ADCA_IMM	12'h089
`define ORA_IMM		12'h08A
`define ADDA_IMM	12'h08B
`define CMPX_IMM	12'h08C
`define BSR				12'h08D
`define LDX_IMM		12'h08E
`define JMP_FAR		12'h08F

`define SUBA_DP		12'h090
`define CMPA_DP		12'h091
`define SBCA_DP		12'h092
`define SUBD_DP		12'h093
`define ANDA_DP		12'h094
`define BITA_DP		12'h095
`define LDA_DP		12'h096
`define STA_DP		12'h097
`define EORA_DP		12'h098
`define ADCA_DP		12'h099
`define ORA_DP		12'h09A
`define ADDA_DP		12'h09B
`define CMPX_DP		12'h09C
`define JSR_DP		12'h09D
`define LDX_DP		12'h09E
`define STX_DP		12'h09F

`define SUBA_NDX	12'h0A0
`define CMPA_NDX	12'h0A1
`define SBCA_NDX	12'h0A2
`define SUBD_NDX	12'h0A3
`define ANDA_NDX	12'h0A4
`define BITA_NDX	12'h0A5
`define LDA_NDX		12'h0A6
`define STA_NDX		12'h0A7
`define EORA_NDX	12'h0A8
`define ADCA_NDX	12'h0A9
`define ORA_NDX		12'h0AA
`define ADDA_NDX	12'h0AB
`define CMPX_NDX	12'h0AC
`define JSR_NDX		12'h0AD
`define LDX_NDX		12'h0AE
`define STX_NDX		12'h0AF

`define SUBA_EXT	12'h0B0
`define CMPA_EXT	12'h0B1
`define SBCA_EXT	12'h0B2
`define SUBD_EXT	12'h0B3
`define ANDA_EXT	12'h0B4
`define BITA_EXT	12'h0B5
`define LDA_EXT		12'h0B6
`define STA_EXT		12'h0B7
`define EORA_EXT	12'h0B8
`define ADCA_EXT	12'h0B9
`define ORA_EXT		12'h0BA
`define ADDA_EXT	12'h0BB
`define CMPX_EXT	12'h0BC
`define JSR_EXT		12'h0BD
`define LDX_EXT		12'h0BE
`define STX_EXT		12'h0BF

`define SUBB_IMM	12'h0C0
`define CMPB_IMM	12'h0C1
`define SBCB_IMM	12'h0C2
`define ADDD_IMM	12'h0C3
`define ANDB_IMM	12'h0C4
`define BITB_IMM	12'h0C5
`define LDB_IMM		12'h0C6
`define EORB_IMM	12'h0C8
`define ADCB_IMM	12'h0C9
`define ORB_IMM		12'h0CA
`define ADDB_IMM	12'h0CB
`define LDD_IMM		12'h0CC
`define LDQ_IMM		12'h0CD
`define LDU_IMM		12'h0CE
`define JSR_FAR		12'h0CF

`define SUBB_DP		12'h0D0
`define CMPB_DP		12'h0D1
`define SBCB_DP		12'h0D2
`define ADDD_DP		12'h0D3
`define ANDB_DP		12'h0D4
`define BITB_DP		12'h0D5
`define LDB_DP		12'h0D6
`define STB_DP		12'h0D7
`define EORB_DP		12'h0D8
`define ADCB_DP		12'h0D9
`define ORB_DP		12'h0DA
`define ADDB_DP		12'h0DB
`define LDD_DP		12'h0DC
`define STD_DP		12'h0DD
`define LDU_DP		12'h0DE
`define STU_DP		12'h0DF

`define SUBB_NDX	12'h0E0
`define CMPB_NDX	12'h0E1
`define SBCB_NDX	12'h0E2
`define ADDD_NDX	12'h0E3
`define ANDB_NDX	12'h0E4
`define BITB_NDX	12'h0E5
`define LDB_NDX		12'h0E6
`define STB_NDX		12'h0E7
`define EORB_NDX	12'h0E8
`define ADCB_NDX	12'h0E9
`define ORB_NDX		12'h0EA
`define ADDB_NDX	12'h0EB
`define LDD_NDX		12'h0EC
`define STD_NDX		12'h0ED
`define LDU_NDX		12'h0EE
`define STU_NDX		12'h0EF

`define SUBB_EXT	12'h0F0
`define CMPB_EXT	12'h0F1
`define SBCB_EXT	12'h0F2
`define ADDD_EXT	12'h0F3
`define ANDB_EXT	12'h0F4
`define BITB_EXT	12'h0F5
`define LDB_EXT		12'h0F6
`define STB_EXT		12'h0F7
`define EORB_EXT	12'h0F8
`define ADCB_EXT	12'h0F9
`define ORB_EXT		12'h0FA
`define ADDB_EXT	12'h0FB
`define LDD_EXT		12'h0FC
`define STD_EXT		12'h0FD
`define LDU_EXT		12'h0FE
`define STU_EXT		12'h0FF

`define TFS			12'h11E
`define TTS			12'h11F

`define LBRN		12'h121
`define LBHI		12'h122
`define LBLS		12'h123
`define LBHS		12'h124
`define LBLO		12'h125
`define LBNE		12'h126
`define LBEQ		12'h127
`define LBVC		12'h128
`define LBVS		12'h129
`define LBPL		12'h12A
`define LBMI		12'h12B
`define LBGE		12'h12C
`define LBLT		12'h12D
`define LBGT		12'h12E
`define LBLE		12'h12F

`define ADDR		12'h130
`define ADCR		12'h131
`define SUBR		12'h132
`define SBCR		12'h133
`define ANDR		12'h134
`define ORR			12'h135
`define EORR		12'h136
`define CMPR		12'h137
`define JTT			12'h13B
`define SWI2		12'h13F
`define NEGD		12'h140
`define COMD		12'h143
`define LSRD		12'h144
`define RORD		12'h146
`define ASRD		12'h147
`define ASLD		12'h148
`define ROLD		12'h149
`define DECD		12'h14A
`define INCD		12'h14C
`define TSTD		12'h14D
`define CLRD		12'h14F
`define COMW		12'h153
`define LSRW		12'h154
`define RORW		12'h156
`define ROLW		12'h159
`define DECW		12'h15A
`define INCW		12'h15C
`define TSTW		12'h15D
`define CLRW		12'h15F
`define SUBW_IMM	12'h180
`define CMPW_IMM	12'h181
`define SBCD_IMM	12'h182
`define CMPD_IMM	12'h183
`define ANDD_IMM	12'h184
`define BITD_IMM	12'h185
`define LDW_IMM		12'h186
`define EORD_IMM	12'h188
`define ADCD_IMM	12'h189
`define ORD_IMM		12'h18A
`define ADDW_IMM	12'h18B
`define CMPY_IMM	12'h18C
`define LDY_IMM		12'h18E
`define SUBW_DP		12'h190
`define CMPW_DP		12'h191
`define SBCD_DP		12'h192
`define CMPD_DP		12'h193
`define ANDD_DP		12'h194
`define BITD_DP		12'h195
`define LDW_DP		12'h196
`define STW_DP		12'h197
`define EORD_DP		12'h198
`define ADCD_DP		12'h199
`define ORD_DP		12'h19A
`define ADDW_DP		12'h19B
`define CMPY_DP		12'h19C
`define JTT_DP		12'h19D
`define LDY_DP		12'h19E
`define STY_DP		12'h19F
`define SUBW_NDX	12'h1A0
`define CMPW_NDX	12'h1A1
`define SBCD_NDX	12'h1A2
`define CMPD_NDX	12'h1A3
`define ANDD_NDX	12'h1A4
`define BITD_NDX	12'h1A5
`define LDW_NDX		12'h1A6
`define STW_NDX		12'h1A7
`define EORD_NDX	12'h1A8
`define ADCD_NDX	12'h1A9
`define ORD_NDX		12'h1AA
`define ADDW_NDX	12'h1AB
`define CMPY_NDX	12'h1AC
`define JTT_NDX		12'h1AD
`define LDY_NDX		12'h1AE
`define STY_NDX		12'h1AF
`define SUBW_EXT	12'h1B0
`define CMPW_EXT	12'h1B1
`define SBCD_EXT	12'h1B2
`define CMPD_EXT	12'h1B3
`define ANDD_EXT	12'h1B4
`define BITD_EXT	12'h1B5
`define LDW_EXT		12'h1B6
`define STW_EXT		12'h1B7
`define EORD_EXT	12'h1B8
`define ADCD_EXT	12'h1B9
`define	ORD_EXT		12'h1BA
`define ADDW_EXT	12'h1BB
`define CMPY_EXT	12'h1BC
`define JTT_EXT		12'h1BD
`define LDY_EXT		12'h1BE
`define STY_EXT		12'h1BF
`define LDS_IMM		12'h1CE
`define LDQ_DP		12'h1DC
`define STQ_DP		12'h1DD
`define LDS_DP		12'h1DE
`define STS_DP		12'h1DF
`define LDQ_NDX		12'h1EC
`define STQ_NDX		12'h1ED
`define LDS_NDX		12'h1EE
`define STS_NDX		12'h1EF
`define LDQ_EXT		12'h1FC
`define STQ_EXT		12'h1FD
`define LDS_EXT		12'h1FE
`define STS_EXT		12'h1FF
`define BAND_DP		12'h230
`define BIAND_DP	12'h231
`define BOR_DP		12'h232
`define BIOR_DP		12'h233
`define BEOR_DP		12'h234
`define BIEOR_DP	12'h235
`define BITMD		12'h23C
`define LDMD		12'h23D
`define SWI3		12'h23F
`define COME		12'h243
`define DECE		12'h24A
`define INCE		12'h24C
`define TSTE		12'h24D
`define CLRE		12'h24F
`define COMF		12'h253
`define DECF		12'h25A
`define INCF		12'h25C
`define TSTF		12'h25D
`define CLRF		12'h25F
`define SUBE_IMM	12'h280
`define CMPU_IMM	12'h283
`define LDE_IMM		12'h286
`define ADDE_IMM	12'h28B
`define DIVD_IMM	12'h28D
`define DIVQ_IMM	12'h28E
`define MULD_IMM	12'h28F
`define SUBE_DP		12'h290
`define LDE_DP		12'h296
`define ADDE_DP		12'h29B
`define DIVD_DP		12'h29D
`define DIVQ_DP		12'h29E
`define MULD_DP		12'h29F
`define SUBE_NDX	12'h2A0
`define LDE_NDX		12'h2A6
`define ADDE_NDX	12'h2AB
`define DIVD_NDX	12'h2AD
`define DIVQ_NDX	12'h2AE
`define MULD_NDX	12'h2AF
`define SUBE_EXT	12'h2B0
`define LDE_EXT		12'h2B6
`define ADDE_EXT	12'h2BB
`define DIVD_EXT	12'h2BD
`define DIVQ_EXT	12'h2BE
`define MULD_EXT	12'h2BF
`define SUBF_IMM	12'h2C0
`define LDF_IMM		12'h2C6
`define ADDF_IMM	12'h2CB
`define SUBF_DP		12'h2D0
`define LDF_DP		12'h2D6
`define ADDF_DP		12'h2DB
`define SUBF_NDX	12'h2E0
`define LDF_NDX		12'h2E6
`define ADDF_NDX	12'h2EB
`define SUBF_EXT	12'h2F0
`define LDF_EXT		12'h2F6
`define ADDF_EXT	12'h2FB
`define CMPE_IMM	12'h281
`define CMPE_DP		12'h291
`define STE_DP		12'h297
`define STE_NDX		12'h2A7
`define STE_EXT		12'h2B7
`define STF_DP		12'h2D7
`define STF_NDX		12'h2E7
`define STF_EXT		12'h2F7
`define CMPE_NDX	12'h2A1
`define CMPE_EXT	12'h2B1
`define CMPF_IMM	12'h2C1
`define CMPF_DP		12'h2D1
`define CMPF_NDX	12'h2E1
`define CMPF_EXT	12'h2F1
`define CMPS_IMM	12'h28C
`define CMPU_DP		12'h293
`define CMPS_DP		12'h29C
`define CMPU_NDX	12'h2A3
`define CMPS_NDX	12'h2AC
`define CMPU_EXT	12'h2B3
`define CMPS_EXT	12'h2BC

`define DFADD			12'h331
`define DFSUB			12'h332
`define DFCMP			12'h333
`define DFMUL			12'h334
`define DFDIV			12'h335
`define SYS				12'h33F

`define NEGG			12'h340
`define TSTG			12'h34D
`define CLRG			12'h34F

`define CMPG_DP		12'h393
`define LDG_DP		12'h396
`define DIVG_DP		12'h39D
`define MULG_DP		12'h39F
`define CMPG_NDX	12'h3A3
`define LDG_NDX		12'h3A6
`define DIVG_NDX	12'h3AD
`define MULG_NDX	12'h3AF
`define CMPG_EXT	12'h3B3
`define LDG_EXT		12'h3B6
`define DIVG_EXT	12'h3BD
`define MULG_EXT	12'h3BF

`define ADDG_DP		12'h3D3
`define SUBG_DP		12'h3D4
`define STG_DP		12'h3DD
`define ADDG_NDX	12'h3E3
`define SUBG_NDX	12'h3E4
`define STG_NDX		12'h3ED
`define ADDG_EXT	12'h3F3
`define SUBG_EXT	12'h3F4
`define STG_EXT		12'h3FD

// Unused opcode
`define INT			12'h33E

`define LW_CCR		6'd0
`define LW_ACCA		6'd1
`define LW_ACCB		6'd2
`define LW_DPRH		6'd3
`define LW_XH		6'd4
`define LW_XL		6'd5
`define LW_YH		6'd6
`define LW_YL		6'd7
`define LW_USPH		6'd8
`define LW_USPL		6'd9
`define LW_SSPH		6'd10
`define LW_SSPL		6'd11
`define LW_PCH		6'd12
`define LW_PCL		6'd13
`define LW_BL		6'd14
`define LW_BH		6'd15
`define LW_IAL		6'd16
`define LW_IAH		6'd17
`define LW_PC3124	6'd18
`define LW_PC2316	6'd19
`define LW_IA3124	6'd20
`define LW_IA2316	6'd21
`define LW_B3124	6'd22
`define LW_B2316	6'd23
`define LW_X3124	6'd24
`define LW_X2316	6'd25
`define LW_Y3124	6'd26
`define LW_Y2316	6'd27
`define LW_USP3124	6'd28
`define LW_USP2316	6'd29
`define LW_SSP3124	6'd30
`define LW_SSP2316	6'd31
`define LW_ACCE			6'd32
`define LW_ACCF			6'd33
`define LW_DPRL			6'd34
`define LW_PCB3			6'd35
`define LW_PCB2			6'd36
`define LW_B0			6'd40
`define LW_B1			6'd41
`define LW_B2			6'd42
`define LW_B3			6'd43
`define LW_B4			6'd44
`define LW_B5			6'd45
`define LW_B6			6'd46
`define LW_B7			6'd47
`define LW_B8			6'd48
`define LW_B9			6'd49
`define LW_B10			6'd50
`define LW_NOTHING	6'd63

`define SW_ACCDH	6'd0
`define SW_ACCDL	6'd1
`define SW_ACCA		6'd2
`define SW_ACCB		6'd3
`define SW_DPRH		6'd4
`define SW_XL		6'd5
`define SW_XH		6'd6
`define SW_YL		6'd7
`define SW_YH		6'd8
`define SW_USPL		6'd9
`define SW_USPH		6'd10
`define SW_SSPL		6'd11
`define SW_SSPH		6'd12
`define SW_PCH		6'd13
`define SW_PCL		6'd14
`define SW_CCR		6'd15
`define SW_RES8		6'd16
`define SW_RES16L	6'd17
`define SW_RES16H	6'd18
`define SW_DEF8		6'd19
`define SW_PC3124	6'd20
`define SW_PC2316	6'd21
`define SW_ACCQ3124	6'd22
`define SW_ACCQ2316	6'd23
`define SW_ACCQ158	6'd24
`define SW_ACCQ70	6'd25
`define SW_X3124	6'd26
`define SW_X2316	6'd27
`define SW_Y3124	6'd28
`define SW_Y2316	6'd29
`define SW_USP3124	6'd30
`define SW_USP2316	6'd31
`define SW_SSP3124	6'd32
`define SW_SSP2316	6'd33
`define SW_ACCA3124 6'd34
`define SW_ACCA2316 6'd35
`define SW_ACCA158 	6'd36
`define SW_ACCA70	6'd37
`define SW_ACCB3124 6'd38
`define SW_ACCB2316 6'd39
`define SW_ACCB158 	6'd40
`define SW_ACCB70	6'd41
`define SW_ACCE		6'd42
`define SW_ACCF		6'd43
`define SW_ACCWH	6'd44
`define SW_ACCWL	6'd45
`define SW_DPRL		6'd46
`define SW_G0			6'd50
`define SW_G1			6'd51
`define SW_G2			6'd52
`define SW_G3			6'd53
`define SW_G4			6'd54
`define SW_G5			6'd55
`define SW_G6			6'd56
`define SW_G7			6'd57
`define SW_G8			6'd58
`define SW_G9			6'd59
`define SW_G10		6'd60
`define SW_NOTHING	6'd63

endpackage
