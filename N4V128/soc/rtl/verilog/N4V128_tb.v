module N4V128_tb();

reg rstn;
reg xclk;
wire [7:0] led;

initial begin
	xclk = 1'b0;
	rstn = 1'b1;
	#10 rstn = 1'b0;
	#100 rstn = 1'b1;
end

always #5 xclk = ~xclk;

N4V128Sys utb1
(
	.cpu_resetn(rstn),
	.xclk(xclk),
	.led(led),
	.btnu(),
	.btnd(),
	.btnl(),
	.btnr(),
	.btnc(),
	.sw(),
    .kd(),
    .kclk(),
    .TMDS_OUT_clk_p(),
    .TMDS_OUT_clk_n(),
    .TMDS_OUT_data_p(),
    .TMDS_OUT_data_n(),
    .ac_mclk(),
    .ac_adc_sdata(),
    .ac_dac_sdata(),
    .ac_bclk(),
    .ac_lrclk(),
    .scl(),
    .sda(),
    .oled_sdin(),
    .oled_sclk(),
    .oled_dc(),
    .oled_res(),
    .oled_vbat(),
    .oled_vdd(),
    .rtc_clk(),
    .rtc_data(),
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
);

endmodule
