module mult112_tb();
reg clk;
wire [223:0] p;
wire [223:0] p2;

initial begin
	clk = 1'b0;
end

always #5
	clk = ~clk;

mult112x112 u1 (clk, 112'h12345678, 112'h100000, p);
mult112x112 u2 (clk, 112'h123456789ABCDEF01234, 112'h1000000000, p2);

endmodule
