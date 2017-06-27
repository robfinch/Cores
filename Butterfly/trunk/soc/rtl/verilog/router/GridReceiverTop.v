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
`define HIGH    1'b1
`define LOW     1'b0

module GridReceiverTop(rst, refclk, clk57,
    TMDS_Clk_p, TMDS_Clk_n, TMDS_Data_p, TMDS_Data_n,
    txd0, txd1, txd2, txd3, txd4, txd5, txd6, txd7, txd8
);
input rst;
input refclk;
input clk57;
input TMDS_Clk_p;
input TMDS_Clk_n;
input [2:0] TMDS_Data_p;
input [2:0] TMDS_Data_n;
output [3:0] txd0;
output [3:0] txd1;
output [3:0] txd2;
output [3:0] txd3;
output [3:0] txd4;
output [3:0] txd5;
output [3:0] txd6;
output [3:0] txd7;
output [3:0] txd8;
parameter NCHANNELS = 9;
parameter IDLE = 4'd0;
parameter READTX1 = 4'd1;
parameter READTX2 = 4'd1;
parameter READTX3 = 4'd1;

integer n,m;
reg [3:0] state;
wire vclk;
wire hsync;
wire blank;
reg [NCHANNELS-1:0] cyc, we, cs;
wire [NCHANNELS-1:0] ack, txEmpty;
wire [35:0] pData;
reg [127:0] rxbuf [0:NCHANNELS-1];
wire [127:0] dout [0:NCHANNELS-1];
reg [NCHANNELS-1:0] wf, rf, rf1;
wire [NCHANNELS-1:0] rd_data_count, full;
wire [3:0] txd [0:NCHANNELS-1];
assign txd0 = txd[0];
assign txd1 = txd[1];
assign txd2 = txd[2];
assign txd3 = txd[3];
assign txd4 = txd[4];
assign txd5 = txd[5];
assign txd6 = txd[6];
assign txd7 = txd[7];
assign txd8 = txd[8];

GridReceiver #(.kAddBUFG(1'b0)) u1
(
    .TMDS_Clk_p(TMDS_Clk_p),
    .TMDS_Clk_n(TMDS_Clk_n),
    .TMDS_Data_p(TMDS_Data_p),
    .TMDS_Data_n(TMDS_Data_n),

    .RefClk(refclk),
    .aRst(rst),
    .aRst_n(~rst),

    .vid_pData(pData),
    .vid_pVDE(blank),
    .vid_pHSync(hsync),
    .vid_pVSync(),

    .PixelClk(vclk),
    .SerialClk(),
    .aPixelClkLckd(),
      
    .DDC_SDA_I(),
    .DDC_SDA_O(),
    .DDC_SDA_T(),
    .DDC_SCL_I(),
    .DDC_SCL_O(), 
    .DDC_SCL_T(),
    
    .pRst(),    // : in std_logic; -- synchronous reset; will restart locking procedure
    .pRst_n()   // : in std_logic -- synchronous reset; will restart locking procedure
);

wire pe_hsync;
edge_det u2 (.rst(rst), .clk(vclk), .ce(1'b1), .i(hsync), .pe(pe_hsync), .ne(), .ee() );

genvar g;
generate begin : GridRxFifos
for (g = 0; g < NCHANNELS; g = g + 1)
begin
GridRxFifo2 u3 (
  .rst(rst),                      // input wire rst
  .wr_clk(vclk),                // input wire wr_clk
  .rd_clk(clk57),                // input wire rd_clk
  .din(rxbuf[g]),                      // input wire [127 : 0] din
  .wr_en(wf[g]),                  // input wire wr_en
  .rd_en(rf[g]),                  // input wire rd_en
  .dout(dout[g]),                    // output wire [127 : 0] dout
  .full(full[g]),                    // output wire full
  .empty(),                  // output wire empty
  .rd_data_count(rd_data_count[g])  // output wire [8 : 0] rd_data_count
);

routerTxNasyn #(4,4) u4 (
	// WISHBONE SoC bus interface
	.rst_i(rst),		// reset
	.clk_i(clk57),		// clock
	.cyc_i(cyc),		// cycle valid
	.stb_i(cyc),		// strobe
	.ack_o(ack),		// transfer done
	.we_i(we),		// write transmitter
	.dat_i(dout[g]),   // data in
	//--------------------
	.cs_i(cs),			// chip select
	.sclk(clk57),
	.cts(1'b1),			// clear to send
	.txd(txd[g]),		// external serial output
	.sync(),
	.empty(txEmpty[g])	    // buffer is empty
);
end
end
endgenerate

always @(posedge clk57)
if (rst)
    state <= IDLE;
else begin
for (n = 0; n < NCHANNELS; n = n + 1)
    rf[n] <= 1'b0;
case(state)
IDLE:
    begin
        for (n = 0; n < NCHANNELS; n = n + 1) begin
            if ({full[n],rd_data_count[n]} != 10'd0 && txEmpty[n]) begin
                rf[n] <= 1'b1;
                rf1[n] <= 1'b1;
                state <= READTX1;
            end
        end
    end
READTX1:    state <= READTX2;
READTX2:
    begin
        for (n = 0; n < NCHANNELS; n = n + 1) begin
            if (rf1[n]) begin
                cs[n] <= `HIGH;
                cyc[n] <= `HIGH;
                we[n] <= `HIGH;
                rf1[n] <= 1'b0;
                state <= READTX3;
            end
        end
    end
READTX3:
    begin
        for (n = 0; n < NCHANNELS; n = n + 1) begin
            if (ack[n]) begin
                cs[n] <= `LOW;
                cyc[n] <= `LOW;
                we[n] <= `LOW;
                state <= IDLE;
            end
        end        
    end
endcase
end

reg [5:0] cctr;
always @(posedge vclk)
begin
    for (n = 0; n < NCHANNELS; n = n + 1)
        wf[n] <= 1'b0;
    if (pe_hsync)
        cctr <= 6'd0;
    else if (!blank) begin
        cctr <= cctr + 6'd1;
        if (cctr==6'd39)
            cctr <= 6'd0;
        for (m = 4; m < 36; m = m + 1) begin
            if (cctr==m) begin
                rxbuf[0] <= {rxbuf[0][123:0],pData[3:0]};
                rxbuf[1] <= {rxbuf[1][123:0],pData[7:4]};
                rxbuf[2] <= {rxbuf[2][123:0],pData[11:7]};
                rxbuf[3] <= {rxbuf[3][123:0],pData[15:12]};
                rxbuf[4] <= {rxbuf[4][123:0],pData[19:16]};
                rxbuf[5] <= {rxbuf[5][123:0],pData[23:20]};
                rxbuf[6] <= {rxbuf[6][123:0],pData[27:24]};
                rxbuf[7] <= {rxbuf[7][123:0],pData[31:28]};
                rxbuf[8] <= {rxbuf[8][123:0],pData[35:32]};
            end
        end
        if (cctr==6'd37) begin
            for (n = 0; n < NCHANNELS; n = n + 1)
                if (rxbuf[n][127:120]!=8'h00) wf[n] <= 1'b1;
        end
    end
end

endmodule
