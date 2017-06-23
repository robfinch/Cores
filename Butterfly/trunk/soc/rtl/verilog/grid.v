`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
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
//
//	Verilog 1995
//
// ============================================================================
//
module grid(rst_i, clk_i, clk100, clk200, clk400,
    cyc11,
    stb11,
    ack11,
    we11,
    adr11,
    dati11,
    dato11, 
    cyc21,
    stb21,
    ack21,
    we21,
    adr21,
    dati21,
    dato21,
    cyc31,
    stb31,
    ack31,
    we31,
    adr31,
    dati31,
    dato31,
    cyc41,
    stb41,
    ack41,
    we41,
    adr41,
    dati41,
    dato41,
    cyc42,
    stb42,
    ack42,
    we42,
    adr42,
    dati42,
    dato42,
    gr_clki_p,
    gr_clki_n,
    gr_seri_p,
    gr_seri_n,
    gr_clko_p,
    gr_clko_n,
    gr_sero_p,
    gr_sero_n,
    mem_ui_clk,
    b_cyc,
    b_stb,
    b_ack,
    b_we,
    b_adr,
    b_dati,
    b_dato,
    vclk,
    hsync,
    vsync,
    blank,
    rgbo
//    TMDS_OUT_clk_n, TMDS_OUT_clk_p,
//    TMDS_OUT_data_n, TMDS_OUT_data_p, 
//    TMDS_IN_clk_n, TMDS_IN_clk_p,
//    TMDS_IN_data_n, TMDS_IN_data_p 
);
input rst_i;
input clk_i;
input clk100;
input clk200;
input clk400;
output cyc11;
output stb11;
input ack11;
output we11;
output [15:0] adr11;
input [7:0] dati11;
output [7:0] dato11;
output cyc21;
output stb21;
input ack21;
output we21;
output [15:0] adr21;
input [7:0] dati21;
output [7:0] dato21;
output cyc31;
output stb31;
input ack31;
output we31;
output [15:0] adr31;
input [7:0] dati31;
output [7:0] dato31;
output cyc41;
output stb41;
input ack41;
output we41;
output [15:0] adr41;
input [7:0] dati41;
output [7:0] dato41;
output cyc42;
output stb42;
input ack42;
output we42;
output [15:0] adr42;
input [7:0] dati42;
output [7:0] dato42;
input gr_clki_p;
input gr_clki_n;
input [2:0] gr_seri_p;
input [2:0] gr_seri_n;
output gr_clko_p;
output gr_clko_n;
output [2:0] gr_sero_p;
output [2:0] gr_sero_n;
input mem_ui_clk;
output b_cyc;
output b_stb;
input b_ack;
output b_we;
output [31:0] b_adr;
input [127:0] b_dati;
output [127:0] b_dato;
input vclk;
input hsync;
input vsync;
input blank;
output [23:0] rgbo;
parameter Z = 4'h1;

wire [3:0] txdX11,txdX21,txdX31,txdX41,txdX51,txdX61,txdX71,txdX81;
wire [3:0] txdX12,txdX22,txdX32,txdX42,txdX52,txdX62,txdX72,txdX82;
wire [3:0] txdX13,txdX23,txdX33,txdX43,txdX53,txdX63,txdX73,txdX83;
wire [3:0] txdX14,txdX24,txdX34,txdX44,txdX54,txdX64,txdX74,txdX84;
wire [3:0] txdX15,txdX25,txdX35,txdX45,txdX55,txdX65,txdX75,txdX85;
wire [3:0] txdX16,txdX26,txdX36,txdX46,txdX56,txdX66,txdX76,txdX86;
wire [3:0] txdX17,txdX27,txdX37,txdX47,txdX57,txdX67,txdX77,txdX87;
wire [3:0] txdX18,txdX28,txdX38,txdX48,txdX58,txdX68,txdX78,txdX88;
wire [3:0] txdXF1;

wire [3:0] txdY11,txdY21,txdY31,txdY41,txdY51,txdY61,txdY71,txdY81;
wire [3:0] txdY12,txdY22,txdY32,txdY42,txdY52,txdY62,txdY72,txdY82;
wire [3:0] txdY13,txdY23,txdY33,txdY43,txdY53,txdY63,txdY73,txdY83;
wire [3:0] txdY14,txdY24,txdY34,txdY44,txdY54,txdY64,txdY74,txdY84;
wire [3:0] txdY15,txdY25,txdY35,txdY45,txdY55,txdY65,txdY75,txdY85;
wire [3:0] txdY16,txdY26,txdY36,txdY46,txdY56,txdY66,txdY76,txdY86;
wire [3:0] txdY17,txdY27,txdY37,txdY47,txdY57,txdY67,txdY77,txdY87;
wire [3:0] txdY18,txdY28,txdY38,txdY48,txdY58,txdY68,txdY78,txdY88;

wire [2:0] txdZ41,txdZ42,txdZ43,txdZ44,txdZ45,txdZ46;
wire [2:0] rxdZ41,rxdZ42,rxdZ43,rxdZ44,rxdZ45,rxdZ46;

GridRouterTx ugrtx
(
    .rst(rst_i),
    .pclk(clk100),
    .sclk(clk400),
    .ig1({txdZ41,txdZ42}),
    .ig2({txdZ43,txdZ44}),
    .ig3({txdZ45,txdZ46}),
    .clk_p(gr_clko_p),
    .clk_n(gr_clko_n),
    .sero_p(gr_sero_p),
    .sero_n(gr_sero_n)
);

GridRouterRx ugrrx
(
    .rst(rst_i),
    .refclk(clk200),
    .pclk(clk100),
    .og1({rxdZ41,rxdZ42}),
    .og2({rxdZ43,rxdZ44}),
    .og3({rxdZ45,rxdZ46}),
    .clk_p(gr_clki_p),
    .clk_n(gr_clki_n),
    .seri_p(gr_seri_p),
    .seri_n(gr_seri_n)
);

node #({8'h11,Z},0) un11
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdXF1),
    .txdX(txdX11),
    .rxdY(txdY17),
    .txdY(txdY11),
    .rxdZ(rxdZ11),
    .txdZ(txdZ11),
    .cyc(cyc11),
    .stb(stb11),
    .ack(ack11),
    .we(we11),
    .adr(adr11),
    .dati(dati11),
    .dato(dato11)
);

node #({8'h21,Z}) un21
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX11),
    .txdX(txdX21),
    .rxdY(txdY27),
    .txdY(txdY21),
    .cyc(cyc21),
    .stb(stb21),
    .ack(ack21),
    .we(we21),
    .adr(adr21),
    .dati(dati21),
    .dato(dato21)
);

node #({8'h31,Z}) un31
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX21),
    .txdX(txdX31),
    .rxdY(txdY37),
    .txdY(txdY31),
    .cyc(cyc31),
    .stb(stb31),
    .ack(ack31),
    .we(we31),
    .adr(adr31),
    .dati(dati31),
    .dato(dato31)
);

node #({8'h41,Z},2) un41
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX31),
    .txdX(txdX41),
    .rxdY(txdY47),
    .txdY(txdY41),
    .rxdZ(rxdZ41),
    .txdZ(txdZ41),
    .cyc(cyc41),
    .stb(stb41),
    .ack(ack41),
    .we(we41),
    .adr(adr41),
    .dati(dati41),
    .dato(dato41)
);

node #({8'h51,Z}) un51
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX41),
    .txdX(txdX51),
    .rxdY(txdY57),
    .txdY(txdY51)
);

node #({8'h61,Z}) un61
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX51),
    .txdX(txdX61),
    .rxdY(txdY67),
    .txdY(txdY61)
);

node #({8'h71,Z}) un71
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX61),
    .txdX(txdX71),
    .rxdY(txdY77),
    .txdY(txdY71)
);

node #({8'h81,Z}) un81
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX71),
    .txdX(txdX81),
    .rxdY(txdY87),
    .txdY(txdY81)
);

node #({8'h12,Z}) un12
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX82),
    .txdX(txdX12),
    .rxdY(txdY11),
    .txdY(txdY12)
);

node #({8'h22,Z}) un22
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX12),
    .txdX(txdX22),
    .rxdY(txdY21),
    .txdY(txdY22)
);

node #({8'h32,Z}) un32
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX22),
    .txdX(txdX32),
    .rxdY(txdY31),
    .txdY(txdY32)
);

node #({8'h42,Z},2) un42
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX32),
    .txdX(txdX42),
    .rxdY(txdY41),
    .txdY(txdY42),
    .rxdZ(rxdZ42),
    .txdZ(txdZ42),
    .cyc(cyc42),
    .stb(stb42),
    .ack(ack42),
    .we(we42),
    .adr(adr42),
    .dati(dati42),
    .dato(dato42)
);

node #({8'h52,Z}) un52
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX42),
    .txdX(txdX52),
    .rxdY(txdY51),
    .txdY(txdY52)
);

node #({8'h62,Z}) un62
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX52),
    .txdX(txdX62),
    .rxdY(txdY61),
    .txdY(txdY62)
);

node #({8'h72,Z}) un72
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX62),
    .txdX(txdX72),
    .rxdY(txdY71),
    .txdY(txdY72)
);

node #({8'h82,Z}) un82
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX72),
    .txdX(txdX82),
    .rxdY(txdY81),
    .txdY(txdY82)
);

node #({8'h13,Z}) un13
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX83),
    .txdX(txdX13),
    .rxdY(txdY12),
    .txdY(txdY13)
);

node #({8'h23,Z}) un23
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX13),
    .txdX(txdX23),
    .rxdY(txdY22),
    .txdY(txdY23)
);

node #({8'h33,Z},0) un33
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX23),
    .txdX(txdX33),
    .rxdY(txdY32),
    .txdY(txdY33)
);

node #({8'h43,Z},2) un43
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX33),
    .txdX(txdX43),
    .rxdY(txdY42),
    .txdY(txdY43),
    .rxdZ(rxdZ43),
    .txdZ(txdZ43)
);

node #({8'h53,Z}) un53
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX43),
    .txdX(txdX53),
    .rxdY(txdY52),
    .txdY(txdY53)
);

node #({8'h63,Z}) un63
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX53),
    .txdX(txdX63),
    .rxdY(txdY62),
    .txdY(txdY63)
);

node #({8'h73,Z}) un73
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX63),
    .txdX(txdX73),
    .rxdY(txdY72),
    .txdY(txdY73)
);

node #({8'h83,Z}) un83
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX73),
    .txdX(txdX83),
    .rxdY(txdY82),
    .txdY(txdY83)
);

node #({8'h14,Z}) un14
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX84),
    .txdX(txdX14),
    .rxdY(txdY13),
    .txdY(txdY14)
);

node #({8'h24,Z}) un24
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX14),
    .txdX(txdX24),
    .rxdY(txdY23),
    .txdY(txdY24)
);

node #({8'h34,Z}) un34
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX24),
    .txdX(txdX34),
    .rxdY(txdY33),
    .txdY(txdY34)
);

node #({8'h44,Z},2) un44
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX34),
    .txdX(txdX44),
    .rxdY(txdY43),
    .txdY(txdY44),
    .rxdZ(rxd),
    .txdZ(txd)
);

node #({8'h54,Z}) un54
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX44),
    .txdX(txdX54),
    .rxdY(txdY53),
    .txdY(txdY54)
);

node #({8'h64,Z}) un64
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX54),
    .txdX(txdX64),
    .rxdY(txdY63),
    .txdY(txdY64)
);

node #({8'h74,Z}) un74
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX64),
    .txdX(txdX74),
    .rxdY(txdY73),
    .txdY(txdY74)
);

node #({8'h84,Z}) un84
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX74),
    .txdX(txdX84),
    .rxdY(txdY83),
    .txdY(txdY84)
);

node #({8'h15,Z}) un15
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX85),
    .txdX(txdX15),
    .rxdY(txdY14),
    .txdY(txdY15)
);

node #({8'h25,Z}) un25
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX15),
    .txdX(txdX25),
    .rxdY(txdY24),
    .txdY(txdY25)
);

node #({8'h35,Z}) un35
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX25),
    .txdX(txdX35),
    .rxdY(txdY34),
    .txdY(txdY35)
);

node #({8'h45,Z},2) un45
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX35),
    .txdX(txdX45),
    .rxdY(txdY44),
    .txdY(txdY45),
    .rxdZ(rxdZ45),
    .txdZ(txdZ45)
);

node #({8'h55,Z}) un55
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX45),
    .txdX(txdX55),
    .rxdY(txdY54),
    .txdY(txdY55)
);

node #({8'h65,Z}) un65
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX55),
    .txdX(txdX65),
    .rxdY(txdY64),
    .txdY(txdY65)
);

node #({8'h75,Z}) un75
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX65),
    .txdX(txdX75),
    .rxdY(txdY74),
    .txdY(txdY75)
);

node #({8'h85,Z}) un85
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX75),
    .txdX(txdX85),
    .rxdY(txdY84),
    .txdY(txdY85)
);

node #({8'h16,Z}) un16
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX86),
    .txdX(txdX16),
    .rxdY(txdY15),
    .txdY(txdY16)
);

node #({8'h26,Z}) un26
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX16),
    .txdX(txdX26),
    .rxdY(txdY25),
    .txdY(txdY26)
);

node #({8'h36,Z}) un36
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX26),
    .txdX(txdX36),
    .rxdY(txdY35),
    .txdY(txdY36)
);

node #({8'h46,Z},2) un46
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX36),
    .txdX(txdX46),
    .rxdY(txdY45),
    .txdY(txdY46),
    .rxdZ(rxdZ46),
    .txdZ(txdZ46)
);

node #({8'h56,Z}) un56
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX46),
    .txdX(txdX56),
    .rxdY(txdY55),
    .txdY(txdY56)
);

node #({8'h66,Z}) un66
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX56),
    .txdX(txdX66),
    .rxdY(txdY65),
    .txdY(txdY66)
);

node #({8'h76,Z}) un76
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX66),
    .txdX(txdX76),
    .rxdY(txdY75),
    .txdY(txdY76)
);

node #({8'h86,Z}) un86
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX76),
    .txdX(txdX86),
    .rxdY(txdY85),
    .txdY(txdY86)
);

node #({8'h17,Z}) un17
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX87),
    .txdX(txdX17),
    .rxdY(txdY16),
    .txdY(txdY17)
);

node #({8'h27,Z}) un27
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX17),
    .txdX(txdX27),
    .rxdY(txdY26),
    .txdY(txdY27)
);

node #({8'h37,Z}) un37
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX27),
    .txdX(txdX37),
    .rxdY(txdY36),
    .txdY(txdY37)
);

node #({8'h47,Z},0) un47
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX37),
    .txdX(txdX47),
    .rxdY(txdY46),
    .txdY(txdY47),
    .rxdZ(rxdZ47),
    .txdZ(txdZ47)
);

node #({8'h57,Z}) un57
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX47),
    .txdX(txdX57),
    .rxdY(txdY56),
    .txdY(txdY57)
);

node #({8'h67,Z}) un67
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX57),
    .txdX(txdX67),
    .rxdY(txdY66),
    .txdY(txdY67)
);

node #({8'h77,Z}) un77
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX67),
    .txdX(txdX77),
    .rxdY(txdY76),
    .txdY(txdY77)
);

node #({8'h87,Z}) un87
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX77),
    .txdX(txdX87),
    .rxdY(txdY86),
    .txdY(txdY87)
);

/*
node #({8'h18,Z}) un18
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX88),
    .txdX(txdX18),
    .rxdY(txdY17),
    .txdY(txdY18)
);

node #({8'h28,Z}) un28
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX18),
    .txdX(txdX28),
    .rxdY(txdY27),
    .txdY(txdY28)
);

node #({8'h38,Z}) un38
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX28),
    .txdX(txdX38),
    .rxdY(txdY37),
    .txdY(txdY38)
);

node #({8'h48,Z},0) un48
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX38),
    .txdX(txdX48),
    .rxdY(txdY47),
    .txdY(txdY48),
    .rxdZ(rxdZ48),
    .txdZ(txdZ48)
);

node #({8'h58,Z}) un58
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX48),
    .txdX(txdX58),
    .rxdY(txdY57),
    .txdY(txdY58)
);

node #({8'h68,Z}) un68
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX58),
    .txdX(txdX68),
    .rxdY(txdY67),
    .txdY(txdY68)
);

node #({8'h78,Z}) un78
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX68),
    .txdX(txdX78),
    .rxdY(txdY77),
    .txdY(txdY78)
);

node #({8'h88,Z}) un88
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX78),
    .txdX(txdX88),
    .rxdY(txdY87),
    .txdY(txdY88)
);
*/

BMCNode unF1 (
    .rst_i(rst_i),
    .clk_i(clk_i),
    .sclk(clk100),
    .rxdX(txdX81),
    .txdX(txdXF1),
    .rxdY(),
    .txdY(),
    .rxdZ(),
    .txdZ(),
    .mem_ui_clk(mem_ui_clk),
    .cyc(b_cyc),
    .stb(b_stb),
    .ack(b_ack),
    .we(b_we),
    .adr(b_adr),
    .dati(b_dati),
    .dato(b_dato),
    .vclk(vclk),
    .hsync(hsync),
    .vsync(vsync),
    .blank(blank),
    .rgbo(rgbo)
);

endmodule
