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

module mpmc8_read_cache(rst, wclk, wr, wadr, wdat, inv,
	rclk0, radr0, rdat0, hit0,
	rclk1, radr1, rdat1, hit1,
	rclk2, radr2, rdat2, hit2,
	rclk3, radr3, rdat3, hit3,
	rclk4, radr4, rdat4, hit4,
	rclk5, radr5, rdat5, hit5,
	rclk6, radr6, rdat6, hit6,
	rclk7, radr7, rdat7, hit7
);
input rst;
input wclk;
input wr;
input [31:0] wadr;
input [127:0] wdat;
input inv;
input rclk0;
input [31:0] radr0;
output reg [127:0] rdat0;
output reg hit0;
input rclk1;
input [31:0] radr1;
output reg [127:0] rdat1;
output reg hit1;
input rclk2;
input [31:0] radr2;
output reg [127:0] rdat2;
output reg hit2;
input rclk3;
input [31:0] radr3;
output reg [127:0] rdat3;
output reg hit3;
input rclk4;
input [31:0] radr4;
output reg [127:0] rdat4;
output reg hit4;
input rclk5;
input [31:0] radr5;
output reg [127:0] rdat5;
output reg hit5;
input rclk6;
input [31:0] radr6;
output reg [127:0] rdat6;
output reg hit6;
input rclk7;
input [31:0] radr7;
output reg [127:0] rdat7;
output reg hit7;

(* ram_style="block" *)
reg [127:0] lines [0:1023];
(* ram_style="block" *)
reg [27:0] tags [0:1023];
(* ram_style="distributed" *)
reg [1023:0] vbit;
reg [31:0] radrr0;
reg [31:0] radrr1;
reg [31:0] radrr2;
reg [31:0] radrr3;
reg [31:0] radrr4;
reg [31:0] radrr5;
reg [31:0] radrr6;
reg [31:0] radrr7;
reg [27:0] tago0;
reg [27:0] tago1;
reg [27:0] tago2;
reg [27:0] tago3;
reg [27:0] tago4;
reg [27:0] tago5;
reg [27:0] tago6;
reg [27:0] tago7;
reg vbito0;
reg vbito1;
reg vbito2;
reg vbito3;
reg vbito4;
reg vbito5;
reg vbito6;
reg vbito7;

always_ff @(posedge rclk0)
	radrr0 <= radr0;
always_ff @(posedge rclk1)
	radrr1 <= radr1;
always_ff @(posedge rclk2)
	radrr2 <= radr2;
always_ff @(posedge rclk3)
	radrr3 <= radr3;
always_ff @(posedge rclk4)
	radrr4 <= radr4;
always_ff @(posedge rclk5)
	radrr5 <= radr5;
always_ff @(posedge rclk6)
	radrr6 <= radr6;
always_ff @(posedge rclk7)
	radrr7 <= radr7;
always_ff @(posedge wclk)
	if (wr) lines[wadr[13:4]] <= wdat;
always_ff @(posedge rclk0)
	rdat0 <= lines[radrr0[13:4]];
always_ff @(posedge rclk1)
	rdat1 <= lines[radrr1[13:4]];
always_ff @(posedge rclk2)
	rdat2 <= lines[radrr2[13:4]];
always_ff @(posedge rclk3)
	rdat3 <= lines[radrr3[13:4]];
always_ff @(posedge rclk4)
	rdat4 <= lines[radrr4[13:4]];
always_ff @(posedge rclk5)
	rdat5 <= lines[radrr5[13:4]];
always_ff @(posedge rclk6)
	rdat6 <= lines[radrr6[13:4]];
always_ff @(posedge rclk7)
	rdat7 <= lines[radrr7[13:4]];
always_ff @(posedge rclk0)
	tago0 <= tags[radrr0[13:4]];
always_ff @(posedge rclk1)
	tago1 <= tags[radrr1[13:4]];
always_ff @(posedge rclk2)
	tago2 <= tags[radrr2[13:4]];
always_ff @(posedge rclk3)
	tago3 <= tags[radrr3[13:4]];
always_ff @(posedge rclk4)
	tago4 <= tags[radrr4[13:4]];
always_ff @(posedge rclk5)
	tago5 <= tags[radrr5[13:4]];
always_ff @(posedge rclk6)
	tago6 <= tags[radrr6[13:4]];
always_ff @(posedge rclk7)
	tago7 <= tags[radrr7[13:4]];
always_ff @(posedge rclk0)
	vbito0 <= vbit[radrr0[13:4]];
always_ff @(posedge rclk1)
	vbito1 <= vbit[radrr1[13:4]];
always_ff @(posedge rclk2)
	vbito2 <= vbit[radrr2[13:4]];
always_ff @(posedge rclk3)
	vbito3 <= vbit[radrr3[13:4]];
always_ff @(posedge rclk4)
	vbito4 <= vbit[radrr4[13:4]];
always_ff @(posedge rclk5)
	vbito5 <= vbit[radrr5[13:4]];
always_ff @(posedge rclk6)
	vbito6 <= vbit[radrr6[13:4]];
always_ff @(posedge rclk7)
	vbito7 <= vbit[radrr7[13:4]];
always_ff @(posedge wclk)
	if (wr) tags[wadr[13:4]] <= wadr[31:4];
always_ff @(posedge wclk)
if (rst)
	vbit <= 256'b0;
else begin
	if (wr)
		vbit[wadr[13:4]] <= 1'b1;
	else if (inv)
		vbit[wadr[13:4]] <= 1'b0;
end
always_comb
	hit0 = (tago0==radrr0[31:4]) && (vbito0==1'b1);
always_comb
	hit1 = (tago1==radrr1[31:4]) && (vbito1==1'b1);
always_comb
	hit2 = (tago2==radrr2[31:4]) && (vbito2==1'b1);
always_comb
	hit3 = (tago3==radrr3[31:4]) && (vbito3==1'b1);
always_comb
	hit4 = (tago4==radrr4[31:4]) && (vbito4==1'b1);
always_comb
	hit5 = (tago5==radrr5[31:4]) && (vbito5==1'b1);
always_comb
	hit6 = (tago6==radrr6[31:4]) && (vbito6==1'b1);
always_comb
	hit7 = (tago7==radrr7[31:4]) && (vbito7==1'b1);

endmodule
