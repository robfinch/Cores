`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_MMU.v
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

module FT64_mmu(rst_i, clk_i, ol_i, pcr_i, pcr2_i, mapen_i, s_ex_i, s_cyc_i, s_stb_i, s_ack_o, s_wr_i, s_adr_i, s_dat_i, s_dat_o,
    pea_o, cyc_o, stb_o,
    exv_o, rdv_o, wrv_o);
input rst_i;
input clk_i;
input [2:0] ol_i;
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
output reg cyc_o;
output reg stb_o;
output reg exv_o;       // execute violation
output reg rdv_o;       // read violation
output reg wrv_o;       // write violation

wire cs = s_cyc_i && s_stb_i && (s_adr_i[31:12]==20'hFFDC4);
wire [5:0] okey = pcr_i[5:0];
wire [5:0] akey = pcr_i[13:8];
wire mol = ol_i==3'b000; // machine operating level

reg ack1, ack2, ack3;
always @(posedge clk_i)
    ack1 <= cs;
always @(posedge clk_i)
    ack2 <= ack1 & (cs);
assign s_ack_o = (cs) ? ack2 : 1'b0;

reg cyc1,cyc2,stb1,stb2;
wire [20:0] douta,doutb;
wire [20:0] doutca;
wire [2:0] cwrx = doutb[18:16];

always @(posedge clk_i)
    exv_o <= s_ex_i & ~cwrx[0] & cyc2 & stb2 & mapen_i;
always @(posedge clk_i)
    rdv_o <= ~(s_wr_i | s_ex_i) & ~cwrx[1] & cyc2 & stb2 & mapen_i;
always @(posedge clk_i)
    wrv_o <= s_wr_i & ~cwrx[2] & cyc2 & stb2 & mapen_i;

wire [15:0] addra = {akey,s_adr_i[11:2]};
wire [15:0] addrb = pcr2_i[okey] ? {okey,s_adr_i[28:19]} :
                         {okey,s_adr_i[22:13]};

FT64_MMURam1 u1 (
  .clka(clk_i),    // input wire clka
  .ena(cs),      // input wire ena
  .wea(cs & s_wr_i),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [15 : 0] addra
  .dina(s_dat_i[20:0]),    // input wire [12 : 0] dina
  .douta(douta),
  .clkb(clk_i),    // input wire clkb
  .enb(mapen_i),  // input wire enb
  .web(1'b0),
  .addrb(addrb),  // input wire [13 : 0] addrb
  .dinb(21'h0),
  .doutb(doutb)  // output wire [51 : 0] doutb
);

assign s_dat_o = {11'd0,douta};

// The following delay reg is to keep all the address bits in sync
// with the output of the map table. So there are no intermediate
// invalid addresses.
reg mapen1, mapen2;
reg [31:0] s_adr1, s_adr2;
reg _4MB1, _4MB2;
always @(posedge clk_i)
    s_adr1 <= s_adr_i;
always @(posedge clk_i)
    s_adr2 <= s_adr1;
always @(posedge clk_i)
    _4MB1 <= pcr2_i[okey];
always @(posedge clk_i)
    _4MB2 <= _4MB1 | !mapen1;
always @(posedge clk_i)
    mapen1 <= !mol && mapen_i && (s_adr_i[31:29]==3'h0);
always @(posedge clk_i)
    mapen2 <= mapen1;
always @(posedge clk_i)
    cyc1 <= s_cyc_i;
always @(posedge clk_i)
    cyc2 <= cyc1 & s_cyc_i;
always @(posedge clk_i)
    stb1 <= s_stb_i;
always @(posedge clk_i)
    stb2 <= stb1 & s_stb_i;    

always @(posedge clk_i)
if (rst_i) begin
    cyc_o <= 1'b0;
    stb_o <= 1'b0;
    pea_o <= 32'hFFFC0100;
end
else begin
    pea_o[12:0] <= s_adr2[12:0];
    pea_o[18:13] <= mapen2 ? (_4MB2 ? s_adr2[18:13] : doutb[5:0]) : s_adr2[18:13];
    pea_o[28:19] <= mapen2 ? doutb[15:6] : s_adr2[28:19];
    pea_o[31:29] <= s_adr2[31:29];
    cyc_o <= cyc2 & s_cyc_i;
    stb_o <= stb2 & s_stb_i;
end

endmodule
