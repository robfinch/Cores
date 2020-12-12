// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rtf64-tlb.sv
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

import rtf64configpkg::*;

module rtf64_TLB(rst_i, clk_i, asid_i, umode_i,xlaten_i,we_i,ladr_i,iacc_i,iadr_i,padr_o,acr_o,tlben_i,wrtlb_i,tlbadr_i,tlbdat_i,tlbdat_o,tlbmiss_o);
parameter AWID=32;
parameter RSTIP = 64'hFFFFFFFFFFFC0200;
input rst_i;
input clk_i;
input [7:0] asid_i;
input umode_i;
input xlaten_i;
input we_i;
input [AWID-1:0] ladr_i;
input iacc_i;
input [AWID-1:0] iadr_i;
output reg [AWID-1:0] padr_o;
output reg [3:0] acr_o;
input tlben_i;
input wrtlb_i;
input [11:0] tlbadr_i;
input [63:0] tlbdat_i;
output reg [63:0] tlbdat_o;
output reg tlbmiss_o;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

wire [AWID-1:0] rstip = RSTIP;
reg [63:0] tadri0, tadri1, tadri2, tadri3;
reg wr0,wr1,wr2,wr3, wed;
reg hit0,hit1,hit2,hit3;
wire tlbwr1 = tlbadr_i[11:10]==2'd0 && wrtlb_i;
wire tlbwr2 = tlbadr_i[11:10]==2'd1 && wrtlb_i;
wire tlbwr3 = tlbadr_i[11:10]==2'd2 && wrtlb_i;
wire tlbwr4 = tlbadr_i[11:10]==2'd3 && wrtlb_i;
wire [63:0] tlbdato1,tlbdato2,tlbdato3,tlbdato4;
wire [63:0] tadr0, tadr1, tadr2, tadr3;
wire clk_g = clk_i;
always @*
case(tlbadr_i[11:10])
2'd0: tlbdat_o <= tlbdato1;
2'd1: tlbdat_o <= tlbdato2;
2'd2: tlbdat_o <= tlbdato3;
2'd3: tlbdat_o <= tlbdato4;
endcase

wire xlatd;
delay #(.WID(1), .DEP(2)) udl1 (.clk(clk_g), .ce(1'b1), .i(xlaten_i), .o(xlatd));
/*
wire pe_xlat, ne_xlat;
edge_det u5 (
  .rst(rst_i),
  .clk(clk_g),
  .ce(1'b1),
  .i(xlaten_i),
  .pe(pe_xlat),
  .ne(ne_xlat),
  .ee()
);
*/

// Dirty / Accessed bit write logic
always @(posedge clk_g)
  wed <= we_i;
always @(posedge clk_g)
begin
  wr0 <= 1'b0;
  wr1 <= 1'b0;
  wr2 <= 1'b0;
  wr3 <= 1'b0;
  if (xlatd) begin
    if (hit0) begin
      tadri0 <= {tadr0[63:55],wed,1'b1,tadr0[52:0]};
      wr0 <= 1'b1;
    end
    if (hit1) begin
      tadri1 <= {tadr1[63:55],wed,1'b1,tadr1[52:0]};
      wr1 <= 1'b1;
    end
    if (hit2) begin
      tadri2 <= {tadr2[63:55],wed,1'b1,tadr2[52:0]};
      wr2 <= 1'b1;
    end
    if (hit3) begin
      tadri3 <= {tadr3[63:55],wed,1'b1,tadr3[52:0]};
      wr3 <= 1'b1;
    end
  end
end

TLBRam u1 (
  .clka(clk_g),    // input wire clka
  .ena(tlben_i),      // input wire ena
  .wea(tlbwr1),      // input wire [0 : 0] wea
  .addra(tlbadr_i[9:0]),  // input wire [9 : 0] addra
  .dina(tlbdat_i),    // input wire [63 : 0] dina
  .douta(tlbdato1),  // output wire [63 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(xlaten_i|wr0),      // input wire enb
  .web(wr0),      // input wire [0 : 0] web
  .addrb(ladr_i[23:14]),  // input wire [9 : 0] addrb
  .dinb(tadri0),    // input wire [63 : 0] dinb
  .doutb(tadr0)  // output wire [63 : 0] doutb
);

TLBRam u2 (
  .clka(clk_g),    // input wire clka
  .ena(tlben_i),      // input wire ena
  .wea(tlbwr2),      // input wire [0 : 0] wea
  .addra(tlbadr_i[9:0]),  // input wire [9 : 0] addra
  .dina(tlbdat_i),    // input wire [63 : 0] dina
  .douta(tlbdato2),  // output wire [63 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(xlaten_i|wr1),      // input wire enb
  .web(wr1),      // input wire [0 : 0] web
  .addrb(ladr_i[23:14]),  // input wire [9 : 0] addrb
  .dinb(tadri1),    // input wire [63 : 0] dinb
  .doutb(tadr1)  // output wire [63 : 0] doutb
);

TLBRam u3 (
  .clka(clk_g),    // input wire clka
  .ena(tlben_i),      // input wire ena
  .wea(tlbwr3),      // input wire [0 : 0] wea
  .addra(tlbadr_i[9:0]),  // input wire [9 : 0] addra
  .dina(tlbdat_i),    // input wire [63 : 0] dina
  .douta(tlbdato3),  // output wire [63 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(xlaten_i|wr2),      // input wire enb
  .web(wr2),      // input wire [0 : 0] web
  .addrb(ladr_i[23:14]),  // input wire [9 : 0] addrb
  .dinb(tadri2),    // input wire [63 : 0] dinb
  .doutb(tadr2)  // output wire [63 : 0] doutb
);

TLBRam u4 (
  .clka(clk_g),    // input wire clka
  .ena(tlben_i),      // input wire ena
  .wea(tlbwr4),      // input wire [0 : 0] wea
  .addra(tlbadr_i[9:0]),  // input wire [9 : 0] addra
  .dina(tlbdat_i),    // input wire [63 : 0] dina
  .douta(tlbdato4),  // output wire [63 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(xlaten_i|wr3),      // input wire enb
  .web(wr3),      // input wire [0 : 0] web
  .addrb(ladr_i[23:14]),  // input wire [9 : 0] addrb
  .dinb(tadri3),    // input wire [63 : 0] dinb
  .doutb(tadr3)  // output wire [63 : 0] doutb
);

always @(posedge clk_g)
if (rst_i)
  padr_o[13:0] <= rstip[13:0];
else
  padr_o[13:0] <= iacc_i ? iadr_i[13:0] : ladr_i[13:0];

always @(posedge clk_g)
if (rst_i) begin
  padr_o[AWID-1:14] <= rstip[AWID-1:14];
end
else begin
  if (xlaten_i) begin
    hit0 <= 1'b0;
    hit1 <= 1'b0;
    hit2 <= 1'b0;
    hit3 <= 1'b0;
  end
  if (iacc_i) begin
    padr_o[AWID-1:14] <= iadr_i[AWID-1:14];
  end
  else if (!umode_i || ladr_i[AWID-1:24]=={AWID-24{1'b1}}) begin
    tlbmiss_o <= FALSE;
    padr_o[AWID-1:14] <= ladr_i[AWID-1:14];
    acr_o <= 4'b1111;
  end
  else if (tadr0[AWID+7:32]==ladr_i[AWID-1:24] && (tadr0[63:56]==asid_i || tadr0[55])) begin
    tlbmiss_o <= FALSE;
    padr_o[AWID-1:14] <= tadr0[AWID-15:0];
    acr_o <= tadr0[51:48];
    hit0 <= 1'b1;
  end
  else if (tadr1[AWID+7:32]==ladr_i[AWID-1:24] && (tadr1[63:56]==asid_i || tadr1[55])) begin
    tlbmiss_o <= FALSE;
    padr_o[AWID-1:14] <= tadr1[AWID-15:0];
    acr_o <= tadr1[51:48];
    hit1 <= 1'b1;
  end
  else if (tadr2[AWID+7:32]==ladr_i[AWID-1:24] && (tadr2[63:56]==asid_i || tadr2[55])) begin
    tlbmiss_o <= FALSE;
    padr_o[AWID-1:14] <= tadr2[AWID-15:0];
    acr_o <= tadr2[51:48];
    hit2 <= 1'b1;
  end
  else if (tadr3[AWID+7:32]==ladr_i[AWID-1:24] && (tadr3[63:56]==asid_i || tadr3[55])) begin
    tlbmiss_o <= FALSE;
    padr_o[AWID-1:14] <= tadr3[AWID-15:0];
    acr_o <= tadr3[51:48];
    hit3 <= 1'b1;
  end
  else
    tlbmiss_o <= TRUE;
end

endmodule
