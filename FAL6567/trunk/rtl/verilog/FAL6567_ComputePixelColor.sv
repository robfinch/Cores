// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_ComputePixelColor.sv
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
module FAL6567_ComputePixelColor(rst, clk, dotclk_en, ecm, bmm, mcm, pixelColor,
	shiftingPixels, shiftingChar, b0c, b1c, b2c, b3c);
input rst;
input clk;
input dotclk_en;
input ecm;		// extended color mode
input bmm;		// bitmap mode
input mcm;		// multi-color mode
output reg [3:0] pixelColor;
input [7:0] shiftingPixels;
input [11:0] shiftingChar;
input [3:0] b0c;
input [3:0] b1c;
input [3:0] b2c;
input [3:0] b3c;

// Compute pixel color
always_ff @(posedge clk)
if (rst)
	pixelColor <= 4'h0;
else begin
	if (dotclk_en) begin
		pixelColor <= 4'h0; // black
		case({ecm,bmm,mcm})
		3'b000:	// Text mode
			pixelColor <= shiftingPixels[7] ? shiftingChar[11:8] : b0c;
		3'b001:	// Multi-color text mode
			if (shiftingChar[11])
				case(shiftingPixels[7:6])
				2'b00:  pixelColor <= b0c;
				2'b01:  pixelColor <= b1c;
				2'b10:  pixelColor <= b2c;
				2'b11:  pixelColor <= shiftingChar[10:8];
				endcase
			else
				pixelColor <= shiftingPixels[7] ? shiftingChar[11:8] : b0c;
		3'b010,3'b110: 
			pixelColor <= shiftingPixels[7] ? shiftingChar[7:4] : shiftingChar[3:0];
		3'b011,3'b111:
			case(shiftingPixels[7:6])
			2'b00:  pixelColor <= b0c;
			2'b01:  pixelColor <= shiftingChar[7:4];
			2'b10:  pixelColor <= shiftingChar[3:0];
			2'b11:  pixelColor <= shiftingChar[11:8];
			endcase
		3'b100:
			case({shiftingPixels[7],shiftingChar[7:6]})
			3'b000:  pixelColor <= b0c;
			3'b001:  pixelColor <= b1c;
			3'b010:  pixelColor <= b2c;
			3'b011:  pixelColor <= b3c;
			default:  pixelColor <= shiftingChar[11:8];
			endcase
		3'b101:
			if (shiftingChar[11])
				case(shiftingPixels[7:6])
				2'b00:  pixelColor <= b0c;
				2'b01:  pixelColor <= b1c;
				2'b10:  pixelColor <= b2c;
				2'b11:  pixelColor <= shiftingChar[11:8];
				endcase
			else
				case({shiftingPixels[7],shiftingChar[7:6]})
				3'b000:  pixelColor <= b0c;
				3'b001:  pixelColor <= b1c;
				3'b010:  pixelColor <= b2c;
				3'b011:  pixelColor <= b3c;
				default:  pixelColor <= shiftingChar[11:8];
				endcase
		endcase
	end
end

endmodule
