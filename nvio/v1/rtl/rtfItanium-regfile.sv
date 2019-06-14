// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
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
// ============================================================================
//
`include "rtfItanium-config.sv"

module Regfile(clk, clk2x, wr0, wa0, i0, wr1, wa1, i1,
	rclk, ra0, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8,
	o0, o1, o2, o3, o4, o5, o6 ,o7, o8);
parameter WID = 80;
input clk;
input clk2x;
input wr0;
input [9:0] wa0;
input [WID+3:0] i0;
input wr1;
input [9:0] wa1;
input [WID-1:0] i1;
input rclk;
input [9:0] ra0;
input [9:0] ra1;
input [9:0] ra2;
input [9:0] ra3;
input [9:0] ra4;
input [9:0] ra5;
input [9:0] ra6;
input [9:0] ra7;
input [9:0] ra8;
output [WID+3:0] o0;
output [WID+3:0] o1;
output [WID+3:0] o2;
output [WID+3:0] o3;
output [WID+3:0] o4;
output [WID+3:0] o5;
output [WID+3:0] o6;
output [WID+3:0] o7;
output [WID+3:0] o8;

//reg [5:0] rra0, rra1;
//reg [WID-1:0] mem [0:63];
integer n;
wire [WID+3:0] p0o, p1o, p2o, p3o, p4o, p5o, p6o, p7o, p8o;

wire wr = clk ? wr0 : wr1;
wire [9:0] wa = clk ? wa0 : wa1;
wire [WID+3:0] i = clk ? i0 : i1;

`ifdef SIM
reg [WID+3:0] mem [0:1023];
initial begin
	for (n = 0; n < 1024; n = n + 1)
		mem[n] = {WID{1'b0}};
end
always @(posedge clk2x)
	if (wr) mem[wa] <= i;
assign p0o = mem[ra0];
assign p1o = mem[ra1];
assign p2o = mem[ra2];
assign p3o = mem[ra3];
assign p4o = mem[ra4];
assign p5o = mem[ra5];
assign p6o = mem[ra6];
assign p7o = mem[ra7];
assign p8o = mem[ra8];

`else
regfileRam u1 (
  .clka(clk2x),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa),  // input wire [9 : 0] addra
  .dina(i),    // input wire [79 : 0] dina
  .douta(),  // output wire [79 : 0] douta
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(ra0),  // input wire [9 : 0] addrb
  .dinb(84'h0),    // input wire [79 : 0] dinb
  .doutb(p0o)  // output wire [79 : 0] doutb
);

regfileRam u2 (
  .clka(clk2x),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa),  // input wire [9 : 0] addra
  .dina(i),    // input wire [79 : 0] dina
  .douta(),  // output wire [79 : 0] douta
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(ra1),  // input wire [9 : 0] addrb
  .dinb(84'h0),    // input wire [79 : 0] dinb
  .doutb(p1o)  // output wire [79 : 0] doutb
);

regfileRam u3 (
  .clka(clk2x),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa),  // input wire [9 : 0] addra
  .dina(i),    // input wire [79 : 0] dina
  .douta(),  // output wire [79 : 0] douta
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(ra2),  // input wire [9 : 0] addrb
  .dinb(84'h0),    // input wire [79 : 0] dinb
  .doutb(p2o)  // output wire [79 : 0] doutb
);

regfileRam u4 (
  .clka(clk2x),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa),  // input wire [9 : 0] addra
  .dina(i),    // input wire [79 : 0] dina
  .douta(),  // output wire [79 : 0] douta
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(ra3),  // input wire [9 : 0] addrb
  .dinb(84'h0),    // input wire [79 : 0] dinb
  .doutb(p3o)  // output wire [79 : 0] doutb
);

regfileRam u5 (
  .clka(clk2x),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa),  // input wire [9 : 0] addra
  .dina(i),    // input wire [79 : 0] dina
  .douta(),  // output wire [79 : 0] douta
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(ra4),  // input wire [9 : 0] addrb
  .dinb(84'h0),    // input wire [79 : 0] dinb
  .doutb(p4o)  // output wire [79 : 0] doutb
);

regfileRam u6 (
  .clka(clk2x),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa),  // input wire [9 : 0] addra
  .dina(i),    // input wire [79 : 0] dina
  .douta(),  // output wire [79 : 0] douta
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(ra5),  // input wire [9 : 0] addrb
  .dinb(84'h0),    // input wire [79 : 0] dinb
  .doutb(p5o)  // output wire [79 : 0] doutb
);

regfileRam u7 (
  .clka(clk2x),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa),  // input wire [9 : 0] addra
  .dina(i),    // input wire [79 : 0] dina
  .douta(),  // output wire [79 : 0] douta
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(ra6),  // input wire [9 : 0] addrb
  .dinb(84'h0),    // input wire [79 : 0] dinb
  .doutb(p6o)  // output wire [79 : 0] doutb
);

regfileRam u8 (
  .clka(clk2x),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa),  // input wire [9 : 0] addra
  .dina(i),    // input wire [79 : 0] dina
  .douta(),  // output wire [79 : 0] douta
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(ra7),  // input wire [9 : 0] addrb
  .dinb(84'h0),    // input wire [79 : 0] dinb
  .doutb(p7o)  // output wire [79 : 0] doutb
);

regfileRam u9 (
  .clka(clk2x),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa),  // input wire [9 : 0] addra
  .dina(i),    // input wire [79 : 0] dina
  .douta(),  // output wire [79 : 0] douta
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(ra8),  // input wire [9 : 0] addrb
  .dinb(84'h0),    // input wire [79 : 0] dinb
  .doutb(p8o)  // output wire [79 : 0] doutb
);
`endif

assign o0 = ra0[5:0]==6'd0 ? {WID+4{1'b0}} : ra0==wa1 && wr1 ? i1 : ra0==wa0 && wr0 ? i0 : p0o;
assign o1 = ra1[5:0]==6'd0 ? {WID+4{1'b0}} : ra1==wa1 && wr1 ? i1 : ra1==wa0 && wr0 ? i0 : p1o;
assign o2 = ra2[5:0]==6'd0 ? {WID+4{1'b0}} : ra2==wa1 && wr1 ? i1 : ra2==wa0 && wr0 ? i0 : p2o;
assign o3 = ra3[5:0]==6'd0 ? {WID+4{1'b0}} : ra3==wa1 && wr1 ? i1 : ra3==wa0 && wr0 ? i0 : p3o;
assign o4 = ra4[5:0]==6'd0 ? {WID+4{1'b0}} : ra4==wa1 && wr1 ? i1 : ra4==wa0 && wr0 ? i0 : p4o;
assign o5 = ra5[5:0]==6'd0 ? {WID+4{1'b0}} : ra5==wa1 && wr1 ? i1 : ra5==wa0 && wr0 ? i0 : p5o;
assign o6 = ra6[5:0]==6'd0 ? {WID+4{1'b0}} : ra6==wa1 && wr1 ? i1 : ra6==wa0 && wr0 ? i0 : p6o;
assign o7 = ra7[5:0]==6'd0 ? {WID+4{1'b0}} : ra7==wa1 && wr1 ? i1 : ra7==wa0 && wr0 ? i0 : p7o;
assign o8 = ra8[5:0]==6'd0 ? {WID+4{1'b0}} : ra8==wa1 && wr1 ? i1 : ra8==wa0 && wr0 ? i0 : p8o;

endmodule
