`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	BCDSub8NClk.sv
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
// The following added breaks up the carry chain.
//
// The adder is organized into three rows and N*2 columns of digits. The first
// row is set to the input a, b operands. The carry for the first row and column
// is set to the carry input. The operands in a row are added without taking
// carry into consideration. But the carry out is recorded and added as the 'B'
// operand in the next row. The sum from one row is fed as the 'A' operand into
// the next row. Values (sum and carry) are moved between rows in a clocked
// fashion. The first row contains full BCD adders. After that only a single
// bit is added.
//
// There cannot be more than three rows required. The worst case scenario occurs
// when all the inputs are at a max and there is a carry input. This generates a
// carry output from each digit in the second row.
//
// In that case
//   99999999
// + 99999999
// +        1 (carry in)
//---------------
//  188888889		<- first row result
// + 11111110		<- carries out of first row
//---------------
//  199999999   <- second row result

module BCDSub8NClk(clk, ld, a, b, o, ci, co, done);
parameter N=33;
input clk;
input ld;
input [N*8-1:0] a;
input [N*8-1:0] b;
output reg [N*8-1:0] o;
input ci;
output reg co;
output reg done;

reg [N-1:0] c [0:2];
wire [N*8-1:0] o1 [0:2];
reg [N*8-1:0] o2 [0:2];
wire [N:0] d [0:2];

genvar g,k;
generate begin : gBCDadd
for (g = 0; g < N; g = g + 1) begin
	for (k = 0; k < 3; k = k + 1) begin
		BCDSub u1 (
			.ci(k==0 && g==0 ? ci : 1'b0),
			.a(k==0 ? a[g*8+7:g*8] : o2[k-1][g*8+7:g*8]),
			.b(k==0 ? b[g*8+7:g*8] : {7'h00,c[k-1][g]}),
			.o(o1[k][g*8+7:g*8]),
			.c(d[k][g])
		);
		always_ff @(posedge clk)
			o2[k] <= o1[k];
		always_ff @(posedge clk)
			c[k][g] <= d[k][g];
	end
end
always_ff @(posedge clk)
begin
	o <= o1[2];
	co <= c[2][N-1];
end
end
endgenerate
endmodule

