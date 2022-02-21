`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2010-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	dfisqrt.v
//	- integer square root
//  - uses the standard long form calc.
//	- geared towards use in an decimal floating point unit
//	- calculates to WID fractional precision (double width output)
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
// ============================================================================

module dfisqrt(rst, clk, ce, ld, a, o, done);
parameter N=34;
parameter WID = N*4;
localparam MSB = WID-1;
input rst;
input clk;
input ce;
input ld;
input [MSB:0] a;
output reg [WID*2-1:0] o;
output reg done;

reg [3:0] state;
parameter SKIPLZ = 4'd1;
parameter A0 = 4'd2;
parameter S3 = 4'd3;
parameter INCJ = 4'd4;
parameter DONE = 4'd5;
parameter S1 = 4'd6;
parameter S4 = 4'd7;
parameter S2 = 4'd8;

reg [3:0] tbl [0:255];
reg [7:0] tbl5 [0:9];
reg [7:0] sqra [0:9];

initial begin
	sqra[0] = 8'h00;
	sqra[1] = 8'h01;
	sqra[2] = 8'h04;
	sqra[3] = 8'h09;
	sqra[4] = 8'h16;
	sqra[5] = 8'h25;
	sqra[6] = 8'h36;
	sqra[7] = 8'h49;
	sqra[8] = 8'h64;
	sqra[9] = 8'h81;
end

genvar g;
generate begin
	for (g = 0; g < 256; g = g + 1)
		initial begin
			if (g >= 8'h81)
				tbl[g] = 4'h9;
			else if (g >= 8'h64)
				tbl[g] = 4'h8;
			else if (g >= 8'h49)
				tbl[g] = 4'h7;
			else if (g >= 8'h36)
				tbl[g] = 4'h6;
			else if (g >= 8'h25)
				tbl[g] = 4'h5;
			else if (g >= 8'h16)
				tbl[g] = 4'h4;
			else if (g >= 8'h09)
				tbl[g] = 4'd3;
			else if (g >= 8'h04)
				tbl[g] = 4'h2;
			else if (g >= 8'h01)
				tbl[g] = 4'h1;
			else
				tbl[g] = 4'h0;
		end
end
endgenerate

initial begin
	tbl5[0] = 8'h05;
	tbl5[1] = 8'h15;
	tbl5[2] = 8'h25;
	tbl5[3] = 8'h35;
	tbl5[4] = 8'h45;
	tbl5[5] = 8'h55;
	tbl5[6] = 8'h65;
	tbl5[7] = 8'h75;
	tbl5[8] = 8'h85;
	tbl5[9] = 8'h95;
end


reg [7:0] dcnt;
reg [7:0] j;
reg [N*2*4-1:0] b;
reg [N*4*2-1:0] ii;
wire [N*4*2-1:0] firstRa;
reg [N*4*2-1+4:0] ai, Rbx5;
wire [(N*2+1)*4-1:0] Rax2, Rax4, Rax5i, newRax5a;
reg [(N*2+1)*4-1:0] Rax5, pRax5, newRax5;
wire tooBig;

BCDAddN #(.N(N*2+1)) ua1 (.ci(1'b0), .a({4'h0,firstRa}), .b({4'h0,firstRa}), .o(Rax2), .co());
BCDAddN #(.N(N*2+1)) ua2 (.ci(1'b0), .a(Rax2), .b(Rax2), .o(Rax4), .co());
BCDAddN #(.N(N*2+1)) ua3 (.ci(1'b0), .a({4'h0,firstRa}), .b(Rax4), .o(Rax5i), .co());

BCDSubN #(.N(N*2+1)) ua4 (.ci(1'b0), .a(Rax5), .b(Rbx5), .o(newRax5a), .co(tooBig));


wire [3:0] a0 = tbl[ii[N*4*2-1:N*4*2-8]];
wire [7:0] sqra00 = sqra[a0];
wire [N*2*4+3:0] srqa0 = {4'h0,sqra00,{N*2*4-8{1'b0}}};

BCDSubN #(.N(N*2)) ua5 (.ci(1'b0), .a(ii), .b(srqa0), .o(firstRa), .co());

wire [WID*2-1:0] tbl5x = {tbl5[b[3:0]],{(N*2-3)*4{1'b0}}};
wire [WID*2-1:0] tbl5s = tbl5x >> {j,2'h0};

wire [N*2*4-1:0] sum_ai;
BCDAddN #(.N(N*2)) ua6 (.ci(1'b0), .a(ai), .b(tbl5s), .o(sum_ai), .co());

always @(posedge clk)
begin
case(state)
SKIPLZ:
	begin
		Rax5 <= {N*2*4+4{1'd0}};
		Rbx5 <= {N*2*4+4{1'd0}};
		if (ii[N*4*2-1:N*4*2-8]==8'h00) begin
			ii <= {ii[N*4*2-9:0],8'h00};		
			dcnt <= dcnt - 8'd2;
			if (dcnt==8'h00) begin
				o <= {WID*2{1'b0}};
				state <= DONE;
			end
		end
		else
			state <= A0;
	end
	// Get the first digit of the square root.
A0:
	begin
		b <= 4'd0;
		ai <= {4'd0,a0,{(N*2-2)*4{1'b0}}};
		state <= S1;
	end
	// Set initial Ra5
S1:
	begin
		Rax5 <= Rax5i;
		Rbx5 <= {4'h0,sum_ai};
		pRax5 <= Rax5i;
		state <= S2;
	end
S2:
	begin
		newRax5 <= newRax5a;
		if (tooBig) begin
			Rax5 <= {Rax5,4'h0};
			ai <= ai | (b << (N*2-j)*4-8);
			state <= INCJ;
		end
		else begin
			b <= b + 1'd1;
			state <= S3;
		end
	end
S3:
	begin
		pRax5 <= Rax5;
		Rax5 <= newRax5;
		Rbx5 <= {4'h0,sum_ai};
		state <= S2;
	end
INCJ:
	begin
		b <= 4'd0;
		j <= j + 1'd1;
		dcnt <= dcnt - 1'd1;
		if (dcnt==0) begin
			state <= DONE;
			o <= ai;
		end
		else
			state <= S4;
	end
S4:
	begin
		Rbx5 <= {4'h0,sum_ai};
		state <= S2;
	end
DONE:
	begin
		done <= 1'b1;
	end
endcase
if (ld) begin
	state <= SKIPLZ;
	dcnt <= N*2;
	j <= 8'd1;
	b <= 4'd0;
	ii <= {a,{N*4{1'b0}}};
	done <= 1'b0;
end
end

endmodule


module dfisqrt_tb();
parameter N=34;

reg clk;
reg rst;
reg [N*4-1:0] a;
wire [N*4*2-1:0] o;
reg ld;
wire done;
reg [7:0] state;

initial begin
	clk = 1;
	rst = 0;
	#100 rst = 1;
	#100 rst = 0;
end

always #10 clk = ~clk;	//  50 MHz

always @(posedge clk)
if (rst) begin
	state <= 8'd0;
	a <= 64'h987654321;
end
else
begin
ld <= 1'b0;
case(state)
8'd0:
	begin	
		a <= 64'h987654321;
		ld <= 1'b1;
		state <= 8'd1;
	end
8'd1:
	if (done) begin
		$display("i=%h o=%h", a, o);
	end
endcase
end

dfisqrt #(.N(N)) u1 (.rst(rst), .clk(clk), .ce(1'b1), .ld(ld), .a(a), .o(o), .done(done));

endmodule


