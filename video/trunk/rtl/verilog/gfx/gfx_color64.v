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

*/

module color_to_memory64(color_depth_i, color_i, x_lsb_i,
                       mem_o, sel_o);

input  [1:0]  color_depth_i;
input  [31:0] color_i;
input  [2:0]  x_lsb_i;
output [63:0] mem_o;
output reg [7:0]  sel_o;

always @*
casez({color_depth_i,x_lsb_i})
5'b00000:	sel_o <= 8'h01;
5'b00001:	sel_o <= 8'h02;
5'b00010:	sel_o <= 8'h04;
5'b00011:	sel_o <= 8'h08;
5'b00100:	sel_o <= 8'h10;
5'b00101:	sel_o <= 8'h20;
5'b00110:	sel_o <= 8'h40;
5'b00111:	sel_o <= 8'h80;
5'b0100?:	sel_o <= 8'h03;
5'b0101?:	sel_o <= 8'h0C;
5'b0110?:	sel_o <= 8'h30;
5'b0111?:	sel_o <= 8'hC0;
5'b110??:	sel_o <= 8'h0F;
5'b111??:	sel_o <= 8'hF0;
default:	sel_o <= 8'h00;
endcase

reg [5:0] shftcnt;
always @*
casez({color_depth_i,x_lsb_i})
5'b00000:	shftcnt <= 6'd0;
5'b00001:	shftcnt <= 6'd8;
5'b00010:	shftcnt <= 6'd16;
5'b00011:	shftcnt <= 6'd24;
5'b00100:	shftcnt <= 6'd32;
5'b00101:	shftcnt <= 6'd40;
5'b00110:	shftcnt <= 6'd48;
5'b00111:	shftcnt <= 6'd56;
5'b0100?:	shftcnt <= 6'd0;
5'b0101?:	shftcnt <= 6'd16;
5'b0110?: shftcnt <= 6'd32;
5'b0111?: shftcnt <= 6'd48;
5'b110??:	shftcnt <= 6'd0;
5'b111??:	shftcnt <= 6'd32;
default:	shftcnt <= 6'd0;
endcase

reg [31:0] mask;
always @*
case(color_depth_i)
2'b00:	mask <= 32'h000000FF;
2'b01:	mask <= 32'h0000FFFF;
2'b11:	mask <= 32'hFFFFFFFF;
default:	mask <= 32'h00000000;
endcase

assign mem_o = {32'd0,color_i & mask} << shftcnt;

endmodule

module memory_to_color64(color_depth_i, mem_i, mem_lsb_i,
                       color_o, sel_o);

input  [1:0]  color_depth_i;
input  [63:0] mem_i;
input  [2:0]  mem_lsb_i;
output reg [31:0] color_o;
output reg [3:0]  sel_o;

always @*
case(color_depth_i)
2'b00:	sel_o <= 4'b0001;
2'b01:	sel_o <= 4'b0011;
2'b11:	sel_o <= 4'b1111;
default:	sel_o <= 4'b0000;
endcase

reg [5:0] shftcnt;
always @*
casez({color_depth_i,mem_lsb_i})
5'b00000:	shftcnt <= 6'd0;
5'b00001:	shftcnt <= 6'd8;
5'b00010:	shftcnt <= 6'd16;
5'b00011:	shftcnt <= 6'd24;
5'b00100:	shftcnt <= 6'd32;
5'b00101:	shftcnt <= 6'd40;
5'b00110:	shftcnt <= 6'd48;
5'b00111:	shftcnt <= 6'd56;
5'b0100?:	shftcnt <= 6'd0;
5'b0101?:	shftcnt <= 6'd16;
5'b0110?: shftcnt <= 6'd32;
5'b0111?: shftcnt <= 6'd48;
5'b110??:	shftcnt <= 6'd0;
5'b111??:	shftcnt <= 6'd32;
default:	shftcnt <= 6'd0;
endcase

reg [31:0] mask;
always @*
case(color_depth_i)
2'b00:	mask <= 32'h000000FF;
2'b01:	mask <= 32'h0000FFFF;
2'b11:	mask <= 32'hFFFFFFFF;
default:	mask <= 32'h00000000;
endcase

always @*
	color_o <= (mem_i >> shftcnt) & mask;

endmodule

