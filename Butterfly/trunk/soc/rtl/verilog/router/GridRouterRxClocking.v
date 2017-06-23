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
// ============================================================================
//
module GridRouterRxClocking(rst, refclk, clk_p, clk_n, sclk, pclk);
input rst;
input refclk;
input clk_p;
input clk_n;
output sclk;
output pclk;

parameter pIOStandard = "TMDS_33";
parameter pClkRange = 3.0;
parameter pClkMult = 4.0;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

wire pclki,sclki;
wire clkfb;
wire locked;
wire pe_lock,ne_lock;
reg [2:0] mmcm_rst;

IBUFDS #(
    .DIFF_TERM("FALSE"),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD(pIOStandard)
    )
u1
(
    .O(pclki),
    .I(clk_p),
    .IB(clk_n)
);

BUFIO u2
(
    .O(sclk),
    .I(sclki)
);

BUFR #(
    .BUFR_DIVIDE("4"),
    .SIM_DEVICE("7SERIES")
    )
u3
(
    .O(pclk),
    .I(sclki),
    .CE(1'b1),
    .CLR(pe_lock)
);

edge_det u4 (.rst(rst), .clk(refclk), .ce(1'b1), .i(locked), .pe(pe_lock), .ne(ne_lock), .ee() );

always @(posedge refclk)
if (rst)
    mmcm_rst <= 3'b111;
else begin
    if (ne_lock)
        mmcm_rst <= 3'b111;
    else
        mmcm_rst <= {1'b0,mmcm_rst[1:0]};
end

MMCME2_ADV #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKOUT4_CASCADE("FALSE"),
    .COMPENSATION("ZHOLD"),
    .STARTUP_WAIT("FALSE"),
    .DIVCLK_DIVIDE(1),
    .CLKFBOUT_MULT_F(pClkRange * pClkMult),
    .CLKFBOUT_PHASE(0.0),
    .CLKFBOUT_USE_FINE_PS("FALSE"),
    .CLKOUT0_DIVIDE_F(pClkRange),
    .CLKOUT0_PHASE(0.000),
    .CLKOUT0_DUTY_CYCLE(0.500),
    .CLKOUT0_USE_FINE_PS("FALSE"),
    .CLKIN1_PERIOD(pClkRange * 6.0),
    .REF_JITTER1(0.010)
   )
u6
(
    .CLKFBOUT(clkfb),
    .CLKFBOUTB(),
    .CLKOUT0(sclki),
    .CLKOUT0B(),
    .CLKOUT1(),
    .CLKOUT1B(),
    .CLKOUT2(),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    .CLKFBIN(clkfb),
    .CLKIN1(pclki),
    .CLKIN2(1'b0),
    .CLKINSEL(1'b1),
    .DADDR(0),
    .DCLK(1'b0),
    .DEN(1'b0),
    .DI(0),
    .DO(),
    .DRDY(),
    .DWE(1'b0),
    .PSCLK(1'b0),
    .PSEN(1'b0),
    .PSINCDEC(1'b0),
    .PSDONE(),
    .LOCKED(locked),
    .CLKINSTOPPED(),
    .CLKFBSTOPPED(),
    .PWRDWN(1'b0),
    .RST(mmcm_rst[0])    
);

endmodule
