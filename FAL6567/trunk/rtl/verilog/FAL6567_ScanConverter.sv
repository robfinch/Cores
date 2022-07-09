// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_ScanConverter.sv
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

module FAL6567_ScanConverter(chip, clken8, clk33, col80, hSync8_i, vSync8_i, color_i, hSync33_i, vSync33_i, color_o);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;

input [1:0] chip;
input clken8;
input clk33;
input col80;
input hSync8_i;
input vSync8_i;
input [3:0] color_i;
input hSync33_i;
input vSync33_i;
output reg [3:0] color_o;

(* ram_style="block" *)
reg [3:0] mem [0:274431];	// 134kB
reg [9:0] raster8X;
reg [9:0] raster8XMax = 10'd0;
reg [8:0] raster8Y = 9'd0;
reg [8:0] raster8YMax;
reg phSync8 = 1'b0, pvSync8 = 1'b0;

reg [11:0] raster33X;
reg [9:0] raster33Y;
reg [9:0] raster33YMax;
reg phSync33 = 1'b0, pvSync33 = 1'b0;

reg [3:0] color_ir;
reg [3:0] color_ou;
reg [17:0] adr8;
reg [17:0] adr33;

// Set Limits
always_ff @(posedge clk33)
case(chip)
CHIP6567R8:   raster8XMax = 10'd520;
CHIP6567OLD:  raster8XMax = 10'd512;
CHIP6569:     raster8XMax = 10'd504;
CHIP6572:     raster8XMax = 10'd504;
endcase

always_ff @(posedge clk33)
if (clken8) begin
	phSync8 <= hSync8_i;
	pvSync8 <= vSync8_i;
	if (hSync8_i && !phSync8)
		raster8X <= 10'd0;
	else
		raster8X <= raster8X + 10'd1;
	if (vSync8_i && !pvSync8)
		raster8Y <= 9'd0;
	else if (hSync8_i && !phSync8)
		raster8Y <= raster8Y + 9'd1;
end

always_ff @(posedge clk33)
begin
	phSync33 <= hSync33_i;
	pvSync33 <= vSync33_i;
	if (!hSync33_i && phSync33)
		raster33X <= 12'd0;
	else
		raster33X <= raster33X + 2'd1;
	if (!vSync33_i && pvSync33)
		raster33Y <= 10'd0;
	else if (!hSync33_i && phSync33)
		raster33Y <= raster33Y + 2'd1;
end

always_ff @(posedge clk33)
  if (clken8)
		adr8 <= raster8Y * raster8XMax + raster8X;
always_ff @(posedge clk33)
  if (clken8)
  	color_ir <= color_i;
always_ff @(posedge clk33)
  if (clken8)
    mem[adr8] <= color_ir;

always_ff @(posedge clk33)
	if (col80)
		adr33 <= raster33Y[9:1] * {raster8XMax,1'b0} + raster33X[11:0];
	else
		adr33 <= raster33Y[9:1] * raster8XMax + raster33X[11:1];
always_ff @(posedge clk33)
	color_ou <= mem[adr33];
always_ff @(posedge clk33)
	color_o <= color_ou;

endmodule
