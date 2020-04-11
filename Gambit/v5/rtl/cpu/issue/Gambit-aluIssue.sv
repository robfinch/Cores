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

module aluIssue(rst, clk, ce, allow_issue, could_issue, alu0_idle, alu1_idle, iq_alu, iq_alu0, iq_prior_sync, issue0, issue1);
input rst;
input clk;
input ce;
input [8:0] allow_issue;
input [`IQ_ENTRIES-1:0] could_issue;
input alu0_idle;
input alu1_idle;
input [`IQ_ENTRIES-1:0] iq_alu;
input [`IQ_ENTRIES-1:0] iq_alu0;
input [`IQ_ENTRIES-1:0] iq_prior_sync;
output reg [`IQ_ENTRIES-1:0] issue0;
output reg [`IQ_ENTRIES-1:0] issue1;

integer n;
reg [`IQ_ENTRIES-1:0] issue0p;
reg [`IQ_ENTRIES-1:0] issue1p;

// Start search for instructions to process at head of queue (oldest instruction).
always @*
begin
	issue0p = {`IQ_ENTRIES{1'b0}};
	issue1p = {`IQ_ENTRIES{1'b0}};
	
	if (alu0_idle & allow_issue[0]) begin
		for (n = 0; n < `IQ_ENTRIES; n = n + 1) begin
			if (could_issue[n] && iq_alu[n]
			&& issue0p == {`IQ_ENTRIES{1'b0}}
			// If there are no valid queue entries prior it doesn't matter if there is
			// a sync.
			&& (!iq_prior_sync[n])
			)
			  issue0p[n] = `TRUE;
		end
	end

	if (alu1_idle && allow_issue[1] && `NUM_ALU > 1) begin
		for (n = 0; n < `IQ_ENTRIES; n = n + 1) begin
			if (could_issue[n] && iq_alu[n] && !iq_alu0[n]
				&& !issue0p[n]
				&& issue1p == {`IQ_ENTRIES{1'b0}}
				&& (!iq_prior_sync[n])
			)
			  issue1p[n] = `TRUE;
		end
	end
end


always @*
	issue0 <= issue0p;
always @*
	issue1 <= issue1p;

/*
always @(posedge clk)
if (ce)
	issue0 <= issue0p;
always @(posedge clk)
if (ce)
	issue1 <= issue1p;
*/

endmodule
