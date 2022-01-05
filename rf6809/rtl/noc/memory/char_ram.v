// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2021  Robert Finch, Waterloo
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
module char_ram(clk_i, cs_i, we_i, adr_i, dat_i, dat_o, dot_clk_i, ce_i, char_code_i, maxscanline_i, scanline_i, bmp_o);
input clk_i;
input cs_i;
input we_i;
input [12:0] adr_i;
input [8:0] dat_i;
output reg [8:0] dat_o;
input dot_clk_i;
input ce_i;
input [8:0] char_code_i;
input [4:0] maxscanline_i;
input [4:0] scanline_i;
output reg [8:0] bmp_o;

(* ram_style="block" *)
reg [8:0] mem [0:8191];
reg [12:0] radr;
reg [12:0] rcc;
reg [8:0] dat1;
reg [8:0] bmp;

initial begin
`include "d:\\cores2022\\rf6809\\rtl\\noc\\memory\\char_bitmaps.v";
end

always @(posedge clk_i)
	if (cs_i & we_i)
		mem[adr_i] <= dat_i;
always @(posedge clk_i)
	radr <= adr_i;
always @(posedge clk_i)
	dat1 <= mem[radr];
always @(posedge clk_i)
	dat_o <= dat1;

always @(posedge dot_clk_i)
	if (ce_i)
		rcc <= char_code_i*maxscanline_i+scanline_i;
always @(posedge dot_clk_i)
	bmp <= mem[rcc];
always @(posedge dot_clk_i)
	bmp_o <= bmp;

endmodule
