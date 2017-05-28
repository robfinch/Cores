
module basicrom(clk, ad, o);
input clk;
input [13:0] ad;
output reg [7:0] o;

reg [32:0] rommem [0:4095];
reg [13:0] radr;

initial begin
`include "C:\cores3\ft816\trunk\software\asm\basic.ver"
end

always @(posedge clk)
    radr <= ad;
wire [31:0] o1 = rommem[radr[13:2]];
always @(posedge clk)
case(radr[1:0])
2'b00:  o = o1[7:0];
2'b01:  o = o1[15:8];
2'b10:  o = o1[23:16];
2'b11:  o = o1[31:24];
endcase

endmodule
