// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	intToPosit.sv
//    - integer to posit number converter
//    - parameterized width
//
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
// ============================================================================
//
`timescale 1ns / 1ps
module intToPosit_tb_v;

function [31:0] log2;
input reg [31:0] value;
	begin
	value = value-1;
	for (log2=0; value>0; log2=log2+1)
        	value = value>>1;
      	end
endfunction

parameter N=32;
parameter E=8;
parameter Bs=log2(N);
parameter es = 2;

reg clk;
reg [19:0] cnt;

wire signed [N-1:0] out, outi;

reg [N-1:0] a, a1;

reg [31:0] fa;
wire [31:0] f2po;
fpToPosit #(.FPWID(32)) ufp1 (.i(fa), .o(f2po));

wire [63:0] double = {fa[31], fa[30], {3{~fa[30]}}, fa[29:23], fa[22:0], {29{1'b0}}};

// Instantiate the Unit Under Test (UUT)
intToPosit #(.PSTWID(N), .es(es)) u2 (.i(a), .o(out));
positToInt #(.PSTWID(N), .es(es)) u3 (.clk(clk), .ce(1'b1), .i(f2po), .o(outi));

//FP_to_posit #(.N(32), .E(8), .es(es)) u3 (in, out3);
//Posit_to_FP #(.N(32), .E(8), .es(es)) u5 (out, out3);


	initial begin
	  a = $urandom(1);
		// Initialize Inputs
		clk = 1;
		cnt = 0;
		// Wait 100 ns for global reset to finish
		#1000000 
		$fclose(outfile);
		$finish;
	end
	
always #5 clk=~clk;
always @(posedge clk) begin
  a <= $urandom();
  cnt <= cnt + 1;
  if (cnt > 10000) begin
    if (cnt[4:0]==5'd0)
      fa <= $urandom();
  end
  else
  case (cnt[19:5])
  2:  fa <= 32'h3f000001; // 0.5 + 1ulp
  3:  fa <= 32'h3EFFFFFF; // 0.4999...
  4:  a <= 32'h17cf4600;
  5:  a <= 10;
  6:  a <= -1;
  7:  a <= -10;
  8:  a <= 100;
  default: 
    if (cnt[4:0]==5'h0)
      a <= $urandom();
  endcase
end

integer outfile;
initial outfile = $fopen("d:/cores2020/rtf64/v2/rtl/verilog/cpu/pau/test_bench/intToPosit_tvo32.txt", "wb");
  always @(posedge clk) begin
    if (cnt[4:0]==5'h1F)
     $fwrite(outfile, "%h\t%d\t%h\t%d\t%e\n",f2po,a,out,outi,$bitstoreal(double));
  end

endmodule

