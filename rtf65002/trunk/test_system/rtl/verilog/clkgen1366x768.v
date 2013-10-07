//=============================================================================
//	2012-2013 Robert T Finch
//	robfinch@opencores.org
//
//	clkgen1366x768.v
//
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
//
//	System clock generator. Generates clock enables for various parts of the
//	system.
//
//=============================================================================

module clkgen1366x768(xreset, xclk, rst, clk100, clk50, clk200, clk125, vclk, vclk2, vclk10, sys_clk, dram_clk, locked, pulse1000Hz, pulse100Hz);
parameter pClkFreq=20000000;
input xreset;		// external reset
input xclk;			// external clock source (100 MHz)
output rst;
output clk100;		// cpu (system clock - eg. 100.000 MHz)
output clk50;
output clk200;
output clk125;		// 125 MHz
output vclk;		// video clock  (85.7Mhz)
output vclk2;		// video clock *2
output vclk10;		// video clock *10
output sys_clk;		// system clock (50 MHz)
output dram_clk;	// DDR2 ram clock (286 MHz)
output locked;
output pulse1000Hz;	// 1000 Hz pulse
output pulse100Hz;

wire gnd;
wire clk200u;
wire clkfb;
wire clk2x;
wire clk25u;
wire clk100u;		// unbuffered 50MHz
wire clk85u;		// unbuffered 85MHz
wire clk125u;
wire clkvu;
wire locked0,locked1;
wire pllfb;
wire ivclk;
wire ivclk2;
wire ivclk10;
wire isys_clk;
wire idram_clk;
wire clk125b;

assign gnd = 1'b0;

BUFG bg0 (.I(clk100u), 	.O(clk100) );
//BUFG bg1 (.I(clk73u), 	.O(vclk) );
BUFG bg2 (.I(clk50u), 	.O(clk50) );
BUFG bg3 (.I(clk200u),  .O(clk200) );
BUFG bg1 (.I(ivclk), .O(vclk) );
BUFG bg4 (.I(ivclk2), .O(vclk2) );
BUFG bg5 (.I(clk85u), .O(sys_clk) );
BUFG bg6 (.I(clk200u), .O(dram_clk) );
BUFG bg7 (.I(clk125u), .O(clk125b) );
//BUFG bg5 (.I(ivclk10), .O(vclk10) );

ODDR2 #(
      .DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1" 
      .SRTYPE    ("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
   ) ODDR2_inst (
      .Q     (clk125),   // 1-bit DDR output data
      .C0    (clk125b),   // 1-bit clock input
      .C1    (~clk125b),  // 1-bit clock input
      .CE    (1'b1),       // 1-bit clock enable input
      .D0    (1'b1),       // 1-bit data input (associated with C0)
      .D1    (1'b0),       // 1-bit data input (associated with C1)
      .R     (1'b0),       // 1-bit reset input
      .S     (1'b0) );     // 1-bit set input


// Reset:
//
// Hold the reset line active for a few thousand clock cycles
// to allow the clock generator and other devices to stabilize.

reg [14:0] rst_ctr;
assign rst = xreset | !(locked0&locked1);// | !locked;// | !rst_ctr[14];

always @(posedge xclk)
	if (xreset)
		rst_ctr <= 0;
	else if (!rst_ctr[14])
		rst_ctr <= rst_ctr + 1;


// 1000Hz pulse generator
reg [19:0] cnt;
wire pulse1000 = cnt==pClkFreq/1000;
assign pulse1000Hz = cnt>=pClkFreq/1000-10;

always @(posedge clk50)
if (rst)
	cnt <= 20'd1;
else begin
	if (pulse1000)
		cnt <= 20'd1;
	else
		cnt <= cnt + 20'd1;
end

reg [19:0] cnt2;
wire pulse100 = cnt2==pClkFreq/100;
assign pulse100Hz = cnt2>=pClkFreq/100-10;

always @(posedge clk50)
if (rst)
	cnt2 <= 20'd1;
else begin
	if (pulse100)
		cnt2 <= 20'd1;
	else
		cnt2 <= cnt2 + 20'd1;
end



// connect rst to global network
//	STARTUP_SPARTAN3 su0(.GSR(rst));

// Generate 85.7 MHz source from 100 MHz
DCM dcm0(
	.RST(xreset),
	.PSCLK(gnd),
	.PSEN(gnd),
	.PSINCDEC(gnd),
	.DSSEN(gnd),
	.CLKIN(xclk),
	.CLKFB(clk200u),	// 200.000 MHz
	.CLKDV(clk50u),
	.CLKFX(clk85u),		// 85.714 MHz unbuffered
	.CLKFX180(),
	.CLK0(clk100u),
	.CLK2X(clk200u),	// 200.xxx MHz
	.CLK2X180(),
	.CLK90(),
	.CLK180(),
	.CLK270(),
	.LOCKED(locked0),
	.PSDONE(),
	.STATUS()
);
defparam dcm0.CLK_FEEDBACK = "2x";
defparam dcm0.CLKDV_DIVIDE = 5.0;
defparam dcm0.CLKFX_DIVIDE = 7;	// (6/7)*100 = 85.7142 MHz
defparam dcm0.CLKFX_MULTIPLY = 6;
defparam dcm0.CLKIN_DIVIDE_BY_2 = "FALSE";
defparam dcm0.CLKIN_PERIOD = 10.000;
defparam dcm0.CLKOUT_PHASE_SHIFT = "NONE";
defparam dcm0.DESKEW_ADJUST = "SYSTEM_SYNCHRONOUS";
defparam dcm0.DFS_FREQUENCY_MODE = "LOW";
defparam dcm0.DLL_FREQUENCY_MODE = "LOW";
defparam dcm0.DUTY_CYCLE_CORRECTION = "FALSE";
//	defparam dcm0.FACTORY_JF = 16'h8080;
defparam dcm0.PHASE_SHIFT = 0;
defparam dcm0.STARTUP_WAIT = "FALSE";

PLL_BASE pll0
(
	.RST(xreset),
	.CLKIN(clk85u),
	.LOCKED(locked),
	.CLKOUT0(vclk10),	// 857.14
	.CLKOUT1(ivclk2),	// 171.4284
	.CLKOUT2(ivclk),
	.CLKOUT3(),	// 50
	.CLKOUT4(),	// 285.714
	.CLKOUT5(),
	.CLKFBIN(pllfb),
	.CLKFBOUT(pllfb)
);
defparam pll0.CLKIN_PERIOD = 11.667;
defparam pll0.CLK_FEEDBACK = "CLKFBOUT";
defparam pll0.CLKOUT0_PHASE = 0;
defparam pll0.CLKOUT0_DUTY_CYCLE = 0.5;
defparam pll0.CLKOUT0_DIVIDE = 1;
defparam pll0.CLKOUT1_PHASE = 0;
defparam pll0.CLKOUT1_DUTY_CYCLE = 0.5;
defparam pll0.CLKOUT1_DIVIDE = 5;
defparam pll0.CLKOUT2_PHASE = 0;
defparam pll0.CLKOUT2_DUTY_CYCLE = 0.5;
defparam pll0.CLKOUT2_DIVIDE = 10;
//defparam pll0.CLKOUT3_PHASE = 0;
//defparam pll0.CLKOUT3_DUTY_CYCLE = 0.5;
//defparam pll0.CLKOUT3_DIVIDE = 10;
//defparam pll0.CLKOUT4_PHASE = 0;
//defparam pll0.CLKOUT4_DUTY_CYCLE = 0.5;
//defparam pll0.CLKOUT4_DIVIDE = 3;
defparam pll0.CLKFBOUT_PHASE = 0;
defparam pll0.CLKFBOUT_MULT = 10;
defparam pll0.DIVCLK_DIVIDE = 1;

PLL_BASE pll1
(
	.RST(xreset),
	.CLKIN(clk50),
	.LOCKED(locked1),
	.CLKOUT0(clk125u),	// 125.0
	.CLKOUT1(),
	.CLKOUT2(),
	.CLKOUT3(),
	.CLKOUT4(),
	.CLKOUT5(),
	.CLKFBIN(pll1fb),
	.CLKFBOUT(pll1fb)
);
defparam pll1.CLKIN_PERIOD = 50;
defparam pll1.CLK_FEEDBACK = "CLKFBOUT";
defparam pll1.CLKOUT0_PHASE = 0;
defparam pll1.CLKOUT0_DUTY_CYCLE = 0.5;
defparam pll1.CLKOUT0_DIVIDE = 4;
//defparam pll1.CLKOUT1_PHASE = 0;
//defparam pll1.CLKOUT1_DUTY_CYCLE = 0.5;
//defparam pll1.CLKOUT1_DIVIDE = 5;
//defparam pll1.CLKOUT2_PHASE = 0;
//defparam pll1.CLKOUT2_DUTY_CYCLE = 0.5;
//defparam pll1.CLKOUT2_DIVIDE = 10;
//defparam pll1.CLKOUT3_PHASE = 0;
//defparam pll1.CLKOUT3_DUTY_CYCLE = 0.5;
//defparam pll1.CLKOUT3_DIVIDE = 10;
//defparam pll1.CLKOUT4_PHASE = 0;
//defparam pll1.CLKOUT4_DUTY_CYCLE = 0.5;
//defparam pll1.CLKOUT4_DIVIDE = 3;
defparam pll1.CLKFBOUT_PHASE = 0;
defparam pll1.CLKFBOUT_MULT = 25;
defparam pll1.DIVCLK_DIVIDE = 1;

endmodule
