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
// FT64_multiplier.v
//  - 64 bit multiplier
//
// ============================================================================
//
module FT64_multiplier(rst, clk, ld, abort, sgn, sgnus, a, b, o, done, idle);
parameter WID=64;
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
reg [WID*2-1:0] prod;
//wire [64:0] p1 = aa[0] ? prod[127:64] + b : prod[127:64];
//wire [65:0] p2 = aa[1] ? p1 + {b,1'b0} : p1;
wire [WID+WID/4-1:0] p1 = bb * aa[WID/4-1:0] + prod[WID*2-1:WID];

initial begin
    prod = 64'd0;
    o = 64'd0;
end

always @(posedge clk)
if (rst) begin
	aa <= {WID{1'b0}};
	bb <= {WID{1'b0}};
	prod <= {WID*2{1'b0}};
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
		prod <= {WID*2{1'b0}};
		cnt <= 8'd4;
		state <= MULT;
	end
MULT:
	if (!cnt_done) begin
		aa <= {16'b0,aa[WID-1:WID/4]};
		prod <= {16'b0,prod[WID*2-1:WID/4]};
		prod[WID*2-1:WID*3/4] <= p1;
	end
	else begin
		if (sgn|sgnus) begin
			if (so)
				o <= -prod;
			else
				o <= prod;
		end
		else
			o <= prod;
		state <= DONE;
	end
default:
	state <= IDLE;
endcase
end

endmodule

module FT64_multiplier_tb();

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


FT64_multiplier u1
(
	.rst(rst),
	.clk(clk),
	.ld(ld),
	.sgn(1'b0),
	.isMuli(1'b1),
	.a(64'd56),
	.b(64'd0),
	.imm(64'd27),
	.o(o)
);

endmodule

