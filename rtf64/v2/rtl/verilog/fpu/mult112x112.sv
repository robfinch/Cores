// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
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
// Latency 16 clocks.                                     
// ============================================================================

// Thanks to Karatsuba

module mult112x112(clk, a, b, p);
input clk;
input [111:0] a;
input [111:0] b;
output reg [223:0] p;

reg [111:0] p1d;
wire [111:0] z0, z2, p1;
reg [111:0] z1;
wire [111:0] ad, bd;
reg [56:0] a1, b1;
reg [55:0] a2, b2;
wire sgn;

always @(posedge clk)
	a1 <= a[55:0] - a[111:56];
always @(posedge clk)
	b1 <= b[111:56] - b[55:0];
always @(posedge clk)
	a2 <= a1[56] ? -a1 : a1;
always @(posedge clk)
	b2 <= b1[56] ? -b1 : b1;

delay3 #(112) uda (.clk(clk), .ce(1'b1), .i(a), .o(ad));
delay3 #(112) udb (.clk(clk), .ce(1'b1), .i(b), .o(bd));
vtdl #(1) uds (.clk(clk), .ce(1'b1), .a(4'd12), .d(a1[56]^b1[56]), .q(sgn));

mult56x56 u1 (
  .CLK(clk),
  .A(ad[111:56]),
  .B(bd[111:56]),
  .P(z2)
);

mult56x56 u2 (
  .CLK(clk),
  .A(ad[55:0]),
  .B(bd[55:0]),
  .P(z0)
);

mult56x56 u3 (
  .CLK(clk),
  .A(a2),
  .B(b2),
  .P(p1)
);

always @(posedge clk)
	p1d <= sgn ? -p1 : p1;

always @(posedge clk)
	z1 <= p1d + z2 + z0;

always @(posedge clk)
	p <= {z2,z0} + {z1,56'd0};

endmodule
