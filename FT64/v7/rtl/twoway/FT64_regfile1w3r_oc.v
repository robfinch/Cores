`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
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

module FT64_regfile1w3r_oc(clk, wr0, we0, wa0, i0,
	rclk, ra0, ra1, ra2, o0, o1, o2);
parameter WID=64;
parameter RBIT = 11;
input clk;
input wr0;
input [7:0] we0;
input [RBIT:0] wa0;
input [WID-1:0] i0;
input rclk;
input [RBIT:0] ra0;
input [RBIT:0] ra1;
input [RBIT:0] ra2;
output [WID-1:0] o0;
output [WID-1:0] o1;
output [WID-1:0] o2;

reg wr;
reg [RBIT:0] wa;
reg [WID-1:0] i;
reg [7:0] we;
wire [WID-1:0] o00, o01, o02;

integer n;

`ifdef SIM
FT64_regfileRam_sim urf10 (
  .clka(clk),
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
  .clka(clk),
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
  .clka(clk),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .clkb(rclk),
  .enb(1'b1),
  .addrb(ra2),
  .doutb(o02)
);

`else
FT64_regfileRam urf10 (
  .clka(clk),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .douta(),
  .clkb(rclk),
  .enb(1'b1),
  .web(8'b0),
  .addrb(ra0),
  .dinb(64'h00),
  .doutb(o00)
);

FT64_regfileRam urf11 (
  .clka(clk),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .douta(),
  .clkb(rclk),
  .enb(1'b1),
  .web(8'b0),
  .addrb(ra1),
  .dinb(64'h00),
  .doutb(o01)
);

FT64_regfileRam urf12 (
  .clka(clk),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .douta(),
  .clkb(rclk),
  .enb(1'b1),
  .web(8'b0),
  .addrb(ra2),
  .dinb(64'h00),
  .doutb(o02)
);

`endif

always @*
begin
	wr <= wr0;
	we <= we0;
	wa <= wa0;
	i <= i0;
end

assign o0[7:0] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[0] && (ra0==wa0)) ? i0[7:0] : o00[7:0];
assign o0[15:8] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[1] && (ra0==wa0)) ? i0[15:8] : o00[15:8];
assign o0[23:16] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[2] && (ra0==wa0)) ? i0[23:16] : o00[23:16];
assign o0[31:24] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[3] && (ra0==wa0)) ? i0[31:24] : o00[31:24];
assign o0[39:32] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[4] && (ra0==wa0)) ? i0[39:32] : o00[39:32];
assign o0[47:40] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[5] && (ra0==wa0)) ? i0[47:40] : o00[47:40];
assign o0[55:48] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[6] && (ra0==wa0)) ? i0[55:48] : o00[55:48];
assign o0[63:56] = ra0[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[7] && (ra0==wa0)) ? i0[63:56] : o00[63:56];

assign o1[7:0] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[0] && (ra1==wa0)) ? i0[7:0] : o01[7:0];
assign o1[15:8] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[1] && (ra1==wa0)) ? i0[15:8] : o01[15:8];
assign o1[23:16] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[2] && (ra1==wa0)) ? i0[23:16] : o01[23:16];
assign o1[31:24] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[3] && (ra1==wa0)) ? i0[31:24] : o01[31:24];
assign o1[39:32] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[4] && (ra1==wa0)) ? i0[39:32] : o01[39:32];
assign o1[47:40] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[5] && (ra1==wa0)) ? i0[47:40] : o01[47:40];
assign o1[55:48] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[6] && (ra1==wa0)) ? i0[55:48] : o01[55:48];
assign o1[63:56] = ra1[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[7] && (ra1==wa0)) ? i0[63:56] : o01[63:56];

assign o2[7:0] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[0] && (ra2==wa0)) ? i0[7:0] : o02[7:0];
assign o2[15:8] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[1] && (ra2==wa0)) ? i0[15:8] : o02[15:8];
assign o2[23:16] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[2] && (ra2==wa0)) ? i0[23:16] : o02[23:16];
assign o2[31:24] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[3] && (ra2==wa0)) ? i0[31:24] : o02[31:24];
assign o2[39:32] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[4] && (ra2==wa0)) ? i0[39:32] : o02[39:32];
assign o2[47:40] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[5] && (ra2==wa0)) ? i0[47:40] : o02[47:40];
assign o2[55:48] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[6] && (ra2==wa0)) ? i0[55:48] : o02[55:48];
assign o2[63:56] = ra2[4:0]==5'd0 ? {8{1'b0}} :
	(wr0 && we0[7] && (ra2==wa0)) ? i0[63:56] : o02[63:56];

endmodule

