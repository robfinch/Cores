// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
//	FAL6567_SRamScanConverter.v
//  - this version of the scan converter stores the scan data in the 
//    sram rather than internal block ram.
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
module FAL6567_SRamScanConverter(chip, clken8, clk33, turbo2, hSync8_i, vSync8_i, color_i, hSync33_i, vSync33_i, color_o,
	ram_wadr, ram_dato, ram_radr, ram_dati, ram_rlatch
	);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;

input [1:0] chip;
input clken8;
input clk33;
input turbo2;
input hSync8_i;
input vSync8_i;
input [3:0] color_i;
input hSync33_i;
input vSync33_i;
output reg [3:0] color_o;
output reg [18:0] ram_wadr;
output reg [7:0] ram_dato;
output reg [18:0] ram_radr;
input [7:0] ram_dati;
input ram_rlatch;

reg [9:0] raster8X;
reg [9:0] raster8XMax;
reg [8:0] raster8Y;
reg [8:0] raster8YMax;
reg phSync8, pvSync8;

reg [10:0] raster33X;
reg [9:0] raster33Y;
reg [9:0] raster33YMax;
reg phSync33, pvSync33;

// Set Limits
always @*
if (turbo2)
case(chip)
CHIP6567R8:   raster8XMax = 10'd606;
CHIP6567OLD:  raster8XMax = 10'd606;
CHIP6569:     raster8XMax = 10'd640;
CHIP6572:     raster8XMax = 10'd640;
endcase
else
case(chip)
CHIP6567R8:   raster8XMax = 10'd520;
CHIP6567OLD:  raster8XMax = 10'd512;
CHIP6569:     raster8XMax = 10'd504;
CHIP6572:     raster8XMax = 10'd504;
endcase

always @(posedge clk33)
begin
	ram_wadr <= raster8Y * raster8XMax + raster8X;
	ram_wadr[18] <= 1'b1;
end
always @(posedge clk33)
	ram_dato <= color_i;
always @(posedge clk33) begin
	ram_radr <= raster33Y[9:1] * raster8XMax + raster33X[10:1];
	ram_radr[18] <= 1'b1;
end
initial begin
	  phSync8 = 1'b0;
	  pvSync8 = 1'b0;
	  phSync33 = 1'b1;
	  pvSync33 = 1'b1;
	  raster8X = 10'd0;
	  raster8Y = 9'd0;
end
always @(posedge clk33)
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

always @(posedge clk33)
begin
	phSync33 <= hSync33_i;
	pvSync33 <= vSync33_i;
	if (!hSync33_i && phSync33)
		raster33X <= 10'd0;
	else
		raster33X <= raster33X + 10'd1;
	if (!vSync33_i && pvSync33)
		raster33Y <= 10'd0;
	else if (!hSync33_i && phSync33)
		raster33Y <= raster33Y + 10'd1;
end

always @(posedge clk33)
	if (ram_rlatch)
		color_o <= ram_dati[3:0];

endmodule
