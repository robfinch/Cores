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

`include "rtf65004-config.sv"
`include "rtf65004-defines.sv"

module rtf65000(rst_i, clk_i, clk2x_i, clk4x_i, tm_clk_i, irq_i, 
		bte_o, cti_o, bok_i, cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_o, dat_i,
    icl_o, exc_o);
parameter WID = 16;
input rst_i;
input clk_i;
input clk2x_i;
input clk4x_i;
input tm_clk_i;
input irq_i;
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
output icl_o;
output [7:0] exc_o;
parameter TM_CLKFREQ = 20000000;
parameter UOQ_ENTRIES = `UOQ_ENTRIES;
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter QSLOTS = `QSLOTS;
parameter RENTRIES = `RENTRIES;
parameter RSLOTS = `RSLOTS;
parameter AREGS = 8;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;
parameter VAL = 1'b1;
parameter INV = 1'b0;
parameter RSTIP = 16'hFFFC;
parameter BRKIP = 16'hFFFE;
parameter DEBUG = 1'b0;
parameter DBW = 16;
parameter ABW = 16;
parameter AMSB = ABW-1;
parameter RBIT = 6;
parameter WB_DEPTH = 7;

// Memory access sizes
parameter byt = 3'd0;
parameter wyde = 3'd1;

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

`include "rtf65000-busStates.sv"

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

reg [7:0] ac;
reg [7:0] xr;
reg [7:0] yr;
reg [7:0] sp;
reg [15:0] pc;
reg [15:0] tmp;
reg [7:0] sr;

reg [15:0] rfoa [0:QSLOTS-1];
reg [15:0] rfob [0:QSLOTS-1];

wire tlb_miss;
wire exv;

reg q1, q2;	// number of macro instructions queued


wire [95:0] ic1_out;
wire [63:0] ic2_out;
wire [31:0] ic3_out;

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

wire [3:0] len1, len2, len3;
reg [23:0] insnx [0:1];

wire [`QBITS] tails [0:QSLOTS-1];
wire [`QBITS] heads [0:IQ_ENTRIES-1];
wire [`RBITS] rob_tails [0:RSLOTS-1];
wire [`RBITS] rob_heads [0:RSLOTS-1];

// Micro-op queue
reg [UOQ_ENTRIES-1:0] uoq_v;
reg [15:0] uoq_pc [0:UOQ_ENTRIES-1];
reg [15:0] uoq_uop [0:UOQ_ENTRIES-1];
reg [15:0] uoq_const [0:UOQ_ENTRIES-1];
reg [1:0] uoq_fl;		// first or last micro-op
reg [1:0] uoq_flagsupd [0:UOQ_ENTRIES-1];
reg [UOQ_ENTRIES-1:0] uqo_jc;
reg [UOQ_ENTRIES-1:0] uqo_br;
reg [UOQ_ENTRIES-1:0] uqo_ret;

// Issue queue
reg [IQ_ENTRIES-1:0] iq_v;						// valid indicator (set from iq_state)
reg [IQ_ENTRIES-1:0] iq_done;
reg [IQ_ENTRIES-1:0] iq_out;
reg [IQ_ENTRIES-1:0] iq_agen;
reg [2:0] iq_state [0:IQ_ENTRIES-1];
reg [`SNBITS] iq_sn  [0:IQ_ENTRIES-1];		// sequence number
reg [15:0] iq_pc [0:IQ_ENTRIES-1];	// program counter associated with instruction
reg [15:0] iq_ma [0:IQ_ENTRIES-1];		// memory address
reg [5:0] iq_instr [0:IQ_ENTRIES-1];	// micro-op instruction
reg [1:0] iq_fl [0:IQ_ENTRIES-1];			// first or last indicators
reg [IQ_ENTRIES-1:0] iq_alu = 1'h0;  	// alu type instruction
reg [IQ_ENTRIES-1:0] iq_canex = 8'h00;	// true if it's an instruction that can exception
reg [IQ_ENTRIES-1:0] iq_mem;	// touches memory: 1 if LW/SW
reg [IQ_ENTRIES-1:0] iq_load;	// is a memory load instruction
reg [IQ_ENTRIES-1:0] iq_store;	// is a memory store instruction
reg [IQ_ENTRIES-1:0] iq_rmw;	// memory RMW op
reg [IQ_ENTRIES-1:0] iq_bt;						// branch taken
reg [IQ_ENTRIES-1:0] iq_pt;						// predicted taken branch
reg [IQ_ENTRIES-1:0] iq_fc;						// flow control instruction
reg [IQ_ENTRIES-1:0] iq_jmp;					// changes control flow: 1 if BEQ/JALR
reg [IQ_ENTRIES-1:0] iq_br;						// branch instruction
reg [IQ_ENTRIES-1:0] iq_rts;
reg [IQ_ENTRIES-1:0] iq_irq;
reg [IQ_ENTRIES-1:0] iq_brk;
reg [IQ_ENTRIES-1:0] iq_rti;
reg [IQ_ENTRIES-1:0] iq_rfw;	// writes to register file
reg [3:0] iq_exc	[0:IQ_ENTRIES-1];	// only for branches ... indicates a HALT instruction
reg [2:0] iq_tgt [0:IQ_ENTRIES-1];		// target register
reg [15:0] iq_argA [0:IQ_ENTRIES-1];	// First argument
reg [15:0] iq_argB [0:IQ_ENTRIES-1];	// Second argument
reg [ 7:0] iq_argS [0:IQ_ENTRIES-1];	// status register input
reg [`RBITS] iq_argA_s [0:IQ_ENTRIES-1];
reg [`RBITS] iq_argB_s [0:IQ_ENTRIES-1]; 
reg [`RBITS] iq_argS_s [0:IQ_ENTRIES-1];
reg [IQ_ENTRIES-1:0] iq_argA_v;
reg [IQ_ENTRIES-1:0] iq_argB_v;
reg [IQ_ENTRIES-1:0] iq_argS_v;
reg [IQ_ENTRIES-1:0] iq_uses_sr;		// instruction uses the status register (eg adc, php)
reg [1:0] iq_sr_tgts [0:IQ_ENTRIES-1];			// status register bits targeted
reg [`RBITS] iq_rid [0:IQ_ENTRIES-1];	// index of rob entry

// Re-order buffer
reg [RENTRIES-1:0] rob_v;
reg [`QBITS] rob_id [0:RENTRIES-1];	// instruction queue id that owns this entry
reg [1:0] rob_state [0:RENTRIES-1];
reg [`ABITS] rob_pc	[0:RENTRIES-1];	// program counter for this instruction
reg [4:0] rob_instr[0:RENTRIES-1];	// instruction opcode
reg [7:0] rob_exc [0:RENTRIES-1];
reg [15:0] rob_ma [0:RENTRIES-1];
reg [15:0] rob_res [0:RENTRIES-1];
reg [7:0] rob_sr [0:RENTRIES-1];		// status register result
reg [RBIT:0] rob_tgt [0:RENTRIES-1];
reg [7:0] rob_crres [0:RENTRIES-1];

// debugging
initial begin
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	iq_argA_s[n] <= 1'd0;
	iq_argB_s[n] <= 1'd0;
	iq_argS_s[n] <= 1'd0;
end

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

reg [AREGS-1:1] livetarget;
reg [AREGS-1:1] iq_livetarget [0:IQ_ENTRIES-1];
reg [AREGS-1:1] iq_latestID [0:IQ_ENTRIES-1];
reg [AREGS-1:1] iq_cumulative [0:IQ_ENTRIES-1];
wire  [AREGS-1:1] iq_out2 [0:IQ_ENTRIES-1];
wire  [AREGS-1:1] iq_out2a [0:IQ_ENTRIES-1];

wire [QSLOTS-1:0] take_branch;

reg         id1_v;
reg   [`QBITS] id1_id;
reg  [23:0] id1_instr;
reg         id1_pt;
reg   [5:0] id1_Rt;
wire [`IBTOP:0] id_bus [0:QSLOTS-1];

reg         id2_v;
reg   [`QBITS] id2_id;
reg  [23:0] id2_instr;
reg         id2_pt;
reg   [5:0] id2_Rt;

reg         id3_v;
reg   [`QBITS] id3_id;
reg  [23:0] id3_instr;
reg         id3_pt;
reg   [5:0] id3_Rt;

reg [`SNBITS] alu0_sn;
reg 				alu0_cmt;
wire				alu0_abort;
reg        alu0_ld;
reg        alu0_dataready;
wire       alu0_done;
wire       alu0_idle;
reg  [`QBITS] alu0_sourceid;
reg [`RBITS] alu0_rid;
reg [23:0] alu0_instr;
reg        alu0_mem;
reg        alu0_load;
reg        alu0_store;
reg        alu0_shft;
reg [RBIT:0] alu0_Ra;
reg [VWID-1:0] alu0_argA;
reg [VWID-1:0] alu0_argB;
reg [VWID-1:0] alu0_argC;
reg [WID-1:0] alu0_argI;	// only used by BEQ
reg [RBIT:0] alu0_tgt;
reg [`ABITS] alu0_pc;
reg [WID-1:0] alu0_bus;
wire [WID-1:0] alu0_out;
wire [7:0] alu0_cro;
wire  [`QBITS] alu0_id;
(* mark_debug="true" *)
wire  [`XBITS] alu0_exc;
wire        alu0_v;
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
wire       alu1_done;
wire       alu1_idle;
reg  [`QBITS] alu1_sourceid;
reg [`RBITS] alu1_rid;
reg [39:0] alu1_instr;
reg        alu1_mem;
reg        alu1_load;
reg        alu1_store;
reg        alu1_shft;
reg [RBIT:0] alu1_Ra;
reg [WID-1:0] alu1_argA;
reg [WID-1:0] alu1_argB;
reg [WID-1:0] alu1_argC;
reg [WID-1:0] alu1_argI;	// only used by BEQ
reg [RBIT:0] alu1_tgt;
reg [`ABITS] alu1_pc;
reg [WID-1:0] alu1_bus;
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
reg [`SNBITS] agen0_sn;
reg [`QBITS] agen0_sourceid;
wire [`QBITS] agen0_id;
reg [`RBITS] agen0_rid;
reg [RBIT:0] agen0_tgt;
reg agen0_dataready;
reg [2:0] agen0_unit;
reg [23:0] agen0_instr;
reg agen0_mem2;
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
reg [`SNBITS] agen1_sn;
reg [`QBITS] agen1_sourceid;
wire [`QBITS] agen1_id;
reg [`RBITS] agen1_rid;
reg [RBIT:0] agen1_tgt;
reg agen1_dataready;
reg [2:0] agen1_unit;
reg [39:0] agen1_instr;
reg agen1_mem2;
reg agen1_memdb;
reg agen1_memsb;
reg [AMSB:0] agen1_ma;
reg [WID-1:0] agen1_res;
reg [WID-1:0] agen1_argA, agen1_argB, agen1_argC, agen1_argI;
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
reg [23:0] fcu_instr;
reg [23:0] fcu_prevInstr;
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
reg [WID-1:0] fcu_argI;	// only used by BEQ
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
reg [23:0] rmw_instr;

// write buffer
wire [2:0] wb_ptr;
wire [WID-1:0] wb_data;
wire [`ABITS] wb_addr [0:WB_DEPTH-1];
wire [1:0] wb_ol;
wire [WB_DEPTH-1:0] wb_v;
wire wb_rmw;
wire [IQ_ENTRIES-1:0] wb_id;
wire [IQ_ENTRIES-1:0] wbo_id;
wire [1:0] wb_sel;
reg wb_en;
wire wb_hit0, wb_hit1;

reg branchmiss = 1'b0;
reg branchhit = 1'b0;
reg  [`QBITS] missid;

wire [1:0] issue_count;
reg [1:0] missue_count;
wire [IQ_ENTRIES-1:0] memissue;

wire        dram_avail;
reg	 [2:0] dram0;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [2:0] dram1;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg [79:0] dram0_argI, dram0_argB;
reg [WID-1:0] dram0_data;
reg [`ABITS] dram0_addr;
reg [23:0] dram0_instr;
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
reg [15:0] dram1_argI, dram1_argB;
reg [WID-1:0] dram1_data;
reg [`ABITS] dram1_addr;
reg [23:0] dram1_instr;
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
reg [WID-1:0] commit0_bus;
reg [7:0] commit0_crbus;
reg [3:0] commit0_rid;
reg commit0_tgts_sr;
reg commit1_v;
reg [`RBITS] commit1_id;
reg [RBIT:0] commit1_tgt;
reg [WID-1:0] commit1_bus;
reg [7:0] commit1_crbus;
reg [3:0] commit1_rid;
reg commit1_tgts_sr;
reg commit2_v;
reg [`RBITS] commit2_id;
reg [RBIT:0] commit2_tgt;
reg [WID-1:0] commit2_bus;
reg [7:0] commit2_crbus;
reg [3:0] commit2_rid;
reg commit2_tgts_sr;

reg [QSLOTS-1:0] queuedOn;
reg [QENTRIES-1:0] rqueuedOn;
wire [QSLOTS-1:0] queuedOnp;
wire [QSLOTS-1:0] predict_taken;
wire predict_taken0;
wire predict_taken1;
wire predict_taken2;
wire [FSLOTS-1:0] slot_rfw;


// Instruction to micro-op translation table.
// Each instruction may translate into 1 to 4 micro-ops.
// There is additional meta-data associated with the instruction.

reg [71:0] uopl [0:255];
initial begin
	// Initialize everything to NOPs
	for (n = 0; n < 256; n = n + 1)
		uopl[n] = {2'd0,70'h0};
uopl[`BRK] 			= {2'd3,`UOF_NONE,2'd3,`UO_ADDB,`UO_M3,`UO_SP,2'd0,`UO_STB,`UO_M1,`UO_SR,2'd0,`UO_STW,`UO_M2,`UO_PC,2'd0,`UO_LDW,`UO_M2,`UO_PC,2'd0};
uopl[`LDA_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_LDIB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`LDA_ZP]		= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`LDA_ZPX]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R8,`UO_ACC,`UO_XR,48'h0};
uopl[`LDA_IX]		= {2'd1,`UOF_NZ,2'd1,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0000};
uopl[`LDA_IY]		= {2'd2,`UOF_NZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`LDA_ABS]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R16,`UO_ACC,`UO_ZR,48'h0};
uopl[`LDA_ABSX]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R16,`UO_ACC,`UO_XR,48'h0};
uopl[`LDA_ABSY]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R16,`UO_ACC,`UO_YR,48'h0};
uopl[`STA_ZP]	  = {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`STA_ZPX]  = {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R8,`UO_ACC,`UO_XR,48'h0};
uopl[`STA_IX]		= {2'd1,`UOF_NONE,2'd0,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_STB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0000};
uopl[`STA_IY]		= {2'd2,`UOF_NONE,2'd0,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_STB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`STA_ABS]	= {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R16,`UO_ACC,`UO_ZR,48'h0};
uopl[`STA_ABSX]	= {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R16,`UO_ACC,`UO_XR,48'h0};
uopl[`STA_ABSY]	= {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R16,`UO_ACC,`UO_YR,48'h0};
uopl[`ADC_IMM]	= {2'd0,`UOF_CVNZ,2'd0,`UO_ADCB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`ADC_ZP]		= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ADC_ZPX]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ADC_IX]		= {2'd2,`UOF_CVNZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`ADC_IY]		= {2'd3,`UOF_CVNZ,2'd3,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP};
uopl[`ADC_ABS]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ADC_ABSX]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ADC_ABSY]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_YR,`UO_ADCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`SBC_IMM]	= {2'd0,`UOF_CVNZ,2'd0,`UO_SBCB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`SBC_ZP]		= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`SBC_ZPX]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`SBC_IX]		= {2'd2,`UOF_CVNZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`SBC_IY]		= {2'd3,`UOF_CVNZ,2'd3,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP};
uopl[`SBC_ABS]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`SBC_ABSX]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`SBC_ABSY]	= {2'd1,`UOF_CVNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_YR,`UO_SBCB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`CMP_IMM]	= {2'd0,`UOF_CNZ,2'd0,`UO_CMPB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`CMP_ZP]		= {2'd1,`UOF_CNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_CMPB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`CMP_ZPX]	= {2'd1,`UOF_CNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_CMPB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`CMP_IX]		= {2'd2,`UOF_CNZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_CMPB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`CMP_IY]		= {2'd3,`UOF_CNZ,2'd3,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_CMPB,`UO_ZERO,`UO_ACC,`UO_TMP};
uopl[`CMP_ABS]	= {2'd1,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_CMP,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`CMP_ABSX]	= {2'd1,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_CMP,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`CMP_ABSY]	= {2'd1,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_YR,`UO_CMP,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`AND_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_ANDB,`UO_R8,`UO_ACC,`UO_M1R,48'h0};
uopl[`AND_ZP]		= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_ANDB,`UO_M1,`UO_ACC,`UO_TMP,32'h0};
uopl[`AND_ZPX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_ANDB,`UO_M1,`UO_ACC,`UO_TMP,32'h0};
uopl[`AND_IX]		= {2'd2,`UOF_NZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_ANDB,`UO_M1,`UO_ACC,`UO_TMP,16'h0000};
uopl[`AND_IY]		= {2'd3,`UOF_NZ,2'd3,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_ANDB,`UO_M1,`UO_ACC,`UO_TMP};
uopl[`AND_ABS]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_AND,`UO_M1,`UO_ACC,`UO_TMP,32'h0};
uopl[`AND_ABSX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_AND,`UO_M1,`UO_ACC,`UO_TMP,32'h0};
uopl[`AND_ABSY]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_YR,`UO_AND,`UO_M1,`UO_ACC,`UO_TMP,32'h0};
uopl[`ORA_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_ORB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`ORA_ZP]		= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ORA_ZPX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ORA_IX]		= {2'd2,`UOF_NZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`ORA_IY]		= {2'd3,`UOF_NZ,2'd3,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP};
uopl[`ORA_ABS]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ORA_ABSX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ORA_ABSY]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_YR,`UO_ORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`EOR_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_EORB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`EOR_ZP]		= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`EOR_ZPX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`EOR_IX]		= {2'd2,`UOF_NZ,2'd2,`UO_LDW,`UO_R8,`UO_TMP,`UO_XR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP,16'h0000};
uopl[`EOR_IY]		= {2'd3,`UOF_NZ,2'd3,`UO_LDW,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDW,`UO_ZERO,`UO_TMP,`UO_YR,`UO_LDB,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP};
uopl[`EOR_ABS]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`EOR_ABSX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`EOR_ABSY]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_YR,`UO_EORB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`ASL_ACC]  = {2'd0,`UOF_CNZ,2'd0,`UO_ASL,`UO_ZERO,`UO_ACC,`UO_ZR,48'h0};
uopl[`ASL_ZP]		= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_ASL,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R8,`UO_TMP,`UO_ZR,16'h0};
uopl[`ASL_ZPX]	= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_ASL,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R8,`UO_TMP,`UO_XR,16'h0};
uopl[`ASL_ABS]	= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_ASL,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R16,`UO_TMP,`UO_ZR,16'h0};
uopl[`ASL_ABSX]	= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_ASL,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R16,`UO_TMP,`UO_XR,16'h0};
uopl[`ROL_ACC]  = {2'd0,`UOF_CNZ,2'd0,`UO_ROL,`UO_ZERO,`UO_ACC,`UO_ZR,48'h0};
uopl[`ROL_ZP]		= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_ROL,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R8,`UO_TMP,`UO_ZR,16'h0};
uopl[`ROL_ZPX]	= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_ROL,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R8,`UO_TMP,`UO_XR,16'h0};
uopl[`ROL_ABS]	= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_ROL,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R16,`UO_TMP,`UO_ZR,16'h0};
uopl[`ROL_ABSX]	= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_ROL,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R16,`UO_TMP,`UO_XR,16'h0};
uopl[`LSR_ACC]  = {2'd0,`UOF_CNZ,2'd0,`UO_LSR,`UO_ZERO,`UO_ACC,`UO_ZR,48'h0};
uopl[`LSR_ZP]		= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_LSR,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R8,`UO_TMP,`UO_ZR,16'h0};
uopl[`LSR_ZPX]	= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_LSR,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R8,`UO_TMP,`UO_XR,16'h0};
uopl[`LSR_ABS]	= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_LSR,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R16,`UO_TMP,`UO_ZR,16'h0};
uopl[`LSR_ABSX]	= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_LSR,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R16,`UO_TMP,`UO_XR,16'h0};
uopl[`ROR_ACC]  = {2'd0,`UOF_CNZ,2'd0,`UO_ROR,`UO_ZERO,`UO_ACC,`UO_ZR,48'h0};
uopl[`ROR_ZP]		= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_ROR,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R8,`UO_TMP,`UO_ZR,16'h0};
uopl[`ROR_ZPX]	= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_ROR,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R8,`UO_TMP,`UO_XR,16'h0};
uopl[`ROR_ABS]	= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_ROR,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R16,`UO_TMP,`UO_ZR,16'h0};
uopl[`ROR_ABSX]	= {2'd2,`UOF_CNZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_ROR,`UO_ZERO,`UO_TMP,`UO_TMP,`UO_STB,`UO_R16,`UO_TMP,`UO_XR,16'h0};
uopl[`INC_ZP]		= {2'd2,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDIB,`UO_P1,`UO_TMP,`UO_TMP,`UO_STB,`UO_R8,`UO_TMP,`UO_ZR,16'h0};
uopl[`INC_ZPX]	= {2'd2,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_ADDIB,`UO_P1,`UO_TMP,`UO_TMP,`UO_STB,`UO_R8,`UO_TMP,`UO_XR,16'h0};
uopl[`INC_ABS]	= {2'd2,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_ADDIB,`UO_P1,`UO_TMP,`UO_TMP,`UO_STB,`UO_R16,`UO_TMP,`UO_ZR,16'h0};
uopl[`INC_ABSX]	= {2'd2,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_ADDIB,`UO_P1,`UO_TMP,`UO_TMP,`UO_STB,`UO_R16,`UO_TMP,`UO_XR,16'h0};
uopl[`DEC_ZP]		= {2'd2,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_ADDIB,`UO_M1,`UO_TMP,`UO_TMP,`UO_STB,`UO_R8,`UO_TMP,`UO_ZR,16'h0};
uopl[`DEC_ZPX]	= {2'd2,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_ADDIB,`UO_M1,`UO_TMP,`UO_TMP,`UO_STB,`UO_R8,`UO_TMP,`UO_XR,16'h0};
uopl[`DEC_ABS]	= {2'd2,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_ADDIB,`UO_M1,`UO_TMP,`UO_TMP,`UO_STB,`UO_R16,`UO_TMP,`UO_ZR,16'h0};
uopl[`DEC_ABSX]	= {2'd2,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_ADDIB,`UO_M1,`UO_TMP,`UO_TMP,`UO_STB,`UO_R16,`UO_TMP,`UO_XR,16'h0};
uopl[`BIT_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_BITIB,`UO_R8,`UO_ACC,`UO_ZR,48'h0};
uopl[`BIT_ZP]		= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_BITB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`BIT_ZPX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_BITB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`BIT_ABS]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_BITB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`BIT_ABSX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_XR,`UO_BITB,`UO_ZERO,`UO_ACC,`UO_TMP,32'h0};
uopl[`LDX_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_LDIB,`UO_R8,`UO_XR,`UO_ZR,48'h0};
uopl[`LDX_ZP]		= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R8,`UO_XR,`UO_ZR,48'h0};
uopl[`LDX_ZPY]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R8,`UO_XR,`UO_YR,48'h0};
uopl[`LDX_ABS]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R16,`UO_XR,`UO_ZR,48'h0};
uopl[`LDX_ABSY]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R16,`UO_XR,`UO_YR,48'h0};
uopl[`STX_ZP]	  = {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R8,`UO_XR,`UO_ZR,48'h0};
uopl[`STX_ZPY]  = {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R8,`UO_XR,`UO_YR,48'h0};
uopl[`STX_ABS]	= {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R16,`UO_XR,`UO_ZR,48'h0};
uopl[`CPX_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_CMPB,`UO_R8,`UO_XR,`UO_ZR,48'h0};
uopl[`CPX_ZP]		= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_CMPB,`UO_ZERO,`UO_XR,`UO_TMP,32'h0};
uopl[`CPX_ZPY]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_YR,`UO_CMPB,`UO_ZERO,`UO_XR,`UO_TMP,32'h0};
uopl[`CPX_ABS]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_CMP,`UO_ZERO,`UO_XR,`UO_TMP,32'h0};
uopl[`LDY_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_LDIB,`UO_R8,`UO_YR,`UO_ZR,48'h0};
uopl[`LDY_ZP]		= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R8,`UO_YR,`UO_ZR,48'h0};
uopl[`LDY_ZPX]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R8,`UO_YR,`UO_XR,48'h0};
uopl[`LDY_ABS]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R16,`UO_YR,`UO_ZR,48'h0};
uopl[`LDY_ABSX]	= {2'd0,`UOF_NZ,2'd0,`UO_LDB,`UO_R16,`UO_YR,`UO_XR,48'h0};
uopl[`STY_ZP]	  = {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R8,`UO_YR,`UO_ZR,48'h0};
uopl[`STY_ZPX]  = {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R8,`UO_YR,`UO_XR,48'h0};
uopl[`STY_ABS]	= {2'd0,`UOF_NONE,2'd0,`UO_STB,`UO_R16,`UO_YR,`UO_ZR,48'h0};
uopl[`CPY_IMM]	= {2'd0,`UOF_NZ,2'd0,`UO_CMPB,`UO_R8,`UO_YR,`UO_ZR,48'h0};
uopl[`CPY_ZP]		= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_ZR,`UO_CMPB,`UO_ZERO,`UO_YR,`UO_TMP,32'h0};
uopl[`CPY_ZPX]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R8,`UO_TMP,`UO_XR,`UO_CMPB,`UO_ZERO,`UO_YR,`UO_TMP,32'h0};
uopl[`CPY_ABS]	= {2'd1,`UOF_NZ,2'd1,`UO_LDB,`UO_R16,`UO_TMP,`UO_ZR,`UO_CMP,`UO_ZERO,`UO_YR,`UO_TMP,32'h0};
uopl[`INX]			= {2'd0,`UOF_NZ,2'd1,`UO_ADDB,`UO_P1,`UO_XR,`UO_ZR,48'h0};
uopl[`DEX]			= {2'd0,`UOF_NZ,2'd1,`UO_ADDB,`UO_M1,`UO_XR,`UO_ZR,48'h0};
uopl[`INY]			= {2'd0,`UOF_NZ,2'd1,`UO_ADDB,`UO_P1,`UO_YR,`UO_ZR,48'h0};
uopl[`DEY]			= {2'd0,`UOF_NZ,2'd1,`UO_ADDB,`UO_M1,`UO_YR,`UO_ZR,48'h0};
uopl[`PHA]			= {2'd1,`UOF_NONE,2'd0,`UO_SB,`UO_100H,`UO_ACC,`UO_SP,`UO_ADDB,`UO_M1,`UO_SP,`UO_ZR,32'h0};
uopl[`PLA]			= {2'd1,`UOF_NZ,2'd1,`UO_ADDB,`UO_P1,`UO_SP,`UO_ZR,`UO_LDB,`UO_100H,`UO_ACC,`UO_SP,32'h0};
uopl[`PHP]			= {2'd1,`UOF_NONE,2'd0,`UO_SB,`UO_100H,`UO_SR,`UO_SP,`UO_ADDB,`UO_M1,`UO_SP,`UO_ZR,32'h0};
uopl[`PLP]			= {2'd1,`UOF_NZ,2'd1,`UO_ADDB,`UO_P1,`UO_SP,`UO_ZR,`UO_LDB,`UO_100H,`UO_SR,`UO_SP,32'h0};
uopl[`TAX]			= {2'd0,`UOF_NZ,2'd0,`UO_MOV,`UO_ZERO,`UO_XR,`UO_ACC};
uopl[`TXA]			= {2'd0,`UOF_NZ,2'd0,`UO_MOV,`UO_ZERO,`UO_ACC,`UO_XR};
uopl[`TAY]			= {2'd0,`UOF_NZ,2'd0,`UO_MOV,`UO_ZERO,`UO_YR,`UO_ACC};
uopl[`TYA]			= {2'd0,`UOF_NZ,2'd0,`UO_MOV,`UO_ZERO,`UO_ACC,`UO_YR};
uopl[`TSX]			= {2'd0,`UOF_NZ,2'd0,`UO_MOV,`UO_ZERO,`UO_XR,`UO_SP};
uopl[`TXS]			= {2'd0,`UOF_NONE,2'd0,`UO_MOV,`UO_ZERO,`UO_SP,`UO_XR};
uopl[`BEQ]			= {2'd0,`UOF_NONE,2'd0,`UO_BEQ,`UO_R8,`UO_ZERO,`UO_ZR};
uopl[`BNE]			= {2'd0,`UOF_NONE,2'd0,`UO_BNE,`UO_R8,`UO_ZERO,`UO_ZR};
uopl[`BCS]			= {2'd0,`UOF_NONE,2'd0,`UO_BCS,`UO_R8,`UO_ZERO,`UO_ZR};
uopl[`BCC]			= {2'd0,`UOF_NONE,2'd0,`UO_BCC,`UO_R8,`UO_ZERO,`UO_ZR};
uopl[`BVS]			= {2'd0,`UOF_NONE,2'd0,`UO_BVS,`UO_R8,`UO_ZERO,`UO_ZR};
uopl[`BVC]			= {2'd0,`UOF_NONE,2'd0,`UO_BVC,`UO_R8,`UO_ZERO,`UO_ZR};
uopl[`BMI]			= {2'd0,`UOF_NONE,2'd0,`UO_BMI,`UO_R8,`UO_ZERO,`UO_ZR};
uopl[`BPL]			= {2'd0,`UOF_NONE,2'd0,`UO_BPL,`UO_R8,`UO_ZERO,`UO_ZR};
uopl[`CLC]			= {2'd0,`UOF_C,2'd0,`UO_CLC,`UO_ZERO,`UO_ZR,`UO_ZR};
uopl[`SEC]			= {2'd0,`UOF_C,2'd0,`UO_SEC,`UO_ZERO,`UO_ZR,`UO_ZR};
uopl[`CLV]			= {2'd0,`UOF_V,2'd0,`UO_CLV,`UO_ZERO,`UO_ZR,`UO_ZR};
uopl[`JMP]			= {2'd0,`UOF_NONE,2'd0,`UO_JMP,`UO_R16,`UO_ZERO,`UO_ZR,48'h0};
uopl[`JMP_IND]	= {2'd1,`UOF_NONE,2'd0,`UO_LDW,`UO_R16,`UO_TMP,`UO_ZR,`UO_JMP,`UO_ZERO,`UO_ZR,`UO_TMP,32'h0};
uopl[`JSR]			= {2'd2,`UOF_NONE,2'd0,`UO_STW,`UO_FFH,`UO_PC2,`UO_SP,`UO_ADDIB,`UO_M2,`UO_SP,`UO_ZR,`UO_JMP,`UO_R16,`UO_ZERO,`UO_ZR,16'h0};
uopl[`RTS]		  = {2'd2,`UOF_NONE,2'd0,`UO_ADDB,`UO_P2,`UO_SP,`UO_ZR,`UO_LDW,`UO_FFFFH,`UO_TMP,`UO_SP,`UO_JMP,`UO_P1,`UO_TMP,`UO_ZR,16'h0};
uopl[`RTI]		  = {2'd3,`UOF_NONE,2'd0,`UO_ADDB,`UO_P3,`UO_SP,`UO_ZR,`UO_LDW,`UO_FFFFH,`UO_TMP,`UO_SP,`UO_LDB,`UO_FFFEH,`UO_SR,`UO_SP,`UO_JMP,`UO_ZERO,`UO_TMP,`UO_ZR};
end

task tskLd4;
input [3:0] ld4;
input [23:0] insn;
output [15:0] const;
begin
	case(ld4)
	`UO_M3:	const <= 16'hFFFD;
	`UO_M2:	const <= 16'hFFFE;
	`UO_M1:	const <= 16'hFFFF;
	`UO_P3:	const <= 16'h0003;
	`UO_P2:	const <= 16'h0002;
	`UO_P1:	const <= 16'h0001;
	`UO_R8:	const <= insn[15:8];
	`UO_R16:	const <= insn[23:8];
	default:	const <= 16'h0000;
	endcase
end
endtask

wire [2:0] uo_len1 = uopl[opcode1][69:68] + 2'd1;
wire [2:0] uo_len2 = uopl[opcode2][69:68] + 2'd1;
wire [1:0] uo_flags1 = uopl[opcode1][67:66];
wire [1:0] uo_flags2 = uopl[opcode2][67:66];
wire [1:0] uo_whflg1 = uopl[opcode1][65:64];
wire [1:0] uo_whflg2 = uopl[opcode2][65:64];
wire [15:0] uo_insn1 [0:3];
wire [15:0] uo_insn2 [0:3];
assign uo_insn1[0] = uopl[opcode1][63:48];
assign uo_insn1[1] = uopl[opcode1][47:32];
assign uo_insn1[2] = uopl[opcode1][31:16];
assign uo_insn1[3] = uopl[opcode1][15: 0];
assign uo_insn2[1] = uopl[opcode2][63:48];
assign uo_insn2[2] = uopl[opcode2][47:32];
assign uo_insn2[3] = uopl[opcode2][31:16];
assign uo_insn2[4] = uopl[opcode2][15: 0];

wire [QSLOTS-1:0] slotv;
wire [4:0] uoq_size = 5'd16;
reg [7:0] uoq_tail, uoq_head;

// Only scans up to eight ahead because that's all the room that might be
// needed (there could be more than eight available).
reg [4:0] uoq_room;
reg uoq_hitv; 
always @*
begin
uoq_hitv = FALSE;
uoq_room = 5'd0;
for (n = 0; n < 8; n = n + 1)
	if (uoq_v[(uoq_tail + n) % UOQ_ENTRIES] == `INV && !uoq_hitv) begin
		uoq_room = uoq_room + 5'd1;
		uoq_hitv = TRUE;
	end
end

always @*
begin
	q1 <= FALSE;
	q2 <= FALSE;
	if (uoq_room >= uo_len1 + uo_len2) begin
		q2 <= TRUE;
	else if (uoq_room >= uo_len1) begin
		q1 <= TRUE;
end

reg [3:0] queuedCnt;
always @(posedge clk_i)
if (rst_i) begin
	queuedCnt <= 4'd0;
end
begin
	queuedCnt <= 4'd0;
	if (q2)
		queuedCnt <= 4'd2 + uo_len1 + uo_len2;
	else if (q1)
		queuedCnt <= 4'd1 + uo_len1;
end

always @(posedge clk_i)
if (rst_i)
	uoq_head <= 4'd0;
else
	uoq_head <= (uoq_head + queuedCnt) % UOQ_ENTRIES;

assign slotv[0] = uoq_head != uoq_tail;
assign slotv[1] = uoq_head != uoq_tail && uoq_head + 4'd1 != uoq_tail;
assign slotv[2] = uoq_head != uoq_tail && uoq_head + 4'd1 != uoq_tail && uoq_head + 4'd2 != uoq_tail;

assign ic2_out = ic1_out >> {len1,3'b0};
wire [7:0] opcode1 = ic_out[7:0];
wire [7:0] opcode2 = ic2_out[7:0];
instLength il1 (opcode1, len1);
instLength il2 (opcode2, len2);

wire [`ABITS] btgt [0:QSLOTS-1];
wire [23:0] insnxp [0:QSLOTS-1];
reg invdcl;
reg [AMSB:0] invlineAddr;
wire L1_invline;
wire [15:0] L1_adr, L2_adr;
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
wire [15:0] d0L1_adr, d0L2_adr;
wire [15:0] d1L1_adr, d1L2_adr;
wire d0L1_rhit, d0L2_rhit, d0L2_whit;
wire d0L2_rhita, d1L2_rhita;
wire d0L1_nxt, d0L2_nxt;					// advances cache way lfsr
wire d1L1_dhit, d1L2_rhit, d1L2_whit;
wire d1L1_nxt, d1L2_nxt;					// advances cache way lfsr
wire [32:0] d0L1_sel, d0L2_sel;
wire [32:0] d1L1_sel, d1L2_sel;
wire [263:0] d0L1_dat, d0L2_rdat, d0L2_wdat;
wire [263:0] d1L1_dat, d1L2_rdat, d1L2_wdat;
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
reg [1:0] dcsel;
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

function IsBranch;
input [7:0] opcode;
IsBranch = opcode==`BEQ || opcode==`BNE || opcode==`BCS || opcode==`BCC ||
						opcode==`BVS || opcode==`BVC || opcode==`BMI || opcode==`BPL;
endfunction
function IsBrk;
input [7:0] opcode;
IsBrk = opcode==`BRK;
endfunction
function IsRti;
input [7:0] opcode;
IsRti = opcode==`RTI;
endfunction

// Branch decodes, needed to guide the program counter logic.
wire [1:0] slot_rts;
wire [1:0] slot_br;
wire [1:0] slot_jc;
wire [1:0] take_branch;
assign slot_rts[0] = opcode1==`RTS;
assign slot_rts[1] = opcode2==`RTS;
assign slot_br[0] = opcode1==`BEQ || opcode1==`BNE || opcode1==`BCS || opcode1==`BCC ||
										 opcode1==`BVS || opcode1==`BVC || opcode1==`BMI || opcode1==`BPL;
assign slot_br[1] = opcode2==`BEQ || opcode2==`BNE || opcode2==`BCS || opcode2==`BCC ||
										 opcode2==`BVS || opcode2==`BVC || opcode2==`BMI || opcode2==`BPL;
assign slot_jc[0] = opcode1==`JMP || opcode1==`JSR;
assign slot_jc[1] = opcode2==`JMP || opcode2==`JSR;
assign slot_br[0] = opcode1==`BRK || opcode1==`RTI;
assign slot_br[1] = opcode2==`BRK || opcode2==`RTI;
assign take_branch[0] = (IsBranch(opcode1) && predict_taken[0]) || IsBrk(opcode1) || IsRti(opcode1);
assign take_branch[1] = (IsBranch(opcode2) && predict_taken[1]) || IsBrk(opcode2) || IsRti(opcode2);
// Branching for purposes of the branch shadow.
wire [FSLOTS-1:0] is_branch;
reg [IQ_ENTRIES-1:0] is_qbranch;
assign is_branch[0] = IsBranch(opcode1) || id_bus[0][`IB_BRK] || id_bus[0][`IB_RTI] || id_bus[0][`IB_RTS] || id_bus[0][`IB_JRL];
assign is_branch[1] = IsBranch(opcode2) || id_bus[1][`IB_BRK] || id_bus[1][`IB_RTI] || id_bus[1][`IB_RTS] || id_bus[1][`IB_JRL];
always @*
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	is_qbranch[n] = iq_br[n] | iq_brk[n] | iq_rti[n] | iq_rts[n];

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

function IsNop;
input [23:0] ins;
IsNop = ins[`OPCODE]==`NOP;
endfunction

wire [`RBITS] next_iq_rid [0:IQ_ENTRIES-1];
wire [`RENTRIES-1:0] next_rob_v;



wire [AREGS-1:0] rf_v;								// register is valid
wire [AREGS-1:0] regIsValid;					// register is valid (in this cycle)
reg  [`QBITSP1] rf_source[0:AREGS-1];

regfileValid urfv1
(
	.rst(rst_i),
	.clk(clk),
	.slotvd(slotvd),
	.slot_rfw(slot_rfw),
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
	.rf_source(rf_source),
	.iq_source(iq_source),
	.take_branch(take_branch),
	.Rd(Rd),
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
	.rob_tails(rob_tails),
	.iq_latestID(iq_latestID),
	.iq_tgt(iq_tgt),
	.iq_rid(iq_rid),
	.rf_source(rf_source)
);

reg [3:0] nxtrb;
always @*
begin
	if (commit0_v & commit1_v & commit2_v)
		max_cs = 2'd2;
	else if (commit0_v & commimt1_v)
		max_cs = 2'd1;
	else if (commit0_v)
		max_cs = 2'd0;

	// Amount to increment reorder buffer pointer by
	case(max_cs)
	2'd0:	r_amt = commit0_rid - rob_heads[0] + 4'd1;
	2'd1:	r_amt = commit1_rid - rob_heads[0] + 4'd1;
	2'd2:	r_amt = commit2_rid - rob_heads[0] + 4'd1;
	default:	r_amt = 1'd0;
	endcase
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

programCounter upc1
(
	.rst(rst_i),
	.clk(clk),
	// This should be handled by branch miss logic
/*
	.commit0_v(commit0_v),
	.commit1_v(commit1_v),
	.commit2_v(commit2_v),
	.commit0_bus(commit0_bus),
	.commit1_bus(commit1_bus),
	.commit2_bus(commit2_bus),
	.commit0_tgt(commit0_tgt),
	.commit1_tgt(commit1_tgt),
	.commit2_tgt(commit2_tgt),
*/
	.q1(q1),
	.q2(q2),
	.insnx(insnx),
	.phit(phit),
	.freezepc(freezepc),
	.branchmiss(branchmiss),
	.misspc(misspc),
	.len1(len1),
	.len2(len2),
	.jc(slot_jc),
	.rts(slot_rts),
	.br(slot_br),
	.take_branch(take_branch),
	.btgt(btgt),
	.pc(pc),
	.branch_pc(next_pc),
	.ra(ra),
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
	.Ra(Rn),
	.Rd(Rd),
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
  .npcC())
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

assign xisBr[0] = iq_br[heads[0]] & commit0_v & ~iq_instr[heads[0]][5];
assign xisBr[1] = iq_br[heads[1]] & commit1_v & ~iq_instr[heads[1]][5];
assign xisBr[2] = iq_br[heads[2]] & commit1_v & ~iq_instr[heads[2]][5];
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
BranchPredictor ubp1
(
  .rst(rst_i),
  .clk(clk_i),
  .clk2x(clk2x_i),
  .clk4x(clk4x_i),
  .en(bpe),
  .xisBranch(xisBr),
  .xip(xpc),
  .takb(xtkb),
  .pc(pcs),
  .predict_taken(predict_takenx)
);
`else
assign predict_takenx[0] = insnx[0][15];
assign predict_takenx[1] = insnx[1][15];
`endif

assign predict_taken[0] = predict_takenx[0];
assign predict_taken[1] = predict_takenx[1];


reg StoreAck1, isStore;
wire [15:0] dc0_out, dc1_out;
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

wire [127:0] aligned_data = fnDatiAlign(dram0_addr,xdati);
wire [127:0] rdat0, rdat1;
assign rdat0 = fnDataExtend(dram0_instr,dram0_unc ? aligned_data : dc0_out);
assign rdat1 = fnDataExtend(dram1_instr,dram1_unc ? aligned_data : dc1_out);
reg [15:0] rmw_ad0, rmw_ad1;
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


// Register read ports
reg [2:0] Rd [QSLOTS-1:0];
reg [2:0] Rn [QSLOTS-1:0];

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	Rd[n] = uoq_uop[(uoq_head+n)%UOQ_ENTRIES][5:3];
always @*
for (n = 0; n < QSLOTS; n = n + 1)
	Rn[n] = uoq_uop[(uoq_head+n)%UOQ_ENTRIES][2:0];

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	case(Rd[n])
	3'd0:	rfoa[n] <= {8'h00,ac};
	3'd1:	rfoa[n] <= {8'h00,xr};
	3'd2:	rfoa[n] <= {8'h00,yr};
	3'd3:	rfoa[n] <= {8'h01,sp};
	3'd4:	rfoa[n] <= uoq_pc[(uoq_head+n) % UOQ_ENTRIES];
	3'd5: rfoa[n] <= tmp;
	3'd7:	rfoa[n] <= {8'h00,sr};
	default:	rfoa[n] <= 16'h0;
	endcase

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	case(Rn[n])
	2'd0:	rfob[n] <= 16'h0000;
	2'd1:	rfob[n] <= {8'h0,xr};
	2'd2:	rfob[n] <= {8'h0,yr};
	2'd3:	rfob[n] <= {8'h1,sp};
	endcase

always @*
for (n = 0; n < QSLOTS; n = n + 1)
	rfos[n] <= sr;

// Writes to the register file. Fortunately the register file is small so
// three update ports are easily supported.
always @(posedge clk)
	if (commit2_v && commit2_tgt==`UO_ACC)
		ac <= commit2_bus;
	else if (commit1_v && commit1_tgt==`UO_ACC)
		ac <= commit1_bus;
	else if (commit0_v && commit0_tgt==`UO_ACC)
		ac <= commit0_bus;

always @(posedge clk)
	if (commit2_v && commit2_tgt==`UO_XR)
		xr <= commit2_bus;
	else if (commit1_v && commit1_tgt==`UO_XR)
		xr <= commit1_bus;
	else if (commit0_v && commit0_tgt==`UO_XR)
		xr <= commit0_bus;

always @(posedge clk)
	if (commit2_v && commit2_tgt==`UO_YR)
		yr <= commit2_bus;
	else if (commit1_v && commit1_tgt==`UO_YR)
		yr <= commit1_bus;
	else if (commit0_v && commit0_tgt==`UO_YR)
		yr <= commit0_bus;

always @(posedge clk)
	if (commit2_v && commit2_tgt==`UO_SP)
		sp <= commit2_bus;
	else if (commit1_v && commit1_tgt==`UO_SP)
		sp <= commit1_bus;
	else if (commit0_v && commit0_tgt==`UO_SP)
		sp <= commit0_bus;

always @(posedge clk)
	if (commit2_v && commit2_tgt==`UO_TMP)
		tmp <= commit2_bus;
	else if (commit1_v && commit1_tgt==`UO_TMP)
		tmp <= commit1_bus;
	else if (commit0_v && commit0_tgt==`UO_TMP)
		tmp <= commit0_bus;

wire [15:0] argA [0:QSLOTS-1];
wire [15:0] argB [0:QSLOTS-1];
wire [ 7:0] argS [0:QSLOTS-1];

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
decoder3 iq0 (
	.num(iq_tgt[g][2:0]),
	.out(iq_out2[g])
);
end
end
endgenerate

function Source1Valid;
input [15:0] ins;
Source1Valid = TRUE;
endfunction

function Source2Valid;
input [15:0] ins;
case(ins[2:0])
3'd0,3'd4,3'd6:	Source2Valid = TRUE;
default:	Source2Valid = FALSE;
endcase
endfunction

function SourceTValid;
input [15:0] ins;
case(ins[15:10])
`UO_BEQ,`UO_BNE,`UO_BCC,`UO_BCS,`UO_BVC,`UO_BVS,`UO_BMI,`UO_BPL,
`UO_CLC,`UO_SEC,`UO_CLV,`UO_CLI,`UO_SEI:
	SourceTValid = TRUE;
default:	SourceTValid = FALSE;
endcase
endfunction

function IsMem;
input [15:0] isn;
case(isn[15:10])
`UO_LDB,``UO_LDW,`UO_STB,`UO_STW:	IsMem = TRUE;
default:	IsMem = FALSE;
endcase
endfunction

// Really IsPredictableBranch
function IsBranch;
input [15:0] isn;
case(isn[15:10])
`UO_BEQ,`UO_BNE,`UO_BCS,``UO_BCC,`UO_BVS,`UO_BVC,`UO_BMI,`UO_BPL:	
	IsBranch = TRUE;
default:	IsBranch = FALSE;
endcase
endfunction

function IsFLowCtrl;
input [15:0] isn;
case(isn[15:10])
`UO_BEQ,`UO_BNE,`UO_BCS,``UO_BCC,`UO_BVS,`UO_BVC,`UO_BMI,`UO_BPL:	
	IsFlowCtrl = TRUE;
`UO_JMP:	IsFLowCtrl = TRUE;
`UO_SEI,`UO_CLI:	IsFlowCtrl = TRUE;
default:	IsFlowCtrl = FALSE;
endcase
endfunction

function IsSei;
input [15:0] isn;
case(isn[15:10])
`UO_SEI:	IsSei = TRUE;
default:	IsSei = FALSE;
endcase

function IsRFW;
input [15:0] isn;
case(isn[15:10])
`UO_NOP:	IsRFW = FALSE;
`UO_CMPB,`UO_BITB,`UO_STB,`UO_STW:	IsRFW = FALSE;
`UO_BEQ,`UO_BNE,`UO_BCS,``UO_BCC,`UO_BVS,`UO_BVC,`UO_BMI,`UO_BPL:	
	IsRFW = FALSE;
`UO_JMP:	IsRFW = FALSE;
`UO_CLC,`UO_SEC,`UO_CLV,`UO_SEI,`UO_CLI:
	IsRFW = FALSE;
default:	IsRFW = TRUE;
endcase

function [1:0] fnSelect;
input [15:0] isn;
case(isn[15:10])
`UO_LDB,`UO_STB:	fnSelect = 2'b01;
`UO_LDW,`UO_STW:	fnSelect = 2'b11;
default:	fnSelect = 2'b00;
endcase
endfunction

function [15:0] fnDataExtend;
input [15:0] isn;
input [15:0] dat;
case(isn[15:10])
`UO_LDB:	fnDataExtend = {{8{dat[7]}},dat[7:0]};
default:	fnDataExtend = dat;
endcase
endfunction

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
for (j = 1; j < AREGS; j = j + 1) begin
	livetarget[j] = 1'b0;
	for (n = 0; n < QENTRIES; n = n + 1)
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
		  (iq_argA_v[g] 
`ifdef FU_BYPASS
        || (iq_argA_s[g][`RBITS] == alu0_rid && alu0_vsn)
        || ((iq_argA_s[g][`RBITS] == alu1_rid && alu1_vsn) && (`NUM_ALU > 1))
`endif
        )
    && (iq_argB_v[g] || iq_mem[g]	// a2 does not need to be valid immediately for a mem op (agen), it is checked by iq_memready logic
`ifdef FU_BYPASS
        || (iq_argB_s[g][`RBITS] == alu0_rid && alu0_vsn)
        || ((iq_argB_s[g][`RBITS] == alu1_rid && alu1_vsn) && (`NUM_ALU > 1))
`endif
        )
    && (iq_argS_v[g] 
        || (iq_mem[g] & ~iq_agen[g] & ~iq_memndx[g])    // a3 needs to be valid for indexed instruction
//        || (iq_mem[g] & ~iq_agen[g])
`ifdef FU_BYPASS
        || (iq_argS_s[g][`RBITS] == alu0_rid && alu0_vsn)
        || ((iq_argS_s[g][`RBITS] == alu1_rid && alu1_vsn) && (`NUM_ALU > 1))
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
	if (j > 0)
		for (n = j-1; n >= 0; n = n - 1)
			prior_sync[heads[j]] = prior_sync[heads[j]]|(iq_v[heads[n]] & iq_sync[heads[n]]);
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
	
	if (alu0_available & alu0_idle) begin
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

	if (alu1_available && alu1_idle && `NUM_ALU > 1) begin
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
												&& (alu0_available & alu0_done))
		issuing_on_alu0 = TRUE;
end

always @*
begin
issuing_on_alu1 = FALSE;
for (n = 0; n < IQ_ENTRIES; n = n + 1)
	if (iq_alu1_issue[n] && !(iq_v[n] && iq_stomp[n])
												&& (alu1_available & alu1_done))
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
	.iq_fc(iq_fc),
	.iq_aq(1'b0),
	.iq_rl(1'b0),
	.iq_ma(iq_ma),
	.iq_memsb(1'b0),
	.iq_memdb(1'b0),
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
	last_issue0 = IQ_ENTRIES;
	last_issue1 = IQ_ENTRIES;
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
    if (~iq_stomp[heads[n]] && iq_memissue[heads[n]] && !iq_done[heads[n]] && iq_v[heads[n]]) begin
      if (mem1_available && dram0 == `DRAMSLOT_AVAIL) begin
       last_issue0 = heads[n];
      end
    end
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
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
	iq_stomp = 1'b0;
	if (branchmiss) begin
		for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
			if (iq_sn[n] > iq_sn[missid])
				iq_stomp[n] = TRUE;
		end
	end
end

always @*
begin
	stompedOnRets = 1'b0;
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
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
	.Rt(Rd[g][2:0]),
	.predict_taken(predict_taken[g]),
	.bus(id_bus[g]),
	.debug_on(debug_on)
);
end
end
endgenerate

rtf65004_alu ualu1
(
	.op(alu0_inst),
	.dst(alu0_argT),
	.src1(alu0_argA),
	.src2(alu0_argB),
	.o(alu0_out),
	.s_i(alu0_argS),
	.s_o(alu0_sout)
	.idle(alu0_idle)
);

rtf65004_alu ualu2
(
	.op(alu1_inst),
	.dst(alu1_argT),
	.src1(alu1_argA),
	.src2(alu1_argB),
	.o(alu1_out),
	.s_i(alu1_argS),
	.s_o(alu1_sout),
	.idle(alu1_idle)
);

agen uagn1
(
	.src1(agen0_argA),
	.src2(agen0_argB),
	.ma(agen0_ma),
	.idle(agen0_idle)
);

agen uagn2
(
	.src1(agen1_argA),
	.src2(agen1_argB),
	.ma(agen1_ma),
	.idle(agen1_idle)
);


always @(posedge clk_i)
if (rst_i) begin
	uoq_tail <= 4'd0;
	for (n = 0; n < UOQ_ENTRIES; n = n + 1) begin
		uoq_v[n] <= `INV;
		uoq_uop[n] <= 14'd0;
		uoq_const[n] <= 16'h0000;
	end
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

	if (q2) begin
		uoq_v[uop_tail] <= `VAL;
		uoq_pc[uoq_tail] <= pc;
		uoq_uop[uoq_tail] <= uo_insn1[0];
		uoq_fl[uoq_tail] <= uo_len1==2'b00 ? 2'b11: 2'b01;
		uoq_flagsupd[uoq_tail + uo_whflg1] = uo_flags1;
		tskLd4(uo_insn1[0][`UO_LD4],insnx[0],uoq_const[uoq_tail]);
		if (uopl[opcode1][65:64]>2'b00) begin
			uoq_v[(uoq_tail+1) % UOQ_ENTRIES] <= `VAL;
			uoq_pc[(uoq_tail+1) % UOQ_ENTRIES] <= pc;
			uoq_uop[(uoq_tail+1) % UOQ_ENTRIES] <= uo_insn1[1];
			uoq_fl[(uoq_tail+1) % UOQ_ENTRIES] <= uopl[opcode1][65:64]==2'b01 ? 2'b10 : 2'b00;
			tskLd4(uo_insn1[1][`UO_LD4],insnx[0],uoq_const[(uoq_tail+1) % UOQ_ENTRIES]);
		end
		if (uopl[opcode1][65:64]>2'b01) begin
			uoq_v[(uoq_tail+2) % UOQ_ENTRIES] <= `VAL;
			uoq_pc[(uoq_tail+2) % UOQ_ENTRIES] <= pc;
			uoq_uop[(uoq_tail+2) % UOQ_ENTRIES] <= uo_insn1[2];
			uoq_fl[(uoq_tail+2) % UOQ_ENTRIES] <= uopl[opcode1][65:64]==2'b10 ? 2'b10 : 2'b00;
			tskLd4(uo_insn1[2][`UO_LD4],insnx[0],uoq_const[(uoq_tail+2) % UOQ_ENTRIES]);
		end
		if (uopl[opcode1][65:64]>2'b10) begin
			uoq_v[(uoq_tail+3) % UOQ_ENTRIES] <= `VAL;
			uoq_pc[(uoq_tail+3) % UOQ_ENTRIES] <= pc;
			uoq_uop[(uoq_tail+3) % UOQ_ENTRIES] <= uo_insn1[3];
			uoq_fl[(uoq_tail+3) % UOQ_ENTRIES] <= 2'b10;
			tskLd4(uo_insn1[3][`UO_LD4],insnx[0],uoq_const[(uoq_tail+3) % UOQ_ENTRIES]);
		end
		for (n = 0; n < 4; n = n + 1)
			if (n < uo_len1)
				uop_flagsupd[(uop_tail+n) % UOQ_ENTRIES] <= `UOF_NONE;
		uop_flagsupd[(uop_tail+uo_whflg1) % UOP_ENTRIES] <= uo_flags1;
		uoq_v[(uoq_tail+uo_len1) % UOQ_ENTRIES] <= `VAL;
		uoq_pc[(uoq_tail+uo_len1) % UOQ_ENTRIES] <= pc + len1;
		uoq_uop[(uoq_tail+uo_len1) % UOQ_ENTRIES] <= uo_insn2[0];
		uoq_fl[(uoq_tail+uo_len1) % UOQ_ENTRIES] <= uo_len2==2'b00 ? 2'b11 : 2'b01;
		uoq_tail <= (uoq_tail + uo_len1 + 8'd1) % UOQ_ENTRIES;
		tskLd4(uo_insn2[0][`UO_LD4],insnx[1],uoq_const[uoq_tail + uo_len1]);
		if (uo_len2 > 2'b00) begin
			uoq_v[(uoq_tail+uo_len1+1) % UOQ_ENTRIES] <= `VAL;
			uoq_pc[(uoq_tail+uo_len1+1) % UOQ_ENTRIES] <= pc + len1;
			uoq_uop[(uoq_tail+uo_len1+1) % UOQ_ENTRIES] <= uo_insn2[1];
			uoq_fl[(uoq_tail+uo_len1+1) % UOQ_ENTRIES] <= uo_len2==2'b01 ? 2'b10 : 2'b00;
			uoq_tail <= (uoq_tail + uo_len1 + 8'd2) % UOQ_ENTRIES;
			tskLd4(uo_insn2[1][`UO_LD4],insnx[1],uoq_const[(uoq_tail+uo_len1+1) % UOQ_ENTRIES]);
		end
		if (uo_len2 > 2'b01) begin
			uoq_v[(uoq_tail+uo_len1+2) % UOQ_ENTRIES] <= `VAL;
			uoq_pc[(uoq_tail+uo_len1+2) % UOQ_ENTRIES] <= pc + len1;
			uoq_uop[(uoq_tail+uo_len1+2) % UOQ_ENTRIES] <= uo_insn2[2];
			uoq_fl[(uoq_tail+uo_len1+2) % UOQ_ENTRIES] <= uo_len2==2'b10 ? 2'b10 : 2'b00;
			uoq_tail <= (uoq_tail + uo_len1 + 8'd3) % UOQ_ENTRIES;
			tskLd4(uo_insn2[2][`UO_LD4],insnx[1],uoq_const[(uoq_tail+uo_len1+2) % UOQ_ENTRIES]);
		end
		if (uo_len2 > 2'b10) begin
			uoq_v[(uoq_tail+uo_len1+3) % UOQ_ENTRIES] <= `VAL;
			uoq_pc[(uoq_tail+uo_len1+3) % UOQ_ENTRIES] <= pc + len1;
			uoq_uop[(uoq_tail+uo_len1+3) % UOQ_ENTRIES] <= uo_insn2[3];
			uoq_fl[(uoq_tail+uo_len1+3) % UOQ_ENTRIES] <= 2'b10;
			uoq_tail <= (uoq_tail + uo_len1 + 8'd4) % UOQ_ENTRIES;
			tskLd4(uo_insn2[3][`UO_LD4],insnx[1],uoq_const[(uoq_tail+uo_len1+3) % UOQ_ENTRIES]);
		end
		for (n = 0; n < 4; n = n + 1)
			if (n < uo_len2)
				uop_flagsupd[(uop_tail+uo_len1+n) % UOQ_ENTRIES] <= `UOF_NONE;
		uop_flagsupd[(uop_tail+uo_len1+uo_whflg1) % UOP_ENTRIES] <= uo_flags1;
	end
	else if (q1) begin
		uoq_v[uoq_tail] <= `VAL;
		uoq_pc[uoq_tail] <= pc;
		uoq_uop[uoq_tail] <= uo_insn1[0];
		uoq_fl[uoq_tail] <= uo_len1==2'b00 ? 2'b11: 2'b01;
		uoq_tail <= (uoq_tail + 8'd1) % UOQ_ENTRIES;
		tskLd4(uo_insn1[0][`UO_LD4],insnx[0],uoq_const[uoq_tail]);
		if (uo_len1 > 2'b00) begin
			uoq_v[(uoq_tail+1) % UOQ_ENTRIES] <= `VAL;
			uoq_pc[(uoq_tail+1) % UOQ_ENTRIES] <= pc;
			uoq_uop[(uoq_tail+1) % UOQ_ENTRIES] <= uo_insn1[1];
			uoq_fl[(uoq_tail+1) % UOQ_ENTRIES] <= uopl[opcode1][65:64]==2'b01 ? 2'b10 : 2'b00;
			uoq_tail <= (uoq_tail + 8'd2) % UOQ_ENTRIES;
			tskLd4(uo_insn1[1][`UO_LD4],insnx[0],uoq_const[(uoq_tail+1) % UOQ_ENTRIES]);
		end
		if (uo_len1 > 2'b01) begin
			uoq_v[(uoq_tail+2) % UOQ_ENTRIES] <= `VAL;
			uoq_pc[(uoq_tail+2) % UOQ_ENTRIES] <= pc;
			uoq_uop[(uoq_tail+2) % UOQ_ENTRIES] <= uo_insn1[2];
			uoq_fl[(uoq_tail+2) % UOQ_ENTRIES] <= uopl[opcode1][65:64]==2'b10 ? 2'b10 : 2'b00;
			uoq_tail <= (uoq_tail + 8'd3) % UOQ_ENTRIES;
			tskLd4(uo_insn1[2][`UO_LD4],insnx[0],uoq_const[(uoq_tail+2) % UOQ_ENTRIES]);
		end
		if (uo_len1 > 2'b10) begin
			uoq_v[(uoq_tail+3) % UOQ_ENTRIES] <= `VAL;
			uoq_pc[(uoq_tail+3) % UOQ_ENTRIES] <= pc;
			uoq_uop[(uoq_tail+3) % UOQ_ENTRIES] <= uo_insn1[3];
			uoq_fl[(uoq_tail+3) % UOQ_ENTRIES] <= 2'b10;
			uoq_tail <= (uoq_tail + 8'd4) % UOQ_ENTRIES;
			tskLd4(uo_insn1[3][`UO_LD4],insnx[0],uoq_const[(uoq_tail+3) % UOQ_ENTRIES]);
		end
		for (n = 0; n < 4; n = n + 1)
			if (n < uo_len1)
				uop_flagsupd[(uop_tail+n) % UOQ_ENTRIES] <= `UOF_NONE;
		uop_flagsupd[(uop_tail+uo_whflg1) % UOP_ENTRIES] <= uo_flags1;
	end

	if (!branchmiss) begin
		queuedOn <= queuedOnp;
		case(slotvd)
		3'b001:
			if (queuedOnp[0]) begin
				queue_slot(0,rob_tails[0],maxsn+1'd1,id_bus[0],active_tag,rob_tails[0]);
				uoq_v[uoq_head] <= `INV;
				uoq_head <= uoq_head + 3'd1;
			end
		3'b010:
			if (queuedOnp[1]) begin
				queue_slot(1,rob_tails[0],maxsn+1'd1,id_bus[1],active_tag,rob_tails[0]);
				uoq_v[uoq_head] <= `INV;
				uoq_head <= uoq_head + 3'd1;
			end
		3'b011:
			if (queuedOnp[0]) begin
				queue_slot(0,rob_tails[0],maxsn+1'd1,id_bus[0],active_tag,rob_tails[0]);
				uoq_v[uoq_head] <= `INV;
				uoq_head <= uoq_head + 3'd1;
				if (queuedOnp[1]) begin
					queue_slot(1,rob_tails[1],maxsn+2'd2,id_bus[1],is_branch[0] ? active_tag+2'd1 : active_tag,rob_tails[1]);
					uoq_v[(uoq_head + 1) % UOQ_ENTRIES] <= `INV;
					uoq_head <= uoq_head + 3'd2;
					arg_vs(3'b011);
				end
			end
		3'b100:
			if (queuedOnp[2]) begin
				queue_slot(2,rob_tails[0],maxsn+1'd1,id_bus[2],active_tag,rob_tails[0]);
				uoq_v[uoq_head] <= `INV;
				uoq_head <= uoq_head + 3'd1;
			end
		3'b101:	;	// illegal
		3'b110:
			if (queuedOnp[1]) begin
				queue_slot(1,rob_tails[0],maxsn+1'd1,id_bus[1],active_tag,rob_tails[0]);
				uoq_v[uoq_head] <= `INV;
				uoq_head <= uoq_head + 3'd1;
				if (queuedOnp[2]) begin
					queue_slot(2,rob_tails[1],maxsn+2'd2,id_bus[2],is_branch[1] ? active_tag + 2'd1 : active_tag,rob_tails[1]);
					uoq_v[(uoq_head + 1) % UOQ_ENTRIES] <= `INV;
					uoq_head <= uoq_head + 3'd2;
					arg_vs(3'b110);
				end
			end
		3'b111:
			if (queuedOnp[0]) begin
				uoq_head <= uoq_head + 3'd1;
				uoq_v[uoq_head] <= `INV;
				queue_slot(0,rob_tails[0],maxsn+1'd1,id_bus[0],active_tag,rob_tails[0]);
				if (queuedOnp[1]) begin
					queue_slot(1,rob_tails[1],maxsn+2'd2,id_bus[1],is_branch[0] ? active_tag + 2'd1 : active_tag,rob_tails[1]);
					uoq_v[(uoq_head + 1) % UOQ_ENTRIES] <= `INV;
					uoq_head <= uoq_head + 3'd2;
					arg_vs(3'b011);
					if (queuedOnp[2]) begin
						queue_slot(2,rob_tails[2],maxsn+2'd3,id_bus[2],
							is_branch[0] && is_branch[1] ? active_tag + 2'd2 :
							is_branch[0] ? active_tag + 2'd1 : is_branch[1] ? active_tag + 2'd1 : active_tag,rob_tails[2]);
						uoq_v[(uoq_head + 2) % UOQ_ENTRIES] <= `INV;
						uoq_head <= uoq_head + 3'd3;
						arg_vs(3'b111);
					end
				end
			end
		default:	;
		endcase
	end
	
end

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
			iq_argA_v [tails[tails_rc(pat,row)]] <= regIsValid[Rd[row]] | SourceTValid(uop[insnx[row][7:0]]);
			iq_argA_s [tails[tails_rc(pat,row)]] <= rf_source[Rd[row]];
			iq_argB_v [tails[tails_rc(pat,row)]] <= regIsValid[Rn[row]] | Source2Valid(uop[insnx[row][7:0]]);
			iq_argB_s [tails[tails_rc(pat,row)]] <= rf_source[Rn[row]];
			for (col = 0; col < QSLOTS; col = col + 1) begin
				if (col < row) begin
					if (pat[col]) begin
						// Special checking for condition register sideways slice
						if (Rd[row]==Rd[col] && slot_rfw[col]) begin
							iq_argA_v [tails[tails_rc(pat,row)]] <= SourceTValid(uop[insnx[row][7:0]]);
							iq_argA_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end

						if (Rn[row]==Rd[col] && slot_rfw[col]) begin
							iq_argB_v [tails[tails_rc(pat,row)]] <= Source2Valid(uop[insnx[row][7:0]]);
							iq_argB_s [tails[tails_rc(pat,row)]] <= {1'b0,tails[tails_rc(pat,col)]};
						end
					end
				end
			end
		end
	end
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
	iq_pc <= uoq_pc[(uoq_head+slot) % UOQ_ENTRIES];
	iq_instr[ndx][5:0] <= uoq_uop[(uoq_head+slot) % UOQ_ENTRIES][15:10];
	iq_fl[ndx] <= uoq_fl[(uoq_head+slot) % UOQ_ENTRIES];
	iq_argI[ndx] <= uoq_const[(uoq_head+slot) % UOQ_ENTRIES];
	iq_argA[ndx] <= argA[slot];
	iq_argB[ndx] <= argB[slot];
	iq_argS[ndx] <= argS[slot];
	iq_argA_v[ndx] <= regIsValid[Rd[slot]] || Source1Valid(uoq_uop[(uoq_head+slot) % UOQ_ENTRIES][15:10]);
	iq_argB_v[ndx] <= regIsValid[Rn[slot]] || Source2Valid(uoq_uop[(uoq_head+slot) % UOQ_ENTRIES][15:10]);
	iq_argS_v[ndx] <= regIsValid[7] || SourceSValid(uoq_uop[(uoq_head+slot) % UOQ_ENTRIES][15:10]);
	iq_argA_s[ndx] <= rf_source[Rd[slot]];
	iq_argB_s[ndx] <= rf_source[Rn[slot]];
	iq_argS_s[ndx] <= rf_source[7];
	iq_pt[ndx] <= predict_taken[slot];
	iq_tgt[ndx] <= uoq_uop[(uoq_head+slot) % UOQ_ENTRIES][5:3];
	iq_sr_tgts[ndx] <= uoq_flagsupd[(uoq_head+slot) % UOQ_ENTRIES];
	set_insn(ndx,id_bus);
	rob_pc[rid] <= uoq_pc[(uoq_head+slot) % UOQ_ENTRIES];
	rob_res[rid] <= 1'd0;
	rob_status[rid] <= 1'd0;
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
		dram0_rmw  <= iq_rmw[n];
		dram0_preload <= iq_preload[n];
		dram0_tgt 	<= iq_tgt[n];
		// These two args needed only to support AMO operations
		dram0_argI	<= {{68{iq_instr[n][27]}},iq_instr[n][27:16]};
		dram0_argB  <= iq_argB_v[n] ? iq_argB[n][WID-1:0]
			: iq_argB_s[n]==alu0_id ? ralu0_bus
			: iq_argB_s[n]==alu1_id ? ralu1_bus
			: iq_argB_s[n]==fpu1_id ? rfpu1_bus[WID-1:0]
			: 80'hDEADDEADDEADDEADDEAD;
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
	dram1_argB  <= iq_argB_v[n] ? iq_argB[n][WID-1:0]
	  : iq_argB_s[n]==alu0_id ? ralu0_bus
	  : iq_argB_s[n]==alu1_id ? ralu1_bus
	  : iq_argB_s[n]==fpu1_id ? rfpu1_bus[WID-1:0]
	  : 80'hDEADDEADDEADDEADDEAD;
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

module instLength(opcode,len);
input [7:0] opcode;
case(opcode)
`SEP,`REP:	len <= 4'd2;
`BRK:	len <= 4'd0;
`BPL,`BMI,`BCS,`BCC,`BVS,`BVC,`BEQ,`BNE,`BRA:	len <= 4'd2;
`BRL: len <= 4'd3;
`CLC,`SEC,`CLD,`SED,`CLV,`CLI,`SEI:	len <= 4'd1;
`TAS,`TSA,`TAY,`TYA,`TAX,`TXA,`TSX,`TXS,`TYX,`TXY,`TCD,`TDC,`XBA:	len <= 4'd1;
`INY,`DEY,`INX,`DEX,`INA,`DEA: len <= 4'd1;
`XCE,`WDM: len <= 4'd1;
`STP,`WAI: len <= 4'd1;
`JMP,`JML,`JMP_IND,`JMP_INDX,
`RTS,`RTL,`RTI: len <= 4'd0;
`JSR,`JSR_INDX:	len <= 4'd2;
`JSL:	len <= 4'd3;
`NOP: len <= 4'd1;

`ADC_IMM,`SBC_IMM,`CMP_IMM,`AND_IMM,`ORA_IMM,`EOR_IMM,`LDA_IMM,`BIT_IMM:	len <= m16 ? 4'd3 : 4'd2;
`LDX_IMM,`LDY_IMM,`CPX_IMM,`CPY_IMM: len <= xb16 ? 4'd3 : 4'd2;

`TRB_ZP,`TSB_ZP,
`ADC_ZP,`SBC_ZP,`CMP_ZP,`AND_ZP,`ORA_ZP,`EOR_ZP,`LDA_ZP,`STA_ZP: len <= 4'd2;
`LDY_ZP,`LDX_ZP,`STY_ZP,`STX_ZP,`CPX_ZP,`CPY_ZP,`BIT_ZP,`STZ_ZP: len <= 4'd2;
`ASL_ZP,`ROL_ZP,`LSR_ZP,`ROR_ZP,`INC_ZP,`DEC_ZP: len <= 4'd2;

`ADC_ZPX,`SBC_ZPX,`CMP_ZPX,`AND_ZPX,`ORA_ZPX,`EOR_ZPX,`LDA_ZPX,`STA_ZPX: len <= 4'd2;
`LDY_ZPX,`STY_ZPX,`BIT_ZPX,`STZ_ZPX: len <= 4'd2;
`ASL_ZPX,`ROL_ZPX,`LSR_ZPX,`ROR_ZPX,`INC_ZPX,`DEC_ZPX: len <= 4'd2;
`LDX_ZPY,`STX_ZPY: len <= 4'd2;

`ADC_I,`SBC_I,`AND_I,`ORA_I,`EOR_I,`CMP_I,`LDA_I,`STA_I,
`ADC_IL,`SBC_IL,`AND_IL,`ORA_IL,`EOR_IL,`CMP_IL,`LDA_IL,`STA_IL,
`ADC_IX,`SBC_IX,`CMP_IX,`AND_IX,`OR_IX,`EOR_IX,`LDA_IX,`STA_IX: len <= 4'd2;

`ADC_IY,`SBC_IY,`CMP_IY,`AND_IY,`OR_IY,`EOR_IY,`LDA_IY,`STA_IY: len <= 4'd2;
`ADC_IYL,`SBC_IYL,`CMP_IYL,`AND_IYL,`ORA_IYL,`EOR_IYL,`LDA_IYL,`STA_IYL: len <= 4'd2;

`TRB_ABS,`TSB_ABS,
`ADC_ABS,`SBC_ABS,`CMP_ABS,`AND_ABS,`OR_ABS,`EOR_ABS,`LDA_ABS,`STA_ABS: len <= 4'd3;
`LDX_ABS,`LDY_ABS,`STX_ABS,`STY_ABS,`CPX_ABS,`CPY_ABS,`BIT_ABS,`STZ_ABS: len <= 4'd3;
`ASL_ABS,`ROL_ABS,`LSR_ABS,`ROR_ABS,`INC_ABS,`DEC_ABS: len <= 4'd3;

`ADC_ABSX,`SBC_ABSX,`CMP_ABSX,`AND_ABSX,`OR_ABSX,`EOR_ABSX,`LDA_ABSX,`STA_ABSX: len <= 4'd3;
`LDY_ABSX,`BIT_ABSX,`STZ_ABSX:	len <= 4'd3;
`ASL_ABSX,`ROL_ABSX,`LSR_ABSX,`ROR_ABSX,`INC_ABSX,`DEC_ABSX: len <= 4'd3;

`ADC_ABSY,`SBC_ABSY,`CMP_ABSY,`AND_ABSY,`ORA_ABSY,`EOR_ABSY,`LDA_ABSY,`STA_ABSY: len <= 4'd3;
`LDX_ABSY: len <= 4'd3;

`ADC_AL,`SBC_AL,`CMP_AL,`AND_AL,`ORA_AL,`EOR_AL,`LDA_AL,`STA_AL: len <= 4'd4;
`ADC_ALX,`SBC_ALX,`CMP_ALX,`AND_ALX,`ORA_ALX,`EOR_ALX,`LDA_ALX,`STA_ALX: len <= 4'd4;

`ADC_DSP,`SBC_DSP,`CMP_DSP,`AND_DSP,`ORA_DSP,`EOR_DSP,`LDA_DSP,`STA_DSP: len <= 4'd2;
`ADC_DSPIY,`SBC_DSPIY,`CMP_DSPIY,`AND_DSPIY,`ORA_DSPIY,`EOR_DSPIY,`LDA_DSPIY,`STA_DSPIY: len <= 4'd2;

`ASL_ACC,`LSR_ACC,`ROR_ACC,`ROL_ACC: len <= 4'd1;

`PHP,`PHA,`PHX,`PHY,`PHK,`PHB,`PHD,`PLP,`PLA,`PLX,`PLY,`PLB,`PLD: len <= 4'd1;
`PEA,`PER,`MVN,`MVP: len <= 4'd3;
`PEI:	len <= 4'd2;

default:	len <= 4'd0;	// unimplemented instruction
endcase
endmodule
