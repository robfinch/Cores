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
reg [12:0] adr;
reg [127:0] mem [0:8191];
reg [127:0] memo [0:9000];
reg [255:0] memd [0:8191];
reg [255:0] memdo [0:9000];
reg [31:0] a,b,c;
wire [31:0] a5,b5,c5;
wire [31:0] o;
reg [63:0] ad,bd,cd;
wire [63:0] ad5,bd5,cd5,ad17,bd17,cd17;
wire [63:0] od;
reg [4:0] cnt;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	cnt = 0;
//	$readmemh("d:/cores6/rtfItanium/v1/rtl/fpUnit/test_bench/fpFMA_tv.txt", mem);
	$readmemh("d:/cores6/rtfItanium/v1/rtl/fpUnit/test_bench/fpFMA_tvd.txt", memd);
	#20 rst = 1;
	#50 rst = 0;
end

always #5
	clk = ~clk;

delay5 #(32) u2 (clk, 1'b1, a, a5);
delay5 #(32) u3 (clk, 1'b1, b, b5);
delay5 #(32) u4 (clk, 1'b1, c, c5);
delay5 #(64) u5 (clk, 1'b1, ad, ad5);
delay5 #(64) u6 (clk, 1'b1, bd, bd5);
delay5 #(64) u7 (clk, 1'b1, cd, cd5);
vtdl #(64,32) u8 (clk, 1'b1, 5'd16, ad, ad17);
vtdl #(64,32) u9 (clk, 1'b1, 5'd16, bd, bd17);
vtdl #(64,32) u10 (clk, 1'b1, 5'd16, cd, cd17);

always @(posedge clk)
	cnt <= cnt + 1;

always @(posedge clk)
if (rst)
	adr = 0;
else
begin
	if (cnt==1) 
	begin
		a <= mem[adr][31: 0];
		b <= mem[adr][63:32];
		c <= mem[adr][95:64];
		ad <= memd[adr][63: 0];
		bd <= memd[adr][127:64];
		cd <= memd[adr][191:128];
	end
	if (cnt==31) 
	begin
		adr <= adr + 1;
//		memo[adr] <= {o,c17,b17,a17};
		memdo[adr] <= {od,cd,bd,ad};
		if (adr==8191) begin
			//$writememh("d:/cores6/rtfItanium/v1/rtl/fpUnit/test_bench/fpFMA_tvo.txt", memo);
			$writememh("d:/cores6/rtfItanium/v1/rtl/fpUnit/test_bench/fpFMA_tvdo.txt", memdo);
			$finish;
		end
	end
end

//fpFMAnr #(32) u1 (clk, 1'b1, a, b, o, 3'b000);//, sign_exe, inf, overflow, underflow);
fpFMAnr #(64) u11 (clk, 1'b1, 1'b0, 3'b000, ad, bd, cd, od);//, sign_exe, inf, overflow, underflow);

endmodule
