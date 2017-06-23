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
input [7:0] i;
output reg [5:0] o;

function [2:0] fnGCR4ToBin3;
input [3:0] gcr;
begin
case(gcr)
4'hA:   fnGCR4ToBin3 = 3'd0;
4'hB:   fnGCR4ToBin3 = 3'd1;
4'h9:   fnGCR4ToBin3 = 3'd2;
4'hC:   fnGCR4ToBin3 = 3'd3;
4'h4:   fnGCR4ToBin3 = 3'h4;
4'h5:   fnGCR4ToBin3 = 3'h5;
4'h6:   fnGCR4ToBin3 = 3'h6;
4'h7:   fnGCR4ToBin3 = 3'h7;
default:    fnGCR4ToBin3 = 3'd0;
endcase
end
endfunction

function [4:0] fnGCR5ToBin4;
input [3:0] bin;
begin
case(bin)
5'h0A:   fnGCR5ToBin4 = 4'h0;
5'h0B:   fnGCR5ToBin4 = 4'h1;
5'h12:   fnGCR5ToBin4 = 4'h2;
5'h13:   fnGCR5ToBin4 = 4'h3;
5'h0E:   fnGCR5ToBin4 = 4'h4;
5'h0F:   fnGCR5ToBin4 = 4'h5;
5'h16:   fnGCR5ToBin4 = 4'h6;
5'h17:   fnGCR5ToBin4 = 4'h7;
5'h09:   fnGCR5ToBin4 = 4'h8;
5'h19:   fnGCR5ToBin4 = 4'h9;
5'h1A:   fnGCR5ToBin4 = 4'hA;
5'h1B:   fnGCR5ToBin4 = 4'hB;
5'h0D:   fnGCR5ToBin4 = 4'hC;
5'h1D:   fnGCR5ToBin4 = 4'hD;
5'h1E:   fnGCR5ToBin4 = 4'hE;
5'h15:   fnGCR5ToBin4 = 4'hF;
default:    fnGCR5ToBin4 = 4'h0;
endcase
end
endfunction

function [5:0] fnGCR8ToBin6;
input [7:0] gcr;
begin
case(gcr)
8'h96:  fnGCR8ToBin6 = 6'h00;
6'h97:  fnGCR8ToBin6 = 6'h01;
6'h9A:  fnGCR8ToBin6 = 6'h02;
6'h9B:  fnGCR8ToBin6 = 6'h03;
6'h9D:  fnGCR8ToBin6 = 6'h04;
6'h9E:  fnGCR8ToBin6 = 6'h05;
6'h9F:  fnGCR8ToBin6 = 6'h06;
6'hA6:  fnGCR8ToBin6 = 6'h07;
6'hA7:  fnGCR8ToBin6 = 6'h08;
6'hAB:  fnGCR8ToBin6 = 6'h09;
6'hAC:  fnGCR8ToBin6 = 6'h0A;
6'hAD:  fnGCR8ToBin6 = 6'h0B;
6'hAE:  fnGCR8ToBin6 = 6'h0C;
6'hAF:  fnGCR8ToBin6 = 6'h0D;
6'hB2:  fnGCR8ToBin6 = 6'h0E;
6'hB3:  fnGCR8ToBin6 = 6'h0F;
6'hB4:  fnGCR8ToBin6 = 6'h10;
6'hB5:  fnGCR8ToBin6 = 6'h11;
6'hB6:  fnGCR8ToBin6 = 6'h12;
6'hB7:  fnGCR8ToBin6 = 6'h13;
6'hB9:  fnGCR8ToBin6 = 6'h14;
6'hBA:  fnGCR8ToBin6 = 6'h15;
6'hBB:  fnGCR8ToBin6 = 6'h16;
6'hBC:  fnGCR8ToBin6 = 6'h17;
6'hBD:  fnGCR8ToBin6 = 6'h18;
6'hBE:  fnGCR8ToBin6 = 6'h19;
6'hBF:  fnGCR8ToBin6 = 6'h1A;
6'hCB:  fnGCR8ToBin6 = 6'h1B;
6'hCD:  fnGCR8ToBin6 = 6'h1C;
6'hCE:  fnGCR8ToBin6 = 6'h1D;
6'hCF:  fnGCR8ToBin6 = 6'h1E;
6'hD3:  fnGCR8ToBin6 = 6'h1F;
6'hD6:  fnGCR8ToBin6 = 6'h20;
6'hD7:  fnGCR8ToBin6 = 6'h21;
6'hD9:  fnGCR8ToBin6 = 6'h22;
6'hDA:  fnGCR8ToBin6 = 6'h23;
6'hDB:  fnGCR8ToBin6 = 6'h24;
6'hDC:  fnGCR8ToBin6 = 6'h25;
6'hDD:  fnGCR8ToBin6 = 6'h26;
6'hDE:  fnGCR8ToBin6 = 6'h27;
6'hDF:  fnGCR8ToBin6 = 6'h28;
6'hE5:  fnGCR8ToBin6 = 6'h29;
6'hE6:  fnGCR8ToBin6 = 6'h2A;
6'hE7:  fnGCR8ToBin6 = 6'h2B;
6'hE9:  fnGCR8ToBin6 = 6'h2C;
6'hEA:  fnGCR8ToBin6 = 6'h2D;
6'hEB:  fnGCR8ToBin6 = 6'h2E;
6'hEC:  fnGCR8ToBin6 = 6'h2F;
6'hED:  fnGCR8ToBin6 = 6'h30;
6'hEE:  fnGCR8ToBin6 = 6'h31;
6'hEF:  fnGCR8ToBin6 = 6'h32;
6'hF2:  fnGCR8ToBin6 = 6'h33;
6'hF3:  fnGCR8ToBin6 = 6'h34;
6'hF4:  fnGCR8ToBin6 = 6'h35;
6'hF5:  fnGCR8ToBin6 = 6'h36;
6'hF6:  fnGCR8ToBin6 = 6'h37;
6'hF7:  fnGCR8ToBin6 = 6'h38;
6'hF9:  fnGCR8ToBin6 = 6'h39;
6'hFA:  fnGCR8ToBin6 = 6'h3A;
6'hFB:  fnGCR8ToBin6 = 6'h3B;
6'hFC:  fnGCR8ToBin6 = 6'h3C;
6'hFD:  fnGCR8ToBin6 = 6'h3D;
6'hFE:  fnGCR8ToBin6 = 6'h3E;
6'hFF:  fnGCR8ToBin6 = 6'h3F;
endcase
end
endfunction

always @(posedge clk)
    o <= fnGCR8ToBin6(i);

endmodule
