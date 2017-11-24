// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	VGASyncGen800x600_60Hz.v
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
//	WXGA video sync generator.
//
//	Input clock:     40.00 MHz (100 MHz * 12/30)
//	Horizontal freq: 37.9 kHz	(generated) (37.879 KHz)
//	Vertical freq:   60.32  Hz (generated)  (60.316 Hz)
//
//	This module generates the basic sync timing signals required for a
//	WXGA display.
//
// ============================================================================

module VGASyncGen800x600_60Hz(rst, clk, eol, eof, hSync, vSync, hCtr, vCtr, blank, border);
parameter phSyncOn  = 40;		//   40 front porch
parameter phSyncOff = 168;		//  128 sync
parameter phBlankOff = 256;		//   88 back porch
parameter phBorderOff = 262;	//   80 border
parameter phBorderOn = 902;		//  640 display
parameter phBlankOn = 908;		//   80 border
parameter phTotal = 908;		// 1056 total clocks
// 47.7 = 60 * 795 kHz
parameter pvSyncOn  = 1;		//    1 front porch
parameter pvSyncOff = 5;		//    4 vertical sync
parameter pvBlankOff = 28;		//   23 back porch
parameter pvBorderOff = 72;		//   44 border	0
parameter pvBorderOn = 584;		//  512 display
parameter pvBlankOn = 628;  	//   44 border	0
parameter pvTotal = 628;		//  628 total scan lines
// 60 Hz
// 1280x768
input rst;			// reset
input clk;			// video clock
output reg eol;
output reg eof;
output reg hSync, vSync;	// sync outputs
output [11:0] hCtr;
output [11:0] vCtr;
output blank;			// blanking output
output border;

//---------------------------------------------------------------------
//---------------------------------------------------------------------

wire vBlank, hBlank;
wire vBorder,hBorder;
wire hSync1,vSync1;
reg blank;
reg border;

wire eol1 = hCtr==phTotal;
wire eof1 = vCtr==pvTotal && eol;

assign vSync1 = vCtr >= pvSyncOn && vCtr < pvSyncOff;
assign hSync1 = hCtr >= phSyncOn && hCtr < phSyncOff;
assign vBlank = vCtr >= pvBlankOn || vCtr < pvBlankOff;
assign hBlank = hCtr >= phBlankOn || hCtr < phBlankOff;
assign vBorder = vCtr >= pvBorderOn || vCtr < pvBorderOff;
assign hBorder = hCtr >= phBorderOn || hCtr < phBorderOff;

counter #(12) u1 (.rst(rst), .clk(clk), .ce(1'b1), .ld(eol1), .d(12'd1), .q(hCtr), .tc() );
counter #(12) u2 (.rst(rst), .clk(clk), .ce(eol),  .ld(eof1), .d(12'd1), .q(vCtr), .tc() );

always @(posedge clk)
    blank <= #1 hBlank|vBlank;
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

endmodule

