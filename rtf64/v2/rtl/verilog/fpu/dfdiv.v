// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	dfdiv.v
//    Decimal Float divider primitive
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

module dfdiv(clk, ld, a, b, q, r, done, lzcnt);
parameter N=33;
localparam FPWID = N*4;
parameter RADIX = 10;
localparam FPWID1 = FPWID;//((FPWID+2)/3)*3;    // make FPWIDth a multiple of three
localparam DMSB = FPWID1-1;
input clk;
input ld;
input [FPWID-1:0] a;
input [FPWID-1:0] b;
output reg [FPWID*2-1:0] q;
output reg [FPWID-1:0] r;
output reg done;
output reg [7:0] lzcnt;	// Leading zero digit count as a BCD number


reg [1:0] st;
parameter PREP = 2'd0;
parameter SUBN = 2'd1;
parameter DONE = 2'd2;

reg [3:0] cnt;				// iteration count
reg [7:0] dcnt;				// digit count
reg [9:0] clkcnt;
reg [FPWID*2-1:0] qi = 0;
reg [FPWID+4-1:0] ri = 0;
reg [FPWID-1:0] bi = 0;
wire [FPWID+4-1:0] dif; 
reg gotnz;					// got a non-zero digit

BCDSubN #(.N((FPWID+4)/4)) u1
(
	.ci(1'b0),
	.a(ri),
	.b({4'd0,bi}),
	.o(dif),
	.co(co)
);

always @(posedge clk)
begin
case(st)
SUBN:
	begin
		clkcnt <= clkcnt + 1'd1;
		if (co) begin
			ri <= {ri,qi[FPWID*2-1:FPWID*2-4]};
			qi <= {qi[FPWID*2-5:0],cnt};
			cnt <= 4'd0;
			dcnt <= dcnt - 1'd1;
			if (dcnt==6'd0)
				st <= DONE;
			if (dcnt <= FPWID/4) begin
				if (|cnt)
					gotnz <= 1'b1;
				else if (!gotnz) begin
					if (lzcnt[3:0]==4'd9)
						lzcnt <= lzcnt + 4'd7;
					else
						lzcnt <= lzcnt + 1'd1;
				end
			end
		end
		else begin
			if (clkcnt > 600) begin
				ri <= {ri,qi[FPWID*2-1:FPWID*2-4]};
				qi <= {qi[FPWID*2-5:0],cnt};
				cnt <= 4'd0;
				dcnt <= dcnt - 1'd1;
				if (dcnt==6'd0)
					st <= DONE;
				if (dcnt <= FPWID/4) begin
					if (|cnt)
						gotnz <= 1'b1;
					else if (!gotnz) begin
						if (lzcnt[3:0]==4'd9)
							lzcnt <= lzcnt + 4'd7;
						else
							lzcnt <= lzcnt + 1'd1;
					end
				end
			end
			else begin
				ri <= dif;
				cnt <= cnt + 1'd1;
			end
		end
	end
DONE:
	begin
		q <= qi;
		r <= ri;
		done <= 1'b1;
	end
default:
	st <= SUBN;
endcase
if (ld) begin
	clkcnt <= 10'd0;
	cnt <= 4'd0;
	dcnt <= (FPWID*2)/4;
	qi <= {a,{FPWID{1'd0}}};
	ri <= {FPWID{1'd0}};
	bi <= b;
	st <= SUBN;
	gotnz <= 1'b0;
	lzcnt <= 8'd0;
	done <= 1'b0;
end
end

endmodule

module dfdiv_tb();

reg clk;
reg ld;
reg [107:0] a, b;
wire [215:0] q;
wire [107:0] r;
wire [7:0] lzcnt;

initial begin
	clk = 1'b0;
	ld = 1'b0;
	a = 108'h099_00000000_00000000_00000000;
	b = 108'h560_00000000_00000000_00000000;
	#20 ld = 1'b1;
	#40 ld = 1'b0;
end

always #5 clk = ~clk;

dfdiv #(.N(27)) u1 (
	.clk(clk),
	.ld(ld), 
	.a(a),
	.b(b),
	.q(q),
	.r(r), 
	.done(done),
	.lzcnt(lzcnt)
);
endmodule
