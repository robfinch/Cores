
module friscv_tb();

reg rst;
reg clk;
wire [1:0] bte;
wire [2:0] cti;
wire cyc;
wire stb;
wire br_ack;
wire [31:0] br_do;
wire [31:0] adr;
wire we;
wire [31:0] cpu_do;
wire tc_ack;
wire [31:0] tc_do;

initial begin
	#0 clk = 1'b0;
	#0 rst = 1'b0;
	#20 rst = 1'b1;
	#100 rst = 1'b0;
end

always #5 clk = ~clk;

friscv u1
(
	.rst_i(rst),
	.clk_i(clk),
	.bte_o(bte),
	.cti_o(cti),
	.bl_o(),
	.cyc_o(cyc),
	.stb_o(stb),
	.ack_i(br_ack|tc_ack),
	.we_o(we),
	.sel_o(),
	.adr_o(adr),
	.dat_i(br_do|tc_do),
	.dat_o(cpu_do)
);

bootrom u2
(
	.rst_i(rst),
	.clk_i(clk),
	.cti_i(cti),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(br_ack),
	.adr_i(adr),
	.dat_o(br_do),
	.perr()
);

rtfTextController3 u3
(
	.rst_i(rst),
	.clk_i(clk),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(tc_ack),
	.we_i(we),
	.adr_i(adr),
	.dat_i(cpu_do),
	.dat_o(tc_do),
	.lp(),
	.curpos(),
	.vclk(),
	.hsync(),
	.vsync(),
	.blank(),
	.border(),
	.rgbIn(),
	.rgbOut()
);

always @(posedge clk)
	$display("%d: %h mres=%h pc=%h ir=%h xir=%h xopcode=%h.%h %s", $time, adr, u1.mres, u1.pc, u1.ir, u1.xir, u1.xopcode, u1.xfunct3, u1.fnStateName(u1.state));

endmodule
