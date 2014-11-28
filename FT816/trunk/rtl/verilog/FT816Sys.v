`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT816Sys.v
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

module FT816Sys(btn, xclk, Led, sw);
input [5:0] btn;
input xclk;
output [7:0] Led;
reg [7:0] Led;
input [7:0] sw;

wire xreset = ~btn[0];
wire irq = btn[1];
reg [32:0] rommem [2047:0];
reg [7:0] rammem [8191:0];
wire rw;
wire [23:0] ad;
tri [7:0] db;
wire cs0,cs1,cs4,cs6;

initial begin
`include "..\..\software\asm\test816.ver"
end

wire locked;
wire clk200u,clk85u,clk;
BUFG bg5 (.I(clk85u), .O(clk) );

DCM dcm0(
	.RST(xreset),
	.PSCLK(gnd),
	.PSEN(gnd),
	.PSINCDEC(gnd),
	.DSSEN(gnd),
	.CLKIN(xclk),
	.CLKFB(clk200u),	// 200.000 MHz
	.CLKDV(),
	.CLKFX(clk85u),		// 85.714 MHz unbuffered
	.CLKFX180(),
	.CLK0(),
	.CLK2X(clk200u),	// 200.xxx MHz
	.CLK2X180(),
	.CLK90(),
	.CLK180(),
	.CLK270(),
	.LOCKED(locked),
	.PSDONE(),
	.STATUS()
);
defparam dcm0.CLK_FEEDBACK = "2x";
defparam dcm0.CLKDV_DIVIDE = 5.0;
defparam dcm0.CLKFX_DIVIDE = 25;	// (16/25)*100 = 64 MHz
defparam dcm0.CLKFX_MULTIPLY = 16;
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
	.rst(~locked),
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
	.vda(),
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
