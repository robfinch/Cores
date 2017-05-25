
module FT832_tb();

reg [5:0] btn;
reg [5:0] prev_state;
reg [31:0] prev_ad;
reg clk;
always #10 clk <= ~clk;

initial begin
	#1 clk <= 1'b0;
	#50 btn <= 6'h00;
	#50 btn <= 6'h3D;
	#20000 btn[1] <= 1'b1;
	#2000 btn[1] <= 1'b0;
end

FT832_NexysVideo u1
(
	.btnu(btn[0]),
	.btnd(btn[1]),
	.btnl(btn[2]),
	.btnr(btn[3]),
	.btnc(btn[4]),
	.xclk(clk),
	.led(),
	.sw(8'h00)
);

always @(posedge clk)
begin
	prev_state <= u1.u1.u1.state;
	prev_ad <= u1.u1.u1.ad;
	if (prev_state != u1.u1.u1.state || u1.u1.u1.ad != prev_ad) begin
	$display("%d %c ad=%h db=%h pc=%h ir=%h %s", $time, u1.u1.u1.rw ? " " : "W",
		u1.u1.u1.ad, u1.u1.u1.db,
		u1.u1.u1.pc, u1.u1.u1.ir, u1.u1.u1.fnStateName(u1.u1.u1.state));
	end
end

endmodule
