`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006, 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpmulr2.v
//		Radix 2 floating point multiplier primitive
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
//	Performance
//	Webpack 8.1i  xc3s1000-4ft256
//	202 slices / 382 LUTs / 72.5 MHz
// ============================================================================
//
module fpmulr2
#(	parameter WID = 24 )
(
	input rst,
	input clk,
	input ce,
	input ld,
	input [WID-1:0] a,
	input [WID-1:0] b,
	output reg [WID*2:0] p,
	output done
);
localparam DMSB = WID-1;

wire [WID:0] sum;		// remainder holds
reg [7:0] cnt;				// iteration count
reg [WID-1:0] m;
assign sum = p[WID*2-1:0] + b;


always @(posedge clk)
if (rst)
	cnt <= 0;		// force done signal valid
else begin
	if (ce) begin
		if (ld)
			cnt <= WID*2-1;
		else if (!done)
			cnt <= cnt - 1;
	end
end


always @(posedge clk)
	if (ce) begin
		if (ld) begin
			m <= a;
			p <= {WID*2{1'b0}};
		end
		else if (!done) begin
			$display("sum=%h m=%h b=%h", sum, m, b);
			m <= {m,1'b0};
			if (m[WID-1])
				p <= {sum,1'b0};
			else
				p <= {p,1'b0};
		end
	end

// correct remainder
assign done = ~|cnt;

endmodule

/*
module fpdiv_tb();

reg rst;
reg clk;
reg ld;
reg [6:0] cnt;

wire ce = 1'b1;
wire [49:0] a = 50'h0_0000_0400_0000;
wire [23:0] b = 24'd101;
wire [49:0] q;
wire [49:0] r;
wire done;

initial begin
	clk = 1;
	rst = 0;
	#100 rst = 1;
	#100 rst = 0;
end

always #20 clk = ~clk;	//  25 MHz

always @(posedge clk)
	if (rst)
		cnt <= 0;
	else begin
		ld <= 0;
		cnt <= cnt + 1;
		if (cnt == 3)
			ld <= 1;
		$display("ld=%b q=%h r=%h done=%b", ld, q, r, done);
	end


fpdivr8 divu0(.clk(clk), .ce(ce), .ld(ld), .a(a), .b(b), .q(q), .r(r), .done(done) );

endmodule

*/

