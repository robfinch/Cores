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
// 41318
//`include "nvio3-config.sv"

module VecRegfile(clk, clk2x, ol, wr0, wr1, wa0, wa1, i0, i1,
	ra0, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10, ra11, ra12, ra13, ra14, ra15,
	o0, o1, o2, o3, o4, o5, o6, o7, o8, o9, o10, o11, o12, o13, o14, o15);
parameter WID=256;
localparam W=WID-1;
input clk;
input clk2x;
input [1:0] ol;
input wr0;
input wr1;
input [4:0] wa0;
input [4:0] wa1;
input [W:0] i0;
input [W:0] i1;
input [4:0] ra0;
input [4:0] ra1;
input [4:0] ra2;
input [4:0] ra3;
input [4:0] ra4;
input [4:0] ra5;
input [4:0] ra6;
input [4:0] ra7;
input [4:0] ra8;
input [4:0] ra9;
input [4:0] ra10;
input [4:0] ra11;
input [4:0] ra12;
input [4:0] ra13;
input [4:0] ra14;
input [4:0] ra15;
output [W:0] o0;
output [W:0] o1;
output [W:0] o2;
output [W:0] o3;
output [W:0] o4;
output [W:0] o5;
output [W:0] o6;
output [W:0] o7;
output [W:0] o8;
output [W:0] o9;
output [W:0] o10;
output [W:0] o11;
output [W:0] o12;
output [W:0] o13;
output [W:0] o14;
output [W:0] o15;
(* ram_style="distributed" *)
reg [W:0] mem0 [0:31];
reg [W:0] mem1 [0:31];

wire wr = clk ? wr0 : wr1;
wire [4:0] wa = clk ? wa0 : wa1;
wire [W:0] i = clk ? i0 : i1;

always @(posedge clk2x)
	if (wr) begin
		mem0[wa] <= i;
		mem1[wa] <= i;
	end

wire [W:0] p0o = mem0[ra0];
wire [W:0] p1o = mem0[ra1];
wire [W:0] p2o = mem0[ra2];
wire [W:0] p3o = mem0[ra3];
wire [W:0] p4o = mem0[ra4];
wire [W:0] p5o = mem0[ra5];
wire [W:0] p6o = mem0[ra6];
wire [W:0] p7o = mem0[ra7];
wire [W:0] p8o = mem1[ra8];
wire [W:0] p9o = mem1[ra9];
wire [W:0] p10o = mem1[ra10];
wire [W:0] p11o = mem1[ra11];
wire [W:0] p12o = mem1[ra12];
wire [W:0] p13o = mem1[ra13];
wire [W:0] p14o = mem1[ra14];
wire [W:0] p15o = mem1[ra15];

assign o0 = ra0==wa1 && wr1 ? i1 : ra0==wa0 && wr0 ? i0 : p0o;
assign o1 = ra1==wa1 && wr1 ? i1 : ra1==wa0 && wr0 ? i0 : p1o;
assign o2 = ra2==wa1 && wr1 ? i1 : ra2==wa0 && wr0 ? i0 : p2o;
assign o3 = ra3==wa1 && wr1 ? i1 : ra3==wa0 && wr0 ? i0 : p3o;
assign o4 = ra4==wa1 && wr1 ? i1 : ra4==wa0 && wr0 ? i0 : p4o;
assign o5 = ra5==wa1 && wr1 ? i1 : ra5==wa0 && wr0 ? i0 : p5o;
assign o6 = ra6==wa1 && wr1 ? i1 : ra6==wa0 && wr0 ? i0 : p6o;
assign o7 = ra7==wa1 && wr1 ? i1 : ra7==wa0 && wr0 ? i0 : p7o;
assign o8 = ra8==wa1 && wr1 ? i1 : ra8==wa0 && wr0 ? i0 : p8o;
assign o9 = ra9==wa1 && wr1 ? i1 : ra9==wa0 && wr0 ? i0 : p9o;
assign o10 = ra10==wa1 && wr1 ? i1 : ra10==wa0 && wr0 ? i0 : p10o;
assign o11 = ra11==wa1 && wr1 ? i1 : ra11==wa0 && wr0 ? i0 : p11o;
assign o12 = ra12==wa1 && wr1 ? i1 : ra12==wa0 && wr0 ? i0 : p12o;
assign o13 = ra13==wa1 && wr1 ? i1 : ra13==wa0 && wr0 ? i0 : p13o;
assign o14 = ra14==wa1 && wr1 ? i1 : ra14==wa0 && wr0 ? i0 : p14o;
assign o15 = ra15==wa1 && wr1 ? i1 : ra15==wa0 && wr0 ? i0 : p15o;

endmodule
