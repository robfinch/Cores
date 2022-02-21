// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPDivide.sv
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

module DFPDivide(rst, clk, ce, ld, op, a, b, o, done, sign_exe, overflow, underflow);
parameter N=33;
// FADD is a constant that makes the divider width a multiple of four and includes eight extra bits.			
input rst;
input clk;
input ce;
input ld;
input op;
input  [N*4+16+4-1:0] a, b;
output [(N+1)*4*2+16+4-1:0] o;
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
reg [3:0] st;
reg [15:0] xo;
reg [(N+1)*4*2-1:0] mo;
assign o = {st,xo,mo};

// constants
wire [15:0] infXp = 16'h9999;	// infinite / NaN - all ones
// The following is the value for an exponent of zero, with the offset
// eg. 8'h7f for eight bit exponent, 11'h7ff for eleven bit exponent, etc.
// The following is a template for a quiet nan. (MSB=1)
wire [N*4-1:0] qNaN  = {4'h1,{(N-1)*4{1'b0}}};

// variables
wire [(N+2)*4*2-1:0] divo;

// Operands
wire sa, sb;			// sign bit
wire sxa, sxb;
wire [15:0] xa, xb;	// exponent bits
wire [N*4-1:0] siga, sigb;
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
DFPDecomposeReg u1a (.clk(clk), .ce(ce), .i(a), .sgn(sa), .sx(sxa), .exp(xa), .sig(siga), .xz(a_dn), .vz(az), .inf(aInf), .nan(aNan) );
DFPDecomposeReg u1b (.clk(clk), .ce(ce), .i(b), .sgn(sb), .sx(sxb), .exp(xb), .sig(sigb), .xz(b_dn), .vz(bz), .inf(bInf), .nan(bNan) );
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
reg [15:0] ex2, ex1, ex2a, ex2b;	// sum of exponents
reg qNaNOut;
reg under1, under;
reg over1, over;
wire [15:0] xapxb, xamxb, xbmxa;
wire xapxbc, xamxbc, xbmxac;
reg sxo0;

BCDAddN #(.N(4)) u5 (.ci(1'b0), .a(xa), .b(xb), .o(xapxb), .co(xapxbc) );
BCDSubN #(.N(4)) u6 (.ci(1'b0), .a(xa), .b(xb), .o(xamxb), .co(xamxbc) );
BCDSubN #(.N(4)) u7 (.ci(1'b0), .a(xb), .b(xa), .o(xbmxa), .co(xbmxac) );
BCDSubN #(.N(5)) u10 (.ci(1'b0), .a(20'h10000), .b(ex2a), .o(ex2b), .co() );

always @*
case ({sxa,sxb})
2'b11:	begin ex2a <= xbmxa; sxo0 <= ~xbmxac; over1 <= 1'b0; under1 <= 1'b0; end
2'b10:	begin ex2a <= xapxb; sxo0 <= 1'b1; over1 <= xapxbc; under1 <= 1'b0; end
2'b01:	begin ex2a <= xapxb; sxo0 <= 1'b0; over1 <= 1'b0; under1 <= xapxbc; end
2'b00:	begin ex2a <= xamxb; sxo0 <= ~xamxbc; over1 <= 1'b0; under1 <= 1'b0; end
endcase

always @*
if (~sxo0 && ~(sa^sb))
	ex2 <= ex2b;
else
	ex2 <= ex2a;

wire [15:0] ex1a, ex1b, ex1d;
reg [15:0] ex1c;
wire sxoa, sxob, sxoc;

BCDAddN #(.N(4)) u8 (.ci(1'b0), .a(ex2), .b({8'h00,lzcnt}), .o(ex1a), .co(sxoa) );
BCDSubN #(.N(4)) u9 (.ci(1'b0), .a(ex2), .b({8'h00,lzcnt}), .o(ex1b), .co(sxob) );
BCDSubN #(.N(5)) u11 (.ci(1'b0), .a(20'h10000), .b(ex1c), .o(ex1d), .co() );

always @(posedge clk)
case(sxo0)
2'd1:	begin ex1c <= ex1b; sxo <= ~sxob; over <= over1; under <= under1; end
2'd0:	begin ex1c <= ex1a; sxo <= 1'b0; over <= over1;  under <= under1|sxob; end
endcase

always @*
if (sxo0 & sxob)	// There was a borrow on a subtract, making the number negative
	ex1 <= ex1d;
else
	ex1 <= ex1c;


always @(posedge clk)
  if (ce) qNaNOut <= (az&bz)|(aInf&bInf);

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

		st[0] <= sxo;
		st[1] <= aInf;
		st[2] <= ~(sa ^ sb);
		so  		<= ~(sa ^ sb);
		sign_exe 	<= sa & sb;
		overflow	<= over;
		underflow 	<= under;
	end
end

endmodule

module DFPDividenr(rst, clk, ce, ld, op, a, b, o, rm, done, sign_exe, inf, overflow, underflow);
parameter N=33;
input rst;
input clk;
input ce;
input ld;
input op;
input  [N*4+16+4-1:0] a, b;
output [N*4+16+4-1:0] o;
input [2:0] rm;
output sign_exe;
output done;
output inf;
output overflow;
output underflow;

wire [(N+1)*4*2+16+4-1:0] o1;
wire sign_exe1, inf1, overflow1, underflow1;
wire [N*4+16+4-1+4:0] fpn0;
wire done1, done1a;

DFPDivide    #(.N(N)) u1 (rst, clk, ce, ld, op, a, b, o1, done1, sign_exe1, overflow1, underflow1);
DFPNormalize #(.N(N)) u2(.clk(clk), .ce(ce), .under_i(underflow1), .i(o1), .o(fpn0) );
DFPRound     #(.N(N)) u3(.clk(clk), .ce(ce), .rm(rm), .i(fpn0), .o(o) );
delay2      #(1)   u4(.clk(clk), .ce(ce), .i(sign_exe1), .o(sign_exe));
delay2      #(1)   u5(.clk(clk), .ce(ce), .i(inf1), .o(inf));
delay2      #(1)   u6(.clk(clk), .ce(ce), .i(overflow1), .o(overflow));
delay2      #(1)   u7(.clk(clk), .ce(ce), .i(underflow1), .o(underflow));
delay	#(.WID(1),.DEP(11))   u8(.clk(clk), .ce(ce), .i(done1), .o(done1a));
assign done = done1&done1a;

endmodule

