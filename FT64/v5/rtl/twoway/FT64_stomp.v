// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_stomp.v
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
`include "FT64_config.vh"

module FT64_stomp(branchmiss,branchmiss_thrd,missid,head0,thrd,iqentry_v,stomp);
parameter QENTRIES = `QENTRIES;
input branchmiss;
input branchmiss_thrd;
input [`QBITS] missid;
input [`QBITS] head0;
input [QENTRIES-1:0] thrd;
input [QENTRIES-1:0] iqentry_v;
output reg [QENTRIES-1:0] stomp;

// Stomp logic for branch miss.

integer n;
reg [QENTRIES-1:0] stomp2;
reg [`QBITS] contid;
always @*
if (branchmiss) begin
    stomp2 = {QENTRIES{1'b0}};

    // If missed at the head, all queue entries but the head are stomped on.
    if (head0==missid) begin
        for (n = 0; n < QENTRIES; n = n + 1)
            if (n!=missid) begin
        		if (thrd[n]==branchmiss_thrd)
                	stomp2[n] = iqentry_v[n];
            end
    end
    // If head0 is after the missid queue entries between the missid and
    // head0 are stomped on.
    else if (head0 > missid) begin
        for (n = 0; n < QENTRIES; n = n + 1)
            if (n > missid && n < head0) begin
        		if (thrd[n]==branchmiss_thrd)
                	stomp2[n] = iqentry_v[n];
            end
    end
    // Otherwise still queue entries between missid and head0 are stomped on
    // but the range 'wraps around'.
    else begin
        for (n = 0; n < QENTRIES; n = n + 1)
            if (n < head0) begin
        		if (thrd[n]==branchmiss_thrd)
                	stomp2[n] = iqentry_v[n];
            end
        for (n = 0; n < QENTRIES; n = n + 1)
            if (n >= missid + 1) begin
        		if (thrd[n]==branchmiss_thrd)
                	stomp2[n] = iqentry_v[n];
            end
    end
    stomp = stomp2;
end
else begin
    stomp = {QENTRIES{1'b0}};
end

endmodule
