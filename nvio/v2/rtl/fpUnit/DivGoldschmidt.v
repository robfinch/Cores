// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DivGoldschmidt.v
//		
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
//
// ============================================================================
//
`include "fpConfig.sv"

module DivGoldschmidt(rst, clk, ld, a, b, q, done, lzcnt);
parameter FPWID=32;
parameter WHOLE=16;
parameter POINTS=16;
parameter LEFT=1'b1;
localparam SIZE=FPWID+WHOLE;
localparam POINTS2 = POINTS+WHOLE;
input rst;
input clk;
input ld;
input [FPWID-1:0] a;
input [FPWID-1:0] b;
output reg [FPWID*2-1:0] q;
output reg done;
output reg [7:0] lzcnt;
parameter IDLE = 2'd0;
parameter DIV = 2'd1;
parameter DONE = 2'd2;
parameter DIV2 = 2'd3;

integer n;
// Scale D so it is between 0 < D < 1 (shift)
reg [SIZE-1:0] F;
reg [SIZE*3-1:0] N, D;
wire [SIZE*3-1:0] N1, D1;
assign N1 = N * F;
assign D1 = D * F;
reg [1:0] state = IDLE;
reg [7:0] count = 0;
reg [7:0] lzcnt2;
wire [7:0] shft;

// Count the leading zeros on the b side input. Determines how much
// shifting is required.
always @*
begin
	lzcnt2 = 8'd0;
	if (b[FPWID-1]==1'b0)
		for (n = FPWID-2; n >= 0; n = n - 1)
			if(b[n] && lzcnt2==8'd0)
				lzcnt2 = (FPWID-1)-n;
end


// Count the leading zeros in the output. the float divider uses this.
always @*
begin
	lzcnt = 8'd0;
	if (q[FPWID*2-1]==1'b0)
		for (n = FPWID*2-2; n >= 0; n = n - 1)
			if(q[n] && lzcnt==8'd0)
				lzcnt = (FPWID*2-1)-n;
end

wire shift_left = lzcnt2 > WHOLE;
assign shft = shift_left ? lzcnt2-WHOLE : WHOLE-lzcnt2;
//assign done = (state==IDLE && !ld)||state==DONE;

always @(posedge clk)
if (rst) begin
	done <= 1'b0;
	count <= 6'd0;
	state <= IDLE;
end
else begin
	done <= 1'b0;
case(state)
IDLE:
	begin
		if (ld) begin
			// Shifting the numerator and denomintor right or left using a barrel
			// or funnel shifter is what gives Goldschmidt a lot of it's performance.
			// Most of the divide is being performed by shifting.
			// For most floating point numbers shifting left isn't required as the
			// number is always between 1.0 and 2.0. Instead typically only a single
			// shift to the right is required. For fixed point numbers however, we
			// probably want to be able to shift left, hence the LEFT parameter.
			// With no left shifting the only impact is for denormal numbers which
			// take longer for the divide to converge.
			if (shift_left) begin
				if (LEFT) begin
					N <= {16'd0,a,{WHOLE{1'b0}}} << shft;
					D <= {16'd0,b,{WHOLE{1'd0}}} << shft;
					F <= {16'd2,{POINTS2{1'b0}}} - ({b,{WHOLE{1'd0}}} << shft);
				end
				else begin
					N <= {16'd0,a,{WHOLE{1'b0}}};
					D <= {16'd0,b,{WHOLE{1'd0}}};
					F <= {16'd2,{POINTS2{1'b0}}} - ({b,{WHOLE{1'd0}}});
				end
			end
			else begin
				N <= {16'd0,a,{WHOLE{1'b0}}} >> shft;
				D <= {16'd0,b,{WHOLE{1'd0}}} >> shft;
				F <= {16'd2,{POINTS2{1'b0}}} - ({b,{WHOLE{1'd0}}} >> shft);
			end
			count <= 0;
			state <= DIV;
		end
	end
DIV:
	begin
		$display("C: %d N: %x D: %x F: %x", count, N,D,F);
		N <= N1[SIZE*3-1:POINTS2] + N1[POINTS2-1];
		D <= D1[SIZE*3-1:POINTS2] + D1[POINTS2-1];
		F <= {16'd2,{POINTS2{1'd0}}} - (D1[SIZE*3-1:POINTS2] + D1[POINTS2-1]);
//		q <= N1[SIZE*2-1:POINTS2] + N1[POINTS2-1];
		if (D[SIZE*3-1:0]=={2'h1,{POINTS2{1'd0}}})
			state <= DONE;
		count <= count + 1;
	end
DONE:
	begin
		done <= 1'b1;
		q <= N[SIZE*3-1:0];
		state <= IDLE;
	end
endcase
end

endmodule

module G_divider_tb();
parameter FPWID=4;
reg rst;
reg clk;
reg ld;
wire done;
wire [FPWID*2-1:0] qo;
reg [3:0] state;
reg [3:0] a, b;
reg [7:0] count;

initial begin
	clk = 1;
	rst = 0;
	#100 rst = 1;
	#100 rst = 0;
	#100 ld = 1;
	#150 ld = 0;
end

always #10 clk = ~clk;	//  50 MHz

always @(posedge clk)
if (rst) begin
	state <= 3'd0;
	count = 0;
end
else begin
case(state)
3'd0:	
	begin
		ld <= 1;
		a <= count[7:4];
		b <= count[3:0];
	end
3'd1:
	if (done) begin
		$display("C: %x Q: %x  f: %x", count, qo, f0);
		state <= 3'd2;
	end
3'd2:
	begin
		count <= count + 8'd1;
		state <= 3'd0;
	end
endcase
end

DivGoldschmidt #(.FPWID(FPWID),.WHOLE(1),.POINTS(3)) u00
(
	.rst(rst),
	.clk(clk),
	.ld(ld),
//	.sgn(1'b1),
//	.isDivi(1'b0),
	.a(a),
	.b(b),
//	.imm(64'd123),
	.q(qo),
//	.ro(ro),
//	.dvByZr(),
	.done(done),
	.lzcnt()
);

endmodule

