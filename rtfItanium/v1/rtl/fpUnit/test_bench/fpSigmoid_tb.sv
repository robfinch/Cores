// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	sigmoid_tb.v
//		- test sigmoid
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
//
// This module returns the sigmoid of a number using a lookup table.
// -1.0 or +1.0 is returned for entries outside of the range -8.0 to +8.0
//                                                                          
//
// ============================================================================

module sigmoid_tb();
reg clk, rst;
reg [12:0] ndx;
wire [31:0] o;

initial begin
  #0 rst = 1'b0;
  #0 clk = 1'b0;
  #10 rst = 1'b1;
  #40 rst = 1'b0;
end

always #5 clk = ~clk;

reg [31:0] RngLUT [0:8191];
initial begin
`include "D:\Cores6\rtfItanium\v1\rtl\fpUnit\RangeTbl.ver"
end

fpSigmoid #(32) u1 (clk, 1'b1, RngLUT[ndx], o);

always @(posedge clk)
if (rst)
  ndx = 0;
else begin
  ndx = ndx + 13'd1;
end

wire [31:0] o1, o2;
// Multiply number by 4096 (it is in range -1 to 1) then convert to integer
assign o1[22:0] = o[22:0];
assign o1[30:23] = o[30:23] + 8'd12; // we know this won't overflow
assign o1[31] = o[31];

f2i #(32) u2
(
  .clk(clk),
  .ce(1'b1),
  .i(o1),
  .o(o2)
);

endmodule
