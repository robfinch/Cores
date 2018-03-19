// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// EqualizationPulse.v
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

always @*
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
