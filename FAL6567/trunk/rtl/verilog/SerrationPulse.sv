// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// SerrationPulse.v
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
module SerrationPulse(chip, turbo2, rasterX, SE);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;
input [1:0] chip;
input turbo2;
input [9:0] rasterX;
output reg SE;

always_comb
if (turbo2)
case(chip)
CHIP6567R8:
	SE <=		// 93% tH (7%tH) (3051-427)
	(rasterX < 10'd261) ||	// 43%
	(	
		(rasterX >= 10'd304) &&	// 50%
	 	(rasterX < 10'd565)		// 93%
	)
	;
CHIP6567OLD:
	SE <=		// 93% tH (7%tH) (3051-427)
	(rasterX < 10'd261) ||	// 43%
	(	
		(rasterX >= 10'd304) &&
	 	(rasterX < 10'd565)
	)
	;
	// ToDo: fix serration for PAL turbo2
CHIP6569,CHIP6572:
	SE <=		// 93% tH (7%tH) (3051-427)
	(rasterX < 10'd261) ||
	(	
		(rasterX >= 10'd304) &&
	 	(rasterX < 10'd565)
	)
	;
endcase
else
case(chip)
CHIP6567R8:
	SE <=		// 93% tH (7%tH) (3051-427)
	(rasterX < 10'd224) ||	// 43%
	(	
		(rasterX >= 10'd260) &&	// 50%
	 	(rasterX < 10'd484)		// 93%
	)
	;
CHIP6567OLD:
	SE <=		// 93% tH (7%tH) (3051-427)
	(rasterX < 10'd220) ||	// 43%
	(	
		(rasterX >= 10'd256) &&
	 	(rasterX < 10'd476)
	)
	;
CHIP6569,CHIP6572:
	SE <=		// 93% tH (7%tH) (3051-427)
	(rasterX < 10'd217) ||
	(	
		(rasterX >= 10'd252) &&
	 	(rasterX < 10'd469)
	)
	;
endcase

endmodule
