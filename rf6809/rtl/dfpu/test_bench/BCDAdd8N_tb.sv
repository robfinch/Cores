module BCDAdd8N_tb();

reg rst;
reg clk;
reg [15:0] adr;
reg [263:0] a,b;
wire [263:0] o;
reg [3:0] rm;

integer n;
reg [263:0] a1, b1;

integer outfile;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	a = $urandom(1);
	b = 1;
	#20 rst = 1;
	#50 rst = 0;
	#10000000  $fclose(outfile);
	#10 $finish;
end

always #5
	clk = ~clk;

genvar g;
generate begin : gRand
	for (g = 0; g < 264; g = g + 4) begin
		always @(posedge clk) begin
			a1[g+3:g] <= $urandom() % 10;
			b1[g+3:g] <= $urandom() % 10;
		end
	end
end
endgenerate

reg [7:0] count;
always @(posedge clk)
if (rst) begin
	adr <= 0;
	count <= 0;
end
else
begin
  if (adr==0) begin
    outfile = $fopen("d:/cores2022/rf6809/rtl/dfpu/test_bench/BCDAddPairNClk_tvo.txt", "wb");
    $fwrite(outfile, " rm ------- A ------  ------- B ------  ------ sum -----  -- SIM Sum --\n");
  end
	count <= count + 1;
	if (count > 35)
		count <= 1'd1;
	if (count==2) begin
		a <= a1;
		b <= b1;
		rm <= adr[14:12];
		//ad <= memd[adr][63: 0];
		//bd <= memd[adr][127:64];
	end
	if (count==35) begin
		if (adr[11]) begin
	  	$fwrite(outfile, "%c%h\t%h\t%h\t%h\n", "-",rm, a, b, o);
	  end
	  else begin
	  	$fwrite(outfile, "%c%h\t%h\t%h\t%h\n", "+",rm, a, b, o);
	  end
		adr <= adr + 1;
	end
end

//fpMulnr #(64) u1 (clk, 1'b1, a, b, o, rm);//, sign_exe, inf, overflow, underflow);
BCDAdd8NClk #(33) u6 (
  .clk(clk),
  .ci(1'b0),
  .a(a),
  .b(b),
  .o(o),
  .co()
);

endmodule
