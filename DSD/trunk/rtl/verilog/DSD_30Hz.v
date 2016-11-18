// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD_30Hz.v
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
module DSD_30Hz(rst_i, clk_i, _30Hz_o);
input rst_i;
input clk_i;
output reg _30Hz_o;
parameter CLK_FREQ = 50000000;
localparam MAX_COUNT = CLK_FREQ / 30;

reg [31:0] count;

always @(posedge clk_i)
if (rst_i) begin
    _30Hz_o <= 1'b0;
    count <= 32'h1;
end
else begin
    if (count==MAX_COUNT) begin
        _30Hz_o <= 1'b1;
        count <= 32'h1;
    end
    if (count==30)
        _30Hz_o <= 1'b0;
end

endmodule
