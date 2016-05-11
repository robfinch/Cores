
module Thor_tb();
parameter DBW=32;
reg rst;
reg clk;
reg clk2x;
reg nmi;
reg p100Hz;
reg p1000Hz;
wire [2:0] cti;
wire cpu_clk;
wire cyc;
wire stb;
wire we;
wire [7:0] sel;
wire br_ack;
wire [31:0] adr;
wire [DBW+6:0] br_dato;
wire scr_ack;
wire [63:0] scr_dato;
reg [31:0] rammem [0:1048575];
wire err1,err2;

wire cpu_ack;
wire [DBW-1:0] cpu_dati;
wire [DBW-1:0] cpu_dato;
wire pic_ack,irq;
wire [31:0] pic_dato;
wire [7:0] vecno;
wire baud16;
wire uart_rxd;
wire uart_ack;
wire uart_irq;
wire [7:0] uart_dato;
wire LEDS_ack;

initial begin
	#0 rst = 1'b0;
	#0 clk = 1'b0;
	#0 clk2x = 1'b0;
	#0 nmi = 1'b0;
	#0 p100Hz = 1'b0;
	#0 p1000Hz = 1'b1;
	#10 rst = 1'b1;
	#50 rst = 1'b0;
	#20800 nmi = 1'b1;
	#20 nmi = 1'b0;
end

always #10 clk = ~clk;
always #5 clk2x = ~clk2x;
always #10000 p100Hz = ~p100Hz;
always #3000 p1000Hz = ~p1000Hz;

wire ram_cs = cyc && stb && adr[31:28]==4'd0 && adr[31:14]!= 18'h0000;
wire [31:0] ramo = ram_cs ? rammem[adr[21:2]] : 32'd0;
always @(posedge clk)
    if (ram_cs & we) begin
        if (sel[0]) rammem[adr[21:2]][7:0] <= cpu_dato[7:0];
        if (sel[1]) rammem[adr[21:2]][15:8] <= cpu_dato[15:8];
        if (sel[2]) rammem[adr[21:2]][23:16] <= cpu_dato[23:16];
        if (sel[3]) rammem[adr[21:2]][31:24] <= cpu_dato[31:24];
    end
reg ramack1,ramack2,ramack3,ramack4,ramack5,ramack6,ram_ack;
always @(posedge clk)
begin
  ramack1 <= ram_cs;
  ramack2 <= ramack1 & ram_cs;
  ramack3 <= ramack2 & ram_cs;
  ramack4 <= ramack3 & ram_cs;
  ramack5 <= ramack4 & ram_cs;
  ramack6 <= ramack5 & ram_cs;
  ram_ack <= ramack6 & ram_cs;
end

assign LEDS_ack = cyc && stb && adr[31:8]==32'hFFDC06;
always @(posedge clk)
	if (LEDS_ack)
		$display("LEDS: %b", cpu_dato[7:0]);

always @(posedge clk)
    if ((err1|err2)&&$time > 11000)
        $stop;

wire tc1_ack, tc2_ack;
wire kbd_ack;
wire [31:0] tc1_dato, tc2_dato;
wire [7:0] kbd_dato;

//wire cs0 = cyc&& stb && adr[31:16]==16'h0000;

assign cpu_ack =
	LEDS_ack |
	scr_ack |
	br_ack |
	tc1_ack | tc2_ack |
	kbd_ack | pic_ack |
	ram_ack | uart_ack
	;
assign cpu_dati =
	scr_dato |
	br_dato |
	tc1_dato | tc2_dato |
	{4{kbd_dato}} |
	pic_dato |
	ramo |
	{4{uart_dato}}
	;

rtfSerialTxSim ussim1
(
    .rst(rst),
    .baud16(baud16),
    .txd(uart_rxd)
);

rtfSimpleUart uuart1
(
	// WISHBONE Slave interface
	.rst_i(rst),		    // reset
	.clk_i(clk),	    // eg 100.7MHz
	.cyc_i(cyc),		// cycle valid
	.stb_i(stb),		// strobe
	.we_i(we),			// 1 = write
	.adr_i(adr),		// register address
	.dat_i(cpu_dato[7:0]),	// data input bus
	.dat_o(uart_dato),	    // data output bus
	.ack_o(uart_ack),		// transfer acknowledge
	.vol_o(),		        // volatile register selected
    .irq_o(uart_irq),		// interrupt request
	//----------------
	.cts_ni(1'b0),		// clear to send - active low - (flow control)
	.rts_no(),	// request to send - active low - (flow control)
	.dsr_ni(1'b0),		// data set ready - active low
	.dcd_ni(1'b0),		// data carrier detect - active low
	.dtr_no(),	// data terminal ready - active low
	.rxd_i(uart_rxd),	// serial data in
	.txd_o(),			// serial data out
    .data_present_o(),
    .baud16_clk(baud16)
);

Ps2Keyboard_sim ukbd
(
    .rst_i(rst),
    .clk_i(cpu_clk),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(kbd_ack),
    .we_i(we),
    .adr_i(adr),
    .dat_i(cpu_dato),
    .dat_o(kbd_dato),
    .kclk(),
    .kd(),
    .irq_o()
);

rtfTextController3 #(.num(1), .pTextAddress(32'hFFD00000))  tc1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(tc1_ack),
	.we_i(we),
	.adr_i(adr),
	.dat_i(cpu_dato),
	.dat_o(tc1_dato),
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

rtfTextController3 #(.num(1), .pTextAddress(32'hFFD10000), .pRegAddress(32'hFFDA0040))  tc2
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(tc2_ack),
	.we_i(we),
	.adr_i(adr),
	.dat_i(cpu_dato),
	.dat_o(tc2_dato),
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

scratchmem32 #(DBW) uscrm1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
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
	.clk_i(cpu_clk),
	.cti_i(cti),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(br_ack),
	.adr_i(adr),
	.dat_o(br_dato),
	.perr(),
	.err1(err1),
	.err2(err2)
);

wire nmio;
Thor_pic upic1
(
	.rst_i(rst),		// reset
	.clk_i(cpu_clk),	// system clock
	.cyc_i(cyc),	// cycle valid
	.stb_i(stb),	// strobe
    .ack_o(pic_ack),	// transfer acknowledge
	.we_i(we),		// write
	.adr_i(adr),	// address
	.dat_i(cpu_dato),
	.dat_o(pic_dato),
	.vol_o(),		// volatile register selected
	.i1(p1000Hz),
	.i2(p100Hz),
	.i3(),
	.i4(),
	.i5(),
	.i6(),
	.i7(uart_irq),
	.i8(),
	.i9(),
	.i10(),
	.i11(),
	.i12(),
	.i13(),
	.i14(),
	.i15(),
	.irqo(irq),	// normally connected to the processor irq
	.nmii(nmi),		// nmi input connected to nmi requester
	.nmio(nmio),	// normally connected to the nmi of cpu
	.vecno(vecno)
);

Thor #(DBW) uthor1
(
	.rst_i(rst),
	.clk_i(clk),
	.clk2x_i(clk2x),
	.clk_o(cpu_clk),
	.nmi_i(nmio),
	.irq_i(irq),
	.vec_i(vecno),
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
