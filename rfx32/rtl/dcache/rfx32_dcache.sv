// ============================================================================
//        __
//   \\__/ o\    (C) 2021-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfx32_dcache.sv
//	- data cache
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
// 2947 LUTs / 673 FFs / 20 BRAMs  64kB cache 16kB * 4 way
// ============================================================================

import fta_bus_pkg::*;
import rfx32pkg::*;
import rfx32_cache_pkg::*;

module rfx32_dcache(rst, clk, dce, snoop_adr, snoop_v, snoop_cid,
	cache_load, hit, modified, uway, cpu_req_i, cpu_resp_o, update_data_i, dump, dump_o,
	dump_ack_i, wr, way,
	invce, dc_invline, dc_invall);
parameter CORENO = 6'd3;
parameter CID = 4'd3;
parameter WAYS = 4;
parameter LINES = 512;
parameter LOBIT = 6;
parameter HIBIT = 14;
parameter T6 = 6;
parameter T15 = 15;
parameter TAGBIT = 15;
localparam LOG_WAYS = $clog2(WAYS)-1;

input rst;
input clk;
input dce;										// 1= data cache enabled
input rfx32pkg::address_t snoop_adr;
input snoop_v;								// 1= valid snoop taking place
input [5:0] snoop_cid;
input cache_load;							// 1= load operation, 0=update
output reg hit;
output reg modified;
output reg [LOG_WAYS:0] uway;	// way to use on a cache hit
input fta_cmd_request512_t cpu_req_i;
output fta_cmd_response512_t cpu_resp_o;
input fta_cmd_response512_t update_data_i;

output reg dump;
output DCacheLine dump_o;
input dump_ack_i;
input wr;
input [LOG_WAYS:0] way;
input invce;
input dc_invline;
input dc_invall;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Data Cache
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
typedef logic [$bits(rfx32pkg::address_t)-1:T6] cache_tag_t;
typedef struct packed
{
	logic resv;			// make struct a multiple of eight
	logic v;
	logic m;
	rfx32pkg::asid_t asid;
	cache_tag_t tag;
	logic [rfx32_cache_pkg::DCacheLineWidth-1:0] data;
} cache_line_t;

localparam CACHE_LINE_WIDTH = ($bits(cache_line_t)+7) & 32'hFFF8;	// Must be a multiple of eight

integer n, m;
integer k, j;

reg dump1;							// dump the cache line to memory
cache_line_t cline_in;
reg [LINES-1:0] validr [0:WAYS-1];
reg [WAYS-1:0] valid;
reg [WAYS-1:0] hits, mods;
cache_tag_t [WAYS-1:0] ptags;	// physical tags associated with even cache line
DCacheLine line;
cache_line_t [WAYS-1:0] lines;
reg [pL1DCacheWays-1:0] dcache_wr;
localparam NSEL = rfx32_cache_pkg::DCacheLineWidth/8;
reg [CACHE_LINE_WIDTH/8-1:0] sel;
wire cdvndx,cdvndx1;
reg cdvndx2;
reg [HIBIT:LOBIT] vndx;
fta_cache_t cache_type;

wire [16:0] lfsr_o;

lfsr17 #(.WID(17)) ulfsr1
(
	.rst(rst),
	.clk(clk),
	.ce(1'b1),
	.cyc(1'b0),
	.o(lfsr_o)
);

always_comb
	cache_type = cpu_req_i.cache;

change_det
#(
	.WID(HIBIT-LOBIT+1)
)
cdradr
(
	.rst(rst),
	.clk(clk),
	.ce(1'b1),
	.i(vndx),
	.cd(cdvndx)
);

delay1
#(
	.WID(1)
)
ucdd
(
	.clk(clk),
	.ce(1'b1),
	.i(cdvndx),
	.o(cdvndx1)
);

genvar g;

// Setup cache line input. Cache line input is coming from a cache line load if
// there was a miss on the address and it is a read or write allocate. Otherwise
// the input is coming from an update hit.

always_comb
	vndx <= {cpu_req_i.vadr[HIBIT:LOBIT],{LOBIT{1'b0}}};

always_comb
	if (cache_load)
		sel <= {CACHE_LINE_WIDTH/8{1'b1}};
	else
		sel <= {{CACHE_LINE_WIDTH/8{1'b1}},cpu_req_i.sel};
		
always_comb
begin
	cline_in.resv <= 'd0;
	cline_in.v <= 1'b1;					// Whether updating the line or loading a new one, always valid.
	cline_in.m <= ~cache_load;	// It is not modified if it is a fresh load.
	cline_in.asid <= cpu_req_i.asid;
	cline_in.tag <= cpu_req_i.vadr[$bits(rfx32pkg::address_t)-1:T6];
	if (cache_load)
		cline_in.data <= update_data_i.dat;
	else
		cline_in.data <= cpu_req_i.dat;
end


generate begin : gDcacheRAM
for (g = 0; g < WAYS; g = g + 1) begin : gFor
	sram_1r1w_bw 
	#(
		.WID(CACHE_LINE_WIDTH),
		.DEP(LINES)
	)
	udcme
	(
		.rst(rst),
		.clk(clk),
		.sel(sel),
		.wr(wr && way==g),
		.wadr(vndx),
		.radr(vndx),
		.i(cline_in),
		.o(lines[g])
	);

	// Physcial tag memory needs to be snooped, so it has its own memory with
	// read port.
	sram_1r1w 
	#(
		.WID($bits(cache_tag_t)),
		.DEP(LINES)
	)
	udcte
	(
		.rst(rst),
		.clk(clk),
		.wr(wr && way==g && cache_load),
		.wadr(vndx),
		.radr(snoop_adr[HIBIT:LOBIT]),
		.i(update_data_i.adr[$bits(rfx32pkg::address_t)-1:T6]),
		.o(ptags[g])
	);

end
end
endgenerate

reg non_cacheable;
reg read_allocate;

always_comb
	non_cacheable =
	cache_type==NC_NB ||
	cache_type==NON_CACHEABLE
	;
always_comb
	read_allocate =
	cache_type==CACHEABLE_NB ||
	cache_type==CACHEABLE ||
	cache_type==WT_READ_ALLOCATE ||
	cache_type==WT_READWRITE_ALLOCATE ||
	cache_type==WB_READ_ALLOCATE ||
	cache_type==WB_READWRITE_ALLOCATE
	;

// Pass through the incoming line back to the CPU when data cache is not enabled.
// If a cache hit, the update way is the hit way.

always_comb
begin
	line = 'd0;
	uway = 'd0;
	if (non_cacheable|~read_allocate|~dce)
		uway = 'd0;
	else
		casez (hits)
		4'b1???:
			begin
				line.v = valid[3];
				line.ptag = ptags[3];
				line.m = lines[3].m;
				line.vtag = lines[3].tag;
				line.data = lines[3].data;
				uway = 2'd3;
			end
		4'b01??:
			begin
				line.v = valid[2];
				line.ptag = ptags[2];
				line.m = lines[2].m;
				line.vtag = lines[2].tag;
				line.data = lines[2].data;
				uway = 2'd2;
			end
		4'b001?:
			begin
				line.v = valid[1];
				line.ptag = ptags[1];
				line.m = lines[1].m;
				line.vtag = lines[1].tag;
				line.data = lines[1].data;
				uway = 2'd1;
			end
		4'b0001:
			begin
				line.v = valid[0];
				line.ptag = ptags[0];
				line.m = lines[0].m;
				line.vtag = lines[0].tag;
				line.data = lines[0].data;
				uway = 2'd0;
			end
		default:
			begin
				line.v = 1'b0;
				line.ptag = ptags[0];
				line.m = 1'b0;
				line.vtag = lines[0].tag;
				line.data = lines[0].data;
				uway = 2'd0;
			end
		endcase
end

always_ff @(posedge clk)
begin
	cpu_resp_o = 'd0;
	if (non_cacheable|~read_allocate|~dce)
		cpu_resp_o = update_data_i;
	else
		casez (hits)

		4'b1???:
			begin
				cpu_resp_o.ack = cpu_req_i.cyc;
				cpu_resp_o.adr = {ptags[3],vndx,{LOBIT{1'b0}}};
				cpu_resp_o.dat = lines[3].data;
			end
		4'b01??:
			begin
				cpu_resp_o.ack = cpu_req_i.cyc;
				cpu_resp_o.adr = {ptags[2],vndx,{LOBIT{1'b0}}};
				cpu_resp_o.dat = lines[2].data;
			end
		4'b001?:
			begin
				cpu_resp_o.ack = cpu_req_i.cyc;
				cpu_resp_o.adr = {ptags[1],vndx,{LOBIT{1'b0}}};
				cpu_resp_o.dat = lines[1].data;
			end
		4'b0001:
			begin
				cpu_resp_o.ack = cpu_req_i.cyc;
				cpu_resp_o.adr = {ptags[0],vndx,{LOBIT{1'b0}}};
				cpu_resp_o.dat = lines[0].data;
			end
		default:
			begin
				cpu_resp_o.cid = update_data_i.cid;
				cpu_resp_o.tid = update_data_i.tid;
				cpu_resp_o.ack = update_data_i.ack;
				cpu_resp_o.adr = update_data_i.adr;
				cpu_resp_o.dat = update_data_i.dat;
			end
		endcase
	
end


always_comb
begin
	dump1 = 1'b0;
	if (hits==4'd0 && cdvndx1 && !cdvndx2) begin	// no hit
		if (!valid[0]||!lines[0].m)
			dump1 = 1'b0;
		else if (!valid[1]||!lines[1].m)
			dump1 = 1'b0;
		else if (!valid[2]||!lines[2].m)
			dump1 = 1'b0;
		else if (!valid[3]||!lines[3].m)
			dump1 = 1'b0;
		else begin
			dump1 = 1'b1;
		end
	end
end

always_ff @(posedge clk)
	cdvndx2 <= cdvndx1;
always_ff @(posedge clk)
if (rst)
	dump <= 'b0;
else begin
	if (dump_ack_i)
		dump <= 1'b0;
	else
		dump <= dump1;
	if (dump1 & ~dump) begin
		dump_o.v <= 1'b1;
		dump_o.m <= 1'b0;
		dump_o.asid <= lines[way].asid;
		dump_o.vtag <= lines[way].tag;
		dump_o.ptag <= ptags[way];
		dump_o.data <= lines[way].data;
	end
end

always_comb
begin
	for (j = 0; j < WAYS; j = j + 1) begin
	  hits[j] = lines[j[LOG_WAYS:0]].tag[$bits(rfx32pkg::address_t)-1:T15]==
	  						cpu_req_i.vadr[$bits(rfx32pkg::address_t)-1:T15] && 
	  					lines[j[LOG_WAYS:0]].asid==cpu_req_i.asid &&
	  					lines[j[LOG_WAYS:0]].v==1'b1;
	  mods[j] = lines[j[LOG_WAYS:0]].tag[$bits(rfx32pkg::address_t)-1:T15]==
	  						cpu_req_i.vadr[$bits(rfx32pkg::address_t)-1:T15] && 
	  					lines[j[LOG_WAYS:0]].asid==cpu_req_i.asid &&
	  					lines[j[LOG_WAYS:0]].m==1'b1;
	end
end


always_ff @(posedge clk)
	hit <= |hits;
always_ff @(posedge clk)
	modified <= |mods;

initial begin
for (m = 0; m < WAYS; m = m + 1) begin
  for (n = 0; n < LINES; n = n + 1) begin
    validr[m][n] = 1'b0;
  end
end
end

always_ff @(posedge clk, posedge rst)
if (rst) begin
	for (k = 0; k < WAYS; k = k + 1)
		validr[k] <= 'd0;
	valid <= 'd0;
end
else begin
	if (wr)
		validr[way][cpu_req_i.vadr[HIBIT:LOBIT]] <= 1'b1;
	else if (invce) begin
		for (k = 0; k < WAYS; k = k + 1) begin
			if (dc_invline)
				validr[k][cpu_req_i.vadr[HIBIT:LOBIT]] <= 1'b0;
			else if (dc_invall)
				validr[k] <= 'd0;
		end
	end
	// Two different virtual addresses pointing to the same physical address will
	// end up in the same set as long as the cache is smaller than a memory page
	// in size. So, there is no need to compare every physical address, just every
	// address in a set will do.
	// Invalidation does not need to be done for the channel that triggered the
	// snoop.
	if (snoop_v && snoop_cid!=CID) begin
		for (k = 0; k < WAYS; k = k + 1) begin
			if (snoop_adr[$bits(rfx32pkg::address_t)-1:T15]==ptags[k][$bits(rfx32pkg::address_t)-1:T15])
				validr[k][snoop_adr[HIBIT:LOBIT]] <= 1'b0;
		end
	end
	for (k = 0; k < WAYS; k = k + 1)
		valid[k] <= validr[k][vndx];
end


endmodule
