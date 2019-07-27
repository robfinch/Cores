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
// Latency 18 clocks.                                     
// ============================================================================

// Thanks to Karatsuba

module mult128x128(clk, ce, ss, su, a, b, p);
input clk;
input ce;
input ss;
input su;
input [127:0] a;
input [127:0] b;
output reg [255:0] p;

reg [127:0] p1d;
reg [127:0] aa, bb;
wire [127:0] z0, z2, p1;
reg [127:0] z1;
wire [127:0] ad, bd;
reg [63:0] a1, b1;
reg [63:0] a2, b2;
reg [255:0] p2;
wire sgn;
reg rsgn;

// Clock #1
// Make both operands positive
always @(posedge clk)
if (su)
	rsgn <= a[127];
else if (ss)
	rsgn <= a[127] ^ b[127];
else
	rsgn <= 1'b0;
always @(posedge clk)
if (ss | su)
	aa <= a[127] ? -a : a;
else
	aa <= a;
always @(posedge clk)
if (ss)
	bb <= b[127] ? -b : b;
else
	bb <= b;

// Clock #2
always @(posedge clk)
	if (ce) a1 <= aa[63:0] - aa[127:64];
always @(posedge clk)
	if (ce) b1 <= bb[127:64] - bb[63:0];
always @(posedge clk)
	if (ce) a2 <= a1[63] ? -a1 : a1;
always @(posedge clk)
	if (ce) b2 <= b1[63] ? -b1 : b1;

delay3 #(128) uda (.clk(clk), .ce(1'b1), .i(aa), .o(ad));
delay3 #(128) udb (.clk(clk), .ce(1'b1), .i(bb), .o(bd));
vtdl #(1) uds (.clk(clk), .ce(1'b1), .a(4'd12), .d(a1[63]^b1[63]), .q(sgn));

mult64x64 u1 (
  .CLK(clk),
  .CE(ce),
  .A(ad[127:64]),
  .B(bd[127:64]),
  .P(z2)
);

mult64x64 u2 (
  .CLK(clk),
  .CE(ce),
  .A(ad[63:0]),
  .B(bd[63:0]),
  .P(z0)
);

mult64x64 u3 (
  .CLK(clk),
  .CE(ce),
  .A(a2),
  .B(b2),
  .P(p1)
);

always @(posedge clk)
	if (ce) p1d <= sgn ? -p1 : p1;

always @(posedge clk)
	if (ce) z1 <= p1d + z2 + z0;

always @(posedge clk)
	if (ce) p2 <= {z2,z0} + {z1,64'd0};

always @(posedge clk)
	if (ce)
		p <= rsgn ? -p2 : p2;

endmodule
