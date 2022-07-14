// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_blank.sv
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

module FAL6567_blank(chip, clk, col80, rasterX, rasterY, vBlank, hBlank, blank);
input [1:0] chip;
input clk;
input col80;
input [10:0] rasterX;
input [8:0] rasterY;
output reg vBlank;
output reg hBlank;
output blank;

always_ff @(posedge clk)
begin
	vBlank <= `FALSE;
	case(chip)
	CHIP6567R8,CHIP6567OLD:
		if (rasterY <= 9'd40)
			vBlank <= `TRUE;
	CHIP6569,CHIP6572:
		if (rasterY >= 9'd300 || rasterY < 9'd15)
			vBlank <= `TRUE;
	endcase
end

reg [10:0] hBlankOff;
reg [10:0] hBlankOn;
always_ff @(posedge clk)
	hBlankOff <= 11'd88;
always_ff @(posedge clk)
	hBlankOn <= col80 ? 11'd812 : 11'd492;

always_ff @(posedge clk)
begin
	hBlank <= `FALSE;
	if (rasterX < hBlankOff)		// 15%
		hBlank <= `TRUE;
	else if (rasterX >= hBlankOn)	// 97.2%
		hBlank <= `TRUE;
end

assign blank = hBlank | vBlank;

endmodule
