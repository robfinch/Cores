// ============================================================================
//        __
//   \\__/ o\    (C) 2002-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	RGB2YIQ3.v
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
//	RGB to COMPOSITE COLOR SPACE CONVERTER
//	converts 24 bit RGB to Composite
//
//	To convert RGB to composite the conversion is done in two
//	steps. First RGB is converted to YIQ then YIQ is converted
//	to composite.
//	
//	Converting RGB to YIQ
//	---------------------
//	The following equations convert the RGB color space to YIQ
//	Y = 30% red, 11% blue, and 59% green
//	I = 60% red, -32% blue, -28% green
//	Q = 21% red, 31% blue, -52% green
//	
//	Y = 19R + 7B + 38G	// scaled to 64th's
//	I = 38R - 20B - 18G
//	Q = 13R + 20B - 33G
//	
//	Note that since each of R,G, and B use only eight bits there
//	is a built in error term of about 0.4%
//	The percentage operation is performed by first multiplying the
//	component (R,G or B) by an integer scaled to give the percentage
//	as a ratio, then dividing by the scale. Eg. 30%=154/512. 512 was
//	choosen as the scaling unit because this gives results within
//	0.2% which is half the error of the incoming R,G,B. Also we
//	want to divide by shifting, so the scale must be a multiple of
//	two. All this multiplying and dividing is relatively easy to
//	do because we are dealing with constant values. The
//	multiplications can be done by shifting and adding by constant
//	amounts.
//	
//	Converting YIQ to composite
//	---------------------------
//	This conversion requires the use of a modulation subcarrier
//	frequency.
//	Composite = Y + IM + QM, where IM, QM are a modulated 3.58MHz
//	color subcarrier signal.
//	The Q signal modulates a 3.58MHz carrier that is phase shifted
//	90 deg. from the I modulated carrier. Otherwise the modulation
//	is performed in the same fashion.
//	The Y signal is used directly.
//	The composite output is the sum of the Y plus the I and Q
//	modulated 3.58MHz signals.
//	IM = I * clock (0' phase shift mod 3.58MHz)
//		1.5MHz bandwidth - direct AM modulation
//	QM = Q * clock (90' phase shift 3.58MHz)
//		0.5MHz bandwidth - direct AM modulation
//
// ============================================================================
//
// Might want to adjust this to also account for sync and
// blanking levels
`define DC_OFFSET		11'd1178		// -38 * 31

`define SYNC_LEVEL		12'd0			// neg. sync
`define BLANK_LEVEL		12'd400
`define BURST_LEVEL		12'd450
`define BURST_STRENGTH	9
`define SIGNAL_LEVEL	`BLANK_LEVEL + `DC_OFFSET

module RGB2Composite(clk, ph, r, g, b, co);
input clk;		// synchronizing clock 57.27272MHz
input [3:0] ph;	// clock phase 3.58MHz ref (22.5 deg. inc.)
input [7:0] r;	// red input
input [7:0] g;	// green input
input [7:0] b;	// blue input

// Only 13 bits are useful for composite output
// (13 bits = 512*5 bits + 1 extra for rounding). However
// this signal will also need to have sync and blanking levels
// added.
output reg [12:0] co;// composite output

reg [6:0] i;
reg [6:0] q;
reg signed [5:0] sin;	// sin of angle
reg signed [5:0] sin90;	// 90 deg. phase shift sin
reg [24:0] co1;


// Even though only nine bits are required for the desired
// accuracy, a couple of extra bits are preserved in the
// calculations to enhance accuracy.

// Y generation
wire [16:0] ry = r * 9'd154;			// 0.3 * R
wire [16:0] by = b * 9'd56;				// 0.11 * B
wire [16:0] gy = g * 9'd302;			// 0.59 * G
wire [18:0] y1 = (ry + by + gy);

wire [8:0] y = y1[10:3];

// I generation
wire [16:0] ri = r * 9'd307;			// 0.60 * R
wire [16:0] bi = b * 9'd164;			// 0.32 * B
wire [16:0] gi = g * 9'd143;			// 0.28 * G
wire [18:0] i2 = (ri - bi - gi);	// result could be -38 to +38
wire [8:0] i1 = i2[11:3];			// preserves sign

// Q generation
wire [16:0] rq = r * 9'd108;			// 0.21 * R
wire [16:0] bq = b * 9'd159;				// 0.31 * b
wire [16:0] gq = g * 9'd266;			// 0.52 * g
wire [18:0] q2 = (rq + bq - gq);	// result could be -33 to +33
wire [8:0] q1 = q2[11:3];

// IM and QM generation
// im and qm are modulated i and q signals, where the i, q
// modulation is the result of multiplying by a sine wave
// that varies in amplitude from -31 to +31. To keep the
// y signal on the same scale it is also multiplied by
// 32.
reg signed [24:0] im;
reg signed [24:0] qm;
reg signed [24:0] ym;
reg signed [24:0] im2;	// modulation results - complex
reg signed [24:0] qm2;
reg signed [24:0] ym2;

always @(posedge clk)
	im2 <= $signed(i2) * $signed(sin);
always @(posedge clk)
	qm2 <= $signed(q2) * $signed(sin90);
always @(posedge clk)
	ym2 <= ym << 5;		// keep ym the same scale

// phase delay color subcarrier by 90 deg (4 clocks)
reg [3:0] ph90;
always @(posedge clk)
	ph90 <= {ph90[2:0],ph[3]};

always @*
begin
	ym <= ym2;
	im <= im2;
	qm <= qm2;
end

// A simple sin lookup table is used because there are only
// 16 values needed, (assuming a 16x 3.58MHz (57.28MHz) clock
// is in use). To get a smoother curve a much higher clock
// frequency is required, which isn't practical.
always @(ph) begin
	case (ph)
	4'h0:	sin <= 0;
	4'h1:	sin <= 12;
	4'h2:	sin <= 22;
	4'h3:	sin <= 29;
	4'h4:	sin <= 31;
	4'h5:	sin <= 29;
	4'h6:	sin <= 22;
	4'h7:	sin <= 12;
	4'h8:	sin <= 0;
	4'h9:	sin <= -12;
	4'ha:	sin <= -22;
	4'hb:	sin <= -29;
	4'hc:	sin <= -31;
	4'hd:	sin <= -29;
	4'he:	sin <= -22;
	4'hf:	sin <= -12;
	endcase
	case (ph-4)
	4'h0:	sin90 <= 0;
	4'h1:	sin90 <= 12;
	4'h2:	sin90 <= 22;
	4'h3:	sin90 <= 29;
	4'h4:	sin90 <= 31;
	4'h5:	sin90 <= 29;
	4'h6:	sin90 <= 22;
	4'h7:	sin90 <= 12;
	4'h8:	sin90 <= 0;
	4'h9:	sin90 <= -12;
	4'ha:	sin90 <= -22;
	4'hb:	sin90 <= -29;
	4'hc:	sin90 <= -31;
	4'hd:	sin90 <= -29;
	4'he:	sin90 <= -22;
	4'hf:	sin90 <= -12;
	endcase
end

always @(posedge clk) begin
	co1 <= im + qm + ym;
	// Last step: create uni-polar output by adding in the
	// maximum negative offset (31*-38) that could occur.
	co <= $signed(co1[24:20]) + $signed(5'd16);
end

endmodule

