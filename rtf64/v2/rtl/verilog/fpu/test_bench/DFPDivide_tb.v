`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPDivider_tb.v
//		- decimal floating point divider test bench
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
//                                                                          
//	Floating Point Multiplier / Divider
//
//	This multiplier/divider handles denormalized numbers.
//	The output format is of an internal expanded representation
//	in preparation to be fed into a normalization unit, then
//	rounding. Basically, it's the same as the regular format
//	except the mantissa is doubled in size, the leading two
//	bits of which are assumed to be whole bits.
//
//
// ============================================================================

module DFPDivide_tb();
parameter N=33;
reg rst;
reg clk;
reg [15:0] adr;
reg [N*4+16+4-1:0] a,b;
wire [N*4+16+4-1:0] o, sqrto;
reg [N*4+16+4-1:0] ad,bd;
wire [N*4+16+4-1:0] od;
reg [3:0] rm;
wire done;

integer n;
reg [N*4+16+4-1:0] a1, b1;
reg [39:0] sum_cc;

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
	#5000000  $fclose(outfile);
	#10 $finish;
end

always #5
	clk = ~clk;

genvar g;
generate begin : gRand
	for (g = 0; g < N*4+16+4; g = g + 4) begin
		always @(posedge clk) begin
			a1[g+3:g] <= $urandom() % 10;
			b1[g+3:g] <= $urandom() % 10;
		end
	end
end
endgenerate

reg [9:0] count;
always @(posedge clk)
if (rst) begin
	adr <= 0;
	count <= 0;
	sum_cc = 0;
end
else
begin
  if (adr==0) begin
    outfile = $fopen("d:/cores2020/rtf64/v2/rtl/verilog/cpu/fpu/test_bench/DFPDivide_tvo.txt", "wb");
    $fwrite(outfile, "rm ------ A ------  ------- B ------  - DUT Quotient - - Square root -\n");
    sum_cc = 0;
  end
	count <= count + 1;
	if (count > 1000)
		count <= 1'd1;
	if (count==2) begin	
		a[N*4+16+4-1:0] <= a1;
		b[N*4+16+4-1:0] <= b1;
		a[N*4+16+4-1:N*4+16+4-4] <= 4'h5;
		b[N*4+16+4-1:N*4+16+4-4] <= 4'h5;
		rm <= adr[15:13];
		//ad <= memd[adr][63: 0];
		//bd <= memd[adr][127:64];
	end
	if (adr==1 && count==2) begin
		a <= 152'h50000700000000000000000000000000000000;
		b <= 152'h50000200000000000000000000000000000000;
	end
	if (adr==1 && count==2) begin
		a <= 152'h50000100000000000000000000000000000000;
		b <= 152'h50000300000000000000000000000000000000;
	end
	if (adr==2 && count==2) begin
		a <= 152'h50000900000000000000000000000000000000;
		b <= 152'h50000200000000000000000000000000000000;
	end
	if (adr==3 && count==2) begin
		a <= 152'h50000000000000000000000000000000000000;
		b <= 152'h50000000000000000000000000000000000000;
	end
	if (adr==4 && count==2) begin
		a <= 152'h50001100000000000000000000000000000000;
		b <= 152'h50001100000000000000000000000000000000;
	end
	if (adr==4 && count==2) begin
		a <= 152'h50000100000000000000000000000000000000;
		b <= 152'h50000300000000000000000000000000000000;
	end
	if (adr==5 && count==2) begin
		a <= 152'h50002100000000000000000000000000000000;
		b <= 152'h50000300000000000000000000000000000000;
	end
	if (adr==6 && count==2) begin
		a <= 152'h50002987654321000000000000000000000000;
		b <= 152'h50000300000000000000000000000000000000;
	end
	if (count > 1000) begin
		sum_cc = sum_cc + u6.u1.u2.clkcnt;
	  $fwrite(outfile, "%h\t%h\t%h\t%h\t%h\t%d\t%f\n", rm, a, b, o, sqrto, u6.u1.u2.clkcnt, $itor(sum_cc) / $itor(adr));
		adr <= adr + 1;
	end
end

//fpMulnr #(64) u1 (clk, 1'b1, a, b, o, rm);//, sign_exe, inf, overflow, underflow);
DFPDividenr #(.N(N)) u6 (
  .rst(rst),
  .clk(clk),
  .ce(1'b1),
  .ld(count==3),
  .op(1'b0),
  .a(a),
  .b(b),
  .o(o),
  .rm(rm),
  .done(done),
  .sign_exe(),
  .inf(),
  .overflow(),
  .underflow()
  );

DFPSqrtnr #(.N(N)) u1 (rst, clk, 1'b1, count==3, a, sqrto, rm);//, sign_exe, inf, overflow, underflow);

endmodule
