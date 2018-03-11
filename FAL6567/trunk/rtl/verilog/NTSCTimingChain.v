// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
//	NTSCTimingChain.v
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
//  520 8.18MHz pixels on a scanline, is 227.5 color clocks.
//	2080 @32.73MHz is 227.5 color clocks
//  3.58MHz = 14.31818 / 4
//  8.18MHz = 14.31818 / 14 * 8
//  32.73MHz = 14.31818 * 16 / 7
//
//    Notes:
//
//	4.5 x 455/572
//	Line Rate = 4.5 MHz / 286 = 15734.26573 (Choosen to fit in with audio
//	subcarrier.
//	Line Rate / 60 = 59.94005992
//
//	525 = 3x3x5x7
//
//	Vertical Interval Reference: line #19
//	70% luma, chrominance match
//	50% luma
//	7.5 luma
//
//	3.14159265358_979
//	
//	Front Porch:  1.8 us
//	Back Porch:   5.1 us
//	Sync:         4.6 us
//	Left Border:  8.3 us
//	Right Border: 8.3 us
//
//	Burst: 3.579545
//	A burst of 3.555555 = 96/27
//
//	32.7272 MHz in / 15734.26573 = 2080
//
//                                            
//	The number of lines in the NTSC standard is defined as 262.5 per frame
//	and is not controllable.	
// ============================================================================
//
module NTSCTimingChain(rst, clk, clk57, eol, eof, lineCount, clockCount, 
	pixndx, pixwndx, pixw,
	row, col, phoff,
	field,
	HS, VS, EQ, SE, CS, vblnk, hbln, burst_window,
	VDA, HDA, DA
);
parameter SCANLENGTH=16'd2080;	// 32.727 MHz

input rst;						// reset
input clk;						// clock
input clk57;
output eol;						// end of line
output eof;						// end of frame
output [15:0] clockCount;		// counting clocks to full scan length
output [11:0] lineCount;		// line count
output [ 4:0] pixndx;			// index of pixel within byte (0 to 7)
output [ 4:0] pixwndx;			// index of clock within pixel
input  [ 4:0] pixw;				// pixel width in clocks
output [ 7:0] row;				// display row
output [ 7:0] col;				// display column
output [ 4:0] phoff;			// phase offset
output field;					// odd / even field
output HS;						// horizontal sync
output VS;						// vertical sync
output EQ;						// equalization pulse
output SE;						// serration pulse
output CS;						// composite sync
output [3:0] BRST;				// burst output
output vblnk;					// vertical blank
output hbln;					// horizontal blank
output burst_window;
output VDA;						// vertical display active area
output HDA;						// horizontal display active area
output DA;						// display active

reg field;
reg CS;

reg ntscAct;
assign VS = lineCount==12'd3 || lineCount==12'd4 || lineCount==12'd5;
assign vblnk = lineCount < 9'd21;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Video Timing Chain
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

wire fullScan = (clockCount==SCANLENGTH);
wire halfScan = (clockCount==(SCANLENGTH/2));

assign hbln =
	(clockCount < 16'd312) ||		// 15%
	(clockCount > 16'd2022);		// 97.2%
// display = 1710

// End of scan line
// During the odd frame, scan line #8 is terminated one-half scan line
// early.
// Similarly, on the even field, line #263 is terminated one-half scan line
// early.
// The effect of this is to adjust the sync position and thus the line
// position by one half of a scan line, creating an interlaced display.
// Odd and even frames are then both 262.5 scans long.
//
assign eol =
	 fullScan ||	// full scan line
	 (field && lineCount==9'd008 && halfScan) ||
	(!field && lineCount==9'd262 && halfScan)
	;

// End of frame
//
assign eof = eol && (lineCount==12'd262);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Full scan line length counter.
// Count the clocks for a scan line.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
VT163 #(16) u1
(
	.clk(clk),
	.clr_n(!rst),
	.ent(1'b1),
	.enp(1'b1),
	.ld_n(!eol),
	.d(16'd1),
	.q(clockCount),
	.rco()
);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Line counter
// Count the number of video scan lines
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
VT163 #(12) u2
(
	.clk(clk),
	.clr_n(!rst),
	.ent(eol),
	.enp(1'b1),
	.ld_n(!eof),
	.d(12'd0),
	.q(lineCount),
	.rco()
);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Pixel width counter
// - counts the clocks in a pixel
// Standard Pixel is 4 clocks wide
// = 65 chars (40 visble)
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
wire nxtPx = pixwndx==pixw;
VT163 #(5) upw
(
	.clk(clk),
	.clr_n(!rst),
	.ent(1'b1),
	.enp(1'b1),
	.ld_n(!(nxtPx|eol)),
	.d(5'd00),
	.q(pixwndx),
	.rco()
);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Pixel index counter
// - counts the pixels in a character
// Provides count of up to 32 pixels
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//	wire nxtCh = (lineCount[7:4]==4'd2 || lineCount==4'd3) ? pixndx==5'd31 : pixndx==5'd7;
wire nxtCh = pixndx==5'd7;
VT163 #(5) upn
(
	.clk(clk),
	.clr_n(!rst),
	.ent(nxtPx),
	.enp(1'b1),
	.ld_n(!((nxtCh & nxtPx)|eol)),
	.d(8'd00),
	.q(pixndx),
	.rco()
);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Column counter
// - counts the column number of the display
// Synchronized to the start of the line.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
VT163 #(8) ucc
(
	.clk(clk),
	.clr_n(!rst),
	.ent(nxtPx & nxtCh),
	.enp(1'b1),
	.ld_n(!eol),
	.d(8'd253),
	.q(col),
	.rco()
);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Colour burst frequency generator
// NTSC Burst is 3.579565 MHz;
// 57.272727 / 16 = 3.579545
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

wire [3:0] bcnt;				// burst counter

VT163 #(4) ubrst
(
	.clk(clk57),
	.clr_n(!rst),
	.ent(1'b1),
	.enp(1'b1),
	.ld_n(!(bcnt == 4'd15)),
	.d(4'd0),
	.q(bcnt),
	.rco()
);

//	assign BRST = bcnt;
// Output Burst is inverted every other line as lines are 1/2 a burst clock in remainder
// However the burst clock in continuously running; it's the scan line length that causes
// the apparent inversion. During one scan line bcnt will be zero; during the next scan
// line bcnt will be eight when the burst is enabled.
//
always@(bcnt)
	case(bcnt)
	4'd0:	BRST = 4'd9;
	4'd1:	BRST = 4'd11;
	4'd2:	BRST = 4'd11;
	4'd3:	BRST = 4'd12;
	4'd4:	BRST = 4'd11;
	4'd5:	BRST = 4'd11;
	4'd6:	BRST = 4'd9;
	4'd7:	BRST = 4'd9;
	4'd8:	BRST = 4'd9;
	4'd9:	BRST = 4'd7;
	4'd10:	BRST = 4'd7;
	4'd11:	BRST = 4'd6;
	4'd12:	BRST = 4'd7;
	4'd13:	BRST = 4'd7;
	4'd14:	BRST = 4'd9;
	4'd15:	BRST = 4'd9;
	endcase

assign phoff = bcnt - pixwndx;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Odd / Even display field indicator
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

always @(posedge clk)
	if (rst)
		field <= 1'b0;
	else if (eof)
		field <= !field;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Composite sync combiner
// - sync components calculated based on the SCAN time.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
assign burst_window = clockCount >=16'd192 && clockCount <= (16'd192 + 16'd80);// && !vblnk;

assign HS =
	clockCount  < (SCANLENGTH *  8 / 100);	//  8% tH

assign EQ =		//  4% tH equalization width
	(clockCount < (SCANLENGTH * 4 / 100)) ||
	(
		(clockCount >= (SCANLENGTH * 50 / 100)) &&
		(clockCount < (SCANLENGTH * 54 / 100))
	)
	;

assign SE =		// 93% tH (7%tH) (3051-427)
	(clockCount < (SCANLENGTH * 43 / 100)) ||
	(	
		(clockCount >= (SCANLENGTH *50 / 100)) &&
	 	(clockCount < (SCANLENGTH * 93 / 100))
	)
	;


always @(lineCount or EQ or SE or HS)
	case(lineCount)
	12'd0:	CS <= EQ;
	12'd1:	CS <= EQ;
	12'd2:	CS <= EQ;
	12'd3:	CS <= SE;
	12'd4:	CS <= SE;
	12'd5:	CS <= SE;
	12'd6:	CS <= EQ;
	12'd7:	CS <= EQ;
	12'd8:	CS <= EQ;
	default:
			CS <= HS;
	endcase

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
assign VDA = lineCount > 12'd21 && lineCount < 12'd253;	// vertical active area (232 scan lines)
assign HDA = clockCount > SCANLENGTH * 14 / 100 && clockCount < SCANLENGTH * 98 / 100;
assign DA  = VDA & HDA;

wire [11:0] lc = lineCount - 12'd22;
assign row = lc[7:5];

endmodule

module NTSCTimingChain_tb();
reg clk;
reg clk57;
reg rst;

initial begin
	clk57 = 1;
	clk = 1;
	rst = 0;
	#100 rst = 1;
	#100 rst = 0;
end

always #15.2777777 clk = ~clk;		// 32.7272727 MHz
always #8.73015877 clk57 = ~clk57;	//  57.2727272 MHz

NTSCTimingChain u1
(
	.rst(rst),
	.clk(clk),
	.clk57(clk57),
	.eol(),
	.eof(),
	.lineCount(),
	.clockCount(), 
	.pixndx(),
	.pixwndx(),
	.pixw(5'd3),
	.row(),
	.col(),
	.phoff(),
	.field(),
	.HS(),
	.VS(),
	.EQ(),
	.SE(),
	.CS(),
	.BRST(),
	.vblnk(),
	.hbln(),
	.burst_window(),
	.VDA(),
	.HDA(),
	.DA()
);

endmodule
