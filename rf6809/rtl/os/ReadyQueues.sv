// ============================================================================
//        __
//   \\__/ o\    (C) 2020-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	ReadyQueues.sv
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
//                                                                          
// ============================================================================

module ReadyQueues(rst_i, clk_i, insert_i, pop_i, peek_i, tid_i, priority_i, tid_o);
parameter NQ = 5;
input rst_i;
input clk_i;
input insert_i;
input pop_i;
input peek_i;
input [11:0] tid_i;
input [2:0] priority_i;
output reg [11:0] tid_o;

reg [NQ-1:0] wrq, rdq;
wire [11:0] tid [0:NQ-1];
wire [11:0] data_count [0:NQ-1];
wire [NQ-1:0] empty;
wire [NQ-1:0] valid;
reg [4:0] q2check_ndx;
reg [2:0] q2check [0:31];
initial begin
	q2check[0] = 3'd0;
	q2check[1] = 3'd0;
	q2check[2] = 3'd0;
	q2check[3] = 3'd0;
	q2check[4] = 3'd0;
	q2check[5] = 3'd1;
	q2check[6] = 3'd0;
	q2check[7] = 3'd0;
	q2check[8] = 3'd1;
	q2check[9] = 3'd0;
	q2check[10] = 3'd0;
	q2check[11] = 3'd2;
	q2check[12] = 3'd0;
	q2check[13] = 3'd0;
	q2check[14] = 3'd0;
	q2check[15] = 3'd4;
	q2check[16] = 3'd0;
	q2check[17] = 3'd3;
	q2check[18] = 3'd0;
	q2check[19] = 3'd0;
	q2check[20] = 3'd1;
	q2check[21] = 3'd0;
	q2check[22] = 3'd0;
	q2check[23] = 3'd4;
	q2check[24] = 3'd0;
	q2check[25] = 3'd0;
	q2check[26] = 3'd1;
	q2check[27] = 3'd0;
	q2check[28] = 3'd0;
	q2check[29] = 3'd0;
	q2check[30] = 3'd0;
	q2check[31] = 3'd0;
end
	
integer n;
genvar g;
generate begin : ques
for (g = 0; g < NQ; g = g + 1)
//  vtdl #(8,64) uq1 (clk_i, wrq[g], qndx[g], tid_i, tid[g]);
// Fifo:
// common clock, 4096 entries, fall through 12 bits wide
ReadyFifo uqx (
  .clk(clk_i),                // input wire clk
  .srst(rst_i),              // input wire srst
  .din(tid_i),                // input wire [7 : 0] din
  .wr_en(wrq[g]),            // input wire wr_en
  .rd_en(rdq[g]),            // input wire rd_en
  .dout(tid[g]),              // output wire [7 : 0] dout
  .full(),              // output wire full
  .empty(empty[g]),            // output wire empty
  .valid(valid[g])            // output wire valid
//  .data_count(data_count[g])  // output wire [5 : 0] data_count
);
end
endgenerate

reg [2:0] qndx;
always_comb
	qndx = q2check[q2check_ndx];
	
always_ff @(posedge clk_i)
if (rst_i)
	q2check_ndx <= 'd0;
else begin
	for (n = 0; n < NQ; n = n + 1) 
		rdq[n] <= 1'b0;
	for (n = 0; n < NQ; n = n + 1) 
		wrq[n] <= 1'b0;
	if (pop_i) begin
	  rdq[qndx] <= 1'b1;
		tid_o <= empty[qndx]||!valid[qndx] ? 12'd0 : tid[qndx];
		q2check_ndx <= q2check_ndx + 2'd1;
		if (q2check_ndx==NQ-1)
			q2check_ndx <= 'd0;
	end
	else if (insert_i)
		wrq[priority_i] <= 1'b1;
  else if (peek_i)
		tid_o <= empty[qndx]||!valid[qndx] ? 12'd0 : tid[qndx];
end

endmodule
