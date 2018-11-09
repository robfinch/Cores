// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	VGASyncGen.v
//		VGA sync generator
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
//
//	VGA video sync generator.
//
//	This module generates the basic sync timing signals required for a
//	VGA display.
//
// ============================================================================

module VGASyncGen(rst, clk, eol, eof, hSync, vSync, hCtr, vCtr,
    blank, vblank, vbl_int, border,
    hTotal_i, vTotal_i,
    hSyncOn_i, hSyncOff_i, vSyncOn_i, vSyncOff_i,
    hBlankOn_i, hBlankOff_i, vBlankOn_i, vBlankOff_i,
    hBorderOn_i, vBorderOn_i, hBorderOff_i, vBorderOff_i);
input rst;			// reset
input clk;			// video clock
output reg eol;
output reg eof;
output reg hSync, vSync;	// sync outputs
output [11:0] hCtr;
output [11:0] vCtr;
output reg blank;		// blanking output
output reg vblank;
output reg vbl_int;
output border;
input [11:0] hTotal_i;
input [11:0] vTotal_i;
input [11:0] hSyncOn_i;
input [11:0] hSyncOff_i;
input [11:0] vSyncOn_i;
input [11:0] vSyncOff_i;
input [11:0] hBlankOn_i;
input [11:0] hBlankOff_i;
input [11:0] vBlankOn_i;
input [11:0] vBlankOff_i;
input [11:0] hBorderOn_i;
input [11:0] hBorderOff_i;
input [11:0] vBorderOn_i;
input [11:0] vBorderOff_i;

//---------------------------------------------------------------------
//---------------------------------------------------------------------

wire vBlank1, hBlank1;
wire vBorder,hBorder;
wire hSync1,vSync1;
reg border;

wire eol1 = hCtr==hTotal_i;
wire eof1 = vCtr==vTotal_i;

assign vSync1 = vCtr >= vSyncOn_i && vCtr < vSyncOff_i;
assign hSync1 = hCtr >= hSyncOn_i && hCtr < hSyncOff_i;
assign vBlank1 = ~(vCtr < vBlankOn_i && vCtr >= vBlankOff_i);
assign hBlank1 = ~(hCtr < hBlankOn_i && hCtr >= hBlankOff_i);
assign vBorder = ~(vCtr < vBorderOn_i && vCtr >= vBorderOff_i);
assign hBorder = ~(hCtr < hBorderOn_i && hCtr >= hBorderOff_i);

counter #(12) u1 (.rst(rst), .clk(clk), .ce(1'b1), .ld(eol1), .d(12'd1), .q(hCtr), .tc() );
counter #(12) u2 (.rst(rst), .clk(clk), .ce(eol1),  .ld(eof1), .d(12'd1), .q(vCtr), .tc() );

always @(posedge clk)
    blank <= #1 hBlank1|vBlank1;
always @(posedge clk)
    vblank <= #1 vBlank1;
always @(posedge clk)
    border <= #1 hBorder|vBorder;
always @(posedge clk)
	hSync <= #1 hSync1;
always @(posedge clk)
	vSync <= #1 vSync1;
always @(posedge clk)
    eof <= eof1;
always @(posedge clk)
    eol <= eol1;
always @(posedge clk)
    vbl_int <= hCtr==12'd8 && vCtr==12'd1;

endmodule

