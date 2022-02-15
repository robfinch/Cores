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

module mpmc8_addr_select(rst, clk, state, ch,
	we0, we1, we2, we3, we4, we5, we6, we7,
	adr0, adr1, adr2, adr3, adr4, adr5, adr6, adr7,
	adr);
input rst;
input clk;
input [3:0] state;
input [3:0] ch;
input we0;
input we1;
input we2;
input we3;
input we4;
input we5;
input we6;
input we7;
input [31:0] adr0;
input [31:0] adr1;
input [31:0] adr2;
input [31:0] adr3;
input [31:0] adr4;
input [31:0] adr5;
input [31:0] adr6;
input [31:0] adr7;
output reg [31:0] adr;

// Select the address input
reg [31:0] adrx;
always_ff @(posedge clk)
if (state==IDLE) begin
	case(ch)
	3'd0:	if (we0)
				adrx <= {adr0[AMSB:0]};
			else
				adrx <= {adr0[AMSB:7],7'h0};
	3'd1:	if (we1)
				adrx <= {adr1[AMSB:4],4'h0};
			else
				adrx <= {adr1[AMSB:5],5'h0};
	3'd2:	adrx <= {adr2[AMSB:4],4'h0};
	3'd3:	adrx <= {adr3[AMSB:4],4'h0};
	3'd4:	adrx <= {adr4[AMSB:4],4'h0};
	3'd5:	adrx <= {adr5[AMSB:6],6'h0};
	3'd6:	adrx <= {adr6[AMSB:4],4'h0};
	3'd7:
		if (we7) 
			adrx <= {adr7[AMSB:0]};
		else
			adrx <= {adr7[AMSB:4],4'h0};
	default:	adrx <= 29'h1FFFFFF0;
	endcase
end
always_ff @(posedge clk)
if (rst)
	adr <= 32'h1FFFFFF0;
else if (state==PRESET1)
	adr <= adrx;

endmodule
