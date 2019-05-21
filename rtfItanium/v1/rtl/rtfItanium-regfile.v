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
module Regfile(clk, wr, wa, i,
	ra0, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8,
	o0, o1, o2, o3, o4, o5, o6 ,o7, o8);
parameter WID = 80;
input clk;
input wr;
input [5:0] wa;
input [79:0] i;
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

reg [5:0] rra0, rra1;
reg [WID-1:0] mem [0:63];

always @(posedge clk)
	if (wr) mem[wa] <= i;

assign o0 = ra0==6'd0 ? ra0==wa ? i : {WID{1'b0}} : mem[ra0];
assign o1 = ra1==6'd0 ? ra1==wa ? i : {WID{1'b0}} : mem[ra1];
assign o2 = ra2==6'd0 ? ra2==wa ? i : {WID{1'b0}} : mem[ra2];
assign o3 = ra3==6'd0 ? ra3==wa ? i : {WID{1'b0}} : mem[ra3];
assign o4 = ra4==6'd0 ? ra4==wa ? i : {WID{1'b0}} : mem[ra4];
assign o5 = ra5==6'd0 ? ra5==wa ? i : {WID{1'b0}} : mem[ra5];
assign o6 = ra6==6'd0 ? ra6==wa ? i : {WID{1'b0}} : mem[ra6];
assign o7 = ra7==6'd0 ? ra7==wa ? i : {WID{1'b0}} : mem[ra7];
assign o8 = ra8==6'd0 ? ra8==wa ? i : {WID{1'b0}} : mem[ra8];

endmodule
