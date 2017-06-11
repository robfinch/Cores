
module ButterflySoC(cpu_resetn, xclk, btnl, btnr, btnc, btnd, btnu, led,
    TMDS_OUT_clk_n, TMDS_OUT_clk_p,
    TMDS_OUT_data_n, TMDS_OUT_data_p 
);
input cpu_resetn;
input xclk;
input btnl;
input btnr;
input btnc;
input btnd;
input btnu;
output [7:0] led;
reg [7:0] led;
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
wire cyc21,stb21,we21;
wire [15:0] adr21;
wire [7:0] dato21;

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

// -----------------------------------------------------------------------------
// Circuit selection circuitry.
// -----------------------------------------------------------------------------

wire cs_btns = (adr21[15:4]==12'hB20) && cyc21 && stb21;
wire cs_leds = (adr11[15:4]==12'hB20) && cyc11 && stb11;
wire cs_tc_regs = adr11[15:4]==12'hB10;
wire cs_tc_ram = adr11[15:12]==4'h2;

// -----------------------------------------------------------------------------
// Buttons
// -----------------------------------------------------------------------------
reg [7:0] btns_dat;
wire btnu_db,btnd_db,btnl_db,btnr_db,btnc_db;
BtnDebounce bdbu(.clk(clk), .btn_i(btnu), .o(btnu_db));
BtnDebounce bdbd(.clk(clk), .btn_i(btnd), .o(btnd_db));
BtnDebounce bdbl(.clk(clk), .btn_i(btnl), .o(btnl_db));
BtnDebounce bdbr(.clk(clk), .btn_i(btnr), .o(btnr_db));
BtnDebounce bdbc(.clk(clk), .btn_i(btnc), .o(btnc_db));

wire btns_ack = cs_btns;
always @*
    btns_dat <= {3'h0,btnc_db,btnu_db,btnd_db,btnl_db,btnr_db};

// -----------------------------------------------------------------------------
// LEDs
// -----------------------------------------------------------------------------
always @(posedge clk)
    if (cs_leds & we11)
        led <= dato11;
    else
        led <= adr11[7:0];

wire leds_ack = cs_leds;

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

TextController8 tc1
(
    .rst_i(rst),
    .clk_i(clk),
    .cs_regs_i(cs_tc_regs),
    .cs_ram_i(cs_tc_ram),
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

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

grid u1
(
    .rst_i(rst),
    .clk_i(clk),

    .cyc11(cyc11),
    .stb11(stb11),
    .ack11(tc1_ack|leds_ack),
    .we11(we11),
    .adr11(adr11),
    .dati11(tc1_dato),
    .dato11(dato11), 

    .cyc21(cyc21),
    .stb21(stb21),
    .ack21(btns_ack),
    .we21(we21),
    .adr21(adr21),
    .dati21(btns_dat),
    .dato21() 
);

endmodule
