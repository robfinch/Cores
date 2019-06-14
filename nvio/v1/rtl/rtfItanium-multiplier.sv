// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2019  Robert Finch, Waterloo
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
module multiplier(rst, clk, ld, abort, sgn, sgnus, a, b, o, done, idle);
parameter WID=80;
parameter SGNADJO=3'd2;
parameter MULT=3'd3;
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
output [WID*2-1:0] o;
reg [WID*2-1:0] o;
output done;
output idle;

reg [WID-1:0] aa,bb;
reg so;
reg [2:0] state;
reg [7:0] cnt;
wire cnt_done = cnt==8'd0;
assign done = state==DONE || (state==IDLE && !ld); // State == DONE
assign idle = state==IDLE;

wire [159:0] pp;
wire [159:0] pp0;
wire [79:0] pp1;
wire [79:0] pp2;

generate begin : gMults
if (WID > 40) begin
mult40 umul1
(
  .CLK(clk),  // input wire CLK
  .A(aa[39:0]),      // input wire [63 : 0] A
  .B(bb[39:0]),      // input wire [63 : 0] B
  .P(pp0[79:0])      // output wire [127 : 0] P
);
mult40 umul2
(
  .CLK(clk),  // input wire CLK
  .A(aa[79:40]),      // input wire [63 : 0] A
  .B(bb[39:0]),      // input wire [63 : 0] B
  .P(pp1)      // output wire [127 : 0] P
);
mult40 umul3
(
  .CLK(clk),  // input wire CLK
  .A(aa[39:0]),      // input wire [63 : 0] A
  .B(bb[79:40]),      // input wire [63 : 0] B
  .P(pp2)      // output wire [127 : 0] P
);
mult40 umul4
(
  .CLK(clk),  // input wire CLK
  .A(aa[79:40]),      // input wire [63 : 0] A
  .B(bb[79:40]),      // input wire [63 : 0] B
  .P(pp0[159:80])      // output wire [127 : 0] P
);
assign pp = pp0 + {pp1,40'b0} + {pp2,40'b0};
end
else if (WID > 32) begin
mult40 umul1
(
  .CLK(clk),  // input wire CLK
  .A(aa),      // input wire [63 : 0] A
  .B(bb),      // input wire [63 : 0] B
  .P(pp)      // output wire [127 : 0] P
);
end
else if (WID > 16) begin
mult32 umul1
(
  .CLK(clk),  // input wire CLK
  .A(aa),      // input wire [63 : 0] A
  .B(bb),      // input wire [63 : 0] B
  .P(pp)      // output wire [127 : 0] P
);
end
else if (WID > 8) begin
mult16 umul1
(
  .CLK(clk),  // input wire CLK
  .A(aa),      // input wire [63 : 0] A
  .B(bb),      // input wire [63 : 0] B
  .P(pp)      // output wire [127 : 0] P
);
end
else begin
mult8 umul1
(
  .CLK(clk),  // input wire CLK
  .A(aa),      // input wire [63 : 0] A
  .B(bb),      // input wire [63 : 0] B
  .P(pp)      // output wire [127 : 0] P
);
end
end
endgenerate

always @(posedge clk)
if (rst) begin
	aa <= {WID{1'b0}};
	bb <= {WID{1'b0}};
	o <= {WID*2{1'b0}};
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
	  if (sgnus) begin
			aa <= a[WID-1] ? -a : a;
			bb <= b;
			so = a[WID-1];
	  end
		else if (sgn) begin
			aa <= a[WID-1] ? -a : a;
			bb <= b[WID-1] ? -b : b;
			so <= a[WID-1] ^ b[WID-1];
		end
		else begin
			aa <= a;
			bb <= b;
			so <= 1'b0;
		end
		cnt <= 8'd20;
		state <= MULT;
	end
MULT:
	if (cnt_done) begin
		if (sgn|sgnus) begin
			if (so)
				o <= -pp;
			else
				o <= pp;
		end
		else
			o <= pp;
		state <= DONE;
	end
DONE:
	state <= IDLE;
default:
	state <= IDLE;
endcase
end

endmodule

module multiplier_tb();

reg rst;
reg clk;
reg ld;
wire [127:0] o;

initial begin
	clk = 1;
	rst = 0;
	#100 rst = 1;
	#100 rst = 0;
	#100 ld = 1;
	#150 ld = 0;
end

always #10 clk = ~clk;	//  50 MHz


multiplier u1
(
	.rst(rst),
	.clk(clk),
	.ld(ld),
	.sgn(1'b1),
	.isMuli(1'b0),
	.a(64'd0),
	.b(64'd48),
	.o(o)
);

endmodule

