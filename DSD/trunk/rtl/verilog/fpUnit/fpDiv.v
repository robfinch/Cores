`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpDiv.v
//    - floating point divider
//    - parameterized width
//    - IEEE 754 representation
//
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
//	Floating Point Multiplier / Divider
//
//Properties:
//+-inf * +-inf = -+inf    (this is handled by exOver)
//+-inf * 0     = QNaN
//+-0 / +-0      = QNaN
// ============================================================================

module fpDiv(clk, ce, ld, a, b, o, done, sign_exe, overflow, underflow);

parameter WID = 128;
localparam MSB = WID-1;
localparam EMSB = WID==128 ? 14 :
                  WID==96 ? 14 :
                  WID==80 ? 14 :
                  WID==64 ? 10 :
				  WID==52 ? 10 :
				  WID==48 ? 10 :
				  WID==44 ? 10 :
				  WID==42 ? 10 :
				  WID==40 ?  9 :
				  WID==32 ?  7 :
				  WID==24 ?  6 : 4;
localparam FMSB = WID==128 ? 111 :
                  WID==96 ? 79 :
                  WID==80 ? 63 :
                  WID==64 ? 51 :
				  WID==52 ? 39 :
				  WID==48 ? 35 :
				  WID==44 ? 31 :
				  WID==42 ? 29 :
				  WID==40 ? 28 :
				  WID==32 ? 22 :
				  WID==24 ? 15 : 9;

localparam FX = (FMSB+2)*2-1;	// the MSB of the expanded fraction
localparam EX = FX + 1 + EMSB + 1 + 1 - 1;

input clk;
input ce;
input ld;
input [MSB:0] a, b;
output [EX:0] o;
output done;
output sign_exe;
output overflow;
output underflow;

// registered outputs
reg sign_exe;
reg inf;
reg	overflow;
reg	underflow;

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
wire [EMSB+2:0] ex1;	// sum of exponents
wire [FX:0] divo;

// Operands
wire sa, sb;			// sign bit
wire [EMSB:0] xa, xb;	// exponent bits
wire [FMSB+1:0] fracta, fractb;
wire a_dn, b_dn;			// a/b is denormalized
wire az, bz;
wire aInf, bInf;
wire aNan,bNan;

// -----------------------------------------------------------
// - decode the input operands
// - derive basic information
// - calculate exponent
// - calculate fraction
// -----------------------------------------------------------

fpDecomp #(WID) u1a (.i(a), .sgn(sa), .exp(xa), .fract(fracta), .xz(a_dn), .vz(az), .inf(aInf), .nan(aNan) );
fpDecomp #(WID) u1b (.i(b), .sgn(sb), .exp(xb), .fract(fractb), .xz(b_dn), .vz(bz), .inf(bInf), .nan(bNan) );

// Compute the exponent.
// - correct the exponent for denormalized operands
// - adjust the difference by the bias (add 127)
// - also factor in the different decimal position for division
assign ex1 = (xa|a_dn) - (xb|b_dn) + bias + FMSB - 1;

// check for exponent underflow/overflow
wire under = ex1[EMSB+2];	// MSB set = negative exponent
wire over = (&ex1[EMSB:0] | ex1[EMSB+1]) & !ex1[EMSB+2];

// Perform divide
// could take either 1 or 16 clock cycles
fpdivr8 #(FMSB+2,2) u2 (.clk(clk), .ld(ld), .a({3'b0,fracta}), .b({3'b0,fractb}), .q(divo), .r(), .done(done));

// determine when a NaN is output
wire qNaNOut = (az&bz)|(aInf&bInf);

always @(posedge clk)
	if (ce) begin
		if (done) begin
			casex({qNaNOut|aNan|bNan,bInf,bz})
			3'b1xx:		xo = infXp;	// NaN exponent value
			3'bx1x:		xo = 0;		// divide by inf
			3'bxx1:		xo = infXp;	// divide by zero
			default:	xo = ex1;		// normal or underflow: passthru neg. exp. for normalization
			endcase

			casex({aNan,bNan,qNaNOut,bInf,bz})
			5'b1xxxx:       mo = {1'b0,a[FMSB:0],{FMSB+1{1'b0}}};
			5'bx1xxx:       mo = {1'b0,b[FMSB:0],{FMSB+1{1'b0}}};
			5'bxx1xx:		mo = {1'b0,qNaN[FMSB:0]|{aInf,1'b0}|{az,bz},{FMSB+1{1'b0}}};
			5'bxxx1x:		mo = 0;	// div by inf
			5'bxxxx1:		mo = 0;	// div by zero
			default:	mo = divo;	// plain div
			endcase

			so  		= sa ^ sb;
			sign_exe 	= sa & sb;
			overflow	= over;
			underflow 	= under;
		end
	end

endmodule
