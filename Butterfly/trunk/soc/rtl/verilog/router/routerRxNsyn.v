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
module routerRxNsyn (rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, dat_o,
    sclk, clear, sync, rxd, overrun, fifocnt, fifofull
);
parameter pBitsParallel = 4;
parameter p2 = 4;
localparam pCount =
    pBitsParallel==8 ? 8'd15 : 
    pBitsParallel==4 ? 8'd31 :
    pBitsParallel==3 ? 8'd42 :
    8'd63; // 2
// WISHBONE SoC bus interface
input rst_i;            // reset
input clk_i;            // clock
input cs_i;                // chip select
input cyc_i;            // cycle is valid
input stb_i;            // strobe
output ack_o;            // data is ready
input we_i;                // write (this signal is used to qualify reads)
output [127:0] dat_o;        // data out
//------------------------
input sclk;                // serialization clock
input clear;            // clear reciever
input sync;
input [pBitsParallel-1:0] rxd;        // external serial input
output reg overrun;            // receiver overrun
// Fifo status
output [4:0] fifocnt;
output fifofull;

// variables
reg [pBitsParallel-1:0] rxdd [0:1];	// synchronizer flops
reg [1:0] syncd;
reg [7:0] cnt;			// sample bit rate counter
reg [127:0] rx_data;		// working receive data register
wire [127:0] next_rx_data = {rxdd[1],rx_data[127:pBitsParallel]};
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
  .din(rx_data),                // input wire [127 : 0] din
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
end
always @(posedge sclk) begin
    syncd[0] <= sync;
    syncd[1] <= syncd[0];
end

always @(posedge sclk)
if (rst_i) begin
    cnt <= 8'h00;
    wf <= 1'b0;
    overrun <= 1'b0;
end
else begin
    wf <= 1'b0;
    if (clear) begin
        cnt <= 8'h00;
        wf <= 1'b0;
        overrun <= 1'b0;
    end
    else begin
        cnt <= cnt + 8'd1;
        if (syncd[1])
            cnt <= 8'd1;
        // End of the frame ?
        // - check for framing error
        // - write data to read fifo
        if (cnt==pCount) begin
            cnt <= 8'h00;	
            if (fifocnt < 5'd31 && !fifofull)
                wf <= 1'b1;
            else
                overrun <= 1'b1;
        end
        rx_data <= next_rx_data;
    end
end

endmodule

