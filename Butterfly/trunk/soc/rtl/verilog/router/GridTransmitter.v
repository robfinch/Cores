// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// ============================================================================
//
`define HIGH    1'b1
`define LOW     1'b0

module GridTransmitter (
    rst_i,
    clk_i,
    clk57,
    clk400,
    rxd0,rxd1,rxd2,rxd3,rxd4,rxd5,rxd6,rxd7,rxd8,
    hsync,vsync,blank,
    GridTMDS_Data_p,
    GridTMDS_Data_n,
    GridTMDS_Clk_p,
    GridTMDS_Clk_n
);
input rst_i;
input clk_i;
input clk57;
input clk400;
input [3:0] rxd0;
input [3:0] rxd1;
input [3:0] rxd2;
input [3:0] rxd3;
input [3:0] rxd4;
input [3:0] rxd5;
input [3:0] rxd6;
input [3:0] rxd7;
input [3:0] rxd8;
input hsync;
input vsync;
input blank;
output [2:0] GridTMDS_Data_p;
output [2:0] GridTMDS_Data_n;
output GridTMDS_Clk_p;
output GridTMDS_Clk_n;

parameter NCHANNELS = 9;
parameter IDLE = 4'h0;
parameter READRX = 4'd1;

integer n,m;

reg [3:0] state;
reg [NCHANNELS-1:0] cs, cyc, we;
wire [NCHANNELS-1:0] ack;
wire [127:0] dat [0:NCHANNELS-1]; 
reg [127:0] din [0:NCHANNELS-1];
wire [127:0] dout [0:NCHANNELS-1];
reg [NCHANNELS-1:0] wf, rf, rf1;
wire [3:0] rxd [0:NCHANNELS-1];
wire [NCHANNELS-1:0] rd_data_count;
wire [NCHANNELS-1:0] full;
wire [4:0] fifocnt [0:NCHANNELS-1];
wire [NCHANNELS-1:0] fifofull;
reg [0:3] ig [0:NCHANNELS-1];
wire [13:0] o1, o2, o3;

assign rxd[0] = rxd0;
assign rxd[1] = rxd1;
assign rxd[2] = rxd2;
assign rxd[3] = rxd3;
assign rxd[4] = rxd4;
assign rxd[5] = rxd5;
assign rxd[6] = rxd6;
assign rxd[7] = rxd7;
assign rxd[8] = rxd8;

genvar g;
generate begin : receivers

for (g = 0; g < NCHANNELS; g = g + 1)
routerRxNasyn u1
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .cs_i(cs[g]),
    .cyc_i(cyc[g]),
    .stb_i(cyc[g]),
    .ack_o(ack[g]),
    .we_i(we[g]),
    .dat_o(dat[g]),
    .sclk(sclk),
    .clear(),
    .rxd(rxd[g]),
    .sync(),
    .overrun(),
    .fifocnt(fifocnt[g]),
    .fifofull(fifofull[g])
);

GridTxFifo u2
(
    .rst(rst_i),                    // input wire rst
    .wr_clk(clk_i),                 // input wire wr_clk
    .rd_clk(vclk),                // input wire rd_clk
    .din(din[g]),                   // input wire [127 : 0] din
    .wr_en(wf[g]),                  // input wire wr_en
    .rd_en(rf[g]),                  // input wire rd_en
    .dout(dout[g]),                 // output wire [127 : 0] dout
    .full(full[g]),                // output wire full
    .empty(),                  // output wire empty
    .rd_data_count(rd_data_count[g])  // output wire [8 : 0] rd_data_count
);

end
endgenerate

always @(posedge clk_i)
begin
for (n = 0; n < NCHANNELS; n = n + 1)
    wf[n] <= 1'b0;

case(state)
IDLE:
    for (n = 0; n < NCHANNELS; n = n + 1)
        if ({fifofull[n],fifocnt[n]} != 6'd0) begin
            cs[n] <= `HIGH;
            cyc[n] <= `HIGH;
            we[n] <= `LOW;
            state <= READRX;
        end
READRX:
    for (n = 0; n < 8; n = n + 1)
        if (ack[n]) begin
            cs[n] <= `LOW;
            cyc[n] <= `LOW;
            wf[n] <= 1'b1;
            din[n] <= dat[n];
            state <= IDLE;
        end
endcase
end

edge_det u20 (.rst(rst_i), .clk(clk57), .ce(1'b1), .i(hsync), .pe(pe_hsync), .ne(), .ee() );

reg [11:0] hctr;
reg [5:0] cctr;
always @(posedge clk57)
if (pe_hsync) begin
    hctr <= 12'h0;
    cctr <= 6'd0;
end
else if (!blank) begin
    hctr <= hctr + 12'd1;
    cctr <= cctr + 6'd1;
    if (cctr==6'd39)
        cctr <= 6'd0;
end

reg [3:0] ig [0:NCHANNELS-1];

always @(posedge clk57)
for (n = 0; n < NCHANNELS; n = n + 1) begin
    rf[n] <= 1'b0;
    if (cctr==6'd1) begin
        if (rd_data_count[n] != 5'd0 || full[n]) begin
            rf[n] <= 1'b1;
            rf1[n] <= 1'b1;
        end
    end
    if (blank)
        ig[n] <= 4'h0;
    else begin
        for (m = 4; m < 36; m = m + 1)
            if (cctr==m) begin
                if (rf1[n])
                    ig[n] <= dout[n] >> {m-4,2'b0};
                else
                    ig[n] <= 4'h0;
            end
    end
    if (cctr==6'd38)
        rf1[n] <= 1'b0;
end

GridTMDS_Encoder u21
(
    .PixelClk(clk57),
    .SerialClk(clk400),
    .aRst(rst_i),
    
    //Encoded parallel data
    .pDataOutRaw(o1),
    
    //Unencoded parallel data
    .pDataOut({ig[0],ig[1],ig[2]}),
    .pC0(1'b0),
    .pC1(1'b0),
    .pVde(blank)
);

GridTMDS_Encoder u22
(
    .PixelClk(clk57),
    .SerialClk(clk400),
    .aRst(rst_i),
    
    //Encoded parallel data
    .pDataOutRaw(o2),
    
    //Unencoded parallel data
    .pDataOut({ig[3],ig[4],ig[5]}),
    .pC0(1'b0),
    .pC1(1'b0),
    .pVde(blank)
);

GridTMDS_Encoder u23
(
    .PixelClk(clk57),
    .SerialClk(clk400),
    .aRst(rst_i),
    
    //Encoded parallel data
    .pDataOutRaw(o3),
    
    //Unencoded parallel data
    .pDataOut({ig[6],ig[7],ig[8]}),
    .pC0(hsync),
    .pC1(vsync),
    .pVde(blank)
);

OutputSERDES #(14) u24
(
    .PixelClk(clk57),
    .SerialClk(clk400),
    .sDataOut_p(GridTMDS_Data_p[0]),
    .sDataOut_n(GridTMDS_Data_n[0]),
    .pDataOut(o1),
    .aRst(rst_i)
);

OutputSERDES #(14) u25
(
    .PixelClk(clk57),
    .SerialClk(clk400),
    .sDataOut_p(GridTMDS_Data_p[1]),
    .sDataOut_n(GridTMDS_Data_n[1]),
    .pDataOut(o2),
    .aRst(rst_i)
);

OutputSERDES #(14) u26
(
    .PixelClk(clk57),
    .SerialClk(clk400),
    .sDataOut_p(GridTMDS_Data_p[2]),
    .sDataOut_n(GridTMDS_Data_n[2]),
    .pDataOut(o3),
    .aRst(rst_i)
);

OutputSERDES #(14) u27
(
    .PixelClk(clk57),
    .SerialClk(clk400),
    .sDataOut_p(GridTMDS_Clk_p),
    .sDataOut_n(GridTMDS_Clk_n),
    .pDataOut(14'b11111110000000),
    .aRst(rst_i)
);

endmodule
