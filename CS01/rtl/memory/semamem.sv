// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	semamem.sv
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
// Address
// 0b0nnnnnnaaaa		read: decrement by aaaaaa, write increment by aaaaaa
// 0b1nnnnnn----	  read: peek value, write absolute data
// ============================================================================

module semamem(clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o);
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output reg ack_o;
input we_i;
input [12:0] adr_i;
input [7:0] dat_i;
output reg [7:0] dat_o;

wire cs = cs_i & cyc_i & stb_i;
always_ff @(posedge clk_i)
  ack_o <= cs;

reg [7:0] mem [0:255];
reg [7:0] memi;
reg [7:0] memo;
reg [8:0] memopi,memomi;
always_comb
	memo <= mem[adr_i[11:4]];
always_comb
	memopi <= memo + adr_i[3:0];
always_comb
	memomi <= memo - adr_i[3:0];
assign o = memo;

wire pe_cs;
edge_det ued1 (.clk(clk_i), .ce(1'b1), .i(cs), .pe(pe_cs), .ne(), .ee());

always_ff @(posedge clk_i)
if (pe_cs)
	mem[adr_i[11:4]] <= memi;

always_comb
begin
	casez({adr_i,we_i})
	14'b0????????????0:	memi <= memomi[8] ? 8'h00 : memomi[7:0];
	14'b0????????????1:	memi <= memopi[8] ? 8'hFF : memopi[7:0];
	14'b1????????????0:	memi <= memo;
	14'b1????????????1:	memi <= dat_i;
	endcase
end

always_ff @(posedge clk_i)
  if (pe_cs)
    dat_o <= mem[adr_i[11:4]];

endmodule
