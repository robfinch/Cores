
module rtf6809_sys(clk,btn);
input clk;
input [5:0] btn;

wire [15:0] pc;
wire [63:0] insn;

rtf6809_rom urom1
(
	.rclk(~clk),
	.rce(1'b1),
	.pc(pc),
	.insn(insn)
);

rtf6809 ucpu1
(
	.rst_i(rst),
	.clk_i(clk50),
	.halt_i(),
	.nmi_i(),
	.irq_i(),
	.firq_i(),
	.ba_o(),
	.bs_o(),
	.pc(pc),
	.insn(insn)
);

endmodule
