/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca

	fregs.v
		- floating point register file
		- parameterized width

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

	- maintains floating point register values
	- stores double width mantissa

	Ref: Webpack 8.1i Spartan3-4 xc3s1000 4ft256
	133 slices / 264 LUTs / 10 ns

=============================================================== */

module fregs(clk, we, wa, i, ra, rb,
	oa, oa_xz, oa_mz, oa_vz, oa_inf,// output 'a'
	ob, ob_xz, ob_mz, ob_vz, ob_inf	// output 'b'
);
	parameter WID=32;
	parameter NREGS=16;

	localparam MSB = WID-1;
	localparam EMSB = WID==80 ? 14 : WID==64 ? 10 : WID==48 ? 10 : WID==32 ? 7 : 6;
	localparam FMSB = WID==80 ? 63 : WID==64 ? 51 : WID==48 ? 35 : WID==32 ? 22 : 15;
	localparam FX = (FMSB+2)*2-1;	// the MSB of the expanded fraction

	input clk;
	input we;
	input [3:0] wa;
	input [EMSB+2+FX:0] i;
	input [3:0] ra;
	input [3:0] rb;

	output [EMSB+2+FX:0] oa;
	output oa_xz;
	output oa_mz;
	output oa_vz;
	output oa_inf;
	output [EMSB+2+FX:0] ob;
	output ob_xz;
	output ob_mz;
	output ob_vz;
	output ob_inf;

	// Decompose input
	wire si;			// input sign
	wire [EMSB:0] xi;	// input exponent
	wire [FX:0] mi;		// input mantissa
	wire ixz;
	wire imz;
	wire ivz;
	wire iinf;

	// Register File Storage area
	reg [NREGS-1:0] sgn;			// sign
	reg [EMSB:0] exp [NREGS-1:0];	// exponent
	reg [FX:0] man [NREGS-1:0];		// mantissa	(double width)

	reg [NREGS-1:0] xz;		// exponent is zero (denormalized)
	reg [NREGS-1:0] mz;		// mantissa is zero
	reg [NREGS-1:0] vz;		// value is zero (both exponent and mantissa are zero)
	reg [NREGS-1:0] vinf;	// value is infinite

	fdecomp #(WID) u1(.i(i), .sgn(si), .exp(xi), .man(mi), .xz(ixz), .mz(imz), .vz(ivz), .inf(iinf) );

	always @(posedge clk)
		if (we) sgn[wa] <= si;

	always @(posedge clk)
		if (we) exp[wa] <= xi;

	always @(posedge clk)
		if (we) man[wa] <= mi;

	always @(posedge clk)
		if (we) xz[wa] <= ixz;
		
	always @(posedge clk)
		if (we) mz[wa] <= imz;

	always @(posedge clk)
		if (we) vz[wa] <= ivz;

	always @(posedge clk)
		if (we) vinf[wa] <= iinf;

	assign oa = {sgn[ra],exp[ra],man[ra]};
	assign oa_xz = xz[ra];
	assign oa_mz = mz[ra];
	assign oa_vz = vz[ra];
	assign oa_inf = vinf[ra];
	assign ob = {sgn[rb],exp[rb],man[rb]};
	assign ob_xz = xz[rb];
	assign ob_mz = mz[rb];
	assign ob_vz = vz[rb];
	assign ob_inf = vinf[rb];

endmodule
