`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpFMA_tb.v
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

module fpFMA_tb();
reg rst;
reg clk;
reg [15:0] adr;
reg [131:0] mem [0:24000];
reg [131:0] memo [0:24000];
reg [259:0] memd [0:24000];
reg [259:0] memdo [0:24000];
reg [31:0] a,b,c;
reg [3:0] rm, rmx;
wire [3:0] rms;
wire [31:0] a5,b5,c5;
wire [31:0] o;
wire [31:0] as,bs,cs;
reg [63:0] ad,bd,cd;
wire [63:0] ad5,bd5,cd5,adx,bdx,cdx;
wire [63:0] od;
reg [7:0] cnt;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	cnt = 0;
	$readmemh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpFMA_tv.txt", mem);
	//$readmemh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpFMA_tvd.txt", memd);
	#20 rst = 1;
	#50 rst = 0;
end

always #5
	clk = ~clk;

wire [4:0] dd = 5'd27;
delay5 #(32) u2 (clk, 1'b1, a, a5);
delay5 #(32) u3 (clk, 1'b1, b, b5);
delay5 #(32) u4 (clk, 1'b1, c, c5);
delay5 #(64) u5 (clk, 1'b1, ad, ad5);
delay5 #(64) u6 (clk, 1'b1, bd, bd5);
delay5 #(64) u7 (clk, 1'b1, cd, cd5);
vtdl #(64,32) u8 (clk, 1'b1, dd, ad, adx);
vtdl #(64,32) u9 (clk, 1'b1, dd, bd, bdx);
vtdl #(64,32) u10 (clk, 1'b1, dd, cd, cdx);
vtdl #(4,32) u11 (clk, 1'b1, dd, rm, rms);
vtdl #(32,32) u12 (clk, 1'b1, dd, a, as);
vtdl #(32,32) u13 (clk, 1'b1, dd, b, bs);
vtdl #(32,32) u14 (clk, 1'b1, dd, c, cs);

always @(posedge clk)
if (rst) begin
	adr <= 0;
	cnt <= 0;
end else
begin
	cnt <= cnt + 1;
	if (cnt==54)
		cnt <= 0;
	if (cnt==4) 
	begin
		a <= mem[adr][31: 0];
		b <= mem[adr][63:32];
		c <= mem[adr][95:64];
		rm <= mem[adr][131:128];
		ad <= memd[adr][63: 0];
		bd <= memd[adr][127:64];
		cd <= memd[adr][191:128];
	end
	if (cnt==53)
	begin
		adr <= adr + 1;
		memo[adr] <= {rm,o,c,b,a};
//		memdo[adr] <= {od,cd17,bd17,ad17};
		//memdo[adr] <= {rmd,od,cdx,bdx,adx};
		if (adr==23999) begin
			$writememh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpFMA_tvo.txt", memo);
//			$writememh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpFMA_tvdo.txt", memdo);
			$finish;
		end
	end
end

fpFMAnr #(32) u1 (clk, 1'b1, 1'b0, rm[2:0], c, b, a, o);//, sign_exe, inf, overflow, underflow);
//fpFMAnr #(64) u15 (clk, 1'b1, 1'b0, rmd[2:0], ad, bd, cd, od);//, inf, overflow, underflow, inexact);

endmodule
