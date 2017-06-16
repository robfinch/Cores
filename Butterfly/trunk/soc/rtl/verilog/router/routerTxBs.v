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
	output [4:0] txd,	// external serial output
	output reg empty	// buffer is empty
);
    reg txing;
	reg [143:0] tx_data;	// transmit data working reg (raw)
	reg [127:0] fdo;	// data output
	reg [8:0] cnt;		// baud clock counter
	reg rd;

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

	assign ack_o = cyc_i & stb_i & cs_i;
	assign txd = fnGCR(tx_data[3:0]);

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
				if (cnt==9'h8F)
				    txing <= 1'b0;
				// Load next data ?
				if (cnt==9'h8F || !txing) begin
					cnt <= 9'd0;
					if (!empty && cts) begin
					    txing <= 1'b1;
						tx_data <= {8'hFF,fdo,8'h00};
						rd <= 1'b1;
					end
				end
				// Shift the data out. LSB first.
				else if (cnt[1:0]==2'h3)
					tx_data <= {8'hFF,tx_data[143:4]};

			end
		end

endmodule
