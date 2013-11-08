
module Thor_tb();
reg rst;
reg clk;
reg nmi;

initial begin
	#0 rst = 1'b0;
	#0 clk = 1'b0;
	#10 rst = 1'b1;
	#50 rst = 1'b0;
	#500 nmi = 1'b1;
	#20 nmi = 1'b0;
end

always #5 clk = ~clk;

Thor uthor1
(
	.rst_i(rst),
	.clk_i(clk),
	.nmi_i(nmi),
	.irq_i(1'b0),
	.vec_i(8'h00),
	.bte_o(),
	.cti_o(),
	.bl_o(),
	.cyc_o(),
	.stb_o(),
	.ack_i(1'b1),
	.we_o(),
	.sel_o(),
	.adr_o(),
	.dat_i({8{8'h10}}),
	.dat_o()
);

endmodule
