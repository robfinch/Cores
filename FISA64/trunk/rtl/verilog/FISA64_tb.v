module FISA64_tb();
reg rst;
reg clk;
wire cyc;
wire stb;
wire we;
wire [7:0] sel;
wire [31:0] adr;
wire [63:0] cpu_dati,cpu_dato,rom_dato,ram_dato,scm_dato;
wire [31:0] tc_dato;
wire br_ack, tc_ack;

initial begin
	#0 clk = 1'b0;
	#0 rst = 0;
	#100 rst = 1;
	#200 rst = 0;
end

always #5 clk = ~clk;

wire cs_ram = adr[31:16]==16'd0;
wire cs_rom = adr[31:16]==16'd1;
wire cs_leds = adr[31:8]==24'hFFDC06 && cyc && stb;

FISA64 u1 (
	.rst_i(rst),
	.clk_i(clk),
	.clk_o(),
	.nmi_i(0),
	.irq_i(0),
	.vect_i(0),
	.bte_o(),
	.cti_o(),
	.bl_o(),
	.cyc_o(cyc),
	.stb_o(stb),
	.ack_i(br_ack | cs_leds | tc_ack | scm_ack),
	.err_i(0),
	.we_o(we),
	.sel_o(sel),
	.adr_o(adr),
	.dat_i(cpu_dati),
	.dat_o(cpu_dato)
);

bootrom u2 (
	.rst_i(rst),
	.clk_i(clk),
	.cti_i(0),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(br_ack),
	.adr_i(adr),
	.dat_o(rom_dato),
	.perr()
);

RAM u3 (
	.clk(clk),
	.cs(cs_ram),
	.wr(we),
	.sel(sel),
	.adr(adr[15:0]),
	.dat_o(ram_dato),
	.dat_i(cpu_dato)
);

scratchmem u4 (
	.rst_i(rst),
	.clk_i(clk),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(scm_ack),
	.we_i(we),
	.sel_i(sel),
	.adr_i(adr),
	.dat_i(cpu_dato),
	.dat_o(scm_dato)
);

rtfTextController3 utc3
(
	.rst_i(rst), .clk_i(clk),
	.cyc_i(cyc), .stb_i(stb), .ack_o(tc_ack), .we_i(we), .adr_i(adr), .dat_i(cpu_dato), .dat_o(tc_dato),
	.lp(), .curpos(),
	.vclk(), .hsync(), .vsync(), .blank(), .border(), .rgbIn(), .rgbOut()
);


assign cpu_dati = rom_dato | {2{tc_dato}} | scm_dato;

always @(posedge clk)
begin
	$display("%d %h %h c=%h sp=%h %s", $time, u1.pc, u1.ir, u1.c, u1.sp, u1.fnStateName(u1.state));
	$display("%cres2=%h wres2=%h", (u1.xRt2==1'b1)?"S":" ",u1.res2, u1.wres2);
end
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

module RAM(clk,cs,wr,sel,adr,dat_i,dat_o);
input clk;
input cs;
input wr;
input [7:0] sel;
input [15:0] adr;
input [63:0] dat_i;
output reg [63:0] dat_o;

reg [63:0] mem [0:2047];

always @(posedge clk)
	if (cs & wr) begin
		if (sel[0]) mem[adr[13:3]][7:0] <= dat_i[7:0];
		if (sel[1]) mem[adr[13:3]][15:8] <= dat_i[15:8];
		if (sel[2]) mem[adr[13:3]][23:16] <= dat_i[23:16];
		if (sel[3]) mem[adr[13:3]][31:24] <= dat_i[31:24];
		if (sel[4]) mem[adr[13:3]][39:32] <= dat_i[39:32];
		if (sel[5]) mem[adr[13:3]][47:40] <= dat_i[47:40];
		if (sel[6]) mem[adr[13:3]][55:48] <= dat_i[55:48];
		if (sel[7]) mem[adr[13:3]][63:56] <= dat_i[63:56];
	end

always @*
	dat_o = mem[adr[13:3]];

endmodule

module TEXTCTRL(clk,cs,wr,sel,adr,dat_i,dat_o);
input clk;
input cs;
input wr;
input [3:0] sel;
input [15:0] adr;
input [31:0] dat_i;
output reg [31:0] dat_o;

reg [31:0] mem [0:2047];

always @(posedge clk)
	if (cs & wr) begin
		if (sel[0]) mem[adr[12:2]][7:0] <= dat_i[7:0];
		if (sel[1]) mem[adr[12:2]][15:8] <= dat_i[15:8];
		if (sel[2]) mem[adr[12:2]][23:16] <= dat_i[23:16];
		if (sel[3]) mem[adr[12:2]][31:24] <= dat_i[31:24];
	end

always @*
	dat_o = mem[adr[12:2]];

endmodule

