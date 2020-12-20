// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	dfmul.v
//    Decimal Float multiplier primitive
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

module dfmul(clk, ld, a, b, p, done);
parameter N=33;
localparam FPWID = N*4;
parameter RADIX = 10;
localparam FPWID1 = FPWID;//((FPWID+2)/3)*3;    // make FPWIDth a multiple of three
localparam DMSB = FPWID1-1;
input clk;
input ld;
input [FPWID-1:0] a;
input [FPWID-1:0] b;
output reg [FPWID*2-1:0] p;
output reg done;


reg [1:0] st;
parameter PREP = 2'd0;
parameter ADDN = 2'd1;
parameter DONE = 2'd2;

reg [3:0] cnt;				// iteration count
reg [7:0] dcnt;				// digit count
reg [9:0] clkcnt;
reg [FPWID*2-1:0] pi = 0;
reg [FPWID-1:0] ai = 0;
reg [FPWID*2-1:0] bi = 0;
wire [FPWID*2-1:0] sum; 

BCDAddN #(.N((FPWID*2)/4)) u1
(
	.ci(1'b0),
	.a(pi),
	.b(bi),
	.o(sum),
	.co()
);

always @(posedge clk)
begin
case(st)
ADDN:
	begin
		clkcnt <= clkcnt + 1'd1;
		if (ai[FPWID-1:FPWID-4]!=4'h0) begin
			pi <= sum;
			ai[FPWID-1:FPWID-4] <= ai[FPWID-1:FPWID-4] - 1'd1;
			cnt <= cnt + 1'd1;
		end
		else begin
			ai <= {ai,4'h0};
			bi <= {4'h0,bi[FPWID*2-1:4]};
			pi <= pi;
			dcnt <= dcnt - 1'd1;
			if (dcnt==6'd0)
				st <= DONE;
		end
	end
DONE:
	begin
		p <= pi;
		done <= 1'b1;
	end
default:
	st <= ADDN;
endcase
if (ld) begin
	clkcnt <= 10'd0;
	cnt <= 4'd0;
	dcnt <= (FPWID*2)/4;
	pi <= {FPWID*2{1'b0}};
	ai <= a;
	bi <= {4'h0,b,{FPWID-4{1'b0}}};
	st <= ADDN;
	done <= 1'b0;
end
end

endmodule

module dfmul_tb();

reg clk;
reg ld;
reg [107:0] a, b;
wire [215:0] p;

initial begin
	clk = 1'b0;
	ld = 1'b0;
	a = 108'h099_00000000_00000000_00000000;
	b = 108'h560_00000000_00000000_00000000;
	#20 ld = 1'b1;
	#40 ld = 1'b0;
end

always #5 clk = ~clk;

dfmul #(27) u1 (
	.clk(clk),
	.ld(ld), 
	.a(a),
	.b(b),
	.p(p),
	.done(done)
);
endmodule
