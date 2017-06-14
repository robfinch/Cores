`define IDLE	0
`define CNT		1

module routerRxBs(
	// WISHBONE SoC bus interface
	input rst_i,			// reset
	input clk_i,			// clock
	input cyc_i,			// cycle is valid
	input stb_i,			// strobe
	output ack_o,			// data is ready
	input we_i,				// write (this signal is used to qualify reads)
	output [127:0] dat_o,		// data out
	//------------------------
	input cs_i,				// chip select
	input baud_ce,		   // baud rate clock enable
	input clear,			// clear reciever
	input [7:0] rxd,		// external serial input
	output data_present,	// data present in fifo
	output reg frame_err,		// framing error
	output reg overrun			// receiver overrun
);

	// variables
	reg [7:0] rxdd [0:3];	// synchronizer flops
	reg [7:0] cnt;			// sample bit rate counter
	reg [143:0] rx_data;		// working receive data register
	reg state;				// state machine
	reg wf;					// buffer write
	wire [127:0] dat;

wire cs = cyc_i & stb_i & cs_i;
reg rdy1;
always @(posedge clk_i)
    rdy1 <= cs;

assign ack_o = cs ? rdy1 : 1'b0;
assign dat_o = ack_o ? dat : 128'b0;

wire pecs;
edge_det u2 (.rst(rst), .clk(clk), .ce(1'b1), .i(cs & ~we_i), .pe(pecs), .ne(), .ee() );

wire empty;
wire [6:0] data_count;

routerFifo u1 (
  .clk(clk_i),
  .srst(rst_i),
  .din(rx_data[135:8]),
  .wr_en(wf),
  .rd_en(pecs),
  .dout(dat),
  .full(),
  .almost_full(),
  .empty(empty),
  .almost_empty()
);

assign data_present = !empty;

	// Three stage synchronizer to synchronize incoming data to
	// the local clock (avoids metastability).
	always @(posedge clk_i) begin
	    rxdd[0] <= rxd;
	    rxdd[1] <= rxdd[0];
	    rxdd[2] <= rxdd[1];
	    rxdd[3] <= rxdd[2];
	end

	always @(posedge clk_i) begin
		if (rst_i) begin
			state <= `IDLE;
			wf <= 1'b0;
			overrun <= 1'b0;
		end
		else begin

			// Clear write flag
			wf <= 1'b0;

			if (clear) begin
				wf <= 1'b0;
				state <= `IDLE;
				overrun <= 1'b0;
			end

			else if (baud_ce) begin

				case (state)

				// Sit in the idle state until a start bit is
				// detected.
				`IDLE:
					// look for start byte
					if (rxdd[3]==8'h00)
						state <= `CNT;

				`CNT:
					begin
						// End of the frame ?
						// - check for framing error
						// - write data to read buffer
						if (cnt==8'h8C)
							begin	
								frame_err <= rxdd[3] != 8'hFF;
								if (!data_present)
									wf <= 1'b1;
								else
									overrun <= 1'b1;
							end
						// Switch back to the idle state a little
						// bit too soon.
						if (cnt==8'h8E)
							state <= `IDLE;
	
						// On start bit check make sure the start
						// bit is low, otherwise go back to the
						// idle state because it's a false start.
						if (cnt==8'h03 && (rxdd[3]!=8'h00))
							state <= `IDLE;

						if (cnt[2:0]==3'h3)
							rx_data <= {rxdd[3],rx_data[143:8]};
					end

				endcase
			end
		end
	end


	// bit rate counter
	always @(posedge clk_i)
		if (baud_ce) begin
			if (state == `IDLE)
				cnt <= 0;
			else
				cnt <= cnt + 1;
		end

endmodule

