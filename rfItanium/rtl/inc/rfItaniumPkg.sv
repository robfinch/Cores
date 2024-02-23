package rfItaniumPkg;

typedef enum logic [3:0] {
	INT_MISC = 4'd0,
	INT_DEPOSIT = 4'd4,
	INT_SHIFT = 4'd5,
	INT_MM_MPY = 4'd7,
	INT_MM_ALU = 4'd8,
	INT_ADD22 = 4'd9,
	INT_CMPC = 4'dC,
	INT_CMPD = 4'dD,
	INT_CMPE = 4'dE
} e_int;

typedef enum logic [3:0] {
	MEM_MGNT0 = 4'd0,
	MEM_MGNT1 = 4'd1,
	MEM_INT_LSREG = 4'd4,
	MEM_INT_LSIMM = 4'd5,
	MEM_FP_LSREG = 4'd6,
	MEM_FP_LSIMM = 4'd7,
	MEM_MM_ALU = 4'd8,
	MEM_ADD22 = 4'd9,
	MEM_CMPC = 4'dC,
	MEM_CMPD = 4'dD,
	MEM_CMPE = 4'dE
} e_mem;

typedef enum logic [3:0] {
	FP_MISC0 = 4'd0,
	FP_MISC1 = 4'd1,
	FP_CMP = 4'd4,
	FP_CLASS = 4'd5,
	FP_FMA8 = 4'd8,
	FP_FMA9 = 4'd9,
	FP_FMSA = 4'd10,
	FP_FMSB = 4'd11,
	FP_FNMAC = 4'd12,
	FP_FNMAD = 4'd13,
	FP_SELECT = 4'd14
} e_fp;

typedef enum logic [3:0] {
	BR_MISC = 4'd0,
	BR_ICALL = 4'd1,
	BR_NOP = 4'd2,
	BR_IPRELBR = 4'd4,
	BR_IPRELCALL = 4'd5
} e_br;

typedef enum logic [3:0] {
	LX_MISC = 4'd0,
	LX_MOVL = 4'd6
} e_lx;

typedef enum logic [4:0] {
	TM_MII = 5'h00,
	TM_MIIG = 5'h01,
	TM_MIGI = 5'd02,
	TM_MIGIG = 5'h03,
	TM_ML = 5'h04,
	TM_MLG = 5'h05,
	TM_MMI = 5'h08,
	TM_MMIG = 5'h09,
	TM_MGMI = 5'h0A,
	TM_MGMIG = 5'h0B,
	TM_MFI = 5'h0C,
	TM_MFIG = 5'h0D,
	TM_MMF = 5'h0E,
	TM_MMFG = 5'h0F,
	TM_MIB = 5'h10,
	TM_MIBG 5'h11,
	TM_MBB = 5'h12,
	TM_MBBG = 5'h13,
	TM_BBB = 5'h16,
	TM_BBBG = 5'h17,
	TM_MMB = 5'h18,
	TM_MMBG = 5'h19,
	TM_MFB = 5'h1C,
	TM_MFBG = 5'h1D
} e_template;

typedef struct packed
{
	logic [40:0] payload;
} any_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv;
	logic [1:0] x2a;
	logic ve;
	logic [3:0] x4;
	logic [1:0] x2b;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} A1_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv;
	logic [1:0] x2a;
	logic ve;
	logic [3:0] x4;
	logic [1:0] ct2d;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} A2_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [1:0] x2a;
	logic ve;
	logic [3:0] x4;
	logic [1:0] ct2d;
	logic [6:0] r3;
	logic [6:0] imm7b;
	logic [6:0] r1;
	logic [5:0] qp;
} A3_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [1:0] x2a;
	logic ve;
	logic [5:0] imm6d;
	logic [6:0] r3;
	logic [6:0] imm7b;
	logic [6:0] r1;
	logic [5:0] qp;
} A4_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [8:0] imm9d;
	logic [4:0] imm5c;
	logic [1:0] r3;
	logic [6:0] imm7b;
	logic [6:0] r1;
	logic [5:0] qp;
} A5_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic tb;
	logic [1:0] x2;
	logic ta;
	logic [5:0] p2;
	logic [6:0] r3;
	logic [6:0] r2;
	logic c;
	logic [5:0] p1;
	logic [5:0] qp;
} A6_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic tb;
	logic [1:0] x2;
	logic ta;
	logic [5:0] p2;
	logic [6:0] r3;
	logic [6:0] zero;
	logic c;
	logic [5:0] p1;
	logic [5:0] qp;
} A7_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [1:0] x2;
	logic ta;
	logic [5:0] p2;
	logic [6:0] r3;
	logic [6:0] imm7b;
	logic c;
	logic [5:0] p1;
	logic [5:0] qp;
} A8_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic za;
	logic [1:0] x2a;
	logic zb;
	logic [3:0] x4;
	logic [1:0] x2b;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} A9_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic za;
	logic [1:0] x2a;
	logic zb;
	logic [3:0] x4;
	logic [1:0] ct2d;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} A10_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic za;
	logic [1:0] x2a;
	logic zb;
	logic ve;
	logic [1:0] ct2d;
	logic [1:0] x2b;
	logic resv;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} I1_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic za;
	logic [1:0] x2a;
	logic zb;
	logic ve;
	logic [1:0] x2c;
	logic [1:0] x2b;
	logic resv;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} I2_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic za;
	logic [1:0] x2a;
	logic zb;
	logic ve;
	logic [1:0] x2c;
	logic [1:0] x2b;
	logic [3:0] resv;
	logic [3:0] mbt4c;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} I3_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic za;
	logic [1:0] x2a;
	logic zb;
	logic ve;
	logic [1:0] x2c;
	logic [1:0] x2b;
	logic [7:0] mht8c;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} I4_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic za;
	logic [1:0] x2a;
	logic zb;
	logic ve;
	logic [1:0] x2c;
	logic [1:0] x2b;
	logic resv;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} I5_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic za;
	logic [1:0] x2a;
	logic zb;
	logic ve;
	logic [1:0] x2c;
	logic [1:0] x2b;
	logic resv;
	logic [6:0] r3;
	logic resv2;
	logic [4:0] count5b;
	logic resv1;
	logic [6:0] r1;
	logic [5:0] qp;
} I6_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic za;
	logic [1:0] x2a;
	logic zb;
	logic ve;
	logic [1:0] x2c;
	logic [1:0] x2b;
	logic resv;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} I7_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic za;
	logic [1:0] x2a;
	logic zb;
	logic ve;
	logic [1:0] x2c;
	logic [1:0] x2b;
	logic [2:0] resv;
	logic [4:0] count5c;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} I8_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic za;
	logic [1:0] x2a;
	logic zb;
	logic ve;
	logic [1:0] x2c;
	logic [1:0] x2b;
	logic resv;
	logic [6:0] r3;
	logic [6:0] zero;
	logic [6:0] r1;
	logic [5:0] qp;
} I9_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv;
	logic [1:0] x2;
	logic x;
	logic [5:0] count6d;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} I10_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv;
	logic [1:0] x2;
	logic x;
	logic [5:0] len6d;
	logic [6:0] r3;
	logic [5:0] pos6b;
	logic y;
	logic [6:0] r1;
	logic [5:0] qp;
} I11_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv;
	logic [1:0] x2;
	logic x;
	logic [5:0] len6d;
	logic y;
	logic [5:0] pos6c;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} I12_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [1:0] x2;
	logic x;
	logic [5:0] len6d;
	logic y;
	logic [5:0] pos6c;
	logic [6:0] imm7b;
	logic [6:0] r1;
	logic [5:0] qp;
} I13_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [1:0] x2;
	logic x;
	logic [5:0] len6d;
	logic [6:0] r3;
	logic [5:0] cpos6b;
	logic resv;
	logic [6:0] r1;
	logic [5:0] qp;
} I14_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic [5:0] cpos6d;
	logic [3:0] len4d;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} I15_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic tb;
	logic [1:0] x2;
	logic ta;
	logic [5:0] p2;
	logic [6:0] r3;
	logic [5:0] pos6b;
	logic y;
	logic c;
	logic [5:0] p1;
	logic [5:0] qp;
} I16_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic tb;
	logic [1:0] x2;
	logic ta;
	logic [5:0] p2;
	logic [6:0] r3;
	logic [5:0] resv;
	logic y;
	logic c;
	logic [5:0] p1;
	logic [5:0] qp;
} I17_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic i;
	logic [2:0] x3;
	logic [5:0] x6;
	logic resv;
	logic [19:0] imm20a;
	logic [5:0] qp;
} I19_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [2:0] x3;
	logic [12:0] imm13c;
	logic [6:0] r2;
	logic [6:0] imm7a;
	logic [5:0] qp;
} I20_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv3;
	logic [2:0] x3;
	logic [9:0] resv2;
	logic x;
	logic [1:0] resv;
	logic [6:0] r2;
	logic [3:0] resv;
	logic [2:0] b1;
	logic [5:0] qp;
} I21_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [5:0] x6;
	logic [10:0] resv;
	logic [2:0] b2;
	logic [6:0] r1;
	logic [5:0] qp;
} I22_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [2:0] x3;
	logic resv2;
	logic [7:0] mask8c;
	logic [3:0] resv;
	logic [6:0] r2;
	logic [6:0] mask7a;
	logic [5:0] qp;
} I23_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [2:0] x3;
	logic [26:0] imm27a;
	logic [5:0] qp;
} I24_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [5:0] x6;
	logic [13:0] resv;
	logic [6:0] r1;
	logic [5:0] qp;
} I25_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [5:0] x6;
	logic [6:0] ar3;
	logic [6:0] r2;
	logic [6:0] resv;
	logic [5:0] qp;
} I26_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [2:0] x3;
	logic [5:0] x6;
	logic [6:0] ar3;
	logic [6:0] imm7b;
	logic [6:0] resv;
	logic [5:0] qp;
} I27_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [5:0] x6;
	logic [6:0] ar3;
	logic [6:0] resv;
	logic [6:0] r1;
	logic [5:0] qp;
} I28_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [5:0] x6;
	logic [6:0] r3;
	logic [6:0] resv;
	logic [6:0] r1;
	logic [5:0] qp;
} I29_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] hint;
	logic x;
	logic [6:0] r3;
	logic [6:0] resv;
	logic [6:0] r1;
	logic [5:0] qp;
} M1_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] hint;
	logic x;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} M2_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [5:0] x6;
	logic [1:0] hint;
	logic i;
	logic [6:0] r3;
	logic [6:0] imm7b;
	logic [6:0] r1;
	logic [5:0] qp;
} M3_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] hint;
	logic x;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] resv;
	logic [5:0] qp;
} M4_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [5:0] x6;
	logic [1:0] hint;
	logic i;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] imm7a;
	logic [5:0] qp;
} M5_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] hint;
	logic x;
	logic [6:0] r3;
	logic [6:0] resv;
	logic [6:0] f1;
	logic [5:0] qp;
} M6_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] hint;
	logic x;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] f1;
	logic [5:0] qp;
} M7_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [5:0] x6;
	logic [1:0] hint;
	logic i;
	logic [6:0] r3;
	logic [6:0] imm7b;
	logic [6:0] f1;
	logic [5:0] qp;
} M8_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] hint;
	logic x;
	logic [6:0] r3;
	logic [6:0] f2;
	logic [6:0] resv;
	logic [5:0] qp;
} M9_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [5:0] x6;
	logic [1:0] hint;
	logic i;
	logic [6:0] r3;
	logic [6:0] f2;
	logic [6:0] imm7a;
	logic [5:0] qp;
} M10_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] hint;
	logic x;
	logic [6:0] r3;
	logic [6:0] f2;
	logic [6:0] f1;
	logic [5:0] qp;
} M11_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] hint;
	logic x;
	logic [6:0] r3;
	logic [6:0] f2;
	logic [6:0] f1;
	logic [5:0] qp;
} M12_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] hint;
	logic x;
	logic [6:0] r3;
	logic [13:0] resv;
	logic [5:0] qp;
} M13_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] hint;
	logic x;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] resv;
	logic [5:0] qp;
} M14_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [5:0] x6;
	logic [1:0] hint;
	logic i;
	logic [6:0] r3;
	logic [6:0] imm7b;
	logic [6:0] resv;
	logic [5:0] qp;
} M15_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] hint;
	logic x;
	logic [6:0] r3;
	logic [6:0] r2;
	logic [6:0] r1;
	logic [5:0] qp;
} M16_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] hint;
	logic x;
	logic [6:0] r3;
	logic [3:0] resv;
	logic s;
	logic [1:0] i2b;
	logic [6:0] r1;
	logic [5:0] qp;
} M17_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] resv2;
	logic x;
	logic [6:0] resv;
	logic [6:0] r2;
	logic [6:0] f1;
	logic [5:0] qp;
} M18_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic m;
	logic [5:0] x6;
	logic [1:0] resv2;
	logic x;
	logic [6:0] resv;
	logic [6:0] f2;
	logic [6:0] r1;
	logic [5:0] qp;
} M19_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [2:0] x3;
	logic [12:0] imm13c;
	logic [6:0] r2;
	logic [6:0] imm7a;
	logic [5:0] qp;
} M20_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [2:0] x3;
	logic [12:0] imm13c;
	logic [6:0] f2;
	logic [6:0] imm7a;
	logic [5:0] qp;
} M21_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [2:0] x3;
	logic [19:0] imm20b;
	logic [6:0] r1;
	logic [5:0] qp;
} M22_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [2:0] x3;
	logic [19:0] imm20b;
	logic [6:0] f1;
	logic [5:0] qp;
} M23_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [1:0] x2;
	logic [3:0] x4;
	logic [20:0] resv;
	logic [5:0] qp;
} M24_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [1:0] x2;
	logic [3:0] x4;
	logic [20:0] resv;
	logic [5:0] qp;		// zero
} M25_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [1:0] x2;
	logic [3:0] x4;
	logic [13:0] resv;
	logic [6:0] r1;
	logic [5:0] qp;
} M26_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [1:0] x2;
	logic [3:0] x4;
	logic [13:0] resv;
	logic [6:0] f1;
	logic [5:0] qp;
} M27_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [5:0] x6;
	logic [6:0] r3;
	logic [13:0] resv;
	logic [5:0] qp;
} M28_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [5:0] x6;
	logic [6:0] ar3;
	logic [6:0] r2;
	logic [6:0] resv;
	logic [5:0] qp;
} M29_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [2:0] x3;
	logic [1:0] x2;
	logic [3:0] x4;
	logic [6:0] ar3;
	logic [6:0] imm7b;
	logic [6:0] resv;
	logic [5:0] qp;
} M30_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [2:0] x3;
	logic [5:0] x6;
	logic [6:0] ar3;
	logic [6:0] resv;
	logic [6:0] r1;
	logic [5:0] qp;
} M31_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [1:0] resv;
	logic [3:0] sor;
	logic [6:0] sol;
	logic [6:0] sof;
	logic [6:0] r1;
	logic [5:0] qp;
} M34_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv3;
	logic [2:0] x3;
	logic [5:0] x6;
	logic [6:0] resv2;
	logic [6:0] r2;
	logic [6:0] resv;
	logic [5:0] qp;
} M35_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv3;
	logic [2:0] x3;
	logic [5:0] x6;
	logic [6:0] resv2;
	logic [6:0] resv;
	logic [6:0] r1;
	logic [5:0] qp;
} M36_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic i;
	logic [2:0] x3;
	logic [1:0] x2;
	logic [3:0] x4;
	logic resv;
	logic [19:0] imm20a;
	logic [5:0] qp;
} M37_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [2:0] x3;
	logic [5:0] x6;
	logic [6:0] r3;
	logic [6:0] resv;
	logic [6:0] r1;
	logic [5:0] qp;
} M43_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic i;
	logic [2:0] x3;
	logic [1:0] i2d;
	logic [3:0] x4;
	logic [20:0] imm21a;
	logic [5:0] qp;
} M44_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic d;
	logic [1:0] wh;
	logic [19:0] imm20b;
	logic p;
	logic [2:0] resv;
	logic [2:0] btype;
	logic [5:0] qp;
} B1_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic d;
	logic [1:0] wh;
	logic [19:0] imm20b;
	logic p;
	logic [2:0] resv;
	logic [2:0] btype;
	logic [5:0] qp;		// zero
} B2_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic d;
	logic [1:0] wh;
	logic [19:0] imm20b;
	logic p;
	logic [2:0] resv;
	logic [2:0] b1;
	logic [5:0] qp;
} B3_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv3;
	logic d;
	logic [1:0] wh;
	logic [5:0] x6;
	logic [10:0] resv2
	logic [2:0] b2;
	logic p;
	logic [2:0] resv;
	logic [2:0] btype;
	logic [5:0] qp;
} B4_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv3;
	logic d;
	logic [2:0] wh;
	logic [15:0] resv2
	logic [2:0] b2;
	logic p;
	logic [2:0] resv;
	logic [2:0] b1;
	logic [5:0] qp;
} B5_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic [3:0] resv2;
	logic [5:0] x6;
	logic [20:0] resv;
	logic [5:0] qp;		// zero
} B8_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic i;
	logic [2:0] resv2;
	logic [5:0] x6;
	logic resv;
	logic [19:0] imm20a;
	logic [5:0] qp;
} B9_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic x;
	logic [1:0] sf;
	logic [6:0] f4;
	logic [6:0] f3;
	logic [6:0] f2;
	logic [6:0] f1;
	logic [5:0] qp;
} F1_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic x;
	logic [1:0] x2;
	logic [6:0] f4;
	logic [6:0] f3;
	logic [6:0] f2;
	logic [6:0] f1;
	logic [5:0] qp;
} F2_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic x;
	logic [1:0] resv;
	logic [6:0] f4;
	logic [6:0] f3;
	logic [6:0] f2;
	logic [6:0] f1;
	logic [5:0] qp;
} F3_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic rb;
	logic [1:0] sf;
	logic ra;
	logic [5:0] p2;
	logic [6:0] f3;
	logic [6:0] f2;
	logic ta;
	logic [5:0] p1;
	logic [5:0] qp;
} F4_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic [1:0] resv;
	logic [1:0] fc2;
	logic [5:0] p2;
	logic [6:0] fclass7c;
	logic [6:0] f2;
	logic ta;
	logic [5:0] p1;
	logic [5:0] qp;
} F5_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic q;
	logic [1:0] sf;
	logic x;
	logic [5:0] p2;
	logic [6:0] f3;
	logic [6:0] f2;
	logic [6:0] f1;
	logic [5:0] qp;
} F6_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic q;
	logic [1:0] sf;
	logic x;
	logic [5:0] p2;
	logic [6:0] f3;
	logic [6:0] resv;
	logic [6:0] f1;
	logic [5:0] qp;
} F7_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv;
	logic [1:0] sf;
	logic x;
	logic [5:0] x6;
	logic [6:0] f3;
	logic [6:0] f2;
	logic [6:0] f1;
	logic [5:0] qp;
} F8_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic [2:0] resv;
	logic x;
	logic [5:0] x6;
	logic [6:0] f3;
	logic [6:0] f2;
	logic [6:0] f1;
	logic [5:0] qp;
} F9_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv;
	logic [1:0] sf;
	logic x;
	logic [5:0] x6;
	logic [6:0] resv;
	logic [6:0] f2;
	logic [6:0] f1;
	logic [5:0] qp;
} F10_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic [2:0] resv;
	logic x;
	logic [5:0] x6;
	logic [6:0] resv;
	logic [6:0] f2;
	logic [6:0] f1;
	logic [5:0] qp;
} F11_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [1:0] sf;
	logic x;
	logic [5:0] x6;
	logic [6:0] omask7c;
	logic [6:0] amask7b;
	logic [6:0] resv;
	logic [5:0] qp;
} F12_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic resv2;
	logic [1:0] sf;
	logic x;
	logic [5:0] x6;
	logic [20:0] resv;
	logic [5:0] qp;
} F13_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic s;
	logic [1:0] sf;
	logic x;
	logic [5:0] x6;
	logic resv;
	logic [19:0] imm20a;
	logic [5:0] qp;
} F14_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic i;
	logic [1:0] resv2;
	logic x;
	logic [5:0] x6;
	logic resv;
	logic [19:0] imm20a;
	logic [5:0] qp;
} F15_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic i;
	logic [1:0] x3;
	logic [5:0] x6;
	logic resv;
	logic [19:0] imm20a;
	logic [5:0] qp;
} X1_inst_t;

typedef struct packed
{
	logic [3:0] opc;
	logic i;
	logic [8:0] imm9d;
	logic [4:0] imm5c;
	logic ic;
	logic vc;
	logic [6:0] imm7b;
	logic [6:0] r1;
	logic [5:0] qp;
} X2_inst_t;

typedef union packed
{
	any_inst_t any;
} instruction_t;

typedef struct packed
{
	e_template tmpl;
	instruction_t ins2;
	instruction_t ins1;
	instruction_t ins0;
} bundle_t;

endpackage
