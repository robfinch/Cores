// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Petajon-SoC.v
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
//`define ORSOC_GFX	1'b1
`define SOC_FULL
`define TEXT_CONTROLLER	1'b1
`define BMP_CONTROLLER 1'b1		// needed for sync generation
`define SPRITE_CONTROLLER	1'b1
//`define SDC_CONTROLLER 1'b1
//`define GPU_GRID	1'b1
`define RANDOM_GEN	1'b1
`define ETHMAC	1'b1

module PetajonSoC(cpu_resetn, xclk, led, sw, btnl, btnr, btnc, btnd, btnu, 
    kclk, kd, uart_txd, uart_rxd,
    TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n,
    ac_mclk, ac_adc_sdata, ac_dac_sdata, ac_bclk, ac_lrclk,
    rtc_clk, rtc_data,
    spiClkOut, spiDataIn, spiDataOut, spiCS_n,
    sd_cmd, sd_dat, sd_clk, sd_cd, sd_reset,
    pti_clk, pti_rxf, pti_txe, pti_rd, pti_wr, pti_siwu, pti_oe, pti_dat, spien,
    oled_sdin, oled_sclk, oled_dc, oled_res, oled_vbat, oled_vdd
`ifdef ETHMAC
		, eth_mdio, eth_mdc, eth_txclk, eth_txd, eth_txctl, eth_rxclk, eth_rxd, eth_rxctl, eth_int_b, eth_rst_b,
`endif
		eeprom_clk, eeprom_data,
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
output uart_txd;
input uart_rxd;
output TMDS_OUT_clk_p;
output TMDS_OUT_clk_n;
output [2:0] TMDS_OUT_data_p;
output [2:0] TMDS_OUT_data_n;
output ac_mclk;
input ac_adc_sdata;
output ac_dac_sdata;
inout ac_bclk;
inout ac_lrclk;
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
`ifdef ETHMAC
inout eth_mdio;
output eth_mdc;
output eth_txclk;
output [3:0] eth_txd;
output eth_txctl;
input eth_rxclk;
input [3:0] eth_rxd;
input eth_rxctl;
input eth_int_b;
output eth_rst_b;
`endif
inout eeprom_clk;
inout eeprom_data;
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
wire clk10, clk14, clk20, clk25, clk40, clk60, clk80, clk100, clk200;
wire cpu_clk = clk20;
wire cpu_clk2x = clk40;
wire cpu_clk4x = clk80;
wire mem_ui_clk;
wire xclk_bufg;
wire hSync, vSync, blank, border;
wire [7:0] red, blue, green;

wire [2:0] cti;
(* mark_debug = "true" *)
wire cyc;
(* mark_debug = "true" *)
wire stb, ack;
wire we;
wire [15:0] sel;
(* mark_debug = "true" *)
wire [31:0] adr;
reg [63:0] dati = 64'd0;
wire [63:0] dato;
wire sr,cr,rb;
// CPU2 connectors
wire cyc2;
wire stb2;
reg ack2;
wire we2;
wire [15:0] sel2;
wire [31:0] adr2;
reg [63:0] dati2 = 64'd0;
wire [63:0] dato2;
wire sr2, cr2, rb2;

wire [31:0] tc1_rgb;
wire tc1_ack;
wire [63:0] tc1_dato;
wire ack_scr;
(* mark_debug = "true" *)
wire ack_br;
wire ack_br2;
wire [63:0] scr_dato, br_dato, br_dato2;
wire br_bok, scr_bok;
wire rnd_ack;
wire [31:0] rnd_dato;
(* mark_debug="true" *)
wire dram_ack;
wire [63:0] dram_dato;
wire dram_ack2;
wire [63:0] dram_dato2;
wire avic_ack;
wire [63:0] avic_dato;
wire [31:0] avic_rgb;
wire kbd_rst;
wire kbd_ack;
wire [7:0] kbd_dato;
wire kbd_irq;

wire spr_ack;
wire [63:0] spr_dato;
(* mark_debug = "true" *)
wire spr_cyc;
wire spr_stb;
(* mark_debug = "true" *)
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

wire ack_1761;

wire ack_bridge1;
wire ack_bridge1a;
wire br1_cyc;
wire br1_stb;
reg br1_ack = 1'b0;
wire br1_we;
wire [7:0] br1_sel;
wire [3:0] br1_sel32;
wire [31:0] br1_adr;
wire [31:0] br1_adr32;
wire [63:0] br1_cdato;
wire [63:0] br1_cdato2;
wire br1_s2_ack;
wire [63:0] br1_s2_cdato;
wire [63:0] br1_dato;
wire [31:0] br1_dat32;
wire [7:0] br1_dat8;
reg [63:0] br1_dati = 64'd0;

wire ack_bridge2;
wire ack_bridge2a;
wire br2_cyc;
wire br2_stb;
reg br2_ack = 1'b0;
wire br2_we;
wire [7:0] br2_sel;
wire [3:0] br2_sel32;
wire [31:0] br2_adr;
wire [31:0] br2_adr32;
wire [63:0] br2_cdato;
wire [63:0] br2_cdato2;
wire [63:0] br2_dato;
wire [31:0] br2_dat32;
wire [7:0] br2_dat8;
reg [63:0] br2_dati = 64'd0;

wire ack_bridge3;
wire ack_bridge3a;
wire br3_cyc;
wire br3_stb;
reg br3_ack = 1'b0;
wire br3_we;
wire [7:0] br3_sel;
wire [3:0] br3_sel32;
wire [31:0] br3_adr;
wire [31:0] br3_adr32;
wire [63:0] br3_cdato;
wire [63:0] br3_cdato2;
wire [63:0] br3_dato;
wire [31:0] br3_dat32;
wire [7:0] br3_dat8;
reg [63:0] br3_dati = 64'd0;

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
wire [63:0] aud_cdato;

wire rtc_ack;
wire [7:0] rtc_cdato;
wire spi_ack;
wire [7:0] spi_dato;

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
wire grid_ack;
wire grid_we;
wire [3:0] grid_sel;
wire [31:0] grid_adr;
reg [31:0] grid_dati = 32'd0;
wire grid_dram_ack;
wire [63:0] grid_dram_dati1;
wire [31:0] grid_dato;
wire [31:0] grid_zrgb;

wire uart_ack;
wire [31:0] uart_dato;
wire via_ack;
wire [31:0] via_dato;
wire [31:0] pa_o;
wire [31:0] pa_i;
wire ack_pic;
wire [31:0] pic_dato;
wire ack_sema;
wire [7:0] sema_dato;
wire ack_mut;
wire [63:0] mut_dato;
wire eth_ack;
wire [31:0] eth_cdato;

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
  .clk80(clk80),		// cpu 4x
  .clk40(clk40),		// cpu 2x / display
  .clk20(clk20),		// cpu
//  .clk10(clk10),
  .clk14(clk14),		// 16x baud clock
  .clk25(clk25),
  // Status and control signals
  .reset(xrst), 
  .locked(locked),       // output locked
 // Clock in ports
  .clk_in1(xclk_bufg)
);
assign rst = !locked;
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
	.clk(xclk_bufg),
	.adr_i(adr),
	.dat_i(dati[31:0]),
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
wire cs_dram = adr[31:29]==3'h0;		// Main memory 512MB
wire cs_dram2 = adr2[31:29]==3'h0;		// Main memory 512MB
reg cs_br;
reg cs_br2;
always @*
	cs_br <= adr[31:16]==16'hFFFC		// Boot rom 192k
				|| adr[31:16]==16'hFFFD
				|| adr[31:16]==16'hFFFE;
always @*
	cs_br2 <= adr2[31:16]==16'hFFFC		// Boot rom 192k
				|| adr2[31:16]==16'hFFFD
				|| adr2[31:16]==16'hFFFE;
wire cs_scr = adr[31:22]==10'b1111_1111_01;	// Scratchpad memory 64k
// No need to check for the $FFD in the top 12 address bits as these are 
// detected in the I/O bridges.
wire cs_tc1 = br1_adr[19:16]==4'h0	// FFD0xxxx Text Controller 128k
					||  br1_adr[19:16]==4'h1;
wire cs_spr = br1_adr[19:12]==8'hAD;	// FFDADxxx	Sprite Controller
wire cs_bmp = br1_adr[19:12]==8'hC5;	//          Bitmap Controller
wire cs_pic = br1_adr[19:8]==12'hC0F;
wire cs_sema = br1_adr[19:12]==8'hB0;
wire cs_mut = br1_adr[19:8]==12'hBFF;
//wire cs_bmp = 1'b0;
//wire cs_avic = br1_adr[31:13]==19'b1111_1111_1101_1100_110;	// FFDCC000-FFDCDFFF
wire cs_avic = 1'b0;									// defunct: audio / video controller
wire cs_gfx00 = br1_adr[19:12]==8'hD8;		// orsoc graphics accelerator
wire cs_rnd = br2_adr[19:8]==12'hC0C;		// PRNG random number generator
wire cs_via = br3_adr[19:8]==12'hC06;		// LEDS,buttons,switches
wire cs_kbd  = br2_adr[19:4]==16'hC000;		// keyboard controller
wire cs_aud  = br2_adr[19:8]==12'h510;		// audio controller
wire cs_1761 = br2_adr[19:4]==16'hC070;		// AC97 controller
wire cs_cmdc = br2_adr[19:4]==16'hC080;
wire cs_grid = br2_adr[19:8]==12'h520;		// graphics grid computer
wire cs_imem = br2_adr[19:12]==8'hC8 		// instruction memory for grid computer
						|| br2_adr[19:12]==8'hC9
						|| br2_adr[19:12]==8'hCA
						|| br2_adr[19:12]==8'hCB
						;
wire cs_eth = br2_adr[19:12]==8'hC2;
wire cs_rtc = br3_adr[19:4]==16'hC020;		// real-time clock chip
wire cs_spi = br3_adr[19:8]==12'hC05;			// spi controller
wire cs_sdc = br3_adr[19:8]==12'hC0B;			// sdc controller
wire cs_pti = br3_adr[19:8]==12'hC12;			// parallel transfer interface
wire cs_uart = br3_adr[19:4]==16'hC0A0;
wire cs_eeprom = br3_adr[19:4]==16'hC0E1;

//wire cs_gfx00 = gbr1_adr[31:12]==20'hFFDD8 && gbr1_cyc && gbr1_stb;
wire cs_gfx01 = gbr1_adr[19:12]==8'hD9 && gbr1_cyc && gbr1_stb;	// orsoc graphics accelerator
wire cs_gfx10 = gbr1_adr[19:12]==8'hDA && gbr1_cyc && gbr1_stb;	// orsoc graphics accelerator
wire cs_gfx11 = gbr1_adr[19:12]==8'hDB && gbr1_cyc && gbr1_stb;	// orsoc graphics accelerator

wire cs_bridge1 = (cs_gfx00 | cs_avic | cs_tc1 | cs_spr | cs_bmp) & (br1_cyc & br1_stb);
wire cs_bridge2 = (cs_rnd | cs_kbd | cs_aud | cs_1761 | cs_cmdc | cs_grid | cs_imem) & (br2_cyc & br2_stb);


reg [14:0] cmd_core;
always @(posedge cpu_clk)
	if (cs_cmdc & br2_cyc & br2_stb & br2_we)
		cmd_core <= br2_dato[14:0];

`ifdef GPU_GRID
FT_GPUGrid ugpugrid1
(
	.rst_i(rst),
	.imem_wr_i(cs_imem & br2_cyc & br2_stb & br2_we),
	.imem_adr_i(br2_adr[13:0]),
	.imem_dat_i(br2_dat32),
	.cmd_clk_i(cpu_clk),
	.cmd_core_i(cmd_core),
	.wr_cmd_i(cs_grid & br2_cyc & br2_stb & br2_we),
	.cmd_adr_i(br2_adr[7:0]),
	.cmd_dat_i(br2_dato[31:0]),
	.cmd_count_o(),
	.cyc_o(grid_cyc),
	.stb_o(grid_stb),
	.ack_i(grid_ack),
	.we_o(grid_we),
	.sel_o(grid_sel),
	.adr_o(grid_adr),
	.dat_o(grid_dato),
	.dat_i(grid_dati),
	.dot_clk_i(clk40),
	.blank_i(blank),
	.vctr_i(vctr),
	.hctr_i(hctr),
	.fctr_i(fctr),
	.zrgb_o(grid_zrgb)
);
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
	.wb_clk_i(cpu_clk),
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
TextController64 #(.num(1)) tc1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_tc1),
	.cti_i(cti),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(tc1_ack),
	.wr_i(br1_we),
	.sel_i(br1_sel),
	.adr_i(br1_adr[16:0]),
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

wire vb_irq;
`ifdef BMP_CONTROLLER
rtfBitmapController5 #(.MDW(BMPW)) ubmc1
(
	.rst_i(rst),
	.s_clk_i(cpu_clk),
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
	.vblank_o(vb_irq),
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
assgin vb_irq = 1'b0;
`endif

`ifdef SPRITE_CONTROLLER
rtfSpriteController2 usc2
(
	.clk_i(cpu_clk),
	.cs_i(cs_spr),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(spr_ack),
	.we_i(br1_we),
	.sel_i(br1_sel),
	.adr_i(br1_adr[11:0]),
	.dat_i(br1_dato),
	.dat_o(spr_dato),
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
	.border_i(border),
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
assign blank = ~vde;
`else
assign vm_cyc = 1'b0;
assign vm_stb = 1'b0;
assign vm_we = 1'b0;
assign avic_ack = 1'b0;
`endif
/*
wire ack_led = cs_led;
always @(posedge cpu_clk)
begin
//led[0] <= cs_br;
//led[1] <= cs_scr;
//led[2] <= rst;
//led[7:4] <= adr[6:3];
if (cs_led & br2_we)
  led[7:0] <= br2_dato[7:0];
end
*/
//wire [31:0] led_dato = {11'h0,btnc,btnu,btnd,btnl,btnr,8'h00,sw};
assign pa_i = {11'h0,btnc,btnu,btnd,btnl,btnr,8'h00,sw};

reg ack1 = 1'b0;
reg ack1a = 1'b0;
reg ack2b = 1'b0;
assign ack = ack_scr|ack_bridge1|ack_bridge2|ack_bridge3|ack_br|dram_ack;
wire ack2a = ack_bridge1a|ack_bridge2a|ack_bridge3a|ack_br2|dram_ack2;
//assign ack = ack_br;
always @(posedge cpu_clk)
	ack1a <= ack;
always @(posedge cpu_clk)
	ack1 <= ack1a & ack;
always @(posedge cpu_clk)
	ack2b <= ack2a;
always @(posedge cpu_clk)
	ack2 <= ack2b & ack2a;
always @(posedge cpu_clk)
casez({ack_br,ack_scr,ack_bridge1,ack_bridge2,cs_dram,ack_bridge3})
6'b1?????: dati <= br_dato;
6'b01????: dati <= scr_dato;
6'b001???: dati <= br1_cdato;
6'b0001??: dati <= br2_cdato;
6'b00001?: dati <= dram_dato;
6'b000001: dati <= br3_cdato;
default:   dati <= dati;
endcase
always @(posedge cpu_clk)
casez({ack_br2,ack_bridge1a,ack_bridge2a,cs_dram2,ack_bridge3a})
5'b1????: dati2 <= br_dato2;
5'b01???: dati2 <= br1_cdato2;
5'b001??: dati2 <= br2_cdato2;
5'b0001?: dati2 <= dram_dato2;
5'b00001: dati2 <= br3_cdato2;
default:  dati2 <= dati2;
endcase

wire br1_ack1 = tc1_ack|spr_ack|bmp_ack|avic_ack|gfx00_cack|ack_pic|ack_sema|ack_mut;
reg br1_ack1a;
always @(posedge cpu_clk)
	br1_ack1a <= br1_ack1;
always @(posedge cpu_clk)
	br1_ack <= br1_ack1a & br1_ack1;

always @(posedge cpu_clk)
casez({tc1_ack,spr_ack,bmp_ack,avic_ack,gfx00_cack,ack_pic,ack_sema,ack_mut})
8'b1???????:	br1_dati <= tc1_dato;
8'b01??????:	br1_dati <= spr_dato;
8'b001?????:	br1_dati <= bmp_cdato;
8'b0001????:	br1_dati <= avic_dato;
8'b00001???:	br1_dati <= gfx00_cdato;
8'b000001??:	br1_dati <= {2{pic_dato}};
8'b0000001?:	br1_dati <= {8{sema_dato}};
8'b00000001:	br1_dati <= mut_dato;
default:	br1_dati <= br1_dati;
endcase

wire br2_ack1 = rnd_ack|kbd_ack|ack_1761|aud_ack|cs_cmdc|cs_grid|cs_imem|eth_ack;
reg br2_ack1a;
always @(posedge cpu_clk)
	br2_ack1a <= br2_ack1;
always @(posedge cpu_clk)
	br2_ack <= br2_ack1a & br2_ack1;

always @(posedge cpu_clk)
casez({cs_rnd,cs_kbd,aud_ack,cs_eth})
4'b1???:	br2_dati <= {2{rnd_dato}};	// 32 bits reflected twice
4'b01??:	br2_dati <= {8{kbd_dato}};	// 8 bits reflect 8 times
4'b001?:	br2_dati <= aud_cdato;			// 64 bit peripheral
4'b0001:	br2_dati <= {2{eth_cdato}};
default:	br2_dati <= br2_dati;
endcase

wire ack_s2_bridge1;
assign grid_ack = ack_s2_bridge1 | cs_imem | grid_dram_ack;
always @(posedge cpu_clk)
casez({ack_s2_bridge1,grid_dram_ack})
2'b1?:	grid_dati <= grid_adr[3] ? br1_s2_cdato[63:32] : br1_s2_cdato[31:0];
2'b01:	grid_dati <= grid_adr[3] ? grid_dram_dati1[63:32] : grid_dram_dati1[31:0];
default:	grid_dati <= grid_dati;
endcase

IOBridge64 u_video_bridge
(
	.rst_i(rst),
	.clk_i(cpu_clk),

	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge1),
	.s1_sel_i(sel),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br1_cdato),

	.s2_cyc_i(cyc2),
	.s2_stb_i(stb2),
	.s2_ack_o(ack_bridge1a),
	.s2_sel_i(sel2),
	.s2_we_i(we2),
	.s2_adr_i(adr2),
	.s2_dat_i(dato2),
	.s2_dat_o(br1_cdato2),
/*
	.s2_cyc_i(grid_cyc),
	.s2_stb_i(grid_stb),
	.s2_ack_o(ack_s2_bridge1),
	.s2_sel_i(grid_sel << {grid_adr[3:2],2'b0}),
	.s2_we_i(grid_we),
	.s2_adr_i(grid_adr),
	.s2_dat_i({4{grid_dato}}),
	.s2_dat_o(br1_s2_cdato),
*/
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

IOBridge64 u_bridge2
(
	.rst_i(rst),
	.clk_i(cpu_clk),

	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge2),
	.s1_sel_i(sel),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br2_cdato),

	.s2_cyc_i(cyc2),
	.s2_stb_i(stb2),
	.s2_ack_o(ack_bridge2a),
	.s2_sel_i(sel2),
	.s2_we_i(we2),
	.s2_adr_i(adr2),
	.s2_dat_i(dato2),
	.s2_dat_o(br2_cdato2),

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
	.m_dat32_o(br2_dat32),
	.m_dat8_o(br2_dat8)
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
	.adr_i(br2_adr32[4:1]),
	.dat_i(br2_dat32),
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
assign ac_bclk = en_rxtx ? ac_bclk1 : 1'bz;
assign ac_lrclk = en_rxtx ? ac_lrclk1 : 1'bz;
assign ac_dac_sdata = en_tx ? ac_dac_sdata1 : 1'b0;
`else
assign ack_1761 = 1'b0;
assign ac_mclk = 1'b0;
assign ac_bclk = 1'bz;
assign ac_lrclk = 1'bz;
assign ac_dac_sdata = 1'b0;
`endif

PS2kbd u_kybd1
(
	// WISHBONE/SoC bus interface 
	.rst_i(rst),
	.clk_i(cpu_clk),	// system clock
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
	.db(),
	//-------------
  .irq(kbd_irq)
);
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
`endif

wire eth_irq;
wire eth_cyc, eth_stb;
wire eth_acki;
wire eth_we;
wire [3:0] eth_sel;
wire [31:0] eth_adr;
wire [31:0] eth_dato;
wire [31:0] eth_dati;
wire eth_md_o, eth_md_i;
wire eth_mdoe;

ethmac umac1
(
  // WISHBONE common
  .wb_clk_i(cpu_clk),
  .wb_rst_i(rst),

  // WISHBONE slave
  .wb_cyc_i(br2_cyc),
  .wb_stb_i(br2_stb),
  .wb_we_i(br2_we),
  .wb_ack_o(eth_ack),
  .wb_err_o(), 
  .wb_sel_i(br2_sel32),
  .wb_adr_i(br2_adr32),
  .wb_dat_i(br2_dato32),
  .wb_dat_o(eth_cdato), 

  // WISHBONE master
  .m_wb_cti_o(),
  .m_wb_bte_o(), 
  .m_wb_cyc_o(eth_cyc), 
  .m_wb_stb_o(eth_stb),
  .m_wb_ack_i(eth_acki),
  .m_wb_we_o(eth_we), 
  .m_wb_sel_o(eth_sel),
  .m_wb_adr_o(eth_adr),
  .m_wb_dat_i(eth_dati),
  .m_wb_dat_o(eth_dato),
  .m_wb_err_i(), 

  //TX
  .mtx_clk_pad_i(clk25),
  .mtxd_pad_o(eth_txd),
  .mtxen_pad_o(eth_txctl),
  .mtxerr_pad_o(),

  //RX
  .mrx_clk_pad_i(eth_rxclk),
  .mrxd_pad_i(eth_rxd),
  .mrxdv_pad_i(eth_rxctl),
  .mrxerr_pad_i(1'b0),
  .mcoll_pad_i(1'b0),
  .mcrs_pad_i(1'b0),
  
  // MIIM
  .mdc_pad_o(eth_mdc),
  .md_pad_i(eth_md_i),
  .md_pad_o(eth_md_o),
  .md_padoe_o(eth_mdoe),

  .int_o(eth_irq)

  // Bist
`ifdef ETH_BIST
  ,
  // debug chain signals
  mbist_si_i,       // bist scan serial in
  mbist_so_o,       // bist scan serial out
  mbist_ctrl_i        // bist chain shift control
`endif

);
assign eth_md_i = eth_mdio;
assign eth_mdio = eth_mdoe ? eth_md_o : 1'bz;
assign eth_txclk = clk25;
assign eth_rst_b = ~rst;

`ifndef SIM
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

mpmc8 #(.C0W(BMPW), .C1W(64), .C6W(128), .C7W(64), .C8W(128)) umc1
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

	// CPU2
	.cs1(cs_dram2),
	.cyc1(cyc2),
	.stb1(stb2),
	.ack1(dram_ack2),
	.we1(we2),
	.sel1(sel2),
	.adr1(adr2),
	.dati1(dato2),
	.dato1(dram_dato2),
	.sr1(sr2),
	.cr1(cr2),
	.rb1(rb2),
	
	.cyc2(eth_cyc),
	.stb2(eth_stb),
	.ack2(eth_acki),
	.we2(eth_we),
	.sel2(eth_sel),
	.adr2(eth_adr),
	.dati2(eth_dato),
	.dato2(eth_dati),
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
`endif
`ifdef GRID_GFX
	.cyc4(grid_cyc),
	.stb4(grid_stb),
	.ack4(grid_dram_ack),
	.we4(grid_we),
	.sel4(grid_adr[3] ? {grid_sel,4'h0} : {4'h0,grid_sel}),
	.adr4(grid_adr),
	.dati4({2{grid_dato}}),
	.dato4(grid_dram_dati1),
`endif
	.cyc5(spr_cyc),
	.stb5(spr_stb),
	.ack5(spr_acki),
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

	// CPU1
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

	.cyc2(pti_cyc),
	.stb2(pti_stb),
	.ack2(pti_acki),
	.we2(pti_we),
	.sel2(pti_sel),
	.adr2(pti_adr),
	.dati2(pti_dato),
	.dato2(pti_dati),

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
`endif

mutex umut1
(
	.rst(rst),
	.clk(cpu_clk),

	.cs0(cs_mut),
	.cyc0(br1_cyc),
	.stb0(br1_stb),
	.ack0(ack_mut),
	.wr0(br1_we),
	.ad0(br1_adr),
	.i0(br1_dato),
	.o0(mut_dato),

	.cs1(1'b0),
	.cyc1(1'b0),
	.stb1(1'b0),
	.ack1(),
	.wr1(1'b0),
	.ad1(8'h00),
	.i1(64'h0),
	.o1()
);

semamem usema1
(
	.rst(rst),
	.clk(cpu_clk),
	.cs0(cs_sema),
	.cyc0(br1_cyc),
	.stb0(br1_stb),
	.ack0(ack_sema),
	.wr0(br1_we),
	.ad0(br1_adr32[10:0]),
	.i0(br1_dat8),
	.o0(sema_dato),

	.cs1(1'b0),
	.cyc1(1'b0),
	.stb1(1'b0),
	.wr1(1'b0),
	.ad1(11'h0),
	.i1(8'h00)
);


scratchmem uscr1
(
  .rst_i(rst),
  .clk_i(cpu_clk),
  .cti_i(3'b000),
  .bok_o(scr_bok),
  .cs_i(cs_scr),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_scr),
  .we_i(we),
  .sel_i(sel),
  .adr_i(adr[15:0]),
  .dat_i(dato),
  .dat_o(scr_dato)
`ifdef SIM
  ,.sp(32'h0)
`else
	,.sp(32'h0)
`endif
);

//assign ack_scr = 1'b0;
//assign scr_dato = 64'd0;

bootrom #(64) ubr1
(
	.rst_i(rst),
  .clk_i(cpu_clk),
  .cti_i(3'b000),
  .bok_o(br_bok),
  .cs_i(cs_br),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_br),
  .adr_i(adr[17:0]),
  .dat_o(br_dato)
);
//assign br_bok = 1'b0;
//assign ack_br = 1'b0;
//assign br_dato = 128'd0;
bootrom #(64) ubr2
(
	.rst_i(rst),
  .clk_i(cpu_clk),
  .cti_i(3'b000),
  .bok_o(),
  .cs_i(cs_br2),
  .cyc_i(cyc2),
  .stb_i(stb2),
  .ack_o(ack_br2),
  .adr_i(adr2[17:0]),
  .dat_o(br_dato2)
);

(* mark_debug="true" *)
wire err;
BusError ube1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cyc_i(cyc),
	.ack_i(ack1),
	.stb_i(stb),
	.adr_i(adr),
	.err_o(err)
);

wire [7:0] cause;
wire [2:0] pic_irq, pic_irq2;
wire eeprom_irq;

Petajon_pic upic1
(
	.rst_i(rst),		// reset
	.clk_i(cpu_clk),		// system clock
	.cs_i(cs_pic),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(ack_pic),
	.wr_i(br1_we),
	.adr_i(br1_adr32[7:0]),
	.dat_i(br1_dat32),
	.dat_o(pic_dato),
	.vol_o(),
	.i1(1'b0),
	.i2(1'b0),
	.i3(1'b0),
	.i4(eth_irq),
	.i5(1'b0),
	.i6(1'b0),
	.i7(1'b0),
	.i8(vb_irq),
	.i9(1'b0),
	.i10(1'b0),
	.i11(1'b0),
	.i12(~eth_int_b),	// eth_int_b is active low
	.i13(1'b0),
	.i14(1'b0),
	.i15(1'b0),
	.i16(uart_irq),
	.i17(1'b0),
	.i18(1'b0),
	.i19(1'b0),
	.i20(1'b0),
	.i21(1'b0),
	.i22(1'b0),
	.i23(1'b0),
	.i24(1'b0),
	.i25(pti_dirq),
	.i26(pti_sirq),
	.i27(eeprom_irq),
	.i28(kbd_irq),
	.i29(1'b0),
	.i30(1'b0),
	.i31(via_irq),
	.irqo(pic_irq),
	.irqo2(pic_irq2),
	.nmii(1'b0),		// nmi input connected to nmi requester
	.nmio(),	// normally connected to the nmi of cpu
	.causeo(cause)
);
//parameter pIOAddress = 32'hFFDC_0F00;

wire [3:0] ARID, AWID;
wire [3:0] ARID2, AWID2;

Petajon_dba64 ucpu1
(
  .hartid_i(64'h0),
  .rst_i(rst),
  .clk_i(cpu_clk),
 
  .wc_clk_i(clk20),
	.irq_i(|pic_irq),
	.cause_i(cause),
  .cyc_o(cyc),
  .wb_stb_o(stb),
  .ack_i(ack1),
//  .err_i(err),
  .wb_we_o(we),
  .wb_sel_o(sel),
  .wb_adr_o(adr),
  .wb_dat_o(dato),
  .wb_dat_i(dati),
  .sr_o(sr),
  .cr_o(cr),
  .rb_i(rb),
  .AWID(AWID),
  .AWREADY(1'b1),
  .WREADY(1'b1),
  .BID(AWID),
  .BVALID(1'b1),
  .ARREADY(1'b1),
  .ARID(ARID),
  .RVALID(1'b1),
  .RREADY(),
  .RID(ARID),
  .RDATA(dati)
);

Petajon_dba64 ucpu2
(
  .hartid_i(64'h20),
  .rst_i(rst),
  .clk_i(cpu_clk),
 
  .wc_clk_i(clk20),
	.irq_i(|pic_irq2),
	.cause_i(cause),
  .cyc_o(cyc2),
  .wb_stb_o(stb2),
  .ack_i(ack2),
//  .err_i(err),
  .wb_we_o(we2),
  .wb_sel_o(sel2),
  .wb_adr_o(adr2),
  .wb_dat_o(dato2),
  .wb_dat_i(dati2),
  .sr_o(sr2),
  .cr_o(cr2),
  .rb_i(rb2),
  .AWID(AWID2),
  .AWREADY(1'b1),
  .WREADY(1'b1),
  .BID(AWID2),
  .BVALID(1'b1),
  .ARREADY(1'b1),
  .ARID(ARID2),
  .RVALID(1'b1),
  .RREADY(),
  .RID(ARID2),
  .RDATA(dati2)
);

ila_0 uila1 (
	.clk(clk40), // input wire clk

//	.trig_in(btnu_db),// input wire trig_in 
//	.trig_in_ack(),// output wire trig_in_ack 

	.probe0(ucpu1.pc), // input wire [31:0]  probe0  
	.probe1(ucpu1.ir), // input wire [7:0]  probe1 
	.probe2(adr),
	.probe3(dati), // input wire [0:0]  probe2 
	.probe4(cs_eeprom),
	.probe5(eeprom_ack), // input wire [0:0]  probe4
	.probe6(|pic_irq),
	.probe7(br3_stb),
	.probe8(ucpu1.ladr),
	.probe9(uart_irq),
	.probe10(kbd_irq),
	.probe11(via_irq),
	.probe12({ucpu1.mcause[63],ucpu1.mcause[7:0]}),
	.probe13(ucpu1.mstatus[11:0]),
	.probe14(dato)
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


IOBridge64 u_bridge3
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge3),
	.s1_sel_i(sel),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br3_cdato),

	.s2_cyc_i(cyc2),
	.s2_stb_i(stb2),
	.s2_ack_o(ack_bridge3a),
	.s2_sel_i(sel2),
	.s2_we_i(we2),
	.s2_adr_i(adr2),
	.s2_dat_i(dato2),
	.s2_dat_o(br3_cdato2),

	.m_cyc_o(br3_cyc),
	.m_stb_o(br3_stb),
	.m_ack_i(br3_ack),
	.m_we_o(br3_we),
	.m_sel_o(br3_sel),
	.m_adr_o(br3_adr),
	.m_dat_i(br3_dati),
	.m_dat_o(br3_dato),
	.m_sel32_o(br3_sel32),
	.m_adr32_o(br3_adr32),
	.m_dat32_o(br3_dat32),
	.m_dat8_o(br3_dat8)
);

wire br3_ack1 = rtc_ack|spi_ack|sdc_ack|pti_ack|uart_ack|via_ack|eeprom_ack;
reg br3_ack1a;
always @(posedge cpu_clk)
	br3_ack1a <= br3_ack1;
always @(posedge cpu_clk)
	br3_ack <= br3_ack1a & br3_ack1;

//wire [8:0] uart_rd_data_count;
//wire uart_tx_fifo_full;
wire [7:0] eeprom_cdato;

always @(posedge cpu_clk)
casez({rtc_ack,spi_ack,sdc_ack,cs_pti,cs_uart,cs_via,cs_eeprom})
7'b1??????:	br3_dati <= {8{rtc_cdato}};
7'b01?????:	br3_dati <= {8{spi_dato}};
7'b001????:	br3_dati <= {2{sdc_cdato}};
7'b0001???:	br3_dati <= {8{pti_cdato}};
7'b00001??:	br3_dati <= {2{uart_dato}};
7'b000001?:	br3_dati <= {2{via_dato}};
7'b0000001:	br3_dati <= {8{eeprom_cdato}};
default:	br3_dati <= br3_dati;
endcase

wire eeprom_clko, eeprom_datao;
wire eeprom_clk_en,eeprom_data_en;
wire eeprom_clki;
wire [7:0] eeprom_dati;
assign eeprom_clk = eeprom_clk_en ? 1'bz : eeprom_clko;
assign eeprom_data = eeprom_data_en ? 1'bz : eeprom_datao;
assign eeprom_clki = eeprom_clk_en ? eeprom_clk : 1'b1;
assign eeprom_dati = eeprom_data_en ? eeprom_data : 1'b1;

i2c_master_top ui2c1
(
	.wb_clk_i(cpu_clk),
	.wb_rst_i(rst),
	.cs_i(cs_eeprom),
	.wb_adr_i(br3_adr32[2:0]),
	.wb_dat_i(br3_dat8),
	.wb_dat_o(eeprom_cdato),
	.wb_we_i(br3_we),
	.wb_stb_i(br3_stb),
	.wb_cyc_i(br3_cyc),
	.wb_ack_o(eeprom_ack),
	.wb_inta_o(eeprom_irq),
	.scl_pad_i(eeprom_clki),
	.scl_pad_o(eeprom_clko),
	.scl_padoen_o(eeprom_clk_en),
	.sda_pad_i(eeprom_datai),
	.sda_pad_o(eeprom_datao),
	.sda_padoen_o(eeprom_data_en)
);
/*
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
*/
/*
  `ifdef SDC_CLK_SEP
   ,sd_clk_i_pad
  `endif
  `ifdef SDC_IRQ_ENABLE
   ,int_a, int_b, int_c  
  `endif
*/
/*
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
*/

Petajon_pti upti1(
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
	.sirq_o(pti_sirq),
	.dirq_o(pti_dirq),
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

// -----------------------------------------------------------------------------
// clock divider
// Used to pulse width modulate (PWM) the led signals to reduce the brightness.
// -----------------------------------------------------------------------------

reg [31:0] dvd;
always @(posedge clk100)
if (rst)
	dvd <= 32'd1;
else begin
	if (dvd==32'd50000000)
		dvd <= 32'd1;
	else
		dvd <= dvd + 32'd1;
end

// -----------------------------------------------------------------------------
// LED output
// -----------------------------------------------------------------------------

assign led[0] = pa_o[0] & ~dvd[26] & dvd[12];
assign led[1] = pa_o[1] & dvd[12];
assign led[7:2] = pa_o[7:2] & {6{dvd[12]}};


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

via6522 uvia1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.irq_o(via_irq),
	.cs_i(cs_via),
	.cyc_i(br3_cyc),
	.stb_i(br3_stb),
	.ack_o(via_ack),
	.we_i(br3_we),
	.sel_i(br3_sel32),
	.adr_i(br3_adr32[5:2]),
	.dat_i(br3_dat32),
	.dat_o(via_dato), 
	.pa(),
	.pa_i(pa_i),
	.pa_o(pa_o),
	.pb(),
	.ca1(),
	.ca2(),
	.cb1(),
	.cb2()
);

uart6551 uuart1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_uart),
	.irq_o(uart_irq),
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
	.xclk_i(clk14),
	.RxC_i(1'b0)
);

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

