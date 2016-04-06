
module friscv_node(num, rst_i, clk_i, net_i, net_o);
input [3:0] num;
input rst_i;
input clk_i;
input [127:0] net_i;
output [127:0] net_o;

wire [15:0] pc1,pc2;
wire [31:0] insn1,insn2;
wire cyc1,cyc2;
wire stb1,stb2;
wire ack1,ack2;
wire we1,we2;
wire [3:0] sel1, sel2;
wire [31:0] adr1, adr2;
wire [31:0] dato1, dato2;
wire [31:0] mdato1,mdato2;
wire [31:0] ncdato;
wire [31:0] dati1 = mdato1 | ncdato;
wire [31:0] dati2 = mdato2;
wire ncack;
wire ramack1, ramack2;
assign ack1 = ramack1|ncack;
assign ack2 = ramack2;

netctrl unet1
(
  .num(num),
  .rst(rst_i),
  .clk(clk_i),
  .cyc(cyc1),
  .stb(stb1),
  .ack(ncack),
  .we(we1),
  .adr(adr1),
  .dati(dato1),
  .dato(ncdato),
  .neti(net_i),
  .neto(net_o)
);

DualBootrom ubr1 (rst_i, clk_i, pc1, insn1, pc2, insn2);

reg rdy1a,rdy1b,rdy2a,rdy2b;
wire csram1 = cyc1 && stb1 && adr1[31:16]==16'h0;
wire csram2 = cyc2 && stb2 && adr2[31:16]==16'h0;
always @(posedge clk_i)
begin
  rdy2a <= csram2;
  rdy2b <= rdy2a & csram2;
  rdy1a <= csram1;
  rdy1b <= rdy1a & csram1;
end
assign ramack1 = csram1 ? (we1 ? 1'b1 : rdy1b) : 1'b0; 
assign ramack2 = csram2 ? (we2 ? 1'b1 : rdy2b) : 1'b0; 

dpram umem1
(
  .clka(clk_i),
  .ena(csram1),
  .wea(sel1 & {4{we1}}),
  .addra(adr1[15:2]),
  .dina(dato1),
  .douta(mdato1),
  .clkb(clk_i),
  .enb(csram2),
  .web(sel2 & {4{we2}}),
  .addrb(adr2[15:2]),
  .dinb(dato2),
  .doutb(mdato2)
);

friscv2 cpu1
(
  .rst_i(rst_i),
  .clk_i(clk_i),
  .cyc_o(cyc1),
  .stb_o(stb1),
  .ack_i(ack1),
  .we_o(we1),
  .sel_o(sel1),
  .adr_o(adr1),
  .dat_i(dati1),
  .dat_o(dato1),
  .pc(pc1),
  .insn(insn1)
);

friscv2 cpu2
(
  .rst_i(rst_i),
  .clk_i(clk_i),
  .cyc_o(cyc2),
  .stb_o(stb2),
  .ack_i(ack2),
  .we_o(we2),
  .sel_o(sel2),
  .adr_o(adr2),
  .dat_i(dati2),
  .dat_o(dato2),
  .pc(pc2),
  .insn(insn2)
);

endmodule
