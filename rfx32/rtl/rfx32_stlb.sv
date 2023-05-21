// ============================================================================
//        __
//   \\__/ o\    (C) 2020-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfx32_stlb.sv
//	- shared TLB
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
// 1649 LUTs / 1907 FFs / 12 BRAMs
// ============================================================================

import fta_bus_pkg::*;
import rfx32pkg::*;
import rfx32Mmupkg::*;

module rfx32_stlb(rst_i, clk_i, rdy_o,	rwx_o, tlbmiss_irq_o,
	wbn_req_i, wbn_resp_o, fta_req_o, fta_resp_i, snoop_v, snoop_adr, snoop_cid);
parameter ASSOC = 6;	// MAX assoc = 15
parameter LVL1_ASSOC = 1;
parameter CHANNELS = 4;
parameter RSTIP = 32'hFFFD0000;
parameter PAGE_SIZE = 16384;
localparam LOG_PAGE_SIZE = $clog2(PAGE_SIZE);
localparam LOG_ENTRIES = $clog2(ENTRIES);

parameter IO_ADDR = 32'hFEF00001;
parameter IO_ADDR2 = 32'hFEEF0001;
parameter IO_ADDR_MASK = 32'h00FF0000;

parameter CFG_BUS = 8'd0;
parameter CFG_DEVICE = 5'd12;
parameter CFG_FUNC = 3'd0;
parameter CFG_VENDOR_ID	=	16'h0;
parameter CFG_DEVICE_ID	=	16'h0;
parameter CFG_SUBSYSTEM_VENDOR_ID	= 16'h0;
parameter CFG_SUBSYSTEM_ID = 16'h0;
parameter CFG_ROM_ADDR = 32'hFFFFFFF0;

parameter CFG_REVISION_ID = 8'd0;
parameter CFG_PROGIF = 8'd1;
parameter CFG_SUBCLASS = 8'h00;					// 00 = RAM
parameter CFG_CLASS = 8'h05;						// 05 = memory controller
parameter CFG_CACHE_LINE_SIZE = 8'd8;		// 32-bit units
parameter CFG_MIN_GRANT = 8'h00;
parameter CFG_MAX_LATENCY = 8'h00;
parameter CFG_IRQ_LINE = 8'hFF;

localparam CFG_HEADER_TYPE = 8'h00;			// 00 = a general device

input rst_i;
input clk_i;
output rdy_o;
output reg [2:0] rwx_o;
output [31:0] tlbmiss_irq_o;
input fta_cmd_request128_t [CHANNELS-1:0] wbn_req_i;
output fta_cmd_response128_t [CHANNELS-1:0] wbn_resp_o;
output fta_cmd_request128_t fta_req_o;
input fta_cmd_response128_t fta_resp_i;
output reg snoop_v;
output fta_address_t snoop_adr;
output reg [3:0] snoop_cid;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

tlb_state_t state = ST_RST;

integer n;
integer n1,j1;
integer n2;
integer n3, n4, n5, n6, n7, n8, n9, n10, n11, n12;
genvar g;

reg tlbmiss_irq;
wire irq_en;
reg [2:0] rgn;
reg [3:0] cache;
reg [3:0] cache_o;
REGION region;
wire [127:0] rgn_dato;
reg [2:0] rwx;
reg tlben_i;
reg wrtlb_i;
reg [31:0] tlbadr_i;

reg [2:0] rd_tlb;
reg wr_tlb;
STLBE tlbdat_i;
reg [31:0] ctrl_reg;

rfx32pkg::address_t last_ladr, last_iadr;
rfx32pkg::address_t adrd;
rfx32pkg::address_t tlbmiss_adr;
reg invall;
reg [LOG_ENTRIES-1:0] inv_count;

tlb_count_t master_count;
fta_cmd_request128_t req,req1,wbs_req,fta_req;
fta_cmd_response128_t wbm_resp;
fta_asid_t asid_i;
fta_asid_t asidd;
fta_asid_t tlbmiss_asid;
fta_operating_mode_t om_i, omd, omd2;

reg [1:0] al;
reg LRU, RAND;
code_address_t rstip = RSTIP;
reg [3:0] randway;
STLBE tentryi [0:ASSOC-1];
STLBE tentryo [0:ASSOC-1];
STLBE tentryo2 [0:ASSOC-1];
reg xlaten_i;
reg xlatend;
reg we_i;
rfx32pkg::address_t adr_i;
reg [LOG_ENTRIES-1:0] adr_i_slice [0:ASSOC-1];
rfx32pkg::address_t iadrd;
reg next_i;
STLBE [ASSOC-1:0] tlbdato;
wire clk_g = clk_i;

reg [4:0] wway;
STLBE tlbdat_rst;
STLBE tlbdati;
reg [4:0] count;
reg [ASSOC-1:0] tlbwrr;
reg tlbeni;
wire [LOG_ENTRIES-1:0] tlbadri;
reg clock_r;
reg [LOG_ENTRIES-1:0] rcount;

SPTE pte_reg;
SVPN vpn_reg;
reg [31:0] ctrl_req;
reg [3:0] selected_channel;
reg [CHANNELS-1:0] ch_active;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

assign wbs_req = fta_req_o;

wire acko;
reg cs_config, cs_stlbq, cs_rgnq;
wire cs_stlb, cs_rgn;
wire [127:0] cfg_out;
reg [127:0] dato;

always_ff @(posedge clk_g)
	cs_config <= wbs_req.cyc && wbs_req.stb &&
		wbs_req.padr[31:28]==4'hD &&
		wbs_req.padr[27:20]==CFG_BUS &&
		wbs_req.padr[19:15]==CFG_DEVICE &&
		wbs_req.padr[14:12]==CFG_FUNC;

always_comb
	cs_stlbq <= cs_stlb && wbs_req.cyc && wbs_req.stb;
always_comb
	cs_rgnq <= cs_rgn && wbs_req.cyc && wbs_req.stb;


ack_gen #(
	.READ_STAGES(1),
	.WRITE_STAGES(0),
	.REGISTER_OUTPUT(1)
) uag1
(
	.rst_i(rst_i),
	.clk_i(clk_g),
	.ce_i(1'b1),
	.rid_i('d0),
	.wid_i('d0),
	.i((cs_config|cs_stlbq|cs_rgnq) & ~wbs_req.we),
	.we_i((cs_config|cs_stlbq|cs_rgnq) & wbs_req.we),
	.o(acko),
	.rid_o(),
	.wid_o()
);

pci128_config #(
	.CFG_BUS(CFG_BUS),
	.CFG_DEVICE(CFG_DEVICE),
	.CFG_FUNC(CFG_FUNC),
	.CFG_VENDOR_ID(CFG_VENDOR_ID),
	.CFG_DEVICE_ID(CFG_DEVICE_ID),
	.CFG_BAR0(IO_ADDR),
	.CFG_BAR0_MASK(IO_ADDR_MASK),
	.CFG_BAR1(IO_ADDR2),
	.CFG_BAR1_MASK(IO_ADDR_MASK),
	.CFG_SUBSYSTEM_VENDOR_ID(CFG_SUBSYSTEM_VENDOR_ID),
	.CFG_SUBSYSTEM_ID(CFG_SUBSYSTEM_ID),
	.CFG_ROM_ADDR(CFG_ROM_ADDR),
	.CFG_REVISION_ID(CFG_REVISION_ID),
	.CFG_PROGIF(CFG_PROGIF),
	.CFG_SUBCLASS(CFG_SUBCLASS),
	.CFG_CLASS(CFG_CLASS),
	.CFG_CACHE_LINE_SIZE(CFG_CACHE_LINE_SIZE),
	.CFG_MIN_GRANT(CFG_MIN_GRANT),
	.CFG_MAX_LATENCY(CFG_MAX_LATENCY),
	.CFG_IRQ_LINE(CFG_IRQ_LINE)
)
upci
(
	.rst_i(rst_i),
	.clk_i(clk_g),
	.irq_i(tlbmiss_irq & irq_en),
	.irq_o(tlbmiss_irq_o),
	.cs_config_i(cs_config),
	.we_i(wbs_req.we),
	.sel_i(wbs_req.sel),
	.adr_i(wbs_req.padr),
	.dat_i(wbs_req.data1),
	.dat_o(cfg_out),
	.cs_bar0_o(cs_stlb),
	.cs_bar1_o(cs_rgn),
	.cs_bar2_o(),
	.irq_en_o(irq_en)
);

always_ff @(posedge clk_g, posedge rst_i)
if (rst_i) begin
	pte_reg <= 'd0;
	vpn_reg <= 'd0;
	ctrl_reg <= 'd0;
	rd_tlb <= 'b0;
	wr_tlb <= 1'b0;
	wrtlb_i <= 1'b0;
	tlben_i <= 1'b0;
	tlbadr_i <= 'd0;
	tlbdat_i <= 'd0;
	LRU <= 1'b1;
	RAND <= 1'b0;
end
else begin
	tlben_i <= |rd_tlb;
	rd_tlb <= {rd_tlb[1:0],1'b0};
	wr_tlb <= 1'b0;
	if (state==ST_UPD3)
		wrtlb_i <= 1'b0;
	if (cs_stlbq & wbs_req.we) begin
		case(wbs_req.padr[6:4])
		3'd0:	pte_reg <= wbs_req.data1;
		3'd1:	vpn_reg <= wbs_req.data1;
		3'd7:	
			begin
			case(wbs_req.sel)
			16'h000F:	
				begin
					ctrl_reg <= wbs_req.data1[31:0];
					LRU <= wbs_req.data1[17:16]==2'b01;
					RAND <= wbs_req.data1[17:16]==2'b10;
				end
			default:	;
			endcase
			if (wbs_req.sel[13])
				rd_tlb <= 3'b001;
			if (wbs_req.sel[14])
				wr_tlb <= 1'b1;
			end
		default:	;
		endcase
	end
	if (wr_tlb) begin
		tlben_i <= 1'b1;
		wrtlb_i <= 1'b1;
		tlbdat_i.count <= master_count;
		tlbdat_i.lru <= 'd0;
		tlbdat_i.pte <= pte_reg;
		tlbdat_i.vpn <= vpn_reg;
		tlbadr_i <= ctrl_reg;
	end
	if (rd_tlb[0])
		tlbadr_i <= ctrl_reg;
	if (rd_tlb[2]) begin
		pte_reg <= tlbdato[tlbadr_i[3:0]].pte;
		vpn_reg <= tlbdato[tlbadr_i[3:0]].vpn;
	end
end

always_ff @(posedge clk_g, posedge rst_i)
if (rst_i)
	dato <= 'd0;
else begin
	if (cs_config)
		dato <= cfg_out;
	else if (cs_stlbq)
		case(wbs_req.padr[6:4])
		3'd0:	dato <= pte_reg;
		3'd1:	dato <= vpn_reg;
		3'd2:	
			begin
				dato <= tlbmiss_adr;
				dato[123:112] <= tlbmiss_asid;
			end
		3'd7:	dato <= ctrl_reg;
		default:	dato <= 'd0;
		endcase
	else if (cs_rgnq)
		dato <= rgn_dato;
	else
		dato <= 'd0;
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

rfx32_stlb_active_region urgn
(
	.rst(rst_i),
	.clk(clk_i),
	.cs_rgn(cs_rgnq),
	.rgn(rgn),
	.wbs_req(fta_req_o),
	.dato(rgn_dato),
	.region_num(),
	.region(region),
	.sel(),
	.err()
);

assign rgn_dato = 'd0;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Arbitrate incoming requests.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg rr_ce;
reg [CHANNELS-1:0] rr_active;
reg [CHANNELS-1:0] rr_req;
wire [CHANNELS-1:0] rr_sel;
wire ne_ack;
wire [CHANNELS-1:0] ne_cyc;
fta_cmd_request128_t [CHANNELS-1:0] wbn_req_d;

edge_det uedack
(
	.rst(rst_i),
	.clk(clk_i),
	.ce(1'b1),
	.i(fta_resp_i.ack|fta_resp_i.err|fta_resp_i.rty),
	.pe(),
	.ne(ne_ack),
	.ee()
);

generate begin : gNeCyc
	for (g = 0; g < CHANNELS; g = g + 1)
		edge_det uedcyc (
			.rst(rst_i),
			.clk(clk_i),
			.ce(1'b1),
			.i(wbn_req_i[g].cyc),
			.pe(),
			.ne(ne_cyc[g]),
			.ee()
		);
end
endgenerate

reg [5:0] arbit_ctr;
always_ff @(posedge clk_i)
if (rst_i)
	arbit_ctr <= 'd0;
else
	arbit_ctr <= arbit_ctr + 2'd1;

// Piplein delay to line up with seleect.
always_ff @(posedge clk_i)
	for (n12 = 0; n12 < CHANNELS; n12 = n12 + 1)
		wbn_req_d[n12] <= wbn_req_i[n12];
	
always_ff @(posedge clk_i)
begin
	req = 'd0;
	selected_channel = 'd0;
	for (n8 = 0; n8 < CHANNELS; n8 = n8 + 1)
		if (rr_sel[n8])	begin // should be one hot
			req = wbn_req_d[n8];
			selected_channel = n8;
		end
end

always_comb
begin
	wbm_resp = 'd0;
	wbm_resp.cid = fta_req_o.cid;
	wbm_resp.tid = fta_req_o.tid;
	wbm_resp.stall = 1'b0;
	wbm_resp.next = 1'b0;
	wbm_resp.ack = acko;
	wbm_resp.err = 1'b0;
	wbm_resp.rty = 1'b0;
	wbm_resp.pri = 4'd7;
	wbm_resp.dat = dato;
	wbm_resp.adr = fta_req_o.padr;
end

reg [3:0] used_tid [0:CHANNELS-1];
reg [3:0] resp_ch;

always_ff @(posedge clk_i)
if (rst_i) begin
	for (n10 = 0; n10 < CHANNELS; n10 = n10 + 1)
		used_tid[n10] <= 4'hF;
end
else begin
	for (n10 = 0; n10 < CHANNELS; n10 = n10 + 1)
		if (wbn_req_i[n10].cyc)
			used_tid[n10] <= wbn_req_i[n10].tid[7:4];
end

function [3:0] fnRespch;
input [7:0] tid;
integer n;
begin
	fnRespch = CHANNELS;
	for (n = 0; n < CHANNELS; n = n + 1)
		if (tid[7:4]==used_tid[n])
			fnRespch = n;
end
endfunction

always_comb
	for (n11 = 0; n11 < CHANNELS; n11 = n11 + 1)
		rr_req[n11] = wbn_req_i[n11].cyc;

reg [5:0] chcnt = 'd0;
always_ff @(posedge clk_i)
	chcnt <= chcnt + 2'd1;

// Send a retry back as the response for non-selected channels.
always_comb
begin
	wbn_resp_o = 'd0;
	case(rr_req)
	// No channels active, one of them should not be retrying.
	4'b0000:
		begin
			for (n9 = 0; n9 < CHANNELS; n9 = n9 + 1) begin
				wbn_resp_o[n9].rty = 'd1;
				wbn_resp_o[chcnt[$clog2(CHANNELS)-1:0]].rty = 'd0;
			end
		end
	// Some channels are active, only the chosen one gets the bus.
	default:
		for (n9 = 0; n9 < CHANNELS; n9 = n9 + 1)
			wbn_resp_o[n9].rty = (n9!=selected_channel);
	endcase
	wbn_resp_o[fnRespch(fta_resp_i.tid)] = fta_resp_i;
	if (wbm_resp.ack)
		wbn_resp_o[fnRespch(wbm_resp.tid)] = wbm_resp;
//	wbn_resp_o[fta_resp_i.tid[7:4]].adr = fta_req_o.padr;
end

always_comb
	xlaten_i = req.cyc;
always_comb
	om_i = req.om;
always_comb
	we_i = req.we;
always_comb
	asid_i = req.asid;
always_comb
	adr_i = req.vadr;
always_comb
	next_i = fta_resp_i.next;

always_ff @(posedge clk_i)
if (rst_i)
	rr_active <= 'd0;
else begin
	rr_active <= (rr_active | rr_sel);
	if (fta_resp_i.ack|fta_resp_i.rty|fta_resp_i.err)
		rr_active[fta_resp_i.tid[7:4]] <= 1'b0;
	if (wbm_resp.ack)
		rr_active[wbm_resp.tid[7:4]] <= 1'b0;
end
wire [3:0] cache_type = fta_req_o.cache;

wire non_cacheable =
	cache_type==NC_NB ||
	cache_type==NON_CACHEABLE
	;
always_comb
//	snoop_v = (fta_req_o.we|non_cacheable) & fta_req_o.cyc; // Why non-cacheable????
	snoop_v = fta_req_o.we & fta_req_o.cyc;
always_comb
	snoop_adr = fta_req_o.padr;
always_comb
	snoop_cid = (non_cacheable) ? 4'd15 : fta_req_o.tid[7:4];

roundRobin
#(
	.N(CHANNELS)
) 
urr1
(
	.rst(rst_i),
	.clk(clk_i),
	.ce(1'b1),
	.req(rr_req),
	.lock('d0),
	.sel(rr_sel),
	.sel_enc()
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Select the least recently used entry.
always_comb
begin
	wway = 5'd31;
	for (n6 = 0; n6 < 4; n6 = n6 + 1)
		if (wway==5'd31)
			if (tlbdato[n6].lru==3'd7)
				wway = n6;
			else if (tlbdato[n6].lru==3'd6)
				wway = n6;
			else if (tlbdato[n6].lru==3'd5)
				wway = n6;
			else if (tlbdato[n6].lru==3'd4)
				wway = n6;
			else if (tlbdato[n6].lru==3'd3)
				wway = n6;
			else if (tlbdato[n6].lru==3'd2)
				wway = n6;
			else if (tlbdato[n6].lru==3'd1)
				wway = n6;
			else
				wway = n6;
end


reg [ASSOC-1:0] wr;
reg wed;
reg [3:0] hit;
reg [ASSOC-1:0] wrtlb, next_wrtlb;
genvar g1;
generate begin : gWrtlb
	for (g1 = 0; g1 < ASSOC; g1 = g1 + 1) begin : gFor
		always_comb begin
			next_wrtlb[g1] <= 'd0;
			if (state==ST_UPD3) begin
				if (LRU && tlbadr_i[3:0] < 4) begin
					if (g1==wway)
						next_wrtlb[g1] <= wrtlb_i;
				end
				else begin
					if (tlbadr_i[3:0]==ASSOC-1) begin
						if (g1==ASSOC-1)
		 					next_wrtlb[g1] <= wrtlb_i;
		 			end
					else if (g1 < 4)
		 				next_wrtlb[g1] <= (RAND ? randway==g1 : tlbadr_i[3:0]==g1) && wrtlb_i;
		 			else
		 				next_wrtlb[g1] <= tlbadr_i[3:0]==g1 && wrtlb_i;
	 			end
 			end
 		end
 	end
end
endgenerate

// TLB RAM has a 1 cycle lookup latency.
// These signals need to be matched
always_ff @(posedge clk_g)
	xlatend <= xlaten_i;
always_ff @(posedge clk_g)
	iadrd <= req.vadr;

wire [ASSOC-1:0] wrtlbd;
ft_delay #(.WID(ASSOC), .DEP(3)) udlyw (.clk(clk_g), .ce(1'b1), .i(wrtlb), .o(wrtlbd));

wire pe_xlat, ne_xlat;
edge_det u5 (
  .rst(rst_i),
  .clk(clk_g),
  .ce(1'b1),
  .i(xlaten_i),
  .pe(pe_xlat),
  .ne(ne_xlat),
  .ee()
);

// Detect a change in the page number
wire cd_adr;
change_det #(.WID($bits(rfx32pkg::address_t)-LOG_PAGE_SIZE)) ucd1 (
	.rst(rst_i),
	.clk(clk_g),
	.ce(1'b1),
	.i(adr_i[$bits(rfx32pkg::address_t)-1:LOG_PAGE_SIZE]),
	.cd(cd_adr)
);

reg [5:0] dl;
always_ff @(posedge clk_g)
	if (cd_adr)
		dl <= 6'd0;
	else
		dl <= {dl[4:0],1'b1};

always_ff @(posedge clk_g)
	adrd <= adr_i;
always_ff @(posedge clk_g)
	asidd <= asid_i;

always_ff @(posedge clk_g, posedge rst_i)
if (rst_i) begin
	randway <= 'd0;
end
else begin
	if (!wrtlb_i) begin
		randway <= randway + 2'd1;
		if (randway==ASSOC-2)
			randway <= 'd0;
	end
end

always_ff @(posedge clk_g, posedge rst_i)
if (rst_i) begin
	state <= ST_RST;
	tlbdat_rst <= 'd0;
	master_count <= 6'd1;
	tlbeni <= 1'b1;		// forces ready low
	tlbwrr <= 'd0;
	wrtlb <= 'd0;
	count <= 'd0;		// Map only last 256kB
	rcount <= 'd0;
	inv_count <= 'd0;
	invall <= 'd0;
	clock_r <= 1'b0;
end
else begin
tlbeni  <= 1'b0;
tlbwrr <= 'd0;
case(state)
	
// Setup the last 256kB/16 pages of memory to point to the ROM BIOS.
ST_RST:
	begin
		master_count <= 6'd1;
		tlbeni <= 1'b1;
		tlbwrr <= 'd0;
		case(count[4])
//		13'b000: begin tlbwr0r <= 1'b1; tlbdat_rst <= {8'h00,8'hEF,14'h0,count[11:10],12'h000,8'h00,count[11:0]};	end // Map 16MB RAM area
//		13'b001: begin tlbwr1r <= 1'b1; tlbdat_rst <= {8'h00,8'hEF,14'h1,count[11:10],12'h000,8'h00,count[11:0]};	end // Map 16MB RAM area
//		13'b010: begin tlbwr2r <= 1'b1; tlbdat_rst <= {8'h00,8'hEF,14'h2,count[11:10],12'h000,8'h00,count[11:0]};	end // Map 16MB RAM area
		1'b0:
			begin
				tlbwrr[ASSOC-1] <= 1'b1; 
				tlbdat_rst <= 'd0;
				tlbdat_rst.count <= 6'd1;
				//tlbdat_rst.pte.g <= 1'b1;
				tlbdat_rst.pte.v <= 1'b1;
				tlbdat_rst.pte.m <= 1'b1;
				tlbdat_rst.pte.g <= 1'b1;
				tlbdat_rst.pte.rwx <= 3'd7;
				//tlbdat_rst.pte.c <= 1'b1;
				// FFFC0000
				// 1111_1111_1111_1100_00 00_0000_0000_0000
				tlbdat_rst.vpn.asid <= 'd0;
				tlbdat_rst.vpn <= 8'hFF;
				tlbdat_rst.pte.ppn <= {14'h3FFF,count[3:0]};
				tlbdat_rst.pte.cache <= 'd0;//fta_bus_pkg::CACHEABLE;
				//tlbdat_rst.ppnx <= 12'h000;
				rcount <= {6'h3F,count[3:0]};
			end // Map 16MB ROM/IO area
		1'b1: begin state <= ST_RUN; tlbwrr[ASSOC-1] <= 1'd1; end
		default:	;
		endcase
		count <= count + 2'd1;
		invall <= 'd0;
		inv_count <= ENTRIES-1;
	end
ST_RUN:
	begin
		if (invall && inv_count==ENTRIES-1) begin
			inv_count <= 'd0;
			invall <= 'd0;
			// Master count never hits zero.
			master_count <= master_count + 2'd1;
			if (master_count == 6'd63)
				master_count <= 6'd1;
		end
		if (wrtlb_i) begin
			tlbeni <= 1'b1;
			state <= ST_UPD1;
		end
		else if (inv_count != ENTRIES-1) begin
			wrtlb <= 'd0;
			inv_count <= inv_count + 2'd1;
			state <= ST_INVALL1;
		end
	end
ST_UPD1:
	begin
		tlbeni <= 1'b1;
		state <= ST_UPD2;
	end
ST_UPD2:
	begin
		tlbeni <= 1'b1;
		state <= ST_UPD3;
	end
ST_UPD3:
	begin
		tlbeni <= 1'b1;
		wrtlb <= next_wrtlb;
		state <= ST_RUN;
	end

ST_INVALL1:
	begin
		tlbeni <= 1'b1;
		state <= ST_INVALL2;
	end
ST_INVALL2:
	begin
		tlbeni <= 1'b1;
		state <= ST_INVALL3;
	end
ST_INVALL3:
	begin
		tlbeni <= 1'b1;
		state <= ST_INVALL4;
	end
ST_INVALL4:
	begin
		tlbeni <= 1'b1;
		for (n2 = 0; n2 < ASSOC; n2 = n2 + 1) begin
			if (tlbdato[n2].count!=master_count)
				tlbwrr[n2] <= 1'b1;
		end
		state <= ST_RUN;
	end
default:
	state <= ST_RUN;
endcase
end
assign rdy_o = ~tlbeni;

rfx32_stlb_ad_state_machine
#(
	.ENTRIES(ENTRIES),
	.PAGE_SIZE(PAGE_SIZE),
	.ASSOC(ASSOC)
)
usm2
(
	.clk(clk_g),
	.state(state),
	.rcount(rcount),
	.tlbadr_i(tlbadr_i),
	.tlbadro(tlbadri), 
	.tlbdat_rst(tlbdat_rst),
	.tlbdat_i(tlbdat_i),
	.tlbdato(tlbdati),
	.master_count(master_count),
	.inv_count(inv_count)
);

// Dirty / Accessed bit write logic
always_ff @(posedge clk_g)
  wed <= we_i;

always_ff @(posedge clk_g)
begin
	wr <= 'd0;
  if (ne_xlat) begin
  	for (n1 = 0; n1 < ASSOC; n1 = n1 + 1) begin
  		tentryi[n1] <= tentryo2[n1];
  		case(hit)
  		4'd0,4'd1,4'd2,4'd3:
	  		if (n1 < 4) begin
		  		if (tentryo2[n1].lru < tentryo2[hit].lru)
		  			tentryi[n1].lru <= tentryo2[n1].lru + 2'd1;
	  		end
  		4'd5:
	  		if (n1==4) begin
		  		if (tentryo2[n1].lru < tentryo2[hit].lru)
		  			tentryi[n1].lru <= tentryo2[n1].lru + 2'd1;
	  		end
  		default:	;
  		endcase
  	end
  	if (hit < 4'd15) begin
			tentryi[hit].lru <= 'd0;
			if (wed)
				tentryi[hit].pte.m <= 1'b1;
	 		wr <= {ASSOC{1'b1}};
 		end
  end
end

always_comb
for (n7 = 0; n7 < ASSOC; n7 = n7 + 1)
	if (n7 < ASSOC-LVL1_ASSOC-1 || n7==ASSOC-1)
		adr_i_slice[n7] = adr_i[LOG_PAGE_SIZE+LOG_ENTRIES-1:LOG_PAGE_SIZE];
	else
		adr_i_slice[n7] = adr_i[$bits(rfx32pkg::address_t)-1:LOG_ENTRIES+LOG_PAGE_SIZE];
	
generate begin : gTlbRAM
for (g = 0; g < ASSOC; g = g + 1) begin : gLvls
	rfx32_TLBRam
	# (
		.ENTRIES(ENTRIES),
		.WIDTH($bits(STLBE))
	)
	u1 (
	  .clka(clk_g),
	  .ena(tlben_i|tlbeni),
	  .wea(wrtlb[g]|tlbwrr[g]),
	  .addra(tlbadri),
	  .dina(tlbdati),
	  .douta(tlbdato[g]),
	  .clkb(clk_g),
	  .enb(xlaten_i),
	  .web(wr[g]),
	  .addrb(adr_i_slice[g]),
	  .dinb(tentryi[g]),
	  .doutb(tentryo[g])
	);
end
end
endgenerate

// Pipeline delay req.
always_ff @(posedge clk_g, posedge rst_i)
if (rst_i)
	req1 <= 'd0;
else
	req1 <= req;
always_ff @(posedge clk_g, posedge rst_i)
if (rst_i)
	omd <= fta_bus_pkg::APP;
else
	omd <= om_i;
always_ff @(posedge clk_g, posedge rst_i)
if (rst_i)
	omd2 <= fta_bus_pkg::APP;
else
	omd2 <= omd;


// Mask selecting between incoming address bits and address bits from the PPN.
function rfx32pkg::address_t fnAmask;
input [4:0] L;
integer nn;
begin
for (nn = 0; nn < $bits(rfx32pkg::address_t); nn = nn + 1)
	if (nn < LOG_PAGE_SIZE + LOG_ENTRIES*L)
		fnAmask[nn] = 1'b1;
	else
		fnAmask[nn] = 1'b0;
end
endfunction

// Mask for virtual address bits that must match the incoming address.
function rfx32pkg::address_t fnVmask1;
input [4:0] L;
integer nn;
begin
for (nn = 0; nn < $bits(rfx32pkg::address_t); nn = nn + 1)
	if (nn < LOG_PAGE_SIZE + LOG_ENTRIES*(L+1))
		fnVmask1[nn] = 1'b0;
	else
		fnVmask1[nn] = 1'b1;
end
endfunction

// Compute shift for low order bits that do not need to be compared.
// Applied to incoming virtual address.
function [7:0] fnShamt1;
input [4:0] L;
integer nn;
begin
	fnShamt1 = LOG_PAGE_SIZE + LOG_ENTRIES*(L+1);
end
endfunction

// Compute shift for low order bits that do not need to be compared.
// Applied to the virtual page number.
function [7:0] fnShamt2;
input [4:0] L;
integer nn;
begin
	fnShamt2 = LOG_ENTRIES*L;
end
endfunction

// Mask for virtual page number that must match incoming address's page number.
function rfx32pkg::address_t fnVmask2;
input [4:0] L;
integer nn;
begin
	for (nn = 0; nn < $bits(rfx32pkg::address_t); nn = nn + 1)
		if (nn < LOG_ENTRIES * L)
			fnVmask2 = 1'b0;
		else
			fnVmask2 = 1'b1;
end
endfunction

function fnCompareVPN2Address;
input [77:0] vpn;
input [$bits(rfx32pkg::address_t)-1:0] address;
input [4:0] L;
begin
	fnCompareVPN2Address = 
		(vpn >> fnShamt2(L)) ==
		(address >> fnShamt1(L))
		;
end
endfunction

always_ff @(posedge clk_g, posedge rst_i)
if (rst_i) begin
//	fta_req_o <= 'd0;
//	fta_req_o <= req1;
	fta_req.om <= fta_bus_pkg::APP;
	fta_req.cid <= 'd0;
	fta_req.tid <= 'd0;
	fta_req.cmd <= fta_bus_pkg::CMD_NONE;
	fta_req.bte <= fta_bus_pkg::LINEAR;
	fta_req.blen <= 'd0;
	fta_req.sz <= fta_bus_pkg::hexi;
	fta_req.seg <= fta_bus_pkg::DATA;
	fta_req.cti <= fta_bus_pkg::CLASSIC;
	fta_req.cyc <= 1'b0;
	fta_req.stb <= 1'b0;
	fta_req.we <= 1'b0;
	fta_req.sel <= 16'h0;
	fta_req.asid <= 'd0;
	fta_req.vadr <= rstip;
 	fta_req.padr[LOG_PAGE_SIZE-1:0] <= rstip[LOG_PAGE_SIZE-1:0];
  fta_req.padr[$bits(rfx32pkg::address_t)-1:LOG_PAGE_SIZE] <= rstip[$bits(rfx32pkg::address_t)-1:LOG_PAGE_SIZE];
  fta_req.data1 <= 'd0;
  fta_req.data2 <= 'd0;
  fta_req.csr <= 'd0;
  fta_req.pl <= 'd0;
  fta_req.pri <= 4'd7;
  fta_req.cache <= fta_bus_pkg::NC_NB;
  hit <= 4'd15;
  tlbmiss_irq <= FALSE;
	tlbmiss_adr <= 'd0;
	tlbmiss_asid <= 'd0;
  rwx <= 3'd7;
  rgn <= 3'd7;	// select default ROM region
  cache <= fta_bus_pkg::CACHEABLE;
	for (n = 0; n < ASSOC; n = n + 1)
		tentryo2[n] <= 'd0;
end
else begin
	fta_req.om <= req1.om;
	fta_req.cid <= req1.cid;
	fta_req.tid <= req1.tid;
	fta_req.seg <= req1.seg;
	fta_req.cti <= req1.cti;
	fta_req.cyc <= 1'b0;
	fta_req.stb <= req1.stb;
	fta_req.we <= req1.we;
	fta_req.sel <= req1.sel;
	fta_req.asid <= req1.asid;
	fta_req.vadr <= req1.vadr;
	fta_req.padr <= fta_req_o.padr;
	fta_req.data1 <= req1.data1;
	fta_req.data2 <= req1.data2;
	fta_req.cache <= req1.cache;
  rgn <= 3'd7;	// select default ROM region
  if (pe_xlat) begin
  	hit <= 4'd15;
  end
	if (next_i) begin
		hit <= hit;
		rgn <= rgn;
		cache <= cache;
    tlbmiss_irq <= FALSE;
		rwx <= rwx;
		fta_req.padr <= fta_req.padr + 6'd16;
	end
  else begin
		if (!xlatend) begin
	    tlbmiss_irq <= FALSE;
			fta_req.cyc <= req1.cyc;
	  	fta_req.padr <= {16'h0000,iadrd[$bits(rfx32pkg::address_t)-1:0]};
	    rwx <= 4'hF;
		end
		else begin
			tlbmiss_irq <= dl[4] & ~cd_adr;
			if (dl[4] & ~cd_adr) begin
				tlbmiss_adr <= adrd;
				tlbmiss_asid <= asidd;
			end
			hit <= 4'd15;
			rwx <= 4'h0;
			for (n = 0; n < ASSOC; n = n + 1) begin
				tentryo2[n] <= tentryo[n];
				if (tentryo[n].count==master_count) begin
					if (tentryo[n].vpn.asid[11:0]==asidd[11:0] || tentryo[n].pte.g) begin
						if (tentryo[n].pte.v) begin
							if (fnCompareVPN2Address(
								tentryo[n].vpn.vpn,
								{{2{&iadrd[$bits(rfx32pkg::address_t)-1:$bits(rfx32pkg::address_t)-4]}},iadrd},
								tentryo[n].pte.lvl
								)) begin
								rwx <= tentryo[n].pte.rwx[omd];
								cache <= tentryo[n].pte.cache;
								tlbmiss_irq <= FALSE;
							  rgn <= tentryo[n].pte.rgn;
								hit <= n;
								fta_req.cyc <= req1.cyc;
								fta_req.padr <= (iadrd & fnAmask(tentryo[n].pte.lvl)) |
											  				({tentryo[n].pte.ppn,{LOG_PAGE_SIZE{1'b0}}} & ~fnAmask(tentryo[n].pte.lvl));
							end
						end
					end
				end				
			end
		end
	end
end

always_comb
	rwx_o = |rwx ? rwx : region.at[omd2].rwx;

// Cache-ability output. Region takes precedence.
always_comb
	case(fta_cache_t'(region.at[omd2].cache))
	NC_NB:					cache_o = NC_NB;
	NON_CACHEABLE:	cache_o = NON_CACHEABLE;
	CACHEABLE_NB:
		case(fta_cache_t'(cache))
		NC_NB:					cache_o = NC_NB;
		NON_CACHEABLE:	cache_o = NON_CACHEABLE;
		CACHEABLE_NB:		cache_o = CACHEABLE_NB;
		CACHEABLE:			cache_o = CACHEABLE_NB;
		default:				cache_o = cache;
		endcase
	CACHEABLE:
		case(fta_cache_t'(cache))
		NC_NB:					cache_o = NC_NB;
		NON_CACHEABLE:	cache_o = NON_CACHEABLE;
		CACHEABLE_NB:		cache_o = CACHEABLE_NB;
		default:				cache_o = cache;
		endcase
	WT_NO_ALLOCATE,WT_READ_ALLOCATE,WT_WRITE_ALLOCATE,WT_READWRITE_ALLOCATE,
	WB_NO_ALLOCATE,WB_READ_ALLOCATE,WB_WRITE_ALLOCATE,WB_READWRITE_ALLOCATE:
		case(fta_cache_t'(cache))
		NC_NB:					cache_o = NC_NB;
		NON_CACHEABLE:	cache_o = NON_CACHEABLE;
		default:				cache_o = region.at[omd2].cache;
		endcase
	default:	cache_o = NC_NB;
	endcase

always_comb
begin
	fta_req_o = fta_req;
	fta_req_o.cache = fta_cache_t'(cache_o);
	fta_req_o.we = fta_req.we & rwx_o[1];
end

endmodule
