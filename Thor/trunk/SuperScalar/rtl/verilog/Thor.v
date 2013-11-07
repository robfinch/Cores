// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
//
// Thor Superscaler
//
// ============================================================================
//
`include "Thor_defines.v"
`define INSTRUCTION_RA	23:16
`define INSTRUCTION_RB	31:24
`define ZERO		16'd0

// exception types:
`define EXC_NONE	4'd0
`define EXC_HALT	4'd1
`define EXC_TLBMISS	4'd2
`define EXC_SIGSEGV	4'd3
`define EXC_INVALID	4'd4

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

`define DRAMSLOT_AVAIL	2'b00
`define DRAMREQ_READY	2'b11

module Thor(rst_i, clk_i, nmi_i, irq_i, bte_o, cti_o, bl_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter IDLE = 4'd0;
parameter ICACHE1 = 4'd1;
parameter NREGS = 303;
parameter PF = 4'd0;
parameter PT = 4'd1;
parameter PEQ = 4'd2;
parameter PNE = 4'd3;
parameter PLE = 4'd4;
parameter PGT = 4'd5;
parameter PGE = 4'd6;
parameter PLT = 4'd7;
parameter PLEU = 4'd8;
parameter PGTU = 4'd9;
parameter PGEU = 4'd10;
parameter PLTU = 4'd11;
input rst_i;
input clk_i;
input nmi_i;
input irq_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [4:0] bl_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [7:0] sel_o;
output reg [63:0] adr_o;
input [63:0] dat_i;
output reg [63:0] dat_o;

integer n,i;
reg [3:0] cstate;
reg [63:0] pc;					// program counter
wire [63:0] pcp16 = pc + 64'd16;
reg [3:0] panic;
reg [63:0] bregs [0:15];		// branch target registers
reg [ 3:0] pregs [0:15];		// predicate registers
reg [63:12] sregs [0:15];		// segment registers
wire [63:0] rfoa0,rfoa1;
wire [63:0] rfob0,rfob1;
reg ic_invalidate;
wire [127:0] insn;
reg [303:0] rf_v;
reg [15:0] pf_v;

wire clk = clk_i;

// Operand registers
wire take_branch;

reg [3:0] rf_source [0:NREGS];
reg [3:0] pf_source [15:0];

// instruction queue (ROB)
reg [7:0]  iqentry_v;			// entry valid?  -- this should be the first bit
reg        iqentry_out	[0:7];	// instruction has been issued to an ALU ... 
reg        iqentry_done	[0:7];	// instruction result valid
reg [7:0]  iqentry_cmt;  		// commit result to machine state
reg        iqentry_bt  	[0:7];	// branch-taken (used only for branches)
reg        iqentry_agen [0:7];	// address-generate ... signifies that address is ready (only for LW/SW)
reg        iqentry_mem	[0:7];	// touches memory: 1 if LW/SW
reg        iqentry_jmp	[0:7];	// changes control flow: 1 if BEQ/JALR
reg        iqentry_rfw	[0:7];	// writes to register file
reg [63:0] iqentry_res	[0:7];	// instruction result
reg  [3:0] iqentry_insnsz [0:7];
reg  [3:0] iqentry_cond [0:7];
reg  [3:0] iqentry_pred [0:7];
reg        iqentry_p_v  [0:7];
reg  [3:0] iqentry_p_s  [0:7];
reg  [7:0] iqentry_op	[0:7];	// instruction opcode
reg  [3:0] iqentry_exc	[0:7];	// only for branches ... indicates a HALT instruction
reg  [8:0] iqentry_tgt	[0:7];	// Rt field or ZERO -- this is the instruction's target (if any)
reg [63:0] iqentry_a0	[0:7];	// argument 0 (immediate)
reg [63:0] iqentry_a1	[0:7];	// argument 1
reg        iqentry_a1_v	[0:7];	// arg1 valid
reg  [3:0] iqentry_a1_s	[0:7];	// arg1 source (iq entry # with top bit representing ALU/DRAM bus)
reg [63:0] iqentry_a2	[0:7];	// argument 2
reg        iqentry_a2_v	[0:7];	// arg2 valid
reg  [3:0] iqentry_a2_s	[0:7];	// arg2 source (iq entry # with top bit representing ALU/DRAM bus)
reg [63:0] iqentry_pc	[0:7];	// program counter for this instruction

wire  [7:0] iqentry_source;
wire  [7:0] iqentry_imm;
wire  [7:0] iqentry_memready;
wire  [7:0] iqentry_memopsvalid;

reg  [7:0] iqentry_memissue;
wire  [7:0] iqentry_stomp;
reg  [7:0] iqentry_issue;
wire  [1:0] iqentry_0_islot;
wire  [1:0] iqentry_1_islot;
wire  [1:0] iqentry_2_islot;
wire  [1:0] iqentry_3_islot;
wire  [1:0] iqentry_4_islot;
wire  [1:0] iqentry_5_islot;
wire  [1:0] iqentry_6_islot;
wire  [1:0] iqentry_7_islot;
reg [1:0] iqentry_islot[0:7];

wire  [NREGS:1] livetarget;
wire  [NREGS:1] iqentry_0_livetarget;
wire  [NREGS:1] iqentry_1_livetarget;
wire  [NREGS:1] iqentry_2_livetarget;
wire  [NREGS:1] iqentry_3_livetarget;
wire  [NREGS:1] iqentry_4_livetarget;
wire  [NREGS:1] iqentry_5_livetarget;
wire  [NREGS:1] iqentry_6_livetarget;
wire  [NREGS:1] iqentry_7_livetarget;
wire  [NREGS:1] iqentry_0_latestID;
wire  [NREGS:1] iqentry_1_latestID;
wire  [NREGS:1] iqentry_2_latestID;
wire  [NREGS:1] iqentry_3_latestID;
wire  [NREGS:1] iqentry_4_latestID;
wire  [NREGS:1] iqentry_5_latestID;
wire  [NREGS:1] iqentry_6_latestID;
wire  [NREGS:1] iqentry_7_latestID;
wire  [NREGS:1] iqentry_0_cumulative;
wire  [NREGS:1] iqentry_1_cumulative;
wire  [NREGS:1] iqentry_2_cumulative;
wire  [NREGS:1] iqentry_3_cumulative;
wire  [NREGS:1] iqentry_4_cumulative;
wire  [NREGS:1] iqentry_5_cumulative;
wire  [NREGS:1] iqentry_6_cumulative;
wire  [NREGS:1] iqentry_7_cumulative;


reg  [2:0] tail0;
reg  [2:0] tail1;
reg  [2:0] head0;
reg  [2:0] head1;
reg  [2:0] head2;	// used only to determine memory-access ordering
reg  [2:0] head3;	// used only to determine memory-access ordering
reg  [2:0] head4;	// used only to determine memory-access ordering
reg  [2:0] head5;	// used only to determine memory-access ordering
reg  [2:0] head6;	// used only to determine memory-access ordering
reg  [2:0] head7;	// used only to determine memory-access ordering

wire  [2:0] missid;
reg   fetchbuf;		// determines which pair to read from & write to

wire [63:0] fetchbuf0_instr;
wire [63:0] fetchbuf0_pc;
wire        fetchbuf0_v;
wire        fetchbuf0_mem;
wire        fetchbuf0_jmp;
wire        fetchbuf0_rfw;
wire        fetchbuf0_pfw;
wire [63:0] fetchbuf1_instr;
wire [63:0] fetchbuf1_pc;
wire        fetchbuf1_v;
wire        fetchbuf1_mem;
wire        fetchbuf1_jmp;
wire        fetchbuf1_rfw;
wire        fetchbuf1_pfw;
wire        fetchbuf1_bfw;

reg [63:0] fetchbufA_instr;	
reg [63:0] fetchbufA_pc;
reg        fetchbufA_v;
reg [63:0] fetchbufB_instr;
reg [63:0] fetchbufB_pc;
reg        fetchbufB_v;
reg [63:0] fetchbufC_instr;
reg [63:0] fetchbufC_pc;
reg        fetchbufC_v;
reg [63:0] fetchbufD_instr;
reg [63:0] fetchbufD_pc;
reg        fetchbufD_v;

reg        did_branchback;

reg        alu0_available;
reg        alu0_dataready;
reg  [3:0] alu0_sourceid;
reg  [3:0] alu0_insnsz;
reg  [7:0] alu0_op;
reg  [3:0] alu0_cond;
reg        alu0_bt;
wire        alu0_cmt;
reg [63:0] alu0_argA;
reg [63:0] alu0_argB;
reg [63:0] alu0_argI;
reg  [3:0] alu0_pred;
reg [63:0] alu0_pc;
wire [63:0] alu0_bus;
wire  [3:0] alu0_id;
wire  [3:0] alu0_exc;
wire        alu0_v;
wire        alu0_branchmiss;
wire [63:0] alu0_misspc;

reg        alu1_available;
reg        alu1_dataready;
reg  [3:0] alu1_sourceid;
reg  [3:0] alu1_insnsz;
reg  [7:0] alu1_op;
reg  [3:0] alu1_cond;
reg        alu1_bt;
wire        alu1_cmt;
reg [63:0] alu1_argA;
reg [63:0] alu1_argB;
reg [63:0] alu1_argI;
reg  [3:0] alu1_pred;
reg [63:0] alu1_pc;
wire [63:0] alu1_bus;
wire  [3:0] alu1_id;
wire  [3:0] alu1_exc;
wire        alu1_v;
wire        alu1_branchmiss;
wire [63:0] alu1_misspc;

wire        branchmiss;
wire [63:0] misspc;

wire        dram_avail;
reg	 [1:0] dram0;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [1:0] dram1;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [1:0] dram2;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg [63:0] dram0_data;
reg [63:0] dram0_addr;
reg  [2:0] dram0_op;
reg  [6:0] dram0_tgt;
reg  [3:0] dram0_id;
reg  [3:0] dram0_exc;
reg [63:0] dram1_data;
reg [63:0] dram1_addr;
reg  [2:0] dram1_op;
reg  [6:0] dram1_tgt;
reg  [3:0] dram1_id;
reg  [3:0] dram1_exc;
reg [63:0] dram2_data;
reg [63:0] dram2_addr;
reg  [2:0] dram2_op;
reg  [6:0] dram2_tgt;
reg  [3:0] dram2_id;
reg  [3:0] dram2_exc;

reg [63:0] dram_bus;
reg  [6:0] dram_tgt;
reg  [3:0] dram_id;
reg  [3:0] dram_exc;
reg        dram_v;

wire        outstanding_stores;
reg [63:0] I;	// instruction count

wire        commit0_v;
wire  [3:0] commit0_id;
wire  [8:0] commit0_tgt;
wire [63:0] commit0_bus;
wire        commit1_v;
wire  [3:0] commit1_id;
wire  [8:0] commit1_tgt;
wire [63:0] commit1_bus;

//
// BRANCH-MISS LOGIC: livetarget
//
// livetarget implies that there is a not-to-be-stomped instruction that targets the register in question
// therefore, if it is zero it implies the rf_v value should become VALID on a branchmiss
// 

Thor_livetarget #(NREGS) ultgt1 
(
	iqentry_v,
	iqentry_stomp,
	iqentry_cmt,
	iqentry_tgt[0],
	iqentry_tgt[1],
	iqentry_tgt[2],
	iqentry_tgt[3],
	iqentry_tgt[4],
	iqentry_tgt[5],
	iqentry_tgt[6],
	iqentry_tgt[7],
	livetarget,
	iqentry_0_livetarget,
	iqentry_1_livetarget,
	iqentry_2_livetarget,
	iqentry_3_livetarget,
	iqentry_4_livetarget,
	iqentry_5_livetarget,
	iqentry_6_livetarget,
	iqentry_7_livetarget
);

//
// BRANCH-MISS LOGIC: latestID
//
// latestID is the instruction queue ID of the newest instruction (latest) that targets
// a particular register.  looks a lot like scheduling logic, but in reverse.
// 

assign iqentry_0_latestID = (missid == 3'd0 || ((iqentry_0_livetarget & iqentry_1_cumulative) == {NREGS{1'b0}}))
				? iqentry_0_livetarget
				: {NREGS{1'b0}};
assign iqentry_0_cumulative = (missid == 3'd0)
				? iqentry_0_livetarget
				: iqentry_0_livetarget | iqentry_1_cumulative;

assign iqentry_1_latestID = (missid == 3'd1 || ((iqentry_1_livetarget & iqentry_2_cumulative) == {NREGS{1'b0}}))
				? iqentry_1_livetarget
				: {NREGS{1'b0}};
assign iqentry_1_cumulative = (missid == 3'd1)
				? iqentry_1_livetarget
				: iqentry_1_livetarget | iqentry_2_cumulative;

assign iqentry_2_latestID = (missid == 3'd2 || ((iqentry_2_livetarget & iqentry_3_cumulative) == {NREGS{1'b0}}))
				? iqentry_2_livetarget
				: {NREGS{1'b0}};
assign iqentry_2_cumulative = (missid == 3'd2)
				? iqentry_2_livetarget
				: iqentry_2_livetarget | iqentry_3_cumulative;

assign iqentry_3_latestID = (missid == 3'd3 || ((iqentry_3_livetarget & iqentry_4_cumulative) == {NREGS{1'b0}}))
				? iqentry_3_livetarget
				: {NREGS{1'b0}};
assign iqentry_3_cumulative = (missid == 3'd3)
				? iqentry_3_livetarget
				: iqentry_3_livetarget | iqentry_4_cumulative;

assign iqentry_4_latestID = (missid == 3'd4 || ((iqentry_4_livetarget & iqentry_5_cumulative) == {NREGS{1'b0}}))
				? iqentry_4_livetarget
				: {NREGS{1'b0}};
assign iqentry_4_cumulative = (missid == 3'd4)
				? iqentry_4_livetarget
				: iqentry_4_livetarget | iqentry_5_cumulative;

assign iqentry_5_latestID = (missid == 3'd5 || ((iqentry_5_livetarget & iqentry_6_cumulative) == {NREGS{1'b0}}))
				? iqentry_5_livetarget
				: 287'd0;
assign iqentry_5_cumulative = (missid == 3'd5)
				? iqentry_5_livetarget
				: iqentry_5_livetarget | iqentry_6_cumulative;

assign iqentry_6_latestID = (missid == 3'd6 || ((iqentry_6_livetarget & iqentry_7_cumulative) == {NREGS{1'b0}}))
				? iqentry_6_livetarget
				: {NREGS{1'b0}};
assign iqentry_6_cumulative = (missid == 3'd6)
				? iqentry_6_livetarget
				: iqentry_6_livetarget | iqentry_7_cumulative;

assign iqentry_7_latestID = (missid == 3'd7 || ((iqentry_7_livetarget & iqentry_0_cumulative) == {NREGS{1'b0}}))
				? iqentry_7_livetarget
				: {NREGS{1'b0}};
assign iqentry_7_cumulative = (missid == 3'd7)
				? iqentry_7_livetarget
				: iqentry_7_livetarget | iqentry_0_cumulative;

assign
	iqentry_source[0] = | iqentry_0_latestID,
	iqentry_source[1] = | iqentry_1_latestID,
	iqentry_source[2] = | iqentry_2_latestID,
	iqentry_source[3] = | iqentry_3_latestID,
	iqentry_source[4] = | iqentry_4_latestID,
	iqentry_source[5] = | iqentry_5_latestID,
	iqentry_source[6] = | iqentry_6_latestID,
	iqentry_source[7] = | iqentry_7_latestID;


assign iqentry_0_islot = iqentry_islot[0];
assign iqentry_1_islot = iqentry_islot[1];
assign iqentry_2_islot = iqentry_islot[2];
assign iqentry_3_islot = iqentry_islot[3];
assign iqentry_4_islot = iqentry_islot[4];
assign iqentry_5_islot = iqentry_islot[5];
assign iqentry_6_islot = iqentry_islot[6];
assign iqentry_7_islot = iqentry_islot[7];

wire [7:0] iqentry_op0_ = iqentry_op[ alu0_id[2:0] ];
wire [7:0] iqentry_op1_ = iqentry_op[ alu1_id[2:0] ];

wire [7:0] Ra0 = fetchbuf0_instr[`INSTRUCTION_RA];
wire [8:0] Rb0 = {1'b0,fetchbuf0_instr[`INSTRUCTION_RB]};
wire [7:0] Ra1 = fetchbuf1_instr[`INSTRUCTION_RA];
wire [8:0] Rb1 = {1'b0,fetchbuf1_instr[`INSTRUCTION_RB]};
wire [7:0] opcode0 = (fetchbuf0_instr[3:0]==4'h0 && fetchbuf0_instr[7:4] > 4'h1 && fetchbuf0_instr[7:4] < 4'h9) ? `IMM : fetchbuf0_instr[15:8];
wire [7:0] opcode1 = (fetchbuf1_instr[3:0]==4'h0 && fetchbuf1_instr[7:4] > 4'h1 && fetchbuf1_instr[7:4] < 4'h9) ? `IMM : fetchbuf1_instr[15:8];
wire [3:0] cond0 = fetchbuf0_instr[3:0];
wire [3:0] cond1 = fetchbuf1_instr[3:0];
wire [3:0] Pn1 = fetchbuf1_instr[7:4];
wire [3:0] Pn0 = fetchbuf0_instr[7:4];
wire [3:0] Pt1 = fetchbuf1_instr[11:8];
wire [3:0] Pt0 = fetchbuf0_instr[11:8];

function [8:0] fnRa;
input [63:0] insn;
case(insn[15:8])
`JSR,`SYS,`INT,`RTS:
	fnRa = {5'h11,insn[23:20]};
default:	fnRa = {1'b0,insn[`INSTRUCTION_RA]};
endcase
endfunction


Thor_regfile2w4r urf1
(
	.clk(clk),
	.rclk(~clk),
	.wr0(commit0_v & ~commit0_tgt[8]),
	.wr1(commit1_v & ~commit1_tgt[8]),
	.wa0(commit0_tgt[7:0]),
	.wa1(commit1_tgt[7:0]),
	.ra0(Ra0),
	.ra1(Rb0),
	.ra2(Ra1),
	.ra3(Rb1),
	.i0(commit0_bus),
	.i1(commit1_bus),
	.o0(rfoa0),
	.o1(rfob0),
	.o2(rfoa1),
	.o3(rfob1)
);

always @(posedge clk)
begin
	if (commit0_v && commit0_tgt[8:4]==5'h10)
		pregs[commit0_tgt[3:0]] <= commit0_bus[3:0];
	if (commit1_v && commit1_tgt[8:4]==5'h10)
		pregs[commit1_tgt[3:0]] <= commit1_bus[3:0];
end

always @(posedge clk)
begin
	if (commit0_v && commit0_tgt[8:4]==5'h11)
		bregs[commit0_tgt[3:0]] <= commit0_bus;
	if (commit1_v && commit1_tgt[8:4]==5'h11)
		bregs[commit1_tgt[3:0]] <= commit1_bus;
end

always @(posedge clk)
begin
	if (commit0_v && commit0_tgt[8:4]==5'h12)
		sregs[commit0_tgt[3:0]] <= commit0_bus;
	if (commit1_v && commit1_tgt[8:4]==5'h12)
		sregs[commit1_tgt[3:0]] <= commit1_bus;
end

//
// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource1_v;
input [7:0] opcode;
	case(opcode)
	`SEI,`CLI,`SYNC:		fnSource1_v = 1'b1;
	`BR:			fnSource1_v = 1'b1;
	default:			fnSource1_v = 1'b0;
	endcase
endfunction

//
// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource2_v;
input [7:0] opcode;
	casex(opcode)
	`TST:			fnSource2_v = 1'b1;
	`ADDI,`ADDUI:	fnSource2_v = 1'b1;
	`SUBI,`SUBUI:	fnSource2_v = 1'b1;
	`ANDI:			fnSource2_v = 1'b1;
	`ORI:			fnSource2_v = 1'b1;
	`EORI:			fnSource2_v = 1'b1;
	`SHLI,`SHLUI,`SHRI,`SHRUI,`ROLI,`RORI,
	`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`SB,`SC,`SH,`SW:
			fnSource2_v = 1'b1;
	`JSR,`SYS,`INT,`RTS,`BR:
			fnSource2_v = 1'b1;
	default:	fnSource2_v = 1'b0;
	endcase
endfunction

function fnIsBranch;
input [6:0] opcode;
case(opcode)
`BR:	fnIsBranch = `TRUE;
default:	fnIsBranch = `FALSE;
endcase
endfunction

wire xbr = (iqentry_op[head0]==`BR) || (iqentry_op[head1]==`BR);
wire takb = iqentry_op[head0]==`BR ? commit0_v : commit1_v;
wire [63:0] xbrpc = (iqentry_op[head0]==`BR) ? iqentry_pc[head0] : iqentry_pc[head1];

wire predict_takenA,predict_takenB,predict_takenC,predict_takenD;

Thor_BranchHistory ubhtA
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(xbr),
	.xisBranch(xbr),
	.pc(pc),
	.xpc(xbrpc),
	.takb(takb),
	.predict_taken(predict_takenA)
);

Thor_BranchHistory ubhtB
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(xbr),
	.xisBranch(xbr),
	.pc(pc),
	.xpc(xbrpc),
	.takb(takb),
	.predict_taken(predict_takenB)
);

Thor_BranchHistory ubhtC
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(xbr),
	.xisBranch(xbr),
	.pc(pc),
	.xpc(xbrpc),
	.takb(takb),
	.predict_taken(predict_takenC)
);

Thor_BranchHistory ubhtD
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(xbr),
	.xisBranch(xbr),
	.pc(pc),
	.xpc(xbrpc),
	.takb(takb),
	.predict_taken(predict_takenD)
);


Thor_icachemem uicm1 
(
	.wclk(clk),
	.wce(cstate==ICACHE1),
	.wr(ack_i),
	.wa(adr_o),
	.wd(dat_i),
	.rclk(~clk),
	.pc(pc),
	.insn(insn)
);

wire hit0,hit1;
Thor_itagmem uitm1
(
	.wclk(clk),
	.wce(cstate==ICACHE1 && adr_o[4:3]==2'b11),
	.wr(ack_i),
	.wa(adr_o),
	.invalidate(ic_invalidate),
	.rclk(~clk),
	.rce(1'b1),
	.pc(pc),
	.hit0(hit0),
	.hit1(hit1)
);

wire ihit = hit0 & hit1;

//wire [3:0] Pn = ir[7:4];

// Set the target register
// 00xx = general register file
// 010x = predicate register
// 011x = branch register
// 012x = segment register
function [8:0] fnTargetReg;
input [63:0] ir;
begin
	casex(ir[15:8])
	`ADD,`ADDU,`SUB,`SUBU,
	`AND,`OR,`EOR,`NAND,`NOR,`ENOR,`ANDC,`ORC,
	`_2ADDU,`_4ADDU,`_8ADDU,`_16ADDU,
	`SHL,`SHR,`SHLU,`SHRU,`ROL,`ROR:
		fnTargetReg = {1'b0,ir[39:32]};
	`ADDI,`ADDUI,`SUBI,`SUBUI,`ANDI,`ORI,`EORI,
	`SHLI,`SHRI,`SHLUI,`SHRUI,`ROLI,`RORI,
	`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW:
		fnTargetReg = {1'b0,ir[39:32]};
	`MFSPR:
		fnTargetReg = {1'b0,ir[31:24]};
	`STSB,`STSW:
		fnTargetReg = {1'b0,ir[23:16]};
	`CMP,`CMPI,`TST:
		fnTargetReg = {1'b1,4'h0,ir[11:8]};
	`JSR,`SYS,`INT:
		fnTargetReg = {1'b1,4'h1,ir[19:16]};
	`MTSPR:
		if (ir[31:28]==4'h2)	// Move to seg. reg.
			fnTargetReg = {1'b1,4'h2,ir[27:24]};
		else
			fnTargetReg = 9'h000;
	default:	fnTargetReg = 9'h00;
	endcase
end
endfunction

function fnHasConst;
input [7:0] opcode;
	casex(opcode)
	`ADDI,`SUBI,`ADDUI,`SUBUI,
	`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI,
	`CMPI,
	`ANDI,`ORI,`EORI,
	`SHLI,`SHLUI,`SHRI,`SHRUI,`ROLI,`RORI,
	`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,
	`SB,`SC,`SH,`SW,
	`JSR,`SYS,`INT,`BR:
		fnHasConst = 1'b1;
	default:
		fnHasConst = 1'b0;
	endcase
endfunction

function fnIsFlowCtrl;
input [7:0] opcode;
begin
case(opcode)
`JSR,`SYS,`INT,`BR,`RTS:
	fnIsFlowCtrl = 1'b1;
default:	fnIsFlowCtrl = 1'b0;
endcase
end
endfunction

function [3:0] fnInsnLength;
input [127:0] insn;
casex(insn[15:0])
16'bxxxxxxxx00000000:	fnInsnLength = 4'd1;
16'bxxxxxxxx00010000:	fnInsnLength = 4'd1;
16'bxxxxxxxx00100000:	fnInsnLength = 4'd2;
16'bxxxxxxxx00110000:	fnInsnLength = 4'd3;
16'bxxxxxxxx01000000:	fnInsnLength = 4'd4;
16'bxxxxxxxx01010000:	fnInsnLength = 4'd5;
16'bxxxxxxxx01100000:	fnInsnLength = 4'd6;
16'bxxxxxxxx01110000:	fnInsnLength = 4'd7;
16'bxxxxxxxx10000000:	fnInsnLength = 4'd8;
16'bxxxxxxxx10010000:
	casex(insn[15:8])
	`NOP,`SEI,`CLI:
		fnInsnLength = 4'd2;
	`TST,`BR,`RTS:
		fnInsnLength = 4'd3;
	`JSR,`SYS,`CMP,`CMPI:
		fnInsnLength = 4'd4;
	default:
		fnInsnLength = 4'd5;
	endcase
default:	fnInsnLength = 4'd5;
endcase
endfunction

function [3:0] fnInsnLength1;
input [127:0] insn;
case(fnInsnLength(insn))
4'd1:	fnInsnLength1 = fnInsnLength(insn[127: 8]);
4'd2:	fnInsnLength1 = fnInsnLength(insn[127:16]);
4'd3:	fnInsnLength1 = fnInsnLength(insn[127:24]);
4'd4:	fnInsnLength1 = fnInsnLength(insn[127:32]);
4'd5:	fnInsnLength1 = fnInsnLength(insn[127:40]);
4'd6:	fnInsnLength1 = fnInsnLength(insn[127:48]);
4'd7:	fnInsnLength1 = fnInsnLength(insn[127:56]);
4'd8:	fnInsnLength1 = fnInsnLength(insn[127:64]);
default:	fnInsnLength1 = 4'd0;
endcase
endfunction

assign fetchbuf0_instr = (fetchbuf == 1'b0) ? fetchbufA_instr : fetchbufC_instr;
assign fetchbuf0_v     = (fetchbuf == 1'b0) ? fetchbufA_v     : fetchbufC_v    ;
assign fetchbuf0_pc    = (fetchbuf == 1'b0) ? fetchbufA_pc    : fetchbufC_pc   ;
assign fetchbuf1_instr = (fetchbuf == 1'b0) ? fetchbufB_instr : fetchbufD_instr;
assign fetchbuf1_v     = (fetchbuf == 1'b0) ? fetchbufB_v     : fetchbufD_v    ;
assign fetchbuf1_pc    = (fetchbuf == 1'b0) ? fetchbufB_pc    : fetchbufD_pc   ;

wire [7:0] opcodeA = fetchbufA_instr[`OPCODE];
wire [7:0] opcodeB = fetchbufB_instr[`OPCODE];
wire [7:0] opcodeC = fetchbufC_instr[`OPCODE];
wire [7:0] opcodeD = fetchbufD_instr[`OPCODE];

function fnIsMem;
input [7:0] opcode;
fnIsMem = 	opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW ||
			opcode==`SB || opcode==`SC || opcode==`SH || opcode==`SW
			;
endfunction

// Determines which instruction write to the register file
function fnIsRFW;
input [7:0] opcode;
fnIsRFW =	opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW ||
			opcode==`ADDI || opcode==`SUBI || opcode==`ADDUI || opcode==`SUBUI ||
			opcode==`ANDI || opcode==`ORI || opcode==`EORI ||
			opcode==`ADD || opcode==`SUB || opcode==`ADDU || opcode==`SUBU ||
			opcode==`AND || opcode==`OR || opcode==`EOR || opcode==`NAND || opcode==`NOR || opcode==`ENOR || opcode==`ANDC || opcode==`ORC ||
			opcode==`SHL || opcode==`SHLU || opcode==`SHR || opcode==`SHRU || opcode==`ROL || opcode==`ROR ||
			opcode==`NOT || opcode==`NEG || opcode==`ABS || opcode==`SGN
			;
endfunction

function fnIsStore;
input [7:0] opcode;
fnIsStore = 	opcode==`SB || opcode==`SC || opcode==`SH || opcode==`SW;
endfunction

function fnIsLoad;
input [7:0] opcode;
fnIsLoad =	opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW;
endfunction

function fnIsPFW;
input [7:0] opcode;
fnIsPFW =	opcode==`CMP || opcode==`CMPI || opcode==`TST;
endfunction

function [7:0] fnSelect;
input [7:0] opcode;
input [63:0] adr;
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

function fnDatai;
input [7:0] opcode;
input [63:0] dat;
input [7:0] sel;
begin
case(opcode)
`LB:
	case(sel)
	8'h01:	fnDatai = {{56{dat[7]}},dat[7:0]};
	8'h02:	fnDatai = {{56{dat[15]}},dat[15:8]};
	8'h04:	fnDatai = {{56{dat[23]}},dat[23:16]};
	8'h08:	fnDatai = {{56{dat[31]}},dat[31:24]};
	8'h10:	fnDatai = {{56{dat[39]}},dat[39:32]};
	8'h20:	fnDatai = {{56{dat[47]}},dat[47:40]};
	8'h40:	fnDatai = {{56{dat[55]}},dat[55:48]};
	8'h80:	fnDatai = {{56{dat[63]}},dat[63:56]};
	default:	fnDatai = 64'hDEADDEADDEADDEAD;
	endcase
`LBU:
	case(sel)
	8'h01:	fnDatai = dat[7:0];
	8'h02:	fnDatai = dat[15:8];
	8'h04:	fnDatai = dat[23:16];
	8'h08:	fnDatai = dat[31:24];
	8'h10:	fnDatai = dat[39:32];
	8'h20:	fnDatai = dat[47:40];
	8'h40:	fnDatai = dat[55:48];
	8'h80:	fnDatai = dat[63:56];
	default:	fnDatai = 64'hDEADDEADDEADDEAD;
	endcase
`LC:
	case(sel)
	8'h03:	fnDatai = {{48{dat[15]}},dat[15:0]};
	8'h0C:	fnDatai = {{48{dat[31]}},dat[31:0]};
	8'h30:	fnDatai = {{48{dat[47]}},dat[47:32]};
	8'hC0:	fnDatai = {{48{dat[63]}},dat[63:48]};
	default:	fnDatai = 64'hDEADDEADDEADDEAD;
	endcase
`LCU:
	case(sel)
	8'h03:	fnDatai = dat[15:0];
	8'h0C:	fnDatai = dat[31:0];
	8'h30:	fnDatai = dat[47:32];
	8'hC0:	fnDatai = dat[63:48];
	default:	fnDatai = 64'hDEADDEADDEADDEAD;
	endcase
`LH:
	case(sel)
	8'h0F:	fnDatai = {{32{dat[31]}},dat[31:0]};
	8'hF0:	fnDatai = {{32{dat[63]}},dat[63:32]};
	default:	fnDatai = 64'hDEADDEADDEADDEAD;
	endcase
`LHU:
	case(sel)
	8'h0F:	fnDatai = dat[31:0];
	8'hF0:	fnDatai = dat[63:32];
	default:	fnDatai = 64'hDEADDEADDEADDEAD;
	endcase
`LW:
	case(sel)
	8'hFF:	fnDatai = dat;
	default:	fnDatai = 64'hDEADDEADDEADDEAD;
	endcase
default:	fnDatai = 64'hDEADDEADDEADDEAD;
endcase
end
endfunction

function fnDatao;
input [7:0] opcode;
input [63:0] dat;
case(opcode)
`SW:	fnDatao = dat;
`SH:	fnDatao = {2{dat[31:0]}};
`SC:	fnDatao = {4{dat[15:0]}};
`SB:	fnDatao = {8{dat[7:0]}};
default:	fnDatao = dat;
endcase
endfunction

assign fetchbuf0_mem	= fetchbuf ? fnIsMem(opcodeC) : fnIsMem(opcodeA);
assign fetchbuf1_mem	= fetchbuf ? fnIsMem(opcodeD) : fnIsMem(opcodeB);

assign fetchbuf0_jmp   = fnIsFlowCtrl(opcode0);
assign fetchbuf1_jmp   = fnIsFlowCtrl(opcode1);

assign fetchbuf0_rfw	= fetchbuf ? fnIsRFW(opcodeC) : fnIsRFW(opcodeA);
assign fetchbuf1_rfw	= fetchbuf ? fnIsRFW(opcodeD) : fnIsRFW(opcodeB);
assign fetchbuf0_pfw	= fetchbuf ? fnIsPFW(opcodeC) : fnIsPFW(opcodeA);
assign fetchbuf1_pfw    = fetchbuf ? fnIsPFW(opcodeD) : fnIsPFW(opcodeB);

wire predict_taken0 = fetchbuf ? predict_takenC : predict_takenA;
wire predict_taken1 = fetchbuf ? predict_takenD : predict_takenB;
//
// set branchback and backpc values ... ignore branches in fetchbuf slots not ready for enqueue yet
//
assign take_branch =
		({fetchbuf0_v, fnIsBranch(opcode0), predict_taken0}  == {`VAL, `TRUE, `TRUE}) ||
		({fetchbuf1_v, fnIsBranch(opcode1), predict_taken1}  == {`VAL, `TRUE, `TRUE})
		;
assign branch_pc =
		({fetchbuf0_v, fnIsBranch(opcode0), predict_taken0}  == {`VAL, `TRUE, `TRUE}) ? 
			fetchbuf0_pc + fnInsnLength(fetchbuf0_instr) + {{56{fetchbuf0_instr[23]}},fetchbuf0_instr[23:16]} :
			fetchbuf1_pc + fnInsnLength(fetchbuf1_instr) + {{56{fetchbuf1_instr[23]}},fetchbuf1_instr[23:16]};

wire [63:0] insn0 = insn[63:0];
reg [63:0] insn1;

always @(insn)
	case(fnInsnLength(insn))
	4'd1:	insn1 <= insn[71: 8];
	4'd2:	insn1 <= insn[79:16];
	4'd3:	insn1 <= insn[87:24];
	4'd4:	insn1 <= insn[95:32];
	4'd5:	insn1 <= insn[103:40];
	4'd6:	insn1 <= insn[111:48];
	4'd7:	insn1 <= insn[119:56];
	4'd8:	insn1 <= insn[127:64];
	default:	insn1 <= {16{8'h10}};	// NOPs
	endcase

function [7:0] fnImm;
input [127:0] insn;

casex(insn[15:8])
`LOOP,`BR:
	fnImm = insn[23:16];
`SYS,`JSR,`INT,`CMPI:
	fnImm = insn[31:24];
default:
	fnImm = insn[39:32];
endcase

endfunction

// Return MSB of immediate value for instruction
function fnImmMSB;
input [127:0] insn;

casex(insn[15:8])
`LOOP,`BR:
	fnImmMSB = insn[23];
`SYS,`JSR,`INT,`CMPI:
	fnImmMSB = insn[31];
default:
	fnImmMSB = insn[39];
endcase

endfunction

`include "Thor_issue_combo.v"
`include "Thor_execute_combo.v"
`include "Thor_memory_combo.v"
`include "Thor_commit_combo.v"


always @(posedge clk) begin

	ic_invalidate <= `FALSE;
	if (rst_i) begin
		ic_invalidate <= `TRUE;
		for (i=0; i<8; i=i+1) begin
			iqentry_v[i] <= `INV;
		end
	end
	
	rf_v[0] <= 1'b1;
	did_branchback <= take_branch;

	if (branchmiss) begin
		for (n = 1; n < 256; n = n + 1)
			if (rf_v[n] == `INV && ~livetarget[n]) rf_v[n] <= `VAL;

	    if (|iqentry_0_latestID[255:1])	rf_source[ iqentry_tgt[0] ] <= { iqentry_mem[0], 3'd0 };
	    if (|iqentry_1_latestID[255:1])	rf_source[ iqentry_tgt[1] ] <= { iqentry_mem[1], 3'd1 };
	    if (|iqentry_2_latestID[255:1])	rf_source[ iqentry_tgt[2] ] <= { iqentry_mem[2], 3'd2 };
	    if (|iqentry_3_latestID[255:1])	rf_source[ iqentry_tgt[3] ] <= { iqentry_mem[3], 3'd3 };
	    if (|iqentry_4_latestID[255:1])	rf_source[ iqentry_tgt[4] ] <= { iqentry_mem[4], 3'd4 };
	    if (|iqentry_5_latestID[255:1])	rf_source[ iqentry_tgt[5] ] <= { iqentry_mem[5], 3'd5 };
	    if (|iqentry_6_latestID[255:1])	rf_source[ iqentry_tgt[6] ] <= { iqentry_mem[6], 3'd6 };
	    if (|iqentry_7_latestID[255:1])	rf_source[ iqentry_tgt[7] ] <= { iqentry_mem[7], 3'd7 };

		for (n = 0; n < 16; n = n + 1)
			if (pf_v[n] == `INV && ~livetarget[n+256]) pf_v[n] <= `VAL;

	    if (|iqentry_0_latestID[271:256])	pf_source[ iqentry_tgt[0][3:0] ] <= { iqentry_mem[0], 3'd0 };
	    if (|iqentry_1_latestID[271:256])	pf_source[ iqentry_tgt[1][3:0] ] <= { iqentry_mem[1], 3'd1 };
	    if (|iqentry_2_latestID[271:256])	pf_source[ iqentry_tgt[2][3:0] ] <= { iqentry_mem[2], 3'd2 };
	    if (|iqentry_3_latestID[271:256])	pf_source[ iqentry_tgt[3][3:0] ] <= { iqentry_mem[3], 3'd3 };
	    if (|iqentry_4_latestID[271:256])	pf_source[ iqentry_tgt[4][3:0] ] <= { iqentry_mem[4], 3'd4 };
	    if (|iqentry_5_latestID[271:256])	pf_source[ iqentry_tgt[5][3:0] ] <= { iqentry_mem[5], 3'd5 };
	    if (|iqentry_6_latestID[271:256])	pf_source[ iqentry_tgt[6][3:0] ] <= { iqentry_mem[6], 3'd6 };
	    if (|iqentry_7_latestID[271:256])	pf_source[ iqentry_tgt[7][3:0] ] <= { iqentry_mem[7], 3'd7 };
		
	end

`include "Thor_ifetch.v"
`include "Thor_enque.v"
`include "Thor_dataincoming.v"
`include "Thor_issue.v"
`include "Thor_memory.v"
`include "Thor_commit.v"

	case(cstate)
	IDLE:
		if (!ihit) begin
			if (dram0!=2'd0 || dram1!=2'd0 || dram2!=2'd0)
				;
			else begin
				bte_o <= 2'b00;
				cti_o <= 3'b001;
				cyc_o <= 1'b1;
				stb_o <= 1'b1;
				we_o <= 1'b0;
				sel_o <= 8'hFF;
				adr_o <= !hit0 ? {pc[63:5],5'b00000} : {pcp16[63:5],5'b00000};
				dat_o <= 64'd0;
				cstate <= ICACHE1;
			end
		end
	ICACHE1:
		if (ack_i) begin
			adr_o[4:3] <= adr_o[4:3] + 2'd1;
			if (adr_o[4:3]==2'b10)
				cti_o <= 3'b111;
			if (adr_o[4:3]==2'b11) begin
				wb_nack();
				cstate <= IDLE;
			end
		end
	endcase

end

task wb_nack;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b000;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 8'h00;
	adr_o <= 64'd0;
	dat_o <= 64'd0;
end
endtask

task wb_read_byte;
input [63:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b0;
	case(adr[2:0])
	3'd0:	sel_o <= 8'b00000001;
	3'd1:	sel_o <= 8'b00000010;
	3'd2:	sel_o <= 8'b00000100;
	3'd3:	sel_o <= 8'b00001000;
	3'd4:	sel_o <= 8'b00010000;
	3'd5:	sel_o <= 8'b00100000;
	3'd6:	sel_o <= 8'b01000000;
	3'd7:	sel_o <= 8'b10000000;
	endcase
	adr_o <= adr;
end
endtask

task t_mem;
input port;
input [40:0] ir;
input [63:0] a;
input [63:0] b;
begin
	case(ir[34:30])
	`LB:	wb_read_byte(a+{{49{ir[14]}},ir[14:0]});
	`LC:	wb_read_char(a+{{49{ir[14]}},ir[14:0]});
	`LH:	wb_read_half(a+{{49{ir[14]}},ir[14:0]});
	`LW:	wb_read_word(a+{{49{ir[14]}},ir[14:0]});
	`SB:	wb_store_byte(a+{{49{ir[14]}},ir[14:0]},{8{b[7:0]}});
	`SC:	wb_store_byte(a+{{49{ir[14]}},ir[14:0]},{4{b[15:0]}});
	`SH:	wb_store_byte(a+{{49{ir[14]}},ir[14:0]},{2{b[31:0]}});
	`SW:	wb_store_byte(a+{{49{ir[14]}},ir[14:0]},b);
	endcase
end
endtask

endmodule

