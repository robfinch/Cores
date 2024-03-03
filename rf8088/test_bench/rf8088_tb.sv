`timescale 1ns / 10ps

module rf8088_tb();

reg rst;
reg clk;
reg [7:0] rstcnt = 8'd0;
wire [6:0] state;
wire [7:0] led;

initial begin
	clk = 1'b0;
end
always
 #5 clk = ~clk;
 
always_ff @(posedge clk)
if (!rstcnt[6])
	rstcnt <= rstcnt + 2'd1;
always_comb
	rst = rstcnt < 8'd64;

rf8088_soc usoc1
(
	.cpu_resetn(~rst),
	.xclk(clk),
	.led(led),
	.sw(8'h00),
	.btnl(1'b0),
	.btnr(1'b0),
	.btnc(1'b0),
	.btnd(1'b0),
	.btnu(1'b0), 
  .kclk(),
  .kd(),
  .uart_txd(),
  .uart_rxd(1'b0),
  .TMDS_OUT_clk_p(),
  .TMDS_OUT_clk_n(),
  .TMDS_OUT_data_p(),
  .TMDS_OUT_data_n(),
  .ac_mclk(),
	.ac_adc_sdata(),
	.ac_dac_sdata(),
	.ac_bclk(),
	.ac_lrclk(),
  .rtc_clk(),
  .rtc_data(),
  .spiClkOut(),
  .spiDataIn(1'b0),
  .spiDataOut(),
  .spiCS_n(),
  .sd_cmd(),
  .sd_dat(),
  .sd_clk(),
  .sd_cd(),
  .sd_reset(),
  .pti_clk(),
  .pti_rxf(),
  .pti_txe(),
  .pti_rd(),
  .pti_wr(),
  .pti_siwu(),
  .pti_oe(),
  .pti_dat(),
  .spien(),
  .oled_sdin(),
  .oled_sclk(),
  .oled_dc(),
  .oled_res(),
  .oled_vbat(),
  .oled_vdd(),
  .ddr3_ck_p(),
  .ddr3_ck_n(),
  .ddr3_cke(),
  .ddr3_reset_n(),
  .ddr3_ras_n(),
  .ddr3_cas_n(),
  .ddr3_we_n(),
  .ddr3_ba(),
  .ddr3_addr(),
  .ddr3_dq(),
  .ddr3_dqs_p(),
  .ddr3_dqs_n(),
  .ddr3_dm(),
  .ddr3_odt()
//    gtp_clk_p, gtp_clk_n,
//    dp_tx_hp_detect, dp_tx_aux_p, dp_tx_aux_n, dp_rx_aux_p, dp_rx_aux_n,
//    dp_tx_lane0_p, dp_tx_lane0_n, dp_tx_lane1_p, dp_tx_lane1_n
);

/*
Thor2023seq ucpu (
	.coreno_i(32'h10),
	.rst_i(rst),
	.clk_i(clk),
//	.icause_i('d0),
	.wbm_req(req),
	.wbm_resp(resp),
//	.state_o(state),
//	.trigger_o(),
//	.bok_i(1'b0),
	.rb_i(1'b0)
);

scratchmem128 umem1
(
	.rst_i(rst), 
	.clk_i(clk),
	.cti_i(req.cti),
	.tid_i(req.tid),
	.tid_o(resp.tid),
	.cs_i(req.cyc),
	.cyc_i(req.cyc),
	.stb_i(req.stb),
	.next_o(resp.next),
	.ack_o(resp.ack),
	.we_i(req.we),
	.sel_i(req.sel),
	.adr_i(req.adr),
	.dat_i(req.data1),
	.dat_o(resp.dat),
	.adr_o(resp.adr),
	.ip('d0),
	.sp('d0)
);
*/

endmodule
