// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rtf64-bitfield.sv
//    - bitfield operations
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

module bitfield(clk, ce, ir, d_i, d_ext, d_extu, d_flip, d_dep, d_depi, d_ffo, a, b, c, d, imm, o);
input clk;
input ce;
input [63:0] ir;
input d_i;
input d_ext;
input d_extu;
input d_flip;
input d_dep;
input d_depi;
input d_ffo;
input [63:0] a;
input [63:0] b;
input [63:0] c;
input [63:0] d;
input [63:0] imm;
output reg [63:0] o;

integer n;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #1
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [5:0] mb, mw;

always @(posedge clk)
  if (ce) mb <= d_i ? ir[23:18] : b[5:0];
always @(posedge clk)
  if (ce) mw <= d_i ? ir[29:24] : c[5:0];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #2
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [5:0] me;
reg [5:0] mb2;

always @(posedge clk)
  if (ce) mb2 <= mb;
always @(posedge clk)
  if (ce) me <= mb + mw;  

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #3
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [63:0] mask;
reg [5:0] me3;
reg [5:0] mb3;
wire [63:0] a3, b3, c3, d3, imm3;
integer nn;
always @(posedge clk)
  if (ce) mb3 <= mb2;
always @(posedge clk)
  if (ce) me3 <= me;
always @(posedge clk)
	for (nn = 0; nn < 64; nn = nn + 1)
		if (ce) mask[nn] <= (nn >= mb) ^ (nn <= me) ^ (me >= mb);

delay #(.WID(64), .DEP(3)) ud1 (.clk(clk), .ce(ce), .i(a), .o(a3));
delay #(.WID(64), .DEP(3)) ud2 (.clk(clk), .ce(ce), .i(b), .o(b3));
delay #(.WID(64), .DEP(3)) ud3 (.clk(clk), .ce(ce), .i(c), .o(c3));
delay #(.WID(64), .DEP(3)) ud4 (.clk(clk), .ce(ce), .i(d), .o(d3));
delay #(.WID(64), .DEP(3)) ud5 (.clk(clk), .ce(ce), .i(imm), .o(imm3));

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #4
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [63:0] mask4;
reg [63:0] a4, d4;
reg [5:0] mb4;
reg [63:0] bfo1;

always @(posedge clk)
  if (ce) mb4 <= mb3;
always @(posedge clk)
  if (ce) mask4 <= mask;
always @(posedge clk)
  if (ce) a4 <= a3;
always @(posedge clk)
  if (ce) d4 <= d3;

always @(posedge clk)
if (ce) begin
  if (d_dep) begin
  	bfo1 <= a3 << mb3;
  end
  else if (d_depi)
  	bfo1 <= imm3 << mb3;
  else if (d_flip) begin
    for (n = 0; n < 64; n = n + 1)
      bfo1[n] <= mask[n] ? a3[n]^d3[n] : d3[n];
  end
  else if (d_ext) begin
  	for (n = 0; n < 64; n = n + 1)
  		bfo1[n] <= mask[n] ? a3[n] : 1'b0;
  end
  else if (d_extu) begin
  	for (n = 0; n < 64; n = n + 1)
  		bfo1[n] <= mask[n] ? a3[n] : 1'b0;
  end
  else if (d_ffo) begin
  	for (n = 0; n < 64; n = n + 1)
  		bfo1[n] <= mask[n] ? a3[n] : 1'b0;
  end
  else
  	bfo1 <= {64{1'b0}};
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #5
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
reg [5:0] mb5;
reg [63:0] bfo2;

always @(posedge clk)
  if (ce) mb5 <= mb4;

always @(posedge clk)
if (ce) begin
  if (d_dep) begin
  	for (n = 0; n < 64; n = n + 1)
  	  bfo2[n] <= (mask4[n] ? bfo1[n] : d4[n]);
  end
  else if (d_depi) begin
  	for (n = 0; n < 64; n = n + 1)
  	  bfo2[n] <= (mask4[n] ? bfo1[n] : d4[n]);
  end
  else if (d_flip)
    bfo2 <= bfo1;
  else if (d_ext) begin
  	bfo2 <= bfo1 >> mb4;
  end
  else if (d_extu) begin
  	bfo2 <= bfo1 >> mb4;
  end
  else if (d_ffo) begin
    bfo2 <= {64{1'b1}};
    for (n = 0; n < 64; n = n + 1)
      if (bfo1[n]==1'b1)
        bfo2 <= n;
  end
  else
  	bfo2 <= {64{1'b0}};
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Clock #6
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
wire [5:0] mw5;
delay #(.WID(6), .DEP(4)) ud6 (.clk(clk), .ce(ce), .i(mw), .o(mw5));

always @(posedge clk)
if (d_dep)
  o <= bfo2;
else if (d_depi)
  o <= bfo2;
else if (d_flip)
  o <= bfo2;
else if (d_ext) begin
	for (n = 0; n < 64; n = n + 1)
		o[n] <= n > mw5 ? bfo2[mw5] : bfo2[n];
end
else if (d_extu)
	o <= bfo2;
else if (d_ffo)
	o <= bfo2[63] ? bfo2 : bfo2 - mb5;
else
	o <= {64{1'b0}};

endmodule
