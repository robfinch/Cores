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
module Thor(rst_i, clk_i, nmi_i, irq_i, );

reg [122:0] ir,xir;
reg [63:0] pc0,pc1,pc2;		// program counters
reg [3:0] panic;

reg [63:0] pc;					// instruction pointer
reg [63:0] bregs [0:15];		// branch target registers
reg [ 3:0] pregs [0:15];		// predicate registers
reg [63:12] sregs [0:15];		// segment registers
reg loadm1,loadm2;
reg pres0,pres1,pres2;
reg pv0,pv1,pv2;
wire [63:0] rfoa0,rfoa1,rfoa2;
wire [63:0] rfob0,rfob1,rfob2;
reg [6:0] xRt0,xRt1,xRt2;

wire clk = clk_i;

// Operand registers
reg [63:0] a0,b0,a1,b1,a2,b2;
wire take_branch;

reg [3:0] rf_source [0:287];

// instruction queue (ROB)
reg        iqentry_v  	[0:7];	// entry valid?  -- this should be the first bit
reg        iqentry_out	[0:7];	// instruction has been issued to an ALU ... 
reg        iqentry_done	[0:7];	// instruction result valid
reg        iqentry_bt  	[0:7];	// branch-taken (used only for branches)
reg        iqentry_agen [0:7];	// address-generate ... signifies that address is ready (only for LW/SW)
reg        iqentry_mem	[0:7];	// touches memory: 1 if LW/SW
reg        iqentry_jmp	[0:7];	// changes control flow: 1 if BEQ/JALR
reg        iqentry_rfw	[0:7];	// writes to register file
reg        iqentry_pfw  [0:7];  // writes to predicate register file
reg        iqentry_bfw  [0:7];  // writes to branch regiser file
reg [63:0] iqentry_res	[0:7];	// instruction result
reg  [6:0] iqentry_op	[0:7];	// instruction opcode
reg  [3:0] iqentry_exc	[0:7];	// only for branches ... indicates a HALT instruction
reg  [6:0] iqentry_tgt	[0:7];	// Rt field or ZERO -- this is the instruction's target (if any)
reg  [3:0] iqentry_ptgt [0:7];	// Pt field - target predicate register
reg  [3:0] iqentry_btgt [0:7];  // Bt field - target branch register
reg  [3:0] iqentry_p    [0:7];  // predicate argument
reg        iqentry_p_v  [0:7];  // predicate argument valid
reg  [3:0] iqentry_p_s  [0:7];  // predicate source
reg [63:0] iqentry_b    [0:7];  // branch register value
reg        iqentry_b_v  [0:7];  // branch register argument valid
reg  [3:0] iqentry_b_s  [0:7];  // branch register source
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
wire  [7:0] iqentry_issue;
wire  [1:0] iqentry_0_islot;
wire  [1:0] iqentry_1_islot;
wire  [1:0] iqentry_2_islot;
wire  [1:0] iqentry_3_islot;
wire  [1:0] iqentry_4_islot;
wire  [1:0] iqentry_5_islot;
wire  [1:0] iqentry_6_islot;
wire  [1:0] iqentry_7_islot;
reg [1:0] iqentry_islot[0:7];

reg   [287:1] livetarget;
wire  [287:1] iqentry_0_livetarget;
wire  [287:1] iqentry_1_livetarget;
wire  [287:1] iqentry_2_livetarget;
wire  [287:1] iqentry_3_livetarget;
wire  [287:1] iqentry_4_livetarget;
wire  [287:1] iqentry_5_livetarget;
wire  [287:1] iqentry_6_livetarget;
wire  [287:1] iqentry_7_livetarget;
wire  [287:1] iqentry_0_latestID;
wire  [287:1] iqentry_1_latestID;
wire  [287:1] iqentry_2_latestID;
wire  [287:1] iqentry_3_latestID;
wire  [287:1] iqentry_4_latestID;
wire  [287:1] iqentry_5_latestID;
wire  [287:1] iqentry_6_latestID;
wire  [287:1] iqentry_7_latestID;
wire  [287:1] iqentry_0_cumulative;
wire  [287:1] iqentry_1_cumulative;
wire  [287:1] iqentry_2_cumulative;
wire  [287:1] iqentry_3_cumulative;
wire  [287:1] iqentry_4_cumulative;
wire  [287:1] iqentry_5_cumulative;
wire  [287:1] iqentry_6_cumulative;
wire  [287:1] iqentry_7_cumulative;


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
wire        fetchbuf0_bfw;
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
reg  [6:0] alu0_op;
reg        alu0_bt;
reg [63:0] alu0_argA;
reg [63:0] alu0_argB;
reg [63:0] alu0_argI;	// only used by BEQ
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
reg  [6:0] alu1_op;
reg        alu1_bt;
reg [63:0] alu1_argA;
reg [63:0] alu1_argB;
reg [63:0] alu1_argI;	// only used by BEQ
reg [63:0] alu1_pc;
wire [63:0] alu1_bus;
wire  [3:0] alu1_id;
wire  [3:0] alu1_exc;
wire        alu1_v;
wire        alu1_branchmiss;
wire [63:0] alu1_misspc;

wire        branchback;
wire [63:0] backpc;
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

Thor_livetarget ultgt1 (
	iqentry_v,
	iqentry_stomp,
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

assign iqentry_0_latestID = (missid == 3'd0 || ((iqentry_0_livetarget & iqentry_1_cumulative) == 287'd0))
				? iqentry_0_livetarget
				: 287'd0;
assign iqentry_0_cumulative = (missid == 3'd0)
				? iqentry_0_livetarget
				: iqentry_0_livetarget | iqentry_1_cumulative;

assign iqentry_1_latestID = (missid == 3'd1 || ((iqentry_1_livetarget & iqentry_2_cumulative) == 287'd0))
				? iqentry_1_livetarget
				: 287'd0;
assign iqentry_1_cumulative = (missid == 3'd1)
				? iqentry_1_livetarget
				: iqentry_1_livetarget | iqentry_2_cumulative;

assign iqentry_2_latestID = (missid == 3'd2 || ((iqentry_2_livetarget & iqentry_3_cumulative) == 287'd0))
				? iqentry_2_livetarget
				: 287'd0;
assign iqentry_2_cumulative = (missid == 3'd2)
				? iqentry_2_livetarget
				: iqentry_2_livetarget | iqentry_3_cumulative;

assign iqentry_3_latestID = (missid == 3'd3 || ((iqentry_3_livetarget & iqentry_4_cumulative) == 287'd0))
				? iqentry_3_livetarget
				: 287'd0;
assign iqentry_3_cumulative = (missid == 3'd3)
				? iqentry_3_livetarget
				: iqentry_3_livetarget | iqentry_4_cumulative;

assign iqentry_4_latestID = (missid == 3'd4 || ((iqentry_4_livetarget & iqentry_5_cumulative) == 287'd0))
				? iqentry_4_livetarget
				: 287'd0;
assign iqentry_4_cumulative = (missid == 3'd4)
				? iqentry_4_livetarget
				: iqentry_4_livetarget | iqentry_5_cumulative;

assign iqentry_5_latestID = (missid == 3'd5 || ((iqentry_5_livetarget & iqentry_6_cumulative) == 287'd0))
				? iqentry_5_livetarget
				: 287'd0;
assign iqentry_5_cumulative = (missid == 3'd5)
				? iqentry_5_livetarget
				: iqentry_5_livetarget | iqentry_6_cumulative;

assign iqentry_6_latestID = (missid == 3'd6 || ((iqentry_6_livetarget & iqentry_7_cumulative) == 287'd0))
				? iqentry_6_livetarget
				: 287'd0;
assign iqentry_6_cumulative = (missid == 3'd6)
				? iqentry_6_livetarget
				: iqentry_6_livetarget | iqentry_7_cumulative;

assign iqentry_7_latestID = (missid == 3'd7 || ((iqentry_7_livetarget & iqentry_0_cumulative) == 287'd0))
				? iqentry_7_livetarget
				: 287'd0;
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


wire [7:0] Ra0 = fetchbuf0_instr[`INSTRUCTION_RA];
wire [7:0] Rb0 = fetchbuf0_instr[`INSTRUCTION_RB];
wire [7:0] Ra1 = fetchbuf1_instr[`INSTRUCTION_RA];
wire [7:0] Rb1 = fetchbuf1_instr[`INSTRUCTION_RB];

wire [63:0] rfoa0,rfob0;
wire [63:0] rfoa1,rfob1;

Thor_regfile2w4r
(
	.clk(clk),
	.wr0(commit0_v & ~commit0_tgt[8]),
	.wr1(commit1_v & ~commit1_tgt[8]),
	.wa0(commit0_tgt),
	.wa1(commit1_tgt),
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
	if (commit0_v && commit0_tgt[8:4]==5'h00)
		pregs[commit0_tgt[3:0]] <= commit0_bus[3:0];
	if (commit1_v && commit1_tgt[8:4]==5'h00)
		pregs[commit1_tgt[3:0]] <= commit1_bus[3:0];
end

always @(posedge clk)
begin
	if (commit0_v && commit0_tgt[8:4]==5'h01)
		bregs[commit0_tgt[3:0]] <= commit0_bus;
	if (commit1_v && commit1_tgt[8:4]==5'h01)
		bregs[commit1_tgt[3:0]] <= commit1_bus;
end

//
// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function source1_v;
input [41:0] insn;
	case(insn[`INSTRUCTION_OP])
	`RR:
		case(insn[`INSTRUCTION_FN])
		`ADD:	source1_v = 0;
		`SUB:	source1_v = 0;
		`AND:	source1_v = 0;
		`OR:	source1_v = 0;
		`EOR:	source1_v = 0;
		default:	source1_v = 0;
		endcase
	`ADDI:	source1_v = 0;
	`SUBI:	source1_v = 0;
	`ANDI:	source1_v = 0;
	`ORI:	source1_v = 0;
	`EORI:	source1_v = 0;
	default:	source1_v = 0;
	endcase
endfunction

//
// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function source2_v;
input [41:0] insn;
	case(insn[`INSTRUCTION_OP])
	`RR:
		case(insn[`INSTRUCTION_FN])
		`ADD:	source2_v = 0;
		`SUB:	source2_v = 0;
		`AND:	source2_v = 0;
		`OR:	source2_v = 0;
		`EOR:	source2_v = 0;
		default:	source2_v = 1;
		endcase
	`ADDI:	source2_v = 1;
	`SUBI:	source2_v = 1;
	`ANDI:	source2_v = 1;
	`ORI:	source2_v = 1;
	`EORI:	source2_v = 1;
	default:	source2_v = 1;
	endcase
endfunction

function fnIsBranch;
input [6:0] opcode;
case(opcode)
`BR:	fnIsBranch = `TRUE;
endcase
endfunction

task tskIncFetchbuf;
begin
	fetchbuf <= fetchbuf + ~iqentry_v[tail0];
end
endtask

wire [5:0] xopcode0 = xir[40:35];
wire [5:0] xopcode1 = xir[81:76];
wire [5:0] xopcode2 = xir[122:117];

// Template decoding
wire [4:0] itemplate = insn[127:123];
reg [4:0] dtemplate;
reg [4:0] xtemplate;
wire xisInt0 = xtemplate <= 5'h0d;
wire xisInt1 = 	xtemplate==5'd00 || xtemplate==5'd01 || xtemplate==5'd02 ||
				xtemplate==5'd06 || xtemplate==5'h10 || xtemplate==5'h11;
wire xisCmp0 = xir[34] & xisInt0;
wire xisCmp1 = xir[75] & xisInt1;
wire i0isBranch = itemplate[4];
wire i1isBranch = itemplate==5'h12 || itemplate==5'h13 || itemplate==5'h16 || itemplate==5'h17;
wire i2isBranch = itemplate==5'h16 || itemplate==5'h17;
wire x0isBranch = xtemplate[4];
wire x1isBranch = xtemplate==5'h12 || xtemplate==5'h13 || xtemplate==5'h16 || xtemplate==5'h17;
wire x2isBranch = xtemplate==5'h16 || xtemplate==5'h17;

m_cmp ucmp1(xopcode0,a0,b0,imm0,pv0);
m_cmp ucmp2(xopcode1,a1,b1,imm1,pv1);

wire [5:0] prn0 = xir[40:35];
wire [5:0] prn1 = xir[81:76];
wire [5:0] prn2 = xir[122:117];
wire [5:0] prt0 = xir[21:16];
wire [5:0] prt1 = xir[62:57];
wire [5:0] prt2 = xir[103:98];

wire [6:0] Ra0 = fetchbuf0_instr[`INSTRUCTION_RA];
wire [6:0] Ra1 = fetchbuf1_instr[`INSTRUCTION_RA];
wire [6:0] Ra2 = fetchbuf2_instr[`INSTRUCTION_RA];
wire [6:0] Rb0 = fetchbuf0_instr[`INSTRUCTION_RB];
wire [6:0] Rb1 = fetchbuf1_instr[`INSTRUCTION_RB];
wire [6:0] Rb2 = fetchbuf2_instr[`INSTRUCTION_RB];

// Predicates with forwarding
wire pr0 = prn0==6'd0 ? 1'b0 : prn0==6'd1 ? 1'b1 : xisCmp1 ? pv1 : xisCmp0 ? pv0 : pr[prn0];
wire pr1 = prn1==6'd0 ? 1'b0 : prn1==6'd1 ? 1'b1 : xisCmp1 ? pv1 : xisCmp0 ? pv0 : pr[prn1];
wire pr2 = prn2==6'd0 ? 1'b0 : prn2==6'd1 ? 1'b1 : xisCmp1 ? pv1 : xisCmp0 ? pv0 : pr[prn2];

wire takb0 = (x0isBranch & pr0);
wire takb1 = (x1isBranch & pr1) & !takb0;
wire takb2 = (x2isBranch & pr2) & !takb0 & !takb1;

wire predict_takenA,predict_takenB,predict_takenC,predict_takenD;

Thor_BranchHistory ubhtA
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(advanceX),
	.xisBranch(x0isBranch),
	.pc(pc[63:4]),
	.xpc(xpc[63:4]),
	.takb(takbA),
	.predict_taken(predict_takenA)
);

Thor_BranchHistory ubhtB
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(advanceX),
	.xisBranch(x1isBranch),
	.ip(ip[57:4]),
	.xip(ip[57:4]),
	.takb(takbB),
	.predict_taken(predict_takenB)
);

Thor_BranchHistory ubhtC
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(advanceX),
	.xisBranch(x2isBranch),
	.ip(ip[57:4]),
	.xip(ip[57:4]),
	.takb(takbC),
	.predict_taken(predict_takenC)
);

Thor_BranchHistory ubhtD
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(advanceX),
	.xisBranch(x2isBranch),
	.ip(ip[57:4]),
	.xip(ip[57:4]),
	.takb(takbD),
	.predict_taken(predict_takenD)
);


function [8:0] fnTargetReg;
input [63:0] ir;
begin
	// Set target register
	case(opcode)
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
		fnTargetReg = {1'b0,Ra};
	`CMP,`CMPI,`TST:
		fnTargetReg = {1'b1,4'h0,ir[11:8]};
	`JSR,`SYS,`INT:
		fnTargetReg = {1'b1,4'h1,ir[19:16]};
	default:	fnTargetReg = 9'h00;
	endcase
end
endfunction

function fnHasConst;
input [7:0] opcode;
	case(opcode)
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

wire advanceI = advanceR & ihit;

function [63:0] fnIpInc;
input [63:0] ip;
begin
	fnIpInc = {ip[63:4] + 60'd1,4'b0000};
end
endfunction

assign fetchbuf0_instr = (fetchbuf == 1'b0) ? fetchbufA_instr : fetchbufD_instr;
assign fetchbuf0_v     = (fetchbuf == 1'b0) ? fetchbufA_v     : fetchbufD_v    ;
assign fetchbuf0_pc    = (fetchbuf == 1'b0) ? fetchbufA_pc    : fetchbufD_pc   ;
assign fetchbuf1_instr = (fetchbuf == 1'b0) ? fetchbufB_instr : fetchbufE_instr;
assign fetchbuf1_v     = (fetchbuf == 1'b0) ? fetchbufB_v     : fetchbufE_v    ;
assign fetchbuf1_pc    = (fetchbuf == 1'b0) ? fetchbufB_pc    : fetchbufE_pc   ;
assign fetchbuf2_instr = (fetchbuf == 1'b0) ? fetchbufC_instr : fetchbufF_instr;
assign fetchbuf2_v     = (fetchbuf == 1'b0) ? fetchbufC_v     : fetchbufF_v    ;
assign fetchbuf2_pc    = (fetchbuf == 1'b0) ? fetchbufC_pc    : fetchbufF_pc   ;

wire [6:0] opcodeA = fetchbufA_instr[`INSTRUCTION_OP];
wire [6:0] opcodeB = fetchbufB_instr[`INSTRUCTION_OP];
wire [6:0] opcodeC = fetchbufC_instr[`INSTRUCTION_OP];
wire [6:0] opcodeD = fetchbufD_instr[`INSTRUCTION_OP];
wire [6:0] opcodeE = fetchbufE_instr[`INSTRUCTION_OP];
wire [6:0] opcodeF = fetchbufF_instr[`INSTRUCTION_OP];

wire [6:0] opcode0 = fetchbuf ? opcodeD : opcodeA;
wire [6:0] opcode1 = fetchbuf ? opcodeE : opcodeB;
wire [6:0] opcode2 = fetchbuf ? opcodeF : opcodeC;

function fnIsMem;
input [6:0] opcode;
fnIsMem = 	opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW ||
			opcode==`SB || opcode==`SC || opcode==`SH || opcode==`SW
			;
endfunction

// Determines which instruction write to the register file
function fnIsRFW;
input [7:0] opcode;
input [6:0] func;
fnIsRFW =	opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW ||
			opcode==`ADDI || opcode==`SUBI || opcode==`ADDUI || opcode==`SUBUI ||
			opcode==`ANDI || opcode==`ORI || opcode==`EORI ||
			(opcode==`RR && (
				func==`ADD || func==`SUB || func==`ADDU || func==`SUBU ||
				func==`AND || func==`OR || func==`EOR || func==`NAND || func==`NOR || func==`ENOR || func==`ANDC || func==`ORC ||
				func==`SHL || func==`SHR || func==`SHLU || func==`SHRU || func==`ROL || func==`ROR
			)) ||
			(opcode==`R && (
				func==`NOT || func==`NEG || func==`ABS || func==`SGN
			))
			;
endfunction

function fnIsStore;
input [7:0] opcode;
fnIsStore = 	opcode==`SB || opcode==`SC || opcode==`SH || opcode==`SW;
endfunction

function fnIsPFW;
input [7:0] opcode;
fnIsPFW =	opcode==`CMP || opcode==`CMPI || opcode==`TST;
endfunction

assign fetchbuf0_mem	= fetchbuf ? fnIsMem(opcodeC) : fnIsMem(opcodeA);
assign fetchbuf1_mem	= fetchbuf ? fnIsMem(opcodeD) : fnIsMem(opcodeB);

assign fetchbuf0_jmp   = (fetchbuf == 1'b0)
			? (fetchbufA_instr[`INSTRUCTION_OP] == `BEQ || fetchbufA_instr[`INSTRUCTION_OP] == `JALR)
			: (fetchbufC_instr[`INSTRUCTION_OP] == `BEQ || fetchbufC_instr[`INSTRUCTION_OP] == `JALR);

assign fetchbuf0_rfw	= fetchbuf ? fnIsRFW(opcodeC,funcC) : fnIsRWF(opcodeA,funcA);
assign fetchbuf1_rfw	= fetchbuf ? fnIsRFW(opcodeD,funcD) : fnIsRWF(opcodeB,funcB);
assign fetchbuf0_pfw	= fetchbuf ? fnIsPFW(opcodeC) : fnIsPFW(opcodeA);
assign fetchbuf1_pfw    = fetchbuf ? fnIsPFW(opcodeD) : fnIsPFW(opcodeB);

//
// set branchback and backpc values ... ignore branches in fetchbuf slots not ready for enqueue yet
//
assign take_branch =
		({fetchbuf0_v, fnIsBranch(fetchbuf0_instr[`INSTRUCTION_OP]), predict_taken0}  == {`VAL, `TRUE, `TRUE}) ||
		({fetchbuf1_v, fnIsBranch(fetchbuf1_instr[`INSTRUCTION_OP]), predict_taken1}  == {`VAL, `TRUE, `TRUE}) ||
		({fetchbuf2_v, fnIsBranch(fetchbuf2_instr[`INSTRUCTION_OP]), predict_taken2}  == {`VAL, `TRUE, `TRUE})
		;
assign branch_pc =
		({fetchbuf0_v, fnIsBranch(fetchbuf0_instr[`INSTRUCTION_OP]), predict_taken0}  == {`VAL, `TRUE, `TRUE}) ? 
			fetchbuf0_pc + fetchbuf0_instr[, fetchbuf0_instr[1:0]}
			(({fetchbuf0_v, fetchbuf0_instr[`INSTRUCTION_OP], fetchbuf0_instr[`INSTRUCTION_SB]} == {`VAL, `BEQ, `BACK_BRANCH}) 
			? (fetchbuf0_pc + 1 + { {9 {fetchbuf0_instr[`INSTRUCTION_SB]}}, fetchbuf0_instr[`INSTRUCTION_IM]})
			: (fetchbuf1_pc + 1 + { {9 {fetchbuf1_instr[`INSTRUCTION_SB]}}, fetchbuf1_instr[`INSTRUCTION_IM]}));

wire [127:0] insn0 = insn;
reg [127:0] insn1;
reg [127:0] insn2;
reg [127:0] insn3;

always @(insn)
	case(fnInsnLength(insn))
	4'd1:	insn1 <= insn[127: 8];
	4'd2:	insn1 <= insn[127:16];
	4'd3:	insn1 <= insn[127:24];
	4'd4:	insn1 <= insn[127:32];
	4'd5:	insn1 <= insn[127:40];
	4'd6:	insn1 <= insn[127:48];
	4'd7:	insn1 <= insn[127:56];
	4'd8:	insn1 <= insn[127:64];
	default:	insn1 <= {16{8'h10}};	// NOPs
	endcase
always @(insn)
	case(fnInsnLength(insn)+fnInsnLength1(insn))
	5'd2:	insn2 <= insn[127:16];
	5'd3:	insn2 <= insn[127:24];
	5'd4:	insn2 <= insn[127:32];
	5'd5:	insn2 <= insn[127:40];
	5'd6:	insn2 <= insn[127:48];
	5'd7:	insn2 <= insn[127:56];
	5'd8:	insn2 <= insn[127:64];
	5'd9:	insn2 <= insn[127:72];
	5'd10:	insn2 <= insn[127:80];
	5'd11:	insn2 <= insn[127:88];
	5'd12:	insn2 <= insn[127:96];
	5'd13:	insn2 <= insn[127:104];
	5'd14:	insn2 <= insn[127:112];
	5'd15:	insn2 <= insn[127:120];
	default:	insn2 <= {16{8'h10}};	// NOPs
	endcase
always @(insn)
	case(fnInsnLength(insn)+fnInsnLength1(insn)+fnInsnLength2(insn))
	5'd3:	insn3 <= insn[127:24];
	5'd4:	insn3 <= insn[127:32];
	5'd5:	insn3 <= insn[127:40];
	5'd6:	insn3 <= insn[127:48];
	5'd7:	insn3 <= insn[127:56];
	5'd8:	insn3 <= insn[127:64];
	5'd9:	insn3 <= insn[127:72];
	5'd10:	insn3 <= insn[127:80];
	5'd11:	insn3 <= insn[127:88];
	5'd12:	insn3 <= insn[127:96];
	5'd13:	insn3 <= insn[127:104];
	5'd14:	insn3 <= insn[127:112];
	5'd15:	insn3 <= insn[127:120];
	default:	insn3 <= {16{8'h10}};	// NOPs
	endcase

function [7:0] fnImm;
input [127:0] insn;

case(insn[15:8])
`LOOP,`BR:
	fnImm <= insn[23:16];
`SYS,`JSR,`INT,`CMPI,`BSR:
	fnImm <= insn[31:24];
default:
	fnImm <= insn[39:32];
endcase

endfunction

// Return MSB of immediate value for instruction
function fnImmMSB;
input [127:0] insn;

case(insn[15:8])
`LOOP,`BR:
	fnImmMSB <= insn[23];
`SYS,`JSR,`INT,`CMPI,`BSR:
	fnImmMSB <= insn[31];
default:
	fnImmMSB <= insn[39];
endcase

endfunction

`include "Thor_issue_combo.v"
`include "Thor_execute_combo.v"
`include "Thor_memory_combo.v"
`include "Thor_commit_combo.v"

//
// FETCH
//
// fetch exactly two instructions from memory into the fetch buffer
// unless either one of the buffers is still full, in which case we
// do nothing (kinda like alpha approach)
//
always @(posedge clk) begin

	if (rst) begin
		for (i=0; i<8; i=i+1) begin
			iqentry_v[i] <= `INV;
		end
	end
	
	did_branchback <= branchback;

	if (branchmiss) begin
	    pc <= misspc;
	    fetchbuf <= 1'b0;
	    fetchbufA_v <= 1'b0;
	    fetchbufB_v <= 1'b0;
	    fetchbufC_v <= 1'b0;
	    fetchbufD_v <= 1'b0;

		for (n = 1; n < 288; n = n + 1)
			if (rf_v[n] == `INV && ~livetarget[n]) rf_v[n] <= `VAL;

	    if (|iqentry_0_latestID)	rf_source[ iqentry_tgt[0] ] <= { iqentry_mem[0], 3'd0 };
	    if (|iqentry_1_latestID)	rf_source[ iqentry_tgt[1] ] <= { iqentry_mem[1], 3'd1 };
	    if (|iqentry_2_latestID)	rf_source[ iqentry_tgt[2] ] <= { iqentry_mem[2], 3'd2 };
	    if (|iqentry_3_latestID)	rf_source[ iqentry_tgt[3] ] <= { iqentry_mem[3], 3'd3 };
	    if (|iqentry_4_latestID)	rf_source[ iqentry_tgt[4] ] <= { iqentry_mem[4], 3'd4 };
	    if (|iqentry_5_latestID)	rf_source[ iqentry_tgt[5] ] <= { iqentry_mem[5], 3'd5 };
	    if (|iqentry_6_latestID)	rf_source[ iqentry_tgt[6] ] <= { iqentry_mem[6], 3'd6 };
	    if (|iqentry_7_latestID)	rf_source[ iqentry_tgt[7] ] <= { iqentry_mem[7], 3'd7 };

	end

`include "Thor_ifetch.v"

    //
    // ENQUEUE
    //
    // place up to three instructions from the fetch buffer into slots in the IQ.
    //   note: they are placed in-order, and they are expected to be executed
    // 0, 1, or 2 of the fetch buffers may have valid data
    // 0, 1, or 2 slots in the instruction queue may be available.
    // if we notice that one of the instructions in the fetch buffer is a backwards branch,
    // predict it taken (set branchback/backpc and delete any instructions after it in fetchbuf)
    //

	//
	// COMMIT PHASE (register-file update only ... dequeue is elsewhere)
	//
	// look at head0 and head1 and let 'em write the register file if they are ready
	//
	// why is it happening here and not in another phase?
	// want to emulate a pass-through register file ... i.e. if we are reading
	// out of r3 while writing to r3, the value read is the value written.
	// requires BLOCKING assignments, so that we can read from rf[i] later.
	//
	if (commit0_v) begin
	    if (!rf_v[ commit0_tgt ]) 
			rf_v[ commit0_tgt ] <= rf_source[ commit0_tgt ] == commit0_id || (branchmiss && iqentry_source[ commit0_id[2:0] ]);
	    if (commit0_tgt != 7'd0) $display("r%d <- %h", commit0_tgt, commit0_bus);
	end
	if (commit1_v) begin
	    if (!rf_v[ commit1_tgt ]) 
			rf_v[ commit1_tgt ] <= rf_source[ commit1_tgt ] == commit1_id || (branchmiss && iqentry_source[ commit1_id[2:0] ]);
	    if (commit1_tgt != 7'd0) $display("r%d <- %h", commit1_tgt, commit1_bus);
	end

	rf_v[0] <= 1'b1;

`include "Thor_enque.v"
`include "Thor_dataincoming.v"
`include "Thor_issue.v"
`include "Thor_memory.v"
`include "Thor_commit.v"
    end

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
	`SW:	wb_store_byte(a+{{49{ir[14]}},ir[14:0]},b});
	endcase
end
endtask

endmodule

always @*
begin
	pv <= opcode[4] ? fnCmp(opcode[3:0],lt,ltu,eq) : fnCmp(opcode[3:0],lti,ltui,eqi);
end
endmodule

function [3:0] fnInsnLength;
input [127:0] insn;
casex(insn[15:0])
16'bxxxxxxxx00000000:	fnInsnLength = 4'd1;
16'bxxxxxxxx00010000:	fnInsnLength = 4'd1;
16'hxxxxxxxx00100000:	fnInsnLength = 4'd2;
16'hxxxxxxxx00110000:	fnInsnLength = 4'd3;
16'hxxxxxxxx01000000:	fnInsnLength = 4'd4;
16'hxxxxxxxx01010000:	fnInsnLength = 4'd5;
16'hxxxxxxxx01100000:	fnInsnLength = 4'd6;
16'hxxxxxxxx01110000:	fnInsnLength = 4'd7;
16'hxxxxxxxx10000000:	fnInsnLength = 4'd8;
16'hxxxxxxxx10010000:
	case(opcode[15:8])
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

function [4:0] fnInsnLength2;
input [127:0] insn;
begin
	case(fnInsnLength(insn)+fnInsnLength1(insn))
	5'd2:	fnInsnLength2 = fnInsnLength(insn[127:16]);
	5'd3:	fnInsnLength2 = fnInsnLength(insn[127:24]);
	5'd4:	fnInsnLength2 = fnInsnLength(insn[127:32]);
	5'd5:	fnInsnLength2 = fnInsnLength(insn[127:40]);
	5'd6:	fnInsnLength2 = fnInsnLength(insn[127:48]);
	5'd7:	fnInsnLength2 = fnInsnLength(insn[127:56]);
	5'd8:	fnInsnLength2 = fnInsnLength(insn[127:64]);
	5'd9:	fnInsnLength2 = fnInsnLength(insn[127:72]);
	5'd10:	fnInsnLength2 = fnInsnLength(insn[127:80]);
	5'd11:	fnInsnLength2 = fnInsnLength(insn[127:88]);
	5'd12:	fnInsnLength2 = fnInsnLength(insn[127:96]);
	5'd13:	fnInsnLength2 = fnInsnLength(insn[127:104]);
	5'd14:	fnInsnLength2 = fnInsnLength(insn[127:112]);
	// Use the ADD instruction to force a length > 1 unless predicate 00 or 01 is present
	5'd15:	fnInsnLength2 = fnInsnLength({8'h40,insn[127:120]});
	default:	fnInsnLength2 = 5'd0;
	endcase
	if (fnInsnLength2+fnInsnLength(insn)+fnInsnLength1(insn) > 5'd15)
		fnInsnLength2 = 5'd0;
end
endfunction

function [4:0] fnInsnLength3;
input [127:0] insn;
begin
	case(fnInsnLength(insn)+fnInsnLength1(insn) + fnInsnLength2(insn))
	5'd3:	fnInsnLength3 = fnInsnLength(insn[127:24]);
	5'd4:	fnInsnLength3 = fnInsnLength(insn[127:32]);
	5'd5:	fnInsnLength3 = fnInsnLength(insn[127:40]);
	5'd6:	fnInsnLength3 = fnInsnLength(insn[127:48]);
	5'd7:	fnInsnLength3 = fnInsnLength(insn[127:56]);
	5'd8:	fnInsnLength3 = fnInsnLength(insn[127:64]);
	5'd9:	fnInsnLength3 = fnInsnLength(insn[127:72]);
	5'd10:	fnInsnLength3 = fnInsnLength(insn[127:80]);
	5'd11:	fnInsnLength3 = fnInsnLength(insn[127:88]);
	5'd12:	fnInsnLength3 = fnInsnLength(insn[127:96]);
	5'd13:	fnInsnLength3 = fnInsnLength(insn[127:104]);
	5'd14:	fnInsnLength3 = fnInsnLength(insn[127:112]);
	// Use the ADD instruction to force a length > 1 unless predicate 00 or 01 is present
	5'd15:	fnInsnLength3 = fnInsnLength({8'h40,insn[127:120]});
	default:	fnInsnLength3 = 5'd0;
	endcase
	if (fnInsnLength3+fnInsnLength(insn)+fnInsnLength1(insn)+fnInsnLength2(insn) > 5'd15)
		fnInsnLength3 = 5'd0;
end
endfunction

