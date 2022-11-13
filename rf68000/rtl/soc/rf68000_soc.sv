`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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

import wishbone_pkg::*;
import nic_pkg::*;

module rf68000_soc(cpu_resetn, xclk, led, sw, btnl, btnr, btnc, btnd, btnu, 
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

wire rst, rstn;
wire xrst = ~cpu_resetn;
wire locked;
wire clk20, clk40, clk50, clk100, clk200;
wire xclk_bufg;
wire node_clk = clk50;
wb_write_request128_t ch7req;
wb_read_response128_t ch7resp;
wb_write_request128_t fb_req;
wb_read_response128_t fb_resp;
reg ack;
wire [3:0] sel;
reg [31:0] dati;
wire [31:0] dato;
wire br1_cyc;
wire br1_stb;
reg br1_ack;
wire [3:0] br1_sel;
wire [31:0] br1_adr;
wire [31:0] br1_cdato;
reg [31:0] br1_dati;
wire [31:0] br1_dato;
wire br1_cack;
wire br3_cyc;
wire br3_stb;
reg br3_ack;
wire [3:0] br3_sel;
wire [31:0] br3_adr;
wire [31:0] br3_cdato;
reg [31:0] br3_dati;
wire [31:0] br3_dato;
wire br3_cack;
wire fb_ack;
wire [31:0] fb_dato;
wire tc_ack;
wire [31:0] tc_dato;
wire kbd_ack;
wire [7:0] kbd_dato;
wire rand_ack;
wire [31:0] rand_dato;
wire sema_ack;
wire [7:0] sema_dato;
wire scr_ack;
wire [31:0] scr_dato;
wire acia_ack;
wire [31:0] acia_dato;

wire leds_ack;

wire hSync, vSync;
wire blank, border;
wire [7:0] red, blue, green;
wire [39:0] fb_rgb, tc_rgb;
assign red = tc_rgb[35:28];
assign green = tc_rgb[23:16];
assign blue = tc_rgb[11:4];

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

IBUFG #(.IBUF_LOW_PWR("FALSE"),.IOSTANDARD("DEFAULT")) ubg1
(
  .I(xclk),
  .O(xclk_bufg)
);

NexysVideoClkgen ucg1
(
  // Clock out ports
  .clk200(clk200),	// display / ddr3
  .clk100(clk100),
  .clk50(clk50),		// cpu 4x
  .clk40(clk40),		// cpu 2x / display
  .clk20(clk20),		// cpu
//  .clk14(clk14),		// 16x baud clock
  // Status and control signals
  .reset(xrst), 
  .locked(locked),       // output locked
 // Clock in ports
  .clk_in1(xclk_bufg)
);

assign rst = !locked;

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

wire cs_tc = (ch7req.adr[31:16]==16'hFD00 || ch7req.adr[31:16]==16'hFD01 ||
							ch7req.adr[31:16]==16'hFD02 || ch7req.adr[31:16]==16'hFD03) && ch7req.stb;
wire cs_br1_tc = (br1_adr[31:16]==16'hFD00 || br1_adr[31:16]==16'hFD01 ||
									br1_adr[31:16]==16'hFD02 || br1_adr[31:16]==16'hFD03) && br1_stb;
wire cs_fb = ch7req.adr[31:16]==16'hFD04 && ch7req.stb;
wire cs_br1_fb = br1_adr[31:16]==16'hFD04 && br1_stb;
wire cs_leds = ch7req.adr[31:8]==24'hFD0FFF && ch7req.stb;
wire cs_br3_leds = br3_adr[31:8]==24'hFD0FFF && br3_stb;
wire cs_kbd  = ch7req.adr[31:8]==24'hFD0FFE && ch7req.stb;
wire cs_br3_kbd  = br3_adr[31:8]==24'hFD0FFE && br3_stb;
wire cs_rand  = ch7req.adr[31:8]==24'hFD0FFD && ch7req.stb;
wire cs_br3_rand  = br3_adr[31:8]==24'hFD0FFD && br3_stb;
wire cs_sema = ch7req.adr[31:16]==16'hFD05 && ch7req.stb;
wire cs_acia = ch7req.adr[31:12]==20'hFD060 && ch7req.stb;
wire cs_br3_acia = br3_adr[31:12]==20'hFD060 && br3_stb;
wire cs_scr = ch7req.adr[31:20]==12'h001 && ch7req.stb;

rfFrameBuffer uframebuf1
(
	.rst_i(rst),
	.irq_o(),
	.s_clk_i(node_clk),
	.s_cs_i(cs_br1_fb),
	.s_cyc_i(br1_cyc),
	.s_stb_i(br1_stb),
	.s_ack_o(fb_ack),
	.s_we_i(br1_we),
	.s_sel_i(br1_sel),
	.s_adr_i(br1_adr),
	.s_dat_i(br1_dato),
	.s_dat_o(fb_dato),
	.m_clk_i(clk50),
	.m_fst_o(), 
//	m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o,
	.wbm_req(fb_req),
	.wbm_resp(fb_resp),
	.dot_clk_i(clk40),
	.zrgb_o(fb_rgb),
	.xonoff_i(sw[0]),
	.xal_o(),
	.hsync_o(hSync),
	.vsync_o(vSync),
	.blank_o(blank),
	.border_o(border),
	.hctr_o(),
	.vctr_o(),
	.fctr_o(),
	.vblank_o()
);

rfTextController utc1
(
	.rst_i(rst),
	.clk_i(node_clk),
	.cs_i(cs_br1_tc),
	.cti_i(3'd0),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(tc_ack),
	.wr_i(br1_we),
	.sel_i(br1_sel),
	.adr_i(br1_adr[17:0]),
	.dat_i(br1_dato),
	.dat_o(tc_dato),
	.dot_clk_i(clk40),
	.hsync_i(hSync),
	.vsync_i(vSync),
	.blank_i(blank),
	.border_i(border),
	.zrgb_i(fb_rgb),
	.zrgb_o(tc_rgb),
	.xonoff_i(sw[1])
);

IOBridge ubridge1
(
	.rst_i(rst),
	.clk_i(node_clk),
	.s1_cyc_i(ch7req.cyc),
	.s1_stb_i(ch7req.stb),
	.s1_ack_o(br1_cack),
	.s1_we_i(ch7req.we),
	.s1_sel_i(sel),
	.s1_adr_i(ch7req.adr),
	.s1_dat_i(dato),
	.s1_dat_o(br1_cdato),
	.s2_cyc_i(1'b0),
	.s2_stb_i(1'b0),
	.s2_ack_o(),
	.s2_we_i(1'b0),
	.s2_sel_i(4'h0),
	.s2_adr_i(32'h0),
	.s2_dat_i(32'h0),
	.s2_dat_o(),
	.m_cyc_o(br1_cyc),
	.m_stb_o(br1_stb),
	.m_ack_i(br1_ack),
	.m_we_o(br1_we),
	.m_sel_o(br1_sel),
	.m_adr_o(br1_adr),
	.m_dat_i(br1_dati),
	.m_dat_o(br1_dato)
);

always_ff @(posedge node_clk)
	br1_dati <= fb_dato|tc_dato;

always_ff @(posedge node_clk)
	br1_ack <= fb_ack|tc_ack;

PS2kbd ukbd1
(
	// WISHBONE/SoC bus interface 
	.rst_i(rst),
	.clk_i(clk40),	// system clock
	.cs_i(cs_br3_kbd),
	.cyc_i(br3_cyc),
	.stb_i(br3_stb),	// core select (active high)
	.ack_o(kbd_ack),	// bus transfer acknowledged
	.we_i(br3_we),	// I/O write taking place (active high)
	.adr_i(br3_adr[3:0]),	// address
	.dat_i(br3_dato[7:0]),	// data in
	.dat_o(kbd_dato),	// data out
	.db(),
	//-------------
	.irq(),	// interrupt request (active high)
	.kclk_i(kclk),	// keyboard clock from keyboard
	.kclk_en(kclk_en),	// 1 = drive clock low
	.kdat_i(kd),	// keyboard data
	.kdat_en(kdat_en)	// 1 = drive data low
);

assign kclk = kclk_en ? 1'b0 : 'bz;
assign kd = kdat_en ? 1'b0 : 'bz;

random urnd1
(
	.rst_i(rst),
	.clk_i(node_clk),
	.cs_i(cs_br3_rand),
	.cyc_i(br3_cyc),
	.stb_i(br3_stb),
	.ack_o(rand_ack),
	.we_i(br3_we),
	.adr_i(br3_adr[3:0]),
	.dat_i(br3_dato),
	.dat_o(rand_dato)
);

uart6551 uuart
(
	.rst_i(rst),
	.clk_i(clk40),
	.cs_i(cs_br3_acia),
	.irq_o(),
	.cyc_i(br3_cyc),
	.stb_i(br3_stb),
	.ack_o(acia_ack),
	.we_i(br3_we),
	.sel_i(br3_sel),
	.adr_i(br3_adr[3:2]),
	.dat_i(br3_dato),
	.dat_o(acia_dato),
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
	.xclk_i(clk20),
	.RxC_i(1'b0)
);


IOBridge ubridge3
(
	.rst_i(rst),
	.clk_i(node_clk),
	.s1_cyc_i(ch7req.cyc),
	.s1_stb_i(ch7req.stb),
	.s1_ack_o(br3_cack),
	.s1_we_i(ch7req.we),
	.s1_sel_i(sel),
	.s1_adr_i(ch7req.adr),
	.s1_dat_i(dato),
	.s1_dat_o(br3_cdato),
	.s2_cyc_i(1'b0),
	.s2_stb_i(1'b0),
	.s2_ack_o(),
	.s2_we_i(1'b0),
	.s2_sel_i(4'h0),
	.s2_adr_i(32'h0),
	.s2_dat_i(32'h0),
	.s2_dat_o(),
	.m_cyc_o(br3_cyc),
	.m_stb_o(br3_stb),
	.m_ack_i(br3_ack),
	.m_we_o(br3_we),
	.m_sel_o(br3_sel),
	.m_adr_o(br3_adr),
	.m_dat_i(br3_dati),
	.m_dat_o(br3_dato)
);

always_ff @(posedge node_clk)
	casez({cs_br3_rand,cs_br3_kbd,cs_br3_leds})
	3'b??1:	br3_dati <= led;
	3'b??0:	br3_dati <= {4{kbd_dato}}|rand_dato|acia_dato;
	default:	br3_dati <= 'd0;
	endcase

always_ff @(posedge node_clk)
	br3_ack <= leds_ack|kbd_ack|rand_ack|acia_ack;

assign leds_ack = cs_br3_leds;
always_ff @(posedge node_clk)
	if (cs_br3_leds & br3_we)
		led <= br3_dato[7:0];

wire mem_ui_rst;
wire calib_complete;
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

mig_7series_0 uddr3
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

mpmc10_wb umpmc1
(
	.rst(rst),
	.clk100MHz(clk100),
	.mem_ui_rst(mem_ui_rst),
	.mem_ui_clk(mem_ui_clk),
	.calib_complete(calib_complete),
	.rstn(rstn),
	.app_waddr(),
	.app_rdy(mem_rdy),
	.app_en(mem_en),
	.app_cmd(mem_cmd),
	.app_addr(mem_addr),
	.app_rd_data_valid(mem_rd_data_valid),
	.app_wdf_mask(mem_wdf_mask),
	.app_wdf_data(mem_wdf_data),
	.app_wdf_rdy(mem_wdf_rdy),
	.app_wdf_wren(mem_wdf_wren),
	.app_wdf_end(mem_wdf_end),
	.app_rd_data(mem_rd_data),
	.app_rd_data_end(mem_rd_data_end),
	.ch0clk(),
	.ch1clk(),
	.ch2clk(),
	.ch3clk(),
	.ch4clk(),
	.ch5clk(),
	.ch6clk(),
	.ch7clk(clk100),
	.ch0i(fb_req),
	.ch0o(fb_resp),
	.ch1i('d0),
	.ch1o(),
	.ch2i('d0),
	.ch2o(),
	.ch3i('d0),
	.ch3o(),
	.ch4i('d0),
	.ch4o(),
	.ch5i('d0),
	.ch5o(),
	.ch6i('d0),
	.ch6o(),
	.ch7i(ch7req),
	.ch7o(ch7resp),
	.state()
);

semamem usema1
(
	.rst_i(rst),
	.clk_i(node_clk),
	.cs_i(cs_sema),
	.cyc_i(ch7req.cyc),
	.stb_i(ch7req.stb),
	.ack_o(sema_ack),
	.we_i(ch7req.we),
	.adr_i(ch7req.adr[14:2]),
	.dat_i(dato[7:0]),
	.dat_o(sema_dato)
);

scratchmem uscr1
(
	.rst_i(rst),
	.cs_i(cs_scr),
	.clk_i(node_clk),
	.cyc_i(ch7req.cyc),
	.stb_i(ch7req.stb),
	.ack_o(scr_ack),
	.we_i(ch7req.we),
	.sel_i(sel),
	.adr_i(ch7req.adr[13:0]),
	.dat_i(dato),
	.dat_o(scr_dato)
);

packet_t [5:0] packet;
packet_t [5:0] rpacket;
ipacket_t [5:0] ipacket;

reg [23:0] icnt;
reg irq;

always @(posedge clk100)
if (rst) begin
	icnt <= 24'd1;
	irq <= 1'b0;
end
else begin
	icnt <= icnt + 2'd1;
	if (icnt==24'd150)
		irq <= 1'b1;
	else if (icnt==24'd200)
		irq <= 1'b0;
	else if (icnt==24'd8192)
		icnt <= 24'd1;
end

rf68000_nic unic1
(
	.id(6'd62),			// system node id
	.rst_i(rst),
	.clk_i(node_clk),
	.s_cti_i(3'd0),
	.s_atag_o(),
	.s_cyc_i(1'b0),
	.s_stb_i(1'b0),
	.s_ack_o(),
	.s_aack_o(),
	.s_rty_o(),
	.s_we_i(1'b0),
	.s_sel_i(4'h0),
	.s_adr_i(32'h0),
	.s_dat_i(32'h0),
	.s_dat_o(),
	.m_cyc_o(ch7req.cyc),
	.m_stb_o(ch7req.stb),
	.m_ack_i(ack),
	.m_we_o(ch7req.we),
	.m_sel_o(sel),
	.m_adr_o(ch7req.adr),
	.m_dat_o(dato),
	.m_dat_i(dati),
	.packet_i(packet[3]),
	.packet_o(packet[4]),
	.ipacket_i(ipacket[3]),
	.ipacket_o(ipacket[4]),
	.rpacket_i(rpacket[3]),
	.rpacket_o(rpacket[4]),
	.irq_i(/*irq ? 3'd6 :*/ 3'd0),
	.firq_i(1'b0),
	.cause_i(8'h00),
	.iserver_i(6'd2),
	.irq_o(),
	.firq_o(),
	.cause_o()
);

nic_ager uager1
(
	.clk_i(node_clk),
	.packet_i(packet[4]),
	.packet_o(packet[5]),
	.ipacket_i(ipacket[4]),
	.ipacket_o(ipacket[5]), 
	.rpacket_i(rpacket[4]),
	.rpacket_o(rpacket[5])
);

ila_0 your_instance_name (
	.clk(node_clk), // input wire clk

	.probe0(unode1.ucpu1.ir), // input wire [15:0]  probe0  
	.probe1(br1_adr), // input wire [31:0]  probe1 
	.probe2(br1_dato), // input wire [31:0]  probe2 
	.probe3({ch7req.cyc,ch7req.we,irq,ack}), // input wire [7:0]  probe3
	.probe4(unode1.ucpu1.pc),
	.probe5(unode1.ucpu1.state),
	.probe6(ipacket[4])
);

assign ch7req.sel = sel << {ch7req.adr[3:2],2'b0};
assign ch7req.dat = {4{dato}};
always_ff @(posedge node_clk)
if (ch7req.adr[31:29]==3'd1)
	dati <= ch7resp.dat >> {ch7req.adr[3:2],5'b0};
else
	dati <= br1_cdato|br3_cdato|{4{sema_dato}}|scr_dato;
always_ff @(posedge node_clk)
	ack <= ch7resp.ack|br1_cack|br3_cack|sema_ack|scr_ack;

rf68000_node unode1
(
	.id(5'd1),
	.rst(rst),
	.clk(node_clk),
	.packet_i(packet[5]),
	.packet_o(packet[0]),
	.rpacket_i(rpacket[5]),
	.rpacket_o(rpacket[0]),
	.ipacket_i(ipacket[5]),
	.ipacket_o(ipacket[0])
);

rf68000_node unode2
(
	.id(5'd2),
	.rst(rst),
	.clk(node_clk),
	.packet_i(packet[0]),
	.packet_o(packet[1]),
	.rpacket_i(rpacket[0]),
	.rpacket_o(rpacket[1]),
	.ipacket_i(ipacket[0]),
	.ipacket_o(ipacket[1])
);

rf68000_node unode3
(
	.id(5'd3),
	.rst(rst),
	.clk(node_clk),
	.packet_i(packet[1]),
	.packet_o(packet[2]),
	.rpacket_i(rpacket[1]),
	.rpacket_o(rpacket[2]),
	.ipacket_i(ipacket[1]),
	.ipacket_o(ipacket[2])
);

rf68000_node unode4
(
	.id(5'd4),
	.rst(rst),
	.clk(node_clk),
	.packet_i(packet[2]),
	.packet_o(packet[3]),
	.rpacket_i(rpacket[2]),
	.rpacket_o(rpacket[3]),
	.ipacket_i(ipacket[2]),
	.ipacket_o(ipacket[3])
);

endmodule
