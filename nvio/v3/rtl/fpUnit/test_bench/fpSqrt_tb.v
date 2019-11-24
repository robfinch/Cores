`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpSqrt_tb.v
//		- floating point square root test bench
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

module fpSqrt_tb();
reg rst;
reg clk;
reg clk4x;
reg [12:0] adr;
reg [63:0] mem [0:8191];
reg [63:0] memo [0:9000];
reg [127:0] memd [0:8191];
reg [127:0] memdo [0:9000];
reg [31:0] a,a6;
reg [63:0] ad;
wire [31:0] a5;
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
	$readmemh("c:/cores5/ft64/trunk/rtl/fpUnit/fpSqrt_tv.txt", mem);
	$readmemh("c:/cores5/ft64/trunk/rtl/fpUnit/fpSqrt_tvd.txt", memd);
	#20 rst = 1;
	#50 rst = 0;
end

always #8
	clk = ~clk;

always @(posedge clk)
if (rst) begin
	adr = 0;
	state <= 1;
end
else
begin
	ld <= 1'b0;
case(state)
4'd1:
	begin
		a <= mem[adr][31: 0];
		ad <= memd[adr][63:0];
		ld <= 1'b1;
		state <= 2;
	end
4'd2:
	if (done) begin
		memo[adr] <= {o,a};
		memdo[adr] <= {od,ad};
		adr <= adr + 1;
		if (adr==8191) begin
			$writememh("c:/cores5/ft64/trunk/rtl/fpUnit/fpSqrt_tvo.txt", memo);
			$writememh("c:/cores5/ft64/trunk/rtl/fpUnit/fpSqrt_tvdo.txt", memdo);
			$finish;
		end
		state <= 3;
	end
4'd3:	state <= 4;
4'd4:	state <= 5;
4'd5:	state <= 1;
endcase
end

fpSqrtnr #(32) u1 (rst, clk, 1'b1, ld, a, o, 3'b000);//, sign_exe, inf, overflow, underflow);
fpSqrtnr #(64) u2 (rst, clk, 1'b1, ld, ad, od, 3'b000, done);//, sign_exe, inf, overflow, underflow);

endmodule
