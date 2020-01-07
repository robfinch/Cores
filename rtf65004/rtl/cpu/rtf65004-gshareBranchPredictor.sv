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
`include "rtf65004-config.sv"

module gshareBranchPredictor(rst, clk, clk2x, clk4x, en, xisBranch, xip, takb, ip, predict_taken);
parameter AMSB=63;
parameter DBW=64;
parameter FSLOTS = `FSLOTS;
parameter TBLSZ = 4096;
localparam TBIT = $clog2(TBLSZ)-5;
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
reg [AMSB+1:0] pc;
reg takbx;
reg [4:0] pcshead,pcstail;
reg wrhist;
reg [TBIT:0] gbl_branch_hist;
(* ram_style="distributed" *)
reg [1:0] branch_history_table [0:TBLSZ-1];

// For simulation only, initialize the history table to zeros.
// In the real world we don't care.
initial begin
  gbl_branch_hist = 5'b0;
	for (n = 0; n < TBLSZ; n = n + 1) begin
		branch_history_table[n] = 2'h3;
	end
end
wire [4:0] bht_wa = pc[4:0];		// write address
wire [TBIT-1:0] bht_wan = gbl_branch_hist[TBIT:1]^pc[5+TBIT-1:5]^pc[5+TBIT+TBIT-1:5+TBIT]^pc[5+TBIT+TBIT+TBIT-1:5+TBIT+TBIT];
wire [1:0] bht_xbits;
assign bht_xbits = branch_history_table[{bht_wan,bht_wa}];
reg [4:0] bht_ra [0:FSLOTS-1];
reg [TBIT-1:0] bht_ran [0:FSLOTS-1];
reg [1:0] bht_ibits [0:FSLOTS-1];
always @*
for (n = 0; n < FSLOTS; n = n + 1) begin
	bht_ra [n] = ip[n][4:0];	// read address (IF stage)
	bht_ran[n] = gbl_branch_hist[TBIT:1]^ip[n][5+TBIT-1:5]^ip[n][5+TBIT+TBIT-1:5+TBIT]^ip[n][5+TBIT+TBIT+TBIT-1:5+TBIT+TBIT];
	bht_ibits [n] = branch_history_table[{bht_ran[n],bht_ra[n]}];
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
		pc <= pcs[pcshead];
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

always @(posedge clk)
if (rst)
	gbl_branch_hist <= {TBIT+1{1'b0}};
else begin
  if (en) begin
    if (wrhist) begin
      gbl_branch_hist <= {gbl_branch_hist[TBIT-1:0],takbx};
      branch_history_table[{bht_wan,bht_wa}] <= xbits_new;
    end
	end
end

endmodule

