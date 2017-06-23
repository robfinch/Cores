`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
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
//
//	Verilog 1995
//
// ============================================================================
//
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
	input sclk,		        // serialization clock
	input clear,			// clear reciever
	input [3:0] rxd,		// external serial input
	output reg frame_err,		// framing error
	output reg overrun,			// receiver overrun
	// Fifo status
	output [5:0] fifocnt,
	output fifofull
);

	// variables
	reg [3:0] rxdd [0:3];	// synchronizer flops
	reg [8:0] cnt;			// sample bit rate counter
	reg [135:0] rx_data;		// working receive data register
	reg state;				// state machine
	reg wf;					// buffer write
	wire [127:0] dat;

wire cs = cyc_i & stb_i & cs_i;
reg rdy1,rdy2,rdy3;
always @(posedge clk_i)
    rdy1 <= cs;
always @(posedge clk_i)
    rdy2 <= rdy1 & cs;
always @(posedge clk_i)
    rdy3 <= rdy2 & cs;

assign ack_o = cs;// ? rdy3 : 1'b0;
assign dat_o = dat;

wire pecs;
edge_det u2 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs & ~we_i), .pe(pecs), .ne(), .ee() );

routerFifo2 u1
(
  .rst(rst_i),              // input wire srst
  .rd_clk(clk_i),            // input wire clk
  .wr_clk(sclk),
  .din(rx_data[131:4]),                // input wire [127 : 0] din
  .wr_en(wf),            // input wire wr_en
  .rd_en(pecs),            // input wire rd_en
  .dout(dat),              // output wire [127 : 0] dout
  .full(fifofull),         // output wire full
  .empty(),            // output wire empty
  .rd_data_count(fifocnt)  // output wire [4 : 0] data_count
);
/*
routerFifo u1
(
    .wrst(rst_i),
    .wclk(clk_i),
    .wr(wf),
    .di(rx_data[135:8]),
    .rrst(rst_i),
    .rclk(clk_i),
    .rd(necs),
    .dout(dat),
    .cnt(fifocnt)
);
*/
	// Three stage synchronizer to synchronize incoming data to
	// the local clock (avoids metastability).
	always @(posedge sclk) begin
	    rxdd[0] <= rxd;
	    rxdd[1] <= rxdd[0];
	    rxdd[2] <= rxdd[1];
	    rxdd[3] <= rxdd[2];
	end

	always @(posedge sclk) begin
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

			else begin

				case (state)

				// Sit in the idle state until a start bit is
				// detected.
				`IDLE:
					// look for start nybble
					if (rxdd[3]==4'h0)
						state <= `CNT;

				`CNT:
					begin
						// End of the frame ?
						// - check for framing error
						// - write data to read buffer
						if (cnt==9'h86)
							begin	
								frame_err <= rxdd[3] != 4'hF;
								if (fifocnt < 5'd31)
									wf <= 1'b1;
								else
									overrun <= 1'b1;
							end
						// Switch back to the idle state a little
						// bit too soon.
						if (cnt==9'h87)
							state <= `IDLE;
	
						// On start bit check make sure the start
						// bit is low, otherwise go back to the
						// idle state because it's a false start.
						if (cnt==9'h01 && (rxdd[3]!=4'h0))
							state <= `IDLE;

						if (cnt[1:0]==3'h1)
							rx_data <= {rxdd[3],rx_data[135:4]};
					end

				endcase
			end
		end
	end


	// bit rate counter
	always @(posedge sclk)
		begin
			if (state == `IDLE)
				cnt <= 9'd0;
			else
				cnt <= cnt + 9'd1;
		end

endmodule

