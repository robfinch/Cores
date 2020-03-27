module ThorSoc(sys_rst, sys_clk, /*ip, insn, wr, rdy, ad, dati, dato,*/ wr, rdy,ad,dati,dato);
input sys_rst;
input sys_clk;
output wr;
input rdy;
output [23:0] ad;
input [63:0] dati;
output [63:0] dato;

wire clk100, clk200;
wire cpu_clk = clk100;
wire locked;
wire rst = !locked;

wire icyc;
wire [31:0] iadr;
wire [127:0] idat;

ThorSoCclkgen ucg1
(
  // Clock out ports
  .clk200(clk200),
  .clk100(clk100),
  .reset(sys_rst),
  .locked(locked),
 // Clock in ports
  .clk_in1(sys_clk)
);

wire cs_rom = iadr[31:26]==6'h3F;

Thor2020 ucpu1
(
	.rst(rst),
	.clk(cpu_clk),
	.icyc_o(icyc),
	.istb_o(),
	.iack_i(icyc),
	.iadr_o(iadr),
	.idat_i(128'd0),
	.wr(wr),
	.rdy(rdy),
	.ad(ad),
	.dato(dato),
	.dati(dati)
);

endmodule
