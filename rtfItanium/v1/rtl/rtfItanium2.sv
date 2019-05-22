// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
// ============================================================================
//
`include "rtfItanium-config.sv"
`include "rtfItanium-defines.sv"

module rtfItanium2(hartid_i, rst_i, clk_i, clk2x_i, clk4x_i, tm_clk_i, irq_i, cause_i, 
		bte_o, cti_o, bok_i, cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_o, dat_i,
    ol_o, pcr_o, pcr2_o, pkeys_o, icl_o, sr_o, cr_o, rbi_i, signal_i, exc_o);
parameter WID = 80;
input [79:0] hartid_i;
input rst_i;
input clk_i;
input clk2x_i;
input clk4x_i;
input tm_clk_i;
input [3:0] irq_i;
input [7:0] cause_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
input bok_i;
output cyc_o;
output reg stb_o;
input ack_i;
input err_i;
output we_o;
output reg [15:0] sel_o;
output [`ABITS] adr_o;
output reg [127:0] dat_o;
input [127:0] dat_i;
output reg [1:0] ol_o;
output [31:0] pcr_o;
output [63:0] pcr2_o;
output [79:0] pkeys_o;
output icl_o;
output reg cr_o;
output reg sr_o;
input rbi_i;
input [31:0] signal_i;
(* mark_debug="true" *)
output [7:0] exc_o;
parameter TM_CLKFREQ = 20000000;
parameter QENTRIES = 5;
parameter AREGS = 64;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter VAL = 1'b1;
parameter INV = 1'b0;
parameter RSTPC = 80'hFFFFFFFFFFFFFFFC0100;
parameter BRKPC = 80'hFFFFFFFFFFFFFFFC0000;
parameter DEBUG = 1'b0;
parameter DBW = 80;
parameter ABW = 80;
parameter AMSB = ABW-1;
parameter RBIT = 5;
parameter WB_DEPTH = 7;

// Memory access sizes
parameter byt = 3'd0;
parameter wyde = 3'd1;
parameter tetra = 3'd2;
parameter penta = 3'd3;
parameter octa = 3'd4;
parameter deci = 3'd5;
// IQ states
parameter IQS_INVALID = 3'd0;
parameter IQS_QUEUED = 3'd1;
parameter IQS_OUT = 3'd2;
parameter IQS_AGEN = 3'd3;
parameter IQS_MEM = 3'd4;
parameter IQS_DONE = 3'd5;
parameter IQS_CMT = 3'd6;

parameter BUnit = 3'd1;
parameter IUnit = 3'd2;
parameter FUnit = 3'd3;
parameter MUnit = 3'd4;

`include "rtfItanium-bus_states.sv"

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
reg [AMSB:0] vadr;
reg cyc;
reg cyc_pending;	// An i-cache load is about to happen
reg we;

(* ram_style="block" *)
reg [127:0] rommem [0:12287];
initial begin
`include "d:/cores6/rtfItanium/v1/software/boot/boot.ve0"
end

reg [7:0] i;
integer n;
integer j, k;
genvar g, h;

reg [AMSB:0] ip, rip;
reg [AMSB:0] misspc, excmisspc;
reg [1:0] slot;
wire [63:0] slot0ip = {ip[63:4],4'h0};
wire [63:0] slot1ip = {ip[63:4],4'h5};
wire [63:0] slot2ip = {ip[63:4],4'hA};
reg slot0v, slot1v, slot2v;
reg [3:0] fb_panic;

reg [127:0] ibundle;
wire [4:0] template = ibundle[124:120];
wire [39:0] insn0 = ibundle[39:0];
wire [39:0] insn1 = ibundle[79:40];
wire [39:0] insn2 = ibundle[119:80];

reg [4:0] state;
reg [7:0] cnt;
reg r1IsFp,r2IsFp,r3IsFp;

reg  [`QBITS] tail0;
reg  [`QBITS] tail1;
reg  [`QBITS] tail2;
reg  [`QBITS] heads[0:QENTRIES-1];

wire tlb_miss;

wire [RBIT:0] Ra0, Rb0, Rc0, Rd0;
wire [RBIT:0] Ra1, Rb1, Rc1, Rd1;
wire [RBIT:0] Ra2, Rb2, Rc2, Rd2;
wire [79:0] rfoa0, rfob0, rfoc0;
wire [79:0] rfoa1, rfob1, rfoc1;
wire [79:0] rfoa2, rfob2, rfoc2;
reg  [AREGS-1:0] rf_v;
reg  [`QBITSP1] rf_source[0:AREGS-1];
initial begin
for (n = 0; n < AREGS; n = n + 1)
	rf_source[n] = 1'b0;
end
wire [1:0] ol;
wire [1:0] dl;

reg [`ABITS] ip;

reg [`ABITS] excmissip;
reg excmiss;
reg exception_set;
reg rdvq;               // accumulated read violation
reg errq;               // accumulated err_i input status
reg exvq;

// CSR's
reg debug_on;
reg [79:0] cr0;
wire snr = cr0[17];		// sequence number reset
wire dce = cr0[30];     // data cache enable
wire bpe = cr0[32];     // branch predictor enable
wire wbm = cr0[34];
wire sple = cr0[35];		// speculative load enable
wire ctgtxe = cr0[33];
reg [79:0] pmr;
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

// Performance CSR's
reg [39:0] iq_ctr;
reg [39:0] irq_ctr;					// count of number of interrupts
reg [39:0] bm_ctr;					// branch miss counter
reg [39:0] br_ctr;					// branch counter
wire [39:0] icl_ctr;				// instruction cache load counter

reg [7:0] fcu_timeout;
reg [47:0] tick;
reg [79:0] wc_time;
reg [31:0] pcr;
reg [63:0] pcr2;
assign pcr_o = pcr;
assign pcr2_o = pcr2;
reg [63:0] aec;
reg [15:0] cause[0:15];

reg [39:0] im_stack = 40'hFFFFFFFFFF;
wire [3:0] im = im_stack[3:0];
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
reg [79:0] mstatus ;  		// machine status
reg [15:0] ol_stack;
reg [15:0] dl_stack;
assign ol = ol_stack[1:0];	// operating level
assign dl = dl_stack[1:0];
wire [7:0] cpl ;
assign cpl = mstatus[13:6];	// current privilege level
wire [5:0] rgs ;
reg [79:0] pl_stack ;
reg [79:0] rs_stack ;
reg [79:0] brs_stack ;
reg [79:0] fr_stack ;
wire mprv = mstatus[55];
wire [7:0] ASID = mstatus[47:40];
wire [5:0] fprgs = mstatus[25:20];
//assign ol_o = mprv ? ol_stack[2:0] : ol;
wire vca = mstatus[32];		// vector chaining active
reg [63:0] keys;

assign pkeys_o = keys;
reg [63:0] tcb;
reg [127:0] bad_instr[0:15];
reg [`ABITS] badaddr[0:15];
reg [`ABITS] tvec[0:7];
reg [63:0] sema;
reg [63:0] vm_sema;
reg [79:0] cas;         // compare and swap
reg isCAS, isAMO, isInc, isSpt, isRMW;
reg [`QBITS] casid;
reg [RBIT:0] regLR = 6'd61;
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

reg  [3:0] panic;		// indexes the message structure
reg [127:0] message [0:15];	// indexed by panic

wire int_commit;

reg [199:0] xdati;

reg canq1, canq2, canq3;
reg queued1;
reg queued2;
reg queued3;
reg queuedNop;

reg [47:0] codebuf[0:63];
reg [QENTRIES-1:0] setpred;

// instruction queue (ROB)
// State and stqte decodes
reg [2:0] iq_state [0:QENTRIES-1];
reg [QENTRIES-1:0] iq_v;			// entry valid?  -- this should be the first bit
reg [QENTRIES-1:0] iq_done;
reg [QENTRIES-1:0] iq_out;
reg [QENTRIES-1:0] iq_agen;
reg [`SNBITS] iq_sn [0:QENTRIES-1];  // instruction sequence number
reg [QENTRIES-1:0] iq_iv;		// instruction is valid
reg [`QBITSP1] iq_is [0:QENTRIES-1];	// source of instruction
reg [QENTRIES-1:0] iq_pt;		// predict taken
reg [QENTRIES-1:0] iq_bt;		// update branch target buffer
reg [QENTRIES-1:0] iq_takb;	// take branch record
reg [QENTRIES-1:0] iq_jal;
reg [2:0] iq_sz [0:QENTRIES-1];
reg [QENTRIES-1:0] iq_alu = 8'h00;  // alu type instruction
reg [QENTRIES-1:0] iq_fpu;  // floating point instruction
reg [QENTRIES-1:0] iq_fc;   // flow control instruction
reg [QENTRIES-1:0] iq_canex = 8'h00;	// true if it's an instruction that can exception
reg [QENTRIES-1:0] iq_oddball = 8'h00;	// writes to register file
reg [QENTRIES-1:0] iq_load;	// is a memory load instruction
reg [QENTRIES-1:0] iq_store;	// is a memory store instruction
reg [QENTRIES-1:0] iq_preload;	// is a memory preload instruction
reg [QENTRIES-1:0] iq_ldcmp;
reg [QENTRIES-1:0] iq_mem;	// touches memory: 1 if LW/SW
reg [QENTRIES-1:0] iq_memndx;  // indexed memory operation 
reg [2:0] iq_memsz [0:QENTRIES-1];	// size of memory op
reg [QENTRIES-1:0] iq_rmw;	// memory RMW op
reg [QENTRIES-1:0] iq_push;
reg [QENTRIES-1:0] iq_memdb;
reg [QENTRIES-1:0] iq_memsb;
reg [QENTRIES-1:0] iq_rtop;
reg [QENTRIES-1:0] iq_sei;
reg [QENTRIES-1:0] iq_aq;	// memory aquire
reg [QENTRIES-1:0] iq_rl;	// memory release
reg [QENTRIES-1:0] iq_shft;
reg [QENTRIES-1:0] iq_jmp;	// changes control flow: 1 if BEQ/JALR
reg [QENTRIES-1:0] iq_br;  // Bcc (for predictor)
reg [QENTRIES-1:0] iq_ret;
reg [QENTRIES-1:0] iq_irq;
reg [QENTRIES-1:0] iq_brk;
reg [QENTRIES-1:0] iq_rti;
reg [QENTRIES-1:0] iq_wait;
reg [QENTRIES-1:0] iq_rex;
reg [QENTRIES-1:0] iq_chk;
reg [QENTRIES-1:0] iq_sync;  // sync instruction
reg [QENTRIES-1:0] iq_fsync;
reg [QENTRIES-1:0] iq_tlb;
reg [QENTRIES-1:0] iq_cmp;
reg [QENTRIES-1:0] iq_rfw = 1'b0;	// writes to register file
reg [WID-1:0] iq_res	[0:QENTRIES-1];	// instruction result
reg [WID-1:0] iq_ares	[0:QENTRIES-1];	// alternate instruction result
reg [2:0] iq_unit[0:QENTRIES-1];
reg [39:0] iq_instr[0:QENTRIES-1];	// instruction opcode
reg  [7:0] iq_exc	[0:QENTRIES-1];	// only for branches ... indicates a HALT instruction
reg [RBIT:0] iq_Ra [0:QENTRIES-1];
reg [RBIT:0] iq_tgt[0:QENTRIES-1];	// Rt field or ZERO -- this is the instruction's target (if any)
reg [AMSB:0] iq_ma [0:QENTRIES-1];	// memory address
reg [WID-1:0] iq_argI	[0:QENTRIES-1];	// argument 0 (immediate)
reg [WID-1:0] iq_argA	[0:QENTRIES-1];	// argument 1
reg [QENTRIES-1:0] iq_argA_v;	// arg1 valid
reg [`QBITSP1] iq_argA_s	[0:QENTRIES-1];	// arg1 source (iq entry # with top bit representing ALU/DRAM bus)
reg [WID-1:0] iq_argB	[0:QENTRIES-1];	// argument 2
reg        iq_argB_v	[0:QENTRIES-1];	// arg2 valid
reg  [`QBITSP1] iq_argB_s	[0:QENTRIES-1];	// arg2 source (iq entry # with top bit representing ALU/DRAM bus)
reg [WID-1:0] iq_argC	[0:QENTRIES-1];	// argument 3
reg        iq_argC_v	[0:QENTRIES-1];	// arg3 valid
reg  [`QBITSP1] iq_argC_s	[0:QENTRIES-1];	// arg3 source (iq entry # with top bit representing ALU/DRAM bus)
reg [`ABITS] iq_ip	[0:QENTRIES-1];	// program counter for this instruction

// debugging
initial begin
for (n = 0; n < QENTRIES; n = n + 1)
	iq_argA_s[n] <= 1'd0;
	iq_argB_s[n] <= 1'd0;
	iq_argC_s[n] <= 1'd0;
end

reg [QENTRIES-1:0] iq_source = {QENTRIES{1'b0}};
reg [QENTRIES-1:0] iq_imm;
reg [QENTRIES-1:0] iq_memready;
reg [QENTRIES-1:0] iq_memopsvalid;

reg  [QENTRIES-1:0] memissue = {QENTRIES{1'b0}};
reg [1:0] missued;
reg [7:0] last_issue0, last_issue1, last_issue2;
reg  [QENTRIES-1:0] iq_memissue;
reg [QENTRIES-1:0] iq_stomp;
reg [3:0] stompedOnRets;
reg  [QENTRIES-1:0] iq_alu0_issue;
reg  [QENTRIES-1:0] iq_alu1_issue;
reg  [QENTRIES-1:0] iq_alu2_issue;
reg  [QENTRIES-1:0] iq_id1issue;
reg  [QENTRIES-1:0] iq_id2issue;
reg  [QENTRIES-1:0] iq_id3issue;
reg [1:0] iq_mem_islot [0:QENTRIES-1];
reg [QENTRIES-1:0] iq_fcu_issue;
reg [QENTRIES-1:0] iq_fpu1_issue;
reg [QENTRIES-1:0] iq_fpu2_issue;

reg [AREGS-1:1] livetarget;
reg [AREGS-1:1] iq_livetarget [0:QENTRIES-1];
reg [AREGS-1:1] iq_latestID [0:QENTRIES-1];
reg [AREGS-1:1] iq_cumulative [0:QENTRIES-1];
wire  [AREGS-1:1] iq_out2 [0:QENTRIES-1];

// To detect a head change at time of commit. Some values need to pulsed
// with a single pulse.
reg  [`QBITS] ohead[0:2];
reg ocommit0_v, ocommit1_v, ocommit2_v;
reg [11:0] cmt_timer;

wire take_branch0;
wire take_branch1;

reg         id1_v;
reg   [`QBITSP1] id1_id;
reg   [2:0] id1_unit;
reg  [39:0] id1_instr;
reg   [5:0] id1_ven;
reg   [7:0] id1_vl;
reg         id1_thrd;
reg         id1_pt;
reg   [4:0] id1_Rt;
wire [143:0] id1_bus;

reg         id2_v;
reg   [`QBITSP1] id2_id;
reg   [2:0] id2_unit;
reg  [39:0] id2_instr;
reg   [5:0] id2_ven;
reg   [7:0] id2_vl;
reg         id2_thrd;
reg         id2_pt;
reg   [4:0] id2_Rt;
wire [143:0] id2_bus;

reg         id3_v;
reg   [`QBITSP1] id3_id;
reg   [2:0] id3_unit;
reg  [39:0] id3_instr;
reg   [5:0] id3_ven;
reg   [7:0] id3_vl;
reg         id3_thrd;
reg         id3_pt;
reg   [4:0] id3_Rt;
wire [143:0] id3_bus;

reg [WID-1:0] alu0_xs = 64'd0;
reg [WID-1:0] alu1_xs = 64'd0;

reg 				alu0_cmt;
wire				alu0_abort;
reg        alu0_ld;
reg        alu0_dataready;
wire       alu0_done;
wire       alu0_idle;
reg  [`QBITSP1] alu0_sourceid;
reg [39:0] alu0_instr;
reg				 alu0_tlb;
reg        alu0_mem;
reg        alu0_load;
reg        alu0_store;
reg 			 alu0_push;
reg        alu0_shft;
reg [RBIT:0] alu0_Ra;
reg [WID-1:0] alu0_argA;
reg [WID-1:0] alu0_argB;
reg [WID-1:0] alu0_argC;
reg [WID-1:0] alu0_argI;	// only used by BEQ
reg [2:0]  alu0_sz;
reg [RBIT:0] alu0_tgt;
reg [`ABITS] alu0_ip;
reg [WID-1:0] alu0_bus;
wire [WID-1:0] alu0b_bus;
wire [WID-1:0] alu0_out;
wire  [`QBITSP1] alu0_id;
(* mark_debug="true" *)
wire  [`XBITS] alu0_exc;
wire        alu0_v;
wire        alu0_branchmiss;
wire [`ABITS] alu0_misspc;

reg 				alu1_cmt;
wire				alu1_abort;
reg        alu1_ld;
reg        alu1_dataready;
wire       alu1_done;
wire       alu1_idle;
reg  [`QBITSP1] alu1_sourceid;
reg [39:0] alu1_instr;
reg        alu1_mem;
reg        alu1_load;
reg        alu1_store;
reg 			 alu1_push;
reg        alu1_shft;
reg [RBIT:0] alu1_Ra;
reg [WID-1:0] alu1_argA;
reg [WID-1:0] alu1_argB;
reg [WID-1:0] alu1_argC;
reg [WID-1:0] alu1_argT;
reg [WID-1:0] alu1_argI;	// only used by BEQ
reg [2:0]  alu1_sz;
reg [RBIT:0] alu1_tgt;
reg [`ABITS] alu1_ip;
reg [WID-1:0] alu1_bus;
wire [WID-1:0] alu1b_bus;
wire [WID-1:0] alu1_out;
wire  [`QBITSP1] alu1_id;
wire  [`XBITS] alu1_exc;
wire        alu1_v;
wire        alu1_branchmiss;
wire [`ABITS] alu1_misspc;

wire [`XBITS] fpu_exc;
reg 				fpu1_cmt;
reg        fpu1_ld;
reg        fpu1_dataready = 1'b1;
wire       fpu1_done = 1'b1;
wire       fpu1_idle;
reg [`QBITSP1] fpu1_sourceid;
reg [39:0] fpu1_instr;
reg [WID-1:0] fpu1_argA;
reg [WID-1:0] fpu1_argB;
reg [WID-1:0] fpu1_argC;
reg [WID-1:0] fpu1_argT;
reg [WID-1:0] fpu1_argI;	// only used by BEQ
reg [RBIT:0] fpu1_tgt;
reg [`ABITS] fpu1_ip;
wire [WID-1:0] fpu1_out = 64'h0;
reg [WID-1:0] fpu1_bus = 64'h0;
wire  [`QBITSP1] fpu1_id;
wire  [`XBITS] fpu1_exc = 9'h000;
wire        fpu1_v;
wire [31:0] fpu1_status;

reg 				fpu2_cmt;
reg        fpu2_ld;
reg        fpu2_dataready = 1'b1;
wire       fpu2_done = 1'b1;
wire       fpu2_idle;
reg [`QBITSP1] fpu2_sourceid;
reg [39:0] fpu2_instr;
reg [WID-1:0] fpu2_argA;
reg [WID-1:0] fpu2_argB;
reg [WID-1:0] fpu2_argC;
reg [WID-1:0] fpu2_argT;
reg [WID-1:0] fpu2_argI;	// only used by BEQ
reg [RBIT:0] fpu2_tgt;
reg [`ABITS] fpu2_ip;
wire [WID-1:0] fpu2_out = 64'h0;
reg [WID-1:0] fpu2_bus = 64'h0;
wire  [`QBITSP1] fpu2_id;
wire  [`XBITS] fpu2_exc = 9'h000;
wire        fpu2_v;
wire [31:0] fpu2_status;

reg [7:0] fccnt;
reg [47:0] waitctr;
reg 				fcu_cmt;
reg        fcu_ld;
reg        fcu_dataready;
reg        fcu_done;
reg         fcu_idle = 1'b1;
reg [`QBITSP1] fcu_sourceid;
reg [39:0] fcu_instr;
reg [39:0] fcu_prevInstr;
reg  [2:0] fcu_insln;
reg        fcu_pt;			// predict taken
reg        fcu_branch;
reg        fcu_call;
reg        fcu_ret;
reg        fcu_jal;
reg        fcu_brk;
reg        fcu_rti;
reg				fcu_chk;
reg 			fcu_rex;
reg [WID-1:0] fcu_argA;
reg [WID-1:0] fcu_argB;
reg [WID-1:0] fcu_argC;
reg [WID-1:0] fcu_argI;	// only used by BEQ
reg [WID-1:0] fcu_argT;
reg [WID-1:0] fcu_argT2;
reg [WID-1:0] fcu_epc;
reg [`ABITS] fcu_ip;
reg [`ABITS] fcu_nextip;
reg [`ABITS] fcu_brdisp;
wire [WID-1:0] fcu_out;
reg [WID-1:0] fcu_bus;
wire  [`QBITSP1] fcu_id;
reg   [`XBITS] fcu_exc;
wire        fcu_v;
reg        fcu_branchmiss;
reg  fcu_clearbm;
reg [`ABITS] fcu_misspc;
reg fcu_wait;

reg [WID-1:0] rmw_argA;
reg [WID-1:0] rmw_argB;
reg [WID-1:0] rmw_argC;
wire [WID-1:0] rmw_res;
reg [39:0] rmw_instr;

// write buffer
wire [2:0] wb_ptr;
wire [WID-1:0] wb_data;
wire [`ABITS] wb_addr [0:WB_DEPTH-1];
wire [1:0] wb_ol;
wire [WB_DEPTH-1:0] wb_v;
wire wb_rmw;
wire [QENTRIES-1:0] wb_id;
wire [QENTRIES-1:0] wbo_id;
wire [9:0] wb_sel;
reg wb_en;
wire wb_hit0, wb_hit1;
wire wb_update_iq;

reg branchmiss = 1'b0;
reg [`ABITS] missip;
reg  [`QBITS] missid;

wire take_branch;
wire take_branchA;
wire take_branchB;
wire take_branchC;
wire take_branchD;

wire        dram_avail;
reg	 [2:0] dram0;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [2:0] dram1;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg [WID-1:0] dram0_data;
reg [`ABITS] dram0_addr;
reg [39:0] dram0_instr;
reg        dram0_rmw;
reg		   dram0_preload;
reg [RBIT:0] dram0_tgt;
reg  [`QBITSP1] dram0_id;
reg        dram0_unc;
reg [2:0]  dram0_memsize;
reg        dram0_load;	// is a load operation
reg        dram0_store;
reg  [1:0] dram0_ol;
reg [WID-1:0] dram1_data;
reg [`ABITS] dram1_addr;
reg [39:0] dram1_instr;
reg        dram1_rmw;
reg		   dram1_preload;
reg [RBIT:0] dram1_tgt;
reg  [`QBITSP1] dram1_id;
reg        dram1_unc;
reg [2:0]  dram1_memsize;
reg        dram1_load;
reg        dram1_store;
reg  [1:0] dram1_ol;

reg        dramA_v;
reg  [`QBITSP1] dramA_id;
reg [WID-1:0] dramA_bus;
reg        dramB_v;
reg  [`QBITSP1] dramB_id;
reg [WID-1:0] dramB_bus;

wire        outstanding_stores;
reg [47:0] I;		// instruction count
reg [47:0] CC;	// commit count

reg commit0_v;
reg [`QBITS] commit0_id;
reg [RBIT:0] commit0_tgt;
reg [79:0] commit0_bus;
reg commit1_v;
reg [`QBITS] commit1_id;
reg [RBIT:0] commit1_tgt;
reg [79:0] commit1_bus;
reg commit2_v;
reg [`QBITS] commit2_id;
reg [RBIT:0] commit2_tgt;
reg [79:0] commit2_bus;

reg [5:0] ld_time;
reg [63:0] wc_time_dat;
reg [63:0] wc_times;

wire slot0_rfw = IsRFW(Unit0(ibundle[127:120]),ibundle[39:0]);
wire slot1_rfw = IsRFW(Unit1(ibundle[127:120]),ibundle[79:40]);
wire slot2_rfw = IsRFW(Unit2(ibundle[127:120]),ibundle[119:80]);
wire slot0_mem = IsMem(Unit0(ibundle[127:120]));
wire slot1_mem = IsMem(Unit1(ibundle[127:120]));
wire slot2_mem = IsMem(Unit2(ibundle[127:120]));

wire [1:0] ic_fault;
wire [127:0] ic_out;
reg invic, invdc;
reg invicl;
reg [4:0] bstate;
wire [3:0] icstate;
reg [1:0] bwhich;
wire ihit;
reg phit;
always @*
	phit <= (ihit&&icstate==IDLE) && !invicl;

reg [AMSB:0] invlineAddr;
reg L1_invline;
wire [79:0] L1_adr, L2_adr;
wire [257:0] L1_dat, L2_dat;
wire L1_wr, L2_wr;
wire L1_selpc;
wire L2_ld;
wire L1_ihit, L2_ihit;
assign ihit = L1_ihit;
wire L1_nxt, L2_nxt;					// advances cache way lfsr
wire [2:0] L2_cnt;

wire d0L1_wr, d0L2_ld;
wire d1L1_wr, d1L2_ld;
wire [79:0] d0L1_adr, d0L2_adr;
wire [79:0] d1L1_adr, d1L2_adr;
wire d0L1_dhit, d0L2_dhit;
wire d0L1_nxt, d0L2_nxt;					// advances cache way lfsr
wire d1L1_dhit, d1L2_dhit;
wire d1L1_nxt, d1L2_nxt;					// advances cache way lfsr
wire [40:0] d0L1_sel, d0L2_sel;
wire [40:0] d1L1_sel, d1L2_sel;
wire [330:0] d0L1_dat, d0L2_dat;
wire [330:0] d1L1_dat, d1L2_dat;
wire d0L1_hit, d0L2_hit;
wire d1L1_hit, d1L2_hit;
wire d0L1_selpc, d0L2_selpc;
wire d1L1_selpc, d1L2_selpc;
reg [40:0] dcsel;
reg [255:0] dcbuf;

reg preload;
reg [1:0] dccnt;
reg [3:0] dcwait = 4'd3;
reg [3:0] dcwait_ctr = 4'd3;
wire dhit0, dhit1;
wire dhit0a, dhit1a;
wire dhit00, dhit10;
wire dhit01, dhit11;
reg [`ABITS] dc_wadr;
reg [WID-1:0] dc_wdat;
reg dcwr;
wire update_iq;
wire [QENTRIES-1:0] uid;

wire [2:0] icti;
wire [1:0] ibte;
wire [1:0] iol = 2'b00;
wire icyc;
wire istb;
wire iwe = 1'b0;
wire [15:0] isel;
wire [AMSB:0] iadr;

wire [1:0] wol;
wire wcyc;
wire wstb;
wire wwe;
wire [15:0] wsel;
wire [AMSB:0] wadr;
wire [127:0] wdat;
wire wcr;

reg [1:0] dol;
reg [2:0] dcti;
reg [1:0] dbte;
reg dcyc;
reg dstb;
reg dwe;
reg [15:0] dsel;
reg [AMSB:0] dadr;
reg [127:0] ddat;

function [8:0] fnUnits;
input [6:0] tmp;
case(tmp)
7'h00:	fnUnits = {`IUnit,`IUnit,`IUnit};
7'h01:	fnUnits = {`MLdUnit,`IUnit,`IUnit};
7'h02:	fnUnits = {`IUnit,`MLdUnit,`IUnit};
7'h03:	fnUnits = {`MLdUnit,`MLdUnit,`IUnit};
7'h04:	fnUnits = {`IUnit,`IUnit,`MLdUnit};
7'h05:	fnUnits = {`MLdUnit,`IUnit,`MLdUnit};
7'h06:	fnUnits = {`IUnit,`MLdUnit,`MLdUnit};
7'h07:	fnUnits = {`MLdUnit,`MLdUnit,`MLdUnit};
7'h08:	fnUnits = {`BUnit,`IUnit,`IUnit};
7'h09:	fnUnits = {`IUnit,`BUnit,`IUnit};
7'h0A:	fnUnits = {`BUnit,`BUnit,`IUnit};
7'h0B:	fnUnits = {`IUnit,`IUnit,`BUnit};
7'h0C:	fnUnits = {`BUnit,`IUnit,`BUnit};
7'h0D:	fnUnits = {`IUnit,`BUnit,`BUnit};
7'h0E:	fnUnits = {`BUnit,`BUnit,`BUnit};
7'h0F:	fnUnits = {`FUnit,`IUnit,`IUnit};
7'h10:	fnUnits = {`IUnit,`FUnit,`IUnit};
7'h11:	fnUnits = {`FUnit,`FUnit,`IUnit};
7'h12:	fnUnits = {`IUnit,`IUnit,`FUnit};
7'h13:	fnUnits = {`FUnit,`IUnit,`FUnit};
7'h14:	fnUnits = {`IUnit,`FUnit,`FUnit};
7'h15:	fnUnits = {`FUnit,`FUnit,`FUnit};
7'h16:	fnUnits = {`BUnit,`MLdUnit,`MLdUnit};
7'h17:	fnUnits = {`MLdUnit,`BUnit,`MLdUnit};
7'h18:	fnUnits = {`BUnit,`BUnit,`MLdUnit};
7'h19:	fnUnits = {`MLdUnit,`MLdUnit,`BUnit};
7'h1A:	fnUnits = {`BUnit,`MLdUnit,`BUnit};
7'h1B:	fnUnits = {`MLdUnit,`BUnit,`BUnit};
7'h1C:	fnUnits = {`BUnit,`FUnit,`FUnit};
7'h1D:	fnUnits = {`FUnit,`BUnit,`FUnit};
7'h1E:	fnUnits = {`BUnit,`BUnit,`FUnit};
7'h1F:	fnUnits = {`FUnit,`FUnit,`BUnit};

7'h20:	fnUnits = {`BUnit,`FUnit,`BUnit};
7'h21:	fnUnits = {`FUnit,`BUnit,`BUnit};
7'h22:	fnUnits = {`MLdUnit,`FUnit,`FUnit};
7'h23:	fnUnits = {`FUnit,`MLdUnit,`FUnit};
7'h24:	fnUnits = {`MLdUnit,`MLdUnit,`FUnit};
7'h25:	fnUnits = {`FUnit,`FUnit,`MLdUnit};
7'h26:	fnUnits = {`MLdUnit,`FUnit,`MLdUnit};
7'h27:	fnUnits = {`FUnit,`MLdUnit,`MLdUnit};
7'h28:	fnUnits = {`MStUnit,`MLdUnit,`MLdUnit};
7'h29:	fnUnits = {`MLdUnit,`MStUnit,`MLdUnit};
7'h2A:	fnUnits = {`MStUnit,`MStUnit,`MLdUnit};
7'h2B:	fnUnits = {`MLdUnit,`MLdUnit,`MStUnit};
7'h2C:	fnUnits = {`MStUnit,`MLdUnit,`MStUnit};
7'h2D:	fnUnits = {`MLdUnit,`MStUnit,`MStUnit};
7'h2E:	fnUnits = {`MLdUnit,`MStUnit,`IUnit};
7'h2F:	fnUnits = {`MStUnit,`MLdUnit,`IUnit};
7'h30:	fnUnits = {`IUnit,`MLdUnit,`MStUnit};
7'h31:	fnUnits = {`IUnit,`MStUnit,`MLdUnit};
7'h32:	fnUnits = {`MLdUnit,`IUnit,`MStUnit};
7'h33:	fnUnits = {`MStUnit,`IUnit,`MLdUnit};
7'h34:	fnUnits = {`BUnit,`MLdUnit,`MStUnit};
7'h35:	fnUnits = {`BUnit,`MStUnit,`MLdUnit};
7'h36:	fnUnits = {`MLdUnit,`BUnit,`MStUnit};
7'h37:	fnUnits = {`MStUnit,`BUnit,`MLdUnit};
7'h38:	fnUnits = {`MLdUnit,`MStUnit,`BUnit};
7'h39:	fnUnits = {`MStUnit,`MLdUnit,`BUnit};
7'h3A:	fnUnits = {`FUnit,`MLdUnit,`MStUnit};
7'h3B:	fnUnits = {`FUnit,`MStUnit,`MLdUnit};
7'h3C:	fnUnits = {`MLdUnit,`FUnit,`MStUnit};
7'h3D:	fnUnits = {`MStUnit,`FUnit,`MLdUnit};
7'h3E:	fnUnits = {`MLdUnit,`MStUnit,`FUnit};
7'h3F:	fnUnits = {`MStUnit,`MLdUnit,`FUnit};

7'h41:	fnUnits = {`MStUnit,`IUnit,`IUnit};
7'h42:	fnUnits = {`IUnit,`MStUnit,`IUnit};
7'h43:	fnUnits = {`MStUnit,`MStUnit,`IUnit};
7'h44:	fnUnits = {`IUnit,`IUnit,`MStUnit};
7'h45:	fnUnits = {`MStUnit,`IUnit,`MStUnit};
7'h46:	fnUnits = {`IUnit,`MStUnit,`MStUnit};
7'h47:	fnUnits = {`MStUnit,`MStUnit,`MStUnit};
7'h48:	fnUnits = {`MStUnit,`FUnit,`FUnit};
7'h49:	fnUnits = {`FUnit,`MStUnit,`FUnit};
7'h4A:	fnUnits = {`MStUnit,`MStUnit,`FUnit};
7'h4B:	fnUnits = {`FUnit,`FUnit,`MStUnit};
7'h4C:	fnUnits = {`MStUnit,`FUnit,`MStUnit};
7'h4D:	fnUnits = {`FUnit,`MStUnit,`MStUnit};

7'h56:	fnUnits = {`BUnit,`MStUnit,`MStUnit};
7'h57:	fnUnits = {`MStUnit,`BUnit,`MStUnit};
7'h58:	fnUnits = {`BUnit,`BUnit,`MStUnit};
7'h59:	fnUnits = {`MStUnit,`MStUnit,`BUnit};
7'h5A:	fnUnits = {`BUnit,`MStUnit,`BUnit};
7'h5B:	fnUnits = {`MStUnit,`BUnit,`BUnit};
default:	fnUnits = {`NUnit,`NUnit,`NUnit};
endcase
endfunction

function [2:0] Unit0;
input [6:0] tmp;
reg [8:0] units;
units = fnUnits(tmp);
Unit0 = units[2:0];
endfunction

function [2:0] Unit1;
input [6:0] tmp;
reg [8:0] units;
units = fnUnits(tmp);
Unit1 = units[5:3];
endfunction

function [2:0] Unit2;
input [6:0] tmp;
reg [8:0] units;
units = fnUnits(tmp);
Unit2 = units[8:6];
endfunction


function IsMUnit;
input [4:0] tmp;
input [1:0] slt;
case(tmp)
5'h0A,5'h0B:
	IsMUnit = slt==2'd0 || slt==2'd1;
5'h0C,5'h0D:
	IsMUnit = slt==2'd0;
5'h0E,5'h0F:
	IsMUnit = slt==2'd0 || slt==2'd1;
5'h10,5'h11,5'h12,5'h13:
	IsMUnit = slt==2'd0;
5'h18,5'h19:
	IsMUnit = slt==2'd0 || slt==2'd1;
5'h1C,5'h1D:
	IsMUnit = slt==2'd0;
default:
	IsMUnit = FALSE;
endcase
endfunction

function IsNop;
input [2:0] unit;
input [39:0] ins;
IsNop = unit==`BUnit && ins[`OPCODE4]==`NOP;
endfunction

function IsFUnit;
input [4:0] tmp;
input [1:0] slt;
case(tmp)
5'h0C,5'h0D:
	IsFUnit = slt==2'd1;
5'h0E,5'h0F:
	IsFUnit = slt==2'd2;
5'h1C,5'h1D:
	IsFUnit = slt==2'd1;
default:	IsFUnit = FALSE;
endcase
endfunction

function IsIUnit;
input [4:0] tmp;
input [1:0] slt;
case(tmp)
5'h0A,5'h0B,5'h0C,5'h0D:
	IsIUnit = slt==2'd2;
5'h10,5'h11:
	IsIUnit = slt==2'd1;
default:	IsIUnit = FALSE;
endcase
endfunction

function IsBUnit;
input [4:0] tmp;
input [1:0] slt;
case(tmp)
5'h10,5'h11:
	IsBUnit = slt==2'd2;
5'h12,5'h13:
	IsBUnit = slt==2'd1 || slt==2'd2;
5'h16,5'h17:
	IsBUnit = TRUE;
5'h18,5'h19:
	IsBUnit = slt==2'd2;
5'h1C,5'h1D:
	IsBUnit = slt==2'd2;
default:	IsBUnit = FALSE;
endcase
endfunction



Regfile urf1
(
	.clk(clk_i),
	.clk2x(clk2x_i),
	.wr0(commit0_v),
	.wa0(commit0_tgt),
	.i0(commit0_bus),
	.wr1(commit1_v),
	.wa1(commit1_tgt),
	.i1(commit1_bus),
	.ra0(Ra0),
	.ra1(Rb0),
	.ra2(Rc0),
	.ra3(Ra1),
	.ra4(Rb1),
	.ra5(Rc1),
	.ra6(Ra2),
	.ra7(Rb2),
	.ra8(Rc2),
	.o0(rfoa0),
	.o1(rfob0),
	.o2(rfoc0),
	.o3(rfoa1),
	.o4(rfob1),
	.o5(rfoc1),
	.o6(rfoa2),
	.o7(rfob2),
	.o8(rfoc2)
);


ICController uicc1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.pc(ip),
	.hit(L1_ihit),
	.bstate(bstate),
	.state(icstate),
	.invline(1'b0),
	.invlineAddr(80'h0),
	.icl_ctr(),
	.ihitL2(L2_ihit),
	.L2_ld(L2_ld),
	.L2_cnt(L2_cnt),
	.L2_adr(L2_adr),
	.L2_dat(L2_dat),
	.L2_nxt(L2_nxt),
	.L1_selpc(L1_selpc),
	.L1_adr(L1_adr),
	.L1_dat(L1_dat),
	.L1_wr(L1_wr),
	.L1_invline(),
	.icnxt(L1_nxt),
	.icwhich(),
	.icl_o(icl_o),
	.cti_o(icti),
	.bte_o(ibte),
	.bok_i(bok_i),
	.cyc_o(icyc),
	.stb_o(istb),
	.ack_i(ack_i),
	.err_i(err_i),
	.tlbmiss_i(tlb_miss),
	.exv_i(exv_i),
	.sel_o(isel),
	.adr_o(iadr),
	.dat_i(dat_i)
);

L1_icache uic1
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(L1_nxt),
	.wr(L1_wr),
	.wadr(L1_adr),
	.adr(L1_selpc ? ip : L1_adr),
	.i(L1_dat),
	.o(ic_out),
	.fault(),
	.hit(L1_ihit),
	.invall(1'b0),
	.invline(1'b0)
);

L2_icache uic2
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(L2_nxt),
	.wr(L2_wr),
	.adr(L2_ld ? L2_adr : L1_adr),
	.cnt(L2_cnt),
	.exv_i(1'b0),
	.i(dat_i),
	.err_i(1'b0),
	.o(L2_dat),
	.hit(L2_ihit),
	.invall(1'b0),
	.invline(1'b0)
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
wire btbwr0 = iq_v[heads[0]] && iq_state[heads[0]]==IQS_CMT && iq_fc[heads[0]];
wire btbwr1 = iq_v[heads[1]] && iq_state[heads[1]]==IQS_CMT && iq_fc[heads[1]];
wire btbwr2 = iq_v[heads[2]] && iq_state[heads[2]]==IQS_CMT && iq_fc[heads[2]];

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

BTB #(.AMSB(AMSB)) ubtb1
(
  .rst(rst_i),
  .wclk(fcu_clk),
  .wr0(btbwr0),  
  .wadr0(iq_ip[heads[0]]),
  .wdat0(iq_ma[heads[0]]),
  .valid0((iq_br[heads[0]] ? iq_takb[heads[0]] : iq_bt[heads[0]]) & iq_v[heads[0]]),
  .wr1(btbwr1),  
  .wadr1(iq_ip[heads[1]]),
  .wdat1(iq_ma[heads[1]]),
  .valid1((iq_br[heads[1]] ? iq_takb[heads[1]] : iq_bt[heads[1]]) & iq_v[heads[1]]),
  .wr2(btbwr2),  
  .wadr2(iq_ip[heads[2]]),
  .wdat2(iq_ma[heads[2]]),
  .valid2((iq_br[heads[2]] ? iq_takb[heads[2]] : iq_bt[heads[2]]) & iq_v[heads[2]]),
  .rclk(~clk),
  .pcA(ip),
  .btgtA(btgtA),
  .pcB({ip[79:4],4'h5}),
  .btgtB(btgtB),
  .pcC({ip[79:4],4'hA}),
  .btgtC(btgtC),
  .npcA(BRKPC),
  .npcB(BRKPC),
  .npcC(BRKPC)
);

BranchPredictor ubp1
(
  .rst(rst_i),
  .clk(fcu_clk),
  .en(bpe),
  .xisBranch0(iq_br[heads[0]] & commit0_v),
  .xisBranch1(iq_br[heads[1]] & commit1_v),
  .xisBranch2(iq_br[heads[2]] & commit2_v),
  .pcA(ip),
  .pcB({ip[79:4],4'h5}),
  .pcC({ip[79:4],4'hA}),
  .xpc0(iq_ip[heads[0]]),
  .xpc1(iq_ip[heads[1]]),
  .xpc2(iq_ip[heads[2]]),
  .takb0(commit0_v & iq_takb[heads[0]]),
  .takb1(commit1_v & iq_takb[heads[1]]),
  .takb2(commit2_v & iq_takb[heads[2]]),
  .predict_takenA(predict_takenA),
  .predict_takenB(predict_takenB),
  .predict_takenC(predict_takenC)
);

reg StoreAck1, isStore;
wire [199:0] dc0_out, dc1_out;
wire whit0, whit1, whit2;

wire wr_dcache0 = (dcwr)||(((bstate==B_StoreAck && StoreAck1) || (bstate==B_LSNAck && isStore)) && whit0);
wire wr_dcache1 = (dcwr)||(((bstate==B_StoreAck && StoreAck1) || (bstate==B_LSNAck && isStore)) && whit1);

DCController udcc1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.dadr(),
	.rd(),
	.wr(),
	.wsel(),
	.wdat(),
	.bstate(bstate),
	.state(),
	.invline(1'b0),
	.invlineAddr(80'h0),
	.icl_ctr(),
	.dL2_hit(d0L2_hit),
	.dL2_ld(d0L2_ld),
	.dL2_sel(d0L2_sel),
	.dL2_adr(d0L2_adr),
	.dL2_dat(d0L2_dat),
	.dL2_nxt(d0L2_nxt),
	.dL1_hit(d0L1_hit),
	.dL1_selpc(d0L1_selpc),
	.dL1_sel(d0L1_sel),
	.dL1_adr(d0L1_adr),
	.dL1_dat(d0L1_dat),
	.dL1_wr(d0L1_wr),
	.dL1_invline(1'b0),
	.dcnxt(),
	.dcwhich(),
	.dcl_o(),
	.cti_o(dcti),
	.bte_o(dbte),
	.bok_i(bok_i),
	.cyc_o(dcyc),
	.stb_o(dstb),
	.ack_i(ack_i),
	.err_i(err_i),
	.wrv_i(wrv_i),
	.rdv_i(rdv_i),
	.sel_o(dsel),
	.adr_o(dadr),
	.dat_i(dat_i)
);

L1_dcache udc1
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d0L1_nxt),
	.wr(d0L1_wr),
	.wadr(d0L1_adr),
	.adr(d0L1_selpc ? vadr : d0L1_adr),
	.i(d0L1_dat),
	.o(dc0_out),
	.fault(),
	.hit(d0L1_dhit),
	.invall(1'b0),
	.invline(1'b0)
);

L2_dcache udc2
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d0L2_nxt),
	.wr(d0L2_ld),
	.adr(d0L2_ld ? d0L2_adr : d0L1_adr),
	.sel(d0L2_sel),
	.rdv_i(1'b0),
	.wrv_i(1'b0),
	.i(d0L1_dat),
	.err_i(1'b0),
	.o(d0L2_dat),
	.hit(d0L2_dhit),
	.invall(1'b0),
	.invline(1'b0)
);


DCController udcc2
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.dadr(),
	.rd(),
	.wr(),
	.wsel(),
	.wdat(),
	.bstate(),
	.state(),
	.invline(1'b0),
	.invlineAddr(80'h0),
	.icl_ctr(),
	.dL2_hit(d1L2_hit),
	.dL2_ld(d1L2_ld),
	.dL2_sel(d1L2_sel),
	.dL2_adr(d1L2_adr),
	.dL2_dat(d1L2_dat),
	.dL2_nxt(d1L2_nxt),
	.dL1_hit(d1L1_hit),
	.dL1_selpc(d1L1_selpc),
	.dL1_sel(d1L1_sel),
	.dL1_adr(d1L1_adr),
	.dL1_dat(d1L1_dat),
	.dL1_wr(d1L1_wr),
	.dL1_invline(1'b0),
	.dcnxt(),
	.dcwhich(),
	.dcl_o(),
	.cti_o(),
	.bte_o(),
	.bok_i(),
	.cyc_o(),
	.stb_o(),
	.ack_i(),
	.err_i(),
	.wrv_i(),
	.rdv_i(),
	.sel_o(),
	.adr_o(),
	.dat_i(dat_i)
);

L1_dcache udc3
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d1L1_nxt),
	.wr(d1L1_wr),
	.wadr(d1L1_adr),
	.adr(d1L1_selpc ? vadr : d1L1_adr),
	.i(d1L1_dat),
	.o(dc1_out),
	.fault(),
	.hit(d1L1_dhit),
	.invall(1'b0),
	.invline(1'b0)
);

L2_dcache udc4
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d1L2_nxt),
	.wr(d1L2_ld),
	.adr(d1L2_ld ? d1L2_adr : d1L1_adr),
	.sel(d1L2_sel),
	.rdv_i(1'b0),
	.wrv_i(1'b0),
	.i(d1L1_dat),
	.err_i(1'b0),
	.o(d1L2_dat),
	.hit(d1L2_dhit),
	.invall(1'b0),
	.invline(1'b0)
);

wire [199:0] rdat0, rdat1;
assign rdat0 = dram0_unc ? xdati[199:0] : dc0_out;
assign rdat1 = dram1_unc ? xdati[199:0] : dc1_out;

wire [7:0] wb_fault;
wire wb_q0_done, wb_q1_done;
wire wb_has_bus;
assign dhit0 = dhit0a && !wb_hit0;
assign dhit1 = dhit1a && !wb_hit1;

write_buffer uwb1
(
	.rst_i(rst_i),
	.clk_i(clk),
	.bstate(bstate),
	.cyc_pending(cyc_pending),
	.wb_has_bus(wb_has_bus),
	.update_iq(update_iq),
	.uid(uid),
	.fault(wb_fault),
	.p0_id_i(dram0_id),
	.p0_ol_i(dram0_ol),
	.p0_wr_i(dram0==`DRAMSLOT_BUSY && dram0_store),
	.p0_ack_o(wb_q0_done),
	.p0_sel_i(fnSelect(`MStUnit,dram0_instr)),
	.p0_adr_i(dram0_addr),
	.p0_dat_i(dram0_data),
	.p0_hit(wb_hit0),
	.p1_id_i(dram1_id),
	.p1_ol_i(dram1_ol),
	.p1_wr_i(dram1==`DRAMSLOT_BUSY && dram1_store),
	.p1_ack_o(wb_q1_done),
	.p1_sel_i(fnSelect(`MStUnit,dram1_instr)),
	.p1_adr_i(dram1_addr),
	.p1_dat_i(dram1_data),
	.p1_hit(wb_hit1),
	.ol_o(wol),
	.cyc_o(wcyc),
	.stb_o(wstb),
	.ack_i(ack_i),
	.err_i(err_i),
	.tlbmiss_i(tlb_miss),
	.wrv_i(wrv_i),
	.we_o(wwe),
	.sel_o(wsel),
	.adr_o(wadr),
	.dat_o(wdat),
	.cr_o(wcr)
);

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
// If a hardware interrupt instruction is encountered in the instruction stream
// flag it as a privilege violation.
wire freezePC = (irq_i > im) && !int_commit;
always @*
if (freezePC) begin
	ibundle <= {8'h16,{3{1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0}}};
end
else if (phit) begin
	ibundle <= ic_out;
	case(ic_fault)
	2'd1:	ibundle <= {8'h16,{3{1'b1,9'h0,`FLT_TLB,2'b00,4'h0,16'h03C0}}};
	2'd2:	ibundle <= {8'h16,{3{1'b1,9'h0,`FLT_EXF,2'b00,4'h0,16'h03C0}}};
	2'd3:	ibundle <= {8'h16,{3{1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0}}};
	default:
		if (ic_out==128'h0)
			ibundle <= {8'h16,{3{1'b1,9'h0,`FLT_IBE,2'b00,4'h0,16'h03C0}}};
		else begin
			if (ic_out[39:0]==40'h083FC003C0)	begin// PFI
				if (~|irq_i)
					ibundle[39:0] <= `NOP_INSN;
				else
					ibundle[39:0] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
			end
			if (ic_out[79:40]==40'h083FC003C0) begin
				if (~|irq_i)
					ibundle[79:40] <= `NOP_INSN;
				else
					ibundle[79:40] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
			end
			if (ic_out[119:80]==40'h083FC003C0) begin	// PFI
				if (~|irq_i)
					ibundle[119:80] <= `NOP_INSN;
				else
					ibundle[119:80] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
			end
		end
	endcase
end
else begin
	ibundle <= {8'h16,{3{40'h00000000C0}}};
end

function [5:0] fnRt;
input [2:0] unit;
input [39:0] ins;
case(unit)
`BUnit:
	case(ins[`OPCODE4])
	`JAL:		fnRt = ins[`RD];
	`RET:		fnRt = ins[`RD];
	`RTI:		fnRt = ins[39:35]==`SEI ? ins[`RD] : 6'd0;
	default:	fnRt = 6'd0;
	endcase
`IUnit:	fnRt = ins[`RD];
`FUnit:	fnRt = ins[`RD];
`MLdUnit:	fnRt = ins[`RD];
`MStUnit: 
	case(ins[`OPCODE4])
	`PUSH:	fnRt = ins[`RD];
	`PUSHC:	fnRt = ins[`RD];
	`TLB:		fnRt = ins[`RD];
	default:	fnRt = 6'd0;
	endcase
default:	fnRt = 0;
endcase
endfunction

assign Ra0 = insn0[`RS1];
assign Rb0 = insn0[`RS2];
assign Rc0 = insn0[`RS3];
assign Rd0 = fnRt(Unit0(ibundle[124:120]),insn0);
assign Ra1 = insn1[`RS1];
assign Rb1 = insn1[`RS2];
assign Rc1 = insn1[`RS3];
assign Rd1 = fnRt(Unit1(ibundle[124:120]),insn1);
assign Ra2 = insn2[`RS1];
assign Rb2 = insn2[`RS2];
assign Rc2 = insn2[`RS3];
assign Rd2 = fnRt(Unit2(ibundle[124:120]),insn2);

// Detect if a source is automatically valid
function Source1Valid;
input [2:0] unit;
input [39:0] isn;
case(unit)
`BUnit:	
	case(isn[9:6])
	`BRK:	Source1Valid = isn[`RS1]==6'd0;
	`Bcc:	Source1Valid = isn[`RS1]==6'd0;
	`BLcc:	Source1Valid = isn[`RS1]==6'd0;
	`BRcc:	Source1Valid = isn[`RS1]==6'd0;
	`FBcc:	Source1Valid = isn[`RS1]==6'd0;
	`BEQI:	Source1Valid = isn[`RS1]==6'd0;
	`BNEI:	Source1Valid = isn[`RS1]==6'd0;
	`CHKI:	Source1Valid = isn[`RS1]==6'd0;
	`CHK:	Source1Valid = isn[`RS1]==6'd0;
	`JAL:	Source1Valid = isn[`RS1]==6'd0;
	`RET:	Source1Valid = isn[`RS1]==6'd0;
	`JMP:		Source1Valid = TRUE;
	`CALL:	Source1Valid = TRUE;
	`RTI:
		case(isn[39:35])
		5'd0:	Source1Valid = isn[`RS1]==6'd0;
		`REX:	Source1Valid = isn[`RS1]==6'd0;
		default: Source1Valid = TRUE;
		endcase
	default:	Source1Valid = TRUE;
	endcase
`IUnit:	Source1Valid = isn[`RS1]==6'd0;
`FUnit:
	case(isn[9:6])
	`FLT2:
		case(isn[27:22])
		`FSYNC:		Source1Valid = TRUE;
		default:	Source1Valid = isn[`RS1]==6'd0;
		endcase
	`FANDI:	Source1Valid = isn[`RS1]==6'd0;
	`FORI:	Source1Valid = isn[`RS1]==6'd0;
	`FMA:		Source1Valid = isn[`RS1]==6'd0;
	`FMS:		Source1Valid = isn[`RS1]==6'd0;
	`FNMA:	Source1Valid = isn[`RS1]==6'd0;
	`FNMS:	Source1Valid = isn[`RS1]==6'd0;
	default:	Source1Valid = TRUE;
	endcase
`MLdUnit:	Source1Valid = isn[`RS1]==6'd0;
`MStUnit:
	case(isn[9:6])
	`MSX:
		case(isn[39:35])
		`MEMDB:	Source1Valid = TRUE;
		`MEMSB:	Source1Valid = TRUE;
		default:	Source1Valid = isn[`RS1]==6'd0;
		endcase
	default: Source1Valid = isn[`RS1]==6'd0;
	endcase
default:	Source1Valid = TRUE;
endcase
endfunction
  
function Source2Valid;
input [2:0] unit;
input [39:0] isn;
case(unit)
`BUnit:	
	case(isn[9:6])
	`BRK:		Source2Valid = TRUE;
	`Bcc:		Source2Valid = isn[`RS2]==6'd0;
	`BLcc:	Source2Valid = isn[`RS2]==6'd0;
	`BRcc:	Source2Valid = isn[`RS2]==6'd0;
	`FBcc:	Source2Valid = isn[`RS2]==6'd0;
	`BEQI:	Source2Valid = TRUE;
	`BNEI:	Source2Valid = TRUE;
	`CHKI:	Source2Valid = TRUE;
	`CHK:		Source2Valid = isn[`RS2]==6'd0;
	`JAL:		Source2Valid = TRUE;
	`RET:		Source2Valid = isn[`RS2]==6'd0;
	`JMP:		Source2Valid = TRUE;
	`CALL:	Source2Valid = TRUE;
	`RTI:
		case(isn[39:35])
		5'd0:	Source2Valid = TRUE;
		`REX:	Source2Valid = TRUE;
		default: Source2Valid = TRUE;
		endcase
	default:	Source2Valid = TRUE;
	endcase
`IUnit:	
	case({isn[32:31],isn[9:6]})
	`R3:
		case(isn[39:35])
		`SHLI:	Source2Valid = TRUE;
		`ASLI:	Source2Valid = TRUE;
		`SHRI:	Source2Valid = TRUE;
		`ASRI:	Source2Valid = TRUE;
		`ROLI:	Source2Valid = TRUE;
		`RORI:	Source2Valid = TRUE;
		default:	Source2Valid = isn[`RS2]==6'd0;
		endcase
	default:	Source2Valid = TRUE;
	endcase
`FUnit:
	case(isn[9:6])
	`FLT2:
		case(isn[27:22])
		`FMOV:		Source2Valid = TRUE;
		`FTOI:		Source2Valid = TRUE;
		`ITOF:		Source2Valid = TRUE;
		`FNEG:		Source2Valid = TRUE;
		`FABS:		Source2Valid = TRUE;
		`FNABS:		Source2Valid = TRUE;
		`FSIGN:		Source2Valid = TRUE;
		`FMAN:		Source2Valid = TRUE;
		`FSQRT:		Source2Valid = TRUE;
		`FCVTSD:	Source2Valid = TRUE;
		`FCVTDS:	Source2Valid = TRUE;
		`FSYNC:		Source2Valid = TRUE;
		`FSTAT:		Source2Valid = TRUE;
		`FTX:			Source2Valid = TRUE;
		`FCX:			Source2Valid = TRUE;
		`FEX:			Source2Valid = TRUE;
		`FDX:			Source2Valid = TRUE;
		`FRM:			Source2Valid = TRUE;
		default:	Source2Valid = isn[`RS2]==6'd0;
		endcase
	`FANDI:	Source2Valid = TRUE;
	`FORI:	Source2Valid = TRUE;
	`FMA:		Source2Valid = isn[`RS2]==6'd0;
	`FMS:		Source2Valid = isn[`RS2]==6'd0;
	`FNMA:	Source2Valid = isn[`RS2]==6'd0;
	`FNMS:	Source2Valid = isn[`RS2]==6'd0;
	default:	Source2Valid = TRUE;
	endcase
`MLdUnit:
	case(isn[`OPCODE4])
	`MLX:			Source2Valid = TRUE;
	default:	Source2Valid = TRUE;
	endcase
`MStUnit:
	case(isn[`OPCODE4])
	`PUSHC:		Source2Valid = TRUE;
	default:	Source2Valid = isn[`RS2]==6'd0;
	endcase
default:	Source2Valid = TRUE;
endcase
endfunction

function Source3Valid;
input [2:0] unit;
input [39:0] isn;
case(unit)
`BUnit:
	case(isn[9:6])
	`CHK:		Source3Valid = isn[`RS3]==6'd0;
	`BRcc:	Source3Valid = isn[`RS3]==6'd0;
	default:	Source3Valid = TRUE;
	endcase
`IUnit:
	case({isn[32:31],isn[9:6]})
	`R3:	Source3Valid = isn[`RS3]==6'd0;
	`BITFIELD:	Source3Valid = isn[`RS3]==6'd0;
	`CSR:	Source3Valid = TRUE;
	default:	Source3Valid = TRUE;
	endcase
`FUnit:
	case(isn[9:6])
	`FLT2:	Source3Valid = TRUE;
	default:	Source3Valid = isn[`RS3]==6'd0;
	endcase
`MLdUnit:	
	case(isn[9:6])
	`MLX:			Source3Valid = isn[`RS3]==6'd0;
	default:	Source3Valid = TRUE;
	endcase
`MStUnit:
	case(isn[9:6])
	`MSX:			Source3Valid = isn[`RS3]==6'd0;
	default:	Source3Valid = TRUE;
	endcase
default: Source3Valid = TRUE;
endcase
endfunction

function IsMem;
input [2:0] unit;
IsMem = unit==`MLdUnit || unit==`MStUnit;
endfunction

function IsMemNdx;
input [2:0] unit;
input [39:0] isn;
if (IsMem(unit)) begin
	IsMemNdx = (unit==`MLdUnit && isn[9:6]==`MLX)
						|| (unit==`MStUnit && isn[9:6]==`MSX)
						;
end
else
	IsMemNdx = FALSE;
endfunction

function IsLoad;
input [2:0] unit;
IsLoad = unit==`MLdUnit;
endfunction

function IsSWC;
input [2:0] unit;
input [39:0] isn;
if (unit==`MStUnit)
	IsSWC = isn[9:6]==`STDC || (isn[9:6]==`MSX && isn[39:35]==`STDC);
else
	IsSWC = FALSE;
endfunction

function IsSWCX;
input [2:0] unit;
input [39:0] isn;
if (unit==`MStUnit)
	IsSWCX = isn[9:6]==`MSX && isn[39:35]==`STDC;
else
	IsSWCX = FALSE;
endfunction

function IsLWR;
input [2:0] unit;
input [39:0] isn;
if (unit==`MLdUnit)
	IsLWR = isn[9:6]==`LDDR || (isn[9:6]==`MLX && isn[39:35]==`LDDR);
else
	IsLWR = FALSE;
endfunction

function IsLWRX;
input [2:0] unit;
input [39:0] isn;
if (unit==`MLdUnit)
	IsLWRX = isn[9:6]==`MLX && isn[39:35]==`LDDR;
else
	IsLWRX = FALSE;
endfunction

function IsCAS;
input [2:0] unit;
input [39:0] isn;
if (unit==`MStUnit)
	IsCAS = isn[9:6]==`CAS || (isn[9:6]==`MSX && isn[39:35]==`CAS);
else
	IsCAS = FALSE;
endfunction

// Really IsPredictableBranch
// Does not include BccR's
function IsBranch;
input [2:0] unit;
input [39:0] isn;
if (unit==`BUnit)
	case(isn[`OPCODE4])
	`Bcc:	IsBranch = TRUE;
	`BLcc:	IsBranch = TRUE;
//	`BRcc:  IsBranch = TRUE;
	`FBcc:  IsBranch = TRUE;
	`BBc:   IsBranch = TRUE;
	`BEQI:  IsBranch = TRUE;
	`BNEI:  IsBranch = TRUE;
	default:	IsBranch = FALSE;
	endcase
else
	IsBranch = FALSE;
endfunction

function IsWait;
input [2:0] unit;
input [39:0] isn;
IsWait = unit==`BUnit && isn[`OPCODE4]==`RTI && isn[`FUNCT5]==`WAIT;
endfunction

function IsCall;
input [2:0] unit;
input [39:0] isn;
IsCall = unit==`BUnit && isn[`OPCODE4]==`CALL;
endfunction

function IsJmp;
input [2:0] unit;
input [39:0] isn;
IsJmp = unit==`BUnit && isn[`OPCODE4]==`JMP;
endfunction

function IsFlowCtrl;
input [2:0] unit;
IsFlowCtrl = unit==`BUnit;
endfunction

function IsCache;
input [2:0] unit;
input [39:0] isn;
IsCache = unit==`MStUnit && (isn[`OPCODE4]==`CACHE || (isn[`OPCODE4]==`MSX && isn[`FUNCT5]==`CACHE));
endfunction

function [4:0] CacheCmd;
input [39:0] isn;
CacheCmd = isn[`RS2];
endfunction

function IsMemsb;
input [2:0] unit;
input [39:0] isn;
IsMemsb = unit==`MStUnit && isn[`OPCODE4]==`MSX && isn[`FUNCT5]==`MEMSB; 
endfunction

function IsSEI;
input [2:0] unit;
input [39:0] isn;
IsSEI = unit==`BUnit && isn[`OPCODE4]==`RTI && isn[`FUNCT5]==`SEI; 
endfunction

function IsRet;
input [2:0] unit;
input [39:0] isn;
IsRet = unit==`BUnit && isn[`OPCODE4]==`RET;
endfunction

function IsRFW;
input [2:0] unit;
input [39:0] isn;
if (fnRt(unit,isn)==6'd0) 
    IsRFW = FALSE;
else
case(unit)
`BUnit:
	case(isn[`OPCODE4])
	`RTI:			IsRFW = isn[`FUNCT5]==`SEI;
	`JAL:     IsRFW = TRUE;
	`CALL:    IsRFW = TRUE;  
	`RET:     IsRFW = TRUE; 
	default:	IsRFW = FALSE;
	endcase
`IUnit:	IsRFW = TRUE;
`FUnit:
	case(isn[`OPCODE4])
	`FLT2:
		case(isn[27:22])
		`FTX:		IsRFW = FALSE;
		`FCX:		IsRFW = FALSE;
		`FEX:		IsRFW = FALSE;
		`FDX:		IsRFW = FALSE;
		`FRM:		IsRFW = FALSE;
		`FSYNC:	IsRFW = FALSE;
		default:	IsRFW = TRUE;
		endcase
	default:	IsRFW = TRUE;
	endcase
`MLdUnit:	IsRFW = TRUE;
`MStUnit:
	case(isn[`OPCODE4])
	`TLB:		IsRFW = TRUE;
	`PUSH:	IsRFW = TRUE;
	`PUSHC:	IsRFW = TRUE;
	`CAS:		IsRFW = TRUE;
	`MSX:
		case(isn[`FUNCT5])
		`CAS:	IsRFW = TRUE;
		default:	IsRFW = FALSE;
		endcase
	default:	IsRFW = FALSE;
	endcase
default: IsRFW = FALSE;
endcase
endfunction

function IsShifti;
input [2:0] unit;
input [39:0] isn;
if (unit==`IUnit)
	case({isn[32:31],isn[`OPCODE4]})
	`R3:
		case(isn[`FUNCT5])
		`SHLI,`ASLI,`SHRI,`ASRI,`ROLI,`RORI:
			IsShifti = TRUE;
		default:	IsShifti = FALSE;
		endcase
	default:	IsShifti = FALSE;
	endcase
else
	IsShifti = FALSE;
endfunction

function IsShift;
input [2:0] unit;
input [39:0] isn;
if (unit==`IUnit)
	case({isn[32:31],isn[`OPCODE4]})
	`R3:
		case(isn[`FUNCT5])
		`SHL,`ASL,`SHR,`ASR,`ROL,`ROR,
		`SHLI,`ASLI,`SHRI,`ASRI,`ROLI,`RORI:
			IsShift = TRUE;
		default:	IsShift = FALSE;
		endcase
	default:	IsShift = FALSE;
	endcase
else
	IsShift = FALSE;
endfunction

function IsMul;
input [2:0] unit;
input [39:0] isn;
if (unit==`IUnit)
	case({isn[32:31],isn[`OPCODE4]})
	`MUL,`MULU:	IsMul = TRUE;
	`R3:
		case(isn[`FUNCT5])
		`MUL,`MULU,`MULH,`MULUH:
			IsMul = TRUE;
		default:	IsMul = FALSE;
		endcase
	default:	IsMul = FALSE;
	endcase
else
	IsMul = FALSE;
endfunction

function IsDivmod;
input [2:0] unit;
input [39:0] isn;
if (unit==`IUnit)
	case({isn[32:31],isn[`OPCODE4]})
	`DIV,`DIVU,`MOD,`MODU:	IsDivmod = TRUE;
	`R3:
		case(isn[`FUNCT5])
		`DIV,`DIVU,`MOD,`MODU:
			IsDivmod = TRUE;
		default:	IsDivmod = FALSE;
		endcase
	default:	IsDivmod = FALSE;
	endcase
else
	IsDivmod = FALSE;
endfunction

function [9:0] fnSelect;
input [2:0] unit;
input [39:0] isn;
case(unit)
`MLdUnit:
	case(isn[`OPCODE4])
	`LDB:		fnSelect = 10'h001;
	`LDBU:	fnSelect = 10'h001;
	`LDC:		fnSelect = 10'h003;
	`LDCU:	fnSelect = 10'h003;
	`LDT:		fnSelect = 10'h00F;
	`LDTU:	fnSelect = 10'h00F;
	`LDP:		fnSelect = 10'h01F;
	`LDPU:	fnSelect = 10'h01F;
	`LDO:		fnSelect = 10'h0FF;
	`LDOU:	fnSelect = 10'h0FF;
	`LDD:		fnSelect = 10'h3FF;
	`LDDR:	fnSelect = 10'h3FF;
	`MLX:
		case(isn[`FUNCT5])
		`LDB:		fnSelect = 10'h001;
		`LDBU:	fnSelect = 10'h001;
		`LDC:		fnSelect = 10'h003;
		`LDCU:	fnSelect = 10'h003;
		`LDT:		fnSelect = 10'h00F;
		`LDTU:	fnSelect = 10'h00F;
		`LDP:		fnSelect = 10'h01F;
		`LDPU:	fnSelect = 10'h01F;
		`LDO:		fnSelect = 10'h0FF;
		`LDOU:	fnSelect = 10'h0FF;
		`LDD:		fnSelect = 10'h3FF;
		`LDDR:	fnSelect = 10'h3FF;
		default:	fnSelect = 10'h000;
		endcase
	default:	fnSelect = 10'h000;
	endcase
`MStUnit:
	case(isn[`OPCODE4])
	`STB:	fnSelect = 10'h001;
	`STC:	fnSelect = 10'h003;
	`STT:	fnSelect = 10'h00F;
	`STP:	fnSelect = 10'h01F;
	`STO:	fnSelect = 10'h0FF;
	`STD:	fnSelect = 10'h3FF;
	`STDC:	fnSelect = 10'h3FF;
	`CAS:	fnSelect = 10'h3FF;
	`PUSH:	fnSelect = 10'h3FF;
	`PUSHC:	fnSelect = 10'h3FF;
	`MSX:
		case(isn[`FUNCT5])
		`STB:	fnSelect = 10'h001;
		`STC:	fnSelect = 10'h003;
		`STT:	fnSelect = 10'h00F;
		`STP:	fnSelect = 10'h01F;
		`STO:	fnSelect = 10'h0FF;
		`STD:	fnSelect = 10'h3FF;
		`STDC:	fnSelect = 10'h3FF;
		`CAS:		fnSelect = 10'h3FF;
		default:	fnSelect = 10'h000;
		endcase
	default:	fnSelect = 10'h000;
	endcase
default:	fnSelect = 10'h000;
endcase
endfunction

function [79:0] fnDatiAlign;
input [39:0] ins;
input [`ABITS] adr;
input [199:0] dat;
reg [199:0] adat;
begin
adat = dat >> {adr[3:0],3'b0};
case(ins[`OPCODE4])
`LDB:	fnDatiAlign = {72{adat[7],adat[7:0]}};
`LDBU:	fnDatiAlign = {72'd0,adat[7:0]};
`LDC:	fnDatiAlign = {64{adat[15],adat[15:0]}};
`LDCU:	fnDatiAlign = {64'd0,adat[15:0]};
`LDT:	fnDatiAlign = {48{adat[31],adat[31:0]}};
`LDTU:	fnDatiAlign = {48'd0,adat[31:0]};
`LDP:	fnDatiAlign = {40{adat[39],adat[39:0]}};
`LDPU:	fnDatiAlign = {40'd0,adat[39:0]};
`LDO:	fnDatiAlign = {16{adat[63],adat[63:0]}};
`LDOU:	fnDatiAlign = {16'd0,adat[63:0]};
`LDD:	fnDatiAlign = adat[79:0];
`LDDR:	fnDatiAlign = adat[79:0];
`MLX:
	case(ins[`FUNCT5])
	`LDB:	fnDatiAlign = {72{adat[7],adat[7:0]}};
	`LDBU:	fnDatiAlign = {72'd0,adat[7:0]};
	`LDC:	fnDatiAlign = {64{adat[15],adat[15:0]}};
	`LDCU:	fnDatiAlign = {64'd0,adat[15:0]};
	`LDT:	fnDatiAlign = {48{adat[31],adat[31:0]}};
	`LDTU:	fnDatiAlign = {48'd0,adat[31:0]};
	`LDP:	fnDatiAlign = {40{adat[39],adat[39:0]}};
	`LDPU:	fnDatiAlign = {40'd0,adat[39:0]};
	`LDO:	fnDatiAlign = {16{adat[63],adat[63:0]}};
	`LDOU:	fnDatiAlign = {16'd0,adat[63:0]};
	`LDD:	fnDatiAlign = adat[79:0];
	`LDDR:	fnDatiAlign = adat[79:0];
	endcase
	// ToDo: add CAS
default:    fnDatiAlign = dat;
endcase
end
endfunction

function IsTLB;
input [2:0] unit;
input [39:0] isn;
if (unit==`MStUnit)
	case(isn[`OPCODE4])
	`TLB:	IsTLB = TRUE;
	endcase
else
	IsTLB = FALSE;
endfunction

// Indicate if the ALU instruction is valid immediately (single cycle operation)
function IsSingleCycle;
input [2:0] unit;
input [39:0] isn;
IsSingleCycle = !(IsMul(unit,isn)|IsDivmod(unit,isn)|IsTLB(unit,isn));
endfunction

generate begin : gDecocderInst
for (g = 0; g < QENTRIES; g = g + 1) begin
decoder6 iq0 (
	.num(iq_tgt[g][5:0]),
	.out(iq_out2[g])
);
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

	for (n = 0; n < 64; n = n + 1)
		codebuf[n] <= 48'h0;
end


//FT64_RMW_alu urmwalu0 (rmw_instr, rmw_argA, rmw_argB, rmw_argC, rmw_res);



// Stores might exception so we don't want the heads to advance if a subsequent
// instruction is store even though there's no target register.
wire cmt_head1 = (!iq_rfw[heads[1]] && !iq_oddball[heads[1]] && ~|iq_exc[heads[1]]);
wire cmt_head2 = (!iq_rfw[heads[2]] && !iq_oddball[heads[2]] && ~|iq_exc[heads[2]]);

// Determine the head increment amount, this must match code later on.
reg [2:0] hi_amt;
always @*
begin
	hi_amt <= 4'd0;
  casez ({ iq_v[heads[0]],
		iq_state[heads[0]]==IQS_CMT,
		iq_v[heads[1]],
		iq_state[heads[1]]==IQS_CMT,
		iq_v[heads[2]],
		iq_state[heads[2]]==IQS_CMT})

	// retire 3
	6'b0?_0?_0?:
		if (heads[0] != tail0 && heads[1] != tail0 && heads[2] != tail0)
			hi_amt <= 3'd3;
		else if (heads[0] != tail0 && heads[1] != tail0)
			hi_amt <= 3'd2;
		else if (heads[0] != tail0)
			hi_amt <= 3'd1;
	6'b0?_0?_10:
		if (heads[0] != tail0 && heads[1] != tail0)
			hi_amt <= 3'd2;
		else if (heads[0] != tail0)
			hi_amt <= 3'd1;
		else
			hi_amt <= 3'd0;
	6'b0?_0?_11:
		if (`NUM_CMT > 2 || cmt_head2)
			hi_amt <= 3'd3;
		else
			hi_amt <= 3'd2;

	// retire 1 (wait for regfile for heads[1])
	6'b0?_10_??:
		hi_amt <= 3'd1;

	// retire 2
	6'b0?_11_0?,
	6'b0?_11_10:
    if (`NUM_CMT > 1 || cmt_head1)
			hi_amt <= 3'd2;	
    else
			hi_amt <= 3'd1;
  6'b0?_11_11:
    if (`NUM_CMT > 2 || (`NUM_CMT > 1 && cmt_head2))
			hi_amt <= 3'd3;
  	else if (`NUM_CMT > 1 || cmt_head1)
			hi_amt <= 3'd2;
  	else
			hi_amt <= 3'd1;
  6'b10_??_??:	;
  6'b11_0?_0?:
  	if (heads[1] != tail0 && heads[2] != tail0)
			hi_amt <= 3'd3;
  	else if (heads[1] != tail0)
			hi_amt <= 3'd2;
  	else
			hi_amt <= 3'd1;
  6'b11_0?_10:
  	if (heads[1] != tail0)
			hi_amt <= 3'd2;
  	else
			hi_amt <= 3'd1;
  6'b11_0?_11:
  	if (heads[1] != tail0) begin
  		if (`NUM_CMT > 2 || cmt_head2)
				hi_amt <= 3'd3;
  		else
				hi_amt <= 3'd2;
  	end
  	else
			hi_amt <= 3'd1;
  6'b11_10_??:
			hi_amt <= 3'd1;
  6'b11_11_0?:
  	if (`NUM_CMT > 1 && heads[2] != tail0)
			hi_amt <= 3'd3;
  	else if (cmt_head1 && heads[2] != tail0)
			hi_amt <= 3'd3;
		else if (`NUM_CMT > 1 || cmt_head1)
			hi_amt <= 3'd2;
  	else
			hi_amt <= 3'd1;
  6'b11_11_10:
		if (`NUM_CMT > 1 || cmt_head1)
			hi_amt <= 3'd2;
  	else
			hi_amt <= 3'd1;
	6'b11_11_11:
		if (`NUM_CMT > 2 || (`NUM_CMT > 1 && cmt_head2))
			hi_amt <= 3'd3;
		else if (`NUM_CMT > 1 || cmt_head1)
			hi_amt <= 3'd2;
		else
			hi_amt <= 3'd1;
	default:
		begin
			hi_amt <= 3'd0;
			$display("hi_amt: Uncoded case %h",{ iq_v[heads[0]],
				iq_state[heads[0]],
				iq_v[heads[1]],
				iq_state[heads[1]],
				iq_v[heads[2]],
				iq_state[heads[2]]});
		end
  endcase
end

// Amount subtracted from sequence numbers
reg [`SNBITS] tosub;
always @*
case(hi_amt)
3'd3: tosub <= (iq_v[heads[2]] ? iq_sn[heads[2]]
							 : iq_v[heads[1]] ? iq_sn[heads[1]]
							 : iq_v[heads[0]] ? iq_sn[heads[0]]
							 : 4'b0);
3'd2: tosub <= (iq_v[heads[1]] ? iq_sn[heads[1]]
							 : iq_v[heads[0]] ? iq_sn[heads[0]]
							 : 4'b0);
3'd1: tosub <= (iq_v[heads[0]] ? iq_sn[heads[0]]
							 : 4'b0);							 
default:	tosub <= 4'd0;
endcase

reg [`SNBITS] maxsn;
always @*
begin
	maxsn = 8'd0;
	for (n = 0; n < QENTRIES; n = n + 1)
		if (iq_sn[n] > maxsn && iq_v[n])
			maxsn = iq_sn[n];
	maxsn = maxsn - tosub;
end

//
// BRANCH-MISS LOGIC: livetarget
//
// livetarget implies that there is a not-to-be-stomped instruction that targets the register in question
// therefore, if it is zero it implies the rf_v value should become VALID on a branchmiss
// 

always @*
for (j = 1; j < AREGS; j = j + 1) begin
	livetarget[j] = 1'b0;
	for (n = 0; n < QENTRIES; n = n + 1)
		livetarget[j] = livetarget[j] | iq_livetarget[n][j];
end

always @*
	for (n = 0; n < QENTRIES; n = n + 1)
		iq_livetarget[n] = {AREGS {iq_v[n]}} & {AREGS {~iq_stomp[n]}} & iq_out2[n];

//
// BRANCH-MISS LOGIC: latestID
//
// latestID is the instruction queue ID of the newest instruction (latest) that targets
// a particular register.  looks a lot like scheduling logic, but in reverse.
// 
always @*
	for (n = 0; n < QENTRIES; n = n + 1) begin
		iq_cumulative[n] = 1'b0;
		for (j = n; j < n + QENTRIES; j = j + 1) begin
			if (missid==(j % QENTRIES))
				for (k = n; k <= j; k = k + 1)
					iq_cumulative[n] = iq_cumulative[n] | iq_livetarget[k % QENTRIES];
		end
	end

always @*
	for (n = 0; n < QENTRIES; n = n + 1)
    iq_latestID[n] = (missid == n || ((iq_livetarget[n] & iq_cumulative[(n+1)%QENTRIES]) == {AREGS{1'b0}}))
				    ? iq_livetarget[n]
				    : {AREGS{1'b0}};

always @*
	for (n = 0; n < QENTRIES; n = n + 1)
	  iq_source[n] = | iq_latestID[n];


//
// additional logic for ISSUE
//
// for the moment, we look at ALU-input buffers to allow back-to-back issue of 
// dependent instructions ... we do not, however, look ahead for DRAM requests 
// that will become valid in the next cycle.  instead, these have to propagate
// their results into the IQ entry directly, at which point it becomes issue-able
//

// note that, for all intents & purposes, iq_done == iq_agen ... no need to duplicate

wire [QENTRIES-1:0] args_valid;
wire [QENTRIES-1:0] could_issue;
wire [QENTRIES-1:0] could_issueid;

// Note that bypassing is provided only from the first fpu.
generate begin : issue_logic
for (g = 0; g < QENTRIES; g = g + 1)
begin
assign args_valid[g] =
		  (iq_argA_v[g] 
`ifdef FU_BYPASS
        || (iq_argA_s[g] == alu0_sourceid && alu0_dataready && (~alu0_mem | alu0_push))
        || ((iq_argA_s[g] == alu1_sourceid && alu1_dataready && (~alu1_mem | alu1_push)) && (`NUM_ALU > 1))
        || ((iq_argA_s[g] == fpu1_sourceid && fpu1_dataready) && (`NUM_FPU > 0))
`endif
        )
    && (iq_argB_v[g] || iq_mem[g]	// a2 does not need to be valid immediately for a mem op (agen), it is checked by iq_memready logic
`ifdef FU_BYPASS
        || (iq_argB_s[g] == alu0_sourceid && alu0_dataready && (~alu0_mem | alu0_push))
        || ((iq_argB_s[g] == alu1_sourceid && alu1_dataready && (~alu1_mem | alu1_push)) && (`NUM_ALU > 1))
        || ((iq_argB_s[g] == fpu1_sourceid && fpu1_dataready) && (`NUM_FPU > 0))
`endif
        )
    && (iq_argC_v[g] 
        || (iq_mem[g] & ~iq_agen[g] & ~iq_memndx[g])    // a3 needs to be valid for indexed instruction
//        || (iq_mem[g] & ~iq_agen[g])
`ifdef FU_BYPASS
        || (iq_argC_s[g] == alu0_sourceid && alu0_dataready && (~alu0_mem | alu0_push))
        || ((iq_argC_s[g] == alu1_sourceid && alu1_dataready && (~alu1_mem | alu1_push)) && (`NUM_ALU > 1))
`endif
        )
    ;

assign could_issue[g] = iq_v[g] && iq_state[g]==IQS_QUEUED	&& args_valid[g];
                        //&& (iq_mem[g] ? !iq_agen[g] : 1'b1);

assign could_issueid[g] = (iq_v[g]);// || (g==tail0 && canq1))// || (g==tail1 && canq2))
end                                 
end
endgenerate

// Detect if there are any valid queue entries prior to the given queue entry.
reg [QENTRIES-1:0] prior_valid;
//generate begin : gPriorValid
always @*
for (j = 0; j < QENTRIES; j = j + 1)
begin
	prior_valid[heads[j]] = 1'b0;
	if (j > 0)
		for (n = j-1; n >= 0; n = n - 1)
			prior_valid[heads[j]] = prior_valid[heads[j]]|iq_v[heads[n]];
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
			prior_sync[heads[j]] = prior_sync[heads[j]]|(iq_v[heads[n]] & iq_sync[heads[n]]);
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
			prior_fsync[heads[j]] = prior_fsync[heads[j]]|(iq_v[heads[n]] & iq_fsync[heads[n]]);
end
//end
//endgenerate

// Start search for instructions to process at head of queue (oldest instruction).
always @*
begin
	iq_alu0_issue = {QENTRIES{1'b0}};
	iq_alu1_issue = {QENTRIES{1'b0}};
	
	if (alu0_available & alu0_idle) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_alu[heads[n]]
			&& iq_alu0_issue == {QENTRIES{1'b0}}
			// If there are no valid queue entries prior it doesn't matter if there is
			// a sync.
			&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
			)
			  iq_alu0_issue[heads[n]] = `TRUE;
		end
	end

	if (alu1_available && alu1_idle && `NUM_ALU > 1) begin
//		if ((could_issue & ~iq_alu0_issue & ~iq_alu0) != {QENTRIES{1'b0}}) begin
			for (n = 0; n < QENTRIES; n = n + 1) begin
				if (could_issue[heads[n]] && iq_alu[heads[n]]
					&& !iq_alu0_issue[heads[n]]
					&& iq_alu1_issue == {QENTRIES{1'b0}}
					&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
				)
				  iq_alu1_issue[heads[n]] = `TRUE;
			end
//		end
	end
end

// Start search for instructions to process at head of queue (oldest instruction).
always @*
begin
	iq_fpu1_issue = {QENTRIES{1'b0}};
	iq_fpu2_issue = {QENTRIES{1'b0}};
	
	if (fpu1_available && fpu1_idle && `NUM_FPU > 0) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_fpu[heads[n]]
			&& iq_fpu1_issue == {QENTRIES{1'b0}}
			// If there are no valid queue entries prior it doesn't matter if there is
			// a sync.
			&& (!(prior_sync[heads[n]]|prior_fsync[heads[n]]) || !prior_valid[heads[n]])
			)
			  iq_fpu1_issue[heads[n]] = `TRUE;
		end
	end

	if (fpu2_available && fpu2_idle && `NUM_FPU > 1) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_fpu[heads[n]]
			&& !iq_fpu1_issue[heads[n]]
			&& iq_fpu2_issue == {QENTRIES{1'b0}}
			&& (!(prior_sync[heads[n]]|prior_fsync[heads[n]]) || !prior_valid[heads[n]])
			)
			  iq_fpu2_issue[heads[n]] = `TRUE;
		end
	end
end

reg [`QBITS] nids [0:QENTRIES-1];
always @*
for (j = 0; j < QENTRIES; j = j + 1) begin
	// We can't both start and stop at j
	for (n = j; n != (j+1)%QENTRIES; n = (n + (QENTRIES-1)) % QENTRIES)
		nids[j] = n;
	// Do the last one
	nids[j] = (j+1)%QENTRIES;
end

reg [QENTRIES-1:0] nextqd;

// Search the queue for the next entry on the same thread.
reg [`QBITS] nid;
always @*
begin
	nid = fcu_id;
	for (n = QENTRIES-1; n > 0; n = n - 1)
		nid = (fcu_id + n) % QENTRIES;
end

always @*
for (n = 0; n < QENTRIES; n = n + 1)
	nextqd[n] <= iq_sn[nids[n]] > iq_sn[n] || iq_v[n];

//assign nextqd = 8'hFF;

// Don't issue to the fcu until the following instruction is enqueued.
// However, if the queue is full then issue anyway. A branch miss will likely occur.
// Start search for instructions at head of queue (oldest instruction).
always @*
begin
	iq_fcu_issue = {QENTRIES{1'b0}};
	
	if (fcu_done & ~branchmiss) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_fc[heads[n]] && (nextqd[heads[n]] || iq_br[heads[n]])
			&& iq_fcu_issue == {QENTRIES{1'b0}}
			&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
			)
			  iq_fcu_issue[heads[n]] = `TRUE;
		end
	end
end

// Test if a given address is in the write buffer. This is done only for the
// first two queue slots to save logic on comparators.
reg inwb0;
always @*
begin
	inwb0 = FALSE;
	for (n = 0; n < `WB_DEPTH; n = n + 1)
		if (iq_ma[heads[0]][AMSB:4]==wb_addr[n][AMSB:4] && wb_v[n])
			inwb0 = TRUE;
end

reg inwb1;
always @*
begin
	inwb1 = FALSE;
	for (n = 0; n < `WB_DEPTH; n = n + 1)
		if (iq_ma[heads[1]][AMSB:4]==wb_addr[n][AMSB:4] && wb_v[n])
			inwb1 = TRUE;
end

always @*
begin
	for (n = 0; n < QENTRIES; n = n + 1) begin
		iq_v[n] = iq_state[n] != IQS_INVALID;
		iq_done[n] = iq_state[n]==IQS_DONE || iq_state[n]==IQS_CMT;
		iq_out[n] = iq_state[n]==IQS_OUT;
		iq_agen[n] = iq_state[n]==IQS_AGEN;
	end
end

// determine if the instructions ready to issue can, in fact, issue.
// "ready" means that the instruction has valid operands but has not gone yet
reg [1:0] issue_count, missue_count;
generate begin : gMemIssue
always @*
begin
	issue_count = 0;
	 memissue[ heads[0] ] =	iq_memready[ heads[0] ] && !(iq_load[heads[0]] && inwb0);		// first in line ... go as soon as ready
	 if (memissue[heads[0]])
	 	issue_count = issue_count + 1;

	 memissue[ heads[1] ] =	~iq_stomp[heads[1]] && iq_memready[ heads[1] ]		// addr and data are valid
					&& issue_count < `NUM_MEM
					// ... and no preceding instruction is ready to go
					//&& ~iq_memready[heads[0]]
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]]) || iq_done[heads[0]]
						|| ((iq_ma[heads[1]][AMSB:3] != iq_ma[heads[0]][AMSB:3] || iq_out[heads[0]] || iq_done[heads[0]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iq_rl[heads[1]] ? iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]] : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[1]] && (inwb1 || iq_store[heads[0]]))
					// ... and, if it is a store, there is no chance of it being undone
					&& ((iq_load[heads[1]] && sple) ||
					   !(iq_fc[heads[0]]||iq_canex[heads[0]]));
	 if (memissue[heads[1]])
	 	issue_count = issue_count + 1;

	 memissue[ heads[2] ] =	~iq_stomp[heads[2]] && iq_memready[ heads[2] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]])  || iq_done[heads[0]]
						|| ((iq_ma[heads[2]][AMSB:3] != iq_ma[heads[0]][AMSB:3] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]])  || iq_done[heads[1]]
						|| ((iq_ma[heads[2]][AMSB:3] != iq_ma[heads[1]][AMSB:3] || iq_out[heads[1]] || iq_done[heads[1]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iq_rl[heads[2]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[2]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
            && (!(iq_iv[heads[1]] && iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
    				&& (!(iq_iv[heads[1]] && iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
					// ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[2]] && sple) ||
					      !(iq_fc[heads[0]]||iq_canex[heads[0]])
					   && !(iq_fc[heads[1]]||iq_canex[heads[1]]));
	 if (memissue[heads[2]])
	 	issue_count = issue_count + 1;
					        
	 memissue[ heads[3] ] =	~iq_stomp[heads[3]] && iq_memready[ heads[3] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]])  || iq_done[heads[0]]
						|| ((iq_ma[heads[3]][AMSB:3] != iq_ma[heads[0]][AMSB:3] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]])  || iq_done[heads[1]]
						|| ((iq_ma[heads[3]][AMSB:3] != iq_ma[heads[1]][AMSB:3] || iq_out[heads[1]] || iq_done[heads[1]])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]])  || iq_done[heads[2]]
						|| ((iq_ma[heads[3]][AMSB:3] != iq_ma[heads[2]][AMSB:3] || iq_out[heads[2]] || iq_done[heads[2]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iq_rl[heads[3]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[3]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_iv[heads[1]] && iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
    				&& (!(iq_iv[heads[1]] && iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    // ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[3]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]]));
	 if (memissue[heads[3]])
	 	issue_count = issue_count + 1;

	if (QENTRIES > 4) begin
	 memissue[ heads[4] ] =	~iq_stomp[heads[4]] && iq_memready[ heads[4] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					//&& ~iq_memready[heads[3]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]])  || iq_done[heads[0]]
						|| ((iq_ma[heads[4]][AMSB:3] != iq_ma[heads[0]][AMSB:3] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]])  || iq_done[heads[1]]
						|| ((iq_ma[heads[4]][AMSB:3] != iq_ma[heads[1]][AMSB:3] || iq_out[heads[1]] || iq_done[heads[1]])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]])  || iq_done[heads[2]]
						|| ((iq_ma[heads[4]][AMSB:3] != iq_ma[heads[2]][AMSB:3] || iq_out[heads[2]] || iq_done[heads[2]])))
					&& (!iq_mem[heads[3]] || (iq_agen[heads[3]] & iq_out[heads[3]])  || iq_done[heads[3]]
						|| ((iq_ma[heads[4]][AMSB:3] != iq_ma[heads[3]][AMSB:3] || iq_out[heads[3]] || iq_done[heads[3]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iq_rl[heads[4]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
										 && (iq_done[heads[3]] || !iq_v[heads[3]] || !iq_mem[heads[3]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					&& !(iq_aq[heads[3]] && iq_v[heads[3]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[4]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]] || iq_store[heads[3]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_iv[heads[1]] && iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
                    && (!(iq_iv[heads[3]] && iq_memsb[heads[3]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]]))
                    		)
    				&& (!(iq_v[heads[1]] && iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    && (!(iq_iv[heads[3]] && iq_memdb[heads[3]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]]))
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[4]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]])
                       && !(iq_fc[heads[3]]||iq_canex[heads[3]]));
	 if (memissue[heads[4]])
	 	issue_count = issue_count + 1;
	end

	if (QENTRIES > 5) begin
	 memissue[ heads[5] ] =	~iq_stomp[heads[5]] && iq_memready[ heads[5] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					//&& ~iq_memready[heads[3]] 
					//&& ~iq_memready[heads[4]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]]) || iq_done[heads[0]] 
						|| ((iq_ma[heads[5]][AMSB:3] != iq_ma[heads[0]][AMSB:3] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]]) || iq_done[heads[1]] 
						|| ((iq_ma[heads[5]][AMSB:3] != iq_ma[heads[1]][AMSB:3] || iq_out[heads[1]] || iq_done[heads[1]])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]]) || iq_done[heads[2]] 
						|| ((iq_ma[heads[5]][AMSB:3] != iq_ma[heads[2]][AMSB:3] || iq_out[heads[2]] || iq_done[heads[2]])))
					&& (!iq_mem[heads[3]] || (iq_agen[heads[3]] & iq_out[heads[3]]) || iq_done[heads[3]] 
						|| ((iq_ma[heads[5]][AMSB:3] != iq_ma[heads[3]][AMSB:3] || iq_out[heads[3]] || iq_done[heads[3]])))
					&& (!iq_mem[heads[4]] || (iq_agen[heads[4]] & iq_out[heads[4]]) || iq_done[heads[4]] 
						|| ((iq_ma[heads[5]][AMSB:3] != iq_ma[heads[4]][AMSB:3] || iq_out[heads[4]] || iq_done[heads[4]])))
					// ... if a release, any prior memory ops must be done before this one
					&& (iq_rl[heads[5]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
										 && (iq_done[heads[3]] || !iq_v[heads[3]] || !iq_mem[heads[3]])
										 && (iq_done[heads[4]] || !iq_v[heads[4]] || !iq_mem[heads[4]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					&& !(iq_aq[heads[3]] && iq_v[heads[3]])
					&& !(iq_aq[heads[4]] && iq_v[heads[4]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[5]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]] || iq_store[heads[3]]
						|| iq_store[heads[4]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_iv[heads[1]] && iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
                    && (!(iq_iv[heads[3]] && iq_memsb[heads[3]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]]))
                    		)
                    && (!(iq_iv[heads[4]] && iq_memsb[heads[4]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]]))
                    		)
    				&& (!(iq_iv[heads[1]] && iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    && (!(iq_iv[heads[3]] && iq_memdb[heads[3]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]]))
                     		)
                    && (!(iq_iv[heads[4]] && iq_memdb[heads[4]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]]))
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[5]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]])
                       && !(iq_fc[heads[3]]||iq_canex[heads[3]])
                       && !(iq_fc[heads[4]]||iq_canex[heads[4]]));
	 if (memissue[heads[5]])
	 	issue_count = issue_count + 1;
	end

`ifdef FULL_ISSUE_LOGIC
if (QENTRIES > 6) begin
 memissue[ heads[6] ] =	~iq_stomp[heads[6]] && iq_memready[ heads[6] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					//&& ~iq_memready[heads[3]] 
					//&& ~iq_memready[heads[4]] 
					//&& ~iq_memready[heads[5]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]]) || iq_done[heads[0]] 
						|| ((iq_ma[heads[6]][AMSB:3] != iq_ma[heads[0]][AMSB:3])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]]) || iq_done[heads[1]] 
						|| ((iq_ma[heads[6]][AMSB:3] != iq_ma[heads[1]][AMSB:3])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]]) || iq_done[heads[2]] 
						|| ((iq_ma[heads[6]][AMSB:3] != iq_ma[heads[2]][AMSB:3])))
					&& (!iq_mem[heads[3]] || (iq_agen[heads[3]] & iq_out[heads[3]]) || iq_done[heads[3]] 
						|| ((iq_ma[heads[6]][AMSB:3] != iq_ma[heads[3]][AMSB:3])))
					&& (!iq_mem[heads[4]] || (iq_agen[heads[4]] & iq_out[heads[4]]) || iq_done[heads[4]] 
						|| ((iq_ma[heads[6]][AMSB:3] != iq_ma[heads[4]][AMSB:3])))
					&& (!iq_mem[heads[5]] || (iq_agen[heads[5]] & iq_out[heads[5]]) || iq_done[heads[5]] 
						|| ((iq_ma[heads[6]][AMSB:3] != iq_ma[heads[5]][AMSB:3])))
					&& (iq_rl[heads[6]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
										 && (iq_done[heads[3]] || !iq_v[heads[3]] || !iq_mem[heads[3]])
										 && (iq_done[heads[4]] || !iq_v[heads[4]] || !iq_mem[heads[4]])
										 && (iq_done[heads[5]] || !iq_v[heads[5]] || !iq_mem[heads[5]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					&& !(iq_aq[heads[3]] && iq_v[heads[3]])
					&& !(iq_aq[heads[4]] && iq_v[heads[4]])
					&& !(iq_aq[heads[5]] && iq_v[heads[5]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[6]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]] || iq_store[heads[3]]
						|| iq_store[heads[4]] || iq_store[heads[5]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_iv[heads[1]] && iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
                    && (!(iq_iv[heads[3]] && iq_memsb[heads[3]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]]))
                    		)
                    && (!(iq_iv[heads[4]] && iq_memsb[heads[4]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]]))
                    		)
                    && (!(iq_iv[heads[5]] && iq_memsb[heads[5]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]]))
                    		)
    				&& (!(iq_iv[heads[1]] && iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    && (!(iq_iv[heads[3]] && iq_memdb[heads[3]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]]))
                     		)
                    && (!(iq_iv[heads[4]] && iq_memdb[heads[4]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]]))
                     		)
                    && (!(iq_iv[heads[5]] && iq_memdb[heads[5]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]]))
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[6]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]])
                       && !(iq_fc[heads[3]]||iq_canex[heads[3]])
                       && !(iq_fc[heads[4]]||iq_canex[heads[4]])
                       && !(iq_fc[heads[5]]||iq_canex[heads[5]]));
	 if (memissue[heads[6]])
	 	issue_count = issue_count + 1;
	end

	if (QENTRIES > 7) begin
	memissue[ heads[7] ] =	~iq_stomp[heads[7]] && iq_memready[ heads[7] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					//&& ~iq_memready[heads[3]] 
					//&& ~iq_memready[heads[4]] 
					//&& ~iq_memready[heads[5]] 
					//&& ~iq_memready[heads[6]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]]) || iq_done[heads[0]]
						|| ((iq_ma[heads[7]][AMSB:3] != iq_ma[heads[0]][AMSB:3] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]]) || iq_done[heads[1]]
						|| ((iq_ma[heads[7]][AMSB:3] != iq_ma[heads[1]][AMSB:3] || iq_out[heads[1]] || iq_done[heads[1]])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]]) || iq_done[heads[2]] 
						|| ((iq_ma[heads[7]][AMSB:3] != iq_ma[heads[2]][AMSB:3] || iq_out[heads[2]] || iq_done[heads[2]])))
					&& (!iq_mem[heads[3]] || (iq_agen[heads[3]] & iq_out[heads[3]]) || iq_done[heads[3]] 
						|| ((iq_ma[heads[7]][AMSB:3] != iq_ma[heads[3]][AMSB:3] || iq_out[heads[3]] || iq_done[heads[3]])))
					&& (!iq_mem[heads[4]] || (iq_agen[heads[4]] & iq_out[heads[4]]) || iq_done[heads[4]] 
						|| ((iq_ma[heads[7]][AMSB:3] != iq_ma[heads[4]][AMSB:3] || iq_out[heads[4]] || iq_done[heads[4]])))
					&& (!iq_mem[heads[5]] || (iq_agen[heads[5]] & iq_out[heads[5]]) || iq_done[heads[5]] 
						|| ((iq_ma[heads[7]][AMSB:3] != iq_ma[heads[5]][AMSB:3] || iq_out[heads[5]] || iq_done[heads[5]])))
					&& (!iq_mem[heads[6]] || (iq_agen[heads[6]] & iq_out[heads[6]]) || iq_done[heads[6]] 
						|| ((iq_ma[heads[7]][AMSB:3] != iq_ma[heads[6]][AMSB:3] || iq_out[heads[6]] || iq_done[heads[6]])))
					&& (iq_rl[heads[7]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
										 && (iq_done[heads[3]] || !iq_v[heads[3]] || !iq_mem[heads[3]])
										 && (iq_done[heads[4]] || !iq_v[heads[4]] || !iq_mem[heads[4]])
										 && (iq_done[heads[5]] || !iq_v[heads[5]] || !iq_mem[heads[5]])
										 && (iq_done[heads[6]] || !iq_v[heads[6]] || !iq_mem[heads[6]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					&& !(iq_aq[heads[3]] && iq_v[heads[3]])
					&& !(iq_aq[heads[4]] && iq_v[heads[4]])
					&& !(iq_aq[heads[5]] && iq_v[heads[5]])
					&& !(iq_aq[heads[6]] && iq_v[heads[6]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[7]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]] || iq_store[heads[3]]
						|| iq_store[heads[4]] || iq_store[heads[5]] || iq_store[heads[6]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_iv[heads[1]] && iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
                    && (!(iq_iv[heads[3]] && iq_memsb[heads[3]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]]))
                    		)
                    && (!(iq_iv[heads[4]] && iq_memsb[heads[4]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]]))
                    		)
                    && (!(iq_iv[heads[5]] && iq_memsb[heads[5]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]]))
                    		)
                    && (!(iq_iv[heads[6]] && iq_memsb[heads[6]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]])
                    		&&   (iq_done[heads[5]] || !iq_v[heads[5]]))
                    		)
    				&& (!(iq_iv[heads[1]] && iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    && (!(iq_iv[heads[3]] && iq_memdb[heads[3]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]]))
                     		)
                    && (!(iq_iv[heads[4]] && iq_memdb[heads[4]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]]))
                     		)
                    && (!(iq_iv[heads[5]] && iq_memdb[heads[5]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]]))
                     		)
                    && (!(iq_iv[heads[6]] && iq_memdb[heads[6]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]])
                     		&& (!iq_mem[heads[5]] || iq_done[heads[5]] || !iq_v[heads[5]]))
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[7]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]])
                       && !(iq_fc[heads[3]]||iq_canex[heads[3]])
                       && !(iq_fc[heads[4]]||iq_canex[heads[4]])
                       && !(iq_fc[heads[5]]||iq_canex[heads[5]])
                       && !(iq_fc[heads[6]]||iq_canex[heads[6]]));
	 if (memissue[heads[7]])
	 	issue_count = issue_count + 1;
	end

	if (QENTRIES > 8) begin
	memissue[ heads[8] ] =	~iq_stomp[heads[8]] && iq_memready[ heads[8] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					//&& ~iq_memready[heads[3]] 
					//&& ~iq_memready[heads[4]] 
					//&& ~iq_memready[heads[5]] 
					//&& ~iq_memready[heads[6]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]]) || iq_done[heads[0]]
						|| ((iq_ma[heads[8]][AMSB:3] != iq_ma[heads[0]][AMSB:3] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]]) || iq_done[heads[1]]
						|| ((iq_ma[heads[8]][AMSB:3] != iq_ma[heads[1]][AMSB:3] || iq_out[heads[1]] || iq_done[heads[1]])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]]) || iq_done[heads[2]] 
						|| ((iq_ma[heads[8]][AMSB:3] != iq_ma[heads[2]][AMSB:3] || iq_out[heads[2]] || iq_done[heads[2]])))
					&& (!iq_mem[heads[3]] || (iq_agen[heads[3]] & iq_out[heads[3]]) || iq_done[heads[3]] 
						|| ((iq_ma[heads[8]][AMSB:3] != iq_ma[heads[3]][AMSB:3] || iq_out[heads[3]] || iq_done[heads[3]])))
					&& (!iq_mem[heads[4]] || (iq_agen[heads[4]] & iq_out[heads[4]]) || iq_done[heads[4]] 
						|| ((iq_ma[heads[8]][AMSB:3] != iq_ma[heads[4]][AMSB:3] || iq_out[heads[4]] || iq_done[heads[4]])))
					&& (!iq_mem[heads[5]] || (iq_agen[heads[5]] & iq_out[heads[5]]) || iq_done[heads[5]] 
						|| ((iq_ma[heads[8]][AMSB:3] != iq_ma[heads[5]][AMSB:3] || iq_out[heads[5]] || iq_done[heads[5]])))
					&& (!iq_mem[heads[6]] || (iq_agen[heads[6]] & iq_out[heads[6]]) || iq_done[heads[6]] 
						|| ((iq_ma[heads[8]][AMSB:3] != iq_ma[heads[6]][AMSB:3] || iq_out[heads[6]] || iq_done[heads[6]])))
					&& (!iq_mem[heads[7]] || (iq_agen[heads[7]] & iq_out[heads[7]]) || iq_done[heads[7]] 
						|| ((iq_ma[heads[8]][AMSB:3] != iq_ma[heads[7]][AMSB:3] || iq_out[heads[7]] || iq_done[heads[7]])))
					&& (iq_rl[heads[8]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
										 && (iq_done[heads[3]] || !iq_v[heads[3]] || !iq_mem[heads[3]])
										 && (iq_done[heads[4]] || !iq_v[heads[4]] || !iq_mem[heads[4]])
										 && (iq_done[heads[5]] || !iq_v[heads[5]] || !iq_mem[heads[5]])
										 && (iq_done[heads[6]] || !iq_v[heads[6]] || !iq_mem[heads[6]])
										 && (iq_done[heads[7]] || !iq_v[heads[7]] || !iq_mem[heads[7]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					&& !(iq_aq[heads[3]] && iq_v[heads[3]])
					&& !(iq_aq[heads[4]] && iq_v[heads[4]])
					&& !(iq_aq[heads[5]] && iq_v[heads[5]])
					&& !(iq_aq[heads[6]] && iq_v[heads[6]])
					&& !(iq_aq[heads[7]] && iq_v[heads[7]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[8]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]] || iq_store[heads[3]]
						|| iq_store[heads[4]] || iq_store[heads[5]] || iq_store[heads[6]] || iq_store[heads[7]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_iv[heads[1]] && iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
                    && (!(iq_iv[heads[3]] && iq_memsb[heads[3]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]]))
                    		)
                    && (!(iq_iv[heads[4]] && iq_memsb[heads[4]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]]))
                    		)
                    && (!(iq_iv[heads[5]] && iq_memsb[heads[5]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]]))
                    		)
                    && (!(iq_iv[heads[6]] && iq_memsb[heads[6]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]])
                    		&&   (iq_done[heads[5]] || !iq_v[heads[5]]))
                    		)
                    && (!(iq_iv[heads[7]] && iq_memsb[heads[7]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]])
                    		&&   (iq_done[heads[5]] || !iq_v[heads[5]])
                    		&&   (iq_done[heads[6]] || !iq_v[heads[6]])
                    		)
                    		)
    				&& (!(iq_iv[heads[1]] && iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    && (!(iq_iv[heads[3]] && iq_memdb[heads[3]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]]))
                     		)
                    && (!(iq_iv[heads[4]] && iq_memdb[heads[4]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]]))
                     		)
                    && (!(iq_iv[heads[5]] && iq_memdb[heads[5]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]]))
                     		)
                    && (!(iq_iv[heads[6]] && iq_memdb[heads[6]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]])
                     		&& (!iq_mem[heads[5]] || iq_done[heads[5]] || !iq_v[heads[5]]))
                     		)
                    && (!(iq_iv[heads[7]] && iq_memdb[heads[7]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]])
                     		&& (!iq_mem[heads[5]] || iq_done[heads[5]] || !iq_v[heads[5]])
                     		&& (!iq_mem[heads[6]] || iq_done[heads[6]] || !iq_v[heads[6]])
                     		)
                     		)
					// ... and, if it is a SW, there is no chance of it being undone
					&& ((iq_load[heads[8]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]])
                       && !(iq_fc[heads[3]]||iq_canex[heads[3]])
                       && !(iq_fc[heads[4]]||iq_canex[heads[4]])
                       && !(iq_fc[heads[5]]||iq_canex[heads[5]])
                       && !(iq_fc[heads[6]]||iq_canex[heads[6]])
                       && !(iq_fc[heads[7]]||iq_canex[heads[7]])
                       );
	 if (memissue[heads[8]])
	 	issue_count = issue_count + 1;
	end

	if (QENTRIES > 9) begin
	memissue[ heads[9] ] =	~iq_stomp[heads[9]] && iq_memready[ heads[9] ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& issue_count < `NUM_MEM
					//&& ~iq_memready[heads[0]]
					//&& ~iq_memready[heads[1]] 
					//&& ~iq_memready[heads[2]] 
					//&& ~iq_memready[heads[3]] 
					//&& ~iq_memready[heads[4]] 
					//&& ~iq_memready[heads[5]] 
					//&& ~iq_memready[heads[6]] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq_mem[heads[0]] || (iq_agen[heads[0]] & iq_out[heads[0]]) || iq_done[heads[0]]
						|| ((iq_ma[heads[9]][AMSB:3] != iq_ma[heads[0]][AMSB:3] || iq_out[heads[0]] || iq_done[heads[0]])))
					&& (!iq_mem[heads[1]] || (iq_agen[heads[1]] & iq_out[heads[1]]) || iq_done[heads[1]]
						|| ((iq_ma[heads[9]][AMSB:3] != iq_ma[heads[1]][AMSB:3] || iq_out[heads[1]] || iq_done[heads[1]])))
					&& (!iq_mem[heads[2]] || (iq_agen[heads[2]] & iq_out[heads[2]]) || iq_done[heads[2]] 
						|| ((iq_ma[heads[9]][AMSB:3] != iq_ma[heads[2]][AMSB:3] || iq_out[heads[2]] || iq_done[heads[2]])))
					&& (!iq_mem[heads[3]] || (iq_agen[heads[3]] & iq_out[heads[3]]) || iq_done[heads[3]] 
						|| ((iq_ma[heads[9]][AMSB:3] != iq_ma[heads[3]][AMSB:3] || iq_out[heads[3]] || iq_done[heads[3]])))
					&& (!iq_mem[heads[4]] || (iq_agen[heads[4]] & iq_out[heads[4]]) || iq_done[heads[4]] 
						|| ((iq_ma[heads[9]][AMSB:3] != iq_ma[heads[4]][AMSB:3] || iq_out[heads[4]] || iq_done[heads[4]])))
					&& (!iq_mem[heads[5]] || (iq_agen[heads[5]] & iq_out[heads[5]]) || iq_done[heads[5]] 
						|| ((iq_ma[heads[9]][AMSB:3] != iq_ma[heads[5]][AMSB:3] || iq_out[heads[5]] || iq_done[heads[5]])))
					&& (!iq_mem[heads[6]] || (iq_agen[heads[6]] & iq_out[heads[6]]) || iq_done[heads[6]] 
						|| ((iq_ma[heads[9]][AMSB:3] != iq_ma[heads[6]][AMSB:3] || iq_out[heads[6]] || iq_done[heads[6]])))
					&& (!iq_mem[heads[7]] || (iq_agen[heads[7]] & iq_out[heads[7]]) || iq_done[heads[7]] 
						|| ((iq_ma[heads[9]][AMSB:3] != iq_ma[heads[7]][AMSB:3] || iq_out[heads[7]] || iq_done[heads[7]])))
					&& (!iq_mem[heads[8]] || (iq_agen[heads[8]] & iq_out[heads[8]]) || iq_done[heads[8]] 
						|| ((iq_ma[heads[9]][AMSB:3] != iq_ma[heads[8]][AMSB:3] || iq_out[heads[8]] || iq_done[heads[8]])))
					&& (iq_rl[heads[9]] ? (iq_done[heads[0]] || !iq_v[heads[0]] || !iq_mem[heads[0]])
										 && (iq_done[heads[1]] || !iq_v[heads[1]] || !iq_mem[heads[1]])
										 && (iq_done[heads[2]] || !iq_v[heads[2]] || !iq_mem[heads[2]])
										 && (iq_done[heads[3]] || !iq_v[heads[3]] || !iq_mem[heads[3]])
										 && (iq_done[heads[4]] || !iq_v[heads[4]] || !iq_mem[heads[4]])
										 && (iq_done[heads[5]] || !iq_v[heads[5]] || !iq_mem[heads[5]])
										 && (iq_done[heads[6]] || !iq_v[heads[6]] || !iq_mem[heads[6]])
										 && (iq_done[heads[7]] || !iq_v[heads[7]] || !iq_mem[heads[7]])
										 && (iq_done[heads[8]] || !iq_v[heads[8]] || !iq_mem[heads[8]])
											 : 1'b1)
					// ... if a preivous op has the aquire bit set
					&& !(iq_aq[heads[0]] && iq_v[heads[0]])
					&& !(iq_aq[heads[1]] && iq_v[heads[1]])
					&& !(iq_aq[heads[2]] && iq_v[heads[2]])
					&& !(iq_aq[heads[3]] && iq_v[heads[3]])
					&& !(iq_aq[heads[4]] && iq_v[heads[4]])
					&& !(iq_aq[heads[5]] && iq_v[heads[5]])
					&& !(iq_aq[heads[6]] && iq_v[heads[6]])
					&& !(iq_aq[heads[7]] && iq_v[heads[7]])
					&& !(iq_aq[heads[8]] && iq_v[heads[8]])
					// ... and there's nothing in the write buffer during a load
					&& !(iq_load[heads[9]] && (wb_v!=1'b0
						|| iq_store[heads[0]] || iq_store[heads[1]] || iq_store[heads[2]] || iq_store[heads[3]]
						|| iq_store[heads[4]] || iq_store[heads[5]] || iq_store[heads[6]] || iq_store[heads[7]]
						|| iq_store[heads[8]]))
					// ... and there isn't a barrier, or everything before the barrier is done or invalid
                    && (!(iq_iv[heads[1]] && iq_memsb[heads[1]]) || (iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memsb[heads[2]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]]))
                    		)
                    && (!(iq_iv[heads[3]] && iq_memsb[heads[3]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]]))
                    		)
                    && (!(iq_iv[heads[4]] && iq_memsb[heads[4]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]]))
                    		)
                    && (!(iq_iv[heads[5]] && iq_memsb[heads[5]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]]))
                    		)
                    && (!(iq_iv[heads[6]] && iq_memsb[heads[6]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]])
                    		&&   (iq_done[heads[5]] || !iq_v[heads[5]]))
                    		)
                    && (!(iq_iv[heads[7]] && iq_memsb[heads[7]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]])
                    		&&   (iq_done[heads[5]] || !iq_v[heads[5]])
                    		&&   (iq_done[heads[6]] || !iq_v[heads[6]]))
                    		)
                    && (!(iq_iv[heads[8]] && iq_memsb[heads[8]]) ||
                    			((iq_done[heads[0]] || !iq_v[heads[0]])
                    		&&   (iq_done[heads[1]] || !iq_v[heads[1]])
                    		&&   (iq_done[heads[2]] || !iq_v[heads[2]])
                    		&&   (iq_done[heads[3]] || !iq_v[heads[3]])
                    		&&   (iq_done[heads[4]] || !iq_v[heads[4]])
                    		&&   (iq_done[heads[5]] || !iq_v[heads[5]])
                    		&&   (iq_done[heads[6]] || !iq_v[heads[6]])
                    		&&   (iq_done[heads[7]] || !iq_v[heads[7]])
                    		)
                    		)
    				&& (!(iq_iv[heads[1]] && iq_memdb[heads[1]]) || (!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]]))
                    && (!(iq_iv[heads[2]] && iq_memdb[heads[2]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]]))
                     		)
                    && (!(iq_iv[heads[3]] && iq_memdb[heads[3]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]]))
                     		)
                    && (!(iq_iv[heads[4]] && iq_memdb[heads[4]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]]))
                     		)
                    && (!(iq_iv[heads[5]] && iq_memdb[heads[5]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]]))
                     		)
                    && (!(iq_iv[heads[6]] && iq_memdb[heads[6]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]])
                     		&& (!iq_mem[heads[5]] || iq_done[heads[5]] || !iq_v[heads[5]]))
                     		)
                    && (!(iq_iv[heads[7]] && iq_memdb[heads[7]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]])
                     		&& (!iq_mem[heads[5]] || iq_done[heads[5]] || !iq_v[heads[5]])
                     		&& (!iq_mem[heads[6]] || iq_done[heads[6]] || !iq_v[heads[6]]))
                     		)
                    && (!(iq_iv[heads[8]] && iq_memdb[heads[8]]) ||
                     		  ((!iq_mem[heads[0]] || iq_done[heads[0]] || !iq_v[heads[0]])
                     		&& (!iq_mem[heads[1]] || iq_done[heads[1]] || !iq_v[heads[1]])
                     		&& (!iq_mem[heads[2]] || iq_done[heads[2]] || !iq_v[heads[2]])
                     		&& (!iq_mem[heads[3]] || iq_done[heads[3]] || !iq_v[heads[3]])
                     		&& (!iq_mem[heads[4]] || iq_done[heads[4]] || !iq_v[heads[4]])
                     		&& (!iq_mem[heads[5]] || iq_done[heads[5]] || !iq_v[heads[5]])
                     		&& (!iq_mem[heads[6]] || iq_done[heads[6]] || !iq_v[heads[6]])
                     		&& (!iq_mem[heads[7]] || iq_done[heads[7]] || !iq_v[heads[7]])
                     		)
                     		)
					// ... and, if it is a store, there is no chance of it being undone
					&& ((iq_load[heads[9]] && sple) ||
		      		      !(iq_fc[heads[0]]||iq_canex[heads[0]])
                       && !(iq_fc[heads[1]]||iq_canex[heads[1]])
                       && !(iq_fc[heads[2]]||iq_canex[heads[2]])
                       && !(iq_fc[heads[3]]||iq_canex[heads[3]])
                       && !(iq_fc[heads[4]]||iq_canex[heads[4]])
                       && !(iq_fc[heads[5]]||iq_canex[heads[5]])
                       && !(iq_fc[heads[6]]||iq_canex[heads[6]])
                       && !(iq_fc[heads[7]]||iq_canex[heads[7]])
                       && !(iq_fc[heads[8]]||iq_canex[heads[8]])
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
	for (n = 0; n < QENTRIES; n = n + 1)
    if (~iq_stomp[heads[n]] && iq_memissue[heads[n]] && !iq_done[heads[n]] && iq_v[heads[n]]) begin
      if (mem1_available && dram0 == `DRAMSLOT_AVAIL) begin
       last_issue0 = heads[n];
      end
    end
	for (n = 0; n < QENTRIES; n = n + 1)
    if (~iq_stomp[heads[n]] && iq_memissue[heads[n]]) begin
    	if (mem2_available && heads[n] != last_issue0 && `NUM_MEM > 1) begin
        if (dram1 == `DRAMSLOT_AVAIL) begin
					last_issue1 = heads[n];
        end
    	end
    end
end

always @*
begin
	iq_stomp <= 1'b0;
	if (branchmiss) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (iq_v[n]) begin
				if (iq_sn[n] > iq_sn[missid[`QBITS]])
					iq_stomp[n] <= `TRUE;
			end
		end
	end
end

always @*
begin
	stompedOnRets = 1'b0;
	for (n = 0; n < QENTRIES; n = n + 1)
		if (iq_stomp[n] && iq_ret[n])
			stompedOnRets = stompedOnRets + 4'd1;
end

wire [143:0] id0_bus, id1_bus, id2_bus;

idecoder uid1
(
	.instr(insn0),
	.Rt(Rd0[5:0]),
	.predict_taken(predict_taken0),
	.bus(id1_bus),
	.debug_on(debug_on)
);

idecoder uid2
(
	.instr(insn1),
	.Rt(Rd1[5:0]),
	.predict_taken(predict_taken1),
	.bus(id2_bus),
	.debug_on(debug_on)
);

idecoder uid3
(
	.instr(insn2),
	.Rt(Rd2[5:0]),
	.predict_taken(predict_taken2),
	.bus(id3_bus),
	.debug_on(debug_on)
);

//
// EXECUTE
//
wire [15:0] lfsro;
lfsr #(16,16'hACE4) u1 (rst_i, clk_i, 1'b1, 1'b0, lfsro);

reg [63:0] csr_r;
wire [11:0] csrno = alu0_instr[29:18];
always @*
begin
    if (csrno[11:10] >= ol)
    casez(csrno[9:0])
    `CSR_CR0:       csr_r <= cr0;
    `CSR_HARTID:    csr_r <= hartid_i;
    `CSR_TICK:      csr_r <= tick;
    `CSR_PCR:       csr_r <= pcr;
    `CSR_PCR2:      csr_r <= pcr2;
    `CSR_PMR:				csr_r <= pmr;
//    `CSR_WBRCD:		csr_r <= wbrcd;
    `CSR_SEMA:      csr_r <= sema;
    `CSR_KEYS:			csr_r <= keys;
    `CSR_TCB:		csr_r <= tcb;
    `CSR_FSTAT:     csr_r <= {fp_rgs,fp_status};
`ifdef SUPPORT_DBG    
    `CSR_DBAD0:     csr_r <= dbg_adr0;
    `CSR_DBAD1:     csr_r <= dbg_adr1;
    `CSR_DBAD2:     csr_r <= dbg_adr2;
    `CSR_DBAD3:     csr_r <= dbg_adr3;
    `CSR_DBCTRL:    csr_r <= dbg_ctrl;
    `CSR_DBSTAT:    csr_r <= dbg_stat;
`endif   
    `CSR_CAS:       csr_r <= cas;
    `CSR_TVEC:      csr_r <= tvec[csrno[2:0]];
    `CSR_BADADR:    csr_r <= badaddr[{csrno[11:10]}];
    `CSR_BADINSTR:	csr_r <= bad_instr[{csrno[11:10]}];
    `CSR_CAUSE:     csr_r <= {48'd0,cause[{csrno[11:10]}]};
    `CSR_ODL_STACK:	csr_r <= {16'h0,dl_stack,16'h0,ol_stack};
    `CSR_IM_STACK:	csr_r <= im_stack;
    `CSR_PL_STACK:	csr_r <= pl_stack;
    `CSR_RS_STACK:	csr_r <= rs_stack;
    `CSR_STATUS:    csr_r <= mstatus[63:0];
    `CSR_BRS_STACK:	csr_r <= brs_stack;
    `CSR_EPC0:      csr_r <= epc0;
    `CSR_EPC1:      csr_r <= epc1;
    `CSR_EPC2:      csr_r <= epc2;
    `CSR_EPC3:      csr_r <= epc3;
    `CSR_EPC4:      csr_r <= epc4;
    `CSR_EPC5:      csr_r <= epc5;
    `CSR_EPC6:      csr_r <= epc6;
    `CSR_EPC7:      csr_r <= epc7;
    `CSR_CODEBUF:   csr_r <= codebuf[csrno[5:0]];
`ifdef SUPPORT_BBMS
		`CSR_TB:			csr_r <= tb;
		`CSR_CBL:			csr_r <= cbl;
		`CSR_CBU:			csr_r <= cbu;
		`CSR_RO:			csr_r <= ro;
		`CSR_DBL:			csr_r <= dbl;
		`CSR_DBU:			csr_r <= dbu;
		`CSR_SBL:			csr_r <= sbl;
		`CSR_SBU:			csr_r <= sbu;
		`CSR_ENU:			csr_r <= en;
`endif
    `CSR_Q_CTR:		csr_r <= iq_ctr;
    `CSR_BM_CTR:	csr_r <= bm_ctr;
    `CSR_ICL_CTR:	csr_r <= icl_ctr;
    `CSR_IRQ_CTR:	csr_r <= irq_ctr;
    `CSR_TIME:		csr_r <= wc_times;
    `CSR_INFO:
                    case(csrno[3:0])
                    4'd0:   csr_r <= "Finitron";  // manufacturer
                    4'd1:   csr_r <= "        ";
                    4'd2:   csr_r <= "64 bit  ";  // CPU class
                    4'd3:   csr_r <= "        ";
                    4'd4:   csr_r <= "FT64    ";  // Name
                    4'd5:   csr_r <= "        ";
                    4'd6:   csr_r <= 64'd1;       // model #
                    4'd7:   csr_r <= 64'd1;       // serial number
                    4'd8:   csr_r <= {32'd16384,32'd16384};   // cache sizes instruction,csr_ra
                    4'd9:   csr_r <= 64'd0;
                    default:    csr_r <= 64'd0;
                    endcase
    default:    begin    
    			$display("Unsupported CSR:%h",csrno[10:0]);
    			csr_r <= 64'hEEEEEEEEEEEEEEEE;
    			end
    endcase
    else
        csr_r <= 64'h0;
end

reg [79:0] alu0_xu = 1'd0, alu1_xu = 1'd0;

`ifdef SUPPORT_BBMS

`else
// This always block didn't work, it left the signals as X's.
// So they are set to zero where the reg declaration is.
// I'm guessing the @* says there's no variables on the right
// hand side, so I'm not going to evaluate it.
always @*
	alu0_xs <= 64'd0;
always @*
	alu1_xs <= 64'd0;
`endif

wire alu_clk = clk;
//BUFH uclka (.I(clk), .O(alu_clk));

//always @*
//    read_csr(alu0_instr[29:18],csr_r,alu0_thrd);
alu #(.BIG(1'b1),.SUP_VECTOR(1'b0)) ualu0 (
  .rst(rst_i),
  .clk(alu_clk),
  .ld(alu0_ld),
  .abort(alu0_abort),
  .instr(alu0_instr),
  .sz(alu0_sz),
  .store(alu0_store),
  .a(alu0_argA),
  .b(alu0_argB),
  .c(alu0_argC),
  .pc(alu0_ip),
//    .imm(alu0_argI),
  .tgt(alu0_tgt),
  .csr(csr_r),
  .o(alu0_out),
  .ob(alu0b_bus),
  .done(alu0_done),
  .idle(alu0_idle),
  .excen(aec[4:0]),
  .exc(alu0_exc),
  .mem(alu0_mem),
  .shift(alu0_shft),	// 48 bit shift inst.
  .ol(ol)
`ifdef SUPPORT_BBMS
  , .pb(dl==2'b00 ? 64'd0 : pb),
  .cbl(cbl),
  .cbu(cbu),
  .ro(ro),
  .dbl(dbl),
  .dbu(dbu),
  .sbl(sbl),
  .sbu(sbu),
  .en(en)
`endif
);
generate begin : gAluInst
if (`NUM_ALU > 1) begin
alu #(.BIG(1'b0),.SUP_VECTOR(1'b0)) ualu1 (
  .rst(rst_i),
  .clk(clk),
  .ld(alu1_ld),
  .abort(alu1_abort),
  .instr(alu1_instr),
  .sz(alu1_sz),
  .store(alu1_store),
  .a(alu1_argA),
  .b(alu1_argB),
  .c(alu1_argC),
  .pc(alu1_ip),
  //.imm(alu1_argI),
  .tgt(alu1_tgt),
  .csr(64'd0),
  .o(alu1_out),
  .ob(alu1b_bus),
  .done(alu1_done),
  .idle(alu1_idle),
  .excen(aec[4:0]),
  .exc(alu1_exc),
  .thrd(1'b0),
  .mem(alu1_mem),
  .shift(alu1_shft),
  .ol(2'b0)
`ifdef SUPPORT_BBMS
  , .pb(dl==2'b00 ? 64'd0 : pb),
  .cbl(cbl),
  .cbu(cbu),
  .ro(ro),
  .dbl(dbl),
  .dbu(dbu),
  .sbl(sbl),
  .sbu(sbu),
  .en(en)
`endif
);
end
end
endgenerate

wire tlb_done;
wire tlb_idle;
wire [63:0] tlbo;
wire uncached;
`ifdef SUPPORT_TLB
TLB utlb1 (
	.clk(clk),
	.ld(alu0_ld & alu0_tlb),
	.done(tlb_done),
	.idle(tlb_idle),
	.ol(ol),
	.ASID(ASID),
	.op(alu0_instr[34:31]),
	.regno(alu0_instr[19:16]),
	.dati(alu0_argA),
	.dato(tlbo),
	.uncached(uncached),
	.icl_i(icl_o),
	.cyc_i(cyc),
	.we_i(we),
	.vadr_i(vadr),
	.cyc_o(cyc_o),
	.we_o(we_o),
	.padr_o(adr_o),
	.TLBMiss(tlb_miss),
	.wrv_o(wrv_o),
	.rdv_o(rdv_o),
	.exv_o(exv_o),
	.HTLBVirtPageo()
);
`else
assign tlb_done = 1'b1;
assign tlb_idle = 1'b1;
assign tlbo = 64'hDEADDEADDEADDEAD;
assign uncached = 1'b0;
assign adr_o = vadr;
assign cyc_o = cyc;
assign we_o = we;
assign tlb_miss = 1'b0;
assign wrv_o = 1'b0;
assign rdv_o = 1'b0;
assign exv_o = 1'b0;
assign exv_i = 1'b0;	// for now
`endif

always @*
begin
    alu0_cmt <= 1'b1;
    alu1_cmt <= 1'b1;
    fpu1_cmt <= 1'b1;
    fpu2_cmt <= 1'b1;
    fcu_cmt <= 1'b1;

    alu0_bus <= alu0_out;
    alu1_bus <= alu1_out;
    fpu1_bus <= fpu1_out;
    fpu2_bus <= fpu2_out;
    fcu_bus <= fcu_out;
end

assign alu0_abort = 1'b0;
assign alu1_abort = 1'b0;

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
  .rst(rst_i),
  .clk(fpu1_clk),
  .clk4x(clk4x_i),
  .ce(1'b1),
  .ir(fpu1_instr),
  .ld(fpu1_ld),
  .a(fpu1_argA),
  .b(fpu1_argB),
  .imm(fpu1_argI),
  .o(fpu1_out),
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
  .rst(rst_i),
  .clk(fpu2_clk),
  .clk4x(clk4x_i),
  .ce(1'b1),
  .ir(fpu2_instr),
  .ld(fpu2_ld),
  .a(fpu2_argA),
  .b(fpu2_argB),
  .imm(fpu2_argI),
  .o(fpu2_out),
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

wire [1:0] olm = ol;

assign  fcu_v = fcu_dataready;
assign  fcu_id = fcu_sourceid;

wire [4:0] fcmpo;
wire fnanx;
fp_cmp_unit #(64) ufcmp1 (fcu_argA, fcu_argB, fcmpo, fnanx);

wire fcu_takb;

always @*
begin
    fcu_exc <= `FLT_NONE;
    casez(fcu_instr[`OPCODE4])
    `CHK:   begin
              fcu_exc <= fcu_argA >= fcu_argB && fcu_argA < fcu_argC ? `FLT_NONE : `FLT_CHK;
            end
    `REX:
        case(olm)
        `OL_USER:   fcu_exc <= `FLT_PRIV;
        default:    ;
        endcase
// Could have long branches exceptioning and unimplmented in the fetch stage.
//   `BBc:	fcu_exc <= fcu_instr[6] ? `FLT_BRN : `FLT_NONE;
   default: fcu_exc <= `FLT_NONE;
	endcase
end

EvalBranch ube1
(
	.instr(fcu_instr),
	.a(fcu_argA),
	.b(fcu_argB),
	.c(fcu_argC),
	.takb(fcu_takb)
);

FCU_Calc #(.AMSB(AMSB)) ufcuc1
(
	.ol(olm),
	.instr(fcu_instr),
	.tvec(tvec[fcu_instr[14:13]]),
	.a(fcu_argA),
	.pc(fcu_ip),
	.nextpc(fcu_nextip),
	.im(im),
	.waitctr(waitctr),
	.bus(fcu_out)
);

wire will_clear_branchmiss = branchmiss && (
															(slot0v && slot0ip==misspc)
															|| (slot1v && slot1ip==misspc)
															|| (slot2v && slot2ip==misspc)
															);

always @*
begin
case(fcu_instr[`OPCODE4])
`RTI:	fcu_misspc = fcu_epc;		// RTI (we don't bother fully decoding this as it's the only R2)
`RET:	fcu_misspc = fcu_argB;
`REX:	fcu_misspc = fcu_bus;
`BRK:	fcu_misspc = {tvec[0][AMSB:8], 1'b0, olm, 5'h0};
`JAL:	fcu_misspc = fcu_argA + fcu_argI;
`BRcc:	fcu_misspc = fcu_argC;
//`CHK:	fcu_misspc = fcu_nextpc + fcu_argI;	// Handled as an instruction exception
// Default: branch
default:	fcu_misspc = fcu_pt ? fcu_nextip : {fcu_ip[AMSB:32],fcu_ip[31:13] + fcu_brdisp[31:13],fcu_brdisp[12:0]};
endcase
fcu_misspc[0] = 1'b0;
end

// To avoid false branch mispredicts the branch isn't evaluated until the
// following instruction queues. The address of the next instruction is
// looked at to see if the BTB predicted correctly.

wire fcu_brk_miss = fcu_brk || fcu_rti;
`ifdef FCU_ENH
wire fcu_ret_miss = fcu_ret && (fcu_argB != iq_ip[nid]);
wire fcu_jal_miss = fcu_jal && (fcu_argA + fcu_argI != iq_ip[nid]);
wire fcu_followed = iq_sn[nid] > iq_sn[fcu_id[`QBITS]];
`else
wire fcu_ret_miss = fcu_ret;
wire fcu_jal_miss = fcu_jal;
wire fcu_followed = `TRUE;
`endif
always @*
if (fcu_v) begin
	// Break and RTI switch register sets, and so are always treated as a branch miss in order to
	// flush the pipeline. Hardware interrupts also stream break instructions so they need to 
	// flushed from the queue so the interrupt is recognized only once.
	// BRK and RTI are handled as excmiss types which are processed during the commit stage.
	if (fcu_brk_miss)
		fcu_branchmiss = TRUE;
	else if ((fcu_branch && (fcu_takb ^ fcu_pt)) || fcu_instr[`OPCODE4]==`BRcc)
    fcu_branchmiss = TRUE;
	else
		if (fcu_rex && (im < ~ol))
		fcu_branchmiss = TRUE;
	else if (fcu_ret_miss)
		fcu_branchmiss = TRUE;
	else if (fcu_jal_miss)
    fcu_branchmiss = TRUE;
	else if (fcu_chk && ~fcu_takb)
    fcu_branchmiss = TRUE;
	else
    fcu_branchmiss = FALSE;
end
else
	fcu_branchmiss = FALSE;

// Used during queuing to determine which instruction slots are valid to queue.
// Normally the ip is aligned at a bundle address, but a branch may branch into
// the middle of a bundle. We don't want earlier instructions in the bundle to
// execute if they are before the branch target.
reg [2:0] ip_mask;
always @*
case(ip[1:0])
2'b00:	ip_mask = 3'b111;
2'b01:	ip_mask = 3'b011;
2'b10:	ip_mask = 3'b001;
default:	ip_mask = 3'b111;
endcase

//
// additional DRAM-enqueue logic

assign dram_avail = (dram0 == `DRAMSLOT_AVAIL || dram1 == `DRAMSLOT_AVAIL);

always @*
for (n = 0; n < QENTRIES; n = n + 1)
	iq_memopsvalid[n] <= (iq_mem[n] && (iq_store[n] ? iq_argB_v[n] : 1'b1) && iq_state[n]==IQS_AGEN);

always @*
for (n = 0; n < QENTRIES; n = n + 1)
	iq_memready[n] <= (iq_v[n] & iq_iv[n] & iq_memopsvalid[n] & ~iq_memissue[n] & ~iq_stomp[n]);

assign outstanding_stores = (dram0 && dram0_store) ||
                            (dram1 && dram1_store);

//
// additional COMMIT logic
//
always @*
begin
    commit0_v <= (iq_state[heads[0]] == IQS_CMT && ~|panic);
    commit0_id <= {iq_mem[heads[0]], heads[0]};	// if a memory op, it has a DRAM-bus id
    commit0_tgt <= iq_tgt[heads[0]];
    commit0_bus <= iq_res[heads[0]];
    if (`NUM_CMT > 1) begin
	    commit1_v <= ({iq_v[heads[0]],  iq_state[heads[0]] == IQS_CMT} != 2'b10
	               && iq_state[heads[1]] == IQS_CMT
	               && ~|panic);
	    commit1_id <= {iq_mem[heads[1]], heads[1]};
	    commit1_tgt <= iq_tgt[heads[1]];  
	    commit1_bus <= iq_res[heads[1]];
	    // Need to set commit1, and commit2 valid bits for the branch predictor.
	    if (`NUM_CMT > 2) begin
	  	end
	  	else begin
	  		commit2_v <= ({iq_v[heads[0]], iq_state[heads[0]] == IQS_CMT} != 2'b10
	  							 && {iq_v[heads[1]], iq_state[heads[1]] == IQS_CMT} != 2'b10
	  							 && {iq_v[heads[2]], iq_br[heads[2]], iq_state[heads[2]] == IQS_CMT}==3'b111
		               && iq_tgt[heads[2]][4:0]==5'd0 && ~|panic);	// watch out for dbnz and ibne
	  		commit2_tgt <= 12'h000;
	  	end
  	end
  	else begin
  		commit1_v <= ({iq_v[heads[0]], iq_state[heads[0]] == IQS_CMT} != 2'b10
  							 && {iq_v[heads[1]], iq_state[heads[1]] == IQS_CMT} == 2'b11
	               && !iq_rfw[heads[1]] && ~|panic);	// watch out for dbnz and ibne
    	commit1_id <= {iq_mem[heads[1]], heads[1]};	// if a memory op, it has a DRAM-bus id
  		commit1_tgt <= 12'h000;
  		// We don't really need the bus value since nothing is being written.
	    commit1_bus <= iq_res[heads[1]];
  		commit2_v <= ({iq_v[heads[0]], iq_state[heads[0]] == IQS_CMT} != 2'b10
  							 && {iq_v[heads[1]], iq_state[heads[1]] == IQS_CMT} != 2'b10
  							 && {iq_v[heads[2]], iq_br[heads[2]], iq_state[heads[2]] == IQS_CMT}==3'b111
	               && !iq_rfw[heads[2]] && ~|panic);	// watch out for dbnz and ibne
    	commit2_id <= {iq_mem[heads[2]], heads[2]};	// if a memory op, it has a DRAM-bus id
  		commit2_tgt <= 12'h000;
	    commit2_bus <= iq_res[heads[2]];
  	end
end
    
assign int_commit = (commit0_v && iq_irq[heads[0]])
									 || (commit0_v && commit1_v && iq_irq[heads[1]] && `NUM_CMT > 1)
									 || (commit0_v && commit1_v && commit2_v && iq_irq[heads[2]] && `NUM_CMT > 2);

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
     			regIsValid[n] = `VAL;
       end
		if (commit0_v && n=={commit0_tgt[5:0]})
			regIsValid[n] = regIsValid[n] | ((rf_source[ {commit0_tgt[5:0]} ] == commit0_id)
			|| (branchmiss && iq_source[ commit0_id[`QBITS] ]));
		if (commit1_v && n=={commit1_tgt[5:0]} && `NUM_CMT > 1)
			regIsValid[n] = regIsValid[n] | ((rf_source[ {commit1_tgt[5:0]} ] == commit1_id)
			|| (branchmiss && iq_source[ commit1_id[`QBITS] ]));
		if (commit2_v && n=={commit2_tgt[5:0]} && `NUM_CMT > 2)
			regIsValid[n] = regIsValid[n] | ((rf_source[ {commit2_tgt[5:0]} ] == commit2_id)
			|| (branchmiss && iq_source[ commit2_id[`QBITS] ]));
	end
	regIsValid[0] = `VAL;
end

// Wait until the cycle after Ra becomes valid to give time to read
// the vector element from the register file.
reg rf_vra0, rf_vra1, rf_vra2;
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
wire q2open = iq_v[tail0]==`INV && iq_v[tail1]==`INV;
wire q3open = iq_v[tail0]==`INV && iq_v[tail1]==`INV && iq_v[(tail1 + 2'd1) % QENTRIES]==`INV;
always @*
begin
	canq1 <= FALSE;
	canq2 <= FALSE;
	canq3 <= FALSE;
	queued1 <= FALSE;
	queued2 <= FALSE;
	queued3 <= FALSE;
	queuedNop <= FALSE;
	if (!branchmiss) begin
		// Three available
		case({slot0v,slot1v,slot2v})
		3'b000:	;
		3'b001,3'b010,3'b100:
      if (iq_v[tail0]==`INV) begin
        canq1 <= TRUE;
        queued1 <= TRUE;
      end
    3'b011:
    	begin
        if (iq_v[tail0]==`INV) begin
          canq1 <= TRUE;
          queued1 <= TRUE;
        end
        if (!take_branch1) begin
          if (iq_v[tail1]==`INV) begin
            canq2 <= TRUE;
            queued2 <= TRUE;
          end
      	end
	    end
    3'b101:
    	begin
        if (iq_v[tail0]==`INV) begin
          canq1 <= TRUE;
          queued1 <= TRUE;
        end
        if (!take_branch0) begin
          if (iq_v[tail1]==`INV) begin
            canq2 <= TRUE;
            queued2 <= TRUE;
          end
      	end
	    end
	  3'b110:
    	begin
        if (iq_v[tail0]==`INV) begin
          canq1 <= TRUE;
          queued1 <= TRUE;
        end
        if (!take_branch0) begin
          if (iq_v[tail1]==`INV) begin
            canq2 <= TRUE;
            queued2 <= TRUE;
          end
      	end
	    end
		3'b111:
			begin
				if (IsNop(Unit0(ibundle[127:120]),ibundle[119:80])
					&& IsNop(Unit1(ibundle[127:120]),ibundle[79:40])
					&& IsNop(Unit2(ibundle[127:120]),ibundle[79:40]))
					queuedNop <= TRUE;
				else begin
	        if (iq_v[tail0]==`INV) begin
	          canq1 <= TRUE;
	          queued1 <= TRUE;
	        end
					if (!take_branch0) begin
	          if (iq_v[tail1]==`INV) begin
	            canq2 <= TRUE;
	            queued2 <= TRUE;
	          end
	          if (!take_branch1) begin
	            if (iq_v[tail2]==`INV) begin
	              canq3 <= TRUE;
	              queued3 <= TRUE;
	            end
		        end
					end
				end
			end
		endcase
  end
end

//
// Branchmiss seems to be sticky sometimes during simulation. For instance branch miss
// and cache miss at same time. The branchmiss should clear before the core continues
// so the positive edge is detected to avoid incrementing the sequnce number too many
// times.
wire pebm;
edge_det uedbm (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(branchmiss), .pe(pebm), .ne(), .ee() );

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
	 		(mem1_available && dram0==`DRAMSLOT_BUSY && dram0_store && wb_ptr<`WB_DEPTH-1)
	 || (mem2_available && dram1==`DRAMSLOT_BUSY && dram1_store && `NUM_MEM > 1 && wb_ptr<`WB_DEPTH-1)
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
//    missid <= excmiss ? (|iq_exc[heads[0]] ? heads[0] : heads[1]) : fcu_sourceid;
//	branchmiss_thrd <=  excmiss ? excthrd : fcu_thrd;
//end
wire alu0_done_pe, alu1_done_pe, pe_wait;
edge_det uedalu0d (.clk(clk), .ce(1'b1), .i(alu0_done&tlb_done), .pe(alu0_done_pe), .ne(), .ee());
edge_det uedalu1d (.clk(clk), .ce(1'b1), .i(alu1_done), .pe(alu1_done_pe), .ne(), .ee());
edge_det uedwait1 (.clk(clk), .ce(1'b1), .i((waitctr==48'd1) || signal_i[fcu_argA[4:0]|fcu_argI[4:0]]), .pe(pe_wait), .ne(), .ee());

// Bus randomization to mitigate meltdown attacks
wire [WID-1:0] ralu0_bus = |alu0_exc ? {5{lfsro}} : alu0_tlb ? tlbo : alu0_bus;
wire [WID-1:0] ralu1_bus = |alu1_exc ? {5{lfsro}} : alu1_bus;
wire [WID-1:0] rfpu1_bus = |fpu1_exc ? {5{lfsro}} : fpu1_bus;
wire [WID-1:0] rfpu2_bus = |fpu2_exc ? {5{lfsro}} : fpu2_bus;
wire [WID-1:0] rfcu_bus  = |fcu_exc  ? {5{lfsro}} : fcu_bus;
wire [WID-1:0] rdramA_bus = dramA_bus;
wire [WID-1:0] rdramB_bus = dramB_bus;

always @(posedge clk)
begin
	if (icyc) begin
		cti_o <= icti;
		bte_o <= ibte;
		cyc <= icyc;
		stb_o <= istb;
		we <= 1'b0;
		sel_o <= isel;
		vadr <= iadr;
	end
	else if (wb_has_bus) begin
		cti_o <= 3'b000;
		bte_o <= 2'b00;
		cyc <= wcyc;
		stb_o <= wstb;
		we <= wwe;
		sel_o <= wsel;
		vadr <= wadr;
		dat_o <= wdat;
	end
	else begin
		cti_o <= 3'b000;
		bte_o <= 2'b00;
		cyc <= dcyc;
		stb_o <= dstb;
		we <= dwe;
		sel_o <= dsel;
		vadr <= dadr;
		dat_o <= ddat;
	end
end

// Hold reset for five seconds
reg [31:0] rst_ctr;
always @(posedge clk)
if (rst_i)
	rst_ctr <= 32'd0;
else begin
	if (rst_ctr < 32'd10)
		rst_ctr <= rst_ctr + 24'd1;
end

always @(posedge clk)
if (rst_i|(rst_ctr < 32'd10)) begin
	im_stack <= 32'hFFFFFFFF;
	mstatus <= 64'h4000F;	// select register set #16 for thread 0
	rs_stack <= 64'd16;
	brs_stack <= 64'd16;
    for (n = 0; n < QENTRIES; n = n + 1) begin
    	iq_state[n] <= IQS_INVALID;
       iq_is[n] <= 3'b00;
       iq_sn[n] <= 4'd0;
       iq_pt[n] <= FALSE;
       iq_bt[n] <= FALSE;
       iq_br[n] <= FALSE;
       iq_aq[n] <= FALSE;
       iq_rl[n] <= FALSE;
       iq_alu[n] <= FALSE;
       iq_fpu[n] <= FALSE;
       iq_fsync[n] <= FALSE;
       iq_fc[n] <= FALSE;
       iq_takb[n] <= FALSE;
       iq_jmp[n] <= FALSE;
       iq_jal[n] <= FALSE;
       iq_ret[n] <= FALSE;
       iq_rex[n] <= FALSE;
       iq_chk[n] <= FALSE;
       iq_brk[n] <= FALSE;
       iq_irq[n] <= FALSE;
       iq_rti[n] <= FALSE;
       iq_ldcmp[n] <= FALSE;
       iq_load[n] <= FALSE;
       iq_rtop[n] <= FALSE;
       iq_sei[n] <= FALSE;
       iq_shft[n] <= FALSE;
       iq_sync[n] <= FALSE;
       iq_rfw[n] <= FALSE;
       iq_rmw[n] <= FALSE;
       iq_ip[n] <= RSTPC;
    	 iq_instr[n] <= `NOP_INSN;
    	 iq_preload[n] <= FALSE;
    	 iq_mem[n] <= FALSE;
    	 iq_memndx[n] <= FALSE;
       iq_memissue[n] <= FALSE;
       iq_mem_islot[n] <= 3'd0;
       iq_memdb[n] <= FALSE;
       iq_memsb[n] <= FALSE;
       iq_tgt[n] <= 6'd0;
       iq_imm[n] <= 1'b0;
       iq_ma[n] <= 1'b0;
       iq_argI[n] <= 64'd0;
       iq_argA[n] <= 64'd0;
       iq_argB[n] <= 64'd0;
       iq_argC[n] <= 64'd0;
       iq_argA_v[n] <= `INV;
       iq_argB_v[n] <= `INV;
       iq_argC_v[n] <= `INV;
       iq_argA_s[n] <= 5'd0;
       iq_argB_s[n] <= 5'd0;
       iq_argC_s[n] <= 5'd0;
       iq_canex[n] <= FALSE;
    end
     bwhich <= 2'b00;
     dram0 <= `DRAMSLOT_AVAIL;
     dram1 <= `DRAMSLOT_AVAIL;
     dram0_instr <= `NOP_INSN;
     dram1_instr <= `NOP_INSN;
     dram0_addr <= 32'h0;
     dram1_addr <= 32'h0;
     dram0_id <= 1'b0;
     dram1_id <= 1'b0;
     dram0_store <= 1'b0;
     dram1_store <= 1'b0;
     invic <= FALSE;
     invicl <= FALSE;
     tail0 <= 3'd0;
     tail1 <= 3'd1;
     tail2 <= 3'd2;
     for (n = 0; n < QENTRIES; n = n + 1)
     	heads[n] <= n;
     panic = `PANIC_NONE;
     alu0_dataready <= 1'b0;
     alu1_dataready <= 1'b0;
     alu0_sourceid <= 5'd0;
     alu1_sourceid <= 5'd0;
`define SIM_
`ifdef SIM_
		alu0_ip <= RSTPC;
		alu0_instr <= `NOP_INSN;
		alu0_argA <= 64'h0;
		alu0_argB <= 64'h0;
		alu0_argC <= 64'h0;
		alu0_argI <= 64'h0;
		alu0_mem <= 1'b0;
		alu0_shft <= 1'b0;
		alu0_tgt <= 6'h00;
		alu1_ip <= RSTPC;
		alu1_instr <= `NOP_INSN;
		alu1_argA <= 64'h0;
		alu1_argB <= 64'h0;
		alu1_argC <= 64'h0;
		alu1_argI <= 64'h0;
		alu1_mem <= 1'b0;
		alu1_shft <= 1'b0;
		alu1_tgt <= 6'h00;
`endif
     fcu_dataready <= 0;
     fcu_instr <= `NOP_INSN;
     fcu_call <= 1'b0;
     dramA_v <= 0;
     dramB_v <= 0;
     I <= 0;
     CC <= 0;
     bstate <= BIDLE;
     tick <= 64'd0;
     ol_o <= 2'b0;
     bte_o <= 2'b00;
     cti_o <= 3'b000;
     cyc <= `LOW;
     cyc_pending <= `LOW;
     stb_o <= `LOW;
     we <= `LOW;
     sel_o <= 8'h00;
     dat_o <= 64'hFFFFFFFFFFFFFFFF;
     sr_o <= `LOW;
     cr_o <= `LOW;
     vadr <= RSTPC;
     cr0 <= 64'd0;
     cr0[13:8] <= 6'd0;		// select compressed instruction group #0
     cr0[30] <= TRUE;    	// enable data caching
     cr0[32] <= TRUE;    	// enable branch predictor
     cr0[16] <= 1'b0;		// disable SMT
     cr0[17] <= 1'b0;		// sequence number reset = 1
     cr0[34] <= FALSE;	// write buffer merging enable
     cr0[35] <= TRUE;		// load speculation enable
     pcr <= 32'd0;
     pcr2 <= 64'd0;
    for (n = 0; n < AREGS; n = n + 1) begin
      rf_v[n] <= `VAL;
      rf_source[n] <= {`QBIT{1'b1}};
    end
     fp_rm <= 3'd0;			// round nearest even - default rounding mode
     fpu_csr[37:32] <= 5'd31;	// register set #31
     waitctr <= 48'd0;
    for (n = 0; n < 16; n = n + 1) begin
      badaddr[n] <= 64'd0;
      bad_instr[n] <= `NOP_INSN;
    end
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
     pmr[32] <= `FCU_AVAIL;
     wb_en <= `TRUE;
		iq_ctr <= 40'd0;
		bm_ctr <= 40'd0;
		br_ctr <= 40'd0;
		irq_ctr <= 40'd0;
		cmt_timer <= 9'd0;
		StoreAck1 <= `FALSE;
		keys <= 64'h0;
`ifdef SUPPORT_DBG
		dbg_ctrl <= 64'h0;
`endif
/* Initialized with initial begin above
`ifdef SUPPORT_BBMS		
		for (n = 0; n < 64; n = n + 1) begin
			thrd_handle[n] <= 16'h0;
			prg_base[n] <= 64'h0;
			cl_barrier[n] <= 64'h0;
			cu_barrier[n] <= 64'hFFFFFFFFFFFFFFFF;
			ro_barrier[n] <= 64'h0;
			dl_barrier[n] <= 64'h0;
			du_barrier[n] <= 64'hFFFFFFFFFFFFFFFF;
			sl_barrier[n] <= 64'h0;
			su_barrier[n] <= 64'hFFFFFFFFFFFFFFFF;
		end
`endif
*/
end
else begin

	if (|fb_panic)
		panic <= fb_panic;

	// Only one branchmiss is allowed to be processed at a time. If a second 
	// branchmiss occurs while the first is being processed, it would have
	// to of occurred as a speculation in the branch shadow of the first.
	// The second instruction would be stomped on by the first branchmiss so
	// there is no need to process it.
	// The branchmiss has to be latched, then cleared later as there could
	// be a cache miss at the same time meaning the switch to the new pc
	// does not take place immediately.
	if (!branchmiss) begin
		if (excmiss) begin
			branchmiss <= `TRUE;
			misspc <= excmisspc;
			missid <= (|iq_exc[heads[0]] ? heads[0] : |iq_exc[heads[1]] ? heads[1] : heads[2]);
		end
		else if (fcu_branchmiss) begin
			branchmiss <= `TRUE;
			misspc <= fcu_misspc;
			missid <= fcu_sourceid;
		end
	end
	// Clear a branch miss when target instruction is fetched.
	if (will_clear_branchmiss) begin
		branchmiss <= `FALSE;
	end

	// The following signals only pulse

	// Instruction decode output should only pulse once for a queue entry. We
	// want the decode to be invalidated after a clock cycle so that it isn't
	// inadvertently used to update the queue at a later point.
	dramA_v <= `INV;
	dramB_v <= `INV;
	ld_time <= {ld_time[4:0],1'b0};
	wc_times <= wc_time;
     rf_vra0 <= regIsValid[Ra0];
     rf_vra1 <= regIsValid[Ra1];
     rf_vra2 <= regIsValid[Ra2];

	excmiss <= FALSE;
	invic <= FALSE;
	if (L1_invline)
		invicl <= FALSE;
	tick <= tick + 64'd1;
	alu0_ld <= FALSE;
	alu1_ld <= FALSE;
	fpu1_ld <= FALSE;
	fpu2_ld <= FALSE;
	fcu_ld <= FALSE;
	cr0[17] <= 1'b0;

  if (waitctr != 48'd0)
		waitctr <= waitctr - 4'd1;

  if (iq_fc[fcu_id[`QBITS]] && iq_v[fcu_id[`QBITS]] && !iq_done[fcu_id[`QBITS]] && iq_out[fcu_id[`QBITS]])
  	fcu_timeout <= fcu_timeout + 8'd1;

	if (branchmiss) begin
        for (n = 1; n < AREGS; n = n + 1)
           if (~livetarget[n]) begin
           		rf_v[n] <= `VAL;
           end
			for (n = 0; n < QENTRIES; n = n + 1)
	    	if (|iq_latestID[n])
	    		rf_source[ {iq_tgt[n][5:0]} ] <= { 1'b0, iq_mem[n], n[`QBITS] };
    end

    // The source for the register file data might have changed since it was
    // placed on the commit bus. So it's needed to check that the source is
    // still as expected to validate the register.
		if (commit0_v) begin
      if (!rf_v[ {commit0_tgt[RBIT:0]} ]) begin
//         rf_v[ {commit0_tgt[7:0]} ] <= rf_source[ commit0_tgt[7:0] ] == commit0_id || (branchmiss && iq_source[ commit0_id[`QBITS] ]);
        rf_v[ {commit0_tgt[RBIT:0]} ] <= regIsValid[{commit0_tgt[RBIT:0]}];//rf_source[ commit0_tgt[4:0] ] == commit0_id || (branchmiss && iq_source[ commit0_id[`QBITS] ]);
        if (regIsValid[{commit0_tgt[RBIT:0]}])
         	rf_source[{commit0_tgt[RBIT:0]}] <= {`QBIT{1'b1}};
      end
      if (commit0_tgt[RBIT:0] != 6'd0) $display("r%d <- %h   v[%d]<-%d", commit0_tgt, commit0_bus, regIsValid[commit0_tgt[RBIT:0]],
      rf_source[ {commit0_tgt[RBIT:0]} ] == commit0_id || (branchmiss && iq_source[ commit0_id[`QBITS] ]));
      if (commit0_tgt[RBIT:0]==6'd62 && commit0_bus==64'd0)
      	$display("FP <= 0");
    end
    if (commit1_v && `NUM_CMT > 1) begin
      if (!rf_v[ {commit1_tgt[RBIT:0]} ]) begin
      	if ({commit1_tgt[RBIT:0]}=={commit0_tgt[RBIT:0]}) begin
      		rf_v[ {commit1_tgt[RBIT:0]} ] <= regIsValid[{commit0_tgt[RBIT:0]}] | regIsValid[{commit1_tgt[RBIT:0]}];
      		if (regIsValid[{commit0_tgt[RBIT:0]}] | regIsValid[{commit1_tgt[RBIT:0]}])
           	rf_source[{commit1_tgt[RBIT:0]}] <= {`QBIT{1'b1}};
      		/*
      			(rf_source[ commit0_tgt[4:0] ] == commit0_id || (branchmiss && iq_source[ commit0_id[`QBITS] ])) || 
      			(rf_source[ commit1_tgt[4:0] ] == commit1_id || (branchmiss && iq_source[ commit1_id[`QBITS] ]));
      		*/
      	end
      	else begin
					rf_v[ {commit1_tgt[RBIT:0]} ] <= regIsValid[{commit1_tgt[RBIT:0]}];//rf_source[ commit1_tgt[4:0] ] == commit1_id || (branchmiss && iq_source[ commit1_id[`QBITS] ]);
          if (regIsValid[{commit1_tgt[RBIT:0]}])
           	rf_source[{commit1_tgt[RBIT:0]}] <= {`QBIT{1'b1}};
        end
      end
      if (commit1_tgt[5:0] != 6'd0) $display("r%d <- %h   v[%d]<-%d", commit1_tgt, commit1_bus, regIsValid[commit1_tgt[5:0]],
      rf_source[ {commit1_tgt[RBIT:0]} ] == commit1_id || (branchmiss && iq_source[ commit1_id[`QBITS] ]));
      if (commit1_tgt[5:0]==6'd30 && commit1_bus==64'd0)
      	$display("FP <= 0");
    end
    if (commit2_v && `NUM_CMT > 2) begin
      if (!rf_v[ {commit2_tgt[RBIT:0]} ]) begin
      	if ({commit2_tgt[RBIT:0]}=={commit1_tgt[RBIT:0]} && {commit2_tgt[RBIT:0]}=={commit0_tgt[RBIT:0]}) begin
      		rf_v[ {commit2_tgt[RBIT:0]} ] <= regIsValid[{commit0_tgt[RBIT:0]}] | regIsValid[{commit1_tgt[RBIT:0]}] | regIsValid[{commit2_tgt[RBIT:0]}];
      		if (regIsValid[{commit0_tgt[RBIT:0]}] | regIsValid[{commit1_tgt[RBIT:0]}] | regIsValid[{commit2_tgt[RBIT:0]}])
           	rf_source[{commit0_tgt[RBIT:0]}] <= {`QBIT{1'b1}};
      	end
      	else if ({commit2_tgt[RBIT:0]}=={commit0_tgt[RBIT:0]}) begin
      		rf_v[ {commit2_tgt[RBIT:0]} ] <= regIsValid[{commit0_tgt[RBIT:0]}] | regIsValid[{commit2_tgt[RBIT:0]}];
      		if (regIsValid[{commit0_tgt[RBIT:0]}] | regIsValid[{commit2_tgt[RBIT:0]}])
           	rf_source[{commit0_tgt[RBIT:0]}] <= {`QBIT{1'b1}};
      	end
      	else if ({commit2_tgt[RBIT:0]}=={commit1_tgt[RBIT:0]}) begin
      		rf_v[ {commit2_tgt[RBIT:0]} ] <= regIsValid[{commit1_tgt[RBIT:0]}] | regIsValid[{commit2_tgt[RBIT:0]}];
      		if (regIsValid[{commit1_tgt[RBIT:0]}] | regIsValid[{commit2_tgt[RBIT:0]}])
           	rf_source[{commit1_tgt[RBIT:0]}] <= {`QBIT{1'b1}};
      	end
      	else begin
        	rf_v[ {commit2_tgt[RBIT:0]} ] <= regIsValid[{commit2_tgt[RBIT:0]}];//rf_source[ commit1_tgt[4:0] ] == commit1_id || (branchmiss && iq_source[ commit1_id[`QBITS] ]);
        	if (regIsValid[{commit2_tgt[RBIT:0]}])
           	rf_source[{commit2_tgt[RBIT:0]}] <= {`QBIT{1'b1}};
        end
      end
      if (commit2_tgt[5:0] != 6'd0) $display("r%d <- %h   v[%d]<-%d", commit2_tgt, commit2_bus, regIsValid[commit2_tgt[5:0]],
      rf_source[ {commit2_tgt[RBIT:0]} ] == commit2_id || (branchmiss && iq_source[ commit2_id[`QBITS] ]));
      if (commit2_tgt[5:0]==6'd30 && commit2_bus==64'd0)
      	$display("FP <= 0");
    end
     rf_v[0] <= 1;

	if (!branchmiss)
		case({slot0v,slot1v,slot2v}&{3{phit}}&ip_mask)
		3'b000:	;
		3'b001:
			if (canq1) begin
				queue_slot2(tail0,maxsn+2'd1);
				slot0v <= VAL;
				slot1v <= VAL;
				slot2v <= VAL;
				ip <= {ip[79:4] + 76'd1,4'h0};
				if (slot2_rfw) begin
					rf_source[Rd2] <= { 1'b0, slot2_mem, tail0 };	// top bit indicates ALU/MEM bus
					rf_v [Rd2] <= `INV;
				end
			end
		3'b010:
			if (canq1) begin
				queue_slot1(tail0,maxsn+2'd1);
				slot0v <= VAL;
				slot1v <= VAL;
				slot2v <= VAL;
				ip <= {ip[79:4] + 76'd1,4'h0};
				if (slot1_rfw) begin
					rf_source[Rd1] <= { 1'b0, slot1_mem, tail0 };	// top bit indicates ALU/MEM bus
					rf_v [Rd1] <= `INV;
				end
			end
		3'b011:
			if (canq2) begin
				queue_slot1(tail0,maxsn+2'd1);
				queue_slot2(tail1,maxsn+2'd2);
				slot1v <= INV;
				slot2v <= INV;
				ip <= {ip[79:4] + 76'd1,4'h0};
				if (slot1_rfw) begin
					rf_source[Rd1] <= { 1'b0, slot1_mem, tail0 };	// top bit indicates ALU/MEM bus
					rf_v [Rd1] <= `INV;
				end
				if (slot2_rfw) begin
					rf_source[Rd2] <= { 1'b0, slot2_mem, tail1 };	// top bit indicates ALU/MEM bus
					rf_v [Rd2] <= `INV;
				end
				arg_vs_011();
			end
			else if (canq1) begin
				queue_slot1(tail0,maxsn+2'd1);
				slot1v <= INV;
				if (slot1_rfw) begin
					rf_source[Rd1] <= { 1'b0, slot1_mem, tail0 };	// top bit indicates ALU/MEM bus
					rf_v [Rd1] <= `INV;
				end
			end
		3'b100:
			if (canq1) begin
				queue_slot0(tail0,maxsn+2'd1);
				slot0v <= VAL;
				slot1v <= VAL;
				slot2v <= VAL;
				ip <= {ip[79:4] + 76'd1,4'h0};
				if (slot0_rfw) begin
					rf_source[Rd0] <= { 1'b0, slot0_mem, tail0 };	// top bit indicates ALU/MEM bus
					rf_v [Rd0] <= `INV;
				end
			end
		3'b101:
			if (canq2) begin
				queue_slot0(tail0,maxsn+2'd1);
				queue_slot2(tail1,maxsn+2'd2);
				slot0v <= VAL;
				slot1v <= VAL;
				slot2v <= VAL;
				ip <= {ip[79:4] + 76'd1,4'h0};
				if (slot0_rfw) begin
					rf_source[Rd0] <= { 1'b0, slot0_mem, tail0 };	// top bit indicates ALU/MEM bus
					rf_v [Rd0] <= `INV;
				end
				if (slot2_rfw) begin
					rf_source[Rd2] <= { 1'b0, slot2_mem, tail1 };	// top bit indicates ALU/MEM bus
					rf_v [Rd2] <= `INV;
				end
				arg_vs_101();
			end
			else if (canq1) begin
				queue_slot0(tail0,maxsn+2'd1);
				slot0v <= INV;
				if (slot0_rfw) begin
					rf_source[Rd0] <= { 1'b0, slot0_mem, tail0 };	// top bit indicates ALU/MEM bus
					rf_v [Rd0] <= `INV;
				end
			end
		3'b110:
			if (canq2) begin
				queue_slot0(tail0,maxsn+2'd1);
				queue_slot1(tail1,maxsn+2'd2);
				slot0v <= VAL;
				slot1v <= VAL;
				slot2v <= VAL;
				ip <= {ip[79:4] + 76'd1,4'h0};
				if (slot0_rfw) begin
					rf_source[Rd0] <= { 1'b0, slot0_mem, tail0 };	// top bit indicates ALU/MEM bus
					rf_v [Rd0] <= `INV;
				end
				if (slot1_rfw) begin
					rf_source[Rd1] <= { 1'b0, slot1_mem, tail1 };	// top bit indicates ALU/MEM bus
					rf_v [Rd1] <= `INV;
				end
				arg_vs_110();
			end
			else if (canq1) begin
				queue_slot0(tail0,maxsn+2'd1);
				slot0v <= INV;
				if (slot0_rfw) begin
					rf_source[Rd0] <= { 1'b0, slot0_mem, tail0 };	// top bit indicates ALU/MEM bus
					rf_v [Rd0] <= `INV;
				end
			end
		3'b111:
			if (canq3) begin
				queue_slot0(tail0,maxsn+2'd1);
				queue_slot1(tail1,maxsn+2'd2);
				queue_slot2(tail2,maxsn+2'd3);
				slot0v <= VAL;
				slot1v <= VAL;
				slot2v <= VAL;
				ip <= {ip[79:4] + 76'd1,4'h0};
				if (slot0_rfw) begin
					rf_source[Rd0] <= { 1'b0, slot0_mem, tail0 };	// top bit indicates ALU/MEM bus
					rf_v [Rd0] <= `INV;
				end
				if (slot1_rfw) begin
					rf_source[Rd1] <= { 1'b0, slot1_mem, tail1 };	// top bit indicates ALU/MEM bus
					rf_v [Rd1] <= `INV;
				end
				if (slot2_rfw) begin
					rf_source[Rd2] <= { 1'b0, slot2_mem, tail2 };	// top bit indicates ALU/MEM bus
					rf_v [Rd2] <= `INV;
				end
				arg_vs_111();
			end
			else if (canq2) begin
				queue_slot0(tail0,maxsn+2'd1);
				queue_slot1(tail1,maxsn+2'd2);
				slot0v <= INV;
				slot1v <= INV;
				if (slot0_rfw) begin
					rf_source[Rd0] <= { 1'b0, slot0_mem, tail0 };	// top bit indicates ALU/MEM bus
					rf_v [Rd0] <= `INV;
				end
				if (slot1_rfw) begin
					rf_source[Rd1] <= { 1'b0, slot1_mem, tail1 };	// top bit indicates ALU/MEM bus
					rf_v [Rd1] <= `INV;
				end
				arg_vs_110();
			end
			else if (canq1) begin
				queue_slot0(tail0,maxsn+2'd1);
				slot0v <= INV;
				if (slot0_rfw) begin
					rf_source[Rd0] <= { 1'b0, slot0_mem, tail0 };	// top bit indicates ALU/MEM bus
					rf_v [Rd0] <= `INV;
				end
			end
		endcase

//
// DATAINCOMING
//
// wait for operand/s to appear on alu busses and puts them into 
// the iq_a1 and iq_a2 slots (if appropriate)
// as well as the appropriate iq_res slots (and setting valid bits)
//
// put results into the appropriate instruction entries
//
// This chunk of code has to be before the enqueue stage so that the agen bit
// can be reset to zero by enqueue.
// put results into the appropriate instruction entries
//
if (IsMul(`IUnit,alu0_instr)|IsDivmod(`IUnit,alu0_instr)|alu0_shft|alu0_tlb) begin
	if (alu0_done_pe) begin
		alu0_dataready <= TRUE;
	end
end
if (alu1_shft) begin
	if (alu1_done_pe) begin
		alu1_dataready <= TRUE;
	end
end

if (alu0_v) begin
	iq_tgt [ alu0_id[`QBITS] ] <= alu0_tgt;
	iq_res	[ alu0_id[`QBITS] ] <= ralu0_bus;
	iq_exc	[ alu0_id[`QBITS] ] <= alu0_exc;
	if (!iq_mem[ alu0_id[`QBITS] ] && alu0_done && tlb_done) begin
//		iq_done[ alu0_id[`QBITS] ] <= `TRUE;
		iq_state[alu0_id[`QBITS]] <= IQS_CMT;
	end
//	if (alu0_done)
//		iq_cmt [ alu0_id[`QBITS] ] <= `TRUE;
//	iq_out	[ alu0_id[`QBITS] ] <= `INV;
//	iq_agen[ alu0_id[`QBITS] ] <= `VAL;//!iq_fc[alu0_id[`QBITS]];  // RET
	if (iq_mem[alu0_id[`QBITS]])
		iq_state[alu0_id[`QBITS]] <= IQS_AGEN;
	if (iq_mem[ alu0_id[`QBITS] ] && !iq_agen[ alu0_id[`QBITS] ]) begin
		iq_ma[ alu0_id[`QBITS] ] <= alu0_bus;
	end
	if (|alu0_exc) begin
//		iq_done[alu0_id[`QBITS]] <= `VAL;
		iq_store[alu0_id[`QBITS]] <= `INV;
		iq_state[alu0_id[`QBITS]] <= IQS_CMT;
	end
	alu0_dataready <= FALSE;
end

if (alu1_v && `NUM_ALU > 1) begin
	iq_tgt [ alu1_id[`QBITS] ] <= alu1_tgt;
	iq_res	[ alu1_id[`QBITS] ] <= ralu1_bus;
	iq_exc	[ alu1_id[`QBITS] ] <= alu1_exc;
	if (!iq_mem[ alu1_id[`QBITS] ] && alu1_done) begin
//		iq_done[ alu1_id[`QBITS] ] <= `TRUE;
		iq_state[alu1_id[`QBITS]] <= IQS_CMT;
	end
//	iq_done[ alu1_id[`QBITS] ] <= (!iq_mem[ alu1_id[`QBITS] ] && alu1_done);
//	if (alu1_done)
//		iq_cmt [ alu1_id[`QBITS] ] <= `TRUE;
//	iq_out	[ alu1_id[`QBITS] ] <= `INV;
	if (iq_mem[alu1_id[`QBITS]])
		iq_state[alu1_id[`QBITS]] <= IQS_AGEN;
//	iq_agen[ alu1_id[`QBITS] ] <= `VAL;//!iq_fc[alu0_id[`QBITS]];  // RET
	if (iq_mem[ alu1_id[`QBITS] ] && !iq_agen[ alu1_id[`QBITS] ]) begin
		iq_ma[ alu1_id[`QBITS] ] <= alu1_bus;
	end
	if (|alu1_exc) begin
//		iq_done[alu1_id[`QBITS]] <= `VAL;
		iq_store[alu1_id[`QBITS]] <= `INV;
		iq_state[alu1_id[`QBITS]] <= IQS_CMT;
	end
	alu1_dataready <= FALSE;
end

if (fpu1_v && `NUM_FPU > 0) begin
	iq_res [ fpu1_id[`QBITS] ] <= rfpu1_bus;
	iq_ares[ fpu1_id[`QBITS] ] <= fpu1_status;
	iq_exc [ fpu1_id[`QBITS] ] <= fpu1_exc;
//	iq_done[ fpu1_id[`QBITS] ] <= fpu1_done;
//	iq_out [ fpu1_id[`QBITS] ] <= `INV;
	iq_state[fpu1_id[`QBITS]] <= IQS_CMT;
	fpu1_dataready <= FALSE;
end

if (fpu2_v && `NUM_FPU > 1) begin
	iq_res [ fpu2_id[`QBITS] ] <= rfpu2_bus;
	iq_ares[ fpu2_id[`QBITS] ] <= fpu2_status;
	iq_exc [ fpu2_id[`QBITS] ] <= fpu2_exc;
//	iq_done[ fpu2_id[`QBITS] ] <= fpu2_done;
//	iq_out [ fpu2_id[`QBITS] ] <= `INV;
	iq_state[fpu2_id[`QBITS]] <= IQS_CMT;
	//iq_agen[ fpu_id[`QBITS] ] <= `VAL;  // RET
	fpu2_dataready <= FALSE;
end

if (fcu_wait) begin
	if (pe_wait)
		fcu_dataready <= `TRUE;
end

// If the return segment is not the same as the current code segment then a
// segment load is triggered via the memory unit by setting the iq state to
// AGEN. Otherwise the state is set to CMT which will cause a bypass of the
// segment load from memory.

if (fcu_v) begin
	fcu_done <= `TRUE;
	iq_ma  [ fcu_id[`QBITS] ] <= fcu_misspc;
  iq_res [ fcu_id[`QBITS] ] <= rfcu_bus;
  iq_exc [ fcu_id[`QBITS] ] <= fcu_exc;
	iq_state[fcu_id[`QBITS] ] <= IQS_CMT;
	// takb is looked at only for branches to update the predictor. Here it is
	// unconditionally set, the value will be ignored if it's not a branch.
	iq_takb[ fcu_id[`QBITS] ] <= fcu_takb;
	br_ctr <= br_ctr + fcu_branch;
	fcu_dataready <= `INV;
end

// dramX_v only set on a load
if (dramA_v && iq_v[ dramA_id[`QBITS] ]) begin
	iq_res	[ dramA_id[`QBITS] ] <= rdramA_bus;
	iq_state[dramA_id[`QBITS] ] <= IQS_CMT;
	iq_aq  [ dramA_id[`QBITS] ] <= `INV;
end
if (`NUM_MEM > 1 && dramB_v && iq_v[ dramB_id[`QBITS] ]) begin
	iq_res	[ dramB_id[`QBITS] ] <= rdramB_bus;
	iq_state[dramB_id[`QBITS] ] <= IQS_CMT;
	iq_aq  [ dramB_id[`QBITS] ] <= `INV;
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
		setargs(n,{1'b0,fpu1_id},fpu1_v,rfpu1_bus);
	if (`NUM_FPU > 1)
		setargs(n,{1'b0,fpu2_id},fpu2_v,rfpu2_bus);

	// The memory address generated by the ALU should not be posted to be
	// recieved into waiting argument registers. The arguments will be waiting
	// for the result of the memory load, picked up from the dram busses. The
	// only mem operation requiring the alu result bus is the push operation.
	setargs(n,{1'b0,alu0_id},alu0_v & (~alu0_mem | alu0_push),ralu0_bus);
	if (`NUM_ALU > 1)
		setargs(n,{1'b0,alu1_id},alu1_v & (~alu1_mem | alu1_push),ralu1_bus);

	setargs(n,{1'b0,fcu_id},fcu_v,rfcu_bus);

	setargs(n,{1'b0,dramA_id},dramA_v,rdramA_bus);
	if (`NUM_MEM > 1)
		setargs(n,{1'b0,dramB_id},dramB_v,rdramB_bus);

	setargs(n,commit0_id,commit0_v,commit0_bus);
	if (`NUM_CMT > 1)
		setargs(n,commit1_id,commit1_v,commit1_bus);
	if (`NUM_CMT > 2)
		setargs(n,commit2_id,commit2_v,commit2_bus);
end

	if (wb_q0_done)
		iq_state[ dram0_id[`QBITS] ] <= IQS_DONE;
	if (wb_q1_done)
		iq_state[ dram1_id[`QBITS] ] <= IQS_DONE;

	if (wb_update_iq) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (wbo_id[n]) begin
	      iq_exc[n] <= wb_fault;
	     	iq_state[n] <= IQS_CMT;
				iq_aq[n] <= `INV;
			end
		end
	end

// X's on unused busses cause problems in SIM.
    for (n = 0; n < QENTRIES; n = n + 1)
        if (iq_alu0_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (alu0_available & alu0_done) begin
                 alu0_sourceid	<= {iq_push[n],n[`QBITS]};
                 alu0_instr	<= iq_rtop[n] ? (
`ifdef FU_BYPASS                 									
                 									iq_argC_v[n] ? iq_argC[n]
			                            : (iq_argC_s[n] == alu0_id) ? ralu0_bus
			                            : (iq_argC_s[n] == alu1_id) ? ralu1_bus
			                            : (iq_argC_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus
			                            : `NOP_INSN)
`else			                           
																	iq_argC[n]) 
`endif			                            
                 							 : iq_instr[n];
                 alu0_sz    <= iq_sz[n];
                 alu0_tlb   <= iq_tlb[n];
                 alu0_mem   <= iq_mem[n];
                 alu0_load  <= iq_load[n];
                 alu0_store <= iq_store[n];
                 alu0_push  <= iq_push[n];
                 alu0_shft <= iq_shft[n];
                 alu0_ip		<= iq_ip[n];
                 alu0_argA	<=
`ifdef FU_BYPASS                  
                 							iq_argA_v[n] ? iq_argA[n]
                            : (iq_argA_s[n] == alu0_id) ? ralu0_bus
                            : (iq_argA_s[n] == alu1_id) ? ralu1_bus
                            : (iq_argA_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus
                            : 64'hDEADDEADDEADDEAD;
`else
														iq_argA[n];                            
`endif                            
                 alu0_argB	<= iq_imm[n]
                            ? iq_argI[n]
`ifdef FU_BYPASS                            
                            : (iq_argB_v[n] ? iq_argB[n]
                            : (iq_argB_s[n] == alu0_id) ? ralu0_bus 
                            : (iq_argB_s[n] == alu1_id) ? ralu1_bus 
                            : (iq_argB_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus
                            : 64'hDEADDEADDEADDEAD);
`else
														: iq_argB[n];                         
`endif                            
                 alu0_argC	<=
`ifdef FU_BYPASS                  
                 							iq_argC_v[n] ? iq_argC[n]
                            : (iq_argC_s[n] == alu0_id) ? ralu0_bus : ralu1_bus;
`else
															iq_argC[n];                            
`endif                            
                 alu0_argI	<= iq_argI[n];
                 alu0_tgt    <= iq_tgt[n];
                 alu0_dataready <= IsSingleCycle(`IUnit,iq_instr[n]);
                 alu0_ld <= TRUE;
                 iq_state[n] <= IQS_OUT;
            end
        end
	if (`NUM_ALU > 1) begin
    for (n = 0; n < QENTRIES; n = n + 1)
        if (iq_alu1_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (alu1_available && alu1_done) begin
                 alu1_sourceid	<= {iq_push[n],n[`QBITS]};
                 alu1_instr	<= iq_instr[n];
                 alu1_sz    <= iq_sz[n];
                 alu1_mem   <= iq_mem[n];
                 alu1_load  <= iq_load[n];
                 alu1_store <= iq_store[n];
                 alu1_push  <= iq_push[n];
                 alu1_shft  <= iq_shft[n];
                 alu1_ip		<= iq_ip[n];
                 alu1_argA	<=
`ifdef FU_BYPASS                  
                 							iq_argA_v[n] ? iq_argA[n]
                            : (iq_argA_s[n] == alu0_id) ? ralu0_bus
                            : (iq_argA_s[n] == alu1_id) ? ralu1_bus
                            : (iq_argA_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus
                            : 64'hDEADDEADDEADDEAD;
`else
															iq_argA[n];                            
`endif                           
                 alu1_argB	<= iq_imm[n]
                            ? iq_argI[n]
`ifdef FU_BYPASS                           
                            : (iq_argB_v[n] ? iq_argB[n]
                            : (iq_argB_s[n] == alu0_id) ? ralu0_bus 
                            : (iq_argB_s[n] == alu1_id) ? ralu1_bus 
                            : (iq_argB_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus
                            : 64'hDEADDEADDEADDEAD);
`else
														: iq_argB[n];
`endif                            
                 alu1_argC	<=
`ifdef FU_BYPASS                 	
                 							iq_argC_v[n] ? iq_argC[n]
                            : (iq_argC_s[n] == alu0_id) ? ralu0_bus : ralu1_bus;
`else                            
															iq_argC[n];
`endif                            
                 alu1_argI	<= iq_argI[n];
                 alu1_tgt    <= iq_tgt[n];
                 alu1_dataready <= IsSingleCycle(`IUnit,iq_instr[n]);
                 alu1_ld <= TRUE;
                 iq_state[n] <= IQS_OUT;
            end
        end
  end

    for (n = 0; n < QENTRIES; n = n + 1)
        if (iq_fpu1_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (fpu1_available & fpu1_done) begin
                 fpu1_sourceid	<= n[`QBITS];
                 fpu1_instr	<= iq_instr[n];
                 fpu1_ip		<= iq_ip[n];
                 fpu1_argA	<=
`ifdef FU_BYPASS                  
                 							iq_argA_v[n] ? iq_argA[n]
                            : (iq_argA_s[n] == alu0_id) ? ralu0_bus 
                            : (iq_argA_s[n] == alu1_id) ? ralu1_bus 
                            : (iq_argA_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus
                            : 64'hDEADDEADDEADDEAD;
`else
															iq_argA[n];                          
`endif                            
                 fpu1_argB	<=
`ifdef FU_BYPASS                  
                 							(iq_argB_v[n] ? iq_argB[n]
                            : (iq_argB_s[n] == alu0_id) ? ralu0_bus 
                            : (iq_argB_s[n] == alu1_id) ? ralu1_bus 
                            : (iq_argB_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus
                            : 64'hDEADDEADDEADDEAD);
`else
															iq_argB[n];
`endif                            
                 fpu1_argC	<=
`ifdef FU_BYPASS                 
                 							 iq_argC_v[n] ? iq_argC[n]
                            : (iq_argC_s[n] == alu0_id) ? ralu0_bus : ralu1_bus;
`else
															iq_argC[n];                           
`endif                            
                 fpu1_argI	<= iq_argI[n];
                 fpu1_dataready <= `VAL;
                 fpu1_ld <= TRUE;
                 iq_state[n] <= IQS_OUT;
            end
        end

    for (n = 0; n < QENTRIES; n = n + 1)
        if (`NUM_FPU > 1 && iq_fpu2_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (fpu2_available & fpu2_done) begin
                 fpu2_sourceid	<= n[`QBITS];
                 fpu2_instr	<= iq_instr[n];
                 fpu2_ip		<= iq_ip[n];
                 fpu2_argA	<=
`ifdef FU_BYPASS                  
                 							iq_argA_v[n] ? iq_argA[n]
                            : (iq_argA_s[n] == alu0_id) ? ralu0_bus 
                            : (iq_argA_s[n] == alu1_id) ? ralu1_bus 
                            : (iq_argA_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus
                            : 64'hDEADDEADDEADDEAD;
`else
															iq_argA[n];                          
`endif                            
                 fpu2_argB	<=
`ifdef FU_BYPASS                  
                 							(iq_argB_v[n] ? iq_argB[n]
                            : (iq_argB_s[n] == alu0_id) ? ralu0_bus 
                            : (iq_argB_s[n] == alu1_id) ? ralu1_bus 
                            : (iq_argB_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus
                            : 64'hDEADDEADDEADDEAD);
`else
															iq_argB[n];
`endif                            
                 fpu2_argC	<=
`ifdef FU_BYPASS                 
                 							 iq_argC_v[n] ? iq_argC[n]
                            : (iq_argC_s[n] == alu0_id) ? ralu0_bus : ralu1_bus;
`else
															iq_argC[n];                           
`endif                            
                 fpu2_argI	<= iq_argI[n];
                 fpu2_dataready <= `VAL;
                 fpu2_ld <= TRUE;
                 iq_state[n] <= IQS_OUT;
            end
        end

  for (n = 0; n < QENTRIES; n = n + 1)
    if (iq_fcu_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
      if (fcu_done) begin
				fcu_sourceid	<= n[`QBITS];
				fcu_prevInstr <= fcu_instr;
				fcu_instr	<= iq_instr[n];
				fcu_ip		<= iq_ip[n];
				case(iq_ip[n][3:0])
				4'h0:	fcu_nextip <= {iq_ip[n][79:4],4'h5};
				4'h5:	fcu_nextip <= {iq_ip[n][79:4],4'hA};
				4'hA:	fcu_nextip <= {iq_ip[n][79:4],4'h0} + 8'd16;
				default:	begin fcu_nextip <= iq_ip[n]; fcu_exc <= `FLT_ALN; end
				endcase
				fcu_pt     <= iq_pt[n];
				fcu_brdisp <= {{57{iq_instr[n][39]}},iq_instr[n][39:22],iq_instr[n][5:3],iq_instr[n][4:3]};
				fcu_branch <= iq_br[n];
				fcu_call    <= IsCall(`BUnit,iq_instr[n])|iq_jal[n];
				fcu_jal     <= iq_jal[n];
				fcu_ret    <= iq_ret[n];
				fcu_brk  <= iq_brk[n];
				fcu_rti  <= iq_rti[n];
				fcu_rex  <= iq_rex[n];
				fcu_chk  <= iq_chk[n];
				fcu_wait <= iq_wait[n];
				fcu_argA	<= iq_argA_v[n] ? iq_argA[n]
				          : (iq_argA_s[n] == alu0_id) ? ralu0_bus
				          : (iq_argA_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus
				          : ralu1_bus;
				fcu_epc  <= epc0;
				fcu_argB	<=
						  (iq_argB_v[n] ? iq_argB[n]
				          : (iq_argB_s[n] == alu0_id) ? ralu0_bus 
				          : (iq_argB_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus
				          : ralu1_bus);
				// argB
				waitctr  <=  (iq_argB_v[n] ? iq_argB[n][47:0]
				          : (iq_argB_s[n] == alu0_id) ? ralu0_bus[47:0]
				          : (iq_argB_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus[47:0]
				          : ralu1_bus[47:0]);
				fcu_argC	<= iq_argC_v[n] ? iq_argC[n]
				          : (iq_argC_s[n] == alu0_id) ? ralu0_bus : ralu1_bus;
				fcu_argI	<= iq_argI[n];
				fcu_dataready <= !IsWait(`BUnit,iq_instr[n]);
				fcu_clearbm <= `FALSE;
				fcu_ld <= TRUE;
				fcu_timeout <= 8'h00;
				iq_state[n] <= IQS_OUT;
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
// of three pipelined DRAM requests.  if any has the value "000", 
// then it can accept a request (which bumps it up to the value "001"
// at the end of the cycle).  once it hits the value "111" the request
// is finished and the dram_bus takes the value.  if it is a store, the 
// dram_bus value is not used, but the dram_v value along with the
// dram_id value signals the waiting memq entry that the store is
// completed and the instruction can commit.
//

// Flip the ready status to available. Used for loads or stores.

if (dram0 == `DRAMREQ_READY)
	dram0 <= `DRAMSLOT_AVAIL;
if (dram1 == `DRAMREQ_READY && `NUM_MEM > 1)
	dram1 <= `DRAMSLOT_AVAIL;

// grab requests that have finished and put them on the dram_bus
// If stomping on the instruction don't place the value on the argument
// bus to be loaded.
if (dram0 == `DRAMREQ_READY && dram0_load) begin
	dramA_v <= !iq_stomp[dram0_id[`QBITS]];
	dramA_id <= dram0_id;
	dramA_bus <= fnDatiAlign(dram0_instr,dram0_addr,rdat0);
end
if (dram1 == `DRAMREQ_READY && dram1_load && `NUM_MEM > 1) begin
	dramB_v <= !iq_stomp[dram1_id[`QBITS]];
	dramB_id <= dram1_id;
	dramB_bus <= fnDatiAlign(dram1_instr,dram1_addr,rdat1);
end

//
// determine if the instructions ready to issue can, in fact, issue.
// "ready" means that the instruction has valid operands but has not gone yet
for (n = 0; n < QENTRIES; n = n + 1)
if (memissue[n])
	iq_memissue[n] <= `VAL;
//iq_memissue <= memissue;
missue_count <= issue_count;

for (n = 0; n < QENTRIES; n = n + 1)
	if (iq_v[n] && iq_stomp[n]) begin
		iq_mem[n] <= `INV;
		iq_load[n] <= `INV;
		iq_store[n] <= `INV;
		iq_state[n] <= IQS_INVALID;
	end

if (last_issue0 < QENTRIES)
	tDram0Issue(last_issue0);
if (last_issue1 < QENTRIES)
	tDram1Issue(last_issue1);

if (ohead[0]==heads[0])
	cmt_timer <= cmt_timer + 12'd1;
else
	cmt_timer <= 12'd0;

if (cmt_timer==12'd1000 && icstate==IDLE) begin
	iq_state[heads[0]] <= IQS_CMT;
	iq_exc[heads[0]] <= `FLT_CMT;
	cmt_timer <= 12'd0;
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

oddball_commit(commit0_v, heads[0], 2'd0);
if (`NUM_CMT > 1)
	oddball_commit(commit1_v, heads[1], 2'd1);
if (`NUM_CMT > 2)
	oddball_commit(commit2_v, heads[2], 2'd2);

// Fetch and queue are limited to two instructions per cycle, so we might as
// well limit retiring to two instructions max to conserve logic.
//
if (~|panic)
  casez ({ iq_v[heads[0]],iq_state[heads[0]] == IQS_CMT,
		iq_v[heads[1]],iq_state[heads[1]] == IQS_CMT,
		iq_v[heads[2]],iq_state[heads[2]] == IQS_CMT})

	// retire 3
	6'b0?_0?_0?:
		if (heads[0] != tail0 && heads[1] != tail0 && heads[2] != tail0)
			head_inc(3);
		else if (heads[0] != tail0 && heads[1] != tail0)
	    head_inc(2);
		else if (heads[0] != tail0)
	    head_inc(1);
	6'b0?_0?_10:
		if (heads[0] != tail0 && heads[1] != tail0)
			head_inc(2);
		else if (heads[0] != tail0)
			head_inc(1);
	6'b0?_0?_11:
		if (`NUM_CMT > 2 || cmt_head2)	// and it's not an oddball?
      head_inc(3);
		else
      head_inc(2);

	// retire 1 (wait for regfile for heads[1])
	6'b0?_10_??:
		head_inc(1);

	// retire 2
	6'b0?_11_0?,
	6'b0?_11_10:
    if (`NUM_CMT > 1 || cmt_head1)
      head_inc(2);
    else
    	head_inc(1);
  6'b0?_11_11:
    if (`NUM_CMT > 2 || (`NUM_CMT > 1 && cmt_head2))
    	head_inc(3);
  	else if (`NUM_CMT > 1 || cmt_head1)
    	head_inc(2);
  	else
  		head_inc(1);
  6'b10_??_??:	;
  6'b11_0?_0?:
  	if (heads[1] != tail0 && heads[2] != tail0)
			head_inc(3);
  	else if (heads[1] != tail0)
			head_inc(2);
  	else
			head_inc(1);
  6'b11_0?_10:
  	if (heads[1] != tail0)
			head_inc(2);
  	else
			head_inc(1);
  6'b11_0?_11:
  	if (heads[1] != tail0) begin
  		if (`NUM_CMT > 2 || cmt_head2)
				head_inc(3);
  		else
				head_inc(2);
  	end
  	else
			head_inc(1);
  6'b11_10_??:
			head_inc(1);
  6'b11_11_0?:
  	if (`NUM_CMT > 1 && heads[2] != tail0)
			head_inc(3);
  	else if (cmt_head1 && heads[2] != tail0)
			head_inc(3);
		else if (`NUM_CMT > 1 || cmt_head1)
			head_inc(2);
  	else
			head_inc(1);
  6'b11_11_10:
		if (`NUM_CMT > 1 || cmt_head1)
			head_inc(2);
  	else
			head_inc(1);
	6'b11_11_11:
		if (`NUM_CMT > 2 || (`NUM_CMT > 1 && cmt_head2))
			head_inc(3);
		else if (`NUM_CMT > 1 || cmt_head1)
			head_inc(2);
		else
			head_inc(1);
	default:
		begin
			$display("head_inc: Uncoded case %h",{ iq_v[heads[0]],
				iq_state[heads[0]],
				iq_v[heads[1]],
				iq_state[heads[1]],
				iq_v[heads[2]],
				iq_state[heads[2]]});
			$stop;
		end
  endcase


rf_source[0] <= 0;

// A store will never be stomped on because they aren't issued until it's
// guarenteed there will be no change of flow.
// A load or other long running instruction might be stomped on by a change
// of program flow. Stomped on loads already in progress can be aborted early.
// In the case of an aborted load, random data is returned and any exceptions
// are nullified.
if (dram0_load)
case(dram0)
`DRAMSLOT_AVAIL:	;
`DRAMSLOT_BUSY:
	if (iq_v[dram0_id[`QBITS]] && !iq_stomp[dram0_id[`QBITS]])
		dram0 <= dram0 + !dram0_unc;
	else begin
		dram0 <= `DRAMREQ_READY;
		dram0_load <= `FALSE;
		xdati <= {13{lfsro}};
	end
3'd2,3'd3:
	if (iq_v[dram0_id[`QBITS]] && !iq_stomp[dram0_id[`QBITS]])
		dram0 <= dram0 + 3'd1;
	else begin
		dram0 <= `DRAMREQ_READY;
		dram0_load <= `FALSE;
		xdati <= {13{lfsro}};
	end
3'd4:
	if (iq_v[dram0_id[`QBITS]] && !iq_stomp[dram0_id[`QBITS]]) begin
		if (dhit0)
			dram0 <= `DRAMREQ_READY;
		else
			dram0 <= `DRAMSLOT_REQBUS;
	end
	else begin
		dram0 <= `DRAMREQ_READY;
		dram0_load <= `FALSE;
		xdati <= {13{lfsro}};
	end
`DRAMSLOT_REQBUS:	
	if (iq_v[dram0_id[`QBITS]] && !iq_stomp[dram0_id[`QBITS]])
		;
	else begin
		dram0 <= `DRAMREQ_READY;
		dram0_load <= `FALSE;
		xdati <= {13{lfsro}};
	end
`DRAMSLOT_HASBUS:
	if (iq_v[dram0_id[`QBITS]] && !iq_stomp[dram0_id[`QBITS]])
		;
	else begin
		dram0 <= `DRAMREQ_READY;
		dram0_load <= `FALSE;
		xdati <= {13{lfsro}};
	end
`DRAMREQ_READY:		dram0 <= `DRAMSLOT_AVAIL;
endcase

if (dram1_load)
case(dram1)
`DRAMSLOT_AVAIL:	;
`DRAMSLOT_BUSY:
	if (iq_v[dram1_id[`QBITS]] && !iq_stomp[dram1_id[`QBITS]])
		dram1 <= dram1 + !dram1_unc;
	else begin
		dram1 <= `DRAMREQ_READY;
		dram1_load <= `FALSE;
		xdati <= {13{lfsro}};
	end
3'd2,3'd3:
	if (iq_v[dram1_id[`QBITS]] && !iq_stomp[dram1_id[`QBITS]])
		dram1 <= dram1 + 3'd1;
	else begin
		dram1 <= `DRAMREQ_READY;
		dram1_load <= `FALSE;
		xdati <= {13{lfsro}};
	end
3'd4:
	if (iq_v[dram1_id[`QBITS]] && !iq_stomp[dram1_id[`QBITS]]) begin
		if (dhit0)
			dram1 <= `DRAMREQ_READY;
		else
			dram1 <= `DRAMSLOT_REQBUS;
	end
	else begin
		dram1 <= `DRAMREQ_READY;
		dram1_load <= `FALSE;
		xdati <= {13{lfsro}};
	end
`DRAMSLOT_REQBUS:	
	if (iq_v[dram1_id[`QBITS]] && !iq_stomp[dram1_id[`QBITS]])
		;
	else begin
		dram1 <= `DRAMREQ_READY;
		dram1_load <= `FALSE;
		xdati <= {13{lfsro}};
	end
`DRAMSLOT_HASBUS:
	if (iq_v[dram1_id[`QBITS]] && !iq_stomp[dram1_id[`QBITS]])
		;
	else begin
		dram1 <= `DRAMREQ_READY;
		dram1_load <= `FALSE;
		xdati <= {13{lfsro}};
	end
`DRAMREQ_READY:		dram1 <= `DRAMSLOT_AVAIL;
endcase

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

      if (~|wb_v && dram0==`DRAMSLOT_BUSY && dram0_rmw
      	&& !iq_stomp[dram0_id[`QBITS]]) begin
`ifdef SUPPORT_DBG      
            if (dbg_smatch0|dbg_lmatch0) begin
                 dramA_v <= `TRUE;
                 dramA_id <= dram0_id;
                 dramA_bus <= 64'h0;
                 iq_exc[dram0_id[`QBITS]] <= `FLT_DBG;
                 dram0 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            if (!ack_i) begin
                 isRMW <= dram0_rmw;
                 isCAS <= IsCAS(`MStUnit,dram0_instr);
//                 isAMO <= IsAMO(dram0_instr);
//                 isInc <= IsInc(dram0_instr);
                 casid <= dram0_id;
                 bwhich <= 2'b00;
                 dram0 <= `DRAMSLOT_HASBUS;
                 dcyc <= `HIGH;
                 dstb <= `HIGH;
                 dsel <= fnSelect(dram0_instr,dram0_addr);
                 dcbuf <= dram0_data << {dram0_addr[4:0],3'b0};
                 dcsel <= fnSelect(`MStUnit,dram0_instr) << dram0_addr[4:0];
                 dadr <= dram0_addr;
                 ddat <= dram0_data << {dram0_addr[3:0],3'b0};
                 dol  <= dram0_ol;
                 bstate <= B_RMWAck;
            end
        end
        else if (~|wb_v && dram1==`DRAMSLOT_BUSY && dram1_rmw && `NUM_MEM > 1
        	&& !iq_stomp[dram1_id[`QBITS]]) begin
`ifdef SUPPORT_DBG        	
            if (dbg_smatch1|dbg_lmatch1) begin
                 dramB_v <= `TRUE;
                 dramB_id <= dram1_id;
                 dramB_bus <= 64'h0;
                 iq_exc[dram1_id[`QBITS]] <= `FLT_DBG;
                 dram1 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            if (!ack_i) begin
                 isRMW <= dram1_rmw;
//                 isCAS <= IsCAS(dram1_instr);
//                 isAMO <= IsAMO(dram1_instr);
                 //isInc <= IsInc(dram1_instr);
                 casid <= dram1_id;
                 bwhich <= 2'b01;
                 dram1 <= `DRAMSLOT_HASBUS;
                 dcyc <= `HIGH;
                 dstb <= `HIGH;
                 dcbuf <= dram1_data << {dram1_addr[4:0],3'b0};
                 dcsel <= fnSelect(`MStUnit,dram1_instr) << dram1_addr[4:0];
                 dsel <= fnSelect(dram1_instr,dram1_addr);
                 dadr <= dram1_addr;
                 ddat <= dram1_data << {dram1_addr[3:0],3'b0};
                 dol  <= dram1_ol;
                 bstate <= B_RMWAck;
            end
        end
`ifndef HAS_WB
				// Check write buffer enable ?
        else if (dram0==`DRAMSLOT_BUSY && dram0_store) begin
`ifdef SUPPORT_DBG        	
            if (dbg_smatch0) begin
                 dramA_v <= `TRUE;
                 dramA_id <= dram0_id;
                 dramA_bus <= 64'h0;
                 iq_exc[dram0_id[`QBITS]] <= `FLT_DBG;
                 dram0 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            begin
							bwhich <= 2'b00;
							if (!acki) begin                 
								dram0 <= `DRAMSLOT_HASBUS;
								dram0_instr[`INSTRUCTION_OP] <= `NOP;
                dcyc <= `HIGH;
                dstb <= `HIGH;
                dwe <= `HIGH;
                dsel <= fnSelect(dram0_instr,dram0_addr);
                dadr <= dram0_addr;
                ddat <= fnDato(dram0_instr,dram0_data);
                dol  <= dram0_ol;
			        	isStore <= TRUE;
                bstate <= B_StoreAck;
                 dcbuf <= {4{fnDato(dram0_instr,dram0_data)}};
                 dcsel <= fnSelect(dram0_instr,dram0_addr) << {dram0_addr[4:3],3'b0};
              end
//                 cr_o <= IsSWC(dram0_instr);
            end
        end
        else if (dram1==`DRAMSLOT_BUSY && dram1_store && `NUM_MEM > 1) begin
`ifdef SUPPORT_DBG        	
            if (dbg_smatch1) begin
                 dramB_v <= `TRUE;
                 dramB_id <= dram1_id;
                 dramB_bus <= 64'h0;
                 iq_exc[dram1_id[`QBITS]] <= `FLT_DBG;
                 dram1 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            begin
                 bwhich <= 2'b01;
							if (!acki) begin
                dram1 <= `DRAMSLOT_HASBUS;
                dram1_instr[`INSTRUCTION_OP] <= `NOP;
                dcyc <= `HIGH;
                dstb <= `HIGH;
                dwe <= `HIGH;
                dsel <= fnSelect(dram1_instr,dram1_addr);
                dadr <= dram1_addr;
                ddat <= fnDato(dram1_instr,dram1_data);
                dol  <= dram1_ol;
			        	isStore <= TRUE;
                 dcbuf <= {4{fnDato(dram1_instr,dram1_data)}};
                 dcsel <= fnSelect(dram1_instr,dram1_addr) << {dram1_addr[4:3],3'b0};
                bstate <= B_StoreAck;
              end
//                 cr_o <= IsSWC(dram0_instr);
            end
        end
        else if (dram2==`DRAMSLOT_BUSY && dram2_store && `NUM_MEM > 2) begin
`ifdef SUPPORT_DBG        	
            if (dbg_smatch2) begin
                 dramC_v <= `TRUE;
                 dramC_id <= dram2_id;
                 dramC_bus <= 64'h0;
                 iq_exc[dram2_id[`QBITS]] <= `FLT_DBG;
                 dram2 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            begin
                 bwhich <= 2'b10;
							if (!acki) begin
                dram2 <= `DRAMSLOT_HASBUS;
                dram2_instr[`INSTRUCTION_OP] <= `NOP;
                dcyc <= `HIGH;
                dstb <= `HIGH;
                dwe <= `HIGH;
                dsel <= fnSelect(dram2_instr,dram2_addr);
                dadr <= dram2_addr;
                ddat <= fnDato(dram2_instr,dram2_data);
                dol  <= dram2_ol;
				       	isStore <= TRUE;
                 dcbuf <= {4{fnDato(dram2_instr,dram2_data)}};
                 dcsel <= fnSelect(dram2_instr,dram2_addr) << {dram2_addr[4:3],3'b0};
                bstate <= B_StoreAck;
              end
//                 cr_o <= IsSWC(dram0_instr);
            end
        end
`endif
        // Check for read misses on the data cache
        else if (~|wb_v && !dram0_unc && dram0==`DRAMSLOT_REQBUS && dram0_load
        	&& !iq_stomp[dram0_id[`QBITS]]) begin
`ifdef SUPPORT_DBG        	
            if (dbg_lmatch0) begin
               dramA_v <= `TRUE;
               dramA_id <= dram0_id;
               dramA_bus <= 64'h0;
               iq_exc[dram0_id[`QBITS]] <= `FLT_DBG;
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
        else if (~|wb_v && !dram1_unc && dram1==`DRAMSLOT_REQBUS && dram1_load && `NUM_MEM > 1
        	&& !iq_stomp[dram1_id[`QBITS]]) begin
`ifdef SUPPORT_DBG        	
            if (dbg_lmatch1) begin
               dramB_v <= `TRUE;
               dramB_id <= dram1_id;
               dramB_bus <= 64'h0;
               iq_exc[dram1_id[`QBITS]] <= `FLT_DBG;
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
        else if (~|wb_v && dram0_unc && dram0==`DRAMSLOT_BUSY && dram0_load
        	&& !iq_stomp[dram0_id[`QBITS]]) begin
`ifdef SUPPORT_DBG        	
            if (dbg_lmatch0) begin
               dramA_v <= `TRUE;
               dramA_id <= dram0_id;
               dramA_bus <= 64'h0;
               iq_exc[dram0_id[`QBITS]] <= `FLT_DBG;
               dram0 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            if (!ack_i) begin
               bwhich <= 2'b00;
               dram0 <= `DRAMSLOT_HASBUS;
               dcyc <= `HIGH;
               dstb <= `HIGH;
               dsel <= fnSelect(dram0_instr,dram0_addr);
               dadr <= {dram0_addr[AMSB:3],3'b0};
               sr_o <=  IsLWR(`MLdUnit,dram0_instr);
               ol_o  <= dram0_ol;
               dccnt <= 2'd0;
               bstate <= B_DLoadAck;
            end
        end
        else if (~|wb_v && dram1_unc && dram1==`DRAMSLOT_BUSY && dram1_load && `NUM_MEM > 1
        	&& !iq_stomp[dram1_id[`QBITS]]) begin
`ifdef SUPPORT_DBG        	
            if (dbg_lmatch1) begin
               dramB_v <= `TRUE;
               dramB_id <= dram1_id;
               dramB_bus <= 64'h0;
               iq_exc[dram1_id[`QBITS]] <= `FLT_DBG;
               dram1 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            if (!ack_i) begin
               bwhich <= 2'b01;
               dram1 <= `DRAMSLOT_HASBUS;
               dcyc <= `HIGH;
               dstb <= `HIGH;
               dsel <= fnSelect(dram1_instr,dram1_addr);
               dadr <= {dram1_addr[AMSB:3],3'b0};
               sr_o <=  IsLWR(`MLdUnit,dram1_instr);
               ol_o  <= dram1_ol;
               dccnt <= 2'd0;
               bstate <= B_DLoadAck;
            end
        end
        // Check for L2 cache miss
        else if (~|wb_v && !L2_ihit && !ack_i)
        begin
        	cyc_pending <= `HIGH;
        	bstate <= B_WaitIC;
        	/*
           cti_o <= 3'b001;
           bte_o <= 2'b00;//2'b01;	// 4 beat burst wrap
           cyc <= `HIGH;
           stb_o <= `HIGH;
           sel_o <= 8'hFF;
           icl_o <= `HIGH;
           iccnt <= 3'd0;
           icack <= 1'b0;
//            adr_o <= icwhich ? {pc0[31:5],5'b0} : {pc1[31:5],5'b0};
//            L2_adr <= icwhich ? {pc0[31:5],5'b0} : {pc1[31:5],5'b0};
           vadr <= {L1_adr[AMSB:5],5'h0};
`ifdef SUPPORT_SMT          
`else 
           ol_o  <= ol;//???
`endif
           L2_adr <= {L1_adr[AMSB:5],5'h0};
           L2_xsel <= 1'b0;
           selL2 <= TRUE;
           bstate <= B_ICacheAck;
           */
        end
    end
B_WaitIC:
	begin
		cyc_pending <= `LOW;
		cti_o <= icti;
		bte_o <= ibte;
		cyc <= icyc;
		stb_o <= istb;
		sel_o <= isel;
		vadr <= iadr;
		we <= 1'b0;
		if (L2_nxt)
			bstate <= BIDLE;
	end


B_DCacheLoadStart:
  if (~ack_i & ~cyc) begin	// check for idle bus - it should be
    dccnt <= 2'd0;
    bstate <= B_DCacheLoadAck;
		dcti <= 3'b001;	// constant address burst
		dbte <= 2'b00;		// linear burst, non-wrapping
		dcyc <= `HIGH;
		dstb <= `HIGH;
		// Select should be selecting all byte lanes for a cache load
    dsel <= 16'hFFFF;
		// bwhich should always be one of the three channels.
		// If single bit upset, continue to select channel zero when
		// there's only one available.
    case(bwhich)
    2'd1:   if (`NUM_MEM > 1) begin
             dadr <= {dram1_addr[AMSB:5],5'b0};
             dol  <= dram1_ol;
             	if (iq_stomp[dram1_id[`QBITS]]) begin
             		wb_nack();
             		dram1 <= `DRAMREQ_READY;
             		bstate <= BIDLE;
           		end
            end
            else begin
             dadr <= {dram0_addr[AMSB:5],5'b0};
             dol  <= dram0_ol;
             	if (iq_stomp[dram0_id[`QBITS]]) begin
             		wb_nack();
             		dram0 <= `DRAMREQ_READY;
             		bstate <= BIDLE;
           		end
            end
    default: 
      begin
				dadr <= {dram0_addr[AMSB:5],5'b0};
				dol  <= dram0_ol;
       	if (iq_stomp[dram0_id[`QBITS]]) begin
       		wb_nack();
       		dram0 <= `DRAMREQ_READY;
       		bstate <= BIDLE;
     		end
    	end
    endcase
  end

// Data cache load terminal state
B_DCacheLoadAck:
	begin
		dcsel <= 32'hFFFFFFFF;
	  if (ack_i|err_i|tlb_miss|rdv_i) begin
	  	if (!bok_i) begin
	  		dstb <= `LOW;
	  		bstate <= B_DCacheLoadStb;
	  	end
	    errq <= errq | err_i;
	    rdvq <= rdvq | rdv_i;
	    if (!preload)	// A preload instruction ignores any error
	    if (dccnt==3'd3)
		    case(bwhich)
		    2'd0: 	
		    	if (iq_stomp[dram0_id[`QBITS]])
		    		iq_exc[dram0_id[`QBITS]] <= `FLT_NONE;
		    	else
		    		iq_exc[dram0_id[`QBITS]] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DBE : rdv_i ? `FLT_DRF : `FLT_NONE;
		    2'd1:
		    	if (iq_stomp[dram1_id[`QBITS]])
		    		iq_exc[dram1_id[`QBITS]] <= `FLT_NONE;
		    	else
						iq_exc[dram1_id[`QBITS]] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DBE : rdv_i ? `FLT_DRF : `FLT_NONE;
		    endcase
	    case(dccnt)
	    2'd0:	dcbuf[63:0] <= dat_i;
	    2'd1:	dcbuf[127:64] <= dat_i;
	    2'd2:	dcbuf[191:128] <= dat_i;
	    2'd3:	dcbuf[255:192] <= dat_i;
	  	endcase
	    dccnt <= dccnt + 2'd1;
	    dadr[4:3] <= dadr[4:3] + 2'd1;
	    if (dccnt==2'd2)
				dcti <= 3'b111;
	    if (dccnt==2'd3) begin
	    	wb_nack();
				dcwr <= 1'b1;
				dcwait_ctr <= dcwait;
				bstate <= B_DCacheLoadWait;
	    end
	  end
	end
B_DCacheLoadStb:
	begin
		dstb <= `HIGH;
		bstate <= B_DCacheLoadAck;
    case(bwhich)
    2'd0:
     	if (iq_stomp[dram0_id[`QBITS]]) begin
     		wb_nack();
     		dram0 <= `DRAMREQ_READY;
     		bstate <= BIDLE;
   		end
   	2'd1:
     	if (iq_stomp[dram1_id[`QBITS]]) begin
     		wb_nack();
     		dram1 <= `DRAMREQ_READY;
     		bstate <= BIDLE;
   		end
   	default:
     	if (iq_stomp[dram0_id[`QBITS]]) begin
     		wb_nack();
     		dram0 <= `DRAMREQ_READY;
     		bstate <= BIDLE;
   		end
   	endcase
  end
B_DCacheLoadWait:
	begin
		dcsel <= 32'h0;
		dcwr <= 1'b0;
		dcwait_ctr <= dcwait_ctr - 4'd1;
		if (dcwait_ctr[3])	// detect underflow
			bstate <= B_DCacheLoadResetBusy;
	end
// There could be more than one memory cycle active. We reset the state
// of the other machines to retest for a hit because otherwise sequential
// loading of memory will cause successive machines to miss resulting in 
// multiple dcache loads that aren't needed.
B_DCacheLoadResetBusy:
	begin
    if (`NUM_MEM > 1)
		  case(bwhich)
		  2'b01:  
		  	begin
		  		dram1 <= `DRAMREQ_READY;
			    if (dram0 != `DRAMSLOT_AVAIL && dram0_addr[AMSB:5]==vadr[AMSB:5]) dram0 <= `DRAMSLOT_BUSY;  // causes retest of dhit
		  	end
		  2'b10:
		    if (`NUM_MEM > 2) begin
			    if (dram0 != `DRAMSLOT_AVAIL && dram0_addr[AMSB:5]==vadr[AMSB:5]) dram0 <= `DRAMSLOT_BUSY;  // causes retest of dhit
			    if (dram1 != `DRAMSLOT_AVAIL && dram1_addr[AMSB:5]==vadr[AMSB:5]) dram1 <= `DRAMSLOT_BUSY;
		  	end
				else begin
					dram0 <= `DRAMREQ_READY;
			    if (dram1 != `DRAMSLOT_AVAIL && dram1_addr[AMSB:5]==vadr[AMSB:5]) dram1 <= `DRAMSLOT_BUSY;
		  	end
		  default:
		  	begin
		  		dram0 <= `DRAMREQ_READY;
			    if (dram1 != `DRAMSLOT_AVAIL && dram1_addr[AMSB:5]==vadr[AMSB:5]) dram1 <= `DRAMSLOT_BUSY;
		  	end
		  endcase
		else begin
			dram0 <= `DRAMREQ_READY;
		end
    bstate <= BIDLE;
  end

B_RMWAck:
  if (ack_i|err_i|tlb_miss|rdv_i) begin
    if (isCAS) begin
	     iq_res	[ casid[`QBITS] ] <= (dat_i == cas);
         iq_exc [ casid[`QBITS] ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
//             iq_done[ casid[`QBITS] ] <= `VAL;
//    	     iq_out [ casid[`QBITS] ] <= `INV;
	     iq_state [ casid[`QBITS] ] <= IQS_DONE;
	     iq_instr[ casid[`QBITS]] <= `NOP_INSN;
	    if (err_i | rdv_i)
	    	iq_ma[casid[`QBITS]] <= vadr;
      if (dat_i == cas) begin
        dstb <= `LOW;
        dwe <= `TRUE;
        bstate <= B15;
				check_abort_load();
      end
      else begin
				cas <= dat_i;
				dcyc <= `LOW;
				dstb <= `LOW;
				case(bwhich)
				2'b00:   dram0 <= `DRAMREQ_READY;
				2'b01:   dram1 <= `DRAMREQ_READY;
				default:    ;
				endcase
				bstate <= B_LSNAck;
				check_abort_load();
      end
    end
    else if (isRMW) begin
	     rmw_instr <= iq_instr[casid[`QBITS]];
	     rmw_argA <= dat_i;
    	 if (isSpt) begin
    	 	rmw_argB <= 64'd1 << iq_argA[casid[`QBITS]][63:58];
    	 	rmw_argC <= iq_instr[casid[`QBITS]][5:0]==`R2 ?
    	 				iq_argC[casid[`QBITS]][64] << iq_argA[casid[`QBITS]][63:58] :
    	 				iq_argB[casid[`QBITS]][64] << iq_argA[casid[`QBITS]][63:58];
    	 end
    	 else if (isInc) begin
    	 	rmw_argB <= iq_instr[casid[`QBITS]][5:0]==`R2 ? {{59{iq_instr[casid[`QBITS]][22]}},iq_instr[casid[`QBITS]][22:18]} :
    	 														 {{59{iq_instr[casid[`QBITS]][17]}},iq_instr[casid[`QBITS]][17:13]};
     	 end
    	 else begin // isAMO
  	     iq_res [ casid[`QBITS] ] <= dat_i;
  	     rmw_argB <= iq_instr[casid[`QBITS]][31] ? {{59{iq_instr[casid[`QBITS]][20:16]}},iq_instr[casid[`QBITS]][20:16]} : iq_argB[casid[`QBITS]];
       end
         iq_exc [ casid[`QBITS] ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
         dstb <= `LOW;
         bstate <= B20;
				check_abort_load();
		end
  end

// Regular load
B_DLoadAck:
  if (ack_i|err_i|tlb_miss|rdv_i) begin
  	wb_nack();
		sr_o <= `LOW;
		case(dccnt)
		2'd0:	xdati[127:0] <= dat_i;
		2'd1:	xdati[199:128] <= dat_i[71:0];
		endcase
    case(bwhich)
    2'b00:  begin
           		dram0 <= `DRAMREQ_READY;
             	if (iq_stomp[dram0_id[`QBITS]])
             		iq_exc [dram0_id[`QBITS]] <= `FLT_NONE;
             	else
             		iq_exc [ dram0_id[`QBITS] ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
            end
    2'b01:  if (`NUM_MEM > 1) begin
             dram1 <= `DRAMREQ_READY;
             	if (iq_stomp[dram1_id[`QBITS]])
             		iq_exc [dram1_id[`QBITS]] <= `FLT_NONE;
             	else
	             iq_exc [ dram1_id[`QBITS] ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
            end
    default:    ;
    endcase
		bstate <= B_LSNAck;
		check_abort_load();
	end
B_DLoadNack:
	if (~ack_i) begin
		dstb <= `HIGH;
		bstate <= B_DLoadAck;
		check_abort_load();
	end

// Three cycles to detemrine if there's a cache hit during a store.
B16:
	begin
    case(bwhich)
    2'd0:      if (dhit0) begin  dram0 <= `DRAMREQ_READY; bstate <= B17; end
    2'd1:      if (dhit1) begin  dram1 <= `DRAMREQ_READY; bstate <= B17; end
    default:    bstate <= BIDLE;
    endcase
		check_abort_load();
  end
B17:
	begin
    bstate <= B18;
		check_abort_load();
  end
B18:
	begin
  	bstate <= B_LSNAck;
		check_abort_load();
	end
B_LSNAck:
	begin
		bstate <= BIDLE;
		StoreAck1 <= `FALSE;
		isStore <= `FALSE;
		check_abort_load();
	end
B20:
	if (~ack_i) begin
		stb_o <= `HIGH;
		we  <= `HIGH;
		if (bwhich==2'b01)
			ddat <= rmw_res >> (5'd16 - {dram1_addr[3:0],3'b0});
		else
			ddat <= rmw_res >> (5'd16 - {dram0_addr[3:0],3'b0});
		bstate <= B_StoreAck;
		check_abort_load();
	end
B21:
	if (~ack_i) begin
		dstb <= `HIGH;
		bstate <= B_RMWAck;
		check_abort_load();
	end
default:     bstate <= BIDLE;
endcase

if (!branchmiss) begin
  case({slot0v, slot1v, slot2v})
  3'b000:	;
  3'b001:
    if (canq1) begin
     	tail0 <= (tail0+2'd1) % QENTRIES;
     	tail1 <= (tail1+2'd1) % QENTRIES;
     	tail2 <= (tail2+2'd1) % QENTRIES;
    end
  3'b010:
    if (canq1) begin
     	tail0 <= (tail0+2'd1) % QENTRIES;
     	tail1 <= (tail1+2'd1) % QENTRIES;
     	tail2 <= (tail2+2'd1) % QENTRIES;
    end
  3'b011:
    if (canq1) begin
      if (IsBranch(Unit1(ibundle[127:120]),insn1) && predict_taken1) begin
       	tail0 <= (tail0+2'd1) % QENTRIES;
       	tail1 <= (tail1+2'd1) % QENTRIES;
	     	tail2 <= (tail2+2'd1) % QENTRIES;
      end
      else begin
        if (canq2) begin
          tail0 <= (tail0 + 3'd2) % QENTRIES;
          tail1 <= (tail1 + 3'd2) % QENTRIES;
		     	tail2 <= (tail2 + 3'd2) % QENTRIES;
        end
        else begin    // queued1 will be true
         	tail0 <= (tail0+2'd1) % QENTRIES;
			   	tail1 <= (tail1+2'd1) % QENTRIES;
		     	tail2 <= (tail2+2'd1) % QENTRIES;
        end
      end
    end
  3'b100:
    if (canq1) begin
     	tail0 <= (tail0+2'd1) % QENTRIES;
     	tail1 <= (tail1+2'd1) % QENTRIES;
     	tail2 <= (tail2+2'd1) % QENTRIES;
    end
  3'b101:
    if (canq1) begin
      if (IsBranch(Unit0(ibundle[127:120]),insn0) && predict_taken0) begin
       	tail0 <= (tail0+2'd1) % QENTRIES;
       	tail1 <= (tail1+2'd1) % QENTRIES;
	     	tail2 <= (tail2+2'd1) % QENTRIES;
      end
      else begin
        if (canq2) begin
          tail0 <= (tail0 + 3'd2) % QENTRIES;
          tail1 <= (tail1 + 3'd2) % QENTRIES;
		     	tail2 <= (tail2 + 3'd2) % QENTRIES;
        end
        else begin    // queued1 will be true
         	tail0 <= (tail0+2'd1) % QENTRIES;
			   	tail1 <= (tail1+2'd1) % QENTRIES;
		     	tail2 <= (tail2+2'd1) % QENTRIES;
        end
      end
    end
  3'b110:
    if (canq1) begin
      if (IsBranch(Unit0(ibundle[127:120]),insn0) && predict_taken0) begin
       	tail0 <= (tail0+2'd1) % QENTRIES;
       	tail1 <= (tail1+2'd1) % QENTRIES;
	     	tail2 <= (tail2+2'd1) % QENTRIES;
      end
      else begin
        if (canq2) begin
          tail0 <= (tail0 + 3'd2) % QENTRIES;
          tail1 <= (tail1 + 3'd2) % QENTRIES;
		     	tail2 <= (tail2 + 3'd2) % QENTRIES;
        end
        else begin    // queued1 will be true
         	tail0 <= (tail0+2'd1) % QENTRIES;
			   	tail1 <= (tail1+2'd1) % QENTRIES;
		     	tail2 <= (tail2+2'd1) % QENTRIES;
        end
      end
    end
  3'b111:
    if (canq1) begin
      if (IsBranch(Unit0(ibundle[127:120]),insn0) && predict_taken0) begin
       	tail0 <= (tail0+2'd1) % QENTRIES;
       	tail1 <= (tail1+2'd1) % QENTRIES;
	     	tail2 <= (tail2+2'd1) % QENTRIES;
      end
      else begin
      	if (canq2) begin
		      if (IsBranch(Unit1(ibundle[127:120]),insn1) && predict_taken1) begin
		       	tail0 <= (tail0+2'd2) % QENTRIES;
		       	tail1 <= (tail1+2'd2) % QENTRIES;
			     	tail2 <= (tail2+2'd2) % QENTRIES;
		      end
		      else begin
		      	if (canq3) begin
		          tail0 <= (tail0 + 3'd3) % QENTRIES;
		          tail1 <= (tail1 + 3'd3) % QENTRIES;
				     	tail2 <= (tail2 + 3'd3) % QENTRIES;
		      	end
		        else if (canq2) begin
		          tail0 <= (tail0 + 3'd2) % QENTRIES;
		          tail1 <= (tail1 + 3'd2) % QENTRIES;
				     	tail2 <= (tail2 + 3'd2) % QENTRIES;
		        end
		        else begin    // queued1 will be true
		         	tail0 <= (tail0+2'd1) % QENTRIES;
					   	tail1 <= (tail1+2'd1) % QENTRIES;
				     	tail2 <= (tail2+2'd1) % QENTRIES;
		        end
	      	end
      	end
      	else begin
	       	tail0 <= (tail0+2'd1) % QENTRIES;
	       	tail1 <= (tail1+2'd1) % QENTRIES;
		     	tail2 <= (tail2+2'd1) % QENTRIES;
      	end
      end
    end
  endcase
end
else begin	// if branchmiss
	for (n = QENTRIES-1; n >= 0; n = n - 1)
		// (QENTRIES-1) is needed to ensure that n increments forwards so that the modulus is
		// a positive number.
		if (iq_stomp[n] & ~iq_stomp[(n+(QENTRIES-1))%QENTRIES]) begin
			tail0 <= n;
			tail1 <= (n + 1) % QENTRIES;	
			tail2 <= (n + 2) % QENTRIES;
		end
    // otherwise, it is the last instruction in the queue that has been mispredicted ... do nothing
end

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
	for (i=0; i<QENTRIES; i=i+1) 
	    $display("%c%c %d: %c%c%c%c %d %d %c%c %c %c%h %d %o %h %h %h %d %o %h %d %o %h %d %o %d:%h %h %d#",
		 (i[`QBITS]==heads[0])?"C":".",
		 (i[`QBITS]==tail0)?"Q":".",
		  i[`QBITS],
		  iq_state[i]==IQS_INVALID ? "-" :
		  iq_state[i]==IQS_QUEUED ? "Q" :
		  iq_state[i]==IQS_OUT ? "O"  :
		  iq_state[i]==IQS_AGEN ? "A"  :
		  iq_state[i]==IQS_MEM ? "M"  :
		  iq_state[i]==IQS_DONE ? "D"  :
		  iq_state[i]==IQS_CMT ? "C"  : "?",
//		 iq_v[i] ? "v" : "-",
		 iq_iv[i] ? "I" : "-",
		 iq_done[i]?"d":"-",
		 iq_out[i]?"o":"-",
		 iq_bt[i],
		 iq_memissue[i],
		 iq_agen[i] ? "a": "-",
		 iq_alu0_issue[i]?"0":iq_alu1_issue[i]?"1":"-",
		 iq_stomp[i]?"s":"-",
		iq_fc[i] ? "F" : iq_mem[i] ? "M" : (iq_alu[i]==1'b1) ? "a" : (iq_alu[i]==1'bx) ? "X" : iq_fpu[i] ? "f" : "O", 
		iq_instr[i], iq_tgt[i][4:0],
		iq_exc[i], iq_res[i], iq_a0[i], iq_a1[i], iq_a1_v[i],
		iq_a1_s[i],
		iq_a2[i], iq_a2_v[i], iq_a2_s[i],
		iq_a3[i], iq_a3_v[i], iq_a3_s[i],
		iq_thrd[i],
		iq_pc[i],
		iq_sn[i], iq_ven[i]
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
	$display("%d %h %o #", dramA_v, dramA_bus, dramA_id);
	if (`NUM_MEM > 1)
	$display("%d %h %o #", dramB_v, dramB_bus, dramB_id);
	if (`NUM_MEM > 2)
	$display("%d %h %o #", dramC_v, dramC_bus, dramC_id);
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
                 iq_instr[n][`INSTRUCTION_OP] <= `NOP;
                 iq_done[n] <= iq_v[n];
                 iq_cmt[n] <= iq_v[n];
            end
        end
*/
	rf_source[ 0] <= {`QBIT{1'b1}};
	

end	// end of clock domain

// ============================================================================
// ============================================================================
// Start of Tasks
// ============================================================================
// ============================================================================

task check_abort_load;
begin
  case(bwhich)
  2'd0:	if (iq_stomp[dram0_id[`QBITS]]) begin bstate <= BIDLE; dram0 <= `DRAMREQ_READY; end
  2'd1:	if (iq_stomp[dram1_id[`QBITS]]) begin bstate <= BIDLE; dram1 <= `DRAMREQ_READY; end
  default:	if (iq_stomp[dram0_id[`QBITS]]) begin bstate <= BIDLE; dram0 <= `DRAMREQ_READY; end
  endcase
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
    	I = I + iq_v[heads[0]] + iq_v[heads[1]] + iq_v[heads[2]];
    	iq_state[heads[0]] <= IQS_INVALID;
    	iq_state[heads[1]] <= IQS_INVALID;
    	iq_state[heads[2]] <= IQS_INVALID;
    	iq_mem[heads[0]] <= `FALSE;
    	iq_mem[heads[1]] <= `FALSE;
    	iq_mem[heads[2]] <= `FALSE;
    	iq_iv[heads[0]] <= `INV;
    	iq_iv[heads[1]] <= `INV;
    	iq_iv[heads[2]] <= `INV;
    	iq_alu[heads[0]] <= `FALSE;
    	iq_alu[heads[1]] <= `FALSE;
    	iq_alu[heads[2]] <= `FALSE;
  		for (n = 0; n < QENTRIES; n = n + 1)
  			if (iq_v[n])
  				iq_sn[n] <= iq_sn[n] - (iq_v[heads[2]] ? iq_sn[heads[2]]
  																			 : iq_v[heads[1]] ? iq_sn[heads[1]]
  																			 : iq_v[heads[0]] ? iq_sn[heads[0]]
  																			 : 4'b0);
   	end 
    else if (amt==3'd2) begin
    	I = I + iq_v[heads[0]] + iq_v[heads[1]];
    	iq_state[heads[0]] <= IQS_INVALID;
    	iq_state[heads[1]] <= IQS_INVALID;
     iq_mem[heads[0]] <= `FALSE;
     iq_mem[heads[1]] <= `FALSE;
     iq_iv[heads[0]] <= `INV;
     iq_iv[heads[1]] <= `INV;
    	iq_alu[heads[0]] <= `FALSE;
     iq_alu[heads[1]] <= `FALSE;
  		for (n = 0; n < QENTRIES; n = n + 1)
  			if (iq_v[n])
  				iq_sn[n] <= iq_sn[n] - (iq_v[heads[1]] ? iq_sn[heads[1]]
  																			 : iq_v[heads[0]] ? iq_sn[heads[0]]
  																			 : 4'b0);
    end else if (amt==3'd1) begin
    	I = I + iq_v[heads[0]];
    	iq_state[heads[0]] <= IQS_INVALID;
	    iq_mem[heads[0]] <= `FALSE;
     	iq_iv[heads[0]] <= `INV;
    	iq_alu[heads[0]] <= `FALSE;
  		for (n = 0; n < QENTRIES; n = n + 1)
   			if (iq_v[n])
  				iq_sn[n] <= iq_sn[n] - (iq_v[heads[0]] ? iq_sn[heads[0]]
  																			 : 4'b0);
	end
end
endtask

task setargs;
input [`QBITS] nn;
input [`QBITSP1] id;
input v;
input [79:0] bus;
begin
  if (iq_argA_v[nn] == `INV && iq_argA_s[nn] == id && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argA[nn] <= bus;
		iq_argA_v[nn] <= `VAL;
  end
  if (iq_argB_v[nn] == `INV && iq_argB_s[nn] == id && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argB[nn] <= bus;
		iq_argB_v[nn] <= `VAL;
  end
  if (iq_argC_v[nn] == `INV && iq_argC_s[nn] == id && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argC[nn] <= bus;
		iq_argC_v[nn] <= `VAL;
  end
end
endtask

task arg_vs_011;
begin
	// if there is not an overlapping write to the register file.
	if (Ra2 != (Rd1 || !slot1_rfw)) begin
		iq_argA_v [tail1] <= regIsValid[Ra2];
		iq_argA_s [tail1] <= rf_source [Ra2];
	end
	else begin
		iq_argA_v [tail1] <= `INV;
		iq_argA_s [tail1] <= { 1'b0, slot1_mem, tail0 };
	end

	if (Rb2 != (Rd1 || !slot1_rfw)) begin
		iq_argB_v [tail1] <= regIsValid[Rb2];
		iq_argB_s [tail1] <= rf_source [Rb2];
	end
	else begin
		iq_argB_v [tail1] <= `INV;
		iq_argB_s [tail1] <= { 1'b0, slot1_mem, tail0 };
	end

	if (Rc2 != (Rd1 || !slot1_rfw)) begin
		iq_argC_v [tail1] <= regIsValid[Rc2];
		iq_argC_s [tail1] <= rf_source [Rc2];
	end
	else begin
		iq_argC_v [tail1] <= `INV;
		iq_argC_s [tail1] <= { 1'b0, slot1_mem, tail0 };
	end
end
endtask

task arg_vs_101;
begin
	// if there is not an overlapping write to the register file.
	if (Ra2 != (Rd0 || !slot0_rfw)) begin
		iq_argA_v [tail1] <= regIsValid[Ra2];
		iq_argA_s [tail1] <= rf_source [Ra2];
	end
	else begin	// Ra1 must be equal to Rt0 then
		iq_argA_v [tail1] <= `INV;
		iq_argA_s [tail1] <= { 1'b0, slot0_mem, tail0 };
	end

	if (Rb2 != (Rd0 || !slot0_rfw)) begin
		iq_argB_v [tail1] <= regIsValid[Rb2];
		iq_argB_s [tail1] <= rf_source [Rb2];
	end
	else begin	// Ra1 must be equal to Rt0 then
		iq_argB_v [tail1] <= `INV;
		iq_argB_s [tail1] <= { 1'b0, slot0_mem, tail0 };
	end

	if (Rc2 != (Rd0 || !slot0_rfw)) begin
		iq_argC_v [tail1] <= regIsValid[Rc2];
		iq_argC_s [tail1] <= rf_source [Rc2];
	end
	else begin	// Ra1 must be equal to Rt0 then
		iq_argC_v [tail1] <= `INV;
		iq_argC_s [tail1] <= { 1'b0, slot0_mem, tail0 };
	end
end
endtask

task arg_vs_110;
begin
	// if there is not an overlapping write to the register file.
	if (Ra1 != (Rd0 || !slot0_rfw)) begin
		iq_argA_v [tail1] <= regIsValid[Ra1];
		iq_argA_s [tail1] <= rf_source [Ra1];
	end
	else begin	// Ra1 must be equal to Rt0 then
		iq_argA_v [tail1] <= `INV;
		iq_argA_s [tail1] <= { 1'b0, slot0_mem, tail0 };
	end

	if (Rb1 != (Rd0 || !slot0_rfw)) begin
		iq_argB_v [tail1] <= regIsValid[Rb1];
		iq_argB_s [tail1] <= rf_source [Rb1];
	end
	else begin	// Ra1 must be equal to Rt0 then
		iq_argB_v [tail1] <= `INV;
		iq_argB_s [tail1] <= { 1'b0, slot0_mem, tail0 };
	end

	if (Rc1 != (Rd0 || !slot0_rfw)) begin
		iq_argC_v [tail1] <= regIsValid[Rc1];
		iq_argC_s [tail1] <= rf_source [Rc1];
	end
	else begin	// Ra1 must be equal to Rt0 then
		iq_argC_v [tail1] <= `INV;
		iq_argC_s [tail1] <= { 1'b0, slot0_mem, tail0 };
	end
end
endtask

task arg_vs_111;
begin
	// if there is not an overlapping write to the register file.
	if (Ra1 != (Rd0 || !slot0_rfw)) begin
		iq_argA_v [tail1] <= regIsValid[Ra1];
		iq_argA_s [tail1] <= rf_source [Ra1];
	end
	else begin	// Ra1 must be equal to Rt0 then
		iq_argA_v [tail1] <= `INV;
		iq_argA_s [tail1] <= { 1'b0, slot0_mem, tail0 };
	end
	// if there is not an overlapping write to the register file.
	if (Ra2 != (Rd0 || !slot0_rfw) && Ra2 != (Rd1 || !slot1_rfw)) begin
		iq_argA_v [tail2] <= regIsValid[Ra2];
		iq_argA_s [tail2] <= rf_source [Ra2];
	end
	else if (Ra2 != (Rd0 || !slot0_rfw)) begin	// Ra2 must be equal to Rt1 then
		iq_argA_v [tail2] <= `INV;
		iq_argA_s [tail2] <= { 1'b0, slot1_mem, tail1 };
	end
	else if (Ra2 != (Rd1 || !slot1_rfw)) begin	// Ra2 must be equal to Rt0 then
		iq_argA_v [tail2] <= `INV;
		iq_argA_s [tail2] <= { 1'b0, slot0_mem, tail0 };
	end

	// if there is not an overlapping write to the register file.
	if (Rb1 != (Rd0 || !slot0_rfw)) begin
		iq_argB_v [tail1] <= regIsValid[Rb1];
		iq_argB_s [tail1] <= rf_source [Rb1];
	end
	else begin	// Ra1 must be equal to Rt0 then
		iq_argB_v [tail1] <= `INV;
		iq_argB_s [tail1] <= { 1'b0, slot0_mem, tail0 };
	end
	// if there is not an overlapping write to the register file.
	if (Rb2 != (Rd0 || !slot0_rfw) && Rb2 != (Rd1 || !slot1_rfw)) begin
		iq_argB_v [tail2] <= regIsValid[Rb2];
		iq_argB_s [tail2] <= rf_source [Rb2];
	end
	else if (Rb2 != (Rd0 || !slot0_rfw)) begin	// Ra2 must be equal to Rt1 then
		iq_argB_v [tail2] <= `INV;
		iq_argB_s [tail2] <= { 1'b0, slot1_mem, tail1 };
	end
	else if (Rb2 != (Rd1 || !slot1_rfw)) begin	// Ra2 must be equal to Rt0 then
		iq_argB_v [tail2] <= `INV;
		iq_argB_s [tail2] <= { 1'b0, slot0_mem, tail0 };
	end

	// if there is not an overlapping write to the register file.
	if (Rc1 != (Rd0 || !slot0_rfw)) begin
		iq_argC_v [tail1] <= regIsValid[Rc1];
		iq_argC_s [tail1] <= rf_source [Rc1];
	end
	else begin	// Ra1 must be equal to Rt0 then
		iq_argC_v [tail1] <= `INV;
		iq_argC_s [tail1] <= { 1'b0, slot0_mem, tail0 };
	end
	// if there is not an overlapping write to the register file.
	if (Rc2 != (Rd0 || !slot0_rfw) && Rc2 != (Rd1 || !slot1_rfw)) begin
		iq_argC_v [tail2] <= regIsValid[Rc2];
		iq_argC_s [tail2] <= rf_source [Rc2];
	end
	else if (Rc2 != (Rd0 || !slot0_rfw)) begin	// Ra2 must be equal to Rt1 then
		iq_argC_v [tail2] <= `INV;
		iq_argC_s [tail2] <= { 1'b0, slot1_mem, tail1 };
	end
	else if (Rc2 != (Rd1 || !slot1_rfw)) begin	// Ra2 must be equal to Rt0 then
		iq_argC_v [tail2] <= `INV;
		iq_argC_s [tail2] <= { 1'b0, slot0_mem, tail0 };
	end
end
endtask


task set_insn;
input [`QBITS] nn;
input [143:0] bus;
begin
	iq_argI[nn]  <= bus[`IB_CONST];
	iq_imm  [nn]  <= bus[`IB_IMM];
	iq_cmp	 [nn]  <= bus[`IB_CMP];
	iq_tlb  [nn]  <= bus[`IB_TLB];
	iq_sz   [nn]  <= bus[`IB_SZ];
	iq_chk  [nn]  <= bus[`IB_CHK];
	iq_rex  [nn]	<= bus[`IB_REX];
	iq_jal	 [nn]  <= bus[`IB_JAL];
	iq_ret  [nn]  <= bus[`IB_RET];
	iq_irq  [nn]  <= bus[`IB_IRQ];
	iq_brk	 [nn]  <= bus[`IB_BRK];
	iq_rti  [nn]  <= bus[`IB_RTI];
	iq_bt   [nn]  <= bus[`IB_BT];
	iq_alu  [nn]  <= bus[`IB_ALU];
	iq_wait [nn]  <= bus[`IB_WAIT];
	iq_fpu  [nn]  <= bus[`IB_FPU];
	iq_fc   [nn]  <= bus[`IB_FC];
	iq_canex[nn]  <= bus[`IB_CANEX];
	iq_load [nn]  <= bus[`IB_LOAD];
	iq_preload[nn]<= bus[`IB_PRELOAD];
	iq_store[nn]  <= bus[`IB_STORE];
	iq_push [nn]  <= bus[`IB_PUSH];
	iq_oddball[nn] <= bus[`IB_ODDBALL];
	iq_memsz[nn]  <= bus[`IB_MEMSZ];
	iq_mem  [nn]  <= bus[`IB_MEM];
	iq_memndx[nn] <= bus[`IB_MEMNDX];
	iq_rmw  [nn]  <= bus[`IB_RMW];
	iq_memdb[nn]  <= bus[`IB_MEMDB];
	iq_memsb[nn]  <= bus[`IB_MEMSB];
	iq_sei	 [nn]	 <= bus[`IB_SEI];
	iq_aq   [nn]  <= bus[`IB_AQ];
	iq_rl   [nn]  <= bus[`IB_RL];
	iq_jmp  [nn]  <= bus[`IB_JMP];
	iq_br   [nn]  <= bus[`IB_BR];
	iq_sync [nn]  <= bus[`IB_SYNC];
	iq_fsync[nn]  <= bus[`IB_FSYNC];
	iq_rfw  [nn]  <= bus[`IB_RFW];
end
endtask
	
task queue_slot0;
input [`QBITS] ndx;
input [`SNBITS] seqnum;
begin
	iq_v[ndx] <= VAL;
	iq_sn[ndx] <= seqnum;
	iq_state[ndx] <= IQS_QUEUED;
	iq_ip[ndx] <= ip;
	iq_unit[ndx] <= Unit0(ibundle[124:120]);
	iq_instr[ndx] <= ibundle[39:0];
	iq_argA[ndx] <= rfoa0;
	iq_argB[ndx] <= rfob0;
	iq_argC[ndx] <= rfoc0;
	iq_argA_v[ndx] <= regIsValid[Ra0] || Source1Valid(Unit0(ibundle[124:120]),ibundle[39:0]);
	iq_argB_v[ndx] <= regIsValid[Rb0] || Source2Valid(Unit0(ibundle[124:120]),ibundle[39:0]);
	iq_argC_v[ndx] <= regIsValid[Rc0] || Source2Valid(Unit0(ibundle[124:120]),ibundle[39:0]);
	iq_argA_s[ndx] <= rf_source[Ra0];
	iq_argB_s[ndx] <= rf_source[Rb0];
	iq_argC_s[ndx] <= rf_source[Rc0];
	iq_pt[ndx] <= predict_taken0;
	iq_tgt[ndx] <= Rd0;
	iq_res[ndx] <= 80'd0;
	iq_exc[ndx] <= `FLT_NONE;
	set_insn(ndx,id0_bus);
end
endtask

task queue_slot1;
input [`QBITS] ndx;
input [`SNBITS] seqnum;
begin
	iq_v[ndx] <= VAL;
	iq_sn[ndx] <= seqnum;
	iq_state[ndx] <= IQS_QUEUED;
	iq_ip[ndx] <= ip;
	iq_unit[ndx] <= Unit1(ibundle[124:120]);
	iq_instr[ndx] <= ibundle[79:40];
	iq_argA[ndx] <= rfoa1;
	iq_argB[ndx] <= rfob1;
	iq_argC[ndx] <= rfoc1;
	iq_argA_v[ndx] <= regIsValid[Ra1] || Source1Valid(Unit1(ibundle[124:120]),ibundle[79:40]);
	iq_argB_v[ndx] <= regIsValid[Rb1] || Source2Valid(Unit1(ibundle[124:120]),ibundle[79:40]);
	iq_argC_v[ndx] <= regIsValid[Rc1] || Source2Valid(Unit1(ibundle[124:120]),ibundle[79:40]);
	iq_argA_s[ndx] <= rf_source[Ra1];
	iq_argB_s[ndx] <= rf_source[Rb1];
	iq_argC_s[ndx] <= rf_source[Rc1];
	iq_pt[ndx] <= predict_taken1;
	iq_tgt[ndx] <= Rd1;
	iq_res[ndx] <= 80'd0;
	iq_exc[ndx] <= `FLT_NONE;
	set_insn(ndx,id1_bus);
end
endtask

task queue_slot2;
input [`QBITS] ndx;
input [`SNBITS] seqnum;
begin
	iq_v[ndx] <= VAL;
	iq_sn[ndx] <= seqnum;
	iq_state[ndx] <= IQS_QUEUED;
	iq_ip[ndx] <= ip;
	iq_unit[ndx] <= Unit2(ibundle[124:120]);
	iq_instr[ndx] <= ibundle[119:80];
	iq_argA[ndx] <= rfoa2;
	iq_argB[ndx] <= rfob2;
	iq_argC[ndx] <= rfoc2;
	iq_argA_v[ndx] <= regIsValid[Ra2] || Source1Valid(Unit2(ibundle[124:120]),ibundle[119:80]);
	iq_argB_v[ndx] <= regIsValid[Rb2] || Source2Valid(Unit2(ibundle[124:120]),ibundle[119:80]);
	iq_argC_v[ndx] <= regIsValid[Rc2] || Source2Valid(Unit2(ibundle[124:120]),ibundle[119:80]);
	iq_argA_s[ndx] <= rf_source[Ra2];
	iq_argB_s[ndx] <= rf_source[Rb2];
	iq_argC_s[ndx] <= rf_source[Rc2];
	iq_pt[ndx] <= predict_taken2;
	iq_tgt[ndx] <= Rd2;
	iq_res[ndx] <= 80'd0;
	iq_exc[ndx] <= `FLT_NONE;
	set_insn(ndx,id2_bus);
end
endtask

task exc;
input [`QBITS] head;
input thread;
input [7:0] causecd;
begin
  excmiss <= TRUE;
 	excmisspc <= {tvec[3'd0][AMSB:8],1'b0,ol,5'h00};
  badaddr[{thread,2'd0}] <= iq_ma[head];
  bad_instr[{thread,2'd0}] <= iq_instr[head];
  im_stack <= {im_stack[27:0],4'hF};
  ol_stack <= {ol_stack[13:0],2'b00};
  dl_stack <= {dl_stack[13:0],2'b00};
  epc0 <= iq_ip[head];
  epc1 <= epc0;
  epc2 <= epc1;
  epc3 <= epc2;
  epc4 <= epc3;
  epc5 <= epc4;
  epc6 <= epc5;
  epc7 <= epc6;
  epc8 <= epc7;
  pl_stack <= {pl_stack[71:0],cpl};
  rs_stack <= {rs_stack[59:0],`EXC_RGS};
  brs_stack <= {rs_stack[59:0],`EXC_RGS};
  cause[3'd0] <= {8'd0,causecd};
  mstatus[5:4] <= 2'd0;
  mstatus[13:6] <= 8'h00;
  mstatus[19:14] <= `EXC_RGS;
	wb_en <= `TRUE;
  sema[0] <= 1'b0;
`ifdef SUPPORT_DBG            
  dbg_ctrl[62:55] <= {dbg_ctrl[61:55],dbg_ctrl[63]}; 
  dbg_ctrl[63] <= FALSE;
`endif            
end
endtask

// This task takes care of commits for things other than the register file.
task oddball_commit;
input v;
input [`QBITS] head;
input [1:0] which;
reg thread;
begin
    if (v) begin
        if (|iq_exc[head]) begin
        	exc(head,thread,iq_exc[head]);
        end
        else
        case(iq_unit[head])
        `BUnit:
					case(iq_instr[head][`OPCODE4])
					`BRK:   
        		// BRK is treated as a nop unless it's a software interrupt or a
        		// hardware interrupt at a higher priority than the current priority.
            if ((|iq_instr[head][25:21]) || iq_instr[head][20:17] > im) begin
	            excmiss <= TRUE;
              im_stack <= {im_stack[27:0],4'hF};
              ol_stack <= {ol_stack[13:0],2'b00};
              dl_stack <= {dl_stack[13:0],2'b00};
          		excmisspc <= {tvec[3'd0][AMSB:8],1'b0,ol,5'h00};
              epc0 <= iq_ip[head] + {iq_instr[head][25:21],1'b0};
              epc1 <= epc0;
              epc2 <= epc1;
              epc3 <= epc2;
              epc4 <= epc3;
              epc5 <= epc4;
              epc6 <= epc5;
              epc7 <= epc6;
              epc8 <= epc7;
              pl_stack <= {pl_stack[55:0],cpl};
              rs_stack <= {rs_stack[59:0],`BRK_RGS};
              brs_stack <= {brs_stack[59:0],`BRK_RGS};
              cause[3'd0] <= iq_res[head][7:0];
              mstatus[5:4] <= 2'd0;
              mstatus[13:6] <= 8'h00;
              // For hardware interrupts only, set a new mask level. Setting a
              // new mask level will effectively prevent subsequent brks that
              // are streaming from an interrupt from being processed.
              // Select register set according to interrupt level
              if (iq_instr[head][25:21]==5'd0) begin
                mstatus[ 3: 0] <= iq_instr[head][20:17];
                mstatus[31:28] <= iq_instr[head][20:17];
                mstatus[19:14] <= {2'b0,iq_instr[head][20:17]};
                rs_stack[5:0] <= {2'b0,iq_instr[head][20:17]};
                brs_stack[5:0] <= {2'b0,iq_instr[head][20:17]};
              end
              else begin
              	mstatus[19:14] <= `BRK_RGS;
              	rs_stack[5:0] <= `BRK_RGS;
              	brs_stack[5:0] <= `BRK_RGS;
              end
              sema[0] <= 1'b0;
`ifdef SUPPORT_DBG                    
              dbg_ctrl[62:55] <= {dbg_ctrl[61:55],dbg_ctrl[63]}; 
              dbg_ctrl[63] <= FALSE;
`endif                    
            end
           `RTI:
            case(iq_instr[head][`FUNCT5])
            `SEI:   mstatus[3:0] <= iq_res[head][3:0];   // S1
            5'd0:   begin
		            excmiss <= TRUE;
	    					excmisspc <= iq_ma[head];
//            		excmisspc <= epc0;
            		mstatus[3:0] <= im_stack[3:0];
            		mstatus[5:4] <= ol_stack[1:0];
            		mstatus[21:20] <= dl_stack[1:0];
            		mstatus[13:6] <= pl_stack[7:0];
            		mstatus[19:14] <= rs_stack[5:0];
            		im_stack <= {4'd15,im_stack[31:4]};
            		ol_stack <= {2'd0,ol_stack[15:2]};
            		dl_stack <= {2'd0,dl_stack[15:2]};
            		pl_stack <= {8'h00,pl_stack[63:8]};
            		rs_stack <= {6'h00,rs_stack[59:6]};
            		brs_stack <= {6'h00,brs_stack[59:6]};
                epc0 <= epc1;
                epc1 <= epc2;
                epc2 <= epc3;
                epc3 <= epc4;
                epc4 <= epc5;
                epc5 <= epc6;
                epc6 <= epc7;
                epc7 <= epc8;
                epc8 <= {tvec[0][AMSB:8], 1'b0, ol, 5'h0};
                sema[0] <= 1'b0;
                sema[iq_res[head][5:0]] <= 1'b0;
`ifdef SUPPORT_DBG                    
	              dbg_ctrl[62:55] <= {FALSE,dbg_ctrl[62:56]}; 
	              dbg_ctrl[63] <= dbg_ctrl[55];
`endif                    
              end
	        `REX:
            if (ol < iq_instr[head][14:13]) begin
                mstatus[5:4] <= iq_instr[head][14:13];
                badaddr[{1'b0,iq_instr[head][14:13]}] <= badaddr[{1'b0,ol}];
                bad_instr[{1'b0,iq_instr[head][14:13]}] <= bad_instr[{1'b0,ol}];
                cause[{1'b0,iq_instr[head][14:13]}] <= cause[{1'b0,ol}];
                mstatus[13:6] <= iq_instr[head][25:18] | iq_argA[head][7:0];
            end
            default: ;
            endcase
           default:	;
          endcase
        `MStUnit:
        	case(iq_instr[head][`OPCODE4])
        	`MSX:
            case(iq_instr[head][`FUNCT5])
            `CACHE:
                    case(iq_instr[head][22:18])
				            5'h02:	begin invicl <= TRUE; invlineAddr <= {ASID,iq_res[head]}; end
                    5'h03:  invic <= TRUE;
                    5'h10:  cr0[30] <= FALSE;
                    5'h11:  cr0[30] <= TRUE;
                    default:    ;
                    endcase
            default: ;
            endcase
        `CACHE:
            case(iq_instr[head][17:13])
            5'h02:	begin invicl <= TRUE; invlineAddr <= {iq_res[head]}; end
            5'h03:  invic <= TRUE;
            5'h10:  cr0[30] <= FALSE;
            5'h11:  cr0[30] <= TRUE;
            default:    ;
            endcase
          default:	;
          endcase
        `IUnit:
        	case({iq_instr[head][32:31],iq_instr[head][`OPCODE4]})
        `CSRRW:
        		begin
        		write_csr(iq_instr[head][31:18],iq_argA[head],thread);
        		end
        		default:	;
        		endcase
        `FUnit:
            case(iq_instr[head][`OPCODE4])
            `FLT2:
							case(iq_instr[head][27:22])
							`FRM: begin  
										fp_rm <= iq_res[head][2:0];
										end
            `FCX:
                begin
                    fp_sx <= fp_sx & ~iq_res[head][5];
                    fp_inex <= fp_inex & ~iq_res[head][4];
                    fp_dbzx <= fp_dbzx & ~(iq_res[head][3]|iq_res[head][0]);
                    fp_underx <= fp_underx & ~iq_res[head][2];
                    fp_overx <= fp_overx & ~iq_res[head][1];
                    fp_giopx <= fp_giopx & ~iq_res[head][0];
                    fp_infdivx <= fp_infdivx & ~iq_res[head][0];
                    fp_zerozerox <= fp_zerozerox & ~iq_res[head][0];
                    fp_subinfx   <= fp_subinfx   & ~iq_res[head][0];
                    fp_infzerox  <= fp_infzerox  & ~iq_res[head][0];
                    fp_NaNCmpx   <= fp_NaNCmpx   & ~iq_res[head][0];
                    fp_swtx <= 1'b0;
                end
            `FDX:
                begin
                    fp_inexe <= fp_inexe     & ~iq_res[head][4];
                    fp_dbzxe <= fp_dbzxe     & ~iq_res[head][3];
                    fp_underxe <= fp_underxe & ~iq_res[head][2];
                    fp_overxe <= fp_overxe   & ~iq_res[head][1];
                    fp_invopxe <= fp_invopxe & ~iq_res[head][0];
                end
            `FEX:
                begin
                    fp_inexe <= fp_inexe     | iq_res[head][4];
                    fp_dbzxe <= fp_dbzxe     | iq_res[head][3];
                    fp_underxe <= fp_underxe | iq_res[head][2];
                    fp_overxe <= fp_overxe   | iq_res[head][1];
                    fp_invopxe <= fp_invopxe | iq_res[head][0];
                end
              default:	;
              endcase
            default:
                begin
                    // 31 to 29 is rounding mode
                    // 28 to 24 are exception enables
                    // 23 is nsfp
                    // 22 is a fractie
                    fp_fractie <= iq_ares[head][22];
                    fp_raz <= iq_ares[head][21];
                    // 20 is a 0
                    fp_neg <= iq_ares[head][19];
                    fp_pos <= iq_ares[head][18];
                    fp_zero <= iq_ares[head][17];
                    fp_inf <= iq_ares[head][16];
                    // 15 swtx
                    // 14 
                    fp_inex <= fp_inex | (fp_inexe & iq_ares[head][14]);
                    fp_dbzx <= fp_dbzx | (fp_dbzxe & iq_ares[head][13]);
                    fp_underx <= fp_underx | (fp_underxe & iq_ares[head][12]);
                    fp_overx <= fp_overx | (fp_overxe & iq_ares[head][11]);
                    //fp_giopx <= fp_giopx | (fp_giopxe & iq_res2[head][10]);
                    //fp_invopx <= fp_invopx | (fp_invopxe & iq_res2[head][24]);
                    //
                    fp_cvtx <= fp_cvtx |  (fp_giopxe & iq_ares[head][7]);
                    fp_sqrtx <= fp_sqrtx |  (fp_giopxe & iq_ares[head][6]);
                    fp_NaNCmpx <= fp_NaNCmpx |  (fp_giopxe & iq_ares[head][5]);
                    fp_infzerox <= fp_infzerox |  (fp_giopxe & iq_ares[head][4]);
                    fp_zerozerox <= fp_zerozerox |  (fp_giopxe & iq_ares[head][3]);
                    fp_infdivx <= fp_infdivx | (fp_giopxe & iq_ares[head][2]);
                    fp_subinfx <= fp_subinfx | (fp_giopxe & iq_ares[head][1]);
                    fp_snanx <= fp_snanx | (fp_giopxe & iq_ares[head][0]);

                end
            endcase
        default:    ;
        endcase
        // Once the flow control instruction commits, NOP it out to allow
        // pending stores to be issued.
        iq_unit[head] <= `BUnit;
        iq_instr[head] <= `NOP_INSN;
    end
end
endtask

task write_csr;
input [13:0] csrno;
input [79:0] dat;
input thread;
begin
    if (csrno[11:10] >= ol)
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
//        `CSR_WBRCD:		wbrcd <= dat;
        `CSR_SEMA:      sema <= dat;
        `CSR_KEYS:	keys <= dat;
        `CSR_TCB:		tcb <= dat;
        `CSR_FSTAT:		fpu_csr[37:32] <= dat[37:32];
        `CSR_BADADR:    badaddr[{thread,csrno[11:10]}] <= dat;
        `CSR_BADINSTR:	bad_instr[{thread,csrno[11:10]}] <= dat;
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
        `CSR_IM_STACK:	im_stack <= dat[31:0];
        `CSR_ODL_STACK:	begin
        								ol_stack <= dat[15:0];
        								dl_stack <= dat[47:32];
        								end
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
`ifdef SUPPORT_BBMS
				`CSR_TB:			prg_base[brgs] <= dat;
				`CSR_CBL:			cl_barrier[brgs] <= dat;
				`CSR_CBU:			cu_barrier[brgs] <= dat;
				`CSR_RO:			ro_barrier[brgs] <= dat;
				`CSR_DBL:			dl_barrier[brgs] <= dat;
				`CSR_DBU:			du_barrier[brgs] <= dat;
				`CSR_SBL:			sl_barrier[brgs] <= dat;
				`CSR_SBU:			su_barrier[brgs] <= dat;
				`CSR_ENU:			en_barrier[brgs] <= dat;
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
//        `CSR_WBRCD:		wbrcd <= wbrcd | dat;
`ifdef SUPPORT_DBG        
        `CSR_DBCTRL:    dbg_ctrl <= dbg_ctrl | dat;
`endif        
        `CSR_SEMA:      sema <= sema | dat;
        `CSR_STATUS:    mstatus[63:0] <= mstatus[63:0] | dat;
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
//        `CSR_WBRCD:		wbrcd <= wbrcd & ~dat;
`ifdef SUPPORT_DBG        
        `CSR_DBCTRL:    dbg_ctrl <= dbg_ctrl & ~dat;
`endif        
        `CSR_SEMA:      sema <= sema & ~dat;
        `CSR_STATUS:    mstatus[63:0] <= mstatus[63:0] & ~dat;
        default:    ;
        endcase
    default:    ;
    endcase
end
endtask

task tDram0Issue;
input [`QBITSP1] n;
begin
	if (iq_state[n]==IQS_AGEN) begin
//	dramA_v <= `INV;
		dram0 		<= `DRAMSLOT_BUSY;
		dram0_id 	<= { 1'b1, n[`QBITS] };
		dram0_instr <= iq_instr[n];
		dram0_rmw  <= iq_rmw[n];
		dram0_preload <= iq_preload[n];
		dram0_tgt 	<= iq_tgt[n];
		if (iq_imm[n] & iq_push[n])
			dram0_data <= iq_argI[n];
		else
			dram0_data <= iq_argB[n];
		dram0_addr	<= iq_ma[n];
		dram0_unc   <= iq_ma[n][31:20]==12'hFFD || !dce;
		dram0_memsize <= iq_memsz[n];
		dram0_load <= iq_load[n];
		dram0_store <= iq_store[n];
		dram0_ol   <= (iq_Ra[n][RBIT:0]==6'd63 || iq_Ra[n][RBIT:0]==6'd62) ? ol : dl;
	// Once the memory op is issued reset the a1_v flag.
	// This will cause the a1 bus to look for new data from memory (a1_s is pointed to a memory bus)
	// This is used for the load and compare instructions.
	// must reset the a1 source too.
	//iq_a1_v[n] <= `INV;
		iq_state[n] <= IQS_MEM;
	end
end
endtask

task tDram1Issue;
input [`QBITSP1] n;
begin
	if (iq_state[n]==IQS_AGEN) begin
//	dramB_v <= `INV;
	dram1 		<= `DRAMSLOT_BUSY;
	dram1_id 	<= { 1'b1, n[`QBITS] };
	dram1_instr <= iq_instr[n];
	dram1_rmw  <= iq_rmw[n];
	dram1_preload <= iq_preload[n];
	dram1_tgt 	<= iq_tgt[n];
	if (iq_imm[n] & iq_push[n])
		dram1_data <= iq_argI[n];
	else
		dram1_data <= iq_argB[n];
	dram1_addr	<= iq_ma[n];
	//	             if (ol[iq_thrd[n]]==`OL_USER)
	//	             	dram1_seg   <= (iq_Ra[n]==5'd30 || iq_Ra[n]==5'd31) ? {ss[iq_thrd[n]],13'd0} : {ds[iq_thrd[n]],13'd0};
	//	             else
	dram1_unc   <= iq_ma[n][31:20]==12'hFFD || !dce;
	dram1_memsize <= iq_memsz[n];
	dram1_load <= iq_load[n];
	dram1_store <= iq_store[n];
	dram1_ol   <= (iq_Ra[n][RBIT:0]==6'd63 || iq_Ra[n][RBIT:0]==6'd62) ? ol : dl;
	//iq_a1_v[n] <= `INV;
	iq_state[n] <= IQS_MEM;
	end
end
endtask

task wb_nack;
begin
	dcti <= 3'b000;
	dbte <= 2'b00;
	dcyc <= `LOW;
	dstb <= `LOW;
	dwe <= `LOW;
	dsel <= 8'h00;
//	vadr <= 32'hCCCCCCCC;
end
endtask


endmodule

module decoder6 (num, out);
input [5:0] num;
output [63:1] out;

wire [63:0] out1;

assign out1 = 64'd1 << num;
assign out = out1[63:1];

endmodule

