
module FT816_tb();

reg [5:0] btn;
reg [5:0] prev_state;
reg clk;
always #10 clk <= ~clk;

initial begin
	#1 clk <= 1'b0;
	#50 btn <= 6'h00;
	#50 btn <= 6'h3D;
	#20000 btn[1] <= 1'b1;
	#2000 btn[1] <= 1'b0;
end

FT816Sys u1
(
	.btn(btn),
	.xclk(clk),
	.Led(),
	.sw(8'h00)
);

always @(posedge clk)
begin
	prev_state <= u1.u1.u1.state;
	if (prev_state != u1.u1.u1.state) begin
	$display("%d pc=%h ir=%h %s", $time, u1.u1.u1.pc, u1.u1.u1.ir, u1.u1.u1.fnStateName(u1.u1.u1.state));
	end
end

endmodule
