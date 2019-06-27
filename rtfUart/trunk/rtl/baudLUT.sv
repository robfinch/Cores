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
module baudLUT(a, o);
parameter pCounterBits = 32;
input [4:0] a;
output reg [pCounterBits-1:0] o;

// table for a 100.000MHz clock
// value = baud * 16 * 2^ counter bits / clock frequency
always @(a)
	case (a)	// synopsys full_case parallel_case
	5'd0:	o <= 0;
	5'd1:	o <= 32'd34360;	// 50 baud
	5'd2:	o <= 32'd51540;	// 75 baud
	5'd3:	o <= 32'd75536;	// 109.92 baud
	5'd4:	o <= 32'd92483;	// 134.58 baud
	5'd5:	o <= 32'd103079;	// 150 baud
	5'd6:	o <= 32'd206158;	// 300 baud
	5'd7:	o <= 32'd412317;	// 600 baud
	5'd8:	o <= 32'd824634;	// 1200 baud
	5'd9:	o <= 32'd1236951;	// 1800 baud
	5'd10:	o <= 32'd1649267;	// 2400 baud
	5'd11:	o <= 32'd2473901;	// 3600 baud
	5'd12:	o <= 32'd3298535;	// 4800 baud
	5'd13:	o <= 32'd4947802;	// 7200 baud
	5'd14:	o <= 32'd6597070;	// 9600 baud
	5'd15:	o <= 32'd13194140;	// 19200 baud

	5'd16:	o <= 32'd26388279;	// 38400 baud
	5'd17:	o <= 32'd39582419;	// 57600 baud
	5'd18:	o <= 32'd79164837;	// 115200 baud
	5'd19:	o <= 32'd158329674;	// 230400 baud
	5'd20:	o <= 32'd316659349;	// 460800 baud
	5'd21:	o <= 32'd633318698;	// 921600 baud
	5'd22:	o <= 32'd1266637395;	// 1843200 baud
	5'd23:	o <= 32'd2533274790;	// 3686400 baud
	default:	o <= 32'd13194140;	// 19200 baud
	endcase

endmodule


