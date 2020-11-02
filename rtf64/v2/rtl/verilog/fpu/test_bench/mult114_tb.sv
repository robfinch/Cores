module mult114_tb();
reg clk;
wire [227:0] p;
wire [227:0] p2;

initial begin
	clk = 1'b0;
end

always #5
	clk = ~clk;

mult114x114 u1 (clk, 114'h12345678, 114'h100000, p);
mult114x114 u2 (clk, 114'h123456789ABCDEF01234, 114'h1000000000, p2);

endmodule
