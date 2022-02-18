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

module mpmc8_ch_prioritize(clk, elevate,
	cs0, cs1, cs2, cs3, cs4, cs5, cs6, cs7,
	we0, we1, we2, we3, we4, we5, we6, we7,
	ch0_taghit, ch1_taghit, ch2_taghit, ch3_taghit,
	ch4_taghit, ch5_taghit, ch6_taghit, ch7_taghit,
	ch);
input clk;
input elevate;
input cs0;
input cs1;
input cs2;
input cs3;
input cs4;
input cs5;
input cs6;
input cs7;
input we0;
input we1;
input we2;
input we3;
input we4;
input we5;
input we6;
input we7;
input ch0_taghit;
input ch1_taghit;
input ch2_taghit;
input ch3_taghit;
input ch4_taghit;
input ch5_taghit;
input ch6_taghit;
input ch7_taghit;
output reg [3:0] ch;


// Select the channel
// This prioritizes the channel during the IDLE state.
// During an elevate cycle the channel priorities are reversed.
always_ff @(posedge clk)
begin
	if (elevate) begin
		if (cs7 & we7)
			ch <= 4'd7;
		else if (cs6 & we6)
			ch <= 4'd6;
		else if (cs5 & we5)
			ch <= 4'd5;
		else if (cs4 & we4)
			ch <= 4'd4;
		else if (cs3 & we3)
			ch <= 4'd3;
		else if (cs2 & we2)
			ch <= 4'd2;
		else if (cs1 & we1)
			ch <= 4'd1;
		else if (cs0 & we0)
			ch <= 4'd0;
		else if (cs7 & ~ch7_taghit)
			ch <= 4'd7;
		else if (cs6 & ~ch6_taghit)
			ch <= 4'd6;
		else if (cs5 & ~ch5_taghit)
			ch <= 4'd5;
		else if (cs4 & ~ch4_taghit)
			ch <= 4'd4;
		else if (cs3 & ~ch3_taghit)
			ch <= 4'd3;
		else if (cs2 & ~ch2_taghit)
			ch <= 4'd2;
		else if (cs1 & ~ch1_taghit)
			ch <= 4'd1;
		else if (cs0 & ~ch0_taghit)
			ch <= 4'd0;
		else
			ch <= 4'hF;
	end
	// Channel 0 read or write takes precedence
	else if (cs0 & we0)
		ch <= 4'd0;
	else if (cs0 & ~ch0_taghit)
		ch <= 4'd0;
	else if (cs1 & we1)
		ch <= 4'd1;
	else if (cs2 & we2)
		ch <= 4'd2;
	else if (cs3 & we3)
		ch <= 4'd3;
	else if (cs4 & we4)
		ch <= 4'd4;
	else if (cs6 & we6)
		ch <= 4'd6;
	else if (cs7 & we7)
		ch <= 4'd7;
	// Reads, writes detected above
	else if (cs1 & ~ch1_taghit)
		ch <= 4'd1;
	else if (cs2 & ~ch2_taghit)
		ch <= 4'd2;
	else if (cs3 & ~ch3_taghit)
		ch <= 4'd3;
	else if (cs4 & ~ch4_taghit)
		ch <= 4'd4;
	else if (cs5 & ~ch5_taghit)
		ch <= 4'd5;
	else if (cs6 & ~ch6_taghit)
		ch <= 4'd6;
	else if (cs7 & ~ch7_taghit)
		ch <= 4'd7;
	// Nothing selected
	else
		ch <= 4'hF;
end

endmodule
