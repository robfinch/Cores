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
parameter N=8;
parameter W=4;
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
reg [127:0] lines [0:255][0:W-1];
(* ram_style="distributed" *)
reg [27:0] tags [0:255][0:W-1];
(* ram_style="distributed" *)
reg [255:0] vbit [0:W-1];
reg [31:0] radrr [0:N-1];
reg [27:0] tago [0:N-1][0:W-1];
reg vbito [0:N-1][0:W-1];
reg [7:0] rclkw;
reg [31:0] radrw [0:N-1];
reg [127:0] rdatw [0:N-1];
reg hit [0:N-1][0:W-1];
reg [2:0] hitenc [0:N-1];
reg [N-1:0] hitw, hitx, hity;

always_comb
	rclkw[0] = rclk0;
always_comb
	rclkw[1] = rclk1;
always_comb
	rclkw[2] = rclk2;
always_comb
	rclkw[3] = rclk3;
always_comb
	rclkw[4] = rclk4;
always_comb
	rclkw[5] = rclk5;
always_comb
	rclkw[6] = rclk6;
always_comb
	rclkw[7] = rclk7;
always_comb
	radrw[0] = radr0;
always_comb
	radrw[1] = radr1;
always_comb
	radrw[2] = radr2;
always_comb
	radrw[3] = radr3;
always_comb
	radrw[4] = radr4;
always_comb
	radrw[5] = radr5;
always_comb
	radrw[6] = radr6;
always_comb
	radrw[7] = radr7;

always_comb
	rdat0 = rdatw[0];
always_comb
	rdat1 = rdatw[1];
always_comb
	rdat2 = rdatw[2];
always_comb
	rdat3 = rdatw[3];
always_comb
	rdat4 = rdatw[4];
always_comb
	rdat5 = rdatw[5];
always_comb
	rdat6 = rdatw[6];
always_comb
	rdat7 = rdatw[7];
	
always_comb
	hit0 = hity[0];
always_comb
	hit1 = hity[1];
always_comb
	hit2 = hity[2];
always_comb
	hit3 = hity[3];
always_comb
	hit4 = hity[4];
always_comb
	hit5 = hity[5];
always_comb
	hit6 = hity[6];
always_comb
	hit7 = hity[7];

reg [2:0] upw;

always_ff @(posedge wclk)
if (rst)
	upw <= 'd0;
else begin
	if (wr) begin
		if (upw==W-1)
			upw = 'd0;
		else
			upw <= upw + 2'd1;
	end
end

integer n;
genvar g3, g4;
generate begin : graddr
	for (g3 = 0; g3 < N; g3 = g3 + 1) begin
		always_ff @(posedge rclkw[g3])
			radrr[g3] <= radrw[g3];
		always_ff @(posedge rclkw[g3])
			rdatw[g3] <= lines[radrr[g3][11:4]][hitenc[g3]];
		for (g4 = 0; g4 < W; g4 = g4 + 1) begin
			always_ff @(posedge rclkw[g3])
				tago[g3][g4] <= tags[radrr[g3][11:4]][g4];
			always_ff @(posedge rclkw[g3])
				vbito[g3][g4] <= vbit[radrr[g3][11:4]][g4];
			always_ff @(posedge wclk)
				if (rst)
					vbit[g4] <= 256'b0;
				else begin
					if (wr)
						vbit[upw][wadr[13:4]] <= 1'b1;
					else if (inv)
						vbit[g4][wadr[13:4]] <= 1'b0;
				end
			always_comb
				hit[g3][g4] = tago[g3][g4]==radrr[g3] && vbito[g3][g4]==1'b1;
			always_comb
				hitenc[g3] = hit[g3][g4] ? g4[2:0] : 3'd0;
		end
		always_comb begin
			hitw[g3] = 1'b0;
			for (n = 0; n < W; n = n + 1)
				hitw[g3] = hitw[g3] | hit[g3][n];
		end
		always_ff @(posedge rclkw[g3]) begin
			hitx[g3] <= hitw[g3];
			hity[g3] <= hitx[g3];
		end
	end
	always_ff @(posedge wclk)
		if (wr) lines[wadr[11:4]][upw] <= wdat;
	always_ff @(posedge wclk)
		if (wr) tags[wadr[11:4]][upw] <= wadr[31:4];
end
endgenerate

endmodule
