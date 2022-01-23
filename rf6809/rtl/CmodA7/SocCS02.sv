// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================
//
`define DEBUG		1'b1
//`define SIM		1'b1

module SocCS02(sysclk, btn,
	pio2, pio3,
	led, led0_r, led0_g, led0_b,
	uart_rxd_out, uart_txd_in,
	MemAdr, MemDB, RamOEn, RamWEn, RamCEn);
input sysclk;
input [1:0] btn;
inout tri [6:0] pio2;
inout tri [22:0] pio3;
output [1:0] led;
output reg led0_r;
output reg led0_g;
output reg led0_b;
output uart_rxd_out;
input uart_txd_in;
output reg [18:0] MemAdr;
inout tri [7:0] MemDB;
output reg RamOEn;
output reg RamWEn;
output reg RamCEn;

parameter SYNC = 8'hFF;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;


assign pio2 = 7'bz;
assign pio3 = 23'bz;

// -----------------------------------------------------------------------------
// Signals and registers
// -----------------------------------------------------------------------------
wire xrst;					// external reset (push button)
wire rst;						// internal reset
wire clk120;
wire clk80;
wire clk40;
wire clk;						// system clock (50MHz)
wire clk14p7;				// uart clock 14.746 MHz
wire clk20;					// 20MHz for wall clock time
wire cpuclk;
wire locked;				// clock generation is locked
wire [1:0] btn_db;	// debounced button output

reg irq;
wire vpa;
wire cyc;						// cpu cycle is active
wire stb;						// cpu transfer strobe
reg ack;						// cpu transfer acknowledge
wire we;						// cpu write cycle
wire [23:0] adr;		// cpu address
reg [11:0] dat_i;		// cpu data input
wire [11:0] dat_o;	// cpu data output
reg [11:0] dati;		// memory data input

wire cs_rom0, cs_rom1;
wire cs_io;
wire cs_mem;
wire cs_via;
wire cs_sema;
wire ack_rom0, ack_rom1;
wire ack_mem;
wire uart_irq, via_irq;
wire ack_uart, ack_via, ack_sema, rnd_ack;
wire xal;
wire [11:0] rom0_dato;
wire [11:0] rom1_dato;
wire [11:0] uart_dato;
wire [11:0] via_dato;
wire [11:0] mem_dato;
wire [11:0] sema_dato;
wire [11:0] rnd_dato;
wire [11:0] pa;
wire [11:0] pa_i;
wire [11:0] pa_o;
wire badram;
wire t3_if;

// -----------------------------------------------------------------------------
// Clock generation
// -----------------------------------------------------------------------------

cs02clkgen ucg1
(
  // Clock out ports
  .clk120(clk120),
  .clk80(clk80),
  .clk40(clk40),
  .clk14p7(clk14p7),
  .clk20(clk20),
  // Status and control signals
  .reset(xrst),
  .locked(locked),
 // Clock in ports
  .clk_in1(sysclk)
);

assign rst = !locked;
assign irq = uart_irq|via_irq;
assign clk = clk40;
assign cpuclk = clk40;

// -----------------------------------------------------------------------------
// Circuit select logic
// -----------------------------------------------------------------------------
// Memory map
//
// 000000	+---------------+
//   	  	|               |
//  	  	|   Ram 256kB   | (12 bits wide)
// 	  	  |               |
// 040000	+---------------+
// 	  	  |    unused     |
// E00000 +---------------+
// 	 	    |     I/O       |
// EFFFFF	+---------------+
//				|		 unused  		|
// FF8000	+---------------+
//        |     ROM       |
// FFFFFF	+---------------+
//
// I/O Map
//
// E3010x	+---------------+
//        |    Uart6551   |
//        +---------------+
//
// E3060x	+---------------+
//        |     PRNG      |
//        +---------------+
//
// E600xx +---------------+
//        |    VIA6522    |
//        +---------------+
//
// EF0xxx	+---------------+
//        |  semaphores   |
//        +---------------+
//
// -----------------------------------------------------------------------------

assign cs_rom0 = adr[23:14]==10'h3FF;	// $FFFExxxxx to $FFFFxxxxx
assign cs_rom1 = adr[23:14]==10'h3FE;	// $FFFExxxxx to $FFFFxxxxx
//assign cs_basrom = cyc && stb && adr[31:16]==16'b1111_1111_1111_1101;	// $FFFCxxxx to $FFFFxxxx
assign cs_mem = adr[23:20]==4'h0;
assign cs_via = adr[23:8]==16'hE600;
assign cs_uart = adr[23:8]==16'hE301;
assign cs_sema = adr[23:16]==8'hEF;
reg cs_rnd;
always_comb cs_rnd = adr[23:8]==16'hE306;		// PRNG random number generator

// -----------------------------------------------------------------------------
// Input debouncing
// Pressing both buttons at the same time resets the system.
// -----------------------------------------------------------------------------

BtnDebounce udbu (sysclk, btn[0], btn_db[0]);
BtnDebounce udbd (sysclk, btn[1], btn_db[1]);

`ifdef SIM
assign xrst = btn[0];// & btn[1];
`else
assign xrst = btn_db[0] & btn_db[1];
`endif

assign pa_i[8] = btn_db[0];
assign pa_i[9] = btn_db[1];

// -----------------------------------------------------------------------------
// clock divider
// Used to pulse width modulate (PWM) the led signals to reduce the brightness.
// -----------------------------------------------------------------------------

reg [31:0] dvd;
always @(posedge clk)
if (rst)
	dvd <= 32'd1;
else begin
	if (dvd==32'd50000000)
		dvd <= 32'd1;
	else
		dvd <= dvd + 32'd1;
end

// -----------------------------------------------------------------------------
// LED output
// -----------------------------------------------------------------------------

assign led[0] = pa_o[3] & ~dvd[26] & dvd[12];
assign led[1] = pa_o[4] & dvd[12];

assign led0_r = ~irq;	// pa[0]
assign led0_g = ~cyc;	// pa[1]
assign led0_b = ~(pa_o[2] & dvd[12]);	// PWM 50% at about 12kHz.

// -----------------------------------------------------------------------------
// Memory interface
// -----------------------------------------------------------------------------

wire MemT;
wire [7:0] MemDBo;

cs02memInterface umi1
(
	.rst_i(rst),
 	.clk_i(clk40),
 	.cpuclk_i(cpuclk),
	.cs_i(cs_mem),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(ack_mem),
	.we_i(we),
	.adr_i(adr),
	.dat_i(dat_o),
	.dat_o(mem_dato), 
	.RamCEn(RamCEn),
	.RamWEn(RamWEn),
	.RamOEn(RamOEn),
	.MemAdr(MemAdr),
	.MemDBo(MemDBo),
	.MemDBi(MemDB)
);
assign MemDB = {8{RamWEn}} ? 8'bz : MemDBo;
//assign mem_dato = cs_mem ? mem_dato1 : 32'd0;

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

random	uprg1
(
	.rst_i(rst),
	.clk_i(cpuclk),
	.cs_i(cs_rnd),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(rnd_ack),
	.we_i(we),
	.adr_i(adr[3:0]),
	.dat_i(dat_o),
	.dat_o(rnd_dato)
);

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

semamem usema1
(
	.rst_i(rst),
  .clk_i(cpuclk),
  .cs_i(cs_sema),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_sema),
  .we_i(we),
  .adr_i(adr[12:0]),
  .dat_i(dat_o),
  .dat_o(sema_dato)
);

scratchmem uscr2
(
  .rst_i(rst),
  .clk_i(cpuclk),
  .cti_i(3'b000),
  .bok_o(),
  .cs_i(cs_rom0),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_rom0),
  .we_i(we),
  .adr_i(adr[13:0]),
  .dat_i(dat_o),
  .dat_o(rom0_dato)
`ifdef SIM
  ,.sp(24'h0)
`else
	,.sp(24'h0)
`endif
);
demomem uscr2a
(
  .rst_i(rst),
  .clk_i(cpuclk),
  .cti_i(3'b000),
  .bok_o(),
  .cs_i(cs_rom1),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_rom1),
  .we_i(we),
  .adr_i(adr[13:0]),
  .dat_i(dat_o),
  .dat_o(rom1_dato)
`ifdef SIM
  ,.sp(24'h0)
`else
	,.sp(24'h0)
`endif
);

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

via6522_x12 uvia1
(
	.rst_i(rst),
	.clk_i(cpuclk),
	.wc_clk_i(clk40),
	.irq_o(via_irq),
	.cs_i(cs_via),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(ack_via),
	.we_i(we),
	.adr_i(adr[6:0]),
	.dat_i(dat_o),
	.dat_o(via_dato), 
	.pa_i(pa_i),
	.pa_o(pa_o),
	.pa_t(),
	.pb_i(),
	.pb_o(),
	.pb_t(),
	.ca1(),
	.ca2_i(),
	.ca2_o(),
	.ca2_t(),
	.cb1_i(),
	.cb1_o(),
	.cb1_t(),
	.cb2_i(),
	.cb2_o(),
	.cb2_t(),
	.t1_if(),
	.t2_if(),
	.t3_if(t3_if)
);

// -----------------------------------------------------------------------------
// UART
// -----------------------------------------------------------------------------

uart6551_x12 #(.CLK_FREQ(40)) uuart1
(
	.rst_i(rst),
	.clk_i(clk40),
	.cs_i(cs_uart),
	.irq_o(uart_irq),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(ack_uart),
	.we_i(we),
	.adr_i(adr[3:0]),
	.dat_i(dat_o),
	.dat_o(uart_dato),
	.cts_ni(1'b0),
	.rts_no(),
	.dsr_ni(1'b0),
	.dcd_ni(1'b0),
	.dtr_no(),
	.ri_ni(1'b1),
	.rxd_i(uart_txd_in),
	.txd_o(uart_rxd_out),
	.data_present(),
	.rxDRQ_o(),
	.txDRQ_o(),
	.xclk_i(clk20),
	.RxC_i(1'b0)
);

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

wire err;

BusError ube1
(
	.rst_i(rst),
	.clk_i(cpuclk),
	.cyc_i(cyc),
	.ack_i(ack),
	.stb_i(stb),
	.adr_i(adr),
	.err_o(err)
);

// -----------------------------------------------------------------------------
// CPU
// -----------------------------------------------------------------------------

always @(posedge cpuclk)
	ack <= ack_rom0|ack_rom1|ack_mem|ack_via|ack_uart|ack_sema|rnd_ack;

always @(posedge cpuclk)
	dat_i <= rom0_dato|rom1_dato|mem_dato|via_dato|uart_dato|sema_dato|rnd_dato;

rf6809 ucpu1
(
	.id(6'h20),
	.rst_i(rst),
	.clk_i(cpuclk),
	.halt_i(1'b0),
	.nmi_i(1'b0),
	.irq_i(via_irq),
	.firq_i(1'b0),
	.vec_i(24'h0),
	.ba_o(),
	.bs_o(),
	.lic_o(),
	.tsc_i(1'b0),
	.rty_i(1'b0),
	.bte_o(),
	.cti_o(cti),
	.bl_o(),
	.lock_o(),
	.cyc_o(cyc),
	.stb_o(stb),
	.we_o(we),
	.ack_i(ack),
	.aack_i(ack),
	.atag_i(adr[3:0]),
	.adr_o(adr),
	.dat_i(dat_i),
	.dat_o(dat_o),
	.state()
);


CS02_ILA uila1 (
	.clk(clk80), // input wire clk


	.probe0(ucpu1.pc), // input wire [31:0]  probe0  
	.probe1(ucpu1.dat_i), // input wire [31:0]  probe1 
	.probe2(ucpu1.cyc_o), // input wire [0:0]  probe2 
	.probe3(ucpu1.we_o), // input wire [0:0]  probe3 
	.probe4(ucpu1.adr_o), // input wire [31:0]  probe4 
	.probe5(MemDB), // input wire [31:0]  probe5
	.probe6({umi1.ack_o,RamCEn,RamOEn,RamWEn,umi1.state}),
	.probe7(MemAdr)
//	.probe6({ucpu1.to_done,ucpu1.state,ucpu1.crs,ucpu1.regset})
);


endmodule
