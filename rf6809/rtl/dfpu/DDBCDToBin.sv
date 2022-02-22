`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DDBCDToBin.sv
//  Uses the Dubble Dabble algorithm
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
module DDBCDToBin(rst, clk, ld, bcd, bin, done);
parameter WID = 128;
parameter DEP =	2;		// cascade depth
localparam BCDWID = ((WID+(WID-4)/3)+3) & -4;
input rst;
input clk;
input ld;
input [BCDWID-1:0] bcd;
output reg [WID-1:0] bin;
output reg done;

integer k;
genvar n,g;
reg [WID-1:0] binw, binwt;			// working binary value
reg [BCDWID-1:0] bcdwt;
reg [BCDWID-1:0] bcdw [0:DEP];	// working bcd value
reg [7:0] bitcnt;
reg [2:0] state;
parameter IDLE = 3'd0;
parameter CHK5 = 3'd1;
parameter SHFT = 3'd2;
parameter DONE = 3'd3;

function [BCDWID-1:0] fnRow;
input [BCDWID-1:0] i;
begin
	fnRow = 'd0;
	for (k = 0; k < BCDWID; k = k + 4)
		if (((i >> k) & 4'hF) >= 4'd8)
			fnRow = fnRow | (((i >> k) & 4'hF) - 4'd3) << k;
		else
			fnRow = fnRow | ((i >> k) & 4'hf) << k;
end
endfunction

always_comb
	bcdw[0] = bcdwt;
generate begin : gRows
	for (n = 0; n < DEP; n = n + 1)
		always_comb
		begin
			binwt[WID-DEP+n] = bcdw[n][0];
			bcdw[n+1] = fnRow({1'b0,bcdw[n][BCDWID-1:1]});
		end
end
endgenerate

always_ff @(posedge clk)
if (rst) begin
	state <= IDLE;
	done <= 1'b1;
	bcdwt <= 'd0;
	binw <= 'd0;
	bitcnt <= 'd0;
	bin <= 'd0;
end
else begin
	if (ld) begin
		done <= 1'b0;
		bitcnt <= (WID+DEP-1)/DEP-1;
		binw <= 'd0;
		bcdwt <= bcd;
		state <= SHFT;
	end
	else
	case(state)
	IDLE:	;
	SHFT:
		begin
			bitcnt <= bitcnt - 2'd1;
			if (bitcnt==8'd0) begin
				state <= DONE;
			end
			bcdwt <= bcdw[DEP];
			binw <= {binwt[WID-1:WID-DEP],binw[WID-1:DEP]};
		end
	DONE:
		begin
			bin <= binw;
			done <= 1'b1;
			state <= IDLE;
		end
	default:
		state <= IDLE;
	endcase
end


endmodule
