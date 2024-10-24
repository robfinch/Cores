//=============================================================================
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
//=============================================================================
//
`include "rtf65004-config.sv"

module BranchPredictor(rst, clk, clk2x, clk4x, en, xisBranch, xip, takb, ip, predict_taken);
parameter AMSB=63;
parameter DBW=16;
parameter FSLOTS = `FSLOTS;
input rst;
input clk;
input clk2x;
input clk4x;
input en;
input [3:0] xisBranch;
input [AMSB:0] xip [0:3];
input [3:0] takb;
input [AMSB:0] ip [0:FSLOTS-1];
output reg [FSLOTS-1:0] predict_taken;

integer n;

reg [AMSB+1:0] pcs [0:31];
reg [AMSB:0] pc = 1'd0;
reg takbx;
reg [4:0] pcshead,pcstail;
reg wrhist;
reg [2:0] gbl_branch_hist;
reg [1:0] branch_history_table [511:0];
// For simulation only, initialize the history table to zeros.
// In the real world we don't care.
initial begin
    gbl_branch_hist = 3'b000;
	for (n = 0; n < 512; n = n + 1)
		branch_history_table[n] = 3;
end
wire [8:0] bht_wa = {pc[6:0],gbl_branch_hist[2:1]};		// write address
wire [1:0] bht_xbits = branch_history_table[bht_wa];
reg [8:0] bht_ra [0:FSLOTS-1];
reg [1:0] bht_ibits [0:FSLOTS-1];
always @*
for (n = 0; n < FSLOTS; n = n + 1) begin
	bht_ra [n] = {ip[n][6:0],gbl_branch_hist[2:1]};	// read address (IF stage)
	bht_ibits [n] = branch_history_table[bht_ra[n]];
	predict_taken[n] = (bht_ibits[n]==2'd0 || bht_ibits[n]==2'd1) && en;
end

reg xisBr;
reg xtkb;
reg [AMSB:0] xipx;
always @*
begin
	xisBr <= xisBranch[{clk,clk2x}];
	xtkb <= takb[{clk,clk2x}];
	xipx <= xip[{clk,clk2x}];
end

always @(posedge clk4x)
if (rst)
	pcstail <= 5'd0;
else begin
	if (xisBr) begin
		pcs[pcstail] <= {xtkb,xipx[AMSB:0]};
		pcstail <= pcstail + 5'd1;
	end
end

always @(posedge clk)
if (rst)
	pcshead <= 5'd0;
else begin
	wrhist <= 1'b0;
	if (pcshead != pcstail) begin
		pc <= pcs[pcshead][AMSB:0];
		takbx <= pcs[pcshead][AMSB+1];
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
if (wrhist) begin
	if (takbx) begin
		if (bht_xbits != 2'd1)
			xbits_new <= bht_xbits + 2'd1;
		else
			xbits_new <= bht_xbits;
	end
	else begin
		if (bht_xbits != 2'd2)
			xbits_new <= bht_xbits - 2'd1;
		else
			xbits_new <= bht_xbits;
	end
end
else
	xbits_new <= bht_xbits;

always @(posedge clk)
if (rst)
	gbl_branch_hist <= 3'b000;
else begin
  if (en) begin
    if (wrhist) begin
      gbl_branch_hist <= {gbl_branch_hist[1:0],takbx};
      branch_history_table[bht_wa] <= xbits_new;
    end
	end
end

endmodule

