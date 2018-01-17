`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// Register file with three write ports and twelve read ports.
// 85,000 LUTs, 270 Block rams, 1hr :10 min to synthesize
// ============================================================================
//
module regfileRam(wclk, wr, wa, i, rclk,
	ra0, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10, ra11,
	o0, o1, o2, o3, o4, o5, o6, o7, o8, o9, o10, o11);
parameter WID = 64;
parameter RBIT = 11;
input wclk;
input wr;
input [RBIT:0] wa;
input [WID-1:0] i;
input rclk;
input [RBIT:0] ra0;
input [RBIT:0] ra1;
input [RBIT:0] ra2;
input [RBIT:0] ra3;
input [RBIT:0] ra4;
input [RBIT:0] ra5;
input [RBIT:0] ra6;
input [RBIT:0] ra7;
input [RBIT:0] ra8;
input [RBIT:0] ra9;
input [RBIT:0] ra10;
input [RBIT:0] ra11;
output [WID-1:0] o0;
output [WID-1:0] o1;
output [WID-1:0] o2;
output [WID-1:0] o3;
output [WID-1:0] o4;
output [WID-1:0] o5;
output [WID-1:0] o6;
output [WID-1:0] o7;
output [WID-1:0] o8;
output [WID-1:0] o9;
output [WID-1:0] o10;
output [WID-1:0] o11;

(* RAM_STYLE="BLOCK" *)
reg [WID-1:0] mem [0:RBIT==11 ? 4095:RBIT==10 ? 2047:RBIT==9 ? 1023:RBIT==7 ? 255 : 63];
reg [RBIT:0] rra0, rra1, rra2, rra3, rra4, rra5, rra6, rra7, rra8, rra9, rra10, rra11;

`ifdef SIMULATION
integer n;
initial begin
    for (n = 0; n < ((RBIT==11) ? 4095 : (RBIT==10) ? 2047 : (RBIT==9) ? 1024: 256); n = n + 1)
    begin
        mem[n] = 0;
    end
end
`endif

always @(posedge wclk)
	if (wr)
		mem[wa] <= i;
always @(posedge wclk)	rra0 <= ra0;
always @(posedge wclk)	rra1 <= ra1;
always @(posedge wclk)	rra2 <= ra2;
always @(posedge wclk)	rra3 <= ra3;
always @(posedge wclk)	rra4 <= ra4;
always @(posedge wclk)	rra5 <= ra5;
always @(posedge wclk)	rra6 <= ra6;
always @(posedge wclk)	rra7 <= ra7;
always @(posedge wclk)	rra8 <= ra8;
always @(posedge wclk)	rra9 <= ra9;
always @(posedge wclk)	rra10 <= ra10;
always @(posedge wclk)	rra11 <= ra11;

assign o0 = mem[rra0];
assign o1 = mem[rra1];
assign o2 = mem[rra2];
assign o3 = mem[rra3];
assign o4 = mem[rra4];
assign o5 = mem[rra5];
assign o6 = mem[rra6];
assign o7 = mem[rra7];
assign o8 = mem[rra8];
assign o9 = mem[rra9];
assign o10 = mem[rra10];
assign o11 = mem[rra11];

endmodule

module FT64_regfile3w12r(clk, wr0, wr1, wr2, wa0, wa1, wa2, i0, i1, i2,
	rclk,
	ra0, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10, ra11,
	o0, o1, o2, o3, o4, o5, o6, o7, o8, o9, o10, o11);
parameter WID=64;
parameter RBIT = 11;
input clk;
input wr0;
input wr1;
input wr2;
input [RBIT:0] wa0;
input [RBIT:0] wa1;
input [RBIT:0] wa2;
input [WID-1:0] i0;
input [WID-1:0] i1;
input [WID-1:0] i2;
input rclk;
input [RBIT:0] ra0;
input [RBIT:0] ra1;
input [RBIT:0] ra2;
input [RBIT:0] ra3;
input [RBIT:0] ra4;
input [RBIT:0] ra5;
input [RBIT:0] ra6;
input [RBIT:0] ra7;
input [RBIT:0] ra8;
input [RBIT:0] ra9;
input [RBIT:0] ra10;
input [RBIT:0] ra11;
output [WID-1:0] o0;
output [WID-1:0] o1;
output [WID-1:0] o2;
output [WID-1:0] o3;
output [WID-1:0] o4;
output [WID-1:0] o5;
output [WID-1:0] o6;
output [WID-1:0] o7;
output [WID-1:0] o8;
output [WID-1:0] o9;
output [WID-1:0] o10;
output [WID-1:0] o11;

wire [WID-1:0] o00, o01, o02, o03, o04, o05, o06, o07, o08, o09, o010, o011;
wire [WID-1:0] o10, o11, o12, o13, o14, o15, o16, o17, o18, o19, o110, o111;
wire [WID-1:0] o20, o21, o22, o23, o24, o25, o26, o27, o28, o29, o210, o211;

regfileRam #(WID,RBIT) u1 (clk, wr0, wa0, i0, rclk, ra0, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10, ra11, o00, o01, o02, o03, o04, o05, o06, o07, o08, o09, o010, o011);
regfileRam #(WID,RBIT) u2 (clk, wr1, wa1, i1, rclk, ra0, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10, ra11, o10, o11, o12, o13, o14, o15, o16, o17, o18, o19, o110, o111);
regfileRam #(WID,RBIT) u3 (clk, wr2, wa2, i2, rclk, ra0, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10, ra11, o20, o21, o22, o23, o24, o25, o26, o27, o28, o29, o210, o211);

reg [1:0] whichreg [0:RBIT==11 ? 4095:RBIT==10 ? 2047:RBIT==9 ? 1023 :255];	// tracks which register file is the valid one for a given register

// We only care about what's in the regs to begin with in simulation. In sim
// the 'x' values propagate screwing things up. In real hardware there's no such
// thing as an 'x'.
`define SIMULATION
`ifdef SIMULATION
integer n;
initial begin
    for (n = 0; n < ((RBIT==11) ? 4095 : (RBIT==10) ? 2047 : (RBIT==9) ? 1024: 256); n = n + 1)
    begin
        whichreg[n] = 0;
    end
end
`endif


assign o0 = ra0[RBIT:0]==8'd0 ? {WID{1'b0}} :
	(wr2 && (ra0==wa2)) ? i2 :
	(wr1 && (ra0==wa1)) ? i1 :
	(wr0 && (ra0==wa0)) ? i0 :
	whichreg[ra0]==2'b00 ? o00 : whichreg[ra0]==2'b01 ? o10 : o20;
assign o1 = ra1[RBIT:0]==8'd0 ? {WID{1'b0}} :
	(wr2 && (ra1==wa2)) ? i2 :
	(wr1 && (ra1==wa1)) ? i1 :
	(wr0 && (ra1==wa0)) ? i0 :
	whichreg[ra1]==2'b00 ? o01 : whichreg[ra1]==2'b01 ? o11 : o21;
assign o2 = ra2[RBIT:0]==8'd0 ? {WID{1'b0}} :
	(wr2 && (ra2==wa2)) ? i2 :
	(wr1 && (ra2==wa1)) ? i1 :
	(wr0 && (ra2==wa0)) ? i0 :
	whichreg[ra2]==2'b00 ? o02 : whichreg[ra2]==2'b01 ? o12 : o22;
assign o3 = ra3[RBIT:0]==8'd0 ? {WID{1'b0}} :
	(wr2 && (ra3==wa2)) ? i2 :
	(wr1 && (ra3==wa1)) ? i1 :
	(wr0 && (ra3==wa0)) ? i0 :
	whichreg[ra3]==2'b00 ? o03 : whichreg[ra3]==2'b01 ? o13 : o23;
assign o4 = ra4[RBIT:0]==8'd0 ? {WID{1'b0}} :
	(wr2 && (ra4==wa2)) ? i2 :
    (wr1 && (ra4==wa1)) ? i1 :
    (wr0 && (ra4==wa0)) ? i0 :
	whichreg[ra4]==2'b00 ? o04 : whichreg[ra4]==2'b01 ? o14 : o24;
assign o5 = ra5[RBIT:0]==8'd0 ? {WID{1'b0}} :
	(wr2 && (ra5==wa2)) ? i2 :
    (wr1 && (ra5==wa1)) ? i1 :
    (wr0 && (ra5==wa0)) ? i0 :
	whichreg[ra5]==2'b00 ? o05 : whichreg[ra5]==2'b01 ? o15 : o25;
assign o6 = ra6[RBIT:0]==8'd0 ? {WID{1'b0}} :
	(wr2 && (ra6==wa2)) ? i2 :
    (wr1 && (ra6==wa1)) ? i1 :
    (wr0 && (ra6==wa0)) ? i0 :
	whichreg[ra6]==2'b00 ? o06 : whichreg[ra6]==2'b01 ? o16 : o26;
assign o7 = ra7[RBIT:0]==8'd0 ? {WID{1'b0}} :
	(wr2 && (ra7==wa2)) ? i2 :
    (wr1 && (ra7==wa1)) ? i1 :
    (wr0 && (ra7==wa0)) ? i0 :
	whichreg[ra7]==2'b00 ? o07 : whichreg[ra7]==2'b01 ? o17 : o27;
assign o8 = ra8[RBIT:0]==8'd0 ? {WID{1'b0}} :
	(wr2 && (ra8==wa2)) ? i2 :
    (wr1 && (ra8==wa1)) ? i1 :
    (wr0 && (ra8==wa0)) ? i0 :
	whichreg[ra8]==2'b00 ? o08 : whichreg[ra8]==2'b01 ? o18 : o28;
assign o9 = ra9[RBIT:0]==8'd0 ? {WID{1'b0}} :
	(wr2 && (ra9==wa2)) ? i2 :
    (wr1 && (ra9==wa1)) ? i1 :
    (wr0 && (ra9==wa0)) ? i0 :
	whichreg[ra9]==2'b00 ? o09 : whichreg[ra9]==2'b01 ? o19 : o29;
assign o10 = ra10[RBIT:0]==8'd0 ? {WID{1'b0}} :
	(wr2 && (ra10==wa2)) ? i2 :
    (wr1 && (ra10==wa1)) ? i1 :
    (wr0 && (ra10==wa0)) ? i0 :
	whichreg[ra10]==2'b00 ? o010 : whichreg[ra10]==2'b01 ? o110 : o210;
assign o11 = ra11[RBIT:0]==8'd0 ? {WID{1'b0}} :
	(wr2 && (ra11==wa2)) ? i2 :
    (wr1 && (ra11==wa1)) ? i1 :
    (wr0 && (ra11==wa0)) ? i0 :
	whichreg[ra11]==2'b00 ? o011 : whichreg[ra11]==2'b01 ? o111 : o211;

always @(posedge clk)
	// writing three registers at once
	if (wr0 && wr1 && wr2) begin
		if (wa0==wa1 && wa0==wa2)
			whichreg[wa0] <= 2'b10;	// port wa2 wins
		else if (wa0==wa1) begin
			whichreg[wa0] <= 2'b01;	// port wa1 wins
			whichreg[wa2] <= 2'b10;
		end
		else if (wa1==wa2) begin
			whichreg[wa1] <= 2'b10;	// port wa2 wins
			whichreg[wa0] <= 2'b00;
		end
		// All three ports different
		else begin
			whichreg[wa0] <= 2'b00;
			whichreg[wa1] <= 2'b01;
			whichreg[wa2] <= 2'b10;
		end
	end
	// writing two ports at the same time
	else if (wr0 && wr2) begin
		if (wr0==wr2)
			whichreg[wa0] <= 2'b10;
		else begin
			whichreg[wa0] <= 2'b00;
			whichreg[wa2] <= 2'b10;
		end
	end
	else if (wr1 && wr2) begin
		if (wr1==wr2)
			whichreg[wa1] <= 2'b10;
		else begin
			whichreg[wa1] <= 2'b01;
			whichreg[wa2] <= 2'b10;
		end
	end
	// writing one port
	else if (wr0)
		whichreg[wa0] <= 2'b00;
	else if (wr1)
		whichreg[wa1] <= 2'b01;
	else if (wr2)
		whichreg[wa2] <= 2'b10;

endmodule

