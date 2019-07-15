/* ===============================================================
	(C) 2002  Bird Computer
	All rights reserved.

	bc6502_SoC.v

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.
	
================================================================ */

`define ABW 16
`define DBW 8

module bc6502_SoC(xreset, xclk, xa, xd, we, oe, ce,
	cts, rts, sin, sout, kclk, kd, hSync, vSync, vdo,
	led);
	input xreset;
	input xclk;
	output [`ABW:0] xa;
	inout [`DBW-1:0] xd;
	output we;		// active low
	output oe;		// active low
	output ce;		// active low
	input cts;
	output rts;
	input sin;
	output sout;
	inout kclk;
	inout kd;
	output hSync, vSync;
	output [5:0] vdo;
	output led;		// active low
	reg led;

	wire clk;
	wire reset = ~xreset;
	wire rw;
	wire nmi;
	wire irq = 1'b0;
	wire rdy;
	wire so = 1'b0;
	wire sync;
	wire [`ABW-1:0] a;
	wire [`ABW-1:0] a_nxt;
	tri [`DBW-1:0] d;
	wire [`DBW-1:0] bram_do;
	wire [`DBW-1:0] charram_do;
	wire [`DBW-1:0] uart_do;
	wire [`DBW-1:0] timer_do;
	wire uart_irq;
	wire kbd_irq;
	wire vic_irq;
	wire wse;
	wire [8:0] cra;
	wire [7:0] cdin;
	wire [15:0] scr_a, cpu_a;
	wire vbe;
	wire cpu_rw;
	wire rw_nxt;
	reg uart_wr;
	wire [`DBW-1:0] cpu_do;
	tri [`DBW-1:0] cpu_di;
	wire [27:0] state;
	wire [4:0] flags;

	// 512 byte boot rom
	wire rom_cs = a[15:9]==7'b1111_111;		// $FE00
	wire io_cs = a[15:12]==4'hD;			// $Dxxx
	wire uart_cs = io_cs && a[11:8]==4'hF;	// $DF00
	wire kbd_cs = io_cs && a[11:8]==4'hE;	// $DE00
	wire vic_cs = io_cs && a[11:8]==4'hC;	// $DC00
	wire timer_cs = io_cs && a[11:8]==4'hB;	// $DB00
	wire led_cs = io_cs && a[11:8]==4'hA;	// $DA00
	
	always @(posedge clk) begin
		if (reset)
			led <= 1'b0;
		else begin
			if (led_cs & ~rw)
				led <= cpu_do[0];
		end
	end

	// gen approx 1s nmi's	
	reg [24:0] nmi_cntr;
	always @(posedge clk) begin
		if (reset)
			nmi_cntr <= 1'b0;
		else begin
			nmi_cntr <= nmi_cntr + 1;
		end
	end
//	assign nmi = nmi_cntr[24];
	assign nmi = 1'b0;


	// Yes, the ram does underlay the screen and char rams
	// This is because these rams can only be written and
	// not read. Thus we use regular ram to hold a copy of
	// these rams for reading.
	// $0000-$CFFF, $E000-$FFFF
	wire ram_cs = a[15:12]!=4'hD;
	wire charram_cs = a[15:11]==5'b1100_1;	// $C800-$CFFF
	wire scram_cs = a[15:11]==5'b1100_0;	// $C000-$C7FF

	assign xa = {1'b0,a};
	assign xd = ram_cs & ~rw ? cpu_do : 8'bz;
	assign ce = ~ram_cs;
	assign we = rw | wse;

	assign cpu_di = rom_cs ? bram_do : 8'bz;
	assign cpu_di = ram_cs & ~rom_cs ? xd : 8'bz;
	assign cpu_di = uart_cs ? uart_do : 8'bz;
	assign cpu_di = timer_cs ? timer_do : 8'bz;
	assign cpu_di = ~(rom_cs|ram_cs|uart_cs|timer_cs) ? 8'hEA : 8'bz;

/*
	always @(rom_cs or ram_cs or uart_cs or rw or bram_do or
		xd or uart_do) begin
		if (rw) begin
			case(1'b1)
			rom_cs:		cpu_di <= bram_do;
			ram_cs:		cpu_di <= xd;
			uart_cs: 	cpu_di <= uart_do;
			default:	cpu_di <= 8'h00;
			endcase
		end
		else
			cpu_di <= 8'h00;
	end
*/
//	assign d = rw ? bram_do : 8'bz;
//	assign d = ram_cs & rw ? xd : 8'bz;
//	assign d = charram_cs & rw ? charram_do : 8'bz;
	reg [7:0] dat;
	reg rdy2;
//	assign d = ~rw ? dat : 8'bz;

	assign a = cpu_a;
	assign rw = cpu_rw;
	// we are not ready the first cycle of a read from sync
	// bram
//	assign rdy = ~rw|~(rom_cs|charram_cs|scram_cs)|rdy2;
	assign rdy = 1'b1;

	reg [1:0] uart_a;
	reg [3:0] s;

	reg [9:0] cnt;
	always @(posedge clk) begin
		if (reset)
			cnt <= 10'h000;
		else begin
			if (cnt < 10'h2FE)
				cnt <= cnt + 1;
		end
	end

	wire s_reset, s_reset1, s_reset2, s_reset3;
	reg [3:0] ce25;
	wire ce25a = 1'b1; //ce25[3];
	clkgen cg0(.reset(reset), .clki(xclk), .clk(clk), .wse(wse) );
	wire [`DBW-1:0] rom_d;

	// this memory is used as a ROM
	// Can't use rom_cs for enable!
	RAMB4_S8_S8 bram0(.CLKA(clk), .ADDRA(a_nxt[8:0]), .DIA(8'h00), .DOA(bram_do), .ENA(rdy), .WEA(1'b0), .RSTA(1'b0),
		.CLKB(clk), .ADDRB(a[8:0]), .DIB(cpu_do), .ENB(1'b1), .WEB(1'b0), .RSTB(1'b0) );

	// this memory is used as a char RAM
	RAMB4_S8_S8 charram0(
		.CLKA(clk), .ADDRA(a[8:0]), .DIA(cpu_do), .DOA(charram_do), .ENA(charram_cs), .WEA(~rw), .RSTA(1'b0),
		.CLKB(clk), .ADDRB(cra), .DIB(8'b0), .DOB(cdin), .ENB(1'b1), .WEB(1'b0), .RSTB(1'b0) );

	// this memory is used as a screen RAM
	wire [7:0] scrin;
	RAMB4_S4_S4 screenram0(
		.CLKA(clk), .ADDRA(scr_a[9:0]), .DIA(4'b0), .DOA(scrin[3:0]), .ENA(1'b1), .WEA(1'b0), .RSTA(1'b0),
//		.CLKB(clk), .ADDRB(cnt[9:0]), .DIB(flags[3:0]), .ENB(1'b1), .WEB(1'b1), .RSTB(1'b0) );
		.CLKB(clk), .ADDRB(a[9:0]), .DIB(cpu_do[3:0]), .ENB(scram_cs), .WEB(~rw), .RSTB(1'b0) );

	RAMB4_S4_S4 screenram1(
		.CLKA(clk), .ADDRA(scr_a[9:0]), .DIA(4'b0), .DOA(scrin[7:4]), .ENA(1'b1), .WEA(1'b0), .RSTA(1'b0),
//		.CLKB(clk), .ADDRB(cnt[9:0]), .DIB(flags[4]), .ENB(1'b1), .WEB(1'b1), .RSTB(1'b0) );
		.CLKB(clk), .ADDRB(a[9:0]), .DIB(cpu_do[7:4]), .ENB(scram_cs), .WEB(~rw), .RSTB(1'b0) );

	wire [7:0] vic_d;
	vic_text vt0(.reset(reset), .clk(clk), .ce25(1'b1), .cs(vic_cs),
		.rw(rw), .rs(a[8:0]), .d(vic_d),
		.cdin(cdin), .scrin(scrin), .ce50(1'b1),
		.va(scr_a), .cra(cra), .irq(vic_irq),
		.hSync(hSync), .vSync(vSync), .vdo(vdo) );
/*		
	timer tmr0(.reset(reset), .clk(clk), .ce(1'b1), .cs(timer_cs),
		.rw(rw), .a(a[3:0]), .di(cpu_do), .do(timer_do),
		.irq(timer_irq) ); */
/*
	PS2kbd kbd0(.reset(reset), .clk(clk), .ce(1'b1), .cs(kbd_cs), .wr(~rw),
		.a(a[0]), .d(d), .irq(kbd_irq), .kclk(kclk), .kd(kd) );
*/
	bc_uart uart0(.reset(reset), .clk(clk), .ce(rdy), .cs(uart_cs),
		.rd(rw), .wr(~rw), .a(a[2:0]), .di(cpu_do), .do(uart_do), .irq(uart_irq),
		.cts(cts), .rts(rts), .sin(sin), .sout(sout) );

	bc6502 cpu0(.reset(reset), .clk(clk), .nmi(nmi), .irq(irq),
		.rdy(rdy), .so(1'b0), .di(cpu_di),
		.do(cpu_do), .rw(cpu_rw), .ma(cpu_a),
		.ma_nxt(a_nxt),
		.sync(sync), .state(state), .flags(flags) );

endmodule
