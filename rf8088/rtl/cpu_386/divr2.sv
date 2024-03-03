// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
//
//
//	divr2.v
//		Radix 2 divider primitive
//
//=============================================================================

module divr2(rst, clk, ce, ld, su, ri, a, b, i, q, r, divByZero, done);
parameter WID = 32;
parameter IDLE = 3'd0;
parameter DIV = 3'd1;
parameter SGN = 3'd2;
input rst;
input clk;
input ce;				// clock enable
input ld;				// pulse to initiate divide
input su;				// 1=signed or 0=unsigned
input ri;				// port: 1=register  or 0=immediate
input [WID-1:0] a;		// dividend
input [WID/2-1:0] b;	// divisor: register port input
input [WID/2-1:0] i;	// divisor: immediate value port input
output [WID-1:0] q;		// quotient
output [WID/2-1:0] r;	// remainder
output divByZero;
output done;			// =1 if divide is finished
localparam DMSB = WID-1;

reg [7:0] cnt;			// iteration count

reg [1:0] ad;
reg [WID/2-1:0] r0;
reg [WID-1:0] q0;
reg [WID-1:0] aa;
reg [WID/2-1:0] bb;
reg [WID-1:0] q;
reg [WID/2-1:0] r;

wire [WID/2:0] dif = r0 - bb;
reg [2:0] state;
reg divByZero;

always_ff @(posedge clk)
if (rst) begin
	cnt <= 8'd0;
	state <= IDLE;
	divByZero <= 1'b0;
	q <= {WID{1'b0}};
	r <= {WID/2{1'b0}};
	r0 <= {WID/2{1'b0}};
	q0 <= {WID{1'b0}};
end
else if (ce) begin
case(state)
IDLE:
	if (ld) begin
		state <= DIV;
		cnt <= 8'd0;
		r0 <= {WID/2{1'b0}};
		if (su) begin
			q0 <= a[WID-1] ? -a : a;
			bb <= ri ? (b[WID/2-1] ? -b : b) : (i[WID/2-1] ? -i : i);
		end
		else begin
			q0 <= a;
			bb <= ri ? b : i;
		end
		divByZero <= b=={WID/2{1'b0}};
		if (b=={WID/2{1'b0}}) begin
			q <= {WID-1{1'b1}};
			state <= IDLE;
		end
	end
DIV:
	if (cnt <= WID) begin
		cnt <= cnt + 8'd1;
		q0[0] <= ~dif[WID/2-1];
		q0[WID-1:1] <= q0[WID-2:0];
		r0[0] <= q0[WID-1];
		if (~dif[WID/2-1])
			r0[WID/2-1:1] <= dif[WID/2-1:0];
		else
			r0[WID/2-1:1] <= r0  [WID/2-2:0];
	end
	else
		state <= SGN;
SGN:
	begin
		if (a[WID-1]^b[WID/2-1] && su)
			q <= -q0;
		else
			q <= q0;
		if (a[WID-1] & su)
			r <= -r0[WID/2-1:1];
		else
			r <= r0[WID/2-1:1];
		state <= IDLE;
	end
default:
	state <= IDLE;
endcase
end

assign done = state==IDLE;

endmodule


module divr2_tb();

reg rst;
reg clk;
reg ld;
reg [6:0] cnt;

wire ce = 1'b1;
wire [31:0] a = -32'd1283;
wire [31:0] b = -32'd14;
wire [31:0] q;
wire [31:0] r;
wire done;

initial begin
	clk = 1;
	rst = 0;
	#100 rst = 1;
	#100 rst = 0;
end

always #10 clk = ~clk;	//  50 MHz

always_ff @(posedge clk)
	if (rst)
		cnt <= 0;
	else begin
		ld <= 0;
		cnt <= cnt + 1;
		if (cnt == 3)
			ld <= 1;
		$display("ld=%b q=%h r=%h done=%b", ld, q, r, done);
	end


divr2 divu0(.rst(rst), .clk(clk), .ce(ce), .ld(ld), .su(1'b1), .ri(1'b0), .a(a), .b(b), .i(b), .q(q), .r(r), .divByZero(), .done(done) );

endmodule



