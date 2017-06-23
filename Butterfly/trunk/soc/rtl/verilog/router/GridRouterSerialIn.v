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
//
// Input serializer for grid router.
// ============================================================================
//
module GridRouterSerialIn(rst, pclk, sclk, seri_p, seri_n, dato);
parameter pIOStandard = "TMDS_33";
parameter pParallelWidth = 8;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input pclk;         // parallel load clock
input sclk;         // serial clock
input seri_p;      // serial output
input seri_n;
output reg [7:0] dato;  // output data

wire [7:0] q;
wire seri;

IBUFDS #(
    .DIFF_TERM("FALSE"),
    .IOSTANDARD(pIOStandard)
   )
u1
(
    .I(seri_p),
    .IB(seri_n),
    .O(seri)
);

ISERDESE2 #(
    .DATA_RATE("DDR"),
    .DATA_WIDTH(pParallelWidth),
    .INTERFACE_TYPE("NETWORKING"),
    .DYN_CLKDIV_INV_EN("FALSE"),
    .DYN_CLK_INV_EN("FALSE"),
    .NUM_CE(2),
    .OFB_USED("FALSE"),
    .SERDES_MODE("MASTER"),
    .IOBDELAY("NONE")
   )
u2
(
    .Q1(q[0]),
    .Q2(q[1]),
    .Q3(q[2]),
    .Q4(q[3]),
    .Q5(q[4]),
    .Q6(q[5]),
    .Q7(q[6]),
    .Q8(q[7]),
    .SHIFTOUT1(),
    .SHIFTOUT2(),
    .BITSLIP(1'b0),
    .CE1(1'b1),
    .CE2(1'b1),
    .CLK(sclk),
    .CLKB(~sclk),
    .CLKDIV(pclk),
    .CLKDIVP(1'b0),
    .D(seri),
    .DDLY(1'b0),
    .RST(rst),
    .SHIFTIN1(1'b0),
    .SHIFTIN2(1'b0),
    .DYNCLKDIVSEL(1'b0),
    .DYNCLKSEL(1'b0),
    .OFB(1'b0),
    .OCLK(1'b0),
    .OCLKB(1'b0),
    .O()
);        

integer n;
always @*
    for (n = 0; n < pParallelWidth; n = n + 1)
        dato[n] <= q[pParallelWidth-n-1];

endmodule
