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
`define QBITS	2:0

module FT64_stomp(branchmiss,branchmiss_thrd,missid,head0,thread_en,thrd,iqentry_v,stomp);
parameter QENTRIES = 8;
input branchmiss;
input branchmiss_thrd;
input [`QBITS] missid;
input [`QBITS] head0;
input thread_en;
input [QENTRIES-1:0] thrd;
input [QENTRIES-1:0] iqentry_v;
output reg [QENTRIES-1:0] stomp;

// Stomp logic for branch miss.

integer n;
reg [QENTRIES-1:0] stomp2;
reg [`QBITS] contid;
always @*
if (branchmiss) begin
    stomp2 = 8'h00;

    // If missed at the head, all queue entries but the head are stomped on.
    if (head0==missid) begin
        for (n = 0; n < QENTRIES; n = n + 1)
            if (n!=missid) begin
            	if (thread_en) begin
            		if (thrd[n]==branchmiss_thrd)
	                	stomp2[n] = iqentry_v[n];
            	end
            	else
                	stomp2[n] = iqentry_v[n];
            end
    end
    // If head0 is after the missid queue entries between the missid and
    // head0 are stomped on.
    else if (head0 > missid) begin
        for (n = 0; n < QENTRIES; n = n + 1)
            if (n > missid && n < head0) begin
            	if (thread_en) begin
            		if (thrd[n]==branchmiss_thrd)
	                	stomp2[n] = iqentry_v[n];
            	end
            	else
                	stomp2[n] = iqentry_v[n];
            end
    end
    // Otherwise still queue entries between missid and head0 are stomped on
    // but the range 'wraps around'.
    else begin
        for (n = 0; n < QENTRIES; n = n + 1)
            if (n < head0) begin
            	if (thread_en) begin
            		if (thrd[n]==branchmiss_thrd)
	                	stomp2[n] = iqentry_v[n];
            	end
            	else
                	stomp2[n] = iqentry_v[n];
            end
        for (n = 0; n < QENTRIES; n = n + 1)
            if (n >= missid + 1) begin
            	if (thread_en) begin
            		if (thrd[n]==branchmiss_thrd)
	                	stomp2[n] = iqentry_v[n];
            	end
            	else
                	stomp2[n] = iqentry_v[n];
            end
    end
    /*
    // Not sure this logic is worth it for the few cases where the target
    // of the branch is in the queue already and there are no target
    // registers in code stepped over.
    if (BRANCH_PRED) begin
        // If the next instruction in the queue is the target for the miss
        // then no instructions should have been stomped on. Undo the stomp.
        // In this case there would be no branchmiss.
        if (iqentry_stomp2[idp1(missid)] && iqentry_pc[idp1(missid)]==misspc) begin
            iqentry_stomp = 8'h00;
        end
        else if (iqentry_stomp2[idp2(missid)] && iqentry_pc[idp2(missid)]==misspc) begin
            if (iqentry_tgt[idp1(missid)]==12'h000) begin
                iqentry_stomp = 8'h00;
                setpred[(missid+1)&7] = `INV;
            end
            else
                iqentry_stomp = iqentry_stomp2;
        end
        else if (iqentry_stomp2[(missid+3)&7] && iqentry_pc[(missid+3)&7]==misspc) begin
            if (iqentry_tgt[(missid+1)&7]==8'h00 &&
                iqentry_tgt[(missid+2)&7]==8'h00) begin
                iqentry_stomp = 8'h00;
                setpred[(missid+1)&7] = `INV;
                setpred[(missid+2)&7] = `INV;
            end
            else
                iqentry_stomp = iqentry_stomp2;
        end
        else if (iqentry_stomp2[(missid+4)&7] && iqentry_pc[(missid+4)&7]==misspc) begin
            if (iqentry_tgt[(missid+1)&7]==8'h00 &&
                iqentry_tgt[(missid+2)&7]==8'h00 &&
                iqentry_tgt[(missid+3)&7]==8'h00
                ) begin
                iqentry_stomp = 8'h00;
                setpred[(missid+1)&7] = `INV;
                setpred[(missid+2)&7] = `INV;
                setpred[(missid+3)&7] = `INV;
            end
            else
                iqentry_stomp = iqentry_stomp2;
        end
        else if (iqentry_stomp2[(missid+5)&7] && iqentry_pc[(missid+5)&7]==misspc) begin
            if (iqentry_tgt[(missid+1)&7]==8'h00 &&
                iqentry_tgt[(missid+2)&7]==8'h00 &&
                iqentry_tgt[(missid+3)&7]==8'h00 &&
                iqentry_tgt[(missid+4)&7]==8'h00
                ) begin
                iqentry_stomp = 8'h00;
                setpred[(missid+1)&7] = `INV;
                setpred[(missid+2)&7] = `INV;
                setpred[(missid+3)&7] = `INV;
                setpred[(missid+4)&7] = `INV;
            end
            else
                iqentry_stomp = iqentry_stomp2;
        end
        else if (iqentry_stomp2[(missid+6)&7] && iqentry_pc[(missid+6)&7]==misspc) begin
            if (iqentry_tgt[(missid+1)&7]==8'h00 &&
                iqentry_tgt[(missid+2)&7]==8'h00 &&
                iqentry_tgt[(missid+3)&7]==8'h00 &&
                iqentry_tgt[(missid+4)&7]==8'h00 &&
                iqentry_tgt[(missid+5)&7]==8'h00
            ) begin
                iqentry_stomp = 8'h00;
                setpred[(missid+1)&7] = `INV;
                setpred[(missid+2)&7] = `INV;
                setpred[(missid+3)&7] = `INV;
                setpred[(missid+4)&7] = `INV;
                setpred[(missid+5)&7] = `INV;
            end
            else
                iqentry_stomp = iqentry_stomp2;
        end
        else if (iqentry_stomp2[(missid+7)&7] && iqentry_pc[(missid+7)&7]==misspc) begin
            if (iqentry_tgt[(missid+1)&7]==8'h00 &&
                iqentry_tgt[(missid+2)&7]==8'h00 &&
                iqentry_tgt[(missid+3)&7]==8'h00 &&
                iqentry_tgt[(missid+4)&7]==8'h00 &&
                iqentry_tgt[(missid+5)&7]==8'h00 &&
                iqentry_tgt[(missid+6)&7]==8'h00
            ) begin
                iqentry_stomp = 8'h00;
                setpred[(missid+1)&7] = `INV;
                setpred[(missid+2)&7] = `INV;
                setpred[(missid+3)&7] = `INV;
                setpred[(missid+4)&7] = `INV;
                setpred[(missid+5)&7] = `INV;
                setpred[(missid+6)&7] = `INV;
            end
            else
                iqentry_stomp = iqentry_stomp2;
        end
        else
            iqentry_stomp = iqentry_stomp2;
    end
    else
        iqentry_stomp = iqentry_stomp2;
    */
    stomp = stomp2;
end
else begin
    stomp = {QENTRIES{1'b0}};
end

endmodule
