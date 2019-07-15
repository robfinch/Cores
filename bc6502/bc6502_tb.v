/* ===============================================================
	(C) 2001  Bird Computer

	bc6502_tb.v 
==============================================================-= */

`timescale 1ns / 100ps

module bc6502_tb();

	reg clk;
	reg reset;

	reg nmi;
	wire irq = 1'b0;
	wire rdy = 1'b1;
	wire sync;
	wire rw;
	tri [7:0] d;
	wire [7:0] di, do;
	wire [15:0] a;
	
	initial begin
		clk = 1;
		reset = 0;
		nmi = 0;
		#100 reset = 1;
		#100 reset = 0;
		#1000 nmi = 1;
		#1500 nmi = 0;
	end

	always #17.45 clk = ~clk;	// 28.636 MHz

	wire ramcs = a[15];
	wire romcs = ~a[15];
	assign d = ~rw ? do : 8'bz;
	assign di = rw ? d : 8'b0;

	rom8Kx8 rom0(.ce(romcs), .oe(~rw), .addr(a[12:0]), .d(d));
	ram32Kx8 ram0(.clk(clk), .ce(ramcs), .oe(~rw), .we(rw), .addr(a[14:0]), .d(d));

	bc6502 cpu0(.reset(reset), .clk(clk), .nmi(nmi), .irq(irq),
		.rdy(rdy), .di(di), .do(do), .rw(rw), .ma(a), .sync(sync) );

	always @(posedge clk) begin
		$display($time,,"\n");
		$display("sync=%b rdy=%b romcs=%b ramcs=%b rw=%b\n", sync, rdy, romcs, ramcs, rw);
		$display("\tpc=%h a=%h x=%h y=%h sp=%h\n", cpu0.pc, cpu0.a_reg, cpu0.x_reg, cpu0.y_reg, cpu0.sp);
		$display("\tir=%h ma=%h d=%h cpu.ma=%h cpu.ma_nxt=%h cpu.pc_nxt=%h cpu.tmp=%h cpu.taken=%b\n", cpu0.ir, a, d, cpu0.ma, cpu0.ma_nxt, cpu0.pc_nxt, cpu0.tmp, cpu0.taken);
		$display("\tflags: n=%b v=%b z=%b c=%b im=%b d=%b b=%b", cpu0.nf, cpu0.vf, cpu0.zf, cpu0.cf, cpu0.im, cpu0.df, cpu0.bf);
	end

endmodule

/* ---------------------------------------------------------------
	rom8kx8.v -- external async 8Kx8 ROM Verilog model
	(simulation only)

  	Note this module is a functional model, with no timing, and
  is only suitable for simulation, not synthesis.
--------------------------------------------------------------- */
`timescale 1ns / 100ps

module rom8Kx8(ce, oe, addr, d);
	input			ce;	// active low chip enable
	input			oe;	// active low output enable
	input	[12:0]	addr;	// byte address
	output	[7:0]	d;		// tri-state data I/O
	tri [7:0] d;

	reg		[7:0]	mem [0:8191];

	initial begin
		$readmemh ("rom8kx8.mem", mem);
		$display ("Loaded rom8kx8.mem");
		$display (" 000000: %h %h %h %h %h %h %h %h", 
			mem[0], mem[1], mem[2], mem[3], mem[4], mem[5], mem[6], mem[7]);
	end

	assign d = (~oe & ~ce) ? mem[addr] : 8'bz;

	always @(oe or ce or addr) begin
		$display (" 000000: %h %h %h %h %h %h %h %h %h %h", 
			mem[0], mem[1], mem[2], mem[3], mem[4], mem[5], mem[6], mem[7], mem[8], mem[9]);
		$display (" read %h: %h", addr, mem[addr]);
	end

endmodule


/* ---------------------------------------------------------------
	ram32kx8.v -- external sync 32Kx8 RAM Verilog model
	(simulation only)

  	Note this module is a functional model, with no timing, and
  is only suitable for simulation, not synthesis.
--------------------------------------------------------------- */
`timescale 1ns / 100ps

module ram32Kx8(clk, ce, oe, we, addr, d);
	input clk;
	input			ce;		// active low chip enable
	input			oe;		// active low output enable
	input			we;		// active low write enable
	input	[14:0]	addr;	// byte address
	output	[7:0]	d;		// tri-state data I/O
	tri [7:0] d;

	reg		[7:0]	mem [0:32767];
	integer nn;

	initial begin
		for (nn = 0; nn < 32768; nn = nn + 1)
			mem[nn] <= 8'b0;
	end

	assign d = (~oe & ~ce & we) ? mem[addr] : 8'bz;

	always @(posedge clk) begin
		if (clk) begin
			if (~ce & ~we) begin
				mem[addr] <= d;
				$display (" wrote: %h with %h", addr, d);
			end
		end
	end

	always @(we or oe or ce or addr) begin
		$display (" 000000: %h %h %h %h %h %h %h %h %h %h", 
			mem[0], mem[1], mem[2], mem[3], mem[4], mem[5], mem[6], mem[7], mem[8], mem[9]);
	end

endmodule


