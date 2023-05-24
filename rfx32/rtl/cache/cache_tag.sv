// ============================================================================
//        __
//   \\__/ o\    (C) 2021-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	cache_tag.sv
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
// 352 LUTs / 4096 FFs                                                                          
// ============================================================================

import rfx32pkg::*;
import rfx32_cache_pkg::*;

module rfx32_cache_tag(rst, clk, wr, vadr_i, padr_i, way, rclk, ndx, tag,
	sndx, ptag0, ptag1, ptag2, ptag3);
parameter LINES=64;
parameter WAYS=4;
parameter LOBIT=6;
parameter HIBIT=$clog2(LINES)-1+LOBIT;
parameter TAGBIT=HIBIT+2;	// +1 more for odd/even lines
input rst;
input clk;
input wr;
input rfx32pkg::address_t vadr_i;
input rfx32pkg::address_t padr_i;
input [1:0] way;
input rclk;
input [$clog2(LINES)-1:0] ndx;
output cache_tag_t [WAYS-1:0] tag;
input [$clog2(LINES)-1:0] sndx;
output cache_tag_t ptag0;
output cache_tag_t ptag1;
output cache_tag_t ptag2;
output cache_tag_t ptag3;

(* ram_style="distributed" *)
cache_tag_t ptags0 [0:LINES-1];	// physical tags
(* ram_style="distributed" *)
cache_tag_t ptags1 [0:LINES-1];
(* ram_style="distributed" *)
cache_tag_t ptags2 [0:LINES-1];
(* ram_style="distributed" *)
cache_tag_t ptags3 [0:LINES-1];

//typedef logic [$bits(code_address_t)-1:TAGBIT] tag_t;

(* ram_style="distributed" *)
cache_tag_t vtags0 [0:LINES-1];	// virtual tags
(* ram_style="distributed" *)
cache_tag_t vtags1 [0:LINES-1];
(* ram_style="distributed" *)
cache_tag_t vtags2 [0:LINES-1];
(* ram_style="distributed" *)
cache_tag_t vtags3 [0:LINES-1];

integer g,g1;
integer n,n1;

always_ff @(posedge clk)
// Careful reset of tags. Must be done via the same addressing as is used while
// active. The processor must output an incrementing address during reset to 
// reset the tags.
// Resetting all the tags will force implementation with FF's. Since tag values
// do not matter to synthesis it is simply omitted.
if (rst) begin
	vtags0[vadr_i[HIBIT:LOBIT]] <= 'd1;
	vtags1[vadr_i[HIBIT:LOBIT]] <= 'd1;
	vtags2[vadr_i[HIBIT:LOBIT]] <= 'd1;
	vtags3[vadr_i[HIBIT:LOBIT]] <= 'd1;
end
else
begin
	if (wr && way==2'd0) vtags0[vadr_i[HIBIT:LOBIT]] <= {vadr_i[$bits(rfx32pkg::address_t)-1:TAGBIT]};
	if (wr && way==2'd1) vtags1[vadr_i[HIBIT:LOBIT]] <= {vadr_i[$bits(rfx32pkg::address_t)-1:TAGBIT]};
	if (wr && way==2'd2) vtags2[vadr_i[HIBIT:LOBIT]] <= {vadr_i[$bits(rfx32pkg::address_t)-1:TAGBIT]};
	if (wr && way==2'd3) vtags3[vadr_i[HIBIT:LOBIT]] <= {vadr_i[$bits(rfx32pkg::address_t)-1:TAGBIT]};
end

always_ff @(posedge clk)
if (rst) begin
	ptags0[vadr_i[HIBIT:LOBIT]] <= 'd1;
	ptags1[vadr_i[HIBIT:LOBIT]] <= 'd1;
	ptags2[vadr_i[HIBIT:LOBIT]] <= 'd1;
	ptags3[vadr_i[HIBIT:LOBIT]] <= 'd1;
end
else
begin
	if (wr && way==2'd0) ptags0[vadr_i[HIBIT:LOBIT]] <= {padr_i[$bits(rfx32pkg::address_t)-1:TAGBIT]};
	if (wr && way==2'd1) ptags1[vadr_i[HIBIT:LOBIT]] <= {padr_i[$bits(rfx32pkg::address_t)-1:TAGBIT]};
	if (wr && way==2'd2) ptags2[vadr_i[HIBIT:LOBIT]] <= {padr_i[$bits(rfx32pkg::address_t)-1:TAGBIT]};
	if (wr && way==2'd3) ptags3[vadr_i[HIBIT:LOBIT]] <= {padr_i[$bits(rfx32pkg::address_t)-1:TAGBIT]};
end

assign tag[0] = vtags0[ndx];
assign tag[1] = vtags1[ndx];
assign tag[2] = vtags2[ndx];
assign tag[3] = vtags3[ndx];

assign ptag0 = ptags0[sndx];
assign ptag1 = ptags1[sndx];
assign ptag2 = ptags2[sndx];
assign ptag3 = ptags3[sndx];

endmodule
