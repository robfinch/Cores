import fta_bus_pkg::*;
import rfx32_cache_pkg::*;
import rfx32pkg::*;

`define ZERO		32'd0

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

`define DRAMSLOT_AVAIL	2'b00
`define DRAMREQ_READY	2'b11

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
`define PANIC_BADTARGETID	4'd12

module rfx32(rst_i, clk_i, wr_o, adr_o, dat_i, dat_o,
	ftaim_req, ftaim_resp, ftadm_req, ftadm_resp,
	snoop_adr, snoop_v, snoop_cid);
parameter CORENO = 6'd1;
parameter CID = 6'd1;
input rst_i;
input clk_i;
output reg wr_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;
output fta_cmd_request128_t [NDATA_PORTS-1:0] ftadm_req;
input fta_cmd_response128_t [NDATA_PORTS-1:0] ftadm_resp;
output fta_cmd_request128_t ftaim_req;
input fta_cmd_response128_t ftaim_resp;
input rfx32pkg::address_t snoop_adr;
input snoop_v;
input [5:0] snoop_cid;

integer nn,n1,n2,n3;
genvar g;

wire value_t [31:0] rf;
wire [31:0] rf_v;
wire [4:0] rf_source[0:31];
wire [31:0] pc;
reg [31:0] m[0:16383];
wire clk;
wire rst;
assign rst = rst_i;
reg  [3:0] panic;		// indexes the message structure
reg [128:0] message [0:15];	// indexed by panic

// instruction queue (ROB)
iq_entry_t [7:0] iq;

wire  [7:0] iqentry_source;
wire  [7:0] iqentry_imm;
wire  [7:0] iqentry_memready;
wire  [7:0] iqentry_memopsvalid;

reg [7:0] iqentry_memissue;
wire [7:0] iqentry_stomp;
reg [7:0] iqentry_issue;
reg [1:0] iqentry_islot [0:7];

wire  [31:1] livetarget;
wire  [31:1] iqentry_0_livetarget;
wire  [31:1] iqentry_1_livetarget;
wire  [31:1] iqentry_2_livetarget;
wire  [31:1] iqentry_3_livetarget;
wire  [31:1] iqentry_4_livetarget;
wire  [31:1] iqentry_5_livetarget;
wire  [31:1] iqentry_6_livetarget;
wire  [31:1] iqentry_7_livetarget;
wire  [31:1] iqentry_0_latestID;
wire  [31:1] iqentry_1_latestID;
wire  [31:1] iqentry_2_latestID;
wire  [31:1] iqentry_3_latestID;
wire  [31:1] iqentry_4_latestID;
wire  [31:1] iqentry_5_latestID;
wire  [31:1] iqentry_6_latestID;
wire  [31:1] iqentry_7_latestID;
wire  [31:1] iqentry_0_cumulative;
wire  [31:1] iqentry_1_cumulative;
wire  [31:1] iqentry_2_cumulative;
wire  [31:1] iqentry_3_cumulative;
wire  [31:1] iqentry_4_cumulative;
wire  [31:1] iqentry_5_cumulative;
wire  [31:1] iqentry_6_cumulative;
wire  [31:1] iqentry_7_cumulative;
wire  [31:1] iq0_out;
wire  [31:1] iq1_out;
wire  [31:1] iq2_out;
wire  [31:1] iq3_out;
wire  [31:1] iq4_out;
wire  [31:1] iq5_out;
wire  [31:1] iq6_out;
wire  [31:1] iq7_out;

wire [2:0] tail0;
wire [2:0] tail1;
reg  [2:0] head0;
reg  [2:0] head1;
reg  [2:0] head2;	// used only to determine memory-access ordering
reg  [2:0] head3;	// used only to determine memory-access ordering
reg  [2:0] head4;	// used only to determine memory-access ordering
reg  [2:0] head5;	// used only to determine memory-access ordering
reg  [2:0] head6;	// used only to determine memory-access ordering
reg  [2:0] head7;	// used only to determine memory-access ordering

wire  [2:0] missid;

regspec_t Ra0, Rb0, Rc0, Rt0;
regspec_t Ra1, Rb1, Rc1, Rt1;

wire        fetchbuf;	// determines which pair to read from & write to

instruction_t fetchbuf0_instr;	
wire [31:0] fetchbuf0_pc;
wire        fetchbuf0_v;
wire        fetchbuf0_mem;
wire        fetchbuf0_jmp;
wire        fetchbuf0_rfw;
wire [33:0] fetchbuf0_imm;
instruction_t fetchbuf1_instr;
wire [31:0] fetchbuf1_pc;
wire        fetchbuf1_v;
wire        fetchbuf1_mem;
wire        fetchbuf1_jmp;
wire        fetchbuf1_rfw;
wire [33:0] fetchbuf1_imm;

assign fetchbuf0_jmp = 1'b0;
assign fetchbuf1_jmp = 1'b0;

reg        alu0_available;
reg        alu0_dataready;
reg  [3:0] alu0_sourceid;
instruction_t alu0_instr;
reg        alu0_bt;
reg [31:0] alu0_argA;
reg [31:0] alu0_argB;
reg [31:0] alu0_argI;	// only used by BEQ
reg [31:0] alu0_pc;
reg [31:0] alu0_bus;
wire  [3:0] alu0_id;
wire  [3:0] alu0_exc;
wire        alu0_v;
wire        alu0_branchmiss;
reg [31:0] alu0_misspc;
reg takb0;

reg        alu1_available;
reg        alu1_dataready;
reg  [3:0] alu1_sourceid;
instruction_t alu1_instr;
reg        alu1_bt;
reg [31:0] alu1_argA;
reg [31:0] alu1_argB;
reg [31:0] alu1_argI;	// only used by BEQ
reg [31:0] alu1_pc;
reg [31:0] alu1_bus;
wire  [3:0] alu1_id;
wire  [3:0] alu1_exc;
wire        alu1_v;
wire        alu1_branchmiss;
reg [31:0] alu1_misspc;
reg takb1;

wire        branchback;
wire [31:0] backpc;
wire        branchmiss;
wire [31:0] misspc;

wire        dram_avail;
reg	 [1:0] dram0;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [1:0] dram1;	// state of the DRAM request (latency = 4; can have three in pipeline)
reg	 [1:0] dram2;	// state of the DRAM request (latency = 4; can have three in pipeline)

value_t dram0_data;
reg [31:0] dram0_addr;
instruction_t dram0_op;
reg dram0_load;
reg dram0_store;
regspec_t dram0_tgt;
reg  [4:0] dram0_id;
reg  [3:0] dram0_exc;
reg dram0_ack;

value_t dram1_data;
reg [31:0] dram1_addr;
instruction_t dram1_op;
reg dram1_load;
reg dram1_store;
regspec_t dram1_tgt;
reg  [4:0] dram1_id;
reg  [3:0] dram1_exc;
reg dram1_ack;

value_t dram2_data;
reg [31:0] dram2_addr;
instruction_t dram2_op;
reg dram2_load;
reg dram2_store;
regspec_t dram2_tgt;
reg  [4:0] dram2_id;
reg  [3:0] dram2_exc;
reg dram2_ack;

reg [1:0] dramN;
value_t [NDATA_PORTS-1:0] dramN_data;
reg [31:0] dramN_addr [0:NDATA_PORTS-1];
reg [NDATA_PORTS-1:0] dramN_load;
reg [NDATA_PORTS-1:0] dramN_store;
reg [NDATA_PORTS-1:0] dramN_ack;

value_t dram_bus;
regspec_t dram_tgt;
reg  [4:0] dram_id;
reg  [3:0] dram_exc;
reg        dram_v;

wire        outstanding_stores;
reg [63:0] I;	// instruction count

wire commit0_v;
wire [4:0] commit0_id;
regspec_t commit0_tgt;
value_t commit0_bus;
wire commit1_v;
wire [4:0] commit1_id;
regspec_t commit1_tgt;
value_t commit1_bus;

assign clk = clk_i;

function fnA2;
input fetchbuf_rfw;
input instruction_t fetchbuf_instr;
input address_t fetchbuf_pc;
input [4:0] Rb;
begin
	fnA2 = fetchbuf_rfw ?
				 (fnIsCall(fetchbuf_instr) ? fetchbuf_pc : rf[ Rb ])
							      : rf[ Rb ];
end
endfunction

decoder5 iq0(.num(iq[0].tgt), .out(iq0_out));
decoder5 iq1(.num(iq[1].tgt), .out(iq1_out));
decoder5 iq2(.num(iq[2].tgt), .out(iq2_out));
decoder5 iq3(.num(iq[3].tgt), .out(iq3_out));
decoder5 iq4(.num(iq[4].tgt), .out(iq4_out));
decoder5 iq5(.num(iq[5].tgt), .out(iq5_out));
decoder5 iq6(.num(iq[6].tgt), .out(iq6_out));
decoder5 iq7(.num(iq[7].tgt), .out(iq7_out));

    initial begin: stop_at
	#1000000; panic <= `PANIC_OVERRUN;
    end

    initial begin: Init
	integer i;

/*
	for (i=0; i<65536; i=i+1)
	    m[i] = 0;
*/
//	$readmemh("init.dat", m);
	for (i=0; i<8; i=i+1) begin
	  iq[i].v = INV;
	end
	head0 = 0;
	head1 = 1;
	head2 = 2;
	head3 = 3;
	head4 = 4;
	head5 = 5;
	head6 = 6;
	head7 = 7;
	panic = `PANIC_NONE;
	alu0_available = 1;
	alu0_dataready = 0;
	alu1_available = 1;
	alu1_dataready = 0;
	dram_v = 0;
	I = 0;

	dram0 = 0;
	dram1 = 0;
	dram2 = 0;

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
address_t pco;
reg [31:0] icache_ram [0:255];
reg [31:4] icache_tag_ram [0:255];

reg [159:0] inst0, inst1;
reg [31:0] icache_uadr;
reg [31:0] icache_radr;
reg [31:0] icache_udat;
reg [31:0] icache_odat0;
reg [31:0] icache_odat1;
reg [31:0] icache_odat2;
wire [511:0] ic_line_hi, ic_line_lo;
reg [1023:0] ic_line;

always_comb
	ic_line = {ic_line_hi,ic_line_lo};
always_comb
	inst0 = ic_line >> {pco[5:0],3'd0};
always_comb
	inst1 = ic_line >> {pco[5:0]+fnInsLen(inst0),3'd0};

/*
always_comb
	if (dram0_op==`LW || dram1_op==`LW || dram2_op==`LW)
		adr_o = icache_radr;
	else
		adr_o = icache_uadr;
*/
	
//
// FETCH
//
// fetch exactly two instructions from memory into the fetch buffer
// unless either one of the buffers is still full, in which case we
// do nothing (kinda like alpha approach)
//
reg invce = 1'b0;
reg dc_invline = 1'b0;
reg dc_invall = 1'b0;
reg ic_invline = 1'b0;
reg ic_invall = 1'b0;
ICacheLine ic_line_o;

asid_t ip_asid;
wire wr_ic;
wire ihito,ihit;
wire ic_valid;
address_t ic_miss_adr;
asid_t ic_miss_asid;
wire [1:0] ic_wway;
  
rfx32_icache uic1
(
	.rst(rst),
	.clk(clk),
	.invce(invce),
	.snoop_adr(snoop_adr),
	.snoop_v(snoop_v),
	.snoop_cid(snoop_cid),
	.invall(ic_invall),
	.invline(ic_invline),
	.ip_asid(ip_asid),
	.ip(pc),
	.ip_o(pco),
	.ihit_o(ihito),
	.ihit(ihit),
	.ic_line_hi_o(ic_line_hi),
	.ic_line_lo_o(ic_line_lo),
	.ic_valid(ic_valid),
	.miss_adr(ic_miss_adr),
	.miss_asid(ic_miss_asid),
	.ic_line_i(ic_line_o),
	.wway(ic_wway),
	.wr_ic(wr_ic)
);

rfx32_icache_ctrl icctrl1
(
	.rst(rst),
	.clk(clk),
	.wbm_req(ftaim_req),
	.wbm_resp(ftaim_resp),
	.hit(ihit),
	.miss_adr(ic_miss_adr),
	.miss_asid(ic_miss_asid),
	.wr_ic(wr_ic),
	.way(ic_wway),
	.line_o(ic_line_o),
	.snoop_adr(snoop_adr),
	.snoop_v(snoop_v),
	.snoop_cid(snoop_cid)
);

rfx32_ifetch uif1
(
	.rst(rst),
	.clk(clk),
	.branchback(branchback),
	.backpc(backpc),
	.branchmiss(branchmiss),
	.misspc(misspc),
	.pc(pc),
	.inst0(inst0),
	.inst1(inst1),
	.iq(iq),
	.tail0(tail0),
	.tail1(tail1),
	.fetchbuf(fetchbuf),
	.fetchbuf0_instr(fetchbuf0_instr),
	.fetchbuf0_imm(fetchbuf0_imm),
	.fetchbuf0_v(fetchbuf0_v),
	.fetchbuf0_pc(fetchbuf0_pc),
	.fetchbuf1_instr(fetchbuf1_instr),
	.fetchbuf1_v(fetchbuf1_v),
	.fetchbuf1_pc(fetchbuf1_pc),
	.fetchbuf1_imm(fetchbuf1_imm)
);

assign fetchbuf0_mem = fnIsLoad(fetchbuf0_instr) || fnIsStore(fetchbuf0_instr);
assign fetchbuf1_mem = fnIsLoad(fetchbuf1_instr) || fnIsStore(fetchbuf1_instr);
assign fetchbuf0_rfw = Rt0 != 'd0;
assign fetchbuf1_rfw = Rt1 != 'd0;

wire [NDATA_PORTS-1:0] dcache_load;
wire [NDATA_PORTS-1:0] dhit;
wire [NDATA_PORTS-1:0] modified;
wire [1:0] uway [0:NDATA_PORTS-1];
fta_cmd_request512_t [NDATA_PORTS-1:0] cpu_request_i;
fta_cmd_request512_t [NDATA_PORTS-1:0] cpu_request_i2;
fta_cmd_response512_t [NDATA_PORTS-1:0] cpu_resp_o;
fta_cmd_response512_t [NDATA_PORTS-1:0] update_data_i;
wire [NDATA_PORTS-1:0] dump;
wire [NDATA_PORTS-1:0] dump_o;
wire [NDATA_PORTS-1:0] dump_ack;
wire [NDATA_PORTS-1:0] dwr;
wire [1:0] dway [0:NDATA_PORTS-1];

always_comb
begin
	dramN[0] = dram0;
	dramN_addr[0] = dram0_addr;
	dramN_data[0] = dram0_data;
	dramN_store[0] = dram0_store;
	dram0_ack = dramN_ack[0];

	dramN[1] = dram1;
	dramN_addr[1] = dram1_addr;
	dramN_data[1] = dram1_data;
	dramN_store[1] = dram1_store;
	dram1_ack = dramN_ack[1];

	dramN[1] = dram2;
	dramN_addr[1] = dram2_addr;
	dramN_data[1] = dram2_data;
	dramN_store[1] = dram2_store;
	dram2_ack = dramN_ack[2];
end

generate begin : gDcache
for (g = 0; g < NDATA_PORTS; g = g + 1) begin

	always_comb
	begin
		cpu_request_i[g].cyc = dramN[g]==`DRAMREQ_READY;
		cpu_request_i[g].stb = dramN[g]==`DRAMREQ_READY;
		cpu_request_i[g].we = dramN_store[g];
		cpu_request_i[g].vadr = dramN_addr[g];
		cpu_request_i[g].dat = dramN_data[g] << {dramN_addr[g][5:0],3'd0};
		dramN_ack[g] = cpu_resp_o[g].ack;
	end

	rfx32_dcache udc1
	(
		.rst(rst),
		.clk(clk),
		.dce(1'b1),
		.snoop_adr(snoop_adr),
		.snoop_v(snoop_v),
		.snoop_cid(snoop_cid),
		.cache_load(dcache_load[g]),
		.hit(dhit[g]),
		.modified(modified[g]),
		.uway(uway[g]),
		.cpu_req_i(cpu_request_i2[g]),
		.cpu_resp_o(cpu_resp_o[g]),
		.update_data_i(update_data_i[g]),
		.dump(dump[g]),
		.dump_o(dump_o[g]),
		.dump_ack_i(dump_ack[g]),
		.wr(dwr[g]),
		.way(dway[g]),
		.invce(invce),
		.dc_invline(dc_invline),
		.dc_invall(dc_invall)
	);

	rfx32_dcache_ctrl udcctrl1
	(
		.rst_i(rst),
		.clk_i(clk),
		.dce(1'b1),
		.ftam_req(ftadm_req[g]),
		.ftam_resp(ftadm_resp[g]),
		.acr(),
		.hit(dhit[g]),
		.modified(modified[g]),
		.cache_load(dcache_load[g]),
		.cpu_request_i(cpu_request_i[g]),
		.cpu_request_i2(cpu_request_i2[g]),
		.data_to_cache_o(update_data_i[g]),
		.response_from_cache_i(cpu_resp_o[g]),
		.wr(dwr[g]),
		.uway(uway[g]),
		.way(dway[g]),
		.dump(dump[g]),
		.dump_i(dump_o[g]),
		.dump_ack(dump_ack[g]),
		.snoop_adr(snoop_adr),
		.snoop_v(snoop_v),
		.snoop_cid(snoop_cid)
	);

end
end
endgenerate

/* 
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
*/
//
// set branchback and backpc values ... ignore branches in fetchbuf slots not ready for enqueue yet
//
assign branchback = ({fetchbuf0_v, fnIsBackBranch(fetchbuf0_instr)} == {VAL, TRUE})
									|| ({fetchbuf1_v, fnIsBackBranch(fetchbuf1_instr)} == {VAL, TRUE});

assign backpc = ({fetchbuf0_v, fnIsBackBranch(fetchbuf0_instr)} == {VAL, TRUE})
	    ? (fetchbuf0_pc + fnBranchDisp(fetchbuf0_instr))
	    : (fetchbuf1_pc + fnBranchDisp(fetchbuf1_instr));

//
// BRANCH-MISS LOGIC: livetarget
//
// livetarget implies that there is a not-to-be-stomped instruction that targets the register in question
// therefore, if it is zero it implies the rf_v value should become VALID on a branchmiss
// 

assign  livetarget[1] = iqentry_0_livetarget[1] | iqentry_1_livetarget[1] | iqentry_2_livetarget[1] | iqentry_3_livetarget[1]
	    | iqentry_4_livetarget[1] | iqentry_5_livetarget[1] | iqentry_6_livetarget[1] | iqentry_7_livetarget[1]
	    ;
assign  livetarget[2] = iqentry_0_livetarget[2] | iqentry_1_livetarget[2] | iqentry_2_livetarget[2] | iqentry_3_livetarget[2]
	    | iqentry_4_livetarget[2] | iqentry_5_livetarget[2] | iqentry_6_livetarget[2] | iqentry_7_livetarget[2]
	    ;
assign  livetarget[3] = iqentry_0_livetarget[3] | iqentry_1_livetarget[3] | iqentry_2_livetarget[3] | iqentry_3_livetarget[3]
	    | iqentry_4_livetarget[3] | iqentry_5_livetarget[3] | iqentry_6_livetarget[3] | iqentry_7_livetarget[3]
			;
assign  livetarget[4] = iqentry_0_livetarget[4] | iqentry_1_livetarget[4] | iqentry_2_livetarget[4] | iqentry_3_livetarget[4]
	    | iqentry_4_livetarget[4] | iqentry_5_livetarget[4] | iqentry_6_livetarget[4] | iqentry_7_livetarget[4]
			;
assign  livetarget[5] = iqentry_0_livetarget[5] | iqentry_1_livetarget[5] | iqentry_2_livetarget[5] | iqentry_3_livetarget[5]
	    | iqentry_4_livetarget[5] | iqentry_5_livetarget[5] | iqentry_6_livetarget[5] | iqentry_7_livetarget[5]
			;
assign  livetarget[6] = iqentry_0_livetarget[6] | iqentry_1_livetarget[6] | iqentry_2_livetarget[6] | iqentry_3_livetarget[6]
	    | iqentry_4_livetarget[6] | iqentry_5_livetarget[6] | iqentry_6_livetarget[6] | iqentry_7_livetarget[6]
	    ;
assign  livetarget[7] = iqentry_0_livetarget[7] | iqentry_1_livetarget[7] | iqentry_2_livetarget[7] | iqentry_3_livetarget[7]
	    | iqentry_4_livetarget[7] | iqentry_5_livetarget[7] | iqentry_6_livetarget[7] | iqentry_7_livetarget[7]
			;
assign  livetarget[8] = iqentry_0_livetarget[8] | iqentry_1_livetarget[8] | iqentry_2_livetarget[8] | iqentry_3_livetarget[8]
	    | iqentry_4_livetarget[8] | iqentry_5_livetarget[8] | iqentry_6_livetarget[8] | iqentry_7_livetarget[8]
			;
assign  livetarget[9] = iqentry_0_livetarget[9] | iqentry_1_livetarget[9] | iqentry_2_livetarget[9] | iqentry_3_livetarget[9]
	    | iqentry_4_livetarget[9] | iqentry_5_livetarget[9] | iqentry_6_livetarget[9] | iqentry_7_livetarget[9]
			;
assign  livetarget[10] = iqentry_0_livetarget[10] | iqentry_1_livetarget[10] | iqentry_2_livetarget[10] | iqentry_3_livetarget[10]
	    | iqentry_4_livetarget[10] | iqentry_5_livetarget[10] | iqentry_6_livetarget[10] | iqentry_7_livetarget[10]
			;
assign  livetarget[11] = iqentry_0_livetarget[11] | iqentry_1_livetarget[11] | iqentry_2_livetarget[11] | iqentry_3_livetarget[11]
	    | iqentry_4_livetarget[11] | iqentry_5_livetarget[11] | iqentry_6_livetarget[11] | iqentry_7_livetarget[11]
			;
assign  livetarget[12] = iqentry_0_livetarget[12] | iqentry_1_livetarget[12] | iqentry_2_livetarget[12] | iqentry_3_livetarget[12]
	    | iqentry_4_livetarget[12] | iqentry_5_livetarget[12] | iqentry_6_livetarget[12] | iqentry_7_livetarget[12]
			;
assign  livetarget[13] = iqentry_0_livetarget[13] | iqentry_1_livetarget[13] | iqentry_2_livetarget[13] | iqentry_3_livetarget[13]
	    | iqentry_4_livetarget[13] | iqentry_5_livetarget[13] | iqentry_6_livetarget[13] | iqentry_7_livetarget[13]
			;
assign  livetarget[14] = iqentry_0_livetarget[14] | iqentry_1_livetarget[14] | iqentry_2_livetarget[14] | iqentry_3_livetarget[14]
	    | iqentry_4_livetarget[14] | iqentry_5_livetarget[14] | iqentry_6_livetarget[14] | iqentry_7_livetarget[14]
			;
assign  livetarget[15] = iqentry_0_livetarget[15] | iqentry_1_livetarget[15] | iqentry_2_livetarget[15] | iqentry_3_livetarget[15]
	    | iqentry_4_livetarget[15] | iqentry_5_livetarget[15] | iqentry_6_livetarget[15] | iqentry_7_livetarget[15]
			;
assign  
	iqentry_0_livetarget = {15 {iq[0].v}} & {7 {~iqentry_stomp[0]}} & iq0_out,
  iqentry_1_livetarget = {15 {iq[1].v}} & {7 {~iqentry_stomp[1]}} & iq1_out,
  iqentry_2_livetarget = {15 {iq[2].v}} & {7 {~iqentry_stomp[2]}} & iq2_out,
  iqentry_3_livetarget = {15 {iq[3].v}} & {7 {~iqentry_stomp[3]}} & iq3_out,
  iqentry_4_livetarget = {15 {iq[4].v}} & {7 {~iqentry_stomp[4]}} & iq4_out,
  iqentry_5_livetarget = {15 {iq[5].v}} & {7 {~iqentry_stomp[5]}} & iq5_out,
  iqentry_6_livetarget = {15 {iq[6].v}} & {7 {~iqentry_stomp[6]}} & iq6_out,
  iqentry_7_livetarget = {15 {iq[7].v}} & {7 {~iqentry_stomp[7]}} & iq7_out;

//
// BRANCH-MISS LOGIC: latestID
//
// latestID is the instruction queue ID of the newest instruction (latest) that targets
// a particular register.  looks a lot like scheduling logic, but in reverse.
// 

assign iqentry_0_latestID = (missid == 3'd0 || ((iqentry_0_livetarget & iqentry_1_cumulative) == 'd0))
		    ? iqentry_0_livetarget
		    : 7'd0;
assign iqentry_0_cumulative = (missid == 3'd0)
		    ? iqentry_0_livetarget
		    : iqentry_0_livetarget | iqentry_1_cumulative;

assign iqentry_1_latestID = (missid == 3'd1 || ((iqentry_1_livetarget & iqentry_2_cumulative) == 'd0))
		    ? iqentry_1_livetarget
		    : 7'd0;
assign iqentry_1_cumulative = (missid == 3'd1)
		    ? iqentry_1_livetarget
		    : iqentry_1_livetarget | iqentry_2_cumulative;

assign iqentry_2_latestID = (missid == 3'd2 || ((iqentry_2_livetarget & iqentry_3_cumulative) == 'd0))
		    ? iqentry_2_livetarget
		    : 7'd0;
assign iqentry_2_cumulative = (missid == 3'd2)
		    ? iqentry_2_livetarget
		    : iqentry_2_livetarget | iqentry_3_cumulative;

assign iqentry_3_latestID = (missid == 3'd3 || ((iqentry_3_livetarget & iqentry_4_cumulative) == 'd0))
		    ? iqentry_3_livetarget
		    : 7'd0;
assign iqentry_3_cumulative = (missid == 3'd3)
		    ? iqentry_3_livetarget
		    : iqentry_3_livetarget | iqentry_4_cumulative;

assign iqentry_4_latestID = (missid == 3'd4 || ((iqentry_4_livetarget & iqentry_5_cumulative) == 'd0))
		    ? iqentry_4_livetarget
		    : 7'd0;
assign iqentry_4_cumulative = (missid == 3'd4)
		    ? iqentry_4_livetarget
		    : iqentry_4_livetarget | iqentry_5_cumulative;

assign iqentry_5_latestID = (missid == 3'd5 || ((iqentry_5_livetarget & iqentry_6_cumulative) == 'd0))
		    ? iqentry_5_livetarget
		    : 7'd0;
assign iqentry_5_cumulative = (missid == 3'd5)
		    ? iqentry_5_livetarget
		    : iqentry_5_livetarget | iqentry_6_cumulative;

assign iqentry_6_latestID = (missid == 3'd6 || ((iqentry_6_livetarget & iqentry_7_cumulative) == 'd0))
		    ? iqentry_6_livetarget
		    : 7'd0;
assign iqentry_6_cumulative = (missid == 3'd6)
		    ? iqentry_6_livetarget
		    : iqentry_6_livetarget | iqentry_7_cumulative;

assign iqentry_7_latestID = (missid == 3'd7 || ((iqentry_7_livetarget & iqentry_0_cumulative) == 'd0))
		    ? iqentry_7_livetarget
		    : 7'd0;
assign iqentry_7_cumulative = (missid == 3'd7)
		    ? iqentry_7_livetarget
		    : iqentry_7_livetarget | iqentry_0_cumulative;
assign iqentry_7_latestID = (missid == 3'd7 || ((iqentry_7_livetarget & iqentry_0_cumulative) == 'd0))
		    ? iqentry_7_livetarget
		    : 7'd0;
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

rfx32_tail utail1
(
	.rst(rst),
	.clk(clk),
	.branchmiss(branchmiss),
	.fetchbuf0_v(fetchbuf0_v),
	.fetchbuf1_v(fetchbuf1_v),
	.iq(iq),
	.tail0(tail0),
	.tail1(tail1)
);

rfx32_regfile_source urfs1
(
	.rst(rst),
	.clk(clk),
	.tail0(tail0),
	.tail1(tail1),
	.branchmiss(branchmiss),
	.fetchbuf0_instr(fetchbuf0_instr),
	.fetchbuf1_instr(fetchbuf1_instr),
	.fetchbuf0_mem(fetchbuf0_mem),
	.fetchbuf1_mem(fetchbuf1_mem),
	.fetchbuf0_v(fetchbuf0_v),
	.fetchbuf1_v(fetchbuf1_v),
	.fetchbuf0_rfw(fetchbuf0_rfw),
	.fetchbuf1_rfw(fetchbuf1_rfw),
	.iqentry_0_latestID(iqentry_0_latestID),
	.iqentry_1_latestID(iqentry_1_latestID),
	.iqentry_2_latestID(iqentry_2_latestID),
	.iqentry_3_latestID(iqentry_3_latestID),
	.iqentry_4_latestID(iqentry_4_latestID),
	.iqentry_5_latestID(iqentry_5_latestID),
	.iqentry_6_latestID(iqentry_6_latestID),
	.iqentry_7_latestID(iqentry_7_latestID),
	.iq(iq),
	.rf_source(rf_source)
);

rfx32_regfile_valid urfv1
(
	.rst(rst),
	.clk(clk),
	.branchmiss(branchmiss),
	.tail0(tail0),
	.tail1(tail1),
	.fetchbuf0_v(fetchbuf0_v),
	.fetchbuf1_v(fetchbuf1_v),
	.fetchbuf0_rfw(fetchbuf0_rfw),
	.fetchbuf1_rfw(fetchbuf1_rfw),
	.fetchbuf0_instr(fetchbuf0_instr),
	.fetchbuf1_instr(fetchbuf1_instr),
	.iq(iq),
	.iqentry_source(iqentry_source),
	.commit0_v(commit0_v),
	.commit1_v(commit1_v),
	.commit0_tgt(commit0_tgt),
	.commit1_tgt(commit1_tgt),
	.commit0_id(commit0_id),
	.commit1_id(commit1_id),
	.rf_source(rf_source),
	.rf_v(rf_v)
);

rfx32_regfile urf1
(
	.rst(rst),
	.clk(clk),
	.commit0_v(commit0_v),
	.commit1_v(commit1_v),
	.commit0_tgt(commit0_tgt),
	.commit1_tgt(commit1_tgt),
	.commit0_bus(commit0_bus),
	.commit1_bus(commit1_bus),
	.rf(rf)
);

always_comb
	Ra0 = fnRa(fetchbuf0_instr);
always_comb
	Rb0 = fnRb(fetchbuf0_instr);
always_comb
	Rt0 = fnRt(fetchbuf0_instr);
always_comb
	Ra1 = fnRa(fetchbuf1_instr);
always_comb
	Rb1 = fnRb(fetchbuf1_instr);
always_comb
	Rt1 = fnRt(fetchbuf1_instr);

assign
	iq[0].imm = fnIsImm(iq[0].op),
	iq[1].imm = fnIsImm(iq[1].op),
	iq[2].imm = fnIsImm(iq[2].op),
	iq[3].imm = fnIsImm(iq[3].op),
	iq[4].imm = fnIsImm(iq[4].op),
	iq[5].imm = fnIsImm(iq[5].op),
	iq[6].imm = fnIsImm(iq[6].op),
	iq[7].imm = fnIsImm(iq[7].op)
	;

//
// additional logic for ISSUE
//
// for the moment, we look at ALU-input buffers to allow back-to-back issue of 
// dependent instructions ... we do not, however, look ahead for DRAM requests 
// that will become valid in the next cycle.  instead, these have to propagate
// their results into the IQ entry directly, at which point it becomes issue-able
//

// note that, for all intents & purposes, iqentry_done == iqentry_agen ... no need to duplicate

always_comb
	for (n2 = 0; n2 < 8; n2 = n2 + 1) begin
    iqentry_issue[n2] = (iq[n2].v && !iq[n2].out && !iq[n2].agen
				&& (head0 == n2[2:0] || ~|iqentry_islot[(n2+7)&7] || (iqentry_islot[(n2+7)&7] == 2'b01 && ~iqentry_issue[(n2+7)&7]))
				&& (iq[n2].a1_v 
				    || (iq[n2].a1_s == alu0_sourceid && alu0_dataready)
				    || (iq[n2].a1_s == alu1_sourceid && alu1_dataready))
				&& (iq[n2].a2_v 
				    || (iq[n2].mem & ~iq[n2].agen)
				    || (iq[n2].a2_s == alu0_sourceid && alu0_dataready)
				    || (iq[n2].a2_s == alu1_sourceid && alu1_dataready)));
				    
    iqentry_islot[n2] = (head0 == n2[2:0]) ? 2'b00
				: (iqentry_islot[(n2+7)&7] == 2'b11) ? 2'b11
				: (iqentry_islot[(n2+7)&7] + {1'b0, iqentry_issue[(n2+7)&7]});
	end
    // 
    // additional logic for handling a branch miss (STOMP logic)
    //
    assign
    	iqentry_stomp[0] = branchmiss && iq[0].v && head0 != 3'd0 && (missid == 3'd7 || iqentry_stomp[7]),
	    iqentry_stomp[1] = branchmiss && iq[1].v && head0 != 3'd1 && (missid == 3'd0 || iqentry_stomp[0]),
	    iqentry_stomp[2] = branchmiss && iq[2].v && head0 != 3'd2 && (missid == 3'd1 || iqentry_stomp[1]),
	    iqentry_stomp[3] = branchmiss && iq[3].v && head0 != 3'd3 && (missid == 3'd2 || iqentry_stomp[2]),
	    iqentry_stomp[4] = branchmiss && iq[4].v && head0 != 3'd4 && (missid == 3'd3 || iqentry_stomp[3]),
	    iqentry_stomp[5] = branchmiss && iq[5].v && head0 != 3'd5 && (missid == 3'd4 || iqentry_stomp[4]),
	    iqentry_stomp[6] = branchmiss && iq[6].v && head0 != 3'd6 && (missid == 3'd5 || iqentry_stomp[5]),
	    iqentry_stomp[7] = branchmiss && iq[7].v && head0 != 3'd7 && (missid == 3'd6 || iqentry_stomp[6]);


//
// EXECUTE
//
always_comb
	case(opcode_t'(alu0_instr[5:0]))
	OP_R2A:
		case(alu0_instr.r2.func.r2a)
		FN_ADD:	alu0_bus = alu0_argA + alu0_argB;
		FN_SUB:	alu0_bus = alu0_argA - alu0_argB;
		default:	alu0_bus = 32'hDEADBEEF;
		endcase
	OP_R2L:
		case(alu0_instr.r2.func.r2l)
		FN_AND:	alu0_bus = alu0_argA & alu0_argB;
		FN_OR:	alu0_bus = alu0_argA | alu0_argB;
		FN_EOR:	alu0_bus = alu0_argA ^ alu0_argB;
		FN_ANDN:	alu0_bus = alu0_argA & ~alu0_argB;
		FN_NAND:	alu0_bus = ~(alu0_argA & alu0_argB);
		FN_NOR:	alu0_bus = ~(alu0_argA | alu0_argB);
		FN_ENOR:	alu0_bus = ~(alu0_argA ^ alu0_argB);
		FN_ORN:	alu0_bus = alu0_argA | ~alu0_argB;
		endcase
	OP_R2S:
		case(alu0_instr.r2.func.r2s)
		FN_SEQ:	alu0_bus = alu0_argA == alu0_argB;
		FN_SNE:	alu0_bus = alu0_argA != alu0_argB;
		FN_SLT:	alu0_bus = $signed(alu0_argA) < $signed(alu0_argB);
		FN_SLE:	alu0_bus = $signed(alu0_argA) <= $signed(alu0_argB);
		FN_SLTU:	alu0_bus = alu0_argA < alu0_argB;
		FN_SLEU:	alu0_bus = alu0_argA <= alu0_argB;
		default:	alu0_bus = 32'hDEADBEEF;
		endcase
	OP_ADDI:	alu0_bus = alu0_argA + alu0_argB;
	OP_ANDI:	alu0_bus = alu0_argA & alu0_argB;
	OP_ORI:		alu0_bus = alu0_argA | alu0_argB;
	OP_EORI:	alu0_bus = alu0_argA ^ alu0_argB;
	OP_BEQ:		alu0_bus = alu0_argA == alu0_argB;
	OP_BNE:		alu0_bus = alu0_argA != alu0_argB;
	OP_BLT:		alu0_bus = $signed(alu0_argA) < $signed(alu0_argB);
	OP_BLE:		alu0_bus = $signed(alu0_argA) <= $signed(alu0_argB);
	OP_BLTU:	alu0_bus = alu0_argA < alu0_argB;
	OP_BLEU:	alu0_bus = alu0_argA <= alu0_argB;
	OP_LDB:		alu0_bus = alu0_argA + alu0_argB;
	OP_LDBU:	alu0_bus = alu0_argA + alu0_argB;
	OP_LDW:		alu0_bus = alu0_argA + alu0_argB;
	OP_LDWU:	alu0_bus = alu0_argA + alu0_argB;
	OP_LDT:		alu0_bus = alu0_argA + alu0_argB;
	OP_STB:		alu0_bus = alu0_argA + alu0_argB;
	OP_STW:		alu0_bus = alu0_argA + alu0_argB;
	OP_STT:		alu0_bus = alu0_argA + alu0_argB;
	OP_LDBX:	alu0_bus = alu0_argA + alu0_argB;
	OP_LDBUX:	alu0_bus = alu0_argA + alu0_argB;
	OP_LDWX:	alu0_bus = alu0_argA + alu0_argB;
	OP_LDWUX:	alu0_bus = alu0_argA + alu0_argB;
	OP_LDTX:	alu0_bus = alu0_argA + alu0_argB;
	OP_STBX:	alu0_bus = alu0_argA + alu0_argB;
	OP_STWX:	alu0_bus = alu0_argA + alu0_argB;
	OP_STTX:	alu0_bus = alu0_argA + alu0_argB;
	default:	alu0_bus = 32'hDEADBEEF;
	endcase

always_comb
	case(opcode_t'(alu1_instr[5:0]))
	OP_R2A:
		case(alu1_instr.r2.func.r2a)
		FN_ADD:	alu1_bus = alu1_argA + alu1_argB;
		FN_SUB:	alu1_bus = alu1_argA - alu1_argB;
		default:	alu1_bus = 32'hDEADBEEF;
		endcase
	OP_R2L:
		case(alu1_instr.r2.func.r2l)
		FN_AND:	alu1_bus = alu1_argA & alu1_argB;
		FN_OR:	alu1_bus = alu1_argA | alu1_argB;
		FN_EOR:	alu1_bus = alu1_argA ^ alu1_argB;
		FN_ANDN:	alu1_bus = alu1_argA & ~alu1_argB;
		FN_NAND:	alu1_bus = ~(alu1_argA & alu1_argB);
		FN_NOR:	alu1_bus = ~(alu1_argA | alu1_argB);
		FN_ENOR:	alu1_bus = ~(alu1_argA ^ alu1_argB);
		FN_ORN:	alu1_bus = alu1_argA | ~alu1_argB;
		endcase
	OP_R2S:
		case(alu1_instr.r2.func.r2s)
		FN_SEQ:	alu1_bus = alu1_argA == alu1_argB;
		FN_SNE:	alu1_bus = alu1_argA != alu1_argB;
		FN_SLT:	alu1_bus = $signed(alu1_argA) < $signed(alu1_argB);
		FN_SLE:	alu1_bus = $signed(alu1_argA) <= $signed(alu1_argB);
		FN_SLTU:	alu1_bus = alu1_argA < alu1_argB;
		FN_SLEU:	alu1_bus = alu1_argA <= alu1_argB;
		default:	alu1_bus = 32'hDEADBEEF;
		endcase
	OP_ADDI:	alu1_bus = alu1_argA + alu1_argB;
	OP_ANDI:	alu1_bus = alu1_argA & alu1_argB;
	OP_ORI:		alu1_bus = alu1_argA | alu1_argB;
	OP_EORI:	alu1_bus = alu1_argA ^ alu1_argB;
	OP_BEQ:		alu1_bus = alu1_argA == alu1_argB;
	OP_BNE:		alu1_bus = alu1_argA != alu1_argB;
	OP_BLT:		alu1_bus = $signed(alu1_argA) < $signed(alu1_argB);
	OP_BLE:		alu1_bus = $signed(alu1_argA) <= $signed(alu1_argB);
	OP_BLTU:	alu1_bus = alu1_argA < alu1_argB;
	OP_BLEU:	alu1_bus = alu1_argA <= alu1_argB;
	OP_LDB:		alu1_bus = alu1_argA + alu1_argB;
	OP_LDBU:	alu1_bus = alu1_argA + alu1_argB;
	OP_LDW:		alu1_bus = alu1_argA + alu1_argB;
	OP_LDWU:	alu1_bus = alu1_argA + alu1_argB;
	OP_LDT:		alu1_bus = alu1_argA + alu1_argB;
	OP_STB:		alu1_bus = alu1_argA + alu1_argB;
	OP_STW:		alu1_bus = alu1_argA + alu1_argB;
	OP_STT:		alu1_bus = alu1_argA + alu1_argB;
	OP_LDBX:	alu1_bus = alu1_argA + alu1_argB;
	OP_LDBUX:	alu1_bus = alu1_argA + alu1_argB;
	OP_LDWX:	alu1_bus = alu1_argA + alu1_argB;
	OP_LDWUX:	alu1_bus = alu1_argA + alu1_argB;
	OP_LDTX:	alu1_bus = alu1_argA + alu1_argB;
	OP_STBX:	alu1_bus = alu1_argA + alu1_argB;
	OP_STWX:	alu1_bus = alu1_argA + alu1_argB;
	OP_STTX:	alu1_bus = alu1_argA + alu1_argB;
	default:	alu1_bus = 32'hDEADBEEF;
	endcase

    assign  alu0_v = alu0_dataready,
	    alu1_v = alu1_dataready;

    assign  alu0_id = alu0_sourceid,
	    alu1_id = alu1_sourceid;

always_comb
	if (fnIsBranch(alu0_instr))
		alu0_misspc = alu0_bt ? alu0_pc + fnInsLen(alu0_instr) : alu0_pc + alu0_argI;
	else if (fnIsCall(alu0_instr)) begin
		if (alu0_instr[7:6]==2'd3)
			alu0_misspc = alu0_argI;
		else
			alu0_misspc = alu0_pc + alu0_argI;
	end

always_comb
	if (fnIsBranch(alu1_instr))
		alu1_misspc = alu1_bt ? alu1_pc + fnInsLen(alu1_instr) : alu1_pc + alu1_argI;
	else if (fnIsCall(alu1_instr)) begin
		if (alu1_instr[7:6]==2'd3)
			alu1_misspc = alu1_argI;
		else
			alu1_misspc = alu1_pc + alu1_argI;
	end

always_comb
	case(opcode_t'(alu0_instr[5:0]))
	OP_BEQ:	takb0 = alu0_argA==alu0_argB;
	OP_BNE:	takb0 = alu0_argA!=alu0_argB;
	OP_BLT:	takb0 = $signed(alu0_argA) < $signed(alu0_argB);
	OP_BLE:	takb0 = $signed(alu0_argA) <= $signed(alu0_argB);
	OP_BLTU:	takb0 = alu0_argA < alu0_argB;
	OP_BLEU:	takb0 = alu0_argA <= alu0_argB;
	OP_LBcc,OP_XLBcc:
		case(cond_t'(alu0_instr[18:16]))
		CND_EQ:	takb0 = alu0_argA==alu0_argB;
		CND_NE:	takb0 = alu0_argA!=alu0_argB;
		CND_LT:	takb0 = $signed(alu0_argA) < $signed(alu0_argB);
		CND_LE: takb0 = $signed(alu0_argA) <= $signed(alu0_argB);
		CND_LTU:	takb0 = alu0_argA < alu0_argB;
		CND_LEU:	takb0 = alu0_argA <= alu0_argB;
		default:	takb0 = 1'b0;
		endcase
	default:	takb0 = 1'b0;
	endcase	

always_comb
	case(opcode_t'(alu1_instr[5:0]))
	OP_BEQ:	takb1 = alu1_argA==alu1_argB;
	OP_BNE:	takb1 = alu1_argA!=alu1_argB;
	OP_BLT:	takb1 = $signed(alu1_argA) < $signed(alu1_argB);
	OP_BLE:	takb1 = $signed(alu1_argA) <= $signed(alu1_argB);
	OP_BLTU:	takb1 = alu1_argA < alu1_argB;
	OP_BLEU:	takb1 = alu1_argA <= alu1_argB;
	OP_LBcc,OP_XLBcc:
		case(cond_t'(alu1_instr[18:16]))
		CND_EQ:	takb1 = alu1_argA==alu1_argB;
		CND_NE:	takb1 = alu1_argA!=alu1_argB;
		CND_LT:	takb1 = $signed(alu1_argA) < $signed(alu1_argB);
		CND_LE: takb1 = $signed(alu1_argA) <= $signed(alu1_argB);
		CND_LTU:	takb1 = alu1_argA < alu1_argB;
		CND_LEU:	takb1 = alu1_argA <= alu1_argB;
		default:	takb1 = 1'b0;
		endcase
	default:	takb1 = 1'b0;
	endcase	

    assign  alu0_exc = (alu0_instr != `EXTEND)
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

    assign  alu1_exc = (alu1_instr != `EXTEND)
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
			   (fnIsBranch(alu0_instr) ? ((takb0 && ~alu0_bt) || (!takb0 && alu0_bt))
			  : fnIsCall(alu0_instr));

    assign alu1_branchmiss = alu1_dataready && 
			   (fnIsBranch(alu1_instr)  ? ((takb1 && ~alu1_bt) || (!takb1 && alu1_bt))
			  : fnIsCall(alu1_instr));

    assign  branchmiss = (alu0_branchmiss | alu1_branchmiss),
	    misspc = (alu0_branchmiss ? alu0_misspc : alu1_misspc),
	    missid = (alu0_branchmiss ? alu0_sourceid : alu1_sourceid);

//
// additional DRAM-enqueue logic

assign dram_avail = (dram0 == `DRAMSLOT_AVAIL || dram1 == `DRAMSLOT_AVAIL || dram2 == `DRAMSLOT_AVAIL);

assign
	iqentry_memopsvalid[0] = (iq[0].mem & iq[0].a2_v & iq[0].agen),
  iqentry_memopsvalid[1] = (iq[1].mem & iq[1].a2_v & iq[1].agen),
  iqentry_memopsvalid[2] = (iq[2].mem & iq[2].a2_v & iq[2].agen),
  iqentry_memopsvalid[3] = (iq[3].mem & iq[3].a2_v & iq[3].agen),
  iqentry_memopsvalid[4] = (iq[4].mem & iq[4].a2_v & iq[4].agen),
  iqentry_memopsvalid[5] = (iq[5].mem & iq[5].a2_v & iq[5].agen),
  iqentry_memopsvalid[6] = (iq[6].mem & iq[6].a2_v & iq[6].agen),
  iqentry_memopsvalid[7] = (iq[7].mem & iq[7].a2_v & iq[7].agen);

assign
  iqentry_memready[0] = (iq[0].v & iqentry_memopsvalid[0] & ~iqentry_memissue[0] & ~iq[0].done & ~iq[0].out & ~iqentry_stomp[0]),
  iqentry_memready[1] = (iq[1].v & iqentry_memopsvalid[1] & ~iqentry_memissue[1] & ~iq[1].done & ~iq[1].out & ~iqentry_stomp[1]),
  iqentry_memready[2] = (iq[2].v & iqentry_memopsvalid[2] & ~iqentry_memissue[2] & ~iq[2].done & ~iq[2].out & ~iqentry_stomp[2]),
  iqentry_memready[3] = (iq[3].v & iqentry_memopsvalid[3] & ~iqentry_memissue[3] & ~iq[3].done & ~iq[3].out & ~iqentry_stomp[3]),
  iqentry_memready[4] = (iq[4].v & iqentry_memopsvalid[4] & ~iqentry_memissue[4] & ~iq[4].done & ~iq[4].out & ~iqentry_stomp[4]),
  iqentry_memready[5] = (iq[5].v & iqentry_memopsvalid[5] & ~iqentry_memissue[5] & ~iq[5].done & ~iq[5].out & ~iqentry_stomp[5]),
  iqentry_memready[6] = (iq[6].v & iqentry_memopsvalid[6] & ~iqentry_memissue[6] & ~iq[6].done & ~iq[6].out & ~iqentry_stomp[6]),
  iqentry_memready[7] = (iq[7].v & iqentry_memopsvalid[7] & ~iqentry_memissue[7] & ~iq[7].done & ~iq[7].out & ~iqentry_stomp[7]);

assign outstanding_stores = (dram0 && dram0_store) || (dram1 && dram1_store) || (dram2 && dram2_store);

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
always_ff @(posedge clk) begin

	if (dram0_store || dram1_store || dram2_store)
		icache_ram[icache_uadr] <= icache_udat;


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
    	if (iq[tail0].v == INV) begin
				iq[tail0].v    <=   VAL;
				iq[tail0].done    <=   INV;
				iq[tail0].out    <=   INV;
				iq[tail0].res    <=   `ZERO;
				iq[tail0].op    <=   fetchbuf1_instr[7:0]; 
				iq[tail0].bt    <=   (fnIsBranch(fetchbuf1_instr)	&& fnBranchDispSign(fetchbuf1_instr)); 
				iq[tail0].agen    <=   INV;
				iq[tail0].pc    <=   fetchbuf1_pc;
				iq[tail0].mem    <=   fetchbuf1_mem;
				iq[tail0].load <= fnIsLoad(fetchbuf1_instr);
				iq[tail0].store <= fnIsStore(fetchbuf1_instr);
				iq[tail0].jmp    <=   fetchbuf1_jmp;
				iq[tail0].rfw    <=   fetchbuf1_rfw;
				case(opcode_t'(fetchbuf1_instr[5:0]))
				OP_CALL,OP_LCALL,OP_XLCALL:
					iq[tail0].tgt <= {3'd0,fetchbuf1_instr[7:6]};   
				default:
					iq[tail0].tgt <= fetchbuf1_rfw ? Rt1 : 'd0;
				endcase
				iq[tail0].exc <= `EXC_NONE;
				iq[tail0].a0 <= fetchbuf1_imm;
				iq[tail0].a1 <= rf [ Ra1 ];
				iq[tail0].a1_v <= fnSource1v(fetchbuf1_instr) | rf_v[ Ra1 ];
				iq[tail0].a1_s <= rf_source [ Ra1 ];
				iq[tail0].a2 <= fnA2(fetchbuf1_rfw, fetchbuf1_instr, fetchbuf1_pc, Rb1);
				iq[tail0].a2_v <= fnSource2v(fetchbuf1_instr) | rf_v[ Rb1 ];
				iq[tail0].a2_s  <= rf_source [ Rb1 ];
	    end

    2'b10:
    	if (iq[tail0].v == INV) begin
				if (!fnIsBranch(fetchbuf0_instr))		panic <= `PANIC_FETCHBUFBEQ;
				if (!fnIsBackBranch(fetchbuf0_instr))	panic <= `PANIC_FETCHBUFBEQ;
				//
				// this should only happen when the first instruction is a BEQ-backwards and the IQ
				// happened to be full on the previous cycle (thus we deleted fetchbuf1 but did not
				// enqueue fetchbuf0) ... probably no need to check for LW -- sanity check, just in case
				//
				iq[tail0].v	<=	VAL;
				iq[tail0].done <= INV;
				iq[tail0].out	<= INV;
				iq[tail0].res	<= `ZERO;
				iq[tail0].op <= fetchbuf0_instr[7:0]; 			// BEQ
				iq[tail0].bt <= VAL;
				iq[tail0].agen <= INV;
				iq[tail0].pc <= fetchbuf0_pc;
				iq[tail0].mem <= fetchbuf0_mem;
				iq[tail0].load <= fnIsLoad(fetchbuf0_instr);
				iq[tail0].store <= fnIsStore(fetchbuf0_instr);
				iq[tail0].jmp <= fetchbuf0_jmp;
				iq[tail0].rfw <= fetchbuf0_rfw;
				case(opcode_t'(fetchbuf0_instr[5:0]))
				OP_CALL,OP_LCALL,OP_XLCALL:
					iq[tail0].tgt <= {3'd0,fetchbuf0_instr[7:6]};   
				default:
					iq[tail0].tgt <= fetchbuf0_rfw ? Rt0 : 'd0;
				endcase
				iq[tail0].exc    <=	`EXC_NONE;
				iq[tail0].a0	<=	fetchbuf0_imm;
				iq[tail0].a1 <= rf [ Ra0 ];
				iq[tail0].a1_v <= fnSource1v(fetchbuf0_instr) | rf_v[ Ra0 ];
				iq[tail0].a1_s <= rf_source [ Ra0 ];
				iq[tail0].a2 <= fnA2(fetchbuf0_rfw, fetchbuf0_instr, fetchbuf0_pc, Rb0);
				iq[tail0].a2_v <= fnSource2v(fetchbuf0_instr) | rf_v[ Rb0 ];
				iq[tail0].a2_s  <= rf_source [ Rb0 ];
	    end

    2'b11:
    	if (iq[tail0].v == INV) begin

				//
				// if the first instruction is a backwards branch, enqueue it & stomp on all following instructions
				//
				if (fnIsBackBranch(fetchbuf0_instr)) begin
			    iq[tail0].v    <=	VAL;
			    iq[tail0].done    <=	INV;
			    iq[tail0].out    <=	INV;
			    iq[tail0].res    <=	`ZERO;
			    iq[tail0].op    <=	fetchbuf0_instr[7:0]; 			// BEQ
			    iq[tail0].bt    <=	VAL;
			    iq[tail0].agen    <=	INV;
			    iq[tail0].pc    <=	fetchbuf0_pc;
			    iq[tail0].mem    <=	fetchbuf0_mem;
					iq[tail0].load <= fnIsLoad(fetchbuf0_instr);
					iq[tail0].store <= fnIsStore(fetchbuf0_instr);
			    iq[tail0].jmp    <=	fetchbuf0_jmp;
			    iq[tail0].rfw    <=	fetchbuf0_rfw;
					case(opcode_t'(fetchbuf0_instr[5:0]))
					OP_CALL,OP_LCALL,OP_XLCALL:
						iq[tail0].tgt <= {3'd0,fetchbuf0_instr[7:6]};   
					default:
						iq[tail0].tgt <= fetchbuf0_rfw ? Rt0 : 'd0;
					endcase
			    iq[tail0].exc    <=	`EXC_NONE;
			    iq[tail0].a0    <=	fetchbuf0_imm;
					iq[tail0].a1 <= rf [ Ra0 ];
					iq[tail0].a1_v <= fnSource1v(fetchbuf0_instr) | rf_v[ Ra0 ];
					iq[tail0].a1_s <= rf_source [ Ra0 ];
					iq[tail0].a2 <= fnA2(fetchbuf0_rfw, fetchbuf0_instr, fetchbuf0_pc, Rb0);
					iq[tail0].a2_v <= fnSource2v(fetchbuf0_instr) | rf_v[ Rb0 ];
					iq[tail0].a2_s  <= rf_source [ Rb0 ];
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

			    //
			    // enqueue the first instruction ...
			    //
			    iq[tail0].v    <=   VAL;
			    iq[tail0].done    <=   INV;
			    iq[tail0].out    <=   INV;
			    iq[tail0].res    <=   `ZERO;
			    iq[tail0].op    <=   fetchbuf0_instr[7:0]; 
			    iq[tail0].bt    <=   INV;
			    iq[tail0].agen    <=   INV;
			    iq[tail0].pc    <=   fetchbuf0_pc;
			    iq[tail0].mem    <=   fetchbuf0_mem;
					iq[tail0].load <= fnIsLoad(fetchbuf0_instr);
					iq[tail0].store <= fnIsStore(fetchbuf0_instr);
			    iq[tail0].jmp    <=   fetchbuf0_jmp;
			    iq[tail0].rfw    <=   fetchbuf0_rfw;
					case(opcode_t'(fetchbuf0_instr[5:0]))
					OP_CALL,OP_LCALL,OP_XLCALL:
						iq[tail0].tgt <= {3'd0,fetchbuf0_instr[7:6]};   
					default:
						iq[tail0].tgt <= fetchbuf0_rfw ? Rt0 : 'd0;
					endcase
			    iq[tail0].exc    <=   `EXC_NONE;
			    iq[tail0].a0    <=   fetchbuf0_imm;
					iq[tail0].a1 <= rf [ Ra0];
					iq[tail0].a1_v <= fnSource1v(fetchbuf0_instr) | rf_v[ Ra0 ];
					iq[tail0].a1_s <= rf_source [ Ra0 ];
					iq[tail0].a2 <= fnA2(fetchbuf0_rfw, fetchbuf0_instr, fetchbuf0_pc, Rb0);
					iq[tail0].a2_v <= fnSource2v(fetchbuf0_instr) | rf_v[ Rb0 ];
					iq[tail0].a2_s <= rf_source [ Rb0 ];

			    //
			    // if there is room for a second instruction, enqueue it
			    //
			    if (iq[tail1].v == INV) begin

						iq[tail1].v    <=   VAL;
						iq[tail1].done    <=   INV;
						iq[tail1].out    <=   INV;
						iq[tail1].res    <=   `ZERO;
						iq[tail1].op    <=   fetchbuf1_instr[7:0]; 
						iq[tail1].bt    <=   (fnIsBackBranch(fetchbuf1_instr)); 
						iq[tail1].agen    <=   INV;
						iq[tail1].pc    <=   fetchbuf1_pc;
						iq[tail1].mem    <=   fetchbuf1_mem;
						iq[tail1].load <= fnIsLoad(fetchbuf1_instr);
						iq[tail1].store <= fnIsStore(fetchbuf1_instr);
						iq[tail1].jmp    <=   fetchbuf1_jmp;
						iq[tail1].rfw    <=   fetchbuf1_rfw;
						case(opcode_t'(fetchbuf1_instr[5:0]))
						OP_CALL,OP_LCALL,OP_XLCALL:
							iq[tail1].tgt <= {3'd0,fetchbuf1_instr[7:6]};   
						default:
							iq[tail1].tgt <= fetchbuf1_rfw ? Rt1 : 'd0;
						endcase
						iq[tail1].exc <= `EXC_NONE;
						iq[tail1].a0 <= fetchbuf1_imm;
						iq[tail1].a1 <= rf [ Ra1 ];
						iq[tail1].a2 <= fnA2(fetchbuf1_rfw, fetchbuf1_instr, fetchbuf1_pc, Rb1);

						// a1/a2_v and a1/a2_s values require a bit of thinking ...

						//
						// SOURCE 1 ... this is relatively straightforward, because all instructions
						// that have a source (i.e. every instruction but LUI) read from RB
						//
						// if the argument is an immediate or not needed, we're done
						if (fnSource1v(fetchbuf1_instr)) begin
					    iq[tail1].a1_v <= VAL;
					    iq[tail1].a1_s <= 'd0;
						end
						// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
						else if (~fetchbuf0_rfw) begin
					    iq[tail1].a1_v <= rf_v [ Ra1 ];
					    iq[tail1].a1_s <= rf_source [ Ra1 ];
						end
						// otherwise, previous instruction does write to RF ... see if overlap
						else if (Rt0 != 'd0 && Ra1 == Rt0) begin
					    // if the previous instruction is a LW, then grab result from memq, not the iq
					    iq[tail1].a1_v <= INV;
					    iq[tail1].a1_s <= { fetchbuf0_mem, tail0 };
						end
						// if no overlap, get info from rf_v and rf_source
						else begin
					    iq[tail1].a1_v <= rf_v [ Ra1 ];
					    iq[tail1].a1_s <= rf_source [ Ra1 ];
						end

						//
						// SOURCE 2 ... this is more contorted than the logic for SOURCE 1 because
						// some instructions (NAND and ADD) read from RC and others (SW, BEQ) read from RA
						//
						// if the argument is an immediate or not needed, we're done
						if (fnSource2v(fetchbuf1_instr)) begin
					    iq[tail1].a2_v <= VAL;
					    iq[tail1].a2_s <= 'd0;
						end
						// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
						else if (~fetchbuf0_rfw) begin
					    iq[tail1].a2_v <= rf_v [ Rb1 ];
					    iq[tail1].a2_s <= rf_source [ Rb1 ];
						end
						// otherwise, previous instruction does write to RF ... see if overlap
						else if (Rt0 != 5'd0 && Rb1 == Rt0) begin
					    // if the previous instruction is a LW, then grab result from memq, not the iq
					    iq[tail1].a2_v <= INV;
					    iq[tail1].a2_s <= { fetchbuf0_mem, tail0 };
						end
						// if no overlap, get info from rf_v and rf_source
						else begin
					    iq[tail1].a2_v <= rf_v [ Rb1 ];
					    iq[tail1].a2_s <= rf_source [ Rb1 ];
						end
					end	// ends the "else fetchbuf0 doesn't have a backwards branch" clause
	    	end
	    end
		endcase
//
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
    iq[ alu0_id[2:0] ].res <= alu0_bus;
    iq[ alu0_id[2:0] ].exc <= alu0_exc;
    iq[ alu0_id[2:0] ].done <= (!iq[ alu0_id[2:0] ].load && !iq[ alu0_id[2:0] ].store);
    iq[ alu0_id[2:0] ].out <= INV;
    iq[ alu0_id[2:0] ].agen <= VAL;
	end
	if (alu1_v) begin
    iq[ alu1_id[2:0] ].res <= alu1_bus;
    iq[ alu1_id[2:0] ].exc <= alu1_exc;
    iq[ alu1_id[2:0] ].done <= (!iq[ alu1_id[2:0] ].load && !iq[ alu1_id[2:0] ].store);
    iq[ alu1_id[2:0] ].out <= INV;
    iq[ alu1_id[2:0] ].agen <= VAL;
	end
	if (dram_v && iq[ dram_id[2:0] ].v && iq[ dram_id[2:0] ].mem ) begin	// if data for stomped instruction, ignore
    iq[ dram_id[2:0] ].res <= dram_bus;
    iq[ dram_id[2:0] ].exc <= dram_exc;
    iq[ dram_id[2:0] ].done <= VAL;
	end

	//
	// set the IQ entry == DONE as soon as the SW is let loose to the memory system
	//
	if (dram0 == 2'd1 && dram0_store) begin
    if ((alu0_v && dram0_id[2:0] == alu0_id[2:0]) || (alu1_v && dram0_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
    iq[ dram0_id[2:0] ].done <= VAL;
    iq[ dram0_id[2:0] ].out <= INV;
	end
	if (dram1 == 2'd1 && fnIsStore(dram1_op)) begin
    if ((alu0_v && dram1_id[2:0] == alu0_id[2:0]) || (alu1_v && dram1_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
    iq[ dram1_id[2:0] ].done <= VAL;
    iq[ dram1_id[2:0] ].out <= INV;
	end
	if (dram2 == 2'd1 && fnIsStore(dram2_op)) begin
    if ((alu0_v && dram2_id[2:0] == alu0_id[2:0]) || (alu1_v && dram2_id[2:0] == alu1_id[2:0]))	panic <= `PANIC_MEMORYRACE;
    iq[ dram2_id[2:0] ].done <= VAL;
    iq[ dram2_id[2:0] ].out <= INV;
	end

	//
	// see if anybody else wants the results ... look at lots of buses:
	//  - alu0_bus
	//  - alu1_bus
	//  - dram_bus
	//  - commit0_bus
	//  - commit1_bus
	//

	for (nn = 0; nn < 8; nn = nn + 1) begin
		if (iq[nn].a1_v == INV && iq[nn].a1_s == alu0_id && iq[nn].v == VAL && alu0_v == VAL) begin
	    iq[nn].a1 <= alu0_bus;
	    iq[nn].a1_v <= VAL;
		end
		if (iq[nn].a2_v == INV && iq[nn].a2_s == alu0_id && iq[nn].v == VAL && alu0_v == VAL) begin
	    iq[nn].a2 <= alu0_bus;
	    iq[nn].a2_v <= VAL;
		end
		if (iq[nn].a1_v == INV && iq[nn].a1_s == alu1_id && iq[nn].v == VAL && alu1_v == VAL) begin
	    iq[nn].a1 <= alu1_bus;
	    iq[nn].a1_v <= VAL;
		end
		if (iq[nn].a2_v == INV && iq[nn].a2_s == alu1_id && iq[nn].v == VAL && alu1_v == VAL) begin
	    iq[nn].a2 <= alu1_bus;
	    iq[nn].a2_v <= VAL;
		end
		if (iq[nn].a1_v == INV && iq[nn].a1_s == dram_id && iq[nn].v == VAL && dram_v == VAL) begin
	    iq[nn].a1 <= dram_bus;
	    iq[nn].a1_v <= VAL;
		end
		if (iq[nn].a2_v == INV && iq[nn].a2_s == dram_id && iq[nn].v == VAL && dram_v == VAL) begin
	    iq[nn].a2 <= dram_bus;
	    iq[nn].a2_v <= VAL;
		end
		if (iq[nn].a1_v == INV && iq[nn].a1_s == commit0_id && iq[nn].v == VAL && commit0_v == VAL) begin
	    iq[nn].a1 <= commit0_bus;
	    iq[nn].a1_v <= VAL;
		end
		if (iq[nn].a2_v == INV && iq[nn].a2_s == commit0_id && iq[nn].v == VAL && commit0_v == VAL) begin
	    iq[nn].a2 <= commit0_bus;
	    iq[nn].a2_v <= VAL;
		end
		if (iq[nn].a1_v == INV && iq[nn].a1_s == commit1_id && iq[nn].v == VAL && commit1_v == VAL) begin
	    iq[nn].a1 <= commit1_bus;
	    iq[nn].a1_v <= VAL;
		end
		if (iq[nn].a2_v == INV && iq[nn].a2_s == commit1_id && iq[nn].v == VAL && commit1_v == VAL) begin
	    iq[nn].a2 <= commit1_bus;
	    iq[nn].a2_v <= VAL;
		end
	end

//
// ISSUE 
//
// determines what instructions are ready to go, then places them
// in the various ALU queues.  
// also invalidates instructions following a branch-miss BEQ or any JALR (STOMP logic)
//

alu0_dataready <= alu0_available 
		&& ((iqentry_issue[0] && iqentry_islot[0] == 2'd0 && !iqentry_stomp[0])
		 || (iqentry_issue[1] && iqentry_islot[1] == 2'd0 && !iqentry_stomp[1])
		 || (iqentry_issue[2] && iqentry_islot[2] == 2'd0 && !iqentry_stomp[2])
		 || (iqentry_issue[3] && iqentry_islot[3] == 2'd0 && !iqentry_stomp[3])
		 || (iqentry_issue[4] && iqentry_islot[4] == 2'd0 && !iqentry_stomp[4])
		 || (iqentry_issue[5] && iqentry_islot[5] == 2'd0 && !iqentry_stomp[5])
		 || (iqentry_issue[6] && iqentry_islot[6] == 2'd0 && !iqentry_stomp[6])
		 || (iqentry_issue[7] && iqentry_islot[7] == 2'd0 && !iqentry_stomp[7]));

alu1_dataready <= alu1_available 
		&& ((iqentry_issue[0] && iqentry_islot[0] == 2'd1 && !iqentry_stomp[0])
		 || (iqentry_issue[1] && iqentry_islot[1] == 2'd1 && !iqentry_stomp[1])
		 || (iqentry_issue[2] && iqentry_islot[2] == 2'd1 && !iqentry_stomp[2])
		 || (iqentry_issue[3] && iqentry_islot[3] == 2'd1 && !iqentry_stomp[3])
		 || (iqentry_issue[4] && iqentry_islot[4] == 2'd1 && !iqentry_stomp[4])
		 || (iqentry_issue[5] && iqentry_islot[5] == 2'd1 && !iqentry_stomp[5])
		 || (iqentry_issue[6] && iqentry_islot[6] == 2'd1 && !iqentry_stomp[6])
		 || (iqentry_issue[7] && iqentry_islot[7] == 2'd1 && !iqentry_stomp[7]));

	for (n1 = 0; n1 < 8; n1 = n1 + 1) begin
		if (iq[n1].v && iqentry_stomp[n1]) begin
	    iq[n1].v <= INV;
	    if (dram0_id[2:0] == n1[2:0])	dram0 <= `DRAMSLOT_AVAIL;
	    if (dram1_id[2:0] == n1[2:0])	dram1 <= `DRAMSLOT_AVAIL;
	    if (dram2_id[2:0] == n1[2:0])	dram2 <= `DRAMSLOT_AVAIL;
		end
		else if (iqentry_issue[n1]) begin
	    case (iqentry_islot[n1]) 
			2'd0: 
				if (alu0_available) begin
					alu0_sourceid	<= 4'd0;
					alu0_instr		<= iq[n1].op;
					alu0_bt		<= iq[n1].bt;
					alu0_pc		<= iq[n1].pc;
					alu0_argA	<= 
									iq[n1].a0[1:0]==2'b00 ? iq[n1].a0[33:2]
									: iq[n1].a1_v ? iq[n1].a1
							    : (iq[n1].a1_s == alu0_id) ? alu0_bus
							    : (iq[n1].a1_s == alu1_id) ? alu1_bus
							    : 32'hDEADBEEF;
					alu0_argB	<= 
									iq[n1].a0[1:0]==2'b01 ? iq[n1].a0[33:2]
							    : (iq[n1].a2_v ? iq[n1].a2
									: (iq[n1].a2_s == alu0_id) ? alu0_bus
									: (iq[n1].a2_s == alu1_id) ? alu1_bus
									: 32'hDEADBEEF);
					alu0_argI	<= iq[n1].a0[33:2];
		    end
			2'd1:
				if (alu1_available) begin
					alu1_sourceid	<= 4'd0;
					alu1_instr		<= iq[n1].op;
					alu1_bt		<= iq[n1].bt;
					alu1_pc		<= iq[n1].pc;
					alu1_argA	<= 
									iq[n1].a0[1:0]==2'b00 ? iq[n1].a0[33:2]
									: iq[n1].a1_v ? iq[n1].a1
							    : (iq[n1].a1_s == alu0_id) ? alu0_bus
							    : (iq[n1].a1_s == alu1_id) ? alu1_bus
							    : 32'hDEADBEEF;
					alu1_argB	<= 
									iq[n1].a0[1:0]==2'b01 ? iq[n1].a0[33:2]
							    : (iq[n1].a2_v ? iq[n1].a2
									: (iq[n1].a2_s == alu0_id) ? alu0_bus
									: (iq[n1].a2_s == alu1_id) ? alu1_bus
									: 32'hDEADBEEF);
					alu1_argI	<= iq[n1].a0[33:2];
		    end
			default: panic <= `PANIC_INVALIDISLOT;
	    endcase
	    iq[n1].out <= VAL;
	    // if it is a memory operation, this is the address-generation step ... collect result into arg1
	    if (iq[n1].mem) begin
				iq[n1].a1_v <= INV;
				iq[n1].a1_s <= 4'd0;
	    end
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

	case(dram0)
	`DRAMSLOT_AVAIL:	;
	`DRAMREQ_READY:
		if (dram0_ack)
			dram0 <= dram0 + 2'd1;
	default:
		dram0 <= dram0 + 2'd1;
	endcase

	case(dram1)
	`DRAMSLOT_AVAIL:	;
	`DRAMREQ_READY:
		if (dram1_ack)
			dram1 <= dram1 + 2'd1;
	default:
		dram1 <= dram1 + 2'd1;
	endcase

	case(dram2)
	`DRAMSLOT_AVAIL:	;
	`DRAMREQ_READY:
		if (dram2_ack)
			dram2 <= dram2 + 2'd1;
	default:
		dram2 <= dram2 + 2'd1;
	endcase

	casex ({dram0, dram1, dram2})
	    // not particularly portable ...
	    6'b1111xx,
	    6'b11xx11,
	    6'bxx1111:	;//panic <= `PANIC_IDENTICALDRAMS;

	    default: begin
		//
		// grab requests that have finished and put them on the dram_bus
		if (dram0 == `DRAMREQ_READY && dram0_ack) begin
		    dram_v <= dram0_load;
		    dram_id <= dram0_id;
		    dram_tgt <= dram0_tgt;
		    dram_exc <= dram0_exc;
		    if (dram0_load)
		    	casez(dram0_addr)
		    	32'hFFD?????:	
		    		begin
		    			adr_o <= dram0_addr;
		    			dram_bus <= dat_i;
		    		end
		    	default: dram_bus <= icache_odat0;	
		    	endcase
		    else if (dram0_store)
		    	casez(dram0_addr)
		    	32'hFFD?????:
		    		begin
		    			wr_o <= 1'b1;
		    			adr_o <= dram0_addr;
		    			dat_o <= dram0_data;
		    		end
		    	default:	;
		    	endcase
		    else			panic <= `PANIC_INVALIDMEMOP;
		    if (dram0_store)
		    	$display("m[%h] <- %h", dram0_addr, dram0_data);
		end
		else if (dram1 == `DRAMREQ_READY && dram1_ack) begin
		    dram_v <= (dram1_load);
		    dram_id <= dram1_id;
		    dram_tgt <= dram1_tgt;
		    dram_exc <= dram1_exc;
		    if (dram1_load) 	
		    	casez(dram1_addr)
		    	32'hFFD?????:	
		    		begin
		    			adr_o <= dram1_addr;
		    			dram_bus <= dat_i;
		    		end
		    	default: dram_bus <= icache_odat1;	
		    	endcase
		    else if (dram1_store)
		    	casez(dram1_addr)
		    	32'hFFD?????:
		    		begin
		    			wr_o <= 1'b1;
		    			adr_o <= dram1_addr;
		    			dat_o <= dram1_data;
		    		end
		    	default:	;
		    	endcase
		    else			panic <= `PANIC_INVALIDMEMOP;
		    if (dram1_store)
		     	$display("m[%h] <- %h", dram1_addr, dram1_data);
		end
		else if (dram2 == `DRAMREQ_READY && dram2_ack) begin
		    dram_v <= (dram2_load);
		    dram_id <= dram2_id;
		    dram_tgt <= dram2_tgt;
		    dram_exc <= dram2_exc;
		    if (dram2_load) 	
		    	casez(dram2_addr)
		    	32'hFFD?????:	
		    		begin
		    			adr_o <= dram2_addr;
		    			dram_bus <= dat_i;
		    		end
		    	default: dram_bus <= icache_odat2;	
		    	endcase
		    else if (dram2_store)
		    	casez(dram2_addr)
		    	32'hFFD?????:
		    		begin
		    			wr_o <= 1'b1;
		    			adr_o <= dram2_addr;
		    			dat_o <= dram2_data;
		    		end
		    	default:	;
		    	endcase
		    else			panic <= `PANIC_INVALIDMEMOP;
		    if (dram2_store)
		     	$display("m[%h] <- %h", dram2_addr, dram2_data);
		end
		else begin
		    dram_v <= INV;
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
					&& (!iq[head0].mem || (iq[head0].agen & iq[head0].out) 
						|| (iq[head0].a1_v && iq[head1].a1 != iq[head0].a1))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iq[head1].load || (!fnIsFlowCtrl(iq[head0].op)));

	iqentry_memissue[ head2 ] <=	~iqentry_stomp[head2] && iqentry_memready[ head2 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq[head0].mem || (iq[head0].agen & iq[head0].out) 
						|| (iq[head0].a1_v && iq[head2].a1 != iq[head0].a1))
					&& (!iq[head1].mem || (iq[head1].agen & iq[head1].out) 
						|| (iq[head1].a1_v && iq[head2].a1 != iq[head1].a1))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iq[head2].load ||
					    ( !fnIsFlowCtrl(iq[head0].op) && !fnIsFlowCtrl(iq[head1].op)));

	iqentry_memissue[ head3 ] <=	~iqentry_stomp[head3] && iqentry_memready[ head3 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					&& ~iqentry_memready[head2] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq[head0].mem || (iq[head0].agen & iq[head0].out) 
						|| (iq[head0].a1_v && iq[head3].a1 != iq[head0].a1))
					&& (!iq[head1].mem || (iq[head1].agen & iq[head1].out) 
						|| (iq[head1].a1_v && iq[head3].a1 != iq[head1].a1))
					&& (!iq[head2].mem || (iq[head2].agen & iq[head2].out) 
						|| (iq[head2].a1_v && iq[head3].a1 != iq[head2].a1))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iq[head3].load ||
					    ( !fnIsFlowCtrl(iq[head0].op) &&
					      !fnIsFlowCtrl(iq[head1].op) &&
					      !fnIsFlowCtrl(iq[head2].op)));

	iqentry_memissue[ head4 ] <=	~iqentry_stomp[head4] && iqentry_memready[ head4 ]		// addr and data are valid
					// ... and no preceding instruction is ready to go
					&& ~iqentry_memready[head0]
					&& ~iqentry_memready[head1] 
					&& ~iqentry_memready[head2] 
					&& ~iqentry_memready[head3] 
					// ... and there is no address-overlap with any preceding instruction
					&& (!iq[head0].mem || (iq[head0].agen & iq[head0].out) 
						|| (iq[head0].a1_v && iq[head4].a1 != iq[head0].a1))
					&& (!iq[head1].mem || (iq[head1].agen & iq[head1].out) 
						|| (iq[head1].a1_v && iq[head4].a1 != iq[head1].a1))
					&& (!iq[head2].mem || (iq[head2].agen & iq[head2].out) 
						|| (iq[head2].a1_v && iq[head4].a1 != iq[head2].a1))
					&& (!iq[head3].mem || (iq[head3].agen & iq[head3].out) 
						|| (iq[head3].a1_v && iq[head4].a1 != iq[head3].a1))
					// ... and, if it is a SW, there is no chance of it being undone
					&& (iq[head4].load ||
					    ( !fnIsFlowCtrl(iq[head0].op) &&
					    	!fnIsFlowCtrl(iq[head1].op) &&
					    	!fnIsFlowCtrl(iq[head2].op) &&
					    	!fnIsFlowCtrl(iq[head3].op)));

	iqentry_memissue [head5] <= 1'b0;
	iqentry_memissue [head6] <= 1'b0;
	iqentry_memissue [head7] <= 1'b0;
/*
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
*/
	//
	// take requests that are ready and put them into DRAM slots

	if (dram0 == `DRAMSLOT_AVAIL)	dram0_exc <= `EXC_NONE;
	if (dram1 == `DRAMSLOT_AVAIL)	dram1_exc <= `EXC_NONE;
	if (dram2 == `DRAMSLOT_AVAIL)	dram2_exc <= `EXC_NONE;

	for (n3 = 0; n3 < 8; n3 = n3 + 1) begin
		if (~iqentry_stomp[n3] && iqentry_memissue[n3] && iq[n3].agen && ~iq[n3].out) begin
	    if (dram0 == `DRAMSLOT_AVAIL) begin
				dram0 		<= 2'd1;
				dram0_id 	<= { 1'b1, n3[2:0] };
				dram0_op 	<= iq[n3].op;
				dram0_load <= iq[n3].load;
				dram0_store <= iq[n3].store;
				dram0_tgt 	<= iq[n3].tgt;
				dram0_data	<= iq[n3].a2;
				dram0_addr	<= iq[n3].a1;
				iq[n3].out	<= VAL;
	    end
	    else if (dram1 == `DRAMSLOT_AVAIL) begin
				dram1 		<= 2'd1;
				dram1_id 	<= { 1'b1, n3[2:0] };
				dram1_op 	<= iq[n3].op;
				dram1_load <= iq[n3].load;
				dram1_store <= iq[n3].store;
				dram1_tgt 	<= iq[n3].tgt;
				dram1_data	<= iq[n3].a2;
				dram1_addr	<= iq[n3].a1;
				iq[n3].out	<= VAL;
	    end
	    else if (dram2 == `DRAMSLOT_AVAIL) begin
				dram2 		<= 2'd1;
				dram2_id 	<= { 1'b1, n3[2:0] };
				dram2_op 	<= iq[n3].op;
				dram2_load <= iq[n3].load;
				dram2_store <= iq[n3].store;
				dram2_tgt 	<= iq[n3].tgt;
				dram2_data	<= iq[n3].a2;
				dram2_addr	<= iq[n3].a1;
				iq[n3].out	<= VAL;
	    end
		end
	end

//
// COMMIT PHASE (dequeue only ... not register-file update)
//
// look at head0 and head1 and let 'em write to the register file if they are ready
//
	if (~|panic)
	case ({ iq[head0].v,
		iq[head0].done,
		iq[head1].v,
		iq[head1].done })

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
		if (iq[head0].v || head0 != tail0) begin
		    iq[head0].v <= INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
		    head0 <= head0 + 1;
		    head1 <= head1 + 1;
		    head2 <= head2 + 1;
		    head3 <= head3 + 1;
		    head4 <= head4 + 1;
		    head5 <= head5 + 1;
		    head6 <= head6 + 1;
		    head7 <= head7 + 1;
		    if (iq[head0].v && iq[head0].exc)	panic <= `PANIC_HALTINSTRUCTION;
		    I <= I + 1;
		end
	    end

	    //
	    // retire 2
	    default: begin
		if ((iq[head0].v && iq[head1].v) || (head0 != tail0 && head1 != tail0)) begin
		    iq[head0].v <= INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
		    iq[head1].v <= INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
		    head0 <= head0 + 2;
		    head1 <= head1 + 2;
		    head2 <= head2 + 2;
		    head3 <= head3 + 2;
		    head4 <= head4 + 2;
		    head5 <= head5 + 2;
		    head6 <= head6 + 2;
		    head7 <= head7 + 2;
		    if (iq[head0].v && iq[head0].exc)	panic <= `PANIC_HALTINSTRUCTION;
		    if (iq[head1].v && iq[head1].exc)	panic <= `PANIC_HALTINSTRUCTION;
		    I <= I + 2;
		end
		else if (iq[head0].v || head0 != tail0) begin
		    iq[head0].v <= INV;	// may conflict with STOMP, but since both are setting to 0, it is okay
		    head0 <= head0 + 1;
		    head1 <= head1 + 1;
		    head2 <= head2 + 1;
		    head3 <= head3 + 1;
		    head4 <= head4 + 1;
		    head5 <= head5 + 1;
		    head6 <= head6 + 1;
		    head7 <= head7 + 1;
		    if (iq[head0].v && iq[head0].exc)	panic <= `PANIC_HALTINSTRUCTION;
		    I <= I + 1;
		end
	    end
	endcase

    end

//
// additional COMMIT logic
//

assign commit0_v = ({iq[head0].v, iq[head0].done} == 2'b11 && ~|panic);
assign commit1_v = (   {iq[head0].v, iq[head0].done} != 2'b10 
	&& {iq[head1].v, iq[head1].done} == 2'b11 && ~|panic);

assign commit0_id = {iq[head0].mem, head0};	// if a memory op, it has a DRAM-bus id
assign commit1_id = {iq[head1].mem, head1};	// if a memory op, it has a DRAM-bus id

assign commit0_tgt = iq[head0].tgt;
assign commit1_tgt = iq[head1].tgt;

assign commit0_bus = iq[head0].res;
assign commit1_bus = iq[head1].res;


always_ff @(posedge clk) begin: clock_n_debug
	reg [3:0] i;
	integer j;

	$display("\n\n\n\n\n\n\n\n");
	$display("TIME %0d", $time);
	$display("%h #", pc);

	for (i=0; i<8; i=i+1)
	    $display("%d: %h %d %o #", i, rf[i], rf_v[i], rf_source[i]);

	$display("%d %h #", branchback, backpc);
	$display("%c%c A: %d %h %h #",
	    45, fetchbuf?45:62, uif1.fetchbufA_v, uif1.fetchbufA_instr, uif1.fetchbufA_pc);
	$display("%c%c B: %d %h %h #",
	    45, fetchbuf?45:62, uif1.fetchbufB_v, uif1.fetchbufB_instr, uif1.fetchbufB_pc);
	$display("%c%c C: %d %h %h #",
	    45, fetchbuf?62:45, uif1.fetchbufC_v, uif1.fetchbufC_instr, uif1.fetchbufC_pc);
	$display("%c%c D: %d %h %h #",
	    45, fetchbuf?62:45, uif1.fetchbufD_v, uif1.fetchbufD_instr, uif1.fetchbufD_pc);

	for (i=0; i<8; i=i+1) 
	    $display("%c%c %d: %d %d %d %d %d %d %d %d %d %c%d 0%d %o %h %h %h %d %o %h %d %o %h #",
		(i[2:0]==head0)?72:46, (i[2:0]==tail0)?84:46, i,
		iq[i].v, iq[i].done, iq[i].out, iq[i].bt, iqentry_memissue[i], iq[i].agen, iqentry_issue[i],
		((i==0) ? iqentry_islot[0] : (i==1) ? iqentry_islot[1] : (i==2) ? iqentry_islot[2] : (i==3) ? iqentry_islot[3] :
		 (i==4) ? iqentry_islot[4] : (i==5) ? iqentry_islot[5] : (i==6) ? iqentry_islot[6] : iqentry_islot[7]), iqentry_stomp[i],
		(fnIsFlowCtrl(iq[i].op) ? 98 : (iq[i].load || iq[i].store) ? 109 : 97), 
		iq[i].op, iq[i].tgt, iq[i].exc, iq[i].res, iq[i].a0, iq[i].a1, iq[i].a1_v,
		iq[i].a1_s, iq[i].a2, iq[i].a2_v, iq[i].a2_s, iq[i].pc);

	$display("%d %h %h %c%d %o #",
	    dram0, dram0_addr, dram0_data, (fnIsFlowCtrl(dram0_op) ? 98 : (dram0_load || dram0_store) ? 109 : 97), 
	    dram0_op, dram0_id);
	$display("%d %h %h %c%d %o #",
	    dram1, dram1_addr, dram1_data, (fnIsFlowCtrl(dram1_op) ? 98 : (dram1_load || dram1_store) ? 109 : 97), 
	    dram1_op, dram1_id);
	$display("%d %h %h %c%d %o #",
	    dram2, dram2_addr, dram2_data, (fnIsFlowCtrl(dram2_op) ? 98 : (dram2_load || dram2_store) ? 109 : 97), 
	    dram2_op, dram2_id);
	$display("%d %h %o %h #", dram_v, dram_bus, dram_id, dram_exc);

	$display("%d %h %h %h %c%d %d %o %h #",
		alu0_dataready, alu0_argI, alu0_argA, alu0_argB, 
		 ((fnIsFlowCtrl(alu0_instr)) ? 98 : (fnIsLoad(alu0_instr) || fnIsStore(alu0_instr)) ? 109 : 97),
		alu0_instr, alu0_bt, alu0_sourceid, alu0_pc);
	$display("%d %h %o 0 #", alu0_v, alu0_bus, alu0_id);
	$display("%d %o %h #", alu0_branchmiss, alu0_sourceid, alu0_misspc); 

	$display("%d %h %h %h %c%d %d %o %h #",
		alu1_dataready, alu1_argI, alu1_argA, alu1_argB, 
		 ((fnIsFlowCtrl(alu1_instr)) ? 98 : (fnIsLoad(alu1_instr) || fnIsStore(alu1_instr)) ? 109 : 97),
		alu1_instr, alu1_bt, alu1_sourceid, alu1_pc);
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
		alu0_available, alu0_dataready, alu0_sourceid, alu0_instr, alu0_argA,
		alu0_argB, alu0_argI, alu0_bt);
	$display("  1: avail=%d data=%d id=%o op=%d a1=%h a2=%h im=%h bt=%d",
		alu1_available, alu1_dataready, alu1_sourceid, alu1_instr, alu1_argA,
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

module decoder5 (num, out);
input [4:0] num;
output [31:1] out;

reg [31:0] out1;
always_comb
	out1 = 32'd1 << num;

assign out = out1[31:1];

endmodule
