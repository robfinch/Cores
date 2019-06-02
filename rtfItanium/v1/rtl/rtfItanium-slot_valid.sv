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

module slot_valid(rst, clk, branchmiss, phit, ip_mask,
	canq1, canq2, canq3, 
	slot_jc, take_branch, slotv, debug_on);
parameter VAL = 1'b1;
parameter INV = 1'b0;
input rst;
input clk;
input branchmiss;
input canq1;
input canq2;
input canq3;
input [2:0] slot_jc;
input [2:0] take_branch;
input phit;
input [2:0] ip_mask;
output reg [2:0] slotv;
input debug_on;

integer n;

wire [2:0] pat;
assign pat = slotv & {3{phit}} & {ip_mask[0],ip_mask[1],ip_mask[2]};

// Find last one
function [2:0] flo;
input [2:0] i;
case(i)
3'b001: flo <= 3'd0;
3'b010: flo <= 3'd1;
3'b011:	flo <= 3'd0;
3'b100: flo <= 3'd2;
3'b101:	flo <= 3'd0;
3'b110:	flo <= 3'd1;
3'b111:	flo <= 3'd0;
default:    flo <= 3'd0;
endcase
endfunction

// Find second one bit
function [2:0] fso;
input [2:0] i;
casez(i)
3'b11?:  fso <= 3'd1;
3'b011:  fso <= 3'd2;
3'b001:  fso <= 3'd0;
3'b101:	 fso <= 3'd2;
default:    fso <= 3'd0;
endcase
endfunction

always @(posedge clk)
if (rst)
	mark_all_valid();
else begin
	if (branchmiss)
		mark_all_valid();
	else begin
		// Setting slot valid
		case(pat)
		3'b000:	;
		3'b001,
		3'b010,
		3'b100:
			if (canq1)
				mark_all_valid();
		3'b011,
		3'b101,
		3'b110:
			if (canq2 & !debug_on && `WAYS > 1)
				mark_all_valid();
			else if (canq1) begin
				slotv[flo(pat)] <= INV;
				if (slot_jc[flo(pat)]|take_branch[flo(pat)])
					mark_all_valid();
			end
		3'b111:
			if (canq3 & !debug_on && `WAYS > 2)
				mark_all_valid();
			else if (canq2 & !debug_on && `WAYS > 1) begin
				slotv[flo(pat)] <= INV;
				slotv[fso(pat)] <= INV;
				if (|slot_jc| (|take_branch))
					mark_all_valid();
			end
			else if (canq1) begin
				slotv[flo(pat)] <= INV;
				if (slot_jc[flo(pat)]|take_branch[flo(pat)])
					mark_all_valid();
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

endmodule
