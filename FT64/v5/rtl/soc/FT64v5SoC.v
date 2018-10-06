// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
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
//`define SIM
//`define AVIC	1'b1
//`define ORSOC_GRAPHICS	1'b1
`define TEXT_CONTROLLER	1'b1
`define BMP_CONTROLLER 1'b1		// needed for sync generation

module FT64v5SoC(cpu_resetn, xclk, led, sw, btnl, btnr, btnc, btnd, btnu, 
    kclk, kd,
    TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n,
    ac_mclk, ac_adc_sdata, ac_dac_sdata, ac_bclk, ac_lrclk,
    oled_sdin, oled_sclk, oled_dc, oled_res, oled_vbat, oled_vdd
`ifndef SIM
    ,ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_reset_n,ddr3_ras_n,ddr3_cas_n,ddr3_we_n,
    ddr3_ba,ddr3_addr,ddr3_dq,ddr3_dqs_p,ddr3_dqs_n,ddr3_dm,ddr3_odt
`endif
//    gtp_clk_p, gtp_clk_n,
//    dp_tx_hp_detect, dp_tx_aux_p, dp_tx_aux_n, dp_rx_aux_p, dp_rx_aux_n,
//    dp_tx_lane0_p, dp_tx_lane0_n, dp_tx_lane1_p, dp_tx_lane1_n
);
input cpu_resetn;
input xclk;
output reg [7:0] led;
input [7:0] sw;
input btnl;
input btnr;
input btnc;
input btnd;
input btnu;
inout kclk;
tri kclk;
inout kd;
tri kd;
output TMDS_OUT_clk_p;
output TMDS_OUT_clk_n;
output [2:0] TMDS_OUT_data_p;
output [2:0] TMDS_OUT_data_n;
output ac_mclk;
input ac_adc_sdata;
output ac_dac_sdata;
inout ac_bclk;
inout ac_lrclk;
output oled_sdin;
output oled_sclk;
output oled_dc;
output oled_res;
output oled_vbat;
output oled_vdd;
`ifndef SIM
output [0:0] ddr3_ck_p;
output [0:0] ddr3_ck_n;
output [0:0] ddr3_cke;
output ddr3_reset_n;
output ddr3_ras_n;
output ddr3_cas_n;
output ddr3_we_n;
output [2:0] ddr3_ba;
output [14:0] ddr3_addr;
inout [15:0] ddr3_dq;
inout [1:0] ddr3_dqs_p;
inout [1:0] ddr3_dqs_n;
output [1:0] ddr3_dm;
output [0:0] ddr3_odt;
`endif
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
wire clk12;
wire clk20, clk40, clk50, clk80, clk100, clk200, clk400;
wire mem_ui_clk;
wire xclk_bufg;
wire hSync, vSync, blank, border;
wire [7:0] red, blue, green;

wire [2:0] cti;
wire cyc, stb, ack;
wire we;
wire [7:0] sel;
wire [31:0] adr;
reg [63:0] dati;
wire [63:0] dato;
wire sr,cr,rb;

wire [31:0] tc1_rgb;
wire tc1_ack;
wire [63:0] tc1_dato;
wire ack_scr, ack_br;
wire [63:0] scr_dato, br_dato;
wire rnd_ack;
wire [31:0] rnd_dato;
wire dram_ack;
wire [63:0] dram_dato;
wire avic_ack;
wire [63:0] avic_dato;
wire [31:0] avic_rgb;
wire kbd_rst;
wire kbd_ack;
wire [7:0] kbd_dato;
wire kbd_irq;

wire spr_ack;
wire [63:0] spr_dato;
wire spr_cyc;
wire spr_stb;
wire spr_acki;
wire spr_we;
wire [7:0] spr_sel;
wire [31:0] spr_adr;
wire [63:0] spr_dati;
wire [31:0] spr_rgbo;
wire [4:0] spr_spriteno;

wire bmp_ack;
wire [63:0] bmp_cdato;
wire bmp_cyc;
wire bmp_stb;
wire bmp_acki;
wire bmp_we;
wire [7:0] bmp_sel;
wire [31:0] bmp_adr;
wire [63:0] bmp_dati;
wire [63:0] bmp_dato;
wire [31:0] bmp_rgb;
wire [11:0] hctr, vctr;

wire ack_1761;

wire ack_bridge1;
wire br1_cyc;
wire br1_stb;
reg br1_ack;
wire br1_we;
wire [7:0] br1_sel;
wire [3:0] br1_sel32;
wire [31:0] br1_adr;
wire [31:0] br1_adr32;
wire [63:0] br1_cdato;
wire [63:0] br1_dato;
wire [31:0] br1_dato32;
reg [63:0] br1_dati;

wire ack_bridge2;
wire br2_cyc;
wire br2_stb;
reg br2_ack;
wire br2_we;
wire [7:0] br2_sel;
wire [3:0] br2_sel32;
wire [31:0] br2_adr;
wire [31:0] br2_adr32;
wire [63:0] br2_cdato;
wire [63:0] br2_dato;
wire [31:0] br2_dato32;
reg [63:0] br2_dati;

wire gpio_ack;
wire [15:0] aud0, aud1, aud2, aud3;
wire [15:0] audi;
wire aud_cyc;
wire aud_stb;
wire aud_acki;
wire aud_we;
wire [1:0] aud_sel;
wire [31:0] aud_adr;
wire [15:0] aud_dati;
wire [15:0] aud_dato;
wire aud_ack;
wire [63:0] aud_cdato;

wire ack_gbridge1;
wire gbr1_cyc;
wire gbr1_stb;
reg gbr1_ack;
wire gbr1_we;
wire [7:0] gbr1_sel;
wire [3:0] gbr1_sel32;
wire [31:0] gbr1_adr;
wire [31:0] gbr1_adr32;
wire [63:0] gbr1_cdato;
wire [63:0] gbr1_dato;
wire [31:0] gbr1_dato32;
reg [63:0] gbr1_dati;

wire [31:0] grid_zrgb;

// -----------------------------------------------------------------------------
// Input debouncing
// -----------------------------------------------------------------------------

wire btnu_db, btnd_db, btnl_db, btnr_db, btnc_db;
BtnDebounce udbu (clk20, btnu, btnu_db);
BtnDebounce udbd (clk20, btnd, btnd_db);
BtnDebounce udbl (clk20, btnl, btnl_db);
BtnDebounce udbr (clk20, btnr, btnr_db);
BtnDebounce udbc (clk20, btnc, btnc_db);

// -----------------------------------------------------------------------------
// Clock generation
// -----------------------------------------------------------------------------

NexysVideoClkgen ucg1
 (
  // Clock out ports
  .clk100(clk100),
  .clk400(clk400),
  .clk80(clk80),
  .clk20(clk20),
  .clk40(clk40),
  .clk200(clk200),
  .clk12(clk12),
  // Status and control signals
  .reset(xrst), 
  .locked(locked),       // output locked
 // Clock in ports
  .clk_in1(xclk_bufg)
);
assign rst = !locked;

`ifndef AVIC
//WXGASyncGen1280x768_60Hz u4
//(
//	.rst(rst),
//	.clk(clk80),
//	.hSync(hSync),
//	.vSync(vSync),
//	.blank(blank),
//	.border(border)
//);
`endif

rgb2dvi #(
	.kGenerateSerialClk(1'b0),
	.kClkPrimitive("MMCM"),
	.kClkRange(3),
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
	.vid_pHSync(hSync),    // hSync is neg going for 1366x768
	.vid_pVSync(vSync),
	.PixelClk(clk40),
	.SerialClk(clk200)
);

OLED uoled1
(
	.rst(rst),
	.clk(xclk_bufg),
	.adr_i(adr),
	.dat_i(dati),
	.SDIN(oled_sdin),
	.SCLK(oled_sclk),
	.DC(oled_dc),
	.RES(oled_res),
	.VBAT(oled_vbat),
	.VDD(oled_vdd)
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

// -----------------------------------------------------------------------------
// Address Decoding
// -----------------------------------------------------------------------------
wire cs_dram = adr[31:29]==3'h0;
wire cs_br = adr[31:16]==16'hFFFC
					|| adr[31:16]==16'hFFFD
					|| adr[31:16]==16'hFFFE;
wire cs_scr = adr[31:20]==12'hFF4;
wire cs_tc1 = br1_adr[31:16]==16'hFFD0;
wire cs_spr = br1_adr[31:12]==20'hFFDAD;
//wire cs_bmp = br1_adr[31:12]==20'hFFDC5;
wire cs_bmp = 1'b0;
wire cs_avic = br1_adr[31:13]==19'b1111_1111_1101_1100_110;	// FFDCC000-FFDCDFFF
wire cs_gfx00 = br1_adr[31:12]==20'hFFDD8;
wire cs_rnd = br2_adr[31:4]==28'hFFDC0C0;
wire cs_led = br2_cyc && br2_stb && (br2_adr[31:4]==28'hFFDC060);
wire cs_kbd  = br2_adr[31:4]==28'hFFDC000;
wire cs_aud  = br2_adr[31:8]==24'hFFD510;
wire cs_1761 = br2_adr[31:4]==28'hFFDC070;
wire cs_cmdc = br2_adr[31:4]==28'hFFDC080;
wire cs_grid = br2_adr[31:8]==24'hFFD520;

//wire cs_gfx00 = gbr1_adr[31:12]==20'hFFDD8 && gbr1_cyc && gbr1_stb;
wire cs_gfx01 = gbr1_adr[31:12]==20'hFFDD9 && gbr1_cyc && gbr1_stb;
wire cs_gfx10 = gbr1_adr[31:12]==20'hFFDDA && gbr1_cyc && gbr1_stb;
wire cs_gfx11 = gbr1_adr[31:12]==20'hFFDDB && gbr1_cyc && gbr1_stb;

reg [14:0] cmd_core;
always @(posedge clk20)
	if (cs_cmdc & br2_cyc & br2_stb & br2_we)
		cmd_core <= br2_dato[14:0];

FT_GPUGrid ugpugrid1
(
	.rst_i(rst),
	.cmd_clk_i(clk20),
	.cmd_core_i(cmd_core),
	.wr_cmd_i(cs_grid & br2_cyc & br2_stb & br2_we),
	.cmd_adr_i(br2_adr[7:0]),
	.cmd_dat_i(br2_dato[31:0]),
	.cmd_count_o(),
	.dot_clk_i(clk40),
	.blank_i(blank),
	.vctr_i(vctr),
	.hctr_i(hctr),
	.zrgb_o(grid_zrgb)
);

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
reg [31:0] gfx_rgb;
wire gfx00_cyc;
wire gfx00_stb;
wire gfx00_ack;
wire gfx00_cack;
wire gfx00_we;
wire [7:0] gfx00_sel;
wire [31:0] gfx00_adr;
wire [63:0] gfx00_cdato;
wire [63:0] gfx00_dati;
wire [63:0] gfx00_dato;

`ifdef ORSOC_GFX
gfx_top64 ugfx00
(
	.wb_clk_i(clk20),
	.wb_rst_i(rst),
	.wb_inta_o(),
  // Wishbone master signals (interfaces with video memory, write)
  .wbm_cyc_o(gfx00_cyc),
  .wbm_stb_o(gfx00_stb),
  .wbm_cti_o(),
  .wbm_bte_o(),
  .wbm_we_o(gfx00_we),
  .wbm_adr_o(gfx00_adr),
  .wbm_sel_o(gfx00_sel),
  .wbm_ack_i(gfx00_ack),
  .wbm_err_i(),
  .wbm_dat_i(gfx00_dati),
  .wbm_dat_o(gfx00_dato),
  // Wishbone slave signals (interfaces with main bus/CPU)
  .wbs_cs_i(cs_gfx00),
  .wbs_cyc_i(br1_cyc),
  .wbs_stb_i(br1_stb),
  .wbs_cti_i(),
  .wbs_bte_i(),
  .wbs_we_i(br1_we),
  .wbs_adr_i(br1_adr),
  .wbs_sel_i(br1_sel),
  .wbs_ack_o(gfx00_cack),
  .wbs_err_o(),
  .wbs_dat_i(br1_dato),
  .wbs_dat_o(gfx00_cdato)
);
`else
assign gfx00_cyc = 1'b0;
assign gfx00_stb = 1'b0;
assign gfx00_we = 1'b0;
assign gfx00_sel = 8'h00;
assign gfx00_adr = 32'h0;
assign gfx00_dato = 64'd0;
assign gfx00_cack = 1'b0;
assign gfx00_cdato = 64'd0;
`endif

`ifdef TEXT_CONTROLLER
FT64_TextController2 #(.num(1)) tc1
(
	.rst_i(rst),
	.clk_i(clk20),
	.cs_i(cs_tc1),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(tc1_ack),
	.wr_i(br1_we),
	.adr_i(br1_adr),
	.dat_i(br1_dato),
	.dat_o(tc1_dato),
	.lp_i(),
	.dot_clk_i(clk40),
	.hsync_i(hSync),
	.vsync_i(vSync),
	.blank_i(blank),
	.border_i(border),
	.zrgb_i(grid_zrgb),
	.zrgb_o(tc1_rgb),
	.xonoff_i(sw[3])
);
assign red = spr_rgbo[23:16];
assign green = spr_rgbo[15:8];
assign blue = spr_rgbo[7:0];
`endif

`ifdef BMP_CONTROLLER
rtfBitmapController5 ubmc1
(
	.rst_i(rst),
	.s_clk_i(clk20),
	.s_cs_i(cs_bmp),
	.s_cyc_i(br1_cyc),
	.s_stb_i(br1_stb),
	.s_ack_o(bmp_ack),
	.s_we_i(br1_we),
	.s_sel_i(br1_sel),
	.s_adr_i(br1_adr[11:0]),
	.s_dat_i(br1_dato),
	.s_dat_o(bmp_cdato),
	.irq_o(),
	.m_clk_i(clk20),
	.m_cyc_o(bmp_cyc),
	.m_stb_o(bmp_stb),
	.m_ack_i(bmp_acki),
	.m_we_o(bmp_we),
	.m_sel_o(bmp_sel),
	.m_adr_o(bmp_adr),
	.m_dat_i(bmp_dati),
	.m_dat_o(bmp_dato),
	.dot_clk_i(clk40),
	.hsync_o(hSync),
	.vsync_o(vSync),
	.blank_o(blank),
	.border_o(border),
	.hctr_o(hctr),
	.vctr_o(vctr),
	.zrgb_o(bmp_rgb),
	.xonoff_i(sw[2])
);
`else
assign bmp_ack = 1'b0;
assign bmp_cdato = 64'd0;
assign bmp_cyc = 1'b0;
assign bmp_stb = 1'b0;
assign bmp_we = 1'b0;
assign bmp_sel = 8'h00;
assign bmp_adr = 32'h0;
assign bmp_dato = 64'h0;
`endif

rtfSpriteController2 usc2
(
	.rst_i(rst),
	.clk_i(clk20),
	.cs_i(cs_spr),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(spr_ack),
	.we_i(br1_we),
	.sel_i(br1_sel),
	.adr_i(br1_adr),
	.dat_i(br1_dato),
	.dat_o(spr_dato),
	.m_clk_i(mem_ui_clk),
	.m_cyc_o(spr_cyc),
	.m_stb_o(spr_stb),
	.m_ack_i(spr_acki),
	.m_sel_o(spr_sel),
	.m_adr_o(spr_adr),
	.m_dat_i(spr_dati),
	.m_spriteno_o(spr_spriteno),
	.dot_clk_i(clk40),
	.hsync_i(hSync),
	.vsync_i(vSync),
	.border_i(border),
	.zrgb_i(tc1_rgb),
	.zrgb_o(spr_rgbo),
	.test(sw[1])
);

wire [23:0] rgb;
wire vde;
wire vm_cyc, vm_stb, vm_ack, vm_we;
wire [15:0] vm_sel;
wire [31:0] vm_adr;
wire [127:0] vm_dat_o;
wire [127:0] vm_dat_i;
wire [7:0] gst;

`ifdef AVIC
AVIC128 uavic1
(
	// Slave port
	.rst_i(rst),
	.clk_i(clk20),
	.cs_i(cs_avic),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(avic_ack),
	.we_i(br1_we),
	.sel_i(br1_sel),
	.adr_i(br1_adr[12:0]),
	.dat_i(br1_dato),
	.dat_o(avic_dato),
	// Bus master
	.m_clk_i(clk40),
	.m_cyc_o(vm_cyc),
	.m_stb_o(vm_stb),
	.m_ack_i(vm_ack),
	.m_we_o(vm_we),
	.m_sel_o(vm_sel),
	.m_adr_o(vm_adr),
	.m_dat_i(vm_dat_i),
	.m_dat_o(vm_dat_o),
	// Video port
	.vclk(clk40),
	.hSync(hSync),
	.vSync(vSync),
	.de(vde),
	.rgb(avic_rgb),
	// Audio ports
	.aud0_out(aud0),
	.aud1_out(aud1),
	.aud2_out(aud2),
	.aud3_out(aud3),
	.aud_in(audi),
	// Debug
	.state(gst)
);
assign blank = ~vde;
`else
assign vm_cyc = 1'b0;
assign vm_stb = 1'b0;
assign vm_we = 1'b0;
assign avic_ack = 1'b0;
`endif

wire ack_led = cs_led;
always @(posedge clk20)
begin
//led[0] <= cs_br;
//led[1] <= cs_scr;
//led[2] <= rst;
//led[7:4] <= adr[6:3];
if (cs_led & br2_we)
  led <= br2_dato[7:0];
end
wire [31:0] led_dato = {11'h0,btnc,btnu,btnd,btnl,btnr,8'h00,sw};

reg ack1;
assign ack = ack_scr|ack_bridge1|ack_bridge2|ack_br|dram_ack;
always @(posedge clk20)
if (rst)
	ack1 <= 1'b0;
else
	ack1 <= ack;
always @(posedge clk20)
casez({cs_br,ack_bridge1,cs_scr,ack_bridge2,cs_dram})
5'b1????: dati <= br_dato;
5'b01???: dati <= br1_cdato;
5'b001??: dati <= scr_dato;
5'b0001?: dati <= br2_cdato;
5'b00001: dati <= dram_dato;
default:    dati <= {4{16'h0080}}; // NOP
endcase

wire br1_ack1 = tc1_ack|spr_ack|bmp_ack|avic_ack|gfx00_cack;
always @(posedge clk20)
if (rst)
	br1_ack <= 1'b0;
else
	br1_ack <= br1_ack1;

always @(posedge clk20)
casez({cs_tc1,cs_spr,cs_bmp,cs_avic,cs_gfx00})
5'b1????:	br1_dati <= tc1_dato;
5'b01???:	br1_dati <= spr_dato;
5'b001??:	br1_dati <= bmp_cdato;
5'b0001?:	br1_dati <= avic_dato;
5'b00001:	br1_dati <= gfx00_cdato;
default:	br1_dati <= 64'hDEADDEADDEADDEAD;
endcase

wire br2_ack1 = rnd_ack|ack_led|kbd_ack|ack_1761|aud_ack|cs_cmdc|cs_grid;
always @(posedge clk20)
if (rst)
	br2_ack <= 1'b0;
else
	br2_ack <= br2_ack1;

always @(posedge clk20)
casez({cs_rnd,cs_led,cs_kbd,cs_aud})
4'b1???:	br2_dati <= {2{rnd_dato}};
4'b01??:	br2_dati <= {2{led_dato}};
4'b001?:	br2_dati <= {8{kbd_dato}};
4'b0001:	br2_dati <= aud_cdato;
default:	br2_dati <= 64'hDEADDEADDEADDEAD;
endcase

IOBridge u_video_bridge
(
	.rst_i(rst),
	.clk_i(clk20),
	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge1),
	.s1_sel_i(sel),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br1_cdato),

	.m_cyc_o(br1_cyc),
	.m_stb_o(br1_stb),
	.m_ack_i(br1_ack),
	.m_we_o(br1_we),
	.m_sel_o(br1_sel),
	.m_adr_o(br1_adr),
	.m_dat_i(br1_dati),
	.m_dat_o(br1_dato),
	.m_sel32_o(br1_sel32),
	.m_adr32_o(br1_adr32),
	.m_dat32_o(br1_dat32)
);

IOBridge u_bridge2
(
	.rst_i(rst),
	.clk_i(clk20),
	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge2),
	.s1_sel_i(sel),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br2_cdato),

	.m_cyc_o(br2_cyc),
	.m_stb_o(br2_stb),
	.m_ack_i(br2_ack),
	.m_we_o(br2_we),
	.m_sel_o(br2_sel),
	.m_adr_o(br2_adr),
	.m_dat_i(br2_dati),
	.m_dat_o(br2_dato),
	.m_sel32_o(br2_sel32),
	.m_adr32_o(br2_adr32),
	.m_dat32_o(br2_dat32)
);

random	uprg1
(
	.rst_i(rst),
	.clk_i(clk20),
	.cs_i(cs_rnd),
	.cyc_i(br2_cyc),
	.stb_i(br2_stb),
	.ack_o(rnd_ack),
	.we_i(br2_we),
	.adr_i(br2_adr32),
	.dat_i(br2_dat32),
	.dat_o(rnd_dato)
);

AudioController uaud1
(
	.rst_i(rst),
	.s_clk_i(clk20),
	.s_cyc_i(br2_cyc),
	.s_stb_i(br2_stb),
	.s_ack_o(aud_ack),
	.s_we_i(br2_we),
	.s_sel_i(br2_sel),
	.s_adr_i(br2_adr[7:0]),
	.s_dat_o(aud_cdato),
	.s_dat_i(br2_dato),
	.s_cs_i(cs_aud),
	.m_clk_i(clk20),
	.m_cyc_o(aud_cyc),
	.m_stb_o(aud_stb),
	.m_ack_i(aud_acki),
	.m_we_o(aud_we),
	.m_sel_o(aud_sel),
	.m_adr_o(aud_adr),
	.m_dat_i(aud_dati),
	.m_dat_o(aud_dato),
	.aud0_out(aud0),
	.aud1_out(aud1),
	.aud2_out(aud2),
	.aud3_out(aud3),
	.audi_in(audi),
	.record_i(btnl_db),
	.playback_i(btnr_db)
);

wire ac_dac_sdata1;
wire ac_bclk1;
wire ac_lrclk1;
wire en_rxtx;
wire en_tx;
ADAU1761_Interface uai1
(
	.rst_i(rst),
	.clk_i(clk20),
	.cs_i(cs_1761),
	.cyc_i(br2_cyc),
	.stb_i(br2_stb),
	.ack_o(ack_1761),
	.we_i(br2_we),
	.dat_i(br2_dato[7:0]),
	.aud0_i(aud0),
	.aud2_i(aud2),
	.audi_o(audi),
	.ac_mclk_i(ac_mclk),
	.ac_bclk_o(ac_bclk1),
	.ac_lrclk_o(ac_lrclk1),
	.ac_adc_sdata_i(ac_adc_sdata),
	.ac_dac_sdata_o(ac_dac_sdata1),
	.en_rxtx_o(en_rxtx),
	.en_tx_o(en_tx),
	.record_i(btnl_db),
	.playback_i(btnr_db)
);
assign ac_mclk = clk12;
assign ac_bclk = en_rxtx ? ac_bclk1 : 1'bz;
assign ac_lrclk = en_rxtx ? ac_lrclk1 : 1'bz;
assign ac_dac_sdata = en_tx ? ac_dac_sdata1 : 1'b0;

reg br2_dat8;
always @*
case(br2_sel)
8'b00000001:	br2_dat8 <= br2_dato[7:0];
8'b00000010:	br2_dat8 <= br2_dato[15:8];
8'b00000100:	br2_dat8 <= br2_dato[23:16];
8'b00001000:	br2_dat8 <= br2_dato[31:24];
8'b00010000:	br2_dat8 <= br2_dato[39:32];
8'b00100000:	br2_dat8 <= br2_dato[47:40];
8'b01000000:	br2_dat8 <= br2_dato[55:48];
8'b10000000:	br2_dat8 <= br2_dato[63:56];
8'b00000011:	br2_dat8 <= br2_dato[7:0];
8'b00001100:	br2_dat8 <= br2_dato[23:16];
8'b00110000:	br2_dat8 <= br2_dato[39:32];
8'b11000000:	br2_dat8 <= br2_dato[55:48];
8'b00001111:	br2_dat8 <= br2_dato[7:0];
8'b11110000:	br2_dat8 <= br2_dato[39:32];
8'b11111111:	br2_dat8 <= br2_dato[7:0];
default:		br2_dat8 <= br2_dato[7:0];
endcase

Ps2Keyboard u_ps2kbd
(
  .rst_i(rst),
  .clk_i(clk),
  .cs_i(cs_kbd),
  .cyc_i(br2_cyc),
  .stb_i(br2_stb),
  .ack_o(kbd_ack),
  .we_i(br2_wr),
  .adr_i(br2_adr32),
  .dat_i(br2_dat8),
  .dat_o(kbd_dato),
  .kclk(kclk),
  .kd(kd),
  .irq_o(kbd_irq)
);

IBUFG #(.IBUF_LOW_PWR("FALSE"),.IOSTANDARD("DEFAULT")) ubg1
(
    .I(xclk),
    .O(xclk_bufg)
);


`ifdef SIM
mainmem_sim umm1
(
	.rst_i(rst),
	.clk_i(clk20),
	.cti_i(cti),
	.cs_i(cs_dram),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(dram_ack),
	.we_i(we),
	.sel_i(sel),
	.adr_i(adr[28:0]),
	.dat_i(dato),
	.dat_o(dram_dato)
);
`endif

`ifndef SIM
mpmc6 umc1
(
	.rst_i(rst),
	.clk100MHz(xclk_bufg),
	.clk200MHz(clk200),
	.mem_ui_clk(mem_ui_clk),
/*
	.cyc0(vm_cyc),
	.stb0(vm_stb),
	.ack0(vm_ack),
	.we0(vm_we),
	.sel0(vm_sel),
	.adr0(vm_adr),
	.dati0(vm_dat_o),
	.dato0(vm_dat_i),
*/
	.cyc0(bmp_cyc),
	.stb0(bmp_stb),
	.ack0(bmp_acki),
	.we0(bmp_we),
	.sel0(bmp_sel),
	.adr0(bmp_adr),
	.dati0(bmp_dato),
	.dato0(bmp_dati),

/*
cs1, cyc1, stb1, ack1, we1, sel1, adr1, dati1, dato1, sr1, cr1, rb1,
cyc2, stb2, ack2, we2, sel2, adr2, dati2, dato2,
cyc3, stb3, ack3, we3, sel3, adr3, dati3, dato3,
cyc4, stb4, ack4, we4, sel4, adr4, dati4, dato4,
cyc5, stb5, ack5, adr5, dato5,
cyc6, stb6, ack6, we6, sel6, adr6, dati6, dato6,
cs7, cyc7, stb7, ack7, we7, sel7, adr7, dati7, dato7, sr7, cr7, rb7,
*/
	.cyc3(aud_cyc),
	.stb3(aud_stb),
	.ack3(aud_acki),
	.we3(aud_we),
	.sel3(aud_sel),
	.adr3(aud_adr),
	.dati3(aud_dato),
	.dato3(aud_dati),

	.cyc4(gfx00_cyc),
	.stb4(gfx00_stb),
	.ack4(gfx00_ack),
	.we4(gfx00_we),
	.sel4(gfx00_sel),
	.adr4(gfx00_adr),
	.dati4(gfx00_dato),
	.dato4(gfx00_dati),

	.cyc5(spr_cyc),
	.stb5(spr_stb),
	.ack5(spr_acki),
	.adr5(spr_adr),
	.dato5(spr_dati),
	.spriteno(spr_spriteno),

	.cs7(cs_dram),
	.cyc7(cyc),
	.stb7(stb),
	.ack7(dram_ack),
	.we7(we),
	.sel7(sel),
	.adr7(adr),
	.dati7(dato),
	.dato7(dram_dato),
	.sr7(sr),
	.cr7(cr),
	.rb7(rb),

	// DDR3 interface
	.ddr3_dq(ddr3_dq),
	.ddr3_dqs_n(ddr3_dqs_n),
	.ddr3_dqs_p(ddr3_dqs_p),
	.ddr3_addr(ddr3_addr),
	.ddr3_ba(ddr3_ba),
	.ddr3_ras_n(ddr3_ras_n),
	.ddr3_cas_n(ddr3_cas_n),
	.ddr3_we_n(ddr3_we_n),
	.ddr3_ck_p(ddr3_ck_p),
	.ddr3_ck_n(ddr3_ck_n),
	.ddr3_cke(ddr3_cke),
	.ddr3_reset_n(ddr3_reset_n),
	.ddr3_dm(ddr3_dm),
	.ddr3_odt(ddr3_odt),
	// Debugging	
	.state(),
	.ch()
);
`endif


scratchmem uscr1
(
  .rst_i(rst),
  .clk_i(clk20),
  .cti_i(cti),
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

bootrom #(64) ubr1
(
  .rst_i(rst),
  .clk_i(clk20),
  .cti_i(cti),
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
  .clk_i(clk20),
  .clk4x_i(clk40),
  .tm_clk_i(clk20),
  .i1(1'b0),
  .i2(1'b0),
  .i3(1'b0),
  .i4(1'b0),
  .i5(1'b0),
  .i6(1'b0),
  .i7(1'b0),
  .i8(1'b0),
  .i9(1'b0),
  .i10(1'b0),
  .i11(1'b0),
  .i12(1'b0),
  .i13(1'b0),
  .i14(1'b0),
  .i15(1'b0),
  .i16(1'b0),
  .i17(1'b0),
  .i18(1'b0),
  .i19(1'b0),
  .i20(1'b0),
  .i21(1'b0),
  .i22(1'b0),
  .i23(1'b0),
  .i24(1'b0),
  .i25(1'b0),
  .i26(1'b0),
  .i27(1'b0),
  .i28(1'b0),
  .i29(kbd_irq),
  .irq_o(),
  .cti_o(cti),
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack1),
  .err_i(1'b0),
  .we_o(we),
  .sel_o(sel),
  .adr_o(adr),
  .dat_o(dato),
  .dat_i(dati),
  .sr_o(sr),
  .cr_o(cr),
  .rb_i(rb)
);

endmodule
