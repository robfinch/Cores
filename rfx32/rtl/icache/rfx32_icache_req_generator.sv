// ============================================================================
//        __
//   \\__/ o\    (C) 2021-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfx32_icache_req_generator.sv
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

module rfx32_icache_req_generator(rst, clk, hit, miss_adr, miss_asid,
	wbm_req, wbm_resp, vtags, snoop_v, snoop_adr, snoop_cid);
parameter CORENO = 6'd1;
parameter CID = 6'd1;
parameter WAIT = 6'd6;
input rst;
input clk;
input hit;
input fta_address_t miss_adr;
input rfx32pkg::asid_t miss_asid;
output fta_cmd_request128_t wbm_req;
input fta_cmd_response128_t wbm_resp;
output rfx32pkg::address_t [15:0] vtags;
input snoop_v;
input fta_address_t snoop_adr;
input [5:0] snoop_cid;


typedef enum logic [3:0] {
	RESET = 0,
	WAIT4MISS,STATE2,STATE3,STATE4,STATE5,DELAY1,RAND_DELAY
} state_t;
state_t req_state;

rfx32pkg::address_t madr, vadr;
reg [7:0] lfsr_cnt;
fta_tranid_t tid_cnt;
wire [16:0] lfsr_o;
reg [5:0] wait_cnt;

lfsr17 #(.WID(17)) ulfsr1
(
	.rst(rst),
	.clk(clk),
	.ce(req_state != RESET),
	.cyc(1'b0),
	.o(lfsr_o)
);

always_ff @(posedge clk, posedge rst)
if (rst) begin
	req_state <= RESET;
	tid_cnt <= {CORENO,1'b0,4'h0};
	wbm_req <= 'd0;
	lfsr_cnt <= 'd0;
	wait_cnt <= 'd0;
	vtags <= 'd0;
end
else begin
	case(req_state)
	RESET:
		begin
			wbm_req.asid <= 'd0;
			wbm_req.cmd <= fta_bus_pkg::CMD_ICACHE_LOAD;
			wbm_req.sz  <= fta_bus_pkg::hexi;
			wbm_req.blen <= 'd0;
			wbm_req.cid <= 3'd7;					// CPU channel id
			wbm_req.tid <= 'd0;
			wbm_req.csr  <= 'd0;					// clear/set reservation
			wbm_req.pl	<= 'd0;						// privilege level
			wbm_req.pri	<= 4'h7;					// average priority (higher is better).
			wbm_req.cache <= fta_bus_pkg::CACHEABLE;
			wbm_req.seg <= fta_bus_pkg::CODE;
			wbm_req.bte <= fta_bus_pkg::LINEAR;
			wbm_req.cti <= fta_bus_pkg::CLASSIC;
			wbm_req.cyc <= 1'b0;
			wbm_req.stb <= 1'b0;
			wbm_req.sel <= 16'h0000;
			wbm_req.we <= 1'b0;
			if (lfsr_cnt=={CID,2'b0})
				req_state <= WAIT4MISS;
			lfsr_cnt <= lfsr_cnt + 2'd1;
		end
	WAIT4MISS:
		if (!hit) begin
			tid_cnt[7:4] <= {CORENO,1'b0};
			wbm_req.tid <= tid_cnt;
			wbm_req.blen <= 6'd1;
			wbm_req.cti <= fta_bus_pkg::FIXED;
			wbm_req.cyc <= 1'b1;
			wbm_req.stb <= 1'b1;
			wbm_req.sel <= 16'hFFFF;
			wbm_req.we <= 1'b0;
			wbm_req.vadr <= {miss_adr[$bits(fta_address_t)-1:rfx32_cache_pkg::ICacheTagLoBit],{rfx32_cache_pkg::ICacheTagLoBit{1'h0}}};
			wbm_req.asid <= miss_asid;
			vtags[tid_cnt & 4'hF] <= {miss_adr[$bits(fta_address_t)-1:rfx32_cache_pkg::ICacheTagLoBit],{rfx32_cache_pkg::ICacheTagLoBit{1'h0}}};
			vadr <= {miss_adr[$bits(fta_address_t)-1:rfx32_cache_pkg::ICacheTagLoBit],{rfx32_cache_pkg::ICacheTagLoBit{1'h0}}};
			madr <= {miss_adr[$bits(fta_address_t)-1:rfx32_cache_pkg::ICacheTagLoBit],{rfx32_cache_pkg::ICacheTagLoBit{1'h0}}};
			if (!wbm_resp.rty) begin
				tid_cnt[2:0] <= tid_cnt[2:0] + 2'd1;
				req_state <= STATE3;
			end
		end
	STATE3:
		begin
			tid_cnt[7:4] <= {CORENO,1'b0};
			wbm_req.tid <= tid_cnt;
			wbm_req.cti <= fta_bus_pkg::FIXED;
			wbm_req.stb <= 1'b1;
			wbm_req.sel <= 16'hFFFF;
			wbm_req.vadr <= vadr + 5'd16;
			vtags[tid_cnt & 4'hF] <= madr + 5'd16;
			if (!wbm_resp.rty) begin
				vadr <= vadr + 5'd16;
				madr <= madr + 5'd16;
				tid_cnt[2:0] <= tid_cnt[2:0] + 2'd1;
				req_state <= STATE4;
			end
		end
	STATE4:
		begin
			tid_cnt[7:4] <= {CORENO,1'b0};
			wbm_req.tid <= tid_cnt;
			wbm_req.cti <= fta_bus_pkg::FIXED;
			wbm_req.stb <= 1'b1;
			wbm_req.sel <= 16'hFFFF;
			wbm_req.vadr <= vadr + 5'd16;
			vtags[tid_cnt & 4'hF] <= madr + 5'd16;
			if (!wbm_resp.rty) begin
				vadr <= vadr + 5'd16;
				madr <= madr + 5'd16;
				tid_cnt[2:0] <= tid_cnt[2:0] + 2'd1;
				req_state <= STATE5;
			end
		end
	STATE5:
		begin
			tid_cnt[7:4] <= {CORENO,1'b0};
			wbm_req.tid <= tid_cnt;
			wbm_req.cti <= fta_bus_pkg::EOB;
			wbm_req.stb <= 1'b1;
			wbm_req.sel <= 16'hFFFF;
			wbm_req.vadr <= vadr + 5'd16;
			vtags[tid_cnt & 4'hF] <= madr + 5'd16;
			if (!wbm_resp.rty) begin
				wait_cnt <= 'd0;
				vadr <= vadr + 5'd16;
				madr <= madr + 5'd16;
				tid_cnt[2:0] <= tid_cnt[2:0] + 2'd1;
				req_state <= RAND_DELAY;
			end
		end
	DELAY1:
		begin
			tBusClear();
			req_state <= WAIT4MISS;
		end
	// Wait some random number of clocks before trying again.
	RAND_DELAY:
		begin
			tBusClear();
			if (wait_cnt==WAIT && lfsr_o[2:0]==3'b111)
				req_state <= WAIT4MISS;
			else if (wait_cnt != WAIT)
				wait_cnt <= wait_cnt + 2'd1;
		end
	default:
		req_state <= RESET;
	endcase
	// Only the cache index need be compared for snoop hit.
	if (snoop_v && snoop_adr[rfx32_cache_pkg::ITAG_BIT:rfx32_cache_pkg::ICacheTagLoBit]==
		miss_adr[rfx32_cache_pkg::ITAG_BIT:rfx32_cache_pkg::ICacheTagLoBit] &&
		snoop_cid != CID) begin
		tBusClear();
		req_state <= RAND_DELAY;		
	end
end

task tBusClear;
begin
	wbm_req.cti <= fta_bus_pkg::CLASSIC;
	wbm_req.cyc <= 1'b0;
	wbm_req.stb <= 1'b0;
	wbm_req.sel <= 16'h0000;
	wbm_req.we <= 1'b0;
end
endtask

endmodule
