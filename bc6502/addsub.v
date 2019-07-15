/* ===============================================================
	(C) 2002 Bird Computer
	All rights reserved.

	addsub.v
		Please read the Licensing Agreement (license.html file).
	Use of this file is subject to the license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.

	
	Adder / subtractor module with carry in, carry and overflow
	outputs. Parameterized width with a default of 32 bits.
	
	Note: we use a trick in the adder to get carry generated
	and an adder / subtractor packed into 1 LUT per bit. The
	'a' and 'b' inputs are specified with an extra unused bit
	on the left (pass a zero for this bit).
	Also note that the carry (borrow) input for a subtract has
	to be inverted. IE. ci = 1 = no borrow in.
	
=============================================================== */
`timescale 1ns / 100ps

module addsub(op, ci, a, b, o, co, v);
	parameter DBW = 32;
	input op;			// 0 = add, 1 = sub
	input ci;			// carry in
	input [DBW:0] a, b;	// operands input
	output [DBW-1:0] o;	// result
	output co;			// carry out
	output v;			// overflow

	reg [DBW+1:0] sum;

	// Note XST does not like assignments to bit group on LHS
	// for subtract
	always @(op or ci or a or b) begin
		case(op)
		1'd0:	sum <= {a,ci} + {b,1'b1};
		1'd1:	sum <= {a,ci} - {b,1'b1};
		endcase
	end

	assign o = sum[DBW:1];
	assign co = sum[DBW+1];
	// compute overflow
	assign v = (op ^ o[DBW-1] ^ b[DBW-1]) & (~op ^ a[DBW-1] ^ b[DBW-1]);

endmodule

