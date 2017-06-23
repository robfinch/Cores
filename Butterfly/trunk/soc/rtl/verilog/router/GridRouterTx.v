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
module GridRouterTx(rst, pclk, sclk, ig1, ig2, ig3, clk_p, clk_n, sero_p, sero_n);
input rst;
input pclk;         // parallel clock
input sclk;         // serial clock
input [5:0] ig1;
input [5:0] ig2;
input [5:0] ig3;
output clk_p;
output clk_n;
output [2:0] sero_p;
output [2:0] sero_n;
parameter pIOStandard = "TMDS_33";

wire [7:0] o1, o2, o3;

GridRouterGCREncoder u1
(
    .clk(pclk),
    .i(ig1),
    .o(o1)
);

GridRouterGCREncoder u2
(
    .clk(pclk),
    .i(ig2),
    .o(o2)
);

GridRouterGCREncoder u3
(
    .clk(pclk),
    .i(ig3),
    .o(o3)
);

GridRouterSerialOut #(pIOStandard) u4
(
    .rst(rst),
    .pclk(pclk),
    .sclk(sclk),
    .dati(o1),
    .sero_p(sero_p[0]),
    .sero_n(sero_n[0])
);

GridRouterSerialOut #(pIOStandard) u5
(
    .rst(rst),
    .pclk(pclk),
    .sclk(sclk),
    .dati(o2),
    .sero_p(sero_p[1]),
    .sero_n(sero_n[1])
);

GridRouterSerialOut #(pIOStandard) u6
(
    .rst(rst),
    .pclk(pclk),
    .sclk(sclk),
    .dati(o3),
    .sero_p(sero_p[2]),
    .sero_n(sero_n[2])
);

GridRouterSerialOut #(pIOStandard) u7
(
    .rst(rst),
    .pclk(pclk),
    .sclk(sclk),
    .dati(14'b11111110000000),
    .sero_p(clk_p),
    .sero_n(clk_n)
);

endmodule
