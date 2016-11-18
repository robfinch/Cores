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
module DSD7_multiplier(clk, a, b, p);
input clk;
input [31:0] a;
input [31:0] b;
output reg [63:0] p;

reg [31:0] p1,p2,p3,p4;
reg [63:0] sum1,sum2,sum3;

always @(posedge clk)
    p1 = a[15:0] * b[15:0];
always @(posedge clk)
    p2 = a[15:0] * b[31:16];
always @(posedge clk)
    p3 = a[31:16] * b[15:0];
always @(posedge clk)
    p4 = a[31:16] * b[31:16];
always @(posedge clk)
    sum1 <= {p4,p1};
always @(posedge clk)
    sum3 <= {p2+p3,16'h0000};
always @(posedge clk)
    p <= sum1 + sum3; 

endmodule

module DSD7_multiplier_tb();
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


DSD7_multiplier u1
(
	.clk(clk),
	.a(112345678),
	.b(987654321),
	.p(p)
);

endmodule

