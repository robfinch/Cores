
module Thor_tb();
reg rst;
reg clk;
reg nmi;
wire [2:0] cti;
wire cyc;
wire stb;
wire br_ack;
wire [31:0] adr;
wire [63:0] br_dato;

wire cpu_ack;
wire [63:0] cpu_dati;

initial begin
	#0 rst = 1'b0;
	#0 clk = 1'b0;
	#10 rst = 1'b1;
	#50 rst = 1'b0;
	#500 nmi = 1'b1;
	#20 nmi = 1'b0;
end

always #5 clk = ~clk;

wire cs0 = cyc&& stb && adr[31:16]==16'h0000;

assign cpu_ack =
	cs0 |
	br_ack
	;
assign cpu_dati =
	br_dato
	;
always @(posedge clk)
	$display("ubr adr:%h", ubr1.radr);

bootrom ubr1
(
	.rst_i(rst),
	.clk_i(clk),
	.cti_i(cti),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(br_ack),
	.adr_i(adr),
	.dat_o(br_dato),
	.perr()
);

Thor uthor1
(
	.rst_i(rst),
	.clk_i(clk),
	.nmi_i(nmi),
	.irq_i(1'b0),
	.vec_i(8'h00),
	.bte_o(),
	.cti_o(cti),
	.bl_o(),
	.cyc_o(cyc),
	.stb_o(stb),
	.ack_i(cpu_ack),
	.we_o(),
	.sel_o(),
	.adr_o(adr),
	.dat_i(cpu_dati),
	.dat_o()
);

endmodule
