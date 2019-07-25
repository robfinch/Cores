// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpRsqrte_tb.v
//		- test reciprocal square root estimate
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

module fpRsqrte_tb();
reg clk, rst;
reg [12:0] ndx;
wire [31:0] o;

reg [5:0] cnt;
reg [63:0] mem [0:8191];
reg [63:0] memo [0:8191];
reg ld;

initial begin
  #0 rst = 1'b0;
  #0 clk = 1'b0;
	$readmemh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpRsqrte_tv.txt", mem);
  #10 rst = 1'b1;
  #40 rst = 1'b0;
end

always #5 clk = ~clk;

wire [31:0] a = mem[ndx][31:0];
wire [79:0] a1, o3;
F32ToF80 u2 (a, a1);
fpRsqrte #(80) u1 (clk, 1'b1, ld, a1, o3);
F80ToF32 u3 (o3, o);

always @(posedge clk)
if (rst)
  cnt = 0;
else begin
  cnt = cnt + 2'd1;
end
always @(posedge clk)
if (rst)
  ndx = 0;
else begin
	ld <= 1'b0;
	if (cnt==6'd0)
		ld <= 1'b1;
	if (cnt==6'd63) begin
		memo[ndx] <= {o,a};
  	ndx = ndx + 2'd1;
  end
	if (ndx==8191) begin
		$writememh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpRsqrte_tvo.txt", memo);
		$finish;
	end
end

wire [31:0] o1, o2;
// Multiply number by 4096 (it is in range -1 to 1) then convert to integer
assign o1[22:0] = o[22:0];
assign o1[30:23] = o[30:23] + 8'd12; // we know this won't overflow
assign o1[31] = o[31];

f2i #(32) u4
(
  .clk(clk),
  .ce(1'b1),
  .i(o1),
  .o(o2)
);

endmodule
