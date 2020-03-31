module Thor2020SoC_tb();

reg clk;
reg rstn;

initial begin
	rstn = 1'b1;
	#20 rstn = 1'b0;
	#200 rstn = 1'b1;
	clk = 1'b0;
end

always #10 clk = ~clk;

ThorSoC usoc1
(
	.cpu_resetn(rstn),
	.xclk(clk),
	.led(),
	.sw()
);

endmodule
