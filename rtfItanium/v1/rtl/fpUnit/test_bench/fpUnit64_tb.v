module fpUnit64_tb();
reg rst;
reg clk, clk4x;
reg [12:0] adr;
reg [191:0] mem [0:8191];
reg [191:0] memo [0:9000];
reg [63:0] a,b,a6,b6;
wire [63:0] a5,b5;
wire [63:0] o;
reg ld;
reg [9:0] cnt;
wire done;
reg [39:0] ir;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	clk4x = 1'b0;
	adr = 0;
	$readmemh("d:/cores6/rtfItanium/v1/rtl/fpUnit/test_bench/fpRem_tvd.txt", mem);
	#20 rst = 1;
	#50 rst = 0;
end

always #8
	clk = ~clk;
always #2
	clk4x = ~clk4x;

vtdl #(64) u2 (clk, 1'b1, 4'd11, a, a5);
vtdl #(64) u3 (clk, 1'b1, 4'd11, b, b5);

always @(posedge clk)
if (rst) begin
	adr = 0;
	ir <= 1'd0;
	ir[9:6] <= 4'h2;		// FLT2
	ir[39:35] <= 5'h0A;	// FREM
end
else
begin
	ld <= 1'b0;
	if (done) begin
		ld <= 1'b1;
		adr <= adr + 1;
		a <= mem[adr][63: 0];
		b <= mem[adr][127:64];
		a6 <= a5;
		b6 <= b5;
		memo[adr] <= {o,b,a};
		if (adr==8191) begin
			$writememh("d:/cores6/rtfItanium/v1/rtl/fpUnit/test_bench/fpRem_tvdo.txt", memo);
			$finish;
		end
	end
end

fpUnit #(64) u1 (
	.rst(rst),
	.clk(clk),
	.clk4x(clk4x),
	.ce(1'b1),
	.ir(ir),
	.ld(ld),
	.a(a),
	.b(b),
	.c(64'd0),
	.imm(),
	.o(o),
	.csr_i(),
	.status(),
	.exception(),
	.done(done),
	.rm(3'b000)
);

endmodule
