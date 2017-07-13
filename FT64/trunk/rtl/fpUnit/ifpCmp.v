/* ============================================================================
	(C) 2007  Robert T Finch
	All rights reserved.
	rob@birdcomputer.ca

	ifpCmp.v
		- combined integer / floating point comparison unit
		- parameterized width
		- IEEE 754 representation

	Verilog 1995

	Notice of Confidentiality

	http://en.wikipedia.org/wiki/IEEE_754

	Ref: Webpack 8.1i Spartan3-4 xc3s1000-4ft256
	111 LUTS / 58 slices / 16 ns

============================================================================ */

`define CLT		3'd0
`define CGE		3'd1
`define CLE		3'd2
`define CGT		3'd3
`define CUN		3'd4
`define COR		3'd5
`define CEQ		3'd6
`define CNEQ	3'd7

module ifpCmp(op, a, b, o, nanx);
	parameter WID   = 32;
	localparam MSB  = WID-1;
	localparam EMSB = WID==80 ? 14 : WID==64 ? 10 : WID==48 ? 10 : WID==32 ?  7 : WID==24 ?  6 : WID==20 ?   5 : 4;
	localparam FMSB = WID==80 ? 63 : WID==64 ? 51 : WID==48 ? 35 : WID==32 ? 22 : WID==24 ? 15 : WID==20 ?  12 : 9;

	input [2:0] op;
	input [WID-1:0] a, b;
	output reg o;
	output nanx;

	// Decompose the operands
	wire sa;
	wire sb;
	wire [EMSB:0] xa;
	wire [EMSB:0] xb;
	wire [FMSB:0] ma;
	wire [FMSB:0] mb;
	wire az, bz;
	wire nan_a, nan_b;

	fpDecomp #(WID) u1(.i(a), .sgn(sa), .exp(xa), .man(ma), .vz(az), .qnan(), .snan(), .nan(nan_a) );
	fpDecomp #(WID) u2(.i(b), .sgn(sb), .exp(xb), .man(mb), .vz(bz), .qnan(), .snan(), .nan(nan_b) );

	wire unordered = nan_a | nan_b;

	wire eq = (az & bz) || (a==b);	// special test for zero, ugh!
	wire gt1 = {xa,ma} > {xb,mb};
	wire lt1 = {xa,ma} < {xb,mb};

	wire lt = sa ^ sb ? sa & !(az & bz): sa ? gt1 : lt1;

	always @(op,unordered,eq,lt)
		case (op)	// synopsys full_case parallel_case
		`COR:	o = !unordered;
		`CUN:	o =  unordered;
		`CEQ:	o =  eq;
		`CNEQ:	o = !eq;
		`CLT:	o =  lt;
		`CGE:	o = !lt;
		`CLE:	o =  lt | eq;
		`CGT:	o = !(lt | eq);
		endcase

	// an unorder comparison will signal a nan exception
	assign nanx = op!=`COR && op!=`CUN && unordered;

endmodule
