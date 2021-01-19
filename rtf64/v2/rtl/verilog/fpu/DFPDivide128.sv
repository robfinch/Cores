// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPDivide128.sv
//    - decimal floating point divider
//    - parameterized width
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
//	Floating Point Divider
//
//Properties:
//+-inf * +-inf = -+inf    (this is handled by exOver)
//+-inf * 0     = QNaN
//+-0 / +-0      = QNaN
// ============================================================================

import fp::*;

module DFPDivide128(rst, clk, ce, ld, op, a, b, o, done, sign_exe, overflow, underflow);
parameter N=34;
// FADD is a constant that makes the divider width a multiple of four and includes eight extra bits.			
input rst;
input clk;
input ce;
input ld;
input op;
input  DFP128 a, b;
output DFP128UD o;
output reg done;
output sign_exe;
output overflow;
output underflow;

// registered outputs
reg sign_exe=0;
reg inf=0;
reg	overflow=0;
reg	underflow=0;

reg so, sxo;
reg [13:0] xo;
reg [(N+1)*4*2-1:0] mo;

DFP128U au, bu;
DFPUnpack128 u01 (a, au);
DFPUnpack128 u02 (b, bu);

// constants
wire [13:0] infXp = 13'h2FFF;	// infinite / NaN - all ones
// The following is the value for an exponent of zero, with the offset
// eg. 8'h7f for eight bit exponent, 11'h7ff for eleven bit exponent, etc.
// The following is a template for a quiet nan. (MSB=1)
wire [N*4-1:0] qNaN  = {4'h1,{(N-1)*4{1'b0}}};

// variables
wire [(N+2)*4*2-1:0] divo;

// Operands
reg sa, sb;			// sign bit
reg [13:0] xa, xb;	// exponent bits
reg [N*4-1:0] siga, sigb;
reg az, bz;
reg aInf, bInf;
reg aNan,bNan;
wire done1;
wire signed [7:0] lzcnt;

// -----------------------------------------------------------
// Clock #1
// - decode the input operands
// - derive basic information
// - calculate fraction
// -----------------------------------------------------------
reg ld1;
always @(posedge clk)
	if (ce) sa <= au.sign;
always @(posedge clk)
	if (ce) sb <= bu.sign;
always @(posedge clk)
	if (ce) siga <= au.sig;
always @(posedge clk)
	if (ce) sigb <= bu.sig;
always @(posedge clk)
	if (ce) az <= au.exp==14'd0 && au.sig==136'd0;
always @(posedge clk)
	if (ce) bz <= bu.exp==14'd0 && bu.sig==136'd0;
always @(posedge clk)
	if (ce) aInf <= au.infinity;
always @(posedge clk)
	if (ce) bInf <= bu.infinity;
always @(posedge clk)
	if (ce) aNan <= au.nan;
always @(posedge clk)
	if (ce) bNan <= bu.nan;
delay #(.WID(1), .DEP(1)) udly1 (.clk(clk), .ce(ce), .i(ld), .o(ld1));

// -----------------------------------------------------------
// Clock #2 to N
// - calculate fraction
// -----------------------------------------------------------
wire done3a,done3;
// Perform divide
dfdiv #(N+2) u2 (.clk(clk), .ld(ld1), .a({siga,8'b0}), .b({sigb,8'b0}), .q(divo), .r(), .done(done1), .lzcnt(lzcnt));
wire [7:0] lzcnt_bin = lzcnt[3:0] + (lzcnt[7:4] * 10);
wire [(N+2)*4*2-1:0] divo1 = divo[(N+2)*4*2-1:0] << ({lzcnt_bin,2'b0}+(N*4));//WAS FPWID=128?+44
delay #(.WID(1), .DEP(3)) u3 (.clk(clk), .ce(ce), .i(done1), .o(done3a));
assign done3 = done1&done3a;

// -----------------------------------------------------------
// Clock #N+1
// - calculate exponent
// - calculate fraction
// - determine when a NaN is output
// -----------------------------------------------------------
// Compute the exponent.
// - correct the exponent for denormalized operands
// - adjust the difference by the bias (add 127)
// - also factor in the different decimal position for division
reg [15:0] ex1;	// sum of exponents
reg qNaNOut;

always @(posedge clk)
  if (ce) ex1 <= xa - xb + bias - lzcnt;

always @(posedge clk)
  if (ce) qNaNOut <= (az&bz)|(aInf&bInf);

assign over1 = 1'b0;
assign under1 = &ex1[15:14];

// -----------------------------------------------------------
// Clock #N+3
// -----------------------------------------------------------
always @(posedge clk)
// Simulation likes to see these values reset to zero on reset. Otherwise the
// values propagate in sim as X's.
if (rst) begin
	xo <= 1'd0;
	mo <= 1'd0;
	so <= 1'd0;
	sign_exe <= 1'd0;
	overflow <= 1'd0;
	underflow <= 1'd0;
	done <= 1'b1;
end
else if (ce) begin
  done <= 1'b0;
	if (done3&done1) begin
	  done <= 1'b1;

		casez({qNaNOut|aNan|bNan,bInf,bz,over,under})
		5'b1????:		xo <= infXp;	// NaN exponent value
		5'b01???:		xo <= 1'd0;		// divide by inf
		5'b001??:		xo <= infXp;	// divide by zero
		5'b0001?:		xo <= infXp;	// overflow
		5'b00001:		xo <= 1'd0;		// underflow
		default:		xo <= ex1;	// normal or underflow: passthru neg. exp. for normalization
		endcase

		casez({aNan,bNan,qNaNOut,bInf,bz,over,aInf&bInf,az&bz})
		8'b1???????:  begin mo <= {4'h1,a[N*4-1:0],{(N+1)*4-1{1'b0}}}; st[3] <= 1'b1; end
		8'b01??????:  begin mo <= {4'h1,b[N*4-1:0],{(N+1)*4-1{1'b0}}}; st[3] <= 1'b1; end
		8'b001?????:	begin mo <= {4'h1,qNaN[N*4-1:0]|{aInf,1'b0}|{az,bz},{(N+1)*4-1{1'b0}}}; st[3] <= 1'b1; end
		8'b0001????:	begin mo <= {(N+1)*4*2-1{1'd0}};	st[3] <= 1'b0; end 	// div by inf
		8'b00001???:	begin mo <= {(N+1)*4*2-1{1'd0}};	st[3] <= 1'b0; end	// div by zero
		8'b000001??:	begin mo <= {(N+1)*4*2-1{1'd0}};	st[3] <= 1'b0; end 	// Inf exponent
		8'b0000001?:	begin mo <= {4'h1,qNaN|`QINFDIV,{(N+1)*4-1{1'b0}}};	st[3] <= 1'b1; end 	// infinity / infinity
		8'b00000001:	begin mo <= {4'h1,qNaN|`QZEROZERO,{(N+1)*4-1{1'b0}}};	st[3] <= 1'b1; end	// zero / zero
		default:		begin mo <= divo1[(N+2)*4*2-1:8];	st[3] <= 1'b0; end	// plain div
		endcase

		sign_exe 	<= sa & sb;
		overflow	<= over;
		underflow 	<= under;

		o.nan <= aNan|bNan|qNanOut;
		o.snan <= aNan|bNan|qNanOut;
		o.qnan <= 1'b0;
		o.infinity <= over|aInf;
		o.sign <= sa ^ sb;
		o.exp <= xo;
		o.sig <= mo;
	end
end

endmodule

module DFPDivide128nr(rst, clk, ce, ld, op, a, b, o, rm, done, sign_exe, inf, overflow, underflow);
parameter N=34;
input rst;
input clk;
input ce;
input ld;
input op;
input  DFP128 a, b;
output DFP128 o;
input [2:0] rm;
output sign_exe;
output done;
output inf;
output overflow;
output underflow;

DFP128UD o1;
wire sign_exe1, inf1, overflow1, underflow1;
DFP128UN fpn0;
wire done1, done1a;

DFPDivide128    #(.N(N)) u1 (rst, clk, ce, ld, op, a, b, o1, done1, sign_exe1, overflow1, underflow1);
DFPNormalize128 #(.N(N)) u2(.clk(clk), .ce(ce), .under_i(underflow1), .i(o1), .o(fpn0) );
DFPRound128     #(.N(N)) u3(.clk(clk), .ce(ce), .rm(rm), .i(fpn0), .o(o) );
delay2      #(1)   u4(.clk(clk), .ce(ce), .i(sign_exe1), .o(sign_exe));
delay2      #(1)   u5(.clk(clk), .ce(ce), .i(inf1), .o(inf));
delay2      #(1)   u6(.clk(clk), .ce(ce), .i(overflow1), .o(overflow));
delay2      #(1)   u7(.clk(clk), .ce(ce), .i(underflow1), .o(underflow));
delay	#(.WID(1),.DEP(11))   u8(.clk(clk), .ce(ce), .i(done1), .o(done1a));
assign done = done1&done1a;

endmodule

