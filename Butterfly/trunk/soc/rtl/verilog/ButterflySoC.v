
module ButterflySoC(cpu_resetn, xclk,
    TMDS_OUT_clk_n, TMDS_OUT_clk_p,
    TMDS_OUT_data_n, TMDS_OUT_data_p 
);
input cpu_resetn;
input xclk;
output TMDS_OUT_clk_n;
output TMDS_OUT_clk_p;
output [2:0] TMDS_OUT_data_n;
output [2:0] TMDS_OUT_data_p;

wire xreset = ~cpu_resetn;
wire rst;
wire vclk;
wire hSync,vSync;
wire blank,border;
wire [7:0] red, green, blue;
wire [7:0] tc1_dato;
wire tc1_ack;
wire [23:0] tc1_rgb;

wire cyc11,stb11,we11;
wire [15:0] adr11;
wire [7:0] dato11;

clkgen u2
(
    .xreset(xreset),
    .xclk(xclk),
    .rst(rst),
    .clk100(),
    .clk25(),
    .clk50(),
    .clk200(),
    .clk300(),
    .clk125(),
    .vclk(vclk),
    .ub_sys_clk(),
    .sys_clk(clk),
    .dram_clk(),
    .locked(),
    .pulse1000Hz(),
    .pulse100Hz()
);

WXGASyncGen1366x768_60Hz u4
(
	.rst(rst),
	.clk(vclk),
	.hSync(hSync),
	.vSync(vSync),
	.blank(blank),
	.border(border)
);

rgb2dvi #(
    .kGenerateSerialClk(1'b1),
    .kClkPrimitive("MMCM"),
    .kClkRange(2),
    .kRstActiveHigh(1'b1)
)
ur2d1 
(
    .TMDS_Clk_p(TMDS_OUT_clk_p),
    .TMDS_Clk_n(TMDS_OUT_clk_n),
    .TMDS_Data_p(TMDS_OUT_data_p),
    .TMDS_Data_n(TMDS_OUT_data_n),
    .aRst(rst),
//    .aRst_n(~rst),
    .vid_pData({red,blue,green}),
    .vid_pVDE(~blank),
    .vid_pHSync(~hSync),    // hSync is neg going for 1366x768
    .vid_pVSync(vSync),
    .PixelClk(vclk)
);

TextController8 tc1
(
    .rst_i(rst),
    .clk_i(clk),
    .cs_regs_i(adr11[15:4]==4'hB00),
    .cs_ram_i(adr11[15:12]==4'h1),
    .cyc_i(cyc11),
    .stb_i(stb11),
    .ack_o(tc1_ack),
    .we_i(we11),
    .adr_i(adr11[11:0]),
    .dat_i(dato11),
    .dat_o(tc1_dato),
    .vclk(vclk),
    .hsync(hSync),
    .vsync(vSync),
    .blank(blank),
    .border(border),
    .rgbIn(),
    .rgbOut(tc1_rgb)
);
assign red = tc1_rgb[23:16];
assign green = tc1_rgb[15:8];
assign blue = tc1_rgb[7:0];

grid u1
(
    .rst_i(rst),
    .clk_i(clk),
    .cyc11(cyc11),
    .stb11(stb11),
    .ack11(tc1_ack),
    .we11(we11),
    .adr11(adr11),
    .dati11(tc1_dato),
    .dato11(dato11), 
    .cyc21(),
    .stb21(),
    .ack21(),
    .we21(),
    .adr21(),
    .dati21(),
    .dato21() 
);

endmodule
