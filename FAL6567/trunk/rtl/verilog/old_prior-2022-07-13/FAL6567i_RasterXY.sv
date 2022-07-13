// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_RasterXY.sv
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
module FAL6567i_RasterXY(rst, clk8,
	rasterXMax, rasterYMax, preRasterX, rasterX,
	preRasterY, rasterY, nextRasterY
);
input rst;
input clk8;
input [10:0] rasterXMax;
input [8:0] rasterYMax;
output reg [10:0] preRasterX;
output reg [10:0] rasterX;
output reg [8:0] preRasterY;
output reg [8:0] rasterY;
output reg [8:0] nextRasterY;

always_ff @(posedge clk8)
if (rst) begin
	preRasterX <= 11'd0;
end
else begin
	if (preRasterX==rasterXMax)
		preRasterX <= 11'd0;
	else
		preRasterX <= preRasterX + 2'd1;
end

always_ff @(posedge clk8)
if (rst) begin
	rasterX <= 11'd0;
end
else begin
	if (preRasterX==11'h14)
		rasterX <= 11'h0;
	else
		rasterX <= rasterX + 2'd1;
end

always_ff @(posedge clk8)
if (rst) begin
	preRasterY <= 9'd0;
end
else begin
	if (preRasterX==rasterXMax) begin
		if (preRasterY==rasterYMax)
			preRasterY <= 9'd0;
		else
			preRasterY <= preRasterY + 2'd1;
	end  
end

always_ff @(posedge clk8)
if (rst) begin
	rasterY <= 9'd0;
end
else begin
	if (preRasterX==11'h14)
		rasterY <= preRasterY;
end

always_ff @(posedge clk8)
if (rst) begin
	nextRasterY <= 9'd0;
end
else begin
	if (rasterX==11'd0)
		nextRasterY <= rasterY + 2'd1;
end

endmodule
