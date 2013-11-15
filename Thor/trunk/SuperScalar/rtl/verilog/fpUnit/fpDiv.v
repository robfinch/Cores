/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca

	fpDiv.v
		- floating point divider
		- parameterized width
		- IEEE 754 representation

	This source code is free for use and modification for
	non-commercial or evaluation purposes, provided this
	copyright statement and disclaimer remains present in
	the file.

	If you do modify the code, please state the origin and
	note that you have modified the code.

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

	This multiplier/divider handles denormalized numbers.
	The output format is of an internal expanded representation
	in preparation to be fed into a normalization unit, then
	rounding. Basically, it's the same as the regular format
	except the mantissa is doubled in size, the leading two
	bits of which are assumed to be whole bits.


	Floating Point Multiplier / Divider

	Properties:
	+-inf * +-inf = -+inf	(this is handled by exOver)
	+-inf * 0     = QNaN
	+-0 / +-0	  = QNaN

	Ref: Webpack8.2i Spartan3-4 xc3s1000-4ft256
	316 LUTS / 174 slices / 49.7 MHz
=============================================================== */

module fpDiv(clk, ce, ld, a, b, o, done, sign_exe, overflow, underflow);

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


// -----------------------------------------------------------
// - decode the input operands
// - derive basic information
// - calculate exponent
// - calculate fraction
// -----------------------------------------------------------

fpDecomp #(WID) u1a (.i(a), .sgn(sa), .exp(xa), .fract(fracta), .xz(a_dn), .vz(az), .inf(aInf) );
fpDecomp #(WID) u1b (.i(b), .sgn(sb), .exp(xb), .fract(fractb), .xz(b_dn), .vz(bz), .inf(bInf) );

// Compute the exponent.
// - correct the exponent for denormalized operands
// - adjust the difference by the bias (add 127)
// - also factor in the different decimal position for division
assign ex1 = (xa|a_dn) - (xb|b_dn) + bias + FMSB-1;

// check for exponent underflow/overflow
wire under = ex1[EMSB+2];	// MSB set = negative exponent
wire over = (&ex1[EMSB:0] | ex1[EMSB+1]) & !ex1[EMSB+2];

// Perform divide
// could take either 1 or 16 clock cycles
fpdivr8 #(WID) u2 (.clk(clk), .ld(ld), .a(fracta), .b(fractb), .q(divo), .r(), .done(done));

// determine when a NaN is output
wire qNaNOut = (az&bz)|(aInf&bInf);

always @(posedge clk)
	if (ce) begin
		if (done) begin
			casex({qNaNOut,bInf,bz})
			3'b1xx:		xo = infXp;	// NaN exponent value
			3'bx1x:		xo = 0;		// divide by inf
			3'bxx1:		xo = infXp;	// divide by zero
			default:	xo = ex1;		// normal or underflow: passthru neg. exp. for normalization
			endcase

			casex({qNaNOut,bInf,bz})
			3'b1xx:		mo = {1'b0,qNaN[FMSB:0]|{aInf,1'b0}|{az,bz},{FMSB+1{1'b0}}};
			3'bx1x:		mo = 0;	// div by inf
			3'bxx1:		mo = 0;	// div by zero
			default:	mo = divo;		// plain div
			endcase

			so  		= sa ^ sb;
			sign_exe 	= sa & sb;
			overflow	= over;
			underflow 	= under;
		end
	end

endmodule
