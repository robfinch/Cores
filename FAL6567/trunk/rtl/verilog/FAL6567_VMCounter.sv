// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_VMCounter.sv
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

module FAL6567_VMCounter(rst, clk, col80, phi02, enaData, badline, vicCycle, 
	scanline, rasterX2, rasterY, rasterYMax, vmndx);
input rst;
input clk;
input col80;
input phi02;
input enaData;
input badline;
input [2:0] vicCycle;
input [2:0] scanline;
input [10:0] rasterX2;
input [8:0] rasterY;
input [8:0] rasterYMax;
output reg [10:0] vmndx;

reg [10:0] vmndxStart;

always_ff @(posedge clk)
if (rst) begin
	vmndx <= 11'd0;
	vmndxStart <= 11'd0;
end
else begin
	if (col80) begin
		if (enaData) begin
			if (rasterY==rasterYMax)
				vmndx <= 11'd0;
			if (vicCycle==VIC_CHAR && badline)
				vmndx <= vmndx + 1;
			if (rasterX2[10:4]==7'h3E) begin	// was 2c
				if (scanline==3'd7)
					vmndxStart <= vmndx;
				else
					vmndx <= vmndxStart;
			end
		end
	end
	else begin
		if (phi02 && enaData) begin
			if (rasterY==rasterYMax)
				vmndx <= 11'd0;
			if ((vicCycle==VIC_CHAR||vicCycle==VIC_G) && badline)
				vmndx <= vmndx + 1;
			if (rasterX2[10:4]==7'h3E) begin	// was 2c
				if (scanline==3'd7)
					vmndxStart <= vmndx;
				else
					vmndx <= vmndxStart;
			end
		end
	end
end

endmodule
