//=============================================================================
//        __
//   \\__/ o\    (C) 2013-2019  Robert Finch, Waterloo
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
// g-share predictor
//
//=============================================================================
//
`include "rtfItanium-config.sv"

module gsBranchPredictor(rst, clk, clk2x, clk4x, en, xisBranch, xip, takb, ip, predict_taken);
parameter AMSB=79;
parameter DBW=80;
parameter QSLOTS = `QSLOTS;
input rst;
input clk;
input clk2x;
input clk4x;
input en;
input [3:0] xisBranch;
input [AMSB:0] xip [0:3];
input [3:0] takb;
input [AMSB:0] ip [0:QSLOTS-1];
output reg [QSLOTS-1:0] predict_taken;

integer n;

reg [AMSB:0] pcs [0:31];
reg [AMSB:0] pc;
reg takbx;
reg [4:0] pcshead,pcstail;
reg wrhist;
reg [5:0] gbl_branch_hist;
reg [1:0] branch_history_table [1023:0];
// For simulation only, initialize the history table to zeros.
// In the real world we don't care.
initial begin
  gbl_branch_hist = 5'b0;
	for (n = 0; n < 1024; n = n + 1)
		branch_history_table[n] = 3;
end
wire [9:0] bht_wa = {pc[6:2],gbl_branch_hist[5:1]^pc[11:7]};		// write address
wire [1:0] bht_xbits = branch_history_table[bht_wa];
reg [9:0] bht_ra [0:QSLOTS-1];
reg [1:0] bht_ibits [0:QSLOTS-1];
always @*
for (n = 0; n < QSLOTS; n = n + 1) begin
	bht_ra [n] = {ip[n][6:2],gbl_branch_hist[5:1]^ip[n][11:7]};	// read address (IF stage)
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
		pcs[pcstail] <= {xipx[AMSB:1],xtkb};
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
		takbx <= pcs[pcshead][0];
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
	gbl_branch_hist <= 6'b0;
else begin
  if (en) begin
    if (wrhist) begin
      gbl_branch_hist <= {gbl_branch_hist[4:0],takbx};
      branch_history_table[bht_wa] <= xbits_new;
    end
	end
end

endmodule

