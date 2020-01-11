module mult65(CLK, CE, A, B, P);
input CLK;
input CE;
input [64:0] A;
input [64:0] B;
output reg [129:0] P;

reg [129:0] P1;

always @(posedge CLK)
if (CE) begin
	P1 <= A * B;
	P <= P1;
end

endmodule
