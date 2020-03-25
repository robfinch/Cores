module Tiny32Soc(sys_rst, sys_clk, /*ip, insn, wr, rdy, ad, dati, dato,*/ ip2, insn2, wr2, rdy2,ad2,dati2,dato2);
input sys_rst;
input sys_clk;
/*
output [23:0] ip;
input [31:0] insn;
output wr;
input rdy;
output [23:0] ad;
input [31:0] dati;
output [31:0] dato;
*/
output [23:0] ip2;
input [127:0] insn2;
output wr2;
input rdy2;
output [23:0] ad2;
input [63:0] dati2;
output [63:0] dato2;

wire clk100, clk200;
wire cpu_clk = clk100;
wire locked;
wire rst = !locked;

Tiny32clkgen ucg1
(
  // Clock out ports
  .clk200(clk200),
  .clk100(clk100),
  .reset(sys_rst),
  .locked(locked),
 // Clock in ports
  .clk_in1(sys_clk)
);

/*
FT20200324 ucpu1
(
	.rst(rst),
	.clk(cpu_clk),
	.ip(ip),
	.insn(insn),
	.wr(wr),
	.rdy(rdy),
	.ad(ad),
	.dato(dato),
	.dati(dati)
);
*/

FTIA64 ucpu2
(
	.rst(rst),
	.clk(cpu_clk),
	.ip(ip2),
	.insn(insn2),
	.wr(wr2),
	.rdy(rdy2),
	.ad(ad2),
	.dato(dato2),
	.dati(dati2)
);

endmodule
