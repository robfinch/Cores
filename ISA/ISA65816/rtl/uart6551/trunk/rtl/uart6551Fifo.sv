// ============================================================================
//        __
//   \\__/ o\    (C) 2003-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
module uart6551Fifo(clk, rst, wr, rd, din, dout, ctr, full, empty);
parameter WID=8;
parameter DEP=16;
localparam pCtrBits = $clog2(DEP)-1;
input clk;
input rst;
input wr;
input rd;
input [WID-1:0] din;
output [WID-1:0] dout;
output [pCtrBits:0] ctr;
reg [pCtrBits:0] ctr;
output full;
output empty;

assign full = ctr=={pCtrBits{1'b1}}-1;
assign empty = ctr=={pCtrBits{1'b1}};
wire rdok = rd & ~empty;
wire wrok = wr & ~full;

vtdl #(WID,DEP) u1 (.clk(clk), .ce(1'b1), .a(ctr), .d(din), .q(dout));

always_ff @(posedge clk)
if (rst)
	ctr <= {pCtrBits{1'b1}};
else
	ctr <= ctr + {rdok&~wrok,rdok&~wrok,rdok&~wrok,rdok^wrok};

endmodule
