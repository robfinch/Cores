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

module routerRxBsZ(
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
	input sclk,		      // serializing clock
	input clear,			// clear reciever
	input [2:0] rxd,		       // external serial input
	output reg frame_err,		// framing error
	output reg overrun,			// receiver overrun
	// Fifo status
	output [5:0] fifocnt,
	output fifofull
);

// variables
reg [2:0] rxdd [0:3];	// synchronizer flops
reg [11:0] cnt;			// sample bit rate counter
reg [134:0] rx_data;	// working receive data register
wire [127:0] rx_data1;
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
  .rd_clk(clk_i),              // input wire clk
  .wr_clk(sclk),
  .rst(rst_i),              // input wire srst
  .din(rx_data1),                // input wire [127 : 0] din
  .wr_en(wf),            // input wire wr_en
  .rd_en(pecs),            // input wire rd_en
  .dout(dat),              // output wire [127 : 0] dout
  .full(fifofull),         // output wire full
  .empty(),            // output wire empty
  .rd_data_count(fifocnt)  // output wire [4 : 0] data_count
);
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
					if (rxdd[3]==3'h0)
						state <= `CNT;

				`CNT:
					begin
						// End of the frame ?
						// - check for framing error
						// - write data to read buffer
						if (cnt==12'hB2)
							begin	
								frame_err <= rxdd[3] != 3'h7;
								if (fifocnt < 5'd31)
									wf <= 1'b1;
								else
									overrun <= 1'b1;
							end
						// Switch back to the idle state a little
						// bit too soon.
						if (cnt==12'hB3)
							state <= `IDLE;
	
						// On start bit check make sure the start
						// bit is low, otherwise go back to the
						// idle state because it's a false start.
						if (cnt==12'h01 && (rxdd[3]!=1'h0))
							state <= `IDLE;

						if (cnt[1:0]==3'h1)
							rx_data <= {rxdd[3],rx_data[134:3]};
					end

				endcase
			end
		end
	end


	// bit rate counter
	always @(posedge sclk)
		begin
			if (state == `IDLE)
				cnt <= 12'd0;
			else
				cnt <= cnt + 12'd1;
		end
assign rx_data1 = rx_data[130:3];

/*
assign rx_data1 = {
    rx_data[158:151],
    rx_data[148:141],
    rx_data[138:131],
    rx_data[128:121],
    rx_data[118:111],
    rx_data[108:101],
    rx_data[98:91],
    rx_data[88:81],
    rx_data[78:71],
    rx_data[68:61],
    rx_data[58:51],
    rx_data[48:41],
    rx_data[38:31],
    rx_data[28:21],
    rx_data[18:11],
    rx_data[8:1]
    };
*/
endmodule

