module mult11(CLK, CE, A, B, P);
input CLK;
input CE;
input [10:0] A;
input [10:0] B;
output reg [21:0] P;

reg [21:0] P1;

always @(posedge CLK)
if (CE) begin
	P1 <= A * B;
	P <= P1;
end

endmodule
