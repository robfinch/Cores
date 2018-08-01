// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// FT64 Superscaler
// FT64_divider.v
//  - 64 bit divider
//
// ============================================================================
//
module FT64_divider(rst, clk, ld, abort, sgn, sgnus, a, b, qo, ro, dvByZr, done, idle);
parameter WID=64;
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

reg [WID-1:0] bb;
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
    q = 64'd0;
    r = 64'd0;
    qo = 64'd0;
    ro = 64'd0;
end

always @(posedge clk)
if (rst) begin
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
		if (dvByZr)
			count <= 8'h00;
	end
	else begin
		$display("cnt:%d r1=%h q[63:0]=%h", cnt,r1,q);
		if (sgn|sgnus) begin
			if (so) begin
				qo <= dvByZr ? {1'b1,{WID-1{1'b0}}} : -q;
				ro <= dvByZr ? {1'b1,{WID-1{1'b0}}} : -r[WID:1];
			end
			else begin
				qo <= dvByZr ? {WID-1{1'b1}} : q;
				ro <= dvByZr ? {WID-1{1'b1}} : r[WID:1];
			end
		end
		else begin
			qo <= dvByZr ? {WID-1{1'b1}} : q;
			ro <= dvByZr ? {WID-1{1'b1}} : r[WID:1];
		end
		state <= DONE;
	end
DONE:
	state <= IDLE;
default: state <= IDLE;
endcase
end

endmodule

module FT64_divider_tb();
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


FT64_divider #(WID) u1
(
	.rst(rst),
	.clk(clk),
	.ld(ld),
	.sgn(1'b1),
	.isDivi(1'b0),
	.a(64'd10005),
	.b(64'd27),
	.imm(64'd123),
	.qo(qo),
	.ro(ro),
	.dvByZr(),
	.done(done)
);

endmodule

