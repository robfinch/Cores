module fpRes_tb();
reg rst;
reg clk;
reg [12:0] adr;
reg [127:0] mem [0:8191];
reg [127:0] memo [0:9000];
reg [63:0] a,a6;
wire [63:0] a5;
wire [63:0] o;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	$readmemh("d:/cores6/rtfItanium/v1/rtl/fpUnit/fpRes_tv.txt", mem);
	#20 rst = 1;
	#50 rst = 0;
end

always #5
	clk = ~clk;

delay3 #(64) u2 (clk, 1'b1, a, a5);

always @(posedge clk)
if (rst)
	adr = 0;
else
begin
	adr <= adr + 1;
	a <= mem[adr][63: 0];
	a6 <= a5;
	if (adr > 2)
		memo[adr-1] <= {o,a5};
	if (adr==8191) begin
		$writememh("d:/cores6/rtfItanium/v1/rtl/fpUnit/fpRes_tvo.txt", memo);
		$finish;
	end
end

fpRes #(64) u1 (clk, a, o);

endmodule
