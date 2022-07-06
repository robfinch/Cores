// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_ColorROM.sv
//		Color lookup ROM.
//		Converts a 4-bit color code to a 24 bit RGB value.
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

// TC64 color codes
`define TC64_BLACK			4'd0
`define TC64_WHITE			4'd1
`define TC64_RED			  4'd2
`define TC64_CYAN			  4'd3
`define TC64_PURPLE			4'd4
`define TC64_GREEN			4'd5
`define TC64_BLUE			  4'd6
`define TC64_YELLOW			4'd7
`define TC64_ORANGE			4'd8
`define TC64_BROWN			4'd9
`define TC64_PINK			  4'd10
`define TC64_DARK_GREY		4'd11
`define TC64_MEDIUM_GREY	4'd12
`define TC64_LIGHT_GREEN	4'd13
`define TC64_LIGHT_BLUE		4'd14
`define TC64_LIGHT_GREY		4'd15

module FAL6567_ColorROM(clk, ce, code, color);
input clk;
input ce;
input [3:0] code;
output [23:0] color;
reg [23:0] color;

always_ff @(posedge clk)
	if (ce) begin
		case (code)
		`TC64_BLACK:	 	color = 24'h10_10_10;
		`TC64_WHITE:	 	color = 24'hFF_FF_FF;
		`TC64_RED:    	color = 24'hE0_40_40;
		`TC64_CYAN:   	color = 24'h60_FF_FF;
		`TC64_PURPLE: 	color = 24'hE0_60_E0;
		`TC64_GREEN:	 	color = 24'h40_E0_40;
		`TC64_BLUE:   	color = 24'h40_40_E0;
		`TC64_YELLOW: 	color = 24'hFF_FF_40;
		`TC64_ORANGE: 	color = 24'hE0_A0_40;
		`TC64_BROWN:  	color = 24'h9C_74_48;
		`TC64_PINK:   	color = 24'hFF_A0_A0;
		`TC64_DARK_GREY:   	color = 24'h54_54_54;
		`TC64_MEDIUM_GREY: 	color = 24'h88_88_88;
		`TC64_LIGHT_GREEN: 	color = 24'hA0_FF_A0;
		`TC64_LIGHT_BLUE:  	color = 24'hA0_A0_FF;
		`TC64_LIGHT_GREY:  	color = 24'hC0_C0_C0;
		endcase
	end

endmodule


