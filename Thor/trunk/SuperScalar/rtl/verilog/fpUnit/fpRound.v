/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca

	fpRound.v
		- floating point rounding unit
		- parameterized width
		- IEEE 754 representation

	This source code is free for use and modification for
	non-commercial or evaluation purposes, provided this
	copyright statement and disclaimer remains present in
	the file.

	If the code is modified, please state the origin and
	note that the code has been modified.

	NO WARRANTY.
	THIS Work, IS PROVIDEDED "AS IS" WITH NO WARRANTIES OF
	ANY KIND, WHETHER EXPRESS OR IMPLIED. The user must assume
	the entire risk of using the Work.

	IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
	ANY INCIDENTAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES
	WHATSOEVER RELATING TO THE USE OF THIS WORK, OR YOUR
	RELATIONSHIP WITH THE AUTHOR.

	IN ADDITION, IN NO EVENT DOES THE AUTHOR AUTHORIZE YOU
	TO USE THE WORK IN APPLICATIONS OR SYSTEMS WHERE THE
	WORK'S FAILURE TO PERFORM CAN REASONABLY BE EXPECTED
	TO RESULT IN A SIGNIFICANT PHYSICAL INJURY, OR IN LOSS
	OF LIFE. ANY SUCH USE BY YOU IS ENTIRELY AT YOUR OWN RISK,
	AND YOU AGREE TO HOLD THE AUTHOR AND CONTRIBUTORS HARMLESS
	FROM ANY CLAIMS OR LOSSES RELATING TO SUCH UNAUTHORIZED
	USE.


	This unit takes a normalized floating point number in an
	expanded format and rounds it according to the IEEE-754
	standard. NaN's and infinities are not rounded.
	This module has a single cycle latency.

	Mode
	0:		round to nearest even
	1:		round to zero (truncate)
	2:		round towards +infinity
	3:		round towards -infinity

	Ref: Webpack 8.1i  Spartan3-4 xc3s1000-4ft256
	69 slices / 129 LUTS / 21.3 ns  (32 bit)
=============================================================== */

module fpRound(rm, i, o);
parameter WID = 32;
localparam MSB = WID-1;
localparam EMSB = WID==80 ? 14 :
                  WID==64 ? 10 :
				  WID==52 ? 10 :
				  WID==48 ? 10 :
				  WID==44 ? 10 :
				  WID==42 ? 10 :
				  WID==40 ?  9 :
				  WID==32 ?  7 :
				  WID==24 ?  6 : 4;
localparam FMSB = WID==80 ? 63 :
                  WID==64 ? 51 :
				  WID==52 ? 39 :
				  WID==48 ? 35 :
				  WID==44 ? 31 :
				  WID==42 ? 29 :
				  WID==40 ? 28 :
				  WID==32 ? 22 :
				  WID==24 ? 15 : 9;

input [1:0] rm;			// rounding mode
input [MSB+2:0] i;		// intermediate format input
output [WID-1:0] o;		// rounded output

//------------------------------------------------------------
// variables
wire so;
wire [EMSB:0] xo;
reg  [FMSB:0] mo;
wire [EMSB:0] xo1 = i[MSB+1:FMSB+4];
wire [FMSB+3:0] mo1 = i[FMSB+3:0];
wire xInf = &xo1;
wire dn = !(|xo1);			// denormalized input
assign o = {so,xo,mo};

wire g = i[2];	// guard bit: always the same bit for all operations
wire r = i[1];	// rounding bit
wire s = i[0];	// sticky bit
reg rnd;

// Compute the round bit
// Infinities and NaNs are not rounded!
always @(xInf,rm,g,r,s,so)
	case ({xInf,rm})
	3'd0:	rnd = (g & r) | (r & s);	// round to nearest even
	3'd1:	rnd = 0;					// round to zero (truncate)
	3'd2:	rnd = (r | s) & !so;		// round towards +infinity
	3'd3:	rnd = (r | s) & so;			// round towards -infinity
	default:	rnd = 0;				// no rounding if exponent indicates infinite or NaN
	endcase

// round the number, check for carry
// note: inf. exponent checked above (if the exponent was infinite already, then no rounding occurs as rnd = 0)
// note: exponent increments if there is a carry (can only increment to infinity)
// performance note: use the carry chain to increment the exponent
wire [MSB:0] rounded = {xo1,mo1[FMSB+3:2]} + rnd;
wire carry = mo1[FMSB+3] & !rounded[FMSB+1];

assign so = i[MSB+2];
assign xo = rounded[MSB:FMSB+2];

always @(rnd or xo or carry or dn or rounded or mo1)
	casex({rnd,&xo,carry,dn})
	4'b0xx0:	mo = mo1[FMSB+2:1];		// not rounding, not denormalized, => hide MSB
	4'b0xx1:	mo = mo1[FMSB+3:2];		// not rounding, denormalized
	4'b1000:	mo = rounded[FMSB  :0];	// exponent didn't change, number was normalized, => hide MSB
	4'b1001:	mo = rounded[FMSB+1:1];	// exponent didn't change, but number was denormalized, => retain MSB
	4'b1010:	mo = rounded[FMSB+1:1];	// exponent incremented (new MSB generated), number was normalized, => hide 'extra (FMSB+2)' MSB
	4'b1011:	mo = rounded[FMSB+1:1];	// exponent incremented (new MSB generated), number was denormalized, number became normalized, => hide 'extra (FMSB+2)' MSB
	4'b11xx:	mo = 0;					// number became infinite, no need to check carry etc., rnd would be zero if input was NaN or infinite
	endcase

endmodule


// Round and register the output

module fpRoundReg(clk, ce, rm, i, o);
parameter WID = 32;
localparam MSB = WID-1;
localparam EMSB = WID==80 ? 14 :
                  WID==64 ? 10 :
				  WID==52 ? 10 :
				  WID==48 ? 10 :
				  WID==44 ? 10 :
				  WID==42 ? 10 :
				  WID==40 ?  9 :
				  WID==32 ?  7 :
				  WID==24 ?  6 : 4;
localparam FMSB = WID==80 ? 63 :
                  WID==64 ? 51 :
				  WID==52 ? 39 :
				  WID==48 ? 35 :
				  WID==44 ? 31 :
				  WID==42 ? 29 :
				  WID==40 ? 28 :
				  WID==32 ? 22 :
				  WID==24 ? 15 : 9;

input clk;
input ce;
input [1:0] rm;			// rounding mode
input [MSB+2:0] i;		// expanded format input
output reg [WID-1:0] o;		// rounded output

wire [WID-1:0] o1;
fpRound #(WID) u1 (.rm(rm), .i(i), .o(o1) );

always @(posedge clk)
	if (ce)
		o <= o1;

endmodule
