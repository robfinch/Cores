`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	frisc_soc.v
//  - system on a chip
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
// ============================================================================
//
`define CLK_FREQ  25000000

module friscv_soc(cpu_resetn, btnl, btnr, btnc, btnd, btnu, xclk, led, sw, an, ssg, 
  red, green, blue, hSync, vSync, UartTx, UartRx);
input cpu_resetn;
input btnl;
input btnr;
input btnc;
input btnd;
input btnu;
input xclk;
output [3:0] red;
output [3:0] green;
output [3:0] blue;
output hSync;
output vSync;
output UartTx;
input UartRx;
input [15:0] sw;
output [7:0] an;
output [7:0] ssg;
output [15:0] led;
reg [15:0] led;

wire xreset = ~cpu_resetn;
wire rst;
wire cyc;
wire stb;
wire we;
wire [3:0] sel;
wire [31:0] adr;
wire [31:0] dato;
wire [31:0] dati;
wire [127:0] net1,net2,net3,net4,net5,net14;
wire tc_ack,ack;
wire [31:0] tc1_dato;
wire [23:0] tc1_out;
assign red = tc1_out[23:20];
assign green = tc1_out[15:12];
assign blue = tc1_out[7:4];

wire [7:0] uart_dato;
wire uart_ack;
wire uart_irq;
wire clk100, clk200, clk300;
wire clk, clk2x;
wire vclk;
wire locked;
wire pulse1024Hz, pulse30Hz;

clkgen1366x768_Nexys4ddr #(.pClkFreq(`CLK_FREQ)) ucg1
(
	.xreset(xreset),
	.xclk(xclk),
	.rst(rst),
	.clk100(clk100),
	.clk25(),
//	.clk125(eth_gtxclk),
	.clk200(clk200),
	.clk300(clk300),
	.vclk(vclk),
	.sys_clk(clk),
	.sys_clk2x(clk2x),
//	.dram_clk(dram_clk),
	.locked(locked),
	.pulse1024Hz(pulse1024Hz),
	.pulse30Hz(pulse30Hz)
);

//VGASyncGen640x480_60Hz u4
WXGASyncGen1366x768_60Hz usg1
(
	.rst(rst),
	.clk(vclk),
	.hSync(hSync),
	.vSync(vSync),
	.blank(blank),
	.border(border)
);

rtfTextController3 #(.num(1), .pTextAddress(32'hFFD00000))  tc1
(
	.rst_i(rst),
	.clk_i(clk),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(tc_ack),
	.we_i(we),
	.adr_i(adr),
	.dat_i(dato),
	.dat_o(tcdato),
	.lp(),
	.curpos(),
	.vclk(vclk),
	.hsync(hSync),
	.vsync(vSync),
	.blank(blank),
	.border(border),
	.rgbIn(),
	.rgbOut(tc1_out)
);

rtfSimpleUart uuart1
(
	// WISHBONE Slave interface
	.rst_i(rst),		    // reset
	.clk_i(clk),	    // eg 100.7MHz
	.cyc_i(cyc),		// cycle valid
	.stb_i(stb),		// strobe
	.we_i(we),			// 1 = write
	.adr_i(adr),		// register address
	.dat_i(dato[7:0]),	// data input bus
	.dat_o(uart_dato),	    // data output bus
	.ack_o(uart_ack),		// transfer acknowledge
	.vol_o(),		        // volatile register selected
  .irq_o(uart_irq),		// interrupt request
	//----------------
	.cts_ni(1'b0),		// clear to send - active low - (flow control)
	.rts_no(),	// request to send - active low - (flow control)
	.dsr_ni(1'b0),		// data set ready - active low
	.dcd_ni(1'b0),		// data carrier detect - active low
	.dtr_no(),	// data terminal ready - active low
	.rxd_i(UartRx),			// serial data in
	.txd_o(UartTx),			// serial data out
  .data_present_o(),
  .baud16_clk()
);

reg [31:0] addb, ssdat;
always @(posedge clk)
    addb <= btnr ? dato : btnl ? adr : ssdat;

wire sseg_ack = cyc && stb && we && adr[31:4]==28'hFFDC008;
always @(posedge clk)
    if (sseg_ack)
        ssdat <= dato;

// Seven segment LED driver
seven_seg8 ssd0
(
	.rst(rst),
	.clk(clk),
	.dp({UartTx,UartRx,6'b000100}),
	.val(addb),
	.ssLedAnode(an),
	.ssLedSeg(ssg)
);

wire cs_leds = cyc && stb && (adr[31:8]==24'hFFDC06);
wire leds_ack = cs_leds;
always @(posedge clk)
if (rst)
    led <= 16'h0000;
else begin
	if (cs_leds && we)
		led[15:0] <= dato;
//    led[15] <= irq;
    led[14] <= pulse1024Hz;
    led[13] <= pulse30Hz;
end

assign ack = tc_ack|sseg_ack|leds_ack|uart_ack;
assign dati = tcdato|{4{uart_dato}};

friscv_node um1 (1, rst, clk, net14, net1);
friscv_node um2 (2, rst, clk, net1, net2);
friscv_node um3 (3, rst, clk, net2, net3);
friscv_node um4 (4, rst, clk, net3, net4);
friscv_node um5 (5, rst, clk, net4, net5);
soci ugdi1 (14, rst, clk, net5, net14, cyc, stb, ack, we, sel, adr, dati, dato);

endmodule
