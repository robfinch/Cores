`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPAddsub128_tb.v
//		- decimal floating point addsub test bench
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================

module DFPAddsub128_tb();
reg rst;
reg clk;
reg [15:0] adr;
reg [127:0] a,b;
wire [127:0] o;
reg [127:0] ad,bd;
reg [127:0] od;
reg [3:0] rm;

integer n;
reg [127:0] a1, b1;
wire [63:0] doubleA = {a[31], a[30], {3{~a[30]}}, a[29:23], a[22:0], {29{1'b0}}};
wire [63:0] doubleB = {b[31], b[30], {3{~b[30]}}, b[29:23], b[22:0], {29{1'b0}}};

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
	for (g = 0; g < 128; g = g + 4) begin
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
    outfile = $fopen("d:/cores2022/rf6809/rtl/dfpu/test_bench/DFPAddsub128_tvo.txt", "wb");
    $fwrite(outfile, " rm ------- A ------  ------- B ------  ------ sum -----  -- SIM Sum --\n");
  end
	count <= count + 1;
	if (count > 35)
		count <= 1'd1;
	if (count==2) begin
		a <= a1;
		b <= b1;
		a[127:124] <= 4'h5;
		b[127:124] <= 4'h5;
		rm <= adr[14:12];
		//ad <= memd[adr][63: 0];
		//bd <= memd[adr][127:64];
	end
	if (adr==1 && count==2) begin
		a <= 128'h50000700000000000000000000000000;
		b <= 128'h50000200000000000000000000000000;
	end
	if (adr==2 && count==2) begin
		a <= 128'h50000900000000000000000000000000;
		b <= 128'h50000200000000000000000000000000;
	end
	if (adr==3 && count==2) begin
		a <= 128'h50000000000000000000000000000000;
		b <= 128'h50000000000000000000000000000000;
	end
	if (adr==4 && count==2) begin
		a <= 128'h44000000000000000000000000000000;
		b <= 128'h44000000000000000000000000000000;
	end
	if (adr==5 && count==2) begin
		a <= 128'h44004000000000000000000000000000;
		b <= 128'h44004000000000000000000000000000;
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
DFPAddsub128nr u6 (
  .clk(clk),
  .ce(1'b1),
  .op(adr[11]),
  .a(a),
  .b(b),
  .o(o),
  .rm(rm)
  );

endmodule
