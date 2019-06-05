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

module slot_valid(rst, clk, branchmiss, phit, nextb, ip_mask,
	canq1, canq2, canq3, 
	slot_jc, take_branch, slotv, slotvd, debug_on);
parameter VAL = 1'b1;
parameter INV = 1'b0;
input rst;
input clk;
input branchmiss;
input nextb;
input canq1;
input canq2;
input canq3;
input [2:0] slot_jc;
input [2:0] take_branch;
input phit;
input [2:0] ip_mask;
output reg [2:0] slotv;
output reg [2:0] slotvd;
input debug_on;

integer n;

wire [2:0] pat;
assign pat = /*{slotv[0],slotv[1],slotv[2]} &*/ {3{phit}} & ip_mask;

// Find first one
function [2:0] ffo;
input [2:0] i;
case(i)
3'b001: ffo <= 3'd2;
3'b010: ffo <= 3'd1;
3'b011:	ffo <= 3'd1;
3'b100: ffo <= 3'd0;
3'b101:	ffo <= 3'd0;
3'b110:	ffo <= 3'd0;
3'b111:	ffo <= 3'd0;
default:    ffo <= 3'd0;
endcase
endfunction

// Find last one
function [2:0] flo;
input [2:0] i;
case(i)
3'b001: flo <= 3'd2;
3'b010: flo <= 3'd1;
3'b011:	flo <= 3'd2;
3'b100: flo <= 3'd0;
3'b101:	flo <= 3'd2;
3'b110:	flo <= 3'd1;
3'b111:	flo <= 3'd2;
default:    flo <= 3'd0;
endcase
endfunction

// Find second one bit
function [2:0] fso;
input [2:0] i;
casez(i)
3'b011:  fso <= 3'd2;
3'b11?:  fso <= 3'd1;
3'b101:	 fso <= 3'd2;
default:    fso <= 3'd0;
endcase
endfunction

always @*
if (rst)
	mark_all_valid();
else begin
	if (phit & nextb)
		slotvd <= slotv;
	if (branchmiss)
		mark_all_invalid();
	else begin
		if (pat==3'b000 && phit)
			slotv <= ip_mask;
		case(pat)
		3'b000:	;
		3'b001:
			if (canq1) begin
				if (slot_jc[2]|take_branch[2])
					mark_all_invalid();
				else
					mark_all_valid();
			end
		3'b010:
			if (canq1) begin
				if (slot_jc[1]|take_branch[1])
					mark_all_invalid();
				else
					mark_all_valid();
			end
		3'b100:
			if (canq1) begin
				if (slot_jc[0]|take_branch[0])
					mark_all_invalid();
				else
					mark_all_valid();
			end
		3'b011:
			if (canq2 & !debug_on && `WAYS > 1) begin
				if (slot_jc[1]|take_branch[1])
					mark_all_invalid();
				else if (slot_jc[2]|take_branch[2])
					mark_all_invalid();
				else
					mark_all_valid();
			end
			else if (canq1) begin
				slotv[1] <= INV;
				if (slot_jc[1]|take_branch[1])
					mark_all_invalid();
			end
		3'b101:
			if (canq2 & !debug_on && `WAYS > 1) begin
				if (slot_jc[0]|take_branch[0])
					mark_all_invalid();
				else if (slot_jc[1]|take_branch[1])
					mark_all_invalid();
				else
					mark_all_valid();
			end
			else if (canq1) begin
				slotv[0] <= INV;
				if (slot_jc[0]|take_branch[0])
					mark_all_invalid();
			end
		3'b110:
			if (canq2 & !debug_on && `WAYS > 1) begin
				if (slot_jc[0]|take_branch[0])
					mark_all_invalid();
				else if (slot_jc[1]|take_branch[1])
					mark_all_invalid();
				else
					mark_all_valid();
			end
			else if (canq1) begin
				slotv[0] <= INV;
				if (slot_jc[0]|take_branch[0])
					mark_all_invalid();
			end
		3'b111:
			if (canq3 & !debug_on && `WAYS > 2)
				if (slot_jc[0]|take_branch[0])
					mark_all_invalid();
				else if (slot_jc[1]|take_branch[1])
					mark_all_invalid();
				else if (slot_jc[2]|take_branch[2])
					mark_all_invalid();
				else
					mark_all_valid();
			else if (canq2 & !debug_on && `WAYS > 1) begin
				slotv[0] <= INV;
				slotv[1] <= INV;
				if (slot_jc[0]|take_branch[0])
					mark_all_invalid();
				else if (slot_jc[1]|take_branch[1])
					mark_all_invalid();
			end
			else if (canq1) begin
				slotv[0] <= INV;
				if (slot_jc[0]|take_branch[0])
					mark_all_invalid();
			end
		endcase
	end
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
