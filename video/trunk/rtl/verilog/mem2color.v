
// do a bitfield extract of color data
module mem2color(mem_i, mb_i, me_i, color_o);

input  [127:0] mem_i;
input [6:0] mb_i;
input [6:0] me_i;
output reg [31:0] color_o;

reg [127:0] mask;
reg [127:0] o1;
integer nn,n;
always @(mb_i or me_i or nn)
	for (nn = 0; nn < 128; nn = nn + 1)
		mask[nn] <= (nn >= mb_i) ^ (nn <= me_i) ^ (me_i >= mb_i);
always @*
begin
	for (n = 0; n < 128; n = n + 1)
		o1[n] = mask[n] ? mem_i[n] : 1'b0;
	color_o <= o1 >> mb_i;
end

endmodule

