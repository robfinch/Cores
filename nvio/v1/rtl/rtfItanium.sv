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

module rtfItanium(hartid_i, rst_i, clk_i, clk2x_i, clk4x_i, tm_clk_i, irq_i, cause_i, 
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
output [7:0] exc_o;
parameter TM_CLKFREQ = 20000000;
parameter QENTRIES = `QENTRIES;
parameter QSLOTS = `QSLOTS;
parameter AREGS = 128;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;
parameter VAL = 1'b1;
parameter INV = 1'b0;
parameter RSTIP = 80'hFFFFFFFFFFFFFFFC0100;
parameter BRKIP = 80'hFFFFFFFFFFFFFFFC0000;
parameter DEBUG = 1'b0;
parameter DBW = 80;
parameter ABW = 80;
parameter AMSB = ABW-1;
parameter RBIT = 6;
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

parameter NUnit = 3'd0;
parameter BUnit = 3'd1;
parameter IUnit = 3'd2;
parameter FUnit = 3'd3;
parameter MUnit = 3'd4;

parameter BBB = 7'h00;		// Branch, Branch, Branch template

`include "rtfItanium-bus_states.sv"

wire clk;
//BUFG uclkb1
//(
//	.I(clk_i),
//	.O(clk)
//);
assign clk = clk_i;

wire rdv_i;
wire wrv_i;
reg [AMSB:0] vadr;
reg cyc;
reg cyc_pending;	// An i-cache load is about to happen
reg we;

reg [7:0] i;
integer n;
integer j, k;
integer row, col;
genvar g, h;

wire [AMSB:0] ip, ipd, next_ip;
wire ip_override;
reg [AMSB:0] rip;
reg [AMSB:0] ra;		// return address - predicted
reg [2:0] ip_mask, ip_maskd;
reg [AMSB:0] missip, excmissip;
wire freezeip;
reg [1:0] slot;
wire [AMSB:0] slot0ip = {ip[AMSB:4],4'h0};
wire [AMSB:0] slot1ip = {ip[AMSB:4],4'h5};
wire [AMSB:0] slot2ip = {ip[AMSB:4],4'hA};
wire [QSLOTS-1:0] slotv;
wire [QSLOTS-1:0] slotvd;
reg [2:0] slotu [QSLOTS-1:0];
reg [2:0] slotup [QSLOTS-1:0];
reg [3:0] fb_panic;

wire [127:0] ibundle;
wire [7:0] template [0:QSLOTS-1];
wire [39:0] insnx [0:QSLOTS-1];
assign insnx[0] = ibundle[39:0];
assign insnx[1] = ibundle[79:40];
assign insnx[2] = ibundle[119:80];

reg [4:0] state;
reg [7:0] cnt;
reg r1IsFp,r2IsFp,r3IsFp;

wire  [`QBITS] tails [0:QSLOTS-1];
wire  [`QBITS] heads [0:QENTRIES-1];

wire tlb_miss;
wire exv;

wire [RBIT:0] Rs1 [0:QSLOTS-1];
wire [RBIT:0] Rs2 [0:QSLOTS-1];
wire [RBIT:0] Rs3 [0:QSLOTS-1];
wire [RBIT:0] Rd [0:QSLOTS-1];
wire [WID-1:0] rfoa [0:QSLOTS-1];
wire [WID-1:0] rfob [0:QSLOTS-1];
wire [WID-1:0] rfoc [0:QSLOTS-1];
wire  [AREGS-1:0] rf_v;
reg  [`QBITS] rf_source[0:AREGS-1];
wire [1:0] ol;
wire [1:0] dl;

reg excmiss;
reg exception_set;
reg rdvq;               // accumulated read violation
reg errq;               // accumulated err_i input status
reg exvq;

// CSR's
reg debug_on;
reg [WID-1:0] cr0;
wire snr = cr0[17];		// sequence number reset
wire dce = cr0[30];     // data cache enable
wire bpe = cr0[32];     // branch predictor enable
wire wbm = cr0[34];
wire sple = cr0[35];		// speculative load enable
wire ctgtxe = cr0[33];
reg [WID-1:0] pmr;
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
reg [`QBITS] bstmp_ctr;
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
reg [`ABITS] ipc ;
reg [`ABITS] ipc0 ;
reg [`ABITS] ipc1 ;
reg [`ABITS] ipc2 ;
reg [`ABITS] ipc3 ;
reg [`ABITS] ipc4 ;
reg [`ABITS] ipc5 ;
reg [`ABITS] ipc6 ;
reg [`ABITS] ipc7 ;
reg [`ABITS] ipc8 ; 			// exception pc and stack
reg [79:0] mstatus ;  		// machine status
reg [15:0] ol_stack;
reg [15:0] dl_stack;
assign ol = ol_stack[1:0];	// operating level
assign dl = dl_stack[1:0];
wire [7:0] cpl ;
assign cpl = mstatus[13:6];	// current privilege level
reg [79:0] pl_stack ;
reg [79:0] rs_stack ;
reg [79:0] brs_stack ;
reg [79:0] fr_stack ;
wire [3:0] rgs = rs_stack[3:0];
wire mprv = mstatus[55];
wire [7:0] ASID = mstatus[47:40];
wire [3:0] fprgs = mstatus[23:20];
//assign ol_o = mprv ? ol_stack[2:0] : ol;
wire vca = mstatus[32];		// vector chaining active
reg [WID*2-1:0] keys;

assign pkeys_o = keys;
reg [WID-1:0] tcb;
reg [47:0] bad_instr[0:15];
reg [`ABITS] badaddr[0:15];
reg [`ABITS] tvec[0:7];
reg [WID-1:0] sema;
reg [WID-1:0] vm_sema;
reg [WID-1:0] cas;         // compare and swap
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
wire [3:0] fp_rgs = fpu_csr[35:32];

reg  [3:0] panic;		// indexes the message structure
reg [127:0] message [0:15];	// indexed by panic

wire int_commit;

reg [199:0] xdati;

wire [2:0] queuedCnt;
reg queuedNop;
reg [2:0] hi_amt;

reg [47:0] codebuf[0:63];
reg [QENTRIES-1:0] setpred;

// instruction queue (ROB)
// State and stqte decodes
reg [2:0] iq_state [0:QENTRIES-1];
reg [QENTRIES-1:0] iq_v;			// entry valid?  -- this should be the first bit
reg [`QBITS] iq_br_tag [0:QENTRIES-1];
reg [QENTRIES-1:0] iq_done;
reg [QENTRIES-1:0] iq_out;
reg [QENTRIES-1:0] iq_agen;
reg [2:0] iq_sn [0:QENTRIES-1];  // instruction sequence number
reg [`QBITS] iq_is [0:QENTRIES-1];	// source of instruction
reg [QENTRIES-1:0] iq_pt;		// predict taken
reg [QENTRIES-1:0] iq_bt;		// update branch target buffer
reg [QENTRIES-1:0] iq_takb;	// take branch record
reg [QENTRIES-1:0] iq_jal;
reg [2:0] iq_sz [0:QENTRIES-1];
reg [QENTRIES-1:0] iq_alu = 8'h00;  // alu type instruction
reg [QENTRIES-1:0] iq_alu0 = 1'b0;
reg [QENTRIES-1:0] iq_fpu;  // floating point instruction
reg [QENTRIES-1:0] iq_fc;   // flow control instruction
reg [QENTRIES-1:0] iq_canex = 8'h00;	// true if it's an instruction that can exception
reg [QENTRIES-1:0] iq_oddball = 8'h00;	// writes to register file
reg [QENTRIES-1:0] iq_lea;
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
reg [QENTRIES-1:0] iq_brcc;  // BEcc
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
reg [WID+3:0] iq_res	[0:QENTRIES-1];	// instruction result
reg [31:0] iq_ares	[0:QENTRIES-1];	// alternate instruction result (fpu status)
reg [2:0] iq_unit[0:QENTRIES-1];
reg [39:0] iq_instr[0:QENTRIES-1];	// instruction opcode
reg  [7:0] iq_exc	[0:QENTRIES-1];	// only for branches ... indicates a HALT instruction
reg [RBIT:0] iq_rs1 [0:QENTRIES-1];
reg [RBIT:0] iq_rs2 [0:QENTRIES-1];		// debugging
reg [RBIT:0] iq_rs3 [0:QENTRIES-1];
reg [RBIT:0] iq_tgt[0:QENTRIES-1];	// Rt field or ZERO -- this is the instruction's target (if any)
reg [AMSB:0] iq_ma [0:QENTRIES-1];	// memory address
reg [WID-1:0] iq_argI	[0:QENTRIES-1];	// argument 0 (immediate)
reg [WID+3:0] iq_argA	[0:QENTRIES-1];	// argument 1
reg [QENTRIES-1:0] iq_argA_v;	// arg1 valid
reg [`QBITS] iq_argA_s	[0:QENTRIES-1];	// arg1 source (iq entry # with top bit representing ALU/DRAM bus)
reg [WID+3:0] iq_argB	[0:QENTRIES-1];	// argument 2
reg [QENTRIES-1:0] iq_argB_v;	// arg2 valid
reg  [`QBITS] iq_argB_s	[0:QENTRIES-1];	// arg2 source (iq entry # with top bit representing ALU/DRAM bus)
reg [WID+3:0] iq_argC	[0:QENTRIES-1];	// argument 3
reg [QENTRIES-1:0] iq_argC_v;	// arg3 valid
reg  [`QBITS] iq_argC_s	[0:QENTRIES-1];	// arg3 source (iq entry # with top bit representing ALU/DRAM bus)
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

reg [1:0] missued;
reg [7:0] last_issue0, last_issue1, last_issue2;
reg  [QENTRIES-1:0] iq_memissue;
reg [QENTRIES-1:0] iq_stomp;
reg [3:0] stompedOnRets;
reg  [QENTRIES-1:0] iq_alu0_issue;
reg  [QENTRIES-1:0] iq_alu1_issue;
reg  [QENTRIES-1:0] iq_alu2_issue;
reg  [QENTRIES-1:0] iq_agen0_issue;
reg  [QENTRIES-1:0] iq_agen1_issue;
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

wire [QSLOTS-1:0] take_branch;

reg         id1_v;
reg   [`QBITS] id1_id;
reg   [2:0] id1_unit;
reg  [39:0] id1_instr;
reg   [5:0] id1_ven;
reg   [7:0] id1_vl;
reg         id1_thrd;
reg         id1_pt;
reg   [4:0] id1_Rt;
wire [`IBTOP:0] id_bus [0:QSLOTS-1];

reg         id2_v;
reg   [`QBITS] id2_id;
reg   [2:0] id2_unit;
reg  [39:0] id2_instr;
reg   [5:0] id2_ven;
reg   [7:0] id2_vl;
reg         id2_thrd;
reg         id2_pt;
reg   [4:0] id2_Rt;

reg         id3_v;
reg   [`QBITS] id3_id;
reg   [2:0] id3_unit;
reg  [39:0] id3_instr;
reg   [5:0] id3_ven;
reg   [7:0] id3_vl;
reg         id3_thrd;
reg         id3_pt;
reg   [4:0] id3_Rt;

reg [WID-1:0] alu0_xs = 64'd0;
reg [WID-1:0] alu1_xs = 64'd0;

reg [31:0] alu0_sn;
reg 				alu0_cmt;
wire				alu0_abort;
reg        alu0_ld;
reg        alu0_dataready;
wire       alu0_done;
wire       alu0_idle;
reg  [`QBITS] alu0_sourceid;
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
wire  [`QBITS] alu0_id;
(* mark_debug="true" *)
wire  [`XBITS] alu0_exc;
wire        alu0_v;
wire alu0_vsn;
reg alu0_v1;
wire        alu0_branchmiss;
wire [`ABITS] alu0_missip;
reg [`QBITS] alu0_id1;
reg [`QBITS] alu1_id1;
reg [WID-1:0] alu0_bus1;
reg [WID-1:0] alu1_bus1;


reg [31:0] alu1_sn;
reg 				alu1_cmt;
wire				alu1_abort;
reg        alu1_ld;
reg        alu1_dataready;
wire       alu1_done;
wire       alu1_idle;
reg  [`QBITS] alu1_sourceid;
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
wire  [`QBITS] alu1_id;
wire  [`XBITS] alu1_exc;
wire        alu1_v;
reg alu1_v1;
wire        alu1_branchmiss;
wire [`ABITS] alu1_missip;
wire alu1_vsn;

wire agen0_v;
wire agen0_vsn;
wire agen0_idle;
reg [31:0] agen0_sn;
reg [`QBITS] agen0_sourceid;
wire [`QBITS] agen0_id;
reg [RBIT:0] agen0_tgt;
reg agen0_dataready;
reg [2:0] agen0_unit;
reg [39:0] agen0_instr;
reg agen0_lea;
reg agen0_push;
reg [AMSB:0] agen0_ma;
reg [79:0] agen0_argA, agen0_argB, agen0_argC;

wire agen1_v;
wire agen1_vsn;
wire agen1_idle;
reg [31:0] agen1_sn;
reg [`QBITS] agen1_sourceid;
wire [`QBITS] agen1_id;
reg [RBIT:0] agen1_tgt;
reg agen1_dataready;
reg [2:0] agen1_unit;
reg [39:0] agen1_instr;
reg agen1_lea;
reg agen1_push;
reg [AMSB:0] agen1_ma;
reg [79:0] agen1_argA, agen1_argB, agen1_argC;

wire [`XBITS] fpu_exc;
reg 				fpu1_cmt;
reg        fpu1_ld;
reg        fpu1_dataready = 1'b1;
wire       fpu1_done = 1'b1;
wire       fpu1_idle;
reg [`QBITS] fpu1_sourceid;
reg [39:0] fpu1_instr;
reg [WID+3:0] fpu1_argA;
reg [WID+3:0] fpu1_argB;
reg [WID+3:0] fpu1_argC;
reg [WID+3:0] fpu1_argT;
reg [WID-1:0] fpu1_argI;	// only used by BEQ
reg [RBIT:0] fpu1_tgt;
reg [`ABITS] fpu1_ip;
wire [WID+3:0] fpu1_out = 84'h0;
reg [WID+3:0] fpu1_bus = 84'h0;
wire  [`QBITS] fpu1_id;
wire  [`XBITS] fpu1_exc;
wire        fpu1_v;
wire [31:0] fpu1_status;

reg 				fpu2_cmt;
reg        fpu2_ld;
reg        fpu2_dataready = 1'b1;
wire       fpu2_done = 1'b1;
wire       fpu2_idle;
reg [`QBITS] fpu2_sourceid;
reg [39:0] fpu2_instr;
reg [WID+3:0] fpu2_argA;
reg [WID+3:0] fpu2_argB;
reg [WID+3:0] fpu2_argC;
reg [WID+3:0] fpu2_argT;
reg [WID-1:0] fpu2_argI;	// only used by BEQ
reg [RBIT:0] fpu2_tgt;
reg [`ABITS] fpu2_ip;
wire [WID+3:0] fpu2_out = 84'h0;
reg [WID+3:0] fpu2_bus = 84'h0;
wire  [`QBITS] fpu2_id;
wire  [`XBITS] fpu2_exc;
wire        fpu2_v;
wire [31:0] fpu2_status;

reg [7:0] fccnt;
reg [47:0] waitctr;
reg 				fcu_cmt;
reg        fcu_ld;
reg        fcu_dataready;
reg        fcu_done;
reg         fcu_idle = 1'b1;
reg [`QBITS] fcu_sourceid;
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
reg [WID-1:0] fcu_ipc;
reg [`ABITS] fcu_ip;
reg [`ABITS] fcu_nextip;
reg [`ABITS] fcu_brdisp;
wire [WID-1:0] fcu_out;
reg [WID-1:0] fcu_bus;
wire  [`QBITS] fcu_id;
reg   [`XBITS] fcu_exc;
wire        fcu_v;
reg        fcu_branchmiss;
reg fcu_branchhit;
reg  fcu_clearbm;
reg [`ABITS] fcu_missip;
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

reg branchmiss = 1'b0;
reg branchhit = 1'b0;
reg  [`QBITS] missid;

wire [1:0] issue_count;
reg [1:0] missue_count;
wire [QENTRIES-1:0] memissue;

wire        dram_avail;
reg	 [2:0] dram0;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [2:0] dram1;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg [79:0] dram0_argI, dram0_argB;
reg [WID-1:0] dram0_data;
reg [`ABITS] dram0_addr;
reg [39:0] dram0_instr;
reg        dram0_rmw;
reg		   dram0_preload;
reg [RBIT:0] dram0_tgt;
reg  [`QBITS] dram0_id;
reg        dram0_unc;
reg [2:0]  dram0_memsize;
reg        dram0_load;	// is a load operation
reg        dram0_store;
reg  [1:0] dram0_ol;
reg [79:0] dram1_argI, dram1_argB;
reg [WID-1:0] dram1_data;
reg [`ABITS] dram1_addr;
reg [39:0] dram1_instr;
reg        dram1_rmw;
reg		   dram1_preload;
reg [RBIT:0] dram1_tgt;
reg  [`QBITS] dram1_id;
reg        dram1_unc;
reg [2:0]  dram1_memsize;
reg        dram1_load;
reg        dram1_store;
reg  [1:0] dram1_ol;

reg        dramA_v;
reg  [`QBITS] dramA_id;
reg [WID-1:0] dramA_bus;
reg        dramB_v;
reg  [`QBITS] dramB_id;
reg [WID-1:0] dramB_bus;

wire        outstanding_stores;
reg [47:0] I;		// instruction count
reg [47:0] CC;	// commit count

reg commit0_v;
reg [`QBITS] commit0_id;
reg [RBIT:0] commit0_tgt;
reg [WID+3:0] commit0_bus;
reg commit1_v;
reg [`QBITS] commit1_id;
reg [RBIT:0] commit1_tgt;
reg [WID+3:0] commit1_bus;
reg commit2_v;
reg [`QBITS] commit2_id;
reg [RBIT:0] commit2_tgt;
reg [WID+3:0] commit2_bus;

reg [5:0] ld_time;
reg [79:0] wc_time_dat;
reg [79:0] wc_times;

reg [`QBITS] active_tag, miss_tag;
reg [`QBITS] br_tag [0:QENTRIES-1];

reg [QSLOTS-1:0] queuedOn;
wire [QSLOTS-1:0] queuedOnp;
wire [QSLOTS-1:0] predict_taken;
wire predict_taken0;
wire predict_taken1;
wire predict_taken2;
wire [QSLOTS-1:0] slot_rfw;
wire [QSLOTS-1:0] slot_jc;
wire [QSLOTS-1:0] slot_jal;
wire [QSLOTS-1:0] slot_br;
wire [QSLOTS-1:0] slot_call;
wire [QSLOTS-1:0] slot_ret;

assign slot_rfw[0] = IsRFW(slotu[0],insnx[0]);
assign slot_rfw[1] = IsRFW(slotu[1],insnx[1]);
assign slot_rfw[2] = IsRFW(slotu[2],insnx[2]);
wire slot0_mem = IsMem(slotu[0]) && !IsLea(slotu[0],insnx[0]);
wire slot1_mem = IsMem(slotu[1]) && !IsLea(slotu[1],insnx[1]);
wire slot2_mem = IsMem(slotu[2]) && !IsLea(slotu[2],insnx[2]);
assign slot_jal[0] = id_bus[0][`IB_JAL];
assign slot_jal[1] = id_bus[1][`IB_JAL];
assign slot_jal[2] = id_bus[2][`IB_JAL];
assign slot_call[0] = id_bus[0][`IB_CALL];
assign slot_call[1] = id_bus[1][`IB_CALL];
assign slot_call[2] = id_bus[2][`IB_CALL];
assign slot_ret[0] = id_bus[0][`IB_RET];
assign slot_ret[1] = id_bus[1][`IB_RET];
assign slot_ret[2] = id_bus[2][`IB_RET];
assign slot_jc[0] = IsCall(slotu[0],insnx[0]) || IsJmp(slotu[0],insnx[0]);
assign slot_jc[1] = IsCall(slotu[1],insnx[1]) || IsJmp(slotu[1],insnx[1]);
assign slot_jc[2] = IsCall(slotu[2],insnx[2]) || IsJmp(slotu[2],insnx[2]);
assign slot_br[0] = IsBranchReg(slotup[0],insnxp[0]) || IsBrk(slotup[0],insnxp[0]) || IsRti(slotup[0],insnxp[0]);
assign slot_br[1] = IsBranchReg(slotup[1],insnxp[1]) || IsBrk(slotup[1],insnxp[1]) || IsRti(slotup[1],insnxp[1]);
assign slot_br[2] = IsBranchReg(slotup[2],insnxp[2]) || IsBrk(slotup[2],insnxp[2]) || IsRti(slotup[2],insnxp[2]);
assign take_branch[0] = (IsBranch(slotu[0],insnx[0]) && predict_taken[0]) || IsBrk(slotu[0],insnx[0]) || IsRti(slotu[0],insnx[0]);
assign take_branch[1] = (IsBranch(slotu[1],insnx[1]) && predict_taken[1]) || IsBrk(slotu[1],insnx[1]) || IsRti(slotu[1],insnx[1]);
assign take_branch[2] = (IsBranch(slotu[2],insnx[2]) && predict_taken[2]) || IsBrk(slotu[2],insnx[2]) || IsRti(slotu[2],insnx[2]);
// Branching for purposes of the branch shadow.
wire [QSLOTS-1:0] is_branch;
reg [QENTRIES-1:0] is_qbranch;
assign is_branch[0] = IsBranch(slotu[0],insnx[0]) || id_bus[0][`IB_BRK] || id_bus[0][`IB_RTI] || id_bus[0][`IB_RET] || id_bus[0][`IB_JAL];
assign is_branch[1] = IsBranch(slotu[1],insnx[1]) || id_bus[1][`IB_BRK] || id_bus[1][`IB_RTI] || id_bus[1][`IB_RET] || id_bus[1][`IB_JAL];
assign is_branch[2] = IsBranch(slotu[2],insnx[2]) || id_bus[2][`IB_BRK] || id_bus[2][`IB_RTI] || id_bus[2][`IB_RET] || id_bus[2][`IB_JAL];
always @*
for (n = 0; n < QENTRIES; n = n + 1)
	is_qbranch[n] = iq_br[n] | iq_brk[n] | iq_rti[n] | iq_ret[n] | iq_jal[n] | iq_brcc[n];
wire [1:0] ic_fault;
wire [127:0] ic_out;
reg invic, invdc;
reg invicl;
reg [4:0] bstate;
wire [3:0] icstate;
reg [1:0] bwhich;
wire ihit;
reg phit, phitd;
// The L1 address might not be equal to the ip if a cache update is taking
// place. This can lead to a false hit because once the cache is updated
// it'll match L1, but L1 hasn't switched back to ip yet, and it's a hit
// on the ip address we're looking for. => make sure the cache controller
// is IDLE.
always @*
	phit <= (ihit&&icstate==IDLE) && !invicl && icstate==IDLE;
always @(posedge clk)
if (rst_i)
	phitd <= 1'b1;
else begin
	if (phit & nextb)
		phitd <= phit;
end

wire [`ABITS] btgt [0:QSLOTS-1];
wire nextb;		// fetch next bundle
wire [127:0] ibundlep;
wire [39:0] insnxp [0:QSLOTS-1];
wire [7:0] templatep [0:QSLOTS-1];
reg invdcl;
reg [AMSB:0] invlineAddr;
wire L1_invline;
wire [79:0] L1_adr, L2_adr;
wire [257:0] L1_dat, L2_dat;
wire L1_wr, L2_wr;
wire L1_selpc;
wire L2_ld;
wire L1_ihit, L2_ihit, L2_ihita;
assign ihit = L1_ihit;
wire L1_nxt, L2_nxt;					// advances cache way lfsr
wire [2:0] L2_cnt;
wire [255:0] ROM_dat;

wire d0L1_wr, d0L2_ld;
wire d1L1_wr, d1L2_ld;
wire [79:0] d0L1_adr, d0L2_adr;
wire [79:0] d1L1_adr, d1L2_adr;
wire d0L1_rhit, d0L2_rhit, d0L2_whit;
wire d0L1_nxt, d0L2_nxt;					// advances cache way lfsr
wire d1L1_dhit, d1L2_rhit, d1L2_whit;
wire d1L1_nxt, d1L2_nxt;					// advances cache way lfsr
wire [40:0] d0L1_sel, d0L2_sel;
wire [40:0] d1L1_sel, d1L2_sel;
wire [329:0] d0L1_dat, d0L2_rdat, d0L2_wdat;
wire [329:0] d1L1_dat, d1L2_rdat, d1L2_wdat;
wire d0L1_dhit, d0L2_hit;
wire d0L1_selpc, d0L2_selpc;
wire d1L1_selpc, d1L2_selpc;
wire d0L1_invline,d1L1_invline;
reg [255:0] dcbuf;

reg preload;
reg [1:0] dccnt;
reg [3:0] dcwait = 4'd3;
reg [3:0] dcwait_ctr = 4'd3;
wire dhit0, dhit1;
wire dhit0a, dhit1a;
wire dhit00, dhit10;
wire dhit01, dhit11;
reg [`ABITS] dcadr;
reg [WID-1:0] dcdat;
reg dcwr;
reg [9:0] dcsel;
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
reg iack_i;
reg iexv_i;
reg ierr_i;

wire [2:0] d0cti;
wire [1:0] d0bte;
wire [1:0] d0ol = 2'b00;
wire d0cyc;
wire d0stb;
wire d0we = 1'b0;
wire [15:0] d0sel;
wire [AMSB:0] d0adr;
reg d0ack_i;
reg d0rdv_i;
reg d0wrv_i;
reg d0err_i;

wire [2:0] d1cti;
wire [1:0] d1bte;
wire [1:0] d1ol = 2'b00;
wire d1cyc;
wire d1stb;
wire d1we = 1'b0;
wire [15:0] d1sel;
wire [AMSB:0] d1adr;
reg d1ack_i;
reg d1rdv_i;
reg d1wrv_i;
reg d1err_i;

wire [1:0] wol;
wire wcyc;
wire wstb;
wire wwe;
wire [15:0] wsel;
wire [AMSB:0] wadr;
wire [127:0] wdat;
wire wcr;
reg wack_i;
reg werr_i;
reg wrdv_i;
reg wwrv_i;
reg wtlbmiss_i;

reg [1:0] dol;
reg [2:0] dcti;
reg [1:0] dbte;
reg dcyc;
reg dstb;
reg dack_i;
reg derr_i;
reg dwe;
reg [15:0] dsel;
reg [AMSB:0] dadr;
reg [127:0] ddat;

function [8:0] fnUnits;
input [6:0] tmp;
case(tmp)
7'h0: fnUnits = {`BUnit,`BUnit,`BUnit};
7'h1: fnUnits = {`IUnit,`BUnit,`BUnit};
7'h2: fnUnits = {`FUnit,`BUnit,`BUnit};
7'h3: fnUnits = {`MUnit,`BUnit,`BUnit};
7'h4: fnUnits = {`BUnit,`IUnit,`BUnit};
7'h5: fnUnits = {`IUnit,`IUnit,`BUnit};
7'h6: fnUnits = {`FUnit,`IUnit,`BUnit};
7'h7: fnUnits = {`MUnit,`IUnit,`BUnit};
7'h8: fnUnits = {`BUnit,`FUnit,`BUnit};
7'h9: fnUnits = {`IUnit,`FUnit,`BUnit};
7'ha: fnUnits = {`FUnit,`FUnit,`BUnit};
7'hb: fnUnits = {`MUnit,`FUnit,`BUnit};
7'hc: fnUnits = {`BUnit,`MUnit,`BUnit};
7'hd: fnUnits = {`IUnit,`MUnit,`BUnit};
7'he: fnUnits = {`FUnit,`MUnit,`BUnit};
7'hf: fnUnits = {`MUnit,`MUnit,`BUnit};
7'h10: fnUnits = {`BUnit,`BUnit,`IUnit};
7'h11: fnUnits = {`IUnit,`BUnit,`IUnit};
7'h12: fnUnits = {`FUnit,`BUnit,`IUnit};
7'h13: fnUnits = {`MUnit,`BUnit,`IUnit};
7'h14: fnUnits = {`BUnit,`IUnit,`IUnit};
7'h15: fnUnits = {`IUnit,`IUnit,`IUnit};
7'h16: fnUnits = {`FUnit,`IUnit,`IUnit};
7'h17: fnUnits = {`MUnit,`IUnit,`IUnit};
7'h18: fnUnits = {`BUnit,`FUnit,`IUnit};
7'h19: fnUnits = {`IUnit,`FUnit,`IUnit};
7'h1a: fnUnits = {`FUnit,`FUnit,`IUnit};
7'h1b: fnUnits = {`MUnit,`FUnit,`IUnit};
7'h1c: fnUnits = {`BUnit,`MUnit,`IUnit};
7'h1d: fnUnits = {`IUnit,`MUnit,`IUnit};
7'h1e: fnUnits = {`FUnit,`MUnit,`IUnit};
7'h1f: fnUnits = {`MUnit,`MUnit,`IUnit};
7'h20: fnUnits = {`BUnit,`BUnit,`FUnit};
7'h21: fnUnits = {`IUnit,`BUnit,`FUnit};
7'h22: fnUnits = {`FUnit,`BUnit,`FUnit};
7'h23: fnUnits = {`MUnit,`BUnit,`FUnit};
7'h24: fnUnits = {`BUnit,`IUnit,`FUnit};
7'h25: fnUnits = {`IUnit,`IUnit,`FUnit};
7'h26: fnUnits = {`FUnit,`IUnit,`FUnit};
7'h27: fnUnits = {`MUnit,`IUnit,`FUnit};
7'h28: fnUnits = {`BUnit,`FUnit,`FUnit};
7'h29: fnUnits = {`IUnit,`FUnit,`FUnit};
7'h2a: fnUnits = {`FUnit,`FUnit,`FUnit};
7'h2b: fnUnits = {`MUnit,`FUnit,`FUnit};
7'h2c: fnUnits = {`BUnit,`MUnit,`FUnit};
7'h2d: fnUnits = {`IUnit,`MUnit,`FUnit};
7'h2e: fnUnits = {`FUnit,`MUnit,`FUnit};
7'h2f: fnUnits = {`MUnit,`MUnit,`FUnit};
7'h30: fnUnits = {`BUnit,`BUnit,`MUnit};
7'h31: fnUnits = {`IUnit,`BUnit,`MUnit};
7'h32: fnUnits = {`FUnit,`BUnit,`MUnit};
7'h33: fnUnits = {`MUnit,`BUnit,`MUnit};
7'h34: fnUnits = {`BUnit,`IUnit,`MUnit};
7'h35: fnUnits = {`IUnit,`IUnit,`MUnit};
7'h36: fnUnits = {`FUnit,`IUnit,`MUnit};
7'h37: fnUnits = {`MUnit,`IUnit,`MUnit};
7'h38: fnUnits = {`BUnit,`FUnit,`MUnit};
7'h39: fnUnits = {`IUnit,`FUnit,`MUnit};
7'h3a: fnUnits = {`FUnit,`FUnit,`MUnit};
7'h3b: fnUnits = {`MUnit,`FUnit,`MUnit};
7'h3c: fnUnits = {`BUnit,`MUnit,`MUnit};
7'h3d: fnUnits = {`IUnit,`MUnit,`MUnit};
7'h3e: fnUnits = {`FUnit,`MUnit,`MUnit};
7'h3f: fnUnits = {`MUnit,`MUnit,`MUnit};

7'h7D: fnUnits = {`IUnit,`NUnit,`NUnit};
7'h7E: fnUnits = {`FUnit,`NUnit,`NUnit};
default:	fnUnits = {`NUnit,`NUnit,`NUnit};
endcase
endfunction

function mxtbl;
input [2:0] units;
case(units)
`BUnit:	mxtbl = 8'h00;	// branch,branch,branch
`IUnit:	mxtbl = 8'h01;	// int, branch, branch
`FUnit:	mxtbl = 8'h02;
`MUnit:	mxtbl = 8'h03;
default:	mxtbl = 8'hFF;
endcase
endfunction

function [2:0] Unit0;
input [6:0] tmp;
reg [8:0] units;
units = fnUnits(tmp);
Unit0 = units[8:6];
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
Unit2 = units[2:0];
endfunction

function IsNop;
input [2:0] unit;
input [39:0] ins;
IsNop = unit==`BUnit && ins[`OPCODE4]==`NOP;
endfunction

assign slotu[0] = Unit0(template[0]);
assign slotu[1] = Unit1(template[1]);
assign slotu[2] = Unit2(template[2]);
assign slotup[0] = Unit0(templatep[0]);
assign slotup[1] = Unit1(templatep[1]);
assign slotup[2] = Unit2(templatep[2]);

regfile_valid urfv1
(
	.rst(rst_i),
	.clk(clk),
	.slotvd(slotvd),
	.slot_rfw(slot_rfw),
	.tails(tails),
	.livetarget(livetarget),
	.branchmiss(branchmiss),
	.commit0_v(commit0_v),
	.commit1_v(commit1_v),
	.commit0_id(commit0_id),
	.commit1_id(commit1_id),
	.commit0_tgt(commit0_tgt),
	.commit1_tgt(commit1_tgt),
	.rf_source(rf_source),
	.iq_source(iq_source),
	.take_branch(take_branch),
	.Rd(Rd),
	.queuedOn(queuedOnp),
	.rf_v(rf_v)
);

regfile_source urfs1
(
	.rst(rst_i),
	.clk(clk),
	.branchmiss(branchmiss),
	.slotvd(slotvd),
	.slot_rfw(slot_rfw),
	.queuedOn(queuedOnp),
	.Rd(Rd),
	.tails(tails),
	.iq_latestID(iq_latestID),
	.iq_tgt(iq_tgt),
	.rf_source(rf_source)
);

Regfile urf1
(
	.clk(clk_i),
	.clk2x(clk2x_i),
	.wr0(commit0_v),
	.wa0({rgs,commit0_tgt}),
	.i0(commit0_bus),
	.wr1(commit1_v),
	.wa1({rgs,commit1_tgt}),
	.i1(commit1_bus),
	.rclk(~clk_i),
	.ra0({rgs,Rs1[0]}),
	.ra1({rgs,Rs2[0]}),
	.ra2({rgs,Rs3[0]}),
	.ra3({rgs,Rs1[1]}),
	.ra4({rgs,Rs2[1]}),
	.ra5({rgs,Rs3[1]}),
	.ra6({rgs,Rs1[2]}),
	.ra7({rgs,Rs2[2]}),
	.ra8({rgs,Rs3[2]}),
	.o0(rfoa[0]),
	.o1(rfob[0]),
	.o2(rfoc[0]),
	.o3(rfoa[1]),
	.o4(rfob[1]),
	.o5(rfoc[1]),
	.o6(rfoa[2]),
	.o7(rfob[2]),
	.o8(rfoc[2])
);


instruction_pointer uip1
(
	.rst(rst_i),
	.clk(clk),
	.queuedCnt(queuedCnt),
	.insnx(insnx),
	.phit(phit),
	.freezeip(freezeip),
	.next_bundle(nextb),
	.branchmiss(branchmiss),
	.missip(missip),
	.ip_mask(ip_mask),
	.ip_maskd(ip_maskd),
	.slotv(slotv),
	.slotvd(slotvd),
	.slot_jc(slot_jc),
	.slot_ret(slot_ret),
	.slot_br(slot_br),
	.take_branch(take_branch),
	.btgt(btgt),
	.ip(ip),
	.ipd(ipd),
	.branch_ip(next_ip),
	.ra(ra),
	.ip_override(ip_override),
	.debug_on(debug_on)
);

RSB ursb1
(
	.rst(rst_i),
	.clk(clk),
	.clk2x(clk2x_i),
	.clk4x(clk4x_i),
	.regLR(6'd61),
	.queuedOn(queuedOn),
	.jal(slot_jal),
	.Ra(Rs1),
	.Rd(Rd),
	.call(slot_call),
	.ret(slot_ret),
	.ip(ipd),
	.ra(ra),
	.stompedRets(),
	.stompedRet()
);

next_bundle unb1
(
	.rst(rst_i),
	.slotv(slotv),
	.phit(phit),
	.next(nextb)
);

ICController uicc1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.ip(ip),
	.hit(L1_ihit),
	.bstate(bstate),
	.state(icstate),
	.invline(invicl),
	.invlineAddr(invlineAddr),
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
	.L1_invline(L1_invline),
	.ROM_dat(ROM_dat),
	.isROM(isROM),
	.icnxt(L1_nxt),
	.icwhich(),
	.icl_o(icl_o),
	.cti_o(icti),
	.bte_o(ibte),
	.bok_i(bok_i),
	.cyc_o(icyc),
	.stb_o(istb),
	.ack_i(iack_i),
	.err_i(ierr_i),
	.tlbmiss_i(tlb_miss),
	.exv_i(iexv_i),
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
	.invall(invic),
	.invline(L1_invline)
);

L2_icache uic2
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(L2_nxt),
	.wr(L2_ld),
	.adr(L2_ld ? L2_adr : L1_adr),
	.cnt(L2_cnt),
	.exv_i(1'b0),
	.i(dat_i),
	.err_i(1'b0),
	.o(L2_dat),
	.hit(L2_ihit),
	.invall(invic),
	.invline(L1_invline)
);

assign L2_ihit = isROM|L2_ihita;

reg [12:0] rL1_adr;
reg [255:0] rommem [0:7167];
initial begin
`include "d:/cores6/rtfItanium/v1/software/boot/boottc.ve0"
end
always @(posedge clk)
	rL1_adr <= L1_adr[17:5];
assign ROM_dat = rommem[rL1_adr];

//wire predict_taken;
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
  .clk(clk_i),
  .clk2x(clk2x_i),
  .clk4x(clk4x_i),
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
  .btgtA(btgt[0]),
  .pcB({ip[AMSB:4],4'h5}),
  .btgtB(btgt[1]),
  .pcC({ip[AMSB:4],4'hA}),
  .btgtC(btgt[2]),
  .npcA({ip[AMSB:4],4'h5}),
  .npcB({ip[AMSB:4],4'hA}),
  .npcC({ip[AMSB:4]+4'h1,4'h0})
);

wire [AMSB:0] ips [0:QSLOTS-1];
generate begin : gips
	if (QSLOTS==1)
begin
assign ips[0] = ipd;
assign ips[1] = ipd;
assign ips[2] = ipd;
end
	else if (QSLOTS==3)
begin
assign ips[0] = {ipd[AMSB:4],4'h0};
assign ips[1] = {ipd[AMSB:4],4'h5};
assign ips[2] = {ipd[AMSB:4],4'hA};
end
	else if (QSLOTS==6)
begin
assign ips[0] = {ipd[AMSB:4],4'h0};
assign ips[1] = {ipd[AMSB:4],4'h5};
assign ips[2] = {ipd[AMSB:4],4'hA};
assign ips[3] = {ipd[AMSB:4]+2'd1,4'h0};
assign ips[4] = {ipd[AMSB:4]+2'd1,4'h5};
assign ips[5] = {ipd[AMSB:4]+2'd1,4'hA};
end
end
endgenerate

wire [3:0] xisBr;
wire [AMSB:0] xip [0:3];
wire [3:0] xtkb;

assign xisBr[0] = iq_br[heads[0]] & commit0_v & ~iq_instr[heads[0]][5];
assign xisBr[1] = iq_br[heads[1]] & commit1_v & ~iq_instr[heads[1]][5];
assign xisBr[2] = iq_br[heads[2]] & commit2_v & ~iq_instr[heads[2]][5];
assign xisBr[3] = 1'b0;
assign xip[0] = iq_ip[heads[0]];
assign xip[1] = iq_ip[heads[1]];
assign xip[2] = iq_ip[heads[2]];
assign xip[3] = 1'd0;
assign xtkb[0] = commit0_v & iq_takb[heads[0]];
assign xtkb[1] = commit1_v & iq_takb[heads[1]];
assign xtkb[2] = commit2_v & iq_takb[heads[2]];
assign xtkb[3] = 1'b0;

wire [QSLOTS-1:0] predict_takenx;

BranchPredictor ubp1
(
  .rst(rst_i),
  .clk(clk_i),
  .clk2x(clk2x_i),
  .clk4x(clk4x_i),
  .en(bpe),
  .xisBranch(xisBr),
  .xip(xip),
  .takb(xtkb),
  .ip(ips),
  .predict_taken(predict_takenx)
);

assign predict_taken[0] = insnx[0][5]==1'b1 ? insnx[0][4] : predict_takenx[0];
assign predict_taken[1] = insnx[1][5]==1'b1 ? insnx[1][4] : predict_takenx[1];
assign predict_taken[2] = insnx[2][5]==1'b1 ? insnx[2][4] : predict_takenx[2];


reg StoreAck1, isStore;
wire [199:0] dc0_out, dc1_out;
wire whit0, whit1, whit2;

wire wr_dcache0 = (dcwr)||(((bstate==B_StoreAck && StoreAck1) || (bstate==B_LSNAck && isStore)) && whit0);
wire wr_dcache1 = (dcwr)||(((bstate==B_StoreAck && StoreAck1) || (bstate==B_LSNAck && isStore)) && whit1);
wire rd_dcache0 = !dram0_unc & (dram0_load | dram0_rmw);
wire rd_dcache1 = !dram1_unc & (dram1_load | dram1_rmw);

DCController udcc1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.dadr(dram0_addr),
	.rd(rd_dcache0),
	.wr(dcwr),
	.wsel(dcsel),
	.wadr(dcadr),
	.wdat(dcdat),
	.bstate(bstate),
	.state(),
	.invline(invdcl),
	.invlineAddr(invlineAddr),
	.icl_ctr(),
	.dL2_rhit(d0L2_rhit),
	.dL2_rdat(d0L2_rdat),
	.dL2_whit(d0L2_whit),
	.dL2_ld(d0L2_ld),
	.dL2_wsel(d0L2_sel),
	.dL2_wadr(d0L2_adr),
	.dL2_wdat(d0L2_wdat),
	.dL2_nxt(d0L2_nxt),
	.dL1_hit(d0L1_dhit),
	.dL1_selpc(d0L1_selpc),
	.dL1_sel(d0L1_sel),
	.dL1_adr(d0L1_adr),
	.dL1_dat(d0L1_dat),
	.dL1_wr(d0L1_wr),
	.dL1_invline(d0L1_invline),
	.dcnxt(),
	.dcwhich(),
	.dcl_o(),
	.cti_o(d0cti),
	.bte_o(d0bte),
	.bok_i(bok_i),
	.cyc_o(d0cyc),
	.stb_o(d0stb),
	.ack_i(d0ack_i),
	.err_i(d0err_i),
	.wrv_i(d0wrv_i),
	.rdv_i(d0rdv_i),
	.sel_o(d0sel),
	.adr_o(d0adr),
	.dat_i(dat_i)
);

L1_dcache udc1
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d0L1_nxt),
	.wr(d0L1_wr),
	.wadr(d0L1_adr),
	.adr(d0L1_selpc ? dram0_addr : d0L1_adr),
	.i(d0L1_dat),
	.o(dc0_out),
	.fault(),
	.hit(d0L1_dhit),
	.invall(invdc),
	.invline(d0L1_invline)
);

L2_dcache udc2
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d0L2_nxt),
	.wr(d0L2_ld),
	.wadr(d0L2_adr),
	.radr(d0L1_adr),
	.sel(d0L2_sel),
	.rdv_i(1'b0),
	.wrv_i(1'b0),
	.i(d0L2_wdat),
	.err_i(1'b0),
	.o(d0L2_rdat),
	.rhit(d0L2_rhit),
	.whit(d0L2_whit),
	.invall(invdc),
	.invline(d0L1_invline)
);


DCController udcc2
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.dadr(dram1_addr),
	.rd(rd_dcache1),
	.wr(dcwr),
	.wsel(dcsel),
	.wadr(dcadr),
	.wdat(dcdat),
	.bstate(bstate),
	.state(),
	.invline(invdcl),
	.invlineAddr(invlineAddr),
	.icl_ctr(),
	.dL2_rhit(d1L2_rhit),
	.dL2_rdat(d1L2_rdat),
	.dL2_whit(d1L2_whit),
	.dL2_ld(d1L2_ld),
	.dL2_wsel(d1L2_sel),
	.dL2_wadr(d1L2_adr),
	.dL2_wdat(d1L2_wdat),
	.dL2_nxt(d1L2_nxt),
	.dL1_hit(d1L1_dhit),
	.dL1_selpc(d1L1_selpc),
	.dL1_sel(d1L1_sel),
	.dL1_adr(d1L1_adr),
	.dL1_dat(d1L1_dat),
	.dL1_wr(d1L1_wr),
	.dL1_invline(d1L1_invline),
	.dcnxt(),
	.dcwhich(),
	.dcl_o(),
	.cti_o(d1cti),
	.bte_o(d1bte),
	.bok_i(bok_i),
	.cyc_o(d1cyc),
	.stb_o(d1stb),
	.ack_i(d1ack_i),
	.err_i(d1err_i),
	.wrv_i(d1wrv_i),
	.rdv_i(d1rdv_i),
	.sel_o(d1sel),
	.adr_o(d1adr),
	.dat_i(dat_i)
);

L1_dcache udc3
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d1L1_nxt),
	.wr(d1L1_wr),
	.wadr(d1L1_adr),
	.adr(d1L1_selpc ? dram1_addr : d1L1_adr),
	.i(d1L1_dat),
	.o(dc1_out),
	.fault(),
	.hit(d1L1_dhit),
	.invall(invdc),
	.invline(d1L1_invline)
);

L2_dcache udc4
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d1L2_nxt),
	.wr(d1L2_ld),
	.wadr(d1L2_adr),
	.radr(d1L1_adr),
	.sel(d1L2_sel),
	.rdv_i(1'b0),
	.wrv_i(1'b0),
	.i(d1L2_wdat),
	.err_i(1'b0),
	.o(d1L2_rdat),
	.rhit(d1L2_rhit),
	.whit(d1L2_whit),
	.invall(invdc),
	.invline(d1L1_invline)
);

wire [199:0] rdat0, rdat1;
assign rdat0 = dram0_unc ? xdati[199:0] : dc0_out;
assign rdat1 = dram1_unc ? xdati[199:0] : dc1_out;
reg [79:0] rmw_ad0, rmw_ad1;
wire [79:0] aligned_data0 = fnDatiAlign(dram0_instr,dram0_addr,rdat0);
wire [79:0] aligned_data1 = fnDatiAlign(dram1_instr,dram1_addr,rdat1);
assign dhit0a = d0L1_dhit;
assign dhit1a = d1L1_dhit;

wire [7:0] wb_fault;
wire wb_q0_done, wb_q1_done;
wire wb_has_bus;
assign dhit0 = dhit0a && !wb_hit0;
assign dhit1 = dhit1a && !wb_hit1;
wire wb_p0_wr = (dram0==`DRAMSLOT_BUSY && dram0_store)
							 || (dram0==`DRAMSLOT_RMW2 && dram0_rmw);
wire wb_p1_wr = (dram1==`DRAMSLOT_BUSY && dram1_store)
							 || (dram1==`DRAMSLOT_RMW2 && dram1_rmw);

write_buffer #(.QENTRIES(QENTRIES)) uwb1
(
	.rst_i(rst_i),
	.clk_i(clk),
	.bstate(bstate),
	.cyc_pending(cyc_pending),
	.wb_has_bus(wb_has_bus),
	.wb_v(wb_v),
	.wb_addr(wb_addr),
	.update_iq(update_iq),
	.uid(uid),
	.fault(wb_fault),
	.p0_id_i(dram0_id),
	.p0_ol_i(dram0_ol),
	.p0_wr_i(wb_p0_wr),
	.p0_ack_o(wb_q0_done),
	.p0_sel_i(fnSelect(dram0_rmw ? `MUnit: `MUnit,dram0_instr)),
	.p0_adr_i(dram0_addr),
	.p0_dat_i(dram0_data),
	.p0_hit(wb_hit0),
	.p1_id_i(dram1_id),
	.p1_ol_i(dram1_ol),
	.p1_wr_i(wb_p1_wr),
	.p1_ack_o(wb_q1_done),
	.p1_sel_i(fnSelect(dram1_rmw ? `MUnit: `MUnit,dram1_instr)),
	.p1_adr_i(dram1_addr),
	.p1_dat_i(dram1_data),
	.p1_hit(wb_hit1),
	.ol_o(wol),
	.cyc_o(wcyc),
	.stb_o(wstb),
	.ack_i(wack_i),
	.err_i(werr_i),
	.tlbmiss_i(wtlbmiss_i),
	.wrv_i(wwrv_i),
	.we_o(wwe),
	.sel_o(wsel),
	.adr_o(wadr),
	.dat_o(wdat),
	.cr_o(wcr),
	.cwr_o(dcwr),
	.csel_o(dcsel),
	.cadr_o(dcadr),
	.cdat_o(dcdat)
);

headptrs uhp1
(
	.rst(rst_i),
	.clk(clk),
	.amt(hi_amt),
	.heads(heads)
);

tailptrs utp1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.branchmiss(branchmiss),
	.iq_stomp(iq_stomp),
	.iq_br_tag(iq_br_tag),
	.queuedCnt(queuedCnt),
	.tails(tails),
	.active_tag(miss_tag)
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
`else
assign debug_on = FALSE;
`endif

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

decode_buffer udcb1
(
	.rst(rst_i),
	.clk(clk),
	.irq_i(irq_i),
	.im(im),
	.cause_i(cause_i),
	.freezeip(freezeip),
	.int_commit(int_commit),
	.ic_fault(ic_fault),
	.ic_out(ic_out),
	.codebuf(codebuf),
	.phit(phit),
	.next_bundle(nextb),
	.ibundlep(ibundlep),
	.templatep(templatep),
	.insnxp(insnxp),
	.ibundle(ibundle),
	.template(template),
	.insnx(insnx)
);


function [6:0] fnRd;
input [2:0] unit;
input [39:0] ins;
case(unit)
`BUnit:
	case(ins[`OPCODE4])
	`CALL:	fnRd = 7'd61;
	`JAL:		fnRd = {1'b0,ins[`RD]};
	`RET:		fnRd = {1'b0,ins[`RD]};
	`BMISC:	fnRd = ins[39:35]==`SEI ? {1'b0,ins[`RD]} : 7'd0;
	default:	fnRd = 7'd0;
	endcase
`IUnit:	fnRd = {1'b0,ins[`RD]};
`FUnit:
	if (ins[`OPCODE4]==`FLT1)
		case(ins[`FUNCT5])
		`FTOI:	fnRd = {1'b0,ins[`RD]};
		default:	fnRd = {1'b1,ins[`RD]};
		endcase
	else
		fnRd = {1'b1,ins[`RD]};
`MUnit: 
	casez(mopcode(ins))
	`PUSH:	fnRd = {1'b0,ins[`RD]};
	`PUSHC:	fnRd = {1'b0,ins[`RD]};
	`TLB:		fnRd = {1'b0,ins[`RD]};
	`LOAD:
		case(mopcode(ins))
		`LDFS,`LDFD:
					fnRd = {1'b1,ins[`RD]};
		default:	fnRd = {1'b0,ins[`RD]};
		endcase
	default:	fnRd = 6'd0;
	endcase
`NUnit:		fnRd = 1'd0;
default:	fnRd = 1'd0;
endcase
endfunction

function [6:0] fnRs1;
input [2:0] unit;
input [39:0] ins;
case(unit)
`BUnit:	fnRs1 = {1'b0,ins[`RS1]};
`IUnit:	fnRs1 = {1'b0,ins[`RS1]};
`FUnit:
	case(ins[`OPCODE4])	
	`FLT1:	// FLT2 or FLT1
		case(ins[`FUNCT5])
		`ITOF:	fnRs1 = {1'b0,ins[`RS1]};
		default:	fnRs1 = {1'b1,ins[`RS1]};
		endcase
	default:	fnRs1 = {1'b1,ins[`RS1]};
	endcase
`MUnit:	fnRs1 = {1'b0,ins[`RS1]};
default:	fnRs1 = 1'd0;
endcase
endfunction

function [6:0] fnRs2;
input [2:0] unit;
input [39:0] ins;
case(unit)
`BUnit:	fnRs2 = {1'b0,ins[`RS2]};
`IUnit:	fnRs2 = {1'b0,ins[`RS2]};
`FUnit:	fnRs2 = {1'b1,ins[`RS2]};
`MUnit:	fnRs2 = {1'b0,ins[`RS2]};
default:	fnRs2 = 1'd0;
endcase
endfunction

function [6:0] fnRs3;
input [2:0] unit;
input [39:0] ins;
case(unit)
`BUnit:	fnRs3 = {1'b0,ins[`RS3]};
`IUnit:	fnRs3 = {1'b0,ins[`RS3]};
`FUnit:	fnRs3 = {1'b1,ins[`RS3]};
`MUnit:	fnRs3 = {1'b0,ins[`RS3]};
default:	fnRs3 = 1'd0;
endcase
endfunction

assign Rs1[0] = fnRs1(slotu[0],insnx[0]);
assign Rs2[0] = fnRs2(slotu[0],insnx[0]);
assign Rs3[0] = fnRs3(slotu[0],insnx[0]);
assign Rd[0] = fnRd(slotu[0],insnx[0]);
assign Rs1[1] = fnRs1(slotu[1],insnx[1]);
assign Rs2[1] = fnRs2(slotu[1],insnx[1]);
assign Rs3[1] = fnRs3(slotu[1],insnx[1]);
assign Rd[1] = fnRd(slotu[1],insnx[1]);
assign Rs1[2] = fnRs1(slotu[2],insnx[2]);
assign Rs2[2] = fnRs2(slotu[2],insnx[2]);
assign Rs3[2] = fnRs3(slotu[2],insnx[2]);
assign Rd[2] = fnRd(slotu[2],insnx[2]);

function [5:0] mopcode;
input [39:0] isn;
mopcode = {isn[34:33],isn[`OPCODE4]};
endfunction

// Detect if a source is automatically valid
function Source1Valid;
input [2:0] unit;
input [39:0] isn;
case(unit)
`BUnit:	
	case(isn[`OPCODE4])
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
	`BMISC:
		case(isn[`FUNCT5])
		`RTI:	Source1Valid = isn[`RS1]==6'd0;
		`SEI:	Source1Valid = isn[`RS1]==6'd0;
		`REX:	Source1Valid = isn[`RS1]==6'd0;
		default: Source1Valid = TRUE;
		endcase
	default:	Source1Valid = TRUE;
	endcase
`IUnit:	Source1Valid = isn[`RS1]==6'd0;
`FUnit:
	case(isn[`OPCODE4])
	`FLT1:
		case(isn[`FUNCT5])
		`FSYNC:		Source1Valid = TRUE;
		default:	Source1Valid = isn[`RS1]==6'd0;
		endcase
	`FANDI:	Source1Valid = isn[`RS1]==6'd0;
	`FORI:	Source1Valid = isn[`RS1]==6'd0;
	`FLT2:	Source1Valid = isn[`RS1]==6'd0;
	`FLT2I:	Source1Valid = isn[`RS1]==6'd0;
	`FLT2LI:Source1Valid = isn[`RS1]==6'd0;
	`FLT3:
		case(isn[`FUNCT5])
		`FMA:		Source1Valid = isn[`RS1]==6'd0;
		`FMS:		Source1Valid = isn[`RS1]==6'd0;
		`FNMA:	Source1Valid = isn[`RS1]==6'd0;
		`FNMS:	Source1Valid = isn[`RS1]==6'd0;
		`FMAX:	Source1Valid = isn[`RS1]==6'd0;
		`FMIN:	Source1Valid = isn[`RS1]==6'd0;
		default:	Source1Valid = isn[`RS1]==6'd0;
		endcase
	default:	Source1Valid = TRUE;
	endcase
`MUnit:
	case(mopcode(isn))
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
	case(isn[`OPCODE4])
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
	`BMISC:
		case(isn[`FUNCT5])
		`RTI:	Source2Valid = TRUE;
		`REX:	Source2Valid = TRUE;
		default: Source2Valid = TRUE;
		endcase
	default:	Source2Valid = TRUE;
	endcase
`IUnit:	
	casez({isn[32:31],isn[`OPCODE4]})
	`R3:
		case(isn[`FUNCT5])
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
	case(isn[`OPCODE4])
	`FLT1:
		case(isn[`FUNCT5])
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
	`FLT2:			Source2Valid = isn[`RS2]==6'd0;
	`FLT2I:			Source2Valid = TRUE;
	`FLT2LI:		Source2Valid = TRUE;
	`FLT3:			Source2Valid = isn[`RS2]==6'd0;
	`FANDI:	Source2Valid = TRUE;
	`FORI:	Source2Valid = TRUE;
	default:	Source2Valid = TRUE;
	endcase
`MUnit:
	casez(mopcode(isn))
	`PUSHC:	Source2Valid = TRUE;
	`STORE:	Source2Valid = isn[`RS2]==6'd0;
	default:	Source2Valid = TRUE;
	endcase
default:	Source2Valid = TRUE;
endcase
endfunction

function Source3Valid;
input [2:0] unit;
input [39:0] isn;
case(unit)
`BUnit:
	case(isn[`OPCODE4])
	`CHK:		Source3Valid = isn[`RS3]==6'd0;
	`BRcc:	Source3Valid = isn[`RS3]==6'd0;
	default:	Source3Valid = TRUE;
	endcase
`IUnit:
	case({isn[32:31],isn[`OPCODE4]})
	`R3:	Source3Valid = isn[`RS3]==6'd0;
	`BITFIELD:	Source3Valid = isn[`RS3]==6'd0;
	`CSRRW:	Source3Valid = TRUE;
	default:	Source3Valid = TRUE;
	endcase
`FUnit:
	case(isn[`OPCODE4])
	`FLT1:	Source3Valid = TRUE;
	`FLT2:	Source3Valid = TRUE;
	`FLT2I:	Source3Valid = TRUE;
	`FLT2LI:	Source3Valid = TRUE;
	default:	Source3Valid = isn[`RS3]==6'd0;
	endcase
`MUnit:	
	case(mopcode(isn))
	`MLX:			Source3Valid = isn[`RS3]==6'd0;
	`MSX:			Source3Valid = isn[`RS3]==6'd0;
	default:	Source3Valid = TRUE;
	endcase
default: Source3Valid = TRUE;
endcase
endfunction

function IsMem;
input [2:0] unit;
IsMem = unit==`MUnit;
endfunction

function IsMemNdx;
input [2:0] unit;
input [39:0] isn;
if (IsMem(unit)) begin
	IsMemNdx = (mopcode(isn)==`MLX) || (mopcode(isn)==`MSX)
						;
end
else
	IsMemNdx = FALSE;
endfunction


function IsSWC;
input [2:0] unit;
input [39:0] isn;
if (unit==`MUnit)
	IsSWC = mopcode(isn)==`STDC || (mopcode(isn)==`MSX && isn[`FUNCT5]==`STDCX);
else
	IsSWC = FALSE;
endfunction

function IsSWCX;
input [2:0] unit;
input [39:0] isn;
if (unit==`MUnit)
	IsSWCX = (mopcode(isn)==`MSX && isn[`FUNCT5]==`STDCX);
else
	IsSWCX = FALSE;
endfunction

function IsLea;
input [2:0] unit;
input [39:0] isn;
if (unit==`MUnit)
	IsLea = mopcode(isn)==`LEA || (mopcode(isn)==`MLX && isn[`FUNCT5]==`LEA);
else
	IsLea = FALSE;
endfunction

function IsLWR;
input [2:0] unit;
input [39:0] isn;
if (unit==`MUnit)
	IsLWR = mopcode(isn)==`LDDR || (mopcode(isn)==`MLX && isn[`FUNCT5]==`LDDR);
else
	IsLWR = FALSE;
endfunction

function IsLWRX;
input [2:0] unit;
input [39:0] isn;
if (unit==`MUnit)
	IsLWRX = mopcode(isn)==`MLX && isn[`FUNCT5]==`LDDR;
else
	IsLWRX = FALSE;
endfunction

function IsCAS;
input [2:0] unit;
input [39:0] isn;
if (unit==`MUnit)
	IsCAS = mopcode(isn)==`CAS || (mopcode(isn)==`MSX && isn[`FUNCT5]==`CAS);
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

function IsBranchReg;
input [2:0] unit;
input [39:0] isn;
if (unit==`BUnit)
	IsBranchReg = isn[`OPCODE4]==`BRcc;
else
	IsBranchReg = FALSE;
endfunction

function IsWait;
input [2:0] unit;
input [39:0] isn;
IsWait = unit==`BUnit && isn[`OPCODE4]==`BMISC && isn[`FUNCT5]==`WAIT;
endfunction

function IsCall;
input [2:0] unit;
input [39:0] isn;
IsCall = unit==`BUnit && isn[`OPCODE4]==`CALL;
endfunction

function IsJal;
input [2:0] unit;
input [39:0] isn;
IsJal = unit==`BUnit && isn[`OPCODE4]==`JAL;
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
IsCache = unit==`MUnit && (mopcode(isn)==`CACHE || (mopcode(isn)==`MSX && isn[`FUNCT5]==`CACHEX));
endfunction

function [4:0] CacheCmd;
input [39:0] isn;
CacheCmd = isn[`RS2];
endfunction

function IsMemsb;
input [2:0] unit;
input [39:0] isn;
IsMemsb = unit==`MUnit && mopcode(isn)==`MSX && isn[`FUNCT5]==`MEMSB; 
endfunction

function IsSEI;
input [2:0] unit;
input [39:0] isn;
IsSEI = unit==`BUnit && isn[`OPCODE4]==`BMISC && isn[`FUNCT5]==`SEI; 
endfunction

function IsRet;
input [2:0] unit;
input [39:0] isn;
IsRet = unit==`BUnit && isn[`OPCODE4]==`RET;
endfunction

function IsRFW;
input [2:0] unit;
input [39:0] isn;
if (fnRd(unit,isn)==6'd0) 
    IsRFW = FALSE;
else
case(unit)
`BUnit:
	case(isn[`OPCODE4])
	`BMISC:		IsRFW = isn[`FUNCT5]==`SEI;
	`JAL:     IsRFW = TRUE;
	`CALL:    IsRFW = TRUE;  
	`RET:     IsRFW = TRUE; 
	default:	IsRFW = FALSE;
	endcase
`IUnit:	IsRFW = TRUE;
`FUnit:
	case(isn[`OPCODE4])
	`FLT1:
		case(isn[`FUNCT5])
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
`MUnit:
	casez(mopcode(isn))
	`LOAD:	IsRFW = TRUE;
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
	casez({isn[32:31],isn[`OPCODE4]})
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

function IsExec;
input [2:0] unit;
input [39:0] isn;
IsExec = unit==`BUnit && (isn[`OPCODE4]==`BMISC && isn[`FUNCT5]==`EXEC);
endfunction

function IsPfi;
input [2:0] unit;
input [39:0] isn;
IsPfi = unit==`BUnit && (isn[`OPCODE4]==`BRK && isn[`FUNCT5]==`PFI);
endfunction

function IsBrk;
input [2:0] unit;
input [39:0] isn;
IsBrk = unit==`BUnit && (isn[`OPCODE4]==`BRK && isn[`FUNCT5]==5'd0);
endfunction

function IsRti;
input [2:0] unit;
input [39:0] isn;
IsRti = unit==`BUnit && (isn[`OPCODE4]==`BMISC && isn[`FUNCT5]==`RTI);
endfunction

function IsDivmod;
input [2:0] unit;
input [39:0] isn;
if (unit==`IUnit)
	casez({isn[32:31],isn[`OPCODE4]})
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
`MUnit:
	case(mopcode(isn))
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
	`AMO:
		case(isn[`SZ3])
		3'd0:		fnSelect = 10'h001;
		3'd1:		fnSelect = 10'h003;
		3'd2:		fnSelect = 10'h00F;
		3'd3:		fnSelect = 10'h01F;
		3'd4:		fnSelect = 10'h0FF;
		3'd5:		fnSelect = 10'h3FF;
		default:	fnSelect = 10'h000;
		endcase
	`STB:	fnSelect = 10'h001;
	`STC:	fnSelect = 10'h003;
	`STT:	fnSelect = 10'h00F;
	`STP:	fnSelect = 10'h01F;
	`STO:	fnSelect = 10'h0FF;
	`STD:	fnSelect = 10'h3FF;
	`STDC:	fnSelect = 10'h3FF;
	`CAS:	fnSelect = 10'h3FF;
	`PUSH:	
		case(isn[`FUNCT5])
		5'h01:	fnSelect = 10'h001;
		5'h02:	fnSelect = 10'h003;
		5'h04:	fnSelect = 10'h00F;
		5'h05:	fnSelect = 10'h01F;
		5'h08:	fnSelect = 10'h0FF;
		5'h0A:	fnSelect = 10'h3FF;
		default:	fnSelect = 10'h3FF;
		endcase
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
case(mopcode(ins))
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
if (unit==`MUnit)
	case(mopcode(isn))
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
decoder7 iq0 (
	.num(iq_tgt[g][6:0]),
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


//RMW_alu urmwalu0 (rmw_instr, rmw_argA, rmw_argB, rmw_argC, rmw_res);



// Stores might exception so we don't want the heads to advance if a subsequent
// instruction is store even though there's no target register.
wire cmt_head1 = (!iq_rfw[heads[1]] && !iq_oddball[heads[1]] && ~|iq_exc[heads[1]]);
wire cmt_head2 = (!iq_rfw[heads[2]] && !iq_oddball[heads[2]] && ~|iq_exc[heads[2]]);

// Determine the head increment amount, this must match code later on.
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
		if (heads[0] != tails[0] && heads[1] != tails[0] && heads[2] != tails[0])
			hi_amt <= 3'd3;
		else if (heads[0] != tails[0] && heads[1] != tails[0])
			hi_amt <= 3'd2;
		else if (heads[0] != tails[0])
			hi_amt <= 3'd1;
	6'b0?_0?_10:
		if (heads[0] != tails[0] && heads[1] != tails[0])
			hi_amt <= 3'd2;
		else if (heads[0] != tails[0])
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
  	if (heads[1] != tails[0] && heads[2] != tails[0])
			hi_amt <= 3'd3;
  	else if (heads[1] != tails[0])
			hi_amt <= 3'd2;
  	else
			hi_amt <= 3'd1;
  6'b11_0?_10:
  	if (heads[1] != tails[0])
			hi_amt <= 3'd2;
  	else
			hi_amt <= 3'd1;
  6'b11_0?_11:
  	if (heads[1] != tails[0]) begin
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
  	if (`NUM_CMT > 1 && heads[2] != tails[0])
			hi_amt <= 3'd3;
  	else if (cmt_head1 && heads[2] != tails[0])
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
        || (iq_argA_s[g] == alu0_sourceid && alu0_vsn)
        || ((iq_argA_s[g] == alu1_sourceid && alu1_vsn) && (`NUM_ALU > 1))
        || ((iq_argA_s[g] == fpu1_sourceid && fpu1_dataready) && (`NUM_FPU > 0))
        || ((iq_argA_s[g] == fpu2_sourceid && fpu2_dataready) && (`NUM_FPU > 1))
`endif
        )
    && (iq_argB_v[g] || iq_mem[g]	// a2 does not need to be valid immediately for a mem op (agen), it is checked by iq_memready logic
`ifdef FU_BYPASS
        || (iq_argB_s[g] == alu0_sourceid && alu0_vsn)
        || ((iq_argB_s[g] == alu1_sourceid && alu1_vsn) && (`NUM_ALU > 1))
        || ((iq_argB_s[g] == fpu1_sourceid && fpu1_dataready) && (`NUM_FPU > 0))
        || ((iq_argB_s[g] == fpu2_sourceid && fpu2_dataready) && (`NUM_FPU > 1))
`endif
        )
    && (iq_argC_v[g] 
        || (iq_mem[g] & ~iq_agen[g] & ~iq_memndx[g])    // a3 needs to be valid for indexed instruction
//        || (iq_mem[g] & ~iq_agen[g])
`ifdef FU_BYPASS
        || (iq_argC_s[g] == alu0_sourceid && alu0_vsn)
        || ((iq_argC_s[g] == alu1_sourceid && alu1_vsn) && (`NUM_ALU > 1))
        || ((iq_argC_s[g] == fpu1_sourceid && fpu1_dataready) && (`NUM_FPU > 0))
        || ((iq_argC_s[g] == fpu2_sourceid && fpu2_dataready) && (`NUM_FPU > 1))
`endif
        )
    ;

assign could_issue[g] = iq_v[g] && iq_state[g]==IQS_QUEUED	&& args_valid[g];
                        //&& (iq_mem[g] ? !iq_agen[g] : 1'b1);

assign could_issueid[g] = (iq_v[g]);// || (g==tails[0] && canq1))// || (g==tails[1] && canq2))
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
				if (could_issue[heads[n]] && iq_alu[heads[n]] && !iq_alu0[heads[n]]
					&& !iq_alu0_issue[heads[n]]
					&& iq_alu1_issue == {QENTRIES{1'b0}}
					&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
				)
				  iq_alu1_issue[heads[n]] = `TRUE;
			end
//		end
	end
end

always @*
begin
	iq_agen0_issue = {QENTRIES{1'b0}};
	iq_agen1_issue = {QENTRIES{1'b0}};
	
	if (agen0_idle) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_mem[heads[n]]
			&& iq_agen0_issue == {QENTRIES{1'b0}}
			// If there are no valid queue entries prior it doesn't matter if there is
			// a sync.
			&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
			)
			  iq_agen0_issue[heads[n]] = `TRUE;
		end
	end

	if (agen1_idle && `NUM_AGEN > 1) begin
//		if ((could_issue & ~iq_alu0_issue & ~iq_alu0) != {QENTRIES{1'b0}}) begin
			for (n = 0; n < QENTRIES; n = n + 1) begin
				if (could_issue[heads[n]] && iq_mem[heads[n]]
					&& !iq_agen0_issue[heads[n]]
					&& iq_agen1_issue == {QENTRIES{1'b0}}
					&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
				)
				  iq_agen1_issue[heads[n]] = `TRUE;
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
memissueLogic umi1
(
	.heads(heads),
	.iq_v(iq_v),
	.iq_memready(iq_memready),
	.iq_out(iq_out),
	.iq_done(iq_done),
	.iq_mem(iq_mem),
	.iq_agen(iq_agen), 
	.iq_load(iq_load),
	.iq_store(iq_store),
	.iq_fc(iq_fc),
	.iq_aq(iq_aq),
	.iq_rl(iq_rl),
	.iq_ma(iq_ma),
	.iq_memsb(iq_memsb),
	.iq_memdb(iq_memdb),
	.iq_stomp(iq_stomp),
	.iq_canex(iq_canex), 
	.wb_v(wb_v),
	.inwb0(inwb0),
	.inwb1(inwb1),
	.sple(sple),
	.memissue(memissue),
	.issue_count(issue_count)
);


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
		j = missid;
		k = (missid + 1) % QENTRIES;
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (iq_v[k]) begin
				if (iq_br_tag[k]==br_tag[j]) begin
					iq_stomp[k] <= `TRUE;
					if (is_qbranch[k])
						j = k;
				end
			end
			k = (k + 1) % QENTRIES;
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

//wire [143:0] id_bus[0], id_bus[1], id_bus[2];

generate begin : idecoders
for (g = 0; g < QSLOTS; g = g + 1)
begin
idecoder uid1
(
	.unit(slotu[g]),
	.instr(insnx[g]),
	.Rt(Rd[g][5:0]),
	.predict_taken(predict_taken[g]),
	.bus(id_bus[g]),
	.debug_on(debug_on)
);
end
end
endgenerate

//
// EXECUTE
//
wire [15:0] lfsro;
//lfsr #(16,16'hACE4) u1 (rst_i, clk_i, 1'b1, 1'b0, lfsro);

reg [79:0] csr_r;
wire [13:0] csrno = {alu0_instr[37:36],alu0_instr[27:16]};
always @*
begin
    if (csrno[13:12] >= ol)
    casez(csrno[11:0])
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
    `CSR_IPC0:      csr_r <= ipc0;
    `CSR_IPC1:      csr_r <= ipc1;
    `CSR_IPC2:      csr_r <= ipc2;
    `CSR_IPC3:      csr_r <= ipc3;
    `CSR_IPC4:      csr_r <= ipc4;
    `CSR_IPC5:      csr_r <= ipc5;
    `CSR_IPC6:      csr_r <= ipc6;
    `CSR_IPC7:      csr_r <= ipc7;
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
alu #(.BIG(1'b1),.SUP_VECTOR(1'b0)) ualu1 (
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

agen uag1(agen0_unit, agen0_instr, agen0_argA, agen0_argB, agen0_argC, agen0_ma, agen0_idle);
agen uag2(agen1_unit, agen1_instr, agen1_argA, agen1_argB, agen1_argC, agen1_ma, agen1_idle);
assign agen0_id = agen0_sourceid;
assign agen1_id = agen1_sourceid;
assign agen0_v = agen0_dataready;
assign agen1_v = agen1_dataready;

wire tlb_done;
wire tlb_idle;
wire [79:0] tlbo;
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
	.exv_o(exv),
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
assign alu0_vsn = alu0_v;// && iq_v[alu0_id] && alu0_sn==iq_sn[alu0_id];
assign alu1_vsn = alu1_v;// && iq_v[alu1_id] && alu1_sn==iq_sn[alu1_id];
assign agen0_vsn = agen0_v;// && iq_v[agen0_id] && agen0_sn==iq_sn[agen0_id] && iq_state[agen0_id] != IQS_MEM;
assign agen1_vsn = agen1_v;// && iq_v[agen1_id] && agen1_sn==iq_sn[agen1_id] && iq_state[agen1_id] != IQS_MEM;

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

fpUnit #(84) ufp1
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
fpUnit #(84) ufp1
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
    `CHKI:  begin
              fcu_exc <= fcu_argA >= fcu_argB && fcu_argA < fcu_argI ? `FLT_NONE : `FLT_CHK;
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
	.nextpc(fcu_nextip),
	.im(im),
	.waitctr(waitctr),
	.bus(fcu_out)
);

wire will_clear_branchmiss = branchmiss && (
															(slotv[0] && slot0ip[AMSB:2]==missip[AMSB:2])
															|| (slotv[1] && slot1ip[AMSB:2]==missip[AMSB:2])
															|| (slotv[2] && slot2ip[AMSB:2]==missip[AMSB:2])
															);

always @*
begin
case(fcu_instr[`OPCODE4])
`BMISC:	fcu_missip = fcu_ipc;		// RTI (we don't bother fully decoding this as it's the only R2)
`RET:	fcu_missip = fcu_argB;
`REX:	fcu_missip = fcu_bus;
`BRK:	fcu_missip = {tvec[0][AMSB:8], 1'b0, olm, 5'h0};
`JAL:	fcu_missip = fcu_argA + fcu_argI;
`BRcc:	fcu_missip = fcu_argC;
//`JMP,`CALL:	fcu_missip = {fcu_ip[AMSB:38],fcu_instr[39:10],fcu_instr[5:0],fcu_instr[1:0]};
//`CHK:	fcu_missip = fcu_nextip + fcu_argI;	// Handled as an instruction exception
// Default: branch
default:	fcu_missip = fcu_pt ? fcu_nextip : {fcu_ip[AMSB:4]+fcu_brdisp[AMSB:4],fcu_brdisp[3:0]};
endcase
fcu_missip[0] = 1'b0;
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
	fcu_branchhit <= (fcu_branch && !(fcu_takb ^ fcu_pt))
		|| (fcu_ret && (fcu_argB == iq_ip[nid]))
		|| (fcu_jal && (fcu_argA + fcu_argI == iq_ip[nid]))
		 ;
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
// Also, if it's a large immediate bundle, don't try and execute the immediate.
always @*
if (templatep[0]==7'h7D || templatep[0]==7'h7E)
	ip_mask = 3'b001;
else
	case(ip[3:2])
	2'b00:	ip_mask = 3'b111;
	2'b01:	ip_mask = 3'b110;
	2'b10:	ip_mask = 3'b100;
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
	iq_memready[n] <= (iq_v[n] & iq_memopsvalid[n] & ~iq_memissue[n] & ~iq_stomp[n]);

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
  		commit2_tgt <= 6'h000;
  	end
	end
	else begin
		commit1_v <= ({iq_v[heads[0]], iq_state[heads[0]] == IQS_CMT} != 2'b10
							 && {iq_v[heads[1]], iq_state[heads[1]] == IQS_CMT} == 2'b11
               && !iq_rfw[heads[1]] && ~|panic);	// watch out for dbnz and ibne
  	commit1_id <= {iq_mem[heads[1]], heads[1]};	// if a memory op, it has a DRAM-bus id
		commit1_tgt <= 6'h000;
		// We don't really need the bus value since nothing is being written.
    commit1_bus <= iq_res[heads[1]];
		commit2_v <= ({iq_v[heads[0]], iq_state[heads[0]] == IQS_CMT} != 2'b10
							 && {iq_v[heads[1]], iq_state[heads[1]] == IQS_CMT} != 2'b10
							 && {iq_v[heads[2]], iq_br[heads[2]], iq_state[heads[2]] == IQS_CMT}==3'b111
               && !iq_rfw[heads[2]] && ~|panic);	// watch out for dbnz and ibne
  	commit2_id <= {iq_mem[heads[2]], heads[2]};	// if a memory op, it has a DRAM-bus id
		commit2_tgt <= 6'h000;
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

		if (commit0_v && n=={commit0_tgt[RBIT:0]} && !rf_v[n])
			regIsValid[n] = ((rf_source[ {commit0_tgt[RBIT:0]} ] == commit0_id) || (branchmiss && iq_source[ commit0_id[`QBITS] ]));
		if (commit1_v && n=={commit1_tgt[RBIT:0]} && !rf_v[n] && `NUM_CMT > 1)
			regIsValid[n] = ((rf_source[ {commit1_tgt[RBIT:0]} ] == commit1_id) || (branchmiss && iq_source[ commit1_id[`QBITS] ]));
		if (commit2_v && n=={commit2_tgt[RBIT:0]} && !rf_v[n] && `NUM_CMT > 2)
			regIsValid[n] = ((rf_source[ {commit2_tgt[RBIT:0]} ] == commit2_id) || (branchmiss && iq_source[ commit2_id[`QBITS] ]));
	end
	regIsValid[0] = `VAL;
	regIsValid[64] = `VAL;
end

// Wait until the cycle after Rs1 becomes valid to give time to read
// the vector element from the register file.
reg rf_vra0, rf_vra1, rf_vra2;
/*always @(posedge clk)
    rf_vra0 <= regIsValid[Ra0s];
always @(posedge clk)
    rf_vra1 <= regIsValid[Ra1s];
*/

// Check how many instructions can be queued. 
getQueuedCount ugqc1
(
	.branchmiss(branchmiss),
	.tails(tails),
	.slotvd(slotvd),
	.slot_jc(slot_jc),
	.slot_ret(slot_ret),
	.take_branch(take_branch),
	.iq_v(iq_v),
	.queuedCnt(queuedCnt),
	.queuedOnp(queuedOnp),
	.debug_on(debug_on)
);

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
		wc_time[39:0] <= wc_time[39:0] + 32'd1;
		if (wc_time[39:0] >= TM_CLKFREQ-1) begin
			wc_time[39:0] <= 32'd0;
			wc_time[79:40] <= wc_time[79:40] + 32'd1;
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
//    missip <= excmiss ? excmissip : fcu_missip;
//    missid <= excmiss ? (|iq_exc[heads[0]] ? heads[0] : heads[1]) : fcu_sourceid;
//	branchmiss_thrd <=  excmiss ? excthrd : fcu_thrd;
//end
wire alu0_done_pe, alu1_done_pe, pe_wait;
edge_det uedalu0d (.clk(clk), .ce(1'b1), .i(alu0_done&tlb_done), .pe(alu0_done_pe), .ne(), .ee());
edge_det uedalu1d (.clk(clk), .ce(1'b1), .i(alu1_done), .pe(alu1_done_pe), .ne(), .ee());
edge_det uedwait1 (.clk(clk), .ce(1'b1), .i((waitctr==48'd1) || signal_i[fcu_argA[4:0]|fcu_argI[4:0]]), .pe(pe_wait), .ne(), .ee());

// Bus randomization to mitigate meltdown attacks
/*
wire [WID-1:0] ralu0_bus = |alu0_exc ? {5{lfsro}} : alu0_tlb ? tlbo : alu0_bus;
wire [WID-1:0] ralu1_bus = |alu1_exc ? {5{lfsro}} : alu1_bus;
wire [WID-1:0] rfpu1_bus = |fpu1_exc ? {5{lfsro}} : fpu1_bus;
wire [WID-1:0] rfpu2_bus = |fpu2_exc ? {5{lfsro}} : fpu2_bus;
wire [WID-1:0] rfcu_bus  = |fcu_exc  ? {5{lfsro}} : fcu_bus;
wire [WID-1:0] rdramA_bus = dramA_bus;
wire [WID-1:0] rdramB_bus = dramB_bus;
*/
wire [WID-1:0] ralu0_bus = alu0_tlb ? tlbo : alu0_bus;
wire [WID-1:0] ralu1_bus = alu1_bus;
wire [WID+3:0] rfpu1_bus = fpu1_bus;
wire [WID+3:0] rfpu2_bus = fpu2_bus;
wire [WID-1:0] rfcu_bus  = fcu_bus;
wire [WID-1:0] rdramA_bus = dramA_bus;
wire [WID-1:0] rdramB_bus = dramB_bus;

reg [2:0] mwhich;
reg [3:0] mstate;
always @(posedge clk)
if (rst_i) begin
	mwhich <= 3'd5;
	mstate <= 1'd0;
end
else begin
	case(mstate)
	4'd0:
	if (~ack_i) begin
		if (icyc) begin
			mwhich <= 3'd0;
			mstate <= 4'd1;
		end
		else if (wb_has_bus) begin
			mwhich <= 3'd1;
			mstate <= 4'd1;
		end
		else if (d0cyc) begin
			mwhich <= 3'd2;
			mstate <= 4'd1;
		end
		else if (d1cyc) begin
			mwhich <= 3'd3;
			mstate <= 4'd1;
		end
		else if (dcyc) begin
			mwhich <= 3'd4;
			mstate <= 4'd1;
		end
		else begin
			mwhich <= 3'd5;
		end
	end
4'd1:
	if (~cyc)
		mstate <= 4'd0;
endcase
end

always @(posedge clk)
case(mwhich)
3'd0:
	begin
		cti_o <= icti;
		bte_o <= ibte;
		cyc <= icyc;
		stb_o <= istb;
		we <= 1'b0;
		sel_o <= isel;
		vadr <= iadr;
	end
3'd1:
	begin
		cti_o <= 3'b000;
		bte_o <= 2'b00;
		cyc <= wcyc;
		stb_o <= wstb;
		we <= wwe;
		sel_o <= wsel;
		vadr <= wadr;
		dat_o <= wdat;
	end
3'd2:
	begin
		cti_o <= d0cti;
		bte_o <= d0bte;
		cyc <= d0cyc;
		stb_o <= d0stb;
		we <= `LOW;
		sel_o <= d0sel;
		vadr <= d0adr;
	end
3'd3:
	begin
		cti_o <= d1cti;
		bte_o <= d1bte;
		cyc <= d1cyc;
		stb_o <= d1stb;
		we <= `LOW;
		sel_o <= d1sel;
		vadr <= d1adr;
	end
3'd4:
	begin
		cti_o <= 3'b000;
		bte_o <= 2'b00;
		cyc <= dcyc;
		stb_o <= dstb;
		we <= dwe;
		sel_o <= dsel;
		vadr <= dadr;
		dat_o <= ddat;
	end
3'd5:
	begin
		cti_o <= 3'b000;
		bte_o <= 2'b00;
		cyc <= 1'b0;
		stb_o <= 1'b0;
		we <= 1'b0;
		sel_o <= 16'h0;
		vadr <= 1'h0;
		dat_o <= 1'h0;
	end
endcase

always @*
case(mwhich)
3'd0:
	begin
		iack_i <= ack_i;
		ierr_i <= err_i;
		iexv_i <= exv;
	end
3'd1:
	begin
		wack_i <= ack_i;
		werr_i <= err_i;
		wwrv_i <= wrv_i;
		wrdv_i <= rdv_i;
		wtlbmiss_i <= tlb_miss;
	end
3'd2:
	begin
		d0ack_i <= ack_i;
		d0err_i <= err_i;
		d0wrv_i <= wrv_i;
		d0rdv_i <= rdv_i;
	end
3'd3:
	begin
		d1ack_i <= ack_i;
		d1err_i <= err_i;
		d1wrv_i <= wrv_i;
		d1rdv_i <= rdv_i;
	end
3'd4:
	begin
		dack_i <= ack_i;
		derr_i <= err_i;
//		dwrv_i <= wrv_i;
//		drdv_i <= rdv_i;
	end
default:
	begin
		iack_i <= `LOW;
		ierr_i <= `LOW;
		iexv_i <= `LOW;
		wack_i <= `LOW;
		werr_i <= `LOW;
		wwrv_i <= `LOW;
		wrdv_i <= `LOW;
		wtlbmiss_i <= `LOW;
		d0ack_i <= `LOW;
		d0err_i <= `LOW;
		d0wrv_i <= `LOW;
		d0rdv_i <= `LOW;
		d1ack_i <= `LOW;
		d1err_i <= `LOW;
		d1wrv_i <= `LOW;
		d1rdv_i <= `LOW;
		dack_i <= `LOW;
		derr_i <= `LOW;
	end
endcase

// Hold reset for five seconds
reg [31:0] rst_ctr;
always @(posedge clk)
if (rst_i)
	rst_ctr <= 32'd0;
else begin
	if (rst_ctr < 32'd10)
		rst_ctr <= rst_ctr + 24'd1;
end

slot_valid usv1
(
	.rst(rst_i),
	.clk(clk),
	.branchmiss(branchmiss),
	.phit(phit),
	.nextb(nextb),
	.ip_mask(ip_mask),
	.ip_maskd(ip_maskd),
	.ip_override(ip_override),
	.queuedCnt(queuedCnt),
	.slot_jc(slot_jc),
	.slot_ret(slot_ret),
	.take_branch(take_branch),
	.slotv(slotv),
	.slotvd(slotvd),
	.debug_on(debug_on)
);

always @(posedge clk)
if (rst_i|(rst_ctr < 32'd2)) begin
	im_stack <= 32'hFFFFFFFF;
	mstatus <= 64'h4000F;	// select register set #16 for thread 0
	rs_stack <= 64'd0;
	brs_stack <= 64'd16;
    for (n = 0; n < QENTRIES; n = n + 1) begin
    	iq_state[n] <= IQS_INVALID;
       iq_is[n] <= 3'b00;
       iq_sn[n] <= 1'd0;
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
       iq_ip[n] <= RSTIP;
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
     dram0_rmw <= 1'b0;
     dram1_rmw <= 1'b0;
     dram0_load <= 1'b0;
     dram1_load <= 1'b0;
     dram0_unc <= 1'b0;
     dram1_unc <= 1'b0;
     dram0_store <= 1'b0;
     dram1_store <= 1'b0;
     invic <= FALSE;
     invicl <= FALSE;
     panic = `PANIC_NONE;
     alu0_dataready <= 1'b0;
     alu1_dataready <= 1'b0;
     alu0_sourceid <= 5'd0;
     alu1_sourceid <= 5'd0;
`define SIM_
`ifdef SIM_
		alu0_ip <= RSTIP;
		alu0_instr <= `NOP_INSN;
		alu0_argA <= 64'h0;
		alu0_argB <= 64'h0;
		alu0_argC <= 64'h0;
		alu0_argI <= 64'h0;
		alu0_mem <= 1'b0;
		alu0_shft <= 1'b0;
		alu0_tgt <= 6'h00;
		alu1_ip <= RSTIP;
		alu1_instr <= `NOP_INSN;
		alu1_argA <= 64'h0;
		alu1_argB <= 64'h0;
		alu1_argC <= 64'h0;
		alu1_argI <= 64'h0;
		alu1_mem <= 1'b0;
		alu1_shft <= 1'b0;
		alu1_tgt <= 6'h00;  
		agen0_argA <= 1'd0;
		agen0_argB <= 1'd0;
		agen0_argC <= 1'd0;
		agen1_argA <= 1'd0;
		agen1_argB <= 1'd0;
		agen1_argC <= 1'd0;
`endif
     fcu_dataready <= 0;
     fcu_instr <= `NOP_INSN;
     fcu_call <= 1'b0;
     dramA_v <= 0;
     dramB_v <= 0;
     I <= 0;
     CC <= 0;
     bstate <= BIDLE;
     tick <= 1'd0;
     ol_o <= 2'b0;
     cyc_pending <= `LOW;
     sr_o <= `LOW;
     cr_o <= `LOW;
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
     fp_rm <= 3'd0;			// round nearest even - default rounding mode
     fpu_csr[37:32] <= 5'd31;	// register set #31
     waitctr <= 48'd0;
    for (n = 0; n < 16; n = n + 1) begin
      badaddr[n] <= 64'd0;
      bad_instr[n] <= `NOP_INSN;
    end
     fcu_done <= `TRUE;
     sema <= 64'h0;
     tvec[0] <= RSTIP;
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
		dcyc <= `LOW;
		dstb <= `LOW;
		dwe <= `LOW;
		dsel <= 16'h0000;
		dadr <= RSTIP;
		ddat <= 128'h0;
		fpu1_instr <= 40'h0;
		fpu1_ld <= FALSE;
		fpu1_argA <= 80'h0;
		fpu1_argB <= 80'h0;
		fpu1_argI <= 80'h0;
		fpu2_instr <= 40'h0;
		fpu2_ld <= FALSE;
		fpu2_argA <= 80'h0;
		fpu2_argB <= 80'h0;
		fpu2_argI <= 80'h0;
`ifdef SUPPORT_DEBUG
		dbg_ctrl <= 64'h0;
`endif
		active_tag <= 1'd0;
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
			missip <= excmissip;
			missid <= (|iq_exc[heads[0]] ? heads[0] : |iq_exc[heads[1]] ? heads[1] : heads[2]);
		end
		else if (fcu_branchmiss) begin
			branchmiss <= `TRUE;
			missip <= fcu_missip;
			missid <= fcu_sourceid;
		end
	end
	else
		active_tag <= miss_tag;
	// Clear a branch miss when target instruction is fetched.
	if (will_clear_branchmiss) begin
		branchmiss <= `FALSE;
	end

	// Sequence numbers are adjusted every clock cycle by the number of
	// instructions comitted.
//	for (n = 0; n < QENTRIES; n = n + 1)
//		if (iq_v[n])  
//			iq_sn[n] <= iq_sn[n] - tosub;

	// The following signals only pulse

	// Instruction decode output should only pulse once for a queue entry. We
	// want the decode to be invalidated after a clock cycle so that it isn't
	// inadvertently used to update the queue at a later point.
	dramA_v <= `INV;
	dramB_v <= `INV;
	ld_time <= {ld_time[4:0],1'b0};
	wc_times <= wc_time;
     rf_vra0 <= regIsValid[Rs1[0]];
     rf_vra1 <= regIsValid[Rs1[1]];
     rf_vra2 <= regIsValid[Rs1[2]];

	excmiss <= FALSE;
	invic <= FALSE;
	if (L1_invline)
		invicl <= FALSE;
	invdcl <= FALSE;
	tick <= tick + 4'd1;
	alu0_ld <= FALSE;
	alu1_ld <= FALSE;
	fpu1_ld <= FALSE;
	fpu2_ld <= FALSE;
	fcu_ld <= FALSE;
	cr0[17] <= 1'b0;
	queuedOn <= 1'b0;

  if (waitctr != 48'd0)
		waitctr <= waitctr - 4'd1;

  if (iq_fc[fcu_id[`QBITS]] && iq_v[fcu_id[`QBITS]] && !iq_done[fcu_id[`QBITS]] && iq_out[fcu_id[`QBITS]])
  	fcu_timeout <= fcu_timeout + 8'd1;

	if (!branchmiss) begin
		queuedOn <= queuedOnp;
		case(slotvd)
		3'b001:
			if (queuedOnp[0])
				queue_slot(0,tails[0],3'h0,id_bus[0],active_tag);
		3'b010:
			if (queuedOnp[1])
				queue_slot(1,tails[0],3'h0,id_bus[1],active_tag);
		3'b011:
			if (queuedOnp[0]) begin
				queue_slot(0,tails[0],3'h0,id_bus[0],active_tag);
				if (queuedOnp[1]) begin
					queue_slot(1,tails[1],3'h1,id_bus[1],is_branch[0] ? active_tag+2'd1 : active_tag);
					arg_vs(3'b011);
				end
			end
		3'b100:
			if (queuedOnp[2])
				queue_slot(2,tails[0],3'h0,id_bus[2],active_tag);
		3'b101:	;	// illegal
		3'b110:
			if (queuedOnp[1]) begin
				queue_slot(1,tails[0],3'h0,id_bus[1],active_tag);
				if (queuedOnp[2]) begin
					queue_slot(2,tails[1],3'h1,id_bus[2],is_branch[1] ? active_tag + 2'd1 : active_tag);
					arg_vs(3'b110);
				end
			end
		3'b111:
			if (queuedOnp[0]) begin
				queue_slot(0,tails[0],3'h0,id_bus[0],active_tag);
				if (queuedOnp[1]) begin
					queue_slot(1,tails[1],3'h1,id_bus[1],is_branch[0] ? active_tag + 2'd1 : active_tag);
					arg_vs(3'b011);
					if (queuedOnp[2]) begin
						queue_slot(2,tails[2],3'h2,id_bus[2],
							is_branch[0] && is_branch[1] ? active_tag + 2'd2 :
							is_branch[0] ? active_tag + 2'd1 : is_branch[1] ? active_tag + 2'd1 : active_tag);
						arg_vs(3'b111);
					end
				end
			end
		default:	;
		endcase
		if (queuedOnp[0])
			br_tag[tails[0]] <= active_tag + is_branch[0];
		if (queuedOnp[1])
			br_tag[tails[1]] <= active_tag + (queuedOnp[0] & is_branch[0]) + is_branch[1];
		if (queuedOnp[2])
			br_tag[tails[2]] <= active_tag + (queuedOnp[0] & is_branch[0]) + (queuedOnp[1] & is_branch[1]) + is_branch[2];
		active_tag <= active_tag + (queuedOnp[0] & is_branch[0]) + (queuedOnp[1] & is_branch[1]) + (queuedOnp[2] & is_branch[2]);
	end

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

if (alu0_vsn) begin
	iq_tgt [ alu0_id[`QBITS] ] <= alu0_tgt;
	iq_res	[ alu0_id[`QBITS] ] <= {ralu0_bus,4'd0};
	iq_exc	[ alu0_id[`QBITS] ] <= alu0_exc;
	if (alu0_done) begin
		iq_state[alu0_id[`QBITS]] <= IQS_CMT;
	end
	if (|alu0_exc) begin
		iq_store[alu0_id[`QBITS]] <= `INV;
		iq_state[alu0_id[`QBITS]] <= IQS_CMT;
	end
	//alu0_dataready <= FALSE;
end

if (alu1_vsn && `NUM_ALU > 1) begin
	iq_tgt [ alu1_id[`QBITS] ] <= alu1_tgt;
	iq_res	[ alu1_id[`QBITS] ] <= {ralu1_bus,4'd0};
	iq_exc	[ alu1_id[`QBITS] ] <= alu1_exc;
	if (alu1_done) begin
		iq_state[alu1_id[`QBITS]] <= IQS_CMT;
	end
	if (|alu1_exc) begin
		iq_store[alu1_id[`QBITS]] <= `INV;
		iq_state[alu1_id[`QBITS]] <= IQS_CMT;
	end
	//alu1_dataready <= FALSE;
end

if (agen0_v) begin
	iq_tgt[agen0_id[`QBITS]] <= agen0_tgt;
	iq_state[agen0_id[`QBITS]] <= agen0_lea ? IQS_CMT : IQS_AGEN;
	iq_res[agen0_id[`QBITS]] <= {agen0_ma,4'd0};		// LEA needs this result
	iq_exc[agen0_id[`QBITS]] <= `FLT_NONE;
	if (iq_state[agen0_id[`QBITS]]!=IQS_AGEN)
		iq_ma[agen0_id[`QBITS]] <= agen0_ma;
	agen0_dataready <= FALSE;
end

if (agen1_v && `NUM_AGEN > 1) begin
	iq_tgt[agen1_id[`QBITS]] <= agen1_tgt;
	iq_state[agen1_id[`QBITS]] <= agen1_lea ? IQS_CMT : IQS_AGEN;
	iq_res[agen1_id[`QBITS]] <= {agen1_ma,4'd0};		// LEA needs this result
	iq_exc[agen1_id[`QBITS]] <= `FLT_NONE;
	if (iq_state[agen1_id[`QBITS]]!=IQS_AGEN)
		iq_ma[agen1_id[`QBITS]] <= agen1_ma;
	agen1_dataready <= FALSE;
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
	iq_ma  [ fcu_id[`QBITS] ] <= fcu_missip;
  iq_res [ fcu_id[`QBITS] ] <= {rfcu_bus,4'd0};
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
	iq_res	[ dramA_id[`QBITS] ] <= {rdramA_bus,4'd0};
	iq_state[dramA_id[`QBITS] ] <= IQS_CMT;
	iq_aq  [ dramA_id[`QBITS] ] <= `INV;
end
if (`NUM_MEM > 1 && dramB_v && iq_v[ dramB_id[`QBITS] ]) begin
	iq_res	[ dramB_id[`QBITS] ] <= {rdramB_bus,4'd0};
	iq_state[dramB_id[`QBITS] ] <= IQS_CMT;
	iq_aq  [ dramB_id[`QBITS] ] <= `INV;
end

if (wb_q0_done) begin
	dram0 <= `DRAMREQ_READY;
	iq_state[ dram0_id[`QBITS] ] <= IQS_DONE;
end
if (wb_q1_done) begin
	dram1 <= `DRAMREQ_READY;
	iq_state[ dram1_id[`QBITS] ] <= IQS_DONE;
end

if (update_iq) begin
	for (n = 0; n < QENTRIES; n = n + 1) begin
		if (uid[n]) begin
      iq_exc[n] <= wb_fault;
     	iq_state[n] <= IQS_CMT;
			iq_aq[n] <= `INV;
		end
	end
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
	setargs(n,commit0_id,commit0_v,commit0_bus);
	if (`NUM_CMT > 1)
		setargs(n,commit1_id,commit1_v,commit1_bus);
	if (`NUM_CMT > 2)
		setargs(n,commit2_id,commit2_v,commit2_bus);

	if (`NUM_FPU > 0)
		setargs(n,fpu1_id,fpu1_v,rfpu1_bus);
	if (`NUM_FPU > 1)
		setargs(n,fpu2_id,fpu2_v,rfpu2_bus);

	setargs(n,alu0_id,alu0_vsn,{ralu0_bus,4'd0});
	if (`NUM_ALU > 1)
		setargs(n,alu1_id,alu1_vsn,{ralu1_bus,4'd0});

	setargs(n,agen0_id,agen0_v & (agen0_push|agen0_lea),{agen0_ma,4'd0});
	if (`NUM_AGEN > 1)
		setargs(n,agen1_id,agen1_v & (agen1_push|agen1_lea),{agen1_ma,4'd0});

	setargs(n,fcu_id,fcu_v,{rfcu_bus,4'd0});

	setargs(n,dramA_id,dramA_v,{rdramA_bus,4'd0});
	if (`NUM_MEM > 1)
		setargs(n,dramB_id,dramB_v,{rdramB_bus,4'd0});
end

// X's on unused busses cause problems in SIM.
    for (n = 0; n < QENTRIES; n = n + 1)
        if (iq_alu0_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (alu0_available & alu0_done) begin
            		 alu0_sn <= iq_sn[n];
                 alu0_sourceid	<= n[`QBITS];
                 alu0_instr	<= iq_rtop[n] ? (
`ifdef FU_BYPASS                 									
                 									iq_argC_v[n] ? iq_argC[n][WID+3:4]
			                            : (iq_argC_s[n] == alu0_id) ? ralu0_bus
			                            : (iq_argC_s[n] == alu1_id) ? ralu1_bus
			                            : (iq_argC_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus[WID+3:4]
			                            : `NOP_INSN)
`else			                           
																	iq_argC[n][WID+3:4]) 
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
                 // Agen output is not bypassed since there's only one
                 // instruction (LEA) to bypass for.
`ifdef FU_BYPASS
								 if (iq_argA_v[n])
								 	 alu0_argA <= iq_argA[n][WID+3:4];
								 else
	                 case(iq_argA_s[n])
	                 alu0_id:	alu0_argA <= ralu0_bus;
	                 alu1_id:	alu0_argA <= ralu1_bus;
	                 fpu1_id:	alu0_argA <= rfpu1_bus[WID+3:4];
	                 fpu2_id:	alu0_argA <= rfpu2_bus[WID+3:4];
	                 default:	alu0_argA <= 80'hDEADDEADDEADDEADDEAD;
	                 endcase
`else
								alu0_argA <= iq_argA[n][WID+3:4];               
`endif                 
`ifdef FU_BYPASS
								if (iq_imm[n])
									alu0_argB <= iq_argI[n];
								else if (iq_argB_v[n])
									alu0_argB <= iq_argB[n][WID+3:4];
								else
									case(iq_argB_s[n])
									alu0_id:	alu0_argB <= ralu0_bus;
									alu1_id:	alu0_argB <= ralu1_bus;
									fpu1_id:	alu0_argB <= rfpu1_bus[WID+3:4];
									fpu2_id:	alu0_argB <= rfpu2_bus[WID+3:4];
									default:	alu0_argB <= 80'hDEADDEADDEADDEADDEAD;
									endcase
`else
								if (iq_imm[n])
									alu0_argB <= iq_argI[n];
								else
									alu0_argB <= iq_argB[n][WID+3:4];
`endif
`ifdef FU_BYPASS
								 if (iq_argC_v[n])
								 	alu0_argC <= iq_argC[n][WID+3:4];
								 else
	                 case(iq_argC_s[n])
	                 alu0_id:	alu0_argC <= ralu0_bus;
	                 alu1_id:	alu0_argC <= ralu1_bus;
	                 fpu1_id:	alu0_argC <= rfpu1_bus[WID+3:4];
	                 fpu2_id:	alu0_argC <= rfpu2_bus[WID+3:4];
	                 default:	alu0_argC <= 80'hDEADDEADDEADDEADDEAD;
	                 endcase
`else
								alu0_argC <= iq_argC[n][WID+3:4];
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
            		 alu1_sn <= iq_sn[n];
                 alu1_sourceid	<= n[`QBITS];
                 alu1_instr	<= iq_instr[n];
                 alu1_sz    <= iq_sz[n];
                 alu1_mem   <= iq_mem[n];
                 alu1_load  <= iq_load[n];
                 alu1_store <= iq_store[n];
                 alu1_push  <= iq_push[n];
                 alu1_shft  <= iq_shft[n];
                 alu1_ip		<= iq_ip[n];
`ifdef FU_BYPASS
								 if (iq_argA_v[n])
								 	 alu1_argA <= iq_argA[n][WID+3:4];
								 else
	                 case(iq_argA_s[n])
	                 alu0_id:	alu1_argA <= ralu0_bus;
	                 alu1_id:	alu1_argA <= ralu1_bus;
	                 fpu1_id:	alu1_argA <= rfpu1_bus[WID+3:4];
	                 fpu2_id:	alu1_argA <= rfpu2_bus[WID+3:4];
	                 default:	alu1_argA <= 80'hDEADDEADDEADDEADDEAD;
	                 endcase
`else
								alu1_argA <= iq_argA[n][WID+3:4];               
`endif                 
`ifdef FU_BYPASS
								if (iq_imm[n])
									alu1_argB <= iq_argI[n];
								else if (iq_argB_v[n])
									alu1_argB <= iq_argB[n][WID+3:4];
								else
									case(iq_argB_s[n])
									alu0_id:	alu1_argB <= ralu0_bus;
									alu1_id:	alu1_argB <= ralu1_bus;
									fpu1_id:	alu1_argB <= rfpu1_bus[WID+3:4];
									fpu2_id:	alu1_argB <= rfpu2_bus[WID+3:4];
									default:	alu1_argB <= 80'hDEADDEADDEADDEADDEAD;
									endcase
`else
								if (iq_imm[n])
									alu1_argB <= iq_argI[n];
								else
									alu1_argB <= iq_argB[n][WID+3:4];
`endif
`ifdef FU_BYPASS
								 if (iq_argC_v[n])
								 	alu1_argC <= iq_argC[n][WID+3:4];
								 else
	                 case(iq_argC_s[n])
	                 alu0_id:	alu1_argC <= ralu0_bus;
	                 alu1_id:	alu1_argC <= ralu1_bus;
	                 fpu1_id:	alu1_argC <= rfpu1_bus[WID+3:4];
	                 fpu2_id:	alu1_argC <= rfpu2_bus[WID+3:4];
	                 default:	alu1_argC <= 80'hDEADDEADDEADDEADDEAD;
	                 endcase
`else
								alu1_argC <= iq_argC[n][WID+3:4];
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
        if (iq_agen0_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (1'b1) begin
            		agen0_sn <= iq_sn[n];
                 agen0_sourceid	<= n[`QBITS];
                 agen0_unit <= iq_unit[n];
                 agen0_instr	<= iq_instr[n];
                 agen0_lea  <= iq_lea[n];
                 agen0_push <= iq_push[n];
`ifdef FU_BYPASS
								 if (iq_argA_v[n])
								 	 agen0_argA <= iq_argA[n][WID+3:4];
								 else
	                 case(iq_argA_s[n])
	                 alu0_id:	agen0_argA <= ralu0_bus;
	                 alu1_id:	agen0_argA <= ralu1_bus;
	                 fpu1_id:	agen0_argA <= rfpu1_bus[WID+3:4];
	                 fpu2_id:	agen0_argA <= rfpu2_bus[WID+3:4];
	                 default:	agen0_argA <= 80'hDEADDEADDEADDEADDEAD;
	                 endcase
`else
								agen0_argA <= iq_argA[n][WID+3:4];
`endif                 
//                 agen0_argB	<= iq_argB[n];	// ArgB not used by agen
`ifdef FU_BYPASS
								 if (iq_argC_v[n])
								 	agen0_argC <= iq_argC[n][WID+3:4];
								 else
	                 case(iq_argC_s[n])
	                 alu0_id:	agen0_argC <= ralu0_bus;
	                 alu1_id:	agen0_argC <= ralu1_bus;
	                 fpu1_id:	agen0_argC <= rfpu1_bus[WID+3:4];
	                 fpu2_id:	agen0_argC <= rfpu2_bus[WID+3:4];
	                 default:	agen0_argC <= 80'hDEADDEADDEADDEADDEAD;
	                 endcase
`else
								agen0_argC <= iq_argC[n][WID+3:4];
`endif                 
                 agen0_tgt    <= iq_tgt[n];
                 agen0_dataready <= 1'b1;
                 iq_state[n] <= IQS_OUT;
            end
        end

	if (`NUM_AGEN > 1) begin
    for (n = 0; n < QENTRIES; n = n + 1)
        if (iq_agen1_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (1'b1) begin
            		agen1_sn <= iq_sn[n];
                 agen1_sourceid	<= n[`QBITS];
                 agen1_unit <= iq_unit[n];
                 agen1_instr	<= iq_instr[n];
                 agen1_lea  <= iq_lea[n];
                 agen1_push <= iq_push[n];
`ifdef FU_BYPASS
								 if (iq_argA_v[n])
								 	 agen1_argA <= iq_argA[n][WID+3:4];
								 else
	                 case(iq_argA_s[n])
	                 alu0_id:	agen1_argA <= ralu0_bus;
	                 alu1_id:	agen1_argA <= ralu1_bus;
	                 fpu1_id:	agen1_argA <= rfpu1_bus[WID+3:4];
	                 fpu2_id:	agen1_argA <= rfpu2_bus[WID+3:4];
	                 default:	agen1_argA <= 80'hDEADDEADDEADDEADDEAD;
	                 endcase
`else
								agen1_argA <= iq_argA[n][WID+3:4];
`endif                 
//                 agen1_argB	<= iq_argB[n];	// ArgB not used by agen
`ifdef FU_BYPASS
								 if (iq_argC_v[n])
								 	agen1_argC <= iq_argC[n][WID+3:4];
								 else
	                 case(iq_argC_s[n])
	                 alu0_id:	agen1_argC <= ralu0_bus;
	                 alu1_id:	agen1_argC <= ralu1_bus;
	                 fpu1_id:	agen1_argC <= rfpu1_bus[WID+3:4];
	                 fpu2_id:	agen1_argC <= rfpu2_bus[WID+3:4];
	                 default:	agen1_argC <= 80'hDEADDEADDEADDEADDEAD;
	                 endcase
`else
								agen1_argC <= iq_argC[n][WID+3:4];
`endif                 
                 agen1_tgt    <= iq_tgt[n];
                 agen1_dataready <= 1'b1;
                 iq_state[n] <= IQS_OUT;
            end
        end
  end

	if (`NUM_FPU > 0) begin
    for (n = 0; n < QENTRIES; n = n + 1)
        if (iq_fpu1_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (fpu1_available & fpu1_done) begin
                 fpu1_sourceid	<= n[`QBITS];
                 fpu1_instr	<= iq_instr[n];
                 fpu1_ip		<= iq_ip[n];
`ifdef FU_BYPASS
								 if (iq_argA_v[n])
								 	 fpu1_argA <= iq_argA[n];
								 else
	                 case(iq_argA_s[n])
	                 alu0_id:	fpu1_argA <= {ralu0_bus,4'd0};
	                 alu1_id:	fpu1_argA <= {ralu1_bus,4'd0};
	                 fpu1_id:	fpu1_argA <= rfpu1_bus;
	                 fpu2_id:	fpu1_argA <= rfpu2_bus;
	                 default:	fpu1_argA <= 80'hDEADDEADDEADDEADDEAD;
	                 endcase
`else
								fpu1_argA <= iq_argA[n];               
`endif                 
`ifdef FU_BYPASS
								if (iq_imm[n])
									fpu1_argB <= {iq_argI[n],4'd0};
								else if (iq_argB_v[n])
									fpu1_argB <= iq_argB[n];
								else
									case(iq_argB_s[n])
									alu0_id:	fpu1_argB <= {ralu0_bus,4'd0};
									alu1_id:	fpu1_argB <= {ralu1_bus,4'd0};
									fpu1_id:	fpu1_argB <= rfpu1_bus;
									fpu2_id:	fpu1_argB <= rfpu2_bus;
									default:	fpu1_argB <= 80'hDEADDEADDEADDEADDEAD;
									endcase
`else
								if (iq_imm[n])
									fpu1_argB <= iq_argI[n];
								else
									fpu1_argB <= iq_argB[n];
`endif
`ifdef FU_BYPASS
								 if (iq_argC_v[n])
								 	fpu1_argC <= iq_argC[n];
								 else
	                 case(iq_argC_s[n])
	                 alu0_id:	fpu1_argC <= {ralu0_bus,4'd0};
	                 alu1_id:	fpu1_argC <= {ralu1_bus,4'd0};
	                 fpu1_id:	fpu1_argC <= rfpu1_bus;
	                 fpu2_id:	fpu1_argC <= rfpu2_bus;
	                 default:	fpu1_argC <= 80'hDEADDEADDEADDEADDEAD;
	                 endcase
`else
								fpu1_argC <= iq_argC[n];
`endif                 
                 fpu1_argI	<= iq_argI[n];
                 fpu1_dataready <= `VAL;
                 fpu1_ld <= TRUE;
                 iq_state[n] <= IQS_OUT;
            end
        end
	end

    for (n = 0; n < QENTRIES; n = n + 1)
        if (`NUM_FPU > 1 && iq_fpu2_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (fpu2_available & fpu2_done) begin
                 fpu2_sourceid	<= n[`QBITS];
                 fpu2_instr	<= iq_instr[n];
                 fpu2_ip		<= iq_ip[n];
`ifdef FU_BYPASS
								 if (iq_argA_v[n])
								 	 fpu2_argA <= iq_argA[n];
								 else
	                 case(iq_argA_s[n])
	                 alu0_id:	fpu2_argA <= {ralu0_bus,4'd0};
	                 alu1_id:	fpu2_argA <= {ralu1_bus,4'd0};
	                 fpu1_id:	fpu2_argA <= rfpu1_bus;
	                 fpu2_id:	fpu2_argA <= rfpu2_bus;
	                 default:	fpu2_argA <= 80'hDEADDEADDEADDEADDEAD;
	                 endcase
`else
								fpu2_argA <= iq_argA[n];               
`endif                 
`ifdef FU_BYPASS
								if (iq_imm[n])
									fpu2_argB <= iq_argI[n];
								else if (iq_argB_v[n])
									fpu2_argB <= iq_argB[n];
								else
									case(iq_argB_s[n])
									alu0_id:	fpu2_argB <= {ralu0_bus,4'd0};
									alu1_id:	fpu2_argB <= {ralu1_bus,4'd0};
									fpu1_id:	fpu2_argB <= rfpu1_bus;
									fpu2_id:	fpu2_argB <= rfpu2_bus;
									default:	fpu2_argB <= 80'hDEADDEADDEADDEADDEAD;
									endcase
`else
								if (iq_imm[n])
									fpu2_argB <= {iq_argI[n],4'd0};
								else
									fpu2_argB <= iq_argB[n];
`endif
`ifdef FU_BYPASS
								 if (iq_argC_v[n])
								 	fpu2_argC <= iq_argC[n];
								 else
	                 case(iq_argC_s[n])
	                 alu0_id:	fpu2_argC <= {ralu0_bus,4'd0};
	                 alu1_id:	fpu2_argC <= {ralu1_bus,4'd0};
	                 fpu1_id:	fpu2_argC <= rfpu1_bus;
	                 fpu2_id:	fpu2_argC <= rfpu2_bus;
	                 default:	fpu2_argC <= 80'hDEADDEADDEADDEADDEAD;
	                 endcase
`else
								fpu2_argC <= iq_argC[n];
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
				default:	begin fcu_nextip <= iq_ip[n]; end
				endcase
				fcu_pt     <= iq_pt[n];
				fcu_brdisp <= {{60{iq_instr[n][39]}},iq_instr[n][39:24],iq_instr[n][23:22],iq_instr[n][23:22]};
				//$display("Branch tgt: %h", {iq_instr[n][39:22],iq_instr[n][5:3],iq_instr[n][4:3]});
				fcu_branch <= iq_br[n];
				fcu_call    <= IsCall(`BUnit,iq_instr[n])|iq_jal[n];
				fcu_jal     <= iq_jal[n];
				fcu_ret    <= iq_ret[n];
				fcu_brk  <= iq_brk[n];
				fcu_rti  <= iq_rti[n];
				fcu_rex  <= iq_rex[n];
				fcu_chk  <= iq_chk[n];
				fcu_wait <= iq_wait[n];
`ifdef FU_BYPASS
				if (iq_argA_v[n])
					fcu_argA <= iq_argA[n][WID+3:4];
				else
					case(iq_argA_s[n])
					alu0_id:	fcu_argA <= ralu0_bus;
					alu1_id:	fcu_argA <= ralu1_bus;
					fpu1_id:	fcu_argA <= rfpu1_bus[WID+3:4];
					fpu2_id:	fcu_argA <= rfpu2_bus[WID+3:4];
					default:	fcu_argA <= 80'hDEADDEADDEADDEADDEAD;
					endcase
`else
				fcu_argA <= iq_argA[n][WID+3:4];               
`endif                 
`ifdef FU_BYPASS
				if (iq_imm[n])
					fcu_argB <= iq_argI[n];
				else if (iq_argB_v[n])
					fcu_argB <= iq_argB[n][WID+3:4];
				else
					case(iq_argB_s[n])
					alu0_id:	fcu_argB <= ralu0_bus;
					alu1_id:	fcu_argB <= ralu1_bus;
					fpu1_id:	fcu_argB <= rfpu1_bus[WID+3:4];
					fpu2_id:	fcu_argB <= rfpu2_bus[WID+3:4];
					default:	fcu_argB <= 80'hDEADDEADDEADDEADDEAD;
					endcase
`else
				if (iq_imm[n])
					fcu_argB <= iq_argI[n];
				else
					fcu_argB <= iq_argB[n][WID+3:4];
`endif
`ifdef FU_BYPASS
				if (iq_argC_v[n])
					fcu_argC <= iq_argC[n][WID+3:4];
				else
					case(iq_argC_s[n])
					alu0_id:	fcu_argC <= ralu0_bus;
					alu1_id:	fcu_argC <= ralu1_bus;
					fpu1_id:	fcu_argC <= rfpu1_bus[WID+3:4];
					fpu2_id:	fcu_argC <= rfpu2_bus[WID+3:4];
					default:	fcu_argC <= 80'hDEADDEADDEADDEADDEAD;
					endcase
`else
				fcu_argC <= iq_argC[n][WID+3:4];
`endif                 
				fcu_argI	<= iq_argI[n];
				fcu_ipc  <= ipc0;
`ifdef FU_BYPASS
				if (iq_argB_v[n])
					waitctr <= iq_argB[n][51:4];
				else
					case(iq_argB_s[n])
					alu0_id:	waitctr <= ralu0_bus[47:0];
					alu1_id:	waitctr <= ralu1_bus[47:0];
					fpu1_id:	waitctr <= rfpu1_bus[51:4];
					fpu2_id:	waitctr <= rfpu2_bus[51:4];
					default:	waitctr <= 48'hDEADDEADDEAD;
					endcase
`else
				waitctr <= iq_argB[n][51:4];
`endif
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
	dramA_bus <= aligned_data0;
end
if (dram1 == `DRAMREQ_READY && dram1_load && `NUM_MEM > 1) begin
	dramB_v <= !iq_stomp[dram1_id[`QBITS]];
	dramB_id <= dram1_id;
	dramB_bus <= aligned_data1;
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
		if (alu0_id==n)
			alu0_dataready <= FALSE;
		if (alu1_id==n)
			alu1_dataready <= FALSE;
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
		if (heads[0] != tails[0] && heads[1] != tails[0] && heads[2] != tails[0])
			head_inc(3);
		else if (heads[0] != tails[0] && heads[1] != tails[0])
	    head_inc(2);
		else if (heads[0] != tails[0])
	    head_inc(1);
	6'b0?_0?_10:
		if (heads[0] != tails[0] && heads[1] != tails[0])
			head_inc(2);
		else if (heads[0] != tails[0])
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
  	if (heads[1] != tails[0] && heads[2] != tails[0])
			head_inc(3);
  	else if (heads[1] != tails[0])
			head_inc(2);
  	else
			head_inc(1);
  6'b11_0?_10:
  	if (heads[1] != tails[0])
			head_inc(2);
  	else
			head_inc(1);
  6'b11_0?_11:
  	if (heads[1] != tails[0]) begin
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
  	if (`NUM_CMT > 1 && heads[2] != tails[0])
			head_inc(3);
  	else if (cmt_head1 && heads[2] != tails[0])
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


// A store will never be stomped on because they aren't issued until it's
// guarenteed there will be no change of flow.
// A load or other long running instruction might be stomped on by a change
// of program flow. Stomped on loads already in progress can be aborted early.
// In the case of an aborted load, random data is returned and any exceptions
// are nullified.
if (dram0_load|dram0_rmw)
case(dram0)
`DRAMSLOT_AVAIL:	;
`DRAMSLOT_BUSY:
	if (iq_v[dram0_id[`QBITS]] && !iq_stomp[dram0_id[`QBITS]]) begin
		if (dhit0 & !dram0_unc)
			dram0 <= dram0_rmw ? `DRAMSLOT_RMW : `DRAMREQ_READY;
	end
	else begin
		dram0 <= `DRAMREQ_READY;
		dram0_load <= `FALSE;
		//xdati <= {13{lfsro}};
	end
`DRAMSLOT_RMW:
	begin
		rmw_ad0 <= aligned_data0;
	end
`DRAMSLOT_RMW2:
	begin
		dram0 <= `DRAMSLOT_BUSY;
		case(dram0_instr[`FUNCT5])
		`AMOSWAP:		dram0_data <= dram0_argB;
		`AMOSWAPI:	dram0_data <= dram0_argI;
		`AMOADD:		dram0_data <= rmw_ad0 + dram0_argB;
		`AMOADDI:		dram0_data <= rmw_ad0 + dram0_argI;
		`AMOAND:		dram0_data <= rmw_ad0 & dram0_argB;
		`AMOANDI:		dram0_data <= rmw_ad0 & dram0_argI;
		`AMOOR:			dram0_data <= rmw_ad0 | dram0_argB;
		`AMOORI:		dram0_data <= rmw_ad0 | dram0_argI;
		`AMOXOR:		dram0_data <= rmw_ad0 ^ dram0_argB;
		`AMOXORI:		dram0_data <= rmw_ad0 ^ dram0_argI;
		`AMOSHL:		dram0_data <= rmw_ad0 << dram0_argB[6:0];
		`AMOSHLI:		dram0_data <= rmw_ad0 << dram0_argI[6:0];
		`AMOSHR:		dram0_data <= rmw_ad0 >> dram0_argB[6:0];
		`AMOSHRI:		dram0_data <= rmw_ad0 >> dram0_argI[6:0];
		`AMOMIN:		dram0_data <= $signed(rmw_ad0) < $signed(dram0_argB) ? rmw_ad0 : dram0_argB;
		`AMOMINI:		dram0_data <= $signed(rmw_ad0) < $signed(dram0_argI) ? rmw_ad0 : dram0_argI;
		`AMOMAX:		dram0_data <= $signed(rmw_ad0) < $signed(dram0_argB) ? rmw_ad0 : dram0_argB;
		`AMOMAXI:		dram0_data <= $signed(rmw_ad0) < $signed(dram0_argI) ? rmw_ad0 : dram0_argI;
		`AMOMINU:		dram0_data <= rmw_ad0 < dram0_argB ? rmw_ad0 : dram0_argB;
		`AMOMINUI:	dram0_data <= rmw_ad0 < dram0_argI ? rmw_ad0 : dram0_argI;
		`AMOMAXU:		dram0_data <= rmw_ad0 < dram0_argB ? rmw_ad0 : dram0_argB;
		`AMOMAXUI:	dram0_data <= rmw_ad0 < dram0_argI ? rmw_ad0 : dram0_argI;
		default:		dram0_data <= rmw_ad0;
		endcase
   	end
`DRAMSLOT_REQBUS:	
	if (iq_v[dram0_id[`QBITS]] && !iq_stomp[dram0_id[`QBITS]])
		;
	else begin
		dram0 <= `DRAMREQ_READY;
		dram0_load <= `FALSE;
		//xdati <= {13{lfsro}};
	end
`DRAMSLOT_HASBUS:
	if (iq_v[dram0_id[`QBITS]] && !iq_stomp[dram0_id[`QBITS]])
		;
	else begin
		dram0 <= `DRAMREQ_READY;
		dram0_load <= `FALSE;
		//xdati <= {13{lfsro}};
	end
`DRAMREQ_READY:		dram0 <= `DRAMSLOT_AVAIL;
endcase

if (dram1_load|dram1_rmw)
case(dram1)
`DRAMSLOT_AVAIL:	;
`DRAMSLOT_BUSY:
	if (iq_v[dram1_id[`QBITS]] && !iq_stomp[dram1_id[`QBITS]]) begin
		if (dhit1 && !dram1_unc)
			dram1 <= dram1_rmw ? `DRAMSLOT_RMW : `DRAMREQ_READY;
	end
	else begin
		dram1 <= `DRAMREQ_READY;
		dram1_load <= `FALSE;
		//xdati <= {13{lfsro}};
	end
`DRAMSLOT_RMW:
	begin
		rmw_ad1 <= aligned_data1;
		dram1 <= `DRAMSLOT_RMW2;
	end
`DRAMSLOT_RMW2:
	begin
		dram1 <= `DRAMSLOT_BUSY;
		case(dram1_instr[`FUNCT5])
		`AMOSWAP:		dram1_data <= dram1_argB;
		`AMOSWAPI:	dram1_data <= dram1_argI;
		`AMOADD:		dram1_data <= rmw_ad1 + dram1_argB;
		`AMOADDI:		dram1_data <= rmw_ad1 + dram1_argI;
		`AMOAND:		dram1_data <= rmw_ad1 & dram1_argB;
		`AMOANDI:		dram1_data <= rmw_ad1 & dram1_argI;
		`AMOOR:			dram1_data <= rmw_ad1 | dram1_argB;
		`AMOORI:		dram1_data <= rmw_ad1 | dram1_argI;
		`AMOXOR:		dram1_data <= rmw_ad1 ^ dram1_argB;
		`AMOXORI:		dram1_data <= rmw_ad1 ^ dram1_argI;
		`AMOSHL:		dram1_data <= rmw_ad1 << dram1_argB[6:0];
		`AMOSHLI:		dram1_data <= rmw_ad1 << dram1_argI[6:0];
		`AMOSHR:		dram1_data <= rmw_ad1 >> dram1_argB[6:0];
		`AMOSHRI:		dram1_data <= rmw_ad1 >> dram1_argI[6:0];
		`AMOMIN:		dram1_data <= $signed(rmw_ad1) < $signed(dram1_argB) ? rmw_ad1 : dram1_argB;
		`AMOMINI:		dram1_data <= $signed(rmw_ad1) < $signed(dram1_argI) ? rmw_ad1 : dram1_argI;
		`AMOMAX:		dram1_data <= $signed(rmw_ad1) < $signed(dram1_argB) ? rmw_ad1 : dram1_argB;
		`AMOMAXI:		dram1_data <= $signed(rmw_ad1) < $signed(dram1_argI) ? rmw_ad1 : dram1_argI;
		`AMOMINU:		dram1_data <= rmw_ad1 < dram1_argB ? rmw_ad1 : dram1_argB;
		`AMOMINUI:	dram1_data <= rmw_ad1 < dram1_argI ? rmw_ad1 : dram1_argI;
		`AMOMAXU:		dram1_data <= rmw_ad1 < dram1_argB ? rmw_ad1 : dram1_argB;
		`AMOMAXUI:	dram1_data <= rmw_ad1 < dram1_argI ? rmw_ad1 : dram1_argI;
		default:		dram1_data <= rmw_ad1;
		endcase
   	end
`DRAMSLOT_REQBUS:	
	if (iq_v[dram1_id[`QBITS]] && !iq_stomp[dram1_id[`QBITS]])
		;
	else begin
		dram1 <= `DRAMREQ_READY;
		dram1_load <= `FALSE;
		//xdati <= {13{lfsro}};
	end
`DRAMSLOT_HASBUS:
	if (iq_v[dram1_id[`QBITS]] && !iq_stomp[dram1_id[`QBITS]])
		;
	else begin
		dram1 <= `DRAMREQ_READY;
		dram1_load <= `FALSE;
		//xdati <= {13{lfsro}};
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
            if (!dack_i) begin
                 isRMW <= dram0_rmw;
                 isCAS <= IsCAS(`MUnit,dram0_instr);
//                 isAMO <= IsAMO(dram0_instr);
//                 isInc <= IsInc(dram0_instr);
                 casid <= dram0_id;
                 bwhich <= 2'b00;
                 dram0 <= `DRAMSLOT_HASBUS;
                 dcyc <= `HIGH;
                 dstb <= `HIGH;
                 dsel <= fnSelect(dram0_instr,dram0_addr);
                 //dcbuf <= dram0_data << {dram0_addr[4:0],3'b0};
                 //dcsel <= fnSelect(`MUnit,dram0_instr) << dram0_addr[4:0];
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
            if (!dack_i) begin
                 isRMW <= dram1_rmw;
//                 isCAS <= IsCAS(dram1_instr);
//                 isAMO <= IsAMO(dram1_instr);
                 //isInc <= IsInc(dram1_instr);
                 casid <= dram1_id;
                 bwhich <= 2'b01;
                 dram1 <= `DRAMSLOT_HASBUS;
                 dcyc <= `HIGH;
                 dstb <= `HIGH;
                 //dcbuf <= dram1_data << {dram1_addr[4:0],3'b0};
                 //dcsel <= fnSelect(`MUnit,dram1_instr) << dram1_addr[4:0];
                 dsel <= fnSelect(dram1_instr,dram1_addr);
                 dadr <= dram1_addr;
                 ddat <= dram1_data << {dram1_addr[3:0],3'b0};
                 dol  <= dram1_ol;
                 bstate <= B_RMWAck;
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
            if (!dack_i) begin
               bwhich <= 2'b00;
               dram0 <= `DRAMSLOT_HASBUS;
               dcyc <= `HIGH;
               dstb <= `HIGH;
               dsel <= fnSelect(dram0_instr,dram0_addr);
               dadr <= {dram0_addr[AMSB:3],3'b0};
               sr_o <=  IsLWR(`MUnit,dram0_instr);
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
            if (!dack_i) begin
               bwhich <= 2'b01;
               dram1 <= `DRAMSLOT_HASBUS;
               dcyc <= `HIGH;
               dstb <= `HIGH;
               dsel <= fnSelect(dram1_instr,dram1_addr);
               dadr <= {dram1_addr[AMSB:3],3'b0};
               sr_o <=  IsLWR(`MUnit,dram1_instr);
               ol_o  <= dram1_ol;
               dccnt <= 2'd0;
               bstate <= B_DLoadAck;
            end
        end
        // Check for L2 cache miss
        else if (~|wb_v && !L2_ihit && !dack_i)
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
//		cti_o <= icti;
//		bte_o <= ibte;
//		cyc <= icyc;
//		stb_o <= istb;
//		sel_o <= isel;
//		vadr <= iadr;
//		we <= 1'b0;
		if (L2_nxt)
			bstate <= BIDLE;
	end

B_RMWAck:
  if (dack_i|derr_i|tlb_miss|rdv_i) begin
    if (isCAS) begin
	     iq_res	[ casid[`QBITS] ] <= {(dat_i == cas),4'd0};
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
    	 	rmw_argB <= 64'd1 << iq_argA[casid[`QBITS]][67:62];
    	 	rmw_argC <= iq_instr[casid[`QBITS]][5:0]==`R2 ?
    	 				iq_argC[casid[`QBITS]][64] << iq_argA[casid[`QBITS]][67:62] :
    	 				iq_argB[casid[`QBITS]][64] << iq_argA[casid[`QBITS]][67:62];
    	 end
    	 else if (isInc) begin
    	 	rmw_argB <= iq_instr[casid[`QBITS]][5:0]==`R2 ? {{59{iq_instr[casid[`QBITS]][22]}},iq_instr[casid[`QBITS]][22:18]} :
    	 														 {{59{iq_instr[casid[`QBITS]][17]}},iq_instr[casid[`QBITS]][17:13]};
     	 end
    	 else begin // isAMO
  	     iq_res [ casid[`QBITS] ] <= {dat_i,4'd0};
  	     rmw_argB <= iq_instr[casid[`QBITS]][31] ? {{59{iq_instr[casid[`QBITS]][20:16]}},iq_instr[casid[`QBITS]][20:16]} : iq_argB[casid[`QBITS]][WID+3:4];
       end
         iq_exc [ casid[`QBITS] ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
         dstb <= `LOW;
         bstate <= B_RMWCvt;
				check_abort_load();
		end
  end

// Regular load
B_DLoadAck:
  if (dack_i|derr_i|tlb_miss|rdv_i) begin
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
	if (~dack_i) begin
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
// Turn the RMW operation into a store operation that will be picked up by
// the write buffer logic. The data caches will be updated if there is a
// write hit.
B_RMWCvt:
	if (~dack_i) begin
		//stb_o <= `HIGH;
		//we  <= `HIGH;
		if (bwhich==2'b01) begin
			dram1 <= `DRAMSLOT_BUSY;
			dram1_store <= TRUE;
			dram1_rmw <= FALSE;
			dram1_data <= rmw_res;
			ddat <= rmw_res >> (5'd16 - {dram1_addr[3:0],3'b0});
		end
		else begin
			dram0 <= `DRAMSLOT_BUSY;
			dram0_store <= TRUE;
			dram0_rmw <= FALSE;
			dram0_data <= rmw_res;
			ddat <= rmw_res >> (5'd16 - {dram0_addr[3:0],3'b0});
		end
		bstate <= BIDLE;
		check_abort_load();
	end
B21:
	if (~dack_i) begin
		dstb <= `HIGH;
		bstate <= B_RMWAck;
		check_abort_load();
	end
default:     bstate <= BIDLE;
endcase


`ifdef SIM
	$display("\n\n\n\n\n\n\n\n");
	$display("TIME %0d", $time);
	$display("%b %h %h#", ip_mask, ip, ibundlep);
	$display("%b %h %h#", ip_mask, ipd, ibundle);
    $display ("Regfile: %d", rgs);
	for (n=0; n < 64; n=n+4) begin
	    $display("%d: %h %d %o   %d: %h %d %o   %d: %h %d %o   %d: %h %d %o#",
	       n[5:0]+0, urf1.mem[{rgs,n[5:2],2'b00}], regIsValid[n+0], rf_source[n+0],
	       n[5:0]+1, urf1.mem[{rgs,n[5:2],2'b01}], regIsValid[n+1], rf_source[n+1],
	       n[5:0]+2, urf1.mem[{rgs,n[5:2],2'b10}], regIsValid[n+2], rf_source[n+2],
	       n[5:0]+3, urf1.mem[{rgs,n[5:2],2'b11}], regIsValid[n+3], rf_source[n+3]
	       );
	end
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
	$display("Insn%d: %h", 0, insnx[0]);
	for (i=0; i<QENTRIES; i=i+1) 
	    $display("%c%c %d: %c%c%c %d %d %c%c %c %c%h %d %o %h %h %h %d %o %h %d %o %h %d %o %h %o %h#",
		 (i[`QBITS]==heads[0])?"C":".",
		 (i[`QBITS]==tails[0])?"Q":".",
		  i[`QBITS],
		  iq_state[i]==IQS_INVALID ? "-" :
		  iq_state[i]==IQS_QUEUED ? "Q" :
		  iq_state[i]==IQS_OUT ? "O"  :
		  iq_state[i]==IQS_AGEN ? "A"  :
		  iq_state[i]==IQS_MEM ? "M"  :
		  iq_state[i]==IQS_DONE ? "D"  :
		  iq_state[i]==IQS_CMT ? "C"  : "?",
//		 iq_v[i] ? "v" : "-",
		 iq_done[i]?"d":"-",
		 iq_out[i]?"o":"-",
		 iq_bt[i],
		 iq_memissue[i],
		 iq_agen[i] ? "a": "-",
		 iq_alu0_issue[i]?"0":iq_alu1_issue[i]?"1":"-",
		 iq_stomp[i]?"s":"-",
		iq_fc[i] ? "F" : iq_mem[i] ? "M" : (iq_alu[i]==1'b1) ? "a" : iq_fpu[i] ? "f" : "O", 
		iq_instr[i], iq_tgt[i][5:0],
		iq_exc[i], iq_res[i], iq_argI[i], iq_argA[i], iq_argA_v[i],
		iq_argA_s[i],
		iq_argB[i], iq_argB_v[i], iq_argB_s[i],
		iq_argC[i], iq_argC_v[i], iq_argC_s[i],
		iq_ip[i],
		iq_sn[i],
		iq_br_tag[i]
		);
    $display("DRAM");
	$display("%d %h %h %c%h %o #",
	    dram0, dram0_addr, dram0_data, (IsFlowCtrl(dram0_instr) ? 98 : (IsMem(dram0_instr)) ? 109 : 97), 
	    dram0_instr, dram0_id);
	  if (`NUM_MEM > 1)
	$display("%d %h %h %c%h %o #",
	    dram1, dram1_addr, dram1_data, (IsFlowCtrl(dram1_instr) ? 98 : (IsMem(dram1_instr)) ? 109 : 97), 
	    dram1_instr, dram1_id);
	$display("%d %h %o #", dramA_v, dramA_bus, dramA_id);
	if (`NUM_MEM > 1)
	$display("%d %h %o #", dramB_v, dramB_bus, dramB_id);
    $display("ALU");
	$display("%d %h %h %h %c%h %o %h #",
		alu0_dataready, alu0_argI, alu0_argA, alu0_argB, 
		 (IsFlowCtrl(alu0_instr) ? 98 : IsMem(alu0_instr) ? 109 : 97),
		alu0_instr, alu0_sourceid, alu0_ip);
	$display("%d %h %o 0 #", alu0_v, alu0_bus, alu0_id);
	if (`NUM_ALU > 1) begin
		$display("%d %h %h %h %c%h %o %h #",
			alu1_dataready, alu1_argI, alu1_argA, alu1_argB, 
		 	(IsFlowCtrl(alu1_instr) ? 98 : IsMem(alu1_instr) ? 109 : 97),
			alu1_instr, alu1_sourceid, alu1_ip);
		$display("%d %h %o 0 #", alu1_v, alu1_bus, alu1_id);
	end
	$display("FCU");
	$display("%d %h %h %h %h %c%c #", fcu_v, fcu_bus, fcu_argI, fcu_argA, fcu_argB, fcu_takb?"T":"-", fcu_pt?"T":"-");
	$display("%c %h %h %h %h #", fcu_branchmiss?"m":" ", fcu_sourceid, fcu_missip, fcu_nextip, fcu_brdisp); 
    $display("Commit");
	$display("0: %c %h %o %d #", commit0_v?"v":" ", commit0_bus, commit0_id, commit0_tgt[5:0]);
	$display("1: %c %h %o %d #", commit1_v?"v":" ", commit1_bus, commit1_id, commit1_tgt[5:0]);
    $display("instructions committed: %d valid committed: %d ticks: %d ", CC, I, tick);
  $display("Write Buffer:");
  for (n = `WB_DEPTH-1; n >= 0; n = n - 1)
  	$display("%c adr: %h dat: %h", wb_v[n]?" ":"*", wb_addr[n], uwb1.wb_data[n]);
    //$display("Write merges: %d", wb_merges);
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
		if (n < amt) begin
			if (!((heads[n]==tails[0] && queuedCnt==3'd1)
			|| (heads[n]==tails[1] && queuedCnt==3'd2)
			|| (heads[n]==tails[2] && queuedCnt==3'd3))) begin
				iq_state[heads[n]] <= IQS_INVALID;
				iq_mem[heads[n]] <= `FALSE;
				iq_alu[heads[n]] <= `FALSE;
				iq_fc[heads[n]] <= `FALSE;
				iq_agen[heads[n]] <= `FALSE;
				iq_fpu[heads[n]] <= `FALSE;
				if (alu0_id==n)
					alu0_dataready <= `FALSE;
				if (alu1_id==n)
					alu1_dataready <= `FALSE;
			end
		end

	CC <= CC + amt;
end
endtask

task setargs;
input [`QBITS] nn;
input [`QBITS] id;
input v;
input [79:0] bus;
begin
  if (iq_argA_v[nn] == `INV && iq_argA_s[nn][`QBITS] == id[`QBITS] && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argA[nn] <= bus;
		iq_argA_v[nn] <= `VAL;
  end
  if (iq_argB_v[nn] == `INV && iq_argB_s[nn][`QBITS] == id[`QBITS] && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argB[nn] <= bus;
		iq_argB_v[nn] <= `VAL;
  end
  if (iq_argC_v[nn] == `INV && iq_argC_s[nn][`QBITS] == id[`QBITS] && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argC[nn] <= bus;
		iq_argC_v[nn] <= `VAL;
  end
end
endtask

// Patterns do not have all one bits! The tail queue slot depends on which set
// bit of the pattern is present. For instance patterns 001,010, and 100 all
// refer to the same tail - tail[0]. Need to count the set bits in the pattern
// to determine the tail number.
function [2:0] tails_rc;
input [QSLOTS-1:0] pat;
input [QSLOTS-1:0] rc;
reg [2:0] cnt;
begin
	cnt = 0;
	tails_rc = QSLOTS-1;
	for (n = 0; n < QSLOTS; n = n + 1) begin
		if (rc==n)
			tails_rc = cnt;
		if (pat[n])
			cnt = cnt + 1;
	end
end
endfunction

task arg_vs;
input [QSLOTS-1:0] pat;
begin
	for (row = 0; row < QSLOTS; row = row + 1) begin
		if (pat[row]) begin
			iq_argA_v [tails[tails_rc(pat,row)]] <= regIsValid[Rs1[row]] | Source1Valid(slotu[row],insnx[row]);
			iq_argA_s [tails[tails_rc(pat,row)]] <= rf_source[Rs1[row]];
			iq_argB_v [tails[tails_rc(pat,row)]] <= regIsValid[Rs2[row]] | Source2Valid(slotu[row],insnx[row]);
			iq_argB_s [tails[tails_rc(pat,row)]] <= rf_source[Rs2[row]];
			iq_argC_v [tails[tails_rc(pat,row)]] <= regIsValid[Rs3[row]] | Source3Valid(slotu[row],insnx[row]);
			iq_argC_s [tails[tails_rc(pat,row)]] <= rf_source[Rs3[row]];
			for (col = 0; col < QSLOTS; col = col + 1) begin
				if (col < row) begin
					if (pat[col]) begin
						if (Rs1[row]==Rd[col] && Rs1[row][5:0]!=6'd0 && slot_rfw[col]) begin
							iq_argA_v [tails[tails_rc(pat,row)]] <= Source1Valid(slotu[row],insnx[row]);
							iq_argA_s [tails[tails_rc(pat,row)]] <= tails[tails_rc(pat,col)];
						end
						if (Rs2[row]==Rd[col] && Rs2[row][5:0]!=6'd0 && slot_rfw[col]) begin
							iq_argB_v [tails[tails_rc(pat,row)]] <= Source2Valid(slotu[row],insnx[row]);
							iq_argB_s [tails[tails_rc(pat,row)]] <= tails[tails_rc(pat,col)];
						end
						if (Rs3[row]==Rd[col] && Rs3[row][5:0]!=6'd0 && slot_rfw[col]) begin
							iq_argC_v [tails[tails_rc(pat,row)]] <= Source3Valid(slotu[row],insnx[row]);
							iq_argC_s [tails[tails_rc(pat,row)]] <= tails[tails_rc(pat,col)];
						end
					end
				end
			end
		end
	end
end
endtask

/*
task arg_vs_011;
begin
	// if there is not an overlapping write to the register file.
	if ((Rs1[2] != Rd[1]) || !slot_rfw[1]) begin
		iq_argA_v [tails[1]] <= regIsValid[Rs1[2]] | Source1Valid(slotu[2],insnx[2]);
		iq_argA_s [tails[1]] <= rf_source [Rs1[2]];
	end
	else begin
		iq_argA_v [tails[1]] <= Source1Valid(slotu[2],insnx[2]);
		iq_argA_s [tails[1]] <= tails[0];
	end

	if ((Rs2[2] != Rd[1]) || !slot_rfw[1]) begin
		iq_argB_v [tails[1]] <= regIsValid[Rs2[2]] | Source2Valid(slotu[2],insnx[2]);
		iq_argB_s [tails[1]] <= rf_source [Rs2[2]];
	end
	else begin
		iq_argB_v [tails[1]] <= Source2Valid(slotu[2],insnx[2]);
		iq_argB_s [tails[1]] <= tails[0];
	end

	if ((Rs3[2] != Rd[1]) || !slot_rfw[1]) begin
		iq_argC_v [tails[1]] <= regIsValid[Rs3[2]] | Source3Valid(slotu[2],insnx[2]);
		iq_argC_s [tails[1]] <= rf_source [Rs3[2]];
	end
	else begin
		iq_argC_v [tails[1]] <= Source3Valid(slotu[2],insnx[2]);
		iq_argC_s [tails[1]] <= tails[0];
	end
end
endtask

task arg_vs_101;
begin
	// if there is not an overlapping write to the register file.
	if ((Rs1[2] != Rd[0]) || !slot_rfw[0]) begin
		iq_argA_v [tails[1]] <= regIsValid[Rs1[2]] | Source1Valid(slotu[2],insnx[2]);
		iq_argA_s [tails[1]] <= rf_source [Rs1[2]];
	end
	else begin	// Rs1[1] must be equal to Rt0 then
		iq_argA_v [tails[1]] <= Source1Valid(slotu[2],insnx[2]);
		iq_argA_s [tails[1]] <= tails[0];
	end

	if ((Rs2[2] != Rd[0]) || !slot_rfw[0]) begin
		iq_argB_v [tails[1]] <= regIsValid[Rs2[2]] | Source2Valid(slotu[2],insnx[2]);
		iq_argB_s [tails[1]] <= rf_source [Rs2[2]];
	end
	else begin	// Rs1[1] must be equal to Rt0 then
		iq_argB_v [tails[1]] <= Source2Valid(slotu[2],insnx[2]);
		iq_argB_s [tails[1]] <= tails[0];
	end

	if ((Rs3[2] != Rd[0]) || !slot_rfw[0]) begin
		iq_argC_v [tails[1]] <= regIsValid[Rs3[2]] | Source3Valid(slotu[2],insnx[2]);
		iq_argC_s [tails[1]] <= rf_source [Rs3[2]];
	end
	else begin	// Rs1[1] must be equal to Rt0 then
		iq_argC_v [tails[1]] <= Source3Valid(slotu[2],insnx[2]);
		iq_argC_s [tails[1]] <= tails[0];
	end
end
endtask

task arg_vs_110;
begin
	// if there is not an overlapping write to the register file.
	if ((Rs1[1] != Rd[0]) || !slot_rfw[0]) begin
		iq_argA_v [tails[1]] <= regIsValid[Rs1[1]] | Source1Valid(slotu[1],insnx[1]);
		iq_argA_s [tails[1]] <= rf_source [Rs1[1]];
	end
	else begin	// Rs1[1] must be equal to Rt0 then
		iq_argA_v [tails[1]] <= Source1Valid(slotu[1],insnx[1]);
		iq_argA_s [tails[1]] <= tails[0];
	end

	if ((Rs2[1] != Rd[0]) || !slot_rfw[0]) begin
		iq_argB_v [tails[1]] <= regIsValid[Rs2[1]] | Source2Valid(slotu[1],insnx[1]);
		iq_argB_s [tails[1]] <= rf_source [Rs2[1]];
	end
	else begin	// Rs1[1] must be equal to Rt0 then
		iq_argB_v [tails[1]] <= Source2Valid(slotu[1],insnx[1]);
		iq_argB_s [tails[1]] <= tails[0];
	end

	if ((Rs3[1] != Rd[0]) || !slot_rfw[0]) begin
		iq_argC_v [tails[1]] <= regIsValid[Rs3[1]] | Source3Valid(slotu[1],insnx[1]);
		iq_argC_s [tails[1]] <= rf_source [Rs3[1]];
	end
	else begin	// Rs1[1] must be equal to Rt0 then
		iq_argC_v [tails[1]] <= Source3Valid(slotu[1],insnx[1]);
		iq_argC_s [tails[1]] <= tails[0];
	end
end
endtask

task arg_vs_111;
begin
	// if there is not an overlapping write to the register file.
	if ((Rs1[1] != Rd[0]) || !slot_rfw[0]) begin
		iq_argA_v [tails[1]] <= regIsValid[Rs1[1]] | Source1Valid(slotu[1],insnx[1]);
		iq_argA_s [tails[1]] <= rf_source [Rs1[1]];
	end
	else begin	// Rs1[1] must be equal to Rt0 then
		iq_argA_v [tails[1]] <= Source1Valid(slotu[1],insnx[1]);
		iq_argA_s [tails[1]] <= tails[0];
	end
	// if there is not an overlapping write to the register file.
	if (((Rs1[2] != Rd[0]) || !slot_rfw[0]) && ((Rs1[2] != Rd[1]) || !slot_rfw[1])) begin
		iq_argA_v [tails[2]] <= regIsValid[Rs1[2]] | Source1Valid(slotu[2],insnx[2]);
		iq_argA_s [tails[2]] <= rf_source [Rs1[2]];
	end
	else if ((Rs1[2] != Rd[0]) || !slot_rfw[0]) begin	// Rs1[2] must be equal to Rt1 then
		iq_argA_v [tails[2]] <= Source1Valid(slotu[2],insnx[2]);
		iq_argA_s [tails[2]] <= tails[1];
	end
	else if ((Rs1[2] != Rd[1]) || !slot_rfw[1]) begin	// Rs1[2] must be equal to Rt0 then
		iq_argA_v [tails[2]] <= Source1Valid(slotu[2],insnx[2]);
		iq_argA_s [tails[2]] <= tails[0];
	end
	else begin	// Rs1[2]==Rd[1] && Rs1[2]==Rd[0]
		iq_argA_v [tails[2]] <= Source1Valid(slotu[2],insnx[2]);
		iq_argA_s [tails[2]] <= tails[1];
	end

	// if there is not an overlapping write to the register file.
	if ((Rs2[1] != Rd[0]) || !slot_rfw[0]) begin
		iq_argB_v [tails[1]] <= regIsValid[Rs2[1]] | Source2Valid(slotu[1],insnx[1]);
		iq_argB_s [tails[1]] <= rf_source [Rs2[1]];
	end
	else begin	// Rs1[1] must be equal to Rt0 then
		iq_argB_v [tails[1]] <= Source2Valid(slotu[1],insnx[1]);
		iq_argB_s [tails[1]] <= tails[0];
	end
	// if there is not an overlapping write to the register file.
	if (((Rs2[2] != Rd[0]) || !slot_rfw[0]) && ((Rs2[2] != Rd[1]) || !slot_rfw[1])) begin
		iq_argB_v [tails[2]] <= regIsValid[Rs2[2]] | Source2Valid(slotu[2],insnx[2]);
		iq_argB_s [tails[2]] <= rf_source [Rs2[2]];
	end
	else if ((Rs2[2] != Rd[0]) || !slot_rfw[0]) begin	// Rs1[2] must be equal to Rt1 then
		iq_argB_v [tails[2]] <= Source2Valid(slotu[2],insnx[2]);
		iq_argB_s [tails[2]] <= tails[1];
	end
	else if ((Rs2[2] != Rd[1]) || !slot_rfw[1]) begin	// Rs1[2] must be equal to Rt0 then
		iq_argB_v [tails[2]] <= Source2Valid(slotu[2],insnx[2]);
		iq_argB_s [tails[2]] <= tails[0];
	end
	else begin
		iq_argB_v [tails[2]] <= Source2Valid(slotu[2],insnx[2]);
		iq_argB_s [tails[2]] <= tails[1];
	end

	// if there is not an overlapping write to the register file.
	if ((Rs3[1] != Rd[0]) || !slot_rfw[0]) begin
		iq_argC_v [tails[1]] <= regIsValid[Rs3[1]] | Source3Valid(slotu[1],insnx[1]);
		iq_argC_s [tails[1]] <= rf_source [Rs3[1]];
	end
	else begin	// Rs1[1] must be equal to Rt0 then
		iq_argC_v [tails[1]] <= Source3Valid(slotu[1],insnx[1]);
		iq_argC_s [tails[1]] <= tails[0];
	end
	// if there is not an overlapping write to the register file.
	if (((Rs3[2] != Rd[0]) || !slot_rfw[0]) && ((Rs3[2] != Rd[1]) || !slot_rfw[1])) begin
		iq_argC_v [tails[2]] <= regIsValid[Rs3[2]] | Source3Valid(slotu[2],insnx[2]);
		iq_argC_s [tails[2]] <= rf_source [Rs3[2]];
	end
	else if ((Rs3[2] != Rd[0]) || !slot_rfw[0]) begin	// Rs1[2] must be equal to Rt1 then
		iq_argC_v [tails[2]] <= Source3Valid(slotu[2],insnx[2]);
		iq_argC_s [tails[2]] <= tails[1];
	end
	else if ((Rs3[2] != Rd[1]) || !slot_rfw[1]) begin	// Rs1[2] must be equal to Rt0 then
		iq_argC_v [tails[2]] <= Source3Valid(slotu[2],insnx[2]);
		iq_argC_s [tails[2]] <= tails[0];
	end
	else begin
		iq_argC_v [tails[2]] <= Source3Valid(slotu[2],insnx[2]);
		iq_argC_s [tails[2]] <= tails[1];
	end
end
endtask
*/

task set_insn;
input [`QBITS] nn;
input [`IBTOP:0] bus;
begin
	if (template[0]==7'h7D || template[0]==7'h7E)
		iq_argI[nn] <= ibundle[119:40];
	else
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
	iq_wait [nn]  <= bus[`IB_WAIT];
	iq_fpu  [nn]  <= bus[`IB_FPU];
	iq_fc   [nn]  <= bus[`IB_FC];
	iq_canex[nn]  <= bus[`IB_CANEX];
	iq_lea  [nn]  <= bus[`IB_LEA];
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
	iq_brcc [nn]  <= bus[`IB_BRCC];
	iq_sync [nn]  <= bus[`IB_SYNC];
	iq_fsync[nn]  <= bus[`IB_FSYNC];
	iq_rs1   [nn]  <= bus[`IB_RS1];
	iq_rs2   [nn]  <= bus[`IB_RS2];
	iq_rs3   [nn]  <= bus[`IB_RS3];
	iq_rfw  [nn]  <= bus[`IB_RFW];
end
endtask
	
task queue_slot;
input [2:0] slot;
input [`QBITS] ndx;
input [2:0] seqnum;
input [`IBTOP:0] id_bus;
input [`QBITS] btag;
begin
	iq_sn[ndx] <= seqnum;
	iq_state[ndx] <= IQS_QUEUED;
	iq_br_tag[ndx] <= btag;
	case(slot)
	3'd0:	iq_ip[ndx] <= {ipd[AMSB:4],4'h0};
	3'd1:	iq_ip[ndx] <= {ipd[AMSB:4],4'h5};
	3'd2:	iq_ip[ndx] <= {ipd[AMSB:4],4'hA};
	3'd3:	iq_ip[ndx] <= {ipd[AMSB:4]+2'd1,4'h0};
	3'd4:	iq_ip[ndx] <= {ipd[AMSB:4]+2'd1,4'h5};
	3'd5:	iq_ip[ndx] <= {ipd[AMSB:4]+2'd1,4'hA};
	default:	iq_ip[ndx] <= {ipd[AMSB:4],4'h0};
	endcase
	iq_unit[ndx] <= slotu[slot];
	iq_instr[ndx] <= insnx[slot];
	iq_argA[ndx] <= rfoa[slot];
	iq_argB[ndx] <= rfob[slot];
	iq_argC[ndx] <= rfoc[slot];
	iq_argA_v[ndx] <= regIsValid[Rs1[slot]] || Source1Valid(slotu[slot],insnx[slot]);
	iq_argB_v[ndx] <= regIsValid[Rs2[slot]] || Source2Valid(slotu[slot],insnx[slot]);
	iq_argC_v[ndx] <= regIsValid[Rs3[slot]] || Source3Valid(slotu[slot],insnx[slot]);
	iq_argA_s[ndx] <= rf_source[Rs1[slot]];
	iq_argB_s[ndx] <= rf_source[Rs2[slot]];
	iq_argC_s[ndx] <= rf_source[Rs3[slot]];
	iq_pt[ndx] <= predict_taken[slot];
	iq_tgt[ndx] <= Rd[slot];
	iq_res[ndx] <= 84'd0;
	iq_exc[ndx] <= `FLT_NONE;
	set_insn(ndx,id_bus);
end
endtask

task exc;
input [`QBITS] head;
input thread;
input [7:0] causecd;
begin
  excmiss <= TRUE;
 	excmissip <= {tvec[3'd0][AMSB:8],1'b0,ol,5'h00};
  badaddr[{thread,2'd0}] <= iq_ma[head];
  bad_instr[{thread,2'd0}] <= iq_instr[head];
  im_stack <= {im_stack[27:0],4'hF};
  ol_stack <= {ol_stack[13:0],2'b00};
  dl_stack <= {dl_stack[13:0],2'b00};
  ipc0 <= iq_ip[head];
  ipc1 <= ipc0;
  ipc2 <= ipc1;
  ipc3 <= ipc2;
  ipc4 <= ipc3;
  ipc5 <= ipc4;
  ipc6 <= ipc5;
  ipc7 <= ipc6;
  ipc8 <= ipc7;
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
          		excmissip <= {tvec[3'd0][AMSB:8],1'b0,ol,5'h00};
              ipc0 <= iq_ip[head] + {iq_instr[head][25:21],1'b0};
              ipc1 <= ipc0;
              ipc2 <= ipc1;
              ipc3 <= ipc2;
              ipc4 <= ipc3;
              ipc5 <= ipc4;
              ipc6 <= ipc5;
              ipc7 <= ipc6;
              ipc8 <= ipc7;
              pl_stack <= {pl_stack[55:0],cpl};
              rs_stack <= {rs_stack[59:0],`BRK_RGS};
              brs_stack <= {brs_stack[59:0],`BRK_RGS};
              cause[3'd0] <= iq_res[head][11:4];
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
           `BMISC:
            case(iq_instr[head][`FUNCT5])
            `SEI:   mstatus[3:0] <= iq_res[head][7:4];   // S1
            `RTI:   begin
		            excmiss <= TRUE;
	    					excmissip <= iq_ma[head];
//            		excmissip <= ipc0;
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
                ipc0 <= ipc1;
                ipc1 <= ipc2;
                ipc2 <= ipc3;
                ipc3 <= ipc4;
                ipc4 <= ipc5;
                ipc5 <= ipc6;
                ipc6 <= ipc7;
                ipc7 <= ipc8;
                ipc8 <= {tvec[0][AMSB:8], 1'b0, ol, 5'h0};
                sema[0] <= 1'b0;
                sema[iq_res[head][9:4]] <= 1'b0;
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
                mstatus[13:6] <= iq_instr[head][25:18] | iq_argA[head][11:4];
            end
            default: ;
            endcase
           default:	;
          endcase
        `MUnit:
        	case(iq_instr[head][`OPCODE4])
        	`MSX:
            case(iq_instr[head][`FUNCT5])
            `CACHE:
            	begin
                case(iq_instr[head][18:16])
		            3'h3:	begin invicl <= TRUE; invlineAddr <= {iq_res[head][WID+3:4]}; end
                3'h4:  	invic <= TRUE;
                default:	;
              	endcase
                case(iq_instr[head][21:19])
                3'h1:  cr0[30] <= TRUE;
                3'h2:  cr0[30] <= FALSE;
                3'h4:		invdc <= TRUE;
                default:    ;
                endcase
              end
            default: ;
            endcase
        `CACHE:
        		begin
	            case(iq_instr[head][18:16])
	            3'h1:	begin invicl <= TRUE; invlineAddr <= {iq_res[head][WID+3:4]}; end
	            3'h2:  	invic <= TRUE;
	            default:	;
	          	endcase
	            case(iq_instr[head][21:19])
	            3'h1:  cr0[30] <= TRUE;
	            3'h2:  cr0[30] <= FALSE;
	            3'd3:		invdcl <= TRUE;
	            3'h4:		invdc <= TRUE;
	            default:    ;
	            endcase
		          end
          default:	;
          endcase
        `IUnit:
        	case({iq_instr[head][32:31],iq_instr[head][`OPCODE4]})
        `CSRRW:
        		begin
        		write_csr(iq_instr[head][39:38],{iq_instr[head][37:36],iq_instr[head][28:16]},iq_argA[head][WID+3:4],thread);
        		end
        		default:	;
        		endcase
        `FUnit:
            case(iq_instr[head][`OPCODE4])
            `FLT1:
							case(iq_instr[head][`FUNCT5])
							`FRM: begin  
										fp_rm <= iq_res[head][6:4];
										end
            `FCX:
                begin
                    fp_sx <= fp_sx & ~iq_res[head][9];
                    fp_inex <= fp_inex & ~iq_res[head][8];
                    fp_dbzx <= fp_dbzx & ~(iq_res[head][7]|iq_res[head][4]);
                    fp_underx <= fp_underx & ~iq_res[head][6];
                    fp_overx <= fp_overx & ~iq_res[head][5];
                    fp_giopx <= fp_giopx & ~iq_res[head][4];
                    fp_infdivx <= fp_infdivx & ~iq_res[head][4];
                    fp_zerozerox <= fp_zerozerox & ~iq_res[head][4];
                    fp_subinfx   <= fp_subinfx   & ~iq_res[head][4];
                    fp_infzerox  <= fp_infzerox  & ~iq_res[head][4];
                    fp_NaNCmpx   <= fp_NaNCmpx   & ~iq_res[head][4];
                    fp_swtx <= 1'b0;
                end
            `FDX:
                begin
                    fp_inexe <= fp_inexe     & ~iq_res[head][8];
                    fp_dbzxe <= fp_dbzxe     & ~iq_res[head][7];
                    fp_underxe <= fp_underxe & ~iq_res[head][6];
                    fp_overxe <= fp_overxe   & ~iq_res[head][5];
                    fp_invopxe <= fp_invopxe & ~iq_res[head][4];
                end
            `FEX:
                begin
                    fp_inexe <= fp_inexe     | iq_res[head][8];
                    fp_dbzxe <= fp_dbzxe     | iq_res[head][7];
                    fp_underxe <= fp_underxe | iq_res[head][6];
                    fp_overxe <= fp_overxe   | iq_res[head][5];
                    fp_invopxe <= fp_invopxe | iq_res[head][4];
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
input [1:0] csrop;
input [13:0] csrno;
input [79:0] dat;
input thread;
begin
    if (csrno[13:12] >= ol)
    case(csrop)
    2'd1:   // CSRRW
        casez(csrno[11:0])
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
        `CSR_IPC0:      ipc0 <= dat;
        `CSR_IPC1:      ipc1 <= dat;
        `CSR_IPC2:      ipc2 <= dat;
        `CSR_IPC3:      ipc3 <= dat;
        `CSR_IPC4:      ipc4 <= dat;
        `CSR_IPC5:      ipc5 <= dat;
        `CSR_IPC6:      ipc6 <= dat;
        `CSR_IPC7:      ipc7 <= dat;
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
        `CSR_RS_STACK:	rs_stack[63:0] <= rs_stack[63:0] | dat;
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
        `CSR_RS_STACK:	rs_stack[63:0] <= rs_stack[63:0] & ~dat;
        default:    ;
        endcase
    default:    ;
    endcase
end
endtask

task tDram0Issue;
input [`QBITS] n;
begin
	if (iq_state[n]==IQS_AGEN) begin
//	dramA_v <= `INV;
		dram0 		<= `DRAMSLOT_BUSY;
		dram0_id 	<= n[`QBITS];
		dram0_instr <= iq_instr[n];
		dram0_rmw  <= iq_rmw[n];
		dram0_preload <= iq_preload[n];
		dram0_tgt 	<= iq_tgt[n];
		// These two args needed only to support AMO operations
		dram0_argI	<= {{66{iq_instr[n][34]}},iq_instr[n][34:33],iq_instr[n][27:16]};
		dram0_argB  <= iq_argB_v[n] ? iq_argB[n][WID+3:4]
			: iq_argB_s[n]==alu0_id ? ralu0_bus
			: iq_argB_s[n]==alu1_id ? ralu1_bus
			: iq_argB_s[n]==fpu1_id ? rfpu1_bus[WID+3:4]
			: 80'hDEADDEADDEADDEADDEAD;
		if (iq_imm[n] & iq_push[n])
			dram0_data <= iq_argI[n];
		else
			dram0_data <= iq_argB[n][WID+3:4];
		dram0_addr	<= iq_ma[n];
		dram0_unc   <= iq_ma[n][31:20]==12'hFFD || !dce;
		dram0_memsize <= iq_memsz[n];
		dram0_load <= iq_load[n];
		dram0_store <= iq_store[n];
		dram0_ol   <= (iq_rs1[n][RBIT:0]==6'd63 || iq_rs1[n][RBIT:0]==6'd62) ? ol : dl;
	// Once the memory op is issued reset the a1_v flag.
	// This will cause the a1 bus to look for new data from memory (a1_s is pointed to a memory bus)
	// This is used for the load and compare instructions.
	// must reset the a1 source too.
	//iq_a1_v[n] <= `INV;
		iq_state[n] <= IQS_MEM;
		iq_memissue[n] <= `INV;
	end
end
endtask

task tDram1Issue;
input [`QBITS] n;
begin
	if (iq_state[n]==IQS_AGEN) begin
//	dramB_v <= `INV;
	dram1 		<= `DRAMSLOT_BUSY;
	dram1_id 	<= n[`QBITS];
	dram1_instr <= iq_instr[n];
	dram1_rmw  <= iq_rmw[n];
	dram1_preload <= iq_preload[n];
	dram1_tgt 	<= iq_tgt[n];
	// These two args needed only to support AMO operations
	dram1_argI	<= {{66{iq_instr[n][34]}},iq_instr[n][34:33],iq_instr[n][27:16]};
	dram1_argB  <= iq_argB_v[n] ? iq_argB[n][WID+3:4]
	  : iq_argB_s[n]==alu0_id ? ralu0_bus
	  : iq_argB_s[n]==alu1_id ? ralu1_bus
	  : iq_argB_s[n]==fpu1_id ? rfpu1_bus[WID+3:4]
	  : 80'hDEADDEADDEADDEADDEAD;
	if (iq_imm[n] & iq_push[n])
		dram1_data <= iq_argI[n];
	else
		dram1_data <= iq_argB[n][WID+3:4];
	dram1_addr	<= iq_ma[n];
	//	             if (ol[iq_thrd[n]]==`OL_USER)
	//	             	dram1_seg   <= (iq_rs1[n]==5'd30 || iq_rs1[n]==5'd31) ? {ss[iq_thrd[n]],13'd0} : {ds[iq_thrd[n]],13'd0};
	//	             else
	dram1_unc   <= iq_ma[n][31:20]==12'hFFD || !dce;
	dram1_memsize <= iq_memsz[n];
	dram1_load <= iq_load[n];
	dram1_store <= iq_store[n];
	dram1_ol   <= (iq_rs1[n][RBIT:0]==6'd63 || iq_rs1[n][RBIT:0]==6'd62) ? ol : dl;
	//iq_a1_v[n] <= `INV;
	iq_state[n] <= IQS_MEM;
	iq_memissue[n] <= `INV;
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

module decoder7 (num, out);
input [6:0] num;
output [127:1] out;

wire [127:0] out1;

assign out1 = 128'd1 << num;
assign out = out1[127:1];

endmodule

