// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
//
`include "Gambit-config.sv"
`include "Gambit-defines.sv"

module programCounter(rst, clk,
	q1, q2, q1bx, insnx, freezepc, 
	phit, branchmiss, misspc, len1, len2, len3,
	jc, jcl, rts, br, wai, take_branch,
	btgt, pc, pcd, pc_chg, branch_pc, 
	ra, pc_override,
	debug_on);
parameter AMSB = 51;
parameter RSTPC = 52'hFFFFFFFFC0000;
parameter FSLOTS = `FSLOTS;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk;
input q2;
input q1;
input q1bx;
input [51:0] insnx [0:FSLOTS-1];
input freezepc;
input phit;
input branchmiss;
input [AMSB:0] misspc;
input [2:0] len1;
input [2:0] len2;
input [2:0] len3;
input [FSLOTS-1:0] jc;
input [FSLOTS-1:0] jcl;
input [FSLOTS-1:0] rts;
input [FSLOTS-1:0] br;
input [FSLOTS-1:0] wai;
input [FSLOTS-1:0] take_branch;
input [AMSB:0] btgt [0:FSLOTS-1];
output reg [AMSB:0] pc = RSTPC;
output reg [AMSB:0] pcd = RSTPC;
output pc_chg;
output reg [AMSB:0] branch_pc;
input [AMSB:0] ra;
output pc_override;
input debug_on;

assign pc_override = pc != branch_pc;
assign pc_chg = pc != pcd;

reg phitd;
reg [AMSB:0] next_pc;
reg [AMSB:0] branch_pcd1, branch_pcd2;
reg [AMSB:0] pcd1, pcd2;

always @(posedge clk)
	branch_pcd1 <= branch_pc;
always @(posedge clk)
	branch_pcd2 <= branch_pcd1;
always @(posedge clk)
	pcd1 <= pc;
always @(posedge clk)
	pcd2 <= pcd1;

always @*
if (rst) begin
	next_pc <= RSTPC;
end
else begin
	if (branchmiss)
		next_pc <= misspc;
	else begin
		if (!freezepc) begin
			begin
				next_pc <= pc + len2;
				if (br[0])
					next_pc <= btgt[0];
				if (q2 & br[1])
					next_pc <= btgt[1];
			end
		end
		if (pc_override)
			next_pc <= branch_pc;
	end
end


always @(posedge clk)
if (rst) begin
	pc <= RSTPC;
	pcd <= RSTPC;
	//pc_maskd <= 2'b11;
	phitd <= 1'b1;
end
else begin
	begin
		pcd <= pc;
		phitd <= phit;
	end
	if (branchmiss) begin
		$display("==============================");
		$display("==============================");
		$display("Branch miss: tgt=%h",misspc);
		$display("==============================");
		$display("==============================");
		pc <= misspc;
	end
	else begin
		if (!freezepc) begin
			begin
				if (q2)
					pc <= pc + len1 + len2;
				else if (q1 & ~q1bx)
					pc <= pc + len1;
//				if (((q1 & ~q1bx)|q2) & br[0])
//					pc <= btgt[0];
//				else if (q2 & br[1])
//					pc <= btgt[1];
			end
		end
		if (pc_override)
			pc <= branch_pc;
	end
//	if (commit2_v && commit2_tgt==`UO_PC)
//		pc <= commit2_bus;
//	else if (commit1_v && commit1_tgt==`UO_PC)
//		pc <= commit1_bus;
//	else if (commit0_v && commit0_tgt==`UO_PC)
//		pc <= commit0_bus;
	//pc <= next_pc;
end

always @*
if (rst) begin
	branch_pc <= RSTPC;
end
else begin
	branch_pc = pc;
	if (q1 & ~q1bx) begin
		if (wai[0])
			branch_pc = pc - 52'd1;
		else if (rts[0])
			branch_pc = ra;
		else if (take_branch[0]) begin
			$display("take branch 0");
			branch_pc = pc + {{35{insnx[0][25]}},insnx[0][25:9]} + 4'd2;
		end
		else if (jc[0])
			branch_pc[45:0] = insnx[0][51:6];
	end
	else if (q2) begin
		if (wai[0])
			branch_pc = pc - 52'd1;
		else if (rts[0])
			branch_pc = ra;
		else if (take_branch[0]) begin
			$display("take branch 0");
			branch_pc = pc + {{35{insnx[0][25]}},insnx[0][25:9]} + 4'd2;
		end
		else if (jc[0])
			branch_pc[45:0] = insnx[0][51:6];
		else if (rts[1])
			branch_pc = ra;
		else if (wai[1])
			branch_pc = pc - 52'd1 + len1;
		else if (take_branch[1]) begin
			$display("take branch 1");
			branch_pc = pc + {{35{insnx[1][25]}},insnx[1][25:9]} + 4'd2 + len1;
		end
		else if (jc[1])
			branch_pc[45:0] = insnx[1][51:6];
	end
end

endmodule
