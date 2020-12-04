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


`define ZERO		16'd0

`define ADD	3'd0
`define ADDI	3'd1
`define NAND	3'd2
`define LUI	3'd3
`define SW	3'd4
`define LW	3'd5
`define BEQ	3'd6
`define JALR	3'd7

// JALR and EXTENDED are synonyms
`define EXTEND	3'd7

// system-call subclasses:
`define SYS_NONE	3'd0
`define SYS_CALL	3'd1
`define SYS_MFSR	3'd2
`define SYS_MTSR	3'd3
`define SYS_RFU1	3'd4
`define SYS_RFU2	3'd5
`define SYS_RFU3	3'd6
`define SYS_EXC		3'd7	// doesn't need to be last, but what the heck

// exception types:
`define EXC_NONE	4'd0
`define EXC_HALT	4'd1
`define EXC_TLBMISS	4'd2
`define EXC_SIGSEGV	4'd3
`define EXC_INVALID	4'd4

`define INSTRUCTION_OP	15:13	// opcode
`define INSTRUCTION_RA	12:10	// rA 
`define INSTRUCTION_RB	9:7	// rB 
`define INSTRUCTION_RC	2:0	// rC 
`define INSTRUCTION_IM	6:0	// immediate (7-bit)
`define INSTRUCTION_LI	9:0	// large unsigned immediate (10-bit, 0-extended)
`define INSTRUCTION_SB	6	// immediate's sign bit
`define INSTRUCTION_S1  6:4	// contains the syscall sub-class (NONE, CALL, MFSR, MTSR, EXC, etc.)
`define INSTRUCTION_S2  3:0	// contains the sub-class identifier value

`define FORW_BRANCH	1'b0
`define BACK_BRANCH	1'b1

`define DRAMSLOT_AVAIL	2'b00
`define DRAMREQ_READY	2'b11

`define INV	1'b0
`define VAL	1'b1

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

module RiSC;

    reg [15:0] rf[0:7];
    reg        rf_v[0:7];
    reg  [3:0] rf_source[0:7];
    reg [15:0] pc0;
    reg [15:0] pc1;
    reg [15:0] m[0:65535];
    reg        clk;
    reg  [3:0] panic;		// indexes the message structure
    reg [128:0] message [0:15];	// indexed by panic

    // instruction queue (ROB)
    reg        iqentry_v  	[0:7];	// entry valid?  -- this should be the first bit
    reg        iqentry_out	[0:7];	// instruction has been issued to an ALU ... 
    reg        iqentry_done	[0:7];	// instruction result valid
    reg        iqentry_bt  	[0:7];	// branch-taken (used only for branches)
    reg        iqentry_agen  	[0:7];	// address-generate ... signifies that address is ready (only for LW/SW)
    reg        iqentry_mem	[0:7];	// touches memory: 1 if LW/SW
    reg        iqentry_jmp	[0:7];	// changes control flow: 1 if BEQ/JALR
    reg        iqentry_rfw	[0:7];	// writes to register file
    reg [15:0] iqentry_res	[0:7];	// instruction result
    reg  [2:0] iqentry_op	[0:7];	// instruction opcode
    reg  [3:0] iqentry_exc	[0:7];	// only for branches ... indicates a HALT instruction
    reg  [2:0] iqentry_tgt	[0:7];	// rA field or ZERO -- this is the instruction's target (if any)
    reg [15:0] iqentry_a0	[0:7];	// argument 0 (immediate)
    reg [15:0] iqentry_a1	[0:7];	// argument 1
    reg        iqentry_a1_v	[0:7];	// arg1 valid
    reg  [3:0] iqentry_a1_s	[0:7];	// arg1 source (iq entry # with top bit representing ALU/DRAM bus)
    reg [15:0] iqentry_a2	[0:7];	// argument 2
    reg        iqentry_a2_v	[0:7];	// arg2 valid
    reg  [3:0] iqentry_a2_s	[0:7];	// arg2 source (iq entry # with top bit representing ALU/DRAM bus)
    reg [15:0] iqentry_pc	[0:7];	// program counter for this instruction

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

   wire  [7:1] livetarget;
   wire  [7:1] iqentry_0_livetarget;
   wire  [7:1] iqentry_1_livetarget;
   wire  [7:1] iqentry_2_livetarget;
   wire  [7:1] iqentry_3_livetarget;
   wire  [7:1] iqentry_4_livetarget;
   wire  [7:1] iqentry_5_livetarget;
   wire  [7:1] iqentry_6_livetarget;
   wire  [7:1] iqentry_7_livetarget;
   wire  [7:1] iqentry_0_latestID;
   wire  [7:1] iqentry_1_latestID;
   wire  [7:1] iqentry_2_latestID;
   wire  [7:1] iqentry_3_latestID;
   wire  [7:1] iqentry_4_latestID;
   wire  [7:1] iqentry_5_latestID;
   wire  [7:1] iqentry_6_latestID;
   wire  [7:1] iqentry_7_latestID;
   wire  [7:1] iqentry_0_cumulative;
   wire  [7:1] iqentry_1_cumulative;
   wire  [7:1] iqentry_2_cumulative;
   wire  [7:1] iqentry_3_cumulative;
   wire  [7:1] iqentry_4_cumulative;
   wire  [7:1] iqentry_5_cumulative;
   wire  [7:1] iqentry_6_cumulative;
   wire  [7:1] iqentry_7_cumulative;
   wire  [7:1] iq0_out;
   wire  [7:1] iq1_out;
   wire  [7:1] iq2_out;
   wire  [7:1] iq3_out;
   wire  [7:1] iq4_out;
   wire  [7:1] iq5_out;
   wire  [7:1] iq6_out;
   wire  [7:1] iq7_out;

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
    reg        source1_v	[0:7];	// indexed by opcode ... tells whether we need the RF value
    reg        source2_v	[0:7];	// indexed by opcode ... tells whether we need the RF value

    reg        fetchbuf;	// determines which pair to read from & write to

   wire [15:0] fetchbuf0_instr;	
   wire [15:0] fetchbuf0_pc;
   wire        fetchbuf0_v;
   wire        fetchbuf0_mem;
   wire        fetchbuf0_jmp;
   wire        fetchbuf0_rfw;
   wire [15:0] fetchbuf1_instr;
   wire [15:0] fetchbuf1_pc;
   wire        fetchbuf1_v;
   wire        fetchbuf1_mem;
   wire        fetchbuf1_jmp;
   wire        fetchbuf1_rfw;

    reg [15:0] fetchbufA_instr;	
    reg [15:0] fetchbufA_pc;
    reg        fetchbufA_v;
    reg [15:0] fetchbufB_instr;
    reg [15:0] fetchbufB_pc;
    reg        fetchbufB_v;
    reg [15:0] fetchbufC_instr;
    reg [15:0] fetchbufC_pc;
    reg        fetchbufC_v;
    reg [15:0] fetchbufD_instr;
    reg [15:0] fetchbufD_pc;
    reg        fetchbufD_v;

    reg        did_branchback;

    reg        alu0_available;
    reg        alu0_dataready;
    reg  [3:0] alu0_sourceid;
    reg  [2:0] alu0_op;
    reg        alu0_bt;
    reg [15:0] alu0_argA;
    reg [15:0] alu0_argB;
    reg [15:0] alu0_argI;	// only used by BEQ
    reg [15:0] alu0_pc;
   wire [15:0] alu0_bus;
   wire  [3:0] alu0_id;
   wire  [3:0] alu0_exc;
   wire        alu0_v;
   wire        alu0_branchmiss;
   wire [15:0] alu0_misspc;

    reg        alu1_available;
    reg        alu1_dataready;
    reg  [3:0] alu1_sourceid;
    reg  [2:0] alu1_op;
    reg        alu1_bt;
    reg [15:0] alu1_argA;
    reg [15:0] alu1_argB;
    reg [15:0] alu1_argI;	// only used by BEQ
    reg [15:0] alu1_pc;
   wire [15:0] alu1_bus;
   wire  [3:0] alu1_id;
   wire  [3:0] alu1_exc;
   wire        alu1_v;
   wire        alu1_branchmiss;
   wire [15:0] alu1_misspc;

   wire        branchback;
   wire [15:0] backpc;
   wire        branchmiss;
   wire [15:0] misspc;

   wire        dram_avail;
    reg	 [1:0] dram0;	// state of the DRAM request (latency = 4; can have three in pipeline)
    reg	 [1:0] dram1;	// state of the DRAM request (latency = 4; can have three in pipeline)
    reg	 [1:0] dram2;	// state of the DRAM request (latency = 4; can have three in pipeline)
    reg [15:0] dram0_data;
    reg [15:0] dram0_addr;
    reg  [2:0] dram0_op;
    reg  [2:0] dram0_tgt;
    reg  [3:0] dram0_id;
    reg  [3:0] dram0_exc;
    reg [15:0] dram1_data;
    reg [15:0] dram1_addr;
    reg  [2:0] dram1_op;
    reg  [2:0] dram1_tgt;
    reg  [3:0] dram1_id;
    reg  [3:0] dram1_exc;
    reg [15:0] dram2_data;
    reg [15:0] dram2_addr;
    reg  [2:0] dram2_op;
    reg  [2:0] dram2_tgt;
    reg  [3:0] dram2_id;
    reg  [3:0] dram2_exc;

    reg [15:0] dram_bus;
    reg  [2:0] dram_tgt;
    reg  [3:0] dram_id;
    reg  [3:0] dram_exc;
    reg        dram_v;

   wire        outstanding_stores;
    reg [63:0] I;	// instruction count

   wire        commit0_v;
   wire  [3:0] commit0_id;
   wire  [2:0] commit0_tgt;
   wire [15:0] commit0_bus;
   wire        commit1_v;
   wire  [3:0] commit1_id;
   wire  [2:0] commit1_tgt;
   wire [15:0] commit1_bus;

   decoder3 iq0(.num(iqentry_tgt[0]), .out(iq0_out));
   decoder3 iq1(.num(iqentry_tgt[1]), .out(iq1_out));
   decoder3 iq2(.num(iqentry_tgt[2]), .out(iq2_out));
   decoder3 iq3(.num(iqentry_tgt[3]), .out(iq3_out));
   decoder3 iq4(.num(iqentry_tgt[4]), .out(iq4_out));
   decoder3 iq5(.num(iqentry_tgt[5]), .out(iq5_out));
   decoder3 iq6(.num(iqentry_tgt[6]), .out(iq6_out));
   decoder3 iq7(.num(iqentry_tgt[7]), .out(iq7_out));

    initial begin: stop_at
	#1000000; panic <= `PANIC_OVERRUN;
    end

    initial begin: Init
	integer i;

	for (i=0; i<65536; i=i+1)
	    m[i] = 0;

	$readmemh("init.dat", m);
	pc0 = 0;
	pc1 = 1;
	clk = 0;
	for (i=0; i<8; i=i+1) begin
	    rf[i] = 0;
	    rf_v[i] = 1;
	    iqentry_v[i] = `INV;
	end
	fetchbufA_v = 0;
	fetchbufB_v = 0;
	fetchbufC_v = 0;
	fetchbufD_v = 0;
	head0 = 0;
	head1 = 1;
	head2 = 2;
	head3 = 3;
	head4 = 4;
	head5 = 5;
	head6 = 6;
	head7 = 7;
	tail0 = 0;
	tail1 = 1;
	panic = `PANIC_NONE;
	alu0_available = 1;
	alu0_dataready = 0;
	alu1_available = 1;
	alu1_dataready = 0;
	dram_v = 0;
	fetchbuf = 0;
	I = 0;

	dram0 = 0;
	dram1 = 0;
	dram2 = 0;

	//
	// 1 if the the operand is automatically valid, 
	// 0 if we need a RF value
	source1_v  [`ADD]	= 0;
	source2_v  [`ADD]	= 0;
	source1_v  [`ADDI]	= 0;
	source2_v  [`ADDI]	= 1;
	source1_v  [`NAND]	= 0;
	source2_v  [`NAND]	= 0;
	source1_v  [`LUI]	= 1;
	source2_v  [`LUI]	= 1;
	source1_v  [`LW]	= 0;
	source2_v  [`LW]	= 1;
	source1_v  [`SW]	= 0;
	source2_v  [`SW]	= 0;
	source1_v  [`BEQ]	= 0;
	source2_v  [`BEQ]	= 0;
	source1_v  [`JALR]	= 0;
	source2_v  [`JALR]	= 1;

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

    //
    // FETCH
    //
    // fetch exactly two instructions from memory into the fetch buffer
    // unless either one of the buffers is still full, in which case we
    // do nothing (kinda like alpha approach)
    //
    always @(posedge clk) begin: fetch_phase

	did_branchback <= branchback;

	if (branchmiss) begin
	    pc0 <= misspc;
	    pc1 <= misspc + 1;
	    fetchbuf <= 1'b0;
	    fetchbufA_v <= `INV;
	    fetchbufB_v <= `INV;
	    fetchbufC_v <= `INV;
	    fetchbufD_v <= `INV;

	    if (rf_v[1] == `INV && ~livetarget[1])	rf_v[1] <= `VAL;
	    if (rf_v[2] == `INV && ~livetarget[2])	rf_v[2] <= `VAL;
	    if (rf_v[3] == `INV && ~livetarget[3])	rf_v[3] <= `VAL;
	    if (rf_v[4] == `INV && ~livetarget[4])	rf_v[4] <= `VAL;
	    if (rf_v[5] == `INV && ~livetarget[5])	rf_v[5] <= `VAL;
	    if (rf_v[6] == `INV && ~livetarget[6])	rf_v[6] <= `VAL;
	    if (rf_v[7] == `INV && ~livetarget[7])	rf_v[7] <= `VAL;

	    if (|iqentry_0_latestID)	rf_source[ iqentry_tgt[0] ] <= { iqentry_mem[0], 3'd0 };
	    if (|iqentry_1_latestID)	rf_source[ iqentry_tgt[1] ] <= { iqentry_mem[1], 3'd1 };
	    if (|iqentry_2_latestID)	rf_source[ iqentry_tgt[2] ] <= { iqentry_mem[2], 3'd2 };
	    if (|iqentry_3_latestID)	rf_source[ iqentry_tgt[3] ] <= { iqentry_mem[3], 3'd3 };
	    if (|iqentry_4_latestID)	rf_source[ iqentry_tgt[4] ] <= { iqentry_mem[4], 3'd4 };
	    if (|iqentry_5_latestID)	rf_source[ iqentry_tgt[5] ] <= { iqentry_mem[5], 3'd5 };
	    if (|iqentry_6_latestID)	rf_source[ iqentry_tgt[6] ] <= { iqentry_mem[6], 3'd6 };
	    if (|iqentry_7_latestID)	rf_source[ iqentry_tgt[7] ] <= { iqentry_mem[7], 3'd7 };

	end
	else if (branchback) begin

	    // update the fetchbuf valid bits as well as fetchbuf itself
	    // ... this must be based on which things are backwards branches, how many things
	    // will get enqueued (0, 1, or 2), and how old the instructions are
	    if (fetchbuf == 1'b0) case ({fetchbufA_v, fetchbufB_v, fetchbufC_v, fetchbufD_v})

		4'b0000	: ;	// do nothing
		4'b0001	: panic <= `PANIC_INVALIDFBSTATE;
		4'b0010	: panic <= `PANIC_INVALIDFBSTATE;
		4'b0011	: panic <= `PANIC_INVALIDFBSTATE;	// this looks like it might be screwy fetchbuf logic

		// because the first instruction has been enqueued, 
		// we must have noted this in the previous cycle.
		// therefore, pc0 and pc1 have to have been set appropriately ... so do a regular fetch
		// this looks like the following:
		//   cycle 0 - fetched a INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - enqueued fbA, stomped on fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufB_v appropriately
		4'b0100 : begin
			if ({fetchbufB_v, fetchbufB_instr[`INSTRUCTION_OP], fetchbufB_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    fetchbufC_instr <= m[pc0];
			    fetchbufC_v <= `VAL;
			    fetchbufC_pc <= pc0;
			    fetchbufD_instr <= m[pc1];
			    fetchbufD_v <= `VAL;
			    fetchbufD_pc <= pc1;
			    pc0 <= pc0 + 2;
			    pc1 <= pc1 + 2;

			    fetchbufB_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else panic <= `PANIC_BRANCHBACK;
		    end

		4'b0101	: panic <= `PANIC_INVALIDFBSTATE;
		4'b0110	: panic <= `PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - enqueued fbA, but not fbB, recognized branchback in fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbB, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufB_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b0111 : begin
			if ({fetchbufB_v, fetchbufB_instr[`INSTRUCTION_OP], fetchbufB_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    fetchbufB_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else if ({fetchbufC_v, fetchbufC_instr[`INSTRUCTION_OP], fetchbufC_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufB_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else if ({fetchbufD_v, fetchbufD_instr[`INSTRUCTION_OP], fetchbufD_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufB_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else panic <= `PANIC_BRANCHBACK;
		    end

		// this looks like the following:
		//   cycle 0 - fetched a BEQ+INSTR, with fbA holding a branchback
		//   cycle 1 - stomped on fbB, but could not enqueue fbA, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufA_v appropriately
		4'b1000 : begin
			if ({fetchbufA_v, fetchbufA_instr[`INSTRUCTION_OP], fetchbufA_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    fetchbufC_instr <= m[pc0];
			    fetchbufC_v <= `VAL;
			    fetchbufC_pc <= pc0;
			    fetchbufD_instr <= m[pc1];
			    fetchbufD_v <= `VAL;
			    fetchbufD_pc <= pc1;
			    pc0 <= pc0 + 2;
			    pc1 <= pc1 + 2;

			    fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else panic <= `PANIC_BRANCHBACK;
		    end

		4'b1001	: panic <= `PANIC_INVALIDFBSTATE;
		4'b1010	: panic <= `PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched a BEQ+INSTR, with fbA holding a branchback
		//   cycle 1 - stomped on fbB, but could not enqueue fbA, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbA, but fetched from backwards target
		//   cycle 3 - where we are now ... set fetchbufA_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b1011 : begin
			if ({fetchbufA_v, fetchbufA_instr[`INSTRUCTION_OP], fetchbufA_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else if ({fetchbufC_v, fetchbufC_instr[`INSTRUCTION_OP], fetchbufC_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else if ({fetchbufD_v, fetchbufD_instr[`INSTRUCTION_OP], fetchbufD_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else panic <= `PANIC_BRANCHBACK;
		    end

		// if fbB has the branchback, can't immediately tell which of the following scenarios it is:
		//   cycle 0 - fetched a pair of instructions, one or both of which is a branchback
		//   cycle 1 - where we are now.  stomp, enqueue, and update pc0/pc1
		// or
		//   cycle 0 - fetched a INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - could not enqueue fbA or fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufX_v appropriately
		// if fbA has the branchback, then it is scenario 1.
		// if fbB has it: if pc0 == fbB_pc, then it is the former scenario, else it is the latter
		4'b1100 : begin
			if ({fetchbufA_v, fetchbufA_instr[`INSTRUCTION_OP], fetchbufA_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // has to be first scenario
			    pc0 <= backpc;
			    pc1 <= backpc + 1;
			    fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbufB_v <= `INV;		// stomp on it
			    if (~iqentry_v[tail0])	fetchbuf <= 1'b0;
			end
			else if ({fetchbufB_v, fetchbufB_instr[`INSTRUCTION_OP], fetchbufB_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    if (did_branchback) begin
				fetchbufC_instr <= m[pc0];
				fetchbufC_v <= `VAL;
				fetchbufC_pc <= pc0;
				fetchbufD_instr <= m[pc1];
				fetchbufD_v <= `VAL;
				fetchbufD_pc <= pc1;
				pc0 <= pc0 + 2;
				pc1 <= pc1 + 2;

				fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
				fetchbufB_v <= iqentry_v[tail1];	// if it can be queued, it will
				fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
			    end
			    else begin
				pc0 <= backpc;
				pc1 <= backpc + 1;
				fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
				fetchbufB_v <= iqentry_v[tail1];	// if it can be queued, it will
				if (~iqentry_v[tail0] & ~iqentry_v[tail1])	fetchbuf <= 1'b0;
			    end
			end
			else panic <= `PANIC_BRANCHBACK;
		    end

		4'b1101	: panic <= `PANIC_INVALIDFBSTATE;
		4'b1110	: panic <= `PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbB holding a branchback
		//   cycle 1 - enqueued neither fbA nor fbB, recognized branchback in fbB, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbB, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufX_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b1111 : begin
			if ({fetchbufB_v, fetchbufB_instr[`INSTRUCTION_OP], fetchbufB_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbufB_v <= iqentry_v[tail1];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
			end
			else if ({fetchbufC_v, fetchbufC_instr[`INSTRUCTION_OP], fetchbufC_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbufB_v <= iqentry_v[tail1];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
			end
			else if ({fetchbufD_v, fetchbufD_instr[`INSTRUCTION_OP], fetchbufD_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufA_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbufB_v <= iqentry_v[tail1];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
			end
			else panic <= `PANIC_BRANCHBACK;
		    end

	    endcase
	    else case ({fetchbufC_v, fetchbufD_v, fetchbufA_v, fetchbufB_v})

		4'b0000	: ; // do nothing
		4'b0001	: panic <= `PANIC_INVALIDFBSTATE;
		4'b0010	: panic <= `PANIC_INVALIDFBSTATE;
		4'b0011	: panic <= `PANIC_INVALIDFBSTATE;	// this looks like it might be screwy fetchbuf logic

		// because the first instruction has been enqueued, 
		// we must have noted this in the previous cycle.
		// therefore, pc0 and pc1 have to have been set appropriately ... so do a regular fetch
		// this looks like the following:
		//   cycle 0 - fetched a INSTR+BEQ, with fbD holding a branchback
		//   cycle 1 - enqueued fbC, stomped on fbD, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufB_v appropriately
		4'b0100 : begin
			if ({fetchbufD_v, fetchbufD_instr[`INSTRUCTION_OP], fetchbufD_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    fetchbufA_instr <= m[pc0];
			    fetchbufA_v <= `VAL;
			    fetchbufA_pc <= pc0;
			    fetchbufB_instr <= m[pc1];
			    fetchbufB_v <= `VAL;
			    fetchbufB_pc <= pc1;
			    pc0 <= pc0 + 2;
			    pc1 <= pc1 + 2;

			    fetchbufD_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else panic <= `PANIC_BRANCHBACK;
		    end

		4'b0101	: panic <= `PANIC_INVALIDFBSTATE;
		4'b0110	: panic <= `PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbD holding a branchback
		//   cycle 1 - enqueued fbC, but not fbD, recognized branchback in fbD, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbD, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufD_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b0111 : begin
			if ({fetchbufD_v, fetchbufD_instr[`INSTRUCTION_OP], fetchbufD_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    fetchbufD_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else if ({fetchbufA_v, fetchbufA_instr[`INSTRUCTION_OP], fetchbufA_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufD_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else if ({fetchbufB_v, fetchbufB_instr[`INSTRUCTION_OP], fetchbufB_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufD_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else panic <= `PANIC_BRANCHBACK;
		    end

		// this looks like the following:
		//   cycle 0 - fetched a BEQ+INSTR, with fbC holding a branchback
		//   cycle 1 - stomped on fbD, but could not enqueue fbC, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufC_v appropriately
		4'b1000 : begin
			if ({fetchbufC_v, fetchbufC_instr[`INSTRUCTION_OP], fetchbufC_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    fetchbufA_instr <= m[pc0];
			    fetchbufA_v <= `VAL;
			    fetchbufA_pc <= pc0;
			    fetchbufB_instr <= m[pc1];
			    fetchbufB_v <= `VAL;
			    fetchbufB_pc <= pc1;
			    pc0 <= pc0 + 2;
			    pc1 <= pc1 + 2;

			    fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else panic <= `PANIC_BRANCHBACK;
		    end

		4'b1001	: panic <= `PANIC_INVALIDFBSTATE;
		4'b1010	: panic <= `PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched a BEQ+INSTR, with fbC holding a branchback
		//   cycle 1 - stomped on fbD, but could not enqueue fbC, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbC, but fetched from backwards target
		//   cycle 3 - where we are now ... set fetchbufC_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b1011 : begin
			if ({fetchbufC_v, fetchbufC_instr[`INSTRUCTION_OP], fetchbufC_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else if ({fetchbufA_v, fetchbufA_instr[`INSTRUCTION_OP], fetchbufA_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else if ({fetchbufB_v, fetchbufB_instr[`INSTRUCTION_OP], fetchbufB_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + ~iqentry_v[tail0];
			end
			else panic <= `PANIC_BRANCHBACK;
		    end

		// if fbD has the branchback, can't immediately tell which of the following scenarios it is:
		//   cycle 0 - fetched a pair of instructions, one or both of which is a branchback
		//   cycle 1 - where we are now.  stomp, enqueue, and update pc0/pc1
		// or
		//   cycle 0 - fetched a INSTR+BEQ, with fbD holding a branchback
		//   cycle 1 - could not enqueue fbC or fbD, stalled fetch + updated pc0/pc1
		//   cycle 2 - where we are now ... fetch the two instructions & update fetchbufX_v appropriately
		// if fbC has the branchback, then it is scenario 1.
		// if fbD has it: if pc0 == fbB_pc, then it is the former scenario, else it is the latter
		4'b1100 : begin
			if ({fetchbufC_v, fetchbufC_instr[`INSTRUCTION_OP], fetchbufC_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // has to be first scenario
			    pc0 <= backpc;
			    pc1 <= backpc + 1;
			    fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbufD_v <= `INV;		// stomp on it
			    if (~iqentry_v[tail0])	fetchbuf <= 1'b0;
			end
			else if ({fetchbufD_v, fetchbufD_instr[`INSTRUCTION_OP], fetchbufD_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    if (did_branchback) begin
				fetchbufA_instr <= m[pc0];
				fetchbufA_v <= `VAL;
				fetchbufA_pc <= pc0;
				fetchbufB_instr <= m[pc1];
				fetchbufB_v <= `VAL;
				fetchbufB_pc <= pc1;
				pc0 <= pc0 + 2;
				pc1 <= pc1 + 2;

				fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
				fetchbufD_v <= iqentry_v[tail1];	// if it can be queued, it will
				fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
			    end
			    else begin
				pc0 <= backpc;
				pc1 <= backpc + 1;
				fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
				fetchbufD_v <= iqentry_v[tail1];	// if it can be queued, it will
				if (~iqentry_v[tail0] & ~iqentry_v[tail1])	fetchbuf <= 1'b0;
			    end
			end
			else panic <= `PANIC_BRANCHBACK;
		    end

		4'b1101	: panic <= `PANIC_INVALIDFBSTATE;
		4'b1110	: panic <= `PANIC_INVALIDFBSTATE;

		// this looks like the following:
		//   cycle 0 - fetched an INSTR+BEQ, with fbD holding a branchback
		//   cycle 1 - enqueued neither fbC nor fbD, recognized branchback in fbD, stalled fetch + updated pc0/pc1
		//   cycle 2 - still could not enqueue fbD, but fetched from backwards target
		//   cycle 3 - where we are now ... update fetchbufX_v appropriately
		//
		// however -- if there are backwards branches in the latter two slots, it is more complex.
		// simple solution: leave it alone and wait until we are through with the first two slots.
		4'b1111 : begin
			if ({fetchbufD_v, fetchbufD_instr[`INSTRUCTION_OP], fetchbufD_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbufD_v <= iqentry_v[tail1];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
			end
			else if ({fetchbufA_v, fetchbufA_instr[`INSTRUCTION_OP], fetchbufA_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbufD_v <= iqentry_v[tail1];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
			end
			else if ({fetchbufB_v, fetchbufB_instr[`INSTRUCTION_OP], fetchbufB_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) begin
			    // branchback is in later instructions ... do nothing
			    fetchbufC_v <= iqentry_v[tail0];	// if it can be queued, it will
			    fetchbufD_v <= iqentry_v[tail1];	// if it can be queued, it will
			    fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
			end
			else panic <= `PANIC_BRANCHBACK;
		    end
	    endcase

	end // if branchback

	else begin	// there is no branchback in the system
	    //
	    // update fetchbufX_v and fetchbuf ... relatively simple, as
	    // there are no backwards branches in the mix
	    if (fetchbuf == 1'b0) case ({fetchbufA_v, fetchbufB_v, ~iqentry_v[tail0], ~iqentry_v[tail1]})
		4'b00_00 : ;	// do nothing
		4'b00_01 : panic <= `PANIC_INVALIDIQSTATE;
		4'b00_10 : ;	// do nothing
		4'b00_11 : ;	// do nothing
		4'b01_00 : ;	// do nothing
		4'b01_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b01_10,
		4'b01_11 : begin	// enqueue fbB and flip fetchbuf
			fetchbufB_v <= `INV;
			fetchbuf <= ~fetchbuf;
		    end

		4'b10_00 : ;	// do nothing
		4'b10_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b10_10,
		4'b10_11 : begin	// enqueue fbA and flip fetchbuf
			fetchbufA_v <= `INV;
			fetchbuf <= ~fetchbuf;
		    end

		4'b11_00 : ;	// do nothing
		4'b11_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b11_10 : begin	// enqueue fbA but leave fetchbuf
			fetchbufA_v <= `INV;
		    end

		4'b11_11 : begin	// enqueue both and flip fetchbuf
			fetchbufA_v <= `INV;
			fetchbufB_v <= `INV;
			fetchbuf <= ~fetchbuf;
		    end
	    endcase
	    else case ({fetchbufC_v, fetchbufD_v, ~iqentry_v[tail0], ~iqentry_v[tail1]})
		4'b00_00 : ;	// do nothing
		4'b00_01 : panic <= `PANIC_INVALIDIQSTATE;
		4'b00_10 : ;	// do nothing
		4'b00_11 : ;	// do nothing
		4'b01_00 : ;	// do nothing
		4'b01_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b01_10,
		4'b01_11 : begin	// enqueue fbD and flip fetchbuf
			fetchbufD_v <= `INV;
			fetchbuf <= ~fetchbuf;
		    end

		4'b10_00 : ;	// do nothing
		4'b10_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b10_10,
		4'b10_11 : begin	// enqueue fbC and flip fetchbuf
			fetchbufC_v <= `INV;
			fetchbuf <= ~fetchbuf;
		    end

		4'b11_00 : ;	// do nothing
		4'b11_01 : panic <= `PANIC_INVALIDIQSTATE;

		4'b11_10 : begin	// enqueue fbC but leave fetchbuf
			fetchbufC_v <= `INV;
		    end

		4'b11_11 : begin	// enqueue both and flip fetchbuf
			fetchbufC_v <= `INV;
			fetchbufD_v <= `INV;
			fetchbuf <= ~fetchbuf;
		    end
	    endcase
	    //
	    // get data iff the fetch buffers are empty
	    //
	    if (fetchbufA_v == `INV && fetchbufB_v == `INV) begin
		fetchbufA_instr <= m[pc0];
		fetchbufA_v <= `VAL;
		fetchbufA_pc <= pc0;
		fetchbufB_instr <= m[pc1];
		fetchbufB_v <= `VAL;
		fetchbufB_pc <= pc1;
		pc0 <= pc0 + 2;
		pc1 <= pc1 + 2;
	    end
	    else if (fetchbufC_v == `INV && fetchbufD_v == `INV) begin
		fetchbufC_instr <= m[pc0];
		fetchbufC_v <= `VAL;
		fetchbufC_pc <= pc0;
		fetchbufD_instr <= m[pc1];
		fetchbufD_v <= `VAL;
		fetchbufD_pc <= pc1;
		pc0 <= pc0 + 2;
		pc1 <= pc1 + 2;
	    end
	end
    end

    assign fetchbuf0_instr = (fetchbuf == 1'b0) ? fetchbufA_instr : fetchbufC_instr;
    assign fetchbuf0_v     = (fetchbuf == 1'b0) ? fetchbufA_v     : fetchbufC_v    ;
    assign fetchbuf0_pc    = (fetchbuf == 1'b0) ? fetchbufA_pc    : fetchbufC_pc   ;
    assign fetchbuf1_instr = (fetchbuf == 1'b0) ? fetchbufB_instr : fetchbufD_instr;
    assign fetchbuf1_v     = (fetchbuf == 1'b0) ? fetchbufB_v     : fetchbufD_v    ;
    assign fetchbuf1_pc    = (fetchbuf == 1'b0) ? fetchbufB_pc    : fetchbufD_pc   ;

    assign fetchbuf0_mem   = (fetchbuf == 1'b0) 
				? (fetchbufA_instr[`INSTRUCTION_OP] == `LW || fetchbufA_instr[`INSTRUCTION_OP] == `SW)
				: (fetchbufC_instr[`INSTRUCTION_OP] == `LW || fetchbufC_instr[`INSTRUCTION_OP] == `SW);
    assign fetchbuf0_jmp   = (fetchbuf == 1'b0)
				? (fetchbufA_instr[`INSTRUCTION_OP] == `BEQ || fetchbufA_instr[`INSTRUCTION_OP] == `JALR)
				: (fetchbufC_instr[`INSTRUCTION_OP] == `BEQ || fetchbufC_instr[`INSTRUCTION_OP] == `JALR);
    assign fetchbuf0_rfw   = (fetchbuf == 1'b0)
				? (fetchbufA_instr[`INSTRUCTION_OP] != `BEQ && fetchbufA_instr[`INSTRUCTION_OP] != `SW)
				: (fetchbufC_instr[`INSTRUCTION_OP] != `BEQ && fetchbufC_instr[`INSTRUCTION_OP] != `SW);

    assign fetchbuf1_mem   = (fetchbuf == 1'b0) 
				? (fetchbufB_instr[`INSTRUCTION_OP] == `LW || fetchbufB_instr[`INSTRUCTION_OP] == `SW)
				: (fetchbufD_instr[`INSTRUCTION_OP] == `LW || fetchbufD_instr[`INSTRUCTION_OP] == `SW);
    assign fetchbuf1_jmp   = (fetchbuf == 1'b0)
				? (fetchbufB_instr[`INSTRUCTION_OP] == `BEQ || fetchbufB_instr[`INSTRUCTION_OP] == `JALR)
				: (fetchbufD_instr[`INSTRUCTION_OP] == `BEQ || fetchbufD_instr[`INSTRUCTION_OP] == `JALR);
    assign fetchbuf1_rfw   = (fetchbuf == 1'b0)
				? (fetchbufB_instr[`INSTRUCTION_OP] != `BEQ && fetchbufB_instr[`INSTRUCTION_OP] != `SW)
				: (fetchbufD_instr[`INSTRUCTION_OP] != `BEQ && fetchbufD_instr[`INSTRUCTION_OP] != `SW);

    //
    // set branchback and backpc values ... ignore branches in fetchbuf slots not ready for enqueue yet
    //
    assign branchback = ({fetchbuf0_v, fetchbuf0_instr[`INSTRUCTION_OP], fetchbuf0_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) 
			|| ({fetchbuf1_v, fetchbuf1_instr[`INSTRUCTION_OP], fetchbuf1_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH});

    assign backpc = (({fetchbuf0_v, fetchbuf0_instr[`INSTRUCTION_OP], fetchbuf0_instr[`INSTRUCTION_SB]} 
				== {`VAL, `BEQ, `BACK_BRANCH}) 
			    ? (fetchbuf0_pc + 1 + { {9 {fetchbuf0_instr[`INSTRUCTION_SB]}}, fetchbuf0_instr[`INSTRUCTION_IM]})
			    : (fetchbuf1_pc + 1 + { {9 {fetchbuf1_instr[`INSTRUCTION_SB]}}, fetchbuf1_instr[`INSTRUCTION_IM]}));

    //
    // BRANCH-MISS LOGIC: livetarget
    //
    // livetarget implies that there is a not-to-be-stomped instruction that targets the register in question
    // therefore, if it is zero it implies the rf_v value should become VALID on a branchmiss
    // 

    assign  livetarget[1] = iqentry_0_livetarget[1] | iqentry_1_livetarget[1] | iqentry_2_livetarget[1] | iqentry_3_livetarget[1]
			    | iqentry_4_livetarget[1] | iqentry_5_livetarget[1] | iqentry_6_livetarget[1] | iqentry_7_livetarget[1];

    assign  livetarget[2] = iqentry_0_livetarget[2] | iqentry_1_livetarget[2] | iqentry_2_livetarget[2] | iqentry_3_livetarget[2]
			    | iqentry_4_livetarget[2] | iqentry_5_livetarget[2] | iqentry_6_livetarget[2] | iqentry_7_livetarget[2];

    assign  livetarget[3] = iqentry_0_livetarget[3] | iqentry_1_livetarget[3] | iqentry_2_livetarget[3] | iqentry_3_livetarget[3]
			    | iqentry_4_livetarget[3] | iqentry_5_livetarget[3] | iqentry_6_livetarget[3] | iqentry_7_livetarget[3];

    assign  livetarget[4] = iqentry_0_livetarget[4] | iqentry_1_livetarget[4] | iqentry_2_livetarget[4] | iqentry_3_livetarget[4]
			    | iqentry_4_livetarget[4] | iqentry_5_livetarget[4] | iqentry_6_livetarget[4] | iqentry_7_livetarget[4];

    assign  livetarget[5] = iqentry_0_livetarget[5] | iqentry_1_livetarget[5] | iqentry_2_livetarget[5] | iqentry_3_livetarget[5]
			    | iqentry_4_livetarget[5] | iqentry_5_livetarget[5] | iqentry_6_livetarget[5] | iqentry_7_livetarget[5];

    assign  livetarget[6] = iqentry_0_livetarget[6] | iqentry_1_livetarget[6] | iqentry_2_livetarget[6] | iqentry_3_livetarget[6]
			    | iqentry_4_livetarget[6] | iqentry_5_livetarget[6] | iqentry_6_livetarget[6] | iqentry_7_livetarget[6];

    assign  livetarget[7] = iqentry_0_livetarget[7] | iqentry_1_livetarget[7] | iqentry_2_livetarget[7] | iqentry_3_livetarget[7]
			    | iqentry_4_livetarget[7] | iqentry_5_livetarget[7] | iqentry_6_livetarget[7] | iqentry_7_livetarget[7];

    assign  iqentry_0_livetarget = {7 {iqentry_v[0]}} & {7 {~iqentry_stomp[0]}} & iq0_out,
	    iqentry_1_livetarget = {7 {iqentry_v[1]}} & {7 {~iqentry_stomp[1]}} & iq1_out,
	    iqentry_2_livetarget = {7 {iqentry_v[2]}} & {7 {~iqentry_stomp[2]}} & iq2_out,
	    iqentry_3_livetarget = {7 {iqentry_v[3]}} & {7 {~iqentry_stomp[3]}} & iq3_out,
	    iqentry_4_livetarget = {7 {iqentry_v[4]}} & {7 {~iqentry_stomp[4]}} & iq4_out,
	    iqentry_5_livetarget = {7 {iqentry_v[5]}} & {7 {~iqentry_stomp[5]}} & iq5_out,
	    iqentry_6_livetarget = {7 {iqentry_v[6]}} & {7 {~iqentry_stomp[6]}} & iq6_out,
	    iqentry_7_livetarget = {7 {iqentry_v[7]}} & {7 {~iqentry_stomp[7]}} & iq7_out;

    //
    // BRANCH-MISS LOGIC: latestID
    //
    // latestID is the instruction queue ID of the newest instruction (latest) that targets
    // a particular register.  looks a lot like scheduling logic, but in reverse.
    // 

    assign iqentry_0_latestID = (missid == 3'd0 || ((iqentry_0_livetarget & iqentry_1_cumulative) == 7'd0))
				    ? iqentry_0_livetarget
				    : 7'd0;
    assign iqentry_0_cumulative = (missid == 3'd0)
				    ? iqentry_0_livetarget
				    : iqentry_0_livetarget | iqentry_1_cumulative;

    assign iqentry_1_latestID = (missid == 3'd1 || ((iqentry_1_livetarget & iqentry_2_cumulative) == 7'd0))
				    ? iqentry_1_livetarget
				    : 7'd0;
    assign iqentry_1_cumulative = (missid == 3'd1)
				    ? iqentry_1_livetarget
				    : iqentry_1_livetarget | iqentry_2_cumulative;

    assign iqentry_2_latestID = (missid == 3'd2 || ((iqentry_2_livetarget & iqentry_3_cumulative) == 7'd0))
				    ? iqentry_2_livetarget
				    : 7'd0;
    assign iqentry_2_cumulative = (missid == 3'd2)
				    ? iqentry_2_livetarget
				    : iqentry_2_livetarget | iqentry_3_cumulative;

    assign iqentry_3_latestID = (missid == 3'd3 || ((iqentry_3_livetarget & iqentry_4_cumulative) == 7'd0))
				    ? iqentry_3_livetarget
				    : 7'd0;
    assign iqentry_3_cumulative = (missid == 3'd3)
				    ? iqentry_3_livetarget
				    : iqentry_3_livetarget | iqentry_4_cumulative;

    assign iqentry_4_latestID = (missid == 3'd4 || ((iqentry_4_livetarget & iqentry_5_cumulative) == 7'd0))
				    ? iqentry_4_livetarget
				    : 7'd0;
    assign iqentry_4_cumulative = (missid == 3'd4)
				    ? iqentry_4_livetarget
				    : iqentry_4_livetarget | iqentry_5_cumulative;

    assign iqentry_5_latestID = (missid == 3'd5 || ((iqentry_5_livetarget & iqentry_6_cumulative) == 7'd0))
				    ? iqentry_5_livetarget
				    : 7'd0;
    assign iqentry_5_cumulative = (missid == 3'd5)
				    ? iqentry_5_livetarget
				    : iqentry_5_livetarget | iqentry_6_cumulative;

    assign iqentry_6_latestID = (missid == 3'd6 || ((iqentry_6_livetarget & iqentry_7_cumulative) == 7'd0))
				    ? iqentry_6_livetarget
				    : 7'd0;
    assign iqentry_6_cumulative = (missid == 3'd6)
				    ? iqentry_6_livetarget
				    : iqentry_6_livetarget | iqentry_7_cumulative;

    assign iqentry_7_latestID = (missid == 3'd7 || ((iqentry_7_livetarget & iqentry_0_cumulative) == 7'd0))
				    ? iqentry_7_livetarget
				    : 7'd0;
    assign iqentry_7_cumulative = (missid == 3'd7)
				    ? iqentry_7_livetarget
				    : iqentry_7_livetarget | iqentry_0_cumulative;

    assign  iqentry_source[0] = | iqentry_0_latestID,
	    iqentry_source[1] = | iqentry_1_latestID,
	    iqentry_source[2] = | iqentry_2_latestID,
	    iqentry_source[3] = | iqentry_3_latestID,
	    iqentry_source[4] = | iqentry_4_latestID,
	    iqentry_source[5] = | iqentry_5_latestID,
	    iqentry_source[6] = | iqentry_6_latestID,
	    iqentry_source[7] = | iqentry_7_latestID;

    //
    // ENQUEUE
    //
    // place up to two instructions from the fetch buffer into slots in the IQ.
    //   note: they are placed in-order, and they are expected to be executed
    // 0, 1, or 2 of the fetch buffers may have valid data
    // 0, 1, or 2 slots in the instruction queue may be available.
    // if we notice that one of the instructions in the fetch buffer is a backwards branch,
    // predict it taken (set branchback/backpc and delete any instructions after it in fetchbuf)
    //
    always @(posedge clk) begin: enqueue_phase

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
	    rf[ commit0_tgt ] = commit0_bus;
	    if (!rf_v[ commit0_tgt ]) 
		rf_v[ commit0_tgt ] = rf_source[ commit0_tgt ] == commit0_id || (branchmiss && iqentry_source[ commit0_id[2:0] ]);
	    if (commit0_tgt != 3'd0) $display("r%d <- %h", commit0_tgt, commit0_bus);
	end
	if (commit1_v) begin
	    rf[ commit1_tgt ] = commit1_bus;
	    if (!rf_v[ commit1_tgt ]) 
		rf_v[ commit1_tgt ] = rf_source[ commit1_tgt ] == commit1_id || (branchmiss && iqentry_source[ commit1_id[2:0] ]);
	    if (commit1_tgt != 3'd0) $display("r%d <- %h", commit1_tgt, commit1_bus);
	end

	rf[0] = 0;
	rf_v[0] = 1;

	//
	// enqueue fetchbuf0 and fetchbuf1, but only if there is room, 
	// and ignore fetchbuf1 if fetchbuf0 has a backwards branch in it.
	//
	// also, do some instruction-decode ... set the operand_valid bits in the IQ
	// appropriately so that the DATAINCOMING stage does not have to look at the opcode
	//
	if (!branchmiss) 	// don't bother doing anything if there's been a branch miss

	case ({fetchbuf0_v, fetchbuf1_v})

	    2'b00: ; // do nothing

	    2'b01: if (iqentry_v[tail0] == `INV) begin

		iqentry_v    [tail0]    <=   `VAL;
		iqentry_done [tail0]    <=   `INV;
		iqentry_out  [tail0]    <=   `INV;
		iqentry_res  [tail0]    <=   `ZERO;
		iqentry_op   [tail0]    <=   fetchbuf1_instr[`INSTRUCTION_OP]; 
		iqentry_bt   [tail0]    <=   (fetchbuf1_instr[`INSTRUCTION_OP] == `BEQ 
						&& fetchbuf1_instr[`INSTRUCTION_SB] == `BACK_BRANCH); 
		iqentry_agen [tail0]    <=   `INV;
		iqentry_pc   [tail0]    <=   fetchbuf1_pc;
		iqentry_mem  [tail0]    <=   fetchbuf1_mem;
		iqentry_jmp  [tail0]    <=   fetchbuf1_jmp;
		iqentry_rfw  [tail0]    <=   fetchbuf1_rfw;
		iqentry_tgt  [tail0]    <=   fetchbuf1_rfw ? fetchbuf1_instr[`INSTRUCTION_RA] : 3'd0;
		iqentry_exc  [tail0]    <=   `EXC_NONE;
		iqentry_a0   [tail0]    <=   (fetchbuf1_instr[`INSTRUCTION_OP] == `LUI)
					      ? {fetchbuf1_instr[`INSTRUCTION_LI], 6'd0}
					      : {{9 {fetchbuf1_instr[`INSTRUCTION_SB]}}, fetchbuf1_instr[`INSTRUCTION_IM]};
		iqentry_a1   [tail0]    <=   rf [fetchbuf1_instr[`INSTRUCTION_RB]];
		iqentry_a1_v [tail0]    <=   source1_v[ fetchbuf1_instr[`INSTRUCTION_OP] ]
						| rf_v[ fetchbuf1_instr[`INSTRUCTION_RB] ];
		iqentry_a1_s [tail0]    <=   rf_source [fetchbuf1_instr[`INSTRUCTION_RB]];
		iqentry_a2   [tail0]    <=   (fetchbuf1_rfw) 
					      ? ((fetchbuf1_instr[`INSTRUCTION_OP] == `JALR)
						 ? fetchbuf1_pc
						 : rf[ fetchbuf1_instr[`INSTRUCTION_RC] ])
					      : rf[ fetchbuf1_instr[`INSTRUCTION_RA] ];
		iqentry_a2_v [tail0]    <=   source2_v[ fetchbuf1_instr[`INSTRUCTION_OP] ]
					      | (fetchbuf1_rfw
						  ? rf_v[ fetchbuf1_instr[`INSTRUCTION_RC] ]
						  : rf_v[ fetchbuf1_instr[`INSTRUCTION_RA] ]);
		iqentry_a2_s [tail0]    <=   (fetchbuf1_rfw
					      ? rf_source[ fetchbuf1_instr[`INSTRUCTION_RC] ]
					      : rf_source[ fetchbuf1_instr[`INSTRUCTION_RA] ]);
		tail0 <= tail0 + 1;
		tail1 <= tail1 + 1;
		if (fetchbuf1_rfw) begin
		    rf_v[ fetchbuf1_instr[`INSTRUCTION_RA] ] <= `INV;
		    rf_source[ fetchbuf1_instr[`INSTRUCTION_RA] ] <= { fetchbuf1_mem, tail0 };	// top bit indicates ALU/MEM bus
		end

	    end

	    2'b10: if (iqentry_v[tail0] == `INV) begin
		if (fetchbuf0_instr[`INSTRUCTION_OP] != `BEQ)		panic <= `PANIC_FETCHBUFBEQ;
		if (fetchbuf0_instr[`INSTRUCTION_SB] != `BACK_BRANCH)	panic <= `PANIC_FETCHBUFBEQ;
		//
		// this should only happen when the first instruction is a BEQ-backwards and the IQ
		// happened to be full on the previous cycle (thus we deleted fetchbuf1 but did not
		// enqueue fetchbuf0) ... probably no need to check for LW -- sanity check, just in case
		//

		iqentry_v    [tail0]	<=	`VAL;
		iqentry_done [tail0]	<=	`INV;
		iqentry_out  [tail0]	<=	`INV;
		iqentry_res  [tail0]	<=	`ZERO;
		iqentry_op   [tail0]	<=	fetchbuf0_instr[`INSTRUCTION_OP]; 			// BEQ
		iqentry_bt   [tail0]    <=	`VAL;
		iqentry_agen [tail0]    <=	`INV;
		iqentry_pc   [tail0]    <=	fetchbuf0_pc;
		iqentry_mem  [tail0]    <=	fetchbuf0_mem;
		iqentry_jmp  [tail0]    <=	fetchbuf0_jmp;
		iqentry_rfw  [tail0]    <=	fetchbuf0_rfw;
		iqentry_tgt  [tail0]    <=	fetchbuf0_rfw ? fetchbuf0_instr[`INSTRUCTION_RA] : 3'd0;
		iqentry_exc  [tail0]    <=	`EXC_NONE;
		iqentry_a0   [tail0]	<=	{{9 {fetchbuf0_instr[`INSTRUCTION_SB]}}, fetchbuf0_instr[`INSTRUCTION_IM]};
		iqentry_a1   [tail0]	<=	rf [fetchbuf0_instr[`INSTRUCTION_RB]];
		iqentry_a1_v [tail0]    <=	rf_v [fetchbuf0_instr[`INSTRUCTION_RB]];
		iqentry_a1_s [tail0]	<=	rf_source [fetchbuf0_instr[`INSTRUCTION_RB]];
		iqentry_a2   [tail0]	<=	rf[ fetchbuf0_instr[`INSTRUCTION_RA] ];
		iqentry_a2_v [tail0]    <=	rf_v[ fetchbuf0_instr[`INSTRUCTION_RA] ];
		iqentry_a2_s [tail0]	<=	rf_source[ fetchbuf0_instr[`INSTRUCTION_RA] ];
		tail0 <= tail0 + 1;
		tail1 <= tail1 + 1;

	    end

	    2'b11: if (iqentry_v[tail0] == `INV) begin

		//
		// if the first instruction is a backwards branch, enqueue it & stomp on all following instructions
		//
		if ({fetchbuf0_instr[`INSTRUCTION_OP], fetchbuf0_instr[`INSTRUCTION_SB]} == {`BEQ, `BACK_BRANCH}) begin

		    iqentry_v    [tail0]    <=	`VAL;
		    iqentry_done [tail0]    <=	`INV;
		    iqentry_out  [tail0]    <=	`INV;
		    iqentry_res  [tail0]    <=	`ZERO;
		    iqentry_op   [tail0]    <=	fetchbuf0_instr[`INSTRUCTION_OP]; 			// BEQ
		    iqentry_bt   [tail0]    <=	`VAL;
		    iqentry_agen [tail0]    <=	`INV;
		    iqentry_pc   [tail0]    <=	fetchbuf0_pc;
		    iqentry_mem  [tail0]    <=	fetchbuf0_mem;
		    iqentry_jmp  [tail0]    <=	fetchbuf0_jmp;
		    iqentry_rfw  [tail0]    <=	fetchbuf0_rfw;
		    iqentry_tgt  [tail0]    <=	fetchbuf0_rfw ? fetchbuf0_instr[`INSTRUCTION_RA] : 3'd0;
		    iqentry_exc  [tail0]    <=	`EXC_NONE;
		    iqentry_a0   [tail0]    <=	{{9 {fetchbuf0_instr[`INSTRUCTION_SB]}}, fetchbuf0_instr[`INSTRUCTION_IM]};
		    iqentry_a1   [tail0]    <=	rf [fetchbuf0_instr[`INSTRUCTION_RB]];
		    iqentry_a1_v [tail0]    <=	rf_v [fetchbuf0_instr[`INSTRUCTION_RB]];
		    iqentry_a1_s [tail0]    <=	rf_source [fetchbuf0_instr[`INSTRUCTION_RB]];
		    iqentry_a2   [tail0]    <=	rf[ fetchbuf0_instr[`INSTRUCTION_RA] ];
		    iqentry_a2_v [tail0]    <=	rf_v[ fetchbuf0_instr[`INSTRUCTION_RA] ];
		    iqentry_a2_s [tail0]    <=	rf_source[ fetchbuf0_instr[`INSTRUCTION_RA] ];
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
		    iqentry_out  [tail0]    <=   `INV;
		    iqentry_res  [tail0]    <=   `ZERO;
		    iqentry_op   [tail0]    <=   fetchbuf0_instr[`INSTRUCTION_OP]; 
		    iqentry_bt   [tail0]    <=   `INV;
		    iqentry_agen [tail0]    <=   `INV;
		    iqentry_pc   [tail0]    <=   fetchbuf0_pc;
		    iqentry_mem  [tail0]    <=   fetchbuf0_mem;
		    iqentry_jmp  [tail0]    <=   fetchbuf0_jmp;
		    iqentry_rfw  [tail0]    <=   fetchbuf0_rfw;
		    iqentry_tgt  [tail0]    <=   fetchbuf0_rfw ? fetchbuf0_instr[`INSTRUCTION_RA] : 3'd0;
		    iqentry_exc  [tail0]    <=   `EXC_NONE;
		    iqentry_a0   [tail0]    <=   (fetchbuf0_instr[`INSTRUCTION_OP] == `LUI)
						  ? {fetchbuf0_instr[`INSTRUCTION_LI], 6'd0}
						  : {{9 {fetchbuf0_instr[`INSTRUCTION_SB]}}, fetchbuf0_instr[`INSTRUCTION_IM]};
		    iqentry_a1   [tail0]    <=   rf [fetchbuf0_instr[`INSTRUCTION_RB]];
		    iqentry_a1_v [tail0]    <=   source1_v[ fetchbuf0_instr[`INSTRUCTION_OP] ]
						    | rf_v[ fetchbuf0_instr[`INSTRUCTION_RB] ];
		    iqentry_a1_s [tail0]    <=   rf_source [fetchbuf0_instr[`INSTRUCTION_RB]];
		    iqentry_a2   [tail0]    <=   (fetchbuf0_rfw) 
						  ? ((fetchbuf0_instr[`INSTRUCTION_OP] == `JALR)
						     ? fetchbuf0_pc
						     : rf[ fetchbuf0_instr[`INSTRUCTION_RC] ])
						  : rf[ fetchbuf0_instr[`INSTRUCTION_RA] ];
		    iqentry_a2_v [tail0]    <=   source2_v[ fetchbuf0_instr[`INSTRUCTION_OP] ]
						  | (fetchbuf0_rfw
						      ? rf_v[ fetchbuf0_instr[`INSTRUCTION_RC] ]
						      : rf_v[ fetchbuf0_instr[`INSTRUCTION_RA] ]);
		    iqentry_a2_s [tail0]    <=   (fetchbuf0_rfw
						  ? rf_source[ fetchbuf0_instr[`INSTRUCTION_RC] ]
						  : rf_source[ fetchbuf0_instr[`INSTRUCTION_RA] ]);

		    //
		    // if there is room for a second instruction, enqueue it
		    //
		    if (iqentry_v[tail1] == `INV) begin

			iqentry_v    [tail1]    <=   `VAL;
			iqentry_done [tail1]    <=   `INV;
			iqentry_out  [tail1]    <=   `INV;
			iqentry_res  [tail1]    <=   `ZERO;
			iqentry_op   [tail1]    <=   fetchbuf1_instr[`INSTRUCTION_OP]; 
			iqentry_bt   [tail1]    <=   (fetchbuf1_instr[`INSTRUCTION_OP] == `BEQ 
							&& fetchbuf1_instr[`INSTRUCTION_SB] == `BACK_BRANCH); 
			iqentry_agen [tail1]    <=   `INV;
			iqentry_pc   [tail1]    <=   fetchbuf1_pc;
			iqentry_mem  [tail1]    <=   fetchbuf1_mem;
			iqentry_jmp  [tail1]    <=   fetchbuf1_jmp;
			iqentry_rfw  [tail1]    <=   fetchbuf1_rfw;
			iqentry_tgt  [tail1]    <=   fetchbuf1_rfw ? fetchbuf1_instr[`INSTRUCTION_RA] : 3'd0;
			iqentry_exc  [tail1]    <=   `EXC_NONE;
			iqentry_a0   [tail1]    <=   (fetchbuf1_instr[`INSTRUCTION_OP] == `LUI)
						      ? {fetchbuf1_instr[`INSTRUCTION_LI], 6'd0}
						      : {{9 {fetchbuf1_instr[`INSTRUCTION_SB]}}, fetchbuf1_instr[`INSTRUCTION_IM]};
			iqentry_a1   [tail1]    <=   rf [fetchbuf1_instr[`INSTRUCTION_RB]];
			iqentry_a2   [tail1]    <=   (fetchbuf1_rfw) 
						      ? ((fetchbuf1_instr[`INSTRUCTION_OP] == `JALR)
							 ? fetchbuf1_pc
							 : rf[ fetchbuf1_instr[`INSTRUCTION_RC] ])
						      : rf[ fetchbuf1_instr[`INSTRUCTION_RA] ];

			// a1/a2_v and a1/a2_s values require a bit of thinking ...

			//
			// SOURCE 1 ... this is relatively straightforward, because all instructions
			// that have a source (i.e. every instruction but LUI) read from RB
			//
			// if the argument is an immediate or not needed, we're done
			if (source1_v[ fetchbuf1_instr[`INSTRUCTION_OP] ] == `VAL) begin
			    iqentry_a1_v [tail1] <= `VAL;
			    iqentry_a1_s [tail1] <= 4'd0;
			end
			// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
			else if (~fetchbuf0_rfw) begin
			    iqentry_a1_v [tail1]    <=   rf_v [fetchbuf1_instr[`INSTRUCTION_RB]];
			    iqentry_a1_s [tail1]    <=   rf_source [fetchbuf1_instr[`INSTRUCTION_RB]];
			end
			// otherwise, previous instruction does write to RF ... see if overlap
			else if (fetchbuf0_instr[`INSTRUCTION_RA] != 3'd0
				&& fetchbuf1_instr[`INSTRUCTION_RB] == fetchbuf0_instr[`INSTRUCTION_RA]) begin
			    // if the previous instruction is a LW, then grab result from memq, not the iq
			    iqentry_a1_v [tail1]    <=   `INV;
			    iqentry_a1_s [tail1]    <=   { fetchbuf0_mem, tail0 };
			end
			// if no overlap, get info from rf_v and rf_source
			else begin
			    iqentry_a1_v [tail1]    <=   rf_v [fetchbuf1_instr[`INSTRUCTION_RB]];
			    iqentry_a1_s [tail1]    <=   rf_source [fetchbuf1_instr[`INSTRUCTION_RB]];
			end

			//
			// SOURCE 2 ... this is more contorted than the logic for SOURCE 1 because
			// some instructions (NAND and ADD) read from RC and others (SW, BEQ) read from RA
			//
			// if the argument is an immediate or not needed, we're done
			if (source2_v[ fetchbuf1_instr[`INSTRUCTION_OP] ] == `VAL) begin
			    iqentry_a2_v [tail1] <= `VAL;
			    iqentry_a2_s [tail1] <= 4'd0;
			end
			// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
			else if (~fetchbuf0_rfw) begin
			    iqentry_a2_v [tail1] <= ((fetchbuf1_instr[`INSTRUCTION_OP] == `ADD 
							|| fetchbuf1_instr[`INSTRUCTION_OP] == `NAND)
						      ? rf_v[ fetchbuf1_instr[`INSTRUCTION_RC] ]
						      : rf_v[ fetchbuf1_instr[`INSTRUCTION_RA] ]);
			    iqentry_a2_s [tail1] <= ((fetchbuf1_instr[`INSTRUCTION_OP] == `ADD 
							|| fetchbuf1_instr[`INSTRUCTION_OP] == `NAND)
						      ? rf_source[ fetchbuf1_instr[`INSTRUCTION_RC] ]
						      : rf_source[ fetchbuf1_instr[`INSTRUCTION_RA] ]);
			end
			// otherwise, previous instruction does write to RF ... see if overlap
			else if (fetchbuf0_instr[`INSTRUCTION_RA] != 3'd0 &&
				(((fetchbuf1_instr[`INSTRUCTION_OP] == `ADD || fetchbuf1_instr[`INSTRUCTION_OP] == `NAND)
				     && fetchbuf1_instr[`INSTRUCTION_RC] == fetchbuf0_instr[`INSTRUCTION_RA])
				  || 
				 ((fetchbuf1_instr[`INSTRUCTION_OP] == `SW || fetchbuf1_instr[`INSTRUCTION_OP] == `BEQ)
				     && fetchbuf1_instr[`INSTRUCTION_RA] == fetchbuf0_instr[`INSTRUCTION_RA]))) begin
			    // if the previous instruction is a LW, then grab result from memq, not the iq
			    iqentry_a2_v [tail1]    <=   `INV;
			    iqentry_a2_s [tail1]    <=   { fetchbuf0_mem, tail0 };
			end
			// if no overlap, get info from rf_v and rf_source
			else begin
			    iqentry_a2_v [tail1] <= ((fetchbuf1_instr[`INSTRUCTION_OP] == `ADD 
							|| fetchbuf1_instr[`INSTRUCTION_OP] == `NAND)
						      ? rf_v[ fetchbuf1_instr[`INSTRUCTION_RC] ]
						      : rf_v[ fetchbuf1_instr[`INSTRUCTION_RA] ]);
			    iqentry_a2_s [tail1] <= ((fetchbuf1_instr[`INSTRUCTION_OP] == `ADD 
							|| fetchbuf1_instr[`INSTRUCTION_OP] == `NAND)
						      ? rf_source[ fetchbuf1_instr[`INSTRUCTION_RC] ]
						      : rf_source[ fetchbuf1_instr[`INSTRUCTION_RA] ]);
			end

			//
			// if the two instructions enqueued target the same register, 
			// make sure only the second writes to rf_v and rf_source.
			// first is allowed to update rf_v and rf_source only if the
			// second has no target (BEQ or SW)
			//
			if (fetchbuf0_instr[`INSTRUCTION_RA] == fetchbuf1_instr[`INSTRUCTION_RA]) begin
			    if (fetchbuf1_rfw) begin
				rf_v[ fetchbuf1_instr[`INSTRUCTION_RA] ] <= `INV;
				rf_source[ fetchbuf1_instr[`INSTRUCTION_RA] ] <= { fetchbuf1_mem, tail1 };
			    end
			    else if (fetchbuf0_rfw) begin
				rf_v[ fetchbuf0_instr[`INSTRUCTION_RA] ] <= `INV;
				rf_source[ fetchbuf0_instr[`INSTRUCTION_RA] ] <= { fetchbuf0_mem, tail0 };
			    end
			end
			else begin
			    if (fetchbuf0_rfw) begin
				rf_v[ fetchbuf0_instr[`INSTRUCTION_RA] ] <= `INV;
				rf_source[ fetchbuf0_instr[`INSTRUCTION_RA] ] <= { fetchbuf0_mem, tail0 };
			    end
			    if (fetchbuf1_rfw) begin
				rf_v[ fetchbuf1_instr[`INSTRUCTION_RA] ] <= `INV;
				rf_source[ fetchbuf1_instr[`INSTRUCTION_RA] ] <= { fetchbuf1_mem, tail1 };
			    end
			end

		    end	// ends the "if IQ[tail1] is available" clause
		    else begin	// only first instruction was enqueued
			if (fetchbuf0_rfw) begin
			    rf_v[ fetchbuf0_instr[`INSTRUCTION_RA] ] <= `INV;
			    rf_source[ fetchbuf0_instr[`INSTRUCTION_RA] ] <= {fetchbuf0_mem, tail0};
			end
		    end

		end	// ends the "else fetchbuf0 doesn't have a backwards branch" clause
	    end
	endcase
	else begin	// if branchmiss
	    if (iqentry_stomp[0] & ~iqentry_stomp[7]) begin
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
    end

    //
    // DATAINCOMING
    //
    // wait for operand/s to appear on alu busses and puts them into 
    // the iqentry_a1 and iqentry_a2 slots (if appropriate)
    // as well as the appropriate iqentry_res slots (and setting valid bits)
    //
    always @(posedge clk) begin: dataincoming_phase
	//
	// put results into the appropriate instruction entries
	//
	if (alu0_v) begin
	    iqentry_res	[ alu0_id[2:0] ] <= alu0_bus;
	    iqentry_exc	[ alu0_id[2:0] ] <= alu0_exc;
	    iqentry_done[ alu0_id[2:0] ] <= (iqentry_op[ alu0_id[2:0] ] != `LW && iqentry_op[ alu0_id[2:0] ] != `SW);
	    iqentry_out	[ alu0_id[2:0] ] <= `INV;
	    iqentry_agen[ alu0_id[2:0] ] <= `VAL;
	end
	if (alu1_v) begin
	    iqentry_res	[ alu1_id[2:0] ] <= alu1_bus;
	    iqentry_exc	[ alu1_id[2:0] ] <= alu1_exc;
	    iqentry_done[ alu1_id[2:0] ] <= (iqentry_op[ alu1_id[2:0] ] != `LW && iqentry_op[ alu1_id[2:0] ] != `SW);
	    iqentry_out	[ alu1_id[2:0] ] <= `INV;
	    iqentry_agen[ alu1_id[2:0] ] <= `VAL;
	end
	if (dram_v && iqentry_v[ dram_id[2:0] ] && iqentry_mem[ dram_id[2:0] ] ) begin	// if data for stomped instruction, ignore
	    iqentry_res	[ dram_id[2:0] ] <= dram_bus;
	    iqentry_exc	[ dram_id[2:0] ] <= dram_exc;
	    iqentry_done[ dram_id[2:0] ] <= `VAL;
	end

	//
	// set the IQ entry == DONE as soon as the SW is let loose to the memory system
	//
	if (dram0 == 2'd1 && dram0_op == `SW) begin
	    if ((alu0_v && dram0_id[2:0] == alu0_id[2:0]) || (alu1_v && dram0_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
	    iqentry_done[ dram0_id[2:0] ] <= `VAL;
	    iqentry_out[ dram0_id[2:0] ] <= `INV;
	end
	if (dram1 == 2'd1 && dram1_op == `SW) begin
	    if ((alu0_v && dram1_id[2:0] == alu0_id[2:0]) || (alu1_v && dram1_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
	    iqentry_done[ dram1_id[2:0] ] <= `VAL;
	    iqentry_out[ dram1_id[2:0] ] <= `INV;
	end
	if (dram2 == 2'd1 && dram2_op == `SW) begin
	    if ((alu0_v && dram2_id[2:0] == alu0_id[2:0]) || (alu1_v && dram2_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
	    iqentry_done[ dram2_id[2:0] ] <= `VAL;
	    iqentry_out[ dram2_id[2:0] ] <= `INV;
	end

	//
	// see if anybody else wants the results ... look at lots of buses:
	//  - alu0_bus
	//  - alu1_bus
	//  - dram_bus
	//  - commit0_bus
	//  - commit1_bus
	//

	if (iqentry_a1_v[0] == `INV && iqentry_a1_s[0] == alu0_id && iqentry_v[0] == `VAL && alu0_v == `VAL) begin
	    iqentry_a1[0] <= alu0_bus;
	    iqentry_a1_v[0] <= `VAL;
	end
	if (iqentry_a2_v[0] == `INV && iqentry_a2_s[0] == alu0_id && iqentry_v[0] == `VAL && alu0_v == `VAL) begin
	    iqentry_a2[0] <= alu0_bus;
	    iqentry_a2_v[0] <= `VAL;
	end
	if (iqentry_a1_v[0] == `INV && iqentry_a1_s[0] == alu1_id && iqentry_v[0] == `VAL && alu1_v == `VAL) begin
	    iqentry_a1[0] <= alu1_bus;
	    iqentry_a1_v[0] <= `VAL;
	end
	if (iqentry_a2_v[0] == `INV && iqentry_a2_s[0] == alu1_id && iqentry_v[0] == `VAL && alu1_v == `VAL) begin
	    iqentry_a2[0] <= alu1_bus;
	    iqentry_a2_v[0] <= `VAL;
	end
	if (iqentry_a1_v[0] == `INV && iqentry_a1_s[0] == dram_id && iqentry_v[0] == `VAL && dram_v == `VAL) begin
	    iqentry_a1[0] <= dram_bus;
	    iqentry_a1_v[0] <= `VAL;
	end
	if (iqentry_a2_v[0] == `INV && iqentry_a2_s[0] == dram_id && iqentry_v[0] == `VAL && dram_v == `VAL) begin
	    iqentry_a2[0] <= dram_bus;
	    iqentry_a2_v[0] <= `VAL;
	end
	if (iqentry_a1_v[0] == `INV && iqentry_a1_s[0] == commit0_id && iqentry_v[0] == `VAL && commit0_v == `VAL) begin
	    iqentry_a1[0] <= commit0_bus;
	    iqentry_a1_v[0] <= `VAL;
	end
	if (iqentry_a2_v[0] == `INV && iqentry_a2_s[0] == commit0_id && iqentry_v[0] == `VAL && commit0_v == `VAL) begin
	    iqentry_a2[0] <= commit0_bus;
	    iqentry_a2_v[0] <= `VAL;
	end
	if (iqentry_a1_v[0] == `INV && iqentry_a1_s[0] == commit1_id && iqentry_v[0] == `VAL && commit1_v == `VAL) begin
	    iqentry_a1[0] <= commit1_bus;
	    iqentry_a1_v[0] <= `VAL;
	end
	if (iqentry_a2_v[0] == `INV && iqentry_a2_s[0] == commit1_id && iqentry_v[0] == `VAL && commit1_v == `VAL) begin
	    iqentry_a2[0] <= commit1_bus;
	    iqentry_a2_v[0] <= `VAL;
	end

	if (iqentry_a1_v[1] == `INV && iqentry_a1_s[1] == alu0_id && iqentry_v[1] == `VAL && alu0_v == `VAL) begin
	    iqentry_a1[1] <= alu0_bus;
	    iqentry_a1_v[1] <= `VAL;
	end
	if (iqentry_a2_v[1] == `INV && iqentry_a2_s[1] == alu0_id && iqentry_v[1] == `VAL && alu0_v == `VAL) begin
	    iqentry_a2[1] <= alu0_bus;
	    iqentry_a2_v[1] <= `VAL;
	end
	if (iqentry_a1_v[1] == `INV && iqentry_a1_s[1] == alu1_id && iqentry_v[1] == `VAL && alu1_v == `VAL) begin
	    iqentry_a1[1] <= alu1_bus;
	    iqentry_a1_v[1] <= `VAL;
	end
	if (iqentry_a2_v[1] == `INV && iqentry_a2_s[1] == alu1_id && iqentry_v[1] == `VAL && alu1_v == `VAL) begin
	    iqentry_a2[1] <= alu1_bus;
	    iqentry_a2_v[1] <= `VAL;
	end
	if (iqentry_a1_v[1] == `INV && iqentry_a1_s[1] == dram_id && iqentry_v[1] == `VAL && dram_v == `VAL) begin
	    iqentry_a1[1] <= dram_bus;
	    iqentry_a1_v[1] <= `VAL;
	end
	if (iqentry_a2_v[1] == `INV && iqentry_a2_s[1] == dram_id && iqentry_v[1] == `VAL && dram_v == `VAL) begin
	    iqentry_a2[1] <= dram_bus;
	    iqentry_a2_v[1] <= `VAL;
	end
	if (iqentry_a1_v[1] == `INV && iqentry_a1_s[1] == commit0_id && iqentry_v[1] == `VAL && commit0_v == `VAL) begin
	    iqentry_a1[1] <= commit0_bus;
	    iqentry_a1_v[1] <= `VAL;
	end
	if (iqentry_a2_v[1] == `INV && iqentry_a2_s[1] == commit0_id && iqentry_v[1] == `VAL && commit0_v == `VAL) begin
	    iqentry_a2[1] <= commit0_bus;
	    iqentry_a2_v[1] <= `VAL;
	end
	if (iqentry_a1_v[1] == `INV && iqentry_a1_s[1] == commit1_id && iqentry_v[1] == `VAL && commit1_v == `VAL) begin
	    iqentry_a1[1] <= commit1_bus;
	    iqentry_a1_v[1] <= `VAL;
	end
	if (iqentry_a2_v[1] == `INV && iqentry_a2_s[1] == commit1_id && iqentry_v[1] == `VAL && commit1_v == `VAL) begin
	    iqentry_a2[1] <= commit1_bus;
	    iqentry_a2_v[1] <= `VAL;
	end

	if (iqentry_a1_v[2] == `INV && iqentry_a1_s[2] == alu0_id && iqentry_v[2] == `VAL && alu0_v == `VAL) begin
	    iqentry_a1[2] <= alu0_bus;
	    iqentry_a1_v[2] <= `VAL;
	end
	if (iqentry_a2_v[2] == `INV && iqentry_a2_s[2] == alu0_id && iqentry_v[2] == `VAL && alu0_v == `VAL) begin
	    iqentry_a2[2] <= alu0_bus;
	    iqentry_a2_v[2] <= `VAL;
	end
	if (iqentry_a1_v[2] == `INV && iqentry_a1_s[2] == alu1_id && iqentry_v[2] == `VAL && alu1_v == `VAL) begin
	    iqentry_a1[2] <= alu1_bus;
	    iqentry_a1_v[2] <= `VAL;
	end
	if (iqentry_a2_v[2] == `INV && iqentry_a2_s[2] == alu1_id && iqentry_v[2] == `VAL && alu1_v == `VAL) begin
	    iqentry_a2[2] <= alu1_bus;
	    iqentry_a2_v[2] <= `VAL;
	end
	if (iqentry_a1_v[2] == `INV && iqentry_a1_s[2] == dram_id && iqentry_v[2] == `VAL && dram_v == `VAL) begin
	    iqentry_a1[2] <= dram_bus;
	    iqentry_a1_v[2] <= `VAL;
	end
	if (iqentry_a2_v[2] == `INV && iqentry_a2_s[2] == dram_id && iqentry_v[2] == `VAL && dram_v == `VAL) begin
	    iqentry_a2[2] <= dram_bus;
	    iqentry_a2_v[2] <= `VAL;
	end
	if (iqentry_a1_v[2] == `INV && iqentry_a1_s[2] == commit0_id && iqentry_v[2] == `VAL && commit0_v == `VAL) begin
	    iqentry_a1[2] <= commit0_bus;
	    iqentry_a1_v[2] <= `VAL;
	end
	if (iqentry_a2_v[2] == `INV && iqentry_a2_s[2] == commit0_id && iqentry_v[2] == `VAL && commit0_v == `VAL) begin
	    iqentry_a2[2] <= commit0_bus;
	    iqentry_a2_v[2] <= `VAL;
	end
	if (iqentry_a1_v[2] == `INV && iqentry_a1_s[2] == commit1_id && iqentry_v[2] == `VAL && commit1_v == `VAL) begin
	    iqentry_a1[2] <= commit1_bus;
	    iqentry_a1_v[2] <= `VAL;
	end
	if (iqentry_a2_v[2] == `INV && iqentry_a2_s[2] == commit1_id && iqentry_v[2] == `VAL && commit1_v == `VAL) begin
	    iqentry_a2[2] <= commit1_bus;
	    iqentry_a2_v[2] <= `VAL;
	end

	if (iqentry_a1_v[3] == `INV && iqentry_a1_s[3] == alu0_id && iqentry_v[3] == `VAL && alu0_v == `VAL) begin
	    iqentry_a1[3] <= alu0_bus;
	    iqentry_a1_v[3] <= `VAL;
	end
	if (iqentry_a2_v[3] == `INV && iqentry_a2_s[3] == alu0_id && iqentry_v[3] == `VAL && alu0_v == `VAL) begin
	    iqentry_a2[3] <= alu0_bus;
	    iqentry_a2_v[3] <= `VAL;
	end
	if (iqentry_a1_v[3] == `INV && iqentry_a1_s[3] == alu1_id && iqentry_v[3] == `VAL && alu1_v == `VAL) begin
	    iqentry_a1[3] <= alu1_bus;
	    iqentry_a1_v[3] <= `VAL;
	end
	if (iqentry_a2_v[3] == `INV && iqentry_a2_s[3] == alu1_id && iqentry_v[3] == `VAL && alu1_v == `VAL) begin
	    iqentry_a2[3] <= alu1_bus;
	    iqentry_a2_v[3] <= `VAL;
	end
	if (iqentry_a1_v[3] == `INV && iqentry_a1_s[3] == dram_id && iqentry_v[3] == `VAL && dram_v == `VAL) begin
	    iqentry_a1[3] <= dram_bus;
	    iqentry_a1_v[3] <= `VAL;
	end
	if (iqentry_a2_v[3] == `INV && iqentry_a2_s[3] == dram_id && iqentry_v[3] == `VAL && dram_v == `VAL) begin
	    iqentry_a2[3] <= dram_bus;
	    iqentry_a2_v[3] <= `VAL;
	end
	if (iqentry_a1_v[3] == `INV && iqentry_a1_s[3] == commit0_id && iqentry_v[3] == `VAL && commit0_v == `VAL) begin
	    iqentry_a1[3] <= commit0_bus;
	    iqentry_a1_v[3] <= `VAL;
	end
	if (iqentry_a2_v[3] == `INV && iqentry_a2_s[3] == commit0_id && iqentry_v[3] == `VAL && commit0_v == `VAL) begin
	    iqentry_a2[3] <= commit0_bus;
	    iqentry_a2_v[3] <= `VAL;
	end
	if (iqentry_a1_v[3] == `INV && iqentry_a1_s[3] == commit1_id && iqentry_v[3] == `VAL && commit1_v == `VAL) begin
	    iqentry_a1[3] <= commit1_bus;
	    iqentry_a1_v[3] <= `VAL;
	end
	if (iqentry_a2_v[3] == `INV && iqentry_a2_s[3] == commit1_id && iqentry_v[3] == `VAL && commit1_v == `VAL) begin
	    iqentry_a2[3] <= commit1_bus;
	    iqentry_a2_v[3] <= `VAL;
	end

	if (iqentry_a1_v[4] == `INV && iqentry_a1_s[4] == alu0_id && iqentry_v[4] == `VAL && alu0_v == `VAL) begin
	    iqentry_a1[4] <= alu0_bus;
	    iqentry_a1_v[4] <= `VAL;
	end
	if (iqentry_a2_v[4] == `INV && iqentry_a2_s[4] == alu0_id && iqentry_v[4] == `VAL && alu0_v == `VAL) begin
	    iqentry_a2[4] <= alu0_bus;
	    iqentry_a2_v[4] <= `VAL;
	end
	if (iqentry_a1_v[4] == `INV && iqentry_a1_s[4] == alu1_id && iqentry_v[4] == `VAL && alu1_v == `VAL) begin
	    iqentry_a1[4] <= alu1_bus;
	    iqentry_a1_v[4] <= `VAL;
	end
	if (iqentry_a2_v[4] == `INV && iqentry_a2_s[4] == alu1_id && iqentry_v[4] == `VAL && alu1_v == `VAL) begin
	    iqentry_a2[4] <= alu1_bus;
	    iqentry_a2_v[4] <= `VAL;
	end
	if (iqentry_a1_v[4] == `INV && iqentry_a1_s[4] == dram_id && iqentry_v[4] == `VAL && dram_v == `VAL) begin
	    iqentry_a1[4] <= dram_bus;
	    iqentry_a1_v[4] <= `VAL;
	end
	if (iqentry_a2_v[4] == `INV && iqentry_a2_s[4] == dram_id && iqentry_v[4] == `VAL && dram_v == `VAL) begin
	    iqentry_a2[4] <= dram_bus;
	    iqentry_a2_v[4] <= `VAL;
	end
	if (iqentry_a1_v[4] == `INV && iqentry_a1_s[4] == commit0_id && iqentry_v[4] == `VAL && commit0_v == `VAL) begin
	    iqentry_a1[4] <= commit0_bus;
	    iqentry_a1_v[4] <= `VAL;
	end
	if (iqentry_a2_v[4] == `INV && iqentry_a2_s[4] == commit0_id && iqentry_v[4] == `VAL && commit0_v == `VAL) begin
	    iqentry_a2[4] <= commit0_bus;
	    iqentry_a2_v[4] <= `VAL;
	end
	if (iqentry_a1_v[4] == `INV && iqentry_a1_s[4] == commit1_id && iqentry_v[4] == `VAL && commit1_v == `VAL) begin
	    iqentry_a1[4] <= commit1_bus;
	    iqentry_a1_v[4] <= `VAL;
	end
	if (iqentry_a2_v[4] == `INV && iqentry_a2_s[4] == commit1_id && iqentry_v[4] == `VAL && commit1_v == `VAL) begin
	    iqentry_a2[4] <= commit1_bus;
	    iqentry_a2_v[4] <= `VAL;
	end

	if (iqentry_a1_v[5] == `INV && iqentry_a1_s[5] == alu0_id && iqentry_v[5] == `VAL && alu0_v == `VAL) begin
	    iqentry_a1[5] <= alu0_bus;
	    iqentry_a1_v[5] <= `VAL;
	end
	if (iqentry_a2_v[5] == `INV && iqentry_a2_s[5] == alu0_id && iqentry_v[5] == `VAL && alu0_v == `VAL) begin
	    iqentry_a2[5] <= alu0_bus;
	    iqentry_a2_v[5] <= `VAL;
	end
	if (iqentry_a1_v[5] == `INV && iqentry_a1_s[5] == alu1_id && iqentry_v[5] == `VAL && alu1_v == `VAL) begin
	    iqentry_a1[5] <= alu1_bus;
	    iqentry_a1_v[5] <= `VAL;
	end
	if (iqentry_a2_v[5] == `INV && iqentry_a2_s[5] == alu1_id && iqentry_v[5] == `VAL && alu1_v == `VAL) begin
	    iqentry_a2[5] <= alu1_bus;
	    iqentry_a2_v[5] <= `VAL;
	end
	if (iqentry_a1_v[5] == `INV && iqentry_a1_s[5] == dram_id && iqentry_v[5] == `VAL && dram_v == `VAL) begin
	    iqentry_a1[5] <= dram_bus;
	    iqentry_a1_v[5] <= `VAL;
	end
	if (iqentry_a2_v[5] == `INV && iqentry_a2_s[5] == dram_id && iqentry_v[5] == `VAL && dram_v == `VAL) begin
	    iqentry_a2[5] <= dram_bus;
	    iqentry_a2_v[5] <= `VAL;
	end
	if (iqentry_a1_v[5] == `INV && iqentry_a1_s[5] == commit0_id && iqentry_v[5] == `VAL && commit0_v == `VAL) begin
	    iqentry_a1[5] <= commit0_bus;
	    iqentry_a1_v[5] <= `VAL;
	end
	if (iqentry_a2_v[5] == `INV && iqentry_a2_s[5] == commit0_id && iqentry_v[5] == `VAL && commit0_v == `VAL) begin
	    iqentry_a2[5] <= commit0_bus;
	    iqentry_a2_v[5] <= `VAL;
	end
	if (iqentry_a1_v[5] == `INV && iqentry_a1_s[5] == commit1_id && iqentry_v[5] == `VAL && commit1_v == `VAL) begin
	    iqentry_a1[5] <= commit1_bus;
	    iqentry_a1_v[5] <= `VAL;
	end
	if (iqentry_a2_v[5] == `INV && iqentry_a2_s[5] == commit1_id && iqentry_v[5] == `VAL && commit1_v == `VAL) begin
	    iqentry_a2[5] <= commit1_bus;
	    iqentry_a2_v[5] <= `VAL;
	end

	if (iqentry_a1_v[6] == `INV && iqentry_a1_s[6] == alu0_id && iqentry_v[6] == `VAL && alu0_v == `VAL) begin
	    iqentry_a1[6] <= alu0_bus;
	    iqentry_a1_v[6] <= `VAL;
	end
	if (iqentry_a2_v[6] == `INV && iqentry_a2_s[6] == alu0_id && iqentry_v[6] == `VAL && alu0_v == `VAL) begin
	    iqentry_a2[6] <= alu0_bus;
	    iqentry_a2_v[6] <= `VAL;
	end
	if (iqentry_a1_v[6] == `INV && iqentry_a1_s[6] == alu1_id && iqentry_v[6] == `VAL && alu1_v == `VAL) begin
	    iqentry_a1[6] <= alu1_bus;
	    iqentry_a1_v[6] <= `VAL;
	end
	if (iqentry_a2_v[6] == `INV && iqentry_a2_s[6] == alu1_id && iqentry_v[6] == `VAL && alu1_v == `VAL) begin
	    iqentry_a2[6] <= alu1_bus;
	    iqentry_a2_v[6] <= `VAL;
	end
	if (iqentry_a1_v[6] == `INV && iqentry_a1_s[6] == dram_id && iqentry_v[6] == `VAL && dram_v == `VAL) begin
	    iqentry_a1[6] <= dram_bus;
	    iqentry_a1_v[6] <= `VAL;
	end
	if (iqentry_a2_v[6] == `INV && iqentry_a2_s[6] == dram_id && iqentry_v[6] == `VAL && dram_v == `VAL) begin
	    iqentry_a2[6] <= dram_bus;
	    iqentry_a2_v[6] <= `VAL;
	end
	if (iqentry_a1_v[6] == `INV && iqentry_a1_s[6] == commit0_id && iqentry_v[6] == `VAL && commit0_v == `VAL) begin
	    iqentry_a1[6] <= commit0_bus;
	    iqentry_a1_v[6] <= `VAL;
	end
	if (iqentry_a2_v[6] == `INV && iqentry_a2_s[6] == commit0_id && iqentry_v[6] == `VAL && commit0_v == `VAL) begin
	    iqentry_a2[6] <= commit0_bus;
	    iqentry_a2_v[6] <= `VAL;
	end
	if (iqentry_a1_v[6] == `INV && iqentry_a1_s[6] == commit1_id && iqentry_v[6] == `VAL && commit1_v == `VAL) begin
	    iqentry_a1[6] <= commit1_bus;
	    iqentry_a1_v[6] <= `VAL;
	end
	if (iqentry_a2_v[6] == `INV && iqentry_a2_s[6] == commit1_id && iqentry_v[6] == `VAL && commit1_v == `VAL) begin
	    iqentry_a2[6] <= commit1_bus;
	    iqentry_a2_v[6] <= `VAL;
	end

	if (iqentry_a1_v[7] == `INV && iqentry_a1_s[7] == alu0_id && iqentry_v[7] == `VAL && alu0_v == `VAL) begin
	    iqentry_a1[7] <= alu0_bus;
	    iqentry_a1_v[7] <= `VAL;
	end
	if (iqentry_a2_v[7] == `INV && iqentry_a2_s[7] == alu0_id && iqentry_v[7] == `VAL && alu0_v == `VAL) begin
	    iqentry_a2[7] <= alu0_bus;
	    iqentry_a2_v[7] <= `VAL;
	end
	if (iqentry_a1_v[7] == `INV && iqentry_a1_s[7] == alu1_id && iqentry_v[7] == `VAL && alu1_v == `VAL) begin
	    iqentry_a1[7] <= alu1_bus;
	    iqentry_a1_v[7] <= `VAL;
	end
	if (iqentry_a2_v[7] == `INV && iqentry_a2_s[7] == alu1_id && iqentry_v[7] == `VAL && alu1_v == `VAL) begin
	    iqentry_a2[7] <= alu1_bus;
	    iqentry_a2_v[7] <= `VAL;
	end
	if (iqentry_a1_v[7] == `INV && iqentry_a1_s[7] == dram_id && iqentry_v[7] == `VAL && dram_v == `VAL) begin
	    iqentry_a1[7] <= dram_bus;
	    iqentry_a1_v[7] <= `VAL;
	end
	if (iqentry_a2_v[7] == `INV && iqentry_a2_s[7] == dram_id && iqentry_v[7] == `VAL && dram_v == `VAL) begin
	    iqentry_a2[7] <= dram_bus;
	    iqentry_a2_v[7] <= `VAL;
	end
	if (iqentry_a1_v[7] == `INV && iqentry_a1_s[7] == commit0_id && iqentry_v[7] == `VAL && commit0_v == `VAL) begin
	    iqentry_a1[7] <= commit0_bus;
	    iqentry_a1_v[7] <= `VAL;
	end
	if (iqentry_a2_v[7] == `INV && iqentry_a2_s[7] == commit0_id && iqentry_v[7] == `VAL && commit0_v == `VAL) begin
	    iqentry_a2[7] <= commit0_bus;
	    iqentry_a2_v[7] <= `VAL;
	end
	if (iqentry_a1_v[7] == `INV && iqentry_a1_s[7] == commit1_id && iqentry_v[7] == `VAL && commit1_v == `VAL) begin
	    iqentry_a1[7] <= commit1_bus;
	    iqentry_a1_v[7] <= `VAL;
	end
	if (iqentry_a2_v[7] == `INV && iqentry_a2_s[7] == commit1_id && iqentry_v[7] == `VAL && commit1_v == `VAL) begin
	    iqentry_a2[7] <= commit1_bus;
	    iqentry_a2_v[7] <= `VAL;
	end

    end

    //
    // ISSUE 
    //
    // determines what instructions are ready to go, then places them
    // in the various ALU queues.  
    // also invalidates instructions following a branch-miss BEQ or any JALR (STOMP logic)
    //
    always @(posedge clk) begin: issue_phase

	alu0_dataready <= alu0_available 
				&& ((iqentry_issue[0] && iqentry_0_islot == 2'd0 && !iqentry_stomp[0])
				 || (iqentry_issue[1] && iqentry_1_islot == 2'd0 && !iqentry_stomp[1])
				 || (iqentry_issue[2] && iqentry_2_islot == 2'd0 && !iqentry_stomp[2])
				 || (iqentry_issue[3] && iqentry_3_islot == 2'd0 && !iqentry_stomp[3])
				 || (iqentry_issue[4] && iqentry_4_islot == 2'd0 && !iqentry_stomp[4])
				 || (iqentry_issue[5] && iqentry_5_islot == 2'd0 && !iqentry_stomp[5])
				 || (iqentry_issue[6] && iqentry_6_islot == 2'd0 && !iqentry_stomp[6])
				 || (iqentry_issue[7] && iqentry_7_islot == 2'd0 && !iqentry_stomp[7]));

	alu1_dataready <= alu1_available 
				&& ((iqentry_issue[0] && iqentry_0_islot == 2'd1 && !iqentry_stomp[0])
				 || (iqentry_issue[1] && iqentry_1_islot == 2'd1 && !iqentry_stomp[1])
				 || (iqentry_issue[2] && iqentry_2_islot == 2'd1 && !iqentry_stomp[2])
				 || (iqentry_issue[3] && iqentry_3_islot == 2'd1 && !iqentry_stomp[3])
				 || (iqentry_issue[4] && iqentry_4_islot == 2'd1 && !iqentry_stomp[4])
				 || (iqentry_issue[5] && iqentry_5_islot == 2'd1 && !iqentry_stomp[5])
				 || (iqentry_issue[6] && iqentry_6_islot == 2'd1 && !iqentry_stomp[6])
				 || (iqentry_issue[7] && iqentry_7_islot == 2'd1 && !iqentry_stomp[7]));

	if (iqentry_v[0] && iqentry_stomp[0]) begin
	    iqentry_v[0] <= `INV;
	    if (dram0_id[2:0] == 3'd0)	dram0 <= `DRAMSLOT_AVAIL;
	    if (dram1_id[2:0] == 3'd0)	dram1 <= `DRAMSLOT_AVAIL;
	    if (dram2_id[2:0] == 3'd0)	dram2 <= `DRAMSLOT_AVAIL;
	end
	else if (iqentry_issue[0]) begin
	    case (iqentry_0_islot) 
		2'd0: if (alu0_available) begin
			alu0_sourceid	<= 4'd0;
			alu0_op		<= (iqentry_op[0] == `ADDI || iqentry_op[0] == `LW || iqentry_op[0] == `SW)
					    ? `ADD
					    : iqentry_op[0];
			alu0_bt		<= iqentry_bt[0];
			alu0_pc		<= iqentry_pc[0];
			alu0_argA	<= iqentry_a1_v[0] ? iqentry_a1[0]
					    : (iqentry_a1_s[0] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[0] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu0_argB	<= iqentry_imm[0]
					    ? iqentry_a0[0]
					    : (iqentry_a2_v[0] ? iqentry_a2[0]
						: (iqentry_a2_s[0] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[0] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu0_argI	<= iqentry_a0[0];
		    end
		2'd1: if (alu1_available) begin
			alu1_sourceid	<= 4'd0;
			alu1_op		<= (iqentry_op[0] == `ADDI || iqentry_op[0] == `LW || iqentry_op[0] == `SW)
					    ? `ADD
					    : iqentry_op[0];
			alu1_bt		<= iqentry_bt[0];
			alu1_pc		<= iqentry_pc[0];
			alu1_argA	<= iqentry_a1_v[0] ? iqentry_a1[0]
					    : (iqentry_a1_s[0] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[0] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu1_argB	<= iqentry_imm[0]
					    ? iqentry_a0[0]
					    : (iqentry_a2_v[0] ? iqentry_a2[0]
						: (iqentry_a2_s[0] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[0] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu1_argI	<= iqentry_a0[0];
		    end
		default: panic <= `PANIC_INVALIDISLOT;
	    endcase
	    iqentry_out[0] <= `VAL;
	    // if it is a memory operation, this is the address-generation step ... collect result into arg1
	    if (iqentry_mem[0]) begin
		iqentry_a1_v[0] <= `INV;
		iqentry_a1_s[0] <= 4'd0;
	    end
	end

	if (iqentry_v[1] && iqentry_stomp[1]) begin
	    iqentry_v[1] <= `INV;
	    if (dram0_id[2:0] == 3'd1)	dram0 <= `DRAMSLOT_AVAIL;
	    if (dram1_id[2:0] == 3'd1)	dram1 <= `DRAMSLOT_AVAIL;
	    if (dram2_id[2:0] == 3'd1)	dram2 <= `DRAMSLOT_AVAIL;
	end
	else if (iqentry_issue[1]) begin
	    case (iqentry_1_islot) 
		2'd0: if (alu0_available) begin
			alu0_sourceid	<= 4'd1;
			alu0_op		<= (iqentry_op[1] == `ADDI || iqentry_op[1] == `LW || iqentry_op[1] == `SW)
					    ? `ADD
					    : iqentry_op[1];
			alu0_bt		<= iqentry_bt[1];
			alu0_pc		<= iqentry_pc[1];
			alu0_argA	<= iqentry_a1_v[1] ? iqentry_a1[1]
					    : (iqentry_a1_s[1] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[1] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu0_argB	<= iqentry_imm[1]
					    ? iqentry_a0[1]
					    : (iqentry_a2_v[1] ? iqentry_a2[1]
						: (iqentry_a2_s[1] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[1] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu0_argI	<= iqentry_a0[1];
		    end
		2'd1: if (alu1_available) begin
			alu1_sourceid	<= 4'd1;
			alu1_op		<= (iqentry_op[1] == `ADDI || iqentry_op[1] == `LW || iqentry_op[1] == `SW)
					    ? `ADD
					    : iqentry_op[1];
			alu1_bt		<= iqentry_bt[1];
			alu1_pc		<= iqentry_pc[1];
			alu1_argA	<= iqentry_a1_v[1] ? iqentry_a1[1]
					    : (iqentry_a1_s[1] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[1] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu1_argB	<= iqentry_imm[1]
					    ? iqentry_a0[1]
					    : (iqentry_a2_v[1] ? iqentry_a2[1]
						: (iqentry_a2_s[1] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[1] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu1_argI	<= iqentry_a0[1];
		    end
		default: panic <= `PANIC_INVALIDISLOT;
	    endcase
	    iqentry_out[1] <= `VAL;
	    // if it is a memory operation, this is the address-generation step ... collect result into arg1
	    if (iqentry_mem[1]) begin
		iqentry_a1_v[1] <= `INV;
		iqentry_a1_s[1] <= 4'd1;
	    end
	end

	if (iqentry_v[2] && iqentry_stomp[2]) begin
	    iqentry_v[2] <= `INV;
	    if (dram0_id[2:0] == 3'd2)	dram0 <= `DRAMSLOT_AVAIL;
	    if (dram1_id[2:0] == 3'd2)	dram1 <= `DRAMSLOT_AVAIL;
	    if (dram2_id[2:0] == 3'd2)	dram2 <= `DRAMSLOT_AVAIL;
	end
	else if (iqentry_issue[2]) begin
	    case (iqentry_2_islot) 
		2'd0: if (alu0_available) begin
			alu0_sourceid	<= 4'd2;
			alu0_op		<= (iqentry_op[2] == `ADDI || iqentry_op[2] == `LW || iqentry_op[2] == `SW)
					    ? `ADD
					    : iqentry_op[2];
			alu0_bt		<= iqentry_bt[2];
			alu0_pc		<= iqentry_pc[2];
			alu0_argA	<= iqentry_a1_v[2] ? iqentry_a1[2]
					    : (iqentry_a1_s[2] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[2] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu0_argB	<= iqentry_imm[2]
					    ? iqentry_a0[2]
					    : (iqentry_a2_v[2] ? iqentry_a2[2]
						: (iqentry_a2_s[2] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[2] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu0_argI	<= iqentry_a0[2];
		    end
		2'd1: if (alu1_available) begin
			alu1_sourceid	<= 4'd2;
			alu1_op		<= (iqentry_op[2] == `ADDI || iqentry_op[2] == `LW || iqentry_op[2] == `SW)
					    ? `ADD
					    : iqentry_op[2];
			alu1_bt		<= iqentry_bt[2];
			alu1_pc		<= iqentry_pc[2];
			alu1_argA	<= iqentry_a1_v[2] ? iqentry_a1[2]
					    : (iqentry_a1_s[2] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[2] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu1_argB	<= iqentry_imm[2]
					    ? iqentry_a0[2]
					    : (iqentry_a2_v[2] ? iqentry_a2[2]
						: (iqentry_a2_s[2] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[2] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu1_argI	<= iqentry_a0[2];
		    end
		default: panic <= `PANIC_INVALIDISLOT;
	    endcase
	    iqentry_out[2] <= `VAL;
	    // if it is a memory operation, this is the address-generation step ... collect result into arg1
	    if (iqentry_mem[2]) begin
		iqentry_a1_v[2] <= `INV;
		iqentry_a1_s[2] <= 4'd2;
	    end
	end

	if (iqentry_v[3] && iqentry_stomp[3]) begin
	    iqentry_v[3] <= `INV;
	    if (dram0_id[2:0] == 3'd3)	dram0 <= `DRAMSLOT_AVAIL;
	    if (dram1_id[2:0] == 3'd3)	dram1 <= `DRAMSLOT_AVAIL;
	    if (dram2_id[2:0] == 3'd3)	dram2 <= `DRAMSLOT_AVAIL;
	end
	else if (iqentry_issue[3]) begin
	    case (iqentry_3_islot) 
		2'd0: if (alu0_available) begin
			alu0_sourceid	<= 4'd3;
			alu0_op		<= (iqentry_op[3] == `ADDI || iqentry_op[3] == `LW || iqentry_op[3] == `SW)
					    ? `ADD
					    : iqentry_op[3];
			alu0_bt		<= iqentry_bt[3];
			alu0_pc		<= iqentry_pc[3];
			alu0_argA	<= iqentry_a1_v[3] ? iqentry_a1[3]
					    : (iqentry_a1_s[3] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[3] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu0_argB	<= iqentry_imm[3]
					    ? iqentry_a0[3]
					    : (iqentry_a2_v[3] ? iqentry_a2[3]
						: (iqentry_a2_s[3] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[3] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu0_argI	<= iqentry_a0[3];
		    end
		2'd1: if (alu1_available) begin
			alu1_sourceid	<= 4'd3;
			alu1_op		<= (iqentry_op[3] == `ADDI || iqentry_op[3] == `LW || iqentry_op[3] == `SW)
					    ? `ADD
					    : iqentry_op[3];
			alu1_bt		<= iqentry_bt[3];
			alu1_pc		<= iqentry_pc[3];
			alu1_argA	<= iqentry_a1_v[3] ? iqentry_a1[3]
					    : (iqentry_a1_s[3] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[3] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu1_argB	<= iqentry_imm[3]
					    ? iqentry_a0[3]
					    : (iqentry_a2_v[3] ? iqentry_a2[3]
						: (iqentry_a2_s[3] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[3] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu1_argI	<= iqentry_a0[3];
		    end
		default: panic <= `PANIC_INVALIDISLOT;
	    endcase
	    iqentry_out[3] <= `VAL;
	    // if it is a memory operation, this is the address-generation step ... collect result into arg1
	    if (iqentry_mem[3]) begin
		iqentry_a1_v[3] <= `INV;
		iqentry_a1_s[3] <= 4'd3;
	    end
	end

	if (iqentry_v[4] && iqentry_stomp[4]) begin
	    iqentry_v[4] <= `INV;
	    if (dram0_id[2:0] == 3'd4)	dram0 <= `DRAMSLOT_AVAIL;
	    if (dram1_id[2:0] == 3'd4)	dram1 <= `DRAMSLOT_AVAIL;
	    if (dram2_id[2:0] == 3'd4)	dram2 <= `DRAMSLOT_AVAIL;
	end
	else if (iqentry_issue[4]) begin
	    case (iqentry_4_islot) 
		2'd0: if (alu0_available) begin
			alu0_sourceid	<= 4'd4;
			alu0_op		<= (iqentry_op[4] == `ADDI || iqentry_op[4] == `LW || iqentry_op[4] == `SW)
					    ? `ADD
					    : iqentry_op[4];
			alu0_bt		<= iqentry_bt[4];
			alu0_pc		<= iqentry_pc[4];
			alu0_argA	<= iqentry_a1_v[4] ? iqentry_a1[4]
					    : (iqentry_a1_s[4] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[4] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu0_argB	<= iqentry_imm[4]
					    ? iqentry_a0[4]
					    : (iqentry_a2_v[4] ? iqentry_a2[4]
						: (iqentry_a2_s[4] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[4] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu0_argI	<= iqentry_a0[4];
		    end
		2'd1: if (alu1_available) begin
			alu1_sourceid	<= 4'd4;
			alu1_op		<= (iqentry_op[4] == `ADDI || iqentry_op[4] == `LW || iqentry_op[4] == `SW)
					    ? `ADD
					    : iqentry_op[4];
			alu1_bt		<= iqentry_bt[4];
			alu1_pc		<= iqentry_pc[4];
			alu1_argA	<= iqentry_a1_v[4] ? iqentry_a1[4]
					    : (iqentry_a1_s[4] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[4] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu1_argB	<= iqentry_imm[4]
					    ? iqentry_a0[4]
					    : (iqentry_a2_v[4] ? iqentry_a2[4]
						: (iqentry_a2_s[4] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[4] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu1_argI	<= iqentry_a0[4];
		    end
		default: panic <= `PANIC_INVALIDISLOT;
	    endcase
	    iqentry_out[4] <= `VAL;
	    // if it is a memory operation, this is the address-generation step ... collect result into arg1
	    if (iqentry_mem[4]) begin
		iqentry_a1_v[4] <= `INV;
		iqentry_a1_s[4] <= 4'd4;
	    end
	end

	if (iqentry_v[5] && iqentry_stomp[5]) begin
	    iqentry_v[5] <= `INV;
	    if (dram0_id[2:0] == 3'd5)	dram0 <= `DRAMSLOT_AVAIL;
	    if (dram1_id[2:0] == 3'd5)	dram1 <= `DRAMSLOT_AVAIL;
	    if (dram2_id[2:0] == 3'd5)	dram2 <= `DRAMSLOT_AVAIL;
	end
	else if (iqentry_issue[5]) begin
	    case (iqentry_5_islot) 
		2'd0: if (alu0_available) begin
			alu0_sourceid	<= 4'd5;
			alu0_op		<= (iqentry_op[5] == `ADDI || iqentry_op[5] == `LW || iqentry_op[5] == `SW)
					    ? `ADD
					    : iqentry_op[5];
			alu0_bt		<= iqentry_bt[5];
			alu0_pc		<= iqentry_pc[5];
			alu0_argA	<= iqentry_a1_v[5] ? iqentry_a1[5]
					    : (iqentry_a1_s[5] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[5] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu0_argB	<= iqentry_imm[5]
					    ? iqentry_a0[5]
					    : (iqentry_a2_v[5] ? iqentry_a2[5]
						: (iqentry_a2_s[5] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[5] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu0_argI	<= iqentry_a0[5];
		    end
		2'd1: if (alu1_available) begin
			alu1_sourceid	<= 4'd5;
			alu1_op		<= (iqentry_op[5] == `ADDI || iqentry_op[5] == `LW || iqentry_op[5] == `SW)
					    ? `ADD
					    : iqentry_op[5];
			alu1_bt		<= iqentry_bt[5];
			alu1_pc		<= iqentry_pc[5];
			alu1_argA	<= iqentry_a1_v[5] ? iqentry_a1[5]
					    : (iqentry_a1_s[5] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[5] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu1_argB	<= iqentry_imm[5]
					    ? iqentry_a0[5]
					    : (iqentry_a2_v[5] ? iqentry_a2[5]
						: (iqentry_a2_s[5] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[5] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu1_argI	<= iqentry_a0[5];
		    end
		default: panic <= `PANIC_INVALIDISLOT;
	    endcase
	    iqentry_out[5] <= `VAL;
	    // if it is a memory operation, this is the address-generation step ... collect result into arg1
	    if (iqentry_mem[5]) begin
		iqentry_a1_v[5] <= `INV;
		iqentry_a1_s[5] <= 4'd5;
	    end
	end

	if (iqentry_v[6] && iqentry_stomp[6]) begin
	    iqentry_v[6] <= `INV;
	    if (dram0_id[2:0] == 3'd6)	dram0 <= `DRAMSLOT_AVAIL;
	    if (dram1_id[2:0] == 3'd6)	dram1 <= `DRAMSLOT_AVAIL;
	    if (dram2_id[2:0] == 3'd6)	dram2 <= `DRAMSLOT_AVAIL;
	end
	else if (iqentry_issue[6]) begin
	    case (iqentry_6_islot) 
		2'd0: if (alu0_available) begin
			alu0_sourceid	<= 4'd6;
			alu0_op		<= (iqentry_op[6] == `ADDI || iqentry_op[6] == `LW || iqentry_op[6] == `SW)
					    ? `ADD
					    : iqentry_op[6];
			alu0_bt		<= iqentry_bt[6];
			alu0_pc		<= iqentry_pc[6];
			alu0_argA	<= iqentry_a1_v[6] ? iqentry_a1[6]
					    : (iqentry_a1_s[6] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[6] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu0_argB	<= iqentry_imm[6]
					    ? iqentry_a0[6]
					    : (iqentry_a2_v[6] ? iqentry_a2[6]
						: (iqentry_a2_s[6] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[6] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu0_argI	<= iqentry_a0[6];
		    end
		2'd1: if (alu1_available) begin
			alu1_sourceid	<= 4'd6;
			alu1_op		<= (iqentry_op[6] == `ADDI || iqentry_op[6] == `LW || iqentry_op[6] == `SW)
					    ? `ADD
					    : iqentry_op[6];
			alu1_bt		<= iqentry_bt[6];
			alu1_pc		<= iqentry_pc[6];
			alu1_argA	<= iqentry_a1_v[6] ? iqentry_a1[6]
					    : (iqentry_a1_s[6] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[6] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu1_argB	<= iqentry_imm[6]
					    ? iqentry_a0[6]
					    : (iqentry_a2_v[6] ? iqentry_a2[6]
						: (iqentry_a2_s[6] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[6] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu1_argI	<= iqentry_a0[6];
		    end
		default: panic <= `PANIC_INVALIDISLOT;
	    endcase
	    iqentry_out[6] <= `VAL;
	    // if it is a memory operation, this is the address-generation step ... collect result into arg1
	    if (iqentry_mem[6]) begin
		iqentry_a1_v[6] <= `INV;
		iqentry_a1_s[6] <= 4'd6;
	    end
	end

	if (iqentry_v[7] && iqentry_stomp[7]) begin
	    iqentry_v[7] <= `INV;
	    if (dram0_id[2:0] == 3'd7)	dram0 <= `DRAMSLOT_AVAIL;
	    if (dram1_id[2:0] == 3'd7)	dram1 <= `DRAMSLOT_AVAIL;
	    if (dram2_id[2:0] == 3'd7)	dram2 <= `DRAMSLOT_AVAIL;
	end
	else if (iqentry_issue[7]) begin
	    case (iqentry_7_islot) 
		2'd0: if (alu0_available) begin
			alu0_sourceid	<= 4'd7;
			alu0_op		<= (iqentry_op[7] == `ADDI || iqentry_op[7] == `LW || iqentry_op[7] == `SW)
					    ? `ADD
					    : iqentry_op[7];
			alu0_bt		<= iqentry_bt[7];
			alu0_pc		<= iqentry_pc[7];
			alu0_argA	<= iqentry_a1_v[7] ? iqentry_a1[7]
					    : (iqentry_a1_s[7] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[7] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu0_argB	<= iqentry_imm[7]
					    ? iqentry_a0[7]
					    : (iqentry_a2_v[7] ? iqentry_a2[7]
						: (iqentry_a2_s[7] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[7] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu0_argI	<= iqentry_a0[7];
		    end
		2'd1: if (alu1_available) begin
			alu1_sourceid	<= 4'd7;
			alu1_op		<= (iqentry_op[7] == `ADDI || iqentry_op[7] == `LW || iqentry_op[7] == `SW)
					    ? `ADD
					    : iqentry_op[7];
			alu1_bt		<= iqentry_bt[7];
			alu1_pc		<= iqentry_pc[7];
			alu1_argA	<= iqentry_a1_v[7] ? iqentry_a1[7]
					    : (iqentry_a1_s[7] == alu0_id) ? alu0_bus
					    : (iqentry_a1_s[7] == alu1_id) ? alu1_bus
					    : 16'hDEAD;
			alu1_argB	<= iqentry_imm[7]
					    ? iqentry_a0[7]
					    : (iqentry_a2_v[7] ? iqentry_a2[7]
						: (iqentry_a2_s[7] == alu0_id) ? alu0_bus
						: (iqentry_a2_s[7] == alu1_id) ? alu1_bus
						: 16'hDEAD);
			alu1_argI	<= iqentry_a0[7];
		    end
		default: panic <= `PANIC_INVALIDISLOT;
	    endcase
	    iqentry_out[7] <= `VAL;
	    // if it is a memory operation, this is the address-generation step ... collect result into arg1
	    if (iqentry_mem[7]) begin
		iqentry_a1_v[7] <= `INV;
		iqentry_a1_s[7] <= 4'd7;
	    end
	end

    end

    assign  iqentry_imm[0] = (iqentry_op[0]==`ADDI || iqentry_op[0]==`LUI || iqentry_mem[0] || iqentry_op[0]==`JALR),
	    iqentry_imm[1] = (iqentry_op[1]==`ADDI || iqentry_op[1]==`LUI || iqentry_mem[1] || iqentry_op[1]==`JALR),
	    iqentry_imm[2] = (iqentry_op[2]==`ADDI || iqentry_op[2]==`LUI || iqentry_mem[2] || iqentry_op[2]==`JALR),
	    iqentry_imm[3] = (iqentry_op[3]==`ADDI || iqentry_op[3]==`LUI || iqentry_mem[3] || iqentry_op[3]==`JALR),
	    iqentry_imm[4] = (iqentry_op[4]==`ADDI || iqentry_op[4]==`LUI || iqentry_mem[4] || iqentry_op[4]==`JALR),
	    iqentry_imm[5] = (iqentry_op[5]==`ADDI || iqentry_op[5]==`LUI || iqentry_mem[5] || iqentry_op[5]==`JALR),
	    iqentry_imm[6] = (iqentry_op[6]==`ADDI || iqentry_op[6]==`LUI || iqentry_mem[6] || iqentry_op[6]==`JALR),
	    iqentry_imm[7] = (iqentry_op[7]==`ADDI || iqentry_op[7]==`LUI || iqentry_mem[7] || iqentry_op[7]==`JALR);

    //
    // additional logic for ISSUE
    //
    // for the moment, we look at ALU-input buffers to allow back-to-back issue of 
    // dependent instructions ... we do not, however, look ahead for DRAM requests 
    // that will become valid in the next cycle.  instead, these have to propagate
    // their results into the IQ entry directly, at which point it becomes issue-able
    //

    // note that, for all intents & purposes, iqentry_done == iqentry_agen ... no need to duplicate

    assign iqentry_issue[0] = (iqentry_v[0] && !iqentry_out[0] && !iqentry_agen[0]
				&& (head0 == 3'd0 || ~|iqentry_7_islot || (iqentry_7_islot == 2'b01 && ~iqentry_issue[7]))
				&& (iqentry_a1_v[0] 
				    || (iqentry_a1_s[0] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a1_s[0] == alu1_sourceid && alu1_dataready))
				&& (iqentry_a2_v[0] 
				    || (iqentry_mem[0] & ~iqentry_agen[0])
				    || (iqentry_a2_s[0] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a2_s[0] == alu1_sourceid && alu1_dataready)));
    assign iqentry_0_islot = (head0 == 3'd0) ? 2'b00
				: (iqentry_7_islot == 2'b11) ? 2'b11
				: (iqentry_7_islot + {1'b0, iqentry_issue[7]});

    assign iqentry_issue[1] = (iqentry_v[1] && !iqentry_out[1] && !iqentry_agen[1]
				&& (head0 == 3'd1 || ~|iqentry_0_islot || (iqentry_0_islot == 2'b01 && ~iqentry_issue[0]))
				&& (iqentry_a1_v[1] 
				    || (iqentry_a1_s[1] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a1_s[1] == alu1_sourceid && alu1_dataready))
				&& (iqentry_a2_v[1] 
				    || (iqentry_mem[1] & ~iqentry_agen[1])
				    || (iqentry_a2_s[1] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a2_s[1] == alu1_sourceid && alu1_dataready)));
    assign iqentry_1_islot = (head0 == 3'd1) ? 2'b00
				: (iqentry_0_islot == 2'b11) ? 2'b11
				: (iqentry_0_islot + {1'b0, iqentry_issue[0]});

    assign iqentry_issue[2] = (iqentry_v[2] && !iqentry_out[2] && !iqentry_agen[2]
				&& (head0 == 3'd2 || ~|iqentry_1_islot || (iqentry_1_islot == 2'b01 && ~iqentry_issue[1]))
				&& (iqentry_a1_v[2] 
				    || (iqentry_a1_s[2] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a1_s[2] == alu1_sourceid && alu1_dataready))
				&& (iqentry_a2_v[2] 
				    || (iqentry_mem[2] & ~iqentry_agen[2])
				    || (iqentry_a2_s[2] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a2_s[2] == alu1_sourceid && alu1_dataready)));
    assign iqentry_2_islot = (head0 == 3'd2) ? 2'b00
				: (iqentry_1_islot == 2'b11) ? 2'b11
				: (iqentry_1_islot + {1'b0, iqentry_issue[1]});

    assign iqentry_issue[3] = (iqentry_v[3] && !iqentry_out[3] && !iqentry_agen[3]
				&& (head0 == 3'd3 || ~|iqentry_2_islot || (iqentry_2_islot == 2'b01 && ~iqentry_issue[2]))
				&& (iqentry_a1_v[3] 
				    || (iqentry_a1_s[3] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a1_s[3] == alu1_sourceid && alu1_dataready))
				&& (iqentry_a2_v[3] 
				    || (iqentry_mem[3] & ~iqentry_agen[3])
				    || (iqentry_a2_s[3] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a2_s[3] == alu1_sourceid && alu1_dataready)));
    assign iqentry_3_islot = (head0 == 3'd3) ? 2'b00
				: (iqentry_2_islot == 2'b11) ? 2'b11
				: (iqentry_2_islot + {1'b0, iqentry_issue[2]});

    assign iqentry_issue[4] = (iqentry_v[4] && !iqentry_out[4] && !iqentry_agen[4]
				&& (head0 == 3'd4 || ~|iqentry_3_islot || (iqentry_3_islot == 2'b01 && ~iqentry_issue[3]))
				&& (iqentry_a1_v[4] 
				    || (iqentry_a1_s[4] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a1_s[4] == alu1_sourceid && alu1_dataready))
				&& (iqentry_a2_v[4] 
				    || (iqentry_mem[4] & ~iqentry_agen[4])
				    || (iqentry_a2_s[4] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a2_s[4] == alu1_sourceid && alu1_dataready)));
    assign iqentry_4_islot = (head0 == 3'd4) ? 2'b00
				: (iqentry_3_islot == 2'b11) ? 2'b11
				: (iqentry_3_islot + {1'b0, iqentry_issue[3]});

    assign iqentry_issue[5] = (iqentry_v[5] && !iqentry_out[5] && !iqentry_agen[5]
				&& (head0 == 3'd5 || ~|iqentry_4_islot || (iqentry_4_islot == 2'b01 && ~iqentry_issue[4]))
				&& (iqentry_a1_v[5] 
				    || (iqentry_a1_s[5] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a1_s[5] == alu1_sourceid && alu1_dataready))
				&& (iqentry_a2_v[5] 
				    || (iqentry_mem[5] & ~iqentry_agen[5])
				    || (iqentry_a2_s[5] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a2_s[5] == alu1_sourceid && alu1_dataready)));
    assign iqentry_5_islot = (head0 == 3'd5) ? 2'b00
				: (iqentry_4_islot == 2'b11) ? 2'b11
				: (iqentry_4_islot + {1'b0, iqentry_issue[4]});

    assign iqentry_issue[6] = (iqentry_v[6] && !iqentry_out[6] && !iqentry_agen[6]
				&& (head0 == 3'd6 || ~|iqentry_5_islot || (iqentry_5_islot == 2'b01 && ~iqentry_issue[5]))
				&& (iqentry_a1_v[6] 
				    || (iqentry_a1_s[6] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a1_s[6] == alu1_sourceid && alu1_dataready))
				&& (iqentry_a2_v[6] 
				    || (iqentry_mem[6] & ~iqentry_agen[6])
				    || (iqentry_a2_s[6] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a2_s[6] == alu1_sourceid && alu1_dataready)));
    assign iqentry_6_islot = (head0 == 3'd6) ? 2'b00
				: (iqentry_5_islot == 2'b11) ? 2'b11
				: (iqentry_5_islot + {1'b0, iqentry_issue[5]});

    assign iqentry_issue[7] = (iqentry_v[7] && !iqentry_out[7] && !iqentry_agen[7]
				&& (head0 == 3'd7 || ~|iqentry_6_islot || (iqentry_6_islot == 2'b01 && ~iqentry_issue[6]))
				&& (iqentry_a1_v[7] 
				    || (iqentry_a1_s[7] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a1_s[7] == alu1_sourceid && alu1_dataready))
				&& (iqentry_a2_v[7] 
				    || (iqentry_mem[7] & ~iqentry_agen[7])
				    || (iqentry_a2_s[7] == alu0_sourceid && alu0_dataready)
				    || (iqentry_a2_s[7] == alu1_sourceid && alu1_dataready)));
    assign iqentry_7_islot = (head0 == 3'd7) ? 2'b00
				: (iqentry_6_islot == 2'b11) ? 2'b11
				: (iqentry_6_islot + {1'b0, iqentry_issue[6]});

    // 
    // additional logic for handling a branch miss (STOMP logic)
    //
    assign  iqentry_stomp[0] = branchmiss && iqentry_v[0] && head0 != 3'd0 && (missid == 3'd7 || iqentry_stomp[7]),
	    iqentry_stomp[1] = branchmiss && iqentry_v[1] && head0 != 3'd1 && (missid == 3'd0 || iqentry_stomp[0]),
	    iqentry_stomp[2] = branchmiss && iqentry_v[2] && head0 != 3'd2 && (missid == 3'd1 || iqentry_stomp[1]),
	    iqentry_stomp[3] = branchmiss && iqentry_v[3] && head0 != 3'd3 && (missid == 3'd2 || iqentry_stomp[2]),
	    iqentry_stomp[4] = branchmiss && iqentry_v[4] && head0 != 3'd4 && (missid == 3'd3 || iqentry_stomp[3]),
	    iqentry_stomp[5] = branchmiss && iqentry_v[5] && head0 != 3'd5 && (missid == 3'd4 || iqentry_stomp[4]),
	    iqentry_stomp[6] = branchmiss && iqentry_v[6] && head0 != 3'd6 && (missid == 3'd5 || iqentry_stomp[5]),
	    iqentry_stomp[7] = branchmiss && iqentry_v[7] && head0 != 3'd7 && (missid == 3'd6 || iqentry_stomp[6]);


    //
    // EXECUTE
    //
    assign alu0_bus =     (alu0_op == `ADD)	? alu0_argA + alu0_argB
			: (alu0_op == `NAND)	? ~(alu0_argA & alu0_argB)
			: (alu0_op == `LUI)	? alu0_argB
			: (alu0_op == `BEQ)	? alu0_argA ^ alu0_argB
			: (alu0_op == `JALR)	? alu0_pc + 1
			: 16'hDEAD;	

    assign alu1_bus =     (alu1_op == `ADD)	? alu1_argA + alu1_argB
			: (alu1_op == `NAND)	? ~(alu1_argA & alu1_argB)
			: (alu1_op == `LUI)	? alu1_argB
			: (alu1_op == `BEQ)	? alu1_argA ^ alu1_argB
			: (alu1_op == `JALR)	? alu1_pc + 1
			: 16'hDEAD;	

    assign  alu0_v = alu0_dataready,
	    alu1_v = alu1_dataready;

    assign  alu0_id = alu0_sourceid,
	    alu1_id = alu1_sourceid;

    assign  alu0_misspc = (alu0_op == `JALR) ? alu0_argA : (alu0_bt ? alu0_pc + 1 : alu0_pc + 1 + alu0_argI),
	    alu1_misspc = (alu1_op == `JALR) ? alu1_argA : (alu1_bt ? alu1_pc + 1 : alu1_pc + 1 + alu1_argI);

    assign  alu0_exc = (alu0_op != `EXTEND)
			? `EXC_NONE
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_NONE)	? `EXC_NONE
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_CALL)	? alu0_argB[`INSTRUCTION_S2]
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_MFSR)	? `EXC_NONE
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_MTSR)	? `EXC_NONE
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_RFU1)	? `EXC_INVALID
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_RFU2)	? `EXC_INVALID
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_RFU3)	? `EXC_INVALID
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_EXC)	? alu0_argB[`INSTRUCTION_S2]
			: `EXC_INVALID;

    assign  alu1_exc = (alu1_op != `EXTEND)
			? `EXC_NONE
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_NONE)	? `EXC_NONE
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_CALL)	? alu1_argB[`INSTRUCTION_S2]
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_MFSR)	? `EXC_NONE
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_MTSR)	? `EXC_NONE
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_RFU1)	? `EXC_INVALID
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_RFU2)	? `EXC_INVALID
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_RFU3)	? `EXC_INVALID
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_EXC)	? alu1_argB[`INSTRUCTION_S2]
			: `EXC_INVALID;

    assign alu0_branchmiss = alu0_dataready && 
			   ((alu0_op == `BEQ)  ? ((alu0_argA == alu0_argB && ~alu0_bt) || (alu0_argA != alu0_argB && alu0_bt))
			  : (alu0_op == `JALR) ? (alu0_argB[`INSTRUCTION_S1] != `SYS_MFSR && alu0_argB[`INSTRUCTION_S1] != `SYS_MTSR)
			  : `INV);

    assign alu1_branchmiss = alu1_dataready && 
			   ((alu1_op == `BEQ)  ? ((alu1_argA == alu1_argB && ~alu1_bt) || (alu1_argA != alu1_argB && alu1_bt))
			  : (alu1_op == `JALR) ? (alu1_argB[`INSTRUCTION_S1] != `SYS_MFSR && alu1_argB[`INSTRUCTION_S1] != `SYS_MTSR)
			  : `INV);

    assign  branchmiss = (alu0_branchmiss | alu1_branchmiss),
	    misspc = (alu0_branchmiss ? alu0_misspc : alu1_misspc),
	    missid = (alu0_branchmiss ? alu0_sourceid : alu1_sourceid);

    //
    // MEMORY
    //
    // update the memory queues and put data out on bus if appropriate
    //
    always @(posedge clk) begin: memory_phase

	//
	// dram0, dram1, dram2 are the "state machines" that keep track
	// of three pipelined DRAM requests.  if any has the value "00", 
	// then it can accept a request (which bumps it up to the value "01"
	// at the end of the cycle).  once it hits the value "11" the request
	// is finished and the dram_bus takes the value.  if it is a store, the 
	// dram_bus value is not used, but the dram_v value along with the
	// dram_id value signals the waiting memq entry that the store is
	// completed and the instruction can commit.
	//

	if (dram0 != `DRAMSLOT_AVAIL)	dram0 <= dram0 + 2'd1;
	if (dram1 != `DRAMSLOT_AVAIL)	dram1 <= dram1 + 2'd1;
	if (dram2 != `DRAMSLOT_AVAIL)	dram2 <= dram2 + 2'd1;

	casex ({dram0, dram1, dram2})
	    // not particularly portable ...
	    6'b1111xx,
	    6'b11xx11,
	    6'bxx1111:	panic <= `PANIC_IDENTICALDRAMS;

	    default: begin
		//
		// grab requests that have finished and put them on the dram_bus
		if (dram0 == `DRAMREQ_READY) begin
		    dram_v <= (dram0_op == `LW);
		    dram_id <= dram0_id;
		    dram_tgt <= dram0_tgt;
		    dram_exc <= dram0_exc;
		    if (dram0_op == `LW) 	dram_bus <= m[ dram0_addr ];
		    else if (dram0_op == `SW) 	m[ dram0_addr ] <= dram0_data;
		    else			panic <= `PANIC_INVALIDMEMOP;
		    if (dram0_op == `SW) 	$display("m[%h] <- %h", dram0_addr, dram0_data);
		end
		else if (dram1 == `DRAMREQ_READY) begin
		    dram_v <= (dram1_op == `LW);
		    dram_id <= dram1_id;
		    dram_tgt <= dram1_tgt;
		    dram_exc <= dram1_exc;
		    if (dram1_op == `LW) 	dram_bus <= m[ dram1_addr ];
		    else if (dram1_op == `SW) 	m[ dram1_addr ] <= dram1_data;
		    else			panic <= `PANIC_INVALIDMEMOP;
		    if (dram1_op == `SW) 	$display("m[%h] <- %h", dram1_addr, dram1_data);
		end
		else if (dram2 == `DRAMREQ_READY) begin
		    dram_v <= (dram2_op == `LW);
		    dram_id <= dram2_id;
		    dram_tgt <= dram2_tgt;
		    dram_exc <= dram2_exc;
		    if (dram2_op == `LW) 	dram_bus <= m[ dram2_addr ];
		    else if (dram2_op == `SW) 	m[ dram2_addr ] <= dram2_data;
		    else			panic <= `PANIC_INVALIDMEMOP;
		    if (dram2_op == `SW) 	$display("m[%h] <- %h", dram2_addr, dram2_data);
		end
		else begin
		    dram_v <= `INV;
		end
	    end
	endcase

	//
	// determine if the instructions ready to issue can, in fact, issue.
	// "ready" means that the instruction has valid operands but has not gone yet
	iqentry_memissue[ head0 ] <=	iqentry_memready[ head0 ];		// first in line ... go as soon as ready

	iqentry_memissue[ head1 ] <=	~iqentry_stomp[head1] && iqentry_memready[ head1 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
						|| (iqentry_a1_v[head0] && iqentry_a1[head1] != iqentry_a1[head0]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_op[head1] == `LW ||
					    (iqentry_op[head0] != `BEQ && iqentry_op[head0] != `JALR));

	iqentry_memissue[ head2 ] <=	~iqentry_stomp[head2] && iqentry_memready[ head2 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
						|| (iqentry_a1_v[head0] && iqentry_a1[head2] != iqentry_a1[head0]))
					&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
						|| (iqentry_a1_v[head1] && iqentry_a1[head2] != iqentry_a1[head1]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_op[head2] == `LW ||
					    (   iqentry_op[head0] != `BEQ && iqentry_op[head0] != `JALR
					     && iqentry_op[head1] != `BEQ && iqentry_op[head1] != `JALR));

	iqentry_memissue[ head3 ] <=	~iqentry_stomp[head3] && iqentry_memready[ head3 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					&& ~iqentry_memready[head2] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
						|| (iqentry_a1_v[head0] && iqentry_a1[head3] != iqentry_a1[head0]))
					&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
						|| (iqentry_a1_v[head1] && iqentry_a1[head3] != iqentry_a1[head1]))
					&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
						|| (iqentry_a1_v[head2] && iqentry_a1[head3] != iqentry_a1[head2]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_op[head3] == `LW ||
					    (   iqentry_op[head0] != `BEQ && iqentry_op[head0] != `JALR
					     && iqentry_op[head1] != `BEQ && iqentry_op[head1] != `JALR
					     && iqentry_op[head2] != `BEQ && iqentry_op[head2] != `JALR));

	iqentry_memissue[ head4 ] <=	~iqentry_stomp[head4] && iqentry_memready[ head4 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					&& ~iqentry_memready[head2] 
					&& ~iqentry_memready[head3] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
						|| (iqentry_a1_v[head0] && iqentry_a1[head4] != iqentry_a1[head0]))
					&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
						|| (iqentry_a1_v[head1] && iqentry_a1[head4] != iqentry_a1[head1]))
					&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
						|| (iqentry_a1_v[head2] && iqentry_a1[head4] != iqentry_a1[head2]))
					&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
						|| (iqentry_a1_v[head3] && iqentry_a1[head4] != iqentry_a1[head3]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_op[head4] == `LW ||
					    (   iqentry_op[head0] != `BEQ && iqentry_op[head0] != `JALR
					     && iqentry_op[head1] != `BEQ && iqentry_op[head1] != `JALR
					     && iqentry_op[head2] != `BEQ && iqentry_op[head2] != `JALR
					     && iqentry_op[head3] != `BEQ && iqentry_op[head3] != `JALR));

	iqentry_memissue[ head5 ] <=	~iqentry_stomp[head5] && iqentry_memready[ head5 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					&& ~iqentry_memready[head2] 
					&& ~iqentry_memready[head3] 
					&& ~iqentry_memready[head4] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[head0] || (iqentry_agen[head0] & iqentry_out[head0]) 
						|| (iqentry_a1_v[head0] && iqentry_a1[head5] != iqentry_a1[head0]))
					&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
						|| (iqentry_a1_v[head1] && iqentry_a1[head5] != iqentry_a1[head1]))
					&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
						|| (iqentry_a1_v[head2] && iqentry_a1[head5] != iqentry_a1[head2]))
					&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
						|| (iqentry_a1_v[head3] && iqentry_a1[head5] != iqentry_a1[head3]))
					&& (!iqentry_mem[head4] || (iqentry_agen[head4] & iqentry_out[head4]) 
						|| (iqentry_a1_v[head4] && iqentry_a1[head5] != iqentry_a1[head4]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_op[head5] == `LW ||
					    (   iqentry_op[head0] != `BEQ && iqentry_op[head0] != `JALR
					     && iqentry_op[head1] != `BEQ && iqentry_op[head1] != `JALR
					     && iqentry_op[head2] != `BEQ && iqentry_op[head2] != `JALR
					     && iqentry_op[head3] != `BEQ && iqentry_op[head3] != `JALR
					     && iqentry_op[head4] != `BEQ && iqentry_op[head4] != `JALR));

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
						|| (iqentry_a1_v[head0] && iqentry_a1[head6] != iqentry_a1[head0]))
					&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
						|| (iqentry_a1_v[head1] && iqentry_a1[head6] != iqentry_a1[head1]))
					&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
						|| (iqentry_a1_v[head2] && iqentry_a1[head6] != iqentry_a1[head2]))
					&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
						|| (iqentry_a1_v[head3] && iqentry_a1[head6] != iqentry_a1[head3]))
					&& (!iqentry_mem[head4] || (iqentry_agen[head4] & iqentry_out[head4]) 
						|| (iqentry_a1_v[head4] && iqentry_a1[head6] != iqentry_a1[head4]))
					&& (!iqentry_mem[head5] || (iqentry_agen[head5] & iqentry_out[head5]) 
						|| (iqentry_a1_v[head5] && iqentry_a1[head6] != iqentry_a1[head5]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_op[head6] == `LW ||
					    (   iqentry_op[head0] != `BEQ && iqentry_op[head0] != `JALR
					     && iqentry_op[head1] != `BEQ && iqentry_op[head1] != `JALR
					     && iqentry_op[head2] != `BEQ && iqentry_op[head2] != `JALR
					     && iqentry_op[head3] != `BEQ && iqentry_op[head3] != `JALR
					     && iqentry_op[head4] != `BEQ && iqentry_op[head4] != `JALR
					     && iqentry_op[head5] != `BEQ && iqentry_op[head5] != `JALR));

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
						|| (iqentry_a1_v[head0] && iqentry_a1[head7] != iqentry_a1[head0]))
					&& (!iqentry_mem[head1] || (iqentry_agen[head1] & iqentry_out[head1]) 
						|| (iqentry_a1_v[head1] && iqentry_a1[head7] != iqentry_a1[head1]))
					&& (!iqentry_mem[head2] || (iqentry_agen[head2] & iqentry_out[head2]) 
						|| (iqentry_a1_v[head2] && iqentry_a1[head7] != iqentry_a1[head2]))
					&& (!iqentry_mem[head3] || (iqentry_agen[head3] & iqentry_out[head3]) 
						|| (iqentry_a1_v[head3] && iqentry_a1[head7] != iqentry_a1[head3]))
					&& (!iqentry_mem[head4] || (iqentry_agen[head4] & iqentry_out[head4]) 
						|| (iqentry_a1_v[head4] && iqentry_a1[head7] != iqentry_a1[head4]))
					&& (!iqentry_mem[head5] || (iqentry_agen[head5] & iqentry_out[head5]) 
						|| (iqentry_a1_v[head5] && iqentry_a1[head7] != iqentry_a1[head5]))
					&& (!iqentry_mem[head6] || (iqentry_agen[head6] & iqentry_out[head6]) 
						|| (iqentry_a1_v[head6] && iqentry_a1[head7] != iqentry_a1[head6]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_op[head7] == `LW ||
					    (   iqentry_op[head0] != `BEQ && iqentry_op[head0] != `JALR
					     && iqentry_op[head1] != `BEQ && iqentry_op[head1] != `JALR
					     && iqentry_op[head2] != `BEQ && iqentry_op[head2] != `JALR
					     && iqentry_op[head3] != `BEQ && iqentry_op[head3] != `JALR
					     && iqentry_op[head4] != `BEQ && iqentry_op[head4] != `JALR
					     && iqentry_op[head5] != `BEQ && iqentry_op[head5] != `JALR
					     && iqentry_op[head6] != `BEQ && iqentry_op[head6] != `JALR));

	//
	// take requests that are ready and put them into DRAM slots

	if (dram0 == `DRAMSLOT_AVAIL)	dram0_exc <= `EXC_NONE;
	if (dram1 == `DRAMSLOT_AVAIL)	dram1_exc <= `EXC_NONE;
	if (dram2 == `DRAMSLOT_AVAIL)	dram2_exc <= `EXC_NONE;

	if (~iqentry_stomp[0] && iqentry_memissue[0] && iqentry_agen[0] && ~iqentry_out[0]) begin
	    if (dram0 == `DRAMSLOT_AVAIL) begin
		dram0 		<= 2'd1;
		dram0_id 	<= { 1'b1, 3'd0 };
		dram0_op 	<= iqentry_op[0];
		dram0_tgt 	<= iqentry_tgt[0];
		dram0_data	<= iqentry_a2[0];
		dram0_addr	<= iqentry_a1[0];
		iqentry_out[0]	<= `VAL;
	    end
	    else if (dram1 == `DRAMSLOT_AVAIL) begin
		dram1 		<= 2'd1;
		dram1_id 	<= { 1'b1, 3'd0 };
		dram1_op 	<= iqentry_op[0];
		dram1_tgt 	<= iqentry_tgt[0];
		dram1_data	<= iqentry_a2[0];
		dram1_addr	<= iqentry_a1[0];
		iqentry_out[0]	<= `VAL;
	    end
	    else if (dram2 == `DRAMSLOT_AVAIL) begin
		dram2 		<= 2'd1;
		dram2_id 	<= { 1'b1, 3'd0 };
		dram2_op 	<= iqentry_op[0];
		dram2_tgt 	<= iqentry_tgt[0];
		dram2_data	<= iqentry_a2[0];
		dram2_addr	<= iqentry_a1[0];
		iqentry_out[0]	<= `VAL;
	    end
	end

	if (~iqentry_stomp[1] && iqentry_memissue[1] && iqentry_agen[1] && ~iqentry_out[1]) begin
	    if (dram0 == `DRAMSLOT_AVAIL) begin
		dram0 		<= 2'd1;
		dram0_id 	<= { 1'b1, 3'd1 };
		dram0_op 	<= iqentry_op[1];
		dram0_tgt 	<= iqentry_tgt[1];
		dram0_data	<= iqentry_a2[1];
		dram0_addr	<= iqentry_a1[1];
		iqentry_out[1]	<= `VAL;
	    end
	    else if (dram1 == `DRAMSLOT_AVAIL) begin
		dram1 		<= 2'd1;
		dram1_id 	<= { 1'b1, 3'd1 };
		dram1_op 	<= iqentry_op[1];
		dram1_tgt 	<= iqentry_tgt[1];
		dram1_data	<= iqentry_a2[1];
		dram1_addr	<= iqentry_a1[1];
		iqentry_out[1]	<= `VAL;
	    end
	    else if (dram2 == `DRAMSLOT_AVAIL) begin
		dram2 		<= 2'd1;
		dram2_id 	<= { 1'b1, 3'd1 };
		dram2_op 	<= iqentry_op[1];
		dram2_tgt 	<= iqentry_tgt[1];
		dram2_data	<= iqentry_a2[1];
		dram2_addr	<= iqentry_a1[1];
		iqentry_out[1]	<= `VAL;
	    end
	end

	if (~iqentry_stomp[2] && iqentry_memissue[2] && iqentry_agen[2] && ~iqentry_out[2]) begin
	    if (dram0 == `DRAMSLOT_AVAIL) begin
		dram0 		<= 2'd1;
		dram0_id 	<= { 1'b1, 3'd2 };
		dram0_op 	<= iqentry_op[2];
		dram0_tgt 	<= iqentry_tgt[2];
		dram0_data	<= iqentry_a2[2];
		dram0_addr	<= iqentry_a1[2];
		iqentry_out[2]	<= `VAL;
	    end
	    else if (dram1 == `DRAMSLOT_AVAIL) begin
		dram1 		<= 2'd1;
		dram1_id 	<= { 1'b1, 3'd2 };
		dram1_op 	<= iqentry_op[2];
		dram1_tgt 	<= iqentry_tgt[2];
		dram1_data	<= iqentry_a2[2];
		dram1_addr	<= iqentry_a1[2];
		iqentry_out[2]	<= `VAL;
	    end
	    else if (dram2 == `DRAMSLOT_AVAIL) begin
		dram2 		<= 2'd1;
		dram2_id 	<= { 1'b1, 3'd2 };
		dram2_op 	<= iqentry_op[2];
		dram2_tgt 	<= iqentry_tgt[2];
		dram2_data	<= iqentry_a2[2];
		dram2_addr	<= iqentry_a1[2];
		iqentry_out[2]	<= `VAL;
	    end
	end

	if (~iqentry_stomp[3] && iqentry_memissue[3] && iqentry_agen[3] && ~iqentry_out[3]) begin
	    if (dram0 == `DRAMSLOT_AVAIL) begin
		dram0 		<= 2'd1;
		dram0_id 	<= { 1'b1, 3'd3 };
		dram0_op 	<= iqentry_op[3];
		dram0_tgt 	<= iqentry_tgt[3];
		dram0_data	<= iqentry_a2[3];
		dram0_addr	<= iqentry_a1[3];
		iqentry_out[3]	<= `VAL;
	    end
	    else if (dram1 == `DRAMSLOT_AVAIL) begin
		dram1 		<= 2'd1;
		dram1_id 	<= { 1'b1, 3'd3 };
		dram1_op 	<= iqentry_op[3];
		dram1_tgt 	<= iqentry_tgt[3];
		dram1_data	<= iqentry_a2[3];
		dram1_addr	<= iqentry_a1[3];
		iqentry_out[3]	<= `VAL;
	    end
	    else if (dram2 == `DRAMSLOT_AVAIL) begin
		dram2 		<= 2'd1;
		dram2_id 	<= { 1'b1, 3'd3 };
		dram2_op 	<= iqentry_op[3];
		dram2_tgt 	<= iqentry_tgt[3];
		dram2_data	<= iqentry_a2[3];
		dram2_addr	<= iqentry_a1[3];
		iqentry_out[3]	<= `VAL;
	    end
	end

	if (~iqentry_stomp[4] && iqentry_memissue[4] && iqentry_agen[4] && ~iqentry_out[4]) begin
	    if (dram0 == `DRAMSLOT_AVAIL) begin
		dram0 		<= 2'd1;
		dram0_id 	<= { 1'b1, 3'd4 };
		dram0_op 	<= iqentry_op[4];
		dram0_tgt 	<= iqentry_tgt[4];
		dram0_data	<= iqentry_a2[4];
		dram0_addr	<= iqentry_a1[4];
		iqentry_out[4]	<= `VAL;
	    end
	    else if (dram1 == `DRAMSLOT_AVAIL) begin
		dram1 		<= 2'd1;
		dram1_id 	<= { 1'b1, 3'd4 };
		dram1_op 	<= iqentry_op[4];
		dram1_tgt 	<= iqentry_tgt[4];
		dram1_data	<= iqentry_a2[4];
		dram1_addr	<= iqentry_a1[4];
		iqentry_out[4]	<= `VAL;
	    end
	    else if (dram2 == `DRAMSLOT_AVAIL) begin
		dram2 		<= 2'd1;
		dram2_id 	<= { 1'b1, 3'd4 };
		dram2_op 	<= iqentry_op[4];
		dram2_tgt 	<= iqentry_tgt[4];
		dram2_data	<= iqentry_a2[4];
		dram2_addr	<= iqentry_a1[4];
		iqentry_out[4]	<= `VAL;
	    end
	end

	if (~iqentry_stomp[5] && iqentry_memissue[5] && iqentry_agen[5] && ~iqentry_out[5]) begin
	    if (dram0 == `DRAMSLOT_AVAIL) begin
		dram0 		<= 2'd1;
		dram0_id 	<= { 1'b1, 3'd5 };
		dram0_op 	<= iqentry_op[5];
		dram0_tgt 	<= iqentry_tgt[5];
		dram0_data	<= iqentry_a2[5];
		dram0_addr	<= iqentry_a1[5];
		iqentry_out[5]	<= `VAL;
	    end
	    else if (dram1 == `DRAMSLOT_AVAIL) begin
		dram1 		<= 2'd1;
		dram1_id 	<= { 1'b1, 3'd5 };
		dram1_op 	<= iqentry_op[5];
		dram1_tgt 	<= iqentry_tgt[5];
		dram1_data	<= iqentry_a2[5];
		dram1_addr	<= iqentry_a1[5];
		iqentry_out[5]	<= `VAL;
	    end
	    else if (dram2 == `DRAMSLOT_AVAIL) begin
		dram2 		<= 2'd1;
		dram2_id 	<= { 1'b1, 3'd5 };
		dram2_op 	<= iqentry_op[5];
		dram2_tgt 	<= iqentry_tgt[5];
		dram2_data	<= iqentry_a2[5];
		dram2_addr	<= iqentry_a1[5];
		iqentry_out[5]	<= `VAL;
	    end
	end

	if (~iqentry_stomp[6] && iqentry_memissue[6] && iqentry_agen[6] && ~iqentry_out[6]) begin
	    if (dram0 == `DRAMSLOT_AVAIL) begin
		dram0 		<= 2'd1;
		dram0_id 	<= { 1'b1, 3'd6 };
		dram0_op 	<= iqentry_op[6];
		dram0_tgt 	<= iqentry_tgt[6];
		dram0_data	<= iqentry_a2[6];
		dram0_addr	<= iqentry_a1[6];
		iqentry_out[6]	<= `VAL;
	    end
	    else if (dram1 == `DRAMSLOT_AVAIL) begin
		dram1 		<= 2'd1;
		dram1_id 	<= { 1'b1, 3'd6 };
		dram1_op 	<= iqentry_op[6];
		dram1_tgt 	<= iqentry_tgt[6];
		dram1_data	<= iqentry_a2[6];
		dram1_addr	<= iqentry_a1[6];
		iqentry_out[6]	<= `VAL;
	    end
	    else if (dram2 == `DRAMSLOT_AVAIL) begin
		dram2 		<= 2'd1;
		dram2_id 	<= { 1'b1, 3'd6 };
		dram2_op 	<= iqentry_op[6];
		dram2_tgt 	<= iqentry_tgt[6];
		dram2_data	<= iqentry_a2[6];
		dram2_addr	<= iqentry_a1[6];
		iqentry_out[6]	<= `VAL;
	    end
	end

	if (~iqentry_stomp[7] && iqentry_memissue[7] && iqentry_agen[7] && ~iqentry_out[7]) begin
	    if (dram0 == `DRAMSLOT_AVAIL) begin
		dram0 		<= 2'd1;
		dram0_id 	<= { 1'b1, 3'd7 };
		dram0_op 	<= iqentry_op[7];
		dram0_tgt 	<= iqentry_tgt[7];
		dram0_data	<= iqentry_a2[7];
		dram0_addr	<= iqentry_a1[7];
		iqentry_out[7]	<= `VAL;
	    end
	    else if (dram1 == `DRAMSLOT_AVAIL) begin
		dram1 		<= 2'd1;
		dram1_id 	<= { 1'b1, 3'd7 };
		dram1_op 	<= iqentry_op[7];
		dram1_tgt 	<= iqentry_tgt[7];
		dram1_data	<= iqentry_a2[7];
		dram1_addr	<= iqentry_a1[7];
		iqentry_out[7]	<= `VAL;
	    end
	    else if (dram2 == `DRAMSLOT_AVAIL) begin
		dram2 		<= 2'd1;
		dram2_id 	<= { 1'b1, 3'd7 };
		dram2_op 	<= iqentry_op[7];
		dram2_tgt 	<= iqentry_tgt[7];
		dram2_data	<= iqentry_a2[7];
		dram2_addr	<= iqentry_a1[7];
		iqentry_out[7]	<= `VAL;
	    end
	end

    end

    //
    // additional DRAM-enqueue logic

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

    assign outstanding_stores = (dram0 && dram0_op == `SW) || (dram1 && dram1_op == `SW) || (dram2 && dram2_op == `SW);

    //
    // COMMIT PHASE (dequeue only ... not register-file update)
    //
    // look at head0 and head1 and let 'em write to the register file if they are ready
    //
    always @(posedge clk) begin: commit_phase

	if (~|panic)
	case ({ iqentry_v[head0],
		iqentry_done[head0],
		iqentry_v[head1],
		iqentry_done[head1] })

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
	    // retire 0
	    4'b10_00,
	    4'b10_01,
	    4'b10_10,
	    4'b10_11: ;

	    //
	    // retire 1
	    4'b00_10,
	    4'b01_10,
	    4'b11_10: begin
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
		    if (iqentry_v[head0] && iqentry_exc[head0])	panic <= `PANIC_HALTINSTRUCTION;
		    I <= I + 1;
		end
	    end

	    //
	    // retire 2
	    default: begin
		if ((iqentry_v[head0] && iqentry_v[head1]) || (head0 != tail0 && head1 != tail0)) begin
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
		    if (iqentry_v[head0] && iqentry_exc[head0])	panic <= `PANIC_HALTINSTRUCTION;
		    if (iqentry_v[head1] && iqentry_exc[head1])	panic <= `PANIC_HALTINSTRUCTION;
		    I <= I + 2;
		end
		else if (iqentry_v[head0] || head0 != tail0) begin
		    iqentry_v[head0] <= `INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
		    head0 <= head0 + 1;
		    head1 <= head1 + 1;
		    head2 <= head2 + 1;
		    head3 <= head3 + 1;
		    head4 <= head4 + 1;
		    head5 <= head5 + 1;
		    head6 <= head6 + 1;
		    head7 <= head7 + 1;
		    if (iqentry_v[head0] && iqentry_exc[head0])	panic <= `PANIC_HALTINSTRUCTION;
		    I <= I + 1;
		end
	    end
	endcase

    end

    //
    // additional COMMIT logic
    //

    assign commit0_v = ({iqentry_v[head0], iqentry_done[head0]} == 2'b11 && ~|panic);
    assign commit1_v = (   {iqentry_v[head0], iqentry_done[head0]} != 2'b10 
			&& {iqentry_v[head1], iqentry_done[head1]} == 2'b11 && ~|panic);

    assign commit0_id = {iqentry_mem[head0], head0};	// if a memory op, it has a DRAM-bus id
    assign commit1_id = {iqentry_mem[head1], head1};	// if a memory op, it has a DRAM-bus id

    assign commit0_tgt = iqentry_tgt[head0];
    assign commit1_tgt = iqentry_tgt[head1];

    assign commit0_bus = iqentry_res[head0];
    assign commit1_bus = iqentry_res[head1];


    always begin: clock_n_debug
	reg [3:0] i;
	integer j;

	#5 clk = 0; 
	#5 rf[0] = 0; rf_v[0] = 1; rf_source[0] = 0; clk = 1;

	$display("\n\n\n\n\n\n\n\n");
	$display("TIME %0d", $time);
	$display("%h #", pc0);

	for (i=0; i<8; i=i+1)
	    $display("%d: %h %d %o #", i, rf[i], rf_v[i], rf_source[i]);

	$display("%d %h #", branchback, backpc);
	$display("%c%c A: %d %h %h #",
	    45, fetchbuf?45:62, fetchbufA_v, fetchbufA_instr, fetchbufA_pc);
	$display("%c%c B: %d %h %h #",
	    45, fetchbuf?45:62, fetchbufB_v, fetchbufB_instr, fetchbufB_pc);
	$display("%c%c C: %d %h %h #",
	    45, fetchbuf?62:45, fetchbufC_v, fetchbufC_instr, fetchbufC_pc);
	$display("%c%c D: %d %h %h #",
	    45, fetchbuf?62:45, fetchbufD_v, fetchbufD_instr, fetchbufD_pc);

	for (i=0; i<8; i=i+1) 
	    $display("%c%c %d: %d %d %d %d %d %d %d %d %d %c%d 0%d %o %h %h %h %d %o %h %d %o %h #",
		(i[2:0]==head0)?72:46, (i[2:0]==tail0)?84:46, i,
		iqentry_v[i], iqentry_done[i], iqentry_out[i], iqentry_bt[i], iqentry_memissue[i], iqentry_agen[i], iqentry_issue[i],
		((i==0) ? iqentry_0_islot : (i==1) ? iqentry_1_islot : (i==2) ? iqentry_2_islot : (i==3) ? iqentry_3_islot :
		 (i==4) ? iqentry_4_islot : (i==5) ? iqentry_5_islot : (i==6) ? iqentry_6_islot : iqentry_7_islot), iqentry_stomp[i],
		((iqentry_op[i]==`BEQ || iqentry_op[i]==`JALR) ? 98 : (iqentry_op[i]==`LW || iqentry_op[i]==`SW) ? 109 : 97), 
		iqentry_op[i], iqentry_tgt[i], iqentry_exc[i], iqentry_res[i], iqentry_a0[i], iqentry_a1[i], iqentry_a1_v[i],
		iqentry_a1_s[i], iqentry_a2[i], iqentry_a2_v[i], iqentry_a2_s[i], iqentry_pc[i]);

	$display("%d %h %h %c%d %o #",
	    dram0, dram0_addr, dram0_data, ((dram0_op==`BEQ || dram0_op==`JALR) ? 98 : (dram0_op==`LW || dram0_op==`SW) ? 109 : 97), 
	    dram0_op, dram0_id);
	$display("%d %h %h %c%d %o #",
	    dram1, dram1_addr, dram1_data, ((dram1_op==`BEQ || dram1_op==`JALR) ? 98 : (dram1_op==`LW || dram1_op==`SW) ? 109 : 97), 
	    dram1_op, dram1_id);
	$display("%d %h %h %c%d %o #",
	    dram2, dram2_addr, dram2_data, ((dram2_op==`BEQ || dram2_op==`JALR) ? 98 : (dram2_op==`LW || dram2_op==`SW) ? 109 : 97), 
	    dram2_op, dram2_id);
	$display("%d %h %o %h #", dram_v, dram_bus, dram_id, dram_exc);

	$display("%d %h %h %h %c%d %d %o %h #",
		alu0_dataready, alu0_argI, alu0_argA, alu0_argB, 
		 ((alu0_op==`BEQ || alu0_op==`JALR) ? 98 : (alu0_op==`LW || alu0_op==`SW) ? 109 : 97),
		alu0_op, alu0_bt, alu0_sourceid, alu0_pc);
	$display("%d %h %o 0 #", alu0_v, alu0_bus, alu0_id);
	$display("%d %o %h #", alu0_branchmiss, alu0_sourceid, alu0_misspc); 

	$display("%d %h %h %h %c%d %d %o %h #",
		alu1_dataready, alu1_argI, alu1_argA, alu1_argB, 
		 ((alu1_op==`BEQ || alu1_op==`JALR) ? 98 : (alu1_op==`LW || alu1_op==`SW) ? 109 : 97),
		alu1_op, alu1_bt, alu1_sourceid, alu1_pc);
	$display("%d %h %o 0 #", alu1_v, alu1_bus, alu1_id);
	$display("%d %o %h #", alu1_branchmiss, alu1_sourceid, alu1_misspc); 

	$display("0: %d %h %o 0%d #", commit0_v, commit0_bus, commit0_id, commit0_tgt);
	$display("1: %d %h %o 0%d #", commit1_v, commit1_bus, commit1_id, commit1_tgt);

/*
	$display("\n\n\n\n\n\n\n\n");
	$display("TIME %0d", $time);
	$display("  pc0=%h", pc0);
	$display("  pc1=%h", pc1);
	$display("  reg0=%h, v=%d, src=%o", rf[0], rf_v[0], rf_source[0]);
	$display("  reg1=%h, v=%d, src=%o", rf[1], rf_v[1], rf_source[1]);
	$display("  reg2=%h, v=%d, src=%o", rf[2], rf_v[2], rf_source[2]);
	$display("  reg3=%h, v=%d, src=%o", rf[3], rf_v[3], rf_source[3]);
	$display("  reg4=%h, v=%d, src=%o", rf[4], rf_v[4], rf_source[4]);
	$display("  reg5=%h, v=%d, src=%o", rf[5], rf_v[5], rf_source[5]);
	$display("  reg6=%h, v=%d, src=%o", rf[6], rf_v[6], rf_source[6]);
	$display("  reg7=%h, v=%d, src=%o", rf[7], rf_v[7], rf_source[7]);

	$display("Fetch Buffers:");
	$display("  %c%c fbA: v=%d instr=%h pc=%h     %c%c fbC: v=%d instr=%h pc=%h", 
	    fetchbuf?32:45, fetchbuf?32:62, fetchbufA_v, fetchbufA_instr, fetchbufA_pc,
	    fetchbuf?45:32, fetchbuf?62:32, fetchbufC_v, fetchbufC_instr, fetchbufC_pc);
	$display("  %c%c fbB: v=%d instr=%h pc=%h     %c%c fbD: v=%d instr=%h pc=%h", 
	    fetchbuf?32:45, fetchbuf?32:62, fetchbufB_v, fetchbufB_instr, fetchbufB_pc,
	    fetchbuf?45:32, fetchbuf?62:32, fetchbufD_v, fetchbufD_instr, fetchbufD_pc);
	$display("  branchback=%d backpc=%h", branchback, backpc);

	$display("Instruction Queue:");
	for (i=0; i<8; i=i+1) 
	    $display(" %c%c%d: v=%d done=%d out=%d agen=%d res=%h op=%d bt=%d tgt=%d a1=%h (v=%d/s=%o) a2=%h (v=%d/s=%o) im=%h pc=%h exc=%h",
		(i[2:0]==head0)?72:32, (i[2:0]==tail0)?84:32, i,
		iqentry_v[i], iqentry_done[i], iqentry_out[i], iqentry_agen[i], iqentry_res[i], iqentry_op[i], 
		iqentry_bt[i], iqentry_tgt[i], iqentry_a1[i], iqentry_a1_v[i], iqentry_a1_s[i], iqentry_a2[i], iqentry_a2_v[i], 
		iqentry_a2_s[i], iqentry_a0[i], iqentry_pc[i], iqentry_exc[i]);

	$display("Scheduling Status:");
	$display("  iqentry0 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b", 
		iqentry_0_issue, iqentry_0_islot, iqentry_stomp[0], iqentry_source[0], iqentry_memready[0], iqentry_memissue[0]);
	$display("  iqentry1 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b",
		iqentry_1_issue, iqentry_1_islot, iqentry_stomp[1], iqentry_source[1], iqentry_memready[1], iqentry_memissue[1]);
	$display("  iqentry2 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b",
		iqentry_2_issue, iqentry_2_islot, iqentry_stomp[2], iqentry_source[2], iqentry_memready[2], iqentry_memissue[2]);
	$display("  iqentry3 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b", 
		iqentry_3_issue, iqentry_3_islot, iqentry_stomp[3], iqentry_source[3], iqentry_memready[3], iqentry_memissue[3]);
	$display("  iqentry4 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b", 
		iqentry_4_issue, iqentry_4_islot, iqentry_stomp[4], iqentry_source[4], iqentry_memready[4], iqentry_memissue[4]);
	$display("  iqentry5 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b", 
		iqentry_5_issue, iqentry_5_islot, iqentry_stomp[5], iqentry_source[5], iqentry_memready[5], iqentry_memissue[5]);
	$display("  iqentry6 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b",
		iqentry_6_issue, iqentry_6_islot, iqentry_stomp[6], iqentry_source[6], iqentry_memready[6], iqentry_memissue[6]);
	$display("  iqentry7 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b",
		iqentry_7_issue, iqentry_7_islot, iqentry_stomp[7], iqentry_source[7], iqentry_memready[7], iqentry_memissue[7]);

	$display("ALU Inputs:");
	$display("  0: avail=%d data=%d id=%o op=%d a1=%h a2=%h im=%h bt=%d",
		alu0_available, alu0_dataready, alu0_sourceid, alu0_op, alu0_argA,
		alu0_argB, alu0_argI, alu0_bt);
	$display("  1: avail=%d data=%d id=%o op=%d a1=%h a2=%h im=%h bt=%d",
		alu1_available, alu1_dataready, alu1_sourceid, alu1_op, alu1_argA,
		alu1_argB, alu1_argI, alu1_bt);

	$display("ALU Outputs:");
	$display("  0: v=%d bus=%h id=%o bmiss=%d misspc=%h missid=%o",
		alu0_v, alu0_bus, alu0_id, alu0_branchmiss, alu0_misspc, alu0_sourceid);
	$display("  1: v=%d bus=%h id=%o bmiss=%d misspc=%h missid=%o",
		alu1_v, alu1_bus, alu1_id, alu1_branchmiss, alu1_misspc, alu1_sourceid);

	$display("DRAM Status:");
	$display("  OUT: v=%d data=%h tgt=%d id=%o", dram_v, dram_bus, dram_tgt, dram_id);
	$display("  dram0: status=%h addr=%h data=%h op=%d tgt=%d id=%o",
	    dram0, dram0_addr, dram0_data, dram0_op, dram0_tgt, dram0_id);
	$display("  dram1: status=%h addr=%h data=%h op=%d tgt=%d id=%o", 
	    dram1, dram1_addr, dram1_data, dram1_op, dram1_tgt, dram1_id);
	$display("  dram2: status=%h addr=%h data=%h op=%d tgt=%d id=%o",
	    dram2, dram2_addr, dram2_data, dram2_op, dram2_tgt, dram2_id);

	$display("Commit Buses:");
	$display("  0: v=%d id=%o data=%h", commit0_v, commit0_id, commit0_bus);
	$display("  1: v=%d id=%o data=%h", commit1_v, commit1_id, commit1_bus);

*/
	$display("Memory Contents:");
	for (j=0; j<64; j=j+16)
	    $display("  %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h", 
		m[j+0], m[j+1], m[j+2], m[j+3], m[j+4], m[j+5], m[j+6], m[j+7],
		m[j+8], m[j+9], m[j+10], m[j+11], m[j+12], m[j+13], m[j+14], m[j+15]);

	$display("");

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

endmodule


module decoder3 (num, out);
    input [2:0] num;
    output [7:1] out;
    reg [7:1] out;

    always @(num)
	case (num)
	    3'd0 :	out <= 7'b0000000; 
	    3'd1 :	out <= 7'b0000001;
	    3'd2 :	out <= 7'b0000010;
	    3'd3 :	out <= 7'b0000100;
	    3'd4 :	out <= 7'b0001000;
	    3'd5 :	out <= 7'b0010000;
	    3'd6 :	out <= 7'b0100000;
	    3'd7 :	out <= 7'b1000000;
	endcase
endmodule


