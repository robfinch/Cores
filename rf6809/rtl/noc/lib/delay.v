/* ===============================================================
	(C) 2006-2021  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca

	delay.v
		- delays signals by so many clock cycles


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

module delay1
	#(parameter WID = 1)
	(
	input clk,
	input ce,
	input [WID:1] i,
	output reg [WID:1] o
	);

	always @(posedge clk)
		if (ce)
			o <= i;

endmodule


module delay2
	#(parameter WID = 1)
	(
	input clk,
	input ce,
	input [WID:1] i,
	output reg [WID:1] o
	);


	reg	[WID:1]	r1;
	
	always @(posedge clk)
		if (ce)
			r1 <= i;
	
	always @(posedge clk)
		if (ce)
			o <= r1;
	
endmodule


module delay3
	#(parameter WID = 1)
	(
	input clk,
	input ce,
	input [WID:1] i,
	output reg [WID:1] o
	);

	reg	[WID:1] r1, r2;
	
	always @(posedge clk)
		if (ce)
			r1 <= i;
	
	always @(posedge clk)
		if (ce)
			r2 <= r1;
	
	always @(posedge clk)
		if (ce)
			o <= r2;
			
endmodule
	
module delay4
	#(parameter WID = 1)
	(
	input clk,
	input ce,
	input [WID-1:0] i,
	output reg [WID-1:0] o
	);

	reg	[WID-1:0] r1, r2, r3;
	
	always @(posedge clk)
		if (ce)
			r1 <= i;
	
	always @(posedge clk)
		if (ce)
			r2 <= r1;
	
	always @(posedge clk)
		if (ce)
			r3 <= r2;
	
	always @(posedge clk)
		if (ce)
			o <= r3;

endmodule

	
module delay5
#(parameter WID = 1)
(
	input clk,
	input ce,
	input [WID:1] i,
	output reg [WID:1] o
);

	reg	[WID:1] r1, r2, r3, r4;
	
	always @(posedge clk)
		if (ce) r1 <= i;
	
	always @(posedge clk)
		if (ce) r2 <= r1;
	
	always @(posedge clk)
		if (ce) r3 <= r2;
	
	always @(posedge clk)
		if (ce) r4 <= r3;
	
	always @(posedge clk)
		if (ce) o <= r4;
	
endmodule

module delay6
#(parameter WID = 1)
(
	input clk,
	input ce,
	input [WID:1] i,
	output reg [WID:1] o
);

	reg	[WID:1] r1, r2, r3, r4, r5;
	
	always @(posedge clk)
		if (ce) r1 <= i;
	
	always @(posedge clk)
		if (ce) r2 <= r1;
	
	always @(posedge clk)
		if (ce) r3 <= r2;
	
	always @(posedge clk)
		if (ce) r4 <= r3;
	
	always @(posedge clk)
		if (ce) r5 <= r4;
	
	always @(posedge clk)
		if (ce) o <= r5;
	
endmodule

module ft_delay(clk, ce, i, o);
parameter WID = 1;
parameter DEP = 1;
input clk;
input ce;
input [WID-1:0] i;
output [WID-1:0] o;

reg [WID-1:0] pldreg [0:DEP-1];

genvar g;
generate begin : gPipeline
  always @(posedge clk)
    if (ce) pldreg[0] <= i;
  for (g = 0; g < DEP - 1; g = g + 1)
    always @(posedge clk)
      if (ce) pldreg[g+1] <= pldreg[g];
  assign o = pldreg[DEP-1];    
end
endgenerate

endmodule
