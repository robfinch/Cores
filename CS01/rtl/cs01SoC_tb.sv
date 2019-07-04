module cs01SoC_tb();
reg clk;
reg rst;
reg [1:0] btn;

initial begin
	rst = 1'b0;
	btn = 2'b00;
	clk = 1'b0;
	#100 btn = 2'b11;
	#1500 btn = 2'b00;
	#20 rst = 1'b1;
	#150 rst = 1'b0;
end

always #42.6667 clk = ~clk;

SocCS01 usoc1
(
	.sysclk(clk),
	.btn(btn)
);

endmodule
