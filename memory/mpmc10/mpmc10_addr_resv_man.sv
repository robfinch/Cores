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

module mpmc10_addr_resv_man(rst, clk, state,
	adr0, adr1, adr2, adr3, adr4, adr5, adr6, adr7,
	sr0, sr1, sr2, sr3, sr4, sr5, sr6, sr7,
	wch, we, wadr, cr, ch1_taghit,
	resv_ch, resv_adr, rack);
parameter NAR = 2;
input rst;
input clk;
input [3:0] state;
input [31:0] adr0;
input [31:0] adr1;
input [31:0] adr2;
input [31:0] adr3;
input [31:0] adr4;
input [31:0] adr5;
input [31:0] adr6;
input [31:0] adr7;
input sr0;
input sr1;
input sr2;
input sr3;
input sr4;
input sr5;
input sr6;
input sr7;
input [3:0] wch;
input cr;
input we;
input [31:0] wadr;
input ch1_taghit;
output reg [3:0] resv_ch [0:NAR-1];
output reg [31:0] resv_adr [0:NAR-1];
output reg [7:0] rack;	// reservation acknowledged

reg [19:0] resv_to_cnt;
wire [2:0] enc;
wire [7:0] srr = {sr7,sr6,sr5,sr4,sr3,sr2,sr1,sr0};
wire [31:0] adr [0:7];

assign adr[0] = adr0;
assign adr[1] = adr1;
assign adr[2] = adr2;
assign adr[3] = adr3;
assign adr[4] = adr4;
assign adr[5] = adr5;
assign adr[6] = adr6;
assign adr[7] = adr7;

roundRobin urr1
(
	.rst(rst),
	.clk(clk),
	.ce(1'b1),
	.req(srr),
	.lock(8'h00),
	.sel(),
	.sel_enc(enc)
);

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

always_comb
	rack = ~srr | srr[enc];
	
// Managing address reservations
integer n7;
always_ff @(posedge clk)
if (rst) begin
	resv_to_cnt <= 20'd0;
 	for (n7 = 0; n7 < NAR; n7 = n7 + 1)
		resv_ch[n7] <= 4'hF;
end
else begin
	resv_to_cnt <= resv_to_cnt + 20'd1;

	for (n7 = 0; n7 < 8; n7 = n7 + 1)
		if (enc==n7 && |srr)
			reserve_adr({1'b0,n7[2:0]},adr[n7]);

	if (state==IDLE) begin
		if (we) begin
	    if (cr) begin
	    	for (n7 = 0; n7 < NAR; n7 = n7 + 1)
	        if ((resv_ch[n7]==wch) && (resv_adr[n7][31:4]==wadr[31:4]))
            resv_ch[n7] <= 4'hF;
	    end
		end
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
 		if (resv_ch[n8]==ch && resv_adr[n8][31:5]==adr[31:5])
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
