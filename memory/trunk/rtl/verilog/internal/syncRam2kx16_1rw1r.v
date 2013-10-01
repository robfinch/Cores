/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca

	syncRam2kx16_1rw1r.v

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


=============================================================== */

`define SYNTHESIS
`define VENDOR_XILINX
`define SPARTAN3

module syncRam2kx16_1rw1r(
	input wrst,
	input wclk,
	input wce,
	input we,
	input [1:0] wsel,
	input [10:0] wadr,
	input [15:0] i,
	output [15:0] wo,
	input rrst,
	input rclk,
	input rce,
	input [10:0] radr,
	output [15:0] o
);

syncRam2kx8_1rw1r u1
(
	.wrst(wrst),
	.wclk(wclk),
	.wce(wce),
	.we(we & wsel[0]),
	.wadr(wadr),
	.i(i[7:0]),
	.wo(wo[7:0]),
	.rrst(rrst),
	.rclk(rclk),
	.rce(rce),
	.radr(radr),
	.o(o[7:0])
);

syncRam2kx8_1rw1r u2
(
	.wrst(wrst),
	.wclk(wclk),
	.wce(wce),
	.we(we & wsel[1]),
	.wadr(wadr),
	.i(i[15:8]),
	.wo(wo[15:8]),
	.rrst(rrst),
	.rclk(rclk),
	.rce(rce),
	.radr(radr),
	.o(o[15:8])
);

endmodule
