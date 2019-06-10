module fpAddsub_L10d_tb();
reg rst;
reg clk;
reg [12:0] adr;
reg [191:0] mem [0:8191];
reg [191:0] memo [0:9000];
reg [63:0] a,b,a6,b6;
wire [63:0] a5,b5;
wire [63:0] o;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	$readmemh("d:/cores6/rtfItanium/v1/rtl/fpUnit/test_bench/fpAddsub_tvd.txt", mem);
	#20 rst = 1;
	#50 rst = 0;
end

always #5
	clk = ~clk;

vtdl #(64) u2 (clk, 1'b1, 4'd11, a, a5);
vtdl #(64) u3 (clk, 1'b1, 4'd11, b, b5);

always @(posedge clk)
if (rst)
	adr = 0;
else
begin
	adr <= adr + 1;
	a <= mem[adr][63: 0];
	b <= mem[adr][127:64];
	a6 <= a5;
	b6 <= b5;
	if (adr > 5)
		memo[adr-6] <= {o,b5,a5};
	if (adr==8191) begin
		$writememh("d:/cores6/rtfItanium/v1/rtl/fpUnit/test_bench/fpAddsub_L10_tvdo.txt", memo);
		$finish;
	end
end

fpAddsubnr_L10 #(64) u1 (clk, 1'b1, 3'b000, 1'b0, a, b, o);

endmodule
