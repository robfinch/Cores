// Byte serial transmitter
module routerTxBs (
	// WISHBONE SoC bus interface
	input rst_i,		// reset
	input clk_i,		// clock
	input cyc_i,		// cycle valid
	input stb_i,		// strobe
	output ack_o,		// transfer done
	input we_i,			// write transmitter
	input [127:0] dat_i,// data in
	//--------------------
	input cs_i,			// chip select
	input baud_ce,	    // baud rate clock enable
	input cts,			// clear to send
	output [7:0] txd,	// external serial output
	output reg empty	// buffer is empty
);
    reg txing;
	reg [143:0] tx_data;	// transmit data working reg (raw)
	reg [127:0] fdo;	// data output
	reg [7:0] cnt;		// baud clock counter
	reg rd;

	assign ack_o = cyc_i & stb_i & cs_i;
	assign txd = tx_data[7:0];

	always @(posedge clk_i)
		if (rst_i) begin
		    txing <= 1'b0;
		    empty <= 1'b1;
			cnt <= 8'h00;
			rd <= 1'b0;
			tx_data <= {144{1'b1}};
		end
		else begin
    		if (ack_o & we_i)
    		  fdo <= dat_i;
    		if (ack_o & we_i)
    		  empty <= 1'b0;
    		else if (rd)
    		  empty <= 1'b1;

			rd <= 1'b0;

			if (baud_ce) begin

				cnt <= cnt + 8'd1;
				if (cnt==8'h8F)
				    txing <= 1'b0;
				// Load next data ?
				if (cnt==8'h8F || !txing) begin
					cnt <= 8'd0;
					if (!empty && cts) begin
					    txing <= 1'b1;
						tx_data <= {8'hFF,fdo,8'h00};
						rd <= 1'b1;
					end
				end
				// Shift the data out. LSB first.
				else if (cnt[2:0]==3'h7)
					tx_data <= {8'hFF,tx_data[143:8]};

			end
		end

endmodule
