
import nPower::*;

module nPower_tb();

reg rst;
reg clk;
wire vpa;
wire cyc;
wire stb;
wire ack = cyc & stb;
wire we;
wire [7:0] sel;
wire [AWID-1:0] adr;
wire [63:0] dato;
wire [63:0] dati = NOP_INSN;

initial begin
  #0 rst = 1'b0;
  #0 clk = 1'b0;
  #20 rst = 1'b1;
  #200 rst = 1'b0;
end

always #5 clk = ~clk;

nPower ucpu1
(
  .rst_i(rst),
  .clk_i(clk),
  .vpa_o(vpa),
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .we_o(we),
  .sel_o(sel),
  .adr_o(adr),
  .dat_i(dati),
  .dat_o(dato)
);

endmodule
