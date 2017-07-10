// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
//	Verilog 1995
//
//	System clock generator. Generates clock enables for various parts of the
//	system.
// ============================================================================
//
module clkgen(xreset, xclk, rst, clk100, clk57, clk200, clk300, clk400, clk125, clk80, ub_sys_clk, sys_clk, locked, pulse1000Hz, pulse100Hz);
parameter pClkFreq=57142857;
input xreset;		// external reset
input xclk;			// external clock source (100 MHz)
output rst;
output clk100;		// cpu (system clock - eg. 100.000 MHz)
output clk57;
output clk200;
output clk300;
output clk400;
output clk125;		// 125 MHz
output clk80;		// video clock  (85.7Mhz)
output ub_sys_clk;
output sys_clk;		// system clock (50 MHz)
output locked;
output pulse1000Hz;	// 1000 Hz pulse
output pulse100Hz;

wire gnd;
wire clk200u;
wire clk300u;
wire clk400u;
wire clk1200u;
wire clk25u;
wire clk100u;		// unbuffered 50MHz
wire clk80u;		// unbuffered 85MHz
wire clk125u;
wire locked0,locked1;
wire isys_clk;

assign gnd = 1'b0;
assign locked1 = 1'b1;

BUFG bg0 (.I(clk100u), 	.O(clk100) );
//BUFG bg1 (.I(clk73u), 	.O(vclk) );
BUFG bg2 (.I(clk57u), 	.O(clk57) );
BUFG bg3 (.I(clk200u),  .O(clk200) );
BUFG bg4 (.I(clk300u),  .O(clk300) );
BUFG bg8 (.I(clk400u),  .O(clk400) );
BUFG bg1 (.I(clk80u), .O(clk80) );
BUFG bg5 (.I(isys_clk), .O(sys_clk) );
BUFG bg7 (.I(clk125u), .O(clk125b) );
assign ub_sys_clk = isys_clk;

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
wire pulse1000 = cnt==200000;
assign pulse1000Hz = cnt>=200000-10;

always @(posedge clk200)
if (rst)
	cnt <= 20'd1;
else begin
	if (pulse1000)
		cnt <= 20'd1;
	else
		cnt <= cnt + 20'd1;
end

reg [31:0] cnt2;
wire pulse100 = cnt2==3333333;
assign pulse100Hz = cnt2>=3333333-10;

always @(posedge clk200)
if (rst)
	cnt2 <= 32'd1;
else begin
	if (pulse100)
		cnt2 <= 32'd1;
	else
		cnt2 <= cnt2 + 32'd1;
end


wire clkfb,clkfbo;
BUFG clkbufg (.I(clkfbo), .O(clk1200));

PLLE2_BASE u1
(
    .RST(xreset),
    .CLKIN1(xclk),
    .CLKFBIN(clk1200),
    .CLKFBOUT(clkfbo),
    .LOCKED(locked0),
    .CLKOUT0(clk400u),
    .CLKOUT1(isys_clk), // 66 MHz
    .CLKOUT2(clk200u),
    .CLKOUT3(clk57u),
    .CLKOUT4(clk80u),
    .CLKOUT5(clk100u)
);
defparam u1.CLKFBOUT_MULT = 12;     // must place VCO frequency 800-1600 MHz (1200)
defparam u1.CLKOUT0_DIVIDE = 3.0;
defparam u1.CLKOUT1_DIVIDE = 21;
defparam u1.CLKOUT2_DIVIDE = 6;
defparam u1.CLKOUT3_DIVIDE = 21;
defparam u1.CLKOUT4_DIVIDE = 15;
defparam u1.CLKOUT5_DIVIDE = 12;
defparam u1.CLKIN1_PERIOD = 10.000;

endmodule
