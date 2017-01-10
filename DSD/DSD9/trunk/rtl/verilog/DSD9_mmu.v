`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2017  Robert Finch, Waterloo
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

module DSD9_mmu(rst_i, clk_i, ol_i, pcr_i, pcr2_i, mapen_i, s_ex_i, s_cyc_i, s_stb_i, s_ack_o, s_wr_i, s_adr_i, s_dat_i, s_dat_o, pea_o,
    exv_o, rdv_o, wrv_o);
input rst_i;
input clk_i;
input [1:0] ol_i;
input [31:0] pcr_i;     // paging enabled
input [63:0] pcr2_i;
input mapen_i;
input s_ex_i;           // executable address
input s_cyc_i;
input s_stb_i;
input s_wr_i;           // write strobe
output s_ack_o;
input [31:0] s_adr_i;    // virtual address
input [31:0] s_dat_i;
output [31:0] s_dat_o;
output reg [31:0] pea_o;
output reg exv_o;       // execute violation
output reg rdv_o;       // read violation
output reg wrv_o;       // write violation

wire cs = s_cyc_i && s_stb_i && (s_adr_i[31:12]==20'hFFDC4);
wire [5:0] okey = pcr_i[5:0];
wire [5:0] akey = pcr_i[13:8];

reg ack1, ack2;
always @(posedge clk_i)
    ack1 <= cs;
always @(posedge clk_i)
    ack2 <= ack1 & (cs);
assign s_ack_o = (cs) ? ack2 : 1'b0;

wire [18:0] doutb;
wire [18:0] doutca;
wire [2:0] cwrx = doutb[18:16];

always @*
    exv_o <= s_ex_i & ~cwrx[0] & s_cyc_i & s_stb_i;
always @*
    rdv_o <= ~(s_wr_i | s_ex_i) & ~cwrx[1] & s_cyc_i & s_stb_i;
always @*
    wrv_o <= s_wr_i & ~cwrx[2] & s_cyc_i & s_stb_i;

wire [15:0] addra = {akey,s_adr_i[11:2]};
wire [15:0] addrb = cs ? {akey,s_adr_i[11:2]} :
                    pcr2_i[okey] ? {okey,s_adr_i[31:22]} :
                         {okey,s_adr_i[25:16]};

DSD9_MMURam1 u1 (
  .clka(clk_i),    // input wire clka
  .ena(cs),      // input wire ena
  .wea(cs & s_wr_i),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [15 : 0] addra
  .dina(s_dat_i[18:0]),    // input wire [12 : 0] dina
  .clkb(clk_i),    // input wire clkb
  .enb(mapen_i),  // input wire enb
  .addrb(addrb),  // input wire [13 : 0] addrb
  .doutb(doutb)  // output wire [51 : 0] doutb
);

assign s_dat_o = {12'd0,doutb};

// The following delay reg is to keep all the address bits in sync
// with the output of the map table. So there are no intermediate
// invalid addresses.
reg [31:0] s_adr1, s_adr2;
reg _4MB1, _4MB2;
always @(posedge clk_i)
    s_adr1 <= s_adr_i;
always @(posedge clk_i)
    s_adr2 <= s_adr1;
always @(posedge clk_i)
    _4MB1 <= pcr2_i[okey];
always @(posedge clk_i)
    _4MB2 <= _4MB1;

always @(s_adr2 or doutb or _4MB2)
begin
    pea_o[15:0] <= s_adr2[15:0];
    pea_o[21:16] <= _4MB2 ? s_adr2[21:16] : doutb[5:0];
    pea_o[31:22] <= doutb[15:6];
end

endmodule
