//=============================================================================
//	2012-2016 Robert T Finch
//	robfinch@finitron.ca
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

module clkgen1366x768_Nexys4ddr(xreset, xclk, rst, clk100, clk25, clk200, clk300, clk125,
  vclk, bmp_clk, ub_sys_clk, sys_clk, sys_clk2x, dram_clk, locked, pulse1024Hz, pulse30Hz);
parameter pClkFreq=20000000;
parameter SYSCLKDIV = 48;
input xreset;		// external reset
input xclk;			// external clock source (100 MHz)
output rst;
output clk100;		// cpu (system clock - eg. 100.000 MHz)
output clk25;
output clk200;
output clk300;
output clk125;		// 125 MHz
output vclk;		// video clock  (85.7Mhz)
output bmp_clk;
output ub_sys_clk;
output sys_clk;		// system clock (50 MHz)
output sys_clk2x; //
output dram_clk;	// DDR2 ram clock (286 MHz)
output locked;
output pulse1024Hz;	// 1000 Hz pulse
output pulse30Hz;

wire gnd;
wire clk200u;
wire clk300u;
wire clk2x;
wire clk25u;
wire clk100u;		// unbuffered 50MHz
wire clk85u;		// unbuffered 85MHz
wire clk125u;
wire clkvu;
wire locked0,locked1;
wire pllfb;
wire ivclk;
wire isys_clk;
wire isys_clk2x;
wire idram_clk;
wire clk125b;

assign gnd = 1'b0;
assign locked1 = 1'b1;

BUFG bg0 (.I(clk100u), 	.O(clk100) );
//BUFG bg1 (.I(clk73u), 	.O(vclk) );
BUFG bg2 (.I(clk25u), 	.O(clk25) );
BUFG bg3 (.I(clk200u),  .O(clk200) );
BUFG bg4 (.I(clk300u),  .O(clk300) );
BUFG bg1 (.I(clk85u), .O(vclk) );
BUFG bg5 (.I(isys_clk), .O(sys_clk) );
BUFG bg6 (.I(clk200u), .O(dram_clk) );
BUFG bg7 (.I(clk125u), .O(clk125b) );
BUFG bg8 (.I(ibmp_clk), .O(bmp_clk) );
BUFG bg9 (.I(isys_clk2x), .O(sys_clk2x) );
assign ub_sys_clk = isys_clk;

//BUFG bg5 (.I(ivclk10), .O(vclk10) );
/*
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
*/

// Reset:
//
// Hold the reset line active for a few thousand clock cycles
// to allow the clock generator and other devices to stabilize.

reg [14:0] rst_ctr;
assign rst = xreset | !(locked0&locked1);// | !locked;// | !rst_ctr[14];
assign locked = locked0&locked1;

always @(posedge xclk)
	if (xreset)
		rst_ctr <= 0;
	else if (!rst_ctr[14])
		rst_ctr <= rst_ctr + 1;


// 1000Hz pulse generator
reg [19:0] cnt;
wire pulse1024 = cnt==pClkFreq/1024;
assign pulse1024Hz = cnt>=pClkFreq/1024-10;

always @(posedge sys_clk)
if (rst)
	cnt <= 20'd1;
else begin
	if (pulse1024)
		cnt <= 20'd1;
	else
		cnt <= cnt + 20'd1;
end

reg [31:0] cnt2;
wire pulse30 = cnt2==pClkFreq/30;
assign pulse30Hz = cnt2>=pClkFreq/30-10;

always @(posedge sys_clk)
if (rst)
	cnt2 <= 32'd1;
else begin
	if (pulse30)
		cnt2 <= 32'd1;
	else
		cnt2 <= cnt2 + 32'd1;
end


wire clkfb,clkfbo;
BUFG clkbufg (.I(clkfbo), .O(clkfb));

PLLE2_BASE u1
(
    .RST(xreset),
    .CLKIN1(xclk),
    .CLKFBIN(clkfb),
    .CLKFBOUT(clkfbo),
    .LOCKED(locked0),
    .CLKOUT0(clk85u),
    .CLKOUT1(isys_clk), // 25 MHz
    .CLKOUT2(clk200u),
    .CLKOUT3(clk300u),
    .CLKOUT4(clk100u),
    .CLKOUT5(isys_clk2x)
);
defparam u1.CLKFBOUT_MULT = 12;     // must place VCO frequency 800-1600 MHz (1200)
defparam u1.CLKOUT0_DIVIDE = 14;
defparam u1.CLKOUT1_DIVIDE = SYSCLKDIV;
defparam u1.CLKOUT2_DIVIDE = 6;
defparam u1.CLKOUT3_DIVIDE = 4;
defparam u1.CLKOUT4_DIVIDE = 12;
defparam u1.CLKOUT5_DIVIDE = SYSCLKDIV/2;
//defparam u1.CLKOUT5_PHASE = 180.0;

// connect rst to global network
//	STARTUP_SPARTAN3 su0(.GSR(rst));

// Generate 85.7 MHz source from 100 MHz
/*
DCM dcm0(
	.RST(xreset),
	.PSCLK(gnd),
	.PSEN(gnd),
	.PSINCDEC(gnd),
	.DSSEN(gnd),
	.CLKIN(xclk),
	.CLKFB(clk200u),	// 200.000 MHz
	.CLKDV(isys_clk),
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
defparam dcm0.CLKDV_DIVIDE = 1.5;
defparam dcm0.CLKFX_DIVIDE = 7;	// (12/7)*50 = 85.7142 MHz
defparam dcm0.CLKFX_MULTIPLY = 6;
defparam dcm0.CLKIN_DIVIDE_BY_2 = "FALSE";
defparam dcm0.CLKIN_PERIOD = 20.000;
defparam dcm0.CLKOUT_PHASE_SHIFT = "NONE";
defparam dcm0.DESKEW_ADJUST = "SYSTEM_SYNCHRONOUS";
defparam dcm0.DFS_FREQUENCY_MODE = "LOW";
defparam dcm0.DLL_FREQUENCY_MODE = "LOW";
defparam dcm0.DUTY_CYCLE_CORRECTION = "FALSE";
//	defparam dcm0.FACTORY_JF = 16'h8080;
defparam dcm0.PHASE_SHIFT = 0;
defparam dcm0.STARTUP_WAIT = "FALSE";
*/
/*
wire clk200ub;
// Generate 85.7 MHz source from 100 MHz
DCM dcm1(
	.RST(xreset),
	.PSCLK(gnd),
	.PSEN(gnd),
	.PSINCDEC(gnd),
	.DSSEN(gnd),
	.CLKIN(xclk),
	.CLKFB(clk200ub),	// 200.000 MHz
	.CLKDV(),
	.CLKFX(isys_clk),	// 85.714 MHz unbuffered
	.CLKFX180(),
	.CLK0(),
	.CLK2X(clk200ub),	// 200.xxx MHz
	.CLK2X180(),
	.CLK90(),
	.CLK180(),
	.CLK270(),
	.LOCKED(locked1),
	.PSDONE(),
	.STATUS()
);
defparam dcm1.CLK_FEEDBACK = "2x";
defparam dcm1.CLKDV_DIVIDE = 2.0;
defparam dcm1.CLKFX_DIVIDE = 30;	// (6/15)*50 = 20.00 MHz
defparam dcm1.CLKFX_MULTIPLY = 6;
defparam dcm1.CLKIN_DIVIDE_BY_2 = "FALSE";
defparam dcm1.CLKIN_PERIOD = 20.000;
defparam dcm1.CLKOUT_PHASE_SHIFT = "NONE";
defparam dcm1.DESKEW_ADJUST = "SYSTEM_SYNCHRONOUS";
defparam dcm1.DFS_FREQUENCY_MODE = "LOW";
defparam dcm1.DLL_FREQUENCY_MODE = "LOW";
defparam dcm1.DUTY_CYCLE_CORRECTION = "FALSE";
//	defparam dcm0.FACTORY_JF = 16'h8080;
defparam dcm1.PHASE_SHIFT = 0;
defparam dcm1.STARTUP_WAIT = "FALSE";
*/
endmodule
