//
//	COPYRIGHT 2000 by Bruce L. Jacob
//	(contact info: http://www.ece.umd.edu/~blj/)
//
//	You are welcome to use, modify, copy, and/or redistribute this implementation, provided:
//	  1. you share with the author (Bruce Jacob) any changes you make;
//	  2. you properly credit the author (Bruce Jacob) if used within a larger work; and
//	  3. you do not modify, delete, or in any way obscure the implementation's copyright 
//	     notice or following comments (i.e. the first 3-4 dozen lines of this file).
//
//	RiSC-16
//
//	This is an out-of-order implementation of the RiSC-16, a teaching instruction-set used by
//	the author at the University of Maryland, and which is a blatant (but sanctioned) rip-off
//	of the Little Computer (LC-896) developed by Peter Chen at the University of Michigan.
//	The primary differences include the following:
//	  1. a move from 17-bit to 16-bit instructions; and
//	  2. the replacement of the NOP and HALT opcodes by ADDI and LUI ... HALT and NOP are
//	     now simply special instances of other instructions: NOP is a do-nothing ADD, and
//	     HALT is a subset of JALR.
//
//	RiSC stands for Ridiculously Simple Computer, which makes sense in the context in which
//	the instruction-set is normally used -- to teach simple organization and architecture to
//	undergraduates who do not yet know how computers work.  This implementation was targetted
//	towards more advanced undergraduates doing design & implementation and was intended to 
//	demonstrate some high-performance concepts on a small scale -- an 8-entry reorder buffer,
//	eight opcodes, two ALUs, two-way issue, two-way commit, etc.  However, the out-of-order 
//	core is much more complex than I anticipated, and I hope that its complexity does not 
//	obscure its underlying structure.  We'll see how well it flies in class ...
//
//	CAVEAT FREELOADER: This Verilog implementation was developed and debugged in a (somewhat
//	frantic) 2-week period before the start of the Fall 2000 semester.  Not surprisingly, it
//	still contains many bugs and some horrible, horrible logic.  The logic is also written so
//	as to be debuggable and/or explain its function, rather than to be efficient -- e.g. in
//	several places, signals are over-constrained so that they are easy to read in the debug
//	output ... also, you will see statements like
//
//	    if (xyz[`INSTRUCTION_OP] == `BEQ || xyz[`INSTRUCTION_OP] == `SW)
//
//	instead of and/nand combinations of bits ... sorry; can't be helped.  Use at your own risk.
//
//	DOCUMENTATION: Documents describing the RiSC-16 in all its forms (sequential, pipelined,
//	as well as out-of-order) can be found on the author's website at the following URL:
//
//	    http://www.ece.umd.edu/~blj/RiSC/
//
//	If you do not find what you are looking for, please feel free to email me with suggestions
//	for more/different/modified documents.  Same goes for bug fixes.
//
//
//	KNOWN PROBLEMS (i.e., bugs I haven't got around to fixing yet)
//
//	- If the target of a backwards branch is a backwards branch, the fetchbuf steering logic
//	  will get confused.  This can be fixed by having a separate did_branchback status register
//	  for each of the fetch buffers.
//
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
// This work is starting with the RiSC-16 as noted in the copyright statement
// above. Hopefully it will be possible to run this processor in real hardware
// (FPGA) as opposed to just simulation. To the RiSC-16 are added:
//
//	64/32 bit datapath rather than 16 bit
//  256 general purpose registers
//   16 branch registers
//   16 predicate registers / predicated instruction execution
//      A branch history table, and a (2,2) correlating branch predictor added
//      variable length instruction encodings (code density)
//      support for interrupts
//      The instruction set is changed completely with many new instructions.
//      An instruction cache was added.
//      A WISHBONE bus interface was added,
//
// ============================================================================
//
`include "Thor_defines.v"

module Thor(rst_i, clk_i, nmi_i, irq_i, vec_i, bte_o, cti_o, bl_o, cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter DBW = 32;
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
input [7:0] vec_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [4:0] bl_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
input err_i;
output reg we_o;
output reg [DBW/8-1:0] sel_o;
output reg [DBW-1:0] adr_o;
input [DBW-1:0] dat_i;
output reg [DBW-1:0] dat_o;

integer n,i;
reg [3:0] cstate;
reg [DBW-1:0] pc;				// program counter (virtual)
wire [DBW-1:0] ppc;				// physical pc address
reg [DBW-1:0] vadr;				// data virtual address
reg [3:0] panic;		// indexes the message structure
reg [128:0] message [0:15];	// indexed by panic
reg [DBW-1:0] bregs [0:15];		// branch target registers
reg [ 3:0] pregs [0:15];		// predicate registers
`ifdef SEGMENTATION
reg [DBW-1:12] sregs [0:15];		// segment registers
`endif
reg [DBW-1:0] miss_addr;
wire ITLBMiss;
wire DTLBMiss;
reg pwe;
wire [DBW-1:0] pea;
reg [DBW-1:0] tick;
reg [DBW-1:0] lc;				// loop counter
wire [DBW-1:0] rfoa0,rfoa1;
wire [DBW-1:0] rfob0,rfob1;
reg ic_invalidate;
reg ierr;						// err_i during icache load
wire insnerr;					// err_i during icache load
wire [127:0] insn;
reg [NREGS:0] rf_v;
//reg [15:0] pf_v;
reg im,imb;
reg nmi1,nmi_edge;
reg StatusHWI;
wire int_commit;
wire int_pending;
`ifdef SEGMENTATION
wire [DBW-1:0] spc = (pc[DBW-1:DBW-4]==4'hF) ? pc : {sregs[15],12'h000} + pc;
`else
wire [DBW-1:0] spc = pc;
`endif
wire [DBW-1:0] ppcp16 = ppc + 64'd16;
reg [DBW-1:0] string_pc;

wire clk = clk_i;

// Operand registers
wire take_branch;
wire take_branch0;
wire take_branch1;

reg [3:0] rf_source [0:NREGS];
//reg [3:0] pf_source [15:0];

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
reg [DBW-1:0] iqentry_res	[0:7];	// instruction result
reg  [3:0] iqentry_insnsz [0:7];	// the size of the instruction
reg  [3:0] iqentry_cond [0:7];	// predicating condition
reg  [3:0] iqentry_pred [0:7];	// predicate value
reg        iqentry_p_v  [0:7];	// predicate is valid
reg  [3:0] iqentry_p_s  [0:7];	// predicate source
reg  [7:0] iqentry_op	[0:7];	// instruction opcode
reg  [8:0] iqentry_tgt	[0:7];	// Rt field or ZERO -- this is the instruction's target (if any)
reg [DBW-1:0] iqentry_a0	[0:7];	// argument 0 (immediate)
reg [DBW-1:0] iqentry_a1	[0:7];	// argument 1
reg        iqentry_a1_v	[0:7];	// arg1 valid
reg  [3:0] iqentry_a1_s	[0:7];	// arg1 source (iq entry # with top bit representing ALU/DRAM bus)
reg [DBW-1:0] iqentry_a2	[0:7];	// argument 2
reg        iqentry_a2_v	[0:7];	// arg2 valid
reg  [3:0] iqentry_a2_s	[0:7];	// arg2 source (iq entry # with top bit representing ALU/DRAM bus)
reg [DBW-1:0] iqentry_a3	[0:7];	// argument 3
reg        iqentry_a3_v	[0:7];	// arg3 valid
reg  [3:0] iqentry_a3_s	[0:7];	// arg3 source (iq entry # with top bit representing ALU/DRAM bus)
reg [DBW-1:0] iqentry_pc	[0:7];	// program counter for this instruction

wire  [7:0] iqentry_source;
wire  [7:0] iqentry_imm;
wire  [7:0] iqentry_memready;
wire  [7:0] iqentry_memopsvalid;

wire stomp_all;
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
reg  [1:0] iqentry_islot[0:7];

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

reg  [63:0] fetchbuf0_instr;
reg  [DBW-1:0] fetchbuf0_pc;
reg         fetchbuf0_v;
wire        fetchbuf0_mem;
wire        fetchbuf0_jmp;
wire        fetchbuf0_rfw;
wire        fetchbuf0_pfw;
reg  [63:0] fetchbuf1_instr;
reg  [DBW-1:0] fetchbuf1_pc;
reg        fetchbuf1_v;
wire        fetchbuf1_mem;
wire        fetchbuf1_jmp;
wire        fetchbuf1_rfw;
wire        fetchbuf1_pfw;
wire        fetchbuf1_bfw;

reg [63:0] fetchbufA_instr;	
reg [DBW-1:0] fetchbufA_pc;
reg        fetchbufA_v;
reg [63:0] fetchbufB_instr;
reg [DBW-1:0] fetchbufB_pc;
reg        fetchbufB_v;
reg [63:0] fetchbufC_instr;
reg [DBW-1:0] fetchbufC_pc;
reg        fetchbufC_v;
reg [63:0] fetchbufD_instr;
reg [DBW-1:0] fetchbufD_pc;
reg        fetchbufD_v;

reg        did_branchback;
reg 		did_branchback0;
reg			did_branchback1;

reg        alu0_ld;
reg        alu0_available;
reg        alu0_dataready;
reg  [3:0] alu0_sourceid;
reg  [3:0] alu0_insnsz;
reg  [7:0] alu0_op;
reg  [3:0] alu0_cond;
reg        alu0_bt;
wire        alu0_cmt;
reg [DBW-1:0] alu0_argA;
reg [DBW-1:0] alu0_argB;
reg [DBW-1:0] alu0_argC;
reg [DBW-1:0] alu0_argI;
reg  [3:0] alu0_pred;
reg [DBW-1:0] alu0_pc;
wire [DBW-1:0] alu0_bus;
wire  [3:0] alu0_id;
wire  [3:0] alu0_exc;
wire        alu0_v;
wire        alu0_branchmiss;
wire [DBW-1:0] alu0_misspc;

reg        alu1_ld;
reg        alu1_available;
reg        alu1_dataready;
reg  [3:0] alu1_sourceid;
reg  [3:0] alu1_insnsz;
reg  [7:0] alu1_op;
reg  [3:0] alu1_cond;
reg        alu1_bt;
wire        alu1_cmt;
reg [DBW-1:0] alu1_argA;
reg [DBW-1:0] alu1_argB;
reg [DBW-1:0] alu1_argC;
reg [DBW-1:0] alu1_argI;
reg  [3:0] alu1_pred;
reg [DBW-1:0] alu1_pc;
wire [DBW-1:0] alu1_bus;
wire  [3:0] alu1_id;
wire  [3:0] alu1_exc;
wire        alu1_v;
wire        alu1_branchmiss;
wire [DBW-1:0] alu1_misspc;

wire        branchmiss;
wire [DBW-1:0] misspc;

wire        dram_avail;
reg	 [2:0] dram0;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [2:0] dram1;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [2:0] dram2;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg  [2:0] tlb_state;
reg [3:0] tlb_id;
reg [3:0] tlb_op;
reg [3:0] tlb_regno;
reg [8:0] tlb_tgt;
reg [DBW-1:0] tlb_data;

wire [DBW-1:0] tlb_dato;
reg [DBW-1:0] dram0_data;
reg [DBW-1:0] dram0_addr;
reg  [7:0] dram0_op;
reg  [8:0] dram0_tgt;
reg  [3:0] dram0_id;
reg  [3:0] dram0_exc;
reg [DBW-1:0] dram1_data;
reg [DBW-1:0] dram1_addr;
reg  [7:0] dram1_op;
reg  [8:0] dram1_tgt;
reg  [3:0] dram1_id;
reg  [3:0] dram1_exc;
reg [DBW-1:0] dram2_data;
reg [DBW-1:0] dram2_addr;
reg  [7:0] dram2_op;
reg  [8:0] dram2_tgt;
reg  [3:0] dram2_id;
reg  [3:0] dram2_exc;

reg [DBW-1:0] dram_bus;
reg  [8:0] dram_tgt;
reg  [3:0] dram_id;
reg  [3:0] dram_exc;
reg        dram_v;

wire        outstanding_stores;
reg [DBW-1:0] I;	// instruction count

wire        commit0_v;
wire  [3:0] commit0_id;
wire  [8:0] commit0_tgt;
wire [DBW-1:0] commit0_bus;
wire        commit1_v;
wire  [3:0] commit1_id;
wire  [8:0] commit1_tgt;
wire [DBW-1:0] commit1_bus;
wire limit_cmt;
wire committing2;

wire [63:0] alu0_divq;
wire [63:0] alu0_rem;
wire alu0_div_done;

wire [63:0] alu1_divq;
wire [63:0] alu1_rem;
wire alu1_div_done;

wire [127:0] alu0_prod;
wire alu0_mult_done;
wire [127:0] alu1_prod;
wire alu1_mult_done;

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


//assign iqentry_0_islot = iqentry_islot[0];
//assign iqentry_1_islot = iqentry_islot[1];
//assign iqentry_2_islot = iqentry_islot[2];
//assign iqentry_3_islot = iqentry_islot[3];
//assign iqentry_4_islot = iqentry_islot[4];
//assign iqentry_5_islot = iqentry_islot[5];
//assign iqentry_6_islot = iqentry_islot[6];
//assign iqentry_7_islot = iqentry_islot[7];

// A single instruction can require 3 read ports. Only a total of four read
// ports are supported because most of the time that's enough.
// If there aren't enough read ports available then the second instruction
// isn't enqueued (it'll be enqueued in the next cycle).
wire [8:0] Ra0 = fnRa(fetchbuf0_instr);
wire [8:0] Rb0 = ((fnNumReadPorts(fetchbuf0_instr) < 3'd2) || !fetchbuf0_v) ? {1'b0,fetchbuf1_instr[`INSTRUCTION_RC]} :
				{1'b0,fetchbuf0_instr[`INSTRUCTION_RB]};
wire [8:0] Ra1 = (!fetchbuf0_v || fnNumReadPorts(fetchbuf0_instr) < 3'd3) ? fnRa(fetchbuf1_instr) :
					fetchbuf0_instr[`INSTRUCTION_RC];
wire [8:0] Rb1 = (fnNumReadPorts(fetchbuf1_instr) < 3'd2 && fetchbuf0_v) ? fnRa(fetchbuf1_instr):{1'b0,fetchbuf1_instr[`INSTRUCTION_RB]};

function [7:0] fnOpcode;
input [63:0] ins;
fnOpcode = (ins[3:0]==4'h0 && ins[7:4] > 4'h1 && ins[7:4] < 4'h9) ? `IMM : 
						ins[7:0]==8'h10 ? `NOP :
						ins[7:0]==8'h11 ? `RTS : ins[15:8];
endfunction

wire [7:0] opcode0 = fnOpcode(fetchbuf0_instr);
wire [7:0] opcode1 = fnOpcode(fetchbuf1_instr);
wire [3:0] cond0 = fetchbuf0_instr[3:0];
wire [3:0] cond1 = fetchbuf1_instr[3:0];
wire [3:0] Pn1 = fetchbuf1_instr[7:4];
wire [3:0] Pn0 = fetchbuf0_instr[7:4];
wire [3:0] Pt1 = fetchbuf1_instr[11:8];
wire [3:0] Pt0 = fetchbuf0_instr[11:8];

function [8:0] fnRa;
input [63:0] insn;
if (insn[7:0]==8'h11)	// RTS short form
	fnRa = 9'h111;
else
	case(insn[15:8])
	`RTI:	fnRa = 9'h11E;
	`RTE:	fnRa = 9'h11D;
	`JSR,`SYS,`INT,`RTS:
		fnRa = {5'h11,insn[23:20]};
	default:	fnRa = {1'b0,insn[`INSTRUCTION_RA]};
	endcase
endfunction

function [8:0] fnRb;
input [63:0] insn;
if (insn[7:0]==8'h11)	// RTS short form
	fnRb = 9'h111;
else
	case(insn[15:8])
	`RTI:	fnRb = 9'h11E;
	`RTE:	fnRb = 9'h11D;
	`JSR,`SYS,`INT,`RTS:
		fnRb = {5'h11,insn[23:20]};
	default:	fnRb = {1'b0,insn[`INSTRUCTION_RB]};
	endcase
endfunction

function [3:0] fnBra;
input [63:0] insn;
if (insn[7:0]==8'h11)	// RTS short form
	fnBra = 4'h1;
else
	case(insn[15:8])
	`RTI:	fnBra = 4'hE;
	`RTE:	fnBra = 4'hD;
	`JSR,`SYS,`INT,`RTS:
		fnBra = {insn[23:20]};
	default:	fnBra = 4'h0;
	endcase
endfunction


Thor_regfile2w4r #(DBW) urf1
(
	.clk(clk),
	.rclk(~clk),
	.wr0(commit0_v & ~commit0_tgt[8]),
	.wr1(commit1_v & ~commit1_tgt[8]),
	.wa0(commit0_tgt[7:0]),
	.wa1(commit1_tgt[7:0]),
	.ra0(Ra0[7:0]),
	.ra1(Rb0[7:0]),
	.ra2(Ra1[7:0]),
	.ra3(Rb1[7:0]),
	.i0(commit0_bus),
	.i1(commit1_bus),
	.o0(rfoa0),
	.o1(rfob0),
	.o2(rfoa1),
	.o3(rfob1)
);

wire [63:0] bregs0 = fnBra(fetchbuf0_instr)==4'd0 ? 64'd0 : fnBra(fetchbuf0_instr)==4'hF ? fetchbuf0_pc : bregs[fnBra(fetchbuf0_instr)];
wire [63:0] bregs1 = fnBra(fetchbuf1_instr)==4'd0 ? 64'd0 : fnBra(fetchbuf1_instr)==4'hF ? fetchbuf1_pc : bregs[fnBra(fetchbuf1_instr)];

//
// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource1_v;
input [7:0] opcode;
	casex(opcode)
	`SEI,`CLI,`SYNC,`NOP:		fnSource1_v = 1'b1;
	`BR,`LOOP:		fnSource1_v = 1'b1;
	`LDI,`IMM:		fnSource1_v = 1'b1;
	`TLB:			fnSource1_v = 1'b1;
	default:		fnSource1_v = 1'b0;
	endcase
endfunction

//
// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource2_v;
input [7:0] opcode;
	casex(opcode)
	`NEG,`NOT:		fnSource2_v = 1'b1;
	`LDI,`IMM,`NOP:		fnSource2_v = 1'b1;
	`SEI,`CLI,`SYNC:	fnSource2_v = 1'b1;
	`RTI,`RTE:		fnSource2_v = 1'b1;
	`TST:			fnSource2_v = 1'b1;
	`ADDI,`ADDUI:	fnSource2_v = 1'b1;
	`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI:
					fnSource2_v = 1'b1;
	`SUBI,`SUBUI:	fnSource2_v = 1'b1;
	`CMPI:			fnSource2_v = 1'b1;
	`MULI,`MULUI,`DIVI,`DIVUI:
					fnSource2_v = 1'b1;
	`ANDI:			fnSource2_v = 1'b1;
	`ORI:			fnSource2_v = 1'b1;
	`EORI:			fnSource2_v = 1'b1;
	`SHLI,`SHLUI,`SHRI,`SHRUI,`ROLI,`RORI,
	`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW:
			fnSource2_v = 1'b1;
	`JSR,`SYS,`INT,`RTS,`BR,`LOOP:
			fnSource2_v = 1'b1;
	`MTSPR,`MFSPR:
				fnSource2_v = 1'b1;
	default:	fnSource2_v = 1'b0;
	endcase
endfunction

// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource3_v;
input [7:0] opcode;
	casex(opcode)
	`SBX,`SCX,`SHX,`SWX:	fnSource3_v = 1'b0;
	`MUX:	fnSource3_v = 1'b0;
	default:	fnSource3_v = 1'b1;
	endcase
endfunction

// Return the number of register read ports required for an instruction.
function [2:0] fnNumReadPorts;
input [63:0] ins;
case(fnOpcode(ins))
`SEI,`CLI,`SYNC,`NOP:	fnNumReadPorts = 3'd0;
`BR,`LOOP:				fnNumReadPorts = 3'd0;
`LDI,`IMM:				fnNumReadPorts = 3'd0;
`NEG,`NOT:				fnNumReadPorts = 3'd1;
`RTI,`RTE:			fnNumReadPorts = 3'd1;
`TST:				fnNumReadPorts = 3'd1;
`ADDI,`ADDUI:		fnNumReadPorts = 3'd1;
`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI:
					fnNumReadPorts = 3'd1;
`SUBI,`SUBUI:		fnNumReadPorts = 3'd1;
`CMPI:				fnNumReadPorts = 3'd1;
`MULI,`MULUI,`DIVI,`DIVUI:
					fnNumReadPorts = 3'd1;
`ANDI,`ORI,`EORI:	fnNumReadPorts = 3'd1;
`SHLI,`SHLUI,`SHRI,`SHRUI,`ROLI,`RORI:
					fnNumReadPorts = 3'd1;
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LVB,`LVC,`LVH,`LVW:
					fnNumReadPorts = 3'd1;
`JSR,`SYS,`INT,`RTS,`BR,`LOOP:
					fnNumReadPorts = 3'd1;
`SBX,`SCX,`SHX,`SWX,
`MUX:
					fnNumReadPorts = 3'd3;
`MTSPR,`MFSPR:		fnNumReadPorts = 3'd1;
`TLB:				fnNumReadPorts = 3'd2;	// *** TLB reads on Rb we say 2 for simplicity
default:			fnNumReadPorts = 3'd2;
endcase
endfunction

function fnIsBranch;
input [7:0] opcode;
casex(opcode)
`BR:	fnIsBranch = `TRUE;
default:	fnIsBranch = `FALSE;
endcase
endfunction

function fnIsStoreString;
input [7:0] opcode;
fnIsStoreString =
	opcode==`STSW || opcode==`STSB || opcode==`STSH || opcode==`STSC;
endfunction

wire xbr = (iqentry_op[head0]==`BR) || (iqentry_op[head1]==`BR);
wire takb = (iqentry_op[head0]==`BR) ? commit0_v : commit1_v;
wire [DBW-1:0] xbrpc = (iqentry_op[head0]==`BR) ? iqentry_pc[head0] : iqentry_pc[head1];

wire predict_takenA,predict_takenB,predict_takenC,predict_takenD;

// There are really only two branch tables required one for fetchbuf0 and one
// for fetchbuf1. Synthesis removes the extra tables.
//
Thor_BranchHistory #(DBW) ubhtA
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

Thor_BranchHistory #(DBW) ubhtB
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(xbr),
	.xisBranch(xbr),
	.pc(pc+fnInsnLength(insn)),
	.xpc(xbrpc),
	.takb(takb),
	.predict_taken(predict_takenB)
);

Thor_BranchHistory #(DBW) ubhtC
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

Thor_BranchHistory #(DBW) ubhtD
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(xbr),
	.xisBranch(xbr),
	.pc(pc+fnInsnLength(insn)),
	.xpc(xbrpc),
	.takb(takb),
	.predict_taken(predict_takenD)
);


Thor_icachemem #(DBW) uicm1
(
	.wclk(clk),
	.wce(cstate==ICACHE1),
	.wr(ack_i|err_i),
	.wa(adr_o),
	.wd({err_i,dat_i}),
	.rclk(~clk),
	.pc(ppc),
	.insn(insn)
);

wire hit0,hit1;
Thor_itagmem #(DBW-1) uitm1
(
	.wclk(clk),
	.wce(cstate==ICACHE1 && cti_o==3'b111),
	.wr(ack_i|err_i),
	.wa(adr_o),
	.err_i(err_i|ierr),
	.invalidate(ic_invalidate),
	.rclk(~clk),
	.rce(1'b1),
	.pc(ppc),
	.hit0(hit0),
	.hit1(hit1),
	.err_o(insnerr)
);

wire ihit = hit0 & hit1;
wire ld_fetchbuf = ihit || (nmi_edge & !StatusHWI)||(irq_i & ~im & !StatusHWI);

wire [DBW-1:0] shfto0,shfto1;

function fnIsShiftiop;
input [7:0] opcode;
fnIsShiftiop = opcode==`SHLI || opcode==`SHLUI ||
				opcode==`SHRI || opcode==`SHRUI ||
				opcode==`ROLI || opcode==`RORI
				;
endfunction

function fnIsShiftop;
input [7:0] opcode;
fnIsShiftop = opcode==`SHL || opcode==`SHLI || opcode==`SHLU || opcode==`SHLUI ||
				opcode==`SHR || opcode==`SHRI || opcode==`SHRU || opcode==`SHRUI ||
				opcode==`ROL || opcode==`ROLI || opcode==`ROR || opcode==`RORI
				;
endfunction

//wire [3:0] Pn = ir[7:4];

// Set the target register
// 0xx = general register file
// 10x = predicate register
// 11x = branch register
// 12x = segment register
// 130 = predicate register horizontal
function [8:0] fnTargetReg;
input [63:0] ir;
begin
	if (ir[3:0]==4'h0)	// Process special predicates
		fnTargetReg = 9'h000;
	else
		casex(fnOpcode(ir))
		`LDI:
			fnTargetReg = {1'b0,ir[23:16]};
		`BCD,
		`ADD,`ADDU,`SUB,`SUBU,`MUL,`MULU,`DIV,`DIVU,
		`AND,`OR,`EOR,`NAND,`NOR,`ENOR,`ANDC,`ORC,
		`_2ADDU,`_4ADDU,`_8ADDU,`_16ADDU,
		`SHL,`SHR,`SHLU,`SHRU,`ROL,`ROR,
		`LWX,`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX:
			fnTargetReg = {1'b0,ir[39:32]};
		`NEG,
		`ADDI,`ADDUI,`SUBI,`SUBUI,`MULI,`MULUI,`DIVI,`DIVUI,
		`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI,
		`ANDI,`ORI,`EORI,
		`SHLI,`SHRI,`SHLUI,`SHRUI,`ROLI,`RORI,
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW:
			fnTargetReg = {1'b0,ir[31:24]};
		`TLB:
			if (ir[19:16]==`TLB_RDREG)
				fnTargetReg = {1'b0,ir[31:24]};
			else
				fnTargetReg = 9'h000;
		`MFSPR:
			fnTargetReg = {1'b0,ir[31:24]};
		`STSB,`STSW:
			fnTargetReg = {1'b0,ir[23:16]};
		`CMP,`CMPI,`TST:
			fnTargetReg = {1'b1,4'h0,ir[11:8]};
		`JSR,`SYS,`INT:
			fnTargetReg = {1'b1,4'h1,ir[19:16]};
		`MTSPR:
			if (ir[31:28]==4'h1)		// Move to branch register
				fnTargetReg = {1'b1,4'h1,ir[27:24]};
			else if (ir[31:28]==4'h2)	// Move to seg. reg.
				fnTargetReg = {1'b1,4'h2,ir[27:24]};
			else if (ir[31:24]==8'h04)
				fnTargetReg = 9'h130;
			else
				fnTargetReg = 9'h000;
		default:	fnTargetReg = 9'h00;
		endcase
end
endfunction

function fnTargetsBr;
input [63:0] ir;
begin
if (ir[3:0]==4'h0)
	fnTargetsBr = `FALSE;
else begin
	case(fnOpcode(ir))
	`JSR,`SYS,`INT:	fnTargetsBr = `TRUE;
	`MTSPR:
		begin
			if (ir[31:28]==4'h1)
				fnTargetsBr = `TRUE;
			else
				fnTargetsBr = `FALSE;
		end
	default:	fnTargetsBr = `FALSE;
	endcase
end
end
endfunction

function fnTargetsSegreg;
input [63:0] ir;
if (ir[3:0]==4'h0)
	fnTargetsSegreg = `FALSE;
else
	case(fnOpcode(ir))
	`MTSPR:
		if (ir[31:28]==4'h2)
			fnTargetsSegreg = `TRUE;
		else
			fnTargetsSegreg = `FALSE;
	default:	fnTargetsSegreg = `FALSE;
	endcase
endfunction

function fnHasConst;
input [7:0] opcode;
	casex(opcode)
	`LDI,
	`ADDI,`SUBI,`ADDUI,`SUBUI,`MULI,`MULUI,`DIVI,`DIVUI,
	`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI,
	`CMPI,
	`ANDI,`ORI,`EORI,
	`SHLI,`SHLUI,`SHRI,`SHRUI,`ROLI,`RORI,
	`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,
	`LWX,`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,
	`SBX,`SCX,`SHX,`SWX,
	`LVB,`LVC,`LVH,`LVW,
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
casex(opcode)
`JSR,`SYS,`INT,`BR,`RTS,`RTI,`RTE:
	fnIsFlowCtrl = 1'b1;
default:	fnIsFlowCtrl = 1'b0;
endcase
end
endfunction

// Return the length of an instruction.
function [3:0] fnInsnLength;
input [127:0] insn;
casex(insn[15:0])
16'bxxxxxxxx00000000:	fnInsnLength = 4'd1;	// BRK
16'bxxxxxxxx00010000:	fnInsnLength = 4'd1;	// NOP
16'bxxxxxxxx00100000:	fnInsnLength = 4'd2;
16'bxxxxxxxx00110000:	fnInsnLength = 4'd3;
16'bxxxxxxxx01000000:	fnInsnLength = 4'd4;
16'bxxxxxxxx01010000:	fnInsnLength = 4'd5;
16'bxxxxxxxx01100000:	fnInsnLength = 4'd6;
16'bxxxxxxxx01110000:	fnInsnLength = 4'd7;
16'bxxxxxxxx10000000:	fnInsnLength = 4'd8;
16'bxxxxxxxx00010001:	fnInsnLength = 4'd1;	// RTS short form
default:
	casex(insn[15:8])
	`NOP,`SEI,`CLI,`RTI,`RTE,`SYNC:
		fnInsnLength = 4'd2;
	`TST,`BR,`RTS:
		fnInsnLength = 4'd3;
	`JSR,`SYS,`CMP,`CMPI,`MTSPR,`MFSPR,`LDI,`NEG,`TLB:
		fnInsnLength = 4'd4;
	`LBX,`LWX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`SCX,`SBX,`SHX,`SWX,`MUX,`BCD:
		fnInsnLength = 4'd6;
	default:
		fnInsnLength = 4'd5;
	endcase
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

always @(fetchbuf or fetchbufA_instr or fetchbufA_v or fetchbufA_pc
 or fetchbufB_instr or fetchbufB_v or fetchbufB_pc
 or fetchbufC_instr or fetchbufC_v or fetchbufC_pc
 or fetchbufD_instr or fetchbufD_v or fetchbufD_pc
)
begin
	fetchbuf0_instr <= (fetchbuf == 1'b0) ? fetchbufA_instr : fetchbufC_instr;
	fetchbuf0_v     <= (fetchbuf == 1'b0) ? fetchbufA_v     : fetchbufC_v    ;
	if (int_pending && string_pc!=64'd0)
		fetchbuf0_pc <= string_pc;
	else
		fetchbuf0_pc    <= (fetchbuf == 1'b0) ? fetchbufA_pc    : fetchbufC_pc   ;
	fetchbuf1_instr <= (fetchbuf == 1'b0) ? fetchbufB_instr : fetchbufD_instr;
	fetchbuf1_v     <= (fetchbuf == 1'b0) ? fetchbufB_v     : fetchbufD_v    ;
	if (int_pending && string_pc != 64'd0)
		fetchbuf1_pc <= string_pc;
	else
		fetchbuf1_pc    <= (fetchbuf == 1'b0) ? fetchbufB_pc    : fetchbufD_pc   ;
end

wire [7:0] opcodeA = fetchbufA_instr[`OPCODE];
wire [7:0] opcodeB = fetchbufB_instr[`OPCODE];
wire [7:0] opcodeC = fetchbufC_instr[`OPCODE];
wire [7:0] opcodeD = fetchbufD_instr[`OPCODE];

function fnIsMem;
input [7:0] opcode;
fnIsMem = 	opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW || 
			opcode==`LBX || opcode==`LWX || opcode==`LBUX || opcode==`LHX || opcode==`LHUX || opcode==`LCX || opcode==`LCUX ||
			opcode==`SB || opcode==`SC || opcode==`SH || opcode==`SW ||
			opcode==`SBX || opcode==`SCX || opcode==`SHX || opcode==`SWX ||
			opcode==`STSB || opcode==`STSC || opcode==`STSH || opcode==`STSW ||
			opcode==`LVB || opcode==`LVC || opcode==`LVH || opcode==`LVW ||
			opcode==`TLB
			;
endfunction

// Determines which instruction write to the register file
function fnIsRFW;
input [7:0] opcode;
input [63:0] ir;
begin
fnIsRFW =	// General registers
			opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW ||
			opcode==`LBX || opcode==`LBUX || opcode==`LCX || opcode==`LCUX || opcode==`LHX || opcode==`LHUX || opcode==`LWX ||
			opcode==`ADDI || opcode==`SUBI || opcode==`ADDUI || opcode==`SUBUI || opcode==`MULI || opcode==`MULUI || opcode==`DIVI || opcode==`DIVUI ||
			opcode==`ANDI || opcode==`ORI || opcode==`EORI ||
			opcode==`ADD || opcode==`SUB || opcode==`ADDU || opcode==`SUBU || opcode==`MUL || opcode==`MULU || opcode==`DIV || opcode==`DIVU ||
			opcode==`AND || opcode==`OR || opcode==`EOR || opcode==`NAND || opcode==`NOR || opcode==`ENOR || opcode==`ANDC || opcode==`ORC ||
			opcode==`SHL || opcode==`SHLU || opcode==`SHR || opcode==`SHRU || opcode==`ROL || opcode==`ROR ||
			opcode==`SHLI || opcode==`SHLUI || opcode==`SHRI || opcode==`SHRUI || opcode==`ROLI || opcode==`RORI ||
			opcode==`NOT || opcode==`NEG ||
			opcode==`LDI || opcode==`MFSPR ||
			// Branch registers / Segment registers
			(opcode==`MTSPR && (fnTargetsBr(ir) || fnTargetsSegreg(ir))) ||
			opcode==`JSR || opcode==`SYS || opcode==`INT ||
			// predicate registers
			(opcode[7:4] < 4'h3) ||
			(opcode==`TLB && ir[19:16]==`TLB_RDREG) ||
			opcode==`BCD
			;
end
endfunction

function fnIsStore;
input [7:0] opcode;
fnIsStore = 	opcode==`SB || opcode==`SC || opcode==`SH || opcode==`SW ||
				opcode==`SBX || opcode==`SCX || opcode==`SHX || opcode==`SWX ||
				opcode==`STSB || opcode==`STSC || opcode==`STSH || opcode==`STSW;
endfunction

function fnIsLoad;
input [7:0] opcode;
fnIsLoad =	opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW || 
			opcode==`LBX || opcode==`LBUX || opcode==`LCX || opcode==`LCUX || opcode==`LHX || opcode==`LHUX || opcode==`LWX ||
			opcode==`LVB || opcode==`LVC || opcode==`LVH || opcode==`LVW;
endfunction

function fnIsIndexed;
input [7:0] opcode;
fnIsIndexed = opcode==`LBX || opcode==`LBUX || opcode==`LCX || opcode==`LCUX || opcode==`LHX || opcode==`LHUX || opcode==`LWX ||
				opcode==`SBX || opcode==`SCX || opcode==`SHX || opcode==`SWX;
endfunction

// *** check these
function fnIsPFW;
input [7:0] opcode;
fnIsPFW =	opcode[7:4]<4'h3;//opcode==`CMP || opcode==`CMPI || opcode==`TST;
endfunction

function [7:0] fnSelect;
input [7:0] opcode;
input [DBW-1:0] adr;
begin
if (DBW==32)
	case(opcode)
	`LB,`LBU,`LBX,`LBUX,`SB,`SBX,`LVB:
		case(adr[1:0])
		3'd0:	fnSelect = 8'h11;
		3'd1:	fnSelect = 8'h22;
		3'd2:	fnSelect = 8'h44;
		3'd3:	fnSelect = 8'h88;
		endcase
	`LC,`LCU,`SC,`LVC,`LCX,`LCUX,`SCX:
		case(adr[1])
		1'd0:	fnSelect = 8'h33;
		1'd1:	fnSelect = 8'hCC;
		endcase
	`LH,`LHU,`SH,`LVH,`LHX,`LHUX,`SHX:
		fnSelect = 8'hFF;
	`LW,`LWX,`SW,`LVW,`SWX:
		fnSelect = 8'hFF;
	default:	fnSelect = 8'h00;
	endcase
else
	case(opcode)
	`LB,`LBU,`LBX,`SB,`LVB,`LBUX,`SBX:
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
	`LC,`LCU,`SC,`LVC,`LCX,`LCUX,`SCX:
		case(adr[2:1])
		2'd0:	fnSelect = 8'h03;
		2'd1:	fnSelect = 8'h0C;
		2'd2:	fnSelect = 8'h30;
		2'd3:	fnSelect = 8'hC0;
		endcase
	`LH,`LHU,`SH,`LVH,`LHX,`LHUX,`SHX:
		case(adr[2])
		1'b0:	fnSelect = 8'h0F;
		1'b1:	fnSelect = 8'hF0;
		endcase
	`LW,`LWX,`SW,`LVW,`SWX:
		fnSelect = 8'hFF;
	default:	fnSelect = 8'h00;
	endcase
end
endfunction

function [DBW-1:0] fnDatai;
input [7:0] opcode;
input [DBW-1:0] dat;
input [7:0] sel;
begin
if (DBW==32)
	case(opcode)
	`LB,`LBX,`LVB:
		case(sel[3:0])
		8'h1:	fnDatai = {{24{dat[7]}},dat[7:0]};
		8'h2:	fnDatai = {{24{dat[15]}},dat[15:8]};
		8'h4:	fnDatai = {{24{dat[23]}},dat[23:16]};
		8'h8:	fnDatai = {{24{dat[31]}},dat[31:24]};
		default:	fnDatai = {DBW{1'b1}};
		endcase
	`LBU,`LBUX:
		case(sel[3:0])
		4'h1:	fnDatai = dat[7:0];
		4'h2:	fnDatai = dat[15:8];
		4'h4:	fnDatai = dat[23:16];
		4'h8:	fnDatai = dat[31:24];
		default:	fnDatai = {DBW{1'b1}};
		endcase
	`LC,`LVC,`LCX:
		case(sel[3:0])
		4'h3:	fnDatai = {{16{dat[15]}},dat[15:0]};
		4'hC:	fnDatai = {{16{dat[31]}},dat[31:16]};
		default:	fnDatai = {DBW{1'b1}};
		endcase
	`LCU,`LCUX:
		case(sel[3:0])
		4'h3:	fnDatai = dat[15:0];
		4'hC:	fnDatai = dat[31:16];
		default:	fnDatai = {DBW{1'b1}};
		endcase
	`LH,`LHU,`LW,`LWX,`LVH,`LVW,`LHX,`LHUX:
		fnDatai = dat[31:0];
	default:	fnDatai = {DBW{1'b1}};
	endcase
else
	case(opcode)
	`LB,`LBX,`LVB:
		case(sel)
		8'h01:	fnDatai = {{DBW*7/8{dat[DBW*1/8-1]}},dat[DBW*1/8-1:0]};
		8'h02:	fnDatai = {{DBW*7/8{dat[DBW*2/8-1]}},dat[DBW*2/8-1:DBW*1/8]};
		8'h04:	fnDatai = {{DBW*7/8{dat[DBW*3/8-1]}},dat[DBW*3/8-1:DBW*2/8]};
		8'h08:	fnDatai = {{DBW*7/8{dat[DBW*4/8-1]}},dat[DBW*4/8-1:DBW*3/8]};
		8'h10:	fnDatai = {{DBW*7/8{dat[DBW*5/8-1]}},dat[DBW*5/8-1:DBW*4/8]};
		8'h20:	fnDatai = {{DBW*7/8{dat[DBW*6/8-1]}},dat[DBW*6/8-1:DBW*5/8]};
		8'h40:	fnDatai = {{DBW*7/8{dat[DBW*7/8-1]}},dat[DBW*7/8-1:DBW*6/8]};
		8'h80:	fnDatai = {{DBW*7/8{dat[DBW-1]}},dat[DBW-1:DBW*7/8]};
		default:	fnDatai = {DBW{1'b1}};
		endcase
	`LBU,`LBUX:
		case(sel)
		8'h01:	fnDatai = dat[DBW*1/8-1:0];
		8'h02:	fnDatai = dat[DBW*2/8-1:DBW*1/8];
		8'h04:	fnDatai = dat[DBW*3/8-1:DBW*2/8];
		8'h08:	fnDatai = dat[DBW*4/8-1:DBW*3/8];
		8'h10:	fnDatai = dat[DBW*5/8-1:DBW*4/8];
		8'h20:	fnDatai = dat[DBW*6/8-1:DBW*5/8];
		8'h40:	fnDatai = dat[DBW*7/8-1:DBW*6/8];
		8'h80:	fnDatai = dat[DBW-1:DBW*7/8];
		default:	fnDatai = {DBW{1'b1}};
		endcase
	`LC,`LVC,`LCX:
		case(sel)
		8'h03:	fnDatai = {{DBW*3/4{dat[DBW/4-1]}},dat[DBW/4-1:0]};
		8'h0C:	fnDatai = {{DBW*3/4{dat[DBW/2-1]}},dat[DBW/2-1:DBW/4]};
		8'h30:	fnDatai = {{DBW*3/4{dat[DBW*3/4-1]}},dat[DBW*3/4-1:DBW/2]};
		8'hC0:	fnDatai = {{DBW*3/4{dat[DBW-1]}},dat[DBW-1:DBW*3/4]};
		default:	fnDatai = {DBW{1'b1}};
		endcase
	`LCU,`LCUX:
		case(sel)
		8'h03:	fnDatai = dat[DBW/4-1:0];
		8'h0C:	fnDatai = dat[DBW/2-1:DBW/4];
		8'h30:	fnDatai = dat[DBW*3/4-1:DBW/2];
		8'hC0:	fnDatai = dat[DBW-1:DBW*3/4];
		default:	fnDatai = {DBW{1'b1}};
		endcase
	`LH,`LVH,`LHX:
		case(sel)
		8'h0F:	fnDatai = {{DBW/2{dat[DBW/2-1]}},dat[DBW/2-1:0]};
		8'hF0:	fnDatai = {{DBW/2{dat[DBW-1]}},dat[DBW-1:DBW/2]};
		default:	fnDatai = {DBW{1'b1}};
		endcase
	`LHU,`LHUX:
		case(sel)
		8'h0F:	fnDatai = dat[DBW/2-1:0];
		8'hF0:	fnDatai = dat[DBW-1:DBW/2];
		default:	fnDatai = {DBW{1'b1}};
		endcase
	`LW,`LWX,`LVW:
		case(sel)
		8'hFF:	fnDatai = dat;
		default:	fnDatai = {DBW{1'b1}};
		endcase
	default:	fnDatai = {DBW{1'b1}};
	endcase
end
endfunction

function [DBW-1:0] fnDatao;
input [7:0] opcode;
input [DBW-1:0] dat;
if (DBW==32)
	case(opcode)
	`SW,`SWX:	fnDatao = dat;
	`SH,`SHX:	fnDatao = dat;
	`SC,`SCX:	fnDatao = {2{dat[15:0]}};
	`SB,`SBX:	fnDatao = {4{dat[7:0]}};
	default:	fnDatao = dat;
	endcase
else
	case(opcode)
	`SW,`SWX:	fnDatao = dat;
	`SH,`SHX:	fnDatao = {2{dat[DBW/2-1:0]}};
	`SC,`SCX:	fnDatao = {4{dat[DBW/4-1:0]}};
	`SB,`SBX:	fnDatao = {8{dat[DBW/8-1:0]}};
	default:	fnDatao = dat;
	endcase
endfunction

assign fetchbuf0_mem	= fetchbuf ? fnIsMem(opcodeC) : fnIsMem(opcodeA);
assign fetchbuf1_mem	= fetchbuf ? fnIsMem(opcodeD) : fnIsMem(opcodeB);

assign fetchbuf0_jmp   = fnIsFlowCtrl(opcode0);
assign fetchbuf1_jmp   = fnIsFlowCtrl(opcode1);

assign fetchbuf0_rfw	= fetchbuf ? fnIsRFW(opcodeC,fetchbufC_instr) : fnIsRFW(opcodeA,fetchbufA_instr);
assign fetchbuf1_rfw	= fetchbuf ? fnIsRFW(opcodeD,fetchbufD_instr) : fnIsRFW(opcodeB,fetchbufB_instr);
assign fetchbuf0_pfw	= fetchbuf ? fnIsPFW(opcodeC) : fnIsPFW(opcodeA);
assign fetchbuf1_pfw    = fetchbuf ? fnIsPFW(opcodeD) : fnIsPFW(opcodeB);

wire predict_taken0 = fetchbuf ? predict_takenC : predict_takenA;
wire predict_taken1 = fetchbuf ? predict_takenD : predict_takenB;
//
// set branchback and backpc values ... ignore branches in fetchbuf slots not ready for enqueue yet
//
assign take_branch0 = ({fetchbuf0_v, fnIsBranch(opcode0), predict_taken0}  == {`VAL, `TRUE, `TRUE});
assign take_branch1 = ({fetchbuf1_v, fnIsBranch(opcode1), predict_taken1}  == {`VAL, `TRUE, `TRUE});
assign take_branch = take_branch0 || take_branch1;

wire [DBW-1:0] branch_pc =
		({fetchbuf0_v, fnIsBranch(opcode0), predict_taken0}  == {`VAL, `TRUE, `TRUE}) ? 
			fetchbuf0_pc + {{DBW-12{fetchbuf0_instr[11]}},fetchbuf0_instr[11:8],fetchbuf0_instr[23:16]} :
			fetchbuf1_pc + {{DBW-12{fetchbuf1_instr[11]}},fetchbuf1_instr[11:8],fetchbuf1_instr[23:16]};


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
reg [63:0] insn1a;
reg [63:0] insn0,insn1;
always @(nmi_edge or StatusHWI or int_commit or irq_i or im or insnerr or insn or vec_i or ITLBMiss)
if (int_commit)
	insn0 <= {8{8'h10}};	// load with NOPs
else if (nmi_edge & ~StatusHWI & ~int_commit)
	insn0 <= {8'hFE,8'hCE,8'hA6,8'h01,8'hFE,8'hCE,8'hA6,8'h01};
else if (ITLBMiss)
	insn0 <= {8'hF9,8'hCE,8'hA6,8'h01,8'hF9,8'hCE,8'hA6,8'h01};
else if (insnerr)
	insn0 <= {8'hFC,8'hCE,8'hA6,8'h01,8'hFC,8'hCE,8'hA6,8'h01};
else if (irq_i & ~im & ~StatusHWI & ~int_commit)
	insn0 <= {vec_i,8'hCE,8'hA6,8'h01,vec_i,8'hCE,8'hA6,8'h01};
else
	insn0 <= insn[63:0];


always @(nmi_edge or StatusHWI or int_commit or irq_i or im or insnerr or insn1a or vec_i or ITLBMiss)
if (int_commit)
	insn1 <= {8{8'h10}};	// load with NOPs
else if (nmi_edge & ~StatusHWI & ~int_commit)
	insn1 <= {8'hFE,8'hCE,8'hA6,8'h01,8'hFE,8'hCE,8'hA6,8'h01};
else if (ITLBMiss)
	insn1 <= {8'hF9,8'hCE,8'hA6,8'h01,8'hF9,8'hCE,8'hA6,8'h01};
else if (insnerr)
	insn1 <= {8'hFC,8'hCE,8'hA6,8'h01,8'hFC,8'hCE,8'hA6,8'h01};
else if (irq_i & ~im & ~StatusHWI & ~int_commit)
	insn1 <= {vec_i,8'hCE,8'hA6,8'h01,vec_i,8'hCE,8'hA6,8'h01};
else
	insn1 <= insn1a;

//wire [63:0] insn0 = 
//			(nmi_edge & !StatusHWI) ?	 {8'hFE,8'hCE,8'hA6,8'h01,8'hFE,8'hCE,8'hA6,8'h01} :
//			(irq_i & ~im & !StatusHWI) ? {vec_i,8'hCE,8'hA6,8'h01,vec_i,8'hCE,8'hA6,8'h01} :
//			insnerr ? 					 {8'hFC,8'hCE,8'hA6,8'h01,8'hFC,8'hCE,8'hA6,8'h01} :
//			insn[63:0];
//wire [63:0] insn1 = 
//			(nmi_edge & !StatusHWI) ? 	 {8'hFE,8'hCE,8'hA6,8'h01,8'hFE,8'hCE,8'hA6,8'h01} :
//			(irq_i & ~im & !StatusHWI) ? {vec_i,8'hCE,8'hA6,8'h01,vec_i,8'hCE,8'hA6,8'h01} :
//			insnerr ? 					 {8'hFC,8'hCE,8'hA6,8'h01,8'hFC,8'hCE,8'hA6,8'h01} :
//			insn1a;

// Find the second instruction in the instruction line.
always @(insn)
	case(fnInsnLength(insn))
	4'd1:	insn1a <= insn[71: 8];
	4'd2:	insn1a <= insn[79:16];
	4'd3:	insn1a <= insn[87:24];
	4'd4:	insn1a <= insn[95:32];
	4'd5:	insn1a <= insn[103:40];
	4'd6:	insn1a <= insn[111:48];
	4'd7:	insn1a <= insn[119:56];
	4'd8:	insn1a <= insn[127:64];
	default:	insn1a <= {8{8'h10}};	// NOPs
	endcase

// Return the immediate field of an instruction
function [7:0] fnImm;
input [127:0] insn;

case(insn[15:8])
`BCD:
	fnImm = insn[47:40];
`TLB:
	fnImm = insn[23:16];
`LOOP:
	fnImm = insn[23:16];
`SYS,`JSR,`INT,`CMPI,`LDI:
	fnImm = insn[31:24];
`RTS:
	fnImm = {4'h0,insn[19:16]};
`RTE,`RTI:
	fnImm = 8'h00;
`LBX,`LBUX,`LHX,`LHUX,`LCX,`LCUX,`LWX,
`SBX,`SCX,`SHX,`SWX:
	fnImm = insn[47:40];
default:
	fnImm = insn[39:32];
endcase

endfunction

// Return MSB of immediate value for instruction
function fnImmMSB;
input [127:0] insn;

case(insn[15:8])
`TLB,`BCD:
	fnImmMSB = 1'b0;		// TLB regno is unsigned
`LOOP:
	fnImmMSB = insn[23];
`JSR,`CMPI,`LDI:
	fnImmMSB = insn[31];
`SYS,`INT:
	fnImmMSB = 1'b0;		// SYS,INT are unsigned
`RTS,`RTE,`RTI:
	fnImmMSB = 1'b0;		// RTS is unsigned
`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,
`SBX,`SCX,`SHX,`SWX:
	fnImmMSB = insn[47];
default:
	fnImmMSB = insn[39];
endcase

endfunction

function [63:0] fnImmImm;
input [63:0] insn;
case(insn[7:4])
4'd2:	fnImmImm = {{48{insn[15]}},insn[15:8],8'h00};
4'd3:	fnImmImm = {{40{insn[23]}},insn[23:8],8'h00};
4'd4:	fnImmImm = {{32{insn[31]}},insn[31:8],8'h00};
4'd5:	fnImmImm = {{24{insn[39]}},insn[39:8],8'h00};
4'd6:	fnImmImm = {{16{insn[47]}},insn[47:8],8'h00};
4'd7:	fnImmImm = {{ 8{insn[55]}},insn[55:8],8'h00};
4'd8:	fnImmImm = {insn[63:8],8'h00};
default:	fnImmImm = 64'd0;
endcase
endfunction

function [63:0] fnOpa;
input [7:0] opcode;
input [63:0] ins;
input [63:0] rfo;
input [63:0] epc;
begin
	if (opcode==`LOOP)
		fnOpa = epc;
	else if (fnIsFlowCtrl(opcode))
		fnOpa = fnBra(ins)==4'd0 ? 64'd0 : fnBra(ins)==4'd15 ? epc :
			(commit0_v && commit0_tgt[8:4]==5'h11 && commit0_tgt[3:0]==fnBra(ins)) ? commit0_bus :
			bregs[fnBra(ins)];
	else if (opcode==`MFSPR)
		casex(ins[23:16])
		`TICK:	fnOpa = tick;
		`LCTR:	fnOpa = lc;
		`PREGS:
				begin
					fnOpa[3:0] = pregs[0];
					fnOpa[7:4] = pregs[1];
					fnOpa[11:8] = pregs[2];
					fnOpa[15:12] = pregs[3];
					fnOpa[19:16] = pregs[4];
					fnOpa[23:20] = pregs[5];
					fnOpa[27:24] = pregs[6];
					fnOpa[31:28] = pregs[7];
					fnOpa[35:32] = pregs[8];
					fnOpa[39:36] = pregs[9];
					fnOpa[43:40] = pregs[10];
					fnOpa[47:44] = pregs[11];
					fnOpa[51:48] = pregs[12];
					fnOpa[55:52] = pregs[13];
					fnOpa[59:56] = pregs[14];
					fnOpa[63:60] = pregs[15];
				end
		8'h1x:	fnOpa = ins[19:16]==4'h0 ? 64'd0 : ins[19:16]==4'hF ? epc :
						(commit0_v && commit0_tgt[8:4]==5'h11 && commit0_tgt[3:0]==ins[19:16]) ? commit0_bus :
						bregs[ins[19:16]];
`ifdef SEGMENTATION
		8'h2x:	fnOpa = 
			(commit0_v && commit0_tgt[8:4]==5'h12 && commit0_tgt[3:0]==ins[19:16]) ? {commit0_bus[DBW-1:12],12'h000} :
			{sregs[ins[19:16]],12'h000};
`endif
		default:	fnOpa = 64'h0;
		endcase
	else
		fnOpa = rfo;
end
endfunction

function [15:0] fnRegstrGrp;
input [8:0] Rn;
if (!Rn[8]) begin
	fnRegstrGrp="GP";
end
else
	case(Rn[7:4])
	4'h0:	fnRegstrGrp="P ";
	4'h1:	fnRegstrGrp="BR";
	4'h2:	fnRegstrGrp="SG";
	endcase

endfunction

function [7:0] fnRegstr;
input [8:0] Rn;
if (!Rn[8]) begin
	fnRegstr = Rn[7:0];
end
else
	fnRegstr = Rn[3:0];
endfunction

initial begin
	//
	// set up panic messages
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

`include "Thor_issue_combo.v"
`include "Thor_execute_combo.v"
`include "Thor_memory_combo.v"
`include "Thor_commit_combo.v"

always @(posedge clk)
	if (rst_i)
		tick <= 64'd0;
	else
		tick <= tick + 64'd1;

always @(posedge clk)
	if (rst_i)
		nmi1 <= 1'b0;
	else
		nmi1 <= nmi_i;

always @(posedge clk) begin

	if (nmi_i & !nmi1)
		nmi_edge <= 1'b1;
		
	alu0_ld <= 1'b0;
	alu1_ld <= 1'b0;

	ic_invalidate <= `FALSE;
	if (rst_i) begin
		nmi_edge <= 1'b0;
		cstate <= IDLE;
		pc <= {{DBW-4{1'b1}},4'h0};
		StatusHWI <= `TRUE;		// disables interrupts at startup until an RTI instruction is executed.
		im <= 1'b1;
		ic_invalidate <= `TRUE;
		fetchbuf <= 1'b0;
		fetchbufA_v <= `INV;
		fetchbufB_v <= `INV;
		fetchbufC_v <= `INV;
		fetchbufD_v <= `INV;
		fetchbufA_instr <= {8{8'h10}};
		fetchbufB_instr <= {8{8'h10}};
		fetchbufC_instr <= {8{8'h10}};
		fetchbufD_instr <= {8{8'h10}};
		fetchbufA_pc <= {{DBW-4{1'b1}},4'h0};
		fetchbufB_pc <= {{DBW-4{1'b1}},4'h0};
		fetchbufC_pc <= {{DBW-4{1'b1}},4'h0};
		fetchbufD_pc <= {{DBW-4{1'b1}},4'h0};
		for (i=0; i<8; i=i+1) begin
			iqentry_v[i] <= `INV;
		end
		// All the register are flagged as valid on startup even though they
		// may not contain valid data. Otherwise the processor will stall
		// waiting for the registers to become valid. Ideally the registers
		// should be initialized with valid values before use. But who knows
		// what someone will do in boot code and we don't want the processor
		// to stall.
		for (n = 1; n < NREGS; n = n + 1)
			rf_v[n] = `VAL;
		rf_v[0] = `VAL;
		rf_v[9'h110] = `VAL;
		rf_v[9'h11F] = `VAL;
		alu0_available <= `TRUE;
		alu1_available <= `TRUE;
		tail0 <= 3'd0;
		tail1 <= 3'd1;
		head0 <= 3'd0;
		head1 <= 3'd1;
		head2 <= 3'd2;
		head3 <= 3'd3;
		head4 <= 3'd4;
		head5 <= 3'd5;
		head6 <= 3'd6;
		head7 <= 3'd7;
		dram0 <= 3'b00;
		dram1 <= 3'b00;
		dram2 <= 3'b00;
		tlb_state <= 3'd0;
		panic <= `PANIC_NONE;
		string_pc <= 64'd0;
		// The pc wraps around to address zero while fetching the reset vector.
		// This causes the processor to use the code segement register so the
		// CS has to be defined for reset.
		sregs[15] <= 52'd0;
		for (i=0; i < 16; i=i+1)
			pregs[i] <= 4'd0;
	end

	// The following registers are always valid
	rf_v[9'h000] = `VAL;
	rf_v[9'h110] = `VAL;	// BR0
	rf_v[9'h11F] = `VAL;	// BR15 (PC)

	did_branchback <= take_branch;
	did_branchback0 <= take_branch0;
	did_branchback1 <= take_branch1;

	if (branchmiss) begin
		for (n = 1; n < NREGS; n = n + 1)
			if (rf_v[n] == `INV && ~livetarget[n]) rf_v[n] = `VAL;

	    if (|iqentry_0_latestID[255:1])	rf_source[ iqentry_tgt[0] ] <= { iqentry_mem[0], 3'd0 };
	    if (|iqentry_1_latestID[255:1])	rf_source[ iqentry_tgt[1] ] <= { iqentry_mem[1], 3'd1 };
	    if (|iqentry_2_latestID[255:1])	rf_source[ iqentry_tgt[2] ] <= { iqentry_mem[2], 3'd2 };
	    if (|iqentry_3_latestID[255:1])	rf_source[ iqentry_tgt[3] ] <= { iqentry_mem[3], 3'd3 };
	    if (|iqentry_4_latestID[255:1])	rf_source[ iqentry_tgt[4] ] <= { iqentry_mem[4], 3'd4 };
	    if (|iqentry_5_latestID[255:1])	rf_source[ iqentry_tgt[5] ] <= { iqentry_mem[5], 3'd5 };
	    if (|iqentry_6_latestID[255:1])	rf_source[ iqentry_tgt[6] ] <= { iqentry_mem[6], 3'd6 };
	    if (|iqentry_7_latestID[255:1])	rf_source[ iqentry_tgt[7] ] <= { iqentry_mem[7], 3'd7 };

	end

	if (ihit) begin
		$display("\r\n");
		$display("TIME %0d", $time);
	end
`include "Thor_ifetch.v"
	if (ihit) begin
	$display("%h hit0=%b hit1=%b#", spc, hit0, hit1);
	$display("insn=%h", insn);
	$display("%c insn0=%h insn1=%h", nmi_edge ? "*" : " ",insn0, insn1);
	$display("takb=%d br_pc=%h #", take_branch, branch_pc);
	$display("%c%c A: %d %h %h #",
	    45, fetchbuf?45:62, fetchbufA_v, fetchbufA_instr, fetchbufA_pc);
	$display("%c%c B: %d %h %h #",
	    45, fetchbuf?45:62, fetchbufB_v, fetchbufB_instr, fetchbufB_pc);
	$display("%c%c C: %d %h %h #",
	    45, fetchbuf?62:45, fetchbufC_v, fetchbufC_instr, fetchbufC_pc);
	$display("%c%c D: %d %h %h #",
	    45, fetchbuf?62:45, fetchbufD_v, fetchbufD_instr, fetchbufD_pc);
	$display("fetchbuf=%d",fetchbuf);
	end
`include "Thor_commit_early.v"
`include "Thor_enque.v"
	if (ihit) begin
	for (i=0; i<8; i=i+1) 
	    $display("%c%c %d: %d %d %d %d %d %d %d %d %d %d %c%h %d%s %h %h %h %d %o %h %d %o %h #",
		(i[2:0]==head0)?72:46, (i[2:0]==tail0)?84:46, i,
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
`include "Thor_dataincoming.v"
`include "Thor_issue.v"
	if (ihit) $display("iss=%b stomp=%b", iqentry_issue, iqentry_stomp);
`include "Thor_memory.v"
//	$display("TLB: en=%b imatch=%b pgsz=%d pcs=%h phys=%h", utlb1.TLBenabled,utlb1.IMatch,utlb1.PageSize,utlb1.pcs,utlb1.IPFN);
//	for (i = 0; i < 64; i = i + 1)
//		$display("vp=%h G=%b",utlb1.TLBVirtPage[i],utlb1.TLBG[i]);
`include "Thor_commit.v"

	case(cstate)
	IDLE:
		if (!ihit) begin
			if (dram0!=2'd0 || dram1!=2'd0 || dram2!=2'd0)
				;
			else begin
				$display("********************");
				$display("Cache access to: %h",!hit0 ? {ppc[DBW-1:5],5'b00000} : {ppcp16[DBW-1:5],5'b00000});
				$display("********************");
				ierr <= 1'b0;
				bte_o <= 2'b00;
				cti_o <= 3'b001;
				bl_o <= DBW==32 ? 5'd7 : 5'd3;
				cyc_o <= 1'b1;
				stb_o <= 1'b1;
				we_o <= 1'b0;
				sel_o <= {DBW/8{1'b1}};
				adr_o <= !hit0 ? {ppc[DBW-1:5],5'b00000} : {ppcp16[DBW-1:5],5'b00000};
				dat_o <= {DBW{1'b0}};
				cstate <= ICACHE1;
			end
		end
	ICACHE1:
		if (ack_i|err_i) begin
			ierr <= ierr | err_i;	// cumulate an error status
			if (DBW==32) begin
				adr_o[4:2] <= adr_o[4:2] + 3'd1;
				if (adr_o[4:2]==3'b110)
					cti_o <= 3'b111;
				if (adr_o[4:2]==3'b111) begin
					wb_nack();
					cstate <= IDLE;
				end
			end
			else begin
				adr_o[4:3] <= adr_o[4:3] + 2'd1;
				if (adr_o[4:3]==2'b10)
					cti_o <= 3'b111;
				if (adr_o[4:3]==2'b11) begin
					wb_nack();
					cstate <= IDLE;
				end
			end
		end
	endcase

//	for (i=0; i<8; i=i+1)
//	    $display("%d: %h %d %o #", i, urf1.regs0[i], rf_v[i], rf_source[i]);

	if (ihit) begin
	$display("dr=%d I=%h A=%h B=%h op=%c%d bt=%d src=%o pc=%h #",
		alu0_dataready, alu0_argI, alu0_argA, alu0_argB, 
		 (fnIsFlowCtrl(alu0_op) ? 98 : (fnIsMem(alu0_op)) ? 109 : 97),
		alu0_op, alu0_bt, alu0_sourceid, alu0_pc);
	$display("dr=%d I=%h A=%h B=%h op=%c%d bt=%d src=%o pc=%h #",
		alu1_dataready, alu1_argI, alu1_argA, alu1_argB, 
		 (fnIsFlowCtrl(alu1_op) ? 98 : (fnIsMem(alu1_op)) ? 109 : 97),
		alu1_op, alu1_bt, alu1_sourceid, alu1_pc);
	$display("v=%d bus=%h id=%o 0 #", alu0_v, alu0_bus, alu0_id);
	$display("bmiss0=%b src=%o mpc=%h #", alu0_branchmiss, alu0_sourceid, alu0_misspc); 
	$display("cmt=%b cnd=%d prd=%d", alu0_cmt, alu0_cond, alu0_pred);
	$display("bmiss1=%b src=%o mpc=%h #", alu1_branchmiss, alu1_sourceid, alu1_misspc); 
	$display("cmt=%b cnd=%d prd=%d", alu1_cmt, alu1_cond, alu1_pred);
	$display("bmiss=%b mpc=%h", branchmiss, misspc);

	$display("0: %d %h %o 0%d #", commit0_v, commit0_bus, commit0_id, commit0_tgt);
	$display("1: %d %h %o 0%d #", commit1_v, commit1_bus, commit1_id, commit1_tgt);
	end
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

task wb_nack;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b000;
	bl_o <= 5'd0;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 8'h00;
	adr_o <= {DBW{1'b0}};
	dat_o <= {DBW{1'b0}};
end
endtask

endmodule

