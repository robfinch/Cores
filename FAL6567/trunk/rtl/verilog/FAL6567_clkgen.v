// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2018  Robert Finch, Waterloo
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
module FAL6567_clkgen(rst, xclk, clk33, clk33_120, clk33_240, turbo2, dcrate, dotclk, clk57, locked);
parameter PAL = 1'b0;
input rst;
input xclk;     // 14.31818MHz color reference
output clk33;
output clk33_120;
output clk33_240;
input turbo2;
input dcrate;
output dotclk;
output clk57;
output locked;

wire clk8u, clk33u, clk40u;
wire clk33_120u, clk33_240u, clk40_120u, clk40_240u;
wire clk14u, clk57u;
wire clkfb,clkfbo;
BUFG clkbufg (.I(clkfbo), .O(clkfb));
BUFG cb3 (.I(clk57u), .O(clk57));
BUFGMUX cb5 (.S(turbo2), .I0(clk33u), .I1(clk40u), .O(clk33));
BUFGMUX cb6 (.S(dcrate), .I0(clk8u), .I1(clk14u), .O(dotclk));
BUFGMUX cb7 (.S(turbo2), .I0(clk33_120u), .I1(clk40_120u), .O(clk33_120));
BUFGMUX cb8 (.S(turbo2), .I0(clk33_240u), .I1(clk40_240u), .O(clk33_240));

generate begin : mmcm
if (PAL) begin : pal_mmcm
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
    .CLKOUT0(clk33u),
    .CLKOUT1(clk33_120u),
    .CLKOUT2(clk8u),
    .CLKOUT3(clk57u),
    .CLKOUT4(clk14u),
    .CLKOUT5(clk33_240u)
);
defparam u1.CLKFBOUT_MULT_F = 64.000;   // can't be any higher than 64!  must place VCO frequency 800-1600 MHz (1135Mhz for PAL)
defparam u1.CLKOUT0_DIVIDE_F = 36;		// = 31.5MHz base clock
defparam u1.CLKOUT1_DIVIDE = 36;
defparam u1.CLKOUT1_PHASE = 120;		// 
defparam u1.CLKOUT2_DIVIDE = 144;		// 7.881978 MHz dot clock
defparam u1.CLKOUT3_DIVIDE = 16;		// 16x color burst 70.937800MHz
defparam u1.CLKOUT4_DIVIDE = 64;		// 17.734450 MHz
defparam u1.CLKOUT5_DIVIDE = 36;
defparam u1.CLKOUT5_PHASE = 240;
defparam u1.CLKIN1_PERIOD = 69.8412;

MMCM_BASE u2
(
    .RST(rst),
    .CLKIN1(xclk),
    .CLKFBIN(clkfb),
    .CLKFBOUT(clkfbo),
    .LOCKED(locked),
    .CLKOUT0(clk40u),
    .CLKOUT1(clk40_120u),
    .CLKOUT2(clk40_240u)
);
defparam u2.CLKFBOUT_MULT_F = 64.000;     	// can't be any higher than 64!  must place VCO frequency 800-1600 MHz (916Mhz)
defparam u2.CLKOUT0_DIVIDE_F = 30.000;		// 37.833493 MHz
defparam u2.CLKOUT1_DIVIDE = 30;
defparam u2.CLKOUT1_PHASE = 120;
defparam u2.CLKOUT2_DIVIDE = 30;
defparam u2.CLKOUT2_PHASE = 240;
defparam u2.CLKIN1_PERIOD = 69.8412;

end
else begin
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
    .CLKOUT0(clk33u),
    .CLKOUT1(clk33_120u),
    .CLKOUT2(clk8u),
    .CLKOUT3(clk57u),
    .CLKOUT4(clk14u),
    .CLKOUT5(clk33_240u)
);
defparam u1.CLKFBOUT_MULT_F = 64.000;     // can't be any higher than 64!  must place VCO frequency 800-1600 MHz (916Mhz)
defparam u1.CLKOUT0_DIVIDE_F = 28;			
defparam u1.CLKOUT1_DIVIDE = 28;
defparam u1.CLKOUT1_PHASE = 120;
defparam u1.CLKOUT2_DIVIDE = 112;
defparam u1.CLKOUT3_DIVIDE = 16;
defparam u1.CLKOUT4_DIVIDE = 64;
defparam u1.CLKOUT5_DIVIDE = 28;
defparam u1.CLKOUT5_PHASE = 240;
defparam u1.CLKIN1_PERIOD = 69.8412;

MMCM_BASE u2
(
    .RST(rst),
    .CLKIN1(xclk),
    .CLKFBIN(clkfb),
    .CLKFBOUT(clkfbo),
    .LOCKED(locked),
    .CLKOUT0(clk40u),
    .CLKOUT1(clk40_120u),
    .CLKOUT2(clk40_240u)
);
defparam u2.CLKFBOUT_MULT_F = 64.000;     // can't be any higher than 64!  must place VCO frequency 800-1600 MHz (916Mhz)
defparam u2.CLKOUT0_DIVIDE_F = 24.000;
defparam u2.CLKOUT1_DIVIDE = 24;
defparam u2.CLKOUT1_PHASE = 120;
defparam u2.CLKOUT2_DIVIDE = 24;
defparam u2.CLKOUT2_PHASE = 240;
defparam u2.CLKIN1_PERIOD = 69.8412;

end
end
endgenerate

endmodule
