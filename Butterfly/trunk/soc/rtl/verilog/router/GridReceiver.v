`define HIGH    1'b1
`define LOW     1'b0

module GridReceiver(
    rst_i,
    clk_i,
    sclk,
    pclk,
    rxd0,rxd1,rxd2,rxd3,rxd4,rxd5,rxd6,rxd7,rxd8,
    vclk,hsync,vsync,blank,
);
input rst_i;
parameter NCHANNELS = 9;
parameter IDLE = 4'h0;
parameter READRX = 4'd1;
reg [NCHANNELS-1:0] cs, cyc, we;
wire [NCHANNELS-1:0] ack;
wire [127:0] dat [0:NCHANNELS-1]; 
reg [127:0] din [0:NCHANNELS-1];
reg [7:0] wf;
wire [3:0] rxd [0:NCHANNELS-1];
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
generate begin

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

GridRxFifo u2
(
    .rst(rst_i),                    // input wire rst
    .wr_clk(clk_i),                 // input wire wr_clk
    .rd_clk(rd_clk),                // input wire rd_clk
    .din(din[g])                    // input wire [127 : 0] din
    .wr_en(wf[g]),                  // input wire wr_en
    .rd_en(rd_en),                  // input wire rd_en
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

if (pe_hsync)
    hctr <= 12'h0;
else if (!blank)
    hctr <= hctr + 12'd1;
    

endmodule
