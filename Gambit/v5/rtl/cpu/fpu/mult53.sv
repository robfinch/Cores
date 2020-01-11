module mult53(CLK, CE, A, B, P);
input CLK;
input CE;
input [52:0] A;
input [52:0] B;
output reg [105:0] P;

reg [105:0] P1;

always @(posedge CLK)
if (CE) begin
	P1 <= A * B;
	P <= P1;
end

endmodule
