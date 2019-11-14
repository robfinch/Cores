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

module LkRegfile(clk, clk2x, wr0, wr1, wa0, wa1, i0, i1, ra0, ra1, ra2, o0, o1, o2);
input clk;
input clk2x;
input wr0;
input wr1;
input [2:0] wa0;
input [2:0] wa1;
input [127:0] i0;
input [127:0] i1;
input [2:0] ra0;
input [2:0] ra1;
input [2:0] ra2;
output [127:0] o0;
output [127:0] o1;
output [127:0] o2;
reg [127:0] mem [0:7];

wire wr = clk ? wr0 : wr1;
wire [2:0] wa = clk ? wa0 : wa1;
wire [127:0] i = clk ? i0 : i1;

always @(posedge clk2x)
	if (wr)
		mem[wa] <= i;

wire [127:0] p0o = mem[ra0];
wire [127:0] p1o = mem[ra1];
wire [127:0] p1o = mem[ra1];

assign o0 = ra0==3'd0 ? {128{1'b0}} : ra0==wa1 && wr1 ? i1 : ra0==wa0 && wr0 ? i0 : p0o;
assign o1 = ra1==3'd0 ? {128{1'b0}} : ra1==wa1 && wr1 ? i1 : ra1==wa0 && wr0 ? i0 : p1o;
assign o2 = ra2==3'd0 ? {128{1'b0}} : ra2==wa1 && wr1 ? i1 : ra2==wa0 && wr0 ? i0 : p2o;

endmodule
