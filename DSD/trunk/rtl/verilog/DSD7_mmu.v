`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD7_MMU.v
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
//
// ============================================================================
//
module DSD7_mmu(clk_i, pcr_i, vpa_i, vda_i, rdy_o, wr_i, vadr_i, padr_o, dat_i, dat_o, vpa_o, vda_o, wr_o);
input clk_i;
input [31:0] pcr_i;     // paging control register
input vpa_i;            // valid program address
input vda_i;            // valid data address
input wr_i;             // write strobe
output rdy_o;           // Address translation and MMU are ready
input [31:0] vadr_i;    // virtual address
output [31:0] padr_o;   // physical address
input [31:0] dat_i;
output [31:0] dat_o;
output vpa_o;
output vda_o;
output wr_o;

wire cs = vda_i && (vadr_i[31:12]==20'hFFDC4);

wire [12:0] o0,o1;

DSD7_MMURam u1
(
    .clk(clk_i),
    .wr(cs & wr_i),
    .wa({pcr_i[12:8],vadr_i[8:0]}),
    .i(dat_i[12:0]),
    .ra0({pcr_i[12:8],vadr_i[8:0]}),
    .o0(o0),
    .ra1({pcr_i[4:0],vadr_i[24:16]}),
    .o1(o1)
);

assign dat_o = cs ? {2{3'b0,o0}} : 32'd0;

wire pe = pcr_i[31] & ~vadr_i[31];

reg vpa_d;
reg vda_d;
always @(posedge clk_i)
begin
    vpa_d <= vpa_i;
    vda_d <= vda_i;
end
assign vpa_o = pe ? vpa_d : vpa_i;
assign vda_o = pe ? vda_d : vda_i;

assign padr_o[15:0] = vadr_i[15:0];
assign padr_o[27:16] = pe ? o1[11:0] : vadr_i[27:16];
assign padr_o[31:28] = vadr_i[31:28];

assign wr_o = wr_i & (pe ? o1[12] : 1'b1);

// Create a one cycle delayed ready signal.
assign rdy_o = (cs & wr_i) ? 1'b1 : (vpa_i & vpa_o) | (vda_i & vda_o);

endmodule

module DSD7_MMURam(clk,wr,wa,i,ra0,o0,ra1,o1);
input clk;
input wr;
input [13:0] wa;
input [12:0] i;
input [13:0] ra0;
output [12:0] o0;
input [13:0] ra1;
output [12:0] o1;

reg [12:0] mapram [0:16383];
reg [13:0] rra0,rra1;

always @(posedge clk)
    if (wr)
        mapram[wa] <= i;

always @(posedge clk)
    rra0 <= ra0;
assign o0 = mapram[rra0];
always @(posedge clk)
    rra1 <= ra1;
assign o1 = mapram[rra1];

endmodule
