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
module Regfile(clk, clk2x, wr0, wa0, i0, wr1, wa1, i1,
	ra0, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8,
	o0, o1, o2, o3, o4, o5, o6 ,o7, o8);
parameter WID = 80;
input clk;
input clk2x;
input wr0;
input [5:0] wa0;
input [79:0] i0;
input wr1;
input [5:0] wa1;
input [79:0] i1;
input [5:0] ra0;
input [5:0] ra1;
input [5:0] ra2;
input [5:0] ra3;
input [5:0] ra4;
input [5:0] ra5;
input [5:0] ra6;
input [5:0] ra7;
input [5:0] ra8;
output [79:0] o0;
output [79:0] o1;
output [79:0] o2;
output [79:0] o3;
output [79:0] o4;
output [79:0] o5;
output [79:0] o6;
output [79:0] o7;
output [79:0] o8;

integer n;
reg [5:0] rra0, rra1;
reg [WID-1:0] mem [0:63];
initial begin
	for (n = 0; n < 64; n = n + 1)
		mem[n] = 0;
end

wire wr = clk ? wr0 : wr1;
wire [5:0] wa = clk ? wa0 : wa1;
wire [WID-1:0] i = clk ? i0 : i1;
always @(posedge clk2x)
	if (wr) mem[wa] <= i;

assign o0 = ra0==6'd0 ? {WID{1'b0}} : ra0==wa1 ? i1 : ra0==wa0 ? i0 : mem[ra0];
assign o1 = ra1==6'd0 ? {WID{1'b0}} : ra1==wa1 ? i1 : ra1==wa0 ? i0 : mem[ra1];
assign o2 = ra2==6'd0 ? {WID{1'b0}} : ra2==wa1 ? i1 : ra2==wa0 ? i0 : mem[ra2];
assign o3 = ra3==6'd0 ? {WID{1'b0}} : ra3==wa1 ? i1 : ra3==wa0 ? i0 : mem[ra3];
assign o4 = ra4==6'd0 ? {WID{1'b0}} : ra4==wa1 ? i1 : ra4==wa0 ? i0 : mem[ra4];
assign o5 = ra5==6'd0 ? {WID{1'b0}} : ra5==wa1 ? i1 : ra5==wa0 ? i0 : mem[ra5];
assign o6 = ra6==6'd0 ? {WID{1'b0}} : ra6==wa1 ? i1 : ra6==wa0 ? i0 : mem[ra6];
assign o7 = ra7==6'd0 ? {WID{1'b0}} : ra7==wa1 ? i1 : ra7==wa0 ? i0 : mem[ra7];
assign o8 = ra8==6'd0 ? {WID{1'b0}} : ra8==wa1 ? i1 : ra8==wa0 ? i0 : mem[ra8];

endmodule
