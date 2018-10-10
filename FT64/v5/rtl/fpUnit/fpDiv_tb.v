`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpDiv_tb.v
//		- floating point divider test bench
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

module fpDiv_tb();
reg rst;
reg clk;
reg clk4x;
reg [12:0] adr;
reg [95:0] mem [0:8191];
reg [95:0] memo [0:9000];
reg [191:0] memd [0:8191];
reg [191:0] memdo [0:9000];
reg [31:0] a,b,a6,b6;
reg [63:0] ad,bd;
wire [31:0] a5,b5;
wire [31:0] o;
wire [63:0] od;
reg ld;
wire done;
reg [3:0] state;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	clk4x = 0;
	adr = 0;
	$readmemh("d:/cores5/ft64/v5/rtl/fpUnit/fpDiv_tv.txt", mem);
	$readmemh("d:/cores5/ft64/v5/rtl/fpUnit/fpDiv_tvd.txt", memd);
	#20 rst = 1;
	#50 rst = 0;
end

always #2
	clk4x = ~clk4x;
always #8
	clk = ~clk;

always @(posedge clk)
if (rst) begin
	adr = 0;
	state <= 3;
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
		state <= 2;
	end
4'd2:
	if (done)
		state <= 4'd3;
4'd3:
	begin
		memo[adr] <= {o,b,a};
		memdo[adr] <= {od,bd,ad};
		adr <= adr + 1;
		if (adr==8191) begin
			$writememh("d:/cores5/ft64/v5/rtl/fpUnit/fpDiv_tvo.txt", memo);
			$writememh("d:/cores5/ft64/v5/rtl/fpUnit/fpDiv_tvdo.txt", memdo);
			$finish;
		end
		state <= 4;
	end
4'd4:	state <= 5;
4'd5:	state <= 1;
endcase
end

fpDivnr #(32) u1 (rst, clk, clk4x, 1'b1, ld, 1'b0, a, b, o, 3'b000);//, sign_exe, inf, overflow, underflow);
fpDivnr #(64) u2 (rst, clk, clk4x, 1'b1, ld, 1'b0, ad, bd, od, 3'b000, done);//, sign_exe, inf, overflow, underflow);

endmodule
