`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT816Sys2.v
//  - Top Module for 16 bit CPU
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
`define TRUE 	1'b1
`define FALSE	1'b0

module FT816Sys2(btn, xclk, Led, sw,
	HDMIOUTCLKP, HDMIOUTCLKN,
	HDMIOUTD0P,HDMIOUTD0N,
	HDMIOUTD1P,HDMIOUTD1N,
	HDMIOUTD2P,HDMIOUTD2N,
	HDMIOUTSCL,HDMIOUTSDA
);
input [5:0] btn;
input xclk;
output [7:0] Led;
reg [7:0] Led;
input [7:0] sw;
output HDMIOUTCLKP;
output HDMIOUTCLKN;
output HDMIOUTD0P;
output HDMIOUTD0N;
output HDMIOUTD1P;
output HDMIOUTD1N;
output HDMIOUTD2P;
output HDMIOUTD2N;
inout HDMIOUTSCL;
inout HDMIOUTSDA;
tri HDMIOUTSCL;
tri HDMIOUTSDA;

wire xreset = ~btn[0];
wire irq = btn[1];
reg [32:0] rommem [2047:0];
reg [7:0] rammem [8191:0];
wire rw;
wire vda;
wire [23:0] ad;
tri [7:0] db;
wire cs0,cs1,cs4,cs6;
wire rst;
wire vclk,vclk2,vclk10;
wire hsync,vsync,blank,border;
wire [24:0] tc_rgb;

wire [3:0] TMDS;
wire [3:0] TMDSB;
assign HDMIOUTCLKP = TMDS[3];
assign HDMIOUTCLKN = TMDSB[3];
assign HDMIOUTD0P = TMDS[0];
assign HDMIOUTD0N = TMDSB[0];
assign HDMIOUTD1P = TMDS[1];
assign HDMIOUTD1N = TMDSB[1];
assign HDMIOUTD2P = TMDS[2];
assign HDMIOUTD2N = TMDSB[2];
//assign HDMIOUTSCL = 1'b0;
//assign HDMIOUTSDA = 1'b0;


initial begin
`include "..\..\software\asm\test816.ver"
end

wire locked;
wire clk200u,clk85u,clk,sys_clk;

clkgen1366x768 u2
(
	.xreset(xreset),
	.xclk(xclk),
	.rst(rst),
	.clk100(),
	.clk25(),
	.clk200(),
	.clk125(),		// ETHERMAC clock
	.vclk(vclk),		// 85.7MHz
	.vclk2(vclk2),
	.vclk10(vclk10),
	.bmp_clk(),
	.sys_clk(sys_clk),
	.dram_clk(),
	.locked(locked),
	.pulse1000Hz(),
	.pulse100Hz()
);
assign clk = sys_clk;

dvi_out_native u3
(
	.reset(rst),
	.pll_lckd(locked),
	.clkin(vclk),                // pixel clock, from bufg
	.clkx2in(vclk2),             // pixel clock x2, from bufg
	.clkx10in(vclk10),           // pixel clock x10, unbuffered
	.blue_din(tc_rgb[7:0]),       // Blue data in
	.green_din(tc_rgb[15:8]),      // Green data in
	.red_din(tc_rgb[23:16]),        // Red data in
	.hsync(hsync),          // hsync data
	.vsync(vsync),          // vsync data
	.de(!blank),             // data enable
  
	.TMDS(TMDS),
	.TMDSB(TMDSB)
);

//VGASyncGen640x480_60Hz u4
WXGASyncGen1366x768_60Hz u4
(
	.rst(rst),
	.clk(vclk),
	.hSync(hsync),
	.vSync(vsync),
	.blank(blank),
	.border(border)
);

rtfTextController816 tc1
(
	.rst(rst),
	.clk(clk),
	.rw(rw),
	.vda(vda),
	.ad(ad),
	.db(db),
	.vclk(vclk),
	.hsync(hsync),
	.vsync(vsync),
	.blank(blank),
	.border(border),
	.rgbIn(25'h0),
	.rgbOut(tc_rgb)
);


always @(posedge clk)
if (~locked)
	Led <= 8'h00;
else begin
	if (~cs0 && ~rw && ad[7:0]==8'h00)
		Led <= db;
end

always @(posedge clk)
	if (~cs6 & ~rw)
		rammem[ad[12:0]] <= db;

reg [7:0] ro;
always @*
case(ad[1:0])
2'd0:	ro <= rommem[ad[12:2]][7:0];
2'd1:	ro <= rommem[ad[12:2]][15:8];
2'd2:	ro <= rommem[ad[12:2]][23:16];
2'd3:	ro <= rommem[ad[12:2]][31:24];
endcase

assign db = rw & ~cs1 ? sw : {8{1'bz}};
assign db = rw & ~cs4 ? ro : {8{1'bz}};
assign db = rw & ~cs6 ? rammem[ad[12:0]] : {8{1'bz}};

FT816mpu u1
(
	.rst(rst),
	.clk(clk),
	.phi11(),
	.phi12(),
	.phi81(),
	.phi82(),
	.rdy(1'b1),
	.e(),
	.mx(),
	.nmi(1'b0),
	.irq(btn[1]),
	.be(1'b1),
	.vpa(),
	.vda(vda),
	.mlb(),
	.vpb(),
	.rw(rw),
	.ad(ad),
	.db(db),
	.cs0(cs0),
	.cs1(cs1),
	.cs2(),
	.cs3(),
	.cs4(cs4),
	.cs5(),
	.cs6(cs6)
);

endmodule
