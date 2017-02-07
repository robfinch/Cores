
module scratchram2(clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o);
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [3:0] sel_i;
input [13:0] adr_i;
input [31:0] dat_i;
output [31:0] dat_o;

reg ack;
wire cs = cs_i & cyc_i & stb_i;
always @(posedge clk_i)
    ack <= cs;
assign ack_o = cs ? (we_i ? 1'b1 : ack) : 1'b0;

reg [13:0] radr;
reg [31:0] mem [0:4095];

always @(posedge clk_i)
if (cs & we_i) begin
    if (sel_i[0]) mem[adr_i[13:2]][7:0] <= dat_i[7:0];
    if (sel_i[1]) mem[adr_i[13:2]][15:8] <= dat_i[15:8];
    if (sel_i[2]) mem[adr_i[13:2]][23:16] <= dat_i[23:16];
    if (sel_i[3]) mem[adr_i[13:2]][31:24] <= dat_i[31:24];
end

always @(posedge clk_i)
    radr <= adr_i;

assign dat_o = mem[radr];

endmodule
