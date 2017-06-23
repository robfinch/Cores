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
// Output serializer for grid router.
// ============================================================================
//
module GridRouterSerialOut(rst, pclk, sclk, dati, sero_p, sero_n);
parameter pIOStandard = "TMDS_33";
parameter pParallelWidth = 8;
input rst;
input pclk;         // parallel load clock
input sclk;         // serial clock
input [7:0] dati;  // input data
output sero_p;      // serial output
output sero_n;

wire sero;
wire q1, q2;

OBUFDS #(.IOSTANDARD(pIOStandard)) u1
(
    .O(sero_p),
    .OB(sero_n),
    .I(sero)
);

OSERDESE2 #(
    .DATA_RATE_OQ("DDR"),
    .DATA_RATE_TQ("SDR"),
    .DATA_WIDTH(pParallelWidth),
    .TRISTATE_WIDTH(1),
    .TBYTE_CTL("FALSE"),
    .TBYTE_SRC("FALSE"),
    .SERDES_MODE("MASTER")
    )
u2
(
    .OFB(),
    .OQ(sero),
    .SHIFTOUT1(),
    .SHIFTOUT2(),
    .TBYTEOUT(),
    .TFB(),
    .TQ(),
    .CLK(sclk),
    .CLKDIV(pclk),
    .D1(dati[0]),
    .D2(dati[1]),
    .D3(dati[2]),
    .D4(dati[3]),
    .D5(dati[4]),
    .D6(dati[5]),
    .D7(dati[6]),
    .D8(dati[7]),
    .OCE(1'b1),
    .RST(rst),
    .SHIFTIN1(),
    .SHIFTIN2(),
    .T1(1'b0),
    .T2(1'b0),
    .T3(1'b0),
    .T4(1'b0),
    .TBYTEIN(1'b0),
    .TCE(1'b0)
);
    
endmodule
