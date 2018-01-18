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
// Register file with two write ports and six read ports.
// ============================================================================
//
`define SIM

module FT64_regfileRam_sim(clka, ena, wea, addra, dina, clkb, enb, addrb, doutb);
parameter WID=64;
parameter RBIT = 11;
input clka;
input ena;
input [7:0] wea;
input [RBIT:0] addra;
input [WID-1:0] dina;
input clkb;
input enb;
input [RBIT:0] addrb;
output [WID-1:0] doutb;

integer n;
(* RAM_STYLE="BLOCK" *)
reg [63:0] mem [0:4095];
reg [RBIT:0] raddrb;

initial begin
	for (n = 0; n < 4096; n = n + 1)
		mem[n] = 0;
end

always @(posedge clka) if (ena & wea[0]) mem[addra][7:0] <= #1 dina[7:0];
always @(posedge clka) if (ena & wea[1]) mem[addra][15:8] <= #1 dina[15:8];
always @(posedge clka) if (ena & wea[2]) mem[addra][23:16] <= #1 dina[23:16];
always @(posedge clka) if (ena & wea[3]) mem[addra][31:24] <= #1 dina[31:24];
always @(posedge clka) if (ena & wea[4]) mem[addra][39:32] <= #1 dina[39:32];
always @(posedge clka) if (ena & wea[5]) mem[addra][47:40] <= #1 dina[47:40];
always @(posedge clka) if (ena & wea[6]) mem[addra][55:48] <= #1 dina[55:48];
always @(posedge clka) if (ena & wea[7]) mem[addra][63:56] <= #1 dina[63:56];

always @(posedge clkb)
	raddrb <= #1 addrb;
assign doutb = mem[raddrb];
	
endmodule

module FT64x4_regfile3w12r_oc(clk4x, clk, wr0, wr1, wr2, we0, we1, we2, wa0, wa1, wa2, i0, i1, i2,
	rclk, ra0, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10, ra11,
	o0, o1, o2, o3, o4, o5, o6, o7, o8, o9, o10, o11);
parameter WID=64;
parameter RBIT = 11;
input clk4x;
input clk;
input wr0;
input wr1;
input wr2;
input [7:0] we0;
input [7:0] we1;
input [7:0] we2;
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

reg wr;
reg [RBIT:0] wa;
reg [WID-1:0] i;
reg [7:0] we;
wire [WID-1:0] o00, o01, o02, o03, o04, o05, o06, o07, o08, o09, o010, o011;
reg wr1x;
reg [RBIT:0] wa1x;
reg [WID-1:0] i1x;
reg [7:0] we1x;
reg wr2x;
reg [RBIT:0] wa2x;
reg [WID-1:0] i2x;
reg [7:0] we2x;

`ifdef SIM
FT64_regfileRam_sim urf10 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra0),
  .doutb(o00)
);

FT64_regfileRam_sim urf11 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra1),
  .doutb(o01)
);

FT64_regfileRam_sim urf12 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra2),
  .doutb(o02)
);

FT64_regfileRam_sim urf13 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra3),
  .doutb(o03)
);

FT64_regfileRam_sim urf14 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra4),
  .doutb(o04)
);

FT64_regfileRam_sim urf15 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra5),
  .doutb(o05)
);

FT64_regfileRam_sim urf16 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra6),
  .doutb(o06)
);

FT64_regfileRam_sim urf17 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra7),
  .doutb(o07)
);

FT64_regfileRam_sim urf18 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra8),
  .doutb(o08)
);

FT64_regfileRam_sim urf19 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra9),
  .doutb(o09)
);

FT64_regfileRam_sim urf110 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra10),
  .doutb(o010)
);

FT64_regfileRam_sim urf111 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra11),
  .doutb(o011)
);
`else
FT64_regfileRam urf10 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra0),
  .doutb(o00)
);

FT64_regfileRam urf11 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra1),
  .doutb(o01)
);

FT64_regfileRam urf12 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra2),
  .doutb(o02)
);

FT64_regfileRam urf13 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra3),
  .doutb(o03)
);

FT64_regfileRam urf14 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra4),
  .doutb(o04)
);

FT64_regfileRam urf15 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra5),
  .doutb(o05)
);

FT64_regfileRam urf16 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra6),
  .doutb(o06)
);

FT64_regfileRam urf17 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra7),
  .doutb(o07)
);

FT64_regfileRam urf18 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra8),
  .doutb(o08)
);

FT64_regfileRam urf19 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra9),
  .doutb(o09)
);

FT64_regfileRam urf110 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra10),
  .doutb(o010)
);

FT64_regfileRam urf111 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra11),
  .doutb(o011)
);
`endif

// The same clock edge that would normally update the register file is the
// clock edge that causes the data to disappear for the next cycle. The
// data needs to be held onto so that it can update the register file on
// the next 4x clock.
always @(posedge clk)
begin
	wr1x <= wr1;
	we1x <= we1;
	wa1x <= wa1;
	i1x <= i1;
end
always @(posedge clk)
begin
	wr2x <= wr2;
	we2x <= we2;
	wa2x <= wa2;
	i2x <= i2;
end


reg wclk2;
always @(posedge clk4x)
	wclk2 <= #1 clk;
always @(posedge clk4x)
	if (clk & ~wclk2) begin
		wr <= wr0;
		we <= we0;
		wa <= wa0;
		i <= i0;
	end
	else if (clk & wclk2) begin
		wr <= wr1x;
		we <= we1x;
		wa <= wa1x;
		i <= i1x;
	end
	else if (~clk & wclk2) begin
		wr <= wr2x;
		we <= we2x;
		wa <= wa2x;
		i <= i2x;
	end
	else begin
		wr <= 1'b0;
		we <= 8'h00;
		wa <= 'd0;
		i <= 'd0;
	end

assign o0 = ra0[4:0]==5'd0 ? {WID{1'b0}} :
	(wr2 && (ra0==wa2)) ? i2 :
	(wr1 && (ra0==wa1)) ? i1 :
	(wr0 && (ra0==wa0)) ? i0 : o00;
assign o1 = ra1[4:0]==5'd0 ? {WID{1'b0}} :
	(wr2 && (ra1==wa2)) ? i2 :
	(wr1 && (ra1==wa1)) ? i1 :
	(wr0 && (ra1==wa0)) ? i0 : o01;
assign o2 = ra2[4:0]==5'd0 ? {WID{1'b0}} :
	(wr2 && (ra2==wa2)) ? i2 :
	(wr1 && (ra2==wa1)) ? i1 :
	(wr0 && (ra2==wa0)) ? i0 : o02;
assign o3 = ra3[4:0]==5'd0 ? {WID{1'b0}} :
	(wr2 && (ra3==wa2)) ? i2 :
	(wr1 && (ra3==wa1)) ? i1 :
	(wr0 && (ra3==wa0)) ? i0 : o03;
assign o4 = ra4[4:0]==5'd0 ? {WID{1'b0}} :
    (wr2 && (ra4==wa2)) ? i2 :
    (wr1 && (ra4==wa1)) ? i1 :
    (wr0 && (ra4==wa0)) ? i0 : o04;
assign o5 = ra5[4:0]==5'd0 ? {WID{1'b0}} :
    (wr2 && (ra5==wa2)) ? i2 :
    (wr1 && (ra5==wa1)) ? i1 :
    (wr0 && (ra5==wa0)) ? i0 : o05;
assign o6 = ra6[4:0]==5'd0 ? {WID{1'b0}} :
    (wr2 && (ra6==wa2)) ? i2 :
    (wr1 && (ra6==wa1)) ? i1 :
    (wr0 && (ra6==wa0)) ? i0 : o06;
assign o7 = ra7[4:0]==5'd0 ? {WID{1'b0}} :
    (wr2 && (ra7==wa2)) ? i2 :
    (wr1 && (ra7==wa1)) ? i1 :
    (wr0 && (ra7==wa0)) ? i0 : o07;
assign o8 = ra8[4:0]==5'd0 ? {WID{1'b0}} :
    (wr2 && (ra8==wa2)) ? i2 :
    (wr1 && (ra8==wa1)) ? i1 :
    (wr0 && (ra8==wa0)) ? i0 : o08;
assign o9 = ra9[4:0]==5'd0 ? {WID{1'b0}} :
    (wr2 && (ra9==wa2)) ? i2 :
    (wr1 && (ra9==wa1)) ? i1 :
    (wr0 && (ra9==wa0)) ? i0 : o09;
assign o10 = ra10[4:0]==5'd0 ? {WID{1'b0}} :
    (wr2 && (ra10==wa2)) ? i2 :
    (wr1 && (ra10==wa1)) ? i1 :
    (wr0 && (ra10==wa0)) ? i0 : o010;
assign o11 = ra11[4:0]==5'd0 ? {WID{1'b0}} :
    (wr2 && (ra11==wa2)) ? i2 :
    (wr1 && (ra11==wa1)) ? i1 :
    (wr0 && (ra11==wa0)) ? i0 : o011;

endmodule

