// ============================================================================
//        __
//   \\__/ o\    (C) 2015  Robert Finch, Stratford
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
//	Verilog 1995
//
// ref: XC7a100t-1CSG324
// ============================================================================
//
module gfx_SplitColorR(color_depth_i, color_i, color_o);
input [2:0] color_depth_i;
input [31:0] color_i;
output reg [7:0] color_o;
parameter BPP6 = 3'd0;
parameter BPP8 = 3'd1;
parameter BPP9 = 3'd2;
parameter BPP12 = 3'd3;
parameter BPP15 = 3'd4;
parameter BPP16 = 3'd5;
parameter BPP24 = 3'd6;
parameter BPP32 = 3'd7;

always @(color_depth_i or color_i)
case(color_depth_i)
BPP6:	color_o = color_i[5:0];
BPP8:	color_o = color_i[7:0];
BPP9:	color_o = color_i[8:6];
BPP12:	color_o = color_i[11:8];
BPP15:	color_o = color_i[14:10];
BPP16:	color_o = color_i[15:11];
BPP24:	color_o = color_i[23:16];
BPP32:	color_o = color_i[23:16];
endcase
endmodule

module gfx_SplitColorG(color_depth_i, color_i, color_o);
input [2:0] color_depth_i;
input [31:0] color_i;
output reg [7:0] color_o;
parameter BPP6 = 3'd0;
parameter BPP8 = 3'd1;
parameter BPP9 = 3'd2;
parameter BPP12 = 3'd3;
parameter BPP15 = 3'd4;
parameter BPP16 = 3'd5;
parameter BPP24 = 3'd6;
parameter BPP32 = 3'd7;

always @(color_depth_i or color_i)
case(color_depth_i)
BPP6:	color_o = color_i[5:0];
BPP8:	color_o = color_i[7:0];
BPP9:	color_o = color_i[5:3];
BPP12:	color_o = color_i[7:4];
BPP15:	color_o = color_i[9:5];
BPP16:	color_o = color_i[10:5];
BPP24:	color_o = color_i[15:8];
BPP32:	color_o = color_i[15:8];
endcase
endmodule

module gfx_SplitColorB(color_depth_i, color_i, color_o);
input [2:0] color_depth_i;
input [31:0] color_i;
output reg [7:0] color_o;
parameter BPP6 = 3'd0;
parameter BPP8 = 3'd1;
parameter BPP9 = 3'd2;
parameter BPP12 = 3'd3;
parameter BPP15 = 3'd4;
parameter BPP16 = 3'd5;
parameter BPP24 = 3'd6;
parameter BPP32 = 3'd7;

always @(color_depth_i or color_i)
case(color_depth_i)
BPP6:	color_o = color_i[5:0];
BPP8:	color_o = color_i[7:0];
BPP9:	color_o = color_i[2:0];
BPP12:	color_o = color_i[3:0];
BPP15:	color_o = color_i[4:0];
BPP16:	color_o = color_i[4:0];
BPP24:	color_o = color_i[7:0];
BPP32:	color_o = color_i[7:0];
endcase
endmodule

