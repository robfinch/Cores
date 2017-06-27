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

module routerRxNasyn (rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, dat_o,
    sclk, clear, rxd, sync, overrun, fifocnt, fifofull
);
parameter pBitsParallel = 4;
parameter pClkMult = 4;
localparam pCount =
    pBitsParallel==8 ? 12'd67 : 
    pBitsParallel==4 ? 12'd135 :
    pBitsParallel==3 ? 12'd183 :
    pBitsParallel==2 ? 12'd271 :
    12'd543;
localparam pCount2 =
    pClkMult==16 ? (pCount+1) * 4 - 1 :
    pClkMult==8 ? (pCount+1) * 2 - 1 :
    pCount;
input rst_i;
input clk_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
output [127:0] dat_o;
input cs_i;
input sclk;
input clear;
input [pBitsParallel-1:0] rxd;
input sync;
output reg overrun;
output [4:0] fifocnt;
output fifofull;

// variables
reg [1:0] syncd;
reg [pBitsParallel-1:0] rxdd [0:1];	// synchronizer flops
reg [11:0] cnt;			// sample bit rate counter
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

wire pecs, pe_sync;
edge_det u2 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs & ~we_i), .pe(pecs), .ne(), .ee() );
edge_det u3 (.rst(rst_i), .clk(sclk), .ce(1'b1), .i(syncd[1]), .pe(pe_sync), .ne(), .ee() );

routerFifo2 u1
(
  .rst(rst_i),              // input wire srst
  .rd_clk(clk_i),            // input wire clk
  .wr_clk(sclk),
  .din(rx_data[127+pBitsParallel:pBitsParallel]),  // input wire [127 : 0] din
  .wr_en(wf),            // input wire wr_en
  .rd_en(pecs),            // input wire rd_en
  .dout(dat),              // output wire [127 : 0] dout
  .full(fifofull),         // output wire full
  .empty(),            // output wire empty
  .rd_data_count(fifocnt)  // output wire [4 : 0] data_count
);

// Two stage synchronizer to synchronize incoming data to
// the local clock (avoids metastability).
always @(posedge sclk) begin
    rxdd[0] <= rxd;
    rxdd[1] <= rxdd[0];
end
always @(posedge sclk) begin
    syncd[0] <= sync;
    syncd[1] <= syncd[0];
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
                // look for sync signal
                if (rxdd[1]==4'h0)
                    state <= `CNT;

            `CNT:
                begin
                    // End of the frame ?
                    // - check for framing error
                    // - write data to read buffer
                    if (cnt==pCount2-1)
                        begin	
                            if (fifocnt < 5'd31 && !fifofull)
                                wf <= 1'b1;
                            else
                                overrun <= 1'b1;
                        end
                    // Switch back to the idle state a little
                    // bit too soon.
                    if (cnt==pCount2-1)
                        state <= `IDLE;
                    
                    if (cnt==8'd01 && rxdd[1] != 4'h0)
                        state <= `IDLE;
                       
                    if (cnt[1:0]==3'h1)
                        rx_data <= {rxdd[1],rx_data[135:pBitsParallel]};
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

endmodule

