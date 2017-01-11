module fd2s(a, o);
	input [63:0] a;
	output [31:0] o;
	
	assign o[31] = a[63];
	assign o[22:0] = a[51:29];

endmodule
