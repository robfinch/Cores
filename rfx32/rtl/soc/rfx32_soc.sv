`timescale 1ns / 10ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2023  Robert Finch, Waterloo
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

import fta_bus_pkg::*;
import wishbone_pkg::*;
//import nic_pkg::*;

//`define USE_GATED_CLOCK	1'b1
//`define HAS_MMU 1'b1

module rfx32_soc(cpu_resetn, xclk, led, sw, btnl, btnr, btnc, btnd, btnu, 
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
wire clk20, clk33, clk40, clk50, clk100, clk200;
wire xclk_bufg;
wire node_clk = clk50;
wb_cmd_request128_t cpu_req;
wb_cmd_response128_t cpu_resp;
wb_cmd_request128_t ch7req;
wb_cmd_request128_t ch7dreq;	// DRAM request
wb_cmd_response128_t ch7resp;
wb_cmd_request128_t fb_req;
wb_cmd_response128_t fb_resp;
reg [31:0] irq_bus;
wb_cycle_type_t cpu_cti;	// cycle type indicator
wire [3:0] cpu_cid;
wire [7:0] cpu_tid;
wb_burst_len_t cpu_blen;	// length of burst-1
wire cpu_cyc;
wire cpu_stb;
wire cpu_we;
wire [31:0] cpu_adr;
reg [31:0] cpu_adri;
wire [127:0] cpu_dato;
reg [3:0] cidi;
reg [7:0] tidi;
reg ack;
reg next;
wire vpa;
wire [15:0] sel;
reg [127:0] dati;
wire [127:0] dato;
wire mmus, ios, iops;
wire mmu_ack;
wire [31:0] mmu_dato;
wb_cmd_request128_t br1_req;
wb_cmd_response128_t br1_resp;
fta_cmd_request64_t br1_mreq;
wire br1_cyc;
wire br1_stb;
reg br1_ack;
wire br1_we;
wire [3:0] br1_sel;
wire [31:0] br1_adr;
wire [127:0] br1_cdato;
reg [31:0] br1_dati;
wire [31:0] br1_dato;
wire br1_cack;
wire [3:0] br1_cido;
wire [7:0] br1_tido;
wb_cmd_request128_t br3_req;
wb_cmd_response128_t br3_resp;
wire br3_cyc;
wire br3_stb;
reg br3_ack;
wire br3_we;
wire [3:0] br3_sel;
wire [31:0] br3_adr;
wire [127:0] br3_cdato;
reg [31:0] br3_dati;
wire [31:0] br3_dato;
wire [3:0] br3_cido;
wire [7:0] br3_tido;
wire br3_cack;
fta_cmd_response64_t fb_cresp;
fta_cmd_response64_t tc_cresp;
wire fb_ack;
wire [31:0] fb_irq;
wire [31:0] fb_dato;
wire tc_ack;
wire [31:0] tc_dato;
wire kclk_en;
wire kdat_en;
wire kbd_ack;
wire [31:0] kbd_irq;
wire [31:0] kbd_dato;
wire rand_ack;
wire [31:0] rand_dato;
wire sema_ack;
wire [31:0] sema_dato;
wire scr_ack;
wire scr_next;
wire [127:0] scr_dato;
wire [31:0] scr_adro;
wire [7:0] scr_tido;
wire [3:0] scr_cido;
wire acia_ack;
wire [31:0] acia_dato;
wire [31:0] acia_irq;
wire i2c2_ack;
wire [31:0] i2c2_dato;
wire [31:0] i2c2_irq;
wire pic_ack;
wire [3:0] pic_irq;
wire [31:0] pic_dato;
wire [7:0] pic_cause;
wire [5:0] pic_core;
wire mem_ui_clk;
wire [4:0] dram_state;
wire [7:0] asid;
wire io_ack;
wire [31:0] io_dato;
wire io_gate, io_gate_en;
wire config_to;
wire node_clk1, node_clk2, node_clk3;

wire leds_ack;
reg [7:0] rst_reg;
wire rst_ack;

wire hSync, vSync;
wire blank, border;
wire [7:0] red, blue, green;
wire [31:0] fb_rgb, tc_rgb;
assign red = tc_rgb[30:21];
assign green = tc_rgb[20:10];
assign blue = tc_rgb[9:0];

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

/*
IBUFG #(.IBUF_LOW_PWR("FALSE"),.IOSTANDARD("DEFAULT")) ubg1
(
  .I(xclk),
  .O(xclk_bufg)
);
*/

NexysVideoClkgen ucg1
(
  // Clock out ports
  .clk200(clk200),	// display / ddr3
  .clk100(clk100),
  .clk50(clk50),		// cpu 4x
  .clk40(clk40),		// cpu 4x
  .clk33(clk33),		// cpu 2x / display
  .clk20(clk20),		// cpu
//  .clk14(clk14),		// 16x baud clock
  // Status and control signals
  .reset(xrst), 
  .locked(locked),       // output locked
 // Clock in ports
  .clk_in1(xclk)
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

wire cs_io;
assign cs_io = ios;//ch7req.adr[31:20]==12'hFD0;
wire cs_io2 = ch7req.padr[31:20]==12'hFD0;
// These two decodes outside the IO area.
wire cs_iobitmap;
assign cs_iobitmap = iops;	//ch7req.adr[31:16]==16'hFC10;
wire cs_mmu;
assign cs_mmu = mmus;	//cpu_adr[31:16]==16'hFC00 || cpu_adr[31:16]==16'hFC01;

wire cs_config = ch7req.padr[31:28]==4'hD;

wire cs_leds = ch7req.padr[19:8]==12'hFFF && ch7req.stb && cs_io2;
wire cs_br3_leds = br3_adr[19:8]==12'hFFF && br3_stb && cs_io2;
wire cs_br3_rst  = br3_adr[19:8]==12'hFFC && br3_stb && cs_io2;
wire cs_sema = ch7req.padr[19:16]==4'h5 && ch7req.stb && cs_io2;
wire cs_scr = ch7req.padr[31:20]==12'h001;
wire cs_dram = ch7req.padr[31:29]==3'b001 && !cs_mmu && !cs_iobitmap && !cs_io;

assign io_gate_en = ch7req.padr[31:20]==12'hFD0 || ch7req.padr[31:20]==12'hFD1;

rfFrameBuffer_fta64 uframebuf1
(
	.rst_i(rst),
	.irq_o(fb_irq),
	.cs_config_i(cs_config),
	.cs_io_i(cs_io),
	.s_clk_i(node_clk),
	.s_req(br1_mreq),
	.s_resp(fb_cresp),
	.m_clk_i(clk40),
	.m_fst_o(), 
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

//assign fb_ack = 1'b0;

rfTextController_fta64 utc1
(
	.rst_i(rst),
	.clk_i(node_clk),
	.cs_config_i(cs_config),
	.cs_io_i(cs_io2),
	.req(br1_mreq),
	.resp(tc_cresp),
	.dot_clk_i(clk40),
	.hsync_i(hSync),
	.vsync_i(vSync),
	.blank_i(blank),
	.border_i(border),
	.zrgb_i(fb_rgb),
	.zrgb_o(tc_rgb),
	.xonoff_i(sw[1])
);

always_comb
begin
	br1_req = ch7req;
	br1_req.cyc = ch7req.cyc & io_gate_en;
	br1_req.stb = ch7req.stb & io_gate_en;
	br1_req.we = ch7req.we & io_gate_en;
end

IOBridge128to64fta ubridge1
(
	.rst_i(rst),
	.clk_i(node_clk),
	.s1_req(br1_req),
	.s1_resp(br1_resp),
	.m_req(br1_mreq),
	.ch0resp(tc_cresp),
	.ch1resp(fb_cresp)
);

PS2kbd #(.pClkFreq(40000000)) ukbd1
(
	// WISHBONE/SoC bus interface 
	.rst_i(rst),
	.clk_i(node_clk),	// system clock
	.cs_config_i(cs_config),
	.cs_io_i(cs_io),
	.cyc_i(br3_cyc),
	.stb_i(br3_stb),	// core select (active high)
	.ack_o(kbd_ack),	// bus transfer acknowledged
	.we_i(br3_we),	// I/O write taking place (active high)
	.sel_i(br3_sel),
	.adr_i(br3_adr),	// address
	.dat_i(br3_dato),	// data in
	.dat_o(kbd_dato),	// data out
	//-------------
	.irq_o(kbd_irq),	// interrupt request (active high)
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
	.cs_config_i(cs_config),
	.cs_io_i(cs_io),
	.cyc_i(br3_cyc),
	.stb_i(br3_stb),
	.ack_o(rand_ack),
	.we_i(br3_we),
	.adr_i(br3_adr[31:0]),
	.dat_i(br3_dato),
	.dat_o(rand_dato)
);

uart6551pci #(.pClkFreq(100), .pClkDiv(24'd130)) uuart
(
	.rst_i(rst),
	.clk_i(clk100),
	.cs_config_i(cs_config),
	.cs_io_i(cs_io),
	.irq_o(acia_irq),
	.cyc_i(br3_cyc),
	.stb_i(br3_stb),
	.ack_o(acia_ack),
	.we_i(br3_we),
	.sel_i(br3_sel),
	.adr_i(br3_adr[31:0]),
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
	.RxC_i(clk20)
);

wire rtc_clko, rtc_clkoen;
wire rtc_datao, rtc_dataoen;

i2c_master_top_pci32 ui2cm1
(
	.wb_clk_i(node_clk),
	.wb_rst_i(rst),
	.arst_i(~rst),
	.cs_config_i(cs_config),
	.cs_io_i(cs_io),
	.wb_sel_i(br3_sel),
	.wb_adr_i(br3_adr[31:0]),
	.wb_dat_i(br3_dato),
	.wb_dat_o(i2c2_dato),
	.wb_we_i(br3_we),
	.wb_stb_i(br3_stb),
	.wb_cyc_i(br3_cyc),
	.wb_ack_o(i2c2_ack),
	.wb_inta_o(i2c2_irq),
	.scl_pad_i(rtc_clk),
	.scl_pad_o(rtc_clko),
	.scl_padoen_o(rtc_clkoen),
	.sda_pad_i(rtc_data),
	.sda_pad_o(rtc_datao), 
	.sda_padoen_o(rtc_dataoen)
);
assign rtc_clk = rtc_clkoen ? 'bz : rtc_clko;
assign rtc_data = rtc_dataoen ? 'bz : rtc_datao;


always_comb
begin
	br3_req = ch7req;
	br3_req.cyc = ch7req.cyc & io_gate_en;
	br3_req.stb = ch7req.stb & io_gate_en;
	br3_req.we = ch7req.we & io_gate_en;
end

IOBridge128wb ubridge3
(
	.rst_i(rst),
	.clk_i(node_clk),
	.s1_req(br3_req),
	.s1_resp(br3_resp),
	.s2_req('d0),
	.s2_resp(),
	.m_cyc_o(br3_cyc),
	.m_stb_o(br3_stb),
	.m_we_o(br3_we),
	.m_adr_o(br3_adr),
	.m64_ack_i(1'b0),
	.m64_sel_o(),
	.m64_dat_i('d0),
	.m64_dat_o(),
	.m32_ack_i(br3_ack),
	.m32_sel_o(br3_sel),
	.m32_dat_i(br3_dati),
	.m32_dat_o(br3_dato)
);

always_ff @(posedge node_clk)
	casez(cs_br3_leds)
	1'b1:	br3_dati <= led;
	1'b0:	br3_dati <= kbd_dato|rand_dato|acia_dato|i2c2_dato;
	default:	br3_dati <= 'd0;
	endcase

always_ff @(posedge node_clk, posedge rst)
if (rst)
	br3_ack <= 'd0;
else
	br3_ack <= leds_ack|kbd_ack|rand_ack|acia_ack|i2c2_ack;

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

always_comb
begin
	ch7dreq <= ch7req;
//	ch7dreq.cid <= 4'd7;
	ch7dreq.cyc <= ch7req.cyc & cs_dram;
	ch7dreq.stb <= ch7req.stb & cs_dram;
end

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
	.ch0clk(clk40),
	.ch1clk(1'b0),
	.ch2clk(1'b0),
	.ch3clk(1'b0),
	.ch4clk(1'b0),
	.ch5clk(1'b0),
	.ch6clk(1'b0),
	.ch7clk(node_clk),
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
	.ch7i(ch7dreq),
	.ch7o(ch7resp),
	.state(dram_state)
);

binary_semamem_pci32 usema1
(
	.rst_i(rst),
	.clk_i(node_clk),
	.cs_config_i(cs_config),
	.cs_io_i(cs_io),
	.cyc_i(ch7req.cyc),
	.stb_i(ch7req.stb),
	.ack_o(sema_ack),
	.sel_i(ch7req.sel[15:12]|ch7req.sel[11:8]|ch7req.sel[7:4]|ch7req.sel[3:0]),
	.we_i(ch7req.we),
	.adr_i(ch7req.padr[31:0]),
	.dat_i(dato[31:0]),
	.dat_o(sema_dato)
);

scratchmem128pci uscr1
(
	.rst_i(rst),
	.cs_config_i(cs_config),
	.cs_ram_i(ch7req.padr[31:24]==8'hFF),
	.clk_i(node_clk),
	.blen_i(ch7req.blen),
	.cid_i(ch7req.cid),
	.tid_i(ch7req.tid),
	.cti_i(ch7req.cti),
	.cyc_i(ch7req.cyc),
	.stb_i(ch7req.stb),
	.ack_o(scr_ack),
	.next_o(scr_next),
	.we_i(ch7req.we),
	.sel_i(sel),
	.adr_i(ch7req.padr[31:0]),
	.adr_o(scr_adro),
	.dat_i(dato),
	.dat_o(scr_dato),
	.cid_o(scr_cido),
	.tid_o(scr_tido)
);

/*
io_bitmap uiob1
(
	.clk_i(node_clk),
	.cs_i(cs_iobitmap),
	.cyc_i(ch7req.cyc),
	.stb_i(ch7req.stb),
	.ack_o(io_ack),
	.we_i(ch7req.we),
	.asid_i(asid),
	.adr_i(ch7req.adr[19:0]),
	.dat_i(dato),
	.dat_o(io_dato),
	.iocs_i(cs_io),
	.gate_o(cs_io2),
	.gate_en(io_gate_en)
);
*/
//assign io_irq = cs_io & ~cs_io2 & io_gate_en;

//packet_t [5:0] packet;
//packet_t [5:0] rpacket;
//ipacket_t [5:0] ipacket;

// Generate 100Hz interrupt
reg [23:0] icnt;
reg tmr_irq;

always @(posedge clk100)
if (rst) begin
	icnt <= 24'd1;
	tmr_irq <= 1'b0;
end
else begin
	icnt <= icnt + 2'd1;
	if (icnt==24'd150)
		tmr_irq <= 1'b1;
	else if (icnt==24'd200)
		tmr_irq <= 1'b0;
	else if (icnt==24'd1000000)
		icnt <= 24'd1;
end

always_comb
	irq_bus = fb_irq|acia_irq|kbd_irq|i2c2_irq;

wire bus_err;
BusError ube1
(
	.rst_i(rst),
	.clk_i(node_clk),
	.cyc_i(ch7req.cyc),
	.ack_i(ack),
	.stb_i(ch7req.stb),
	.adr_i(ch7req.padr),
	.err_o(bus_err)
);

reg [6:0] rst_cnt;
reg [15:0] rsts;
reg [15:0] clken_reg;

`ifdef HAS_MMU
mmu ummu1
(
	.rst_i(rst),
	.clk_i(node_clk),
	.cs_config_i(cs_config),
	.cs_io_i(cs_io),
	.s_seg_i(ch7req.seg),
	.s_cyc_i(cpu_cyc),
	.s_stb_i(cpu_stb),
	.s_ack_o(mmu_ack),
	.s_we_i(cpu_we),
	.s_asid_i(asid),
	.s_adr_i(cpu_adr),
	.s_dat_i(cpu_dato),
	.s_dat_o(mmu_dato),
  .pea_o(ch7req.padr),
  .pdat_o(dato),
  .cyc_o(ch7req.cyc),
  .stb_o(ch7req.stb),
  .we_o(ch7req.we),
  .exv_o(),
  .rdv_o(),
  .wrv_o()
);
`else
assign dato = cpu_dato;
assign ch7req = cpu_req;
/*
assign ch7req.blen = cpu_blen;
assign ch7req.cti = cpu_cti;
assign ch7req.cid = cpu_cid;
assign ch7req.tid = cpu_tid;
assign ch7req.cyc = cpu_cyc;
assign ch7req.stb = cpu_stb;
assign ch7req.we = cpu_we;
assign ch7req.padr = cpu_adr;
*/
assign mmu_ack = 1'b0;
assign mmu_dato = 'd0;
`endif

/*
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
	.s_err_o(),
	.s_vpa_o(),
	.s_we_i(1'b0),
	.s_sel_i(4'h0),
	.s_adr_i(32'h0),
	.s_dat_i(32'h0),
	.s_dat_o(),
	.s_asid_i('d0),
	.s_mmus_i(1'b0),
	.s_ios_i(1'b0),
	.s_iops_i(1'b0),

	.m_cyc_o(cpu_cyc),
	.m_stb_o(cpu_stb),
	.m_ack_i(ack),
	.m_err_i(bus_err),
	.m_vpa_i(vpa),
	.m_we_o(cpu_we),
	.m_sel_o(sel),
	.m_asid_o(asid),
	.m_mmus_o(mmus),
	.m_ios_o(ios),
	.m_iops_o(iops),
	.m_adr_o(cpu_adr),
	.m_dat_o(cpu_dato),
	.m_dat_i(dati),

	.packet_i(packet[0]),//clken_reg[3] ? packet[2] : clken_reg[2] ? packet[1] : packet[0]),
	.packet_o(packet[3]),
	.ipacket_i(ipacket[0]),//clken_reg[3] ? ipacket[2] : clken_reg[2] ? ipacket[1] : ipacket[0]),
	.ipacket_o(ipacket[3]),
	.rpacket_i(rpacket[0]),//clken_reg[3] ? rpacket[2] : clken_reg[2] ? rpacket[1] : rpacket[0]),
	.rpacket_o(rpacket[3]),

	.irq_i(pic_irq[2:0]),
	.firq_i(1'b0),
	.cause_i(pic_cause),
	.iserver_i(pic_core),
	.irq_o(),
	.firq_o(),
	.cause_o()
);

nic_ager uager1
(
	.clk_i(node_clk),
	.packet_i(packet[3]),
	.packet_o(packet[4]),
	.ipacket_i(ipacket[3]),
	.ipacket_o(ipacket[4]), 
	.rpacket_i(rpacket[3]),
	.rpacket_o(rpacket[4])
);
*/
/*
ila_0 your_instance_name (
	.clk(clk100), // input wire clk

	.probe0(unode1.ucpu1.ir), // input wire [15:0]  probe0  
	.probe1(cpu_adr), // input wire [31:0]  probe1 
	.probe2(dato), // input wire [31:0]  probe2 
	.probe3({cpu_cyc,cpu_stb,ack,cs_io2,cs_io,ch7req.stb,cpu_we}), // input wire [7:0]  probe3
	.probe4(unode1.ucpu1.pc),
	.probe5({dram_state,unode1.ucpu1.ios_o,ios}),
	.probe6(unode1.ucpu1.state),
	.probe7(mem_wdf_mask),
	.probe8({umpmc1.req_fifoo.stb,umpmc1.req_fifoo.we}),
	.probe9(umpmc1.req_fifoo.sel),
	.probe10(unode1.ucpu1.dfdivo[95:64])
);
*/
config_timout_ctr ucfgtoctr1
(
	.rst(rst),
	.clk(node_clk),
	.cs(cs_config),
	.o(config_to)
);

fta_cmd_response128_t [4:0] resps;

fta_respbuf #(5) urspbuf1
(
	.rst(rst),
	.clk(node_clk),
	.resp(resps),
	.resp_o(cpu_resp)
);

assign resps[0] = fta_cmd_response128_t'(ch7resp);
assign resps[1] = fta_cmd_response128_t'(br1_resp);
assign resps[2] = fta_cmd_response128_t'(br3_resp);
assign resps[3].cid = cpu_cid;
assign resps[3].tid = cpu_tid;
assign resps[3].ack = sema_ack;
assign resps[3].dat = {4{sema_dato}};
assign resps[3].adr = cpu_adr;
assign resps[4].cid = scr_cido;
assign resps[4].tid = scr_tido;
assign resps[4].ack = scr_ack;
assign resps[4].dat = scr_dato;
assign resps[4].adr = scr_adro;

//assign ch7req.sel = ch7req.we ? sel << {ch7req.padr[3:2],2'b0} : 16'hFFFF;
//assign ch7req.data1 = {4{dato}};
/*
always_ff @(posedge node_clk)
if (config_to)
	dati <= {128{1'b1}};
else if (cs_dram)
	dati <= ch7resp.dat;
else
	dati <= br1_cdato|br3_cdato|{4{sema_dato}}|scr_dato|mmu_dato;
*/
//always_ff @(posedge node_clk)
//	cpu_adri <= scr_adro;
/*
always_ff @(posedge node_clk)
	ack <= ch7resp.ack|br1_cack|br3_cack|sema_ack|scr_ack|mmu_ack|config_to;
*/
always_ff @(posedge node_clk)
	next <= scr_next;
//always_ff @(posedge node_clk)
//	tidi <= scr_tido|br1_tido|br3_tido;
always_ff @(posedge node_clk)
if (rst) begin
	rst_cnt <= 'd0;
	rst_reg <= 16'h0000;
	clken_reg <= 16'h00000006;
end
else begin
	if (cs_br3_rst) begin
		if (|sel[1:0]) begin
			rst_reg <= br3_dato[15:0];
			rst_cnt <= 'd0;
			clken_reg[2] <= clken_reg[2] | |br3_dato[5:4];
			//clken_reg[3] <= clken_reg[3] | |br3_dato[7:6];
		end
		if (|sel[3:2])
			clken_reg[2:0] <= br3_dato[18:16];
	end
	if (~rst_cnt[6])
		rst_cnt <= rst_cnt + 2'd1;
	else
		rst_reg <= 'd0;
end
assign rst_ack = cs_br3_rst;
always_comb
	rsts <= {16{~rst_cnt[6]}} & rst_reg;

assign node_clk1 = node_clk;
`ifdef USE_GATED_CLOCK
BUFGCE uce2 (.CE(clken_reg[2]), .I(node_clk), .O(node_clk2));
BUFGCE uce3 (.CE(clken_reg[3]), .I(node_clk), .O(node_clk3));
`else
assign node_clk2 = node_clk;
assign node_clk3 = node_clk;
`endif

rfx32_mpu umpu1
(
	.rst_i(rst),
	.clk_i(node_clk),
	.ftam_req(cpu_req),
	.ftam_resp(cpu_resp),
	.irq_bus(irq_bus),
	.clk0(1'b0),
	.gate0(1'b0),
	.out0(),
	.clk1(1'b0),
	.gate1(1'b0),
	.out1(),
	.clk2(1'b0),
	.gate2(1'b0),
	.out2(),
	.clk3(1'b0),
	.gate3(1'b0),
	.out3()
);

assign cpu_blen = cpu_req.blen;
assign cpu_cti = cpu_req.cti;
assign cpu_cid = cpu_req.cid;
assign cpu_tid = cpu_req.tid;
assign cpu_cyc = cpu_req.cyc;
assign cpu_stb = cpu_req.stb;
assign cpu_we = cpu_req.we;
assign sel = cpu_req.sel;
assign asid = cpu_req.asid;
assign cpu_adr = cpu_req.padr;
assign cpu_dato = cpu_req.data1;

/*
assign cpu_resp.tid = tidi;
assign cpu_resp.cid = cidi;
assign cpu_resp.err = bus_err;
assign cpu_resp.ack = ack;
assign cpu_resp.next = next;
assign cpu_resp.rty = 1'b0;
assign cpu_resp.stall = 1'b0;
assign cpu_resp.adr = cpu_adri;
assign cpu_resp.dat = dati;
*/
endmodule
