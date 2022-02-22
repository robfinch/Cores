// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	df128Toi.sv
//  - convert decimal floating point to integer
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

module df128Toi (rst, clk, ce, ld, op, i, o, overflow, done);
input rst;
input clk;
input ce;
input ld;
input op;						// 1 = signed, 0 = unsigned
input [127:0] i;		// float input
output [127:0] o;		// integer output
output overflow;
output done;

wire done1;
reg done2;
assign done = done1 & done2;

wire [127:0] sig;

DFP128U ui;
DFPUnpack128 uunpk1 (i, ui);

wire [127:0] maxInt = op ? {1'd0,{127{1'b1}}} : {128{1'b1}};		// maximum integer value
wire [13:0] zeroXp = 14'h17FF;

reg sgn;									// sign
always @(posedge clk)
	if (ce) sgn = ui.sign;
wire [13:0] exp = ui.exp;		// exponent

wire iz = i[126:0]==0;			// zero value (special)

wire [14:0] ovx = exp - zeroXp;
assign overflow  = ovx > 32 && !ovx[14];	// lots of numbers are too big - don't forget one less bit is available due to signed values
wire underflow = exp < zeroXp - 2'd1;			// value less than 1/2

wire [7:0] shamt = 8'd172 - {(exp - zeroXp),2'd0};	// exp - zeroXp will be <= MSB

wire [176:0] o1 = {ui.sig,41'b0} >> shamt;	// keep an extra bit for rounding
wire [127:0] o2;		// round up
reg [127:0] o3;

DDBCDToBin ub2b1
(
	.rst(rst),
	.clk(clk),
	.ld(ld),
	.bcd({o1[172:1]+o1[0]}),
	.bin(o2),
	.done(done1)
);


always @(posedge clk)
	if (ce) begin
		if (underflow|iz)
			o3 <= 0;
		else if (overflow)
			o3 <= maxInt;
		// value between 1/2 and 1 - round up
		else if (exp==zeroXp-1)
			o3 <= 128'd1;
		// value > 1
		else
			o3 <= o2;
	end
always @(posedge clk)
	if (ce) done2 <= done1;
		
assign o = (op & sgn) ? -o3 : o3;					// adjust output for correct signed value

endmodule
