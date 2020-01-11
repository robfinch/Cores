module mult41(CLK, CE, A, B, P);
input CLK;
input CE;
input [40:0] A;
input [40:0] B;
output reg [81:0] P;

reg [81:0] P1;

always @(posedge CLK)
if (CE) begin
	P1 <= A * B;
	P <= P1;
end

endmodule
