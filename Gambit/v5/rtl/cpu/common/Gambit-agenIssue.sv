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

module agenIssue(agen0_idle, agen1_idle, heads, could_issue, iq_mem, prior_sync, prior_valid, issue0, issue1);
input agen0_idle;
input agen1_idle;
input [`QBITS] heads [0:`IQ_ENTRIES-1];
input [`IQ_ENTRIES-1:0] could_issue;
input [`IQ_ENTRIES-1:0] iq_mem;
input [`IQ_ENTRIES-1:0] prior_sync;
input [`IQ_ENTRIES-1:0] prior_valid;
output reg [`QBITS] issue0;
output reg [`QBITS] issue1;

integer n;

always @*
begin
	issue0 = {`IQ_ENTRIES{1'b0}};
	issue1 = {`IQ_ENTRIES{1'b0}};
	
	if (agen0_idle) begin
		for (n = 0; n < `IQ_ENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_mem[heads[n]] && issue0 == {`IQ_ENTRIES{1'b0}}
			// If there are no valid queue entries prior it doesn't matter if there is
			// a sync.
			&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
			)
			  issue0[heads[n]] = `TRUE;
		end
	end

	if (agen1_idle && `NUM_AGEN > 1) begin
		for (n = 0; n < `IQ_ENTRIES; n = n + 1) begin
			if (could_issue[heads[n]] && iq_mem[heads[n]]
				&& !issue0[heads[n]]
				&& issue1 == {`IQ_ENTRIES{1'b0}}
				&& (!prior_sync[heads[n]] || !prior_valid[heads[n]])
			)
			  issue1[heads[n]] = `TRUE;
		end
	end
end

endmodule
