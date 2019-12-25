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
// 81708 130733
// 85699 137118
// 101049 166478 (with queue bypassing network)
`include "..\common\Gambit-config.sv"
`include "..\common\Gambit-types.sv"
`include "..\common\Gambit-defines.sv"

module Gambit(rst_i, clk_i, clk2x_i, clk4x_i, tm_clk_i, nmi_i, irq_i,
		bte_o, cti_o, bok_i, cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_o, dat_i,
    icl_o, exc_o);
parameter WID = 52;
input rst_i;
input clk_i;
input clk2x_i;
input clk4x_i;
input tm_clk_i;
input nmi_i;
input irq_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
input bok_i;
output cyc_o;
output reg stb_o;
input ack_i;
input err_i;
output we_o;
output reg [7:0] sel_o;
output [`ABITS] adr_o;
output reg [103:0] dat_o;
input [103:0] dat_i;
output icl_o;
output [7:0] exc_o;
parameter TM_CLKFREQ = 20000000;
parameter UOQ_ENTRIES = `UOQ_ENTRIES;
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter QSLOTS = `QSLOTS;
parameter FSLOTS = `FSLOTS;
parameter RENTRIES = `RENTRIES;
parameter RSLOTS = `RSLOTS;
parameter AREGS = 32;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;
parameter VAL = 1'b1;
parameter INV = 1'b0;
parameter RSTIP = 52'hFFFFFFFFC0000;
parameter BRKIP = 52'hFFFFFFFFFFFFC;
parameter DEBUG = 1'b0;
parameter DBW = 16;
parameter ABW = 52;
parameter AMSB = ABW-1;
parameter RBIT = 4;
parameter WB_DEPTH = 7;

// Memory access sizes
parameter octa = 4'd0;
parameter byt = 4'd1;
parameter wyde = 4'd2;
parameter tbyt = 4'd3;
parameter tetra = 4'd4;
parameter ubyt = 4'd5;
parameter uwyde = 4'd6;
parameter utbyt = 4'd7;
parameter utetra = 4'd8;

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

`include "..\common\Micro-op_Engine\Gambit-micro-program-parameters.sv"
`include "..\common\Gambit-busStates.sv"

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

reg [31:0] rst_ctr;
reg [7:0] i;
integer n;
integer j, k;
integer row, col;
genvar g, h;

reg [WID-1:0] regs [0:31];
reg [WID-1:0] regsx [0:31];
initial begin
	for (n = 0; n < 32; n = n + 1) begin
		regsx[n] = 1'd0;
		regs[n] = 1'd0;
	end
end
reg [15:0] sr;
reg sre;
reg [15:0] srx;
reg srex;

wire [AMSB:0] pc;
wire [AMSB:0] pcd;
reg [31:0] tick;

reg [WID-1:0] rfoa [0:QSLOTS-1];
reg [WID-1:0] rfob [0:QSLOTS-1];
reg [WID-1:0] rfot [0:QSLOTS-1];
reg [ 7:0] rfos [0:QSLOTS-1];

// Register read ports
reg [5:0] Rd [0:QSLOTS-1];
reg [5:0] Rn [0:QSLOTS-1];
reg [5:0] Ra [0:QSLOTS-1];
reg [5:0] RdReal [0:QSLOTS-1];
reg [5:0] RnReal [0:QSLOTS-1];
reg [5:0] RaReal [0:QSLOTS-1];


wire tlb_miss;
wire exv;

reg q1, q2, q1b, q1bx;	// number of macro instructions queued
reg qb;						// queue a brk instruction


reg [143:0] ic1_out;
reg [51:0] ic2_out;

reg  [3:0] panic;		// indexes the message structure
reg [127:0] message [0:15];	// indexed by panic

wire int_commit;

reg [103:0] xdati;

reg [31:0] uop_queued;
reg [31:0] ins_queued;
reg [31:0] ins_stomped;
reg [31:0] ins_committed;
reg [31:0] uop_stomped;
wire [31:0] uop_committed;
reg [31:0] ic_stalls;
reg [31:0] br_override;
reg [31:0] br_total;
reg [31:0] br_missed;

wire [2:0] queuedCnt;
wire [2:0] rqueuedCnt;
reg queuedNop;
reg [2:0] hi_amt;
reg [2:0] r_amt, r_amt2;
wire [`SNBITS] tosub;

wire [2:0] iclen1;
reg [2:0] len1, len2, len1d, len2d;
reg [51:0] insnx [0:1];

wire [`QBITS] tails [0:QSLOTS-1];
wire [`QBITS] heads [0:IQ_ENTRIES-1];
wire [`RBITS] rob_tails [0:RSLOTS-1];
wire [`RBITS] rob_heads [0:RENTRIES-1];
wire [FSLOTS-1:0] slotvd, pc_maskd, pc_mask;

// Micro instruction pointers.
reg [7:0] mip1, mip2;
wire nextBundle;

// Micro-op queue
reg [UOQ_ENTRIES-1:0] uoq_v;
reg [WID-1:0] uoq_pc [0:UOQ_ENTRIES-1];
reg [2:0] uoq_ilen [0:UOQ_ENTRIES-1];
MicroOp uoq_uop [0:UOQ_ENTRIES-1];
reg [51:0] uoq_inst [0:UOQ_ENTRIES-1];
reg [3:0] uoq_size [0:UOQ_ENTRIES-1];
reg [51:0] uoq_const [0:UOQ_ENTRIES-1];
reg [1:0] uoq_fl [0:UOQ_ENTRIES-1];		// first or last micro-op
reg [6:0] uoq_flagsupd [0:UOQ_ENTRIES-1];
reg [4:0] uoq_Ra [0:UOQ_ENTRIES-1];
reg [4:0] uoq_Rb [0:UOQ_ENTRIES-1];
reg [4:0] uoq_Rt [0:UOQ_ENTRIES-1];
reg [UOQ_ENTRIES-1:0] uoq_rfw;
reg [UOQ_ENTRIES-1:0] uoq_hs;
reg [UOQ_ENTRIES-1:0] uoq_jc;
reg [UOQ_ENTRIES-1:0] uoq_takb;

// Issue queue
reg [IQ_ENTRIES-1:0] iq_v;						// valid indicator (set from iq_state)
reg [IQ_ENTRIES-1:0] iq_done;
reg [IQ_ENTRIES-1:0] iq_out;
reg [IQ_ENTRIES-1:0] iq_agen;
reg [2:0] iq_state [0:IQ_ENTRIES-1];
reg [`SNBITS] iq_sn  [0:IQ_ENTRIES-1];		// sequence number
reg [WID-1:0] iq_pc [0:IQ_ENTRIES-1];	// program counter associated with instruction
reg [2:0] iq_len [0:IQ_ENTRIES-1];
reg [IQ_ENTRIES-1:0] iq_canex;
reg [`ABITS] iq_ma [0:IQ_ENTRIES-1];		// memory address
reg [5:0] iq_instr [0:IQ_ENTRIES-1];	// micro-op instruction
reg [1:0] iq_fl [0:IQ_ENTRIES-1];			// first or last indicators
reg [WID-1:0] iq_const [0:IQ_ENTRIES-1];
reg [IQ_ENTRIES-1:0] iq_hs;						// hardware (1) or software (0) interrupt
reg [IQ_ENTRIES-1:0] iq_alu = 1'h0;  	// alu type instruction
reg [IQ_ENTRIES-1:0] iq_mem;	// touches memory: 1 if LW/SW
reg [2:0] iq_memsz [0:IQ_ENTRIES-1];
reg [IQ_ENTRIES-1:0] iq_wrap;
reg [IQ_ENTRIES-1:0] iq_load;	// is a memory load instruction
reg [IQ_ENTRIES-1:0] iq_store;	// is a memory store instruction
reg [22:0] iq_sel [0:IQ_ENTRIES-1];		// select lines, for memory overlap detect
reg [IQ_ENTRIES-1:0] iq_bt;						// branch taken
reg [IQ_ENTRIES-1:0] iq_pt;						// predicted taken branch
reg [IQ_ENTRIES-1:0] iq_fc;						// flow control instruction
reg [IQ_ENTRIES-1:0] iq_jmp;					// changes control flow: 1 if BEQ/JALR
reg [IQ_ENTRIES-1:0] iq_cmp;
reg [IQ_ENTRIES-1:0] iq_br;						// branch instruction
reg [IQ_ENTRIES-1:0] iq_takb;
reg [IQ_ENTRIES-1:0] iq_rfw;	// writes to register file
reg [IQ_ENTRIES-1:0] iq_sei;
reg [IQ_ENTRIES-1:0] iq_need_sr;
reg [3:0] iq_src1 [0:IQ_ENTRIES-1];
reg [2:0] iq_src2 [0:IQ_ENTRIES-1];
reg [2:0] iq_dst  [0:IQ_ENTRIES-1];
reg [3:0] iq_exc	[0:IQ_ENTRIES-1];	// only for branches ... indicates a HALT instruction
reg [RBIT+1:0] iq_tgt [0:IQ_ENTRIES-1];		// target register
reg [WID-1:0] iq_argA [0:IQ_ENTRIES-1];	// First argument
reg [WID-1:0] iq_argB [0:IQ_ENTRIES-1];	// Second argument
reg [ 7:0] iq_argS [0:IQ_ENTRIES-1];	// status register input
reg [`RBITS] iq_argA_s [0:IQ_ENTRIES-1];
reg [`RBITS] iq_argB_s [0:IQ_ENTRIES-1]; 
reg [`RBITS] iq_argS_s [0:IQ_ENTRIES-1];
reg [IQ_ENTRIES-1:0] iq_argA_v;
reg [IQ_ENTRIES-1:0] iq_argB_v;
reg [IQ_ENTRIES-1:0] iq_argS_v;
reg [IQ_ENTRIES-1:0] iq_uses_sr;		// instruction uses the status register (eg adc, php)
reg [7:0] iq_sr_tgts [0:IQ_ENTRIES-1];			// status register bits targeted
reg [`RBITS] iq_rid [0:IQ_ENTRIES-1];	// index of rob entry

// Re-order buffer
reg [RENTRIES-1:0] rob_v;
reg [`QBITS] rob_id [0:RENTRIES-1];	// instruction queue id that owns this entry
reg [1:0] rob_state [0:RENTRIES-1];
reg [`ABITS] rob_pc	[0:RENTRIES-1];	// program counter for this instruction
reg [5:0] rob_instr[0:RENTRIES-1];	// instruction opcode
reg [7:0] rob_exc [0:RENTRIES-1];
reg [`ABITS] rob_ma [0:RENTRIES-1];
reg [WID-1:0] rob_res [0:RENTRIES-1];
reg [7:0] rob_sr_res [0:RENTRIES-1];		// status register result
reg [RBIT:0] rob_tgt [0:RENTRIES-1];
reg [7:0] rob_sr_tgts [0:RENTRIES-1];
reg [RENTRIES-1:0] rob_rfw;

// debugging
initial begin
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	iq_argA_s[n] <= 1'd0;
	iq_argB_s[n] <= 1'd0;
	iq_argS_s[n] <= 1'd0;
end

reg [IQ_ENTRIES-1:0] iq_sr_source = {IQ_ENTRIES{1'b0}};
reg [IQ_ENTRIES-1:0] iq_source = {IQ_ENTRIES{1'b0}};
reg [IQ_ENTRIES-1:0] iq_source2 = {IQ_ENTRIES{1'b0}};
reg [IQ_ENTRIES-1:0] iq_imm;
reg [IQ_ENTRIES-1:0] iq_memready;
reg [IQ_ENTRIES-1:0] iq_memopsvalid;

reg [1:0] missued;
reg [7:0] last_issue0, last_issue1, last_issue2;
reg  [IQ_ENTRIES-1:0] iq_memissue;
reg [IQ_ENTRIES-1:0] iq_stomp;
reg [3:0] stompedOnRets;
reg [3:0] iq_fuid [0:IQ_ENTRIES-1];
reg  [IQ_ENTRIES-1:0] iq_alu0_issue;
reg  [IQ_ENTRIES-1:0] iq_alu1_issue;
reg  [IQ_ENTRIES-1:0] iq_agen0_issue;
reg  [IQ_ENTRIES-1:0] iq_agen1_issue;
reg  [IQ_ENTRIES-1:0] iq_id1issue;
reg  [IQ_ENTRIES-1:0] iq_id2issue;
reg  [IQ_ENTRIES-1:0] iq_id3issue;
reg [1:0] iq_mem_islot [0:IQ_ENTRIES-1];
reg [IQ_ENTRIES-1:0] iq_fcu_issue;

reg [AREGS-1:0] livetarget;
reg [AREGS-1:0] iq_livetarget [0:IQ_ENTRIES-1];
reg [AREGS-1:0] iq_latestID [0:IQ_ENTRIES-1];
reg [AREGS-1:0] iq_cumulative [0:IQ_ENTRIES-1];
wire  [AREGS-1:0] iq_out2 [0:IQ_ENTRIES-1];
wire  [AREGS-1:0] iq_out2a [0:IQ_ENTRIES-1];
reg [IQ_ENTRIES-1:0] iq_latest_sr_ID;

reg [FSLOTS-1:0] take_branch;
wire [FSLOTS-1:0] take_branchd;
reg [FSLOTS-1:0] take_branchq;
reg [`QBITS] active_tag;

reg         id1_v;
reg   [`QBITS] id1_id;
reg  [31:0] id1_instr;
reg         id1_pt;
reg   [5:0] id1_Rt;
wire [`IBTOP:0] id_bus [0:QSLOTS-1];

reg         id2_v;
reg   [`QBITS] id2_id;
reg  [31:0] id2_instr;
reg         id2_pt;
reg   [5:0] id2_Rt;

reg         id3_v;
reg   [`QBITS] id3_id;
reg  [31:0] id3_instr;
reg         id3_pt;
reg   [5:0] id3_Rt;

reg [`SNBITS] alu0_sn;
reg 				alu0_cmt;
wire				alu0_abort;
reg        alu0_ld;
reg        alu0_dataready;
wire       alu0_done = 1'b1;
wire       alu0_idle;
reg  [`QBITS] alu0_sourceid;
reg [`RBITS] alu0_rid;
reg [5:0] alu0_instr;
reg        alu0_mem;
reg        alu0_load;
reg        alu0_store;
reg        alu0_shft;
reg [RBIT:0] alu0_Ra;
reg [WID-1:0] alu0_argT;
reg [WID-1:0] alu0_argB;
reg [WID-1:0] alu0_argA;
reg [7:0] alu0_argS;
reg [WID-1:0] alu0_argI;	// only used by BEQ
reg [RBIT:0] alu0_tgt;
reg [`ABITS] alu0_pc;
reg [WID-1:0] alu0_bus;
wire [WID-1:0] alu0_out;
wire [7:0] alu0_sro;
reg [7:0] alu0_sr_tgts;
reg  [`QBITS] alu0_id;
(* mark_debug="true" *)
wire  [`XBITS] alu0_exc;
wire        alu0_v = alu0_dataready;
reg [`QBITS] alu0_id1;
reg [`QBITS] alu1_id1;
reg [WID-1:0] alu0_bus1;
reg [WID-1:0] alu1_bus1;
reg issuing_on_alu0;
reg alu0_dne = TRUE;

reg [`SNBITS] alu1_sn;
reg 				alu1_cmt;
wire				alu1_abort;
reg        alu1_ld;
reg        alu1_dataready;
wire       alu1_done = 1'b1;
wire       alu1_idle;
reg  [`QBITS] alu1_sourceid;
reg [`RBITS] alu1_rid;
reg [5:0] alu1_instr;
reg        alu1_mem;
reg        alu1_load;
reg        alu1_store;
reg        alu1_shft;
reg [RBIT:0] alu1_Ra;
reg [WID-1:0] alu1_argT;
reg [WID-1:0] alu1_argB;
reg [WID-1:0] alu1_argA;
reg [WID-1:0] alu1_argI;	// only used by BEQ
reg [7:0] alu1_argS;
reg [RBIT:0] alu1_tgt;
reg [`ABITS] alu1_pc;
reg [WID-1:0] alu1_bus;
wire [WID-1:0] alu1_out;
wire [7:0] alu1_sro;
reg [7:0] alu1_sr_tgts;
reg  [`QBITS] alu1_id;
wire  [`XBITS] alu1_exc;
wire        alu1_v = alu1_dataready;
reg alu1_v1;
wire alu1_vsn;
reg issuing_on_alu1;
reg alu1_dne = TRUE;

wire agen0_vsn;
wire agen0_idle;
reg [`SNBITS] agen0_sn;
reg [`QBITS] agen0_sourceid;
reg [`QBITS] agen0_id;
reg [`RBITS] agen0_rid;
reg [RBIT:0] agen0_tgt;
reg agen0_dataready;
wire agen0_v = agen0_dataready;
reg [2:0] agen0_unit;
reg [5:0] agen0_instr;
reg agen0_mem2;
reg [`ABITS] agen0_ma;
reg [WID-1:0] agen0_res;
reg [WID-1:0] agen0_argT, agen0_argB, agen0_argA, agen0_argI;
reg agen0_dne = TRUE;
reg agen0_stopString;
reg [11:0] agen0_bytecnt;
reg agen0_offset;
wire agen0_upd2;
reg [1:0] agen0_base;

wire agen1_vsn;
wire agen1_idle;
reg [`SNBITS] agen1_sn;
reg [`QBITS] agen1_sourceid;
reg [`QBITS] agen1_id;
reg [`RBITS] agen1_rid;
reg [RBIT:0] agen1_tgt;
reg agen1_dataready;
wire agen1_v = agen1_dataready;
reg [2:0] agen1_unit;
reg [5:0] agen1_instr;
reg agen1_mem2;
reg agen1_memdb;
reg agen1_memsb;
reg [`ABITS] agen1_ma;
reg [WID-1:0] agen1_res;
reg [WID-1:0] agen1_argT, agen1_argB, agen1_argA, agen1_argI;
reg agen1_dne = TRUE;
wire agen1_upd2;
reg [1:0] agen1_base;

reg [7:0] fccnt;
reg [47:0] waitctr;
reg 				fcu_cmt;
reg        fcu_ld;
reg        fcu_dataready;
reg        fcu_done;
reg         fcu_idle = 1'b1;
reg [`QBITS] fcu_sourceid;
reg [`RBITS] fcu_rid;
reg [5:0] fcu_instr;
reg [5:0] fcu_prevInstr;
reg  [2:0] fcu_insln;
reg        fcu_pt = 1'b0;			// predict taken
reg        fcu_branch;
reg [6:0] fcu_argS;
reg [WID-1:0] fcu_argT;
reg [WID-1:0] fcu_argA;
reg [WID-1:0] fcu_argB;
reg [WID-1:0] fcu_argC;
reg [WID-1:0] fcu_argI;
reg [RBIT:0] fcu_tgt;
reg [`ABITS] fcu_pc;
reg [`ABITS] fcu_nextpc;
reg [`ABITS] fcu_brdisp;
wire [WID-1:0] fcu_out;
reg [WID-1:0] fcu_bus;
reg [7:0] fcu_sr_bus;
reg [7:0] fcu_sr_tgts;
reg  [`QBITS] fcu_id;
reg   [`XBITS] fcu_exc;
wire        fcu_v = fcu_dataready;
reg        fcu_branchmiss;
reg fcu_branchhit;
reg  fcu_clearbm;
reg [`ABITS] fcu_misspc;
reg [`ABITS] misspc;
reg fcu_wait;
reg fcu_hs;	// hardware / software interrupt indicator
reg fcu_dne = TRUE;
wire fcu_takb;

// write buffer
wire [2:0] wb_ptr;
wire [WID-1:0] wb_data;
wire [`ABITS] wb_addr [0:WB_DEPTH-1];
wire [1:0] wb_ol;
wire [WB_DEPTH-1:0] wb_v;
wire wb_rmw;
wire [IQ_ENTRIES-1:0] wb_id;
wire [IQ_ENTRIES-1:0] wbo_id;
wire [7:0] wb_sel;
reg wb_en;
wire wb_hit0, wb_hit1;

wire freezepc;
reg phit;
reg phitd;

reg branchmiss = 1'b0;
wire branchmissd2;
reg branchhit = 1'b0;
reg  [`QBITS] missid;
reg [`SNBITS] misssn;

wire [1:0] issue_count;
reg [1:0] missue_count;
wire [IQ_ENTRIES-1:0] memissue;

wire        dram_avail;
reg	 [2:0] dram0;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [2:0] dram1;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg [WID-1:0] dram0_argI, dram0_argB;
reg [WID-1:0] dram0_data;
reg dram0_wrap;
reg [`ABITS] dram0_addr;
reg [5:0] dram0_instr;
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
reg [WID-1:0] dram1_argI, dram1_argB;
reg [WID-1:0] dram1_data;
reg dram1_wrap;
reg [`ABITS] dram1_addr;
reg [5:0] dram1_instr;
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
reg [7:0] dramA_sr_bus;
reg [7:0] dramA_sr_tgts = 8'h82;
reg        dramB_v;
reg  [`QBITS] dramB_id;
reg [`QBITS] dramB_rid;
reg [WID-1:0] dramB_bus;
reg [7:0] dramB_sr_bus;
reg [7:0] dramB_sr_tgts = 8'h82;

wire        outstanding_stores;
reg [47:0] I;		// instruction count
reg [47:0] CC;	// commit count

reg commit0_v;
reg [`RBITS] commit0_id;
reg [RBIT+1:0] commit0_tgt;
reg commit0_rfw;
reg [WID-1:0] commit0_bus;
reg [7:0] commit0_sr_bus;
reg [3:0] commit0_rid;
reg [7:0] commit0_sr_tgts;
reg commit1_v;
reg [`RBITS] commit1_id;
reg [RBIT+1:0] commit1_tgt;
reg commit1_rfw;
reg [WID-1:0] commit1_bus;
reg [7:0] commit1_sr_bus;
reg [3:0] commit1_rid;
reg [7:0] commit1_sr_tgts;
reg commit2_v;
reg [`RBITS] commit2_id;
reg [RBIT+1:0] commit2_tgt;
reg commit2_rfw;
reg [WID-1:0] commit2_bus;
reg [7:0] commit2_sr_bus;
reg [3:0] commit2_rid;
reg [7:0] commit2_sr_tgts;

reg [QSLOTS-1:0] queuedOn;
reg [IQ_ENTRIES-1:0] rqueuedOn;
wire [QSLOTS-1:0] queuedOnp;
wire [FSLOTS-1:0] predict_taken;
wire predict_taken0;
wire predict_taken1;
wire predict_taken2;
reg [QSLOTS-1:0] slot_rfw;
reg [7:0] slot_sr_tgts [0:QSLOTS-1];

reg [8:0] opcode1, opcode2;

task tskLd4;
input [3:0] ld4;
input [51:0] insn;
output [51:0] cnst;
begin
	case(ld4)
	ZERO:	cnst = 52'h0000;
	ONE:	cnst = 52'h0001;
	TWO:	cnst = 52'h0002;
	THREE:	cnst = 52'h0003;
	FOUR:		cnst = 52'h0004;
	REF4:		cnst = {{48{insn[12]}},insn[12:9]};
	REF17:	cnst = {{35{insn[25]}},insn[25:9]};
	REF46:	cnst = {6'd0,insn[51:6]};
	REF23:	cnst = {{29{insn[38]}},insn[38:16]};
	REF36:	cnst = {{16{insn[51]}},insn[51:16]};
	REF7:		cnst = insn[12:6];
	REF9:		cnst = insn[25] ? {{43{insn[24]}},insn[24:16]} : 52'd0;
	MFOUR:	cnst = 52'hFFFFFFFFFFFFC;
	default:	cnst = 52'h0000;
	endcase
end
endtask

wire [FSLOTS-1:0] slotv;
reg [QSLOTS-1:0] uoq_slotv;
reg [7:0] uoq_tail [0:7];
reg [7:0] uoq_head;

// Branch decodes, needed to guide the program counter logic.
wire [`FSLOTS-1:0] slot_rts;
wire [`FSLOTS-1:0] slot_br;
wire [`FSLOTS-1:0] slot_jc;
wire [`FSLOTS-1:0] slot_jcl;
wire [`FSLOTS-1:0] slot_brk;
wire [3:0] slot_pf [0:FSLOTS-1];
reg [7:0] slot_rtsx;
reg [7:0] slot_brx;
reg [7:0] slot_jcx;
reg [7:0] slot_jclx;
reg [7:0] slot_brkx;
reg [3:0] slot_pfx [0:7];


// Only scans up to eight ahead because that's all the room that might be
// needed (there could be more than eight available).
reg [4:0] uoq_room;
reg uoq_hitv; 
always @*
begin
//	if (uoq_tail[0] > uoq_head)
//		uoq_room = UOQ_ENTRIES - (uoq_tail[0] - uoq_head);
//	// If head and tail are the same, then either the queue is full or it's empty
//	// Detection of the queue full is done by checking a single entry for valid.
//	else if (uoq_head - uoq_tail[0] == 1'd0)
//		uoq_room = uoq_v[0] ? 5'd0 : UOQ_ENTRIES;
//	else
//		uoq_room = uoq_head - uoq_tail[0];
//end
	uoq_hitv = FALSE;
	uoq_room = 5'd0;
	for (n = 0; n < 8; n = n + 1)
		if (uoq_v[uoq_tail[n]] == `INV)
			uoq_room = uoq_room + 5'd1;
//		if (uoq_v[uoq_tail[n]] == `INV && !uoq_hitv)
//			uoq_room = uoq_room + 5'd1;
//		else
//			uoq_hitv = TRUE;
end

reg uoq_empty;
always @*
begin
	uoq_empty = TRUE;
	for (n = 0; n < `UOQ_ENTRIES; n = n + 1)
		if (uoq_v[n])
			uoq_empty <= FALSE;
end

// q1 and q2 determine the pc increment. The pc determines which instructions
// appear at the I$ output. q1 and q2 also determine how many micro-ops are
// placed in the queue.
/*
always @*
begin
	qb <= FALSE;
	uopQueued <= FALSE;
	if (phit|freezepc) begin
		if (uoq_room >= 3'd4)
			uopQueued <= TRUE;
	end
end
*/
always @(posedge clk_i)
if (rst_i) begin
	ic_stalls <= 0;
end
else begin
	if (!phit)
		ic_stalls <= ic_stalls + 2'd1;
end

always @(posedge clk_i)
if (rst_i) begin
	br_override <= 0;
end
else begin
	if (pc_override)
		br_override <= br_override + 2'd1;
end

always @*
begin
	if (uoq_head==uoq_tail[0]) begin
		if (&uoq_v)							// Is the queue full ?
			uoq_slotv <= 3'b111;	// If so all slots from the head are valid
		else if (~|uoq_v)				// Is the queue empty ?
			uoq_slotv <= 3'b000;
		else begin
			uoq_slotv[0] <= `VAL;
			uoq_slotv[1] <= ((uoq_head + 2'd1) % UOQ_ENTRIES) != uoq_tail[0] && uoq_v[(uoq_head + 2'd1) % UOQ_ENTRIES];
			uoq_slotv[2] <= ((uoq_head + 2'd2) % UOQ_ENTRIES) != uoq_tail[0] && uoq_v[(uoq_head + 2'd2) % UOQ_ENTRIES];
		end
	end
	else begin
		uoq_slotv[0] <= `VAL;
		uoq_slotv[1] <= ((uoq_head + 2'd1) % UOQ_ENTRIES) != uoq_tail[0] && uoq_v[(uoq_head + 2'd1) % UOQ_ENTRIES];
		uoq_slotv[2] <= ((uoq_head + 2'd2) % UOQ_ENTRIES) != uoq_tail[0] && uoq_v[(uoq_head + 2'd2) % UOQ_ENTRIES];
	end
end

`include "..\common\Micro-op_Engine\Gambit-micro-program.sv"

MicroOp uop2q [0:`MAX_UOPQ-1];
wire MicroOpPtr ptr [0:`MAX_UOPQ-1];
wire [`MAX_UOPQ-1:0] whinst, whinst1;			// Which instruction the corresponding pointer points to.
wire MicroOpPtr nmip1, nmip2;
wire branchmiss1, branchmiss2;
wire [51:0] insnxx [0:1];

// Compute pointers into micro-instruction program.
// Set which instruction a pointer points to.
mip_ptr ump1
(
	.uop_prg(uop_prg),
	.mip1(mip1),
	.mip2(mip2),
//	.branchmiss(branchmiss|branchmiss1),
	.branchmiss(branchmiss),
	.ptr(ptr),
	.whinst(whinst)
);


// Calculate number of instructions (not micro-ops) that queued.
wire [2:0] qcnt;
calc_qcnt ucalcqcnt1
(
	.ptr(ptr),
	.uop_prg(uop_prg),
	.mip1(mip1),
	.mip2(mip2),
	.qcnt(qcnt)
);

// Although four micro-ops are fetched from the table we might not want to
// queue all four. We only want to queue up to the end of the program 
// sequence for that instruction.
wire [2:0] uopqc;
calc_uopqc ucalcqc1
(
	.ptr(ptr),
	.uop_prg(uop_prg),
	.mip1(mip1),
	.mip2(mip2),
	.uopqc(uopqc)
);

// Calc how many micro-ops to queue. Depends on the room available and the
// length of the micro-sequence.
wire [2:0] uopqd, uopqd1;
calc_uopqd ucalcqd1
(
	.uoq_room(uoq_room),
	.uopqc(uopqc),
	.uopqd(uopqd)
);

wire uopQueued = uopqd > 3'd0;

wire [AMSB:0] uoppc [0:`MAX_UOPQ-1];

wire stall_uoq = /*(uopqd < uopqc) ||*/ uoq_room < uopqd1;// || !(qcnt==3'd2 || (qcnt==3'd1 && ~|mip1));

wire [AMSB:0] pcd2;
wire [2:0] len1d2;

// Under construction: additional pipelining
delay2 #(AMSB+1) udl1 (.clk(clk_i), .ce(nextBundle), .i(pc), .o(pcd2));
delay2 #(FSLOTS) udl2 (.clk(clk_i), .ce(nextBundle), .i(take_branch), .o(take_branchd));
delay2 #(3) udl3 (.clk(clk_i), .ce(nextBundle), .i(len1), .o(len1d2));
delay2 #(1) udl4 (.clk(clk_i), .ce(nextBundle), .i(branchmiss), .o(branchmissd2));


// The following is the micro-program engine. It advances the micro-program
// counters as micro-instructions are queued. And select which micro-program
// instructions to queue.
microop_engine umoe1
(
	.rst(rst_i),
	.clk(clk_i),
	.qcnt(qcnt),
	.phit(phit),
	.stall_uoq(stall_uoq),
	.opcode1(opcode1),
	.opcode2(opcode2),
	.pc(pc),
	.len1(len1),
	.uop_prg(uop_prg),
	.uopqd(uopqd),
	.uopqd_o(uopqd1),
	.uoq_empty(uoq_empty),
	.branchmiss(branchmiss),
	.take_branch(take_branch),
	.take_branchq(take_branchq),
	.ptr(ptr),
	.insnx(insnx),
	.insnxx(insnxx),
	.whinst(whinst),
	.whinst_o(whinst1),
	.mip1(mip1),
	.mip2(mip2),
	.uop2q(uop2q),
	.uoppc(uoppc),
	.branchmiss1(branchmiss1),
	.nextBundle(nextBundle)
);

//assign uoq_slotv[0] = uoq_v[uoq_head]==`VAL;	//uoq_head != uoq_tail[0] || ~|uoq_v || &uoq_v;
//assign uoq_slotv[1] = uoq_slotv[0] && uoq_v[(uoq_head+1) % UOQ_ENTRIES] == `VAL && ((uoq_head + 2'd1) % UOQ_ENTRIES) != uoq_tail[1];//(uoq_head != uoq_tail[0] && uoq_head + 4'd1 != uoq_tail[0]) || ~|uoq_v || &uoq_v;
//assign uoq_slotv[2] = uoq_slotv[1] && uoq_v[(uoq_head+2) % UOQ_ENTRIES] == `VAL && ((uoq_head + 2'd2) % UOQ_ENTRIES) != uoq_tail[2];//(uoq_head != uoq_tail[0] && uoq_head + 4'd1 != uoq_tail[0] && uoq_head + 4'd2 != uoq_tail[0])  || ~|uoq_v || &uoq_v;
wire [1023:0] ic_out;
reg [2:0] len2g [0:10];
generate begin : icouto
assign iclen1 = ic_out[15:13];
always @*
	len1 = ic_out[15:13];
for (g = 0; g < 11; g = g + 1)
always @*
	len2g[g] = ic_out[{g,4'h0}+15:{g,4'h0}+13];
always @*
	len2 = len2g[iclen1];
for (g = 0; g < 11; g = g + 1) begin
	always @*
		ic1_out[g*13+:13] = ic_out[g*16+:13];
end
for (g = 0; g < 4; g = g + 1) begin
	always @*
		ic2_out[g*13+:13] = ic_out[(g+iclen1)*16+:13];
end
end
endgenerate

assign freezepc = ((rst_ctr < 32'd16) || nmi_i || (irq_i & ~sr[4])) && !int_commit;

// Since the micro-program doesn't support conditional logic or branches a 
// conditional load for the PFI instruction is accomplished here.
wire [8:0] opcode1a = branchmiss ? 1'd0 : freezepc ? {(rst_ctr < 32'd16) ? `RST : nmi_i ? `NMI : irq_i ? `IRQ : 3'd7,`BRKGRP} : ic1_out[8:0];
wire [8:0] opcode2a = branchmiss ? 1'd0 : freezepc ? {(rst_ctr < 32'd16) ? `RST : nmi_i ? `NMI : irq_i ? `IRQ : 3'd7,`BRKGRP} : ic2_out[8:0];
always @*
	if ((opcode1a==`PFI || opcode1a==`WAI) && irq_i && !srx[4])
		opcode1 <= opcode1a|9'b1;
	else
		opcode1 <= opcode1a;
always @*
	if ((opcode2a==`PFI || opcode2a==`WAI) && irq_i && !srx[4])
		opcode2 <= opcode2a|9'b1;
	else
		opcode2 <= opcode2a;

always @*
	insnx[0] = freezepc ? {(rst_ctr < 32'd16) ? `RST : nmi_i ? `NMI : irq_i ? `IRQ : 3'd7,`BRKGRP} : ic1_out[51:0];
always @*
	insnx[1] = freezepc ? {(rst_ctr < 32'd16) ? `RST : nmi_i ? `NMI : irq_i ? `IRQ : 3'd7,`BRKGRP} : ic2_out[51:0];

wire IsRst = (freezepc && rst_ctr < 4'd16);
wire IsNmi = (freezepc & nmi_i);
wire IsIrq = (freezepc & irq_i & ~sr[3]);

wire [`ABITS] btgt [0:FSLOTS-1];
wire [51:0] insnxp [0:QSLOTS-1];
reg invdcl;
reg [AMSB:0] invlineAddr = 24'h0;
wire L1_invline;
wire [WID-1:0] L1_adr, L2_adr;
wire [475:0] L1_dat, L2_dat;
wire L1_wr, L2_wr;
wire L1_selpc;
wire L2_ld;
wire L1_ihit, L2_ihit, L2_ihita;
wire ihit;
assign ihit = L1_ihit;
wire L1_nxt, L2_nxt;					// advances cache way lfsr
wire [2:0] L2_cnt;
wire [415:0] ROM_dat;
wire [415:0] d0ROM_dat;
wire [415:0] d1ROM_dat;

wire isROM;
wire d0isROM, d1isROM;
wire d0L1_wr, d0L2_ld;
wire d1L1_wr, d1L2_ld;
wire [WID-1:0] d0L1_adr, d0L2_adr;
wire [WID-1:0] d1L1_adr, d1L2_adr;
wire d0L2_rhit, d0L2_whit;
wire d0L2_rhita, d1L2_rhita;
wire d0L1_nxt, d0L2_nxt;					// advances cache way lfsr
wire d1L1_dhit, d1L2_rhit, d1L2_whit;
wire d1L1_nxt, d1L2_nxt;					// advances cache way lfsr
wire [36:0] d0L1_sel, d0L2_sel;
wire [36:0] d1L1_sel, d1L2_sel;
wire [475:0] d0L1_dat, d0L2_rdat, d0L2_wdat;
wire [475:0] d1L1_dat, d1L2_rdat, d1L2_wdat;
wire d0L1_dhit;
wire d0L1_selpc;
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
reg [7:0] dcsel;
wire update_iq;
wire [IQ_ENTRIES-1:0] uid;
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
reg [7:0] dsel;
reg [AMSB:0] dadr;
reg [127:0] ddat;
wire [15:0] dselx = dsel << dadr[2:0];
reg dwrap;

function IsBranch;
input [51:0] insn;
reg [5:0] opcode = insn[5:0];
IsBranch = opcode==`BccD4a || opcode==`BccD4b || opcode==`BccD17a || opcode==`BccD17b;
endfunction
function IsBrk;
input [51:0] insn;
IsBrk = insn[`OPCODE]==`BRKGRP;
endfunction
function IsRti;
input [51:0] insn;
IsRti = insn[`OPCODE]==`RETGRP && insn[8:6]==`RTI;
endfunction
function IsRts;
input [51:0] insn;
IsRts = insn[`OPCODE]==`RETGRP && insn[8:6]==`RTS;
endfunction
function IsWai;
input [51:0] insn;
IsWai = insn[`OPCODE]==`RETGRP && insn[8:6]==`WAI;
endfunction
function IsJsr;
input [51:0] insn;
IsJsr = insn[`OPCODE]==`JSR;
endfunction
function IsJmp;
input [51:0] insn;
IsJmp = insn[`OPCODE]==`JMP;
endfunction

reg [7:0] slot_waix;
wire [FSLOTS-1:0] slot_wai;
generate begin : mdecoders
for (g = 0; g < 8; g = g + 1)
always @*
begin
	slot_rtsx[g] = IsRts(ic1_out[g*13+:52]);
	slot_brx[g] = IsBranch(ic1_out[g*13+:52]);
	slot_jcx[g]	= IsJsr(ic1_out[g*13+:52]) || IsJmp(ic1_out[g*13+:52]);
	slot_brkx[g]	= IsBrk(ic1_out[g*13+:52]) || IsRti(ic1_out[g*13+:52]);
	slot_waix[g] = IsWai(ic1_out[g*13+:52]);
end
end
endgenerate

assign slot_rts[0] = slot_rtsx[0];
assign slot_rts[1] = slot_rtsx[iclen1];
assign slot_br[0] = slot_brx[0];
assign slot_br[1] = slot_brx[iclen1];
assign slot_jc[0] = slot_jcx[0];
assign slot_jc[1] = slot_jcx[iclen1];
assign slot_jcl[0] = slot_jclx[0];
assign slot_jcl[1] = slot_jclx[iclen1];
assign slot_brk[0] = slot_brkx[0];
assign slot_brk[1] = slot_brkx[iclen1];
assign slot_pf[0] = slot_pfx[0];
assign slot_pf[1] = slot_pfx[iclen1];
assign slot_wai[0] = slot_waix[0];
assign slot_wai[1] = slot_waix[iclen1];

initial begin
	take_branch = 2'b00;
end
always @*
begin
	take_branch[0] = (slot_br[0] && predict_taken[0]) || slot_brk[0];
	take_branch[1] = (slot_br[1] && predict_taken[1]) || slot_brk[1];
end

// Branching for purposes of the branch shadow.
reg [IQ_ENTRIES-1:0] is_qbranch;
reg [QSLOTS-1:0] slot_jmp;
reg [QSLOTS-1:0] uoq_take_branch;
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	slot_jmp[n] = uoq_uop[(uoq_head + n) % UOQ_ENTRIES].opcode==JMP;
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	slot_rfw[n] = IsRFW(uoq_uop[(uoq_head + n) % UOQ_ENTRIES]);
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	slot_sr_tgts[n] = uoq_flagsupd[(uoq_head + n) % UOQ_ENTRIES];

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	uoq_take_branch = uoq_takb[(uoq_head + n) % UOQ_ENTRIES];

always @*
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	is_qbranch[n] = iq_br[n];

wire [1:0] ic_fault;
wire [AMSB:0] missadr;
reg invic, invdc;
reg invicl;
reg [4:0] bstate;
wire [3:0] icstate;
reg [1:0] bwhich;

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

function IsNop;
input [23:0] ins;
IsNop = ins[7:0]==`NOP;
endfunction

wire [`RBITS] next_iq_rid [0:IQ_ENTRIES-1];
wire [`RENTRIES-1:0] next_rob_v;



wire [AREGS:0] rf_v;								// register is valid
wire [AREGS:0] regIsValid;					// register is valid (in this cycle)
reg  [`QBITSP1] rf_source[0:AREGS-1];
wire [`QBITSP1] sr_source;

regfileValid urfv1
(
	.rst(rst_i),
	.clk(clk),
	.slotv(uoq_slotv),
	.slot_rfw(slot_rfw),
	.slot_sr_tgts(slot_sr_tgts),
	.tails(tails),
	.livetarget(livetarget),
	.branchmiss(branchmiss),
	.rob_id(rob_id),
	.commit0_v(commit0_v),
	.commit1_v(commit1_v),
	.commit2_v(commit2_v),
	.commit0_id(commit0_id),
	.commit1_id(commit1_id),
	.commit2_id(commit2_id),
	.commit0_tgt(commit0_tgt),
	.commit1_tgt(commit1_tgt),
	.commit2_tgt(commit2_tgt),
	.commit0_rfw(commit0_rfw),
	.commit1_rfw(commit1_rfw),
	.commit2_rfw(commit2_rfw),
	.commit0_sr_tgts(commit0_sr_tgts),
	.commit1_sr_tgts(commit1_sr_tgts),
	.commit2_sr_tgts(commit2_sr_tgts),
	.rf_source(rf_source),
	.sr_source(sr_source),
	.iq_source(iq_source),
	.iq_sr_source(iq_sr_source),
	.iq_latest_sr_ID(iq_latest_sr_ID),
	.Rd(RdReal),
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
	.slotv(uoq_slotv),
	.slot_rfw(slot_rfw),
	.slot_sr_tgts(slot_sr_tgts),
	.queuedOn(queuedOnp),
	.rqueuedOn(rqueuedOn),
	.iq_state(iq_state),
	.iq_rfw(iq_rfw),
	.iq_Rd(iq_tgt),
	.Rd(RdReal),
	.rob_tails(tails),
	.iq_latestID(iq_latestID),
	.iq_latest_sr_ID(iq_latest_sr_ID),
	.iq_tgt(iq_tgt),
	.iq_rid(iq_rid),
	.rf_source(rf_source),
	.sr_source(sr_source)
);

// Check how many instructions can be queued. An instruction can queue only if
// there are entries available in both the dispatch and re-order buffer. This
// quarentees the re-order buffer id is available during queue. The instruction
// can't execute until there is a place to put the result.
// The break bit in the instruction template must also be clear in order for an
// instruction to queue.
getQueuedCount ugqc1
(
	.branchmiss(branchmiss),
	.brk(3'b0),
	.phitd(phitd),
	.tails(tails),
	.rob_tails(tails),
	.slotvd(uoq_slotv),
	.slot_jmp(slot_jmp),
	.take_branch(uoq_take_branch),
	.iq_v(iq_v),
	.rob_v(rob_v),
	.queuedCnt(queuedCnt),
	.queuedOnp(queuedOnp)
);

getRQueuedCount ugrqct1
(
	.rst(rst_i),
	.rob_tails(tails),
	.rob_v_i(rob_v),
	.rob_v_o(next_rob_v),
	.heads(heads),
	.iq_state(iq_state),
	.iq_rid_i(iq_rid),
	.iq_rid_o(next_iq_rid),
	.rqueuedCnt(rqueuedCnt),
	.rqueuedOn(rqueuedOn)
);


reg [3:0] nxtrb;
reg [1:0] max_cs;
always @*
begin
	if (commit0_v & commit1_v & commit2_v)
		r_amt = 2'd3;
	else if (commit0_v & commit1_v)
		r_amt = 2'd2;
	else if (commit0_v)
		r_amt = 2'd1;
	else
		r_amt = 2'd0;

	// Amount to increment reorder buffer pointer by
//	case(max_cs)
//	2'd0:	r_amt = commit0_rid - rob_heads[0] + 4'd1;
//	2'd1:	r_amt = commit1_rid - rob_heads[0] + 4'd1;
//	2'd2:	r_amt = commit2_rid - rob_heads[0] + 4'd1;
//	default:	r_amt = 1'd0;
//	endcase
	// Now search ahead for invalid entries that can be skipped over.
	nxtrb = (rob_heads[0] + r_amt) % RENTRIES;
	if (rob_state[nxtrb[`RBITS]]==RS_INVALID && rob_heads[nxtrb[`RBITS]]!=rob_tails[0]) begin
		r_amt = r_amt + 4'd1;
		nxtrb = (rob_heads[0] + r_amt) % RENTRIES;
		if (rob_state[nxtrb[`RBITS]]==RS_INVALID && rob_heads[nxtrb[`RBITS]]!=rob_tails[0]) begin
			r_amt = r_amt + 4'd1;
			nxtrb = (rob_heads[0] + r_amt) % RENTRIES;
			if (rob_state[nxtrb[`RBITS]]==RS_INVALID && rob_heads[nxtrb[`RBITS]]!=rob_tails[0]) begin
				r_amt = r_amt + 4'd1;
				nxtrb = (rob_heads[0] + r_amt) % RENTRIES;
				if (rob_state[nxtrb[`RBITS]]==RS_INVALID && rob_heads[nxtrb[`RBITS]]!=rob_tails[0]) begin
					r_amt = r_amt + 4'd1;
					nxtrb = rob_heads[0] + r_amt;
				end
			end
		end
	end
end

programCounter upc1
(
	.rst(rst_i),
	.clk(clk),
	.q1(1'b0),
	.q2(nextBundle),
	.q1bx(1'b0),
	.insnx(insnx),
	.phit(phit),
	.freezepc(freezepc),
	.branchmiss(branchmiss),
	.misspc(misspc),
	.len1(len1),
	.len2(len2),
	.len3(1'd0),
	.jc(slot_jc),
	.jcl(slot_jcl),
	.rts(slot_rts),
	.br(slot_br),
	.wai(slot_wai),
	.take_branch(take_branch),
	.btgt(btgt),
	.pc(pc),
	.pcd(pcd),
	.pc_chg(nextb),
	.branch_pc(next_pc),
	.ra(52'd0),	//(ra),
	.pc_override(pc_override),
	.debug_on(debug_on)
);

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
	.Ra(RnReal),
	.Rd(RdReal),
	.call(slot_jsr),
	.ret(slot_rts),
	.pc(pcd),
	.ra(ra),
	.stompedRets(),
	.stompedRet()
);
`else
assign ra = `FCU_RA;
`endif
//
//next_bundle unb1
//(
//	.rst(rst_i),
//	.slotv(slotv),
//	.phit(phit),
//	.next(nextb)
//);

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
	.adr(L1_selpc ? pc : L1_adr),
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

reg [8:0] rL1_adr;
reg [8:0] rd0L1_adr;
reg [8:0] rd1L1_adr;
wire [511:0] ROM_d;
(* ram_style="block" *)
reg [511:0] rommem [0:511];
initial begin
`include "d:/cores5/Gambit/trunk/software/boot/fibonacci.ve0"
end
always @(posedge clk)
	rL1_adr <= L1_adr[13:5];
always @(posedge clk)
	rd0L1_adr <= d0L1_adr[13:5];
always @(posedge clk)
	rd1L1_adr <= d1L1_adr[13:5];
wire [511:0] romo = rommem[rL1_adr];
wire [511:0] romo0 = rommem[rd0L1_adr];
wire [511:0] romo1 = rommem[rd1L1_adr];
wire [12:0] romoo [0:31];
wire [12:0] romoo0 [0:31];
wire [12:0] romoo1 [0:31];
generate begin : romslices
for (g = 0; g < 32; g = g + 1)
begin
assign ROM_d = rommem[rd0L1_adr];
assign romoo[g] = romo[g*16+12:g*16];
assign romoo0[g] = romo0[g*16+12:g*16];
assign romoo1[g] = romo1[g*16+12:g*16];
assign ROM_dat[g*13+12:g*13] = romoo[g];
assign d0ROM_dat[g*13+12:g*13] = romoo0[g];
assign d1ROM_dat[g*13+12:g*13] = romoo1[g];
end
assign romoo0[31] = romo0[508:496];
end
endgenerate
//assign ROM_dat = rommem[rL1_adr];
//assign d0ROM_dat = rommem[rd0L1_adr];
//assign d1ROM_dat = rommem[rd1L1_adr];

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

wire btbwr0 = iq_state[heads[0]]==IQS_CMT && iq_fc[heads[0]];
wire btbwr1 = iq_state[heads[1]]==IQS_CMT && iq_fc[heads[1]];
wire btbwr2 = iq_state[heads[2]]==IQS_CMT && iq_fc[heads[2]];

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
  .wadr0(iq_pc[heads[0]]),
  .wdat0(iq_ma[heads[0]]),
  .valid0((iq_br[heads[0]] ? iq_takb[heads[0]] : iq_bt[heads[0]]) & iq_v[heads[0]]),
  .wr1(btbwr1),  
  .wadr1(iq_pc[heads[1]]),
  .wdat1(iq_ma[heads[1]]),
  .valid1((iq_br[heads[1]] ? iq_takb[heads[1]] : iq_bt[heads[1]]) & iq_v[heads[1]]),
  .wr2(btbwr2),  
  .wadr2(iq_pc[heads[2]]),
  .wdat2(iq_ma[heads[2]]),
  .valid2((iq_br[heads[2]] ? iq_takb[heads[2]] : iq_bt[heads[2]]) & iq_v[heads[2]]),
  .rclk(~clk),
  .pcA(pc),
  .btgtA(btgt[0]),
  .pcB(pc + len1),
  .btgtB(btgt[1]),
  .pcC(pc + len1 + len2),
  .btgtC(),
  .npcA(pc + len1),
  .npcB(pc + len1 + len2),
  .npcC()
);
`else
assign btgt[0] = pc + len1;
assign btgt[1] = pc + len1 + len2;
`endif

wire [AMSB:0] pcs [0:FSLOTS-1];
assign pcs[0] = pc;
assign pcs[1] = pc + len1;

wire [3:0] xisBr;
wire [AMSB:0] xpc [0:3];
wire [3:0] xtkb;

assign xisBr[0] = iq_br[heads[0]] & commit0_v;// & ~\[heads[0]][5];
assign xisBr[1] = iq_br[heads[1]] & commit1_v;// & ~iq_instr[heads[1]][5];
assign xisBr[2] = iq_br[heads[2]] & commit2_v;// & ~iq_instr[heads[2]][5];
assign xisBr[3] = 1'b0;
assign xpc[0] = iq_pc[heads[0]];
assign xpc[1] = iq_pc[heads[1]];
assign xpc[2] = iq_pc[heads[2]];
assign xpc[3] = 1'd0;
assign xtkb[0] = commit0_v & iq_takb[heads[0]];
assign xtkb[1] = commit1_v & iq_takb[heads[1]];
assign xtkb[2] = commit2_v & iq_takb[heads[2]];
assign xtkb[3] = 1'b0;

wire [FSLOTS-1:0] predict_takenx;

`ifdef FCU_BP
gselectPredictor ubp1
(
  .rst(rst_i),
  .clk(clk_i),
  .clk2x(clk2x_i),
  .clk4x(clk4x_i),
  .en(1'b1),
  .xisBranch(xisBr),
  .xip(xpc),
  .takb(xtkb),
  .ip(pcs),
  .predict_taken(predict_takenx)
);
`else
assign predict_takenx[0] = insnx[0][15];
assign predict_takenx[1] = insnx[1][15];
`endif

assign predict_taken[0] = predict_takenx[0];
assign predict_taken[1] = predict_takenx[1];


reg StoreAck1, isStore;
wire [WID-1:0] dc0_out, dc1_out;
wire whit0, whit1, whit2;

wire wr_dcache0 = (dcwr)||(((bstate==B_StoreAck && StoreAck1) || (bstate==B_LSNAck && isStore)) && whit0);
wire wr_dcache1 = (dcwr)||(((bstate==B_StoreAck && StoreAck1) || (bstate==B_LSNAck && isStore)) && whit1);
wire rd_dcache0 = !dram0_unc & dram0_load;
wire rd_dcache1 = !dram1_unc & dram1_load;

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
	.dcnxt(d0L1_nxt),
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
	.invall(1'b0),//invdc),
	.invline(1'b0)//d0L1_invline)
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
	.invall(1'b0),//invdc),
	.invline(1'b0)//d0L1_invline)
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
	.dcnxt(d1L1_nxt),
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
	.invall(1'b0),//invdc),
	.invline(1'b0)//d1L1_invline)
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
	.invall(1'b0),//invdc),
	.invline(1'b0)//d1L1_invline)
);

wire [WID-1:0] aligned_data = fnDatiAlign(dram0_addr,xdati);
wire [WID-1:0] rdat0, rdat1;
assign rdat0 = fnDataExtend(dram0_instr,dram0_unc ? aligned_data : dc0_out);
assign rdat1 = fnDataExtend(dram1_instr,dram1_unc ? aligned_data : dc1_out);
assign dhit0a = d0L1_dhit;
assign dhit1a = d1L1_dhit;

wire [7:0] wb_fault;
wire wb_q0_done, wb_q1_done;
wire wb_has_bus;
assign dhit0 = dhit0a && !wb_hit0;
assign dhit1 = dhit1a && !wb_hit1;
wire wb_p0_wr = (dram0==`DRAMSLOT_BUSY && dram0_store);
wire wb_p1_wr = (dram1==`DRAMSLOT_BUSY && dram1_store);

writeBuffer #(.IQ_ENTRIES(IQ_ENTRIES)) uwb1
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
	.p0_wrap_i(dram0_wrap),
	.p0_wr_i(wb_p0_wr),
	.p0_ack_o(wb_q0_done),
	.p0_sel_i(fnSelect(dram0_instr)),
	.p0_adr_i(dram0_addr),
	.p0_dat_i(dram0_data),
	.p0_hit(wb_hit0),
	.p1_id_i(dram1_id),
	.p1_rid_i(dram1_rid),
	.p1_wrap_i(dram1_wrap),
	.p1_wr_i(wb_p1_wr),
	.p1_ack_o(wb_q1_done),
	.p1_sel_i(fnSelect(dram1_instr)),
	.p1_adr_i(dram1_addr),
	.p1_dat_i(dram1_data),
	.p1_hit(wb_hit1),
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

wire rob_empty = rob_v == {RENTRIES{`INV}};

headptrs uhp1
(
	.rst(rst_i),
	.clk(clk),
	.amt(hi_amt),
	.heads(heads),
	.ramt(r_amt),
	.rob_heads(rob_heads),
	.headcnt(uop_committed)
);

tailptrs utp1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.branchmiss(branchmiss),
	.iq_stomp(iq_stomp),
//	.iq_br_tag(iq_br_tag),
	.queuedCnt(queuedCnt),
	.iq_tails(tails),
	.rqueuedCnt(queuedCnt),
	.rob_tails(rob_tails),
//	.active_tag(miss_tag),
	.iq_rid(iq_rid)
);


always @*
for (n = 0; n < QSLOTS; n = n + 1)
	Rd[n] = uoq_uop[(uoq_head+n)%UOQ_ENTRIES].tgt;
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	Rn[n] = uoq_uop[(uoq_head+n)%UOQ_ENTRIES].src2;
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	Ra[n] = uoq_uop[(uoq_head+n)%UOQ_ENTRIES].src1;

// In emulation mode, rfot and rfoa are the same
always @*
	for (n = 0; n < QSLOTS; n = n + 1) begin
		case(Ra[n])
		ZERO:		rfoa[n] <= 64'h0;
		//`UO_RT:		rfoa[n] <= regsx[uoq_Rt[(uoq_head+n) % UOQ_ENTRIES]];
		Rareg:		rfoa[n] <= uoq_inst[(uoq_head+n) % UOQ_ENTRIES][`RA]==6'd0 ? 52'd0 : regsx[uoq_inst[(uoq_head+n) % UOQ_ENTRIES][`RA]];
		acc:	rfoa[n] <= regsx[1];
		xr:		rfoa[n] <= regsx[2];
		yr:		rfoa[n] <= regsx[3];
		SP:		rfoa[n] <= regsx[31];
		PC:		rfoa[n] <= uoq_pc[(uoq_head+n) % UOQ_ENTRIES];
		TMP1: 	rfoa[n] <= regsx[4];
		TMP2: 	rfoa[n] <= regsx[5];
		SR:		rfoa[n] <= {16'h00,srx};
		PC1:	rfoa[n] <= uoq_pc[(uoq_head+n) % UOQ_ENTRIES] + 3'd1;
		PC4:	rfoa[n] <= uoq_pc[(uoq_head+n) % UOQ_ENTRIES] + 3'd4;
		default:	rfoa[n] <= 52'h0;
		endcase
		case(Rd[n])
		ZERO:		rfot[n] <= 64'h0;
		Rtreg:		rfot[n] <= regsx[uoq_inst[(uoq_head+n) % UOQ_ENTRIES][`RT]];
		//`UO_RA:		rfot[n] <= uoq_Ra[(uoq_head+n) % UOQ_ENTRIES]==6'd0 ? 64'd0 : regsx[uoq_Ra[(uoq_head+n) % UOQ_ENTRIES]];
		acc:	rfot[n] <= regsx[1];
		xr:		rfot[n] <= regsx[2];
		yr:		rfot[n] <= regsx[3];
		SP:		rfot[n] <= regsx[31];
		PC:		rfot[n] <= uoq_pc[(uoq_head+n) % UOQ_ENTRIES];
		TMP1: 	rfot[n] <= regsx[4];
		TMP2: 	rfot[n] <= regsx[5];
		SR:		rfot[n] <= {16'h00,srx};
		PC1:	rfot[n] <= uoq_pc[(uoq_head+n) % UOQ_ENTRIES] + 3'd1;
		PC4:	rfot[n] <= uoq_pc[(uoq_head+n) % UOQ_ENTRIES] + 3'd4;
		default:	rfot[n] <= 64'h0;
		endcase
	end

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	case(Rn[n])
	ZERO:		rfob[n] <= 52'h0;
//	`UO_RA:		rfob[n] <= regsx[uoq_Ra[(uoq_head+n) % UOQ_ENTRIES]];
	Rbreg:
		if (uoq_inst[(uoq_head+n) % UOQ_ENTRIES][25])
			rfob[n] <= 52'd0;// uoq_const[(uoq_head+n) % UOQ_ENTRIES];
		else
			rfob[n] <= uoq_inst[(uoq_head+n) % UOQ_ENTRIES][`RB]==6'd0 ? 52'd0 : regsx[uoq_inst[(uoq_head+n) % UOQ_ENTRIES][`RB]];
	acc:	rfob[n] <= regsx[1];
	xr:		rfob[n] <= regsx[2];
	yr:		rfob[n] <= regsx[3];
	SP:		rfob[n] <= regsx[31];
//	MONE:		rfob[n] <= 52'hFFFFFFFFFFFFF;
	TMP1:	rfob[n] <= regsx[4];
	TMP2:	rfob[n] <= regsx[5];
	//`UO_P2:		rfob[n] <= 64'd2;
	default:	rfob[n] <= 64'h0;
	endcase

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	case(Rd[n])
	Rtreg:		RdReal[n] <= uoq_inst[(uoq_head+n) % UOQ_ENTRIES][`RT];
	//`UO_RA:		RdReal[n] <= uoq_Ra[(uoq_head+n) % UOQ_ENTRIES];
	acc:	RdReal[n] <= 6'd1;
	xr:		RdReal[n] <= 6'd2;
	yr:		RdReal[n] <= 6'd3;
	TMP1:	RdReal[n] <= 6'd4;
	TMP2:	RdReal[n] <= 6'd5;
	SP:		RdReal[n] <= 6'd31;
	SR:		RdReal[n] <= 6'd32;
	default:	RdReal[n] <= 6'd0;
	endcase
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	case(Rn[n])
//	`UO_RT:		RnReal[n] <= uoq_Rt[(uoq_head+n) % UOQ_ENTRIES];
//	`UO_RA:		RnReal[n] <= uoq_Ra[(uoq_head+n) % UOQ_ENTRIES];
	Rbreg:		RnReal[n] <= uoq_inst[(uoq_head+n) % UOQ_ENTRIES][25] ? 6'd0 : uoq_inst[(uoq_head+n) % UOQ_ENTRIES][`RB];
	acc:	RnReal[n] <= 6'd1;
	xr:		RnReal[n] <= 6'd2;
	yr:		RnReal[n] <= 6'd3;
	TMP1:	RnReal[n] <= 6'd4;
	TMP2:	RnReal[n] <= 6'd5;
	SP:		RnReal[n] <= 6'd31;
	SR:		RnReal[n] <= 6'd32;
	default:	RnReal[n] <= 6'd0;
	endcase
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	case(Ra[n])
//	`UO_RT:		RaReal[n] <= uoq_Rt[(uoq_head+n) % UOQ_ENTRIES];
	Rareg:		RaReal[n] <= uoq_inst[(uoq_head+n) % UOQ_ENTRIES][`RA];
	acc:	RaReal[n] <= 6'd1;
	xr:		RaReal[n] <= 6'd2;
	yr:		RaReal[n] <= 6'd3;
	TMP1:	RaReal[n] <= 6'd4;
	TMP2:	RaReal[n] <= 6'd5;
	SP:		RaReal[n] <= 6'd31;
	SR:		RaReal[n] <= 6'd32;
	default:	RaReal[n] <= 6'd0;
	endcase

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	rfos[n] <= srx;

generate begin : regupd
for (g = 1; g < 32; g = g + 1)
always @*
	if (commit2_v && commit2_tgt==g && commit2_rfw)
		regsx[g] = commit2_bus;
	else if (commit1_v && commit1_tgt==g && commit1_rfw)
		regsx[g] = commit1_bus;
	else if (commit0_v && commit0_tgt==g && commit0_rfw)
		regsx[g] = commit0_bus;
	else
		regsx[g] = regs[g];
end
endgenerate

// PLP and RTI target the sr during a load. They write the whole word.
// The brk flag in the status register always loads as zero. The only time the
// brk flag is set is during execution of the BRK opcode. Even if the brk flag
// is set to one in memory, it still reads back as zero.
// There could be different status bits being modified for each commit bus.
// Commit1 could be modifying C while commit 2 modifies NZ. Both commits should
// be able to happen.  Can't use a if/elseif tree here.
always @*
	if (rst_i) begin
		srx = 16'h0110;	// mask interrupts on reset, clear decimal mode, emulation mode
	end
	else begin
		srx = sr;
		if (commit0_v) begin
			if (commit0_tgt==6'd32 && commit0_rfw)
				srx[7:0] = commit0_bus[7:0] & 8'hEF;	// clear break bit
			else begin
				if (commit0_sr_tgts[0]) srx[0] = commit0_sr_bus[0];
				if (commit0_sr_tgts[1]) srx[1] = commit0_sr_bus[1];
				if (commit0_sr_tgts[2]) srx[2] = commit0_sr_bus[2];
				if (commit0_sr_tgts[3]) srx[3] = commit0_sr_bus[3];
				if (commit0_sr_tgts[4]) srx[4] = commit0_sr_bus[4];
				if (commit0_sr_tgts[5]) srx[5] = commit0_sr_bus[5];
				if (commit0_sr_tgts[6]) srx[6] = commit0_sr_bus[6];
				if (commit0_sr_tgts[7]) srx[7] = commit0_sr_bus[7];
			end
		end
		if (commit1_v) begin
			if (commit1_tgt==6'd32 && commit1_rfw)
				srx[7:0] = commit1_bus[7:0] & 8'hEF;	// clear break bit
			else begin
				if (commit1_sr_tgts[0]) srx[0] = commit1_sr_bus[0];
				if (commit1_sr_tgts[1]) srx[1] = commit1_sr_bus[1];
				if (commit1_sr_tgts[2]) srx[2] = commit1_sr_bus[2];
				if (commit1_sr_tgts[3]) srx[3] = commit1_sr_bus[3];
				if (commit1_sr_tgts[4]) srx[4] = commit1_sr_bus[4];
				if (commit1_sr_tgts[5]) srx[5] = commit1_sr_bus[5];
				if (commit1_sr_tgts[6]) srx[6] = commit1_sr_bus[6];
				if (commit1_sr_tgts[7]) srx[7] = commit1_sr_bus[7];
			end
		end
		if (commit2_v) begin
			if (commit2_tgt==6'd32 && commit2_rfw)
				srx[7:0] = commit2_bus[7:0] & 8'hEF;	// clear break bit
			else begin
				if (commit2_sr_tgts[0]) srx[0] = commit2_sr_bus[0];
				if (commit2_sr_tgts[1]) srx[1] = commit2_sr_bus[1];
				if (commit2_sr_tgts[2]) srx[2] = commit2_sr_bus[2];
				if (commit2_sr_tgts[3]) srx[3] = commit2_sr_bus[3];
				if (commit2_sr_tgts[4]) srx[4] = commit2_sr_bus[4];
				if (commit2_sr_tgts[5]) srx[5] = commit2_sr_bus[5];
				if (commit2_sr_tgts[6]) srx[6] = commit2_sr_bus[6];
				if (commit2_sr_tgts[7]) srx[7] = commit2_sr_bus[7];
			end
		end
	end
always @(posedge clk)
	sr <= srx;

reg [WID-1:0] argA [0:QSLOTS-1];
reg [WID-1:0] argB [0:QSLOTS-1];
reg [ 7:0] argS [0:QSLOTS-1];

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	argA[n] = rfoa[n];
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	argB[n] = rfob[n];
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	argS[n] = rfos[n];

generate begin : gDecoderInst
for (g = 0; g < IQ_ENTRIES; g = g + 1) begin
decoder6 iq0 (
	.num(iq_tgt[g]),
	.rfw(iq_rfw[g]),
	.out(iq_out2[g])
);
end
end
endgenerate

function SourceBValid;
input MicroOp ins;
case(ins.opcode)
`UO_BEQ,`UO_BNE,`UO_BMI,`UO_BPL,`UO_BCS,`UO_BCC,`UO_BVS,`UO_BVC,`UO_BRA,`UO_BUS,`UO_BUC:
	SourceBValid = TRUE;
`UO_REP,`UO_SEP,`UO_NOP:
	SourceBValid = TRUE;
default:
	SourceBValid = ins.src2 > 4'd8 || ins.src2==4'd0;
endcase
endfunction

function SourceSValid;
input MicroOp ins;
case(ins.opcode)
`UO_BEQ,`UO_BNE,`UO_BMI,`UO_BPL,`UO_BCS,`UO_BCC,`UO_BVS,`UO_BVC,`UO_BUS,`UO_BUC:
	SourceSValid = FALSE;
default:	SourceSValid = TRUE;
endcase
endfunction

function SourceTValid;
input MicroOp ins;
case(ins.opcode)
`UO_BEQ,`UO_BNE,`UO_BMI,`UO_BPL,`UO_BCS,`UO_BCC,`UO_BVS,`UO_BVC,`UO_BRA,`UO_BUS,`UO_BUC,
`UO_REP,`UO_SEP,`UO_NOP:
	SourceTValid = TRUE;
default:
	SourceTValid = ins.tgt > 4'd8 || ins.tgt==4'd0;
endcase
endfunction

function SourceAValid;
input MicroOp ins;
case(ins.opcode)
`UO_BEQ,`UO_BNE,`UO_BMI,`UO_BPL,`UO_BCS,`UO_BCC,`UO_BVS,`UO_BVC,`UO_BRA,`UO_BUS,`UO_BUC,
`UO_REP,`UO_SEP,`UO_NOP:
	SourceAValid = TRUE;
default:
	SourceAValid = ins.src1>4'd8 || ins.src1==4'd0;
endcase
endfunction

function IsMem;
input [23:0] isn;
case(isn[21:16])
LD_D9,LD_D23,LD_D36,LDB_D36,
ST_D9,ST_D23,ST_D36,STB_D36:
	IsMem = TRUE;
default:	IsMem = FALSE;
endcase
endfunction

// Really IsPredictableBranch
function IsUoBranch;
input [23:0] isn;
case(isn[21:16])
`UO_BEQ,`UO_BNE,`UO_BMI,`UO_BPL,`UO_BCS,`UO_BCC,`UO_BVS,`UO_BVC,`UO_BRA,`UO_BUS,`UO_BUC:
	IsUoBranch = TRUE;
default:	IsUoBranch = FALSE;
endcase
endfunction

function [6:0] fnNeedSr;
input MicroOp isn;
case(isn.opcode)
ST_D9,ST_D23,ST_D36:
	fnNeedSr = isn.tgt==SR ? 7'h7F : 7'h00;
`UO_BEQ,`UO_BNE:
	fnNeedSr = 7'b0000001;
`UO_BMI,`UO_BPL:
	fnNeedSr = 7'b1000000;
`UO_BCS,`UO_BCC:
	fnNeedSr = 7'b0001000;
`UO_BVS,`UO_BVC:
	fnNeedSr = 7'b0100000;
`UO_BUS,`UO_BUC:
	fnNeedSr = 7'b0010000;
default:
	fnNeedSr = 7'b0000000;
endcase
endfunction

function IsFlowCtrl;
input [23:0] isn;
case(isn[21:16])
JMP,
`UO_BEQ,`UO_BNE,`UO_BMI,`UO_BPL,`UO_BCS,`UO_BCC,`UO_BVS,`UO_BVC,`UO_BRA,`UO_BUS,`UO_BUC:
	IsFlowCtrl = TRUE;
default:	IsFlowCtrl = FALSE;
endcase
endfunction

function IsRFW;
input [23:0] isn;
case(isn[21:16])
NOP:	IsRFW = FALSE;
CAUSE:	IsRFW = FALSE;
JMP,
`UO_BEQ,`UO_BNE,`UO_BMI,`UO_BPL,`UO_BCS,`UO_BCC,`UO_BVS,`UO_BVC,`UO_BRA,`UO_BUS,`UO_BUC:	IsRFW = FALSE;
SUBu,
ANDu:
	IsRFW = isn[15:12]!=6'd0;
REP,SEP:	IsRFW = FALSE;
ST,STB:		IsRFW = FALSE;
default:	IsRFW = TRUE;
endcase
endfunction

function [3:0] fnSelect;
input [5:0] isn;
case(isn)
LD,LDu:	fnSelect = 4'b1111;
LDB,LDBu:	fnSelect = 4'b0001;
ST:	fnSelect = 4'b1111;
STB:	fnSelect = 4'b0001;
default:	fnSelect = 4'b000;
endcase
endfunction

function [WID-1:0] fnDatiAlign;
input [`ABITS] adr;
input [103:0] dat;
reg [103:0] adat;
begin
adat = dat >> (adr[3:0] * 13);
fnDatiAlign = adat[WID-1:0];
end
endfunction

function [WID-1:0] fnDataExtend;
input [5:0] isn;
input [WID-1:0] dat;
case(isn[5:0])
LDB_D36:	fnDataExtend = {{39{dat[12]}},dat[12:0]};
default:	fnDataExtend = dat;
endcase
endfunction

// Simulation aid
function [31:0] fnMnemonic;
input [5:0] ins;
case(ins)
CAUSE:	fnMnemonic = "CAUS";
ADD:	fnMnemonic = "ADD ";
ADDu:	fnMnemonic = "ADDu";
SUB:	fnMnemonic = "SUB ";
SUBu:	fnMnemonic = "SUBu";
ORu:	fnMnemonic = "ORu ";
LD:		fnMnemonic = "LD  ";
ST:		fnMnemonic = "ST  ";
JSI:	fnMnemonic = "JSI ";
JMP:	fnMnemonic = "JMP ";
SEP:	fnMnemonic = "SEP ";
BNE:	fnMnemonic = "BNE ";
NOP:	fnMnemonic = "NOP ";
default:	fnMnemonic = "????";
endcase
endfunction

function [23:0] fnRegT;
input [5:0] rg;
case(rg)
acc:	fnRegT = "ACC ";
xr:		fnRegT = "XR  ";
yr:		fnRegT = "YR  ";
SP:		fnRegT = "SP  ";
TMP1:	fnRegT = "TMP1";
TMP2:	fnRegT = "TMP2";
SR:		fnRegT = "SR ";
PC:		fnRegT = "PC ";
PC1:	fnRegT = "PC1";
PC4:	fnRegT = "PC4";
endcase
endfunction

initial begin
	panic = 4'd0;
end
/*
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

end
*/
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
				if (!iq_v[heads[3]] && heads[3] != tails[0])
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
					if (!iq_v[heads[3]] && heads[3] != tails[0])
						hi_amt <= 3'd4;
				end
			end
			else if (!iq_v[heads[1]]) begin
				if (heads[1] != tails[0]) begin
					hi_amt <= 3'd2;
					if (iq_v[heads[2]] && iq_state[heads[2]]==IQS_CMT) begin
						hi_amt <= 3'd3;
					end
					else if (!iq_v[heads[2]]) begin
						if (heads[2] != tails[0]) begin
							hi_amt <= 3'd3;
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
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
		iq_livetarget[n] = {AREGS {iq_v[n]}} & {AREGS {~iq_stomp[n]}} & iq_out2[n];

always @*
begin
	iq_latest_sr_ID = {`QBIT{1'b1}};
	iq_sr_source = {IQ_ENTRIES{1'b0}};
	for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
		for (j = n; j < n + IQ_ENTRIES; j = j + 1) begin
			if (missid==(j % IQ_ENTRIES))
				for (k = n; k <= j; k = k + 1) begin
					if (iq_v[k % IQ_ENTRIES]
						&& ~iq_stomp[k % IQ_ENTRIES]					// not stomped on
						&& iq_sr_tgts[k % IQ_ENTRIES]!=8'h00	// and updates the sr
						&& iq_latest_sr_ID == {`QBIT{1'b1}})	begin // and not found yet
						iq_latest_sr_ID = k % IQ_ENTRIES;
						iq_sr_source[k % IQ_ENTRIES] = TRUE;
					end
				end
		end
	end
end




always @*
for (j = 0; j < AREGS; j = j + 1) begin
	livetarget[j] = 1'b0;
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
		livetarget[j] = livetarget[j] | iq_livetarget[n][j];
end

//
// BRANCH-MISS LOGIC: latestID
//
// latestID is the instruction queue ID of the newest instruction (latest) that targets
// a particular register.  looks a lot like scheduling logic, but in reverse.
// 
always @*
	for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
		iq_cumulative[n] = 1'b0;
		for (j = n; j < n + IQ_ENTRIES; j = j + 1) begin
			if (missid==(j % IQ_ENTRIES))
				for (k = n; k <= j; k = k + 1)
					iq_cumulative[n] = iq_cumulative[n] | iq_livetarget[k % IQ_ENTRIES];
		end
	end

always @*
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
    iq_latestID[n] = (missid == n || ((iq_livetarget[n] & iq_cumulative[(n+1)%IQ_ENTRIES]) == {AREGS{1'b0}}))
				    ? iq_livetarget[n]
				    : {AREGS{1'b0}};

always @*
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
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

wire [IQ_ENTRIES-1:0] args_valid;
wire [IQ_ENTRIES-1:0] could_issue;
wire [IQ_ENTRIES-1:0] could_issueid;

// Note that bypassing is provided only from the first fpu.
generate begin : issue_logic
for (g = 0; g < IQ_ENTRIES; g = g + 1)
begin
assign args_valid[g] =
		  (iq_argA_v[g] || iq_mem[g]
`ifdef FU_BYPASS
        || (iq_argA_s[g] == alu0_rid)
        || ((iq_argA_s[g] == alu1_rid) && (`NUM_ALU > 1))
        || (iq_argA_s[g] == dramA_rid && dramA_v)
        || ((iq_argA_s[g] == dramB_rid && dramB_v) && (`NUM_MEM > 1))
`endif
        )
        // argA is a constant, it'll always be valid
    && (iq_argB_v[g] //|| iq_mem[g]	// a2 does not need to be valid immediately for a mem op (agen), it is checked by iq_memready logic
`ifdef FU_BYPASS
        || (iq_argB_s[g] == alu0_rid)
        || ((iq_argB_s[g] == alu1_rid) && (`NUM_ALU > 1))
        || (iq_argB_s[g] == dramA_rid && dramA_v)
        || ((iq_argB_s[g] == dramB_rid && dramB_v) && (`NUM_MEM > 1))
`endif
        )
    && (iq_argS_v[g] || !iq_need_sr[g]
//        || (iq_mem[g] & ~iq_agen[g])
`ifdef FU_BYPASS
        || (iq_argS_s[g] == alu0_rid && alu0_v)
        || ((iq_argS_s[g] == alu1_rid && alu1_v) && (`NUM_ALU > 1))
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
reg [IQ_ENTRIES-1:0] prior_valid;
//generate begin : gPriorValid
always @*
for (j = 0; j < IQ_ENTRIES; j = j + 1)
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
reg [IQ_ENTRIES-1:0] prior_sync;
//generate begin : gPriorSync
always @*
for (j = 0; j < IQ_ENTRIES; j = j + 1)
begin
	prior_sync[heads[j]] = 1'b0;
//	if (j > 0)
//		for (n = j-1; n >= 0; n = n - 1)
//			prior_sync[heads[j]] = prior_sync[heads[j]]|(iq_v[heads[n]] & iq_sync[heads[n]]);
end
//end
//endgenerate

//end
//endgenerate
// Start search for instructions to process at head of queue (oldest instruction).
always @*
begin
	iq_alu0_issue = {IQ_ENTRIES{1'b0}};
	iq_alu1_issue = {IQ_ENTRIES{1'b0}};
	
	if (alu0_idle) begin
		for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_alu[heads[n]]
			&& iq_alu0_issue == {IQ_ENTRIES{1'b0}}
			// If there are no valid queue entries prior it doesn't matter if there is
			// a sync.
			&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
			)
			  iq_alu0_issue[heads[n]] = `TRUE;
		end
	end

	if (alu1_idle && `NUM_ALU > 1) begin
//		if ((could_issue & ~iq_alu0_issue & ~iq_alu0) != {IQ_ENTRIES{1'b0}}) begin
			for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
				if (could_issue[heads[n]] && iq_alu[heads[n]]
					&& !iq_alu0_issue[heads[n]]
					&& iq_alu1_issue == {IQ_ENTRIES{1'b0}}
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
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	if (iq_alu0_issue[n] && !(iq_v[n] && iq_stomp[n])
												&& (alu0_done))
		issuing_on_alu0 = TRUE;
end

always @*
begin
issuing_on_alu1 = FALSE;
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	if (iq_alu1_issue[n] && !(iq_v[n] && iq_stomp[n])
												&& (alu1_done))
		issuing_on_alu1 = TRUE;
end

reg issuing_on_agen0;
always @*
begin
issuing_on_agen0 = FALSE;
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	if (iq_agen0_issue[n] && !(iq_v[n] && iq_stomp[n]))
		issuing_on_agen0 = TRUE;
end

reg issuing_on_agen1;
always @*
begin
issuing_on_agen1 = FALSE;
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	if (iq_agen1_issue[n] && !(iq_v[n] && iq_stomp[n]))
		issuing_on_agen1 = TRUE;
end

reg issuing_on_fcu;
always @*
begin
issuing_on_fcu = FALSE;
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	if (iq_fcu_issue[n] && !(iq_v[n] && iq_stomp[n]) && fcu_done)
		issuing_on_fcu = TRUE;
end

always @*
begin
	iq_agen0_issue = {IQ_ENTRIES{1'b0}};
	iq_agen1_issue = {IQ_ENTRIES{1'b0}};
	
	if (agen0_idle) begin
		for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_mem[heads[n]]
			&& iq_agen0_issue == {IQ_ENTRIES{1'b0}}
			// If there are no valid queue entries prior it doesn't matter if there is
			// a sync.
			&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
			)
			  iq_agen0_issue[heads[n]] = `TRUE;
		end
	end

	if (agen1_idle && `NUM_AGEN > 1) begin
//		if ((could_issue & ~iq_alu0_issue & ~iq_alu0) != {IQ_ENTRIES{1'b0}}) begin
			for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
				if (could_issue[heads[n]] && iq_mem[heads[n]]
					&& !iq_agen0_issue[heads[n]]
					&& iq_agen1_issue == {IQ_ENTRIES{1'b0}}
					&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
				)
				  iq_agen1_issue[heads[n]] = `TRUE;
			end
//		end
	end
end

reg [`QBITS] nids [0:IQ_ENTRIES-1];
always @*
for (j = 0; j < IQ_ENTRIES; j = j + 1) begin
	// We can't both start and stop at j
	for (n = j; n != (j+1)%IQ_ENTRIES; n = (n + (IQ_ENTRIES-1)) % IQ_ENTRIES)
		nids[j] = n;
	// Do the last one
	nids[j] = (j+1)%IQ_ENTRIES;
end

reg [IQ_ENTRIES-1:0] nextqd;

// Search the queue for the next entry on the same thread.
reg [`QBITS] nid;
always @*
begin
	nid = fcu_id;
	for (n = IQ_ENTRIES-1; n > 0; n = n - 1)
		nid = (fcu_id + n) % IQ_ENTRIES;
end

always @*
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	nextqd[n] <= iq_sn[nids[n]] > iq_sn[n] || iq_v[n];

//assign nextqd = 8'hFF;

// Don't issue to the fcu until the following instruction is enqueued.
// However, if the queue is full then issue anyway. A branch miss will likely occur.
// Start search for instructions at head of queue (oldest instruction).
always @*
begin
	iq_fcu_issue = {IQ_ENTRIES{1'b0}};
	
	if (fcu_done & ~branchmiss) begin
		for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_fc[heads[n]] && (nextqd[heads[n]] || iq_br[heads[n]])
			&& iq_fcu_issue == {IQ_ENTRIES{1'b0}}
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
	for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
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
	.iq_aq({IQ_ENTRIES{1'b0}}),
	.iq_rl({IQ_ENTRIES{1'b0}}),
	.iq_ma(iq_ma),
	.iq_memsb({IQ_ENTRIES{1'b0}}),
	.iq_memdb({IQ_ENTRIES{1'b0}}),
	.iq_stomp(iq_stomp),
	.iq_canex({IQ_ENTRIES{1'b0}}), 
	.wb_v(wb_v),
	.inwb0(inwb0),
	.inwb1(inwb1),
	.sple(1'b1),
	.memissue(memissue),
	.issue_count(issue_count)
);

// Starts search for instructions to issue at the head of the queue and 
// progresses from there. This ensures that the oldest instructions are
// selected first for processing.
always @*
begin
	last_issue0 = IQ_ENTRIES;
	last_issue1 = IQ_ENTRIES;
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
    if (~iq_stomp[heads[n]] && iq_memissue[heads[n]] && !iq_done[heads[n]] && iq_v[heads[n]]) begin
      if (dram0 == `DRAMSLOT_AVAIL) begin
       last_issue0 = heads[n];
      end
    end
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
    if (~iq_stomp[heads[n]] && iq_memissue[heads[n]]) begin
    	if (heads[n] != last_issue0 && `NUM_MEM > 1) begin
        if (dram1 == `DRAMSLOT_AVAIL) begin
					last_issue1 = heads[n];
        end
    	end
    end
end

always @*
begin
	iq_stomp = 1'b0;
	if (branchmiss) begin
		for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
			if (iq_sn[n] > misssn)
				iq_stomp[n] = TRUE;
		end
	end
end

always @*
begin
	stompedOnRets = 1'b0;
//	for (n = 0; n < IQ_ENTRIES; n = n + 1)
//		if (iq_stomp[n] && iq_rts[n])
//			stompedOnRets = stompedOnRets + 4'd1;
end

EvalBranch ube1
(
	.instr(fcu_instr),
	.sr(fcu_argS),
	.takb(fcu_takb)
);


/*
wire will_clear_branchmiss = branchmiss && (
															(uoq_slotv[0] && uoq_pc[uoq_head]==misspc)
															|| (uoq_slotv[1] && uoq_pc[(uoq_head + 2'd1) % UOQ_ENTRIES]==misspc)
															|| (uoq_slotv[2] && uoq_pc[(uoq_head + 2'd2) % UOQ_ENTRIES]==misspc)
															);
*/													
wire will_clear_branchmiss = branchmiss && (pc==misspc);

always @*
case(fcu_instr)
JMP:	fcu_misspc = {fcu_pc[`AMSB:46],fcu_argI[45:0] + fcu_argA[45:0]};
JSI:	fcu_misspc = fcu_argI + fcu_argA;
default:
	// The length of the branch instruction is hardcoded here.
	fcu_misspc = fcu_pt ? (fcu_pc + 2'd2) : (fcu_pc + fcu_brdisp + 2'd2);
endcase

// To avoid false branch mispredicts the branch isn't evaluated until the
// following instruction queues. The address of the next instruction is
// looked at to see if the BTB predicted correctly.

`ifdef FCU_ENH
wire fcu_followed = iq_sn[nid] > iq_sn[fcu_id];
`else
wire fcu_followed = `TRUE;
`endif
always @*
if (fcu_v) begin
	// Break and RTI switch register sets, and so are always treated as a branch miss in order to
	// flush the pipeline. Hardware interrupts also stream break instructions so they need to 
	// flushed from the queue so the interrupt is recognized only once.
	// BRK and RTI are handled as excmiss types which are processed during the commit stage.
	fcu_branchhit <= (fcu_branch && !(fcu_takb ^ fcu_pt));
	if (fcu_branch && (fcu_takb ^ fcu_pt))
    fcu_branchmiss = TRUE;
	else if (fcu_instr==JMP || fcu_instr==JSI) begin
		if (fcu_followed)
			fcu_branchmiss = iq_pc[nid]!=fcu_misspc;
		else
			fcu_branchmiss = TRUE;
	end
	else
    fcu_branchmiss = FALSE;
end
else
	fcu_branchmiss = FALSE;

// A holdover from nvio3 - not really needed here.
assign pc_mask = 2'b11;

//
// additional DRAM-enqueue logic

assign dram_avail = (dram0 == `DRAMSLOT_AVAIL || dram1 == `DRAMSLOT_AVAIL);

always @*
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	iq_memopsvalid[n] <= (iq_mem[n] && (iq_store[n] ? iq_argA_v[n] : 1'b1) && iq_state[n]==IQS_AGEN);

always @*
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	iq_memready[n] <= (iq_v[n] & iq_memopsvalid[n] & ~iq_memissue[n] & ~iq_stomp[n]);

assign outstanding_stores = (dram0 && dram0_store) ||
                            (dram1 && dram1_store);

//
// additional COMMIT logic
//

always @*
begin
	// The first commit bus is always tied to the same place
  commit0_v <= (iq_state[heads[0][`RBITS]] == IQS_CMT && ~|panic);
  commit0_id <= heads[0][`RBITS];	// if a memory op, it has a DRAM-bus id
  commit0_tgt <= rob_tgt[heads[0][`RBITS]];
  commit0_rfw <= rob_rfw[heads[0]];
  commit0_bus <= rob_res[heads[0][`RBITS]];
  commit0_sr_tgts <= rob_sr_tgts[heads[0][`RBITS]];
  commit0_sr_bus <= rob_sr_res[heads[0][`RBITS]];
  commit0_rid <= heads[0][`RBITS];

  commit1_v <= (hi_amt > 3'd1
             && iq_state[heads[1][`RBITS]] == IQS_CMT
             && ~|panic);
	commit1_id <= heads[1][`RBITS];
	commit1_tgt <= rob_tgt[heads[1][`RBITS]];
  commit1_rfw <= rob_rfw[heads[1]];
	commit1_bus <= rob_res[heads[1][`RBITS]];
  commit1_sr_tgts <= rob_sr_tgts[heads[1][`RBITS]];
  commit1_sr_bus <= rob_sr_res[heads[1][`RBITS]];
  commit1_rid <= heads[1][`RBITS];

  commit2_v <= (hi_amt > 3'd2
             && iq_state[heads[2][`RBITS]] == IQS_CMT
             && ~|panic);
  commit2_id <= heads[2][`RBITS];
  commit2_tgt <= rob_tgt[heads[2][`RBITS]];  
  commit2_rfw <= rob_rfw[heads[2]];
  commit2_bus <= rob_res[heads[2][`RBITS]];
  commit2_sr_tgts <= rob_sr_tgts[heads[2][`RBITS]];
  commit2_sr_bus <= rob_sr_res[heads[2][`RBITS]];
  commit2_rid <= heads[2][`RBITS];
end

assign int_commit = (commit0_v && iq_instr[heads[0]]==`UO_JSI)
									 || (hi_amt > 3'd1 && commit1_v && iq_instr[heads[1]]==`UO_JSI)
									 || (hi_amt > 3'd2 && commit2_v && iq_instr[heads[2]]==`UO_JSI);


//wire [143:0] id_bus[0], id_bus[1], id_bus[2];

generate begin : idecoders
for (g = 0; g < QSLOTS; g = g + 1)
begin
idecoder uid1
(
	.instr(uoq_uop[(uoq_head+g) % UOQ_ENTRIES]),
	.predict_taken(predict_taken[g]),
	.bus(id_bus[g])
);
end
end
endgenerate

alu ualu1
(
	.op(alu0_instr),
	.a(alu0_argA),
	.imm(alu0_argI),
	.b(alu0_argB),
	.o(alu0_bus),
	.s_i(alu0_argS),
	.s_o(alu0_sro),
	.idle(alu0_idle)
);

alu ualu2
(
	.op(alu1_instr),
	.a(alu1_argA),
	.imm(alu1_argI),
	.b(alu1_argB),
	.o(alu1_bus),
	.s_i(alu1_argS),
	.s_o(alu1_sro),
	.idle(alu1_idle)
);

agen uagn1
(
	.src1(agen0_argI),
	.src2(agen0_argA),
	.ma(agen0_ma),
	.idle(agen0_idle)
);

agen uagn2
(
	.src1(agen1_argI),
	.src2(agen1_argA),
	.ma(agen1_ma),
	.idle(agen1_idle)
);

wire [WID-1:0] ralu0_bus = alu0_bus;
wire [WID-1:0] ralu1_bus = alu1_bus;
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
		vadr <= {dadr[AMSB:4],4'h0};
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
assign cyc_o = cyc;
assign stb_o = stb;
assign we_o = we;
assign adr_o = vadr;

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
always @(posedge clk)
if (rst_i)
	rst_ctr <= 32'd0;
else begin
	if (rst_ctr < 32'd16)
		rst_ctr <= rst_ctr + 24'd1;
end

slotValid usv1
(
	.rst(rst_i),
	.clk(clk),
	.branchmiss(branchmiss),
	.phit(phit),
	.nextb(nextb),
	.pc_mask(pc_mask),
	.pc_maskd(pc_maskd),
	.pc_override(pc_override),
	.q1(1'b0),
	.q2(nextBundle & phit),//q2),
	.slot_jc(slot_jc),
	.slot_rts(slot_rts),
	.take_branch(take_branch),
	.slotv(slotv),
	.slotvd(slotvd),
	.debug_on(debug_on)
);

wire [`SNBITS] maxsn;

seqnum usqn1
(
	.rst(rst_i),
	.clk(clk),
	.heads(heads),
	.hi_amt(hi_amt),
	.iq_v(iq_v),
	.iq_sn(iq_sn),
	.overflow(sn_overflow(1)),
	.maxsn(maxsn),
	.tosub(tosub)
);

always @(posedge clk_i)
if (rst_i) begin
	ins_stomped = 0;
end
else begin
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
		ins_stomped = ins_stomped + iq_stomp[n];
end

wire [2:0] fl3 = ((iq_fl[commit0_id]==2'b01) && commit0_v) + ((iq_fl[commit1_id]==2'b01) && commit1_v) + ((iq_fl[commit2_id]==2'b01) && commit2_v) +
								((iq_fl[commit0_id]==2'b11) && commit0_v) + ((iq_fl[commit1_id]==2'b11) && commit1_v) + ((iq_fl[commit2_id]==2'b11) && commit2_v);
wire [2:0] fl2 = ((iq_fl[commit0_id]==2'b01) && commit0_v) + ((iq_fl[commit1_id]==2'b01) && commit1_v) + 
								((iq_fl[commit0_id]==2'b11) && commit0_v) + ((iq_fl[commit1_id]==2'b11) && commit1_v);
wire [2:0] fl1 = ((iq_fl[commit0_id]==2'b01) && commit0_v) + ((iq_fl[commit0_id]==2'b11) && commit0_v);

always @(posedge clk_i)
if (rst_i)
	ins_committed <= 0;
else begin
	if (hi_amt==3'd3)
		ins_committed <= ins_committed + fl3;
	else if (hi_amt==3'd2)
		ins_committed <= ins_committed + fl2;
	else if (hi_amt==3'd1)
		ins_committed <= ins_committed + fl1;
end


always @(posedge clk_i)
if (rst_i)
	br_missed <= 0;
else
	br_missed <= br_missed + (fcu_branch & fcu_branchmiss);
always @(posedge clk_i)
if (rst_i)
	br_total <= 0;
else
	br_total <= br_total + (fcu_branch & fcu_v);

//wire pe_branchmiss;
//edge_det ubmed1 (.rst(rst_i), .clk(clk), .ce(1'b1), .i(branchmiss), .pe(pe_branchmiss), .ne(), .ee());

always @(posedge clk_i)
if (rst_i) begin
	tick <= 0;
	uop_queued <= 0;
	ins_queued <= 0;
	uop_stomped <= 0;
	uoq_head <= 0;
	for (n = 0; n < 8; n = n + 1)
		uoq_tail[n] <= n;
	for (n = 0; n < UOQ_ENTRIES; n = n + 1) begin
		uoq_v[n] <= `INV;
		uoq_uop[n] <= {0,0,0,0,0};
		uoq_const[n] <= 52'h0000;
		uoq_inst[n] <= 52'h0;
		uoq_flagsupd[n] <= 7'h00;
		uoq_fl[n] <= 2'b11;
		uoq_pc[n] <= 52'h00FFFC;
		uoq_hs[n] <= 1'd0;
		uoq_takb[n] <= FALSE;
	end
	q1b <= FALSE;
  for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
  	iq_state[n] <= IQS_INVALID;
		iq_sn[n] <= n;
		iq_pt[n] <= FALSE;
		iq_bt[n] <= FALSE;
		iq_br[n] <= FALSE;
		iq_alu[n] <= FALSE;
		iq_fc[n] <= FALSE;
		iq_takb[n] <= FALSE;
		iq_jmp[n] <= FALSE;
		iq_load[n] <= FALSE;
		iq_rfw[n] <= FALSE;
		iq_pc[n] <= 52'h00E000;
		iq_instr[n] <= 5'h00;	// `UO_NOP
		iq_mem[n] <= FALSE;
		iq_memissue[n] <= FALSE;
		iq_mem_islot[n] <= 3'd0;
		iq_sel[n] <= 1'd0;
//		iq_memdb[n] <= 1'd0;
//		iq_memsb[n] <= 1'd0;
//		iq_aq[n] <= 1'd0;
//		iq_rl[n] <= 1'd0;
		iq_canex[n] <= 1'd0;
		iq_tgt[n] <= 6'd0;
		iq_imm[n] <= 1'b0;
		iq_ma[n] <= 1'b0;
		iq_argA[n] <= 64'd0;
		iq_argB[n] <= 64'd0;
		iq_argS[n] <= 8'd0;
		iq_argA_v[n] <= `INV;
		iq_argB_v[n] <= `INV;
		iq_argS_v[n] <= `INV;
		iq_argA_s[n] <= 5'd0;
		iq_argB_s[n] <= 5'd0;
		iq_argS_s[n] <= 5'd0;
		iq_fl[n] <= 2'b00;
		iq_rid[n] <= 3'd0;
  end
    for (n = 0; n < RENTRIES; n = n + 1) begin
    	rob_state[n] <= RS_INVALID;
    	rob_pc[n] <= 1'd0;
//    	rob_instr[n] <= `UO_NOP;
    	rob_ma[n] <= 1'd0;
    	rob_res[n] <= 1'd0;
    	rob_tgt[n] <= 1'd0;
    	rob_sr_res[n] <= 1'd0;
    	rob_sr_tgts[n] <= 8'h00;
    end
     bwhich <= 2'b00;
     dram0 <= `DRAMSLOT_AVAIL;
     dram1 <= `DRAMSLOT_AVAIL;
//     dram0_instr <= `UO_NOP;
//     dram1_instr <= `UO_NOP;
     dram0_addr <= 32'h0;
     dram1_addr <= 32'h0;
     dram0_id <= 1'b0;
     dram1_id <= 1'b0;
     dram0_rid <= 1'd0;
     dram1_rid <= 1'd0;
     dram0_load <= 1'b0;
     dram1_load <= 1'b0;
     dram0_unc <= 1'b0;
     dram1_unc <= 1'b0;
     dram0_store <= 1'b0;
     dram1_store <= 1'b0;
     dram0_wrap <= 1'b0;
     dram1_wrap <= 1'b0;
     invic <= FALSE;
     invicl <= FALSE;
     alu0_dataready <= 1'b1;
     alu1_dataready <= 1'b1;
     alu0_sourceid <= 5'd0;
     alu1_sourceid <= 5'd0;
`define SIM_
`ifdef SIM_
		alu0_pc <= RSTIP;
//		alu0_instr <= `UO_NOP;
		alu0_argT <= 16'h0;
		alu0_argA <= 1'h0;
		alu0_argB <= 1'h0;
		alu0_argS <= 8'h0;
		alu0_argI <= 16'h0;
		alu0_mem <= 1'b0;
		alu0_shft <= 1'b0;
		alu0_tgt <= 3'h0;
		alu0_sr_tgts <= 8'h00;
		alu0_rid <= {RBIT{1'b1}};
		alu1_pc <= RSTIP;
//		alu1_instr <= `UO_NOP;
		alu1_argT <= 16'h0;
		alu1_argA <= 1'h0;
		alu1_argB <= 1'h0;
		alu1_argS <= 8'h0;
		alu1_argI <= 16'h0;
		alu1_mem <= 1'b0;
		alu1_shft <= 1'b0;
		alu1_tgt <= 3'h0;  
		alu1_sr_tgts <= 8'h00;
		alu1_rid <= {RBIT{1'b1}};
		agen0_argT <= 1'd0;
		agen0_argB <= 1'd0;
		agen0_argA <= 1'd0;
		agen0_dataready <= FALSE;
		agen1_argT <= 1'd0;
		agen1_argB <= 1'd0;
		agen1_argA <= 1'd0;
		agen1_dataready <= FALSE;
		fcu_branch <= 1'd0;
		fcu_sr_tgts <= 8'h00;
`endif
     fcu_dataready <= 0;
//     fcu_instr <= `UO_NOP;
     dramA_v <= 0;
     dramB_v <= 0;
     I <= 0;
     CC <= 0;
     bstate <= BIDLE;
     cyc_pending <= `LOW;
     fcu_done <= `TRUE;
     wb_en <= `TRUE;
//		iq_ctr <= 40'd0;
//		bm_ctr <= 40'd0;
//		br_ctr <= 40'd0;
//		irq_ctr <= 40'd0;
		StoreAck1 <= `FALSE;
		dcyc <= `LOW;
		dstb <= `LOW;
		dwe <= `LOW;
		dsel <= 8'h00;
		dadr <= RSTIP;
		ddat <= 128'h0;
		regs[31] <= 52'h01FFC;
end
else begin

	if (sn_overflow(1))
		for (j = 0; j < IQ_ENTRIES; j = j + 1)
			iq_sn[j] <= iq_sn[j] - {2'b01,{`SNBIT-2{1'b0}}};

	for (n = 1; n < 32; n = n + 1)
		regs[n] <= regsx[n];

//	if (|fb_panic)
//		panic <= fb_panic;

	// Only one branchmiss is allowed to be processed at a time. If a second 
	// branchmiss occurs while the first is being processed, it would have
	// to of occurred as a speculation in the branch shadow of the first.
	// The second instruction would be stomped on by the first branchmiss so
	// there is no need to process it.
	// The branchmiss has to be latched, then cleared later as there could
	// be a cache miss at the same time meaning the switch to the new pc
	// does not take place immediately.
	if (!branchmiss) begin
//		if (excmiss) begin
//			branchmiss <= `TRUE;
//			misspc <= excmisspc;
//			missid <= (|iq_exc[heads[0]] ? heads[0] : |iq_exc[heads[1]] ? heads[1] : heads[2]);
//		end
//		else
		if (fcu_branchmiss) begin
			branchmiss <= `TRUE;
			misspc <= fcu_misspc;
			missid <= fcu_sourceid;
//			if (sn_overflow(1))
//				misssn <= iq_sn[fcu_sourceid] - {2'b01,{`SNBIT-2{1'b0}}};
//			else
				misssn <= iq_sn[fcu_sourceid];
		end
	end
//	else
//		active_tag <= miss_tag;
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
//	ld_time <= {ld_time[4:0],1'b0};
//	wc_times <= wc_time;

	invic <= FALSE;
	if (L1_invline)
		invicl <= FALSE;
	invdcl <= FALSE;
	if (rst_ctr >= 32'd16)
		tick <= tick + 4'd1;
	alu0_ld <= FALSE;
	alu1_ld <= FALSE;
	fcu_ld <= FALSE;
	queuedOn <= 1'b0;
	ins_queued <= ins_queued + queuedCnt;

  if (waitctr != 48'd0)
		waitctr <= waitctr - 4'd1;

	for (n = 0; n < QSLOTS; n = n + 1)
		if (tails[(n+1)%IQ_ENTRIES] != (tails[n] + 1) % IQ_ENTRIES) begin
			$display("Tails out of sync");
			$stop;
		end

	// The tail can't point to a valid slot unless the queue is full.
	// For some reason in simulation the tail slot was being marked as valid
	// when two instructions queued at the same time. I've double-checked the
	// code and can't find out why the extra slot is validated. I'm 
	// assuming a bit error in sim for now. The issue is that it blocks
	// further queuing. So for now if this situation occurs the slot at the
	// tail is set to invalid.
//	if (uoq_v[uoq_tail[0]] && uoq_tail[0] != uoq_head)
//		uoq_v[uoq_tail[0]] <= `INV;

	// Invalidate all entries in the micro-op queue on a branch miss.

	if (branchmiss|branchmiss1) begin
		// Must take core not to clear already cleared entries. The already cleared
		// entries may be in the process of queuing new instructions from the 
		// target address.
		for (n = 0; n < UOQ_ENTRIES; n = n + 1)
			//if (uoq_v[n])
				uoq_v[n] <= 1'd0;
		for (n = 0; n < UOQ_ENTRIES; n = n + 1)
			uop_stomped <= uop_stomped + uoq_v[n];
		for (n = 0; n < 8; n = n + 1)
			uoq_tail[n] <= n;
		uoq_head <= 2'd0;
	end

	if (!(branchmiss||branchmiss1||uoq_room < uopqd1)) begin
		if (uopqd1 > 3'd0) begin
			queue_uop(uoq_tail[0],uoppc[0],uop2q[0],uop2q[0].fl,8'h00,1'b0,1'b0);
			uoq_takb[uoq_tail[0]] <= take_branchq[whinst1[0]];
			uoq_inst[uoq_tail[0]] <= insnxx[whinst1[0]];
			tskLd4(uop2q[0].cnst,insnxx[whinst1[0]],uoq_const[uoq_tail[0]]);
			flagsUpd(uop2q[0],uoq_flagsupd[uoq_tail[0]]);
		end
		if (uopqd1 > 3'd1) begin
			queue_uop(uoq_tail[1],uoppc[1],uop2q[1],uop2q[1].fl,8'h00,1'b0,1'b0);
			uoq_takb[uoq_tail[1]] <= take_branchq[whinst1[1]];
			uoq_inst[uoq_tail[1]] <= insnxx[whinst1[1]];
			tskLd4(uop2q[1].cnst,insnxx[whinst1[1]],uoq_const[uoq_tail[1]]);
			flagsUpd(uop2q[1],uoq_flagsupd[uoq_tail[1]]);
		end
		if (uopqd1 > 3'd2) begin
			queue_uop(uoq_tail[2],uoppc[2],uop2q[2],uop2q[2].fl,8'h00,1'b0,1'b0);
			uoq_takb[uoq_tail[2]] <= take_branchq[whinst1[2]];
			uoq_inst[uoq_tail[2]] <= insnxx[whinst1[2]];
			tskLd4(uop2q[2].cnst,insnxx[whinst1[2]],uoq_const[uoq_tail[2]]);
			flagsUpd(uop2q[2],uoq_flagsupd[uoq_tail[2]]);
		end
		if (uopqd1 > 3'd3) begin
			queue_uop(uoq_tail[3],uoppc[3],uop2q[3],uop2q[3].fl,8'h00,1'b0,1'b0);
			uoq_takb[uoq_tail[3]] <= take_branchq[whinst1[3]];
			uoq_inst[uoq_tail[3]] <= insnxx[whinst1[3]];
			tskLd4(uop2q[3].cnst,insnxx[whinst1[3]],uoq_const[uoq_tail[3]]);
			flagsUpd(uop2q[3],uoq_flagsupd[uoq_tail[3]]);
		end
		for (n = 0; n < 8; n = n + 1)
			uoq_tail[n] <= (uoq_tail[n] + uopqd1) % UOQ_ENTRIES;
	end

	if (!branchmiss) begin
		queuedOn <= queuedOnp;
		case(uoq_slotv)
		3'b001:
			if (queuedOnp[0]) begin
				queue_slot(0,tails[0],maxsn+2'd1,id_bus[0],tails[0]);
				uoq_v[uoq_head] <= `INV;
				uoq_takb[uoq_head] <= FALSE;
				uoq_head <= (uoq_head + 3'd1) % UOQ_ENTRIES;
			end
		3'b010:
			if (queuedOnp[1]) begin
				queue_slot(1,tails[0],maxsn+2'd1,id_bus[1],tails[0]);
				uoq_v[uoq_head] <= `INV;
				uoq_takb[uoq_head] <= FALSE;
				uoq_head <= (uoq_head + 3'd1) % UOQ_ENTRIES;
			end
		3'b011:
			if (queuedOnp[0]) begin
				queue_slot(0,tails[0],maxsn+2'd1,id_bus[0],tails[0]);
				uoq_v[uoq_head] <= `INV;
				uoq_takb[uoq_head] <= FALSE;
				uoq_head <= (uoq_head + 3'd1) % UOQ_ENTRIES;
				if (queuedOnp[1]) begin
					queue_slot(1,tails[1],maxsn+2'd2,id_bus[1],tails[1]);
					uoq_v[(uoq_head + 1) % UOQ_ENTRIES] <= `INV;
					uoq_takb[(uoq_head + 1) % UOQ_ENTRIES] <= FALSE;
					uoq_head <= (uoq_head + 3'd2) % UOQ_ENTRIES;
					arg_vs(3'b011);
				end
			end
		3'b100:
			if (queuedOnp[2]) begin
				queue_slot(2,tails[0],maxsn+2'd1,id_bus[2],tails[0]);
				uoq_v[uoq_head] <= `INV;
				uoq_takb[uoq_head] <= FALSE;
				uoq_head <= (uoq_head + 3'd1) % UOQ_ENTRIES;
			end
		3'b101:	// believe this case is illegal (can't happen)
			if (queuedOnp[0]) begin
				queue_slot(0,tails[0],maxsn+2'd1,id_bus[0],tails[0]);
				uoq_v[uoq_head] <= `INV;
				uoq_takb[uoq_head] <= FALSE;
				uoq_head <= (uoq_head + 3'd1) % UOQ_ENTRIES;
				if (queuedOnp[2]) begin
					queue_slot(2,tails[1],maxsn+2'd2,id_bus[2],tails[1]);
					uoq_v[(uoq_head + 1) % UOQ_ENTRIES] <= `INV;
					uoq_takb[(uoq_head + 1) % UOQ_ENTRIES] <= FALSE;
					uoq_head <= (uoq_head + 3'd2) % UOQ_ENTRIES;
					arg_vs(3'b101);
				end
			end
		3'b110:
			if (queuedOnp[1]) begin
				queue_slot(1,tails[0],maxsn+2'd1,id_bus[1],tails[0]);
				uoq_v[uoq_head] <= `INV;
				uoq_takb[uoq_head] <= FALSE;
				uoq_head <= (uoq_head + 3'd1) % UOQ_ENTRIES;
				if (queuedOnp[2]) begin
					queue_slot(2,tails[1],maxsn+2'd2,id_bus[2],tails[1]);
					uoq_v[(uoq_head + 1) % UOQ_ENTRIES] <= `INV;
					uoq_takb[(uoq_head + 1) % UOQ_ENTRIES] <= FALSE;
					uoq_head <= (uoq_head + 3'd2) % UOQ_ENTRIES;
					arg_vs(3'b110);
				end
			end
		3'b111:
			if (queuedOnp[0]) begin
				uoq_head <= (uoq_head + 3'd1) % UOQ_ENTRIES;
				uoq_v[uoq_head] <= `INV;
				uoq_takb[uoq_head] <= FALSE;
				queue_slot(0,tails[0],maxsn+2'd1,id_bus[0],tails[0]);
				if (queuedOnp[1]) begin
					queue_slot(1,tails[1],maxsn+2'd2,id_bus[1],tails[1]);
					uoq_v[(uoq_head + 1) % UOQ_ENTRIES] <= `INV;
					uoq_takb[(uoq_head + 1) % UOQ_ENTRIES] <= FALSE;
					uoq_head <= (uoq_head + 3'd2) % UOQ_ENTRIES;
					arg_vs(3'b011);
					if (queuedOnp[2]) begin
						queue_slot(2,tails[2],maxsn+2'd3,id_bus[2],tails[2]);
						uoq_v[(uoq_head + 2) % UOQ_ENTRIES] <= `INV;
						uoq_takb[(uoq_head + 2) % UOQ_ENTRIES] <= FALSE;
						uoq_head <= (uoq_head + 3'd3) % UOQ_ENTRIES;
						arg_vs(3'b111);
					end
				end
			end
		default:	;
		endcase
	end

	if (alu0_v) begin
		rob_res	[ alu0_rid ] <= ralu0_bus;
		rob_sr_res [ alu0_rid] <= alu0_sro;
		rob_exc	[ alu0_rid ] <= 4'h0;
	//	if (alu0_done) begin
			if (iq_state[alu0_id]==IQS_OUT) begin
				iq_state[alu0_id] <= IQS_CMT;
				rob_state[alu0_rid] <= RS_CMT;
			end
	//	end
		alu0_dataready <= FALSE;
	end

	if (alu1_v && `NUM_ALU > 1) begin
		rob_res	[ alu1_rid ] <= ralu1_bus;
		rob_sr_res [ alu1_rid] <= alu1_sro;
		rob_exc	[ alu1_rid ] <= alu1_exc;
	//	if (alu1_done) begin
			if (iq_state[alu1_id]==IQS_OUT) begin
				iq_state[alu1_id] <= IQS_CMT;
				rob_state[alu1_rid] <= RS_CMT;
			end
	//	end
		alu1_dataready <= FALSE;
	end

	if (agen0_v) begin
		if (iq_state[agen0_id]==IQS_OUT)
			iq_state[agen0_id] <= IQS_AGEN;
		rob_res[agen0_rid] <= 16'h0;//agen0_ma;
		rob_exc[agen0_rid] <= 4'h0;
		if (iq_state[agen0_id]==IQS_OUT) begin
			iq_ma[agen0_id] <= agen0_ma;
			iq_sel[agen0_id] <= fnSelect(agen0_instr) << agen0_ma[3:0];
		end
		agen0_dataready <= FALSE;
	end

	if (agen1_v && `NUM_AGEN > 1) begin
		if (iq_state[agen1_id]==IQS_OUT)
			iq_state[agen1_id] <= IQS_AGEN;
		rob_res[agen1_rid] <= 16'h0;//agen1_ma;		// LEA needs this result
		rob_exc[agen1_rid] <= 4'h0;
		if (iq_state[agen1_id]==IQS_OUT) begin
			iq_ma[agen1_id] <= agen1_ma;
			iq_sel[agen1_id] <= fnSelect(agen1_instr) << agen1_ma[3:0];
		end
		agen1_dataready <= FALSE;
	end

	if (fcu_v) begin
		fcu_done <= `TRUE;
		fcu_sr_bus <= (fcu_instr==JSI) ? (fcu_argS | `UOF_I) : fcu_argS;
		rob_sr_res[fcu_rid] <= (fcu_instr==JSI) ? (fcu_argS | `UOF_I) : fcu_argS;
		//fcu_sr_bus <= fcu_argS;
		//rob_sr_res[fcu_id] <= fcu_argS;
		//iq_ma  [ fcu_id ] <= fcu_misspc;
	  rob_res [ fcu_rid ] <= rfcu_bus;
	  rob_exc [ fcu_rid ] <= fcu_exc;
		if (iq_state[fcu_id]==IQS_OUT) begin
			iq_state[fcu_id ] <= IQS_CMT;
			rob_state[fcu_rid ] <= RS_CMT;
		end
		// takb is looked at only for branches to update the predictor. Here it is
		// unconditionally set, the value will be ignored if it's not a branch.
		iq_takb[ fcu_id ] <= fcu_takb;
		//br_ctr <= br_ctr + fcu_branch;
		fcu_dataready <= `INV;
	end

	// dramX_v only set on a load
	if (dramA_v && iq_v[ dramA_id ]) begin
		rob_res	[ dramA_rid ] <= rdramA_bus;
		rob_sr_res [dramA_rid] <= dramA_sr_bus;
		rob_state[dramA_rid ] <= RS_CMT;
		iq_state[dramA_id ] <= IQS_CMT;
	end
	if (`NUM_MEM > 1 && dramB_v && iq_v[ dramB_id ]) begin
		rob_res	[ dramB_id ] <= rdramB_bus;
		rob_sr_res [dramB_rid] <= dramB_sr_bus;
		rob_state[dramB_rid ] <= RS_CMT;
		iq_state[dramB_id ] <= IQS_CMT;
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
		for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
			if (uid[n]) begin
				iq_state[n] <= IQS_CMT;
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

// More bypassing from one queue result to another queue entrys args.
// Boosts performance quite a bit, and also the core size.
`ifdef QBYPASSING
	setargs2();
`endif

	for (n = 0; n < IQ_ENTRIES; n = n + 1)
	begin
		setargs(n,{1'b0,commit0_id},commit0_v & commit0_rfw,commit0_bus);
		setargs(n,{1'b0,commit1_id},commit1_v & commit1_rfw,commit1_bus);
		setargs(n,{1'b0,commit2_id},commit2_v & commit2_rfw,commit2_bus);

		setargs(n,{1'b0,alu0_rid},alu0_v,ralu0_bus);
		if (`NUM_ALU > 1)
			setargs(n,{1'b0,alu1_rid},alu1_v,ralu1_bus);

//		setargs(n,{1'b1,agen0_rid},agen0_v & agen0_mem2,agen0_res);
//		if (`NUM_AGEN > 1) begin
//			setargs(n,{1'b1,agen1_rid},agen1_v & agen1_mem2,agen1_res);
//		end

		setargs(n,{1'b0,fcu_rid},fcu_v,rfcu_bus);

		setargs(n,{1'b0,dramA_rid},dramA_v,rdramA_bus);
		if (`NUM_MEM > 1)
			setargs(n,{1'b0,dramB_rid},dramB_v,rdramB_bus);
			
		set_sr_args(n,{1'b0,commit0_id},commit0_v,commit0_sr_bus, commit0_sr_tgts);
		set_sr_args(n,{1'b0,commit1_id},commit1_v,commit1_sr_bus, commit1_sr_tgts);
		set_sr_args(n,{1'b0,commit2_id},commit2_v,commit2_sr_bus, commit2_sr_tgts);

		set_sr_args(n,{1'b0,alu0_rid},alu0_v,alu0_sro,alu0_sr_tgts);
		if (`NUM_ALU > 1)
			set_sr_args(n,{1'b0,alu1_rid},alu1_v,alu1_sro, alu1_sr_tgts);

		set_sr_args(n,{1'b0,fcu_rid},fcu_v,fcu_sr_bus, fcu_sr_tgts);	// JSI changes I,D flags

		set_sr_args(n,{1'b0,dramA_rid},dramA_v,dramA_sr_bus,dramA_sr_tgts);
		if (`NUM_MEM > 1)
			set_sr_args(n,{1'b0,dramB_rid},dramB_v,dramB_sr_bus,dramB_sr_tgts);
			
	end

// Argument loading for functional units.
// X's on unused busses cause problems in SIM.
  for (n = 0; n < IQ_ENTRIES; n = n + 1)
    if (iq_alu0_issue[n] && !(iq_v[n] && iq_stomp[n])
										&& (alu0_done)) begin
			iq_fuid[n] <= 3'd0;
			alu0_sourceid	<= n[`QBITS];
			if (alu1_rid==n[`QBITS] && !issuing_on_alu1)
				alu1_rid <= {`QBIT{1'b1}};
			if (agen0_rid==n[`QBITS] && !issuing_on_agen0)
				agen0_rid <= {`QBIT{1'b1}};
			if (agen1_rid==n[`QBITS] && !issuing_on_agen1)
				agen1_rid <= {`QBIT{1'b1}};
			if (fcu_rid==n[`QBITS] && !issuing_on_fcu)
				fcu_rid <= {`QBIT{1'b1}};
					// The following line is a hack. The alu is done (tested above) so it
					// should be setting the state to CMT.
//					if (iq_state[alu0_id]==IQS_OUT)
//						iq_state[alu0_id] <= IQS_CMT;
			alu0_id <= n[`QBITS];
			alu0_rid <= iq_rid[n];
			alu0_instr	<= iq_instr[n];
			alu0_pc		<= iq_pc[n];
					// Agen output is not bypassed since there's only one
					// instruction (LEA) to bypass for.
      alu0_argI <= iq_const[n];
			argBypass(iq_argA_v[n],iq_argA_s[n],iq_argA[n],alu0_argA);
			argBypass(iq_argB_v[n],iq_argB_s[n],iq_argB[n],alu0_argB);
			argBypassS(iq_argS_v[n],iq_argS_s[n],iq_argS[n][7:0],alu0_argS);
			alu0_tgt    <= iq_tgt[n];
			alu0_sr_tgts <= iq_sr_tgts[n];
			alu0_dataready <= 1'b1;	//IsSingleCycle(iq_instr[n]);
			alu0_ld <= TRUE;
			iq_state[n] <= IQS_OUT;
    end

	if (`NUM_ALU > 1) begin
    for (n = 0; n < IQ_ENTRIES; n = n + 1)
      if ((iq_alu1_issue[n] && !(iq_v[n] && iq_stomp[n])
												&& (alu1_done))) begin
				iq_fuid[n] <= 3'd1;
				alu1_sourceid	<= n[`QBITS];
				if (alu0_rid==n[`QBITS] && !issuing_on_alu0)
					alu0_rid <= {`QBIT{1'b1}};
				if (agen0_rid==n[`QBITS] && !issuing_on_agen0)
					agen0_rid <= {`QBIT{1'b1}};
				if (agen1_rid==n[`QBITS] && !issuing_on_agen1)
					agen1_rid <= {`QBIT{1'b1}};
				if (fcu_rid==n[`QBITS] && !issuing_on_fcu)
					fcu_rid <= {`QBIT{1'b1}};
								// The following line is a hack. The alu is done (tested above) so it
								// should be setting the state to CMT.
	//							if (iq_state[alu1_id]==IQS_OUT)
	//								iq_state[alu1_id] <= IQS_CMT;
				alu1_id <= n[`QBITS];
				alu1_rid <= iq_rid[n];
				alu1_instr	<= iq_instr[n];
				alu1_pc		<= iq_pc[n];
				alu1_argI <= iq_const[n];
				argBypass(iq_argA_v[n],iq_argA_s[n],iq_argA[n],alu1_argA);
				argBypass(iq_argB_v[n],iq_argB_s[n],iq_argB[n],alu1_argB);
				argBypassS(iq_argS_v[n],iq_argS_s[n],iq_argS[n][7:0],alu1_argS);
				alu1_tgt    <= iq_tgt[n];
				alu1_sr_tgts <= iq_sr_tgts[n];
				alu1_dataready <= 1'b1;	//IsSingleCycle(iq_instr[n]);
				alu1_ld <= TRUE;
				iq_state[n] <= IQS_OUT;
      end
  end

    for (n = 0; n < IQ_ENTRIES; n = n + 1)
      if (iq_agen0_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
        if (~agen0_v) begin
					iq_fuid[n] <= 3'd2;
					agen0_sourceid	<= n[`QBITS];
					if (alu0_rid==n[`QBITS] && !issuing_on_alu0)
						alu0_rid <= {`QBIT{1'b1}};
					if (alu1_rid==n[`QBITS] && !issuing_on_alu1)
						alu1_rid <= {`QBIT{1'b1}};
					if (agen1_rid==n[`QBITS] && !issuing_on_agen1)
						agen1_rid <= {`QBIT{1'b1}};
					if (fcu_rid==n[`QBITS] && !issuing_on_fcu)
						fcu_rid <= {`QBIT{1'b1}};
					agen0_id <= n[`QBITS];
					agen0_rid <= iq_rid[n];
					agen0_instr	<= iq_instr[n];
					agen0_argI <= iq_const[n];
					argBypass(iq_argB_v[n],iq_argB_s[n],iq_argB[n],agen0_argB);
					agen0_dataready <= 1'b1;
					iq_state[n] <= IQS_OUT;
        end
      end

	if (`NUM_AGEN > 1) begin
    for (n = 0; n < IQ_ENTRIES; n = n + 1)
      if (iq_agen1_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
        if (~agen1_v) begin
					iq_fuid[n] <= 3'd3;
					agen1_sourceid	<= n[`QBITS];
					if (alu0_rid==n[`QBITS] && !issuing_on_alu0)
						alu0_rid <= {`QBIT{1'b1}};
					if (alu1_rid==n[`QBITS] && !issuing_on_alu1)
						alu1_rid <= {`QBIT{1'b1}};
					if (agen0_rid==n[`QBITS] && !issuing_on_agen0)
						agen0_rid <= {`QBIT{1'b1}};
					if (fcu_rid==n[`QBITS] && !issuing_on_fcu)
					fcu_rid <= {`QBIT{1'b1}};
					agen1_id <= n[`QBITS];
					agen1_rid <= iq_rid[n];
					agen1_instr	<= iq_instr[n];
//                 agen1_argB	<= iq_argB[n];	// ArgB not used by agen
					agen1_argI <= iq_const[n];
					argBypass(iq_argB_v[n],iq_argB_s[n],iq_argB[n],agen1_argB);
					agen1_dataready <= 1'b1;
					iq_state[n] <= IQS_OUT;
        end
      end
  end

  for (n = 0; n < IQ_ENTRIES; n = n + 1)
    if (iq_fcu_issue[n] && !(iq_v[n] && iq_stomp[n])) begin
      if (fcu_done) begin
					iq_fuid[n] <= 3'd6;
				fcu_sourceid	<= n[`QBITS];
				check_done(n[`QBITS]);
        fcu_rid <= iq_rid[n];
					if (alu0_rid==n[`QBITS] && !issuing_on_alu0)
						alu0_rid <= {`QBIT{1'b1}};
					if (alu1_rid==n[`QBITS] && !issuing_on_alu1)
						alu1_rid <= {`QBIT{1'b1}};
					if (agen0_rid==n[`QBITS] && !issuing_on_agen0)
						agen0_rid <= {`QBIT{1'b1}};
					if (agen1_rid==n[`QBITS] && !issuing_on_agen1)
						agen1_rid <= {`QBIT{1'b1}};
				fcu_id <= n[`QBITS];
				fcu_prevInstr <= fcu_instr;
				fcu_instr	<= iq_instr[n];
				fcu_hs		<= iq_hs[n];
				fcu_pc		<= iq_pc[n];
				fcu_nextpc <= iq_pc[n] + iq_len[n];
				fcu_pt     <= iq_pt[n];
				fcu_brdisp <= iq_const[n];
				fcu_sr_tgts <= iq_sr_tgts[n];
				//$display("Branch tgt: %h", {iq_instr[n][39:22],iq_instr[n][5:3],iq_instr[n][4:3]});
				fcu_branch <= iq_br[n];
				fcu_argI <= iq_const[n];
				argBypass(iq_argA_v[n],iq_argA_s[n],iq_argA[n],fcu_argA);
				argBypassS(iq_argS_v[n],iq_argS_s[n],iq_argS[n][6:0],fcu_argS);
				fcu_dataready <= 1'b1;
				fcu_clearbm <= `FALSE;
				fcu_ld <= TRUE;
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
		dramA_sr_bus <= 8'h00;
		dramA_sr_bus[1] <= rdat0[7:0]==8'h00;
		dramA_sr_bus[7] <= rdat0[7];
		dramA_sr_tgts <= 8'h82;
	end
	if (dram1 == `DRAMREQ_READY && dram1_load && `NUM_MEM > 1) begin
		dramB_v <= !iq_stomp[dram1_id];
		dramB_id <= dram1_id;
		dramB_rid <= dram1_rid;
		dramB_bus <= rdat1;
		dramB_sr_bus <= 8'h00;
		dramB_sr_tgts <= 8'h82;
		dramB_sr_bus[1] <= rdat1[7:0]==8'h00;
		dramB_sr_bus[7] <= rdat1[7];
	end

//
// determine if the instructions ready to issue can, in fact, issue.
// "ready" means that the instruction has valid operands but has not gone yet
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
	if (memissue[n])
		iq_memissue[n] <= `VAL;
	//iq_memissue <= memissue;
	missue_count <= issue_count;

	for (n = 0; n < IQ_ENTRIES; n = n + 1)
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

	if (last_issue0 < IQ_ENTRIES)
		tDram0Issue(last_issue0);
	if (last_issue1 < IQ_ENTRIES)
		tDram1Issue(last_issue1);
/*
	if (ohead[0]==heads[0])
		cmt_timer <= cmt_timer + 12'd1;
	else
		cmt_timer <= 12'd0;

	if (cmt_timer==12'd1000 && icstate==IDLE) begin
		iq_state[heads[0]] <= IQS_CMT;
		iq_exc[heads[0]] <= `FLT_CMT;
		cmt_timer <= 12'd0;
	end
*/
//
// COMMIT PHASE (dequeue only ... not register-file update)
//
// look at heads[0] and heads[1] and let 'em write to the register file if they are ready
//
//    always @(posedge clk) begin: commit_phase

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
if (dram0_load)
case(dram0)
`DRAMSLOT_AVAIL:	;
`DRAMSLOT_BUSY:
	if (iq_v[dram0_id] && !iq_stomp[dram0_id]) begin
		if (dhit0 & !dram0_unc) begin
//			dramA_v <= !iq_stomp[dram0_id];
//			dramA_id <= dram0_id;
//			dramA_rid <= dram0_rid;
//			dramA_bus <= rdat0;
//			dramA_sr_bus <= 8'h00;
//			dramA_sr_bus[1] <= rdat0[7:0]==8'h00;
//			dramA_sr_bus[7] <= rdat0[7];
//			dramA_sr_tgts <= 8'h82;
//			dram0 <= `DRAMSLOT_AVAIL;
			dram0 <= `DRAMREQ_READY;
		end
	end
	else begin
		dram0 <= `DRAMREQ_READY;
		dram0_load <= `FALSE;
		//xdati <= {13{lfsro}};
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

if (dram1_load)
case(dram1)
`DRAMSLOT_AVAIL:	;
`DRAMSLOT_BUSY:
	if (iq_v[dram1_id] && !iq_stomp[dram1_id]) begin
		if (dhit1 && !dram1_unc) begin
//			dramB_v <= !iq_stomp[dram1_id];
//			dramB_id <= dram1_id;
//			dramB_rid <= dram1_rid;
//			dramB_bus <= rdat1;
//			dramB_sr_bus <= 8'h00;
//			dramB_sr_tgts <= 8'h82;
//			dramB_sr_bus[1] <= rdat1[7:0]==8'h00;
//			dramB_sr_bus[7] <= rdat1[7];
			dram1 <= `DRAMREQ_READY;
		end
	end
	else begin
		dram1 <= `DRAMREQ_READY;
		dram1_load <= `FALSE;
		//xdati <= {13{lfsro}};
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
		bwhich <= 2'b00;

        if (~|wb_v && dram0_unc && dram0==`DRAMSLOT_BUSY && dram0_load
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
               dadr <= dram0_addr;
               dwrap <= dram0_wrap;
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
               dadr <= dram1_addr;
               dwrap <= dram1_wrap;
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

// Regular load
B_DLoadAck:
  if (dack_i|derr_i|tlb_miss|rdv_i) begin
  	if (dselx > 16'h00FF && dccnt==2'd0) begin
  		dsel <= dselx[15:8];
  		dstb <= `LOW;
  		dadr <= dadr + 16'd1;
  		bstate <= B_DLoadNack;
  	end
  	else begin
  		wb_nack();
  		bstate <= B_LSNAck;
  	end
		case(dccnt)
		2'd0:	xdati[103:0] <= dat_i >> (dadr[2:0] * 13);
		2'd1:	
			case(dsel)
			8'b00000000:	;
			8'b00000001:	xdati[103:91] <= dat_i;
			8'b00000011:	xdati[103:78] <= dat_i;
			8'b00000111:	xdati[103:65] <= dat_i;
			default:			;
			endcase
		default:	;
		endcase
    case(bwhich)
    2'b00:  begin
           		dram0 <= `DRAMREQ_READY;
//             	if (iq_stomp[dram0_id])
//             		iq_exc [dram0_id] <= `FLT_NONE;
//             	else
//             		iq_exc [ dram0_id ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
            end
    2'b01:  if (`NUM_MEM > 1) begin
             dram1 <= `DRAMREQ_READY;
//             	if (iq_stomp[dram1_id])
//             		iq_exc [dram1_id] <= `FLT_NONE;
//             	else
//	             iq_exc [ dram1_id ] <= tlb_miss ? `FLT_TLB : err_i ? `FLT_DRF : rdv_i ? `FLT_DRF : `FLT_NONE;
            end
    default:    ;
    endcase
    dccnt <= dccnt + 2'd1;
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
default:     bstate <= BIDLE;
endcase

`ifdef SIM
	$display("\n\n\n\n\n\n\n\n");
	$display("TIME %0d", $time);
	$display("%b %h #", pc_mask, pc);
	$display("%b %h #", pc_mask, pc + len1);
    $display ("--------------------------------------------------------------------- Regfile ---------------------------------------------------------------------");
  $display("ac: %h %d %d #", regsx[1], regIsValid[1], rf_source[1]);
  $display("xr: %h %d %d #", regsx[2], regIsValid[2], rf_source[2]);
  $display("yr: %h %d %d #", regsx[3], regIsValid[3], rf_source[3]);
  $display("sp: %h %d %d #", regsx[31], regIsValid[31], rf_source[31]);
  $display("sr: %h %d %d #", srx, regIsValid[AREGS], sr_source);
  $display("tmp1: %h %d %d #", regsx[4], regIsValid[4], rf_source[4]);
  $display("tmp2: %h %d %d #", regsx[5], regIsValid[5], rf_source[5]);
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
	$display("Insn%d: %h %h %h %h", 0, insnx[0], insnx[1], opcode1, opcode2);
	$display ("------------------------------------------------------------------------ Micro-op Buffer -----------------------------------------------------------------------");
	for (i = 0; i < UOQ_ENTRIES; i = i + 1)
		$display("%c%c %d: %c%c %h %h %h %h ins=%h#",
			i[`UOQ_BITS]==uoq_head ? "H":".",
			i[`UOQ_BITS]==uoq_tail[0] ? "T":".",
			i[`UOQ_BITS],
			uoq_v[i] ? "v" : "-",
			uoq_fl[i]==2'b01 ? "F" : uoq_fl[i]==2'b10 ? "L" : uoq_fl[i]==2'b11 ? "B" : "-",
			uoq_pc[i],
			uoq_uop[i],
			uoq_const[i],
			uoq_flagsupd[i],
			uoq_inst[i]
			);
	$display ("------------------------------------------------------------------------ Dispatch Buffer -----------------------------------------------------------------------");
	for (i=0; i<IQ_ENTRIES; i=i+1) 
	    $display("%c%c %d: %c%c%c %d %d %c%c %c %c%h %s %d,%s %h %h %d %d %d %h %d %d %d %h %d %d %d %h %d #",
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
		iq_fc[i] ? "F" : iq_mem[i] ? "M" : (iq_alu[i]==1'b1) ? "A" : "O", 
		iq_instr[i],fnMnemonic(iq_instr[i]), iq_tgt[i], fnRegT({1'b0,iq_tgt[i]}),
		iq_const[i],
		iq_argA[i], iq_src1[i], iq_argA_v[i], iq_argA_s[i],
		iq_argB[i], iq_src2[i], iq_argB_v[i], iq_argB_s[i],
		iq_argS[i], iq_src2[i], iq_argS_v[i], iq_argS_s[i],
		iq_pc[i],
		iq_sn[i]
		);
	$display ("------------- Reorder Buffer ------------");
	for (i = 0; i < RENTRIES; i = i + 1)
	$display("%c%c %d(%d): %c %h %d %h %h %h#",
		 (i[`RBITS]==heads[0])?"C":".",
		 (i[`RBITS]==tails[0])?"Q":".",
		  i[`RBITS],
		  rob_id[i],
		  rob_state[i]==RS_INVALID ? "-" :
		  rob_state[i]==RS_ASSIGNED ? "A"  :
		  rob_state[i]==RS_CMT ? "C"  : "D",
		  rob_exc[i],
		  rob_tgt[i],
		  rob_res[i],
		  rob_sr_res[i],
		  rob_sr_tgts[i]
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
	$display("%d %h %h %h %c%s %h %h #",
		alu0_dataready, 0, alu0_argT, alu0_argB, 
		 (IsFlowCtrl(alu0_instr) ? 98 : IsMem(alu0_instr) ? 109 : 97),
		fnMnemonic(alu0_instr), alu0_sourceid, alu0_pc);
	$display("%d %h %o 0 #", alu0_v, alu0_bus, alu0_id);
	if (`NUM_ALU > 1) begin
		$display("%d %h %h %h %c%s %h %h #",
			alu1_dataready, 0, alu1_argT, alu1_argB, 
		 	(IsFlowCtrl(alu1_instr) ? 98 : IsMem(alu1_instr) ? 109 : 97),
			fnMnemonic(alu1_instr), alu1_sourceid, alu1_pc);
		$display("%d %h %o 0 #", alu1_v, alu1_bus, alu1_id);
	end
	$display("FCU");
	$display("%d %h %h %h %h %c%c #", fcu_v, fcu_bus, 0, fcu_argT, fcu_argB, fcu_takb?"T":"-", fcu_pt?"T":"-");
	$display("%c %h %h %h %h #", fcu_branchmiss?"m":" ", fcu_sourceid, fcu_misspc, fcu_nextpc, fcu_brdisp); 
    $display("Commit");
	$display("0: %c %h %o %d #", commit0_v?"v":" ", commit0_bus, commit0_id, commit0_tgt);
	$display("1: %c %h %o %d #", commit1_v?"v":" ", commit1_bus, commit1_id, commit1_tgt);
	$display("2: %c %h %o %d #", commit2_v?"v":" ", commit2_bus, commit2_id, commit2_tgt);
    $display("micro-ops committed: %d  ticks: %d ", uop_committed, tick);
    $display("micro-ops queued: %d", uop_queued);
    $display("micro-ops stomped by branches: %d ", ins_stomped);
    $display("instr. queued: %d", ins_queued);
    $display("instr. committed: %d", ins_committed);
    $display("I$ load stalls cycles: %d", ic_stalls);
    $display("Branch override BTB: %d", br_override);
    $display("Total branches: %d", br_total);
    $display("Missed branches: %d", br_missed);
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
end	// end of clock domain

// ============================================================================
// ============================================================================
// Start of Tasks
// ============================================================================
// ============================================================================

task flagsUpd;
input MicroOp op;
output [6:0] upd;
case(op.opcode)
ADDu:	upd = 7'b1101001;
SUBu:	
	if (op.tgt==4'd0)
		upd = 7'b1001001;
	else
		upd = 7'b1101001;
ANDu:
	if (op.tgt==4'd0)
		upd = 7'b1100001;
	else
		upd = 7'b1000001;
ORu:	upd = 7'b1000001;
EORu:	upd = 7'b1000001;
ASLu:	upd = 7'b1001001;
ROLu:	upd = 7'b1001001;
LSRu:	upd = 7'b1001001;
RORu:	upd = 7'b1001001;
default:
	upd = 7'h00;
endcase
endtask

// Note the use of blocking(=) assigments here. For some reason in sim <= 
// assignments didn't work.
task argBypass;
input v;
input [`RBITS] src;
input [WID-1:0] iq_arg;
output [WID-1:0] arg;
begin
`ifdef FU_BYPASS
	if (v)
		arg = iq_arg;
	else
		case(src)
		alu0_rid:	arg = ralu0_bus;
		alu1_rid:	arg = ralu1_bus;
		dramA_rid:	arg = dramA_bus;
		dramB_rid:	arg = dramB_bus;
		default:	arg = {1{16'hDEAD}};
		endcase
`else
	arg = iq_arg;
`endif           
end
endtask

task argBypassS;
input v;
input [`RBITS] src;
input [6:0] iq_arg;
output [6:0] arg;
begin
`ifdef FU_BYPASS
	if (v)
		arg = iq_arg;
	else
		case(src)
		alu0_rid:	arg = alu0_sro;
		alu1_rid:	arg = alu1_sro;
		default:	arg = 8'h04;			// IRQ masked (shouldn't get here)
		endcase
`else
	arg = iq_arg;
`endif
end
endtask

task check_abort_load;
begin
  case(bwhich)
  2'd0:	if (iq_stomp[dram0_id]) begin bstate <= BIDLE; dram0 <= `DRAMREQ_READY; end
  2'd1:	if (iq_stomp[dram1_id]) begin bstate <= BIDLE; dram1 <= `DRAMREQ_READY; end
  default:	if (iq_stomp[dram0_id]) begin bstate <= BIDLE; dram0 <= `DRAMREQ_READY; end
  endcase
end
endtask

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

// Detect overflow of a sequence number, done by testing the high order bit for
// each queue entry. Amounts to a wide or gate.
function sn_overflow;
input dummy;
begin
	sn_overflow = FALSE;
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
		if (iq_sn[n][`SNBIT])
			sn_overflow = TRUE;
end
endfunction

// Increment the head pointers
// Also increments the instruction counter
// Used when instructions are committed.
// Also clear any outstanding state bits that foul things up.
//
task head_inc;
input [`QBITS] amt;
begin
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
		if (n < amt) begin
			if (!((heads[n]==tails[0] && queuedCnt==3'd1)
			|| (heads[n]==tails[1] && queuedCnt==3'd2)
			|| (heads[n]==tails[2] && queuedCnt==3'd3)
			|| (heads[n]==tails[3] && queuedCnt==3'd4)
			)) begin
				iq_state[heads[n]] <= IQS_INVALID;
				rob_state[heads[n]] <= RS_INVALID;
				iq_mem[heads[n]] <= `FALSE;
				iq_alu[heads[n]] <= `FALSE;
				iq_fc[heads[n]] <= `FALSE;
//				if (alu0_id==heads[n] && iq_state[alu0_id]==IQS_CMT
//					&& !issuing_on_alu0)
//					alu0_dataready <= `FALSE;
//				if (alu1_id==heads[n] && iq_state[alu1_id]==IQS_CMT
//					&& !issuing_on_alu1)
//					alu1_dataready <= `FALSE;
//					$display("head_inc: IQS_INVALID[%d]",heads[n]);
		end
	end
			
//		if (iq_v[n])
//			iq_sn[n] <= /*(tosub > iq_sn[n]) ? 1'd0 : */iq_sn[n] - tosub;
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
					//rob_state[rob_heads[n]] <= RS_INVALID;
			end
		end
end
endtask

task setargs;
input [`QBITS] nn;
input [`RBITS] id;
input v;
input [51:0] bus;
begin
  if (iq_argB_v[nn] == `INV && iq_argB_s[nn][`RBITS] == id && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argB[nn] <= bus;
		iq_argB_v[nn] <= `VAL;
  end
  if (iq_argA_v[nn] == `INV && iq_argA_s[nn][`RBITS] == id && iq_v[nn] == `VAL && v == `VAL) begin
		iq_argA[nn] <= bus;
		iq_argA_v[nn] <= `VAL;
  end
end
endtask

task setargs2;
begin
	for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
		for (j = 0; j < IQ_ENTRIES; j = j + 1) begin
			if (iq_state[j]==IQS_CMT && iq_rid[j]==iq_argB_s[n] && iq_argB_v[n]==`INV) begin
				iq_argB[n] <= rob_res[iq_rid[j]];
				iq_argB_v[n] <= `VAL;
			end
			if (iq_state[j]==IQS_CMT && iq_rid[j]==iq_argA_s[n] && iq_argA_v[n]==`INV) begin
				iq_argA[n] <= rob_res[iq_rid[j]];
				iq_argA_v[n] <= `VAL;
			end
		end
	end
end
endtask

task set_sr_args;
input [`QBITS] nn;
input [`RBITS] id;
input v;
input [7:0] bus;
input [7:0] mask;
begin
  if (iq_argS_v[nn] == `INV && iq_argS_s[nn][`RBITS] == id && iq_v[nn] == `VAL && v == `VAL) begin
  	if (mask[0]) iq_argS[nn][0] <= bus[0];
  	if (mask[1]) iq_argS[nn][1] <= bus[1];
  	if (mask[2]) iq_argS[nn][2] <= bus[2];
  	if (mask[3]) iq_argS[nn][3] <= bus[3];
  	if (mask[4]) iq_argS[nn][4] <= bus[4];
  	if (mask[5]) iq_argS[nn][5] <= bus[5];
  	if (mask[6]) iq_argS[nn][6] <= bus[6];
  	if (mask[7]) iq_argS[nn][7] <= bus[7];
		if (|mask) iq_argS_v[nn] <= `VAL;
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
			iq_argA_v [tails[tails_rc(pat,row)]] <= regIsValid[RaReal[row]] | SourceAValid(uoq_uop[(uoq_head+row) % UOQ_ENTRIES]);
			iq_argA_s [tails[tails_rc(pat,row)]] <= RaReal[row]==6'd32 ? sr_source : rf_source[RaReal[row]];
			// iq_argA is a constant
			iq_argB_v [tails[tails_rc(pat,row)]] <= regIsValid[RnReal[row]] || RnReal[row]==6'd0 || SourceBValid(uoq_uop[(uoq_head+row) % UOQ_ENTRIES]);
			iq_argB_s [tails[tails_rc(pat,row)]] <= rf_source[RnReal[row]];
			iq_argS_v [tails[tails_rc(pat,row)]] <= regIsValid[AREGS] | SourceSValid(uoq_uop[(uoq_head+row) % UOQ_ENTRIES]);
			iq_argS_s [tails[tails_rc(pat,row)]] <= sr_source;
			for (col = 0; col < QSLOTS; col = col + 1) begin
				if (col < row) begin
					if (pat[col]) begin
						if (RaReal[row]==RdReal[col] && slot_rfw[col] && RaReal[row] != 6'd0) begin
							iq_argA_v [tails[tails_rc(pat,row)]] <= SourceAValid(uoq_uop[(uoq_head+row) % UOQ_ENTRIES]);
							iq_argA_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end
						if (RnReal[row]==RdReal[col] && slot_rfw[col] && RnReal[row] != 6'd0) begin
							iq_argB_v [tails[tails_rc(pat,row)]] <= SourceBValid(uoq_uop[(uoq_head+row) % UOQ_ENTRIES]);
							iq_argB_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end
//						if (3'd7==Rd[col] && slot_sr_tgts[col]!=8'h00) begin
						if ((fnNeedSr(uoq_uop[(uoq_head+row) % UOQ_ENTRIES]) & slot_sr_tgts[col]) != 7'b0) begin
							iq_argS_v [tails[tails_rc(pat,row)]] <= SourceSValid(uoq_uop[(uoq_head+row) % UOQ_ENTRIES]);
							iq_argS_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end
						else begin
							iq_argS_v [tails[tails_rc(pat,row)]] <= `VAL;
							iq_argS_s [tails[tails_rc(pat,row)]] <= sr_source;
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
	iq_cmp	 [nn]  <= bus[`IB_CMP];
	iq_bt   [nn]  <= bus[`IB_BT];
	iq_alu  [nn]  <= bus[`IB_ALU];
	iq_fc   [nn]  <= bus[`IB_FC];
	iq_load [nn]  <= bus[`IB_LOAD];
	iq_store[nn]  <= bus[`IB_STORE];
	iq_memsz[nn]  <= bus[`IB_MEMSZ];
	iq_mem  [nn]  <= bus[`IB_MEM];
	iq_jmp  [nn]  <= bus[`IB_JMP];
	iq_br   [nn]  <= bus[`IB_BR];
	iq_src1   [nn]  <= bus[`IB_SRC1];
	iq_src2   [nn]  <= bus[`IB_SRC2];
	iq_dst   [nn]  <= bus[`IB_DST];
	iq_rfw  [nn]  <= bus[`IB_RFW];
	iq_need_sr[nn] <= bus[`IB_NEED_SR];
end
endtask

task queue_uop;
input [`UOQ_BITS] ndx;
input [`ABITS] pc;
input MicroOp op;
input [1:0] fl;
input [6:0] flagmask;
input hs;
input [3:0] size;
begin
	uoq_v[ndx] <= `VAL;
	uoq_pc[ndx] <= pc;
	uoq_uop[ndx] <= op;
	uoq_fl[ndx] <= fl;
	//uoq_flagsupd[ndx] <= flagmask;
	uoq_hs[ndx] <= hs;
	uoq_size[ndx] <= size;
end
endtask

task queue_slot;
input [2:0] slot;
input [`QBITS] ndx;
input [`SNBITS] seqnum;
input [`IBTOP:0] id_bus;
input [`RBITS] rid;
begin
	iq_rid[ndx] <= rid;
	iq_sn[ndx] <= seqnum;
	iq_state[ndx] <= IQS_QUEUED;
	//iq_br_tag[ndx] <= btag;
	iq_pc[ndx] <= uoq_pc[(uoq_head+slot) % UOQ_ENTRIES];
	iq_len[ndx] <= uoq_ilen[(uoq_head+slot) % UOQ_ENTRIES];
	iq_instr[ndx][5:0] <= uoq_uop[(uoq_head+slot) % UOQ_ENTRIES].opcode;
	iq_const[ndx] <= uoq_const[(uoq_head+slot) % UOQ_ENTRIES];
	iq_hs[ndx] <= uoq_hs[(uoq_head+slot) % UOQ_ENTRIES];
	iq_fl[ndx] <= uoq_fl[(uoq_head+slot) % UOQ_ENTRIES];
	//iq_argI[ndx] <= uoq_const[(uoq_head+slot) % UOQ_ENTRIES];
	iq_argA[ndx] <= argA[slot % FSLOTS];
	iq_argB[ndx] <= argB[slot % FSLOTS];
	iq_argS[ndx] <= srx;//argS[slot % FSLOTS];
	iq_argA_v[ndx] <= regIsValid[RaReal[slot % FSLOTS]] || SourceAValid(uoq_uop[(uoq_head+slot) % UOQ_ENTRIES]);
	iq_argB_v[ndx] <= regIsValid[RnReal[slot % FSLOTS]] || RnReal[slot % FSLOTS]==6'd0 || SourceBValid(uoq_uop[(uoq_head+slot) % UOQ_ENTRIES]);
	iq_argS_v[ndx] <= regIsValid[AREGS] || SourceSValid(uoq_uop[(uoq_head+slot) % UOQ_ENTRIES]);
	iq_argA_s[ndx] <= RaReal[slot % FSLOTS]==6'd32 ? sr_source : rf_source[RaReal[slot % FSLOTS]];
	iq_argB_s[ndx] <= rf_source[RnReal[slot % FSLOTS]];
	iq_argS_s[ndx] <= sr_source;
	iq_sr_tgts[ndx] <= uoq_flagsupd[(uoq_head+slot) % UOQ_ENTRIES];
	iq_pt[ndx] <= uoq_takb[(uoq_head+slot) % UOQ_ENTRIES];
	iq_tgt[ndx] <= RdReal[slot % FSLOTS];
	set_insn(ndx,id_bus);
	rob_pc[rid] <= uoq_pc[(uoq_head+slot) % UOQ_ENTRIES];
	rob_tgt[rid] <= RdReal[slot % FSLOTS];
	rob_rfw[rid] <= IsRFW(uoq_uop[(uoq_head+slot) % UOQ_ENTRIES].opcode);
	rob_res[rid] <= 1'd0;
	rob_sr_tgts[rid] <= uoq_flagsupd[(uoq_head+slot) % UOQ_ENTRIES];
	rob_sr_res[rid] <= 1'd0;
	rob_state[rid] <= RS_ASSIGNED;
	rob_id[rid] <= ndx;
end
endtask

task tDram0Issue;
input [`QBITS] n;
begin
	if (iq_state[n]==IQS_AGEN) begin
//	dramA_v <= `INV;
		dram0 		<= `DRAMSLOT_BUSY;
		dram0_id 	<= n[`QBITS];
		dram0_rid <= iq_rid[n];
		dram0_instr <= iq_instr[n];
		dram0_tgt 	<= iq_tgt[n];
		dram0_data <= iq_argA[n][WID-1:0];
		dram0_addr	<= iq_ma[n];
		dram0_unc   <= 1'b0;//iq_ma[n][31:20]==12'hFFD || !dce;
		dram0_wrap  <= iq_wrap[n] && ((iq_ma[n] & 8'hFF) == 8'hFF);
		dram0_memsize <= iq_memsz[n];
		dram0_load <= iq_load[n];
		dram0_store <= iq_store[n];
		dram0_preload <= iq_load[n] & iq_tgt[n]==6'd0;
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
	dram1_rid <= iq_rid[n];
	dram1_instr <= iq_instr[n];
	dram1_tgt 	<= iq_tgt[n];
	dram1_data <= iq_argA[n][WID-1:0];
	dram1_addr	<= iq_ma[n];
	dram1_wrap  <= iq_wrap[n] && ((iq_ma[n] & 8'hFF) == 8'hFF);
	//	             if (ol[iq_thrd[n]]==`OL_USER)
	//	             	dram1_seg   <= (iq_rs1[n]==5'd30 || iq_rs1[n]==5'd31) ? {ss[iq_thrd[n]],13'd0} : {ds[iq_thrd[n]],13'd0};
	//	             else
	dram1_unc   <= 1'b0;//iq_ma[n][31:20]==12'hFFD || !dce;
	dram1_memsize <= iq_memsz[n];
	dram1_load <= iq_load[n];
	dram1_store <= iq_store[n];
	dram1_preload <= iq_load[n] & iq_tgt[n]==6'd0;
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

module decoder6 (num, rfw, out);
input [5:0] num;
input rfw;
output [32:0] out;

wire [32:0] out1;

assign out1 = {32'd0,rfw} << num;
assign out = out1[32:0];

endmodule

module instLength(opcode,len);
input [5:0] opcode;
output reg [2:0] len;

always @*
case(opcode)
`ADD_3R:	len <= 3'd2;
`ADD_I23:	len <= 3'd3;
`ADD_I36:	len <= 3'd4;
`JMP:			len <= 3'd4;
`ASL_3R:	len <= 3'd2;
`SUB_3R:	len <= 3'd2;
`SUB_I23:	len <= 3'd3;
`SUB_I36:	len <= 3'd4;
`JSR:			len <= 3'd4;
`LSR_3R:	len <= 3'd2;
`RETGRP:	len <= 3'd1;
`ROL_3R:	len <= 3'd2;
`AND_3R:	len <= 3'd2;
`AND_I23: len <= 3'd3;
`AND_I36: len <= 3'd4;
`BRKGRP:	len <= 3'd1;
`ROR_3R:	len <= 3'd2;
`OR_3R:		len <= 3'd2;
`OR_I23:	len <= 3'd3;
`OR_I36:	len <= 3'd4;
`JMP_RN:	len <= 3'd1;
`SEP:			len <= 3'd1;
`EOR_3R:	len <= 3'd2;
`EOR_I23:	len <= 3'd3;
`EOR_I36: len <= 3'd4;
`JSR_RN:	len <= 3'd1;
`REP:			len <= 3'd1;
`LD_D9:		len <= 3'd2;
`LD_D23:	len <= 3'd3;
`LD_D36:	len <= 3'd4;
`LDB_D36:	len <= 3'd4;
`PLP:			len <= 3'd1;
`POP:			len <= 3'd1;
`ST_D9:		len <= 3'd2;
`ST_D23:	len <= 3'd3;
`ST_D36:	len <= 3'd4;
`STB_D36:	len <= 3'd4;
`PHP:			len <= 3'd1;
`PSH:			len <= 3'd1;
`BccD4a:	len <= 3'd1;
`BccD4b:	len <= 3'd1;
`BccD17a:	len <= 3'd2;
`BccD17b:	len <= 3'd2;
default:	len <= 3'd1;	// unimplemented instruction
endcase
endmodule

// Compute the address of the next set of micro-ops. The next address will not
// be used unless there is stall cycle required to queue more micro-ops than
// can be queued in a single cycle.

module nextMip(rst, clk, mip1, mip2, uopqd, uop_prg, nmip1, nmip2);
input rst;
input clk;
input [7:0] mip1;
input [7:0] mip2;
input [2:0] uopqd;
input MicroOp uop_prg [0:188];
output reg [7:0] nmip1;
output reg [7:0] nmip2;

always @(posedge clk)
if (rst) begin
	nmip1 <= 1'd1;
	nmip2 <= 1'd1;
end
else begin
	nmip1 <= mip1 + uopqd;
	nmip2 <= mip2;	// default to no increment
	if (uop_prg[mip1].fl[1]) begin	// If it's the end of 1st sequence
		nmip1 <= 1'd0;
		if (uopqd > 3'd1) begin
			nmip2 <= mip2 + uopqd - 3'd1;
			if (uop_prg[mip2].fl[1])
				nmip2 <= 1'd0;
			else begin
				if (uopqd > 3'd2) begin
					nmip2 <= mip2 + uopqd - 3'd2;
					if (uop_prg[mip2+1].fl[1])
						nmip2 <= 1'd0;
					else begin
						if (uopqd > 3'd3) begin
							nmip2 <= mip2 + uopqd - 3'd3;
							if (uop_prg[mip2+2].fl[1])
								nmip2 <= 1'd0;
							else
								nmip2 <= nmip2 + uopqd - 3'd4;
						end
					end
				end
			end
		end
	end
	// Not the end of the first sequence. Did anything queue?
	// No need to increment pointers if nothing queued.
	else begin
		if (uopqd > 3'd1) begin
			if (uop_prg[mip1+1].fl[1]) begin
				nmip1 <= 1'd0;
				if (uopqd > 3'd2) begin
					nmip2 <= mip2 + uopqd - 3'd2;
					if (uop_prg[mip2].fl[1])
						nmip2 <= 1'd0;
					else begin
						if (uopqd > 3'd3) begin
							nmip2 <= mip2 + uopqd - 3'd3;
							if (uop_prg[mip2+1].fl[1])
								nmip2 <= 1'd0;
							else
								nmip2 <= nmip2 + uopqd - 3'd4;
						end
					end
				end
			end
			else begin
				if (uop_prg[mip1+2].fl[1]) begin
					nmip1 <= 1'd0;
					if (uopqd > 3'd3) begin
						nmip2 <= nmip2 + uopqd - 3'd3;
						if (uop_prg[mip2].fl[1])
							nmip2 <= 1'd0;
						else
							nmip2 <= nmip2 + uopqd - 3'd4;
					end
				end
				else begin
					if (uop_prg[mip1+3].fl[1])
						nmip1 <= 1'd0;
				end
			end
		end
	end
end

endmodule
