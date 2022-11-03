module rf68000_tb();
reg rst;
reg clk;

initial begin
	clk = 1'b0;
	rst = 1'b0;
	#10 rst = 1'b1;
	#300 rst = 1'b0;
end

always #5 clk = ~clk;

rf68000_soc usic1
(
	.cpu_resetn(~rst),
	.xclk(clk),
	.led(),
	.sw(),
	.btnl(), .btnr(), .btnc(), .btnd(), .btnu(),
  .kclk(), .kd(), .uart_txd(), .uart_rxd(),
  .TMDS_OUT_clk_p(), .TMDS_OUT_clk_n(), .TMDS_OUT_data_p(), .TMDS_OUT_data_n()
/*
  ac_mclk, ac_adc_sdata, ac_dac_sdata, ac_bclk, ac_lrclk,
  rtc_clk, rtc_data,
  spiClkOut, spiDataIn, spiDataOut, spiCS_n,
  sd_cmd, sd_dat, sd_clk, sd_cd, sd_reset,
  pti_clk, pti_rxf, pti_txe, pti_rd, pti_wr, pti_siwu, pti_oe, pti_dat, spien,
  oled_sdin, oled_sclk, oled_dc, oled_res, oled_vbat, oled_vdd
  ,ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_reset_n,ddr3_ras_n,ddr3_cas_n,ddr3_we_n,
  ddr3_ba,ddr3_addr,ddr3_dq,ddr3_dqs_p,ddr3_dqs_n,ddr3_dm,ddr3_odt
*/
//    gtp_clk_p, gtp_clk_n,
//    dp_tx_hp_detect, dp_tx_aux_p, dp_tx_aux_n, dp_rx_aux_p, dp_rx_aux_n,
//    dp_tx_lane0_p, dp_tx_lane0_n, dp_tx_lane1_p, dp_tx_lane1_n
);

endmodule
