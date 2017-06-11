module routerTx (
	// WISHBONE SoC bus interface
	input rst_i,		// reset
	input clk_i,		// clock
	input cyc_i,		// cycle valid
	input stb_i,		// strobe
	output ack_o,		// transfer done
	input we_i,			// write transmitter
	input [255:0] dat_i,// data in
	//--------------------
	input cs_i,			// chip select
	input baud16x_ce,	// baud rate clock enable
	input cts,			// clear to send
	output txd,			// external serial output
	output reg empty	// buffer is empty
);

	reg [257:0] tx_data;	// transmit data working reg (raw)
	reg [255:0] fdo;	// data output
	reg [15:0] cnt;		// baud clock counter
	reg rd;

	assign ack_o = cyc_i & stb_i & cs_i;
	assign txd = tx_data[0];

	always @(posedge clk_i)
		if (ack_o & we_i) fdo <= dat_i;

	// set full / empty status
	always @(posedge clk_i)
		if (rst_i) empty <= 1;
		else begin
		if (ack_o & we_i) empty <= 0;
		else if (rd) empty <= 1;
		end


	always @(posedge clk_i)
		if (rst_i) begin
			cnt <= 16'h0000;
			rd <= 0;
			tx_data <= {258{1'b1}};
		end
		else begin

			rd <= 0;

			if (baud16x_ce) begin

				cnt <= cnt + 1;
				// Load next data ?
				if (cnt==16'h81F) begin
					cnt <= 0;
					if (!empty && cts) begin
						tx_data <= {1'b1,fdo,1'b0};
						rd <= 1;
					end
				end
				// Shift the data out. LSB first.
				else if (cnt[3:0]==4'hF)
					tx_data <= {1'b1,tx_data[255:1]};

			end
		end

endmodule
