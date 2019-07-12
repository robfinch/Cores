// ============================================================================
//        __
//   \\__/ o\    (C) 2005-2019  Robert Finch, Waterloo
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
`define UART_TRB 		2'd0    // transmit/receive buffer
`define UART_STAT		2'd1
`define UART_CMD		2'd2
`define UART_CTRL		2'd3

module uart6551(rst_i, clk_i, cs_i, irq_o,
	cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o,
	cts_ni, rts_no, dsr_ni, dcd_ni, dtr_no, ri_ni,
	rxd_i, txd_o, data_present,
	rxDRQ_o, txDRQ_o,
	xclk_i, RxC_i
);
parameter pCounterBits = 24;
parameter pFifoSize = 1024;
parameter pClkDiv = 24'd1302;	// 9.6k baud, 200.000MHz clock
parameter HIGH = 1'b1;
parameter LOW = 1'b0;
input rst_i;
input clk_i;			// eg 50.000MHz
input cs_i;		// circuit select
// WISHBONE -------------------------------
input cyc_i;		// bus cycle valid
input stb_i;
output ack_o;
input we_i;			// 1 = write
input [3:0] sel_i;
input [3:2] adr_i;	// register address
input [31:0] dat_i;	// data input bus
output reg [31:0] dat_o;	// data output bus
//------------------------------------------
output reg irq_o;		// interrupt request
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
wire [11:0] rxCnt;	// reciever counter value
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
reg fifoEnable;
wire [3:0] rxQued;
wire [3:0] txQued;

// test
wire txd1;

assign data_present = ~rxEmpty;

assign rxITrig = rxQued >= rxThres;
assign txITrig = txQued <= txThres;
wire rxDRQ1 = (fifoEnable ? rxITrig : ~rxEmpty);
wire txDRQ1 = (fifoEnable ? txITrig : txEmpty);
assign rxDRQ = dmaEnable & rxDRQ1;
assign txDRQ = dmaEnable & txDRQ1;
wire rxIRQ = rxIe & rxDRQ1;
wire txIRQ = txIe & txDRQ1;

reg [7:0] cmd0, cmd1, cmd2, cmd3;
reg [7:0] ctrl0, ctrl1, ctrl2, ctrl3;

always @(posedge clk_i)
	irq_o <= 
	  rxIRQ
	| txIRQ
	| (rxTout & rxToutIe)
	| (lineStatusChange & lineStatusChangeIe)
	| (modemStatusChange & modemStatusChangeIe)
	;

// Hold onto address and data an extra cycle.
// The extra cycle updates or reads the serial transmit / receive.
reg [31:0] dati;
always @(posedge clk_i)
	dati <= dat_i;
reg [3:2] adr_h;
always @(posedge clk_i)
	adr_h <= adr_i;
reg we;
always @(posedge clk_i)
	we <= we_i;
reg [3:0] sel;
always @(posedge clk_i)
	sel <= sel_i;

wire [7:0] rx_do;
wire rdrx = ack_o && adr_h==`UART_TRB && ~we && !accessCD;
wire txrx = ack_o && adr_h==`UART_TRB && !accessCD;

wire cs = cs_i & cyc_i & stb_i;

ack_gen #(
	.READ_STAGES(1),
	.WRITE_STAGES(0),
	.REGISTER_OUTPUT(1)
) uag1
(
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(cs),
	.we_i(cs & we_i),
	.o(ack_o)
);

uart6551Rx uart_rx0
(
	.rst(rst_i),
	.clk(clk_i),
	.cyc(cyc_i),
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
	.cyc(cyc_i),
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
	.clear(clear),
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
always @(posedge clk_i)
begin
	case(adr_i)
	`UART_TRB:	dat_o <= accessCD ? {8'h0,clkdiv} : {24'h0,rx_do};	// receiver holding register
	`UART_STAT:	dat_o <= {irqStatusReg,modemStatusReg,lineStatusReg,irq_o,dsrx[1],dcdx[1],fifoEnable ? ~txFull : txEmpty,~rxEmpty,overrun,frameErr,parityErr};
	`UART_CMD:	dat_o <= {cmd3,cmd2,cmd1,cmd0};
	`UART_CTRL:	dat_o <= {ctrl3,ctrl2,ctrl1,ctrl0};
	endcase
end


// register updates
always @(posedge clk_i)
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
	fifoEnable	<= 1'b1;
	// Test
	llb			<= 1'b0;
	selCD		<= 1'b0;
	accessCD   <= 1'b0;
end
else begin

	//llb <= 1'b1;
	rxFifoClear <= 1'b0;
	txFifoClear <= 1'b0;
	ctrl2[1] <= 1'b0;
	ctrl2[2] <= 1'b0;

	if (ack_o & we) begin
		case (adr_h)	// synopsys full_case parallel_case

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
      		selCD <= dati[30];
      		accessCD <= dati[31];
      	end
      end

	 	default:
	 		;
	 	endcase
	end
end

// ----------------------------------------------------------------------------
// Baud rate control.
// ----------------------------------------------------------------------------

always @(posedge clk_i)
	xClkSrc <= baudRateSel==5'd0;

wire [pCounterBits-1:0] bclkdiv;
uart6551BaudLUT #(pCounterBits) ublt1 (.a(baudRateSel), .o(bclkdiv));

reg [pCounterBits-1:0] clkdiv2;
always @(posedge clk_i)
	clkdiv2 <= selCD ? clkdiv : bclkdiv;

always @(posedge clk_i)
if (rst_i)
	c <= 1'd1;
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

always @(xClkSrc or xclkEdge or ibaud16)
if (xClkSrc)		// 16x external clock (xclk)
	baud16 <= xclkEdge;
else
	baud16 <= ibaud16;

assign baud16rx = rxClkSrc ? baud16 : rxClkEdge;

//------------------------------------------------------------
// external signal synchronization
//------------------------------------------------------------

// External receiver clock
always @(posedge clk_i)
	RxCs <= {RxCs[1:0],RxC_i};

// External baud clock
always @(posedge clk_i)
	xclks <= {xclks[1:0],xclk_i};


always @(posedge clk_i)
	ctsx <= {ctsx[0],llb?~rts_no:~cts_ni};

always @(posedge clk_i)
	dcdx <= {dcdx[0],~dcd_ni};

always @(posedge clk_i)
	dsrx <= {dsrx[0],llb?~dtr_no:~dsr_ni};

always @(posedge clk_i)
	rix <= {rix[0],~ri_ni};

//------------------------------------------------------------
// state change detectors
//------------------------------------------------------------

wire ne_stat;
edge_det ued3 (
	.rst(rst_i),
	.clk(clk_i),
	.ce(1'b1),
	.i(ack_o && adr_i==`UART_STAT && ~we_i && sel_i[2]),
	.pe(),
	.ne(ne_stat),
	.ee()
);

// detect a change on the dsr signal
always @(posedge clk_i)
if (rst_i)
	deltaDsr <= 1'b0;
else begin
	if (ne_stat)
		deltaDsr <= 0;
	else if (~deltaDsr)
		deltaDsr <= dsrx[1] ^ dsrx[0];
end

// detect a change on the dcd signal
always @(posedge clk_i)
if (rst_i)
	deltaDcd <= 1'b0;
else begin
	if (ne_stat)
		deltaDcd <= 0;
	else if (~deltaDcd)
		deltaDcd <= dcdx[1] ^ dcdx[0];
end

// detect a change on the cts signal
always @(posedge clk_i)
if (rst_i)
	deltaCts <= 1'b0;
else begin
	if (ne_stat)
		deltaCts <= 0;
	else if (~deltaCts)
		deltaCts <= ctsx[1] ^ ctsx[0];
end

// detect a change on the ri signal
always @(posedge clk_i)
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
always @(posedge clk_i)
	pLineStatusReg <= lineStatusReg;

assign lineStatusChange = pLineStatusReg != lineStatusReg;

//-----------------------------------------------------

// compute recieve timeout
always @(wordLength)
	rxToutMax <= (wordLength << 2) + 6'd12;

always @(posedge clk_i)
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
always @*
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
always @(rxDRQ or rxTout or txDRQ or lineStatusChange or modemStatusChange)
	irqenc <= 
		lineStatusChange ? 3'd0 :
		~rxDRQ ? 3'd1 :
		rxTout ? 3'd2 :
		~txDRQ ? 3'd3 :
		modemStatusChange ? 3'd4 :
		3'd0;

endmodule
