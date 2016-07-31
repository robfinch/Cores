// ============================================================================
//	(C) 2006-2016  Robert Finch
//	rob@<remove>finitron.ca
//
//	FAL6567_ColorROM.v
//		Color lookup ROM.
//		Converts a 4-bit color code to a 24 bit RGB value.
//
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
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

always @(posedge clk)
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


