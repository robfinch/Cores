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
module routerTxNsyn (rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, dat_i,
    sclk, cts, txd, sync, empty
);
parameter pBitsParallel = 4;
parameter p2 = 4;
localparam pCount =
    pBitsParallel==8 ? 8'd15 : 
    pBitsParallel==4 ? 8'd31 :
    pBitsParallel==3 ? 8'd42 :
    8'd63; // 2
// WISHBONE SoC bus interface
input rst_i;        // reset
input clk_i;        // clock
input cs_i;         // circuit select
input cyc_i;        // cycle valid
input stb_i;        // strobe
output ack_o;        // transfer done
input we_i;            // write transmitter
input [127:0] dat_i;// data in
//--------------------
input sclk;           // serializing clock
input cts;            // clear to send
output [pBitsParallel-1:0] txd;    // external serial output
output reg sync;
output reg empty;    // buffer is empty

reg [4:0] ackwe;
reg txing;
reg [127:0] tx_data;	// transmit data working reg (raw)
reg [127:0] fdo;	// data output
reg [7:0] cnt;		// baud clock counter
reg rd;

assign ack_o = cyc_i & stb_i & cs_i;
assign txd = tx_data[pBitsParallel-1:0];
wire ackwe1 = ack_o & we_i;

// Extend out the ack pulse a few cycles in case clk_i is faster then sclk.
always @(posedge clk_i)
begin
    ackwe[0] <= ackwe1;
    ackwe[1] <= ackwe[0];
    ackwe[2] <= ackwe[1];
    ackwe[3] <= ackwe[2];
    ackwe[4] <= ackwe[3];
end

wire pe_ack;
edge_det u1 (.rst(rst_i), .clk(sclk), .ce(1'b1), .i(|ackwe| ackwe1), .pe(pe_ack), .ne(), .ee() );

always @(posedge sclk)
if (rst_i) begin
    txing <= 1'b0;
    empty <= 1'b1;
    cnt <= 8'h00;
    sync <= 1'b0;
    tx_data <= {128{1'b1}};
end
else begin
    if (pe_ack)
      fdo <= dat_i;
    if (pe_ack)
      empty <= 1'b0;
    else if (sync)
      empty <= 1'b1;

    sync <= 1'b0;

    cnt <= cnt + 9'd1;
    if (cnt==pCount)
        txing <= 1'b0;
    // Load next data ?
    if (cnt==pCount || !txing) begin
        cnt <= 8'd0;
        if (!empty && cts) begin
            txing <= 1'b1;
            tx_data <= fdo;
            sync <= 1'b1;
        end
    end
    // Shift the data out. LSB first.
    else
        tx_data <= {8'hFF,tx_data[127:pBitsParallel]};

end

endmodule
