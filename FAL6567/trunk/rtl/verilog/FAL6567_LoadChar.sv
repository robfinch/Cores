// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_LoadChar.sv
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

module FAL6567_LoadChar(rst, clk, col80, phi02, enaData, vicCycle, badline, 
	startFetchCharBmp, fetchCharBmp, db, propChar, char);
input rst;
input clk;
input col80;
input phi02;
input enaData;
input [2:0] vicCycle;
input badline;
input [11:0] db;
input [11:0] propChar;		// propagated char
output reg [11:0] char;

integer n2;
always_ff @(posedge clk)
if (rst)
	char <= 12'h000;
else begin
	if (startFetchCharBmp)
		char <= 12'h000;
	else if (enaData) begin
		if (phi02==`LOW && fetchCharBmp)
			char <= char + 2'd1;
		else if (col80) begin
			if (vicCycle==VIC_CHAR) begin
				if (badline)
					char <= db;
				else
					char <= propChar;
			end
		end
		else begin
			if (phi02==`HIGH && (vicCycle==VIC_RC || vicCycle==VIC_CHAR)) begin
				if (badline)
					char <= db;
				else
					char <= propChar;
			end
		end
	end
end

endmodule
