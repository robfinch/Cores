// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rf6809_noc.sv
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================
//
//`define SIM
//`define AVIC	1'b1
//`define ORSOC_GFX	1'b1
`define SOC_FULL
`define TEXT_CONTROLLER	1'b1
`define BMP_CONTROLLER 1'b1		// needed for sync generation
`define SPRITE_CONTROLLER	1'b1
//`define I2C_MASTER 1'b1
//`define SPI_MASTER 1'b1
//`define SDC_CONTROLLER 1'b1
//`define GPU_GRID	1'b1
//`define RANDOM_GEN	1'b1
//`define NOC_RING	1'b1

import rf6809_pkg::*;
import nic_pkg::*;

module rf6809_test_soc(cpu_resetn, xclk, led, sw, btnl, btnr, btnc, btnd, btnu, 
  kclk, kd, uart_txd, uart_rxd,
  TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n,
  ac_mclk, ac_adc_sdata, ac_dac_sdata, ac_bclk, ac_lrclk,
  rtc_clk, rtc_data,
  spiClkOut, spiDataIn, spiDataOut, spiCS_n,
  sd_cmd, sd_dat, sd_clk, sd_cd, sd_reset,
  pti_clk, pti_rxf, pti_txe, pti_rd, pti_wr, pti_siwu, pti_oe, pti_dat, spien,
  oled_sdin, oled_sclk, oled_dc, oled_res, oled_vbat, oled_vdd
  ,ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_reset_n,ddr3_ras_n,ddr3_cas_n,ddr3_we_n,
  ddr3_ba,ddr3_addr,ddr3_dq,ddr3_dqs_p,ddr3_dqs_n,ddr3_dm,ddr3_odt
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
output uart_txd;
input uart_rxd;
output TMDS_OUT_clk_p;
output TMDS_OUT_clk_n;
output [2:0] TMDS_OUT_data_p;
output [2:0] TMDS_OUT_data_n;
output ac_mclk;
input ac_adc_sdata;
output reg ac_dac_sdata;
inout reg ac_bclk;
inout reg ac_lrclk;
inout rtc_clk;
tri rtc_clk;
inout rtc_data;
tri rtc_data;
output spiCS_n;
output spiClkOut;
output spiDataOut;
input spiDataIn;
inout sd_cmd;
tri sd_cmd;
inout [3:0] sd_dat;
tri [3:0] sd_dat;
output sd_clk;
input sd_cd;
output sd_reset;
input pti_clk;
input pti_rxf;
input pti_txe;
output pti_rd;
output pti_wr;
input spien;
output pti_siwu;
output pti_oe;
inout [7:0] pti_dat;
output oled_sdin;
output oled_sclk;
output oled_dc;
output oled_res;
output oled_vbat;
output oled_vdd;

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
wire clk10, clk14, clk20, clk40, clk60, clk80, clk100, clk200;
wire xb400, xb57, xb40, xb29, xb19;
wire cpu_clk = clk40;
wire div_clk = clk20;
wire cpu_clk2x = clk40;
wire cpu_clk4x = clk80;
wire mem_ui_clk;
wire xclk_bufg;
wire hSync, vSync;
reg blank;
wire border;
wire [7:0] red, blue, green;

wire [2:0] cti;
(* mark_debug = "true" *)
wire cyc;
(* mark_debug = "true" *)
wire stb;
reg ack;
wire we;
wire [15:0] sel;
(* mark_debug = "true" *)
wire [23:0] adr;
reg [BPB-1:0] dati = {BPB{1'b0}};
wire [BPB-1:0] dato;
wire sr,cr,rb;

wire [31:0] tc1_rgb;
wire tc1_ack;
wire [11:0] tc1_dato;
wire ack_scr;
wire ack_scr0;
wire ack_scr1;
wire ack_scr2;
wire ack_scr3;
(* mark_debug = "true" *)
wire ack_br;
wire [11:0] scr_dato;
wire [11:0] scr0_dato;
wire [11:0] scr1_dato;
wire [11:0] scr2_dato;
wire [11:0] scr3_dato;
wire [11:0] br_dato;
wire br_bok, scr_bok;
wire rnd_ack;
wire [31:0] rnd_dato;
(* mark_debug="true" *)
wire dram_ack;
wire [127:0] dram_dato;
wire avic_ack;
wire [63:0] avic_dato;
wire [31:0] avic_rgb;
wire kbd_rst;
reg kbd_ack;
reg [11:0] kbd_dato;
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
wire [5:0] spr_spriteno;

parameter BMPW = 128;
wire bmp_ack;
wire [63:0] bmp_cdato;
wire bmp_cyc;
wire bmp_stb;
wire bmp_acki;
wire bmp_we;
wire [(BMPW==128 ? 15 : 7):0] bmp_sel;
wire [31:0] bmp_adr;
wire [BMPW-1:0] bmp_dati;
wire [BMPW-1:0] bmp_dato;
wire [31:0] bmp_rgb;
wire [11:0] hctr, vctr;
wire [5:0] fctr;
wire xal;

wire ack_1761;

wire ack_bridge1;
wire br1_cyc;
wire br1_stb;
reg br1_ack = 1'b0;
wire br1_we;
wire [7:0] br1_sel;
wire [3:0] br1_sel32;
wire [23:0] br1_adr;
wire [31:0] br1_adr32;
wire [BPB-1:0] br1_cdato;
wire br1_s2_ack;
wire [BPB-1:0] br1_s2_cdato;
wire [BPB-1:0] br1_dato;
wire [31:0] br1_dat32;
wire [7:0] br1_dat8;
reg [7:0] br1_dati = 8'd0;

wire ack_bridge2;
wire br2_cyc;
wire br2_stb;
reg br2_ack = 1'b0;
wire br2_we;
wire [7:0] br2_sel;
wire [3:0] br2_sel32;
wire [23:0] br2_adr;
wire [31:0] br2_adr32;
wire [BPB-1:0] br2_cdato;
wire [BPB-1:0] br2_dato;
wire [31:0] br2_dat32;
wire [7:0] br2_dat8;
reg [7:0] br2_dati = 8'd0;

wire ack_bridge3;
wire br3_cyc;
wire br3_stb;
reg br3_ack = 1'b0;
wire br3_we;
wire [7:0] br3_sel;
wire [3:0] br3_sel32;
wire [23:0] br3_adr;
wire [31:0] br3_adr32;
wire [BPB-1:0] br3_cdato;
wire [BPB-1:0] br3_dato;
wire [31:0] br3_dat32;
wire [7:0] br3_dat8;
reg [7:0] br3_dati = 8'd0;

reg cs_pic;
wire pic_ack;
wire [11:0] pic_dat;

wire gpio_ack;
wire [15:0] aud0, aud1, aud2, aud3;
wire [15:0] audi;
(* mark_debug = "true" *)
wire aud_cyc;
wire aud_stb;
(* mark_debug = "true" *)
wire aud_acki;
wire aud_we;
wire [1:0] aud_sel;
wire [31:0] aud_adr;
wire [15:0] aud_dati;
wire [15:0] aud_dato;
wire aud_ack;
wire [11:0] aud_cdato;

wire rtc_ack;
wire [7:0] rtc_cdato;
wire spi_ack;
wire [7:0] spi_dato;

/*
wire pti_ack = 1'b0;
wire [63:0] pti_cdato = 64'd0;
wire pti_cyc = 1'b0;
wire pti_stb = 1'b0;
wire pti_acki;
wire pti_we = 1'b0;
wire [15:0] pti_sel = 16'b0;
wire [31:0] pti_adr = 32'd0;
wire [127:0] pti_dato = 128'd0;
wire [127:0] pti_dati;
*/
wire pti_ack;
wire [63:0] pti_cdato;
wire pti_cyc;
wire pti_stb;
wire pti_acki;
wire pti_we;
wire [15:0] pti_sel;
wire [31:0] pti_adr;
wire [127:0] pti_dato;
wire [127:0] pti_dati;

wire sdc_ack;
wire [31:0] sdc_cdato;
(* mark_debug = "true" *)
wire sdc_cyc;
wire sdc_stb;
(* mark_debug = "true" *)
wire sdc_acki;
wire sdc_we;
wire [3:0] sdc_sel;
wire [31:0] sdc_adr;
wire [31:0] sdc_dato;
wire [31:0] sdc_dati;

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
reg [63:0] gbr1_dati = 64'd0;

wire grid_cyc;
wire grid_stb;
reg grid_ack;
wire grid_we;
wire [3:0] grid_sel;
wire [31:0] grid_adr;
reg [31:0] grid_dati = 32'd0;
wire grid_dram_ack;
wire [63:0] grid_dram_dati1;
wire [31:0] grid_dato;
wire [31:0] grid_zrgb;

wire uart_irq;
wire uart_ack;
wire [31:0] uart_dato;

wire sema_ack;
wire [7:0] sema_dato;

wire xb_ack = 1'b0;
wire xb_cyc;
wire xb_stb;
wire xb_we;
wire [15:0] xb_sel;
wire [31:0] xb_adr;
wire [127:0] xb_dato;
wire [127:0] xb_dati;

wire irq;
wire firq;
wire [BPB-1:0] cause;
wire [5:0] iserver;

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
  .clk200(clk200),	// display / ddr3
  .clk100(clk100),
  .clk60(clk60),		// cpu 4x
  .clk40(clk40),		// cpu 2x / display
  .clk20(clk20),		// cpu
  .clk10(clk10),
  .clk14(clk14),		// 16x baud clock
  // Status and control signals
  .reset(xrst), 
  .locked(locked),       // output locked
 // Clock in ports
  .clk_in1(xclk_bufg)
);

wire locked2 = 1'b1;
/*
NexysVideoClkgen2 ucg2
(
  // Clock out ports
  .clk400(xb400),	// xbus
  .clk57(xb57),
  .clk40(xb40),
  .clk29(xb29),
  .clk19(xb19),
  // Status and control signals
  .reset(xrst), 
  .locked(locked2),       // output locked
 // Clock in ports
  .clk_in1(xclk_bufg)
);
*/
assign rst = !locked | !locked2;
assign sd_reset = rst;


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

`ifdef SOC_FULL
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
	.clk(clk100), //xclk_bufg
	.adr_i(adr),
	.dat_i(dato[7:0]),
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
`endif

// -----------------------------------------------------------------------------
// Address Decoding
// -----------------------------------------------------------------------------
(* mark_debug="true" *)
wire cs_dram = adr[23:20] < 4'hE && adr[23:16]!=8'h00;		// Main memory 14MB
reg cs_br = 1'b0;
`ifndef NOC_RING
always_comb cs_br = adr[23:16]==8'hFF;	// Scratchpad memory 8k
assign ack_scr = 1'b0;
assign scr_dato = 12'h0;
`else
assign ack_br = 1'b0;
assign br_dato = 12'h0;
assign ack_scr0 = 1'b0;
assign ack_scr1 = 1'b0;
assign ack_scr2 = 1'b0;
assign ack_scr3 = 1'b0;
assign scr0_dato = 12'h0;
assign scr1_dato = 12'h0;
assign scr2_dato = 12'h0;
assign scr3_dato = 12'h0;
`endif
/*
always_comb
	cs_br <= adr[31:16]==16'hFFFC		// Boot rom 192k
				|| adr[31:16]==16'hFFFD
				|| adr[31:16]==16'hFFFE;
*/
reg cs_scr;
reg cs_scr0;
reg cs_scr1;
reg cs_scr2;
reg cs_scr3;
`ifdef NOC_RING
always_comb cs_scr = adr[23:16]==8'hFF;	// Scratchpad memory 8k
`else
always_comb cs_scr0 = adr[23:14]==10'h00;	// Scratchpad memory 8k
always_comb cs_scr1 = adr[23:14]==10'h01;	// Scratchpad memory 8k
always_comb cs_scr2 = adr[23:14]==10'h02;	// Scratchpad memory 8k
always_comb cs_scr3 = adr[23:14]==10'h03;	// Scratchpad memory 8k
`endif
always_comb cs_pic = adr[23:8]==16'hE3F0;

// No need to check for the $E in the top 4 address bits as these are 
// detected in the I/O bridges.
reg cs_tc1;
always_comb cs_tc1 = br1_adr[23:16]==8'hE0;	// E0xxxx Text Controller 64k
reg cs_spr;
always_comb cs_spr = br1_adr[23:16]==8'hE1;	// FF8Bxxxx	Sprite Controller
reg cs_bmp;
always_comb cs_bmp = br1_adr[23:16]==8'hE2;	//          Bitmap Controller
//wire cs_bmp = 1'b0;
//wire cs_avic = br1_adr[31:13]==19'b1111_1111_1101_1100_110;	// FFDCC000-FFDCDFFF
wire cs_avic = 1'b0;									// defunct: audio / video controller
reg cs_gfx00 = 1'b0;
//always_comb cs_gfx00 = br1_adr[23:12]==12'h8C0;		// orsoc graphics accelerator
reg cs_rnd = 1'b0;
//always_comb cs_rnd = br2_adr[23:16]==8'h94;		// PRNG random number generator
reg cs_led;
always_comb cs_led = br2_cyc && br2_stb && (br2_adr[23:8]==16'hE600);	// LEDS,buttons,switches
reg cs_kbd;
always_comb cs_kbd  = br2_adr[23:8]==16'hE304;		// keyboard controller
reg cs_aud=1'b0;
//always_comb cs_aud  = br2_adr[23:16]==8'h85;		// audio controller
reg cs_1761 = 1'b0;
//always_comb cs_1761 = br2_adr[23:12]==12'h854;		// AC97 controller
reg cs_cmdc = 1'b0;
//always_comb cs_cmdc = br2_adr[23:16]==8'h9B;
reg cs_grid = 1'b0;
//always_comb cs_grid = br2_adr[23:16]==8'h9C;		// graphics grid computer
reg cs_imem = 1'b0;
/*
always_comb cs_imem = br2_adr[23:12]==12'h9C8 		// instruction memory for grid computer
						|| br2_adr[23:12]==12'h9C9
						|| br2_adr[23:12]==12'h9CA
						|| br2_adr[23:12]==12'h9CB
						;
*/
reg cs_sema;					// EF0000 to EF1FFF
always_comb cs_sema = br3_adr[23:13]==11'b1110_1111_000;     // 256 counting semaphores
reg cs_rtc = 1'b0;
//always_comb cs_rtc = br3_adr[23:16]==8'h90;		// real-time clock chip
reg cs_spi = 1'b0;
//always_comb cs_spi = br3_adr[23:16]==8'h9D;			// spi controller
reg cs_sdc = 1'b0;
//always_comb cs_sdc = br3_adr[23:16]==8'h9E;			// sdc controller
reg cs_pti = 1'b0;
//always_comb cs_pti = br3_adr[23:16]==8'h97;			// parallel transfer interface
reg cs_uart;
always_comb cs_uart = br3_adr[23:8]==16'hE301;

//always_comb cs_gfx00 = gbr1_adr[31:12]==20'hFFDD8 && gbr1_cyc && gbr1_stb;
reg cs_gfx01 = 1'b0;
//always_comb cs_gfx01 = gbr1_adr[23:12]==12'h8C4 && gbr1_cyc && gbr1_stb;	// orsoc graphics accelerator
reg cs_gfx10 = 1'b0;
//always_comb cs_gfx10 = gbr1_adr[23:12]==12'h8C8 && gbr1_cyc && gbr1_stb;	// orsoc graphics accelerator
reg cs_gfx11 = 1'b0;
//always_comb cs_gfx11 = gbr1_adr[23:12]==12'h8CC && gbr1_cyc && gbr1_stb;	// orsoc graphics accelerator

reg cs_bridge1, cs_bridge2, cs_bridge3;
always_comb cs_bridge1 = (cs_gfx00 | cs_avic | cs_tc1 | cs_spr | cs_bmp) & (br1_cyc & br1_stb);
always_comb cs_bridge2 = (cs_rnd | cs_led | cs_kbd | cs_aud | cs_1761 | cs_cmdc | cs_grid | cs_imem) & (br2_cyc & br2_stb);
always_comb cs_bridge3 = (cs_sema | cs_rtc | cs_spi | cs_sdc | cs_pti | cs_uart) & (br3_cyc & br3_stb);

reg [14:0] cmd_core;
always @(posedge cpu_clk)
	if (cs_cmdc & br2_cyc & br2_stb & br2_we)
		cmd_core <= br2_dato;

`ifdef GPU_GRID
`else
assign grid_cyc = 1'b0;
assign grid_stb = 1'b0;
assign grid_we = 1'b0;
assign grid_sel = 8'h0;
assign grid_adr = 1'b0;
assign grid_dato = 1'b0;
assign grid_zrgb = 32'h0;
`endif

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
	.wb_clk_i(clk40),
	.wb_rst_i(rst),
	.wb_inta_o(),
  // Wishbone slave signals (interfaces with main bus/CPU)
  .wbs_cs_i(cs_gfx00),
  .wbs_cyc_i(br1_cyc),
  .wbs_stb_i(br1_stb),
  .wbs_cti_i(3'b0),
  .wbs_bte_i(2'b0),
  .wbs_we_i(br1_we),
  .wbs_adr_i(br1_adr),
  .wbs_sel_i(br1_sel),
  .wbs_ack_o(gfx00_cack),
  .wbs_err_o(),
  .wbs_dat_i(br1_dato),
  .wbs_dat_o(gfx00_cdato),
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
  .wbm_dat_o(gfx00_dato)
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
rfTextController_x12 #(.num(1)) tc1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_tc1),
	.cti_i(cti),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(tc1_ack),
	.wr_i(br1_we),
	.adr_i(br1_adr[15:0]),
	.dat_i(br1_dato),
	.dat_o(tc1_dato),
	.lp_i(),
	.dot_clk_i(clk40),
	.hsync_i(hSync),
	.vsync_i(vSync),
	.blank_i(blank),
	.border_i(border),
	.zrgb_i(bmp_rgb),
	.zrgb_o(tc1_rgb),
	.xonoff_i(sw[3])
);
assign red = spr_rgbo[23:16];
assign green = spr_rgbo[15:8];
assign blue = spr_rgbo[7:0];
`endif

`ifdef BMP_CONTROLLER
rfFrameBuffer #(.MDW(BMPW)) ufbc1
(
	.rst_i(rst),
	.s_clk_i(cpu_clk),
	.s_cs_i(cs_bmp),
	.s_cyc_i(br1_cyc),
	.s_stb_i(br1_stb),
	.s_ack_o(bmp_ack),
	.s_we_i(br1_we),
	.s_sel_i(br1_sel),
	.s_adr_i(br1_adr[13:0]),
	.s_dat_i(br1_dato),
	.s_dat_o(bmp_cdato),
	.irq_o(),
	.m_clk_i(clk40),
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
	.fctr_o(fctr),
	.zrgb_o(bmp_rgb),
	.xonoff_i(sw[2]),
	.xal_o(xal)
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

`ifdef SPRITE_CONTROLLER
rfSpriteController_x12 usc2
(
	.rst_i(rst),
	.s_clk_i(cpu_clk),
	.s_cs_i(cs_spr),
	.s_cyc_i(br1_cyc),
	.s_stb_i(br1_stb),
	.s_ack_o(spr_ack),
	.s_we_i(br1_we),
	.s_adr_i(br1_adr[11:0]),
	.s_dat_i(br1_dato),
	.s_dat_o(spr_dato),
	.m_clk_i(clk40),
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
	.blank_i(border),
	.zrgb_i(tc1_rgb),
	.zrgb_o(spr_rgbo),
	.test(sw[1])
);
`else
assign spr_ack = 1'b0;
assign spr_dato = 64'd0;
assign spr_cyc = 1'b0;
assign spr_stb = 1'b0;
assign spr_sel = 1'b0;
assign spr_adr = 1'b0;
assign spr_spriteno = 1'b0;
`endif

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
	.clk_i(cpu_clk),
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
	.m_clk_i(cpu_clk),
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
always_comb blank = ~vde;
`else
assign vm_cyc = 1'b0;
assign vm_stb = 1'b0;
assign vm_we = 1'b0;
assign avic_ack = 1'b0;
`endif

wire ack_led = cs_led;
always_ff @(posedge cpu_clk)
if (rst)
	led[7:0] <= 8'h00;
else begin
//led[0] <= cs_br;
//led[1] <= cs_scr;
//led[2] <= rst;
//led[7:4] <= adr[6:3];
if (cs_led & br2_we)
  led[7:0] <= br2_dato[7:0];
end
reg [BPB-1:0] led_dato;
always_comb
case(br2_adr[1:0])
2'd0:	led_dato <= {4'd0,sw};
2'd1:	led_dato <= {7'd0,btnc,btnu,btnd,btnl,btnr};
default:	;
endcase

reg ack1 = 1'b0;
always_ff @(posedge cpu_clk)
	ack1 <= ack_scr|ack_scr0|ack_scr1|ack_scr2|ack_scr3|pic_ack|ack_bridge1|ack_bridge2|ack_bridge3|ack_br|dram_ack|xb_ack;
//assign ack = ack_br;
wire cs_any = cs_br|cs_scr|cs_scr0|cs_scr1|cs_scr2|cs_scr3|cs_pic|cs_dram|ack_bridge1|ack_bridge2|ack_bridge3;
always_ff @(posedge cpu_clk)
	if (cs_any)
		dati <= br_dato|scr_dato|scr0_dato|scr1_dato|scr2_dato|scr3_dato|pic_dat|br1_cdato|br2_cdato|dram_dato|br3_cdato;
	else
		dati <= dati;
/*
always_ff @(posedge cpu_clk)
casez({cs_br,cs_scr,ack_bridge1,ack_bridge2,dram_ack,ack_bridge3,xb_ack})
7'b1??????: dati <= br_dato;
7'b01?????: dati <= scr_dato;
7'b001????: dati <= br1_cdato;
7'b0001???: dati <= br2_cdato;
7'b00001??: dati <= dram_dato;
7'b000001?: dati <= br3_cdato;
7'b0000001: dati <= xb_dato;
default:   dati <= dati;
endcase
*/

wire br1_ack1 = tc1_ack|spr_ack|bmp_ack|avic_ack|gfx00_cack;
always_ff @(posedge cpu_clk)
	br1_ack <= br1_ack1;

wire cs_br1 = cs_tc1|cs_spr|cs_bmp|cs_gfx00;
always_ff @(posedge cpu_clk)
	if (cs_br1)
		br1_dati <= tc1_dato|spr_dato|bmp_cdato|gfx00_cdato;
	else
		br1_dati <= 12'h0;
/*
always_ff @(posedge cpu_clk)
casez({tc1_ack,spr_ack,bmp_ack,avic_ack,gfx00_cack})
5'b1????:	br1_dati <= tc1_dato;
5'b01???:	br1_dati <= spr_dato;
5'b001??:	br1_dati <= bmp_cdato;
5'b0001?:	br1_dati <= avic_dato;
5'b00001:	br1_dati <= gfx00_cdato;
default:	br1_dati <= br1_dati;
endcase
*/
wire br2_ack1 = rnd_ack|ack_led|kbd_ack|ack_1761|aud_ack|cs_cmdc|cs_grid|cs_imem;
always_ff @(posedge cpu_clk)
	br2_ack <= br2_ack1;
wire cs_br2 = cs_rnd|cs_led|cs_kbd|cs_aud;
always_ff @(posedge cpu_clk)
	if (cs_br2)
		br2_dati <= rnd_dato|led_dato|kbd_dato|aud_cdato;
	else
		br2_dati <= 12'h0;
/*
always_ff @(posedge cpu_clk)
casez({rnd_ack,ack_led,kbd_ack,aud_ack})
4'b1???:	br2_dati <= {2{rnd_dato}};	// 32 bits reflected twice
4'b01??:	br2_dati <= {2{led_dato}};	
4'b001?:	br2_dati <= {8{kbd_dato}};	// 8 bits reflect 8 times
4'b0001:	br2_dati <= aud_cdato;			// 64 bit peripheral
default:	br2_dati <= br2_dati;
endcase
*/
wire ack_s2_bridge1;
always_comb grid_ack <= ack_s2_bridge1 | cs_imem | grid_dram_ack;
always_ff @(posedge cpu_clk)
casez({ack_s2_bridge1,grid_dram_ack})
2'b1?:	grid_dati <= br1_s2_cdato;
2'b01:	grid_dati <= grid_adr[3] ? grid_dram_dati1[63:32] : grid_dram_dati1[31:0];
default:	grid_dati <= grid_dati;
endcase

IOBridge u_video_bridge
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge1),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br1_cdato),

	.s2_cyc_i(grid_cyc),
	.s2_stb_i(grid_stb),
	.s2_ack_o(ack_s2_bridge1),
	.s2_we_i(grid_we),
	.s2_adr_i(grid_adr),
	.s2_dat_i({4{grid_dato}}),
	.s2_dat_o(br1_s2_cdato),

	.m_cyc_o(br1_cyc),
	.m_stb_o(br1_stb),
	.m_ack_i(br1_ack),
	.m_we_o(br1_we),
	.m_adr_o(br1_adr),
	.m_dat_i(br1_dati),
	.m_dat_o(br1_dato)
);

IOBridge u_bridge2
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge2),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br2_cdato),

	.s2_cyc_i(1'b0),
	.s2_stb_i(1'b0),
	.s2_ack_o(),
	.s2_we_i(1'b0),
	.s2_adr_i(24'h0),
	.s2_dat_i(8'h0),
	.s2_dat_o(),

	.m_cyc_o(br2_cyc),
	.m_stb_o(br2_stb),
	.m_ack_i(br2_ack),
	.m_we_o(br2_we),
	.m_adr_o(br2_adr),
	.m_dat_i(br2_dati),
	.m_dat_o(br2_dato)
);

`ifdef RANDOM_GEN
random	uprg1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_rnd),
	.cyc_i(br2_cyc),
	.stb_i(br2_stb),
	.ack_o(rnd_ack),
	.we_i(br2_we),
	.adr_i(br2_adr[3:0]),
	.dat_i(br2_dato),
	.dat_o(rnd_dato)
);
`else
assign rnd_ack = 1'b0;
assign rnd_dato = 1'b0;
`endif

`ifdef AUDIO_CONTROLLER
AudioController uaud1
(
	.rst_i(rst),
	.s_clk_i(cpu_clk),
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
`else
assign aud_ack = 1'b0;
assign aud_cdato = 1'b0;
assign aud_cyc = 1'b0;
assign aud_stb = 1'b0;
assign aud_we = 1'b0;
assign aud_sel = 1'b0;
assign aud_adr = 1'b0;
assign aud_dato = 1'b0;
`endif

`ifdef AUDIO_CONTROLLER
wire ac_dac_sdata1;
wire ac_bclk1;
wire ac_lrclk1;
wire en_rxtx;
wire en_tx;
ADAU1761_Interface uai1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
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
assign ac_mclk = clk10;
always_comb ac_bclk <= en_rxtx ? ac_bclk1 : 1'bz;
always_comb ac_lrclk <= en_rxtx ? ac_lrclk1 : 1'bz;
always_comb ac_dac_sdata = en_tx ? ac_dac_sdata1 : 1'b0;
`else
assign ack_1761 = 1'b0;
assign ac_mclk = 1'b0;
assign ac_bclk = 1'bz;
assign ac_lrclk = 1'bz;
assign ac_dac_sdata = 1'b0;
`endif

wire kclk_en, kdat_en;
wire kdo, kdt;
wire kclko, kclkt;
/*
PS2kbd u_kybd1
(
	// WISHBONE/SoC bus interface 
	.rst_i(rst),
	.clk_i(clk40),	// system clock
	.cs_i(cs_kbd),
  .cyc_i(br2_cyc),
  .stb_i(br2_stb),
  .ack_o(kbd_ack),
  .we_i(br2_we),
  .adr_i(br2_adr[3:0]),
  .dat_i(br2_dato),
  .dat_o(kbd_dato),
  .kclk_i(kclk),
  .kdat_i(kd),
  .kclk_en(kclk_en),
  .kdat_en(kdat_en),
	.db(),
	//-------------
  .irq(kbd_irq)
);
*/
assign kclk = kclkt ? 1'bz : kclko;
assign kd = kdt ? 1'bz : kdo;
wire [7:0] kbd_dat;
reg [11:0] kbd_buf;
reg [11:0] kbd_stat;
wire kbd_we, kbd_rd;
wire kbd_busy;
wire kbd_par;
edge_det uedkbd (
	.rst(rst),
	.clk(clk100),
	.ce(1'b1),
	.i(cs_kbd && br2_adr[3:0]==4'h0 && br2_we && br2_cyc && br2_stb),
	.pe(kbd_we),
	.ne(),
	.ee()
);

Ps2Interface ups21
(
 .PS2_Data_I(kd),
 .PS2_Data_O(kdo),
 .PS2_Data_T(kdt),
 .PS2_Clk_I(kclk),
 .PS2_Clk_O(kclko),
 .PS2_Clk_T(kclkt),
 .clk(clk100),
 .rst(rst),
 .tx_data(br2_dato[7:0]),
 .write_data(kbd_we),
 .rx_data(kbd_dat),
 .read_data(kbd_rd),
 .ack(),
 .busy(kbd_busy),
 .err_par(kbd_par),
 .err_nack()
);

always_ff @(posedge clk100)
begin
	if (kbd_rd) begin
		kbd_buf <= {4'h0,kbd_dat};
		kbd_stat <= {4'h0,1'b1,kbd_busy,5'h0,kbd_par};
	end
	kbd_stat[6] <= kbd_busy;
	if (cs_kbd && br2_cyc && br2_stb) begin
		kbd_ack <= 1'b1;
		case(br2_adr[3:0])
		4'd0:	kbd_dato <= kbd_buf;
		4'd1:
			begin
				kbd_dato <= {4'd0,kbd_stat};
				if (br2_we && br2_dato[7:0]==8'h00)
					kbd_stat[7] <= 1'b0;
			end
		default:	;
		endcase
	end
	else begin
		kbd_ack <= 1'b0;
		kbd_dato <= 12'h0;
	end
end

/*
Ps2Keyboard u_ps2kbd
(
  .rst_i(rst),
  .clk_i(clk100),
  .cs_i(cs_kbd),
  .cyc_i(br2_cyc),
  .stb_i(br2_stb),
  .ack_o(kbd_ack),
  .we_i(br2_we),
  .adr_i(br2_adr32[3:0]),
  .dat_i(br2_dat8),
  .dat_o(kbd_dato),
  .kclk(kclk),
  .kd(kd),
  .irq_o(kbd_irq)
);
*/
IBUFG #(.IBUF_LOW_PWR("FALSE"),.IOSTANDARD("DEFAULT")) ubg1
(
    .I(xclk),
    .O(xclk_bufg)
);

/*
`ifdef SIM
mainmem_sim umm1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
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
*/

wire mem_ui_rst;
wire calib_complete;
wire rstn;
wire [28:0] mem_addr;
wire [2:0] mem_cmd;
wire mem_en;
wire [127:0] mem_wdf_data;
wire [15:0] mem_wdf_mask;
wire mem_wdf_end;
wire mem_wdf_wren;
wire [127:0] mem_rd_data;
wire mem_rd_data_valid;
wire mem_rd_data_end;
wire mem_rdy;
wire mem_wdf_rdy;
wire [3:0] dram_state;

mig_7series_1 uddr3
(
	.ddr3_dq(ddr3_dq),
	.ddr3_dqs_p(ddr3_dqs_p),
	.ddr3_dqs_n(ddr3_dqs_n),
	.ddr3_addr(ddr3_addr),
	.ddr3_ba(ddr3_ba),
	.ddr3_ras_n(ddr3_ras_n),
	.ddr3_cas_n(ddr3_cas_n),
	.ddr3_we_n(ddr3_we_n),
	.ddr3_ck_p(ddr3_ck_p),
	.ddr3_ck_n(ddr3_ck_n),
	.ddr3_cke(ddr3_cke),
	.ddr3_dm(ddr3_dm),
	.ddr3_odt(ddr3_odt),
	.ddr3_reset_n(ddr3_reset_n),
	// Inputs
	.sys_clk_i(clk100),
    .clk_ref_i(clk200),
	.sys_rst(rstn),
	// user interface signals
	.app_addr(mem_addr),
	.app_cmd(mem_cmd),
	.app_en(mem_en),
	.app_wdf_data(mem_wdf_data),
	.app_wdf_end(mem_wdf_end),
	.app_wdf_mask(mem_wdf_mask),
	.app_wdf_wren(mem_wdf_wren),
	.app_rd_data(mem_rd_data),
	.app_rd_data_end(mem_rd_data_end),
	.app_rd_data_valid(mem_rd_data_valid),
	.app_rdy(mem_rdy),
	.app_wdf_rdy(mem_wdf_rdy),
	.app_sr_req(1'b0),
	.app_sr_active(),
	.app_ref_req(1'b0),
	.app_ref_ack(),
	.app_zq_req(1'b0),
	.app_zq_ack(),
	.ui_clk(mem_ui_clk),
	.ui_clk_sync_rst(mem_ui_rst),
	.init_calib_complete(calib_complete)
);

mpmc7 #(.C0W(BMPW), .C4W(128), .C6W(128)) umc1
(
	.rst_i(rst),
	.clk40MHz(clk40),
	.clk100MHz(clk100),
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

	.clk0(clk40),
	.cyc0(bmp_cyc),
	.stb0(bmp_stb),
	.ack0(bmp_acki),
	.we0(bmp_we),
	.sel0(bmp_sel),
	.adr0(bmp_adr),
	.dati0(bmp_dato),
	.dato0(bmp_dati),

  .cs1(1'b0),
  .cyc1(1'b0),
  .stb1(1'b0),
  .we1(1'b0),
  .sel1(4'b0),
  .adr1(32'h0),
  .dati1(32'h0),

  .cyc2(1'b0),
  .stb2(1'b0),
  .we2(1'b0),
  .sel2(4'b0),
  .adr2(32'h0),
  .dati2(32'h0),
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
`ifdef ORSOC_GFX
	.cyc4(gfx00_cyc),
	.stb4(gfx00_stb),
	.ack4(gfx00_ack),
	.we4(gfx00_we),
	.sel4(gfx00_sel),
	.adr4(gfx00_adr),
	.dati4(gfx00_dato),
	.dato4(gfx00_dati),
`else
`ifdef GRID_GFX
	.cyc4(grid_cyc),
	.stb4(grid_stb),
	.ack4(grid_dram_ack),
	.we4(grid_we),
	.sel4(grid_adr[3] ? {grid_sel,4'h0} : {4'h0,grid_sel}),
	.adr4(grid_adr),
	.dati4({2{grid_dato}}),
	.dato4(grid_dram_dati1),
`else
  .cyc4(1'b0),
  .stb4(1'b0),
  .we4(1'b0),
  .sel4(8'h00),
  .adr4(32'h0),
  .dati4(64'd0),
`endif
`endif
	.cyc5(spr_cyc),
	.stb5(spr_stb),
	.ack5(spr_acki),
	.sel5(8'hFF),
	.adr5(spr_adr),
	.dato5(spr_dati),
	.spriteno(spr_spriteno),

	.cyc6(pti_cyc),
	.stb6(pti_stb),
	.ack6(pti_acki),
	.we6(pti_we),
	.sel6(pti_sel),
	.adr6(pti_adr),
	.dati6(pti_dato),
	.dato6(pti_dati),

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

	// MIG memory interface
	.rstn(rstn),
	.mem_ui_clk(mem_ui_clk),
	.mem_ui_rst(mem_ui_rst),
	.calib_complete(calib_complete),
	.mem_addr(mem_addr),
	.mem_cmd(mem_cmd),
	.mem_en(mem_en),
	.mem_wdf_data(mem_wdf_data),
	.mem_wdf_end(mem_wdf_end),
	.mem_wdf_mask(mem_wdf_mask),
	.mem_wdf_wren(mem_wdf_wren),
	.mem_rd_data(mem_rd_data),
	.mem_rd_data_end(mem_rd_data_end),
	.mem_rd_data_valid(mem_rd_data_valid),
	.mem_rdy(mem_rdy),
	.mem_wdf_rdy(mem_wdf_rdy),

	// Debugging	
	.state(dram_state),
	.ch()
);


semamem usema1
(
	.rst_i(rst),
  .clk_i(clk60),
  .cs_i(cs_sema),
  .cyc_i(br3_cyc),
  .stb_i(br3_stb),
  .ack_o(sema_ack),
  .we_i(br3_we),
  .adr_i(br3_adr[12:0]),
  .dat_i(br3_dato),
  .dat_o(sema_dato)
);

`ifdef NOC_RING
scratchmem uscr1
(
  .rst_i(rst),
  .clk_i(clk60),
  .cti_i(3'b000),
  .bok_o(scr_bok),
  .cs_i(cs_scr),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_scr),
  .we_i(we),
  .adr_i(adr[13:0]),
  .dat_i(dato),
  .dat_o(scr_dato)
`ifdef SIM
  ,.sp(24'h0)//ucpu1.ucpu1.urf1.mem[{4'd0,6'd63}][35:4])
`else
	,.sp(24'h0)
`endif
);
`else
scratchmem uscr2
(
  .rst_i(rst),
  .clk_i(clk40),
  .cti_i(3'b000),
  .bok_o(scr_bok),
  .cs_i(cs_br),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_br),
  .we_i(we),
  .adr_i(adr[13:0]),
  .dat_i(dato),
  .dat_o(br_dato)
`ifdef SIM
  ,.sp(24'h0)//ucpu1.ucpu1.urf1.mem[{4'd0,6'd63}][35:4])
`else
	,.sp(24'h0)
`endif
);
scratchmem uscr1a
(
  .rst_i(rst),
  .clk_i(clk40),
  .cti_i(3'b000),
  .bok_o(),
  .cs_i(cs_scr0),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_scr0),
  .we_i(we),
  .adr_i(adr[13:0]),
  .dat_i(dato),
  .dat_o(scr0_dato)
`ifdef SIM
  ,.sp(24'h0)//ucpu1.ucpu1.urf1.mem[{4'd0,6'd63}][35:4])
`else
	,.sp(24'h0)
`endif
);
scratchmem uscr1b
(
  .rst_i(rst),
  .clk_i(clk40),
  .cti_i(3'b000),
  .bok_o(),
  .cs_i(cs_scr1),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_scr1),
  .we_i(we),
  .adr_i(adr[13:0]),
  .dat_i(dato),
  .dat_o(scr1_dato)
`ifdef SIM
  ,.sp(24'h0)//ucpu1.ucpu1.urf1.mem[{4'd0,6'd63}][35:4])
`else
	,.sp(24'h0)
`endif
);
scratchmem uscr1c
(
  .rst_i(rst),
  .clk_i(clk40),
  .cti_i(3'b000),
  .bok_o(),
  .cs_i(cs_scr2),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_scr2),
  .we_i(we),
  .adr_i(adr[13:0]),
  .dat_i(dato),
  .dat_o(scr2_dato)
`ifdef SIM
  ,.sp(24'h0)//ucpu1.ucpu1.urf1.mem[{4'd0,6'd63}][35:4])
`else
	,.sp(24'h0)
`endif
);
scratchmem uscr1d
(
  .rst_i(rst),
  .clk_i(clk40),
  .cti_i(3'b000),
  .bok_o(),
  .cs_i(cs_scr3),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_scr3),
  .we_i(we),
  .adr_i(adr[13:0]),
  .dat_i(dato),
  .dat_o(scr3_dato)
`ifdef SIM
  ,.sp(24'h0)//ucpu1.ucpu1.urf1.mem[{4'd0,6'd63}][35:4])
`else
	,.sp(24'h0)
`endif
);
`endif

//assign ack_scr = 1'b0;
//assign scr_dato = 64'd0;
/*
bootrom128 #(128) ubr1
(
	.rst_i(rst),
  .clk_i(cpu_clk),
	.cti_i(cti),
  .bok_o(br_bok),
  .cs_i(cs_br),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_br),
  .adr_i(adr[17:0]),
  .dat_o(br_dato)
);
*/
/*
assign br_bok = 1'b0;
assign ack_br = 1'b0;
assign br_dato = 128'd0;
*/
(* mark_debug="true" *)
wire err;
BusError ube1
(
	.rst_i(rst),
	.clk_i(clk60),
	.cyc_i(cyc),
	.ack_i(ack1),
	.stb_i(stb),
	.adr_i(adr),
	.err_o(err)
);

wire xbTMDS_OUT_clk_p, xbTMDS_OUT_clk_n;
wire [2:0] xbTMDS_OUT_data_p, xbTMDS_OUT_data_n;
wire xbTMDS_IN_clk_p, xbTMDS_IN_clk_n;
wire [2:0] xbTMDS_IN_data_p, xbTMDS_IN_data_n;
wire xbClkRecovered, xbClkRecovered2;
wire [35:0] xb_rcvData;
wire [35:0] xbdi;
wire xb_deo,xb_deo1;
wire [35:0] xbdo, xbdo1;
wire xb_synco, xb_synco1;
wire xb_synci, xb_dei;
wire xb_synci1, xb_dei1;
wire xb_err = 1'b0;
/*
xbusTransmitter #(
  .kParallelWidth(14),
	.kGenerateBitClk(1'b0),
	.kClkPrimitive("MMCM"),
	.kClkRange(3),
	.kRstActiveHigh(1'b1)
)
uxbt2
(
	.TMDS_Clk_p(xbTMDS_IN_clk_p),
	.TMDS_Clk_n(xbTMDS_IN_clk_n),
	.TMDS_Data_p(xbTMDS_IN_data_p),
	.TMDS_Data_n(xbTMDS_IN_data_n),
	.aRst(rst),
	.aRst_n(~rst),
	.dat_i(xbdo1),
	.sync_i(xb_synco1),
	.de_i(xb_deo1),
	.PacketClk(xb57),
	.BitClk(xb400)
);

xbusReceiver #(
  .kParallelWidth(14)
)
uxbr1
(
  .TMDS_Clk_p(xbTMDS_OUT_clk_p),
  .TMDS_Clk_n(xbTMDS_OUT_clk_n),
  .TMDS_Data_p(xbTMDS_OUT_data_p),
  .TMDS_Data_n(xbTMDS_OUT_data_n),
  
  .RefClk(xb400),
  .aRst(rst),
  .aRst_n(~rst),
  
  .dat_o(xb_rcvData),
  .sync_o(xb_synci1),
  .de_o(xb_dei1),
 
  .PacketClk(xbClkRecovered),
  .BitClk(),     // not used
  .aPacketClkLckd(), // not used

  .DDC_SDA_I(), // not used
  .DDC_SDA_O(), // not used
  .DDC_SDA_T(), // not used
  .DDC_SCL_I(), // not used
  .DDC_SCL_O(), // not used       
  .DDC_SCL_T(), // not used
  
  .pRst(rst),
  .pRst_n(~rst),
  .pDeviceNum(6'd1)
);

xbusSlaveBridge uxbsb1
(
  .dev_num_i(4'd1),
  .rst_i(rst),
  .clk_i(xb57),
  .rclk_i(xbClkRecovered),
  .cyc_o(xb_cyc),
  .stb_o(xb_stb),
  .ack_i(xb_sack),
  .we_o(xb_we),
  .sel_o(xb_sel),
  .adr_o(xb_adr),
  .dat_o(xb_dato),
  .dat_i(xb_dati),
  .xb_dat_i(xb_rcvData),
  .xb_dat_o(xbdo1),
  .xb_sync_i(xb_synci1),
  .xb_de_i(xb_dei1),
  .xb_sync_o(xb_synco1),
  .xb_de_o(xb_deo1)
);

xbusTransmitter #(
  .kParallelWidth(14),
	.kGenerateBitClk(1'b0),
	.kClkPrimitive("MMCM"),
	.kClkRange(3),
	.kRstActiveHigh(1'b1)
)
uxbt1 
(
	.TMDS_Clk_p(xbTMDS_OUT_clk_p),
	.TMDS_Clk_n(xbTMDS_OUT_clk_n),
	.TMDS_Data_p(xbTMDS_OUT_data_p),
	.TMDS_Data_n(xbTMDS_OUT_data_n),
	.aRst(rst),
	.aRst_n(~rst),
	.dat_i(xbdo),
	.sync_i(xb_synco),
	.de_i(xb_deo),
	.PacketClk(xb57),
	.BitClk(xb400)
);

xbusReceiver #(
  .kParallelWidth(14)
)
uxbr2
(
  .TMDS_Clk_p(xbTMDS_IN_clk_p),
  .TMDS_Clk_n(xbTMDS_IN_clk_n),
  .TMDS_Data_p(xbTMDS_IN_data_p),
  .TMDS_Data_n(xbTMDS_IN_data_n),
  
  .RefClk(xb400),
  .aRst(rst),
  .aRst_n(~rst),
  
  .dat_o(xbdi),
  .sync_o(xb_synci),
  .de_o(xb_dei),
 
  .PacketClk(xbClkRecovered2),
  .BitClk(),     // not used
  .aPacketClkLckd(), // not used

  .DDC_SDA_I(), // not used
  .DDC_SDA_O(), // not used
  .DDC_SDA_T(), // not used
  .DDC_SCL_I(), // not used
  .DDC_SCL_O(), // not used       
  .DDC_SCL_T(), // not used
  
  .pRst(rst),
  .pRst_n(~rst),
  .pDeviceNum(6'd1)
);

xbusBridge uxbb1
(
  .bridge_num_i(4'd1),
  .rst_i(rst),
  .clk_i(xb57),
  .rclk_i(xbClkRecovered2),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(xb_ack),
  .berr_o(xb_err),
  .we_i(we),
  .sel_i(sel),
  .adr_i(adr),
  .dat_i(dato),
  .dat_o(xb_dato),
  .xbd_o(xbdo),
  .xb_sync_o(xb_synco),
  .xb_de_o(xb_deo),
  .xbd_i(xbdi),
  .xb_sync_i(xb_synci),
  .xb_de_i(xb_dei)
);
*/

Packet packet_i, packet_o;
Packet rpacket_i, rpacket_o;
IPacket ipacket_i, ipacket_o;
wire [3:0] irqo;

`ifdef NOC_RING
node_ring_x1 unr1 (
	.rst_i(rst),
	.clk_i(clk40),
	.packet_i(packet_i),
	.packet_o(packet_o),
	.rpacket_i(rpacket_i),
	.rpacket_o(rpacket_o),
	.ipacket_i(ipacket_i),
	.ipacket_o(ipacket_o)
);

nic unic1
(
	.id(6'd62),
	.rst_i(rst),
	.clk_i(clk40),
	.s_cyc_i(1'b0),
	.s_stb_i(1'b0),
	.s_ack_o(),
	.s_rty_o(),
	.s_we_i(1'b0),
	.s_adr_i(24'h0),
	.s_dat_i(12'h00),
	.s_dat_o(),
	.m_cyc_o(cyc),
	.m_stb_o(stb),
	.m_ack_i(ack1),
	.m_we_o(we),
	.m_adr_o(adr),
	.m_dat_o(dato),
	.m_dat_i(dati),
	.packet_i(packet_o),
	.packet_o(packet_i),
	.rpacket_i(rpacket_o),
	.rpacket_o(rpacket_i),
	.ipacket_i(ipacket_o),
	.ipacket_o(ipacket_i),
	.irq_i(irq),
	.firq_i(firq),
	.cause_i(cause),
	.iserver_i(iserver),
	.irq_o(),
	.firq_o(),
	.cause_o()
);
`else
rf6809 ucpu1
(
	.id(6'd2),
	.rst_i(rst),
	.clk_i(clk40),
	.halt_i(1'b0),
	.nmi_i(1'b0),
	.irq_i(irq),
	.firq_i(firq),
	.vec_i(24'h0),
	.ba_o(),
	.bs_o(),
	.lic_o(),
	.tsc_i(1'b0),
	.rty_i(1'b0),
	.bte_o(),
	.cti_o(cti),
	.bl_o(),
	.lock_o(),
	.cyc_o(cyc),
	.stb_o(stb),
	.we_o(we),
	.ack_i(ack1),
	.aack_i(1'b0),
	.atag_i(4'h0),
	.adr_o(adr),
	.dat_i(dati),
	.dat_o(dato),
	.state()
);
`endif

rf6809_pic upic1
(
	.rst_i(rst),		// reset
	.clk_i(clk40),		// system clock
	.cs_i(cs_pic),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(pic_ack),       // controller is ready
	.wr_i(we),			// write
	.adr_i(adr[7:0]),	// address
	.dat_i(dato),
	.dat_o(pic_dat),
	.vol_o(),		// volatile register selected
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
	.i29(1'b0),
	.i30(1'b0),
	.i31(1'b0),
	.irqo(irqo),	// normally connected to the processor irq
	.nmii(1'b0),		// nmi input connected to nmi requester
	.nmio(),	// normally connected to the nmi of cpu
	.causeo(cause),
	.server_o(iserver)
);
assign irq = irqo[0];
assign firq = irqo[1];

`ifdef NOC_RING
ila_0 uila1 (
	.clk(clk40), // input wire clk
	.probe0(packet_o), // input wire [63:0]  probe0  
	.probe1({unr1.pc[0][23:0]}), // input wire [63:0]  probe0  
	.probe2({unr1.pc[0][23:0]}), // input wire [63:0]  probe0  
	.probe3({unr1.pc[1][23:0]}), // input wire [63:0]  probe0  
	.probe4({unr1.pc[1][23:0]}) // input wire [63:0]  probe0  
);
`else
ila_0 uila1 (
	.clk(clk40), // input wire clk
	.probe0(packet_o), // input wire [63:0]  probe0  
	.probe1({ucpu1.pc[23:0]}), // input wire [63:0]  probe0  
	.probe2({adr[23:0]}), // input wire [63:0]  probe0  
	.probe3({cyc,stb,ack1}), // input wire [63:0]  probe0  
	.probe4({dato,dati}) // input wire [63:0]  probe0  
);
`endif

/*
rf6809 ucpu1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.halt_i(1'b0),
	.nmi_i(1'b0),
	.irq_i(1'b0),
	.firq_i(1'b0),
	.vec_i(24'h0),
	.ba_o(),
	.bs_o(),
	.lic_o(),
	.tsc_i(1'b0),
	.rty_i(1'b0),
	.bte_o(),
	.cti_o(cti),
	.bl_o(),
	.lock_o(),
	.cyc_o(cyc),
	.stb_o(stb),
	.we_o(we),
	.ack_i(ack1),
	.adr_o(adr),
	.dat_i(dati),
	.dat_o(dato),
	.state()
);
*/

/*
ila_0 uila1 (
	.clk(clk40), // input wire clk
	.probe0(ucpu1.ucpu1.ip), // input wire [23:0]  probe0  
	.probe1(ucpu1.ucpu1.ir[31:0]), // input wire [31:0]  probe1 
	.probe2(ucpu1.ucpu1.adr_o), // input wire [23:0]  probe2 
	.probe3(ucpu1.ucpu1.rob_exec), // input wire [7:0]  probe3 
	.probe4({ucpu1.ucpu1.cyc_o,ucpu1.ucpu1.ack_i,ucpu1.ucpu1.we_o,cs_dram,dram_ack,cr,ack_bridge3,pti_ack}), // input wire [7:0]  probe4 
	.probe5({4'h0,dram_state}) // input wire [7:0]  probe5
);
*/
// -----------------------------------------------------------------------------
// UART
// -----------------------------------------------------------------------------

uart6551 uuart1
(
	.rst_i(rst),
	.clk_i(clk40),
	.cs_i(cs_uart),
	.irq_o(uart_irq),
	.cyc_i(br3_cyc),
	.stb_i(br3_stb),
	.ack_o(uart_ack),
	.we_i(br3_we),
	.adr_i(br3_adr[3:0]),
	.dat_i(br3_dat),
	.dat_o(uart_dato),
	.cts_ni(1'b0),
	.rts_no(),
	.dsr_ni(1'b0),
	.dcd_ni(1'b0),
	.dtr_no(),
	.ri_ni(1'b1),
	.rxd_i(uart_rxd),
	.txd_o(uart_txd),
	.data_present(),
	.rxDRQ_o(),
	.txDRQ_o(),
	.xclk_i(clk14),
	.RxC_i(1'b0)
);


/*
edge_det uedrst (.clk(cpu_clk), .ce(1'b1), .i(rst), .pe(), .ne(ne_rst), .ee());

nvioILA uila1
(
	.clk(clk40),
	.probe0(ucpu1.ucpu1.ip), // input wire [31:0]  probe0  
	.probe1(ucpu1.ucpu1.vadr), // input wire [31:0]  probe1 
	.probe2(ucpu1.ucpu1.dat_o[31:0]), // input wire [31:0]  probe2 
	.probe3({ucpu1.ucpu1.icstate,bmp_cyc,cs_scr,cs_dram,cs_led}), // input wire [7:0]  probe3 
	.probe4(8'h00), // input wire [7:0]  probe4 
	.probe5(8'h00) // input wire [7:0]  probe5
);
*/

/*
ila_0 uila1 (
	.clk(clk40), // input wire clk

	.trig_in(btnu_db),// input wire trig_in 
	.trig_in_ack(),// output wire trig_in_ack 

	.probe0(ucpu1.ucpu1.pc0[23:0]), // input wire [31:0]  probe0  
	.probe1(ucpu1.ucpu1.insn0[31:0]), // input wire [7:0]  probe1 
	.probe2(ucpu1.ucpu1.vadr),
	.probe3(ucpu1.ucpu1.ihit), // input wire [0:0]  probe2 
	.probe4({err,ack_br,
		ucpu1.ucpu1.alu0_exc,
		bmp_cyc,bmp_acki,cyc,cs_dram,dram_ack,ucpu1.ucpu1.iqentry_state[0],ucpu1.ucpu1.iqentry_state[1],ucpu1.ucpu1.iqentry_state[2],ucpu1.ucpu1.iqentry_state[3]}), // input wire [0:0]  probe3 
	.probe5({ucpu1.ucpu1.icstate}), // input wire [0:0]  probe4
	.probe6(adr)
);
*/
/*
ila_0 uila1 (
	.clk(clk40), // input wire clk


	.probe0(ucpu1.ucpu1.ip[23:0]), // input wire [24:0]  probe0  
	.probe1(ucpu1.ucpu1.ir), // input wire [35:0]  probe1 
//	.probe2(ucpu1.ucpu1.adr_o[31:0]), // input wire [31:0]  probe2 
	.probe2(ucpu1.ucpu1.adr_o), // input wire [31:0]  probe2 
	.probe3(ucpu1.ucpu1.t0), // input wire [31:0]  probe3
	.probe4(ucpu1.ucpu1.ubiu.fifoToCtrl_empty),
	.probe5(ucpu1.ucpu1.advance_d),
	.probe6(ucpu1.ucpu1.wcause),
	.probe7(ucpu1.ucpu1.ubiu.state),
//	.probe7({ucpu1.ucpu1.advance_w,ucpu1.ucpu1.xJxz,ucpu1.ucpu1.takb,cs_rnd,ack_bridge2}),

	.probe7(
	{
		ucpu1.ucpu1.rob[7].ui,
		ucpu1.ucpu1.rob[6].ui,
		ucpu1.ucpu1.rob[5].ui,
		ucpu1.ucpu1.rob[4].ui,
		ucpu1.ucpu1.rob[3].ui,
		ucpu1.ucpu1.rob[2].ui,
		ucpu1.ucpu1.rob[1].ui,
		ucpu1.ucpu1.rob[0].ui
	}),

	.probe8(ucpu1.ucpu1.micro_ip),
	.probe9({
		ucpu1.ucpu1.cyc_o,
		ucpu1.ucpu1.stb_o,
		ucpu1.ucpu1.ack_i,
		ucpu1.ucpu1.we_o,
		cs_br,
		ack_br
	}),
	.probe10(ucpu1.ucpu1.dat_i[31:0]),
	.probe11(ucpu1.ucpu1.ubiu.desc_out.base[31:0])
//	.probe11(ucpu1.ucpu1.umc1.memreq.adr)
	//.probe6(ucpu1.ucpu1.memreq.fifo_wr)
);
*/
IOBridge u_bridge3
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge3),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br3_cdato),

	.s2_cyc_i(1'b0),
	.s2_stb_i(1'b0),
	.s2_ack_o(),
	.s2_we_i(1'b0),
	.s2_adr_i(24'h0),
	.s2_dat_i(8'h0),
	.s2_dat_o(),

	.m_cyc_o(br3_cyc),
	.m_stb_o(br3_stb),
	.m_ack_i(br3_ack),
	.m_we_o(br3_we),
	.m_adr_o(br3_adr),
	.m_dat_i(br3_dati),
	.m_dat_o(br3_dato)
);

reg br3_ack1;
always_comb br3_ack1 <= rtc_ack|spi_ack|sdc_ack|pti_ack|uart_ack|sema_ack;
always_ff @(posedge cpu_clk)
	br3_ack <= br3_ack1;

//wire [8:0] uart_rd_data_count;
//wire uart_tx_fifo_full;
wire cs_br3 = cs_rtc|cs_spi|cs_sdc|cs_pti|cs_uart|cs_sema;
always_ff @(posedge cpu_clk)
	if (cs_br3)
		br3_dati <= {8{rtc_cdato}}|{8{spi_dato}}|{2{sdc_cdato}}|pti_cdato|{2{uart_dato}}|{8{sema_dato}};
	else
		br3_dati <= 64'h0;
/*
always_ff @(posedge cpu_clk)
casez({rtc_ack,spi_ack,sdc_ack,pti_ack,uart_ack,sema_ack})
6'b1?????:	br3_dati <= {8{rtc_cdato}};
6'b01????:	br3_dati <= {8{spi_dato}};
6'b001???:	br3_dati <= {2{sdc_cdato}};
6'b0001??:	br3_dati <= pti_cdato;
6'b00001?:	br3_dati <= {2{uart_dato}};
6'b000001:  br3_dati <= {8{sema_dato}};
default:	br3_dati <= br3_dati;
endcase
*/

wire rtc_clko, rtc_datao;
wire rtc_clk_en,rtc_data_en;
assign rtc_clk = rtc_clk_en ? 1'bz : rtc_clko;
assign rtc_data = rtc_data_en ? 1'bz : rtc_datao;

`ifdef I2C_MASTER
i2c_master_top ui2c2
(
	.wb_clk_i(cpu_clk),
	.wb_rst_i(rst),
	.cs_i(cs_rtc),
	.wb_adr_i(br3_adr32[2:0]),
	.wb_dat_i(br3_dat8),
	.wb_dat_o(rtc_cdato),
	.wb_we_i(br3_we),
	.wb_stb_i(br3_stb),
	.wb_cyc_i(br3_cyc),
	.wb_ack_o(rtc_ack),
	.wb_inta_o(),
	.scl_pad_i(rtc_clk),
	.scl_pad_o(rtc_clko),
	.scl_padoen_o(rtc_clk_en),
	.sda_pad_i(rtc_data),
	.sda_pad_o(rtc_datao),
	.sda_padoen_o(rtc_data_en)
);
`else
assign rtc_ack = cs_rtc & br3_cyc & br3_stb;
assign rtc_dato = 1'b0;
`endif


`ifdef SPI_MASTER
spiMaster uspi1
(
  .clk_i(cpu_clk),
  .rst_i(rst),
  .address_i(br3_adr32[7:0]),
  .data_i(br3_dat8),
  .data_o(spi_dato),
  .strobe_i(cs_spi & br3_cyc & br3_stb),
  .we_i(br3_we),
  .ack_o(spi_ack),
  .rdy_o(),

  // SPI logic clock
  .spiSysClk(cpu_clk),

  //SPI bus
  .spiClkOut(spiClkOut),
  .spiDataIn(spiDataIn),
  .spiDataOut(spiDataOut),
  .spiCS_n(spiCS_n)
);
`else
assign spi_ack = cs_spi & br3_cyc & br3_stb;
assign spi_dato = 1'b0;
`endif

wire sd_cmdi, sd_cmdo;
wire sd_cmdoe, sd_datoe;
wire [3:0] sd_dati, sd_dato;
`ifdef SDC_CONTROLLER
assign sd_cmd = sd_cmdoe ? sd_cmdo : 1'bz;
assign sd_cmdi = sd_cmd;
assign sd_dat = sd_datoe ? sd_dato : 4'bz;
assign sd_dati = sd_dat;
sdc_controller usdc1
(
  .wb_clk_i(cpu_clk),
  .wb_rst_i(rst),

  // WISHBONE slave
  .cs_i(cs_sdc),
  .wb_cyc_i(br3_cyc),
  .wb_stb_i(br3_stb),
  .wb_ack_o(sdc_ack),
  .wb_we_i(br3_we),
  .wb_sel_i(br3_sel32),
  .wb_adr_i(br3_adr32[7:0]),
  .wb_dat_i(br3_dat32),
  .wb_dat_o(sdc_cdato),

  // WISHBONE master
  .m_wb_cti_o(),
  .m_wb_bte_o(),
  .m_wb_cyc_o(sdc_cyc),
  .m_wb_stb_o(sdc_stb),
  .m_wb_ack_i(sdc_acki),
  .m_wb_we_o(sdc_we),
  .m_wb_sel_o(sdc_sel),
  .m_wb_adr_o(sdc_adr),
  .m_wb_dat_o(sdc_dato),
  .m_wb_dat_i(sdc_dati), 

  //SD BUS
  .sd_cmd_dat_i(sd_cmdi),
  .sd_cmd_out_o(sd_cmdo),
  .sd_cmd_oe_o(sd_cmdoe),
  .card_detect(sd_cd),
  .sd_dat_dat_i(sd_dati),
  .sd_dat_out_o(sd_dato),
  .sd_dat_oe_o(sd_datoe),
  .sd_clk_o_pad(sd_clk),
  
  .sd_clk_i_pad(clk40)

/*
  `ifdef SDC_CLK_SEP
   ,sd_clk_i_pad
  `endif
  `ifdef SDC_IRQ_ENABLE
   ,int_a, int_b, int_c  
  `endif
*/

);
`else
assign sd_cmd = 1'bz;
assign sd_cmdi = sd_cmd;
assign sd_dat = 4'bz;
assign sd_dati = sd_dat;
assign sdc_ack = 1'b0;
assign sdc_cdato = 32'd0;
assign sdc_cyc = 1'b0;
assign sdc_stb = 1'b0;
assign sdc_we = 1'b0;
assign sdc_sel = 4'h0;
assign sdc_adr = 32'd0;
assign sdc_dato = 32'd0;
`endif

/*
rfPti upti1(
	.rst_i(rst),
	.clk_i(pti_clk),
	.rxf_ni(pti_rxf),
	.txe_ni(pti_txe),
	.rd_no(pti_rd),
	.wr_no(pti_wr),
	.spien_i(spien),
  .siwu_no(pti_siwu),
	.oe_no(pti_oe),
	.dat_io(pti_dat),
	.cs_i(cs_pti),
	.w_clk_i(cpu_clk),
	.sirq_o(),
	.dirq_o(),
	.s_cyc_i(br3_cyc),
	.s_stb_i(br3_stb),
	.s_ack_o(pti_ack),
	.s_we_i(br3_we),
	.s_sel_i(br3_sel),
	.s_adr_i(br3_adr[7:0]),
	.s_dat_i(br3_dato),
	.s_dat_o(pti_cdato),
	.m_cyc_o(pti_cyc),
	.m_stb_o(pti_stb),
	.m_ack_i(pti_acki),
	.m_we_o(pti_we),
	.m_sel_o(pti_sel),
	.m_adr_o(pti_adr),
	.m_dat_i(pti_dati),
	.m_dat_o(pti_dato)
);
*/

/*
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

rtfUart uuart1
(
	.rst_i(rst),
	.clk_i(clk100),
	.cs_i(cs_uart),
	.cyc_i(br3_cyc),
	.stb_i(br3_stb),
	.ack_o(uart_ack),
	.we_i(br3_we),
	.sel_i(br3_sel32),
	.adr_i(br3_adr32[3:2]),
	.dat_i(br3_dat32),
	.dat_o(uart_dato),
	.cts_ni(1'b0),
	.rts_no(),
	.dsr_ni(1'b0),
	.dcd_ni(1'b0),
	.dtr_no(),
	.ri_ni(1'b1),
	.rxd_i(uart_rxd),
	.txd_o(uart_txd),
	.data_present(),
	.rxDRQ_o(),
	.txDRQ_o(),
	.xclk_i(1'b0),
	.RxC_i(1'b0)
);
*/
/*
reg wr_tx;
reg wr_utxFifo;
wire txFifoEmpty;
wire tx_empty;
wire [7:0] txdata;

always @(posedge clk14)
	wr_tx <= tx_empty & !txFifoEmpty;

edge_det utxfed1 (.rst(rst), .clk(cpu_clk), .ce(1'b1), .i(cs_uart), .pe(pe_cs_uart), .ne(), .ee());
always @(posedge cpu_clk)
	wr_utxFifo <= pe_cs_uart && br3_we && br3_cyc && br3_stb && br3_adr[4:3]==2'd0;

rtfSimpleUartTx utx1
(
	// WISHBONE SoC bus interface
	.rst_i(rst),
	.clk_i(clk14),
	.cyc_i(wr_tx),
	.stb_i(wr_tx),
	.ack_o(),
	.we_i(wr_tx),
	.dat_i(txdata),
	//--------------------
	.cs_i(1'b1),
	.baud16x_ce(1'b1),
  .baud8x(1'b0),
	.cts(1'b1),
	.txd(uart_txd),
	.empty(tx_empty),
  .txc()
);

uartTxFifo utxf1
(
  .rst(rst),
  .wr_clk(cpu_clk),
  .rd_clk(clk14),
  .din(br3_dat8),
  .wr_en(wr_utxFifo),
  .rd_en(wr_tx),
  .dout(txdata),
  .full(uart_tx_fifo_full),
  .empty(txFifoEmpty),
  .wr_rst_busy(),
  .rd_rst_busy()
);

reg rd_rx, rd_rxd;
reg rd_urxFifo;
wire rx_datapresent;
wire [7:0] rxdata;

always @(posedge cpu_clk)
	rd_urxFifo <= pe_cs_uart && ~br3_we && br3_cyc && br3_stb && br3_adr[4:3]==2'b00;

rtfSimpleUartRx uurx1
(
	// WISHBONE SoC bus interface
	.rst_i(rst),
	.clk_i(clk14),
	.cyc_i(rd_rx),
	.stb_i(rd_rx),
	.ack_o(),
	.we_i(1'b0),
	.dat_o(rxdata),
	//------------------------
	.cs_i(1'b1),
	.baud16x_ce(1'b1),
  .baud8x(1'b0),
	.clear(1'b0),
	.rxd(uart_rxd),
	.data_present(rx_datapresent),
	.frame_err(),
	.overrun()
);

always @(posedge clk14)
	rd_rx <= rx_datapresent;
always @(posedge clk14)
	rd_rxd <= rd_rx;

uartRxFifo urxf1
(
  .rst(rst),
  .wr_clk(clk14),
  .rd_clk(cpu_clk),
  .din(rxdata),
  .wr_en(rd_rxd),
  .rd_en(rd_urxFifo),
  .dout(uart_dato),
  .full(),
  .empty(),
  .rd_data_count(uart_rd_data_count),
  .wr_rst_busy(),
  .rd_rst_busy()
);
*/

endmodule

