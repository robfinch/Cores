//=============================================================================
//        __
//   \\__/ o\    (C) 2013-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//  
//	FT64x4_BranchPredictor.v
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
module FT64x4_BranchPredictor(rst, clk, en,
    xisBranch0, xisBranch1, xisBranch2, xisBranch3,
    pcA, pcB, pcC, pcD, pcE, pcF, pcG, pcH, xpc0, xpc1, xpc2, xpc3,
    takb0, takb1, takb2, takb3,
    predict_takenA, predict_takenB, predict_takenC, predict_takenD,
    predict_takenE, predict_takenF, predict_takenG, predict_takenH);
parameter DBW=32;
input rst;
input clk;
input en;
input xisBranch0;
input xisBranch1;
input xisBranch2;
input xisBranch3;
input [DBW-1:0] pcA;
input [DBW-1:0] pcB;
input [DBW-1:0] pcC;
input [DBW-1:0] pcD;
input [DBW-1:0] pcE;
input [DBW-1:0] pcF;
input [DBW-1:0] pcG;
input [DBW-1:0] pcH;
input [DBW-1:0] xpc0;
input [DBW-1:0] xpc1;
input [DBW-1:0] xpc2;
input [DBW-1:0] xpc3;
input takb0;
input takb1;
input takb2;
input takb3;
output predict_takenA;
output predict_takenB;
output predict_takenC;
output predict_takenD;
output predict_takenE;
output predict_takenF;
output predict_takenG;
output predict_takenH;

integer n;
reg [2:0] gbl_branch_hist;
reg [1:0] branch_history_table [511:0];
reg [31:0] pcs [0:31];
reg [31:0] pc;
reg [4:0] pcstail, pcshead;
reg wrhist;
reg takb;

// For simulation only, initialize the history table to zeros.
// In the real world we don't care.
initial begin
    gbl_branch_hist = 3'b000;
	for (n = 0; n < 512; n = n + 1)
		branch_history_table[n] = 3;
end
wire [8:0] bht_wa = {pc[8:2],gbl_branch_hist[2:1]};		// write address
wire [8:0] bht_raA = {pcA[8:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [8:0] bht_raB = {pcB[8:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [8:0] bht_raC = {pcC[8:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [8:0] bht_raD = {pcD[8:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [8:0] bht_raE = {pcE[8:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [8:0] bht_raF = {pcF[8:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [8:0] bht_raG = {pcG[8:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [8:0] bht_raH = {pcH[8:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [1:0] bht_xbits = branch_history_table[bht_wa];
wire [1:0] bht_ibitsA = branch_history_table[bht_raA];
wire [1:0] bht_ibitsB = branch_history_table[bht_raB];
wire [1:0] bht_ibitsC = branch_history_table[bht_raC];
wire [1:0] bht_ibitsD = branch_history_table[bht_raD];
wire [1:0] bht_ibitsE = branch_history_table[bht_raE];
wire [1:0] bht_ibitsF = branch_history_table[bht_raF];
wire [1:0] bht_ibitsG = branch_history_table[bht_raG];
wire [1:0] bht_ibitsH = branch_history_table[bht_raH];
assign predict_takenA = (bht_ibitsA==2'd0 || bht_ibitsA==2'd1) && en;
assign predict_takenB = (bht_ibitsB==2'd0 || bht_ibitsB==2'd1) && en;
assign predict_takenC = (bht_ibitsC==2'd0 || bht_ibitsC==2'd1) && en;
assign predict_takenD = (bht_ibitsD==2'd0 || bht_ibitsD==2'd1) && en;
assign predict_takenE = (bht_ibitsE==2'd0 || bht_ibitsE==2'd1) && en;
assign predict_takenF = (bht_ibitsF==2'd0 || bht_ibitsF==2'd1) && en;
assign predict_takenG = (bht_ibitsG==2'd0 || bht_ibitsG==2'd1) && en;
assign predict_takenH = (bht_ibitsH==2'd0 || bht_ibitsH==2'd1) && en;

// Rate converter

always @(posedge clk)
if (rst)
	pcstail <= 5'd0;
else begin
	if (xisBranch0 & xisBranch1 & xisBranch2 & xisBranch3) begin
		pcs[pcstail] <= {xpc0[31:1],takb0};
		pcs[pcstail+1] <= {xpc1[31:1],takb1};
		pcs[pcstail+2] <= {xpc2[31:1],takb2};
		pcs[pcstail+3] <= {xpc3[31:1],takb3};
		pcstail <= pcstail + 5'd4;
	end	
	else if (xisBranch0 & xisBranch1 & xisBranch2) begin
		pcs[pcstail] <= {xpc0[31:1],takb0};
		pcs[pcstail+1] <= {xpc1[31:1],takb1};
		pcs[pcstail+2] <= {xpc2[31:1],takb2};
		pcstail <= pcstail + 5'd3;
	end	
	if (xisBranch0 & xisBranch1 & xisBranch3) begin
		pcs[pcstail] <= {xpc0[31:1],takb0};
		pcs[pcstail+1] <= {xpc1[31:1],takb1};
		pcs[pcstail+2] <= {xpc3[31:1],takb3};
		pcstail <= pcstail + 5'd3;
	end	
	if (xisBranch0 & xisBranch2 & xisBranch3) begin
		pcs[pcstail] <= {xpc0[31:1],takb0};
		pcs[pcstail+1] <= {xpc2[31:1],takb2};
		pcs[pcstail+2] <= {xpc3[31:1],takb3};
		pcstail <= pcstail + 5'd3;
	end	
	if (xisBranch1 & xisBranch2 & xisBranch3) begin
		pcs[pcstail] <= {xpc1[31:1],takb1};
		pcs[pcstail+1] <= {xpc2[31:1],takb2};
		pcs[pcstail+2] <= {xpc3[31:1],takb3};
		pcstail <= pcstail + 5'd3;
	end	
	else if (xisBranch0 & xisBranch1) begin
		pcs[pcstail] <= {xpc0[31:1],takb0};
		pcs[pcstail+1] <= {xpc1[31:1],takb1};
		pcstail <= pcstail + 5'd2;
	end
	else if (xisBranch0 & xisBranch2) begin
		pcs[pcstail] <= {xpc0[31:1],takb0};
		pcs[pcstail+1] <= {xpc2[31:1],takb2};
		pcstail <= pcstail + 5'd2;
	end
	else if (xisBranch0 & xisBranch3) begin
		pcs[pcstail] <= {xpc0[31:1],takb0};
		pcs[pcstail+1] <= {xpc3[31:1],takb3};
		pcstail <= pcstail + 5'd2;
	end
	else if (xisBranch1 & xisBranch2) begin
		pcs[pcstail] <= {xpc1[31:1],takb1};
		pcs[pcstail+1] <= {xpc2[31:1],takb2};
		pcstail <= pcstail + 5'd2;
	end
	else if (xisBranch1 & xisBranch3) begin
		pcs[pcstail] <= {xpc1[31:1],takb1};
		pcs[pcstail+1] <= {xpc3[31:1],takb3};
		pcstail <= pcstail + 5'd2;
	end
	else if (xisBranch2 & xisBranch3) begin
		pcs[pcstail] <= {xpc2[31:1],takb2};
		pcs[pcstail+1] <= {xpc3[31:1],takb3};
		pcstail <= pcstail + 5'd2;
	end
	else if (xisBranch0) begin
		pcs[pcstail] <= {xpc0[31:1],takb0};
		pcstail <= pcstail + 5'd1;
	end
	else if (xisBranch1) begin
		pcs[pcstail] <= {xpc1[31:1],takb1};
		pcstail <= pcstail + 5'd1;
	end
	else if (xisBranch2) begin
		pcs[pcstail] <= {xpc2[31:1],takb2};
		pcstail <= pcstail + 5'd1;
	end
	else if (xisBranch3) begin
		pcs[pcstail] <= {xpc3[31:1],takb3};
		pcstail <= pcstail + 5'd1;
	end
end

always @(posedge clk)
if (rst)
	pcshead <= 5'd0;
else begin
	wrhist <= 1'b0;
	if (pcshead != pcstail) begin
		pc <= pcs[pcshead];
		takb <= pcs[pcshead][0];
		wrhist <= 1'b1;
		pcshead <= pcshead + 5'd1;
	end
end

// Two bit saturating counter
// If taking a branch in commit0 then a following branch
// in commit1 is never encountered. So only update for
// commit1 if commit0 is not taken.
reg [1:0] xbits_new;
always @*
if (takb & wrhist) begin
	if (bht_xbits != 2'd1)
		xbits_new <= bht_xbits + 2'd1;
	else
		xbits_new <= bht_xbits;
end
else begin
	if (bht_xbits != 2'd2)
		xbits_new <= bht_xbits - {1'b0,wrhist};
	else
		xbits_new <= bht_xbits;
end

always @(posedge clk)
if (rst)
	gbl_branch_hist <= 3'b000;
else begin
    if (en) begin
        if (wrhist) begin
            gbl_branch_hist <= {gbl_branch_hist[1:0],takb};
            branch_history_table[bht_wa] <= xbits_new;
        end
	end
end

endmodule

