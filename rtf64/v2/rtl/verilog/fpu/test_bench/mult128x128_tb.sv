// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	mult128x128_tb.sv
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

module mult128x128_tb();
reg clk;
reg [23:0] cnt;

reg [127:0] a, b;
wire [255:0] o;

integer outfile;
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
	

always #5 clk = ~clk;

mult128x128 u1 (clk, 1'b1, a, b, o);

always @(posedge clk)
begin
  cnt <= cnt + 1;
  case(cnt[23:5])
  1:
    begin
      a <= 128'd10;
      b <= 128'd10;
    end
  2:
    begin
      a <= 128'd21;
      b <= 128'd1700000;
    end 
  3:
    begin
      a <= 128'd215000;
      b <= 128'd11;
    end 
  default:
    if (cnt[4:0]==5'd0) begin
      a[31:0] <= $urandom();
      b[31:0] <= $urandom();
      if (cnt[23:5] > 19'h200) begin
      	a[63:32] <= $urandom();
      	b[63:32] <= $urandom();
      end
      if (cnt[23:5] > 19'h400) begin
      	a[63:32] <= $urandom();
      	b[63:32] <= $urandom();
      	a[95:64] <= $urandom();
      	b[95:64] <= $urandom();
      	a[127:96] <= $urandom();
      	b[127:96] <= $urandom();
      end
    end
  endcase
end

initial outfile = $fopen("d:/cores2020/rtf64/v2/rtl/verilog/cpu/fpu/test_bench/mult128x128_tvo.txt", "wb");
  always @(posedge clk) begin
    if (cnt[4:0]==5'h1F)
     $fwrite(outfile, "%c%h\t%h\t%h\t%h\n",o!=a*b ? "*" : " ",a,b,o, a*b);
  end

endmodule
