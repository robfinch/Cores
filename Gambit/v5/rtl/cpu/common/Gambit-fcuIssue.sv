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
//
// ============================================================================
//
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-types.sv"

module fcuIssue(rst, clk, ce, could_issue, branchmiss, fcu_id, fcu_done, iq_fc,
	iq_br, iq_brkgrp, iq_retgrp, iq_jal, iqs_v, iq_sn,
	iq_prior_sync, issue, nid);
input rst;
input clk;
input ce;
input [`IQ_ENTRIES-1:0] could_issue;
input branchmiss;
input Qid fcu_id;
input fcu_done;
input [`IQ_ENTRIES-1:0] iq_fc;
input [`IQ_ENTRIES-1:0] iq_br;
input [`IQ_ENTRIES-1:0] iq_brkgrp;
input [`IQ_ENTRIES-1:0] iq_retgrp;
input [`IQ_ENTRIES-1:0] iq_jal;
input [`IQ_ENTRIES-1:0] iqs_v;
input Seqnum iq_sn [0:`IQ_ENTRIES-1];
input [`IQ_ENTRIES-1:0] iq_prior_sync;
output reg [`IQ_ENTRIES-1:0] issue;
output Qid nid;

integer j, n;
reg [`IQ_ENTRIES-1:0] nextqd;
reg [`IQ_ENTRIES-1:0] issuep;


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

//always @*
//for (n = 0; n < `IQ_ENTRIES; n = n + 1)
//	nextqd[n] <= iq_sn[(n+1)%`IQ_ENTRIES] > iq_sn[n] && iq_state[(n+1)%`IQ_ENTRIES]!=IQS_INVALID;

always @*
for (n = 0; n < `IQ_ENTRIES; n = n + 1)
	nextqd[n] <= iq_sn[(n+1)%`IQ_ENTRIES] > iq_sn[n] && iqs_v[(n+1)%`IQ_ENTRIES];

//assign nextqd = 8'hFF;

// Start search for instructions at head of queue (oldest instruction).
always @*
if (rst)
	issuep = {`IQ_ENTRIES{1'b0}};
else begin
	issuep = {`IQ_ENTRIES{1'b0}};
	
	if (fcu_done & ~branchmiss) begin
		for (n = 0; n < `IQ_ENTRIES; n = n + 1) begin
			if (could_issue[n] && iq_fc[n]
			&& issuep == {`IQ_ENTRIES{1'b0}}
			&& (!iq_prior_sync[n])
			)
			  issuep[n] = `TRUE;
		end
	end
end

always @(posedge clk)
if (ce)
	issue <= issuep;

endmodule
