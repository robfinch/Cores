// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_ColorSelect.sv
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
module FAL6567_ColorSelect(clk, dotclk_en, rasterX, rasterY, ecm, bmm, mcm, pixelColor, mdp, mmc,
	pixelBgFlag, MCurrentPixel, mm0, mm1, mc, ec, ec1, vicBlank, vicBorder, color);
parameter MIBCNT = 16;
input clk;
input dotclk_en;
input [10:0] rasterX;
input [8:0] rasterY;
input ecm;
input bmm;
input mcm;
input [3:0] pixelColor;
input [MIBCNT-1:0] mdp;
input [MIBCNT-1:0] mmc;
input pixelBgFlag;
input [1:0] MCurrentPixel [MIBCNT-1:0];
input [3:0] mm0;
input [3:0] mm1;
input [3:0] mc [MIBCNT-1:0];
input [3:0] ec;
input [3:0] ec1;
input vicBlank;
input vicBorder;
output reg [3:0] color;

reg [3:0] color_code;
integer n13;
always_ff @(posedge clk)
if (dotclk_en) begin
	// Force the output color to black for "illegal" modes
	case({ecm,bmm,mcm})
	3'b101,3'b110,3'b111:
		color_code <= 4'h0;
	default: color_code <= pixelColor;
	endcase
	// See if the mib overrides the output
	for (n13 = 0; n13 < MIBCNT; n13 = n13 + 1) begin
		if (!mdp[n13] || !pixelBgFlag) begin
			if (mmc[n13]) begin  // multi-color mode ?
				case(MCurrentPixel[n13])
				2'b00:  ;
				2'b01:  color_code <= mm0;
				2'b10:  color_code <= mc[n13];
				2'b11:  color_code <= mm1;
				endcase
			end
			else if (MCurrentPixel[n13][1])
				color_code <= mc[n13];
		end
	end
end

always_ff @(posedge clk)
if (dotclk_en) begin
	if (vicBlank)
		color <= 4'd0;
  else if (vicBorder)
		color <= ec;
  else
		color <= color_code;
end

endmodule
