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
	input sclk,	       // serializing clock
	input cts,			// clear to send
	output [2:0] txd,       // external serial output
	output reg empty	// buffer is empty
);
    reg txing;
	reg [134:0] tx_data;	// transmit data working reg (raw)
	reg [127:0] fdo;	// data output
	reg [11:0] cnt;		// baud clock counter
	reg rd;

	assign ack_o = cyc_i & stb_i & cs_i;
	assign txd = tx_data[2:0];

wire pe_ack;
edge_det u1 (.rst(rst_i), .clk(sclk), .ce(1'b1), .i(ack_o & we_i), .pe(pe_ack), .ne(), .ee() );

	always @(posedge sclk)
		if (rst_i) begin
		    txing <= 1'b0;
		    empty <= 1'b1;
			cnt <= 12'h000;
			rd <= 1'b0;
			tx_data <= {160{1'b1}};
		end
		else begin
    		if (pe_ack)
    		  fdo <= dat_i;
    		if (pe_ack)
    		  empty <= 1'b0;
    		else if (rd)
    		  empty <= 1'b1;

			rd <= 1'b0;

            cnt <= cnt + 9'd1;
            if (cnt==12'hB3)
                txing <= 1'b0;
            // Load next data ?
            if (cnt==12'hB3 || !txing) begin
                cnt <= 12'd0;
                if (!empty && cts) begin
                    txing <= 1'b1;
                    tx_data <= {4'hF,fdo,3'd0};
                    /*
                    tx_data <= {1'b1,fdo[127:120],1'b0,
                                1'b1,fdo[119:112],1'b0,
                                1'b1,fdo[111:104],1'b0,
                                1'b1,fdo[103:96],1'b0,
                                1'b1,fdo[95:88],1'b0,
                                1'b1,fdo[87:80],1'b0,
                                1'b1,fdo[79:72],1'b0,
                                1'b1,fdo[71:64],1'b0,
                                1'b1,fdo[63:56],1'b0,
                                1'b1,fdo[55:48],1'b0,
                                1'b1,fdo[47:40],1'b0,
                                1'b1,fdo[39:32],1'b0,
                                1'b1,fdo[31:24],1'b0,
                                1'b1,fdo[23:16],1'b0,
                                1'b1,fdo[15:8],1'b0,
                                1'b1,fdo[7:0],1'b0
                                };
                    */
                    rd <= 1'b1;
                end
            end
            // Shift the data out. LSB first.
            else if (cnt[1:0]==2'h3)
                tx_data <= {3'h7,tx_data[134:3]};

		end

endmodule
