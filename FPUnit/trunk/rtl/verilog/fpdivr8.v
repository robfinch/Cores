`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006, 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// fpdivr8.v
//  - Radix 8 floating point divider primitive
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
//	Webpack 7.1i  xc3s1000-4ft256
//	222 slices / 410 LUTs / 51.5 MHz
// ============================================================================
//
module fpdivr8
#(	parameter WID = 24 )
(
	input clk,
	input ld,
	input [WID-1:0] a,
	input [WID-1:0] b,
	output reg [WID*2-1:0] q,
	output [WID-1:0] r,
	output done
);
localparam DMSB = WID-1;

wire [DMSB:0] rx [2:0];		// remainder holds
reg [DMSB:0] rxx;
reg [5:0] cnt;				// iteration count
wire [DMSB:0] sdq;
wire [DMSB:0] sdr;
wire sddbz;

assign rx[0] = rxx  [DMSB] ? {rxx  ,q[WID*2-1  ]} + b : {rxx  ,q[WID*2-1  ]} - b;
assign rx[1] = rx[0][DMSB] ? {rx[0],q[WID*2-1-1]} + b : {rx[0],q[WID*2-1-1]} - b;
assign rx[2] = rx[1][DMSB] ? {rx[1],q[WID*2-1-2]} + b : {rx[1],q[WID*2-1-2]} - b;


always @(posedge clk)
	if (ld)
		cnt <= WID*2/3;
	else if (!done)
		cnt <= cnt - 1;


always @(posedge clk)
	if (ld)
		rxx <= 0;
	else if (!done)
		rxx <= rx[2];


always @(posedge clk)
	if (ld)
		q <= {a,{WID{1'b0}}};
	else if (!done) begin
		q[WID*2-1:3] <= q[WID*2-1-3:0];
		q[0] <= ~rx[2][DMSB];
		q[1] <= ~rx[1][DMSB];
		q[2] <= ~rx[0][DMSB];
	end

// correct remainder
assign r = rx[2][DMSB] ? rx[2] + b : rx[2];
assign done = cnt[5];

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

