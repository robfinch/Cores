// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2021  Robert Finch, Waterloo
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

module SocCS01(sysclk, btn, pio, pio2, pio3,
	led, led0_r, led0_g, led0_b,
	uart_rxd_out, uart_txd_in,
	MemAdr, MemDB, RamOEn, RamWEn, RamCEn);
input sysclk;
input [1:0] btn;
inout tri [14:1] pio;
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
wire clk80;
wire clk40;
wire clk;						// system clock (50MHz)
wire clk14p7;				// uart clock 14.746 MHz
wire clk20;					// 20MHz for wall clock time
wire cpuclk;
wire locked;				// clock generation is locked
wire [1:0] btn_db;	// debounced button output

reg irq;
wire cyc;						// cpu cycle is active
wire stb;						// cpu transfer strobe
reg ack;						// cpu transfer acknowledge
wire we;						// cpu write cycle
wire [3:0] sel;			// cpu select lines
wire [31:0] adr;		// cpu address
reg [31:0] dat_i;		// cpu data input
wire [31:0] dat_o;	// cpu data output
reg [31:0] dati;		// memory data input

wire cs_rom;
wire cs_io;
wire cs_mem;
wire cs_via;
wire cs_sema;
wire ack_rom;
wire ack_mem;
wire uart_irq, via_irq;
wire ack_uart, ack_via, ack_sema;
wire [31:0] uart_dato;
wire [31:0] via_dato;
wire [31:0] mem_dato;
wire [7:0] sema_dato;
wire [31:0] pa;
wire [31:0] pa_i;
wire [31:0] pa_o;

// -----------------------------------------------------------------------------
// Clock generation
// -----------------------------------------------------------------------------

cs01clkgen ucg1
(
  // Clock out ports
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
// 00000000	+---------------+
//  	 	  	|               |
// 	  	  	|   Ram 512kB   | (32 bits wide)
// 		  	  |               |
// 00080000	+---------------+
// 		  	  |    unused     |
// FFD00000 +---------------+
// 	  	    |     I/O       |
// FFFC0000	+---------------+
//          |     ROM       |
// FFFFFFFF	+---------------+
//
// I/O Map
//
// FFDB0000	+---------------+
//          |  semaphores   |
//          +---------------+
//
// FFDC0600	+---------------+
//          |    VIA6522    |
//          +---------------+
//
// FFDC0A00	+---------------+
//          |    Uart6551   |
//          +---------------+
// -----------------------------------------------------------------------------

assign cs_rom = cyc && stb && adr[31:16]==16'b1111_1111_1111_1100;	// $FFFCxxxx to $FFFFxxxx
//assign cs_basrom = cyc && stb && adr[31:16]==16'b1111_1111_1111_1101;	// $FFFCxxxx to $FFFFxxxx
assign cs_mem = cyc && stb && adr[31:16] < 16'h0008;
assign cs_via = cyc && stb && adr[31:8]==24'hFFDC06;
assign cs_uart = cyc && stb && adr[31:4]==28'hFFDC0A0;
assign cs_sema = cyc && stb && adr[31:16]==16'hFFDB;

(* ram_style="block" *)
reg [31:0] rommem [0:6143];
wire [31:0] rom_dato;
initial begin
`include "../software/boot/cs01rom.ve0"
end
reg [31:0] adrr;
always @(posedge clk)
	adrr <= adr;
assign rom_dato = rommem[adrr[14:2]];
ack_gen #(.READ_STAGES(3), .WRITE_STAGES(3)) uag1
(
 .clk_i(cpuclk),
 .ce_i(1'b1),
 .i(cs_rom),
 .we_i(cs_rom),
 .o(ack_rom)
);

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

cs01memInterface umi1
(
	.rst_i(rst),
	.clk_i(clk80),
	.cs_i(cs_mem),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(ack_mem),
	.we_i(we),
	.sel_i(sel),
	.adr_i(adr),
	.dat_i(dat_o),
	.dat_o(mem_dato), 
	.RamCEn(RamCEn),
	.RamWEn(RamWEn),
	.RamOEn(RamOEn),
	.MemAdr(MemAdr),
	.MemDB(MemDB)
);

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

semamem usema1
(
	.clk_i(cpuclk),
	.cs_i(cs_sema),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(ack_sema),
	.we_i(we),
	.adr_i(adr[14:2]),
	.dat_i(dat_o[7:0]),
	.dat_o(sema_dato)
);

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

via6522 uvia1
(
	.rst_i(rst),
	.clk_i(clk40),
	.irq_o(via_irq),
	.cs_i(cs_via),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(ack_via),
	.we_i(we),
	.sel_i(sel),
	.adr_i(adr[5:2]),
	.dat_i(dat_o),
	.dat_o(via_dato), 
	.pa(),
	.pa_i(pa_i),
	.pa_o(pa_o),
	.pb(),
	.ca1(),
	.ca2(),
	.cb1(),
	.cb2()
);

// -----------------------------------------------------------------------------
// UART
// -----------------------------------------------------------------------------

uart6551 uuart1
(
	.rst_i(rst),
	.clk_i(clk40),
	.cs_i(cs_uart),
	.irq_o(uart_irq),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(ack_uart),
	.we_i(we),
	.sel_i(sel),
	.adr_i(adr[3:2]),
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
// CPU
// -----------------------------------------------------------------------------

always @(posedge cpuclk)
	ack <= ack_rom|ack_mem|ack_via|ack_uart|ack_sema;

always @(posedge cpuclk)
casez({cs_rom,cs_mem,cs_via,cs_uart,cs_sema})
5'b1????:	dat_i <= rom_dato;
5'b01???:	dat_i <= mem_dato;
5'b001??:	dat_i <= via_dato;
5'b0001?:	dat_i <= uart_dato;
5'b00001:	dat_i <= {24'd0,sema_dato};
default:	dat_i <= 32'hCCEECCEE;
endcase

friscv_wb ucpu1
(
	.rst_i(rst),
	.clk_i(cpuclk),
	.wc_clk_i(clk20),
	.irq_i({1'b0,uart_irq,via_irq}),
	.cause_i(uart_irq ? 8'd37 : via_irq ? 8'd47 : 8'd00),
	.cyc_o(cyc),
	.stb_o(stb),
	.ack_i(ack),
	.we_o(we),
	.sel_o(sel),
	.adr_o(adr),
	.dat_i(dat_i),
	.dat_o(dat_o)
);

CS01_ILA uila1 (
	.clk(clk), // input wire clk


	.probe0(ucpu1.ipc), // input wire [31:0]  probe0  
	.probe1(ucpu1.ir), // input wire [31:0]  probe1 
	.probe2(ucpu1.cyc_o), // input wire [0:0]  probe2 
	.probe3(ucpu1.we_o), // input wire [0:0]  probe3 
	.probe4(ucpu1.adr_o), // input wire [31:0]  probe4 
	.probe5(ucpu1.dat_o), // input wire [31:0]  probe5
	.probe6({ucpu1.irq_i,ucpu1.pmStack[8:0],ucpu1.mtid})
//	.probe6({ucpu1.to_done,ucpu1.state,ucpu1.crs,ucpu1.regset})
);


endmodule
