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
import mpmc8_pkg::*;

module mpmc8_addr_resv_man(rst, clk, state,
	cs1, ack1, we1, adr1, sr1, cr1, ch1_taghit,
	cs7, ack7, we7, adr7, sr7, cr7, ch7_taghit,
	resv_ch, resv_adr);
input rst;
input clk;
input [3:0] state;
input cs1;
input ack1;
input we1;
input [31:0] adr1;
input sr1;
input cr1;
input ch1_taghit;
input cs7;
input ack7;
input we7;
input [31:0] adr7;
input sr7;
input cr7;
input ch7_taghit;
output reg [3:0] resv_ch [0:NAR-1];
output reg [31:0] resv_adr [0:NAR-1];

reg [19:0] resv_to_cnt;
reg toggle, toggle_sr;

// For address reservation below
reg [7:0] match;
always @(posedge clk)
if (rst)
	match <= 8'h00;
else begin
	if (match >= NAR)
		match <= 8'h00;
	else
		match <= match + 8'd1;
end

// Managing address reservations
integer n7;
always_ff @(posedge clk)
if (rst) begin
	resv_to_cnt <= 20'd0;
	toggle <= FALSE;
	toggle_sr <= FALSE;
 	for (n7 = 0; n7 < NAR; n7 = n7 + 1)
		resv_ch[n7] <= 4'hF;
end
else begin
	resv_to_cnt <= resv_to_cnt + 20'd1;

	if (sr1 & sr7) begin
		if (toggle_sr) begin
			reserve_adr(4'h1,adr1);
			toggle_sr <= 1'b0;
		end
		else begin
			reserve_adr(4'h7,adr7);
			toggle_sr <= 1'b1;
		end
	end
	else begin
		if (sr1)
			reserve_adr(4'h1,adr1);
		if (sr7)
			reserve_adr(4'h7,adr7);
	end

	if (state==IDLE) begin
		if (cs1 & we1 & ~ack1) begin
		    toggle <= 1'b1;
		    if (cr1) begin
		    	for (n7 = 0; n7 < NAR; n7 = n7 + 1)
		        if ((resv_ch[n7]==4'd1) && (resv_adr[n7][31:4]==adr1[31:4]))
		            resv_ch[n7] <= 4'hF;
		    end
		end
		else if (cs7 & we7 & ~ack7) begin
		    toggle <= 1'b1;
		    if (cr7) begin
		    	for (n7 = 0; n7 < NAR; n7 = n7 + 1)
		        if ((resv_ch[n7]==4'd7) && (resv_adr[n7][31:4]==adr7[31:4]))
		            resv_ch[n7] <= 4'hF;
		    end
		end
		else if (!we1 & cs1 & ~ch1_taghit & (cs7 ? toggle : 1'b1))
			toggle <= 1'b0;
		else if (!we7 & cs7 & ~ch7_taghit)
			toggle <= 1'b1;
	end
end

integer empty_resv;
function resv_held;
input [3:0] ch;
input [31:0] adr;
integer n8;
begin
	resv_held = FALSE;
 	for (n8 = 0; n8 < NAR; n8 = n8 + 1)
 		if (resv_ch[n8]==ch && resv_adr[n8]==adr)
 			resv_held = TRUE;
end
endfunction

// Find an empty reservation bucket
integer n9;
always_comb
begin
	empty_resv <= -1;
 	for (n9 = 0; n9 < NAR; n9 = n9 + 1)
		if (resv_ch[n9]==4'hF)
			empty_resv <= n9;
end

// Two reservation buckets are allowed for. There are two (or more) CPU's in the
// system and as long as they are not trying to control the same resource (the
// same semaphore) then they should be able to set a reservation. Ideally there
// could be more reservation buckets available, but it starts to be a lot of
// hardware.
task reserve_adr;
input [3:0] ch;
input [31:0] adr;
begin
	// Ignore an attempt to reserve an address that's already reserved. The LWAR
	// instruction is usually called in a loop and we don't want it to use up
	// all address reservations.
	if (!resv_held(ch,adr)) begin
		if (empty_resv >= 0) begin
			resv_ch[empty_resv] <= ch;
			resv_adr[empty_resv] <= adr;
		end
		// Here there were no free reservation buckets, so toss one of the
		// old reservations out.
		else begin
			resv_ch[match] <= ch;
			resv_adr[match] <= adr;
		end
	end
end
endtask

endmodule
