// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
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
wire clk;						// system clock (50MHz)
wire clk14p7;				// uart clock 14.746 MHz
wire clk20;					// 20MHz for wall clock time
wire locked;				// clock generation is locked
wire [1:0] btn_db;	// debounced button output

reg irq;
reg timer1Irq;
reg rxIrq;
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
wire cs_rxmem;
wire cs_txmem;
wire cs_led;
wire cs_irqsrc;
wire cs_irqack;
wire cs_gpio;
wire ack_rom;
reg ack_mem;
wire rxDataPresent;
wire tx_empty;
wire [7:0] rxDato;

// -----------------------------------------------------------------------------
// Clock generation
// -----------------------------------------------------------------------------

cs01clkgen ucg1
(
  // Clock out ports
  .clk50(clk),
  .clk14p7(clk14p7),
  .clk20(clk20),
  // Status and control signals
  .reset(xrst),
  .locked(locked),
 // Clock in ports
  .clk_in1(sysclk)
);

assign rst = !locked;

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
// FFDC0090 +---------------+
//          |   Buttons     |
// FFDC00A0 +---------------+
//          |     GPIO      |
// FFDC00B0	+---------------+
//          |  IRQ Status   |
// FFDC00C0 +---------------+
//          |   IRQ Ack     |
// FFDC0600	+---------------+
//          |    LEDS       |
//          +---------------+
//
// FFDC0A00	+---------------+
//          |    Uart       |
//          +---------------+
// -----------------------------------------------------------------------------

assign cs_rom = cyc && stb && adr[31:18]==14'b1111_1111_1111_11;	// $FFFCxxxx to $FFFFxxxx
assign cs_io = cyc && stb && adr[31:20]==12'hFFD;
assign cs_mem = cyc && stb && adr[31:16] < 16'h0008;
assign cs_btn = cyc && stb && adr[31:4]==28'hFFDC009;
assign cs_gpio = cyc && stb && adr[31:4]==28'hFFDC00A;
assign cs_irqsrc = cyc && stb && adr[31:4]==28'hFFDC00B;
assign cs_irqack = cyc && stb && adr[31:4]==28'hFFDC00C;
assign cs_led = cyc && stb && adr[31:4]==28'hFFDC060;
assign cs_uart = cyc && stb && adr[31:4]==28'hFFDC0A0;

(* ram_style="block" *)
reg [31:0] rommem [0:4095];
wire [31:0] romo;
initial begin
`include "../software/boot/cs01rom.ve0"
end
reg [31:0] adrr;
always @(posedge clk)
	adrr <= adr;
assign romo = rommem[adrr[13:2]];
ack_gen uag1 (.clk_i(clk), .ce_i(1'b1), .i(cs_rom), .we_i(cs_rom), .o(ack_rom));

reg wr_tx, rd_rx, wrxd;
wire [7:0] rxdatob, txdatob;
wire [7:0] rxdatib;
wire rx_empty;
wire [5:0] rx_data_count;
reg rxIRQ;

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

// -----------------------------------------------------------------------------
// LED output
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

assign led[0] = dvd[26];
reg ledr;
assign led[1] = ledr;

always @(posedge clk)
if (rst)
	ledr <= 1'b0;
else begin
	if (cs_led & we & clk)
		ledr <= dat_o[0];
end

// -----------------------------------------------------------------------------
// Memory access state machine
// -----------------------------------------------------------------------------

reg [3:0] state;
parameter IDLE = 4'd0;
parameter RD1 = 4'd1;
parameter WR1 = 4'd2;
parameter WR2 = 4'd3;
parameter WR3 = 4'd4;
parameter RWDONE = 4'd5;
parameter RWNACK = 4'd6;
reg [3:0] memCount;
reg [31:0] memDat;

always @(posedge clk)
if (rst) begin
	state <= IDLE;
	RamWEn <= HIGH;
	RamOEn <= HIGH;
	RamCEn <= HIGH;
	memCount <= 4'd0;
	ack_mem <= 1'b0;
end
else
case(state)
IDLE:
	begin
		// Default action is to disable all bus drivers
		RamWEn <= HIGH;
		RamCEn <= HIGH;
		RamOEn <= HIGH;
		if (cs_mem & cyc) begin
			RamCEn <= LOW;											// tell the ram it's selected
			MemAdr <= {adr,3'b0} + {adr,1'b0};	// adr is multiplied by 10 to form base address
			memDat <= dat_o;
			memCount <= 4'd0;
			state <= we ? WR1 : RD1;
			if (!we)							// For a read cycle enable the ram's output drivers
				RamOEn <= LOW;
		end
	end
	// For a read, after a clock cycle latch the input data.
	// Increment the memory address and count.
	// Simply stay in this state until the count expires.
RD1:
	begin
		dati <= {dati[23:0],MemDB};
		MemAdr <= MemAdr + 2'd1;
		memCount <= memCount + 4'd1;
		if (memCount==4'd3)
			state <= RWDONE;
	end
	// For a write cycle begin by enabling the ram's write input.
WR1:
	begin
		RamWEn <= ~sel[memCount];
		state <= WR2;
	end
	// AFter a cycle disable the write input. This will cause the ram to latch
	// the data.
WR2:
	begin
		RamWEn <= HIGH;
		state <= WR3;
	end
	// After another cycle, shift over the data to store to the ram.
	// increment the memory address and memory count.
	// If the count expired goto the done state, otherwise go back to the first
	// write state.
WR3:
	begin
		memDat <= {8'h00,memDat[31:8]};
		MemAdr <= MemAdr + 2'd1;
		memCount <= memCount + 2'd1;
		if (memCount==4'd3)
			state <= RWDONE;
		else
			state <= WR1;
	end
	// Here a read/write is done. Signal the processor.
RWDONE:
	begin
		ack_mem <= HIGH;
		state <= RWNACK;
	end
	// Wait until the processor is done with the read / write then go back to the
	// idle state to wait for another operation.
RWNACK:
	if (!cs_mem) begin
		ack_mem <= LOW;
		state <= IDLE;
	end
endcase

// Assign the memory bus tri-state unless a write is occuring.
// Reading the ram will override the tri-state drivers.
assign MemDB = RamWEn ? 8'bz : memDat[7:0];

always @(posedge clk)
	ack <= ack_rom|cs_irqsrc|cs_led|cs_btn|ack_mem|cs_gpio;

always @(posedge clk)
casez({cs_rom,cs_irqsrc,cs_btn,cs_mem,cs_gpio,cs_uart})
6'b1?????:	dat_i <= romo;
6'b01????:	dat_i <= adr[2] ? 8'h00 : {rxIRQ,timer1Irq};
6'b001???:	dat_i <= {6'h0,btn};
6'b0001??:	dat_i <= dati;
6'b00001?:	dat_i <= adr[2] ? {pio[14:1],1'b0} : {15'd0,pio3[22:0]};
6'b000001:	dat_i <= adr[2] ? {24'd0,rx_data_count, tx_empty, rx_empty} : {24'h0,rxDato};
default:	dat_i <= 32'hCCEECCEE;
endcase

// -----------------------------------------------------------------------------
// Serial Transmitter
// -----------------------------------------------------------------------------
wire pe_wr_tx;

rtfSimpleUartTx utx1
(
	// WISHBONE SoC bus interface
	.rst_i(rst),
	.clk_i(clk14p7),
	.cyc_i(wr_tx),
	.stb_i(wr_tx),
	.ack_o(),
	.we_i(wr_tx),
	.dat_i(dat_o[7:0]),
	//--------------------
	.cs_i(wr_tx),
	.baud16x_ce(1'b1),
  .baud8x(1'b0),
	.cts(1'b1),
	.txd(uart_rxd_out),
	.empty(tx_empty),
  .txc()
);

//assign uart_rxd_out = uart_txd_in;
edge_det ued1 (.rst(rst), .clk(clk14p7), .ce(1'b1), .i(cs_uart && we && adr[2]==1'b0), .pe(pe_wr_tx), .ne(), .ee());

always @(posedge clk14p7)
if (rst) 
	wr_tx <= 1'b0;
else begin
	wr_tx <= 1'b0;
	if (pe_wr_tx)
		wr_tx <= 1'b1;
end

// -----------------------------------------------------------------------------
// Serial Receiver
// -----------------------------------------------------------------------------

wire ne_rd_rx;

rtfSimpleUartRx urx1
(
	// WISHBONE SoC bus interface
	.rst_i(rst),
	.clk_i(clk14p7),
	.cyc_i(rd_rx),
	.stb_i(rd_rx),
	.ack_o(),
	.we_i(1'b0),
	.dat_o(rxdatib),
	//------------------------
	.cs_i(1'b1),
	.baud16x_ce(1'b1),
  .baud8x(1'b0),
	.clear(rst),
	.rxd(uart_txd_in),
	.data_present(rxDataPresent),
	.frame_err(),
	.overrun()
);

// 64-entry fifo for receive
CS01rxFifo urxf1
(
  .rst(rst),
  .wr_clk(clk14p7),
  .rd_clk(clk),
  .din(rxdatib),
  .wr_en(rd_rx),
  
  .rd_en(ne_rd_rx),
  .dout(rxDato),
  .full(),
  .empty(rx_empty),
  .rd_data_count(rx_data_count)
);

// Whenever data is present in the reciever generate a read pulse.
// Read and store the data.
always @(posedge clk14p7)
if (rst)
	rd_rx <= 1'b0;
else begin
	rd_rx <= 1'b0;
	if (rxDataPresent)
		rd_rx <= 1'b1;
end

edge_det ued2 (.rst(rst), .clk(clk), .ce(1'b1), .i(cs_uart && !we && adr[2]==1'b0), .pe(), .ne(ne_rd_rx), .ee());

// -----------------------------------------------------------------------------
// 30 Hz timer interrupt
// -----------------------------------------------------------------------------

reg [21:0] timer1Cnt;

always @(posedge clk)
if (rst)
	timer1Cnt <= 22'd1;
else begin
	timer1Cnt <= timer1Cnt + 2'd1;
	if (timer1Cnt==22'd1666666)
		timer1Cnt <= 22'd1;
end

always @(posedge clk)
if (rst)
	timer1Irq <= 1'b0;
else begin
	timer1Irq <= 1'b0;
	if (timer1Cnt==22'd1666666)
		timer1Irq <= 1'b1;
	if (cs_irqack & we)
		timer1Irq <= 1'b0;
end

// -----------------------------------------------------------------------------
// IRQ output
// -----------------------------------------------------------------------------

always @(posedge clk)
if (rst)
	irq <= 1'b0;
else
	irq <= 1'b0;//(timer1Irq|rxIrq);

assign led0_r = ~timer1Irq;
assign led0_g = ~cyc;
assign led0_b = ~cs_txmem & dvd[12];	// PWM 50% at about 12kHz.

// -----------------------------------------------------------------------------
// GPIO
// -----------------------------------------------------------------------------

reg [63:0] gpio_ddr;
reg [48:1] gpio_dato;
integer n;

always @(posedge clk)
if (rst)
	gpio_ddr <= 64'd0;
else begin
	if (cs_gpio && we)
		case(adr[3:2])
		2'd0:	gpio_dato[31:1] <= dat_o[31:1];
		2'd1: gpio_dato[48:32] <= dat_o[16:0];
		2'd2:	gpio_ddr[31:0] <= dat_o;
		2'd3:	gpio_ddr[63:32] <= dat_o;
		default:	;
		endcase
end

genvar g;
generate begin : gpi
for (g = 1; g < 15; g = g + 1) begin
	assign pio[g] = gpio_ddr[g] ? gpio_dato[g] : 1'bz;
end
end
endgenerate

// -----------------------------------------------------------------------------
// CPU
// -----------------------------------------------------------------------------

cs01riscv ucpu1
(
	.rst_i(rst),
	.clk_i(clk),
	.wc_clk_i(clk20),
	.irq_i(irq),
	.cyc_o(cyc),
	.stb_o(stb),
	.ack_i(ack),
	.we_o(we),
	.sel_o(sel),
	.adr_o(adr),
	.dat_i(dat_i),
	.dat_o(dat_o)
);

endmodule
