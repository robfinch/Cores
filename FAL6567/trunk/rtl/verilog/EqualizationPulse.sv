// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// EqualizationPulse.v
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
module EqualizationPulse(chip, turbo2, rasterX, EQ);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;
input [1:0] chip;
input turbo2;
input [9:0] rasterX;
output reg EQ;

always_comb
if (turbo2)
case(chip)
CHIP6567R8:
	EQ <=		//  4% tH equalization width
	(rasterX < 10'd24) ||
	(
		(rasterX >= 10'd304) &&	// 50%
		(rasterX < 10'd328)		// 54%
	)
	;
CHIP6567OLD:
	EQ <=		//  4% tH equalization width
	(rasterX < 10'd24) ||
	(
		(rasterX >= 10'd304) &&
		(rasterX < 10'd328)
	)
	;
CHIP6569,CHIP6572:
	EQ <=		//  4% tH equalization width
	(rasterX < 10'd24) ||
	(
		(rasterX >= 10'd304) &&
		(rasterX < 10'd328)
	)
	;
endcase
else
case(chip)
CHIP6567R8:
	EQ <=		//  4% tH equalization width
	(rasterX < 10'd21) ||
	(
		(rasterX >= 10'd260) &&	// 50%
		(rasterX < 10'd281)		// 54%
	)
	;
CHIP6567OLD:
	EQ <=		//  4% tH equalization width
	(rasterX < 10'd20) ||
	(
		(rasterX >= 10'd256) &&
		(rasterX < 10'd276)
	)
	;
CHIP6569,CHIP6572:
	EQ <=		//  4% tH equalization width
	(rasterX < 10'd20) ||	// 4%
	(
		(rasterX >= 10'd252) &&	// 50%
		(rasterX < 10'd272)		// 54%
	)
	;
endcase

endmodule
