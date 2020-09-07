module ReadyQueues(rst_i, clk_i, insert_i, remove_i, tid_i, priority_i, tid_o);
parameter NQ = 8;
input rst_i;
input clk_i;
input insert_i;
input remove_i;
input [31:0] tid_i;
input [2:0] priority_i;
output reg [31:0] tid_o;

reg [NQ-1:0] wrq;
reg [5:0] qndx [0:NQ-1];
wire [31:0] tid [0:NQ-1];

integer n;
genvar g;
generate begin : ques
for (g = 0; g < NQ; g = g + 1)
  vtdl #(32,64) uq1 (clk_i, wrq[g], qndx[g], tid_i, tid[g]);
end
endgenerate

always @(posedge clk_i)
if (rst_i) begin
  for (n = 0; n < NQ; n = n + 1)  
    qndx[n] <= 6'd0;
end
else begin
	for (n = 0; n < NQ; n = n + 1) 
		wrq[n] <= 1'b0;
	if (remove_i) begin
		if (~|qndx[priority_i])
			tid_o <= 32'd0;
		else
			tid_o <= tid[priority_i];
		if (|qndx[priority_i])
			qndx[priority_i] <= qndx[priority_i] - 2'd1;
	end
	else if (insert_i) begin
		wrq[priority_i] <= 1'b1;
		if (~&qndx[priority_i]) begin
			qndx[priority_i] <= qndx[priority_i] + 2'd1;
		end
	end
end

endmodule
