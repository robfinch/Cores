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
input [5:0] i;
output reg [7:0] o;

function [3:0] fnBin3ToGCR4;
input [2:0] bin;
begin
case(bin)
3'd0:   fnBin3ToGCR4 = 4'hA;
3'd1:   fnBin3ToGCR4 = 4'hB;
3'd2:   fnBin3ToGCR4 = 4'h9;
3'd3:   fnBin3ToGCR4 = 4'hC;
3'd4:   fnBin3ToGCR4 = 4'h4;
3'd5:   fnBin3ToGCR4 = 4'h5;
3'd6:   fnBin3ToGCR4 = 4'h6;
3'd7:   fnBin3ToGCR4 = 4'h7;
endcase
end
endfunction

function [4:0] fnBin4ToGCR5;
input [3:0] bin;
begin
case(bin)
4'h0:   fnBin4ToGCR5 = 5'h0A;
4'h1:   fnBin4ToGCR5 = 5'h0B;
4'h2:   fnBin4ToGCR5 = 5'h12;
4'h3:   fnBin4ToGCR5 = 5'h13;
4'h4:   fnBin4ToGCR5 = 5'h0E;
4'h5:   fnBin4ToGCR5 = 5'h0F;
4'h6:   fnBin4ToGCR5 = 5'h16;
4'h7:   fnBin4ToGCR5 = 5'h17;
4'h8:   fnBin4ToGCR5 = 5'h09;
4'h9:   fnBin4ToGCR5 = 5'h19;
4'hA:   fnBin4ToGCR5 = 5'h1A;
4'hB:   fnBin4ToGCR5 = 5'h1B;
4'hC:   fnBin4ToGCR5 = 5'h0D;
4'hD:   fnBin4ToGCR5 = 5'h1D;
4'hE:   fnBin4ToGCR5 = 5'h1E;
4'hF:   fnBin4ToGCR5 = 5'h15;
endcase
end
endfunction

function [7:0] fnBin6ToGCR8;
input [5:0] bin;
begin
case(bin)
6'h00:  fnBin6ToGCR8 = 8'h96;
6'h01:  fnBin6ToGCR8 = 8'h97;
6'h02:  fnBin6ToGCR8 = 8'h9A;
6'h03:  fnBin6ToGCR8 = 8'h9B;
6'h04:  fnBin6ToGCR8 = 8'h9D;
6'h05:  fnBin6ToGCR8 = 8'h9E;
6'h06:  fnBin6ToGCR8 = 8'h9F;
6'h07:  fnBin6ToGCR8 = 8'hA6;
6'h08:  fnBin6ToGCR8 = 8'hA7;
6'h09:  fnBin6ToGCR8 = 8'hAB;
6'h0A:  fnBin6ToGCR8 = 8'hAC;
6'h0B:  fnBin6ToGCR8 = 8'hAD;
6'h0C:  fnBin6ToGCR8 = 8'hAE;
6'h0D:  fnBin6ToGCR8 = 8'hAF;
6'h0E:  fnBin6ToGCR8 = 8'hB2;
6'h0F:  fnBin6ToGCR8 = 8'hB3;
6'h10:  fnBin6ToGCR8 = 8'hB4;
6'h11:  fnBin6ToGCR8 = 8'hB5;
6'h12:  fnBin6ToGCR8 = 8'hB6;
6'h13:  fnBin6ToGCR8 = 8'hB7;
6'h14:  fnBin6ToGCR8 = 8'hB9;
6'h15:  fnBin6ToGCR8 = 8'hBA;
6'h16:  fnBin6ToGCR8 = 8'hBB;
6'h17:  fnBin6ToGCR8 = 8'hBC;
6'h18:  fnBin6ToGCR8 = 8'hBD;
6'h19:  fnBin6ToGCR8 = 8'hBE;
6'h1A:  fnBin6ToGCR8 = 8'hBF;
6'h1B:  fnBin6ToGCR8 = 8'hCB;
6'h1C:  fnBin6ToGCR8 = 8'hCD;
6'h1D:  fnBin6ToGCR8 = 8'hCE;
6'h1E:  fnBin6ToGCR8 = 8'hCF;
6'h1F:  fnBin6ToGCR8 = 8'hD3;
6'h20:  fnBin6ToGCR8 = 8'hD6;
6'h21:  fnBin6ToGCR8 = 8'hD7;
6'h22:  fnBin6ToGCR8 = 8'hD9;
6'h23:  fnBin6ToGCR8 = 8'hDA;
6'h24:  fnBin6ToGCR8 = 8'hDB;
6'h25:  fnBin6ToGCR8 = 8'hDC;
6'h26:  fnBin6ToGCR8 = 8'hDD;
6'h27:  fnBin6ToGCR8 = 8'hDE;
6'h28:  fnBin6ToGCR8 = 8'hDF;
6'h29:  fnBin6ToGCR8 = 8'hE5;
6'h2A:  fnBin6ToGCR8 = 8'hE6;
6'h2B:  fnBin6ToGCR8 = 8'hE7;
6'h2C:  fnBin6ToGCR8 = 8'hE9;
6'h2D:  fnBin6ToGCR8 = 8'hEA;
6'h2E:  fnBin6ToGCR8 = 8'hEB;
6'h2F:  fnBin6ToGCR8 = 8'hEC;
6'h30:  fnBin6ToGCR8 = 8'hED;
6'h31:  fnBin6ToGCR8 = 8'hEE;
6'h32:  fnBin6ToGCR8 = 8'hEF;
6'h33:  fnBin6ToGCR8 = 8'hF2;
6'h34:  fnBin6ToGCR8 = 8'hF3;
6'h35:  fnBin6ToGCR8 = 8'hF4;
6'h36:  fnBin6ToGCR8 = 8'hF5;
6'h37:  fnBin6ToGCR8 = 8'hF6;
6'h38:  fnBin6ToGCR8 = 8'hF7;
6'h39:  fnBin6ToGCR8 = 8'hF9;
6'h3A:  fnBin6ToGCR8 = 8'hFA;
6'h3B:  fnBin6ToGCR8 = 8'hFB;
6'h3C:  fnBin6ToGCR8 = 8'hFC;
6'h3D:  fnBin6ToGCR8 = 8'hFD;
6'h3E:  fnBin6ToGCR8 = 8'hFE;
6'h3F:  fnBin6ToGCR8 = 8'hFF;
endcase
end
endfunction

always @(posedge clk)
    o <= fnBin6ToGCR8(i);

endmodule
