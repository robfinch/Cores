// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_borders.sv
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

module FAL6567_borders(clk33, den, rsel, csel, rasterX, rasterY, hBorder, vBorder, border);
input clk33;
input den;
input rsel;
input csel;
input [9:0] rasterX;
input [8:0] rasterY;
output reg hBorder;
output reg vBorder;
output border;

always_ff @(posedge clk33)
begin
	vBorder <= `TRUE;
	if (den) begin
		if (rsel) begin
			if (rasterY >= 9'd51 && rasterY <= 9'd251)
				vBorder <= `FALSE;
		end
		else begin
			if (rasterY >= 9'd55 && rasterY <= 9'd247)
				vBorder <= `FALSE;
		end
	end
end

always_ff @(posedge clk33)
begin
	hBorder <= `TRUE;
	if (den) begin
		if (csel) begin
			if (rasterX >= 10'd25 && rasterX <= 10'd345)
				hBorder <= `FALSE;
		end
		else begin
			if (rasterX >= 10'd32 && rasterX <= 10'd336)
				hBorder <= `FALSE;
		end
	end
end

assign border = hBorder | vBorder;

endmodule
