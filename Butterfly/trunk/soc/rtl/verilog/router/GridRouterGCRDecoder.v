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
module GridRouterGCRDecoder(clk, i, o);
input clk;
input [13:0] i;
output reg [8:0] o;

function [3:0] fnGCRToBin;
input [2:0] bin;
begin
case(bin)
4'hA:   fnGCRToBin = 3'd0;
4'hB:   fnGCRToBin = 3'd1;
4'h9:   fnGCRToBin = 3'd2;
4'hC:   fnGCRToBin = 3'd3;
4'h4:   fnGCRToBin = 3'h4;
4'h5:   fnGCRToBin = 3'h5;
4'h6:   fnGCRToBin = 3'h6;
4'h7:   fnGCRToBin = 3'h7;
default:    fnGCRToBin = 3'd0;
endcase
end
endfunction

always @(posedge clk)
    o <= {fnGCRToBin(i[11:8]),fnGCRToBin(i[7:4]),fnGCRToBin(i[3:0])};

endmodule
