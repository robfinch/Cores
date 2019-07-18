`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpMul_tb.v
//		- floating point multiplier test bench
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

module fpMul_tb();
reg rst;
reg clk;
reg [15:0] adr;
reg [99:0] mem [0:38000];
reg [99:0] memo [0:38000];
reg [191:0] memd [0:38000];
reg [191:0] memdo [0:38000];
reg [31:0] a,b;
wire [31:0] a5,b5;
wire [31:0] o;
reg [63:0] ad,bd;
wire [63:0] ad5,bd5;
wire [63:0] od;
reg [3:0] rm;
wire [3:0] rm5;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	$readmemh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpMul_tv.txt", mem);
	//$readmemh("c:/cores5/ft64/trunk/rtl/fpUnit/fpMul_tvd.txt", memd);
	#20 rst = 1;
	#50 rst = 0;
end

always #5
	clk = ~clk;

delay5 #(32) u2 (clk, 1'b1, a, a5);
delay5 #(32) u3 (clk, 1'b1, b, b5);
delay5 #(4)  u7 (clk, 1'b1, rm, rm5);
delay5 #(64) u4 (clk, 1'b1, ad, ad5);
delay5 #(64) u5 (clk, 1'b1, bd, bd5);

reg [7:0] count;
always @(posedge clk)
if (rst) begin
	adr <= 0;
	count <= 0;
end
else
begin
	count <= count + 1;
	if (count > 48)
		count <= 1'd1;
	if (count==2) begin	
		a <= mem[adr][31: 0];
		b <= mem[adr][63:32];
		rm <= mem[adr][99:96];
		//ad <= memd[adr][63: 0];
		//bd <= memd[adr][127:64];
	end
	if (count==47) begin
			memo[adr] <= {rm,o,b,a};
//			memdo[adr] <= {od,bd5,ad5};
		if (adr==8191) begin
			$writememh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpMul_tvo.txt", memo);
			//$writememh("c:/cores5/ft64/trunk/rtl/fpUnit/fpMul_tvdo.txt", memdo);
			$finish;
		end
		adr <= adr + 1;
	end
end

fpMulnr #(32) u1 (clk, 1'b1, a, b, o, rm);//, sign_exe, inf, overflow, underflow);
fpMulnr #(64) u6 (clk, 1'b1, ad, bd, od, 3'b000);//, sign_exe, inf, overflow, underflow);

endmodule
