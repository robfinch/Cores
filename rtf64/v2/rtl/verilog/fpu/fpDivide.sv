// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpDivide.sv
//    - floating point divider
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
//	Floating Point Divider
//
//Properties:
//+-inf * +-inf = -+inf    (this is handled by exOver)
//+-inf * 0     = QNaN
//+-0 / +-0      = QNaN
// ============================================================================

import fp::*;
//`define GOLDSCHMIDT	1'b1

module fpDivide(rst, clk, clk4x, ce, ld, op, a, b, o, done, sign_exe, overflow, underflow);
// FADD is a constant that makes the divider width a multiple of four and includes eight extra bits.			
localparam FADD = FPWID==128 ? 9 :
				  FPWID==96 ? 9 :
				  FPWID==84 ? 9 :
				  FPWID==80 ? 9 :
				  FPWID==64 ? 13 :
				  FPWID==52 ? 9 :
				  FPWID==48 ? 10 :
				  FPWID==44 ? 9 :
				  FPWID==42 ? 11 :
				  FPWID==40 ? 8 :
				  FPWID==32 ? 10 :
				  FPWID==24 ? 9 : 11;
input rst;
input clk;
input clk4x;
input ce;
input ld;
input op;
input [MSB:0] a, b;
output [EX:0] o;
output reg done;
output sign_exe;
output overflow;
output underflow;

// registered outputs
reg sign_exe=0;
reg inf=0;
reg	overflow=0;
reg	underflow=0;

reg so;
reg [EMSB:0] xo;
reg [FX:0] mo;
assign o = {so,xo,mo};

// constants
wire [EMSB:0] infXp = {EMSB+1{1'b1}};	// infinite / NaN - all ones
// The following is the value for an exponent of zero, with the offset
// eg. 8'h7f for eight bit exponent, 11'h7ff for eleven bit exponent, etc.
wire [EMSB:0] bias = {1'b0,{EMSB{1'b1}}};	//2^0 exponent
// The following is a template for a quiet nan. (MSB=1)
wire [FMSB:0] qNaN  = {1'b1,{FMSB{1'b0}}};

// variables
`ifndef GOLDSCHMIDT
wire [(FMSB+FADD)*2-1:0] divo;
`else
wire [(FMSB+5)*2-1:0] divo;
`endif

// Operands
wire sa, sb;			// sign bit
wire [EMSB:0] xa, xb;	// exponent bits
wire [FMSB+1:0] fracta, fractb;
wire a_dn, b_dn;			// a/b is denormalized
wire az, bz;
wire aInf, bInf;
wire aNan,bNan;
wire done1;
wire signed [7:0] lzcnt;

// -----------------------------------------------------------
// Clock #1
// - decode the input operands
// - derive basic information
// - calculate fraction
// -----------------------------------------------------------
reg ld1;
fpDecompReg u1a (.clk(clk), .ce(ce), .i(a), .sgn(sa), .exp(xa), .fract(fracta), .xz(a_dn), .vz(az), .inf(aInf), .nan(aNan) );
fpDecompReg u1b (.clk(clk), .ce(ce), .i(b), .sgn(sb), .exp(xb), .fract(fractb), .xz(b_dn), .vz(bz), .inf(bInf), .nan(bNan) );
delay #(.WID(1), .DEP(1)) udly1 (.clk(clk), .ce(ce), .i(ld), .o(ld1));

// -----------------------------------------------------------
// Clock #2 to N
// - calculate fraction
// -----------------------------------------------------------
wire done3;
// Perform divide
// Divider width must be a multiple of four
`ifndef GOLDSCHMIDT
fpdivr16 #(FMSB+FADD) u2 (.clk(clk), .ld(ld1), .a({3'b0,fracta,8'b0}), .b({3'b0,fractb,8'b0}), .q(divo), .r(), .done(done1), .lzcnt(lzcnt));
//fpdivr2 #(FMSB+FADD) u2 (.clk4x(clk4x), .ld(ld), .a({3'b0,fracta,8'b0}), .b({3'b0,fractb,8'b0}), .q(divo), .r(), .done(done1), .lzcnt(lzcnt));
wire [(FMSB+FADD)*2-1:0] divo1 = divo[(FMSB+FADD)*2-1:0] << (lzcnt-2);
`else
DivGoldschmidt #(.WID(FMSB+6),.WHOLE(1),.POINTS(FMSB+5))
	u2 (.rst(rst), .clk(clk), .ld(ld1), .a({fracta,4'b0}), .b({fractb,4'b0}), .q(divo), .done(done1), .lzcnt(lzcnt));
wire [(FMSB+6)*2+1:0] divo1 =
	lzcnt > 8'd5 ? divo << (lzcnt-8'd6) :
	divo >> (8'd6-lzcnt);
	;
`endif
delay #(.WID(1), .DEP(3)) u3 (.clk(clk), .ce(ce), .i(done1), .o(done3));

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
reg [EMSB+2:0] ex1;	// sum of exponents
reg qNaNOut;

always @(posedge clk)
`ifndef GOLDSCHMIDT
  if (ce) ex1 <= (xa|a_dn) - (xb|b_dn) + bias + FMSB + (FADD-1) - lzcnt - 8'd1;
`else
  if (ce) ex1 <= (xa|a_dn) - (xb|b_dn) + bias + FMSB - lzcnt + 8'd4;
`endif

always @(posedge clk)
  if (ce) qNaNOut <= (az&bz)|(aInf&bInf);


// -----------------------------------------------------------
// Clock #N+2
// - check for exponent underflow/overflow
// -----------------------------------------------------------
reg under;
reg over;
always @(posedge clk)
  if (ce) under <= ex1[EMSB+2];	// MSB set = negative exponent
always @(posedge clk)
  if (ce) over <= (&ex1[EMSB:0] | ex1[EMSB+1]) & !ex1[EMSB+2];


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
  if (ld)
    done <= 1'b0;
	if (done3) begin
	  done <= 1'b1;

		casez({qNaNOut|aNan|bNan,bInf,bz,over,under})
		5'b1????:		xo <= infXp;	// NaN exponent value
		5'b01???:		xo <= 1'd0;		// divide by inf
		5'b001??:		xo <= infXp;	// divide by zero
		5'b0001?:		xo <= infXp;	// overflow
		5'b00001:		xo <= 1'd0;		// underflow
		default:		xo <= ex1;	// normal or underflow: passthru neg. exp. for normalization
		endcase

`ifdef SUPPORT_DENORMALS
		casez({aNan,bNan,qNaNOut,bInf,bz,over,aInf&bInf,az&bz})
`else
		casez({aNan,bNan,qNaNOut,bInf,bz,over|under,aInf&bInf,az&bz})
`endif
		8'b1???????:  mo <= {1'b1,a[FMSB:0],{FMSB+1{1'b0}}};
		8'b01??????:  mo <= {1'b1,b[FMSB:0],{FMSB+1{1'b0}}};
		8'b001?????:	mo <= {1'b1,qNaN[FMSB:0]|{aInf,1'b0}|{az,bz},{FMSB+1{1'b0}}};
		8'b0001????:	mo <= 1'd0;	// div by inf
		8'b00001???:	mo <= 1'd0;	// div by zero
		8'b000001??:	mo <= 1'd0;	// Inf exponent
		8'b0000001?:	mo <= {1'b1,qNaN|`QINFDIV,{FMSB+1{1'b0}}};	// infinity / infinity
		8'b00000001:	mo <= {1'b1,qNaN|`QZEROZERO,{FMSB+1{1'b0}}};	// zero / zero
`ifndef GOLDSCHMIDT
		default:		mo <= divo1[(FMSB+FADD)*2-1:(FADD-2)*2-2];	// plain div
`else
		default:		mo <= divo1[(FMSB+6)*2+1:2];	// plain div
`endif
		endcase

		so  		<= sa ^ sb;
		sign_exe 	<= sa & sb;
		overflow	<= over;
		underflow 	<= under;
	end
end

endmodule

module fpDividenr(rst, clk, clk4x, ce, ld, op, a, b, o, rm, done, sign_exe, inf, overflow, underflow);
input rst;
input clk;
input clk4x;
input ce;
input ld;
input op;
input  [MSB:0] a, b;
output [MSB:0] o;
input [2:0] rm;
output sign_exe;
output done;
output inf;
output overflow;
output underflow;

wire [EX:0] o1;
wire sign_exe1, inf1, overflow1, underflow1;
wire [MSB+3:0] fpn0;
wire done1;

fpDivide    #(FPWID) u1 (rst, clk, clk4x, ce, ld, op, a, b, o1, done1, sign_exe1, overflow1, underflow1);
fpNormalize #(FPWID) u2(.clk(clk), .ce(ce), .under_i(underflow1), .i(o1), .o(fpn0) );
fpRound     #(FPWID) u3(.clk(clk), .ce(ce), .rm(rm), .i(fpn0), .o(o) );
delay2      #(1)   u4(.clk(clk), .ce(ce), .i(sign_exe1), .o(sign_exe));
delay2      #(1)   u5(.clk(clk), .ce(ce), .i(inf1), .o(inf));
delay2      #(1)   u6(.clk(clk), .ce(ce), .i(overflow1), .o(overflow));
delay2      #(1)   u7(.clk(clk), .ce(ce), .i(underflow1), .o(underflow));
delay2		  #(1)   u8(.clk(clk), .ce(ce), .i(done1), .o(done));
endmodule

