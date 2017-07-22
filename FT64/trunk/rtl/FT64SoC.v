// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64SoC.v
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
module FT64SoC(cpu_resetn, xclk, led, sw,
    TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n
//    gtp_clk_p, gtp_clk_n,
//    dp_tx_hp_detect, dp_tx_aux_p, dp_tx_aux_n, dp_rx_aux_p, dp_rx_aux_n,
//    dp_tx_lane0_p, dp_tx_lane0_n, dp_tx_lane1_p, dp_tx_lane1_n
);
input cpu_resetn;
input xclk;
output reg [7:0] led;
input [7:0] sw;
output TMDS_OUT_clk_p;
output TMDS_OUT_clk_n;
output [2:0] TMDS_OUT_data_p;
output [2:0] TMDS_OUT_data_n;
//input gtp_clk_p;
//input gtp_clk_n;
//input dp_tx_hp_detect;
//output dp_tx_aux_p;
//output dp_tx_aux_n;
//input dp_rx_aux_p;
//input dp_rx_aux_n;
//output dp_tx_lane0_p;
//output dp_tx_lane0_n;
//output dp_tx_lane1_p;
//output dp_tx_lane1_n;

wire rst;
wire xrst = ~cpu_resetn;
wire clk50, clk80, clk100, clk400;
wire hSync, vSync, blank, border;
wire [7:0] red, blue, green;

wire cyc, stb, ack;
wire we;
wire [7:0] sel;
wire [31:0] adr;
reg [63:0] dati;
wire [63:0] dato;

wire [23:0] tc1_rgb;
wire tc1_ack;
wire [31:0] tc1_dato;
wire ack_scr, ack_br;
wire [63:0] scr_dato, br_dato;

NexysVideoClkgen ucg1
 (
  // Clock out ports
  .clk100(clk100),
  .clk400(clk400),
  .clk80(clk80),
  .clk50(clk50),
  // Status and control signals
  .reset(xrst), 
  .locked(locked),       // output locked
 // Clock in ports
  .clk_in1(xclk)
);
assign rst = !locked;

WXGASyncGen1280x768_60Hz u4
(
	.rst(rst),
	.clk(clk80),
	.hSync(hSync),
	.vSync(vSync),
	.blank(blank),
	.border(border)
);

rgb2dvi #(
    .kGenerateSerialClk(1'b0),
    .kClkPrimitive("MMCM"),
    .kClkRange(2),
    .kRstActiveHigh(1'b1)
)
ur2d1 
(
    .TMDS_Clk_p(TMDS_OUT_clk_p),
    .TMDS_Clk_n(TMDS_OUT_clk_n),
    .TMDS_Data_p(TMDS_OUT_data_p),
    .TMDS_Data_n(TMDS_OUT_data_n),
    .aRst(rst),
    .aRst_n(~rst),
    .vid_pData({red,blue,green}),
    .vid_pVDE(~blank),
    .vid_pHSync(~hSync),    // hSync is neg going for 1366x768
    .vid_pVSync(vSync),
    .PixelClk(clk80),
    .SerialClk(clk400)
);

//top_level udp1
//(
//    .clk100(clk100),
//    .debug(),
//    .gtptxp({dp_tx_lane1_p,dp_tx_lane0_p}),
//    .gtptxn({dp_tx_lane1_n,dp_tx_lane0_n}),
//    .refclk0_p(gtp_clk_p),
//    .refclk0_n(gtp_clk_n), 
//    .refclk1_p(gtp_clk_p),
//    .refclk1_n(gtp_clk_n),
//    .dp_tx_hp_detect(dp_tx_hp_detect),
//    .dp_tx_aux_p(dp_tx_aux_p),
//    .dp_tx_aux_n(dp_tx_aux_n),
//    .dp_rx_aux_p(dp_rx_aux_p),
//    .dp_rx_aux_n(dp_rx_aux_n)
//);

wire cs_br = adr[31:18]==14'h3FFF;
wire cs_tc1 = adr[31:16]==16'hFFD0;
wire cs_scr = adr[31:15]==17'h00000;
wire cs_led = cyc && stb && (adr[31:4]==28'hFFDC060);

FT64_TextController #(.num(1)) tc1
(
	.rst_i(rst),
	.clk_i(clk50),
	.cs_i(cs_tc1),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(tc1_ack),
	.wr_i(we),
	.adr_i(adr[15:0]),
	.dat_i(dato[31:0]),
	.dat_o(tc1_dato),
	.lp(),
	.curpos(),
	.vclk(clk80),
	.hsync(hSync),
	.vsync(vSync),
	.blank(blank),
	.border(border),
	.rgbIn(24'd0),
	.rgbOut(tc1_rgb)
);
assign red = tc1_rgb[23:16];
assign green = tc1_rgb[15:8];
assign blue = tc1_rgb[7:0];

wire ack_led = cs_led;
always @(posedge clk50)
begin
led[0] <= cs_br;
led[1] <= cs_scr;
if (cs_led)
    led <= dato[7:0];
end
wire [7:0] led_dato = sw;

assign ack = ack_scr|ack_led|tc1_ack|ack_br;
always @*
casex({cs_br,cs_tc1,cs_scr,cs_led})
4'b1xxx:    dati <= br_dato;
4'b01xx:    dati <= {2{tc1_dato}};
4'b001x:    dati <= scr_dato;
4'b0001:    dati <= {8{led_dato}};
default:    dati <= {2{32'h1C}}; // NOP
endcase

scratchmem uscr1
(
    .rst_i(rst),
    .clk_i(clk50),
    .cs_i(cs_scr),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(ack_scr),
    .we_i(we),
    .sel_i(sel),
    .adr_i(adr[14:0]),
    .dat_i(dato),
    .dat_o(scr_dato)
);

bootrom ubr1
(
    .rst_i(rst),
    .clk_i(clk50),
    .cs_i(cs_br),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(ack_br),
    .adr_i(adr[17:0]),
    .dat_o(br_dato)
);

FT64_mpu ucpu1
(
    .hartid_i(64'h1),
    .rst_i(rst),
    .clk_i(clk50),
    .irq_i(3'd0),
    .vec_i(9'h000),
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .err_i(1'b0),
    .we_o(we),
    .sel_o(sel),
    .adr_o(adr),
    .dat_o(dato),
    .dat_i(dati)
);

endmodule
