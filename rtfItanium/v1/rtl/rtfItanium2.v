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
`include "rtfItanium-config.vh"
`include "rtfItanium-defines.vh"

module rtfItanium2(hartid_i, rst_i, clk_i, tm_clk_i, irq_i, cause_i, 
		bte_o, cti_o, bok_i, cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_o, dat_i,
    ol_o, pcr_o, pcr2_o, pkeys_o, icl_o, sr_o, cr_o, rbi_i, signal_i, exc_o);
input [79:0] hartid_i;
input rst;
input clk_i;
input clk4x;
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

parameter QENTRIES = 5;
parameter AREGS = 64;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter RSTPC = 80'hFFFFFFFFFFFFFFFC0100;
parameter BRKPC = 80'hFFFFFFFFFFFFFFFC0000;
parameter DEBUG = 1'b0;
parameter DBW = 80;
parameter ABW = 80;
parameter AMSB = ABW-1;
parameter RBIT = 5;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
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

`include "rtfItanium-bus_states.v"

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
reg [127:0] imem [0:12287];
initial begin
`include "d:/cores6/rtfItanium/v1/software/boot/boot.ve0"
end

reg [7:0] i;
integer n;
integer j, k;
genvar g, h;

reg [AMSB:0] ip, rip;
reg [1:0] slot;
wire [63:0] slot0ip = {ip[63:4],4'h0};
wire [63:0] slot1ip = {ip[63:4],4'h5};
wire [63:0] slot2ip = {ip[63:4],4'hA};

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
assign rgs = rs_stack[5:0];
assign brgs = brs_stack[5:0];
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

reg [127:0] xdati;

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
reg [QENTRIES-1:0] iq_rex;
reg [QENTRIES-1:0] iq_sync;  // sync instruction
reg [QENTRIES-1:0] iq_fsync;
reg [QENTRIES-1:0] iq_tlb;
reg [QENTRIES-1:0] iq_cmp;
reg [QENTRIES-1:0] iq_rfw = 1'b0;	// writes to register file
reg [WID-1:0] iq_res	[0:QENTRIES-1];	// instruction result
reg [2:0] iq_unit[0:QENTRIES-1];
reg [39:0] iq_instr[0:QENTRIES-1];	// instruction opcode
reg  [7:0] iq_exc	[0:QENTRIES-1];	// only for branches ... indicates a HALT instruction
reg [RBIT:0] iq_tgt[0:QENTRIES-1];	// Rt field or ZERO -- this is the instruction's target (if any)
reg [AMSB:0] iq_ma [0:QENTRIES-1];	// memory address
reg [WID-1:0] iq_argI	[0:QENTRIES-1];	// argument 0 (immediate)
reg [WID-1:0] iq_argA	[0:QENTRIES-1];	// argument 1
reg [QENTRIES-1:0] iq_argA_v;	// arg1 valid
reg [`QBITSP1] iq_aegA_s	[0:QENTRIES-1];	// arg1 source (iq entry # with top bit representing ALU/DRAM bus)
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

reg [PREGS-1:1] livetarget;
reg [PREGS-1:1] iq_livetarget [0:QENTRIES-1];
reg [PREGS-1:1] iq_latestID [0:QENTRIES-1];
reg [PREGS-1:1] iq_cumulative [0:QENTRIES-1];
wire  [PREGS-1:1] iq_out [0:QENTRIES-1];

reg  [`QBITS] tail0;
reg  [`QBITS] tail1;
reg  [`QBITS] tail2;
reg  [`QBITS] heads[0:QENTRIES-1];

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
reg [WDI-1:0] alu1_xs = 64'd0;

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

reg [WID-1:0] rmw_argA;
reg [WID-1:0] rmw_argB;
reg [WID-1:0] rmw_argC;
wire [WID-1:0] rmw_res;
reg [39:0] rmw_instr;

// write buffer
wire [WID-1:0] wb_data;
wire [`ABITS] wb_addr;
wire [1:0] wb_ol;
wire wb_v;
wire wb_rmw;
wire [QENTRIES-1:0] wb_id;
wire [QENTRIES-1:0] wbo_id;
wire [9:0] wb_sel;
reg wb_en;
wire wb_hit0, wb_hit1;

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
reg 			 dram0_loadseg;
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
reg 			 dram1_loadseg;
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

wire [127:0] ic_out;
reg invic, invdc;
reg invicl;
wire [3:0] icstate;
wire ihit;
always @*
	phit <= (ihit&&icstate==IDLE) && !invicl;

wire [79:0] L1_adr, L2_adr;
wire [257:0] L1_dat, L2_dat;
wire L1_wr, L2_wr;
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

function [2:0] Unit0;
input [4:0] tmp;
case(tmp)
5'h00:	Unit0 = IUnit;
5'h01:	Unit0 = IUnit;
5'h02:	Unit0 = IUnit;
5'h03:	Unit0 = IUnit;
5'h08:	Unit0 = IUnit;
5'h09:	Unit0 = IUnit;
5'h0A:	Unit0 = IUnit;
5'h0B:	Unit0 = IUnit;
5'h0C:	Unit0 = IUnit;
5'h0D:	Unit0 = IUnit;
5'h0E:	Unit0 = FUnit;
5'h0F:	Unit0 = FUnit;
5'h10:	Unit0 = BUnit;
5'h11:	Unit0 = BUnit;
5'h12:	Unit0 = BUnit;
5'h13:	Unit0 = BUnit;
5'h16:	Unit0 = BUnit;
5'h17:	Unit0 = BUnit;
5'h18:	Unit0 = BUnit;
5'h19:	Unit0 = BUnit;
5'h1C:	Unit0 = BUnit;
5'h1D:	Unit0 = BUnit;
default:	Unit0 = NUnit;
endcase
endfunction

function [2:0] Unit1;
input [4:0] tmp;
case(tmp)
5'h00:	Unit1 = IUnit;
5'h01:	Unit1 = IUnit;
5'h02:	Unit1 = IUnit;
5'h03:	Unit1 = IUnit;
5'h08:	Unit1 = MUnit;	
5'h09:	Unit1 = MUnit;	
5'h0A:	Unit1 = MUnit;	
5'h0B:	Unit1 = MUnit;
5'h0C:	Unit1 = FUnit;
5'h0D:	Unit1 = FUnit;
5'h0E:	Unit1 = MUnit;	
5'h0F:	Unit1 = MUnit;
5'h10:	Unit1 = IUnit;
5'h11:	Unit1 = IUnit;
5'h12:	Unit1 = BUnit;
5'h13:	Unit1 = BUnit;
5'h15:	Unit1 = BUnit;
5'h16:	Unit1 = BUnit;
5'h18:	Unit1 = MUnit;	
5'h19:	Unit1 = MUnit;
5'h1C:	Unit1 = FUnit;
5'h1D:	Unit1 = FUnit;
default:	Unit1 = NUnit;
endcase
endfunction

function [2:0] Unit2;
input [4:0] tmp;
case(tmp)
5'h00:	Unit2 = MUnit;	
5'h01:	Unit2 = MUnit;	
5'h02:	Unit2 = MUnit;	
5'h03:	Unit2 = MUnit;	
5'h04:	Unit2 = MUnit;	
5'h05:	Unit2 = MUnit;	
5'h08:	Unit2 = MUnit;	
5'h09:	Unit2 = MUnit;	
5'h0A:	Unit2 = MUnit;	
5'h0B:	Unit2 = MUnit;	
5'h0C:	Unit2 = MUnit;	
5'h0D:	Unit2 = MUnit;	
5'h0E:	Unit2 = MUnit;	
5'h0F:	Unit2 = MUnit;	
5'h10:	Unit2 = MUnit;	
5'h11:	Unit2 = MUnit;	
5'h12:	Unit2 = MUnit;	
5'h13:	Unit2 = MUnit;	
5'h16:	Unit2 = BUnit;
5'h17:	Unit2 = BUnit;	
5'h18:	Unit2 = MUnit;	
5'h19:	Unit2 = MUnit;	
5'h1C:	Unit2 = MUnit;	
5'h1D:	Unit2 = MUnit;	
default:	Unit2 = NUnit;
endcase
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

function IsFpLoad;
input [40:0] ins;
if (ins[40:37]==4'h6) begin
	case({ins[36],ins[27]})
	2'b00:
		case(ins[35:30])
		6'h00,6'h01,6'h02,6'h03,
		6'h04,6'h05,6'h06,6'h07,
		6'h08,6'h09,6'h0A,6'h0B,
		6'h0C,6'h0D,6'h0E,6'h0F:
			IsFpLoad = TRUE;
		6'h1B:
			IsFpLoad = TRUE;
		6'h20,6'h21,6'h22,6'h23,
		6'h24,6'h25,6'h26,6'h27:
			IsFpLoad = TRUE;
		default:	IsFpLoad = FALSE;
		endcase
	2'b01:
		case(ins[35:30])
		6'h01,6'h02,6'h03,
		6'h05,6'h06,6'h07,
		6'h09,6'h0A,6'h0B,
		6'h0D,6'h0E,6'h0F:
			IsFpLoad = TRUE;
		6'h1C,6'h1D,6'h1E,6'h1F:
			IsFpLoad = TRUE;
		6'h21,6'h22,6'h23,
		6'h25,6'h26,6'h27:
			IsFpLoad = TRUE;
		default:	IsFpLoad = FALSE;
		endcase
	2'b10:
		case(ins[35:30])
		6'h00,6'h01,6'h02,6'h03,
		6'h04,6'h05,6'h06,6'h07,
		6'h08,6'h09,6'h0A,6'h0B,
		6'h0C,6'h0D,6'h0E,6'h0F:
			IsFpLoad = TRUE;
		6'h1B:
			IsFpLoad = TRUE;
		6'h20,6'h21,6'h22,6'h23,
		6'h24,6'h25,6'h26,6'h27:
			IsFpLoad = TRUE;
		6'h2C,6'h2D,6'h2E,6'h2F:
			IsFpLoad = TRUE;
		default:	IsFpLoad = FALSE;
		endcase
	2'b11:
		case(ins[35:30])
		6'h01,6'h02,6'h03,
		6'h05,6'h06,6'h07,
		6'h09,6'h0A,6'h0B,
		6'h0D,6'h0E,6'h0F:
			IsFpLoad = TRUE;
		6'h21,6'h22,6'h23,
		6'h25,6'h26,6'h27:
			IsFpLoad = TRUE;
		default:	IsFpLoad = FALSE;
		endcase
	end
end
endfunction

function [6:0] InstType;
input [4:0] tmp;
input [40:0] ins;
if (IsMUnit(tmp)) begin
	case(ins[40:37])
	4'h0:	InstType = ITMemmgnt;
	4'h1: InstType = ITMemmgnt;
	4'h4:	InstType = ITIntLdReg;
	4'h5:	InstType = ITIntLdStImm;
	4'h6:	InstType = ITFpLdStReg;
	4'h7:	InstType = ITFPLdStImm;
	4'h8:	InstType = ITALU;
	4'h9: InstType = ITAdd;
	4'hC:	InstType = ITCmp;
	4'hD:	InstType = ITCmp;
	4'hE:	InstType = ITCmp;
	default:	InstType = ITUnimp;
	endcase
end
else if (IsIUnit(tmp)) begin
	case(ins[40:37])
	4'h0:	InstType = ITMisc;
	4'h4:	InstType = ITDeposit;
	4'h5:	InstType = ITShift;
	4'h6:	InstType = ITMovl;
	4'h7:	InstType = ITMpy;
	4'h8:	InstType = ITALU;
	4'h9: InstType = ITAdd;
	4'hC:	InstType = ITCmp;
	4'hD:	InstType = ITCmp;
	4'hE:	InstType = ITCmp;
	default:	InstType = ITUnimp;
	endcase
end
else if (IsFUnit(tmp)) begin
	case(ins[40:37])
	4'h0:	InstType = ITFPMisc;
	4'h1:	InstType = ITFPMisc;
	4'h4:	InstType = ITFPCmp;
	4'h5:	InstType = ITFPClass;
	4'h8:	InstType = ITFPfma;
	4'h9:	InstType = ITFPfma;
	4'hA:	InstType = ITFPfms;
	4'hB:	InstType = ITFPfms;
	4'hC:	InstType = ITFPfnma;
	4'hD:	InstType = ITFPfnma;
	4'hE:	InstType = ITFPSelect;
	default:	InstType = ITUnimp;
	endcase
end
else if (IsBUnit(tmp)) begin
	case(ins[40:37])
	4'h0:	InstType = ITIndBranch;
	4'h1:	InstType = ITIndCall;
	4'h2:	InstType = ITNop;
	4'h4:	InstType = ITRelBranch;
	4'h5:	InstType = ITRelCall;
	default:	InstType = ITUnimp;
	endcase
end
endfunction

Regfile urf1
(
	.clk(clk_i),
	.wr(commit0_v),
	.wa(commit0_tgt),
	.i(commit0_bus),
	.ra0(Ra0),
	.ra1(Rb0)
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
	.bstate(bus_state),
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
  .rst(rst),
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

FT64_BranchPredictor ubp1
(
  .rst(rst),
  .clk(fcu_clk),
  .en(bpe),
  .xisBranch0(iq_br[heads[0]] & commit0_v),
  .xisBranch1(iq_br[heads[1]] & commit1_v),
  .xisBranch2(iq_br[heads[2]] & commit2_v),
  .pcA(ip),
  .pcB({ip[79:4],4'h5}),
  .pcC({ip[79:4],4'hA}),
  .xpc0(iq_pc[heads[0]]),
  .xpc1(iq_pc[heads[1]]),
  .xpc2(iq_pc[heads[2]]),
  .takb0(commit0_v & iq_takb[heads[0]]),
  .takb1(commit1_v & iq_takb[heads[1]]),
  .takb2(commit2_v & iq_takb[heads[2]]),
  .predict_takenA(predict_takenA),
  .predict_takenB(predict_takenB),
  .predict_takenC(predict_takenC)
);

wire [79:0] dc0_out, dc1_out;

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
	.wr(d0L2_wr),
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

L1_dcache udc1
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

L2_dcache udc2
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

wire [79:0] rdat0, rdat1;
assign rdat0 = dram0_unc ? xdati[79:0] : dc0_out;
assign rdat1 = dram1_unc ? xdati[79:0] : dc1_out;

wire [7:0] wb_fault;
wire wb_q0_done, wb_q1_done;

assign dhit0 = dhit0a && !wb_hit0;
assign dhit1 = dhit1a && !wb_hit1;
assign dhit2 = dhit2a && !wb_hit2;
wire whit0, whit1, whit2;

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
	.p0_sel_i(fnSelect(dram0_instr,dram0_addr)),
	.p0_adr_i(dram0_addr),
	.p0_dat_i(fnDato(dram0_instr,dram0_data)),
	.p0_hit(wb_hit0),
	.p1_id_i(dram1_id),
	.p1_ol_i(dram1_ol),
	.p1_wr_i(dram1==`DRAMSLOT_BUSY && dram1_store),
	.p1_ack_o(wb_q1_done),
	.p1_sel_i(fnSelect(dram1_instr,dram1_addr)),
	.p1_adr_i(dram1_addr),
	.p1_dat_i(fnDato(dram1_instr,dram1_data)),
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
					ibundle[39:0] <= 40'h00000000C0;
				else
					ibundle[39:0] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
			end
			if (ic_out[79:40]==40'h083FC003C0) begin
				if (~|irq_i)
					ibundle[79:40] <= 40'h00000000C0;
				else
					ibundle[79:40] <= {1'b1,9'h0,cause_i,2'b00,irq_i,16'h03C0};
			end
			if (ic_out[119:80]==40'h083FC003C0) begin	// PFI
				if (~|irq_i)
					ibundle[119:80] <= 40'h00000000C0;
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
	case(ins[9:6])
	`JAL:		fnRt = ins[RD];
	`RET:		fnRt = ins[RD];
	`RTI:		fnRt = ins[39:35]==`SEI ? ins[RD] : 6'd0;
	default:	fnRt = 6'd0;
	endcase
`IUnit:	fnRt = ins[RD];
`FUnit:	fnRt = ins[RD];
`MLdUnit:	fnRt = ins[RD];
`MStUnit: 
	case()
	`PUSH:	fnRt = ins[RD];
	`PUSHC:	fnRt = ins[RD];
	`TLB:		fnRt = ins[RD];
	default:	fnRt = 6'd0;
	endcase
default:	fnRt = 0;
endcase
endfunction

assign Ra0 = insn0[RS1];
assign Rb0 = insn0[RS2];
assign Rc0 = insn0[RS3];
assign Rd0 = fnRt(Unit0(ibundle[124:120]),insn0);
assign Ra1 = insn1[RS1];
assign Rb1 = insn1[RS2];
assign Rc1 = insn1[RS3];
assign Rd1 = fnRt(Unit1(ibundle[124:120]),insn1);
assign Ra2 = insn2[RS1];
assign Rb2 = insn2[RS2];
assign Rc2 = insn2[RS3];
assign Rd2 = fnRt(Unit2(ibundle[124:120]),insn2);

// Detect if a source is automatically valid
function Source1Valid;
input [2:0] unit;
input [39:0] isn;
case(unit)
`BUnit:	
	case(isn[9:6])
	`BRK:	Source1Valid = isn[RS1]==6'd0;
	`Bcc:	Source1Valid = isn[RS1]==6'd0;
	`BLcc:	Source1Valid = isn[RS1]==6'd0;
	`BRcc:	Source1Valid = isn[RS1]==6'd0;
	`FBcc:	Source1Valid = isn[RS1]==6'd0;
	`BEQI:	Source1Valid = isn[RS1]==6'd0;
	`BNEI:	Source1Valid = isn[RS1]==6'd0;
	`CHKI:	Source1Valid = isn[RS1]==6'd0;
	`CHK:	Source1Valid = isn[RS1]==6'd0;
	`JAL:	Source1Valid = isn[RS1]==6'd0;
	`RET:	Source1Valid = isn[RS1]==6'd0;
	`JMP:		Source1Valid = TRUE;
	`CALL:	Source1Valid = TRUE;
	`RTI:
		case(isn[39:35])
		5'd0:	Source1Valid = isn[RS1]==6'd0;
		`REX:	Source1Valid = isn[RS1]==6'd0;
		default: Source1Valid = TRUE;
		endcase
	default:	Source1Valid = TRUE;
	endcase
`IUnit:	Source1Valid = isn[RS1]==6'd0;
`FUnit:
	case(isn[9:6])
	`FLT2:
		case(isn[27:22])
		`FSYNC:		Source1Valid = TRUE;
		default:	Source1Valid = isn[RS1]==6'd0;
		endcase
	`FANDI:	Source1Valid = isn[RS1]==6'd0;
	`FORI:	Source1Valid = isn[RS1]==6'd0;
	`FMA:		Source1Valid = isn[RS1]==6'd0;
	`FMS:		Source1Valid = isn[RS1]==6'd0;
	`FNMA:	Source1Valid = isn[RS1]==6'd0;
	`FNMS:	Source1Valid = isn[RS1]==6'd0;
	default:	Source1Valid = TRUE;
	endcase
`MLdUnit:	Source1Valid = isn[RS1]==6'd0;
`MStUnit:
	case(isn[9:6])
	`MSX:
		case(isn[39:35])
		`MEMDB:	Source1Valid = TRUE;
		`MEMSB:	Source1Valid = TRUE;
		default:	Source1Valid = isn[RS1]==6'd0;
		endcase
	default: Source1Valid = isn[RS1]==6'd0;
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
	`Bcc:		Source2Valid = isn[RS2]==6'd0;
	`BLcc:	Source2Valid = isn[RS2]==6'd0;
	`BRcc:	Source2Valid = isn[RS2]==6'd0;
	`FBcc:	Source2Valid = isn[RS2]==6'd0;
	`BEQI:	Source2Valid = TRUE;
	`BNEI:	Source2Valid = TRUE;
	`CHKI:	Source2Valid = TRUE;
	`CHK:		Source2Valid = isn[RS2]==6'd0;
	`JAL:		Source2Valid = TRUE;
	`RET:		Source2Valid = isn[RS2]==6'd0;
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
		default:	Source2Valid = isn[RS2]==6'd0;
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
		default:	Source2Valid = isn[RS2]==6'd0;
		endcase
	`FANDI:	Source2Valid = TRUE;
	`FORI:	Source2Valid = TRUE;
	`FMA:		Source2Valid = isn[RS2]==6'd0;
	`FMS:		Source2Valid = isn[RS2]==6'd0;
	`FNMA:	Source2Valid = isn[RS2]==6'd0;
	`FNMS:	Source2Valid = isn[RS2]==6'd0;
	default:	Source2Valid = TRUE;
	endcase
`MLdUnit:
	case(isn[9:6])
	`MLX:			Source2Valid = TRUE;
	default:	Source2Valid = TRUE;
	endcase
`MStUnit:
	case(isn[9:6])
	`PUSHC:		Source2Valid = TRUE;
	default:	Source2Valid = isn[RS2]==6'd0;
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
	`CHK:		Source3Valid = isn[RS3]==6'd0;
	`BRcc:	Source3Valid = isn[RS3]==6'd0;
	default:	Source3Valid = TRUE;
	endcase
`IUnit:
	case({isn[32:31],isn[9:6]})
	`R3:	Source3Valid = isn[RS3]==6'd0;
	`BITFIELD:	Source3Valid = isn[RS3]==6'd0;
	`CSR:	Source3Valid = TRUE;
	default:	Source3Valid = TRUE;
	endcase
`FUnit:
	case(isn[9:6])
	`FLT2:	Source3Valid = TRUE;
	default:	Source3Valid = isn[RS3]==6'd0;
	endcase
`MLdUnit:	
	case(isn[9:6])
	`MLX:			Source3Valid = isn[RS3]==6'd0;
	default:	Source3Valid = TRUE;
	endcase
`MStUnit:
	case(isn[9:6])
	`MSX:			Source3Valid = isn[RS3]==6'd0;
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
input [47:0] isn;
casez(isn[`INSTRUCTION_OP])
`Bcc:   IsBranch = TRUE;
`BRcc:  IsBranch = TRUE;
`FBcc:  IsBranch = TRUE;
`BBc:   IsBranch = TRUE;
`BEQI:  IsBranch = TRUE;
`BNEI:  IsBranch = TRUE;
`CHK:   IsBranch = TRUE;
default:    IsBranch = FALSE;
endcase
endfunction


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

wire fcu_brk = fcu_op4==`BRK;
wire fcu_rti = fcu_op4==`RTI && fcu_func5==5'd0;
wire fcu_rex = fcu_op4==`RTI && fcu_func5==`REX;
wire fcu_chk = fcu_op4==`CHK || fcu_op4==`CHKI;
wire fcu_ret = fcu_op4==`RET;
wire fcu_jal = fcu_op4==`JAL;

always @*
begin
case(fcu_op4)
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
	else if ((fcu_branch && (fcu_takb ^ fcu_pt)) || fcu_op4==`BRcc)
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

//FT64_RMW_alu urmwalu0 (rmw_instr, rmw_argA, rmw_argB, rmw_argC, rmw_res);


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
                            (dram1 && dram1_store) ||
                            (dram2 && dram2_store);

//
// additional COMMIT logic
//
always @*
begin
    commit0_v <= (iqentry_state[heads[0]] == IQS_CMT && ~|panic);
    commit0_id <= {iqentry_mem[heads[0]], heads[0]};	// if a memory op, it has a DRAM-bus id
    commit0_tgt <= iqentry_tgt[heads[0]];
    commit0_bus <= iqentry_res[heads[0]];
    if (`NUM_CMT > 1) begin
	    commit1_v <= ({iqentry_v[heads[0]],  iqentry_state[heads[0]] == IQS_CMT} != 2'b10
	               && iqentry_state[heads[1]] == IQS_CMT
	               && ~|panic);
	    commit1_id <= {iqentry_mem[heads[1]], heads[1]};
	    commit1_tgt <= iqentry_tgt[heads[1]];  
	    commit1_bus <= iqentry_res[heads[1]];
	    // Need to set commit1, and commit2 valid bits for the branch predictor.
	    if (`NUM_CMT > 2) begin
	  	end
	  	else begin
	  		commit2_v <= ({iqentry_v[heads[0]], iqentry_state[heads[0]] == IQS_CMT} != 2'b10
	  							 && {iqentry_v[heads[1]], iqentry_state[heads[1]] == IQS_CMT} != 2'b10
	  							 && {iqentry_v[heads[2]], iqentry_br[heads[2]], iqentry_state[heads[2]] == IQS_CMT}==3'b111
		               && iqentry_tgt[heads[2]][4:0]==5'd0 && ~|panic);	// watch out for dbnz and ibne
	  		commit2_tgt <= 12'h000;
	  	end
  	end
  	else begin
  		commit1_v <= ({iqentry_v[heads[0]], iqentry_state[heads[0]] == IQS_CMT} != 2'b10
  							 && {iqentry_v[heads[1]], iqentry_state[heads[1]] == IQS_CMT} == 2'b11
	               && !iqentry_rfw[heads[1]] && ~|panic);	// watch out for dbnz and ibne
    	commit1_id <= {iqentry_mem[heads[1]], heads[1]};	// if a memory op, it has a DRAM-bus id
  		commit1_tgt <= 12'h000;
  		// We don't really need the bus value since nothing is being written.
	    commit1_bus <= iqentry_res[heads[1]];
  		commit2_v <= ({iqentry_v[heads[0]], iqentry_state[heads[0]] == IQS_CMT} != 2'b10
  							 && {iqentry_v[heads[1]], iqentry_state[heads[1]] == IQS_CMT} != 2'b10
  							 && {iqentry_v[heads[2]], iqentry_br[heads[2]], iqentry_state[heads[2]] == IQS_CMT}==3'b111
	               && !iqentry_rfw[heads[2]] && ~|panic);	// watch out for dbnz and ibne
    	commit2_id <= {iqentry_mem[heads[2]], heads[2]};	// if a memory op, it has a DRAM-bus id
  		commit2_tgt <= 12'h000;
	    commit2_bus <= iqentry_res[heads[2]];
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

reg [`SNBITS] maxsn [0:`WAYS-1];
always @*
begin
	maxsn = 8'd0;
	for (n = 0; n < QENTRIES; n = n + 1)
		if (iqentry_sn[n] > maxsn && iq_v[n])
			maxsn = iq_sn[n];
	maxsn = maxsn - tosub;
end


always @(posedge clk_i)
if (rst_i) begin
	cnt <= 8'd0;
	ircnt <= 2'd0;
	ip <= RST_ADDR;
end
else begin
case (state)
RESET:
	begin
		rip <= ip[63:4];
		cnt <= cnt + 2'd1;
		if (cnt[2])
			state <= IFETCH;
	end
IFETCH:
	begin
		selFpReg <= 1'b0;
		fpLdSt <= 1'b0;
		slot <= slot + 2'd1;
		case(slot)
		2'd0:	begin ir41 <= ir[40:0]; state <= DCRF; end
		2'd1:	begin ir41 <= ir[81:41]; state <= DCRF; end
		2'd2:	begin ir41 <= ir[122:82]; state <= DCRF; end
		2'd3:
			begin
				rip <= ip[63:4] + 2'd1;
				ip <= ip + 8'd16;
			end
		endcase
	end
DCRF:
	begin
		if ((template==5'h0C || template==5'h0D) && slot==2'd1)
			selFp <= 1'b1;
		else if ((template==5'h0E || template==5'h0F) && slot==2'd2)
			selFp <= 1'b1;
		else if ((template==5'h1C || template==5'h1D) && slot==2'd1)
			selFp <= 1'b1;
		if ((template==))
	end
endcase
end

	case({slot0v,slot1v,slot2v}&{3{phit}})
	3'b000:	;
	3'b001:
		if (canq1) begin
			queue_slot2(tail0,maxsn+2'd1);
			slot0v <= VAL;
			slot1v <= VAL;
			slot2v <= VAL;
			ip <= ip + 80'd16;
		end
	3'b010:
		if (canq1) begin
			queue_slot1(tail0,maxsn+2'd1);
			slot0v <= VAL;
			slot1v <= VAL;
			slot2v <= VAL;
			ip <= ip + 80'd16;
		end
	3'b011:
		if (canq2) begin
			queue_slot1(tail0,maxsn+2'd1);
			queue_slot2(tail1,maxsn+2'd2);
			slot1v <= INV;
			slot2v <= INV;
			ip <= ip + 80'd16;
		end
		else if (canq1) begin
			queue_slot1(tail0,maxsn+2'd1);
			slot1v <= INV;
		end
	3'b100:
		if (canq1) begin
			queue_slot0(tail0,maxsn+2'd1);
			slot0v <= VAL;
			slot1v <= VAL;
			slot2v <= VAL;
			ip <= ip + 80'd16;
		end
	3'b101:
		if (canq2) begin
			queue_slot0(tail0,maxsn+2'd1);
			queue_slot2(tail1,maxsn+2'd2);
			slot0v <= VAL;
			slot1v <= VAL;
			slot2v <= VAL;
			ip <= ip + 80'd16;
		end
		else if (canq1) begin
			queue_slot0(tail0,maxsn+2'd1);
			slot0v <= INV;
		end
	3'b110:
		if (canq2) begin
			queue_slot0(tail0,maxsn+2'd1);
			queue_slot1(tail1,maxsn+2'd2);
			slot0v <= VAL;
			slot1v <= VAL;
			slot2v <= VAL;
			ip <= ip + 80'd16;
		end
		else if (canq1) begin
			queue_slot0(tail0,maxsn+2'd1);
			slot0v <= INV;
		end
	3'b111:
		if (canq3) begin
			queue_slot0(tail0,maxsn+2'd1);
			queue_slot1(tail1,maxsn+2'd2);
			queue_slot2(tail2,maxsn+2'd3);
			slot0v <= VAL;
			slot1v <= VAL;
			slot2v <= VAL;
			ip <= ip + 80'd16;
		end
		else if (canq2) begin
			queue_slot0(tail0,maxsn+2'd1);
			queue_slot1(tail1,maxsn+2'd2);
			slot0v <= INV;
			slot1v <= INV;
		end
		else if (canq1) begin
			queue_slot0(tail0,maxsn+2'd1);
			slot0v <= INV;
		end
	endcase

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

  for (n = 0; n < QENTRIES; n = n + 1)
    if (iq_fcu_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
      if (fcu_done) begin
				fcu_sourceid	<= n[`QBITS];
				fcu_prevInstr <= fcu_instr;
				fcu_instr	<= iq_instr[n];
				fcu_ip		<= iq_ip[n];
				case(iq_ip[3:0])
				4'h0:	fcu_nextip <= {iq_ip[n][79:4],4'h5};
				4'h5:	fcu_nextip <= {iq_ip[n][79:4],4'hA};
				4'hA:	fcu_nextip <= {iq_ip[n][79:4],4'h0} + 8'd16;
				default:	begin fcu_nextip <= iq_ip; fcu_exc <= `FLT_ALGN; end
				endcase
				fcu_pt     <= iq_pt[n];
				fcu_brdisp <= iq_instr[n][6] ? {{36{iq_instr[n][47]}},iq_instr[n][47:23],iq_instr[n][17:16],1'b0}
										 : {{52{iq_instr[n][31]}},iq_instr[n][31:23],iq_instr[n][17:16],1'b0};
				fcu_branch <= iq_br[n];
				fcu_call    <= IsCall(iq_instr[n])|iq_jal[n];
				fcu_jal     <= iq_jal[n];
				fcu_ret    <= iq_ret[n];
				fcu_brk  <= iq_brk[n];
				fcu_rti  <= iq_rti[n];
				fcu_rex  <= iq_rex[n];
				fcu_chk  <= iq_chk[n];
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
				fcu_dataready <= !IsWait(iq_instr[n]);
				fcu_clearbm <= `FALSE;
				fcu_ld <= TRUE;
				fcu_timeout <= 8'h00;
				iq_state[n] <= IQS_OUT;
				fcu_done <= `FALSE;
      end
    end
end

task setinsn;
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
	iq_alu0 [nn]  <= bus[`IB_ALU0];
	iq_fpu  [nn]  <= bus[`IB_FPU];
	iq_fc   [nn]  <= bus[`IB_FC];
	iq_canex[nn]  <= bus[`IB_CANEX];
	iq_loadv[nn]  <= bus[`IB_LOADV];
	iq_load [nn]  <= bus[`IB_LOAD];
	iq_loadseg[nn]<= bus[`IB_LOADSEG];
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
	iq_shft [nn]  <= bus[`IB_SHFT];	// 48 bit shift instructions
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
	iq_argAv[ndx] <= regIsValid[Ra0] || Source1Valid({Unit0(ibundle[124:120]),ibundle[39:0]});
	iq_argBv[ndx] <= regIsValid[Rb0] || Source2Valid({Unit0(ibundle[124:120]),ibundle[39:0]});
	iq_argCv[ndx] <= regIsValid[Rc0] || Source2Valid({Unit0(ibundle[124:120]),ibundle[39:0]});
	iq_argAs[ndx] <= rf_source[Ra0];
	iq_argBs[ndx] <= rf_source[Rb0];
	iq_argCs[ndx] <= rf_source[Rc0];
	iq_pt[ndx] <= predict_taken0;
	iq_tgt[ndx] <= Rt0;
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
	iq_argAv[ndx] <= regIsValid[Ra1] || Source1Valid({Unit1(ibundle[124:120]),ibundle[79:40]});
	iq_argBv[ndx] <= regIsValid[Rb1] || Source2Valid({Unit1(ibundle[124:120]),ibundle[79:40]});
	iq_argCv[ndx] <= regIsValid[Rc1] || Source2Valid({Unit1(ibundle[124:120]),ibundle[79:40]});
	iq_argAs[ndx] <= rf_source[Ra1];
	iq_argBs[ndx] <= rf_source[Rb1];
	iq_argCs[ndx] <= rf_source[Rc1];
	iq_pt[ndx] <= predict_taken1;
	iq_tgt[ndx] <= Rt1;
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
	iq_argAv[ndx] <= regIsValid[Ra2] || Source1Valid({Unit2(ibundle[124:120]),ibundle[119:80]});
	iq_argBv[ndx] <= regIsValid[Rb2] || Source2Valid({Unit2(ibundle[124:120]),ibundle[119:80]});
	iq_argCv[ndx] <= regIsValid[Rc2] || Source2Valid({Unit2(ibundle[124:120]),ibundle[119:80]});
	iq_argAs[ndx] <= rf_source[Ra2];
	iq_argBs[ndx] <= rf_source[Rb2];
	iq_argCs[ndx] <= rf_source[Rc2];
	iq_pt[ndx] <= predict_taken2;
	iq_tgt[ndx] <= Rt2;
	iq_res[ndx] <= 80'd0;
	iq_exc[ndx] <= `FLT_NONE;
	set_insn(ndx,id2_bus);
end
endtask

endmodule

