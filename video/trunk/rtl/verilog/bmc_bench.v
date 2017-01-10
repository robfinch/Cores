module bmc_bench();

reg vclk;
reg clk;
reg s_clk;
reg rst;
wire m_cyc;
wire [31:0] m_adr;
wire [23:0] rgbo;
wire hsync,vsync;

initial begin
	vclk = 0;
	clk = 0;
	s_clk = 0;
	rst = 0;
	#10 rst = 1;
	#50 rst = 0;
end

always #12.5 vclk = ~vclk;
always #10 clk = ~clk;
always #30 s_clk = ~s_clk;

WXGASyncGen1366x768_60Hz usync
(
	.rst(rst),
	.clk(vclk),
	.hSync(hsync),
	.vSync(vsync),
	.blank(blank),
	.border(),
	.eol(),
	.eof()
);

rtfBitmapController5 ubmc
(
	.rst_i(rst),
	.s_clk_i(s_clk),
	.s_cyc_i(),
	.s_stb_i(),
	.s_ack_o(),
	.s_we_i(),
	.s_adr_i(),
	.s_dat_i(),
	.s_dat_o(),
	.irq_o(),
	
	.m_clk_i(clk),
	.m_bte_o(),
	.m_cti_o(),
	.m_cyc_o(m_cyc),
	.m_stb_o(),
	.m_ack_i(m_cyc),
	.m_we_o(),
	.m_sel_o(),
	.m_adr_o(m_adr),
	.m_dat_i({4{m_adr}}),
	.m_dat_o(),
	
	.vclk(vclk),
	.hsync(hsync),
	.vsync(vsync),
	.blank(blank),
	.rgbo(rgbo),
	.xonoff(1'b1)
);

endmodule
