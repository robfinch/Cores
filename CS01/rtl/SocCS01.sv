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
`define SIM		1'b1

module SocCS01(sysclk, btn, pio,
	led, led0_r, led0_g, led0_b,
	uart_rxd_out, uart_txd_in,
	MemAdr, MemDB, RamOEn, RamWEn, RamCEn);
input sysclk;
input [1:0] btn;
inout tri reg [48:1] pio;
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

// -----------------------------------------------------------------------------
// Signals and registers
// -----------------------------------------------------------------------------
wire xrst;					// external reset (push button)
wire rst;						// internal reset
wire clk;						// system clock (50MHz)
wire clk14p7;				// uart clock 14.746 MHz
wire locked;				// clock generation is locked
wire [1:0] btn_db;	// debounced button output

reg irq;
reg timer1Irq;
reg rxIrq;
wire cyc;						// cpu cycle is active
reg ack;						// cpu transfer acknowledge
wire we;						// cpu write cycle
wire [15:0] adr;		// cpu address
reg [79:0] dat_i;		// cpu data input
wire [79:0] dat_o;	// cpu data output
reg [79:0] dati;		// memory data input

wire cs_io;
wire cs_mem;
wire cs_rxmem;
wire cs_txmem;
wire cs_led;
wire cs_irqsrc;
wire cs_irqack;
wire cs_gpio;
reg ack_mem;

// -----------------------------------------------------------------------------
// Clock generation
// -----------------------------------------------------------------------------

cs01clkgen ucg1
(
  // Clock out ports
  .clk50(clk),
  .clk14p7(clk14p7),
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
// 0000	+---------------+
// 			|               |
// 			|  Ram 52.4kD   | (80 bits wide)
// 			|               |
// D000	+---------------+
// 			|  Rx Buffer    | (32 bits wide)
// E000	+---------------+
// 			|  Tx Buffer    |	(32 bits wide)
// F000	+---------------+
// 		  |     I/O       |
// FFFF	+---------------+
//
// I/O Map
//
// F030	+---------------+
//      |  LED / BTN    |
// F040	+---------------+
//      |  IRQ Status   |
// F050	+---------------+
//      |  IRQ Status   |
// F060	+---------------+
//      |    GPIO       |
//      +---------------+
//
// -----------------------------------------------------------------------------

assign cs_io = cyc && adr[15:12]==4'hF;
assign cs_mem = cyc && adr[15:12] <= 4'hD;
assign cs_rxmem = cyc && adr[15:12]==4'hD;
assign cs_txmem = cyc && adr[15:12]==4'hE;
assign cs_led = cyc && adr[15:4]==12'hF03;
assign cs_irqsrc = cyc && adr[15:4]==12'hF04;
assign cs_irqack = cyc && adr[15:4]==12'hF05;
assign cs_gpio = cyc && adr[15:4]==12'hF06

reg ack_txmem, ack_rxmem;
reg wr_tx, rd_rx, wrxd;
reg [13:0] tx_adr, rx_adr;
wire [31:0] rxdatoa, txdatoa;
wire [7:0] rxdatob, txdatob;
wire [7:0] rxdatib;
reg [7:0] readyFifoDato;
reg [7:0] readyFifoCnt;
reg rxIRQ;

rxtx_mem utxmem1
(
  .clka(clk),
  .ena(cs_txmem),
  .wea(we),
  .addra(adr[11:0]),
  .dina(dat_o[31:0]),
  .douta(txdatoa),
  .clkb(clk14p7),
  .enb(1'b1),
  .web(1'b0),
  .addrb(tx_adr),
  .dinb(8'h00),
  .doutb(txdatob)
);
rxtx_mem urxmem1
(
  .clka(clk),
  .ena(cs_rxmem),
  .wea(we),
  .addra(adr[11:0]),
  .dina(dat_o[31:0]),
  .douta(rxdatoa),
  .clkb(clk14p7),
  .enb(1'b1),
  .web(wrxd),
  .addrb(rx_adr),
  .dinb(rxdatib),
  .doutb()
);

always @(posedge clk)
	ack_txmem <= cs_txmem;
always @(posedge clk)
	ack_rxmem <= cs_rxmem;

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
reg [79:0] memDat;

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
		dati <= {dati[71:0],MemDB};
		MemAdr <= MemAdr + 2'd1;
		memCount <= memCount + 4'd1;
		if (memCount==4'd9)
			state <= RWDONE;
	end
	// For a write cycle begin by enabling the ram's write input.
WR1:
	begin
		RamWEn <= LOW;
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
		memDat <= {8'h00,memDat[79:8]};
		MemAdr <= MemAdr + 2'd1;
		memCount <= memCount + 2'd1;
		if (memCount==4'd9)
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
	ack <= ack_txmem|ack_rxmem|cs_irqsrc|cs_led|ack_mem|cs_gpio;

always @(posedge clk)
casez({cs_txmem,cs_rxmem,cs_irqsrc,cs_led,cs_mem,cs_gpio})
6'b1?????:	dat_i <= txdatoa;
6'b01????:	dat_i <= rxdatoa;
6'b001???:	dat_i <= adr[0] ? 8'h00 : {rxIRQ,timer1Irq};
6'b0001??:	dat_i <= {6'h0,btn};
6'b00001?:	dat_i <= dati;
6'b000001:	dat_i <= {pio,1'b0};
default:	dat_i <= 80'hCCEECCEECCEECCEECCEE;
endcase

// -----------------------------------------------------------------------------
// Serial Transmitter
//
// The serial transmitter transmits a buffer periodically. The first 32 bytes
// of the buffer should contain the sync character FF.
// -----------------------------------------------------------------------------
wire tx_empty;
wire pe_tx_empty;
reg [7:0] txdata;
`ifdef DEBUG
reg [255:0] msgHelloWorld = "     H e l l o   w o r l d !    ";
reg [7:0] chars [0:31];
genvar g;
generate begin : strx
for (g = 0; g < 32; g = g + 1) begin
	always @*
		chars[31-g] = msgHelloWorld[g*8+7:g*8];
	end
end
endgenerate
`endif

rtfSimpleUartTx utx1
(
	// WISHBONE SoC bus interface
	.rst_i(rst),
	.clk_i(clk14p7),
	.cyc_i(wr_tx),
	.stb_i(wr_tx),
	.ack_o(),
	.we_i(wr_tx),
	.dat_i(txdata),
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
edge_det ued1 (.rst(rst), .clk(clk14p7), .ce(1'b1), .i(tx_empty), .pe(pe_tx_empty), .ne(), .ee());

always @(posedge clk14p7)
if (rst) 
	wr_tx <= 1'b0;
else begin
	wr_tx <= 1'b0;
	if (pe_tx_empty)
		wr_tx <= 1'b1;
end

always @(posedge clk14p7)
if (rst)
 	tx_adr <= 14'd0;
else begin
	if (timer1Irq)
		tx_adr <= 14'd0;
	else if (wr_tx)
		tx_adr <= tx_adr + 14'd1;
end

always @(posedge clk14p7)
if (rst)
	txdata <= SYNC;
else begin
	if (tx_adr < 13'h0014)
		txdata <= SYNC;
`ifdef DEBUG
	else if (tx_adr < 13'h0034)
		txdata <= chars[tx_adr-8'h14];
`endif
	else
		txdata <= txdatob;
end

// -----------------------------------------------------------------------------
// Serial Receiver
//
// Recieving begins with the recognition of 16 or more FF bytes and ends
// with the recognition of 16 or more AA bytes. When the AA bytes are
// recieved an interrupt to the cpu is asserted.
// -----------------------------------------------------------------------------

wire rxDataPresent;
reg [7:0] synccnt;
reg [7:0] eotcnt;

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

always @(posedge clk14p7)
if (rst)
	wrxd <= 1'b0;
else
	wrxd <= rd_rx;

always @(posedge clk14p7)
if (rst)
	synccnt <= 8'd0;
else begin
	if (wrxd) begin
		if (rxdatib == 8'hFF)
			synccnt <= synccnt + 2'd1;
		else
			synccnt <= 8'd0;
	end
end

always @(posedge clk14p7)
if (rst)
	eotcnt <= 8'd0;
else begin
	if (wrxd) begin
		if (rxdatib == 8'hAA)
			eotcnt <= eotcnt + 2'd1;
		else
			eotcnt <= 8'd0;
	end
end

always @(posedge clk14p7)
if (rst)
	rxIrq <= 1'b0;
else begin
	if (eotcnt==8'd16)
		rxIrq <= 1'b1;
	else if (cs_irqack & we)
		rxIrq <= 1'b0;
end

// Reciever addressing.
// Reset the reciever address if a sync sequence is detected.
// The sync sequence is 16 or more FF's.
always @(posedge clk14p7)
if (rst)
	rx_adr <= 15'd0;
else begin
	if (wrxd) begin
		if (synccnt >= 8'd16)
			rx_adr <= 15'd0;
		else
			rx_adr <= rx_adr + 15'd1;
	end
end

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

reg [79:0] gpio_ddr;
reg [48:1] gpio_dato;
integer n;

always @(posedge clk)
if (rst)
	gpio_ddr <= 80'd0;
else begin
	if (cs_gpio && we)
		case(adr[3:0])
		4'd0:	gpio_dato <= dat_o[48:1];
		4'd1:	gpio_ddr <= dat_o;
		default:	;
		endcase
end
always @*
	for (n = 1; n < 49; n = n + 1)
		pio[n] = gpio_ddr[n] ? gpio_dato[n] : 1'bz;

// -----------------------------------------------------------------------------
// CPU
// -----------------------------------------------------------------------------

cs01 ucpu1
(
	.rst_i(rst),
	.clk_i(clk),
	.irq_i(irq),
	.cyc_o(cyc),
	.ack_i(ack),
	.we_o(we),
	.adr_o(adr),
	.dat_i(dat_i),
	.dat_o(dat_o)
);

endmodule
