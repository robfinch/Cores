`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
//
// rf68000_divider.v
//  - 32 bit divider
//
// ============================================================================
//
module rf68000_divider(rst, clk, ld, abort, sgn, sgnus, a, b, qo, ro, dvByZr, done, idle);
parameter WID=32;
parameter DIV=3'd3;
parameter IDLE=3'd4;
parameter DONE=3'd5;
input clk;
input rst;
input ld;
input abort;
input sgn;
input sgnus;
input [WID-1:0] a;
input [WID-1:0] b;
output [WID-1:0] qo;
reg [WID-1:0] qo;
output [WID-1:0] ro;
reg [WID-1:0] ro;
output done;
output idle;
output dvByZr;
reg dvByZr;

reg [WID-1:0] aa,bb;
reg so;
reg [2:0] state;
reg [7:0] cnt;
wire cnt_done = cnt==8'd0;
assign done = state==DONE||(state==IDLE && !ld);
assign idle = state==IDLE;
reg ce1;
reg [WID-1:0] q;
reg [WID:0] r;
wire b0 = bb <= r;
wire [WID-1:0] r1 = b0 ? r - bb : r;

initial begin
    q = 32'd0;
    r = 32'd0;
    qo = 32'd0;
    ro = 32'd0;
end

always @(posedge clk)
if (rst) begin
	aa <= {WID{1'b0}};
	bb <= {WID{1'b0}};
	q <= {WID{1'b0}};
	r <= {WID{1'b0}};
	qo <= {WID{1'b0}};
	ro <= {WID{1'b0}};
	cnt <= 8'd0;
	dvByZr <= 1'b0;
	state <= IDLE;
end
else
begin
if (abort)
    cnt <= 8'd00;
else if (!cnt_done)
	cnt <= cnt - 8'd1;

case(state)
IDLE:
	if (ld) begin
		if (sgn) begin
			q <= a[WID-1] ? -a : a;
			bb <= b[WID-1] ? -b : b;
			so <= a[WID-1] ^ b[WID-1];
		end
		else if (sgnus) begin
			q <= a[WID-1] ? -a : a;
            bb <= b;
            so <= a[WID-1];
		end
		else begin
			q <= a;
			bb <= b;
			so <= 1'b0;
			$display("bb=%d", b);
		end
		dvByZr <= b=={WID{1'b0}};
		r <= {WID{1'b0}};
		cnt <= WID+1;
		state <= DIV;
	end
DIV:
	if (!cnt_done) begin
		$display("cnt:%d r1=%h q[63:0]=%h", cnt,r1,q);
		q <= {q[WID-2:0],b0};
		r <= {r1,q[WID-1]};
	end
	else begin
		$display("cnt:%d r1=%h q[63:0]=%h", cnt,r1,q);
		if (sgn|sgnus) begin
			if (so) begin
				qo <= -q;
				ro <= -r[WID:1];
			end
			else begin
				qo <= q;
				ro <= r[WID:1];
			end
		end
		else begin
			qo <= q;
			ro <= r[WID:1];
		end
		state <= DONE;
	end
DONE:
	state <= IDLE;
default: state <= IDLE;
endcase
end

endmodule

module rf68000_divider_tb();
parameter WID=64;
reg rst;
reg clk;
reg ld;
wire done;
wire [WID-1:0] qo,ro;

initial begin
	clk = 1;
	rst = 0;
	#100 rst = 1;
	#100 rst = 0;
	#100 ld = 1;
	#150 ld = 0;
end

always #10 clk = ~clk;	//  50 MHz


rf68000_divider #(WID) u1
(
	.rst(rst),
	.clk(clk),
	.ld(ld),
	.sgn(1'b1),
	.isDivi(1'b0),
	.a(32'd10005),
	.b(32'd27),
	.imm(32'd123),
	.qo(qo),
	.ro(ro),
	.dvByZr(),
	.done(done)
);

endmodule

