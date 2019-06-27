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
module CmodA7_SoC(sysclk, btn, 
	rst_o, phi2_o, vpb_i, rdy_io, abortb_o, irqb_o, nmib_o, mlb_i, vda_i, vpa_i,
	rw_i, adr_i, dat_io, e_i, mx_i, be_o,
	led, led0_r, led0_g, led0_b, p_io,
	uart_rxd_out, uart_txd_in,
	MemAdr, MemDB, ramOEn, ramWEn, ramCEn);
input sysclk;
input [1:0] btn;
output reg rst_o;
output reg [1:0] led;
output reg led0_r;
output reg led0_g;
output reg led0_b;
inout tri [5:0] p_io;
// 65C816 I/Os
output reg phi2_o;
input vpb_i;
inout tri rdy_io;
output abortb_o;
output reg irqb_o;
output nmib_o;
input mlb_i;
input vda_i;
input vpa_i;
input rw_i;
input [15:0] adr_i;
inout tri [7:0] dat_io;
input e_i;
input mx_i;
output be_o;
// Uart
output uart_rxd_out;
input uart_txd_in;

output [18:0] MemAdr;
inout tri [7:0] MemDB;
output reg ramOEn;
output reg ramWEn;
output reg ramCEn;

assign be_o = 1'b1;
assign rdy_io = 1'bz;
assign abortb_o = 1'b1;
assign irqb_o = 1'b1;
assign nmib_o = 1'b1;

wire xrst;
wire clk100,clk16,clk12;
wire locked;

wire [1:0] btn_db;
reg [23:0] adr;
reg [7:0] dati;
reg [7:0] dato;
reg [7:0] ramDato;

reg timer1Irq, rxIrq;
wire cs_rom;
wire cs_ram;
wire cs_txmem;
wire cs_rxmem;
wire cs_irqack;
wire cs_irqsrc;
wire cs_timer1IrqAck;

reg wr_tx, rd_rx, wrxd;
reg [14:0] tx_adr, rx_adr;
wire [7:0] rxdatoa, txdatoa;
wire [7:0] rxdatob, txdatob;
wire [7:0] rxdatib;

reg [32:0] rommem [0:1023];
initial begin
`include "cmodA7rom.ver"
end

reg [7:0] rom_dato;
always @*
case(adr[1:0])
2'd0:	rom_dato = rommem[adr[11:2]][7:0];
2'd1:	rom_dato = rommem[adr[11:2]][15:8];
2'd2:	rom_dato = rommem[adr[11:2]][23:16];
2'd3:	rom_dato = rommem[adr[11:2]][31:24];
endcase

rxtx_mem utxmem1
(
  .clka(clk100),
  .ena(cs_txmem),
  .wea(~rw_i),
  .addra(adr[12:0]),
  .dina(dat_io),
  .douta(txdatoa),
  .clkb(clk16),
  .enb(1'b1),
  .web(1'b0),
  .addrb(tx_adr),
  .dinb(8'h00),
  .doutb(txdatob)
);
rxtx_mem urxmem1
(
  .clka(clk100),
  .ena(cs_rxmem),
  .wea(~rw_i),
  .addra(adr[12:0]),
  .dina(dat_io),
  .douta(rxdatoa),
  .clkb(clk16),
  .enb(1'b1),
  .web(wrxd),
  .addrb(rx_adr),
  .dinb(rxdatib),
  .doutb()
);

// -----------------------------------------------------------------------------
// Input debouncing
// Pressing both buttons at the same time resets the system.
// -----------------------------------------------------------------------------

BtnDebounce udbu (sysclk, btn[0], btn_db[0]);
BtnDebounce udbd (sysclk, btn[1], btn_db[1]);

assign xrst = btn_db[0] & btn_db[1];

// -----------------------------------------------------------------------------
// Clock generator
// -----------------------------------------------------------------------------

clkCmodA7 uclk1
(
  // Clock out ports
  .clk100(clk100),
  .clk16(clk16),
  .clk12(clk12),
  // Status and control signals
  .reset(xrst),
  .locked(locked),
 // Clock in ports
  .clk_in1(sysclk)
);

assign phi2_o = clk12;
assign rst_o = ~locked;

// -----------------------------------------------------------------------------
// Circuit select logic
// -----------------------------------------------------------------------------

assign cs_rom = (vpa_i||vda_i) && adr[23:12] == 12'b0000_0000_1111;
assign cs_ram = (vpa_i||vda_i) && adr[23:20] == 4'h0 && !cs_rom;
assign cs_txmem = (vpa_i||vda_i) && adr[23:16]==8'hF1;
assign cs_rxmem = (vpa_i||vda_i) && adr[23:16]==8'hF0;
assign cs_irqsrc = (vpa_i||vda_i) && adr[23:0]==24'hF20000;
assign cs_irqack = (vpa_i||vda_i) && adr[23:0]==24'hF20001;
assign cs_timer1IrqAck = (vpa_i||vda_i) && adr[23:0]==24'hF20002;

// -----------------------------------------------------------------------------
// RAM bus bridge
// -----------------------------------------------------------------------------

always @(posedge clk100)
if (~phi2_o)
	adr[23:16] <= dat_io;
always @(posedge clk100)
	adr[15:0] <= adr_i;
assign MemAdr = adr[18:0];	
always @(posedge clk100)
	ramCEn <= ~cs_ram;
always @(posedge clk100)
	ramWEn <= rw_i | ~phi2_o;
always @(posedge clk100)
	ramOEn <= ~(cs_ram & rw_i);
always @(posedge clk100)
	ramDato <= dat_io;
assign MemDB = rw_i ? 8'bz : ramDato;

always @(posedge clk100)
casez({cs_rom,cs_txmem,cs_rxmem,cs_irqsrc})
4'b1???:	dato <= rom_dato;
4'b01??:	dato <= txdatoa;
4'b001?:	dato <= rxdatoa;
4'b0001:	dato <= {timer1Irq,rxIrq};
default:	dato <= MemDB;
endcase

assign dat_io = rw_i ? dato : 8'bz;

// -----------------------------------------------------------------------------
// Serial Transmitter
//
// The serial transmitter transmits a buffer periodically. The first 32 bytes
// of the buffer should contain the sync character FF.
// -----------------------------------------------------------------------------
wire tx_empty;

rtfSimpleUartTx utx1
(
	// WISHBONE SoC bus interface
	.rst_i(rst_o),
	.clk_i(clk16),
	.cyc_i(wr_tx),
	.stb_i(wr_tx),
	.ack_o(),
	.we_i(wr_tx),
	.dat_i(txdatob),
	//--------------------
	.cs_i(1'b1),
	.baud16x_ce(1'b1),
  .baud8x(1'b0),
	.cts(1'b1),
	.txd(uart_rxd_out),
	.empty(tx_empty),
  .txc()
);

always @(posedge clk16)
if (rst_o) 
	wr_tx <= 1'b0;
else begin
	wr_tx <= 1'b0;
	if (tx_empty)
		wr_tx <= 1'b1;
end

always @(posedge clk16)
if (rst_o)
 	tx_adr <= 15'd0;
else begin
	if (timer1Irq)
		tx_adr <= 15'd0;
	else if (tx_empty)
		tx_adr <= tx_adr + 15'd1;
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
	.rst_i(rst_o),
	.clk_i(clk16),
	.cyc_i(rd_rx),
	.stb_i(rd_rx),
	.ack_o(),
	.we_i(1'b0),
	.dat_o(rxdatib),
	//------------------------
	.cs_i(1'b1),
	.baud16x_ce(1'b1),
  .baud8x(1'b0),
	.clear(rst_o),
	.rxd(uart_txd_in),
	.data_present(rxDataPresent),
	.frame_err(),
	.overrun()
);

// Whenever data is present in the reciever generate a read pulse.
// Read and store the data.
always @(posedge clk16)
if (rst_o)
	rd_rx <= 1'b0;
else begin
	rd_rx <= 1'b0;
	if (rxDataPresent)
		rd_rx <= 1'b1;
end

always @(posedge clk16)
if (rst_o)
	wrxd <= 1'b0;
else
	wrxd <= rd_rx;

always @(posedge clk16)
if (rst_o)
	synccnt <= 8'd0;
else begin
	if (wrxd) begin
		if (rxdatib == 8'hFF)
			synccnt <= synccnt + 2'd1;
		else
			synccnt <= 8'd0;
	end
end

always @(posedge clk16)
if (rst_o)
	eotcnt <= 8'd0;
else begin
	if (wrxd) begin
		if (rxdatib == 8'hAA)
			eotcnt <= eotcnt + 2'd1;
		else
			eotcnt <= 8'd0;
	end
end

always @(posedge clk16)
if (rst_o)
	rxIrq <= 1'b0;
else begin
	if (eotcnt==8'd16)
		rxIrq <= 1'b1;
	else if (cs_irqack)
		rxIrq <= 1'b0;
end

// Reciever addressing.
// Reset the reciever address if a sync sequence is detected.
// The sync sequence is 16 or more FF's.
always @(posedge clk16)
if (rst_o)
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

reg [19:0] timer1Cnt;

always @(posedge clk12)
if (rst_o)
	timer1Cnt <= 20'd1;
else begin
	timer1Cnt <= timer1Cnt + 2'd1;
	if (timer1Cnt==20'd400000)
		timer1Cnt <= 20'd1;
end

always @(posedge clk12)
if (rst_o)
	timer1Irq <= 1'b0;
else begin
	if (timer1Cnt==20'd400000)
		timer1Irq <= 1'b1;
	if (cs_timer1IrqAck)
		timer1Irq <= 1'b0;
end

// -----------------------------------------------------------------------------
// IRQ output
// -----------------------------------------------------------------------------

always @(posedge clk100)
if (rst_o)
	irqb_o <= 1'b1;
else
	irqb_o <= ~(timer1Irq|rxIrq);

assign led0_r = timer1Irq;
assign led0_g = rxIrq;
assign led0_b = 1'b0;

endmodule

