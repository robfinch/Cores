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

module aluIssue(heads, could_issue, alu0_idle, alu1_idle, iq_alu, iq_alu0, iq_prior_sync, issue0, issue1);
input Qid heads [0:`IQ_ENTRIES-1];
input [`IQ_ENTRIES-1:0] could_issue;
input alu0_idle;
input alu1_idle;
input [`IQ_ENTRIES-1:0] iq_alu;
input [`IQ_ENTRIES-1:0] iq_alu0;
input [`IQ_ENTRIES-1:0] iq_prior_sync;
output reg [`IQ_ENTRIES-1:0] issue0;
output reg [`IQ_ENTRIES-1:0] issue1;

integer n;

// Start search for instructions to process at head of queue (oldest instruction).
always @*
begin
	issue0 = {`IQ_ENTRIES{1'b0}};
	issue1 = {`IQ_ENTRIES{1'b0}};
	
	if (alu0_idle) begin
		for (n = 0; n < `IQ_ENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_alu[heads[n]]
			&& issue0 == {`IQ_ENTRIES{1'b0}}
			// If there are no valid queue entries prior it doesn't matter if there is
			// a sync.
			&& (!iq_prior_sync[heads[n]])
			)
			  issue0[heads[n]] = `TRUE;
		end
	end

	if (alu1_idle && `NUM_ALU > 1) begin
		for (n = 0; n < `IQ_ENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_alu[heads[n]] && !iq_alu0[heads[n]]
				&& !issue0[heads[n]]
				&& issue1 == {`IQ_ENTRIES{1'b0}}
				&& (!iq_prior_sync[heads[n]])
			)
			  issue1[heads[n]] = `TRUE;
		end
	end
end


endmodule
