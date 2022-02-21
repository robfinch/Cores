// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPRound.sv
//    - decimal floating point rounding unit
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

module DFPRound(clk, ce, rm, i, o);
parameter N=33;
input clk;
input ce;
input [2:0] rm;			// rounding mode
input [N*4+16+4+4-1:0] i;		// intermediate format input
output [N*4+16+4-1:0] o;		// rounded output

parameter ROUND_CEILING = 3'd0;
parameter ROUND_FLOOR = 3'd1;
parameter ROUND_HALF_UP = 3'd2;
parameter ROUND_HALF_EVEN = 3'd3;
parameter ROUND_DOWN = 3'd4;

//------------------------------------------------------------
// variables
wire [3:0] so;
wire [15:0] xo;
reg  [N*4-1:0] mo;
reg [15:0] xo1;
reg [N*4-1:0] mo1;
wire xInf = i[N*4+16+4-1:(N+1)*4]==16'h9999;
wire so0 = i[N*4+16+4-2];
assign o = {so,xo,mo};

wire [3:0] l = i[7:4];
wire [3:0] r = i[3:0];

reg rnd;

//------------------------------------------------------------
// Clock #1
// - determine round amount (add 1 or 0)
//------------------------------------------------------------

always @`PIPE_ADV
if (ce) xo1 <= i[N*4+16+4-1:(N+1)*4];
always @`PIPE_ADV
if (ce) mo1 <= i[(N+1)*4-1:4];

// Compute the round bit
// Infinities and NaNs are not rounded!
always @`PIPE_ADV
if (ce)
	if (|so[1:0])
		rnd = 1'b0;
	else
		case (rm)
		ROUND_CEILING:	rnd <= (r == 4'd0 || so[2]==1'b0) ? 1'b0 : 1'b1;
		ROUND_FLOOR:		rnd <= (r == 4'd0 || so[2]==1'b1) ? 1'b0 : 1'b1;
		ROUND_HALF_UP:	rnd <= r >= 4'h5;
		ROUND_HALF_EVEN:	rnd <= r==4'h5 ? l[0] : r > 4'h5 ? 1'b1 : 1'b0;
		ROUND_DOWN:			rnd <= 1'b0;
		default:				rnd <= 1'b0;
		endcase

//------------------------------------------------------------
// Clock #2
// round the number, check for carry
// note: inf. exponent checked above (if the exponent was infinite already, then no rounding occurs as rnd = 0)
// note: exponent increments if there is a carry (can only increment to infinity)
//------------------------------------------------------------

wire [N*4+16+4-1-4:0] rounded1;
wire co1;

BCDAddN #(.N(N+4)) ubcdan1
(
	.ci(1'b0),
	.a({xo1,mo1}),
	.b({{N*4+16+4-1-4{1'd0}},rnd}),
	.o(rounded1),
	.co(co1)
);


reg [N*4+16+4-1-4:0] rounded2;
reg carry2;
reg rnd2;
reg dn2;
wire [15:0] xo2;
always @`PIPE_ADV
	if (ce) rounded2 <= rounded1;
always @`PIPE_ADV
	if (ce) carry2 <= co1;
always @`PIPE_ADV
	if (ce) rnd2 <= rnd;
always @`PIPE_ADV
	if (ce) dn2 <= !(|xo1);
assign xo2 = rounded2[N*4+16+4-1-4:N*4];

//------------------------------------------------------------
// Clock #3
// - shift mantissa if required.
//------------------------------------------------------------
`ifdef MIN_LATENCY
assign so = i[N*4+16+4+3:N*4+16+4];
assign xo = xo2;
`else
delay3 #(4) u21 (.clk(clk), .ce(ce), .i(i[N*4+16+4+3:N*4+16+4]), .o(so));
delay1 #(16) u22 (.clk(clk), .ce(ce), .i(xo2), .o(xo));
`endif

always @`PIPE_ADV
if (ce)
	casez({rnd2,xo2==16'h9999,carry2,dn2})
	4'b0??0:	mo <= mo1[N*4-1:0];							// not rounding, not denormalized
	4'b0??1:	mo <= mo1[N*4-1:0];							// not rounding, denormalized
	4'b1000:	mo <= rounded2[N*4-1: 0];				// exponent didn't change, number was normalized
	4'b1001:	mo <= rounded2[N*4-1: 0];				// exponent didn't change, but number was denormalized
	4'b1010:	mo <= {4'h1,rounded2[N*4-1: 4]};	// exponent incremented (new MSD generated), number was normalized
	4'b1011:	mo <= rounded2[N*4-1:0];					// exponent incremented (new MSB generated), number was denormalized, number became normalized
	4'b11??:	mo <= {N*4{1'd0}};									// number became infinite, no need to check carry etc., rnd would be zero if input was NaN or infinite
	endcase

endmodule
