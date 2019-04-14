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

input  [2:0]  color_depth_i;
input  [31:0] color_i;
input  [2:0]  x_lsb_i;
output [63:0] mem_o;
output reg [7:0]  sel_o;

always @*
casez({color_depth_i,x_lsb_i})
6'b001000:	sel_o <= 8'h01;
6'b001001:	sel_o <= 8'h02;
6'b001010:	sel_o <= 8'h04;
6'b001011:	sel_o <= 8'h08;
6'b001100:	sel_o <= 8'h10;
6'b001101:	sel_o <= 8'h20;
6'b001110:	sel_o <= 8'h40;
6'b001111:	sel_o <= 8'h80;
6'b01100?:	sel_o <= 8'h03;
6'b01101?:	sel_o <= 8'h0C;
6'b01110?:	sel_o <= 8'h30;
6'b01111?:	sel_o <= 8'hC0;
6'b1110??:	sel_o <= 8'h0F;
6'b1111??:	sel_o <= 8'hF0;
default:	sel_o <= 8'h00;
endcase

reg [5:0] shftcnt;
always @*
casez({color_depth_i,x_lsb_i})
6'b001000:	shftcnt <= 6'd0;
6'b001001:	shftcnt <= 6'd8;
6'b001010:	shftcnt <= 6'd16;
6'b001011:	shftcnt <= 6'd24;
6'b001100:	shftcnt <= 6'd32;
6'b001101:	shftcnt <= 6'd40;
6'b001110:	shftcnt <= 6'd48;
6'b001111:	shftcnt <= 6'd56;
6'b01100?:	shftcnt <= 6'd0;
6'b01101?:	shftcnt <= 6'd16;
6'b01110?:  shftcnt <= 6'd32;
6'b01111?:  shftcnt <= 6'd48;
6'b1110??:	shftcnt <= 6'd0;
6'b1111??:	shftcnt <= 6'd32;
default:	shftcnt <= 6'd0;
endcase

reg [31:0] mask;
always @*
case(color_depth_i)
3'd0:		mask <= 32'h0000000F;
3'd1:		mask <= 32'h000000FF;
3'd2:		mask <= 32'h00000FFF;
3'd3:		mask <= 32'h0000FFFF;
3'd4:		mask <= 32'h000FFFFF;
3'd7:		mask <= 32'hFFFFFFFF;
default:	mask <= 32'h00000000;
endcase

assign mem_o = {32'd0,color_i & mask} << shftcnt;

endmodule

module memory_to_color64(color_depth_i, mem_i, mem_lsb_i,
                       color_o, sel_o);

input  [2:0]  color_depth_i;
input  [63:0] mem_i;
input  [2:0]  mem_lsb_i;
output reg [31:0] color_o;
output reg [3:0]  sel_o;

always @*
case(color_depth_i)
3'd1:		sel_o <= 4'b0001;
3'd3:		sel_o <= 4'b0011;
3'd7:		sel_o <= 4'b1111;
default:	sel_o <= 4'b0000;
endcase

reg [5:0] shftcnt;
always @*
casez({color_depth_i,mem_lsb_i})
6'b001000:	shftcnt <= 6'd0;
6'b001001:	shftcnt <= 6'd8;
6'b001010:	shftcnt <= 6'd16;
6'b001011:	shftcnt <= 6'd24;
6'b001100:	shftcnt <= 6'd32;
6'b001101:	shftcnt <= 6'd40;
6'b001110:	shftcnt <= 6'd48;
6'b001111:	shftcnt <= 6'd56;
6'b01100?:	shftcnt <= 6'd0;
6'b01101?:	shftcnt <= 6'd16;
6'b01110?: 	shftcnt <= 6'd32;
6'b01111?: 	shftcnt <= 6'd48;
6'b1110??:	shftcnt <= 6'd0;
6'b1111??:	shftcnt <= 6'd32;
default:	shftcnt <= 6'd0;
endcase

reg [31:0] mask;
always @*
case(color_depth_i)
3'd0:		mask <= 32'h0000000F;
3'd1:		mask <= 32'h000000FF;
3'd2:		mask <= 32'h00000FFF;
3'd3:		mask <= 32'h0000FFFF;
3'd4:		mask <= 32'h000FFFFF;
3'd7:		mask <= 32'hFFFFFFFF;
default:	mask <= 32'h00000000;
endcase

always @*
	color_o <= (mem_i >> shftcnt) & mask;

endmodule

