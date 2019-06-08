module fpdivr8_tb();

reg rst;
reg clk;
reg ld;
reg [15:0] cnt;

wire ce = 1'b1;
wire [32:0] a = 33'h1000;
wire [32:0] b = 33'h10;
wire [32:0] q;
wire [32:0] r;
wire done;

initial begin
	clk = 1;
	rst = 0;
	#100 rst = 1;
	#100 rst = 0;
end

always #20 clk = ~clk;	//  25 MHz

always @(posedge clk)
	if (rst)
		cnt <= 0;
	else begin
		ld <= 0;
		cnt <= cnt + 1;
		if (cnt == 3)
			ld <= 1;
		$display("%d: ld=%b q=%h r=%h done=%b", divu0.cnt, ld, q, r, done);
		if (cnt==2000)
			$finish;
	end
	

fpdivr8 #(33) divu0(.clk(clk), .ld(ld), .a(a), .b(b), .q(q), .r(r), .done(done) );

endmodule



