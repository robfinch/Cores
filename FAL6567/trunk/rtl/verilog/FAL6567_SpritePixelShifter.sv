// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_SpritePixelShifter.sv
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
import FAL6567_pkg::*;

module FAL6567_SpritePixelShifter(rst, clk, dotclk_en, phi02, enaData, 
	sprite1, vicCycle, MActive, MShift, mClkShift, mmc, db, sprite, MCurrentPixel);
input rst;
input clk;
input dotclk_en;
input phi02;
input enaData;
input [8:0] sprite1;
input [2:0] vicCycle;
input [MIBCNT-1:0] MActive;
input [MIBCNT-1:0] MShift;
input [MIBCNT-1:0] mClkShift;
input [MIBCNT-1:0] mmc;
input [7:0] db;
input [3:0] sprite;
output reg [1:0] MCurrentPixel [MIBCNT-1:0];

reg [23:0] MPixels [MIBCNT-1:0];

integer n11;
always_ff @(posedge clk)
if (rst) begin
	for (n11 = 0; n11 < MIBCNT; n11 = n11 + 1)
		MPixels[n11] <= 24'h0;
end
else begin
	if (dotclk_en) begin
		for (n11 = 0; n11 < MIBCNT; n11 = n11 + 1) begin
			if (MShift[n11]) begin
				if (mClkShift[n11]) begin
					if (mmc[n11])
						MPixels[n11] <= {MPixels[n11][21:0],2'b0};
					else
						MPixels[n11] <= {MPixels[n11][22:0],1'b0};
				end
			end
		end  
	end
	if (sprite1[4]) begin
		if (vicCycle==VIC_SPRITE && phi02 && enaData) begin
			if (MActive[sprite])
				MPixels[sprite] <= {MPixels[sprite][15:0],db[7:0]};
		end 
	end
	else begin
		if (vicCycle==VIC_SPRITE && enaData) begin
			if (MActive[sprite])
				MPixels[sprite] <= {MPixels[sprite][15:0],db[7:0]};
		end
	end
end

// Adds a pipeline delay of one to the sprite pixel
integer n12;
always_ff @(posedge clk)
if (rst) begin
	for (n12 = 0; n12 < MIBCNT; n12 = n12 + 1)
		MCurrentPixel[n12] <= 2'b00;
end
else begin
	if (dotclk_en)
		for (n12 = 0; n12 < MIBCNT; n12 = n12 + 1) begin
			if (MShift[n12])
				MCurrentPixel[n12] <= MPixels[n12][23:22];
			else
				MCurrentPixel[n12] <= 2'b00;
		end
end

endmodule
