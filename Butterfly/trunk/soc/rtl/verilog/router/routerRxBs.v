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
	input baud_ce,		   // baud rate clock enable
	input clear,			// clear reciever
	input [4:0] rxd,		// external serial input
	output reg frame_err,		// framing error
	output reg overrun,			// receiver overrun
	// Fifo status
	output [4:0] fifocnt
);

	// variables
	reg [4:0] rxdd [0:3];	// synchronizer flops
	reg [8:0] cnt;			// sample bit rate counter
	reg [143:0] rx_data;		// working receive data register
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

assign ack_o = cs ? rdy3 : 1'b0;
assign dat_o = dat;

function [3:0] fnBin;
input [4:0] gcr;
case(gcr)
5'h0A:  fnBin = 4'h0;
5'h0B:  fnBin = 4'h1;
5'h12:  fnBin = 4'h2;
5'h13:  fnBin = 4'h3;
5'h0E:  fnBin = 4'h4;
5'h0F:  fnBin = 4'h5;
5'h16:  fnBin = 4'h6;
5'h17:  fnBin = 4'h7;
5'h09:  fnBin = 4'h8;
5'h19:  fnBin = 4'h9;
5'h1A:  fnBin = 4'hA;
5'h1B:  fnBin = 4'hB;
5'h0D:  fnBin = 4'hC;
5'h1D:  fnBin = 4'hD;
5'h1E:  fnBin = 4'hE;
5'h15:  fnBin = 4'hF;
default:    fnBin = 4'h0; 
endcase
endfunction

function [4:0] fnGCR;
input [3:0] bin;
case(bin)
4'h0:   fnGCR = 5'h0A;
4'h1:   fnGCR = 5'h0B;
4'h2:   fnGCR = 5'h12;
4'h3:   fnGCR = 5'h13;
4'h4:   fnGCR = 5'h0E;
4'h5:   fnGCR = 5'h0F;
4'h6:   fnGCR = 5'h16;
4'h7:   fnGCR = 5'h17;
4'h8:   fnGCR = 5'h09;
4'h9:   fnGCR = 5'h19;
4'hA:   fnGCR = 5'h1A;
4'hB:   fnGCR = 5'h1B;
4'hC:   fnGCR = 5'h0D;
4'hD:   fnGCR = 5'h1D;
4'hE:   fnGCR = 5'h1E;
4'hF:   fnGCR = 5'h15;
endcase
endfunction

wire pecs;
edge_det u2 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs & ~we_i), .pe(pecs), .ne(), .ee() );

routerFifo2 u1
(
  .clk(clk_i),              // input wire clk
  .srst(rst_i),              // input wire srst
  .din(rx_data[135:8]),                // input wire [127 : 0] din
  .wr_en(wf),            // input wire wr_en
  .rd_en(pecs),            // input wire rd_en
  .dout(dat),              // output wire [127 : 0] dout
  .full(),              // output wire full
  .empty(),            // output wire empty
  .data_count(fifocnt)  // output wire [4 : 0] data_count
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
					// look for start nybble
					if (rxdd[3]==5'h0A)
						state <= `CNT;

				`CNT:
					begin
						// End of the frame ?
						// - check for framing error
						// - write data to read buffer
						if (cnt==9'h8E)
							begin	
								frame_err <= rxdd[3] != 5'h15;
								if (fifocnt < 5'd31)
									wf <= 1'b1;
								else
									overrun <= 1'b1;
							end
						// Switch back to the idle state a little
						// bit too soon.
						if (cnt==9'h8F)
							state <= `IDLE;
	
						// On start bit check make sure the start
						// bit is low, otherwise go back to the
						// idle state because it's a false start.
						if (cnt==9'h01 && (rxdd[3]!=5'h0A))
							state <= `IDLE;

						if (cnt[1:0]==3'h1)
							rx_data <= {fnBin(rxdd[3]),rx_data[143:4]};
					end

				endcase
			end
		end
	end


	// bit rate counter
	always @(posedge clk_i)
		if (baud_ce) begin
			if (state == `IDLE)
				cnt <= 9'd0;
			else
				cnt <= cnt + 9'd1;
		end

endmodule

