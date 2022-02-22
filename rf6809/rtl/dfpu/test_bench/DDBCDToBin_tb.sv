module DDBCDToBin_tb();

reg rst;
reg clk;
reg [15:0] adr;
reg [171:0] bcd;
reg [7:0] count;

wire [127:0] bin;

integer outfile;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	bcd = $urandom(1);
	#20 rst = 1;
	#50 rst = 0;
	#10000000  $fclose(outfile);
	#10 $finish;
end

always #5
	clk = ~clk;

genvar g;
generate begin : gRand
	for (g = 0; g < 172; g = g + 4) begin
		always @(posedge clk) begin
			if (count==2)
				bcd[g+3:g] <= $urandom() % 10;
		end
	end
end
endgenerate

always @(posedge clk)
if (rst) begin
	adr <= 0;
	count <= 0;
end
else
begin
  if (adr==0) begin
    outfile = $fopen("d:/cores2022/rf6809/rtl/dfpu/test_bench/DDBinToBCD_tvo.txt", "wb");
    $fwrite(outfile, " ------ bin ------  ------ bcd ------  \n");
  end
	count <= count + 1;
	if (count > 140)
		count <= 1'd1;
	if (adr==2) begin
		bcd <= 172'h010;
	end
	if (adr==3) begin
		bcd <= 172'h0100;
	end
	if (adr==4) begin
		bcd <= 172'h12345678;
	end
	if (count==140) begin
  	$fwrite(outfile, "%h\t%h\n", bin, bcd);
		adr <= adr + 1;
	end
end

//fpMulnr #(64) u1 (clk, 1'b1, a, b, o, rm);//, sign_exe, inf, overflow, underflow);
DDBCDToBin #(128) u6 (
	.rst(rst),
  .clk(clk),
  .ld(count==3),
  .bcd(bcd),
  .bin(bin)
);

endmodule
