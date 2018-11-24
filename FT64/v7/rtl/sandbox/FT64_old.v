// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64.v
//	Features include:
//  - 16/32/48 bit instructions
//  - vector instruction set,
//  - SIMD instructions
//  - data width of 64 bits
//	- 32 general purpose registers
//  - 32 floating point registers
//	- 32 vector registers, length 63
//  - powerful branch prediction
//  - branch target buffer (BTB)
//  - return address predictor (RSB)
//  - bus interface unit
//  - instruction and data caches
//  - asynchronous logic loops for issue and branch miss
//    re-written for synchronous operation, not as elegant
//    but required for operation in an FPGA
//	- fine-grained simultaneous multi-threading (SMT)
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
// Approx 41,000 LUTs. 66,000 LC's.
// ============================================================================
//
`include "FT64_config.vh"
`include "FT64_defines.vh"

module FT64(hartid, rst, clk_i, clk4x, tm_clk_i, irq_i, vec_i, bte_o, cti_o, cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_o, dat_i,
    ol_o, pcr_o, pcr2_o, icl_o, sr_o, cr_o, rbi_i, signal_i);
input [63:0] hartid;
input rst;
input clk_i;
input clk4x;
input tm_clk_i;
input [3:0] irq_i;
input [7:0] vec_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output cyc_o;
output reg stb_o;
input ack_i;
input err_i;
output we_o;
output reg [7:0] sel_o;
output [`ABITS] adr_o;
output reg [63:0] dat_o;
input [63:0] dat_i;
output reg [1:0] ol_o;
output [31:0] pcr_o;
output [63:0] pcr2_o;
output reg icl_o;
output reg cr_o;
output reg sr_o;
input rbi_i;
input [31:0] signal_i;

parameter TM_CLKFREQ = 20000000;
parameter QENTRIES = `QENTRIES;
parameter RSTPC = 64'hFFFC0100;
parameter BRKPC = 64'hFFFC0000;
`ifdef SUPPORT_SMT
parameter PREGS = 256;   // number of physical registers - 1
parameter AREGS = 256;   // number of architectural registers
`else
parameter PREGS = 128;
parameter AREGS = 128;
`endif
parameter RBIT = 11;
parameter DEBUG = 1'b0;
parameter NMAP = QENTRIES;
parameter BRANCH_PRED = 1'b0;
parameter SUP_TXE = 1'b0;
`ifdef SUPPORT_VECTOR
parameter SUP_VECTOR = 1'b1;
`else
parameter SUP_VECTOR = 1'b0;
`endif
parameter DBW = 64;
parameter ABW = 64;
parameter AMSB = ABW-1;
parameter NTHREAD = 1;
reg [7:0] i;
integer n;
integer j, k;
genvar g, h;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
// Memory access sizes
parameter byt = 3'd0;
parameter wyde = 3'd1;
parameter tetra = 3'd2;
parameter octa = 3'd3;
// IQ states
parameter IQS_IDLE = 2'd0;
parameter IQS_AGEN = 2'd1;
parameter IQS_LDDONE = 2'd2;
parameter IQS_S3 = 2'd3;

wire clk;
//BUFG uclkb1
//(
//	.I(clk_i),
//	.O(clk)
//);
assign clk = clk_i;

wire exv_i;
wire rdv_i;
wire wrv_i;
reg [ABW-1:0] vadr;
reg cyc;
reg we;

wire dc_ack;
wire acki = ack_i|dc_ack;
wire [RBIT:0] Ra0, Ra1, Ra2;
wire [RBIT:0] Rb0, Rb1, Rb2;
wire [RBIT:0] Rc0, Rc1, Rc2;
wire [RBIT:0] Rt0, Rt1, Rt2;
wire [63:0] rfoa0,rfob0,rfoc0,rfoc0a;
wire [63:0] rfoa1,rfob1,rfoc1,rfoc1a;
wire [63:0] rfoa2,rfob2,rfoc2,rfoc2a;
`ifdef SUPPORT_SMT
wire [7:0] Ra0s = {Ra0[7:0]};
wire [7:0] Ra1s = {Ra1[7:0]};
wire [7:0] Ra2s = {Ra2[7:0]};
wire [7:0] Rb0s = {Rb0[7:0]};
wire [7:0] Rb1s = {Rb1[7:0]};
wire [7:0] Rb2s = {Rb2[7:0]};
wire [7:0] Rc0s = {Rc0[7:0]};
wire [7:0] Rc1s = {Rc1[7:0]};
wire [7:0] Rc2s = {Rc2[7:0]};
wire [7:0] Rt0s = {Rt0[7:0]};
wire [7:0] Rt1s = {Rt1[7:0]};
wire [7:0] Rt2s = {Rt2[7:0]};
`else
wire [6:0] Ra0s = {Ra0[7],Ra0[5:0]};
wire [6:0] Ra1s = {Ra1[7],Ra1[5:0]};
wire [6:0] Ra2s = {Ra2[7],Ra2[5:0]};
wire [6:0] Rb0s = {Rb0[7],Rb0[5:0]};
wire [6:0] Rb1s = {Rb1[7],Rb1[5:0]};
wire [6:0] Rb2s = {Rb2[7],Rb2[5:0]};
wire [6:0] Rc0s = {Rc0[7],Rc0[5:0]};
wire [6:0] Rc1s = {Rc1[7],Rc1[5:0]};
wire [6:0] Rc2s = {Rc2[7],Rc2[5:0]};
wire [6:0] Rt0s = {Rt0[7],Rt0[5:0]};
wire [6:0] Rt1s = {Rt1[7],Rt1[5:0]};
wire [6:0] Rt2s = {Rt2[7],Rt2[5:0]};
/*
wire [5:0] Ra0s = {Ra0[5:0]};
wire [5:0] Ra1s = {Ra1[5:0]};
wire [5:0] Rb0s = {Rb0[5:0]};
wire [5:0] Rb1s = {Rb1[5:0]};
wire [5:0] Rc0s = {Rc0[5:0]};
wire [5:0] Rc1s = {Rc1[5:0]};
wire [5:0] Rt0s = {Rt0[5:0]};
wire [5:0] Rt1s = {Rt1[5:0]};
*/
`endif

reg [63:0] ds [0:NTHREAD];
reg [63:0] ss [0:NTHREAD];
reg [63:0] ptrmask [0:NTHREAD];
reg [63:0] ptrkey = "  OBJECT";
reg [63:0] wbrcd;

reg  [PREGS-1:0] rf_v;
reg  [`QBITSP1] rf_source[0:AREGS-1];
initial begin
for (n = 0; n < AREGS; n = n + 1)
	rf_source[n] = 1'b0;
end
wire [`ABITS] pc0;
wire [`ABITS] pc1;
wire [`ABITS] pc2;

reg excmiss;
reg [`ABITS] excmisspc;
reg excthrd;
reg exception_set;
reg rdvq;               // accumulated read violation
reg errq;               // accumulated err_i input status
reg exvq;

// Vector
reg [5:0] vqe0, vqe1, vqe2;   // vector element being queued
reg [5:0] vqet0, vqet1, vqet2;
reg [7:0] vl;           // vector length
reg [63:0] vm [0:7];    // vector mask registers
reg [1:0] m2;

reg [31:0] wb_merges;
// CSR's
reg [63:0] cr0;
wire snr = cr0[17];		// sequence number reset
wire dce = cr0[30];     // data cache enable
wire bpe = cr0[32];     // branch predictor enable
wire wbm = cr0[34];
wire ctgtxe = cr0[33];
reg [63:0] pmr;
wire id1_available = pmr[0];
wire id2_available = pmr[1];
wire id3_available = pmr[2];
wire alu0_available = pmr[8];
wire alu1_available = pmr[9];
wire fpu1_available = pmr[16];
wire fpu2_available = pmr[17];
wire mem1_available = pmr[24];
wire mem2_available = pmr[25];
wire mem3_available = pmr[26];
wire fcu_available = pmr[32];
// Simply setting this flag to zero should strip out almost all the logic
// associated SMT.
`ifdef SUPPORT_SMT
wire thread_en = cr0[16];
`else
wire thread_en = 1'b0;
`endif
wire vechain = cr0[18];
reg [39:0] iq_ctr;
reg [39:0] irq_ctr;					// count of number of interrupts
reg [39:0] bm_ctr;					// branch miss counter
reg [39:0] icl_ctr;					// instruction cache load counter

reg [7:0] fcu_timeout;
reg [63:0] tick;
reg [63:0] wc_time;
reg [31:0] pcr;
reg [63:0] pcr2;
assign pcr_o = pcr;
assign pcr2_o = pcr2;
reg [63:0] aec;
reg [15:0] cause[0:15];
`ifdef SUPPORT_SMT
reg [`ABITS] epc [0:NTHREAD];
reg [`ABITS] epc0 [0:NTHREAD];
reg [`ABITS] epc1 [0:NTHREAD];
reg [`ABITS] epc2 [0:NTHREAD];
reg [`ABITS] epc3 [0:NTHREAD];
reg [`ABITS] epc4 [0:NTHREAD];
reg [`ABITS] epc5 [0:NTHREAD];
reg [`ABITS] epc6 [0:NTHREAD];
reg [`ABITS] epc7 [0:NTHREAD];
reg [`ABITS] epc8 [0:NTHREAD]; 			// exception pc and stack
reg [63:0] mstatus [0:NTHREAD];  		// machine status
wire [3:0] im = mstatus[0][3:0];
wire [1:0] ol [0:NTHREAD];
wire [1:0] dl [0:NTHREAD];
assign ol[0] = mstatus[0][5:4];	// operating level
assign dl[0] = mstatus[0][21:20];
wire [7:0] cpl [0:NTHREAD];
assign cpl[0] = mstatus[0][13:6];	// current privilege level
wire [5:0] rgs [0:NTHREAD];
assign rgs[0] = mstatus[0][19:14];
assign ol[1] = mstatus[1][5:4];	// operating level
assign cpl[1] = mstatus[1][13:6];	// current privilege level
assign rgs[1] = mstatus[1][19:14];
assign dl[1] = mstatus[1][21:20];
wire [7:0] ASID = mstatus[0][47:40];
reg [15:0] ol_stack [0:NTHREAD];
reg [31:0] im_stack [0:NTHREAD];
reg [63:0] pl_stack [0:NTHREAD];
reg [63:0] rs_stack [0:NTHREAD];
reg [63:0] fr_stack [0:NTHREAD];
wire mprv = mstatus[0][55];
wire [5:0] fprgs = mstatus[0][25:20];
//assign ol_o = mprv ? ol_stack[0][2:0] : ol[0];
wire vca = mstatus[0][32];		// vector chaining active
`else
reg [`ABITS] epc ;
reg [`ABITS] epc0 ;
reg [`ABITS] epc1 ;
reg [`ABITS] epc2 ;
reg [`ABITS] epc3 ;
reg [`ABITS] epc4 ;
reg [`ABITS] epc5 ;
reg [`ABITS] epc6 ;
reg [`ABITS] epc7 ;
reg [`ABITS] epc8 ; 			// exception pc and stack
reg [63:0] mstatus ;  		// machine status
wire [3:0] im = mstatus[3:0];
wire [1:0] ol ;
wire [1:0] dl;
assign ol = mstatus[5:4];	// operating level
assign dl = mstatus[21:20];
wire [7:0] cpl ;
assign cpl = mstatus[13:6];	// current privilege level
wire [5:0] rgs ;
assign rgs = mstatus[19:14];
reg [15:0] ol_stack ;
reg [31:0] im_stack ;
reg [63:0] pl_stack ;
reg [63:0] rs_stack ;
reg [63:0] fr_stack ;
wire mprv = mstatus[55];
wire [7:0] ASID = mstatus[47:40];
wire [5:0] fprgs = mstatus[25:20];
//assign ol_o = mprv ? ol_stack[2:0] : ol;
wire vca = mstatus[32];		// vector chaining active
`endif
reg [63:0] tcb;
reg [`ABITS] badaddr[0:15];
reg [`ABITS] tvec[0:7];
reg [63:0] sema;
reg [63:0] vm_sema;
reg [63:0] cas;         // compare and swap
reg [63:0] ve_hold;
reg isCAS, isAMO, isInc, isSpt, isRMW;
reg [`QBITS] casid;
reg [`ABITS] sbl, sbu;
reg [4:0] regLR = 5'd29;

reg [2:0] fp_rm;
reg fp_inexe;
reg fp_dbzxe;
reg fp_underxe;
reg fp_overxe;
reg fp_invopxe;
reg fp_giopxe;
reg fp_nsfp = 1'b0;
reg fp_fractie;
reg fp_raz;

reg fp_neg;
reg fp_pos;
reg fp_zero;
reg fp_inf;

reg fp_inex;		// inexact exception
reg fp_dbzx;		// divide by zero exception
reg fp_underx;		// underflow exception
reg fp_overx;		// overflow exception
reg fp_giopx;		// global invalid operation exception
reg fp_sx;			// summary exception
reg fp_swtx;        // software triggered exception
reg fp_gx;
reg fp_invopx;

reg fp_infzerox;
reg fp_zerozerox;
reg fp_subinfx;
reg fp_infdivx;
reg fp_NaNCmpx;
reg fp_cvtx;
reg fp_sqrtx;
reg fp_snanx;

wire [31:0] fp_status = {

	fp_rm,
	fp_inexe,
	fp_dbzxe,
	fp_underxe,
	fp_overxe,
	fp_invopxe,
	fp_nsfp,

	fp_fractie,
	fp_raz,
	1'b0,
	fp_neg,
	fp_pos,
	fp_zero,
	fp_inf,

	fp_swtx,
	fp_inex,
	fp_dbzx,
	fp_underx,
	fp_overx,
	fp_giopx,
	fp_gx,
	fp_sx,
	
	fp_cvtx,
	fp_sqrtx,
	fp_NaNCmpx,
	fp_infzerox,
	fp_zerozerox,
	fp_infdivx,
	fp_subinfx,
	fp_snanx
	};

reg [63:0] fpu_csr;
wire [5:0] fp_rgs = fpu_csr[37:32];

//reg [25:0] m[0:8191];
reg  [3:0] panic;		// indexes the message structure
reg [128:0] message [0:15];	// indexed by panic

wire int_commit;
reg StatusHWI;
reg [47:0] insn0, insn1, insn2;
wire [47:0] insn0a, insn1b, insn2b;
reg [47:0] insn1a, insn2a;
// Only need enough bits in the seqnence number to cover the instructions in
// the queue plus an extra count for skipping on branch misses. In this case
// that would be four bits minimum (count 0 to 8). 
wire [63:0] rdat0,rdat1,rdat2;
reg [63:0] xdati;

reg canq1, canq2, canq3;
reg queued1;
reg queued2;
reg queued3;
reg queuedNop;

reg [47:0] codebuf[0:63];
reg [QENTRIES-1:0] setpred;

// instruction queue (ROB)
reg [`SNBITS] iqentry_sn [0:QENTRIES-1];  // instruction sequence number
reg [QENTRIES-1:0] iqentry_v;			// entry valid?  -- this should be the first bit
reg [QENTRIES-1:0] iqentry_iv;		// instruction is valid
reg [`QBITSP1] iqentry_is [0:QENTRIES-1];	// source of instruction
reg [QENTRIES-1:0] iqentry_out;	// instruction has been issued to an ALU ... 
reg [QENTRIES-1:0] iqentry_done;	// instruction result valid
(* mark_debug="true" *)
reg [QENTRIES-1:0] iqentry_cmt;
reg [QENTRIES-1:0] iqentry_thrd;		// which thread the instruction is in
reg [QENTRIES-1:0] iqentry_pt;		// predict taken
reg [QENTRIES-1:0] iqentry_bt;		// update branch target buffer
reg [QENTRIES-1:0] iqentry_takb;	// take branch record
reg [QENTRIES-1:0] iqentry_jal;
reg [QENTRIES-1:0] iqentry_agen;	// address-generate ... signifies that address is ready (only for LW/SW)
reg  [1:0] iqentry_state [0:QENTRIES-1];
reg [2:0] iqentry_sz [0:QENTRIES-1];
reg [QENTRIES-1:0] iqentry_alu = 8'h00;  // alu type instruction
reg [QENTRIES-1:0] iqentry_alu0;	 // only valid on alu #0
reg [QENTRIES-1:0] iqentry_fpu;  // floating point instruction
reg [QENTRIES-1:0] iqentry_fc;   // flow control instruction
reg [QENTRIES-1:0] iqentry_canex = 8'h00;	// true if it's an instruction that can exception
reg [QENTRIES-1:0] iqentry_oddball = 8'h00;	// writes to register file
reg [QENTRIES-1:0] iqentry_load;	// is a memory load instruction
reg [QENTRIES-1:0] iqentry_loadv;	// is a volatile memory load instruction
reg [QENTRIES-1:0] iqentry_store;	// is a memory store instruction
reg [QENTRIES-1:0] iqentry_preload;	// is a memory preload instruction
reg [QENTRIES-1:0] iqentry_ldcmp;
reg [QENTRIES-1:0] iqentry_mem;	// touches memory: 1 if LW/SW
reg [QENTRIES-1:0] iqentry_memndx;  // indexed memory operation 
reg [2:0] iqentry_memsz [0:QENTRIES-1];	// size of memory op
reg [QENTRIES-1:0] iqentry_rmw;	// memory RMW op
reg [QENTRIES-1:0] iqentry_push;
reg [QENTRIES-1:0] iqentry_memdb;
reg [QENTRIES-1:0] iqentry_memsb;
reg [QENTRIES-1:0] iqentry_rtop;
reg [QENTRIES-1:0] iqentry_sei;
reg [QENTRIES-1:0] iqentry_aq;	// memory aquire
reg [QENTRIES-1:0] iqentry_rl;	// memory release
reg [QENTRIES-1:0] iqentry_shft;
reg [QENTRIES-1:0] iqentry_jmp;	// changes control flow: 1 if BEQ/JALR
reg [QENTRIES-1:0] iqentry_br;  // Bcc (for predictor)
reg [QENTRIES-1:0] iqentry_ret;
reg [QENTRIES-1:0] iqentry_irq;
reg [QENTRIES-1:0] iqentry_brk;
reg [QENTRIES-1:0] iqentry_rti;
reg [QENTRIES-1:0] iqentry_sync;  // sync instruction
reg [QENTRIES-1:0] iqentry_fsync;
reg [QENTRIES-1:0] iqentry_tlb;
reg [QENTRIES-1:0] iqentry_rfw = 8'h00;	// writes to register file
reg  [7:0] iqentry_we   [0:QENTRIES-1];	// enable strobe
reg [63:0] iqentry_res	[0:QENTRIES-1];	// instruction result
reg [63:0] iqentry_ares	[0:QENTRIES-1];	// alternate instruction result
reg [47:0] iqentry_instr[0:QENTRIES-1];	// instruction opcode
reg  [2:0] iqentry_insln[0:QENTRIES-1]; // instruction length
reg  [7:0] iqentry_exc	[0:QENTRIES-1];	// only for branches ... indicates a HALT instruction
reg [RBIT:0] iqentry_tgt[0:QENTRIES-1];	// Rt field or ZERO -- this is the instruction's target (if any)
reg  [7:0] iqentry_vl   [0:QENTRIES-1];
reg  [5:0] iqentry_ven  [0:QENTRIES-1];  // vector element number
reg [AMSB:0] iqentry_ma [0:QENTRIES-1];	// memory address
reg [63:0] iqentry_a0	[0:QENTRIES-1];	// argument 0 (immediate)
reg [63:0] iqentry_a1	[0:QENTRIES-1];	// argument 1
reg        iqentry_a1_v	[0:QENTRIES-1];	// arg1 valid
reg  [`QBITSP1] iqentry_a1_s	[0:QENTRIES-1];	// arg1 source (iq entry # with top bit representing ALU/DRAM bus)
reg [63:0] iqentry_a2	[0:QENTRIES-1];	// argument 2
reg        iqentry_a2_v	[0:QENTRIES-1];	// arg2 valid
reg  [`QBITSP1] iqentry_a2_s	[0:QENTRIES-1];	// arg2 source (iq entry # with top bit representing ALU/DRAM bus)
reg [63:0] iqentry_a3	[0:QENTRIES-1];	// argument 3
reg        iqentry_a3_v	[0:QENTRIES-1];	// arg3 valid
reg  [`QBITSP1] iqentry_a3_s	[0:QENTRIES-1];	// arg3 source (iq entry # with top bit representing ALU/DRAM bus)
reg [`ABITS] iqentry_pc	[0:QENTRIES-1];	// program counter for this instruction
reg [RBIT:0] iqentry_Ra [0:QENTRIES-1];
reg [RBIT:0] iqentry_Rb [0:QENTRIES-1];
reg [RBIT:0] iqentry_Rc [0:QENTRIES-1];
// debugging
//reg  [4:0] iqentry_ra   [0:7];  // Ra
initial begin
for (n = 0; n < QENTRIES; n = n + 1)
	iqentry_a1_s[n] <= 5'd0;
	iqentry_a2_s[n] <= 5'd0;
	iqentry_a3_s[n] <= 5'd0;
end

reg [QENTRIES-1:0] iqentry_source = {QENTRIES{1'b0}};
reg   [QENTRIES-1:0] iqentry_imm;
reg  [QENTRIES-1:0] iqentry_memready;
reg  [QENTRIES-1:0] iqentry_memopsvalid;

reg  [QENTRIES-1:0] memissue = {QENTRIES{1'b0}};
reg [1:0] missued;
reg [7:0] last_issue0, last_issue1, last_issue2;
reg  [QENTRIES-1:0] iqentry_memissue;
reg [QENTRIES-1:0] iqentry_stomp;
reg [3:0] stompedOnRets;
reg  [QENTRIES-1:0] iqentry_alu0_issue;
reg  [QENTRIES-1:0] iqentry_alu1_issue;
reg  [QENTRIES-1:0] iqentry_alu2_issue;
reg  [QENTRIES-1:0] iqentry_id1issue;
reg  [QENTRIES-1:0] iqentry_id2issue;
reg  [QENTRIES-1:0] iqentry_id3issue;
reg [1:0] iqentry_mem_islot [0:QENTRIES-1];
reg [QENTRIES-1:0] iqentry_fcu_issue;
reg [QENTRIES-1:0] iqentry_fpu1_issue;
reg [QENTRIES-1:0] iqentry_fpu2_issue;

reg [PREGS-1:1] livetarget;
reg [PREGS-1:1] iqentry_livetarget [0:QENTRIES-1];
reg [PREGS-1:1] iqentry_latestID [0:QENTRIES-1];
reg [PREGS-1:1] iqentry_cumulative [0:QENTRIES-1];
wire  [PREGS-1:1] iq_out [0:QENTRIES-1];

reg  [`QBITS] tail0;
reg  [`QBITS] tail1;
reg  [`QBITS] tail2;
reg  [`QBITS] heads[0:QENTRIES-1];

// To detect a head change at time of commit. Some values need to pulsed
// with a single pulse.
reg  [`QBITS] ohead[0:2];
reg ocommit0_v, ocommit1_v, ocommit2_v;
reg [8:0] cmt_timer;

wire take_branch0;
wire take_branch1;

reg [3:0] nop_fetchbuf;
wire        fetchbuf;	// determines which pair to read from & write to
wire [3:0] fb_panic;

wire [47:0] fetchbuf0_instr;	
wire  [2:0] fetchbuf0_insln;
wire [`ABITS] fetchbuf0_pc;
wire        fetchbuf0_v;
wire		fetchbuf0_thrd;
wire 		fetchbuf0_mem;
wire        fetchbuf0_rfw;
wire [47:0] fetchbuf1_instr;
wire  [2:0] fetchbuf1_insln;
wire [`ABITS] fetchbuf1_pc;
wire        fetchbuf1_v;
wire		fetchbuf1_thrd;
wire		fetchbuf1_mem;
wire        fetchbuf1_rfw;
wire [47:0] fetchbuf2_instr;
wire  [2:0] fetchbuf2_insln;
wire [`ABITS] fetchbuf2_pc;
wire        fetchbuf2_v;
wire		fetchbuf2_thrd;
wire		fetchbuf2_mem;
wire        fetchbuf2_rfw;

wire [47:0] fetchbufA_instr;	
wire [`ABITS] fetchbufA_pc;
wire        fetchbufA_v;
wire [47:0] fetchbufB_instr;
wire [`ABITS] fetchbufB_pc;
wire        fetchbufB_v;
wire [47:0] fetchbufC_instr;
wire [`ABITS] fetchbufC_pc;
wire        fetchbufC_v;
wire [47:0] fetchbufD_instr;
wire [`ABITS] fetchbufD_pc;
wire        fetchbufD_v;
wire [47:0] fetchbufE_instr;
wire [`ABITS] fetchbufE_pc;
wire        fetchbufE_v;
wire [47:0] fetchbufF_instr;
wire [`ABITS] fetchbufF_pc;
wire        fetchbufF_v;

//reg        did_branchback0;
//reg        did_branchback1;

reg         id1_v;
reg   [`QBITSP1] id1_id;
reg  [47:0] id1_instr;
reg   [5:0] id1_ven;
reg   [7:0] id1_vl;
reg         id1_thrd;
reg         id1_pt;
reg   [4:0] id1_Rt;
wire [143:0] id1_bus;

reg         id2_v;
reg   [`QBITSP1] id2_id;
reg  [47:0] id2_instr;
reg   [5:0] id2_ven;
reg   [7:0] id2_vl;
reg         id2_thrd;
reg         id2_pt;
reg   [4:0] id2_Rt;
wire [143:0] id2_bus;

reg         id3_v;
reg   [`QBITSP1] id3_id;
reg  [47:0] id3_instr;
reg   [5:0] id3_ven;
reg   [7:0] id3_vl;
reg         id3_thrd;
reg         id3_pt;
reg   [4:0] id3_Rt;
wire [143:0] id3_bus;

reg        alu0_ld;
reg        alu0_dataready;
wire       alu0_done;
wire       alu0_idle;
reg  [`QBITSP1] alu0_sourceid;
reg [47:0] alu0_instr;
reg				 alu0_tlb;
reg        alu0_mem;
reg        alu0_load;
reg 			 alu0_push;
reg        alu0_shft;
reg [63:0] alu0_argA;
reg [63:0] alu0_argB;
reg [63:0] alu0_argC;
reg [63:0] alu0_argI;	// only used by BEQ
reg [2:0]  alu0_sz;
reg [RBIT:0] alu0_tgt;
reg [5:0]  alu0_ven;
reg        alu0_thrd;
reg [`ABITS] alu0_pc;
wire [63:0] alu0_bus;
wire [63:0] alu0b_bus;
wire  [`QBITSP1] alu0_id;
wire  [`XBITS] alu0_exc;
wire        alu0_v;
wire        alu0_branchmiss;
wire [`ABITS] alu0_misspc;

reg        alu1_ld;
reg        alu1_dataready;
wire       alu1_done;
wire       alu1_idle;
reg  [`QBITSP1] alu1_sourceid;
reg [47:0] alu1_instr;
reg        alu1_mem;
reg        alu1_load;
reg 			 alu1_push;
reg        alu1_shft;
reg [63:0] alu1_argA;
reg [63:0] alu1_argB;
reg [63:0] alu1_argC;
reg [63:0] alu1_argI;	// only used by BEQ
reg [2:0]  alu1_sz;
reg [RBIT:0] alu1_tgt;
reg [5:0]  alu1_ven;
reg [`ABITS] alu1_pc;
reg        alu1_thrd;
wire [63:0] alu1_bus;
wire [63:0] alu1b_bus;
wire  [`QBITSP1] alu1_id;
wire  [`XBITS] alu1_exc;
wire        alu1_v;
wire        alu1_branchmiss;
wire [`ABITS] alu1_misspc;

wire [`XBITS] fpu_exc;
reg        fpu1_ld;
reg        fpu1_dataready = 1'b1;
wire       fpu1_done = 1'b1;
wire       fpu1_idle;
reg  [3:0] fpu1_sourceid;
reg [47:0] fpu1_instr;
reg [63:0] fpu1_argA;
reg [63:0] fpu1_argB;
reg [63:0] fpu1_argC;
reg [63:0] fpu1_argI;	// only used by BEQ
reg [RBIT:0] fpu1_tgt;
reg [`ABITS] fpu1_pc;
wire [63:0] fpu1_bus = 64'h0;
wire  [`QBITSP1] fpu1_id;
wire  [`XBITS] fpu1_exc = 9'h000;
wire        fpu1_v;
wire [31:0] fpu1_status;

reg        fpu2_ld;
reg        fpu2_dataready = 1'b1;
wire       fpu2_done = 1'b1;
wire       fpu2_idle;
reg  [3:0] fpu2_sourceid;
reg [47:0] fpu2_instr;
reg [63:0] fpu2_argA;
reg [63:0] fpu2_argB;
reg [63:0] fpu2_argC;
reg [63:0] fpu2_argI;	// only used by BEQ
reg [RBIT:0] fpu2_tgt;
reg [`ABITS] fpu2_pc;
wire [63:0] fpu2_bus = 64'h0;
wire  [`QBITSP1] fpu2_id;
wire  [`XBITS] fpu2_exc = 9'h000;
wire        fpu2_v;
wire [31:0] fpu2_status;

reg [7:0] fccnt;
reg [63:0] waitctr;
reg        fcu_ld;
reg        fcu_dataready;
reg        fcu_done;
reg         fcu_idle = 1'b1;
reg  [3:0] fcu_sourceid;
reg [47:0] fcu_instr;
reg  [2:0] fcu_insln;
reg        fcu_pt;			// predict taken
reg        fcu_branch;
reg        fcu_call;
reg        fcu_ret;
reg        fcu_jal;
reg        fcu_brk;
reg        fcu_rti;
reg [63:0] fcu_argA;
reg [63:0] fcu_argB;
reg [63:0] fcu_argC;
reg [63:0] fcu_argI;	// only used by BEQ
reg [63:0] fcu_argT;
reg [63:0] fcu_argT2;
reg [`ABITS] fcu_pc;
reg [`ABITS] fcu_nextpc;
reg [`ABITS] fcu_brdisp;
wire [63:0] fcu_bus;
wire  [`QBITSP1] fcu_id;
reg   [`XBITS] fcu_exc;
wire        fcu_v;
reg        fcu_thrd;
reg        fcu_branchmiss;
reg  fcu_clearbm;
reg [`ABITS] fcu_misspc;

reg [63:0] rmw_argA;
reg [63:0] rmw_argB;
reg [63:0] rmw_argC;
wire [63:0] rmw_res;
reg [47:0] rmw_instr;

// write buffer
reg [63:0] wb_data [0:`WB_DEPTH-1];
reg [`ABITS] wb_addr [0:`WB_DEPTH-1];
reg [1:0] wb_ol [0:`WB_DEPTH-1];
reg [`WB_DEPTH-1:0] wb_v;
reg [`WB_DEPTH-1:0] wb_rmw;
reg [QENTRIES-1:0] wb_id [0:`WB_DEPTH-1];
reg [QENTRIES-1:0] wbo_id;
reg [7:0] wb_sel [0:`WB_DEPTH-1];
reg wb_en;
reg wb_shift;

(* mark_debug="true" *)
reg branchmiss = 1'b0;
reg branchmiss_thrd = 1'b0;
reg [`ABITS] misspc;
reg  [`QBITS] missid;

wire take_branch;
wire take_branchA;
wire take_branchB;
wire take_branchC;
wire take_branchD;

wire        dram_avail;
reg	 [2:0] dram0;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [2:0] dram1;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [2:0] dram2;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg [63:0] dram0_data;
reg [`ABITS] dram0_addr;
reg [47:0] dram0_instr;
reg        dram0_rmw;
reg		   dram0_preload;
reg [RBIT:0] dram0_tgt;
reg  [`QBITSP1] dram0_id;
reg  [`XBITS] dram0_exc;
reg        dram0_unc;
reg [2:0]  dram0_memsize;
reg        dram0_load;	// is a load operation
reg        dram0_store;
reg  [1:0] dram0_ol;
reg [63:0] dram1_data;
reg [`ABITS] dram1_addr;
reg [47:0] dram1_instr;
reg        dram1_rmw;
reg		   dram1_preload;
reg [RBIT:0] dram1_tgt;
reg  [`QBITSP1] dram1_id;
reg  [`XBITS] dram1_exc;
reg        dram1_unc;
reg [2:0]  dram1_memsize;
reg        dram1_load;
reg        dram1_store;
reg  [1:0] dram1_ol;
reg [63:0] dram2_data;
reg [`ABITS] dram2_addr;
reg [47:0] dram2_instr;
reg        dram2_rmw;
reg		   dram2_preload;
reg [RBIT:0] dram2_tgt;
reg  [`QBITSP1] dram2_id;
reg  [`XBITS] dram2_exc;
reg        dram2_unc;
reg [2:0]  dram2_memsize;
reg        dram2_load;
reg        dram2_store;
reg  [1:0] dram2_ol;

reg        dramA_v;
reg  [3:0] dramA_id;
reg [63:0] dramA_bus;
reg  [`XBITS] dramA_exc;
reg        dramB_v;
reg  [3:0] dramB_id;
reg [63:0] dramB_bus;
reg  [`XBITS] dramB_exc;
reg        dramC_v;
reg  [3:0] dramC_id;
reg [63:0] dramC_bus;
reg  [`XBITS] dramC_exc;

wire        outstanding_stores;
reg [63:0] I;		// instruction count
reg [63:0] CC;	// commit count

reg        commit0_v;
reg  [`QBITSP1] commit0_id;
reg [RBIT:0] commit0_tgt;
reg  [7:0] commit0_we = 8'h00;
reg [63:0] commit0_bus;
reg        commit1_v;
reg  [`QBITSP1] commit1_id;
reg [RBIT:0] commit1_tgt;
reg  [7:0] commit1_we = 8'h00;
reg [63:0] commit1_bus;
reg        commit2_v;
reg  [`QBITSP1] commit2_id;
reg [RBIT:0] commit2_tgt;
reg  [7:0] commit2_we = 8'h00;
reg [63:0] commit2_bus;

reg StoreAck1;
reg [4:0] bstate;
parameter BIDLE = 5'd0;
parameter B_StoreAck = 5'd1;
parameter B_DCacheLoadStart = 5'd2;
parameter B_DCacheLoadStb = 5'd3;
parameter B_DCacheLoadWait1 = 5'd4;
parameter B_DCacheLoadWait2 = 5'd5;
parameter B_DCacheLoadResetBusy = 5'd6;
parameter B_ICacheAck = 5'd7;
parameter B8 = 5'd8;
parameter B_ICacheNack = 5'd9;
parameter B10 = 5'd10;
parameter B11 = 5'd11;
parameter B12 = 5'd12;
parameter B_DLoadAck = 5'd13;
parameter B14 = 5'd14;
parameter B15 = 5'd15;
parameter B16 = 5'd16;
parameter B17 = 5'd17;
parameter B18 = 5'd18;
parameter B19 = 5'd19;
parameter B2a = 5'd20;
parameter B2b = 5'd21;
parameter B2c = 5'd22;
parameter B_DCacheLoadAck = 5'd23;
parameter B20 = 5'd24;
parameter B21 = 5'd25;
parameter B_DCacheLoadWait3 = 5'd26;
reg [1:0] bwhich;
reg [3:0] icstate,picstate;
parameter IDLE = 4'd0;
parameter IC1 = 4'd1;
parameter IC2 = 4'd2;
parameter IC3 = 4'd3;
parameter IC_WaitL2 = 4'd4;
parameter IC5 = 4'd5;
parameter IC6 = 4'd6;
parameter IC7 = 4'd7;
parameter IC_Next = 4'd8;
parameter IC9 = 4'd9;
parameter IC10 = 4'd10;
parameter IC3a = 4'd11;
reg invic, invdc;
reg [1:0] icwhich;
reg icnxt,L2_nxt;
wire ihit0,ihit1,ihit2,ihitL2;
wire ihit = ihit0&ihit1&ihit2;
reg phit;
wire threadx;
always @*
	phit <= ihit&&icstate==IDLE;
reg [2:0] iccnt;
reg L1_wr0,L1_wr1,L1_wr2;
reg L1_invline;
wire [1:0] ic0_fault,ic1_fault,ic2_fault;
reg [8:0] L1_en;
reg [71:0] L1_adr, L2_adr;
reg [289:0] L2_rdat;
wire [289:0] L2_dato;
reg L2_xsel;

generate begin : gRegfileInst
if (`WAYS > 2) begin : gb1
FT64_regfile2w9r_oc #(.RBIT(RBIT)) urf1
(
  .clk(clk),
  .clk4x(clk4x),
  .wr0(commit0_v),
  .wr1(commit1_v),
  .we0(commit0_we),
  .we1(commit1_we),
  .wa0(commit0_tgt),
  .wa1(commit1_tgt),
  .i0(commit0_bus),
  .i1(commit1_bus),
	.rclk(~clk),
	.ra0(Ra0),
	.ra1(Rb0),
	.ra2(Rc0),
	.o0(rfoa0),
	.o1(rfob0),
	.o2(rfoc0a),
	.ra3(Ra1),
	.ra4(Rb1),
	.ra5(Rc1),
	.o3(rfoa1),
	.o4(rfob1),
	.o5(rfoc1a),
	.ra6(Ra2),
	.ra7(Rb2),
	.ra8(Rc2),
	.o6(rfoa2),
	.o7(rfob2),
	.o8(rfoc2a)
);
assign rfoc0 = Rc0[11:6]==6'h3F ? vm[Rc0[2:0]] : rfoc0a;
assign rfoc1 = Rc1[11:6]==6'h3F ? vm[Rc1[2:0]] : rfoc1a;
assign rfoc2 = Rc2[11:6]==6'h3F ? vm[Rc2[2:0]] : rfoc2a;
end
else if (`WAYS > 1) begin : gb1
FT64_regfile2w6r_oc #(.RBIT(RBIT)) urf1
(
  .clk(clk),
  .clk4x(clk4x),
  .wr0(commit0_v),
  .wr1(commit1_v),
  .we0(commit0_we),
  .we1(commit1_we),
  .wa0(commit0_tgt),
  .wa1(commit1_tgt),
  .i0(commit0_bus),
  .i1(commit1_bus),
	.rclk(~clk),
	.ra0(Ra0),
	.ra1(Rb0),
	.ra2(Rc0),
	.o0(rfoa0),
	.o1(rfob0),
	.o2(rfoc0a),
	.ra3(Ra1),
	.ra4(Rb1),
	.ra5(Rc1),
	.o3(rfoa1),
	.o4(rfob1),
	.o5(rfoc1a)
);
assign rfoc0 = Rc0[11:6]==6'h3F ? vm[Rc0[2:0]] : rfoc0a;
assign rfoc1 = Rc1[11:6]==6'h3F ? vm[Rc1[2:0]] : rfoc1a;
end
else begin : gb1
FT64_regfile1w3r_oc #(.RBIT(RBIT)) urf1
(
  .clk(clk),
  .wr0(commit0_v),
  .we0(commit0_we),
  .wa0(commit0_tgt),
  .i0(commit0_bus),
	.rclk(~clk),
	.ra0(Ra0),
	.ra1(Rb0),
	.ra2(Rc0),
	.o0(rfoa0),
	.o1(rfob0),
	.o2(rfoc0a)
);
end
assign rfoc0 = Rc0[11:6]==6'h3F ? vm[Rc0[2:0]] : rfoc0a;
end
endgenerate

function [3:0] fnInsLength;
input [47:0] ins;
`ifdef SUPPORT_DCI
if (ins[`INSTRUCTION_OP]==`CMPRSSD)
	fnInsLength = 4'd2;
else
`endif
	case(ins[7:6])
	2'd0:	fnInsLength = 4'd4;
	2'd1:	fnInsLength = 4'd6;
	default:	fnInsLength = 4'd2;
	endcase
endfunction

wire [`ABITS] pc0plus6 = pc0 + 32'd6;
wire [`ABITS] pc0plus12 = pc0 + 32'd12;

generate begin : gInsnVar
	if (`WAYS > 1) begin
		always @*
			if (thread_en)
				insn1a <= insn1b;
			else
				insn1a = {insn1b,insn0a} >> {fnInsLength(insn0a),3'b0};
	end
	if (`WAYS > 2) begin
		always @*
			if (thread_en)
				insn2a <= insn2b;
			else
				insn2a = {insn2b,insn1b,insn0a} >> {fnInsLength(insn0a) + fnInsLength(insn1a),3'b0};
	end
end
endgenerate

FT64_L1_icache #(.pSize(`L1_ICACHE_SIZE)) uic0
(
  .rst(rst),
  .clk(clk),
  .nxt(icnxt),
  .wr(L1_wr0),
  .wr_ack(),
  .en(L1_en),
  .adr((icstate==IDLE||icstate==IC_Next) ? {pcr[5:0],pc0} : L1_adr),
  .wadr(L1_adr),
  .i(L2_rdat),
  .o(insn0a),
  .fault(ic0_fault),
  .hit(ihit0),
  .invall(invic),
  .invline(L1_invline)
);
generate begin : gICacheInst
if (`WAYS > 1) begin
FT64_L1_icache #(.pSize(`L1_ICACHE_SIZE)) uic1
(
  .rst(rst),
  .clk(clk),
  .nxt(icnxt),
  .wr(L1_wr1),
  .wr_ack(),
  .en(L1_en),
  .adr((icstate==IDLE||icstate==IC_Next) ? (thread_en ? {pcr[5:0],pc1}: {pcr[5:0],pc0plus6} ): L1_adr),
  .wadr(L1_adr),
  .i(L2_rdat),
  .o(insn1b),
  .fault(ic1_fault),
  .hit(ihit1),
  .invall(invic),
  .invline(L1_invline)
);
end
else begin
assign ihit1 = 1'b1;
end
if (`WAYS > 2) begin
FT64_L1_icache #(.pSize(`L1_ICACHE_SIZE)) uic2
(
  .rst(rst),
  .clk(clk),
  .nxt(icnxt),
  .wr(L1_wr2),
  .wr_ack(),
  .en(L1_en),
  .adr((icstate==IDLE||icstate==IC_Next) ? (thread_en ? {pcr[5:0],pc2} : {pcr[5:0],pc0plus12}) : L1_adr),
  .wadr(L1_adr),
  .i(L2_rdat),
  .o(insn2b),
  .fault(ic2_fault),
  .hit(ihit2),
  .invall(invic),
  .invline(L1_invline)
);
end
else
assign ihit2 = 1'b1;
end
endgenerate

FT64_L2_icache uic2
(
  .rst(rst),
  .clk(clk),
  .nxt(L2_nxt),
  .wr(bstate==B_ICacheAck && (ack_i|err_i)),
  .xsel(L2_xsel),
  .adr(L2_adr),
  .cnt(iccnt),
  .exv_i(exvq),
  .i(dat_i),
  .err_i(errq),
  .o(L2_dato),
  .hit(ihitL2),
  .invall(invic),
  .invline()
);

wire predict_taken;
wire predict_taken0;
wire predict_taken1;
wire predict_taken2;
wire predict_takenA;
wire predict_takenB;
wire predict_takenC;
wire predict_takenD;
wire predict_takenE;
wire predict_takenF;
wire predict_takenA1;
wire predict_takenB1;
wire predict_takenC1;
wire predict_takenD1;

wire [`ABITS] btgtA, btgtB, btgtC, btgtD, btgtE, btgtF;
wire btbwr0 = iqentry_v[heads[0]] && iqentry_done[heads[0]] &&
        (
        iqentry_jal[heads[0]] ||
        iqentry_brk[heads[0]] ||
        iqentry_rti[heads[0]]);
generate begin: gbtbvar
if (`WAYS > 1) begin
wire btbwr1 = iqentry_v[heads[1]] && iqentry_done[heads[1]] &&
        (
        iqentry_jal[heads[1]] ||
        iqentry_brk[heads[1]] ||
        iqentry_rti[heads[1]]);
end
end
endgenerate

wire fcu_clk;
`ifdef FCU_ENH
//BUFGCE ufcuclk
//(
//	.I(clk_i),
//	.CE(fcu_available),
//	.O(fcu_clk)
//);
`endif
assign fcu_clk = clk_i;

generate begin: gBTBInst
if (`WAYS > 2) begin
`ifdef FCU_ENH
FT64_BTB ubtb1
(
  .rst(rst),
  .wclk(fcu_clk),
  .wr(btbwr0 | btbwr1),  
  .wadr(btbwr0 ? iqentry_pc[heads[0]] : iqentry_pc[heads[1]]),
  .wdat(btbwr0 ? iqentry_ma[heads[0]] : iqentry_ma[heads[1]]),
  .valid(btbwr0 ? iqentry_bt[heads[0]] & iqentry_v[heads[0]] : iqentry_bt[heads[1]] & iqentry_v[heads[1]]),
  .rclk(~clk),
  .pcA(fetchbufA_pc),
  .btgtA(btgtA),
  .pcB(fetchbufB_pc),
  .btgtB(btgtB),
  .pcC(fetchbufC_pc),
  .btgtC(btgtC),
  .pcD(fetchbufD_pc),
  .btgtD(btgtD),
  .pcE(fetchbufE_pc),
  .btgtE(btgtE),
  .pcF(fetchbufF_pc),
  .btgtF(btgtF),
  .npcA(BRKPC),
  .npcB(BRKPC),
  .npcC(BRKPC),
  .npcD(BRKPC),
  .npcE(BRKPC),
  .npcF(BRKPC)
);
`else
// Branch tergets are picked up by fetchbuf logic and need to be present.
// Without a target predictor they are just set to the reset address.
// This virtually guarentees a miss.
assign btgtA = RSTPC;
assign btgtB = RSTPC;
assign btgtC = RSTPC;
assign btgtD = RSTPC;
assign btgtE = RSTPC;
assign btgtF = RSTPC;
`endif
end
else if (`WAYS > 1) begin
`ifdef FCU_ENH
FT64_BTB ubtb1
(
  .rst(rst),
  .wclk(fcu_clk),
  .wr(btbwr0 | btbwr1),  
  .wadr(btbwr0 ? iqentry_pc[heads[0]] : iqentry_pc[heads[1]]),
  .wdat(btbwr0 ? iqentry_ma[heads[0]] : iqentry_ma[heads[1]]),
  .valid(btbwr0 ? iqentry_bt[heads[0]] & iqentry_v[heads[0]] : iqentry_bt[heads[1]] & iqentry_v[heads[1]]),
  .rclk(~clk),
  .pcA(fetchbufA_pc),
  .btgtA(btgtA),
  .pcB(fetchbufB_pc),
  .btgtB(btgtB),
  .pcC(fetchbufC_pc),
  .btgtC(btgtC),
  .pcD(fetchbufD_pc),
  .btgtD(btgtD),
  .pcE(32'd0),
  .btgtE(),
  .pcF(32'd0),
  .btgtF(),
  .npcA(BRKPC),
  .npcB(BRKPC),
  .npcC(BRKPC),
  .npcD(BRKPC),
  .npcE(BRKPC),
  .npcF(BRKPC)
);
`else
// Branch tergets are picked up by fetchbuf logic and need to be present.
// Without a target predictor they are just set to the reset address.
// This virtually guarentees a miss.
assign btgtA = RSTPC;
assign btgtB = RSTPC;
assign btgtC = RSTPC;
assign btgtD = RSTPC;
`endif
end
else begin
`ifdef FCU_ENH
FT64_BTB ubtb1
(
  .rst(rst),
  .wclk(fcu_clk),
  .wr(btbwr0),  
  .wadr(iqentry_pc[heads[0]]),
  .wdat(iqentry_ma[heads[0]]),
  .valid(iqentry_bt[heads[0]] & iqentry_v[heads[0]]),
  .rclk(~clk),
  .pcA(fetchbufA_pc),
  .btgtA(btgtA),
  .pcB(fetchbufB_pc),
  .btgtB(btgtB),
  .pcC(32'd0),
  .btgtC(),
  .pcD(32'd0),
  .btgtD(),
  .pcE(32'd0),
  .btgtE(),
  .pcF(32'd0),
  .btgtF(),
  .npcA(BRKPC),
  .npcB(BRKPC),
  .npcC(BRKPC),
  .npcD(BRKPC),
  .npcE(BRKPC),
  .npcF(BRKPC)
);
`else
// Branch tergets are picked up by fetchbuf logic and need to be present.
// Without a target predictor they are just set to the reset address.
// This virtually guarentees a miss.
assign btgtA = RSTPC;
assign btgtB = RSTPC;
`endif
end
end
endgenerate

generate begin: gBPInst
if (`WAYS > 2) begin
`ifdef FCU_ENH
FT64_BranchPredictor ubp1
(
  .rst(rst),
  .clk(fcu_clk),
  .en(bpe),
  .xisBranch0(iqentry_br[heads[0]] & commit0_v),
  .xisBranch1(iqentry_br[heads[1]] & commit1_v),
  .xisBranch2(iqentry_br[heads[2]] & commit2_v),
  .pcA(fetchbufA_pc),
  .pcB(fetchbufB_pc),
  .pcC(fetchbufC_pc),
  .pcD(fetchbufD_pc),
  .pcE(fetchbufE_pc),
  .pcF(fetchbufF_pc),
  .xpc0(iqentry_pc[heads[0]]),
  .xpc1(iqentry_pc[heads[1]]),
  .xpc2(iqentry_pc[heads[2]]),
  .takb0(commit0_v & iqentry_takb[heads[0]]),
  .takb1(commit1_v & iqentry_takb[heads[1]]),
  .takb2(commit2_v & iqentry_takb[heads[2]]),
  .predict_takenA(predict_takenA),
  .predict_takenB(predict_takenB),
  .predict_takenC(predict_takenC),
  .predict_takenD(predict_takenD),
  .predict_takenE(predict_takenE),
  .predict_takenF(predict_takenF)
);
`else
// Predict based on sign of displacement
assign predict_takenA = fetchbufA_instr[6] ? fetchbufA_instr[47] : fetchbufA_instr[31];
assign predict_takenB = fetchbufB_instr[6] ? fetchbufB_instr[47] : fetchbufB_instr[31];
assign predict_takenC = fetchbufC_instr[6] ? fetchbufC_instr[47] : fetchbufC_instr[31];
assign predict_takenD = fetchbufD_instr[6] ? fetchbufD_instr[47] : fetchbufD_instr[31];
assign predict_takenE = fetchbufE_instr[6] ? fetchbufE_instr[47] : fetchbufE_instr[31];
assign predict_takenF = fetchbufF_instr[6] ? fetchbufF_instr[47] : fetchbufF_instr[31];
`endif
end
else if (`WAYS > 1) begin
`ifdef FCU_ENH
FT64_BranchPredictor ubp1
(
  .rst(rst),
  .clk(fcu_clk),
  .en(bpe),
  .xisBranch0(iqentry_br[heads[0]] & commit0_v),
  .xisBranch1(iqentry_br[heads[1]] & commit1_v),
  .xisBranch2(iqentry_br[heads[2]] & commit2_v),
  .pcA(fetchbufA_pc),
  .pcB(fetchbufB_pc),
  .pcC(fetchbufC_pc),
  .pcD(fetchbufD_pc),
  .pcE(32'd0),
  .pcF(32'd0),
  .xpc0(iqentry_pc[heads[0]]),
  .xpc1(iqentry_pc[heads[1]]),
  .xpc2(iqentry_pc[heads[2]]),
  .takb0(commit0_v & iqentry_takb[heads[0]]),
  .takb1(commit1_v & iqentry_takb[heads[1]]),
  .takb2(commit2_v & iqentry_takb[heads[2]]),
  .predict_takenA(predict_takenA),
  .predict_takenB(predict_takenB),
  .predict_takenC(predict_takenC),
  .predict_takenD(predict_takenD),
  .predict_takenE(),
  .predict_takenF()
);
`else
// Predict based on sign of displacement
assign predict_takenA = fetchbufA_instr[6] ? fetchbufA_instr[47] : fetchbufA_instr[31];
assign predict_takenB = fetchbufB_instr[6] ? fetchbufB_instr[47] : fetchbufB_instr[31];
assign predict_takenC = fetchbufC_instr[6] ? fetchbufC_instr[47] : fetchbufC_instr[31];
assign predict_takenD = fetchbufD_instr[6] ? fetchbufD_instr[47] : fetchbufD_instr[31];
`endif
end
else begin
`ifdef FCU_ENH
FT64_BranchPredictor ubp1
(
  .rst(rst),
  .clk(fcu_clk),
  .en(bpe),
  .xisBranch0(iqentry_br[heads[0]] & commit0_v),
  .xisBranch1(iqentry_br[heads[1]] & commit1_v),
  .xisBranch2(iqentry_br[heads[2]] & commit2_v),
  .pcA(fetchbufA_pc),
  .pcB(fetchbufB_pc),
  .pcC(32'd0),
  .pcD(32'd0),
  .pcE(32'd0),
  .pcF(32'd0),
  .xpc0(iqentry_pc[heads[0]]),
  .xpc1(iqentry_pc[heads[1]]),
  .xpc2(iqentry_pc[heads[2]]),
  .takb0(commit0_v & iqentry_takb[heads[0]]),
  .takb1(commit1_v & iqentry_takb[heads[1]]),
  .takb2(commit2_v & iqentry_takb[heads[2]]),
  .predict_takenA(predict_takenA),
  .predict_takenB(predict_takenB),
  .predict_takenC(),
  .predict_takenD(),
  .predict_takenE(),
  .predict_takenF()
);
`else
// Predict based on sign of displacement
assign predict_takenA = fetchbufA_instr[6] ? fetchbufA_instr[47] : fetchbufA_instr[31];
assign predict_takenB = fetchbufB_instr[6] ? fetchbufB_instr[47] : fetchbufB_instr[31];
`endif
end
end
endgenerate

//-----------------------------------------------------------------------------
// Debug
//-----------------------------------------------------------------------------
`ifdef SUPPORT_DBG

wire [DBW-1:0] dbg_stat1x;
reg [DBW-1:0] dbg_stat;
reg [DBW-1:0] dbg_ctrl;
reg [ABW-1:0] dbg_adr0;
reg [ABW-1:0] dbg_adr1;
reg [ABW-1:0] dbg_adr2;
reg [ABW-1:0] dbg_adr3;
reg dbg_imatchA0,dbg_imatchA1,dbg_imatchA2,dbg_imatchA3,dbg_imatchA;
reg dbg_imatchB0,dbg_imatchB1,dbg_imatchB2,dbg_imatchB3,dbg_imatchB;

wire dbg_lmatch00 =
			dbg_ctrl[0] && dbg_ctrl[17:16]==2'b11 && dram0_addr[AMSB:3]==dbg_adr0[AMSB:3] &&
				((dbg_ctrl[19:18]==2'b00 && dram0_addr[2:0]==dbg_adr0[2:0]) ||
				 (dbg_ctrl[19:18]==2'b01 && dram0_addr[2:1]==dbg_adr0[2:1]) ||
				 (dbg_ctrl[19:18]==2'b10 && dram0_addr[2]==dbg_adr0[2]) ||
				 dbg_ctrl[19:18]==2'b11)
				 ;
wire dbg_lmatch01 =
             dbg_ctrl[0] && dbg_ctrl[17:16]==2'b11 && dram1_addr[AMSB:3]==dbg_adr0[AMSB:3] &&
                 ((dbg_ctrl[19:18]==2'b00 && dram1_addr[2:0]==dbg_adr0[2:0]) ||
                  (dbg_ctrl[19:18]==2'b01 && dram1_addr[2:1]==dbg_adr0[2:1]) ||
                  (dbg_ctrl[19:18]==2'b10 && dram1_addr[2]==dbg_adr0[2]) ||
                  dbg_ctrl[19:18]==2'b11)
                  ;
wire dbg_lmatch02 =
           dbg_ctrl[0] && dbg_ctrl[17:16]==2'b11 && dram2_addr[AMSB:3]==dbg_adr0[AMSB:3] &&
               ((dbg_ctrl[19:18]==2'b00 && dram2_addr[2:0]==dbg_adr0[2:0]) ||
                (dbg_ctrl[19:18]==2'b01 && dram2_addr[2:1]==dbg_adr0[2:1]) ||
                (dbg_ctrl[19:18]==2'b10 && dram2_addr[2]==dbg_adr0[2]) ||
                dbg_ctrl[19:18]==2'b11)
                ;
wire dbg_lmatch10 =
             dbg_ctrl[1] && dbg_ctrl[21:20]==2'b11 && dram0_addr[AMSB:3]==dbg_adr1[AMSB:3] &&
                 ((dbg_ctrl[23:22]==2'b00 && dram0_addr[2:0]==dbg_adr1[2:0]) ||
                  (dbg_ctrl[23:22]==2'b01 && dram0_addr[2:1]==dbg_adr1[2:1]) ||
                  (dbg_ctrl[23:22]==2'b10 && dram0_addr[2]==dbg_adr1[2]) ||
                  dbg_ctrl[23:22]==2'b11)
                  ;
wire dbg_lmatch11 =
           dbg_ctrl[1] && dbg_ctrl[21:20]==2'b11 && dram1_addr[AMSB:3]==dbg_adr1[AMSB:3] &&
               ((dbg_ctrl[23:22]==2'b00 && dram1_addr[2:0]==dbg_adr1[2:0]) ||
                (dbg_ctrl[23:22]==2'b01 && dram1_addr[2:1]==dbg_adr1[2:1]) ||
                (dbg_ctrl[23:22]==2'b10 && dram1_addr[2]==dbg_adr1[2]) ||
                dbg_ctrl[23:22]==2'b11)
                ;
wire dbg_lmatch12 =
           dbg_ctrl[1] && dbg_ctrl[21:20]==2'b11 && dram2_addr[AMSB:3]==dbg_adr1[AMSB:3] &&
               ((dbg_ctrl[23:22]==2'b00 && dram2_addr[2:0]==dbg_adr1[2:0]) ||
                (dbg_ctrl[23:22]==2'b01 && dram2_addr[2:1]==dbg_adr1[2:1]) ||
                (dbg_ctrl[23:22]==2'b10 && dram2_addr[2]==dbg_adr1[2]) ||
                dbg_ctrl[23:22]==2'b11)
                ;
wire dbg_lmatch20 =
               dbg_ctrl[2] && dbg_ctrl[25:24]==2'b11 && dram0_addr[AMSB:3]==dbg_adr2[AMSB:3] &&
                   ((dbg_ctrl[27:26]==2'b00 && dram0_addr[2:0]==dbg_adr2[2:0]) ||
                    (dbg_ctrl[27:26]==2'b01 && dram0_addr[2:1]==dbg_adr2[2:1]) ||
                    (dbg_ctrl[27:26]==2'b10 && dram0_addr[2]==dbg_adr2[2]) ||
                    dbg_ctrl[27:26]==2'b11)
                    ;
wire dbg_lmatch21 =
               dbg_ctrl[2] && dbg_ctrl[25:24]==2'b11 && dram1_addr[AMSB:3]==dbg_adr2[AMSB:3] &&
                   ((dbg_ctrl[27:26]==2'b00 && dram1_addr[2:0]==dbg_adr2[2:0]) ||
                    (dbg_ctrl[27:26]==2'b01 && dram1_addr[2:1]==dbg_adr2[2:1]) ||
                    (dbg_ctrl[27:26]==2'b10 && dram1_addr[2]==dbg_adr2[2]) ||
                    dbg_ctrl[27:26]==2'b11)
                    ;
wire dbg_lmatch22 =
               dbg_ctrl[2] && dbg_ctrl[25:24]==2'b11 && dram2_addr[AMSB:3]==dbg_adr2[AMSB:3] &&
                   ((dbg_ctrl[27:26]==2'b00 && dram2_addr[2:0]==dbg_adr2[2:0]) ||
                    (dbg_ctrl[27:26]==2'b01 && dram2_addr[2:1]==dbg_adr2[2:1]) ||
                    (dbg_ctrl[27:26]==2'b10 && dram2_addr[2]==dbg_adr2[2]) ||
                    dbg_ctrl[27:26]==2'b11)
                    ;
wire dbg_lmatch30 =
                 dbg_ctrl[3] && dbg_ctrl[29:28]==2'b11 && dram0_addr[AMSB:3]==dbg_adr3[AMSB:3] &&
                     ((dbg_ctrl[31:30]==2'b00 && dram0_addr[2:0]==dbg_adr3[2:0]) ||
                      (dbg_ctrl[31:30]==2'b01 && dram0_addr[2:1]==dbg_adr3[2:1]) ||
                      (dbg_ctrl[31:30]==2'b10 && dram0_addr[2]==dbg_adr3[2]) ||
                      dbg_ctrl[31:30]==2'b11)
                      ;
wire dbg_lmatch31 =
               dbg_ctrl[3] && dbg_ctrl[29:28]==2'b11 && dram1_addr[AMSB:3]==dbg_adr3[AMSB:3] &&
                   ((dbg_ctrl[31:30]==2'b00 && dram1_addr[2:0]==dbg_adr3[2:0]) ||
                    (dbg_ctrl[31:30]==2'b01 && dram1_addr[2:1]==dbg_adr3[2:1]) ||
                    (dbg_ctrl[31:30]==2'b10 && dram1_addr[2]==dbg_adr3[2]) ||
                    dbg_ctrl[31:30]==2'b11)
                    ;
wire dbg_lmatch32 =
               dbg_ctrl[3] && dbg_ctrl[29:28]==2'b11 && dram2_addr[AMSB:3]==dbg_adr3[AMSB:3] &&
                   ((dbg_ctrl[31:30]==2'b00 && dram2_addr[2:0]==dbg_adr3[2:0]) ||
                    (dbg_ctrl[31:30]==2'b01 && dram2_addr[2:1]==dbg_adr3[2:1]) ||
                    (dbg_ctrl[31:30]==2'b10 && dram2_addr[2]==dbg_adr3[2]) ||
                    dbg_ctrl[31:30]==2'b11)
                    ;
wire dbg_lmatch0 = dbg_lmatch00|dbg_lmatch10|dbg_lmatch20|dbg_lmatch30;                  
wire dbg_lmatch1 = dbg_lmatch01|dbg_lmatch11|dbg_lmatch21|dbg_lmatch31;                  
wire dbg_lmatch2 = dbg_lmatch02|dbg_lmatch12|dbg_lmatch22|dbg_lmatch32;                  
wire dbg_lmatch = dbg_lmatch00|dbg_lmatch10|dbg_lmatch20|dbg_lmatch30|
                  dbg_lmatch01|dbg_lmatch11|dbg_lmatch21|dbg_lmatch31|
                  dbg_lmatch02|dbg_lmatch12|dbg_lmatch22|dbg_lmatch32
                    ;

wire dbg_smatch00 =
			dbg_ctrl[0] && dbg_ctrl[17:16]==2'b11 && dram0_addr[AMSB:3]==dbg_adr0[AMSB:3] &&
				((dbg_ctrl[19:18]==2'b00 && dram0_addr[2:0]==dbg_adr0[2:0]) ||
				 (dbg_ctrl[19:18]==2'b01 && dram0_addr[2:1]==dbg_adr0[2:1]) ||
				 (dbg_ctrl[19:18]==2'b10 && dram0_addr[2]==dbg_adr0[2]) ||
				 dbg_ctrl[19:18]==2'b11)
				 ;
wire dbg_smatch01 =
             dbg_ctrl[0] && dbg_ctrl[17:16]==2'b11 && dram1_addr[AMSB:3]==dbg_adr0[AMSB:3] &&
                 ((dbg_ctrl[19:18]==2'b00 && dram1_addr[2:0]==dbg_adr0[2:0]) ||
                  (dbg_ctrl[19:18]==2'b01 && dram1_addr[2:1]==dbg_adr0[2:1]) ||
                  (dbg_ctrl[19:18]==2'b10 && dram1_addr[2]==dbg_adr0[2]) ||
                  dbg_ctrl[19:18]==2'b11)
                  ;
wire dbg_smatch02 =
           dbg_ctrl[0] && dbg_ctrl[17:16]==2'b11 && dram2_addr[AMSB:3]==dbg_adr0[AMSB:3] &&
               ((dbg_ctrl[19:18]==2'b00 && dram2_addr[2:0]==dbg_adr0[2:0]) ||
                (dbg_ctrl[19:18]==2'b01 && dram2_addr[2:1]==dbg_adr0[2:1]) ||
                (dbg_ctrl[19:18]==2'b10 && dram2_addr[2]==dbg_adr0[2]) ||
                dbg_ctrl[19:18]==2'b11)
                ;
wire dbg_smatch10 =
             dbg_ctrl[1] && dbg_ctrl[21:20]==2'b11 && dram0_addr[AMSB:3]==dbg_adr1[AMSB:3] &&
                 ((dbg_ctrl[23:22]==2'b00 && dram0_addr[2:0]==dbg_adr1[2:0]) ||
                  (dbg_ctrl[23:22]==2'b01 && dram0_addr[2:1]==dbg_adr1[2:1]) ||
                  (dbg_ctrl[23:22]==2'b10 && dram0_addr[2]==dbg_adr1[2]) ||
                  dbg_ctrl[23:22]==2'b11)
                  ;
wire dbg_smatch11 =
           dbg_ctrl[1] && dbg_ctrl[21:20]==2'b11 && dram1_addr[AMSB:3]==dbg_adr1[AMSB:3] &&
               ((dbg_ctrl[23:22]==2'b00 && dram1_addr[2:0]==dbg_adr1[2:0]) ||
                (dbg_ctrl[23:22]==2'b01 && dram1_addr[2:1]==dbg_adr1[2:1]) ||
                (dbg_ctrl[23:22]==2'b10 && dram1_addr[2]==dbg_adr1[2]) ||
                dbg_ctrl[23:22]==2'b11)
                ;
wire dbg_smatch12 =
           dbg_ctrl[1] && dbg_ctrl[21:20]==2'b11 && dram2_addr[AMSB:3]==dbg_adr1[AMSB:3] &&
               ((dbg_ctrl[23:22]==2'b00 && dram2_addr[2:0]==dbg_adr1[2:0]) ||
                (dbg_ctrl[23:22]==2'b01 && dram2_addr[2:1]==dbg_adr1[2:1]) ||
                (dbg_ctrl[23:22]==2'b10 && dram2_addr[2]==dbg_adr1[2]) ||
                dbg_ctrl[23:22]==2'b11)
                ;
wire dbg_smatch20 =
               dbg_ctrl[2] && dbg_ctrl[25:24]==2'b11 && dram0_addr[AMSB:3]==dbg_adr2[AMSB:3] &&
                   ((dbg_ctrl[27:26]==2'b00 && dram0_addr[2:0]==dbg_adr2[2:0]) ||
                    (dbg_ctrl[27:26]==2'b01 && dram0_addr[2:1]==dbg_adr2[2:1]) ||
                    (dbg_ctrl[27:26]==2'b10 && dram0_addr[2]==dbg_adr2[2]) ||
                    dbg_ctrl[27:26]==2'b11)
                    ;
wire dbg_smatch21 =
           dbg_ctrl[2] && dbg_ctrl[25:24]==2'b11 && dram1_addr[AMSB:3]==dbg_adr2[AMSB:3] &&
                    ((dbg_ctrl[27:26]==2'b00 && dram1_addr[2:0]==dbg_adr2[2:0]) ||
                     (dbg_ctrl[27:26]==2'b01 && dram1_addr[2:1]==dbg_adr2[2:1]) ||
                     (dbg_ctrl[27:26]==2'b10 && dram1_addr[2]==dbg_adr2[2]) ||
                     dbg_ctrl[27:26]==2'b11)
                     ;
wire dbg_smatch22 =
            dbg_ctrl[2] && dbg_ctrl[25:24]==2'b11 && dram2_addr[AMSB:3]==dbg_adr2[AMSB:3] &&
                     ((dbg_ctrl[27:26]==2'b00 && dram2_addr[2:0]==dbg_adr2[2:0]) ||
                      (dbg_ctrl[27:26]==2'b01 && dram2_addr[2:1]==dbg_adr2[2:1]) ||
                      (dbg_ctrl[27:26]==2'b10 && dram2_addr[2]==dbg_adr2[2]) ||
                      dbg_ctrl[27:26]==2'b11)
                      ;
wire dbg_smatch30 =
                 dbg_ctrl[3] && dbg_ctrl[29:28]==2'b11 && dram0_addr[AMSB:3]==dbg_adr3[AMSB:3] &&
                     ((dbg_ctrl[31:30]==2'b00 && dram0_addr[2:0]==dbg_adr3[2:0]) ||
                      (dbg_ctrl[31:30]==2'b01 && dram0_addr[2:1]==dbg_adr3[2:1]) ||
                      (dbg_ctrl[31:30]==2'b10 && dram0_addr[2]==dbg_adr3[2]) ||
                      dbg_ctrl[31:30]==2'b11)
                      ;
wire dbg_smatch31 =
               dbg_ctrl[3] && dbg_ctrl[29:28]==2'b11 && dram1_addr[AMSB:3]==dbg_adr3[AMSB:3] &&
                   ((dbg_ctrl[31:30]==2'b00 && dram1_addr[2:0]==dbg_adr3[2:0]) ||
                    (dbg_ctrl[31:30]==2'b01 && dram1_addr[2:1]==dbg_adr3[2:1]) ||
                    (dbg_ctrl[31:30]==2'b10 && dram1_addr[2]==dbg_adr3[2]) ||
                    dbg_ctrl[31:30]==2'b11)
                    ;
wire dbg_smatch32 =
               dbg_ctrl[3] && dbg_ctrl[29:28]==2'b11 && dram2_addr[AMSB:3]==dbg_adr3[AMSB:3] &&
                   ((dbg_ctrl[31:30]==2'b00 && dram2_addr[2:0]==dbg_adr3[2:0]) ||
                    (dbg_ctrl[31:30]==2'b01 && dram2_addr[2:1]==dbg_adr3[2:1]) ||
                    (dbg_ctrl[31:30]==2'b10 && dram2_addr[2]==dbg_adr3[2]) ||
                    dbg_ctrl[31:30]==2'b11)
                    ;
wire dbg_smatch0 = dbg_smatch00|dbg_smatch10|dbg_smatch20|dbg_smatch30;
wire dbg_smatch1 = dbg_smatch01|dbg_smatch11|dbg_smatch21|dbg_smatch31;
wire dbg_smatch2 = dbg_smatch02|dbg_smatch12|dbg_smatch22|dbg_smatch32;

wire dbg_smatch =   dbg_smatch00|dbg_smatch10|dbg_smatch20|dbg_smatch30|
                    dbg_smatch01|dbg_smatch11|dbg_smatch21|dbg_smatch31|
                    dbg_smatch02|dbg_smatch12|dbg_smatch22|dbg_smatch32
                    ;

wire dbg_stat0 = dbg_imatchA0 | dbg_imatchB0 | dbg_lmatch00 | dbg_lmatch01 | dbg_lmatch02 | dbg_smatch00 | dbg_smatch01 | dbg_smatch02;
wire dbg_stat1 = dbg_imatchA1 | dbg_imatchB1 | dbg_lmatch10 | dbg_lmatch11 | dbg_lmatch12 | dbg_smatch10 | dbg_smatch11 | dbg_smatch12;
wire dbg_stat2 = dbg_imatchA2 | dbg_imatchB2 | dbg_lmatch20 | dbg_lmatch21 | dbg_lmatch22 | dbg_smatch20 | dbg_smatch21 | dbg_smatch22;
wire dbg_stat3 = dbg_imatchA3 | dbg_imatchB3 | dbg_lmatch30 | dbg_lmatch31 | dbg_lmatch32 | dbg_smatch30 | dbg_smatch31 | dbg_smatch32;
assign dbg_stat1x = {dbg_stat3,dbg_stat2,dbg_stat1,dbg_stat0};
wire debug_on = |dbg_ctrl[3:0]|dbg_ctrl[7]|dbg_ctrl[63];

always @*
begin
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
end

always @*
begin
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
end
`endif

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

// freezePC squashes the pc increment if there's an irq.
wire freezePC = (irq_i > im) && ~int_commit;
always @*
if (freezePC)
	insn0 <= {8'd0,3'd0,irq_i,1'b0,vec_i,2'b00,`BRK};
else if (phit) begin
	if (insn0a[`INSTRUCTION_OP]==`BRK && insn0a[23:21]==3'd0 && insn0a[7:6]==2'b00)
		insn0 <= {8'd1,3'd0,4'b0,1'b0,`FLT_PRIV,2'b00,`BRK};
	else
		insn0 <= ic0_fault[1] ? `INSN_FLT_IBE : ic0_fault[0] ? `INSN_FLT_EXF : insn0a;
end
else
	insn0 <= `NOP_INSN;
generate begin : gInsnMux
if (`WAYS > 1) begin
always @*
if (freezePC && !thread_en)
	insn1 <= {8'd0,3'd0,irq_i,1'b0,vec_i,2'b00,`BRK};
else if (phit) begin
	if (insn1a[`INSTRUCTION_OP]==`BRK && insn1a[23:21]==3'd0 && insn1a[7:6]==2'b00)
		insn1 <= {8'd1,3'd0,4'b0,1'b0,`FLT_PRIV,2'b00,`BRK};
	else
		insn1 <= ic1_fault[1] ? `INSN_FLT_IBE : ic1_fault[0] ? `INSN_FLT_EXF : insn1a;
end
else
	insn1 <= `NOP_INSN;
end
if (`WAYS > 2) begin
always @*
if (freezePC && !thread_en)
	insn2 <= {8'd0,3'd0,irq_i,1'b0,vec_i,2'b00,`BRK};
else if (phit) begin
	if (insn2a[`INSTRUCTION_OP]==`BRK && insn1a[23:21]==3'd0 && insn2a[7:6]==2'b00)
		insn2 <= {8'd1,3'd0,4'b0,1'b0,`FLT_PRIV,2'b00,`BRK};
	else
		insn2 <= ic2_fault[1] ? `INSN_FLT_IBE : ic2_fault[0] ? `INSN_FLT_EXF : insn2a;
end
else
	insn2 <= `NOP_INSN;
end
end
endgenerate

wire [63:0] dc0_out, dc1_out, dc2_out;
assign rdat0 = dram0_unc ? xdati : dc0_out;
assign rdat1 = dram1_unc ? xdati : dc1_out;
assign rdat2 = dram2_unc ? xdati : dc2_out;

reg preload;
reg [1:0] dccnt;
wire dhit0, dhit1, dhit2;
wire dhit0a, dhit1a, dhit2a;
wire dhit00, dhit10, dhit20;
wire dhit01, dhit11, dhit21;
reg [`ABITS] dc_wadr;
reg [63:0] dc_wdat;
reg isStore;

// If the data is in the write buffer, give the buffer a chance to
// write out the data before trying to load from the cache.
reg wb_hit0, wb_hit1, wb_hit2;
always @*
begin
	wb_hit0 <= FALSE;
	wb_hit1 <= FALSE;
	wb_hit2 <= FALSE;
	for (n = 0; n < `WB_DEPTH; n = n + 1) begin
		if (wb_v[n] && wb_addr[n][31:3]==dram0_addr[31:3])
			wb_hit0 <= TRUE;
		if (`NUM_MEM > 1 && wb_v[n] && wb_addr[n][31:3]==dram1_addr[31:3])
			wb_hit1 <= TRUE;
		if (`NUM_MEM > 2 && wb_v[n] && wb_addr[n][31:3]==dram2_addr[31:3])
			wb_hit2 <= TRUE;
	end
end

assign dhit0 = dhit0a & !wb_hit0;
assign dhit1 = dhit1a & !wb_hit1;
assign dhit2 = dhit2a & !wb_hit2;
wire whit0, whit1, whit2;

wire wr_dcache0 = (bstate==B_DCacheLoadAck && ack_i)||(((bstate==B_StoreAck && StoreAck1) || (bstate==B19 && isStore)) && whit0);
wire wr_dcache1 = (bstate==B_DCacheLoadAck && ack_i)||(((bstate==B_StoreAck && StoreAck1) || (bstate==B19 && isStore)) && whit1);
wire wr_dcache2 = (bstate==B_DCacheLoadAck && ack_i)||(((bstate==B_StoreAck && StoreAck1) || (bstate==B19 && isStore)) && whit2);

FT64_dcache udc0
(
  .rst(rst),
  .wclk(clk),
  .dce(dce),
  .wr(wr_dcache0),
  .sel(sel_o),
  .wadr({pcr[5:0],vadr}),
  .whit(whit0),
  .i((bstate==B_DCacheLoadAck) ? dat_i : dat_o),
  .rclk(clk),
  .rdsize(dram0_memsize),
  .radr({pcr[5:0],dram0_addr}),
  .o(dc0_out),
  .rhit(dhit0a)
);
generate begin : gDCacheInst
if (`NUM_MEM > 1) begin
FT64_dcache udc1
(
  .rst(rst),
  .wclk(clk),
  .dce(dce),
  .wr(wr_dcache1),
  .sel(sel_o),
  .wadr({pcr[5:0],vadr}),
  .whit(whit1),
  .i((bstate==B_DCacheLoadAck) ? dat_i : dat_o),
  .rclk(clk),
  .rdsize(dram1_memsize),
  .radr({pcr[5:0],dram1_addr}),
  .o(dc1_out),
  .rhit(dhit1a)
);
end
if (`NUM_MEM > 2) begin
FT64_dcache udc2
(
  .rst(rst),
  .wclk(clk),
  .dce(dce),
  .wr(wr_dcache2),
  .sel(sel_o),
  .wadr({pcr[5:0],vadr}),
  .whit(whit2),
  .i((bstate==B_DCacheLoadAck) ? dat_i : dat_o),
  .rclk(clk),
  .rdsize(dram2_memsize),
  .radr({pcr[5:0],dram2_addr}),
  .o(dc2_out),
  .rhit(dhit2a)
);
end
end
endgenerate

`ifdef SUPPORT_SMT
function [RBIT:0] fnRa;
input [47:0] isn;
input [5:0] vqei;
input [5:0] vli;
input thrd;
case(isn[`INSTRUCTION_OP])
`IVECTOR:
	case(isn[`INSTRUCTION_S2])
        `VCIDX,`VSCAN:  fnRa = {6'd0,1'b1,isn[`INSTRUCTION_RA]};
        `VMxx:
        	case(isn[25:23])
        	`VMAND,`VMOR,`VMXOR,`VMXNOR,`VMPOP,`VMFIRST,`VMLAST:
                    fnRa = {6'h3F,1'b1,2'b0,isn[8:6]};
            `VMFILL:fnRa = {6'd0,1'b1,isn[`INSTRUCTION_RA]};
            default:fnRa = {6'h3F,1'b1,2'b0,isn[8:6]};
            endcase
        `VSHLV:     fnRa = (vqei+1+isn[15:11] >= vli) ? 11'h000 : {vli-vqei-isn[15:11]-1,1'b1,isn[`INSTRUCTION_RA]};
        `VSHRV:     fnRa = (vqei+isn[15:11] >= vli) ? 11'h000 : {vqei+isn[15:11],1'b1,isn[`INSTRUCTION_RA]};
        `VSxx,`VSxxU,`VSxxS,`VSxxSU:    fnRa = {vqei,1'b1,isn[`INSTRUCTION_RA]};
        default:    fnRa = {vqei,1'b1,isn[`INSTRUCTION_RA]};
        endcase
`R2:    casez(isn[`INSTRUCTION_S2])
		`MOV:
			case(isn[25:23])
			3'd0:	fnRa = {rgs[thrd],1'b0,isn[`INSTRUCTION_RA]};
			3'd1:	fnRa = {isn[26],isn[22:18],1'b0,isn[`INSTRUCTION_RA]};
			3'd2:	fnRa = {rgs[thrd],1'b0,isn[`INSTRUCTION_RA]};
			3'd3:	fnRa = {rs_stack[thrd][5:0],1'b0,isn[`INSTRUCTION_RA]};
			3'd4:	fnRa = {rgs[thrd],1'b0,isn[`INSTRUCTION_RA]};
			3'd5:	fnRa = {fp_rgs[thrd],1'b0,isn[`INSTRUCTION_RA]};
			3'd6:	fnRa = {fp_rgs[thrd],1'b0,isn[`INSTRUCTION_RA]};
			default:fnRa = {rgs[thrd],1'b0,isn[`INSTRUCTION_RA]};
			endcase
        `VMOV:
            case (isn[`INSTRUCTION_S1])
            5'h0:   fnRa = {rgs[thrd],1'b0,isn[`INSTRUCTION_RA]};
            5'h1:   fnRa = {6'h3F,1'b1,isn[`INSTRUCTION_RA]};
            endcase
        default:    fnRa = {rgs[thrd],1'b0,isn[`INSTRUCTION_RA]};
        endcase
`FLOAT:		fnRa = {fp_rgs[thrd],1'b0,isn[`INSTRUCTION_RA]};
default:    fnRa = {rgs[thrd],1'b0,isn[`INSTRUCTION_RA]};
endcase
endfunction

function [RBIT:0] fnRb;
input [47:0] isn;
input fb;
input [5:0] vqei;
input [5:0] rfoa0i;
input [5:0] rfoa1i;
input thrd;
case(isn[`INSTRUCTION_OP])
`R2:        case(isn[`INSTRUCTION_S2])
            `VEX:       fnRb = fb ? {rfoa1i,1'b1,isn[`INSTRUCTION_RB]} : {rfoa0i,1'b1,isn[`INSTRUCTION_RB]};
            `LVX,`SVX:  fnRb = {vqei,1'b1,isn[`INSTRUCTION_RB]};
            default:    fnRb = {rgs[thrd],1'b0,isn[`INSTRUCTION_RB]};
            endcase
`IVECTOR:
			case(isn[`INSTRUCTION_S2])
			`VMxx:
				case(isn[25:23])
            	`VMAND,`VMOR,`VMXOR,`VMXNOR,`VMPOP:
                	fnRb = {6'h3F,1'b1,2'b0,isn[20:18]};
                default:	fnRb = 12'h000;
            	endcase
            `VXCHG:     fnRb = {vqei,1'b1,isn[`INSTRUCTION_RB]};
            `VSxx,`VSxxU:   fnRb = {vqei,1'b1,isn[`INSTRUCTION_RB]};
        	`VSxxS,`VSxxSU:    fnRb = {vqei,1'b0,isn[`INSTRUCTION_RB]};
            `VADDS,`VSUBS,`VMULS,`VANDS,`VORS,`VXORS,`VXORS:
                fnRb = {rgs[thrd],1'b0,isn[`INSTRUCTION_RB]};
            `VSHL,`VSHR,`VASR:
                fnRb = {isn[25],isn[22]}==2'b00 ? {rgs[thrd],1'b0,isn[`INSTRUCTION_RB]} : {vqei,1'b1,isn[`INSTRUCTION_RB]};
            default:    fnRb = {vqei,1'b1,isn[`INSTRUCTION_RB]};
            endcase
`FLOAT:		fnRb = {fp_rgs[thrd],1'b0,isn[`INSTRUCTION_RB]};
default:    fnRb = {rgs[thrd],1'b0,isn[`INSTRUCTION_RB]};
endcase
endfunction

function [RBIT:0] fnRc;
input [47:0] isn;
input [5:0] vqei;
input thrd;
case(isn[`INSTRUCTION_OP])
`R2:	fnRc = {rgs[thrd],1'b0,isn[`INSTRUCTION_RC]};
`MEMNDX:	fnRc = {rgs[thrd],1'b0,isn[`INSTRUCTION_RC]};	// SVX not implemented
`IVECTOR:
			case(isn[`INSTRUCTION_S2])
            `VSxx,`VSxxS,`VSxxU,`VSxxSU:    fnRc = {6'h3F,1'b1,2'b0,isn[25:23]};
            default:    fnRc = {vqei,1'b1,isn[`INSTRUCTION_RC]};
            endcase
`FLOAT:		fnRc = {fp_rgs[thrd],1'b0,isn[`INSTRUCTION_RC]};
default:    fnRc = {rgs[thrd],1'b0,isn[`INSTRUCTION_RC]};
endcase
endfunction

function [RBIT:0] fnRt;
input [47:0] isn;
input [5:0] vqei;
input [5:0] vli;
input thrd;
casez(isn[`INSTRUCTION_OP])
`IVECTOR:
		case(isn[`INSTRUCTION_S2])
		`VMxx:
			case(isn[25:23])
        	`VMAND,`VMOR,`VMXOR,`VMXNOR,`VMFILL:
                    fnRt = {6'h3F,1'b1,2'b0,isn[15:13]};
            `VMPOP:	fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
            default:
                    fnRt = {6'h3F,1'b1,2'b0,isn[15:13]};
            endcase
        `VSxx,`VSxxU,`VSxxS,`VSxxSU:    fnRt = {6'h3F,1'b1,2'b0,isn[15:13]};
        `VSHLV:     fnRt = (vqei+1 >= vli) ? 11'h000 : {vli-vqei-1,1'b1,isn[`INSTRUCTION_RT]};
        `VSHRV:     fnRt = (vqei >= vli) ? 11'h000 : {vqei,1'b1,isn[`INSTRUCTION_RT]};
        `VEINS:     fnRt = {vqei,1'b1,isn[`INSTRUCTION_RT]};	// ToDo: add element # from Ra
        `V2BITS:    fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
        default:    fnRt = {vqei,1'b1,isn[`INSTRUCTION_Rt]};
        endcase
       
`R2:
	if (isn[`INSTRUCTION_L2]==2'b01)
		case(isn[47:42])
	  `CMOVEZ:    fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
  	`CMOVNZ:    fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
  	default:		fnRt = 12'd0;
		endcase
	else
    casez(isn[`INSTRUCTION_S2])
		`MOV:
			case(isn[25:23])
			3'd0:	fnRt = {isn[26],isn[22:18],1'b0,isn[`INSTRUCTION_RT]};
			3'd1:	fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
			3'd2:	fnRt = {rs_stack[thrd][5:0],1'b0,isn[`INSTRUCTION_RT]};
			3'd3:	fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
			3'd4:	fnRt = {fp_rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
			3'd5:	fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
			3'd6:	fnRt = {fp_rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
			default:fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
			endcase
        `VMOV:
            case (isn[`INSTRUCTION_S1])
            5'h0:   fnRt = {6'h3F,1'b1,isn[`INSTRUCTION_RT]};
            5'h1:   fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
            default:	fnRt = 12'h000;
            endcase
        `R1:    
        	case(isn[22:18])
        	`CNTLO,`CNTLZ,`CNTPOP,`ABS,`NOT,`REDOR,`ZXB,`ZXC,`ZXH,`SXB,`SXC,`SXH:
        		fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
        	`MEMDB,`MEMSB,`SYNC:
        		fnRt = 12'd0;
        	default:	fnRt = 12'd0;
        	endcase
        `CMOVEZ:    fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
        `CMOVNZ:    fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
        `MUX:       fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
        `MIN:       fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
        `MAX:       fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
        `LVX:       fnRt = {vqei,1'b1,isn[20:16]};
        `SHIFTR:	fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
        `SHIFT31,`SHIFT63:
        			fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
        `SEI:		fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
        `WAIT,`RTI,`CHK:
    			fnRt = 12'd0;
    		default:    fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
        endcase
`MEMNDX:
	begin
		if (!isn[31])
			case({isn[31:28],isn[22:21]})
			`LVX,
			`CACHEX,
			`LVBX,`LVBUX,`LVCX,`LVCUX,`LVHX,`LVHUX,`LVWX,
			`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LWRX:
				fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
			default: fnRt = 12'd0;
			endcase
		else
			case({isn[31:28],isn[17:16]})
			`PUSH:	fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
		  `SBX,`SCX,`SHX,`SWX,`SWCX,`CACHEX:
		  			fnRt = 12'd0;
		  default:    fnRt = 12'd0;
		  endcase
	end
`FLOAT:
		case(isn[31:26])
		`FTX,`FCX,`FEX,`FDX,`FRM:
					fnRt = 12'd0;
		`FSYNC:		fnRt = 12'd0;
		default:	fnRt = {fp_rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
		endcase
`BRK:	fnRt = 12'd0;
`REX:	fnRt = 12'd0;
`CHK:	fnRt = 12'd0;
`EXEC:	fnRt = 12'd0;
`Bcc:   fnRt = 12'd0;
`BBc:   fnRt = 12'd0;
`NOP:  fnRt = 12'd0;
`BEQI:  fnRt = 12'd0;
`SB,`Sx,`SWC,`CACHE:
		fnRt = 12'd0;
`JMP:	fnRt = 12'd0;
`CALL:  fnRt = {rgs[thrd],1'b0,5'd29};	// regLR
`LV:    fnRt = {vqei,1'b1,isn[`INSTRUCTION_RT]};
`AMO:	fnRt = isn[31] ? {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]} : {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
`AUIPC,`LUI:	fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
default:    fnRt = {rgs[thrd],1'b0,isn[`INSTRUCTION_RT]};
endcase
endfunction
`else
function [RBIT:0] fnRa;
input [47:0] isn;
input [5:0] vqei;
input [5:0] vli;
input thrd;
case(isn[`INSTRUCTION_OP])
`IVECTOR:
	case(isn[`INSTRUCTION_S2])
  `VCIDX,`VSCAN:  fnRa = {6'd0,1'b1,isn[`INSTRUCTION_RA]};
  `VMxx:
  	case(isn[25:23])
  	`VMAND,`VMOR,`VMXOR,`VMXNOR,`VMPOP,`VMFIRST,`VMLAST:
              fnRa = {6'h3F,1'b1,2'b0,isn[8:6]};
      `VMFILL:fnRa = {6'd0,1'b1,isn[`INSTRUCTION_RA]};
      default:fnRa = {6'h3F,1'b1,2'b0,isn[8:6]};
      endcase
  `VSHLV:     fnRa = (vqei+1+isn[15:11] >= vli) ? 11'h000 : {vli-vqei-isn[15:11]-1,1'b1,isn[`INSTRUCTION_RA]};
  `VSHRV:     fnRa = (vqei+isn[15:11] >= vli) ? 11'h000 : {vqei+isn[15:11],1'b1,isn[`INSTRUCTION_RA]};
  `VSxx,`VSxxU,`VSxxS,`VSxxSU:    fnRa = {vqei,1'b1,isn[`INSTRUCTION_RA]};
  default:    fnRa = {vqei,1'b1,isn[`INSTRUCTION_RA]};
  endcase
`R2:
	casez(isn[`INSTRUCTION_S2])
	`MOV:
		case(isn[25:23])
		3'd0:	fnRa = {rgs,1'b0,isn[`INSTRUCTION_RA]};
		3'd1:	fnRa = {isn[26],isn[22:18],1'b0,isn[`INSTRUCTION_RA]};
		3'd2:	fnRa = {rgs,1'b0,isn[`INSTRUCTION_RA]};
		3'd3:	fnRa = {rs_stack[5:0],1'b0,isn[`INSTRUCTION_RA]};
		3'd4:	fnRa = {rgs,1'b0,isn[`INSTRUCTION_RA]};
		3'd5:	fnRa = {fp_rgs,1'b0,isn[`INSTRUCTION_RA]};
		3'd6:	fnRa = {fp_rgs,1'b0,isn[`INSTRUCTION_RA]};
		default:fnRa = {rgs,1'b0,isn[`INSTRUCTION_RA]};
		endcase
  `VMOV:
    case (isn[`INSTRUCTION_S1])
    5'h0:   fnRa = {rgs,1'b0,isn[`INSTRUCTION_RA]};
    5'h1:   fnRa = {6'h3F,1'b1,isn[`INSTRUCTION_RA]};
    default:	fnRa = {rgs,1'b0,isn[`INSTRUCTION_RA]};
    endcase
  default:    fnRa = {rgs,1'b0,isn[`INSTRUCTION_RA]};
  endcase
`FLOAT:		fnRa = {fp_rgs,1'b0,isn[`INSTRUCTION_RA]};
default:    fnRa = {rgs,1'b0,isn[`INSTRUCTION_RA]};
endcase
endfunction

function [RBIT:0] fnRb;
input [47:0] isn;
input fb;
input [5:0] vqei;
input [5:0] rfoa0i;
input [5:0] rfoa1i;
input thrd;
case(isn[`INSTRUCTION_OP])
`RR:        case(isn[`INSTRUCTION_S2])
            `VEX:       fnRb = fb ? {rfoa1i,1'b1,isn[`INSTRUCTION_RB]} : {rfoa0i,1'b1,isn[`INSTRUCTION_RB]};
            `LVX,`SVX:  fnRb = {vqei,1'b1,isn[`INSTRUCTION_RB]};
            default:    fnRb = {rgs,1'b0,isn[`INSTRUCTION_RB]};
            endcase
`IVECTOR:
			case(isn[`INSTRUCTION_S2])
			`VMxx:
				case(isn[25:23])
            	`VMAND,`VMOR,`VMXOR,`VMXNOR,`VMPOP:
                	fnRb = {6'h3F,1'b1,2'b0,isn[20:18]};
                default:	fnRb = 12'h000;
            	endcase
            `VXCHG:     fnRb = {vqei,1'b1,isn[`INSTRUCTION_RB]};
            `VSxx,`VSxxU:   fnRb = {vqei,1'b1,isn[`INSTRUCTION_RB]};
        	`VSxxS,`VSxxSU:    fnRb = {vqei,1'b0,isn[`INSTRUCTION_RB]};
            `VADDS,`VSUBS,`VMULS,`VANDS,`VORS,`VXORS,`VXORS:
                fnRb = {rgs,1'b0,isn[`INSTRUCTION_RB]};
            `VSHL,`VSHR,`VASR:
                fnRb = {isn[25],isn[22]}==2'b00 ? {rgs,1'b0,isn[`INSTRUCTION_RB]} : {vqei,1'b1,isn[`INSTRUCTION_RB]};
            default:    fnRb = {vqei,1'b1,isn[`INSTRUCTION_RB]};
            endcase
`FLOAT:		fnRb = {fp_rgs,1'b0,isn[`INSTRUCTION_RB]};
default:    fnRb = {rgs,1'b0,isn[`INSTRUCTION_RB]};
endcase
endfunction

function [RBIT:0] fnRc;
input [47:0] isn;
input [5:0] vqei;
input thrd;
case(isn[`INSTRUCTION_OP])
`R2:	fnRc = {rgs,1'b0,isn[`INSTRUCTION_RC]};
`MEMNDX:	fnRc = {rgs,1'b0,isn[`INSTRUCTION_RC]};	// SVX not implemented
`IVECTOR:
			case(isn[`INSTRUCTION_S2])
            `VSxx,`VSxxS,`VSxxU,`VSxxSU:    fnRc = {6'h3F,1'b1,2'b0,isn[25:23]};
            default:    fnRc = {vqei,1'b1,isn[`INSTRUCTION_RC]};
            endcase
`FLOAT:		fnRc = {fp_rgs,1'b0,isn[`INSTRUCTION_RC]};
default:    fnRc = {rgs,1'b0,isn[`INSTRUCTION_RC]};
endcase
endfunction

function [RBIT:0] fnRt;
input [47:0] isn;
input [5:0] vqei;
input [5:0] vli;
input thrd;
casez(isn[`INSTRUCTION_OP])
`IVECTOR:
		case(isn[`INSTRUCTION_S2])
		`VMxx:
			case(isn[25:23])
        	`VMAND,`VMOR,`VMXOR,`VMXNOR,`VMFILL:
                    fnRt = {6'h3F,1'b1,2'b0,isn[15:13]};
            `VMPOP:	fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
            default:
                    fnRt = {6'h3F,1'b1,2'b0,isn[15:13]};
            endcase
        `VSxx,`VSxxU,`VSxxS,`VSxxSU:    fnRt = {6'h3F,1'b1,2'b0,isn[15:13]};
        `VSHLV:     fnRt = (vqei+1 >= vli) ? 11'h000 : {vli-vqei-1,1'b1,isn[`INSTRUCTION_RT]};
        `VSHRV:     fnRt = (vqei >= vli) ? 11'h000 : {vqei,1'b1,isn[`INSTRUCTION_RT]};
        `VEINS:     fnRt = {vqei,1'b1,isn[`INSTRUCTION_RT]};	// ToDo: add element # from Ra
        `V2BITS:    fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
        default:    fnRt = {vqei,1'b1,isn[`INSTRUCTION_RT]};
        endcase
       
`FVECTOR:
		case(isn[`INSTRUCTION_S2])
		`VMxx:
			case(isn[25:23])
        	`VMAND,`VMOR,`VMXOR,`VMXNOR,`VMFILL:
                    fnRt = {6'h3F,1'b1,2'b0,isn[15:13]};
            `VMPOP:	fnRt = {rgs,1'b0,isn[`INSTRUCTION_RB]};
            default:
                    fnRt = {6'h3F,1'b1,2'b0,isn[15:13]};
            endcase
        `VSxx,`VSxxU,`VSxxS,`VSxxSU:    fnRt = {6'h3F,1'b1,2'b0,isn[15:13]};
        `VSHLV:     fnRt = (vqei+1 >= vli) ? 11'h000 : {vli-vqei-1,1'b1,isn[`INSTRUCTION_RT]};
        `VSHRV:     fnRt = (vqei >= vli) ? 11'h000 : {vqei,1'b1,isn[`INSTRUCTION_RT]};
        `VEINS:     fnRt = {vqei,1'b1,isn[`INSTRUCTION_RT]};	// ToDo: add element # from Ra
        `V2BITS:    fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
        default:    fnRt = {vqei,1'b1,isn[`INSTRUCTION_RT]};
        endcase
       
`R2:
	if (isn[`INSTRUCTION_L2]==2'b01)
		case(isn[47:42])
	  `CMOVEZ:    fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
  	`CMOVNZ:    fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
  	default:		fnRt = 12'd0;
		endcase
	else
	casez(isn[`INSTRUCTION_S2])
	`MOV:
		case(isn[25:23])
		3'd0:	fnRt = {isn[26],isn[22:18],1'b0,isn[`INSTRUCTION_RT]};
		3'd1:	fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
		3'd2:	fnRt = {rs_stack[5:0],1'b0,isn[`INSTRUCTION_RT]};
		3'd3:	fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
		3'd4:	fnRt = {fp_rgs,1'b0,isn[`INSTRUCTION_RT]};
		3'd5:	fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
		3'd6:	fnRt = {fp_rgs,1'b0,isn[`INSTRUCTION_RT]};
		default:fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
		endcase
  `VMOV:
    case (isn[`INSTRUCTION_S1])
    5'h0:   fnRt = {6'h3F,1'b1,isn[`INSTRUCTION_RT]};
    5'h1:   fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
    default:	fnRt = 12'h000;
    endcase
  `R1:    
  	case(isn[22:18])
  	`CNTLO,`CNTLZ,`CNTPOP,`ABS,`NOT,`REDOR,`ZXB,`ZXC,`ZXH,`SXB,`SXC,`SXH:
  		fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
  	`MEMDB,`MEMSB,`SYNC:
  		fnRt = 12'd0;
  	default:	fnRt = 12'd0;
  	endcase
  `MUX:       fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
  `MIN:       fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
  `MAX:       fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
  `LVX:       fnRt = {vqei,1'b1,isn[`INSTRUCTION_RT]};
  `SHIFTR:	fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
  `SHIFT31,`SHIFT63:
  			fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
  `SEI:		fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
  `WAIT,`RTI,`CHK:
  			fnRt = 12'd0;
  default:    fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
  endcase
`MEMNDX:
	begin
		if (!isn[31])
			case({isn[31:28],isn[22:21]})
			`LVX,
			`CACHEX,
			`LVBX,`LVBUX,`LVCX,`LVCUX,`LVHX,`LVHUX,`LVWX,
			`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LWRX:
				fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
			default: fnRt = 12'd0;
			endcase
		else
			case({isn[31:28],isn[17:16]})
			`PUSH:	fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
		  `SBX,`SCX,`SHX,`SWX,`SWCX,`CACHEX:
		  			fnRt = 12'd0;
		  default:    fnRt = 12'd0;
		  endcase
	end
`FLOAT:
		case(isn[31:26])
		`FTX,`FCX,`FEX,`FDX,`FRM:
					fnRt = 12'd0;
		`FSYNC:		fnRt = 12'd0;
		default:	fnRt = {fp_rgs,1'b0,isn[`INSTRUCTION_RT]};
		endcase
`BRK:	fnRt = 12'd0;
`REX:	fnRt = 12'd0;
`CHK:	fnRt = 12'd0;
`EXEC:	fnRt = 12'd0;
`Bcc:   fnRt = 12'd0;
`BBc:	fnRt = 12'd0;
`NOP:  fnRt = 12'd0;
`BEQI:  fnRt = 12'd0;
`SB,`Sx,`SWC,`CACHE:
		fnRt = 12'd0;
`JMP:	fnRt = 12'd0;
`CALL:  fnRt = {rgs,1'b0,5'd29};	// regLR
`LV:    fnRt = {vqei,1'b1,isn[`INSTRUCTION_RT]};
`AMO:	fnRt = isn[31] ? {rgs,1'b0,isn[`INSTRUCTION_RT]} : {rgs,1'b0,isn[`INSTRUCTION_RT]};
`AUIPC,`LUI:	fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
default:    fnRt = {rgs,1'b0,isn[`INSTRUCTION_RT]};
endcase
endfunction
`endif

// Determines which lanes of the target register get updated.
// Duh, all the lanes.
function [7:0] fnWe;
input [47:0] isn;
fnWe = 8'hFF;
/*
casez(isn[`INSTRUCTION_OP])
`R2:
	case(isn[`INSTRUCTION_S2])
	`R1:
		case(isn[22:18])
		`ABS,`CNTLZ,`CNTLO,`CNTPOP:
			case(isn[25:23])
			3'b000: fnWe = 8'h01;
			3'b001:	fnWe = 8'h03;
			3'b010:	fnWe = 8'h0F;
			3'b011:	fnWe = 8'hFF;
			default:	fnWe = 8'hFF;
			endcase
		default: fnWe = 8'hFF;
		endcase
	`SHIFT31:	fnWe = (~isn[25] & isn[21]) ? 8'hFF : 8'hFF;
	`SHIFT63:	fnWe = (~isn[25] & isn[21]) ? 8'hFF : 8'hFF;
	`SLT,`SLTU,`SLE,`SLEU,
	`ADD,`SUB,
	`AND,`OR,`XOR,
	`NAND,`NOR,`XNOR,
	`DIV,`DIVU,`DIVSU,
	`MOD,`MODU,`MODSU,
	`MUL,`MULU,`MULSU,
	`MULH,`MULUH,`MULSUH,
	`FXMUL:
		case(isn[25:23])
		3'b000: fnWe = 8'h01;
		3'b001:	fnWe = 8'h03;
		3'b010:	fnWe = 8'h0F;
		3'b011:	fnWe = 8'hFF;
		default:	fnWe = 8'hFF;
		endcase
	default: fnWe = 8'hFF;
	endcase
default:	fnWe = 8'hFF;
endcase
*/
endfunction

// Detect if a source is automatically valid
function Source1Valid;
input [47:0] isn;
casez(isn[`INSTRUCTION_OP])
`BRK:   Source1Valid = isn[16] ? isn[`INSTRUCTION_RA]==5'd0 : TRUE;
`Bcc:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`BBc:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`BEQI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`CHK:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`RR:    case(isn[`INSTRUCTION_S2])
        `SHIFT31:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
        `SHIFT63:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
        `SHIFTR:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
        default:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
        endcase
`MEMNDX:Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`ADDI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SLTI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SLTUI: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SGTI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SGTUI: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`ANDI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`ORI:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`XORI:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`XNORI: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`MULI: 	Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`MULUI: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`MULFI: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`DIVI: 	Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`DIVUI: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`AMO: 	Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LB:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LBU:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`Lx:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LxU:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LWR:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LV:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LVx:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`LVxU:  Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SB:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`Sx:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SWC:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`SV:    Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`INC:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`CAS:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`CACHE: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`JAL:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`RET:   Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`CSRRW: Source1Valid = isn[`INSTRUCTION_RA]==5'd0;
`BITFIELD: 	case(isn[47:44])
	`BFINSI:	Source1Valid = TRUE;
	default:	Source1Valid = isn[`INSTRUCTION_RA]==5'd0 || isn[30]==1'b0;
	endcase
`IVECTOR:
	Source1Valid = FALSE;
default:    Source1Valid = TRUE;
endcase
endfunction
  
function Source2Valid;
input [47:0] isn;
casez(isn[`INSTRUCTION_OP])
`BRK:   Source2Valid = TRUE;
`Bcc:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`BBc:   Source2Valid = TRUE;
`BEQI:  Source2Valid = TRUE;
`CHK:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`R2:    casez(isn[`INSTRUCTION_S2])
				`TLB:				Source2Valid = TRUE;
        `R1:       	Source2Valid = TRUE;
        `MOV:				Source2Valid = TRUE;
        `SHIFTR:   	Source2Valid = isn[25] ? 1'b1 : isn[`INSTRUCTION_RB]==5'd0;
        `SHIFT31:  	Source2Valid = isn[25] ? 1'b1 : isn[`INSTRUCTION_RB]==5'd0;
        `SHIFT63:  	Source2Valid = isn[25] ? 1'b1 : isn[`INSTRUCTION_RB]==5'd0;
        `LVX,`SVX: 	Source2Valid = FALSE;
        default:   	Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
        endcase
`MEMNDX:
	begin
		if (!isn[31])
			case({isn[31:28],isn[22:21]})
			`LVX: Source2Valid = FALSE;
			`CACHEX,
			`LVBX,`LVBUX,`LVCX,`LVCUX,`LVHX,`LVHUX,`LVWX,
			`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LWRX:	Source2Valid = TRUE;
			default:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
			endcase
		else
			case({isn[31:28],isn[17:16]})
			`SVX: Source2Valid = FALSE;
			default:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
			endcase
	end
`ADDI:  Source2Valid = TRUE;
`SLTI:  Source2Valid = TRUE;
`SLTUI: Source2Valid = TRUE;
`SGTI:  Source2Valid = TRUE;
`SGTUI: Source2Valid = TRUE;
`ANDI:  Source2Valid = TRUE;
`ORI:   Source2Valid = TRUE;
`XORI:  Source2Valid = TRUE;
`XNORI: Source2Valid = TRUE;
`MULUI: Source2Valid = TRUE;
`MULFI: Source2Valid = TRUE;
`LB:    Source2Valid = TRUE;
`LBU:   Source2Valid = TRUE;
`Lx:    Source2Valid = TRUE;
`LxU:   Source2Valid = TRUE;
`LWR:   Source2Valid = TRUE;
`LVx:   Source2Valid = TRUE;
`LVxU:  Source2Valid = TRUE;
`INC:		Source2Valid = TRUE;
`SB:    Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`Sx:    Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`SWC:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`CAS:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`JAL:   Source2Valid = TRUE;
`RET:   Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
`IVECTOR:
		    case(isn[`INSTRUCTION_S2])
        `VABS:  Source2Valid = TRUE;
        `VMAND,`VMOR,`VMXOR,`VMXNOR,`VMPOP:
            Source2Valid = FALSE;
        `VADDS,`VSUBS,`VANDS,`VORS,`VXORS:
            Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
        `VBITS2V:   Source2Valid = TRUE;
        `V2BITS:    Source2Valid = isn[`INSTRUCTION_RB]==5'd0;
        `VSHL,`VSHR,`VASR:  Source2Valid = isn[22:21]==2'd2;
        default:    Source2Valid = FALSE;
        endcase
`LV:        Source2Valid = TRUE;
`SV:        Source2Valid = FALSE;
`AMO:		Source2Valid = isn[31] || isn[`INSTRUCTION_RB]==5'd0;
`BITFIELD: 	Source2Valid = isn[`INSTRUCTION_RB]==5'd0 || isn[31]==1'b0;
default:    Source2Valid = TRUE;
endcase
endfunction

function Source3Valid;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`IVECTOR:
    case(isn[`INSTRUCTION_S2])
    `VEX:       Source3Valid = TRUE;
    default:    Source3Valid = TRUE;
    endcase
`CHK:   Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
`R2:
	if (isn[`INSTRUCTION_L2]==2'b01)
		case(isn[47:42])
    `CMOVEZ,`CMOVNZ:  Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
		default:	Source3Valid = TRUE;
		endcase
	else
    case(isn[`INSTRUCTION_S2])
    `MAJ:		Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
    default:    Source3Valid = TRUE;
    endcase
`MEMNDX:
		if (!isn[31])
			case({isn[31:28],isn[22:21]})
			`CACHEX,
			`LVBX,`LVBUX,`LVCX,`LVCUX,`LVHX,`LVHUX,`LVWX,
			`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LWRX:
				Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
	    default:    Source3Valid = TRUE;
			endcase
		else
	    case({isn[31:28],isn[17:16]})
	    `PUSH:	Source3Valid = TRUE;
	    `SBX:   Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
	    `SCX:   Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
	    `SHX:   Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
	    `SWX:   Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
	    `SWCX:  Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
	    `CASX:  Source3Valid = isn[`INSTRUCTION_RC]==5'd0;
	    default:    Source3Valid = TRUE;
	    endcase
`BITFIELD: 	Source3Valid = isn[`INSTRUCTION_RC]==5'd0 || isn[32]==1'b0;
default:    Source3Valid = TRUE;
endcase
endfunction

// Used to indicate to the queue logic that the instruction needs to be
// recycled to the queue VL number of times.
function IsVector;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
  case(isn[`INSTRUCTION_S2])
  `LVX,`SVX:  IsVector = TRUE;
  default:    IsVector = FALSE;
  endcase
`IVECTOR:
	case(isn[`INSTRUCTION_S2])
	`VMxx:
		case(isn[25:23])
  	`VMAND,`VMOR,`VMXOR,`VMXNOR,`VMPOP:
              IsVector = FALSE;
    default:	IsVector = TRUE;
    endcase
  `VEINS:     IsVector = FALSE;
  `VEX:       IsVector = FALSE;
  default:    IsVector = TRUE;
  endcase
`LV,`SV:    IsVector = TRUE;
default:    IsVector = FALSE;
endcase
endfunction

function IsVeins;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`IVECTOR:   IsVeins = isn[`INSTRUCTION_S2]==`VEINS;
default:    IsVeins = FALSE;
endcase
endfunction

function IsVex;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`IVECTOR:   IsVex = isn[`INSTRUCTION_S2]==`VEX;
default:    IsVex = FALSE;
endcase
endfunction

function IsVCmprss;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`IVECTOR:   IsVCmprss = isn[`INSTRUCTION_S2]==`VCMPRSS || isn[`INSTRUCTION_S2]==`VCIDX;
default:    IsVCmprss = FALSE;
endcase
endfunction

function IsVShifti;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`IVECTOR:
		    case(isn[`INSTRUCTION_S2])
            `VSHL,`VSHR,`VASR:
                IsVShifti = {isn[25],isn[22]}==2'd2;
            default:    IsVShifti = FALSE;
            endcase    
default:    IsVShifti = FALSE;
endcase
endfunction

function IsVLS;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
		if (IsLoad(isn))
	    case({isn[31:28],isn[22:21]})
	    `LVX,`LVWS:  IsVLS = TRUE;
	    default:    IsVLS = FALSE;
	    endcase
    else
	    case({isn[31:28],isn[17:16]})
	    `SVX,`SVWS:  IsVLS = TRUE;
	    default:    IsVLS = FALSE;
	    endcase
`LV,`SV:    IsVLS = TRUE;
default:    IsVLS = FALSE;
endcase
endfunction

function [1:0] fnM2;
input [31:0] isn;
case(isn[`INSTRUCTION_OP])
`RR:    fnM2 = isn[24:23];
default:    fnM2 = 2'b00;
endcase
endfunction

function [0:0] IsMem;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:	IsMem = TRUE;
`AMO:	IsMem = TRUE;
`LB:    IsMem = TRUE;
`LBU:   IsMem = TRUE;
`Lx:    IsMem = TRUE;
`LxU:   IsMem = TRUE;
`LWR:   IsMem = TRUE;
`LV,`SV:    IsMem = TRUE;
`INC:		IsMem = TRUE;
`SB:    IsMem = TRUE;
`Sx:    IsMem = TRUE;
`SWC:   IsMem = TRUE;
`CAS:   IsMem = TRUE;
`LVx:		IsMem = TRUE;
`LVxU:	IsMem = TRUE;
default:    IsMem = FALSE;
endcase
endfunction

function IsMemNdx;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:	IsMemNdx = TRUE;
default:    IsMemNdx = FALSE;
endcase
endfunction

function IsLoad;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:	IsLoad = !isn[31];
`LB:    IsLoad = TRUE;
`LBU:   IsLoad = TRUE;
`Lx:    IsLoad = TRUE;
`LxU:   IsLoad = TRUE;
`LWR:   IsLoad = TRUE;
`LV:    IsLoad = TRUE;
`LVx:   IsLoad = TRUE;
`LVxU:  IsLoad = TRUE;
default:    IsLoad = FALSE;
endcase
endfunction

function IsInc;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
   	if (isn[`INSTRUCTION_L2]==2'b00)
		case({isn[31:28],isn[17:16]})
    `INC:   IsInc = TRUE;
    default:    IsInc = FALSE;
    endcase
	else
		IsInc = FALSE;
`INC:    IsInc = TRUE;
default:    IsInc = FALSE;
endcase
endfunction

function IsSWC;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
   	if (isn[`INSTRUCTION_L2]==2'b00)
		case({isn[31:28],isn[17:16]})
    `SWCX:   IsSWC = TRUE;
    default:    IsSWC = FALSE;
    endcase
	else
		IsSWC = FALSE;
`SWC:    IsSWC = TRUE;
default:    IsSWC = FALSE;
endcase
endfunction

// Aquire / release bits are only available on indexed SWC / LWR
function IsSWCX;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b00)
		case({isn[31:28],isn[17:16]})
    `SWCX:   IsSWCX = TRUE;
    default:    IsSWCX = FALSE;
    endcase
	else
		IsSWCX = FALSE;
default:    IsSWCX = FALSE;
endcase
endfunction

function IsLWR;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b00)
	    case({isn[31:28],isn[22:21]})
	    `LWRX:   IsLWR = TRUE;
	    default:    IsLWR = FALSE;
	    endcase
	else
		IsLWR = FALSE;
`LWR:    IsLWR = TRUE;
default:    IsLWR = FALSE;
endcase
endfunction

function IsLWRX;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b00)
	    case({isn[31:28],isn[22:21]})
	    `LWRX:   IsLWRX = TRUE;
	    default:    IsLWRX = FALSE;
	    endcase
	else
		IsLWRX = FALSE;
default:    IsLWRX = FALSE;
endcase
endfunction

function IsCAS;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b00)
		case({isn[31:28],isn[17:16]})
    `CASX:   IsCAS = TRUE;
    default:    IsCAS = FALSE;
    endcase
	else
		IsCAS = FALSE;
`CAS:       IsCAS = TRUE;
default:    IsCAS = FALSE;
endcase
endfunction

function IsAMO;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`AMO:       IsAMO = TRUE;
default:    IsAMO = FALSE;
endcase
endfunction

// Really IsPredictableBranch
// Does not include BccR's
function IsBranch;
input [47:0] isn;
casez(isn[`INSTRUCTION_OP])
`Bcc:   IsBranch = TRUE;
`BBc:   IsBranch = TRUE;
`BEQI:  IsBranch = TRUE;
`CHK:   IsBranch = TRUE;
default:    IsBranch = FALSE;
endcase
endfunction

function IsWait;
input [47:0] isn;
IsWait = isn[`INSTRUCTION_OP]==`R2 && isn[`INSTRUCTION_L2]==2'b00 && isn[`INSTRUCTION_S2]==`WAIT;
endfunction

function IsCall;
input [47:0] isn;
IsCall = isn[`INSTRUCTION_OP]==`CALL && isn[7]==1'b0;
endfunction

function IsJmp;
input [47:0] isn;
IsJmp = isn[`INSTRUCTION_OP]==`JMP && isn[7]==1'b0;
endfunction

function IsFlowCtrl;
input [47:0] isn;
casez(isn[`INSTRUCTION_OP])
`BRK:    IsFlowCtrl = TRUE;
`R2:    case(isn[`INSTRUCTION_S2])
        `RTI:   IsFlowCtrl = TRUE;
        default:    IsFlowCtrl = FALSE;
        endcase
`Bcc:   IsFlowCtrl = TRUE;
`BBc:		IsFlowCtrl = TRUE;
`BEQI:  IsFlowCtrl = TRUE;
`CHK:   IsFlowCtrl = TRUE;
`JAL:   IsFlowCtrl = TRUE;
`JMP:		IsFlowCtrl = TRUE;
`CALL:  IsFlowCtrl = TRUE;
`RET:   IsFlowCtrl = TRUE;
default:    IsFlowCtrl = FALSE;
endcase
endfunction

function IsCache;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b00)
	    case({isn[31:28],isn[22:21]})
	    `CACHEX:    IsCache = TRUE;
	    default:    IsCache = FALSE;
	    endcase
	else
		IsCache = FALSE;
`CACHE: IsCache = TRUE;
default: IsCache = FALSE;
endcase
endfunction

function [4:0] CacheCmd;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b00)
	    case({isn[31:28],isn[22:21]})
	    `CACHEX:    CacheCmd = isn[17:13];
	    default:    CacheCmd = 5'd0;
	    endcase
	else
		CacheCmd = 5'd0;
`CACHE: CacheCmd = isn[15:11];
default: CacheCmd = 5'd0;
endcase
endfunction

function IsMemsb;
input [47:0] isn;
IsMemsb = (isn[`INSTRUCTION_OP]==`RR && isn[`INSTRUCTION_L2]==2'b00 && isn[`INSTRUCTION_S2]==`R1 && isn[22:18]==`MEMSB); 
endfunction

function IsSEI;
input [47:0] isn;
IsSEI = (isn[`INSTRUCTION_OP]==`R2 && isn[`INSTRUCTION_L2]==2'b00 && isn[`INSTRUCTION_S2]==`SEI); 
endfunction

function IsLV;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b00)
	    case({isn[31:28],isn[22:21]})
	    `LVX:   IsLV = TRUE;
	    default:    IsLV = FALSE;
	    endcase
	else
		IsLV = FALSE;
`LV:        IsLV = TRUE;
default:    IsLV = FALSE;
endcase
endfunction

function IsRFW;
input [47:0] isn;
input [5:0] vqei;
input [5:0] vli;
input thrd;
if (fnRt(isn,vqei,vli,thrd)==12'd0) 
    IsRFW = FALSE;
else
casez(isn[`INSTRUCTION_OP])
`IVECTOR:   IsRFW = TRUE;
`FVECTOR:   IsRFW = TRUE;
`R2:
	if (isn[`INSTRUCTION_L2]==2'b00)
	    casez(isn[`INSTRUCTION_S2])
	    `TLB:		IsRFW = TRUE;
	    `R1:    IsRFW = TRUE;
	    `ADD:   IsRFW = TRUE;
	    `SUB:   IsRFW = TRUE;
	    `SLT:   IsRFW = TRUE;
	    `SLTU:  IsRFW = TRUE;
	    `SLE:   IsRFW = TRUE;
        `SLEU:  IsRFW = TRUE;
	    `AND:   IsRFW = TRUE;
	    `OR:    IsRFW = TRUE;
	    `XOR:   IsRFW = TRUE;
	    `NAND:	IsRFW = TRUE;
	    `NOR:		IsRFW = TRUE;
	    `XNOR:	IsRFW = TRUE;
	    `MULU:  IsRFW = TRUE;
	    `MULSU: IsRFW = TRUE;
	    `MUL:   IsRFW = TRUE;
	    `MULUH:  IsRFW = TRUE;
	    `MULSUH: IsRFW = TRUE;
	    `MULH:   IsRFW = TRUE;
	    `MULF:	IsRFW = TRUE;
	    `FXMUL:	IsRFW = TRUE;
	    `DIVU:  IsRFW = TRUE;
	    `DIVSU: IsRFW = TRUE;
	    `DIV:IsRFW = TRUE;
	    `MODU:  IsRFW = TRUE;
	    `MODSU: IsRFW = TRUE;
	    `MOD:IsRFW = TRUE;
	    `MOV:	IsRFW = TRUE;
	    `VMOV:	IsRFW = TRUE;
	    `SHIFTR,`SHIFT31,`SHIFT63:
		    	IsRFW = TRUE;
	    `MIN,`MAX:    IsRFW = TRUE;
	    `SEI:	IsRFW = TRUE;
	    default:    IsRFW = FALSE;
	    endcase
	else if (isn[`INSTRUCTION_L2]==2'b01)
		case(isn[47:42])
		`CMOVEZ:	IsRFW = TRUE;
		`CMOVNZ:	IsRFW = TRUE;
		default:	IsRFW = FALSE;
		endcase
	else if (isn[7]==1'b1)
	// The following instructions might come from a compressed version.
	    casez(isn[`INSTRUCTION_S2])
	    `ADD:   IsRFW = TRUE;
	    `SUB:   IsRFW = TRUE;
	    `AND:   IsRFW = TRUE;
	    `OR:    IsRFW = TRUE;
	    `XOR:   IsRFW = TRUE;
	    `MOV:	IsRFW = TRUE;
	    `SHIFTR,`SHIFT31,`SHIFT63:
		    	IsRFW = TRUE;
	    default:    IsRFW = FALSE;
	    endcase
	else
		IsRFW = FALSE;
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b10) begin
		if (!isn[31])
			IsRFW = TRUE;
		else
			case({isn[31:28],isn[17:16]})
			`PUSH:	IsRFW = TRUE;
	    `CASX:  IsRFW = TRUE;
	    default:    IsRFW = FALSE;
	    endcase
	end
	else if (isn[`INSTRUCTION_L2]==2'b00) begin
		if (!isn[31])
	    case({isn[31:28],isn[22:21]})
	    `LBX:   IsRFW = TRUE;
	    `LBUX:  IsRFW = TRUE;
	    `LCX:   IsRFW = TRUE;
	    `LCUX:  IsRFW = TRUE;
	    `LHX:   IsRFW = TRUE;
	    `LHUX:  IsRFW = TRUE;
	    `LWX:   IsRFW = TRUE;
	    `LVBX:  IsRFW = TRUE;
	    `LVBUX: IsRFW = TRUE;
	    `LVCX:  IsRFW = TRUE;
	    `LVCUX: IsRFW = TRUE;
	    `LVHX:  IsRFW = TRUE;
	    `LVHUX: IsRFW = TRUE;
	    `LVWX:  IsRFW = TRUE;
	    `LWRX:  IsRFW = TRUE;
	    `LVX:   IsRFW = TRUE;
	    default:	IsRFW = FALSE;
	    endcase
    else
			case({isn[31:28],isn[17:16]})
			`PUSH:	IsRFW = TRUE;
	    `CASX:  IsRFW = TRUE;
	    default:    IsRFW = FALSE;
	    endcase
	end
	else
		IsRFW = FALSE;
`BBc:	IsRFW = FALSE;
`BITFIELD:  IsRFW = TRUE;
`ADDI:      IsRFW = TRUE;
`SLTI:      IsRFW = TRUE;
`SLTUI:     IsRFW = TRUE;
`SGTI:      IsRFW = TRUE;
`SGTUI:     IsRFW = TRUE;
`ANDI:      IsRFW = TRUE;
`ORI:       IsRFW = TRUE;
`XORI:      IsRFW = TRUE;
`XNORI:			IsRFW = TRUE;
`MULUI:     IsRFW = TRUE;
`MULI:      IsRFW = TRUE;
`MULFI:			IsRFW = TRUE;
`DIVUI:     IsRFW = TRUE;
`DIVI:      IsRFW = TRUE;
`MODI:      IsRFW = TRUE;
`JAL:       IsRFW = TRUE;
`CALL:      IsRFW = TRUE;  
`RET:       IsRFW = TRUE; 
`LB:        IsRFW = TRUE;
`LBU:       IsRFW = TRUE;
`Lx:        IsRFW = TRUE;
`LxU:       IsRFW = TRUE;
`LWR:       IsRFW = TRUE;
`LV:        IsRFW = TRUE;
`LVx:				IsRFW = TRUE;
`LVxU:			IsRFW = TRUE;
`CAS:       IsRFW = TRUE;
`AMO:				IsRFW = TRUE;
`CSRRW:			IsRFW = TRUE;
`AUIPC:			IsRFW = TRUE;
`LUI:				IsRFW = TRUE;
default:    IsRFW = FALSE;
endcase
endfunction

function IsShifti;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`R2:
	if (isn[`INSTRUCTION_L2]==2'b00)
	    case(isn[`INSTRUCTION_S2])
	    `SHIFT31,`SHIFT63:
	    	IsShifti = TRUE;
	    default: IsShifti = FALSE;
	    endcase
    else
    	IsShifti = FALSE;
default: IsShifti = FALSE;
endcase
endfunction

function IsRtop;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`R2:
	if (isn[`INSTRUCTION_L2]==2'b01)
	    case(isn[47:42])
	    `RTOP: IsRtop = TRUE;
	    default: IsRtop = FALSE;
	    endcase
    else
    	IsRtop = FALSE;
default: IsRtop = FALSE;
endcase
endfunction

function IsMul;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`R2:
	if (isn[`INSTRUCTION_L2]==2'b00)
    case(isn[`INSTRUCTION_S2])
    `MULU,`MULSU,`MUL: IsMul = TRUE;
    `MULUH,`MULSUH,`MULH: IsMul = TRUE;
    default:    IsMul = FALSE;
    endcase
	else
		IsMul = FALSE;
`MULUI,`MULI:  IsMul = TRUE;
default:    IsMul = FALSE;
endcase
endfunction

function IsDivmod;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`R2:
	if (isn[`INSTRUCTION_L2]==2'b00)
    case(isn[`INSTRUCTION_S2])
    `DIVU,`DIVSU,`DIV: IsDivmod = TRUE;
    `MODU,`MODSU,`MOD: IsDivmod = TRUE;
    default: IsDivmod = FALSE;
    endcase
	else
		IsDivmod = FALSE;
`DIVUI,`DIVI,`MODI:  IsDivmod = TRUE;
default:    IsDivmod = FALSE;
endcase
endfunction

function IsExec;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`EXEC:	IsExec = TRUE;
default:	IsExec = FALSE;
endcase
endfunction

function [7:0] fnSelect;
input [47:0] ins;
input [`ABITS] adr;
begin
	case(ins[`INSTRUCTION_OP])
	`MEMNDX:
		if (ins[`INSTRUCTION_L2]==2'b10) begin
			if (ins[31]) begin
				case({ins[31:28],ins[17:16]})
				`PUSH:	fnSelect = 8'hFF;
				default: fnSelect = 8'h00;
				endcase
			end
			else
				fnSelect = 8'h00;
		end
		else if (ins[`INSTRUCTION_L2]==2'b00) begin
			if (!ins[31])
				case({ins[31:28],ins[22:21]})
				`LBX,`LBUX,`LVBX,`LVBUX:
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
				`LCX,`LCUX,`LVCX,`LVCUX:
				    case(adr[2:1])
				    2'd0:   fnSelect = 8'h03;
				    2'd1:   fnSelect = 8'h0C;
				    2'd2:   fnSelect = 8'h30;
				    2'd3:   fnSelect = 8'hC0;
				    endcase
				`LHX,`LHUX,`LVHX,`LVHUX:
				   case(adr[2])
				   1'b0:    fnSelect = 8'h0F;
				   1'b1:    fnSelect = 8'hF0;
				   endcase
				`INC,`LVWX,
				`LWX,`LWRX,`LVX:
				   fnSelect = 8'hFF;
				default:fnSelect = 8'hFF;
	     	endcase
	    else
				case({ins[31:28],ins[17:16]})
	       `SBX:
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
	        `SCX:
	            case(adr[2:1])
	            2'd0:   fnSelect = 8'h03;
	            2'd1:   fnSelect = 8'h0C;
	            2'd2:   fnSelect = 8'h30;
	            2'd3:   fnSelect = 8'hC0;
	            endcase
	    	`SHX:
	           case(adr[2])
	           1'b0:    fnSelect = 8'h0F;
	           1'b1:    fnSelect = 8'hF0;
	           endcase
	       `INC,
	       `SWX,`SWCX,`SVX,`CASX,`PUSH:
	           fnSelect = 8'hFF;
	       default: fnSelect = 8'h00;
		   endcase
		 end
	   else
	   	fnSelect = 8'h00;
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
  `Lx,`LxU,`LVx,`LVxU:
  	casez(ins[20:18])
  	3'b100:	fnSelect = 8'hFF;
  	3'b?10: fnSelect = adr[2] ? 8'hF0 : 8'h0F;
  	3'b??1:
      case(adr[2:1])
      2'd0:   fnSelect = 8'h03;
      2'd1:   fnSelect = 8'h0C;
      2'd2:   fnSelect = 8'h30;
      2'd3:   fnSelect = 8'hC0;
      endcase
    default: fnSelect = 8'h00;
    endcase
  `Sx:
  	casez(ins[15:13])
  	3'b100:	fnSelect = 8'hFF;
  	3'b?10: fnSelect = adr[2] ? 8'hF0 : 8'h0F;
  	3'b??1:
      case(adr[2:1])
      2'd0:   fnSelect = 8'h03;
      2'd1:   fnSelect = 8'h0C;
      2'd2:   fnSelect = 8'h30;
      2'd3:   fnSelect = 8'hC0;
      endcase
    default: fnSelect = 8'h00;
    endcase
	`INC,
	`LWR,`SWC,`CAS:   fnSelect = 8'hFF;
	`LV,`SV:   fnSelect = 8'hFF;
	`AMO:
		case(ins[23:21])
		3'd0:	fnSelect = {8'h01 << adr[2:0]};
		3'd1:	fnSelect = {8'h03 << {adr[2:1],1'b0}};
		3'd2:	fnSelect = {8'h0F << {adr[2],2'b00}};
		3'd3:	fnSelect = 8'hFF;
		default:	fnSelect = 8'hFF;
		endcase
	default:	fnSelect = 8'h00;
	endcase
end
endfunction
/*
function [63:0] fnDatc;
input [47:0] ins;
input [63:0] dat;
case(ins[`INSTRUCTION_OP])
`R2:
	if (isn[`INSTRUCTION_L2]==2'b01)
		case(ins[47:42])
		`FINDB:		fnDatc = dat[7:0];
		`FINDC:		fnDatc = dat[15:0];
		`FINDH:		fnDatc = dat[31:0];
		`FINDW:		fnDatc = dat[63:0];
		default:	fnDatc = dat[63:0];
		endcase
	else
		fnDatc = dat[63:0];
default:	fnDatc = dat[63:0];
endcase
endfunction
*/
/*
function [63:0] fnMemInc;
input [47:0] ins;
case(ins[`INSTRUCTION_OP])
`R2:
	if (isn[`INSTRUCTION_L2]==2'b01)
		case(ins[47:42])
		`FINDB:		fnMemInc = 32'd1;
		`FINDC:		fnMemInc = 32'd2;
		`FINDH:		fnMemInc = 32'd4;
		`FINDW:		fnMemInc = 32'd8;
		default:	fnMemInc = 32'd8;
		endcase
	else
		fnMemInc = 32'd8;
default:	fnMemInc = 32'd8;
endcase
endfunction
*/
function [63:0] fnDatiAlign;
input [47:0] ins;
input [`ABITS] adr;
input [63:0] dat;
case(ins[`INSTRUCTION_OP])
`MEMNDX:
	if (ins[`INSTRUCTION_L2]==2'b00)
	    case({ins[31:28],ins[22:21]})
	    `LBX,`LVBX:
	        case(adr[2:0])
	        3'd0:   fnDatiAlign = {{56{dat[7]}},dat[7:0]};
	        3'd1:   fnDatiAlign = {{56{dat[15]}},dat[15:8]};
	        3'd2:   fnDatiAlign = {{56{dat[23]}},dat[23:16]};
	        3'd3:   fnDatiAlign = {{56{dat[31]}},dat[31:24]};
	        3'd4:   fnDatiAlign = {{56{dat[39]}},dat[39:32]};
	        3'd5:   fnDatiAlign = {{56{dat[47]}},dat[47:40]};
	        3'd6:   fnDatiAlign = {{56{dat[55]}},dat[55:48]};
	        3'd7:   fnDatiAlign = {{56{dat[63]}},dat[63:56]};
	        endcase
	    `LBUX,`LVBUX:
	        case(adr[2:0])
	        3'd0:   fnDatiAlign = {{56{1'b0}},dat[7:0]};
	        3'd1:   fnDatiAlign = {{56{1'b0}},dat[15:8]};
	        3'd2:   fnDatiAlign = {{56{1'b0}},dat[23:16]};
	        3'd3:   fnDatiAlign = {{56{1'b0}},dat[31:24]};
	        3'd4:   fnDatiAlign = {{56{1'b0}},dat[39:32]};
	        3'd5:   fnDatiAlign = {{56{1'b0}},dat[47:40]};
	        3'd6:   fnDatiAlign = {{56{1'b0}},dat[55:48]};
	        3'd7:   fnDatiAlign = {{56{2'b0}},dat[63:56]};
	        endcase
	    `LCX,`LVCX:
	        case(adr[2:1])
	        2'd0:   fnDatiAlign = {{48{dat[15]}},dat[15:0]};
	        2'd1:   fnDatiAlign = {{48{dat[31]}},dat[31:16]};
	        2'd2:   fnDatiAlign = {{48{dat[47]}},dat[47:32]};
	        2'd3:   fnDatiAlign = {{48{dat[63]}},dat[63:48]};
	        endcase
	    `LCUX,`LVCUX:
	        case(adr[2:1])
	        2'd0:   fnDatiAlign = {{48{1'b0}},dat[15:0]};
	        2'd1:   fnDatiAlign = {{48{1'b0}},dat[31:16]};
	        2'd2:   fnDatiAlign = {{48{1'b0}},dat[47:32]};
	        2'd3:   fnDatiAlign = {{48{1'b0}},dat[63:48]};
	        endcase
	    `LHX,`LVHX:
	        case(adr[2])
	        1'b0:   fnDatiAlign = {{32{dat[31]}},dat[31:0]};
	        1'b1:   fnDatiAlign = {{32{dat[63]}},dat[63:32]};
	        endcase
	    `LHUX,`LVHUX:
	        case(adr[2])
	        1'b0:   fnDatiAlign = {{32{1'b0}},dat[31:0]};
	        1'b1:   fnDatiAlign = {{32{1'b0}},dat[63:32]};
	        endcase
	    `LWX,`LWRX,`LVX,`CAS,`LVWX:  fnDatiAlign = dat;
	    default:    fnDatiAlign = dat;
	    endcase
	else
		fnDatiAlign = dat;
`LB:
  case(adr[2:0])
  3'd0:   fnDatiAlign = {{56{dat[7]}},dat[7:0]};
  3'd1:   fnDatiAlign = {{56{dat[15]}},dat[15:8]};
  3'd2:   fnDatiAlign = {{56{dat[23]}},dat[23:16]};
  3'd3:   fnDatiAlign = {{56{dat[31]}},dat[31:24]};
  3'd4:   fnDatiAlign = {{56{dat[39]}},dat[39:32]};
  3'd5:   fnDatiAlign = {{56{dat[47]}},dat[47:40]};
  3'd6:   fnDatiAlign = {{56{dat[55]}},dat[55:48]};
  3'd7:   fnDatiAlign = {{56{dat[63]}},dat[63:56]};
  endcase
`LBU:
  case(adr[2:0])
  3'd0:   fnDatiAlign = {{56{1'b0}},dat[7:0]};
  3'd1:   fnDatiAlign = {{56{1'b0}},dat[15:8]};
  3'd2:   fnDatiAlign = {{56{1'b0}},dat[23:16]};
  3'd3:   fnDatiAlign = {{56{1'b0}},dat[31:24]};
  3'd4:   fnDatiAlign = {{56{1'b0}},dat[39:32]};
  3'd5:   fnDatiAlign = {{56{1'b0}},dat[47:40]};
  3'd6:   fnDatiAlign = {{56{1'b0}},dat[55:48]};
  3'd7:   fnDatiAlign = {{56{2'b0}},dat[63:56]};
  endcase
`Lx,`LVx:
	casez(ins[20:18])
	3'b100:	fnDatiAlign = dat;
	3'b?10:
	  case(adr[2])
	  1'b0:   fnDatiAlign = {{32{dat[31]}},dat[31:0]};
	  1'b1:   fnDatiAlign = {{32{dat[63]}},dat[63:32]};
	  endcase
	3'b??1:
	  case(adr[2:1])
	  2'd0:   fnDatiAlign = {{48{dat[15]}},dat[15:0]};
	  2'd1:   fnDatiAlign = {{48{dat[31]}},dat[31:16]};
	  2'd2:   fnDatiAlign = {{48{dat[47]}},dat[47:32]};
	  2'd3:   fnDatiAlign = {{48{dat[63]}},dat[63:48]};
	  endcase
	default:	fnDatiAlign = dat;
	endcase
`LxU,`LVxU:
	casez(ins[20:18])
	3'b100:	fnDatiAlign = dat;
	3'b?10:
	  case(adr[2])
	  1'b0:   fnDatiAlign = {{32{1'b0}},dat[31:0]};
	  1'b1:   fnDatiAlign = {{32{1'b0}},dat[63:32]};
	  endcase
	3'b??1:
	  case(adr[2:1])
	  2'd0:   fnDatiAlign = {{48{1'b0}},dat[15:0]};
	  2'd1:   fnDatiAlign = {{48{1'b0}},dat[31:16]};
	  2'd2:   fnDatiAlign = {{48{1'b0}},dat[47:32]};
	  2'd3:   fnDatiAlign = {{48{1'b0}},dat[63:48]};
	  endcase
	default:	fnDatiAlign = dat;
	endcase
`LWR,`LV,`CAS,`AMO:   fnDatiAlign = dat;
default:    fnDatiAlign = dat;
endcase
endfunction

function [63:0] fnDato;
input [47:0] isn;
input [63:0] dat;
case(isn[`INSTRUCTION_OP])
`MEMNDX:
	if (isn[`INSTRUCTION_L2]==2'b00)
		case({isn[31:28],isn[17:16]})
		`SBX:   fnDato = {8{dat[7:0]}};
		`SCX:   fnDato = {4{dat[15:0]}};
		`SHX:   fnDato = {2{dat[31:0]}};
		default:    fnDato = dat;
		endcase
	else
		fnDato = dat;
`SB:   fnDato = {8{dat[7:0]}};
`Sx:
	casez(isn[15:13])
	3'b100:	fnDato = dat;
	3'b?10:	fnDato = {2{dat[31:0]}};
	3'b??1:	fnDato = {4{dat[15:0]}};
	default:	fnDato = dat;
	endcase
`AMO:
	case(isn[23:21])
	3'd0:	fnDato = {8{dat[7:0]}};
	3'd1:	fnDato = {4{dat[15:0]}};
	3'd2:	fnDato = {2{dat[31:0]}};
	3'd3:	fnDato = dat;
	default:	fnDato = dat;
	endcase
default:    fnDato = dat;
endcase
endfunction

function IsTLB;
input [47:0] isn;
case(isn[`INSTRUCTION_OP])
`R2:
  case(isn[`INSTRUCTION_S2])
  `TLB:   IsTLB = TRUE;
  default:    IsTLB = FALSE;
  endcase
default:    IsTLB = FALSE;
endcase
endfunction

// Indicate if the ALU instruction is valid immediately (single cycle operation)
function IsSingleCycle;
input [47:0] isn;
IsSingleCycle = !(IsMul(isn)|IsDivmod(isn)|IsTLB(isn));
endfunction


generate begin : gDecocderInst
for (g = 0; g < QENTRIES; g = g + 1) begin
`ifdef SUPPORT_SMT
decoder8 iq0(.num({iqentry_tgt[g][8:7],iqentry_tgt[g][5:0]}), .out(iq_out[g]));
`else
decoder7 iq0(.num({iqentry_tgt[g][7],iqentry_tgt[g][5:0]}), .out(iq_out[g]));
`endif
end
end
endgenerate

initial begin: Init
	//
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
	message[ `PANIC_ALU0ONLY ] = "ALU0 Only       ";

	for (n = 0; n < 64; n = n + 1)
		codebuf[n] <= 48'h0;

end

// ---------------------------------------------------------------------------
// FETCH
// ---------------------------------------------------------------------------
//
assign fetchbuf0_mem = IsMem(fetchbuf0_instr);// & IsLoad(fetchbuf0_instr);
assign fetchbuf0_rfw   = IsRFW(fetchbuf0_instr,vqe0,vl,fetchbuf0_thrd);

generate begin: gFetchbufDec
if (`WAYS > 1) begin
assign fetchbuf1_mem = IsMem(fetchbuf1_instr);// & IsLoad(fetchbuf1_instr);
assign fetchbuf1_rfw   = IsRFW(fetchbuf1_instr,vqe1,vl,fetchbuf1_thrd);
end
if (`WAYS > 2) begin
assign fetchbuf2_mem = IsMem(fetchbuf2_instr);// & IsLoad(fetchbuf2_instr);
assign fetchbuf2_rfw   = IsRFW(fetchbuf2_instr,vqe2,vl,fetchbuf2_thrd);
end
end
endgenerate

generate begin : gFetchbufInst
if (`WAYS > 2) begin : gb1
FT64_fetchbuf_x3 #(AMSB,RSTPC) ufb1
(
  .rst(rst),
  .clk4x(clk4x),
  .clk(clk),
  .fcu_clk(fcu_clk),
  .cs_i(vadr[31:16]==16'hFFFF),
  .cyc_i(cyc),
  .stb_i(stb_o),
  .ack_o(dc_ack),
  .we_i(we),
  .adr_i(vadr[15:0]),
  .dat_i(dat_o[47:0]),
  .cmpgrp(cr0[10:8]),
  .freezePC(freezePC),
  .regLR(regLR),
  .thread_en(thread_en),
  .insn0(insn0),
  .insn1(insn1),
  .insn1(insn2),
  .phit(phit), 
  .threadx(threadx),
  .branchmiss(branchmiss),
  .misspc(misspc),
  .branchmiss_thrd(branchmiss_thrd),
  .predict_takenA(predict_takenA),
  .predict_takenB(predict_takenB),
  .predict_takenC(predict_takenC),
  .predict_takenD(predict_takenD),
  .predict_takenE(predict_takenE),
  .predict_takenF(predict_takenF),
  .predict_taken0(predict_taken0),
  .predict_taken1(predict_taken1),
  .predict_taken2(predict_taken2),
  .queued1(queued1),
  .queued2(queued2),
  .queued2(queued3),
  .queuedNop(queuedNop),
  .pc0(pc0),
  .pc1(pc1),
  .fetchbuf(fetchbuf),
  .fetchbufA_v(fetchbufA_v),
  .fetchbufB_v(fetchbufB_v),
  .fetchbufC_v(fetchbufC_v),
  .fetchbufD_v(fetchbufD_v),
  .fetchbufD_v(fetchbufE_v),
  .fetchbufD_v(fetchbufF_v),
  .fetchbufA_pc(fetchbufA_pc),
  .fetchbufB_pc(fetchbufB_pc),
  .fetchbufC_pc(fetchbufC_pc),
  .fetchbufD_pc(fetchbufD_pc),
  .fetchbufD_pc(fetchbufE_pc),
  .fetchbufD_pc(fetchbufF_pc),
  .fetchbufA_instr(fetchbufA_instr),
  .fetchbufB_instr(fetchbufB_instr),
  .fetchbufC_instr(fetchbufC_instr),
  .fetchbufD_instr(fetchbufD_instr),
  .fetchbufE_instr(fetchbufE_instr),
  .fetchbufF_instr(fetchbufF_instr),
  .fetchbuf0_instr(fetchbuf0_instr),
  .fetchbuf1_instr(fetchbuf1_instr),
  .fetchbuf0_thrd(fetchbuf0_thrd),
  .fetchbuf1_thrd(fetchbuf1_thrd),
  .fetchbuf2_thrd(fetchbuf2_thrd),
  .fetchbuf0_pc(fetchbuf0_pc),
  .fetchbuf1_pc(fetchbuf1_pc),
  .fetchbuf2_pc(fetchbuf2_pc),
  .fetchbuf0_v(fetchbuf0_v),
  .fetchbuf1_v(fetchbuf1_v),
  .fetchbuf2_v(fetchbuf2_v),
  .fetchbuf0_insln(fetchbuf0_insln),
  .fetchbuf1_insln(fetchbuf1_insln),
  .fetchbuf2_insln(fetchbuf2_insln),
  .codebuf0(codebuf[insn0[21:16]]),
  .codebuf1(codebuf[insn1[21:16]]),
  .codebuf2(codebuf[insn2[21:16]]),
  .btgtA(btgtA),
  .btgtB(btgtB),
  .btgtC(btgtC),
  .btgtD(btgtD),
  .btgtE(btgtE),
  .btgtF(btgtF),
  .nop_fetchbuf(nop_fetchbuf),
  .take_branch0(take_branch0),
  .take_branch1(take_branch1),
  .take_branch2(take_branch2),
  .stompedRets(stompedOnRets),
  .panic(fb_panic)
);
end
else if (`WAYS > 1) begin : gb1
FT64_fetchbuf #(AMSB,RSTPC) ufb1
(
  .rst(rst),
  .clk4x(clk4x),
  .clk(clk),
  .fcu_clk(fcu_clk),
  .cs_i(vadr[31:16]==16'hFFFF),
  .cyc_i(cyc),
  .stb_i(stb_o),
  .ack_o(dc_ack),
  .we_i(we),
  .adr_i(vadr[15:0]),
  .dat_i(dat_o[47:0]),
  .cmpgrp(cr0[10:8]),
  .freezePC(freezePC),
  .regLR(regLR),
  .thread_en(thread_en),
  .insn0(insn0),
  .insn1(insn1),
  .phit(phit), 
  .threadx(threadx),
  .branchmiss(branchmiss),
  .misspc(misspc),
  .branchmiss_thrd(branchmiss_thrd),
  .predict_takenA(predict_takenA),
  .predict_takenB(predict_takenB),
  .predict_takenC(predict_takenC),
  .predict_takenD(predict_takenD),
  .predict_taken0(predict_taken0),
  .predict_taken1(predict_taken1),
  .queued1(queued1),
  .queued2(queued2),
  .queuedNop(queuedNop),
  .pc0(pc0),
  .pc1(pc1),
  .fetchbuf(fetchbuf),
  .fetchbufA_v(fetchbufA_v),
  .fetchbufB_v(fetchbufB_v),
  .fetchbufC_v(fetchbufC_v),
  .fetchbufD_v(fetchbufD_v),
  .fetchbufA_pc(fetchbufA_pc),
  .fetchbufB_pc(fetchbufB_pc),
  .fetchbufC_pc(fetchbufC_pc),
  .fetchbufD_pc(fetchbufD_pc),
  .fetchbufA_instr(fetchbufA_instr),
  .fetchbufB_instr(fetchbufB_instr),
  .fetchbufC_instr(fetchbufC_instr),
  .fetchbufD_instr(fetchbufD_instr),
  .fetchbuf0_instr(fetchbuf0_instr),
  .fetchbuf1_instr(fetchbuf1_instr),
  .fetchbuf0_thrd(fetchbuf0_thrd),
  .fetchbuf1_thrd(fetchbuf1_thrd),
  .fetchbuf0_pc(fetchbuf0_pc),
  .fetchbuf1_pc(fetchbuf1_pc),
  .fetchbuf0_v(fetchbuf0_v),
  .fetchbuf1_v(fetchbuf1_v),
  .fetchbuf0_insln(fetchbuf0_insln),
  .fetchbuf1_insln(fetchbuf1_insln),
  .codebuf0(codebuf[insn0[21:16]]),
  .codebuf1(codebuf[insn1[21:16]]),
  .btgtA(btgtA),
  .btgtB(btgtB),
  .btgtC(btgtC),
  .btgtD(btgtD),
  .nop_fetchbuf(nop_fetchbuf),
  .take_branch0(take_branch0),
  .take_branch1(take_branch1),
  .stompedRets(stompedOnRets),
  .panic(fb_panic)
);
end
else begin : gb1
FT64_fetchbuf_x1 #(AMSB,RSTPC) ufb1
(
  .rst(rst),
  .clk4x(clk4x),
  .clk(clk),
  .fcu_clk(fcu_clk),
  .cs_i(vadr[31:16]==16'hFFFF),
  .cyc_i(cyc),
  .stb_i(stb_o),
  .ack_o(dc_ack),
  .we_i(we),
  .adr_i(vadr[15:0]),
  .dat_i(dat_o[47:0]),
  .cmpgrp(cr0[10:8]),
  .freezePC(freezePC),
  .regLR(regLR),
  .thread_en(thread_en),
  .insn0(insn0),
  .phit(phit), 
  .threadx(threadx),
  .branchmiss(branchmiss),
  .misspc(misspc),
  .branchmiss_thrd(branchmiss_thrd),
  .predict_takenA(predict_takenA),
  .predict_takenB(predict_takenB),
  .predict_taken0(predict_taken0),
  .queued1(queued1),
  .queuedNop(queuedNop),
  .pc0(pc0),
  .fetchbuf(fetchbuf),
  .fetchbufA_v(fetchbufA_v),
  .fetchbufB_v(fetchbufB_v),
  .fetchbufA_pc(fetchbufA_pc),
  .fetchbufB_pc(fetchbufB_pc),
  .fetchbufA_instr(fetchbufA_instr),
  .fetchbufB_instr(fetchbufB_instr),
  .fetchbuf0_instr(fetchbuf0_instr),
  .fetchbuf0_thrd(fetchbuf0_thrd),
  .fetchbuf0_pc(fetchbuf0_pc),
  .fetchbuf0_v(fetchbuf0_v),
  .fetchbuf0_insln(fetchbuf0_insln),
  .codebuf0(codebuf[insn0[21:16]]),
  .btgtA(btgtA),
  .btgtB(btgtB),
  .nop_fetchbuf(nop_fetchbuf),
  .take_branch0(take_branch0),
  .stompedRets(stompedOnRets),
  .panic(fb_panic)
);
assign fetchbuf1_v = `INV;
end
end
endgenerate

// Determine the head increment amount, this must match code later on.
reg [2:0] hi_amt;
always @*
begin
	hi_amt <= 4'd0;
  casez ({ iqentry_v[heads[0]],
		iqentry_cmt[heads[0]],
		iqentry_v[heads[1]],
		iqentry_cmt[heads[1]],
		iqentry_v[heads[2]],
		iqentry_cmt[heads[2]]})

	// retire 3
	6'b0?_0?_0?:
		if (heads[0] != tail0 && heads[1] != tail0 && heads[2] != tail0) begin
			hi_amt <= 3'd3;
		end
		else if (heads[0] != tail0 && heads[1] != tail0) begin
			hi_amt <= 3'd2;
		end
		else if (heads[0] != tail0) begin
			hi_amt <= 3'd1;
		end
	6'b0?_0?_10:	;
	6'b0?_0?_11:
		if (`NUM_CMT > 2 || iqentry_tgt[heads[2]][4:0]==5'd0) begin
			hi_amt <= 3'd3;
		end
		else begin
			hi_amt <= 3'd2;
		end

	// retire 1 (wait for regfile for heads[1])
	6'b0?_10_??:
		hi_amt <= 3'd1;

	// retire 2
	6'b0?_11_0?,
	6'b0?_11_10:
        if (`NUM_CMT > 1 || iqentry_tgt[heads[1]]==12'd0) begin
					hi_amt <= 3'd2;	
        end
        else begin
					hi_amt <= 3'd1;
      	end
  6'b0?_11_11:
        if (`NUM_CMT > 2 || (`NUM_CMT > 1 && iqentry_tgt[heads[2]] == 12'd0 && !iqentry_oddball[heads[2]] && ~|iqentry_exc[heads[2]])) begin
					hi_amt <= 3'd3;
      	end	
      	else if (`NUM_CMT > 1 || iqentry_tgt[heads[1]]==12'd0) begin
					hi_amt <= 3'd2;
      	end
      	else
					hi_amt <= 3'd1;
  6'b10_??_??:	;
  6'b11_0?_0?:
  	if (heads[1] != tail0 && heads[2] != tail0) begin
			hi_amt <= 3'd3;
  	end
  	else if (heads[1] != tail0) begin
			hi_amt <= 3'd2;
  	end
  	else begin
			hi_amt <= 3'd1;
  	end
  6'b11_0?_10:
  	if (heads[1] != tail0) begin
			hi_amt <= 3'd2;
  	end
  	else begin
			hi_amt <= 3'd1;
  	end
  6'b11_0?_11:
  	if (heads[1] != tail0) begin
  		if (`NUM_CMT > 2 || (iqentry_tgt[heads[2]]==12'd0 && !iqentry_oddball[heads[2]] && ~|iqentry_exc[heads[2]])) begin
				hi_amt <= 3'd3;
  		end
  		else begin
				hi_amt <= 3'd2;
			end
  	end
  	else begin
			hi_amt <= 3'd1;
  	end
  6'b11_10_??:
  	begin
			hi_amt <= 3'd1;
  	end
  6'b11_11_0?:
  	if (`NUM_CMT > 1 && heads[2] != tail0) begin
			hi_amt <= 3'd3;
  	end
  	else if (iqentry_tgt[heads[1]]== 12'd0 && heads[2] != tail0) begin
			hi_amt <= 3'd3;
  	end
  	else if (`NUM_CMT > 1 || iqentry_tgt[heads[1]]==12'd0) begin
			hi_amt <= 3'd2;
  	end
  	else begin
			hi_amt <= 3'd1;
  	end
  6'b11_11_10:
  	if (`NUM_CMT > 1 || iqentry_tgt[heads[1]]==12'd0) begin
			hi_amt <= 3'd2;
  	end
  	else begin
			hi_amt <= 3'd1;
  	end
	6'b11_11_11:
		if (`NUM_CMT > 2 || (`NUM_CMT > 1 && iqentry_tgt[heads[2]]==12'd0 && !iqentry_oddball[heads[2]] && ~|iqentry_exc[heads[2]])) begin
			hi_amt <= 3'd3;
		end
		else if (`NUM_CMT > 1 || iqentry_tgt[heads[1]]==12'd0) begin
			hi_amt <= 3'd2;
		end
		else begin
			hi_amt <= 3'd1;
		end
	default:
		begin
			hi_amt <= 3'd0;
			$display("hi_amt: Uncoded case %b",{ iqentry_v[heads[0]],
				iqentry_cmt[heads[0]],
				iqentry_v[heads[1]],
				iqentry_cmt[heads[1]],
				iqentry_v[heads[2]],
				iqentry_cmt[heads[2]]});
		end
  endcase
end

// Amount subtracted from sequence numbers
reg [`SNBITS] tosub;
always @*
case(hi_amt)
3'd3: tosub <= (iqentry_v[heads[2]] ? iqentry_sn[heads[2]]
							 : iqentry_v[heads[1]] ? iqentry_sn[heads[1]]
							 : iqentry_v[heads[0]] ? iqentry_sn[heads[0]]
							 : 4'b0);
3'd2: tosub <= (iqentry_v[heads[1]] ? iqentry_sn[heads[1]]
							 : iqentry_v[heads[0]] ? iqentry_sn[heads[0]]
							 : 4'b0);
3'd1: tosub <= (iqentry_v[heads[0]] ? iqentry_sn[heads[0]]
							 : 4'b0);							 
default:	tosub <= 4'd0;
endcase

//initial begin: stop_at
//#1000000; panic <= `PANIC_OVERRUN;
//end

//
// BRANCH-MISS LOGIC: livetarget
//
// livetarget implies that there is a not-to-be-stomped instruction that targets the register in question
// therefore, if it is zero it implies the rf_v value should become VALID on a branchmiss
// 

always @*
for (j = 1; j < PREGS; j = j + 1) begin
	livetarget[j] = 1'b0;
	for (n = 0; n < QENTRIES; n = n + 1)
		livetarget[j] = livetarget[j] | iqentry_livetarget[n][j];
end

always @*
	for (n = 0; n < QENTRIES; n = n + 1)
		iqentry_livetarget[n] = {PREGS {iqentry_v[n]}} & {PREGS {~iqentry_stomp[n] && iqentry_thrd[n]==branchmiss_thrd}} & iq_out[n];

//
// BRANCH-MISS LOGIC: latestID
//
// latestID is the instruction queue ID of the newest instruction (latest) that targets
// a particular register.  looks a lot like scheduling logic, but in reverse.
// 
always @*
	for (n = 0; n < QENTRIES; n = n + 1) begin
		iqentry_cumulative[n] = 1'b0;
		for (j = n; j < n + QENTRIES; j = j + 1) begin
			if (missid==(j % QENTRIES))
				for (k = n; k <= j; k = k + 1)
					iqentry_cumulative[n] = iqentry_cumulative[n] | iqentry_livetarget[k % QENTRIES];
		end
	end

always @*
	for (n = 0; n < QENTRIES; n = n + 1)
    iqentry_latestID[n] = (missid == n || ((iqentry_livetarget[n] & iqentry_cumulative[(n+1)%QENTRIES]) == {PREGS{1'b0}}))
				    ? iqentry_livetarget[n]
				    : {PREGS{1'b0}};

always @*
	for (n = 0; n < QENTRIES; n = n + 1)
	  iqentry_source[n] = | iqentry_latestID[n];

reg vqueued2;
assign Ra0 = fnRa(fetchbuf0_instr,vqe0,vl,fetchbuf0_thrd) | {fetchbuf0_thrd,7'b0};
assign Rb0 = fnRb(fetchbuf0_instr,1'b0,vqe0,rfoa0[5:0],rfoa1[5:0],fetchbuf0_thrd) | {fetchbuf0_thrd,7'b0};
assign Rc0 = fnRc(fetchbuf0_instr,vqe0,fetchbuf0_thrd) | {fetchbuf0_thrd,7'b0};
assign Rt0 = fnRt(fetchbuf0_instr,vqet0,vl,fetchbuf0_thrd) | {fetchbuf0_thrd,7'b0};
assign Ra1 = fnRa(fetchbuf1_instr,vqueued2 ? vqe0 + 1 : vqe1,vl,fetchbuf1_thrd) | {fetchbuf1_thrd,7'b0};
assign Rb1 = fnRb(fetchbuf1_instr,1'b1,vqueued2 ? vqe0 + 1 : vqe1,rfoa0[5:0],rfoa1[5:0],fetchbuf1_thrd) | {fetchbuf1_thrd,7'b0};
assign Rc1 = fnRc(fetchbuf1_instr,vqueued2 ? vqe0 + 1 : vqe1,fetchbuf1_thrd) | {fetchbuf1_thrd,7'b0};
assign Rt1 = fnRt(fetchbuf1_instr,vqueued2 ? vqet0 + 1 : vqet1,vl,fetchbuf1_thrd) | {fetchbuf1_thrd,7'b0};

//
// additional logic for ISSUE
//
// for the moment, we look at ALU-input buffers to allow back-to-back issue of 
// dependent instructions ... we do not, however, look ahead for DRAM requests 
// that will become valid in the next cycle.  instead, these have to propagate
// their results into the IQ entry directly, at which point it becomes issue-able
//

// note that, for all intents & purposes, iqentry_done == iqentry_agen ... no need to duplicate

wire [QENTRIES-1:0] args_valid;
wire [QENTRIES-1:0] could_issue;
wire [QENTRIES-1:0] could_issueid;

generate begin : issue_logic
for (g = 0; g < QENTRIES; g = g + 1)
begin
assign args_valid[g] =
		  (iqentry_a1_v[g] 
`ifdef FU_BYPASS
        || (iqentry_a1_s[g] == alu0_sourceid && alu0_dataready && (~alu0_mem | alu0_push))
        || ((iqentry_a1_s[g] == alu1_sourceid && alu1_dataready && (~alu1_mem | alu1_push)) && (`NUM_ALU > 1))
        || ((iqentry_a1_s[g] == fpu1_sourceid && fpu1_dataready) && (`NUM_FPU > 0))
`endif
        )
    && (iqentry_a2_v[g] 
`ifdef FU_BYPASS
        || (iqentry_a2_s[g] == alu0_sourceid && alu0_dataready && (~alu0_mem | alu0_push))
        || ((iqentry_a2_s[g] == alu1_sourceid && alu1_dataready && (~alu1_mem | alu1_push)) && (`NUM_ALU > 1))
        || ((iqentry_a2_s[g] == fpu1_sourceid && fpu1_dataready) && (`NUM_FPU > 0))
`endif
        )
    && (iqentry_a3_v[g] 
        || (iqentry_mem[g] & ~iqentry_agen[g] & ~iqentry_memndx[g])    // a3 needs to be valid for indexed instruction
//        || (iqentry_mem[g] & ~iqentry_agen[g])
`ifdef FU_BYPASS
        || (iqentry_a3_s[g] == alu0_sourceid && alu0_dataready && (~alu0_mem | alu0_push))
        || ((iqentry_a3_s[g] == alu1_sourceid && alu1_dataready && (~alu1_mem | alu1_push)) && (`NUM_ALU > 1))
`endif
        )
    ;

assign could_issue[g] = iqentry_v[g] && !iqentry_done[g] && !iqentry_out[g]
												&& args_valid[g]
												&& iqentry_iv[g]
                        && (iqentry_mem[g] ? !iqentry_agen[g] : 1'b1);

assign could_issueid[g] = (iqentry_v[g])// || (g==tail0 && canq1))// || (g==tail1 && canq2))
														&& !iqentry_iv[g];
//		  && (iqentry_a1_v[g] 
//        || (iqentry_a1_s[g] == alu0_sourceid && alu0_dataready)
//        || (iqentry_a1_s[g] == alu1_sourceid && alu1_dataready));

end                                 
end
endgenerate

// The (old) simulator didn't handle the asynchronous race loop properly in the 
// original code. It would issue two instructions to the same islot. So the
// issue logic has been re-written to eliminate the asynchronous loop.
// Can't issue to the ALU if it's busy doing a long running operation like a 
// divide.
// ToDo: fix the memory synchronization, see fp_issue below
`ifndef INLINE_DECODE
always @*
begin
	iqentry_id1issue = {QENTRIES{1'b0}};
	if (id1_available) begin
		for (n = 0; n < QENTRIES; n = n + 1)
			if (could_issueid[heads[n]] && iqentry_id1issue=={QENTRIES{1'b0}})
			  iqentry_id1issue[heads[n]] = `TRUE;
	end
end
generate begin : gIDUIssue
	if (`NUM_IDU > 1) begin
		always @*
		begin
			iqentry_id2issue = {QENTRIES{1'b0}};
			if (id2_available) begin
				for (n = 0; n < QENTRIES; n = n + 1)
					if (could_issueid[heads[n]] && !iqentry_id1issue[heads[n]] && iqentry_id2issue=={QENTRIES{1'b0}})
					  iqentry_id2issue[heads[n]] = `TRUE;
			end
		end
	end
	if (`NUM_IDU > 2) begin
		always @*
		begin
			iqentry_id3issue = {QENTRIES{1'b0}};
			if (id3_available) begin
				for (n = 0; n < QENTRIES; n = n + 1)
					if (could_issueid[heads[n]] 
					&& !iqentry_id1issue[heads[n]]
					&& !iqentry_id2issue[heads[n]]
					&& iqentry_id3issue=={QENTRIES{1'b0}})
					  iqentry_id3issue[heads[n]] = `TRUE;
			end
		end
	end
end
endgenerate
`endif	// not INLINE_DECODE

// Detect if there are any valid queue entries prior to the given queue entry.
reg [QENTRIES-1:0] prior_valid;
//generate begin : gPriorValid
always @*
for (j = 0; j < QENTRIES; j = j + 1)
begin
	prior_valid[heads[j]] = 1'b0;
	if (j > 0)
		for (n = j-1; n >= 0; n = n - 1)
			prior_valid[heads[j]] = prior_valid[heads[j]]|iqentry_v[heads[n]];
end
//end
//endgenerate

// Detect if there are any valid sync instructions prior to the given queue 
// entry.
reg [QENTRIES-1:0] prior_sync;
//generate begin : gPriorSync
always @*
for (j = 0; j < QENTRIES; j = j + 1)
begin
	prior_sync[heads[j]] = 1'b0;
	if (j > 0)
		for (n = j-1; n >= 0; n = n - 1)
			prior_sync[heads[j]] = prior_sync[heads[j]]|(iqentry_v[heads[n]] & iqentry_sync[heads[n]]);
end
//end
//endgenerate

// Detect if there are any valid fsync instructions prior to the given queue 
// entry.
reg [QENTRIES-1:0] prior_fsync;
//generate begin : gPriorFsync
always @*
for (j = 0; j < QENTRIES; j = j + 1)
begin
	prior_fsync[heads[j]] = 1'b0;
	if (j > 0)
		for (n = j-1; n >= 0; n = n - 1)
			prior_fsync[heads[j]] = prior_fsync[heads[j]]|(iqentry_v[heads[n]] & iqentry_fsync[heads[n]]);
end
//end
//endgenerate

// Start search for instructions to process at head of queue (oldest instruction).
always @*
begin
	iqentry_alu0_issue = {QENTRIES{1'b0}};
	iqentry_alu1_issue = {QENTRIES{1'b0}};
	
	if (alu0_available & alu0_idle) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iqentry_alu[heads[n]]
			&& iqentry_alu0_issue == {QENTRIES{1'b0}}
			// If there are no valid queue entries prior it doesn't matter if there is
			// a sync.
			&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
			)
			  iqentry_alu0_issue[heads[n]] = `TRUE;
		end
	end

	if (alu1_available && alu1_idle && `NUM_ALU > 1) begin
//		if ((could_issue & ~iqentry_alu0_issue & ~iqentry_alu0) != {QENTRIES{1'b0}}) begin
			for (n = 0; n < QENTRIES; n = n + 1) begin
				if (could_issue[heads[n]] && iqentry_alu[heads[n]]
					&& !iqentry_alu0[heads[n]]	// alu0 only
					&& !iqentry_alu0_issue[heads[n]]
					&& iqentry_alu1_issue == {QENTRIES{1'b0}}
					&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
				)
				  iqentry_alu1_issue[heads[n]] = `TRUE;
			end
//		end
	end
end


// Start search for instructions to process at head of queue (oldest instruction).
always @*
begin
	iqentry_fpu1_issue = {QENTRIES{1'b0}};
	iqentry_fpu2_issue = {QENTRIES{1'b0}};
	
	if (fpu1_available && fpu1_idle && `NUM_FPU > 0) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iqentry_fpu[heads[n]]
			&& iqentry_fpu1_issue == {QENTRIES{1'b0}}
			// If there are no valid queue entries prior it doesn't matter if there is
			// a sync.
			&& (!(prior_sync[heads[n]]|prior_fsync[heads[n]]) || !prior_valid[heads[n]])
			)
			  iqentry_fpu1_issue[heads[n]] = `TRUE;
		end
	end

	if (fpu2_available && fpu2_idle && `NUM_FPU > 1) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iqentry_fpu[heads[n]]
			&& !iqentry_fpu1_issue[heads[n]]
			&& iqentry_fpu2_issue == {QENTRIES{1'b0}}
			&& (!(prior_sync[heads[n]]|prior_fsync[heads[n]]) || !prior_valid[heads[n]])
			)
			  iqentry_fpu2_issue[heads[n]] = `TRUE;
		end
	end
end

reg [QENTRIES-1:0] nextqd;
// Next queue id

/*
reg [`QBITS] nids [0:QENTRIES-1];
always @*
for (n = 0; n < QENTRIES; n = n + 1)
begin
	nids[n] = n[`QBITS];
	for (j = n; j != (n+1) % QENTRIES; j = (j - 1) % QENTRIES)
		if (iqentry_thrd[(j+1)%QENTRIES]==iqentry_thrd[n])
			nids[n] = (j + 1) % QENTRIES;
	// Add one more compare and set
end
*/
/*
reg [`QBITS] nid0;
always @*
if (iqentry_thrd[1]==iqentry_thrd[0])
	nid0 = 4'd1;
else if (iqentry_thrd[2]==iqentry_thrd[0])
	nid0 = 4'd2;
else if (iqentry_thrd[3]==iqentry_thrd[0])
	nid0 = 4'd3;
else if (iqentry_thrd[4]==iqentry_thrd[0])
	nid0 = 4'd4;
else if (iqentry_thrd[5]==iqentry_thrd[0])
	nid0 = 4'd5;
else if (iqentry_thrd[6]==iqentry_thrd[0])
	nid0 = 4'd6;
else if (iqentry_thrd[7]==iqentry_thrd[0])
	nid0 = 4'd7;
else if (iqentry_thrd[8]==iqentry_thrd[0])
	nid0 = 4'd8;
else if (iqentry_thrd[9]==iqentry_thrd[0])
	nid0 = 4'd9;
else
	nid0 = 4'd0;

reg [`QBITS] nid1;
always @*
if (iqentry_thrd[2]==iqentry_thrd[1])
	nid1 = 4'd2;
else if (iqentry_thrd[3]==iqentry_thrd[1])
	nid1 = 4'd3;
else if (iqentry_thrd[4]==iqentry_thrd[1])
	nid1 = 4'd4;
else if (iqentry_thrd[5]==iqentry_thrd[1])
	nid1 = 4'd5;
else if (iqentry_thrd[6]==iqentry_thrd[1])
	nid1 = 4'd6;
else if (iqentry_thrd[7]==iqentry_thrd[1])
	nid1 = 4'd7;
else if (iqentry_thrd[8]==iqentry_thrd[1])
	nid1 = 4'd8;
else if (iqentry_thrd[9]==iqentry_thrd[1])
	nid1 = 4'd9;
else if (iqentry_thrd[0]==iqentry_thrd[1])
	nid1 = 4'd0;
else
	nid1 = 4'd1;

reg [`QBITS] nid2;
always @*
if (iqentry_thrd[3]==iqentry_thrd[2])
	nid2 = 4'd3;
else if (iqentry_thrd[4]==iqentry_thrd[2])
	nid2 = 4'd4;
else if (iqentry_thrd[5]==iqentry_thrd[2])
	nid2 = 4'd5;
else if (iqentry_thrd[6]==iqentry_thrd[2])
	nid2 = 4'd6;
else if (iqentry_thrd[7]==iqentry_thrd[2])
	nid2 = 4'd7;
else if (iqentry_thrd[8]==iqentry_thrd[2])
	nid2 = 4'd8;
else if (iqentry_thrd[9]==iqentry_thrd[2])
	nid2 = 4'd9;
else if (iqentry_thrd[0]==iqentry_thrd[2])
	nid2 = 4'd0;
else if (iqentry_thrd[1]==iqentry_thrd[2])
	nid2 = 4'd1;
else
	nid2 = 4'd2;

reg [`QBITS] nid3;
always @*
if (iqentry_thrd[4]==iqentry_thrd[3])
	nid3 = 4'd4;
else if (iqentry_thrd[5]==iqentry_thrd[3])
	nid3 = 4'd5;
else if (iqentry_thrd[6]==iqentry_thrd[3])
	nid3 = 4'd6;
else if (iqentry_thrd[7]==iqentry_thrd[3])
	nid3 = 4'd7;
else if (iqentry_thrd[8]==iqentry_thrd[3])
	nid3 = 4'd8;
else if (iqentry_thrd[9]==iqentry_thrd[3])
	nid3 = 4'd9;
else if (iqentry_thrd[0]==iqentry_thrd[3])
	nid3 = 4'd0;
else if (iqentry_thrd[1]==iqentry_thrd[3])
	nid3 = 4'd1;
else if (iqentry_thrd[2]==iqentry_thrd[3])
	nid3 = 4'd2;
else
	nid3 = 4'd3;

reg [`QBITS] nid4;
always @*
if (iqentry_thrd[5]==iqentry_thrd[4])
	nid4 = 4'd5;
else if (iqentry_thrd[6]==iqentry_thrd[4])
	nid4 = 4'd6;
else if (iqentry_thrd[7]==iqentry_thrd[4])
	nid4 = 4'd7;
else if (iqentry_thrd[8]==iqentry_thrd[4])
	nid4 = 4'd8;
else if (iqentry_thrd[9]==iqentry_thrd[4])
	nid4 = 4'd9;
else if (iqentry_thrd[0]==iqentry_thrd[4])
	nid4 = 4'd0;
else if (iqentry_thrd[1]==iqentry_thrd[4])
	nid4 = 4'd1;
else if (iqentry_thrd[2]==iqentry_thrd[4])
	nid4 = 4'd2;
else if (iqentry_thrd[3]==iqentry_thrd[4])
	nid4 = 4'd3;
else
	nid4 = 4'd4;

reg [`QBITS] nid5;
always @*
if (iqentry_thrd[6]==iqentry_thrd[5])
	nid5 = 4'd6;
else if (iqentry_thrd[7]==iqentry_thrd[5])
	nid5 = 4'd7;
else if (iqentry_thrd[8]==iqentry_thrd[5])
	nid5 = 4'd8;
else if (iqentry_thrd[9]==iqentry_thrd[5])
	nid5 = 4'd9;
else if (iqentry_thrd[0]==iqentry_thrd[5])
	nid5 = 4'd0;
else if (iqentry_thrd[1]==iqentry_thrd[5])
	nid5 = 4'd1;
else if (iqentry_thrd[2]==iqentry_thrd[5])
	nid5 = 4'd2;
else if (iqentry_thrd[3]==iqentry_thrd[5])
	nid5 = 4'd3;
else if (iqentry_thrd[4]==iqentry_thrd[5])
	nid5 = 4'd4;
else
	nid5 = 4'd5;

reg [`QBITS] nid6;
always @*
if (iqentry_thrd[7]==iqentry_thrd[6])
	nid6 = 4'd7;
else if (iqentry_thrd[8]==iqentry_thrd[6])
	nid6 = 4'd8;
else if (iqentry_thrd[9]==iqentry_thrd[6])
	nid6 = 4'd9;
else if (iqentry_thrd[0]==iqentry_thrd[6])
	nid6 = 4'd0;
else if (iqentry_thrd[1]==iqentry_thrd[6])
	nid6 = 4'd1;
else if (iqentry_thrd[2]==iqentry_thrd[6])
	nid6 = 4'd2;
else if (iqentry_thrd[3]==iqentry_thrd[6])
	nid6 = 4'd3;
else if (iqentry_thrd[4]==iqentry_thrd[6])
	nid6 = 4'd4;
else if (iqentry_thrd[5]==iqentry_thrd[6])
	nid6 = 4'd5;
else
	nid6 = 4'd6;

reg [`QBITS] nid7;
always @*
if (iqentry_thrd[8]==iqentry_thrd[7])
	nid7 = 4'd8;
else if (iqentry_thrd[9]==iqentry_thrd[7])
	nid7 = 4'd9;
else if (iqentry_thrd[0]==iqentry_thrd[7])
	nid7 = 4'd0;
else if (iqentry_thrd[1]==iqentry_thrd[7])
	nid7 = 4'd1;
else if (iqentry_thrd[2]==iqentry_thrd[7])
	nid7 = 4'd2;
else if (iqentry_thrd[3]==iqentry_thrd[7])
	nid7 = 4'd3;
else if (iqentry_thrd[4]==iqentry_thrd[7])
	nid7 = 4'd4;
else if (iqentry_thrd[5]==iqentry_thrd[7])
	nid7 = 4'd5;
else if (iqentry_thrd[6]==iqentry_thrd[7])
	nid7 = 4'd6;
else
	nid7 = 4'd7;

reg [`QBITS] nid8;
always @*
if (iqentry_thrd[9]==iqentry_thrd[8])
	nid8 = 4'd9;
else if (iqentry_thrd[0]==iqentry_thrd[8])
	nid8 = 4'd0;
else if (iqentry_thrd[1]==iqentry_thrd[8])
	nid8 = 4'd1;
else if (iqentry_thrd[2]==iqentry_thrd[8])
	nid8 = 4'd2;
else if (iqentry_thrd[3]==iqentry_thrd[8])
	nid8 = 4'd3;
else if (iqentry_thrd[4]==iqentry_thrd[8])
	nid8 = 4'd4;
else if (iqentry_thrd[5]==iqentry_thrd[8])
	nid8 = 4'd5;
else if (iqentry_thrd[6]==iqentry_thrd[8])
	nid8 = 4'd6;
else if (iqentry_thrd[7]==iqentry_thrd[8])
	nid8 = 4'd7;
else
	nid8 = 4'd8;

reg [`QBITS] nid9;
always @*
if (iqentry_thrd[0]==iqentry_thrd[9])
	nid9 = 4'd0;
else if (iqentry_thrd[1]==iqentry_thrd[9])
	nid9 = 4'd1;
else if (iqentry_thrd[2]==iqentry_thrd[9])
	nid9 = 4'd2;
else if (iqentry_thrd[3]==iqentry_thrd[9])
	nid9 = 4'd3;
else if (iqentry_thrd[4]==iqentry_thrd[9])
	nid9 = 4'd4;
else if (iqentry_thrd[5]==iqentry_thrd[9])
	nid9 = 4'd5;
else if (iqentry_thrd[6]==iqentry_thrd[9])
	nid9 = 4'd6;
else if (iqentry_thrd[7]==iqentry_thrd[9])
	nid9 = 4'd7;
else if (iqentry_thrd[8]==iqentry_thrd[9])
	nid9 = 4'd8;
else
	nid9 = 4'd9;
*/
reg [`QBITS] nids [0:QENTRIES-1];
always @*
for (j = 0; j < QENTRIES; j = j + 1) begin
	// We can't both start and stop at j
	for (n = j; n != (j+1)%QENTRIES; n = (n + (QENTRIES-1)) % QENTRIES)
		if (iqentry_thrd[n]==iqentry_thrd[j])
			nids[j] = n;
	// Do the last one
	if (iqentry_thrd[(j+1)%QENTRIES]==iqentry_thrd[j])
		nids[j] = (j+1)%QENTRIES;
end
/*
assign nids[0] = nid0;
assign nids[1] = nid1;
assign nids[2] = nid2;
assign nids[3] = nid3;
assign nids[4] = nid4;
assign nids[5] = nid5;
assign nids[6] = nid6;
assign nids[7] = nid7;
assign nids[8] = nid8;
assign nids[9] = nid9;
*/
// Search the queue for the next entry on the same thread.
reg [`QBITS] nid;
always @*
begin
	nid = fcu_id;
	for (n = QENTRIES-1; n > 0; n = n - 1)
		if (iqentry_thrd[(fcu_id + n) % QENTRIES]==fcu_thrd)
			nid = (fcu_id + n) % QENTRIES;
end
/*
always @*
if (iqentry_thrd[idp1(fcu_id)]==iqentry_thrd[fcu_id[`QBITS]])
	nid = idp1(fcu_id);
else if (iqentry_thrd[idp2(fcu_id)]==iqentry_thrd[fcu_id[`QBITS]])
	nid = idp2(fcu_id);
else if (iqentry_thrd[idp3(fcu_id)]==iqentry_thrd[fcu_id[`QBITS]])
	nid = idp3(fcu_id);
else if (iqentry_thrd[idp4(fcu_id)]==iqentry_thrd[fcu_id[`QBITS]])
	nid = idp4(fcu_id);
else if (iqentry_thrd[idp5(fcu_id)]==iqentry_thrd[fcu_id[`QBITS]])
	nid = idp5(fcu_id);
else if (iqentry_thrd[idp6(fcu_id)]==iqentry_thrd[fcu_id[`QBITS]])
	nid = idp6(fcu_id);
else if (iqentry_thrd[idp7(fcu_id)]==iqentry_thrd[fcu_id[`QBITS]])
	nid = idp7(fcu_id);
else if (iqentry_thrd[idp8(fcu_id)]==iqentry_thrd[fcu_id[`QBITS]])
	nid = idp8(fcu_id);
else if (iqentry_thrd[idp9(fcu_id)]==iqentry_thrd[fcu_id[`QBITS]])
	nid = idp9(fcu_id);
else
	nid = fcu_id;
*/
always @*
for (n = 0; n < QENTRIES; n = n + 1)
	nextqd[n] <= iqentry_sn[nids[n]] > iqentry_sn[n] || iqentry_v[n];

//assign nextqd = 8'hFF;

// Don't issue to the fcu until the following instruction is enqueued.
// However, if the queue is full then issue anyway. A branch miss will likely occur.
// Start search for instructions at head of queue (oldest instruction).
always @*
begin
	iqentry_fcu_issue = {QENTRIES{1'b0}};
	
	if (fcu_done) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iqentry_fc[heads[n]] && nextqd[heads[n]]
			&& iqentry_fcu_issue == {QENTRIES{1'b0}}
			&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
			)
			  iqentry_fcu_issue[heads[n]] = `TRUE;
		end
	end
end

//
// determine if the instructions ready to issue can, in fact, issue.
// "ready" means that the instruction has valid operands but has not gone yet
reg [1:0] issue_count, missue_count;
generate begin : gMemIssue
always @*
begin
	issue_count = 0;
	 memissue[ heads[0] ] =	iqentry_memready[ heads[0] ];		// first in line ... go as soon as ready
	 if (memissue[heads[0]])
	 	issue_count = issue_count + 1;

	 memissue[ heads[1] ] =	~iqentry_stomp[heads[1]] && iqentry_memready[ heads[1] ]		// addr and data are valid
					&& issue_count < `NUM_MEM
					// ... and no preceding instruction is ready to go
					//&& ~iqentry_memready[heads[0]]
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[heads[0]] || (iqentry_agen[heads[0]] & iqentry_out[heads[0]]) || iqentry_done[heads[0]]
						|| ((iqentry_ma[heads[1]][AMSB:3] != iqentry_ma[heads[0]][AMSB:3] || iqentry_out[heads[0]] || iqentry_done[heads[0]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iqentry_rl[heads[1]] ? iqentry_done[heads[0]] || !iqentry_v[heads[0]] || !iqentry_mem[heads[0]] : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iqentry_aq[heads[0]] && iqentry_v[heads[0]])
					// ... and, if it is a store, there is no chance of it being undone
					&& (iqentry_load[heads[1]] ||
					   !(iqentry_fc[heads[0]]||iqentry_canex[heads[0]]));
	 if (memissue[heads[1]])
	 	issue_count = issue_count + 1;

	 memissue[ heads[2] ] =	~iqentry_stomp[heads[2]] && iqentry_memready[ heads[2] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iqentry_memready[heads[0]]
					//&& ~iqentry_memready[heads[1]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[heads[0]] || (iqentry_agen[heads[0]] & iqentry_out[heads[0]])  || iqentry_done[heads[0]]
						|| ((iqentry_ma[heads[2]][AMSB:3] != iqentry_ma[heads[0]][AMSB:3] || iqentry_out[heads[0]] || iqentry_done[heads[0]])))
					&& (!iqentry_mem[heads[1]] || (iqentry_agen[heads[1]] & iqentry_out[heads[1]])  || iqentry_done[heads[1]]
						|| ((iqentry_ma[heads[2]][AMSB:3] != iqentry_ma[heads[1]][AMSB:3] || iqentry_out[heads[1]] || iqentry_done[heads[1]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iqentry_rl[heads[2]] ? (iqentry_done[heads[0]] || !iqentry_v[heads[0]] || !iqentry_mem[heads[0]])
										 && (iqentry_done[heads[1]] || !iqentry_v[heads[1]] || !iqentry_mem[heads[1]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iqentry_aq[heads[0]] && iqentry_v[heads[0]])
					&& !(iqentry_aq[heads[1]] && iqentry_v[heads[1]])
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
            && (!(iqentry_iv[heads[1]] && iqentry_memsb[heads[1]]) || (iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
    				&& (!(iqentry_iv[heads[1]] && iqentry_memdb[heads[1]]) || (!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_load[heads[2]] ||
					      !(iqentry_fc[heads[0]]||iqentry_canex[heads[0]])
					   && !(iqentry_fc[heads[1]]||iqentry_canex[heads[1]]));
	 if (memissue[heads[2]])
	 	issue_count = issue_count + 1;
					        
	 memissue[ heads[3] ] =	~iqentry_stomp[heads[3]] && iqentry_memready[ heads[3] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iqentry_memready[heads[0]]
					//&& ~iqentry_memready[heads[1]] 
					//&& ~iqentry_memready[heads[2]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[heads[0]] || (iqentry_agen[heads[0]] & iqentry_out[heads[0]])  || iqentry_done[heads[0]]
						|| ((iqentry_ma[heads[3]][AMSB:3] != iqentry_ma[heads[0]][AMSB:3] || iqentry_out[heads[0]] || iqentry_done[heads[0]])))
					&& (!iqentry_mem[heads[1]] || (iqentry_agen[heads[1]] & iqentry_out[heads[1]])  || iqentry_done[heads[1]]
						|| ((iqentry_ma[heads[3]][AMSB:3] != iqentry_ma[heads[1]][AMSB:3] || iqentry_out[heads[1]] || iqentry_done[heads[1]])))
					&& (!iqentry_mem[heads[2]] || (iqentry_agen[heads[2]] & iqentry_out[heads[2]])  || iqentry_done[heads[2]]
						|| ((iqentry_ma[heads[3]][AMSB:3] != iqentry_ma[heads[2]][AMSB:3] || iqentry_out[heads[2]] || iqentry_done[heads[2]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iqentry_rl[heads[3]] ? (iqentry_done[heads[0]] || !iqentry_v[heads[0]] || !iqentry_mem[heads[0]])
										 && (iqentry_done[heads[1]] || !iqentry_v[heads[1]] || !iqentry_mem[heads[1]])
										 && (iqentry_done[heads[2]] || !iqentry_v[heads[2]] || !iqentry_mem[heads[2]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iqentry_aq[heads[0]] && iqentry_v[heads[0]])
					&& !(iqentry_aq[heads[1]] && iqentry_v[heads[1]])
					&& !(iqentry_aq[heads[2]] && iqentry_v[heads[2]])
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iqentry_iv[heads[1]] && iqentry_memsb[heads[1]]) || (iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memsb[heads[2]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                    		)
    				&& (!(iqentry_iv[heads[1]] && iqentry_memdb[heads[1]]) || (!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memdb[heads[2]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                     		)
                    // ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_load[heads[3]] ||
		      		      !(iqentry_fc[heads[0]]||iqentry_canex[heads[0]])
                       && !(iqentry_fc[heads[1]]||iqentry_canex[heads[1]])
                       && !(iqentry_fc[heads[2]]||iqentry_canex[heads[2]]));
	 if (memissue[heads[3]])
	 	issue_count = issue_count + 1;

	if (QENTRIES > 4) begin
	 memissue[ heads[4] ] =	~iqentry_stomp[heads[4]] && iqentry_memready[ heads[4] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iqentry_memready[heads[0]]
					//&& ~iqentry_memready[heads[1]] 
					//&& ~iqentry_memready[heads[2]] 
					//&& ~iqentry_memready[heads[3]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[heads[0]] || (iqentry_agen[heads[0]] & iqentry_out[heads[0]])  || iqentry_done[heads[0]]
						|| ((iqentry_ma[heads[4]][AMSB:3] != iqentry_ma[heads[0]][AMSB:3] || iqentry_out[heads[0]] || iqentry_done[heads[0]])))
					&& (!iqentry_mem[heads[1]] || (iqentry_agen[heads[1]] & iqentry_out[heads[1]])  || iqentry_done[heads[1]]
						|| ((iqentry_ma[heads[4]][AMSB:3] != iqentry_ma[heads[1]][AMSB:3] || iqentry_out[heads[1]] || iqentry_done[heads[1]])))
					&& (!iqentry_mem[heads[2]] || (iqentry_agen[heads[2]] & iqentry_out[heads[2]])  || iqentry_done[heads[2]]
						|| ((iqentry_ma[heads[4]][AMSB:3] != iqentry_ma[heads[2]][AMSB:3] || iqentry_out[heads[2]] || iqentry_done[heads[2]])))
					&& (!iqentry_mem[heads[3]] || (iqentry_agen[heads[3]] & iqentry_out[heads[3]])  || iqentry_done[heads[3]]
						|| ((iqentry_ma[heads[4]][AMSB:3] != iqentry_ma[heads[3]][AMSB:3] || iqentry_out[heads[3]] || iqentry_done[heads[3]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iqentry_rl[heads[4]] ? (iqentry_done[heads[0]] || !iqentry_v[heads[0]] || !iqentry_mem[heads[0]])
										 && (iqentry_done[heads[1]] || !iqentry_v[heads[1]] || !iqentry_mem[heads[1]])
										 && (iqentry_done[heads[2]] || !iqentry_v[heads[2]] || !iqentry_mem[heads[2]])
										 && (iqentry_done[heads[3]] || !iqentry_v[heads[3]] || !iqentry_mem[heads[3]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iqentry_aq[heads[0]] && iqentry_v[heads[0]])
					&& !(iqentry_aq[heads[1]] && iqentry_v[heads[1]])
					&& !(iqentry_aq[heads[2]] && iqentry_v[heads[2]])
					&& !(iqentry_aq[heads[3]] && iqentry_v[heads[3]])
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iqentry_iv[heads[1]] && iqentry_memsb[heads[1]]) || (iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memsb[heads[2]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                    		)
                    && (!(iqentry_iv[heads[3]] && iqentry_memsb[heads[3]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]]))
                    		)
    				&& (!(iqentry_v[heads[1]] && iqentry_memdb[heads[1]]) || (!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memdb[heads[2]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                     		)
                    && (!(iqentry_iv[heads[3]] && iqentry_memdb[heads[3]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]]))
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_load[heads[4]] ||
		      		      !(iqentry_fc[heads[0]]||iqentry_canex[heads[0]])
                       && !(iqentry_fc[heads[1]]||iqentry_canex[heads[1]])
                       && !(iqentry_fc[heads[2]]||iqentry_canex[heads[2]])
                       && !(iqentry_fc[heads[3]]||iqentry_canex[heads[3]]));
	 if (memissue[heads[4]])
	 	issue_count = issue_count + 1;
	end

	if (QENTRIES > 5) begin
	 memissue[ heads[5] ] =	~iqentry_stomp[heads[5]] && iqentry_memready[ heads[5] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iqentry_memready[heads[0]]
					//&& ~iqentry_memready[heads[1]] 
					//&& ~iqentry_memready[heads[2]] 
					//&& ~iqentry_memready[heads[3]] 
					//&& ~iqentry_memready[heads[4]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[heads[0]] || (iqentry_agen[heads[0]] & iqentry_out[heads[0]]) || iqentry_done[heads[0]] 
						|| ((iqentry_ma[heads[5]][AMSB:3] != iqentry_ma[heads[0]][AMSB:3] || iqentry_out[heads[0]] || iqentry_done[heads[0]])))
					&& (!iqentry_mem[heads[1]] || (iqentry_agen[heads[1]] & iqentry_out[heads[1]]) || iqentry_done[heads[1]] 
						|| ((iqentry_ma[heads[5]][AMSB:3] != iqentry_ma[heads[1]][AMSB:3] || iqentry_out[heads[1]] || iqentry_done[heads[1]])))
					&& (!iqentry_mem[heads[2]] || (iqentry_agen[heads[2]] & iqentry_out[heads[2]]) || iqentry_done[heads[2]] 
						|| ((iqentry_ma[heads[5]][AMSB:3] != iqentry_ma[heads[2]][AMSB:3] || iqentry_out[heads[2]] || iqentry_done[heads[2]])))
					&& (!iqentry_mem[heads[3]] || (iqentry_agen[heads[3]] & iqentry_out[heads[3]]) || iqentry_done[heads[3]] 
						|| ((iqentry_ma[heads[5]][AMSB:3] != iqentry_ma[heads[3]][AMSB:3] || iqentry_out[heads[3]] || iqentry_done[heads[3]])))
					&& (!iqentry_mem[heads[4]] || (iqentry_agen[heads[4]] & iqentry_out[heads[4]]) || iqentry_done[heads[4]] 
						|| ((iqentry_ma[heads[5]][AMSB:3] != iqentry_ma[heads[4]][AMSB:3] || iqentry_out[heads[4]] || iqentry_done[heads[4]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iqentry_rl[heads[5]] ? (iqentry_done[heads[0]] || !iqentry_v[heads[0]] || !iqentry_mem[heads[0]])
										 && (iqentry_done[heads[1]] || !iqentry_v[heads[1]] || !iqentry_mem[heads[1]])
										 && (iqentry_done[heads[2]] || !iqentry_v[heads[2]] || !iqentry_mem[heads[2]])
										 && (iqentry_done[heads[3]] || !iqentry_v[heads[3]] || !iqentry_mem[heads[3]])
										 && (iqentry_done[heads[4]] || !iqentry_v[heads[4]] || !iqentry_mem[heads[4]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iqentry_aq[heads[0]] && iqentry_v[heads[0]])
					&& !(iqentry_aq[heads[1]] && iqentry_v[heads[1]])
					&& !(iqentry_aq[heads[2]] && iqentry_v[heads[2]])
					&& !(iqentry_aq[heads[3]] && iqentry_v[heads[3]])
					&& !(iqentry_aq[heads[4]] && iqentry_v[heads[4]])
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iqentry_iv[heads[1]] && iqentry_memsb[heads[1]]) || (iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memsb[heads[2]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                    		)
                    && (!(iqentry_iv[heads[3]] && iqentry_memsb[heads[3]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]]))
                    		)
                    && (!(iqentry_iv[heads[4]] && iqentry_memsb[heads[4]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]]))
                    		)
    				&& (!(iqentry_iv[heads[1]] && iqentry_memdb[heads[1]]) || (!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memdb[heads[2]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                     		)
                    && (!(iqentry_iv[heads[3]] && iqentry_memdb[heads[3]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]]))
                     		)
                    && (!(iqentry_iv[heads[4]] && iqentry_memdb[heads[4]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]]))
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_load[heads[5]] ||
		      		      !(iqentry_fc[heads[0]]||iqentry_canex[heads[0]])
                       && !(iqentry_fc[heads[1]]||iqentry_canex[heads[1]])
                       && !(iqentry_fc[heads[2]]||iqentry_canex[heads[2]])
                       && !(iqentry_fc[heads[3]]||iqentry_canex[heads[3]])
                       && !(iqentry_fc[heads[4]]||iqentry_canex[heads[4]]));
	 if (memissue[heads[5]])
	 	issue_count = issue_count + 1;
	end

`ifdef FULL_ISSUE_LOGIC
if (QENTRIES > 6) begin
 memissue[ heads[6] ] =	~iqentry_stomp[heads[6]] && iqentry_memready[ heads[6] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iqentry_memready[heads[0]]
					//&& ~iqentry_memready[heads[1]] 
					//&& ~iqentry_memready[heads[2]] 
					//&& ~iqentry_memready[heads[3]] 
					//&& ~iqentry_memready[heads[4]] 
					//&& ~iqentry_memready[heads[5]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[heads[0]] || (iqentry_agen[heads[0]] & iqentry_out[heads[0]]) || iqentry_done[heads[0]] 
						|| ((iqentry_ma[heads[6]][AMSB:3] != iqentry_ma[heads[0]][AMSB:3])))
					&& (!iqentry_mem[heads[1]] || (iqentry_agen[heads[1]] & iqentry_out[heads[1]]) || iqentry_done[heads[1]] 
						|| ((iqentry_ma[heads[6]][AMSB:3] != iqentry_ma[heads[1]][AMSB:3])))
					&& (!iqentry_mem[heads[2]] || (iqentry_agen[heads[2]] & iqentry_out[heads[2]]) || iqentry_done[heads[2]] 
						|| ((iqentry_ma[heads[6]][AMSB:3] != iqentry_ma[heads[2]][AMSB:3])))
					&& (!iqentry_mem[heads[3]] || (iqentry_agen[heads[3]] & iqentry_out[heads[3]]) || iqentry_done[heads[3]] 
						|| ((iqentry_ma[heads[6]][AMSB:3] != iqentry_ma[heads[3]][AMSB:3])))
					&& (!iqentry_mem[heads[4]] || (iqentry_agen[heads[4]] & iqentry_out[heads[4]]) || iqentry_done[heads[4]] 
						|| ((iqentry_ma[heads[6]][AMSB:3] != iqentry_ma[heads[4]][AMSB:3])))
					&& (!iqentry_mem[heads[5]] || (iqentry_agen[heads[5]] & iqentry_out[heads[5]]) || iqentry_done[heads[5]] 
						|| ((iqentry_ma[heads[6]][AMSB:3] != iqentry_ma[heads[5]][AMSB:3])))
					&& (iqentry_rl[heads[6]] ? (iqentry_done[heads[0]] || !iqentry_v[heads[0]] || !iqentry_mem[heads[0]])
										 && (iqentry_done[heads[1]] || !iqentry_v[heads[1]] || !iqentry_mem[heads[1]])
										 && (iqentry_done[heads[2]] || !iqentry_v[heads[2]] || !iqentry_mem[heads[2]])
										 && (iqentry_done[heads[3]] || !iqentry_v[heads[3]] || !iqentry_mem[heads[3]])
										 && (iqentry_done[heads[4]] || !iqentry_v[heads[4]] || !iqentry_mem[heads[4]])
										 && (iqentry_done[heads[5]] || !iqentry_v[heads[5]] || !iqentry_mem[heads[5]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iqentry_aq[heads[0]] && iqentry_v[heads[0]])
					&& !(iqentry_aq[heads[1]] && iqentry_v[heads[1]])
					&& !(iqentry_aq[heads[2]] && iqentry_v[heads[2]])
					&& !(iqentry_aq[heads[3]] && iqentry_v[heads[3]])
					&& !(iqentry_aq[heads[4]] && iqentry_v[heads[4]])
					&& !(iqentry_aq[heads[5]] && iqentry_v[heads[5]])
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iqentry_iv[heads[1]] && iqentry_memsb[heads[1]]) || (iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memsb[heads[2]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                    		)
                    && (!(iqentry_iv[heads[3]] && iqentry_memsb[heads[3]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]]))
                    		)
                    && (!(iqentry_iv[heads[4]] && iqentry_memsb[heads[4]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]]))
                    		)
                    && (!(iqentry_iv[heads[5]] && iqentry_memsb[heads[5]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                    		&&   (iqentry_done[heads[4]] || !iqentry_v[heads[4]]))
                    		)
    				&& (!(iqentry_iv[heads[1]] && iqentry_memdb[heads[1]]) || (!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memdb[heads[2]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                     		)
                    && (!(iqentry_iv[heads[3]] && iqentry_memdb[heads[3]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]]))
                     		)
                    && (!(iqentry_iv[heads[4]] && iqentry_memdb[heads[4]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]]))
                     		)
                    && (!(iqentry_iv[heads[5]] && iqentry_memdb[heads[5]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                     		&& (!iqentry_mem[heads[4]] || iqentry_done[heads[4]] || !iqentry_v[heads[4]]))
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_load[heads[6]] ||
		      		      !(iqentry_fc[heads[0]]||iqentry_canex[heads[0]])
                       && !(iqentry_fc[heads[1]]||iqentry_canex[heads[1]])
                       && !(iqentry_fc[heads[2]]||iqentry_canex[heads[2]])
                       && !(iqentry_fc[heads[3]]||iqentry_canex[heads[3]])
                       && !(iqentry_fc[heads[4]]||iqentry_canex[heads[4]])
                       && !(iqentry_fc[heads[5]]||iqentry_canex[heads[5]]));
	 if (memissue[heads[6]])
	 	issue_count = issue_count + 1;
	end

	if (QENTRIES > 7) begin
	memissue[ heads[7] ] =	~iqentry_stomp[heads[7]] && iqentry_memready[ heads[7] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iqentry_memready[heads[0]]
					//&& ~iqentry_memready[heads[1]] 
					//&& ~iqentry_memready[heads[2]] 
					//&& ~iqentry_memready[heads[3]] 
					//&& ~iqentry_memready[heads[4]] 
					//&& ~iqentry_memready[heads[5]] 
					//&& ~iqentry_memready[heads[6]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[heads[0]] || (iqentry_agen[heads[0]] & iqentry_out[heads[0]]) || iqentry_done[heads[0]]
						|| ((iqentry_ma[heads[7]][AMSB:3] != iqentry_ma[heads[0]][AMSB:3] || iqentry_out[heads[0]] || iqentry_done[heads[0]])))
					&& (!iqentry_mem[heads[1]] || (iqentry_agen[heads[1]] & iqentry_out[heads[1]]) || iqentry_done[heads[1]]
						|| ((iqentry_ma[heads[7]][AMSB:3] != iqentry_ma[heads[1]][AMSB:3] || iqentry_out[heads[1]] || iqentry_done[heads[1]])))
					&& (!iqentry_mem[heads[2]] || (iqentry_agen[heads[2]] & iqentry_out[heads[2]]) || iqentry_done[heads[2]] 
						|| ((iqentry_ma[heads[7]][AMSB:3] != iqentry_ma[heads[2]][AMSB:3] || iqentry_out[heads[2]] || iqentry_done[heads[2]])))
					&& (!iqentry_mem[heads[3]] || (iqentry_agen[heads[3]] & iqentry_out[heads[3]]) || iqentry_done[heads[3]] 
						|| ((iqentry_ma[heads[7]][AMSB:3] != iqentry_ma[heads[3]][AMSB:3] || iqentry_out[heads[3]] || iqentry_done[heads[3]])))
					&& (!iqentry_mem[heads[4]] || (iqentry_agen[heads[4]] & iqentry_out[heads[4]]) || iqentry_done[heads[4]] 
						|| ((iqentry_ma[heads[7]][AMSB:3] != iqentry_ma[heads[4]][AMSB:3] || iqentry_out[heads[4]] || iqentry_done[heads[4]])))
					&& (!iqentry_mem[heads[5]] || (iqentry_agen[heads[5]] & iqentry_out[heads[5]]) || iqentry_done[heads[5]] 
						|| ((iqentry_ma[heads[7]][AMSB:3] != iqentry_ma[heads[5]][AMSB:3] || iqentry_out[heads[5]] || iqentry_done[heads[5]])))
					&& (!iqentry_mem[heads[6]] || (iqentry_agen[heads[6]] & iqentry_out[heads[6]]) || iqentry_done[heads[6]] 
						|| ((iqentry_ma[heads[7]][AMSB:3] != iqentry_ma[heads[6]][AMSB:3] || iqentry_out[heads[6]] || iqentry_done[heads[6]])))
					&& (iqentry_rl[heads[7]] ? (iqentry_done[heads[0]] || !iqentry_v[heads[0]] || !iqentry_mem[heads[0]])
										 && (iqentry_done[heads[1]] || !iqentry_v[heads[1]] || !iqentry_mem[heads[1]])
										 && (iqentry_done[heads[2]] || !iqentry_v[heads[2]] || !iqentry_mem[heads[2]])
										 && (iqentry_done[heads[3]] || !iqentry_v[heads[3]] || !iqentry_mem[heads[3]])
										 && (iqentry_done[heads[4]] || !iqentry_v[heads[4]] || !iqentry_mem[heads[4]])
										 && (iqentry_done[heads[5]] || !iqentry_v[heads[5]] || !iqentry_mem[heads[5]])
										 && (iqentry_done[heads[6]] || !iqentry_v[heads[6]] || !iqentry_mem[heads[6]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iqentry_aq[heads[0]] && iqentry_v[heads[0]])
					&& !(iqentry_aq[heads[1]] && iqentry_v[heads[1]])
					&& !(iqentry_aq[heads[2]] && iqentry_v[heads[2]])
					&& !(iqentry_aq[heads[3]] && iqentry_v[heads[3]])
					&& !(iqentry_aq[heads[4]] && iqentry_v[heads[4]])
					&& !(iqentry_aq[heads[5]] && iqentry_v[heads[5]])
					&& !(iqentry_aq[heads[6]] && iqentry_v[heads[6]])
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iqentry_iv[heads[1]] && iqentry_memsb[heads[1]]) || (iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memsb[heads[2]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                    		)
                    && (!(iqentry_iv[heads[3]] && iqentry_memsb[heads[3]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]]))
                    		)
                    && (!(iqentry_iv[heads[4]] && iqentry_memsb[heads[4]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]]))
                    		)
                    && (!(iqentry_iv[heads[5]] && iqentry_memsb[heads[5]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                    		&&   (iqentry_done[heads[4]] || !iqentry_v[heads[4]]))
                    		)
                    && (!(iqentry_iv[heads[6]] && iqentry_memsb[heads[6]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                    		&&   (iqentry_done[heads[4]] || !iqentry_v[heads[4]])
                    		&&   (iqentry_done[heads[5]] || !iqentry_v[heads[5]]))
                    		)
    				&& (!(iqentry_iv[heads[1]] && iqentry_memdb[heads[1]]) || (!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memdb[heads[2]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                     		)
                    && (!(iqentry_iv[heads[3]] && iqentry_memdb[heads[3]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]]))
                     		)
                    && (!(iqentry_iv[heads[4]] && iqentry_memdb[heads[4]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]]))
                     		)
                    && (!(iqentry_iv[heads[5]] && iqentry_memdb[heads[5]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                     		&& (!iqentry_mem[heads[4]] || iqentry_done[heads[4]] || !iqentry_v[heads[4]]))
                     		)
                    && (!(iqentry_iv[heads[6]] && iqentry_memdb[heads[6]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                     		&& (!iqentry_mem[heads[4]] || iqentry_done[heads[4]] || !iqentry_v[heads[4]])
                     		&& (!iqentry_mem[heads[5]] || iqentry_done[heads[5]] || !iqentry_v[heads[5]]))
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_load[heads[7]] ||
		      		      !(iqentry_fc[heads[0]]||iqentry_canex[heads[0]])
                       && !(iqentry_fc[heads[1]]||iqentry_canex[heads[1]])
                       && !(iqentry_fc[heads[2]]||iqentry_canex[heads[2]])
                       && !(iqentry_fc[heads[3]]||iqentry_canex[heads[3]])
                       && !(iqentry_fc[heads[4]]||iqentry_canex[heads[4]])
                       && !(iqentry_fc[heads[5]]||iqentry_canex[heads[5]])
                       && !(iqentry_fc[heads[6]]||iqentry_canex[heads[6]]));
	 if (memissue[heads[7]])
	 	issue_count = issue_count + 1;
	end

	if (QENTRIES > 8) begin
	memissue[ heads[8] ] =	~iqentry_stomp[heads[8]] && iqentry_memready[ heads[8] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iqentry_memready[heads[0]]
					//&& ~iqentry_memready[heads[1]] 
					//&& ~iqentry_memready[heads[2]] 
					//&& ~iqentry_memready[heads[3]] 
					//&& ~iqentry_memready[heads[4]] 
					//&& ~iqentry_memready[heads[5]] 
					//&& ~iqentry_memready[heads[6]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[heads[0]] || (iqentry_agen[heads[0]] & iqentry_out[heads[0]]) || iqentry_done[heads[0]]
						|| ((iqentry_ma[heads[8]][AMSB:3] != iqentry_ma[heads[0]][AMSB:3] || iqentry_out[heads[0]] || iqentry_done[heads[0]])))
					&& (!iqentry_mem[heads[1]] || (iqentry_agen[heads[1]] & iqentry_out[heads[1]]) || iqentry_done[heads[1]]
						|| ((iqentry_ma[heads[8]][AMSB:3] != iqentry_ma[heads[1]][AMSB:3] || iqentry_out[heads[1]] || iqentry_done[heads[1]])))
					&& (!iqentry_mem[heads[2]] || (iqentry_agen[heads[2]] & iqentry_out[heads[2]]) || iqentry_done[heads[2]] 
						|| ((iqentry_ma[heads[8]][AMSB:3] != iqentry_ma[heads[2]][AMSB:3] || iqentry_out[heads[2]] || iqentry_done[heads[2]])))
					&& (!iqentry_mem[heads[3]] || (iqentry_agen[heads[3]] & iqentry_out[heads[3]]) || iqentry_done[heads[3]] 
						|| ((iqentry_ma[heads[8]][AMSB:3] != iqentry_ma[heads[3]][AMSB:3] || iqentry_out[heads[3]] || iqentry_done[heads[3]])))
					&& (!iqentry_mem[heads[4]] || (iqentry_agen[heads[4]] & iqentry_out[heads[4]]) || iqentry_done[heads[4]] 
						|| ((iqentry_ma[heads[8]][AMSB:3] != iqentry_ma[heads[4]][AMSB:3] || iqentry_out[heads[4]] || iqentry_done[heads[4]])))
					&& (!iqentry_mem[heads[5]] || (iqentry_agen[heads[5]] & iqentry_out[heads[5]]) || iqentry_done[heads[5]] 
						|| ((iqentry_ma[heads[8]][AMSB:3] != iqentry_ma[heads[5]][AMSB:3] || iqentry_out[heads[5]] || iqentry_done[heads[5]])))
					&& (!iqentry_mem[heads[6]] || (iqentry_agen[heads[6]] & iqentry_out[heads[6]]) || iqentry_done[heads[6]] 
						|| ((iqentry_ma[heads[8]][AMSB:3] != iqentry_ma[heads[6]][AMSB:3] || iqentry_out[heads[6]] || iqentry_done[heads[6]])))
					&& (!iqentry_mem[heads[7]] || (iqentry_agen[heads[7]] & iqentry_out[heads[7]]) || iqentry_done[heads[7]] 
						|| ((iqentry_ma[heads[8]][AMSB:3] != iqentry_ma[heads[7]][AMSB:3] || iqentry_out[heads[7]] || iqentry_done[heads[7]])))
					&& (iqentry_rl[heads[8]] ? (iqentry_done[heads[0]] || !iqentry_v[heads[0]] || !iqentry_mem[heads[0]])
										 && (iqentry_done[heads[1]] || !iqentry_v[heads[1]] || !iqentry_mem[heads[1]])
										 && (iqentry_done[heads[2]] || !iqentry_v[heads[2]] || !iqentry_mem[heads[2]])
										 && (iqentry_done[heads[3]] || !iqentry_v[heads[3]] || !iqentry_mem[heads[3]])
										 && (iqentry_done[heads[4]] || !iqentry_v[heads[4]] || !iqentry_mem[heads[4]])
										 && (iqentry_done[heads[5]] || !iqentry_v[heads[5]] || !iqentry_mem[heads[5]])
										 && (iqentry_done[heads[6]] || !iqentry_v[heads[6]] || !iqentry_mem[heads[6]])
										 && (iqentry_done[heads[7]] || !iqentry_v[heads[7]] || !iqentry_mem[heads[7]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iqentry_aq[heads[0]] && iqentry_v[heads[0]])
					&& !(iqentry_aq[heads[1]] && iqentry_v[heads[1]])
					&& !(iqentry_aq[heads[2]] && iqentry_v[heads[2]])
					&& !(iqentry_aq[heads[3]] && iqentry_v[heads[3]])
					&& !(iqentry_aq[heads[4]] && iqentry_v[heads[4]])
					&& !(iqentry_aq[heads[5]] && iqentry_v[heads[5]])
					&& !(iqentry_aq[heads[6]] && iqentry_v[heads[6]])
					&& !(iqentry_aq[heads[7]] && iqentry_v[heads[7]])
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iqentry_iv[heads[1]] && iqentry_memsb[heads[1]]) || (iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memsb[heads[2]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                    		)
                    && (!(iqentry_iv[heads[3]] && iqentry_memsb[heads[3]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]]))
                    		)
                    && (!(iqentry_iv[heads[4]] && iqentry_memsb[heads[4]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]]))
                    		)
                    && (!(iqentry_iv[heads[5]] && iqentry_memsb[heads[5]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                    		&&   (iqentry_done[heads[4]] || !iqentry_v[heads[4]]))
                    		)
                    && (!(iqentry_iv[heads[6]] && iqentry_memsb[heads[6]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                    		&&   (iqentry_done[heads[4]] || !iqentry_v[heads[4]])
                    		&&   (iqentry_done[heads[5]] || !iqentry_v[heads[5]]))
                    		)
                    && (!(iqentry_iv[heads[7]] && iqentry_memsb[heads[7]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                    		&&   (iqentry_done[heads[4]] || !iqentry_v[heads[4]])
                    		&&   (iqentry_done[heads[5]] || !iqentry_v[heads[5]])
                    		&&   (iqentry_done[heads[6]] || !iqentry_v[heads[6]])
                    		)
                    		)
    				&& (!(iqentry_iv[heads[1]] && iqentry_memdb[heads[1]]) || (!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memdb[heads[2]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                     		)
                    && (!(iqentry_iv[heads[3]] && iqentry_memdb[heads[3]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]]))
                     		)
                    && (!(iqentry_iv[heads[4]] && iqentry_memdb[heads[4]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]]))
                     		)
                    && (!(iqentry_iv[heads[5]] && iqentry_memdb[heads[5]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                     		&& (!iqentry_mem[heads[4]] || iqentry_done[heads[4]] || !iqentry_v[heads[4]]))
                     		)
                    && (!(iqentry_iv[heads[6]] && iqentry_memdb[heads[6]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                     		&& (!iqentry_mem[heads[4]] || iqentry_done[heads[4]] || !iqentry_v[heads[4]])
                     		&& (!iqentry_mem[heads[5]] || iqentry_done[heads[5]] || !iqentry_v[heads[5]]))
                     		)
                    && (!(iqentry_iv[heads[7]] && iqentry_memdb[heads[7]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                     		&& (!iqentry_mem[heads[4]] || iqentry_done[heads[4]] || !iqentry_v[heads[4]])
                     		&& (!iqentry_mem[heads[5]] || iqentry_done[heads[5]] || !iqentry_v[heads[5]])
                     		&& (!iqentry_mem[heads[6]] || iqentry_done[heads[6]] || !iqentry_v[heads[6]])
                     		)
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iqentry_load[heads[8]] ||
		      		      !(iqentry_fc[heads[0]]||iqentry_canex[heads[0]])
                       && !(iqentry_fc[heads[1]]||iqentry_canex[heads[1]])
                       && !(iqentry_fc[heads[2]]||iqentry_canex[heads[2]])
                       && !(iqentry_fc[heads[3]]||iqentry_canex[heads[3]])
                       && !(iqentry_fc[heads[4]]||iqentry_canex[heads[4]])
                       && !(iqentry_fc[heads[5]]||iqentry_canex[heads[5]])
                       && !(iqentry_fc[heads[6]]||iqentry_canex[heads[6]])
                       && !(iqentry_fc[heads[7]]||iqentry_canex[heads[7]])
                       );
	 if (memissue[heads[8]])
	 	issue_count = issue_count + 1;
	end

	if (QENTRIES > 9) begin
	memissue[ heads[9] ] =	~iqentry_stomp[heads[9]] && iqentry_memready[ heads[9] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iqentry_memready[heads[0]]
					//&& ~iqentry_memready[heads[1]] 
					//&& ~iqentry_memready[heads[2]] 
					//&& ~iqentry_memready[heads[3]] 
					//&& ~iqentry_memready[heads[4]] 
					//&& ~iqentry_memready[heads[5]] 
					//&& ~iqentry_memready[heads[6]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iqentry_mem[heads[0]] || (iqentry_agen[heads[0]] & iqentry_out[heads[0]]) || iqentry_done[heads[0]]
						|| ((iqentry_ma[heads[9]][AMSB:3] != iqentry_ma[heads[0]][AMSB:3] || iqentry_out[heads[0]] || iqentry_done[heads[0]])))
					&& (!iqentry_mem[heads[1]] || (iqentry_agen[heads[1]] & iqentry_out[heads[1]]) || iqentry_done[heads[1]]
						|| ((iqentry_ma[heads[9]][AMSB:3] != iqentry_ma[heads[1]][AMSB:3] || iqentry_out[heads[1]] || iqentry_done[heads[1]])))
					&& (!iqentry_mem[heads[2]] || (iqentry_agen[heads[2]] & iqentry_out[heads[2]]) || iqentry_done[heads[2]] 
						|| ((iqentry_ma[heads[9]][AMSB:3] != iqentry_ma[heads[2]][AMSB:3] || iqentry_out[heads[2]] || iqentry_done[heads[2]])))
					&& (!iqentry_mem[heads[3]] || (iqentry_agen[heads[3]] & iqentry_out[heads[3]]) || iqentry_done[heads[3]] 
						|| ((iqentry_ma[heads[9]][AMSB:3] != iqentry_ma[heads[3]][AMSB:3] || iqentry_out[heads[3]] || iqentry_done[heads[3]])))
					&& (!iqentry_mem[heads[4]] || (iqentry_agen[heads[4]] & iqentry_out[heads[4]]) || iqentry_done[heads[4]] 
						|| ((iqentry_ma[heads[9]][AMSB:3] != iqentry_ma[heads[4]][AMSB:3] || iqentry_out[heads[4]] || iqentry_done[heads[4]])))
					&& (!iqentry_mem[heads[5]] || (iqentry_agen[heads[5]] & iqentry_out[heads[5]]) || iqentry_done[heads[5]] 
						|| ((iqentry_ma[heads[9]][AMSB:3] != iqentry_ma[heads[5]][AMSB:3] || iqentry_out[heads[5]] || iqentry_done[heads[5]])))
					&& (!iqentry_mem[heads[6]] || (iqentry_agen[heads[6]] & iqentry_out[heads[6]]) || iqentry_done[heads[6]] 
						|| ((iqentry_ma[heads[9]][AMSB:3] != iqentry_ma[heads[6]][AMSB:3] || iqentry_out[heads[6]] || iqentry_done[heads[6]])))
					&& (!iqentry_mem[heads[7]] || (iqentry_agen[heads[7]] & iqentry_out[heads[7]]) || iqentry_done[heads[7]] 
						|| ((iqentry_ma[heads[9]][AMSB:3] != iqentry_ma[heads[7]][AMSB:3] || iqentry_out[heads[7]] || iqentry_done[heads[7]])))
					&& (!iqentry_mem[heads[8]] || (iqentry_agen[heads[8]] & iqentry_out[heads[8]]) || iqentry_done[heads[8]] 
						|| ((iqentry_ma[heads[9]][AMSB:3] != iqentry_ma[heads[8]][AMSB:3] || iqentry_out[heads[8]] || iqentry_done[heads[8]])))
					&& (iqentry_rl[heads[9]] ? (iqentry_done[heads[0]] || !iqentry_v[heads[0]] || !iqentry_mem[heads[0]])
										 && (iqentry_done[heads[1]] || !iqentry_v[heads[1]] || !iqentry_mem[heads[1]])
										 && (iqentry_done[heads[2]] || !iqentry_v[heads[2]] || !iqentry_mem[heads[2]])
										 && (iqentry_done[heads[3]] || !iqentry_v[heads[3]] || !iqentry_mem[heads[3]])
										 && (iqentry_done[heads[4]] || !iqentry_v[heads[4]] || !iqentry_mem[heads[4]])
										 && (iqentry_done[heads[5]] || !iqentry_v[heads[5]] || !iqentry_mem[heads[5]])
										 && (iqentry_done[heads[6]] || !iqentry_v[heads[6]] || !iqentry_mem[heads[6]])
										 && (iqentry_done[heads[7]] || !iqentry_v[heads[7]] || !iqentry_mem[heads[7]])
										 && (iqentry_done[heads[8]] || !iqentry_v[heads[8]] || !iqentry_mem[heads[8]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iqentry_aq[heads[0]] && iqentry_v[heads[0]])
					&& !(iqentry_aq[heads[1]] && iqentry_v[heads[1]])
					&& !(iqentry_aq[heads[2]] && iqentry_v[heads[2]])
					&& !(iqentry_aq[heads[3]] && iqentry_v[heads[3]])
					&& !(iqentry_aq[heads[4]] && iqentry_v[heads[4]])
					&& !(iqentry_aq[heads[5]] && iqentry_v[heads[5]])
					&& !(iqentry_aq[heads[6]] && iqentry_v[heads[6]])
					&& !(iqentry_aq[heads[7]] && iqentry_v[heads[7]])
					&& !(iqentry_aq[heads[8]] && iqentry_v[heads[8]])
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iqentry_iv[heads[1]] && iqentry_memsb[heads[1]]) || (iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memsb[heads[2]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                    		)
                    && (!(iqentry_iv[heads[3]] && iqentry_memsb[heads[3]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]]))
                    		)
                    && (!(iqentry_iv[heads[4]] && iqentry_memsb[heads[4]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]]))
                    		)
                    && (!(iqentry_iv[heads[5]] && iqentry_memsb[heads[5]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                    		&&   (iqentry_done[heads[4]] || !iqentry_v[heads[4]]))
                    		)
                    && (!(iqentry_iv[heads[6]] && iqentry_memsb[heads[6]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                    		&&   (iqentry_done[heads[4]] || !iqentry_v[heads[4]])
                    		&&   (iqentry_done[heads[5]] || !iqentry_v[heads[5]]))
                    		)
                    && (!(iqentry_iv[heads[7]] && iqentry_memsb[heads[7]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                    		&&   (iqentry_done[heads[4]] || !iqentry_v[heads[4]])
                    		&&   (iqentry_done[heads[5]] || !iqentry_v[heads[5]])
                    		&&   (iqentry_done[heads[6]] || !iqentry_v[heads[6]]))
                    		)
                    && (!(iqentry_iv[heads[8]] && iqentry_memsb[heads[8]]) ||
                    			((iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                    		&&   (iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                    		&&   (iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                    		&&   (iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                    		&&   (iqentry_done[heads[4]] || !iqentry_v[heads[4]])
                    		&&   (iqentry_done[heads[5]] || !iqentry_v[heads[5]])
                    		&&   (iqentry_done[heads[6]] || !iqentry_v[heads[6]])
                    		&&   (iqentry_done[heads[7]] || !iqentry_v[heads[7]])
                    		)
                    		)
    				&& (!(iqentry_iv[heads[1]] && iqentry_memdb[heads[1]]) || (!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]]))
                    && (!(iqentry_iv[heads[2]] && iqentry_memdb[heads[2]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]]))
                     		)
                    && (!(iqentry_iv[heads[3]] && iqentry_memdb[heads[3]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]]))
                     		)
                    && (!(iqentry_iv[heads[4]] && iqentry_memdb[heads[4]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]]))
                     		)
                    && (!(iqentry_iv[heads[5]] && iqentry_memdb[heads[5]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                     		&& (!iqentry_mem[heads[4]] || iqentry_done[heads[4]] || !iqentry_v[heads[4]]))
                     		)
                    && (!(iqentry_iv[heads[6]] && iqentry_memdb[heads[6]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                     		&& (!iqentry_mem[heads[4]] || iqentry_done[heads[4]] || !iqentry_v[heads[4]])
                     		&& (!iqentry_mem[heads[5]] || iqentry_done[heads[5]] || !iqentry_v[heads[5]]))
                     		)
                    && (!(iqentry_iv[heads[7]] && iqentry_memdb[heads[7]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                     		&& (!iqentry_mem[heads[4]] || iqentry_done[heads[4]] || !iqentry_v[heads[4]])
                     		&& (!iqentry_mem[heads[5]] || iqentry_done[heads[5]] || !iqentry_v[heads[5]])
                     		&& (!iqentry_mem[heads[6]] || iqentry_done[heads[6]] || !iqentry_v[heads[6]]))
                     		)
                    && (!(iqentry_iv[heads[8]] && iqentry_memdb[heads[8]]) ||
                     		  ((!iqentry_mem[heads[0]] || iqentry_done[heads[0]] || !iqentry_v[heads[0]])
                     		&& (!iqentry_mem[heads[1]] || iqentry_done[heads[1]] || !iqentry_v[heads[1]])
                     		&& (!iqentry_mem[heads[2]] || iqentry_done[heads[2]] || !iqentry_v[heads[2]])
                     		&& (!iqentry_mem[heads[3]] || iqentry_done[heads[3]] || !iqentry_v[heads[3]])
                     		&& (!iqentry_mem[heads[4]] || iqentry_done[heads[4]] || !iqentry_v[heads[4]])
                     		&& (!iqentry_mem[heads[5]] || iqentry_done[heads[5]] || !iqentry_v[heads[5]])
                     		&& (!iqentry_mem[heads[6]] || iqentry_done[heads[6]] || !iqentry_v[heads[6]])
                     		&& (!iqentry_mem[heads[7]] || iqentry_done[heads[7]] || !iqentry_v[heads[7]])
                     		)
                     		)
					// ... and, if it is a store, there is no chance of it being undone
					&& (iqentry_load[heads[9]] ||
		      		      !(iqentry_fc[heads[0]]||iqentry_canex[heads[0]])
                       && !(iqentry_fc[heads[1]]||iqentry_canex[heads[1]])
                       && !(iqentry_fc[heads[2]]||iqentry_canex[heads[2]])
                       && !(iqentry_fc[heads[3]]||iqentry_canex[heads[3]])
                       && !(iqentry_fc[heads[4]]||iqentry_canex[heads[4]])
                       && !(iqentry_fc[heads[5]]||iqentry_canex[heads[5]])
                       && !(iqentry_fc[heads[6]]||iqentry_canex[heads[6]])
                       && !(iqentry_fc[heads[7]]||iqentry_canex[heads[7]])
                       && !(iqentry_fc[heads[8]]||iqentry_canex[heads[8]])
                       );
	 if (memissue[heads[9]])
	 	issue_count = issue_count + 1;
	end
end
end
endgenerate
`endif

// Starts search for instructions to issue at the head of the queue and 
// progresses from there. This ensures that the oldest instructions are
// selected first for processing.
always @*
begin
	last_issue0 = QENTRIES;
	last_issue1 = QENTRIES;
	last_issue2 = QENTRIES;
	for (n = 0; n < QENTRIES; n = n + 1)
    if (~iqentry_stomp[heads[n]] && iqentry_memissue[heads[n]] && iqentry_agen[heads[n]] && ~iqentry_out[heads[n]] && ~iqentry_done[heads[n]]) begin
      if (mem1_available && dram0 == `DRAMSLOT_AVAIL) begin
       last_issue0 = heads[n];
      end
    end
	for (n = 0; n < QENTRIES; n = n + 1)
    if (~iqentry_stomp[heads[n]] && iqentry_memissue[heads[n]] && iqentry_agen[heads[n]] && ~iqentry_out[heads[n]] && ~iqentry_done[heads[n]]) begin
    	if (mem2_available && heads[n] != last_issue0 && `NUM_MEM > 1) begin
        if (dram1 == `DRAMSLOT_AVAIL) begin
					last_issue1 = heads[n];
        end
    	end
    end
	for (n = 0; n < QENTRIES; n = n + 1)
    if (~iqentry_stomp[heads[n]] && iqentry_memissue[heads[n]] && iqentry_agen[heads[n]] && ~iqentry_out[heads[n]] && ~iqentry_done[heads[n]]) begin
    	if (mem3_available && heads[n] != last_issue0 && heads[n] != last_issue1 && `NUM_MEM > 2) begin
        if (dram2 == `DRAMSLOT_AVAIL) begin
        	last_issue2 = heads[n];
        end
    	end
    end
end

reg [2:0] wbptr;
// Stomp logic for branch miss.
/*
FT64_stomp #(QENTRIES) ustmp1
(
	.branchmiss(branchmiss),
	.branchmiss_thrd(branchmiss_thrd),
	.missid(missid),
	.head0(heads[0]),
	.thrd(iqentry_thrd),
	.iqentry_v(iqentry_v),
	.stomp(iqentry_stomp)
);
*/
always @*
begin
	iqentry_stomp <= 1'b0;
	if (branchmiss) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (iqentry_v[n] && iqentry_thrd[n]==branchmiss_thrd) begin
				if (iqentry_sn[n] > iqentry_sn[missid[`QBITS]])
					iqentry_stomp[n] <= `TRUE;
			end
		end
	end
	/*
	if (fcu_branchmiss) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (iqentry_v[n] && iqentry_thrd[n]==fcu_thrd) begin
				if (iqentry_sn[n] > iqentry_sn[fcu_id[`QBITS]])
					iqentry_stomp[n] <= `TRUE;
			end
		end
	end
	*/
end

always @*
begin
	stompedOnRets = 1'b0;
	for (n = 0; n < QENTRIES; n = n + 1)
		if (iqentry_stomp[n] && iqentry_ret[n])
			stompedOnRets = stompedOnRets + 4'd1;
end

reg id1_vi, id2_vi, id3_vi;
wire [4:0] id1_ido, id2_ido, id3_ido;
wire id1_vo, id2_vo, id3_vo;
wire id1_clk, id2_clk, id3_clk;

// Always at least one decoder
assign id1_clk = clk_i;
//BUFGCE uclkb2
//(
//	.I(clk_i),
//	.CE(id1_available),
//	.O(id1_clk)
//);

FT64_idecoder uid1
(
	.clk(id1_clk),
	.idv_i(id1_vi),
	.id_i(id1_id),
`ifdef INLINE_DECODE
	.instr(fetchbuf0_instr),
`else
	.instr(id1_instr),
`endif
	.ven(id1_ven),
	.vl(id1_vl),
	.thrd(id1_thrd),
	.predict_taken(id1_pt),
	.Rt(id1_Rt),
	.bus(id1_bus),
	.id_o(id1_ido),
	.idv_o(id1_vo)
);

generate begin : gIDUInst
if (`NUM_IDU > 1) begin
//BUFGCE uclkb3
//(
//	.I(clk_i),
//	.CE(id2_available),
//	.O(id2_clk)
//);
assign id2_clk = clk_i;

FT64_idecoder uid2
(
	.clk(id2_clk),
	.idv_i(id2_vi),
	.id_i(id2_id),
`ifdef INLINE_DECODE
	.instr(fetchbuf1_instr),
`else
	.instr(id2_instr),
`endif
	.ven(id2_ven),
	.vl(id2_vl),
	.thrd(id2_thrd),
	.predict_taken(id2_pt),
	.Rt(id2_Rt),
	.bus(id2_bus),
	.id_o(id2_ido),
	.idv_o(id2_vo)
);
end
if (`NUM_IDU > 2) begin
//BUFGCE uclkb4
//(
//	.I(clk_i),
//	.CE(id3_available),
//	.O(id3_clk)
//);
assign id3_clk = clk_i;

FT64_idecoder uid2
(
	.clk(id3_clk),
	.idv_i(id3_vi),
	.id_i(id3_id),
`ifdef INLINE_DECODE
	.instr(fetchbuf2_instr),
`else
	.instr(id3_instr),
`endif
	.ven(id3_ven),
	.vl(id3_vl),
	.thrd(id3_thrd),
	.predict_taken(id3_pt),
	.Rt(id3_Rt),
	.bus(id3_bus),
	.id_o(id3_ido),
	.idv_o(id3_vo)
);
end
end
endgenerate

//
// EXECUTE
//
reg [63:0] csr_r;
always @*
    read_csr(alu0_instr[29:18],csr_r,alu0_thrd);
FT64_alu #(.BIG(1'b1),.SUP_VECTOR(SUP_VECTOR)) ualu0 (
  .rst(rst),
  .clk(clk),
  .ld(alu0_ld),
  .abort(1'b0),
  .instr(alu0_instr),
  .sz(alu0_sz),
  .tlb(alu0_tlb),
  .a(alu0_argA),
  .b(alu0_argB),
  .c(alu0_argC),
  .pc(alu0_pc),
//    .imm(alu0_argI),
  .tgt(alu0_tgt),
  .ven(alu0_ven),
  .vm(vm[alu0_instr[25:23]]),
  .sbl(sbl),
  .sbu(sbu),
  .csr(csr_r),
  .o(alu0_bus),
  .ob(alu0b_bus),
  .done(alu0_done),
  .idle(alu0_idle),
  .excen(aec[4:0]),
  .exc(alu0_exc),
  .thrd(alu0_thrd),
  .mem(alu0_mem),
  .shift(alu0_shft),
  .ol(ol),
  .ASID(ASID),
  .icl_i(icl_o),
  .cyc_i(cyc),
  .we_i(we),
  .vadr_i(vadr),
  .cyc_o(cyc_o),
  .we_o(we_o),
  .padr_o(adr_o),
  .uncached(),
  .tlb_miss(tlb_miss),
  .exv_o(exv_i),
  .wrv_o(wrv_i),
  .rdv_o(rdv_i)
);
generate begin : gAluInst
if (`NUM_ALU > 1) begin
FT64_alu #(.BIG(1'b0),.SUP_VECTOR(SUP_VECTOR)) ualu1 (
  .rst(rst),
  .clk(clk),
  .ld(alu1_ld),
  .abort(1'b0),
  .instr(alu1_instr),
  .sz(alu1_sz),
  .tlb(1'b0),
  .a(alu1_argA),
  .b(alu1_argB),
  .c(alu1_argC),
  .pc(alu1_pc),
  //.imm(alu1_argI),
  .tgt(alu1_tgt),
  .ven(alu1_ven),
  .vm(vm[alu1_instr[25:23]]),
  .sbl(sbl),
  .sbu(sbu),
  .csr(64'd0),
  .o(alu1_bus),
  .ob(alu1b_bus),
  .done(alu1_done),
  .idle(alu1_idle),
  .excen(aec[4:0]),
  .exc(alu1_exc),
  .thrd(1'b0),
  .mem(alu1_mem),
  .shift(alu1_shft),
  .ol(2'b0),
  .ASID(8'h0),
  .cyc_i(1'b0),
  .we_i(1'b0),
  .vadr_i(64'd0),
  .cyc_o(),
  .we_o(),
  .padr_o(),
  .uncached(),
  .tlb_miss(),
  .exv_o(),
  .wrv_o(),
  .rdv_o()
);
end
end
endgenerate

generate begin : gFPUInst
if (`NUM_FPU > 0) begin
wire fpu1_clk;
//BUFGCE ufpc1
//(
//	.I(clk_i),
//	.CE(fpu1_available),
//	.O(fpu1_clk)
//);
assign fpu1_clk = clk_i;

fpUnit ufp1
(
  .rst(rst),
  .clk(fpu1_clk),
  .clk4x(clk4x),
  .ce(1'b1),
  .ir(fpu1_instr),
  .ld(fpu1_ld),
  .a(fpu1_argA),
  .b(fpu1_argB),
  .imm(fpu1_argI),
  .o(fpu1_bus),
  .csr_i(),
  .status(fpu1_status),
  .exception(),
  .done(fpu1_done)
);
end
if (`NUM_FPU > 1) begin
wire fpu2_clk;
//BUFGCE ufpc2
//(
//	.I(clk_i),
//	.CE(fpu2_available),
//	.O(fpu2_clk)
//);
assign fpu2_clk = clk_i;
fpUnit ufp1
(
  .rst(rst),
  .clk(fpu2_clk),
  .clk4x(clk4x),
  .ce(1'b1),
  .ir(fpu2_instr),
  .ld(fpu2_ld),
  .a(fpu2_argA),
  .b(fpu2_argB),
  .imm(fpu2_argI),
  .o(fpu2_bus),
  .csr_i(),
  .status(fpu2_status),
  .exception(),
  .done(fpu2_done)
);
end
end
endgenerate

assign fpu1_exc = (fpu1_available) ? 
									((|fpu1_status[15:0]) ? `FLT_FLT : `FLT_NONE) : `FLT_UNIMP;
assign fpu2_exc = (fpu2_available) ? 
									((|fpu2_status[15:0]) ? `FLT_FLT : `FLT_NONE) : `FLT_UNIMP;

assign  alu0_v = alu0_dataready,
        alu1_v = alu1_dataready;
assign  alu0_id = alu0_sourceid,
 	    alu1_id = alu1_sourceid;
assign  fpu1_v = fpu1_dataready;
assign  fpu1_id = fpu1_sourceid;
assign  fpu2_v = fpu2_dataready;
assign  fpu2_id = fpu2_sourceid;

`ifdef SUPPORT_SMT
wire [1:0] olm = ol[fcu_thrd];
`else
wire [1:0] olm = ol;
`endif

reg [`SNBITS] maxsn [0:`WAYS-1];
always @*
begin
	for (j = 0; j < `WAYS; j = j + 1) begin
		maxsn[j] = 8'd0;
		for (n = 0; n < QENTRIES; n = n + 1)
			if (iqentry_sn[n] > maxsn[j] && iqentry_thrd[n]==j && iqentry_v[n])
				maxsn[j] = iqentry_sn[n];
		maxsn[j] = maxsn[j] - tosub;
	end
end

assign  fcu_v = fcu_dataready;
assign  fcu_id = fcu_sourceid;

wire [4:0] fcmpo;
wire fnanx;
fp_cmp_unit #(64) ufcmp1 (fcu_argA, fcu_argB, fcmpo, fnanx);

wire fcu_takb;

always @*
begin
    fcu_exc <= `FLT_NONE;
    casez(fcu_instr[`INSTRUCTION_OP])
    `CHK:   begin
                if (fcu_instr[21])
                    fcu_exc <= fcu_argA >= fcu_argB && fcu_argA < fcu_argC ? `FLT_NONE : `FLT_CHK;
            end
    `REX:
        case(olm)
        `OL_USER:   fcu_exc <= `FLT_PRIV;
        default:    ;
        endcase
   default: fcu_exc <= `FLT_NONE;
	endcase
end

FT64_EvalBranch ube1
(
	.instr(fcu_instr),
	.a(fcu_argA),
	.b(fcu_argB),
	.c(fcu_argC),
	.takb(fcu_takb)
);

FT64_FCU_Calc #(.AMSB(AMSB)) ufcuc1
(
	.ol(olm),
	.instr(fcu_instr),
	.tvec(tvec[fcu_instr[14:13]]),
	.a(fcu_argA),
	.pc(fcu_pc),
	.nextpc(fcu_nextpc),
	.im(im),
	.waitctr(waitctr),
	.bus(fcu_bus)
);

always @*
begin
case(fcu_instr[`INSTRUCTION_OP])
`R2:	fcu_misspc = fcu_argB;	// RTI (we don't bother fully decoding this as it's the only R2)
`RET:	fcu_misspc = fcu_argB;
`REX:	fcu_misspc = fcu_bus;
`BRK:	fcu_misspc = {tvec[0][AMSB:8], 1'b0, olm, 5'h0};
`JAL:	fcu_misspc = fcu_argA + fcu_argI;
//`CHK:	fcu_misspc = fcu_nextpc + fcu_argI;	// Handled as an instruction exception
// Default: branch
default:	fcu_misspc = fcu_takb ? {fcu_pc[31:8] + fcu_brdisp[31:8],fcu_brdisp[7:0]} : fcu_nextpc;
endcase
fcu_misspc[0] = 1'b0;
end

// To avoid false branch mispredicts the branch isn't evaluated until the
// following instruction queues. The address of the next instruction is
// looked at to see if the BTB predicted correctly.

wire fcu_brk_miss = (fcu_brk || fcu_rti) && fcu_v;
`ifdef FCU_ENH
wire fcu_ret_miss = fcu_ret && fcu_v && (fcu_argB != iqentry_pc[nid]);
wire fcu_jal_miss = fcu_jal && fcu_v && fcu_argA + fcu_argI != iqentry_pc[nid];
wire fcu_followed = iqentry_sn[nid] > iqentry_sn[fcu_id[`QBITS]];
`else
wire fcu_ret_miss = fcu_ret && fcu_v;
wire fcu_jal_miss = fcu_jal && fcu_v;
wire fcu_followed = `TRUE;
`endif
always @*
if (fcu_dataready) begin
//	if (fcu_timeout[7])
//		fcu_branchmiss = TRUE;
	// Break and RTI switch register sets, and so are always treated as a branch miss in order to
	// flush the pipeline. Hardware interrupts also stream break instructions so they need to 
	// flushed from the queue so the interrupt is recognized only once.
	// BRK and RTI are handled as excmiss types which are processed during the commit stage.
//	else
	if (fcu_brk_miss)
		fcu_branchmiss = TRUE & ~fcu_clearbm;
	else if (fcu_branch && fcu_v && (fcu_takb ^ fcu_pt))
    fcu_branchmiss = TRUE & ~fcu_clearbm;
  // the following instruction is queued
	else
	if (fcu_followed) begin
`ifdef SUPPORT_SMT		
		if (fcu_instr[`INSTRUCTION_OP] == `REX && (im < ~ol[fcu_thrd]) && fcu_v)
`else
		if (fcu_instr[`INSTRUCTION_OP] == `REX && (im < ~ol) && fcu_v)
`endif		
			fcu_branchmiss = TRUE & ~fcu_clearbm;
		else if (fcu_ret_miss)
			fcu_branchmiss = TRUE & ~fcu_clearbm;
//		else if (fcu_branch && fcu_v && (((fcu_takb && (fcu_misspc != iqentry_pc[nid])) ||
//		                            (~fcu_takb && (fcu_pc + fcu_insln != iqentry_pc[nid])))))// || iqentry_v[nid]))
		else if (fcu_jal_miss)
		    fcu_branchmiss = TRUE & ~fcu_clearbm;
		else if (fcu_instr[`INSTRUCTION_OP] == `CHK && ~fcu_takb && fcu_v)
		    fcu_branchmiss = TRUE & ~fcu_clearbm;
		else
		    fcu_branchmiss = FALSE;
	end
	else begin
		// Stuck at the head and can't finish because there's still an uncommitted instruction in the queue.
		// -> cause a branch miss to clear the queue.
		if (iqentry_v[nid] && !IsCall(fcu_instr) && !IsJmp(fcu_instr) && fcu_v)
			fcu_branchmiss = TRUE & ~fcu_clearbm;
		else
		/*
		if (fcu_id==heads[0] && iqentry_v[idp1(heads[0])]) begin
			if ((fcu_bus[0] && (~fcu_bt || (fcu_misspc == iqentry_pc[nid]))) ||
		                            (~fcu_bus[0] && ( fcu_bt || (fcu_pc + 32'd4 == iqentry_pc[nid]))))
		        fcu_branchmiss = FALSE;
		    else
				fcu_branchmiss = TRUE;
		end
		else if (fcu_id==heads[1] && iqentry_v[idp2(heads[1])]) begin
			if ((fcu_bus[0] && (~fcu_bt || (fcu_misspc == iqentry_pc[nid]))) ||
		                            (~fcu_bus[0] && ( fcu_bt || (fcu_pc + 32'd4 == iqentry_pc[nid]))))
		        fcu_branchmiss = FALSE;
		    else
				fcu_branchmiss = TRUE;
		end
		else*/
			fcu_branchmiss = FALSE;
	end
end
else
	fcu_branchmiss = FALSE;

// Flow control ops don't issue until the next instruction queues.
// The fcu_timeout tracks how long the flow control op has been in the "out" state.
// It should never be that way more than a couple of cycles. Sometimes the fcu_wr pulse got missed
// because the following instruction got stomped on during a branchmiss, hence iqentry_v isn't true.
wire fcu_wr = (fcu_v && iqentry_v[fcu_id[`QBITS]] && iqentry_iv[fcu_id[`QBITS]] && iqentry_v[nid] && iqentry_sn[nid] > iqentry_sn[fcu_id[`QBITS]] && !fcu_done);//	// && iqentry_v[nid]
//					&& fcu_instr==iqentry_instr[fcu_id[`QBITS]]);// || fcu_timeout==8'h05;

FT64_RMW_alu urmwalu0 (rmw_instr, rmw_argA, rmw_argB, rmw_argC, rmw_res);

//assign fcu_done = IsWait(fcu_instr) ? ((waitctr==64'd1) || signal_i[fcu_argA[4:0]|fcu_argI[4:0]]) :
//					fcu_v && iqentry_v[idp1(fcu_id)] && iqentry_sn[idp1(fcu_id)]==iqentry_sn[fcu_id[`QBITS]]+5'd1;

// An exception in a committing instruction takes precedence
/*
Too slow. Needs to be registered
assign  branchmiss = excmiss|fcu_branchmiss,
    misspc = excmiss ? excmisspc : fcu_misspc,
    missid = excmiss ? (|iqentry_exc[heads[0]] ? heads[0] : heads[1]) : fcu_sourceid;
assign branchmiss_thrd =  excmiss ? excthrd : fcu_thrd;
*/

//
// additional DRAM-enqueue logic

assign dram_avail = (dram0 == `DRAMSLOT_AVAIL || dram1 == `DRAMSLOT_AVAIL || dram2 == `DRAMSLOT_AVAIL);

always @*
for (n = 0; n < QENTRIES; n = n + 1)
	iqentry_memopsvalid[n] <= (iqentry_mem[n] & (iqentry_store ? iqentry_a2_v[n] : 1'b1) & iqentry_agen[n]);

always @*
for (n = 0; n < QENTRIES; n = n + 1)
	iqentry_memready[n] <= (iqentry_v[n] & iqentry_iv[n] & iqentry_memopsvalid[n] & ~iqentry_memissue[n] & ~iqentry_done[n] & ~iqentry_out[n] & ~iqentry_stomp[n]);

assign outstanding_stores = (dram0 && dram0_store) ||
                            (dram1 && dram1_store) ||
                            (dram2 && dram2_store);

//
// additional COMMIT logic
//
always @*
begin
    commit0_v <= ({iqentry_v[heads[0]], iqentry_cmt[heads[0]]} == 2'b11 && ~|panic);
    commit0_id <= {iqentry_mem[heads[0]], heads[0]};	// if a memory op, it has a DRAM-bus id
    commit0_tgt <= iqentry_tgt[heads[0]];
    commit0_we  <= iqentry_we[heads[0]];
    commit0_bus <= iqentry_res[heads[0]];
    if (`NUM_CMT > 1) begin
	    commit1_v <= ({iqentry_v[heads[0]], iqentry_cmt[heads[0]]} != 2'b10
	               && {iqentry_v[heads[1]], iqentry_cmt[heads[1]]} == 2'b11
	               && ~|panic);
	    commit1_id <= {iqentry_mem[heads[1]], heads[1]};
	    commit1_tgt <= iqentry_tgt[heads[1]];  
	    commit1_we  <= iqentry_we[heads[1]];
	    commit1_bus <= iqentry_res[heads[1]];
	    // Need to set commit1, and commit2 valid bits for the branch predictor.
	    if (`NUM_CMT > 2) begin
	  	end
	  	else begin
	  		commit2_v <= ({iqentry_v[heads[0]], iqentry_cmt[heads[0]]} != 2'b10
	  							 && {iqentry_v[heads[1]], iqentry_cmt[heads[1]]} != 2'b10
	  							 && {iqentry_v[heads[2]], iqentry_br[heads[2]], iqentry_cmt[heads[2]]}==3'b111
		               && iqentry_tgt[heads[2]][4:0]==5'd0 && ~|panic);	// watch out for dbnz and ibne
	  		commit2_tgt <= 12'h000;
	  		commit2_we <= 8'h00;
	  	end
  	end
  	else begin
  		commit1_v <= ({iqentry_v[heads[0]], iqentry_cmt[heads[0]]} != 2'b10
  							 && {iqentry_v[heads[1]], iqentry_br[heads[1]], iqentry_cmt[heads[1]]}==3'b111
	               && iqentry_tgt[heads[1]][4:0]==5'd0 && ~|panic);	// watch out for dbnz and ibne
  		commit1_tgt <= 12'h000;
  		commit1_we <= 8'h00;
  		commit2_v <= ({iqentry_v[heads[0]], iqentry_cmt[heads[0]]} != 2'b10
  							 && {iqentry_v[heads[1]], iqentry_cmt[heads[1]]} != 2'b10
  							 && {iqentry_v[heads[2]], iqentry_br[heads[2]], iqentry_cmt[heads[2]]}==3'b111
	               && iqentry_tgt[heads[2]][4:0]==5'd0 && ~|panic);	// watch out for dbnz and ibne
  		commit2_tgt <= 12'h000;
  		commit2_we <= 8'h00;
  	end
end
    
assign int_commit = (commit0_v && iqentry_irq[heads[0]])
									 || (commit0_v && commit1_v && iqentry_irq[heads[1]] && `NUM_CMT > 1)
									 || (commit0_v && commit1_v && commit2_v && iqentry_irq[heads[2]] && `NUM_CMT > 2);

// Detect if a given register will become valid during the current cycle.
// We want a signal that is active during the current clock cycle for the read
// through register file, which trims a cycle off register access for every
// instruction. But two different kinds of assignment statements can't be
// placed under the same always block, it's a bad practice and may not work.
// So a signal is created here with it's own always block.
reg [AREGS-1:0] regIsValid;
always @*
begin
	for (n = 1; n < AREGS; n = n + 1)
	begin
		regIsValid[n] = rf_v[n];
		if (branchmiss)
	       if (~livetarget[n]) begin
	       		if (branchmiss_thrd) begin
	       			if (n >= 128)
	           			regIsValid[n] = `VAL;
	       		end
	       		else begin
	       			if (n < 128)
	           			regIsValid[n] = `VAL;
	       		end
	       end
		if (commit0_v && n=={commit0_tgt[7:0]})
			regIsValid[n] = regIsValid[n] | ((rf_source[ {commit0_tgt[7:0]} ] == commit0_id)
			|| (branchmiss && branchmiss_thrd == iqentry_thrd[commit0_id[`QBITS]] && iqentry_source[ commit0_id[`QBITS] ]));
		if (commit1_v && n=={commit1_tgt[7:0]} && `NUM_CMT > 1)
			regIsValid[n] = regIsValid[n] | ((rf_source[ {commit1_tgt[7:0]} ] == commit1_id)
			|| (branchmiss && branchmiss_thrd == iqentry_thrd[commit1_id[`QBITS]] && iqentry_source[ commit1_id[`QBITS] ]));
		if (commit2_v && n=={commit2_tgt[7:0]} && `NUM_CMT > 2)
			regIsValid[n] = regIsValid[n] | ((rf_source[ {commit2_tgt[7:0]} ] == commit2_id)
			|| (branchmiss && branchmiss_thrd == iqentry_thrd[commit2_id[`QBITS]] && iqentry_source[ commit2_id[`QBITS] ]));
	end
	regIsValid[0] = `VAL;
	regIsValid[32] = `VAL;
	regIsValid[64] = `VAL;
	regIsValid[96] = `VAL;
`ifdef SMT
	regIsValid[128] = `VAL;
	regIsValid[160] = `VAL;
	regIsValid[192] = `VAL;
	regIsValid[224] = `VAL;
`endif
end

// Wait until the cycle after Ra becomes valid to give time to read
// the vector element from the register file.
reg rf_vra0, rf_vra1;
/*always @(posedge clk)
    rf_vra0 <= regIsValid[Ra0s];
always @(posedge clk)
    rf_vra1 <= regIsValid[Ra1s];
*/
// Check how many instructions can be queued. This might be fewer than the
// number ready to queue from the fetch stage if queue slots aren't
// available or if there are no more physical registers left for remapping.
// The fetch stage needs to know how many instructions will queue so this
// logic is placed here.
// NOPs are filtered out and do not enter the instruction queue. The core
// will stream NOPs on a cache miss and they would mess up the queue order
// if there are immediate prefixes in the queue.
// For the VEX instruction, the instruction can't queue until register Ra
// is valid, because register Ra is used to specify the vector element to
// read.
wire q2open = iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV;
wire q3open = iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV && iqentry_v[(tail1 + 2'd1) % QENTRIES]==`INV;
always @*
begin
	canq1 <= FALSE;
	canq2 <= FALSE;
	queued1 <= FALSE;
	queued2 <= FALSE;
	queuedNop <= FALSE;
	vqueued2 <= FALSE;
	if (!branchmiss) begin
      // Two available
      if (fetchbuf1_v & fetchbuf0_v) begin
          // Is there a pair of NOPs ? (cache miss)
          if ((fetchbuf0_instr[`INSTRUCTION_OP]==`NOP) && (fetchbuf1_instr[`INSTRUCTION_OP]==`NOP))
              queuedNop <= TRUE; 
          else begin
              // If it's a predicted branch queue only the first instruction, the second
              // instruction will be stomped on.
              if (take_branch0 && fetchbuf1_thrd==fetchbuf0_thrd) begin
                  if (iqentry_v[tail0]==`INV) begin
                      canq1 <= TRUE;
                      queued1 <= TRUE;
                  end
              end
              // This is where a single NOP is allowed through to simplify the code. A
              // single NOP can't be a cache miss. Otherwise it would be necessary to queue
              // fetchbuf1 on tail0 it would add a nightmare to the enqueue code.
              // Not a branch and there are two instructions fetched, see whether or not
              // both instructions can be queued.
              else begin
                  if (iqentry_v[tail0]==`INV) begin
                      canq1 <= !IsVex(fetchbuf0_instr) || rf_vra0 || !SUP_VECTOR;
                      queued1 <= (
                      	((!IsVex(fetchbuf0_instr) || rf_vra0) && (!IsVector(fetchbuf0_instr))) || !SUP_VECTOR);
                      if (iqentry_v[tail1]==`INV) begin
                          canq2 <= ((!IsVex(fetchbuf1_instr) || rf_vra1)) || !SUP_VECTOR;
                          queued2 <= (
                          	(!IsVector(fetchbuf1_instr) && (!IsVex(fetchbuf1_instr) || rf_vra1) && (!IsVector(fetchbuf0_instr))) || !SUP_VECTOR);
                          vqueued2 <= IsVector(fetchbuf0_instr) && vqe0 < vl-2 && !vechain;
                      end
                  end
                  // If an irq is active during a vector instruction fetch, claim the vector instruction
                  // is finished queueing even though it may not be. It'll pick up where it left off after
                  // the exception is processed.
                  if (freezePC) begin
                  	if (IsVector(fetchbuf0_instr) && IsVector(fetchbuf1_instr) && vechain) begin
                  		queued1 <= TRUE;
                  		queued2 <= TRUE;
                  	end
                  	else if (IsVector(fetchbuf0_instr)) begin
                  		queued1 <= TRUE;
                  		if (vqe0 < vl-2)
                  			queued2 <= TRUE;
                  		else
                  			queued2 <= iqentry_v[tail1]==`INV;
                  	end
                  end
              end
          end
      end
      // One available
      else if (fetchbuf0_v) begin
          if (fetchbuf0_instr[`INSTRUCTION_OP]!=`NOP) begin
              if (iqentry_v[tail0]==`INV) begin
                  canq1 <= !IsVex(fetchbuf0_instr) || rf_vra0 || !SUP_VECTOR;
                  queued1 <=  
                  	(((!IsVex(fetchbuf0_instr) || rf_vra0) && (!IsVector(fetchbuf0_instr))) || !SUP_VECTOR);
              end
              if (iqentry_v[tail1]==`INV) begin
              	canq2 <= IsVector(fetchbuf0_instr) && vqe0 < vl-2 && SUP_VECTOR;
                  vqueued2 <= IsVector(fetchbuf0_instr) && vqe0 < vl-2 && !vechain;
          	end
          	if (freezePC) begin
              	if (IsVector(fetchbuf0_instr)) begin
              		queued1 <= TRUE;
              		if (vqe0 < vl-2)
              			queued2 <= iqentry_v[tail1]==`INV;
              	end
          	end
          end
          else
              queuedNop <= TRUE;
      end
      else if (fetchbuf1_v) begin
          if (fetchbuf1_instr[`INSTRUCTION_OP]!=`NOP) begin
              if (iqentry_v[tail0]==`INV) begin
                  canq1 <= !IsVex(fetchbuf1_instr) || rf_vra1 || !SUP_VECTOR;
                  queued1 <= (
                  	((!IsVex(fetchbuf1_instr) || rf_vra1) && (!IsVector(fetchbuf1_instr))) || !SUP_VECTOR);
              end
              if (iqentry_v[tail1]==`INV) begin
              	canq2 <= IsVector(fetchbuf1_instr) && vqe1 < vl-2 && SUP_VECTOR;
                  vqueued2 <= IsVector(fetchbuf1_instr) && vqe1 < vl-2;
          	end
          	if (freezePC) begin
              	if (IsVector(fetchbuf1_instr)) begin
              		queued1 <= TRUE;
              		if (vqe1 < vl-2)
              			queued2 <= iqentry_v[tail1]==`INV;
              	end
          	end
          end
          else
              queuedNop <= TRUE;
      end
      //else no instructions available to queue
    end
    else begin
      // One available
      if (fetchbuf0_v && fetchbuf0_thrd != branchmiss_thrd) begin
          if (fetchbuf0_instr[`INSTRUCTION_OP]!=`NOP) begin
              if (iqentry_v[tail0]==`INV) begin
                  canq1 <= !IsVex(fetchbuf0_instr) || rf_vra0 || !SUP_VECTOR;
                  queued1 <= (
                  	((!IsVex(fetchbuf0_instr) || rf_vra0) && (!IsVector(fetchbuf0_instr))) || !SUP_VECTOR);
              end
              if (iqentry_v[tail1]==`INV) begin
              	canq2 <= IsVector(fetchbuf0_instr) && vqe0 < vl-2 && SUP_VECTOR;
                  vqueued2 <= IsVector(fetchbuf0_instr) && vqe0 < vl-2 && !vechain;
          	end
          end
          else
              queuedNop <= TRUE;
      end
      else if (fetchbuf1_v && fetchbuf1_thrd != branchmiss_thrd) begin
          if (fetchbuf1_instr[`INSTRUCTION_OP]!=`NOP) begin
              if (iqentry_v[tail0]==`INV) begin
                  canq1 <= !IsVex(fetchbuf1_instr) || rf_vra1 || !SUP_VECTOR;
                  queued1 <= (
                  	((!IsVex(fetchbuf1_instr) || rf_vra1) && (!IsVector(fetchbuf1_instr))) || !SUP_VECTOR);
              end
              if (iqentry_v[tail1]==`INV) begin
              	canq2 <= IsVector(fetchbuf1_instr) && vqe1 < vl-2 && SUP_VECTOR;
                  vqueued2 <= IsVector(fetchbuf0_instr) && vqe0 < vl-2 && !vechain;
          	end
          end
          else
              queuedNop <= TRUE;
      end
    	else
    		queuedNop <= TRUE;
    end
end

//
// Branchmiss seems to be sticky sometimes during simulation. For instance branch miss
// and cache miss at same time. The branchmiss should clear before the core continues
// so the positive edge is detected to avoid incrementing the sequnce number too many
// times.
wire pebm;
edge_det uedbm (.rst(rst), .clk(clk), .ce(1'b1), .i(branchmiss), .pe(pebm), .ne(), .ee() );

reg [5:0] ld_time;
reg [63:0] wc_time_dat;
reg [63:0] wc_times;
always @(posedge tm_clk_i)
begin
	if (|ld_time)
		wc_time <= wc_time_dat;
	else begin
		wc_time[31:0] <= wc_time[31:0] + 32'd1;
		if (wc_time[31:0] >= TM_CLKFREQ-1) begin
			wc_time[31:0] <= 32'd0;
			wc_time[63:32] <= wc_time[63:32] + 32'd1;
		end
	end
end

wire writing_wb =
	 		(mem1_available && dram0==`DRAMSLOT_BUSY && dram0_store && !iqentry_stomp[dram0_id[`QBITS]] && wbptr<`WB_DEPTH-1)
	 || (mem2_available && dram1==`DRAMSLOT_BUSY && dram1_store && !iqentry_stomp[dram1_id[`QBITS]] && `NUM_MEM > 1 && wbptr<`WB_DEPTH-1)
	 || (mem3_available && dram2==`DRAMSLOT_BUSY && dram2_store && !iqentry_stomp[dram2_id[`QBITS]] && `NUM_MEM > 2 && wbptr<`WB_DEPTH-1)
	 ;

// Monster clock domain.
// Like to move some of this to clocking under different always blocks in order
// to help out the toolset's synthesis, but it ain't gonna be easy.
// Simulation doesn't like it if things are under separate always blocks.
// Synthesis doesn't like it if things are under the same always block.

//always @(posedge clk)
//begin
//	branchmiss <= excmiss|fcu_branchmiss;
//    misspc <= excmiss ? excmisspc : fcu_misspc;
//    missid <= excmiss ? (|iqentry_exc[heads[0]] ? heads[0] : heads[1]) : fcu_sourceid;
//	branchmiss_thrd <=  excmiss ? excthrd : fcu_thrd;
//end
wire alu0_done_pe, alu1_done_pe;
edge_det uedalu0d (.clk(clk), .ce(1'b1), .i(alu0_done), .pe(alu0_done_pe), .ne(), .ee());
edge_det uedalu1d (.clk(clk), .ce(1'b1), .i(alu1_done), .pe(alu1_done_pe), .ne(), .ee());

always @(posedge clk)
if (rst) begin
`ifdef SUPPORT_SMT
     mstatus[0] <= 64'h000F;	// select register set #0 for thread 0
     mstatus[1] <= 64'h800F;	// select register set #2 for thread 1
`else
     mstatus <= 64'h000F;	// select register set #0 for thread 0
`endif
    for (n = 0; n < QENTRIES; n = n + 1) begin
       iqentry_v[n] <= `INV;
       iqentry_iv[n] <= `INV;
       iqentry_is[n] <= 3'b00;
       iqentry_done[n] <= FALSE;
       iqentry_cmt[n] <= FALSE;
       iqentry_out[n] <= FALSE;
       iqentry_agen[n] <= FALSE;
       iqentry_sn[n] <= 4'd0;
       iqentry_pt[n] <= FALSE;
       iqentry_bt[n] <= FALSE;
       iqentry_br[n] <= FALSE;
       iqentry_aq[n] <= FALSE;
       iqentry_rl[n] <= FALSE;
       iqentry_alu0[n] <= FALSE;
       iqentry_alu[n] <= FALSE;
       iqentry_fpu[n] <= FALSE;
       iqentry_fsync[n] <= FALSE;
       iqentry_fc[n] <= FALSE;
       iqentry_takb[n] <= FALSE;
       iqentry_jmp[n] <= FALSE;
       iqentry_jal[n] <= FALSE;
       iqentry_ret[n] <= FALSE;
       iqentry_brk[n] <= FALSE;
       iqentry_irq[n] <= FALSE;
       iqentry_rti[n] <= FALSE;
       iqentry_ldcmp[n] <= FALSE;
       iqentry_load[n] <= FALSE;
       iqentry_rtop[n] <= FALSE;
       iqentry_sei[n] <= FALSE;
       iqentry_shft[n] <= FALSE;
       iqentry_sync[n] <= FALSE;
       iqentry_ven[n] <= 6'd0;
       iqentry_vl[n] <= 8'd0;
       iqentry_we[n] <= 8'h00;
       iqentry_rfw[n] <= FALSE;
       iqentry_rmw[n] <= FALSE;
       iqentry_pc[n] <= RSTPC;
    	 iqentry_instr[n] <= `NOP_INSN;
    	 iqentry_insln[n] <= 3'd4;
    	 iqentry_preload[n] <= FALSE;
    	 iqentry_mem[n] <= FALSE;
    	 iqentry_memndx[n] <= FALSE;
       iqentry_memissue[n] <= FALSE;
       iqentry_mem_islot[n] <= 3'd0;
       iqentry_memdb[n] <= FALSE;
       iqentry_memsb[n] <= FALSE;
       iqentry_tgt[n] <= 6'd0;
       iqentry_imm[n] <= 1'b0;
       iqentry_ma[n] <= 1'b0;
       iqentry_a0[n] <= 64'd0;
       iqentry_a1[n] <= 64'd0;
       iqentry_a2[n] <= 64'd0;
       iqentry_a3[n] <= 64'd0;
       iqentry_a1_v[n] <= `INV;
       iqentry_a2_v[n] <= `INV;
       iqentry_a3_v[n] <= `INV;
       iqentry_a1_s[n] <= 5'd0;
       iqentry_a2_s[n] <= 5'd0;
       iqentry_a3_s[n] <= 5'd0;
       iqentry_canex[n] <= FALSE;
    end
     bwhich <= 2'b00;
     dram0 <= `DRAMSLOT_AVAIL;
     dram1 <= `DRAMSLOT_AVAIL;
     dram2 <= `DRAMSLOT_AVAIL;
     dram0_instr <= `NOP_INSN;
     dram1_instr <= `NOP_INSN;
     dram2_instr <= `NOP_INSN;
     dram0_addr <= 32'h0;
     dram1_addr <= 32'h0;
     dram2_addr <= 32'h0;
     dram0_id <= 1'b0;
     dram1_id <= 1'b0;
     dram2_id <= 1'b0;
     L1_adr <= RSTPC;
     invic <= FALSE;
     tail0 <= 3'd0;
     tail1 <= 3'd1;
     for (n = 0; n < QENTRIES; n = n + 1)
     	heads[n] <= n;
     panic = `PANIC_NONE;
     alu0_dataready <= 1'b0;
     alu1_dataready <= 1'b0;
     alu0_sourceid <= 5'd0;
     alu1_sourceid <= 5'd0;
`define SIM_
`ifdef SIM_
		alu0_pc <= RSTPC;
		alu0_instr <= `NOP_INSN;
		alu0_argA <= 64'h0;
		alu0_argB <= 64'h0;
		alu0_argC <= 64'h0;
		alu0_argI <= 64'h0;
		alu0_mem <= 1'b0;
		alu0_shft <= 1'b0;
		alu0_thrd <= 1'b0;
		alu0_tgt <= 6'h00;
		alu0_ven <= 6'd0;
		alu1_pc <= RSTPC;
		alu1_instr <= `NOP_INSN;
		alu1_argA <= 64'h0;
		alu1_argB <= 64'h0;
		alu1_argC <= 64'h0;
		alu1_argI <= 64'h0;
		alu1_mem <= 1'b0;
		alu1_shft <= 1'b0;
		alu1_thrd <= 1'b0;
		alu1_tgt <= 6'h00;
		alu1_ven <= 6'd0;
`endif
     fcu_dataready <= 0;
     fcu_instr <= `NOP_INSN;
     dramA_v <= 0;
     dramB_v <= 0;
     dramC_v <= 0;
     I <= 0;
     CC <= 0;
     icstate <= IDLE;
     bstate <= BIDLE;
     tick <= 64'd0;
     ol_o <= 2'b0;
     bte_o <= 2'b00;
     cti_o <= 3'b000;
     cyc <= `LOW;
     stb_o <= `LOW;
     we <= `LOW;
     sel_o <= 8'h00;
     dat_o <= 64'hFFFFFFFFFFFFFFFF;
     sr_o <= `LOW;
     cr_o <= `LOW;
     vadr <= RSTPC;
     icl_o <= `LOW;      	// instruction cache load
     cr0 <= 64'd0;
     cr0[13:8] <= 6'd0;		// select compressed instruction group #0
     cr0[30] <= TRUE;    	// enable data caching
     cr0[32] <= TRUE;    	// enable branch predictor
     cr0[16] <= 1'b0;		// disable SMT
     cr0[17] <= 1'b0;		// sequence number reset = 1
     cr0[34] <= FALSE;	// write buffer merging enable
     pcr <= 32'd0;
     pcr2 <= 64'd0;
    for (n = 0; n < PREGS; n = n + 1)
         rf_v[n] <= `VAL;
     fp_rm <= 3'd0;			// round nearest even - default rounding mode
     fpu_csr[37:32] <= 5'd31;	// register set #31
     waitctr <= 64'd0;
    for (n = 0; n < 16; n = n + 1)
         badaddr[n] <= 64'd0;
     sbl <= 32'h0;
     sbu <= 32'hFFFFFFFF;
    // Vector
     vqe0 <= 6'd0;
     vqet0 <= 6'd0;
     vqe1 <= 6'd0;
     vqet1 <= 6'd0;
     vl <= 7'd62;
    for (n = 0; n < 8; n = n + 1)
         vm[n] <= 64'h7FFFFFFFFFFFFFFF;
     nop_fetchbuf <= 4'h0;
     fcu_done <= `TRUE;
     sema <= 64'h0;
     tvec[0] <= RSTPC;
     pmr <= 64'hFFFFFFFFFFFFFFFF;
     pmr[0] <= `ID1_AVAIL;
     pmr[1] <= `ID2_AVAIL;
     pmr[2] <= `ID3_AVAIL;
     pmr[8] <= `ALU0_AVAIL;
     pmr[9] <= `ALU1_AVAIL;
     pmr[16] <= `FPU1_AVAIL;
     pmr[17] <= `FPU2_AVAIL;
     pmr[24] <= `MEM1_AVAIL;
     pmr[25] <= `MEM2_AVAIL;
		 pmr[26] <= `MEM3_AVAIL;     
     pmr[32] <= `FCU_AVAIL;
     for (n = 0; n < `WB_DEPTH; n = n + 1) begin
     	wb_v[n] <= 1'b0;
     	wb_rmw[n] <= 1'b0;
     	wb_id[n] <= {QENTRIES{1'b0}};
     	wb_ol[n] <= 2'b00;
     	wb_sel[n] <= 8'h00;
     	wb_addr[n] <= 32'd0;
     	wb_data[n] <= 64'd0;
     end
     wb_en <= `TRUE;
     wbo_id <= {QENTRIES{1'b0}};
     wbptr <= 2'd0;
`ifdef SIM
		wb_merges <= 32'd0;
`endif
		iq_ctr <= 40'd0;
		icl_ctr <= 40'd0;
		bm_ctr <= 40'd0;
		irq_ctr <= 40'd0;
		cmt_timer <= 9'd0;
		StoreAck1 <= `FALSE;
end
else begin
	if (|fb_panic)
		panic <= fb_panic;
	begin
		branchmiss <= excmiss|fcu_branchmiss;
		misspc <= excmiss ? excmisspc : fcu_misspc;
		missid <= excmiss ? (|iqentry_exc[heads[0]] ? heads[0] : heads[1]) : fcu_sourceid;
		branchmiss_thrd <=  excmiss ? excthrd : fcu_thrd;
	end
	// The following signals only pulse

	// Instruction decode output should only pulse once for a queue entry. We
	// want the decode to be invalidated after a clock cycle so that it isn't
	// inadvertently used to update the queue at a later point.
	dramA_v <= `INV;
	dramB_v <= `INV;
	dramC_v <= `INV;
	id1_vi <= `INV;
	if (`NUM_IDU > 1)
		id2_vi <= `INV;
	if (`NUM_IDU > 2)
		id3_vi <= `INV;
	if (iqentry_v[nid] && iqentry_sn[nid] > iqentry_sn[fcu_id[`QBITS]])
		fcu_dataready <= `INV;
	wb_shift <= FALSE;
	ld_time <= {ld_time[4:0],1'b0};
	wc_times <= wc_time;
     rf_vra0 <= regIsValid[Ra0s];
     rf_vra1 <= regIsValid[Ra1s];
    if (vqe0 >= vl) begin
         vqe0 <= 6'd0;
         vqet0 <= 6'h0;
    end
    if (vqe1 >= vl) begin
         vqe1 <= 6'd0;
         vqet1 <= 6'h0;
    end
    // Turn off vector chaining indicator when chained instructions are done.
    if ((vqe0 >= vl || vqe0==6'd0) && (vqe1 >= vl || vqe1==6'd0))
`ifdef SUPPORT_SMT
    	mstatus[0][32] <= 1'b0;
`else
    	mstatus[32] <= 1'b0;
`endif    	

     nop_fetchbuf <= 4'h0;
     excmiss <= FALSE;
     invic <= FALSE;
     tick <= tick + 64'd1;
     alu0_ld <= FALSE;
     alu1_ld <= FALSE;
     fpu1_ld <= FALSE;
     fpu2_ld <= FALSE;
     fcu_ld <= FALSE;
     dramA_v <= FALSE;
     dramB_v <= FALSE;
     dramC_v <= FALSE;
     cr0[17] <= 1'b0;
    if (waitctr != 64'd0)
         waitctr <= waitctr - 64'd1;


    if (iqentry_fc[fcu_id[`QBITS]] && iqentry_v[fcu_id[`QBITS]] && !iqentry_done[fcu_id[`QBITS]] && iqentry_out[fcu_id[`QBITS]])
    	fcu_timeout <= fcu_timeout + 8'd1;

	if (branchmiss) begin
        for (n = 1; n < PREGS; n = n + 1)
           if (~livetarget[n]) begin
           		if (branchmiss_thrd) begin
           			if (n >= 128)
                		rf_v[n] <= `VAL;
           		end
           		else begin
           			if (n < 128)
                		rf_v[n] <= `VAL;
            	end
           end

			for (n = 0; n < QENTRIES; n = n + 1)
	    	if (|iqentry_latestID[n])
	    		if (iqentry_thrd[n]==branchmiss_thrd) rf_source[ {iqentry_tgt[n][7:0]} ] <= { 1'b0, iqentry_mem[n], n[`QBITS] };
        
    end

    // The source for the register file data might have changed since it was
    // placed on the commit bus. So it's needed to check that the source is
    // still as expected to validate the register.
	if (commit0_v) begin
        if (!rf_v[ {commit0_tgt[7:0]} ]) 
//             rf_v[ {commit0_tgt[7:0]} ] <= rf_source[ commit0_tgt[7:0] ] == commit0_id || (branchmiss && iqentry_source[ commit0_id[`QBITS] ]);
             rf_v[ {commit0_tgt[7:0]} ] <= regIsValid[{commit0_tgt[7:0]}];//rf_source[ commit0_tgt[4:0] ] == commit0_id || (branchmiss && iqentry_source[ commit0_id[`QBITS] ]);
        if (commit0_tgt[5:0] != 6'd0) $display("r%d <- %h   v[%d]<-%d", commit0_tgt, commit0_bus, regIsValid[commit0_tgt[5:0]],
        rf_source[ {commit0_tgt[7:0]} ] == commit0_id || (branchmiss && iqentry_source[ commit0_id[`QBITS] ]));
        if (commit0_tgt[5:0]==6'd30 && commit0_bus==64'd0)
        	$display("FP <= 0");
    end
    if (commit1_v && `NUM_CMT > 1) begin
        if (!rf_v[ {commit1_tgt[7:0]} ]) begin
        	if ({commit1_tgt[7:0]}=={commit0_tgt[7:0]})
        		 rf_v[ {commit1_tgt[7:0]} ] <= regIsValid[{commit0_tgt[7:0]}] | regIsValid[{commit1_tgt[7:0]}];
        		/*
        			(rf_source[ commit0_tgt[4:0] ] == commit0_id || (branchmiss && iqentry_source[ commit0_id[`QBITS] ])) || 
        			(rf_source[ commit1_tgt[4:0] ] == commit1_id || (branchmiss && iqentry_source[ commit1_id[`QBITS] ]));
        		*/
        	else
            	 rf_v[ {commit1_tgt[7:0]} ] <= regIsValid[{commit1_tgt[7:0]}];//rf_source[ commit1_tgt[4:0] ] == commit1_id || (branchmiss && iqentry_source[ commit1_id[`QBITS] ]);
        end
        if (commit1_tgt[5:0] != 6'd0) $display("r%d <- %h   v[%d]<-%d", commit1_tgt, commit1_bus, regIsValid[commit1_tgt[5:0]],
        rf_source[ {commit1_tgt[7:0]} ] == commit1_id || (branchmiss && iqentry_source[ commit1_id[`QBITS] ]));
        if (commit1_tgt[5:0]==6'd30 && commit1_bus==64'd0)
        	$display("FP <= 0");
    end
    if (commit2_v && `NUM_CMT > 2) begin
      if (!rf_v[ {commit2_tgt[7:0]} ]) begin
      	if ({commit2_tgt[7:0]}=={commit1_tgt[7:0]} && {commit2_tgt[7:0]}=={commit0_tgt[7:0]})
      		 rf_v[ {commit2_tgt[7:0]} ] <= regIsValid[{commit0_tgt[7:0]}] | regIsValid[{commit1_tgt[7:0]}] | regIsValid[{commit2_tgt[7:0]}];
      	else if ({commit2_tgt[7:0]}=={commit0_tgt[7:0]})
      		 rf_v[ {commit2_tgt[7:0]} ] <= regIsValid[{commit0_tgt[7:0]}] | regIsValid[{commit2_tgt[7:0]}];
      	else if ({commit2_tgt[7:0]}=={commit1_tgt[7:0]})
      		 rf_v[ {commit2_tgt[7:0]} ] <= regIsValid[{commit1_tgt[7:0]}] | regIsValid[{commit2_tgt[7:0]}];
      	else
        	 rf_v[ {commit2_tgt[7:0]} ] <= regIsValid[{commit2_tgt[7:0]}];//rf_source[ commit1_tgt[4:0] ] == commit1_id || (branchmiss && iqentry_source[ commit1_id[`QBITS] ]);
      end
      if (commit2_tgt[5:0] != 6'd0) $display("r%d <- %h   v[%d]<-%d", commit2_tgt, commit2_bus, regIsValid[commit2_tgt[5:0]],
      rf_source[ {commit2_tgt[7:0]} ] == commit2_id || (branchmiss && iqentry_source[ commit2_id[`QBITS] ]));
      if (commit2_tgt[5:0]==6'd30 && commit2_bus==64'd0)
      	$display("FP <= 0");
    end
     rf_v[0] <= 1;

  //
  // ENQUEUE
  //
  // place up to two instructions from the fetch buffer into slots in the IQ.
  //   note: they are placed in-order, and they are expected to be executed
  // 0, 1, or 2 of the fetch buffers may have valid data
  // 0, 1, or 2 slots in the instruction queue may be available.
  // if we notice that one of the instructions in the fetch buffer is a predicted branch,
  // (set branchback/backpc and delete any instructions after it in fetchbuf)
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

	    2'b01:
		    if (canq1) begin
					if (fetchbuf1_rfw) begin
						rf_source[ Rt1s ] <= { 1'b0, fetchbuf1_mem, tail0 };	// top bit indicates ALU/MEM bus
						rf_v [Rt1s] <= `INV;
					end
					if (IsVector(fetchbuf1_instr) && SUP_VECTOR) begin
						vqe1 <= vqe1 + 4'd1;
						if (IsVCmprss(fetchbuf1_instr)) begin
							if (vm[fetchbuf1_instr[25:23]][vqe1])
								vqet1 <= vqet1 + 4'd1;
						end
						else
							vqet1 <= vqet1 + 4'd1; 
						if (vqe1 >= vl-2)
							nop_fetchbuf <= fetchbuf ? 4'b0100 : 4'b0001;
						enque1(tail0, fetchbuf1_thrd ? maxsn[1]+4'd1 : maxsn[0]+4'd1, vqe1);
						iq_ctr = iq_ctr + 4'd1;
						if (canq2 && vqe1 < vl-2) begin
							vqe1 <= vqe1 + 4'd2;
							if (IsVCmprss(fetchbuf1_instr)) begin
								if (vm[fetchbuf1_instr[25:23]][vqe1+6'd1])
									vqet1 <= vqet1 + 4'd2;
							end
							else
								vqet1 <= vqet1 + 4'd2;
							enque1(tail1, fetchbuf1_thrd ? maxsn[1] + 4'd2 : maxsn[0] + 4'd2, vqe1 + 6'd1);
							iq_ctr = iq_ctr + 4'd2;
						end
					end
					else begin
						enque1(tail0, fetchbuf1_thrd ? maxsn[1]+4'd1 : maxsn[0]+4'd1, 6'd0);
						iq_ctr = iq_ctr + 4'd1;
					end
		    end

	    2'b10:
	    	if (canq1) begin
	    		enque0x();
		    end

	    2'b11:
		    if (canq1) begin
				//
				// if the first instruction is a predicted branch, enqueue it & stomp on all following instructions
				// but only if the following instruction is in the same thread. Otherwise we want to queue two.
				//
				if (take_branch0 && fetchbuf1_thrd==fetchbuf0_thrd) begin
					enque0x();
				end

				else begin	// fetchbuf0 doesn't contain a predicted branch
				    //
				    // so -- we can enqueue 1 or 2 instructions, depending on space in the IQ
				    // update the rf_v and rf_source bits separately (at end)
				    //   the problem is that if we do have two instructions, 
				    //   they may interact with each other, so we have to be
				    //   careful about where things point.
				    //
				    // enqueue the first instruction ...
				    //
		            if (IsVector(fetchbuf0_instr) && SUP_VECTOR) begin
		                 vqe0 <= vqe0 + 4'd1;
		                if (IsVCmprss(fetchbuf0_instr)) begin
		                    if (vm[fetchbuf0_instr[25:23]][vqe0])
		                         vqet0 <= vqet0 + 4'd1;
		                end
		                else
		                     vqet0 <= vqet0 + 4'd1; 
		                if (vqe0 >= vl-2)
		                	nop_fetchbuf <= fetchbuf ? 4'b1000 : 4'b0010;
		            end
		            if (vqe0 < vl || !IsVector(fetchbuf0_instr)) begin
			            enque0(tail0, fetchbuf0_thrd ? maxsn[1]+4'd1 : maxsn[0]+4'd1, vqe0);
									iq_ctr = iq_ctr + 4'd1;
					    //
					    // if there is room for a second instruction, enqueue it
					    //
					    if (canq2) begin
					    	if (vechain && IsVector(fetchbuf1_instr)
					    	&& Ra1s != Rt0s	// And there is no dependency
					    	&& Rb1s != Rt0s
					    	&& Rc1s != Rt0s
					    	) begin
`ifdef SUPPORT_SMT					    		
					    		mstatus[0][32] <= 1'b1;
`else
					    		mstatus[32] <= 1'b1;
`endif					    		
				                vqe1 <= vqe1 + 4'd1;
				                if (IsVCmprss(fetchbuf1_instr)) begin
				                    if (vm[fetchbuf1_instr[25:23]][vqe1])
				                         vqet1 <= vqet1 + 4'd1;
				                end
				                else
				                     vqet1 <= vqet1 + 4'd1; 
				                if (vqe1 >= vl-2)
				                	nop_fetchbuf <= fetchbuf ? 4'b0100 : 4'b0001;
					      		enque1(tail1,
					      			fetchbuf1_thrd==fetchbuf0_thrd && fetchbuf1_thrd==1'b1 ? maxsn[1] + 4'd2 :
					      			fetchbuf1_thrd==fetchbuf0_thrd && fetchbuf1_thrd==1'b0 ? maxsn[0] + 4'd2 :
					      			fetchbuf1_thrd ? maxsn[1] + 4'd2: maxsn[0] + 4'd2, 6'd0);
										iq_ctr = iq_ctr + 4'd2;

								// SOURCE 1 ...
								a1_vs();

								// SOURCE 2 ...
								a2_vs();

								// SOURCE 3 ...
								a3_vs();

								// if the two instructions enqueued target the same register, 
								// make sure only the second writes to rf_v and rf_source.
								// first is allowed to update rf_v and rf_source only if the
								// second has no target
								//
							    if (fetchbuf0_rfw) begin
								     rf_source[ Rt0s ] <= { 1'b0,fetchbuf0_mem, tail0 };
								     rf_v [ Rt0s] <= `INV;
							    end
							    if (fetchbuf1_rfw) begin
								     rf_source[ Rt1s ] <= { 1'b0,fetchbuf1_mem, tail1 };
								     rf_v [ Rt1s ] <= `INV;
							    end
					    	end
					    	// If there was a vector instruction in fetchbuf0, we really
					    	// want to queue the next vector element, not the next
					    	// instruction waiting in fetchbuf1.
				            else if (IsVector(fetchbuf0_instr) && SUP_VECTOR && vqe0 < vl-1) begin
				                 vqe0 <= vqe0 + 4'd2;
				                if (IsVCmprss(fetchbuf0_instr)) begin
				                    if (vm[fetchbuf0_instr[25:23]][vqe0+6'd1])
				                         vqet0 <= vqet0 + 4'd2;
				                end
				                else
				                     vqet0 <= vqet0 + 4'd2; 
				                if (vqe0 >= vl-3)
			    	            	 nop_fetchbuf <= fetchbuf ? 4'b1000 : 4'b0010;
			    	            if (vqe0 < vl-1) begin
						      		enque0(tail1, fetchbuf0_thrd ? maxsn[1] + 4'd2 : maxsn[0] + 4'd2, vqe0 + 6'd1);
											iq_ctr = iq_ctr + 4'd2;

									// SOURCE 1 ...
						     iqentry_a1_v [tail1] <= regIsValid[Ra0s];
						     iqentry_a1_s [tail1] <= rf_source [Ra0s];

									// SOURCE 2 ...
						     iqentry_a2_v [tail1] <= regIsValid[Rb0s];
						     iqentry_a2_s [tail1] <= rf_source[ Rb0s ];

									// SOURCE 3 ...
						     iqentry_a3_v [tail1] <= regIsValid[Rc0s];
						     iqentry_a3_s [tail1] <= rf_source[ Rc0s ];

									// if the two instructions enqueued target the same register, 
									// make sure only the second writes to rf_v and rf_source.
									// first is allowed to update rf_v and rf_source only if the
									// second has no target (BEQ or SW)
									//
								    if (fetchbuf0_rfw) begin
									     rf_source[ Rt0s ] <= { 1'b0, fetchbuf0_mem, tail1 };
									     rf_v [ Rt0s ] <= `INV;
								    end
								end
				        	end
				            else if (IsVector(fetchbuf1_instr) && SUP_VECTOR) begin
			            		 vqe1 <= 6'd1;
				                if (IsVCmprss(fetchbuf1_instr)) begin
				                    if (vm[fetchbuf1_instr[25:23]][IsVector(fetchbuf0_instr)? 6'd0:vqe1+6'd1])
			                        	 vqet1 <= 6'd1;
			                        else
			                        	 vqet1 <= 6'd0;
				                end
				                else
			                   		 vqet1 <= 6'd1; 
			                    if (IsVector(fetchbuf0_instr) && SUP_VECTOR)
			   	            		nop_fetchbuf <= fetchbuf ? 4'b1000 : 4'b0010;
					      		enque1(tail1,
					      			fetchbuf1_thrd==fetchbuf0_thrd && fetchbuf1_thrd==1'b1 ? maxsn[1] + 4'd2 :
					      			fetchbuf1_thrd==fetchbuf0_thrd && fetchbuf1_thrd==1'b0 ? maxsn[0] + 4'd2 :
					      			fetchbuf1_thrd ? maxsn[1] + 4'd2: maxsn[0] + 4'd2, 6'd0);
										iq_ctr = iq_ctr + 4'd2;

								// SOURCE 1 ...
								a1_vs();

								// SOURCE 2 ..
								a2_vs();

								// SOURCE 3 ...
								a3_vs();

								// if the two instructions enqueued target the same register, 
								// make sure only the second writes to rf_v and rf_source.
								// first is allowed to update rf_v and rf_source only if the
								// second has no target
								//
							    if (fetchbuf0_rfw) begin
								     rf_source[ Rt0s ] <= { 1'b0,fetchbuf0_mem, tail0 };
								     rf_v [ Rt0s] <= `INV;
							    end
							    if (fetchbuf1_rfw) begin
								     rf_source[ Rt1s ] <= { 1'b0,fetchbuf1_mem, tail1 };
								     rf_v [ Rt1s ] <= `INV;
							    end
				            end
				            else begin
//					      		enque1(tail1, seq_num + 5'd1, 6'd0);
					      		enque1(tail1,
					      			fetchbuf1_thrd==fetchbuf0_thrd && fetchbuf1_thrd==1'b1 ? maxsn[1] + 4'd2 :
					      			fetchbuf1_thrd==fetchbuf0_thrd && fetchbuf1_thrd==1'b0 ? maxsn[0] + 4'd2 :
					      			fetchbuf1_thrd ? maxsn[1] + 4'd1: maxsn[0]+4'd1, 6'd0);
										iq_ctr = iq_ctr + 4'd2;

								// SOURCE 1 ...
								a1_vs();

								// SOURCE 2 ...
								a2_vs();

								// SOURCE 3 ...
								a3_vs();

								// if the two instructions enqueued target the same register, 
								// make sure only the second writes to regIsValid and rf_source.
								// first is allowed to update regIsValid and rf_source only if the
								// second has no target (BEQ or SW)
								//
							    if (fetchbuf0_rfw) begin
								     rf_source[ Rt0s ] <= { 1'b0,fetchbuf0_mem, tail0 };
								     rf_v [ Rt0s] <= `INV;
								     $display("r%dx (%d) Invalidated", Rt0s, Rt0s[4:0]);
							    end
							    else 
							    	$display("No rfw");
							    if (fetchbuf1_rfw) begin
								     rf_source[ Rt1s ] <= { 1'b0,fetchbuf1_mem, tail1 };
								     $display("r%dx (%d) Invalidated", Rt1s, Rt1s[4:0]);
								     rf_v [ Rt1s ] <= `INV;
							    end
							    else
							    	$display("No rfw");
							end

					    end	// ends the "if IQ[tail1] is available" clause
					    else begin	// only first instruction was enqueued
							if (fetchbuf0_rfw) begin
							     $display("r%dx (%d) Invalidated 1", Rt0s, Rt0s[4:0]);
							     rf_source[ Rt0s ] <= {1'b0,fetchbuf0_mem, tail0};
							     rf_v [ Rt0s ] <= `INV;
							end
						end
				    end

				end	// ends the "else fetchbuf0 doesn't have a backwards branch" clause
		    end
		endcase
	if (pebm) begin
		bm_ctr <= bm_ctr + 40'd1;
	end

//
// DATAINCOMING
//
// wait for operand/s to appear on alu busses and puts them into 
// the iqentry_a1 and iqentry_a2 slots (if appropriate)
// as well as the appropriate iqentry_res slots (and setting valid bits)
//
// put results into the appropriate instruction entries
//
// This chunk of code has to be before the enqueue stage so that the agen bit
// can be reset to zero by enqueue.
// put results into the appropriate instruction entries
//
if (IsMul(alu0_instr)|IsDivmod(alu0_instr)|alu0_shft|alu0_tlb) begin
	if (alu0_done_pe) begin
		alu0_dataready <= `TRUE;
	end
end
if (alu1_shft) begin
	if (alu1_done_pe) begin
		alu1_dataready <= `TRUE;
	end
end

if (alu0_v) begin
	iqentry_tgt [ alu0_id[`QBITS] ] <= alu0_tgt;
	if (iqentry_mem[ alu0_id[`QBITS] ] && !iqentry_agen[ alu0_id[`QBITS] ])
		iqentry_ma[ alu0_id[`QBITS] ] <= alu0_bus;
	iqentry_res	[ alu0_id[`QBITS] ] <= alu0_bus;
	iqentry_exc	[ alu0_id[`QBITS] ] <= alu0_exc;
	iqentry_done[ alu0_id[`QBITS] ] <= !iqentry_mem[ alu0_id[`QBITS] ] && alu0_done;
	iqentry_cmt [ alu0_id[`QBITS] ] <= !iqentry_mem[ alu0_id[`QBITS] ] && alu0_done;
	iqentry_out	[ alu0_id[`QBITS] ] <= `INV;
	iqentry_agen[ alu0_id[`QBITS] ] <= `VAL;//!iqentry_fc[alu0_id[`QBITS]];  // RET
	alu0_dataready <= FALSE;
end

if (alu1_v && `NUM_ALU > 1) begin
	iqentry_tgt [ alu1_id[`QBITS] ] <= alu1_tgt;
	if (iqentry_mem[ alu1_id[`QBITS] ] && !iqentry_agen[ alu1_id[`QBITS] ])
		iqentry_ma[ alu1_id[`QBITS] ] <= alu1_bus;
	iqentry_res	[ alu1_id[`QBITS] ] <= alu1_bus;
	iqentry_exc	[ alu1_id[`QBITS] ] <= alu1_exc;
	iqentry_done[ alu1_id[`QBITS] ] <= !iqentry_mem[ alu1_id[`QBITS] ] && alu1_done;
	iqentry_cmt [ alu1_id[`QBITS] ] <= !iqentry_mem[ alu1_id[`QBITS] ] && alu1_done;
	iqentry_out	[ alu1_id[`QBITS] ] <= `INV;
	iqentry_agen[ alu1_id[`QBITS] ] <= `VAL;//!iqentry_fc[alu0_id[`QBITS]];  // RET
	alu1_dataready <= FALSE;
end

if (fpu1_v) begin
	iqentry_res [ fpu1_id[`QBITS] ] <= fpu1_bus;
	iqentry_ares[ fpu1_id[`QBITS] ] <= fpu1_status;
	iqentry_exc [ fpu1_id[`QBITS] ] <= fpu1_exc;
	iqentry_done[ fpu1_id[`QBITS] ] <= fpu1_done;
	iqentry_cmt	[ fpu1_id[`QBITS] ] <= fpu1_done;
	iqentry_out [ fpu1_id[`QBITS] ] <= `INV;
	fpu1_dataready <= FALSE;
end

if (fpu2_v && `NUM_FPU > 1) begin
	iqentry_res [ fpu2_id[`QBITS] ] <= fpu2_bus;
	iqentry_ares[ fpu2_id[`QBITS] ] <= fpu2_status;
	iqentry_exc [ fpu2_id[`QBITS] ] <= fpu2_exc;
	iqentry_done[ fpu2_id[`QBITS] ] <= fpu2_done;
	iqentry_cmt [ fpu2_id[`QBITS] ] <= fpu2_done;
	iqentry_out [ fpu2_id[`QBITS] ] <= `INV;
	//iqentry_agen[ fpu_id[`QBITS] ] <= `VAL;  // RET
	fpu2_dataready <= FALSE;
end

if (fcu_wr & ~fcu_done) begin
	fcu_done <= `TRUE;
  if (fcu_ld)
    waitctr <= fcu_argA;
  iqentry_res [ fcu_id[`QBITS] ] <= fcu_bus;
  iqentry_exc [ fcu_id[`QBITS] ] <= fcu_exc;
  if (IsWait(fcu_instr)) begin
		iqentry_done [ fcu_id[`QBITS] ] <= (waitctr==64'd1) || signal_i[fcu_argA[4:0]|fcu_argI[4:0]];
		iqentry_cmt [ fcu_id[`QBITS] ] <= (waitctr==64'd1) || signal_i[fcu_argA[4:0]|fcu_argI[4:0]];
  end
  else begin
		iqentry_done[ fcu_id[`QBITS] ] <= `TRUE;
		iqentry_cmt[ fcu_id[`QBITS] ] <= `TRUE;
  end
	// Only safe place to propagate the miss pc is a0.
	iqentry_ma[ fcu_id[`QBITS] ] <= fcu_misspc;
	// takb is looked at only for branches to update the predictor. Here it is
	// unconditionally set, the value will be ignored if it's not a branch.
	iqentry_takb[ fcu_id[`QBITS] ] <= fcu_takb;
	iqentry_out [ fcu_id[`QBITS] ] <= `INV;
	fcu_dataready <= `VAL;
end
// Clear a branch miss when target instruction is fetched.
if (branchmiss) begin
	if ((fetchbuf0_v && fetchbuf0_pc==fcu_misspc) ||
		(fetchbuf1_v && fetchbuf1_pc==fcu_misspc)) begin
		fcu_clearbm <= `TRUE;
		fcu_branch <= `FALSE;
		branchmiss <= `FALSE;
	end
end


if (mem1_available && dramA_v && iqentry_v[ dramA_id[`QBITS] ] && iqentry_load[ dramA_id[`QBITS] ] && !iqentry_stomp[dramA_id[`QBITS]]) begin
	iqentry_res	[ dramA_id[`QBITS] ] <= dramA_bus;
	iqentry_exc	[ dramA_id[`QBITS] ] <= dramA_exc;
	iqentry_done[ dramA_id[`QBITS] ] <= `VAL;
	iqentry_out [ dramA_id[`QBITS] ] <= `INV;
	iqentry_cmt [ dramA_id[`QBITS] ] <= `VAL;
	iqentry_aq  [ dramA_id[`QBITS] ] <= `INV;
end
if (mem2_available && `NUM_MEM > 1 && dramB_v && iqentry_v[ dramB_id[`QBITS] ] && iqentry_load[ dramB_id[`QBITS] ] && !iqentry_stomp[dramB_id[`QBITS]]) begin
	iqentry_res	[ dramB_id[`QBITS] ] <= dramB_bus;
	iqentry_exc	[ dramB_id[`QBITS] ] <= dramB_exc;
	iqentry_done[ dramB_id[`QBITS] ] <= `VAL;
	iqentry_out [ dramB_id[`QBITS] ] <= `INV;
	iqentry_cmt [ dramB_id[`QBITS] ] <= `VAL;
	iqentry_aq  [ dramB_id[`QBITS] ] <= `INV;
end
if (mem3_available && `NUM_MEM > 2 && dramC_v && iqentry_v[ dramC_id[`QBITS] ] && iqentry_load[ dramC_id[`QBITS] ] && !iqentry_stomp[dramC_id[`QBITS]]) begin
	iqentry_res	[ dramC_id[`QBITS] ] <= dramC_bus;
	iqentry_exc	[ dramC_id[`QBITS] ] <= dramC_exc;
	iqentry_done[ dramC_id[`QBITS] ] <= `VAL;
	iqentry_out [ dramC_id[`QBITS] ] <= `INV;
	iqentry_cmt [ dramC_id[`QBITS] ] <= `VAL;
	iqentry_aq  [ dramC_id[`QBITS] ] <= `INV;
//	    if (iqentry_lptr[dram2_id[`QBITS]])
//	    	wbrcd[pcr[5:0]] <= 1'b1;
end

//
// see if anybody else wants the results ... look at lots of buses:
//  - fpu_bus
//  - alu0_bus
//  - alu1_bus
//  - fcu_bus
//  - dram_bus
//  - commit0_bus
//  - commit1_bus
//

for (n = 0; n < QENTRIES; n = n + 1)
begin
	if (`NUM_FPU > 0)
		setargs(n,{1'b0,fpu1_id},fpu1_v,fpu1_bus);
	if (`NUM_FPU > 1)
		setargs(n,{1'b0,fpu2_id},fpu2_v,fpu2_bus);

	// The memory address generated by the ALU should not be posted to be
	// recieved into waiting argument registers. The arguments will be waiting
	// for the result of the memory load, picked up from the dram busses. The
	// only mem operation requiring the alu result bus is the push operation.
	setargs(n,{1'b0,alu0_id},alu0_v & (~alu0_mem | alu0_push),alu0_bus);
	if (`NUM_ALU > 1)
		setargs(n,{1'b0,alu1_id},alu1_v & (~alu1_mem | alu1_push),alu1_bus);

	setargs(n,{1'b0,fcu_id},fcu_wr,fcu_bus);

	setargs(n,{1'b0,dramA_id},dramA_v,dramA_bus);
	if (`NUM_MEM > 1)
		setargs(n,{1'b0,dramB_id},dramB_v,dramB_bus);
	if (`NUM_MEM > 2)
		setargs(n,{1'b0,dramC_id},dramC_v,dramC_bus);

	setargs(n,commit0_id,commit0_v,commit0_bus);
	if (`NUM_CMT > 1)
		setargs(n,commit1_id,commit1_v,commit1_bus);
	if (`NUM_CMT > 2)
		setargs(n,commit2_id,commit2_v,commit2_bus);
`ifndef INLINE_DECODE
	setinsn(n[`QBITS],id1_ido,id1_available&id1_vo,id1_bus);
	if (`NUM_IDU > 1)
		setinsn(n[`QBITS],id2_ido,id2_available&id2_vo,id2_bus);
	if (`NUM_IDU > 2)
		setinsn(n[`QBITS],id3_ido,id3_available&id3_vo,id3_bus);
`endif
end

//
// ISSUE 
//
// determines what instructions are ready to go, then places them
// in the various ALU queues.  
// also invalidates instructions following a branch-miss BEQ or any JALR (STOMP logic)
//
`ifndef INLINE_DECODE
for (n = 0; n < QENTRIES; n = n + 1)
if (id1_available) begin
if (iqentry_id1issue[n] && !iqentry_iv[n] && !(iqentry_v[n] && iqentry_stomp[n])) begin
		id1_vi <= `VAL;
		id1_id			<= n[4:0];
		id1_instr	<= iqentry_rtop[n] ? (
										iqentry_a3_v[n] ? iqentry_a3[n]
`ifdef FU_BYPASS										
		                : (iqentry_a3_s[n] == alu0_id) ? alu0_bus
		                : (iqentry_a3_s[n] == alu1_id) ? alu1_bus
`endif		            
		                : `NOP_INSN)
								 : iqentry_instr[n];
		id1_ven    <= iqentry_ven[n];
		id1_vl     <= iqentry_vl[n];
		id1_thrd   <= iqentry_thrd[n];
		id1_Rt     <= iqentry_tgt[n][4:0];
		id1_pt			<= iqentry_pt[n];
  end
end
if (`NUM_IDU > 1) begin
for (n = 0; n < QENTRIES; n = n + 1)
	if (id2_available) begin
		if (iqentry_id2issue[n] && !iqentry_iv[n] && !(iqentry_v[n] && iqentry_stomp[n])) begin
			id2_vi <= `VAL;
			id2_id			<= n[4:0];
			id2_instr	<= iqentry_rtop[n] ? (
											iqentry_a3_v[n] ? iqentry_a3[n]
`ifdef FU_BYPASS											
			                : (iqentry_a3_s[n] == alu0_id) ? alu0_bus
			                : (iqentry_a3_s[n] == alu1_id) ? alu1_bus
`endif			                
			                : `NOP_INSN)
									 : iqentry_instr[n];
			id2_ven    <= iqentry_ven[n];
			id2_vl     <= iqentry_vl[n];
			id2_thrd   <= iqentry_thrd[n];
			id2_Rt     <= iqentry_tgt[n][4:0];
			id2_pt			<= iqentry_pt[n];
		end
	end
end
if (`NUM_IDU > 2) begin
for (n = 0; n < QENTRIES; n = n + 1)
	if (id3_available) begin
		if (iqentry_id3issue[n] && !iqentry_iv[n] && !(iqentry_v[n] && iqentry_stomp[n])) begin
			id3_vi <= `VAL;
			id3_id			<= n[4:0];
			id3_instr	<= iqentry_rtop[n] ? (
											iqentry_a3_v[n] ? iqentry_a3[n]
`ifdef FU_BYPASS											
			                : (iqentry_a3_s[n] == alu0_id) ? alu0_bus
			                : (iqentry_a3_s[n] == alu1_id) ? alu1_bus
`endif			                
			                : `NOP_INSN)
									 : iqentry_instr[n];
			id3_ven    <= iqentry_ven[n];
			id3_vl     <= iqentry_vl[n];
			id3_thrd   <= iqentry_thrd[n];
			id3_Rt     <= iqentry_tgt[n][4:0];
			id3_pt			<= iqentry_pt[n];
		end
	end
end
`endif	// not INLINE_DECODE

// X's on unused busses cause problems in SIM.
    for (n = 0; n < QENTRIES; n = n + 1)
        if (iqentry_alu0_issue[n] && !(iqentry_v[n] && iqentry_stomp[n])) begin
            if (alu0_available & alu0_done) begin
                 alu0_sourceid	<= n[3:0];
                 alu0_instr	<= iqentry_rtop[n] ? (
`ifdef FU_BYPASS                 									
                 									iqentry_a3_v[n] ? iqentry_a3[n]
			                            : (iqentry_a3_s[n] == alu0_id) ? alu0_bus
			                            : (iqentry_a3_s[n] == alu1_id) ? alu1_bus
			                            : (iqentry_a3_s[n] == fpu1_id && `NUM_FPU > 0) ? fpu1_bus
			                            : `NOP_INSN)
`else			                           
																	iqentry_a3[n]) 
`endif			                            
                 							 : iqentry_instr[n];
                 alu0_sz    <= iqentry_sz[n];
                 alu0_tlb   <= iqentry_tlb[n];
                 alu0_mem   <= iqentry_mem[n];
                 alu0_load  <= iqentry_load[n];
                 alu0_push  <= iqentry_push[n];
                 alu0_shft <= iqentry_shft[n];
                 alu0_pc		<= iqentry_pc[n];
                 alu0_argA	<=
`ifdef FU_BYPASS                  
                 							iqentry_a1_v[n] ? iqentry_a1[n]
                            : (iqentry_a1_s[n] == alu0_id) ? alu0_bus
                            : (iqentry_a1_s[n] == alu1_id) ? alu1_bus
                            : (iqentry_a1_s[n] == fpu1_id && `NUM_FPU > 0) ? fpu1_bus
                            : 64'hDEADDEADDEADDEAD;
`else
														iqentry_a1[n];                            
`endif                            
                 alu0_argB	<= iqentry_imm[n]
                            ? iqentry_a0[n]
`ifdef FU_BYPASS                            
                            : (iqentry_a2_v[n] ? iqentry_a2[n]
                            : (iqentry_a2_s[n] == alu0_id) ? alu0_bus 
                            : (iqentry_a2_s[n] == alu1_id) ? alu1_bus 
                            : (iqentry_a2_s[n] == fpu1_id && `NUM_FPU > 0) ? fpu1_bus
                            : 64'hDEADDEADDEADDEAD);
`else
														: iqentry_a2[n];                         
`endif                            
                 alu0_argC	<=
`ifdef FU_BYPASS                  
                 							iqentry_a3_v[n] ? iqentry_a3[n]
                            : (iqentry_a3_s[n] == alu0_id) ? alu0_bus : alu1_bus;
`else
															iqentry_a3[n];                            
`endif                            
                 alu0_argI	<= iqentry_a0[n];
                 alu0_tgt    <= IsVeins(iqentry_instr[n]) ?
                                {6'h0,1'b1,iqentry_tgt[n][4:0]} | ((
                                							iqentry_a2_v[n] ? iqentry_a2[n][5:0]
                                            : (iqentry_a2_s[n] == alu0_id) ? alu0_bus[5:0]
                                            : (iqentry_a2_s[n] == alu1_id) ? alu1_bus[5:0]
                                            : {4{16'h0000}})) << 6 : 
                                iqentry_tgt[n];
                 alu0_ven    <= iqentry_ven[n];
                 alu0_thrd   <= iqentry_thrd[n];
                 alu0_dataready <= IsSingleCycle(iqentry_instr[n]);
                 alu0_ld <= TRUE;
                 iqentry_out[n] <= `VAL;
            end
        end
	if (`NUM_ALU > 1) begin
    for (n = 0; n < QENTRIES; n = n + 1)
        if (iqentry_alu1_issue[n] && !(iqentry_v[n] && iqentry_stomp[n])) begin
            if (alu1_available && alu1_done) begin
            		if (iqentry_alu0[n])
            			panic <= `PANIC_ALU0ONLY;
                 alu1_sourceid	<= n[3:0];
                 alu1_instr	<= iqentry_instr[n];
                 alu1_sz    <= iqentry_sz[n];
                 alu1_mem   <= iqentry_mem[n];
                 alu1_load  <= iqentry_load[n];
                 alu1_push  <= iqentry_push[n];
                 alu1_shft  <= iqentry_shft[n];
                 alu1_pc		<= iqentry_pc[n];
                 alu1_argA	<=
`ifdef FU_BYPASS                  
                 							iqentry_a1_v[n] ? iqentry_a1[n]
                            : (iqentry_a1_s[n] == alu0_id) ? alu0_bus
                            : (iqentry_a1_s[n] == alu1_id) ? alu1_bus
                            : (iqentry_a1_s[n] == fpu1_id && `NUM_FPU > 0) ? fpu1_bus
                            : 64'hDEADDEADDEADDEAD;
`else
															iqentry_a1[n];                            
`endif                           
                 alu1_argB	<= iqentry_imm[n]
                            ? iqentry_a0[n]
`ifdef FU_BYPASS                           
                            : (iqentry_a2_v[n] ? iqentry_a2[n]
                            : (iqentry_a2_s[n] == alu0_id) ? alu0_bus 
                            : (iqentry_a2_s[n] == alu1_id) ? alu1_bus 
                            : (iqentry_a2_s[n] == fpu1_id && `NUM_FPU > 0) ? fpu1_bus
                            : 64'hDEADDEADDEADDEAD);
`else
														: iqentry_a2[n];
`endif                            
                 alu1_argC	<=
`ifdef FU_BYPASS                 	
                 							iqentry_a3_v[n] ? iqentry_a3[n]
                            : (iqentry_a3_s[n] == alu0_id) ? alu0_bus : alu1_bus;
`else                            
															iqentry_a3[n];
`endif                            
                 alu1_argI	<= iqentry_a0[n];
                 alu1_tgt    <= IsVeins(iqentry_instr[n]) ?
                                {6'h0,1'b1,iqentry_tgt[n][4:0]} | ((iqentry_a2_v[n] ? iqentry_a2[n][5:0]
                                            : (iqentry_a2_s[n] == alu0_id) ? alu0_bus[5:0]
                                            : (iqentry_a2_s[n] == alu1_id) ? alu1_bus[5:0]
                                            : {4{16'h0000}})) << 6 : 
                                iqentry_tgt[n];
                 alu1_ven    <= iqentry_ven[n];
                 alu1_dataready <= IsSingleCycle(iqentry_instr[n]);
                 alu1_ld <= TRUE;
                 iqentry_out[n] <= `VAL;
            end
        end
  end

    for (n = 0; n < QENTRIES; n = n + 1)
        if (iqentry_fpu1_issue[n] && !(iqentry_v[n] && iqentry_stomp[n])) begin
            if (fpu1_available & fpu1_done) begin
                 fpu1_sourceid	<= n[3:0];
                 fpu1_instr	<= iqentry_instr[n];
                 fpu1_pc		<= iqentry_pc[n];
                 fpu1_argA	<=
`ifdef FU_BYPASS                  
                 							iqentry_a1_v[n] ? iqentry_a1[n]
                            : (iqentry_a1_s[n] == alu0_id) ? alu0_bus 
                            : (iqentry_a1_s[n] == alu1_id) ? alu1_bus 
                            : (iqentry_a1_s[n] == fpu1_id && `NUM_FPU > 0) ? fpu1_bus
                            : 64'hDEADDEADDEADDEAD;
`else
															iqentry_a1[n];                          
`endif                            
                 fpu1_argB	<=
`ifdef FU_BYPASS                  
                 							(iqentry_a2_v[n] ? iqentry_a2[n]
                            : (iqentry_a2_s[n] == alu0_id) ? alu0_bus 
                            : (iqentry_a2_s[n] == alu1_id) ? alu1_bus 
                            : (iqentry_a2_s[n] == fpu1_id && `NUM_FPU > 0) ? fpu1_bus
                            : 64'hDEADDEADDEADDEAD);
`else
															iqentry_a2[n];
`endif                            
                 fpu1_argC	<=
`ifdef FU_BYPASS                 
                 							 iqentry_a3_v[n] ? iqentry_a3[n]
                            : (iqentry_a3_s[n] == alu0_id) ? alu0_bus : alu1_bus;
`else
															iqentry_a3[n];                           
`endif                            
                 fpu1_argI	<= iqentry_a0[n];
                 fpu1_dataready <= `VAL;
                 fpu1_ld <= TRUE;
                 iqentry_out[n] <= `VAL;
            end
        end

    for (n = 0; n < QENTRIES; n = n + 1)
        if (`NUM_FPU > 1 && iqentry_fpu2_issue[n] && !(iqentry_v[n] && iqentry_stomp[n])) begin
            if (fpu2_available & fpu2_done) begin
                 fpu2_sourceid	<= n[3:0];
                 fpu2_instr	<= iqentry_instr[n];
                 fpu2_pc		<= iqentry_pc[n];
                 fpu2_argA	<=
`ifdef FU_BYPASS                  
                 							iqentry_a1_v[n] ? iqentry_a1[n]
                            : (iqentry_a1_s[n] == alu0_id) ? alu0_bus 
                            : (iqentry_a1_s[n] == alu1_id) ? alu1_bus 
                            : (iqentry_a1_s[n] == fpu1_id && `NUM_FPU > 0) ? fpu1_bus
                            : 64'hDEADDEADDEADDEAD;
`else
															iqentry_a1[n];                          
`endif                            
                 fpu2_argB	<=
`ifdef FU_BYPASS                  
                 							(iqentry_a2_v[n] ? iqentry_a2[n]
                            : (iqentry_a2_s[n] == alu0_id) ? alu0_bus 
                            : (iqentry_a2_s[n] == alu1_id) ? alu1_bus 
                            : (iqentry_a2_s[n] == fpu1_id && `NUM_FPU > 0) ? fpu1_bus
                            : 64'hDEADDEADDEADDEAD);
`else
															iqentry_a2[n];
`endif                            
                 fpu2_argC	<=
`ifdef FU_BYPASS                 
                 							 iqentry_a3_v[n] ? iqentry_a3[n]
                            : (iqentry_a3_s[n] == alu0_id) ? alu0_bus : alu1_bus;
`else
															iqentry_a3[n];                           
`endif                            
                 fpu2_argI	<= iqentry_a0[n];
                 fpu2_dataready <= `VAL;
                 fpu2_ld <= TRUE;
                 iqentry_out[n] <= `VAL;
            end
        end

    for (n = 0; n < QENTRIES; n = n + 1)
        if (iqentry_fcu_issue[n] && !(iqentry_v[n] && iqentry_stomp[n])) begin
            if (fcu_done) begin
                 fcu_sourceid	<= n[3:0];
                 fcu_instr	<= iqentry_instr[n];
                 fcu_insln  <= iqentry_insln[n];
                 fcu_pc		<= iqentry_pc[n];
                 fcu_nextpc <= iqentry_pc[n] + iqentry_insln[n];
                 fcu_pt     <= iqentry_pt[n];
                 fcu_brdisp <= {{52{iqentry_instr[n][31]}},iqentry_instr[n][31:23],iqentry_instr[n][17:16],1'b0};
                 fcu_branch <= iqentry_br[n];
                 fcu_call    <= IsCall(iqentry_instr[n])|iqentry_jal[n];
                 fcu_jal     <= iqentry_jal[n];
                 fcu_ret    <= iqentry_ret[n];
                 fcu_brk  <= iqentry_brk[n];
                 fcu_rti  <= iqentry_rti[n];
                 fcu_pc		<= iqentry_pc[n];
                 fcu_argA	<= iqentry_a1_v[n] ? iqentry_a1[n]
                            : (iqentry_a1_s[n] == alu0_id) ? alu0_bus
                            : (iqentry_a1_s[n] == fpu1_id && `NUM_FPU > 0) ? fpu1_bus
                            : alu1_bus;
`ifdef SUPPORT_SMT                            
                 fcu_argB	<= iqentry_rti[n] ? epc0[iqentry_thrd[n]]
`else
                 fcu_argB	<= iqentry_rti[n] ? epc0
`endif                 
                 			: (iqentry_a2_v[n] ? iqentry_a2[n]
                            : (iqentry_a2_s[n] == alu0_id) ? alu0_bus 
                            : (iqentry_a2_s[n] == fpu1_id && `NUM_FPU > 0) ? fpu1_bus
                            : alu1_bus);
                 waitctr	    <= iqentry_imm[n]
                            ? iqentry_a0[n]
                            : (iqentry_a2_v[n] ? iqentry_a2[n]
                            : (iqentry_a2_s[n] == alu0_id) ? alu0_bus : alu1_bus);
                 fcu_argC	<= iqentry_a3_v[n] ? iqentry_a3[n]
                            : (iqentry_a3_s[n] == alu0_id) ? alu0_bus : alu1_bus;
                 fcu_argI	<= iqentry_a0[n];
                 fcu_thrd   <= iqentry_thrd[n];
                 fcu_dataready <= `VAL;
                 fcu_clearbm <= `FALSE;
                 fcu_ld <= TRUE;
                 fcu_timeout <= 8'h00;
                 iqentry_out[n] <= `VAL;
                 fcu_done <= `FALSE;
            end
        end
//
// MEMORY
//
// update the memory queues and put data out on bus if appropriate
//

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

//	if (dram0 != `DRAMSLOT_AVAIL)	dram0 <= dram0 + 2'd1;
//	if (dram1 != `DRAMSLOT_AVAIL)	dram1 <= dram1 + 2'd1;
//	if (dram2 != `DRAMSLOT_AVAIL)	dram2 <= dram2 + 2'd1;

// Flip the ready status to available. Used for loads or stores.

if (dram0 == `DRAMREQ_READY)
	dram0 <= `DRAMSLOT_AVAIL;
if (dram1 == `DRAMREQ_READY && `NUM_MEM > 1)
	dram1 <= `DRAMSLOT_AVAIL;
if (dram2 == `DRAMREQ_READY && `NUM_MEM > 2)
	dram2 <= `DRAMSLOT_AVAIL;

// grab requests that have finished and put them on the dram_bus

if (dram0 == `DRAMREQ_READY && dram0_load) begin
	dramA_v <= !iqentry_stomp[dram0_id[`QBITS]];
	dramA_id <= dram0_id;
	dramA_exc <= dram0_exc;
	dramA_bus <= fnDatiAlign(dram0_instr,dram0_addr,rdat0);
end
//    else
//    	dramA_v <= `INV;
if (dram1 == `DRAMREQ_READY && dram1_load && `NUM_MEM > 1) begin
	dramB_v <= !iqentry_stomp[dram1_id[`QBITS]];
	dramB_id <= dram1_id;
	dramB_exc <= dram1_exc;
	dramB_bus <= fnDatiAlign(dram1_instr,dram1_addr,rdat1);
end
//    else
//    	dramB_v <= `INV;
if (dram2 == `DRAMREQ_READY && dram2_load && `NUM_MEM > 2) begin
	dramC_v <= !iqentry_stomp[dram2_id[`QBITS]];
	dramC_id <= dram2_id;
	dramC_exc <= dram2_exc;
	dramC_bus <= fnDatiAlign(dram2_instr,dram2_addr,rdat2);
end

if (dram0 == `DRAMREQ_READY && dram0_store)
	$display("m[%h] <- %h", dram0_addr, dram0_data);
if (dram1 == `DRAMREQ_READY && dram1_store && `NUM_MEM > 1)
	$display("m[%h] <- %h", dram1_addr, dram1_data);
if (dram2 == `DRAMREQ_READY && dram2_store && `NUM_MEM > 2)
	$display("m[%h] <- %h", dram2_addr, dram2_data);

//
// determine if the instructions ready to issue can, in fact, issue.
// "ready" means that the instruction has valid operands but has not gone yet
iqentry_memissue <= memissue;
missue_count <= issue_count;

if (dram0 == `DRAMSLOT_AVAIL)	 dram0_exc <= `FLT_NONE;
if (dram1 == `DRAMSLOT_AVAIL)	 dram1_exc <= `FLT_NONE;
if (dram2 == `DRAMSLOT_AVAIL)	 dram2_exc <= `FLT_NONE;

for (n = 0; n < QENTRIES; n = n + 1)
	if (iqentry_v[n] && iqentry_stomp[n]) begin
		iqentry_v[n] <= `INV;
		iqentry_iv[n] <= `INV;
		iqentry_agen[n] <= `INV;
		iqentry_out[n] <= `INV;
		iqentry_done[n] <= `INV;
		iqentry_cmt[n] <= `INV;
		if (dram0_id[`QBITS] == n[`QBITS])  begin
			if (dram0==`DRAMSLOT_HASBUS)
				wb_nack();
			dram0_load <= `FALSE;
			dram0_store <= `FALSE;
			dram0_rmw <= `FALSE;
			dram0 <= `DRAMSLOT_AVAIL;
		end
		if (dram1_id[`QBITS] == n[`QBITS])  begin
			if (dram1==`DRAMSLOT_HASBUS)
				wb_nack();
			dram1_load <= `FALSE;
			dram1_store <= `FALSE;
			dram1_rmw <= `FALSE;
			dram1 <= `DRAMSLOT_AVAIL;
		end
		if (dram2_id[`QBITS] == n[`QBITS])  begin
			if (dram2==`DRAMSLOT_HASBUS)
				wb_nack();
			dram2_load <= `FALSE;
			dram2_store <= `FALSE;
			dram2_rmw <= `FALSE;
			dram2 <= `DRAMSLOT_AVAIL;
		end
	end

if (last_issue0 < QENTRIES)
	tDram0Issue(last_issue0);
if (last_issue1 < QENTRIES)
	tDram1Issue(last_issue1);
if (last_issue2 < QENTRIES)
	tDram2Issue(last_issue2);


for (n = 0; n < QENTRIES; n = n + 1)
begin
	if (!iqentry_v[n])
		iqentry_done[n] <= FALSE;
end
      
if (ohead[0]==heads[0])
	cmt_timer <= cmt_timer + 9'd1;
else
	cmt_timer <= 9'd0;
if (cmt_timer==9'd300) begin
	iqentry_cmt[heads[0]] <= `VAL;
	iqentry_exc[heads[0]] <= `FLT_CMT;
	cmt_timer <= 9'd0;
end

//
// COMMIT PHASE (dequeue only ... not register-file update)
//
// look at heads[0] and heads[1] and let 'em write to the register file if they are ready
//
//    always @(posedge clk) begin: commit_phase
ohead[0] <= heads[0];
ohead[1] <= heads[1];
ohead[2] <= heads[2];
ocommit0_v <= commit0_v;
ocommit1_v <= commit1_v;
ocommit2_v <= commit2_v;

oddball_commit(commit0_v, heads[0], heads[0]!=ohead[0] || commit0_v != ocommit0_v);
if (`NUM_CMT > 1)
	oddball_commit(commit1_v, heads[1], heads[1]!=ohead[1] || commit1_v != ocommit1_v);
if (`NUM_CMT > 2)
	oddball_commit(commit2_v, heads[2], heads[2]!=ohead[2] || commit2_v != ocommit2_v);

// Fetch and queue are limited to two instructions per cycle, so we might as
// well limit retiring to two instructions max to conserve logic.
//
if (~|panic)
  casez ({ iqentry_v[heads[0]],
		iqentry_cmt[heads[0]],
		iqentry_v[heads[1]],
		iqentry_cmt[heads[1]],
		iqentry_v[heads[2]],
		iqentry_cmt[heads[2]]})

	// retire 3
	6'b0?_0?_0?:
		if (heads[0] != tail0 && heads[1] != tail0 && heads[2] != tail0) begin
				head_inc(3);
		end
		else if (heads[0] != tail0 && heads[1] != tail0) begin
 		    head_inc(2);
		end
		else if (heads[0] != tail0) begin
		    head_inc(1);
		end
	6'b0?_0?_10:	;
	6'b0?_0?_11:
		if (`NUM_CMT > 2 || iqentry_tgt[heads[2]][4:0]==5'd0) begin
      iqentry_v[heads[2]] <= `INV;
      head_inc(3);
		end
		else begin
      head_inc(2);
		end

	// retire 1 (wait for regfile for heads[1])
	6'b0?_10_??:
		head_inc(1);

	// retire 2
	6'b0?_11_0?,
	6'b0?_11_10:
        if (`NUM_CMT > 1 || iqentry_tgt[heads[1]]==12'd0) begin
          iqentry_v[heads[1]] <= `INV;
          head_inc(2);
        end
        else begin
        	head_inc(1);
      	end
  6'b0?_11_11:
        if (`NUM_CMT > 2 || (`NUM_CMT > 1 && iqentry_tgt[heads[2]] == 12'd0 && !iqentry_oddball[heads[2]] && ~|iqentry_exc[heads[2]])) begin
        	iqentry_v[heads[1]] <= `INV;
          iqentry_v[heads[2]] <= `INV;
        	head_inc(3);
      	end	
      	else if (`NUM_CMT > 1 || iqentry_tgt[heads[1]]==12'd0) begin
        	iqentry_v[heads[1]] <= `INV;
        	head_inc(2);
      	end
      	else
      		head_inc(1);
  6'b10_??_??:	;
  6'b11_0?_0?:
  	if (heads[1] != tail0 && heads[2] != tail0) begin
			iqentry_v[heads[0]] <= `INV;
			head_inc(3);
  	end
  	else if (heads[1] != tail0) begin
			iqentry_v[heads[0]] <= `INV;
			head_inc(2);
  	end
  	else begin
			iqentry_v[heads[0]] <= `INV;
			head_inc(1);
  	end
  6'b11_0?_10:
  	if (heads[1] != tail0) begin
			iqentry_v[heads[0]] <= `INV;
			head_inc(2);
  	end
  	else begin
			iqentry_v[heads[0]] <= `INV;
			head_inc(1);
  	end
  6'b11_0?_11:
  	if (heads[1] != tail0) begin
  		if (`NUM_CMT > 2 || (iqentry_tgt[heads[2]]==12'd0 && !iqentry_oddball[heads[2]] && ~|iqentry_exc[heads[2]])) begin
				iqentry_v[heads[0]] <= `INV;
				iqentry_v[heads[2]] <= `INV;
				head_inc(3);
  		end
  		else begin
				iqentry_v[heads[0]] <= `INV;
				head_inc(2);
			end
  	end
  	else begin
			iqentry_v[heads[0]] <= `INV;
			head_inc(1);
  	end
  6'b11_10_??:
  	begin
			iqentry_v[heads[0]] <= `INV;
			head_inc(1);
  	end
  6'b11_11_0?:
  	if (`NUM_CMT > 1 && heads[2] != tail0) begin
			iqentry_v[heads[0]] <= `INV;
			iqentry_v[heads[1]] <= `INV;
			head_inc(3);
  	end
  	else if (iqentry_tgt[heads[1]]== 12'd0 && heads[2] != tail0) begin
			iqentry_v[heads[0]] <= `INV;
			iqentry_v[heads[1]] <= `INV;
			head_inc(3);
  	end
  	else if (`NUM_CMT > 1 || iqentry_tgt[heads[1]]==12'd0) begin
			iqentry_v[heads[0]] <= `INV;
			iqentry_v[heads[1]] <= `INV;
			head_inc(2);
  	end
  	else begin
			iqentry_v[heads[0]] <= `INV;
			head_inc(1);
  	end
  6'b11_11_10:
  	if (`NUM_CMT > 1 || iqentry_tgt[heads[1]]==12'd0) begin
			iqentry_v[heads[0]] <= `INV;
			iqentry_v[heads[1]] <= `INV;
			head_inc(2);
  	end
  	else begin
			iqentry_v[heads[0]] <= `INV;
			head_inc(1);
  	end
	6'b11_11_11:
		if (`NUM_CMT > 2 || (`NUM_CMT > 1 && iqentry_tgt[heads[2]]==12'd0 && !iqentry_oddball[heads[2]] && ~|iqentry_exc[heads[2]])) begin
			iqentry_v[heads[0]] <= `INV;
			iqentry_v[heads[1]] <= `INV;
			iqentry_v[heads[2]] <= `INV;
			head_inc(3);
		end
		else if (`NUM_CMT > 1 || iqentry_tgt[heads[1]]==12'd0) begin
			iqentry_v[heads[0]] <= `INV;
			iqentry_v[heads[1]] <= `INV;
			head_inc(2);
		end
		else begin
			iqentry_v[heads[0]] <= `INV;
			head_inc(1);
		end
	default:
		begin
			$display("head_inc: Uncoded case %b",{ iqentry_v[heads[0]],
				iqentry_cmt[heads[0]],
				iqentry_v[heads[1]],
				iqentry_cmt[heads[1]],
				iqentry_v[heads[2]],
				iqentry_cmt[heads[2]]});
			$stop;
		end
  endcase


rf_source[0] <= 0;
L1_wr0 <= FALSE;
L1_wr1 <= FALSE;
L1_wr2 <= FALSE;
L1_invline <= FALSE;
icnxt <= FALSE;
L2_nxt <= FALSE;
// Instruction cache state machine.
// On a miss first see if the instruction is in the L2 cache. No need to go to
// the BIU on an L1 miss.
// If not the machine will wait until the BIU loads the L2 cache.

// Capture the previous ic state, used to determine how long to wait in
// icstate #4.
picstate <= icstate;
case(icstate)
IDLE:
	// If the bus unit is busy doing an update involving L1_adr or L2_adr
	// we have to wait.
	if (bstate != B_ICacheAck && bstate != B_ICacheNack) begin
		if (!ihit0) begin
			L1_adr <= {pcr[5:0],pc0[31:5],5'h0};
			L2_adr <= {pcr[5:0],pc0[31:5],5'h0};
			L1_invline <= TRUE;
			icwhich <= 2'b00;
			iccnt <= 3'b00;
			icstate <= IC2;
		end
		else if (!ihit1 && `WAYS > 1) begin
			if (thread_en) begin
				L1_adr <= {pcr[5:0],pc1[31:5],5'h0};
				L2_adr <= {pcr[5:0],pc1[31:5],5'h0};
			end
			else begin
				L1_adr <= {pcr[5:0],pc0plus6[31:5],5'h0};
				L2_adr <= {pcr[5:0],pc0plus6[31:5],5'h0};
			end
			L1_invline <= TRUE;
			icwhich <= 2'b01;
			iccnt <= 3'b00;
			icstate <= IC2;
		end
		else if (!ihit2 && `WAYS > 2) begin
			if (thread_en) begin
				L1_adr <= {pcr[5:0],pc2[31:5],5'h0};
				L2_adr <= {pcr[5:0],pc2[31:5],5'h0};
			end
			else begin
				L1_adr <= {pcr[5:0],pc0plus12[31:5],5'h0};
				L2_adr <= {pcr[5:0],pc0plus12[31:5],5'h0};
			end
			L1_invline <= TRUE;
			icwhich <= 2'b10;
			iccnt <= 3'b00;
			icstate <= IC2;
		end
	end
IC2:     icstate <= IC3;
IC3:     icstate <= IC3a;
IC3a:     icstate <= IC_WaitL2;
// If data was in the L2 cache already there's no need to wait on the
// BIU to retrieve data. It can be determined if the hit signal was
// already active when this state was entered in which case waiting
// will do no good.
// The IC machine will stall in this state until the BIU has loaded the
// L2 cache. 
IC_WaitL2: 
	if (ihitL2 && picstate==IC3a) begin
		L1_en <= 9'h1FF;
		L1_wr0 <= TRUE;
		L1_wr1 <= TRUE && `WAYS > 1;
		L1_wr2 <= TRUE && `WAYS > 2;
		L1_adr <= L2_adr;
		L2_rdat <= L2_dato;
		icstate <= IC5;
	end
	else if (bstate!=B_ICacheNack)
		;
	else begin
		L1_en <= 9'h1FF;
		L1_wr0 <= TRUE;
		L1_wr1 <= TRUE && `WAYS > 1;
		L1_wr2 <= TRUE && `WAYS > 2;
		L1_adr <= L2_adr;
		// L2_rdat set below while loading cache line
		//L2_rdat <= L2_dato;
		icstate <= IC5;
	end
IC5: 
	begin
		L1_en <= 9'h000;
		L1_wr0 <= FALSE;
		L1_wr1 <= FALSE;
		L1_wr2 <= FALSE;
		icstate <= IC6;
	end
IC6:  icstate <= IC7;
IC7:	icstate <= IC_Next;
IC_Next:
  begin
   icstate <= IDLE;
   icnxt <= TRUE;
	end
default:     icstate <= IDLE;
endcase

if (mem1_available && dram0_load)
case(dram0)
`DRAMSLOT_AVAIL:	;
`DRAMSLOT_BUSY:
	dram0 <= dram0 + !dram0_unc;
3'd2:
	dram0 <= dram0 + 3'd1;
3'd3:
	dram0 <= dram0 + 3'd1;
3'd4:
	if (iqentry_v[dram0_id[`QBITS]] && !iqentry_stomp[dram0_id[`QBITS]]) begin
		if (dhit0)
			dram0 <= `DRAMREQ_READY;
		else
			dram0 <= `DRAMSLOT_REQBUS;
	end
	else begin
		dram0 <= `DRAMSLOT_AVAIL;
		dram0_load <= `FALSE;
	end
`DRAMSLOT_REQBUS:	;
`DRAMSLOT_HASBUS:	;
`DRAMREQ_READY:		;
endcase

if (mem2_available && dram1_load && `NUM_MEM > 1)
case(dram1)
`DRAMSLOT_AVAIL:	;
`DRAMSLOT_BUSY:
	dram1 <= dram1 + !dram1_unc;
3'd2:
	dram1 <= dram1 + 3'd1;
3'd3:
	dram1 <= dram1 + 3'd1;
3'd4:
	if (iqentry_v[dram1_id[`QBITS]] && !iqentry_stomp[dram1_id[`QBITS]]) begin
		if (dhit1)
			dram1 <= `DRAMREQ_READY;
		else
			dram1 <= `DRAMSLOT_REQBUS;
	end
	else begin
		dram1 <= `DRAMSLOT_AVAIL;
		dram1_load <= `FALSE;
	end
`DRAMSLOT_REQBUS:	;
`DRAMSLOT_HASBUS:	;
`DRAMREQ_READY:		;
endcase

if (mem3_available && dram2_load && `NUM_MEM > 2)
case(dram2)
`DRAMSLOT_AVAIL:	;
`DRAMSLOT_BUSY:
	dram2 <= dram2 + !dram2_unc;
3'd2:
	dram2 <= dram2 + 3'd1;
3'd3:
	dram2 <= dram2 + 3'd1;
3'd4:
	if (iqentry_v[dram2_id[`QBITS]] && !iqentry_stomp[dram2_id[`QBITS]]) begin
		if (dhit2)
			dram2 <= `DRAMREQ_READY;
		else
			dram2 <= `DRAMSLOT_REQBUS;
	end
	else begin
		dram2 <= `DRAMSLOT_AVAIL;
		dram2_load <= `FALSE;
	end
`DRAMSLOT_REQBUS:	;
`DRAMSLOT_HASBUS:	;
`DRAMREQ_READY:		;
endcase


// Bus Interface Unit (BIU)
// Interfaces to the external bus which is WISHBONE compatible.
// Stores take precedence over other operations.
// Next data cache read misses are serviced.
// Uncached data reads are serviced.
// Finally L2 instruction cache misses are serviced.//
// set the IQ entry == DONE as soon as the SW is let loose to the memory system
//
`ifndef HAS_WB
if (mem1_available && dram0 == `DRAMSLOT_BUSY && dram0_store && !iqentry_stomp[dram0_id[`QBITS]]) begin
	if ((alu0_v && (dram0_id[`QBITS] == alu0_id[`QBITS])) || (alu1_v && (dram0_id[`QBITS] == alu1_id[`QBITS])))	 panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram0_id[`QBITS] ] <= `VAL;
	iqentry_out[ dram0_id[`QBITS] ] <= `INV;
end
if (mem2_available && `NUM_MEM > 1 && dram1 == `DRAMSLOT_BUSY && dram1_store && !iqentry_stomp[dram1_id[`QBITS]]) begin
	if ((alu0_v && (dram1_id[`QBITS] == alu0_id[`QBITS])) || (alu1_v && (dram1_id[`QBITS] == alu1_id[`QBITS])))	 panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram1_id[`QBITS] ] <= `VAL;
	iqentry_out[ dram1_id[`QBITS] ] <= `INV;
end
if (mem3_available && `NUM_MEM > 2 && dram2 == `DRAMSLOT_BUSY && dram2_store && !iqentry_stomp[dram2_id[`QBITS]]) begin
	if ((alu0_v && (dram2_id[`QBITS] == alu0_id[`QBITS])) || (alu1_v && (dram2_id[`QBITS] == alu1_id[`QBITS])))	 panic <= `PANIC_MEMORYRACE;
	iqentry_done[ dram2_id[`QBITS] ] <= `VAL;
	iqentry_out[ dram2_id[`QBITS] ] <= `INV;
end
`endif

`ifdef HAS_WB
  if (mem1_available && dram0==`DRAMSLOT_BUSY && dram0_store && !iqentry_stomp[dram0_id[`QBITS]]) begin
		if (wbptr<`WB_DEPTH-1) begin
			dram0 <= `DRAMREQ_READY;
			dram0_instr[`INSTRUCTION_OP] <= `NOP;
			wb_update(
				dram0_id,
				`FALSE,
				fnSelect(dram0_instr,dram0_addr),
				dram0_ol,
				dram0_addr,
				fnDato(dram0_instr,dram0_data)
			);
			iqentry_done[ dram0_id[`QBITS] ] <= `VAL;
			iqentry_out[ dram0_id[`QBITS] ] <= `INV;
		end
  end
  else if (mem2_available && dram1==`DRAMSLOT_BUSY && dram1_store && !iqentry_stomp[dram1_id[`QBITS]] && `NUM_MEM > 1) begin
		if (wbptr<`WB_DEPTH-1) begin
			dram1 <= `DRAMREQ_READY;
      dram1_instr[`INSTRUCTION_OP] <= `NOP;
			wb_update(
				dram1_id,
				`FALSE,
				fnSelect(dram1_instr,dram1_addr),
				dram1_ol,
				dram1_addr,
				fnDato(dram1_instr,dram1_data)
			);
			iqentry_done[ dram1_id[`QBITS] ] <= `VAL;
			iqentry_out[ dram1_id[`QBITS] ] <= `INV;
		end
  end
  else if (mem3_available && dram2==`DRAMSLOT_BUSY && dram2_store && !iqentry_stomp[dram2_id[`QBITS]] && `NUM_MEM > 2) begin
		if (wbptr<`WB_DEPTH-1) begin
			dram2 <= `DRAMREQ_READY;
      dram2_instr[`INSTRUCTION_OP] <= `NOP;
			wb_update(
				dram2_id,
				`FALSE,
				fnSelect(dram2_instr,dram2_addr),
				dram2_ol,
				dram2_addr,
				fnDato(dram2_instr,dram2_data)
			);
			iqentry_done[ dram2_id[`QBITS] ] <= `VAL;
			iqentry_out[ dram2_id[`QBITS] ] <= `INV;
		end
  end
`endif

case(bstate)
BIDLE:
	begin
		isCAS <= FALSE;
		isAMO <= FALSE;
		isInc <= FALSE;
		isSpt <= FALSE;
		isRMW <= FALSE;
		rdvq <= 1'b0;
		errq <= 1'b0;
		exvq <= 1'b0;
		bwhich <= 2'b00;
		preload <= FALSE;
`ifdef HAS_WB
		if (wb_v[0] & wb_en & ~acki & ~cyc) begin
			cyc <= `HIGH;
			stb_o <= `HIGH;
			we <= `HIGH;
			sel_o <= wb_sel[0];
			vadr <= wb_addr[0];
			dat_o <= wb_data[0];
			ol_o  <= wb_ol[0];
			wbo_id <= wb_id[0];
     	isStore <= TRUE;
			bstate <= wb_rmw[0] ? B12 : B_StoreAck;
			wb_v[0] <= `INV;
		end
		if (wb_v[0]==`INV && !writing_wb) begin
			for (j = 1; j < `WB_DEPTH; j = j + 1) begin
	     	wb_v[j-1] <= wb_v[j];
	     	wb_id[j-1] <= wb_id[j];
	     	wb_rmw[j-1] <= wb_rmw[j];
	     	wb_sel[j-1] <= wb_sel[j];
	     	wb_addr[j-1] <= wb_addr[j];
	     	wb_data[j-1] <= wb_data[j];
	     	wb_ol[j-1] <= wb_ol[j];
	     	if (wbptr > 2'd0)
	     		wbptr <= wbptr - 2'd1;
    	end
    	wb_v[`WB_DEPTH-1] <= `INV;
    	wb_rmw[`WB_DEPTH-1] <= `FALSE;
    end

`endif
      if (~|wb_v && mem1_available && dram0==`DRAMSLOT_BUSY && dram0_rmw) begin
`ifdef SUPPORT_DBG      
            if (dbg_smatch0|dbg_lmatch0) begin
                 dramA_v <= `TRUE;
                 dramA_id <= dram0_id;
                 dramA_exc <= `FLT_DBG;
                 dramA_bus <= 64'h0;
                 dram0 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            if (!acki) begin
                 isRMW <= dram0_rmw;
                 isCAS <= IsCAS(dram0_instr);
                 isAMO <= IsAMO(dram0_instr);
                 isInc <= IsInc(dram0_instr);
                 casid <= dram0_id;
                 bwhich <= 2'b00;
                 dram0 <= `DRAMSLOT_HASBUS;
                 cyc <= `HIGH;
                 stb_o <= `HIGH;
                 sel_o <= fnSelect(dram0_instr,dram0_addr);
                 vadr <= dram0_addr;
                 dat_o <= fnDato(dram0_instr,dram0_data);
                 ol_o  <= dram0_ol;
                 bstate <= B12;
            end
        end
        else if (~|wb_v && mem2_available && dram1==`DRAMSLOT_BUSY && dram1_rmw && `NUM_MEM > 1) begin
`ifdef SUPPORT_DBG        	
            if (dbg_smatch1|dbg_lmatch1) begin
                 dramB_v <= `TRUE;
                 dramB_id <= dram1_id;
                 dramB_exc <= `FLT_DBG;
                 dramB_bus <= 64'h0;
                 dram1 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            if (!acki) begin
                 isRMW <= dram1_rmw;
                 isCAS <= IsCAS(dram1_instr);
                 isAMO <= IsAMO(dram1_instr);
                 isInc <= IsInc(dram1_instr);
                 casid <= dram1_id;
                 bwhich <= 2'b01;
                 dram1 <= `DRAMSLOT_HASBUS;
                 cyc <= `HIGH;
                 stb_o <= `HIGH;
                 sel_o <= fnSelect(dram1_instr,dram1_addr);
                 vadr <= dram1_addr;
                 dat_o <= fnDato(dram1_instr,dram1_data);
                 ol_o  <= dram1_ol;
                 bstate <= B12;
            end
        end
        else if (~|wb_v && mem3_available && dram2==`DRAMSLOT_BUSY && dram2_rmw && `NUM_MEM > 2) begin
`ifdef SUPPORT_DBG        	
            if (dbg_smatch2|dbg_lmatch2) begin
                 dramC_v <= `TRUE;
                 dramC_id <= dram2_id;
                 dramC_exc <= `FLT_DBG;
                 dramC_bus <= 64'h0;
                 dram2 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            if (!acki) begin
                 isRMW <= dram2_rmw;
                 isCAS <= IsCAS(dram2_instr);
                 isAMO <= IsAMO(dram2_instr);
                 isInc <= IsInc(dram2_instr);
                 casid <= dram2_id;
                 bwhich <= 2'b10;
                 dram2 <= `DRAMSLOT_HASBUS;
                 cyc <= `HIGH;
                 stb_o <= `HIGH;
                 sel_o <= fnSelect(dram2_instr,dram2_addr);
                 vadr <= dram2_addr;
                 dat_o <= fnDato(dram2_instr,dram2_data);
                 ol_o  <= dram2_ol;
                 bstate <= B12;
            end
        end
`ifndef HAS_WB
				// Check write buffer enable ?
        else if (mem1_available && dram0==`DRAMSLOT_BUSY && dram0_store) begin
`ifdef SUPPORT_DBG        	
            if (dbg_smatch0) begin
                 dramA_v <= `TRUE;
                 dramA_id <= dram0_id;
                 dramA_exc <= `FLT_DBG;
                 dramA_bus <= 64'h0;
                 dram0 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            begin
							bwhich <= 2'b00;
							if (!acki) begin                 
								dram0 <= `DRAMSLOT_HASBUS;
								dram0_instr[`INSTRUCTION_OP] <= `NOP;
                cyc <= `HIGH;
                stb_o <= `HIGH;
                sel_o <= fnSelect(dram0_instr,dram0_addr);
                vadr <= dram0_addr;
                dat_o <= fnDato(dram0_instr,dram0_data);
                ol_o  <= dram0_ol;
			        	isStore <= TRUE;
                bstate <= B_StoreAck;
              end
//                 cr_o <= IsSWC(dram0_instr);
            end
        end
        else if (mem2_available && dram1==`DRAMSLOT_BUSY && dram1_store && `NUM_MEM > 1) begin
`ifdef SUPPORT_DBG        	
            if (dbg_smatch1) begin
                 dramB_v <= `TRUE;
                 dramB_id <= dram1_id;
                 dramB_exc <= `FLT_DBG;
                 dramB_bus <= 64'h0;
                 dram1 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            begin
                 bwhich <= 2'b01;
							if (!acki) begin
                dram1 <= `DRAMSLOT_HASBUS;
                dram1_instr[`INSTRUCTION_OP] <= `NOP;
                cyc <= `HIGH;
                stb_o <= `HIGH;
                sel_o <= fnSelect(dram1_instr,dram1_addr);
                vadr <= dram1_addr;
                dat_o <= fnDato(dram1_instr,dram1_data);
                ol_o  <= dram1_ol;
			        	isStore <= TRUE;
                bstate <= B_StoreAck;
              end
//                 cr_o <= IsSWC(dram0_instr);
            end
        end
        else if (mem3_available && dram2==`DRAMSLOT_BUSY && dram2_store && `NUM_MEM > 2) begin
`ifdef SUPPORT_DBG        	
            if (dbg_smatch2) begin
                 dramC_v <= `TRUE;
                 dramC_id <= dram2_id;
                 dramC_exc <= `FLT_DBG;
                 dramC_bus <= 64'h0;
                 dram2 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            begin
                 bwhich <= 2'b10;
							if (!acki) begin
                dram2 <= `DRAMSLOT_HASBUS;
                dram2_instr[`INSTRUCTION_OP] <= `NOP;
                cyc <= `HIGH;
                stb_o <= `HIGH;
                sel_o <= fnSelect(dram2_instr,dram2_addr);
                vadr <= dram2_addr;
                dat_o <= fnDato(dram2_instr,dram2_data);
                ol_o  <= dram2_ol;
				       	isStore <= TRUE;
                bstate <= B_StoreAck;
              end
//                 cr_o <= IsSWC(dram0_instr);
            end
        end
`endif
        // Check for read misses on the data cache
        else if (~|wb_v && mem1_available && !dram0_unc && dram0==`DRAMSLOT_REQBUS && dram0_load) begin
`ifdef SUPPORT_DBG        	
            if (dbg_lmatch0) begin
                 dramA_v <= `TRUE;
                 dramA_id <= dram0_id;
                 dramA_exc <= `FLT_DBG;
                 dramA_bus <= 64'h0;
                 dram0 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            begin
                 dram0 <= `DRAMSLOT_HASBUS;
                 bwhich <= 2'b00;
                 preload <= dram0_preload;
                 bstate <= B_DCacheLoadStart; 
            end
        end
        else if (~|wb_v && mem2_available && !dram1_unc && dram1==`DRAMSLOT_REQBUS && dram1_load && `NUM_MEM > 1) begin
`ifdef SUPPORT_DBG        	
            if (dbg_lmatch1) begin
                 dramB_v <= `TRUE;
                 dramB_id <= dram1_id;
                 dramB_exc <= `FLT_DBG;
                 dramB_bus <= 64'h0;
                 dram1 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            begin
                 dram1 <= `DRAMSLOT_HASBUS;
                 bwhich <= 2'b01;
                 preload <= dram1_preload;
                 bstate <= B_DCacheLoadStart;
            end 
        end
        else if (~|wb_v && mem3_available && !dram2_unc && dram2==`DRAMSLOT_REQBUS && dram2_load && `NUM_MEM > 2) begin
`ifdef SUPPORT_DBG        	
            if (dbg_lmatch2) begin
                 dramC_v <= `TRUE;
                 dramC_id <= dram2_id;
                 dramC_exc <= `FLT_DBG;
                 dramC_bus <= 64'h0;
                 dram2 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            begin
                 dram2 <= `DRAMSLOT_HASBUS;
                 preload <= dram2_preload;
                 bwhich <= 2'b10;
                 bstate <= B_DCacheLoadStart;
            end 
        end
        else if (~|wb_v && mem1_available && dram0_unc && dram0==`DRAMSLOT_BUSY && dram0_load) begin
`ifdef SUPPORT_DBG        	
            if (dbg_lmatch0) begin
                 dramA_v <= `TRUE;
                 dramA_id <= dram0_id;
                 dramA_exc <= `FLT_DBG;
                 dramA_bus <= 64'h0;
                 dram0 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            if (!acki) begin
               bwhich <= 2'b00;
               cyc <= `HIGH;
               stb_o <= `HIGH;
               sel_o <= fnSelect(dram0_instr,dram0_addr);
               vadr <= {dram0_addr[AMSB:3],3'b0};
               sr_o <=  IsLWR(dram0_instr);
               ol_o  <= dram0_ol;
               bstate <= B_DLoadAck;
            end
        end
        else if (~|wb_v && mem2_available && dram1_unc && dram1==`DRAMSLOT_BUSY && dram1_load && `NUM_MEM > 1) begin
`ifdef SUPPORT_DBG        	
            if (dbg_lmatch1) begin
                 dramB_v <= `TRUE;
                 dramB_id <= dram1_id;
                 dramB_exc <= `FLT_DBG;
                 dramB_bus <= 64'h0;
                 dram1 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            if (!acki) begin
                 bwhich <= 2'b01;
                 cyc <= `HIGH;
                 stb_o <= `HIGH;
                 sel_o <= fnSelect(dram1_instr,dram1_addr);
                 vadr <= {dram1_addr[AMSB:3],3'b0};
                 sr_o <=  IsLWR(dram1_instr);
                 ol_o  <= dram1_ol;
                 bstate <= B_DLoadAck;
            end
        end
        else if (~|wb_v && mem3_available && dram2_unc && dram2==`DRAMSLOT_BUSY && dram2_load && `NUM_MEM > 2) begin
`ifdef SUPPORT_DBG        	
            if (dbg_lmatch2) begin
                 dramC_v <= `TRUE;
                 dramC_id <= dram2_id;
                 dramC_exc <= `FLT_DBG;
                 dramC_bus <= 64'h0;
                 dram2 <= 2'd0;
            end
            else
`endif            
            if (!acki) begin
                 bwhich <= 2'b10;
                 cyc <= `HIGH;
                 stb_o <= `HIGH;
                 sel_o <= fnSelect(dram2_instr,dram2_addr);
                 vadr <= {dram2_addr[AMSB:3],3'b0};
                 sr_o <=  IsLWR(dram2_instr);
                 ol_o  <= dram2_ol;
                 bstate <= B_DLoadAck;
            end
        end
        // Check for L2 cache miss
        else if (~|wb_v && !ihitL2 && !acki) begin
           cti_o <= 3'b001;
           bte_o <= 2'b00;//2'b01;	// 4 beat burst wrap
           cyc <= `HIGH;
           stb_o <= `HIGH;
           sel_o <= 8'hFF;
           icl_o <= `HIGH;
           iccnt <= 3'd0;
//            adr_o <= icwhich ? {pc0[31:5],5'b0} : {pc1[31:5],5'b0};
//            L2_adr <= icwhich ? {pc0[31:5],5'b0} : {pc1[31:5],5'b0};
           vadr <= {pcr[5:0],L1_adr[AMSB:5],5'h0};
           ol_o  <= ol[0];
           L2_adr <= {pcr[5:0],L1_adr[AMSB:5],5'h0};
           L2_xsel <= 1'b0;
           bstate <= B_ICacheAck;
        end
    end

// Terminal state for a store operation.
// Note that if only a single memory channel is selected, bwhich will be a
// constant 0. This should cause the extra code to be removed.
B_StoreAck:
	begin
		StoreAck1 <= `TRUE;
		isStore <= `TRUE;
	if (acki|err_i|tlb_miss|wrv_i) begin
		wb_nack();
		cr_o <= 1'b0;
    // This isn't a good way of doing things; the state should be propagated
    // to the commit stage, however since this is a store we know there will
    // be no change of program flow. So the reservation status bit is set
    // here. The author wanted to avoid the complexity of propagating the
    // input signal to the commit stage. It does mean that the SWC
    // instruction should be surrounded by SYNC's.
    if (cr_o)
			sema[0] <= rbi_i;
`ifdef HAS_WB
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (wbo_id[n]) begin
        iqentry_exc[n] <= tlb_miss ? `FLT_TLB : wrv_i ? `FLT_DWF : err_i ? `FLT_IBE : `FLT_NONE;
        if (err_i|wrv_i) begin
        	wb_v <= 1'b0;			// Invalidate write buffer if there is a problem with the store
        	wb_en <= `FALSE;	// and disable write buffer
        end
				iqentry_cmt[n] <= `VAL;
				iqentry_aq[n] <= `INV;
			end
		end
`else
    case(bwhich)
    2'd0:   begin
             	dram0 <= `DRAMREQ_READY;
             	iqentry_exc[dram0_id[`QBITS]] <= (wrv_i|err_i) ? `FLT_DWF : `FLT_NONE;
							iqentry_cmt[ dram0_id[`QBITS] ] <= `VAL;
							iqentry_aq[ dram0_id[`QBITS] ] <= `INV;
     		//iqentry_out[ dram0_id[`QBITS] ] <= `INV;
            end
    2'd1:   if (`NUM_MEM > 1) begin
             	dram1 <= `DRAMREQ_READY;
             	iqentry_exc[dram1_id[`QBITS]] <= (wrv_i|err_i) ? `FLT_DWF : `FLT_NONE;
							iqentry_cmt[ dram1_id[`QBITS] ] <= `VAL;
							iqentry_aq[ dram1_id[`QBITS] ] <= `INV;
     		//iqentry_out[ dram1_id[`QBITS] ] <= `INV;
            end
    2'd2:   if (`NUM_MEM > 2) begin
             	dram2 <= `DRAMREQ_READY;
             	iqentry_exc[dram2_id[`QBITS]] <= (wrv_i|err_i) ? `FLT_DWF : `FLT_NONE;
							iqentry_cmt[ dram2_id[`QBITS] ] <= `VAL;
							iqentry_aq[ dram2_id[`QBITS] ] <= `INV;
     		//iqentry_out[ dram2_id[`QBITS] ] <= `INV;
            end
    default:    ;
    endcase
`endif
		bstate <= B19;
  end
	end

B_DCacheLoadStart:
    begin
    dccnt <= 2'd0;
    bstate <= B_DCacheLoadAck;
		cti_o <= 3'b001;	// constant address burst
		bte_o <= 2'b00;		// linear burst, non-wrapping
		cyc <= `HIGH;
		stb_o <= `HIGH;
		// bwhich should always be one of the three channels.
    case(bwhich)
    2'd0:   begin
             sel_o <= fnSelect(dram0_instr,dram0_addr);
             vadr <= {dram0_addr[AMSB:5],5'b0};
             ol_o  <= dram0_ol;
            end
    2'd1:   if (`NUM_MEM > 1) begin
             sel_o <= fnSelect(dram1_instr,dram1_addr);
             vadr <= {dram1_addr[AMSB:5],5'b0};
             ol_o  <= dram1_ol;
            end
    2'd2:   if (`NUM_MEM > 2) begin
             sel_o <= fnSelect(dram2_instr,dram2_addr);
             vadr <= {dram2_addr[AMSB:5],5'b0};
             ol_o  <= dram2_ol;
            end
    default: 
      begin
      	$display("Invalid memory channel selection");
      	$stop;
				cti_o <= 3'b000;
				bte_o <= 2'b00;
				cyc <= `LOW;
				stb_o <= `LOW;
    		bstate <= BIDLE;
    	end
    endcase
    end

// Data cache load terminal state
B_DCacheLoadAck:
  if (ack_i|err_i|tlb_miss|rdv_i) begin
    errq <= errq | err_i;
    rdvq <= rdvq | rdv_i;
    if (!preload)	// A preload instruction ignores any error
    case(bwhich)
    2'd0:   if (err_i|rdv_i|tlb_miss) begin
               iqentry_exc[dram0_id[`QBITS]] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DBE : `FLT_DRF;
            end
    2'd1:   if ((err_i|rdv_i|tlb_miss) && `NUM_MEM > 1) begin
               iqentry_exc[dram1_id[`QBITS]] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DBE : `FLT_DRF;
            end
    2'd2:   if ((err_i|rdv_i|tlb_miss) && `NUM_MEM > 2) begin
               iqentry_exc[dram2_id[`QBITS]] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DBE : `FLT_DRF;
            end
    default:    ;
    endcase
    dccnt <= dccnt + 2'd1;
    vadr[4:3] <= vadr[4:3] + 2'd1;
    bstate <= B_DCacheLoadAck;
    if (dccnt==2'd2)
			cti_o <= 3'b111;
    if (dccnt==2'd3) begin
			cti_o <= 3'b000;
			bte_o <= 2'b00;
			cyc <= `LOW;
			stb_o <= `LOW;
			sel_o <= 8'h00;
			bstate <= B_DCacheLoadWait1;
    end
  end

B_DCacheLoadStb:
	begin
		stb_o <= `HIGH;
		bstate <= B_DCacheLoadAck;
  end
B_DCacheLoadWait1: bstate <= B_DCacheLoadWait2;
B_DCacheLoadWait2: bstate <= B_DCacheLoadResetBusy;
//B_DCacheLoadWait3: bstate <= B_DCacheLoadResetBusy;
B_DCacheLoadResetBusy: begin
    // There could be more than one memory cycle active. We reset the state
    // of all the machines to retest for a hit because otherwise sequential
    // loading of memory will cause successive machines to miss resulting in 
    // multiple dcache loads that aren't needed.
    if (dram0 != `DRAMSLOT_AVAIL && dram0_addr[31:5]==vadr[31:5]) dram0 <= `DRAMSLOT_BUSY;  // causes retest of dhit
    if (dram1 != `DRAMSLOT_AVAIL && dram1_addr[31:5]==vadr[31:5]) dram1 <= `DRAMSLOT_BUSY;
    if (dram2 != `DRAMSLOT_AVAIL && dram2_addr[31:5]==vadr[31:5]) dram2 <= `DRAMSLOT_BUSY;
    if (~ack_i)  bstate <= BIDLE;
    end

// Ack state for instruction cache load
B_ICacheAck:
  if (ack_i|err_i|tlb_miss|exv_i) begin
    errq <= errq | err_i;
    exvq <= exvq | exv_i;
//        L1_en <= 9'h3 << {L2_xsel,L2_adr[4:3],1'b0};
//        L1_wr0 <= `TRUE;
//        L1_wr1 <= `TRUE;
//        L1_adr <= L2_adr;
		if (tlb_miss) begin
			L2_rdat <= {18{`INSN_FLT_TLB}};
			wb_nack();
      icl_o <= `LOW;
      bstate <= B_ICacheNack;
    end
		else if (exv_i) begin
			L2_rdat <= {18{`INSN_FLT_EXF}};
			wb_nack();
      icl_o <= `LOW;
      bstate <= B_ICacheNack;
		end
    else if (err_i) begin
    	L2_rdat <= {18{`INSN_FLT_IBE}};
			wb_nack();
      icl_o <= `LOW;
      bstate <= B_ICacheNack;
    end
    else
    	case(iccnt)
    	3'd0:	L2_rdat[63:0] <= dat_i;
    	3'd1:	L2_rdat[127:64] <= dat_i;
    	3'd2:	L2_rdat[191:128] <= dat_i;
    	3'd3:	L2_rdat[255:192] <= dat_i;
    	3'd4:	L2_rdat[289:256] <= {2'b00,dat_i[31:0]};
    	default:	;
    	endcase
    	//L2_rdat <= {dat_i[31:0],{4{dat_i}}};
    iccnt <= iccnt + 3'd1;
    //stb_o <= `LOW;
    if (iccnt==3'd3)
      cti_o <= 3'b111;
    if (iccnt==3'd4) begin
			wb_nack();
      icl_o <= `LOW;
      bstate <= B_ICacheNack;
    end
    else begin
      L2_adr[4:3] <= L2_adr[4:3] + 2'd1;
      if (L2_adr[4:3]==2'b11)
      	L2_xsel <= 1'b1;
    end
  end
B_ICacheNack:
 	begin
		L1_wr0 <= `FALSE;
		L1_wr1 <= `FALSE;
		L1_wr2 <= `FALSE;
		L1_en <= 9'h1FF;
		L2_xsel <= 1'b0;
		if (~ack_i) begin
			icl_ctr <= icl_ctr + 40'd1;
			bstate <= BIDLE;
			L2_nxt <= TRUE;
		end
	end
B12:
    if (ack_i|err_i|tlb_miss|rdv_i) begin
        if (isCAS) begin
    	     iqentry_res	[ casid[`QBITS] ] <= (dat_i == cas);
             iqentry_exc [ casid[`QBITS] ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
             iqentry_done[ casid[`QBITS] ] <= `VAL;
    	     iqentry_instr[ casid[`QBITS]] <= `NOP_INSN;
    	     iqentry_out [ casid[`QBITS] ] <= `INV;
    	    if (err_i | rdv_i) iqentry_ma[casid[`QBITS]] <= vadr;
            if (dat_i == cas) begin
                 stb_o <= `LOW;
                 we <= `TRUE;
                 bstate <= B15;
            end
            else begin
                 cas <= dat_i;
                 cyc <= `LOW;
                 stb_o <= `LOW;
                case(bwhich)
                2'b00:   dram0 <= `DRAMREQ_READY;
                2'b01:   dram1 <= `DRAMREQ_READY;
                2'b10:   dram2 <= `DRAMREQ_READY;
                default:    ;
                endcase
                 bstate <= B19;
            end
        end
        else if (isRMW) begin
    	     rmw_instr <= iqentry_instr[casid[`QBITS]];
    	     rmw_argA <= dat_i;
        	 if (isSpt) begin
        	 	rmw_argB <= 64'd1 << iqentry_a1[casid[`QBITS]][63:58];
        	 	rmw_argC <= iqentry_instr[casid[`QBITS]][5:0]==`R2 ?
        	 				iqentry_a3[casid[`QBITS]][64] << iqentry_a1[casid[`QBITS]][63:58] :
        	 				iqentry_a2[casid[`QBITS]][64] << iqentry_a1[casid[`QBITS]][63:58];
        	 end
        	 else if (isInc) begin
        	 	rmw_argB <= iqentry_instr[casid[`QBITS]][5:0]==`R2 ? {{59{iqentry_instr[casid[`QBITS]][22]}},iqentry_instr[casid[`QBITS]][22:18]} :
        	 														 {{59{iqentry_instr[casid[`QBITS]][17]}},iqentry_instr[casid[`QBITS]][17:13]};
         	 end
        	 else begin // isAMO
	    	     iqentry_res [ casid[`QBITS] ] <= dat_i;
	    	     rmw_argB <= iqentry_instr[casid[`QBITS]][31] ? {{59{iqentry_instr[casid[`QBITS]][20:16]}},iqentry_instr[casid[`QBITS]][20:16]} : iqentry_a2[casid[`QBITS]];
	         end
             iqentry_exc [ casid[`QBITS] ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
             stb_o <= `LOW;
             bstate <= B20;
    		end
    end

// Regular load
B_DLoadAck:
  if (ack_i|err_i|tlb_miss|rdv_i) begin
  	wb_nack();
		sr_o <= `LOW;
		xdati <= dat_i;
    case(bwhich)
    2'b00:  begin
             dram0 <= `DRAMREQ_READY;
             iqentry_exc [ dram0_id[`QBITS] ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
            end
    2'b01:  if (`NUM_MEM > 1) begin
             dram1 <= `DRAMREQ_READY;
             iqentry_exc [ dram1_id[`QBITS] ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
            end
    2'b10:  if (`NUM_MEM > 2) begin
             dram2 <= `DRAMREQ_READY;
             iqentry_exc [ dram2_id[`QBITS] ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
            end
    default:    ;
    endcase
		bstate <= B19;
	end

// Three cycles to detemrine if there's a cache hit during a store.
B16:    begin
            case(bwhich)
            2'd0:      if (dhit0) begin  dram0 <= `DRAMREQ_READY; bstate <= B17; end
            2'd1:      if (dhit1) begin  dram1 <= `DRAMREQ_READY; bstate <= B17; end
            2'd2:      if (dhit2) begin  dram2 <= `DRAMREQ_READY; bstate <= B17; end
            default:    bstate <= BIDLE;
            endcase
            end
B17:     bstate <= B18;
B18:     bstate <= B19;
B19:    if (~acki)  begin
					sel_o <= 8'h00;
					bstate <= BIDLE;
					StoreAck1 <= `FALSE;
					isStore <= `FALSE;
				end
B20:
	if (~ack_i) begin
		stb_o <= `HIGH;
		we  <= `HIGH;
		dat_o <= fnDato(rmw_instr,rmw_res);
		bstate <= B_StoreAck;
	end
B21:
	if (~ack_i) begin
		stb_o <= `HIGH;
		bstate <= B12;
	end
default:     bstate <= BIDLE;
endcase

if (!branchmiss) begin
    case({fetchbuf0_v, fetchbuf1_v})
    2'b00:  ;
    2'b01:
        if (canq1) begin
           	tail0 <= (tail0+2'd1) % QENTRIES;
           	tail1 <= (tail1+2'd1) % QENTRIES;
        end
    2'b10:
        if (canq1) begin
           	tail0 <= (tail0+2'd1) % QENTRIES;
           	tail1 <= (tail1+2'd1) % QENTRIES;
        end
    2'b11:
        if (canq1) begin
            if (IsBranch(fetchbuf0_instr) && predict_taken0 && fetchbuf0_thrd==fetchbuf1_thrd) begin
	           	tail0 <= (tail0+2'd1) % QENTRIES;
  	         	tail1 <= (tail1+2'd1) % QENTRIES;
            end
            else begin
				if (vqe0 < vl || !IsVector(fetchbuf0_instr)) begin
	                if (canq2) begin
	                  tail0 <= (tail0 + 3'd2) % QENTRIES;
	                  tail1 <= (tail1 + 3'd2) % QENTRIES;
	                end
	                else begin    // queued1 will be true
				           	tail0 <= (tail0+2'd1) % QENTRIES;
        				   	tail1 <= (tail1+2'd1) % QENTRIES;
	                end
            	end
            end
        end
    endcase
end
else if (!thread_en) begin	// if branchmiss
	for (n = QENTRIES-1; n >= 0; n = n - 1)
		// (QENTRIES-1) is needed to ensure that n increments forwards so that the modulus is
		// a positive number.
		if (iqentry_stomp[n] & ~iqentry_stomp[(n+(QENTRIES-1))%QENTRIES]) begin
			tail0 <= n;
			tail1 <= (n + 1) % QENTRIES;	
		end
    // otherwise, it is the last instruction in the queue that has been mispredicted ... do nothing
end

//	#5 rf[0] = 0; rf_v[0] = 1; rf_source[0] = 0;
`ifdef SIM
	$display("\n\n\n\n\n\n\n\n");
	$display("TIME %0d", $time);
	$display("%h #", pc0);
`ifdef SUPPORT_SMT
    $display ("Regfile: %d", rgs[0]);
	for (n=0; n < 32; n=n+4) begin
	    $display("%d: %h %d %o   %d: %h %d %o   %d: %h %d %o   %d: %h %d %o#",
	       n[4:0]+0, urf1.urf10.mem[{rgs[0],1'b0,n[4:2],2'b00}], regIsValid[n+0], rf_source[n+0],
	       n[4:0]+1, urf1.urf10.mem[{rgs[0],1'b0,n[4:2],2'b01}], regIsValid[n+1], rf_source[n+1],
	       n[4:0]+2, urf1.urf10.mem[{rgs[0],1'b0,n[4:2],2'b10}], regIsValid[n+2], rf_source[n+2],
	       n[4:0]+3, urf1.urf10.mem[{rgs[0],1'b0,n[4:2],2'b11}], regIsValid[n+3], rf_source[n+3]
	       );
	end
    $display ("Regfile: %d", rgs[1]);
	for (n=128; n < 160; n=n+4) begin
	    $display("%d: %h %d %o   %d: %h %d %o   %d: %h %d %o   %d: %h %d %o#",
	       n[4:0]+0, urf1.urf10.mem[{rgs[1],1'b0,n[4:2],2'b00}], regIsValid[n+0], rf_source[n+0],
	       n[4:0]+1, urf1.urf10.mem[{rgs[1],1'b0,n[4:2],2'b01}], regIsValid[n+1], rf_source[n+1],
	       n[4:0]+2, urf1.urf10.mem[{rgs[1],1'b0,n[4:2],2'b10}], regIsValid[n+2], rf_source[n+2],
	       n[4:0]+3, urf1.urf10.mem[{rgs[1],1'b0,n[4:2],2'b11}], regIsValid[n+3], rf_source[n+3]
	       );
	end
`else
    $display ("Regfile: %d", rgs);
	for (n=0; n < 32; n=n+4) begin
	    $display("%d: %h %d %o   %d: %h %d %o   %d: %h %d %o   %d: %h %d %o#",
	       n[4:0]+0, gRegfileInst.gb1.urf1.urf10.mem[{rgs,1'b0,n[4:2],2'b00}], regIsValid[n+0], rf_source[n+0],
	       n[4:0]+1, gRegfileInst.gb1.urf1.urf10.mem[{rgs,1'b0,n[4:2],2'b01}], regIsValid[n+1], rf_source[n+1],
	       n[4:0]+2, gRegfileInst.gb1.urf1.urf10.mem[{rgs,1'b0,n[4:2],2'b10}], regIsValid[n+2], rf_source[n+2],
	       n[4:0]+3, gRegfileInst.gb1.urf1.urf10.mem[{rgs,1'b0,n[4:2],2'b11}], regIsValid[n+3], rf_source[n+3]
	       );
	end
`endif
`ifdef FCU_ENH
	$display("Call Stack:");
	for (n = 0; n < 16; n = n + 4)
		$display("%c%d: %h   %c%d: %h   %c%d: %h   %c%d: %h",
			gFetchbufInst.gb1.ufb1.ursb1.rasp==n+0 ?">" : " ", n[4:0]+0, gFetchbufInst.gb1.ufb1.ursb1.ras[n+0],
			gFetchbufInst.gb1.ufb1.ursb1.rasp==n+1 ?">" : " ", n[4:0]+1, gFetchbufInst.gb1.ufb1.ursb1.ras[n+1],
			gFetchbufInst.gb1.ufb1.ursb1.rasp==n+2 ?">" : " ", n[4:0]+2, gFetchbufInst.gb1.ufb1.ursb1.ras[n+2],
			gFetchbufInst.gb1.ufb1.ursb1.rasp==n+3 ?">" : " ", n[4:0]+3, gFetchbufInst.gb1.ufb1.ursb1.ras[n+3]
		);
	$display("\n");
`endif
//    $display("Return address stack:");
//    for (n = 0; n < 16; n = n + 1)
//        $display("%d %h", rasp+n[3:0], ras[rasp+n[3:0]]);
	$display("TakeBr:%d #", take_branch);//, backpc);
	$display("Insn%d: %h", 0, insn0);
	if (`WAYS==1) begin
	$display("%c%c A: %d %h %h #",
	    45, fetchbuf?45:62, fetchbufA_v, fetchbufA_instr, fetchbufA_pc);
	$display("%c%c B: %d %h %h #",
	    45, fetchbuf?62:45, fetchbufB_v, fetchbufB_instr, fetchbufB_pc);
	end
	else if (`WAYS > 1) begin
		$display("Insn%d: %h", 1, insn1);
	$display("%c%c A: %d %h %h #",
	    45, fetchbuf?45:62, fetchbufA_v, fetchbufA_instr, fetchbufA_pc);
	$display("%c%c B: %d %h %h #",
	    45, fetchbuf?45:62, fetchbufB_v, fetchbufB_instr, fetchbufB_pc);
	end
	else if (`WAYS > 2) begin	   
		$display("%c%c C: %d %h %h #",
		    45, fetchbuf?62:45, fetchbufC_v, fetchbufC_instr, fetchbufC_pc);
		$display("%c%c D: %d %h %h #",
		    45, fetchbuf?62:45, fetchbufD_v, fetchbufD_instr, fetchbufD_pc);
	end
	for (i=0; i<QENTRIES; i=i+1) 
	    $display("%c%c %d: %c%c%c%c %d %d %c%c %c %c%h %d %o %h %h %h %d %o %h %d %o %h %d %o %d:%h %h %d#",
		 (i[`QBITS]==heads[0])?"C":".",
		 (i[`QBITS]==tail0)?"Q":".",
		  i[`QBITS],
		 iqentry_v[i] ? "v" : "-",
		 iqentry_iv[i] ? "I" : "-",
		 iqentry_done[i]?"d":"-",
		 iqentry_out[i]?"o":"-",
		 iqentry_bt[i],
		 iqentry_memissue[i],
		 iqentry_agen[i] ? "a": "-",
		 iqentry_alu0_issue[i]?"0":iqentry_alu1_issue[i]?"1":"-",
		 iqentry_stomp[i]?"s":"-",
		iqentry_fc[i] ? "F" : iqentry_mem[i] ? "M" : (iqentry_alu[i]==1'b1) ? "a" : (iqentry_alu[i]==1'bx) ? "X" : iqentry_fpu[i] ? "f" : "O", 
		iqentry_instr[i], iqentry_tgt[i][4:0],
		iqentry_exc[i], iqentry_res[i], iqentry_a0[i], iqentry_a1[i], iqentry_a1_v[i],
		iqentry_a1_s[i],
		iqentry_a2[i], iqentry_a2_v[i], iqentry_a2_s[i],
		iqentry_a3[i], iqentry_a3_v[i], iqentry_a3_s[i],
		iqentry_thrd[i],
		iqentry_pc[i],
		iqentry_sn[i], iqentry_ven[i]
		);
    $display("DRAM");
	$display("%d %h %h %c%h %o #",
	    dram0, dram0_addr, dram0_data, (IsFlowCtrl(dram0_instr) ? 98 : (IsMem(dram0_instr)) ? 109 : 97), 
	    dram0_instr, dram0_id);
	  if (`NUM_MEM > 1)
	$display("%d %h %h %c%h %o #",
	    dram1, dram1_addr, dram1_data, (IsFlowCtrl(dram1_instr) ? 98 : (IsMem(dram1_instr)) ? 109 : 97), 
	    dram1_instr, dram1_id);
	  if (`NUM_MEM > 2)
	$display("%d %h %h %c%h %o #",
	    dram2, dram2_addr, dram2_data, (IsFlowCtrl(dram2_instr) ? 98 : (IsMem(dram2_instr)) ? 109 : 97), 
	    dram2_instr, dram2_id);
	$display("%d %h %o %h #", dramA_v, dramA_bus, dramA_id, dramA_exc);
	if (`NUM_MEM > 1)
	$display("%d %h %o %h #", dramB_v, dramB_bus, dramB_id, dramB_exc);
	if (`NUM_MEM > 2)
	$display("%d %h %o %h #", dramC_v, dramC_bus, dramC_id, dramC_exc);
    $display("ALU");
	$display("%d %h %h %h %c%h %o %h #",
		alu0_dataready, alu0_argI, alu0_argA, alu0_argB, 
		 (IsFlowCtrl(alu0_instr) ? 98 : IsMem(alu0_instr) ? 109 : 97),
		alu0_instr, alu0_sourceid, alu0_pc);
	$display("%d %h %o 0 #", alu0_v, alu0_bus, alu0_id);
	if (`NUM_ALU > 1) begin
		$display("%d %h %h %h %c%h %o %h #",
			alu1_dataready, alu1_argI, alu1_argA, alu1_argB, 
		 	(IsFlowCtrl(alu1_instr) ? 98 : IsMem(alu1_instr) ? 109 : 97),
			alu1_instr, alu1_sourceid, alu1_pc);
		$display("%d %h %o 0 #", alu1_v, alu1_bus, alu1_id);
	end
	$display("FCU");
	$display("%d %h %h %h %h %c%c #", fcu_v, fcu_bus, fcu_argI, fcu_argA, fcu_argB, fcu_takb?"T":"-", fcu_pt?"T":"-");
	$display("%c %h %h %h %h #", fcu_branchmiss?"m":" ", fcu_sourceid, fcu_misspc, fcu_nextpc, fcu_brdisp); 
    $display("Commit");
	$display("0: %c %h %o %d #", commit0_v?"v":" ", commit0_bus, commit0_id, commit0_tgt[4:0]);
	$display("1: %c %h %o %d #", commit1_v?"v":" ", commit1_bus, commit1_id, commit1_tgt[4:0]);
    $display("instructions committed: %d valid committed: %d ticks: %d ", CC, I, tick);
  $display("Write Buffer:");
  for (n = `WB_DEPTH-1; n >= 0; n = n - 1)
  	$display("%c adr: %h dat: %h", wb_v[n]?" ":"*", wb_addr[n], wb_data[n]);
    $display("Write merges: %d", wb_merges);
`endif	// SIM

//
//	$display("\n\n\n\n\n\n\n\n");
//	$display("TIME %0d", $time);
//	$display("  pc0=%h", pc0);
//	$display("  pc1=%h", pc1);
//	$display("  reg0=%h, v=%d, src=%o", rf[0], rf_v[0], rf_source[0]);
//	$display("  reg1=%h, v=%d, src=%o", rf[1], rf_v[1], rf_source[1]);
//	$display("  reg2=%h, v=%d, src=%o", rf[2], rf_v[2], rf_source[2]);
//	$display("  reg3=%h, v=%d, src=%o", rf[3], rf_v[3], rf_source[3]);
//	$display("  reg4=%h, v=%d, src=%o", rf[4], rf_v[4], rf_source[4]);
//	$display("  reg5=%h, v=%d, src=%o", rf[5], rf_v[5], rf_source[5]);
//	$display("  reg6=%h, v=%d, src=%o", rf[6], rf_v[6], rf_source[6]);
//	$display("  reg7=%h, v=%d, src=%o", rf[7], rf_v[7], rf_source[7]);

//	$display("Fetch Buffers:");
//	$display("  %c%c fbA: v=%d instr=%h pc=%h     %c%c fbC: v=%d instr=%h pc=%h", 
//	    fetchbuf?32:45, fetchbuf?32:62, fetchbufA_v, fetchbufA_instr, fetchbufA_pc,
//	    fetchbuf?45:32, fetchbuf?62:32, fetchbufC_v, fetchbufC_instr, fetchbufC_pc);
//	$display("  %c%c fbB: v=%d instr=%h pc=%h     %c%c fbD: v=%d instr=%h pc=%h", 
//	    fetchbuf?32:45, fetchbuf?32:62, fetchbufB_v, fetchbufB_instr, fetchbufB_pc,
//	    fetchbuf?45:32, fetchbuf?62:32, fetchbufD_v, fetchbufD_instr, fetchbufD_pc);
//	$display("  branchback=%d backpc=%h", branchback, backpc);

//	$display("Instruction Queue:");
//	for (i=0; i<8; i=i+1) 
//	    $display(" %c%c%d: v=%d done=%d out=%d agen=%d res=%h op=%d bt=%d tgt=%d a1=%h (v=%d/s=%o) a2=%h (v=%d/s=%o) im=%h pc=%h exc=%h",
//		(i[`QBITS]==heads[0])?72:32, (i[`QBITS]==tail0)?84:32, i,
//		iqentry_v[i], iqentry_done[i], iqentry_out[i], iqentry_agen[i], iqentry_res[i], iqentry_op[i], 
//		iqentry_bt[i], iqentry_tgt[i], iqentry_a1[i], iqentry_a1_v[i], iqentry_a1_s[i], iqentry_a2[i], iqentry_a2_v[i], 
//		iqentry_a2_s[i], iqentry_a0[i], iqentry_pc[i], iqentry_exc[i]);

//	$display("Scheduling Status:");
//	$display("  iqentry0 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b", 
//		iqentry_0_issue, iqentry_0_islot, iqentry_stomp[0], iqentry_source[0], iqentry_memready[0], iqentry_memissue[0]);
//	$display("  iqentry1 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b",
//		iqentry_1_issue, iqentry_1_islot, iqentry_stomp[1], iqentry_source[1], iqentry_memready[1], iqentry_memissue[1]);
//	$display("  iqentry2 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b",
//		iqentry_2_issue, iqentry_2_islot, iqentry_stomp[2], iqentry_source[2], iqentry_memready[2], iqentry_memissue[2]);
//	$display("  iqentry3 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b", 
//		iqentry_3_issue, iqentry_3_islot, iqentry_stomp[3], iqentry_source[3], iqentry_memready[3], iqentry_memissue[3]);
//	$display("  iqentry4 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b", 
//		iqentry_4_issue, iqentry_4_islot, iqentry_stomp[4], iqentry_source[4], iqentry_memready[4], iqentry_memissue[4]);
//	$display("  iqentry5 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b", 
//		iqentry_5_issue, iqentry_5_islot, iqentry_stomp[5], iqentry_source[5], iqentry_memready[5], iqentry_memissue[5]);
//	$display("  iqentry6 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b",
//		iqentry_6_issue, iqentry_6_islot, iqentry_stomp[6], iqentry_source[6], iqentry_memready[6], iqentry_memissue[6]);
//	$display("  iqentry7 issue=%d islot=%d stomp=%d source=%d - memready=%d memissue=%b",
//		iqentry_7_issue, iqentry_7_islot, iqentry_stomp[7], iqentry_source[7], iqentry_memready[7], iqentry_memissue[7]);

//	$display("ALU Inputs:");
//	$display("  0: avail=%d data=%d id=%o op=%d a1=%h a2=%h im=%h bt=%d",
//		alu0_available, alu0_dataready, alu0_sourceid, alu0_op, alu0_argA,
//		alu0_argB, alu0_argI, alu0_bt);
//	$display("  1: avail=%d data=%d id=%o op=%d a1=%h a2=%h im=%h bt=%d",
//		alu1_available, alu1_dataready, alu1_sourceid, alu1_op, alu1_argA,
//		alu1_argB, alu1_argI, alu1_bt);

//	$display("ALU Outputs:");
//	$display("  0: v=%d bus=%h id=%o bmiss=%d misspc=%h missid=%o",
//		alu0_v, alu0_bus, alu0_id, alu0_branchmiss, alu0_misspc, alu0_sourceid);
//	$display("  1: v=%d bus=%h id=%o bmiss=%d misspc=%h missid=%o",
//		alu1_v, alu1_bus, alu1_id, alu1_branchmiss, alu1_misspc, alu1_sourceid);

//	$display("DRAM Status:");
//	$display("  OUT: v=%d data=%h tgt=%d id=%o", dram_v, dram_bus, dram_tgt, dram_id);
//	$display("  dram0: status=%h addr=%h data=%h op=%d tgt=%d id=%o",
//	    dram0, dram0_addr, dram0_data, dram0_op, dram0_tgt, dram0_id);
//	$display("  dram1: status=%h addr=%h data=%h op=%d tgt=%d id=%o", 
//	    dram1, dram1_addr, dram1_data, dram1_op, dram1_tgt, dram1_id);
//	$display("  dram2: status=%h addr=%h data=%h op=%d tgt=%d id=%o",
//	    dram2, dram2_addr, dram2_data, dram2_op, dram2_tgt, dram2_id);

//	$display("Commit Buses:");
//	$display("  0: v=%d id=%o data=%h", commit0_v, commit0_id, commit0_bus);
//	$display("  1: v=%d id=%o data=%h", commit1_v, commit1_id, commit1_bus);

//
//	$display("Memory Contents:");
//	for (j=0; j<64; j=j+16)
//	    $display("  %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h", 
//		m[j+0], m[j+1], m[j+2], m[j+3], m[j+4], m[j+5], m[j+6], m[j+7],
//		m[j+8], m[j+9], m[j+10], m[j+11], m[j+12], m[j+13], m[j+14], m[j+15]);

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
/*	
    for (n = 0; n < QENTRIES; n = n + 1)
        if (branchmiss) begin
            if (!setpred[n]) begin
                 iqentry_instr[n][`INSTRUCTION_OP] <= `NOP;
                 iqentry_done[n] <= iqentry_v[n];
                 iqentry_cmt[n] <= iqentry_v[n];
            end
        end
*/
end // clock domain
/*
always @(posedge clk)
if (rst) begin
     tail0 <= 3'd0;
     tail1 <= 3'd1;
end
else begin
if (!branchmiss) begin
    case({fetchbuf0_v, fetchbuf1_v})
    2'b00:  ;
    2'b01:
        if (canq1) begin
             tail0 <= idp1(tail0);
             tail1 <= idp1(tail1);
        end
    2'b10:
        if (canq1) begin
             tail0 <= idp1(tail0);
             tail1 <= idp1(tail1);
        end
    2'b11:
        if (canq1) begin
            if (IsBranch(fetchbuf0_instr) && predict_taken0) begin
                 tail0 <= idp1(tail0);
                 tail1 <= idp1(tail1);
            end
            else begin
				if (vqe < vl || !IsVector(fetchbuf0_instr)) begin
	                if (canq2) begin
	                     tail0 <= idp2(tail0);
	                     tail1 <= idp2(tail1);
	                end
	                else begin    // queued1 will be true
	                     tail0 <= idp1(tail0);
	                     tail1 <= idp1(tail1);
	                end
            	end
            end
        end
    endcase
end
else begin	// if branchmiss
    if (iqentry_stomp[0] & ~iqentry_stomp[7]) begin
         tail0 <= 3'd0;
         tail1 <= 3'd1;
    end
    else if (iqentry_stomp[1] & ~iqentry_stomp[0]) begin
         tail0 <= 3'd1;
         tail1 <= 3'd2;
    end
    else if (iqentry_stomp[2] & ~iqentry_stomp[1]) begin
         tail0 <= 3'd2;
         tail1 <= 3'd3;
    end
    else if (iqentry_stomp[3] & ~iqentry_stomp[2]) begin
         tail0 <= 3'd3;
         tail1 <= 3'd4;
    end
    else if (iqentry_stomp[4] & ~iqentry_stomp[3]) begin
         tail0 <= 3'd4;
         tail1 <= 3'd5;
    end
    else if (iqentry_stomp[5] & ~iqentry_stomp[4]) begin
         tail0 <= 3'd5;
         tail1 <= 3'd6;
    end
    else if (iqentry_stomp[6] & ~iqentry_stomp[5]) begin
         tail0 <= 3'd6;
         tail1 <= 3'd7;
    end
    else if (iqentry_stomp[7] & ~iqentry_stomp[6]) begin
         tail0 <= 3'd7;
         tail1 <= 3'd0;
    end
    // otherwise, it is the last instruction in the queue that has been mispredicted ... do nothing
end
end
*/

// Update the write buffer.
task wb_update;
input [`QBITS] id;
input rmw;
input [7:0] sel;
input [1:0] ol;
input [`ABITS] addr;
input [63:0] data;
begin
	if (wbm && wbptr > 1 && wb_addr[wbptr-1][AMSB:3]==addr[AMSB:3]
	 && wb_ol[wbptr-1]==ol && wb_rmw[wbptr-1]==rmw && wb_v[wbptr-1]) begin
		// The write buffer is always shifted during the bus IDLE state. That means
		// the data is out of place by a slot. The slot the data is moved from is
		// invalidated.
		wb_v[wbptr-2] <= `INV;
		wb_v[wbptr-1] <= wb_en;
		wb_id[wbptr-1] <= wb_id[wbptr-1] | (16'd1 << id);
		wb_rmw[wbptr-1] <= rmw;
		wb_ol[wbptr-1] <= ol;
		wb_sel[wbptr-1] <= wb_sel[wbptr-1] | sel;
		wb_addr[wbptr-1] <= wb_addr[wbptr-1];
		wb_data[wbptr-1] <= wb_data[wbptr-1];
		if (sel[0]) wb_data[wbptr-1][ 7: 0] <= data[ 7: 0];
		if (sel[1]) wb_data[wbptr-1][15: 8] <= data[15: 8];
		if (sel[2]) wb_data[wbptr-1][23:16] <= data[23:16];
		if (sel[3]) wb_data[wbptr-1][31:24] <= data[31:24];
		if (sel[4]) wb_data[wbptr-1][39:32] <= data[39:32];
		if (sel[5]) wb_data[wbptr-1][47:40] <= data[47:40];
		if (sel[6]) wb_data[wbptr-1][55:48] <= data[55:48];
		if (sel[7]) wb_data[wbptr-1][63:56] <= data[63:56];
		wb_merges <= wb_merges + 32'd1;
	end
	else begin
		wb_v[wbptr] <= wb_en;
		wb_id[wbptr] <= (16'd1 << id);
		wb_rmw[wbptr] <= rmw;
		wb_ol[wbptr] <= ol;
		wb_sel[wbptr] <= sel;
		wb_addr[wbptr] <= {addr[AMSB:3],3'b0};
		wb_data[wbptr] <= data;
		wbptr <= wbptr + 2'd1;
	end
end
endtask

// Increment the head pointers
// Also increments the instruction counter
// Used when instructions are committed.
// Also clear any outstanding state bits that foul things up.
//
task head_inc;
input [`QBITS] amt;
begin
	for (n = 0; n < QENTRIES; n = n + 1)
     heads[n] <= (heads[n] + amt) % QENTRIES;
	CC <= CC + amt;
    if (amt==3'd3) begin
    	I = I + iqentry_v[heads[0]] + iqentry_v[heads[1]] + iqentry_v[heads[2]];
     	iqentry_agen[heads[0]] <= `INV;
    	iqentry_agen[heads[1]] <= `INV;
    	iqentry_agen[heads[2]] <= `INV;
    	iqentry_mem[heads[0]] <= `FALSE;
    	iqentry_mem[heads[1]] <= `FALSE;
    	iqentry_mem[heads[2]] <= `FALSE;
    	iqentry_iv[heads[0]] <= `INV;
    	iqentry_iv[heads[1]] <= `INV;
    	iqentry_iv[heads[2]] <= `INV;
    	iqentry_alu[heads[0]] <= `FALSE;
    	iqentry_alu[heads[1]] <= `FALSE;
    	iqentry_alu[heads[2]] <= `FALSE;
  		for (n = 0; n < QENTRIES; n = n + 1)
  			if (iqentry_v[n])
  				iqentry_sn[n] <= iqentry_sn[n] - (iqentry_v[heads[2]] ? iqentry_sn[heads[2]]
  																			 : iqentry_v[heads[1]] ? iqentry_sn[heads[1]]
  																			 : iqentry_v[heads[0]] ? iqentry_sn[heads[0]]
  																			 : 4'b0);
   	end 
    else if (amt==3'd2) begin
    	I = I + iqentry_v[heads[0]] + iqentry_v[heads[1]];
     iqentry_agen[heads[0]] <= `INV;
     iqentry_agen[heads[1]] <= `INV;
     iqentry_mem[heads[0]] <= `FALSE;
     iqentry_mem[heads[1]] <= `FALSE;
     iqentry_iv[heads[0]] <= `INV;
     iqentry_iv[heads[1]] <= `INV;
    	iqentry_alu[heads[0]] <= `FALSE;
     iqentry_alu[heads[1]] <= `FALSE;
  		for (n = 0; n < QENTRIES; n = n + 1)
  			if (iqentry_v[n])
  				iqentry_sn[n] <= iqentry_sn[n] - (iqentry_v[heads[1]] ? iqentry_sn[heads[1]]
  																			 : iqentry_v[heads[0]] ? iqentry_sn[heads[0]]
  																			 : 4'b0);
    end else if (amt==3'd1) begin
    	I = I + iqentry_v[heads[0]];
	    iqentry_agen[heads[0]] <= `INV;
	    iqentry_mem[heads[0]] <= `FALSE;
     	iqentry_iv[heads[0]] <= `INV;
    	iqentry_alu[heads[0]] <= `FALSE;
  		for (n = 0; n < QENTRIES; n = n + 1)
   			if (iqentry_v[n])
  				iqentry_sn[n] <= iqentry_sn[n] - (iqentry_v[heads[0]] ? iqentry_sn[heads[0]]
  																			 : 4'b0);
	end
end
endtask

task setargs;
input [`QBITS] nn;
input [`QBITSP1] id;
input v;
input [63:0] bus;
begin
  if (iqentry_a1_v[nn] == `INV && iqentry_a1_s[nn] == id && iqentry_v[nn] == `VAL && v == `VAL) begin
		iqentry_a1[nn] <= bus;
		iqentry_a1_v[nn] <= `VAL;
  end
  if (iqentry_a2_v[nn] == `INV && iqentry_a2_s[nn] == id && iqentry_v[nn] == `VAL && v == `VAL) begin
		iqentry_a2[nn] <= bus;
		iqentry_a2_v[nn] <= `VAL;
  end
  if (iqentry_a3_v[nn] == `INV && iqentry_a3_s[nn] == id && iqentry_v[nn] == `VAL && v == `VAL) begin
		iqentry_a3[nn] <= bus;
		iqentry_a3_v[nn] <= `VAL;
  end
end
endtask

task setinsn1;
input [`QBITS] nn;
input [143:0] bus;
begin
	iqentry_iv   [nn]  <= `VAL;
//  	iqentry_Rt   [nn]  <= bus[`IB_RT];
//  	iqentry_Rc   [nn]  <= bus[`IB_RC];
//  	iqentry_Ra   [nn]  <= bus[`IB_RA];
	iqentry_a0	 [nn]  <= bus[`IB_CONST];
	iqentry_imm  [nn]  <= bus[`IB_IMM];
//		iqentry_insln[nn]  <= bus[`IB_LN];
`ifndef INLINE_DECODE
	if (iqentry_insln[nn] != bus[`IB_LN]) begin
		$display("Insn length mismatch.");
		$stop;
	end
`endif
	iqentry_tlb  [nn]  <= bus[`IB_TLB];
	iqentry_sz   [nn]  <= bus[`IB_SZ];
	iqentry_jal	 [nn]  <= bus[`IB_JAL];
	iqentry_ret  [nn]  <= bus[`IB_RET];
	iqentry_irq  [nn]  <= bus[`IB_IRQ];
	iqentry_brk	 [nn]  <= bus[`IB_BRK];
	iqentry_rti  [nn]  <= bus[`IB_RTI];
	iqentry_bt   [nn]  <= bus[`IB_BT];
	iqentry_alu  [nn]  <= bus[`IB_ALU];
	iqentry_alu0 [nn]  <= bus[`IB_ALU0];
	iqentry_fpu  [nn]  <= bus[`IB_FPU];
	iqentry_fc   [nn]  <= bus[`IB_FC];
	iqentry_canex[nn]  <= bus[`IB_CANEX];
	iqentry_loadv[nn]  <= bus[`IB_LOADV];
	iqentry_load [nn]  <= bus[`IB_LOAD];
	iqentry_preload[nn]<= bus[`IB_PRELOAD];
	iqentry_store[nn]  <= bus[`IB_STORE];
	iqentry_push [nn]  <= bus[`IB_PUSH];
	iqentry_oddball[nn] <= bus[`IB_ODDBALL];
	iqentry_memsz[nn]  <= bus[`IB_MEMSZ];
	iqentry_mem  [nn]  <= bus[`IB_MEM];
	iqentry_memndx[nn] <= bus[`IB_MEMNDX];
	iqentry_rmw  [nn]  <= bus[`IB_RMW];
	iqentry_memdb[nn]  <= bus[`IB_MEMDB];
	iqentry_memsb[nn]  <= bus[`IB_MEMSB];
	iqentry_shft [nn]  <= bus[`IB_SHFT];
	iqentry_sei	 [nn]	 <= bus[`IB_SEI];
	iqentry_aq   [nn]  <= bus[`IB_AQ];
	iqentry_rl   [nn]  <= bus[`IB_RL];
	iqentry_jmp  [nn]  <= bus[`IB_JMP];
	iqentry_br   [nn]  <= bus[`IB_BR];
	iqentry_sync [nn]  <= bus[`IB_SYNC];
	iqentry_fsync[nn]  <= bus[`IB_FSYNC];
	iqentry_rfw  [nn]  <= bus[`IB_RFW];
	iqentry_we   [nn]  <= bus[`IB_WE];
end
endtask

task setinsn;
input [`QBITS] nn;
input [4:0] id;
input v;
input [143:0] bus;
begin
  if (iqentry_iv[nn] == `INV && iqentry_is[nn] == id && iqentry_v[nn] == `VAL && v == `VAL)
  	setinsn1(nn,bus);
end
endtask

task a1_vs;
begin
	// if there is not an overlapping write to the register file.
	if (Ra1s != Rt0s || !fetchbuf0_rfw) begin
		iqentry_a1_v [tail1] <= regIsValid[Ra1s];
		iqentry_a1_s [tail1] <= rf_source [Ra1s];
	end
	else begin
		iqentry_a1_v [tail1] <= `INV;
		iqentry_a1_s [tail1] <= { 1'b0, fetchbuf0_mem, tail0 };
	end
end
endtask

task a2_vs;
begin
	// if there is not an overlapping write to the register file.
	if (Rb1s != Rt0s || !fetchbuf0_rfw) begin
		iqentry_a2_v [tail1] <= regIsValid[Rb1s];
		iqentry_a2_s [tail1] <= rf_source [Rb1s];
	end
	else begin
		iqentry_a2_v [tail1] <= `INV;
		iqentry_a2_s [tail1] <= { 1'b0, fetchbuf0_mem, tail0 };
	end
end
endtask

task a3_vs;
begin
	// if there is not an overlapping write to the register file.
	if (Rc1s != Rt0s || !fetchbuf0_rfw) begin
		iqentry_a3_v [tail1] <= regIsValid[Rc1s];
		iqentry_a3_s [tail1] <= rf_source [Rc1s];
	end
	else begin
		iqentry_a3_v [tail1] <= `INV;
		iqentry_a3_s [tail1] <= { 1'b0, fetchbuf0_mem, tail0 };
	end
end
endtask

task enque0x;
begin
	if (IsVector(fetchbuf0_instr) && SUP_VECTOR) begin
		vqe0 <= vqe0 + 4'd1;
		if (IsVCmprss(fetchbuf0_instr)) begin
			if (vm[fetchbuf0_instr[25:23]][vqe0])
			vqet0 <= vqet0 + 4'd1;
		end
		else
			vqet0 <= vqet0 + 4'd1;
		if (vqe0 >= vl-2)
			nop_fetchbuf <= fetchbuf ? 4'b1000 : 4'b0010;
		enque0(tail0, fetchbuf0_thrd ? maxsn[1]+4'd1 : maxsn[0]+4'd1, vqe0);
		iq_ctr = iq_ctr + 4'd1;
		if (fetchbuf0_rfw) begin
			rf_source[ Rt0s ] <= { 1'b0, fetchbuf0_mem, tail0 };    // top bit indicates ALU/MEM bus
			rf_v[Rt0s] <= `INV;
		end
		if (canq2) begin
			if (vqe0 < vl-2) begin
				vqe0 <= vqe0 + 4'd2;
				if (IsVCmprss(fetchbuf0_instr)) begin
					if (vm[fetchbuf0_instr[25:23]][vqe0+6'd1])
						vqet0 <= vqet0 + 4'd2;
				end
				else
					vqet0 <= vqet0 + 4'd2;
				enque0(tail1, fetchbuf0_thrd ? maxsn[1] + 4'd2 : maxsn[0]+4'd2, vqe0 + 6'd1);
				iq_ctr = iq_ctr + 4'd2;
				if (fetchbuf0_rfw) begin
					rf_source[ Rt0s ] <= { 1'b0, fetchbuf0_mem, tail1 };    // top bit indicates ALU/MEM bus
					rf_v[Rt0s] <= `INV;
				end
			end
		end
	end
	else begin
		enque0(tail0, fetchbuf0_thrd ? maxsn[1]+4'd1 : maxsn[0]+4'd1, 6'd0);
		iq_ctr = iq_ctr + 4'd1;
		if (fetchbuf0_rfw) begin
			rf_source[ Rt0s ] <= { 1'b0, fetchbuf0_mem, tail0 };    // top bit indicates ALU/MEM bus
			rf_v[Rt0s] <= `INV;
		end
	end
end
endtask

// Enqueue fetchbuf0 onto the tail of the instruction queue
task enque0;
input [`QBITS] tail;
input [`SNBITS] seqnum;
input [5:0] venno;
begin
	iqentry_exc[tail] <= `FLT_NONE;
`ifdef SUPPORT_DBG
    if (dbg_imatchA)
        iqentry_exc[tail] <= `FLT_DBG;
    else if (dbg_ctrl[63])
        iqentry_exc[tail] <= `FLT_SSM;
`endif
	iqentry_sn   [tail]    <=  seqnum;
	iqentry_v    [tail]    <=   `VAL;
	iqentry_iv	 [tail]    <=   `INV;
	iqentry_is   [tail]    <= tail;
	iqentry_thrd [tail]    <=   fetchbuf0_thrd;
	iqentry_done [tail]    <=    `INV;
	iqentry_cmt  [tail]    <=	`INV;
	iqentry_out  [tail]    <=    `INV;
	iqentry_res  [tail]    <=    `ZERO;
	iqentry_instr[tail]    <=    IsVLS(fetchbuf0_instr) ? (vm[fnM2(fetchbuf0_instr)] ? fetchbuf0_instr : `NOP_INSN) : fetchbuf0_instr;
	iqentry_insln[tail]		 <=  fetchbuf0_insln;
	iqentry_fc   [tail]    <=  `INV;
	iqentry_mem	 [tail]		 <=  `INV;
	iqentry_alu	 [tail]		 <=  `INV;
	iqentry_fpu	 [tail]		 <=  `INV;
	iqentry_load [tail]		 <=  `INV;
	iqentry_pt   [tail]    <=  predict_taken0;
	iqentry_agen [tail]    <=    `INV;
	iqentry_state[tail]    <=   IQS_IDLE;
// If the previous instruction was a hardware interrupt and this instruction is a hardware interrupt
// inherit the previous pc.
//if (IsBrk(fetchbuf0_instr) && !fetchbuf0_instr[15] &&
//   (IsBrk(iqentry_instr[idm1(tail)]) && !iqentry_instr[idm1(tail1)][15] && iqentry_v[idm1(tail)]))
//   iqentry_pc   [tail]    <= iqentry_pc[idm1(tail)];
//else
	 iqentry_pc   [tail] <= fetchbuf0_pc;
	iqentry_rtop [tail]    <=   IsRtop(fetchbuf0_instr);
	iqentry_tgt  [tail]    <=	Rt0;
	iqentry_Ra   [tail]    <= Ra0;
	iqentry_Rb   [tail]    <= Rb0;
	iqentry_Rc   [tail]    <= Rc0;
	iqentry_vl   [tail]    <=  vl;
	iqentry_ven  [tail]    <=   venno;
	iqentry_exc  [tail]    <=    `EXC_NONE;
	iqentry_a1   [tail]    <=    rfoa0;
	iqentry_a1_v [tail]    <=    Source1Valid(fetchbuf0_instr) | regIsValid[Ra0s];
	iqentry_a1_s [tail]    <=    rf_source[Ra0s];
	iqentry_a2   [tail]    <=    rfob0;
	iqentry_a2_v [tail]    <=    Source2Valid(fetchbuf0_instr) | regIsValid[Rb0s];
	iqentry_a2_s [tail]    <=    rf_source[Rb0s];
	iqentry_a3   [tail]    <=    rfoc0;
	iqentry_a3_v [tail]    <=    Source3Valid(fetchbuf0_instr) | regIsValid[Rc0s];
	iqentry_a3_s [tail]    <=    rf_source[Rc0s];
`ifdef INLINE_DECODE
	setinsn1(tail,id1_bus);
`endif
end
endtask

// Enque fetchbuf1. Fetchbuf1 might be the second instruction to queue so some
// of this code checks to see which tail it is being queued on.
task enque1;
input [`QBITS] tail;
input [`SNBITS] seqnum;
input [5:0] venno;
begin
 iqentry_exc[tail] <= `FLT_NONE;
`ifdef SUPPORT_DBG
    if (dbg_imatchB)
        iqentry_exc[tail] <= `FLT_DBG;
    else if (dbg_ctrl[63])
        iqentry_exc[tail] <= `FLT_SSM;
`endif
	iqentry_sn   [tail]    <=   seqnum;
	iqentry_v    [tail]    <=   `VAL;
	iqentry_iv	 [tail]    <=   `INV;
	iqentry_is   [tail]    <= tail;
	iqentry_thrd [tail]    <=   fetchbuf1_thrd;
	iqentry_done [tail]    <=   `INV;
	iqentry_cmt  [tail]    <=	`INV;
	iqentry_out  [tail]    <=   `INV;
	iqentry_res  [tail]    <=   `ZERO;
	iqentry_instr[tail]    <=   IsVLS(fetchbuf1_instr) ? (vm[fnM2(fetchbuf1_instr)] ? fetchbuf1_instr : `NOP_INSN) : fetchbuf1_instr; 
	iqentry_insln[tail]		 <=  fetchbuf1_insln;
	iqentry_fc   [tail]    <=  `INV;
	iqentry_mem	 [tail]		 <=  `INV;
	iqentry_alu	 [tail]		 <=  `INV;
	iqentry_fpu	 [tail]		 <=  `INV;
	iqentry_load [tail]		 <=  `INV;
	iqentry_pt   [tail]    <=  predict_taken1;
	iqentry_agen [tail]    <=   `INV;
	iqentry_state[tail]    <=   IQS_IDLE;
// If queing 2nd instruction must read from first
if (tail==tail1) begin
    // If the previous instruction was a hardware interrupt and this instruction is a hardware interrupt
    // inherit the previous pc.
//    if (IsBrk(fetchbuf1_instr) && !fetchbuf1_instr[15] &&
//        IsBrk(fetchbuf0_instr) && !fetchbuf0_instr[15])
//       iqentry_pc   [tail]    <= fetchbuf0_pc;
//    else
		iqentry_pc   [tail] <= fetchbuf1_pc;
end
else begin
    // If the previous instruction was a hardware interrupt and this instruction is a hardware interrupt
    // inherit the previous pc.
//    if (IsBrk(fetchbuf1_instr) && !fetchbuf1_instr[15] &&
//       (IsBrk(iqentry_instr[idp7(tail)]) && !iqentry_instr[idm1(tail)][15] && iqentry_v[idm1(tail)]))
//       iqentry_pc   [tail]    <= iqentry_pc[idm1(tail)];
//    else
		iqentry_pc   [tail] <= fetchbuf1_pc;
end
	iqentry_rtop [tail]    <=   IsRtop(fetchbuf1_instr);
	iqentry_tgt  [tail]    <= Rt1;
	iqentry_Ra   [tail]    <= Ra1;
	iqentry_Rb   [tail]    <= Rb1;
	iqentry_Rc   [tail]    <= Rc1;
	iqentry_vl   [tail]    <=  vl;
	iqentry_ven  [tail]    <=   venno;
	iqentry_exc  [tail]    <=   `EXC_NONE;
	iqentry_a1   [tail]    <=	rfoa1;
	iqentry_a1_v [tail]    <=	Source1Valid(fetchbuf1_instr) | regIsValid[Ra1s];
	iqentry_a1_s [tail]    <=	rf_source[Ra1s];
	iqentry_a2   [tail]    <=	rfob1;
	iqentry_a2_v [tail]    <=	Source2Valid(fetchbuf1_instr) | regIsValid[Rb1s];
	iqentry_a2_s [tail]    <=	rf_source[Rb1s];
	iqentry_a3   [tail]    <=	rfoc1;
	iqentry_a3_v [tail]    <=	Source3Valid(fetchbuf1_instr) | regIsValid[Rc1s];
	iqentry_a3_s [tail]    <=	rf_source[Rc1s];
`ifdef INLINE_DECODE
	setinsn1(tail,id2_bus);
`endif
end
endtask

// This task takes care of commits for things other than the register file.
task oddball_commit;
input v;
input [`QBITS] head;
input pulse;
reg thread;
begin
    thread = iqentry_thrd[head];
    if (v & pulse) begin
        if (|iqentry_exc[head]) begin
            excmiss <= TRUE;
`ifdef SUPPORT_SMT            
           	excmisspc <= {tvec[3'd0][AMSB:8],1'b0,ol[thread],5'h00};
            excthrd <= iqentry_thrd[head];
            badaddr[{thread,2'd0}] <= iqentry_ma[head];
            epc0[thread] <= iqentry_pc[head]+ 32'd4;
            epc1[thread] <= epc0[thread];
            epc2[thread] <= epc1[thread];
            epc3[thread] <= epc2[thread];
            epc4[thread] <= epc3[thread];
            epc5[thread] <= epc4[thread];
            epc6[thread] <= epc5[thread];
            epc7[thread] <= epc6[thread];
            epc8[thread] <= epc7[thread];
            im_stack[thread] <= {im_stack[thread][27:0],im};
            ol_stack[thread] <= {ol_stack[thread][13:0],ol[thread]};
            pl_stack[thread] <= {pl_stack[thread][55:0],cpl[thread]};
            rs_stack[thread] <= {rs_stack[thread][55:0],rgs[thread]};
            cause[{thread,2'd0}] <= {8'd0,iqentry_exc[head]};
            mstatus[thread][5:4] <= 2'd0;
            mstatus[thread][13:6] <= 8'h00;
            mstatus[thread][19:14] <= 6'd0;
`else
           	excmisspc <= {tvec[3'd0][AMSB:8],1'b0,ol,5'h00};
            excthrd <= iqentry_thrd[head];
            badaddr[{thread,2'd0}] <= iqentry_ma[head];
            epc0 <= iqentry_pc[head]+ 32'd4;
            epc1 <= epc0;
            epc2 <= epc1;
            epc3 <= epc2;
            epc4 <= epc3;
            epc5 <= epc4;
            epc6 <= epc5;
            epc7 <= epc6;
            epc8 <= epc7;
            im_stack <= {im_stack[27:0],im};
            ol_stack <= {ol_stack[13:0],ol};
            pl_stack <= {pl_stack[55:0],cpl};
            rs_stack <= {rs_stack[55:0],rgs};
            cause[{thread,2'd0}] <= {8'd0,iqentry_exc[head]};
            mstatus[5:4] <= 2'd0;
            mstatus[13:6] <= 8'h00;
            mstatus[19:14] <= 6'd0;
`endif           	
						wb_en <= `TRUE;
            sema[0] <= 1'b0;
            ve_hold <= {vqet1,10'd0,vqe1,10'd0,vqet0,10'd0,vqe0};
`ifdef SUPPORT_DBG            
            dbg_ctrl[62:55] <= {dbg_ctrl[61:55],dbg_ctrl[63]}; 
            dbg_ctrl[63] <= FALSE;
`endif            
        end
        else
        case(iqentry_instr[head][`INSTRUCTION_OP])
        `BRK:   
        		// BRK is treated as a nop unless it's a software interrupt or a
        		// hardware interrupt at a higher priority than the current priority.
              if ((iqentry_instr[head][23:21] > 3'd0) || iqentry_instr[head][20:17] > im) begin
		            excmiss <= TRUE;
`ifdef SUPPORT_SMT		            
            		excmisspc <= {tvec[3'd0][AMSB:8],1'b0,ol[thread],5'h00};
            		excthrd <= iqentry_thrd[head];
                    epc0[thread] <= iqentry_pc[head] + {iqentry_instr[head][23:21],2'b00};
                    epc1[thread] <= epc0[thread];
                    epc2[thread] <= epc1[thread];
                    epc3[thread] <= epc2[thread];
                    epc4[thread] <= epc3[thread];
                    epc5[thread] <= epc4[thread];
                    epc6[thread] <= epc5[thread];
                    epc7[thread] <= epc6[thread];
                    epc8[thread] <= epc7[thread];
                    im_stack[thread] <= {im_stack[thread][27:0],im};
                    ol_stack[thread] <= {ol_stack[thread][13:0],ol[thread]};
                    pl_stack[thread] <= {pl_stack[thread][55:0],cpl[thread]};
                    rs_stack[thread] <= {rs_stack[thread][55:0],rgs[thread]};
                    cause[{thread,2'd0}] <= iqentry_res[head][7:0];
                    mstatus[thread][5:4] <= 2'd0;
	                mstatus[thread][13:6] <= 8'h00;
                    // For hardware interrupts only, set a new mask level
                    // Select register set according to interrupt level
                    if (iqentry_instr[head][23:21]==3'd0) begin
                        mstatus[thread][3:0] <= 4'd15;//iqentry_instr[head][18:16];
                        mstatus[thread][31:28] <= iqentry_instr[head][20:17];
                        mstatus[thread][19:14] <= {2'b0,iqentry_instr[head][20:17]};
                    end
                    else
                    	mstatus[thread][19:14] <= 6'd0;
`else
            		excmisspc <= {tvec[3'd0][AMSB:8],1'b0,ol,5'h00};
            		excthrd <= iqentry_thrd[head];
                    epc0 <= iqentry_pc[head] + {iqentry_instr[head][23:21],2'b00};
                    epc1 <= epc0;
                    epc2 <= epc1;
                    epc3 <= epc2;
                    epc4 <= epc3;
                    epc5 <= epc4;
                    epc6 <= epc5;
                    epc7 <= epc6;
                    epc8 <= epc7;
                    im_stack <= {im_stack[27:0],im};
                    ol_stack <= {ol_stack[13:0],ol};
                    pl_stack <= {pl_stack[55:0],cpl};
                    rs_stack <= {rs_stack[55:0],rgs};
                    cause[{thread,2'd0}] <= iqentry_res[head][7:0];
                    mstatus[5:4] <= 2'd0;
	                mstatus[13:6] <= 8'h00;
                    // For hardware interrupts only, set a new mask level
                    // Select register set according to interrupt level
                    if (iqentry_instr[head][23:21]==3'd0) begin
                        mstatus[3:0] <= 4'd15;//iqentry_instr[head][18:16];
                        mstatus[31:28] <= iqentry_instr[head][20:17];
                        mstatus[19:14] <= {2'b0,iqentry_instr[head][20:17]};
                    end
                    else
                    	mstatus[19:14] <= 6'd0;
`endif                    
                    sema[0] <= 1'b0;
                    ve_hold <= {vqet1,10'd0,vqe1,10'd0,vqet0,10'd0,vqe0};
`ifdef SUPPORT_DBG                    
                    dbg_ctrl[62:55] <= {dbg_ctrl[61:55],dbg_ctrl[63]}; 
                    dbg_ctrl[63] <= FALSE;
`endif                    
                end
        `IVECTOR:
            casez(iqentry_tgt[head])
            8'b00100???:  vm[iqentry_tgt[head][2:0]] <= iqentry_res[head];
            8'b00101111:  vl <= iqentry_res[head];
            default:    ;
            endcase
        `R2:
            case(iqentry_instr[head][`INSTRUCTION_S2])
            `R1:	case(iqentry_instr[head][20:16])
            		`CHAIN_OFF:	cr0[18] <= 1'b0;
            		`CHAIN_ON:	cr0[18] <= 1'b1;
            		//`SETWB:		wbrcd[pcr[5:0]] <= 1'b1;
            		default:	;
        			endcase
            `VMOV:  casez(iqentry_tgt[head])
                    12'b1111111_00???:  vm[iqentry_tgt[head][2:0]] <= iqentry_res[head];
                    12'b1111111_01111:  vl <= iqentry_res[head];
                    default:	;
                    endcase
`ifdef SUPPORT_SMT                    
            `SEI:   mstatus[thread][2:0] <= iqentry_res[head][2:0];   // S1
`else
            `SEI:   mstatus[2:0] <= iqentry_res[head][2:0];   // S1
`endif          
            `RTI:   begin
		            excmiss <= TRUE;
`ifdef SUPPORT_SMT		            
            		excmisspc <= epc0[thread];
            		excthrd <= thread;
            		mstatus[thread][3:0] <= im_stack[thread][3:0];
            		mstatus[thread][5:4] <= ol_stack[thread][1:0];
            		mstatus[thread][13:6] <= pl_stack[thread][7:0];
            		mstatus[thread][19:14] <= rs_stack[thread][5:0];
            		im_stack[thread] <= {4'd15,im_stack[thread][31:4]};
            		ol_stack[thread] <= {2'd0,ol_stack[thread][15:2]};
            		pl_stack[thread] <= {8'h00,pl_stack[thread][63:8]};
            		rs_stack[thread] <= {8'h00,rs_stack[thread][63:8]};
                    epc0[thread] <= epc1[thread];
                    epc1[thread] <= epc2[thread];
                    epc2[thread] <= epc3[thread];
                    epc3[thread] <= epc4[thread];
                    epc4[thread] <= epc5[thread];
                    epc5[thread] <= epc6[thread];
                    epc6[thread] <= epc7[thread];
                    epc7[thread] <= epc8[thread];
                    epc8[thread] <= {tvec[0][AMSB:8], 1'b0, ol[thread], 5'h0};
`else
            		excmisspc <= epc0;
            		excthrd <= thread;
            		mstatus[3:0] <= im_stack[3:0];
            		mstatus[5:4] <= ol_stack[1:0];
            		mstatus[13:6] <= pl_stack[7:0];
            		mstatus[19:14] <= rs_stack[5:0];
            		im_stack <= {4'd15,im_stack[31:4]};
            		ol_stack <= {2'd0,ol_stack[15:2]};
            		pl_stack <= {8'h00,pl_stack[63:8]};
            		rs_stack <= {8'h00,rs_stack[63:8]};
                    epc0 <= epc1;
                    epc1 <= epc2;
                    epc2 <= epc3;
                    epc3 <= epc4;
                    epc4 <= epc5;
                    epc5 <= epc6;
                    epc6 <= epc7;
                    epc7 <= epc8;
                    epc8 <= {tvec[0][AMSB:8], 1'b0, ol, 5'h0};
`endif                    
                    sema[0] <= 1'b0;
                    sema[iqentry_res[head][5:0]] <= 1'b0;
                    vqe0  <= ve_hold[ 5: 0];
                    vqet0 <= ve_hold[21:16];
                    vqe1  <= ve_hold[37:32];
                    vqet1 <= ve_hold[53:48];
`ifdef SUPPORT_DBG                    
                    dbg_ctrl[62:55] <= {FALSE,dbg_ctrl[62:56]}; 
                    dbg_ctrl[63] <= dbg_ctrl[55];
`endif                    
                    end
            default: ;
            endcase
        `MEMNDX:
            case(iqentry_instr[head][`INSTRUCTION_S2])
            `CACHEX:
                    case(iqentry_instr[head][22:18])
                    5'h03:  invic <= TRUE;
                    5'h10:  cr0[30] <= FALSE;
                    5'h11:  cr0[30] <= TRUE;
                    default:    ;
                    endcase
            default: ;
            endcase
        `CSRRW:
        		begin
        		write_csr(iqentry_instr[head][31:18],iqentry_a1[head],thread);
        		end
        `REX:
`ifdef SUPPORT_SMT        
            // Can only redirect to a lower level
            if (ol[thread] < iqentry_instr[head][13:11]) begin
                mstatus[thread][5:3] <= iqentry_instr[head][13:11];
                badaddr[{thread,iqentry_instr[head][13:11]}] <= badaddr[{thread,ol[thread]}];
                cause[{thread,iqentry_instr[head][13:11]}] <= cause[{thread,ol[thread]}];
                mstatus[thread][13:6] <= iqentry_instr[head][23:16] | iqentry_a1[head][7:0];
            end
`else
            if (ol < iqentry_instr[head][13:11]) begin
                mstatus[5:3] <= iqentry_instr[head][13:11];
                badaddr[{thread,iqentry_instr[head][13:11]}] <= badaddr[{thread,ol}];
                cause[{thread,iqentry_instr[head][13:11]}] <= cause[{thread,ol}];
                mstatus[13:6] <= iqentry_instr[head][23:16] | iqentry_a1[head][7:0];
            end
`endif            
        `CACHE:
            case(iqentry_instr[head][17:13])
            5'h03:  invic <= TRUE;
            5'h10:  cr0[30] <= FALSE;
            5'h11:  cr0[30] <= TRUE;
            default:    ;
            endcase
        `FLOAT:
            case(iqentry_instr[head][`INSTRUCTION_S2])
            `FRM: begin  
            			fp_rm <= iqentry_res[head][2:0];
            			end
            `FCX:
                begin
                    fp_sx <= fp_sx & ~iqentry_res[head][5];
                    fp_inex <= fp_inex & ~iqentry_res[head][4];
                    fp_dbzx <= fp_dbzx & ~(iqentry_res[head][3]|iqentry_res[head][0]);
                    fp_underx <= fp_underx & ~iqentry_res[head][2];
                    fp_overx <= fp_overx & ~iqentry_res[head][1];
                    fp_giopx <= fp_giopx & ~iqentry_res[head][0];
                    fp_infdivx <= fp_infdivx & ~iqentry_res[head][0];
                    fp_zerozerox <= fp_zerozerox & ~iqentry_res[head][0];
                    fp_subinfx   <= fp_subinfx   & ~iqentry_res[head][0];
                    fp_infzerox  <= fp_infzerox  & ~iqentry_res[head][0];
                    fp_NaNCmpx   <= fp_NaNCmpx   & ~iqentry_res[head][0];
                    fp_swtx <= 1'b0;
                end
            `FDX:
                begin
                    fp_inexe <= fp_inexe     & ~iqentry_res[head][4];
                    fp_dbzxe <= fp_dbzxe     & ~iqentry_res[head][3];
                    fp_underxe <= fp_underxe & ~iqentry_res[head][2];
                    fp_overxe <= fp_overxe   & ~iqentry_res[head][1];
                    fp_invopxe <= fp_invopxe & ~iqentry_res[head][0];
                end
            `FEX:
                begin
                    fp_inexe <= fp_inexe     | iqentry_res[head][4];
                    fp_dbzxe <= fp_dbzxe     | iqentry_res[head][3];
                    fp_underxe <= fp_underxe | iqentry_res[head][2];
                    fp_overxe <= fp_overxe   | iqentry_res[head][1];
                    fp_invopxe <= fp_invopxe | iqentry_res[head][0];
                end
            default:
                begin
                    // 31 to 29 is rounding mode
                    // 28 to 24 are exception enables
                    // 23 is nsfp
                    // 22 is a fractie
                    fp_fractie <= iqentry_ares[head][22];
                    fp_raz <= iqentry_ares[head][21];
                    // 20 is a 0
                    fp_neg <= iqentry_ares[head][19];
                    fp_pos <= iqentry_ares[head][18];
                    fp_zero <= iqentry_ares[head][17];
                    fp_inf <= iqentry_ares[head][16];
                    // 15 swtx
                    // 14 
                    fp_inex <= fp_inex | (fp_inexe & iqentry_ares[head][14]);
                    fp_dbzx <= fp_dbzx | (fp_dbzxe & iqentry_ares[head][13]);
                    fp_underx <= fp_underx | (fp_underxe & iqentry_ares[head][12]);
                    fp_overx <= fp_overx | (fp_overxe & iqentry_ares[head][11]);
                    //fp_giopx <= fp_giopx | (fp_giopxe & iqentry_res2[head][10]);
                    //fp_invopx <= fp_invopx | (fp_invopxe & iqentry_res2[head][24]);
                    //
                    fp_cvtx <= fp_cvtx |  (fp_giopxe & iqentry_ares[head][7]);
                    fp_sqrtx <= fp_sqrtx |  (fp_giopxe & iqentry_ares[head][6]);
                    fp_NaNCmpx <= fp_NaNCmpx |  (fp_giopxe & iqentry_ares[head][5]);
                    fp_infzerox <= fp_infzerox |  (fp_giopxe & iqentry_ares[head][4]);
                    fp_zerozerox <= fp_zerozerox |  (fp_giopxe & iqentry_ares[head][3]);
                    fp_infdivx <= fp_infdivx | (fp_giopxe & iqentry_ares[head][2]);
                    fp_subinfx <= fp_subinfx | (fp_giopxe & iqentry_ares[head][1]);
                    fp_snanx <= fp_snanx | (fp_giopxe & iqentry_ares[head][0]);

                end
            endcase
        default:    ;
        endcase
        // Once the flow control instruction commits, NOP it out to allow
        // pending stores to be issued.
        iqentry_instr[head][5:0] <= `NOP;
    end
end
endtask

// CSR access tasks
task read_csr;
input [11:0] csrno;
output [63:0] dat;
input thread;
begin
`ifdef SUPPORT_SMT
    if (csrno[11:10] >= ol[thread])
`else
    if (csrno[11:10] >= ol)
`endif
    casez(csrno[9:0])
    `CSR_CR0:       dat <= cr0;
    `CSR_HARTID:    dat <= hartid;
    `CSR_TICK:      dat <= tick;
    `CSR_PCR:       dat <= pcr;
    `CSR_PCR2:      dat <= pcr2;
    `CSR_PMR:				dat <= pmr;
    `CSR_WBRCD:		dat <= wbrcd;
    `CSR_SEMA:      dat <= sema;
    `CSR_SBL:       dat <= sbl;
    `CSR_SBU:       dat <= sbu;
    `CSR_TCB:		dat <= tcb;
    `CSR_FSTAT:     dat <= {fp_rgs,fp_status};
`ifdef SUPPORT_DBG    
    `CSR_DBAD0:     dat <= dbg_adr0;
    `CSR_DBAD1:     dat <= dbg_adr1;
    `CSR_DBAD2:     dat <= dbg_adr2;
    `CSR_DBAD3:     dat <= dbg_adr3;
    `CSR_DBCTRL:    dat <= dbg_ctrl;
    `CSR_DBSTAT:    dat <= dbg_stat;
`endif   
    `CSR_CAS:       dat <= cas;
    `CSR_TVEC:      dat <= tvec[csrno[2:0]];
    `CSR_BADADR:    dat <= badaddr[{thread,csrno[11:10]}];
    `CSR_CAUSE:     dat <= {48'd0,cause[{thread,csrno[11:10]}]};
`ifdef SUPPORT_SMT    
    `CSR_IM_STACK:	dat <= im_stack[thread];
    `CSR_OL_STACK:	dat <= ol_stack[thread];
    `CSR_PL_STACK:	dat <= pl_stack[thread];
    `CSR_RS_STACK:	dat <= rs_stack[thread];
    `CSR_STATUS:    dat <= mstatus[thread][63:0];
    `CSR_EPC0:      dat <= epc0[thread];
    `CSR_EPC1:      dat <= epc1[thread];
    `CSR_EPC2:      dat <= epc2[thread];
    `CSR_EPC3:      dat <= epc3[thread];
    `CSR_EPC4:      dat <= epc4[thread];
    `CSR_EPC5:      dat <= epc5[thread];
    `CSR_EPC6:      dat <= epc6[thread];
    `CSR_EPC7:      dat <= epc7[thread];
`else
    `CSR_IM_STACK:	dat <= im_stack;
    `CSR_OL_STACK:	dat <= ol_stack;
    `CSR_PL_STACK:	dat <= pl_stack;
    `CSR_RS_STACK:	dat <= rs_stack;
    `CSR_STATUS:    dat <= mstatus[63:0];
    `CSR_EPC0:      dat <= epc0;
    `CSR_EPC1:      dat <= epc1;
    `CSR_EPC2:      dat <= epc2;
    `CSR_EPC3:      dat <= epc3;
    `CSR_EPC4:      dat <= epc4;
    `CSR_EPC5:      dat <= epc5;
    `CSR_EPC6:      dat <= epc6;
    `CSR_EPC7:      dat <= epc7;
`endif    
    `CSR_CODEBUF:   dat <= codebuf[csrno[5:0]];
    `CSR_Q_CTR:		dat <= iq_ctr;
    `CSR_BM_CTR:	dat <= bm_ctr;
    `CSR_ICL_CTR:	dat <= icl_ctr;
    `CSR_IRQ_CTR:	dat <= irq_ctr;
    `CSR_TIME:		dat <= wc_times;
    `CSR_INFO:
                    case(csrno[3:0])
                    4'd0:   dat <= "Finitron";  // manufacturer
                    4'd1:   dat <= "        ";
                    4'd2:   dat <= "64 bit  ";  // CPU class
                    4'd3:   dat <= "        ";
                    4'd4:   dat <= "FT64    ";  // Name
                    4'd5:   dat <= "        ";
                    4'd6:   dat <= 64'd1;       // model #
                    4'd7:   dat <= 64'd1;       // serial number
                    4'd8:   dat <= {32'd16384,32'd16384};   // cache sizes instruction,data
                    4'd9:   dat <= 64'd0;
                    default:    dat <= 64'd0;
                    endcase
    default:    begin    
    			$display("Unsupported CSR:%h",csrno[10:0]);
    			dat <= 64'hEEEEEEEEEEEEEEEE;
    			end
    endcase
    else
        dat <= 64'h0;
end
endtask

task write_csr;
input [13:0] csrno;
input [63:0] dat;
input thread;
begin
`ifdef SUPPORT_SMT	
    if (csrno[11:10] >= ol[thread])
`else
    if (csrno[11:10] >= ol)
`endif    
    case(csrno[13:12])
    2'd1:   // CSRRW
        casez(csrno[9:0])
        `CSR_CR0:       cr0 <= dat;
        `CSR_PCR:       pcr <= dat[31:0];
        `CSR_PCR2:      pcr2 <= dat;
        `CSR_PMR:	case(`NUM_IDU)
        					0,1:	pmr[0] <= 1'b1;
        					2:
	        					begin	
	        							if (dat[1:0]==2'b00)	
	        								pmr[1:0] <= 2'b01;
	        							else
	        								pmr[1:0] <= dat[1:0];
	        							pmr[63:2] <= dat[63:2];
	        						end
	        				3:
	        					begin	
	        							if (dat[2:0]==3'b000)	
	        								pmr[2:0] <= 3'b001;
	        							else
	        								pmr[2:0] <= dat[2:0];
	        							pmr[63:3] <= dat[63:3];
	        						end
	        				default:	pmr[0] <= 1'b1;
	        				endcase
        `CSR_WBRCD:		wbrcd <= dat;
        `CSR_SEMA:      sema <= dat;
        `CSR_SBL:       sbl <= dat[31:0];
        `CSR_SBU:       sbu <= dat[31:0];
        `CSR_TCB:		tcb <= dat;
        `CSR_FSTAT:		fpu_csr[37:32] <= dat[37:32];
        `CSR_BADADR:    badaddr[{thread,csrno[11:10]}] <= dat;
        `CSR_CAUSE:     cause[{thread,csrno[11:10]}] <= dat[15:0];
`ifdef SUPPORT_DBG        
        `CSR_DBAD0:     dbg_adr0 <= dat[AMSB:0];
        `CSR_DBAD1:     dbg_adr1 <= dat[AMSB:0];
        `CSR_DBAD2:     dbg_adr2 <= dat[AMSB:0];
        `CSR_DBAD3:     dbg_adr3 <= dat[AMSB:0];
        `CSR_DBCTRL:    dbg_ctrl <= dat;
`endif        
        `CSR_CAS:       cas <= dat;
        `CSR_TVEC:      tvec[csrno[2:0]] <= dat[31:0];
`ifdef SUPPORT_SMT        
        `CSR_IM_STACK:	im_stack[thread] <= dat[31:0];
        `CSR_OL_STACK:	ol_stack[thread] <= dat[15:0];
        `CSR_PL_STACK:	pl_stack[thread] <= dat;
        `CSR_RS_STACK:	rs_stack[thread] <= dat;
        `CSR_STATUS:    mstatus[thread][63:0] <= dat;
        `CSR_EPC0:      epc0[thread] <= dat;
        `CSR_EPC1:      epc1[thread] <= dat;
        `CSR_EPC2:      epc2[thread] <= dat;
        `CSR_EPC3:      epc3[thread] <= dat;
        `CSR_EPC4:      epc4[thread] <= dat;
        `CSR_EPC5:      epc5[thread] <= dat;
        `CSR_EPC6:      epc6[thread] <= dat;
        `CSR_EPC7:      epc7[thread] <= dat;
`else
        `CSR_IM_STACK:	im_stack <= dat[31:0];
        `CSR_OL_STACK:	ol_stack <= dat[15:0];
        `CSR_PL_STACK:	pl_stack <= dat;
        `CSR_RS_STACK:	rs_stack <= dat;
        `CSR_STATUS:    mstatus[63:0] <= dat;
        `CSR_EPC0:      epc0 <= dat;
        `CSR_EPC1:      epc1 <= dat;
        `CSR_EPC2:      epc2 <= dat;
        `CSR_EPC3:      epc3 <= dat;
        `CSR_EPC4:      epc4 <= dat;
        `CSR_EPC5:      epc5 <= dat;
        `CSR_EPC6:      epc6 <= dat;
        `CSR_EPC7:      epc7 <= dat;
`endif        
		`CSR_TIME:		begin
						ld_time <= 6'h3f;
						wc_time_dat <= dat;
						end
        `CSR_CODEBUF:   codebuf[csrno[5:0]] <= dat;
        default:    ;
        endcase
    2'd2:   // CSRRS
        case(csrno[9:0])
        `CSR_CR0:       cr0 <= cr0 | dat;
        `CSR_PCR:       pcr[31:0] <= pcr[31:0] | dat[31:0];
        `CSR_PCR2:      pcr2 <= pcr2 | dat;
        `CSR_PMR:				pmr <= pmr | dat;
        `CSR_WBRCD:		wbrcd <= wbrcd | dat;
`ifdef SUPPORT_DBG        
        `CSR_DBCTRL:    dbg_ctrl <= dbg_ctrl | dat;
`endif        
        `CSR_SEMA:      sema <= sema | dat;
`ifdef SUPPORT_SMT        
        `CSR_STATUS:    mstatus[thread][63:0] <= mstatus[thread][63:0] | dat;
`else
        `CSR_STATUS:    mstatus[63:0] <= mstatus[63:0] | dat;
`endif        
        default:    ;
        endcase
    2'd3:   // CSRRC
        case(csrno[9:0])
        `CSR_CR0:       cr0 <= cr0 & ~dat;
        `CSR_PCR:       pcr <= pcr & ~dat;
        `CSR_PCR2:      pcr2 <= pcr2 & ~dat;
        `CSR_PMR:			begin	
        							if (dat[1:0]==2'b11)
        								pmr[1:0] <= 2'b01;
        							else
        								pmr[1:0] <= pmr[1:0] & ~dat[1:0];
        							pmr[63:2] <= pmr[63:2] & ~dat[63:2];
        							end
        `CSR_WBRCD:		wbrcd <= wbrcd & ~dat;
`ifdef SUPPORT_DBG        
        `CSR_DBCTRL:    dbg_ctrl <= dbg_ctrl & ~dat;
`endif        
        `CSR_SEMA:      sema <= sema & ~dat;
`ifdef SUPPORT_SMT        
        `CSR_STATUS:    mstatus[thread][63:0] <= mstatus[thread][63:0] & ~dat;
`else
        `CSR_STATUS:    mstatus[63:0] <= mstatus[63:0] & ~dat;
`endif        
        default:    ;
        endcase
    default:    ;
    endcase
end
endtask

task tDram0Issue;
input [`QBITSP1] n;
begin
	dramA_v <= `INV;
	dram0 		<= `DRAMSLOT_BUSY;
	dram0_id 	<= { 1'b1, n[`QBITS] };
	dram0_instr <= iqentry_instr[n];
	dram0_rmw  <= iqentry_rmw[n];
	dram0_preload <= iqentry_preload[n];
	dram0_tgt 	<= iqentry_tgt[n];
	dram0_data	<= iqentry_a2[n];
	dram0_addr	<= iqentry_ma[n];
	//             if (ol[iqentry_thrd[n]]==`OL_USER)
	//             	dram0_seg   <= (iqentry_Ra[n]==5'd30 || iqentry_Ra[n]==5'd31) ? {ss[iqentry_thrd[n]],13'd0} : {ds[iqentry_thrd[n]],13'd0};
	//             else
	dram0_unc   <= iqentry_ma[n][31:20]==12'hFFD || !dce || iqentry_loadv[n];
	dram0_memsize <= iqentry_memsz[n];
	dram0_load <= iqentry_load[n];
	dram0_store <= iqentry_store[n];
	dram0_ol   <= (iqentry_Ra[n][4:0]==5'd31 || iqentry_Ra[n][4:0]==5'd30) ? ol[iqentry_thrd[n]] : dl[iqentry_thrd[n]];
	// Once the memory op is issued reset the a1_v flag.
	// This will cause the a1 bus to look for new data from memory (a1_s is pointed to a memory bus)
	// This is used for the load and compare instructions.
	iqentry_a1_v[n] <= `INV;
	iqentry_out[n] <= `VAL;
end
endtask

task tDram1Issue;
input [`QBITSP1] n;
begin
	dramB_v <= `INV;
	dram1 		<= `DRAMSLOT_BUSY;
	dram1_id 	<= { 1'b1, n[`QBITS] };
	dram1_instr <= iqentry_instr[n];
	dram1_rmw  <= iqentry_rmw[n];
	dram1_preload <= iqentry_preload[n];
	dram1_tgt 	<= iqentry_tgt[n];
	dram1_data	<= iqentry_a2[n];
	dram1_addr	<= iqentry_ma[n];
	//	             if (ol[iqentry_thrd[n]]==`OL_USER)
	//	             	dram1_seg   <= (iqentry_Ra[n]==5'd30 || iqentry_Ra[n]==5'd31) ? {ss[iqentry_thrd[n]],13'd0} : {ds[iqentry_thrd[n]],13'd0};
	//	             else
	dram1_unc   <= iqentry_ma[n][31:20]==12'hFFD || !dce || iqentry_loadv[n];
	dram1_memsize <= iqentry_memsz[n];
	dram1_load <= iqentry_load[n];
	dram1_store <= iqentry_store[n];
	dram1_ol   <= (iqentry_Ra[n][4:0]==5'd31 || iqentry_Ra[n][4:0]==5'd30) ? ol[iqentry_thrd[n]] : dl[iqentry_thrd[n]];
	iqentry_a1_v[n] <= `INV;
	iqentry_out[n] <= `VAL;
end
endtask

task tDram2Issue;
input [`QBITSP1] n;
begin
	dramC_v <= `INV;
	dram2 		<= `DRAMSLOT_BUSY;
	dram2_id 	<= { 1'b1, n[`QBITS] };
	dram2_instr	<= iqentry_instr[n];
	dram2_rmw  <= iqentry_rmw[n];
	dram2_preload <= iqentry_preload[n];
	dram2_tgt 	<= iqentry_tgt[n];
	dram2_data	<= iqentry_a2[n];
	dram2_addr	<= iqentry_ma[n];
	//	             if (ol[iqentry_thrd[n]]==`OL_USER)
	//	             	dram2_seg   <= (iqentry_Ra[n]==5'd30 || iqentry_Ra[n]==5'd31) ? {ss[iqentry_thrd[n]],13'd0} : {ds[iqentry_thrd[n]],13'd0};
	//	             else
	dram2_unc   <= iqentry_ma[n][31:20]==12'hFFD || !dce || iqentry_loadv[n];
	dram2_memsize <= iqentry_memsz[n];
	dram2_load <= iqentry_load[n];
	dram2_store <= iqentry_store[n];
	dram2_ol   <= (iqentry_Ra[n][4:0]==5'd31 || iqentry_Ra[n][4:0]==5'd30) ? ol[iqentry_thrd[n]] : dl[iqentry_thrd[n]];
	iqentry_a1_v[n] <= `INV;
	iqentry_out[n] <= `VAL;
end
endtask

task wb_nack;
begin
	cti_o <= 3'b000;
	bte_o <= 2'b00;
	cyc <= `LOW;
	stb_o <= `LOW;
	we <= `LOW;
	sel_o <= 8'h00;
end
endtask

endmodule


module decoder5 (num, out);
input [4:0] num;
output [31:1] out;
reg [31:1] out;

always @(num)
case (num)
    5'd0 :	out <= 31'b0000000000000000000000000000000;
    5'd1 :	out <= 31'b0000000000000000000000000000001;
    5'd2 :	out <= 31'b0000000000000000000000000000010;
    5'd3 :	out <= 31'b0000000000000000000000000000100;
    5'd4 :	out <= 31'b0000000000000000000000000001000;
    5'd5 :	out <= 31'b0000000000000000000000000010000;
    5'd6 :	out <= 31'b0000000000000000000000000100000;
    5'd7 :	out <= 31'b0000000000000000000000001000000;
    5'd8 :	out <= 31'b0000000000000000000000010000000;
    5'd9 :	out <= 31'b0000000000000000000000100000000;
    5'd10:	out <= 31'b0000000000000000000001000000000;
    5'd11:	out <= 31'b0000000000000000000010000000000;
    5'd12:	out <= 31'b0000000000000000000100000000000;
    5'd13:	out <= 31'b0000000000000000001000000000000;
    5'd14:	out <= 31'b0000000000000000010000000000000;
    5'd15:	out <= 31'b0000000000000000100000000000000;
    5'd16:	out <= 31'b0000000000000001000000000000000;
    5'd17:	out <= 31'b0000000000000010000000000000000;
    5'd18:	out <= 31'b0000000000000100000000000000000;
    5'd19:	out <= 31'b0000000000001000000000000000000;
    5'd20:	out <= 31'b0000000000010000000000000000000;
    5'd21:	out <= 31'b0000000000100000000000000000000;
    5'd22:	out <= 31'b0000000001000000000000000000000;
    5'd23:	out <= 31'b0000000010000000000000000000000;
    5'd24:	out <= 31'b0000000100000000000000000000000;
    5'd25:	out <= 31'b0000001000000000000000000000000;
    5'd26:	out <= 31'b0000010000000000000000000000000;
    5'd27:	out <= 31'b0000100000000000000000000000000;
    5'd28:	out <= 31'b0001000000000000000000000000000;
    5'd29:	out <= 31'b0010000000000000000000000000000;
    5'd30:	out <= 31'b0100000000000000000000000000000;
    5'd31:	out <= 31'b1000000000000000000000000000000;
endcase

endmodule

module decoder6 (num, out);
input [5:0] num;
output [63:1] out;

wire [63:0] out1;

assign out1 = 64'd1 << num;
assign out = out1[63:1];

endmodule

module decoder7 (num, out);
input [6:0] num;
output [127:1] out;

wire [127:0] out1;

assign out1 = 128'd1 << num;
assign out = out1[127:1];

endmodule

module decoder8 (num, out);
input [7:0] num;
output [255:1] out;

wire [255:0] out1;

assign out1 = 256'd1 << num;
assign out = out1[255:1];

endmodule

