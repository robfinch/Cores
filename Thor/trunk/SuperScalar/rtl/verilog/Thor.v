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
//   \\__/ o\    (C) 2013-2016  Robert Finch, Stratford
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
//      An instruction and data cache were added.
//      A WISHBONE bus interface was added,
//
// 53,950 (86,500 LC's)
// with segmentation
// no bitfield, stack or FP ops
//
// ============================================================================
//
`include "Thor_defines.v"

module Thor(corenum, rst_i, clk_i, clk2x_i, tm_clk_i, clk_o, km, nmi_i, irq_i, vec_i, bte_o, cti_o, bl_o, lock_o, resv_o, resv_i, cres_o,
    cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter DBW = 32;         // databus width
parameter ABW = 32;         // address bus width
parameter RSTCSEG = 52'h0;
parameter RSTPC = 64'hFFFFFFFFFFFC0000;
parameter STARTUP_POWER = 16'hFFFF;
parameter IMCD = 6'h30;
localparam AMSB = ABW-1;
parameter QENTRIES = 8;
parameter ALU1BIG = 0;
parameter RESET1 = 4'd0;
parameter RESET2 = 4'd1;
parameter IDLE = 4'd2;
parameter ICACHE1 = 4'd3;
parameter DCACHE1 = 4'd4;
parameter DCACHE2 = 4'd5;
parameter ICACHE2 = 4'd6;
parameter IBUF3 = 4'd7;
parameter IBUF4 = 4'd8;
parameter IBUF5 = 4'd9;
`ifdef VECTOROPS
parameter NREGS = 511;
`else
parameter NREGS = 127;
`endif
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

// DRAM States
parameter DS_IDLE = 4'd0;
parameter DS_XLAT = 4'd1;
parameter DS_SETUP = 4'd2;
parameter DS_CYC = 4'd3;
parameter DS_ACK = 4'd4;
parameter DS_CAS = 4'd5;
parameter DS_CAS_ACK = 4'd6;
parameter DS_CACHE_READ = 4'd7;
parameter DS_FINAL = 4'd8;

parameter SEGMODEL = 2;

input [63:0] corenum;
input rst_i;
input clk_i;
input clk2x_i;
input tm_clk_i;
output clk_o;
output km;
input nmi_i;
input irq_i;
input [7:0] vec_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [4:0] bl_o;
output reg lock_o;
output reg resv_o;
input resv_i;
output reg cres_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
input err_i;
output reg we_o;
output reg [DBW/8-1:0] sel_o;
output reg [ABW-1:0] adr_o;
input [DBW-1:0] dat_i;
output reg [DBW-1:0] dat_o;

integer n,i;
reg [1:0] mode;
reg [1:0] smode;
reg [3:0] regset,pregset;

// Should make the sequence number bigger, suppose there's a loop without
// branch misses ? Then the sequnce number would roll-over and the
// instruction ordering indicator would be wrong for a few cycles. 
reg [11:0] seqnum;
reg [DBW/8-1:0] rsel;
reg [3:0] cstate;
reg [ABW:0] pc;				     // program counter (virtual)
wire [ABW-1:0] ppc;				// physical pc address
reg [ABW-1:0] interrupt_pc;     // working register for interrupt pc
reg [DBW-1:0] ivno;
reg [DBW-1:0] vadr;				// data virtual address
reg [3:0] panic;		// indexes the message structure
reg [128:0] message [0:15];	// indexed by panic
reg [DBW-1:0] cregs [0:15];		// code address registers
reg [ 3:0] pregs [0:15];		// predicate registers
`ifdef SEGMENTATION
reg [31:0] LDT;
reg [DBW-1:0] GDT;
reg [3:0] segsw;          //
reg [31:0] sregs [0:8];	// segment selector registers
reg [DBW-1:12] sregs_base [0:8];
reg [DBW-1:12] sregs_lmt [0:8];
reg [15:0] sregs_acr [0:8];
wire [7:0] CPL = sregs[7][31:24]; // currently running privilege level
`endif
`ifdef VECTOROPS
reg [3:0] vpregs [1:0][0:15]; // two, sixteen element
`endif
reg [7:0] VL = 0;
reg [DBW-1:0] intarg1;
reg [2:0] rrmapno;				// register rename map number
wire ITLBMiss;
wire DTLBMiss;
wire uncached;
wire [DBW-1:0] cdat;
reg pwe;
wire [DBW-1:0] pea;
reg [63:0] mtime;
reg [63:0] mtimes;
reg [DBW-1:0] tick;
reg [DBW-1:0] lc;				// loop counter
reg [DBW-1:0] rfoa0,rfoa1;
reg [DBW-1:0] rfob0,rfob1;
reg [DBW-1:0] rfoc0,rfoc1;
reg [DBW-1:0] rfot0,rfot1;
reg ic_invalidate,dc_invalidate;
reg ic_invalidate_line,dc_invalidate_line;
reg [ABW-1:0] ic_lineno,dc_lineno;
reg ierr,derr;			// err_i during icache load
wire insnerr;				// err_i during icache load
wire [127:0] insn;
wire iuncached;
reg [NREGS:0] rf_v;
//reg [15:0] pf_v;
reg im,imb;
reg [5:0] imcd;
reg fxe,pfxe;
reg nmi1,nmi_edge;
reg StatusHWI;
reg StatusDBG;
reg [7:0] StatusEXL;
assign km = StatusHWI | |StatusEXL;
reg [7:0] GM;		// register group mask
reg [7:0] GMB;
wire [63:0] sr = {32'd0,imb,7'b0,GMB,im,1'b0,km,fxe,4'b0,GM};
wire int_commit;
wire int_pending;
wire sys_commit;
wire dbg_commit;
`ifdef SEGMENTATION
wire [DBW-1:0] spc = (pc[ABW]==1'b1) ? pc[ABW-1:0] :
                     (pc[ABW-1:ABW-4]==4'hF) ? pc[ABW-1:0] : {sregs_base[3'd7],12'h000} + pc[ABW-1:0];
`else
wire [DBW-1:0] spc = pc;
`endif
wire [DBW-1:0] ppcp16 = ppc + 64'd16;
reg [DBW-1:0] string_pc;
reg stmv_flag;
reg [7:0] asid;
wire [DBW-1:0] operandA0, operandA1;

wire clk;

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
reg        iqentry_br   [0:7];  // branch instruction decode
reg        iqentry_agen [0:7];  // memory address is generated
reg        iqentry_mem	[0:7];	// touches memory: 1 if LW/SW
reg        iqentry_vec  [0:7];  // is a vector instruction
reg        iqentry_ndx  [0:7];  // TRUE if indexed memory op
reg        iqentry_cas  [0:7];
reg        iqentry_pushpop [0:7];
reg        iqentry_pea  [0:7];
reg        iqentry_cmpmv [0:7];
reg        iqentry_lla  [0:7];  // load linear address
reg        iqentry_tlb  [0:7];
reg        iqentry_jmp	[0:7];	// changes control flow: 1 if BEQ/JALR
reg        iqentry_jmpi [0:7];
reg        iqentry_sync [0:7];  // sync instruction
reg        iqentry_memsb[0:7];
reg        iqentry_memdb[0:7];
reg        iqentry_fp   [0:7];  // is an floating point operation
reg        iqentry_rfw	[0:7];	// writes to register file
reg [DBW-1:0] iqentry_res	[0:7];	// instruction result
reg  [3:0] iqentry_insnsz [0:7];	// the size of the instruction
reg  [3:0] iqentry_cond [0:7];	// predicating condition
reg  [3:0] iqentry_preg [0:7];  // predicate regno
reg  [3:0] iqentry_pred [0:7];	// predicate value
reg        iqentry_p_v  [0:7];	// predicate is valid
reg  [3:0] iqentry_p_s  [0:7];	// predicate source
reg  [7:0] iqentry_op	[0:7];	// instruction opcode
reg  [5:0] iqentry_fn   [0:7];  // instruction function
reg  [2:0] iqentry_renmapno [0:7];	// register rename map number
reg  [9:0] iqentry_tgt	[0:7];	// Rt field or ZERO -- this is the instruction's target (if any)
reg [DBW-1:0] iqentry_a0	[0:7];	// argument 0 (immediate)
reg [DBW-1:0] iqentry_a1	[0:7];	// argument 1
reg [7:0]  iqentry_r1   [0:7];
reg        iqentry_a1_v	[0:7];	// arg1 valid
reg  [3:0] iqentry_a1_s	[0:7];	// arg1 source (iq entry # with top bit representing ALU/DRAM bus)
reg [7:0]  iqentry_r2   [0:7];
reg [DBW-1:0] iqentry_a2	[0:7];	// argument 2
reg        iqentry_a2_v	[0:7];	// arg2 valid
reg  [3:0] iqentry_a2_s	[0:7];	// arg2 source (iq entry # with top bit representing ALU/DRAM bus)
reg        iqentry_a2_sv [0:7]; // source is vector register
reg [7:0]  iqentry_r3   [0:7];
reg [DBW-1:0] iqentry_a3	[0:7];	// argument 3
reg        iqentry_a3_v	[0:7];	// arg3 valid
reg  [3:0] iqentry_a3_s	[0:7];	// arg3 source (iq entry # with top bit representing ALU/DRAM bus)
`ifdef VECTOROPS
reg [7:0]  iqentry_r4   [0:7];
reg [DBW-1:0] iqentry_a4 [0:7];  // argument 4
reg        iqentry_a4_v [0:7];
reg [3:0]  iqentry_a4_s [0:7];
`endif
reg [7:0]  iqentry_rt   [0:7];
reg [DBW-1:0] iqentry_T [0:7];
reg        iqentry_T_v [0:7];
reg  [3:0] iqentry_T_s [0:7];
reg [DBW-1:0] iqentry_pc	[0:7];	// program counter for this instruction
reg [11:0] iqentry_sn  [0:7];  // seguence number
reg        iqentry_velv [0:7];

reg  [7:0] iqentry_source;
wire  iqentry_imm [0:7];
wire  iqentry_memready [0:7];
wire  iqentry_memopsvalid [0:7];
reg qstomp;

wire stomp_all;
reg  [7:0] iqentry_fpissue;
reg  [7:0] iqentry_memissue;
wire iqentry_memissue_head0;
wire iqentry_memissue_head1;
wire iqentry_memissue_head2;
wire iqentry_memissue_head3;
wire iqentry_memissue_head4;
wire iqentry_memissue_head5;
wire iqentry_memissue_head6;
wire iqentry_memissue_head7;
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

reg queued1,queued2;
reg queued3;    // for three-way config
reg queued1v,queued2v;
reg queued3v;    // for three-way config
reg allowq;

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
reg  [2:0] tail2;   // used only for three-way config
reg  [2:0] head0;
reg  [2:0] head1;
reg  [2:0] head2;	// used only to determine memory-access ordering
reg  [2:0] head3;	// used only to determine memory-access ordering
reg  [2:0] head4;	// used only to determine memory-access ordering
reg  [2:0] head5;	// used only to determine memory-access ordering
reg  [2:0] head6;	// used only to determine memory-access ordering
reg  [2:0] head7;	// used only to determine memory-access ordering
reg  [2:0] headinc;

reg   fetchbuf;		// determines which pair to read from & write to

reg  [63:0] fetchbuf0_instr;
reg  [DBW-1:0] fetchbuf0_pc;
reg         fetchbuf0_v;
wire        fetchbuf0_mem;
wire        fetchbuf0_vec;
wire        fetchbuf0_jmp;
wire 		fetchbuf0_fp;
wire        fetchbuf0_rfw;
wire        fetchbuf0_pfw;
reg  [63:0] fetchbuf1_instr;
reg  [DBW-1:0] fetchbuf1_pc;
reg        fetchbuf1_v;
wire        fetchbuf1_mem;
wire        fetchbuf1_vec;
wire        fetchbuf1_jmp;
wire 		fetchbuf1_fp;
wire        fetchbuf1_rfw;
wire        fetchbuf1_pfw;
wire        fetchbuf1_bfw;
reg  [63:0] fetchbuf2_instr;
reg  [DBW-1:0] fetchbuf2_pc;
reg        fetchbuf2_v;
wire        fetchbuf2_mem;
wire        fetchbuf2_vec;
wire        fetchbuf2_jmp;
wire 		fetchbuf2_fp;
wire        fetchbuf2_rfw;
wire        fetchbuf2_pfw;
wire        fetchbuf2_bfw;

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
reg        alu0_cmt;
reg [DBW-1:0] alu0_argA;
reg [DBW-1:0] alu0_argB;
reg [DBW-1:0] alu0_argC;
reg [DBW-1:0] alu0_argT;
reg [DBW-1:0] alu0_argI;
reg  [3:0] alu0_pred;
reg [DBW-1:0] alu0_pc;
reg [DBW-1:0] alu0_bus;
reg  [3:0] alu0_id;
wire  [8:0] alu0_exc;
reg        alu0_v;
wire        alu0_branchmiss;
reg [ABW:0] alu0_misspc;

reg        alu1_ld;
reg        alu1_available;
reg        alu1_dataready;
reg  [3:0] alu1_sourceid;
reg  [3:0] alu1_insnsz;
reg  [7:0] alu1_op;
reg  [5:0] alu1_fn;
reg  [3:0] alu1_cond;
reg        alu1_bt;
reg        alu1_cmt;
reg [DBW-1:0] alu1_argA;
reg [DBW-1:0] alu1_argB;
reg [DBW-1:0] alu1_argC;
reg [DBW-1:0] alu1_argT;
reg [DBW-1:0] alu1_argI;
reg  [3:0] alu1_pred;
reg [DBW-1:0] alu1_pc;
reg [DBW-1:0] alu1_bus;
reg  [3:0] alu1_id;
wire  [8:0] alu1_exc;
reg        alu1_v;
wire        alu1_branchmiss;
reg [ABW:0] alu1_misspc;

wire jmpi_miss;
reg [ABW-1:0] jmpi_misspc;
wire mem_stringmissx;
reg mem_stringmiss;
wire        branchmiss;
reg intmiss;
reg rtimiss;
reg [ABW:0] misspc;
reg  [2:0] missid;

`ifdef FLOATING_POINT
reg        fp0_ld;
reg        fp0_available;
reg        fp0_dataready;
reg  [3:0] fp0_sourceid;
reg  [7:0] fp0_op;
reg  [5:0] fp0_fn;
reg  [3:0] fp0_cond;
wire        fp0_cmt;
reg 		fp0_done;
reg [DBW-1:0] fp0_argA;
reg [DBW-1:0] fp0_argB;
reg [DBW-1:0] fp0_argC;
reg [DBW-1:0] fp0_argI;
reg  [3:0] fp0_pred;
reg [DBW-1:0] fp0_pc;
wire [DBW-1:0] fp0_bus;
wire  [3:0] fp0_id;
wire  [7:0] fp0_exc;
wire        fp0_v;
`endif

wire        dram_avail;
reg	 [3:0] dram0;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [3:0] dram1;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [3:0] dram2;	// state of the DRAM request (latency = 4; can have three in pipeline)
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
reg [DBW-1:0] dram0_seg;        // value of segment register associated with memory operation
reg [ABW-1:12] dram0_lmt;       // value of segment limit associated with memory operation
reg  [7:0] dram0_op;
reg  [5:0] dram0_fn;
reg  [9:0] dram0_tgt;
reg  [3:0] dram0_id;
reg  [8:0] dram0_exc;
reg [ABW-1:0] dram0_misspc;
reg dram1_owns_bus;
reg [DBW-1:0] dram1_data;
reg [DBW-1:0] dram1_datacmp;
reg [DBW-1:0] dram1_addr;
reg  [7:0] dram1_op;
reg  [5:0] dram1_fn;
reg  [9:0] dram1_tgt;
reg  [3:0] dram1_id;
reg  [8:0] dram1_exc;
reg [DBW-1:0] dram2_data;
reg [DBW-1:0] dram2_datacmp;
reg [DBW-1:0] dram2_addr;
reg  [7:0] dram2_op;
reg  [5:0] dram2_fn;
reg  [9:0] dram2_tgt;
reg  [3:0] dram2_id;
reg  [8:0] dram2_exc;

reg [DBW-1:0] dram_bus;
reg  [9:0] dram_tgt;
reg  [3:0] dram_id;
reg  [8:0] dram_exc;
reg        dram_v;

reg [DBW-1:0] index;
reg [DBW-1:0] src_addr,dst_addr;
wire mem_issue;

wire        outstanding_stores;
reg [DBW-1:0] I;	// instruction count

wire        commit0_v;
wire  [3:0] commit0_id;
wire  [7:0] commit0_tgt;
wire [DBW-1:0] commit0_bus;
wire        commit1_v;
wire  [3:0] commit1_id;
wire  [7:0] commit1_tgt;
wire [DBW-1:0] commit1_bus;
wire        commit2_v;
wire  [3:0] commit2_id;
wire  [7:0] commit2_tgt;
wire [DBW-1:0] commit2_bus;
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

reg exception_set;

//-----------------------------------------------------------------------------
// Debug
//-----------------------------------------------------------------------------

wire [DBW-1:0] dbg_stat1x;
reg [DBW-1:0] dbg_stat;
reg [DBW-1:0] dbg_ctrl;
reg [ABW-1:0] dbg_adr0;
reg [ABW-1:0] dbg_adr1;
reg [ABW-1:0] dbg_adr2;
reg [ABW-1:0] dbg_adr3;
reg dbg_imatchA0,dbg_imatchA1,dbg_imatchA2,dbg_imatchA3,dbg_imatchA;
reg dbg_imatchB0,dbg_imatchB1,dbg_imatchB2,dbg_imatchB3,dbg_imatchB;

wire dbg_lmatch0 =
			dbg_ctrl[0] && dbg_ctrl[17:16]==2'b11 && dram0_addr[AMSB:3]==dbg_adr0[AMSB:3] &&
				((dbg_ctrl[19:18]==2'b00 && dram0_addr[2:0]==dbg_adr0[2:0]) ||
				 (dbg_ctrl[19:18]==2'b01 && dram0_addr[2:1]==dbg_adr0[2:1]) ||
				 (dbg_ctrl[19:18]==2'b10 && dram0_addr[2]==dbg_adr0[2]) ||
				 dbg_ctrl[19:18]==2'b11)
				 ;
wire dbg_lmatch1 =
             dbg_ctrl[1] && dbg_ctrl[21:20]==2'b11 && dram0_addr[AMSB:3]==dbg_adr1[AMSB:3] &&
                 ((dbg_ctrl[23:22]==2'b00 && dram0_addr[2:0]==dbg_adr1[2:0]) ||
                  (dbg_ctrl[23:22]==2'b01 && dram0_addr[2:1]==dbg_adr1[2:1]) ||
                  (dbg_ctrl[23:22]==2'b10 && dram0_addr[2]==dbg_adr1[2]) ||
                  dbg_ctrl[23:22]==2'b11)
                  ;
wire dbg_lmatch2 =
               dbg_ctrl[2] && dbg_ctrl[25:24]==2'b11 && dram0_addr[AMSB:3]==dbg_adr2[AMSB:3] &&
                   ((dbg_ctrl[27:26]==2'b00 && dram0_addr[2:0]==dbg_adr2[2:0]) ||
                    (dbg_ctrl[27:26]==2'b01 && dram0_addr[2:1]==dbg_adr2[2:1]) ||
                    (dbg_ctrl[27:26]==2'b10 && dram0_addr[2]==dbg_adr2[2]) ||
                    dbg_ctrl[27:26]==2'b11)
                    ;
wire dbg_lmatch3 =
                 dbg_ctrl[3] && dbg_ctrl[29:28]==2'b11 && dram0_addr[AMSB:3]==dbg_adr3[AMSB:3] &&
                     ((dbg_ctrl[31:30]==2'b00 && dram0_addr[2:0]==dbg_adr3[2:0]) ||
                      (dbg_ctrl[31:30]==2'b01 && dram0_addr[2:1]==dbg_adr3[2:1]) ||
                      (dbg_ctrl[31:30]==2'b10 && dram0_addr[2]==dbg_adr3[2]) ||
                      dbg_ctrl[31:30]==2'b11)
                      ;
wire dbg_lmatch = dbg_lmatch0|dbg_lmatch1|dbg_lmatch2|dbg_lmatch3;

wire dbg_smatch0 =
			dbg_ctrl[0] && dbg_ctrl[17:16]==2'b11 && dram0_addr[AMSB:3]==dbg_adr0[AMSB:3] &&
				((dbg_ctrl[19:18]==2'b00 && dram0_addr[2:0]==dbg_adr0[2:0]) ||
				 (dbg_ctrl[19:18]==2'b01 && dram0_addr[2:1]==dbg_adr0[2:1]) ||
				 (dbg_ctrl[19:18]==2'b10 && dram0_addr[2]==dbg_adr0[2]) ||
				 dbg_ctrl[19:18]==2'b11)
				 ;
wire dbg_smatch1 =
             dbg_ctrl[1] && dbg_ctrl[21:20]==2'b11 && dram0_addr[AMSB:3]==dbg_adr1[AMSB:3] &&
                 ((dbg_ctrl[23:22]==2'b00 && dram0_addr[2:0]==dbg_adr1[2:0]) ||
                  (dbg_ctrl[23:22]==2'b01 && dram0_addr[2:1]==dbg_adr1[2:1]) ||
                  (dbg_ctrl[23:22]==2'b10 && dram0_addr[2]==dbg_adr1[2]) ||
                  dbg_ctrl[23:22]==2'b11)
                  ;
wire dbg_smatch2 =
               dbg_ctrl[2] && dbg_ctrl[25:24]==2'b11 && dram0_addr[AMSB:3]==dbg_adr2[AMSB:3] &&
                   ((dbg_ctrl[27:26]==2'b00 && dram0_addr[2:0]==dbg_adr2[2:0]) ||
                    (dbg_ctrl[27:26]==2'b01 && dram0_addr[2:1]==dbg_adr2[2:1]) ||
                    (dbg_ctrl[27:26]==2'b10 && dram0_addr[2]==dbg_adr2[2]) ||
                    dbg_ctrl[27:26]==2'b11)
                    ;
wire dbg_smatch3 =
                 dbg_ctrl[3] && dbg_ctrl[29:28]==2'b11 && dram0_addr[AMSB:3]==dbg_adr3[AMSB:3] &&
                     ((dbg_ctrl[31:30]==2'b00 && dram0_addr[2:0]==dbg_adr3[2:0]) ||
                      (dbg_ctrl[31:30]==2'b01 && dram0_addr[2:1]==dbg_adr3[2:1]) ||
                      (dbg_ctrl[31:30]==2'b10 && dram0_addr[2]==dbg_adr3[2]) ||
                      dbg_ctrl[31:30]==2'b11)
                      ;
wire dbg_smatch = dbg_smatch0|dbg_smatch1|dbg_smatch2|dbg_smatch3;

wire dbg_stat0 = dbg_imatchA0 | dbg_imatchB0 | dbg_lmatch0 | dbg_smatch0;
wire dbg_stat1 = dbg_imatchA1 | dbg_imatchB1 | dbg_lmatch1 | dbg_smatch1;
wire dbg_stat2 = dbg_imatchA2 | dbg_imatchB2 | dbg_lmatch2 | dbg_smatch2;
wire dbg_stat3 = dbg_imatchA3 | dbg_imatchB3 | dbg_lmatch3 | dbg_smatch3;
assign dbg_stat1x = {dbg_stat3,dbg_stat2,dbg_stat1,dbg_stat0};
wire debug_on = |dbg_ctrl[3:0]|dbg_ctrl[7];

reg [11:0] spr_bir;

always @(StatusHWI or StatusDBG or StatusEXL)
if (StatusHWI)
    mode = 2'd1;
else if (StatusDBG)
    mode = 2'd3;
else if (StatusEXL)
    mode = 2'd2;
else
    mode = 2'd0;

//
// BRANCH-MISS LOGIC: livetarget
//
// livetarget implies that there is a not-to-be-stomped instruction that targets the register in question
// therefore, if it is zero it implies the rf_v value should become VALID on a branchmiss
// 
/*
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

assign iqentry_0_latestID = ((missid == 3'd0)|| ((iqentry_0_livetarget & iqentry_1_cumulative) == {NREGS{1'b0}}))
				? iqentry_0_livetarget
				: {NREGS{1'b0}};
assign iqentry_0_cumulative = (missid == 3'd0)
				? iqentry_0_livetarget
				: iqentry_0_livetarget | iqentry_1_cumulative;

assign iqentry_1_latestID = ((missid == 3'd1)|| ((iqentry_1_livetarget & iqentry_2_cumulative) == {NREGS{1'b0}}))
				? iqentry_1_livetarget
				: {NREGS{1'b0}};
assign iqentry_1_cumulative = (missid == 3'd1)
				? iqentry_1_livetarget
				: iqentry_1_livetarget | iqentry_2_cumulative;

assign iqentry_2_latestID = ((missid == 3'd2) || ((iqentry_2_livetarget & iqentry_3_cumulative) == {NREGS{1'b0}}))
				? iqentry_2_livetarget
				: {NREGS{1'b0}};
assign iqentry_2_cumulative = (missid == 3'd2)
				? iqentry_2_livetarget
				: iqentry_2_livetarget | iqentry_3_cumulative;

assign iqentry_3_latestID = ((missid == 3'd3)|| ((iqentry_3_livetarget & iqentry_4_cumulative) == {NREGS{1'b0}}))
				? iqentry_3_livetarget
				: {NREGS{1'b0}};
assign iqentry_3_cumulative = (missid == 3'd3)
				? iqentry_3_livetarget
				: iqentry_3_livetarget | iqentry_4_cumulative;

assign iqentry_4_latestID = ((missid == 3'd4) || ((iqentry_4_livetarget & iqentry_5_cumulative) == {NREGS{1'b0}}))
				? iqentry_4_livetarget
				: {NREGS{1'b0}};
assign iqentry_4_cumulative = (missid == 3'd4)
				? iqentry_4_livetarget
				: iqentry_4_livetarget | iqentry_5_cumulative;

assign iqentry_5_latestID = ((missid == 3'd5)|| ((iqentry_5_livetarget & iqentry_6_cumulative) == {NREGS{1'b0}}))
				? iqentry_5_livetarget
				: 287'd0;
assign iqentry_5_cumulative = (missid == 3'd5)
				? iqentry_5_livetarget
				: iqentry_5_livetarget | iqentry_6_cumulative;

assign iqentry_6_latestID = ((missid == 3'd6) || ((iqentry_6_livetarget & iqentry_7_cumulative) == {NREGS{1'b0}}))
				? iqentry_6_livetarget
				: {NREGS{1'b0}};
assign iqentry_6_cumulative = (missid == 3'd6)
				? iqentry_6_livetarget
				: iqentry_6_livetarget | iqentry_7_cumulative;

assign iqentry_7_latestID = ((missid == 3'd7) || ((iqentry_7_livetarget & iqentry_0_cumulative) == {NREGS{1'b0}}))
				? iqentry_7_livetarget
				: {NREGS{1'b0}};
assign iqentry_7_cumulative = (missid==3'd7)
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
*/
always @*
begin
iqentry_source = 8'h00;
if (missid==head0) begin
    if (iqentry_v[head0] && !iqentry_stomp[head0])
        iqentry_source[head0] = !fnRegIsAutoValid(iqentry_tgt[head0]);
end
else if (missid==head1) begin
    if (iqentry_v[head0] && !iqentry_stomp[head0])
        iqentry_source[head0] = !fnRegIsAutoValid(iqentry_tgt[head0]);
    if (iqentry_v[head1] && !iqentry_stomp[head1])
        iqentry_source[head1] = !fnRegIsAutoValid(iqentry_tgt[head1]);
end
else if (missid==head2) begin 
    if (iqentry_v[head0] && !iqentry_stomp[head0])
        iqentry_source[head0] = !fnRegIsAutoValid(iqentry_tgt[head0]);
    if (iqentry_v[head1] && !iqentry_stomp[head1])
        iqentry_source[head1] = !fnRegIsAutoValid(iqentry_tgt[head1]);
    if (iqentry_v[head2] && !iqentry_stomp[head2])
        iqentry_source[head2] = !fnRegIsAutoValid(iqentry_tgt[head2]);
end
else if (missid==head3) begin 
    if (iqentry_v[head0] && !iqentry_stomp[head0])
        iqentry_source[head0] = !fnRegIsAutoValid(iqentry_tgt[head0]);
    if (iqentry_v[head1] && !iqentry_stomp[head1])
        iqentry_source[head1] = !fnRegIsAutoValid(iqentry_tgt[head1]);
    if (iqentry_v[head2] && !iqentry_stomp[head2])
        iqentry_source[head2] = !fnRegIsAutoValid(iqentry_tgt[head2]);
    if (iqentry_v[head3] && !iqentry_stomp[head3])
        iqentry_source[head3] = !fnRegIsAutoValid(iqentry_tgt[head3]);
end
else if (missid==head4) begin 
    if (iqentry_v[head0] && !iqentry_stomp[head0])
        iqentry_source[head0] = !fnRegIsAutoValid(iqentry_tgt[head0]);
    if (iqentry_v[head1] && !iqentry_stomp[head1])
        iqentry_source[head1] = !fnRegIsAutoValid(iqentry_tgt[head1]);
    if (iqentry_v[head2] && !iqentry_stomp[head2])
        iqentry_source[head2] = !fnRegIsAutoValid(iqentry_tgt[head2]);
    if (iqentry_v[head3] && !iqentry_stomp[head3])
        iqentry_source[head3] = !fnRegIsAutoValid(iqentry_tgt[head3]);
    if (iqentry_v[head4] && !iqentry_stomp[head4])
        iqentry_source[head4] = !fnRegIsAutoValid(iqentry_tgt[head4]);
end
else if (missid==head5) begin 
    if (iqentry_v[head0] && !iqentry_stomp[head0])
        iqentry_source[head0] = !fnRegIsAutoValid(iqentry_tgt[head0]);
    if (iqentry_v[head1] && !iqentry_stomp[head1])
        iqentry_source[head1] = !fnRegIsAutoValid(iqentry_tgt[head1]);
    if (iqentry_v[head2] && !iqentry_stomp[head2])
        iqentry_source[head2] = !fnRegIsAutoValid(iqentry_tgt[head2]);
    if (iqentry_v[head3] && !iqentry_stomp[head3])
        iqentry_source[head3] = !fnRegIsAutoValid(iqentry_tgt[head3]);
    if (iqentry_v[head4] && !iqentry_stomp[head4])
        iqentry_source[head4] = !fnRegIsAutoValid(iqentry_tgt[head4]);
    if (iqentry_v[head5] && !iqentry_stomp[head5])
        iqentry_source[head5] = !fnRegIsAutoValid(iqentry_tgt[head5]);
end
else if (missid==head6) begin 
    if (iqentry_v[head0] && !iqentry_stomp[head0])
        iqentry_source[head0] = !fnRegIsAutoValid(iqentry_tgt[head0]);
    if (iqentry_v[head1] && !iqentry_stomp[head1])
        iqentry_source[head1] = !fnRegIsAutoValid(iqentry_tgt[head1]);
    if (iqentry_v[head2] && !iqentry_stomp[head2])
        iqentry_source[head2] = !fnRegIsAutoValid(iqentry_tgt[head2]);
    if (iqentry_v[head3] && !iqentry_stomp[head3])
        iqentry_source[head3] = !fnRegIsAutoValid(iqentry_tgt[head3]);
    if (iqentry_v[head4] && !iqentry_stomp[head4])
        iqentry_source[head4] = !fnRegIsAutoValid(iqentry_tgt[head4]);
    if (iqentry_v[head5] && !iqentry_stomp[head5])
        iqentry_source[head5] = !fnRegIsAutoValid(iqentry_tgt[head5]);
    if (iqentry_v[head6] && !iqentry_stomp[head6])
        iqentry_source[head6] = !fnRegIsAutoValid(iqentry_tgt[head6]);
end
else if (missid==head7) begin 
    if (iqentry_v[head0] && !iqentry_stomp[head0])
        iqentry_source[head0] = !fnRegIsAutoValid(iqentry_tgt[head0]);
    if (iqentry_v[head1] && !iqentry_stomp[head1])
        iqentry_source[head1] = !fnRegIsAutoValid(iqentry_tgt[head1]);
    if (iqentry_v[head2] && !iqentry_stomp[head2])
        iqentry_source[head2] = !fnRegIsAutoValid(iqentry_tgt[head2]);
    if (iqentry_v[head3] && !iqentry_stomp[head3])
        iqentry_source[head3] = !fnRegIsAutoValid(iqentry_tgt[head3]);
    if (iqentry_v[head4] && !iqentry_stomp[head4])
        iqentry_source[head4] = !fnRegIsAutoValid(iqentry_tgt[head4]);
    if (iqentry_v[head5] && !iqentry_stomp[head5])
        iqentry_source[head5] = !fnRegIsAutoValid(iqentry_tgt[head5]);
    if (iqentry_v[head6] && !iqentry_stomp[head6])
        iqentry_source[head6] = !fnRegIsAutoValid(iqentry_tgt[head6]);
    if (iqentry_v[head7] && !iqentry_stomp[head7])
        iqentry_source[head7] = !fnRegIsAutoValid(iqentry_tgt[head7]);
end
end

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
reg [1:0] ports_avail;  // available read ports for instruction #3.
reg [9:0] pRa0,pRb0,pRa1,pRb1,pRt0,pRt1;
wire [9:0] pRc0,pRd0,pRc1,pRd1;
wire [DBW-1:0] prfoa0,prfob0,prfoa1,prfob1;
wire [DBW-1:0] pvrfoa0,pvrfob0,pvrfoa1,pvrfob1,pvrfoc0,pvrfoc1;
wire [DBW-1:0] prfot0,prfot1;
wire [DBW-1:0] vrfot0,vrfot1;

reg [2:0] vele;
wire [7:0] Ra0 = fnRa(fetchbuf0_instr);
wire [7:0] Rb0 = fnRb(fetchbuf0_instr);
wire [7:0] Rc0 = fnRc(fetchbuf0_instr);
wire [7:0] Rd0 = fnRd(fetchbuf0_instr);
wire [7:0] Ra1 = fnRa(fetchbuf1_instr);
wire [7:0] Rb1 = fnRb(fetchbuf1_instr);
wire [7:0] Rc1 = fnRc(fetchbuf1_instr);
wire [7:0] Rd1 = fnRd(fetchbuf1_instr);
wire [7:0] Rt0 = fnTargetReg(fetchbuf0_instr);
wire [7:0] Rt1 = fnTargetReg(fetchbuf1_instr);
assign pRc0 = Rc0;
assign pRd0 = Rd0;
assign pRc1 = Rc1;
assign pRd1 = Rd1;

always @*
begin
    pRt0 = Rt0;
    pRt1 = Rt1;
    rfot0 = prfot0;
    rfot1 = prfot1; 
    case(fetchbuf0_v ? fnNumReadPorts(fetchbuf0_instr) : 2'd0)
    3'd0:   begin
            pRa0 = 8'd0;
            pRb0 = Rc1;
            pRa1 = Ra1;
            pRb1 = Rb1;
            rfoa0 = 64'd0;
            rfob0 = 64'd0;
            rfoc0 = 64'd0;
            rfoa1 = prfoa1;
            rfob1 = prfob1;
            rfoc1 = prfob0;
            ports_avail = 2'd3;
            end
    3'd1:   begin
            pRa0 = Ra0;
            pRb0 = Rc1;
            pRa1 = Ra1;
            pRb1 = Rb1;
            rfoa0 = prfoa0;
            rfob0 = 64'd0;
            rfoc0 = 64'd0;
            rfoa1 = prfoa1;
            rfob1 = prfob1;
            rfoc1 = prfob0;
            ports_avail = 2'd3;
            end
    3'd2:   begin
            pRa0 = Ra0;
            pRb0 = Rb0;
            pRa1 = Ra1;
            pRb1 = Rb1;
            rfoa0 = prfoa0;
            rfob0 = prfob0;
            rfoc0 = 64'd0;
            rfoa1 = prfoa1;
            rfob1 = prfob1;
            rfoc1 = 64'd0; 
            ports_avail = 2'd2;
            end   
    3'd3:   begin
            pRa0 = Ra0;
            pRb0 = Rb0;
            pRa1 = Rc0;
            pRb1 = Ra1;
            rfoa0 = prfoa0;
            rfob0 = prfob0;
            rfoc0 = prfoa1;
            rfoa1 = prfob1;
            rfob1 = 64'd0;
            rfoc1 = 64'd0;
            ports_avail = 2'd1;
            end
    default:   begin
            pRa0 = 8'd0;
            pRb0 = Rc1;
            pRa1 = Ra1;
            pRb1 = Rb1;
            rfoa0 = 64'd0;
            rfob0 = 64'd0;
            rfoc0 = 64'd0;
            rfoa1 = prfoa1;
            rfob1 = prfob1;
            rfoc1 = prfob0;
            ports_avail = 2'd3;
            end
    endcase
end

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
						ins[7:0]==8'h10 ? `NOP : ins[15:8];
endfunction

wire [7:0] opcode0 = fnOpcode(fetchbuf0_instr);
wire [7:0] opcode1 = fnOpcode(fetchbuf1_instr);
wire [3:0] cond0 = fetchbuf0_instr[3:0];
wire [3:0] cond1 = fetchbuf1_instr[3:0];
wire [3:0] Pn0 = fetchbuf0_instr[7:4];
wire [3:0] Pn1 = fetchbuf1_instr[7:4];

wire [6:0] r27 = 7'd27 + mode;

function [7:0] fnRa;
input [63:0] isn;
	case(isn[15:8])
	`RTF,`JSF:   fnRa = 8'h5C;  // cregs[12]
	`RTS2:  fnRa = 8'h51;
	`RTI:	fnRa = 8'h5E;
	`RTD:   fnRa = 8'h5B;
	`RTE:	fnRa = 8'h5D;
	`JSR,`JSRS,`JSRZ,`SYS,`INT,`RTS:
		fnRa = {4'h5,isn[23:20]};
	`TLB:  fnRa = {4'b0,isn[29:24]};
	`P:    fnRa = 8'h70;
	`LOOP:  fnRa = 8'h73;
	`PUSH:   fnRa = r27;
`ifdef STACKOPS
	`PEA,`POP,`LINK:   fnRa = r27;
`endif
    `MFSPR,`MOVS:   
        if (isn[`INSTRUCTION_RA]==`USP)
            fnRa = 8'd27;
        else
            fnRa = {4'd1,isn[`INSTRUCTION_RA]};
	default:
	       if (isn[`INSTRUCTION_RA]==6'd27)
	           fnRa = r27;
	       else	
	           fnRa = {4'b0,isn[`INSTRUCTION_RA]};
	endcase
endfunction

function [7:0] fnRb;
input [63:0] isn;
	case(isn[15:8])
//	`LOOP:  fnRb = 7'h73;
//	`RTS,`STP,`TLB,`POP:   fnRb = 7'd0;
	`JSR,`JSRS,`JSRZ,`SYS,`INT:
		fnRb = {3'h5,isn[23:20]};
	`SWS:  if (isn[27:22]==`USP)
	           fnRb = {1'b0,6'd27};
	       else 
	           fnRb = {1'b1,isn[27:22]};
	`PUSH:  fnRb = isn[22:16];
`ifdef STACKOPS
	`LINK:  fnRb = {1'b0,isn[27:22]};
	`PEA:   fnRb = {1'b0,isn[21:16]};
`endif
`ifdef VECTOROPS
  `VR:
    case(isn[39:34])
    `VBITS2V: fnRb = {4'd0,isn[25:22]};
    `VEINS:  fnRb = {4'd0,isn[25:22]};
    default:  fnRb = {1'b1,vele,isn[25:22]};
    endcase
  `VRR:
    case(isn[47:43])
    `VSCALE:  fnRb = {4'd0,isn[25:22]};
    `VSCALEL: fnRb = {4'd0,isn[25:22]};
    default:  fnRb = {1'b1,vele,isn[25:22]};
    endcase
`endif
	default:
	   if (isn[`INSTRUCTION_RB]==6'd27)
	       fnRb = r27;
	   else	
	       fnRb = {1'b0,isn[`INSTRUCTION_RB]};
	endcase
endfunction

function [7:0] fnRc;
input [63:0] isn;
case(isn[15:8])
`VRR,`VMAC:
  fnRc = {1'b1,vele,isn[37:34]};
default:
  if (isn[39:34]==6'd27)
      fnRc = r27;
  else
      fnRc = {4'b0,isn[`INSTRUCTION_RC]};
endcase

endfunction

function [7:0] fnRd;
input [63:0] isn;
  fnRd = {1'b1,vele,isn[43:40]};
endfunction

function [3:0] fnCar;
input [63:0] isn;
	case(isn[15:8])
	`RTS2:  fnCar = 4'h1;
	`RTI:	fnCar = 4'hE;
	`RTD:   fnCar = 4'hB;
	`RTE:	fnCar = 4'hD;
	`JSR,`JSRS,`JSRZ,`SYS,`INT,`RTS:
		fnCar = {isn[23:20]};
	default:	fnCar = 4'h0;
	endcase
endfunction

function [5:0] fnFunc;
input [63:0] isn;
case(isn[15:8])
`BITFIELD:	fnFunc = isn[43:40];
`R:     fnFunc = isn[31:28];
`R2:    fnFunc = isn[31:28];
`DOUBLE_R:  fnFunc = isn[31:28];
`SINGLE_R:  fnFunc = isn[31:28];
8'h10:	fnFunc = isn[31:28];
8'h11:	fnFunc = isn[31:28];
8'h12:	fnFunc = isn[31:28];
8'h13:	fnFunc = isn[31:28];
8'h14:	fnFunc = isn[31:28];
8'h15:	fnFunc = isn[31:28];
8'h16:	fnFunc = isn[31:28];
8'h17:	fnFunc = isn[31:28];
8'h18:	fnFunc = isn[31:28];
8'h19:	fnFunc = isn[31:28];
8'h1A:	fnFunc = isn[31:28];
8'h1B:	fnFunc = isn[31:28];
8'h1C:	fnFunc = isn[31:28];
8'h1D:	fnFunc = isn[31:28];
8'h1E:	fnFunc = isn[31:28];
8'h1F:	fnFunc = isn[31:28];
8'h00:	fnFunc = isn[23:22];
8'h01:	fnFunc = isn[23:22];
8'h02:	fnFunc = isn[23:22];
8'h03:	fnFunc = isn[23:22];
8'h04:	fnFunc = isn[23:22];
8'h05:	fnFunc = isn[23:22];
8'h06:	fnFunc = isn[23:22];
8'h07:	fnFunc = isn[23:22];
8'h08:	fnFunc = isn[23:22];
8'h09:	fnFunc = isn[23:22];
8'h0A:	fnFunc = isn[23:22];
8'h0B:	fnFunc = isn[23:22];
8'h0C:	fnFunc = isn[23:22];
8'h0D:	fnFunc = isn[23:22];
8'h0E:	fnFunc = isn[23:22];
8'h0F:	fnFunc = isn[23:22];
`INC:   fnFunc = {isn[39:37],isn[24:22]};
`TLB:   fnFunc = isn[19:16];
`RTS:   fnFunc = isn[19:16];   // used to pass a small immediate
`CACHE: fnFunc = isn[31:26];
`PUSH,`PEA: fnFunc = km ? 6'b0 : 6'b110000; // select segment register #6
`JMPI:  fnFunc = {isn[39:37],1'b0,isn[27:26]};
`JMPIX: fnFunc = {isn[39:37],1'b0,isn[33:32]};
`MTSPR: fnFunc = isn[31:28];
`ifdef VECTOROPS
`VRR:   fnFunc = isn[47:43];
`VR:    fnFunc = isn[39:34];
`endif
default:
	fnFunc = isn[39:34];
endcase
endfunction

function fnVelv;
input [63:0] isn;
case(isn[15:8])
`VR:
  case(isn[39:34])
  6'd0: fnVelv = `FALSE;
  default: fnVelv = `TRUE;
  endcase
default: fnVelv = `TRUE;
endcase
endfunction

function fnVecL;
input [63:0] isn;
case(isn[15:8])
`VRR: fnVecL = isn[47];
`VR:  fnVecL = isn[39];
`VMAC: fnVecL = isn[55];
default: fnVecL = 1'b0;
endcase
endfunction

// Returns true if the operation is limited to ALU #0
function fnIsAlu0Op;
input [7:0] opcode;
input [5:0] func;
case(opcode)
`R:
    case(func)
    `CNTLZ,`CNTLO,`CNTPOP:  fnIsAlu0Op = `TRUE;
    `ABS,`SGN,`ZXB,`ZXC,`ZXH,`SXB,`SXC,`SXH:  fnIsAlu0Op = `TRUE;
    default:    fnIsAlu0Op = `FALSE;
    endcase
`R2:    fnIsAlu0Op = `TRUE;
`RR:
    case(func)
    `MUL,`MULU: fnIsAlu0Op = `TRUE;
    `DIV,`DIVU: fnIsAlu0Op = `TRUE;
    `MOD,`MODU: fnIsAlu0Op = `TRUE;
    `MIN,`MAX:  fnIsAlu0Op = `TRUE;
    default:    fnIsAlu0Op = `FALSE;
    endcase
`BCD:       fnIsAlu0Op = `TRUE;
`MULI,`MULUI:   fnIsAlu0Op = `TRUE;
`DIVI,`DIVUI:   fnIsAlu0Op = `TRUE;
`MODI,`MODUI:   fnIsAlu0Op = `TRUE;
//`DOUBLE:    fnIsAlu0Op = `TRUE;
`SHIFT:     fnIsAlu0Op = `TRUE;
`BITFIELD:  fnIsAlu0Op = `TRUE;
default:    fnIsAlu0Op = `FALSE;
endcase
endfunction

// Returns TRUE if the alu will be valid immediately
//
function fnAluValid;
input [7:0] opcode;
input [5:0] func;
case(opcode)
`R: fnAluValid = `TRUE;
`RR:
    case(func)
    `MUL,`MULU,`DIV,`DIVU,`MOD,`MODU: fnAluValid = `FALSE;
    default:    fnAluValid = `TRUE;
    endcase
`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI:   fnAluValid = `FALSE;
default:    fnAluValid = `TRUE;
endcase
endfunction

Thor_regfile2w6r #(DBW) urf1
(
	.clk(clk),
	.clk2x(clk2x_i),
	.rclk(~clk),
	.regset(regset[2:0]),
	.wr0(commit0_v && commit0_tgt[7:6]==2'h0),
	.wr1(commit1_v && commit1_tgt[7:6]==2'h0),
	.wa0(commit0_tgt[5:0]),
	.wa1(commit1_tgt[5:0]),
	.ra0(pRa0[5:0]),
	.ra1(pRb0[5:0]),
	.ra2(pRa1[5:0]),
	.ra3(pRb1[5:0]),
	.ra4(pRt0[5:0]),
	.ra5(pRt1[5:0]),
	.i0(commit0_bus),
	.i1(commit1_bus),
	.o0(prfoa0),
	.o1(prfob0),
	.o2(prfoa1),
	.o3(prfob1),
	.o4(prfot0),
	.o5(prfot1)
);

/* Too large
Thor_regfile2w6r #(DBW) urf1
(
	.clk(clk),
	.rclk(~clk),
	.wr0(commit0_v && commit0_tgt[7:6]==2'h0),
	.wr1(commit1_v && commit1_tgt[7:6]==2'h0),
	.wa0({regset[1:0],commit0_tgt[5:0]}),
	.wa1({regset[1:0],commit1_tgt[5:0]}),
	.ra0({regset[1:0],pRa0[5:0]}),
	.ra1({regset[1:0],pRb0[5:0]}),
	.ra2({regset[1:0],pRa1[5:0]}),
	.ra3({regset[1:0],pRb1[5:0]}),
	.ra4({regset[1:0],pRt0[5:0]}),
	.ra5({regset[1:0],pRt1[5:0]}),
	.i0(commit0_bus),
	.i1(commit1_bus),
	.o0(prfoa0),
	.o1(prfob0),
	.o2(prfoa1),
	.o3(prfob1),
	.o4(prfot0),
	.o5(prfot1)
);
*/
`ifdef VECTOROPS
Thor_vregfile2w6r #(DBW) uvrf1
(
	.clk(clk),
	.rclk(~clk),
	.wr0(commit0_v && commit0_tgt[7]),
	.wr1(commit1_v && commit1_tgt[7]),
	.wa0(commit0_tgt[6:0]),
	.wa1(commit1_tgt[6:0]),
	.ra0(pRb0[6:0]),
	.ra1(pRc0[6:0]),
	.ra2(pRd0[6:0]),
	.ra3(pRb1[6:0]),
	.ra4(pRc1[6:0]),
	.ra5(pRd1[6:0]),
	.ra6(pRt0[6:0]),
  .ra7(pRt1[6:0]),
	.i0(commit0_bus),
	.i1(commit1_bus),
	.o0(pvrfoa0),
	.o1(pvrfob0),
	.o2(pvrfoc0),
	.o3(pvrfoa1),
	.o4(pvrfob1),
	.o5(pvrfoc1),
	.o6(vrfot0),
  .o7(vrfot1)
);
`endif

wire [63:0] cregs0 = fnCar(fetchbuf0_instr)==4'd0 ? 64'd0 : fnCar(fetchbuf0_instr)==4'hF ? fetchbuf0_pc : cregs[fnCar(fetchbuf0_instr)];
wire [63:0] cregs1 = fnCar(fetchbuf1_instr)==4'd0 ? 64'd0 : fnCar(fetchbuf1_instr)==4'hF ? fetchbuf1_pc : cregs[fnCar(fetchbuf1_instr)];
//
// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource1_v;
input [7:0] opcode;
	case(opcode)
	`SEI,`CLI,`MEMSB,`MEMDB,`SYNC,`NOP,`STP,`RTF,`JSF:
					fnSource1_v = 1'b1;
	`LDI,`LDIS,`IMM:	fnSource1_v = 1'b1;
	`LDISEG,`LDISEG|1'b1:  fnSource1_v = 1'b1;
	default:
	   case(opcode[7:4])
       `BR:		fnSource1_v = 1'b1;
	   default:    fnSource1_v = 1'b0;
	   endcase
	endcase
endfunction

//
// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource2_v;
input [7:0] opcode;
input [5:0] func;
	case(opcode)
	`R,`P:		fnSource2_v = 1'b1;
	`LDI,`LDIS,`IMM,`NOP,`STP:		fnSource2_v = 1'b1;
	`LDISEG,`LDISEG|1'b1:  fnSource2_v = 1'b1;
	`SEI,`CLI,`MEMSB,`MEMDB,`SYNC:
					fnSource2_v = 1'b1;
	`RTI,`RTD,`RTE,`JMPI:	fnSource2_v = 1'b1;
	// TST
	8'h00:			fnSource2_v = 1'b1;
	8'h01:			fnSource2_v = 1'b1;
	8'h02:			fnSource2_v = 1'b1;
	8'h03:			fnSource2_v = 1'b1;
	8'h04:			fnSource2_v = 1'b1;
	8'h05:			fnSource2_v = 1'b1;
	8'h06:			fnSource2_v = 1'b1;
	8'h07:			fnSource2_v = 1'b1;
	8'h08:			fnSource2_v = 1'b1;
	8'h09:			fnSource2_v = 1'b1;
	8'h0A:			fnSource2_v = 1'b1;
	8'h0B:			fnSource2_v = 1'b1;
	8'h0C:			fnSource2_v = 1'b1;
	8'h0D:			fnSource2_v = 1'b1;
	8'h0E:			fnSource2_v = 1'b1;
	8'h0F:			fnSource2_v = 1'b1;
	`ADDI,`ADDUI,`ADDUIS:
	                fnSource2_v = 1'b1;
	`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI:
					fnSource2_v = 1'b1;
	`SUBI,`SUBUI:	fnSource2_v = 1'b1;
	// CMPI
	8'h20:			fnSource2_v = 1'b1;
	8'h21:			fnSource2_v = 1'b1;
	8'h22:			fnSource2_v = 1'b1;
	8'h23:			fnSource2_v = 1'b1;
	8'h24:			fnSource2_v = 1'b1;
	8'h25:			fnSource2_v = 1'b1;
	8'h26:			fnSource2_v = 1'b1;
	8'h27:			fnSource2_v = 1'b1;
	8'h28:			fnSource2_v = 1'b1;
	8'h29:			fnSource2_v = 1'b1;
	8'h2A:			fnSource2_v = 1'b1;
	8'h2B:			fnSource2_v = 1'b1;
	8'h2C:			fnSource2_v = 1'b1;
	8'h2D:			fnSource2_v = 1'b1;
	8'h2E:			fnSource2_v = 1'b1;
	8'h2F:			fnSource2_v = 1'b1;
	// BR
    8'h30:            fnSource2_v = 1'b1;
    8'h31:            fnSource2_v = 1'b1;
    8'h32:            fnSource2_v = 1'b1;
    8'h33:            fnSource2_v = 1'b1;
    8'h34:            fnSource2_v = 1'b1;
    8'h35:            fnSource2_v = 1'b1;
    8'h36:            fnSource2_v = 1'b1;
    8'h37:            fnSource2_v = 1'b1;
    8'h38:            fnSource2_v = 1'b1;
    8'h39:            fnSource2_v = 1'b1;
    8'h3A:            fnSource2_v = 1'b1;
    8'h3B:            fnSource2_v = 1'b1;
    8'h3C:            fnSource2_v = 1'b1;
    8'h3D:            fnSource2_v = 1'b1;
    8'h3E:            fnSource2_v = 1'b1;
    8'h3F:            fnSource2_v = 1'b1;
	`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI:
					fnSource2_v = 1'b1;
	`ANDI,`BITI:	fnSource2_v = 1'b1;
	`ORI:			fnSource2_v = 1'b1;
	`EORI:			fnSource2_v = 1'b1;
	`SHIFT:
	           if (func[5:4]==2'h1)
	               fnSource2_v = `TRUE;
	           else
	               fnSource2_v = `FALSE;
	`CACHE,`LCL,`TLB,`LLA,`LEA,
	`LVB,`LVC,`LVH,`LVW,`LVWAR,
	`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWS,`STI,`INC:
			fnSource2_v = 1'b1;
	`JSR,`JSRS,`JSRZ,`JSF,`SYS,`INT,`RTS,`RTS2,`RTF:
			fnSource2_v = 1'b1;
	`MTSPR,`MFSPR,`POP,`UNLINK:
				fnSource2_v = 1'b1;
	`BITFIELD:
	       if (func==`BFINS)
	           fnSource2_v = 1'b0;
	       else
	           fnSource2_v = 1'b1;
	`LOOP:      fnSource2_v = 1'b1;
	default:    fnSource2_v = 1'b0;
	endcase
endfunction


// Source #3 valid
// Since most instructions don't use a third source the default it to return 
// a valid status.
// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource3_v;
input [7:0] opcode;
input [5:0] func;
	case(opcode)
	`RR:
	   case(func)
	   `CHK,`CHKX:   fnSource3_v = 1'b0;
	   default:    fnSource3_v = 1'b1;
	   endcase
	`SBX,`SCX,`SHX,`SWX,`CAS,`STMV,`STCMP,`STFND:	fnSource3_v = 1'b0;
	`MUX:	fnSource3_v = 1'b0;
	default:	fnSource3_v = 1'b1;
	endcase
endfunction

// Source #4 valid
// Since most instructions don't use a fourth source the default it to return 
// a valid status.
// 1 if the the operand is automatically valid, 
// 0 if we need a RF value
function fnSource4_v;
input [7:0] opcode;
input [5:0] func;
	case(opcode)
	`VMAC: fnSource4_v = 1'b0;
	default:	fnSource4_v = 1'b1;
	endcase
endfunction

function fnSourceT_v;
input [7:0] opcode;
input [5:0] func;
    case(opcode)
    `RR:
        case(func)
        `CHK,`CHKX:   fnSourceT_v = 1'b1;
        default:    fnSourceT_v = 1'b0;
        endcase
    // BR
    8'h30,8'h31,8'h32,8'h33,
    8'h34,8'h35,8'h36,8'h37,
    8'h38,8'h39,8'h3A,8'h3B,
    8'h3C,8'h3D,8'h3E,8'h3F,
    `SB,`SC,`SH,`SW,`SBX,`SCX,`SHX,`SWX,`SWS,`SV,`SVWS,`SVX,
    `CACHE,`CHKI,`CHKXI,
    `SEI,`CLI,`NOP,`STP,`RTI,`RTD,`RTE,
    `MEMSB,`MEMDB,`SYNC:
            fnSourceT_v = 1'b1;
    default:    fnSourceT_v = 1'b0;
    endcase
endfunction

// Return the number of register read ports required for an instruction.
function [2:0] fnNumReadPorts;
input [63:0] ins;
case(fnOpcode(ins))
`SEI,`CLI,`MEMSB,`MEMDB,`SYNC,`NOP,`MOVS,`STP:
					fnNumReadPorts = 3'd0;
`LDI,`LDIS,`IMM:		fnNumReadPorts = 3'd0;
`LDISEG,`LDISEG|1'b1:  fnNumReadPorts = 3'd0;
`R,`P,`STI,`LOOP,`JMPI:   fnNumReadPorts = 3'd1;
`RTI,`RTD,`RTE,`RTF,`JSF:		fnNumReadPorts = 3'd1;
`ADDI,`ADDUI,`ADDUIS:
                    fnNumReadPorts = 3'd1;
`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI:
					fnNumReadPorts = 3'd1;
`SUBI,`SUBUI:		fnNumReadPorts = 3'd1;
`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI:
					fnNumReadPorts = 3'd1;
`BITI,
`ANDI,`ORI,`EORI:	fnNumReadPorts = 3'd1;
`SHIFT:
                    if (ins[39:38]==2'h1)   // shift immediate
					   fnNumReadPorts = 3'd1;
					else
					   fnNumReadPorts = 3'd2;
`CACHE,`LCL,`TLB,`LLA,`LEA,					 
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LVB,`LVC,`LVH,`LVW,`LVWAR,`LWS,`INC:
					fnNumReadPorts = 3'd1;
`JSR,`JSRS,`JSRZ,`SYS,`INT,`RTS,`RTS2,`BR:
					fnNumReadPorts = 3'd1;
`SBX,`SCX,`SHX,`SWX,
`MUX,`CAS,`STMV,`STCMP:
					fnNumReadPorts = 3'd3;
`MTSPR,`MFSPR,`POP,`UNLINK:	fnNumReadPorts = 3'd1;
`STFND:	   fnNumReadPorts = 3'd2;	// *** TLB reads on Rb we say 2 for simplicity
`RR:
    case(ins[39:34])
    `CHK,`CHKX:   fnNumReadPorts = 3'd3;
    default:    fnNumReadPorts = 3'd2;
    endcase
`BITFIELD:
    case(ins[43:40])
    `BFSET,`BFCLR,`BFCHG,`BFEXT,`BFEXTU,`BFINSI:
					fnNumReadPorts = 3'd1;
    `BFINS:         fnNumReadPorts = 3'd2;
    default:        fnNumReadPorts = 3'd0;
    endcase
default:
    case(ins[15:12])
    `TST:			fnNumReadPorts = 3'd1;
    `CMPI:			fnNumReadPorts = 3'd1;
    `CMP:			fnNumReadPorts = 3'd2;
    `BR:            fnNumReadPorts = 3'd0;
    default:        fnNumReadPorts = 3'd2;
    endcase
endcase
endfunction

function fnIsBranch;
input [7:0] opcode;
case(opcode[7:4])
`BR:	fnIsBranch = `TRUE;
default:	fnIsBranch = `FALSE;
endcase
endfunction

function fnIsPush;
input [63:0] isn;
fnIsPush = isn[15:8]==`PUSH || isn[15:8]==`PEA;
endfunction

function fnIsPop;
input [63:0] isn;
fnIsPop = isn[15:8]==`POP;
endfunction

function fnIsStoreString;
input [7:0] opcode;
fnIsStoreString =
	opcode==`STS;
endfunction

reg [DBW-1:0] branch_pc;
wire xbr = iqentry_br[head0] | iqentry_br[head1];
wire takb = iqentry_br[head0] ? commit0_v : commit1_v;
wire [DBW-1:0] xbrpc = iqentry_br[head0] ? iqentry_pc[head0] : iqentry_pc[head1];

wire predict_taken0;
wire predict_taken1;

// This is really just a single history table with three read ports.
// One for fetchbuf0, one for fetchbuf1 and one for the branch_pc.
// Ideally, there really needs to be two write ports as well (for
// head0 and head1).
// There is only a single write port for branches committing at
// head0 or head1. If there are two branches one after the other
// in code, then the prediction will be off because the taken/
// not taken status for the second branch won't be updated. It
// doesn't happen that often that branches are piled together and
// executing during the same clock cycle.
// There's usually at least an intervening compare operation.
// Needs more work yet.
//
// ToDo: add return address stack predictor.
//
Thor_BranchHistory #(DBW) ubhtA
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(xbr),
	.xisBranch(xbr),
	.pc(branch_pc),
	.xpc(xbrpc),
	.takb(takb),
	.predict_taken(predict_takenBr)
);

Thor_BranchHistory #(DBW) ubhtB
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(xbr),
	.xisBranch(xbr),
	.pc(fetchbuf0_pc),
	.xpc(xbrpc),
	.takb(takb),
	.predict_taken(predict_taken0)
);

Thor_BranchHistory #(DBW) ubhtC
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(xbr),
	.xisBranch(xbr),
	.pc(fetchbuf1_pc),
	.xpc(xbrpc),
	.takb(takb),
	.predict_taken(predict_taken1)
);

/*
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
*/
`ifdef PCHIST
wire [63:0] pc_histo;
reg pc_cap;
reg [5:0] pc_ndx;

vtdl #(.WID(64),.DEP(64)) uvtl1
(
    .clk(clk),
    .ce(pc_cap),
    .a(pc_ndx),
    .d({fetchbuf1_pc,fetcbuf0_pc}),
    .q(pc_histo)
);
`endif

Thor_icachemem #(.DBW(DBW),.ABW(ABW),.ECC(1'b0)) uicm1
(
	.wclk(clk),
	.wce(cstate==ICACHE1),
	.wr(ack_i|err_i),
	.wa(adr_o),
	.wd(dat_i),
	.rclk(~clk),
	.pc(ppc),
	.insn(insn)
);

wire hit0,hit1;
reg idblmiss;
reg [5:0] iccntr;

reg ic_ld;
reg [31:0] ic_ld_cntr;
Thor_itagmem #(DBW-1) uitm1
(
	.wclk(clk),
	.wce((cstate==ICACHE1 && cti_o==3'b111)|ic_ld),
	.wr(ack_i|err_i|ic_ld),
	.wa(adr_o|ic_ld_cntr),
	.err_i(err_i|ierr),
	.invalidate(ic_invalidate),
	.invalidate_line(ic_invalidate_line),
	.invalidate_lineno(ic_lineno),
	.rclk(~clk),
	.rce(1'b1),
	.pc(ppc),
	.hit0(hit0),
	.hit1(hit1),
	.err_o(insnerr)
);

wire ihit = hit0 & hit1;
wire do_pcinc = ihit;// && !((nmi_edge & ~StatusHWI & ~int_commit) || (irq_i & ~im & ~StatusHWI & ~int_commit));
wire ld_fetchbuf = ihit || (nmi_edge & !StatusHWI)||(irq_i & ~im & !StatusHWI);

wire whit;

Thor_dcachemem_1w1r #(DBW) udcm1
(
	.wclk(clk),
	.wce((whit & we_o) || cstate==DCACHE1),
	.wr(ack_i|err_i),
	.sel((whit & we_o) ? sel_o : 8'hFF),
	.wa(adr_o),
	.wd((whit & we_o) ? dat_o : dat_i[DBW-1:0]),
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
	.invalidate(dc_invalidate),
	.invalidate_line(dc_invalidate_line),
    .invalidate_lineno(dc_lineno),
	.rclk(~clk),
	.rce(1'b1),
	.ra(pea),
	.whit(whit),
	.rhit(rhit),
	.err_o()
);

`ifdef COMPRESSED_INSN
wire [31:0] hinsn0, hinsn1;
wire hl_ce = cyc_o && stb_o && we_o && adr_o[31:14]==18'h3FFFF;
Thor_hLookupTbl uhm1
(
    .wclk(clk),
    .wr(h1_ce),
    .wadr(adr_o[13:2]),
    .wdata(dat_o),
    .rclk(~clk),
    .radr0({insn[23:16],insn[11:8]}),
    .rdata0(hinsn0),
    .radr1({insn1a[23:16],insn1a[11:8]}),
    .rdata1(hinsn1)
);
`endif

wire [DBW-1:0] shfto0,shfto1;

function fnIsShiftiop;
input [63:0] isn;
fnIsShiftiop =  isn[15:8]==`SHIFT && isn[39:38]==2'b1;
//(
//                isn[39:34]==`SHLI || isn[39:34]==`SHLUI ||
//				isn[39:34]==`SHRI || isn[39:34]==`SHRUI ||
//				isn[39:34]==`ROLI || isn[39:34]==`RORI
//				)
//				;
endfunction

function fnIsFP;
input [7:0] opcode;
fnIsFP = 	opcode==`DOUBLE_R||opcode==`FLOAT||opcode==`SINGLE_R;
//            opcode==`ITOF || opcode==`FTOI || opcode==`FNEG || opcode==`FSIGN || /*opcode==`FCMP || */ opcode==`FABS ||
//			opcode==`FADD || opcode==`FSUB || opcode==`FMUL || opcode==`FDIV
//			;
endfunction

function fnIsFPCtrl;
input [63:0] isn;
fnIsFPCtrl = (isn[15:8]==`SINGLE_R && (isn[31:28]==`FTX||isn[31:28]==`FCX||isn[31:28]==`FDX||isn[31:28]==`FEX)) ||
             (isn[15:8]==`DOUBLE_R && (isn[31:28]==`FRM))
             ;
endfunction

function fnIsBitfield;
input [7:0] opcode;
fnIsBitfield = opcode==`BITFIELD;
endfunction

//wire [3:0] Pn = ir[7:4];

// Set the target register
// 00-3F = general register file
// 40-4F = predicate register
// 50-5F = code address register
// 60-67 = segment base register
// 68-6F = segment limit register
// 70 = predicate register horizontal
// 73 = loop counter
// 7C = breakout index register
// 7D = broken out register
// 7F = power shift register
// 80 vector reg #0, element #0
// 81 vector reg #1, element #0
// ...
// 8F vector reg #15, element #0
// 90 vector reg #0, element #1
// ...
// FF vector reg #15, element #7

function [7:0] fnTargetReg;
input [63:0] ir;
begin
    // Process special predicates (NOP, IMM)
    // Note that BRK (00) is already translated to a SYS instruction
	if (ir[3:0]==4'h0)
		fnTargetReg = 10'h000;
	else
		case(fnOpcode(ir))
`ifdef VECTOROPS
		`VR:
		  case(ir[39:34])
		  `VEX:	  fnTargetReg = {5'h0,ir[30:28]};
		  default:	  fnTargetReg = {1'b1,vele,ir[30:28]};
		  endcase
		`LV:  fnTargetReg = {1'b1,vele,ir[24:22]};
		`LVWS,`LVX: fnTargetReg = {1'b1,vele,ir[30:28]};
		`VLOG,`VADDSUB,`VMULDIV:  fnTargetReg = {1'b1,vele,ir[30:28]};
// ToDo: assign register range for vector predicates
//		`VCMPS:
		`VMAC:  fnTargetReg = {1'b1,vele,ir[43:40]};
`endif
		`POP: fnTargetReg = ir[22:16];
		`LDI,`ADDUIS,`STS,`LINK,`UNLINK,
		`LDISEG,`LDISEG|1'b1:
		    if (ir[21:16]==6'd27)
		        fnTargetReg = r27;
		    else
			    fnTargetReg = {4'b0,ir[21:16]};
		`LDIS:
			fnTargetReg = {4'd1,ir[21:16]};
		`RR,
		`SHIFT,
		`BCD,
        `LOGIC,`FLOAT,`LEAX,
        `LWX,`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`STMV,`STCMP,`STFND:
		    if (ir[33:28]==6'd27)
		        fnTargetReg = r27;
		    else
			    fnTargetReg = {4'b0,ir[33:28]};
		`R,`R2,`DOUBLE_R,`SINGLE_R,
		`ADDI,`ADDUI,`SUBI,`SUBUI,
		`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI,
		`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI,
		`ANDI,`ORI,`EORI,`LLA,`LEA,
		`LVB,`LVC,`LVH,`LVW,`LVWAR,
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LINK,
		`BITFIELD,`MFSPR:
		    if (ir[27:22]==6'd27)
		        fnTargetReg = r27;
		    else
			    fnTargetReg = {4'b0,ir[27:22]};
		`CAS:
			fnTargetReg = {4'b0,ir[39:34]};
		`TLB:
			if (ir[19:16]==`TLB_RDREG)
				fnTargetReg = {4'b0,ir[29:24]};
			else
				fnTargetReg = 10'h00;
		`BITI:
		      fnTargetReg = {6'h4,ir[25:22]};
		`CHKI:
              fnTargetReg = {6'h4,ir[43:40]};
		// TST
		8'h00,8'h01,8'h02,8'h03,
		8'h04,8'h05,8'h06,8'h07,
		8'h08,8'h09,8'h0A,8'h0B,
		8'h0C,8'h0D,8'h0E,8'h0F,
		// CMP
		8'h10,8'h11,8'h12,8'h13,
        8'h14,8'h15,8'h16,8'h17,
        8'h18,8'h19,8'h1A,8'h1B,
        8'h1C,8'h1D,8'h1E,8'h1F,
		// CMPI
        8'h20,8'h21,8'h22,8'h23,
        8'h24,8'h25,8'h26,8'h27,
        8'h28,8'h29,8'h2A,8'h2B,
        8'h2C,8'h2D,8'h2E,8'h2F:
		    begin
			fnTargetReg = {6'h4,ir[11:8]};
			end
		`SWCR:    fnTargetReg = {6'h4,4'h0};
		`JSR,`JSRZ,`JSRS,`SYS,`INT:
			fnTargetReg = {4'h5,ir[19:16]};
		`JSF: fnTargetReg = 8'h51;
		`JMPI:
		    fnTargetReg = {4'h5,ir[25:22]};
		`JMPIX:
		    fnTargetReg = {4'h5,ir[31:28]};
		`MTSPR,`MOVS,`LWS:
		    if (ir[27:22]==`USP)
		        fnTargetReg = {4'b0,6'd27};
		    else
		        fnTargetReg = {4'd1,ir[27:22]};
/*
			if (ir[27:26]==2'h1)		// Move to code address register
				fnTargetReg = {3'h5,ir[25:22]};
			else if (ir[27:26]==2'h2)	// Move to seg. reg.
				fnTargetReg = {3'h6,ir[25:22]};
			else if (ir[27:22]==6'h04)
				fnTargetReg = 7'h70;
			else
				fnTargetReg = 7'h00;
*/      
        `PUSH:      fnTargetReg = r27;
        `LOOP:      fnTargetReg = 10'h73;
        `STP:       fnTargetReg = 10'h7F;
        `P:         fnTargetReg = 10'h70;
		default:	fnTargetReg = 10'h00;
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
	`JSR,`JSRZ,`JSRS,`JSF,`SYS,`INT:
	       fnTargetsCa = `TRUE;
	`JMPI,`JMPIX:
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
		if (ir[27:25]==3'h4)
			fnTargetsSegreg = `TRUE;
		else
			fnTargetsSegreg = `FALSE;
	`LDIS:
		if (ir[21:19]==3'h4)
			fnTargetsSegreg = `TRUE;
		else
			fnTargetsSegreg = `FALSE;
	`MTSPR,`MOVS:
		if (ir[27:25]==3'h4)
			fnTargetsSegreg = `TRUE;
		else
			fnTargetsSegreg = `FALSE;
	default:	fnTargetsSegreg = `FALSE;
	endcase
endfunction

function fnHasConst;
input [7:0] opcode;
	case(opcode)
	`BFCLR,`BFSET,`BFCHG,`BFEXT,`BFEXTU,`BFINS,
	`LDI,`LDIS,`ADDUIS,`LDISEG,`LDISEG|1'b1,
	`ADDI,`SUBI,`ADDUI,`SUBUI,`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI,
	`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI,`CHKI,`CHKXI,
	// CMPI
	8'h20,8'h21,8'h22,8'h23,
	8'h24,8'h25,8'h26,8'h27,
	8'h28,8'h29,8'h2A,8'h2B,
	8'h2C,8'h2D,8'h2E,8'h2F,
	// BR
    8'h30,8'h31,8'h32,8'h33,
    8'h34,8'h35,8'h36,8'h37,
    8'h38,8'h39,8'h3A,8'h3B,
    8'h3C,8'h3D,8'h3E,8'h3F,
	`ANDI,`ORI,`EORI,`BITI,
//	`SHLI,`SHLUI,`SHRI,`SHRUI,`ROLI,`RORI,
	`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWS,`INC,
	`LVB,`LVC,`LVH,`LVW,`LVWAR,`STI,`JMPI,
	`SB,`SC,`SH,`SW,`SWCR,`CAS,`SWS,
	`RTI,`RTD,`RTE,`RTF,`JSF,`LLA,`LEA,
	`JSR,`JSRS,`SYS,`INT,`LOOP,`PEA,`LINK,`UNLINK:
		fnHasConst = 1'b1;
	default:
		fnHasConst = 1'b0;
	endcase
endfunction

// Used by memory issue logic.
function fnIsFlowCtrl;
input [7:0] opcode;
begin
case(opcode)
`JMPI,`JMPIX,
`JSR,`JSRS,`JSRZ,`JSF,`SYS,`INT,`LOOP,`RTS,`RTF,`RTS2,`RTI,`RTD,`RTE:
	fnIsFlowCtrl = 1'b1;
default:
    if (opcode[7:4]==`BR)
        fnIsFlowCtrl = 1'b1;
    else
        fnIsFlowCtrl = 1'b0;
endcase
end
endfunction

// fnCanException
//
// Used by memory issue logic.
// Returns TRUE if the instruction can cause an exception.
// In debug mode any instruction could potentially cause a breakpoint exception.
// Rather than check all the addresses for potential debug exceptions it's
// simpler to just have it so that all instructions could exception. This will
// slow processing down somewhat as stores will only be done at the head of the
// instruction queue, but it's debug mode so we probably don't care.
//
function fnCanException;
input [7:0] op;
input [5:0] func;
if (debug_on)
    fnCanException = `TRUE;
else
case(op)
`FLOAT:
    case(func)
    `FDIVS,`FMULS,`FADDS,`FSUBS,
    `FDIV,`FMUL,`FADD,`FSUB:
        fnCanException = `TRUE;
    default:    fnCanException = `FALSE;
    endcase
`SINGLE_R:
    if (func==`FTX) fnCanException = `TRUE;
    else fnCanException = `FALSE;
`ADDI,`SUBI,`DIVI,`MODI,`MULI,`CHKXI:
    fnCanException = `TRUE;
`RR:
    if (func==`ADD || func==`SUB || func==`MUL || func==`DIV || func==`MOD || func==`CHKX)
        fnCanException = `TRUE;
    else
        fnCanException = `FALSE;
`TLB,`RTI,`RTD,`RTE,`CLI,`SEI:
    fnCanException = `TRUE;
default:
    fnCanException = fnIsMem(op);
endcase
endfunction

// fnInsnLength
// Used by fetch logic.
// Return the length of an instruction.
//
function [3:0] fnInsnLength;
input [127:0] isn;
case(isn[7:0])
8'b00000000:	fnInsnLength = 4'd1;	// BRK
8'b00010000:	fnInsnLength = 4'd1;	// NOP
8'b00100000:	fnInsnLength = 4'd2;
8'b00110000:	fnInsnLength = 4'd3;
8'b01000000:	fnInsnLength = 4'd4;
8'b01010000:	fnInsnLength = 4'd5;
8'b01100000:	fnInsnLength = 4'd6;
8'b01110000:	fnInsnLength = 4'd7;
8'b10000000:	fnInsnLength = 4'd8;
default:
	case(isn[15:8])
	`NOP,`SEI,`CLI,`RTI,`RTD,`RTE,`RTS2,`RTF,`JSF,`MEMSB,`MEMDB,`SYNC:
		fnInsnLength = 4'd2;
	`JSRZ,`RTS,`CACHE,`LOOP,`PUSH,`POP,`UNLINK:
		fnInsnLength = 4'd3;
	`SYS,`MTSPR,`MFSPR,`LDI,`LDIS,`LDISEG,`LDISEG|1'b1,`ADDUIS,`R,`TLB,`MOVS,`STP:
		fnInsnLength = 4'd4;
	`BITFIELD,`JSR,`MUX,`BCD,`INC:
		fnInsnLength = 4'd6;
	`CAS,`CHKI:
		fnInsnLength = 4'd6;
`ifdef VECTOROPS
  `LV,`SV: fnInsnLength = 4'd4;
  `VMAC:  fnInsnLength = 4'd6;
  // Others are default 5
`endif
	default:
	   begin
	    case(isn[15:12])
	    4'hE:     fnInsnLength = 4'd3;
	    `TST:     fnInsnLength = 4'd3;
	    `BR:      fnInsnLength = 4'd3;
	    `CMP,`CMPI:    fnInsnLength = 4'd4;
	    default:       fnInsnLength = 4'd5;
	    endcase
	    end
	endcase
endcase
endfunction

function [3:0] fnInsnLength1;
input [127:0] isn;
case(fnInsnLength(isn))
4'd1:	fnInsnLength1 = fnInsnLength(isn[127: 8]);
4'd2:	fnInsnLength1 = fnInsnLength(isn[127:16]);
4'd3:	fnInsnLength1 = fnInsnLength(isn[127:24]);
4'd4:	fnInsnLength1 = fnInsnLength(isn[127:32]);
4'd5:	fnInsnLength1 = fnInsnLength(isn[127:40]);
4'd6:	fnInsnLength1 = fnInsnLength(isn[127:48]);
4'd7:	fnInsnLength1 = fnInsnLength(isn[127:56]);
4'd8:	fnInsnLength1 = fnInsnLength(isn[127:64]);
default:	fnInsnLength1 = 4'd0;
endcase
endfunction

function [3:0] fnInsnLength2;
input [127:0] isn;
case(fnInsnLength(isn)+fnInsnLength1(isn))
4'd2:	fnInsnLength2 = fnInsnLength(isn[127:16]);
4'd3:	fnInsnLength2 = fnInsnLength(isn[127:24]);
4'd4:	fnInsnLength2 = fnInsnLength(isn[127:32]);
4'd5:	fnInsnLength2 = fnInsnLength(isn[127:40]);
4'd6:	fnInsnLength2 = fnInsnLength(isn[127:48]);
4'd7:	fnInsnLength2 = fnInsnLength(isn[127:56]);
4'd8:	fnInsnLength2 = fnInsnLength(isn[127:64]);
4'd9:	fnInsnLength2 = fnInsnLength(isn[127:72]);
4'd10:	fnInsnLength2 = fnInsnLength(isn[127:80]);
4'd11:	fnInsnLength2 = fnInsnLength(isn[127:88]);
4'd12:	fnInsnLength2 = fnInsnLength(isn[127:96]);
4'd13:	fnInsnLength2 = fnInsnLength(isn[127:104]);
4'd14:	fnInsnLength2 = fnInsnLength(isn[127:112]);
4'd15:	fnInsnLength2 = fnInsnLength(isn[127:120]);
default:	fnInsnLength2 = 4'd0;
endcase
endfunction

wire [5:0] total_insn_length = fnInsnLength(insn) + fnInsnLength1(insn) + fnInsnLength2(insn);
wire [5:0] insn_length12 = fnInsnLength(insn) + fnInsnLength1(insn);
wire insn3_will_fit = total_insn_length < 6'd16;

always @(fetchbuf or fetchbufA_instr or fetchbufA_v or fetchbufA_pc
 or fetchbufB_instr or fetchbufB_v or fetchbufB_pc
 or fetchbufC_instr or fetchbufC_v or fetchbufC_pc
 or fetchbufD_instr or fetchbufD_v or fetchbufD_pc
 or int_pending or string_pc
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

wire [7:0] opcodeA = fnOpcode(fetchbufA_instr);
wire [7:0] opcodeB = fnOpcode(fetchbufB_instr);
wire [7:0] opcodeC = fnOpcode(fetchbufC_instr);
wire [7:0] opcodeD = fnOpcode(fetchbufD_instr);

function fnIsMem;
input [7:0] opcode;
fnIsMem = 	opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW || 
			opcode==`LBX || opcode==`LWX || opcode==`LBUX || opcode==`LHX || opcode==`LHUX || opcode==`LCX || opcode==`LCUX ||
			opcode==`SB || opcode==`SC || opcode==`SH || opcode==`SW ||
			opcode==`SBX || opcode==`SCX || opcode==`SHX || opcode==`SWX ||
`ifdef VECTOROPS
			opcode==`LV || opcode==`LVWS || opcode==`LVX ||
			opcode==`SV || opcode==`SVWS || opcode==`SVX ||
`endif
			opcode==`STS || opcode==`LCL ||
			opcode==`LVB || opcode==`LVC || opcode==`LVH || opcode==`LVW || opcode==`LVWAR || opcode==`SWCR ||
			opcode==`TLB || opcode==`CAS || opcode==`STMV || opcode==`STCMP || opcode==`STFND ||
			opcode==`LWS || opcode==`SWS || opcode==`STI ||
			opcode==`INC ||
			opcode==`JMPI || opcode==`JMPIX ||
			opcode==`LLA || opcode==`LLAX ||
			opcode==`PUSH || opcode==`POP || opcode==`PEA || opcode==`LINK || opcode==`UNLINK
			;
endfunction

function fnIsVec;
input [7:0] opcode;
`ifdef VECTOROPS
fnIsVec = opcode==`VMAC || opcode==`VR || opcode==`VRR;// || opcode==`VLD || opcode==`VLDX || opcode==`VST || opcode==`VSTX;
`else
fnIsVec = `FALSE;
`endif
endfunction

// Determines which instruction write to the register file
function fnIsRFW;
input [7:0] opcode;
input [63:0] ir;
begin
fnIsRFW =	// General registers
			opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW ||
			opcode==`LBX || opcode==`LBUX || opcode==`LCX || opcode==`LCUX || opcode==`LHX || opcode==`LHUX || opcode==`LWX ||
			opcode==`LVB || opcode==`LVH || opcode==`LVC || opcode==`LVW || opcode==`LVWAR || opcode==`SWCR ||
			opcode==`STP || opcode==`LLA || opcode==`LLAX || opcode==`LEA || opcode==`LEAX ||
			opcode==`CAS || opcode==`LWS || opcode==`STMV || opcode==`STCMP || opcode==`STFND ||
			opcode==`STS || opcode==`PUSH || opcode==`POP || opcode==`LINK || opcode==`UNLINK ||
			opcode==`JMPI || opcode==`JMPIX ||
			opcode==`ADDI || opcode==`SUBI || opcode==`ADDUI || opcode==`SUBUI ||
			opcode==`MULI || opcode==`MULUI || opcode==`DIVI || opcode==`DIVUI || opcode==`MODI || opcode==`MODUI ||
			opcode==`_2ADDUI || opcode==`_4ADDUI || opcode==`_8ADDUI || opcode==`_16ADDUI ||
			opcode==`ANDI || opcode==`ORI || opcode==`EORI ||
			opcode==`SHIFT || opcode==`LOGIC ||
			opcode==`R || opcode==`R2 || (opcode==`RR && (ir[39:34]!=`CHKX)) || opcode==`LOOP ||
			opcode==`CHKI || opcode==`CMP || opcode==`CMPI || opcode==`TST ||
			opcode==`LDI || opcode==`LDIS || opcode==`ADDUIS || opcode==`MFSPR ||
			opcode==`LDISEG || opcode==(`LDISEG|1'b1) ||
`ifdef VECTOROPS
			opcode==`LV || opcode==`LVWS || opcode==`LVX ||
			opcode==`VLOG || opcode==`VADDSUB | opcode==`VCMPS || opcode==`VMULDIV ||
			opcode==`VMAC || opcode==`VR ||
`endif
`ifdef FLOATING_POINT
			opcode==`DOUBLE_R || opcode==`FLOAT_RR || opcode==`SINGLE_R ||
`endif
			// Branch registers / Segment registers
			((opcode==`MTSPR || opcode==`MOVS) /*&& (fnTargetsCa(ir) || fnTargetsSegreg(ir))*/) ||
			opcode==`JSR || opcode==`JSRS || opcode==`JSRZ || opcode==`JSF || opcode==`SYS || opcode==`INT ||
			// predicate registers
			(opcode[7:4] < 4'h3) || opcode==`P || opcode==`BITI || 
			(opcode==`TLB && ir[19:16]==`TLB_RDREG) ||
			opcode==`BCD 
			;
end
endfunction

function fnIsStore;
input [7:0] opcode;
fnIsStore = 	opcode==`SB || opcode==`SC || opcode==`SH || opcode==`SW ||
				opcode==`SBX || opcode==`SCX || opcode==`SHX || opcode==`SWX ||
				opcode==`STS || opcode==`SWCR ||
				opcode==`SWS || opcode==`STI ||
				opcode==`SV || opcode==`SVWS || opcode==`SVX ||
				opcode==`PUSH || opcode==`PEA || opcode==`LINK; 
endfunction

function fnIsLoad;
input [7:0] opcode;
fnIsLoad =	opcode==`LB || opcode==`LBU || opcode==`LC || opcode==`LCU || opcode==`LH || opcode==`LHU || opcode==`LW || 
			opcode==`LBX || opcode==`LBUX || opcode==`LCX || opcode==`LCUX || opcode==`LHX || opcode==`LHUX || opcode==`LWX ||
			opcode==`LVB || opcode==`LVC || opcode==`LVH || opcode==`LVW || opcode==`LVWAR || opcode==`LCL ||
			opcode==`LWS || opcode==`UNLINK || opcode==`JMPI || opcode==`JMPIX ||
			opcode==`LV || opcode==`LVWS || opcode==`LVX ||
			opcode==`POP;
endfunction

function fnIsLoadV;
input [7:0] opcode;
fnIsLoadV = opcode==`LVB || opcode==`LVC || opcode==`LVH || opcode==`LVW || opcode==`LVWAR || opcode==`LCL ||
            opcode==`LV || opcode==`LVWS || opcode==`LVX;
endfunction

function fnIsIndexed;
input [7:0] opcode;
fnIsIndexed = opcode==`LBX || opcode==`LBUX || opcode==`LCX || opcode==`LCUX || opcode==`LHX || opcode==`LHUX || opcode==`LWX ||
        opcode==`LVX || opcode==`SVX ||
				opcode==`SBX || opcode==`SCX || opcode==`SHX || opcode==`SWX || opcode==`JMPIX;
endfunction

// 
function fnIsPFW;
input [7:0] opcode;
fnIsPFW =	opcode[7:4]<4'h3 || opcode==`BITI || opcode==`P;//opcode==`CMP || opcode==`CMPI || opcode==`TST;
endfunction

// Decoding for illegal opcodes
function fnIsIllegal;
input [7:0] op;
input [5:0] fn;
if (`TRUE)
fnIsIllegal = `FALSE;
else
casex(op)
8'h40:
    if (fn > 6'h17)
        fnIsIllegal = `TRUE;
    else if (fn==6'hC || fn==6'hD || fn==6'hE || fn==6'hF || fn==6'h12 || fn==6'h16)
        fnIsIllegal = `TRUE; 
    else fnIsIllegal = `FALSE;
8'h41:
    if (fn > 6'd3)  fnIsIllegal = `TRUE;
    else fnIsIllegal = `FALSE;
8'h42:
    if (fn > 6'd7)  fnIsIllegal = `TRUE;
    else fnIsIllegal = `FALSE;
8'h50:
    if (fn > 6'd7)  fnIsIllegal = `TRUE;
    else fnIsIllegal = `FALSE;
8'h58:
    if (fn > 6'h15 || (fn > 6'h5 && fn < 6'h10))
        fnIsIllegal = `TRUE; 
    else
        fnIsIllegal = `FALSE;
8'h77:
    if (fn==8'h99 || fn==8'h9A || fn==8'h9B || fn==8'h9E || fn==8'h9F)
        fnIsIllegal = `TRUE; 
    else 
        fnIsIllegal = `FALSE;
8'h78:
    if ((fn >= 8'h07 && fn <= 8'h0B) || (fn >= 8'h17 && fn <= 8'h1B))
        fnIsIllegal = `FALSE; 
    else
        fnIsIllegal = `TRUE;
8'h79:
    if (fn==8'h99 || fn==8'h9A || fn==8'h9B)
        fnIsIllegal = `TRUE; 
    else 
        fnIsIllegal = `FALSE;
8'hAA:
    if (fn > 4'd6)
        fnIsIllegal = `TRUE; 
    else 
        fnIsIllegal = `FALSE;
8'hF5:
    if (fn > 4'd2)
        fnIsIllegal = `TRUE; 
    else 
        fnIsIllegal = `FALSE;
8'h43,8'h44:  fnIsIllegal = `TRUE;
`ifndef VECTOROPS
8'h52,8'h56,8'h57,8'h5A,8'h5C,8'h5E,8'hCD,8'hCE,8'hCF,8'hBD,8'hBE,8'hBF:
    fnIsIllegal = `TRUE;
`endif
8'h59:
    fnIsIllegal = `TRUE;
8'h60,8'h61,8'h62,8'h63,8'h64,8'h65,8'h66,8'h67:
    fnIsIllegal = `TRUE;
8'h73,8'h74,8'h75,8'h76,8'h7A,8'h7B,8'h7C,8'h7D:
    fnIsIllegal = `TRUE;
8'h87,8'h88,8'h8A:
    fnIsIllegal = `TRUE;
8'h94,8'h95,8'h9C:
    fnIsIllegal = `TRUE;
8'hBA,8'hBB,8'hBC:
    fnIsIllegal = `TRUE;
8'hC8,8'hC9,8'hCA,8'hCB,8'hCD:
    fnIsIllegal = `TRUE;
8'hDx:  fnIsIllegal = `TRUE;
8'hEx:  fnIsIllegal = `TRUE;
8'hFD,8'hFE:    fnIsIllegal = `TRUE;
default:    fnIsIllegal = `FALSE;
endcase
endfunction


function [7:0] fnSelect;
input [7:0] opcode;
input [5:0] fn;
input [DBW-1:0] adr;
begin
if (DBW==32)
	case(opcode)
	`STS,`STMV,`STCMP,`STFND,`INC:
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
    `JMPI,`JMPIX:
        case(fn[1:0])
        2'd1:
            case(adr[1]) 
            1'b0:   fnSelect = 8'h33;
            1'b1:   fnSelect = 8'hCC;
            endcase
        2'd2:   fnSelect = 8'hFF;
        2'd3:   fnSelect = 8'hFF;
        default:    fnSelect = 8'h00;
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
	`LW,`LWX,`SW,`SWCR,`LVW,`LVWAR,`SWX,`CAS,`LWS,`SWS,`STI,`LCL,
	`LV,`LVWS,`LVX,`SV,`SVWS,`SVX,
	`PUSH,`PEA,`POP,`LINK,`UNLINK:
		fnSelect = 8'hFF;
	default:	fnSelect = 8'h00;
	endcase
else
	case(opcode)
	`STS,`STMV,`STCMP,`STFND,`INC:
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
    `JMPI,`JMPIX:
       case(fn[1:0])
       2'd1:
           case(adr[2:1]) 
           2'd0:   fnSelect = 8'h03;
           2'd1:   fnSelect = 8'h0C;
           2'd2:   fnSelect = 8'h30;
           2'd3:   fnSelect = 8'hC0;
           endcase
       2'd2:
            case(adr[2])
            1'b0:   fnSelect = 8'h0F;
            1'b1:   fnSelect = 8'hF0;
            endcase
       2'd3:   fnSelect = 8'hFF;
       default:    fnSelect = 8'h00;
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
	`LW,`LWX,`SW,`SWCR,`LVW,`LVWAR,`SWX,`CAS,`LWS,`SWS,`STI,`LCL,
	`LV,`LVWS,`LVX,`SV,`SVWS,`SVX,
	`PUSH,`PEA,`POP,`LINK,`UNLINK:
		fnSelect = 8'hFF;
	default:	fnSelect = 8'h00;
	endcase
end
endfunction

function [DBW-1:0] fnDatai;
input [7:0] opcode;
input [5:0] func;
input [DBW-1:0] dat;
input [7:0] sel;
begin
if (DBW==32)
	case(opcode)
	`STMV,`STCMP,`STFND,`INC:
	   case(func[2:0])
	   3'd0,3'd4:
		case(sel[3:0])
        4'h1:    fnDatai = dat[7:0];
        4'h2:    fnDatai = dat[15:8];
        4'h4:    fnDatai = dat[23:16];
        4'h8:    fnDatai = dat[31:24];
        default:    fnDatai = {DBW{1'b1}};
        endcase
       3'd1,3'd5:
		case(sel[3:0])
        4'h3:    fnDatai = dat[15:0];
        4'hC:    fnDatai = dat[31:16];
        default:    fnDatai = {DBW{1'b1}};
        endcase
       default:    
		fnDatai = dat[31:0];
	   endcase
	`JMPI,`JMPIX:
	   case(func[1:0])
	   2'd1:
	       case(sel[3:0])
	       4'h3:   fnDatai = dat[15:0];
	       4'hC:   fnDatai = dat[31:16];
	       default:    fnDatai = {DBW{1'b1}};
	       endcase
	   2'd2:   fnDatai = dat[31:0];
	   default:    fnDatai = dat[31:0];
	   endcase
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
	`LH,`LHU,`LW,`LWX,`LVH,`LVW,`LVWAR,`LHX,`LHUX,
	`LV,`LVWS,`LVX,
	`CAS,`LCL,`LWS,`POP,`UNLINK:
		fnDatai = dat[31:0];
	default:	fnDatai = {DBW{1'b1}};
	endcase
else
	case(opcode)
	`STMV,`STCMP,`STFND,`INC:
	   case(func[2:0])
	   3'd0,3'd4:
		case(sel)
        8'h01:    fnDatai = dat[DBW*1/8-1:0];
        8'h02:    fnDatai = dat[DBW*2/8-1:DBW*1/8];
        8'h04:    fnDatai = dat[DBW*3/8-1:DBW*2/8];
        8'h08:    fnDatai = dat[DBW*4/8-1:DBW*3/8];
        8'h10:    fnDatai = dat[DBW*5/8-1:DBW*4/8];
        8'h20:    fnDatai = dat[DBW*6/8-1:DBW*5/8];
        8'h40:    fnDatai = dat[DBW*7/8-1:DBW*6/8];
        8'h80:    fnDatai = dat[DBW-1:DBW*7/8];
        default:    fnDatai = {DBW{1'b1}};
        endcase
       3'd1,3'd5:
		case(sel)
        8'h03:    fnDatai = dat[DBW/4-1:0];
        8'h0C:    fnDatai = dat[DBW/2-1:DBW/4];
        8'h30:    fnDatai = dat[DBW*3/4-1:DBW/2];
        8'hC0:    fnDatai = dat[DBW-1:DBW*3/4];
        default:    fnDatai = {DBW{1'b1}};
        endcase
       3'd2,3'd6:
		case(sel)
        8'h0F:    fnDatai = dat[DBW/2-1:0];
        8'hF0:    fnDatai = dat[DBW-1:DBW/2];
        default:    fnDatai = {DBW{1'b1}};
        endcase
       3'd3,3'd7:   fnDatai = dat;
	   endcase
	`JMPI,`JMPIX:
	   case(func[1:0])
	   2'd1:
	       case(sel[7:0])
	       8'h03:  fnDatai = dat[15:0];
	       8'h0C:  fnDatai = dat[31:16];
	       8'h30:  fnDatai = dat[47:32];
	       8'hC0:  fnDatai = dat[63:48];
	       default:    fnDatai = dat[15:0];
	       endcase
	   2'd2:
	       case(sel[7:0])
           8'h0F:  fnDatai = dat[31:0];
           8'hF0:  fnDatai = dat[63:32];
           default: fnDatai = dat[31:0];
           endcase
       2'd3:    fnDatai = dat;
       default: fnDatai = dat;
	   endcase
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
	`LW,`LWX,`LVW,`LVWAR,
	`LV,`LVWS,`LVX,
	`CAS,`LCL,`LWS,`POP,`UNLINK:
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
input [5:0] func;
input [DBW-1:0] dat;
if (DBW==32)
	case(opcode)
	`STMV,`INC:
	   case(func[2:0])
	   3'd0,3'd4:  fnDatao = {4{dat[7:0]}};
	   3'd1,3'd5:  fnDatao = {2{dat[15:8]}};
	   default:    fnDatao = dat;
	   endcase
	`SW,`SWCR,`SWX,`CAS,`SWS,`STI,`SV,`SVWS,`SVX,
	`PUSH,`PEA,`LINK:	fnDatao = dat;
	`SH,`SHX:	fnDatao = dat;
	`SC,`SCX:	fnDatao = {2{dat[15:0]}};
	`SB,`SBX:	fnDatao = {4{dat[7:0]}};
	default:	fnDatao = dat;
	endcase
else
	case(opcode)
	`STMV,`INC:
	   case(func[2:0])
	   3'd0,3'd4:  fnDatao = {8{dat[DBW/8-1:0]}};
	   3'd1,3'd5:  fnDatao = {4{dat[DBW/4-1:0]}};
	   3'd2,3'd6:  fnDatao = {2{dat[DBW/2-1:0]}};
	   3'd3,3'd7:  fnDatao = dat;
	   endcase
	`SW,`SWCR,`SWX,`CAS,`SWS,`STI,`SV,`SVWS,`SVX,
	`PUSH,`PEA,`LINK:	fnDatao = dat;
	`SH,`SHX:	fnDatao = {2{dat[DBW/2-1:0]}};
	`SC,`SCX:	fnDatao = {4{dat[DBW/4-1:0]}};
	`SB,`SBX:	fnDatao = {8{dat[DBW/8-1:0]}};
	default:	fnDatao = dat;
	endcase
endfunction

assign fetchbuf0_mem	= fnIsMem(opcode0);
assign fetchbuf0_vec  = fnIsVec(opcode0);
assign fetchbuf0_jmp   = fnIsFlowCtrl(opcode0);
assign fetchbuf0_fp		= fnIsFP(opcode0);
assign fetchbuf0_rfw	= fnIsRFW(opcode0,fetchbuf0_instr);
assign fetchbuf0_pfw	= fnIsPFW(opcode0);
assign fetchbuf1_mem	= fnIsMem(opcode1);
assign fetchbuf1_vec  = fnIsVec(opcode1);
assign fetchbuf1_jmp   = fnIsFlowCtrl(opcode1);
assign fetchbuf1_fp		= fnIsFP(opcode1);
assign fetchbuf1_rfw	= fnIsRFW(opcode1,fetchbuf1_instr);
assign fetchbuf1_pfw    = fnIsPFW(opcode1);

//
// set branchback and backpc values ... ignore branches in fetchbuf slots not ready for enqueue yet
//
assign take_branch0 = ({fetchbuf0_v, fnIsBranch(opcode0), predict_taken0}  == {`VAL, `TRUE, `TRUE}) ||
                      ({fetchbuf0_v, opcode0==`LOOP}  == {`VAL, `TRUE})
                        ;
assign take_branch1 = ({fetchbuf1_v, fnIsBranch(opcode1), predict_taken1}  == {`VAL, `TRUE, `TRUE}) ||
                      ({fetchbuf1_v, opcode1==`LOOP}  == {`VAL, `TRUE})
                        ;
assign take_branch = take_branch0 || take_branch1
        ;

always @*
if (fnIsBranch(opcode0) && fetchbuf0_v && predict_taken0) begin
    branch_pc <= fetchbuf0_pc + {{ABW-12{fetchbuf0_instr[11]}},fetchbuf0_instr[11:8],fetchbuf0_instr[23:16]} + 64'd3;
end
else if (opcode0==`LOOP && fetchbuf0_v) begin
    branch_pc <= fetchbuf0_pc + {{ABW-8{fetchbuf0_instr[23]}},fetchbuf0_instr[23:16]} + 64'd3;
end
else if (fnIsBranch(opcode1) && fetchbuf1_v && predict_taken1) begin
    branch_pc <= fetchbuf1_pc + {{ABW-12{fetchbuf1_instr[11]}},fetchbuf1_instr[11:8],fetchbuf1_instr[23:16]} + 64'd3;
end
else if (opcode1==`LOOP && fetchbuf1_v) begin
    branch_pc <= fetchbuf1_pc + {{ABW-8{fetchbuf1_instr[23]}},fetchbuf1_instr[23:16]} + 64'd3;
end
else begin
    branch_pc <= RSTPC;  // set to something to prevent a latch
end

assign int_pending = (nmi_edge & ~StatusHWI & ~int_commit) || (irq_i & ~im & ~StatusHWI & ~int_commit);

assign mem_stringmissx = ((dram0_op==`STS || dram0_op==`STFND) && int_pending && lc != 0 && !mem_stringmiss) ||
                        ((dram0_op==`STMV || dram0_op==`STCMP) && int_pending && lc != 0 && !mem_stringmiss && stmv_flag);

assign jmpi_miss = dram_v && (dram0_op==`JMPI || dram0_op==`JMPIX);

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
reg [63:0] insn1a,insn2a;
reg [63:0] insn0,insn1,insn2;
always @*
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
else if (ihit) begin
	if (insn[7:0]==8'h00)
		insn0 <= {8'h00,8'hCD,8'hA5,8'h01,8'h00,8'hCD,8'hA5,8'h01};
`ifdef COMPRESSED_INSN
    else if (insn[15:12]==4'hE)
        insn0 <= {hinsn0,insn[7:0]};
`endif
	else
        insn0 <= insn[63:0];
end
else
	insn0 <= {8{8'h10}};	// load with NOPs


always @*
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
else if (ihit) begin
	if (insn1a[7:0]==8'h00)
		insn1 <= {8'h00,8'hCD,8'hA5,8'h01,8'h00,8'hCD,8'hA5,8'h01};
`ifdef COMPRESSED_INSN
    else if (insn1a[15:12]==4'hE)
        insn1 <= {hinsn1,insn1a[7:0]};
`endif
	else
		insn1 <= insn1a;
end
else
	insn1 <= {8{8'h10}};	// load with NOPs


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
function [63:0] fnImm;
input [127:0] insn;
case(insn[15:8])
`P:     fnImm = insn[33:16];
`CAS:	fnImm = {{56{insn[47]}},insn[47:40]};
`BCD:	fnImm = insn[47:40];
`TLB:	fnImm = insn[23:16];
`LOOP:	fnImm = {{56{insn[23]}},insn[23:16]};
`STP:   fnImm = insn[31:16];
`JSR:	fnImm = {{40{insn[47]}},insn[47:24]};
`JSRS:  fnImm = {{48{insn[39]}},insn[39:24]};
`BITFIELD:	fnImm = insn[47:32];
`SYS,`INT:	fnImm = {insn[31:24],4'h0};
//`CMPI,
8'h20,8'h21,8'h22,8'h23,
8'h24,8'h25,8'h26,8'h27,
8'h28,8'h29,8'h2A,8'h2B,
8'h2C,8'h2D,8'h2E,8'h2F,
`LDI,`LDIS,`ADDUIS:
	fnImm = {{54{insn[31]}},insn[31:22]};
`LDISEG,`LDISEG|1'b1:
	fnImm = {insn[23:22],insn[8],{53{insn[31]}},insn[31:24]};
`RTF: fnImm = {9'h264,4'h0};
`JSF: fnImm = {9'h265,4'h0};
`RTS:	fnImm = insn[19:16];
`RTD,`RTE,`RTI,`RTS2,`JSRZ,`STMV,`STCMP,`STFND,`CACHE,`STS:	fnImm = 64'h0;
`STI:	fnImm = {{58{insn[33]}},insn[33:28]};
`PUSH:  fnImm = 64'hFFFFFFFFFFFFFFF8;   //-8
//`LINK:  fnImm = {insn[39:28],3'b000};
`JMPI,`LLA,`LEA,
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LVB,`LVC,`LVH,`LVW,`LVWAR,
`SB,`SC,`SH,`SW,`SWCR,`LWS,`SWS,`INC,`LCL,`PEA:
  if (SEGMODEL==2)
  	fnImm = {{52{insn[39]}},insn[39:28]};
  else
	  fnImm = {{55{insn[36]}},insn[36:28]};
default:
	fnImm = {{52{insn[39]}},insn[39:28]};
endcase

endfunction

function [7:0] fnImm8;
input [127:0] insn;
case(insn[15:8])
`CAS:	fnImm8 = insn[47:40];
`BCD:	fnImm8 = insn[47:40];
`TLB:	fnImm8 = insn[23:16];
`LOOP:	fnImm8 = insn[23:16];
`STP:   fnImm8 = insn[23:16];
`JSR,`JSRS:	fnImm8 = insn[31:24];
`BITFIELD:	fnImm8 = insn[39:32];
`SYS,`INT:	fnImm8 = {insn[27:24],4'h0};
//`CMPI,
8'h20,8'h21,8'h22,8'h23,
8'h24,8'h25,8'h26,8'h27,
8'h28,8'h29,8'h2A,8'h2B,
8'h2C,8'h2D,8'h2E,8'h2F,
`LDI,`LDIS,`ADDUIS:	fnImm8 = insn[29:22];
`LDISEG,`LDISEG|1'b1: fnImm8 = insn[31:24];
`RTF,`JSF: fnImm8 = 8'h80;
`RTS:	fnImm8 = insn[19:16];
`RTD,`RTE,`RTI,`RTS2,`JSRZ,`STMV,`STCMP,`STFND,`CACHE,`STS:	fnImm8 = 8'h00;
`STI:	fnImm8 = insn[35:28];
`PUSH:  fnImm8 = 8'hF8;
`ifdef STACKOPS
`LINK:  fnImm8 = {insn[32:28],3'b000};
`endif
`JMPI,`LLA,`LEA,
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LVB,`LVC,`LVH,`LVW,`LVWAR,
`SB,`SC,`SH,`SW,`SWCR,`LWS,`SWS,`INC,`LCL,`PEA:
  if (SEGMODEL==2)
	  fnImm8 = insn[35:28];
  else
	  fnImm8 = insn[35:28];
default:	fnImm8 = insn[35:28];
endcase
endfunction

// Return MSB of immediate value for instruction
function fnImmMSB;
input [127:0] insn;
case(insn[15:8])
`CAS:	fnImmMSB = insn[47];
`TLB,`BCD,`STP:
	fnImmMSB = 1'b0;		// TLB regno is unsigned
`LOOP:
	fnImmMSB = insn[23];
`JSR:
	fnImmMSB = insn[47];
`JSRS:
    fnImmMSB = insn[39];
//`CMPI,
8'h20,8'h21,8'h22,8'h23,
8'h24,8'h25,8'h26,8'h27,
8'h28,8'h29,8'h2A,8'h2B,
8'h2C,8'h2D,8'h2E,8'h2F,
`LDI,`LDIS,`ADDUIS,`LDISEG,`LDISEG:
	fnImmMSB = insn[31];
`SYS,`INT,`CACHE,`LINK:
	fnImmMSB = 1'b0;		// SYS,INT are unsigned
`JSF,`RTS,`RTF,`RTD,`RTE,`RTI,`JSRZ,`STMV,`STCMP,`STFND,`RTS2,`STS:
	fnImmMSB = 1'b0;		// RTS is unsigned
`PUSH:  fnImmMSB = 1'b1;
`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,
`SBX,`SCX,`SHX,`SWX:
	fnImmMSB = insn[47];
`JMPI,`LLA,`LEA,
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LVB,`LVC,`LVH,`LVW,
`SB,`SC,`SH,`SW,`SWCR,`STI,`LWS,`SWS,`INC,`LCL,`PEA:
  if (SEGMODEL==2)
  	fnImmMSB = insn[39];
  else
	  fnImmMSB = insn[36];
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

// In the works: multiplexing for the immediate operand
function fnOp0;
input [7:0] opcode;
input [5:0] vel;
input [63:0] ins;
input [2:0] tail;
    fnOp0  = 
`ifdef VECTOROPS
             (opcode==`LVX || opcode==`SVX) ? vel :
`endif 
             (opcode==`INT || opcode==`SYS || opcode==`RTF || opcode==`JSF) ? fnImm(ins) :
             fnIsBranch(opcode) ? {{DBW-12{ins[11]}},ins[11:8],ins[23:16]} : 
             (iqentry_op[(tail-3'd1)&7]==`IMM && iqentry_v[tail-3'd1]) ? {iqentry_a0[(tail-3'd1)&7][DBW-1:8],fnImm8(ins)}:
             opcode==`IMM ? fnImmImm(ins) : fnImm(ins);
endfunction

// Used during enque
// Operand A is a little more work than B or C as it may read from special
// purpose registers.
function [63:0] fnOpa;
input [7:0] opcode;
input [7:0] Ra;
input [63:0] ins;
input [63:0] rfo;
input [63:0] epc;
begin
`ifdef BITFIELDOPS
    if (opcode==`BITFIELD && ins[43:40]==`BFINSI)
        fnOpa = ins[21:16];
    else
`endif
	if (Ra[7:6]==2'h1)
		fnOpa = fnSpr(Ra[5:0],epc);
	else
		fnOpa = rfo;
end
endfunction

function [DBW-1:0] fnOpb;
input [7:0] opcode;
input [9:0] Rb;
input [63:0] ins;
input [63:0] rfo;
input [63:0] vrfo;
input [63:0] epc;
begin
    fnOpb = fnIsShiftiop(ins) ? {{DBW-6{1'b0}},ins[`INSTRUCTION_RB]} :
            fnIsFPCtrl(ins) ? {{DBW-6{1'b0}},ins[`INSTRUCTION_RB]} :
            opcode==`INC ? {{56{ins[47]}},ins[47:40]} : 
            opcode==`STI ? ins[27:22] :
            Rb[7:6]==2'h1 ? fnSpr(Rb[5:0],epc) :
`ifdef VECTOROPS            
            Rb[7] ? vrfo :
`endif
            rfo;
end                                
endfunction

// Used during enque
function [63:0] fnOpt;
input [7:0] tgt;
input [63:0] rfo;
input [63:0] vrfo;
input [63:0] epc;
begin
    if (tgt[7:6]==2'b01)
        fnOpt = fnSpr(tgt[5:0],epc);
`ifdef VECTOROPS
    else if (tgt[7])
        fnOpt = vrfo;
`endif
    else
        fnOpt = rfo;
end
endfunction

// Returns TRUE if instruction is only allowed in kernel mode.
function fnIsKMOnly;
input [7:0] op;
`ifdef PRIVCHKS
    fnIsKMOnly = op==`RTI || op==`RTE || op==`RTD || op==`TLB || op==`CLI || op==`SEI ||
                 op==`STP
                ;
`else
    fnIsKMOnly = `FALSE;
`endif
endfunction

function fnIsKMOnlyReg;
input [7:0] regx;
`ifdef PRIVCHKS
    fnIsKMOnlyReg = regx==7'd28 || regx==7'd29 || regx==7'd30 || regx==7'd31 ||
                    regx==7'h5B || regx==7'h5C || regx==7'h5D || regx==7'h5E
                    ;
`else
    fnIsKMOnlyReg = `FALSE;
`endif
endfunction

// Returns TRUE if the register is automatically valid.
function fnRegIsAutoValid;
input [7:0] regno;  // r0, c0, c15, tick
fnRegIsAutoValid = regno==7'h00 || regno==7'h50 || regno==7'h5F || regno==7'h72;
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
	2'h3:
	       case(Rn[3:0])
	       3'h0:   fnRegstrGrp="PA";
	       3'h3:   fnRegstrGrp="LC";
	       endcase
	endcase

endfunction

function [7:0] fnRegstr;
input [7:0] Rn;
begin
if (Rn[7:6]==2'b00) begin
	fnRegstr = Rn[5:0];
end
else
	fnRegstr = Rn[3:0];
end
endfunction

assign operandA0 = fnOpa(opcode0,Ra0,fetchbuf0_instr,rfoa0,fetchbuf0_pc);
assign operandA1 = fnOpa(opcode1,Ra1,fetchbuf1_instr,rfoa1,fetchbuf1_pc);

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
/*
always @*
for (n = 0; n < QENTRIES; n = n + 1)
    iq_cmt[n] <= fnPredicate(iqentry_pred[n], iqentry_cond[n]) ||
        (iqentry_cond[n] < 4'h2 && ({iqentry_pred[n],iqentry_cond[n]}!=8'h90));
*/
wire [QENTRIES-1:0] args_valid;
wire [QENTRIES-1:0] could_issue;

genvar g;
generate
begin : argsv

for (g = 0; g < QENTRIES; g = g + 1)
begin : block1
assign  iqentry_imm[g] = fnHasConst(iqentry_op[g]);

assign args_valid[g] =
			(iqentry_p_v[g]
				|| (iqentry_p_s[g]==alu0_sourceid && alu0_v)
				|| (iqentry_p_s[g]==alu1_sourceid && alu1_v))
			&& (iqentry_a1_v[g] 
//				|| (iqentry_mem[g] && !iqentry_agen[g] && iqentry_op[g]!=`TLB)
				|| (iqentry_a1_s[g] == alu0_sourceid && alu0_v)
				|| (iqentry_a1_s[g] == alu1_sourceid && alu1_v))
			&& (iqentry_a2_v[g] 
				|| (iqentry_a2_s[g] == alu0_sourceid && alu0_v)
				|| (iqentry_a2_s[g] == alu1_sourceid && alu1_v))
			&& (iqentry_a3_v[g] 
				|| (iqentry_a3_s[g] == alu0_sourceid && alu0_v)
				|| (iqentry_a3_s[g] == alu1_sourceid && alu1_v))
`ifdef VECTOROPS
			&& (iqentry_a4_v[g] 
          || (iqentry_a4_s[g] == alu0_sourceid && alu0_v)
          || (iqentry_a4_s[g] == alu1_sourceid && alu1_v))
`endif
			&& (iqentry_T_v[g]
				|| (iqentry_T_s[g] == alu0_sourceid && alu0_v)
                || (iqentry_T_s[g] == alu1_sourceid && alu1_v))
			;

assign could_issue[g] = iqentry_v[g] && !iqentry_done[g] &&
                        !iqentry_out[g] && args_valid[g] &&
                         (iqentry_mem[g] ? !iqentry_agen[g] : 1'b1);

end
end
endgenerate

// The (old) simulator didn't handle the asynchronous race loop properly in the 
// original code. It would issue two instructions to the same islot. So the
// issue logic has been re-written to eliminate the asynchronous loop.
// Can't issue to the ALU if it's busy doing a long running operation like a 
// divide.
always @*//(could_issue or head0 or head1 or head2 or head3 or head4 or head5 or head6 or head7)
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
	// See if we can issue to the first alu.
	if (alu0_idle) begin
    if (could_issue[head0] && !iqentry_fp[head0]) begin
      iqentry_issue[head0] = `TRUE;
      iqentry_islot[head0] = 2'b00;
    end
    else if (could_issue[head1] && !iqentry_fp[head1]
    && !(iqentry_v[head0] && iqentry_sync[head0]))
    begin
      iqentry_issue[head1] = `TRUE;
      iqentry_islot[head1] = 2'b00;
    end
    else if (could_issue[head2] && !iqentry_fp[head2]
    && !(iqentry_v[head0] && iqentry_sync[head0])
    && !(iqentry_v[head1] && iqentry_sync[head1])
    )
    begin
      iqentry_issue[head2] = `TRUE;
      iqentry_islot[head2] = 2'b00;
    end
    else if (could_issue[head3] && !iqentry_fp[head3]
    && !(iqentry_v[head0] && iqentry_sync[head0])
    && !(iqentry_v[head1] && iqentry_sync[head1])
    && !(iqentry_v[head2] && iqentry_sync[head2])
    ) begin
      iqentry_issue[head3] = `TRUE;
      iqentry_islot[head3] = 2'b00;
    end
    else if (could_issue[head4] && !iqentry_fp[head4]
    && !(iqentry_v[head0] && iqentry_sync[head0])
    && !(iqentry_v[head1] && iqentry_sync[head1])
    && !(iqentry_v[head2] && iqentry_sync[head2])
    && !(iqentry_v[head3] && iqentry_sync[head3])
    ) begin
      iqentry_issue[head4] = `TRUE;
      iqentry_islot[head4] = 2'b00;
    end
    else if (could_issue[head5] && !iqentry_fp[head5]
    && !(iqentry_v[head0] && iqentry_sync[head0])
    && !(iqentry_v[head1] && iqentry_sync[head1])
    && !(iqentry_v[head2] && iqentry_sync[head2])
    && !(iqentry_v[head3] && iqentry_sync[head3])
    && !(iqentry_v[head4] && iqentry_sync[head4])
    ) begin
      iqentry_issue[head5] = `TRUE;
      iqentry_islot[head5] = 2'b00;
    end
    else if (could_issue[head6] && !iqentry_fp[head6]
    && !(iqentry_v[head0] && iqentry_sync[head0])
    && !(iqentry_v[head1] && iqentry_sync[head1])
    && !(iqentry_v[head2] && iqentry_sync[head2])
    && !(iqentry_v[head3] && iqentry_sync[head3])
    && !(iqentry_v[head4] && iqentry_sync[head4])
    && !(iqentry_v[head5] && iqentry_sync[head5])
    ) begin
      iqentry_issue[head6] = `TRUE;
      iqentry_islot[head6] = 2'b00;
    end
    else if (could_issue[head7] && !iqentry_fp[head7]
    && !(iqentry_v[head0] && iqentry_sync[head0])
    && !(iqentry_v[head1] && iqentry_sync[head1])
    && !(iqentry_v[head2] && iqentry_sync[head2])
    && !(iqentry_v[head3] && iqentry_sync[head3])
    && !(iqentry_v[head4] && iqentry_sync[head4])
    && !(iqentry_v[head5] && iqentry_sync[head5])
    && !(iqentry_v[head6] && iqentry_sync[head6])
    ) begin
      iqentry_issue[head7] = `TRUE;
      iqentry_islot[head7] = 2'b00;
  	end
	end

  if (alu1_idle) begin
    if (could_issue[head0] && !iqentry_fp[head0]
    && !fnIsAlu0Op(iqentry_op[head0],iqentry_fn[head0])
    && !iqentry_issue[head0]) begin
      iqentry_issue[head0] = `TRUE;
      iqentry_islot[head0] = 2'b01;
    end
    else if (could_issue[head1] && !iqentry_fp[head1] && !iqentry_issue[head1]
    && !fnIsAlu0Op(iqentry_op[head1],iqentry_fn[head1])
    && !(iqentry_v[head0] && iqentry_sync[head0]))
    begin
      iqentry_issue[head1] = `TRUE;
      iqentry_islot[head1] = 2'b01;
    end
    else if (could_issue[head2] && !iqentry_fp[head2] && !iqentry_issue[head2]
    && !fnIsAlu0Op(iqentry_op[head2],iqentry_fn[head2])
    && !(iqentry_v[head0] && iqentry_sync[head0])
    && !(iqentry_v[head1] && iqentry_sync[head1])
    )
    begin
      iqentry_issue[head2] = `TRUE;
      iqentry_islot[head2] = 2'b01;
    end
    else if (could_issue[head3] && !iqentry_fp[head3] && !iqentry_issue[head3]
    && !fnIsAlu0Op(iqentry_op[head3],iqentry_fn[head3])
    && !(iqentry_v[head0] && iqentry_sync[head0])
    && !(iqentry_v[head1] && iqentry_sync[head1])
    && !(iqentry_v[head2] && iqentry_sync[head2])
    ) begin
      iqentry_issue[head3] = `TRUE;
      iqentry_islot[head3] = 2'b01;
    end
    else if (could_issue[head4] && !iqentry_fp[head4] && !iqentry_issue[head4]
    && !fnIsAlu0Op(iqentry_op[head4],iqentry_fn[head4])
    && !(iqentry_v[head0] && iqentry_sync[head0])
    && !(iqentry_v[head1] && iqentry_sync[head1])
    && !(iqentry_v[head2] && iqentry_sync[head2])
    && !(iqentry_v[head3] && iqentry_sync[head3])
    ) begin
      iqentry_issue[head4] = `TRUE;
      iqentry_islot[head4] = 2'b01;
    end
    else if (could_issue[head5] && !iqentry_fp[head5] && !iqentry_issue[head5]
    && !fnIsAlu0Op(iqentry_op[head5],iqentry_fn[head5])
    && !(iqentry_v[head0] && iqentry_sync[head0])
    && !(iqentry_v[head1] && iqentry_sync[head1])
    && !(iqentry_v[head2] && iqentry_sync[head2])
    && !(iqentry_v[head3] && iqentry_sync[head3])
    && !(iqentry_v[head4] && iqentry_sync[head4])
    ) begin
      iqentry_issue[head5] = `TRUE;
      iqentry_islot[head5] = 2'b01;
    end
    else if (could_issue[head6] & !iqentry_fp[head6] && !iqentry_issue[head6]
    && !fnIsAlu0Op(iqentry_op[head6],iqentry_fn[head6])
    && !(iqentry_v[head0] && iqentry_sync[head0])
    && !(iqentry_v[head1] && iqentry_sync[head1])
    && !(iqentry_v[head2] && iqentry_sync[head2])
    && !(iqentry_v[head3] && iqentry_sync[head3])
    && !(iqentry_v[head4] && iqentry_sync[head4])
    && !(iqentry_v[head5] && iqentry_sync[head5])
    ) begin
      iqentry_issue[head6] = `TRUE;
      iqentry_islot[head6] = 2'b01;
    end
    else if (could_issue[head7] && !iqentry_fp[head7] && !iqentry_issue[head7]
    && !fnIsAlu0Op(iqentry_op[head7],iqentry_fn[head7])
    && !(iqentry_v[head0] && iqentry_sync[head0])
    && !(iqentry_v[head1] && iqentry_sync[head1])
    && !(iqentry_v[head2] && iqentry_sync[head2])
    && !(iqentry_v[head3] && iqentry_sync[head3])
    && !(iqentry_v[head4] && iqentry_sync[head4])
    && !(iqentry_v[head5] && iqentry_sync[head5])
    && !(iqentry_v[head6] && iqentry_sync[head6])
    ) begin
      iqentry_issue[head7] = `TRUE;
      iqentry_islot[head7] = 2'b01;
    end
  end
end

`ifdef FLOATING_POINT
reg [3:0] fpispot;
always @* //(could_issue or head0 or head1 or head2 or head3 or head4 or head5 or head6 or head7)
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
	&& !(iqentry_v[head0] && iqentry_sync[head0]))
	begin
		iqentry_fpissue[head1] = `TRUE;
		iqentry_fpislot[head1] = 2'b00;
		fpispot = head1;
	end
	else if (could_issue[head2] & iqentry_fp[head2]
	&& !(iqentry_v[head0] && iqentry_sync[head0])
	&& !(iqentry_v[head1] && iqentry_sync[head1])
	)
	begin
		iqentry_fpissue[head2] = `TRUE;
		iqentry_fpislot[head2] = 2'b00;
		fpispot = head2;
	end
	else if (could_issue[head3] & iqentry_fp[head3]
	&& !(iqentry_v[head0] && iqentry_sync[head0])
	&& !(iqentry_v[head1] && iqentry_sync[head1])
	&& !(iqentry_v[head2] && iqentry_sync[head2])
	) begin
		iqentry_fpissue[head3] = `TRUE;
		iqentry_fpislot[head3] = 2'b00;
		fpispot = head3;
	end
	else if (could_issue[head4] & iqentry_fp[head4]
	&& !(iqentry_v[head0] && iqentry_sync[head0])
	&& !(iqentry_v[head1] && iqentry_sync[head1])
	&& !(iqentry_v[head2] && iqentry_sync[head2])
	&& !(iqentry_v[head3] && iqentry_sync[head3])
	) begin
		iqentry_fpissue[head4] = `TRUE;
		iqentry_fpislot[head4] = 2'b00;
		fpispot = head4;
	end
	else if (could_issue[head5] & iqentry_fp[head5]
	&& !(iqentry_v[head0] && iqentry_sync[head0])
	&& !(iqentry_v[head1] && iqentry_sync[head1])
	&& !(iqentry_v[head2] && iqentry_sync[head2])
	&& !(iqentry_v[head3] && iqentry_sync[head3])
	&& !(iqentry_v[head4] && iqentry_sync[head4])
	) begin
		iqentry_fpissue[head5] = `TRUE;
		iqentry_fpislot[head5] = 2'b00;
		fpispot = head5;
	end
	else if (could_issue[head6] & iqentry_fp[head6]
	&& !(iqentry_v[head0] && iqentry_sync[head0])
	&& !(iqentry_v[head1] && iqentry_sync[head1])
	&& !(iqentry_v[head2] && iqentry_sync[head2])
	&& !(iqentry_v[head3] && iqentry_sync[head3])
	&& !(iqentry_v[head4] && iqentry_sync[head4])
	&& !(iqentry_v[head5] && iqentry_sync[head5])
	) begin
		iqentry_fpissue[head6] = `TRUE;
		iqentry_fpislot[head6] = 2'b00;
		fpispot = head6;
	end
	else if (could_issue[head7] & iqentry_fp[head7]
	&& !(iqentry_v[head0] && iqentry_sync[head0])
	&& !(iqentry_v[head1] && iqentry_sync[head1])
	&& !(iqentry_v[head2] && iqentry_sync[head2])
	&& !(iqentry_v[head3] && iqentry_sync[head3])
	&& !(iqentry_v[head4] && iqentry_sync[head4])
	&& !(iqentry_v[head5] && iqentry_sync[head5])
	&& !(iqentry_v[head6] && iqentry_sync[head6])
	) begin
		iqentry_fpissue[head7] = `TRUE;
		iqentry_fpislot[head7] = 2'b00;
		fpispot = head7;
	end
	else
		fpispot = 4'd8;

end
`endif

// 
// additional logic for handling a branch miss (STOMP logic)
//
wire [QENTRIES-1:0] alu0_issue_;
wire [QENTRIES-1:0] alu1_issue_;
wire [QENTRIES-1:0] fp0_issue_;
generate
begin : stomp_logic
assign iqentry_stomp[0] = branchmiss & (iqentry_v[0] && head0 != 3'd0 && ((missid == QENTRIES-1) || iqentry_stomp[QENTRIES-1]));
for (g = 1; g < QENTRIES; g = g + 1)
assign iqentry_stomp[g] = branchmiss & (iqentry_v[g] && head0 != g && ((missid == g-1) || iqentry_stomp[g-1]));
for (g = 0; g < QENTRIES; g = g + 1)
begin : block2
assign alu0_issue_[g] = (!(iqentry_v[g] && iqentry_stomp[g]) && iqentry_issue[g] && iqentry_islot[g]==2'd0);
assign alu1_issue_[g] = (!(iqentry_v[g] && iqentry_stomp[g]) && iqentry_issue[g] && iqentry_islot[g]==2'd1);
assign fp0_issue_[g] = (!(iqentry_v[g] && iqentry_stomp[g]) && iqentry_fpissue[g] && iqentry_islot[g]==2'd0);
end
end
endgenerate

assign alu0_issue = |alu0_issue_;
assign alu1_issue = |alu1_issue_;
`ifdef FLOATING_POINT
assign fp0_issue = |fp0_issue_;
`endif

wire dcache_access_pending = dram0 == DS_CACHE_READ && (!rhit || (dram0_op==`LCL && dram0_tgt==7'd1));

//
// determine if the instructions ready to issue can, in fact, issue.
// "ready" means that the instruction has valid operands but has not gone yet
//
// Stores can only issue if there is no possibility of a change of program flow.
// That means no flow control operations or instructions that can cause an
// exception can be before the store.

// ToDo: if debugging matches are enabled in theory any instruction could cause
// a debug exception. The memory issue logic should check to see a debug address
// match will occur, and avoid a store operation. It may be simpler to have stores
// only occur if they are at the head of the queue if debugging matches are turned
// on.
assign iqentry_memissue_head0 =	iqentry_memready[ head0 ] && cstate==IDLE && !dcache_access_pending && dram0==DS_IDLE;		// first in line ... go as soon as ready

assign iqentry_memissue_head1 =	~iqentry_stomp[head1] && iqentry_memready[ head1 ] 		// addr and data are valid
				// ... and no preceding instruction is ready to go
				&& ~iqentry_memready[head0]
				// ... and there is no address-overlap with any preceding instruction
				&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
					|| (iqentry_a1_v[head0] && iqentry_a1[head1][DBW-1:3] != iqentry_a1[head0][DBW-1:3]))
				// ... and, if it is a SW, there is no chance of it being undone
				&& (fnIsStore(iqentry_op[head1]) ? !fnIsFlowCtrl(iqentry_op[head0])
				&& !fnCanException(iqentry_op[head0],iqentry_fn[head0]) : `TRUE)
				&& (!iqentry_cas[head1])
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_memdb[head0]) 
				&& !(iqentry_v[head0] && iqentry_memsb[head0]) 
				&& cstate==IDLE && !dcache_access_pending && dram0==DS_IDLE
				;

assign iqentry_memissue_head2 =	~iqentry_stomp[head2] && iqentry_memready[ head2 ]		// addr and data are valid
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
				    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0],iqentry_fn[head0]) && 
				    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1],iqentry_fn[head1]) 
				    : `TRUE)
				&& (!iqentry_cas[head2])
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_memdb[head0])
				&& !(iqentry_v[head1] && fnIsMem(iqentry_op[head1]) && iqentry_memdb[head1])
				// ... and there is no instruction barrier
				&& !(iqentry_v[head0] && iqentry_memsb[head0]) 
				&& !(iqentry_v[head1] && iqentry_memsb[head1])
				&& cstate==IDLE && !dcache_access_pending && dram0==DS_IDLE
				;
//					(   !fnIsFlowCtrl(iqentry_op[head0])
//					 && !fnIsFlowCtrl(iqentry_op[head1])));

assign iqentry_memissue_head3 =	~iqentry_stomp[head3] && iqentry_memready[ head3 ] 	// addr and data are valid
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
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0],iqentry_fn[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1],iqentry_fn[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2],iqentry_fn[head2]) 
                    : `TRUE)
				&& (!iqentry_cas[head3])
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_memdb[head0])
				&& !(iqentry_v[head1] && fnIsMem(iqentry_op[head1]) && iqentry_memdb[head1])
				&& !(iqentry_v[head2] && fnIsMem(iqentry_op[head2]) && iqentry_memdb[head2])
				// ... and there is no instruction barrier
				&& !(iqentry_v[head0] && iqentry_memsb[head0]) 
                && !(iqentry_v[head1] && iqentry_memsb[head1]) 
                && !(iqentry_v[head2] && iqentry_memsb[head2])
				&& cstate==IDLE && !dcache_access_pending && dram0==DS_IDLE
				;
/*					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])));
*/
assign iqentry_memissue_head4 =	~iqentry_stomp[head4] && iqentry_memready[ head4 ] 		// addr and data are valid
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
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0],iqentry_fn[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1],iqentry_fn[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2],iqentry_fn[head2]) && 
                    !fnIsFlowCtrl(iqentry_op[head3]) && !fnCanException(iqentry_op[head3],iqentry_fn[head3]) 
                    : `TRUE)
				&& (!iqentry_cas[head4])
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_memdb[head0])
				&& !(iqentry_v[head1] && fnIsMem(iqentry_op[head1]) && iqentry_memdb[head1])
				&& !(iqentry_v[head2] && fnIsMem(iqentry_op[head2]) && iqentry_memdb[head2])
				&& !(iqentry_v[head3] && fnIsMem(iqentry_op[head3]) && iqentry_memdb[head3])
				// ... and there is no instruction barrier
				&& !(iqentry_v[head0] && iqentry_memsb[head0]) 
                && !(iqentry_v[head1] && iqentry_memsb[head1]) 
                && !(iqentry_v[head2] && iqentry_memsb[head2]) 
                && !(iqentry_v[head3] && iqentry_memsb[head3])
				&& cstate==IDLE && !dcache_access_pending && dram0==DS_IDLE
				;
/* ||
					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])
					 && !fnIsFlowCtrl(iqentry_op[head3])));
*/
assign iqentry_memissue_head5 =	~iqentry_stomp[head5] && iqentry_memready[ head5 ] 		// addr and data are valid
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
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0],iqentry_fn[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1],iqentry_fn[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2],iqentry_fn[head2]) && 
                    !fnIsFlowCtrl(iqentry_op[head3]) && !fnCanException(iqentry_op[head3],iqentry_fn[head3]) && 
                    !fnIsFlowCtrl(iqentry_op[head4]) && !fnCanException(iqentry_op[head4],iqentry_fn[head4]) 
                    : `TRUE)
				&& (!iqentry_cas[head5])
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_memdb[head0])
				&& !(iqentry_v[head1] && fnIsMem(iqentry_op[head1]) && iqentry_memdb[head1])
				&& !(iqentry_v[head2] && fnIsMem(iqentry_op[head2]) && iqentry_memdb[head2])
				&& !(iqentry_v[head3] && fnIsMem(iqentry_op[head3]) && iqentry_memdb[head3])
				&& !(iqentry_v[head4] && fnIsMem(iqentry_op[head4]) && iqentry_memdb[head4])
				// ... and there is no instruction barrier
				&& !(iqentry_v[head0] && iqentry_memsb[head0]) 
                && !(iqentry_v[head1] && iqentry_memsb[head1]) 
                && !(iqentry_v[head2] && iqentry_memsb[head2]) 
                && !(iqentry_v[head3] && iqentry_memsb[head3]) 
                && !(iqentry_v[head4] && iqentry_memsb[head4])
				&& cstate==IDLE && !dcache_access_pending && dram0==DS_IDLE
				;
/*||
					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])
					 && !fnIsFlowCtrl(iqentry_op[head3])
					 && !fnIsFlowCtrl(iqentry_op[head4])));
*/
assign iqentry_memissue_head6 =	~iqentry_stomp[head6] && iqentry_memready[ head6 ] 		// addr and data are valid
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
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0],iqentry_fn[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1],iqentry_fn[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2],iqentry_fn[head2]) && 
                    !fnIsFlowCtrl(iqentry_op[head3]) && !fnCanException(iqentry_op[head3],iqentry_fn[head3]) && 
                    !fnIsFlowCtrl(iqentry_op[head4]) && !fnCanException(iqentry_op[head4],iqentry_fn[head4]) && 
                    !fnIsFlowCtrl(iqentry_op[head5]) && !fnCanException(iqentry_op[head5],iqentry_fn[head5]) 
                    : `TRUE)
				&& (!iqentry_cas[head6])
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_memdb[head0])
				&& !(iqentry_v[head1] && fnIsMem(iqentry_op[head1]) && iqentry_memdb[head1])
				&& !(iqentry_v[head2] && fnIsMem(iqentry_op[head2]) && iqentry_memdb[head2])
				&& !(iqentry_v[head3] && fnIsMem(iqentry_op[head3]) && iqentry_memdb[head3])
				&& !(iqentry_v[head4] && fnIsMem(iqentry_op[head4]) && iqentry_memdb[head4])
				&& !(iqentry_v[head5] && fnIsMem(iqentry_op[head5]) && iqentry_memdb[head5])
				// ... and there is no instruction barrier
				&& !(iqentry_v[head0] && iqentry_memsb[head0]) 
                && !(iqentry_v[head1] && iqentry_memsb[head1]) 
                && !(iqentry_v[head2] && iqentry_memsb[head2]) 
                && !(iqentry_v[head3] && iqentry_memsb[head3]) 
                && !(iqentry_v[head4] && iqentry_memsb[head4]) 
                && !(iqentry_v[head5] && iqentry_memsb[head5])
				&& cstate==IDLE && !dcache_access_pending && dram0==DS_IDLE
				;
				/*||
					(   !fnIsFlowCtrl(iqentry_op[head0])
					 && !fnIsFlowCtrl(iqentry_op[head1])
					 && !fnIsFlowCtrl(iqentry_op[head2])
					 && !fnIsFlowCtrl(iqentry_op[head3])
					 && !fnIsFlowCtrl(iqentry_op[head4])
					 && !fnIsFlowCtrl(iqentry_op[head5])));
*/
assign iqentry_memissue_head7 =	~iqentry_stomp[head7] && iqentry_memready[ head7 ] 		// addr and data are valid
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
                    !fnIsFlowCtrl(iqentry_op[head0]) && !fnCanException(iqentry_op[head0],iqentry_fn[head0]) && 
                    !fnIsFlowCtrl(iqentry_op[head1]) && !fnCanException(iqentry_op[head1],iqentry_fn[head1]) &&
                    !fnIsFlowCtrl(iqentry_op[head2]) && !fnCanException(iqentry_op[head2],iqentry_fn[head2]) && 
                    !fnIsFlowCtrl(iqentry_op[head3]) && !fnCanException(iqentry_op[head3],iqentry_fn[head3]) && 
                    !fnIsFlowCtrl(iqentry_op[head4]) && !fnCanException(iqentry_op[head4],iqentry_fn[head4]) && 
                    !fnIsFlowCtrl(iqentry_op[head5]) && !fnCanException(iqentry_op[head5],iqentry_fn[head5]) && 
                    !fnIsFlowCtrl(iqentry_op[head6]) && !fnCanException(iqentry_op[head6],iqentry_fn[head6]) 
                    : `TRUE)
				&& (!iqentry_cas[head7])
				// ... and there is no memory barrier
				&& !(iqentry_v[head0] && fnIsMem(iqentry_op[head0]) && iqentry_memdb[head0])
				&& !(iqentry_v[head1] && fnIsMem(iqentry_op[head1]) && iqentry_memdb[head1])
				&& !(iqentry_v[head2] && fnIsMem(iqentry_op[head2]) && iqentry_memdb[head2])
				&& !(iqentry_v[head3] && fnIsMem(iqentry_op[head3]) && iqentry_memdb[head3])
				&& !(iqentry_v[head4] && fnIsMem(iqentry_op[head4]) && iqentry_memdb[head4])
				&& !(iqentry_v[head5] && fnIsMem(iqentry_op[head5]) && iqentry_memdb[head5])
				&& !(iqentry_v[head6] && fnIsMem(iqentry_op[head6]) && iqentry_memdb[head6])
				// ... and there is no instruction barrier
				&& !(iqentry_v[head0] && iqentry_memsb[head0]) 
                && !(iqentry_v[head1] && iqentry_memsb[head1]) 
                && !(iqentry_v[head2] && iqentry_memsb[head2]) 
                && !(iqentry_v[head3] && iqentry_memsb[head3]) 
                && !(iqentry_v[head4] && iqentry_memsb[head4]) 
                && !(iqentry_v[head5] && iqentry_memsb[head5]) 
                && !(iqentry_v[head6] && iqentry_memsb[head6])
				&& cstate==IDLE && !dcache_access_pending && dram0==DS_IDLE
				;

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

generate
begin : memr
    for (g = 0; g < QENTRIES; g = g + 1)
    begin : block4
assign iqentry_memopsvalid[g] = (iqentry_mem[g] & iqentry_a2_v[g] & iqentry_a3_v[g] & iqentry_agen[g] & iqentry_T_v[g]);
assign iqentry_memready[g] = (iqentry_v[g] & iqentry_memopsvalid[g] & ~iqentry_memissue[g] /*& !iqentry_issue[g]*/ & ~iqentry_done[g] & ~iqentry_out[g] & ~iqentry_stomp[g]);
    end
end
endgenerate

/*
assign
    iqentry_memready[0] = (iqentry_v[0] & iqentry_memopsvalid[0] & ~iqentry_memissue[0] & ~iqentry_done[0] & ~iqentry_out[0] & ~iqentry_stomp[0]),
*/
assign outstanding_stores = (|dram0 && fnIsStore(dram0_op)) || (|dram1 && fnIsStore(dram1_op)) || (|dram2 && fnIsStore(dram2_op));

// This signal needed to stave off an instruction cache access.
assign mem_issue =
    iqentry_memissue_head0 |
    iqentry_memissue_head1 |
    iqentry_memissue_head2 |
    iqentry_memissue_head3 |
    iqentry_memissue_head4 |
    iqentry_memissue_head5 |
    iqentry_memissue_head6 |
    iqentry_memissue_head7
    ;

// Nybble slices for predicate register forwarding
wire [3:0] alu0nyb[0:15];
wire [3:0] alu1nyb[0:15];
wire [3:0] cmt0nyb[0:15];
wire [3:0] cmt1nyb[0:15];

generate
begin : nybs
    for (g = 0; g < DBW/4; g = g + 1)
    begin : block3
assign alu0nyb[g] = alu0_bus[g*4+3:g*4];
assign alu1nyb[g] = alu1_bus[g*4+3:g*4];
assign cmt0nyb[g] = commit0_bus[g*4+3:g*4];
assign cmt1nyb[g] = commit1_bus[g*4+3:g*4];
    end
end
endgenerate

//`include "Thor_commit_combo.v"

assign commit0_v = ({iqentry_v[head0], iqentry_done[head0]} == 2'b11 && ~|panic);
assign commit1_v = ({iqentry_v[head0], iqentry_done[head0]} != 2'b10 
		&& {iqentry_v[head1], iqentry_done[head1]} == 2'b11 && ~|panic);

assign commit0_id = {iqentry_mem[head0], head0};	// if a memory op, it has a DRAM-bus id
assign commit1_id = {iqentry_mem[head1], head1};	// if a memory op, it has a DRAM-bus id

assign commit0_tgt = iqentry_tgt[head0];
assign commit1_tgt = iqentry_tgt[head1];

assign commit0_bus = iqentry_res[head0];
assign commit1_bus = iqentry_res[head1];

// If the target register is code address register #13 or #11 (0Dh) then we really wanted a SYS not an INT.
// The difference is that and INT returns to the interrupted instruction, and a SYS returns to the 
// next instruction. In the case of hardware determined software exceptions we want to be able to
// return to the interrupted instruction, hence an INT is forced targeting code address reg #13.
assign int_commit = (iqentry_op[head0]==`INT && commit0_v && iqentry_tgt[head0][3:0]==4'hE) ||
                    (commit0_v && iqentry_op[head1]==`INT && commit1_v && iqentry_tgt[head1][3:0]==4'hE);
assign sys_commit = ((iqentry_op[head0]==`SYS || (iqentry_op[head0]==`INT &&
                        (iqentry_tgt[head0][3:0]==4'hD || iqentry_tgt[head0][3:0]==4'hB))) && commit0_v) ||
                     (commit0_v && (iqentry_op[head1]==`SYS || (iqentry_op[head1]==`INT &&
                        (iqentry_tgt[head1][3:0]==4'hD || iqentry_tgt[head1][3:0]==4'hB))) && commit1_v);
`ifdef DEBUG_LOGIC                       
assign dbg_commit = (((iqentry_op[head0]==`SYS && iqentry_tgt[head0][3:0]==4'hB) ||
                      (iqentry_op[head0]==`INT && (iqentry_tgt[head0][3:0]==4'hB))) && commit0_v) ||
       (commit0_v && ((iqentry_op[head1]==`SYS && iqentry_tgt[head1][3:0]==4'hB)||
                      (iqentry_op[head1]==`INT && (iqentry_tgt[head1][3:0]==4'hB))) && commit1_v);
`endif

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

//-----------------------------------------------------------------------------
// Clock control
// - reset or NMI reenables the clock
// - this circuit must be under the clk_i domain
//-----------------------------------------------------------------------------
//
reg cpu_clk_en;
reg [15:0] clk_throttle;
reg [15:0] clk_throttle_new;
reg ld_clk_throttle;

//BUFGCE u20 (.CE(cpu_clk_en), .I(clk_i), .O(clk) );

reg lct1;
always @(posedge clk_i)
if (rst_i) begin
	cpu_clk_en <= 1'b1;
	lct1 <= 1'b0;
	clk_throttle <= STARTUP_POWER;	// 50% power
end
else begin
	lct1 <= ld_clk_throttle;
	clk_throttle <= {clk_throttle[14:0],clk_throttle[15]};
	if (ld_clk_throttle && !lct1) begin
		clk_throttle <= clk_throttle_new;
    end
	if (nmi_i)
		clk_throttle <= STARTUP_POWER;
	cpu_clk_en <= clk_throttle[15];
end

// Clock throttling bypassed for now
assign clk_o = clk;
assign clk = clk_i;

always @(posedge tm_clk_i)
  mtime <= mtime + 8'd1;

//-----------------------------------------------------------------------------
// Note that everything clocked has to be in the same always block. This is a
// limitation of some toolsets. Simulation / synthesis may get confused if the
// logic isn't placed in the same always block.
//-----------------------------------------------------------------------------

always @(posedge clk) begin

  mtimes <= mtime;    // synchronize to this clock domain

	if (nmi_i & !nmi1)
		nmi_edge <= 1'b1;
	
	ld_clk_throttle <= `FALSE;
	dram_v <= `INV;
	alu0_ld <= 1'b0;
	alu1_ld <= 1'b0;
`ifdef FLOATING_POINT
	fp0_ld <= 1'b0;
`endif

    // Interrupt enable countdown delay.    
    if (imcd!=6'h3f)
        imcd <= {imcd[4:0],1'b0};
    if (imcd==6'd0) begin
        im <= 1'b0;
        imcd <= 6'h3f;
    end

    mem_stringmiss <= `FALSE;
    if (mem_stringmissx) begin
        mem_stringmiss <= `TRUE;
//        dram0_op <= `NOP;   // clears string miss
    end
	ic_invalidate <= `FALSE;
	dc_invalidate <= `FALSE;
	ic_invalidate_line <= `FALSE;
    dc_invalidate_line <= `FALSE;
    alu0_dataready <= `FALSE;
    alu1_dataready <= `FALSE;

    // Reset segmentation flag once operating in non-segmented area.
    if (pc[ABW-1:ABW-4]==4'hF)
        pc[ABW] <= 1'b0;

    if (rst_i)
        cstate <= RESET1;
	if (rst_i||cstate==RESET1||cstate==RESET2) begin
	    imcd <= 6'h3F;
	    wb_nack();
`ifdef PCHIST
	    pc_cap <= `TRUE;
`endif
	    ierr <= 1'b0;
		GM <= 8'hFF;
		nmi_edge <= 1'b0;
		pc <= RSTPC[ABW-1:0];
		StatusHWI <= `TRUE;		// disables interrupts at startup until an RTI instruction is executed.
		im <= 1'b1;
		imb <= 1'b1;
		ic_invalidate <= `TRUE;
		dc_invalidate <= `TRUE;
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
		for (i=0; i< QENTRIES; i=i+1) begin
			iqentry_v[i] <= `INV;
			iqentry_agen[i] <= `FALSE;
			iqentry_op[i] <= `NOP;
			iqentry_memissue[i] <= `FALSE;
			iqentry_a1[i] <= 64'd0;
			iqentry_a2[i] <= 64'd0;
			iqentry_a3[i] <= 64'd0;
			iqentry_T[i] <= 64'd0;
			iqentry_a1_v[i] <= `INV;
			iqentry_a2_v[i] <= `INV;
			iqentry_a3_v[i] <= `INV;
			iqentry_T_v[i] <= `INV;
			iqentry_a1_s[i] <= 4'd0;
			iqentry_a2_s[i] <= 4'd0;
			iqentry_a3_s[i] <= 4'd0;
			iqentry_T_s[i] <= 4'd0;
		end
		// All the register are flagged as valid on startup even though they
		// may not contain valid data. Otherwise the processor will stall
		// waiting for the registers to become valid. Ideally the registers
		// should be initialized with valid values before use. But who knows
		// what someone will do in boot code and we don't want the processor
		// to stall.
		for (n = 1; n < NREGS; n = n + 1) begin
			rf_v[n] = `VAL;
`ifdef SIMULATION
			rf_source[n] <= 4'd0;
`endif
        dbg_ctrl <= {DBW{1'b0}};
`ifdef SIMULATION
        dbg_adr0 <= 0;
        dbg_adr1 <= 0;
        dbg_adr2 <= 0;
        dbg_adr3 <= 0;
`endif
		end
`ifdef SEGMENTATION
		if (ABW==32)
		  sregs_lmt[7] = 20'hFFFFF;
		else
		  sregs_lmt[7] = 52'hFFFFFFFFFFFFF;
		// The pc wraps around to address zero while fetching the reset vector.
    // This causes the processor to use the code segement register so the
    // CS has to be defined for reset.
    sregs_base[7] <= RSTCSEG;
`endif
		rf_source[0] <= 4'd0;
//		rf_v[0] = `VAL;
//		rf_v[7'h50] = `VAL;
//		rf_v[7'h5F] = `VAL;
		alu0_available <= `TRUE;
		alu1_available <= `TRUE;
        reset_tail_pointers(1);
		head0 <= 3'd0;
		head1 <= 3'd1;
		head2 <= 3'd2;
		head3 <= 3'd3;
		head4 <= 3'd4;
		head5 <= 3'd5;
		head6 <= 3'd6;
		head7 <= 3'd7;
		dram0 <= DS_IDLE;
		dram1 <= DS_IDLE;
		dram2 <= DS_IDLE;
		tlb_state <= 3'd0;
		panic <= `PANIC_NONE;
		string_pc <= 64'd0;
		for (i=0; i < 16; i=i+1)
			pregs[i] <= 4'd0;
		asid <= 8'h00;
		rrmapno <= 3'd0;
		dram0_id <= 0;
		alu1_sourceid <= 0;
		smode <= 2'b00;
		pregset <= 4'd0;
		regset <= 4'd7;
		seqnum <= 8'h00;
	end

	// The following registers are always valid
	rf_v[7'h00] = `VAL;
	rf_v[7'h50] = `VAL;	// C0
	rf_v[7'h5F] = `VAL;	// C15 (PC)
	rf_v[7'h72] = `VAL; // tick
    queued1 = `FALSE;
    queued2 = `FALSE;
    allowq = `TRUE;
    dbg_stat <= dbg_stat | dbg_stat1x;

	did_branchback <= take_branch;
	did_branchback0 <= take_branch0;
	did_branchback1 <= take_branch1;

`include "Thor_Retarget.v"
/*
	if (branchmiss) begin
		for (n = 1; n < NREGS; n = n + 1)
			if (rf_v[n] == `INV && ~livetarget[n]) begin
			  $display("brmiss: rf_v[%d] <= VAL",n);
			  rf_v[n] = `VAL;
			end

	    if (|iqentry_0_latestID[NREGS:1])	rf_source[ iqentry_tgt[0] ] <= { iqentry_mem[0], 3'd0 };
	    if (|iqentry_1_latestID[NREGS:1])	rf_source[ iqentry_tgt[1] ] <= { iqentry_mem[1], 3'd1 };
	    if (|iqentry_2_latestID[NREGS:1])	rf_source[ iqentry_tgt[2] ] <= { iqentry_mem[2], 3'd2 };
	    if (|iqentry_3_latestID[NREGS:1])	rf_source[ iqentry_tgt[3] ] <= { iqentry_mem[3], 3'd3 };
	    if (|iqentry_4_latestID[NREGS:1])	rf_source[ iqentry_tgt[4] ] <= { iqentry_mem[4], 3'd4 };
	    if (|iqentry_5_latestID[NREGS:1])	rf_source[ iqentry_tgt[5] ] <= { iqentry_mem[5], 3'd5 };
	    if (|iqentry_6_latestID[NREGS:1])	rf_source[ iqentry_tgt[6] ] <= { iqentry_mem[6], 3'd6 };
	    if (|iqentry_7_latestID[NREGS:1])	rf_source[ iqentry_tgt[7] ] <= { iqentry_mem[7], 3'd7 };

	end
*/
	if (ihit) begin
		$display("\r\n");
		$display("TIME %0d", $time);
	end
	
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
        if (!rf_v[ commit0_tgt ]) begin 
            rf_v[ commit0_tgt ] = (rf_source[ commit0_tgt ] == commit0_id) || ((branchmiss) && iqentry_source[ commit0_id[2:0] ]);
        end
        if (commit0_tgt != 8'd0) $display("r%d <- %h", commit0_tgt, commit0_bus);
end
if (commit1_v) begin
        if (!rf_v[ commit1_tgt ]) begin 
            rf_v[ commit1_tgt ] = (rf_source[ commit1_tgt ] == commit1_id)|| ((branchmiss) && iqentry_source[ commit1_id[2:0] ]);
        end
        if (commit1_tgt != 8'd0) $display("r%d <- %h", commit1_tgt, commit1_bus);
end

// This chunk of code has to be before the enqueue stage so that the agen bit
// can be reset to zero by enqueue.
// put results into the appropriate instruction entries
//
if ((alu0_op==`RR && (alu0_fn==`MUL || alu0_fn==`MULU)) || alu0_op==`MULI || alu0_op==`MULUI) begin
    if (alu0_done) begin
        alu0_dataready <= `TRUE;
    end
end
else if ((alu0_op==`RR && (alu0_fn==`DIV || alu0_fn==`DIVU || alu0_fn==`MOD || alu0_fn==`MODU)) ||
    alu0_op==`DIVI || alu0_op==`DIVUI || alu0_op==`MODI || alu0_op==`MODUI) begin
    if (alu0_done) begin
        alu0_dataready <= `TRUE;
    end
end

if (alu0_v) begin
	if (|alu0_exc) begin
    set_exception(alu0_id, alu0_exc);
    iqentry_a1[alu0_id[2:0]] <= alu0_bus;
  end
  else begin
    if (iqentry_op[alu0_id[2:0]]!=`IMM)
        iqentry_done[ alu0_id[2:0] ] <= (!iqentry_mem[ alu0_id[2:0] ] || !alu0_cmt);
    // if not committing alux_bus will equal alu_argT
    if (iqentry_jmpi[alu0_id[2:0]] && alu0_cmt)
      iqentry_res [alu0_id[2:0]] <= alu0_pc + alu0_insnsz;
    else
      iqentry_res	[ alu0_id[2:0] ] <= alu0_bus;
    iqentry_out	[ alu0_id[2:0] ] <= `FALSE;
    iqentry_cmt [ alu0_id[2:0] ] <= alu0_cmt;
    iqentry_agen[ alu0_id[2:0] ] <= `TRUE;
end
end


if (((alu1_op==`RR && (alu1_fn==`MUL || alu1_fn==`MULU)) || alu1_op==`MULI || alu1_op==`MULUI)) begin
    if (alu1_done) begin
        alu1_dataready <= `TRUE;
    end
end
else if (((alu1_op==`RR && (alu1_fn==`DIV || alu1_fn==`DIVU || alu1_fn==`MOD || alu1_fn==`MODU)) ||
    alu1_op==`DIVI || alu1_op==`DIVUI || alu1_op==`MODI || alu1_op==`MODUI)) begin
    if (alu1_done) begin
        alu1_dataready <= `TRUE;
    end
end

if (alu1_v) begin
	if (|alu1_exc) begin
    set_exception(alu1_id, alu1_exc);
    iqentry_a1[alu1_id[2:0]] <= alu1_bus;
  end
	else begin
    if (iqentry_op[alu1_id[2:0]]!=`IMM)
        iqentry_done[ alu1_id[2:0] ] <= (!iqentry_mem[ alu1_id[2:0] ] || !alu1_cmt);
     if (iqentry_jmpi[alu1_id[2:0]] && alu1_cmt)
        iqentry_res [alu1_id[2:0]] <= alu1_pc + alu1_insnsz;
     else
        iqentry_res [ alu1_id[2:0] ] <= alu1_bus;
    iqentry_out	[ alu1_id[2:0] ] <= `FALSE;
    iqentry_cmt [ alu1_id[2:0] ] <= alu1_cmt;
    iqentry_agen[ alu1_id[2:0] ] <= `TRUE;
end
end

`ifdef FLOATING_POINT
if (fp0_v) begin
	$display("0results to iq[%d]=%h", fp0_id[2:0],fp0_bus);
	if (|fp0_exc)
	    set_exception(fp0_id, fp0_exc);
	else begin
		iqentry_res	[ fp0_id[2:0] ] <= fp0_bus;
		iqentry_done[ fp0_id[2:0] ] <= fp0_done || !fp0_cmt;
		iqentry_out	[ fp0_id[2:0] ] <= `FALSE;
		iqentry_cmt [ fp0_id[2:0] ] <= fp0_cmt;
		iqentry_agen[ fp0_id[2:0] ] <= `TRUE;
	end
end
`endif

//-------------------------------------------------------------------------------
// ENQUEUE
//
// place up to three instructions from the fetch buffer into slots in the IQ.
//   note: they are placed in-order, and they are expected to be executed
// 0, 1, or 2 of the fetch buffers may have valid data
// 0, 1, or 2 slots in the instruction queue may be available.
// if we notice that one of the instructions in the fetch buffer is a predicted
// branch, (set branchback/backpc and delete any instructions after it in
// fetchbuf)
//
// We place the queue logic before the fetch to allow the tools to do the work
// for us. The fetch logic needs to know how many entries were queued, this is
// tracked in the queue stage by variables queued1,queued2,queued3. Blocking
// assignments are used for these vars.
//-------------------------------------------------------------------------------
//
    exception_set = `FALSE;
    queued1 = `FALSE;
    queued2 = `FALSE;
    queued1v = `FALSE;
    queued2v = `FALSE;
    allowq = `TRUE;
    qstomp = `FALSE;
    if (branchmiss) begin // don't bother doing anything if there's been a branch miss
        reset_tail_pointers(0);
        seqnum <= 8'h00;
    end
    else begin
        case ({fetchbuf0_v, fetchbuf1_v && fnNumReadPorts(fetchbuf1_instr) <=  ports_avail})
        2'b00: ; // do nothing
        2'b01:  enque1(tail0,1,0,1,vele,seqnum);
        2'b10:  enque0(tail0,1,0,1,vele,seqnum);
        2'b11:  begin
                enque0(tail0,1,1,1,vele,seqnum);
                if (allowq) begin
                    enque1(tail1,2,0,0,vele+1,seqnum+8'd1);
                end
                validate_args();
                end
        endcase
        if (queued2)
          seqnum <= seqnum + 8'd2;
        else if (queued1)
          seqnum <= seqnum + 8'd1;
`ifdef VECTOROPS
        // Once instruction is completely queued reset vector element count to zero.
        // Otherwise increment it according to the number of elements queued.
        if (queued1|queued2)
          vele <= 8'd0;
        else if (queued2v)
          vele <= vele + 2;
        else if (queued1v)
          vele <= vele + 1;
`endif
    end

//------------------------------------------------------------------------------
// FETCH
//
// fetch at least two instructions from memory into the fetch buffer unless
// either one of the buffers is still full, in which case we do nothing (kinda
// like alpha approach)
//------------------------------------------------------------------------------
//
if (branchmiss) begin
    $display("pc <= %h", misspc);
    pc <= misspc;
    if (intmiss && !pregset[3]) begin
      pregset <= {1'b1,regset};
      regset <= 3'd7;
    end
    else if (rtimiss) begin
      regset <= pregset[2:0];
      pregset[3] <= 1'b0;
    end
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
			    fetchCD();
				if (do_pcinc) pc[31:0] <= pc[31:0] + fnInsnLength(insn) + fnInsnLength1(insn);
				fetchbuf <= 1'b1;
			end
		4'b0100:
			begin
			    fetchCD();
				if (do_pcinc) pc[31:0] <= pc[31:0] + fnInsnLength(insn) + fnInsnLength1(insn);
				fetchbufB_v <= !queued1;
				if (queued1) begin
				    fetchbufB_instr <= 64'd0;
					fetchbuf <= 1'b1;
				end
				if (queued2|queued3)
				    panic <= `PANIC_INVALIDIQSTATE;
			end
		4'b0111:
			begin
				fetchbufB_v <= !queued1;
				if (queued1) begin
					fetchbuf <= 1'b1;
				    fetchbufB_instr <= 64'd0;
				end
				if (queued2|queued3)
                    panic <= `PANIC_INVALIDIQSTATE;
			end
		4'b1000:
			begin
			    fetchCD();
				if (do_pcinc) pc[31:0] <= pc[31:0] + fnInsnLength(insn) + fnInsnLength1(insn);
				fetchbufA_v <= !queued1;
				if (queued1) begin
					fetchbuf <= 1'b1;
				    fetchbufA_instr <= 64'd0;
				end
				if (queued2|queued3)
                    panic <= `PANIC_INVALIDIQSTATE;
			end
		4'b1011:
			begin
				fetchbufA_v <= !queued1;
				if (queued1) begin
					fetchbuf <= 1'b1;
				    fetchbufB_instr <= 64'd0;
			    end
				if (queued2|queued3)
                    panic <= `PANIC_INVALIDIQSTATE;
			end
		4'b1100: 
			// Note that there is no point to loading C,D here because
			// there is a predicted taken branch that would stomp on the
			// instructions anyways.
			if ((fnIsBranch(opcodeA) && predict_takenBr)||opcodeA==`LOOP) begin
				pc <= branch_pc;
				fetchbufA_v <= !(queued1|queued2);
				fetchbufB_v <= `INV;		// stomp on it
				// may as well stick with same fetchbuf
			end
			else begin
				if (did_branchback0) begin
				    fetchCD();
					if (do_pcinc) pc[31:0] <= pc[31:0] + fnInsnLength(insn) + fnInsnLength1(insn);
					fetchbufA_v <= !(queued1|queued2);
					fetchbufB_v <= !queued2;
					if (queued2)
						fetchbuf <= 1'b1;
				end
				else begin
					pc[ABW-1:0] <= branch_pc;
					fetchbufA_v <= !(queued1|queued2);
					fetchbufB_v <= !queued2;
					// may as well keep the same fetchbuffer
				end
			end
		4'b1111:
			begin
				fetchbufA_v <= !(queued1|queued2);
				fetchbufB_v <= !queued2;
				if (queued2) begin
					fetchbuf <= 1'b1;
				    fetchbufA_instr <= 64'd0;
				    fetchbufB_instr <= 64'd0;
			    end
			end
		default: panic <= `PANIC_INVALIDFBSTATE;
		endcase
	end
	else begin	// fetchbuf==1'b1
		case ({fetchbufC_v,fetchbufD_v,fetchbufA_v,fetchbufB_v})
		4'b0000:
			begin
			    fetchAB();
				if (do_pcinc) pc[31:0] <= pc[31:0] + fnInsnLength(insn) + fnInsnLength1(insn);
				fetchbuf <= 1'b0;
			end
		4'b0100:
			begin
			    fetchAB();
				if (do_pcinc) pc[31:0] <= pc[31:0] + fnInsnLength(insn) + fnInsnLength1(insn);
				fetchbufD_v <= !queued1;
				if (queued1)
					fetchbuf <= 1'b0;
				if (queued2|queued3)
                    panic <= `PANIC_INVALIDIQSTATE;
			end
		4'b0111:
			begin
				fetchbufD_v <= !queued1;
				if (queued1)
					fetchbuf <= 1'b0;
				if (queued2|queued3)
                    panic <= `PANIC_INVALIDIQSTATE;
			end
		4'b1000:
			begin
			    fetchAB();
				if (do_pcinc) pc[31:0] <= pc[31:0] + fnInsnLength(insn) + fnInsnLength1(insn);
				fetchbufC_v <= !queued1;
				if (queued1)
					fetchbuf <= 1'b0;
				if (queued2|queued3)
                    panic <= `PANIC_INVALIDIQSTATE;
			end
		4'b1011:
			begin
				fetchbufC_v <= !queued1;
				if (queued1)
					fetchbuf <= 1'b0;
				if (queued2|queued3)
                    panic <= `PANIC_INVALIDIQSTATE;
			end
		4'b1100:
			if ((fnIsBranch(opcodeC) && predict_takenBr)||opcodeC==`LOOP) begin
				pc <= branch_pc;
				fetchbufC_v <= !(queued1|queued2);
				fetchbufD_v <= `INV;		// stomp on it
				// may as well stick with same fetchbuf
			end
			else begin
				if (did_branchback1) begin
				    fetchAB();
					if (do_pcinc) pc[31:0] <= pc[31:0] + fnInsnLength(insn) + fnInsnLength1(insn);
					fetchbufC_v <= !(queued1|queued2);
					fetchbufD_v <= !queued2;
					if (queued2)
						fetchbuf <= 1'b0;
				end
				else begin
					pc[ABW-1:0] <= branch_pc;
					fetchbufC_v <= !(queued1|queued2);
					fetchbufD_v <= !queued2;
					// may as well keep the same fetchbuffer
				end
			end
		4'b1111:
			begin
				fetchbufC_v <= !(queued1|queued2);
				fetchbufD_v <= !queued2;
				if (queued2)
					fetchbuf <= 1'b0;
			end
		default: panic <= `PANIC_INVALIDFBSTATE;
		endcase
	end
end
else begin
	if (fetchbuf == 1'b0)
		case ({fetchbufA_v, fetchbufB_v})
		2'b00: ;
		2'b01: begin
			fetchbufB_v <= !(queued2|queued1);
			fetchbuf <= queued2|queued1;
			end
		2'b10: begin
			fetchbufA_v <= !(queued2|queued1);
			fetchbuf <= queued2|queued1;
			end
		2'b11: begin
			fetchbufA_v <= !(queued1|queued2);
			fetchbufB_v <= !queued2;
			fetchbuf <= queued2;
			end
		endcase
	else
		case ({fetchbufC_v, fetchbufD_v})
		2'b00:    ;
		2'b01: begin
			fetchbufD_v <= !(queued2|queued1);
			fetchbuf <= !(queued2|queued1);
			end
		2'b10: begin
			fetchbufC_v <= !(queued2|queued1);
			fetchbuf <= !(queued2|queued1);
			end
		2'b11: begin
			fetchbufC_v <= !(queued2|queued1);
			fetchbufD_v <= !queued2;
			fetchbuf <= !queued2;
			end
		endcase
	if (fetchbufA_v == `INV && fetchbufB_v == `INV) begin
	    fetchAB();
		if (do_pcinc) pc[31:0] <= pc[31:0] + fnInsnLength(insn) + fnInsnLength1(insn);
		// fetchbuf steering logic correction
		if (fetchbufC_v==`INV && fetchbufD_v==`INV && do_pcinc)
			fetchbuf <= 1'b0;
		$display("hit %b 1pc <= %h", do_pcinc, pc[31:0] + fnInsnLength(insn) + fnInsnLength1(insn));
	end
	else if (fetchbufC_v == `INV && fetchbufD_v == `INV) begin
	    fetchCD();
		if (do_pcinc) pc[31:0] <= pc[31:0] + fnInsnLength(insn) + fnInsnLength1(insn);
		$display("2pc <= %h", pc[31:0] + fnInsnLength(insn) + fnInsnLength1(insn));
	end
end

	if (ihit) begin
	$display("%h %h hit0=%b hit1=%b#", spc, pc, hit0, hit1);
	$display("insn=%h", insn);
	$display("%c insn0=%h insn1=%h", nmi_edge ? "*" : " ",insn0, insn1);
	$display("takb=%d br_pc=%h #", take_branch, branch_pc);
	$display("%c%c A: %d %h %h # %d",
	    45, fetchbuf?45:62, fetchbufA_v, fetchbufA_instr, fetchbufA_pc, fnInsnLength(fetchbufA_instr));
	$display("%c%c B: %d %h %h # %d",
	    45, fetchbuf?45:62, fetchbufB_v, fetchbufB_instr, fetchbufB_pc, fnInsnLength(fetchbufB_instr));
	$display("%c%c C: %d %h %h # %d",
	    45, fetchbuf?62:45, fetchbufC_v, fetchbufC_instr, fetchbufC_pc, fnInsnLength(fetchbufC_instr));
	$display("%c%c D: %d %h %h # %d",
	    45, fetchbuf?62:45, fetchbufD_v, fetchbufD_instr, fetchbufD_pc, fnInsnLength(fetchbufD_instr));
	$display("fetchbuf=%d",fetchbuf);
	end

//	if (ihit) begin
	for (i=0; i<QENTRIES; i=i+1) 
	    $display("%c%c %d: %c%c%c%c%c%c%c%c %d %c %c%h %d%s %h %h %h %c %o %h %c %o %h %c %o %h %c %o %h %h #",
		(i[2:0]==head0)?72:46, (i[2:0]==tail0)?84:46, i,
		iqentry_v[i]?"v":"-", iqentry_done[i]?"d":"-",
		iqentry_cmt[i]?"c":"-", iqentry_out[i]?"o":"-", iqentry_bt[i]?"b":"-", iqentry_memissue[i]?"m":"-",
		iqentry_agen[i]?"a":"-", iqentry_issue[i]?"i":"-",
		iqentry_islot[i],
//		((i==0) ? iqentry_0_islot : (i==1) ? iqentry_1_islot : (i==2) ? iqentry_2_islot : (i==3) ? iqentry_3_islot :
//		 (i==4) ? iqentry_4_islot : (i==5) ? iqentry_5_islot : (i==6) ? iqentry_6_islot : iqentry_7_islot),
		 iqentry_stomp[i] ? "s" : "-",
		(fnIsFlowCtrl(iqentry_op[i]) ? 98 : fnIsMem(iqentry_op[i]) ? 109 : 97), 
		iqentry_op[i],
		fnRegstr(iqentry_tgt[i]),fnRegstrGrp(iqentry_tgt[i]),
		iqentry_res[i], iqentry_a0[i],
		iqentry_a1[i], iqentry_a1_v[i]?"v":"-", iqentry_a1_s[i],
		iqentry_a2[i], iqentry_a2_v[i]?"v":"-", iqentry_a2_s[i],
		iqentry_a3[i], iqentry_a3_v[i]?"v":"-", iqentry_a3_s[i],
		iqentry_pred[i], iqentry_p_v[i]?"v":"-", iqentry_p_s[i],
		iqentry_pc[i],iqentry_sn[i]);
	$display("com0:%c%c %d r%d %h", commit0_v?"v":"-", iqentry_cmt[head0]?"c":"-", commit0_id, commit0_tgt, commit0_bus);
	$display("com1:%c%c %d r%d %h", commit1_v?"v":"-", iqentry_cmt[head1]?"c":"-", commit1_id, commit1_tgt, commit1_bus);
	
//	end
//`include "Thor_dataincoming.v"
// DATAINCOMING
//
// wait for operand/s to appear on alu busses and puts them into 
// the iqentry_a1 and iqentry_a2 slots (if appropriate)
// as well as the appropriate iqentry_res slots (and setting valid bits)
//
//
if (dram_v && iqentry_v[ dram_id[2:0] ] && iqentry_mem[ dram_id[2:0] ] ) begin	// if data for stomped instruction, ignore
	$display("dram results to iq[%d]=%h", dram_id[2:0],dram_bus);
	if (!iqentry_jmpi[dram_id[2:0]]) 
	   iqentry_res	[ dram_id[2:0] ] <= dram_bus;
	// If an exception occurred, stuff an interrupt instruction into the queue
	// slot. The instruction will re-issue as an ALU operation. We can change
	// the queued instruction because it isn't finished yet.
	if (|dram_exc) begin
	    set_exception(dram_id, dram_exc);
      $stop;
	end
	else begin
	    // Note that the predicate was already evaluated to TRUE before the
	    // dram operation started.
	    iqentry_cmt[dram_id[2:0]] <= `TRUE;
		iqentry_done[ dram_id[2:0] ] <= `TRUE;
		if ((iqentry_op[dram_id[2:0]]==`STS ||
		     iqentry_op[dram_id[2:0]]==`STCMP ||
		     iqentry_op[dram_id[2:0]]==`STMV ||
		     iqentry_op[dram_id[2:0]]==`STFND
		     ) && lc==64'd0) begin
			string_pc <= 64'd0;
		end
	end
end

// What if there's a databus error during the store ?
// set the IQ entry == DONE as soon as the SW is let loose to the memory system
//
if (dram0 == DS_SETUP && fnIsStore(dram0_op) && dram0_op != `STS && dram0_op != `STMV && dram0_op != `SWCR) begin
	if ((alu0_v && dram0_id[2:0] == alu0_id[2:0]) || (alu1_v && dram0_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram0_id[2:0] ] <= `TRUE;
	iqentry_cmt [ dram0_id[2:0]] <= `TRUE;
	iqentry_out[ dram0_id[2:0] ] <= `FALSE;
end
if (dram1 == DS_SETUP && fnIsStore(dram1_op) && dram1_op != `STS && dram1_op != `STMV && dram1_op != `SWCR) begin
	if ((alu0_v && dram1_id[2:0] == alu0_id[2:0]) || (alu1_v && dram1_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram1_id[2:0] ] <= `TRUE;
	iqentry_cmt [ dram1_id[2:0]] <= `TRUE;
	iqentry_out[ dram1_id[2:0] ] <= `FALSE;
end
if (dram2 == DS_SETUP && fnIsStore(dram2_op) && dram2_op != `STS && dram2_op != `STMV && dram2_op != `SWCR) begin
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
//  - mem_bus
//  - commit0_bus
//  - commit1_bus
//
setargs (alu0_id, alu0_v, alu0_bus);
setargs (alu1_id, alu1_v, alu1_bus);
`ifdef FLOATING_POINT
setargs (fp0_id, fp0_v, fp0_bus);
`endif
setargs (dram_id, dram_v, dram_bus);
setargs (commit0_id, commit0_v, commit0_bus);
setargs (commit1_id, commit1_v, commit1_bus);

for (n = 0; n < QENTRIES; n = n + 1)
begin
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==alu0_id && iqentry_v[n] == `VAL && alu0_v == `VAL) begin
		iqentry_pred[n] <= alu0nyb[iqentry_preg[n]];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n] == alu1_id && iqentry_v[n] == `VAL && alu1_v == `VAL) begin
		iqentry_pred[n] <= alu1nyb[iqentry_preg[n]];
		iqentry_p_v[n] <= `VAL;
	end
    // For SWCR
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==dram_id && iqentry_v[n] == `VAL && dram_v == `VAL) begin
		iqentry_pred[n] <= dram_bus[3:0];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n]==commit0_id && iqentry_v[n] == `VAL && commit0_v == `VAL) begin
		iqentry_pred[n] <= cmt0nyb[iqentry_preg[n]];
		iqentry_p_v[n] <= `VAL;
	end
	if (iqentry_p_v[n] == `INV && iqentry_p_s[n] == commit1_id && iqentry_v[n] == `VAL && commit1_v == `VAL) begin
		iqentry_pred[n] <= cmt1nyb[iqentry_preg[n]];
		iqentry_p_v[n] <= `VAL;
	end
end

//`include "Thor_issue.v"
// ISSUE 
//
// determines what instructions are ready to go, then places them
// in the various ALU queues.  
// also invalidates instructions following a branch-miss BEQ or any JALR (STOMP logic)
//
//alu0_dataready <= alu0_available && alu0_issue;
/*
			&& ((iqentry_issue[0] && iqentry_islot[0] == 4'd0 && !iqentry_stomp[0])
			 || (iqentry_issue[1] && iqentry_islot[1] == 4'd0 && !iqentry_stomp[1])
			 || (iqentry_issue[2] && iqentry_islot[2] == 4'd0 && !iqentry_stomp[2])
			 || (iqentry_issue[3] && iqentry_islot[3] == 4'd0 && !iqentry_stomp[3])
			 || (iqentry_issue[4] && iqentry_islot[4] == 4'd0 && !iqentry_stomp[4])
			 || (iqentry_issue[5] && iqentry_islot[5] == 4'd0 && !iqentry_stomp[5])
			 || (iqentry_issue[6] && iqentry_islot[6] == 4'd0 && !iqentry_stomp[6])
			 || (iqentry_issue[7] && iqentry_islot[7] == 4'd0 && !iqentry_stomp[7]));
*/
//alu1_dataready <= alu1_available && alu1_issue;
/* 
			&& ((iqentry_issue[0] && iqentry_islot[0] == 4'd1 && !iqentry_stomp[0])
			 || (iqentry_issue[1] && iqentry_islot[1] == 4'd1 && !iqentry_stomp[1])
			 || (iqentry_issue[2] && iqentry_islot[2] == 4'd1 && !iqentry_stomp[2])
			 || (iqentry_issue[3] && iqentry_islot[3] == 4'd1 && !iqentry_stomp[3])
			 || (iqentry_issue[4] && iqentry_islot[4] == 4'd1 && !iqentry_stomp[4])
			 || (iqentry_issue[5] && iqentry_islot[5] == 4'd1 && !iqentry_stomp[5])
			 || (iqentry_issue[6] && iqentry_islot[6] == 4'd1 && !iqentry_stomp[6])
			 || (iqentry_issue[7] && iqentry_islot[7] == 4'd1 && !iqentry_stomp[7]));
*/
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

for (n = 0; n < QENTRIES; n = n + 1)
begin
	if (iqentry_v[n] && iqentry_stomp[n]) begin
		iqentry_v[n] <= `INV;
		if (dram0_id[2:0] == n[2:0])	dram0 <= `DRAMSLOT_AVAIL;
		if (dram1_id[2:0] == n[2:0])	dram1 <= `DRAMSLOT_AVAIL;
		if (dram2_id[2:0] == n[2:0])	dram2 <= `DRAMSLOT_AVAIL;
	end
	else if (iqentry_issue[n]) begin
		case (iqentry_islot[n]) 
		2'd0: if (alu0_available && alu0_done) begin
			alu0_ld <= 1'b1;
			alu0_sourceid	<= n[3:0];
			alu0_insnsz <= iqentry_insnsz[n];
			alu0_op		<= iqentry_op[n];
			alu0_fn     <= iqentry_fn[n];
			alu0_cond   <= iqentry_cond[n];
			alu0_bt		<= iqentry_bt[n];
			alu0_pc		<= iqentry_pc[n];
			alu0_pred   <= iqentry_p_v[n] ? iqentry_pred[n] :
							(iqentry_p_s[n] == alu0_id) ? alu0nyb[iqentry_preg[n]] :
							(iqentry_p_s[n] == alu1_id) ? alu1nyb[iqentry_preg[n]] : 4'h0;
			alu0_argA	<= iqentry_a1_v[n] ? iqentry_a1[n]
						: (iqentry_a1_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a1_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			alu0_argB	<= iqentry_a2_v[n] ? iqentry_a2[n]
						: (iqentry_a2_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			alu0_argC	<=
`ifdef SEGMENTATION
                     ((iqentry_mem[n] && !iqentry_cmpmv[n]) || iqentry_lla[n]) ? ((SEGMODEL==2) ? 64'h00 : {sregs_base[iqentry_fn[n][5:3]],12'h000}):
`else			               
			               ((iqentry_mem[n] && !iqentry_cmpmv[n]) || iqentry_lla[n]) ? 64'd0 :
`endif			               
			               iqentry_a3_v[n] ? iqentry_a3[n]
						: (iqentry_a3_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a3_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			alu0_argT	<= iqentry_T_v[n] ? iqentry_T[n]
                        : (iqentry_T_s[n] == alu0_id) ? alu0_bus
                        : (iqentry_T_s[n] == alu1_id) ? alu1_bus
                        : 64'hDEADDEADDEADDEAD;
            alu0_argI	<= iqentry_a0[n];
            alu0_dataready <= fnAluValid(iqentry_op[n],iqentry_fn[n]);
    		iqentry_out[n] <= `TRUE;
			end
		2'd1: if (alu1_available && alu1_done) begin
			alu1_ld <= 1'b1;
			alu1_sourceid	<= n[3:0];
			alu1_insnsz <= iqentry_insnsz[n];
			alu1_op		<= iqentry_op[n];
			alu1_fn     <= iqentry_fn[n];
			alu1_cond   <= iqentry_cond[n];
			alu1_bt		<= iqentry_bt[n];
			alu1_pc		<= iqentry_pc[n];
			alu1_pred   <= iqentry_p_v[n] ? iqentry_pred[n] :
							(iqentry_p_s[n] == alu0_id) ? alu0nyb[iqentry_preg[n]] :
							(iqentry_p_s[n] == alu1_id) ? alu1nyb[iqentry_preg[n]] : 4'h0;
			alu1_argA	<= iqentry_a1_v[n] ? iqentry_a1[n]
                            : (iqentry_a1_s[n] == alu0_id) ? alu0_bus
                            : (iqentry_a1_s[n] == alu1_id) ? alu1_bus
                            : 64'hDEADDEADDEADDEAD;
			alu1_argB	<= iqentry_a2_v[n] ? iqentry_a2[n]
						: (iqentry_a2_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			alu1_argC	<=
`ifdef SEGMENTATION
                     ((iqentry_mem[n] && !iqentry_cmpmv[n]) || iqentry_lla[n]) ? ((SEGMODEL==2) ? 64'h00 : {sregs_base[iqentry_fn[n][5:3]],12'h000}):
//			               ((iqentry_mem[n] && !iqentry_cmpmv[n]) || iqentry_lla[n]) ? {sregs_base[iqentry_fn[n][5:3]],12'h000} :
`else			               
			               ((iqentry_mem[n] && !iqentry_cmpmv[n]) || iqentry_lla[n]) ? 64'd0 :
`endif			                
			               iqentry_a3_v[n] ? iqentry_a3[n]
						: (iqentry_a3_s[n] == alu0_id) ? alu0_bus
						: (iqentry_a3_s[n] == alu1_id) ? alu1_bus
						: 64'hDEADDEADDEADDEAD;
			alu1_argT	<= iqentry_T_v[n] ? iqentry_T[n]
                        : (iqentry_T_s[n] == alu0_id) ? alu0_bus
                        : (iqentry_T_s[n] == alu1_id) ? alu1_bus
                        : 64'hDEADDEADDEADDEAD;
            alu1_argI	<= iqentry_a0[n];
            alu1_dataready <= fnAluValid(iqentry_op[n],iqentry_fn[n]);
    		iqentry_out[n] <= `TRUE;
			end
		default: panic <= `PANIC_INVALIDISLOT;
		endcase
//		iqentry_out[n] <= `TRUE;
		// if it is a memory operation, this is the address-generation step ... collect result into arg1
		if (iqentry_mem[n] && !iqentry_tlb[n]) begin
			iqentry_a1_v[n] <= `INV;
			iqentry_a1_s[n] <= n[3:0];
		end
	end
end


`ifdef FLOATING_POINT
for (n = 0; n < QENTRIES; n = n + 1)
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
							(iqentry_p_s[n] == alu0_id) ? alu0nyb[iqentry_preg[n]] :
							(iqentry_p_s[n] == alu1_id) ? alu1nyb[iqentry_preg[n]] : 4'h0;
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
			fp0_argT	<= iqentry_T_v[n] ? iqentry_T[n]
                        : (iqentry_T_s[n] == alu0_id) ? alu0_bus
                        : (iqentry_T_s[n] == alu1_id) ? alu1_bus
                        : 64'hDEADDEADDEADDEAD;
      
			fp0_argI	<= iqentry_a0[n];
			end
		default: panic <= `PANIC_INVALIDISLOT;
		endcase
		iqentry_out[n] <= `TRUE;
	end
end
`endif

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
	dram_exc <= `EX_NONE;
	dram_bus <= tlb_dato;
	tlb_op <= 4'h0;
	tlb_state <= 3'd0;
end

case(dram0)
// The first state is to translate the virtual to physical address.
// Also a good spot to check for debug match and segment limit violation.
// Segmentation should check that the global segment is not used from 
// user mode ?
DS_XLAT:
	begin
		$display("0MEM %c:%h %h cycle started",fnIsStore(dram0_op)?"S" : "L", dram0_addr, dram0_data);
		if (dbg_lmatch|dbg_smatch) begin
		    dram_v <= `TRUE;
		    dram_id <= dram0_id;
		    dram_tgt <= dram0_tgt;
            dram_exc <= `EX_DBG;
            dram_bus <= 64'h0;
            dram0 <= DS_IDLE;
        end
`ifdef SEGMENTATION
        else if (dram0_op==`LLA || dram0_op==`LLAX) begin
          dram_v <= `TRUE;            // we are finished the memory cycle
          dram_id <= dram0_id;
          dram_tgt <= dram0_tgt;
          dram_exc <= `EX_NONE;
          dram_bus <= dram0_addr;
          dram0 <= DS_IDLE;
        end
`ifdef SEGLIMITS
        else if (dram0_addr[ABW-1:12] >= dram0_lmt) begin
            dram_v <= `TRUE;            // we are finished the memory cycle
            dram_id <= dram0_id;
            dram_tgt <= dram0_tgt;
            dram_exc <= `EX_SEGV;    //dram0_exc;
            dram_bus <= 64'h0;
            dram0 <= DS_IDLE;
        end
`endif
`endif
        else if (!cyc_o) dram0 <= DS_SETUP;
	end

// State 2:
// Check for a TLB miss on the translated address, and
// Initiate a bus transfer
DS_SETUP:
	if (DTLBMiss) begin
		dram_v <= `TRUE;			// we are finished the memory cycle
		dram_id <= dram0_id;
		dram_tgt <= dram0_tgt;
		dram_exc <= `EX_TLBMISS;	//dram0_exc;
		dram_bus <= 64'h0;
		dram0 <= DS_IDLE;
	end
	else if (dram0_exc!=`EXC_NONE) begin
		dram_v <= `TRUE;			// we are finished the memory cycle
        dram_id <= dram0_id;
        dram_tgt <= dram0_tgt;
        dram_exc <= dram0_exc;
		dram_bus <= 64'h0;
        dram0 <= DS_IDLE;
	end
	else begin
	    if (dram0_op==`LCL) begin
	       if (dram0_tgt==7'd0) begin
	           ic_invalidate_line <= `TRUE;
	           ic_lineno <= dram0_addr;
	       end
           dram0 <= DS_CACHE_READ;
	    end
		else if (uncached || fnIsStore(dram0_op) || fnIsLoadV(dram0_op) || dram0_op==`CAS ||
		  ((dram0_op==`STMV || dram0_op==`INC) && stmv_flag)) begin
    		if (cstate==IDLE) begin // make sure an instruction load isn't taking place
                dram0_owns_bus <= `TRUE;
                resv_o <= dram0_op==`LVWAR;
                cres_o <= dram0_op==`SWCR;
                lock_o <= dram0_op==`CAS;
//                cyc_o <= 1'b1;
                stb_o <= 1'b1;
                we_o <= fnIsStore(dram0_op) || ((dram0_op==`STMV || dram0_op==`INC) && stmv_flag);
                sel_o <= fnSelect(dram0_op,dram0_fn,pea);
                rsel <= fnSelect(dram0_op,dram0_fn,pea);
                adr_o <= pea;
                if (dram0_op==`INC)
                    dat_o <= fnDatao(dram0_op,dram0_fn,dram0_data) + index;
                else
                    dat_o <= fnDatao(dram0_op,dram0_fn,dram0_data);
                dram0 <= DS_CYC;
			end
		end
		else begin	// cached read
			dram0 <= DS_CACHE_READ;
            rsel <= fnSelect(dram0_op,dram0_fn,pea);
	   end
	end
DS_CYC:
  begin
    cyc_o <= 1'b1;
    dram0 <= DS_ACK;
  end
// Wait for a memory ack
DS_ACK:
	if (ack_i|err_i) begin
		$display("MEM ack");
		dram_v <= dram0_op != `CAS && dram0_op != `INC && dram0_op != `STS && dram0_op != `STMV && dram0_op != `STCMP && dram0_op != `STFND;
		dram_id <= dram0_id;
		dram_tgt <= dram0_tgt;
		dram_exc <= (err_i & (dram0_tgt!=7'd0 || !fnIsLoad(dram0_op))) ? `EX_DBE : `EX_NONE;//dram0_exc;
		if (dram0_op==`SWCR)
		     dram_bus <= {63'd0,resv_i};
		else
		     dram_bus <= fnDatai(dram0_op,dram0_fn,dat_i[DBW-1:0],rsel);
		dram0_owns_bus <= `FALSE;
		wb_nack();
        dram0 <= DS_FINAL;
		case(dram0_op)
`ifdef STRINGOPS
		`STS:
			if (lc != 0 && !int_pending) begin
				dram0_addr <= dram0_addr + fnIndexAmt(dram0_fn);
				lc <= lc - 64'd1;
				dram0 <= DS_XLAT;
//				dram_bus <= dram0_addr + fnIndexAmt(dram0_fn) - dram0_seg;
            end
            else begin
                dram_bus <= dram0_addr + fnIndexAmt(dram0_fn) - dram0_seg;
                dram_v <= `VAL;
                dram0_op <= `NOP;
            end
        `STMV,`STCMP:
            begin
                dram_bus <= index;
                if (lc != 0 && !(int_pending && stmv_flag)) begin 
                    dram0 <= DS_XLAT;
                    dram0_owns_bus <= `TRUE;
                    if (stmv_flag) begin
                        dram0_addr <= src_addr + index;
                        if (dram0_op==`STCMP) begin
                            if (dram0_data != fnDatai(dram0_op,dram0_fn,dat_i[DBW-1:0],rsel)) begin
                                lc <= 64'd0;
                                dram0 <= DS_FINAL;
                                dram_v <= `VAL;
                            end
                        end
                    end               
                    else begin
                        dram0_addr <= dst_addr + index;
                        dram0_data <= fnDatai(dram0_op,dram0_fn,dat_i[DBW-1:0],rsel);
                    end
                    if (!stmv_flag)
                        inc_index(dram0_fn);
                    stmv_flag <= ~stmv_flag;
                end
                else begin
                    dram_v <= `VAL;
                    dram0_op <= `NOP;
                end
            end
        `STFND:
            if (lc != 0 && !int_pending) begin 
                dram0_addr <= src_addr + index;
                inc_index(dram0_fn);
                if (dram0_data == fnDatai(dram0_op,dram0_fn,dat_i[DBW-1:0],rsel)) begin
                    lc <= 64'd0;
                    dram_v <= `VAL;
                    dram_bus <= index;
                end
                else
                    dram0 <= DS_XLAT;
            end
            else begin
                dram_bus <= index;
                dram_v <= `VAL;
                dram0_op <= `NOP;
            end
`endif
        `CAS:
			if (dram0_datacmp == dat_i[DBW-1:0]) begin
				$display("CAS match");
				dram0_owns_bus <= `TRUE;
				cyc_o <= 1'b1;	// hold onto cyc_o
				dram0 <= DS_CAS;
			end
			else begin
				dram_v <= `VAL;
				dram0 <= DS_IDLE;
		    end
		`INC:
		     begin
		         if (stmv_flag) begin
		             dram_v <= `VAL;
    				 dram0 <= DS_IDLE;
		         end
		         else begin
		             dram0_data <= fnDatai(dram0_op,dram0_fn,dat_i[DBW-1:0],rsel);
                     stmv_flag <= ~stmv_flag;
                     dram0 <= DS_XLAT;
		         end
		     end
		`NOP:
		      begin
	              dram_v <= `VAL;
                  dram0 <= DS_IDLE;
		      end
		default:  ;
		endcase
	end

// State 4:
// Start a second bus transaction for the CAS instruction
DS_CAS:
	begin
		stb_o <= 1'b1;
		we_o <= 1'b1;
		sel_o <= fnSelect(dram0_op,dram0_fn,pea);
		adr_o <= pea;
		dat_o <= fnDatao(dram0_op,dram0_fn,dram0_data);
		dram0 <= DS_CAS_ACK;
	end

// State 5:
// Wait for a memory ack for the second bus transaction of a CAS
//
DS_CAS_ACK:
    begin
        dram_id <= dram0_id;
        dram_tgt <= dram0_tgt;
        if (ack_i|err_i) begin
            $display("MEM ack2");
            dram_v <= `VAL;
            dram_exc <= (err_i & dram0_tgt!=7'd0) ? `EX_DBE : `EX_NONE;
            dram0_owns_bus <= `FALSE;
            wb_nack();
            lock_o <= 1'b0;
            dram0 <= DS_FINAL;
        end
    end

// State 6:
// Wait for a data cache read hit
DS_CACHE_READ:
	if (rhit && dram0_op!=`LCL) begin
	    case(dram0_op)
`ifdef STRINGOPS
	    // The read portion of the STMV was just done, go back and do
	    // the write portion.
        `STMV:
           begin
               stmv_flag <= `TRUE;
               dram0_addr <= dst_addr + index;
               dram0_data <= fnDatai(dram0_op,dram0_fn,cdat,rsel);
               dram0 <= DS_XLAT;
           end
        `STCMP:
            begin
                dram_bus <= index;
                dram_id <= dram0_id;
                dram_tgt <= dram0_tgt;
                if (lc != 0 && !int_pending && stmv_flag) begin
                    dram0_addr <= src_addr + index;
                    stmv_flag <= ~stmv_flag;
                    $display("*****************************");
                    $display("STCMP READ2:%H",fnDatai(dram0_op,dram0_fn,cdat,rsel));
                    $display("*****************************");
                    if (dram0_data != fnDatai(dram0_op,dram0_fn,cdat,rsel)) begin
                        lc <= 64'd0;
                        dram0 <= DS_FINAL;
                        dram_v <= `VAL;
                    end
                end
                else if (!stmv_flag) begin
                    stmv_flag <= ~stmv_flag;
                    dram0_addr <= dst_addr + index;
                    dram0_data <= fnDatai(dram0_op,dram0_fn,cdat,rsel);
                    $display("*****************************");
                    $display("STCMP READ1:%H",fnDatai(dram0_op,dram0_fn,cdat,rsel));
                    $display("*****************************");
                    dram0 <= DS_XLAT;
                    inc_index(dram0_fn);
                end
                else begin
                    dram_v <= `VAL;
                    dram0 <= DS_FINAL;
                    dram0_op <= `NOP;
                end
            end
        `STFND:
            begin
                dram_id <= dram0_id;
                dram_tgt <= dram0_tgt;
                dram_bus <= index;
                if (lc != 0 && !int_pending) begin 
                    dram0 <= DS_XLAT;
                    dram0_addr <= src_addr + index;
                    inc_index(dram0_fn);
                    if (dram0_data == fnDatai(dram0_op,dram0_fn,cdat,rsel)) begin
                        lc <= 64'd0;
                        dram0 <= DS_FINAL;
                        dram_v <= `VAL;
                    end
                end
                else begin
                    dram_v <= `VAL;              
                    dram0 <= DS_FINAL;
                    dram0_op <= `NOP;
                end
            end
`endif
		`INC:
             begin
                 dram0_data <= fnDatai(dram0_op,dram0_fn,cdat,rsel);
                 stmv_flag <= `TRUE;
                 dram0 <= DS_XLAT;
            end
        // Set to NOP on a string miss
        `NOP:   begin
                dram_v <= `VAL;
                dram0 <= DS_IDLE;
                end
    default: begin
            $display("Read hit [%h]",dram0_addr);
            dram_v <= `TRUE;
            dram_id <= dram0_id;
            dram_tgt <= dram0_tgt;
            dram_exc <= `EX_NONE;
            dram_bus <= fnDatai(dram0_op,dram0_fn,cdat,rsel);
            dram0 <= DS_IDLE;
            end
        endcase
	end
DS_FINAL:
    begin
    dram0 <= DS_IDLE;
    end
default:    dram0 <= DS_IDLE;
endcase

//
// determine if the instructions ready to issue can, in fact, issue.
// "ready" means that the instruction has valid operands but has not gone yet
//
// Stores can only issue if there is no possibility of a change of program flow.
// That means no flow control operations or instructions that can cause an
// exception can be before the store.
iqentry_memissue[ head0 ] <= iqentry_memissue_head0;
iqentry_memissue[ head1 ] <= iqentry_memissue_head1;
iqentry_memissue[ head2 ] <= iqentry_memissue_head2;
iqentry_memissue[ head3 ] <= iqentry_memissue_head3;
iqentry_memissue[ head4 ] <= iqentry_memissue_head4;
iqentry_memissue[ head5 ] <= iqentry_memissue_head5;
iqentry_memissue[ head6 ] <= iqentry_memissue_head6;
iqentry_memissue[ head7 ] <= iqentry_memissue_head7;
	
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
for (n = 0; n < QENTRIES; n = n + 1)
	if (!iqentry_stomp[n] && iqentry_memissue[n] && iqentry_agen[n] && iqentry_tlb[n] && !iqentry_out[n]) begin
	    $display("TLB issue");
	    if (!iqentry_cmt[n]) begin
	        iqentry_done[n] <= `TRUE;
	        iqentry_out[n] <= `FALSE;
	        iqentry_agen[n] <= `FALSE;
	        iqentry_res[n] <= iqentry_T_v[n] ? iqentry_T[n]
                        : (iqentry_T_s[n] == alu0_id) ? alu0_bus
                        : (iqentry_T_s[n] == alu1_id) ? alu1_bus
                        : 64'hDEADDEADDEADDEAD;
	    end
		else if (tlb_state==3'd0) begin
			tlb_state <= 3'd1;
			tlb_id <= {1'b1, n[2:0]};
			tlb_op <= iqentry_a0[n][3:0];
			tlb_regno <= iqentry_a0[n][7:4];
			tlb_tgt <= iqentry_tgt[n];
			tlb_data <= iqentry_a1[n];
			iqentry_out[n] <= `TRUE;
		end
	end
	else if (!iqentry_stomp[n] && iqentry_memissue[n] && iqentry_agen[n] && !iqentry_out[n]) begin
	    if (!iqentry_cmt[n]) begin
            iqentry_done[n] <= `TRUE;
            iqentry_out[n] <= `FALSE;
            iqentry_agen[n] <= `FALSE;
	        iqentry_res[n] <= iqentry_T_v[n] ? iqentry_T[n]
                        : (iqentry_T_s[n] == alu0_id) ? alu0_bus
                        : (iqentry_T_s[n] == alu1_id) ? alu1_bus
                        : 64'hDEADDEADDEADDEAD;
        end
        else begin
            if (fnIsStoreString(iqentry_op[n]))
                string_pc <= iqentry_pc[n];
            $display("issued memory cycle");
            if (dram0 == `DRAMSLOT_AVAIL) begin
                dram0 		<= DS_XLAT;
                dram0_id 	<= { 1'b1, n[2:0] };
                dram0_misspc <= iqentry_pc[n];
                dram0_op 	<= iqentry_op[n];
                dram0_fn    <= iqentry_fn[n];
                dram0_tgt 	<= iqentry_tgt[n];
                dram0_data	<= (iqentry_ndx[n] || iqentry_cas[n]) ? iqentry_a3[n] :
`ifdef STACKOPS                
                                iqentry_pea[n] ? iqentry_a2[n] + iqentry_a0[n] :
`endif
                                iqentry_a2[n];
                dram0_datacmp <= iqentry_a2[n];
`ifdef SEGMENTATION
                if (iqentry_cmpmv[n]) begin
                  if (SEGMODEL==2)
                    dram0_addr <= iqentry_a1[n][DBW-4:0] + {sregs_base[iqentry_a1[n][DBW-1:DBW-3]],12'h000};
                  else
                    dram0_addr <= iqentry_a1[n] + {sregs_base[iqentry_fn[n][5:3]],12'h000};
                end
                else begin
                    if (SEGMODEL==2)
                      dram0_addr <= iqentry_a1[n][DBW-4:0] + {sregs_base[iqentry_a1[n][DBW-1:DBW-3]],12'h000};
                    else
                      dram0_addr <= iqentry_a1[n];
                end
                if (SEGMODEL==2) begin
                  dram0_seg <= {sregs_base[iqentry_a1[n][DBW-1:DBW-3]],12'h000};
                  dram0_lmt <= sregs_base[iqentry_a1[n][DBW-1:DBW-3]] + sregs_lmt[iqentry_a1[n][DBW-1:DBW-3]];
                end
                else begin
                  dram0_seg <= {sregs_base[iqentry_fn[n][5:3]],12'h000};
                  dram0_lmt <= sregs_base[iqentry_fn[n][5:3]] + sregs_lmt[iqentry_fn[n][5:3]];
                end
//                dram0_exc <= (iqentry_a1[n][ABW-1:12] >= sregs_lmt[iqentry_fn[n][5:3]]) ? `EXC_SEGV : `EXC_NONE;
`ifdef STRINGOPS
                // String address must be in the same segment
                if (SEGMODEL==2) begin
                  src_addr <= iqentry_a1[n][DBW-4:0] + {sregs_base[iqentry_a1[n][DBW-1:DBW-3]],12'h000};
                  dst_addr <= iqentry_a2[n][DBW-4:0] + {sregs_base[iqentry_a1[n][DBW-1:DBW-3]],12'h000};
                end
                else begin                
                  src_addr <= iqentry_a1[n] + {sregs_base[iqentry_fn[n][5:3]],12'h000};
                  dst_addr <= iqentry_a2[n] + {sregs_base[iqentry_fn[n][5:3]],12'h000};
                end
`endif
`else
                dram0_addr <= iqentry_a1[n];
`ifdef STRINGOPS
                src_addr <= iqentry_a1[n];
                dst_addr <= iqentry_a2[n];
`endif
`endif
                stmv_flag <= `FALSE;
                index <= iqentry_op[n]==`STS ? fnIndexAmt(iqentry_fn[n]) : iqentry_op[n]==`INC ? iqentry_a2[n] : iqentry_a3[n];
                iqentry_out[n]	<= `TRUE;
            end
		end
	end

for (n = 0; n < QENTRIES; n = n + 1)
begin
    // It's better to check a sequence number here because if the code is in a
    // loop that such that the previous iteration of the loop is still in the
    // queue the PC could match when we don;t really want a prefix for that
    // iteration.
    if (iqentry_op[n]==`IMM && iqentry_v[(n+1)&7]
    && (iqentry_sn[(n+1)&7]==iqentry_sn[n]+12'd1))
    iqentry_done[n] <= `TRUE;
/*
    if (iqentry_op[n]==`IMM && iqentry_v[(n+1)&7] &&
        ((iqentry_pc[(n+1)&7]==iqentry_pc[n]+iqentry_insnsz[n]) ||
         (iqentry_pc[(n+1)&7]==iqentry_pc[n]))) // address inherited due to interrupt
        iqentry_done[n] <= `TRUE;
*/
    if (!iqentry_v[n])
        iqentry_done[n] <= `FALSE;
end
        

//	$display("TLB: en=%b imatch=%b pgsz=%d pcs=%h phys=%h", utlb1.TLBenabled,utlb1.IMatch,utlb1.PageSize,utlb1.pcs,utlb1.IPFN);
//	for (i = 0; i < 64; i = i + 1)
//		$display("vp=%h G=%b",utlb1.TLBVirtPage[i],utlb1.TLBG[i]);
//`include "Thor_commit.v"
// It didn't work in simulation when the following was declared under an
// independant always clk block
//
commit_spr(commit0_v,commit0_tgt,commit0_bus,0);
commit_spr(commit1_v,commit1_tgt,commit1_bus,1);
    
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
`ifdef PCHIST
	pc_cap <= `FALSE;
`endif
end

if (sys_commit)
begin
	if (StatusEXL!=8'hFF)
		StatusEXL <= StatusEXL + 8'd1;
end

// On a debug commit set status StatusDBG to prevent further single stepping.
`ifdef DEBUG_LOGIC
if (dbg_commit)
begin
    StatusDBG <= `TRUE;
end
`endif

oddball_commit(commit0_v,head0);
oddball_commit(commit1_v,head1);

//
// COMMIT PHASE (dequeue only ... not register-file update)
//
// If the third instruction is invalidated or if it doesn't update the register
// file then it is allowed to commit too.
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
		    head_inc(3);
		end
		else if (head0 != tail0 && head1 != tail0) begin
 		    head_inc(2);
		end
		else if (head0 != tail0) begin
		    head_inc(1);
		end

	// retire 2 (wait for regfile for head2)
	6'b0x_0x_10:
		begin
		    head_inc(2);
		end

	// retire 2 or 3 (wait for regfile for head2)
	6'b0x_0x_11:
	   begin
	        if (iqentry_tgt[head2]==7'd0) begin
	            iqentry_v[head2] <= `INV;
	            head_inc(3);
	        end
	        else begin
	            head_inc(2);
			end
		end

	// retire 3
	6'b0x_11_0x:
		if (head1 != tail0 && head2 != tail0) begin
			iqentry_v[head1] <= `INV;
			head_inc(3);
		end
		else begin
			iqentry_v[head1] <= `INV;
			head_inc(2);
		end

	// retire 2	(wait on head2 or wait on register file for head2)
	6'b0x_11_10:
		begin
			iqentry_v[head1] <= `INV;
			head_inc(2);
		end
	6'b0x_11_11:
        begin
            if (iqentry_tgt[head2]==7'd0) begin
                iqentry_v[head1] <= `INV;
                iqentry_v[head2] <= `INV;
                head_inc(3);
            end
            else begin
                iqentry_v[head1] <= `INV;
                head_inc(2);
            end
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
			head_inc(3);
		end
		else if (head1 != tail0) begin
			iqentry_v[head0] <= `INV;
			head_inc(2);
		end
		else begin
			iqentry_v[head0] <= `INV;
			head_inc(1);
		end

	// retire 2 (wait for regfile for head2)
	6'b11_0x_10:
		begin
			iqentry_v[head0] <= `INV;
			head_inc(2);
		end

	// retire 2 or 3 (wait for regfile for head2)
	6'b11_0x_11:
	    if (iqentry_tgt[head2]==7'd0) begin
			iqentry_v[head0] <= `INV;
			iqentry_v[head2] <= `INV;
			head_inc(3);
	    end
	    else begin
			iqentry_v[head0] <= `INV;
			head_inc(2);
		end

	//
	// retire 1 (stuck on head1)
	6'b00_10_xx,
	6'b01_10_xx,
	6'b11_10_xx:
		if (iqentry_v[head0] || head0 != tail0) begin
    	    iqentry_v[head0] <= `INV;
    	    head_inc(1);
		end

	// retire 2 or 3
	6'b11_11_0x:
		if (head2 != tail0) begin
			iqentry_v[head0] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
			iqentry_v[head1] <= `INV;
			head_inc(3);
		end
		else begin
			iqentry_v[head0] <= `INV;
			iqentry_v[head1] <= `INV;
			head_inc(2);
		end

	// retire 2 (wait on regfile for head2)
	6'b11_11_10:
		begin
			iqentry_v[head0] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
			iqentry_v[head1] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
			head_inc(2);
		end
	6'b11_11_11:
	    if (iqentry_tgt[head2]==7'd0) begin
            iqentry_v[head0] <= `INV;    // may conflict with STOMP, but since both are setting to 0, it is okay
            iqentry_v[head1] <= `INV;    // may conflict with STOMP, but since both are setting to 0, it is okay
            iqentry_v[head2] <= `INV;    // may conflict with STOMP, but since both are setting to 0, it is okay
            head_inc(3);
	    end
        else begin
            iqentry_v[head0] <= `INV;    // may conflict with STOMP, but since both are setting to 0, it is okay
            iqentry_v[head1] <= `INV;    // may conflict with STOMP, but since both are setting to 0, it is okay
            head_inc(2);
        end
endcase

	if (branchmiss)
		rrmapno <= iqentry_renmapno[missid];

	case(cstate)
	RESET1:
	   begin
	       ic_ld <= `TRUE;
	       ic_ld_cntr <= 32'd0;
	       cstate <= RESET2;
	   end
	RESET2:
	   begin
	       ic_ld_cntr <= ic_ld_cntr + 32'd32;
	       if (ic_ld_cntr >= 32'd32768) begin
	           ic_ld <= `FALSE;
	           ic_ld_cntr <= 32'd0;
	           cstate <= IDLE;
	       end;
	   end
	IDLE:
	  if (!ack_i) begin
      if (dcache_access_pending) begin
          $display("********************");
          $display("DCache access to: %h",{pea[DBW-1:4],4'b0000});
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
      else if ((!ihit && !mem_issue && dram0==DS_IDLE)||(dram0==DS_CACHE_READ && (dram0_op==`LCL && dram0_tgt==7'd0))) begin
        if ((dram0!=2'd0 || dram1!=2'd0 || dram2!=2'd0) && !(dram0==DS_CACHE_READ && (dram0_op==`LCL && dram0_tgt==7'd0)))
          $display("drams non-zero");
        else begin
          $display("********************");
          $display("ICache access to: %h",
              (dram0==DS_CACHE_READ && (dram0_op==`LCL && dram0_tgt==7'd0)) ? {dram0_addr[ABW-1:5],5'h00} : 
              !hit0 ? {ppc[DBW-1:5],5'b00000} : {ppcp16[DBW-1:5],5'b00000});
          $display("********************");
          ierr <= 1'b0;
          bte_o <= 2'b00;
          cti_o <= 3'b001;
          bl_o <= DBW==32 ? 5'd7 : 5'd3;
          cyc_o <= 1'b1;
          stb_o <= 1'b1;
          we_o <= 1'b0;
          sel_o <= {DBW/8{1'b1}};
          adr_o <= (dram0==DS_CACHE_READ && (dram0_op==`LCL && dram0_tgt==7'd0)) ? {dram0_addr[ABW-1:5],5'h00} : !hit0 ? {ppc[DBW-1:5],5'b00000} : {ppcp16[DBW-1:5],5'b00000};
          dat_o <= {DBW{1'b0}};
          idblmiss <= !hit0 && !hit1 && ppc[DBW-1:5] != ppcp16[DBW-1:5];
          cstate <= ICACHE1;
        end
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
					if (cti_o==3'b111) begin
						wb_nack();
						cstate <= idblmiss ? ICACHE2 : IDLE;
						if (dram0==DS_CACHE_READ && dram0_op==`LCL) begin
						     dram0_op<=`NOP;
						end
					end
				end
				else begin
					adr_o[4:3] <= adr_o[4:3] + 2'd1;
					if (adr_o[4:3]==2'b10)
						cti_o <= 3'b111;
					if (cti_o==3'b111) begin
						wb_nack();
						cstate <= IDLE;
						if (dram0==DS_CACHE_READ && dram0_op==`LCL) begin
                             dram0_op<=`NOP;
                        end
					end
				end
			end
		end
	ICACHE2:
	 if (!ack_i) begin
	   idblmiss <= 1'b0;
     cti_o <= 3'b001;
     bl_o <= DBW==32 ? 5'd7 : 5'd3;
     cyc_o <= 1'b1;
     stb_o <= 1'b1;
     we_o <= 1'b0;
     sel_o <= {DBW/8{1'b1}};
     adr_o <= {ppcp16[DBW-1:5],5'b00000};
	   cstate <= ICACHE1;
	  end
	DCACHE1:
		begin
			if (ack_i|err_i) begin
				derr <= derr | err_i;	// cumulate an error status
				if (DBW==32) begin
					adr_o[4:2] <= adr_o[4:2] + 3'd1;
					if (adr_o[4:2]==3'b110)
						cti_o <= 3'b111;
					if (cti_o==3'b111) begin
						wb_nack();
						cstate <= IDLE;
						if (dram0_op==`LCL) begin
						    dram0_op <= `NOP;
						    dram0_tgt <= 7'd0;
						end
					end
				end
				else begin
					adr_o[4:3] <= adr_o[4:3] + 2'd1;
					if (adr_o[4:3]==2'b10)
						cti_o <= 3'b111;
					if (cti_o==3'b111) begin
						wb_nack();
						cstate <= IDLE;
						if (dram0_op==`LCL) begin
						    dram0_op <= `NOP;
						    dram0_tgt <= 7'd0;
					    end
					end
				end
			end
		end
    default:    cstate <= IDLE;
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
    resv_o <= 1'b0;
    cres_o <= 1'b0;
	bte_o <= 2'b00;
	cti_o <= 3'b000;
	bl_o <= 5'd0;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 8'h00;
	//adr_o <= {DBW{1'b0}};
	//dat_o <= {DBW{1'b0}};
end
endtask

task commit_spr;
input commit_v;
input [7:0] commit_tgt;
input [DBW-1:0] commit_bus;
input which;
begin
if (commit_v && commit_tgt[7:6]==2'h1) begin
    casex(commit_tgt[5:0])
    6'b00xxxx:  begin
                pregs[commit_tgt[3:0]] <= which ? cmt1nyb[commit_tgt[3:0]] : cmt0nyb[commit_tgt[3:0]];//commit_bus[3:0];
	            $display("pregs[%d]<=%h", commit_tgt[3:0], commit_bus[3:0]);
//	            $stop;
                end
    6'b01xxxx:  begin
                cregs[commit_tgt[3:0]] <= commit_bus;
	            $display("cregs[%d]<=%h", commit_tgt[3:0], commit_bus);
	           end
`ifdef SEGMENTATION    
    6'b100xxx:  begin
                sregs[{1'b0,commit_tgt[2:0]}] <= commit_bus[31:0];
	            $display("sregs[%d]<=%h", commit_tgt[2:0], commit_bus);
	            end
	6'b101000:  sregs[{1'b1,commit_tgt[2:0]}] <= commit_bus[31:0];
	6'b101001:  GDT <= commit_bus;
	6'b101011:  segsw <= commit_bus[4:0];  
	6'b101100:  sregs_base[segsw] <= commit_bus[DBW-1:12];
	6'b101101:  sregs_lmt[segsw] <= commit_bus[DBW-1:12];
	6'b101111:  sregs_acr[segsw] <= commit_bus[15:0];
`endif
    6'b110000:
        begin
        pregs[0] <= commit_bus[3:0];
        pregs[1] <= commit_bus[7:4];
        pregs[2] <= commit_bus[11:8];
        pregs[3] <= commit_bus[15:12];
        pregs[4] <= commit_bus[19:16];
        pregs[5] <= commit_bus[23:20];
        pregs[6] <= commit_bus[27:24];
        pregs[7] <= commit_bus[31:28];
        if (DBW==64) begin
            pregs[8] <= commit_bus[35:32];
            pregs[9] <= commit_bus[39:36];
            pregs[10] <= commit_bus[43:40];
            pregs[11] <= commit_bus[47:44];
            pregs[12] <= commit_bus[51:48];
            pregs[13] <= commit_bus[55:52];
            pregs[14] <= commit_bus[59:56];
            pregs[15] <= commit_bus[63:60];
        end
        end
    `LCTR:  begin    lc <= commit_bus; $display("LC <= %h", commit_bus); end
	`ASID:	    asid <= commit_bus;
`ifdef VECTOROPS
	`VL:      VL <= commit_bus;
`endif
    `SR:    begin
            GM <= commit_bus[7:0];
            regset <= commit_bus[10:8];
            pregset <= commit_bus[26:24];
            GMB <= commit_bus[23:16];
            imb <= commit_bus[31];
            fxe <= commit_bus[12];
            pfxe <= commit_bus[28];
            if (commit_bus[15])
                im <= 1'b1;
            else
                imcd <= IMCD;
            end
    6'd60:  spr_bir <= commit_bus[11:0];
    6'd61:
            case(spr_bir[5:0])
            6'd0:   dbg_adr0 <= commit_bus;  
            6'd1:   dbg_adr1 <= commit_bus;  
            6'd2:   dbg_adr2 <= commit_bus;  
            6'd3:   dbg_adr3 <= commit_bus;  
            6'd4:   dbg_ctrl <= commit_bus;
            6'd5:   dbg_stat <= commit_bus;
`ifdef PCHIST
            6'd18:  pc_ndx <= commit_bus[5:0];
`endif
            default:    ;
            endcase
    6'b111111:
            begin
                ld_clk_throttle <= `TRUE;
                clk_throttle_new <= commit_bus[15:0];
            end
    default:    ;
    endcase
end
end
endtask

// For string memory operations.
// Indexing amount, should synth to a ROM.
//
function [63:0] fnIndexAmt;
input [5:0] fn;
begin
    case(fn[2:0])
    3'd0:   fnIndexAmt = 64'd1;
    3'd1:   fnIndexAmt = 64'd2;
    3'd2:   fnIndexAmt = 64'd4;
    3'd3:   fnIndexAmt = 64'd8;
    3'd4:   fnIndexAmt = 64'd1;
    3'd5:   fnIndexAmt = 64'd2;
    3'd6:   fnIndexAmt = 64'd4;
    3'd7:   fnIndexAmt = 64'd8;
    endcase
end
endfunction


// For string memory operations.
//
task inc_index;
input [5:0] fn;
begin
    index <= index + fnIndexAmt(fn);
    lc <= lc - 64'd1;    
end
endtask

function [DBW-1:0] fnSpr;
input [5:0] regno;
input [63:0] epc;
begin
    // Read from the special registers unless overridden by the
    // value on the commit bus.
    casex(regno)
    6'b00xxxx:  fnSpr = {DBW/4{pregs[regno[3:0]]}};
    6'b01xxxx:  case(regno[3:0])
                4'd0: fnSpr = 64'd0;
                4'd15: fnSpr = epc;
                default: fnSpr = cregs[regno[3:0]];
                endcase
`ifdef SEGMENTATION
    6'b100xxx:  fnSpr = sregs[{1'b0,regno[2:0]}];
    6'b101000:  fnSpr = sregs[{1'b1,regno[2:0]}];
    6'b101001:  fnSpr = GDT;
    6'b101100:  fnSpr = {sregs_base[segsw],12'h000};
    6'b101101:  fnSpr = {sregs_lmt[segsw],12'h000}; // Modify for SS limits ??? (get rid of 12'h000
    6'b101111:  fnSpr = sregs_acr[segsw];
`endif
    6'b110000:  if (DBW==64)
                fnSpr = {pregs[15],pregs[14],pregs[13],pregs[12],
                         pregs[11],pregs[10],pregs[9],pregs[8],
                         pregs[7],pregs[6],pregs[5],pregs[4],
                         pregs[3],pregs[2],pregs[1],pregs[0]};
                else
                fnSpr = {pregs[7],pregs[6],pregs[5],pregs[4],
                         pregs[3],pregs[2],pregs[1],pregs[0]};
    `TICK:      fnSpr = tick;                    
    `LCTR:      fnSpr = lc;
    `ASID:      fnSpr = asid;
`ifdef VECTOROPS
    `VL:    fnSpr = VL;
`endif 
    `SR:    begin
            fnSpr = 8'h0;
            fnSpr[7:0] = GM;
            fnSpr[10:8] = regset;
            fnSpr[23:16] = GMB;
            fnSpr[26:24] = pregset;
            fnSpr[31] = imb;
            fnSpr[15] = im;
            fnSpr[12] = fxe;
            fnSpr[28] = pfxe;
            end
    `ARG1:  fnSpr = intarg1;
    6'd60:  fnSpr = spr_bir;
    6'd61:
            casex(spr_bir[5:0])
            6'd0:   fnSpr = dbg_adr0;  
            6'd1:   fnSpr = dbg_adr1;  
            6'd2:   fnSpr = dbg_adr2;  
            6'd3:   fnSpr = dbg_adr3;  
            6'd4:   fnSpr = dbg_ctrl;
            6'd5:   fnSpr = dbg_stat;
`ifdef PCHIST            
            6'd16:  fnSpr = pc_histo[31:0];
            6'd17:  fnSpr = pc_histo[63:31];
`endif            
            default:    fnSpr = 64'd0;
            endcase
    `IVNO:  fnSpr = ivno; // 62
    default:    fnSpr = 64'd0;
    endcase
// Not sure why bother read the commit bus here ? Why not the alu bus as well ?
// Need bypassing for write-through register file, reg read at same time as write
// Shaves a clock cycle off register updates. rf_v is being set valid on the
// clock cycle of the commit.   
    // If an spr is committing...
    if (commit0_v && commit0_tgt=={1'b1,regno}) begin
        if (regno[5:4]==2'b00) begin
            if (DBW==32)
                fnSpr = {8{cmt0nyb[regno[2:0]]}};
            else
                fnSpr = {16{cmt0nyb[regno[3:0]]}};
        end
        else
            fnSpr = commit0_bus;
    end
    if (commit1_v && commit1_tgt=={1'b1,regno}) begin
        if (regno[5:4]==2'b00) begin
            if (DBW==32)
                fnSpr = {8{cmt1nyb[regno[2:0]]}};
            else
                fnSpr = {16{cmt1nyb[regno[3:0]]}};
        end
        else
            fnSpr = commit1_bus;
    end
 
    // Special cases where the register would not be read from the commit bus
    case(regno)
    `TICK:      fnSpr = tick;
    6'b010000:  fnSpr = 64'd0;  // code address zero
    6'b011111:  fnSpr = epc;    // current program counter from fetchbufx_pc
    default:    ;
    endcase
end
endfunction

// "oddball" instruction commit cases.
//
task oddball_commit;
input commit_v;
input [2:0] head;
begin
    if (commit_v)
        case(iqentry_op[head])
        `INT: begin
              intarg1 <= iqentry_a1[head];
              ivno <= iqentry_imm[head];
              //pregset <= regset;
              //regset <= 4'd7;
              end
        `SYS: ivno <= iqentry_imm[head];
        `CLI:	begin imcd <= IMCD; imb <= 1'b0; end
        `SEI:	begin im <= 1'b1; imb <= 1'b1; end
        // When the RTI instruction commits clear the hardware interrupt status to enable interrupts.
        `RTI:	begin
                //regset <= pregset;
                StatusHWI <= `FALSE;
                if (imb)
                    im <= 1'b1;
                else
                    imcd <= IMCD;
                end
        `RTD:
                begin
                    StatusDBG <= `FALSE;
                    if (StatusEXL!=8'h00)
                        StatusEXL <= StatusEXL - 8'd1;
                end
        `RTE:
                begin
                    if (StatusEXL!=8'h00)
                        StatusEXL <= StatusEXL - 8'd1;
                end
        `CACHE:
               begin
                   case(iqentry_fn[head])
                   6'd0:   ic_invalidate <= `TRUE;
                   6'd1:   begin
                           ic_invalidate_line <= `TRUE;
`ifdef SEGMENTATION                      
                           ic_lineno <= iqentry_a1[head][DBW-4:0]  + {sregs_base[3'd7],12'h000};
`else
                           ic_lineno <= iqentry_a1[head];
`endif                           
                           end
                   6'd32:  dc_invalidate <= `TRUE;
                   6'd33:  begin
                           dc_invalidate_line <= `TRUE;
`ifdef SEGMENTATION                           
                           if (SEGMODEL==2)
                            dc_lineno <= iqentry_a1[head][DBW-4:0] + {sregs_base[iqentry_a1[head][DBW-1:DBW-3]],12'h000};
                           else 
                            dc_lineno <= iqentry_a1[head] + {sregs_base[iqentry_fn[head][5:3]],12'h000};
`else
                           dc_lineno <= iqentry_a1[head];
`endif                           
                           end
                   default: ;   // do nothing
                   endcase
               end
        default:	;
        endcase
end
endtask

// The exception_set var is used to reduce the number of logic levels. Rather
// than having an if/elseif tree for all the exceptional conditions that are
// trapped. The exception_set var tracks these excaptions and reduces the
// tree to a single if.
task enque0a;
input [2:0] tail;
input [2:0] inc;
input unlink;
input [2:0] vel;
input [11:0] sn;
begin
    if (fetchbuf0_pc==32'h0)
        $stop;
    if (fetchbuf0_pc==32'hF44)
        $stop;
    if (fetchbuf0_pc==32'hFFFC275A)
        $stop;
`ifdef SEGMENTATION
`ifdef SEGLIMITS
    // If segment limit exceeded and not in the non-segmented area.
    if (fetchbuf0_pc >= {sregs_lmt[3'd7],12'h000} && fetchbuf0_pc[ABW-1:ABW-4]!=4'hF)
        set_exception(tail,`EX_SEGV);
`endif
`endif
    // If targeting a kernel mode register and not in kernel mode.
    // But okay if it is an SYS or INT instruction.
    if (fnIsKMOnlyReg(Rt0) && !km && !(opcode0==`SYS || opcode0==`INT))
        set_exception(tail,`EX_PRIV);
    // If attempting to use an undefined instruction
`ifdef TRAP_ILLEGALOPS
    if (fnIsIllegal(opcode0,opcode0==`MLO ? rfoc0[5:0] : fnFunc(fetchbuf0_instr)))
        set_exception(tail,9'd250);
`endif
`ifdef DEBUG_LOGIC
    if (dbg_ctrl[0] && dbg_ctrl[17:16]==2'b00 && fetchbuf0_pc==dbg_adr0)
        dbg_imatchA0 = `TRUE;
    if (dbg_ctrl[1] && dbg_ctrl[21:20]==2'b00 && fetchbuf0_pc==dbg_adr1)
        dbg_imatchA1 = `TRUE;
    if (dbg_ctrl[2] && dbg_ctrl[25:24]==2'b00 && fetchbuf0_pc==dbg_adr2)
        dbg_imatchA2 = `TRUE;
    if (dbg_ctrl[3] && dbg_ctrl[29:28]==2'b00 && fetchbuf0_pc==dbg_adr3)
        dbg_imatchA3 = `TRUE;
    if (dbg_imatchA0|dbg_imatchA1|dbg_imatchA2|dbg_imatchA3)
        dbg_imatchA = `TRUE;
    if (dbg_imatchA)
        set_exception(tail,9'd243); // Debug exception
`endif
    if (!exception_set) begin
        interrupt_pc =
            // If the previous instruction was an interrupt, then inherit the address 
            (iqentry_op[(tail-3'd1)&7]==`INT && iqentry_v[(tail-3'd1)&7]==`VAL && iqentry_tgt[(tail-3'd1)&7][3:0]==4'hE) ?
            (string_pc != 0 ? string_pc : iqentry_pc[(tail-3'd1)&7]) :
            // Otherwise inherit the address of any preceding immediate prefix.
            (iqentry_op[(tail-3'd1)&7]==`IMM && iqentry_v[(tail-3'd1)&7]==`VAL) ?
                (string_pc != 0 ? string_pc : iqentry_pc[(tail-3'd1)&7]) :
            // Otherwise use the address of the interrupted instruction
            (string_pc != 0 ? string_pc : fetchbuf0_pc);
    iqentry_sn   [tail]    <=    sn;
    iqentry_v    [tail]    <=   `VAL;
    iqentry_done [tail]    <=   `INV;
    iqentry_cmt  [tail]    <=   `TRUE;
    iqentry_out  [tail]    <=   `INV;
    iqentry_res  [tail]    <=   `ZERO;
    iqentry_insnsz[tail]   <=  fnInsnLength(fetchbuf0_instr);
    iqentry_op   [tail]    <=   opcode0; 
    iqentry_fn   [tail]    <=   opcode0==`MLO ? rfoc0[5:0] : fnFunc(fetchbuf0_instr);
    iqentry_cond [tail]    <=   cond0;
    iqentry_bt   [tail]    <=   fnIsFlowCtrl(opcode0) && predict_taken0;
    iqentry_br   [tail]    <=   opcode0[7:4]==`BR;
    iqentry_agen [tail]    <=   `INV;
    iqentry_pc   [tail]    <=   (opcode0==`INT && Rt0[3:0]==4'hE) ? interrupt_pc : fetchbuf0_pc;
    iqentry_mem  [tail]    <=   fetchbuf0_mem;
    iqentry_vec  [tail]    <=   fetchbuf0_vec;
    iqentry_ndx  [tail]    <=   fnIsIndexed(opcode0);
    iqentry_cas  [tail]    <=   opcode0==`CAS;
    iqentry_pushpop[tail]  <=   opcode0==`PUSH || opcode0==`POP;
    iqentry_pea  [tail]    <=   opcode0==`PEA;
    iqentry_cmpmv[tail]    <=   opcode0==`STCMP || opcode0==`STMV;
    iqentry_lla  [tail]    <=   opcode0==`LLA || opcode0==`LLAX;
    iqentry_tlb  [tail]    <=   opcode0==`TLB;
    iqentry_jmp  [tail]    <=   fetchbuf0_jmp;
    iqentry_jmpi [tail]    <=   opcode0==`JMPI || opcode0==`JMPIX;
    iqentry_sync [tail]    <=   opcode0==`SYNC;
    iqentry_memsb[tail]    <=   opcode0==`MEMSB;
    iqentry_memdb[tail]    <=   opcode0==`MEMDB;
    iqentry_fp   [tail]    <=   fetchbuf0_fp;
    iqentry_rfw  [tail]    <=   fetchbuf0_rfw;
    iqentry_tgt  [tail]    <=   Rt0;
    iqentry_preg [tail]    <=   Pn0;
    // Need the bypassing on the preg file for write-through register effect.
    iqentry_pred [tail]    <=   fnSpr({2'h0,Pn0},fetchbuf0_pc);//pregs[Pn0];
    // Look at the previous queue slot to see if an immediate prefix is enqueued
    iqentry_a0[tail]   <=
`ifdef VECTOROPS
          (opcode0==`LVX || opcode0==`SVX) ? {vel,3'b0} :
`endif
          (opcode0==`INT || opcode0==`SYS || opcode0==`RTF || opcode0==`JSF) ? fnImm(fetchbuf0_instr) :
          fnIsBranch(opcode0) ? {{DBW-12{fetchbuf0_instr[11]}},fetchbuf0_instr[11:8],fetchbuf0_instr[23:16]} : 
          (iqentry_op[(tail-3'd1)&7]==`IMM && iqentry_v[tail-3'd1]) ? {iqentry_a0[(tail-3'd1)&7][DBW-1:8],fnImm8(fetchbuf0_instr)}:
          opcode0==`IMM ? fnImmImm(fetchbuf0_instr) :
          fnImm(fetchbuf0_instr);
                          
    // These register recordings for simulation debug. They should be stripped
    // out of synthesis because they don't drive any signals.
`ifdef SIMULATION    
    iqentry_r1   [tail]    <=   Ra0;
    iqentry_r2   [tail]    <=   Rb0;
    iqentry_r3   [tail]    <=   Rc0;
    iqentry_rt   [tail]    <=   Rt0;
`endif
    iqentry_a1   [tail]    <=   fnOpa(opcode0,Ra0,fetchbuf0_instr,rfoa0,fetchbuf0_pc);
    iqentry_a2   [tail]    <=   fnOpb(opcode0,Rb0,fetchbuf0_instr,rfob0,pvrfoa0,fetchbuf0_pc);   
    iqentry_a3   [tail]    <=   fetchbuf0_vec ? pvrfob0 : rfoc0;
    iqentry_T    [tail]    <=   fnOpt(Rt0,rfot0,vrfot0,fetchbuf0_pc);
    // The source is set even though the arg might be automatically valid (less logic).
    // This is harmless to do. Note there is no source for the 'I' argument.
    iqentry_p_s  [tail]    <=   rf_source[{1'b1,2'h0,Pn0}];
    iqentry_a1_s [tail]    <=   //unlink ? {1'b0, (tail-1)&7} :
                                rf_source[Ra0];
    iqentry_a2_s [tail]    <=   rf_source[Rb0];
    iqentry_a3_s [tail]    <=   rf_source[Rc0];
`ifdef VECTOROPS
    iqentry_a4   [tail]    <=   pvrfoc0;
    iqentry_a4_s [tail]    <=   rf_source[Rd0];
`endif
    iqentry_T_s  [tail]    <=   rf_source[Rt0];

    // Always do this because it's the first queue slot.
    validate_args10(tail);
    end
    tail0 <= tail0 + inc;
    tail1 <= tail1 + inc;
    tail2 <= tail2 + inc;
    // If it's a vector instruction it isn't finished queuing until all the elements
    // have queued. We still need to know however when each element queues so that
    // the element counter can be incremented.
    // Note that the element can't be queued until the vector length is known which
    // is always found in a1.
`ifdef VECTOROPS
    if (fetchbuf0_vec) begin
      if (fnVecL(fetchbuf0_instr) begin
        queued1v = `VAL;
        queued1 = vel >= VL[6:0];
        // We set allowq to FALSE to disallow a second instruction queue if a vector instruction
        // is being queued.
        allowq = `FALSE;
      end
      // For a specific element we need to wait until after the ele is set and
      // the register file has a chance to be read.
      else begin
        ele <= iqentry_a1[tail];
        queued1 = iqentry_a1_v[tail];
      end
    end
    else
`endif
    begin
      queued1 = `TRUE;
    end
    rrmapno <= rrmapno + 3'd1;
end
endtask

task enquePushpopAdd;
input [2:0] tail;
input pushpop;
input link;
input unlink;
input which;
begin
    $display("Pushpop add");
    iqentry_v    [tail]    <=   `VAL;
    iqentry_done [tail]    <=   `INV;
    iqentry_cmt  [tail]    <=   `TRUE;
    iqentry_out  [tail]    <=   `INV;
    iqentry_res  [tail]    <=   64'd0;
    iqentry_insnsz[tail]   <=   4'd0;
    iqentry_op   [tail]    <=   `ADDUI; 
    iqentry_fn   [tail]    <=   6'b0;
    iqentry_cond [tail]    <=   which ? cond1 :cond0;
    iqentry_bt   [tail]    <=   1'b0; 
    iqentry_agen [tail]    <=   `INV;
    iqentry_pc   [tail]    <=   which ? fetchbuf1_pc : fetchbuf0_pc;
    iqentry_mem  [tail]    <=   1'b0;
    iqentry_ndx  [tail]    <=   1'b0;
    iqentry_cas  [tail]    <=   1'b0;
    iqentry_pushpop[tail]  <=   1'b0;
    iqentry_pea  [tail]    <=   1'b0;
    iqentry_cmpmv[tail]    <=   1'b0;
    iqentry_lla  [tail]    <=   1'b0;
    iqentry_tlb  [tail]    <=   1'b0;
    iqentry_jmp  [tail]    <=   1'b0;
    iqentry_jmpi [tail]    <=   1'b0;
    iqentry_sync [tail]    <=   1'b0;
    iqentry_memsb[tail]    <=   1'b0;
    iqentry_memdb[tail]    <=   1'b0;
    iqentry_fp   [tail]    <=   1'b0;
    iqentry_rfw  [tail]    <=   1'b1;
    iqentry_tgt  [tail]    <=   7'd27;
    iqentry_pred [tail]    <=   pregs[which ? Pn1 : Pn0];
    // Look at the previous queue slot to see if an immediate prefix is enqueued
    iqentry_a0   [tail]    <=   link ? (which ? {{46{fetchbuf1_instr[39]}},fetchbuf1_instr[21:16],fetchbuf1_instr[39:28],3'b000} :
                                                {{46{fetchbuf0_instr[39]}},fetchbuf0_instr[21:16],fetchbuf0_instr[39:28],3'b000}) :
                                (pushpop|unlink) ? 64'd8 : -64'd8;
    iqentry_a1   [tail]    <=   which ? rfoa1 : rfoa0;
    iqentry_a2   [tail]    <=   64'd0;
    iqentry_a3   [tail]    <=   64'd0;
    iqentry_T    [tail]    <=   //unlink ? (which ? rfot1 : rfot0) :
                                 (which ? rfoa1 : rfoa0);
    // The source is set even though the arg might be automatically valid (less logic).
    // This is harmless to do. Note there is no source for the 'I' argument.
    iqentry_p_s  [tail]    <=   rf_source[{1'b1,2'h0,which ? Pn1 : Pn0}];
    iqentry_a1_s [tail]    <=   rf_source[Ra0];
    iqentry_a2_s [tail]    <=   rf_source[Rb0];
    iqentry_a3_s [tail]    <=   rf_source[Rc0];
`ifdef VECTOROPS
    iqentry_a4_s [tail]    <=   rf_source[Rd0];
`endif
    iqentry_T_s  [tail]    <=   rf_source[Ra0];
    // Always do this because it's the first queue slot.
    iqentry_p_v  [tail]    <=   rf_v [{1'b1,2'h0,which ? Pn1:Pn0}] || ((which ? cond1 : cond0) < 4'h2);
    iqentry_a1_v [tail]    <=   rf_v[ which ? Ra1 :  Ra0 ];
    iqentry_a2_v [tail]    <=   1'b1;
    iqentry_a3_v [tail]    <=   1'b1;
    iqentry_T_v  [tail]    <=   //unlink ? rf_v[which ? Rt1 : Rt0] :
                                rf_v[ which ? Ra1 :  Ra0 ];
    rf_v[ 7'd27 ] = `INV;
    rf_source[ 7'd27 ] <= { 1'b0, tail };    // top bit indicates ALU/MEM bus
end
endtask

// enque 0 on tail0 or tail1
task enque0;
input [2:0] tail;
input [2:0] inc;
input test_stomp;
input validate_args;
input [2:0] vel;
input [11:0] sn;
begin
/*
`ifdef VECTOROPS
    if (fetchbuf0_vec && VM[vel]==1'b0) begin
       queued1v = iqentry_a1_v[tail];
       if (vel >= iqentry_a1[tail] && iqentry_a1_v[tail])
          queued1 = `TRUE;
    end
    else
`endif
*/
    if (opcode0==`NOP)
        queued1 = `TRUE;    // to update fetch buffers
`ifdef DEBUG_LOGIC
    else
    if (dbg_ctrl[7] && !StatusDBG) begin
        if (iqentry_v[tail]==`INV && iqentry_v[(tail+1)&7]==`INV) begin
            enque0a(tail,3'd2,1'b0,vel,sn);
            set_exception((tail+1)&7,9'd243);
            allowq = `FALSE;
        end
    end
`endif
`ifdef STACKOPS
    // A pop instruction takes 2 queue entries.
    else if (fnIsPop(fetchbuf0_instr)|fnIsPush(fetchbuf0_instr)|opcode0==`LINK) begin
        $display("0 found push/pop");
        if (iqentry_v[tail]==`INV && iqentry_v[(tail+1)&7]==`INV) begin
            $display("enqueing2");
            enque0a(tail,3'd2,1'b0,vel,sn);
            enquePushpopAdd((tail+1)&7,fnIsPop(fetchbuf0_instr),opcode0==`LINK,0,0);
            allowq = `FALSE;
        end
    end
`ifdef UNLINKOP
    else if (opcode0==`UNLINK) begin
        if (iqentry_v[tail]==`INV && iqentry_v[(tail+1)&7]==`INV) begin
            enquePushpopAdd(tail,1'b0,1'b0,1'b1,0);
            enque0a((tail+1)&7,3'd2,1'b1,vel,sn);
            allowq = `FALSE;
        end
    end
`endif
`endif
/*
`ifdef SEGMENTATION
    else if (fnTargetsSegreg(fetchbuf0_instr)) begin
        if (iqentry_v[tail]==`INV && iqentry_v[(tail+1)&7]==`INV) begin
          enque0a(tail,2'd2,0,vel);
          set_exception((tail+1)&7,{6'b100000,Rt0[2:0]}); // Seg load
          allowq = `FALSE;
        end
    end
`endif
*/
    else if (iqentry_v[tail] == `INV) begin
        if ((({fnIsBranch(opcode0), predict_taken0} == {`TRUE, `TRUE})||(opcode0==`LOOP)) && test_stomp)
            qstomp = `TRUE;
        enque0a(tail,inc,0,vel,sn);
    end
end
endtask

task enque1a;
input [2:0] tail;
input [2:0] inc;
input validate_args;
input unlink;
input [2:0] vel;
input [11:0] sn;
begin
    if (fetchbuf1_pc==32'h0)
        $stop;
    if (fetchbuf1_pc==32'hF44)
        $stop;
    if (fetchbuf1_pc==32'hFFFC275A)
        $stop;
`ifdef SEGMENTATION
`ifdef SEGLIMITS
    if (fetchbuf1_pc >= {sregs_lmt[3'd7],12'h000} && fetchbuf1_pc[ABW-1:ABW-4]!=4'hF)
        set_exception(tail,9'd244);
`endif
`endif
    if (fnIsKMOnlyReg(Rt1) && !km && !(opcode1==`SYS || opcode1==`INT))
        set_exception(tail,9'd245);
`ifdef TRAP_ILLEGALOPS
    if (fnIsIllegal(opcode1,opcode1==`MLO ? rfoc1[5:0] : fnFunc(fetchbuf1_instr)))
        set_exception(tail,9'd250);
`endif
`ifdef DEBUG_LOGIC
    if (dbg_ctrl[0] && dbg_ctrl[17:16]==2'b00 && fetchbuf1_pc==dbg_adr0)
        dbg_imatchB0 = `TRUE;
    if (dbg_ctrl[1] && dbg_ctrl[21:20]==2'b00 && fetchbuf1_pc==dbg_adr1)
        dbg_imatchB1 = `TRUE;
    if (dbg_ctrl[2] && dbg_ctrl[25:24]==2'b00 && fetchbuf1_pc==dbg_adr2)
        dbg_imatchB2 = `TRUE;
    if (dbg_ctrl[3] && dbg_ctrl[29:28]==2'b00 && fetchbuf1_pc==dbg_adr3)
        dbg_imatchB3 = `TRUE;
    if (dbg_imatchB0|dbg_imatchB1|dbg_imatchB2|dbg_imatchB3)
        dbg_imatchB = `TRUE;
    if (dbg_imatchB)
        set_exception(tail,9'd243);     // debug excpetion
`endif
    if (!exception_set) begin
    // If an instruction wasn't enqueued or it wasn't an interrupt instruction then
    // the interrupt pc will need to be set. Othersise this enqueue will inherit
    // from the previous one.
    if (!queued1 || !(opcode0==`INT && Rt0[3:0]==4'hE))
        interrupt_pc = (iqentry_op[(tail-3'd1)&7]==`INT && iqentry_v[(tail-3'd1)&7]==`VAL && iqentry_tgt[(tail-3'd1)&7][3:0]==4'hE) ?
            (string_pc != 0 ? string_pc : iqentry_pc[(tail-3'd1)&7]) :
            (iqentry_op[(tail-3'd1)&7]==`IMM && iqentry_v[(tail-3'd1)&7]==`VAL) ? (string_pc != 0 ? string_pc :
            iqentry_pc[(tail-3'd1)&7]) : (string_pc != 0 ? string_pc : fetchbuf1_pc);
    iqentry_sn   [tail]    <=   sn;
    iqentry_v    [tail]    <=   fetchbuf1_vec ? vel < iqentry_a1[tail][2:0] : `VAL;
    iqentry_done [tail]    <=   `INV;
    iqentry_cmt  [tail]    <=   `TRUE;
    iqentry_out  [tail]    <=   `INV;
    iqentry_res  [tail]    <=   `ZERO;
    iqentry_insnsz[tail]   <=  fnInsnLength(fetchbuf1_instr);
    iqentry_op   [tail]    <=   opcode1;
    iqentry_fn   [tail]    <=   opcode1==`MLO ? rfoc1[5:0] : fnFunc(fetchbuf1_instr);
    iqentry_cond [tail]    <=   cond1;
    iqentry_bt   [tail]    <=   fnIsFlowCtrl(opcode1) && predict_taken1; 
    iqentry_br   [tail]    <=   opcode1[7:4]==`BR;
    iqentry_agen [tail]    <=   `INV;
    // If an interrupt is being enqueued and the previous instruction was an immediate prefix, then
    // inherit the address of the previous instruction, so that the prefix will be executed on return
    // from interrupt.
    // If a string operation was in progress then inherit the address of the string operation so that
    // it can be continued.
    
    iqentry_pc   [tail]    <= (opcode1==`INT && Rt1[3:0]==4'hE) ? interrupt_pc : fetchbuf1_pc;
    iqentry_mem  [tail]    <=   fetchbuf1_mem;
    iqentry_ndx  [tail]    <=   fnIsIndexed(opcode1);
    iqentry_cas  [tail]    <=   opcode1==`CAS;
    iqentry_pushpop[tail]  <=   opcode1==`PUSH || opcode1==`POP;
    iqentry_pea  [tail]    <=   opcode1==`PEA;
    iqentry_cmpmv[tail]    <=   opcode1==`STCMP || opcode1==`STMV;
    iqentry_lla  [tail]    <=   opcode1==`LLA || opcode1==`LLAX;
    iqentry_tlb  [tail]    <=   opcode1==`TLB;
    iqentry_jmp  [tail]    <=   fetchbuf1_jmp;
    iqentry_jmpi [tail]    <=   opcode1==`JMPI || opcode1==`JMPIX;
    iqentry_sync [tail]    <=   opcode1==`SYNC;
    iqentry_memsb[tail]    <=   opcode1==`MEMSB;
    iqentry_memdb[tail]    <=   opcode1==`MEMDB;
    iqentry_fp   [tail]    <=   fetchbuf1_fp;
    iqentry_rfw  [tail]    <=   fetchbuf1_rfw;
    iqentry_tgt  [tail]    <=   Rt1;
    iqentry_preg [tail]    <=   Pn1;
    iqentry_pred [tail]    <=   fnSpr({2'h0,Pn1},fetchbuf1_pc);//pregs[Pn1];
    // Look at the previous queue slot to see if an immediate prefix is enqueued
    // But don't allow it for a branch
    iqentry_a0[tail]   <=
`ifdef VECTOROPS 
          (opcode1==`LVX || opcode1==`SVX) ? {vel,3'b0} :
`endif          
          (opcode1==`INT || opcode1==`SYS || opcode1==`RTF || opcode1==`JSF) ? fnImm(fetchbuf1_instr) :
          fnIsBranch(opcode1) ? {{DBW-12{fetchbuf1_instr[11]}},fetchbuf1_instr[11:8],fetchbuf1_instr[23:16]} :
          (queued1 && opcode0==`IMM) ? {fnImmImm(fetchbuf0_instr)|fnImm8(fetchbuf1_instr)} :
          (!queued1 && iqentry_op[(tail-3'd1)&7]==`IMM) && iqentry_v[(tail-3'd1)&7] ? {iqentry_a0[(tail-3'd1)&7][DBW-1:8],fnImm8(fetchbuf1_instr)} :
          opcode1==`IMM ? fnImmImm(fetchbuf1_instr) :
          fnImm(fetchbuf1_instr);
    iqentry_a1   [tail]    <=   fnOpa(opcode1,Ra1,fetchbuf1_instr,rfoa1,fetchbuf1_pc);
    iqentry_a2   [tail]    <=   fnOpb(opcode1,Rb1,fetchbuf1_instr,rfob1,pvrfoa1,fetchbuf1_pc);
    iqentry_a3   [tail]    <=   fetchbuf1_vec ? pvrfob1 : rfoc1;
    iqentry_T    [tail]    <=   fnOpt(Rt1,rfot1,vrfot1,fetchbuf1_pc);
`ifdef SIMULATION
    iqentry_r1   [tail]    <=   Ra1;
    iqentry_r2   [tail]    <=   Rb1;
    iqentry_r3   [tail]    <=   Rc1;
    iqentry_rt   [tail]    <=   Rt1;
`endif
    // The source is set even though the arg might be automatically valid (less logic). If 
    // queueing two entries the source settings may be overridden in the argument valudation.
    iqentry_p_s  [tail]    <=   rf_source[{1'b1,2'h0,Pn1}];
    iqentry_a1_s [tail]    <=   //unlink ? {1'b0, (tail-3'd1)&7} :
                                rf_source[Ra1];
    iqentry_a2_s [tail]    <=   rf_source[Rb1];
    iqentry_a3_s [tail]    <=   rf_source[Rc1];
`ifdef VECTOROPS
    iqentry_a4   [tail]    <=   pvrfoc1;
    iqentry_a4_s [tail]    <=   rf_source[Rd1];
`endif
    iqentry_T_s  [tail]    <=   rf_source[Rt1];
    if (validate_args)
        validate_args11(tail);
    end
    tail0 <= tail0 + inc;
    tail1 <= tail1 + inc;
    tail2 <= tail2 + inc;
end
endtask

// enque 1 on tail0 or tail1
task enque1;
input [2:0] tail;
input [2:0] inc;
input test_stomp;
input validate_args;
input [2:0] vel;
input [11:0] sn;
begin
/*
 This bit of code being superceded by vector predicate bits
`ifdef VECTOROPS
    if (fetchbuf1_vec && VM[vel]==1'b0) begin
      queued1v = iqentry_vl_v[tail];
       if (vel >= iqentry_vl[tail] && iqentry_vl_v[tail])
        queued1 = `TRUE;
    end
    else
`endif
*/
    if (opcode1==`NOP) begin
        if (queued1==`TRUE) queued2 = `TRUE;
        queued1 = `TRUE;
    end
`ifdef DEBUG_LOGIC
    else
    if (dbg_ctrl[7] && !StatusDBG) begin
        if (iqentry_v[tail]==`INV && iqentry_v[(tail+1)&7]==`INV) begin
            enque1a(tail,3'd2,1,0,vel,sn);
            set_exception((tail+1)&7,9'd243);
            allowq = `FALSE;
        end
    end
`endif
`ifdef STACKOPS
    else if (fnIsPop(fetchbuf1_instr)|fnIsPush(fetchbuf1_instr)|opcode1==`LINK) begin
        $display("1 found push/pop");
        $display("iqv[%d]:%d", tail,iqentry_v[tail]);
        $display("iqv[%d+1]:%d", tail, iqentry_v[tail+1]);
        $display("valargs:%d", validate_args);
        $display("qd1:%d", queued1);
        if (iqentry_v[tail]==`INV && iqentry_v[(tail+1)&7]==`INV && validate_args && !queued1) begin
            $display("1 enq 2 ");
            enque1a(tail,3'd2,1,0,vel,sn);
            enquePushpopAdd((tail+1)&7,fnIsPop(fetchbuf1_instr),opcode1==`LINK,0,1);
            allowq = `FALSE;
        end
    end
`ifdef UNLINKOP
    else if (opcode1==`UNLINK) begin
        if (iqentry_v[tail]==`INV && iqentry_v[(tail+1)&7]==`INV) begin
            enquePushpopAdd(tail,1'b0,1'b0,1'b1,1);
            enque1a((tail+1)&7,3'd2,1,1,vel,sn);
            allowq = `FALSE;
        end
    end
`endif
`endif
/*
`ifdef SEGMENTATION
    else if (fnTargetsSegreg(fetchbuf1_instr)) begin
      if (iqentry_v[tail]==`INV && iqentry_v[(tail+1)&7]==`INV) begin
        enque1a(tail,2'd2,1,0,vel);
        set_exception((tail+1)&7,{6'b100000,Rt1[2:0]}); // Seg load
        allowq = `FALSE;
      end
    end
`endif
*/
    else if (iqentry_v[tail] == `INV && !qstomp) begin
        if ((({fnIsBranch(opcode1), predict_taken1} == {`TRUE, `TRUE})||(opcode1==`LOOP)) && test_stomp)
            qstomp = `TRUE;
        enque1a(tail,inc,validate_args,0,vel,sn);
        // Note that if there are two instructions ready to queue and the first instruction is a 
        // vector instruction then we shouldn't get here because allowq would be false.
`ifdef VECTOROPS
        if (queued1v==`TRUE) queued2v = fetchbuf1_vec;
        else queued1v = fetchbuf1_vec;
        if (queued1==`TRUE) queued2 = fetchbuf1_vec ? vele >= VL[6:0] : `TRUE;
        else queued1 = fetchbuf1_vec ? vele >= VL[6:0] : `TRUE;
`else
        if (queued1==`TRUE) queued2 = `TRUE;
        else queued1 = `TRUE;
`endif
    end
end
endtask

task validate_args10;
input [2:0] tail;
begin
    iqentry_p_v  [tail]    <=   rf_v [{1'b1,2'h0,Pn0}] || cond0 < 4'h2;
    iqentry_a1_v [tail]    <=   fnSource1_v( opcode0 ) | rf_v[ Ra0 ];
    iqentry_a2_v [tail]    <=   (fnSource2_v( opcode0, fnFunc(fetchbuf0_instr)) | rf_v[Rb0]);// & fnVelv(fetchbuf0_instr);
    iqentry_a3_v [tail]    <=   fnSource3_v( opcode0, fnFunc(fetchbuf0_instr)) | rf_v[ Rc0 ];
`ifdef VECTOROPS
    iqentry_a4_v [tail]    <=   fnSource4_v( opcode0, fnFunc(fetchbuf0_instr)) | rf_v[ Rd0 ];
`endif
    iqentry_T_v  [tail]    <=   fnSourceT_v( opcode0, fnFunc(fetchbuf0_instr)) | rf_v[ Rt0 ];
    iqentry_velv [tail]    <=   fnVelv(fetchbuf0_instr);
    if (fetchbuf0_rfw|fetchbuf0_pfw) begin
        $display("regv[%d] = %d", Rt0,rf_v[ Rt0 ]);
        rf_v[ Rt0 ] = fnRegIsAutoValid(Rt0);
        $display("reg[%d] <= INV",Rt0);
        rf_source[ Rt0 ] <= { fetchbuf0_mem, tail };    // top bit indicates ALU/MEM bus
        $display("10:rf_src[%d] <= %d, insn=%h", Rt0, tail,fetchbuf0_instr);
        invalidate_pregs(tail, Rt0, fetchbuf0_mem);
    end
end
endtask

task validate_args11;
input [2:0] tail;
begin
    // The predicate is automatically valid for condiitions 0 and 1 (always false or always true).
    iqentry_p_v  [tail]    <=   rf_v [{1'b1,2'h0,Pn1}] || cond1 < 4'h2;
    iqentry_a1_v [tail]    <=   fnSource1_v( opcode1 ) | rf_v[ Ra1 ];
    iqentry_a2_v [tail]    <=   (fnSource2_v( opcode1, fnFunc(fetchbuf1_instr)) | rf_v[ Rb1 ]);// & fnVelv(fetchbuf1_instr);
    iqentry_a3_v [tail]    <=   fnSource3_v( opcode1, fnFunc(fetchbuf1_instr)) | rf_v[ Rc1 ];
`ifdef VECTOROPS
    iqentry_a4_v [tail]    <=   fnSource3_v( opcode1, fnFunc(fetchbuf1_instr)) | rf_v[ Rd1 ];
`endif
    iqentry_T_v  [tail]    <=   fnSourceT_v( opcode1, fnFunc(fetchbuf1_instr)) | rf_v[ Rt1 ];
    iqentry_velv [tail]    <=   fnVelv(fetchbuf1_instr);
    if (fetchbuf1_rfw|fetchbuf1_pfw) begin
        $display("1:regv[%d] = %d", Rt1,rf_v[ Rt1 ]);
        rf_v[ Rt1 ] = fnRegIsAutoValid(Rt1);
        $display("reg[%d] <= INV",Rt1);
        rf_source[ Rt1 ] <= { fetchbuf1_mem, tail };    // top bit indicates ALU/MEM bus
        invalidate_pregs(tail, Rt1, fetchbuf1_mem);
        $display("11:rf_src[%d] <= %d, insn=%h", Rt1, tail,fetchbuf0_instr);
    end
end
endtask

// If two entries were queued then validate the arguments for the second entry.
//
task validate_args;
begin
    if (queued2|queued2v) begin
    // SOURCE 1 ... this is relatively straightforward, because all instructions
       // that have a source (i.e. every instruction but LUI) read from RB
       //
       // if the argument is an immediate or not needed, we're done
       if (fnSource1_v( opcode1 ) == `VAL) begin
           $display("fnSource1_v=1 iq[%d]", tail1);
           iqentry_a1_v [tail1] <= `VAL;
           // The source doesn't need to be set if the arg is being
           // set valid.
//           iqentry_a1_s [tail1] <= 4'hF;
//                    iqentry_a1_s [tail1] <= 4'd0;
       end
       // if previous instruction writes nothing to RF, then get info from rf_v and rf_source
       else if (!fetchbuf0_rfw) begin
           iqentry_a1_v [tail1]    <=   rf_v [Ra1];
           iqentry_a1_s [tail1]    <=   rf_source [Ra1];
       end
       // otherwise, previous instruction does write to RF ... see if overlap
       else if (Rt0 != 10'd0 && Ra1 == Rt0) begin
           // if the previous instruction is a LW, then grab result from memq, not the iq
           $display("invalidating iqentry_a1_v[%d]", tail1);
           iqentry_a1_v [tail1]    <=   `INV;
           iqentry_a1_s [tail1]    <=   {fetchbuf0_mem, tail0};
       end
       // if no overlap, get info from rf_v and rf_source
       else begin
           iqentry_a1_v [tail1]    <=   rf_v [Ra1];
           iqentry_a1_s [tail1]    <=   rf_source [Ra1];
           $display("2:iqentry_a1_s[%d] <= %d", tail1, rf_source [Ra1]);
       end

       if (!fetchbuf0_rfw) begin
           iqentry_p_v  [tail1]    <=   rf_v [{1'b1,2'h0,Pn1}] || cond1 < 4'h2;
           iqentry_p_s  [tail1]    <=   rf_source [{1'b1,2'h0,Pn1}];
       end
       else if ((Rt0 != 8'd0 && (Pn1==Rt0[3:0] || Rt0==8'h70)) && ((Rt0 & 8'h70)==8'h40)||Rt0==8'h70) begin
           iqentry_p_v [tail1] <= cond1 < 4'h2;
           iqentry_p_s [tail1] <= {fetchbuf0_mem, tail0};
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
       if (fnSource2_v( opcode1,fnFunc(fetchbuf1_instr) ) == `VAL) begin
           iqentry_a2_v [tail1] <= `VAL;
//           iqentry_a2_s [tail1] <= 4'hF;
       end
       // if previous instruction writes nothing to RF, then get info from rf_v and rf_source
       else if (!fetchbuf0_rfw) begin
           iqentry_a2_v [tail1] <= rf_v[ Rb1 ];
           iqentry_a2_s [tail1] <= rf_source[Rb1];
       end
       // otherwise, previous instruction does write to RF ... see if overlap
       else if (Rt0 != 8'd0 && Rb1 == Rt0) begin
           // if the previous instruction is a LW, then grab result from memq, not the iq
           iqentry_a2_v [tail1]    <=   `INV;
           iqentry_a2_s [tail1]    <=   {fetchbuf0_mem,tail0};
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
       if (fnSource3_v( opcode1,fnFunc(fetchbuf1_instr) ) == `VAL) begin
           iqentry_a3_v [tail1] <= `VAL;
//           iqentry_a3_s [tail1] <= 4'hF;
//                    iqentry_a1_s [tail1] <= 4'd0;
       end
       // if previous instruction writes nothing to RF, then get info from rf_v and rf_source
       else if (!fetchbuf0_rfw) begin
           iqentry_a3_v [tail1]    <=   rf_v [Rc1];
           iqentry_a3_s [tail1]    <=   rf_source [Rc1];
       end
       // otherwise, previous instruction does write to RF ... see if overlap
       else if (Rt0 != 8'd0 && Rc1 == Rt0) begin
           // if the previous instruction is a LW, then grab result from memq, not the iq
           iqentry_a3_v [tail1]    <=   `INV;
           iqentry_a3_s [tail1]    <=   {fetchbuf0_mem,tail0};
       end
       // if no overlap, get info from rf_v and rf_source
       else begin
           iqentry_a3_v [tail1]    <=   rf_v [Rc1];
           iqentry_a3_s [tail1]    <=   rf_source [Rc1];
       end
`ifdef VECTOROPS
       if (fnSource4_v( opcode1,fnFunc(fetchbuf1_instr) ) == `VAL) begin
          iqentry_a4_v [tail1] <= `VAL;
       end
       // if previous instruction writes nothing to RF, then get info from rf_v and rf_source
      else if (!fetchbuf0_rfw) begin
          iqentry_a4_v [tail1]    <=   rf_v [Rd1];
          iqentry_a4_s [tail1]    <=   rf_source [Rd1];
      end
      // otherwise, previous instruction does write to RF ... see if overlap
      else if (Rt0 != 10'd0 && Rd1 == Rt0) begin
          // if the previous instruction is a LW, then grab result from memq, not the iq
          iqentry_a4_v [tail1]    <=   `INV;
          iqentry_a4_s [tail1]    <=   {fetchbuf0_mem,tail0};
      end
      // if no overlap, get info from rf_v and rf_source
      else begin
          iqentry_a4_v [tail1]    <=   rf_v [Rd1];
          iqentry_a4_s [tail1]    <=   rf_source [Rd1];
      end
`endif
       //
       // Target 3 ... this is relatively straightforward, because all instructions
       // that have a source (i.e. every instruction but LUI) read from RC
       //
       // if the argument is an immediate or not needed, we're done
       if (fnSourceT_v( opcode1,fnFunc(fetchbuf1_instr) ) == `VAL) begin
           iqentry_T_v [tail1] <= `VAL;
           //iqentry_T_s [tail1] <= 4'hF;
       end
       // if previous instruction writes nothing to RF, then get info from rf_v and rf_source
       else if (!fetchbuf0_rfw) begin
           iqentry_T_v [tail1]    <=   rf_v [Rt1];
           iqentry_T_s [tail1]    <=   rf_source [Rt1];
       end
       // otherwise, previous instruction does write to RF ... see if overlap
       else if (Rt0 != 8'd0 && Rt1 == Rt0) begin
           // if the previous instruction is a LW, then grab result from memq, not the iq
           iqentry_T_v [tail1]    <=   `INV;
           iqentry_T_s [tail1]    <=   {fetchbuf0_mem,tail0};
       end
       // if no overlap, get info from rf_v and rf_source
       else begin
           iqentry_T_v [tail1]    <=   rf_v [Rt1];
           iqentry_T_s [tail1]    <=   rf_source [Rt1];
       end
    end
    if (queued1|queued2) begin
        if (fetchbuf0_rfw|fetchbuf0_pfw) begin
            $display("regv[%d] = %d", Rt0,rf_v[ Rt0 ]);
            rf_v[ Rt0 ] = fnRegIsAutoValid(Rt0);
            $display("reg[%d] <= INV",Rt0);
            rf_source[ Rt0 ] <= { fetchbuf0_mem, tail0 };    // top bit indicates ALU/MEM bus
            $display("12:rf_src[%d] <= %d, insn=%h", Rt0, tail0,fetchbuf0_instr);
            invalidate_pregs(tail0, Rt0, fetchbuf0_mem);
        end
    end
    if (queued2) begin
        if (fetchbuf1_rfw|fetchbuf1_pfw) begin
            $display("1:regv[%d] = %d", Rt1,rf_v[ Rt1 ]);
            rf_v[ Rt1 ] = fnRegIsAutoValid(Rt1);
            $display("reg[%d] <= INV",Rt1);
            rf_source[ Rt1 ] <= { fetchbuf1_mem, tail1 };    // top bit indicates ALU/MEM bus
            invalidate_pregs(tail1, Rt1, fetchbuf1_mem);
        end
    end
end
endtask

task fetchAB;
begin
    fetchbufA_instr <= insn0;
    fetchbufA_pc <= pc;
    fetchbufA_v <= ld_fetchbuf;
    fetchbufB_instr <= insn1;
    fetchbufB_pc <= pc + fnInsnLength(insn);
    fetchbufB_v <= ld_fetchbuf;
end
endtask

task fetchCD;
begin
    fetchbufC_instr <= insn0;
    fetchbufC_pc <= pc;
    fetchbufC_v <= ld_fetchbuf;
    fetchbufD_instr <= insn1;
    fetchbufD_pc <= pc + fnInsnLength(insn);
    fetchbufD_v <= ld_fetchbuf;
end
endtask

// Reset the tail pointers.
// Used by the enqueue logic
//
task reset_tail_pointers;
input first;
begin
    if ((iqentry_stomp[0] & ~iqentry_stomp[7]) | first) begin
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
endtask

// Increment the head pointers
// Also increments the instruction counter
// Used when instructions are committed.
// Also clear any outstanding state bits that foul things up.
//
task head_inc;
input [2:0] amt;
begin
    head0 <= head0 + amt;
    head1 <= head1 + amt;
    head2 <= head2 + amt;
    head3 <= head3 + amt;
    head4 <= head4 + amt;
    head5 <= head5 + amt;
    head6 <= head6 + amt;
    head7 <= head7 + amt;
    I <= I + amt;
    if (amt==3'd3) begin
    iqentry_agen[head0] <= `INV;
    iqentry_agen[head1] <= `INV;
    iqentry_agen[head2] <= `INV;
    end else if (amt==3'd2) begin
    iqentry_agen[head0] <= `INV;
    iqentry_agen[head1] <= `INV;
    end else if (amt==3'd1)
	    iqentry_agen[head0] <= `INV;
end
endtask


// set_exception:
// Used to requeue the instruction as an exception if an exception occurs.

task set_exception;
input [2:0] id;     // instruction queue id
input [8:0] exc;    // exception number
begin
    iqentry_op [id[2:0] ] <= `INT;
    iqentry_cond [id[2:0]] <= 4'd1;        // always execute
    iqentry_mem[id[2:0]] <= `FALSE;
    iqentry_rfw[id[2:0]] <= `TRUE;            // writes to IPC
    iqentry_a0 [id[2:0]] <= exc;
    iqentry_p_v  [id[2:0]] <= `TRUE;
    iqentry_a1 [id[2:0]] <= cregs[4'hC];    // *** assumes BR12 is static
    iqentry_a1_v [id[2:0]] <= `TRUE;        // Flag arguments as valid
    iqentry_a2_v [id[2:0]] <= `TRUE;
    iqentry_a3_v [id[2:0]] <= `TRUE;
`ifdef VECTOROPS
    iqentry_a4_v [id[2:0]] <= `TRUE;
`endif
    iqentry_T_v  [id[2:0]] <= `TRUE;
    iqentry_out [id[2:0]] <= `FALSE;
    iqentry_agen [id[2:0]] <= `FALSE;
    iqentry_tgt[id[2:0]] <= {1'b1,2'h1,(exc==9'd243 || exc[8])?4'hB:4'hD};    // Target EPC
    exception_set = `TRUE;
end
endtask

// The core should really invalidate all the predicate registers when the
// sideways slice of all the pregs is manipulated. But then the problem is
// reading the result register into all the predicate registers at once.
// The source for each register would be a bit field of the result register
// and the core does not support this sort of thing.
// So. After manipulating the sideways slice of predicate registers the
// instruction should be followed with a SYNC instruction to ensure that
// the results are picked up.
// To be fixed one day.
task invalidate_pregs;
input [2:0] tail;
input [7:0] Rt;
input mem;
begin
if (Rt==8'h70) begin
    rf_v[8'h40] = `INV;
    rf_v[8'h41] = `INV;
    rf_v[8'h42] = `INV;
    rf_v[8'h43] = `INV;
    rf_v[8'h44] = `INV;
    rf_v[8'h45] = `INV;
    rf_v[8'h46] = `INV;
    rf_v[8'h47] = `INV;
    rf_v[8'h48] = `INV;
    rf_v[8'h49] = `INV;
    rf_v[8'h4A] = `INV;
    rf_v[8'h4B] = `INV;
    rf_v[8'h4C] = `INV;
    rf_v[8'h4D] = `INV;
    rf_v[8'h4E] = `INV;
    rf_v[8'h4F] = `INV;
    rf_source[8'h40] <= { mem, tail };
    rf_source[8'h41] <= { mem, tail };
    rf_source[8'h42] <= { mem, tail };
    rf_source[8'h43] <= { mem, tail };
    rf_source[8'h44] <= { mem, tail };
    rf_source[8'h45] <= { mem, tail };
    rf_source[8'h46] <= { mem, tail };
    rf_source[8'h47] <= { mem, tail };
    rf_source[8'h48] <= { mem, tail };
    rf_source[8'h49] <= { mem, tail };
    rf_source[8'h4A] <= { mem, tail };
    rf_source[8'h4B] <= { mem, tail };
    rf_source[8'h4C] <= { mem, tail };
    rf_source[8'h4D] <= { mem, tail };
    rf_source[8'h4E] <= { mem, tail };
    rf_source[8'h4F] <= { mem, tail };
end
end
endtask

// The following task looks at a functional unit output bus and assigns results
// to waiting arguments.

task setargs;
input [3:0] id;
input v;
input [DBW-1:0] bus;
begin
  for (n = 0; n < QENTRIES; n = n + 1)
  begin
    if (iqentry_a1_v[n] == `INV && iqentry_a1_s[n] == id && iqentry_v[n] == `VAL && v == `VAL) begin
      iqentry_a1[n] <= bus;
      iqentry_a1_v[n] <= `VAL;
    end
    if (iqentry_a2_v[n] == `INV && iqentry_a2_s[n] == id && iqentry_v[n] == `VAL && v == `VAL) begin
      iqentry_a2[n] <= bus;
      iqentry_a2_v[n] <= `VAL;
    end
/*
    if (iqentry_a2_v[n] == `INV && iqentry_a2_sv[n]==`TRUE  && iqentry_v[n] && rf_v [{ele,iqentry_rb[n]}]) begin
      iqentry_a2[n] <= vrfob0;
      iqentry_a2_v[n] <= iqentry_velv[n];
    end
*/
    if (iqentry_a3_v[n] == `INV && iqentry_a3_s[n] == id && iqentry_v[n] == `VAL && v == `VAL) begin
      iqentry_a3[n] <= bus;
      iqentry_a3_v[n] <= `VAL;
    end
`ifdef VECTOROPS
    if (iqentry_a4_v[n] == `INV && iqentry_a4_s[n] == id && iqentry_v[n] == `VAL && v == `VAL) begin
      iqentry_a4[n] <= bus;
      iqentry_a4_v[n] <= `VAL;
    end
`endif
    if (iqentry_T_v[n] == `INV && iqentry_T_s[n] == id && iqentry_v[n] == `VAL && v == `VAL) begin
      iqentry_T[n] <= bus;
      iqentry_T_v[n] <= `VAL;
    end
  end
end
endtask

endmodule
