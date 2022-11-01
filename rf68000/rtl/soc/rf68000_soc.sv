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
wire clk20, clk40, clk80, clk100, clk200;
wire xclk_bufg;
wb_write_request128_t ch7req;
wb_read_response128_t ch7resp;
reg ack;
wire [3:0] sel;
reg [31:0] dati;
wire [31:0] dato;
reg br1_ack;
wire [31:0] br1_adr;
wire [31:0] br1_cdato;
reg [31:0] br1_dati;
wire br1_cack;

wire hSync, vSync;
wire blank;
wire [7:0] red, blue, green;
wire [39:0] fb_rgb;

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
  .clk80(clk80),		// cpu 4x
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

wire cs_fb = ch7req.adr[31:16]==16'hFD04;
wire cs_br1_fb = br1_adr[31:16]==16'hFD04;

rfFrameBuffer uframebuf1
(
	.rst_i(rst),
	.irq_o(),
	.s_clk_i(clk80),
	.s_cs_i(cs_br1_fb),
	.s_cyc_i(br1_cyc),
	.s_stb_i(br1_stb),
	.s_ack_o(fb_ack),
	.s_we_i(br1_we),
	.s_sel_i(br1_sel),
	.s_adr_i(br1_adr),
	.s_dat_i(br1_dat),
	.s_dat_o(fb_dato),
	.m_clk_i(clk80),
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
	.border_o(),
	.hctr_o(),
	.vctr_o(),
	.fctr_o(),
	.vblank_o()
);

IOBridge ubridge1
(
	.rst_i(rst),
	.clk_i(clk80),
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

always_ff @(posedge clk80)
	if (cs_br1_fb)
		br1_dati <= fb_dato;
	else
		br1_dati <= 'd0;

always_ff @(posedge clk80)
	if (cs_br1_fb)
		br1_ack <= fb_ack;
	else
		br1_ack <= 'd0;

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
	.ch7clk(clk80),
	.ch0i('d0),
	.ch0o(),
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

packet_t [4:0] packet;
ipacket_t [4:0] ipacket;

rf68000_nic unic1
(
	.id({4'd15,1'b0}),
	.rst_i(rst),
	.clk_i(clk80),
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
	.rpacket_i(),
	.rpacket_o(),
	.irq_i(),
	.firq_i(),
	.cause_i(),
	.iserver_i(),
	.irq_o(),
	.firq_o(),
	.cause_o()
);

assign ch7req.sel = sel << {ch7req.adr[3:2],2'b0};
assign ch7req.dat = {4{dato}};
always_ff @(posedge clk80)
if (ch7req.adr[31:29]==3'd1)
	dati <= ch7resp.dat >> {ch7req.adr[3:2],5'b0};
else
	dati <= br1_cdato;
always_ff @(posedge clk80)
if (ch7req.adr[31:29]==3'd1)
	ack <= ch7resp.ack;
else
	ack <= br1_cack;

rf68000_node unode1
(
	.id(5'd1),
	.rst(rst),
	.clk(clk80),
	.packet_i(packet[4]),
	.packet_o(packet[0]),
	.ipacket_i(ipacket[4]),
	.ipacket_o(ipacket[0])
);

rf68000_node unode2
(
	.id(5'd2),
	.rst(rst),
	.clk(clk80),
	.packet_i(packet[0]),
	.packet_o(packet[1]),
	.ipacket_i(ipacket[0]),
	.ipacket_o(ipacket[1])
);

rf68000_node unode3
(
	.id(5'd3),
	.rst(rst),
	.clk(clk80),
	.packet_i(packet[1]),
	.packet_o(packet[2]),
	.ipacket_i(ipacket[1]),
	.ipacket_o(ipacket[2])
);

rf68000_node unode4
(
	.id(5'd4),
	.rst(rst),
	.clk(clk80),
	.packet_i(packet[2]),
	.packet_o(packet[3]),
	.ipacket_i(ipacket[2]),
	.ipacket_o(ipacket[3])
);

endmodule
