`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpRes_tb.v
//		- floating point reciprocal estimate test bench
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
// ============================================================================

module fpRes_tb();
reg rst;
reg clk;
reg [12:0] adr;
reg [127:0] mem [0:8191];
reg [191:0] memo [0:9000];
reg [63:0] a,a6,o1;
wire [63:0] a5;
wire [63:0] o,o5;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	$readmemh("d:/cores6/rtfItanium/v1/rtl/fpUnit/fpRes_tv.txt", mem);
	#20 rst = 1;
	#50 rst = 0;
end

always #5
	clk = ~clk;

delay3 #(64) u2 (clk, 1'b1, a, a5);
delay3 #(64) u3 (clk, 1'b1, o1, o5);

always @(posedge clk)
if (rst)
	adr = 0;
else
begin
	adr <= adr + 1;
	a <= mem[adr][63: 0];
	o1 <= mem[adr][127:64];
	a6 <= a5;
	memo[adr] <= {o5,o,a5};
	if (adr==8191) begin
		$writememh("d:/cores6/rtfItanium/v1/rtl/fpUnit/fpRes_tvo.txt", memo);
		$finish;
	end
end

fpRes #(64) u1 (clk, 1'b1, a, o);

endmodule
