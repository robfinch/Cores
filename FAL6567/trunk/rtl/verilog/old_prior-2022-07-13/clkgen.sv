module clkgen(clk100, clk14, clk28, clk8);
input clk100;
input clk14;
output reg clk28;
output reg clk8;
reg [3:0] clk14a;
reg clk2a;
reg clk2b;

reg [6:0] shifta = 0, shiftb = 0;

always @(posedge clk100)
	clk14a = {clk14a,clk14};

always @*
	clk28 = clk14a[2] ^ clk14;

always @(posedge clk28)
	shifta <= {shifta[5:0],~shifta[6]};	
always @(negedge clk28)
	shiftb <= shifta[2];	

always @*
	clk8 = shifta[6] ^ shiftb[6];

endmodule

module clkgen_tb();
reg clk100;
reg clk14;
wire clk28, clk8;

initial begin
clk100 = 0;
clk14 = 0;
end
always #5 clk100 = ~clk100;
always #34.9 clk14 = ~clk14;

clkgen ucg1 (clk100, clk14, clk28, clk8);

endmodule
