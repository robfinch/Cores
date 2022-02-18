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

module mpmc8_mask_select(rst, clk, state, ch,
	wmask0, wmask1, wmask2, wmask3, wmask4, wmask5, wmask6, wmask7, 
	mask, mask2
);
input rst;
input clk;
input [3:0] state;
input [3:0] ch;
input [15:0] wmask0;
input [15:0] wmask1;
input [15:0] wmask2;
input [15:0] wmask3;
input [15:0] wmask4;
input [15:0] wmask5;
input [15:0] wmask6;
input [15:0] wmask7;
output reg [15:0] mask;
output reg [15:0] mask2;

// Setting the data mask. Values are enabled when the data mask is zero.
always_ff @(posedge clk)
if (rst)
  mask2 <= 16'h0000;
else begin
	if (state==PRESET1)
		case(ch)
		4'd0:	mask2 <= wmask0;
		4'd1:	mask2 <= wmask1;
		4'd2:	mask2 <= wmask2;
		4'd3:	mask2 <= wmask3;
		4'd4:	mask2 <= wmask4;
		4'd5:	mask2 <= wmask5;
		4'd6:	mask2 <= wmask6;
		4'd7:	mask2 <= wmask7;
		default:	mask2 <= 16'h0000;
		endcase
	// For RMW cycle all bytes are writtten.
	else if (state==WRITE_TRAMP1)
		mask2 <= 16'h0000;
end
always_ff @(posedge clk)
if (rst)
  mask <= 16'h0000;
else begin
	if (state==PRESET2)
		mask <= mask2;
end

endmodule
