/* ============================================================================
	(C) 2002-2007  Robert T Finch
	All rights reserved.
	rob@birdcomputer.ca

	addsub.v
	- Adder / subtracter with parameterised width, carry and overflow output.


	Verilog 1995

	You may use and modify this source code for non-commercial or evaluation
    purposes, provided this copyright statement and disclaimer remains
    present in the file.


	NO WARRANTY.
	THIS Work, IS PROVIDEDED "AS IS" WITH NO WARRANTIES OF ANY KIND, WHETHER
	EXPRESS OR IMPLIED. The user must assume the entire risk of using the
	Work.

	IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY
	INCIDENTAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES WHATSOEVER RELATING TO
	THE USE OF THIS WORK, OR YOUR RELATIONSHIP WITH THE AUTHOR.

	IN ADDITION, IN NO EVENT DOES THE AUTHOR AUTHORIZE YOU TO USE THE WORK
	IN APPLICATIONS OR SYSTEMS WHERE THE WORK'S FAILURE TO PERFORM CAN
	REASONABLY BE EXPECTED TO RESULT IN A SIGNIFICANT PHYSICAL INJURY, OR IN
	LOSS OF LIFE. ANY SUCH USE BY YOU IS ENTIRELY AT YOUR OWN RISK, AND YOU
	AGREE TO HOLD THE AUTHOR AND CONTRIBUTORS HARMLESS FROM ANY CLAIMS OR
	LOSSES RELATING TO SUCH UNAUTHORIZED USE.

                                                           
	Adder / subtractor module with carry in, carry and overflow outputs.
	Parameterized width with a default of 32 bits.

	Note that the carry (borrow) input for a subtract has to be inverted.
	IE. ci = 1 = no borrow in.

	Ref: Webpack8.1i xc3s1000-4ft256
	35 LUTs / 18 slices / 15 ns

============================================================================ */

module addsub(op, ci, a, b, o, co, v);
parameter WID=32;

input op;			// 0 = add, 1 = sub
input ci;			// carry in (add: 1=carry; sub: 0=borrow)
input [WID:1] a, b;	// operands input
output [WID:1] o;	// result
output co;			// carry out
output v;			// overflow

reg [WID:0] sum;

always @(op or ci or a or b)
	case(op)
	1'd0:	sum <= {a,ci} + {b,1'b1};
	1'd1:	sum <= {a,ci} - {b,1'b1};
	endcase

assign o = sum[WID:1];

carry    u0(.op(op), .a(a[WID]), .b(b[WID]), .s(sum[WID]), .c(co) );
overflow u1(.op(op), .a(a[WID]), .b(b[WID]), .s(sum[WID]), .v(v) );

endmodule
