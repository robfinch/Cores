`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD9_MMU.v
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
`define LOW     1'b0
`define HIGH    1'b1

module DSD9_mmu(rst_i, clk_i, pcr_i, s_cyc_i, s_stb_i, s_ack_o, s_wr_i, s_adr_i, s_dat_i, s_dat_o, pea_o);
input rst_i;
input clk_i;
input [31:0] pcr_i;     // paging control register
input s_cyc_i;
input s_stb_i;
input s_wr_i;             // write strobe
output reg s_ack_o;       // Address translation and MMU are ready
input [31:0] s_adr_i;    // virtual address
input [31:0] s_dat_i;
output reg [31:0] s_dat_o;
output reg [31:0] pea_o;

wire cs = s_cyc_i && s_stb_i && (s_adr_i[31:12]==20'hFFDC4);

reg [3:0] state;
wire [12:0] o0,o1;

DSD9_MMURam u1
(
    .clk(clk_i),
    .wr(cs & s_wr_i),
    .wa({pcr_i[12:8],s_adr_i[9:0]}),
    .i(s_dat_i[12:0]),
    .ra0({pcr_i[12:8],s_adr_i[9:0]}),
    .o0(o0),
    .ra1({pcr_i[4:0],s_adr_i[25:16]}),
    .o1(o1)
);

wire pe = pcr_i[31] & ~s_adr_i[31];

always @(posedge clk_i)
begin
    pea_o[15:0] <= s_adr_i[15:0];
    pea_o[27:16] <= pe ? o1[11:0] : s_adr_i[27:16];
    pea_o[31:28] <= s_adr_i[31:28];
end

endmodule

module DSD9_MMURam(clk,wr,wa,i,ra0,o0,ra1,o1);
input clk;
input wr;
input [14:0] wa;
input [12:0] i;
input [14:0] ra0;
output [12:0] o0;
input [14:0] ra1;
output [12:0] o1;

reg [12:0] mapram [0:32767];
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
