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

module mpmc8_ack_gen(rst, clk, state, ch, cs, adr, cr, wr, to, taghit, 
	resv_ch, resv_adr, ack);
parameter N = 0;
input rst;
input clk;
input [3:0] state;
input [3:0] ch;
input cs;
input [31:0] adr;
input cr;
input wr;
input to;
input taghit;
input [3:0] resv_ch [0:NAR-1];
input [31:0] resv_adr [0:NAR-1];
output reg ack;

integer n;

// Setting ack output
// Ack takes place outside of a state so that reads from different read caches
// may occur at the same time.
always_ff @(posedge clk)
if (rst)
	ack <= FALSE;
else begin
	// Reads: the ack doesn't happen until the data's been cached. If there is
	// cached data we give an ack right away.
	if (taghit)
		ack <= TRUE;

	if (state==IDLE) begin
    if (cr) begin
      ack <= TRUE;
    	for (n = 0; n < NAR; n = n + 1)
      	if ((resv_ch[n]==N) && (resv_adr[n][31:4]==adr[31:4]))
        	ack <= FALSE;
    end
	end

	// Write: an ack can be sent back as soon as the write state is reached..
	if ((state==PRESET1 && wr) || to)
		if (ch==N)
			ack <= TRUE;

	// Clear the ack when the circuit is de-selected.
	if (!cs)
		ack <= FALSE;
end

endmodule
