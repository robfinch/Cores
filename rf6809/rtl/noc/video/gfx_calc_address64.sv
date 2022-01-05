// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================
//
// Compute the graphics address
//
import gfx_pkg::*;

module gfx_calc_address64(clk, base_address_i, color_depth_i, bmp_width_i, x_coord_i, y_coord_i,
	address_o, mb_o, me_o, ce_o);
parameter SW = 128;		// strip width in bits
parameter BN = 6;
input clk;
input [31:0] base_address_i;
input [3:0] color_depth_i;
input [15:0] bmp_width_i;	// pixel per line
input [15:0] x_coord_i;
input [15:0] y_coord_i;
output [31:0] address_o;
output [BN:0] mb_o;					// mask begin
output [BN:0] me_o;					// mask end
output [BN:0] ce_o;					// color bits end

// This coefficient is a fixed point fraction representing the inverse of the
// number of pixels per strip. The inverse (reciprocal) is used for a high
// speed divide operation.
reg [15:0] coeff;
always @(color_depth_i)
	case(color_depth_i)
	BPP6: coeff = 3120; // 1/21 * 65536
	BPP8:	coeff = 4096;	// 1/16 * 65536
	BPP12:	coeff = 6554;	// 1/10 * 65536
	BPP16:	coeff = 8192;	// 1/8 * 65536
	BPP18:	coeff = 9362;	// 1/7 * 65536
	BPP21:	coeff = 10923;	// 1/6 * 65536
	BPP24:	coeff = 13107;	// 1/5 * 65536
	BPP27:	coeff = 16384;	// 1/4 *65536
	BPP32:	coeff = 16384;	// 1/4 * 65536
	BPP33:	coeff = 21845;	// 1/3 * 65536
	default:	coeff = 8192;
	endcase

// Bits per pixel minus one.
reg [5:0] bpp;
always @(color_depth_i)
case(color_depth_i)
BPP6: bpp = 5;
BPP8:	bpp = 7;
BPP12: bpp = 11;
BPP16:	bpp = 15;
BPP18:	bpp = 17;
BPP21:	bpp = 20;
BPP24:	bpp = 23;
BPP27:	bpp = 26;
BPP32:	bpp = 31;
BPP33:	bpp = 32;
default:	bpp = 15;
endcase

// Color bits per pixel minus one.
reg [5:0] cbpp;
always @(color_depth_i)
case(color_depth_i)
BPP6: cbpp = 2;
BPP8:	cbpp = 4;
BPP12: cbpp = 8;
BPP16:	cbpp = 11;
BPP18:	cbpp = 14;
BPP21:	cbpp = 17;
BPP24:	cbpp = 20;
BPP27:	cbpp = 23;
BPP32:	cbpp = 26;
BPP33:	cbpp = 29;
default:	cbpp = 11;
endcase

// This coefficient is the number of bits used by all pixels in the strip. 
// Used to determine pixel placement in the strip.
reg [7:0] coeff2;
always @(color_depth_i)
case(color_depth_i)
BPP6: coeff2 = 126;
BPP8:	coeff2 = 128;
BPP12: coeff2 = 120;
BPP16:	coeff2 = 128;
BPP18:	coeff2 = 126;
BPP21:	coeff2 = 126;
BPP24:	coeff2 = 120;
BPP27:	coeff2 = 108;
BPP32:	coeff2 = 128;
BPP33:	coeff2 = 99;
default:	coeff2 = 128;
endcase

// Compute the fixed point horizonal strip number value. This has 16 binary
// point places.
wire [31:0] strip_num65k = x_coord_i * coeff;
// Truncate off the binary fraction to get the strip number. The strip
// number will be used to form part of the address.
wire [17:0] strip_num = strip_num65k[31:16];
// Calculate pixel position within strip using the fractional part of the
// horizontal strip number.
wire [15:0] strip_fract = strip_num65k[15:0]+16'h7F;  // +7F to round
// Pixel beginning bit is ratio of pixel # into all bits used by pixels
wire [15:0] ndx = strip_fract[15:7] * coeff2;
assign mb_o = ndx[15:9];  // Get whole pixel position (discard fraction)
assign me_o = mb_o + bpp; // Set high order position for mask
assign ce_o = mb_o + cbpp;
// num_strips is essentially a constant value unless the screen resolution changes.
// Gain performance here by regstering the multiply so that there aren't two
// cascaded multiplies when calculating the offset.
reg [31:0] num_strips65k;
always @(posedge clk)
	num_strips65k <= bmp_width_i * coeff;
wire [15:0] num_strips = num_strips65k[31:16];

wire [31:0] offset = {(({4'b0,num_strips} * y_coord_i) + strip_num),4'h0};

assign address_o = base_address_i + offset;

endmodule
