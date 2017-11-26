`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013,2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//
// BusError.v
// - generate a bus timeout error if a cycle has been active without an ack
//   for too long of a time.
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
module BusError(rst_i, clk_i, cyc_i, ack_i, stb_i, adr_i, err_o);
parameter pTO=28'd50000000;
input rst_i;
input clk_i;
input cyc_i;
input ack_i;
input stb_i;
input [31:0] adr_i;
output err_o;
reg err_o;

reg [27:0] tocnt;

always @(posedge clk_i)
if (rst_i) begin
	err_o <= 1'b0;
	tocnt <= 28'd1;
end
else begin
	err_o <= 1'b0;
	// If there is no bus cycle active, or if the bus cycle
	// has been acknowledged, reset the timeout count.
	if (ack_i || !cyc_i) begin
		tocnt <= 28'd1;
		err_o <= 1'b0;
	end
	else if (tocnt < pTO)
		tocnt <= tocnt + 28'd1;
	else if (cyc_i && stb_i && (adr_i[31:4]==28'hFFDCFFE)) begin	// conflist with configrec ?
		tocnt <= 28'd1;
		err_o <= 1'b0;
	end
	else
		err_o <= 1'b1;
end

endmodule
