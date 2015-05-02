/*
ORSoC GFX accelerator core
Copyright 2012, ORSoC, Per Lenander, Anton Fosselius.

Components for aligning colored pixels to memory and the inverse

 This file is part of orgfx.

 orgfx is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version. 

 orgfx is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License
 along with orgfx.  If not, see <http://www.gnu.org/licenses/>.

 Robert Finch:
 Modified memory_to_color to do a bitfield extract of color data.
 color_to_memory no longer used. This is now handled by a bitfield
 insert in the writer module.
*/

module color_to_memory(color_depth_i, color_i, x_lsb_i,
                       mem_o, sel_o);

input  [1:0]  color_depth_i;
input  [31:0] color_i;
input  [1:0]  x_lsb_i;
output [31:0] mem_o;
output [3:0]  sel_o;

assign sel_o = (color_depth_i == 2'b00) && (x_lsb_i == 2'b00) ? 4'b1000 : // 8-bit
               (color_depth_i == 2'b00) && (x_lsb_i == 2'b01) ? 4'b0100 : // 8-bit
               (color_depth_i == 2'b00) && (x_lsb_i == 2'b10) ? 4'b0010 : // 8-bit
               (color_depth_i == 2'b00) && (x_lsb_i == 2'b11) ? 4'b0001 : // 8-bit
               (color_depth_i == 2'b01) && (x_lsb_i[0] == 1'b0)  ? 4'b1100  : // 16-bit, high word
               (color_depth_i == 2'b01) && (x_lsb_i[0] == 1'b1)  ? 4'b0011  : // 16-bit, low word
               4'b1111; // 32-bit

assign mem_o = (color_depth_i == 2'b00) && (x_lsb_i == 2'b00) ? {color_i[7:0], 24'h000000} : // 8-bit
               (color_depth_i == 2'b00) && (x_lsb_i == 2'b01) ? {color_i[7:0], 16'h0000}   : // 8-bit
               (color_depth_i == 2'b00) && (x_lsb_i == 2'b10) ? {color_i[7:0], 8'h00}      : // 8-bit
               (color_depth_i == 2'b00) && (x_lsb_i == 2'b11) ? {color_i[7:0]}             : // 8-bit
               (color_depth_i == 2'b01) && (x_lsb_i[0] == 1'b0)  ? {color_i[15:0], 16'h0000}   : // 16-bit, high word
               (color_depth_i == 2'b01) && (x_lsb_i[0] == 1'b1)  ? {color_i[15:0]}             : // 16-bit, low word
               color_i; // 32-bit

endmodule

// do a bitfield extract of color data
module memory_to_color(mem_i, mb_i, me_i, color_o);

input  [127:0] mem_i;
input [6:0] mb_i;
input [6:0] me_i;
output reg [31:0] color_o;

reg [127:0] mask;
reg [127:0] o1;
integer nn,n;
always @(mb_i or me_i or nn)
	for (nn = 0; nn < 128; nn = nn + 1)
		mask[nn] <= (nn >= mb_i) ^ (nn <= me_i) ^ (me_i >= mb_i);
always @*
begin
	for (n = 0; n < 128; n = n + 1)
		o1[n] = mask[n] ? mem_i[n] : 1'b0;
	color_o <= o1 >> mb_i;
end

endmodule

