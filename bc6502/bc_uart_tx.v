/* ===============================================================
	(C) 2002 Bird Computer
	All rights reserved.

	bc_uart_tx.v
		Please read the Licensing Agreement
	(license.html file). Use of this file is subject to the
	license agreement.

		Uart transmitter circuit with sixteen byte fifo. Fixed
	format 1 start - 8 data - 1 stop bits
	
	Ref: SpartanII -5
	90 MHz (optimized for speed)
	51 slices
	92 4-LUTs
=============================================================== */
`timescale 1ns / 1ns

`define IDLE	0
`define CNT		1
`define SHIFT	2

module bc_uart_tx(reset, clk, baud16x_ce, wr, clear, di, sout, full, empty);
	input reset;
	input clk;
	input baud16x_ce;	// baud rate clock enable
	input wr;			// write transmitter
	input clear;		// clear transmitter
	input [7:0] di;		// fifo data in
	output sout;		// external serial output
	output full;		// fifo is full
	output empty;		// fifo is empty

	reg [9:0] tx_data;	// transmit data working reg (raw)
	assign sout = tx_data[0];
	reg [1:0] state;	// state machine state
	reg [3:0] wa;		// fifo write address
	reg [3:0] ra;		// fifo read address
	reg [3:0] pra;		// previous fifo read address
	assign empty = wa==ra;
	assign full = wa==pra;
	wire [7:0] fdo;		// fifo data output
	reg [3:0] cnt;		// baud clock counter
	reg [3:0] bit_cnt;	// bit counter

	bc_fifo16x8 fifo0(.clk(clk), .wr(wr), .wa(wa), .ra(ra), .di(di), .do(fdo));

	always @(posedge clk) begin
		if (reset) begin
			state <= `IDLE;
			cnt <= 4'd15;
			bit_cnt <= 4'd0;
			ra <= 4'd0;
			wa <= 4'd0;
			pra <= 4'd15;
		end
		else begin

			// On a write, advance the fifo write address. If the
			// fifo is full we will overwrite chars.
			if (wr)
				wa <= wa + 1;

			if (clear) begin
				state <= `IDLE;
				cnt <= 4'd15;
				bit_cnt <= 4'd0;
				ra <= 4'd0;
				wa <= 4'd0;
				pra <= 4'd15;
			end

			if (baud16x_ce) begin

				cnt <= cnt + 1;

				case(state)
	
				// If we're in the idle state then look and see if
				// there are any characters in the fifo to be
				// transmitted.
				`IDLE:
					begin
						bit_cnt <= 4'd0;
						cnt <= 4'd0;
						if (!empty) begin
							tx_data <= {1'b1,fdo,1'b0};
							ra <= ra + 1;
							pra <= ra;
							state <= `CNT;
						end
					end

				// We simply sit in the count state until we've
				// counted enough baud clocks to be ready to shift.
				`CNT:
					begin
						if (cnt==4'd15)
							state <= `SHIFT;
					end

				// Shift the data out. LSB first.
				`SHIFT:
					begin
						tx_data <= {1'b1,tx_data[9:1]};
						bit_cnt <= bit_cnt + 1;
						if (bit_cnt==4'd9)
							state <= `IDLE;
						else
							state <= `CNT;
					end
	
				default:
					state <= `IDLE;
					
				endcase
			end
		end
	end

endmodule
