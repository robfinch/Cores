// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
//	ParallelToSerial.v
//		Parallel to serial data converter (shift register).
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
module ParallelToSerial(rst, clk, mcm, ce, ld, a, qin, d, qh);
localparam WID=64;
input rst;			// reset
input clk;			// clock
input mcm;
input ce;			// clock enable
input ld;			// load
input [2:0] a;  // bits 3-5 of the font width
input qin;			// serial shifting input
input [WID-1:0] d;	// data to load
output reg [1:0] qh;	// serial output

reg [WID-1:0] q;

always @(posedge clk)
	if (rst)
		q <= {WID{1'b0}};
	else if (ce) begin
		if (ld)
			q <= d;
		else if (mcm)
		  q <= {q[WID-3:0],2'b0};
		else
		  q <= {q[WID-2:0],qin};
	end

always @(posedge clk)
  if (ce)
    casez(a)
    3'b1??: qh <= q[63:62];
//    3'b110: qh <= q[55];
//    3'b101: qh <= q[47];
//    3'b100: qh <= q[39];
    3'b01?: qh <= q[31:30];
//    3'b010: qh <= q[23];
    3'b001: qh <= q[15:14];
    3'b000: qh <= q[ 7:6];
    endcase

endmodule
