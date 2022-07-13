// ============================================================================
//        __
//   \\__/ o\    (C) 2002-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	RGB2Composite.sv
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                
// ============================================================================
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
module RGB2Composite(clk, ph, colorBurst, colorBurstWindow, cSync, cBlank, r, g, b, co, yo, iq);
input clk;		// synchronizing clock 57.27272MHz
input [3:0] ph;	// clock phase 3.58MHz ref (22.5 deg. inc.)
input colorBurst;
input colorBurstWindow;
input cSync;
input cBlank;
input [7:0] r;	// red input
input [7:0] g;	// green input
input [7:0] b;	// blue input
output reg [4:0] co;	// composite output
output reg [3:0] yo;
output reg [3:0] iq;

reg signed [5:0] sin;	// sin of angle
reg signed [5:0] sin90;	// 90 deg. phase shift sin
reg [24:0] co1,co2;
reg [5:0] sinp31, sin90p31;

// Even though only nine bits are required for the desired
// accuracy, a couple of extra bits are preserved in the
// calculations to enhance accuracy.

// Y generation
reg [16:0] ry, by, gy, y;
always_ff @(posedge clk)
	ry <= r * 9'd153;		// 0.30 * R
always_ff @(posedge clk)
	by <= b * 9'd56;			// 0.11 * B
always_ff @(posedge clk)
	gy <= g * 9'd302;		// 0.59 * G
always_ff @(posedge clk)
	y <= (ry + by + gy);		// won't be more than 511*

// I generation
reg [16:0] ri, bi, gi, i;
always_ff @(posedge clk)
	ri <= r * 9'd307;		// 0.60 * R
always_ff @(posedge clk)
	bi <= b * 9'd164;		// 0.32 * B
always_ff @(posedge clk)
	gi <= g * 9'd143;		// 0.28 * G
always_ff @(posedge clk)
	i <= (ri - bi - gi) + 9'd307;		// max 0.60 * 512 = +/-307

// Q generation
reg [16:0] rq, bq, gq, q;
always_ff @(posedge clk)
	rq <= r * 9'd108;		// 0.21 * R
always_ff @(posedge clk)
	bq <= b * 9'd159;		// 0.31 * b
always_ff @(posedge clk)
	gq <= g * 9'd266;		// 0.52 * g
always_ff @(posedge clk)
	q <= (rq + bq - gq) + 9'd266;		// mac 0.52 * 512 = +/-266

// IM and QM generation
// im and qm are modulated i and q signals, where the i, q
// modulation is the result of multiplying by a sine wave
// that varies in amplitude from -31 to +31. To keep the
// y signal on the same scale it is also multiplied by
// 32.
reg [22:0] im;
reg [22:0] qm;
reg [22:0] ym;
reg [22:0] iq1;
reg [22:0] yo1;

always_ff @(posedge clk)
	im <= i * sinp31;
always_ff @(posedge clk)
	qm <= q * sin90p31;
always_ff @(posedge clk)
	ym <= y * 48;		// keep ym the same scale

// A simple sin lookup table is used because there are only
// 16 values needed, (assuming a 16x 3.58MHz (57.28MHz) clock
// is in use). To get a smoother curve a much higher clock
// frequency is required, which isn't practical.
always_comb begin
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
always_ff @(posedge clk)
	sinp31 <= sin + 6'd31;
always_ff @(posedge clk)
	sin90p31 <= sin90 + 6'd31;

always_ff @(posedge clk) begin
	// Last step: create uni-polar output by adding in the
	// maximum negative offset that could occur.
	co1 <= im + qm + ym;
	if (!cBlank)
		co <= ((co1[24:19] + 8) * 24) >> 5;
	else
		co <= (cSync * 8) + (colorBurstWindow ? ((sinp31 >> 2) - 6) : 0);
//		co <= (cSync * 6) + (colorBurstWindow ? $signed((colorBurst * 8) - 4) : 0);
	iq1 <= im + qm;
	iq <= iq1[22:19];
	yo1 <= ym;
	if (!cBlank)
		yo <= yo1[22:19] + 4;
	else
		yo <= (cSync * 3) + (colorBurstWindow ? ((sinp31 >> 2) - 2) : 0);
end

endmodule
