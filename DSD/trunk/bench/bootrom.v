`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
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
// ============================================================================
//
module bootrom_sim(rst_i, clk_i, va_i, rdy_o, adr_i, dat_o);
input rst_i;
input clk_i;
input va_i;
output rdy_o;
input [31:0] adr_i;
output [31:0] dat_o;
reg [31:0] dat_o;

wire cs;
assign cs = va_i && (adr_i[31:14]==18'h3FFFF);
assign rdy_o = 1'b1;

reg [38:0] rommem0[0:8191];
initial begin
`include "C:\Cores4\DSD\trunk\software\bootrom\source\bootrom.ve0"
end

always @(cs or adr_i)
	if (cs)
		dat_o <= rommem0[adr_i[13:2]][31:0];
	else
		dat_o <= 32'd0;

endmodule
