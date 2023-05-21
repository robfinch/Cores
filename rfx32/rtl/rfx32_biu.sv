// ============================================================================
//        __
//   \\__/ o\    (C) 2022-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfx32_biu.sv
//	- bus interface unit
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// 32373 LUTs / 35147 FFs / 31 BRAMs                                                                          
// ============================================================================

import wishbone_pkg::*;
import rfx32pkg::*;
import rfx32Mmupkg::*;
import rfx32_cache_pkg::*;

module rfx32_biu(rst,clk,tlbclk,clock,AppMode,MAppMode,omode,bounds_chk,pe,
	ip_asid,ip,ip_o,ihit_o,ifStall,ic_line_hi,ic_line_lo,ic_valid,
	fifoToCtrl0_wack, fifoToCtrl0_i,fifoToCtrl0_full_o,
	fifoToCtrl1_wack, fifoToCtrl1_i,fifoToCtrl1_full_o,
	fifoFromCtrl0_o,fifoFromCtrl0_rd,fifoFromCtrl0_empty,fifoFromCtrl0_v,
	fifoFromCtrl1_o,fifoFromCtrl1_rd,fifoFromCtrl1_empty,fifoFromCtrl1_v,
	bte_o, blen_o, tid_o, cti_o, seg_o, cyc_o, stb_o, we_o, sel_o, adr_o, dat_o, csr_o,
	stall_i, next_i, rty_i, ack_i, err_i, tid_i, dat_i, rb_i, adr_i, asid_i,
	dce, keys, arange, ptbr, ipage_fault, clr_ipage_fault,
	iftam_req, iftam_resp, dftam_req, dftam_resp, tlbacr,
	rollback, rollback_bitmaps, snoop_adr, snoop_v, snoop_cid);
parameter CORENO = 6'd1;
parameter AWID=32;
parameter CID = 4'd1;
input rst;
input clk;
input tlbclk;
input clock;							// clock for clock algorithm
input AppMode;
input MAppMode;
input [1:0] omode;
input bounds_chk;
input pe;									// protected mode enable
input rfx32pkg::asid_t ip_asid;
input code_address_t ip;
output code_address_t ip_o;
output ihit_o;
input ifStall;
output ICacheLine ic_line_hi;
output ICacheLine ic_line_lo;
output ic_valid;
// Fifo controls
output fifoToCtrl0_wack;
input memory_arg_t fifoToCtrl0_i;
output fifoToCtrl0_full_o;
output fifoToCtrl1_wack;
input memory_arg_t fifoToCtrl1_i;
output fifoToCtrl1_full_o;
output memory_arg_t fifoFromCtrl_o;
input fifoFromCtrl_rd;
output fifoFromCtrl_empty;
output fifoFromCtrl_v;
// Bus controls
//output wb_write_request128_t wbm_req;
//input wb_read_response128_t wbm_resp;
output wb_burst_type_t bte_o;
output wb_burst_len_t blen_o;
output wb_tranid_t tid_o;
output wb_cycle_type_t cti_o;
output wb_segment_t seg_o;
output reg cyc_o;
output reg stb_o;
input stall_i;
input next_i;
input ack_i;
input rty_i;
input err_i;
input wb_tranid_t tid_i;
output reg we_o;
output reg [15:0] sel_o;
output wb_address_t adr_o;
input [127:0] dat_i;
output reg [127:0] dat_o;
output reg csr_o;
input rb_i;
input wb_address_t adr_i;
input asid_t asid_i;

output reg dce;							// data cache enable
input [23:0] keys [0:7];
input [2:0] arange;
input [127:0] ptbr;
output reg ipage_fault;
input clr_ipage_fault;
input [NTHREADS-1:0] rollback;
output reg [127:0] rollback_bitmaps [0:NTHREADS-1];
input address_t snoop_adr;
input snoop_v;
input [3:0] snoop_cid;
output wb_cmd_request128_t iftam_req;
input wb_cmd_response128_t iftam_resp;
output wb_cmd_request128_t dftam_req;
input wb_cmd_response128_t dftam_resp;
input [3:0] tlbacr;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;

parameter VLOOKUP1	= 4'd2;
parameter VLOOKUP2  = 4'd3;
parameter VLOOKUP3  = 4'd4;
parameter PADR_SET 	= 4'd5;
parameter DATA_ALN	= 4'd6;

parameter IO_KEY_ADR	= 16'hFF88;

integer m,n,k;
integer n4,n5,n7,n10,n11;
genvar g;

reg mem_pipe_adv;
reg [5:0] shr_ma;

reg [6:0] state;
// States for hardware routine stack, five deep.
// States go at least 3 deep.
// Memory1
// PT_FETCH <on a tlbmiss>
// READ_PDE/PTE
// 
wb_address_t imiss_padr, imiss_vadr;
wb_address_t vadr;	// virtual address associated with a request
wb_address_t next_adr_o;
reg first_ifetch;
reg [6:0] stk_state [0:15];
reg [3:0] stk_dep;
memory_arg_t memr, memr_hold;

wb_segment_t last_seg;
reg xlaten_stk;
wb_segment_t seg_stk;
wb_burst_type_t bte_stk;
wb_burst_len_t blen_stk;
wb_cycle_type_t cti_stk;
reg cyc_stk;
reg stb_stk;
reg we_stk;
reg [15:0] sel_stk;
address_t adro_stk;
address_t dadr_stk;
address_t iadr_stk;
reg [127:0] dato_stk;
reg [7:0] last_tid0, last_tid1;
reg [1:0] waycnt;
reg iaccess;
reg daccess;
reg [4:0] icnt;
reg [4:0] dcnt;
address_t iadr;
reg keyViolation = 1'b0;
reg xlaten;
wire memq_v;
reg [31:0] memreq_sel;
code_address_t last_cadr;
PDCE ptc;
physical_address_t padrd1,padrd2,padrd3;	// physical_address_t

memory_arg_t memreq0,imemreq0;
memory_arg_t memreq1,imemreq1;
reg memr_v;
reg memr_fed;
wire tlbrdy;
wire fifoToCtrl0_empty;
wire fifoToCtrl0_v;
wire fifoToCtrl1_empty;
wire fifoToCtrl1_v;


// In this case back-toback reads of the fifo are allowed as a memory
// pipeline is being filled.
reg memreq0_rd;
always_comb
	memreq0_rd = !fifoToCtrl0_empty;// && !memr_v;
reg memreq1_rd;
always_comb
	memreq1_rd = !fifoToCtrl1_empty;// && !memr_v;

memory_arg_t memresp0, memresp1;
memory_arg_t [6:0] mem_resp;	// memory pipeline
reg zero_data = 0;
wb_tranid_t tid_cnt = 'd0;
value_t movdat;
reg [127:0] rb_bitmaps1 [0:NTHREADS-1];
reg [127:0] rb_bitmaps2 [0:NTHREADS-1];
reg [127:0] rb_bitmaps3 [0:NTHREADS-1];
reg [127:0] rb_bitmaps4 [0:NTHREADS-1];
reg [1023:0] dc_line;
reg [1:0] dc_line_mod;
wire [1023:0] stmask;
reg [127:0] memr_sel;
reg [1023:0] memr_res;

// 0,1: PTE
// 2,3: PMT
// 4: PTE address
// 5: PMT address
// 6: TLB update address + way
// 15: trigger read / write
reg [63:0] tlb_bucket [0:15];

address_t cta;		// card table address
address_t ea;
address_t afilt;

always_comb
	afilt = (memreq.func==MR_MOVST) ? memreq.res : memreq.adr;

always_comb
	ea = cta + (afilt >> shr_ma);

reg [7:0] ealow;

reg [1:0] strips;
reg [127:0] sel;
reg [127:0] nsel;
reg [1023:0] dat, dati;
wire [511:0] datis;

biu_dati_align uda1
(
	.dati(response_from_cache0.dat),
	.datis(datis), 
	.amt({response_from_cache0.adr[6:0],3'b0})
);

biu_dati_align uda1
(
	.dati(response_from_cache1.dat),
	.datis(datis), 
	.amt({response_from_cache1.adr[6:0],3'b0})
);

// Build an insert mask for data cache store operations.

rfx32_stmask ustmsk1 (mem_resp[VLOOKUP3].sel, mem_resp[VLOOKUP3].adr[5:0], stmask);

always_comb
	for (n10 = 0; n10 < NTHREADS; n10 = n10 + 1)
		rollback_bitmaps[n10] = rb_bitmaps1[n10]|rb_bitmaps2[n10]|rb_bitmaps3[n10]|rb_bitmaps4[n10];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

physical_address_t padr;
wire [3:0] ififo_cnt, ofifo_cnt;
wire [16:0] lfsr_o;

lfsr17 #(.WID(17)) ulfsr1
(
	.rst(rst),
	.clk(clk),
	.ce(1'b1),
	.cyc(1'b0),
	.o(lfsr_o)
);

wire pev;
edge_det ued1 (.rst(rst), .clk(clk), .ce(1'b1), .i(fifoToCtrl_v), .pe(pev), .ne(), .ee());

rfx32_mem_req_queue 
#(
	.MERGE_STORES(1'b0)
)
umreqq0
(
	.rst(rst),
	.clk(clk),
	.wr0(fifoToCtrl0_i.wr),
	.wr_ack0(fifoToCtrl0_wack),
	.i0(fifoToCtrl0_i),
	.wr1(1'b0),
	.wr_ack1(),
	.i1('d0),
	.rd(memreq_rd),// & ~pev),
	.o(imemreq),
	.valid(fifoToCtrl_v),
	.empty(fifoToCtrl_empty),
	.ldo0(),
	.found0(),
	.ldo1(),
	.found1(),
  .full(fifoToCtrl_full_o),
  .rollback(rollback),
  .rollback_bitmaps(rb_bitmaps1)
);

rfx32_mem_req_queue 
#(
	.MERGE_STORES(1'b0)
)
umreqq1
(
	.rst(rst),
	.clk(clk),
	.wr0(fifoToCtrl1_i.wr),
	.wr_ack0(fifoToCtrl1_wack),
	.i0(fifoToCtrl1_i),
	.wr1(1'b0),
	.wr_ack1(),
	.i1('d0),
	.rd(memreq_rd),// & ~pev),
	.o(imemreq),
	.valid(fifoToCtrl_v),
	.empty(fifoToCtrl_empty),
	.ldo0(),
	.found0(),
	.ldo1(),
	.found1(),
  .full(fifoToCtrl_full_o),
  .rollback(rollback),
  .rollback_bitmaps(rb_bitmaps1)
);

wire memresp0_full;
wire [3:0] fifoFromCtrl0_cnt;
assign fifoFromCtrl0_empty = fifoFromCtrl0_cnt=='d0;

wire memresp1_full;
wire [3:0] fifoFromCtrl1_cnt;
assign fifoFromCtrl1_empty = fifoFromCtrl1_cnt=='d0;

// This fifo sits between the output of the data cache module and the CPU. It
// may return either cached data to the CPU or uncached data.

rfx32_mem_resp_fifo uofifo0
(
	.rst(rst),
	.clk(clk),
	.wr(memresp0.wr),
	.di(memresp0),
	.rd(fifoFromCtrl0_rd),
	.dout(fifoFromCtrl0_o),
	.cnt(fifoFromCtrl0_cnt),
	.full(memresp0_full),
	.v(fifoFromCtrl0_v),
	.rollback(1'b0),
	.rollback_bitmaps()
);

rfx32_mem_resp_fifo uofifo1
(
	.rst(rst),
	.clk(clk),
	.wr(memresp1.wr),
	.di(memresp1),
	.rd(fifoFromCtrl1_rd),
	.dout(fifoFromCtrl1_o),
	.cnt(fifoFromCtrl1_cnt),
	.full(memresp1_full),
	.v(fifoFromCtrl1_v),
	.rollback(1'b0),
	.rollback_bitmaps()
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction cache
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

parameter IWAYS = 4;
localparam LOG_IWAYS = $clog2(IWAYS)-1;
wire itlbrdy;
reg itlben, itlbwr;
wire ihit;
TLBE itlbdato;
rfx32pkg::asid_t imiss_asid;
code_address_t phys_ip, imiss_adr;
code_address_t original_ip;
wb_address_t upd_adr = 'd0;
wire wr_ic2;
ICacheLine ic_input;		// Must be a multiple of 128 bits wide for shifting.
reg [2:0] ivictim_count;
ICacheLine [4:0] ivictim_cache;
reg [LOG_IWAYS:0] ic_wway;
reg [2:0] vcn;
reg ic_invline,ic_invall;

rfx32_icache
#(
	.CID({CID,1'b0}),
	.WAYS(IWAYS)
) 
uic1
(
	.rst(rst),
	.clk(clk),
	.invce(state==MEMORY4),
	.snoop_adr(snoop_adr),
	.snoop_v(snoop_v),
	.snoop_cid(snoop_cid),
	.ip_asid(ip_asid),
	.ip(ip),
	.ip_o(ip_o),
	.ihit_o(ihit_o),
	.ihit(ihit),
	.ic_line_hi_o(ic_line_hi),
	.ic_line_lo_o(ic_line_lo),
	.ic_valid(ic_valid),
	.miss_asid(imiss_asid),
	.miss_adr(imiss_adr),
	.ic_line_i(ic_input),
	.wway(ic_wway),
	.wr_ic(wr_ic2)
);

rfx32_icache_ctrl 
#(
	.CID({CID,1'b0}),
	.WAYS(IWAYS)
) 
uictrl
(
	.rst(rst),
	.clk(clk),
	.wbm_req(iftam_req),
	.wbm_resp(iftam_resp),
	.hit(ihit),
	.miss_asid(imiss_asid),
	.miss_adr(imiss_adr),
	.wr_ic(wr_ic2),
	.way(ic_wway),
	.line_o(ic_input),
	.snoop_adr(snoop_adr),
	.snoop_v(snoop_v),
	.snoop_cid(snoop_cid)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Data Cache
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
parameter DWAYS = 4;
localparam LOG_DWAYS = $clog2(DWAYS)-1;
wire dtlbrdy, dtlbmiss;
reg dtlben, dtlbwr;
TLBE dtlbdato;
physical_address_t phys_dadr, phys_dadrd1;
reg dc_wr0, dcwr1;
wire dhit0,dhit1,dmodified0,dmodified1;
address_t dadr;
DCacheLine dci [0:1];
DCacheLine dci1,dci2;
reg [1023:0] datil;
reg dcachable;
reg dc_invline,dc_invall;
wire dcache_load0, dcache_load1;
wire [1:0] dc_uway0, dc_way0, dc_uway1, dc_way1;
wb_cmd_request512_t cpu_req0, cpu_req1;
wb_cmd_response512_t response_from_cache0, data_to_cache0, response_from_cache1, data_to_cache1;
wire dc_dump0, dc_dump0_ack, dc_dump1, dc_dump1_ack;
DCacheLine dc_dump0_o,dc_dump1_o;

always_comb
begin
	memresp0.sel = cpu_req0.sel;
	memresp0.cause = imemreq0.cause;
//	tDataAlign(response_from_cache,imemreq.bytcnt,memresp);
	memresp0.res = response_from_cache0.dat;
	memresp0.tgt = imemreq0.tgt;
	memresp0.wr_tgt = imemreq0.wr_tgt;
	memresp0.tid = response_from_cache0.tid;
	memresp0.wr = response_from_cache0.ack;
	memresp0.load = imemreq0.load;
	memresp0.store = imemreq0.store;
	memresp0.group = imemreq0.group;
	memresp0.v = response_from_cache0.ack;
end


rfx32_dcache
#(
	.CORENO(CORENO),
	.CID({CID,1'b1}),
	.WAYS(DWAYS)
)
udc0
(
	.rst(rst),
	.clk(clk),
	.dce(dce),
	.snoop_adr(snoop_adr),
	.snoop_v(snoop_v),
	.snoop_cid(snoop_cid),
	.cache_load(dcache_load0),
	.hit(dhit0),
	.modified(dmodified0),
	.uway(dc_uway0),
	.cpu_req_i(cpu_req0),
	.cpu_resp_o(response_from_cache0),
	.update_data_i(data_to_cache0),
	.dump(dc_dump0),
	.dump_o(dc_dump0_o),
	.dump_ack_i(dc_dump0_ack),
	.wr(dc_wr0),
	.way(dc_way0),
	.invce(state==MEMORY4),
	.dc_invline(dc_invline),
	.dc_invall(dc_invall)
);


rfx32_dcache_ctrl
#(
	.CORENO(CORENO),
	.CID({CID,1'b1}),
	.WAYS(DWAYS)
)
udcctrl0
(
	.rst_i(rst),
	.clk_i(clk),
	.dce(dce),
	.wbm_req(dwbm0_req),
	.wbm_resp(dwbm0_resp),
	.acr(tlbacr0),
	.hit(dhit0),
	.modified(dmodified0),
	.cache_load(dcache_load0),
	.cpu_request_i(cpu_req0),
	.data_to_cache_o(data_to_cache0),
	.response_from_cache_i(response_from_cache0),
	.wr(dc_wr0),
	.uway(dc_uway0),
	.way(dc_way0),
	.dump(dc_dump0),
	.dump_i(dc_dump0_o),
	.dump_ack(dc_dump0_ack),
	.snoop_adr(snoop_adr),
	.snoop_v(snoop_v),
	.snoop_cid(snoop_cid)
);

always_comb
begin
	memresp1.sel = cpu_req1.sel;
	memresp1.cause = imemreq1.cause;
//	tDataAlign(response_from_cache,imemreq.bytcnt,memresp);
	memresp1.res = response_from_cache1.dat;
	memresp1.tgt = imemreq1.tgt;
	memresp1.wr_tgt = imemreq1.wr_tgt;
	memresp1.tid = response_from_cache1.tid;
	memresp1.wr = response_from_cache1.ack;
	memresp1.load = imemreq1.load;
	memresp1.store = imemreq1.store;
	memresp1.group = imemreq1.group;
	memresp1.v = response_from_cache1.ack;
end


rfx32_dcache
#(
	.CORENO(CORENO),
	.CID({CID,1'b1}),
	.WAYS(DWAYS)
)
udc1
(
	.rst(rst),
	.clk(clk),
	.dce(dce),
	.snoop_adr(snoop_adr),
	.snoop_v(snoop_v),
	.snoop_cid(snoop_cid),
	.cache_load(dcache_load1),
	.hit(dhit1),
	.modified(dmodified1),
	.uway(dc_uway1),
	.cpu_req_i(cpu_req1),
	.cpu_resp_o(response_from_cache1),
	.update_data_i(data_to_cache1),
	.dump(dc_dump1),
	.dump_o(dc_dump1_o),
	.dump_ack_i(dc_dump1_ack),
	.wr(dc_wr1),
	.way(dc_way1),
	.invce(state==MEMORY4),
	.dc_invline(dc_invline),
	.dc_invall(dc_invall)
);


rfx32_dcache_ctrl
#(
	.CORENO(CORENO),
	.CID({CID,1'b1}),
	.WAYS(DWAYS)
)
udcctrl1
(
	.rst_i(rst),
	.clk_i(clk),
	.dce(dce),
	.wbm_req(dwbm1_req),
	.wbm_resp(dwbm1_resp),
	.acr(tlbacr1),
	.hit(dhit1),
	.modified(dmodified1),
	.cache_load(dcache_load1),
	.cpu_request_i(cpu_req1),
	.data_to_cache_o(data_to_cache1),
	.response_from_cache_i(response_from_cache1),
	.wr(dc_wr1),
	.uway(dc_uway1),
	.way(dc_way1),
	.dump(dc_dump1),
	.dump_i(dc_dump1_o),
	.dump_ack(dc_dump1_ack),
	.snoop_adr(snoop_adr),
	.snoop_v(snoop_v),
	.snoop_cid(snoop_cid)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// TLB
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

reg tlb_access = 1'b0;
TLBE tmptlbe;
reg [5:0] ipt_miss_count;
reg tlben, tlbwr;
wire tlbmiss;
TLBE tlbdato;
reg [31:0] tlb_ia;
TLBE tlb_ib;
wire tlb_cyc;
wire [127:0] tlb_dat;
address_t tlb_adr;
reg tlb_ack;
reg inext;
virtual_address_t tlbmiss_adr;
virtual_address_t miss_adr;
reg wr_ptg;
/*
always_comb
begin
	tlb_ib[ 63:  0] <= tlb_bucket[0];
	tlb_ib[127: 64] <= tlb_bucket[1];
	tlb_ib[191:128] <= tlb_bucket[2];
	tlb_ib[255:128] <= tlb_bucket[3];
	tlb_ib.adr 			<= tlb_bucket[4];
	tlb_ib.pmtadr 	<= tlb_bucket[5];
	tlb_ia <= tlb_bucket[6][31:0];
end
*/
/*
rfx32_tlb utlb
(
  .rst_i(rst),
  .clk_i(tlbclk),
  .al_i(ptbr[7:6]),
  .clock(clock),
  .rdy_o(tlbrdy),
  .asid_i(mem_resp[0].asid),
  .sys_mode_i(seg_o==wishbone_pkg::CODE ? ~AppMode : ~MAppMode),
  .xlaten_i(xlaten),
  .we_i(we_o),
  .dadr_i(dadr),
  .next_i(inext),
  .iacc_i(mem_resp[0].v),//iaccess|daccess),
  .dacc_i(1'b0),
  .iadr_i(mem_resp[0].adr),
  .padr_o(padr),
  .acr_o(tlbacr),
  .tlben_i(tlben),
  .wrtlb_i(tlbwr),
  .tlbadr_i(tlb_ia[15:0]),
  .tlbdat_i(tlb_ib),
  .tlbdat_o(tlbdato),
  .tlbmiss_o(tlbmiss),
  .tlbmiss_adr_o(tlbmiss_adr),
  .m_cyc_o(tlb_cyc),
  .m_ack_i(tlb_ack),
  .m_adr_o(tlb_adr),
  .m_dat_o(tlb_dat)
);
*/
reg [4:0] mp_delay;
vtdl #(.WID($bits(physical_address_t)), .DEP(32)) umpd1 (.clk(clk), .ce(1'b1), .a(mp_delay), .d(phys_dadr), .q(phys_dadrd1));

//always_ff @(posedge clk)	// delay for data tag lookup
//	padrd1 <= padr;
always_ff @(posedge clk)	// two cycle delay for data fetch
	padrd2 <= phys_dadrd1;
always_ff @(posedge clk)
	padrd3 <= padrd2;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Page Directory Entries
//   There are only 64 PDEs required to map the upper six bits of the address
// space. So, to improve performance and conserve memory the PDE table has
// its own dedicated memory.
//   The PDE table is memory mapped for programmatic read/write access.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

reg pde_wr;
reg pde_en;
PDE pde_dat;
PDE pde_o;
PDE miss_pde;
reg [9:0] pde_adr;
sram_PDEx1024_1rw1w upder1
(
	.rst(rst),
	.clk(clk),
	.ena(pde_en),
	.wra(pde_wr),
	.adra(pde_adr),
	.ia(pde_dat),
	.oa(pde_o),
	.enb(tlbmiss),
	.adrb({mem_resp[VLOOKUP3].thread,tlbmiss_adr[31:26]}),
	.ob(miss_pde)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// IPT
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

reg [6:0] ptg_state = IPT_IDLE;
reg [7:0] fault_code;
reg ptg_fault;
reg clr_ptg_fault;
wire ptg_en = ptbr[2];
PTG ptg;
PTE tmptlbe2;
PTGCE [PTGC_DEP-1:0] ptgc;
reg pte_found;
wire [2:0] entry_num;
reg [3:0] span_lo, span_hi;
wire [15:0] hash;
reg [127:0] ndat;		// next data output
reg ptgram_wr;
reg ptgram_en;
reg [14:0] ptgram_adr;
reg [127:0] ptgram_dati;
wire [127:0] ptgram_dato;
reg ptgram_web = 1'b0;
reg [11:0] ptgram_adrb = 'd0;
PTG ptgram_datib;
address_t ptg_lookup_address;
reg [3:0] ptgacr = 4'd15;
wire pe_clock;
reg clock_r = 1'b0;
reg [11:0] clock_count = 'd0;

// SIM debugging
reg [5:0] ptg_lac = 'd0;
address_t [63:0] ptg_last_adr;

`ifdef SUPPORT_HASHPT

always_ff @(posedge clk)
begin
	if (ptgram_wr) begin
		ptg_last_adr[ptg_lac] <= ptgram_adr;
		ptg_lac <= ptg_lac + 1'd1;
	end
end

PTG_RAM uptgram (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(ptgram_wr),      // input wire [0 : 0] wea
  .addra(ptgram_adr),  // input wire [13 : 0] addra
  .dina(ptgram_dati),    // input wire [159 : 0] dina
  .douta(ptgram_dato),  // output wire [159 : 0] douta
  .clkb(tlbclk),  // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(ptgram_web & ~ptgram_wr),      // input wire [0 : 0] web
  .addrb(ptgram_adrb),  // input wire [10 : 0] addrb
  .dinb(ptgram_datib),    // input wire [1279 : 0] dinb
  .doutb(ptg)  // output wire [1279 : 0] doutb
);
`endif

`ifdef SUPPORT_HASHPT2
rfx32_ipt_hash uhash
(
	.clk(clk),
	.asid(ASID),
	.adr(miss_adr),
	.mask(ptbr[127:96]),
	.hash(hash)
);

rfx32_ptg_search uptgs
(
	.ptg(ptg),
	.asid(ASID),
	.miss_adr(miss_adr),
	.pte(tmptlbe2),
	.found(pte_found),
	.entry_num(entry_num)
);

`endif

// Hold onto the previous idadr if none is selected, to allow the update of
// the PTG RAM to complete without changes. A PTG write cycle will bounce
// back to the memory IDLE state almost immediately, this leaves the address
// to be maintained.
address_t idadr, prev_idadr;
always_comb
	case(1'b1)
	daccess: idadr <= dadr;
	iaccess: idadr <= iadr;
	default:	idadr <= 32'hFF7FFFFF;
	endcase
always_ff @(posedge clk)
	prev_idadr <= idadr;

`ifdef SUPPORT_HASHPT
rfx32_ipt_hash uhash
(
	.clk(clk),
	.asid(ASID),
	.adr(idadr),
	.mask(ptbr[127:96]),
	.hash(hash)
);

rfx32_ptg_search uptgs
(
	.ptg(ptg),
	.asid(ASID),
	.miss_adr(idadr),
	.pte(tmptlbe2),
	.found(pte_found),
	.entry_num(entry_num)
);

always_comb
begin
	next_adr_o <= adr_o;
	if (ptg_en) begin
		if (pte_found)
			next_adr_o <= {tmptlbe2.ppn,idadr[15:12]+tmptlbe2.mb,idadr[11:0]};
	end
	else
		next_adr_o <= idadr;
end

always @(posedge tlbclk)
begin
	adr_o <= next_adr_o;
	if (ptg_en) begin
		if (pte_found) begin
			if (idadr[15:12] + tmptlbe2.mb <= tmptlbe2.me)
				ptgacr <= tmptlbe2.rwx;
			else
				ptgacr <= 4'd0;
		end
	end
	else
		ptgacr <= 4'd15;
end

assign tlbacr = ptgacr;
assign tlbrdy = 1'b1;
assign tlb_cyc = 1'b0;
`else
always_comb
begin
	next_adr_o <= adr_o;
	/*
	if (ptg_en) begin
		if (pte_found)
			next_adr_o <= {tmptlbe2.ppn,idadr[15:12]+tmptlbe2.mb,idadr[11:0]};
	end
	else
	*/
		next_adr_o <= idadr;
end
`endif

// 0   159  319 479  639  799   959  1119  1279
// 0 128 255 383 511 639 767 895 1023 1151 1279
always_ff @(posedge clk)
	case(entry_num)
	3'd0:	begin span_lo <= 4'd0; span_hi <= 4'd1; end
	3'd1: begin span_lo <= 4'd1; span_hi <= 4'd2; end
	3'd2: begin span_lo <= 4'd2; span_hi <= 4'd3; end
	3'd3: begin span_lo <= 4'd3; span_hi <= 4'd4; end
	3'd4: begin span_lo <= 4'd5; span_hi <= 4'd6; end
	3'd5: begin span_lo <= 4'd6; span_hi <= 4'd7; end
	3'd6: begin span_lo <= 4'd7; span_hi <= 4'd8; end
	3'd7: begin span_lo <= 4'd8; span_hi <= 4'd9; end
	endcase


integer j;
reg [11:0] square_table [0:63];
initial begin
	for (j = 0; j < 64; j = j + 1)
		square_table[j] = j * j;
end

wire cd_idadr;
reg cd_idadr_r;
edge_det uclked1 (.rst(rst), .clk(tlbclk), .ce(1'b1), .i(clock), .pe(pe_clock), .ne(), .ee());
change_det uchgdt1 (.rst(rst), .clk(tlbclk), .ce(1'b1), .i(idadr), .cd(cd_idadr));

reg special_ram;
always_comb
	special_ram = ptgram_en || tlb_access;

reg [15:0] hash_r;
`ifdef SUPPORT_HASHPT
integer n6;
always_ff @(posedge tlbclk)
begin
	if (clr_ptg_fault|clr_ipage_fault) begin
		ipt_miss_count <= 'd0;
		ptg_fault <= 1'b0;
	end
	if (pe_clock)
		clock_r <= 1'b1;
	if (cd_idadr)
		cd_idadr_r <= TRUE;

	case (ptg_state)
	IPT_IDLE:
		begin
			ipt_miss_count <= 'd0;
			if ((!pte_found || cd_idadr_r) && ptg_en && (iaccess||daccess) && !special_ram) begin
				cd_idadr_r <= FALSE;
				ptg_state <= IPT_RW_PTG2;
				ptgram_adrb <= hash & 16'hFFFF;
				hash_r <= hash;
			end
			else if (clock_r) begin
				clock_r <= 1'b0;
				ptg_state <= IPT_CLOCK1;
				clock_count <= clock_count + 2'd1;
			end
		end

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// Hardware routine to find an address translation.
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// 
	IPT_FETCH1:
		begin
			// Open addressing with quadratic probing
			ptgram_adrb <= ((hash_r + square_table[ipt_miss_count]) & 16'hFFFF);
	    if (ipt_miss_count==6'd12)
	    	ptg_fault <= 1'b1;
	    else
	    	ptg_state <= IPT_RW_PTG2;
		end
	IPT_RW_PTG2:
		begin
			ipt_miss_count <= ipt_miss_count + 2'd1;
 			ptg_state <= IPT_RW_PTG3;
		end
	// Region is not valid until after next_adr_o is set
	IPT_RW_PTG3:
		begin
			ptg_state <= IPT_RW_PTG4;
		end
	IPT_RW_PTG4:
		begin
			ptg_state <= IPT_RW_PTG5;
		end
	IPT_RW_PTG5:
		ptg_state <= IPT_RW_PTG6;
	IPT_RW_PTG6:
		begin
  		ptg_state <= pte_found ? IPT_IDLE : IPT_FETCH1;
		end	

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// Age access counts
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	IPT_CLOCK1:
		ptg_state <= IPT_CLOCK2;
	IPT_CLOCK2:
		ptg_state <= IPT_CLOCK3;
	IPT_CLOCK3:
		begin
  		ptg_state <= IPT_IDLE;
		end
	
	default:
		ptg_state <= IPT_IDLE;

	endcase
end
`endif

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// PT
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Page table vars
reg [2:0] dep;
reg [12:0] adr_slice;
PTE pte;
PDE pde;
reg wr_pte;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Capture data and address
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg acki1, acki2, cs1;

typedef struct packed
{
	wb_burst_len_t blen;
	logic we;
	wb_address_t vadr;
	wb_address_t adr;
	wb_segment_t seg;
} req_table_t;

wb_tranid_t prev_tid;
reg req_done, clr_req_done;
reg wr_reqtbl;
req_table_t [255:0] reqtbl;
req_table_t req;
always_ff @(posedge clk)
	if (wr_reqtbl)
		reqtbl[tid_o] <= {blen_o,we_o,vadr,adr_o,seg_o};
reg [7:0] tid_id;
always_ff @(posedge clk)
	tid_id <= tid_i;
assign req = reqtbl[tid_i];

always_ff @(posedge clk)
if (rst) begin
	prev_tid <= 'd0;
end
else begin
	if (ack_i) begin
		if (tid_i[7:3]!=prev_tid[7:3] && tid_i[2:0]=='d0) begin
			prev_tid <= tid_i;
		end
	end
end

always_ff @(posedge clk)
if (rst)
	last_tid0 <= 'd0;
else begin
	if (memreq0_rd) begin
		if (imemreq0.tid != last_tid0)
			last_tid0 <= imemreq0.tid;
	end
end

always_ff @(posedge clk)
if (rst)
	last_tid1 <= 'd0;
else begin
	if (memreq1_rd) begin
		if (imemreq1.tid != last_tid1)
			last_tid1 <= imemreq1.tid;
	end
end

always_ff @(posedge clk)
if (rst) begin
	cpu_req0.blen <= 'd0;
	cpu_req0.cyc <= 'd0;
	cpu_req0.stb <= 'd0;
	cpu_req0.we <= 'd0;
	cpu_req0.sel <= 'd0;
	cpu_req0.padr <= 'd0;
	cpu_req0.csr <= 'd0;
	cpu_req0.pl <= 'd0;
	cpu_req0.pri <= 4'd7;
	cpu_req0.dat <= 'd0;
	cpu_req0.cid <= {CID,1'b1};
end
else begin
	if (memreq0_rd) begin
		if (imemreq0.tid != last_tid0) begin
			case(imemreq0.func)
			MR_LOAD:	cpu_req0.cmd <= CMD_LOAD;
			MR_LOADZ:	cpu_req0.cmd <= CMD_LOADZ;
			MR_STORE:	cpu_req0.cmd <= CMD_STORE;
			default:	cpu_req0.cmd <= CMD_LOAD;
			endcase
			cpu_req0.tid <= imemreq0.tid;
			cpu_req0.om <= wb_operating_mode_t'(imemreq0.omode);
			cpu_req0.seg <= wishbone_pkg::DATA;
			cpu_req0.bte <= wishbone_pkg::LINEAR;
			cpu_req0.cti <= wishbone_pkg::CLASSIC;
			cpu_req0.cyc <= 1'b1;
			cpu_req0.stb <= 1'b1;
			cpu_req0.we <= imemreq0.store;
			cpu_req0.sel <= imemreq0.sel;
			cpu_req0.asid <= imemreq0.asid;
			cpu_req0.vadr <= imemreq0.adr;
			cpu_req0.dat <= imemreq0.res;
			cpu_req0.sz <= wb_size_t'(imemreq0.sz);
			cpu_req0.cache <= wb_cache_t'(imemreq0.cache_type);
		end
//		else if (response_from_cache.ack || response_from_cache.err || response_from_cache.rty) begin
		else begin
			cpu_req0.cmd <= CMD_NONE;
			cpu_req0.cyc <= 1'b0;
			cpu_req0.stb <= 1'b0;
			cpu_req0.we <= 1'b0;
			cpu_req0.sel <= 'd0;
		end
	end
end

always_ff @(posedge clk)
if (rst) begin
	cpu_req1.blen <= 'd0;
	cpu_req1.cyc <= 'd0;
	cpu_req1.stb <= 'd0;
	cpu_req1.we <= 'd0;
	cpu_req1.sel <= 'd0;
	cpu_req1.padr <= 'd0;
	cpu_req1.csr <= 'd0;
	cpu_req1.pl <= 'd0;
	cpu_req1.pri <= 4'd7;
	cpu_req1.dat <= 'd0;
	cpu_req1.cid <= {CID,1'b1};
end
else begin
	if (memreq1_rd) begin
		if (imemreq1.tid != last_tid1) begin
			case(imemreq1.func)
			MR_LOAD:	cpu_req1.cmd <= CMD_LOAD;
			MR_LOADZ:	cpu_req1.cmd <= CMD_LOADZ;
			MR_STORE:	cpu_req1.cmd <= CMD_STORE;
			default:	cpu_req1.cmd <= CMD_LOAD;
			endcase
			cpu_req1.tid <= imemreq1.tid;
			cpu_req1.om <= wb_operating_mode_t'(imemreq1.omode);
			cpu_req1.seg <= wishbone_pkg::DATA;
			cpu_req1.bte <= wishbone_pkg::LINEAR;
			cpu_req1.cti <= wishbone_pkg::CLASSIC;
			cpu_req1.cyc <= 1'b1;
			cpu_req1.stb <= 1'b1;
			cpu_req1.we <= imemreq1.store;
			cpu_req1.sel <= imemreq1.sel;
			cpu_req1.asid <= imemreq1.asid;
			cpu_req1.vadr <= imemreq1.adr;
			cpu_req1.dat <= imemreq1.res;
			cpu_req1.sz <= wb_size_t'(imemreq1.sz);
			cpu_req1.cache <= wb_cache_t'(imemreq1.cache_type);
		end
//		else if (response_from_cache.ack || response_from_cache.err || response_from_cache.rty) begin
		else begin
			cpu_req1.cmd <= CMD_NONE;
			cpu_req1.cyc <= 1'b0;
			cpu_req1.stb <= 1'b0;
			cpu_req1.we <= 1'b0;
			cpu_req1.sel <= 'd0;
		end
	end
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// State Machine
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg dfetch2,dstore1;
task tReset;
begin
	dce <= TRUE;
	zero_data <= FALSE;
	dcachable <= TRUE;
	ivictim_count <= 3'd0;
	icnt <= 'd0;
	vcn <= 3'd0;
	shr_ma <= 6'd0;
	itlben <= TRUE;
	dtlben <= TRUE;
	iadr <= RSTPC;
	dadr <= RSTPC;	// prevents MR_TLB miss at startup
	tDeactivateBus();
	seg_o <= wishbone_pkg::CODE;
	adr_o <= 'd0;
	dat <= 'd0;
	csr_o <= LOW;
	waycnt <= 2'd0;
	iaccess <= FALSE;
	daccess <= FALSE;
//	memreq_rd <= FALSE;
  xlaten <= FALSE;
  tmptlbe <= 'd0;
  wr_pte <= 1'b0;
  wr_ptg <= 1'b0;
  tlb_ack <= 1'b0;
  ptgram_wr <= FALSE;
  ptg_fault <= 1'b0;
	clr_ptg_fault <= 1'b0;
	ipage_fault <= 1'b0;
	ptgram_en <= 1'b0;
	tlb_access <= 1'b0;
	sel <= 'd0;
	dfetch2 <= 1'b0;
//	rd_memq1 <= 'd0;
	mem_resp[0] <= 'd0;
	mem_resp[1] <= 'd0;
	mem_resp[2] <= 'd0;
	mem_resp[3] <= 'd0;
	mem_resp[4] <= 'd0;
	mem_resp[5] <= 'd0;
	mem_resp[6] <= 'd0;
	last_cadr <= 'd0;
	tid_o <= 'd0;
	for (n = 0; n < NTHREADS; n = n + 1)
		rb_bitmaps2[n] <= 'd0;
	goto (MEMORY_INIT);
	dep <= 'd0;
	stk_dep <= 'd0;
	dcnt <= 'd0;
	mp_delay <= 'd0;
	wr_reqtbl <= 'd0;
	tid_cnt <= 'd0;
	clr_req_done <= 'd0;
	memr_v <= FALSE;
	memr_fed <= FALSE;
	first_ifetch <= FALSE;
end
endtask

reg [5:0] blen1;
always_ff @(posedge clk)
	acki1 <= ack_i;
always_ff @(posedge clk)
	acki2 <= acki1;
always_comb// @(posedge clk)
	cs1 <= req.seg==wishbone_pkg::CODE;
always_ff @(posedge clk)
	blen1 <= req.blen;

always_ff @(posedge clk)
if (rst) begin
	tReset();
end
else begin
	for (n = 0; n < NTHREADS; n = n + 1)
		if (rollback[n])
			rb_bitmaps2[n] <= 'd0;
	dcachable <= TRUE;
	inext <= FALSE;
//	memreq_rd <= FALSE;
	itlbwr <= FALSE;
	dtlbwr <= FALSE;
	tlb_ack <= FALSE;
	ptgram_wr <= FALSE;
	clr_ptg_fault <= 1'b0;
	if (clr_ipage_fault)
		ipage_fault <= 1'b0;
//	wr_ic2 <= wr_ic1;
//	wr_dc2 <= wr_dc1;
//	if (ack_i && count==req.blen && req.seg==wishbone_pkg::DATA)	// && !req.we)
//		wr_dc1 <= TRUE;
	wr_reqtbl <= 'd0;
	clr_req_done <= 'd0;

	mem_resp[DATA_ALN].wr <= FALSE;
	itlbwr <= FALSE;
	dtlbwr <= FALSE;
	tlb_ack <= FALSE;
	ptgram_wr <= FALSE;
	tStage0();
	tStage1();

		for (n5 = 0; n5 < 7; n5 = n5 + 1)
			if (rollback[mem_resp[n5].thread]) begin
				mem_resp[n5].v <= 1'b0;
				rb_bitmaps2[mem_resp[n5].thread][mem_resp[n5].tgt] <= 1'b1;
			end

	case(state)
	MEMORY_INIT:
		begin
			for (n5 = 0; n5 < 8; n5 = n5 + 1)
				ptc[n5] <= 'd0;
//			rd_memq1 <= FALSE;
			goto (MEMORY1);
		end

	MEMORY1:
		begin
		end

	// The following two states for MR_TLB translation lookup
	// Must check for two PTG states since that machine is clocked at twice
	// the rate.
	MEMORY3:
`ifdef SUPPORT_HASHPT
		if (ptg_state==IPT_RW_PTG5 || ptg_state==IPT_RW_PTG6 || !ptg_en || special_ram)
			goto (MEMORY4);
`else
		goto (MEMORY4);
`endif
`ifdef SUPPORT_KEYCHK
	MEMORY4:
		goto (MEMORY_KEYCHK1);
`else
	MEMORY4:
		goto (MEMORY5);
`endif
`ifdef SUPPORT_KEYCHK
	MEMORY_KEYCHK1:
		tKeyCheck(MEMORY5);
	KEYCHK_ERR:
		begin
		/*
			memresp.step <= memreq.step;
	    memresp.cause <= {4'h8,FLT_KEY};	// KEY fault
	    memresp.cmt <= TRUE;
			memresp.tid <= memreq.tid;
		  memresp.adr <= ea;
		  memresp.wr <= TRUE;
			memresp.res <= 128'd0;
		*/
		  ret(0);
		end
`endif
	MEMORY5: goto (MEMORY5a);
	MEMORY5a:		// Allow time for lookup
		goto (MEMORY_ACTIVATE);

	MEMORY_ACTIVATE:
		tMemoryActivate();

	MEMORY_ACK:
		tMemoryAck();

	MEMORY_NACK:
		tMemoryNack();
		
	MEMORY_UPD1:
		begin
			//dci[0] <= dci[1].data;
			//dci[1] <= dci[0].data;
			//dci[0].m <= 1'b1;
			//dci[1].m <= 1'b1;
			if (memr.hit==2'b11)
				goto (MEMORY_UPD2);
			else
				ret(0);
		end
	MEMORY_UPD2:
		ret(0);

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// Complete TLB access cycle
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	TLB1:
		goto (TLB2);	// Give time for MR_TLB to process
	TLB2:
		goto (TLB3);	// Give time for MR_TLB to process
	TLB3:
		begin
			/*
			memresp.cause <= FLT_NONE;
			memresp.step <= memreq.step;
	    memresp.res <= {432'd0,itlbdato};
	    memresp.cmt <= TRUE;
			memresp.tid <= memreq.tid;
			memresp.wr <= TRUE;
			*/
	   	ret(0);
		end

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	// Initiate burst access
	DFETCH2:
	  if (!next_i) begin
	  	seg_o <= wishbone_pkg::DATA;
			last_seg <= wishbone_pkg::DATA;
	  	bte_o <= wishbone_pkg::LINEAR;
	  	cti_o <= wishbone_pkg::FIXED;	// constant address burst cycle
	    cyc_o <= HIGH;
			stb_o <= HIGH;
	    sel_o <= 16'hFFFF;
	    dcnt <= 'd0;
	    tid_o <= {tid_cnt[7:3]+2'd1,3'd0};
    	tid_cnt[7:3] <= tid_cnt[7:3] + 2'd1;
    	tid_cnt[2:0] <= 'd0;
    	wr_reqtbl <= 1'b1;
	    goto (DFETCH5);
	    case(memr.hit)
	    2'b00:		// need both even and odd cache lines (start with even)
	    	begin
			  	blen_o <= 8'd1;
					adr_o <= {memr.adr[AWID-1:6]+memr.adr[5],1'b0,5'h0};
				end
	    2'b01:		// If got a hit on the even address, the odd one must be missing
	    	begin
			  	blen_o <= 8'd1;
			  	cti_o <= wishbone_pkg::CLASSIC;
					adr_o <= {memr.adr[AWID-1:6],1'b1,5'h0};
				end
			2'b10:		// Otherwise the even one must be missing
				begin
			  	blen_o <= 8'd1;
			  	cti_o <= wishbone_pkg::CLASSIC;
					adr_o <= {memr.adr[AWID-1:6]+memr.adr[5],1'b0,5'h0};
				end
			2'b11:		// not missing lines, finished
				begin
					tDeactivateBus();
					ret(0);
				end
			endcase
	  end

	// Sustain burst access
	DFETCH5:
	  begin
	  	stb_o <= HIGH;
	    if (next_i) begin
	    	wr_reqtbl <= 1'b1;
				seg_o <= wishbone_pkg::DATA;
	    	tid_o <= tid_cnt;
	    	tid_cnt[2:0] <= tid_cnt[2:0] + 2'd1;
	    	dcnt <= dcnt + 4'd4;
	      //dci[0].data <= {dat_i,dci[0].data[255:128]};
	      //dci[0].m <= 1'b0;
	      if (dcnt[4:2]==blen_o-1 && blen_o > 'd0)
	      	cti_o <= wishbone_pkg::EOB;
	      if (dcnt[4:2]==blen_o[2:0]) begin		// Are we done?
	      	case(memr.hit)
	      	2'b00:	memr.hit <= 2'b01;
	      	2'b01:	memr.hit <= 2'b11;
	      	2'b10:	memr.hit <= 2'b11;
	      	2'b11:	memr.hit <= 2'b11;
	      	endcase
	      	// Fill in missing memory data.
	      	/*
	      	case(memr.hit)
	      	2'b00:	memr.res[ 255:  0] <= {dat_i,dci[0].data[255:128]};
	      	2'b01:	memr.res[ 511:256] <= {dat_i,dci[0].data[255:128]};
	      	2'b10:	memr.res[ 255:  0] <= {dat_i,dci[0].data[255:128]};
	      	2'b11:	;
	      	endcase
	      	*/
	      	tDeactivateBus();
	      	goto (DFETCH7);
	    	end
	    	else
		    	adr_o <= adr_o + 5'd16;
	    	/*
	    	if (!bok_i) begin							// burst mode supported?
	    		cti_o <= wishbone_pkg::CLASSIC;						// no, use normal cycles
	    		goto (DFETCH6);
	    	end
	    	*/
	    end
	  end
  
  // Increment address and bounce back for another read.
  DFETCH6:
		begin
			stb_o <= LOW;
			if (!ack_i)	begin							// wait till consumer ready
				goto (DFETCH5);
			end
		end

	// Trgger a data cache update. The data cache line is in dci. The only thing
	// left to do is update the tag and valid status.
	DFETCH7:
		if (memr.hit==2'b11) begin
			tDeactivateBus();
			// Now that the cache has been loaded, resubmit the memory request.
			ret(1);
		end
		else
			goto(DFETCH2);

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// This subroutine stores a data cache line for writeback cache.
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	DSTORE1:
	  if (!ack_i) begin
			if (dstore1) begin
	  		dstore1 <= 1'b0;
				if (memr.adr[5])
					adr_o <= {memr.adr[AWID-1:6],1'b1,5'h0};
				else
					adr_o <= {memr.adr[AWID-1:6],1'b0,5'h0};
			end
	  	seg_o <= wishbone_pkg::DATA;
	  	bte_o <= wishbone_pkg::LINEAR;
	  	blen_o <= 3'd1;
	  	cti_o <= wishbone_pkg::CLASSIC;
	    cyc_o <= HIGH;
			stb_o <= HIGH;
  		sel_o <= 16'hFFFF;
			dat_o <= memr.res[127:0];
	    tid_o <= {tid_cnt[7:3]+2'd1,3'd0};
    	tid_cnt[7:3] <= tid_cnt[7:3] + 2'd1;
    	tid_cnt[2:0] <= 'd0;
	    goto (DSTORE2);
	  end

	DSTORE2:
    if (ack_i)
  		goto (DSTORE3);
  
  // Increment address and bounce back for another write.
  DSTORE3:
		begin
			stb_o <= LOW;
			if (!ack_i)	begin							// wait till consumer ready
				tid_cnt[2:0] <= tid_cnt[2:0] + 2'd1;
	    	dcnt <= dcnt + 4'd4;
				if (dcnt[4:2]==blen_o) begin
					memr.mod <= 2'b00;
					tDeactivateBus();
					ret(0);
				end
				else
					goto (DSTORE1);
				memr.res <= memr.res >> {5'd16,3'b0};
				adr_o <= adr_o + 5'd16;
			end
		end

`ifdef SUPPORT_HWWALK
`ifdef SUPPORT_HASHPT2
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// Hardware subroutine to find an address translation and update the TLB.
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// 
	IPT_FETCH1:
		begin
			// Open addressing with quadratic probing
//			dadr <= ptbr + {ptg.link,7'h0};
			dadr <= ptbr + ({(hash + square_table[ipt_miss_count]) & 16'hFFFF,6'h0});//ptbr + {ptg.link,7'h0};
	 		xlaten <= FALSE;
	 		wr_ptg <= 1'b0;
	    if (ipt_miss_count==6'd12)
	    	tPageFault(fault_code,miss_adr);
	    else
	    	gosub (IPT_RW_PTG2);
	    if (pte_found) begin
	    	tmptlbe <= tmptlbe2;
	    	goto (IPT_FETCH2);
	    end
		end
	IPT_FETCH2:
		begin
//			tlbwr <= 1'b1;
			tlb_ia <= 'd0;
			tlb_ia[31:20] <= 2'b10;	// write a random way
			tlb_ia[19:15] <= 5'h0;
			tlb_ia[14:0] <= {miss_adr[25:16],5'h0};
			tlb_ib <= tmptlbe;
			tlb_ib.a <= 1'b1;
			tlb_ib.adr <= dadr;
//			wr_ptg <= 1'b1;
//			ptg[entry_num * $bits(PTE) + 132] <= 1'b1;	// The 'a' bit in the pte
//			if (tmptlbe.av)
//				call (IPT_RW_PTG2,IPT_FETCH3);
//			else
			goto (IPT_FETCH3);
		end
	// Delay a couple of cycles to allow TLB update
	IPT_FETCH3:
		begin
//			tlbwr <= 1'b0;
			wr_ptg <= 1'b0;
			if (fault_code==FLT_DPF) begin
				xlaten <= xlaten_stk;
				dadr <= dadr_stk;
				goto (IPT_FETCH4);
			end
			else begin
				xlaten <= xlaten_stk;
				iadr <= iadr_stk;
			  if (!ack_i)
		  		goto (IPT_FETCH4);
			end	
		end
	IPT_FETCH4:
		goto (IPT_FETCH5);
	IPT_FETCH5:
		begin
			// Restore the bus state, it should not miss now.
			tPopBus();
			ret(0);
		end

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// Hardware subroutine to read / write a page table group.
	//
	// Writes only as much as it needs to. For writes just the PTE needs
	// to be updated.
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
`ifdef SOMETHING
	IPT_RW_PTG2:
		begin
			ipt_miss_count <= ipt_miss_count + 2'd1;
	 		xlaten <= FALSE;
			daccess <= TRUE;
			iaccess <= FALSE;
			dcnt <= 'd0;
	  	seg_o <= wishbone_pkg::CODE;
	  	bte_o <= wishbone_pkg::LINEAR;
	  	cti_o <= wishbone_pkg::FIXED;	// constant address burst cycle
	    cyc_o <= HIGH;
			stb_o <= HIGH;
`ifdef SUPPORT_SHPTE
			sel_o <= dadr[3] ? 16'hFF00 : 16'h00FF;
`else
	    sel_o <= 16'hFFFF;
`endif	    
	    we_o <= wr_ptg;
	    // We need only to write the access bit which is in the upper half of
	    // the pte.
  		case(span_lo)
`ifdef SUPPPORT_SHPTE
  		4'd0:	dat_o <= {2{ptg[63:0]}};
  		4'd1: dat_o <= {2{ptg[127:64]}};
  		4'd2:	dat_o <= {2{ptg[191:128]};
  		4'd3:	dat_o <= {2{ptg[255:192]};
  		4'd3:	dat_o <= {2{ptg[319:256]};
  		4'd3:	dat_o <= {2{ptg[383:320]};
  		4'd3:	dat_o <= {2{ptg[447:384]};
  		4'd3:	dat_o <= {2{ptg[511:448]};
`else
  		4'd0:	dat_o <= ptg[255:128];
  		4'd1: dat_o <= ptg[383:256];
  		4'd2:	dat_o <= ptg[511:384];
  		4'd3:	dat_o <= ptg[639:512];
  		4'd4:	dat_o <= ptg[767:640];
  		4'd5: dat_o <= ptg[895:768];
  		4'd6: dat_o <= ptg[1023:895];
  		4'd7: dat_o <= ptg[1151:1024];
  		4'd8:	dat_o <= ptg[1279:1152];
//  		4'd9:	dat_o <= ptg[1407:1280];
//  		4'd10:	dat_o <= ptg[1535:1408];
`endif
  		default:	;
  		endcase
  		if (dce & dhit & ~wr_ptg) begin
  			tDeactivateBus();
  		end
  		goto (IPT_RW_PTG4);
`ifdef SUPPORT_MMU_CACHE  		
			if (!wr_ptg) begin
				for (n4 = 0; n4 < PTGC_DEP; n4 = n4 + 1) begin
					if (ptgc[n4].dadr == dadr && ptgc[n4].v) begin
						tDeactivateBus();
						ptg <= ptgc[n4];
						ret(0);
					end
				end
			end
`endif			
		end
	IPT_RW_PTG4:
		begin
			if (dce & dhit & ~wr_ptg) begin
				ptg <= dc_line;
  			tDeactivateBus();
      	daccess <= FALSE;
`ifdef SUPPORT_MMU_CACHE		      	
      	for (n4 = 1; n4 < PTGC_DEP; n4 = n4 + 1)
      		ptgc[n4] <= ptgc[n4-1];
      	ptgc[0].dadr <= dadr;
`ifdef SUPPORT_SHPTE
    		ptgc[0].ptg <= {dat_i,ptg[383:0]};
`else		      	
    		ptgc[0].ptg <= {dat_i,ptg[1151:0]};
`endif	      		
    		ptgc[0].v <= 1'b1;
`endif	      		
      	ret(0);
			end
			else begin
				if (dce & dhit)
					dci <= dc_line;
				if (wr_ptg) begin
					memreq.func <= MR_STORE;
					/*
					case({dadr[4:3],sel_o})
					18'h000FF:	dci[].data[63:0] <= ptg[63:0];
					18'h0FF00:	dci[127:64] <= ptg[127:64];
					18'h100FF:	dci[191:128] <= ptg[191:128];
					18'h1FF00:	dci[255:192] <= ptg[255:192];
					18'h200FF:	dci[319:256] <= ptg[319:256];
					18'h2FF00:	dci[383:320] <= ptg[383:320];
					18'h300FF:	dci[447:384] <= ptg[447:384];
					18'h3FF00:	dci[511:448] <= ptg[511:448];
					default:		dci <= dc_line;
					endcase
					*/
				end
	  		stb_o <= HIGH;
		    if (ack_i) begin
		    	if (wr_ptg) begin
		      	tDeactivateBus();
		      	daccess <= FALSE;
		      	goto(IPT_RW_PTG6);
		    	end
		    	else begin
			    	case(dcnt[3:0])
			    	4'd0:	ptg[127:  0] <= dat_i;
			    	4'd1: ptg[255:128] <= dat_i;
			    	4'd2:	ptg[383:256] <= dat_i;
			    	4'd3: ptg[511:384] <= dat_i;
`ifndef SUPPORT_SHPTE		    	
			    	4'd4:	ptg[639:512] <= dat_i;
			    	4'd5: ptg[767:640] <= dat_i;
			    	4'd6: ptg[895:768] <= dat_i;
			    	4'd7: ptg[1023:896] <= dat_i;
`endif		    	
	//		    	4'd8: ptg[1151:1024] <= dat_i;
	//		    	4'd9: ptg[1279:1152] <= dat_i;
	//		    	4'd10: 	ptg[1407:1280] <= dat_i;
	//		    	4'd11: 	ptg[1535:1408] <= dat_i;
			    	default:	;
			    	endcase
`ifdef SUPPORT_SHPTE
			      if (dcnt[3:0]==4'd3) begin		// Are we done?
`else		    	
				    if (dcnt[3:0]==rfx32_mmupkg::PtgSize/128-1) begin		// Are we done?
`endif		      	
`ifdef SUPPORT_MMU_CACHE		      	
			      	for (n4 = 1; n4 < PTGC_DEP; n4 = n4 + 1)
			      		ptgc[n4] <= ptgc[n4-1];
			      	ptgc[0].dadr <= dadr;
`ifdef SUPPORT_SHPTE
		      		ptgc[0].ptg <= {dat_i,ptg[383:0]};
`else		      	
		      		ptgc[0].ptg <= {dat_i,ptg[1151:0]};
`endif	      		
		      		ptgc[0].v <= 1'b1;
`endif	      		
			      	tDeactivateBus();
			      	daccess <= FALSE;
			      	ret(0);
			    	end
			    	else if (!bok_i) begin				// burst mode supported?
			    		cti_o <= wishbone_pkg::CLASSIC;						// no, use normal cycles
			    		goto (IPT_RW_PTG5);
			    	end
				  end
		      dcnt <= dcnt + 2'd1;					// increment word count
		    end
	  	end
  	end
  // Increment address and bounce back for another read.
  IPT_RW_PTG5:
		begin
			stb_o <= LOW;
			if (!ack_i)	begin							// wait till consumer ready
				inext <= TRUE;
				goto (IPT_RW_PTG4);
			end
		end
	IPT_RW_PTG6:
		ret(0);

	IPT_WRITE_PTE:
		begin
			ptg <= 'd0;
`ifdef SUPPORT_SHPTE
			ptg <= tlb_dat[63:0] << (tlb_dat.en * $bits(SHPTE));	// will cause entry_num to be zero.
`else
			ptg <= tlb_dat[159:0] << (tlb_dat.en * $bits(PTE));	// will cause entry_num to be zero.
`endif
			case(tlb_dat.en)
`ifdef SUPPORT_SHPTE
			3'd0:	dadr <= tlb_dat.adr;
			3'd1:	dadr <= tlb_dat.adr + 12'd8;
			3'd2:	dadr <= tlb_dat.adr + 12'd16;
			3'd3:	dadr <= tlb_dat.adr + 12'd24;
			3'd4:	dadr <= tlb_dat.adr + 12'd32;
			3'd5:	dadr <= tlb_dat.adr + 12'd40;
			3'd6:	dadr <= tlb_dat.adr + 12'd48;
			3'd7:	dadr <= tlb_dat.adr + 12'd56;
`else				
			3'd0:	dadr <= tlb_dat.adr;
			3'd1:	dadr <= tlb_dat.adr + 12'd16;
			3'd2:	dadr <= tlb_dat.adr + 12'd48;
			3'd3:	dadr <= tlb_dat.adr + 12'd64;
			3'd4:	dadr <= tlb_dat.adr + 12'd96;
			3'd5:	dadr <= tlb_dat.adr + 12'd112;
			3'd6:	dadr <= tlb_dat.adr + 12'd144;
			3'd7:	dadr <= tlb_dat.adr + 12'd160;
`endif			
			endcase
			tInvalidatePtgc(tlb_dat.adr,tlb_dat.adr + 12'd160);
			miss_adr <= {tlb_dat.vpn,16'd0};
			wr_ptg <= 1'b1;
			goto (IPT_RW_PTG2);
		end

`endif
`endif	// SOMETHING

`ifdef SUPPORT_HIERPT
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// Hardware subroutine to find an address translation and update the TLB.
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	PT_FETCH1:
		begin
			dep <= ptbr[10:8];
			wr_pte <= 1'b0;
	  	case(ptbr[10:8])
	  	3'd1:
	  		begin
	  			pte.ppn <= ptbr[31:14];
	  			pte.lvl <= 3'd0;
	  			pte.m <= 1'b0;
	  			pte.a <= 1'b1;
	  			pte.v <= 1'b1;
	  			adr_slice <= miss_adr[25:14];
	  			if (miss_adr[AWID-1:26] != 'd0 && miss_adr[AWID-1:26] != {AWID-26{1'b1}})
	  				tPageFault(0,miss_adr);
	  			else
	  				call (PT_RW_PTE1, PT_FETCH3);
	  		end
	  	3'd2:
	  		begin
	  			pde.ppn <= ptbr[31:14];
	  			pde.v <= 1'b1;
	  			pde.d <= 1'b0;
	  			pde.a <= 1'b1;
	  			pde.lvl <= 3'd1;
	  			adr_slice <= miss_adr[31:26];	// [40:28]
	  			call (PT_RW_PDE1, PT_FETCH2);
	  		end // 8 bits
	  	/*
	  	3'd3:	
	  		begin
	  			pde <= ptbr[31:12];
	  			pde.v <= 1'b1;
	  			pde.d <= 1'b0;
	  			pde.a <= 1'b1;
	  			pde.lvl <= 3'd3;
	  			adr_slice <= miss_adr[53:41];
	  			call (PT_RW_PDE1, PT_FETCH2);
	  		end // 13 bits
	  	3'd4:
	  		begin
	  			pde <= ptbr[31:12];	
	  			pde.v <= 1'b1;
	  			pde.d <= 1'b0;
	  			pde.a <= 1'b1;
	  			pde.lvl <= 3'd4;
	  			adr_slice <= miss_adr[66:54];
	  			call (PT_READ_PDE1, PT_FETCH2);
	  		end // 13 bits
	  	3'd5:
	  		begin
	  			pde <= ptbr[31:12];
	  			pde.v <= 1'b1;
	  			pde.d <= 1'b0;
	  			pde.a <= 1'b1;
	  			pde.lvl <= 3'd5;
	  			adr_slice <= miss_adr[79:67];
	  			call (PT_READ_PDE1, PT_FETCH2);
	  		end // 13 bits
	  	*/
	  	default:	ret(0);
	  	endcase
		end
	PT_FETCH2:
	  begin
	  	if (pde.lvl >= dep)
	  		tPageFault(FLT_LVL,adr_o); 
	  	else
		  	case(dep)
		  	3'd1:
		  		begin
		  			pte.ppn <= pde.ppn;
		  			adr_slice <= miss_adr[25:14];
		  			call (PT_RW_PTE1, PT_FETCH3);
		  		end
/*		  	
		  	3'd2:
		  		begin
		  			adr_slice <= miss_adr[31:28];	// [40:28];
	  				gosub (PT_RW_PDE1);
	  				dep <= pde.lvl;
		  		end // 13 bits
			  3'd3:
			  	begin
			  		adr_slice <= miss_adr[53:41];
			  		gosub (PT_RW_PTE1);
			  		dep <= pde.lvl;
			  	end // 13 bits
		  	3'd4:
		  		begin
		  			adr_slice <= miss_adr[66:54];
		  			gosub (PT_READ_PDE1);
		  			dep <= pde.lvl;
		  		end // 13 bits
		  	3'd5:
		  		begin
		  			adr_slice <= miss_adr[79:67];
		  			gosub (PT_READ_PDE1);
		  			dep <= pde.lvl;
		  		end // 13 bits
*/		  		
		  	default:	ret(0);
		  	endcase
	  end
	PT_FETCH3:
		begin
//			tlbwr <= 1'b1;
			tlb_ia <= 'd0;
			tlb_ib <= 'd0;
			tlb_ia[31] <= 1'b1;	// write to tlb
			tlb_ia[15:14] <= 2'b10;	// write a random way
			tlb_ia[13:10] <= 4'h0;
			tlb_ia[9:0] <= miss_adr[23:14];
			tlb_ib.ppn <= pte.ppn;
			tlb_ib.d <= pte.d;
			tlb_ib.u <= pte.u;
			tlb_ib.s <= pte.s;
			tlb_ib.a <= pte.a;
			tlb_ib.c <= pte.c;
			tlb_ib.r <= pte.r;
			tlb_ib.w <= pte.w;
			tlb_ib.x <= pte.x;
			tlb_ib.sc <= pte.sc;
			tlb_ib.sr <= pte.sr;
			tlb_ib.sw <= pte.sw;
			tlb_ib.sx <= pte.sx;
			tlb_ib.v <= pte.v;
			tlb_ib.g <= pte.g;
			tlb_ib.bc <= pte.lvl;
			tlb_ib.n <= pte.n;
			tlb_ib.av <= pte.av;
			tlb_ib.mb <= pte.mb;
			tlb_ib.me <= pte.me;
			tlb_ib.adr <= dadr;
			pte.a <= 1'b1;
//			tlb_ib <= tmptlbe;
			tlb_ib.a <= 1'b1;
			wr_pte <= 1'b1;
			goto (PT_FETCH4);
		end
	PT_FETCH4:
		begin
//			tlbwr <= 1'b0;
			wr_pte <= 1'b0;
			xlaten <= xlaten_stk;
			if (fault_code==FLT_DPF) begin
				dadr <= dadr_stk;
				goto (PT_FETCH5);
			end
			else begin
				iadr <= iadr_stk;
			  if (!ack_i)
		  		goto (PT_FETCH5);
			end	
		end
	// Delay a couple of cycles to allow TLB update
	PT_FETCH5:
		begin
			goto (PT_FETCH6);
		end
	PT_FETCH6:
		begin
			// Restore the bus state, it should not miss now.
			tPopBus();
			ret(0);
		end

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// Hardware subroutine to read or write a PTE.
	// If the PTE is not valid then a page fault occurs.
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	PT_RW_PTE1:
		begin
	 		xlaten <= FALSE;
			daccess <= TRUE;
			iaccess <= FALSE;
			dadr <= {pte.ppn,adr_slice[11:0],2'h0};
			goto (PT_RW_PTE3);
		end
`endif
	PT_RW_PTE2:
		goto (PT_RW_PTE3);
	PT_RW_PTE3:
		if (!ack_i) begin
			seg_o <= wishbone_pkg::DATA;
	  	bte_o <= wishbone_pkg::LINEAR;
	  	blen_o <= 'd0;
	  	cti_o <= wishbone_pkg::CLASSIC;
	    cyc_o <= HIGH;    
			stb_o <= HIGH;
			we_o <= wr_pte;
	    sel_o <= 16'hFFFF;
	    dat_o <= pte;
	    goto (PT_RW_PTE4);
		end
	PT_RW_PTE4:
		if (ack_i) begin
			tDeactivateBus();
			if (!wr_pte)
				pte <= dat_i >> {adr_o[3:2],5'd0};
			goto (PT_RW_PTE5);
		end
	PT_RW_PTE5:
		begin
			if (pte.v)
				ret(0);
			else
				tPageFault(fault_code,miss_adr);
		end
	
	PT_WRITE_PTE:
		begin
	 		xlaten <= FALSE;
			daccess <= TRUE;
			iaccess <= FALSE;
			wr_pte <= TRUE;
			pte <= tlb_dat;
			dadr <= {tlb_adr[AWID-1:2],2'h0};
			miss_adr <= {tlb_adr[AWID-1:2],2'h0};
			goto (PT_RW_PTE2);
		end

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// Hardware subroutine to read or write a PDE.
	// If the PDE is not valid then a page fault occurs.
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	PT_RW_PDE1:
		begin
			goto (PT_RW_PDE3);
	 		xlaten <= FALSE;
			daccess <= TRUE;
			iaccess <= FALSE;
			dadr <= {pde.ppn,adr_slice[11:0],2'h0};
`ifdef SUPPORT_MMU_CACHE			
			if (!wr_pte)
				for (n4 = 0; n4 < 12; n4 = n4 + 1)
					if (ptc[n4].adr=={pde.ppn,adr_slice[11:0],2'h0} && ptc[n4].v) begin
						pde <= ptc[n4].pde;
						ret(0);
					end
`endif					
		end
	PT_RW_PDE3:
		if (!ack_i) begin
			seg_o <= wishbone_pkg::DATA;
	  	bte_o <= wishbone_pkg::LINEAR;
	  	blen_o <= 'd0;
	  	cti_o <= wishbone_plg::CLASSIC;
	    cyc_o <= HIGH;    
			stb_o <= HIGH;
			we_o <= wr_pte;
	    sel_o <= 16'hFFFF;
	    dat_o <= pde;
	    goto (PT_RW_PDE4);
		end
	PT_RW_PDE4:
		if (ack_i) begin
			tDeactivateBus();
			if (!wr_pte)
				pde <= dat_i >> {adr_slice[1:0],5'h0};
			pde.padr <= adr_o;
			goto (PT_RW_PDE5);
		end
	PT_RW_PDE5:
		begin
			if (pde.v) begin
`ifdef SUPPORT_MMU_CACHE				
				for (n4 = 0; n4 < 11; n4 = n4 + 1)
					ptc[n4+1] <= ptc[n4];
				ptc[0].v <= 1'b1;
				ptc[0].adr <= dadr;
				ptc[0].pde <= pde;
`endif				
				ret(0);
			end
			else
				tPageFault(fault_code,miss_adr);
		end
`endif	// SUPPORT_HWWALK

	default:
		goto (MEMORY_IDLE);
	endcase
end

task tInvalidatePtgc;
input address_t adrlo;
input address_t adrhi;
integer n5;
begin
`ifdef SUPPORT_MMU_CACHE
	for (n5 = 0; n5 < PTGC_DEP; n5 = n5 + 1)
		if (ptgc[n5].dadr >= adrlo && ptgc[n5].dadr <= adrhi)
			ptgc[n5].v <= 1'b0;
`endif			
end
endtask


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Start of memory pipeline.
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
always_comb
	mem_pipe_adv = !memresp_full;

// memreq_rd cannot be used to signal the start of pipeline loading of mem_resp
// as it must pulse only once for each read of the fifo. If it is held the fifo
// would be emptied out incorrectly. wasrd is the sticky version of signal
// needed in case the pipeline is stalled.
reg wasrd;

// Add request to pipeline
task tStage0;
begin
	if (mem_pipe_adv)
		wasrd <= FALSE;
//	memreq_rd <= FALSE;
	memr_fed <= FALSE;
	xlaten <= FALSE;
//	if (!fifoToCtrl_empty && tlbrdy && !memr_v) begin
//		memreq_rd <= TRUE;
	if (memreq_rd) begin
		wasrd <= TRUE;
	end
	mem_resp[0] <= 'd0;
	if (wasrd) begin
		if (mem_pipe_adv) begin
			if (itlbrdy&dtlbrdy) begin
				if (tlb_cyc) begin
					mem_resp[0].func <= MR_TLB;
					mem_resp[0].adr <= {tlb_adr[AWID-1:5],5'h0} + 5'd16;
					rb_bitmaps2[imemreq.thread][imemreq.tgt] <= 1'b1;
				end
				else if (fifoToCtrl_v) begin
					if (imemreq.tid != mem_resp[0].tid) begin
						xlaten <= imemreq.omode != 2'd3;
						mem_resp[0] <= imemreq;
						mem_resp[0].v <= 1'b1;
						rb_bitmaps2[imemreq.thread][imemreq.tgt] <= 1'b1;
					end
					else begin
						mem_resp[0] <= 'd0;
						mem_resp[0].tid <= mem_resp[0].tid;
					end
				end
			end
		end
		// Hold onto the request if pipe could not advance.
		else
			mem_resp[0] <= 'd0;//mem_resp[0];
	end
	// If there is an empty spot, insert an outstanding memory request that
	// missed on a data cache read.
	else begin
		if (mem_pipe_adv) begin
			if (itlbrdy&dtlbrdy) begin
				if (memr_v) begin
					xlaten <= memr.omode != 2'd3;
					mem_resp[0] <= memr_hold;
					mem_resp[0].v <= 1'b1;
					rb_bitmaps2[memr.thread][memr.tgt] <= 1'b1;
					memr_fed <= TRUE;
					memr_v <= FALSE;
				end
				else if (tlb_cyc) begin
					mem_resp[0].func <= MR_TLB;
					mem_resp[0].adr <= {tlb_adr[AWID-1:5],5'h0} + 5'd16;
					rb_bitmaps2[imemreq.thread][imemreq.tgt] <= 1'b1;
				end
				else if (fifoToCtrl_v) begin
					if (imemreq.tid != mem_resp[0].tid) begin
						xlaten <= imemreq.omode != 2'd3;
						mem_resp[0] <= imemreq;
						mem_resp[0].v <= 1'b1;
						rb_bitmaps2[imemreq.thread][imemreq.tgt] <= 1'b1;
					end
					else begin
						mem_resp[0] <= 'd0;
						mem_resp[0].tid <= mem_resp[0].tid;
					end
				end
			end
		end
		// Hold onto the request if pipe could not advance.
		else
			mem_resp[0] <= 'd0;//mem_resp[0];
	end
	if (mem_pipe_adv)
		mp_delay <= 4'd0;
	else
		mp_delay <= mp_delay + 2'd1;
end
endtask

// Stage 1
// Perform cache operation
// Setup access to special memory mapped entities
// Compute select lines for memory access

task tStage1;
begin
	if (mem_pipe_adv) begin
		tlb_access <= 1'b0;
		ptgram_en <= 1'b0;
		pde_en <= FALSE;
		mem_resp[1] <= mem_resp[0];
		mem_resp[1].cause <= FLT_NONE;
		if (mem_resp[0].func==MR_CACHE) begin
			ic_invline <= mem_resp[0].res[2:0]==3'd1;
			ic_invall	<= mem_resp[0].res[2:0]==3'd2;
			dc_invline <= mem_resp[0].res[5:3]==3'd3;
			dc_invall	<= mem_resp[0].res[5:3]==3'd4;
			if (mem_resp[0].res[5:3]==3'd1)
				dce <= TRUE;
			if (mem_resp[0].res[4:2]==3'd2)
				dce <= FALSE;
	    mem_resp[1].cmt <= TRUE;
			mem_resp[1].wr <= TRUE;
			mem_resp[1].res <= 'd0;
		end
		else if ((mem_resp[0].func==MR_LOAD || mem_resp[0].func==MR_LOADZ || mem_resp[0].func==MR_STORE || 
//			mem_resp[0].func==MR_TLBRD || mem_resp[0].func==MR_TLBRW ||
			mem_resp[0].func==MR_ICACHE_LOAD) && mem_resp[0].v) begin
			// For a store, select lines are shifted into position during data cache
			// line masking. Do not shift them here.
			if (mem_resp[0].func == MR_STORE)
				mem_resp[1].sel <= mem_resp[0].sel;
			// Check if the select lines have been shifted already by testing bit 0.
			else if (mem_resp[0].sel[0])
	    	mem_resp[1].sel <= {32'h0,mem_resp[0].sel} << mem_resp[0].adr[3:0];
			casez(mem_resp[0].adr)
			32'hFFA?????:
				begin
					mem_resp[1].ptgram_en <= 1'b1;
					ptgram_en <= 1'b1;
					ptgram_wr <= mem_resp[0].func==MR_STORE;
				end
			32'hFFD?????:
				begin
				end
			32'hFFE0????:
				begin
//					itlbwr <= mem_resp[0].func==MR_TLBRW && ~mem_resp[0].adr[4];
//					dtlbwr <= mem_resp[0].func==MR_TLBRW &&  mem_resp[0].adr[4];
					mem_resp[1].tlb_access <= 1'b1;
					tlb_access <= 1'b1;
					tlb_ia <= mem_resp[0].adr[15:0];
					tlb_ib <= mem_resp[0].res;
				end
			32'hFFEF????:
				begin
					mem_resp[1].pde_en <= 1'b1;
					pde_wr <= mem_resp[0].func==MR_STORE;
					pde_en <= 1'b1;
				end
			default:	;
			endcase
			pde_adr <= {mem_resp[0].thread,mem_resp[0].adr[7:2]};
			pde_dat <= mem_resp[0].res[$bits(PDE)-1:0];
`ifdef SUPPORT_HASHPT
			ptgram_adr <= mem_resp[0].adr[18:4];
			ptgram_dati <= mem_resp[0].res;
`endif
		end
	end
end
endtask

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// End of memory pipeline.
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Sequencer states
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

// Use original_ip to hold onto the original ip value. The ip value might
// change during a cache load due to a branch. We also want the start
// of the cache line identified as the access will span into the next
// cache line.

task tBeginIFetch;
begin
	waycnt <= waycnt + 2'd1;
	original_ip <= {memr.adr[$bits(address_t)-1:5],5'b0};
	first_ifetch <= TRUE;
	goto (IFETCH1);
	tid_cnt[7:3] <= tid_cnt[7:3] + 2'd1;
	tid_cnt[2:0] <= 'd0;
end
endtask

task tBeginStore;
begin
`ifdef SUPPORT_HWWALK    		
	// Invalidate PTCEs when a store occurs to the PDE
	for (n4 = 0; n4 < 12; n4 = n4 + 1)
		if (ptc[n4].pde.padr[AWID-1:4]==memr.adr[AWID-1:4])
			ptc[n4].v <= 1'b0;
`endif						
	seg_o <= wishbone_pkg::DATA;
	bte_o <= wishbone_pkg::LINEAR;
	blen_o <= 3'd0;
	cti_o <= wishbone_pkg::CLASSIC;
	cyc_o <= HIGH;
	stb_o <= HIGH;
	we_o <= HIGH;
	sel_o <= memr_sel[15:0];
	if (stk_dep=='d1)
		adr_o <= {memr.adr[31:4],4'd0};
	else
		adr_o <= adr_o + 5'd16;
	dat_o <= memr_res[127:0];
	dat <= memr_res[127:0];
	csr_o <= memr.func2==MR_STCR;
  tid_o <= {tid_cnt[7:3] + 2'd1,3'd0};
	tid_cnt[7:3] <= tid_cnt[7:3] + 2'd1;
	tid_cnt[2:0] <= 'd0;
	wr_reqtbl <= 1'b1;
	goto (MEMORY_ACK);
end
endtask

task tBeginLoad;
begin
	// It was cachable data and a miss occurred. Fetch the data and return
	// a miss status to the execute unit so it will try again.
	// If the line was modified, write it out first.
	if (memr.acr[3]) begin
		if (|memr.mod)
			gosub(DSTORE1);
		else
			goto (DFETCH2);
	end
	// Otherwise non-cacheable data, begin a load operation.
	else begin
		seg_o <= wishbone_pkg::DATA;
  	bte_o <= wishbone_pkg::LINEAR;
  	blen_o <= 3'd0;
		cti_o <= wishbone_pkg::CLASSIC;
		cyc_o <= HIGH;
		stb_o <= HIGH;
		we_o <= LOW;
		sel_o <= memr_sel[15:0];
		if (stk_dep=='d1)
  		adr_o <= {memr.adr[31:4],4'd0};
  	else
  		adr_o <= adr_o + 5'd16;
//		csr_o <= memr.func2==MR_LDR;
    tid_o <= {tid_cnt[7:3] + 2'd1,3'd0};
  	tid_cnt[7:3] <= tid_cnt[7:3] + 2'd1;
  	tid_cnt[2:0] <= 'd0;
  	wr_reqtbl <= 1'b1;
		goto (MEMORY_ACK);
	end
end
endtask

task tMemoryActivate;
begin
	dfetch2 <= 1'b0;
	dstore1 <= 1'b0;
	strips <= 2'd0;
	dcnt <= 'd0;
	case(memr.func)
	MR_STORE,MR_MOVST:	tBeginStore();
	// Trim a cycle off of I$ update by starting the access here.
	MR_ICACHE_LOAD:			tBeginIFetch();
	MR_LOAD,MR_LOADZ:		tBeginLoad();
	// Other operations should have been filtered out by the memory pipeline.
	default:	ret(0);	// unknown operation
	endcase
end
endtask

task tMemoryAck;
begin
	case(memr.func)
	MR_STORE,MR_MOVST:
		if (ack_i || !stb_o) begin
		  goto (MEMORY_NACK);
      stb_o <= LOW;
    end
  MR_LOAD,MR_LOADZ:
    if (ack_i || !stb_o) begin
      goto (MEMORY_NACK);
      stb_o <= LOW;
    end
  default:	ret(0);
	endcase
end
endtask

task tMemoryNack;
begin
  if (~ack_i) begin
   	memr_sel <= memr_sel >> 16;
    case(memr.func)
    MR_LOAD,MR_LOADZ,MR_MOVLD:
    	begin
	    	case(adr_o[6:4])
	    	3'd0:	dati[127:  0] <= dat_i;
	    	3'd1:	dati[255:128] <= dat_i;
	    	3'd2:	dati[383:256] <= dat_i;
	    	3'd3:	dati[511:384] <= dat_i;
	    	3'd4:	dati[639:512] <= dat_i;
	    	3'd5:	dati[767:640] <= dat_i;
	    	3'd6: dati[895:768] <= dat_i;
	    	3'd7: dati[1023:896] <= dat_i;
	    	default:	;
	    	endcase
		    if (|memr_sel[31:16]) begin
		    	// Recursive call, goes a max of eight deep.
	  	    gosub (MEMORY_ACTIVATE);
	  	  end
	  	  else begin
	  	  	if (memr_sel[127:16]=='d0) begin
    				tDeactivateBus();
	        	goto (DATA_ALIGN);
	        end
	      end
    	end
    MR_STORE,MR_MOVST:
    	begin
		    if (|memr_sel[31:16]) begin
      		memr_res <= memr_res >> 128;
		    	// Recursive call, goes a max of eight deep.
		    	gosub (MEMORY_ACTIVATE);
			  end
			  else begin
			  	if (memr_sel[127:16]=='d0) begin
		    		if (memr.func2==MR_STPTR) begin	// STPTR
				    	if (~|ea[AWID-5:0]) begin// || shr_ma[5:3] >= region.at[18:16]) begin
								if (!memresp_full)
									ret(0);
				    	end
				    	else begin
//				    		if (shr_ma=='d0) begin
//				    			cta <= region.cta;
				    			// Turn request address into an index into region
//				    			memreq.adr <= memreq.adr - region.start;
//				    		end
				    		shr_ma <= shr_ma + 4'd8;
				    		zero_data <= TRUE;
				    		goto (MEMORY_DISPATCH);
				    	end
		    		end
		    		else begin
		    			tDeactivateBus();
							if (!memresp_full) begin
								if (|memr.hit[1:0]) begin
									//if (memr.adr[5])
									//	dci <= {dci[0],dci[1]};
									goto (MEMORY_UPD1);
								end
								else
									ret(0);
							end
			      end
		    	end
	    	end
    	end
    default:
    	begin
    		ret(0);
    	end
    endcase
  end
end
endtask

task tAlignFaultDetect;
input wb_cmd_request512_t req;
output cause_code_t code;
begin
	code <= FLT_NONE;
	case(req.sz)
	rfx32pkg::nul:		;		
	rfx32pkg::byt:		;
	rfx32pkg::wyde: 	if (req.vadr[5:0]==6'h3F) code <= FLT_ALN;
	rfx32pkg::tetra:	if (req.vadr[5:0] >6'h3C) code <= FLT_ALN;
	rfx32pkg::octa:	if (req.vadr[5:0] >6'h38) code <= FLT_ALN;
	rfx32pkg::hexi:	if (req.vadr[5:0] >6'h30) code <= FLT_ALN;
	default:	if (req.vadr[5:0]!=6'h00) code <= FLT_ALN;
	endcase
end
endtask

// This data align is for non-cached data.

task tDataAlign;
input wb_cmd_request512_t req;
input [7:0] bytcnt;
output memory_arg_t resp;
begin
  case(req.cmd)
  CMD_LOAD:
  	begin
			case(bytcnt)
			8'd0:	resp.res <= 'h0;
			8'd1:	begin resp.res <= {{120{datis[7]}},datis[7:0]}; end
			8'd2:	begin resp.res <= {{112{datis[15]}},datis[15:0]}; end
			8'd3:	begin resp.res <= {{104{datis[23]}},datis[23:0]}; end
			8'd4:	begin resp.res <= {{96{datis[31]}},datis[31:0]}; end
			8'd5:	begin resp.res <= {{88{datis[39]}},datis[39:0]}; end
			8'd6:	begin resp.res <= {{80{datis[47]}},datis[47:0]}; end
			8'd7:	begin resp.res <= {{72{datis[55]}},datis[55:0]}; end
			8'd8:	begin resp.res <= {{64{datis[63]}},datis[63:0]}; end
			8'd9:	begin resp.res <= {{56{datis[71]}},datis[71:0]}; end
			8'd10:	begin resp.res <= {{48{datis[79]}},datis[79:0]}; end
			8'd11:	begin resp.res <= {{40{datis[87]}},datis[87:0]}; end
			8'd12:	begin resp.res <= {{32{datis[95]}},datis[95:0]}; end
			8'd13:	begin resp.res <= {{24{datis[103]}},datis[103:0]}; end
			8'd14:	begin resp.res <= {{16{datis[111]}},datis[111:0]}; end
			8'd15:	begin resp.res <= {{ 8{datis[119]}},datis[119:0]}; end
			8'd16:	begin resp.res <= datis[127:0]; end
			8'd64:	begin resp.res <= datis[511:0]; end
			default:	resp.res <= datis[511:0];
			endcase
		end
  CMD_LOADZ:
  	begin
			case(bytcnt)
			8'd0:	resp.res <= 'h0;
			8'd1:	begin resp.res <= {{120{1'b0}},datis[7:0]}; end
			8'd2:	begin resp.res <= {{112{1'b0}},datis[15:0]}; end
			8'd3:	begin resp.res <= {{104{1'b0}},datis[23:0]}; end
			8'd4:	begin resp.res <= {{96{1'b0}},datis[31:0]}; end
			8'd5:	begin resp.res <= {{88{1'b0}},datis[39:0]}; end
			8'd6:	begin resp.res <= {{80{1'b0}},datis[47:0]}; end
			8'd7:	begin resp.res <= {{72{1'b0}},datis[55:0]}; end
			8'd8:	begin resp.res <= {{64{1'b0}},datis[63:0]}; end
			8'd9:	begin resp.res <= {{56{1'b0}},datis[71:0]}; end
			8'd10:	begin resp.res <= {{48{1'b0}},datis[79:0]}; end
			8'd11:	begin resp.res <= {{40{1'b0}},datis[87:0]}; end
			8'd12:	begin resp.res <= {{32{1'b0}},datis[95:0]}; end
			8'd13:	begin resp.res <= {{24{1'b0}},datis[103:0]}; end
			8'd14:	begin resp.res <= {{16{1'b0}},datis[111:0]}; end
			8'd15:	begin resp.res <= {{ 8{1'b0}},datis[119:0]}; end
			8'd16:	begin resp.res <= datis[127:0]; end
			8'd64:	begin resp.res <= datis[511:0]; end
			default:	resp.res <= datis[511:0];
			endcase
		end
  default:  ;
  endcase
end
endtask


// TLB miss processing
//
// TLB misses may be handled by either software or hardware.
// Software handling terminates the current bus cycle then sends an exception
// response back to the mainline.
// Hardware handling pushes the current bus cycle on a stack then terminates
// the current bus cycle. Next a hardware subroutine is called to walk the 
// page tables and update the TLB with a translation.

// Page faults occur only during hardware page table walks when a translation
// cannot be found.

task tPageFault;
input cause_code_t typ;
input address_t ba;
begin
	/*
	memresp.step <= memreq.step;
	memresp.cmt <= TRUE;
  memresp.cause <= typ;
	memresp.tid <= memreq.tid;
  memresp.adr <= ba;
  memresp.wr <= TRUE;
	memresp.res <= 128'd0;
	*/
	tDeactivateBus();
	if (!memresp_full)
		goto (MEMORY_IDLE);
end
endtask

task tKeyViolation;
input address_t ba;
begin
	/*
	memresp.step <= memreq.step;
	memresp.cmt <= TRUE;
  memresp.cause <= FLT_KEY;
	memresp.tid <= memreq.tid;
  memresp.adr <= ba;
  memresp.wr <= TRUE;
	memresp.res <= 128'd0;
	*/
	tDeactivateBus();
	if (!memresp_full)
		goto (MEMORY_IDLE);
end
endtask

`ifdef SUPPORT_KEYCHK
task tKeyCheck;
input [6:0] nst;
begin
	if (!kyhit)
		gosub(KYLD);
	else begin
		goto (KEYCHK_ERR);
		for (n = 0; n < 8; n = n + 1)
			if (kyut == keys[n] || kyut==20'd0)
				goto(nst);
	end
	if (memreq.func==MR_CACHE)
  	tPMAEA();
  if (adr_o[31:16]==IO_KEY_ADR) begin
  	/*
		memresp.cause <= FLT_NONE;
  	memresp.step <= memreq.step;
  	memresp.cmt <= TRUE;
  	memresp.res <= io_keys[adr_o[12:2]];
  	memresp.wr <= TRUE;
  	if (memreq.func==MR_STORE) begin
  		io_keys[adr_o[12:2]] <= memreq.res[19:0];
  	end
  	*/
		if (!memresp_full)
	  	ret(0);
	end
end
endtask
`endif

/* Probably dead code, wanted for reference to key violation.
task tPMAEA;
input wr;
input tlbwr;
begin
	we_o <= 1'b0;
  if (keyViolation && omode == 2'd0)
  	tKeyViolation(adr_o);
  // PMA Check
 	we_o <= wr & tlbwr & region.at[1];
  if (wr && !region.at[1])
  	tWriteViolation(dadr);
  else if (~wr && !region.at[2])
    tReadViolation(dadr);
//	memresp.cause <= {4'h8,FLT_PMA};
	dcachable <= dcachable & region.at[3];
end
endtask
*/

task tDeactivateBus;
begin
//	seg_o <= wishbone_pkg::DATA;
	bte_o <= wishbone_pkg::LINEAR;
	blen_o <= 'd0;
	cti_o <= wishbone_pkg::CLASSIC;	// Normal cycles again
	cyc_o <= LOW;
	stb_o <= LOW;
	we_o <= LOW;
	sel_o <= 16'h0000;
	csr_o <= LOW;
  xlaten <= FALSE;
end
endtask

task tPushBus;
begin
	xlaten_stk <= xlaten;
	seg_stk <= seg_o;
	bte_stk <= bte_o;
	blen_stk <= blen_o;
	cti_stk <= cti_o;
	cyc_stk <= cyc_o;
	stb_stk <= stb_o;
	we_stk <= we_o;
	sel_stk <= sel_o;
	dadr_stk <= dadr;
	iadr_stk <= iadr;
	dato_stk <= dat_o;
end
endtask

task tPopBus;
begin
	xlaten <= xlaten_stk;
	seg_o <= seg_stk;
	bte_o <= bte_stk;
	blen_o <= blen_stk;
	cti_o <= cti_stk;
	cyc_o <= cyc_stk;
	stb_o <= stb_stk;
	we_o <= we_stk;
	sel_o <= sel_stk;
//	dadr <= dadr_stk;
//	iadr <= iadr_stk;
	dat_o <= dato_stk;
end
endtask

task goto;
input [6:0] nst;
begin
	state <= nst;
end
endtask

task call;
input [6:0] nst;
input [6:0] rst;
begin
	stk_state[stk_dep] <= rst;
	stk_dep <= stk_dep+2'd1;
	state <= nst;
end
endtask

task push;
begin
	stk_state[stk_dep] <= state;
	stk_dep <= stk_dep+2'd1;
end
endtask

task gosub;
input [6:0] nst;
begin
	push();
	state <= nst;
end
endtask

task ret;
input loop;
integer n;
begin
	if (loop) begin
		if (!memr_fed)
			memr_v <= TRUE;
		else begin
			state <= stk_state[stk_dep-2'd1];
			stk_dep <= stk_dep - 2'd1;
		end
	end
	else begin
		state <= stk_state[stk_dep-2'd1];
		stk_dep <= stk_dep - 2'd1;
	end
end
endtask

endmodule

module biu_dati_align(dati, datis, amt);
input [1023:0] dati;
output reg [511:0] datis;
input [9:0] amt;

reg [1023:0] shift0;
reg [1023:0] shift1;
reg [1023:0] shift2;
reg [1023:0] shift3;
reg [1023:0] shift4;
always_comb
begin
	datis = dati >> amt;
	/*
	shift0 = dati >> {amt[9:8],8'd0};
	shift1 = shift0 >> {amt[7:6],6'd0};
	shift2 = shift1 >> {amt[5:4],4'd0};
	shift3 = shift2 >> {amt[3:2],2'd0};
	shift4 = shift3 >> amt[1:0];
	datis = shift4[127:0];
	*/
end

endmodule
