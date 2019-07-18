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

module slotValid(rst, clk, branchmiss, phit, nextb, ip_mask, ip_maskd,
	ip_override, queuedCnt, lsm,
	slot_jc, slot_ret, take_branch, slotv, slotvd, debug_on);
parameter QSLOTS = `QSLOTS;
parameter VAL = 1'b1;
parameter INV = 1'b0;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk;
input branchmiss;
input nextb;
input [2:0] queuedCnt;
input [QSLOTS-1:0] lsm;
input [QSLOTS-1:0] slot_jc;
input [QSLOTS-1:0] slot_ret;
input [QSLOTS-1:0] take_branch;
input phit;
input ip_override;
input [QSLOTS-1:0] ip_mask;
input [QSLOTS-1:0] ip_maskd;
output reg [QSLOTS-1:0] slotv;
output reg [QSLOTS-1:0] slotvd;
input debug_on;

integer n;

wire [2:0] pat;
assign pat = /*{slotv[0],slotv[1],slotv[2]} &*/ {3{phit}} & ip_maskd;
reg nextb3;
reg stomp_next;		// stomp on next bundle
reg stomp_next2;
reg nextbd;

//delay1 #(1) ud1 (.clk(clk), .ce(1'b1), .i(stomp_next), .o(stomp_next));
always @(posedge clk)
if (rst)
	nextbd <= 1'b0;
else
	nextbd <= nextb;

always @(posedge clk)
if (rst) begin
	slotvd <= 3'b000;
	stomp_next2 <= FALSE;
end
else begin
	if (nextb) begin
		slotvd <= stomp_next ? 1'b0 : ip_mask;
		stomp_next2 <= stomp_next;
	end
	else if (branchmiss)
		slotvd <= 1'b0;
	else
		slotvd <= slotv;
end

always @*
if (rst)
	mark_all_invalid();
else begin
	stomp_next <= FALSE;
	slotv <= slotvd;
	case(slotvd)
	default:
		mark_all_invalid();
	3'b001:
		if (queuedCnt==3'd1 && !lsm[0]) begin
			mark_all_invalid();
			if ((slot_jc[0]|slot_ret[0]|take_branch[0]) & ip_override)
				stomp_next <= TRUE;
		end
	3'b010:
		if (queuedCnt==3'd1 && !lsm[1]) begin
			mark_all_invalid();
			if ((slot_jc[1]|slot_ret[1]|take_branch[1]) & ip_override)
				stomp_next <= TRUE;
		end
	3'b011:
		if (queuedCnt==3'd2 && !lsm[0] && !lsm[1]) begin
			mark_all_invalid();
			if ((slot_jc[0]|slot_ret[0]|take_branch[0]) & ip_override)
				stomp_next <= TRUE;
			else if ((slot_jc[1]|slot_ret[1]|take_branch[1]) & ip_override)
				stomp_next <= TRUE;
		end
		else if (queuedCnt==3'd1 && !lsm[0]) begin
			slotv[0] <= INV;
			slotv[1] <= VAL;
			slotv[2] <= INV;
			if ((slot_jc[0]|slot_ret[0]|take_branch[0]) & ip_override) begin
				mark_all_invalid();
				stomp_next <= TRUE;
			end
		end
	3'b100:
		if (queuedCnt==3'd1 && !lsm[2]) begin
			mark_all_invalid();
			if ((slot_jc[2]|slot_ret[2]|take_branch[2]) & ip_override)
				stomp_next <= TRUE;
		end
	3'b110:
		if (queuedCnt==3'd2 && !lsm[2] && !lsm[1]) begin
			mark_all_invalid();
			if ((slot_jc[1]|slot_ret[1]|take_branch[1]) & ip_override)
				stomp_next <= TRUE;
			else if ((slot_jc[2]|slot_ret[2]|take_branch[2]) & ip_override)
				stomp_next <= TRUE;
		end
		else if (queuedCnt==3'd1 && !lsm[1]) begin
			slotv[0] <= INV;
			slotv[1] <= INV;
			slotv[2] <= VAL;
			if ((slot_jc[1]|slot_ret[1]|take_branch[1]) & ip_override) begin
				mark_all_invalid();
				stomp_next <= TRUE;
			end
		end
	3'b111:
		if (queuedCnt==3'd3 && lsm==3'b000) begin
			mark_all_invalid();
			if ((slot_jc[0]|slot_ret[0]|take_branch[0]) & ip_override)
				stomp_next <= TRUE;
			else if ((slot_jc[1]|slot_ret[1]|take_branch[1]) & ip_override)
				stomp_next <= TRUE;
			else if ((slot_jc[2]|slot_ret[2]|take_branch[2]) & ip_override)
				stomp_next <= TRUE;
		end
		else if (queuedCnt==3'd2 && lsm[1:0]==2'b00) begin
			slotv[0] <= INV;
			slotv[1] <= INV;
			slotv[2] <= VAL;
			if ((slot_jc[0]|slot_ret[0]|take_branch[0]) & ip_override) begin
				mark_all_invalid();
				stomp_next <= TRUE;
			end
			else if ((slot_jc[1]|slot_ret[1]|take_branch[1]) & ip_override) begin
				mark_all_invalid();
				stomp_next <= TRUE;
			end
		end
		else if (queuedCnt==3'd1 && lsm[0]==1'b0) begin
			slotv[0] <= INV;
			slotv[1] <= VAL;
			slotv[2] <= VAL;
			if ((slot_jc[0]|slot_ret[0]|take_branch[0]) & ip_override) begin
				mark_all_invalid();
				stomp_next <= TRUE;
			end
		end
	endcase
end

task mark_all_valid;
begin
	for (n = 0; n < 3; n = n + 1)
		slotv[n] <= VAL;
end
endtask

task mark_all_invalid;
begin
	for (n = 0; n < 3; n = n + 1)
		slotv[n] <= INV;
end
endtask

endmodule
