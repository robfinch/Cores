//=============================================================================
//        __
//   \\__/ o\    (C) 2013-2017  Robert Finch, Waaterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//  
//	FT64BranchPredictor.v
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
//=============================================================================
//
module FT64BranchPredictor(rst, clk, en,
    xisBranch0, xisBranch1,
    pcA, pcB, pcC, pcD, xpc0, xpc1, takb0, takb1,
    predict_takenA, predict_takenB, predict_takenC, predict_takenD);
parameter DBW=32;
input rst;
input clk;
input en;
input xisBranch0;
input xisBranch1;
input [DBW-1:0] pcA;
input [DBW-1:0] pcB;
input [DBW-1:0] pcC;
input [DBW-1:0] pcD;
input [DBW-1:0] xpc0;
input [DBW-1:0] xpc1;
input takb0;
input takb1;
output predict_takenA;
output predict_takenB;
output predict_takenC;
output predict_takenD;

integer n;
reg [2:0] gbl_branch_hist;
reg [1:0] branch_history_table [511:0];
// For simulation only, initialize the history table to zeros.
// In the real world we don't care.
initial begin
    gbl_branch_hist = 3'b000;
	for (n = 0; n < 512; n = n + 1)
		branch_history_table[n] = 0;
end
wire [8:0] bht_wa0 = {xpc0[8:2],gbl_branch_hist[2:1]};		// write address
wire [8:0] bht_wa1 = {xpc1[8:2],gbl_branch_hist[2:1]};		// write address
wire [8:0] bht_raA = {pcA[8:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [8:0] bht_raB = {pcB[8:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [8:0] bht_raC = {pcC[8:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [8:0] bht_raD = {pcD[8:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [1:0] bht_xbits0 = branch_history_table[bht_wa0];
wire [1:0] bht_xbits1 = branch_history_table[bht_wa1];
wire [1:0] bht_ibitsA = branch_history_table[bht_raA];
wire [1:0] bht_ibitsB = branch_history_table[bht_raB];
wire [1:0] bht_ibitsC = branch_history_table[bht_raC];
wire [1:0] bht_ibitsD = branch_history_table[bht_raD];
assign predict_takenA = (bht_ibitsA==2'd0 || bht_ibitsA==2'd1) && en;
assign predict_takenB = (bht_ibitsB==2'd0 || bht_ibitsB==2'd1) && en;
assign predict_takenC = (bht_ibitsC==2'd0 || bht_ibitsC==2'd1) && en;
assign predict_takenD = (bht_ibitsD==2'd0 || bht_ibitsD==2'd1) && en;

// Two bit saturating counter
// If taking a branch in commit0 then a following branch
// in commit1 is never encountered. So only update for
// commit1 if commit0 is not taken.
reg [1:0] xbits_new0, xbits_new1;
always @(takb0 or takb1 or bht_xbits0 or bht_xbits1)
if (takb0) begin
	if (bht_xbits0 != 2'd1)
		xbits_new0 <= bht_xbits0 + 2'd1;
	else
		xbits_new0 <= bht_xbits0;
	xbits_new1 = bht_xbits1;
end
else begin
	if (bht_xbits0 != 2'd2)
		xbits_new0 <= bht_xbits0 - 2'd1;
	else
		xbits_new0 <= bht_xbits0;
    if (takb1) begin
        if (bht_xbits1 != 2'd1)
            xbits_new1 <= bht_xbits1 + 2'd1;
        else
            xbits_new1 <= bht_xbits1;
    end
    else begin
        if (bht_xbits1 != 2'd2)
            xbits_new1 <= bht_xbits1 - 2'd1;
        else
            xbits_new1 <= bht_xbits1;
    end
end

always @(posedge clk)
if (rst)
	gbl_branch_hist <= 3'b000;
else begin
    if (en) begin
        if (xisBranch0 & xisBranch1) begin
            if (takb0) begin
                gbl_branch_hist <= {gbl_branch_hist[1:0],takb0};
                branch_history_table[bht_wa0] <= xbits_new0;
            end
            else begin
                gbl_branch_hist <= {gbl_branch_hist[0],takb0,takb1};
                branch_history_table[bht_wa1] <= xbits_new1;
                branch_history_table[bht_wa0] <= xbits_new0;
            end
        end
        else if (xisBranch0) begin
            gbl_branch_hist <= {gbl_branch_hist[1:0],takb0};
            branch_history_table[bht_wa0] <= xbits_new0;
        end
        else if (xisBranch1) begin
            gbl_branch_hist <= {gbl_branch_hist[1:0],takb1};
            branch_history_table[bht_wa1] <= xbits_new1;
        end
	end
end

endmodule

