
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

parameter NDATA_PORTS = 2;

typedef logic [11:0] asid_t;
typedef logic [31:0] address_t;
typedef logic [31:0] code_address_t;
typedef logic [31:0] virtual_address_t;
typedef logic [31:0] physical_address_t;
typedef logic [31:0] value_t;
typedef logic [63:0] double_value_t;
typedef logic [5:0] cause_t;

typedef struct packed {
	logic [4:0] num;
} regspec_t;

typedef enum logic [5:0] {
	OP_SYS = 6'd0,
	OP_APCIS = 6'd1,
	OP_R2 = 6'd2,
	OP_ADDIS = 6'd3,
	OP_ADDI = 6'd4,
	OP_CMPI = 6'd5,
	OP_MULI = 6'd6,
	OP_DIVI = 6'd7,
	OP_ANDI = 6'd8,
	OP_ORI = 6'd9,
	OP_EORI = 6'd10,
	OP_ANDIS = 6'd11,
	OP_SUBFI = 6'd12,
	OP_SLTI = 6'd13,
	OP_MULUI = 6'd14,
	OP_DIVUI = 6'd15,
	OP_ERET = 6'd16,
	OP_RETD = 6'd17,
	OP_CALL = 6'd18,
	OP_JAL = 6'd19,
	OP_ORIS = 6'd20,
	OP_EORIS = 6'd21,
	OP_BEQ = 6'd24,
	OP_BNE = 6'd25,
	OP_BLT = 6'd26,
	OP_BLE = 6'd27,
	OP_BLTU = 6'd28,
	OP_BLEU = 6'd29,
	OP_BccR = 6'd30,
	OP_BBS = 6'd31,
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
	OP_NOP = 6'd63
} opcode_t;

typedef enum logic [5:0] {
	FN_ADD = 6'd4,
	FN_CMP = 6'd5,
	FN_MUL = 6'd6,
	FN_DIV = 6'd7,
	FN_AND = 6'd8,
	FN_OR = 6'd9,
	FN_EOR = 6'd10,
	FN_ANDN = 6'd11,
	FN_SUB = 6'd12,
	FN_MULU = 6'd14,
	FN_DIVU = 6'd15,
	FN_NAND = 6'd16,
	FN_NOR = 6'd17,
	FN_ENOR = 6'd18,
	FN_ORN = 6'd19,
	FN_MULH = 6'd22,
	FN_MOD = 6'd23,
	FN_SEQ = 6'd24,
	FN_SNE = 6'd25,
	FN_SLT = 6'd26,
	FN_SLE = 6'd27,
	FN_SLTU = 6'd28,
	FN_SLEU = 6'd29,
	FN_MULUH = 6'd30,
	FN_MODU = 6'd31
} r2func_t;

typedef enum logic [5:0]
{
	FN_BRK = 6'd0,
	FN_IRQ = 6'd1,
	FN_SYS = 6'd2,
	FN_RTS = 6'd3,
	FN_RTI = 6'd4
} sys_func_t;

typedef enum logic [2:0]
{
	CND_EQ = 3'd0,
	CND_NE = 3'd1,
	CND_LT = 3'd2,
	CND_LE = 3'd3,
	CND_LTU = 3'd4,
	CND_LEU = 3'd5,
	CND_BS = 3'd7
} cond_t;

typedef enum logic [8:0]
{
	FLT_NONE = 9'd0,
	FLT_DBG = 9'd3
} fault_t;

typedef struct packed
{
	logic [15:0] imm;
	regspec_t Ra;
	regspec_t Rt;
	opcode_t opcode;
} riinst;

typedef struct packed
{
	r2func_t func;
	logic [4:0] resv;
	regspec_t Rb;
	regspec_t Ra;
	regspec_t Rt;
	opcode_t opcode;
} r2inst;

typedef struct packed
{
	sys_func_t func;
	logic [19:0] payload;
	opcode_t opcode;
} sysinst;

typedef struct packed
{
	logic [15:0] disp1500;
	regspec_t Rb;
	regspec_t Ra;
	opcode_t opcode;
} brinst;

typedef struct packed
{
	logic [7:0] disp0700;
	cond_t cnd;
	regspec_t Rc;
	regspec_t Rb;
	regspec_t Ra;
	opcode_t opcode;
} bccrinst;

typedef struct packed
{
	logic [25:0] payload;
	opcode_t opcode;
} anyinst;

typedef union packed
{
	sysinst sys;
	bccrinst lbr;
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
	logic fc;
	logic alu;
	logic div;
	logic divu;
	logic load;
	logic store;
	logic mem;
	logic sync;
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
	value_t a3;
	logic a3_v;
	logic [4:0] a3_s;
	address_t pc;
} iq_entry_t;

function fnIsBccR;
input instruction_t ir;
begin
	fnIsBccR = ir.any.opcode==OP_BccR;
end
endfunction

function fnIsBranch;
input instruction_t ir;
begin
	case(ir.any.opcode)
	OP_BEQ,OP_BNE,OP_BLT,OP_BLE,OP_BLTU,OP_BLEU,OP_BBS:
		fnIsBranch = 1'b1;
	OP_BccR:	fnIsBranch = 1'b1;
	default:
		fnIsBranch = 1'b0;
	endcase
end
endfunction

function fnBranchDispSign;
input instruction_t ir;
begin
	case(ir.any.opcode)
	OP_BEQ,OP_BNE,OP_BLT,OP_BLE,OP_BLTU,OP_BLEU,OP_BBS:
		fnBranchDispSign = ir[31];
	OP_BccR:	fnBranchDispSign = ir[31];
	default:	fnBranchDispSign = 1'b0;
	endcase	
end
endfunction

function [31:0] fnBranchDisp;
input instruction_t ir;
begin
	case(ir.any.opcode)
	OP_BEQ,OP_BNE,OP_BLT,OP_BLE,OP_BLTU,OP_BLEU,OP_BBS:
		fnBranchDisp = {{16{ir[31]}},ir[31:16]};
	OP_BccR:	fnBranchDisp = {{24{ir[31]}},ir[31:24]};
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
	fnIsCall = ir.any.opcode==OP_CALL;
end
endfunction

function fnIsFlowCtrl;
input instruction_t ir;
begin
	fnIsFlowCtrl = 1'b0;
	case(ir.any.opcode)
	OP_SYS:	fnIsFlowCtrl = 1'b1;
	OP_CALL,OP_JAL:
		fnIsFlowCtrl = 1'b1;
	OP_BEQ,OP_BNE,OP_BLT,OP_BLE,OP_BLTU,OP_BLEU,OP_BBS:
		fnIsFlowCtrl = 1'b1;	
	OP_BccR:
		fnIsFlowCtrl = 1'b1;	
	OP_RETD,OP_ERET:
		fnIsFlowCtrl = 1'b1;	
	default:
		fnIsFlowCtrl = 1'b0;
	endcase
end
endfunction

function fnIsRet;
input instruction_t ir;
begin
	fnIsRet = 1'b0;
	case(ir.any.opcode)
	OP_RETD:
		fnIsRet = 1'b1;	
	default:
		fnIsRet = 1'b0;
	endcase
end
endfunction

function [4:0] fnRa;
input instruction_t ir;
begin
	case(ir.any.opcode)
	OP_BEQ,OP_BNE,OP_BLT,OP_BLE,OP_BLTU,OP_BLEU:
		fnRa = ir[10:6];
	OP_BccR:
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
	OP_BccR:
		fnRb = ir[15:11];
	default:
		fnRb = ir[20:16];
	endcase
end
endfunction

function [4:0] fnRc;
input instruction_t ir;
begin
	case(ir.any.opcode)
	OP_BccR:
		fnRc = ir[20:16];
	OP_RETD:
		fnRc = {3'd0,ir[7:6]};
	OP_STB,OP_STW,OP_STT,OP_STBX,OP_STWX,OP_STTX:
		fnRc = ir[10:6];
	default:
		fnRc = 'd0;
	endcase
end
endfunction

function [4:0] fnRt;
input instruction_t ir;
begin
	case(ir.any.opcode)
	OP_R2:
		case(ir.r2.func)
		FN_ADD:	fnRt = ir[10:6];
		FN_CMP:	fnRt = ir[10:6];
		FN_MUL:	fnRt = ir[10:6];
		FN_DIV:	fnRt = ir[10:6];
		FN_SUB:	fnRt = ir[10:6];
		FN_MULU: fnRt = ir[10:6];
		FN_DIVU:	fnRt = ir[10:6];
		FN_MULH:	fnRt = ir[10:6];
		FN_MOD:	fnRt = ir[10:6];
		FN_MULUH:	fnRt = ir[10:6];
		FN_MODU:	fnRt = ir[10:6];
		FN_AND:	fnRt = ir[10:6];
		FN_OR:	fnRt = ir[10:6];
		FN_EOR:	fnRt = ir[10:6];
		FN_ANDN:	fnRt = ir[10:6];
		FN_NAND:	fnRt = ir[10:6];
		FN_NOR:	fnRt = ir[10:6];
		FN_ENOR:	fnRt = ir[10:6];
		FN_ORN:	fnRt = ir[10:6];
		FN_SEQ:	fnRt = ir[10:6];
		FN_SNE:	fnRt = ir[10:6];
		FN_SLT:	fnRt = ir[10:6];
		FN_SLE:	fnRt = ir[10:6];
		FN_SLTU:	fnRt = ir[10:6];
		FN_SLEU:	fnRt = ir[10:6];
		default:	fnRt = 'd0;
		endcase
	OP_CALL:	fnRt = {3'b0,ir[7:6]};
	OP_RETD:	fnRt = 5'd31;
	OP_JAL,
	OP_ADDIS,OP_ANDIS,OP_ORIS,OP_EORIS,
	OP_ADDI,OP_SUBFI,OP_CMPI,OP_MULI,OP_DIVI,OP_SLTI,
	OP_MULUI,OP_DIVUI,
	OP_ANDI,OP_ORI,OP_EORI:
		fnRt = ir[10:6];
	OP_LDB,OP_LDBU,OP_LDW,OP_LDWU,OP_LDT,
	OP_LDBX,OP_LDBUX,OP_LDWX,OP_LDWUX,OP_LDTX:
		fnRt = ir[10:6];
	OP_APCIS:
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
	OP_SYS:	fnSource1v = VAL;
	OP_R2:
		case(ir.r2.func)
		FN_ADD:	fnSource1v = ir[15:11]=='d0;
		FN_CMP:	fnSource1v = ir[15:11]=='d0;
		FN_MUL:	fnSource1v = ir[15:11]=='d0;
		FN_DIV:	fnSource1v = ir[15:11]=='d0;
		FN_SUB:	fnSource1v = ir[15:11]=='d0;
		FN_MULU: fnSource1v = ir[15:11]=='d0;
		FN_DIVU:	fnSource1v = ir[15:11]=='d0;
		FN_AND:	fnSource1v = ir[15:11]=='d0;
		FN_OR:	fnSource1v = ir[15:11]=='d0;
		FN_EOR:	fnSource1v = ir[15:11]=='d0;
		FN_ANDN:	fnSource1v = ir[15:11]=='d0;
		FN_NAND:	fnSource1v = ir[15:11]=='d0;
		FN_NOR:	fnSource1v = ir[15:11]=='d0;
		FN_ENOR:	fnSource1v = ir[15:11]=='d0;
		FN_ORN:	fnSource1v = ir[15:11]=='d0;
		FN_SEQ:	fnSource1v = ir[15:11]=='d0;
		FN_SNE:	fnSource1v = ir[15:11]=='d0;
		FN_SLT:	fnSource1v = ir[15:11]=='d0;
		FN_SLE:	fnSource1v = ir[15:11]=='d0;
		FN_SLTU:	fnSource1v = ir[15:11]=='d0;
		FN_SLEU:	fnSource1v = ir[15:11]=='d0;
		default:	fnSource1v = VAL;
		endcase
	OP_JAL,
	OP_ADDI:	fnSource1v = ir[15:11]=='d0;
	OP_ADDIS:	fnSource1v = ir[15:11]=='d0;
	OP_CMPI:	fnSource1v = ir[15:11]=='d0;
	OP_MULI:	fnSource1v = ir[15:11]=='d0;
	OP_DIVI:	fnSource1v = ir[15:11]=='d0;
	OP_ANDI:	fnSource1v = ir[15:11]=='d0;
	OP_ORI:		fnSource1v = ir[15:11]=='d0;
	OP_EORI:	fnSource1v = ir[15:11]=='d0;
	OP_ANDIS:	fnSource1v = ir[15:11]=='d0;
	OP_ORIS:	fnSource1v = ir[15:11]=='d0;
	OP_EORIS:	fnSource1v = ir[15:11]=='d0;
	OP_SLTI:	fnSource1v = ir[15:11]=='d0;
	OP_BEQ:		fnSource1v = ir[10:6]=='d0;
	OP_BNE:		fnSource1v = ir[10:6]=='d0;
	OP_BLT:		fnSource1v = ir[10:6]=='d0;
	OP_BLE:		fnSource1v = ir[10:6]=='d0;
	OP_BLTU:	fnSource1v = ir[10:6]=='d0;
	OP_BLEU:	fnSource1v = ir[10:6]=='d0;
	OP_BccR:	fnSource1v = ir[10:6]=='d0;
	OP_LDB,OP_LDBU,OP_LDW,OP_LDWU,OP_LDT:
		fnSource1v = ir[15:11]=='d0;
	OP_LDBX,OP_LDBUX,OP_LDWX,OP_LDWUX,OP_LDTX:
		fnSource1v = ir[15:11]=='d0;
	OP_STB,OP_STW,OP_STT:
		fnSource1v = ir[15:11]=='d0;
	OP_STBX,OP_STWX,OP_STTX:
		fnSource1v = ir[15:11]=='d0;
	default:	fnSource1v = VAL;
	endcase
end
endfunction

function fnSource2v;
input instruction_t ir;
begin
	case(ir.r2.opcode)
	OP_SYS:	fnSource2v = VAL;
	OP_R2:
		case(ir.r2.func)
		FN_ADD:	fnSource2v = ir[20:16]=='d0;
		FN_CMP:	fnSource2v = ir[20:16]=='d0;
		FN_MUL:	fnSource2v = ir[20:16]=='d0;
		FN_DIV:	fnSource2v = ir[20:16]=='d0;
		FN_SUB:	fnSource2v = ir[20:16]=='d0;
		FN_MULU: fnSource2v = ir[20:16]=='d0;
		FN_DIVU: fnSource2v = ir[20:16]=='d0;
		FN_AND:	fnSource2v = ir[20:16]=='d0;
		FN_OR:	fnSource2v = ir[20:16]=='d0;
		FN_EOR:	fnSource2v = ir[20:16]=='d0;
		FN_ANDN:	fnSource2v = ir[20:16]=='d0;
		FN_NAND:	fnSource2v = ir[20:16]=='d0;
		FN_NOR:	fnSource2v = ir[20:16]=='d0;
		FN_ENOR:	fnSource2v = ir[20:16]=='d0;
		FN_ORN:	fnSource2v = ir[20:16]=='d0;
		FN_SEQ:	fnSource2v = ir[20:16]=='d0;
		FN_SNE:	fnSource2v = ir[20:16]=='d0;
		FN_SLT:	fnSource2v = ir[20:16]=='d0;
		FN_SLE:	fnSource2v = ir[20:16]=='d0;
		FN_SLTU:	fnSource2v = ir[20:16]=='d0;
		FN_SLEU:	fnSource2v = ir[20:16]=='d0;
		default:	fnSource2v = VAL;
		endcase
	OP_JAL,
	OP_ADDI:	fnSource2v = VAL;
	OP_ADDIS:	fnSource2v = VAL;
	OP_CMPI:	fnSource2v = VAL;
	OP_MULI:	fnSource2v = VAL;
	OP_DIVI:	fnSource2v = VAL;
	OP_ANDI:	fnSource2v = VAL;
	OP_ORI:		fnSource2v = VAL;
	OP_EORI:	fnSource2v = VAL;
	OP_ANDIS:	fnSource2v = VAL;
	OP_ORIS:	fnSource2v = VAL;
	OP_EORIS:	fnSource2v = VAL;
	OP_SLTI:	fnSource2v = VAL;
	OP_BEQ:		fnSource2v = ir[15:11]=='d0;
	OP_BNE:		fnSource2v = ir[15:11]=='d0;
	OP_BLT:		fnSource2v = ir[15:11]=='d0;
	OP_BLE:		fnSource2v = ir[15:11]=='d0;
	OP_BLTU:	fnSource2v = ir[15:11]=='d0;
	OP_BLEU:	fnSource2v = ir[15:11]=='d0;
	OP_BccR:	fnSource2v = ir[15:11]=='d0;
	OP_LDB,OP_LDBU,OP_LDW,OP_LDWU,OP_LDT:
		fnSource2v = VAL;
	OP_LDBX,OP_LDBUX,OP_LDWX,OP_LDWUX,OP_LDTX:
		fnSource2v = ir[20:16]=='d0;
	OP_STB,OP_STW,OP_STT:
		fnSource2v = VAL;
	OP_STBX,OP_STWX,OP_STTX:
		fnSource2v = INV;
	default:	fnSource2v = VAL;
	endcase
end
endfunction

function fnSource3v;
input instruction_t ir;
begin
	case(ir.r2.opcode)
	OP_STB,OP_STW,OP_STT,OP_STBX,OP_STWX,OP_STTX:
		fnSource3v = ir[10:6]=='d0;
	OP_BccR:
		fnSource3v = ir[20:16]=='d0;
	OP_RETD:
		fnSource3v = ir[7:6]=='d0;
	default:
		fnSource3v = VAL;
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

function fnIsMem;
input instruction_t ir;
begin
	fnIsMem = fnIsLoad(ir) || fnIsStore(ir);
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
	OP_ADDIS,OP_ANDIS,OP_ORIS,OP_EORIS:
		fnIsImm = 1'b1;
	OP_ADDI,OP_CMPI,OP_MULI,OP_DIVI,OP_SUBFI,
	OP_ANDI,OP_ORI,OP_EORI,OP_SLTI:
		fnIsImm = 1'b1;
	OP_RETD:
		fnIsImm = 1'b1;
	OP_LDB,OP_LDBU,OP_LDW,OP_LDWU,OP_LDT,OP_LDA,OP_CACHE,
	OP_STB,OP_STW,OP_STT:
		fnIsImm = 1'b1;
	OP_APCIS:
		fnIsImm = 1'b1;
	default:
		fnIsImm = 1'b0;	
	endcase
end
endfunction

function [31:0] fnImm;
input instruction_t ins;
begin
	fnImm = 'd0;
	case(opcode_t'(ins[5:0]))
	OP_ADDIS:	fnImm = {ins[31:16],16'h00};
	OP_ANDIS: fnImm = {ins[31:16],16'hFFFF};
	OP_ORIS,OP_EORIS:
		fnImm = {ins[31:16],16'h0000};
	OP_ADDI,OP_CMPI,OP_MULI,OP_DIVI,OP_SUBFI,OP_SLTI:
		fnImm = {{16{ins[31]}},ins[31:16]};
	OP_ANDI:	fnImm = {16'hFFFF,ins[31:16]};
	OP_ORI,OP_EORI:
		fnImm = {16'h0000,ins[31:16]};
	OP_RETD:	fnImm = {{16{ins[31]}},ins[31:16]};
	OP_LDB,OP_LDBU,OP_LDW,OP_LDWU,OP_LDT,OP_LDA,OP_CACHE,
	OP_STB,OP_STW,OP_STT:
			fnImm = {{16{ins[31]}},ins[31:16]};
	OP_APCIS:
		fnImm = {ins[31:16],16'h0000};
	default:
		fnImm = 'd0;
	endcase
end
endfunction

function [5:0] fnInsLen;
input [45:0] ins;
begin
	fnInsLen = 6'd4;
end
endfunction

function fnIsDivs;
input instruction_t ir;
begin
	fnIsDivs = ir.any.opcode==OP_DIVI ||
		(ir.any.opcode==OP_R2 && (ir.r2.func==FN_DIV || ir.r2.func==FN_MOD))
		;
end
endfunction

function fnIsDivu;
input instruction_t ir;
begin
	fnIsDivu = ir.any.opcode==OP_DIVUI ||
		(ir.any.opcode==OP_R2 && (ir.r2.func==FN_DIVU || ir.r2.func==FN_MODU))
		;
end
endfunction

function fnIsDiv;
input instruction_t ir;
begin
	fnIsDiv = fnIsDivs(ir) || fnIsDivu(ir);
end
endfunction

function fnIsIrq;
input instruction_t ir;
begin
	fnIsIrq = ir.any.opcode==OP_SYS && ir.sys.func==FN_IRQ;
end
endfunction

function [31:0] fnDati;
input instruction_t ins;
input address_t adr;
input value_t dat;
case(ins.any.opcode)
OP_LDB,OP_LDBX:
  case(adr[1:0])
  2'd0:   fnDati = {{24{dat[7]}},dat[7:0]};
  2'd1:   fnDati = {{24{dat[15]}},dat[15:8]};
  2'd2:   fnDati = {{24{dat[23]}},dat[23:16]};
  2'd3:   fnDati = {{24{dat[31]}},dat[31:24]};
  endcase
OP_LDBU,OP_LDBUX:
  case(adr[1:0])
  2'd0:   fnDati = {{24{1'b0}},dat[7:0]};
  2'd1:   fnDati = {{24{1'b0}},dat[15:8]};
  2'd2:   fnDati = {{24{1'b0}},dat[23:16]};
  2'd3:   fnDati = {{24{1'b0}},dat[31:24]};
  endcase
OP_LDW,OP_LDWX:
  case(adr[1])
  1'd0:   fnDati = {{16{dat[15]}},dat[15:0]};
  1'd1:   fnDati = {{16{dat[31]}},dat[31:16]};
  endcase
OP_LDWU,OP_LDWUX:
  case(adr[1])
  1'd0:   fnDati = {{16{1'b0}},dat[15:0]};
  1'd1:   fnDati = {{16{1'b0}},dat[31:16]};
  endcase
OP_LDT,OP_LDTX:
  fnDati = dat;
default:    fnDati = dat;
endcase
endfunction


endpackage
