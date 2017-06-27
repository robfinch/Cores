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
module routerTxNasyn (rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, dat_i,
    sclk, cts, txd, sync, empty
);
parameter pBitsParallel = 4;
parameter pClkMult = 4;     // 16, 8, or 4 times bit rate clock multiple
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
output reg empty;   // buffer is empty

reg txing;
reg [135:0] tx_data;	// transmit data working reg (raw)
reg [127:0] fdo;	// data output
reg [11:0] cnt;		// baud clock counter
reg sync1;

assign ack_o = cyc_i & stb_i & cs_i;
assign txd = tx_data[pBitsParallel-1:0];
wire ackwe1 = ack_o & we_i;
reg [3:0] ackwe;

// Extend out the ack pulse a few cycles in case clk_i is faster than sclk.
always @(posedge clk_i)
begin
    ackwe[0] <= ackwe1;
    ackwe[1] <= ackwe[0];
    ackwe[2] <= ackwe[1];
    ackwe[3] <= ackwe[2];
end

wire pe_ack;
edge_det u1 (.rst(rst_i), .clk(sclk), .ce(1'b1), .i(|ackwe |ackwe1), .pe(pe_ack), .ne(), .ee() );

always @(posedge sclk)
if (rst_i) begin
    txing <= 1'b0;
    empty <= 1'b1;
    cnt <= 12'h00;
    sync <= 1'b0;
    sync1 <= 1'b0;
    tx_data <= {136{1'b1}};
end
else begin
    if (pe_ack)
      fdo <= dat_i;
    if (pe_ack)
      empty <= 1'b0;
    else if (sync1)
      empty <= 1'b1;

    sync1 <= 1'b0;
    sync <= sync1;

    cnt <= cnt + 12'd1;
    if (cnt==pCount2)
        txing <= 1'b0;
    // Load next data ?
    if (cnt==pCount2 || !txing) begin
        cnt <= 12'd0;
        if (!empty && cts) begin
            txing <= 1'b1;
            case(pBitsParallel)
            8:  tx_data <= {8'hFF,fdo,8'h0};
            4:  tx_data <= {4'hF,fdo,4'h0};
            3:  tx_data <= {3'd7,fdo,3'd0};
            2:  tx_data <= {2'd3,fdo,2'd0};
            default:    tx_data <= {4'hF,fdo,4'h0};
            endcase
            sync <= 1'b1;
            sync1 <= 1'b1;
        end
    end
    // Shift the data out. LSB first.
    else begin
        case(pClkMult)
        4:  if (cnt[1:0]==2'd3) tx_data <= {8'hFF,tx_data[135:pBitsParallel]};
        8:  if (cnt[2:0]==3'd7) tx_data <= {8'hFF,tx_data[135:pBitsParallel]};
        16: if (cnt[3:0]==4'd15) tx_data <= {8'hFF,tx_data[135:pBitsParallel]};
        default:  if (cnt[1:0]==2'd3) tx_data <= {8'hFF,tx_data[135:pBitsParallel]};
        endcase
    end

end

endmodule
