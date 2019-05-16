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
reg [12:0] adr;
reg [95:0] mem [0:8191];
reg [95:0] memo [0:9000];
reg [191:0] memd [0:8191];
reg [191:0] memdo [0:9000];
reg [31:0] a,b;
wire [31:0] a5,b5;
wire [31:0] o;
reg [63:0] ad,bd;
wire [63:0] ad5,bd5;
wire [63:0] od;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	$readmemh("c:/cores5/ft64/trunk/rtl/fpUnit/fpMul_tv.txt", mem);
	$readmemh("c:/cores5/ft64/trunk/rtl/fpUnit/fpMul_tvd.txt", memd);
	#20 rst = 1;
	#50 rst = 0;
end

always #5
	clk = ~clk;

delay5 #(32) u2 (clk, 1'b1, a, a5);
delay5 #(32) u3 (clk, 1'b1, b, b5);
delay5 #(64) u4 (clk, 1'b1, ad, ad5);
delay5 #(64) u5 (clk, 1'b1, bd, bd5);

always @(posedge clk)
if (rst)
	adr = 0;
else
begin
	adr <= adr + 1;
	a <= mem[adr][31: 0];
	b <= mem[adr][63:32];
	ad <= memd[adr][63: 0];
	bd <= memd[adr][127:64];
	if (adr > 5) begin
		memo[adr-6] <= {o,b5,a5};
		memdo[adr-6] <= {od,bd5,ad5};
	end
	if (adr==8191) begin
		$writememh("c:/cores5/ft64/trunk/rtl/fpUnit/fpMul_tvo.txt", memo);
		$writememh("c:/cores5/ft64/trunk/rtl/fpUnit/fpMul_tvdo.txt", memdo);
		$finish;
	end
end

fpMulnr #(32) u1 (clk, 1'b1, a, b, o, 3'b000);//, sign_exe, inf, overflow, underflow);
fpMulnr #(64) u6 (clk, 1'b1, ad, bd, od, 3'b000);//, sign_exe, inf, overflow, underflow);

endmodule
