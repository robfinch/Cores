// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
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
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-types.sv"

module getRQueuedCount(rst, rob_tails, heads, rob_v_i, rob_v_o, iqs_queued, iq_rid_i, iq_rid_o, rqueuedCnt, rqueuedOn);
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter RENTRIES = `RENTRIES;
parameter RSLOTS = `RSLOTS;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter VAL = 1'b1;
parameter INV = 1'b0;
input rst;
input Rid rob_tails [0:RSLOTS*2-1];
input Qid heads [0:IQ_ENTRIES-1];
input [RENTRIES-1:0] rob_v_i;
output reg [RENTRIES-1:0] rob_v_o;
input [IQ_ENTRIES-1:0] iqs_queued;
input Rid iq_rid_i [0:IQ_ENTRIES-1];
output Rid iq_rid_o [0:IQ_ENTRIES-1];
output reg [2:0] rqueuedCnt;
output reg [IQ_ENTRIES-1:0] rqueuedOn;

integer n, j, k;

// The earliest instructions are assigned re-order buffer entries first.
always @*
if (rst) begin
	rob_v_o = 1'd0;
	rqueuedCnt = 1'd0;
	for (n = 0; n < IQ_ENTRIES; n = n + 1)
		iq_rid_o[n]= 1'd0;
	rqueuedOn = 1'd0;
end
else begin
	rqueuedCnt = 3'd0;
	j = rob_tails[0];
	rob_v_o = rob_v_i;
	k = 0;
	for (n = 0; n < IQ_ENTRIES; n = n + 1) begin
		iq_rid_o[heads[n]] = iq_rid_i[heads[n]];
		rqueuedOn[heads[n]] = FALSE;
		if (iqs_queued[heads[n]] && !rob_v_i[j] && k < RSLOTS) begin
			rob_v_o[heads[n]] = VAL;
			rqueuedCnt = rqueuedCnt + 1;
			rqueuedOn[heads[n]] = TRUE;
			iq_rid_o[heads[n]] = j[`QBITS];
			iq_rid_o[heads[n]][`QBIT] = 1'b1;
			j = (j + 1) % RENTRIES;
			k = k + 1;
		end
	end
end

endmodule
