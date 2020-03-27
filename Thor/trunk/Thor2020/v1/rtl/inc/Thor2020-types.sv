`ifndef TYPES_SV
`define TYPES_SV	1'b1

typedef logic [`AMSB:0] tAddress;

typedef struct packed {
	logic [40:0] raw;
} tRawInstruction;

typedef struct packed {
	logic [25:0] payload;
	logic [6:0] opcode;
	logic [3:0] pr;
	logic [2:0] pc;
	logic rc;
} tGenInstruction;

typedef struct packed {
	logic [19:0] target;
	logic [2:0] Ca;
	logic [2:0] Ct;
	logic [6:0] opcode;
	logic [3:0] pr;
	logic [2:0] pc;
	logic rc;
} tJmpInstruction;

typedef struct packed {
  logic [6:0] funct;
	logic pad1;
	logic [11:0] imm;
	logic [2:0] Ls;
	logic [2:0] Ca;
	logic [2:0] pad3;
	logic [6:0] opcode;
	logic [3:0] pr;
	logic [2:0] pc;
	logic rc;
} tRtsInstruction;

typedef union packed {
	tRawInstruction raw;
	tGenInstruction gen;
	tJmpInstruction jmp;
	tRtsInstruction rts;
} tInstruction;

`endif
