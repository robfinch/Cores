// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpFMAUnit_tb.v
//		- floating point multiplier - adder unit test bench
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

`include "..\..\cpu\nvio-config.sv"
`include "..\fpConfig.sv"

module fpFMAUnit_tb();
reg rst;
reg clk;
reg [12:0] adr;
reg [127:0] mem [0:8191];
reg [127:0] memo [0:9000];
reg [319:0] memd [0:8191];
reg [319:0] memdo [0:9000];
reg [31:0] a,b,c;
wire [31:0] a5,b5,c5;
wire [31:0] o;
reg [79:0] ad,bd,cd;
wire [79:0] ad5,bd5,cd5,adx,bdx,cdx;
wire [83:0] od;
reg [4:0] cnt;
wire idle;
reg [`RBITS] tagi;
reg vi;
wire vo;
wire [`RBITS] tago;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	cnt = 0;
//	$readmemh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpFMA_tv.txt", mem);
	$readmemh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpFMAUnit_tv.txt", memd);
	#20 rst = 1;
	#50 rst = 0;
end

always #5
	clk = ~clk;

wire [4:0] dd = 5'd27;
delay5 #(32) u2 (clk, 1'b1, a, a5);
delay5 #(32) u3 (clk, 1'b1, b, b5);
delay5 #(32) u4 (clk, 1'b1, c, c5);
delay5 #(80) u5 (clk, 1'b1, ad, ad5);
delay5 #(80) u6 (clk, 1'b1, bd, bd5);
delay5 #(80) u7 (clk, 1'b1, cd, cd5);
vtdl #(80,32) u8 (clk, 1'b1, dd, ad, adx);
vtdl #(80,32) u9 (clk, 1'b1, dd, bd, bdx);
vtdl #(80,32) u10 (clk, 1'b1, dd, cd, cdx);

always @(posedge clk)
begin
	cnt <= cnt + 1;
	if (cnt==4)
		cnt <= 0;
end

always @(posedge clk)
if (rst)
	adr = 0;
else
begin
	if (idle) 
	begin
		ad <= memd[adr][79: 0];
		bd <= memd[adr][159:80];
		cd <= memd[adr][239:160];
		vi <= $urandom & 1'b1;
		tagi <= $urandom & 3'd7;
	end
	if (idle)
	begin
		adr <= adr + 1;
//		memo[adr] <= {o,c17,b17,a17};
//		memdo[adr] <= {od,cd17,bd17,ad17};
		memdo[adr] <= {od,cdx,bdx,adx};
		if (adr==8191) begin
			//$writememh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpFMA_tvo.txt", memo);
			$writememh("d:/cores6/nvio/v1/rtl/fpUnit/test_bench/fpFMAUnit_tvo.txt", memdo);
			$finish;
		end
		$display ("%c %d %h %h %h : %c %d %h #", vi ? "v" : "-", tagi, ad, bd, cd, 
			vo ? "v" : "-", tago, od[83:4]);
	end
end

//fpFMAnr #(32) u1 (clk, 1'b1, a, b, o, 3'b000);//, sign_exe, inf, overflow, underflow);
fpFMAUnit #(80) u11 (
	.rst(rst),
	.clk(clk),
	.ce(1'b1),
	.ld(idle),
	.instr(40'b0),
	.csr_i(32'd0),
	.rm(3'b000),
	.a({ad,4'h0}),
	.b({bd,4'h0}),
	.c({cd,4'h0}),
	.o(od),
	.v_i(vi),
	.v_o(vo),
	.tag_i(tagi),
	.tag_o(tago),
	.idle(idle)
);

endmodule
