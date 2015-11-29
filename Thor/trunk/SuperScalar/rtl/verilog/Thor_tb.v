
module Thor_tb();
parameter DBW=32;
reg rst;
reg clk;
reg nmi;
wire [2:0] cti;
wire cyc;
wire stb;
wire we;
wire [7:0] sel;
wire br_ack;
wire [31:0] adr;
wire [DBW-1:0] br_dato;
wire scr_ack;
wire [63:0] scr_dato;

wire cpu_ack;
wire [DBW-1:0] cpu_dati;
wire [DBW-1:0] cpu_dato;

wire LEDS_ack;

initial begin
	#0 rst = 1'b0;
	#0 clk = 1'b0;
	#0 nmi = 1'b0;
	#10 rst = 1'b1;
	#50 rst = 1'b0;
	#500 nmi = 1'b1;
	#20 nmi = 1'b0;
end

always #5 clk = ~clk;

assign LEDS_ack = cyc && stb && adr[31:8]==32'hFFDC06;
always @(posedge clk)
	if (LEDS_ack)
		$display("LEDS: %b", cpu_dato[7:0]);

wire tc_ack = cyc && stb && (adr[31:16]==16'hFFD0);

//wire cs0 = cyc&& stb && adr[31:16]==16'h0000;

assign cpu_ack =
	LEDS_ack |
	scr_ack |
	br_ack |
	tc_ack
	;
assign cpu_dati =
	scr_dato |
	br_dato
	;

scratchmem32 #(DBW) uscrm1
(
	.rst_i(rst),
	.clk_i(clk),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(scr_ack),
	.we_i(we),
	.sel_i(sel),
	.adr_i({32'd0,adr}),
	.dat_i(cpu_dato),
	.dat_o(scr_dato)
);

bootrom #(DBW) ubr1
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

Thor #(DBW) uthor1
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
	.err_i(1'b0),
	.we_o(we),
	.sel_o(sel),
	.adr_o(adr),
	.dat_i(cpu_dati),
	.dat_o(cpu_dato)
);

endmodule
