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
`include "FT64_config.vh"

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
reg [64:0] mem [0:4095];
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

module FT64_regfile2w6r_oc(clk4x, clk, wr0, wr1, we0, we1, wa0, wa1, i0, i1,
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
reg wr1x;
reg [RBIT:0] wa1x;
reg [WID-1:0] i1x;
reg [7:0] we1x;

integer n;

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
`else
FT64_regfileRam urf10 (
  .clka(clk4x),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .web(1'b0),
  .addrb(ra0),
  .dinb(8'h00),
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
  .web(1'b0),
  .addrb(ra1),
  .dinb(8'h00),
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
  .web(1'b0),
  .addrb(ra2),
  .dinb(8'h00),
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
  .web(1'b0),
  .addrb(ra3),
  .dinb(8'h00),
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
  .web(1'b0),
  .addrb(ra4),
  .dinb(8'h00),
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
  .web(1'b0),
  .addrb(ra5),
  .dinb(8'h00),
  .doutb(o05)
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

reg wclk2;
always @(posedge clk4x)
begin
	wclk2 <= clk;
	if (clk & ~wclk2) begin
		wr <= wr0;
		we <= we0;
		wa <= wa0;
		i <= i0;
	end
	else if (~clk & wclk2) begin
		wr <= wr1x;
		we <= we1x;
		wa <= wa1x;
		i <= i1x;
	end
	else begin
		wr <= 1'b0;
		we <= 8'h00;
		wa <= 'd0;
		i <= 'd0;
	end
end

assign o0[7:0] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[0] && (ra0==wa1)) ? i1[7:0] :
	(wr0 && we0[0] && (ra0==wa0)) ? i0[7:0] : o00[7:0];
assign o0[15:8] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[1] && (ra0==wa1)) ? i1[15:8] :
	(wr0 && we0[1] && (ra0==wa0)) ? i0[15:8] : o00[15:8];
assign o0[23:16] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[2] && (ra0==wa1)) ? i1[23:16] :
	(wr0 && we0[2] && (ra0==wa0)) ? i0[23:16] : o00[23:16];
assign o0[31:24] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[3] && (ra0==wa1)) ? i1[31:24] :
	(wr0 && we0[3] && (ra0==wa0)) ? i0[31:24] : o00[31:24];
assign o0[39:32] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[4] && (ra0==wa1)) ? i1[39:32] :
	(wr0 && we0[4] && (ra0==wa0)) ? i0[39:32] : o00[39:32];
assign o0[47:40] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[5] && (ra0==wa1)) ? i1[47:40] :
	(wr0 && we0[5] && (ra0==wa0)) ? i0[47:40] : o00[47:40];
assign o0[55:48] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[6] && (ra0==wa1)) ? i1[55:48] :
	(wr0 && we0[6] && (ra0==wa0)) ? i0[55:48] : o00[55:48];
assign o0[63:56] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[7] && (ra0==wa1)) ? i1[63:56] :
	(wr0 && we0[7] && (ra0==wa0)) ? i0[63:56] : o00[63:56];

assign o1[7:0] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[0] && (ra1==wa1)) ? i1[7:0] :
	(wr0 && we0[0] && (ra1==wa0)) ? i0[7:0] : o01[7:0];
assign o1[15:8] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[1] && (ra1==wa1)) ? i1[15:8] :
	(wr0 && we0[1] && (ra1==wa0)) ? i0[15:8] : o01[15:8];
assign o1[23:16] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[2] && (ra1==wa1)) ? i1[23:16] :
	(wr0 && we0[2] && (ra1==wa0)) ? i0[23:16] : o01[23:16];
assign o1[31:24] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[3] && (ra1==wa1)) ? i1[31:24] :
	(wr0 && we0[3] && (ra1==wa0)) ? i0[31:24] : o01[31:24];
assign o1[39:32] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[4] && (ra1==wa1)) ? i1[39:32] :
	(wr0 && we0[4] && (ra1==wa0)) ? i0[39:32] : o01[39:32];
assign o1[47:40] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[5] && (ra1==wa1)) ? i1[47:40] :
	(wr0 && we0[5] && (ra1==wa0)) ? i0[47:40] : o01[47:40];
assign o1[55:48] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[6] && (ra1==wa1)) ? i1[55:48] :
	(wr0 && we0[6] && (ra1==wa0)) ? i0[55:48] : o01[55:48];
assign o1[63:56] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[7] && (ra1==wa1)) ? i1[63:56] :
	(wr0 && we0[7] && (ra1==wa0)) ? i0[63:56] : o01[63:56];

assign o2[7:0] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[0] && (ra2==wa1)) ? i1[7:0] :
	(wr0 && we0[0] && (ra2==wa0)) ? i0[7:0] : o02[7:0];
assign o2[15:8] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[1] && (ra2==wa1)) ? i1[15:8] :
	(wr0 && we0[1] && (ra2==wa0)) ? i0[15:8] : o02[15:8];
assign o2[23:16] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[2] && (ra2==wa1)) ? i1[23:16] :
	(wr0 && we0[2] && (ra2==wa0)) ? i0[23:16] : o02[23:16];
assign o2[31:24] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[3] && (ra2==wa1)) ? i1[31:24] :
	(wr0 && we0[3] && (ra2==wa0)) ? i0[31:24] : o02[31:24];
assign o2[39:32] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[4] && (ra2==wa1)) ? i1[39:32] :
	(wr0 && we0[4] && (ra2==wa0)) ? i0[39:32] : o02[39:32];
assign o2[47:40] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[5] && (ra2==wa1)) ? i1[47:40] :
	(wr0 && we0[5] && (ra2==wa0)) ? i0[47:40] : o02[47:40];
assign o2[55:48] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[6] && (ra2==wa1)) ? i1[55:48] :
	(wr0 && we0[6] && (ra2==wa0)) ? i0[55:48] : o02[55:48];
assign o2[63:56] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[7] && (ra2==wa1)) ? i1[63:56] :
	(wr0 && we0[7] && (ra2==wa0)) ? i0[63:56] : o02[63:56];

assign o3[7:0] = ra3[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[0] && (ra3==wa1)) ? i1[7:0] :
	(wr0 && we0[0] && (ra3==wa0)) ? i0[7:0] : o03[7:0];
assign o3[15:8] = ra3[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[1] && (ra3==wa1)) ? i1[15:8] :
	(wr0 && we0[1] && (ra3==wa0)) ? i0[15:8] : o03[15:8];
assign o3[23:16] = ra3[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[2] && (ra3==wa1)) ? i1[23:16] :
	(wr0 && we0[2] && (ra3==wa0)) ? i0[23:16] : o03[23:16];
assign o3[31:24] = ra3[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[3] && (ra3==wa1)) ? i1[31:24] :
	(wr0 && we0[3] && (ra3==wa0)) ? i0[31:24] : o03[31:24];
assign o3[39:32] = ra3[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[4] && (ra3==wa1)) ? i1[39:32] :
	(wr0 && we0[4] && (ra3==wa0)) ? i0[39:32] : o03[39:32];
assign o3[47:40] = ra3[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[5] && (ra3==wa1)) ? i1[47:40] :
	(wr0 && we0[5] && (ra3==wa0)) ? i0[47:40] : o03[47:40];
assign o3[55:48] = ra3[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[6] && (ra3==wa1)) ? i1[55:48] :
	(wr0 && we0[6] && (ra3==wa0)) ? i0[55:48] : o03[55:48];
assign o3[63:56] = ra3[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[7] && (ra3==wa1)) ? i1[63:56] :
	(wr0 && we0[7] && (ra3==wa0)) ? i0[63:56] : o03[63:56];

assign o4[7:0] = ra4[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[0] && (ra4==wa1)) ? i1[7:0] :
	(wr0 && we0[0] && (ra4==wa0)) ? i0[7:0] : o04[7:0];
assign o4[15:8] = ra4[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[1] && (ra4==wa1)) ? i1[15:8] :
	(wr0 && we0[1] && (ra4==wa0)) ? i0[15:8] : o04[15:8];
assign o4[23:16] = ra4[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[2] && (ra4==wa1)) ? i1[23:16] :
	(wr0 && we0[2] && (ra4==wa0)) ? i0[23:16] : o04[23:16];
assign o4[31:24] = ra4[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[3] && (ra4==wa1)) ? i1[31:24] :
	(wr0 && we0[3] && (ra4==wa0)) ? i0[31:24] : o04[31:24];
assign o4[39:32] = ra4[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[4] && (ra4==wa1)) ? i1[39:32] :
	(wr0 && we0[4] && (ra4==wa0)) ? i0[39:32] : o04[39:32];
assign o4[47:40] = ra4[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[5] && (ra4==wa1)) ? i1[47:40] :
	(wr0 && we0[5] && (ra4==wa0)) ? i0[47:40] : o04[47:40];
assign o4[55:48] = ra4[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[6] && (ra4==wa1)) ? i1[55:48] :
	(wr0 && we0[6] && (ra4==wa0)) ? i0[55:48] : o04[55:48];
assign o4[63:56] = ra4[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[7] && (ra4==wa1)) ? i1[63:56] :
	(wr0 && we0[7] && (ra4==wa0)) ? i0[63:56] : o04[63:56];

assign o5[7:0] = ra5[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[0] && (ra5==wa1)) ? i1[7:0] :
	(wr0 && we0[0] && (ra5==wa0)) ? i0[7:0] : o05[7:0];
assign o5[15:8] = ra5[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[1] && (ra5==wa1)) ? i1[15:8] :
	(wr0 && we0[1] && (ra5==wa0)) ? i0[15:8] : o05[15:8];
assign o5[23:16] = ra5[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[2] && (ra5==wa1)) ? i1[23:16] :
	(wr0 && we0[2] && (ra5==wa0)) ? i0[23:16] : o05[23:16];
assign o5[31:24] = ra5[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[3] && (ra5==wa1)) ? i1[31:24] :
	(wr0 && we0[3] && (ra5==wa0)) ? i0[31:24] : o05[31:24];
assign o5[39:32] = ra5[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[4] && (ra5==wa1)) ? i1[39:32] :
	(wr0 && we0[4] && (ra5==wa0)) ? i0[39:32] : o05[39:32];
assign o5[47:40] = ra5[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[5] && (ra5==wa1)) ? i1[47:40] :
	(wr0 && we0[5] && (ra5==wa0)) ? i0[47:40] : o05[47:40];
assign o5[55:48] = ra5[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[6] && (ra5==wa1)) ? i1[55:48] :
	(wr0 && we0[6] && (ra5==wa0)) ? i0[55:48] : o05[55:48];
assign o5[63:56] = ra5[4:0]==5'd0 ? {8{1'b0}} :
	(wr1 && we1[7] && (ra5==wa1)) ? i1[63:56] :
	(wr0 && we0[7] && (ra5==wa0)) ? i0[63:56] : o05[63:56];
/*
assign o5 = ra5[4:0]==5'd0 ? {WID{1'b0}} :
    (wr1 && (ra5==wa1)) ? i1 :
    (wr0 && (ra5==wa0)) ? i0 : o05;

*/
endmodule

