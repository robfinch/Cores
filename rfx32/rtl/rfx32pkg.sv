
package rfx32pkg;

`define INV	1'b0
`define VAL	1'b1
`define PANIC_INVALIDFBSTATE	4'd1
`define PANIC_BRANCHBACK 4'd2
`define PANIC_INVALIDIQSTATE 4'd3
`define BACK_BRANCH	1'b1

parameter VAL = 1'b1;
parameter INV = 1'b0;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter BACK_BRANCH = 1'b1;
parameter PANIC_INVALIDFBSTATE = 4'd1;
parameter PANIC_BRANCHBACK = 4'd2;
parameter PANIC_INVALIDIQSTATE = 4'd3;

parameter NDATA_PORTS = 3;

typedef logic [11:0] asid_t;
typedef logic [31:0] address_t;
typedef logic [31:0] code_address_t;
typedef logic [31:0] virtual_address_t;
typedef logic [31:0] physical_address_t;
typedef logic [31:0] value_t;
typedef logic [5:0] cause_t;

typedef struct packed {
	logic [4:0] num;
} regspec_t;

typedef enum logic [5:0] {
	OP_BRK = 6'd0,
	OP_ADDIS = 6'd1,
	OP_R2A = 6'd2,
	OP_R2L = 6'd3,
	OP_ADDI = 6'd4,
	OP_CMPI = 6'd5,
	OP_MULI = 6'd6,
	OP_DIVI = 6'd7,
	OP_ANDI = 6'd8,
	OP_ORI = 6'd9,
	OP_EORI = 6'd10,
	OP_R2S = 6'd11,
	OP_SUBFI = 6'd12,
	OP_SLTI = 6'd13,
	OP_MULUI = 6'd14,
	OP_DIVUI = 6'd15,
	OP_RET = 6'd16,
	OP_RETD = 6'd17,
	OP_CALL = 6'd18,
	OP_LCALL = 6'd19,
	OP_XLCALL = 6'd20,
	OP_BEQ = 6'd24,
	OP_BNE = 6'd25,
	OP_BLT = 6'd26,
	OP_BLE = 6'd27,
	OP_BLTU = 6'd28,
	OP_BLEU = 6'd29,
	OP_LBcc = 6'd30,
	OP_XLBcc = 6'd31,
	OP_LDB = 6'd32,
	OP_LDBU = 6'd33,
	OP_LDW = 6'd34,
	OP_LDWU = 6'd35,
	OP_LDT = 6'd36,
	OP_LDA = 6'd38,
	OP_CACHE = 6'd39,
	OP_LDBX = 6'd40,
	OP_LDBUX = 6'd41,
	OP_LDWX = 6'd42,
	OP_LDWUX = 6'd43,
	OP_LDTX = 6'd44,
	OP_LDAX = 6'd46,
	OP_CACHEX = 6'd47,
	OP_STB = 6'd48,
	OP_STW = 6'd49,
	OP_STT = 6'd50,
	OP_STBX = 6'd52,
	OP_STWX = 6'd53,
	OP_STTX = 6'd54,
	OP_PFX8 = 6'd56,
	OP_PFX16 = 6'd57,
	OP_PFX24 = 6'd58,
	OP_PFX32 = 6'd59,
	OP_ADDIPC = 6'd61,
	OP_NOP = 6'd63
} opcode_t;

typedef enum logic [2:0] {
	FN_ADD = 3'd0,
	FN_CMP = 3'd1,
	FN_MUL = 3'd2,
	FN_DIV = 3'd3,
	FN_SUB = 3'd4,
	FN_MULU = 3'd6,
	FN_DIVU = 3'd7
} r2afunc_t;

typedef enum logic [2:0] {
	FN_AND = 3'd0,
	FN_OR = 3'd1,
	FN_EOR = 3'd2,
	FN_ANDN = 3'd3,
	FN_NAND = 3'd4,
	FN_NOR = 3'd5,
	FN_ENOR = 3'd6,
	FN_ORN = 3'd7
} r2lfunc_t;

typedef enum logic [2:0] {
	FN_SEQ = 3'd0,
	FN_SNE = 3'd1,
	FN_SLT = 3'd2,
	FN_SLE = 3'd3,
	FN_SLTU = 3'd4,
	FN_SLEU = 3'd5
} r2sfunc_t;

typedef union packed {
	r2afunc_t r2a;
	r2lfunc_t r2l;
	r2sfunc_t r2s;	
} r2func_t;

typedef enum logic [2:0]
{
	CND_EQ = 3'd0,
	CND_NE = 3'd1,
	CND_LT = 3'd2,
	CND_LE = 3'd3,
	CND_LTU = 3'd4,
	CND_LEU = 3'd5
} cond_t;

typedef struct packed
{
	logic [55:0] pad;
	logic [7:0] imm;
	regspec_t Ra;
	regspec_t Rt;
	opcode_t opcode;
} riinst;

typedef struct packed
{
	logic [55:0] pad;
	r2func_t func;
	regspec_t Rb;
	regspec_t Ra;
	regspec_t Rt;
	opcode_t opcode;
} r2inst;

typedef struct packed
{
	logic [55:0] pad;
	logic [7:0] disp0700;
	regspec_t Rb;
	regspec_t Ra;
	opcode_t opcode;
} brinst;

typedef struct packed
{
	logic [47:0] pad;
	logic [12:0] disp1200;
	cond_t cnd;
	regspec_t Rb;
	regspec_t Ra;
	opcode_t opcode;
} lbrinst;

typedef struct packed
{
	logic [39:0] pad;
	logic [20:0] disp1200;
	cond_t cnd;
	regspec_t Rb;
	regspec_t Ra;
	opcode_t opcode;
} xlbrinst;

typedef struct packed
{
	logic [73:0] payload;
	opcode_t opcode;
} anyinst;

typedef union packed
{
	xlbrinst xlbr;
	lbrinst lbr;
	brinst br;
	r2inst r2;
	riinst ri;
	anyinst any;
} instruction_t;

typedef struct packed {
	logic v;
	logic out;
	logic done;
	logic bt;
	logic agen;
	logic mem;
	logic load;
	logic store;
	logic jmp;
	logic imm;
	logic rfw;
	value_t res;
	instruction_t op;
	cause_t exc;
	regspec_t tgt;
	logic [33:0] a0;
	value_t a1;
	logic a1_v;
	logic [4:0] a1_s;
	value_t a2;
	logic a2_v;
	logic [4:0] a2_s;
	address_t pc;
} iq_entry_t;

function fnIsBranch;
input instruction_t ir;
begin
	case(ir.any.opcode)
	OP_BEQ,OP_BNE,OP_BLT,OP_BLE,OP_BLTU,OP_BLEU:
		fnIsBranch = 1'b1;
	OP_LBcc:	fnIsBranch = 1'b1;
	OP_XLBcc:	fnIsBranch = 1'b1;
	default:
		fnIsBranch = 1'b0;
	endcase
end
endfunction

function fnBranchDispSign;
input instruction_t ir;
begin
	case(ir.any.opcode)
	OP_BEQ,OP_BNE,OP_BLT,OP_BLE,OP_BLTU,OP_BLEU:
		fnBranchDispSign = ir[23];
	OP_LBcc:	fnBranchDispSign = ir[31];
	OP_XLBcc:	fnBranchDispSign = ir[39];
	default:	fnBranchDispSign = 1'b0;
	endcase	
end
endfunction

function [31:0] fnBranchDisp;
input instruction_t ir;
begin
	case(ir.any.opcode)
	OP_BEQ,OP_BNE,OP_BLT,OP_BLE,OP_BLTU,OP_BLEU:
		fnBranchDisp = {{24{ir[23]}},ir[23:16]};
	OP_LBcc:	fnBranchDisp = {{19{ir[31]}},ir[31:19]};
	OP_XLBcc:	fnBranchDisp = {{11{ir[39]}},ir[39:19]};
	default:	fnBranchDisp = 'd0;
	endcase
end
endfunction

function fnIsBackBranch;
input instruction_t ir;
begin
	fnIsBackBranch = fnIsBranch(ir) && fnBranchDispSign(ir);
end
endfunction

function fnIsCall;
input instruction_t ir;
begin
	fnIsCall = ir.any.opcode==OP_CALL || ir.any.opcode==OP_LCALL || ir.any.opcode==OP_XLCALL;
end
endfunction

function fnIsFlowCtrl;
input instruction_t ir;
begin
	fnIsFlowCtrl = 1'b0;
	case(ir.any.opcode)
	OP_BRK:	fnIsFlowCtrl = 1'b1;
	OP_CALL,OP_LCALL,OP_XLCALL:
		fnIsFlowCtrl = 1'b1;
	OP_BEQ,OP_BNE,OP_BLT,OP_BLE,OP_BLTU,OP_BLEU:
		fnIsFlowCtrl = 1'b1;	
	OP_LBcc,OP_XLBcc:
		fnIsFlowCtrl = 1'b1;	
	OP_RETD,OP_RET:
		fnIsFlowCtrl = 1'b1;	
	default:
		fnIsFlowCtrl = 1'b0;
	endcase
end
endfunction

function [4:0] fnRa;
input instruction_t ir;
begin
	case(ir.any.opcode)
	OP_BEQ,OP_BNE,OP_BLT,OP_BLE,OP_BLTU,OP_BLEU:
		fnRa = ir[10:6];
	OP_LBcc,OP_XLBcc:
		fnRa = ir[10:6];
	OP_RETD:
		fnRa = 5'd31;
	default:
		fnRa = ir[15:11];
	endcase
end
endfunction

function [4:0] fnRb;
input instruction_t ir;
begin
	case(ir.any.opcode)
	OP_BEQ,OP_BNE,OP_BLT,OP_BLE,OP_BLTU,OP_BLEU:
		fnRb = ir[15:11];
	OP_LBcc,OP_XLBcc:
		fnRb = ir[15:11];
	default:
		fnRb = ir[20:16];
	endcase
end
endfunction

function [4:0] fnRt;
input instruction_t ir;
begin
	case(ir.any.opcode)
	OP_R2A:
		case(ir.r2.func.r2a)
		FN_ADD:	fnRt = ir[10:6];
		FN_CMP:	fnRt = ir[10:6];
		FN_MUL:	fnRt = ir[10:6];
		FN_DIV:	fnRt = ir[10:6];
		FN_SUB:	fnRt = ir[10:6];
		FN_MULU: fnRt = ir[10:6];
		FN_DIVU:	fnRt = ir[10:6];
		default:	fnRt = 'd0;
		endcase
	OP_R2L:	fnRt = ir[10:6];
	OP_R2S:
		case(ir.r2.func.r2s)
		FN_SEQ:	fnRt = ir[10:6];
		FN_SNE:	fnRt = ir[10:6];
		FN_SLT:	fnRt = ir[10:6];
		FN_SLE:	fnRt = ir[10:6];
		FN_SLTU:	fnRt = ir[10:6];
		FN_SLEU:	fnRt = ir[10:6];
		default:	fnRt = 'd0;
		endcase
	OP_RETD:	fnRt = 5'd31;
	OP_ADDIS,
	OP_ADDI,OP_SUBFI,OP_CMPI,OP_MULI,OP_DIVI,OP_SLTI,
	OP_MULUI,OP_DIVUI,
	OP_ANDI,OP_ORI,OP_EORI:
		fnRt = ir[10:6];
	OP_LDB,OP_LDBU,OP_LDW,OP_LDWU,OP_LDT,
	OP_LDBX,OP_LDBUX,OP_LDWX,OP_LDWUX,OP_LDTX:
		fnRt = ir[10:6];
	OP_ADDIPC:
		fnRt = ir[10:6];
	default:
		fnRt = 'd0;
	endcase
end
endfunction

//
// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource1v;
input instruction_t ir;
begin
	case(ir.r2.opcode)
	OP_BRK:	fnSource1v = VAL;
	OP_R2A:
		case(ir.r2.func.r2a)
		FN_ADD:	fnSource1v = INV;
		FN_CMP:	fnSource1v = INV;
		FN_MUL:	fnSource1v = INV;
		FN_DIV:	fnSource1v = INV;
		FN_SUB:	fnSource1v = INV;
		FN_MULU: fnSource1v = INV;
		FN_DIVU:	fnSource1v = INV;
		default:	fnSource1v = VAL;
		endcase
	OP_R2L:		fnSource1v = INV;
	OP_R2S:
		case(ir.r2.func.r2s)
		FN_SEQ:	fnSource1v = INV;
		FN_SNE:	fnSource1v = INV;
		FN_SLT:	fnSource1v = INV;
		FN_SLE:	fnSource1v = INV;
		FN_SLTU:	fnSource1v = INV;
		FN_SLEU:	fnSource1v = INV;
		default:	fnSource1v = VAL;
		endcase
	OP_ADDI:	fnSource1v = INV;
	OP_CMPI:	fnSource1v = INV;
	OP_MULI:	fnSource1v = INV;
	OP_DIVI:	fnSource1v = INV;
	OP_ANDI:	fnSource1v = INV;
	OP_ORI:		fnSource1v = INV;
	OP_EORI:	fnSource1v = INV;
	OP_SLTI:	fnSource1v = INV;
	OP_BEQ:		fnSource1v = INV;
	OP_BNE:		fnSource1v = INV;
	OP_BLT:		fnSource1v = INV;
	OP_BLE:		fnSource1v = INV;
	OP_BLTU:	fnSource1v = INV;
	OP_BLEU:	fnSource1v = INV;
	OP_LBcc:	fnSource1v = INV;
	OP_XLBcc:	fnSource1v = INV;
	OP_LDB,OP_LDBU,OP_LDW,OP_LDWU,OP_LDT:
		fnSource1v = INV;
	OP_LDBX,OP_LDBUX,OP_LDWX,OP_LDWUX,OP_LDTX:
		fnSource1v = INV;
	OP_STB,OP_STW,OP_STT:
		fnSource1v = INV;
	OP_STBX,OP_STWX,OP_STTX:
		fnSource1v = INV;
	default:	fnSource1v = VAL;
	endcase
end
endfunction

function fnSource2v;
input instruction_t ir;
begin
	case(ir.r2.opcode)
	OP_BRK:	fnSource2v = VAL;
	OP_R2A:
		case(ir.r2.func.r2a)
		FN_ADD:	fnSource2v = INV;
		FN_CMP:	fnSource2v = INV;
		FN_MUL:	fnSource2v = INV;
		FN_DIV:	fnSource2v = INV;
		FN_SUB:	fnSource2v = INV;
		FN_MULU: fnSource2v = INV;
		FN_DIVU: fnSource2v = INV;
		default:	fnSource2v = VAL;
		endcase
	OP_R2L:	fnSource2v = INV;
	OP_R2S:
		case(ir.r2.func.r2s)
		FN_SEQ:	fnSource2v = INV;
		FN_SNE:	fnSource2v = INV;
		FN_SLT:	fnSource2v = INV;
		FN_SLE:	fnSource2v = INV;
		FN_SLTU:	fnSource2v = INV;
		FN_SLEU:	fnSource2v = INV;
		default:	fnSource2v = VAL;
		endcase
	OP_ADDI:	fnSource2v = VAL;
	OP_CMPI:	fnSource2v = VAL;
	OP_MULI:	fnSource2v = VAL;
	OP_DIVI:	fnSource2v = VAL;
	OP_ANDI:	fnSource2v = VAL;
	OP_ORI:		fnSource2v = VAL;
	OP_EORI:	fnSource2v = VAL;
	OP_SLTI:	fnSource2v = VAL;
	OP_BEQ:		fnSource2v = INV;
	OP_BNE:		fnSource2v = INV;
	OP_BLT:		fnSource2v = INV;
	OP_BLE:		fnSource2v = INV;
	OP_BLTU:	fnSource2v = INV;
	OP_BLEU:	fnSource2v = INV;
	OP_LBcc:	fnSource2v = INV;
	OP_XLBcc:	fnSource2v = INV;
	OP_LDB,OP_LDBU,OP_LDW,OP_LDWU,OP_LDT:
		fnSource2v = VAL;
	OP_LDBX,OP_LDBUX,OP_LDWX,OP_LDWUX,OP_LDTX:
		fnSource2v = INV;
	OP_STB,OP_STW,OP_STT:
		fnSource2v = VAL;
	OP_STBX,OP_STWX,OP_STTX:
		fnSource2v = INV;
	default:	fnSource2v = VAL;
	endcase
end
endfunction

function fnIsLoad;
input [18:0] op;
begin
	case(opcode_t'(op[5:0]))
	OP_LDB,OP_LDBU,OP_LDW,OP_LDWU,OP_LDT,
	OP_LDBX,OP_LDBUX,OP_LDWX,OP_LDWUX,OP_LDTX:
		fnIsLoad = 1'b1;
	default:
		fnIsLoad = 1'b1;
	endcase
end
endfunction

function fnIsStore;
input [18:0] op;
begin
	case(opcode_t'(op[5:0]))
	OP_STB,OP_STW,OP_STT,
	OP_STBX,OP_STWX,OP_STTX:
		fnIsStore = 1'b1;
	default:
		fnIsStore = 1'b0;
	endcase
end
endfunction

function [3:0] fnPostfixLen;
input [5:0] opcode;
begin
	case(opcode)
	OP_PFX8:	fnPostfixLen = 4'd2;
	OP_PFX16:	fnPostfixLen = 4'd3;
	OP_PFX24:	fnPostfixLen = 4'd4;
	OP_PFX32:	fnPostfixLen = 4'd5;
	default:	fnPostfixLen = 4'd0;
	endcase
end
endfunction								

function [33:0] fnPostfixImm;
input [39:0] postfix;
begin
	case(opcode_t'(postfix[5:0]))
	OP_PFX8:	fnPostfixImm = {{24{postfix[15]}},postfix[15:6]};
	OP_PFX16:	fnPostfixImm = {{16{postfix[23]}},postfix[23:6]};
	OP_PFX24:	fnPostfixImm = {{8{postfix[31]}},postfix[31:6]};
	OP_PFX32:	fnPostfixImm = postfix[39:6];
	default:	fnPostfixImm = 'd0;
	endcase
end
endfunction

function fnIsImm;
input [18:0] op;
begin
	fnIsImm = 1'b0;
	case(opcode_t'(op[5:0]))
	OP_ADDIS:	fnIsImm = 1'b1;
	OP_ADDI,OP_CMPI,OP_MULI,OP_DIVI,OP_SUBFI,
	OP_ANDI,OP_ORI,OP_EORI,OP_SLTI:
		fnIsImm = 1'b1;
	OP_RETD:
		fnIsImm = 1'b1;
	OP_LDB,OP_LDBU,OP_LDW,OP_LDWU,OP_LDT,OP_LDA,OP_CACHE,
	OP_STB,OP_STW,OP_STT:
		fnIsImm = 1'b1;
	OP_ADDIPC:
		fnIsImm = 1'b1;
	default:
		fnIsImm = 1'b0;	
	endcase
end
endfunction

function [33:0] fnImm;
input [79:0] ins;
begin
	fnImm = 'd3;
	case(opcode_t'(ins[5:0]))
	OP_ADDIS:	fnImm = {{27{ins[15]}},ins[15:11],2'b01};
	OP_ADDI,OP_CMPI,OP_MULI,OP_DIVI,OP_SUBFI,
	OP_ANDI,OP_ORI,OP_EORI,OP_SLTI:
		if (fnPostfixLen(ins[29:24]) != 4'd0)
			fnImm = fnPostfixImm(ins[63:24]);
		else
			fnImm = {{24{ins[23]}},ins[23:16],2'b01};
	OP_RETD:	fnImm = {{22{ins[15]}},ins[15: 6],2'b01};
	OP_LBcc:	
		if (fnPostfixLen(ins[37:32]) != 4'd0)
			fnImm = fnPostfixImm(ins[71:32]);
		else
			fnImm = 'd0;
	OP_XLBcc:
		if (fnPostfixLen(ins[37:32]) != 4'd0)
			fnImm = fnPostfixImm(ins[79:40]);
		else
			fnImm = 'd0;
	OP_LDB,OP_LDBU,OP_LDW,OP_LDWU,OP_LDT,OP_LDA,OP_CACHE,
	OP_STB,OP_STW,OP_STT:
		if (fnPostfixLen(ins[29:24]) != 4'd0)
			fnImm = fnPostfixImm(ins[63:24]);
		else
			fnImm = {{24{ins[23]}},ins[23:16],2'b01};
	OP_ADDIPC:
		if (fnPostfixLen(ins[29:24]) != 4'd0)
			fnImm = fnPostfixImm(ins[63:24]);
		else
			fnImm = {{24{ins[23]}},ins[23:16],2'b01};
	default:
		if (fnPostfixLen(ins[29:24]) != 4'd0)
			fnImm = fnPostfixImm(ins[63:24]);
		else
			fnImm = 'd0;
	endcase
end
endfunction

function [5:0] fnInsLen;
input [45:0] ins;
begin
	case(ins[5:0])
	OP_BRK:		fnInsLen = 6'd1;
	OP_NOP:		fnInsLen = 6'd1;
	OP_ADDIS:	fnInsLen = 6'd2;
	OP_RET:		fnInsLen = 6'd1;
	OP_RETD:	fnInsLen = 6'd2;
	OP_LCALL:	fnInsLen = 6'd4;
	OP_XLCALL:	fnInsLen = 6'd5;
	OP_PFX8:	fnInsLen = 6'd2;
	OP_PFX16:	fnInsLen = 6'd3;
	OP_PFX24:	fnInsLen = 6'd4;
	OP_PFX32:	fnInsLen = 6'd5;
	OP_LBcc:	fnInsLen = 6'd4 + fnPostfixLen(ins[37:32]);
	OP_XLBcc: fnInsLen = 6'd5 + fnPostfixLen(ins[45:40]);
	default:	fnInsLen = 6'd3 + fnPostfixLen(ins[29:24]);
	endcase
end
endfunction

endpackage
