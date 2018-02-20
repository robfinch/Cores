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
//`define SIM

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

always @(posedge clka) if (ena & wea[0]) mem[addra][7:0] <= dina[7:0];
always @(posedge clka) if (ena & wea[1]) mem[addra][15:8] <= dina[15:8];
always @(posedge clka) if (ena & wea[2]) mem[addra][23:16] <= dina[23:16];
always @(posedge clka) if (ena & wea[3]) mem[addra][31:24] <= dina[31:24];
always @(posedge clka) if (ena & wea[4]) mem[addra][39:32] <= dina[39:32];
always @(posedge clka) if (ena & wea[5]) mem[addra][47:40] <= dina[47:40];
always @(posedge clka) if (ena & wea[6]) mem[addra][55:48] <= dina[55:48];
always @(posedge clka) if (ena & wea[7]) mem[addra][63:56] <= dina[63:56];

always @(posedge clkb)
	raddrb <= addrb;
assign doutb = mem[raddrb];
	
endmodule

module FT64_regfile2w6r(clk4x, clk, wr0, wr1, we0, we1, wa0, wa1, i0, i1,
	rclk, ra0, ra1, ra2, ra3, ra4, ra5,
	o0, o1, o2, o3, o4, o5);
parameter WID=64;
parameter RBIT = 11;
input clk4x;
input clk;
input wr0;
input wr1;
input [7:0] we0;
input [7:0] we1;
input [RBIT:0] wa0;
input [RBIT:0] wa1;
input [WID-1:0] i0;
input [WID-1:0] i1;
input rclk;
input [RBIT:0] ra0;
input [RBIT:0] ra1;
input [RBIT:0] ra2;
input [RBIT:0] ra3;
input [RBIT:0] ra4;
input [RBIT:0] ra5;
output [WID-1:0] o0;
output [WID-1:0] o1;
output [WID-1:0] o2;
output [WID-1:0] o3;
output [WID-1:0] o4;
output [WID-1:0] o5;

reg wr;
reg [RBIT:0] wa;
reg [WID-1:0] i;
reg [7:0] we;
wire [WID-1:0] o00, o01, o02, o03, o04, o05;
wire [WID-1:0] o10, o11, o12, o13, o14, o15;
reg wr1x;
reg [RBIT:0] wa1x;
reg [WID-1:0] i1x;
reg [7:0] we1x;

`ifdef SIM
FT64_regfileRam_sim urf10 (
  .clka(clk),
  .ena(wr0),
  .wea(we0),
  .addra(wa0),
  .dina(i0),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra0),
  .doutb(o00)
);

FT64_regfileRam_sim urf11 (
  .clka(clk),
  .ena(wr0),
  .wea(we0),
  .addra(wa0),
  .dina(i0),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra1),
  .doutb(o01)
);

FT64_regfileRam_sim urf12 (
  .clka(clk),
  .ena(wr0),
  .wea(we0),
  .addra(wa0),
  .dina(i0),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra2),
  .doutb(o02)
);

FT64_regfileRam_sim urf13 (
  .clka(clk),
  .ena(wr0),
  .wea(we0),
  .addra(wa0),
  .dina(i0),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra3),
  .doutb(o03)
);

FT64_regfileRam_sim urf14 (
  .clka(clk),
  .ena(wr0),
  .wea(we0),
  .addra(wa0),
  .dina(i0),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra4),
  .doutb(o04)
);

FT64_regfileRam_sim urf15 (
  .clka(clk),
  .ena(wr0),
  .wea(we0),
  .addra(wa0),
  .dina(i0),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra5),
  .doutb(o05)
);
FT64_regfileRam_sim urf20 (
  .clka(clk),
  .ena(wr1),
  .wea(we1),
  .addra(wa1),
  .dina(i1),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra0),
  .doutb(o10)
);

FT64_regfileRam_sim urf21 (
  .clka(clk),
  .ena(wr1),
  .wea(we1),
  .addra(wa1),
  .dina(i1),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra1),
  .doutb(o11)
);

FT64_regfileRam_sim urf22 (
  .clka(clk),
  .ena(wr1),
  .wea(we1),
  .addra(wa1),
  .dina(i1),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra2),
  .doutb(o12)
);

FT64_regfileRam_sim urf23 (
  .clka(clk),
  .ena(wr1),
  .wea(we1),
  .addra(wa1),
  .dina(i1),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra3),
  .doutb(o13)
);

FT64_regfileRam_sim urf24 (
  .clka(clk),
  .ena(wr1),
  .wea(we1),
  .addra(wa1),
  .dina(i1),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra4),
  .doutb(o14)
);

FT64_regfileRam_sim urf25 (
  .clka(clk),
  .ena(wr1),
  .wea(we1),
  .addra(wa1),
  .dina(i1),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra5),
  .doutb(o15)
);
`else
FT64_regfileRam urf10 (
  .clka(clk),
  .ena(wr0),
  .wea(we0),
  .addra(wa0),
  .dina(i0),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra0),
  .doutb(o00)
);

FT64_regfileRam urf11 (
  .clka(clk),
  .ena(wr0),
  .wea(we0),
  .addra(wa0),
  .dina(i0),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra1),
  .doutb(o01)
);

FT64_regfileRam urf12 (
  .clka(clk),
  .ena(wr0),
  .wea(we0),
  .addra(wa0),
  .dina(i0),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra2),
  .doutb(o02)
);

FT64_regfileRam urf13 (
  .clka(clk),
  .ena(wr0),
  .wea(we0),
  .addra(wa0),
  .dina(i0),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra3),
  .doutb(o03)
);

FT64_regfileRam urf14 (
  .clka(clk),
  .ena(wr0),
  .wea(we0),
  .addra(wa0),
  .dina(i0),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra4),
  .doutb(o04)
);

FT64_regfileRam urf15 (
  .clka(clk),
  .ena(wr0),
  .wea(we0),
  .addra(wa0),
  .dina(i0),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra5),
  .doutb(o05)
);

FT64_regfileRam urf20 (
  .clka(clk),
  .ena(wr1),
  .wea(we1),
  .addra(wa1),
  .dina(i1),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra0),
  .doutb(o10)
);

FT64_regfileRam urf21 (
  .clka(clk),
  .ena(wr1),
  .wea(we1),
  .addra(wa1),
  .dina(i1),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra1),
  .doutb(o11)
);

FT64_regfileRam urf22 (
  .clka(clk),
  .ena(wr1),
  .wea(we1),
  .addra(wa1),
  .dina(i1),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra2),
  .doutb(o12)
);

FT64_regfileRam urf23 (
  .clka(clk),
  .ena(wr1),
  .wea(we1),
  .addra(wa1),
  .dina(i1),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra3),
  .doutb(o13)
);

FT64_regfileRam urf24 (
  .clka(clk),
  .ena(wr1),
  .wea(we1),
  .addra(wa1),
  .dina(i1),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra4),
  .doutb(o14)
);

FT64_regfileRam urf25 (
  .clka(clk),
  .ena(wr1),
  .wea(we1),
  .addra(wa1),
  .dina(i1),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra5),
  .doutb(o15)
);
`endif

reg whichreg [0:RBIT==11 ? 4095:RBIT==10 ? 2047:RBIT==9 ? 1023 :255];	// tracks which register file is the valid one for a given register

// We only care about what's in the regs to begin with in simulation. In sim
// the 'x' values propagate screwing things up. In real hardware there's no such
// thing as an 'x'.
//`define SIMULATION
`ifdef SIM
integer n;
initial begin
    for (n = 0; n < ((RBIT==11) ? 4095 : (RBIT==10) ? 2047 : (RBIT==9) ? 1024: 256); n = n + 1)
    begin
        whichreg[n] = 0;
    end
end
`endif

assign o0 = ra0[4:0]==5'd0 ? {WID{1'b0}} :
	(wr1 && (ra0==wa1)) ? i1 :
	(wr0 && (ra0==wa0)) ? i0 :
	whichreg[ra0]==1'b0 ? o00 : o10;
assign o1 = ra1[4:0]==5'd0 ? {WID{1'b0}} :
	(wr1 && (ra1==wa1)) ? i1 :
	(wr0 && (ra1==wa0)) ? i0 :
	whichreg[ra1]==1'b0 ? o01 : o11;
assign o2 = ra2[4:0]==5'd0 ? {WID{1'b0}} :
	(wr1 && (ra2==wa1)) ? i1 :
	(wr0 && (ra2==wa0)) ? i0 :
	whichreg[ra2]==1'b0 ? o02 : o12;
assign o3 = ra3[4:0]==5'd0 ? {WID{1'b0}} :
	(wr1 && (ra3==wa1)) ? i1 :
	(wr0 && (ra3==wa0)) ? i0 :
	whichreg[ra3]==1'b0 ? o03 : o13;
assign o4 = ra4[4:0]==5'd0 ? {WID{1'b0}} :
    (wr1 && (ra4==wa1)) ? i1 :
    (wr0 && (ra4==wa0)) ? i0 :
    whichreg[ra4]==1'b0 ? o04 : o14;
assign o5 = ra5[4:0]==5'd0 ? {WID{1'b0}} :
    (wr1 && (ra5==wa1)) ? i1 :
    (wr0 && (ra5==wa0)) ? i0 :
    whichreg[ra5]==1'b0 ? o05 : o15;

always @(posedge clk)
	// writing three registers at once
	if (wr0 && wr1 && wa0==wa1)		// Two ports writing the same address
		whichreg[wa0] <= 1'b1;		// port one is the valid one
	// writing two registers
	else if (wr0 && wr1) begin
		whichreg[wa0] <= 1'b0;
		whichreg[wa1] <= 1'b1;
	end
	// writing a single register
	else if (wr0)
		whichreg[wa0] <= 1'b0;
	else if (wr1)
		whichreg[wa1] <= 1'b1;

endmodule

