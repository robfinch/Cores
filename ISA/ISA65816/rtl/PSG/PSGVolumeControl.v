`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	PSGVolumeControl.v 
//		Controls the PSG's output volume.
// The volume control is made non-linear with a ROM lookup table based on
// an increment similar to Fibonnaci series.
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
//=============================================================================

module PSGVolumeControl(rst_i, clk_i, i, volume, o);
input rst_i;
input clk_i;
input [21:0] i;
input [3:0] volume;
output [29:0] o;
reg [29:0] o;

// This ROM lookup table to delinearize the volume control.
// Uses mangled Fibonnaci series.
reg [7:0] vol;
always @*
case(volume)
4'd00:  vol = 8'd00;
4'd01:  vol = 8'd01;
4'd03:  vol = 8'd01;
4'd04:  vol = 8'd02;
4'd05:  vol = 8'd03;
4'd06:  vol = 8'd05;
4'd07:  vol = 8'd08;
4'd09:  vol = 8'd13;
4'd10:  vol = 8'd21;
4'd11:  vol = 8'd34;
4'd12:  vol = 8'd56;
4'd13:  vol = 8'd90;
4'd14:  vol = 8'd151;   
4'd15:  vol = 8'd255;
endcase
always @(posedge clk_i)
if (rst_i)
    o <= 26'b0;		// Force the output volume to zero on reset
else
    o <= i * vol;

endmodule
