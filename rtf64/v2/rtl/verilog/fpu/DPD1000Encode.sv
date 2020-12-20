
module DPD1000Encode(i, o);
input [11:0] i;
output [9:0] o;

assign o = i[3:0] + i[7:4] * 10 + i[11:8] * 100;

endmodule

module DPD1000EncodeN(i, o);
parameter N=11;
input [N*12-1:0] i;
output [N*10-1:0] o;

genvar g;
generate begin : gDPDEncodeN
	for (g = 0; g < N; g = g + 1)
		DPD1000Encode u1 (i[g*12+11:g*12],o[g*10+9:g*10]);
end
endgenerate

endmodule
