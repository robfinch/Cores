// ============================================================================
//        __
//   \\__/ o\    (C) 2005-2024  Robert Finch, Waterloo
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
// 369 LUTs / 409 FFs
// ============================================================================
//
`define UART_TRB 		3'd0    // transmit/receive buffer
`define UART_STAT		3'd1
`define UART_CMD		3'd2
`define UART_CTRL		3'd3
`define UART_IMC		3'd4		// interrupt message control

import fta_bus_pkg::*;

module uart6551_fta32(rst_i, clk_i, cs_config_i, cs_io_i,
	req, resp,
	cts_ni, rts_no, dsr_ni, dcd_ni, dtr_no, ri_ni,
	rxd_i, txd_o, data_present,
	rxDRQ_o, txDRQ_o,
	xclk_i, RxC_i
);
parameter pClkFreq = 100;
parameter pCounterBits = 24;
parameter pFifoSize = 1024;
parameter pClkDiv = 24'd1302;	// 9.6k baud, 200.000MHz clock
parameter HIGH = 1'b1;
parameter LOW = 1'b0;

parameter UART_ADDR = 32'hFED00001;
parameter UART_ADDR_MASK = 32'h00FF0000;

parameter CFG_BUS = 8'd0;
parameter CFG_DEVICE = 5'd16;
parameter CFG_FUNC = 3'd0;
parameter CFG_VENDOR_ID	=	16'h0;
parameter CFG_DEVICE_ID	=	16'h0;
parameter CFG_SUBSYSTEM_VENDOR_ID	= 16'h0;
parameter CFG_SUBSYSTEM_ID = 16'h0;
parameter CFG_ROM_ADDR = 32'hFFFFFFF0;

parameter CFG_REVISION_ID = 8'd0;
parameter CFG_PROGIF = 8'd1;
parameter CFG_SUBCLASS = 8'h80;					// 80 = Other
parameter CFG_CLASS = 8'h03;						// 03 = display controller
parameter CFG_CACHE_LINE_SIZE = 8'd8;		// 32-bit units
parameter CFG_MIN_GRANT = 8'h00;
parameter CFG_MAX_LATENCY = 8'h00;
parameter CFG_IRQ_LINE = 8'd16;

localparam CFG_HEADER_TYPE = 8'h00;			// 00 = a general device

parameter MSIX = 1'b0;
input rst_i;
input clk_i;			// fta bus clock eg. 50.000MHz
input cs_config_i;		// config region circuit select
input cs_io_i;		// IO region circuit select
// FTA -------------------------------
input fta_cmd_request32_t req;
output fta_cmd_response32_t resp;
//------------------------------------------
wire [31:0] irq_o;		// interrupt request
input cts_ni;			// clear to send - (flow control) active low
output reg rts_no;		// request to send - (flow control) active low
input dsr_ni;	// data set ready - active low
input dcd_ni;	// data carrier detect - active low
output reg dtr_no;	// data terminal ready - active low
input ri_ni;		// ring indicator
input rxd_i;		// serial data in
output txd_o;		// serial data out
output data_present;
output rxDRQ_o;	// reciever DMA request
output txDRQ_o;	// transmitter DMA request
input xclk_i;		// external clock source
input RxC_i;		// external receiver clock source

wire cs_uart;
reg [31:0] uart_addr;
reg accessCD;		// clock multiplier access flag
reg llb;			// local loopback mode
reg dmaEnable;
// baud rate clock control
reg [4:0] baudRateSel;
reg selCD;				// Use clock multiplier register
reg [pCounterBits-1:0] c;	// current count
reg [pCounterBits-1:0] ckdiv;	// baud rate clock divider
reg [pCounterBits-1:0] clkdiv;	// clock multiplier register
reg [1:0] xclks;	// synchronized external clock
reg [1:0] RxCs;		// synchronized external receiver clock
reg baud16;			// 16x baud rate clock
wire baud16rx;		// reciever clock
reg xClkSrc;		// uart baud clock is external
reg rxClkSrc;		// receiver clock is external

// frame format registers
reg [3:0] wordLength;
reg stopBit;
reg [2:0] stopBits;
reg [2:0] parityCtrl;
wire [7:0] frameSize;

reg txBreak;		// transmit a break

wire rxFull;
wire rxEmpty;
wire txFull;
wire txEmpty;
reg hwfc;			// hardware flow control enable
wire [7:0] lineStatusReg;
wire [7:0] modemStatusReg;
wire [7:0] irqStatusReg;
// interrupt
wire irq_en;		// global IRQ enable
reg irq;
reg rxIe;
reg txIe;
reg modemStatusChangeIe;
wire modemStatusChange;
reg lineStatusChangeIe;
wire lineStatusChange;
reg rxToutIe;		// receiver timeout interrupt enable
reg [3:0] rxThres;	// receiver threshold for interrupt
reg [3:0] txThres;	// transmitter threshold for interrupt
reg rxTout;			// receiver timeout
wire [9:0] rxCnt;	// reciever counter value
reg [7:0] rxToutMax;
reg [2:0] irqenc;	// encoded irq cause
wire rxITrig;		// receiver interrupt trigger level
wire txITrig;		// transmitter interrupt trigger level
// reciever errors
wire parityErr;		// reciever detected a parity error
wire frameErr;		// receiver char framing error
wire overrun;		// receiver over run
wire rxBreak;		// reciever detected a break
wire rxGErr;		// global error: there is at least one error in the reciever fifo
// modem controls
reg [1:0] ctsx;		// cts_n sampling
reg [1:0] dcdx;
reg [1:0] dsrx;
reg [1:0] rix;
reg deltaCts;
reg deltaDcd;
reg deltaDsr;
reg deltaRi;

// fifo
reg rxFifoClear;
reg txFifoClear;
reg txClear;
reg fifoEnable;
wire [3:0] rxQued;
wire [3:0] txQued;

// IRQ management
reg irqa;
reg irq_cdr;
reg [7:0] irq_device;
reg [5:0] irq_core;
reg [2:0] irq_channel;
reg [3:0] irq_priority;
reg [7:0] cause_code;
wire respack;
fta_tranid_t resptid;
fta_cmd_request32_t reqi;
fta_address_t respadr;

// config
reg [31:0] cfg_out;

// test
wire txd1;

assign data_present = ~rxEmpty;

assign rxITrig = rxQued >= rxThres;
assign txITrig = txQued <= txThres;
wire rxDRQ1 = (fifoEnable ? rxITrig : ~rxEmpty);
wire txDRQ1 = (fifoEnable ? txITrig : txEmpty);
assign rxDRQ_o = dmaEnable & rxDRQ1;
assign txDRQ_o = dmaEnable & txDRQ1;
wire rxIRQ = rxIe & rxDRQ1;
wire txIRQ = txIe & txDRQ1;

reg [7:0] cmd0, cmd1, cmd2, cmd3;
reg [7:0] ctrl0, ctrl1, ctrl2, ctrl3;

always_ff @(posedge clk_i)
	irq <= (
	  rxIRQ
	| txIRQ
	| (rxTout & rxToutIe)
	| (lineStatusChange & lineStatusChangeIe)
	| (modemStatusChange & modemStatusChangeIe)
	) & irq_en;
	;

// Hold onto address and data an extra cycle.
// The extra cycle updates or reads the serial transmit / receive.
reg we;
reg [3:0] sel;
reg [31:0] dati;
reg [31:0] dat_o;
reg [31:0] adr_h;
always_ff @(posedge clk_i)
	reqi <= req;
always_ff @(posedge clk_i)
	dati <= req.dat;
always_ff @(posedge clk_i)
	adr_h <= req.padr;
always_ff @(posedge clk_i)
	we <= req.we;
always_ff @(posedge clk_i)
	sel <= req.sel;

wire [7:0] rx_do;
reg erc;

reg cs_config, cs_io, cs_io_ii;
always_ff @(posedge clk_i)
	erc <= req.cti==fta_bus_pkg::ERC;
always_ff @(posedge clk_i)
	cs_config <= req.cyc & req.stb & cs_config_i && req.padr[27:20]==CFG_BUS && req.padr[19:15]==CFG_DEVICE && req.padr[14:12]==CFG_FUNC;
always_ff @(posedge clk_i)
	cs_io_ii <= cs_io_i;
always_comb
	cs_io = cs_io_ii & reqi.cyc & reqi.stb && cs_uart;

wire rdrx = cs_io && adr_h[4:2]==`UART_TRB && ~we && !accessCD;
wire txrx = cs_io && we && adr_h[4:2]==`UART_TRB && !accessCD;

vtdl #(.WID(1), .DEP(16)) urdyd2 (.clk(clk_i), .ce(1'b1), .a(4'd0), .d((cs_io|cs_config)&(erc|~we)), .q(respack));
//vtdl #(.WID(6), .DEP(16)) urdyd3 (.clk(clk_i), .ce(1'b1), .a(4'd1), .d(req.cid), .q(resp.cid));
vtdl #(.WID($bits(fta_tranid_t)), .DEP(16)) urdyd4 (.clk(clk_i), .ce(1'b1), .a(4'd1), .d(req.tid), .q(resptid));
vtdl #(.WID($bits(fta_address_t)), .DEP(16)) urdyd5 (.clk(clk_i), .ce(1'b1), .a(4'd1), .d(req.padr), .q(respadr));
assign resp.ack = respack ? 1'b1 : irqa;
assign resp.tid = respack ? resptid : irqa ? {irq_core,irq_channel,4'd0} : 13'd0;
assign resp.next = 1'b0;
assign resp.stall = 1'b0;
assign resp.err = respack ? fta_bus_pkg::OKAY : irqa ? fta_bus_pkg::IRQ : fta_bus_pkg::OKAY;
assign resp.rty = 1'b0;
assign resp.pri = respack ? 4'd7 : irqa ? irq_priority : 4'd7;
assign resp.adr = respack ? respadr : irqa ? {CFG_BUS,CFG_DEVICE,CFG_FUNC} : 32'd0;
assign resp.dat = respack ? dat_o : irqa ? {24'h00,cause_code} : 32'd0;

pci32_config #(
	.CFG_BUS(CFG_BUS),
	.CFG_DEVICE(CFG_DEVICE),
	.CFG_FUNC(CFG_FUNC),
	.CFG_VENDOR_ID(CFG_VENDOR_ID),
	.CFG_DEVICE_ID(CFG_DEVICE_ID),
	.CFG_BAR0(UART_ADDR),
	.CFG_BAR0_MASK(UART_ADDR_MASK),
	.CFG_SUBSYSTEM_VENDOR_ID(CFG_SUBSYSTEM_VENDOR_ID),
	.CFG_SUBSYSTEM_ID(CFG_SUBSYSTEM_ID),
	.CFG_ROM_ADDR(CFG_ROM_ADDR),
	.CFG_REVISION_ID(CFG_REVISION_ID),
	.CFG_PROGIF(CFG_PROGIF),
	.CFG_SUBCLASS(CFG_SUBCLASS),
	.CFG_CLASS(CFG_CLASS),
	.CFG_CACHE_LINE_SIZE(CFG_CACHE_LINE_SIZE),
	.CFG_MIN_GRANT(CFG_MIN_GRANT),
	.CFG_MAX_LATENCY(CFG_MAX_LATENCY),
	.CFG_IRQ_LINE(CFG_IRQ_LINE)
)
ucfg1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.irq_i(irq),
	.irq_o(irq_o),
	.cs_config_i(cs_config), 
	.we_i(we),
	.sel_i(sel),
	.adr_i(adr_h),
	.dat_i(dati),
	.dat_o(cfg_out),
	.cs_bar0_o(cs_uart),
	.cs_bar1_o(),
	.cs_bar2_o(),
	.irq_en_o(irq_en)
);

uart6551Rx uart_rx0
(
	.rst(rst_i),
	.clk(clk_i),
	.cyc(cs_io),
	.cs(rdrx),
	.wr(we),
	.dout(rx_do),
	.ack(),
	.fifoEnable(fifoEnable),
	.fifoClear(rxFifoClear),
	.clearGErr(1'b0),
	.wordLength(wordLength),
	.parityCtrl(parityCtrl),
	.frameSize(frameSize),
	.stop_bits(stopBits),
	.baud16x_ce(baud16rx),
	.clear(1'b0),
	.rxd(llb ? txd1 : rxd_i),
	.full(),
	.empty(rxEmpty),
	.frameErr(frameErr),
	.overrun(overrun),
	.parityErr(parityErr),
	.break_o(rxBreak),
	.gerr(rxGErr),
	.qcnt(rxQued),
	.cnt(rxCnt)
);

uart6551Tx uart_tx0
(
	.rst(rst_i),
	.clk(clk_i),
	.cyc(cs_io),
	.cs(txrx),
	.wr(we),
	.din(dati[7:0]),
	.ack(),
	.fifoEnable(fifoEnable),
	.fifoClear(txFifoClear),
	.txBreak(txBreak),
	.frameSize(frameSize),	// 16 x 10 bits
	.wordLength(wordLength),// 8 bits
	.parityCtrl(parityCtrl),// no parity
	.baud16x_ce(baud16),
	.cts(ctsx[1]|~hwfc),
	.clear(txClear),
	.txd(txd1),
	.full(txFull),
	.empty(txEmpty),
	.qcnt(txQued)
);

assign txd_o = llb ? 1'b1 : txd1;

assign lineStatusReg = {rxGErr,1'b0,txFull,rxBreak,1'b0,1'b0,1'b0,1'b0};
assign modemStatusChange = deltaDcd|deltaRi|deltaDsr|deltaCts;	// modem status delta
assign modemStatusReg = {1'b0,~rix[1],1'b0,~ctsx[1],deltaDcd, deltaRi, deltaDsr, deltaCts};
assign irqStatusReg = {irq_o,2'b00,irqenc,2'b00};

// mux the reg outputs
always_ff @(posedge clk_i)
if (cs_config)
	dat_o <= cfg_out;
else if (cs_io) begin
	case(adr_h[4:2])
	`UART_TRB:	dat_o <= accessCD ? {8'h0,clkdiv} : {24'h0,rx_do};	// receiver holding register
	`UART_STAT:	dat_o <= {irqStatusReg,modemStatusReg,lineStatusReg,irq_o,dsrx[1],dcdx[1],fifoEnable ? ~txFull : txEmpty,~rxEmpty,overrun,frameErr,parityErr};
	`UART_CMD:	dat_o <= {cmd3,cmd2,cmd1,cmd0};
	`UART_CTRL:	dat_o <= {ctrl3,ctrl2,ctrl1,ctrl0};
	`UART_IMC:	dat_o <= {irq_device,2'd0,irq_core,1'b0,irq_channel,irq_priority,cause_code};
	default:		dat_o <= 32'd0;
	endcase
end
else
	dat_o <= 32'd0;

change_det ucd1 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(irq), .cd(irq_cd));

always_comb
	if ((irq_cd|irq_cdr) & !respack)
		irqa = 1'b1;
	else
		irqa = 1'b0;

always_ff @(posedge clk_i)
if (rst_i)
	irq_cdr <= 1'b0;
else begin
	if (irq_cd)
		irq_cdr <= 1'b1;
	if (irqa)
		irq_cdr <= 1'b0;
end

// register updates
always_ff @(posedge clk_i)
if (rst_i) begin
	rts_no <= HIGH;
	dtr_no <= HIGH;
	// interrupts
	rxIe 				<= 1'b0;
	txIe 				<= 1'b0;
	modemStatusChangeIe	<= 1'b0;
	lineStatusChangeIe 	<= 1'b0;
	hwfc 				<= 1'b0;
	modemStatusChangeIe	<= 1'b0;
	lineStatusChangeIe	<= 1'b0;
	dmaEnable			<= 1'b0;
	// clock control
	baudRateSel <= 5'h0;
	rxClkSrc	<= 1'b0;		// ** 6551 defaults to zero (external receiver clock)
	clkdiv <= pClkDiv;
	// frame format
	wordLength 	<= 4'd8;	// 8 bits
	stopBit 	<= 1'b0;		// 1 stop bit
	parityCtrl 	<= 3'd0;	// no parity

	txBreak 	<= 1'b0;
	// Fifo control
	txFifoClear	<= 1'b1;
	rxFifoClear <= 1'b1;
	txClear <= 1'b1;
	fifoEnable	<= 1'b1;
	// Test
	llb			<= 1'b0;
	selCD		<= 1'b0;
	accessCD   <= 1'b0;
	
	cmd0 <= 8'h00;
	cmd1 <= 8'h00;
	cmd2 <= 8'h00;
	cmd3 <= 8'h00;
	
	ctrl0 <= 8'h00;
	ctrl1 <= 8'h00;
	ctrl2 <= 8'h06;
	ctrl3 <= 8'h20;
	
	irq_device <= 8'd5;
	irq_core <= 6'd1;
	irq_channel <= 3'd2;
	irq_priority <= 4'd5;
	cause_code <= 8'h00;
end
else begin

	//llb <= 1'b1;
	rxFifoClear <= 1'b0;
	txFifoClear <= 1'b0;
	txClear <= 1'b0;
	ctrl2[1] <= 1'b0;
	ctrl2[2] <= 1'b0;

	if (cs_io & we) begin
		case (adr_h[4:2])	// synopsys full_case parallel_case

	 	`UART_TRB:
	 		if (accessCD) begin
 				clkdiv <= dati;
 				accessCD <= 1'b0;
 				ctrl3[7] <= 1'b0;
 			end

		// Writing to the status register does a software reset of some bits.
		`UART_STAT:
			begin
				dtr_no <= HIGH;
				rxIe <= 1'b0;
				rts_no <= HIGH;
				txIe <= 1'b0;
				txBreak <= 1'b0;
				llb <= 1'b0;
			end
	 	`UART_CMD:
      begin
      	if (sel[0]) begin
      		cmd0 <= dati[7:0];
		 			dtr_no <= ~dati[0];
	        rxIe   <= ~dati[1];
	        case(dati[3:2])
	        2'd0:	begin rts_no <= 1'b1; txIe <= 1'b0; txBreak <= 1'b0; end
	        2'd1: begin rts_no <= 1'b0; txIe <= 1'b1; txBreak <= 1'b0; end
	        2'd2: begin rts_no <= 1'b0; txIe <= 1'b0; txBreak <= 1'b0; end
	        2'd3: begin rts_no <= 1'b0; txIe <= 1'b0; txBreak <= 1'b1; end
	      	endcase
	      	llb <= dati[4];
          parityCtrl <= dati[7:5];    //000=none,001=odd,011=even,101=force 1,111 = force 0
      	end
      	if (sel[1]) begin
      		cmd1 <= dati[15:8];
        	lineStatusChangeIe  <= dati[8];
        	modemStatusChangeIe <= dati[9];
        	rxToutIe <= dati[10];
      	end
      	if (sel[2])
      		cmd2 <= dati[23:16];
      	if (sel[3])
      		cmd3 <= dati[31:24];
      end

    `UART_CTRL:
    	begin
    		if (sel[0]) begin
    			ctrl0 <= dati[7:0];
      		baudRateSel[3:0] <= dati[3:0];
		 			rxClkSrc <= dati[4];				// 1 = baud rate generator, 0 = external
          //11=5,10=6,01=7,00=8
          case(dati[6:5])
          2'd0:	wordLength <= 6'd8;
          2'd1:	wordLength <= 6'd7;
          2'd2:	wordLength <= 6'd6;
          2'd3:	wordLength <= 6'd5;
        	endcase
          stopBit    <= dati[7];      //0=1,1=1.5 or 2
      	end
     		// Extended word length, values beyond 11 not supported.
      	if (sel[1]) begin
      		ctrl1 <= dati[15:8];
      	end
      	if (sel[2]) begin
      		ctrl2 <= dati[23:16];
	        fifoEnable <= dati[16];
	        rxFifoClear <= dati[17];
	        txFifoClear <= dati[18];
	        case (dati[21:20])
	        2'd0:   txThres <= 4'd1;                // one-byte
	        2'd1:   txThres <= pFifoSize / 4;       // one-quarter full
	        2'd2:   txThres <= pFifoSize / 2;       // one-half full
	        2'd3:   txThres <= pFifoSize * 3 / 4;   // three-quarters full
	        endcase
	        case (dati[23:22])
	        2'd0:   rxThres <= 4'd1;                // one-byte
	        2'd1:   rxThres <= pFifoSize / 4;       // one-quarter full
	        2'd2:   rxThres <= pFifoSize / 2;       // one-half full
	        2'd3:   rxThres <= pFifoSize * 3 / 4;   // three quarters full
	        endcase
        end
        if (sel[3]) begin
        	ctrl3 <= dati[31:24];
		 			hwfc <= dati[24];
		 			dmaEnable <= dati[26];
      		baudRateSel[4] <= dati[27];
      		txClear <= dati[29];
      		selCD <= dati[30];
      		accessCD <= dati[31];
      	end
      end
		`UART_IMC:
			begin
				if (sel[0])	cause_code <= dati[7:0];
				if (sel[1]) begin
					irq_priority <= dati[11:8];
					irq_channel <= dati[14:12];
				end
				if (sel[2]) irq_core <= dati[21:16];
				if (sel[3]) irq_device <= dati[31:24];
			end
	 	default:
	 		;
	 	endcase
	end
end

// ----------------------------------------------------------------------------
// Baud rate control.
// ----------------------------------------------------------------------------

always_ff @(posedge clk_i)
	xClkSrc <= baudRateSel==5'd0;

wire [pCounterBits-1:0] bclkdiv;
uart6551BaudLUT #(.pClkFreq(pClkFreq), .pCounterBits(pCounterBits)) ublt1 (.a(baudRateSel), .o(bclkdiv));

reg [pCounterBits-1:0] clkdiv2;
always_ff @(posedge clk_i)
	clkdiv2 <= selCD ? clkdiv : bclkdiv;

always_ff @(posedge clk_i)
if (rst_i)
	c <= 24'd1;
else begin
	c <= c + 2'd1;
	if (c >= clkdiv2)
		c <= 2'd1;
end

// for detecting an edge on the baud clock
wire ibaud16 = c == 2'd1;

// Detect an edge on the external clock
wire xclkEdge;
edge_det ed1(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(xclks[1]), .pe(xclkEdge), .ne() );

// Detect an edge on the external clock
wire rxClkEdge;
edge_det ed2(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(RxCs[1]), .pe(rxClkEdge), .ne() );

always_comb
if (xClkSrc)		// 16x external clock (xclk)
	baud16 <= xclkEdge;
else
	baud16 <= ibaud16;

assign baud16rx = rxClkSrc ? baud16 : rxClkEdge;

//------------------------------------------------------------
// external signal synchronization
//------------------------------------------------------------

// External receiver clock
always_ff @(posedge clk_i)
	RxCs <= {RxCs[1:0],RxC_i};

// External baud clock
always_ff @(posedge clk_i)
	xclks <= {xclks[1:0],xclk_i};


always_ff @(posedge clk_i)
	ctsx <= {ctsx[0],llb?~rts_no:~cts_ni};

always_ff @(posedge clk_i)
	dcdx <= {dcdx[0],~dcd_ni};

always_ff @(posedge clk_i)
	dsrx <= {dsrx[0],llb?~dtr_no:~dsr_ni};

always_ff @(posedge clk_i)
	rix <= {rix[0],~ri_ni};

//------------------------------------------------------------
// state change detectors
//------------------------------------------------------------

wire ne_stat;
edge_det ued3 (
	.rst(rst_i),
	.clk(clk_i),
	.ce(1'b1),
	.i(cs_io && adr_h[4:2]==`UART_STAT && ~we && sel[2]),
	.pe(),
	.ne(ne_stat),
	.ee()
);

// detect a change on the dsr signal
always_ff @(posedge clk_i)
if (rst_i)
	deltaDsr <= 1'b0;
else begin
	if (ne_stat)
		deltaDsr <= 0;
	else if (~deltaDsr)
		deltaDsr <= dsrx[1] ^ dsrx[0];
end

// detect a change on the dcd signal
always_ff @(posedge clk_i)
if (rst_i)
	deltaDcd <= 1'b0;
else begin
	if (ne_stat)
		deltaDcd <= 0;
	else if (~deltaDcd)
		deltaDcd <= dcdx[1] ^ dcdx[0];
end

// detect a change on the cts signal
always_ff @(posedge clk_i)
if (rst_i)
	deltaCts <= 1'b0;
else begin
	if (ne_stat)
		deltaCts <= 0;
	else if (~deltaCts)
		deltaCts <= ctsx[1] ^ ctsx[0];
end

// detect a change on the ri signal
always_ff @(posedge clk_i)
if (rst_i)
	deltaRi <= 1'b0;
else begin
	if (ne_stat)
		deltaRi <= 0;
	else if (~deltaRi)
		deltaRi <= rix[1] ^ rix[0];
end

// detect a change in line status
reg [7:0] pLineStatusReg;
always_ff @(posedge clk_i)
	pLineStatusReg <= lineStatusReg;

assign lineStatusChange = pLineStatusReg != lineStatusReg;

//-----------------------------------------------------

// compute recieve timeout
always_comb
	rxToutMax <= (wordLength << 2) + 6'd12;

always_ff @(posedge clk_i)
if (rst_i)
	rxTout <= 1'b0;
else begin
	// read of receiver clears timeout counter
	if (rdrx)
		rxTout <= 1'b0;
	// Don't time out if the fifo is empty
	else if (rxCnt[9:4]==rxToutMax && ~rxEmpty)
		rxTout <= 1'b1;
end


//-----------------------------------------------------
// compute the 2x number of stop bits
always_comb
if (stopBit==1'b0)          // one stop bit
	stopBits <= 3'd2;
else if (wordLength==6'd8 && parityCtrl != 3'd0)
	stopBits <= 3'd2;
else if (wordLength==6'd5 && parityCtrl == 3'd0)	// 5 bits - 1 1/2 stop bit
	stopBits <= 3'd3;
else
	stopBits <= 3'd4;          // two stop bits


// compute frame size
// frame size is one less
assign frameSize = {wordLength + 4'd1 + stopBits[2:1] + parityCtrl[0], stopBits[0],3'b0} - 1;

//-----------------------------------------------------
// encode IRQ mailbox
always_comb
	irqenc <= 
		lineStatusChange ? 3'd0 :
		~rxDRQ_o ? 3'd1 :
		rxTout ? 3'd2 :
		~txDRQ_o ? 3'd3 :
		modemStatusChange ? 3'd4 :
		3'd0;

endmodule
