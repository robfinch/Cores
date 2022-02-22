// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	i2df128.sv
//  - convert integer to decimal floating point
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

import DFPPkg::*;

module i2df128 (rst, clk, ce, ld, op, rm, i, o, done);
parameter FPWID=128;
input rst;
input clk;
input ce;
input ld;
input op;						// 1 = signed, 0 = unsigned
input [2:0] rm;			// rounding mode
input [127:0] i;		// integer input
output [127:0] o;		// float output
output done;

wire [127:0] i1 = (op & i[127]) ? -i : i;
wire [171:0] bcd;
wire done1, done2;
assign done = done1 & done2;

DDBinToBCD ub2b1
(
	.rst(rst),
	.clk(clk),
	.ld(ld),
	.bin(i1),
	.bcd(bcd),
	.done(done1)
);

DFP128U ui;
wire [13:0] zeroXp = 14'h17FF;

reg iz;			// zero input ?
wire [7:0] lz;		// count the leading zeros in the number
reg [7:0] lz4;		// leading zero rounded to multiple of four
wire [13:0] wd;	// compute number of whole digits
reg so;			// copy the sign of the input (easy)
reg [2:0] rmd;
wire [171:0] bcd1;
reg [135:0] simag;

always_ff @(posedge clk)
	rmd <= rm;
always_ff @(posedge clk)
	iz <= i==0;
always_ff @(posedge clk)
	so <= i[127];

delay1 #(172) u2 (.clk(clk), .ce(ce), .i(bcd),  .o(bcd1) );
cntlz192Reg   u4 (.clk(clk), .ce(ce), .i({bcd,20'd0}), .o(lz) );

always_comb
	lz4 = lz >> 2'd2;

assign wd = zeroXp - 8'd1 + 8'd34 - lz4 + 8'd9;	// constant except for lz

reg [13:0] xo;

always_ff @(posedge clk)
	xo <= iz ? 'd0 : wd;

// left align number
// The number may to too large to represent entirely precisely in which case a
// right shift is required. There are only about 114 bits of precision, but the
// incoming number is allowed to be 128-bit.
// Rounding is required only when the number needs to be right-shifted.

always_ff @(posedge clk)
	if (lz4 < 8'd9)	
		simag = bcd1 >> {8'd9 - lz4,2'd0};
	else
		simag = bcd1 << {lz4 - 8'd9,2'd0};	

wire g =  bcd1[{8'd9 - lz4,2'd0}];	// guard bit (lsb)
wire r = 	bcd1[{8'd9 - lz4,2'd0}-1];	// rounding bit
wire s = |(bcd1 & (172'd1 << {8'd9 - lz4,2'd0}-2) - 2'd1);	// "sticky" bit
reg rnd;

// Compute the round bit
always_ff @(posedge clk)
if (lz4 < 8'd9)
	case (rmd)
	3'd0:	rnd = (g & r) | (r & s);	// round to nearest even
	3'd1:	rnd = 0;					// round to zero (truncate)
	3'd2:	rnd = (r | s) & !so;		// round towards +infinity
	3'd3:	rnd = (r | s) & so;			// round towards -infinity
	3'd4:   rnd = (r | s);
	default:	rnd = (g & r) | (r & s);	// round to nearest even
	endcase
else
	rnd = 1'b0;
	
// round the result
assign ui.sig = simag[135:0] + rnd;
assign ui.exp = xo[13:0];
assign ui.sign = op & so;
assign ui.nan = 1'b0;
assign ui.qnan = 1'b0;
assign ui.snan = 1'b0;
assign ui.infinity = 1'b0;

DFPPack128 upk1 (ui, o);

ft_delay #(.WID(1), .DEP(4)) udly1 (.clk(clk), .ce(1'b1), .i(done1), .o(done2));

endmodule
