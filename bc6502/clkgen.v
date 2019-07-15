/* ===============================================================
	(C) 2001 Bird Computer
	All rights reserved.

	clkgen.v
		Please read the Licensing Agreement
	(license.html file). Use of this file is subject to the
	license agreement.
		System clock generator. Generates clock enables for
	various parts of the system.
=============================================================== */
`timescale 1ns / 100ps

module clkgen(reset, clki, clk, wse);
	input reset;
	input clki;		// 50 MHz
	output clk;		// 25 MHz
	output wse;
	
	wire clk0;
	wire clkdv;
	wire clkfb;
	BUFG bg0(.I(clk0), .O(clkfb));
	BUFG bg1(.I(clkdv), .O(clk));

	CLKDLL cd0(.RST(1'b0), .CLKIN(clki), .CLKFB(clkfb), .CLK0(clk0), .CLKDV(clkdv) );
	// synthesis attribute CLKDV_DIVIDE of cd0 is 2

	reg c0, c1;
	assign wse = ~c1;

	always @(posedge clk0) begin
		if (reset)
			c0 <= 1'b0;
		else
			c0 <= ~c0;
	end

	always @(negedge clk0) begin
		if (reset)
			c1 <= 1'b0;
		else
			c1 <= c0;
	end

endmodule
