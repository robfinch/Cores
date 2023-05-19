
package rfx32pkg;

`define INV	1'b0
`define VAL	1'b1
`define PANIC_INVALIDFBSTATE	4'd1
`define PANIC_BRANCHBACK 4'd2
`define PANIC_INVALIDIQSTATE 4'd3
`define BACK_BRANCH	1'b1

typedef logic [31:0] address_t;
typedef logic [31:0] value_t;
typedef logic [5:0] cause_t;

typedef struct packed {
	logic neg;
	logic [3:0] num;
} regspec_t;

typedef enum logic [4:0] {
	OP_BRK = 5'd0,
	OP_LUI = 5'd1,
	OP_R2 = 5'd2,
	OP_AUIPC = 5'd3,
	OP_ADDI = 5'd4,
	OP_CMPI = 5'd5,
	OP_MULI = 5'd6,
	OP_DIVI = 5'd7,
	OP_ANDI = 5'd8,
	OP_ORI = 5'd9,
	OP_EORI = 5'd10,
	OP_Bcc = 5'd11,
	OP_JAL = 5'd12,
	OP_LOAD = 5'd16,
	OP_STORE = 5'd18
} opcode_t;

typedef enum logic [2:0]
{
	CND_EQ,
	CND_NE,
	CND_LT,
	CND_LE,
	CND_LTU,
	CND_LEU
} cond_t;

typedef enum logic [2:0] 
{
	FMT_SSS = 3'd0,
	FMT_SSSM = 3'd1,
	FMT_SVV = 3'd2,
	FMT_SVVM = 3'd3,
	FMT_VVV = 3'd4,
	FMT_VVVM = 3'd5
} format_t;

typedef struct packed
{
	logic [13:0] imm;
	regspec_t Ra;
	format_t fmt;
	regspec_t Rt;
	opcode_t opcode;
} riinst;

typedef struct packed
{
	logic [13:0] imm;
	regspec_t Ra;
	format_t fmt;
	regspec_t Rt;
	opcode_t opcode;
} r2inst;

typedef struct packed
{
	logic [14:0] disp1703;
	logic [3:0] Rb;
	cond_t cnd;
	logic disp2;
	logic [3:0] Ra;
	opcode_t opcode;
} brinst;

typedef union packed
{
	brinst br;
	r2inst r2;
	riinst ri;
} instruction_t;

typedef struct packed {
	logic v;
	logic out;
	logic done;
	logic bt;
	logic agen;
	logic mem;
	logic jmp;
	logic rfw;
	value_t res;
	opcode_t op;
	cause_t exc;
	regspec_t tgt;
	value_t a0;
	value_t a1;
	logic a1_v;
	logic [4:0] a1_s;
	value_t a2;
	logic a2_v;
	logic [4:0] a2_s;
	address_t pc;
} iq_entry_t;

endpackage
