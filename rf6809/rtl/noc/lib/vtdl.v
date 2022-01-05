// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	vtdl - variable tap delay line
//		(dynamic shift register)
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
//    Notes:
//
//	This module acts like a clocked delay line with a variable tap.
//	Miscellaneous usage in rate control circuitry such as fifo's.
//	Capable of delaying a signal bus.
//	Signal bus width is specified with the WID parameter.
//
//   	Verilog 1995
// =============================================================================
//
module vtdl(clk, ce, a, d, q);
parameter WID = 8;
parameter DEP = 16;
localparam AMSB = DEP>64?6:DEP>32?5:DEP>16?4:DEP>8?3:DEP>4?2:DEP>2?1:0;
input clk;
input ce;
input [AMSB:0] a;
input [WID-1:0] d;
output [WID-1:0] q;

reg [WID-1:0] m [DEP-1:0];
integer n;

always @(posedge clk)
	if (ce) begin
		for (n = 1; n < DEP; n = n + 1)
			m[n] <= m[n-1];
		m[0] <= d;
	end

assign q = m[a];

endmodule

module vtdlx1(clk, ce, a, d, q);
parameter DEP = 16;
localparam AMSB = DEP>64?6:DEP>32?5:DEP>16?4:DEP>8?3:DEP>4?2:DEP>2?1:0;
input clk;
input ce;
input [AMSB:0] a;
input d;
output q;

reg [DEP-1:0] m;
integer n;

always @(posedge clk)
	if (ce) begin
		for (n = 1; n < DEP; n = n + 1)
			m[n] <= m[n-1];
		m[0] <= d;
	end

assign q = m[a];

endmodule
