// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
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
// ============================================================================
//
module char_ram(clk_i, cs_i, we_i, adr_i, dat_i, dat_o, dot_clk_i, ce_i, char_code_i, maxscanline_i, scanline_i, bmp_o);
input clk_i;
input cs_i;
input we_i;
input [11:0] adr_i;
input [8:0] dat_i;
output reg [8:0] dat_o;
input dot_clk_i;
input ce_i;
input [8:0] char_code_i;
input [3:0] maxscanline_i;
input [3:0] scanline_i;
output reg [8:0] bmp_o;

(* ram_style="block" *)
reg [8:0] mem [0:4095];
reg [11:0] radr;
reg [11:0] rcc;
reg [8:0] dat1;
reg [8:0] bmp;

initial begin
`include "d:\\cores6\\Petajon\\v1\\rtl\\memory\\char_bitmaps.v";
end

always @(posedge clk_i)
	if (cs_i & we_i)
		mem[adr_i] <= dat_i;
always @(posedge clk_i)
	radr <= adr_i;
always @(posedge clk_i)
	dat1 <= mem[radr];
always @(posedge clk_i)
	dat_o <= dat1;

always @(posedge dot_clk_i)
	if (ce_i)
		rcc <= char_code_i*maxscanline_i+scanline_i;
always @(posedge dot_clk_i)
	bmp <= mem[rcc];
always @(posedge dot_clk_i)
	bmp_o <= bmp;

endmodule
