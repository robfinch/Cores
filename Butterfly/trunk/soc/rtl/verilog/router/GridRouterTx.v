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
module GridRouterTx(rst, pclk, sclk, i, clk_p, clk_n, sero_p, sero_n);
input rst;
input pclk;         // parallel clock
input sclk;         // serial clock
input [26:0] i;
output clk_p;
output clk_n;
output [2:0] sero_p;
output [2:0] sero_n;
parameter pIOStandard = "TMDS_33";

wire [41:0] o;

GridRouterGCREncoder u1
(
    .clk(pclk),
    .i(i[8:0]),
    .o(o[13:0])
);

GridRouterGCREncoder u2
(
    .clk(pclk),
    .i(i[17:9]),
    .o(o[27:14])
);

GridRouterGCREncoder u3
(
    .clk(pclk),
    .i(i[26:18]),
    .o(o[41:28])
);

GridRouterSerialOut #(pIOStandard) u4
(
    .rst(rst),
    .pclk(pclk),
    .sclk(sclk),
    .dati(o[11:0]),
    .sero_p(sero_p[0]),
    .sero_n(sero_n[0])
);

GridRouterSerialOut #(pIOStandard) u5
(
    .rst(rst),
    .pclk(pclk),
    .sclk(sclk),
    .dati(o[23:12]),
    .sero_p(sero_p[1]),
    .sero_n(sero_n[1])
);

GridRouterSerialOut #(pIOStandard) u6
(
    .rst(rst),
    .pclk(pclk),
    .sclk(sclk),
    .dati(o[35:24]),
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
