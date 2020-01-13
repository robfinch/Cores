
module Gambit_tb();
reg rst;
reg clk;
reg clk2x;
reg clk4x;
wire [7:0] led;

wire ddr3_reset_n;
wire ddr3_ck_p;
wire ddr3_ck_n;
wire ddr3_cke;
wire ddr3_ras_n;
wire ddr3_cas_n;
wire ddr3_we_n;
wire [2:0] ddr_ba;
wire [14:0] ddr3_addr;
wire [15:0] ddr3_dq;
wire [1:0] ddr3_dqs_p;
wire [1:0] ddr3_dqs_n;
wire [1:0] ddr3_dm;
wire [0:0] ddr3_odt;

integer n;
genvar g;

wire cyc;
wire stb;
wire we;
wire [7:0] sel;
wire [51:0] adr;
wire [103:0] dato, dati;
reg [103:0] mem [0:4095];
assign dati = mem[adr[14:3]];
initial begin
	for (n = 0; n < 4096; n = n + 1)
		mem[n] = 104'd0;
end
generate begin : memwr
for (g = 0; g < 8; g = g + 1)
	always @(posedge clk)
		if (stb & we & sel[g]) begin
			mem[adr[14:3]][g*13+:13] = dato[g*13+:13];
			$display("writemem: %h = %h", adr, dato);
		end
end
endgenerate

initial begin
    rst = 0;
    clk = 0;
    clk2x = 0;
    clk4x = 0;
    #10 rst = 1;
    #150 rst = 0;
end

always #3 clk4x = ~clk4x;
always #6 clk2x = ~clk2x;
always #12 clk = ~clk;

//always #4000 irq = ~irq;

Gambit ucpu1
(
	.rst_i(rst),
	.clk_i(clk),
	.clk2x_i(clk2x),	// needed by branch predictor
	.clk4x_i(clk4x),
	.tm_clk_i(1'b0),
	.nmi_i(1'b0),
	.irq_i(3'b0),
	.bte_o(),
	.cti_o(),
	.bok_i(1'b1),
	.cyc_o(cyc),
	.stb_o(stb),
	.ack_i(stb),
	.err_i(),
	.we_o(we),
	.sel_o(sel),
	.adr_o(adr),
	.dat_o(dato),
	.dat_i(dati),
  .icl_o(),
  .exc_o()
);


/*
ddr3 uddr31
(
    .rst_n(ddr3_reset_n),
    .ck(ddr3_ck_p),
    .ck_n(ddr3_ck_n),
    .cke(ddr3_cke),
    .cs_n(1'b0),
    .ras_n(ddr3_ras_n),
    .cas_n(ddr3_cas_n),
    .we_n(ddr3_we_n),
    .dm_tdqs(ddr3_dm),
    .ba(ddr3_ba),
    .addr(ddr3_addr),
    .dq(ddr3_dq),
    .dqs(ddr3_dqs_p),
    .dqs_n(ddr3_dqs_n),
    .tdqs_n(),
    .odt(ddr3_odt)
);
*/

endmodule
