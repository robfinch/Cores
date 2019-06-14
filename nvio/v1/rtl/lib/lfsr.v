// ============================================================================
//        __
//   \\__/ o\    (C) 2003-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	lfsr.v
//  - linear feedback shift register
//  - parameterized
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
//
// ============================================================================
//
module lfsr(rst, clk, ce, cyc, o);
	parameter WID=17;
	parameter RST_VAL=0;
	localparam MSB=WID-1;
	
	input rst;
	input clk;
	input ce;
	input cyc;				// shorten the feedback cycle
	output [WID:1] o;
	
	reg [WID:0] c;
	reg [23:0] n;
	assign o = c[WID:1];

	always @(posedge clk) begin
		case (WID)
		3:	n <= 24'h00_0003;
		4:	n <= 24'h00_0004;
		5:	n <= 24'h00_0003;
		6:	n <= 24'h00_0005;
		7:	n <= 24'h00_0006;
		8:	n <= 24'h06_0504;
		9:	n <= 24'h00_0005;
		10:	n <= 24'h00_0007;
		11:	n <= 24'h00_0009;
		12:	n <= 24'h06_0401;
		13:	n <= 24'h04_0301;
		14:	n <= 24'h05_0301;
		15:	n <= 24'h00_000E;
		16:	n <= 24'h0F_0D04;
		17: n <= 24'h00_000E;
		18: n <= 24'h00_000B;
		19: n <= 24'h06_0201;
		20: n <= 24'h00_0011;
		21: n <= 24'h00_0013;
		22:	n <= 24'h00_0015;
		23: n <= 24'h00_0012;
		24:	n <= 24'h17_1611;
		25: n <= 24'h00_0016;
		26: n <= 24'h06_0201;
		27: n <= 24'h05_0201;
		28: n <= 24'h00_0019;
		29: n <= 24'h00_001B;
		30: n <= 24'h06_0401;
		31: n <= 24'h00_001C;
		default:
			n <= 24'h00_0000;
		endcase
	end

			
	always @(posedge clk)
		if (rst)
			c <= RST_VAL;
		else if (ce)
			c <= {c[MSB:0],~(c[WID]^c[n[23:16]]^c[n[15:8]]^c[n[7:0]]^cyc)};
			
endmodule

