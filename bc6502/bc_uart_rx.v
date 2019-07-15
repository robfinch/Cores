/* ===============================================================
	(C) 2002 Bird Computer
	All rights reserved.

	bc_uart_rx.v
		Please read the Licensing Agreement
	(license.html file). Use of this file is subject to the
	license agreement.

		Uart receiver circuit with sixteen byte fifo. Fixed
	format 1 start - 8 data - 1 stop bits
	
	Ref: SpartanII -5
	100 MHz (optimized for speed)
	49 slices
	74 4-LUTs
=============================================================== */
`timescale 1ns / 1ns

`define IDLE	0
`define CNT		1
`define SAMPLE	2

module bc_uart_rx(reset, clk, baud16x_ce, rd, clear, do, sin,
	data_present, full, frame_err, over_run);
	input reset;
	input clk;
	input baud16x_ce;		// baud rate clock enable
	input rd;				// read reciever
	input clear;			// clear reciever
	output [7:0] do;		// fifo data out
	input sin;				// external serial input
	output data_present;	// data present in fifo
	output full;			// receive fifo full
	output frame_err;		// framing error
	output over_run;		// receiver overrun

	reg frame_err;
	reg over_run;
	reg chk_start, chk_stop;
	reg [3:0] sind;			// synchronizer flops
	reg [3:0] cnt;			// sample bit rate counter
	reg [3:0] bit_cnt;		// data bit counter
	reg [7:0] rx_data;		// working receive data register
	reg [1:0] state;		// state machine
	reg wf;			// fifo write
	reg [3:0] wa;	// fifo write address
	reg [3:0] ra;	// fifo read address
	reg [3:0] pra;	// fifo previous read address
	wire data_present = wa!=ra;
	assign full = wa==pra;

	bc_fifo16x8 fifo0(.clk(clk), .wr(wf), .wa(wa), .ra(ra), .di(rx_data), .do(do));

	// Three stage synchronizer to synchronize incoming data to
	// the local clock (avoids metastability).
	always @(posedge clk) begin
		sind <= {sind[2:0],sin};
	end

	always @(posedge clk) begin
		if (reset) begin
			chk_start <= 1'b0;
			chk_stop <= 1'b0;
			state <= `IDLE;
			cnt <= 4'd8;
			bit_cnt <= 4'd0;
			wf <= 1'b0;
			ra <= 4'd0;
			wa <= 4'd0;
			pra <= 4'd15;
			over_run <= 1'b0;
		end
		else begin

			// fifo read - increment read address
			if (rd & data_present) begin
				ra <= ra + 1;
				pra <= ra;
			end

			// If we wrote the fifo this clock, then increment
			// write address.
			if (wf) begin
				wf <= 1'b0;
				wa <= wa + 1;
			end

			if (clear) begin
				ra <= 4'd0;
				wa <= 4'd0;
				wf <= 1'b0;
				pra <= 4'd15;
				chk_start <= 1'b0;
				chk_stop <= 1'b0;
				state <= `IDLE;
				cnt <= 4'd8;
				bit_cnt <= 4'd0;
				over_run <= 1'b0;
			end

			else if (baud16x_ce) begin

				cnt <= cnt + 1;

				case (state)

				// Sit in the idle state until a start bit is
				// detected. Once a start bit is detected, we load
				// the sample counter with eight so it takes only
				// eight more cycles to get to the centre of the
				// start bit. We also make sure the data bit count
				// is reset to zero, and switch to the count state.
				`IDLE:
					begin
						// look for start bit
						if (~sind[3]) begin
							cnt <= 4'd8;
							chk_start <= 1'b1;
							bit_cnt <= 4'd0;
							state <= `CNT;
						end
					end

				// The only place we can go from the count state
				// is to the sample state, and this only happens
				// once we've counted sixteen baud clocks.
				// Otherwise we just count merrily away.
				`CNT:
					begin
						if (cnt==4'd0)
							state <= `SAMPLE;
					end

				// This is where all the fun is.
				`SAMPLE:
					begin
						// On start bit check make sure the start
						// bit is low, otherwise go back to the
						// idle state because it's a false start.
						// If it's not a false start then we're
						// ready to read real bits, so go back to
						// the count stage until the next sample
						// point is reached.
						case (1'b1)	// synopsys full_case parallel_case
						chk_start:
							begin
								chk_start <= 1'b0;
								state <= sind[3] ? `IDLE : `CNT;
							end
						// If we've reached the point where we're
						// checking for a stop bit, then copy the
						// working data register to the fifo (if
						// possible). If we don't have a stop bit
						// here, then it's a framing error. If the
						// fifo is full, then it's an overrun
						// error. In any case, go back to the idle
						// state.
						chk_stop:
							begin
								chk_stop <= 1'b0;
								frame_err <= ~sind[3];
								if (!full)
									wf <= 1'b1;
								else
									over_run <= 1'b1;
								state <= `IDLE;
							end
						// We're not checking for start or stop
						// bits so we must be sampling a data bit.
						// After eight bits start looking for the
						// stop bit. Go back to the count state
						// until the next sample point.
						// *Data is recieved LSB first.
						default:
							begin
								rx_data <= {sind[3],rx_data[7:1]};
								bit_cnt <= bit_cnt + 1;
								if (bit_cnt==4'd7)
									chk_stop <= 1'b1;
								state <= `CNT;
							end
						endcase
					end

				default:
					state <= `IDLE;
					
				endcase
			end
		end
	end

endmodule

