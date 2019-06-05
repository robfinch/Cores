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
`include "rtfItanium-config.sv"

module slot_valid(rst, clk, branchmiss, phit, nextb, ip_mask, ip_maskd,
	ip_override, next_ip_mask, queuedCnt, new_ip_mask,
	slot_jc, take_branch, slotv, slotvd, debug_on);
parameter VAL = 1'b1;
parameter INV = 1'b0;
input rst;
input clk;
input branchmiss;
input nextb;
input [2:0] queuedCnt;
input [2:0] slot_jc;
input [2:0] take_branch;
input phit;
input ip_override;
input [2:0] next_ip_mask;
input [2:0] ip_mask;
input [2:0] ip_maskd;
input new_ip_mask;
output reg [2:0] slotv;
output reg [2:0] slotvd;
input debug_on;

integer n;

wire [2:0] pat;
assign pat = /*{slotv[0],slotv[1],slotv[2]} &*/ {3{phit}} & ip_maskd;
reg nextb3;
delay1 #(1) ud1 (.clk(clk), .ce(1'b1), .i(nextb), .o(nextb3));

always @(posedge clk)
if (rst)
	slotvd <= 3'b000;
else begin
	if (nextb)
		slotvd <= ip_mask;
	else
		slotvd <= slotv;
end

always @*
if (rst)
	mark_all_invalid();
else begin
	slotv <= slotvd;
	case(ip_maskd)
	default:
		mark_all_invalid();
	3'b001:
		if (queuedCnt==3'd1)
			mark_all_invalid();
	3'b010:
		if (queuedCnt==3'd1)
			mark_all_invalid();
	3'b011:
		if (queuedCnt==3'd2)
			mark_all_invalid();
		else if (queuedCnt==3'd1) begin
			slotv[0] <= INV;
			slotv[1] <= VAL;
			slotv[2] <= INV;
			if ((slot_jc[0]|take_branch[0]) & ip_override)
				mark_all_invalid();
		end
	3'b100:
		if (queuedCnt==3'd1)
			mark_all_invalid();
	3'b110:
		if (queuedCnt==3'd2)
			mark_all_invalid();
		else if (queuedCnt==3'd1) begin
			slotv[0] <= INV;
			slotv[1] <= INV;
			slotv[2] <= VAL;
			if ((slot_jc[1]|take_branch[1]) & ip_override)
				mark_all_invalid();
		end
	3'b111:
		if (queuedCnt==3'd3)
			mark_all_invalid();
		else if (queuedCnt==3'd2) begin
			slotv[0] <= INV;
			slotv[1] <= INV;
			slotv[2] <= VAL;
			if ((slot_jc[0]|take_branch[0]) & ip_override)
				mark_all_invalid();
			else if ((slot_jc[1]|take_branch[1]) & ip_override)
				mark_all_invalid();
		end
		else if (queuedCnt==3'd1) begin
			slotv[0] <= INV;
			slotv[1] <= VAL;
			slotv[2] <= VAL;
			if ((slot_jc[0]|take_branch[0]) & ip_override)
				mark_all_invalid();
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
