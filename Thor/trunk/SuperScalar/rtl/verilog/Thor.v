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
//   \\__/ o\    (C) 2013,2015  Robert Finch, Stratford
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
//   64 general purpose registers
//   16 code address registers
//   16 predicate registers / predicated instruction execution
//    8 segment registers
//      A branch history table, and a (2,2) correlating branch predictor added
//      variable length instruction encodings (code density)
//      support for interrupts
//      The instruction set is changed completely with many new instructions.
//      An instruction cache was added.
//      A WISHBONE bus interface was added,
// ============================================================================
//
`include "Thor_defines.v"

module Thor(rst_i, clk_i, km, nmi_i, irq_i, vec_i, bte_o, cti_o, bl_o, lock_o, cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter DBW = 32;
parameter QENTRIES = 8;
parameter IDLE = 4'd0;
parameter ICACHE1 = 4'd1;
parameter DCACHE1 = 4'd2;
parameter IBUF1 = 4'd3;
parameter IBUF2 = 4'd4;
parameter IBUF3 = 4'd5;
parameter IBUF4 = 4'd6;
parameter IBUF5 = 4'd7;
parameter NREGS = 111;
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
output km;
input nmi_i;
input irq_i;
input [7:0] vec_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [4:0] bl_o;
output reg lock_o;
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
reg [DBW-1:0] cregs [0:15];		// code address registers
reg [ 3:0] pregs [0:15];		// predicate registers
`ifdef SEGMENTATION
reg [DBW-1:12] sregs [0:7];		// segment registers
`endif
reg [2:0] rrmapno;				// register rename map number
wire ITLBMiss;
wire DTLBMiss;
wire uncached;
wire [DBW-1:0] cdat;
reg pwe;
wire [DBW-1:0] pea;
reg [DBW-1:0] tick;
reg [DBW-1:0] lc;				// loop counter
wire [DBW-1:0] rfoa0,rfoa1;
wire [DBW-1:0] rfob0,rfob1;
wire [DBW-1:0] rfoc0,rfoc1;
reg ic_invalidate;
reg ierr,derr;					// err_i during icache load
wire insnerr;					// err_i during icache load
wire [127:0] insn;
reg [DBW-1:0] ibufadr;
reg [127:0] ibuf;
wire ibufhit = ibufadr==pc;
wire iuncached;
reg [NREGS:0] rf_v;
//reg [15:0] pf_v;
reg im,imb;
reg fxe;
reg nmi1,nmi_edge;
reg StatusHWI;
reg [7:0] StatusEXL;
assign km = StatusHWI | |StatusEXL;
reg [7:0] GM;		// register group mask
reg [7:0] GMB;
wire [63:0] sr = {32'd0,imb,7'b0,GMB,im,1'b0,km,fxe,4'b0,GM};
wire int_commit;
wire int_pending;
wire sys_commit;
`ifdef SEGMENTATION
wire [DBW-1:0] spc = (pc[DBW-1:DBW-4]==4'hF) ? pc : {sregs[7],12'h000} + pc;
`else
wire [DBW-1:0] spc = pc;
`endif
wire [DBW-1:0] ppcp16 = ppc + 64'd16;
reg [DBW-1:0] string_pc;
reg [7:0] asid;

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
reg        iqentry_fp   [0:7];  // is an floating point operation
reg        iqentry_rfw	[0:7];	// writes to register file
reg [DBW-1:0] iqentry_res	[0:7];	// instruction result
reg  [3:0] iqentry_insnsz [0:7];	// the size of the instruction
reg  [3:0] iqentry_cond [0:7];	// predicating condition
reg  [3:0] iqentry_pred [0:7];	// predicate value
reg        iqentry_p_v  [0:7];	// predicate is valid
reg  [3:0] iqentry_p_s  [0:7];	// predicate source
reg  [7:0] iqentry_op	[0:7];	// instruction opcode
reg  [5:0] iqentry_fn   [0:7];  // instruction function
reg  [2:0] iqentry_renmapno [0:7];	// register rename map number
reg  [6:0] iqentry_tgt	[0:7];	// Rt field or ZERO -- this is the instruction's target (if any)
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
reg  [7:0] iqentry_fpissue;
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
reg [1:0] iqentry_fpislot[0:7];

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
wire 		fetchbuf0_fp;
wire        fetchbuf0_rfw;
wire        fetchbuf0_pfw;
reg  [63:0] fetchbuf1_instr;
reg  [DBW-1:0] fetchbuf1_pc;
reg        fetchbuf1_v;
wire        fetchbuf1_mem;
wire        fetchbuf1_jmp;
wire 		fetchbuf1_fp;
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
reg  [5:0] alu0_fn;
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
reg  [5:0] alu1_fn;
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

`ifdef FLOATING_POINT
reg        fp0_ld;
reg        fp0_available;
reg        fp0_dataready;
reg  [3:0] fp0_sourceid;
reg  [7:0] fp0_op;
reg  [3:0] fp0_cond;
wire        fp0_cmt;
reg 		fp0_done;
reg [DBW-1:0] fp0_argA;
reg [DBW-1:0] fp0_argB;
reg [DBW-1:0] fp0_argC;
reg [DBW-1:0] fp0_argI;
reg  [3:0] fp0_pred;
reg [DBW-1:0] fp0_pc;
reg [DBW-1:0] fp0_bus;
wire  [3:0] fp0_id;
wire  [3:0] fp0_exc;
wire        fp0_v;
`endif

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
reg dram0_owns_bus;
reg [DBW-1:0] dram0_data;
reg [DBW-1:0] dram0_datacmp;
reg [DBW-1:0] dram0_addr;
reg  [7:0] dram0_op;
reg  [5:0] dram0_fn;
reg  [8:0] dram0_tgt;
reg  [3:0] dram0_id;
reg  [3:0] dram0_exc;
reg dram1_owns_bus;
reg [DBW-1:0] dram1_data;
reg [DBW-1:0] dram1_datacmp;
reg [DBW-1:0] dram1_addr;
reg  [7:0] dram1_op;
reg  [5:0] dram1_fn;
reg  [8:0] dram1_tgt;
reg  [3:0] dram1_id;
reg  [3:0] dram1_exc;
reg [DBW-1:0] dram2_data;
reg [DBW-1:0] dram2_datacmp;
reg [DBW-1:0] dram2_addr;
reg  [7:0] dram2_op;
reg  [5:0] dram2_fn;
reg  [8:0] dram2_tgt;
reg  [3:0] dram2_id;
reg  [3:0] dram2_exc;

reg [DBW-1:0] dram_bus;
reg  [8:0] dram_tgt;
reg  [3:0] dram_id;
reg  [3:0] dram_exc;
reg        dram_v;

wire mem_will_issue;

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
wire [6:0] Ra0 = fnRa(fetchbuf0_instr);
wire [6:0] Rb0 = fnRb(fetchbuf0_instr);
wire [6:0] Rc0 = fnRc(fetchbuf0_instr);
wire [6:0] Ra1 = fnRa(fetchbuf1_instr);
wire [6:0] Rb1 = fnRb(fetchbuf1_instr);
wire [6:0] Rc1 = fnRc(fetchbuf1_instr);
/*
wire [8:0] Rb0 = ((fnNumReadPorts(fetchbuf0_instr) < 3'd2) || !fetchbuf0_v) ? {1'b0,fetchbuf1_instr[`INSTRUCTION_RC]} :
				fnRb(fetchbuf0_instr);
wire [8:0] Ra1 = (!fetchbuf0_v || fnNumReadPorts(fetchbuf0_instr) < 3'd3) ? fnRa(fetchbuf1_instr) :
					fetchbuf0_instr[`INSTRUCTION_RC];
wire [8:0] Rb1 = (fnNumReadPorts(fetchbuf1_instr) < 3'd2 && fetchbuf0_v) ? fnRa(fetchbuf1_instr):fnRb(fetchbuf1_instr);
*/
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

function [6:0] fnRa;
input [63:0] insn;
case(insn[7:0])
8'h11:	fnRa = 7'h51;    // RTS short form
default:
	case(insn[15:8])
	`RTI:	fnRa = 7'h5E;
	`RTE:	fnRa = 7'h5D;
	`JSR,`JSRS,`JSRZ,`SYS,`INT,`RTS:
		fnRa = {3'h5,insn[23:20]};
	default:	fnRa = {1'b0,insn[`INSTRUCTION_RA]};
	endcase
endcase
endfunction

function [6:0] fnRb;
input [63:0] insn;
if (insn[7:0]==8'h11)	// RTS short form
	fnRb = 7'h51;
else
	case(insn[15:8])
	`RTI:	fnRb = 7'h5E;
	`RTE:	fnRb = 7'h5D;
	`JSR,`JSRS,`JSRZ,`SYS,`INT,`RTS:
		fnRb = {3'h5,insn[23:20]};
	`TLB:	fnRb = {1'b0,insn[29:24]};
	default:	fnRb = {1'b0,insn[`INSTRUCTION_RB]};
	endcase
endfunction

function [6:0] fnRc;
input [63:0] insn;
fnRc = {1'b0,insn[`INSTRUCTION_RC]};
endfunction

function [3:0] fnCar;
input [63:0] insn;
if (insn[7:0]==8'h11)	// RTS short form
	fnCar = 4'h1;
else
	case(insn[15:8])
	`RTI:	fnCar = 4'hE;
	`RTE:	fnCar = 4'hD;
	`JSR,`JSRS,`JSRZ,`SYS,`INT,`RTS:
		fnCar = {insn[23:20]};
	default:	fnCar = 4'h0;
	endcase
endfunction

function [5:0] fnFunc;
input [63:0] insn;
casex(insn[15:8])
`BITFIELD:	fnFunc = insn[43:40];
`CMP:	fnFunc = insn[31:28];
`TST:	fnFunc = insn[23:22];
default:
	fnFunc = insn[39:34];
endcase
endfunction

Thor_regfile2w6r #(DBW) urf1
(
	.clk(clk),
	.rclk(~clk),
	.wr0(commit0_v && ~commit0_tgt[6] && iqentry_op[head0]!=`MTSPR),
	.wr1(commit1_v && ~commit1_tgt[6] && iqentry_op[head1]!=`MTSPR),
	.wa0(commit0_tgt[5:0]),
	.wa1(commit1_tgt[5:0]),
	.ra0(Ra0[5:0]),
	.ra1(Rb0[5:0]),
	.ra2(Rc0[5:0]),
	.ra3(Ra1[5:0]),
	.ra4(Rb1[5:0]),
	.ra5(Rc1[5:0]),
	.i0(commit0_bus),
	.i1(commit1_bus),
	.o0(rfoa0),
	.o1(rfob0),
	.o2(rfoc0),
	.o3(rfoa1),
	.o4(rfob1),
	.o5(rfoc1)
);

wire [63:0] cregs0 = fnCar(fetchbuf0_instr)==4'd0 ? 64'd0 : fnCar(fetchbuf0_instr)==4'hF ? fetchbuf0_pc : cregs[fnCar(fetchbuf0_instr)];
wire [63:0] cregs1 = fnCar(fetchbuf1_instr)==4'd0 ? 64'd0 : fnCar(fetchbuf1_instr)==4'hF ? fetchbuf1_pc : cregs[fnCar(fetchbuf1_instr)];

//
// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource1_v;
input [7:0] opcode;
	casex(opcode)
	`SEI,`CLI,`MEMSB,`MEMDB,`SYNC,`NOP:
					fnSource1_v = 1'b1;
	`BR,`LOOP:		fnSource1_v = 1'b1;
	`LDI,`LDIS,`IMM:	fnSource1_v = 1'b1;
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
	`NEG,`NOT,`MOV:		fnSource2_v = 1'b1;
	`LDI,`STI,`LDIS,`IMM,`NOP:		fnSource2_v = 1'b1;
	`SEI,`CLI,`MEMSB,`MEMDB,`SYNC:
					fnSource2_v = 1'b1;
	`RTI,`RTE:		fnSource2_v = 1'b1;
	`TST:			fnSource2_v = 1'b1;
	`ADDI,`ADDUI,`ADDUIS:
	                fnSource2_v = 1'b1;
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
	`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWS,`LEA,`STI:
			fnSource2_v = 1'b1;
	`JSR,`JSRS,`JSRZ,`SYS,`INT,`RTS,`BR,`LOOP:
			fnSource2_v = 1'b1;
	`MTSPR,`MFSPR:
				fnSource2_v = 1'b1;
//	`BFSET,`BFCLR,`BFCHG,`BFEXT,`BFEXTU:	// but not BFINS
//				fnSource2_v = 1'b1;
	default:	fnSource2_v = 1'b0;
	endcase
endfunction

// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource3_v;
input [7:0] opcode;
	casex(opcode)
	`SBX,`SCX,`SHX,`SWX,`CAS:	fnSource3_v = 1'b0;
	`MUX:	fnSource3_v = 1'b0;
	default:	fnSource3_v = 1'b1;
	endcase
endfunction

// Return the number of register read ports required for an instruction.
function [2:0] fnNumReadPorts;
input [63:0] ins;
casex(fnOpcode(ins))
`SEI,`CLI,`MEMSB,`MEMDB,`SYNC,`NOP,`MOVS:
					fnNumReadPorts = 3'd0;
`BR:                fnNumReadPorts = 3'd0;
`LOOP:				fnNumReadPorts = 3'd0;
`LDI,`LDIS,`IMM:		fnNumReadPorts = 3'd0;
`NEG,`NOT,`MOV,`STI:	fnNumReadPorts = 3'd1;
`RTI,`RTE:			fnNumReadPorts = 3'd1;
`TST:				fnNumReadPorts = 3'd1;
`ADDI,`ADDUI,`ADDUIS:
                    fnNumReadPorts = 3'd1;
`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI:
					fnNumReadPorts = 3'd1;
`SUBI,`SUBUI:		fnNumReadPorts = 3'd1;
`CMPI:				fnNumReadPorts = 3'd1;
`MULI,`MULUI,`DIVI,`DIVUI:
					fnNumReadPorts = 3'd1;
`ANDI,`ORI,`EORI:	fnNumReadPorts = 3'd1;
`SHIFT:
                    if (ins[39:38]==2'h1)   // shift immediate
					   fnNumReadPorts = 3'd1;
					else
					   fnNumReadPorts = 3'd2;
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LVB,`LVC,`LVH,`LVW,`LWS,`LEA:
					fnNumReadPorts = 3'd1;
`JSR,`JSRS,`JSRZ,`SYS,`INT,`RTS,`BR,`LOOP:
					fnNumReadPorts = 3'd1;
`SBX,`SCX,`SHX,`SWX,
`MUX,`CAS:
					fnNumReadPorts = 3'd3;
`MTSPR,`MFSPR:		fnNumReadPorts = 3'd1;
`TLB:				fnNumReadPorts = 3'd2;	// *** TLB reads on Rb we say 2 for simplicity
`BITFIELD:
    case(ins[43:40])
    `BFSET,`BFCLR,`BFCHG,`BFEXT,`BFEXTU:
					fnNumReadPorts = 3'd1;
    `BFINS:         fnNumReadPorts = 3'd2;
    default:        fnNumReadPorts = 3'd0;
    endcase
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
	opcode==`STS;
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
wire do_pcinc = iuncached ? ibufhit : ihit;
wire ld_fetchbuf = (iuncached ? ibufhit : ihit) || (nmi_edge & !StatusHWI)||(irq_i & ~im & !StatusHWI);

wire whit;

Thor_dcachemem_1w1r #(DBW) udcm1
(
	.wclk(clk),
	.wce(whit || cstate==DCACHE1),
	.wr(ack_i|err_i),
	.sel(whit ? sel_o : 8'hFF),
	.wa(adr_o),
	.wd(whit ? dat_o : dat_i),
	.rclk(~clk),
	.rce(1'b1),
	.ra(pea),
	.o(cdat)
);

Thor_dtagmem #(DBW-1) udtm1
(
	.wclk(clk),
	.wce(cstate==DCACHE1 && cti_o==3'b111),
	.wr(ack_i|err_i),
	.wa(adr_o),
	.err_i(err_i|derr),
	.invalidate(ic_invalidate),
	.rclk(~clk),
	.rce(1'b1),
	.ra(pea),
	.whit(whit),
	.rhit(rhit),
	.err_o()
);

wire [DBW-1:0] shfto0,shfto1;

function fnIsShiftiop;
input [63:0] insn;
fnIsShiftiop =  insn[15:8]==`SHIFT && (
                insn[39:34]==`SHLI || insn[39:34]==`SHLUI ||
				insn[39:34]==`SHRI || insn[39:34]==`SHRUI ||
				insn[39:34]==`ROLI || insn[39:34]==`RORI
				)
				;
endfunction

function fnIsShiftop;
input [7:0] opcode;
fnIsShiftop = opcode==`SHL || opcode==`SHLI || opcode==`SHLU || opcode==`SHLUI ||
				opcode==`SHR || opcode==`SHRI || opcode==`SHRU || opcode==`SHRUI ||
				opcode==`ROL || opcode==`ROLI || opcode==`ROR || opcode==`RORI
				;
endfunction

function fnIsFP;
input [7:0] opcode;
fnIsFP = 	opcode==`ITOF || opcode==`FTOI || opcode==`FNEG || opcode==`FSIGN || /*opcode==`FCMP || */ opcode==`FABS ||
			opcode==`FADD || opcode==`FSUB || opcode==`FMUL || opcode==`FDIV
			;
endfunction

function fnIsBitfield;
input [7:0] opcode;
fnIsBitfield = opcode==`BFSET || opcode==`BFCLR || opcode==`BFCHG || opcode==`BFINS || opcode==`BFEXT || opcode==`BFEXTU;
endfunction

//wire [3:0] Pn = ir[7:4];

// Set the target register
// 0xx = general register file
// 10x = predicate register
// 11x = code address register
// 12x = segment register
// 130 = predicate register horizontal
function [6:0] fnTargetReg;
input [63:0] ir;
begin
	if (ir[3:0]==4'h0)	// Process special predicates
		fnTargetReg = 7'h000;
	else
		casex(fnOpcode(ir))
		`LDI,`ADDUIS,`STS:
			fnTargetReg = {1'b0,ir[21:16]};
		`LDIS:
			fnTargetReg = {1'b1,ir[21:16]};
		`RR:
			fnTargetReg = {1'b0,ir[33:28]};
		`BCD,
		`LOGIC,
		`LWX,`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX:
			fnTargetReg = {1'b0,ir[33:28]};
		`SHIFT:
			fnTargetReg = {1'b0,ir[33:28]};
		`NEG,`NOT,`MOV,
		`ADDI,`ADDUI,`SUBI,`SUBUI,`MULI,`MULUI,`DIVI,`DIVUI,
		`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI,
		`ANDI,`ORI,`EORI,
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LEA:
			fnTargetReg = {1'b0,ir[27:22]};
		`LWS:
			fnTargetReg = {1'b1,ir[27:22]};
		`CAS:
			fnTargetReg = {1'b0,ir[39:34]};
		`BITFIELD:
			fnTargetReg = {1'b0,ir[27:22]};
		`TLB:
			if (ir[19:16]==`TLB_RDREG)
				fnTargetReg = {1'b0,ir[29:24]};
			else
				fnTargetReg = 7'h00;
		`MFSPR:
			fnTargetReg = {1'b0,ir[27:22]};
		`CMP,`CMPI,`TST:
		    begin
			fnTargetReg = {1'b1,2'h0,ir[11:8]};
			end
		`JSR,`JSRZ,`JSRS,`SYS,`INT:
			fnTargetReg = {1'b1,2'h1,ir[19:16]};
		`MTSPR,`MOVS:
			if (ir[27:26]==2'h1)		// Move to code address register
				fnTargetReg = {1'b1,2'h1,ir[25:22]};
			else if (ir[27:26]==2'h2)	// Move to seg. reg.
				fnTargetReg = {1'b1,2'h2,ir[25:22]};
			else if (ir[27:22]==6'h04)
				fnTargetReg = 7'h70;
			else
				fnTargetReg = 7'h00;
		default:	fnTargetReg = 7'h00;
		endcase
end
endfunction
/*
function fnAllowedReg;
input [8:0] regno;
fnAllowedReg = allowedRegs[regno] ? regno : 9'h000;
endfunction
*/
function fnTargetsCa;
input [63:0] ir;
begin
if (ir[3:0]==4'h0)
	fnTargetsCa = `FALSE;
else begin
	case(fnOpcode(ir))
	`JSR,`JSRZ,`JSRS,`SYS,`INT:
	       fnTargetsCa = `TRUE;
	`LWS:
		if (ir[27:26]==2'h1)
			fnTargetsCa = `TRUE;
		else
			fnTargetsCa = `FALSE;
	`LDIS:
		if (ir[21:20]==2'h1)
			fnTargetsCa = `TRUE;
		else
			fnTargetsCa = `FALSE;
	`MTSPR,`MOVS:
		begin
			if (ir[27:26]==2'h1)
				fnTargetsCa = `TRUE;
			else
				fnTargetsCa = `FALSE;
		end
	default:	fnTargetsCa = `FALSE;
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
	`LWS:
		if (ir[27:26]==2'h2)
			fnTargetsSegreg = `TRUE;
		else
			fnTargetsSegreg = `FALSE;
	`LDIS:
		if (ir[21:20]==2'h2)
			fnTargetsSegreg = `TRUE;
		else
			fnTargetsSegreg = `FALSE;
	`MTSPR,`MOVS:
		if (ir[27:26]==2'h2)
			fnTargetsSegreg = `TRUE;
		else
			fnTargetsSegreg = `FALSE;
	default:	fnTargetsSegreg = `FALSE;
	endcase
endfunction

function fnHasConst;
input [7:0] opcode;
	casex(opcode)
	`BFCLR,`BFSET,`BFCHG,`BFEXT,`BFEXTU,`BFINS,
	`LDI,`LDIS,`ADDUIS,
	`ADDI,`SUBI,`ADDUI,`SUBUI,`MULI,`MULUI,`DIVI,`DIVUI,
	`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI,
	`CMPI,
	`ANDI,`ORI,`EORI,
//	`SHLI,`SHLUI,`SHRI,`SHRUI,`ROLI,`RORI,
	`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWS,`LEA,
	`LVB,`LVC,`LVH,`LVW,`STI,
	`SB,`SC,`SH,`SW,`CAS,`SWS,
	`JSR,`JSRS,`SYS,`INT,`BR:
		fnHasConst = 1'b1;
	default:
		fnHasConst = 1'b0;
	endcase
endfunction

function fnIsFlowCtrl;
input [7:0] opcode;
begin
casex(opcode)
`JSR,`JSRS,`JSRZ,`SYS,`INT,`BR,`RTS,`RTI,`RTE:
	fnIsFlowCtrl = 1'b1;
default:	fnIsFlowCtrl = 1'b0;
endcase
end
endfunction

function fnCanException;
input [7:0] op;
case(op)
`ADD,`ADDI,`SUB,`SUBI,`DIV,`DIVI,`MUL,`MULI:
    fnCanException = `TRUE;
default:
    fnCanException = fnIsMem(op) | fnIsFP(op);
endcase
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
	`NOP,`SEI,`CLI,`RTI,`RTE,`MEMSB,`MEMDB,`SYNC:
		fnInsnLength = 4'd2;
	`TST,`BR,`JSRZ,`RTS:
		fnInsnLength = 4'd3;
	`SYS,`CMP,`CMPI,`MTSPR,`MFSPR,`LDI,`LDIS,`ADDUIS,`NEG,`NOT,`MOV,`TLB,`MOVS:
		fnInsnLength = 4'd4;
	`BITFIELD,`JSR,`MUX,`BCD:
		fnInsnLength = 4'd6;
	`CAS:
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
			opcode==`STS ||
			opcode==`LVB || opcode==`LVC || opcode==`LVH || opcode==`LVW ||
			opcode==`TLB || opcode==`CAS ||
			opcode==`LWS || opcode==`SWS || opcode==`STI
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
			opcode==`LVB || opcode==`LVH || opcode==`LVC || opcode==`LVW ||
			opcode==`CAS || opcode==`LWS ||
			opcode==`STS ||
			opcode==`ADDI || opcode==`SUBI || opcode==`ADDUI || opcode==`SUBUI || opcode==`MULI || opcode==`MULUI || opcode==`DIVI || opcode==`DIVUI ||
			opcode==`ANDI || opcode==`ORI || opcode==`EORI ||
			opcode==`ADD || opcode==`SUB || opcode==`ADDU || opcode==`SUBU || opcode==`MUL || opcode==`MULU || opcode==`DIV || opcode==`DIVU ||
			opcode==`AND || opcode==`OR || opcode==`EOR || opcode==`NAND || opcode==`NOR || opcode==`ENOR || opcode==`ANDC || opcode==`ORC ||
			opcode==`SHL || opcode==`SHLU || opcode==`SHR || opcode==`SHRU || opcode==`ROL || opcode==`ROR ||
			opcode==`SHLI || opcode==`SHLUI || opcode==`SHRI || opcode==`SHRUI || opcode==`ROLI || opcode==`RORI ||
			opcode==`NOT || opcode==`NEG || opcode==`MOV || opcode==`LEA ||
			opcode==`LDI || opcode==`LDIS || opcode==`ADDUIS || opcode==`MFSPR ||
			// Branch registers / Segment registers
			((opcode==`MTSPR || opcode==`MOVS) && (fnTargetsCa(ir) || fnTargetsSegreg(ir))) ||
			opcode==`JSR || opcode==`JSRS || opcode==`JSRZ || opcode==`SYS || opcode==`INT ||
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
				opcode==`STS ||
				opcode==`SWS || opcode==`STI;
endfunction

function fnIsLoad;
input [7:0] opcode;
fnIsLoad =	opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW || 
			opcode==`LBX || opcode==`LBUX || opcode==`LCX || opcode==`LCUX || opcode==`LHX || opcode==`LHUX || opcode==`LWX ||
			opcode==`LVB || opcode==`LVC || opcode==`LVH || opcode==`LVW ||
			opcode==`LWS;
endfunction

function fnIsLoadV;
input [7:0] opcode;
fnIsLoadV = opcode==`LVB || opcode==`LVC || opcode==`LVH || opcode==`LVW;
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
input [5:0] fn;
input [DBW-1:0] adr;
begin
if (DBW==32)
	case(opcode)
	`STS:
	   case(fn[2:0])
	   3'd0:
           case(adr[1:0])
           3'd0:    fnSelect = 8'h11;
           3'd1:    fnSelect = 8'h22;
           3'd2:    fnSelect = 8'h44;
           3'd3:    fnSelect = 8'h88;
           endcase
       3'd1:
		   case(adr[1])
           1'd0:    fnSelect = 8'h33;
           1'd1:    fnSelect = 8'hCC;
           endcase
       3'd2:
    		fnSelect = 8'hFF;
       default: fnSelect = 8'h00;
       endcase
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
	`LW,`LWX,`SW,`LVW,`SWX,`CAS,`LWS,`SWS,`STI:
		fnSelect = 8'hFF;
	default:	fnSelect = 8'h00;
	endcase
else
	case(opcode)
	`STS:
       case(fn[2:0])
       3'd0:
           case(adr[2:0])
           3'd0:    fnSelect = 8'h01;
           3'd1:    fnSelect = 8'h02;
           3'd2:    fnSelect = 8'h04;
           3'd3:    fnSelect = 8'h08;
           3'd4:    fnSelect = 8'h10;
           3'd5:    fnSelect = 8'h20;
           3'd6:    fnSelect = 8'h40;
           3'd7:    fnSelect = 8'h80;
           endcase
       3'd1:
           case(adr[2:1])
           2'd0:    fnSelect = 8'h03;
           2'd1:    fnSelect = 8'h0C;
           2'd2:    fnSelect = 8'h30;
           2'd3:    fnSelect = 8'hC0;
           endcase
       3'd2:
           case(adr[2])
           1'b0:    fnSelect = 8'h0F;
           1'b1:    fnSelect = 8'hF0;
           endcase
       3'd3:
           fnSelect = 8'hFF;
       default: fnSelect = 8'h00;
       endcase
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
	`LW,`LWX,`SW,`LVW,`SWX,`CAS,`LWS,`SWS,`STI:
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
	`LH,`LHU,`LW,`LWX,`LVH,`LVW,`LHX,`LHUX,`CAS,`LWS:
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
	`LW,`LWX,`LVW,`CAS,`LWS:
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
	`SW,`SWX,`CAS,`SWS,`STI:	fnDatao = dat;
	`SH,`SHX:	fnDatao = dat;
	`SC,`SCX:	fnDatao = {2{dat[15:0]}};
	`SB,`SBX:	fnDatao = {4{dat[7:0]}};
	default:	fnDatao = dat;
	endcase
else
	case(opcode)
	`SW,`SWX,`CAS,`SWS,`STI:	fnDatao = dat;
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
assign fetchbuf0_fp		= fnIsFP(opcode0);
assign fetchbuf1_fp		= fnIsFP(opcode1);
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
			fetchbuf0_pc + {{DBW-12{fetchbuf0_instr[11]}},fetchbuf0_instr[11:8],fetchbuf0_instr[23:16]} + 64'd3:
			fetchbuf1_pc + {{DBW-12{fetchbuf1_instr[11]}},fetchbuf1_instr[11:8],fetchbuf1_instr[23:16]} + 64'd3;


assign int_pending = (nmi_edge & ~StatusHWI & ~int_commit) || (irq_i & ~im & ~StatusHWI & ~int_commit);

// "Stream" interrupt instructions into the instruction stream until an INT
// instruction commits. This avoids the problem of an INT instruction being
// stomped on by a previous branch instruction.
// Populate the instruction buffers with INT instructions for a hardware interrupt
// Also populate the instruction buffers with a call to the instruction error vector
// if an error occurred during instruction load time.
// Translate the BRK opcode to a syscall.

// There is a one cycle delay in setting the StatusHWI that allowed an extra INT
// instruction to sneek into the queue. This is NOPped out by the int_commit
// signal.

// On a cache miss the instruction buffers are loaded with NOPs this prevents
// the PC from being trashed by invalid branch instructions.
reg [63:0] insn1a;
reg [63:0] insn0,insn1;
always @(nmi_edge or StatusHWI or int_commit or irq_i or im or insnerr or insn or vec_i or ITLBMiss or ihit or iuncached or ibufhit or ierr or ibuf)
//if (int_commit)
//	insn0 <= {8{8'h10}};	// load with NOPs
//else
if (nmi_edge & ~StatusHWI & ~int_commit)
	insn0 <= {8'hFE,8'hCE,8'hA6,8'h01,8'hFE,8'hCE,8'hA6,8'h01};
else if (ITLBMiss)
	insn0 <= {8'hF9,8'hCE,8'hA6,8'h01,8'hF9,8'hCE,8'hA6,8'h01};
else if (insnerr)
	insn0 <= {8'hFC,8'hCE,8'hA6,8'h01,8'hFC,8'hCE,8'hA6,8'h01};
else if (irq_i & ~im & ~StatusHWI & ~int_commit)
	insn0 <= {vec_i,8'hCE,8'hA6,8'h01,vec_i,8'hCE,8'hA6,8'h01};
else if (iuncached) begin
	if (ibufhit) begin
		if (ierr) 
			insn0 <= {8'hFC,8'hCE,8'hA6,8'h01,8'hFC,8'hCE,8'hA6,8'h01};
		else if (ibuf[7:0]==8'h00)
			insn0 <= {8'h00,8'hCD,8'hA5,8'h01,8'h00,8'hCD,8'hA5,8'h01};
		else
			insn0 <= ibuf[63:0];
	end
	else
		insn0 <= {8{8'h10}};	// load with NOPs
end
else if (ihit) begin
	if (insn[7:0]==8'h00)
		insn0 <= {8'h00,8'hCD,8'hA5,8'h01,8'h00,8'hCD,8'hA5,8'h01};
	else
		insn0 <= insn[63:0];
end
else
	insn0 <= {8{8'h10}};	// load with NOPs


always @(nmi_edge or StatusHWI or int_commit or irq_i or im or insnerr or insn1a or vec_i or ITLBMiss or ihit or ierr or ibufhit or iuncached)
//if (int_commit)
//	insn1 <= {8{8'h10}};	// load with NOPs
//else
if (nmi_edge & ~StatusHWI & ~int_commit)
	insn1 <= {8'hFE,8'hCE,8'hA6,8'h01,8'hFE,8'hCE,8'hA6,8'h01};
else if (ITLBMiss)
	insn1 <= {8'hF9,8'hCE,8'hA6,8'h01,8'hF9,8'hCE,8'hA6,8'h01};
else if (insnerr)
	insn1 <= {8'hFC,8'hCE,8'hA6,8'h01,8'hFC,8'hCE,8'hA6,8'h01};
else if (irq_i & ~im & ~StatusHWI & ~int_commit)
	insn1 <= {vec_i,8'hCE,8'hA6,8'h01,vec_i,8'hCE,8'hA6,8'h01};
else if (iuncached) begin
	if (ibufhit) begin
		if (ierr)
			insn1 <= {8'hFC,8'hCE,8'hA6,8'h01,8'hFC,8'hCE,8'hA6,8'h01};
		else if (insn1a[7:0]==8'h00)
			insn1 <= {8'h00,8'hCD,8'hA5,8'h01,8'h00,8'hCD,8'hA5,8'h01};
		else
			insn1 <= insn1a[63:0];
	end
	else
		insn1 <= {8{8'h10}};	// load with NOPs
end
else if (ihit) begin
	if (insn1a[7:0]==8'h00)
		insn1 <= {8'h00,8'hCD,8'hA5,8'h01,8'h00,8'hCD,8'hA5,8'h01};
	else
		insn1 <= insn1a;
end
else
	insn1 <= {8{8'h10}};	// load with NOPs


// Find the second instruction in the instruction line.
always @(insn or iuncached or ibuf)
if (iuncached)
	case(fnInsnLength(ibuf))
	4'd1:	insn1a <= ibuf[71: 8];
	4'd2:	insn1a <= ibuf[79:16];
	4'd3:	insn1a <= ibuf[87:24];
	4'd4:	insn1a <= ibuf[95:32];
	4'd5:	insn1a <= ibuf[103:40];
	4'd6:	insn1a <= ibuf[111:48];
	4'd7:	insn1a <= ibuf[119:56];
	4'd8:	insn1a <= ibuf[127:64];
	default:	insn1a <= {8{8'h10}};	// NOPs
	endcase
else
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
function [63:0] fnImm;
input [127:0] insn;
casex(insn[15:8])
`CAS:	fnImm = {{56{insn[47]}},insn[47:40]};
`BCD:	fnImm = insn[47:40];
`TLB:	fnImm = insn[23:16];
`LOOP:	fnImm = {{56{insn[23]}},insn[23:16]};
`JSR:	fnImm = {{40{insn[47]}},insn[47:24]};
`JSRS:  fnImm = {{48{insn[39]}},insn[39:24]};
`BITFIELD:	fnImm = insn[47:32];
`SYS,`INT:	fnImm = insn[31:24];
`CMPI,`LDI,`LDIS,`ADDUIS:
	fnImm = {{54{insn[31]}},insn[31:22]};
`LDIT10:	fnImm = {insn[31:22],54'd0};
`RTS:	fnImm = insn[19:16];
`RTE,`RTI,`JSRZ:	fnImm = 8'h00;
`STI:	fnImm = {{56{insn[39]}},insn[39:32]};
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LVB,`LVC,`LVH,`LVW,`SB,`SC,`SH,`SW:
	fnImm = {{52{insn[39]}},insn[39:28]};
default:
	fnImm = {{52{insn[39]}},insn[39:28]};
endcase

endfunction

function [7:0] fnImm8;
input [127:0] insn;
casex(insn[15:8])
`CAS:	fnImm8 = insn[47:40];
`BCD:	fnImm8 = insn[47:40];
`TLB:	fnImm8 = insn[23:16];
`LOOP:	fnImm8 = insn[23:16];
`JSR,`JSRS:	fnImm8 = insn[31:24];
`BITFIELD:	fnImm8 = insn[39:32];
`SYS,`INT:	fnImm8 = insn[31:24];
`CMPI,`LDI,`LDIS,`ADDUIS:	fnImm8 = insn[29:22];
`RTS:	fnImm8 = insn[19:16];
`RTE,`RTI,`JSRZ:	fnImm8 = 8'h00;
`STI:	fnImm8 = insn[39:32];
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LVB,`LVC,`LVH,`LVW,`SB,`SC,`SH,`SW:
	fnImm8 = insn[35:28];
default:	fnImm8 = insn[35:28];
endcase
endfunction

// Return MSB of immediate value for instruction
function fnImmMSB;
input [127:0] insn;

casex(insn[15:8])
`CAS:	fnImmMSB = insn[47];
`TLB,`BCD:
	fnImmMSB = 1'b0;		// TLB regno is unsigned
`LOOP:
	fnImmMSB = insn[23];
`JSR:
	fnImmMSB = insn[47];
`JSRS:
    fnImmMSB = insn[39];
`CMPI,`LDI,`LDIS,`ADDUIS:
	fnImmMSB = insn[31];
`SYS,`INT:
	fnImmMSB = 1'b0;		// SYS,INT are unsigned
`RTS,`RTE,`RTI,`JSRZ:
	fnImmMSB = 1'b0;		// RTS is unsigned
`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,
`SBX,`SCX,`SHX,`SWX:
	fnImmMSB = insn[47];
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LVB,`LVC,`LVH,`LVW,`SB,`SC,`SH,`SW,`STI:
	fnImmMSB = insn[39];
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
		fnOpa = fnCar(ins)==4'd0 ? 64'd0 : fnCar(ins)==4'd15 ? epc :
			(commit0_v && commit0_tgt[6:4]==3'h5 && commit0_tgt[3:0]==fnCar(ins)) ? commit0_bus :
			cregs[fnCar(ins)];
	else if (opcode==`MFSPR || opcode==`SWS || opcode==`MOVS)
		casex(ins[21:16])
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
		`ASID:	fnOpa = asid;
		`SR:	fnOpa = sr;
		6'h1x:	fnOpa = ins[19:16]==4'h0 ? 64'd0 : ins[19:16]==4'hF ? epc :
						(commit0_v && commit0_tgt[6:4]==3'h5 && commit0_tgt[3:0]==ins[19:16]) ? commit0_bus :
						cregs[ins[19:16]];
`ifdef SEGMENTATION
		6'h2x:	fnOpa = 
			(commit0_v && commit0_tgt[6:4]==3'h6 && commit0_tgt[3:0]==ins[18:16]) ? {commit0_bus[DBW-1:12],12'h000} :
			{sregs[ins[18:16]],12'h000};
`endif
		default:	fnOpa = 64'h0;
		endcase
	else
		fnOpa = rfo;
end
endfunction

function [15:0] fnRegstrGrp;
input [6:0] Rn;
if (!Rn[6]) begin
	fnRegstrGrp="GP";
end
else
	case(Rn[5:4])
	2'h0:	fnRegstrGrp="PR";
	2'h1:	fnRegstrGrp="CA";
	2'h2:	fnRegstrGrp="SG";
	endcase

endfunction

function [7:0] fnRegstr;
input [6:0] Rn;
begin
if (!Rn[6]) begin
	fnRegstr = Rn[5:0];
end
else
	fnRegstr = Rn[3:0];
end
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

//`include "Thor_issue_combo.v"
/*
assign  iqentry_imm[0] = fnHasConst(iqentry_op[0]),
	iqentry_imm[1] = fnHasConst(iqentry_op[1]),
	iqentry_imm[2] = fnHasConst(iqentry_op[2]),
	iqentry_imm[3] = fnHasConst(iqentry_op[3]),
	iqentry_imm[4] = fnHasConst(iqentry_op[4]),
	iqentry_imm[5] = fnHasConst(iqentry_op[5]),
	iqentry_imm[6] = fnHasConst(iqentry_op[6]),
	iqentry_imm[7] = fnHasConst(iqentry_op[7]);
*/
//
// additional logic for ISSUE
//
// for the moment, we look at ALU-input buffers to allow back-to-back issue of 
// dependent instructions ... we do not, however, look ahead for DRAM requests 
// that will become valid in the next cycle.  instead, these have to propagate
// their results into the IQ entry directly, at which point it becomes issue-able
//

wire [QENTRIES-1:0] args_valid;
wire [QENTRIES-1:0] could_issue;

genvar g;
generate
begin : argsv

for (g = 0; g < QENTRIES; g = g + 1)
begin
assign  iqentry_imm[g] = fnHasConst(iqentry_op[g]);

assign args_valid[g] =
			(iqentry_p_v[g]
				|| (iqentry_p_s[g]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[g]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[g] 
				|| (iqentry_a1_s[g] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[g] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[g] 
				|| (iqentry_mem[g] & ~iqentry_agen[g])
				|| (iqentry_a2_s[g] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[g] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[g] 
				|| (iqentry_mem[g] & ~iqentry_agen[g])
				|| (iqentry_a3_s[g] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[g] == alu1_sourceid && alu1_dataready));

assign could_issue[g] = iqentry_v[g] && !iqentry_out[g] && !iqentry_agen[g] && args_valid[g];
end
end
endgenerate
/*
assign args_valid[0] =
			(iqentry_p_v[3'd0]
				|| (iqentry_p_s[3'd0]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd0]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[0] 
				|| (iqentry_a1_s[0] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[0] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[0] 
				|| (iqentry_mem[0] & ~iqentry_agen[0])
				|| (iqentry_a2_s[0] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[0] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[0] 
				|| (iqentry_mem[0] & ~iqentry_agen[0])
				|| (iqentry_a3_s[0] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[0] == alu1_sourceid && alu1_dataready));

assign args_valid[1] =
			(iqentry_p_v[3'd1]
				|| (iqentry_p_s[3'd1]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd1]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[1] 
				|| (iqentry_a1_s[1] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[1] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[1] 
				|| (iqentry_mem[1] & ~iqentry_agen[1])
				|| (iqentry_a2_s[1] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[1] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[1] 
				|| (iqentry_mem[1] & ~iqentry_agen[1])
				|| (iqentry_a3_s[1] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[1] == alu1_sourceid && alu1_dataready));

assign args_valid[2] =
			(iqentry_p_v[3'd2]
				|| (iqentry_p_s[3'd2]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd2]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[2] 
				|| (iqentry_a1_s[2] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[2] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[2] 
				|| (iqentry_mem[2] & ~iqentry_agen[2])
				|| (iqentry_a2_s[2] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[2] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[2] 
				|| (iqentry_mem[2] & ~iqentry_agen[2])
				|| (iqentry_a3_s[2] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[2] == alu1_sourceid && alu1_dataready));

assign args_valid[3] =
			(iqentry_p_v[3'd3]
				|| (iqentry_p_s[3'd3]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd3]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[3] 
				|| (iqentry_a1_s[3] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[3] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[3] 
				|| (iqentry_mem[3] & ~iqentry_agen[3])
				|| (iqentry_a2_s[3] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[3] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[3] 
				|| (iqentry_mem[3] & ~iqentry_agen[3])
				|| (iqentry_a3_s[3] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[3] == alu1_sourceid && alu1_dataready));

assign args_valid[4] =
			(iqentry_p_v[3'd4]
				|| (iqentry_p_s[3'd4]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd4]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[4] 
				|| (iqentry_a1_s[4] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[4] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[4] 
				|| (iqentry_mem[4] & ~iqentry_agen[4])
				|| (iqentry_a2_s[4] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[4] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[4] 
				|| (iqentry_mem[4] & ~iqentry_agen[4])
				|| (iqentry_a3_s[4] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[4] == alu1_sourceid && alu1_dataready));

assign args_valid[5] =
			(iqentry_p_v[3'd5]
				|| (iqentry_p_s[3'd5]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd5]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[5] 
				|| (iqentry_a1_s[5] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[5] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[5] 
				|| (iqentry_mem[5] & ~iqentry_agen[5])
				|| (iqentry_a2_s[5] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[5] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[5] 
				|| (iqentry_mem[5] & ~iqentry_agen[5])
				|| (iqentry_a3_s[5] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[5] == alu1_sourceid && alu1_dataready));

assign args_valid[6] =
			(iqentry_p_v[3'd6]
				|| (iqentry_p_s[3'd6]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd6]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[6] 
				|| (iqentry_a1_s[6] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[6] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[6] 
				|| (iqentry_mem[6] & ~iqentry_agen[6])
				|| (iqentry_a2_s[6] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[6] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[6] 
				|| (iqentry_mem[6] & ~iqentry_agen[6])
				|| (iqentry_a3_s[6] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[6] == alu1_sourceid && alu1_dataready));

assign args_valid[7] =
			(iqentry_p_v[3'd7]
				|| (iqentry_p_s[3'd7]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd7]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[7] 
				|| (iqentry_a1_s[7] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[7] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[7] 
				|| (iqentry_mem[7] & ~iqentry_agen[7])
				|| (iqentry_a2_s[7] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[7] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[7] 
				|| (iqentry_mem[7] & ~iqentry_agen[7])
				|| (iqentry_a3_s[7] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[7] == alu1_sourceid && alu1_dataready));

assign could_issue[0] = iqentry_v[0] && !iqentry_out[0] && !iqentry_agen[0] && args_valid[0];
assign could_issue[1] = iqentry_v[1] && !iqentry_out[1] && !iqentry_agen[1] && args_valid[1];
assign could_issue[2] = iqentry_v[2] && !iqentry_out[2] && !iqentry_agen[2] && args_valid[2];
assign could_issue[3] = iqentry_v[3] && !iqentry_out[3] && !iqentry_agen[3] && args_valid[3];
assign could_issue[4] = iqentry_v[4] && !iqentry_out[4] && !iqentry_agen[4] && args_valid[4];
assign could_issue[5] = iqentry_v[5] && !iqentry_out[5] && !iqentry_agen[5] && args_valid[5];
assign could_issue[6] = iqentry_v[6] && !iqentry_out[6] && !iqentry_agen[6] && args_valid[6];
assign could_issue[7] = iqentry_v[7] && !iqentry_out[7] && !iqentry_agen[7] && args_valid[7];

wire any_sync =
	   (iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	|| (iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	|| (iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	|| (iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	|| (iqentry_v[head4] && iqentry_op[head4]==`SYNC)
	|| (iqentry_v[head5] && iqentry_op[head5]==`SYNC)
	|| (iqentry_v[head6] && iqentry_op[head6]==`SYNC)
	;
*/
// The simulator didn't handle the asynchronous race loop properly in the 
// original code. It would issue two instructions to the same islot. So the
// issue logic has been re-written to eliminate the asynchronous loop.
// Not that this issue logic won't isse the second instruction if there is
// a valid SYNC instruction ANYWHERE in the instruction queue. This is to
// save a bunch of compare logic. 
always @(could_issue or head0 or head1 or head2 or head3 or head4 or head5 or head6 or head7)
begin
	iqentry_issue = 8'h00;
	iqentry_islot[0] = 2'b00;
	iqentry_islot[1] = 2'b00;
	iqentry_islot[2] = 2'b00;
	iqentry_islot[3] = 2'b00;
	iqentry_islot[4] = 2'b00;
	iqentry_islot[5] = 2'b00;
	iqentry_islot[6] = 2'b00;
	iqentry_islot[7] = 2'b00;
	if (could_issue[head0] & !iqentry_fp[head0]) begin
		iqentry_issue[head0] = `TRUE;
		iqentry_islot[head0] = 2'b00;
	end
	else if (could_issue[head1] & !iqentry_fp[head1]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC))
	begin
		iqentry_issue[head1] = `TRUE;
		iqentry_islot[head1] = 2'b00;
	end
	else if (could_issue[head2] & !iqentry_fp[head2]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	)
	begin
		iqentry_issue[head2] = `TRUE;
		iqentry_islot[head2] = 2'b00;
	end
	else if (could_issue[head3] & !iqentry_fp[head3]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	) begin
		iqentry_issue[head3] = `TRUE;
		iqentry_islot[head3] = 2'b00;
	end
	else if (could_issue[head4] & !iqentry_fp[head4]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	) begin
		iqentry_issue[head4] = `TRUE;
		iqentry_islot[head4] = 2'b00;
	end
	else if (could_issue[head5] & !iqentry_fp[head5]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`SYNC)
	) begin
		iqentry_issue[head5] = `TRUE;
		iqentry_islot[head5] = 2'b00;
	end
	else if (could_issue[head6] & !iqentry_fp[head6]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`SYNC)
	&& !(iqentry_v[head5] && iqentry_op[head5]==`SYNC)
	) begin
		iqentry_issue[head6] = `TRUE;
		iqentry_islot[head6] = 2'b00;
	end
	else if (could_issue[head7] & !iqentry_fp[head7]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`SYNC)
	&& !(iqentry_v[head5] && iqentry_op[head5]==`SYNC)
	&& !(iqentry_v[head6] && iqentry_op[head6]==`SYNC)
	) begin
		iqentry_issue[head7] = `TRUE;
		iqentry_islot[head7] = 2'b00;
	end

    // Don't bother checking head0, it should have issued to the first
    // instruction.
	if (could_issue[head1] && !iqentry_fp[head1] && !iqentry_issue[head1]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC))
	begin
		iqentry_issue[head1] = `TRUE;
		iqentry_islot[head1] = 2'b01;
	end
	else if (could_issue[head2] && !iqentry_fp[head2] && !iqentry_issue[head2]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	)
	begin
		iqentry_issue[head2] = `TRUE;
		iqentry_islot[head2] = 2'b01;
	end
	else if (could_issue[head3] & !iqentry_fp[head3] && !iqentry_issue[head3]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	) begin
		iqentry_issue[head3] = `TRUE;
		iqentry_islot[head3] = 2'b01;
	end
	else if (could_issue[head4] & !iqentry_fp[head4] && !iqentry_issue[head4]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	) begin
		iqentry_issue[head4] = `TRUE;
		iqentry_islot[head4] = 2'b01;
	end
	else if (could_issue[head5] & !iqentry_fp[head5] && !iqentry_issue[head5]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`SYNC)
	) begin
		iqentry_issue[head5] = `TRUE;
		iqentry_islot[head5] = 2'b01;
	end
	else if (could_issue[head6] & !iqentry_fp[head6] && !iqentry_issue[head6]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`SYNC)
	&& !(iqentry_v[head5] && iqentry_op[head5]==`SYNC)
	) begin
		iqentry_issue[head6] = `TRUE;
		iqentry_islot[head6] = 2'b01;
	end
	else if (could_issue[head7] & !iqentry_fp[head7] && !iqentry_issue[head7]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`SYNC)
	&& !(iqentry_v[head5] && iqentry_op[head5]==`SYNC)
	&& !(iqentry_v[head6] && iqentry_op[head6]==`SYNC)
	) begin
		iqentry_issue[head7] = `TRUE;
		iqentry_islot[head7] = 2'b01;
	end

/*
	if (ispot != 4'd8 && !any_sync) begin
		if (could_issue[ispot+1] && !iqentry_issue[ispot+1] && !iqentry_fp[ispot+1]
    	&& !(iqentry_v[ispot+1] && iqentry_op[ispot+1]==`SYNC)
		) begin
			iqentry_issue[ispot+1] = `TRUE;
			iqentry_islot[ispot+1] = 2'b01;
		end
		else if (could_issue[ispot+2] && !iqentry_issue[ispot+2] & !iqentry_fp[ispot+2]
    	&& !(iqentry_v[ispot+1] && iqentry_op[ispot+1]==`SYNC)
    	&& !(iqentry_v[ispot+1] && iqentry_op[ispot+1]==`SYNC)
		) begin
			iqentry_issue[ispot+2] = `TRUE;
			iqentry_islot[ispot+2] = 2'b01;
		end
		else if (could_issue[ispot+3] && !iqentry_issue[ispot+3] & !iqentry_fp[ispot+3]) begin
			iqentry_issue[ispot+3] = `TRUE;
			iqentry_islot[ispot+3] = 2'b01;
		end
		else if (could_issue[ispot+4] && !iqentry_issue[ispot+4] & !iqentry_fp[ispot+4]) begin
			iqentry_issue[ispot+4] = `TRUE;
			iqentry_islot[ispot+4] = 2'b01;
		end
		else if (could_issue[ispot+5] && !iqentry_issue[ispot+5] & !iqentry_fp[ispot+5]) begin
			iqentry_issue[ispot+5] = `TRUE;
			iqentry_islot[ispot+5] = 2'b01;
		end
		else if (could_issue[ispot+6] && !iqentry_issue[ispot+6] & !iqentry_fp[ispot+6]) begin
			iqentry_issue[ispot+6] = `TRUE;
			iqentry_islot[ispot+6] = 2'b01;
		end
		else if (could_issue[ispot+7] && !iqentry_issue[ispot+7] & !iqentry_fp[ispot+7]) begin
			iqentry_issue[ispot+7] = `TRUE;
			iqentry_islot[ispot+7] = 2'b01;
		end
	end
*/
end


`ifdef FLOATING_POINT
reg [3:0] fpispot;
always @(could_issue or head0 or head1 or head2 or head3 or head4 or head5 or head6 or head7)
begin
	iqentry_fpissue = 8'h00;
	iqentry_fpislot[0] = 2'b00;
	iqentry_fpislot[1] = 2'b00;
	iqentry_fpislot[2] = 2'b00;
	iqentry_fpislot[3] = 2'b00;
	iqentry_fpislot[4] = 2'b00;
	iqentry_fpislot[5] = 2'b00;
	iqentry_fpislot[6] = 2'b00;
	iqentry_fpislot[7] = 2'b00;
	fpispot = head0;
	if (could_issue[head0] & iqentry_fp[head0]) begin
		iqentry_fpissue[head0] = `TRUE;
		iqentry_fpislot[head0] = 2'b00;
		fpispot = head0;
	end
	else if (could_issue[head1] & iqentry_fp[head1]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC))
	begin
		iqentry_fpissue[head1] = `TRUE;
		iqentry_fpislot[head1] = 2'b00;
		fpispot = head1;
	end
	else if (could_issue[head2] & iqentry_fp[head2]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	)
	begin
		iqentry_fpissue[head2] = `TRUE;
		iqentry_fpislot[head2] = 2'b00;
		fpispot = head2;
	end
	else if (could_issue[head3] & iqentry_fp[head3]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	) begin
		iqentry_fpissue[head3] = `TRUE;
		iqentry_fpislot[head3] = 2'b00;
		fpispot = head3;
	end
	else if (could_issue[head4] & iqentry_fp[head4]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	) begin
		iqentry_fpissue[head4] = `TRUE;
		iqentry_fpislot[head4] = 2'b00;
		fpispot = head4;
	end
	else if (could_issue[head5] & iqentry_fp[head5]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`SYNC)
	) begin
		iqentry_fpissue[head5] = `TRUE;
		iqentry_fpislot[head5] = 2'b00;
		fpispot = head5;
	end
	else if (could_issue[head6] & iqentry_fp[head6]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`SYNC)
	&& !(iqentry_v[head5] && iqentry_op[head5]==`SYNC)
	) begin
		iqentry_fpissue[head6] = `TRUE;
		iqentry_fpislot[head6] = 2'b00;
		fpispot = head6;
	end
	else if (could_issue[head7] & iqentry_fp[head7]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`SYNC)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`SYNC)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`SYNC)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`SYNC)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`SYNC)
	&& !(iqentry_v[head5] && iqentry_op[head5]==`SYNC)
	&& !(iqentry_v[head6] && iqentry_op[head6]==`SYNC)
	) begin
		iqentry_fpissue[head7] = `TRUE;
		iqentry_fpislot[head7] = 2'b00;
		fpispot = head7;
	end
	else
		fpispot = 4'd8;

//	if (fpispot != 4'd8 && !any_msb) begin
//		if (could_issue[fpispot+1] && !iqentry_fpissue[fpispot+1] && iqentry_fp[fpispot+1]) begin
//			iqentry_fpissue[fpispot+1] = `TRUE;
//			iqentry_fpislot[fpispot+1] = 2'b01;
//		end
//		else if (could_issue[fpispot+2] && !iqentry_fpissue[fpispot+2] && iqentry_fp[fpispot+2]) begin
//			iqentry_fpissue[fpispot+2] = `TRUE;
//			iqentry_fpislot[fpispot+2] = 2'b01;
//		end
//		else if (could_issue[fpispot+3] && !iqentry_fpissue[fpispot+3] && iqentry_fp[fpispot+3]) begin
//			iqentry_fpissue[fpispot+3] = `TRUE;
//			iqentry_fpislot[fpispot+3] = 2'b01;
//		end
//		else if (could_issue[fpispot+4] && !iqentry_fpissue[fpispot+4] && iqentry_fp[fpispot+4]) begin
//			iqentry_fpissue[fpispot+4] = `TRUE;
//			iqentry_fpislot[fpispot+4] = 2'b01;
//		end
//		else if (could_issue[fpispot+5] && !iqentry_fpissue[fpispot+5] && iqentry_fp[fpispot+5]) begin
//			iqentry_fpissue[fpispot+5] = `TRUE;
//			iqentry_fpislot[fpispot+5] = 2'b01;
//		end
//		else if (could_issue[fpispot+6] && !iqentry_fpissue[fpispot+6] && iqentry_fp[fpispot+6]) begin
//			iqentry_fpissue[fpispot+6] = `TRUE;
//			iqentry_fpislot[fpispot+6] = 2'b01;
//		end
//		else if (could_issue[fpispot+7] && !iqentry_fpissue[fpispot+7] && iqentry_fp[fpispot+7]) begin
//			iqentry_fpissue[fpispot+7] = `TRUE;
//			iqentry_fpislot[fpispot+7] = 2'b01;
//		end
//	end
end
`endif

assign stomp_all = fnIsStoreString(iqentry_op[head0]) && int_pending;

// 
// additional logic for handling a branch miss (STOMP logic)
//
assign
	iqentry_stomp[0] = stomp_all || (branchmiss && iqentry_v[0] && head0 != 3'd0 && (missid == 3'd7 || iqentry_stomp[7])),
	iqentry_stomp[1] = stomp_all || (branchmiss && iqentry_v[1] && head0 != 3'd1 && (missid == 3'd0 || iqentry_stomp[0])),
	iqentry_stomp[2] = stomp_all || (branchmiss && iqentry_v[2] && head0 != 3'd2 && (missid == 3'd1 || iqentry_stomp[1])),
	iqentry_stomp[3] = stomp_all || (branchmiss && iqentry_v[3] && head0 != 3'd3 && (missid == 3'd2 || iqentry_stomp[2])),
	iqentry_stomp[4] = stomp_all || (branchmiss && iqentry_v[4] && head0 != 3'd4 && (missid == 3'd3 || iqentry_stomp[3])),
	iqentry_stomp[5] = stomp_all || (branchmiss && iqentry_v[5] && head0 != 3'd5 && (missid == 3'd4 || iqentry_stomp[4])),
	iqentry_stomp[6] = stomp_all || (branchmiss && iqentry_v[6] && head0 != 3'd6 && (missid == 3'd5 || iqentry_stomp[5])),
	iqentry_stomp[7] = stomp_all || (branchmiss && iqentry_v[7] && head0 != 3'd7 && (missid == 3'd6 || iqentry_stomp[6]));


assign alu0_issue = (!(iqentry_v[0] && iqentry_stomp[0]) && iqentry_issue[0] && iqentry_islot[0]==2'd0) ||
			(!(iqentry_v[1] && iqentry_stomp[1]) && iqentry_issue[1] && iqentry_islot[1]==2'd0) ||
			(!(iqentry_v[2] && iqentry_stomp[2]) && iqentry_issue[2] && iqentry_islot[2]==2'd0) ||
			(!(iqentry_v[3] && iqentry_stomp[3]) && iqentry_issue[3] && iqentry_islot[3]==2'd0) ||
			(!(iqentry_v[4] && iqentry_stomp[4]) && iqentry_issue[4] && iqentry_islot[4]==2'd0) ||
			(!(iqentry_v[5] && iqentry_stomp[5]) && iqentry_issue[5] && iqentry_islot[5]==2'd0) ||
			(!(iqentry_v[6] && iqentry_stomp[6]) && iqentry_issue[6] && iqentry_islot[6]==2'd0) ||
			(!(iqentry_v[7] && iqentry_stomp[7]) && iqentry_issue[7] && iqentry_islot[7]==2'd0)
			;

assign alu1_issue = (!(iqentry_v[0] && iqentry_stomp[0]) && iqentry_issue[0] && iqentry_islot[0]==2'd1) ||
			(!(iqentry_v[1] && iqentry_stomp[1]) && iqentry_issue[1] && iqentry_islot[1]==2'd1) ||
			(!(iqentry_v[2] && iqentry_stomp[2]) && iqentry_issue[2] && iqentry_islot[2]==2'd1) ||
			(!(iqentry_v[3] && iqentry_stomp[3]) && iqentry_issue[3] && iqentry_islot[3]==2'd1) ||
			(!(iqentry_v[4] && iqentry_stomp[4]) && iqentry_issue[4] && iqentry_islot[4]==2'd1) ||
			(!(iqentry_v[5] && iqentry_stomp[5]) && iqentry_issue[5] && iqentry_islot[5]==2'd1) ||
			(!(iqentry_v[6] && iqentry_stomp[6]) && iqentry_issue[6] && iqentry_islot[6]==2'd1) ||
			(!(iqentry_v[7] && iqentry_stomp[7]) && iqentry_issue[7] && iqentry_islot[7]==2'd1)
			;

`ifdef FLOATING_POINT
assign fp0_issue = (!(iqentry_v[0] && iqentry_stomp[0]) && iqentry_fpissue[0] && iqentry_islot[0]==2'd0) ||
			(!(iqentry_v[1] && iqentry_stomp[1]) && iqentry_fpissue[1] && iqentry_islot[1]==2'd0) ||
			(!(iqentry_v[2] && iqentry_stomp[2]) && iqentry_fpissue[2] && iqentry_islot[2]==2'd0) ||
			(!(iqentry_v[3] && iqentry_stomp[3]) && iqentry_fpissue[3] && iqentry_islot[3]==2'd0) ||
			(!(iqentry_v[4] && iqentry_stomp[4]) && iqentry_fpissue[4] && iqentry_islot[4]==2'd0) ||
			(!(iqentry_v[5] && iqentry_stomp[5]) && iqentry_fpissue[5] && iqentry_islot[5]==2'd0) ||
			(!(iqentry_v[6] && iqentry_stomp[6]) && iqentry_fpissue[6] && iqentry_islot[6]==2'd0) ||
			(!(iqentry_v[7] && iqentry_stomp[7]) && iqentry_fpissue[7] && iqentry_islot[7]==2'd0)
			;
`endif
`include "Thor_execute_combo.v"
//`include "Thor_memory_combo.v"
// additional DRAM-enqueue logic

Thor_TLB #(DBW) utlb1
(
	.rst(rst_i),
	.clk(clk),
	.km(km),
	.pc(spc),
	.ea(dram0_addr),
	.ppc(ppc),
	.pea(pea),
	.iuncached(iuncached),
	.uncached(uncached),
	.m1IsStore(we_o),
	.ASID(asid),
	.op(tlb_op),
	.state(tlb_state),
	.regno(tlb_regno),
	.dati(tlb_data),
	.dato(tlb_dato),
	.ITLBMiss(ITLBMiss),
	.DTLBMiss(DTLBMiss),
	.HTLBVirtPageo()
);
	
assign dram_avail = (dram0 == `DRAMSLOT_AVAIL || dram1 == `DRAMSLOT_AVAIL || dram2 == `DRAMSLOT_AVAIL);

assign  iqentry_memopsvalid[0] = (iqentry_mem[0] & iqentry_a2_v[0] & iqentry_agen[0]),
	iqentry_memopsvalid[1] = (iqentry_mem[1] & iqentry_a2_v[1] & iqentry_agen[1]),
	iqentry_memopsvalid[2] = (iqentry_mem[2] & iqentry_a2_v[2] & iqentry_agen[2]),
	iqentry_memopsvalid[3] = (iqentry_mem[3] & iqentry_a2_v[3] & iqentry_agen[3]),
	iqentry_memopsvalid[4] = (iqentry_mem[4] & iqentry_a2_v[4] & iqentry_agen[4]),
	iqentry_memopsvalid[5] = (iqentry_mem[5] & iqentry_a2_v[5] & iqentry_agen[5]),
	iqentry_memopsvalid[6] = (iqentry_mem[6] & iqentry_a2_v[6] & iqentry_agen[6]),
	iqentry_memopsvalid[7] = (iqentry_mem[7] & iqentry_a2_v[7] & iqentry_agen[7]);

assign  iqentry_memready[0] = (iqentry_v[0] & iqentry_memopsvalid[0] & ~iqentry_memissue[0] & ~iqentry_done[0] & ~iqentry_out[0] & ~iqentry_stomp[0]),
	iqentry_memready[1] = (iqentry_v[1] & iqentry_memopsvalid[1] & ~iqentry_memissue[1] & ~iqentry_done[1] & ~iqentry_out[1] & ~iqentry_stomp[1]),
	iqentry_memready[2] = (iqentry_v[2] & iqentry_memopsvalid[2] & ~iqentry_memissue[2] & ~iqentry_done[2] & ~iqentry_out[2] & ~iqentry_stomp[2]),
	iqentry_memready[3] = (iqentry_v[3] & iqentry_memopsvalid[3] & ~iqentry_memissue[3] & ~iqentry_done[3] & ~iqentry_out[3] & ~iqentry_stomp[3]),
	iqentry_memready[4] = (iqentry_v[4] & iqentry_memopsvalid[4] & ~iqentry_memissue[4] & ~iqentry_done[4] & ~iqentry_out[4] & ~iqentry_stomp[4]),
	iqentry_memready[5] = (iqentry_v[5] & iqentry_memopsvalid[5] & ~iqentry_memissue[5] & ~iqentry_done[5] & ~iqentry_out[5] & ~iqentry_stomp[5]),
	iqentry_memready[6] = (iqentry_v[6] & iqentry_memopsvalid[6] & ~iqentry_memissue[6] & ~iqentry_done[6] & ~iqentry_out[6] & ~iqentry_stomp[6]),
	iqentry_memready[7] = (iqentry_v[7] & iqentry_memopsvalid[7] & ~iqentry_memissue[7] & ~iqentry_done[7] & ~iqentry_out[7] & ~iqentry_stomp[7]);

assign outstanding_stores = (dram0 && fnIsStore(dram0_op)) || (dram1 && fnIsStore(dram1_op)) || (dram2 && fnIsStore(dram2_op));

// This signal needed to stave off an instruction cache access.
assign mem_will_issue =
	(
	(~iqentry_stomp[0] && iqentry_memissue[0] && iqentry_agen[0] && ~iqentry_out[0] && iqentry_cmt[0] && ihit) ||
	(~iqentry_stomp[1] && iqentry_memissue[1] && iqentry_agen[1] && ~iqentry_out[1] && iqentry_cmt[1] && ihit) ||
	(~iqentry_stomp[2] && iqentry_memissue[2] && iqentry_agen[2] && ~iqentry_out[2] && iqentry_cmt[2] && ihit) ||
	(~iqentry_stomp[3] && iqentry_memissue[3] && iqentry_agen[3] && ~iqentry_out[3] && iqentry_cmt[3] && ihit) ||
	(~iqentry_stomp[4] && iqentry_memissue[4] && iqentry_agen[4] && ~iqentry_out[4] && iqentry_cmt[4] && ihit) ||
	(~iqentry_stomp[5] && iqentry_memissue[5] && iqentry_agen[5] && ~iqentry_out[5] && iqentry_cmt[5] && ihit) ||
	(~iqentry_stomp[6] && iqentry_memissue[6] && iqentry_agen[6] && ~iqentry_out[6] && iqentry_cmt[6] && ihit) ||
	(~iqentry_stomp[7] && iqentry_memissue[7] && iqentry_agen[7] && ~iqentry_out[7] && iqentry_cmt[7] && ihit))
	&& (dram0 == 3'd0 || dram1==3'd0 || dram2==3'd0)
	;

//`include "Thor_commit_combo.v"
// If trying to write to two branch registers at once, or trying to write 
// to two predicate registers at once, then limit the processor to single
// commit.
// The processor does not support writing two registers in the same register
// group at the same time for anything other than the general purpose
// registers. It is possible for the processor to write to two diffent groups
// at the same time.
//assign limit_cmt = (iqentry_rfw[head0] && iqentry_rfw[head1] && iqentry_tgt[head0][8]==1'b1 && iqentry_tgt[head1][8]==1'b1);
assign limit_cmt = 1'b0;
//assign committing2 = (iqentry_v[head0] && iqentry_v[head1] && !limit_cmt) || (head0 != tail0 && head1 != tail0);

assign commit0_v = ({iqentry_v[head0], iqentry_done[head0]} == 2'b11 && ~|panic && iqentry_cmt[head0]);
assign commit1_v = ({iqentry_v[head0], iqentry_done[head0]} != 2'b10 
		&& {iqentry_v[head1], iqentry_done[head1]} == 2'b11 && ~|panic && iqentry_cmt[head1] && !limit_cmt);

assign commit0_id = {iqentry_mem[head0], head0};	// if a memory op, it has a DRAM-bus id
assign commit1_id = {iqentry_mem[head1], head1};	// if a memory op, it has a DRAM-bus id

assign commit0_tgt = iqentry_tgt[head0];
assign commit1_tgt = iqentry_tgt[head1];

assign commit0_bus = iqentry_res[head0];
assign commit1_bus = iqentry_res[head1];

assign int_commit = (iqentry_op[head0]==`INT && commit0_v) || (commit0_v && iqentry_op[head1]==`INT && commit1_v);
assign sys_commit = (iqentry_op[head0]==`SYS && commit0_v) || (commit0_v && iqentry_op[head1]==`SYS && commit1_v);

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
	
	dram_v <= `INV;
	alu0_ld <= 1'b0;
	alu1_ld <= 1'b0;
`ifdef FLOATING_POINT
	fp0_ld <= 1'b0;
`endif

	ic_invalidate <= `FALSE;
	if (rst_i) begin
		GM <= 8'hFF;
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
		sregs[7] <= 52'd0;
		for (i=0; i < 16; i=i+1)
			pregs[i] <= 4'd0;
		asid <= 8'h00;
		rrmapno <= 3'd0;
	end

	// The following registers are always valid
	rf_v[9'h000] = `VAL;
	rf_v[9'h110] = `VAL;	// C0
	rf_v[9'h11F] = `VAL;	// C15 (PC)

	did_branchback <= take_branch;
	did_branchback0 <= take_branch0;
	did_branchback1 <= take_branch1;

	if (branchmiss) begin
		for (n = 1; n < NREGS; n = n + 1)
			if (rf_v[n] == `INV && ~livetarget[n]) rf_v[n] = `VAL;

	    if (|iqentry_0_latestID[NREGS:1])	rf_source[ iqentry_tgt[0] ] <= { iqentry_mem[0], 3'd0 };
	    if (|iqentry_1_latestID[NREGS:1])	rf_source[ iqentry_tgt[1] ] <= { iqentry_mem[1], 3'd1 };
	    if (|iqentry_2_latestID[NREGS:1])	rf_source[ iqentry_tgt[2] ] <= { iqentry_mem[2], 3'd2 };
	    if (|iqentry_3_latestID[NREGS:1])	rf_source[ iqentry_tgt[3] ] <= { iqentry_mem[3], 3'd3 };
	    if (|iqentry_4_latestID[NREGS:1])	rf_source[ iqentry_tgt[4] ] <= { iqentry_mem[4], 3'd4 };
	    if (|iqentry_5_latestID[NREGS:1])	rf_source[ iqentry_tgt[5] ] <= { iqentry_mem[5], 3'd5 };
	    if (|iqentry_6_latestID[NREGS:1])	rf_source[ iqentry_tgt[6] ] <= { iqentry_mem[6], 3'd6 };
	    if (|iqentry_7_latestID[NREGS:1])	rf_source[ iqentry_tgt[7] ] <= { iqentry_mem[7], 3'd7 };

	end

	if (ihit) begin
		$display("\r\n");
		$display("TIME %0d", $time);
	end
//`include "Thor_ifetch.v"
// FETCH
//
// fetch at least two instructions from memory into the fetch buffer
// unless either one of the buffers is still full, in which case we
// do nothing (kinda like alpha approach)
//
if (branchmiss) begin
	$display("pc <= %h", misspc);
	pc <= misspc;
	fetchbuf <= 1'b0;
	fetchbufA_v <= 1'b0;
	fetchbufB_v <= 1'b0;
	fetchbufC_v <= 1'b0;
	fetchbufD_v <= 1'b0;
end
else if (take_branch) begin
	if (fetchbuf == 1'b0) begin
		case ({fetchbufA_v,fetchbufB_v,fetchbufC_v,fetchbufD_v})
		4'b0000:
			begin
				fetchbufC_instr <= insn0;
				fetchbufC_pc <= pc;
				fetchbufC_v <= ld_fetchbuf;
				fetchbufD_instr <= insn1;
				fetchbufD_pc <= pc + fnInsnLength(insn);
				fetchbufD_v <= ld_fetchbuf;
				if (do_pcinc) pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
				fetchbuf <= 1'b1;
			end
		4'b0100:
			begin
				fetchbufC_instr <= insn0;
				fetchbufC_pc <= pc;
				fetchbufC_v <= ld_fetchbuf;
				fetchbufD_instr <= insn1;
				fetchbufD_pc <= pc + fnInsnLength(insn);
				fetchbufD_v <= ld_fetchbuf;
				if (do_pcinc) pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
				fetchbufB_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		4'b0111:
			begin
				fetchbufB_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		4'b1000:
			begin
				fetchbufC_instr <= insn0;
				fetchbufC_v <= ld_fetchbuf;
				fetchbufC_pc <= pc;
				fetchbufD_instr <= insn1;
				fetchbufD_v <= ld_fetchbuf;
				fetchbufD_pc <= pc + fnInsnLength(insn);
				if (do_pcinc) pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
				fetchbufA_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		4'b1011:
			begin
				fetchbufA_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		4'b1100: 
			// Note that there is no point to loading C,D here because
			// there is a predicted taken branch that would stomp on the
			// instructions anyways.
			if (fnIsBranch(opcodeA) && predict_takenA) begin
				pc <= branch_pc;
				fetchbufA_v <= iqentry_v[tail0];
				fetchbufB_v <= `INV;		// stomp on it
				// may as well stick with same fetchbuf
			end
			else begin
				if (did_branchback0) begin
					fetchbufC_instr <= insn0;
					fetchbufC_v <= ld_fetchbuf;
					fetchbufC_pc <= pc;
					fetchbufD_instr <= insn1;
					fetchbufD_v <= ld_fetchbuf;
					fetchbufD_pc <= pc + fnInsnLength(insn);
					if (do_pcinc) pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
					fetchbufA_v <= iqentry_v[tail0];
					fetchbufB_v <= iqentry_v[tail1];
					if (iqentry_v[tail1]==`INV)
						fetchbuf <= 1'b1;
				end
				else begin
					pc <= branch_pc;
					fetchbufA_v <= iqentry_v[tail0];
					fetchbufB_v <= iqentry_v[tail1];
					// may as well keep the same fetchbuffer
				end
			end
		4'b1111:
			begin
				fetchbufA_v <= iqentry_v[tail0];
				fetchbufB_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		default: panic <= `PANIC_INVALIDFBSTATE;
		endcase
	end
	else begin	// fetchbuf==1'b1
		case ({fetchbufC_v,fetchbufD_v,fetchbufA_v,fetchbufB_v})
		4'b0000:
			begin
				fetchbufA_instr <= insn0;
				fetchbufA_pc <= pc;
				fetchbufA_v <= ld_fetchbuf;
				fetchbufB_instr <= insn1;
				fetchbufB_pc <= pc + fnInsnLength(insn);
				fetchbufB_v <= ld_fetchbuf;
				if (do_pcinc) pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
				fetchbuf <= 1'b0;
			end
		4'b0100:
			begin
				fetchbufA_instr <= insn0;
				fetchbufA_pc <= pc;
				fetchbufA_v <= ld_fetchbuf;
				fetchbufB_instr <= insn1;
				fetchbufB_pc <= pc + fnInsnLength(insn);
				fetchbufB_v <= ld_fetchbuf;
				if (do_pcinc) pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
				fetchbufD_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b0;
			end
		4'b0111:
			begin
				fetchbufD_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b0;
			end
		4'b1000:
			begin
				fetchbufA_instr <= insn0;
				fetchbufA_v <= ld_fetchbuf;
				fetchbufA_pc <= pc;
				fetchbufB_instr <= insn1;
				fetchbufB_v <= ld_fetchbuf;
				fetchbufB_pc <= pc + fnInsnLength(insn);
				if (do_pcinc) pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
				fetchbufC_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b0;
			end
		4'b1011:
			begin
				fetchbufC_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b0;
			end
		4'b1100:
			if (fnIsBranch(opcodeC) && predict_takenC) begin
				pc <= branch_pc;
				fetchbufC_v <= iqentry_v[tail0];
				fetchbufD_v <= `INV;		// stomp on it
				// may as well stick with same fetchbuf
			end
			else begin
				if (did_branchback1) begin
					fetchbufA_instr <= insn0;
					fetchbufA_v <= ld_fetchbuf;
					fetchbufA_pc <= pc;
					fetchbufB_instr <= insn1;
					fetchbufB_v <= ld_fetchbuf;
					fetchbufB_pc <= pc + fnInsnLength(insn);
					if (do_pcinc) pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
					fetchbufC_v <= iqentry_v[tail0];
					fetchbufD_v <= iqentry_v[tail1];
					if (iqentry_v[tail1]==`INV)
						fetchbuf <= 1'b0;
				end
				else begin
					pc <= branch_pc;
					fetchbufC_v <= iqentry_v[tail0];
					fetchbufD_v <= iqentry_v[tail1];
					// may as well keep the same fetchbuffer
				end
			end
		4'b1111:
			begin
				fetchbufC_v <= iqentry_v[tail0];
				fetchbufD_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b0;
			end
		default: panic <= `PANIC_INVALIDFBSTATE;
		endcase
	end
end
else begin
	if (fetchbuf == 1'b0)
		case ({fetchbufA_v, fetchbufB_v, ~iqentry_v[tail0], ~iqentry_v[tail1]})
		4'b00_00 : ;
		4'b00_01 : panic <= `PANIC_INVALIDIQSTATE;
		4'b00_10 : ;
		4'b00_11 : ;
		4'b01_00 : ;
		4'b01_01 : panic <= `PANIC_INVALIDIQSTATE;
		4'b01_10,
		4'b01_11 : begin
			fetchbufB_v <= `INV;
			fetchbuf <= 1'b1;
			end
		4'b10_00 : ;
		4'b10_01 : panic <= `PANIC_INVALIDIQSTATE;
		4'b10_10,
		4'b10_11 : begin
			fetchbufA_v <= `INV;
			fetchbuf <= 1'b1;
			end
		4'b11_00 : ;
		4'b11_01 : panic <= `PANIC_INVALIDIQSTATE;
		4'b11_10 : begin
			fetchbufA_v <= `INV;
			end
		4'b11_11 : begin
			fetchbufA_v <= `INV;
			fetchbufB_v <= `INV;
			fetchbuf <= 1'b1;
			end
		endcase
	else
		case ({fetchbufC_v, fetchbufD_v, ~iqentry_v[tail0], ~iqentry_v[tail1]})
		4'b00_00 : ;
		4'b00_01 : panic <= `PANIC_INVALIDIQSTATE;
		4'b00_10 : ;
		4'b00_11 : ;
		4'b01_00 : ;
		4'b01_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b01_10,
		4'b01_11 : begin
			fetchbufD_v <= `INV;
			fetchbuf <= 1'b0;
			end

		4'b10_00 : ;
		4'b10_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b10_10,
		4'b10_11 : begin
			fetchbufC_v <= `INV;
			fetchbuf <= 1'b0;
			end

		4'b11_00 : ;
		4'b11_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b11_10 : begin
			fetchbufC_v <= `INV;
			end

		4'b11_11 : begin
			fetchbufC_v <= `INV;
			fetchbufD_v <= `INV;
			fetchbuf <= 1'b0;
			end
		endcase
	if (fetchbufA_v == `INV && fetchbufB_v == `INV) begin
		fetchbufA_instr <= insn0;
		fetchbufA_v <= ld_fetchbuf;
		fetchbufA_pc <= pc;
		fetchbufB_instr <= insn1;
		fetchbufB_v <= ld_fetchbuf;
		fetchbufB_pc <= pc + fnInsnLength(insn);
		if (do_pcinc) pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
		// fetchbuf steering logic correction
		if (fetchbufC_v==`INV && fetchbufD_v==`INV && do_pcinc)
			fetchbuf <= 1'b0;
		$display("hit %b 1pc <= %h", do_pcinc, pc + fnInsnLength(insn) + fnInsnLength1(insn));
	end
	else if (fetchbufC_v == `INV && fetchbufD_v == `INV) begin
		fetchbufC_instr <= insn0;
		fetchbufC_v <= ld_fetchbuf;
		fetchbufC_pc <= pc;
		fetchbufD_instr <= insn1;
		fetchbufD_v <= ld_fetchbuf;
		fetchbufD_pc <= pc + fnInsnLength(insn);
		if (do_pcinc) pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
		$display("2pc <= %h", pc + fnInsnLength(insn) + fnInsnLength1(insn));
	end
end
	if (ihit) begin
	$display("%h %h hit0=%b hit1=%b#", spc, pc, hit0, hit1);
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
//`include "Thor_enque.v"
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

if (!branchmiss && !stomp_all)  begin	// don't bother doing anything if there's been a branch miss

	case ({fetchbuf0_v, fetchbuf1_v})// && ((fnNumReadPorts(fetchbuf0_instr) + fnNumReadPorts(fetchbuf1_instr) < 3'd5)||!fetchbuf0_v)})

	2'b00: ; // do nothing

	2'b01:
			if (iqentry_v[tail0] == `INV) begin
				iqentry_v    [tail0]    <=   `VAL;
				iqentry_done [tail0]    <=   `INV;
				iqentry_cmt	 [tail0]    <=   `INV;
				iqentry_out  [tail0]    <=   `INV;
				iqentry_res  [tail0]    <=   `ZERO;
				iqentry_insnsz[tail0]   <=  fnInsnLength(fetchbuf1_instr);
				iqentry_op   [tail0]    <=   opcode1;
				iqentry_fn   [tail0]    <=   fnFunc(fetchbuf1_instr);
				iqentry_cond [tail0]    <=   cond1;
				iqentry_bt   [tail0]    <=   fnIsFlowCtrl(opcode1) && predict_taken1; 
				iqentry_agen [tail0]    <=   `INV;
				// If an interrupt is being enqueued and the previous instruction was an immediate prefix, then
				// inherit the address of the previous instruction, so that the prefix will be executed on return
				// from interrupt.
				// If a string operation was in progress then inherit the address of the string operation so that
				// it can be continued.
				iqentry_pc   [tail0]    <=	
					(opcode1==`INT && iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1]==`VAL) ? 
						(string_pc != 64'd0 ? string_pc : iqentry_pc[tail0-3'd1]) : fetchbuf1_pc;
				//iqentry_pc   [tail0]    <=   fetchbuf1_pc;
				iqentry_mem  [tail0]    <=   fetchbuf1_mem;
				iqentry_jmp  [tail0]    <=   fetchbuf1_jmp;
				iqentry_fp   [tail0]    <=   fetchbuf1_fp;
				iqentry_rfw  [tail0]    <=   fetchbuf1_rfw;
				iqentry_tgt  [tail0]    <=   fnTargetReg(fetchbuf1_instr);
				iqentry_pred [tail0]    <=   pregs[Pn1];
				// The predicate is automatically valid for condiitions 0 and 1 (always false or always true).
				iqentry_p_v  [tail0]    <=   rf_v [{1'b1,2'h0,Pn1}] || cond1 < 4'h2;
				iqentry_p_s  [tail0]    <=   rf_source [{1'b1,2'h0,Pn1}];
				// Look at the previous queue slot to see if an immediate prefix is enqueued
				// But don't allow it for a branch
				iqentry_a0[tail0]   <=  	opcode1==`INT ? fnImm(fetchbuf1_instr) :
											fnIsBranch(opcode1) ? {{DBW-12{fetchbuf1_instr[11]}},fetchbuf1_instr[11:8],fetchbuf1_instr[23:16]} :
											iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1] ? {iqentry_a0[tail0-3'd1][DBW-1:8],fnImm8(fetchbuf1_instr)} :
											opcode1==`IMM ? fnImmImm(fetchbuf1_instr) :
											fnImm(fetchbuf1_instr);
				iqentry_a1   [tail0]    <=   //fnIsFlowCtrl(opcode1) ? bregs1 : rfoa1;
												fnOpa(opcode1,fetchbuf1_instr,rfoa1,fetchbuf1_pc);
				iqentry_a1_v [tail0]    <=   fnSource1_v( opcode1 ) | rf_v[ fnRa(fetchbuf1_instr) ];
				iqentry_a1_s [tail0]    <=   rf_source [fnRa(fetchbuf1_instr)];
				iqentry_a2   [tail0]    <=   fnIsShiftiop(fetchbuf1_instr) ? {{DBW-6{1'b0}},fetchbuf1_instr[`INSTRUCTION_RB]} : opcode1==`STI ? fetchbuf1_instr[31:22] : rfob1;
				iqentry_a2_v [tail0]    <=   fnSource2_v( opcode1 ) | rf_v[ Rb1 ];
				iqentry_a2_s [tail0]    <=   rf_source[Rb1];
				iqentry_a3   [tail0]    <=   rfoc1;
				iqentry_a3_v [tail0]    <=   fnSource3_v( opcode1 ) | rf_v[ Rc1 ];
				iqentry_a3_s [tail0]    <=   rf_source[Rc1];
				tail0 <= tail0 + 1;
				tail1 <= tail1 + 1;
				if (fetchbuf1_rfw|fetchbuf1_pfw) begin
					rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail0 };	// top bit indicates ALU/MEM bus
				end
				rrmapno <= rrmapno + 3'd1;
			end

	2'b10:
			if (iqentry_v[tail0] == `INV) begin

				iqentry_v    [tail0]    <=   `VAL;
				iqentry_done [tail0]    <=   `INV;
				iqentry_cmt	 [tail0]    <=   `INV;
				iqentry_out  [tail0]    <=   `INV;
				iqentry_res  [tail0]    <=   `ZERO;
				iqentry_insnsz[tail0]   <=  fnInsnLength(fetchbuf0_instr);
				iqentry_op   [tail0]    <=   opcode0; 
				iqentry_fn   [tail0]    <=   fnFunc(fetchbuf0_instr);
				iqentry_cond [tail0]    <=   cond0;
				iqentry_bt   [tail0]    <=   fnIsFlowCtrl(opcode0) && predict_taken0; 
				iqentry_agen [tail0]    <=   `INV;
				iqentry_pc   [tail0]    <=   
					(opcode0==`INT && iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1]==`VAL) ? 
						(string_pc != 64'd0 ? string_pc : iqentry_pc[tail0-3'd1]) : fetchbuf0_pc;
				iqentry_mem  [tail0]    <=   fetchbuf0_mem;
				iqentry_jmp  [tail0]    <=   fetchbuf0_jmp;
				iqentry_fp   [tail0]    <=   fetchbuf0_fp;
				iqentry_rfw  [tail0]    <=   fetchbuf0_rfw;
				iqentry_tgt  [tail0]    <=   fnTargetReg(fetchbuf0_instr);
				iqentry_pred [tail0]    <=   pregs[Pn0];
				iqentry_p_v  [tail0]    <=   rf_v [{1'b1,2'h0,Pn0}] || cond0 < 4'h2;
				iqentry_p_s  [tail0]    <=   rf_source [{1'b1,2'h0,Pn0}];
				// Look at the previous queue slot to see if an immediate prefix is enqueued
				iqentry_a0[tail0]   <=  	opcode0==`INT ? fnImm(fetchbuf0_instr) :
											fnIsBranch(opcode0) ? {{DBW-12{fetchbuf0_instr[11]}},fetchbuf0_instr[11:8],fetchbuf0_instr[23:16]} : 
											iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1] ? iqentry_a0[tail0-3'd1] | fnImm8(fetchbuf0_instr):
											opcode0==`IMM ? fnImmImm(fetchbuf0_instr) :
											fnImm(fetchbuf0_instr);
				iqentry_a1   [tail0]    <=   //fnIsFlowCtrl(opcode0) ? bregs0 : rfoa0;
												fnOpa(opcode0,fetchbuf0_instr,rfoa0,fetchbuf0_pc);
				iqentry_a1_v [tail0]    <=   fnSource1_v( opcode0 ) | rf_v[ fnRa(fetchbuf0_instr) ];
				iqentry_a1_s [tail0]    <=   rf_source [fnRa(fetchbuf0_instr)];
				iqentry_a2   [tail0]    <=   fnIsShiftiop(fetchbuf0_instr) ? {58'b0,fetchbuf0_instr[`INSTRUCTION_RB]} : opcode0==`STI ? fetchbuf0_instr[31:22] : rfob0;
				iqentry_a2_v [tail0]    <=   fnSource2_v( opcode0) | rf_v[Rb0];
				iqentry_a2_s [tail0]    <=   rf_source [Rb0];
				iqentry_a3   [tail0]    <=   rfoc0;
				iqentry_a3_v [tail0]    <=   fnSource3_v( opcode1 ) | rf_v[ Rc0 ];
				iqentry_a3_s [tail0]    <=   rf_source[Rc0];
				tail0 <= tail0 + 1;
				tail1 <= tail1 + 1;
				if (fetchbuf0_rfw|fetchbuf0_pfw) begin
					rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };	// top bit indicates ALU/MEM bus
				end
				rrmapno <= rrmapno + 3'd1;
			end
	
		2'b11: if (iqentry_v[tail0] == `INV) begin
					rrmapno <= rrmapno + 3'd1;

		//
		// if the first instruction is a backwards branch, enqueue it & stomp on all following instructions
		//
		if ({fnIsBranch(opcode0), predict_taken0} == {`TRUE, `TRUE}) begin
			iqentry_v    [tail0]    <=	`VAL;
			iqentry_done [tail0]    <=	`INV;
			iqentry_cmt	 [tail0]    <=  `INV;
			iqentry_out  [tail0]    <=	`INV;
			iqentry_res  [tail0]    <=	`ZERO;
			iqentry_insnsz[tail0]   <=  fnInsnLength(fetchbuf0_instr);
			iqentry_op   [tail0]    <=	opcode0; 			// BEQ
			iqentry_fn   [tail0]    <=   fnFunc(fetchbuf0_instr);
			iqentry_cond [tail0]    <=   cond0;
			iqentry_bt   [tail0]    <=	`VAL;
			iqentry_agen [tail0]    <=	`INV;
			iqentry_pc   [tail0]    <=	
					(opcode0==`INT && iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1]==`VAL) ? 
						(string_pc != 64'd0 ? string_pc : iqentry_pc[tail0-3'd1]) : fetchbuf0_pc;
			iqentry_mem  [tail0]    <=	fetchbuf0_mem;
			iqentry_jmp  [tail0]    <=	fetchbuf0_jmp;
			iqentry_fp   [tail0]    <=  fetchbuf0_fp;
			iqentry_rfw  [tail0]    <=	fetchbuf0_rfw;
			iqentry_tgt  [tail0]    <=	fnTargetReg(fetchbuf0_instr);
			iqentry_pred [tail0]    <=   pregs[Pn0];
			iqentry_p_v  [tail0]    <=   rf_v [{1'b1,2'h0,Pn0}] || cond0 < 4'h2;
			iqentry_p_s  [tail0]    <=   rf_source [{1'b1,2'h0,Pn0}];
			// Look at the previous queue slot to see if an immediate prefix is enqueued
			iqentry_a0[tail0]   	<=  opcode0==`INT ? fnImm(fetchbuf0_instr) :
										fnIsBranch(opcode0) ? {{DBW-12{fetchbuf0_instr[11]}},fetchbuf0_instr[11:8],fetchbuf0_instr[23:16]} : 
											iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1] ? iqentry_a0[tail0-3'd1] | fnImm8(fetchbuf0_instr):
											opcode0==`IMM ? fnImmImm(fetchbuf0_instr) :
										fnImm(fetchbuf0_instr);
			iqentry_a1   [tail0]    <=	//fnIsFlowCtrl(opcode0) ? bregs0 : rfoa0;
												fnOpa(opcode0,fetchbuf0_instr,rfoa0,fetchbuf0_pc);
			iqentry_a1_v [tail0]    <=	fnSource1_v( opcode0 ) | rf_v[ fnRa(fetchbuf0_instr) ];
			iqentry_a1_s [tail0]    <=	rf_source [fnRa(fetchbuf0_instr)];
			iqentry_a2   [tail0]    <=	fnIsShiftiop(fetchbuf0_instr) ? {58'b0,fetchbuf0_instr[`INSTRUCTION_RB]} : opcode0==`STI ? fetchbuf0_instr[31:22] : rfob0;
			iqentry_a2_v [tail0]    <=	fnSource2_v( opcode0 ) | rf_v[ Rb0 ];
			iqentry_a2_s [tail0]    <=	rf_source[ Rb0 ];
			iqentry_a3   [tail0]    <=   rfoc0;
			iqentry_a3_v [tail0]    <=   fnSource3_v( opcode1 ) | rf_v[ Rc0 ];
			iqentry_a3_s [tail0]    <=   rf_source[Rc0];
			tail0 <= tail0 + 1;
			tail1 <= tail1 + 1;

		end

		else begin	// fetchbuf0 doesn't contain a backwards branch
			//
			// so -- we can enqueue 1 or 2 instructions, depending on space in the IQ
			// update tail0/tail1 separately (at top)
			// update the rf_v and rf_source bits separately (at end)
			//   the problem is that if we do have two instructions, 
			//   they may interact with each other, so we have to be
			//   careful about where things point.
			//

			if (iqentry_v[tail1] == `INV) begin
				tail0 <= tail0 + 2;
				tail1 <= tail1 + 2;
			end
			else begin
				tail0 <= tail0 + 1;
				tail1 <= tail1 + 1;
			end
			//
			// enqueue the first instruction ...
			//
			iqentry_v    [tail0]    <=   `VAL;
			iqentry_done [tail0]    <=   `INV;
			iqentry_cmt  [tail0]    <=   `INV;
			iqentry_out  [tail0]    <=   `INV;
			iqentry_res  [tail0]    <=   `ZERO;
			iqentry_insnsz[tail0]   <=  fnInsnLength(fetchbuf0_instr);
			iqentry_op   [tail0]    <=  opcode0;
			iqentry_fn   [tail0]    <=   fnFunc(fetchbuf0_instr);
			iqentry_cond [tail0]    <=   cond0;
			iqentry_bt   [tail0]    <=   `INV;
			iqentry_agen [tail0]    <=   `INV;
			iqentry_pc   [tail0]    <=
					(opcode0==`INT && iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1]==`VAL) ? 
						(string_pc != 64'd0 ? string_pc : iqentry_pc[tail0-3'd1]) : fetchbuf0_pc;
			iqentry_mem  [tail0]    <=   fetchbuf0_mem;
			iqentry_jmp  [tail0]    <=   fetchbuf0_jmp;
			iqentry_fp   [tail0]    <=   fetchbuf0_fp;
			iqentry_rfw  [tail0]    <=   fetchbuf0_rfw;
			iqentry_tgt  [tail0]    <=   fnTargetReg(fetchbuf0_instr);
			iqentry_pred [tail0]    <=   pregs[Pn0];
			iqentry_p_v  [tail0]    <=   rf_v [{1'b1,2'h0,Pn0}] || cond0 < 4'h2;
			iqentry_p_s  [tail0]    <=   rf_source [{1'b1,2'h0,Pn0}];
			// Look at the previous queue slot to see if an immediate prefix is enqueued
			iqentry_a0[tail0]   	<=  opcode0==`INT ? fnImm(fetchbuf0_instr) :
										fnIsBranch(opcode0) ? {{DBW-12{fetchbuf0_instr[11]}},fetchbuf0_instr[11:8],fetchbuf0_instr[23:16]} : 
											iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1] ? {iqentry_a0[tail0-3'd1][DBW-1:8],fnImm8(fetchbuf0_instr)}:
											opcode0==`IMM ? fnImmImm(fetchbuf0_instr) :
										fnImm(fetchbuf0_instr);
			iqentry_a1   [tail0]    <=   //fnIsFlowCtrl(opcode0) ? bregs0 : rfoa0;
												fnOpa(opcode0,fetchbuf0_instr,rfoa0,fetchbuf0_pc);
										$display("writing %h",fnOpa(opcode0,fetchbuf0_instr,rfoa0,fetchbuf0_pc));
			iqentry_a1_v [tail0]    <=   fnSource1_v( opcode0 ) | rf_v[ fnRa(fetchbuf0_instr) ];
							
			iqentry_a1_s [tail0]    <=   rf_source [fnRa(fetchbuf0_instr)];
			iqentry_a2   [tail0]    <=   fnIsShiftiop(fetchbuf0_instr) ? {58'b0,fetchbuf0_instr[`INSTRUCTION_RB]} : opcode0==`STI ? fetchbuf0_instr[31:22] : rfob0;
			iqentry_a2_v [tail0]    <=   fnSource2_v( opcode0 ) | rf_v[ Rb0 ];
			iqentry_a2_s [tail0]    <=   rf_source[Rb0];
			iqentry_a3   [tail0]    <=   rfoc0;
			iqentry_a3_v [tail0]    <=   fnSource3_v( opcode1 ) | rf_v[ Rc0 ];
			iqentry_a3_s [tail0]    <=   rf_source[Rc0];
			//
			// if there is room for a second instruction, enqueue it
			//
			if (iqentry_v[tail1] == `INV) begin
			iqentry_v    [tail1]    <=   `VAL;
			iqentry_done [tail1]    <=   `INV;
			iqentry_cmt  [tail1]    <=   `INV;
			iqentry_out  [tail1]    <=   `INV;
			iqentry_res  [tail1]    <=   `ZERO;
			iqentry_insnsz[tail1]   <=  fnInsnLength(fetchbuf1_instr);
			iqentry_op   [tail1]    <=   opcode1; 
			iqentry_fn   [tail1]    <=   fnFunc(fetchbuf1_instr);
			iqentry_cond [tail1]    <=   cond1;
			iqentry_bt   [tail1]    <=   fnIsFlowCtrl(opcode1) && predict_taken1; 
			iqentry_agen [tail1]    <=   `INV;
			iqentry_pc   [tail1]    <=   (opcode1==`INT && opcode0==`IMM) ? (string_pc != 64'd0 ? string_pc : fetchbuf0_pc) : fetchbuf1_pc;
			iqentry_mem  [tail1]    <=   fetchbuf1_mem;
			iqentry_jmp  [tail1]    <=   fetchbuf1_jmp;
			iqentry_fp   [tail1]    <=   fetchbuf1_fp;
			iqentry_rfw  [tail1]    <=   fetchbuf1_rfw;
			iqentry_tgt  [tail1]    <=   fnTargetReg(fetchbuf1_instr);
			iqentry_pred [tail1]    <=   pregs[Pn1];
			// Look at the previous queue slot to see if an immediate prefix is enqueued
			iqentry_a0[tail1]   <=  	opcode1==`INT ? fnImm(fetchbuf1_instr) :
										fnIsBranch(opcode1) ? {{DBW-12{fetchbuf1_instr[11]}},fetchbuf1_instr[11:8],fetchbuf1_instr[23:16]} : 
											opcode1==`IMM ? fnImmImm(fetchbuf1_instr) :
											opcode0==`IMM ? fnImmImm(fetchbuf0_instr) | fnImm8(fetchbuf1_instr) :
										fnImm(fetchbuf1_instr);
			iqentry_a1   [tail1]    <=   //fnIsFlowCtrl(opcode1) ? bregs1 : rfoa1;
												fnOpa(opcode1,fetchbuf1_instr,rfoa1,fetchbuf1_pc);
												$display("this1 %h", fnOpa(opcode1,fetchbuf1_instr,rfoa1,fetchbuf1_pc) );
			iqentry_a2   [tail1]    <=   fnIsShiftiop(fetchbuf1_instr) ? {58'b0,fetchbuf1_instr[`INSTRUCTION_RB]} : opcode1==`STI ? fetchbuf1_instr[31:22] : rfob1;
			iqentry_a3   [tail1]    <=   rfoc1;
			// a1/a2_v and a1/a2_s values require a bit of thinking ...

			//
			// SOURCE 1 ... this is relatively straightforward, because all instructions
			// that have a source (i.e. every instruction but LUI) read from RB
			//
			// if the argument is an immediate or not needed, we're done
			if (fnSource1_v( opcode1 ) == `VAL) begin
				iqentry_a1_v [tail1] <= `VAL;
//					iqentry_a1_s [tail1] <= 4'd0;
			end
			// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
			else if (~fetchbuf0_rfw) begin
				begin
					iqentry_a1_v [tail1]    <=   rf_v [fnRa(fetchbuf1_instr)];
					iqentry_a1_s [tail1]    <=   rf_source [fnRa(fetchbuf1_instr)];
				end
			end
			// otherwise, previous instruction does write to RF ... see if overlap
			else if (fnTargetReg(fetchbuf0_instr) != 9'd0
				&& fnRa(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
				// if the previous instruction is a LW, then grab result from memq, not the iq
				iqentry_a1_v [tail1]    <=   `INV;
				iqentry_a1_s [tail1]    <=   { fetchbuf0_mem, tail0 };
			end
			// if no overlap, get info from rf_v and rf_source
			else begin
				begin
					iqentry_a1_v [tail1]    <=   rf_v [fnRa(fetchbuf1_instr)];
					iqentry_a1_s [tail1]    <=   rf_source [fnRa(fetchbuf1_instr)];
				end
			end

			if (~fetchbuf0_pfw) begin
				iqentry_p_v  [tail1]    <=   rf_v [{1'b1,2'h0,Pn1}] || cond1 < 4'h2;
				iqentry_p_s  [tail1]    <=   rf_source [{1'b1,2'h0,Pn1}];
			end
			else if (fnTargetReg(fetchbuf0_instr) != 9'd0 && fetchbuf1_instr[7:4]==fnTargetReg(fetchbuf0_instr) & 4'hF) begin
				iqentry_p_v [tail1] <= cond1 < 4'h2;
				iqentry_p_s [tail1] <= { fetchbuf0_mem, tail0 };
			end
			else begin
				iqentry_p_v [tail1] <= rf_v[{1'b1,2'h0,Pn1}] || cond1 < 4'h2;
				iqentry_p_s [tail1] <= rf_source[{1'b1,2'h0,Pn1}];
			end

			//
			// SOURCE 2 ... this is more contorted than the logic for SOURCE 1 because
			// some instructions (NAND and ADD) read from RC and others (SW, BEQ) read from RA
			//
			// if the argument is an immediate or not needed, we're done
			if (fnSource2_v( opcode1 ) == `VAL) begin
				iqentry_a2_v [tail1] <= `VAL;
//					iqentry_a2_s [tail1] <= 4'd0;
			end
			// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
			else if (~fetchbuf0_rfw) begin
				iqentry_a2_v [tail1] <= rf_v[ Rb1 ];
				iqentry_a2_s [tail1] <= rf_source[Rb1];
			end
			// otherwise, previous instruction does write to RF ... see if overlap
			else if (fnTargetReg(fetchbuf0_instr) != 9'd0 &&
				Rb1 == fnTargetReg(fetchbuf0_instr)) begin
				// if the previous instruction is a LW, then grab result from memq, not the iq
				iqentry_a2_v [tail1]    <=   `INV;
				iqentry_a2_s [tail1]    <=   { fetchbuf0_mem, tail0 };
			end
			// if no overlap, get info from rf_v and rf_source
			else begin
				iqentry_a2_v [tail1] <= rf_v[ Rb1 ];
				iqentry_a2_s [tail1] <= rf_source[Rb1];
			end

			//
			// SOURCE 3 ... this is relatively straightforward, because all instructions
			// that have a source (i.e. every instruction but LUI) read from RC
			//
			// if the argument is an immediate or not needed, we're done
			if (fnSource3_v( opcode1 ) == `VAL) begin
				iqentry_a3_v [tail1] <= `VAL;
//					iqentry_a1_s [tail1] <= 4'd0;
			end
			// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
			else if (~fetchbuf0_rfw) begin
				begin
					iqentry_a3_v [tail1]    <=   rf_v [Rc1];
					iqentry_a3_s [tail1]    <=   rf_source [Rc1];
				end
			end
			// otherwise, previous instruction does write to RF ... see if overlap
			else if (fnTargetReg(fetchbuf0_instr) != 9'd0
				&& Rc1 == fnTargetReg(fetchbuf0_instr)) begin
				// if the previous instruction is a LW, then grab result from memq, not the iq
				iqentry_a3_v [tail1]    <=   `INV;
				iqentry_a3_s [tail1]    <=   { fetchbuf0_mem, tail0 };
			end
			// if no overlap, get info from rf_v and rf_source
			else begin
				begin
					iqentry_a3_v [tail1]    <=   rf_v [Rc1];
					iqentry_a3_s [tail1]    <=   rf_source [Rc1];
				end
			end
			//
			// if the two instructions enqueued target the same register, 
			// make sure only the second writes to rf_v and rf_source.
			// first is allowed to update rf_v and rf_source only if the
			// second has no target (BEQ or SW)
			//
			if (fnTargetReg(fetchbuf0_instr) == fnTargetReg(fetchbuf1_instr)) begin
				if (fetchbuf1_rfw) begin
					rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
				end
				else if (fetchbuf0_rfw) begin
					rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
				end
			end
			else begin
				if (fetchbuf0_rfw) begin
					rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
				end
				if (fetchbuf1_rfw) begin
					rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
				end
			end

			end	// ends the "if IQ[tail1] is available" clause
			else begin	// only first instruction was enqueued
				if (fetchbuf0_rfw) begin
					rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf0_instr) ] <= {fetchbuf0_mem, tail0};
				end
			end

		end	// ends the "else fetchbuf0 doesn't have a backwards branch" clause
		end
	endcase
	end
	else begin	// if branchmiss
		if ((iqentry_stomp[0] & ~iqentry_stomp[7]) || stomp_all) begin
			tail0 <= 0;
			tail1 <= 1;
		end
		else if (iqentry_stomp[1] & ~iqentry_stomp[0]) begin
			tail0 <= 1;
			tail1 <= 2;
		end
		else if (iqentry_stomp[2] & ~iqentry_stomp[1]) begin
			tail0 <= 2;
			tail1 <= 3;
		end
		else if (iqentry_stomp[3] & ~iqentry_stomp[2]) begin
			tail0 <= 3;
			tail1 <= 4;
		end
		else if (iqentry_stomp[4] & ~iqentry_stomp[3]) begin
			tail0 <= 4;
			tail1 <= 5;
		end
		else if (iqentry_stomp[5] & ~iqentry_stomp[4]) begin
			tail0 <= 5;
			tail1 <= 6;
		end
		else if (iqentry_stomp[6] & ~iqentry_stomp[5]) begin
			tail0 <= 6;
			tail1 <= 7;
		end
		else if (iqentry_stomp[7] & ~iqentry_stomp[6]) begin
			tail0 <= 7;
			tail1 <= 0;
		end
		// otherwise, it is the last instruction in the queue that has been mispredicted ... do nothing
	end

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
//`include "Thor_dataincoming.v"
// DATAINCOMING
//
// wait for operand/s to appear on alu busses and puts them into 
// the iqentry_a1 and iqentry_a2 slots (if appropriate)
// as well as the appropriate iqentry_res slots (and setting valid bits)
//
//
// put results into the appropriate instruction entries
//
if (alu0_v) begin
	$display("0results to iq[%d]=%h", alu0_id[2:0],alu0_bus);
	if (|alu0_exc) begin
		iqentry_op [alu0_id[2:0] ] <= `INT;
		iqentry_cond [alu0_id[2:0]] <= 4'd1;		// always execute
		iqentry_mem[alu0_id[2:0]] <= `FALSE;
		iqentry_rfw[alu0_id[2:0]] <= `TRUE;			// writes to IPC
		iqentry_a0 [alu0_id[2:0]] <= alu0_exc;
		iqentry_a1 [alu0_id[2:0]] <= cregs[4'hC];	// *** assumes BR12 is static
		iqentry_a1_v [alu0_id[2:0]] <= `TRUE;		// Flag arguments as valid
		iqentry_a2_v [alu0_id[2:0]] <= `TRUE;
		iqentry_a3_v [alu0_id[2:0]] <= `TRUE;
		iqentry_out [alu0_id[2:0]] <= `FALSE;
		iqentry_agen [alu0_id[2:0]] <= `FALSE;
		iqentry_tgt[alu0_id[2:0]] <= {1'b1,2'h1,4'hE};	// Target IPC
	end
	else begin
		if ((alu0_op==`RR && (alu0_fn==`MUL || alu0_fn==`MULU)) || alu0_op==`MULI || alu0_op==`MULUI) begin
			if (alu0_mult_done) begin
				iqentry_res	[ alu0_id[2:0] ] <= alu0_prod[63:0];
				iqentry_done[alu0_id[2:0]] <= `TRUE;
				iqentry_out	[ alu0_id[2:0] ] <= `FALSE;
			end
		end
		else if ((alu0_op==`RR && (alu0_fn==`DIV || alu0_fn==`DIVU)) || alu0_op==`DIVI || alu0_op==`DIVUI) begin
			if (alu0_div_done) begin
				iqentry_res	[ alu0_id[2:0] ] <= alu0_divq;
				iqentry_done[alu0_id[2:0]] <= `TRUE;
				iqentry_out	[ alu0_id[2:0] ] <= `FALSE;
			end
		end
		else begin
			iqentry_res	[ alu0_id[2:0] ] <= alu0_bus;
			iqentry_done[ alu0_id[2:0] ] <= !fnIsMem(iqentry_op[ alu0_id[2:0] ]) || !alu0_cmt;
			iqentry_out	[ alu0_id[2:0] ] <= `FALSE;
		end
		iqentry_cmt [ alu0_id[2:0] ] <= alu0_cmt;
		iqentry_agen[ alu0_id[2:0] ] <= `TRUE;
	end
end

if (alu1_v) begin
	$display("1results to iq[%d]=%h", alu1_id[2:0],alu1_bus);
	if (|alu1_exc) begin
		iqentry_op [alu1_id[2:0] ] <= `INT;
		iqentry_cond [alu1_id[2:0]] <= 4'd1;		// always execute
		iqentry_mem[alu1_id[2:0]] <= `FALSE;
		iqentry_rfw[alu1_id[2:0]] <= `TRUE;			// writes to IPC
		iqentry_a0 [alu1_id[2:0]] <= alu1_exc;
		iqentry_a1 [alu1_id[2:0]] <= cregs[4'hC];	// *** assumes BR12 is static
		iqentry_a1_v [alu1_id[2:0]] <= `TRUE;		// Flag arguments as valid
		iqentry_a2_v [alu1_id[2:0]] <= `TRUE;
		iqentry_a3_v [alu1_id[2:0]] <= `TRUE;
		iqentry_out [alu1_id[2:0]] <= `FALSE;
		iqentry_agen [alu1_id[2:0]] <= `FALSE;
		iqentry_tgt[alu1_id[2:0]] <= {1'b1,2'h1,4'hE};	// Target IPC
	end
	else begin
		if ((alu1_op==`RR && (alu1_fn==`MUL || alu1_fn==`MULU)) || alu1_op==`MULI || alu1_op==`MULUI) begin
			if (alu1_mult_done) begin
				iqentry_res	[ alu1_id[2:0] ] <= alu1_prod[63:0];
				iqentry_done[alu1_id[2:0]] <= `TRUE;
				iqentry_out	[ alu1_id[2:0] ] <= `FALSE;
			end
		end
		else if ((alu1_op==`RR && (alu1_fn==`DIV || alu1_fn==`DIVU)) || alu1_op==`DIVI || alu1_op==`DIVUI) begin
			if (alu1_div_done) begin
				iqentry_res	[ alu1_id[2:0] ] <= alu1_divq;
				iqentry_done[alu1_id[2:0]] <= `TRUE;
				iqentry_out	[ alu1_id[2:0] ] <= `FALSE;
			end
		end
		else begin
			iqentry_res	[ alu1_id[2:0] ] <= alu1_bus;
			iqentry_done[ alu1_id[2:0] ] <= !fnIsMem(iqentry_op[ alu1_id[2:0] ]) || !alu1_cmt;
			iqentry_out	[ alu1_id[2:0] ] <= `FALSE;
		end
		iqentry_cmt [ alu1_id[2:0] ] <= alu1_cmt;
		iqentry_agen[ alu1_id[2:0] ] <= `TRUE;
	end
end

`ifdef FLOATING_POINT
if (fp0_v) begin
	$display("0results to iq[%d]=%h", alu0_id[2:0],alu0_bus);
	if (|fp0_exc) begin
		iqentry_op [alu0_id[2:0] ] <= `INT;
		iqentry_cond [alu0_id[2:0]] <= 4'd1;		// always execute
		iqentry_mem[alu0_id[2:0]] <= `FALSE;
		iqentry_rfw[alu0_id[2:0]] <= `TRUE;			// writes to IPC
		iqentry_a0 [alu0_id[2:0]] <= fp0_exc;
		iqentry_a1 [alu0_id[2:0]] <= bregs[4'hC];	// *** assumes BR12 is static
		iqentry_a1_v [alu0_id[2:0]] <= `TRUE;		// Flag arguments as valid
		iqentry_a2_v [alu0_id[2:0]] <= `TRUE;
		iqentry_a3_v [alu0_id[2:0]] <= `TRUE;
		iqentry_out [alu0_id[2:0]] <= `FALSE;
		iqentry_agen [alu0_id[2:0]] <= `FALSE;
		iqentry_tgt[alu0_id[2:0]] <= {1'b1,2'h1,4'hE};	// Target IPC
	end
	else begin
		iqentry_res	[ alu0_id[2:0] ] <= fp0_bus;
		iqentry_done[ alu0_id[2:0] ] <= fp0_done || !fp0_cmt;
		iqentry_out	[ alu0_id[2:0] ] <= `FALSE;
		iqentry_cmt [ alu0_id[2:0] ] <= fp0_cmt;
		iqentry_agen[ alu0_id[2:0] ] <= `TRUE;
	end
end
`endif

if (dram_v && iqentry_v[ dram_id[2:0] ] && iqentry_mem[ dram_id[2:0] ] ) begin	// if data for stomped instruction, ignore
	$display("2results to iq[%d]=%h", dram_id[2:0],dram_bus);
	iqentry_res	[ dram_id[2:0] ] <= dram_bus;
	// If an exception occurred, stuff an interrupt instruction into the queue
	// slot. The instruction will re-issue as an ALU operation.
	if (|dram_exc) begin
		iqentry_op [dram_id[2:0] ] <= `INT;
		iqentry_cond [dram_id[2:0]] <= 4'd1;		// always execute
		iqentry_mem[dram_id[2:0]] <= `FALSE;		// It's no longer a memory op
		iqentry_rfw[dram_id[2:0]] <= `TRUE;			// writes to IPC
		iqentry_a0 [dram_id[2:0]] <= dram_exc==`EXC_DBE ? 8'hFB : 8'hF8;
		iqentry_a1 [dram_id[2:0]] <= cregs[4'hC];	// *** assumes BR12 is static
		iqentry_a1_v [dram_id[2:0]] <= `TRUE;		// Flag arguments as valid
		iqentry_a2_v [dram_id[2:0]] <= `TRUE;
		iqentry_a3_v [dram_id[2:0]] <= `TRUE;
		iqentry_out [dram_id[2:0]] <= `FALSE;
		iqentry_agen [dram_id[2:0]] <= `FALSE;
		iqentry_tgt[dram_id[2:0]] <= {1'b1,2'h1,4'hE};	// Target IPC
	end
	else begin
		iqentry_done[ dram_id[2:0] ] <= `TRUE;
		if (iqentry_op[dram_id[2:0]]==`STS && lc==64'd0) begin
			string_pc <= 64'd0;
		end
	end
end

// What if there's a databus error during the store ?
// set the IQ entry == DONE as soon as the SW is let loose to the memory system
//
if (dram0 == 2'd1 && fnIsStore(dram0_op) && dram0_op != `STS) begin
	if ((alu0_v && dram0_id[2:0] == alu0_id[2:0]) || (alu1_v && dram0_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram0_id[2:0] ] <= `TRUE;
	iqentry_cmt [ dram0_id[2:0]] <= `TRUE;
	iqentry_out[ dram0_id[2:0] ] <= `FALSE;
end
if (dram1 == 2'd1 && fnIsStore(dram1_op) && dram1_op != `STS) begin
	if ((alu0_v && dram1_id[2:0] == alu0_id[2:0]) || (alu1_v && dram1_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram1_id[2:0] ] <= `TRUE;
	iqentry_cmt [ dram1_id[2:0]] <= `TRUE;
	iqentry_out[ dram1_id[2:0] ] <= `FALSE;
end
if (dram2 == 2'd1 && fnIsStore(dram2_op) && dram2_op != `STS) begin
	if ((alu0_v && dram2_id[2:0] == alu0_id[2:0]) || (alu1_v && dram2_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram2_id[2:0] ] <= `TRUE;
	iqentry_cmt [ dram2_id[2:0]] <= `TRUE;
	iqentry_out[ dram2_id[2:0] ] <= `FALSE;
end

//
// see if anybody else wants the results ... look at lots of buses:
//  - alu0_bus
//  - alu1_bus
//  - fp0_bus
//  - dram_bus
//  - commit0_bus
//  - commit1_bus
//

for (n = 0; n < 8; n = n + 1)
begin
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==alu0_id && iqentry_v[n] == `VAL && alu0_v == `VAL) begin
		iqentry_pred[n] <= alu0_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == alu0_id && iqentry_v[n] == `VAL && alu0_v == `VAL) begin
		iqentry_a1[n] <= alu0_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == alu0_id && iqentry_v[n] == `VAL && alu0_v == `VAL) begin
		iqentry_a2[n] <= alu0_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == alu0_id && iqentry_v[n] == `VAL && alu0_v == `VAL) begin
		iqentry_a3[n] <= alu0_bus;
		iqentry_a3_v[n] <= `VAL;
	end
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==alu1_id && iqentry_v[n] == `VAL && alu1_v == `VAL) begin
		iqentry_pred[n] <= alu1_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == alu1_id && iqentry_v[n] == `VAL && alu1_v == `VAL) begin
		iqentry_a1[n] <= alu1_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == alu1_id && iqentry_v[n] == `VAL && alu1_v == `VAL) begin
		iqentry_a2[n] <= alu1_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == alu1_id && iqentry_v[n] == `VAL && alu1_v == `VAL) begin
		iqentry_a3[n] <= alu1_bus;
		iqentry_a3_v[n] <= `VAL;
	end
`ifdef FLOATING_POINT
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n] == fp0_id && iqentry_v[n] == `VAL && fp0_v == `VAL) begin
		iqentry_pred[n] <= fp0_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == fp0_id && iqentry_v[n] == `VAL && fp0_v == `VAL) begin
		iqentry_a1[n] <= fp0_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == fp0_id && iqentry_v[n] == `VAL && fp0_v == `VAL) begin
		iqentry_a2[n] <= fp0_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == fp0_id && iqentry_v[n] == `VAL && fp0_v == `VAL) begin
		iqentry_a3[n] <= fp0_bus;
		iqentry_a3_v[n] <= `VAL;
	end
`endif
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==dram_id && iqentry_v[n] == `VAL && dram_v == `VAL) begin
		iqentry_pred[n] <= dram_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == dram_id && iqentry_v[n] == `VAL && dram_v == `VAL) begin
		iqentry_a1[n] <= dram_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == dram_id && iqentry_v[n] == `VAL && dram_v == `VAL) begin
		iqentry_a2[n] <= dram_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == dram_id && iqentry_v[n] == `VAL && dram_v == `VAL) begin
		iqentry_a3[n] <= dram_bus;
		iqentry_a3_v[n] <= `VAL;
	end
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==commit0_id && iqentry_v[n] == `VAL && commit0_v == `VAL) begin
		iqentry_pred[n] <= commit0_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == commit0_id && iqentry_v[n] == `VAL && commit0_v == `VAL) begin
		iqentry_a1[n] <= commit0_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == commit0_id && iqentry_v[n] == `VAL && commit0_v == `VAL) begin
		iqentry_a2[n] <= commit0_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == commit0_id && iqentry_v[n] == `VAL && commit0_v == `VAL) begin
		iqentry_a3[n] <= commit0_bus;
		iqentry_a3_v[n] <= `VAL;
	end
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==commit1_id && iqentry_v[n] == `VAL && commit1_v == `VAL) begin
		iqentry_pred[n] <= commit1_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == commit1_id && iqentry_v[n] == `VAL && commit1_v == `VAL) begin
		iqentry_a1[n] <= commit1_bus;
		iqentry_a1_v[n] <= `VAL;
	end
	if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == commit1_id && iqentry_v[n] == `VAL && commit1_v == `VAL) begin
		iqentry_a2[n] <= commit1_bus;
		iqentry_a2_v[n] <= `VAL;
	end
	if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == commit1_id && iqentry_v[n] == `VAL && commit1_v == `VAL) begin
		iqentry_a3[n] <= commit1_bus;
		iqentry_a3_v[n] <= `VAL;
	end
end

//`include "Thor_issue.v"
// ISSUE 
//
// determines what instructions are ready to go, then places them
// in the various ALU queues.  
// also invalidates instructions following a branch-miss BEQ or any JALR (STOMP logic)
//

alu0_dataready <= alu0_available 
			&& ((iqentry_issue[0] && iqentry_islot[0] == 4'd0 && !iqentry_stomp[0])
			 || (iqentry_issue[1] && iqentry_islot[1] == 4'd0 && !iqentry_stomp[1])
			 || (iqentry_issue[2] && iqentry_islot[2] == 4'd0 && !iqentry_stomp[2])
			 || (iqentry_issue[3] && iqentry_islot[3] == 4'd0 && !iqentry_stomp[3])
			 || (iqentry_issue[4] && iqentry_islot[4] == 4'd0 && !iqentry_stomp[4])
			 || (iqentry_issue[5] && iqentry_islot[5] == 4'd0 && !iqentry_stomp[5])
			 || (iqentry_issue[6] && iqentry_islot[6] == 4'd0 && !iqentry_stomp[6])
			 || (iqentry_issue[7] && iqentry_islot[7] == 4'd0 && !iqentry_stomp[7]));

alu1_dataready <= alu1_available 
			&& ((iqentry_issue[0] && iqentry_islot[0] == 4'd1 && !iqentry_stomp[0])
			 || (iqentry_issue[1] && iqentry_islot[1] == 4'd1 && !iqentry_stomp[1])
			 || (iqentry_issue[2] && iqentry_islot[2] == 4'd1 && !iqentry_stomp[2])
			 || (iqentry_issue[3] && iqentry_islot[3] == 4'd1 && !iqentry_stomp[3])
			 || (iqentry_issue[4] && iqentry_islot[4] == 4'd1 && !iqentry_stomp[4])
			 || (iqentry_issue[5] && iqentry_islot[5] == 4'd1 && !iqentry_stomp[5])
			 || (iqentry_issue[6] && iqentry_islot[6] == 4'd1 && !iqentry_stomp[6])
			 || (iqentry_issue[7] && iqentry_islot[7] == 4'd1 && !iqentry_stomp[7]));

`ifdef FLOATING_POINT
fp0_dataready <= 1'b1
			&& ((iqentry_fpissue[0] && iqentry_islot[0] == 4'd0 && !iqentry_stomp[0])
			 || (iqentry_fpissue[1] && iqentry_islot[1] == 4'd0 && !iqentry_stomp[1])
			 || (iqentry_fpissue[2] && iqentry_islot[2] == 4'd0 && !iqentry_stomp[2])
			 || (iqentry_fpissue[3] && iqentry_islot[3] == 4'd0 && !iqentry_stomp[3])
			 || (iqentry_fpissue[4] && iqentry_islot[4] == 4'd0 && !iqentry_stomp[4])
			 || (iqentry_fpissue[5] && iqentry_islot[5] == 4'd0 && !iqentry_stomp[5])
			 || (iqentry_fpissue[6] && iqentry_islot[6] == 4'd0 && !iqentry_stomp[6])
			 || (iqentry_fpissue[7] && iqentry_islot[7] == 4'd0 && !iqentry_stomp[7]));
`endif

for (n = 0; n < 8; n = n + 1)
begin
	if (iqentry_v[n] && iqentry_stomp[n]) begin
		iqentry_v[n] <= `INV;
		if (dram0_id[2:0] == n[2:0])	dram0 <= `DRAMSLOT_AVAIL;
		if (dram1_id[2:0] == n[2:0])	dram1 <= `DRAMSLOT_AVAIL;
		if (dram2_id[2:0] == n[2:0])	dram2 <= `DRAMSLOT_AVAIL;
	end
	else if (iqentry_issue[n]) begin
		case (iqentry_islot[n]) 
		2'd0: if (alu0_available) begin
				$display("n: %d  alu0_cond=%h, v%b alu0_pred=%h", n, iqentry_cond[n], iqentry_p_v[n], iqentry_pred[n]);
			alu0_ld <= 1'b1;
			alu0_sourceid	<= n[3:0];
			alu0_insnsz <= iqentry_insnsz[n];
			alu0_op		<= iqentry_op[n];
			alu0_fn     <= iqentry_fn[n];
			alu0_cond   <= iqentry_cond[n];
			alu0_bt		<= iqentry_bt[n];
			alu0_pc		<= iqentry_pc[n];
			alu0_pred   <= iqentry_p_v[n] ? iqentry_pred[n] :
							(iqentry_p_s[n] == alu0_id) ? alu0_bus[3:0] :
							(iqentry_p_s[n] == alu1_id) ? alu1_bus[3:0] : 4'h0;
			alu0_argA	<= iqentry_a1_v[n] ? iqentry_a1[n]
						: (iqentry_a1_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a1_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			alu0_argB	<= iqentry_a2_v[n] ? iqentry_a2[n]
						: (iqentry_a2_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			alu0_argC	<= iqentry_a3_v[n] ? iqentry_a3[n]
						: (iqentry_a3_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a3_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			alu0_argI	<= iqentry_a0[n];
			end
		2'd1: if (alu1_available) begin
				$display("n%d  alu1_cond=%h, alu1_pred=%h", n, alu1_cond, alu1_pred);
			alu1_ld <= 1'b1;
			alu1_sourceid	<= n[3:0];
			alu1_insnsz <= iqentry_insnsz[n];
			alu1_op		<= iqentry_op[n];
			alu1_fn     <= iqentry_fn[n];
			alu1_cond   <= iqentry_cond[n];
			alu1_bt		<= iqentry_bt[n];
			alu1_pc		<= iqentry_pc[n];
			alu1_pred   <= iqentry_p_v[n] ? iqentry_pred[n] :
							(iqentry_p_s[n] == alu0_id) ? alu0_bus[3:0] :
							(iqentry_p_s[n] == alu1_id) ? alu1_bus[3:0] : 4'h0;
			alu1_argA	<= iqentry_a1_v[n] ? iqentry_a1[n]
						: (iqentry_a1_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a1_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			alu1_argB	<= iqentry_a2_v[n] ? iqentry_a2[n]
						: (iqentry_a2_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			alu1_argC	<= iqentry_a3_v[n] ? iqentry_a3[n]
						: (iqentry_a3_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a3_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			alu1_argI	<= iqentry_a0[n];
			end
		default: panic <= `PANIC_INVALIDISLOT;
		endcase
		iqentry_out[n] <= `TRUE;
		// if it is a memory operation, this is the address-generation step ... collect result into arg1
		if (iqentry_mem[n]) begin
			iqentry_a1_v[n] <= `FALSE;
			iqentry_a1_s[n] <= n[3:0];
		end
	end
end


`ifdef FLOATING_POINT
for (n = 0; n < 8; n = n + 1)
begin
	if (iqentry_v[n] && iqentry_stomp[n])
		;
	else if (iqentry_fpissue[n]) begin
		case (iqentry_fpislot[n]) 
		2'd0: if (1'b1) begin
			fp0_ld <= 1'b1;
			fp0_sourceid	<= n[3:0];
			fp0_op		<= iqentry_op[n];
			fp0_fn     <= iqentry_fn[n];
			fp0_cond   <= iqentry_cond[n];
			fp0_pred   <= iqentry_p_v[n] ? iqentry_pred[n] :
							(iqentry_p_s[n] == alu0_id) ? alu0_bus[3:0] :
							(iqentry_p_s[n] == alu1_id) ? alu1_bus[3:0] : 4'h0;
			fp0_argA	<= iqentry_a1_v[n] ? iqentry_a1[n]
						: (iqentry_a1_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a1_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			fp0_argB	<= iqentry_a2_v[n] ? iqentry_a2[n]
						: (iqentry_a2_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			fp0_argC	<= iqentry_a3_v[n] ? iqentry_a3[n]
						: (iqentry_a3_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a3_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			fp0_argI	<= iqentry_a0[n];
			end
		default: panic <= `PANIC_INVALIDISLOT;
		endcase
		iqentry_out[n] <= `TRUE;
	end
end
`endif

	if (ihit) $display("iss=%b stomp=%b", iqentry_issue, iqentry_stomp);
//`include "Thor_memory.v"
// MEMORY
//
// update the memory queues and put data out on bus if appropriate
// Always puts data on the bus even for stores. In the case of
// stores, the data is ignored.
//
//
// dram0, dram1, dram2 are the "state machines" that keep track
// of three pipelined DRAM requests.  if any has the value "00", 
// then it can accept a request (which bumps it up to the value "01"
// at the end of the cycle).  once it hits the value "10" the request
// and the bus is acknowledged the dram request
// is finished and the dram_bus takes the value.  if it is a store, the 
// dram_bus value is not used, but the dram_v value along with the
// dram_id value signals the waiting memq entry that the store is
// completed and the instruction can commit.
//
if (tlb_state != 3'd0 && tlb_state < 3'd3)
	tlb_state <= tlb_state + 3'd1;
if (tlb_state==3'd3) begin
	dram_v <= `TRUE;
	dram_id <= tlb_id;
	dram_tgt <= tlb_tgt;
	dram_exc <= `EXC_NONE;
	dram_bus <= tlb_dato;
	tlb_op <= 4'h0;
	tlb_state <= 3'd0;
end

case(dram0)
// The first state is to translate the virtual to physical address.
3'd1:
	begin
		$display("0MEM %c:%h %h cycle started",fnIsLoad(dram0_op)?"L" : "S", dram0_addr, dram0_data);
        dram0 <= dram0 + 3'd1;
	end

// State 2:
// Check for a TLB miss on the translated address, and
// Initiate a bus transfer
3'd2:
	if (DTLBMiss) begin
		dram_v <= `TRUE;			// we are finished the memory cycle
		dram_id <= dram0_id;
		dram_tgt <= dram0_tgt;
		dram_exc <= `EXC_TLBMISS;	//dram0_exc;
		dram_bus <= 64'h0;
		dram0 <= 3'd0;
	end
	else if (dram0_exc!=`EXC_NONE) begin
		dram_v <= `TRUE;			// we are finished the memory cycle
        dram_id <= dram0_id;
        dram_tgt <= dram0_tgt;
        dram_exc <= dram0_exc;
		dram_bus <= 64'h0;
        dram0 <= 3'd0;
	end
	else begin
		if (uncached || fnIsStore(dram0_op) || fnIsLoadV(dram0_op) || dram0_op==`CAS) begin
    		if (cstate==IDLE) begin // make sure an instruction load isn't taking place
                dram0_owns_bus <= `TRUE;
                lock_o <= dram0_op==`CAS;
                cyc_o <= 1'b1;
                stb_o <= 1'b1;
                we_o <= fnIsStore(dram0_op);
                sel_o <= fnSelect(dram0_op,dram0_fn,pea);
                adr_o <= pea;
                dat_o <= fnDatao(dram0_op,dram0_data);
                dram0 <= dram0 + 3'd1;
			end
		end
		else	// cached read
			dram0 <= 3'd6;
	end

// State 3:
// Wait for a memory ack
3'd3:
	if (ack_i|err_i) begin
		$display("MEM ack");
		dram_v <= dram0_op != `CAS && dram0_op != `STS;
		dram_id <= dram0_id;
		dram_tgt <= dram0_tgt;
		dram_exc <= err_i ? `EXC_DBE : `EXC_NONE;//dram0_exc;
		dram_bus <= fnDatai(dram0_op,dat_i,sel_o);
		dram0_owns_bus <= `FALSE;
		wb_nack();
		dram0 <= 3'd7;
		case(dram0_op)
		`STS:
			if (lc != 0 && !int_pending) begin
				dram0_addr <= dram0_addr +
				    (dram0_fn[2:0]==3'd0 ? 64'd1 :
				    dram0_fn[2:0]==3'd1 ? 64'd2 :
				    dram0_fn[2:0]==3'd2 ? 64'd4 :
				    64'd8); 
				lc <= lc - 64'd1;
				dram0 <= 3'd2;
				dram_bus <= dram0_addr +
                    (dram0_fn[2:0]==3'd0 ? 64'd1 :
                    dram0_fn[2:0]==3'd1 ? 64'd2 :
                    dram0_fn[2:0]==3'd2 ? 64'd4 :
                    64'd8); 
            end
            else begin
                dram_bus <= dram0_addr;
                dram_v <= `VAL;
            end
		`CAS:
			if (dram0_datacmp == dat_i) begin
				$display("CAS match");
				dram0_owns_bus <= `TRUE;
				cyc_o <= 1'b1;	// hold onto cyc_o
				dram0 <= dram0 + 3'd1;
			end
			else
				dram_v <= `VAL;
		endcase
	end

// State 4:
// Start a second bus transaction for the CAS instruction
3'd4:
	begin
		stb_o <= 1'b1;
		we_o <= 1'b1;
		sel_o <= fnSelect(dram0_op,dram0_fn,pea);
		adr_o <= pea;
		dat_o <= fnDatao(dram0_op,dram0_data);
		dram0 <= dram0 + 3'd1;
	end

// State 5:
// Wait for a memory ack for the second bus transaction of a CAS
//
3'd5:
	if (ack_i|err_i) begin
		$display("MEM ack2");
		dram_v <= `VAL;
		dram_id <= dram0_id;
		dram_tgt <= dram0_tgt;
		dram_exc <= err_i ? `EXC_DBE : `EXC_NONE;
		dram0_owns_bus <= `FALSE;
		wb_nack();
		lock_o <= 1'b0;
		dram0 <= 3'd7;
	end

// State 6:
// Wait for a data cache read hit
3'd6:
	if (rhit) begin
		$display("Read hit");
		dram_v <= `TRUE;
		dram_id <= dram0_id;
		dram_tgt <= dram0_tgt;
		dram_exc <= `EXC_NONE;
		dram_bus <= fnDatai(dram0_op,cdat,sel_o);
		dram0 <= 3'd0;
	end
3'd7:
    dram0 <= 3'd0;
endcase

//
// determine if the instructions ready to issue can, in fact, issue.
// "ready" means that the instruction has valid operands but has not gone yet
//
// Stores can only issue if there is no possibility of a change of program flow.
// That means no flow control operations or instructions that can cause an
// exception can be before the store.
iqentry_memissue[ head0 ] <=	iqentry_memready[ head0 ];		// first in line ... go as soon as ready

iqentry_memissue[ head1 ] <=	~iqentry_stomp[head1] && iqentry_memready[ head1 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head1][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head1]) ? !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) : `TRUE)
				&& (iqentry_op[head1]!=`CAS)
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_op[head0]==`MEMDB) 
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB) 
				;

iqentry_memissue[ head2 ] <=	~iqentry_stomp[head2] && iqentry_memready[ head2 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				&& ~iqentry_memready[head1] 
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head2][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head2][DBW-1:3] != iqentry_a1[head1][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head2]) ?
				    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) && 
				    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1]) 
				    : `TRUE)
				&& (iqentry_op[head2]!=`CAS)
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_op[head0]==`MEMDB)
				&& !(iqentry_v[head1] && fnIsMem(iqentry_op[head1]) && iqentry_op[head1]==`MEMDB)
				// ... and there is no instruction barrier
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB) 
				&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB) 
				;
//					(   !fnIsFlowCtrl(iqentry_op[head0])
//					 && !fnIsFlowCtrl(iqentry_op[head1])));

iqentry_memissue[ head3 ] <=	~iqentry_stomp[head3] && iqentry_memready[ head3 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				&& ~iqentry_memready[head1] 
				&& ~iqentry_memready[head2] 
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head3][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head3][DBW-1:3] != iqentry_a1[head1][DBW-1:3]))
				&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
					|| (iqentry_a1_v[head2] && iqentry_a1[head3][DBW-1:3] != iqentry_a1[head2][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head3]) ?
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2]) 
                    : `TRUE)
				&& (iqentry_op[head3]!=`CAS)
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_op[head0]==`MEMDB)
				&& !(iqentry_v[head1] && fnIsMem(iqentry_op[head1]) && iqentry_op[head1]==`MEMDB)
				&& !(iqentry_v[head2] && fnIsMem(iqentry_op[head2]) && iqentry_op[head2]==`MEMDB)
				// ... and there is no instruction barrier
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB) 
                && !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB) 
                && !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB) 
				;
/*					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])));
*/
iqentry_memissue[ head4 ] <=	~iqentry_stomp[head4] && iqentry_memready[ head4 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				&& ~iqentry_memready[head1] 
				&& ~iqentry_memready[head2] 
				&& ~iqentry_memready[head3] 
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head4][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head4][DBW-1:3] != iqentry_a1[head1][DBW-1:3]))
				&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
					|| (iqentry_a1_v[head2] && iqentry_a1[head4][DBW-1:3] != iqentry_a1[head2][DBW-1:3]))
				&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
					|| (iqentry_a1_v[head3] && iqentry_a1[head4][DBW-1:3] != iqentry_a1[head3][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head4]) ?
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2]) && 
                    !fnIsFlowCtrl(iqentry_op[head3]) && !fnCanException(iqentry_op[head3]) 
                    : `TRUE)
				&& (iqentry_op[head4]!=`CAS)
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_op[head0]==`MEMDB)
				&& !(iqentry_v[head1] && fnIsMem(iqentry_op[head1]) && iqentry_op[head1]==`MEMDB)
				&& !(iqentry_v[head2] && fnIsMem(iqentry_op[head2]) && iqentry_op[head2]==`MEMDB)
				&& !(iqentry_v[head3] && fnIsMem(iqentry_op[head3]) && iqentry_op[head3]==`MEMDB)
				// ... and there is no instruction barrier
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB) 
                && !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB) 
                && !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB) 
                && !(iqentry_v[head3] && iqentry_op[head3]==`MEMSB) 
				;
/* ||
					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])
					 && !fnIsFlowCtrl(iqentry_op[head3])));
*/
iqentry_memissue[ head5 ] <=	~iqentry_stomp[head5] && iqentry_memready[ head5 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				&& ~iqentry_memready[head1] 
				&& ~iqentry_memready[head2] 
				&& ~iqentry_memready[head3] 
				&& ~iqentry_memready[head4] 
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head5][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head5][DBW-1:3] != iqentry_a1[head1][DBW-1:3]))
				&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
					|| (iqentry_a1_v[head2] && iqentry_a1[head5][DBW-1:3] != iqentry_a1[head2][DBW-1:3]))
				&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
					|| (iqentry_a1_v[head3] && iqentry_a1[head5][DBW-1:3] != iqentry_a1[head3][DBW-1:3]))
				&& (!iqentry_mem[head4] || (iqentry_agen[head4] & iqentry_out[head4]) 
					|| (iqentry_a1_v[head4] && iqentry_a1[head5][DBW-1:3] != iqentry_a1[head4][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head5]) ?
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2]) && 
                    !fnIsFlowCtrl(iqentry_op[head3]) && !fnCanException(iqentry_op[head3]) && 
                    !fnIsFlowCtrl(iqentry_op[head4]) && !fnCanException(iqentry_op[head4]) 
                    : `TRUE)
				&& (iqentry_op[head5]!=`CAS)
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_op[head0]==`MEMDB)
				&& !(iqentry_v[head1] && fnIsMem(iqentry_op[head1]) && iqentry_op[head1]==`MEMDB)
				&& !(iqentry_v[head2] && fnIsMem(iqentry_op[head2]) && iqentry_op[head2]==`MEMDB)
				&& !(iqentry_v[head3] && fnIsMem(iqentry_op[head3]) && iqentry_op[head3]==`MEMDB)
				&& !(iqentry_v[head4] && fnIsMem(iqentry_op[head4]) && iqentry_op[head4]==`MEMDB)
				// ... and there is no instruction barrier
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB) 
                && !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB) 
                && !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB) 
                && !(iqentry_v[head3] && iqentry_op[head3]==`MEMSB) 
                && !(iqentry_v[head4] && iqentry_op[head4]==`MEMSB) 
				;
/*||
					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])
					 && !fnIsFlowCtrl(iqentry_op[head3])
					 && !fnIsFlowCtrl(iqentry_op[head4])));
*/
iqentry_memissue[ head6 ] <=	~iqentry_stomp[head6] && iqentry_memready[ head6 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				&& ~iqentry_memready[head1] 
				&& ~iqentry_memready[head2] 
				&& ~iqentry_memready[head3] 
				&& ~iqentry_memready[head4] 
				&& ~iqentry_memready[head5] 
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head6][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head6][DBW-1:3] != iqentry_a1[head1][DBW-1:3]))
				&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
					|| (iqentry_a1_v[head2] && iqentry_a1[head6][DBW-1:3] != iqentry_a1[head2][DBW-1:3]))
				&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
					|| (iqentry_a1_v[head3] && iqentry_a1[head6][DBW-1:3] != iqentry_a1[head3][DBW-1:3]))
				&& (!iqentry_mem[head4] || (iqentry_agen[head4] & iqentry_out[head4]) 
					|| (iqentry_a1_v[head4] && iqentry_a1[head6][DBW-1:3] != iqentry_a1[head4][DBW-1:3]))
				&& (!iqentry_mem[head5] || (iqentry_agen[head5] & iqentry_out[head5]) 
					|| (iqentry_a1_v[head5] && iqentry_a1[head6][DBW-1:3] != iqentry_a1[head5][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head6]) ?
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2]) && 
                    !fnIsFlowCtrl(iqentry_op[head3]) && !fnCanException(iqentry_op[head3]) && 
                    !fnIsFlowCtrl(iqentry_op[head4]) && !fnCanException(iqentry_op[head4]) && 
                    !fnIsFlowCtrl(iqentry_op[head5]) && !fnCanException(iqentry_op[head5]) 
                    : `TRUE)
				&& (iqentry_op[head6]!=`CAS)
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_op[head0]==`MEMDB)
				&& !(iqentry_v[head1] && fnIsMem(iqentry_op[head1]) && iqentry_op[head1]==`MEMDB)
				&& !(iqentry_v[head2] && fnIsMem(iqentry_op[head2]) && iqentry_op[head2]==`MEMDB)
				&& !(iqentry_v[head3] && fnIsMem(iqentry_op[head3]) && iqentry_op[head3]==`MEMDB)
				&& !(iqentry_v[head4] && fnIsMem(iqentry_op[head4]) && iqentry_op[head4]==`MEMDB)
				&& !(iqentry_v[head5] && fnIsMem(iqentry_op[head5]) && iqentry_op[head5]==`MEMDB)
				// ... and there is no instruction barrier
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB) 
                && !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB) 
                && !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB) 
                && !(iqentry_v[head3] && iqentry_op[head3]==`MEMSB) 
                && !(iqentry_v[head4] && iqentry_op[head4]==`MEMSB) 
                && !(iqentry_v[head5] && iqentry_op[head5]==`MEMSB) 
				;
				/*||
					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])
					 && !fnIsFlowCtrl(iqentry_op[head3])
					 && !fnIsFlowCtrl(iqentry_op[head4])
					 && !fnIsFlowCtrl(iqentry_op[head5])));
*/
iqentry_memissue[ head7 ] <=	~iqentry_stomp[head7] && iqentry_memready[ head7 ]		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				&& ~iqentry_memready[head1] 
				&& ~iqentry_memready[head2] 
				&& ~iqentry_memready[head3] 
				&& ~iqentry_memready[head4] 
				&& ~iqentry_memready[head5] 
				&& ~iqentry_memready[head6] 
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
					|| (iqentry_a1_v[head1] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head1][DBW-1:3]))
				&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
					|| (iqentry_a1_v[head2] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head2][DBW-1:3]))
				&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
					|| (iqentry_a1_v[head3] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head3][DBW-1:3]))
				&& (!iqentry_mem[head4] || (iqentry_agen[head4] & iqentry_out[head4]) 
					|| (iqentry_a1_v[head4] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head4][DBW-1:3]))
				&& (!iqentry_mem[head5] || (iqentry_agen[head5] & iqentry_out[head5]) 
					|| (iqentry_a1_v[head5] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head5][DBW-1:3]))
				&& (!iqentry_mem[head6] || (iqentry_agen[head6] & iqentry_out[head6]) 
					|| (iqentry_a1_v[head6] && iqentry_a1[head7][DBW-1:3] != iqentry_a1[head6][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head7]) ?
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2]) && 
                    !fnIsFlowCtrl(iqentry_op[head3]) && !fnCanException(iqentry_op[head3]) && 
                    !fnIsFlowCtrl(iqentry_op[head4]) && !fnCanException(iqentry_op[head4]) && 
                    !fnIsFlowCtrl(iqentry_op[head5]) && !fnCanException(iqentry_op[head5]) && 
                    !fnIsFlowCtrl(iqentry_op[head6]) && !fnCanException(iqentry_op[head6]) 
                    : `TRUE)
				&& (iqentry_op[head7]!=`CAS)
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_op[head0]==`MEMDB)
				&& !(iqentry_v[head1] && fnIsMem(iqentry_op[head1]) && iqentry_op[head1]==`MEMDB)
				&& !(iqentry_v[head2] && fnIsMem(iqentry_op[head2]) && iqentry_op[head2]==`MEMDB)
				&& !(iqentry_v[head3] && fnIsMem(iqentry_op[head3]) && iqentry_op[head3]==`MEMDB)
				&& !(iqentry_v[head4] && fnIsMem(iqentry_op[head4]) && iqentry_op[head4]==`MEMDB)
				&& !(iqentry_v[head5] && fnIsMem(iqentry_op[head5]) && iqentry_op[head5]==`MEMDB)
				&& !(iqentry_v[head6] && fnIsMem(iqentry_op[head6]) && iqentry_op[head6]==`MEMDB)
				// ... and there is no instruction barrier
				&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB) 
                && !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB) 
                && !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB) 
                && !(iqentry_v[head3] && iqentry_op[head3]==`MEMSB) 
                && !(iqentry_v[head4] && iqentry_op[head4]==`MEMSB) 
                && !(iqentry_v[head5] && iqentry_op[head5]==`MEMSB) 
                && !(iqentry_v[head6] && iqentry_op[head6]==`MEMSB) 
				;
				/* ||
					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])
					 && !fnIsFlowCtrl(iqentry_op[head3])
					 && !fnIsFlowCtrl(iqentry_op[head4])
					 && !fnIsFlowCtrl(iqentry_op[head5])
					 && !fnIsFlowCtrl(iqentry_op[head6])));
*/
//
// take requests that are ready and put them into DRAM slots

if (dram0 == `DRAMSLOT_AVAIL)	dram0_exc <= `EXC_NONE;

// Memory should also wait until segment registers are valid. The segment
// registers are essentially static registers while a program runs. They are
// setup by only the operating system. The system software must ensure the
// segment registers are stable before they get used. We don't bother checking
// for rf_v[].
//
for (n = 0; n < 8; n = n + 1)
	if (~iqentry_stomp[n] && iqentry_memissue[n] && iqentry_agen[n] && iqentry_op[n]==`TLB && ~iqentry_out[n] && iqentry_cmt[n]) begin
		if (tlb_state==3'd0) begin
			tlb_state <= 3'd1;
			tlb_id <= {1'b1, n[2:0]};
			tlb_op <= iqentry_a0[n][3:0];
			tlb_regno <= iqentry_a0[n][7:4];
			tlb_tgt <= iqentry_tgt[n];
			tlb_data <= iqentry_a2[n];
			iqentry_out[n] <= `TRUE;
		end
	end
	else if (~iqentry_stomp[n] && iqentry_memissue[n] && iqentry_agen[n] && ~iqentry_out[n] && iqentry_cmt[n] && ihit) begin
		if (fnIsStoreString(iqentry_op[n]))
			string_pc <= iqentry_pc[n];
		$display("issued memory cycle");
		if (dram0 == `DRAMSLOT_AVAIL) begin
			dram0 		<= 3'd1;
			dram0_id 	<= { 1'b1, n[2:0] };
			dram0_op 	<= iqentry_op[n];
			dram0_fn    <= iqentry_fn[n];
			dram0_tgt 	<= iqentry_tgt[n];
			dram0_data	<= (fnIsIndexed(iqentry_op[n]) || iqentry_op[n]==`CAS) ? iqentry_a3[n] : iqentry_a2[n];
			dram0_datacmp <= iqentry_a2[n];
`ifdef SEGMENTATION
			dram0_addr	<= iqentry_a1[n] + {sregs[iqentry_fn[n][5:3]],12'h000};
//			if (iqentry_a1[n] > sregs_lmt[iqentry_fn[n]])
//			    dram0_exc <= `EXC_SEGLMT;
`else
			dram0_addr	<= iqentry_a1[n];
`endif
			iqentry_out[n]	<= `TRUE;
		end
	end
//	$display("TLB: en=%b imatch=%b pgsz=%d pcs=%h phys=%h", utlb1.TLBenabled,utlb1.IMatch,utlb1.PageSize,utlb1.pcs,utlb1.IPFN);
//	for (i = 0; i < 64; i = i + 1)
//		$display("vp=%h G=%b",utlb1.TLBVirtPage[i],utlb1.TLBG[i]);
//`include "Thor_commit.v"
// It didn't work in simulation when the following was declared under an
// independant always clk block
//
if (commit0_v && commit0_tgt[6:4]==5'b101) begin
	cregs[commit0_tgt[3:0]] <= commit0_bus;
	$display("cregs[%d]<=%h", commit0_tgt[3:0], commit0_bus);
end
if (commit1_v && commit1_tgt[6:4]==5'b101) begin
	$display("cregs[%d]<=%h", commit1_tgt[3:0], commit1_bus);
	cregs[commit1_tgt[3:0]] <= commit1_bus;
end

`ifdef SEGMENTATION
if (commit0_v && commit0_tgt[6:4]==5'b110) begin
	$display("sregs[%d]<=%h", commit0_tgt[2:0], commit0_bus);
	sregs[commit0_tgt[2:0]] <= commit0_bus[DBW-1:12];
end
if (commit1_v && commit1_tgt[6:4]==5'b110) begin
	$display("sregs[%d]<=%h", commit1_tgt[2:0], commit1_bus);
	sregs[commit1_tgt[2:0]] <= commit1_bus[DBW-1:12];
end
`endif

if (commit0_v && commit0_tgt[8:4]==5'b100)
	pregs[commit0_tgt[3:0]] <= commit0_bus[3:0];
if (commit1_v && commit1_tgt[8:4]==5'b100)
	pregs[commit1_tgt[3:0]] <= commit1_bus[3:0];

//	if (commit1_v && commit1_tgt[8:4]==5'h10)
//		pregs[commit1_tgt[3:0]] <= commit1_bus[3:0];
if (commit0_v && commit0_tgt==7'h70) begin
	pregs[0] <= commit0_bus[3:0];
	pregs[1] <= commit0_bus[7:4];
	pregs[2] <= commit0_bus[11:8];
	pregs[3] <= commit0_bus[15:12];
	pregs[4] <= commit0_bus[19:16];
	pregs[5] <= commit0_bus[23:20];
	pregs[6] <= commit0_bus[27:24];
	pregs[7] <= commit0_bus[31:28];
	if (DBW==64) begin
		pregs[8] <= commit0_bus[35:32];
		pregs[9] <= commit0_bus[39:36];
		pregs[10] <= commit0_bus[43:40];
		pregs[11] <= commit0_bus[47:44];
		pregs[12] <= commit0_bus[51:48];
		pregs[13] <= commit0_bus[55:52];
		pregs[14] <= commit0_bus[59:56];
		pregs[15] <= commit0_bus[63:60];
	end
end
if (commit1_v && commit1_tgt==7'h70) begin
	pregs[0] <= commit1_bus[3:0];
	pregs[1] <= commit1_bus[7:4];
	pregs[2] <= commit1_bus[11:8];
	pregs[3] <= commit1_bus[15:12];
	pregs[4] <= commit1_bus[19:16];
	pregs[5] <= commit1_bus[23:20];
	pregs[6] <= commit1_bus[27:24];
	pregs[7] <= commit1_bus[31:28];
	if (DBW==64) begin
		pregs[8] <= commit1_bus[35:32];
		pregs[9] <= commit1_bus[39:36];
		pregs[10] <= commit1_bus[43:40];
		pregs[11] <= commit1_bus[47:44];
		pregs[12] <= commit1_bus[51:48];
		pregs[13] <= commit1_bus[55:52];
		pregs[14] <= commit1_bus[59:56];
		pregs[15] <= commit1_bus[63:60];
	end
end

// When the INT instruction commits set the hardware interrupt status to disable further interrupts.
if (int_commit)
begin
	$display("*********************");
	$display("*********************");
	$display("Interrupt committing");
	$display("*********************");
	$display("*********************");
	StatusHWI <= `TRUE;
	imb <= im;
	im <= 1'b0;
	// Reset the nmi edge sense circuit but only for an NMI
	if ((iqentry_a0[head0][7:0]==8'hFE && commit0_v && iqentry_op[head0]==`INT) ||
	    (iqentry_a0[head1][7:0]==8'hFE && commit1_v && iqentry_op[head1]==`INT))
		nmi_edge <= 1'b0;
	string_pc <= 64'd0;
end

if (sys_commit)
begin
	if (StatusEXL!=8'hFF)
		StatusEXL <= StatusEXL + 8'd1;
end

if (commit0_v) begin
	case(iqentry_op[head0])
	`CLI:	im <= 1'b0;
	`SEI:	im <= 1'b1;
	// When the RTI instruction commits clear the hardware interrupt status to enable interrupts.
	`RTI:	begin
			StatusHWI <= `FALSE;
			im <= imb;
			end
	`RTE:	begin
				if (StatusEXL!=8'h00)
					StatusEXL <= StatusEXL - 8'd1;
			end
	`LOOP:
		if (lc != 64'd0)
			lc <= lc - 64'd1;
	`MTSPR,`LDIS:
		begin
			case(iqentry_tgt[head0][5:0])
			`LCTR:	lc <= commit0_bus;
			`ASID:	asid <= commit0_bus;
			`SR:	begin
					GM <= commit0_bus[7:0];
					GMB <= commit0_bus[23:16];
					imb <= commit0_bus[31];
					im <= commit0_bus[15];
					fxe <= commit0_bus[12];
					end
			default:	;
			endcase
		end
	default:	;
	endcase
end

if (commit0_v && commit1_v) begin
	case(iqentry_op[head1])
	`CLI:	im <= 1'b0;
	`SEI:	im <= 1'b1;
	`RTI:	begin
			StatusHWI <= `FALSE;
			im <= imb;
			end
	`RTE:	begin
				if (StatusEXL!=8'h00)
					StatusEXL <= StatusEXL - 8'd1;
			end
	`LOOP:
		if (lc != 64'd0)
			lc <= lc - 64'd1;
	`MTSPR,`LDIS:
		begin
			case(iqentry_tgt[head1][5:0])
			`LCTR:	lc <= commit1_bus;
			`ASID:	asid <= commit1_bus;
			`SR:	begin
					GM <= commit1_bus[7:0];
					GMB <= commit1_bus[23:16];
					imb <= commit1_bus[31];
					im <= commit1_bus[15];
					fxe <= commit1_bus[12];
					end
			default:	;
			endcase
		end
	default:	;
	endcase
end

//
// COMMIT PHASE (dequeue only ... not register-file update)
//
// If the third instruction is invalidated then it is allowed to commit too.
// The head pointer might advance by three.
//
if (~|panic)
casex ({ iqentry_v[head0],
	iqentry_done[head0],
	iqentry_v[head1],
	iqentry_done[head1],
	iqentry_v[head2],
	iqentry_done[head2]})

	// retire 3
	6'b0x_0x_0x:
		if (head0 != tail0 && head1 != tail0 && head2 != tail0) begin
			head0 <= head0 + 3;
			head1 <= head1 + 3;
			head2 <= head2 + 3;
			head3 <= head3 + 3;
			head4 <= head4 + 3;
			head5 <= head5 + 3;
			head6 <= head6 + 3;
			head7 <= head7 + 3;
			I <= I + 3;
		end
		else if (head0 != tail0 && head1 != tail0) begin
			head0 <= head0 + 2;
			head1 <= head1 + 2;
			head2 <= head2 + 2;
			head3 <= head3 + 2;
			head4 <= head4 + 2;
			head5 <= head5 + 2;
			head6 <= head6 + 2;
			head7 <= head7 + 2;
			I <= I + 2;
		end
		else if (head0 != tail0) begin
			head0 <= head0 + 1;
			head1 <= head1 + 1;
			head2 <= head2 + 1;
			head3 <= head3 + 1;
			head4 <= head4 + 1;
			head5 <= head5 + 1;
			head6 <= head6 + 1;
			head7 <= head7 + 1;
			I <= I + 1;
		end

	// retire 2 (wait for regfile for head2)
	6'b0x_0x_1x:
//		if (head0 != tail0 && head1 != tail0 && iqentry_rfw[head2]==`FALSE) begin
//			head0 <= head0 + 3;
//			head1 <= head1 + 3;
//			head2 <= head2 + 3;
//			head3 <= head3 + 3;
//			head4 <= head4 + 3;
//			head5 <= head5 + 3;
//			head6 <= head6 + 3;
//			head7 <= head7 + 3;
//			I <= I + 3;
//		end
//		else
		if (head0 != tail0 && head1 != tail0) begin
			head0 <= head0 + 2;
			head1 <= head1 + 2;
			head2 <= head2 + 2;
			head3 <= head3 + 2;
			head4 <= head4 + 2;
			head5 <= head5 + 2;
			head6 <= head6 + 2;
			head7 <= head7 + 2;
			I <= I + 2;
		end
		else if (head0 != tail0) begin
			head0 <= head0 + 1;
			head1 <= head1 + 1;
			head2 <= head2 + 1;
			head3 <= head3 + 1;
			head4 <= head4 + 1;
			head5 <= head5 + 1;
			head6 <= head6 + 1;
			head7 <= head7 + 1;
			I <= I + 1;
		end

	// retire 3
	6'b0x_11_0x:
		if (head0 != tail0 && head1 != tail0 && head2 != tail0) begin
			iqentry_v[head1] <= `INV;
			head0 <= head0 + 3;
			head1 <= head1 + 3;
			head2 <= head2 + 3;
			head3 <= head3 + 3;
			head4 <= head4 + 3;
			head5 <= head5 + 3;
			head6 <= head6 + 3;
			head7 <= head7 + 3;
			I <= I + 3;
		end
		else if (head0 != tail0) begin
			iqentry_v[head1] <= `INV;
			head0 <= head0 + 2;
			head1 <= head1 + 2;
			head2 <= head2 + 2;
			head3 <= head3 + 2;
			head4 <= head4 + 2;
			head5 <= head5 + 2;
			head6 <= head6 + 2;
			head7 <= head7 + 2;
			I <= I + 2;
		end

	// retire 2	(wait on head2 or wait on register file for head2)
	6'b0x_11_1x:
		if (head0 != tail0) begin
			iqentry_v[head1] <= `INV;
			head0 <= head0 + 2;
			head1 <= head1 + 2;
			head2 <= head2 + 2;
			head3 <= head3 + 2;
			head4 <= head4 + 2;
			head5 <= head5 + 2;
			head6 <= head6 + 2;
			head7 <= head7 + 2;
			I <= I + 2;
		end

	// 4'b00_00	- neither valid; skip both
	// 4'b00_01	- neither valid; skip both
	// 4'b00_10	- skip head0, wait on head1
	// 4'b00_11	- skip head0, commit head1
	// 4'b01_00	- neither valid; skip both
	// 4'b01_01	- neither valid; skip both
	// 4'b01_10	- skip head0, wait on head1
	// 4'b01_11	- skip head0, commit head1
	// 4'b10_00	- wait on head0
	// 4'b10_01	- wait on head0
	// 4'b10_10	- wait on head0
	// 4'b10_11	- wait on head0
	// 4'b11_00	- commit head0, skip head1
	// 4'b11_01	- commit head0, skip head1
	// 4'b11_10	- commit head0, wait on head1
	// 4'b11_11	- commit head0, commit head1

	//
	// retire 0 (stuck on head0)
	6'b10_xx_xx:	;
	
	// retire 3
	6'b11_0x_0x:
		if (head1 != tail0 && head2 != tail0) begin
			iqentry_v[head0] <= `INV;
			head0 <= head0 + 3;
			head1 <= head1 + 3;
			head2 <= head2 + 3;
			head3 <= head3 + 3;
			head4 <= head4 + 3;
			head5 <= head5 + 3;
			head6 <= head6 + 3;
			head7 <= head7 + 3;
			I <= I + 3;
		end
		else if (head1 != tail0) begin
			iqentry_v[head0] <= `INV;
			head0 <= head0 + 2;
			head1 <= head1 + 2;
			head2 <= head2 + 2;
			head3 <= head3 + 2;
			head4 <= head4 + 2;
			head5 <= head5 + 2;
			head6 <= head6 + 2;
			head7 <= head7 + 2;
			I <= I + 2;
		end
		else begin
			iqentry_v[head0] <= `INV;
			head0 <= head0 + 1;
			head1 <= head1 + 1;
			head2 <= head2 + 1;
			head3 <= head3 + 1;
			head4 <= head4 + 1;
			head5 <= head5 + 1;
			head6 <= head6 + 1;
			head7 <= head7 + 1;
			I <= I + 1;
		end

	// retire 2 (wait for regfile for head2)
	6'b11_0x_1x:
		if (head1 != tail0) begin
			iqentry_v[head0] <= `INV;
			head0 <= head0 + 2;
			head1 <= head1 + 2;
			head2 <= head2 + 2;
			head3 <= head3 + 2;
			head4 <= head4 + 2;
			head5 <= head5 + 2;
			head6 <= head6 + 2;
			head7 <= head7 + 2;
			I <= I + 2;
		end
		else begin
			iqentry_v[head0] <= `INV;
			head0 <= head0 + 1;
			head1 <= head1 + 1;
			head2 <= head2 + 1;
			head3 <= head3 + 1;
			head4 <= head4 + 1;
			head5 <= head5 + 1;
			head6 <= head6 + 1;
			head7 <= head7 + 1;
			I <= I + 1;
		end

	//
	// retire 1 (stuck on head1)
	6'b00_10_xx,
	6'b01_10_xx,
	6'b11_10_xx:
		if (iqentry_v[head0] || head0 != tail0) begin
			iqentry_v[head0] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
			head0 <= head0 + 1;
			head1 <= head1 + 1;
			head2 <= head2 + 1;
			head3 <= head3 + 1;
			head4 <= head4 + 1;
			head5 <= head5 + 1;
			head6 <= head6 + 1;
			head7 <= head7 + 1;
			I <= I + 1;
		end

	// retire 2 or 3
	6'b11_11_0x:
		if (head2 != tail0) begin
			iqentry_v[head0] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
			iqentry_v[head1] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
			head0 <= head0 + 3;
			head1 <= head1 + 3;
			head2 <= head2 + 3;
			head3 <= head3 + 3;
			head4 <= head4 + 3;
			head5 <= head5 + 3;
			head6 <= head6 + 3;
			head7 <= head7 + 3;
			I <= I + 3;
		end
		else begin
			iqentry_v[head0] <= `INV;
			iqentry_v[head1] <= `INV;
			head0 <= head0 + 2;
			head1 <= head1 + 2;
			head2 <= head2 + 2;
			head3 <= head3 + 2;
			head4 <= head4 + 2;
			head5 <= head5 + 2;
			head6 <= head6 + 2;
			head7 <= head7 + 2;
			I <= I + 2;
		end

	// retire 2 (wait on regfile for head2)
	6'b11_11_1x:
		begin
			iqentry_v[head0] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
			iqentry_v[head1] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
			head0 <= head0 + 2;
			head1 <= head1 + 2;
			head2 <= head2 + 2;
			head3 <= head3 + 2;
			head4 <= head4 + 2;
			head5 <= head5 + 2;
			head6 <= head6 + 2;
			head7 <= head7 + 2;
			I <= I + 2;
		end
endcase

	if (branchmiss)
		rrmapno <= iqentry_renmapno[missid];

	case(cstate)
	IDLE:
		if (dram0 == 3'd6 && !rhit) begin
				$display("********************");
				$display("DCache access to: %h",{pea[DBW-1:5],5'b00000});
				$display("********************");
				derr <= 1'b0;
				bte_o <= 2'b00;
				cti_o <= 3'b001;
				bl_o <= DBW==32 ? 5'd7 : 5'd3;
				cyc_o <= 1'b1;
				stb_o <= 1'b1;
				we_o <= 1'b0;
				sel_o <= {DBW/8{1'b1}};
				adr_o <= {pea[DBW-1:5],5'b00000};
				dat_o <= {DBW{1'b0}};
				cstate <= DCACHE1;
		end
		else if (iuncached & !ibufhit & !mem_will_issue) begin
			ierr <= 1'b0;
			bte_o <= 2'b00;
			cti_o <= 3'b001;
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			we_o <= 1'b0;
			sel_o <= {DBW/8{1'b1}};
			dat_o <= {DBW{1'b0}};
			cstate <= IBUF1;
			if (DBW==64) begin
				$display("********************");
				$display("Insn access to: %h", {ppc[DBW-1:3],3'b000});
				$display("********************");
				bl_o <= 5'd2;
				adr_o <= {ppc[DBW-1:3],3'b000};
			end
			else begin
				$display("********************");
				$display("Insn access to: %h", {ppc[DBW-1:2],2'b00});
				$display("********************");
				bl_o <= 5'd4;
				adr_o <= {ppc[DBW-1:2],2'b00};
			end
		end
		else if (!ihit & !mem_will_issue) begin
			if (dram0!=2'd0 || dram1!=2'd0 || dram2!=2'd0)
				$display("drams non-zero");
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
		begin
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
		end
	DCACHE1:
		begin
			if (ack_i|err_i) begin
				derr <= derr | err_i;	// cumulate an error status
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
		end
	IBUF1:
		if (ack_i|err_i) begin
			ierr <= ierr | err_i;
			if (DBW==64) begin
				adr_o[DBW-1:3] <= adr_o[DBW-1:3] + 61'd1;
				case(ppc[2:0])
				3'd0:	ibuf[63:0] <= dat_i;
				3'd1:	ibuf[55:0] <= dat_i[63:8];
				3'd2:	ibuf[47:0] <= dat_i[63:16];
				3'd3:	ibuf[39:0] <= dat_i[63:24];
				3'd4:	ibuf[31:0] <= dat_i[63:32];
				3'd5:	ibuf[23:0] <= dat_i[63:40];
				3'd6:	ibuf[15:0] <= dat_i[63:48];
				3'd7:	ibuf[ 7:0] <= dat_i[63:56];
				endcase
			end
			else begin
				adr_o[DBW-1:2] <= adr_o[DBW-1:2] + 30'd1;
				case(ppc[1:0])
				2'd0:	ibuf[31:0] <= dat_i;
				2'd1:	ibuf[23:0] <= dat_i[31:8];
				2'd2:	ibuf[15:0] <= dat_i[31:16];
				2'd3:	ibuf[7:0] <= dat_i[31:24];
				endcase
			end
			cstate <= IBUF2;
		end
	IBUF2:
		if (ack_i|err_i) begin
			ierr <= ierr | err_i;
			if (DBW==64) begin
				adr_o[DBW-1:3] <= adr_o[DBW-1:3] + 61'd1;
				case(ppc[2:0])
				3'd0:	ibuf[127:64] <= dat_i;
				3'd1:	ibuf[119:56] <= dat_i;
				3'd2:	ibuf[111:48] <= dat_i;
				3'd3:	ibuf[103:40] <= dat_i;
				3'd4:	ibuf[95:32] <= dat_i;
				3'd5:	ibuf[87:24] <= dat_i;
				3'd6:	ibuf[79:16] <= dat_i;
				3'd7:	ibuf[71: 8] <= dat_i;
				endcase
			end
			else begin
				adr_o[DBW-1:2] <= adr_o[DBW-1:2] + 30'd1;
				case(ppc[1:0])
				2'd0:	ibuf[63:32] <= dat_i;
				2'd1:	ibuf[55:24] <= dat_i;
				2'd2:	ibuf[47:16] <= dat_i;
				2'd3:	ibuf[39: 8] <= dat_i;
				endcase
			end
			cstate <= IBUF3;
		end
	IBUF3:
		if (ack_i|err_i) begin
			ierr <= ierr | err_i;
			if (DBW==64) begin
				wb_nack;
				case(ppc[2:0])
				3'd0:	;
				3'd1:	ibuf[127:120] <= dat_i[7:0];
				3'd2:	ibuf[127:112] <= dat_i[15:0];
				3'd3:	ibuf[127:104] <= dat_i[23:0];
				3'd4:	ibuf[127: 96] <= dat_i[31:0];
				3'd5:	ibuf[127: 88] <= dat_i[39:0];
				3'd6:	ibuf[127: 80] <= dat_i[47:0];
				3'd7:	ibuf[127: 72] <= dat_i[55:0];
				endcase
				ibufadr <= ppc;
				cstate <= IDLE;
			end
			else begin
				adr_o[DBW-1:2] <= adr_o[DBW-1:2] + 30'd1;
				case(ppc[1:0])
				2'd0:	ibuf[95:64] <= dat_i;
				2'd1:	ibuf[87:56] <= dat_i;
				2'd2:	ibuf[79:48] <= dat_i;
				2'd3:	ibuf[71:40] <= dat_i;
				endcase
				cstate <= IBUF4;
			end
		end
	IBUF4:
		if (ack_i|err_i) begin
			ierr <= ierr | err_i;
			adr_o[DBW-1:2] <= adr_o[DBW-1:2] + 30'd1;
			case(ppc[1:0])
			2'd0:	ibuf[127:96] <= dat_i;
			2'd1:	ibuf[119:88] <= dat_i;
			2'd2:	ibuf[111:80] <= dat_i;
			2'd3:	ibuf[103:72] <= dat_i;
			endcase
			cstate <= IBUF5;
		end
	IBUF5:
		if (ack_i|err_i) begin
			ierr <= ierr | err_i;
			wb_nack();
			case(ppc[1:0])
			2'd0:	;
			2'd1:	ibuf[127:120] <= dat_i[7:0];
			2'd2:	ibuf[127:112] <= dat_i[15:0];
			2'd3:	ibuf[127:104] <= dat_i[23:0];
			endcase
			ibufadr <= ppc;
			cstate <= IDLE;
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

