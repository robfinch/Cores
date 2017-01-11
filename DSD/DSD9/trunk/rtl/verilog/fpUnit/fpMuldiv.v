/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca

	fpMuldiv.v
		- floating point multiplier / divider
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

	Ref: Spartan3-4
	412 LUTS / 229 slices / 
=============================================================== */

module fpMuldiv(clk, ce, ld, op, a, b, o, done, sign_exe, inf, overflow, underflow);

	parameter WID = 32;
	localparam MSB = WID-1;
	localparam EMSB = WID==80 ? 14 : WID==64 ? 10 : WID==48 ? 10 : WID==42 ? 10 : WID==40 ?  9 : WID==32 ?  7 : WID==24 ?  6 : 4;
	localparam FMSB = WID==80 ? 63 : WID==64 ? 51 : WID==48 ? 35 : WID==42 ? 29 : WID==40 ? 28 : WID==32 ? 22 : WID==24 ? 15 : 9;
	localparam FX = (FMSB+2)*2-1;	// the MSB of the expanded fraction
	localparam EX = FX + 1 + EMSB + 3;

	input clk;
	input ce;
	input ld;
	input op;
	input [MSB:0] a, b;
	output [EX:0] o;
	output done;
	output sign_exe;
	output inf;
	output overflow;
	output underflow;

	// registered outputs
	reg sign_exe;
	reg inf;
	reg	overflow;
	reg	underflow;

	reg so;
	reg [EMSB+2:0] xo;
	reg [EMSB+2:0] xo1;
	reg [FX:0] mo;
	reg [FX:0] mo1;
	assign o = {so,xo,mo};

	// constants
	wire [EMSB:0] infXp = {EMSB+1{1'b1}};	// infinite / NaN exponent
	// The following is the value for an exponent of zero, with the offset
	// eg. 8'h7f for eight bit exponent, 11'h7ff for eleven bit exponent, etc.
	wire [EMSB:0] zeroXp = {1'b0,{EMSB{1'b1}}};	//2^0 exponent
	// The following is a template for a quiet nan. (MSB=1)
	wire [FMSB:0] qNaN  = {1'b1,{FMSB{1'b0}}};

	// variables
	wire [FMSB+1:0] fracta, fractb;
	wire [EMSB+2:0] ex1;	// sum or difference of exponents
	wire [EMSB+2:0] ex2;	// sum or difference of exponents including offset adjustment
	wire isDiv = op;

	// Decompose the operands
	wire sa, sb;
	wire [EMSB:0] xa, xb;
	wire [FMSB:0] ma, mb;

	wire a_dn, b_dn;
	wire aOrb_dn = a_dn^b_dn;	// either operand (but not both)? is denormalized
	wire maz, mbz;
	wire az, bz;
	wire aInf, bInf;

	fpDecomp #(WID) u1a (.i(a), .sgn(sa), .exp(xa), .man(ma), .xz(a_dn), .mz(maz), .vz(az), .inf(aInf) );
	fpDecomp #(WID) u1b (.i(b), .sgn(sb), .exp(xb), .man(mb), .xz(b_dn), .mz(mbz), .vz(bz), .inf(bInf) );

	assign fracta = {!a_dn,ma};	// Recover hidden bit
	assign fractb = {!b_dn,mb};	// Recover hidden bit

	// compute the sum (or difference for division) of the exponents.
	// correct the exponent for denormalized operands
	// a couple of extra bits is included in this adder so that 
	// signed results could be produced
	// mul: ex1 = xa + xb,	result should always be < 1ffh
	// div: ex1 = xa - xb,	result may be neg, range -ff to +ff
	addsub #(EMSB+3) u1 (.op(isDiv), .ci(isDiv), .a({2'b0,xa|a_dn}), .b({2'b0,xb|b_dn}), .o(ex1) );

	// adjust the sum or difference by the exponent offset
	// Note that adjusting by the offset could put the exponent back in range.
	// mul: subtract 127
	// div: add      127
	addsub #(EMSB+3) u2 (.op(!isDiv), .ci(!isDiv), .a(ex1), .b({2'b0,zeroXp}), .o(ex2) );

	// check for exponent overflow
	// Note the exOver will be active if exUnder is active. So test for
	// exUnder first!!!
	wire exUnder = ex2[EMSB+2];	// MSB set = negative exponent
	wire exOver = (&ex2[EMSB:0] | ex2[EMSB+1]) & !exUnder;

	wire [FX:0] divo;
	wire div_done;
	fpdivr8 #(FMSB+2) u3 (.clk(ce), .ce(ce), .ld(ld), .a(fracta), .b(fractb), .q(divo), .done(div_done));

	// determine when a NaN is output
	wire qNaNOut = isDiv ? (az&bz)|(aInf&bInf) : (aInf&bz)|(bInf&az);

	always @(isDiv,qNaNOut,aInf,bInf,bz,exUnder,exOver,qNaN,infXp,ex2)
		casex({isDiv,qNaNOut,aInf,bInf,bz,exUnder,exOver})
		7'bx1xxxxx:	xo1 = infXp;	// NaN exponent value
		7'b1xx1xxx:	xo1 = 0;		// divide by inf
		7'b1xxx1xx:	xo1 = infXp;	// divide by zero
		7'b0x1xxxx:	xo1 = infXp;	// multiply inf
		7'b0xx1xxx:	xo1 = infXp;	// multiply inf
		7'bxxxxx1x:	xo1 = ex2;		// underflow: passthru neg. exp. for normalization
		7'bxxxxxx1:	xo1 = infXp;	// overflow
		default:	xo1 = ex2;
		endcase

	always @(isDiv,qNaNOut,aInf,bInf,bz,exUnder,exOver,qNaN,divo,fracta,fractb)
		casex({isDiv,qNaNOut,aInf,bInf,bz,exUnder,exOver})
		7'b01xxxxx:	mo1 = {1'b0,qNaN[FMSB:0]|3'd4,{FMSB{1'b0}}};	// multiply inf * zero
		7'b11xxxxx:	mo1 = {1'b0,qNaN[FMSB:0]|{aInf,1'b0}|{az,bz},{FMSB{1'b0}}};
		7'b1xx1xxx:	mo1 = 0;	// div by inf
		7'b1xxx1xx:	mo1 = 0;	// div by zero
		7'b1xxxxxx:	mo1 = divo;	// plain div
		7'b0x1xxxx:	mo1 = 0;	// mul inf's
		7'b0xx1xxx:	mo1 = 0;	// mul inf's
		7'b0xxxxx1:	mo1 = 0;	// mul overflow
		default:	mo1 = fracta * fractb;
		endcase

	assign done = div_done|!isDiv;
	always @(posedge clk)
		if (ce) begin
			if (done) begin
				so  		<= sa ^ sb;
				xo   		<= xo1;
				mo 			<= mo1;
				sign_exe 	<= sa & sb;
				overflow	<= exOver;
				underflow 	<= exUnder;
				inf 		<= exOver;
			end
		end

endmodule
