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

module slot_valid(rst, clk, branchmiss, phit, ip_mask, slot_jc, take_branch, slotv);
parameter VAL = 1'b1;
parameter INV = 1'b0;
input rst;
input clk;
input branchmiss;
input [5:0] slot_jc;
input [5:0] take_branch;
input phit;
input [5:0] ip_mask;
output reg [5:0] slotv;

integer n;

wire [5:0] pat;
assign pat = slotv & {6{phit}} & ip_mask;

// Find first one
function ffo(i, o);
input [5:0] i;
output reg [2:0] o;
always @*
casez(i)
6'b1?????:  ffo <= 3'd5;
6'b01????:  ffo <= 3'd4;
6'b001???:  ffo <= 3'd3;
6'b0001??:  ffo <= 3'd2;
6'b00001?:  ffo <= 3'd1;
6'b000001:  ffo <= 3'd0;
default:    ffo <= 3'd7;
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
		6'b000000:	;
		6'b000001,
		6'b000010,
		6'b000100,
		6'b001000,
		6'b010000,
		6'b100000:
			if (canq1)
				mark_all_valid();
		6'b000011,
		6'b000101,
		6'b000110,
		6'b001001,
		6'b001010,
		6'b001100,
		6'b010001,
		6'b010010,
		6'b010100,
		6'b011000,
		6'b100001,
		6'b100010,
		6'b100100,
		6'b101000,
		6'b110000:
			if (canq2 & !debug_on && `WAYS > 1)
				mark_all_valid();
			else if (canq1) begin
				slotv[ffo(pat)] <= INV;
				if (slot_jc[ffo(pat)]|take_branch[ffo(pat)])
					mark_all_valid();
			end
		6'b000111,
		6'b001011,
		6'b001110,
		6'b010011,
		6'b010110,
		6'b011001,
		6'b011010,
		6'b011100,
		3'b111:
			if (canq6 & !debug_on && `WAYS > 5)
				mark_all_valid();
			else if (canq5 & !debug_on && `WAYS > 4) begin
			end
			else if (canq2 & !debug_on && `WAYS > 1) begin
				slotv[0] <= INV;
				slotv[1] <= INV;
				if (slot_jc[0]|take_branch[0]|slot_jc[1]|take_branch[1])
					mark_all_valid();
			end
			else if (canq1) begin
				slotv[0] <= INV;
				if (slot_jc[0]|take_branch[0])
					mark_all_valid();
			end
		endcase
	end
end

task mark_all_valid;
begin
	for (n = 0; n < 6; n = n + 1)
		slotv[n] <= VAL;
end
endtask

endmodule
