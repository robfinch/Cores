
module DPD1000Decode(clk, i, o);
input clk;
input [9:0] i;
output [11:0] o;

reg [9:0] i1;
genvar g;

(* ram_style="block" *)
reg [11:0] tbl [0:1023];

generate begin : gDPDTbl
for (g = 0; g < 1024; g = g + 1) begin
	initial begin
		tbl[g] = (g % 10) | (((g / 10) & 15) << 4) | (((g/100) & 15) << 8);
	end
end
end
endgenerate

always @(posedge clk)
	i1 <= i;
	
assign o = tbl[i1];

endmodule

module DPDDecodeN(clk, i, o);
parameter N=11;
input clk;
input [N*10-1:0] i;
output [N*12-1:0] o;

genvar g;

generate begin : gDPD
	for (g = 0; g < N; g = g + 1)
		DPD1000Decode(clk, i[g*10+9:g*10], o[g*12+11:g*12]);
end
endgenerate

endmodule
