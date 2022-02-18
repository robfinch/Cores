`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
import mpmc8_pkg::*;

module mpmc8_spr_read_cache(rst, wclk, spr_num, wr, wadr, wdat, inv,
	rclk, radr, rdat, hit
);
input rst;
input wclk;
input [4:0] spr_num;
input wr;
input [31:0] wadr;
input [127:0] wdat;
input inv;
input rclk;
input [31:0] radr;
output reg [127:0] rdat;
output reg hit;

(* ram_style="block" *)
reg [127:0] lines [0:511];
(* ram_style="block" *)
reg [27:0] tags [0:511];
(* ram_style="distributed" *)
reg [511:0] vbit;
reg [31:0] radrr;
reg [27:0] tago;
reg vbito;
wire [8:0] wadrs = {spr_num,wadr[7:4]};
wire [8:0] radrs = {spr_num,radrr[7:4]};

always_ff @(posedge rclk)
	radrr <= radr;
always_ff @(posedge wclk)
	if (wr) lines[wadrs] <= wdat;
always_ff @(posedge rclk)
	rdat <= lines[radrs];
always_ff @(posedge rclk)
	tago <= tags[radrs];
always_ff @(posedge rclk)
	vbito <= vbit[radrs];
always_ff @(posedge wclk)
	if (wr) tags[wadrs] <= wadr[31:4];
always_ff @(posedge wclk)
if (rst)
	vbit <= 'b0;
else begin
	if (wr)
		vbit[wadrs] <= 1'b1;
	else if (inv)
		vbit[wadrs] <= 1'b0;
end
always_comb
	hit = (tago==radrr[31:4]) && (vbito==1'b1);

endmodule
