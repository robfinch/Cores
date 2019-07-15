/* ===============================================================
	(C) 2002 Bird Computer
	All rights reserved.

	bc_uart.v

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	reg
	0	transmit / receive buffer
		write 	- write to transmit buffer
		read	- read from receive buffer
	1	status (read only)
		bit 7 = interrupt
		bit 6 = received data present (check before reading)
		bit 5 = receive buffer full
		bit 4 = transmit buffer empty
		bit 3 = transmit buffer full
		bit 0 = cts (clear to send)
	2	control
		bit 6 = receive data present - interrupt enable
		bit 5 = receive buffer full - interrupt enable
		bit 4 = transmit buffer empty - interrupt enable
		bit 1 = rts (request to send)
	3	reset / err
		a write to this register resets the transmitter/receiver
		a read reads the error status
		bit 7 = receiver overrun
		bit 6 = receive char framing error
	4	clock multiplier high
	5	clock multiplier low
		* Clock multiplier steps the 16xbaud clock frequency
		in increments of 1/65536 of the clk input using a
		harmonic frequency synthesizer
		eg. to get a 9600 baud 16x clock (153.6 kHz) with a
		27.175 MHz clock input,
		153600 = 400 * (27.175MHz / 65536)
		115200 baud = 4798 * (27.175 MHz / 65536)
		Higher frequency baud rates will exhibit more jitter
		on the 16x clock, but this will mostly be masked by the 
		16x clock factor.

	Ref. SpartanII -5
	142 slices	217 4-LUTs  89 MHz
=============================================================== */
module bc_uart(reset, clk, ce, cs, rd, wr, a, di, do, irq,
	cts, rts, sin, sout);
	input reset;
	input clk;		// eg 100.7MHz
	input ce;		// eg 25.175MHz enable
	input cs;		// circuit select
	input rd;		// 1 = read
	input wr;		// 1 = write
	input [2:0] a;	// register address
	input [7:0] di;	// data input bus
	output [7:0] do;	// data output bus
	reg [7:0] do;
	output irq;		// interrupt request
	input cts;		// clear to send (flow control)
	output rts;		// request to send (flow control)
	reg rts;
	input sin;		// serial data in
	output sout;	// serial data out

	reg [15:0] c;	// current count
	reg pcmsb;		// previous value of count msb
	reg [15:0] ck_mul;	// baud rate clock multiplier
	wire data_present;
	wire rx_full, tx_empty, tx_full;
	wire [7:0] dout;
	wire baud16 = c[15] & ~pcmsb;	// edge detector (active one cycle only!)
	reg cts1;		// cts sampling
	reg rx_full_ie;		// interrupt enable flags
	reg rx_present_ie;
	reg tx_empty_ie;
	wire clear = wr && a==3'd3 && ce && cs;
	wire frame_err;		// receiver char framing error
	wire over_run;		// receiver over run

	assign irq = (rx_full & rx_full_ie) |
		(data_present & rx_present_ie) |
		(tx_empty & tx_empty_ie);

	wire [7:0] rx_do;
	bc_uart_rx uart_rx0(.reset(reset), .clk(clk), .baud16x_ce(baud16),
		.rd(rd & cs & a[2:0]==3'b000 & ce), .clear(clear), .do(rx_do),
		.sin(sin), .data_present(data_present), .full(rx_full),
		.frame_err(frame_err), .over_run(over_run) );

	bc_uart_tx uart_tx0(.reset(reset), .clk(clk),. baud16x_ce(baud16),
		.wr(wr & cs & a[2:0]==3'b000 & ce), .clear(clear), .di(di),
		.sout(sout), .full(tx_full), .empty(tx_empty) );

	// mux the reg outputs
	always @(a or rx_do or irq or data_present or rx_full or tx_full
		or tx_empty or rx_present_ie or rx_full_ie or tx_empty_ie
		or cts1 or rts or ck_mul or over_run or frame_err) begin
		case(a)
		3'd0:	do <= rx_do;
		3'd1:	do <= {irq, data_present, rx_full, tx_empty, tx_full,2'b0,cts1};
		3'd2:	do <= {1'b0, rx_present_ie, rx_full_ie, tx_empty_ie, 2'b0, rts, 1'b0};
		3'd3:	do <= {over_run, frame_err, 6'b0};
		3'd4:	do <= ck_mul[15:0];
		3'd5:	do <= ck_mul[7:0];
		3'd6,3'd7: do <= 8'b0;
		endcase
	end

	// Note: baud clock should pulse high for only a single
	// cycle!
	always @(posedge clk) begin
		if (reset) begin
			c <= 16'd0;
			pcmsb <= 1'b0;
		end
		else begin
			c <= c + ck_mul;
			// for detecting an edge on the msb
			pcmsb <= c[15];
			cts1 <= cts;
		end
	end

	// register updates
	always @(posedge clk) begin
		if (reset) begin
			rts <= 1'b0;
			rx_present_ie <= 1'b0;
			rx_full_ie <= 1'b0;
			tx_empty_ie <= 1'b0;
			// 19200 baud=800 with 25 MHZ clock
			// 19200 baud=1007 with 20 MHZ clock
			ck_mul <= 16'd1007;
		end
		else begin
			if (ce & wr & cs) begin
				case (a)
				3'd2:	begin
						rx_present_ie <= di[6];
						rx_full_ie <= di[5];
						tx_empty_ie <= di[4];
						rts <= di[1];
						end
			 	3'd4:	ck_mul[15:8] <= di;
			 	3'd5:	ck_mul[7:0] <= di;
			 	default:
			 		;
			 	endcase
			end
		end
	end

endmodule

