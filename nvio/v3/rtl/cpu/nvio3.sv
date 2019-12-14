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
// 382174 611478
// 552138	883421
// 550578	880925
// 564334 902934
`include "nvio3-config.sv"
`include "nvio3-defines.sv"

module nvio3(hartid_i, rst_i, clk_i, clk2x_i, clk4x_i, tm_clk_i, irq_i, cause_i, 
		bte_o, cti_o, bok_i, cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_o, dat_i,
    ol_o, pcr_o, pcr2_o, pkeys_o, icl_o, sr_o, cr_o, rbi_i, signal_i, exc_o);
parameter WID = 128;
parameter VWID = 256;
input [127:0] hartid_i;
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
output [127:0] pkeys_o;
output icl_o;
output reg cr_o;
output reg sr_o;
input rbi_i;
input [31:0] signal_i;
output [7:0] exc_o;
parameter TM_CLKFREQ = 20000000;
parameter QENTRIES = `QENTRIES;
parameter QSLOTS = `QSLOTS;
parameter RENTRIES = `RENTRIES;
parameter RSLOTS = `RSLOTS;
parameter AREGS = 128;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;
parameter VAL = 1'b1;
parameter INV = 1'b0;
parameter RSTIP = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFF0100;
parameter BRKIP = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000;
parameter DEBUG = 1'b0;
parameter DBW = 80;
parameter ABW = 128;
parameter AMSB = ABW-1;
parameter RBIT = 6;
parameter WB_DEPTH = 7;

// Memory access sizes
parameter byt = 3'd0;
parameter wyde = 3'd1;
parameter tetra = 3'd2;
parameter penta = 3'd3;
parameter octa = 3'd4;
parameter hexi = 3'd5;

parameter byte_para = 4'd8;
parameter wyde_para = 4'd9;
parameter tetra_para = 4'd10;
parameter octa_para = 4'd11;
parameter hexi_para = 4'd12;

parameter fp32 = 4'd1;
parameter fp64 = 4'd2;
parameter fp128 = 4'd3;
parameter fp32_para = 4'd9;
parameter fp64_para = 4'd10;
parameter fp128_para = 4'd11;

// IQ states
parameter IQS_INVALID = 3'd0;
parameter IQS_QUEUED = 3'd1;
parameter IQS_OUT = 3'd2;
parameter IQS_AGEN = 3'd3;
parameter IQS_MEM = 3'd4;
parameter IQS_DONE = 3'd5;
parameter IQS_CMT = 3'd6;

parameter RS_INVALID = 2'd0;
parameter RS_ASSIGNED = 2'd1;
parameter RS_DONE = 2'd2;
parameter RS_CMT = 2'd3;

parameter NUnit = 3'd0;
parameter BUnit = 3'd1;
parameter IUnit = 3'd2;
parameter FUnit = 3'd3;
parameter MUnit = 3'd4;

parameter BBB = 7'h00;		// Branch, Branch, Branch template

`include "nvio3-busStates.sv"

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
reg stb;
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
reg [3:0] ip_mask, ip_maskd;
reg [AMSB:0] missip, excmissip;
wire freezeip;
reg [7:0] condreg [0:7];
reg [1:0] slot;
wire [AMSB:0] slot0ip = {ip[AMSB:2],2'h0};
wire [AMSB:0] slot1ip = {ip[AMSB:2],2'h1};
wire [AMSB:0] slot2ip = {ip[AMSB:2],2'h2};
wire [AMSB:0] slot3ip = {ip[AMSB:2],2'h3};
wire [QSLOTS-1:0] slotv;
wire [QSLOTS-1:0] slotvd;
reg [3:0] fb_panic;
wire [`SNBITS] maxsn;

wire [39:0] insnx [0:QSLOTS-1];
wire [3:0] brkbits;
// BF will be modified to BE by the decode buffer logic once the instruction has queued.
assign brkbits[0] = insnx[0][7:0]==8'hBF;	// prefix with a break
assign brkbits[1] = insnx[1][7:0]==8'hBF;
assign brkbits[2] = insnx[2][7:0]==8'hBF;
assign brkbits[3] = insnx[3][7:0]==8'hBF;

reg [4:0] state;
reg [7:0] cnt;
reg r1IsFp,r2IsFp,r3IsFp;

wire  [`QBITS] tails [0:QSLOTS-1];
wire  [`QBITS] heads [0:QENTRIES-1];
wire [`RBITS] rob_tails [0:RSLOTS-1];
wire [`RBITS] rob_heads [0:RSLOTS-1];

wire tlb_miss;
wire exv;

wire [RBIT:0] Rs1 [0:QSLOTS-1];
wire [RBIT:0] Rs2 [0:QSLOTS-1];
wire [RBIT:0] Rs3 [0:QSLOTS-1];
wire [RBIT:0] Rs4 [0:QSLOTS-1];
wire [RBIT:0] Rd [0:QSLOTS-1];
wire [RBIT:0] Rd2 [0:QSLOTS-1];
wire [2:0] Ms1 [0:QSLOTS-1];
wire [2:0] Ms2 [0:QSLOTS-1];
wire [2:0] Crs [0:QSLOTS-1];
assign Ms1[0] = Rs1[0];
assign Ms1[1] = Rs1[1];
assign Ms1[2] = Rs1[2];
assign Ms1[3] = Rs1[3];
assign Ms2[0] = insnx[0][33:31];
assign Ms2[1] = insnx[1][33:31];
assign Ms2[2] = insnx[2][33:31];
assign Ms2[3] = insnx[3][33:31];
assign Crs[0] = insnx[0][10:8];
assign Crs[1] = insnx[1][10:8];
assign Crs[2] = insnx[2][10:8];
assign Crs[3] = insnx[3][10:8];

reg [WID-1:0] gp_regfilex [0:31];
reg [WID-1:0] gp_regfile [0:31];
reg [WID-1:0] fp_regfilex [0:31];
reg [WID-1:0] fp_regfile [0:31];
reg [WID-1:0] lk_regfilex [0:31];
reg [WID-1:0] lk_regfile [0:31];
reg [VWID-1:0] vc_regfilex [0:31];
reg [VWID-1:0] vc_regfile [0:31];
reg [31:0] vm_regfilex [0:31];
reg [31:0] vm_regfile [0:31];
reg [15:0] vl_regx, vl_reg;
reg [7:0] cr_regfilex [0:7];
reg [7:0] cr_regfile [0:7];

wire [3:0] Crd [0:QSLOTS-1];
wire [127:0] gp_rfoa [0:QSLOTS-1];
wire [127:0] gp_rfob [0:QSLOTS-1];
wire [127:0] gp_rfoc [0:QSLOTS-1];
wire [127:0] fp_rfoa [0:QSLOTS-1];
wire [127:0] fp_rfob [0:QSLOTS-1];
wire [127:0] fp_rfoc [0:QSLOTS-1];
wire [127:0] lk_rfo [0:QSLOTS-1];
wire [7:0] cr_rfo [0:QSLOTS-1];
wire [255:0] vc_rfoa [0:QSLOTS-1];
wire [255:0] vc_rfob [0:QSLOTS-1];
wire [255:0] vc_rfoc [0:QSLOTS-1];
wire [255:0] vc_rfot [0:QSLOTS-1];
wire [31:0] vm_rfoa [0:QSLOTS-1];
wire [31:0] vm_rfob [0:QSLOTS-1];
wire [63:0] cra_o;

wire [AREGS-1:0] rf_v;								// register is valid
wire [AREGS-1:0] regIsValid;					// register is valid (in this cycle)
reg  [`QBITSP1] rf_source[0:AREGS-1];
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

reg [371:0] xdati;

wire [2:0] queuedCnt;
wire [2:0] rqueuedCnt;
reg queuedNop;
reg [2:0] hi_amt;
reg [2:0] r_amt, r_amt2;
wire [`SNBITS] tosub;

reg [47:0] codebuf[0:63];
reg [QENTRIES-1:0] setpred;

// instruction queue (ROB)
// State and stqte decodes
reg [2:0] iq_state [0:QENTRIES-1];
reg [QENTRIES-1:0] iq_v;			// entry valid?  -- this should be the first bit
reg [`QBITS] iq_br_tag [0:QENTRIES-1];
reg [`RBITS] iq_rid [0:QENTRIES-1];
reg [QENTRIES-1:0] iq_done;
reg [QENTRIES-1:0] iq_out;
reg [QENTRIES-1:0] iq_agen;
reg [`SNBITS] iq_sn [0:QENTRIES-1];  // instruction sequence number
reg [`QBITS] iq_is [0:QENTRIES-1];	// source of instruction
reg [QENTRIES-1:0] iq_pt;		// predict taken
reg [QENTRIES-1:0] iq_bt;		// update branch target buffer
reg [QENTRIES-1:0] iq_takb;	// take branch record
reg [QENTRIES-1:0] iq_jrl;
reg [3:0] iq_fmt [0:QENTRIES-1];
reg [QENTRIES-1:0] iq_z;
reg [QENTRIES-1:0] iq_pfx;		// prefix instruction
reg [QENTRIES-1:0] iq_alu = 8'h00;  // alu type instruction
reg [QENTRIES-1:0] iq_alu0 = 1'b0;
reg [QENTRIES-1:0] iq_fpu;  // floating point instruction
reg [QENTRIES-1:0] iq_vset;  // floating point instruction
reg [QENTRIES-1:0] iq_fc;   // flow control instruction
reg [QENTRIES-1:0] iq_canex = 8'h00;	// true if it's an instruction that can exception
reg [QENTRIES-1:0] iq_oddball = 8'h00;	// writes to register file
reg [QENTRIES-1:0] iq_lea;
reg [62:0] iq_sel [0:QENTRIES-1];
reg [QENTRIES-1:0] iq_load;	// is a memory load instruction
reg [QENTRIES-1:0] iq_store;	// is a memory store instruction
reg [QENTRIES-1:0] iq_preload;	// is a memory preload instruction
reg [QENTRIES-1:0] iq_ldcmp;
reg [1:0] iq_base [0:QENTRIES-1];
reg [QENTRIES-1:0] iq_mem;	// touches memory: 1 if LW/SW
reg [QENTRIES-1:0] iq_mem2;		// 2nd memory result
reg [QENTRIES-1:0] iq_memndx;  // indexed memory operation 
reg [2:0] iq_memsz [0:QENTRIES-1];	// size of memory op
reg [QENTRIES-1:0] iq_rmw;	// memory RMW op
reg [QENTRIES-1:0] iq_lsstring;
reg [QENTRIES-1:0] iq_lsm;
reg [QENTRIES-1:0] iq_stpair;
reg [QENTRIES-1:0] iq_push;
reg [QENTRIES-1:0] iq_pushc;
reg [QENTRIES-1:0] iq_pop;
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
reg [7:0] iq_cr [QENTRIES-1:0];
reg [QENTRIES-1:0] iq_rts;
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
reg [QENTRIES-1:0] iq_rfw;	// writes to register file
//reg [WID+3:0] iq_res	[0:QENTRIES-1];	// instruction result
//reg [31:0] iq_ares	[0:QENTRIES-1];	// alternate instruction result (fpu status)
reg [2:0] iq_unit[0:QENTRIES-1];
reg [39:0] iq_instr[0:QENTRIES-1];	// instruction opcode
reg  [7:0] iq_exc	[0:QENTRIES-1];	// only for branches ... indicates a HALT instruction
reg [RBIT:0] iq_rs1 [0:QENTRIES-1];
reg [RBIT:0] iq_rs2 [0:QENTRIES-1];		// debugging
reg [RBIT:0] iq_rs3 [0:QENTRIES-1];
reg [RBIT:0] iq_tgt [0:QENTRIES-1];		// Rt field or ZERO -- this is the instruction's target (if any)
reg [3:0] iq_crtgt [0:QENTRIES-1];
//reg [3:0] iq_tgtrs [0:QENTRIES-1];
//reg [3:0] iq_tgt2rs [0:QENTRIES-1];
reg [VWID-1:0] iq_argI	[0:QENTRIES-1];	// argument 0 (immediate)
reg [VWID-1:0] iq_argA	[0:QENTRIES-1];	// argument 1
reg [VWID-1:0] iq_argB	[0:QENTRIES-1];	// argument 2
reg [VWID-1:0] iq_argC	[0:QENTRIES-1];	// argument 3
reg [31:0] iq_argD	[0:QENTRIES-1];			// argument 4 (vector mask)
reg [VWID-1:0] iq_argT	[0:QENTRIES-1];	// target

reg [QENTRIES-1:0] iq_argA_v;	// arg1 valid
reg [`RBITSP1] iq_argA_s	[0:QENTRIES-1];	// arg1 source (iq entry # with top bit representing Rd2)
reg [QENTRIES-1:0] iq_argB_v;	// arg2 valid
reg  [`RBITSP1] iq_argB_s	[0:QENTRIES-1];	// arg2 source (iq entry # with top bit representing Rd2)
reg [QENTRIES-1:0] iq_argC_v;	// arg3 valid
reg  [`RBITSP1] iq_argC_s	[0:QENTRIES-1];	// arg3 source (iq entry # with top bit representing Rd2))
reg [QENTRIES-1:0] iq_argD_v;	// arg4 valid
reg  [`RBITSP1] iq_argD_s	[0:QENTRIES-1];	// arg4 source (iq entry # with top bit representing Rd2))
reg [QENTRIES-1:0] iq_argT_v;	// target valid
reg  [`RBITSP1] iq_argT_s	[0:QENTRIES-1];	// argt source (iq entry # with top bit representing Rd2))

reg [`ABITS] iq_ip	[0:QENTRIES-1];	// instruction pointer for this instruction
reg [AMSB:0] iq_ma [0:QENTRIES-1];	// memory address

reg [RENTRIES-1:0] rob_v;
reg [`QBITS] rob_id [0:RENTRIES-1];	// instruction queue id that owns this entry
reg [1:0] rob_state [0:RENTRIES-1];
reg [`ABITS] rob_ip	[0:RENTRIES-1];	// instruction pointer for this instruction
reg [2:0] rob_unit [0:RENTRIES-1];
reg [39:0] rob_instr[0:RENTRIES-1];	// instruction opcode
reg [7:0] rob_exc [0:RENTRIES-1];
reg [AMSB:0] rob_ma [0:RENTRIES-1];
reg [VWID-1:0] rob_argA [0:RENTRIES-1];	// value to use for CSR at oddball commit
reg [VWID-1:0] rob_res [0:RENTRIES-1];
reg [7:0] rob_cr [0:RENTRIES-1];
reg [31:0] rob_status [0:RENTRIES-1];
reg [RBIT:0] rob_tgt [0:RENTRIES-1];
reg [3:0] rob_crtgt [0:RENTRIES-1];
reg [7:0] rob_crres [0:RENTRIES-1];
reg [VWID-1:0] rob_res2 [0:RENTRIES-1];
reg [`RBIT2+1:0] nxtrb;

// debugging
initial begin
for (n = 0; n < QENTRIES; n = n + 1)
	iq_argA_s[n] <= 1'd0;
	iq_argB_s[n] <= 1'd0;
	iq_argC_s[n] <= 1'd0;
end

reg [QENTRIES-1:0] iq_source = {QENTRIES{1'b0}};
reg [QENTRIES-1:0] iq_source2 = {QENTRIES{1'b0}};
reg [QENTRIES-1:0] iq_imm;
reg [QENTRIES-1:0] iq_memready;
reg [QENTRIES-1:0] iq_memopsvalid;

reg [1:0] missued;
reg [7:0] last_issue0, last_issue1, last_issue2;
reg  [QENTRIES-1:0] iq_memissue;
reg [QENTRIES-1:0] iq_stomp;
reg [3:0] stompedOnRets;
reg [3:0] iq_fuid [0:QENTRIES-1];
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
reg [AREGS-1:1] livetarget2;
reg [AREGS-1:1] iq_livetarget [0:QENTRIES-1];
reg [AREGS-1:1] iq_livetarget2 [0:QENTRIES-1];
reg [AREGS-1:1] iq_latestID [0:QENTRIES-1];
reg [AREGS-1:1] iq_latestID2 [0:QENTRIES-1];
reg [AREGS-1:1] iq_cumulative [0:QENTRIES-1];
reg [AREGS-1:1] iq_cumulative2 [0:QENTRIES-1];
wire  [AREGS-1:1] iq_out2 [0:QENTRIES-1];
wire  [AREGS-1:1] iq_out2a [0:QENTRIES-1];

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
reg   [5:0] id1_Rt;
wire [`IBTOP:0] id_bus [0:QSLOTS-1];

reg         id2_v;
reg   [`QBITS] id2_id;
reg   [2:0] id2_unit;
reg  [39:0] id2_instr;
reg   [5:0] id2_ven;
reg   [7:0] id2_vl;
reg         id2_thrd;
reg         id2_pt;
reg   [5:0] id2_Rt;

reg         id3_v;
reg   [`QBITS] id3_id;
reg   [2:0] id3_unit;
reg  [39:0] id3_instr;
reg   [5:0] id3_ven;
reg   [7:0] id3_vl;
reg         id3_thrd;
reg         id3_pt;
reg   [5:0] id3_Rt;

reg [WID-1:0] alu0_xs = 64'd0;
reg [WID-1:0] alu1_xs = 64'd0;

reg [32:0] alu0_sn;
reg 				alu0_cmt;
wire				alu0_abort;
reg        alu0_ld;
reg        alu0_dataready;
wire       alu0_done;
wire       alu0_idle;
reg  [`QBITS] alu0_sourceid;
reg [`RBITS] alu0_rid;
reg [39:0] alu0_instr;
reg				 alu0_tlb;
reg        alu0_mem;
reg        alu0_load;
reg        alu0_store;
reg 			 alu0_push;
reg        alu0_shft;
reg [RBIT:0] alu0_Ra;
reg [VWID-1:0] alu0_argA;
reg [VWID-1:0] alu0_argB;
reg [VWID-1:0] alu0_argC;
reg [31:0] alu0_argD;
reg [VWID-1:0] alu0_argT;
reg alu0_z;
reg [WID-1:0] alu0_argI;	// only used by BEQ
reg [3:0]  alu0_fmt;
reg [RBIT:0] alu0_tgt;
reg [3:0] alu0_crtgt;
reg [`ABITS] alu0_ip;
reg [WID-1:0] alu0_bus;
wire [WID-1:0] alu0_bus2;
wire [WID-1:0] alu0b_bus;
wire [WID-1:0] alu0_out;
wire [7:0] alu0_cro;
wire  [`QBITS] alu0_id;
(* mark_debug="true" *)
wire  [`XBITS] alu0_exc;
wire        alu0_v;
wire alu0_vsn;
reg alu0_v1;
reg [`QBITS] alu0_id1;
reg [`QBITS] alu1_id1;
reg [WID-1:0] alu0_bus1;
reg [WID-1:0] alu1_bus1;
reg issuing_on_alu0;
reg alu0_dne = TRUE;

reg [32:0] alu1_sn;
reg 				alu1_cmt;
wire				alu1_abort;
reg        alu1_ld;
reg        alu1_dataready;
wire       alu1_done;
wire       alu1_idle;
reg  [`QBITS] alu1_sourceid;
reg [`RBITS] alu1_rid;
reg [39:0] alu1_instr;
reg        alu1_mem;
reg        alu1_load;
reg        alu1_store;
reg 			 alu1_push;
reg        alu1_shft;
reg [RBIT:0] alu1_Ra;
reg [VWID-1:0] alu1_argA;
reg [VWID-1:0] alu1_argB;
reg [VWID-1:0] alu1_argC;
reg [31:0] alu1_argD;
reg [VWID-1:0] alu1_argT;
reg alu1_z;
reg [WID-1:0] alu1_argI;	// only used by BEQ
reg [3:0]  alu1_fmt;
reg [RBIT:0] alu1_tgt;
reg [3:0] alu1_crtgt;
reg [`ABITS] alu1_ip;
reg [WID-1:0] alu1_bus;
wire [WID-1:0] alu1b_bus;
wire [WID-1:0] alu1_bus2;
wire [WID-1:0] alu1_out;
wire [7:0] alu1_cro;
wire  [`QBITS] alu1_id;
wire  [`XBITS] alu1_exc;
wire        alu1_v;
reg alu1_v1;
wire alu1_vsn;
reg issuing_on_alu1;
reg alu1_dne = TRUE;

wire agen0_v;
wire agen0_vsn;
wire agen0_idle;
reg [31:0] agen0_sn;
reg [`QBITS] agen0_sourceid;
wire [`QBITS] agen0_id;
reg [`RBITS] agen0_rid;
reg [RBIT:0] agen0_tgt;
reg agen0_dataready;
reg [2:0] agen0_unit;
reg [39:0] agen0_instr;
reg agen0_lea;
reg agen0_push;
reg agen0_pop;
reg agen0_mem2;
reg agen0_memdb;
reg agen0_memsb;
reg [AMSB:0] agen0_ma;
reg [WID-1:0] agen0_res;
reg [WID-1:0] agen0_argA, agen0_argB, agen0_argC, agen0_argI;
reg agen0_dne = TRUE;
reg agen0_stopString;
reg [11:0] agen0_bytecnt;
reg agen0_offset;
wire agen0_upd2;
reg [1:0] agen0_base;

wire agen1_v;
wire agen1_vsn;
wire agen1_idle;
reg [31:0] agen1_sn;
reg [`QBITS] agen1_sourceid;
wire [`QBITS] agen1_id;
reg [`RBITS] agen1_rid;
reg [RBIT:0] agen1_tgt;
reg agen1_dataready;
reg [2:0] agen1_unit;
reg [39:0] agen1_instr;
reg agen1_lea;
reg agen1_push;
reg agen1_pop;
reg agen1_mem2;
reg agen1_memdb;
reg agen1_memsb;
reg [AMSB:0] agen1_ma;
reg [WID-1:0] agen1_res;
reg [WID-1:0] agen1_argA, agen1_argB, agen1_argC, agen1_argI;
reg agen1_dne = TRUE;
wire agen1_upd2;
reg [1:0] agen1_base;

wire [`XBITS] fpu_exc;
reg 				fpu1_cmt;
reg        fpu1_ld;
reg        fpu1_dataready = 1'b1;
reg       fpu1_done = 1'b1;
wire       fpu1_idle;
reg [`QBITS] fpu1_sourceid;
reg [`RBITS] fpu1_rid;
reg [39:0] fpu1_instr;
reg [3:0] fpu1_fmt;
reg fpu1_vset;
reg fpu1_z;
reg [VWID-1:0] fpu1_argA;
reg [VWID-1:0] fpu1_argB;
reg [VWID-1:0] fpu1_argC;
reg [15:0] fpu1_argD;
reg [VWID-1:0] fpu1_argT;
reg [WID-1:0] fpu1_argI;	// only used by BEQ
reg [RBIT:0] fpu1_tgt;
reg [3:0] fpu1_crtgt;
reg [`ABITS] fpu1_ip;
reg [VWID-1:0] fpu1_out = 256'h0;
reg [VWID-1:0] fpu1_bus = 256'h0;
wire [7:0] fpu1_cro;
wire  [`QBITS] fpu1_id;
wire  [`XBITS] fpu1_exc;
wire        fpu1_v;
reg [255:0] fpu1_status;
reg fpu1_dne = TRUE;

reg 				fpu2_cmt;
reg        fpu2_ld;
reg        fpu2_dataready = 1'b1;
reg       fpu2_done = 1'b1;
wire       fpu2_idle;
reg [`QBITS] fpu2_sourceid;
reg [`RBITS] fpu2_rid;
reg [39:0] fpu2_instr;
reg [3:0] fpu2_fmt;
reg fpu2_vset;
reg fpu2_z;
reg [VWID-1:0] fpu2_argA;
reg [VWID-1:0] fpu2_argB;
reg [VWID-1:0] fpu2_argC;
reg [15:0] fpu2_argD;
reg [VWID-1:0] fpu2_argT;
reg [WID-1:0] fpu2_argI;	// only used by BEQ
reg [RBIT:0] fpu2_tgt;
reg [3:0] fpu2_crtgt;
reg [`ABITS] fpu2_ip;
reg [VWID-1:0] fpu2_out = 256'h0;
reg [VWID-1:0] fpu2_bus = 256'h0;
wire [7:0] fpu2_cro;
wire  [`QBITS] fpu2_id;
wire  [`XBITS] fpu2_exc;
wire        fpu2_v;
reg [255:0] fpu2_status;
reg fpu2_dne = TRUE;

reg [7:0] fccnt;
reg [47:0] waitctr;
reg 				fcu_cmt;
reg        fcu_ld;
reg        fcu_dataready;
reg        fcu_done;
reg         fcu_idle = 1'b1;
reg [`QBITS] fcu_sourceid;
reg [`RBITS] fcu_rid;
reg [39:0] fcu_instr;
reg [39:0] fcu_prevInstr;
reg  [2:0] fcu_insln;
reg        fcu_pt;			// predict taken
reg        fcu_branch;
reg        fcu_jsr;
reg        fcu_rts;
reg        fcu_jal;
reg        fcu_brk;
reg        fcu_rti;
reg				fcu_chk;
reg 			fcu_rex;
reg [7:0] fcu_cr;
reg [WID-1:0] fcu_argA;
reg [WID-1:0] fcu_argB;
reg [WID-1:0] fcu_argC;
reg [WID-1:0] fcu_argLk;
reg [WID-1:0] fcu_argI;	// only used by BEQ
reg [WID-1:0] fcu_argT;
reg [WID-1:0] fcu_argT2;
reg [RBIT:0] fcu_tgt;
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
reg fcu_dne = TRUE;

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
reg [`RBITS] dram0_rid;
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
reg [`RBITS] dram1_rid;
reg        dram1_unc;
reg [2:0]  dram1_memsize;
reg        dram1_load;
reg        dram1_store;
reg  [1:0] dram1_ol;

reg        dramA_v;
reg  [`QBITS] dramA_id;
reg [`RBITS] dramA_rid;
reg [WID-1:0] dramA_bus;
reg        dramB_v;
reg  [`QBITS] dramB_id;
reg [`QBITS] dramB_rid;
reg [WID-1:0] dramB_bus;

wire        outstanding_stores;
reg [47:0] I;		// instruction count
reg [47:0] CC;	// commit count

reg commit0_v;
reg [`RBITS] commit0_id;
reg [RBIT:0] commit0_tgt;
reg [VWID:0] commit0_bus;
reg [3:0] commit0_crtgt;
reg [7:0] commit0_crbus;
reg [3:0] commit0_rid;
reg commit1_v;
reg [`RBITS] commit1_id;
reg [RBIT:0] commit1_tgt;
reg [VWID:0] commit1_bus;
reg [3:0] commit1_crtgt;
reg [7:0] commit1_crbus;
reg [3:0] commit1_rid;
reg commit2_v;
reg [`RBITS] commit2_id;
reg [RBIT:0] commit2_tgt;
reg [VWID:0] commit2_bus;
reg [3:0] commit2_crtgt;
reg [7:0] commit2_crbus;
reg [3:0] commit2_rid;
reg commit3_v;
reg [`RBITS] commit3_id;
reg [RBIT:0] commit3_tgt;
reg [VWID:0] commit3_bus;
reg [3:0] commit3_crtgt;
reg [7:0] commit3_crbus;
reg [3:0] commit3_rid;

reg [5:0] ld_time;
reg [79:0] wc_time_dat;
reg [79:0] wc_times;

reg [`QBITS] active_tag, miss_tag;
reg [`QBITS] br_tag [0:QENTRIES-1];

reg [QSLOTS-1:0] queuedOn;
reg [QENTRIES-1:0] rqueuedOn;
wire [QSLOTS-1:0] queuedOnp;
wire [QSLOTS-1:0] predict_taken;
wire predict_taken0;
wire predict_taken1;
wire predict_taken2;
wire [QSLOTS-1:0] slot_rfw;
wire [QSLOTS-1:0] slot_jc;
wire [QSLOTS-1:0] slot_jrl;
wire [QSLOTS-1:0] slot_br;
wire [QSLOTS-1:0] slot_ret;

assign slot_rfw[0] = IsRFW(insnx[0]);
assign slot_rfw[1] = IsRFW(insnx[1]);
assign slot_rfw[2] = IsRFW(insnx[2]);
assign slot_rfw[3] = IsRFW(insnx[3]);
wire slot0_mem = IsMem(insnx[0]) && !IsLea(insnx[0]);
wire slot1_mem = IsMem(insnx[1]) && !IsLea(insnx[1]);
wire slot2_mem = IsMem(insnx[2]) && !IsLea(insnx[2]);
wire slot3_mem = IsMem(insnx[3]) && !IsLea(insnx[3]);
assign slot_jrl[0] = id_bus[0][`IB_JRL];
assign slot_jrl[1] = id_bus[1][`IB_JRL];
assign slot_jrl[2] = id_bus[2][`IB_JRL];
assign slot_jrl[3] = id_bus[3][`IB_JRL];
assign slot_jc[0] = id_bus[0][`IB_JSR];
assign slot_jc[1] = id_bus[1][`IB_JSR];
assign slot_jc[2] = id_bus[2][`IB_JSR];
assign slot_jc[3] = id_bus[3][`IB_JSR];
assign slot_ret[0] = id_bus[0][`IB_RTS];
assign slot_ret[1] = id_bus[1][`IB_RTS];
assign slot_ret[2] = id_bus[2][`IB_RTS];
assign slot_ret[3] = id_bus[3][`IB_RTS];
assign slot_br[0] = IsBrk(insnxp[0]) || IsRti(insnxp[0]);
assign slot_br[1] = IsBrk(insnxp[1]) || IsRti(insnxp[1]);
assign slot_br[2] = IsBrk(insnxp[2]) || IsRti(insnxp[2]);
assign slot_br[3] = IsBrk(insnxp[3]) || IsRti(insnxp[3]);
assign take_branch[0] = (IsBranch(insnx[0]) && predict_taken[0]) || IsBrk(insnx[0]) || IsRti(insnx[0]);
assign take_branch[1] = (IsBranch(insnx[1]) && predict_taken[1]) || IsBrk(insnx[1]) || IsRti(insnx[1]);
assign take_branch[2] = (IsBranch(insnx[2]) && predict_taken[2]) || IsBrk(insnx[2]) || IsRti(insnx[2]);
assign take_branch[3] = (IsBranch(insnx[3]) && predict_taken[3]) || IsBrk(insnx[3]) || IsRti(insnx[3]);
// Branching for purposes of the branch shadow.
wire [QSLOTS-1:0] is_branch;
reg [QENTRIES-1:0] is_qbranch;
assign is_branch[0] = IsBranch(insnx[0]) || id_bus[0][`IB_BRK] || id_bus[0][`IB_RTI] || id_bus[0][`IB_RTS] || id_bus[0][`IB_JRL];
assign is_branch[1] = IsBranch(insnx[1]) || id_bus[1][`IB_BRK] || id_bus[1][`IB_RTI] || id_bus[1][`IB_RTS] || id_bus[1][`IB_JRL];
assign is_branch[2] = IsBranch(insnx[2]) || id_bus[2][`IB_BRK] || id_bus[2][`IB_RTI] || id_bus[2][`IB_RTS] || id_bus[2][`IB_JRL];
assign is_branch[3] = IsBranch(insnx[3]) || id_bus[3][`IB_BRK] || id_bus[3][`IB_RTI] || id_bus[3][`IB_RTS] || id_bus[3][`IB_JRL];
always @*
for (n = 0; n < QENTRIES; n = n + 1)
	is_qbranch[n] = iq_br[n] | iq_brk[n] | iq_rti[n] | iq_rts[n] | iq_jrl[n] | iq_brcc[n];
wire [1:0] ic_fault;
wire [1023:0] ic_out;
wire [AMSB:0] missadr;
reg invic, invdc;
reg invicl;
reg [4:0] bstate;
wire [3:0] icstate;
reg [1:0] bwhich;
wire ihit;
reg phit;
reg phitd;
// The L1 address might not be equal to the ip if a cache update is taking
// place. This can lead to a false hit because once the cache is updated
// it'll match L1, but L1 hasn't switched back to ip yet, and it's a hit
// on the ip address we're looking for. => make sure the cache controller
// is IDLE.
wire nextb;		// fetch next bundle
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
wire [255:0] d0ROM_dat;
wire [255:0] d1ROM_dat;

wire isROM;
wire d0isROM, d1isROM;
wire d0L1_wr, d0L2_ld;
wire d1L1_wr, d1L2_ld;
wire [79:0] d0L1_adr, d0L2_adr;
wire [79:0] d1L1_adr, d1L2_adr;
wire d0L1_rhit, d0L2_rhit, d0L2_whit;
wire d0L2_rhita, d1L2_rhita;
wire d0L1_nxt, d0L2_nxt;					// advances cache way lfsr
wire d1L1_dhit, d1L2_rhit, d1L2_whit;
wire d1L1_nxt, d1L2_nxt;					// advances cache way lfsr
wire [41:0] d0L1_sel, d0L2_sel;
wire [41:0] d1L1_sel, d1L2_sel;
wire [335:0] d0L1_dat, d0L2_rdat, d0L2_wdat;
wire [335:0] d1L1_dat, d1L2_rdat, d1L2_wdat;
wire d0L1_dhit, d0L2_hit;
wire d0L1_selpc, d0L2_selpc;
wire d1L1_selpc, d1L2_selpc;
wire d0L1_invline,d1L1_invline;
//reg [255:0] dcbuf;

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
reg [31:0] dcsel;
wire update_iq;
wire [QENTRIES-1:0] uid;
wire [RENTRIES-1:0] ruid;

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

function IsNop;
input [39:0] ins;
IsNop = ins[`OPCODE]==`NOP;
endfunction

wire [`RBITS] next_iq_rid [0:QENTRIES-1];
wire [`RENTRIES-1:0] next_rob_v;

regfileValid urfv1
(
	.rst(rst_i),
	.clk(clk),
	.slotvd(slotvd),
	.slot_rfw(slot_rfw),
	.tails(tails),
	.livetarget(livetarget),
	.livetarget2(livetarget2),
	.branchmiss(branchmiss),
	.rob_id(rob_id),
	.commit0_v(commit0_v),
	.commit1_v(commit1_v),
	.commit2_v(commit2_v),
	.commit3_v(commit3_v),
	.commit0_id(commit0_id),
	.commit1_id(commit1_id),
	.commit2_id(commit2_id),
	.commit3_id(commit3_id),
	.commit0_tgt(commit0_tgt),
	.commit1_tgt(commit1_tgt),
	.commit2_tgt(commit2_tgt),
	.commit3_tgt(commit3_tgt),
	.rf_source(rf_source),
	.iq_source(iq_source),
	.iq_source2(iq_source2),
	.take_branch(take_branch),
	.Rd(Rd),
	.Rd2(Rd2),
	.queuedOn(queuedOnp),
	.rf_v(rf_v),
	.regIsValid(regIsValid)
);

regfileSource urfs1
(
	.rst(rst_i),
	.clk(clk),
	.branchmiss(branchmiss),
	.heads(heads),
	.slotvd(slotvd),
	.slot_rfw(slot_rfw),
	.queuedOn(queuedOnp),
	.rqueuedOn(rqueuedOn),
	.iq_state(iq_state),
	.iq_rfw(iq_rfw),
	.iq_Rd(iq_tgt),
	.Rd(Rd),
	.Rd2(Rd2),
	.rob_tails(rob_tails),
	.iq_latestID(iq_latestID),
	.iq_latestID2(iq_latestID2),
	.iq_tgt(iq_tgt),
	.iq_rid(iq_rid),
	.rf_source(rf_source)
);

assign gp_rfoa[0] = gp_regfilex[Rs1[0][4:0]];
assign gp_rfoa[1] = gp_regfilex[Rs1[1][4:0]];
assign gp_rfoa[2] = gp_regfilex[Rs1[2][4:0]];
assign gp_rfoa[3] = gp_regfilex[Rs1[3][4:0]];
assign gp_rfob[0] = gp_regfilex[Rs2[0][4:0]];
assign gp_rfob[1] = gp_regfilex[Rs2[1][4:0]];
assign gp_rfob[2] = gp_regfilex[Rs2[2][4:0]];
assign gp_rfob[3] = gp_regfilex[Rs2[3][4:0]];
assign gp_rfoc[0] = gp_regfilex[Rs3[0][4:0]];
assign gp_rfoc[1] = gp_regfilex[Rs3[1][4:0]];
assign gp_rfoc[2] = gp_regfilex[Rs3[2][4:0]];
assign gp_rfoc[3] = gp_regfilex[Rs3[3][4:0]];

assign fp_rfoa[0] = fp_regfilex[Rs1[0][4:0]];
assign fp_rfoa[1] = fp_regfilex[Rs1[1][4:0]];
assign fp_rfoa[2] = fp_regfilex[Rs1[2][4:0]];
assign fp_rfoa[3] = fp_regfilex[Rs1[3][4:0]];
assign fp_rfob[0] = fp_regfilex[Rs2[0][4:0]];
assign fp_rfob[1] = fp_regfilex[Rs2[1][4:0]];
assign fp_rfob[2] = fp_regfilex[Rs2[2][4:0]];
assign fp_rfob[3] = fp_regfilex[Rs2[3][4:0]];
assign fp_rfoc[0] = fp_regfilex[Rs3[0][4:0]];
assign fp_rfoc[1] = fp_regfilex[Rs3[1][4:0]];
assign fp_rfoc[2] = fp_regfilex[Rs3[2][4:0]];
assign fp_rfoc[3] = fp_regfilex[Rs3[3][4:0]];

assign vc_rfoa[0] = vc_regfilex[Rs1[0][4:0]];
assign vc_rfoa[1] = vc_regfilex[Rs1[1][4:0]];
assign vc_rfoa[2] = vc_regfilex[Rs1[2][4:0]];
assign vc_rfoa[3] = vc_regfilex[Rs1[3][4:0]];
assign vc_rfob[0] = vc_regfilex[Rs2[0][4:0]];
assign vc_rfob[1] = vc_regfilex[Rs2[1][4:0]];
assign vc_rfob[2] = vc_regfilex[Rs2[2][4:0]];
assign vc_rfob[3] = vc_regfilex[Rs2[3][4:0]];
assign vc_rfoc[0] = vc_regfilex[Rs3[0][4:0]];
assign vc_rfoc[1] = vc_regfilex[Rs3[1][4:0]];
assign vc_rfoc[2] = vc_regfilex[Rs3[2][4:0]];
assign vc_rfoc[3] = vc_regfilex[Rs3[3][4:0]];
assign vc_rfot[0] = vc_regfilex[Rd[0][4:0]];
assign vc_rfot[1] = vc_regfilex[Rd[1][4:0]];
assign vc_rfot[2] = vc_regfilex[Rd[2][4:0]];
assign vc_rfot[3] = vc_regfilex[Rd[3][4:0]];

assign lk_rfo[0] = lk_regfilex[Rs2[0][2:0]];
assign lk_rfo[1] = lk_regfilex[Rs2[1][2:0]];
assign lk_rfo[2] = lk_regfilex[Rs2[2][2:0]];
assign lk_rfo[3] = lk_regfilex[Rs2[3][2:0]];

assign vm_rfoa[0] = vm_regfilex[Ms1[0][2:0]];
assign vm_rfoa[1] = vm_regfilex[Ms1[1][2:0]];
assign vm_rfoa[2] = vm_regfilex[Ms1[2][2:0]];
assign vm_rfoa[3] = vm_regfilex[Ms1[3][2:0]];
assign vm_rfob[0] = vm_regfilex[Ms2[0][2:0]];
assign vm_rfob[1] = vm_regfilex[Ms2[1][2:0]];
assign vm_rfob[2] = vm_regfilex[Ms2[2][2:0]];
assign vm_rfob[3] = vm_regfilex[Ms2[3][2:0]];

assign cr_rfo[0] = cr_regfilex[Crs[0][2:0]];
assign cr_rfo[1] = cr_regfilex[Crs[1][2:0]];
assign cr_rfo[2] = cr_regfilex[Crs[2][2:0]];
assign cr_rfo[3] = cr_regfilex[Crs[3][2:0]];

reg [AMSB:0] program_base;
reg [AMSB:0] data_base;
reg [AMSB:0] io_base;
reg [AMSB:0] extra_base;

initial begin
	program_base = 1'd0;
	data_base = 1'd0;
	io_base = 1'd0;
	extra_base = 1'd0;
end

// Determine amount to advance reorder head pointer by. Based on number of
// consecutive valid commits. Also up to four additional slot that have been
// marked invalid may be advanced past.
always @*
begin
	if (commit0_v & commit1_v & commit2_v & commit3_v)
		r_amt = 3'd4;
	else if (commit0_v & commit1_v & commit2_v)
		r_amt = 3'd3;
	else if (commit0_v & commit1_v)
		r_amt = 3'd2;
	else if (commit0_v)
		r_amt = 3'd1;
	else
		r_amt = 3'd0;

	// Now search ahead for invalid entries that can be skipped over.
	nxtrb = (rob_heads[0] + r_amt) % RENTRIES;
	if (rob_state[nxtrb[`RBITS]]==RS_INVALID && rob_heads[nxtrb[`RBITS]]!=rob_tails[0]) begin
		r_amt = r_amt + 4'd1;
		nxtrb = rob_heads[0] + r_amt;
		if (rob_state[nxtrb[`RBITS]]==RS_INVALID && rob_heads[nxtrb[`RBITS]]!=rob_tails[0]) begin
			r_amt = r_amt + 4'd1;
			nxtrb = rob_heads[0] + r_amt;
			if (rob_state[nxtrb[`RBITS]]==RS_INVALID && rob_heads[nxtrb[`RBITS]]!=rob_tails[0]) begin
				r_amt = r_amt + 4'd1;
				nxtrb = rob_heads[0] + r_amt;
				if (rob_state[nxtrb[`RBITS]]==RS_INVALID && rob_heads[nxtrb[`RBITS]]!=rob_tails[0]) begin
					r_amt = r_amt + 4'd1;
					nxtrb = rob_heads[0] + r_amt;
				end
			end
		end
	end
end

// For vector length
task rf_upd16;
input [`RBITS] n;
input [15:0] i;
output [15:0] o;
begin
	if (commit3_v && commit3_tgt==n)
		o = commit3_bus[15:0];
	else if (commit2_v && commit2_tgt==n)
		o = commit2_bus[15:0];
	else if (commit1_v && commit1_tgt==n)
		o = commit1_bus[15:0];
	else if (commit0_v && commit0_tgt==n)
		o = commit0_bus[15:0];
	else
		o = i;
end
endtask

// For vector masks
task rf_upd32;
input [`RBITS] n;
input [31:0] i;
output [31:0] o;
begin
	if (commit3_v && commit3_tgt==n)
		o = commit3_bus[31:0];
	else if (commit2_v && commit2_tgt==n)
		o = commit2_bus[31:0];
	else if (commit1_v && commit1_tgt==n)
		o = commit1_bus[31:0];
	else if (commit0_v && commit0_tgt==n)
		o = commit0_bus[31:0];
	else
		o = i;
end
endtask

task rf_upd128;
input [`RBITS] n;
input [127:0] i;
output [127:0] o;
begin
	if (commit3_v && commit3_tgt==n)
		o = commit3_bus[127:0];
	else if (commit2_v && commit2_tgt==n)
		o = commit2_bus[127:0];
	else if (commit1_v && commit1_tgt==n)
		o = commit1_bus[127:0];
	else if (commit0_v && commit0_tgt==n)
		o = commit0_bus[127:0];
	else
		o = i;
end
endtask

task rf_upd256;
input [`RBITS] n;
input [255:0] i;
output [255:0] o;
begin
	if (commit3_v && commit3_tgt==n)
		o = commit3_bus[255:0];
	else if (commit2_v && commit2_tgt==n)
		o = commit2_bus[255:0];
	else if (commit1_v && commit1_tgt==n)
		o = commit1_bus[255:0];
	else if (commit0_v && commit0_tgt==n)
		o = commit0_bus[255:0];
	else
		o = i;
end
endtask

always @*
begin
gp_regfilex[0] = 128'd0;
for (n = 1; n < 32; n = n + 1)
	rf_upd128({2'b00,n[4:0]},gp_regfile[n],gp_regfilex[n]);
end
always @*
begin
fp_regfilex[0] = 128'd0;
for (n = 1; n < 32; n = n + 1)
	rf_upd128({2'b01,n[4:0]},fp_regfile[n],fp_regfilex[n]);
end
always @*
for (n = 0; n < 32; n = n + 1)
	rf_upd256({2'b10,n[4:0]},vc_regfile[n],vc_regfilex[n]);
always @*
begin
lk_regfilex[0] = 128'd0;
for (n = 1; n < 8; n = n + 1)
	rf_upd128({4'b1100,n[2:0]},lk_regfile[n],lk_regfilex[n]);
end
always @*
for (n = 0; n < 8; n = n + 1)
	rf_upd32({4'b1101,n[2:0]},vm_regfile[n],vm_regfilex[n]);
always @*
	rf_upd16(124,vl_reg,vl_regx);

always @(posedge clk)
for (n = 1; n < 32; n = n + 1)
	gp_regfile[n] <= gp_regfilex[n];
always @(posedge clk)
for (n = 1; n < 32; n = n + 1)
	fp_regfile[n] <= fp_regfilex[n];
always @(posedge clk)
for (n = 0; n < 32; n = n + 1)
	vc_regfile[n] <= vc_regfilex[n];
always @(posedge clk)
for (n = 1; n < 8; n = n + 1)
	lk_regfile[n] <= lk_regfilex[n];
always @(posedge clk)
for (n = 0; n < 8; n = n + 1)
	vm_regfile[n] <= vm_regfilex[n];
always @(posedge clk)
	vl_reg <= vl_regx;

always @*
begin
if (commit3_v && commit3_tgt==7'd125) begin
	cr_regfilex[0] <= commit3_bus[7:0];
	cr_regfilex[1] <= commit3_bus[15:8];
	cr_regfilex[2] <= commit3_bus[23:16];
	cr_regfilex[3] <= commit3_bus[31:24];
	cr_regfilex[4] <= commit3_bus[39:32];
	cr_regfilex[5] <= commit3_bus[47:40];
	cr_regfilex[6] <= commit3_bus[55:48];
	cr_regfilex[7] <= commit3_bus[63:56];
end
else if (commit2_v && commit2_tgt==7'd125) begin
	cr_regfilex[0] <= commit2_bus[7:0];
	cr_regfilex[1] <= commit2_bus[15:8];
	cr_regfilex[2] <= commit2_bus[23:16];
	cr_regfilex[3] <= commit2_bus[31:24];
	cr_regfilex[4] <= commit2_bus[39:32];
	cr_regfilex[5] <= commit2_bus[47:40];
	cr_regfilex[6] <= commit2_bus[55:48];
	cr_regfilex[7] <= commit2_bus[63:56];
end
else if (commit1_v && commit1_tgt==7'd125) begin
	cr_regfilex[0] <= commit1_bus[7:0];
	cr_regfilex[1] <= commit1_bus[15:8];
	cr_regfilex[2] <= commit1_bus[23:16];
	cr_regfilex[3] <= commit1_bus[31:24];
	cr_regfilex[4] <= commit1_bus[39:32];
	cr_regfilex[5] <= commit1_bus[47:40];
	cr_regfilex[6] <= commit1_bus[55:48];
	cr_regfilex[7] <= commit1_bus[63:56];
end
else if (commit0_v && commit0_tgt==7'd125) begin
	cr_regfilex[0] <= commit0_bus[7:0];
	cr_regfilex[1] <= commit0_bus[15:8];
	cr_regfilex[2] <= commit0_bus[23:16];
	cr_regfilex[3] <= commit0_bus[31:24];
	cr_regfilex[4] <= commit0_bus[39:32];
	cr_regfilex[5] <= commit0_bus[47:40];
	cr_regfilex[6] <= commit0_bus[55:48];
	cr_regfilex[7] <= commit0_bus[63:56];
end
else begin
	for (n = 0; n < 8; n = n + 1) begin
	if (commit3_v && commit3_tgt=={4'b1110,n[2:0]})
		cr_regfilex[n] <= commit3_bus[7:0];
	else if (commit2_v && commit2_tgt=={4'b1110,n[2:0]})
		cr_regfilex[n] <= commit2_bus[7:0];
	else if (commit1_v && commit1_tgt=={4'b1110,n[2:0]})
		cr_regfilex[n] <= commit1_bus[7:0];
	else if (commit0_v && commit0_tgt=={4'b1110,n[2:0]})
		cr_regfilex[n] <= commit0_bus[7:0];
	else if (commit3_v && commit3_crtgt=={1'b1,n[2:0]})
		cr_regfilex[n] <= commit3_crbus;
	else if (commit2_v && commit2_crtgt=={1'b1,n[2:0]})
		cr_regfilex[n] <= commit2_crbus;
	else if (commit1_v && commit1_crtgt=={1'b1,n[2:0]})
		cr_regfilex[n] <= commit1_crbus;
	else if (commit0_v && commit0_crtgt=={1'b1,n[2:0]})
		cr_regfilex[n] <= commit0_crbus;
	else
		cr_regfilex[n] <= cr_regfile[n];
	end
end
end
always @(posedge clk)
for (n = 0; n < 8; n = n + 1)
	cr_regfile[n] <= cr_regfilex[n];

reg [WID-1:0] argA[QSLOTS-1:0];
reg [WID-1:0] argB[QSLOTS-1:0];
reg [WID-1:0] argC[QSLOTS-1:0];
reg [WID-1:0] argD[QSLOTS-1:0];
reg [WID-1:0] argT[QSLOTS-1:0];

// link registers are never argA
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	casez(Rs1[n])
	7'b00?????:	argA[n] <= gp_rfoa[n];
	7'b01?????:	argA[n] <= fp_rfoa[n];
	7'b10?????:	argA[n] <= vc_rfoa[n];
	7'b1101???:	argA[n] <= vm_rfoa[n];
	7'b1110???:	argA[n] <= cr_rfo[n];
	7'b1111100:	argA[n] <= vl_regx;			// for move
	7'b1111101:	argA[n] <= {cr_regfilex[7],cr_regfilex[6],cr_regfilex[5],cr_regfilex[4],cr_regfilex[3],cr_regfilex[2],cr_regfilex[1],cr_regfilex[0]};
	default:		argA[n] <= 256'd0;
	endcase

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	casez(Rs2[n])
	7'b00?????:	argB[n] <= gp_rfob[n];
	7'b01?????:	argB[n] <= fp_rfob[n];
	7'b10?????:	argB[n] <= vc_rfob[n];
	7'b1100???:	argB[n] <= lk_rfo[n];
	7'b1111100:	argA[n] <= vl_regx;			// For store
	7'b1111101:	argB[n] <= {cr_regfilex[7],cr_regfilex[6],cr_regfilex[5],cr_regfilex[4],cr_regfilex[3],cr_regfilex[2],cr_regfilex[1],cr_regfilex[0]};
	default:		argB[n] <= 256'd0;
	endcase
	
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	casez(Rs3[n])
	7'b00?????:	argC[n] <= gp_rfoc[n];
	7'b01?????:	argC[n] <= fp_rfoc[n];
	7'b10?????:	argC[n] <= vc_rfoc[n];
	default:		argC[n] <= 256'd0;
	endcase

// Only the vector mask register is argD
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	casez(Rs4[n])
	7'b1101???:	argD[n] <= vm_rfob[n];
	default:		argD[n] <= 256'd0;
	endcase

// Only thing needing target as a source is vector instructions
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	casez(Rd[n])
	7'b10?????:	argT[n] <= vc_rfot[n];
	default:		argT[n] <= 256'd0;
	endcase


instructionPointer uip1
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

reg [AMSB:0] ipb;
always @*
if (ol!=2'b00 && ip[AMSB:AMSB-11]!=12'hFFF)
	ipb <= ip + program_base;
else
	ipb <= ip;

`ifdef FCU_RSB
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
	.call(slot_jsr),
	.ret(slot_rts),
	.ip(ipd),
	.ra(ra),
	.stompedRets(),
	.stompedRet()
);
`else
assign ra = `FCU_RA;
`endif

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
	.missadr(missadr),
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
	.adr(L1_selpc ? ipb : L1_adr),
	.i(L1_dat),
	.o(ic_out),
	.fault(),
	.hit(L1_ihit),
	.invall(invic),
	.invline(L1_invline),
	.missadr(missadr)
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
	.hit(L2_ihita),
	.invall(invic),
	.invline(L1_invline)
);

assign L2_ihit = isROM|L2_ihita;
assign d0L2_rhit = d0isROM|d0L2_rhita;
assign d1L2_rhit = d1isROM|d1L2_rhita;

reg [12:0] rL1_adr;
reg [12:0] rd0L1_adr;
reg [12:0] rd1L1_adr;
(* ram_style="block" *)
reg [255:0] rommem [0:7167];
initial begin
`include "d:/cores6/nvio/v1/software/boot/boottc.ve0"
end
always @(posedge clk)
	rL1_adr <= L1_adr[17:5];
always @(posedge clk)
	rd0L1_adr <= d0L1_adr[17:5];
always @(posedge clk)
	rd1L1_adr <= d1L1_adr[17:5];
assign ROM_dat = rommem[rL1_adr];
assign d0ROM_dat = rommem[rd0L1_adr];
assign d1ROM_dat = rommem[rd1L1_adr];

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

`ifdef FCU_BTB
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
`else
assign btgt[0] = {ip[AMSB:4],4'h5};
assign btgt[1] = {ip[AMSB:4],4'hA};
assign btgt[2] = {ip[AMSB:4]+4'h1,4'h0};
`endif

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
assign xisBr[3] = iq_br[heads[3]] & commit3_v & ~iq_instr[heads[3]][5];
assign xip[0] = iq_ip[heads[0]];
assign xip[1] = iq_ip[heads[1]];
assign xip[2] = iq_ip[heads[2]];
assign xip[3] = iq_ip[heads[3]];
assign xtkb[0] = commit0_v & iq_takb[heads[0]];
assign xtkb[1] = commit1_v & iq_takb[heads[1]];
assign xtkb[2] = commit2_v & iq_takb[heads[2]];
assign xtkb[3] = commit3_v & iq_takb[heads[3]];

wire [QSLOTS-1:0] predict_takenx;

`ifdef FCU_BP
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
`else
assign predict_takenx[0] = insnx[0][39];
assign predict_takenx[1] = insnx[1][39];
assign predict_takenx[2] = insnx[2][39];
`endif

assign predict_taken[0] = insnx[0][12]==1'b1 ? insnx[0][11] : predict_takenx[0];
assign predict_taken[1] = insnx[1][12]==1'b1 ? insnx[1][11] : predict_takenx[1];
assign predict_taken[2] = insnx[2][12]==1'b1 ? insnx[2][11] : predict_takenx[2];


reg StoreAck1, isStore;
wire [79:0] dc0_out, dc1_out;
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
	.isROM(d0isROM),
	.ROM_dat(d0ROM_dat),
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
	.sel(d0L1_sel),
	.adr(d0L1_selpc ? dram0_addr : d0L1_adr),
	.i({5'd0,d0L1_dat}),
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
	.tlbmiss_i(1'b0),
	.rdv_i(1'b0),
	.wrv_i(1'b0),
	.i(d0L2_wdat),
	.err_i(1'b0),
	.o(d0L2_rdat),
	.rhit(d0L2_rhita),
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
	.isROM(d1isROM),
	.ROM_dat(d1ROM_dat),
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
	.sel(d1L1_sel),
	.adr(d1L1_selpc ? dram1_addr : d1L1_adr),
	.i({5'd0,d1L1_dat}),
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
	.tlbmiss_i(1'b0),
	.rdv_i(1'b0),
	.wrv_i(1'b0),
	.i(d1L2_wdat),
	.err_i(1'b0),
	.o(d1L2_rdat),
	.rhit(d1L2_rhita),
	.whit(d1L2_whit),
	.invall(invdc),
	.invline(d1L1_invline)
);

wire [255:0] aligned_data = fnDatiAlign(dram0_addr,xdati);
wire [255:0] rdat0, rdat1;
assign rdat0 = fnDataExtend(dram0_instr,dram0_unc ? aligned_data : dc0_out);
assign rdat1 = fnDataExtend(dram1_instr,dram1_unc ? aligned_data : dc1_out);
reg [79:0] rmw_ad0, rmw_ad1;
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

writeBuffer #(.QENTRIES(QENTRIES)) uwb1
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
	.ruid(ruid),
	.fault(wb_fault),
	.p0_id_i(dram0_id),
	.p0_rid_i(dram0_rid),
	.p0_ol_i(dram0_ol),
	.p0_wr_i(wb_p0_wr),
	.p0_ack_o(wb_q0_done),
	.p0_sel_i(fnSelect(dram0_instr)),
	.p0_adr_i(dram0_addr),
	.p0_dat_i(dram0_data),
	.p0_hit(wb_hit0),
	.p1_id_i(dram1_id),
	.p1_rid_i(dram1_rid),
	.p1_ol_i(dram1_ol),
	.p1_wr_i(wb_p1_wr),
	.p1_ack_o(wb_q1_done),
	.p1_sel_i(fnSelect(dram1_instr)),
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
	.heads(heads),
	.ramt(r_amt),
	.rob_heads(rob_heads)
);

tailptrs utp1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.branchmiss(branchmiss),
	.iq_stomp(iq_stomp),
	.iq_br_tag(iq_br_tag),
	.queuedCnt(queuedCnt),
	.iq_tails(tails),
	.rqueuedCnt(queuedCnt),
	.rob_tails(rob_tails),
	.active_tag(miss_tag),
	.iq_rid(iq_rid)
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

decodeBuffer udcb1
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
	.stop_string(agen0_stopString),
	.phit(phit),
	.next_bundle(nextb),
	.insnxp(insnxp),
	.insnx(insnx),
	.ip(ipb[5:0]),
	.queued(queuedCnt!=3'd0),
	.queuedOnp(queuedOnp)
);

// Which condition register to update. 
function [3:0] fnCrd;
input [39:0] ins;
casez(ins[`OPCODE])
`R1,`R2,`R2S:
	if (ins[33])
		fnCrd = 4'b1000;
	else
		fnCrd = 4'b0000;
`R2:
	if (ins[33])
		fnCrd = 4'b1000;
	else
		fnCrd = 4'b0000;
8'hE?:	// Float operations
	case(ins[`OPCODE])
	`FLT2,`FLT2I,`FLT2S:
		if (ins[33])
			fnCrd = 4'b1001;
		else
			fnCrd = 4'b0000;
	default:
		if (ins[33])
			fnCrd = 4'b1001;
		else
			fnCrd = 4'b0000;
	endcase
`ADDIr,`MULIr,`DIVIr,`MODIr,`ANDIr,`ORIr,`EORIr:
	fnCrd = 4'b1000;
default:
	fnCrd = 4'b0000;
endcase
endfunction

function [6:0] fnRd;
input [39:0] ins;
casez(ins[`OPCODE])
8'h1A:			fnRd = 7'd121;// LDCR
`JSR:			fnRd = {4'b1100,ins[`RD3]};
`RTS:				fnRd = {2'b00,ins[`RD]};
`BMISC2:
	case(ins[`BFUNCT4])
	`SEI: fnRd = {2'b0,ins[`RD]};
	`MTL:	fnRd = {2'b11,ins[`RD]};				// MTM and MTL
	`CRLOG:	fnRd = 7'b1111101;	// CRLOG (for dependency check)
	default: fnRd = 7'd0;
	endcase
8'b10??????:
	case(ins[`OPCODE])
	`CMPI,`CMPUI:	fnRd = {4'b1110,ins[`RD3]};
	`R2,`R2S:
		case(ins[`FUNCT6])
		`CMP,`CMPU:	fnRd = {4'b1110,ins[`RD3]};
		default:
			fnRd = {2'b0,ins[`RD]};	// ALU
		endcase
	default:
		fnRd = {2'b0,ins[`RD]};	// ALU
	endcase
8'hE1:
	case(ins[`FUNCT6])
	`FTOI:	fnRd = {2'b0,ins[`RD]};
	default:	fnRd = {2'b01,ins[`RD]};
	endcase
`FLT2,`FLT2S:
	case(ins[`FFUNCT5])
	`FCMP,`FCMPM:	fnRd = {4'b1110,ins[`RD3]};
	default:
		fnRd = {2'b01,ins[`RD]};
	endcase
8'hE3,8'hE4,8'hE5,8'hE6,8'hE7:
		fnRd = {2'b01,ins[`RD]};
8'h2D:	fnRd = {2'b00,ins[`RD]};	// TLB
8'b0?,8'h1?:
				fnRd = {2'b00,ins[`RD]};	// MLD
`STORE:
	case(ins[`OPCODE])
	`PUSH,`PUSHC:	fnRd = {2'b00,ins[`RD]};
	default:	fnRd = 7'd0;
	endcase
8'h4?,8'h5?:
				fnRd = {2'b10,ins[`RD]};	// VMLD
default:	fnRd = 7'd0;
endcase
endfunction

function [6:0] fnRd2;
input [39:0] ins;
casez(ins[`OPCODE])
`MEMORY:
	case(ins[`OPCODE])
	`POP:		fnRd2 = {1'b0,ins[`RS1]};
	`PUSHC:	fnRd2 <= 7'd0;
	`LINK:	fnRd2 <= 7'd0;
	default:
		case(ins[`AM])
		2'd1:	fnRd2 = {2'b00,ins[`RS1]};
		2'd2:	fnRd2 = {2'b00,ins[`RS1]};
		2'd3:
			case(ins[`AMX])
			2'd1:	fnRd2 = {2'b00,ins[`RS1]};
			2'd2:	fnRd2 = {2'b00,ins[`RS1]};
			default:	fnRd2 = 7'd0;
			endcase
		default:	fnRd2 = 7'd0;
		endcase
	endcase
default:	fnRd2 = 7'd0;
endcase
endfunction

function [6:0] fnRs1;
input [39:0] ins;
case(ins[`OPCODE])
`BRANCH:
	fnRs1 = {4'b1110,ins[10:8]};
`BMISC2:
	if (ins[`BFUNCT4]==`CRLOG)	// CRLOG
		fnRs1 = 7'b1111101;
	else
		fnRs1 = ins[`RS1];
default:
	fnRs1 = ins[`RS1];
endcase
endfunction

function [6:0] fnRs2;
input [39:0] ins;
case(ins[`OPCODE])
`JRL:	fnRs2 = {4'b1100,ins[20:18]};
`BMISC2:
	if (ins[`BFUNCT4]==`CRLOG)	// CRLOG
		fnRs2 = 7'b1111101;
	else
		fnRs2 = ins[`RS2];
default:
	fnRs2 = ins[`RS2];
endcase
endfunction

function [6:0] fnRs3;
input [39:0] ins;
fnRs3 = {2'b00,ins[`RS3]};
endfunction

function [6:0] fnRs4;
input [39:0] ins;
fnRs4 = {4'b1101,ins[`RS4]};
endfunction

assign Rs1[0] = fnRs1(insnx[0]);
assign Rs2[0] = fnRs2(insnx[0]);
assign Rs3[0] = fnRs3(insnx[0]);
assign Rs4[0] = fnRs4(insnx[0]);
assign Rd[0] = fnRd(insnx[0]);
assign Rd2[0] = fnRd2(insnx[0]);
assign Crd[0] = fnCrd(insnx[0]);
assign Rs1[1] = fnRs1(insnx[1]);
assign Rs2[1] = fnRs2(insnx[1]);
assign Rs3[1] = fnRs3(insnx[1]);
assign Rs4[1] = fnRs4(insnx[1]);
assign Rd[1] = fnRd(insnx[1]);
assign Rd2[1] = fnRd2(insnx[1]);
assign Crd[1] = fnCrd(insnx[1]);
assign Rs1[2] = fnRs1(insnx[2]);
assign Rs2[2] = fnRs2(insnx[2]);
assign Rs3[2] = fnRs3(insnx[2]);
assign Rs4[2] = fnRs4(insnx[2]);
assign Rd[2] = fnRd(insnx[2]);
assign Rd2[2] = fnRd2(insnx[2]);
assign Crd[2] = fnCrd(insnx[2]);
assign Rs1[3] = fnRs1(insnx[3]);
assign Rs2[3] = fnRs2(insnx[3]);
assign Rs3[3] = fnRs3(insnx[3]);
assign Rs4[3] = fnRs4(insnx[3]);
assign Rd[3] = fnRd(insnx[3]);
assign Rd2[3] = fnRd2(insnx[3]);
assign Crd[3] = fnCrd(insnx[3]);

// Detect if a source is automatically valid
function Source1Valid;
input [39:0] isn;
casez(isn[`OPCODE])
// BUnit:	
`BRK:	Source1Valid = isn[`RS1]==5'd0;
`BRANCH:	Source1Valid = FALSE;
`CHK:	Source1Valid = isn[`RS1]==5'd0;
`CHKI:	Source1Valid = isn[`RS1]==5'd0;
`JRL:	Source1Valid = isn[`RS1]==5'd0;
`RTS:	Source1Valid = isn[`RS1]==5'd0;
`JSR:		Source1Valid = TRUE;
`BMISC:
	case(isn[`BFUNCT4])
	`RTI:	Source1Valid = isn[`RS1]==5'd0;
	`SEI:	Source1Valid = isn[`RS1]==5'd0;
	`REX:	Source1Valid = isn[`RS1]==5'd0;
	default: Source1Valid = TRUE;
	endcase

//`IUnit:	Source1Valid = isn[`RS1]==6'd0;
8'h8?,8'h9?,8'hA,8'hB:
	Source1Valid = isn[`RS1]==5'd0;
//`FUnit:
`FLT1:
	case(isn[`FUNCT5])
	`FSYNC:		Source1Valid = TRUE;
	default:	Source1Valid = isn[`RS1]==6'd0;
	endcase
`FLT2:	Source1Valid = isn[`RS1]==6'd0;
`FLT2I:	Source1Valid = isn[`RS1]==6'd0;
`FMA:		Source1Valid = isn[`RS1]==6'd0;
`FMS:		Source1Valid = isn[`RS1]==6'd0;
`FNMA:	Source1Valid = isn[`RS1]==6'd0;
`FNMS:	Source1Valid = isn[`RS1]==6'd0;
//`MUnit:
8'b0???????:
	Source1Valid = isn[`RS1]==5'd0;
default:
	Source1Valid = TRUE;
endcase
endfunction
  
function Source2Valid;
input [39:0] isn;
// `BUnit:	
case(isn[`OPCODE])
`BRK:		Source2Valid = TRUE;
`BRANCH:	Source2Valid = TRUE;
`JRL:		Source2Valid = TRUE;
`RTS:		Source2Valid = isn[`RS2]==5'd0;
`JSR:		Source2Valid = TRUE;
`BMISC2:
	case(isn[`BFUNCT4])
	`RTI:	Source2Valid = TRUE;
	`REX:	Source2Valid = TRUE;
	default: Source2Valid = TRUE;
	endcase
//`IUnit:	
`CHKI:	Source2Valid = TRUE;
`CHK:		Source2Valid = isn[`RS2]==5'd0;
`R2:
	case(isn[`FUNCT6])
	`SHLI:	Source2Valid = TRUE;
	`ASLI:	Source2Valid = TRUE;
	`SHRI:	Source2Valid = TRUE;
	`ASRI:	Source2Valid = TRUE;
	`ROLI:	Source2Valid = TRUE;
	`RORI:	Source2Valid = TRUE;
	default:	Source2Valid = isn[`RS2]==6'd0;
	endcase
//`FUnit:
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
	default:	Source2Valid = isn[`RS2]==5'd0;
	endcase
`FLT2,`FLT2S:
						Source2Valid = isn[`RS2]==5'd0;
`FLT2I:			Source2Valid = TRUE;
`FMA,`FMS,`FNMA,`FNMS:
						Source2Valid = isn[`RS2]==5'd0;
//`MUnit:
`PUSHC:	Source2Valid = TRUE;
8'h2?,8'h3?,8'h6?,8'h7?:	// STORES
	Source2Valid = isn[`RS2]==6'd0;
default:	Source2Valid = TRUE;
endcase
endfunction

function Source3Valid;
input [39:0] isn;
//`BUnit:
case(isn[`OPCODE])
`CHK:		Source3Valid = isn[`RS3]==6'd0;
//`IUnit:
`R2:	Source3Valid = isn[`RS3]==6'd0;
`BITFIELD:	Source3Valid = isn[`RS3]==6'd0;
`CSRRW:	Source3Valid = TRUE;
//`FUnit:
`FLT1:	Source3Valid = TRUE;
`FLT2:	Source3Valid = TRUE;
`FLT2I:	Source3Valid = TRUE;
`FMA,`FMS,`FNMA,`FNMS:
				Source3Valid = isn[`RS3]==5'd0;
//`MUnit:	
8'b0???????:
	case(isn[`AM])
	2'd3:	Source3Valid = isn[`RS3]==5'd0;
	default:	Source3Valid = TRUE;
	endcase
default: Source3Valid = TRUE;
endcase
endfunction

function Source4Valid;
input [39:0] ins;
case(ins)
8'hF1,8'hF2,8'hF4,8'hF5,8'hF6,8'hF7:	// Misc vector instructions (vector mask is arg4)
	Source4Valid = FALSE;
default:	Source4Valid = TRUE;
endcase
endfunction

function SourceTValid;
input [39:0] ins;
SourceTValid = ins[`RD]==5'd0;
endfunction

function IsMem;
input [39:0] isn;
IsMem = !isn[7];
endfunction

function IsMemNdx;
input [39:0] isn;
if (!isn[7])
	IsMemNdx = isn[`AM]==2'b11;
else
	IsMemNdx = FALSE;
endfunction

function IsSWC;
input [39:0] isn;
IsSWC = isn[`OPCODE]==`STHC;
endfunction

function IsLea;
input [39:0] isn;
IsLea = isn[`OPCODE]==`LEA;
endfunction

function IsLWR;
input [39:0] isn;
IsLWR = isn[`OPCODE]==`LDHR;
endfunction

function IsCAS;
input [39:0] isn;
IsCAS = isn[`OPCODE]==`CAS;
endfunction

// Really IsPredictableBranch
// Does not include BccR's
function IsBranch;
input [39:0] isn;
case(isn[`OPCODE])
`BRANCH:	
	IsBranch = TRUE;
default:	IsBranch = FALSE;
endcase
endfunction

function IsWait;
input [39:0] isn;
IsWait = isn[`OPCODE]==`BMISC2 && isn[`BFUNCT4]==`WAIT;
endfunction

function IsJSR;
input [39:0] isn;
IsJSR = isn[`OPCODE]==`JSR;
endfunction

function IsJrl;
input [39:0] isn;
IsJrl = isn[`OPCODE]==`JRL;
endfunction

function IsFlowCtrl;
input [39:0] isn;
IsFlowCtrl = isn[7:5]==3'h6;
endfunction

function IsCache;
input [39:0] isn;
IsCache = isn[`OPCODE]==`CACHE;
endfunction

function [4:0] CacheCmd;
input [39:0] isn;
CacheCmd = isn[`RS2];
endfunction

function IsMemsb;
input [39:0] isn;
IsMemsb = isn[`OPCODE]==`BMISC2 && isn[`BFUNCT4]==`MEMSB; 
endfunction

function IsSEI;
input [40:0] isn;
IsSEI = isn[`OPCODE]==`BMISC && isn[`BFUNCT4]==`SEI; 
endfunction

function IsRet;
input [40:0] isn;
IsRet = isn[`OPCODE]==`RTS;
endfunction

function IsCheck;
input [40:0] isn;
IsCheck = isn[`OPCODE]==`CHKI || (isn[`OPCODE]==`R3 && isn[`AFUNCT6]==`CHK);
endfunction

function IsRFW;
input [40:0] isn;
if ((fnRd(isn)==7'd0 || fnRd(isn)==7'd32) && (fnRd2(isn)==7'd0 || fnRd2(isn)==7'd32))
    IsRFW = FALSE;
else
casez(isn[`OPCODE])
// BUnit:
`BMISC:	
	case(isn[`BFUNCT4])
	`SEI:	IsRFW = TRUE;
	`MTL:	IsRFW = TRUE;
	`MFL:	IsRFW = TRUE;
	default:	IsRFW = FALSE;
	endcase	
`JRL:     IsRFW = TRUE;
`JSR:     IsRFW = TRUE;  
`RTS:     IsRFW = TRUE; 
// IUnit
8'h8?,8'h9?,8'hA?,8'hB?:
	IsRFW = !IsCheck(isn);
// FUnit:
8'hE?:
	case(isn[`OPCODE])
	`FLT1:
		case(isn[`FFUNCT5])
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
// MUnit
`MEMORY:	// Memory
	casez(isn[`OPCODE])
	`LOAD:	IsRFW = TRUE;
	`TLB:		IsRFW = TRUE;
	`PUSH:	IsRFW = TRUE;
	`PUSHC:	IsRFW = TRUE;
	`CAS:		IsRFW = TRUE;
	default:
		if (isn[`AM]==2'b01 || isn[`AM]==2'b10 ||
			  (isn[`AM]==2'b11 && (isn[`AMX]==2'b01 || isn[`AMX]==2'b10)))
			IsRFW = TRUE;
		else
			IsRFW = FALSE;
	endcase
default: IsRFW = FALSE;
endcase
endfunction

function IsMul;
input [39:0] isn;
casez(isn[`OPCODE])
`MULI,`MULUI:	IsMul = TRUE;
`R2:
	case(isn[`FUNCT6])
	`MUL,`MULU,`MULH,`MULUH:
		IsMul = TRUE;
	default:	IsMul = FALSE;
	endcase
default:	IsMul = FALSE;
endcase
endfunction

function IsExec;
input [39:0] isn;
IsExec = (isn[`OPCODE]==`BMISC2 && isn[`BFUNCT4]==`EXEC);
endfunction

function IsPfi;
input [39:0] isn;
IsPfi = (isn[`OPCODE]==`BRK && isn[39:36]==`PFI);
endfunction

function IsBrk;
input [39:0] isn;
IsBrk = (isn[`OPCODE]==`BRK && isn[38:36]==3'd0);
endfunction

function IsRti;
input [39:0] isn;
IsRti = (isn[`OPCODE]==`BMISC2 && isn[`BFUNCT4]==`RTI);
endfunction

function IsDivmod;
input [39:0] isn;
casez(isn[`OPCODE])
`DIVI,`DIVUI,`MODI,`MODUI:	IsDivmod = TRUE;
`R2,`R2S:
	case(isn[`FUNCT5])
	`DIV,`DIVU,`MOD,`MODU:
		IsDivmod = TRUE;
	default:	IsDivmod = FALSE;
	endcase
default:	IsDivmod = FALSE;
endcase
endfunction

function [31:0] fnSelect;
input [39:0] isn;
casez(isn[`OPCODE])
`LDB:		fnSelect = 32'h0001;
`LDBU:	fnSelect = 32'h0001;
`LDW:		fnSelect = 32'h0003;
`LDWU:	fnSelect = 32'h0003;
`LDT:		fnSelect = 32'h000F;
`LDTU:	fnSelect = 32'h000F;
`LDP:		fnSelect = 32'h001F;
`LDPU:	fnSelect = 32'h001F;
`LDO:		fnSelect = 32'h00FF;
`LDOU:	fnSelect = 32'h00FF;
`LDH:		fnSelect = 32'hFFFF;
`LDHR:	fnSelect = 32'hFFFF;
`AMO:
	case(isn[`SZ3])
	3'd0:		fnSelect = 32'h0001;
	3'd1:		fnSelect = 32'h0003;
	3'd2:		fnSelect = 32'h000F;
	3'd3:		fnSelect = 32'h001F;
	3'd4:		fnSelect = 32'h00FF;
	3'd5:		fnSelect = 32'hFFFF;
	default:	fnSelect = 32'h000;
	endcase
`STB:	fnSelect = 32'h0001;
`STW:	fnSelect = 32'h0003;
`STT:	fnSelect = 32'h000F;
`STP:	fnSelect = 32'h001F;
`STO:	fnSelect = 32'h00FF;
`STH:	fnSelect = 32'hFFFF;
`STHC:	fnSelect = 32'hFFFF;
`CAS:	fnSelect = 32'hFFFF;
`PUSH:	fnSelect = 32'hFFFF;
`PUSHC:	fnSelect = 32'hFFFF;
default:	fnSelect = 32'h0000;
endcase
endfunction

function [127:0] fnDataExtend;
input [39:0] ins;
input [127:0] dat;
casez(ins[`OPCODE])
`LDB:	fnDataExtend = {{120{dat[7]}},dat[7:0]};
`LDBU:	fnDataExtend = {120'd0,dat[7:0]};
`LDW:	fnDataExtend = {{112{dat[15]}},dat[15:0]};
`LDWU:	fnDataExtend = {112'd0,dat[15:0]};
`LDT:	fnDataExtend = {{96{dat[31]}},dat[31:0]};
`LDTU:	fnDataExtend = {96'd0,dat[31:0]};
`LDP:	fnDataExtend = {{88{dat[39]}},dat[39:0]};
`LDPU:	fnDataExtend = {88'd0,dat[39:0]};
`LDO:	fnDataExtend = {{64{dat[63]}},dat[63:0]};
`LDOU:	fnDataExtend = {64'd0,dat[63:0]};
`LDH:	fnDataExtend = dat[127:0];
`LDHR:	fnDataExtend = dat[127:0];
`POP:		fnDataExtend = dat[127:0];
	// ToDo: add CAS
default:    fnDataExtend = dat[127:0];
endcase
endfunction

function [127:0] fnDatiAlign;
input [`ABITS] adr;
input [247:0] dat;
reg [247:0] adat;
begin
adat = dat >> {adr[3:0],3'b0};
fnDatiAlign = adat[127:0];
end
endfunction

function IsTLB;
input [39:0] isn;
case(isn[`OPCODE])
`TLB:	IsTLB = TRUE;
default:	IsTLB = FALSE;
endcase
endfunction

// Indicate if the ALU instruction is valid immediately (single cycle operation)
function IsSingleCycle;
input [39:0] isn;
IsSingleCycle = !(IsMul(isn)|IsDivmod(isn)|IsTLB(isn));
endfunction

generate begin : gDecoderInst
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
// If commiting two results on a single head, increment by one, not two.
//wire cmt_head2 = (!iq_rfw[heads[2]] && rob_tgt2[rob_heads[0]][5:0]==6'd0 && !iq_oddball[heads[2]] && ~|iq_exc[heads[2]]);
//wire cmt_head2r = (!iq_rfw[rob_heads[2]] && rob_tgt2[rob_heads[0]][5:0]==6'd0 && !iq_oddball[rob_heads[2]] && ~|iq_exc[rob_heads[2]]);
//wire cmt_tgt2 = rob_tgt2[rob_heads[0]][5:0]!=6'd0;
//wire cmt_tgt21 = rob_tgt2[rob_heads[1]][5:0]!=6'd0;

// Determine the head increment amount, this must match code later on.
always @*
begin
	hi_amt <= 3'd0;
	if (iq_v[heads[0]] && iq_state[heads[0]]==IQS_CMT) begin
		hi_amt <= 3'd1;
		if (iq_v[heads[1]] && iq_state[heads[1]]==IQS_CMT) begin
			hi_amt <= 3'd2;
			if (iq_v[heads[2]] && iq_state[heads[2]]==IQS_CMT) begin
				hi_amt <= 3'd3;
				if (iq_v[heads[3]] && iq_state[heads[3]]==IQS_CMT)
					hi_amt <= 3'd4;
			end
		end
	end
	else if (!iq_v[heads[0]]) begin
		if (heads[0] != tails[0]) begin
			hi_amt <= 3'd1;
			if (iq_v[heads[1]] && iq_state[heads[1]]==IQS_CMT) begin
				hi_amt <= 3'd2;
				if (iq_v[heads[2]] && iq_state[heads[2]]==IQS_CMT) begin
					hi_amt <= 3'd3;
					if (iq_v[heads[3]] && iq_state[heads[3]]==IQS_CMT)
						hi_amt <= 3'd4;
				end
			end
			else if (!iq_v[heads[1]]) begin
				if (heads[1] != tails[0]) begin
					hi_amt <= 3'd2;
					if (iq_v[heads[2]] && iq_state[heads[2]]==IQS_CMT) begin
						hi_amt <= 3'd3;
						if (iq_v[heads[3]] && iq_state[heads[3]]==IQS_CMT)
							hi_amt <= 3'd4;
					end
					else if (!iq_v[heads[2]]) begin
						if (heads[2] != tails[0]) begin
							hi_amt <= 3'd3;
							if (iq_v[heads[3]] && iq_state[heads[3]]==IQS_CMT)
								hi_amt <= 3'd4;
							else begin
								if (!iq_v[heads[3]]) begin
									if (heads[3] != tails[3])
										hi_amt <= 3'd4;
								end
							end
						end
						else if (!iq_v[heads[3]]) begin
							if (heads[3] != tails[3])
								hi_amt <= 3'd4;
						end
					end
				end
			end
		end
	end
end

//
// BRANCH-MISS LOGIC: livetarget
//
// livetarget implies that there is a not-to-be-stomped instruction that targets the register in question
// therefore, if it is zero it implies the rf_v value should become VALID on a branchmiss
// 

always @*
	for (n = 0; n < QENTRIES; n = n + 1)
		iq_livetarget[n] = {AREGS {iq_v[n]}} & {AREGS {~iq_stomp[n]}} & iq_out2[n];
always @*
	for (n = 0; n < QENTRIES; n = n + 1)
		iq_livetarget2[n] = {AREGS {iq_v[n]}} & {AREGS {~iq_stomp[n]}} & iq_out2a[n];


always @*
for (j = 1; j < AREGS; j = j + 1) begin
	livetarget[j] = 1'b0;
	for (n = 0; n < QENTRIES; n = n + 1)
		livetarget[j] = livetarget[j] | iq_livetarget[n][j];
end

always @*
for (j = 1; j < AREGS; j = j + 1) begin
	livetarget2[j] = 1'b0;
	for (n = 0; n < QENTRIES; n = n + 1)
		livetarget2[j] = livetarget2[j] | iq_livetarget2[n][j];
end

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
	for (n = 0; n < QENTRIES; n = n + 1) begin
		iq_cumulative2[n] = 1'b0;
		for (j = n; j < n + QENTRIES; j = j + 1) begin
			if (missid==(j % QENTRIES))
				for (k = n; k <= j; k = k + 1)
					iq_cumulative2[n] = iq_cumulative2[n] | iq_livetarget2[k % QENTRIES];
		end
	end

always @*
	for (n = 0; n < QENTRIES; n = n + 1)
    iq_latestID[n] = (missid == n || ((iq_livetarget[n] & iq_cumulative[(n+1)%QENTRIES]) == {AREGS{1'b0}}))
				    ? iq_livetarget[n]
				    : {AREGS{1'b0}};

always @*
	for (n = 0; n < QENTRIES; n = n + 1)
    iq_latestID2[n] = (missid == n || ((iq_livetarget2[n] & iq_cumulative2[(n+1)%QENTRIES]) == {AREGS{1'b0}}))
				    ? iq_livetarget2[n]
				    : {AREGS{1'b0}};

always @*
	for (n = 0; n < QENTRIES; n = n + 1)
	  iq_source[n] = | iq_latestID[n];

always @*
	for (n = 0; n < QENTRIES; n = n + 1)
	  iq_source2[n] = | iq_latestID2[n];


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
        || (iq_argA_s[g][`RBITS] == alu0_rid && alu0_vsn)
        || ((iq_argA_s[g][`RBITS] == alu1_rid && alu1_vsn) && (`NUM_ALU > 1))
        || ((iq_argA_s[g][`RBITS] == fpu1_rid && fpu1_dataready) && (`NUM_FPU > 0))
        || ((iq_argA_s[g][`RBITS] == fpu2_rid && fpu2_dataready) && (`NUM_FPU > 1))
`endif
        )
    && (iq_argB_v[g] || iq_mem[g]	// a2 does not need to be valid immediately for a mem op (agen), it is checked by iq_memready logic
`ifdef FU_BYPASS
        || (iq_argB_s[g][`RBITS] == alu0_rid && alu0_vsn)
        || ((iq_argB_s[g][`RBITS] == alu1_rid && alu1_vsn) && (`NUM_ALU > 1))
        || ((iq_argB_s[g][`RBITS] == fpu1_rid && fpu1_dataready) && (`NUM_FPU > 0))
        || ((iq_argB_s[g][`RBITS] == fpu2_rid && fpu2_dataready) && (`NUM_FPU > 1))
`endif
        )
    && (iq_argC_v[g] 
        || (iq_mem[g] & ~iq_agen[g] & ~iq_memndx[g])    // a3 needs to be valid for indexed instruction
//        || (iq_mem[g] & ~iq_agen[g])
`ifdef FU_BYPASS
        || (iq_argC_s[g][`RBITS] == alu0_rid && alu0_vsn)
        || ((iq_argC_s[g][`RBITS] == alu1_rid && alu1_vsn) && (`NUM_ALU > 1))
        || ((iq_argC_s[g][`RBITS] == fpu1_rid && fpu1_dataready) && (`NUM_FPU > 0))
        || ((iq_argC_s[g][`RBITS] == fpu2_rid && fpu2_dataready) && (`NUM_FPU > 1))
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
issuing_on_alu0 = FALSE;
for (n = 0; n < QENTRIES; n = n + 1)
	if (iq_alu0_issue[n] && !(iq_v[n] && iq_stomp[n])
												&& (alu0_available & alu0_done))
		issuing_on_alu0 = TRUE;
end

always @*
begin
issuing_on_alu1 = FALSE;
for (n = 0; n < QENTRIES; n = n + 1)
	if (iq_alu1_issue[n] && !(iq_v[n] && iq_stomp[n])
												&& (alu1_available & alu1_done))
		issuing_on_alu1 = TRUE;
end

reg issuing_on_agen0;
always @*
begin
issuing_on_agen0 = FALSE;
for (n = 0; n < QENTRIES; n = n + 1)
	if (iq_agen0_issue[n] && !(iq_v[n] && iq_stomp[n]))
		issuing_on_agen0 = TRUE;
end

reg issuing_on_agen1;
always @*
begin
issuing_on_agen1 = FALSE;
for (n = 0; n < QENTRIES; n = n + 1)
	if (iq_agen1_issue[n] && !(iq_v[n] && iq_stomp[n]))
		issuing_on_agen1 = TRUE;
end

reg issuing_on_fpu1;
always @*
begin
issuing_on_fpu1 = FALSE;
for (n = 0; n < QENTRIES; n = n + 1)
	if (iq_fpu1_issue[n] && !(iq_v[n] && iq_stomp[n])
												&& (fpu1_available & fpu1_done))
		issuing_on_fpu1 = TRUE;
end

reg issuing_on_fpu2;
always @*
begin
issuing_on_fpu2 = FALSE;
for (n = 0; n < QENTRIES; n = n + 1)
	if (iq_fpu2_issue[n] && !(iq_v[n] && iq_stomp[n])
												&& (fpu2_available & fpu2_done))
		issuing_on_fpu2 = TRUE;
end

reg issuing_on_fcu;
always @*
begin
issuing_on_fcu = FALSE;
for (n = 0; n < QENTRIES; n = n + 1)
	if (iq_fcu_issue[n] && !(iq_v[n] && iq_stomp[n]) && fcu_done)
		issuing_on_fcu = TRUE;
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

always @*
begin
	for (n = 0; n < RENTRIES; n = n + 1)
		rob_v[n] = rob_state[n] != RS_INVALID;
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
	.iq_sel(iq_sel),
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

/*
always @*
begin
	iq_stomp <= 1'b0;
	if (branchmiss) begin
		j = missid;
		k = (missid + 1) % QENTRIES;
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (iq_v[k]) begin
				if (iq_br_tag[k]==br_tag[j]) begin
					iq_stomp[k] = `TRUE;
					if (is_qbranch[k])
						j = k;
				end
			end
			k = (k + 1) % QENTRIES;
		end
	end
end
*/
always @*
begin
	iq_stomp = 1'b0;
	if (branchmiss) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (iq_sn[n] > iq_sn[missid])
				iq_stomp[n] = TRUE;
		end
	end
end

always @*
begin
	stompedOnRets = 1'b0;
	for (n = 0; n < QENTRIES; n = n + 1)
		if (iq_stomp[n] && iq_rts[n])
			stompedOnRets = stompedOnRets + 4'd1;
end

//wire [143:0] id_bus[0], id_bus[1], id_bus[2];

generate begin : idecoders
for (g = 0; g < QSLOTS; g = g + 1)
begin
idecoder uid1
(
	.instr(insnx[g]),
	.Rt(Rd[g][4:0]),
	.Rd2(Rd2[g][4:0]),
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
  .fmt(alu0_fmt),
  .store(alu0_store),
  .a(alu0_argA),
  .b(alu0_argB),
  .c(alu0_argC),
 	.t(alu0_argT),
  .m(alu0_argD),
  .z(alu0_z),
  .pc(alu0_ip),
//    .imm(alu0_argI),
  .tgt(alu0_tgt),
  .csr(csr_r),
  .o(alu0_out),
  .ob(alu0_bus2),
  .cro(alu0_cro),
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
  .fmt(alu1_fmt),
  .store(alu1_store),
  .a(alu1_argA),
  .b(alu1_argB),
  .c(alu1_argC),
 	.t(alu1_argT),
  .m(alu1_argD),
  .z(alu1_z),
  .pc(alu1_ip),
  //.imm(alu1_argI),
  .tgt(alu1_tgt),
  .csr(64'd0),
  .o(alu1_out),
  .ob(alu1_bus2),
  .cro(alu1_cro),
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

reg [AMSB:0] bse0, bse1;
always @*
if (dl==2'd0)
	bse0 <= 1'd0;
else
	case(agen0_base)
	2'd0:	bse0 <= program_base;
	2'd1: bse0 <= data_base;
	2'd2: bse0 <= io_base;
	2'd3: bse0 <= extra_base;
	endcase
always @*
if (dl==2'd0)
	bse1 <= 1'd0;
else
	case(agen1_base)
	2'd0:	bse1 <= program_base;
	2'd1: bse1 <= data_base;
	2'd2: bse1 <= io_base;
	2'd3: bse1 <= extra_base;
	endcase

agen uag1
(
	.inst(agen0_instr),
	.a(agen0_argA),
	.b(agen0_argB),
	.c(agen0_argC),
	.i(agen0_argI),
	.base(bse0),
	.offset(agen0_offset),
	.ma(agen0_ma),
	.idle(agen0_idle)
);

agen uag2
(
	.inst(agen1_instr),
	.a(agen1_argA),
	.b(agen1_argB),
	.c(agen1_argC),
	.i(agen1_argI),
	.base(bse1),
	.offset(128'd0),
	.ma(agen1_ma),
	.idle(agen1_idle)
);

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
	.stb_i(stb),
	.we_i(we),
	.vadr_i(vadr),
	.cyc_o(cyc_o),
	.stb_o(stb_o),
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
assign stb_o = stb;
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
wire [1:0] fpu128a_done;
wire [3:0] fpu64a_done;
wire [7:0] fpu32a_done;
wire [255:0] fpu1_out128, fpu1_out64, fpu1_out32;
wire [255:0] fpu1_status128,fpu1_status64,fpu1_status32;

for (g = 0; g < 2; g = g + 1)
fpUnit #(128) ufp1_128a
(
  .rst(rst_i),
  .clk(fpu1_clk),
  .clk4x(clk4x_i),
  .ce(1'b1),
  .ir(fpu1_instr),
  .ld(fpu1_ld),
  .a(fpu1_argA[g*128+:128]),
  .b(fpu1_argB[g*128+:128]),
  .c(fpu1_argC[g*128+:128]),
  .imm(fpu1_argI),
  .o(fpu1_out128[g*128+:128]),
  .csr_i(),
  .status(fpu1_status128[g*32+:32]),
  .exception(),
  .done(fpu128a_done[g])
);

for (g = 0; g < 4; g = g + 1)
fpUnit #(64) ufp1_64a
(
  .rst(rst_i),
  .clk(fpu1_clk),
  .clk4x(clk4x_i),
  .ce(1'b1),
  .ir(fpu1_instr),
  .ld(fpu1_ld),
  .a(fpu1_argA[g*64+:64]),
  .b(fpu1_argB[g*64+:64]),
  .c(fpu1_argC[g*64+:64]),
  .imm(fpu1_argI),
  .o(fpu1_out64[g*64+:64]),
  .csr_i(),
  .status(fpu1_status64[g*32+:32]),
  .exception(),
  .done(fpu64a_done[g])
);

for (g = 0; g < 8; g = g + 1)
fpUnit #(32) ufp1_32a
(
  .rst(rst_i),
  .clk(fpu1_clk),
  .clk4x(clk4x_i),
  .ce(1'b1),
  .ir(fpu1_instr),
  .ld(fpu1_ld),
  .a(fpu1_argA[g*32+:32]),
  .b(fpu1_argB[g*32+:32]),
  .c(fpu1_argC[g*32+:32]),
  .imm(fpu1_argI),
  .o(fpu1_out32[g*32+:32]),
  .csr_i(),
  .status(fpu1_status32[g*32+:32]),
  .exception(),
  .done(fpu32a_done[g])
);

always @*
if (fpu1_vset) begin
case(fpu1_fmt)
fp32_para:	fpu1_out = {
												fpu1_argD[7] ? fpu1_out128[224] : fpu1_z ? 1'b0 : fpu1_argT[7],
												fpu1_argD[6] ? fpu1_out128[192] : fpu1_z ? 1'b0 : fpu1_argT[6],
												fpu1_argD[5] ? fpu1_out128[160] : fpu1_z ? 1'b0 : fpu1_argT[5],
												fpu1_argD[4] ? fpu1_out128[128] : fpu1_z ? 1'b0 : fpu1_argT[4],
												fpu1_argD[3] ? fpu1_out128[ 96] : fpu1_z ? 1'b0 : fpu1_argT[3],
												fpu1_argD[2] ? fpu1_out128[ 64] : fpu1_z ? 1'b0 : fpu1_argT[2],
												fpu1_argD[1] ? fpu1_out128[ 32] : fpu1_z ? 1'b0 : fpu1_argT[1],
											  fpu1_argD[0] ? fpu1_out128[  0] : fpu1_z ? 1'b0 : fpu1_argT[0]
											 };
fp64_para:	fpu1_out = {
												fpu1_argD[3] ? fpu1_out128[192] : fpu1_z ? 1'b0 : fpu1_argT[3],
												fpu1_argD[2] ? fpu1_out128[128] : fpu1_z ? 1'b0 : fpu1_argT[2],
												fpu1_argD[1] ? fpu1_out128[ 64] : fpu1_z ? 1'b0 : fpu1_argT[1],
											  fpu1_argD[0] ? fpu1_out128[  0] : fpu1_z ? 1'b0 : fpu1_argT[0]
											 };
fp128_para:	fpu1_out = {fpu1_argD[1] ? fpu1_out128[128] : fpu1_z ? 1'b0 : fpu1_argT[1],
											  fpu1_argD[0] ? fpu1_out128[  0] : fpu1_z ? 1'b0 : fpu1_argT[0]
											 };
default:	fpu1_out = 256'd0;
endcase
end
else
case(fpu1_fmt)
fp32:	fpu1_out = {224'd0,fpu1_out32[31:0]};
fp64:	fpu1_out = {192'd0,fpu1_out64[63:0]};
fp128:	fpu1_out = {128'd0,fpu1_out128[127:0]};
fp32_para:	fpu1_out = {fpu1_argD[7] ? fpu1_out32[255:224] : fpu1_z ? 32'd0 : fpu1_argT[255:224],
												fpu1_argD[6] ? fpu1_out32[223:192] : fpu1_z ? 32'd0 : fpu1_argT[223:192],
												fpu1_argD[5] ? fpu1_out32[191:160] : fpu1_z ? 32'd0 : fpu1_argT[191:160],
												fpu1_argD[4] ? fpu1_out32[159:128] : fpu1_z ? 32'd0 : fpu1_argT[159:128],
												fpu1_argD[3] ? fpu1_out32[127:96] : fpu1_z ? 32'd0 : fpu1_argT[127:96],
												fpu1_argD[2] ? fpu1_out32[95:64] : fpu1_z ? 32'd0 : fpu1_argT[95:64],
												fpu1_argD[1] ? fpu1_out32[63:32] : fpu1_z ? 32'd0 : fpu1_argT[63:32],
												fpu1_argD[0] ? fpu1_out32[31:0] : fpu1_z ? 32'd0 : fpu1_argT[31:0]};
fp64_para:	fpu1_out = {fpu1_argD[3] ? fpu1_out64[255:192] : fpu1_z ? 64'd0 : fpu1_argT[255:192],
												fpu1_argD[2] ? fpu1_out64[191:128] : fpu1_z ? 64'd0 : fpu1_argT[191:128],
												fpu1_argD[1] ? fpu1_out64[127:64] : fpu1_z ? 64'd0 : fpu1_argT[127:64],
												fpu1_argD[0] ? fpu1_out64[63:0] : fpu1_z ? 64'd0 : fpu1_argT[63:0]};
fp128_para:	fpu1_out = {fpu1_argD[1] ? fpu1_out128[255:128] : fpu1_z ? 128'd0 : fpu1_argT[255:128],
												fpu1_argD[0] ? fpu1_out128[127:0] : fpu1_z ? 128'd0 : fpu1_argT[127:0]};
default:	fpu1_out = 256'd0;
endcase

always @*
case(fpu1_fmt)
fp32:	fpu1_status = fpu1_status32[31:0];
fp64:	fpu1_status = fpu1_status64[31:0];
fp128:	fpu1_status = fpu1_status128[31:0];
fp32_para:	fpu1_status = fpu1_status32;
fp64_para:	fpu1_status = fpu1_status64;
fp128_para:	fpu1_status = fpu1_status128;
default:	fpu1_status = 256'd0;
endcase

always @*
case(fpu1_fmt)
fp32,fp32_para:	fpu1_done = &fpu32a_done;
fp64,fp64_para:	fpu1_done = &fpu64a_done;
default:	fpu1_done = &fpu128a_done;
endcase

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
wire [1:0] fpu128b_done;
wire [3:0] fpu64b_done;
wire [7:0] fpu32b_done;
wire [255:0] fpu2_out128, fpu2_out64, fpu2_out32;
wire [255:0] fpu2_status128,fpu2_status64,fpu2_status32;

for (g = 0; g < 2; g = g + 1)
fpUnit #(128) ufp1_128b
(
  .rst(rst_i),
  .clk(fpu2_clk),
  .clk4x(clk4x_i),
  .ce(1'b1),
  .ir(fpu2_instr),
  .ld(fpu2_ld),
  .a(fpu2_argA[g*128+:128]),
  .b(fpu2_argB[g*128+:128]),
  .c(fpu2_argC[g*128+:128]),
  .imm(fpu2_argI),
  .o(fpu2_out128[g*128+:128]),
  .csr_i(),
  .status(fpu2_status128[g*32+:32]),
  .exception(),
  .done(fpu128b_done[g])
);

for (g = 0; g < 4; g = g + 1)
fpUnit #(64) ufp1_64b
(
  .rst(rst_i),
  .clk(fpu2_clk),
  .clk4x(clk4x_i),
  .ce(1'b1),
  .ir(fpu2_instr),
  .ld(fpu2_ld),
  .a(fpu2_argA[g*64+:64]),
  .b(fpu2_argB[g*64+:64]),
  .c(fpu2_argC[g*64+:64]),
  .imm(fpu2_argI),
  .o(fpu2_out64[g*64+:64]),
  .csr_i(),
  .status(fpu2_status64[g*32+:32]),
  .exception(),
  .done(fpu64b_done[g])
);

for (g = 0; g < 8; g = g + 1)
fpUnit #(32) ufp1_32b
(
  .rst(rst_i),
  .clk(fpu1_clk),
  .clk4x(clk4x_i),
  .ce(1'b1),
  .ir(fpu2_instr),
  .ld(fpu2_ld),
  .a(fpu2_argA[g*32+:32]),
  .b(fpu2_argB[g*32+:32]),
  .c(fpu2_argC[g*32+:32]),
  .imm(fpu2_argI),
  .o(fpu2_out64[g*32+:32]),
  .csr_i(),
  .status(fpu2_status32[g*32+:32]),
  .exception(),
  .done(fpu32b_done[g])
);

always @*
if (fpu2_vset) begin
case(fpu2_fmt)
fp32_para:	fpu2_out = {
												fpu2_argD[7] ? fpu2_out128[224] : fpu2_z ? 1'b0 : fpu2_argT[7],
												fpu2_argD[6] ? fpu2_out128[192] : fpu2_z ? 1'b0 : fpu2_argT[6],
												fpu2_argD[5] ? fpu2_out128[160] : fpu2_z ? 1'b0 : fpu2_argT[5],
												fpu2_argD[4] ? fpu2_out128[128] : fpu2_z ? 1'b0 : fpu2_argT[4],
												fpu2_argD[3] ? fpu2_out128[ 96] : fpu2_z ? 1'b0 : fpu2_argT[3],
												fpu2_argD[2] ? fpu2_out128[ 64] : fpu2_z ? 1'b0 : fpu2_argT[2],
												fpu2_argD[1] ? fpu2_out128[ 32] : fpu2_z ? 1'b0 : fpu2_argT[1],
											  fpu2_argD[0] ? fpu2_out128[  0] : fpu2_z ? 1'b0 : fpu2_argT[0]
											 };
fp64_para:	fpu2_out = {
												fpu2_argD[3] ? fpu2_out128[192] : fpu2_z ? 1'b0 : fpu2_argT[3],
												fpu2_argD[2] ? fpu2_out128[128] : fpu2_z ? 1'b0 : fpu2_argT[2],
												fpu2_argD[1] ? fpu2_out128[ 64] : fpu2_z ? 1'b0 : fpu2_argT[1],
											  fpu2_argD[0] ? fpu2_out128[  0] : fpu2_z ? 1'b0 : fpu2_argT[0]
											 };
fp128_para:	fpu2_out = {fpu2_argD[1] ? fpu2_out128[128] : fpu2_z ? 1'b0 : fpu2_argT[1],
											  fpu2_argD[0] ? fpu2_out128[  0] : fpu2_z ? 1'b0 : fpu2_argT[0]
											 };
default:	fpu2_out = 256'd0;
endcase
end
else
case(fpu2_fmt)
fp32:	fpu2_out = {224'd0,fpu2_out32[31:0]};
fp64:	fpu2_out = {192'd0,fpu2_out64[63:0]};
fp128:	fpu2_out = {128'd0,fpu2_out128[127:0]};
fp32_para:	fpu2_out = {fpu2_argD[7] ? fpu2_out32[255:224] : fpu2_z ? 32'd0 : fpu2_argT[255:224],
												fpu2_argD[6] ? fpu2_out32[223:192] : fpu2_z ? 32'd0 : fpu2_argT[223:192],
												fpu2_argD[5] ? fpu2_out32[191:160] : fpu2_z ? 32'd0 : fpu2_argT[191:160],
												fpu2_argD[4] ? fpu2_out32[159:128] : fpu2_z ? 32'd0 : fpu2_argT[159:128],
												fpu2_argD[3] ? fpu2_out32[127:96] : fpu2_z ? 32'd0 : fpu2_argT[127:96],
												fpu2_argD[2] ? fpu2_out32[95:64] : fpu2_z ? 32'd0 : fpu2_argT[95:64],
												fpu2_argD[1] ? fpu2_out32[63:32] : fpu2_z ? 32'd0 : fpu2_argT[63:32],
												fpu2_argD[0] ? fpu2_out32[31:0] : fpu2_z ? 32'd0 : fpu2_argT[31:0]};
fp64_para:	fpu2_out = {fpu2_argD[3] ? fpu2_out64[255:192] : fpu2_z ? 64'd0 : fpu2_argT[255:192],
												fpu2_argD[2] ? fpu2_out64[191:128] : fpu2_z ? 64'd0 : fpu2_argT[191:128],
												fpu2_argD[1] ? fpu2_out64[127:64] : fpu2_z ? 64'd0 : fpu2_argT[127:64],
												fpu2_argD[0] ? fpu2_out64[63:0] : fpu2_z ? 64'd0 : fpu2_argT[63:0]};
fp128_para:	fpu2_out = {fpu2_argD[1] ? fpu2_out128[255:128] : fpu2_z ? 128'd0 : fpu2_argT[255:128],
												fpu2_argD[0] ? fpu2_out128[127:0] : fpu2_z ? 128'd0 : fpu2_argT[127:0]};
default:	fpu2_out = 256'd0;
endcase

always @*
case(fpu2_fmt)
fp32:	fpu2_status = fpu2_status32[31:0];
fp64:	fpu2_status = fpu2_status64[31:0];
fp128:	fpu2_status = fpu2_status128[31:0];
fp32_para:	fpu2_status = fpu2_status32;
fp64_para:	fpu2_status = fpu2_status64;
fp128_para:	fpu2_status = fpu2_status128;
default:	fpu2_status = 256'd0;
endcase


always @*
case(fpu2_fmt)
fp32,fp32_para:	fpu2_done = &fpu32b_done;
fp64,fp64_para:	fpu2_done = &fpu64b_done;
default:	fpu2_done = &fpu128b_done;
endcase

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
fp_cmp_unit #(84) ufcmp1 (fcu_argA, fcu_argB, fcmpo, fnanx);

wire fcu_takb;

always @*
begin
    fcu_exc <= `FLT_NONE;
    casez(fcu_instr[`OPCODE])
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
	.cr(fcu_cr),
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
															(slotv[0] && slot0ip==missip)
															|| (slotv[1] && slot1ip==missip)
															|| (slotv[2] && slot2ip==missip)
															|| (slotv[3] && slot3ip==missip)
															);

always @*
begin
case(fcu_instr[`OPCODE])
`BMISC:	fcu_missip = fcu_ipc;		// RTI (we don't bother fully decoding this as it's the only R2)
`RTS:	fcu_missip = fcu_argB;
`REX:	fcu_missip = fcu_bus;
`BRK:	fcu_missip = {tvec[0][AMSB:8], 1'b0, olm, 5'h0};
`JRL:	fcu_missip = fcu_argA + fcu_argI;
//`JMP,`CALL:	fcu_missip = {fcu_ip[AMSB:38],fcu_instr[39:10],fcu_instr[5:0],fcu_instr[1:0]};
//`CHK:	fcu_missip = fcu_nextip + fcu_argI;	// Handled as an instruction exception
// Default: branch
default:	fcu_missip = fcu_pt ? fcu_nextip : {fcu_ip[AMSB:27],fcu_brdisp[26:0]};
endcase
fcu_missip[0] = 1'b0;
end

// To avoid false branch mispredicts the branch isn't evaluated until the
// following instruction queues. The address of the next instruction is
// looked at to see if the BTB predicted correctly.

wire fcu_brk_miss = fcu_brk || fcu_rti;
`ifdef FCU_ENH
wire fcu_rts_miss = fcu_rts && (fcu_argB != iq_ip[nid]);
wire fcu_jal_miss = fcu_jal && (fcu_argA + fcu_argI != iq_ip[nid]);
wire fcu_followed = iq_sn[nid] > iq_sn[fcu_id];
`else
wire fcu_rts_miss = fcu_rts;
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
		|| (fcu_rts && (fcu_argB == iq_ip[nid]))
		|| (fcu_jal && (fcu_argA + fcu_argI == iq_ip[nid]))
		 ;
	if (fcu_brk_miss)
		fcu_branchmiss = TRUE;
	else if (fcu_branch && (fcu_takb ^ fcu_pt))
    fcu_branchmiss = TRUE;
	else
		if (fcu_rex && (im < ~ol))
		fcu_branchmiss = TRUE;
	else if (fcu_rts_miss)
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
	case(ip[1:0])
	2'b00:	ip_mask = 4'b1111;
	2'b01:	ip_mask = 4'b1110;
	2'b10:	ip_mask = 4'b1100;
	2'b11:	ip_mask = 4'b1000;
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
	// The first commit bus is always tied to the same place
  commit0_v <= (rob_state[rob_heads[0][`RBITS]] == RS_CMT && ~|panic);
  commit0_id <= rob_heads[0][`RBITS];	// if a memory op, it has a DRAM-bus id
  commit0_tgt <= rob_tgt[rob_heads[0][`RBITS]];
  commit0_bus <= rob_res[rob_heads[0][`RBITS]];
  commit0_crtgt <= rob_crtgt[rob_heads[0][`RBITS]];
  commit0_crbus <= rob_crres[rob_heads[0][`RBITS]];
  commit0_rid <= rob_heads[0];

  commit1_v <= (rob_state[rob_heads[0][`RBITS]] == RS_CMT
             && rob_state[rob_heads[1][`RBITS]] == RS_CMT
             && ~|panic);
	commit1_id <= rob_heads[1][`RBITS];
	commit1_tgt <= rob_tgt[rob_heads[1][`RBITS]];
	commit1_bus <= rob_res[rob_heads[1][`RBITS]];
  commit1_crtgt <= rob_crtgt[rob_heads[1][`RBITS]];
  commit1_crbus <= rob_crres[rob_heads[1][`RBITS]];
  commit1_rid <= rob_heads[1];

  commit2_v <= (rob_state[rob_heads[0][`RBITS]] == RS_CMT
             && rob_state[rob_heads[1][`RBITS]] == RS_CMT
             && rob_state[rob_heads[2][`RBITS]] == RS_CMT
             && ~|panic);
  commit2_id <= rob_heads[2];
  commit2_tgt <= rob_tgt[rob_heads[2][`RBITS]];  
  commit2_bus <= rob_res[rob_heads[2][`RBITS]];
  commit2_crtgt <= rob_crtgt[rob_heads[2][`RBITS]];
  commit2_crbus <= rob_crres[rob_heads[2][`RBITS]];
  commit2_rid <= rob_heads[2];
	
  commit3_v <= (rob_state[rob_heads[0][`RBITS]] == RS_CMT
		         && rob_state[rob_heads[1][`RBITS]] == RS_CMT
    		     && rob_state[rob_heads[2][`RBITS]] == RS_CMT
        		 && rob_state[rob_heads[3][`RBITS]] == RS_CMT
         		&& ~|panic);
  commit3_id <= rob_heads[3][`RBITS];
  commit3_tgt <= rob_tgt[rob_heads[3][`RBITS]];  
  commit3_bus <= rob_res[rob_heads[3][`RBITS]];
  commit3_crtgt <= rob_crtgt[rob_heads[3][`RBITS]];
  commit3_crbus <= rob_crres[rob_heads[3][`RBITS]];
  commit3_rid <= rob_heads[3];
end

assign int_commit = (commit0_v && iq_irq[heads[0]])
									 || (commit0_v && commit1_v && iq_irq[heads[1]])
									 || (commit0_v && commit1_v && commit2_v && iq_irq[heads[2]])
									 || (commit0_v && commit1_v && commit2_v && commit3_v && iq_irq[heads[3]])
									 ;

// Wait until the cycle after Rs1 becomes valid to give time to read
// the vector element from the register file.
reg rf_vra0, rf_vra1, rf_vra2;
/*always @(posedge clk)
    rf_vra0 <= regIsValid[Ra0s];
always @(posedge clk)
    rf_vra1 <= regIsValid[Ra1s];
*/

// Check how many instructions can be queued. An instruction can queue only if
// there are entries available in both the dispatch and re-order buffer. This
// quarentees the re-order buffer id is available during queue. The instruction
// can't execute until there is a place to put the result.
// The break bit in the instruction template must also be clear in order for an
// instruction to queue.
getQueuedCount ugqc1
(
	.branchmiss(branchmiss),
	.brk(brkbits),
	.phitd(phitd),
	.tails(tails),
	.rob_tails(rob_tails),
	.slotvd(slotvd),
	.slot_jc(slot_jc),
	.slot_ret(slot_ret),
	.take_branch(take_branch),
	.iq_v(iq_v),
	.rob_v(rob_v),
	.queuedCnt(queuedCnt),
	.queuedOnp(queuedOnp),
	.debug_on(debug_on)
);

getRQueuedCount ugrqct1
(
	.rst(rst_i),
	.rob_tails(rob_tails),
	.rob_v_i(rob_v),
	.rob_v_o(next_rob_v),
	.heads(heads),
	.iq_state(iq_state),
	.iq_rid_i(iq_rid),
	.iq_rid_o(next_iq_rid),
	.rqueuedCnt(rqueuedCnt),
	.rqueuedOn(rqueuedOn)
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
wire fpu1_done_pe, fpu2_done_pe;
edge_det uedalu0d (.rst(rst_i), .clk(clk), .ce(1'b1), .i(alu0_done&tlb_done), .pe(alu0_done_pe), .ne(), .ee());
edge_det uedalu1d (.rst(rst_i), .clk(clk), .ce(1'b1), .i(alu1_done), .pe(alu1_done_pe), .ne(), .ee());
edge_det uedwait1 (.rst(rst_i), .clk(clk), .ce(1'b1), .i((waitctr==48'd1) || signal_i[fcu_argA[4:0]|fcu_argI[4:0]]), .pe(pe_wait), .ne(), .ee());
edge_det uedfpu1d (.rst(rst_i), .clk(clk), .ce(1'b1), .i(fpu1_done), .pe(fpu1_done_pe), .ne(), .ee());
edge_det uedfpu2d (.rst(rst_i), .clk(clk), .ce(1'b1), .i(fpu2_done), .pe(fpu2_done_pe), .ne(), .ee());

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
wire [VWID-1:0] ralu0_bus = alu0_tlb ? tlbo : alu0_bus;
wire [VWID-1:0] ralu1_bus = alu1_bus;
wire [VWID-1:0] rfpu1_bus = fpu1_bus;
wire [VWID-1:0] rfpu2_bus = fpu2_bus;
wire [VWID-1:0] rfcu_bus  = fcu_bus;
wire [VWID-1:0] rdramA_bus = dramA_bus;
wire [VWID-1:0] rdramB_bus = dramB_bus;

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
		stb <= istb;
		we <= 1'b0;
		sel_o <= isel;
		vadr <= iadr;
	end
3'd1:
	begin
		cti_o <= 3'b000;
		bte_o <= 2'b00;
		cyc <= wcyc;
		stb <= wstb;
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
		stb <= d0stb;
		we <= `LOW;
		sel_o <= d0sel;
		vadr <= d0adr;
	end
3'd3:
	begin
		cti_o <= d1cti;
		bte_o <= d1bte;
		cyc <= d1cyc;
		stb <= d1stb;
		we <= `LOW;
		sel_o <= d1sel;
		vadr <= d1adr;
	end
3'd4:
	begin
		cti_o <= 3'b000;
		bte_o <= 2'b00;
		cyc <= dcyc;
		stb <= dstb;
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
		stb <= 1'b0;
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

slotValid usv1
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

seqnum usqn1
(
	.rst(rst_i),
	.clk(clk),
	.heads(heads),
	.hi_amt(hi_amt),
	.iq_v(iq_v),
	.iq_sn(iq_sn),
	.maxsn(maxsn),
	.tosub(tosub)
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
       iq_jrl[n] <= FALSE;
       iq_rts[n] <= FALSE;
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
       iq_sel[n] <= 1'd0;
       iq_argI[n] <= 64'd0;
       iq_argA[n] <= 64'd0;
       iq_argB[n] <= 64'd0;
       iq_argC[n] <= 64'd0;
       iq_argD[n] <= 64'd0;
       iq_argA_v[n] <= `INV;
       iq_argB_v[n] <= `INV;
       iq_argC_v[n] <= `INV;
       iq_argA_s[n] <= 5'd0;
       iq_argB_s[n] <= 5'd0;
       iq_argC_s[n] <= 5'd0;
       iq_argD_s[n] <= 5'd0;
       iq_canex[n] <= FALSE;
       iq_rid[n] <= 3'd0;
    end
    for (n = 0; n < RENTRIES; n = n + 1) begin
    	rob_state[n] <= RS_INVALID;
    	rob_ip[n] <= 1'd0;
    	rob_instr[n] <= `NOP_INSN;
    	rob_exc[n] <= `FLT_NONE;
    	rob_ma[n] <= 1'd0;
    	rob_res[n] <= 1'd0;
    	rob_argA[n] <= 1'd0;
    	rob_status[n] <= 1'd0;
    	rob_tgt[n] <= 1'd0;
    	rob_crres[n] <= 1'd0;
    	rob_crtgt[n] <= 4'b0000;
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
     dram0_rid <= 1'd0;
     dram1_rid <= 1'd0;
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
     alu0_dataready <= 1'b1;
     alu1_dataready <= 1'b1;
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
		alu0_rid <= {RBIT{1'b1}};
		alu1_ip <= RSTIP;
		alu1_instr <= `NOP_INSN;
		alu1_argA <= 64'h0;
		alu1_argB <= 64'h0;
		alu1_argC <= 64'h0;
		alu1_argI <= 64'h0;
		alu1_mem <= 1'b0;
		alu1_shft <= 1'b0;
		alu1_tgt <= 6'h00;  
		alu1_rid <= {RBIT{1'b1}};
		agen0_argA <= 1'd0;
		agen0_argB <= 1'd0;
		agen0_argC <= 1'd0;
		agen0_dataready <= FALSE;
		agen0_stopString <= FALSE;
		agen0_bytecnt <= 16'hFFFF;
		agen0_offset <= 16'h0;
		agen1_argA <= 1'd0;
		agen1_argB <= 1'd0;
		agen1_argC <= 1'd0;
		agen1_dataready <= FALSE;
`endif
     fcu_dataready <= 0;
     fcu_instr <= `NOP_INSN;
     fcu_jsr <= 1'b0;
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

  if (iq_fc[fcu_id] && iq_v[fcu_id] && !iq_done[fcu_id] && iq_out[fcu_id])
  	fcu_timeout <= fcu_timeout + 8'd1;

	if (!branchmiss) begin
		queuedOn <= queuedOnp;
		case(slotvd)
		4'b0001:
			if (queuedOnp[0]) begin
				queue_slot(0,rob_tails[0],maxsn+1'd1,id_bus[0],active_tag,rob_tails[0]);
			end
		4'b0010:
			if (queuedOnp[1]) begin
				queue_slot(1,rob_tails[0],maxsn+1'd1,id_bus[1],active_tag,rob_tails[0]);
			end
		4'b0011:
			if (queuedOnp[0]) begin
				queue_slot(0,rob_tails[0],maxsn+1'd1,id_bus[0],active_tag,rob_tails[0]);
				if (queuedOnp[1]) begin
					queue_slot(1,rob_tails[1],maxsn+2'd2,id_bus[1],is_branch[0] ? active_tag+2'd1 : active_tag,rob_tails[1]);
					arg_vs(4'b0011);
				end
			end
		4'b0100:
			if (queuedOnp[2]) begin
				queue_slot(2,rob_tails[0],maxsn+1'd1,id_bus[2],active_tag,rob_tails[0]);
			end
		4'b0101:	;	// illegal
		4'b0110:
			if (queuedOnp[1]) begin
				queue_slot(1,rob_tails[0],maxsn+1'd1,id_bus[1],active_tag,rob_tails[0]);
				if (queuedOnp[2]) begin
					queue_slot(2,rob_tails[1],maxsn+2'd2,id_bus[2],is_branch[1] ? active_tag + 2'd1 : active_tag,rob_tails[1]);
					arg_vs(4'b0110);
				end
			end
		4'b0111:
			if (queuedOnp[0]) begin
				queue_slot(0,rob_tails[0],maxsn+1'd1,id_bus[0],active_tag,rob_tails[0]);
				if (queuedOnp[1]) begin
					queue_slot(1,rob_tails[1],maxsn+2'd2,id_bus[1],is_branch[0] ? active_tag + 2'd1 : active_tag,rob_tails[1]);
					arg_vs(4'b0011);
					if (queuedOnp[2]) begin
						queue_slot(2,rob_tails[2],maxsn+2'd3,id_bus[2],
							is_branch[0] && is_branch[1] ? active_tag + 2'd2 :
							is_branch[0] ? active_tag + 2'd1 : is_branch[1] ? active_tag + 2'd1 : active_tag,rob_tails[2]);
						arg_vs(4'b0111);
					end
				end
			end
		4'b1000:
			if (queuedOnp[3]) begin
				queue_slot(3,rob_tails[0],maxsn+1'd1,id_bus[3],active_tag,rob_tails[0]);
			end
		4'b1001:	;	// illegal
		4'b1010:	;	// illegal
		4'b1011:	;	// illegal
		4'b1100:
			if (queuedOnp[2]) begin
				queue_slot(2,rob_tails[0],maxsn+1'd1,id_bus[2],active_tag,rob_tails[0]);
				if (queuedOnp[3]) begin
					queue_slot(3,rob_tails[1],maxsn+2'd2,id_bus[3],is_branch[1] ? active_tag + 2'd1 : active_tag,rob_tails[1]);
					arg_vs(4'b1100);
				end
			end
		4'b1101:	; // illegal
		4'b1110:
			if (queuedOnp[1]) begin
				queue_slot(1,rob_tails[0],maxsn+1'd1,id_bus[1],active_tag,rob_tails[0]);
				if (queuedOnp[2]) begin
					queue_slot(2,rob_tails[1],maxsn+2'd2,id_bus[2],is_branch[0] ? active_tag + 2'd1 : active_tag,rob_tails[1]);
					arg_vs(4'b0110);
					if (queuedOnp[3]) begin
						queue_slot(3,rob_tails[2],maxsn+2'd3,id_bus[3],
							is_branch[0] && is_branch[1] ? active_tag + 2'd2 :
							is_branch[0] ? active_tag + 2'd1 : is_branch[1] ? active_tag + 2'd1 : active_tag,rob_tails[2]);
						arg_vs(4'b1110);
					end
				end
			end
		4'b1111:
			if (queuedOnp[0]) begin
				queue_slot(0,rob_tails[0],maxsn+1'd1,id_bus[0],active_tag,rob_tails[0]);
				if (queuedOnp[1]) begin
					queue_slot(1,rob_tails[1],maxsn+2'd2,id_bus[1],is_branch[0] ? active_tag + 2'd1 : active_tag,rob_tails[1]);
					arg_vs(4'b0011);
					if (queuedOnp[2]) begin
						queue_slot(2,rob_tails[2],maxsn+2'd3,id_bus[2],
							is_branch[0] && is_branch[1] ? active_tag + 2'd2 :
							is_branch[0] ? active_tag + 2'd1 : is_branch[1] ? active_tag + 2'd1 : active_tag,rob_tails[2]);
						arg_vs(4'b0111);
						if (queuedOnp[3]) begin
							queue_slot(3,rob_tails[3],maxsn+3'd4,id_bus[3],
								is_branch[0] && is_branch[1] && is_branch[2] ? active_tag + 2'd3 :
								is_branch[0] && is_branch[1] ? active_tag + 2'd2 :
								is_branch[0] && is_branch[2] ? active_tag + 2'd2 :
								is_branch[1] && is_branch[2] ? active_tag + 2'd2 :
								is_branch[0] ? active_tag + 2'd1 : is_branch[1] ? active_tag + 2'd1 : is_branch[2] ? active_tag + 2'd1 : 
								active_tag,rob_tails[2]);
							arg_vs(4'b1111);
						end
					end
				end
			end
		default:	;
		endcase
		if (queuedOnp[0]) begin
			br_tag[tails[0]] <= active_tag + is_branch[0];
			iq_br_tag[tails[0]] <= active_tag;
		end
		if (queuedOnp[1]) begin
			br_tag[tails[1]] <= active_tag + (queuedOnp[0] & is_branch[0]) + is_branch[1];
			iq_br_tag[tails[1]] <= active_tag + (queuedOnp[0] & is_branch[0]);
		end
		if (queuedOnp[2]) begin
			br_tag[tails[2]] <= active_tag + (queuedOnp[0] & is_branch[0]) + (queuedOnp[1] & is_branch[1]) + is_branch[2];
			iq_br_tag[tails[2]] <= active_tag + (queuedOnp[0] & is_branch[0]) + (queuedOnp[1] & is_branch[1]);
		end
		active_tag <= active_tag + (queuedOnp[0] & is_branch[0])
														+ (queuedOnp[1] & is_branch[1])
														+ (queuedOnp[2] & is_branch[2]);
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
if (IsMul(alu0_instr)|IsDivmod(alu0_instr)|alu0_shft|alu0_tlb) begin
	if (alu0_done_pe) begin
		alu0_dataready <= TRUE;
	end
end

if (alu0_v) begin
	rob_tgt [ alu0_rid ] <= alu0_tgt;
	rob_crtgt [ alu0_rid] <= alu0_crtgt;
	rob_res	[ alu0_rid ] <= ralu0_bus;
	rob_crres [ alu0_rid] <= alu0_cro;
	rob_argA [alu0_rid] <= alu0_argA;
	rob_exc	[ alu0_rid ] <= alu0_exc;
//	if (alu0_done) begin
		if (iq_state[alu0_id]==IQS_OUT) begin
			iq_state[alu0_id] <= IQS_CMT;
			rob_state[alu0_rid] <= RS_CMT;
		end
//	end
	if (|alu0_exc) begin
		iq_store[alu0_id] <= `INV;
		iq_state[alu0_id] <= IQS_CMT;
		rob_state[alu0_rid] <= RS_CMT;
	end
	alu0_dataready <= FALSE;
end

if (IsMul(alu1_instr)|IsDivmod(alu1_instr)|alu1_shft) begin
	if (alu1_done_pe) begin
		alu1_dataready <= TRUE;
	end
end

if (alu1_v && `NUM_ALU > 1) begin
	rob_tgt [ alu1_rid ] <= alu1_tgt;
	rob_crtgt [ alu1_rid] <= alu1_crtgt;
	rob_res	[ alu1_rid ] <= ralu1_bus;
	rob_crres [ alu1_rid] <= alu1_cro;
	rob_argA [alu1_rid] <= alu1_argA;
	rob_exc	[ alu1_rid ] <= alu1_exc;
//	if (alu1_done) begin
		if (iq_state[alu1_id]==IQS_OUT) begin
			iq_state[alu1_id] <= IQS_CMT;
			rob_state[alu1_rid] <= RS_CMT;
		end
//	end
	if (|alu1_exc) begin
		iq_store[alu1_id] <= `INV;
		iq_state[alu1_id] <= IQS_CMT;
		rob_state[alu1_rid] <= RS_CMT;
	end
	alu1_dataready <= FALSE;
end

if (agen0_v) begin
	rob_tgt[agen0_rid] <= agen0_tgt;
	if (iq_state[agen0_id]==IQS_OUT)
		iq_state[agen0_id] <= (agen0_lea|agen0_memdb|agen0_memsb) ? IQS_CMT : IQS_AGEN;
	if (agen0_lea|agen0_memdb|agen0_memsb)
		if (rob_state[agen0_rid]==RS_ASSIGNED)
			rob_state[agen0_rid] <= RS_CMT;
	rob_res[agen0_rid] <= agen0_ma;		// LEA/PUSH needs this result
	rob_exc[agen0_rid] <= `FLT_NONE;
	if (iq_state[agen0_id]!=IQS_AGEN) begin
		iq_ma[agen0_id] <= agen0_ma;
		iq_sel[agen0_id] <= fnSelect(agen0_instr) << agen0_ma[4:0];
		rob_res[agen0_rid] <= agen0_ma;
	end
	agen0_dataready <= FALSE;
end

if (agen1_v && `NUM_AGEN > 1) begin
	rob_tgt[agen1_rid] <= agen1_tgt;
	if (iq_state[agen1_id]==IQS_OUT)
		iq_state[agen1_id] <= (agen1_lea|agen1_memdb|agen1_memsb) ? IQS_CMT : IQS_AGEN;
	if (agen1_lea|agen1_memdb|agen1_memsb)
		if (rob_state[agen1_rid]==RS_ASSIGNED)
			rob_state[agen1_rid] <= RS_CMT;
	rob_res[agen1_rid] <= agen1_ma;		// LEA needs this result
	rob_exc[agen1_rid] <= `FLT_NONE;
	if (iq_state[agen1_id]!=IQS_AGEN) begin
		iq_ma[agen1_id] <= agen1_ma;
		iq_sel[agen1_id] <= fnSelect(agen1_instr) << agen1_ma[4:0];
		rob_res[agen1_rid] <= agen1_ma;
	end
	agen1_dataready <= FALSE;
end

if (fpu1_done_pe)
	fpu1_dataready <= TRUE;

if (fpu1_v && `NUM_FPU > 0) begin
	rob_tgt [ fpu1_rid] <= fpu1_tgt;
	rob_crtgt [ fpu1_rid] <= fpu1_crtgt;
	rob_res [ fpu1_rid ] <= rfpu1_bus;
	rob_status[ fpu1_rid ] <= fpu1_status;
	rob_exc [ fpu1_rid ] <= fpu1_exc;
//	iq_done[ fpu1_id ] <= fpu1_done;
//	iq_out [ fpu1_id ] <= `INV;
	if (iq_state[fpu1_id]==IQS_OUT) begin
		iq_state[fpu1_id] <= IQS_CMT;
		rob_state[fpu1_rid] <= RS_CMT;
	end
	fpu1_dataready <= FALSE;
end

if (fpu2_done_pe)
	fpu2_dataready <= TRUE;

if (fpu2_v && `NUM_FPU > 1) begin
	rob_tgt [ fpu2_rid] <= fpu2_tgt;
	rob_crtgt [ fpu2_rid] <= fpu2_crtgt;
	rob_res [ fpu2_rid ] <= rfpu2_bus;
	rob_status[ fpu2_rid ] <= fpu2_status;
	rob_exc [ fpu2_rid ] <= fpu2_exc;
//	iq_done[ fpu2_id ] <= fpu2_done;
//	iq_out [ fpu2_id ] <= `INV;
	if (iq_state[fpu2_id]==IQS_OUT) begin
		iq_state[fpu2_id] <= IQS_CMT;
		rob_state[fpu2_rid] <= RS_CMT;
	end
	//iq_agen[ fpu_id ] <= `VAL;  // RET
	fpu2_dataready <= FALSE;
end

if (fcu_wait) begin
	if (pe_wait)
		fcu_dataready <= `TRUE;
end

if (fcu_v) begin
	fcu_done <= `TRUE;
	iq_ma  [ fcu_id ] <= fcu_missip;
	rob_tgt [ fcu_rid] <= fcu_tgt;
  rob_res [ fcu_rid ] <= rfcu_bus;
  rob_exc [ fcu_rid ] <= fcu_exc;
	if (iq_state[fcu_id]==IQS_OUT) begin
		iq_state[fcu_id ] <= IQS_CMT;
		rob_state[fcu_rid ] <= RS_CMT;
	end
	// takb is looked at only for branches to update the predictor. Here it is
	// unconditionally set, the value will be ignored if it's not a branch.
	iq_takb[ fcu_id ] <= fcu_takb;
	br_ctr <= br_ctr + fcu_branch;
	fcu_dataready <= `INV;
end

// dramX_v only set on a load
if (dramA_v && iq_v[ dramA_id ]) begin
	rob_res	[ dramA_rid ] <= rdramA_bus;
	rob_state[dramA_rid ] <= RS_CMT;
	iq_state[dramA_id ] <= IQS_CMT;
	iq_aq  [ dramA_id ] <= `INV;
end
if (`NUM_MEM > 1 && dramB_v && iq_v[ dramB_id ]) begin
	rob_res	[ dramB_id ] <= rdramB_bus;
	rob_state[dramB_rid ] <= RS_CMT;
	iq_state[dramB_id ] <= IQS_CMT;
	iq_aq  [ dramB_id ] <= `INV;
end

if (wb_q0_done) begin
	dram0 <= `DRAMREQ_READY;
	iq_state[ dram0_id ] <= IQS_DONE;
end
if (wb_q1_done) begin
	dram1 <= `DRAMREQ_READY;
	iq_state[ dram1_id ] <= IQS_DONE;
end

if (update_iq) begin
	for (n = 0; n < RENTRIES; n = n + 1) begin
		if (ruid[n]) begin
      rob_exc[n] <= wb_fault;
     	rob_state[n] <= RS_CMT;
		end
	end
end
if (update_iq) begin
	for (n = 0; n < QENTRIES; n = n + 1) begin
		if (uid[n]) begin
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
	setargs(n,{1'b0,commit0_id},commit0_v,commit0_bus);
	setargs(n,{1'b0,commit1_id},commit1_v,commit1_bus);
	setargs(n,{1'b0,commit2_id},commit2_v,commit2_bus);
	setargs(n,{1'b0,commit3_id},commit3_v,commit3_bus);

	if (`NUM_FPU > 0)
		setargs(n,{1'b0,fpu1_rid},fpu1_v,rfpu1_bus);
	if (`NUM_FPU > 1)
		setargs(n,{1'b0,fpu2_rid},fpu2_v,rfpu2_bus);

	setargs(n,{1'b0,alu0_rid},alu0_v,ralu0_bus);
	if (`NUM_ALU > 1)
		setargs(n,{1'b0,alu1_rid},alu1_v,ralu1_bus);

	setargs(n,{1'b1,agen0_rid},agen0_v & agen0_mem2,agen0_res);
	if (`NUM_AGEN > 1) begin
		setargs(n,{1'b1,agen1_rid},agen1_v & agen1_mem2,agen1_res);
	end

	setargs(n,{1'b0,fcu_rid},fcu_v,rfcu_bus);

	setargs(n,{1'b0,dramA_rid},dramA_v,rdramA_bus);
	if (`NUM_MEM > 1)
		setargs(n,{1'b0,dramB_rid},dramB_v,rdramB_bus);
end

// Argument loading to functional units.
// X's on unused busses cause problems in SIM.
    for (n = 0; n < QENTRIES; n = n + 1)
        if (iq_alu0_issue[n] && !(iq_v[n] && iq_stomp[n])
												&& (alu0_available & alu0_done)) begin
					iq_fuid[n] <= 3'd0;
					alu0_sn <= iq_sn[n];
					alu0_sourceid	<= n[`QBITS];
					check_done(n[`QBITS]);
					check_issue(7'b1111110);
					// The following line is a hack. The alu is done (tested above) so it
					// should be setting the state to CMT.
//					if (iq_state[alu0_id]==IQS_OUT)
//						iq_state[alu0_id] <= IQS_CMT;
					alu0_rid <= iq_rid[n];
					alu0_instr	<= iq_rtop[n] ? (
`ifdef FU_BYPASS                 									
					iq_argC_v[n] ? iq_argC[n][WID-1:0]
          : (iq_argC_s[n] == alu0_id) ? ralu0_bus
          : (iq_argC_s[n] == alu1_id) ? ralu1_bus
          : (iq_argC_s[n] == fpu1_id && `NUM_FPU > 0) ? rfpu1_bus[WID-1:0]
          : `NOP_INSN)
`else			                           
					iq_argC[n][WID-1:0]) 
`endif			                            
											 : iq_instr[n];
					alu0_fmt    <= iq_fmt[n];
					alu0_z		 <= iq_z[n];
					alu0_tlb   <= iq_tlb[n];
					alu0_mem   <= iq_mem[n];
					alu0_load  <= iq_load[n];
					alu0_store <= iq_store[n];
					alu0_shft <= iq_shft[n];
					alu0_ip		<= iq_ip[n];
					// Agen output is not bypassed since there's only one
					// instruction (LEA) to bypass for.
					bypass(0,0,iq_argA_v[n],iq_argA_s[n][`RBITS],iq_argA[n][VWID-1:0],alu0_argA);
					bypass(iq_imm[n],iq_argI[n],iq_argB_v[n],iq_argB_s[n][`RBITS],iq_argB[n][VWID-1:0],alu0_argB);
					bypass(0,0,iq_argC_v[n],iq_argC_s[n][`RBITS],iq_argC[n][VWID-1:0],alu0_argC);
					bypass32 (0,0,iq_argD_v[n],iq_argD_s[n][`RBITS],iq_argD[n][31:0],alu0_argD);
					bypass(0,0,iq_argT_v[n],iq_argT_s[n][`RBITS],iq_argT[n][VWID-1:0],alu0_argT);
					alu0_argI	<= iq_argI[n];
					alu0_tgt    <= iq_tgt[n];
					alu0_dataready <= IsSingleCycle(iq_instr[n]);
					alu0_ld <= TRUE;
					iq_state[n] <= IQS_OUT;
        end

	if (`NUM_ALU > 1) begin
    for (n = 0; n < QENTRIES; n = n + 1)
        if ((iq_alu1_issue[n] && !(iq_v[n] && iq_stomp[n])
												&& (alu1_available & alu1_done))) begin
								iq_fuid[n] <= 3'd1;
            		 alu1_sn <= iq_sn[n];
                 alu1_sourceid	<= n[`QBITS];
								check_done(n[`QBITS]);
								check_issue(7'b1111101);
								// The following line is a hack. The alu is done (tested above) so it
								// should be setting the state to CMT.
	//							if (iq_state[alu1_id]==IQS_OUT)
	//								iq_state[alu1_id] <= IQS_CMT;
                 alu1_rid <= iq_rid[n];
                 alu1_instr	<= iq_instr[n];
                 alu1_fmt    <= iq_fmt[n];
								alu1_z		 <= iq_z[n];
                 alu1_mem   <= iq_mem[n];
                 alu1_load  <= iq_load[n];
                 alu1_store <= iq_store[n];
                 alu1_shft  <= iq_shft[n];
                 alu1_ip		<= iq_ip[n];
								bypass(0,0,iq_argA_v[n],iq_argA_s[n][`RBITS],iq_argA[n][VWID-1:0],alu1_argA);
								bypass(iq_imm[n],iq_argI[n],iq_argB_v[n],iq_argB_s[n][`RBITS],iq_argB[n][VWID-1:0],alu1_argB);
								bypass(0,0,iq_argC_v[n],iq_argC_s[n][`RBITS],iq_argC[n][VWID-1:0],alu1_argC);
								bypass32 (0,0,iq_argD_v[n],iq_argD_s[n][`RBITS],iq_argD[n][31:0],alu1_argD);
								bypass(0,0,iq_argT_v[n],iq_argT_s[n][`RBITS],iq_argT[n][VWID-1:0],alu1_argT);
                 alu1_argI	<= iq_argI[n];
                 alu1_tgt    <= iq_tgt[n];
                 alu1_dataready <= IsSingleCycle(iq_instr[n]);
                 alu1_ld <= TRUE;
                 iq_state[n] <= IQS_OUT;
        end
  end

    for (n = 0; n < QENTRIES; n = n + 1)
        if (iq_agen0_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (1'b1) begin
							iq_fuid[n] <= 3'd2;
            		agen0_sn <= iq_sn[n];
                 agen0_sourceid	<= n[`QBITS];
								check_done(n[`QBITS]);
								check_issue(7'b1111011);
                 agen0_rid <= iq_rid[n];
                 agen0_unit <= iq_unit[n];
                 agen0_instr	<= iq_instr[n];
                 agen0_lea  <= iq_lea[n];
                 agen0_push <= iq_push[n];
                 agen0_pop <= iq_pop[n];
                 agen0_mem2 <= iq_mem2[n];
                 agen0_memsb <= iq_memsb[n];
                 agen0_memdb <= iq_memdb[n];
								bypass128 (0,0,iq_argA_v[n],iq_argA_s[n][`RBITS],iq_argA[n][VWID-1:0],agen0_argA);
							if (agen0_bytecnt[11]) begin
								agen0_offset <= 16'd0;
									if (iq_lsstring[n]) begin
										bypass128 (0,0,iq_argC_v[n],iq_argC_s[n][`RBITS],iq_argC[n][VWID-1:0],agen0_bytecnt);
								end
							end
							else begin
								agen0_bytecnt <= agen0_bytecnt - 16'd32;
								agen0_offset <= agen0_offset + 16'd32;
								if (agen0_bytecnt < 16'd32)
									agen0_stopString <= TRUE;
							end
//                 agen0_argB	<= iq_argB[n];	// ArgB not used by agen
							bypass128 (0,0,iq_argC_v[n],iq_argC_s[n][`RBITS],iq_argC[n][VWID-1:0],agen0_argC);
								agen0_argI <= iq_argI[n];      
                 agen0_tgt    <= iq_tgt[n];
                 agen0_dataready <= 1'b1;
                 if (iq_lsm[n] & agen0_stopString)
                 	iq_state[n] <= IQS_INVALID;
                 else begin
                 	agen0_stopString <= FALSE;
                 	iq_state[n] <= IQS_OUT;
               		end
            end
        end

	if (`NUM_AGEN > 1) begin
    for (n = 0; n < QENTRIES; n = n + 1)
        if (iq_agen1_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (1'b1) begin
							iq_fuid[n] <= 3'd3;
            		agen1_sn <= iq_sn[n];
                 agen1_sourceid	<= n[`QBITS];
								check_done(n[`QBITS]);
								check_issue(7'b1110111);
                 agen1_rid <= iq_rid[n];
                 agen1_unit <= iq_unit[n];
                 agen1_instr	<= iq_instr[n];
                 agen1_lea  <= iq_lea[n];
                 agen1_push <= iq_push[n];
                 agen1_pop <= iq_pop[n];
                 agen1_mem2 <= iq_mem2[n];
                 agen1_memsb <= iq_memsb[n];
                 agen1_memdb <= iq_memdb[n];
								bypass128 (0,0,iq_argA_v[n],iq_argA_s[n][`RBITS],iq_argA[n][VWID-1:0],agen1_argA);
//                 agen1_argB	<= iq_argB[n];	// ArgB not used by agen
								bypass128 (0,0,iq_argC_v[n],iq_argC_s[n][`RBITS],iq_argC[n][VWID-1:0],agen1_argC);
								agen1_argI <= iq_argI[n];      
                 agen1_tgt    <= iq_tgt[n];
                 agen1_dataready <= 1'b1;
                 iq_state[n] <= IQS_OUT;
            end
        end
  end

	// Produces an unimplmented operation exception if no FPU's are selected.
    for (n = 0; n < QENTRIES; n = n + 1)
        if (iq_fpu1_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (fpu1_available & fpu1_done) begin
            	if (`NUM_FPU > 0) begin
								iq_fuid[n] <= 3'd4;
                 fpu1_sourceid	<= n[`QBITS];
								check_done(n[`QBITS]);
								check_issue(7'b1101111);
                 fpu1_rid <= iq_rid[n];
                 fpu1_instr	<= iq_instr[n];
                 fpu1_fmt   <= iq_fmt[n];
                 fpu1_z     <= iq_z[n];
                 fpu1_vset  <= iq_vset[n];
                 fpu1_ip		<= iq_ip[n];
								bypass(0,0,iq_argA_v[n],iq_argA_s[n][`RBITS],iq_argA[n][VWID-1:0],fpu1_argA);
								bypass(iq_imm[n],iq_argI[n],iq_argB_v[n],iq_argB_s[n][`RBITS],iq_argB[n][VWID-1:0],fpu1_argB);
								bypass(0,0,iq_argC_v[n],iq_argC_s[n][`RBITS],iq_argC[n][VWID-1:0],fpu1_argC);
								bypass32 (0,0,iq_argD_v[n],iq_argD_s[n][`RBITS],iq_argD[n][31:0],fpu1_argD);
								bypass(0,0,iq_argT_v[n],iq_argT_s[n][`RBITS],iq_argT[n][VWID-1:0],fpu1_argT);
                 fpu1_argI	<= iq_argI[n];
                 fpu1_dataready <= `VAL;
                 fpu1_ld <= TRUE;
                 fpu1_tgt <= iq_tgt[n];
                 iq_state[n] <= IQS_OUT;
              end
              else begin
								check_done(n[`QBITS]);
								check_issue(7'b1101111);
                iq_exc[n] <= `FLT_UNIMP;
                iq_state[n] <= IQS_CMT;
            	end
            end
        end

	if (`NUM_FPU > 1) begin
    for (n = 0; n < QENTRIES; n = n + 1)
        if (iq_fpu2_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
            if (fpu2_available & fpu2_done) begin
							iq_fuid[n] <= 3'd5;
                 fpu2_sourceid	<= n[`QBITS];
								check_done(n[`QBITS]);
								check_issue(7'b1011111);
                 fpu2_rid <= iq_rid[n];
                 fpu2_instr	<= iq_instr[n];
                 fpu2_fmt   <= iq_fmt[n];
                 fpu2_z     <= iq_z[n];
                 fpu2_vset  <= iq_vset[n];
                 fpu2_ip		<= iq_ip[n];
								bypass(0,0,iq_argA_v[n],iq_argA_s[n][`RBITS],iq_argA[n][VWID-1:0],fpu2_argA);
								bypass(iq_imm[n],iq_argI[n],iq_argB_v[n],iq_argB_s[n][`RBITS],iq_argB[n][VWID-1:0],fpu2_argB);
								bypass(0,0,iq_argC_v[n],iq_argC_s[n][`RBITS],iq_argC[n][VWID-1:0],fpu2_argC);
								bypass32 (0,0,iq_argD_v[n],iq_argD_s[n][`RBITS],iq_argD[n][31:0],fpu2_argD);
								bypass(0,0,iq_argT_v[n],iq_argT_s[n][`RBITS],iq_argT[n][VWID-1:0],fpu2_argT);
                 fpu2_argI	<= iq_argI[n];
                 fpu2_dataready <= `VAL;
                 fpu2_ld <= TRUE;
                 fpu2_tgt <= iq_tgt[n];
                 iq_state[n] <= IQS_OUT;
            end
        end
  end

  for (n = 0; n < QENTRIES; n = n + 1)
    if (iq_fcu_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
      if (fcu_done) begin
					iq_fuid[n] <= 3'd6;
				fcu_sourceid	<= n[`QBITS];
				check_done(n[`QBITS]);
        fcu_rid <= iq_rid[n];
				check_issue(7'b0111111);
				fcu_prevInstr <= fcu_instr;
				fcu_instr	<= iq_instr[n];
				fcu_ip		<= iq_ip[n];
				fcu_nextip <= iq_ip[n] + 4'd5;
				fcu_pt     <= iq_pt[n];
				fcu_brdisp <= iq_instr[n][37:11];
				//$display("Branch tgt: %h", {iq_instr[n][39:22],iq_instr[n][5:3],iq_instr[n][4:3]});
				fcu_branch <= iq_br[n];
				fcu_cr     <= iq_cr[n];
				fcu_jsr    <= IsJSR(iq_instr[n])|iq_jrl[n];
				fcu_jal     <= iq_jrl[n];
				fcu_rts    <= iq_rts[n];
				fcu_brk  <= iq_brk[n];
				fcu_rti  <= iq_rti[n];
				fcu_rex  <= iq_rex[n];
				fcu_chk  <= iq_chk[n];
				fcu_wait <= iq_wait[n];
				bypass128 (0,0,iq_argA_v[n],iq_argA_s[n][`RBITS],iq_argA[n][VWID-1:0],fcu_argA);
				bypass128 (iq_imm[n],iq_argI[n],iq_argB_v[n],iq_argB_s[n][`RBITS],iq_argB[n][VWID-1:0],fcu_argB);
				bypass128 (0,0,iq_argB_v[n],iq_argB_s[n][`RBITS],iq_argB[n][VWID-1:0],fcu_argLk);
				bypass128 (0,0,iq_argC_v[n],iq_argC_s[n][`RBITS],iq_argC[n][VWID-1:0],fcu_argC);
				fcu_argI	<= iq_argI[n];
				fcu_ipc  <= ipc0;
				bypass32 (0,0,iq_argB_v[n],iq_argB_s[n][`RBITS],iq_argB[n][VWID-1:0],waitctr);
				fcu_dataready <= !IsWait(iq_instr[n]);
				fcu_clearbm <= `FALSE;
				fcu_ld <= TRUE;
				fcu_timeout <= 8'h00;
        fcu_tgt <= iq_tgt[n];
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
	dramA_v <= !iq_stomp[dram0_id];
	dramA_id <= dram0_id;
	dramA_rid <= dram0_rid;
	dramA_bus <= rdat0;
end
if (dram1 == `DRAMREQ_READY && dram1_load && `NUM_MEM > 1) begin
	dramB_v <= !iq_stomp[dram1_id];
	dramB_id <= dram1_id;
	dramB_rid <= dram1_rid;
	dramB_bus <= rdat1;
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
		rob_state[iq_rid[n]] <= RS_INVALID;
//		if (alu0_id==n)
//			alu0_dataready <= FALSE;
//		if (alu1_id==n)
//			alu1_dataready <= FALSE;
		$display("stomp: IQS_INVALID[%d]",n);
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
oddball_commit(commit1_v, heads[1], 2'd1);
oddball_commit(commit2_v, heads[2], 2'd2);
oddball_commit(commit3_v, heads[3], 2'd3);

// Fetch and queue are limited to two instructions per cycle, so we might as
// well limit retiring to two instructions max to conserve logic.
//
	head_inc(hi_amt);
	rob_head_inc(r_amt);

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
	if (iq_v[dram0_id] && !iq_stomp[dram0_id]) begin
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
		rmw_ad0 <= rdat0;
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
	if (iq_v[dram0_id] && !iq_stomp[dram0_id])
		;
	else begin
		dram0 <= `DRAMREQ_READY;
		dram0_load <= `FALSE;
		//xdati <= {13{lfsro}};
	end
`DRAMSLOT_HASBUS:
	if (iq_v[dram0_id] && !iq_stomp[dram0_id])
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
	if (iq_v[dram1_id] && !iq_stomp[dram1_id]) begin
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
		rmw_ad1 <= rdat1;
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
	if (iq_v[dram1_id] && !iq_stomp[dram1_id])
		;
	else begin
		dram1 <= `DRAMREQ_READY;
		dram1_load <= `FALSE;
		//xdati <= {13{lfsro}};
	end
`DRAMSLOT_HASBUS:
	if (iq_v[dram1_id] && !iq_stomp[dram1_id])
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
      	&& !iq_stomp[dram0_id]) begin
`ifdef SUPPORT_DBG      
            if (dbg_smatch0|dbg_lmatch0) begin
                 dramA_v <= `TRUE;
                 dramA_id <= dram0_id;
                 dramA_bus <= 64'h0;
                 iq_exc[dram0_id] <= `FLT_DBG;
                 dram0 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            if (!dack_i) begin
                 isRMW <= dram0_rmw;
                 isCAS <= IsCAS(dram0_instr);
//                 isAMO <= IsAMO(dram0_instr);
//                 isInc <= IsInc(dram0_instr);
                 casid <= dram0_id;
                 bwhich <= 2'b00;
                 dram0 <= `DRAMSLOT_HASBUS;
                 dcyc <= `HIGH;
                 dstb <= `HIGH;
                 dsel <= fnSelect(dram0_instr);
                 //dcbuf <= dram0_data << {dram0_addr[4:0],3'b0};
                 //dcsel <= fnSelect(`MUnit,dram0_instr) << dram0_addr[4:0];
                 dadr <= dram0_addr;
                 ddat <= dram0_data << {dram0_addr[3:0],3'b0};
                 dol  <= dram0_ol;
                 bstate <= B_RMWAck;
            end
        end
        else if (~|wb_v && dram1==`DRAMSLOT_BUSY && dram1_rmw && `NUM_MEM > 1
        	&& !iq_stomp[dram1_id]) begin
`ifdef SUPPORT_DBG        	
            if (dbg_smatch1|dbg_lmatch1) begin
                 dramB_v <= `TRUE;
                 dramB_id <= dram1_id;
                 dramB_bus <= 64'h0;
                 iq_exc[dram1_id] <= `FLT_DBG;
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
                 dsel <= fnSelect(dram1_instr);
                 dadr <= dram1_addr;
                 ddat <= dram1_data << {dram1_addr[3:0],3'b0};
                 dol  <= dram1_ol;
                 bstate <= B_RMWAck;
            end
        end
        else if (~|wb_v && dram0_unc && dram0==`DRAMSLOT_BUSY && dram0_load
        	&& !iq_stomp[dram0_id]) begin
`ifdef SUPPORT_DBG        	
            if (dbg_lmatch0) begin
               dramA_v <= `TRUE;
               dramA_id <= dram0_id;
               dramA_bus <= 64'h0;
               iq_exc[dram0_id] <= `FLT_DBG;
               dram0 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            if (!dack_i) begin
               bwhich <= 2'b00;
               dram0 <= `DRAMSLOT_HASBUS;
               dcyc <= `HIGH;
               dstb <= `HIGH;
               dsel <= fnSelect(dram0_instr);
               dadr <= {dram0_addr[AMSB:3],3'b0};
               sr_o <=  IsLWR(dram0_instr);
               ol_o  <= dram0_ol;
               dccnt <= 2'd0;
               bstate <= B_DLoadAck;
            end
        end
        else if (~|wb_v && dram1_unc && dram1==`DRAMSLOT_BUSY && dram1_load && `NUM_MEM > 1
        	&& !iq_stomp[dram1_id]) begin
`ifdef SUPPORT_DBG        	
            if (dbg_lmatch1) begin
               dramB_v <= `TRUE;
               dramB_id <= dram1_id;
               dramB_bus <= 64'h0;
               iq_exc[dram1_id] <= `FLT_DBG;
               dram1 <= `DRAMSLOT_AVAIL;
            end
            else
`endif            
            if (!dack_i) begin
               bwhich <= 2'b01;
               dram1 <= `DRAMSLOT_HASBUS;
               dcyc <= `HIGH;
               dstb <= `HIGH;
               dsel <= fnSelect(dram1_instr);
               dadr <= {dram1_addr[AMSB:3],3'b0};
               sr_o <=  IsLWR(dram1_instr);
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
	     rob_res	[ casid ] <= {(dat_i == cas),4'd0};
         rob_exc [ casid ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
//             iq_done[ casid ] <= `VAL;
//    	     iq_out [ casid ] <= `INV;
	     iq_state [ casid ] <= IQS_DONE;
	     iq_instr[ casid] <= `NOP_INSN;
	    if (err_i | rdv_i)
	    	iq_ma[casid] <= vadr;
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
	     rmw_instr <= iq_instr[casid];
	     rmw_argA <= dat_i;
    	 if (isSpt) begin
    	 	rmw_argB <= 64'd1 << iq_argA[casid][67:62];
    	 	rmw_argC <= iq_instr[casid][5:0]==`R2 ?
    	 				iq_argC[casid][64] << iq_argA[casid][67:62] :
    	 				iq_argB[casid][64] << iq_argA[casid][67:62];
    	 end
    	 else if (isInc) begin
    	 	rmw_argB <= iq_instr[casid][5:0]==`R2 ? {{59{iq_instr[casid][22]}},iq_instr[casid][22:18]} :
    	 														 {{59{iq_instr[casid][17]}},iq_instr[casid][17:13]};
     	 end
    	 else begin // isAMO
  	     rob_res [ casid ] <= {dat_i,4'd0};
  	     rmw_argB <= iq_instr[casid][31] ? {{59{iq_instr[casid][20:16]}},iq_instr[casid][20:16]} : iq_argB[casid][WID+3:4];
       end
         rob_exc [ casid ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
         dstb <= `LOW;
         bstate <= B_RMWCvt;
				check_abort_load();
		end
  end

// Regular load
B_DLoadAck:
  if (dack_i|derr_i|tlb_miss|rdv_i) begin
  	if (!bok_i) begin
  		dstb <= `LOW;
			dadr[AMSB:4] <= dadr[AMSB:4] + 2'd1;
  		state <= B_DLoadNack;
  	end
  	//wb_nack();
		sr_o <= `LOW;
		case(dccnt)
		2'd0:	xdati[127:0] <= dat_i;
		2'd1:	xdati[255:128] <= dat_i;
		2'd2:	xdati[371:256] <= dat_i[119:0];
		2'd3:	;
		endcase
    case(bwhich)
    2'b00:  begin
           		dram0 <= `DRAMREQ_READY;
             	if (iq_stomp[dram0_id])
             		iq_exc [dram0_id] <= `FLT_NONE;
             	else
             		iq_exc [ dram0_id ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
            end
    2'b01:  if (`NUM_MEM > 1) begin
             dram1 <= `DRAMREQ_READY;
             	if (iq_stomp[dram1_id])
             		iq_exc [dram1_id] <= `FLT_NONE;
             	else
	             iq_exc [ dram1_id ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
            end
    default:    ;
    endcase
    dccnt <= dccnt + 2'd1;
    case(dccnt)
    2'd1:	cti_o <= 3'b111;
    2'd2: begin cti_o <= 3'd000; wb_nack(); bstate <= B_LSNAck; end
  	endcase
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
	$display("%b %h #", ip_mask, ip);
	$display("%b %h #", ip_mask, ipd);
    $display ("--------------------------------------------------------------------- Regfile: %d ---------------------------------------------------------------------", rgs);
	for (n=0; n < 32; n=n+4) begin
	    $display("%d: %h %d %o   %d: %h %d %o   %d: %h %d %o   %d: %h %d %o#",
	       n[4:0]+0, urf1.mem[{rgs,n[4:2],2'b00}], regIsValid[n+0], rf_source[n+0],
	       n[4:0]+1, urf1.mem[{rgs,n[4:2],2'b01}], regIsValid[n+1], rf_source[n+1],
	       n[4:0]+2, urf1.mem[{rgs,n[4:2],2'b10}], regIsValid[n+2], rf_source[n+2],
	       n[4:0]+3, urf1.mem[{rgs,n[4:2],2'b11}], regIsValid[n+3], rf_source[n+3]
	       );
	end
`ifdef FCU_ENH
	$display("Call Stack:");
	for (n = 0; n < 16; n = n + 4)
		$display("%c%d: %h   %c%d: %h   %c%d: %h   %c%d: %h",
			ursb1.rasp==n+0 ?">" : " ", n[4:0]+0, ursb1.ras[n+0],
			ursb1.rasp==n+1 ?">" : " ", n[4:0]+1, ursb1.ras[n+1],
			ursb1.rasp==n+2 ?">" : " ", n[4:0]+2, ursb1.ras[n+2],
			ursb1.rasp==n+3 ?">" : " ", n[4:0]+3, ursb1.ras[n+3]
		);
	$display("\n");
`endif
//    $display("Return address stack:");
//    for (n = 0; n < 16; n = n + 1)
//        $display("%d %h", rasp+n[3:0], ras[rasp+n[3:0]]);
	$display("TakeBr:%d #", take_branch);//, backpc);
	$display("Insn%d: %h", 0, insnx[0]);
	$display ("------------------------------------------------------------------------ Dispatch Buffer -----------------------------------------------------------------------");
	for (i=0; i<QENTRIES; i=i+1) 
	    $display("%c%c %d: %c%c%c %d %d %c%c %c %c%h %d,%d %h %h %d %d %d %h %d %d %d %h %d %d %d %h %o %h#",
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
		iq_instr[i], iq_tgt[i][5:0], iq_tgt[i][5:0],
		iq_argI[i],
		iq_argA[i], iq_rs1[i], iq_argA_v[i], iq_argA_s[i],
		iq_argB[i], iq_rs2[i], iq_argB_v[i], iq_argB_s[i],
		iq_argC[i], iq_rs3[i], iq_argC_v[i], iq_argC_s[i],
		iq_ip[i],
		iq_sn[i],
		iq_br_tag[i]
		);
	$display ("------------- Reorder Buffer ------------");
	for (i = 0; i < RENTRIES; i = i + 1)
	$display("%c%c %d(%d): %c %h %d %h#",
		 (i[`RBITS]==rob_heads[0])?"C":".",
		 (i[`RBITS]==rob_tails[0])?"Q":".",
		  i[`RBITS],
		  rob_id[i],
		  rob_state[i]==RS_INVALID ? "-" :
		  rob_state[i]==RS_ASSIGNED ? "A"  :
		  rob_state[i]==RS_CMT ? "C"  : "D",
		  rob_exc[i],
		  rob_tgt[i],
		  rob_res[i]
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
  2'd0:	if (iq_stomp[dram0_id]) begin bstate <= BIDLE; dram0 <= `DRAMREQ_READY; end
  2'd1:	if (iq_stomp[dram1_id]) begin bstate <= BIDLE; dram1 <= `DRAMREQ_READY; end
  default:	if (iq_stomp[dram0_id]) begin bstate <= BIDLE; dram0 <= `DRAMREQ_READY; end
  endcase
end
endtask


// Bypassing between functional units. There is only bypassing of integer and 
// floating-point units.
// Most of the time i is hard-coded as false and there is no immediate to bypass.
task bypass;
input i;
input [VWID-1:0] imm;
input v;
input [`RBITS] src;
input [VWID-1:0] arg;
output [VWID-1:0] o;
begin
`ifdef FU_BYPASS
	if (i)
		o = imm[VWID-1:0];
	else if (v)
		o = arg[VWID-1:0];
	else
		case(src)
		alu0_rid:	o = ralu0_bus[VWID-1:0];
		alu1_rid:	o = ralu1_bus[VWID-1:0];
		fpu1_rid:	o = rfpu1_bus[VWID-1:0];
		fpu2_rid:	o = rfpu2_bus[VWID-1:0];
		default:	o = {16{16'hDEAD}};
		endcase
`else
	if (i)
		o = imm;
	else
		o = arg[VWID-1:0];
`endif                 
end
endtask

task bypass128;
input i;
input [127:0] imm;
input v;
input [`RBITS] src;
input [127:0] arg;
output [127:0] o;
begin
`ifdef FU_BYPASS
	if (i)
		o = imm[127:0];
	else if (v)
		o = arg[127:0];
	else
		case(src)
		alu0_rid:	o = ralu0_bus[127:0];
		alu1_rid:	o = ralu1_bus[127:0];
		fpu1_rid:	o = rfpu1_bus[127:0];
		fpu2_rid:	o = rfpu2_bus[127:0];
		default:	o = {16{16'hDEAD}};
		endcase
`else
	if (i)
		o = imm;
	else
		o = arg[127:0];
`endif                 
end
endtask

task bypass32;
input i;
input [31:0] imm;
input v;
input [`RBITS] src;
input [31:0] arg;
output [31:0] o;
begin
`ifdef FU_BYPASS
	if (i)
		o = imm[31:0];
	else if (v)
		o = arg[31:0];
	else
		case(src)
		alu0_rid:	o = ralu0_bus[31:0];
		alu1_rid:	o = ralu1_bus[31:0];
		fpu1_rid:	o = rfpu1_bus[31:0];
		fpu2_rid:	o = rfpu2_bus[31:0];
		default:	o = {16{16'hDEAD}};
		endcase
`else
	if (i)
		o = imm;
	else
		o = arg[31:0];
`endif                 
end
endtask

// Check if the core is no longer issuing to a functional unit and set it's
// rid to the non-issue value. This is checked for every instance of an
// issue.
task check_issue;
input [6:0] pat;
begin
	if (alu0_rid==n[`QBITS] && !issuing_on_alu0 && pat[0])
		alu0_rid <= {`QBIT{1'b1}};
	if (alu1_rid==n[`QBITS] && !issuing_on_alu1 && pat[1])
		alu1_rid <= {`QBIT{1'b1}};
	if (fpu1_rid==n[`QBITS] && !issuing_on_fpu1 && pat[2])
		fpu1_rid <= {`QBIT{1'b1}};
	if (fpu2_rid==n[`QBITS] && !issuing_on_fpu2 && pat[3])
		fpu2_rid <= {`QBIT{1'b1}};
	if (agen0_rid==n[`QBITS] && !issuing_on_agen0 && pat[4])
		agen0_rid <= {`QBIT{1'b1}};
	if (agen1_rid==n[`QBITS] && !issuing_on_agen1 && pat[5])
		agen1_rid <= {`QBIT{1'b1}};
	if (fcu_rid==n[`QBITS] && !issuing_on_fcu && pat[6])
		fcu_rid <= {`QBIT{1'b1}};
end
endtask

// Check for units that should no longer be ready.
// If issuing to the same queue slot as a "ready" functional unit make that
// functional unit unready.
task check_done;
input [`QBITS] id;
begin
/*
	if (id==alu0_id && !issuing_on_alu0)
		alu0_dataready = FALSE;
	if (id==alu1_id && !issuing_on_alu1)
		alu1_dataready = FALSE;
	if (n==agen0_id && !issuing_on_agen0)
		agen0_dataready = FALSE;
	if (id==agen1_id && !issuing_on_agen1)
		agen1_dataready = FALSE;
	if (id==fpu1_id && !issuing_on_fpu1)
		fpu1_dataready = FALSE;
	if (id==fpu2_id && !issuing_on_fpu2)
		fpu2_dataready = FALSE;
	if (id==fcu_id && !issuing_on_fcu)
		fcu_dataready = FALSE;
*/
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
			|| (heads[n]==tails[2] && queuedCnt==3'd3)
			|| (heads[n]==tails[3] && queuedCnt==3'd4)
			)) begin
				iq_state[heads[n]] <= IQS_INVALID;
				iq_mem[heads[n]] <= `FALSE;
				iq_alu[heads[n]] <= `FALSE;
				iq_fc[heads[n]] <= `FALSE;
				iq_fpu[heads[n]] <= `FALSE;
//				if (alu0_id==heads[n] && iq_state[alu0_id]==IQS_CMT
//					&& !issuing_on_alu0)
//					alu0_dataready <= `FALSE;
//				if (alu1_id==heads[n] && iq_state[alu1_id]==IQS_CMT
//					&& !issuing_on_alu1)
//					alu1_dataready <= `FALSE;
//					$display("head_inc: IQS_INVALID[%d]",heads[n]);
			end
		end
	for (n = 0; n < QENTRIES; n = n + 1)
		if (iq_v[n])
			iq_sn[n] <= iq_sn[n] - tosub;
end
endtask

// If incrementing by 1/2 then the first result in the rob entry was committed,
// but the second one wasn't. So leave the rob entry as valid and allow the
// commit to try again on the next cycle.
task rob_head_inc;
input [`RBITSP1] amt;
begin
	for (n = 0; n < RENTRIES; n = n + 1)
		if (n < amt) begin
			
			if (!((rob_heads[n][`RBITS]==rob_tails[0] && queuedCnt==3'd1)
				|| (rob_heads[n][`RBITS]==rob_tails[1] && queuedCnt==3'd2)
				|| (rob_heads[n][`RBITS]==rob_tails[2] && queuedCnt==3'd3)
				|| (rob_heads[n][`RBITS]==rob_tails[3] && queuedCnt==3'd4)
				)) begin
				
//					rob_state[rob_heads[n]] <= RS_INVALID;
					//iq_state[rob_id[rob_heads[n]]] <= IQS_INVALID;
					$display("rob_head_inc: IQS_INVALID[%d]",rob_id[rob_heads[n]]);
					rob_state[rob_heads[n]] <= RS_INVALID;
			end
		end
	CC <= CC + amt;
end
endtask

task setargs;
input [`QBITS] nn;
input [`RBITSP1] id;
input v;
input [VWID-1:0] bus;
begin
  if (iq_argA_v[nn] == `INV && iq_argA_s[nn][`RBITSP1] == id && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argA[nn] <= bus;
		iq_argA_v[nn] <= `VAL;
  end
  if (iq_argB_v[nn] == `INV && iq_argB_s[nn][`RBITSP1] == id && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argB[nn] <= bus;
		iq_argB_v[nn] <= `VAL;
  end
  if (iq_argC_v[nn] == `INV && iq_argC_s[nn][`RBITSP1] == id && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argC[nn] <= bus;
		iq_argC_v[nn] <= `VAL;
  end
  if (iq_argD_v[nn] == `INV && iq_argD_s[nn][`RBITSP1] == id && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argD[nn] <= bus;
		iq_argD_v[nn] <= `VAL;
  end
  if (iq_argT_v[nn] == `INV && iq_argT_s[nn][`RBITSP1] == id && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argT[nn] <= bus;
		iq_argT_v[nn] <= `VAL;
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

// Note that the register source id is set to the qid for now, until a ROB 
// entry is assigned. The rid will be looked up when the ROB entry is
// assigned.
task arg_vs;
input [QSLOTS-1:0] pat;
begin
	for (row = 0; row < QSLOTS; row = row + 1) begin
		if (pat[row]) begin
			iq_argA_v [tails[tails_rc(pat,row)]] <= regIsValid[Rs1[row]] | Source1Valid(insnx[row]);
			iq_argA_s [tails[tails_rc(pat,row)]] <= rf_source[Rs1[row]];
			iq_argB_v [tails[tails_rc(pat,row)]] <= regIsValid[Rs2[row]] | Source2Valid(insnx[row]);
			iq_argB_s [tails[tails_rc(pat,row)]] <= rf_source[Rs2[row]];
			iq_argC_v [tails[tails_rc(pat,row)]] <= regIsValid[Rs3[row]] | Source3Valid(insnx[row]);
			iq_argC_s [tails[tails_rc(pat,row)]] <= rf_source[Rs3[row]];
			iq_argD_v [tails[tails_rc(pat,row)]] <= regIsValid[Rs4[row]] | Source4Valid(insnx[row]);
			iq_argD_s [tails[tails_rc(pat,row)]] <= rf_source[Rs4[row]];
			iq_argT_v [tails[tails_rc(pat,row)]] <= regIsValid[Rd[row]] | SourceTValid(insnx[row]);
			iq_argT_s [tails[tails_rc(pat,row)]] <= rf_source[Rd[row]];
			for (col = 0; col < QSLOTS; col = col + 1) begin
				if (col < row) begin
					if (pat[col]) begin
						// Special checking for condition register sideways slice
						if (Rs1[row] >= 7'b1110000 && Rs1[row] <= 7'b1110111 && Rd[col]==7'd125 && slot_rfw[col]) begin
							iq_argA_v [tails[tails_rc(pat,row)]] <= Source1Valid(insnx[row]);
							iq_argA_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end
						else if (Rs1[row]==Rd[col] && Rs1[row]!=7'b0000000 && Rs1[row] != 7'b0100000 && Rs1[row] != 7'b1000000 && slot_rfw[col]) begin
							iq_argA_v [tails[tails_rc(pat,row)]] <= Source1Valid(insnx[row]);
							iq_argA_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end

						if (Rs2[row] >= 7'b1110000 && Rs2[row] <= 7'b1110111 && Rd[col]==7'd125 && slot_rfw[col]) begin
							iq_argA_v [tails[tails_rc(pat,row)]] <= Source2Valid(insnx[row]);
							iq_argA_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end
						else if (Rs2[row]==Rd[col] && Rs2[row]!=7'b0000000 && Rs2[row] != 7'b0100000 && Rs2[row] != 7'b1000000 && slot_rfw[col]) begin
							iq_argB_v [tails[tails_rc(pat,row)]] <= Source2Valid(insnx[row]);
							iq_argB_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end

						if (Rs3[row]==Rd[col] && Rs3[row]!=7'b0000000 && Rs3[row] != 7'b0100000 && Rs3[row] != 7'b1000000 && slot_rfw[col]) begin
							iq_argC_v [tails[tails_rc(pat,row)]] <= Source3Valid(insnx[row]);
							iq_argC_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end
						if (Rs4[row]==Rd[col] && slot_rfw[col]) begin
							iq_argD_v [tails[tails_rc(pat,row)]] <= Source4Valid(insnx[row]);
							iq_argD_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end
						// For vector instructions the target register needs to be read and might have dependencies.
						if (Rd[row]==Rd[col] && Rd[row]!=7'b0000000 && Rd[row] != 7'b0100000 && Rd[row] != 7'b1000000 && slot_rfw[col]) begin
							iq_argT_v [tails[tails_rc(pat,row)]] <= SourceTValid(insnx[row]);
							iq_argT_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end
					end
				end
			end
		end
	end
end
endtask

task set_insn;
input [`QBITS] nn;
input [`IBTOP:0] bus;
begin
	if (bus[`IB_PFXINSN])
		case(bus[`IB_PFX])
		1'd0:	iq_argI[nn] <= bus[`IB_CONST];
		1'd1:	iq_argI[nn] <= {iq_argI[(nn+`QENTRIES-1) % `QENTRIES],bus[`IB_CONST31]};
		endcase
	else
		case(bus[`IB_PFX])
		1'd0:	iq_argI[nn] <= bus[`IB_CONST];
		1'd1: iq_argI[nn] <= {iq_argI[(nn+`QENTRIES-1) % `QENTRIES],bus[`IB_CONST19]};
		endcase
	iq_imm  [nn]  <= bus[`IB_IMM];
	iq_cmp	 [nn]  <= bus[`IB_CMP];
	iq_tlb  [nn]  <= bus[`IB_TLB];
	iq_fmt   [nn]  <= bus[`IB_FMT];
	iq_z		[nn]  <= bus[`IB_Z];
	iq_vset [nn]  <= bus[`IB_VSET];
	iq_chk  [nn]  <= bus[`IB_CHK];
	iq_rex  [nn]	<= bus[`IB_REX];
	iq_jrl	 [nn]  <= bus[`IB_JRL];
	iq_rts  [nn]  <= bus[`IB_RTS];
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
	iq_pushc [nn]  <= bus[`IB_PUSHC];
	iq_pop   [nn]  <= bus[`IB_POP];
	iq_oddball[nn] <= bus[`IB_ODDBALL];
	iq_memsz[nn]  <= bus[`IB_MEMSZ];
	iq_mem  [nn]  <= bus[`IB_MEM];
	iq_mem2 [nn]  <= bus[`IB_MEM2];
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
input [`SNBITS] seqnum;
input [`IBTOP:0] id_bus;
input [`QBITS] btag;
input [`RBITS] rid;
begin
	iq_rid[ndx] <= rid;
	iq_sn[ndx] <= seqnum;
	iq_state[ndx] <= IQS_QUEUED;
	iq_br_tag[ndx] <= btag;
	case(slot)
	3'd0:	iq_ip[ndx] <= {ipd[AMSB:2],2'b00};
	3'd1:	iq_ip[ndx] <= {ipd[AMSB:2],2'b01};
	3'd2:	iq_ip[ndx] <= {ipd[AMSB:2],2'b10};
	3'd3:	iq_ip[ndx] <= {ipd[AMSB:2],2'b11};
	endcase
	if (iq_pfx[ndx])
		iq_ip[ndx] <= iq_ip[(ndx + QENTRIES - 1) % QENTRIES];
	iq_instr[ndx] <= insnx[slot];
	iq_argA[ndx] <= argA[slot];
	iq_argB[ndx] <= argB[slot];
	iq_argC[ndx] <= argC[slot];
	iq_argD[ndx] <= argD[slot];
	iq_argT[ndx] <= argT[slot];
	iq_argA_v[ndx] <= regIsValid[Rs1[slot]] || Source1Valid(insnx[slot]);
	iq_argB_v[ndx] <= regIsValid[Rs2[slot]] || Source2Valid(insnx[slot]);
	iq_argC_v[ndx] <= regIsValid[Rs3[slot]] || Source3Valid(insnx[slot]);
	iq_argD_v[ndx] <= regIsValid[Rs4[slot]] || Source4Valid(insnx[slot]);
	iq_argT_v[ndx] <= regIsValid[Rd[slot]] || SourceTValid(insnx[slot]);
	iq_argA_s[ndx] <= rf_source[Rs1[slot]];
	iq_argB_s[ndx] <= rf_source[Rs2[slot]];
	iq_argC_s[ndx] <= rf_source[Rs3[slot]];
	iq_argD_s[ndx] <= rf_source[Rs4[slot]];
	iq_argT_s[ndx] <= rf_source[Rd[slot]];
	iq_pt[ndx] <= predict_taken[slot];
	iq_tgt[ndx] <= Rd[slot];
	iq_crtgt[ndx] <= Crd[slot];
	set_insn(ndx,id_bus);
	// Some updates depend on instructions decoded at commit time.
	rob_instr[rid] <= insnx[slot];
	case(slot)
	3'd0:	rob_ip[rid] <= {ipd[AMSB:2],2'b00};
	3'd1:	rob_ip[rid] <= {ipd[AMSB:2],2'b01};
	3'd2:	rob_ip[rid] <= {ipd[AMSB:2],2'b10};
	3'd3:	rob_ip[rid] <= {ipd[AMSB:2],2'b11};
	endcase
	if (iq_pfx[ndx])
		rob_ip[rid] <= iq_ip[(ndx + QENTRIES - 1) % QENTRIES];
	rob_res[rid] <= 1'd0;
	rob_status[rid] <= 1'd0;
	rob_state[rid] <= RS_ASSIGNED;
	rob_id[rid] <= ndx;
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
input [`RBITS] head;
input [1:0] which;
reg thread;
begin
  if (v) begin
    if (|rob_exc[head]) begin
    	exc(head,thread,iq_exc[head]);
    end
		else
			case(rob_instr[head][`OPCODE])
			`BMISC:
				case(rob_instr[head][`BFUNCT4])
				`BRK:   
      		// BRK is treated as a nop unless it's a software interrupt or a
      		// hardware interrupt at a higher priority than the current priority.
          if ((|rob_instr[head][25:21]) || rob_instr[head][20:17] > im) begin
            excmiss <= TRUE;
            im_stack <= {im_stack[27:0],4'hF};
            ol_stack <= {ol_stack[13:0],2'b00};
            dl_stack <= {dl_stack[13:0],2'b00};
        		excmissip <= {tvec[3'd0][AMSB:8],1'b0,ol,5'h00};
            ipc0 <= rob_ip[head] + {rob_instr[head][25:21],1'b0};
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
            cause[3'd0] <= rob_res[head][11:4];
            mstatus[5:4] <= 2'd0;
            mstatus[13:6] <= 8'h00;
            // For hardware interrupts only, set a new mask level. Setting a
            // new mask level will effectively prevent subsequent brks that
            // are streaming from an interrupt from being processed.
            // Select register set according to interrupt level
            if (rob_instr[head][25:21]==5'd0) begin
              mstatus[ 3: 0] <= rob_instr[head][20:17];
              mstatus[31:28] <= rob_instr[head][20:17];
              mstatus[19:14] <= {2'b0,rob_instr[head][20:17]};
              rs_stack[5:0] <= {2'b0,rob_instr[head][20:17]};
              brs_stack[5:0] <= {2'b0,rob_instr[head][20:17]};
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
        `BMISC2:
          case(rob_instr[head][`FUNCT5])
          `SEI:   mstatus[3:0] <= rob_res[head][7:4];   // S1
          `RTI:   begin
	            excmiss <= TRUE;
    					excmissip <= rob_ma[head];
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
              sema[rob_res[head][9:4]] <= 1'b0;
`ifdef SUPPORT_DBG                    
	              dbg_ctrl[62:55] <= {FALSE,dbg_ctrl[62:56]}; 
	              dbg_ctrl[63] <= dbg_ctrl[55];
`endif                    
              end
	        `REX:
            if (ol < rob_instr[head][14:13]) begin
                mstatus[5:4] <= rob_instr[head][14:13];
                badaddr[{1'b0,rob_instr[head][14:13]}] <= badaddr[{1'b0,ol}];
                bad_instr[{1'b0,rob_instr[head][14:13]}] <= bad_instr[{1'b0,ol}];
                cause[{1'b0,rob_instr[head][14:13]}] <= cause[{1'b0,ol}];
                mstatus[13:6] <= rob_instr[head][25:18] | iq_argA[head][11:4];
            end
          default: ;
          endcase
        `CACHE:
        		begin
	            case(rob_instr[head][19:18])
	            3'h1:	begin invicl <= TRUE; invlineAddr <= {rob_res[head][WID+3:4]}; end
	            3'h2:  	invic <= TRUE;
	            default:	;
	          	endcase
	            case(rob_instr[head][22:20])
	            3'h1:  cr0[30] <= TRUE;
	            3'h2:  cr0[30] <= FALSE;
	            3'd3:		invdcl <= TRUE;
	            3'h4:		invdc <= TRUE;
	            default:    ;
	            endcase
		          end
        `CSRRW:
        		begin
        		write_csr(rob_instr[head][39:37],{rob_instr[head][36:35],rob_instr[head][29:18]},rob_argA[head][WID-1:0],thread);
        		end
        `FLT1:
					case(rob_instr[head][`FFUNCT5])
					`FRM: begin  
								fp_rm <= rob_res[head][6:4];
								end
          `FCX:
              begin
                  fp_sx <= fp_sx & ~rob_res[head][9];
                  fp_inex <= fp_inex & ~rob_res[head][8];
                  fp_dbzx <= fp_dbzx & ~(rob_res[head][7]|rob_res[head][4]);
                  fp_underx <= fp_underx & ~rob_res[head][6];
                  fp_overx <= fp_overx & ~rob_res[head][5];
                  fp_giopx <= fp_giopx & ~rob_res[head][4];
                  fp_infdivx <= fp_infdivx & ~rob_res[head][4];
                  fp_zerozerox <= fp_zerozerox & ~rob_res[head][4];
                  fp_subinfx   <= fp_subinfx   & ~rob_res[head][4];
                  fp_infzerox  <= fp_infzerox  & ~rob_res[head][4];
                  fp_NaNCmpx   <= fp_NaNCmpx   & ~rob_res[head][4];
                  fp_swtx <= 1'b0;
              end
          `FDX:
              begin
                  fp_inexe <= fp_inexe     & ~rob_res[head][8];
                  fp_dbzxe <= fp_dbzxe     & ~rob_res[head][7];
                  fp_underxe <= fp_underxe & ~rob_res[head][6];
                  fp_overxe <= fp_overxe   & ~rob_res[head][5];
                  fp_invopxe <= fp_invopxe & ~rob_res[head][4];
              end
          `FEX:
              begin
                  fp_inexe <= fp_inexe     | rob_res[head][8];
                  fp_dbzxe <= fp_dbzxe     | rob_res[head][7];
                  fp_underxe <= fp_underxe | rob_res[head][6];
                  fp_overxe <= fp_overxe   | rob_res[head][5];
                  fp_invopxe <= fp_invopxe | rob_res[head][4];
              end
            default:	;
            endcase
          default:
            begin
                // 31 to 29 is rounding mode
                // 28 to 24 are exception enables
                // 23 is nsfp
                // 22 is a fractie
                fp_fractie <= rob_status[head][22];
                fp_raz <= rob_status[head][21];
                // 20 is a 0
                fp_neg <= rob_status[head][19];
                fp_pos <= rob_status[head][18];
                fp_zero <= rob_status[head][17];
                fp_inf <= rob_status[head][16];
                // 15 swtx
                // 14 
                fp_inex <= fp_inex | (fp_inexe & rob_status[head][14]);
                fp_dbzx <= fp_dbzx | (fp_dbzxe & rob_status[head][13]);
                fp_underx <= fp_underx | (fp_underxe & rob_status[head][12]);
                fp_overx <= fp_overx | (fp_overxe & rob_status[head][11]);
                //fp_giopx <= fp_giopx | (fp_giopxe & iq_res2[head][10]);
                //fp_invopx <= fp_invopx | (fp_invopxe & iq_res2[head][24]);
                //
                fp_cvtx <= fp_cvtx |  (fp_giopxe & rob_status[head][7]);
                fp_sqrtx <= fp_sqrtx |  (fp_giopxe & rob_status[head][6]);
                fp_NaNCmpx <= fp_NaNCmpx |  (fp_giopxe & rob_status[head][5]);
                fp_infzerox <= fp_infzerox |  (fp_giopxe & rob_status[head][4]);
                fp_zerozerox <= fp_zerozerox |  (fp_giopxe & rob_status[head][3]);
                fp_infdivx <= fp_infdivx | (fp_giopxe & rob_status[head][2]);
                fp_subinfx <= fp_subinfx | (fp_giopxe & rob_status[head][1]);
                fp_snanx <= fp_snanx | (fp_giopxe & rob_status[head][0]);

            end
          endcase
        endcase
        // Once the flow control instruction commits, NOP it out to allow
        // pending stores to be issued.
        rob_instr[head] <= `NOP_INSN;
    end
end
endtask

task write_csr;
input [2:0] csrop;
input [13:0] csrno;
input [127:0] dat;
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
		check_issue(7'b1111111);
		dram0 		<= `DRAMSLOT_BUSY;
		dram0_id 	<= n[`QBITS];
		dram0_rid <= iq_rid[n];
		dram0_instr <= iq_instr[n];
		dram0_rmw  <= iq_rmw[n];
		dram0_preload <= iq_preload[n];
		dram0_tgt 	<= iq_tgt[n];
		// These two args needed only to support AMO operations
		dram0_argI	<= {{68{iq_instr[n][27]}},iq_instr[n][27:16]};
		// argB must have been valid for the memory instruction to issue.
		dram0_argB <= iq_argB[n];
		if (iq_imm[n] & iq_pushc[n])
			dram0_data <= iq_argI[n];
		else if (iq_stpair[n])
			dram0_data <= {iq_argC[n][127:0],iq_argB[n][127:0]};
		else
			dram0_data <= iq_argB[n][WID-1:0];
		dram0_addr	<= iq_ma[n];
		dram0_unc   <= iq_ma[n][31:20]==12'hFFD || !dce;
		dram0_memsize <= iq_memsz[n];
		dram0_load <= iq_load[n];
		dram0_store <= iq_store[n];
		dram0_ol   <= (iq_rs1[n][RBIT:0]==7'd31 || iq_rs1[n][RBIT:0]==7'd30) ? ol : dl;
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
		check_issue(7'b1111111);
//	dramB_v <= `INV;
		dram1 		<= `DRAMSLOT_BUSY;
		dram1_id 	<= n[`QBITS];
		dram1_rid <= iq_rid[n];
		dram1_instr <= iq_instr[n];
		dram1_rmw  <= iq_rmw[n];
		dram1_preload <= iq_preload[n];
		dram1_tgt 	<= iq_tgt[n];
		// These two args needed only to support AMO operations
		dram1_argI	<= {{68{iq_instr[n][27]}},iq_instr[n][27:16]};
		// argB must have been valid for the memory instruction to issue.
		dram1_argB <= iq_argB[n];
		if (iq_imm[n] & iq_pushc[n])
			dram1_data <= iq_argI[n];
		else if (iq_stpair[n])
			dram1_data <= {iq_argC[n][127:0],iq_argB[n][127:0]};
		else
			dram1_data <= iq_argB[n][WID-1:0];
		dram1_addr	<= iq_ma[n];
		//	             if (ol[iq_thrd[n]]==`OL_USER)
		//	             	dram1_seg   <= (iq_rs1[n]==5'd30 || iq_rs1[n]==5'd31) ? {ss[iq_thrd[n]],13'd0} : {ds[iq_thrd[n]],13'd0};
		//	             else
		dram1_unc   <= iq_ma[n][31:20]==12'hFFD || !dce;
		dram1_memsize <= iq_memsz[n];
		dram1_load <= iq_load[n];
		dram1_store <= iq_store[n];
		dram1_ol   <= (iq_rs1[n][RBIT:0]==7'd31 || iq_rs1[n][RBIT:0]==7'd30) ? ol : dl;
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

