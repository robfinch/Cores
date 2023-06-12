`timescale 1ns / 10ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// ============================================================================

import fta_bus_pkg::*;

module fta_respbuf(rst, clk, resp, resp_o);
parameter CHANNELS = 8;
localparam HBIT = $clog2(CHANNELS);
input rst;
input clk;
input fta_cmd_response128_t [CHANNELS-1:0] resp;
output fta_cmd_response128_t resp_o;

fta_cmd_response128_t [CHANNELS-1:0] respbuf;

reg [HBIT:0] tmp;

integer nn1, nn2;

// Search for channel with response ready.
always_comb
begin
	tmp <= {HBIT+1{1'b1}};
	for (nn1 = 0; nn1 < CHANNELS; nn1 = nn1 + 1) begin
		if (respbuf[nn1].ack) begin
			tmp <= nn1;
		end
	end
end

always_ff @(posedge clk, posedge rst)
if (rst) begin
	for (nn2 = 0; nn2 < CHANNELS; nn2 = nn2 + 1) begin
		respbuf[nn2] <= 'd0;		
	end
end
else begin
	resp_o.ack <= 1'b0;
	resp_o.err <= 'd0;
	resp_o.rty <= 'd0;
	resp_o.dat <= 'd0;
	resp_o.tid <= 'd0;
	resp_o.cid <= 'd0;
	resp_o.adr <= 'd0;
	resp_o.stall <= 'd0;
	resp_o.next <= 'd0;
	resp_o.pri <= 4'hF;
	if (!tmp[HBIT]) begin
		respbuf[tmp[HBIT-1:0]].ack <= 1'b0;
		resp_o.ack <= 1'b1;
		resp_o.err <= respbuf[tmp[HBIT-1:0]].err;
		resp_o.rty <= respbuf[tmp[HBIT-1:0]].rty;
		resp_o.dat <= respbuf[tmp[HBIT-1:0]].dat;
		resp_o.cid <= respbuf[tmp[HBIT-1:0]].cid;
		resp_o.tid <= respbuf[tmp[HBIT-1:0]].tid;
		resp_o.adr <= respbuf[tmp[HBIT-1:0]].adr;
		resp_o.pri <= respbuf[tmp[HBIT-1:0]].pri;
	end
	for (nn2 = 0; nn2 < CHANNELS; nn2 = nn2 + 1) begin
		if (resp[nn2].ack) begin
			respbuf[nn2] <= resp[nn2];
			respbuf[nn2].ack <= 1'b1;
		end
	end
end

endmodule

module fta_respbuf64(rst, clk, resp, resp_o);
parameter CHANNELS = 8;
localparam HBIT = $clog2(CHANNELS);
input rst;
input clk;
input fta_cmd_response64_t [CHANNELS-1:0] resp;
output fta_cmd_response64_t resp_o;

fta_cmd_response64_t [CHANNELS-1:0] respbuf;

reg [HBIT:0] tmp;

integer nn1, nn2;

// Search for channel with response ready.
always_comb
begin
	tmp <= {HBIT+1{1'b1}};
	for (nn1 = 0; nn1 < CHANNELS; nn1 = nn1 + 1) begin
		if (respbuf[nn1].ack) begin
			tmp <= nn1;
		end
	end
end

always_ff @(posedge clk, posedge rst)
if (rst) begin
	for (nn2 = 0; nn2 < CHANNELS; nn2 = nn2 + 1) begin
		respbuf[nn2] <= 'd0;		
	end
end
else begin
	resp_o.ack <= 1'b0;
	resp_o.err <= 'd0;
	resp_o.rty <= 'd0;
	resp_o.dat <= 'd0;
	resp_o.tid <= 'd0;
	resp_o.adr <= 'd0;
	resp_o.stall <= 'd0;
	resp_o.next <= 'd0;
	if (!tmp[HBIT]) begin
		respbuf[tmp[HBIT-1:0]].ack <= 1'b0;
		resp_o.ack <= 1'b1;
		resp_o.err <= respbuf[tmp[HBIT-1:0]].err;
		resp_o.rty <= respbuf[tmp[HBIT-1:0]].rty;
		resp_o.dat <= respbuf[tmp[HBIT-1:0]].dat;
		resp_o.cid <= respbuf[tmp[HBIT-1:0]].cid;
		resp_o.tid <= respbuf[tmp[HBIT-1:0]].tid;
		resp_o.adr <= respbuf[tmp[HBIT-1:0]].adr;
		resp_o.pri <= respbuf[tmp[HBIT-1:0]].pri;
	end
	for (nn2 = 0; nn2 < CHANNELS; nn2 = nn2 + 1) begin
		if (resp[nn2].ack) begin
			respbuf[nn2] <= resp[nn2];
			respbuf[nn2].ack <= 1'b1;
		end
	end
end

endmodule

module fta_respbuf32(rst, clk, resp, resp_o);
parameter CHANNELS = 8;
localparam HBIT = $clog2(CHANNELS);
input rst;
input clk;
input fta_cmd_response32_t [CHANNELS-1:0] resp;
output fta_cmd_response32_t resp_o;

fta_cmd_response32_t [CHANNELS-1:0] respbuf;

reg [HBIT:0] tmp;

integer nn1, nn2;

// Search for channel with response ready.
always_comb
begin
	tmp <= {HBIT+1{1'b1}};
	for (nn1 = 0; nn1 < CHANNELS; nn1 = nn1 + 1) begin
		if (respbuf[nn1].ack) begin
			tmp <= nn1;
		end
	end
end

always_ff @(posedge clk, posedge rst)
if (rst) begin
	for (nn2 = 0; nn2 < CHANNELS; nn2 = nn2 + 1) begin
		respbuf[nn2] <= 'd0;		
	end
end
else begin
	resp_o.ack <= 1'b0;
	resp_o.err <= 'd0;
	resp_o.rty <= 'd0;
	resp_o.dat <= 'd0;
	resp_o.tid <= 'd0;
	resp_o.adr <= 'd0;
	resp_o.stall <= 'd0;
	resp_o.next <= 'd0;
	if (!tmp[HBIT]) begin
		respbuf[tmp[HBIT-1:0]].ack <= 1'b0;
		resp_o.ack <= 1'b1;
		resp_o.err <= respbuf[tmp[HBIT-1:0]].err;
		resp_o.rty <= respbuf[tmp[HBIT-1:0]].rty;
		resp_o.dat <= respbuf[tmp[HBIT-1:0]].dat;
		resp_o.cid <= respbuf[tmp[HBIT-1:0]].cid;
		resp_o.tid <= respbuf[tmp[HBIT-1:0]].tid;
		resp_o.adr <= respbuf[tmp[HBIT-1:0]].adr;
		resp_o.pri <= respbuf[tmp[HBIT-1:0]].pri;
	end
	for (nn2 = 0; nn2 < CHANNELS; nn2 = nn2 + 1) begin
		if (resp[nn2].ack) begin
			respbuf[nn2] <= resp[nn2];
			respbuf[nn2].ack <= 1'b1;
		end
	end
end

endmodule
