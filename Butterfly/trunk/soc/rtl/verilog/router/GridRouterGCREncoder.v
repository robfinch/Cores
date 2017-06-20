// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
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
module GridRouterGCREncoder(clk, i, o);
input clk;
input [8:0] i;
output reg [13:0] o;

function [3:0] fnBinToGCR;
input [2:0] bin;
begin
case(bin)
3'd0:   fnBinToGCR = 4'hA;
3'd1:   fnBinToGCR = 4'hB;
3'd2:   fnBinToGCR = 4'h9;
3'd3:   fnBinToGCR = 4'hC;
3'd4:   fnBinToGCR = 4'h4;
3'd5:   fnBinToGCR = 4'h5;
3'd6:   fnBinToGCR = 4'h6;
3'd7:   fnBinToGCR = 4'h7;
endcase
end
endfunction

always @(posedge clk)
    o <= {2'b00,fnBinToGCR(i[8:6]),fnBinToGCR(i[5:3]),fnBinToGCR(i[2:0])};

endmodule
