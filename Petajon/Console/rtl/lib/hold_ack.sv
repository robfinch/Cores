// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// hold_ack.v
//	- For those devices not following the WISHBONE standard properly
//	  which only pulse the ack signal, extend the ack until cycle is
//		inactive.
//
// ============================================================================
//

module hold_ack(clk, cyc_i, stb_i, ack_i, ack_o);
input clk;
input cyc_i;
input stb_i;
input ack_i;
output reg ack_o;

reg hack;
assign ack_o = ack_i|hack;

always @(posedge clk)
begin
	if (!(cyc_i & stb_i))
		hack <= 1'b0;
	if (ack_i)
		hack <= 1'b1;
end

endmodule
