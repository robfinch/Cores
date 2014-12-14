/* ============================================================================
	(C) 2007  Robert T Finch
	All rights reserved.
	rob@birdcomputer.ca

	fp_cmp_unit.v
		- floating point comparison unit
		- parameterized width
		- IEEE 754 representation

	Verilog 2001

	Notice of Confidentiality

	http://en.wikipedia.org/wiki/IEEE_754

	Ref: Webpack 8.1i Spartan3-4 xc3s1000-4ft256
	111 LUTS / 58 slices / 16 ns
	Ref: Webpack 8.1i Spartan3-4 xc3s1000-4ft256
	109 LUTS / 58 slices / 16.4 ns

============================================================================ */

`define FCLT		4'd0
`define FCGE		4'd1
`define FCLE		4'd2
`define FCGT		4'd3
`define FCEQ		4'd4
`define FCNE		4'd5
`define FCUN		4'd6
`define FCOR		4'd7
`define FCMP		4'd15

module fp_cmp_unit(op, a, b, o, nanx);
parameter WID = 32;
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

input [3:0] op;
input [WID-1:0] a, b;
output o;
reg o;
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

fp_decomp #(WID) u1(.i(a), .sgn(sa), .exp(xa), .man(ma), .vz(az), .qnan(), .snan(), .nan(nan_a) );
fp_decomp #(WID) u2(.i(b), .sgn(sb), .exp(xb), .man(mb), .vz(bz), .qnan(), .snan(), .nan(nan_b) );

wire unordered = nan_a | nan_b;

wire eq = (az & bz) || (a==b);	// special test for zero, ugh!
wire gt1 = {xa,ma} > {xb,mb};
wire lt1 = {xa,ma} < {xb,mb};

wire lt = sa ^ sb ? sa & !(az & bz): sa ? gt1 : lt1;

always @(op or unordered or eq or lt)
	case (op)	// synopsys full_case parallel_case
	`FCOR:	o = !unordered;
	`FCUN:	o =  unordered;
	`FCEQ:	o =  eq;
	`FCNE:	o = !eq;
	`FCLT:	o =  lt;
	`FCGE:	o = !lt;
	`FCLE:	o =  lt | eq;
	`FCGT:	o = !(lt | eq);
	`FCMP:	o = {lt,unordered,60'd0,eq,1'b0};
	endcase

// an unorder comparison will signal a nan exception
assign nanx = op!=`FCOR && op!=`FCUN && unordered;

endmodule
