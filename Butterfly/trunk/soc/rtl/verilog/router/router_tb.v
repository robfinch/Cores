`define HIGH    1'b1
`define LOW     1'b0

module router_tb();
reg rst;
reg clk;
reg cs;
reg cyc;
reg we;
reg [15:0] adr;
reg [7:0] dati;
wire [7:0] dato;
wire ack;
wire [4:0] rxdX,rxdY,txdX,txdY;
reg [127:0] txdata1 = {8'hFF,8'h44,32'h0000,8'h00,8'h01,64'h1122334455667788};
reg [5:0] txdcnt;

initial begin
    clk = 0;
    rst = 0;
    #10 rst = 1;
    #100 rst = 0;
end

always #10 clk = ~clk;

reg [5:0] state;
always @(posedge clk)
if (rst) begin
    state <= 0;
    txdcnt <= 0;
end
else begin
case(state)
0:  begin
    cs <= `HIGH;
    cyc <= `HIGH;
    we <= `LOW;
    adr <= 16'hB012;
    state <= 1;
    end
1:  if (ack) begin
        cs <= `LOW;
        cyc <= `LOW;
        if (dato!=8'h00)
            state <= 0;
        else
            state <= 2;
    end
2:  begin
    cs <= `HIGH;
    cyc <= `HIGH;
    we <= `HIGH;
    adr <= 16'hB000 + txdcnt;
    dati <= txdata1 >> {txdcnt,3'd0};
    state <= 3;
    end
3:  if (ack) begin
        txdcnt <= txdcnt + 6'd1;
        cs <= `LOW;
        cyc <= `LOW;
        we <= `LOW;
        if (txdcnt==6'd15)
            state <= 4;
        else
            state <= 2;
    end
4:  begin
    cs <= `HIGH;
    cyc <= `HIGH;
    we <= `HIGH;
    adr <= 16'hB012;
    dati <= 8'h01;
    state <= 5;
    end
5:  if (ack) begin
        cs <= `LOW;
        cyc <= `LOW;
        we <= `LOW;
        state <= 6;
    end
6:  state <= 6;
endcase
end

routerTop u1
(
    .X(4'h4),
    .Y(4'h4),
    .rst_i(rst),
    .clk_i(clk),
    .cs_i(cs),
    .cyc_i(cyc),
    .stb_i(cyc),
    .ack_o(ack),
    .we_i(we),
    .adr_i(adr[4:0]),
    .dat_i(dati),
    .dat_o(dato),
    .rxdX(txdX),
    .rxdY(txdY),
    .txdX(txdX),
    .txdY(txdY)
);

endmodule
