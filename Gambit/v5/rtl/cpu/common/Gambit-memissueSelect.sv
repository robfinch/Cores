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
// Starts search for instructions to issue at the head of the queue and 
// progresses from there. This ensures that the oldest instructions are
// selected first for processing.
// ============================================================================
//
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-types.sv"

module memissueSelect(heads, iq_stomp, iq_memissue, iq_state, dram0, dram1, issue0, issue1);
input Qid heads [0:`IQ_ENTRIES-1];
input [`IQ_ENTRIES-1:0] iq_stomp;
input [`IQ_ENTRIES-1:0] iq_memissue;
input QState iq_state [0:`IQ_ENTRIES-1];
input [2:0] dram0;
input [2:0] dram1;
output reg [`QBITS] issue0;
output reg [`QBITS] issue1;

integer n;

always @*
begin
	issue0 = `IQ_ENTRIES;
	issue1 = `IQ_ENTRIES;
	for (n = `IQ_ENTRIES - 1; n >= 0; n = n - 1)
    if (!iq_stomp[heads[n]] && iq_memissue[heads[n]] && iq_state[heads[n]]==IQS_AGEN) begin
      if (dram0 == `DRAMSLOT_AVAIL) begin
       	issue0 = heads[n];
      end
    end
	for (n = `IQ_ENTRIES - 1; n >= 0; n = n - 1)
    if (!iq_stomp[heads[n]] && iq_memissue[heads[n]] && iq_state[heads[n]]==IQS_AGEN) begin
    	if (heads[n] != issue0 && `NUM_MEM > 1) begin
        if (dram1 == `DRAMSLOT_AVAIL) begin
					issue1 = heads[n];
        end
    	end
    end
end

endmodule
