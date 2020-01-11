module mult24(CLK, CE, A, B, P);
input CLK;
input CE;
input [23:0] A;
input [23:0] B;
output reg [47:0] P;

reg [47:0] P1;

always @(posedge CLK)
if (CE) begin
	P1 <= A * B;
	P <= P1;
end

endmodule
