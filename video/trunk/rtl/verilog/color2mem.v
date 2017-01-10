module color2mem(mem_i, mb_i, me_i, color_i, mem_o);
input [127:0] mem_i;
input [6:0] mb_i;
input [6:0] me_i;
input [31:0] color_i;
output reg [127:0] mem_o;

reg [127:0] o2;
reg [127:0] mask;
integer nn,n;
always @(mb_i or me_i or nn)
	for (nn = 0; nn < 128; nn = nn + 1)
		mask[nn] <= (nn >= mb_i) ^ (nn <= me_i) ^ (me_i >= mb_i);

always @*
begin
	o2 = color_i << mb_i;
	for (n = 0; n < 128; n = n + 1) mem_o[n] = (mask[n] ? o2[n] : mem_i[n]);
end

endmodule
