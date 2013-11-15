/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.

	fs2d.v
		- convert floating point single to double

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

	- a little trickier than it first might seem

	Ref: Spartan3 -4
=============================================================== */

module fs2d(a, o);
	input [31:0] a;
	output [63:0] o;

	reg signo;
	reg [10:0] expo;
	reg [51:0] mano;

	assign o = {signo,expo,mano};

	wire signi;
	wire [7:0] expi;
	wire [23:0] mani;
	wire xinf;	// exponent infinite
	wire vz;	// value zero
	wire xz;	// exponent zero
	
	fpDecomp #(32) u1 (.i(a), .sgn(signi), .exp(expi), .man(mani), .xinf(xinf), .xz(xz), .vz(vz) );
	wire [4:0] lz;
	cntlz23 u2 (mani, lz);	// '1' bit already unhidden due to denormalized number

	always @(a)
	begin
		// sign out always just = sign in
		signo = signi;

		// special check for zero
		if (vz) begin
			expo <= 0;
			mano <= 0;
		end
		// convert infinity / nan
		// infinity in = infinity out
		else if (xinf) begin
			expo <= 11'h7ff;
			mano <= {mani,29'b0};
		end
		// convert denormal
		// a denormal was really a number with an exponent of -126
		// this value is easily represented in the double format
		// it may be possible to normalize the value if it isn't
		// zero
		else if (xz) begin
			expo <= 11'd897 - lz;	// 1023 "zero" -126 - lz
			mano <= {mani << (lz + 1), 29'd0};	// shift one more to hide leading '1'
		end
		// convert typical number
		// adjust exponent, copy mantissa
		else begin
			expo <= expi + 11'd896;		// 1023-127
			mano <= {mani,29'd0};
		end
	end

endmodule
