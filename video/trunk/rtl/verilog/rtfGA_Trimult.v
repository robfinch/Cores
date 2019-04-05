
module rtfGA_Trimult(CLK, A, B, P);
parameter WID=64;
input CLK;
input [WID:1] A;
input [WID:1] B;
output [WID*2:1] P;

always @(posedge CLK)
	P = A * B;

endmodule