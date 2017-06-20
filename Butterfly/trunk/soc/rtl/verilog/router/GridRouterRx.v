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
// Notes:
//  Channel bonding isn't required because the channels do not have to be
//  synchronized with each other.
//  The received data is feeding a UART
// ============================================================================
//
module GridRouterRx(rst, refclk, pclk, o, clk_p, clk_n, seri_p, seri_n);
input rst;
input refclk;
input pclk;
output reg [26:0] o;
input clk_p;
input clk_n;
input [2:0] seri_p;
input [2:0] seri_n;

wire sclk;
wire [41:0] i;
wire [26:0] o1;
wire [11:0] pclk2;

GridRouterRxClocking u1
(
    .rst(rst),
    .refclk(refclk),
    .clk_p(clk_p),
    .clk_n(clk_n),
    .sclk(sclk),
    .pclk(pclk2)
);

GridRouterGCRDecoder u2
(
    .clk(pclk2),
    .i(i[13:0]),
    .o(o1[8:0])
);

GridRouterGCRDecoder u3
(
    .clk(pclk2),
    .i(i[27:14]),
    .o(o1[17:9])
);

GridRouterGCRDecoder u4
(
    .clk(pclk2),
    .i(i[41:28]),
    .o(o1[26:18])
);

GridRouterSerialIn u5
(
    .rst(rst),
    .pclk(pclk2),
    .sclk(sclk),
    .dato(i[13:0]),
    .seri_p(seri_p[0]),
    .seri_n(seri_n[0])
);

GridRouterSerialIn u6
(
    .rst(rst),
    .pclk(pclk2),
    .sclk(sclk),
    .dato(i[27:14]),
    .seri_p(seri_p[1]),
    .seri_n(seri_n[1])
);

GridRouterSerialIn u7
(
    .rst(rst),
    .pclk(pclk2),
    .sclk(sclk),
    .dato(i[41:28]),
    .seri_p(seri_p[2]),
    .seri_n(seri_n[2])
);

// Register the output onto the pclk domain.
always @(posedge pclk)
    o <= o1;

endmodule
