// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567i_ScanConverter.sv
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
// Requires 67kB of block RAM          
// ============================================================================

module FAL6567i_ScanConverter(chip, clk8, clk40, col80, hSync8_i, vSync8_i, color_i, hSync40_i, vSync40_i, color_o);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;

input [1:0] chip;
input clk8;
input clk40;
input col80;
input hSync8_i;
input vSync8_i;
input [3:0] color_i;
input hSync40_i;
input vSync40_i;
output reg [3:0] color_o;

(* ram_style="block" *)
reg [3:0] mem [0:278527];	// 136kB
reg [10:0] raster8X;
reg [10:0] raster8XMax = 10'd0;
reg [8:0] raster8Y = 9'd0;
reg [8:0] raster8YMax;
reg phSync8 = 1'b0, pvSync8 = 1'b0;

reg [11:0] raster40X;
reg [9:0] raster40Y;
reg [9:0] raster40YMax;
reg phSync40 = 1'b0, pvSync40 = 1'b0;

reg [3:0] color_ir;
reg [3:0] color_ou;
reg [17:0] adr8;
reg [17:0] adr40;

// Set Limits
// The limits are set a little bit high (+8 clocks)
always_ff @(posedge clk8)
if (col80)
	case(chip)
	CHIP6567R8:   raster8XMax = 11'd1048;
	CHIP6567OLD:  raster8XMax = 11'd1032;
	CHIP6569:     raster8XMax = 11'd1016;
	CHIP6572:     raster8XMax = 11'd1016;
	endcase
else
	case(chip)
	CHIP6567R8:   raster8XMax = 11'd528;
	CHIP6567OLD:  raster8XMax = 11'd520;
	CHIP6569:     raster8XMax = 11'd512;
	CHIP6572:     raster8XMax = 11'd512;
	endcase

always_ff @(posedge clk8)
begin
	phSync8 <= hSync8_i;
	pvSync8 <= vSync8_i;
	if (hSync8_i && !phSync8)
		raster8X <= 11'd0;
	else
		raster8X <= raster8X + 2'd1;
	if (vSync8_i && !pvSync8)
		raster8Y <= 9'd0;
	else if (hSync8_i && !phSync8)
		raster8Y <= raster8Y + 2'd1;
end

always_ff @(posedge clk40)
begin
	phSync40 <= hSync40_i;
	pvSync40 <= vSync40_i;
	if (!hSync40_i && phSync40)
		raster40X <= 12'd0;
	else
		raster40X <= raster40X + 2'd1;
	if (!vSync40_i && pvSync40)
		raster40Y <= 10'd0;
	else if (!hSync40_i && phSync40)
		raster40Y <= raster40Y + 2'd1;
end

always_ff @(posedge clk8)
	adr8 <= raster8Y * raster8XMax + raster8X;
always_ff @(posedge clk8)
 	color_ir <= color_i;
always_ff @(posedge clk8)
  mem[adr8] <= color_ir;

always_ff @(posedge clk40)
	if (col80)
		adr40 <= raster40Y[9:1] * raster8XMax + raster40X[11:0];
	else
		adr40 <= raster40Y[9:1] * raster8XMax + raster40X[11:1];
always_ff @(posedge clk40)
	color_ou <= mem[adr40];
always_ff @(posedge clk40)
	color_o <= color_ou;

endmodule
