// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_clkgen.sv
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                
// ============================================================================
//
module FAL6567_clkgen(rst, xclk, clk164, clk33, turbo2, dcrate, dotclk, clk57, locked);
parameter PAL = 1'b0;
input rst;
input xclk;     // 14.31818MHz color reference
output clk164;	// 5x 32.71705MHz
output clk33;		// 32.71705MHz
input turbo2;
input dcrate;
output dotclk;
output clk57;
output locked;

wire clk8u, clk33u, clk40u;
wire clk164u;
wire clk14u, clk57u;
wire clkfb,clkfbo;
BUFG clkbufg (.I(clkfbo), .O(clkfb));
BUFG clkbuf164 (.I(clk164u), .O(clk164));
BUFG cb3 (.I(clk57u), .O(clk57));
BUFGMUX cb5 (.S(turbo2), .I0(clk33u), .I1(clk40u), .O(clk33));
BUFGMUX cb6 (.S(dcrate), .I0(clk8u), .I1(clk14u), .O(dotclk));

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
    .CLKOUT0(clk164u),
    .CLKOUT1(clk33u),
    .CLKOUT2(clk8u),
    .CLKOUT3(clk57u),
    .CLKOUT4(clk14u)
);
defparam u1.CLKFBOUT_MULT_F = 64.000;   // can't be any higher than 64!  must place VCO frequency 800-1600 MHz (1135Mhz for PAL)
defparam u1.CLKOUT0_DIVIDE_F = 7.000;		// = 31.5MHz base clock
defparam u1.CLKOUT1_DIVIDE = 35;
defparam u1.CLKOUT2_DIVIDE = 144;		// 7.881978 MHz dot clock
defparam u1.CLKOUT3_DIVIDE = 16;		// 16x color burst 70.937800MHz
defparam u1.CLKOUT4_DIVIDE = 64;		// 17.734450 MHz
defparam u1.CLKIN1_PERIOD = 69.8412;

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
    .CLKOUT0(clk164u),
    .CLKOUT1(clk33u),
    .CLKOUT2(clk57u),
    .CLKOUT3(clk14u)
);
defparam u1.CLKFBOUT_MULT_F = 57.125;     // can't be any higher than 64!  must place VCO frequency 800-1600 MHz (817Mhz)
defparam u1.CLKOUT0_DIVIDE_F = 5.00;			
defparam u1.CLKOUT1_DIVIDE = 25;
defparam u1.CLKOUT2_DIVIDE = 14;
defparam u1.CLKOUT3_DIVIDE = 56;
defparam u1.CLKIN1_PERIOD = 69.8412;

end
end
endgenerate

endmodule
