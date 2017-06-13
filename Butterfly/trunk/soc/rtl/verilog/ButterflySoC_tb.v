
module ButterflySoC_tb();
reg rst;
reg clk;
wire [7:0] led;

initial begin
    #0 clk = 1'b0;
    #0 rst = 1'b0;
    #10 rst = 1'b1;
    #50 rst = 1'b0;
end

always #5 clk = ~clk;

ButterflySoC u1 
(
    .cpu_resetn(!rst),
    .xclk(clk),
    .btnl(),
    .btnr(),
    .btnc(),
    .btnd(),
    .btnu(),
    .led(led),
    .TMDS_OUT_clk_n(),
    .TMDS_OUT_clk_p(),
    .TMDS_OUT_data_n(),
    .TMDS_OUT_data_p() 
);

endmodule
