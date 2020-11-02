// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	intToPosit.sv
//    - integer to posit number converter
//    - parameterized width
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

import posit::*;

module intToPosit(i, o);
localparam lzs = $clog2(PSTWID-1)-1;
input [PSTWID-1:0] i;
output [PSTWID-1:0] o;

wire [PSTWID*2-1+es+3-2:0] tmp, tmp1;
wire [PSTWID-2:0] ii = i[PSTWID-1] ? -i : i;

wire [lzs:0] lzcnt;
wire [PSTWID-1:0] rnd_ulp, tmp2, tmp2_rnd_ulp;

integer n;
positCntlz #(.PSTWID(PSTWID)) u1 (.i(ii[PSTWID-2:0]), .o(lzcnt));

wire sgn = i[PSTWID-1];
wire [rs:0] rgm = (PSTWID - (lzcnt + 2)) >> es;
wire [PSTWID-3:0] sig = ii << lzcnt;  // left align significand, chop off leading one
generate begin : gExpandedPosit
  // The number is represented as 1.x so for an integer it
  // always needs to be left shifted.
  // Add three trailers for guard, round and sticky.
  if (es > 0) begin
    // exp = lzcnt mod (2**es)
    // remember es is constant so there are no shifts really
    wire [es-1:0] exp = (PSTWID - (lzcnt + 2)) & {es{1'b1}};
    assign tmp = {{{PSTWID-1{1'b1}},1'b0},exp,sig,3'b0};
  end
  else
    assign tmp = {{{PSTWID-1{1'b1}},1'b0},sig,3'b0};
end
endgenerate
// Compute regime shift amount = number of bits to represent regime
// Need one extra bit for the terminator, and one extra '1' bit.
wire [rs:0] rgm_sh = rgm + 2'd2;
assign tmp1 = tmp >> rgm_sh;
wire L = tmp[rgm_sh-0+es];
wire G = tmp[rgm_sh-1+es];
wire R = tmp[rgm_sh-2+es];
reg S;
wire ulp;
always @*
begin
  S = 0;
  for (n = 0; n < PSTWID; n = n + 1) begin
    if (n < rgm_sh - 2 + es)
      S = S | tmp[n];
  end
end

// Extract the bits representing the number, note leave off sign bit
assign tmp2 = tmp1[PSTWID-3+es+3:es+2];
// Round
assign ulp = ((G & (R | S)) | (L & G & ~(R | S)));
assign rnd_ulp = {{PSTWID-1{1'b0}},ulp};
assign tmp2_rnd_ulp = tmp2 + rnd_ulp;
// Final output
assign o = i=={PSTWID{1'b0}} ? {PSTWID{1'b0}} : sgn ? -tmp2_rnd_ulp : tmp2_rnd_ulp;

endmodule
