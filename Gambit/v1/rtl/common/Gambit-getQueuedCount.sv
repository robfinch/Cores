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
// Check how many instructions can be queued. This might be fewer than the
// number ready to queue from the fetch stage if queue slots aren't
// available or if there are no more physical registers left for remapping.
// The fetch stage needs to know how many instructions will queue so this
// logic is placed here.
// For the VEX instruction, the instruction can't queue until register Rs1
// is valid, because register Rs1 is used to specify the vector element to
// read.
//
// ============================================================================
//
`include "rtf65004-config.sv"

module getQueuedCount(branchmiss, brk, phitd, tails, rob_tails, slotvd,
	slot_jmp, take_branch, iq_v, rob_v, queuedCnt, queuedOnp);
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter QSLOTS = `QSLOTS;
parameter RENTRIES = `RENTRIES;
parameter RSLOTS = `RSLOTS;
input branchmiss;
input [2:0] brk;
input phitd;
input [`QBITS] tails [0:QSLOTS-1];
input [`RBITS] rob_tails [0:RSLOTS-1];
input [QSLOTS-1:0] slotvd;
input [QSLOTS-1:0] slot_jmp;
input [QSLOTS-1:0] take_branch;
input [IQ_ENTRIES-1:0] iq_v;
input [RENTRIES-1:0] rob_v;
output reg [2:0] queuedCnt;
output reg [QSLOTS-1:0] queuedOnp;

always @*
begin
	queuedCnt <= 3'd0;
	queuedOnp <= 1'd0;
	if (!branchmiss) begin
		// Three available
		case(slotvd)
		3'b001:
      if (iq_v[tails[0]]==`INV && rob_v[rob_tails[0]]==`INV) begin
        queuedCnt <= 3'd1;
        queuedOnp[0] <= `TRUE;
      end
		3'b010:
      if (iq_v[tails[0]]==`INV && rob_v[rob_tails[0]]==`INV) begin
        queuedCnt <= 3'd1;
        queuedOnp[1] <= `TRUE;
      end
		3'b011:
      if (iq_v[tails[0]]==`INV && rob_v[rob_tails[0]]==`INV) begin
        queuedCnt <= 3'd1;
        queuedOnp[0] <= `TRUE;
        if (!brk[0]) begin
	        if (!(slot_jmp[0]|take_branch[0])) begin
	          if (iq_v[tails[1]]==`INV && rob_v[rob_tails[1]]==`INV) begin
	            if (`WAYS > 1) begin
	            	queuedCnt <= 3'd2;
				        queuedOnp[1] <= `TRUE;
				      end
	          end
	        end
	      end
    	end
		3'b100:
      if (iq_v[tails[0]]==`INV && rob_v[rob_tails[0]]==`INV) begin
        queuedCnt <= 3'd1;
        queuedOnp[2] <= `TRUE;
      end
    3'b101:		//; // Illegal
      if (iq_v[tails[0]]==`INV && rob_v[rob_tails[0]]==`INV) begin
        queuedCnt <= 3'd1;
        queuedOnp[0] <= `TRUE;
      end
    3'b110:
      if (iq_v[tails[0]]==`INV && rob_v[rob_tails[0]]==`INV) begin
        queuedCnt <= 3'd1;
        queuedOnp[1] <= `TRUE;
        if (!brk[1]) begin
	        if (!(slot_jmp[1]|take_branch[1])) begin
	          if (iq_v[tails[1]]==`INV && rob_v[rob_tails[1]]==`INV) begin
	            if (`WAYS > 1) begin
	            	queuedCnt <= 3'd2;
	            	queuedOnp[2] <= `TRUE;
	            end
	          end
	        end
      	end
    	end
		3'b111:
      if (iq_v[tails[0]]==`INV && rob_v[rob_tails[0]]==`INV) begin
        queuedCnt <= 3'd1;
        queuedOnp[0] <= `TRUE;
        if (!brk[0]) begin
					if (!(slot_jmp[0]|take_branch[0])) begin
	          if (iq_v[tails[1]]==`INV && rob_v[rob_tails[1]]==`INV) begin
	            if (`WAYS > 1) begin
	            	queuedCnt <= 3'd2;
	            	queuedOnp[1] <= `TRUE;
	            end
	            if (!brk[1]) begin
		          	if (!(slot_jmp[1]|take_branch[1])) begin
			            if (iq_v[tails[2]]==`INV && rob_v[rob_tails[2]]==`INV) begin
				            if (`WAYS > 2) begin
				            	queuedCnt <= 3'd3;
				            	queuedOnp[2] <= `TRUE;
				            end
			            end
			          end
		        	end
		        end
					end
				end
			end
		default:	;
		endcase
  end
end

endmodule
