/* ===============================================================
	(C) 2007  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca

	logicUnit.v - logical operations unit


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


	Basic logic operations. Parameterized width (default 32
	bits). This unit would be used to provide the logical
	operations of an ALU.
		This core uses a 4-to-1 mux of the positive logic
	followed by an optional inversion. This two stage
	approach results in a significantly smaller resource
	footprint compared to using a simple 8-to-1 mux of the
	logic operations. The cost is only a few picoseconds in
	performance.

	op
	0	xor
	1	and
	2	or
	3	and not
	4	xnor
	5	nand
	6	nor
	7	or not (~a|b)

	Resource Usage Samples:
	Ref. SpartanII
	96 4-LUTs 48 slices with inverse ops
	64 4-LUTs 32 slices without
	Spartan3
	64 LUTs / 37 slices / 10.1ns
=============================================================== */

module logicUnit(op, a, b, o);
	parameter WID = 32;
	input  [2:0] op;			// opcode
	input  [WID:1] a;			// operand 'a'
	input  [WID:1] b;			// operand 'b'
	output [WID:1] o;			// output result
	reg    [WID:1] o;

	reg [WID:1] o1;
	wire inv = op[2];

	always @(a or b or op)
		case (op[1:0])
		2'd0:	o1 <= a^b;		// xor	/ xnor
		2'd1:	o1 <= a&b;		// and 	/ nand
		2'd2:	o1 <= a|b;		// or	/ nor
		2'd3:	o1 <= a&~b;		// andn / orn
		endcase

	always @(o1 or inv)
		case (inv)
		1'd0:	o <= o1;
		1'd1:	o <= ~o1;
		endcase

endmodule
