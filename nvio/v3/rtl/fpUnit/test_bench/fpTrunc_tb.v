`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpTrunc_tb.v
//		- floating point truncate test bench
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

module fpTrunc_tb();
reg rst;
reg clk;
reg [12:0] adr;
reg [63:0] mem [0:8191];
reg [63:0] memo [0:9000];
reg [127:0] memd [0:8191];
reg [127:0] memdo [0:9000];
reg [31:0] a,b,a6,b6;
reg [63:0] ad,bd;
wire [31:0] a5,b5;
wire [31:0] o;
wire [63:0] od;
reg ld;
wire done = 1'b1;
reg [3:0] state;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 13'd0;
	//$readmemh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpTrunc_tv.txt", mem);
	$readmemh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpTrunc_tvd.txt", memd);
	#20 rst = 1'd1;
	#50 rst = 1'd0;
end

always #10
	clk = ~clk;

always @(posedge clk)
if (rst) begin
	adr = 13'd0;
	state <= 4'd4;
end
else
begin
	ld <= 1'b0;
case(state)
4'd1:
	begin
		a <= mem[adr][31: 0];
		b <= mem[adr][63:32];
		ad <= memd[adr][63:0];
		bd <= memd[adr][127:64];
		ld <= 1'b1;
		state <= 4'd2;
	end
4'd2:
		state <= 4'd3;
4'd3:
	if (done) begin
		memo[adr] <= {o,a};
		memdo[adr] <= {od,ad};
		adr <= adr + 4'd1;
		if (adr==13'd8191) begin
//			$writememh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpTrunc_tvo.txt", memo);
			$writememh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpTrunc_tvdo.txt", memdo);
			$finish;
		end
		state <= 4'd4;
	end
4'd4:	state <= 4'd5;
4'd5:	state <= 1;
endcase
end

fpTrunc #(64) u1 (clk, 1'b1, ad, od);

endmodule
