`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpFMA128_tb.v
//		- floating point multiplier - adder test bench
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
//	Floating Point Multiplier / Divider
//
//	This multiplier/divider handles denormalized numbers.
//	The output format is of an internal expanded representation
//	in preparation to be fed into a normalization unit, then
//	rounding. Basically, it's the same as the regular format
//	except the mantissa is doubled in size, the leading two
//	bits of which are assumed to be whole bits.
//
//
// ============================================================================

module fpFMA128_tb();
reg rst;
reg clk;
reg [15:0] adr;
reg [515:0] mem [0:24000];
reg [515:0] memo [0:24000];
reg [127:0] a,b,c;
reg [3:0] rm, rmx;
wire [3:0] rms;
wire [127:0] o;
reg [7:0] cnt;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	cnt = 0;
	$readmemh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpFMA128_tv.txt", mem);
	//$readmemh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpFMA_tvd.txt", memd);
	#20 rst = 1;
	#50 rst = 0;
end

always #5
	clk = ~clk;

wire [4:0] dd = 5'd27;

always @(posedge clk)
if (rst) begin
	adr <= 0;
	cnt <= 0;
end else
begin
	cnt <= cnt + 1;
	if (cnt==64)
		cnt <= 0;
	if (cnt==4) 
	begin
		a <= mem[adr][127: 0];
		b <= mem[adr][255:128];
		c <= mem[adr][383:256];
		rm <= mem[adr][515:512];
	end
	if (cnt==63)
	begin
		adr <= adr + 1;
		memo[adr] <= {rm,o,c,b,a};
//		memdo[adr] <= {od,cd17,bd17,ad17};
		//memdo[adr] <= {rmd,od,cdx,bdx,adx};
		if (adr==3999) begin
			$writememh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpFMA128_tvo.txt", memo);
//			$writememh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpFMA_tvdo.txt", memdo);
			$finish;
		end
	end
end

fpFMA128nr #(128) u1 (clk, 1'b1, 1'b0, rm[2:0], a, b, c, o);//, sign_exe, inf, overflow, underflow);
//fpFMAnr #(64) u15 (clk, 1'b1, 1'b0, rmd[2:0], ad, bd, cd, od);//, inf, overflow, underflow, inexact);

endmodule
