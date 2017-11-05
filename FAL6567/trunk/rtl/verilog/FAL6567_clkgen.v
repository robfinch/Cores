// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_clkgen.v
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
module FAL6567_clkgen(rst, xclk, clk33, locked);
input rst;
input xclk;     // 14.31818MHz color reference
output clk33;
output locked;

wire clk8u, clk33u;
BUFG bg2 (.I(clk33u), 	.O(clk33) );
wire clkfb,clkfbo;
BUFG clkbufg (.I(clkfbo), .O(clkfb));

// MMCM must be used rather than a PLL because the PLL min frequency is
// 19 MHz, just a bit too high for the 14.318MHz color reference clock.
// The MMCM has a min frequency of 10MHz.
MMCM_BASE u1
(
    .RST(rst),
    .CLKIN1(xclk),
    .CLKFBIN(clkfb),
    .CLKFBOUT(clkfbo),
    .LOCKED(locked),
    .CLKOUT0(clk33u)
);
defparam u1.CLKFBOUT_MULT_F = 66.000;     // must place VCO frequency 800-1600 MHz (945Mhz)
defparam u1.CLKOUT0_DIVIDE_F = 28.000;
defparam u1.CLKIN1_PERIOD = 69.8412;

endmodule
