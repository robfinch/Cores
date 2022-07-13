// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// SerrationPulse.v
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
module SerrationPulse(chip, turbo2, rasterX, SE);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;
input [1:0] chip;
input turbo2;
input [9:0] rasterX;
output reg SE;

always @*
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
