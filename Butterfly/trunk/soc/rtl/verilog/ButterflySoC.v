
module ButterflySoC(cpu_resetn, xclk, btnl, btnr, btnc, btnd, btnu, led, sw,
    kclk, kd,
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
input [7:0] sw;
inout kclk;
tri kclk;
inout kd;
tri kd;
output TMDS_OUT_clk_n;
output TMDS_OUT_clk_p;
output [2:0] TMDS_OUT_data_n;
output [2:0] TMDS_OUT_data_p;

wire xreset = ~cpu_resetn;
wire rst;
wire clk80, clk400;
wire hSync,vSync;
wire blank,border;
wire [7:0] red, green, blue;
wire [7:0] tc1_dato,tc2_dato;
wire tc1_ack;
wire [23:0] tc1_rgb;
wire [23:0] tc2_rgb;

wire cyc11,stb11,we11;
wire [15:0] adr11;
wire [7:0] dato11;
wire cyc21,stb21,we21;
wire [15:0] adr21;
wire [7:0] dato21;
wire cyc42,stb42,we42;
wire [15:0] adr42;
wire [7:0] dato42;

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
    .clk400(clk400),
    .clk125(),
    .clk80(clk80),
    .ub_sys_clk(),
    .sys_clk(clk),
    .dram_clk(),
    .locked(),
    .pulse1000Hz(),
    .pulse100Hz()
);

WXGASyncGen1280x768_60Hz u4
(
	.rst(rst),
	.clk(clk80),
	.hSync(hSync),
	.vSync(vSync),
	.blank(blank),
	.border(border)
);

rgb2dvi #(
    .kGenerateSerialClk(1'b0),
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
    .aRst_n(~rst),
    .vid_pData({red,blue,green}),
    .vid_pVDE(~blank),
    .vid_pHSync(~hSync),    // hSync is neg going for 1366x768
    .vid_pVSync(vSync),
    .PixelClk(clk80),
    .SerialClk(clk400)
);

// -----------------------------------------------------------------------------
// Circuit selection circuitry.
// -----------------------------------------------------------------------------

wire cs_btns = (adr21[15:4]==12'hB20) && cyc21 && stb21;
wire cs_kbd =  (adr21[15:4]==12'hB21);
wire cs_sw  =  (adr21[15:4]==12'hB22) && cyc21 && stb21;
wire cs_leds = (adr11[15:4]==12'hB20) && cyc11 && stb11;
wire cs_tc_regs = adr11[15:4]==12'hB10;
wire cs_tc_ram = adr11[15:12]==4'h2;
wire cs_tc2_regs = adr42[15:4]==12'hB10;
wire cs_tc2_ram = adr42[15:12]==4'h2;
wire cs_leds2 = (adr42[15:4]==12'hB20) && cyc42 && stb42;

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

reg [7:0] sw_dat;
always @*
    sw_dat <= sw;
wire sw_ack = cs_sw;

// -----------------------------------------------------------------------------
// LEDs
// -----------------------------------------------------------------------------
always @(posedge clk)
    if (cs_leds & we11)
        led[3:0] <= dato11[3:0];
always @(posedge clk)
    if (cs_leds2 & we42)
        led[7:4] <= dato42[3:0];

wire leds_ack = cs_leds;
wire leds_ack2 = cs_leds2;

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
    .vclk(clk80),
    .hsync(hSync),
    .vsync(vSync),
    .blank(blank),
    .border(border),
    .rgbIn(),
    .rgbOut(tc1_rgb)
);

TextController8 tc2
(
    .rst_i(rst),
    .clk_i(clk),
    .cs_regs_i(cs_tc2_regs),
    .cs_ram_i(cs_tc2_ram),
    .cyc_i(cyc42),
    .stb_i(stb42),
    .ack_o(tc2_ack),
    .we_i(we42),
    .adr_i(adr42[11:0]),
    .dat_i(dato42),
    .dat_o(tc2_dato),
    .vclk(clk80),
    .hsync(hSync),
    .vsync(vSync),
    .blank(blank),
    .border(border),
    .rgbIn(),
    .rgbOut(tc2_rgb)
);
assign red = sw[0] ? tc2_rgb[23:16] : tc1_rgb[23:16];
assign green = sw[0] ? tc2_rgb[15:8] : tc1_rgb[15:8];
assign blue = sw[0] ? tc2_rgb[7:0] : tc1_rgb[7:0];

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

wire kbd_rst;
wire kbd_ack;
wire [7:0] kbd_dato;

Ps2Keyboard u_ps2kbd
(
    .rst_i(rst),
    .clk_i(clk),
    .cs_i(cs_kbd),
    .cyc_i(cyc21),
    .stb_i(stb21),
    .ack_o(kbd_ack),
    .we_i(we21),
    .adr_i(adr21[3:0]),
    .dat_i(dato21),
    .dat_o(kbd_dato),
    .kclk(kclk),
    .kd(kd),
    .irq_o()
);

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
    .ack21(btns_ack|kbd_ack|sw_ack),
    .we21(we21),
    .adr21(adr21),
    .dati21(cs_btns ? btns_dat : cs_sw ? sw_dat : kbd_dato),
    .dato21(), 

    .cyc42(cyc42),
    .stb42(stb42),
    .ack42(tc2_ack|leds_ack2),
    .we42(we42),
    .adr42(adr42),
    .dati42(tc2_dato),
    .dato42(dato42)
);

endmodule
