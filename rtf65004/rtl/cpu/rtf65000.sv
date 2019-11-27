`include "rtf65000-config.sv"
`include "rtf65000-defines.sv"

module rtf65000();


reg [7:0] ac;
reg [7:0] xr;
reg [7:0] yr;
reg [7:0] sp;
reg [15:0] pc;
reg [15:0] tmp;
reg [7:0] sr;

reg [15:0] rfoa [0:QSLOTS-1];
reg [15:0] rfob [0:QSLOTS-1];

reg q1, q2;	// number of macro instructions queued

wire [95:0] ic1_out;
wire [63:0] ic2_out;
wire [31:0] ic3_out;

wire [3:0] len1, len2, len3;
reg [23:0] insnx [0:1];

reg [15:0] uoq_pc [0:UOQ_ENTRIES-1];
reg [15:0] uoq_uop [0:UOQ_ENTRIES-1];
reg [15:0] uoq_const [0:UOQ_ENTRIES-1];
reg [1:0] uoq_fl;		// first or last micro-op
reg [1:0] uoq_flagsupd [0:UOQ_ENTRIES-1];

reg [UOQ_ENTRIES-1:0] uqo_jc;
reg [UOQ_ENTRIES-1:0] uqo_br;
reg [UOQ_ENTRIES-1:0] uqo_ret;

reg [15:0] iq_pc [0:QENTRIES-1];
reg [4:0] iq_instr [0:QENTRIES-1];
reg [2:0] iq_tgt [0:QENTRIES-1];

// Re-order buffer
reg [RENTRIES-1:0] rob_v;
reg [`QBITS] rob_id [0:RENTRIES-1];	// instruction queue id that owns this entry
reg [1:0] rob_state [0:RENTRIES-1];
reg [`ABITS] rob_pc	[0:RENTRIES-1];	// program counter for this instruction
reg [4:0] rob_instr[0:RENTRIES-1];	// instruction opcode
reg [7:0] rob_exc [0:RENTRIES-1];
reg [15:0] rob_ma [0:RENTRIES-1];
reg [15:0] rob_res [0:RENTRIES-1];
reg [7:0] rob_cr [0:RENTRIES-1];
reg [RBIT:0] rob_tgt [0:RENTRIES-1];
reg [7:0] rob_crres [0:RENTRIES-1];

reg [69:0] uopl [0:255];
initial begin
	// Initialize everything to NOPs
	for (n = 0; n < 256; n = n + 1)
		uopl[n] = {2'd0,68'h0};
uopl[`BRK] 			= {2'd3,`UOF_NONE,2'd3,`UO_ADDB,`UO_M3,`UO_SP,2'd0,`UO_STB,`UO_M1,`UO_SR,2'd0,`UO_STW,`UO_M2,`UO_PC,2'd0,`UO_LDW,`UO_M2,`UO_PC,2'd0};
uopl[`LDA_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_LDIB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`LDA_ZP]		= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`LDA_ZPX]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R8,`UO_ACC,`UO_XR,48'h0};
uopl[`LDA_IX]		= {2'd1,`UOF_NZ,2'd1,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0000};
uopl[`LDA_IY]		= {2'd2,`UOF_NZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`LDA_ABS]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R16,`UO_ACC,`UO_ZR,48'h0};
uopl[`LDA_ABSX]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R16,`UO_ACC,`UO_XR,48'h0};
uopl[`LDA_ABSY]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R16,`UO_ACC,`UO_YR,48'h0};
uopl[`STA_ZP]	  = {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`STA_ZPX]  = {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R8,`UO_ACC,`UO_XR,48'h0};
uopl[`STA_IX]		= {2'd1,`UOF_NONE,2'd0,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_STB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0000};
uopl[`STA_IY]		= {2'd2,`UOF_NONE,2'd0,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_STB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`STA_ABS]	= {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R16,`UO_ACC,`UO_ZR,48'h0};
uopl[`STA_ABSX]	= {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R16,`UO_ACC,`UO_XR,48'h0};
uopl[`STA_ABSY]	= {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R16,`UO_ACC,`UO_YR,48'h0};
uopl[`LDX_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_LDIB,`UO_R8,`UO_XR,`UO_ZR,48'h0};
uopl[`LDY_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_LDIB,`UO_R8,`UO_YR,`UO_ZR,48'h0};
uopl[`ADC_IMM]	= {2'd0,`UOF_CVNZ,2'd0,`UO_ADCIB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`ADC_ZP]		= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ADC_ZPX]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ADC_IX]		= {2'd2,`UOF_CVNZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`ADC_IY]		= {2'd3,`UOF_CVNZ,2'd3,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP};
uopl[`ADC_ABS]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ADC_ABSX]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ADC_ABSY]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_YR,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`SBC_IMM]	= {2'd0,`UOF_CVNZ,2'd0,`UO_SBCIB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`SBC_ZP]		= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`SBC_ZPX]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`SBC_IX]		= {2'd2,`UOF_CVNZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`SBC_IY]		= {2'd3,`UOF_CVNZ,2'd3,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP};
uopl[`SBC_ABS]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`SBC_ABSX]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`SBC_ABSY]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_YR,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`CMP_IMM]	= {2'd0,`UOF_CNZ,2'd0,`UO_CMPIB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`CMP_ZP]		= {2'd1,`UOF_CNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_CMPB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`CMP_ZPX]	= {2'd1,`UOF_CNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_CMPB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`CMP_IX]		= {2'd2,`UOF_CNZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_CMPB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`CMP_IY]		= {2'd3,`UOF_CNZ,2'd3,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_CMPB,`UO_ZERO,`UO_ACC,`UO_TMP};
uopl[`CMP_ABS]	= {2'd1,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_CMP,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`CMP_ABSX]	= {2'd1,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_CMP,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`CMP_ABSY]	= {2'd1,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_YR,`UO_CMP,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`AND_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_ANDIB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`AND_ZP]		= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_ANDB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`AND_ZPX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_ANDB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`AND_IX]		= {2'd2,`UOF_NZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_ANDB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`AND_IY]		= {2'd3,`UOF_NZ,2'd3,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_ANDB,`UO_ZERO,`UO_ACC,`UO_TMP};
uopl[`AND_ABS]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_AND,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`AND_ABSX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_AND,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`AND_ABSY]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_YR,`UO_AND,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ORA_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_ORIB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`ORA_ZP]		= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ORA_ZPX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ORA_IX]		= {2'd2,`UOF_NZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`ORA_IY]		= {2'd3,`UOF_NZ,2'd3,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP};
uopl[`ORA_ABS]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ORA_ABSX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ORA_ABSY]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_YR,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`EOR_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_EORIB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`EOR_ZP]		= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`EOR_ZPX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`EOR_IX]		= {2'd2,`UOF_NZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`EOR_IY]		= {2'd3,`UOF_NZ,2'd3,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP};
uopl[`EOR_ABS]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`EOR_ABSX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`EOR_ABSY]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_YR,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`LDX_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_LDIB,`UO_R8,`UO_XR,`UO_ZR,48'h0};
uopl[`LDX_ZP]		= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R8,`UO_XR,`UO_ZR,48'h0};
uopl[`LDX_ZPY]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R8,`UO_XR,`UO_YR,48'h0};
uopl[`LDX_ABS]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R16,`UO_XR,`UO_ZR,48'h0};
uopl[`LDX_ABSY]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R16,`UO_XR,`UO_YR,48'h0};
uopl[`CPX_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_CMPIB,`UO_R8,`UO_XR,`UO_ZR,48'h0};
uopl[`CPX_ZP]		= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_CMPB,`UO_ZERO,`UO_XR,`UO_TMP,32'h0};
uopl[`CPX_ZPY]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_YR,`UO_CMPB,`UO_ZERO,`UO_XR,`UO_TMP,32'h0};
uopl[`CPX_ABS]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_CMP,`UO_ZERO,`UO_XR,`UO_TMP,32'h0};
uopl[`INX]			= {2'd0,`UOF_NZ,2'd1,`UO_ADDIB,`UO_P1,`UO_XR,`UO_ZR,48'h0};
uopl[`DEX]			= {2'd0,`UOF_NZ,2'd1,`UO_ADDIB,`UO_M1,`UO_XR,`UO_ZR,48'h0};
uopl[`INY]			= {2'd0,`UOF_NZ,2'd1,`UO_ADDIB,`UO_P1,`UO_YR,`UO_ZR,48'h0};
uopl[`DEY]			= {2'd0,`UOF_NZ,2'd1,`UO_ADDIB,`UO_M1,`UO_YR,`UO_ZR,48'h0};
uopl[`PHA]			= {2'd1,`UOF_NONE,2'd0,`UO_SB,`UO_100H,`UO_ACC,`UO_SP,`UO_ADDIB,`UO_M1,`UO_SP,`UO_ZR,32'h0};
uopl[`PLA]			= {2'd1,`UOF_NZ,2'd1,`UO_ADDIB,`UO_P1,`UO_SP,`UO_ZR,`UO_LDB,`UO_100H,`UO_ACC,`UO_SP,32'h0};
uopl[`TAX]			= {2'd0,`UOF_NZ,2'd0,`UO_MOV,`UO_ZERO,`UO_XR,`UO_ACC};
uopl[`TXA]			= {2'd0,`UOF_NZ,2'd0,`UO_MOV,`UO_ZERO,`UO_ACC,`UO_XR};
uopl[`TAY]			= {2'd0,`UOF_NZ,2'd0,`UO_MOV,`UO_ZERO,`UO_YR,`UO_ACC};
uopl[`TYA]			= {2'd0,`UOF_NZ,2'd0,`UO_MOV,`UO_ZERO,`UO_ACC,`UO_YR};
uopl[`TSX]			= {2'd0,`UOF_NZ,2'd0,`UO_MOV,`UO_ZERO,`UO_XR,`UO_SP};
uopl[`TXS]			= {2'd0,`UOF_NZ,2'd0,`UO_MOV,`UO_ZERO,`UO_SP,`UO_XR};
uopl[`BEQ]			= {2'd0,`UOF_NONE,2'd0,`UO_BEQ,`UO_R8,`UO_PC,`UO_ZR};
uopl[`BNE]			= {2'd0,`UOF_NONE,2'd0,`UO_BNE,`UO_R8,`UO_PC,`UO_ZR};
uopl[`BCS]			= {2'd0,`UOF_NONE,2'd0,`UO_BCS,`UO_R8,`UO_PC,`UO_ZR};
uopl[`BCC]			= {2'd0,`UOF_NONE,2'd0,`UO_BCC,`UO_R8,`UO_PC,`UO_ZR};
uopl[`BVS]			= {2'd0,`UOF_NONE,2'd0,`UO_BVS,`UO_R8,`UO_PC,`UO_ZR};
uopl[`BVC]			= {2'd0,`UOF_NONE,2'd0,`UO_BVC,`UO_R8,`UO_PC,`UO_ZR};
uopl[`BMI]			= {2'd0,`UOF_NONE,2'd0,`UO_BMI,`UO_R8,`UO_PC,`UO_ZR};
uopl[`BPL]			= {2'd0,`UOF_NONE,2'd0,`UO_BPL,`UO_R8,`UO_PC,`UO_ZR};
uopl[`CLC]			= {2'd0,`UOF_NONE,2'd0,`UO_CLC,`UO_ZERO,`UO_ZR,`UO_ZR};
uopl[`SEC]			= {2'd0,`UOF_NONE,2'd0,`UO_SEC,`UO_ZERO,`UO_ZR,`UO_ZR};
uopl[`JMP]			= {2'd0,`UOF_NONE,2'd0,`UO_LDIW,`UO_R16,`UO_PC,`OU_ZR,48'h0};
uopl[`JSR]			= {2'd1,`UOF_NONE,2'd0,`UO_STW,`UO_FFH,`UO_PC2,`UO_SP,`UO_ADDIB,`UO_M2,`UO_SP,`UO_ZR,32'h0};
uopl[`RTS]		  = {2'd2,`UOF_NONE,2'd0,`UO_ADDIB,`UO_P2,`UO_SP,`UO_ZR,`UO_LDW,`UO_FFFFH,`UO_PC,`UO_SP,`UO_ADDW,`UO_P1,`UO_PC,`UO_ZR,16'h0};
end

task tskLd4;
input [3:0] ld4;
input [23:0] insn;
output [15:0] const;
begin
	case(ld4)
	`UO_M3:	const <= 16'hFFFD;
	`UO_M2:	const <= 16'hFFFE;
	`UO_M1:	const <= 16'hFFFF;
	`UO_P3:	const <= 16'h0003;
	`UO_P2:	const <= 16'h0002;
	`UO_P1:	const <= 16'h0001;
	`UO_R8:	const <= insn[15:8];
	`UO_R16:	const <= insn[23:8];
	default:	const <= 16'h0000;
	endcase
end
endtask

wire [2:0] uo_len1 = uopl[opcode1][69:68] + 2'd1;
wire [2:0] uo_len2 = uopl[opcode2][69:68] + 2'd1;
wire [1:0] uo_flags1 = uopl[opcode1][67:66];
wire [1:0] uo_flags2 = uopl[opcode2][67:66];
wire [1:0] uo_whflg1 = uopl[opcode1][65:64];
wire [1:0] uo_whflg2 = uopl[opcode2][65:64];
wire [15:0] uo_insn1 [0:3];
wire [15:0] uo_insn2 [0:3];
assign uo_insn1[0] = uopl[opcode1][63:48];
assign uo_insn1[1] = uopl[opcode1][47:32];
assign uo_insn1[2] = uopl[opcode1][31:16];
assign uo_insn1[3] = uopl[opcode1][15: 0];
assign uo_insn2[1] = uopl[opcode2][63:48];
assign uo_insn2[2] = uopl[opcode2][47:32];
assign uo_insn2[3] = uopl[opcode2][31:16];
assign uo_insn2[4] = uopl[opcode2][15: 0];

`define UO_OP		15:10
`define UO_LD4	9:6
`define UO_RD		5:3
`define UO_RN		2:0

wire [QSLOTS-1:0] slotv;
reg [7:0] uoq_tail, uoq_head;
wire [7:0] uoq_room = uoq_tail > uoq_head ? uoq_head + uoq_size - uoq_tail : uoq_head - uoq_tail;

always @*
begin
	q1 <= FALSE;
	q2 <= FALSE;
	if (uoq_room >= uo_len1 + uo_len2) begin
		q2 <= TRUE;
	else if (uoq_room >= uo_len1) begin
		q1 <= TRUE;
end

always @(posedge clk_i)
if (rst_i) begin
	for (n = 0; n < UOQ_ENTRIES; n = n + 1) begin
		uoq_uop[n] <= 14'd0;
		uoq_const[n] <= 16'h0000;
	end
end
begin
	if (q2) begin
		uoq_pc[uoq_tail] <= pc;
		uoq_uop[uoq_tail] <= uo_insn1[0];
		uoq_fl[uoq_tail] <= uo_len1==2'b00 ? 2'b11: 2'b01;
		uoq_flagsupd[uoq_tail + uo_whflg1] = uo_flags1;
		tskLd4(uo_insn1[0][`UO_LD4],insnx[0],uoq_const[uoq_tail]);
		if (uopl[opcode1][65:64]>2'b00) begin
			uoq_pc[(uoq_tail+1) % UOQ_ENTRIES] <= pc;
			uoq_uop[(uoq_tail+1) % UOQ_ENTRIES] <= uo_insn1[1];
			uoq_fl[(uoq_tail+1) % UOQ_ENTRIES] <= uopl[opcode1][65:64]==2'b01 ? 2'b10 : 2'b00;
			tskLd4(uo_insn1[1][`UO_LD4],insnx[0],uoq_const[(uoq_tail+1) % UOQ_ENTRIES]);
		end
		if (uopl[opcode1][65:64]>2'b01) begin
			uoq_pc[(uoq_tail+2) % UOQ_ENTRIES] <= pc;
			uoq_uop[(uoq_tail+2) % UOQ_ENTRIES] <= uo_insn1[2];
			uoq_fl[(uoq_tail+2) % UOQ_ENTRIES] <= uopl[opcode1][65:64]==2'b10 ? 2'b10 : 2'b00;
			tskLd4(uo_insn1[2][`UO_LD4],insnx[0],uoq_const[(uoq_tail+2) % UOQ_ENTRIES]);
		end
		if (uopl[opcode1][65:64]>2'b10) begin
			uoq_pc[(uoq_tail+3) % UOQ_ENTRIES] <= pc;
			uoq_uop[(uoq_tail+3) % UOQ_ENTRIES] <= uo_insn1[3];
			uoq_fl[(uoq_tail+3) % UOQ_ENTRIES] <= 2'b10;
			tskLd4(uo_insn1[3][`UO_LD4],insnx[0],uoq_const[(uoq_tail+3) % UOQ_ENTRIES]);
		end
		for (n = 0; n < 4; n = n + 1)
			if (n < uo_len1)
				uop_flagsupd[(uop_tail+n) % UOQ_ENTRIES] = `UOF_NONE;
		uop_flagsupd[(uop_tail+uo_whflg1) % UOP_ENTRIES] = uo_flags1;
		uoq_pc[uoq_tail_uo_len1] <= pc + len1;
		uoq_uop[uoq_tail+uo_len1] <= uo_insn2[0];
		uoq_fl[(uoq_tail+uo_len1) % UOQ_ENTRIES] <= uo_len2==2'b00 ? 2'b11 : 2'b01;
		uoq_tail <= (uoq_tail + uo_len1 + 8'd1) % UOQ_ENTRIES;
		tskLd4(uo_insn2[0][`UO_LD4],insnx[1],uoq_const[uoq_tail + uo_len1]);
		if (uo_len2 > 2'b00) begin
			uoq_pc[(uoq_tail+uo_len1+1) % UOQ_ENTRIES] <= pc + len1;
			uoq_uop[(uoq_tail+uo_len1+1) % UOQ_ENTRIES] <= uo_insn2[1];
			uoq_fl[(uoq_tail+uo_len1+1) % UOQ_ENTRIES] <= uo_len2==2'b01 ? 2'b10 : 2'b00;
			uoq_tail <= (uoq_tail + uo_len1 + 8'd2) % UOQ_ENTRIES;
			tskLd4(uo_insn2[1][`UO_LD4],insnx[1],uoq_const[(uoq_tail+uo_len1+1) % UOQ_ENTRIES]);
		end
		if (uo_len2 > 2'b01) begin
			uoq_pc[(uoq_tail+uo_len1+2) % UOQ_ENTRIES] <= pc + len1;
			uoq_uop[(uoq_tail+uo_len1+2) % UOQ_ENTRIES] <= uo_insn2[2];
			uoq_fl[(uoq_tail+uo_len1+2) % UOQ_ENTRIES] <= uo_len2==2'b10 ? 2'b10 : 2'b00;
			uoq_tail <= (uoq_tail + uo_len1 + 8'd3) % UOQ_ENTRIES;
			tskLd4(uo_insn2[2][`UO_LD4],insnx[1],uoq_const[(uoq_tail+uo_len1+2) % UOQ_ENTRIES]);
		end
		if (uo_len2 > 2'b10) begin
			uoq_pc[(uoq_tail+uo_len1+3) % UOQ_ENTRIES] <= pc + len1;
			uoq_uop[(uoq_tail+uo_len1+3) % UOQ_ENTRIES] <= uo_insn2[3];
			uoq_fl[(uoq_tail+uo_len1+3) % UOQ_ENTRIES] <= 2'b10;
			uoq_tail <= (uoq_tail + uo_len1 + 8'd4) % UOQ_ENTRIES;
			tskLd4(uo_insn2[3][`UO_LD4],insnx[1],uoq_const[(uoq_tail+uo_len1+3) % UOQ_ENTRIES]);
		end
		for (n = 0; n < 4; n = n + 1)
			if (n < uo_len2)
				uop_flagsupd[(uop_tail+uo_len1+n) % UOQ_ENTRIES] = `UOF_NONE;
		uop_flagsupd[(uop_tail+uo_len1+uo_whflg1) % UOP_ENTRIES] = uo_flags1;
	end
	else if (q1) begin
		uoq_pc[uoq_tail] <= pc;
		uoq_uop[uoq_tail] <= uo_insn1[0];
		uoq_fl[uoq_tail] <= uo_len1==2'b00 ? 2'b11: 2'b01;
		uoq_tail <= (uoq_tail + 8'd1) % UOQ_ENTRIES;
		tskLd4(uo_insn1[0][`UO_LD4],insnx[0],uoq_const[uoq_tail]);
		if (uo_len1 > 2'b00) begin
			uoq_pc[(uoq_tail+1) % UOQ_ENTRIES] <= pc;
			uoq_uop[(uoq_tail+1) % UOQ_ENTRIES] <= uo_insn1[1];
			uoq_fl[(uoq_tail+1) % UOQ_ENTRIES] <= uopl[opcode1][65:64]==2'b01 ? 2'b10 : 2'b00;
			uoq_tail <= (uoq_tail + 8'd2) % UOQ_ENTRIES;
			tskLd4(uo_insn1[1][`UO_LD4],insnx[0],uoq_const[(uoq_tail+1) % UOQ_ENTRIES]);
		end
		if (uo_len1 > 2'b01) begin
			uoq_pc[(uoq_tail+2) % UOQ_ENTRIES] <= pc;
			uoq_uop[(uoq_tail+2) % UOQ_ENTRIES] <= uo_insn1[2];
			uoq_fl[(uoq_tail+2) % UOQ_ENTRIES] <= uopl[opcode1][65:64]==2'b10 ? 2'b10 : 2'b00;
			uoq_tail <= (uoq_tail + 8'd3) % UOQ_ENTRIES;
			tskLd4(uo_insn1[2][`UO_LD4],insnx[0],uoq_const[(uoq_tail+2) % UOQ_ENTRIES]);
		end
		if (uo_len1 > 2'b10) begin
			uoq_pc[(uoq_tail+3) % UOQ_ENTRIES] <= pc;
			uoq_uop[(uoq_tail+3) % UOQ_ENTRIES] <= uo_insn1[3];
			uoq_fl[(uoq_tail+3) % UOQ_ENTRIES] <= 2'b10;
			uoq_tail <= (uoq_tail + 8'd4) % UOQ_ENTRIES;
			tskLd4(uo_insn1[3][`UO_LD4],insnx[0],uoq_const[(uoq_tail+3) % UOQ_ENTRIES]);
		end
		for (n = 0; n < 4; n = n + 1)
			if (n < uo_len1)
				uop_flagsupd[(uop_tail+n) % UOQ_ENTRIES] = `UOF_NONE;
		uop_flagsupd[(uop_tail+uo_whflg1) % UOP_ENTRIES] = uo_flags1;
	end
end

reg [3:0] queuedCnt;
always @(posedge clk_i)
if (rst_i) begin
	queuedCnt <= 4'd0;
end
begin
	queuedCnt <= 4'd0;
	if (q2)
		queuedCnt <= 4'd2 + uo_len1 + uo_len2;
	else if (q1)
		queuedCnt <= 4'd1 + uo_len1;
end

always @(posedge clk_i)
	uoq_head <= (uoq_head + queuedCnt) % UOQ_ENTRIES;

assign slotv[0] = uoq_head != uoq_tail;
assign slotv[1] = uoq_head != uoq_tail && uoq_head + 4'd1 != uoq_tail;
assign slotv[2] = uoq_head != uoq_tail && uoq_head + 4'd1 != uoq_tail && uoq_head + 4'd2 != uoq_tail;

assign ic2_out = ic1_out >> {len1,3'b0};
wire [7:0] opcode1 = ic_out[7:0];
wire [7:0] opcode2 = ic2_out[7:0];
instLength il1 (opcode1, len1);
instLength il2 (opcode2, len2);

programCounter upc1
(
	.rst(rst_i),
	.clk(clk),
	.q1(q1),
	.q2(q2),
	.insnx(insnx),
	.phit(phit),
	.freezepc(freezepc),
	.branchmiss(branchmiss),
	.misspc(misspc),
	.len1(len1),
	.len2(len2),
	.jc(slot_jc),
	.rts(slot_ret),
	.br(slot_br),
	.take_branch(take_branch),
	.btgt(btgt),
	.pc(pc),
	.branch_pc(next_pc),
	.ra(ra),
	.pc_override(pc_override),
	.debug_on(debug_on)
);

reg [2:0] Rd;
reg [1:0] Rn;

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	Rd[n] = uoq_uop[(uoq_head+n)%UOQ_ENTRIES][4:2];
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	Rn[n] = uoq_uop[(uoq_head+n)%UOQ_ENTRIES][1:0];

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	case(Rd[n])
	3'd0:	rfoa[n] <= {8'h00,ac};
	3'd1:	rfoa[n] <= {8'h00,xr};
	3'd2:	rfoa[n] <= {8'h00,yr};
	3'd3:	rfoa[n] <= {8'h01,sp};
	3'd4:	rfoa[n] <= pc;
	3'd5: rfoa[n] <= tmp;
	3'd7:	rfoa[n] <= {8'h00,sr};
	default:	rfoa[n] <= 16'h0;
	endcase

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	case(Rn[n])
	2'd0:	rfob[n] <= 16'h0000;
	2'd1:	rfob[n] <= {8'h0,xr};
	2'd2:	rfob[n] <= {8'h0,yr};
	2'd3:	rfob[n] <= {8'h1,sp};
	endcase

wire [15:0] argA [0:QSLOTS-1];
wire [15:0] argB [0:QSLOTS-1];

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	argA[n] = rfoa[n];
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	argB[n] = rfob[n];
	
always @(posedge clk_i)
if (rst_i) begin
end
else begin

	if (|fb_panic)
		panic <= fb_panic;

	// Only one branchmiss is allowed to be processed at a time. If a second 
	// branchmiss occurs while the first is being processed, it would have
	// to of occurred as a speculation in the branch shadow of the first.
	// The second instruction would be stomped on by the first branchmiss so
	// there is no need to process it.
	// The branchmiss has to be latched, then cleared later as there could
	// be a cache miss at the same time meaning the switch to the new pc
	// does not take place immediately.
	if (!branchmiss) begin
		if (excmiss) begin
			branchmiss <= `TRUE;
			missip <= excmissip;
			missid <= (|iq_exc[heads[0]] ? heads[0] : |iq_exc[heads[1]] ? heads[1] : heads[2]);
		end
		else if (fcu_branchmiss) begin
			branchmiss <= `TRUE;
			missip <= fcu_missip;
			missid <= fcu_sourceid;
		end
	end
	else
		active_tag <= miss_tag;
	// Clear a branch miss when target instruction is fetched.
	if (will_clear_branchmiss) begin
		branchmiss <= `FALSE;
	end

	// The following signals only pulse

	// Instruction decode output should only pulse once for a queue entry. We
	// want the decode to be invalidated after a clock cycle so that it isn't
	// inadvertently used to update the queue at a later point.
	dramA_v <= `INV;
	dramB_v <= `INV;
	ld_time <= {ld_time[4:0],1'b0};
	wc_times <= wc_time;
     rf_vra0 <= regIsValid[Rs1[0]];
     rf_vra1 <= regIsValid[Rs1[1]];
     rf_vra2 <= regIsValid[Rs1[2]];

	excmiss <= FALSE;
	invic <= FALSE;
	if (L1_invline)
		invicl <= FALSE;
	invdcl <= FALSE;
	tick <= tick + 4'd1;
	alu0_ld <= FALSE;
	alu1_ld <= FALSE;
	fpu1_ld <= FALSE;
	fpu2_ld <= FALSE;
	fcu_ld <= FALSE;
	cr0[17] <= 1'b0;
	queuedOn <= 1'b0;

  if (waitctr != 48'd0)
		waitctr <= waitctr - 4'd1;

  if (iq_fc[fcu_id] && iq_v[fcu_id] && !iq_done[fcu_id] && iq_out[fcu_id])
  	fcu_timeout <= fcu_timeout + 8'd1;

	if (!branchmiss) begin
		queuedOn <= queuedOnp;
		case(slotvd)
		3'b001:
			if (queuedOnp[0]) begin
				queue_slot(0,rob_tails[0],maxsn+1'd1,id_bus[0],active_tag,rob_tails[0]);
			end
		3'b010:
			if (queuedOnp[1]) begin
				queue_slot(1,rob_tails[0],maxsn+1'd1,id_bus[1],active_tag,rob_tails[0]);
			end
		3'b011:
			if (queuedOnp[0]) begin
				queue_slot(0,rob_tails[0],maxsn+1'd1,id_bus[0],active_tag,rob_tails[0]);
				if (queuedOnp[1]) begin
					queue_slot(1,rob_tails[1],maxsn+2'd2,id_bus[1],is_branch[0] ? active_tag+2'd1 : active_tag,rob_tails[1]);
					arg_vs(4'b0011);
				end
			end
		3'b100:
			if (queuedOnp[2]) begin
				queue_slot(2,rob_tails[0],maxsn+1'd1,id_bus[2],active_tag,rob_tails[0]);
			end
		3'b101:	;	// illegal
		3'b110:
			if (queuedOnp[1]) begin
				queue_slot(1,rob_tails[0],maxsn+1'd1,id_bus[1],active_tag,rob_tails[0]);
				if (queuedOnp[2]) begin
					queue_slot(2,rob_tails[1],maxsn+2'd2,id_bus[2],is_branch[1] ? active_tag + 2'd1 : active_tag,rob_tails[1]);
					arg_vs(4'b0110);
				end
			end
		3'b111:
			if (queuedOnp[0]) begin
				queue_slot(0,rob_tails[0],maxsn+1'd1,id_bus[0],active_tag,rob_tails[0]);
				if (queuedOnp[1]) begin
					queue_slot(1,rob_tails[1],maxsn+2'd2,id_bus[1],is_branch[0] ? active_tag + 2'd1 : active_tag,rob_tails[1]);
					arg_vs(4'b0011);
					if (queuedOnp[2]) begin
						queue_slot(2,rob_tails[2],maxsn+2'd3,id_bus[2],
							is_branch[0] && is_branch[1] ? active_tag + 2'd2 :
							is_branch[0] ? active_tag + 2'd1 : is_branch[1] ? active_tag + 2'd1 : active_tag,rob_tails[2]);
						arg_vs(4'b0111);
					end
				end
			end
		default:	;
		endcase
	end
	
end

// Patterns do not have all one bits! The tail queue slot depends on which set
// bit of the pattern is present. For instance patterns 001,010, and 100 all
// refer to the same tail - tail[0]. Need to count the set bits in the pattern
// to determine the tail number.
function [2:0] tails_rc;
input [QSLOTS-1:0] pat;
input [QSLOTS-1:0] rc;
reg [2:0] cnt;
begin
	cnt = 0;
	tails_rc = QSLOTS-1;
	for (n = 0; n < QSLOTS; n = n + 1) begin
		if (rc==n)
			tails_rc = cnt;
		if (pat[n])
			cnt = cnt + 1;
	end
end
endfunction

// Note that the register source id is set to the qid for now, until a ROB 
// entry is assigned. The rid will be looked up when the ROB entry is
// assigned.
task arg_vs;
input [QSLOTS-1:0] pat;
begin
	for (row = 0; row < QSLOTS; row = row + 1) begin
		if (pat[row]) begin
			iq_argA_v [tails[tails_rc(pat,row)]] <= regIsValid[Rd[row]] | Source1Valid(uop[insnx[row][7:0]][12:8]);
			iq_argA_s [tails[tails_rc(pat,row)]] <= rf_source[Rd[row]];
			iq_argB_v [tails[tails_rc(pat,row)]] <= regIsValid[Rn[row]] | Source2Valid(uop[insnx[row][7:0]][12:8]);
			iq_argB_s [tails[tails_rc(pat,row)]] <= rf_source[Rn[row]];
			for (col = 0; col < QSLOTS; col = col + 1) begin
				if (col < row) begin
					if (pat[col]) begin
						// Special checking for condition register sideways slice
						if (Rd[row]==Rd[col] && slot_rfw[col]) begin
							iq_argA_v [tails[tails_rc(pat,row)]] <= Source1Valid(uop[insnx[row][7:0]][12:8]);;
							iq_argA_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end

						if (Rn[row]==Rd[col] && slot_rfw[col]) begin
							iq_argB_v [tails[tails_rc(pat,row)]] <= Source2Valid(uop[insnx[row][7:0]][12:8]);
							iq_argB_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end
					end
				end
			end
		end
	end
end
endtask

task queue_slot;
input [2:0] slot;
input [`QBITS] ndx;
input [`SNBITS] seqnum;
input [`IBTOP:0] id_bus;
input [`QBITS] btag;
input [`RBITS] rid;
begin
	iq_rid[ndx] <= rid;
	iq_sn[ndx] <= seqnum;
	iq_state[ndx] <= IQS_QUEUED;
	iq_br_tag[ndx] <= btag;
	iq_pc <= uoq_pc[(uo_head+slot) % UOQ_ENTRIES];
	iq_instr[ndx][4:0] <= uoq_uop[(uo_head+slot) % UOQ_ENTRIES][12:8];
	case (uo_queue[uoq_head+slot][7:5])
	3'd0:	iq_instr[ndx][28:13] <= 16'd0;
	3'd1:	iq_instr[ndx][28:13] <= 16'd1;
	3'd2:	iq_instr[ndx][28:13] <= 16'd2;
	3'd3:	iq_instr[ndx][28:13] <= 16'd3;
	3'd4:	iq_instr[ndx][28:13] <= insnx[slot][15:8];
	3'd5:	iq_instr[ndx][28:13] <= insnx[slot][23:8];
	3'd7:	iq_instr[ndx][28:13] <= 16'hFFFF;
	default:	iq_instr[ndx][28:13] <= 16'd0;
	endcase
	iq_argA[ndx] <= argA[slot];
	iq_argB[ndx] <= argB[slot];
	iq_argA_v[ndx] <= regIsValid[Rd[slot]] || Source1Valid(uoq_uop[(uo_head+slot) % UOQ_ENTRIES][12:8]);
	iq_argB_v[ndx] <= regIsValid[Rs2[slot]] || Source2Valid(uoq_uop[(uo_head+slot) % UOQ_ENTRIES][12:8]);
	iq_argA_s[ndx] <= rf_source[Rd[slot]];
	iq_argB_s[ndx] <= rf_source[Rn[slot]];
	iq_pt[ndx] <= predict_taken[slot];
	iq_tgt[ndx] <= uoq_uop[(uo_head+slot) % UOQ_ENTRIES][4:2];
	iq_crtgt[ndx] <= Crd[slot];
	set_insn(ndx,id_bus);
	rob_pc[rid] <= uoq_pc[(uo_head+slot) % UOQ_ENTRIES];
	rob_res[rid] <= 1'd0;
	rob_status[rid] <= 1'd0;
	rob_state[rid] <= RS_ASSIGNED;
	rob_id[rid] <= ndx;
end
endtask

task tDram0Issue;
input [`QBITS] n;
begin
	if (iq_state[n]==IQS_AGEN) begin
//	dramA_v <= `INV;
		dram0 		<= `DRAMSLOT_BUSY;
		dram0_id 	<= n[`QBITS];
		dram0_rid <= iq_rid[n];
		dram0_instr <= iq_instr[n];
		dram0_rmw  <= iq_rmw[n];
		dram0_preload <= iq_preload[n];
		dram0_tgt 	<= iq_tgt[n];
		// These two args needed only to support AMO operations
		dram0_argI	<= {{68{iq_instr[n][27]}},iq_instr[n][27:16]};
		dram0_argB  <= iq_argB_v[n] ? iq_argB[n][WID-1:0]
			: iq_argB_s[n]==alu0_id ? ralu0_bus
			: iq_argB_s[n]==alu1_id ? ralu1_bus
			: iq_argB_s[n]==fpu1_id ? rfpu1_bus[WID-1:0]
			: 80'hDEADDEADDEADDEADDEAD;
		if (iq_imm[n] & iq_pushc[n])
			dram0_data <= iq_argI[n];
		else if (iq_stpair[n])
			dram0_data <= {iq_argC[n][127:0],iq_argB[n][127:0]};
		else
			dram0_data <= iq_argB[n][WID-1:0];
		dram0_addr	<= iq_ma[n];
		dram0_unc   <= iq_ma[n][31:20]==12'hFFD || !dce;
		dram0_memsize <= iq_memsz[n];
		dram0_load <= iq_load[n];
		dram0_store <= iq_store[n];
		dram0_ol   <= (iq_rs1[n][RBIT:0]==7'd31 || iq_rs1[n][RBIT:0]==7'd30) ? ol : dl;
	// Once the memory op is issued reset the a1_v flag.
	// This will cause the a1 bus to look for new data from memory (a1_s is pointed to a memory bus)
	// This is used for the load and compare instructions.
	// must reset the a1 source too.
	//iq_a1_v[n] <= `INV;
		iq_state[n] <= IQS_MEM;
		iq_memissue[n] <= `INV;
	end
end
endtask

task tDram1Issue;
input [`QBITS] n;
begin
	if (iq_state[n]==IQS_AGEN) begin
//	dramB_v <= `INV;
	dram1 		<= `DRAMSLOT_BUSY;
	dram1_id 	<= n[`QBITS];
	dram1_rid <= iq_rid[n];
	dram1_instr <= iq_instr[n];
	dram1_rmw  <= iq_rmw[n];
	dram1_preload <= iq_preload[n];
	dram1_tgt 	<= iq_tgt[n];
	// These two args needed only to support AMO operations
	dram1_argI	<= {{68{iq_instr[n][27]}},iq_instr[n][27:16]};
	dram1_argB  <= iq_argB_v[n] ? iq_argB[n][WID-1:0]
	  : iq_argB_s[n]==alu0_id ? ralu0_bus
	  : iq_argB_s[n]==alu1_id ? ralu1_bus
	  : iq_argB_s[n]==fpu1_id ? rfpu1_bus[WID-1:0]
	  : 80'hDEADDEADDEADDEADDEAD;
	if (iq_imm[n] & iq_pushc[n])
		dram1_data <= iq_argI[n];
	else if (iq_stpair[n])
		dram1_data <= {iq_argC[n][127:0],iq_argB[n][127:0]};
	else
		dram1_data <= iq_argB[n][WID-1:0];
	dram1_addr	<= iq_ma[n];
	//	             if (ol[iq_thrd[n]]==`OL_USER)
	//	             	dram1_seg   <= (iq_rs1[n]==5'd30 || iq_rs1[n]==5'd31) ? {ss[iq_thrd[n]],13'd0} : {ds[iq_thrd[n]],13'd0};
	//	             else
	dram1_unc   <= iq_ma[n][31:20]==12'hFFD || !dce;
	dram1_memsize <= iq_memsz[n];
	dram1_load <= iq_load[n];
	dram1_store <= iq_store[n];
	dram1_ol   <= (iq_rs1[n][RBIT:0]==7'd31 || iq_rs1[n][RBIT:0]==7'd30) ? ol : dl;
	//iq_a1_v[n] <= `INV;
	iq_state[n] <= IQS_MEM;
	iq_memissue[n] <= `INV;
	end
end
endtask

task wb_nack;
begin
	dcti <= 3'b000;
	dbte <= 2'b00;
	dcyc <= `LOW;
	dstb <= `LOW;
	dwe <= `LOW;
	dsel <= 8'h00;
//	vadr <= 32'hCCCCCCCC;
end
endtask

endmodule

module instLength(opcode,len);
input [7:0] opcode;
case(opcode)
`SEP,`REP:	len <= 4'd2;
`BRK:	len <= 4'd0;
`BPL,`BMI,`BCS,`BCC,`BVS,`BVC,`BEQ,`BNE,`BRA:	len <= 4'd2;
`BRL: len <= 4'd3;
`CLC,`SEC,`CLD,`SED,`CLV,`CLI,`SEI:	len <= 4'd1;
`TAS,`TSA,`TAY,`TYA,`TAX,`TXA,`TSX,`TXS,`TYX,`TXY,`TCD,`TDC,`XBA:	len <= 4'd1;
`INY,`DEY,`INX,`DEX,`INA,`DEA: len <= 4'd1;
`XCE,`WDM: len <= 4'd1;
`STP,`WAI: len <= 4'd1;
`JMP,`JML,`JMP_IND,`JMP_INDX,
`RTS,`RTL,`RTI: len <= 4'd0;
`JSR,`JSR_INDX:	len <= 4'd2;
`JSL:	len <= 4'd3;
`NOP: len <= 4'd1;

`ADC_IMM,`SBC_IMM,`CMP_IMM,`AND_IMM,`ORA_IMM,`EOR_IMM,`LDA_IMM,`BIT_IMM:	len <= m16 ? 4'd3 : 4'd2;
`LDX_IMM,`LDY_IMM,`CPX_IMM,`CPY_IMM: len <= xb16 ? 4'd3 : 4'd2;

`TRB_ZP,`TSB_ZP,
`ADC_ZP,`SBC_ZP,`CMP_ZP,`AND_ZP,`ORA_ZP,`EOR_ZP,`LDA_ZP,`STA_ZP: len <= 4'd2;
`LDY_ZP,`LDX_ZP,`STY_ZP,`STX_ZP,`CPX_ZP,`CPY_ZP,`BIT_ZP,`STZ_ZP: len <= 4'd2;
`ASL_ZP,`ROL_ZP,`LSR_ZP,`ROR_ZP,`INC_ZP,`DEC_ZP: len <= 4'd2;

`ADC_ZPX,`SBC_ZPX,`CMP_ZPX,`AND_ZPX,`ORA_ZPX,`EOR_ZPX,`LDA_ZPX,`STA_ZPX: len <= 4'd2;
`LDY_ZPX,`STY_ZPX,`BIT_ZPX,`STZ_ZPX: len <= 4'd2;
`ASL_ZPX,`ROL_ZPX,`LSR_ZPX,`ROR_ZPX,`INC_ZPX,`DEC_ZPX: len <= 4'd2;
`LDX_ZPY,`STX_ZPY: len <= 4'd2;

`ADC_I,`SBC_I,`AND_I,`ORA_I,`EOR_I,`CMP_I,`LDA_I,`STA_I,
`ADC_IL,`SBC_IL,`AND_IL,`ORA_IL,`EOR_IL,`CMP_IL,`LDA_IL,`STA_IL,
`ADC_IX,`SBC_IX,`CMP_IX,`AND_IX,`OR_IX,`EOR_IX,`LDA_IX,`STA_IX: len <= 4'd2;

`ADC_IY,`SBC_IY,`CMP_IY,`AND_IY,`OR_IY,`EOR_IY,`LDA_IY,`STA_IY: len <= 4'd2;
`ADC_IYL,`SBC_IYL,`CMP_IYL,`AND_IYL,`ORA_IYL,`EOR_IYL,`LDA_IYL,`STA_IYL: len <= 4'd2;

`TRB_ABS,`TSB_ABS,
`ADC_ABS,`SBC_ABS,`CMP_ABS,`AND_ABS,`OR_ABS,`EOR_ABS,`LDA_ABS,`STA_ABS: len <= 4'd3;
`LDX_ABS,`LDY_ABS,`STX_ABS,`STY_ABS,`CPX_ABS,`CPY_ABS,`BIT_ABS,`STZ_ABS: len <= 4'd3;
`ASL_ABS,`ROL_ABS,`LSR_ABS,`ROR_ABS,`INC_ABS,`DEC_ABS: len <= 4'd3;

`ADC_ABSX,`SBC_ABSX,`CMP_ABSX,`AND_ABSX,`OR_ABSX,`EOR_ABSX,`LDA_ABSX,`STA_ABSX: len <= 4'd3;
`LDY_ABSX,`BIT_ABSX,`STZ_ABSX:	len <= 4'd3;
`ASL_ABSX,`ROL_ABSX,`LSR_ABSX,`ROR_ABSX,`INC_ABSX,`DEC_ABSX: len <= 4'd3;

`ADC_ABSY,`SBC_ABSY,`CMP_ABSY,`AND_ABSY,`ORA_ABSY,`EOR_ABSY,`LDA_ABSY,`STA_ABSY: len <= 4'd3;
`LDX_ABSY: len <= 4'd3;

`ADC_AL,`SBC_AL,`CMP_AL,`AND_AL,`ORA_AL,`EOR_AL,`LDA_AL,`STA_AL: len <= 4'd4;
`ADC_ALX,`SBC_ALX,`CMP_ALX,`AND_ALX,`ORA_ALX,`EOR_ALX,`LDA_ALX,`STA_ALX: len <= 4'd4;

`ADC_DSP,`SBC_DSP,`CMP_DSP,`AND_DSP,`ORA_DSP,`EOR_DSP,`LDA_DSP,`STA_DSP: len <= 4'd2;
`ADC_DSPIY,`SBC_DSPIY,`CMP_DSPIY,`AND_DSPIY,`ORA_DSPIY,`EOR_DSPIY,`LDA_DSPIY,`STA_DSPIY: len <= 4'd2;

`ASL_ACC,`LSR_ACC,`ROR_ACC,`ROL_ACC: len <= 4'd1;

`PHP,`PHA,`PHX,`PHY,`PHK,`PHB,`PHD,`PLP,`PLA,`PLX,`PLY,`PLB,`PLD: len <= 4'd1;
`PEA,`PER,`MVN,`MVP: len <= 4'd3;
`PEI:	len <= 4'd2;

default:	len <= 4'd0;	// unimplemented instruction
endcase
endmodule
