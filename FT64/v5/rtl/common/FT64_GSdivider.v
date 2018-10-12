// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2018  Robert Finch, Waterloo
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
module FT64_GSdivider(rst, clk, ld, abort, sgn, sgnus, a, b, qo, dvByZr, done, idle);
parameter WID=32;
parameter WHOLE=16;
parameter POINTS=16;
parameter LD=3'd2;
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
wire [WID-1:0] q;
reg ld_dv;
wire gs_done;

initial begin
  qo = 64'd0;
end

DivGoldschmidt #(.WID(WID),.WHOLE(WHOLE),.POINTS(POINTS)) ugsd
(
	.rst(rst),
	.clk(clk),
	.ld(ld_dv),
	.a(aa),
	.b(bb),
	.q(q),
	.done(gs_done),
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
		if (dvByZr)
			state <= DONE;
		else if (gs_done && !ld_dv)
			state <= DONE;
	DONE:
		state <= IDLE;
	default:	state <= IDLE;
	endcase

always @(posedge clk)
if (rst)
	cnt <= 8'h00;
else begin
	if (abort)
	  cnt <= 8'd00;
	else if (ld)
		cnt <= WID+1;
	else if (!cnt_done)
		cnt <= cnt - 8'd1;
end

always @(posedge clk)
if (rst)
	dvByZr <= 1'b0;
else begin
	if (ld)
		dvByZr <= b=={WID{1'b0}};
end

always @(posedge clk)
if (rst) begin
	bb <= {WID{1'b0}};
	qo <= {WID{1'b0}};
	ld_dv <= 1'b0;
end
else
begin

case(state)
IDLE:
	if (ld) begin
		if (sgn) begin
			aa <= a[WID-1] ? -a : a;
			bb <= b[WID-1] ? -b : b;
			so <= a[WID-1] ^ b[WID-1];
		end
		else if (sgnus) begin
			aa <= a[WID-1] ? -a : a;
      bb <= b;
      so <= a[WID-1];
		end
		else begin
			aa <= a;
			bb <= b;
			so <= 1'b0;
			$display("bb=%d", b);
		end
		ld_dv <= 1'b1;
	end
DIV:
	begin
		ld_dv <= 1'b0;
		if ((gs_done & !ld_dv) || dvByZr) begin
			$display("cnt:%d q[63:0]=%h", cnt,q);
			if (sgn|sgnus) begin
				if (so)
					qo <= dvByZr ? {1'b1,{WID-1{1'b0}}} : -q;
				else
					qo <= dvByZr ? {WID-1{1'b1}} : q;
			end
			else
				qo <= dvByZr ? {WID-1{1'b1}} : q;
		end
	end
default: ;
endcase
end

endmodule

module FT64_GSdivider_tb();
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


FT64_GSdivider #(.WID(WID), .WHOLE(32), .POINTS(32)) u1
(
	.rst(rst),
	.clk(clk),
	.ld(ld),
	.sgn(1'b1),
	.sgnus(1'b0),
	.a(64'h1000500000000),
	.b(64'h2700000000),
	.qo(qo),
	.dvByZr(),
	.done(done)
);

endmodule

