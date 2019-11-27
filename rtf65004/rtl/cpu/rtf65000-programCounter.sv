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
`include "rtf65000-config.sv"
`include "rtf65000-defines.sv"

module programCounter(rst, clk, q1, q2, insnx, freezepc, 
	phit, branchmiss, misspc, pc_mask, pc_maskd, len1, len2, len3,
	slotv, slotvd, jc, rts, br, take_branch, btgt, pc, pcd, branch_pc, 
	ra, pc_override,
	debug_on);
parameter AMSB = 15;
parameter RSTIP = 16'hFFFC;
parameter FSLOTS = `FSLOTS;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk;
input q2;
input q1;
input [23:0] insnx [0:FSLOTS-1];
input freezepc;
input phit;
input branchmiss;
input [AMSB:0] misspc;
input [FSLOTS-1:0] jc;
input [FSLOTS-1:0] rts;
input [FSLOTS-1:0] br;
input [FSLOTS-1:0] take_branch;
input [AMSB:0] btgt [0:FSLOTS-1];
output reg [AMSB:0] pc;
output reg [AMSB:0] branch_pc;
input [AMSB:0] ra;
output pc_override;
input debug_on;

assign pc_override = pc != branch_pc;

reg phitd;
reg [AMSB:0] next_pc;

always @*
if (rst) begin
	next_pc <= RSTIP;
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
	pc <= RSTIP;
	pcd <= RSTIP;
	pc_maskd <= 2'b11;
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
				else if (q1)
					pc <= pc + len1;
				if (br[0])
					pc <= btgt[0];
				if (q2 & br[1])
					pc <= btgt[1];
			end
		end
		if (pc_override)
			pc <= branch_pc;
	end
	//pc <= next_pc;
end

always @*
if (rst) begin
	branch_pc <= RSTIP;
end
else begin
	branch_pc <= pc;
	if (q2) begin
		if (rts[0])
			branch_pc <= ra;
		else if (take_branch[0])
			branch_pc <= pc + {{8{insnx[0][15]}},insnx[0][15:8]} + 4'd2;
		else if (jc[0])
			branch_pc <= insnx[0][23:8];
	end
	else if (q1) begin
		if (rts[0])
			branch_pc <= ra;
		else if (take_branch[0])
			branch_pc <= pc + {{8{insnx[0][15]}},insnx[0][15:8]} + 4'd2;
		else if (jc[0])
			branch_pc <= insnx[0][23:8];
		else if (rts[1])
			branch_pc <= ra;
		else if (take_branch[1])
			branch_pc <= pc + {{8{insnx[1][15]}},insnx[1][15:8]} + len1 + 4'd2;
		else if (jc[1])
			branch_pc <= insnx[1][23:8];
	end
end

endmodule
