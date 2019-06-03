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

module intruction_pointer(rst, clk, canq1, canq2, canq3, insnx, phit, branchmiss, missip, ip_mask,
	slotv, slot_jc, slot_br, take_branch, btgt, ip, debug_on);
parameter AMSB = 79;
parameter RSTIP = 80'hFFFFFFFFFFFFFFFC0100;
parameter QSLOTS = `QSLOTS;
input rst;
input clk;
input canq1;
input canq2;
input canq3;
input [39:0] insnx [0:QSLOTS-1];
input phit;
input branchmiss;
input [AMSB:0] missip;
input [QSLOTS-1:0] ip_mask;
input [QSLOTS-1:0] slotv;
input [QSLOTS-1:0] slot_jc;
input [QSLOTS-1:0] slot_br;
input [QSLOTS-1:0] take_branch;
input [AMSB:0] btgt [0:QSLOTS-1];
output reg [AMSB:0] ip;
input debug_on;

always @(posedge clk)
if (rst) begin
	ip <= RSTIP;
end
else begin
	if (branchmiss) begin
		$display("==============================");
		$display("==============================");
		$display("Branch miss: tgt=%h",{missip[AMSB:2],missip[3:2]});
		$display("==============================");
		$display("==============================");
		ip <= {missip[AMSB:2],missip[3:2]};
	end
	else
	case({slotv[0],slotv[1],slotv[2]}&{3{phit}}&ip_mask)
	3'b000:	;
	3'b001:
		if (canq1) begin
			if (take_branch[2]) begin
				if (slot_br[2])
					ip <= btgt[2];
				else
					ip[22:0] <= {insnx[2][39:22],insnx[2][5:3],insnx[2][4:3]};
			end
			else if (slot_jc[2])
				ip[37:0] <= {insnx[2][39:10],insnx[2][5:0],insnx[2][1:0]};
			else
				ip <= {ip[79:4] + 76'd1,4'h0};
		end
	3'b010:
		if (canq1) begin
			if (take_branch[1]) begin
				if (slot_br[1])
					ip <= btgt[1];
				else
					ip[22:0] <= {insnx[1][39:22],insnx[1][5:3],insnx[1][4:3]};
			end
			else if (slot_jc[1])
				ip[37:0] <= {insnx[1][39:10],insnx[1][5:0],insnx[1][1:0]};
			else
				ip <= {ip[AMSB:4] + 2'd1,4'h0};
		end
	3'b011:
		if (canq2 & !debug_on && `WAYS > 1) begin
			if (slot_jc[1])
				ip[37:0] <= {insnx[1][39:10],insnx[1][5:0],insnx[1][1:0]};
			else if (take_branch[1]) begin
				if (slot_br[1])
					ip <= btgt[1];
				else
					ip[22:0] <= {insnx[1][39:22],insnx[1][5:3],insnx[1][4:3]};
			end
			else if (slot_jc[2])
				ip[37:0] <= {insnx[2][39:10],insnx[2][5:0],insnx[2][1:0]};
			else if (take_branch[2]) begin
				if (slot_br[2])
					ip <= btgt[2];
				else
					ip[22:0] <= {insnx[2][39:22],insnx[2][5:3],insnx[2][4:3]};
			end
			else begin
				ip <= {ip[79:4] + 76'd1,4'h0};
			end
		end
		else if (canq1) begin
			if (slot_jc[1])
				ip[37:0] <= {insnx[1][39:10],insnx[1][5:0],insnx[1][1:0]};
			else if (take_branch[1]) begin
				if (slot_br[1])
					ip <= btgt[1];
				else
					ip[22:0] <= {insnx[1][39:22],insnx[1][5:3],insnx[1][4:3]};
			end
			else
				ip[3:0] <= 4'hA;
		end
	3'b100:
		if (canq1) begin
			if (slot_jc[0])
				ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			else if (take_branch[0]) begin
				if (slot_br[0])
					ip <= btgt[0];
				else
					ip[22:0] <= {insnx[0][39:22],insnx[0][5:3],insnx[0][4:3]};
			end
			else
				ip <= {ip[AMSB:4] + 76'd1,4'h0};
		end
	3'b101:
		if (canq2 & !debug_on && `WAYS > 1) begin
			if (slot_jc[0]) begin
				ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			end
			else if (take_branch[0]) begin
				if (slot_br[0])
					ip <= btgt[0];
				else
					ip[22:0] <= {insnx[0][39:22],insnx[0][5:3],insnx[0][4:3]};
			end
			else if (slot_jc[2]) begin
				ip[37:0] <= {insnx[2][39:10],insnx[2][5:0],insnx[2][1:0]};
			end
			else if (take_branch[2]) begin
				if (slot_br[2])
					ip <= btgt[2];
				else
					ip[22:0] <= {insnx[2][39:22],insnx[2][5:3],insnx[2][4:3]};
			end
			else begin
				ip <= {ip[79:4] + 76'd1,4'h0};
			end
		end
		else if (canq1) begin
			if (slot_jc[0]) begin
				ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			end
			else if (take_branch[0]) begin
				if (slot_br[0])
					ip <= btgt[0];
				else
					ip[22:0] <= {insnx[0][39:22],insnx[0][5:3],insnx[0][4:3]};
			end
			else
				ip[3:0] <= 4'hA;
		end
	3'b110:
		if (canq2 & !debug_on & `WAYS > 1) begin
			if (slot_jc[0])
				ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			else if (take_branch[0]) begin
				if (slot_br[0])
					ip <= btgt[0];
				else
					ip[22:0] <= {insnx[0][39:22],insnx[0][5:3],insnx[0][4:3]};
			end
			else if (slot_jc[1])
				ip[37:0] <= {insnx[1][39:10],insnx[1][5:0],insnx[1][1:0]};
			else if (take_branch[1]) begin
				if (slot_br[1])
					ip <= btgt[1];
				else
					ip[22:0] <= {insnx[1][39:22],insnx[1][5:3],insnx[1][4:3]};
			end
			else begin
				ip <= {ip[AMSB:4] + 76'd1,4'h0};
			end
		end
		else if (canq1) begin
			if (slot_jc[0])
				ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			else if (take_branch[0]) begin
				if (slot_br[0])
					ip <= btgt[0];
				else
					ip[22:0] <= {insnx[0][39:22],insnx[0][5:3],insnx[0][4:3]};
			end
			else
				ip[3:0] <= 4'h5;
		end
	3'b111:
		if (canq3 & !debug_on && `WAYS > 2) begin
			if (slot_jc[0]) begin
				ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			end
			else if (take_branch[0]) begin
				if (slot_br[0])
					ip <= btgt[0];
				else
					ip[22:0] <= {insnx[0][39:22],insnx[0][5:3],insnx[0][4:3]};
			end
			else if (slot_jc[1]) begin
				ip[37:0] <= {insnx[1][39:10],insnx[1][5:0],insnx[1][1:0]};
			end
			else if (take_branch[1]) begin
				if (slot_br[1])
					ip <= btgt[1];
				else
					ip[22:0] <= {insnx[1][39:22],insnx[1][5:3],insnx[1][4:3]};
			end
			else if (slot_jc[2]) begin
				ip[37:0] <= {insnx[2][39:10],insnx[2][5:0],insnx[2][1:0]};
			end
			else if (take_branch[2]) begin
				if (slot_br[2])
					ip <= btgt[2];
				else
					ip[22:0] <= {insnx[2][39:22],insnx[2][5:3],insnx[2][4:3]};
			end
			else begin
				ip <= {ip[AMSB:4] + 76'd1,4'h0};
			end
		end
		else if (canq2 & !debug_on && `WAYS > 1) begin
			if (slot_jc[0]) begin
				ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			end
			else if (take_branch[0]) begin
				if (slot_br[0])
					ip <= btgt[0];
				else
					ip[22:0] <= {insnx[0][39:22],insnx[0][5:3],insnx[0][4:3]};
			end
			else if (slot_jc[1]) begin
				ip[37:0] <= {insnx[1][39:10],insnx[1][5:0],insnx[1][1:0]};
			end
			else if (take_branch[1]) begin
				if (slot_br[1])
					ip <= btgt[1];
				else
					ip[22:0] <= {insnx[1][39:22],insnx[1][5:3],insnx[1][4:3]};
			end
			else begin
				ip[3:0] <= 4'hA;
			end
		end
		else if (canq1) begin
			if (slot_jc[0]) begin
				ip[37:0] <= {insnx[0][39:10],insnx[0][5:0],insnx[0][1:0]};
			end
			else if (take_branch[0]) begin
				if (slot_br[0])
					ip <= btgt[0];
				else
					ip[22:0] <= {insnx[0][39:22],insnx[0][5:3],insnx[0][4:3]};
			end
			else begin
				ip[3:0] <= 4'h5;
			end
		end
	endcase
end

endmodule
