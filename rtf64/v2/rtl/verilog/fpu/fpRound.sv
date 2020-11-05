// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpRound.sv
//    - floating point rounding unit
//    - parameterized width
//    - IEEE 754 representation
//
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

import fp::*;

`ifdef MIN_LATENCY
`define PIPE_ADV  *
`else
`define PIPE_ADV  (posedge clk)
`endif

module fpRound(clk, ce, rm, i, o);
input clk;
input ce;
input [2:0] rm;			// rounding mode
input [MSB+3:0] i;		// intermediate format input
output [MSB:0] o;		// rounded output

//------------------------------------------------------------
// variables
wire so;
wire [EMSB:0] xo;
reg  [FMSB:0] mo;
reg [EMSB:0] xo1;
reg [FMSB+3:0] mo1;
wire xInf = &i[MSB+2:FMSB+4];
wire so0 = i[MSB+3];
assign o = {so,xo,mo};

wire l = i[3];
wire g = i[2];	// guard bit: always the same bit for all operations
wire r = i[1];	// rounding bit
wire s = i[0];	// sticky bit
reg rnd;

//------------------------------------------------------------
// Clock #1
// - determine round amount (add 1 or 0)
//------------------------------------------------------------

always @`PIPE_ADV
if (ce) xo1 <= i[MSB+2:FMSB+4];
always @`PIPE_ADV
if (ce) mo1 <= i[FMSB+3:0];

wire tie = g & ~(r|s);
// Compute the round bit
// Infinities and NaNs are not rounded!
always @`PIPE_ADV
if (ce)
	casez ({xInf,rm})
	4'b0000:  rnd <= (g & (r|s)) | (l & tie); // round to nearest ties to even
	4'b0001:	rnd <= 1'd0;				// round to zero (truncate)
	4'b0010:	rnd <= g & !so0;		// round towards +infinity
	4'b0011:	rnd <= g & so0;			// round towards -infinity
	4'b0100:  rnd <= (g & (r|s)) | tie; // round to nearest ties away from zero
	4'b1???:	rnd <= 1'd0;	// no rounding if exponent indicates infinite or NaN
	default:	rnd <= 0;				
	endcase

//------------------------------------------------------------
// Clock #2
// round the number, check for carry
// note: inf. exponent checked above (if the exponent was infinite already, then no rounding occurs as rnd = 0)
// note: exponent increments if there is a carry (can only increment to infinity)
//------------------------------------------------------------

reg [MSB:0] rounded2;
reg carry2;
reg rnd2;
reg dn2;
wire [EMSB:0] xo2;
wire [MSB:0] rounded1 = {xo1,mo1[FMSB+3:3],1'b0} + {rnd,1'b0};	// Add onto LSB, GRS=0
always @`PIPE_ADV
	if (ce) rounded2 <= rounded1;
always @`PIPE_ADV
	if (ce) carry2 <= mo1[FMSB+3] & !rounded1[FMSB+1];
always @`PIPE_ADV
	if (ce) rnd2 <= rnd;
always @`PIPE_ADV
	if (ce) dn2 <= !(|xo1);
assign xo2 = rounded2[MSB:FMSB+2];

//------------------------------------------------------------
// Clock #3
// - shift mantissa if required.
//------------------------------------------------------------
`ifdef MIN_LATENCY
assign so = i[MSB+3];
assign xo = xo2;
`else
delay3 #(1) u21 (.clk(clk), .ce(ce), .i(i[MSB+3]), .o(so));
delay1 #(EMSB+1) u22 (.clk(clk), .ce(ce), .i(xo2), .o(xo));
`endif

always @`PIPE_ADV
if (ce)
	casez({rnd2,&xo2,carry2,dn2})
	4'b0??0:	mo <= mo1[FMSB+2:2];		// not rounding, not denormalized, => hide MSB
	4'b0??1:	mo <= mo1[FMSB+3:3];		// not rounding, denormalized
	4'b1000:	mo <= rounded2[FMSB  :0];	// exponent didn't change, number was normalized, => hide MSB,
	4'b1001:	mo <= rounded2[FMSB+1:1];	// exponent didn't change, but number was denormalized, => retain MSB
	4'b1010:	mo <= rounded2[FMSB+1:1];	// exponent incremented (new MSB generated), number was normalized, => hide 'extra (FMSB+2)' MSB
	4'b1011:	mo <= rounded2[FMSB+1:1];	// exponent incremented (new MSB generated), number was denormalized, number became normalized, => hide 'extra (FMSB+2)' MSB
	4'b11??:	mo <= 1'd0;						// number became infinite, no need to check carry etc., rnd would be zero if input was NaN or infinite
	endcase

endmodule
