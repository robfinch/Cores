
module FT64SoC_tb();
reg rst;
reg clk;
wire cyc;
wire stb;
wire ack;
wire we;
wire [7:0] sel;
wire [31:0] adr;
wire [63:0] dato;
wire [63:0] dati;
reg [63:0] dat;
wire [63:0] br_dato;
wire [63:0] scr_dato;
wire ack_scr;

initial begin
    rst = 0;
    clk = 0;
    #10 rst = 1;
    #50 rst = 0;
end

always #5 clk = ~clk;

//reg [7:0] state;
//always @(posedge clk)
//if (rst) begin
//    state <= 0;
//end
//else begin
//case(state)
//0:
//if (cyc) begin
//    case(adr)
//    32'hFFFC0010:  dat <= {32'b0000000000111111_11110_11100_011010,32'b1010101010101010_00001_00000_001001}; // LDI r1,#$AAAA
//    32'hFFFC0018:  dat <= {32'h0000000000000000_00000_00000_000000,32'b0000011000000000_00001_00000_010100}; // IMML
//    32'hFFFC0020:  dat <= {32'b0000000000111111_11110_11100_011010,32'b0101010101010101_00001_00000_001001}; // LDI r1,#$5555
//    default: dat <= 64'd0;
//    endcase
//    ack <= 1'b1;
//    state <= 1;
//end
//1:  state <= 0;
//endcase
//end

wire led_ack = (adr[31:4]==28'hFFDC060) & stb;
wire cs_scr = adr[31:16]==16'h0000;
wire cs_br = adr[31:16]==16'hFFFC;  

scratchmem uscr
(
    .rst_i(rst),
    .clk_i(clk),
    .cs_i(cs_scr),
    .cyc_i(cyc),
    .stb_i(stb),
    .we_i(we),
    .sel_i(sel),
    .ack_o(ack_scr),
    .adr_i(adr[14:0]),
    .dat_i(dato),
    .dat_o(scr_dato)
);

bootrom ubr
(
    .rst_i(rst),
    .clk_i(clk),
    .cs_i(cs_br),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(br_ack),
    .adr_i(adr[17:0]),
    .dat_o(br_dato)
);

assign ack = br_ack|led_ack|ack_scr;
assign dati = cs_br ? br_dato : scr_dato;

FT64_mpu ucpu1
(
    .rst_i(rst),
    .clk_i(clk),
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .we_o(we),
    .sel_o(sel),
    .adr_o(adr),
    .dat_o(dato),
    .dat_i(dati)
);

endmodule
