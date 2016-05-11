// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2016  Robert Finch, Stratford
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
// Compute the graphics address
//
module gfx_CalcAddress(clk, base_address_i, color_depth_i, hdisplayed_i, x_coord_i, y_coord_i,
	address_o, mb_o, me_o);
input clk;
input [31:0] base_address_i;
input [3:0] color_depth_i;
input [11:0] hdisplayed_i;	// pixel per line
input [11:0] x_coord_i;
input [11:0] y_coord_i;
output [31:0] address_o;
output [6:0] mb_o;
output [6:0] me_o;

parameter BPP6 = 3'd0;
parameter BPP8 = 3'd1;
parameter BPP12 = 3'd2;
parameter BPP16 = 3'd3;
parameter BPP24 = 3'd4;
parameter BPP32 = 3'd5;

// This coefficient is a fixed point fraction representing the inverse of the
// number of pixels per strip. The inverse (reciprocal) is used for a high
// speed divide operation.
reg [15:0] coeff;
always @(color_depth_i)
case(color_depth_i)
BPP6: coeff = 3121; // 1/21 * 65536
BPP8:	coeff = 4096;	// 1/16 * 65536
BPP12:	coeff = 6554;	// 1/10 * 65536
BPP16:	coeff = 8192;	// 1/8 * 65536
BPP24:	coeff = 13107;	// 1/5 * 65536
BPP32:	coeff = 16384;	// 1/4 * 65536
endcase

// Bits per pixel minus one.
reg [5:0] bpp;
always @(color_depth_i)
case(color_depth_i)
BPP6: bpp = 5;
BPP8:	bpp = 7;
BPP12:	bpp = 11;
BPP16:	bpp = 15;
BPP24:	bpp = 23;
BPP32:	bpp = 31;
endcase

// This coefficient is the number of bits used by all pixels in the strip. 
// Used to determine pixel placement in the strip.
reg [7:0] coeff2;
always @(color_depth_i)
case(color_depth_i)
BPP6: coeff2 = 126;
BPP8:	coeff2 = 128;
BPP12:	coeff2 = 120;
BPP16:	coeff2 = 128;
BPP24:	coeff2 = 120;
BPP32:	coeff2 = 128;
endcase

// Compute the fixed point horizonal strip number value. This has 16 binary
// point places.
wire [27:0] strip_num65k = x_coord_i * coeff;
// Truncate off the binary fraction to get the strip number. The strip
// number will be used to form part of the address.
wire [13:0] strip_num = strip_num65k[27:16];
// Calculate pixel position within strip using the fractional part of the
// horizontal strip number.
wire [15:0] strip_fract = strip_num65k[15:0]+16'h7F;  // +7F to round
// Pixel beginning bit is ratio of pixel # into all bits used by pixels
wire [15:0] ndx = strip_fract[15:7] * coeff2;
assign mb_o = ndx[15:9];  // Get whole pixel position (discard fraction)
assign me_o = mb_o + bpp; // Set high order position for mask
// num_strips is essentially a constant value unless the screen resolution changes.
// Gain performance here by regstering the multiply so that there aren't two
// cascaded multiplies when calculating the offset.
reg [27:0] num_strips65k;
always @(posedge clk)
	num_strips65k <= hdisplayed_i * coeff;
wire [11:0] num_strips = num_strips65k[27:16];

wire [31:0] offset = {(({4'b0,num_strips} * y_coord_i) + strip_num),4'h0};
assign address_o = base_address_i + offset;

endmodule
