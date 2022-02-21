// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPDecompose.sv
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

module DFPDecompose(i, sgn, sx, exp, sig, xz, vz, inf, nan);
parameter N=33;
input [(N*4)+16+4-1:0] i;
output sgn;
output sx;
output [15:0] exp;
output [N*4-1:0] sig;
output xz;
output vz;
output inf;
output nan;

assign nan = i[N*4+19];
assign sgn = i[N*4+18];
assign inf = i[N*4+17];
assign sx = i[N*4+16];
assign exp = i[N*4+15:N*4];
assign sig = i[N*4-1:0];
assign xz = ~|exp;
assign vz = ~|{exp,sig};

endmodule


module DFPDecomposeReg(clk, ce, i, sgn, sx, exp, sig, xz, vz, inf, nan);
parameter N=33;
input clk;
input ce;
input [N*4+16+4-1:0] i;
output reg sgn;
output reg sx;
output reg [15:0] exp;
output reg [N*4-1:0] sig;
output reg xz;
output reg vz;
output reg inf;
output reg nan;

always @(posedge clk)
	if (ce) begin
		nan <= i[N*4+19];
		sgn <= i[N*4+18];
		inf <= i[N*4+17];
		sx <= i[N*4+16];
		exp <= i[N*4+15:N*4];
		sig <= i[N*4-1:0];
		xz <= ~|exp;
		vz <= ~|{exp,sig};
	end

endmodule
