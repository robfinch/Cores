// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Manni.v
//  - map the address lines output in 1MB regions so that all of the 
//    512MB ram is used.
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
module Manni(ad, ado);
input [31:1] ad;
output [31:1] ado;

reg [11:0] adh;
always @*
case(ad[31:20])
12'h000:	adh <= ad[31:20];
12'h001:	adh <= ad[31:20];
12'h002:	adh <= ad[31:20];
12'h003:	adh <= ad[31:20];
12'h004:	adh <= ad[31:20];
12'h005:	adh <= ad[31:20];
12'h006:	adh <= ad[31:20];
12'h007:	adh <= ad[31:20];
12'h008:	adh <= ad[31:20];
12'h009:	adh <= ad[31:20];
12'h00C:	adh <= 12'h00A;
12'h070:	adh <= 12'h00B;
12'h071:	adh <= 12'h00C;
12'h072:	adh <= 12'h00D;
12'h073:	adh <= 12'h00E;
12'h074:	adh <= 12'h00F;
12'h075:	adh <= 12'h010;
12'h076:	adh <= 12'h011;
12'h077:	adh <= 12'h012;
12'h078:	adh <= 12'h013;
12'h079:	adh <= 12'h014;
12'h07A:	adh <= 12'h015;
12'h07B:	adh <= 12'h016;
12'h07C:	adh <= 12'h017;
12'h07D:	adh <= 12'h018;
12'h07E:	adh <= 12'h019;
12'h07F:	adh <= 12'h01A;
default:
	if (ad[31:20]==12'h800 && ad[31:20] < 12'h9E6)
		adh <= 12'h01B + (ad[31:20]^12'h800);
	else
		adh <= 12'hFFF;
endcase
assign ado = {adh,ad[19:1]};
endmodule
