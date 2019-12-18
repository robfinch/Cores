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

module slotValid(rst, clk, branchmiss, phit, nextb, pc_mask, pc_maskd,
	pc_override, q1, q2,
	slot_jc, slot_rts, take_branch, slotv, slotvd, debug_on);
parameter FSLOTS = `FSLOTS;
parameter VAL = 1'b1;
parameter INV = 1'b0;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk;
input branchmiss;
input nextb;
input q1;
input q2;
input [FSLOTS-1:0] slot_jc;
input [FSLOTS-1:0] slot_rts;
input [FSLOTS-1:0] take_branch;
input phit;
input pc_override;
input [FSLOTS-1:0] pc_mask;
input [FSLOTS-1:0] pc_maskd;
output reg [FSLOTS-1:0] slotv;
output reg [FSLOTS-1:0] slotvd;
input debug_on;

integer n;

wire [2:0] pat;
assign pat = /*{slotv[0],slotv[1],slotv[2]} &*/ {3{phit}} & pc_maskd;
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
	slotvd <= 2'b00;
	stomp_next2 <= FALSE;
end
else begin
	if (nextb) begin
		slotvd <= stomp_next ? 1'b0 : pc_mask;
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
	2'b01:
		if (q1) begin
			mark_all_invalid();
			if ((slot_jc[0]|slot_rts[0]|take_branch[0]) & pc_override)
				stomp_next <= TRUE;
		end
	2'b10:
		if (q1) begin
			mark_all_invalid();
			if ((slot_jc[1]|slot_rts[1]|take_branch[1]) & pc_override)
				stomp_next <= TRUE;
		end
	2'b11:
		if (q2) begin
			mark_all_invalid();
			if ((slot_jc[0]|slot_rts[0]|take_branch[0]) & pc_override)
				stomp_next <= TRUE;
			else if ((slot_jc[1]|slot_rts[1]|take_branch[1]) & pc_override)
				stomp_next <= TRUE;
		end
		else if (q1) begin
			slotv[0] <= INV;
			slotv[1] <= VAL;
			if ((slot_jc[0]|slot_rts[0]|take_branch[0]) & pc_override) begin
				mark_all_invalid();
				stomp_next <= TRUE;
			end
		end
	endcase
end

task mark_all_valid;
begin
	for (n = 0; n < FSLOTS; n = n + 1)
		slotv[n] <= VAL;
end
endtask

task mark_all_invalid;
begin
	for (n = 0; n < FSLOTS; n = n + 1)
		slotv[n] <= INV;
end
endtask

endmodule
