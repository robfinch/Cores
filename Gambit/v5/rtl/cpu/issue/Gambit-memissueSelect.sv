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
// Starts search for instructions to issue at the head of the queue and 
// progresses from there. This ensures that the oldest instructions are
// selected first for processing.
// ============================================================================
//
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-types.sv"

module memissueSelect(rst, clk, ce, allow_issue, iq_stomp, iq_memissue, iqs_agen, dram0, dram1, issue0, issue1);
input rst;
input clk;
input ce;
input [8:0] allow_issue;
input [`IQ_ENTRIES-1:0] iq_stomp;
input [`IQ_ENTRIES-1:0] iq_memissue;
input [`IQ_ENTRIES-1:0] iqs_agen;
input [2:0] dram0;
input [2:0] dram1;
output reg [`QBITS] issue0;
output reg [`QBITS] issue1;

integer n;
reg [`QBITS] issue0p;
reg [`QBITS] issue1p;

// Prevent back-to-back issue two clock cycles in a row on the same slot.
// It takes a clock cycle for the dram state to be set busy.
reg li0, li1;

always @*
if (rst) begin
	issue0p = `IQ_ENTRIES;
	issue1p = `IQ_ENTRIES;
end
else begin
	issue0p = `IQ_ENTRIES;
	issue1p = `IQ_ENTRIES;
	for (n = 0; n < `IQ_ENTRIES; n = n + 1)
    if (allow_issue[7] && iq_memissue[n] && iqs_agen[n] && !li0) begin
      if (dram0 == `DRAMSLOT_AVAIL) begin
       	issue0p = n;
      end
    end
	for (n = 0; n < `IQ_ENTRIES; n = n + 1)
    if (allow_issue[8] && iq_memissue[n] && iqs_agen[n] && !li1) begin
    	if (n != issue0p && `NUM_MEM > 1) begin
        if (dram1 == `DRAMSLOT_AVAIL) begin
					issue1p = n;
        end
    	end
    end
end

always @(posedge clk)
if (rst)
	li0 = 1'b0;
else begin
	if (ce) begin
		li0 = issue0p != `IQ_ENTRIES;
		issue0 = issue0p;
	end
end
always @(posedge clk)
if (rst)
	li1 = 1'b0;
else begin
	if (ce) begin
		li1 = issue1p != `IQ_ENTRIES;
		issue1 = issue1p;
	end
end

endmodule
