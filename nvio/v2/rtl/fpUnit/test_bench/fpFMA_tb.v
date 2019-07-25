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
reg [131:0] mems [0:24000];
reg [131:0] memso [0:24000];
reg [259:0] memd [0:24000];
reg [259:0] memdo [0:24000];
reg [515:0] memq [0:24000];
reg [515:0] memqo [0:24000];
reg [31:0] a,b,c;
reg [3:0] rm, rmd, rmq;
wire [31:0] o;
reg [63:0] ad,bd,cd;
wire [63:0] od;
reg [127:0] aq,bq,cq;
wire [127:0] oq;
reg [7:0] cnt;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	cnt = 0;
	$readmemh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpFMA_tvs.txt", mems);
	$readmemh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpFMA_tvd.txt", memd);
	$readmemh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpFMA_tvq.txt", memq);
	#20 rst = 1;
	#50 rst = 0;
end

always #5
	clk = ~clk;

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
		a <= mems[adr][31: 0];
		b <= mems[adr][63:32];
		c <= mems[adr][95:64];
		rm <= mems[adr][131:128];
		ad <= memd[adr][63: 0];
		bd <= memd[adr][127:64];
		cd <= memd[adr][191:128];
		rmd <= memd[adr][259:256];
		aq <= memq[adr][127: 0];
		bq <= memq[adr][255:128];
		cq <= memq[adr][383:256];
		rmq <= memq[adr][515:512];
	end
	if (cnt==53)
	begin
		adr <= adr + 1;
		memso[adr] <= {rm,o,c,b,a};
		memdo[adr] <= {rmd,od,cd,bd,ad};
		memqo[adr] <= {rmq,oq,cq,bq,aq};
		//memdo[adr] <= {rmd,od,cdx,bdx,adx};
		if (adr==8191) begin
			$writememh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpFMA_tvso.txt", memso);
			$writememh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpFMA_tvdo.txt", memdo);
			$writememh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpFMA_tvqo.txt", memqo);
			$finish;
		end
	end
end

fpFMAnr #(32) u1 (clk, 1'b1, 1'b0, rm[2:0], c, b, a, o);//, sign_exe, inf, overflow, underflow);
fpFMAnr #(64) u16 (clk, 1'b1, 1'b0, rmd[2:0], ad, bd, cd, od);//, sign_exe, inf, overflow, underflow);
fpFMAnr #(128) u17 (clk, 1'b1, 1'b0, rmq[2:0], cq, bq, aq, oq);//, sign_exe, inf, overflow, underflow);
//fpFMAnr #(64) u15 (clk, 1'b1, 1'b0, rmd[2:0], ad, bd, cd, od);//, inf, overflow, underflow, inexact);

endmodule
