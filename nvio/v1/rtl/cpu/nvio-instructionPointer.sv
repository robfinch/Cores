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
`include "nvio-config.sv"
`include "nvio-defines.sv"

module instructionPointer(rst, clk, queuedCnt, insnx, freezeip, 
	next_bundle, phit, branchmiss, missip, ip_mask, ip_maskd,
	slotv, slotvd, slot_jc, slot_ret, slot_br, take_branch, btgt, ip, ipd, branch_ip, 
	ra, ip_override,
	debug_on);
parameter AMSB = 79;
parameter RSTIP = 80'hFFFFFFFFFFFFFFFC0100;
parameter QSLOTS = `QSLOTS;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk;
input [2:0] queuedCnt;
input [39:0] insnx [0:QSLOTS-1];
input freezeip;
input next_bundle;
input phit;
input branchmiss;
input [AMSB:0] missip;
input [QSLOTS-1:0] ip_mask;
output reg [QSLOTS-1:0] ip_maskd;
input [QSLOTS-1:0] slotv;
input [QSLOTS-1:0] slotvd;
input [QSLOTS-1:0] slot_jc;
input [QSLOTS-1:0] slot_ret;
input [QSLOTS-1:0] slot_br;
input [QSLOTS-1:0] take_branch;
input [AMSB:0] btgt [0:QSLOTS-1];
output reg [AMSB:0] ip;
output reg [AMSB:0] ipd;
output reg [AMSB:0] branch_ip;
input [AMSB:0] ra;
output ip_override;
input debug_on;

assign ip_override = ip != branch_ip;

reg phitd;
reg [AMSB:0] next_ip;

always @*
if (rst) begin
	next_ip <= RSTIP;
end
else begin
	if (branchmiss)
		next_ip <= {missip[AMSB:2],missip[3:2]};
	else begin
		if (!freezeip && next_bundle) begin
			begin
				next_ip <= {ip[AMSB:4] + 2'd1,4'h0};
				if (slot_br[0])
					next_ip <= btgt[0];
				if (slot_br[1])
					next_ip <= btgt[1];
				if (slot_br[2])
					next_ip <= btgt[2];
			end
		end
		if (ip_override)
			next_ip <= branch_ip;
	end
end


always @(posedge clk)
if (rst) begin
	ip <= RSTIP;
	ipd <= RSTIP;
	ip_maskd <= 3'b111;
	phitd <= 1'b1;
end
else begin
	if (next_bundle) begin
		ipd <= ip;
		ip_maskd <= ip_mask;
		phitd <= phit;
	end
	if (branchmiss) begin
		$display("==============================");
		$display("==============================");
		$display("Branch miss: tgt=%h",{missip[AMSB:2],missip[3:2]});
		$display("==============================");
		$display("==============================");
		ip <= {missip[AMSB:2],missip[3:2]};
	end
	else begin
		if (!freezeip && next_bundle) begin
			begin
				ip <= {ip[AMSB:4] + 2'd1,4'h0};
				if (slot_br[0])
					ip <= btgt[0];
				if (slot_br[1])
					ip <= btgt[1];
				if (slot_br[2])
					ip <= btgt[2];
			end
		end
		if (ip_override)
			ip <= branch_ip;
	end
	//ip <= next_ip;
end

always @*
if (rst) begin
	branch_ip <= RSTIP;
end
else begin
	branch_ip <= ip;
	case(slotvd)
	3'b001:
		if (queuedCnt==3'd1) begin
			if (slot_ret[0])
				branch_ip <= ra;
			else if (take_branch[0])
				branch_ip <= {ipd[79:4] + {{60{insnx[0][39]}},insnx[0][39:24]},insnx[0][23:22],insnx[0][23:22]};
			else if (slot_jc[0])
				branch_ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
		end
	3'b010:
		if (queuedCnt==3'd1) begin
			if (slot_ret[1])
				branch_ip <= ra;
			else if (take_branch[1])
				branch_ip <= {ipd[79:4] + {{60{insnx[1][39]}},insnx[1][39:24]},insnx[1][23:22],insnx[1][23:22]};
			else if (slot_jc[1])
				branch_ip[37:0] <= {insnx[1][39:10],insnx[1][5:0],insnx[1][1:0]};
		end
	3'b011:
		if (queuedCnt==3'd2) begin
			if (slot_ret[0])
				branch_ip <= ra;
			else if (slot_jc[0])
				branch_ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			else if (take_branch[0])
				branch_ip <= {ipd[79:4] + {{60{insnx[0][39]}},insnx[0][39:24]},insnx[0][23:22],insnx[0][23:22]};
			else if (slot_ret[1])
				branch_ip <= ra;
			else if (slot_jc[1])
				branch_ip[37:0] <= {insnx[1][39:10],insnx[1][5:0],insnx[1][1:0]};
			else if (take_branch[1])
				branch_ip <= {ipd[79:4] + {{60{insnx[1][39]}},insnx[1][39:24]},insnx[1][23:22],insnx[1][23:22]};
		end
		else if (queuedCnt==3'd1) begin
			if (slot_ret[0])
				branch_ip <= ra;
			else if (slot_jc[0])
				branch_ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			else if (take_branch[0])
				branch_ip <= {ipd[79:4] + {{60{insnx[0][39]}},insnx[0][39:24]},insnx[0][23:22],insnx[0][23:22]};
//			else
//				branch_ip[3:0] <= 4'h5;
		end
	3'b100:
		if (queuedCnt==3'd1) begin
			if (slot_ret[2])
				branch_ip <= ra;
			else if (take_branch[2])
				branch_ip <= {ipd[79:4] + {{60{insnx[2][39]}},insnx[2][39:24]},insnx[2][23:22],insnx[2][23:22]};
			else if (slot_jc[2])
				branch_ip[37:0] <= {insnx[2][39:10],insnx[2][5:0],insnx[2][1:0]};
		end
	3'b110:
		if (queuedCnt==3'd2) begin
			if (slot_ret[1])
				branch_ip <= ra;
			else if (slot_jc[1])
				branch_ip[37:0] <= {insnx[1][39:10],insnx[1][5:0],insnx[1][1:0]};
			else if (take_branch[1])
				branch_ip <= {ipd[79:4] + {{60{insnx[1][39]}},insnx[1][39:24]},insnx[1][23:22],insnx[1][23:22]};
			else if (slot_ret[2])
				branch_ip <= ra;
			else if (slot_jc[2])
				branch_ip[37:0] <= {insnx[2][39:10],insnx[2][5:0],insnx[2][1:0]};
			else if (take_branch[2])
				branch_ip <= {ipd[79:4] + {{60{insnx[2][39]}},insnx[2][39:24]},insnx[2][23:22],insnx[2][23:22]};
		end
		else if (queuedCnt==3'd1) begin
			if (slot_ret[1])
				branch_ip <= ra;
			else if (slot_jc[1])
				branch_ip[37:0] <= {insnx[1][39:10],insnx[1][5:0],insnx[1][1:0]};
			else if (take_branch[1])
				branch_ip <= {ipd[79:4] + {{60{insnx[1][39]}},insnx[1][39:24]},insnx[1][23:22],insnx[1][23:22]};
//			else
//				branch_ip[3:0] <= 4'hA;
		end
	3'b111:
		if (queuedCnt==3'd3) begin
			if (slot_ret[0])
				branch_ip <= ra;
			else if (slot_jc[0])
				branch_ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			else if (take_branch[0])
				branch_ip <= {ipd[79:4] + {{60{insnx[0][39]}},insnx[0][39:24]},insnx[0][23:22],insnx[0][23:22]};
			else if (slot_ret[1])
				branch_ip <= ra;
			else if (slot_jc[1])
				branch_ip[37:0] <= {insnx[1][39:10],insnx[1][5:0],insnx[1][1:0]};
			else if (take_branch[1])
				branch_ip <= {ipd[79:4] + {{60{insnx[1][39]}},insnx[1][39:24]},insnx[1][23:22],insnx[1][23:22]};
			else if (slot_ret[2])
				branch_ip <= ra;
			else if (slot_jc[2])
				branch_ip[37:0] <= {insnx[2][39:10],insnx[2][5:0],insnx[2][1:0]};
			else if (take_branch[2])
				branch_ip <= {ipd[79:4] + {{60{insnx[2][39]}},insnx[2][39:24]},insnx[2][23:22],insnx[2][23:22]};
		end
		else if (queuedCnt==3'd2) begin
			if (slot_ret[0])
				branch_ip <= ra;
			else if (slot_jc[0])
				branch_ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			else if (take_branch[0])
				branch_ip <= {ipd[79:4] + {{60{insnx[0][39]}},insnx[0][39:24]},insnx[0][23:22],insnx[0][23:22]};
			else if (slot_ret[1])
				branch_ip <= ra;
			else if (slot_jc[1])
				branch_ip[37:0] <= {insnx[1][39:10],insnx[1][5:0],insnx[1][1:0]};
			else if (take_branch[1])
				branch_ip <= {ipd[79:4] + {{60{insnx[1][39]}},insnx[1][39:24]},insnx[1][23:22],insnx[1][23:22]};
//			else
//				branch_ip[3:0] <= 4'hA;
		end
		else if (queuedCnt==3'd1) begin
			if (slot_ret[0])
				branch_ip <= ra;
			else if (slot_jc[0])
				branch_ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			else if (take_branch[0])
				branch_ip <= {ipd[79:4] + {{60{insnx[0][39]}},insnx[0][39:24]},insnx[0][23:22],insnx[0][23:22]};
//			else
//				branch_ip[3:0] <= 4'h5;
		end
	default:	;
	endcase
end

endmodule
