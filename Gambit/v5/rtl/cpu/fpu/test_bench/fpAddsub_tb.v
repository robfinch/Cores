module fpAddsub_tb();
reg rst;
reg clk;
reg [15:0] adr;
reg [103:0] mem [0:38000];
reg [103:0] memo [0:38000];
reg [163:0] mem52 [0:38000];
reg [163:0] mem52o [0:38000];
reg [31:0] a,b,a6,b6;
wire [31:0] a5,b5;
wire [31:0] o;
reg [51:0] a52,b52;
wire [51:0] a525,b525;
wire [51:0] o52;

reg [3:0] rm, op, op52;
wire [3:0] rm5;
wire [3:0] op5;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	$readmemh("d:/cores5/Gambit/v5/rtl/cpu/fpu/test_bench/fpAddsub_tv.txt", mem);
	$readmemh("d:/cores5/Gambit/v5/rtl/cpu/fpu/test_bench/fpAddsub_tv52.txt", mem52);
	#20 rst = 1;
	#50 rst = 0;
end

always #5
	clk = ~clk;

delay4 #(32) u2 (clk, 1'b1, a, a5);
delay4 #(32) u3 (clk, 1'b1, b, b5);
delay4 #(4) u4 (clk, 1'b1, rm, rm5);
delay4 #(4) u5 (clk, 1'b1, op, op5);
delay4 #(52) u6 (clk, 1'b1, a52, a525);
delay4 #(52) u7 (clk, 1'b1, b52, b525);

reg [7:0] count;

always @(posedge clk)
if (rst) begin
	adr <= 0;
	count <= 0;
end
else
begin
	count <= count + 1;
	if (count==49)
		count <= 0;
	if (count==2) begin
		a <= mem[adr][31: 0];
		b <= mem[adr][63:32];
		rm <= mem[adr][99:96];
		op <= mem[adr][103:100];
		a52 <= mem52[adr][51: 0];
		b52 <= mem52[adr][103:52];
		op52 <= mem52[adr][163:160];
	end
	if (count==48) begin
		memo[adr] <= {op,rm,o,b,a};
		mem52o[adr] <= {op52,rm,o52,b52,a52};
		if (adr==38000) begin
			$writememh("d:/cores5/Gambit/v5/rtl/cpu/fpu/test_bench/fpAddsub_tvo.txt", memo);
			$writememh("d:/cores5/Gambit/v5/rtl/cpu/fpu/test_bench/fpAddsub_tvo52.txt", mem52o);
			$finish;
		end
		adr <= adr + 1;
	end
end

fpAddsubnr #(32) u1 (clk, 1'b1, rm[2:0], op[0], a, b, o);
fpAddsubnr #(52) u9 (clk, 1'b1, rm[2:0], op52[0], a52, b52, o52);

endmodule
