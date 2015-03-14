module FISA64_tb();
reg rst;
reg clk;
wire cyc;
wire stb;
wire [31:0] adr;
wire [63:0] cpu_dati,rom_dato;

initial begin
	#0 clk = 1'b0;
	#0 rst = 0;
	#100 rst = 1;
	#200 rst = 0;
end

always #5 clk = ~clk;

FISA64 u1 (
	.rst_i(rst),
	.clk_i(clk),
	.nmi_i(0),
	.irq_i(0),
	.vect_i(0),
	.bte_o(),
	.cti_o(),
	.bl_o(),
	.cyc_o(cyc),
	.stb_o(stb),
	.ack_i(cyc&stb),
	.we_o(),
	.sel_o(),
	.adr_o(adr),
	.dat_i(cpu_dati),
	.dat_o()
);

ROM u2 (
	.adr(adr[15:0]),
	.dat_o(rom_dato)
);

assign cpu_dati = rom_dato;

endmodule

module ROM(adr,dat_o);
input [15:0] adr;
output reg [63:0] dat_o;

reg [64:0] rommem [0:8191];
initial begin
`include "..\..\software\test\test_prog.ver"
end

always @*
	dat_o = rommem[adr[15:3]][63:0];

endmodule
