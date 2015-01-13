`define BRK		6'd0
`define NOP		6'd59

`define INV	1'b0
`define VAL	1'b1

`define INSTRUCTION_RA		11:6
`define INSTRUCTION_RB		17:12
`define INSTRUCTION_RC		23:18

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

module FISA64ss(rst_i, clk_i, nmi_i, irq_i, vec_i, bte_o, cti_o, bl_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

input rst_i;
input clk_i;
input nmi_i;
input irq_i;
input [8:0] vec_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [5:0] bl_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

reg [128:0] message [0:15];

wire clk = clk_i;
reg [31:0] pc;
wire [127:0] bundle;
wire [39:0] insn0a = bundle[39: 0];
wire [39:0] insn1a = bundle[79:40];
wire [39:0] insn2a = bundle[119:80];
reg [39:0] insn0,insn1,insn2;
reg isICacheLoad;
reg isICacheReset;
wire ihit;
wire do_pcinc = ihit;
wire branchmiss = FALSE;
wire [31:0] misspc = 32'h0;
wire take_branch = FALSE;
wire did_branchback0 = FALSE;
wire did_branchback1 = FALSE;
reg StatusHWI;
reg nmi_edge;
reg im;
wire ld_fetchbuf = ihit || (nmi_edge & !StatusHWI)||(irq_i & ~im & !StatusHWI);

wire [5:0] Ra0;
wire [5:0] Rb0;
wire [5:0] Rc0;
wire [5:0] Ra1;
wire [5:0] Rb1;
wire [5:0] Rc1;
wire [5:0] Ra2;
wire [5:0] Rb2;
wire [5:0] Rc2;
wire [63:0] rfoa0,rfoa1,rfoa2;
wire [63:0] rfob0,rfob1,rfob2;
wire [63:0] rfoc0,rfoc1,rfoc2;

reg fetchbuf;
reg fetchbufA_v;
reg fetchbufB_v;
reg fetchbufC_v;
reg fetchbufD_v;
reg fetchbufE_v;
reg fetchbufF_v;
reg [39:0] fetchbufA_instr;
reg [39:0] fetchbufB_instr;
reg [39:0] fetchbufC_instr;
reg [39:0] fetchbufD_instr;
reg [39:0] fetchbufE_instr;
reg [39:0] fetchbufF_instr;
reg [31:0] fetchbufA_pc;
reg [31:0] fetchbufB_pc;
reg [31:0] fetchbufC_pc;
reg [31:0] fetchbufD_pc;
reg [31:0] fetchbufE_pc;
reg [31:0] fetchbufF_pc;

reg [39:0] fetchbuf0_instr;
reg [31:0] fetchbuf0_pc;
reg fetchbuf0_v;
reg [39:0] fetchbuf1_instr;
reg [31:0] fetchbuf1_pc;
reg fetchbuf1_v;
reg [39:0] fetchbuf2_instr;
reg [31:0] fetchbuf2_pc;
reg fetchbuf2_v;

reg [15:0] iqentry_v;			// entry valid?  -- this should be the first bit
reg [15:0] iqentry_out;			// instruction has been issued to an ALU ...
reg [15:0] iqentry_done;		// instruction result valid
reg [63:0] iqentry_res [15:0];
reg [15:0] iqentry_rfw;			// writes to register file
reg [5:0]  iqentry_op [15:0];	// opcode
reg [5:0]  iqentry_fn [15:0];	// function
reg [6:0]  iqentry_tgt [15:0];	// target register, if any
reg [63:0] iqentry_a [15:0];	// argument 'a'
reg [15:0] iqentry_av;			// argument 'a' valid
reg [4:0]  iqentry_as [15:0];	// argument 'a' source (iq entry # with top bit representing ALU/DRAM bus)
reg [63:0] iqentry_b [15:0];
reg [15:0] iqentry_bv;			// argument 'b' valid
reg [4:0]  iqentry_bs [15:0];	// argument 'b' source (iq entry # with top bit representing ALU/DRAM bus)
reg [63:0] iqentry_c [15:0];
reg [15:0] iqentry_cv;			// argument 'c' valid
reg [4:0]  iqentry_cs [15:0];	// argument 'c' source (iq entry # with top bit representing ALU/DRAM bus)
reg [63:0] iqentry_imm [15:0];	// immediate value
reg [31:0] iqentry_pc [15:0];

wire [15:0] iqentry_source;
wire [15:0] iqentry_imm;
wire [15:0] iqentry_memready;
wire [15:0] iqentry_memopsvalid;

wire stomp_all;
//reg  [7:0] iqentry_fpissue;
reg  [15:0] iqentry_memissue;
reg [15:0] iqentry_stissue;
reg [15:0] iqentry_ldissue;
wire [15:0] iqentry_stomp;
reg  [15:0] iqentry_issue;
wire [2:0] iqentry_0_islot;
wire [2:0] iqentry_1_islot;
wire [2:0] iqentry_2_islot;
wire [2:0] iqentry_3_islot;
wire [2:0] iqentry_4_islot;
wire [2:0] iqentry_5_islot;
wire [2:0] iqentry_6_islot;
wire [2:0] iqentry_7_islot;
wire [2:0] iqentry_8_islot;
wire [2:0] iqentry_9_islot;
wire [2:0] iqentry_10_islot;
wire [2:0] iqentry_11_islot;
wire [2:0] iqentry_12_islot;
wire [2:0] iqentry_13_islot;
wire [2:0] iqentry_14_islot;
wire [2:0] iqentry_15_islot;
reg  [2:0] iqentry_islot[0:15];
reg  [1:0] iqentry_fpislot[0:15];

wire  [NREGS:1] livetarget;
wire  [NREGS:1] iqentry_0_livetarget;
wire  [NREGS:1] iqentry_1_livetarget;
wire  [NREGS:1] iqentry_2_livetarget;
wire  [NREGS:1] iqentry_3_livetarget;
wire  [NREGS:1] iqentry_4_livetarget;
wire  [NREGS:1] iqentry_5_livetarget;
wire  [NREGS:1] iqentry_6_livetarget;
wire  [NREGS:1] iqentry_7_livetarget;
wire  [NREGS:1] iqentry_8_livetarget;
wire  [NREGS:1] iqentry_9_livetarget;
wire  [NREGS:1] iqentry_10_livetarget;
wire  [NREGS:1] iqentry_11_livetarget;
wire  [NREGS:1] iqentry_12_livetarget;
wire  [NREGS:1] iqentry_13_livetarget;
wire  [NREGS:1] iqentry_14_livetarget;
wire  [NREGS:1] iqentry_15_livetarget;
wire  [NREGS:1] iqentry_0_latestID;
wire  [NREGS:1] iqentry_1_latestID;
wire  [NREGS:1] iqentry_2_latestID;
wire  [NREGS:1] iqentry_3_latestID;
wire  [NREGS:1] iqentry_4_latestID;
wire  [NREGS:1] iqentry_5_latestID;
wire  [NREGS:1] iqentry_6_latestID;
wire  [NREGS:1] iqentry_7_latestID;
wire  [NREGS:1] iqentry_8_latestID;
wire  [NREGS:1] iqentry_9_latestID;
wire  [NREGS:1] iqentry_10_latestID;
wire  [NREGS:1] iqentry_11_latestID;
wire  [NREGS:1] iqentry_12_latestID;
wire  [NREGS:1] iqentry_13_latestID;
wire  [NREGS:1] iqentry_14_latestID;
wire  [NREGS:1] iqentry_15_latestID;
wire  [NREGS:1] iqentry_0_cumulative;
wire  [NREGS:1] iqentry_1_cumulative;
wire  [NREGS:1] iqentry_2_cumulative;
wire  [NREGS:1] iqentry_3_cumulative;
wire  [NREGS:1] iqentry_4_cumulative;
wire  [NREGS:1] iqentry_5_cumulative;
wire  [NREGS:1] iqentry_6_cumulative;
wire  [NREGS:1] iqentry_7_cumulative;
wire  [NREGS:1] iqentry_8_cumulative;
wire  [NREGS:1] iqentry_9_cumulative;
wire  [NREGS:1] iqentry_10_cumulative;
wire  [NREGS:1] iqentry_11_cumulative;
wire  [NREGS:1] iqentry_12_cumulative;
wire  [NREGS:1] iqentry_13_cumulative;
wire  [NREGS:1] iqentry_14_cumulative;
wire  [NREGS:1] iqentry_15_cumulative;

wire [NREGS:1] iq0_out;
wire [NREGS:1] iq1_out;
wire [NREGS:1] iq2_out;
wire [NREGS:1] iq3_out;
wire [NREGS:1] iq4_out;
wire [NREGS:1] iq5_out;
wire [NREGS:1] iq6_out;
wire [NREGS:1] iq7_out;
wire [NREGS:1] iq8_out;
wire [NREGS:1] iq9_out;
wire [NREGS:1] iq10_out;
wire [NREGS:1] iq11_out;
wire [NREGS:1] iq12_out;
wire [NREGS:1] iq13_out;
wire [NREGS:1] iq14_out;
wire [NREGS:1] iq15_out;

//
// BRANCH-MISS LOGIC: livetarget
//
// livetarget implies that there is a not-to-be-stomped instruction that targets the register in question
// therefore, if it is zero it implies the rf_v value should become VALID on a branchmiss
// 

reg [NREGS:1] livetarget;

decoder7 iq0(.num(iqentry_tgt[0]), .out(iq0_out));
decoder7 iq1(.num(iqentry_tgt[1]), .out(iq1_out));
decoder7 iq2(.num(iqentry_tgt[2]), .out(iq2_out));
decoder7 iq3(.num(iqentry_tgt[3]), .out(iq3_out));
decoder7 iq4(.num(iqentry_tgt[4]), .out(iq4_out));
decoder7 iq5(.num(iqentry_tgt[5]), .out(iq5_out));
decoder7 iq6(.num(iqentry_tgt[6]), .out(iq6_out));
decoder7 iq7(.num(iqentry_tgt[7]), .out(iq7_out));
decoder7 iq8(.num(iqentry_tgt[8]), .out(iq8_out));
decoder7 iq9(.num(iqentry_tgt[9]), .out(iq9_out));
decoder7 iq10(.num(iqentry_tgt[10]), .out(iq10_out));
decoder7 iq11(.num(iqentry_tgt[11]), .out(iq11_out));
decoder7 iq12(.num(iqentry_tgt[12]), .out(iq12_out));
decoder7 iq13(.num(iqentry_tgt[13]), .out(iq13_out));
decoder7 iq14(.num(iqentry_tgt[14]), .out(iq14_out));
decoder7 iq15(.num(iqentry_tgt[15]), .out(iq15_out));

assign 
	iqentry_0_livetarget = {NREGS{iqentry_v[0]}} & {NREGS{~iqentry_stomp[0]}} & {NREGS{iqentry_cmt[0]}} & iq0_out,
	iqentry_1_livetarget = {NREGS{iqentry_v[1]}} & {NREGS{~iqentry_stomp[1]}} & {NREGS{iqentry_cmt[1]}} & iq1_out,
	iqentry_2_livetarget = {NREGS{iqentry_v[2]}} & {NREGS{~iqentry_stomp[2]}} & {NREGS{iqentry_cmt[2]}} & iq2_out,
	iqentry_3_livetarget = {NREGS{iqentry_v[3]}} & {NREGS{~iqentry_stomp[3]}} & {NREGS{iqentry_cmt[3]}} & iq3_out,
	iqentry_4_livetarget = {NREGS{iqentry_v[4]}} & {NREGS{~iqentry_stomp[4]}} & {NREGS{iqentry_cmt[4]}} & iq4_out,
	iqentry_5_livetarget = {NREGS{iqentry_v[5]}} & {NREGS{~iqentry_stomp[5]}} & {NREGS{iqentry_cmt[5]}} & iq5_out,
	iqentry_6_livetarget = {NREGS{iqentry_v[6]}} & {NREGS{~iqentry_stomp[6]}} & {NREGS{iqentry_cmt[6]}} & iq6_out,
	iqentry_7_livetarget = {NREGS{iqentry_v[7]}} & {NREGS{~iqentry_stomp[7]}} & {NREGS{iqentry_cmt[7]}} & iq7_out,
	iqentry_8_livetarget = {NREGS{iqentry_v[8]}} & {NREGS{~iqentry_stomp[8]}} & {NREGS{iqentry_cmt[8]}} & iq8_out,
	iqentry_9_livetarget = {NREGS{iqentry_v[9]}} & {NREGS{~iqentry_stomp[9]}} & {NREGS{iqentry_cmt[9]}} & iq9_out,
	iqentry_10_livetarget = {NREGS{iqentry_v[10]}} & {NREGS{~iqentry_stomp[10]}} & {NREGS{iqentry_cmt[10]}} & iq10_out,
	iqentry_11_livetarget = {NREGS{iqentry_v[11]}} & {NREGS{~iqentry_stomp[11]}} & {NREGS{iqentry_cmt[11]}} & iq11_out,
	iqentry_12_livetarget = {NREGS{iqentry_v[12]}} & {NREGS{~iqentry_stomp[12]}} & {NREGS{iqentry_cmt[12]}} & iq12_out,
	iqentry_13_livetarget = {NREGS{iqentry_v[13]}} & {NREGS{~iqentry_stomp[13]}} & {NREGS{iqentry_cmt[13]}} & iq13_out,
	iqentry_14_livetarget = {NREGS{iqentry_v[14]}} & {NREGS{~iqentry_stomp[14]}} & {NREGS{iqentry_cmt[14]}} & iq14_out,
	iqentry_15_livetarget = {NREGS{iqentry_v[15]}} & {NREGS{~iqentry_stomp[15]}} & {NREGS{iqentry_cmt[15]}} & iq15_out;


integer n;
always @*
	for (n = 1; n < NREGS+1; n = n + 1)
		livetarget[n] <=
			iqentry_0_livetarget[n] | iqentry_1_livetarget[n] | iqentry_2_livetarget[n] | iqentry_3_livetarget[n] |
			iqentry_4_livetarget[n] | iqentry_5_livetarget[n] | iqentry_6_livetarget[n] | iqentry_7_livetarget[n] |
			iqentry_8_livetarget[n] | iqentry_9_livetarget[n] | iqentry_10_livetarget[n] | iqentry_11_livetarget[n] |
			iqentry_12_livetarget[n] | iqentry_13_livetarget[n] | iqentry_14_livetarget[n] | iqentry_15_livetarget[n]
			;

reg [3:0] tail0;
reg [3:0] tail1;
reg [3:0] tail2;
reg [3:0] head0;
reg [3:0] head1;
reg [3:0] head2;
// used only to determine memory-access ordering
reg [3:0] head3;
reg [3:0] head4;
reg [3:0] head5;
reg [3:0] head6;
reg [3:0] head7;
reg [3:0] head8;
reg [3:0] head9;
reg [3:0] head10;
reg [3:0] head11;
reg [3:0] head12;
reg [3:0] head13;
reg [3:0] head14;
reg [3:0] head15;

wire [3:0] missid;

reg commit0_v;
reg commit1_v;
reg commit2_v;
reg [6:0] commit0_tgt;
reg [6:0] commit1_tgt;
reg [6:0] commit2_tgt;
reg [63:0] commit0_bus;
reg [63:0] commit1_bus;
reg [63:0] commit2_bus;

icache_ram u1
(
	.wclk(clk),
	.wa(adr_o[12:0]),
	.wr(isICacheLoad & ack_i),
	.i(dat_i),
	.rclk(~clk),
	.pc(pc[12:0]),
	.bundle(bundle)
);

icache_tagram u2
(
	.wclk(clk),
	.wa(adr_o),
	.wr(isICacheReset|(isICacheLoad & ack_i)),
	.v(!isICacheReset),
	.rclk(~clk),
	.pc(pc),
	.hit(ihit)
);

FISA64_regfile u3
(
	.wclk(clk),
	.wr0(commit0_v & ~commit0_tgt[6]),
	.wr1(commit1_v & ~commit1_tgt[6]),
	.wr2(commit2_v & ~commit2_tgt[6]),
	.wa0(commit0_tgt[5:0]),
	.wa1(commit1_tgt[5:0]),
	.wa2(commit2_tgt[5:0]),
	.i0(commit0_bus),
	.i1(commit1_bus),
	.i2(commit2_bus),
	.ra0(fetchbuf0_instr[`INSTRUCTION_RA]),
	.ra1(fetchbuf0_instr[`INSTRUCTION_RB]),
	.ra2(fetchbuf0_instr[`INSTRUCTION_RC]),
	.ra3(fetchbuf1_instr[`INSTRUCTION_RA]),
	.ra4(fetchbuf1_instr[`INSTRUCTION_RB]),
	.ra5(fetchbuf1_instr[`INSTRUCTION_RC]),
	.ra6(fetchbuf2_instr[`INSTRUCTION_RA]),
	.ra7(fetchbuf2_instr[`INSTRUCTION_RB]),
	.ra8(fetchbuf2_instr[`INSTRUCTION_RC]),
	.o0(rfoa0),
	.o1(rfob0),
	.o2(rfoc0),
	.o3(rfoa1),
	.o4(rfob1),
	.o5(rfoc1),
	.o6(rfoa2),
	.o7(rfob2),
	.o8(rfoc2),
	.pc0(fetchbuf0_pc),
	.pc1(fetchbuf1_pc),
	.pc2(fetchbuf2_pc)
);

function [6:0] fnRa;
input [39:0] insn;
case(insn[5:0])
`RR:
	case(insn[39:34])
	`RTI:	fnRa = 7'h5E;
	`RTE:	fnRa = 7'h5D;
	endcase
default:	fnRa = {1'b0,insn[`INSTRUCTION_RA]};
endcase
endfunction

function [6:0] fnRb;
input [39:0] insn;
case(insn[5:0])
`RR:
	case(insn[39:34])
	`RTI:	fnRb = 7'h5E;
	`RTE:	fnRb = 7'h5D;
	endcase
default:	fnRb = {1'b0,insn[`INSTRUCTION_RB]};
endcase
endfunction

function [6:0] fnRc;
input [39:0] insn;
case(insn[5:0])
`RR:
	case(insn[39:34])
	`RTI:	fnRc = 7'h5E;
	`RTE:	fnRc = 7'h5D;
	endcase
default:	fnRc = {1'b0,insn[`INSTRUCTION_RC]};
endcase
endfunction

// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource3_v;
input [5:0] opcode;
	casex(opcode)
	`SB,`SC,`SH,`SW:	fnSource3_v = 1'b0;
	default:	fnSource3_v = 1'b1;
	endcase
endfunction

function fnIsBranch;
input [5:0] opcode;
case(opcode)
6'd16,6'd17,6'd18:	fnIsBranch = TRUE;
default:	fnIsBranch = FALSE;
endcase
endfunction

function fnIsStore;
input [5:0] opcode;
fnIsStore = opcode==`SB || opcode==`SC || opcode==`SH || opcode==`SW;
endfunction

function fnIsLoad;
input [5:0] opcode;
fnIsLoad =	opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW;
endfunction

function fnIsMem;
input [5:0] opcode;
fnIsMem = 	opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW || 
			opcode==`SB || opcode==`SC || opcode==`SH || opcode==`SW
			;
endfunction

function [7:0] fnSelect;
input [5:0] opcode;
input [31:0] adr;
begin
	case(opcode)
	`LB,`LBU,`SB:
		case(adr[2:0])
		3'd0:	fnSelect = 8'h01;
		3'd1:	fnSelect = 8'h02;
		3'd2:	fnSelect = 8'h04;
		3'd3:	fnSelect = 8'h08;
		3'd4:	fnSelect = 8'h10;
		3'd5:	fnSelect = 8'h20;
		3'd6:	fnSelect = 8'h40;
		3'd7:	fnSelect = 8'h80;
		endcase
	`LC,`LCU,`SC:
		case(adr[2:1])
		2'd0:	fnSelect = 8'h03;
		2'd1:	fnSelect = 8'h0C;
		2'd2:	fnSelect = 8'h30;
		2'd3:	fnSelect = 8'hC0;
		endcase
	`LH,`LHU,`SH:
		case(adr[2])
		1'b0:	fnSelect = 8'h0F;
		1'b1:	fnSelect = 8'hF0;
		endcase
	`LW,`SW:
		fnSelect = 8'hFF;
	default:	fnSelect = 8'h00;
	endcase
end
endfunction



wire xbr = (fnIsBranch(iqentry_op[head0])) || (fnIsBranch(iqentry_op[head1])) || (fnIsBranch(iqentry_op[head2]));

//
// BRANCH-MISS LOGIC: latestID
//
// latestID is the instruction queue ID of the newest instruction (latest) that targets
// a particular register.  looks a lot like scheduling logic, but in reverse.
// 

assign iqentry_0_latestID = (missid == 4'd0 || ((iqentry_0_livetarget & iqentry_1_cumulative) == {NREGS{1'b0}}))
				? iqentry_0_livetarget
				: {NREGS{1'b0}};
assign iqentry_0_cumulative = (missid == 4'd0)
				? iqentry_0_livetarget
				: iqentry_0_livetarget | iqentry_1_cumulative;

assign iqentry_1_latestID = (missid == 4'd1 || ((iqentry_1_livetarget & iqentry_2_cumulative) == {NREGS{1'b0}}))
				? iqentry_1_livetarget
				: {NREGS{1'b0}};
assign iqentry_1_cumulative = (missid == 4'd1)
				? iqentry_1_livetarget
				: iqentry_1_livetarget | iqentry_2_cumulative;

assign iqentry_2_latestID = (missid == 4'd2 || ((iqentry_2_livetarget & iqentry_3_cumulative) == {NREGS{1'b0}}))
				? iqentry_2_livetarget
				: {NREGS{1'b0}};
assign iqentry_2_cumulative = (missid == 4'd2)
				? iqentry_2_livetarget
				: iqentry_2_livetarget | iqentry_3_cumulative;

assign iqentry_3_latestID = (missid == 4'd3 || ((iqentry_3_livetarget & iqentry_4_cumulative) == {NREGS{1'b0}}))
				? iqentry_3_livetarget
				: {NREGS{1'b0}};
assign iqentry_3_cumulative = (missid == 4'd3)
				? iqentry_3_livetarget
				: iqentry_3_livetarget | iqentry_4_cumulative;

assign iqentry_4_latestID = (missid == 4'd4 || ((iqentry_4_livetarget & iqentry_5_cumulative) == {NREGS{1'b0}}))
				? iqentry_4_livetarget
				: {NREGS{1'b0}};
assign iqentry_4_cumulative = (missid == 4'd4)
				? iqentry_4_livetarget
				: iqentry_4_livetarget | iqentry_5_cumulative;

assign iqentry_5_latestID = (missid == 4'd5 || ((iqentry_5_livetarget & iqentry_6_cumulative) == {NREGS{1'b0}}))
				? iqentry_5_livetarget
				: 287'd0;
assign iqentry_5_cumulative = (missid == 4'd5)
				? iqentry_5_livetarget
				: iqentry_5_livetarget | iqentry_6_cumulative;

assign iqentry_6_latestID = (missid == 4'd6 || ((iqentry_6_livetarget & iqentry_7_cumulative) == {NREGS{1'b0}}))
				? iqentry_6_livetarget
				: {NREGS{1'b0}};
assign iqentry_6_cumulative = (missid == 4'd6)
				? iqentry_6_livetarget
				: iqentry_6_livetarget | iqentry_7_cumulative;

assign iqentry_7_latestID = (missid == 4'd7 || ((iqentry_7_livetarget & iqentry_8_cumulative) == {NREGS{1'b0}}))
				? iqentry_7_livetarget
				: {NREGS{1'b0}};
assign iqentry_7_cumulative = (missid == 4'd7)
				? iqentry_7_livetarget
				: iqentry_7_livetarget | iqentry_8_cumulative;

assign iqentry_8_latestID = (missid == 4'd8 || ((iqentry_8_livetarget & iqentry_9_cumulative) == {NREGS{1'b0}})) ? iqentry_8_livetarget : {NREGS{1'b0}};
assign iqentry_9_latestID = (missid == 4'd9 || ((iqentry_9_livetarget & iqentry_10_cumulative) == {NREGS{1'b0}})) ? iqentry_9_livetarget : {NREGS{1'b0}};
assign iqentry_10_latestID = (missid == 4'd10 || ((iqentry_10_livetarget & iqentry_11_cumulative) == {NREGS{1'b0}})) ? iqentry_10_livetarget : {NREGS{1'b0}};
assign iqentry_11_latestID = (missid == 4'd11 || ((iqentry_11_livetarget & iqentry_12_cumulative) == {NREGS{1'b0}})) ? iqentry_11_livetarget : {NREGS{1'b0}};
assign iqentry_12_latestID = (missid == 4'd12 || ((iqentry_12_livetarget & iqentry_13_cumulative) == {NREGS{1'b0}})) ? iqentry_12_livetarget : {NREGS{1'b0}};
assign iqentry_13_latestID = (missid == 4'd13 || ((iqentry_13_livetarget & iqentry_14_cumulative) == {NREGS{1'b0}})) ? iqentry_13_livetarget : {NREGS{1'b0}};
assign iqentry_14_latestID = (missid == 4'd14 || ((iqentry_14_livetarget & iqentry_15_cumulative) == {NREGS{1'b0}})) ? iqentry_14_livetarget : {NREGS{1'b0}};
assign iqentry_15_latestID = (missid == 4'd15 || ((iqentry_15_livetarget & iqentry_0_cumulative) == {NREGS{1'b0}})) ? iqentry_15_livetarget : {NREGS{1'b0}};

assign iqentry_8_cumulative = (missid == 4'd8) ? iqentry_8_livetarget : iqentry_8_livetarget | iqentry_9_cumulative;
assign iqentry_9_cumulative = (missid == 4'd9) ? iqentry_9_livetarget : iqentry_9_livetarget | iqentry_10_cumulative;
assign iqentry_10_cumulative = (missid == 4'd10) ? iqentry_10_livetarget : iqentry_10_livetarget | iqentry_11_cumulative;
assign iqentry_11_cumulative = (missid == 4'd11) ? iqentry_11_livetarget : iqentry_11_livetarget | iqentry_12_cumulative;
assign iqentry_12_cumulative = (missid == 4'd12) ? iqentry_12_livetarget : iqentry_12_livetarget | iqentry_13_cumulative;
assign iqentry_13_cumulative = (missid == 4'd13) ? iqentry_13_livetarget : iqentry_13_livetarget | iqentry_14_cumulative;
assign iqentry_14_cumulative = (missid == 4'd14) ? iqentry_14_livetarget : iqentry_14_livetarget | iqentry_15_cumulative;
assign iqentry_15_cumulative = (missid == 4'd15) ? iqentry_15_livetarget : iqentry_15_livetarget | iqentry_0_cumulative;

assign
	iqentry_source[0] = | iqentry_0_latestID,
	iqentry_source[1] = | iqentry_1_latestID,
	iqentry_source[2] = | iqentry_2_latestID,
	iqentry_source[3] = | iqentry_3_latestID,
	iqentry_source[4] = | iqentry_4_latestID,
	iqentry_source[5] = | iqentry_5_latestID,
	iqentry_source[6] = | iqentry_6_latestID,
	iqentry_source[7] = | iqentry_7_latestID,
	iqentry_source[8] = | iqentry_8_latestID,
	iqentry_source[9] = | iqentry_9_latestID,
	iqentry_source[10] = | iqentry_10_latestID,
	iqentry_source[11] = | iqentry_11_latestID,
	iqentry_source[12] = | iqentry_12_latestID,
	iqentry_source[13] = | iqentry_13_latestID,
	iqentry_source[14] = | iqentry_14_latestID,
	iqentry_source[15] = | iqentry_15_latestID;

assign int_pending = (nmi_edge & ~StatusHWI & ~int_commit) || (irq_i & ~im & ~StatusHWI & ~int_commit);

// "Stream" interrupt instructions into the instruction stream until an INT
// instruction commits. This avoids the problem of an INT instruction being
// stomped on by a previous branch instruction.
// Populate the instruction buffers with INT instructions for a hardware interrupt
// Also populate the instruction buffers with a call to the instruction error vector
// if an error occurred during instruction load time.

// There is a one cycle delay in setting the StatusHWI that allowed an extra INT
// instruction to sneek into the queue. This is NOPped out by the int_commit
// signal.

// On a cache miss the instruction buffers are loaded with NOPs this prevents
// the PC from being trashed by invalid branch instructions.
always @(nmi_edge or StatusHWI or int_commit or irq_i or im or insnerr or insn or vec_i or ihit)
if (nmi_edge & ~StatusHWI & ~int_commit)
	insn0 <= {1'b1,2'b00,9'd510,`BRK};
else if (irq_i & ~im & ~StatusHWI & ~int_commit)
	insn0 <= {1'b1,2'b00,vec_i,`BRK};
else if (ihit)
	insn0 <= insn0a;
else
	insn0 <= {34'd0,`NOP};	// load with NOPs

always @(nmi_edge or StatusHWI or int_commit or irq_i or im or insnerr or insn or vec_i or ihit)
if (nmi_edge & ~StatusHWI & ~int_commit)
	insn1 <= {1'b1,2'b00,9'd510,`BRK};
else if (irq_i & ~im & ~StatusHWI & ~int_commit)
	insn1 <= {1'b1,2'b00,vec_i,`BRK};
else if (ihit)
	insn1 <= insn1a;
else
	insn1 <= {34'd0,`NOP};	// load with NOPs

always @(nmi_edge or StatusHWI or int_commit or irq_i or im or insnerr or insn or vec_i or ihit)
if (nmi_edge & ~StatusHWI & ~int_commit)
	insn2 <= {1'b1,2'b00,9'd510,`BRK};
else if (irq_i & ~im & ~StatusHWI & ~int_commit)
	insn2 <= {1'b1,2'b00,vec_i,`BRK};
else if (ihit)
	insn2 <= insn2a;
else
	insn2 <= {34'd0,`NOP};	// load with NOPs


always @*
if (fetchbuf) begin
	fetchbuf0_instr <= fetchbufD_instr;
	fetchbuf0_pc <= fetchbufD_pc;
	fetchbuf0_v <= fetchbufD_v;
	fetchbuf1_instr <= fetchbufE_instr;
	fetchbuf1_pc <= fetchbufE_pc;
	fetchbuf1_v <= fetchbufE_v;
	fetchbuf2_instr <= fetchbufF_instr;
	fetchbuf2_pc <= fetchbufF_pc;
	fetchbuf2_v <= fetchbufF_v;
end
else begin
	fetchbuf0_instr <= fetchbufA_instr;
	fetchbuf0_pc <= fetchbufA_pc;
	fetchbuf0_v <= fetchbufA_v;
	fetchbuf1_instr <= fetchbufB_instr;
	fetchbuf1_pc <= fetchbufB_pc;
	fetchbuf1_v <= fetchbufB_v;
	fetchbuf2_instr <= fetchbufC_instr;
	fetchbuf2_pc <= fetchbufC_pc;
	fetchbuf2_v <= fetchbufC_v;
end

initial begin
	message[ `PANIC_NONE ]			= "NONE            ";
	message[ `PANIC_FETCHBUFBEQ ]		= "FETCHBUFBEQ     ";
	message[ `PANIC_INVALIDISLOT ]		= "INVALIDISLOT    ";
	message[ `PANIC_IDENTICALDRAMS ]	= "IDENTICALDRAMS  ";
	message[ `PANIC_OVERRUN ]		= "OVERRUN         ";
	message[ `PANIC_HALTINSTRUCTION ]	= "HALTINSTRUCTION ";
	message[ `PANIC_INVALIDMEMOP ]		= "INVALIDMEMOP    ";
	message[ `PANIC_INVALIDFBSTATE ]	= "INVALIDFBSTATE  ";
	message[ `PANIC_INVALIDIQSTATE ]	= "INVALIDIQSTATE  ";
	message[ `PANIC_BRANCHBACK ]		= "BRANCHBACK      ";
	message[ `PANIC_MEMORYRACE ]		= "MEMORYRACE      ";
end

`include "FISA64_issue_combo.v"
`include "FISA64_execute_combo.v"
`include "FISA64_memory_combo.v"
`include "FISA64_commit_combo.v"

reg nmi1;
always @(posedge clk_i)
	if (rst_i)
		nmi1 <= 1'b0;
	else
		nmi1 <= nmi_i;

always @(posedge clk)
if (rst_i) begin
	nmi_edge <= 1'b0;
	fetchbuf <= 1'b0;
	fetchbufA_v <= `INV;
	fetchbufB_v <= `INV;
	fetchbufC_v <= `INV;
	fetchbufD_v <= `INV;
	fetchbufE_v <= `INV;
	fetchbufF_v <= `INV;
	iqentry_v <= 16'h0000;
end
else begin
	if (nmi_i & !nmi1)
		nmi_edge <= 1'b1;
`include "FISA64_ifetch3.v"
	if (ihit) begin
	$display("%h %h hit=%b#", spc, pc, ihit);
	$display("%c insn0=%h insn1=%h insn2=%h", nmi_edge ? "*" : " ",insn0, insn1, insn2);
	$display("takb=%d br_pc=%h #", take_branch, branch_pc);
	$display("%c%c A: %d %h %h #",
	    45, fetchbuf?45:62, fetchbufA_v, fetchbufA_instr, fetchbufA_pc);
	$display("%c%c B: %d %h %h #",
	    45, fetchbuf?45:62, fetchbufB_v, fetchbufB_instr, fetchbufB_pc);
	$display("%c%c C: %d %h %h #",
	    45, fetchbuf?45:62, fetchbufC_v, fetchbufC_instr, fetchbufC_pc);
	$display("%c%c D: %d %h %h #",
	    45, fetchbuf?62:45, fetchbufD_v, fetchbufD_instr, fetchbufD_pc);
	$display("%c%c E: %d %h %h #",
	    45, fetchbuf?62:45, fetchbufE_v, fetchbufE_instr, fetchbufE_pc);
	$display("%c%c F: %d %h %h #",
	    45, fetchbuf?62:45, fetchbufF_v, fetchbufF_instr, fetchbufF_pc);
	$display("fetchbuf=%d",fetchbuf);
	end
`include "commit_early.v"
`include "FISA64_enque3.v"
	if (ihit) begin
	for (i=0; i<16; i=i+1) 
	    $display("%c%c %d: %d %d %d %d %d %d %d %d %d %d %c%h %d%s %h %h %h %d %o %h %d %o %h #",
		(i[3:0]==head0)?72:46, (i[3:0]==tail0)?84:46, i,
		iqentry_v[i], iqentry_done[i], iqentry_cmt[i], iqentry_out[i], iqentry_bt[i], iqentry_memissue[i], iqentry_agen[i], iqentry_issue[i],
		iqentry_islot[i],
//		((i==0) ? iqentry_0_islot : (i==1) ? iqentry_1_islot : (i==2) ? iqentry_2_islot : (i==3) ? iqentry_3_islot :
//		 (i==4) ? iqentry_4_islot : (i==5) ? iqentry_5_islot : (i==6) ? iqentry_6_islot : iqentry_7_islot),
		 iqentry_stomp[i],
		(fnIsFlowCtrl(iqentry_op[i]) ? 98 : fnIsMem(iqentry_op[i]) ? 109 : 97), 
		iqentry_op[i],
		fnRegstr(iqentry_tgt[i]),fnRegstrGrp(iqentry_tgt[i]),
		iqentry_res[i], iqentry_a0[i], iqentry_a1[i], iqentry_a1_v[i],
		iqentry_a1_s[i], iqentry_a2[i], iqentry_a2_v[i], iqentry_a2_s[i], iqentry_pc[i]);
	end
`include "FISA64_data_incoming.v"
`include "FISA64_commit3.v"
	if (|panic) begin
	    $display("");
	    $display("-----------------------------------------------------------------");
	    $display("-----------------------------------------------------------------");
	    $display("---------------     PANIC:%s     -----------------", message[panic]);
	    $display("-----------------------------------------------------------------");
	    $display("-----------------------------------------------------------------");
	    $display("");
	    $display("instructions committed: %d", I);
	    $display("total execution cycles: %d", $time / 10);
	    $display("");
	end
	if (|panic && ~outstanding_stores) begin
	    $finish;
	end
end

task LD_fetchbufABC;
	fetchbufA_instr <= insn0;
	fetchbufA_v <= ld_fetchbuf;
	fetchbufA_pc <= {pc[31:4],4'h0};
	fetchbufB_instr <= insn1;
	fetchbufB_v <= ld_fetchbuf;
	fetchbufB_pc <= {pc[31:4],4'h5};
	fetchbufC_instr <= insn2;
	fetchbufC_v <= ld_fetchbuf;
	fetchbufC_pc <= {pc[31:4],4'hA};
	if (do_pcinc) pc[31:4] <= pc[31:4] + 28'd1;
end
endtask

task LD_fetchbufDEF;
	fetchbufD_instr <= insn0;
	fetchbufD_v <= ld_fetchbuf;
	fetchbufD_pc <= {pc[31:4],4'h0};
	fetchbufE_instr <= insn1;
	fetchbufE_v <= ld_fetchbuf;
	fetchbufE_pc <= {pc[31:4],4'h5};
	fetchbufF_instr <= insn2;
	fetchbufF_v <= ld_fetchbuf;
	fetchbufF_pc <= {pc[31:4],4'hA};
	if (do_pcinc) pc[31:4] <= pc[31:4] + 28'd1;
end
endtask

task tskEnque;
input [3:0] tail;
input [39:0] instr;
input [31:0] pc;
input predict_taken;
input [63:0] rfoa;
input [63:0] rfob;
input [63:0] rfoc;
begin
	iqentry_v    [tail]    <=   `VAL;
	iqentry_done [tail]    <=   `INV;
	iqentry_cmt	 [tail]    <=   `INV;
	iqentry_out  [tail]    <=   `INV;
	iqentry_res  [tail]    <=   `ZERO;
	iqentry_op   [tail]    <=    instr[5:0];
	iqentry_fn   [tail]    <=    instr[39:34];
	iqentry_cond [tail]    <=   cond2;
	iqentry_bt   [tail]    <=   fnIsFlowCtrl(instr) && predict_taken;
	iqentry_agen [tail]    <=   `INV;
	// If an interrupt is being enqueued and the previous instruction was an immediate prefix, then
	// inherit the address of the previous instruction, so that the prefix will be executed on return
	// from interrupt.
	// If a string operation was in progress then inherit the address of the string operation so that
	// it can be continued.
	iqentry_pc   [tail]    <=	
		(instr[5:0]==`BRK && iqentry_op[tail-4'd1]==`IMM && iqentry_v[tail-4'd1]==`VAL) ? 
			iqentry_pc[tail-4'd1]) : pc;
	iqentry_mem  [tail]    <=   fnIsMem(instr[5:0]);
	iqentry_jmp  [tail]    <=   fnIsJmp(instr[5:0]);
	iqentry_rfw  [tail]    <=   fnIsRFW(instr);
	iqentry_tgt  [tail]    <=   fnTargetReg(instr);
	// Look at the previous queue slot to see if an immediate prefix is enqueued
	// But don't allow it for a branch
	iqentry_imm  [tail]   <=  	instr[5:0]==`BRK ? fnImm(instr) :
								fnIsBranch(instr[5:0]) ? {{DBW-12{instr[11]}},instr[11:8],instr[23:16]} :
								iqentry_op[tail-4'd1]==`IMM && iqentry_v[tail-4'd1] ? {iqentry_imm[tail-4'd1][DBW-1:8],fnImm8(instr)} :
								instr[5:0]==`IMM ? fnImmImm(instr) :
								fnImm(instr);
	iqentry_a    [tail]    <=   fnOpa(instr[5:0],instr,rfoa,pc);
	iqentry_av   [tail]    <=   fnSource1_v( instr[5:0] ) | rf_v[ fnRa(instr) ];
	iqentry_as   [tail]    <=   rf_source [fnRa(instr)];
	iqentry_b    [tail]    <=   fnIsShiftiop(instr[5:0]) ? {58'b0,fnRb(instr)} : opcode2==`STI ? instr[31:22] : rfob;
	iqentry_bv   [tail]    <=   fnSource2_v( instr[5:0] ) | rf_v[ fnRb(instr) ];
	iqentry_bs   [tail]    <=   rf_source[fnRb(instr)];
	iqentry_c    [tail]    <=   rfoc;
	iqentry_cv   [tail]    <=   fnSource3_v( instr[5:0] ) | rf_v[ fnRc(instr) ];
	iqentry_cs   [tail]    <=   rf_source[fnRc(instr)];
end
endtask

task inc_head;
input [3:0] amt;
begin
	head0 <= head0 + amt;
	head1 <= head1 + amt;
	head2 <= head2 + amt;
	head3 <= head3 + amt;
	head4 <= head4 + amt;
	head5 <= head5 + amt;
	head6 <= head6 + amt;
	head7 <= head7 + amt;
	head8 <= head8 + amt;
	head9 <= head9 + amt;
	head10 <= head10 + amt;
	head11 <= head11 + amt;
	head12 <= head12 + amt;
	head13 <= head13 + amt;
	head14 <= head14 + amt;
	head15 <= head15 + amt;
	I <= I + amt;
end
endtask

endmodule

module icache_ram(wclk, wa, wr, i, rclk, pc, bundle);
input wclk;
input [12:0] wa;
input wr;
input [31:0] i;
input rclk;
input [12:0] pc;
output [127:0] bundle;

reg [127:0] mem [511:0];
always @(posedge wclk)
begin
if (wr & wa[3:2]==2'b00) mem[wa[12:4]][31:0] <= i;
if (wr & wa[3:2]==2'b01) mem[wa[12:4]][63:32] <= i;
if (wr & wa[3:2]==2'b10) mem[wa[12:4]][95:64] <= i;
if (wr & wa[3:2]==2'b11) mem[wa[12:4]][127:96] <= i;
end
reg [12:0] rpc;
always @(posedge rclk)
	rpc <= pc;
assign bundle = mem[rpc[12:4]];

endmodule

module icache_tagram(wclk, wa, wr, v, rclk, pc, hit);
input wclk;
input [31:0] wa;
input wr;
input v;
input rclk;
input [31:0] pc;
output hit;

reg [32:13] mem [511:0];
always @(posedge wclk)
if (wr && wa[3:2]==2'b11) mem[wa[12:4]] <= {v,wa[31:13]};
reg [31:0] rpc;
always @posedge (rclk)
	rpc <= pc;
assign hit = mem[rcp[12:4]]=={1'b1,rpc[31:13]};

endmodule

module decoder7 (num, out);
input [6:0] num;
output [127:1] out;

wire [127:0] out1;

assign out1 = 128'd1 << num;
assign out = out1[127:1];

endmodule
