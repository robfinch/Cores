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
`include "nvio3-config.sv"

module CrRegfile(clk, clk2x, wr0, wr1, wra0, wra1, wa0, wa1, i0, i1, ia0, ia1, ra0, ra1, ra2, ra3, o0, o1, o2, o3, oa);
input clk;
input clk2x;
input wr0;
input wr1;
input wra0;
input wra1;
input [2:0] wa0;
input [2:0] wa1;
input [7:0] i0;
input [7:0] i1;
input [63:0] ia0;
input [63:0] ia1;
input [2:0] ra0;
input [2:0] ra1;
input [2:0] ra2;
input [2:0] ra3;
output [7:0] o0;
output [7:0] o1;
output [7:0] o2;
output [7:0] o3;
output [63:0] oa;

reg [7:0] mem [0:7];

wire wra = clk ? wra0 : wra1;
wire wr = clk ? wr0 : wr1;
wire [2:0] wa = clk ? wa0 : wa1;
wire [7:0] i = clk ? i0 : i1;
wire [63:0] ia = clk ? ia0 : ia1;

always @(posedge clk2x)
	if (wra) begin
		mem[0] <= ia[7:0];
		mem[1] <= ia[15:8];
		mem[2] <= ia[23:16];
		mem[3] <= ia[31:24];
		mem[4] <= ia[39:32];
		mem[5] <= ia[47:40];
		mem[6] <= ia[55:48];
		mem[7] <= ia[63:56];
	end
	else if (wr)
		mem[wa] <= i;

wire [7:0] p0o = mem[ra0];
wire [7:0] p1o = mem[ra1];
wire [7:0] p2o = mem[ra2];
wire [7:0] p3o = mem[ra3];

assign o0 = ra0==3'd0 ? {8{1'b0}} : ra0==wa1 && wr1 ? i1[7:0] : ra0==wa0 && wr0 ? i0[7:0] : p0o;
assign o1 = ra1==3'd0 ? {8{1'b0}} : ra1==wa1 && wr1 ? i1[7:0] : ra1==wa0 && wr0 ? i0[7:0] : p1o;
assign o2 = ra2==3'd0 ? {8{1'b0}} : ra2==wa1 && wr1 ? i1[7:0] : ra2==wa0 && wr0 ? i0[7:0] : p2o;
assign o3 = ra3==3'd0 ? {8{1'b0}} : ra3==wa1 && wr1 ? i1[7:0] : ra3==wa0 && wr0 ? i0[7:0] : p3o;

wire [7:0] q0o = wa1==3'd0 && wr1 ? i1 : wa0==3'd0 && wr0 ? i0 : mem[0];
wire [7:0] q1o = wa1==3'd1 && wr1 ? i1 : wa0==3'd1 && wr0 ? i0 : mem[1];
wire [7:0] q2o = wa1==3'd2 && wr1 ? i1 : wa0==3'd2 && wr0 ? i0 : mem[2];
wire [7:0] q3o = wa1==3'd3 && wr1 ? i1 : wa0==3'd3 && wr0 ? i0 : mem[3];
wire [7:0] q4o = wa1==3'd4 && wr1 ? i1 : wa0==3'd4 && wr0 ? i0 : mem[4];
wire [7:0] q5o = wa1==3'd5 && wr1 ? i1 : wa0==3'd5 && wr0 ? i0 : mem[5];
wire [7:0] q6o = wa1==3'd6 && wr1 ? i1 : wa0==3'd6 && wr0 ? i0 : mem[6];
wire [7:0] q7o = wa1==3'd7 && wr1 ? i1 : wa0==3'd7 && wr0 ? i0 : mem[7];

assign oa = {q7o,q6o,q5o,q4o,q3o,q2o,q1o,q0o};

endmodule
