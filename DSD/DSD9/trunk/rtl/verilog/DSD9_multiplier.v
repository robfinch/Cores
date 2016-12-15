// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2016  Robert Finch, Stratford
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
// DSD7_multiplier.v
// 3 cycle latency
//
// ============================================================================
//
module DSD9_multiplier(clk, a, b, p);
input clk;
input [79:0] a;
input [79:0] b;
output reg [159:0] p;

reg [79:0] p1,p2,p3,p4;
reg [159:0] sum1,sum2,sum3;

always @(posedge clk)
    p1 = a[39:0] * b[39:0];
always @(posedge clk)
    p2 = a[39:0] * b[79:40];
always @(posedge clk)
    p3 = a[79:40] * b[39:0];
always @(posedge clk)
    p4 = a[79:40] * b[79:40];
always @(posedge clk)
    sum1 <= {p4,p1};
always @(posedge clk)
    sum3 <= {p2+p3,40'h0000};
always @(posedge clk)
    p <= sum1 + sum3; 

endmodule

module DSD9_multiplier_tb();
reg rst;
reg clk;
reg ld;
wire done;
wire [63:0] p;

initial begin
	clk = 1;
	rst = 0;
	#100 rst = 1;
	#100 rst = 0;
	#100 ld = 1;
	#150 ld = 0;
end

always #10 clk = ~clk;	//  50 MHz


DSD9_multiplier u1
(
	.clk(clk),
	.a(112345678),
	.b(987654321),
	.p(p)
);

endmodule

