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

module mult114x114(clk, ce, a, b, p);
input clk;
input ce;
input [113:0] a;
input [113:0] b;
output reg [227:0] p;

reg [113:0] p1d;
wire [113:0] z0, z2, p1, z0a, z2a;
reg [113:0] z1;
wire [113:0] ad, bd;
reg [57:0] a1, b1;
reg [56:0] a2, b2;
wire sgn;

always @(posedge clk)
	if (ce) a1 <= a[56:0] - a[113:57];
always @(posedge clk)
	if (ce) b1 <= b[113:57] - b[56:0];

always @(posedge clk)
	if (ce) a2 <= a1[57] ? -a1 : a1;
always @(posedge clk)
	if (ce) b2 <= b1[57] ? -b1 : b1;

delay3 #(114) uda (.clk(clk), .ce(1'b1), .i(a), .o(ad));
delay3 #(114) udb (.clk(clk), .ce(1'b1), .i(b), .o(bd));
vtdl #(1) uds (.clk(clk), .ce(1'b1), .a(4'd12), .d(a1[57]^b1[57]), .q(sgn));

mult57x57 u1 (
  .CLK(clk),
  .CE(ce),
  .A(ad[113:57]),
  .B(bd[113:57]),
  .P(z2)
);

mult57x57 u2 (
  .CLK(clk),
  .CE(ce),
  .A(ad[56:0]),
  .B(bd[56:0]),
  .P(z0)
);

mult57x57 u3 (
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
  if (ce) z2a <= z2;
always @(posedge clk)
  if (ce) z0a <= z0;
always @(posedge clk)
	if (ce) p <= {z2a,z0a} + {z1,57'd0};

endmodule
