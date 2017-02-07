
module bootrom(clk_i, cs_i, cyc_i, stb_i, ack_o, adr_i, dat_o);
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input [15:0] adr_i;
output [31:0] dat_o;

wire cs = cs_i & cyc_i & stb_i;
reg [15:0] radr;
reg [31:0] rommem [0:8191];

reg ack;
always @(posedge clk_i)
    ack <= cs;
assign ack_o = cs ? ack : 1'b0;

initial begin
`include "C:\Cores4\MCMM\trunk\software\bootrom\bootrom.vh"
end

always @(posedge clk_i)
    radr <= adr_i;

assign dat_o = rommem[radr];

endmodule
