module FISA64_tb();
reg rst;
reg clk;
wire [8:0] vecno;
wire cyc;
wire stb;
wire we;
wire [7:0] sel;
wire [31:0] adr;
wire [63:0] cpu_dati,cpu_dato,rom_dato,ram_dato,scm_dato;
wire sr_o;
wire cpu_irq;
wire [31:0] tc_dato;
wire br_ack, tc_ack;
wire io3_cyc,io3_stb,io3_we;
wire [3:0] io3_sel;
wire iob3_ack;
wire [31:0] io3_adr;
wire [31:0] io3_dato,iob3_dato;
wire kbd_ack,pic_ack;
wire [7:0] kbd_dato;
wire [31:0] pic_dato;
reg pulse1024,pulse60;

initial begin
	#0 clk = 1'b0;
	#0 rst = 0;
	#0 pulse1024 = 0;
	#100 rst = 1;
	#200 rst = 0;
	#500000 pulse1024 = 1;
	#100 pulse1024 = 0;
	#1000000 pulse60 = 1;
	#100 pulse60 = 0;
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
	.irq_i(cpu_irq),
	.vect_i(vecno),
	.bte_o(),
	.cti_o(),
	.bl_o(),
	.cyc_o(cyc),
	.stb_o(stb),
	.ack_i(br_ack | cs_leds | iob3_ack | scm_ack | kbd_ack | pic_ack),
	.err_i(0),
	.we_o(we),
	.sel_o(sel),
	.adr_o(adr),
	.dat_i(cpu_dati),
	.dat_o(cpu_dato),
	.sr_o(sr_o)
);

FISA64_pic u_pic
(
	.rst_i(rst),		// reset
	.clk_i(clk),		// system clock
	.cyc_i(cyc),	// cycle valid
	.stb_i(stb),	// strobe
	.ack_o(pic_ack),	// transfer acknowledge
	.we_i(we),		// write
	.adr_i(adr),	// address
	.dat_i(cpu_dato),
	.dat_o(pic_dato),
	.vol_o(),			// volatile register selected
	.i1(),
	.i2(pulse1024),
	.i3(pulse60),
	.i4(),
	.i5(),
	.i6(),
	.i7(),
	.i8(),
	.i9(),
	.i10(),
	.i11(),
	.i12(),
	.i13(),
	.i14(),
	.i15(),
	.irqo(cpu_irq),	// normally connected to the processor irq
	.nmii(),	// nmi input connected to nmi requester
	.nmio(),	// normally connected to the nmi of cpu
	.vecno(vecno)
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

Ps2Keyboard ukbd1
(
	// WISHBONE/SoC bus interface 
	.rst_i(rst),
	.clk_i(clk),	// system clock
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(kbd_ack),
	.we_i(we),
	.adr_i(adr),
	.dat_i(cpu_dato[7:0]),
	.dat_o(kbd_dato),
	//-------------
	.kclk(),
	.kd(),
	.irq_o()
);

rtfTextController3 utc3
(
	.rst_i(rst), .clk_i(clk),
	.cyc_i(io3_cyc), .stb_i(io3_stb), .ack_o(tc_ack),
	.we_i(io3_we), .adr_i(io3_adr), .dat_i(io3_dato), .dat_o(tc_dato),
	.lp(), .curpos(),
	.vclk(), .hsync(), .vsync(), .blank(), .border(), .rgbIn(), .rgbOut()
);

IOBridge uio3 
(
	.rst_i(rst),
	.clk_i(clk),
	.s_cyc_i(cyc),
	.s_stb_i(stb),
	.s_ack_o(iob3_ack),
	.s_sel_i(sel[7:4]|sel[3:0]),
	.s_we_i(we),
	.s_adr_i(adr),
	.s_dat_i(cpu_dato),
	.s_dat_o(iob3_dato),
	.m_cyc_o(io3_cyc),
	.m_stb_o(io3_stb),
	.m_ack_i(tc_ack),
	.m_we_o(io3_we),
	.m_sel_o(io3_sel),
	.m_adr_o(io3_adr),
	.m_dat_i(tc_dato),
	.m_dat_o(io3_dato)
);

assign cpu_dati = rom_dato | {2{iob3_dato}} | scm_dato | {8{kbd_dato}} | {2{pic_dato}};

always @(posedge clk)
begin
	$display(" ");
	$display(" ");
	$display("TIME: %d sp=%h %s", $time, u1.sp, u1.fnStateName(u1.state));
	$display("IFETCH");
	$display("    pc=%h insn=%h", u1.pc, u1.ice ? u1.insn : u1.ibuf);
	$display("REGFETCH");
	$display("    dpc=%h ir=%h Ra=r%d, Rb=r%d Rc=r%d", u1.dpc, u1.ir, u1.Ra, u1.Rb, u1.Rc);
	$display("EXECUTE");
	$display("    xpc=%h xir=%h a=%h b=%h c=%h imm=%h", u1.xpc, u1.xir, u1.a, u1.b, u1.c, u1.imm);
	$display("MULTI-CYCLE");
	$display("    ea=%h xb=%h",u1.ea,u1.xb);
	$display("%cres2=%h wres2=%h", (u1.xRt2==1'b1)?"S":" ",u1.res2, u1.wres2);
	if (u1.wRt != 0 || u1.wRt2 != 0) begin
		$display("WRITEBACK");
		$display("    r%d = %h", u1.wRt, u1.wres);
		if (u1.wRt2 != 0)
			$display("    sp = %h", u1.wres2);
	end
	if (u1.tRt != 0) begin
		$display("TAIL1");
		$display("    r%d = %h", u1.tRt, u1.tres);
	end
	if (u1.uRt != 0) begin
		$display("TAIL2");
		$display("    r%d = %h", u1.uRt, u1.ures);
	end
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

