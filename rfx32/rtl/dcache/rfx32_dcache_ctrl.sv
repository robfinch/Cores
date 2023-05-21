// ============================================================================
//        __
//   \\__/ o\    (C) 2021-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfx32_dcache_ctrl.sv
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
// 212 LUTs / 348 FFs
// ============================================================================

import fta_bus_pkg::*;
import rfx32pkg::*;
import rfx32_cache_pkg::*;

module rfx32_dcache_ctrl(rst_i, clk_i, dce, ftam_req, ftam_resp, acr, hit, modified,
	cache_load, cpu_request_i, cpu_request_i2, data_to_cache_o, response_from_cache_i, wr, uway, way,
	dump, dump_i, dump_ack, snoop_adr, snoop_v, snoop_cid);
parameter CID = 2;
parameter CORENO = 6'd1;
parameter WAYS = 4;
parameter NSEL = 32;
parameter WAIT = 6'd6;
localparam LOG_WAYS = $clog2(WAYS)-1;
input rst_i;
input clk_i;
input dce;
output fta_cmd_request128_t ftam_req;
input fta_cmd_response128_t ftam_resp;
input [3:0] acr;
input hit;
input modified;
output reg cache_load;
input fta_cmd_request512_t cpu_request_i;
output fta_cmd_request512_t cpu_request_i2;
output fta_cmd_response512_t data_to_cache_o;
input fta_cmd_response512_t response_from_cache_i;
output reg wr;
input [LOG_WAYS:0] uway;
output reg [LOG_WAYS:0] way;
input dump;
input DCacheLine dump_i;
output reg dump_ack;
input fta_address_t snoop_adr;
input snoop_v;
input [3:0] snoop_cid;

genvar g;
integer nn,nn1;

typedef enum logic [2:0] {
	RESET = 0,
	STATE1,STATE3,STATE4,STATE5,RAND_DELAY
} state_t;
state_t req_state, resp_state;

reg [LOG_WAYS:0] iway;
fta_cmd_response512_t cache_load_data;
reg cache_dump;
reg [10:0] to_cnt;
fta_tranid_t tid_cnt;
wire [16:0] lfsr_o;
reg [1:0] dump_cnt;
reg [511:0] upd_dat;
reg we_r;
reg [15:0] tran_active;
reg [3:0] ndx;
reg [3:0] v [0:15];
reg [15:0] cache_load_r;
fta_cmd_request512_t cpu_req_queue [0:15];
fta_cmd_request128_t tran_req [0:15];
fta_cmd_response512_t tran_load_data [0:15];
reg [15:0] tran_out;
reg [15:0] is_dump;
reg req_load;
reg [1:0] load_cnt;
reg [5:0] wait_cnt;
reg [1:0] wr_cnt;
reg cpu_request_queued;
reg [7:0] lasttid;
reg bus_busy;

always_comb
	bus_busy = ftam_resp.rty;

lfsr17 #(.WID(17)) ulfsr1
(
	.rst(rst_i),
	.clk(clk_i),
	.ce(1'b1),
	.cyc(1'b0),
	.o(lfsr_o)
);

wire cache_type = cpu_request_i2.cache;
reg non_cacheable;
reg allocate;

always_comb
	non_cacheable =
	!dce ||
	cache_type==NC_NB ||
	cache_type==NON_CACHEABLE
	;
always_comb
	allocate =
	cache_type==CACHEABLE_NB ||
	cache_type==CACHEABLE ||
	cache_type==WT_READ_ALLOCATE ||
	cache_type==WT_WRITE_ALLOCATE ||
	cache_type==WT_READWRITE_ALLOCATE ||
	cache_type==WB_READ_ALLOCATE ||
	cache_type==WB_WRITE_ALLOCATE ||
	cache_type==WB_READWRITE_ALLOCATE
	;
// Comb logic so that hits do not take an extra cycle.
always_comb
	if (hit) begin
		way = uway;
		data_to_cache_o = response_from_cache_i;
		data_to_cache_o.ack = 1'b1;
	end
	else begin
		way = iway;
		data_to_cache_o = cache_load_data;
		data_to_cache_o.dat = upd_dat;
	end

// Selection of data used to update cache.
// For a write request the data includes data from the CPU.
// Otherwise it is just a cache line load, all data comes from the response.
// Note data is passed in 512-bit chunks.
generate begin : gCacheLineUpdate
	for (g = 0; g < 64; g = g + 1) begin : gFor
		always_comb
			if (cpu_req_queue[ndx].we) begin
				if (cpu_req_queue[ndx].sel[g])
					upd_dat[g*8+7:g*8] <= cpu_req_queue[ndx].dat[g*8+7:g*8];
				else
					upd_dat[g*8+7:g*8] <= data_to_cache_o.dat[g*8+7:g*8];
			end
			else
				upd_dat[g*8+7:g*8] <= cache_load_data[g*8+7:g*8];
	end
end
endgenerate				

always_comb
begin
	cpu_request_i2 = 'd0;
	for (nn1 = 0; nn1 < 16; nn1 = nn1 + 1)
		if (cpu_req_queue[nn1].cyc)
			cpu_request_i2 <= cpu_req_queue[nn1];
end
	
always_ff @(posedge clk_i, posedge rst_i)
if (rst_i) begin
	req_state <= RESET;
	resp_state <= RESET;
	to_cnt <= 'd0;
	tid_cnt <= 'd0;
	tid_cnt[7:4] <= {CORENO,1'b1};
	lasttid <= 'd0;
	dump_ack <= 1'd0;
	wr <= 1'b0;
	cache_load_data <= 'd0;
	ftam_req <= 'd0;
	dump_cnt <= 'd0;
	load_cnt <= 'd0;
	cache_load <= 'd0;
	cache_load_r <= 'd0;
	cache_dump <= 'd0;
	for (nn = 0; nn < 16; nn = nn + 1)
		tran_req[nn] <= 'd0;
	tran_active <= 'd0;
	tran_out <= 'd0;
	req_load <= 'd0;
	load_cnt <= 'd0;
	wait_cnt <= 'd0;
	wr_cnt <= 'd0;
	ndx <= 'd0;
	is_dump <= 'd0;
	cpu_request_queued <= 'd1;
end
else begin
	dump_ack <= 1'd0;
	cache_load_data.stall <= 1'b0;
	cache_load_data.next <= 1'b0;
	cache_load_data.ack <= 1'b0;
	cache_load_data.pri <= 4'd7;
	wr <= 1'b0;
	if (cpu_request_i.cyc)
		cpu_req_queue[cpu_request_i.tid & 15] <= cpu_request_i;
	case(req_state)
	RESET:
		begin
			ftam_req.cmd <= fta_bus_pkg::CMD_DCACHE_LOAD;
			ftam_req.sz  <= fta_bus_pkg::hexi;
			ftam_req.blen <= 'd0;
			ftam_req.cid <= 3'd7;					// CPU channel id
			ftam_req.tid <= 'd0;						// transaction id (not used)
			ftam_req.csr  <= 'd0;					// clear/set reservation
			ftam_req.pl	<= 'd0;						// privilege level
			ftam_req.pri	<= 4'h7;					// average priority (higher is better).
			ftam_req.cache <= fta_bus_pkg::CACHEABLE;
			ftam_req.seg <= fta_bus_pkg::DATA;
			ftam_req.bte <= fta_bus_pkg::LINEAR;
			ftam_req.cti <= fta_bus_pkg::CLASSIC;
			tBusClear();
			wr_cnt <= 'd0;
			req_state <= STATE1;
		end
	STATE1:
		begin
			// Look for outstanding transactions to execute.
			if (!bus_busy)
				for (nn = 0; nn < 16; nn = nn + 1) begin
					if (tran_active[nn] && !tran_out[nn]) begin
						tran_out[nn] <= 1'b1;
						ftam_req <= tran_req[nn];
					end
					wait_cnt <= 'd0;
					req_state <= RAND_DELAY;
				end
			// Look for transactions to perform.
			if (req_load && !cache_dump) begin
				if (!modified) begin
					if (load_cnt==2'd3) begin
						req_load <= 1'b0;
						cpu_request_queued <= 1'b1;
					end
					else begin
						tAddr(
							cpu_request_i2.om,
							1'b0,
							!non_cacheable,
							cpu_request_i2.asid,
							{cpu_request_i2.vadr[$bits(fta_address_t)-1:rfx32_cache_pkg::DCacheTagLoBit],load_cnt,{rfx32_cache_pkg::DCacheTagLoBit-2{1'h0}}},
							'd0
						);
						load_cnt <= load_cnt + 2'd1;
					end
				end
				else begin
					cache_dump <= 1'b1;
					dump_cnt <= 'd0;
				end
			end
			else if (((!hit && allocate && dce && modified && cpu_request_i2.cyc) || cache_dump)) begin
			if (cache_dump && dump_cnt==2'd3)
					cache_dump <= 1'b0;
				else begin
					cache_dump <= 1'b1;
					is_dump[tid_cnt & 4'hF] <= 1'b1;
					tAddr(
						cpu_request_i2.om,
						1'b1,
						!non_cacheable,
						dump_i.asid,
						{dump_i.vtag[$bits(fta_address_t)-1:rfx32_cache_pkg::DCacheTagLoBit],dump_cnt[1:0],{rfx32_cache_pkg::DCacheTagLoBit-2{1'h0}}},
						dump_i.data >> {dump_cnt,7'd0}
					);
					dump_cnt <= dump_cnt + 2'd1;
				end
			end
			// It may have missed because a non-cacheable address is being accessed.
			else if (!hit && cpu_request_i2.cyc && !cpu_request_queued && !req_load) begin
				if (!(non_cacheable & cpu_request_i2.cyc) && (allocate)) begin
					req_load <= 1'b1;
					load_cnt <= 'd0;
				end
				else
					tAccess();
			end
			else if (hit && !cpu_request_queued) begin
				
				// If it is not a writeback cache and a write cycle, write to memory.
				if (!(cpu_request_i2.cache == WB_READ_ALLOCATE ||
					cpu_request_i2.cache == WB_WRITE_ALLOCATE ||
					cpu_request_i2.cache == WB_READWRITE_ALLOCATE
				) && cpu_request_i2.we)
					tAccess();
			end
			if (cpu_request_i2.tid != lasttid && cpu_request_queued) begin
				lasttid <= cpu_request_i2.tid;
				cpu_request_queued <= 1'b0;
				wr_cnt <= 'd0;
			end
		end
	STATE5:
		begin
			to_cnt <= to_cnt + 2'd1;
			if (ftam_resp.ack) begin
				tBusClear();
				req_state <= RAND_DELAY;
			end
			else if (ftam_resp.rty) begin
				tBusClear();
				req_state <= STATE1;
			end
			if (to_cnt[10]) begin
				tBusClear();
				req_state <= RAND_DELAY;
			end
		end
	// Wait some random number of clocks before trying again.
	RAND_DELAY:
		begin
			tBusClear();
			if (wait_cnt==WAIT && lfsr_o[3:1]==3'b111)
				req_state <= STATE1;
			else if (wait_cnt != WAIT)
				wait_cnt <= wait_cnt + 2'd1;
		end
	default:	req_state <= RESET;
	endcase

	// Process responses.
	case(resp_state)
	RESET:
		begin
			for (nn = 0; nn < 16; nn = nn + 1)
				v[nn] <= 'd0;
			resp_state <= STATE1;
		end
	STATE1:
		begin
			if (ftam_resp.ack) begin
				// Got an ack back so the tran no longer needs to be performed.
				tran_active[ftam_resp.tid & 4'hF] <= 1'b0;
				tran_out[ftam_resp.tid & 4'hF] <= 1'b0;
				//tran_req[ftam_resp.tid & 4'hF].cyc <= 1'b0;
				tran_load_data[ftam_resp.tid & 4'hF].cid <= ftam_resp.cid;
				tran_load_data[ftam_resp.tid & 4'hF].tid <= ftam_resp.tid;
				tran_load_data[ftam_resp.tid & 4'hF].pri <= ftam_resp.pri;
				tran_load_data[ftam_resp.tid & 4'hF].adr <= {ftam_resp.adr[$bits(fta_address_t)-1:6],6'd0};
				case(ftam_resp.adr[5:4])
				2'd0: begin tran_load_data[ftam_resp.tid & 4'hF].dat[127:  0] <= ftam_resp.dat; v[ftam_resp.tid & 4'hF][0] <= 1'b1; end
				2'd1:	begin tran_load_data[ftam_resp.tid & 4'hF].dat[255:128] <= ftam_resp.dat; v[ftam_resp.tid & 4'hF][1] <= 1'b1; end
				2'd2:	begin tran_load_data[ftam_resp.tid & 4'hF].dat[383:256] <= ftam_resp.dat; v[ftam_resp.tid & 4'hF][2] <= 1'b1; end
				2'd3:	begin tran_load_data[ftam_resp.tid & 4'hF].dat[511:384] <= ftam_resp.dat; v[ftam_resp.tid & 4'hF][3] <= 1'b1; end
				endcase
				we_r <= ftam_req.we;
				tran_load_data[ftam_resp.tid & 4'hF].rty <= 1'b0;
				tran_load_data[ftam_resp.tid & 4'hF].err <= 1'b0;
				tran_load_data[ftam_resp.tid & 4'hF].ack <= 1'b1;
				v[ftam_resp.tid & 4'hF][ftam_resp.adr[5:4]] <= 'd1;
			end
			// Retry or error (only if transaction active)
			// Abort the memory request. Go back and try again.
			else if ((ftam_resp.rty|ftam_resp.err) & tran_active[ftam_resp.tid]) begin
				tran_load_data[ftam_resp.tid & 4'hF].rty <= ftam_resp.rty;
				tran_load_data[ftam_resp.tid & 4'hF].err <= ftam_resp.err;
				tran_load_data[ftam_resp.tid & 4'hF].ack <= 1'b0;
				tran_out[ftam_resp.tid & 4'hF] <= 1'b0;
				v[ftam_resp.tid & 4'hF][ftam_resp.adr[5:4]] <= 'd0;
			end
			for (nn = 0; nn < 16; nn = nn + 1)
				if (v[nn]==4'b1111) begin
					dump_ack <= is_dump[nn];
					is_dump[nn] <= 'd0;
					iway <= lfsr_o[LOG_WAYS:0];
					cache_load_data <= tran_load_data[nn];
					ndx <= nn;
					resp_state <= STATE3;
					// Write to cache only if response from TLB indicates a cacheable
					// address.
				end
		end
	STATE3:
		resp_state <= STATE4;
	// cache_load_data.ack is delayed a couple of cycles to give time to read the
	// cache.
	STATE4:
		begin
			if (!ftam_resp.ack) begin
				if (v[ndx]==4'b1111) begin	// it should be
					// We want to update the cache, but if its allocate on write the
					// cache needs to be loaded with data from RAM first before its
					// updated. Request a cache load.
					if (!hit & (~non_cacheable & dce & cpu_request_i.we & allocate) & !cache_load_r[ndx]) begin
						cache_load_r[ndx] <= 1'b1;
						req_load <= 1'b1;
						load_cnt <= 'd0;
					end
					// If we have a hit on the cache line, write the data to the cache if
					// it is a writeable cacheable transaction.
					else if (hit) begin
						wr <= (~non_cacheable & dce & cpu_request_i.we & allocate);
						v[ndx] <= 'd0;
						cache_load_data.ack <= !cache_dump;
						cache_dump <= 'd0;
						cache_load <= 'd0;
						cache_load_r[ndx] <= 'd0;
						resp_state <= STATE1;
					end
					// No hit on the cache line and not allocating, we're done.
					else begin
						v[ndx] <= 'd0;
						cache_load_data.ack <= !cache_dump;
						cache_load <= 'd0;
						cache_load_r[ndx] <= 'd0;
						resp_state <= STATE1;
					end
				end
				else
					resp_state <= STATE1;
			end
			else
				resp_state <= STATE1;
		end
	default:	resp_state <= STATE1;
	endcase
	// Only the cache index need be compared for snoop hit.
	if (snoop_v && snoop_adr[rfx32_cache_pkg::ITAG_BIT:rfx32_cache_pkg::ICacheTagLoBit]==
		cpu_request_i2.vadr[rfx32_cache_pkg::ITAG_BIT:rfx32_cache_pkg::ICacheTagLoBit] && snoop_cid==CID) begin
		tBusClear();
		wr <= 1'b0;
		// Force any transactions matching the snoop address to retry.
		for (nn = 0; nn < 16; nn = nn + 1)
			// Note: the tag bits are compared only for the addresses that would match
			// between the virtual and physical. The cache line number. Need to match on 
			// the physical address returning from snoop, but only have the virtual
			// address available.
			if (cpu_request_i2.vadr[rfx32_cache_pkg::ITAG_BIT:rfx32_cache_pkg::ICacheTagLoBit] ==
				tran_load_data[nn].adr[rfx32_cache_pkg::ITAG_BIT:rfx32_cache_pkg::ICacheTagLoBit]) begin
				v[nn] <= 'd0;
				tran_load_data[nn].rty <= 1'b1;
			end
			if (cpu_request_i2.vadr[rfx32_cache_pkg::ITAG_BIT:rfx32_cache_pkg::ICacheTagLoBit]==
				cpu_req_queue[nn].vadr[rfx32_cache_pkg::ITAG_BIT:rfx32_cache_pkg::ICacheTagLoBit])
				cpu_req_queue[nn] <= 'd0;
		req_state <= STATE1;		
		resp_state <= STATE1;	
	end
end

task tBusClear;
begin
	ftam_req.cyc <= 1'b0;
	ftam_req.stb <= 1'b0;
	ftam_req.sel <= 16'h0000;
	ftam_req.we <= 1'b0;
end
endtask

task tAddr;
input fta_operating_mode_t om;
input wr;
input cache;
input rfx32pkg::asid_t asid;
input rfx32pkg::address_t adr;
input [127:0] data;
begin
	tid_cnt[7:4] <= {CORENO,1'b1};
	tid_cnt[3] <= 1'b0;
	tid_cnt[2:0] <= tid_cnt[2:0] + 2'd1;
	to_cnt <= 'd0;
	tran_req[tid_cnt & 4'hF].om <= om;
	tran_req[tid_cnt & 4'hF].cmd <= wr ? fta_bus_pkg::CMD_STORE : 
		cache ? fta_bus_pkg::CMD_DCACHE_LOAD : fta_bus_pkg::CMD_LOADZ;
	tran_req[tid_cnt & 4'hF].sz <= fta_bus_pkg::hexi;
	tran_req[tid_cnt & 4'hF].blen <= 'd0;
	tran_req[tid_cnt & 4'hF].cid <= 3'd7;
	tran_req[tid_cnt & 4'hF].tid <= tid_cnt;
	tran_req[tid_cnt & 4'hF].bte <= fta_bus_pkg::LINEAR;
	tran_req[tid_cnt & 4'hF].cti <= fta_bus_pkg::CLASSIC;
	tran_req[tid_cnt & 4'hF].cyc <= 1'b1;
	tran_req[tid_cnt & 4'hF].stb <= 1'b1;
	tran_req[tid_cnt & 4'hF].sel <= 16'hFFFF;
	tran_req[tid_cnt & 4'hF].we <= wr;
	tran_req[tid_cnt & 4'hF].csr <= 'd0;
	tran_req[tid_cnt & 4'hF].asid <= asid;
	tran_req[tid_cnt & 4'hF].vadr <= adr;
	tran_req[tid_cnt & 4'hF].data1 <= data;
	tran_req[tid_cnt & 4'hF].pl <= 'd0;
	tran_req[tid_cnt & 4'hF].pri <= 4'h7;
	tran_req[tid_cnt & 4'hF].cache <= fta_bus_pkg::CACHEABLE;
	tran_req[tid_cnt & 4'hF].seg <= fta_bus_pkg::DATA;
	tran_active[tid_cnt & 4'hF] <= 1'b1;
	tran_load_data[tid_cnt & 4'hF].adr <= adr;
	cpu_req_queue[cpu_request_i2.tid & 15] <= 'd0;
end
endtask

task tAccess;
fta_address_t ta;
begin
	if (wr_cnt == 2'd3) begin
		cpu_request_queued <= 1'b1;
		wr_cnt <= 'd0;
	end
	else
		wr_cnt <= wr_cnt + 2'd1;
	// Access only the strip of memory requested. It could be an I/O device.
	if (wr_cnt==2'd0)
		v[tid_cnt & 4'hF] <= 4'b1111;
	ta = {cpu_request_i2.vadr[$bits(fta_address_t)-1:rfx32_cache_pkg::DCacheTagLoBit],wr_cnt,{rfx32_cache_pkg::DCacheTagLoBit-2{1'h0}}};
	case(wr_cnt)
	2'd0:	
		if (|cpu_request_i2.sel[15: 0]) begin
			v[tid_cnt & 4'hF][0] <= 1'b0;
			tAddr(
				cpu_request_i2.om,
				cpu_request_i2.we,
				!non_cacheable,
				cpu_request_i2.asid,
				{cpu_request_i2.vadr[$bits(fta_address_t)-1:rfx32_cache_pkg::DCacheTagLoBit],wr_cnt,{rfx32_cache_pkg::DCacheTagLoBit-2{1'h0}}},
				cpu_request_i2.dat[127:0]
			);
			req_state <= RAND_DELAY;
		end
	2'd1:	
		if (|cpu_request_i2.sel[31:16]) begin
			v[tid_cnt & 4'hF][1] <= 1'b0;
			tAddr(
				cpu_request_i2.om,
				cpu_request_i2.we,
				!non_cacheable,
				cpu_request_i2.asid,
				{cpu_request_i2.vadr[$bits(fta_address_t)-1:rfx32_cache_pkg::DCacheTagLoBit],wr_cnt,{rfx32_cache_pkg::DCacheTagLoBit-2{1'h0}}},
				cpu_request_i2.dat[255:128]
			);
			req_state <= RAND_DELAY;
		end
	2'd2:
		if (|cpu_request_i2.sel[47:32]) begin
			v[tid_cnt & 4'hF][2] <= 1'b0;
			tAddr(
				cpu_request_i2.om,
				cpu_request_i2.we,
				!non_cacheable,
				cpu_request_i2.asid,
				{cpu_request_i2.vadr[$bits(fta_address_t)-1:rfx32_cache_pkg::DCacheTagLoBit],wr_cnt,{rfx32_cache_pkg::DCacheTagLoBit-2{1'h0}}},
				cpu_request_i2.dat[383:256]
			);
			req_state <= RAND_DELAY;
		end
	2'd3: 
		if (|cpu_request_i2.sel[63:48]) begin
			v[tid_cnt & 4'hF][3] <= 1'b0;
			tAddr(
				cpu_request_i2.om,
				cpu_request_i2.we,
				!non_cacheable,
				cpu_request_i2.asid,
				{cpu_request_i2.vadr[$bits(fta_address_t)-1:rfx32_cache_pkg::DCacheTagLoBit],wr_cnt,{rfx32_cache_pkg::DCacheTagLoBit-2{1'h0}}},
				cpu_request_i2.dat[511:384]
			);
			req_state <= RAND_DELAY;
		end
	endcase
end
endtask

endmodule
