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
//
// ============================================================================
//
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-types.sv"

module fcuIssue(heads, could_issue, branchmiss, fcu_id, fcu_done, iq_fc, iq_br, iq_state, iq_sn, prior_sync, prior_valid, issue, nid);
input Qid heads [0:`IQ_ENTRIES-1];
input [`IQ_ENTRIES-1:0] could_issue;
input branchmiss;
input Qid fcu_id;
input fcu_done;
input [`IQ_ENTRIES-1:0] iq_fc;
input [`IQ_ENTRIES-1:0] iq_br;
input QState iq_state [0:`IQ_ENTRIES-1];
input Seqnum iq_sn [0:`IQ_ENTRIES-1];
input [`IQ_ENTRIES-1:0] prior_sync;
input [`IQ_ENTRIES-1:0] prior_valid;
output reg [`IQ_ENTRIES-1:0] issue;
output reg Qid nid;

integer j, n;
reg [`IQ_ENTRIES-1:0] nextqd;


//reg [`QBITS] nids [0:`IQ_ENTRIES-1];
//always @*
//for (j = 0; j < `IQ_ENTRIES; j = j + 1) begin
//	// We can't both start and stop at j
//	for (n = j; n != (j+1)%`IQ_ENTRIES; n = (n + (`IQ_ENTRIES-1)) % `IQ_ENTRIES)
//		nids[j] = n;
//	// Do the last one
//	nids[j] = (j+1)%`IQ_ENTRIES;
//end

// Search the queue for the next entry on the same thread.
always @*
begin
	nid = (fcu_id + 2'd1) % `IQ_ENTRIES;
//	for (n = `IQ_ENTRIES-1; n > 0; n = n - 1)
//		nid = (fcu_id + n) % `IQ_ENTRIES;
end

always @*
for (n = 0; n < `IQ_ENTRIES; n = n + 1)
	nextqd[n] <= iq_sn[(n+1)%`IQ_ENTRIES] > iq_sn[n] && iq_state[(n+1)%`IQ_ENTRIES]!=IQS_INVALID;

//assign nextqd = 8'hFF;

// Don't issue to the fcu until the following instruction is enqueued.
// However, if the queue is full then issue anyway. A branch miss will likely occur.
// Start search for instructions at head of queue (oldest instruction).
always @*
begin
	issue = {`IQ_ENTRIES{1'b0}};
	
	if (fcu_done & ~branchmiss) begin
		for (n = 0; n < `IQ_ENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_fc[heads[n]] && (nextqd[heads[n]] || iq_br[heads[n]])
			&& issue == {`IQ_ENTRIES{1'b0}}
			&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
			)
			  issue[heads[n]] = `TRUE;
		end
	end
end

endmodule
