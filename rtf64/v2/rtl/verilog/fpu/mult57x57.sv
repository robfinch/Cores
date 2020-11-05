// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	mult57x57.sv
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

module mult57x57(clk, ce, a, b, o);
input clk;
input ce;
input [56:0] a;
input [56:0] b;
output reg [113:0] o;

reg [56:0] p00, p01, p02;
reg p10, p11;

always @(posedge clk)
if (ce) begin
end

endmodule
reg [29:0] p00,p01,p02,p03;
reg [29:0] p10,p11,p12,p13;
reg [29:0] p20,p21,p22,p23;
reg [29:0] p30,p31,p32,p33;
	always @(posedge clk)
	if (ce) begin
	  p00 <= a[14: 0] * b[14: 0];
	  p01 <= a[29:15] * b[14: 0];
	  p02 <= a[43:30] * b[14: 0];
	  p03 <= a[56:44] * b[14: 0];
	  
	  p10 <= a[14: 0] * b[29:15];
	  p11 <= a[29:15] * b[29:15];
	  p12 <= a[43:30] * b[29:15];
	  p13 <= a[56:44] * b[29:15];

	  p20 <= a[14: 0] * b[43:30];
	  p21 <= a[29:15] * b[43:30];
	  p22 <= a[43:30] * b[43:30];
	  p23 <= a[56:44] * b[43:30];
	  
	  p20 <= a[14: 0] * b[43:30];
	  p21 <= a[29:15] * b[43:30];
	  p22 <= a[43:30] * b[43:30];
	  p23 <= a[56:44] * b[43:30];
	  
		p00 <= fracta[17: 0] * fractb[17: 0];
		p01 <= fracta[35:18] * fractb[17: 0];
		p02 <= fracta[52:36] * fractb[17: 0];
		p10 <= fracta[17: 0] * fractb[35:18];
		p11 <= fracta[35:18] * fractb[35:18];
		p12 <= fracta[52:36] * fractb[35:18];
		p20 <= fracta[17: 0] * fractb[52:36];
		p21 <= fracta[35:18] * fractb[52:36];
		p22 <= fracta[52:36] * fractb[52:36];
		fract1 <= 	                            {p02,36'b0} + {p01,18'b0} + p00 +
								  {p12,54'b0} + {p11,36'b0} + {p10,18'b0} +
					{p22,72'b0} + {p21,54'b0} + {p20,36'b0}
				;
	end
