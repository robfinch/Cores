
module FT64v7SoC_tb2();
reg rst;
reg clk;
wire [7:0] led;

wire ddr3_reset_n;
wire ddr3_ck_p;
wire ddr3_ck_n;
wire ddr3_cke;
wire ddr3_ras_n;
wire ddr3_cas_n;
wire ddr3_we_n;
wire [2:0] ddr_ba;
wire [14:0] ddr3_addr;
wire [15:0] ddr3_dq;
wire [1:0] ddr3_dqs_p;
wire [1:0] ddr3_dqs_n;
wire [1:0] ddr3_dm;
wire [0:0] ddr3_odt;


initial begin
    rst = 0;
    clk = 0;
    #10 rst = 1;
    #50 rst = 0;
end

always #5 clk = ~clk;
//always #4000 irq = ~irq;

FT64v7SoC usoc1 (
    .cpu_resetn(~rst),
    .xclk(clk),
    .led(led),
    .sw(8'h00),
    .TMDS_OUT_clk_p(),
    .TMDS_OUT_clk_n(),
    .TMDS_OUT_data_p(),
    .TMDS_OUT_data_n()
/*   
    .ddr3_ck_p(ddr3_ck_p),
    .ddr3_ck_n(ddr3_ck_n),
    .ddr3_cke(ddr3_cke),
    .ddr3_reset_n(ddr3_reset_n),
    .ddr3_ras_n(ddr3_ras_n),
    .ddr3_cas_n(ddr3_cas_n),
    .ddr3_we_n(ddr3_we_n),
    .ddr3_ba(ddr3_ba),
    .ddr3_addr(ddr3_addr),
    .ddr3_dq(ddr3_sq),
    .ddr3_dqs_p(ddr3_dqs_p),
    .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dm(ddr3_dm),
    .ddr3_odt(ddr3_odt)
*/    
);

/*
ddr3 uddr31
(
    .rst_n(ddr3_reset_n),
    .ck(ddr3_ck_p),
    .ck_n(ddr3_ck_n),
    .cke(ddr3_cke),
    .cs_n(1'b0),
    .ras_n(ddr3_ras_n),
    .cas_n(ddr3_cas_n),
    .we_n(ddr3_we_n),
    .dm_tdqs(ddr3_dm),
    .ba(ddr3_ba),
    .addr(ddr3_addr),
    .dq(ddr3_dq),
    .dqs(ddr3_dqs_p),
    .dqs_n(ddr3_dqs_n),
    .tdqs_n(),
    .odt(ddr3_odt)
);
*/

endmodule
