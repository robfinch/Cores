module gfx_CalcAddressBench();

reg clk;
reg [11:0] x;
reg [11:0] y;
reg [19:0] count;
reg [11:0] counth;
reg [11:0] countv;
wire [31:0] addr;
wire [6:0] mb, me;
reg [11:0] hdisplayed;

initial begin
	x = -1;
	y = -1;
	clk = 1;
	hdisplayed = 340;
end

always #3 clk = ~clk;

gfx_CalcAddress u1 
(
	.base_address_i(32'h0400000),
	.color_depth_i(3'd5),
	.hdisplayed_i(hdisplayed),
	.x_coord_i(x),
	.y_coord_i(y),
	.address_o(addr),
	.mb_o(mb),
	.me_o(me)
);

always @(posedge clk)
	if (x >= hdisplayed - 1 ) begin
		x <= 0;
		y <= y + 1;
	end
	else
		x <= x + 1;

endmodule
