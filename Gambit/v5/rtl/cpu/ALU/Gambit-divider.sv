// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2020  Robert Finch, Waterloo
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
// ============================================================================
//
module divider(rst, clk, ld, abort, sgn, sgnus, a, b, qo, ro, dvByZr, done, idle);
parameter WID=52;
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

reg [WID-1:0] bb;
reg so;
reg [2:0] state;
reg [7:0] cnt;
wire cnt_done = cnt==8'd0;
assign done = state==DONE||(state==IDLE && !ld);
assign idle = state==IDLE;
assign dvByZr = b=={WID{1'b0}};
reg ce1;

reg ldd;
reg [WID-1:0] oa;
reg [WID-1:0] ob;
wire ddone;

initial begin
  qo = {WID{1'd0}};
  ro = {WID{1'd0}};
end

fpdivr16 udiv1 (
	.clk(clk),
	.ld(ldd),
	.a(oa),
	.b(ob),
	.q(q),
	.r(r),
	.done(ddone),
	.lzcnt()
);

always @(posedge clk)
if (rst)
	state <= IDLE;
else
	case(state)
	IDLE:
		if (ld)
			state <= DIV;
	DIV:
		if (ddone | dvByZr)
			state <= DONE;
	DONE:
		state <= IDLE;
	default:	state <= IDLE;
	endcase

always @(posedge clk)
if (rst) begin
	oa <= {WID{1'b0}};
	ob <= {WID{1'b0}};
	qo <= {WID{1'b0}};
	ro <= {WID{1'b0}};
	ldd <= 1'b0;
end
else
begin
	ldd <= 1'b0;
	if (ld) begin
		ldd <= b != {WID{1'b0}};
		if (sgn) begin
			oa <= a[WID-1] ? -a : a;
			ob <= b[WID-1] ? -b : b;
			so <= a[WID-1] ^ b[WID-1];
		end
		else if (sgnus) begin
			oa <= a[WID-1] ? -a : a;
      ob <= b;
      so <= a[WID-1];
		end
		else begin
			oa <= a;
			ob <= b;
			so <= 1'b0;
		end
		if (b == {WID{1'b0}}) begin
			if (sgn|sgnus) begin
				if (so) begin
					qo <= {1'b1,{WID-1{1'b0}}};
					ro <= {1'b1,{WID-1{1'b0}}};
				end
				else begin
					qo <= {WID-1{1'b1}};
					ro <= {WID-1{1'b1}};
				end
			end
			else begin
				qo <= {WID-1{1'b1}};
				ro <= {WID-1{1'b1}};
			end
		end
	end
	if (ddone & ~dvByZr) begin
		if (sgn|sgnus) begin
			if (so) begin
				qo <= -q;
				ro <= -r;
			end
			else begin
				qo <= q;
				ro <= r;
			end
		end
		else begin
			qo <= q;
			ro <= r;
		end
	end
end

endmodule

module divider_tb();
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


divider #(WID) u1
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

