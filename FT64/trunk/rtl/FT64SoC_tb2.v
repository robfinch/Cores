
module FT64SoC_tb2();
reg rst;
reg clk;
wire [7:0] led;

initial begin
    rst = 0;
    clk = 0;
    #10 rst = 1;
    #50 rst = 0;
end

always #5 clk = ~clk;

FT64SoC usoc1 (
    .cpu_resetn(~rst),
    .xclk(clk),
    .led(led),
    .sw(),
    .TMDS_OUT_clk_p(),
    .TMDS_OUT_clk_n(),
    .TMDS_OUT_data_p(),
    .TMDS_OUT_data_n()
);


endmodule
