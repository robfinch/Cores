// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpAddsub_tb.v
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

module fpAddsub_tb();
reg rst;
reg clk;
reg [15:0] adr;
reg [103:0] mem [0:38000];
reg [103:0] memo [0:38000];
reg [199:0] memd [0:38000];
reg [199:0] memdo [0:38000];
reg [391:0] memq [0:38000];
reg [391:0] memqo [0:38000];
reg [31:0] a,b,a6,b6;
reg [63:0] ad, bd;
reg [127:0] aq, bq;
wire [127:0] oq;
wire [31:0] a5,b5;
wire [31:0] o;
wire [63:0] od;
reg [3:0] rm, op, rmq, opq, rmd, opd;
wire [3:0] rm5;
wire [3:0] op5;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	$readmemh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpAddsub_tvs.txt", mem);
	$readmemh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpAddsub_tvd.txt", memd);
	$readmemh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpAddsub_tvq.txt", memq);
	#20 rst = 1;
	#50 rst = 0;
end

always #5
	clk = ~clk;

reg [7:0] count;

always @(posedge clk)
if (rst) begin
	adr <= 0;
	count <= 0;
end
else
begin
	count <= count + 1;
	if (count==49)
		count <= 0;
	if (count==2) begin
		a <= mem[adr][31: 0];
		b <= mem[adr][63:32];
		rm <= mem[adr][99:96];
		op <= mem[adr][103:100];
		ad <= memq[adr][63: 0];
		bd <= memq[adr][127:64];
		rmd <= memq[adr][195:192];
		opd <= memq[adr][199:196];
		aq <= memq[adr][127: 0];
		bq <= memq[adr][255:128];
		rmq <= memq[adr][387:384];
		opq <= memq[adr][391:388];
	end
	if (count==48) begin
		memo[adr] <= {op,rm,o,b,a};
		memdo[adr] <= {opd,rmd,od,bd,ad};
		memqo[adr] <= {opq,rmq,oq,bq,aq};
		if (adr==8192) begin
			$writememh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpAddsub_tvso.txt", memo);
			$writememh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpAddsub_tvdo.txt", memdo);
			$writememh("d:/cores6/nvio/v2/rtl/fpUnit/test_bench/fpAddsub_tvqo.txt", memqo);
			$finish;
		end
		adr <= adr + 1;
	end
end

fpAddsubnr #(32) u1 (clk, 1'b1, rm[2:0], op[0], a, b, o);
fpAddsubnr #(64) u2 (clk, 1'b1, rmd[2:0], opd[0], ad, bd, od);
fpAddsubnr #(128) u3 (clk, 1'b1, rmq[2:0], opq[0], aq, bq, oq);

endmodule
