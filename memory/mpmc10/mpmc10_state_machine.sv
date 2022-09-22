`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2022  Robert Finch, Waterloo
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
//
import mpmc10_pkg::*;

module mpmc10_state_machine(rst, clk, to, rdy, wdf_rdy, fifo_empty, rd_fifo, fifo_out, state,
	num_strips, req_strip_cnt, resp_strip_cnt, rd_data_valid, wway);
input rst;
input clk;
input to;							// state machine time-out
input rdy;
input wdf_rdy;
input fifo_empty;
output reg rd_fifo;
input axi_request_readwrite256_t fifo_out;
output reg [3:0] state;
input [5:0] num_strips;
input [5:0] req_strip_cnt;
input [5:0] resp_strip_cnt;
input rd_data_valid;
output reg [1:0] wway;

reg [3:0] next_state;
reg next_rd_fifo;

always_ff @(posedge clk)
	state <= next_state;
always_ff @(posedge clk)
	rd_fifo <= next_rd_fifo;
always_ff @(posedge clk)
if (rst)
	wway <= 2'd0;
else begin
	if (state==PRESET1)
		wway <= wway + 2'd1;
end

always_comb
if (rst) begin
	next_state <= IDLE;	
	next_rd_fifo <= 1'b0;
end
else begin
	next_rd_fifo <= 1'b0;
	case(state)
	IDLE:
		begin
			if (!fifo_empty) begin
				next_rd_fifo <= 1'b1;
				next_state <= PRESET1;
			end
		end
	PRESET1:
		next_state <= PRESET2;
	PRESET2:
		next_state <= PRESET3;
	PRESET3:
		if (fifo_out.write.WVALID)
			next_state <= WRITE_DATA0;
		else
			next_state <= READ_DATA0;
	// Write data to the data fifo
	// Write occurs when app_wdf_wren is true and app_wdf_rdy is true
	WRITE_DATA0:
		// Issue a write command if the fifo is full.
	//	if (!app_wdf_rdy)
	//		next_state <= WRITE_DATA1;
	//	else 
		if (wdf_rdy)// && req_strip_cnt==num_strips)
			next_state <= WRITE_DATA1;
		else
			next_state <= WRITE_DATA0;
	WRITE_DATA1:
		next_state <= WRITE_DATA2;
	WRITE_DATA2:
		if (rdy)
			next_state <= WRITE_DATA3;
		else
			next_state <= WRITE_DATA2;
	WRITE_DATA3:
		next_state <= IDLE;

	// There could be multiple read requests submitted before any response occurs.
	// Stay in the SET_CMD_RD until all requested strips have been processed.
	READ_DATA0:
		next_state <= READ_DATA1;
	// Could it take so long to do the request that we start getting responses
	// back?
	READ_DATA1:
		if (rdy && req_strip_cnt==num_strips)
			next_state <= READ_DATA2;
		else
			next_state <= READ_DATA1;
	// Wait for incoming responses, but only for so long to prevent a hang.
	READ_DATA2:
		if (rd_data_valid && resp_strip_cnt==num_strips)
			next_state <= WAIT_NACK;
		else
			next_state <= READ_DATA2;

	WAIT_NACK:
		// If we're not seeing a nack and there is a channel selected, then the
		// cache tag must not have updated correctly.
		// For writes, assume a nack by now.
		next_state <= IDLE;
		
	default:	next_state <= IDLE;
	endcase

	// Is the state machine hung?
	if (to)
		next_state <= IDLE;
end

endmodule
