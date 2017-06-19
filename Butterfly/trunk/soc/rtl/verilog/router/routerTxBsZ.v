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
// Byte serial transmitter
module routerTxBsZ (
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
	output [2:0] txd,	// external serial output
	output reg empty	// buffer is empty
);
    reg txing;
	reg [143:0] tx_data;	// transmit data working reg (raw)
	reg [127:0] fdo;	// data output
	reg [8:0] cnt;		// baud clock counter
	reg rd;

	assign ack_o = cyc_i & stb_i & cs_i;
	assign txd = tx_data[2:0];

	always @(posedge clk_i)
		if (rst_i) begin
		    txing <= 1'b0;
		    empty <= 1'b1;
			cnt <= 9'h00;
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

				cnt <= cnt + 9'd1;
				if (cnt==9'hBF)
				    txing <= 1'b0;
				// Load next data ?
				if (cnt==9'hBF || !txing) begin
					cnt <= 9'd0;
					if (!empty && cts) begin
					    txing <= 1'b1;
						tx_data <= {8'hFF,fdo,8'h00};
						rd <= 1'b1;
					end
				end
				// Shift the data out. LSB first.
				else if (cnt[1:0]==2'h3)
					tx_data <= {3'd7,tx_data[143:3]};

			end
		end

endmodule
