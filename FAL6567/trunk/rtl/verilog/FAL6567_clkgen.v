// ============================================================================
// (C) 2016 Robert Finch
// rob<remove>@finitron.ca
// All Rights Reserved.
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
input xclk;
output clk33;
output locked;

BUFG bg2 (.I(clk33u), 	.O(clk33) );
wire clkfb,clkfbo;
BUFG clkbufg (.I(clkfbo), .O(clkfb));

PLLE2_BASE u1
(
    .RST(rst),
    .CLKIN1(xclk),
    .CLKFBIN(clkfb),
    .CLKFBOUT(clkfbo),
    .LOCKED(locked),
    .CLKOUT0(clk33u),
    .CLKOUT1(),
    .CLKOUT2(),
    .CLKOUT3(),
    .CLKOUT4(),
    .CLKOUT5()
);
defparam u1.CLKFBOUT_MULT = 12;     // must place VCO frequency 800-1600 MHz (1200)
defparam u1.CLKOUT0_DIVIDE = 36;
defparam u1.CLKIN1_PERIOD = 10;

endmodule
