/* ===============================================================
	2009  Robert Finch
	rob@birdcomputer.ca

	syncRam512x32_1rw3r.v

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

module syncRam512x32_1rw3r(
input wrst,
input wclk,
input wce,
input we,
input [8:0] wadr,
input [31:0] i,
output [31:0] wo,

input rrsta,
input rclka,
input rcea,
input [8:0] radra,
output [31:0] roa,

input rrstb,
input rclkb,
input rceb,
input [8:0] radrb,
output [31:0] rob,

input rrstc,
input rclkc,
input rcec,
input [8:0] radrc,
output [31:0] roc
);

syncRam512x32_1rw1r u1
(
	.wrst(wrst),
	.wclk(wclk),
	.wce(wce),
	.we(we),
	.wadr(wadr),
	.i(i),
	.wo(wo),
	.rrst(rrsta),
	.rclk(rclka),
	.rce(rcea),
	.radr(radra),
	.o(roa)
);

syncRam512x32_1rw1r u2
(
	.wrst(wrst),
	.wclk(wclk),
	.wce(wce),
	.we(we),
	.wadr(wadr),
	.i(i),
	.wo(),
	.rrst(rrstb),
	.rclk(rclkb),
	.rce(rceb),
	.radr(radrb),
	.o(rob)
);

syncRam512x32_1rw1r u3
(
	.wrst(wrst),
	.wclk(wclk),
	.wce(wce),
	.we(we),
	.wadr(wadr),
	.i(i),
	.wo(),
	.rrst(rrstc),
	.rclk(rclkc),
	.rce(rcec),
	.radr(radrc),
	.o(roc)
);

endmodule
