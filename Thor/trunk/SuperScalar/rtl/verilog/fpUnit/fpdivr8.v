/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca

	fpdivr8.v
		Radix 8 floating point divider primitive


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


	Performance
	Webpack 7.1i  xc3s1000-4ft256
	222 slices / 410 LUTs / 51.5 MHz
=============================================================== */

module fpdivr8
#(	parameter WID = 24 )
(
	input clk,
	input ld,
	input [WID-1:0] a,
	input [WID-1:0] b,
	output reg [WID*2-1:0] q,
	output [WID-1:0] r,
	output done
);
	localparam DMSB = WID-1;

	wire [DMSB:0] rx [2:0];		// remainder holds
	reg [DMSB:0] rxx;
	reg [5:0] cnt;				// iteration count
	wire [DMSB:0] sdq;
	wire [DMSB:0] sdr;
	wire sdval;
	wire sddbz;
	
	specialCaseDivider #(WID) u1 (.a(a), .b(b), .q(sdq), .val(sdval), .dbz(sdbz) );


	assign rx[0] = rxx  [DMSB] ? {rxx  ,q[WID*2-1  ]} + b : {rxx  ,q[WID*2-1  ]} - b;
	assign rx[1] = rx[0][DMSB] ? {rx[0],q[WID*2-1-1]} + b : {rx[0],q[WID*2-1-1]} - b;
	assign rx[2] = rx[1][DMSB] ? {rx[1],q[WID*2-1-2]} + b : {rx[1],q[WID*2-1-2]} - b;


	always @(posedge clk)
		if (ld)
			cnt <= sdval ? 6'b100000 : WID*2/3;
		else if (!done)
			cnt <= cnt - 1;


	always @(posedge clk)
		if (ld)
			rxx <= 0;
		else if (!done)
			rxx <= rx[2];


	always @(posedge clk)
		if (ld) begin
			if (sdval)
				q <= {sdq,{WID{1'b0}}};
			else
				q <= {a,{WID{1'b0}}};
		end
		else if (!done) begin
			q[WID*2-1:3] <= q[WID*2-1-3:0];
			q[0] <= ~rx[2][DMSB];
			q[1] <= ~rx[1][DMSB];
			q[2] <= ~rx[0][DMSB];
		end

	// correct remainder
	assign r = sdval ? sdr : rx[2][DMSB] ? rx[2] + b : rx[2];
	assign done = cnt[5];

endmodule

/*
module fpdiv_tb();

	reg rst;
	reg clk;
	reg ld;
	reg [6:0] cnt;

	wire ce = 1'b1;
	wire [49:0] a = 50'h0_0000_0400_0000;
	wire [23:0] b = 24'd101;
	wire [49:0] q;
	wire [49:0] r;
	wire done;

	initial begin
		clk = 1;
		rst = 0;
		#100 rst = 1;
		#100 rst = 0;
	end

	always #20 clk = ~clk;	//  25 MHz
	
	always @(posedge clk)
		if (rst)
			cnt <= 0;
		else begin
			ld <= 0;
			cnt <= cnt + 1;
			if (cnt == 3)
				ld <= 1;
			$display("ld=%b q=%h r=%h done=%b", ld, q, r, done);
		end
	

	fpdivr8 divu0(.clk(clk), .ce(ce), .ld(ld), .a(a), .b(b), .q(q), .r(r), .done(done) );

endmodule

*/

