// ============================================================================
//        __
//   \\__/ o\    (C) 2005-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
//
module uart6551BaudLUT(a, o);
parameter pCounterBits = 24;
input [4:0] a;
output reg [pCounterBits-1:0] o;

// table for a 50.000MHz reference clock
// value = 50,000,000 / (baud * 16)
always @(a)
	case (a)	// synopsys full_case parallel_case
	5'd0:	o <= 0;
	5'd1:	o <= 24'd62500;	// 50 baud
	5'd2:	o <= 24'd41667;	// 75 baud
	5'd3:	o <= 24'd28617;	// 109.92 baud
	5'd4:	o <= 24'd23220;	// 134.58 baud
	5'd5:	o <= 24'd20833;	// 150 baud
	5'd6:	o <= 24'd10417;	// 300 baud
	5'd7:	o <= 24'd5208;	// 600 baud
	5'd8:	o <= 24'd2604;	// 1200 baud
	5'd9:	o <= 24'd1736;	// 1800 baud
	5'd10:	o <= 24'd1302;	// 2400 baud
	5'd11:	o <= 24'd868;	// 3600 baud
	5'd12:	o <= 24'd651;	// 4800 baud
	5'd13:	o <= 24'd434;	// 7200 baud
	5'd14:	o <= 24'd326;	// 9600 baud
	5'd15:	o <= 24'd163;	// 19200 baud

	5'd16:	o <= 24'd81;	// 38400 baud
	5'd17:	o <= 24'd54;	// 57600 baud
	5'd18:	o <= 24'd27;	// 115200 baud
	5'd19:	o <= 24'd14;	// 230400 baud
	5'd20:	o <= 24'd7;	// 460800 baud
	5'd21:	o <= 24'd3;	// 921600 baud
	default:	o <= 24'd326;	// 9600 baud
	endcase

endmodule


