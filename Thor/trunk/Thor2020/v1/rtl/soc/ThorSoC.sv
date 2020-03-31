`define TEXT_CONTROLLER	1'b1
`define BMP_CONTROLLER 1'b1		// needed for sync generation
`define SPRITE_CONTROLLER	1'b1

module ThorSoC(cpu_resetn, xclk, led, sw, btnl, btnr, btnc, btnd, btnu, /*ip, insn, wr, rdy, ad, dati, dato,*/
  kclk, kd, uart_txd, uart_rxd,
  TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n
);
input cpu_resetn;
input xclk;
output reg [7:0] led;
input [7:0] sw;
input btnl;
input btnr;
input btnc;
input btnd;
input btnu;
inout kclk;
tri kclk;
inout kd;
tri kd;
output uart_txd;
input uart_rxd;
output TMDS_OUT_clk_p;
output TMDS_OUT_clk_n;
output [2:0] TMDS_OUT_data_p;
output [2:0] TMDS_OUT_data_n;

wire clk14, clk20, clk40, clk100, clk200;
wire cpu_clk = clk100;
wire locked;
wire rst = !locked;

wire cyc;
wire stb;
wire we;
wire [7:0] sel;
wire [31:0] adr;
reg [63:0] dati;
wire [63:0] dato;

wire [31:0] tc1_rgb;
wire tc1_ack;
wire [63:0] tc1_dato;
wire ack_scr;
(* mark_debug = "true" *)
wire ack_br;
wire ack_br2;
wire [63:0] scr_dato, br_dato, br_dato2;
wire br_bok, scr_bok;
wire rnd_ack;
wire [31:0] rnd_dato;
(* mark_debug="true" *)
wire dram_ack;
wire [63:0] dram_dato;
wire dram_ack2;
wire [63:0] dram_dato2;
wire avic_ack;
wire [63:0] avic_dato;
wire [31:0] avic_rgb;
wire kbd_rst;
wire kbd_ack;
wire [7:0] kbd_dato;
wire kbd_irq;

wire spr_ack;
wire [63:0] spr_dato;
(* mark_debug = "true" *)
wire spr_cyc;
wire spr_stb;
(* mark_debug = "true" *)
wire spr_acki;
wire spr_we;
wire [7:0] spr_sel;
wire [31:0] spr_adr;
wire [63:0] spr_dati;
wire [31:0] spr_rgbo;
wire [5:0] spr_spriteno;

parameter BMPW = 128;
wire bmp_ack;
wire [63:0] bmp_cdato;
wire bmp_cyc;
wire bmp_stb;
wire bmp_acki;
wire bmp_we;
wire [(BMPW==128 ? 15 : 7):0] bmp_sel;
wire [31:0] bmp_adr;
wire [BMPW-1:0] bmp_dati;
wire [BMPW-1:0] bmp_dato;
wire [31:0] bmp_rgb;
wire [11:0] hctr, vctr;
wire [5:0] fctr;

wire ack_1761;
wire gpio_ack;
wire [15:0] aud0, aud1, aud2, aud3;
wire [15:0] audi;
(* mark_debug = "true" *)
wire aud_cyc;
wire aud_stb;
(* mark_debug = "true" *)
wire aud_acki;
wire aud_we;
wire [1:0] aud_sel;
wire [31:0] aud_adr;
wire [15:0] aud_dati;
wire [15:0] aud_dato;
wire aud_ack;
wire [63:0] aud_cdato;

wire rtc_ack;
wire [7:0] rtc_cdato;
wire spi_ack;
wire [7:0] spi_dato;

wire pti_ack;
wire [63:0] pti_cdato;
wire pti_cyc;
wire pti_stb;
wire pti_acki;
wire pti_we;
wire [15:0] pti_sel;
wire [31:0] pti_adr;
wire [127:0] pti_dato;
wire [127:0] pti_dati;

wire sdc_ack;
wire [31:0] sdc_cdato;
(* mark_debug = "true" *)
wire sdc_cyc;
wire sdc_stb;
(* mark_debug = "true" *)
wire sdc_acki;
wire sdc_we;
wire [3:0] sdc_sel;
wire [31:0] sdc_adr;
wire [31:0] sdc_dato;
wire [31:0] sdc_dati;

wire ack_gbridge1;
wire gbr1_cyc;
wire gbr1_stb;
reg gbr1_ack;
wire gbr1_we;
wire [7:0] gbr1_sel;
wire [3:0] gbr1_sel32;
wire [31:0] gbr1_adr;
wire [31:0] gbr1_adr32;
wire [63:0] gbr1_cdato;
wire [63:0] gbr1_dato;
wire [31:0] gbr1_dato32;
reg [63:0] gbr1_dati = 64'd0;

wire grid_cyc;
wire grid_stb;
wire grid_ack;
wire grid_we;
wire [3:0] grid_sel;
wire [31:0] grid_adr;
reg [31:0] grid_dati = 32'd0;
wire grid_dram_ack;
wire [63:0] grid_dram_dati1;
wire [31:0] grid_dato;
wire [31:0] grid_zrgb;

wire uart_ack;
wire [31:0] uart_dato;
wire via_ack;
wire [31:0] via_dato;
wire [31:0] pa_o;
wire [31:0] pa_i;
wire ack_pic;
wire [31:0] pic_dato;
wire ack_sema;
wire [7:0] sema_dato;
wire ack_mut;
wire [63:0] mut_dato;
wire eth_ack;
wire [31:0] eth_cdato;
wire eeprom_ack;

wire ack_bridge1;
wire ack_bridge1a;
wire br1_cyc;
wire br1_stb;
reg br1_ack = 1'b0;
wire br1_we;
wire [7:0] br1_sel;
wire [3:0] br1_sel32;
wire [31:0] br1_adr;
wire [31:0] br1_adr32;
wire [63:0] br1_cdato;
wire [63:0] br1_cdato2;
wire br1_s2_ack;
wire [63:0] br1_s2_cdato;
wire [63:0] br1_dato;
wire [31:0] br1_dat32;
wire [7:0] br1_dat8;
reg [63:0] br1_dati = 64'd0;

wire ack_bridge2;
wire ack_bridge2a;
wire br2_cyc;
wire br2_stb;
reg br2_ack = 1'b0;
wire br2_we;
wire [7:0] br2_sel;
wire [3:0] br2_sel32;
wire [31:0] br2_adr;
wire [31:0] br2_adr32;
wire [63:0] br2_cdato;
wire [63:0] br2_cdato2;
wire [63:0] br2_dato;
wire [31:0] br2_dat32;
wire [7:0] br2_dat8;
reg [63:0] br2_dati = 64'd0;

wire ack_bridge3;
wire ack_bridge3a;
wire cs_bridge3;
wire cs_bridge3a;
wire br3_cyc;
wire br3_stb;
reg br3_ack = 1'b0;
wire br3_we;
wire [7:0] br3_sel;
wire [3:0] br3_sel32;
wire [31:0] br3_adr;
wire [31:0] br3_adr32;
wire [63:0] br3_cdato;
wire [63:0] br3_cdato2;
wire [63:0] br3_dato;
wire [31:0] br3_dat32;
wire [7:0] br3_dat8;
reg [63:0] br3_dati = 64'd0;

wire [63:0] dram_dato;

wire ack_bridge1, ack_bridge2, ack_bridge3;
wire ack_scr, dram_ack;

wire icyc;
wire [31:0] iadr;
wire [127:0] idat;

ThorSoCclkgen ucg1
(
  // Clock out ports
  .clk200(clk200),
  .clk100(clk100),
  .clk40(clk40),
  .clk20(clk20),
  .reset(~cpu_resetn),
  .locked(locked),
 // Clock in ports
  .clk_in1(xclk)
);

rgb2dvi #(
	.kGenerateSerialClk(1'b0),
	.kClkPrimitive("MMCM"),
	.kClkRange(3),
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
	.vid_pHSync(hSync),    // hSync is neg going for 1366x768
	.vid_pVSync(vSync),
	.PixelClk(clk40),
	.SerialClk(clk200)
);

// -----------------------------------------------------------------------------
// Input debouncing
// -----------------------------------------------------------------------------

wire btnu_db, btnd_db, btnl_db, btnr_db, btnc_db;
BtnDebounce udbu (clk20, btnu, btnu_db);
BtnDebounce udbd (clk20, btnd, btnd_db);
BtnDebounce udbl (clk20, btnl, btnl_db);
BtnDebounce udbr (clk20, btnr, btnr_db);
BtnDebounce udbc (clk20, btnc, btnc_db);


// -----------------------------------------------------------------------------
// Address Decoding
// -----------------------------------------------------------------------------
(* mark_debug="true" *)
wire cs_dram = adr[31:29]==3'h0;		// Main memory 512MB
wire cs_rom = iadr[31:26]==6'h3F;
wire cs_scr = adr[31:22]==10'b1111_1111_01;	// Scratchpad memory 64k
// No need to check for the $FFD in the top 12 address bits as these are 
// detected in the I/O bridges.
wire cs_tc1 = br1_adr[19:16]==4'h0	// FFD0xxxx Text Controller 128k
					||  br1_adr[19:16]==4'h1;
wire cs_spr = br1_adr[19:12]==8'hAD;	// FFDADxxx	Sprite Controller
wire cs_bmp = br1_adr[19:12]==8'hC5;	//          Bitmap Controller
wire cs_pic = br1_adr[19:8]==12'hC0F;
wire cs_sema = br1_adr[19:12]==8'hB0;
wire cs_mut = br1_adr[19:8]==12'hBFF;
//wire cs_bmp = 1'b0;
//wire cs_avic = br1_adr[31:13]==19'b1111_1111_1101_1100_110;	// FFDCC000-FFDCDFFF
wire cs_avic = 1'b0;									// defunct: audio / video controller
wire cs_gfx00 = br1_adr[19:12]==8'hD8;		// orsoc graphics accelerator
wire cs_rnd = br2_adr[19:8]==12'hC0C;		// PRNG random number generator
wire cs_via = br3_adr[19:8]==12'hC06;		// LEDS,buttons,switches
wire cs_kbd  = br2_adr[19:4]==16'hC000;		// keyboard controller
wire cs_aud  = br2_adr[19:8]==12'h510;		// audio controller
wire cs_1761 = br2_adr[19:4]==16'hC070;		// AC97 controller
wire cs_cmdc = br2_adr[19:4]==16'hC080;
wire cs_grid = br2_adr[19:8]==12'h520;		// graphics grid computer
wire cs_imem = br2_adr[19:12]==8'hC8 		// instruction memory for grid computer
						|| br2_adr[19:12]==8'hC9
						|| br2_adr[19:12]==8'hCA
						|| br2_adr[19:12]==8'hCB
						;
wire cs_eth = br2_adr[19:12]==8'hC2;
wire cs_rtc = br3_adr[19:4]==16'hC020;		// real-time clock chip
wire cs_spi = br3_adr[19:8]==12'hC05;			// spi controller
wire cs_sdc = br3_adr[19:8]==12'hC0B;			// sdc controller
wire cs_pti = br3_adr[19:8]==12'hC12;			// parallel transfer interface
wire cs_uart = br3_adr[19:4]==16'hC0A0;
wire cs_eeprom = br3_adr[19:4]==16'hC0E1;
wire cs_bridge3 = cs_rtc|cs_spi|cs_via|cs_pti|cs_uart|cs_eeprom|cs_sdc;
wire cs_bridge1 = (cs_gfx00 | cs_avic | cs_tc1 | cs_spr | cs_bmp | cs_pic | cs_sema | cs_mut);
wire cs_bridge2 = (cs_rnd | cs_kbd | cs_aud | cs_1761 | cs_cmdc | cs_grid | cs_imem | cs_eth);

assign pa_i = {11'h0,btnc,btnu,btnd,btnl,btnr,8'h00,sw};

reg ack1 = 1'b0;
reg ack1a = 1'b0;
assign ack = ack_scr|ack_bridge1|ack_bridge2|ack_bridge3|dram_ack;
//assign ack = ack_br;
always @(posedge cpu_clk)
	ack1a <= ack;
always @(posedge cpu_clk)
	ack1 <= ack1a & ack;
always @(posedge cpu_clk)
casez({cs_scr,cs_bridge1,cs_bridge2,cs_dram,cs_bridge3})
5'b1????: dati <= scr_dato;
5'b01???: dati <= br1_cdato;
5'b001??: dati <= br2_cdato;
5'b0001?: dati <= dram_dato;
5'b00001: dati <= br3_cdato;
default:   dati <= dati;
endcase

wire br1_ack1 = tc1_ack|spr_ack|bmp_ack|avic_ack|ack_pic|ack_sema|ack_mut;
reg br1_ack1a;
always @(posedge cpu_clk)
	br1_ack1a <= br1_ack1;
always @(posedge cpu_clk)
	br1_ack <= br1_ack1a & br1_ack1;

always @(posedge cpu_clk)
casez({cs_tc1,cs_spr,cs_bmp,avic_ack,cs_pic,cs_sema,cs_mut})
7'b1???????:	br1_dati <= tc1_dato;
7'b01??????:	br1_dati <= spr_dato;
7'b001?????:	br1_dati <= bmp_cdato;
7'b0001????:	br1_dati <= avic_dato;
7'b00001??:	br1_dati <= {2{pic_dato}};
7'b000001?:	br1_dati <= {8{sema_dato}};
7'b0000001:	br1_dati <= mut_dato;
default:	br1_dati <= br1_dati;
endcase

wire br2_ack1 = rnd_ack|kbd_ack|ack_1761|aud_ack|cs_cmdc|cs_grid|cs_imem|eth_ack;
reg br2_ack1a;
always @(posedge cpu_clk)
	br2_ack1a <= br2_ack1;
always @(posedge cpu_clk)
	br2_ack <= br2_ack1a & br2_ack1;

always @(posedge cpu_clk)
casez({cs_rnd,cs_kbd,aud_ack,cs_eth})
4'b1???:	br2_dati <= {2{rnd_dato}};	// 32 bits reflected twice
4'b01??:	br2_dati <= {8{kbd_dato}};	// 8 bits reflect 8 times
4'b001?:	br2_dati <= aud_cdato;			// 64 bit peripheral
4'b0001:	br2_dati <= {2{eth_cdato}};
default:	br2_dati <= br2_dati;
endcase

via6522 uvia1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.irq_o(via_irq),
	.cs_i(cs_via),
	.cyc_i(br3_cyc),
	.stb_i(br3_stb),
	.ack_o(via_ack),
	.we_i(br3_we),
	.sel_i(br3_sel32),
	.adr_i(br3_adr32[5:2]),
	.dat_i(br3_dat32),
	.dat_o(via_dato), 
	.pa(),
	.pa_i(pa_i),
	.pa_o(pa_o),
	.pb(),
	.ca1(),
	.ca2(),
	.cb1(),
	.cb2()
);


`ifdef TEXT_CONTROLLER
TextController64 #(.num(1)) tc1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_tc1),
	.cti_i(cti),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(tc1_ack),
	.wr_i(br1_we),
	.sel_i(br1_sel),
	.adr_i(br1_adr[16:0]),
	.dat_i(br1_dato),
	.dat_o(tc1_dato),
	.lp_i(),
	.dot_clk_i(clk40),
	.hsync_i(hSync),
	.vsync_i(vSync),
	.blank_i(blank),
	.border_i(border),
	.zrgb_i(bmp_rgb),
	.zrgb_o(tc1_rgb),
	.xonoff_i(sw[3])
);
assign red = spr_rgbo[23:16];
assign green = spr_rgbo[15:8];
assign blue = spr_rgbo[7:0];
`endif

wire vb_irq;
`ifdef BMP_CONTROLLER
rtfBitmapController5 #(.MDW(BMPW)) ubmc1
(
	.rst_i(rst),
	.s_clk_i(cpu_clk),
	.s_cs_i(cs_bmp),
	.s_cyc_i(br1_cyc),
	.s_stb_i(br1_stb),
	.s_ack_o(bmp_ack),
	.s_we_i(br1_we),
	.s_sel_i(br1_sel),
	.s_adr_i(br1_adr[11:0]),
	.s_dat_i(br1_dato),
	.s_dat_o(bmp_cdato),
	.irq_o(),
	.m_clk_i(clk40),
	.m_cyc_o(bmp_cyc),
	.m_stb_o(bmp_stb),
	.m_ack_i(bmp_acki),
	.m_we_o(bmp_we),
	.m_sel_o(bmp_sel),
	.m_adr_o(bmp_adr),
	.m_dat_i(bmp_dati),
	.m_dat_o(bmp_dato),
	.dot_clk_i(clk40),
	.hsync_o(hSync),
	.vsync_o(vSync),
	.blank_o(blank),
	.border_o(border),
	.hctr_o(hctr),
	.vctr_o(vctr),
	.fctr_o(fctr),
	.vblank_o(vb_irq),
	.zrgb_o(bmp_rgb),
	.xonoff_i(sw[2])
);
`else
assign bmp_ack = 1'b0;
assign bmp_cdato = 64'd0;
assign bmp_cyc = 1'b0;
assign bmp_stb = 1'b0;
assign bmp_we = 1'b0;
assign bmp_sel = 8'h00;
assign bmp_adr = 32'h0;
assign bmp_dato = 64'h0;
assgin vb_irq = 1'b0;
`endif

`ifdef SPRITE_CONTROLLER
rtfSpriteController2 usc2
(
	.clk_i(cpu_clk),
	.cs_i(cs_spr),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(spr_ack),
	.we_i(br1_we),
	.sel_i(br1_sel),
	.adr_i(br1_adr[11:0]),
	.dat_i(br1_dato),
	.dat_o(spr_dato),
	.m_clk_i(clk40),
	.m_cyc_o(spr_cyc),
	.m_stb_o(spr_stb),
	.m_ack_i(spr_acki),
	.m_sel_o(spr_sel),
	.m_adr_o(spr_adr),
	.m_dat_i(spr_dati),
	.m_spriteno_o(spr_spriteno),
	.dot_clk_i(clk40),
	.hsync_i(hSync),
	.vsync_i(vSync),
	.border_i(border),
	.zrgb_i(tc1_rgb),
	.zrgb_o(spr_rgbo),
	.test(sw[1])
);
`else
assign spr_ack = 1'b0;
assign spr_dato = 64'd0;
assign spr_cyc = 1'b0;
assign spr_stb = 1'b0;
assign spr_sel = 1'b0;
assign spr_adr = 1'b0;
assign spr_spriteno = 1'b0;
`endif


IOBridge64 u_video_bridge
(
	.rst_i(rst),
	.clk_i(cpu_clk),

	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge1),
	.s1_sel_i(sel),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br1_cdato),

	.s2_cyc_i(cyc2),
	.s2_stb_i(stb2),
	.s2_ack_o(ack_bridge1a),
	.s2_sel_i(sel2),
	.s2_we_i(we2),
	.s2_adr_i(adr2),
	.s2_dat_i(dato2),
	.s2_dat_o(br1_cdato2),
/*
	.s2_cyc_i(grid_cyc),
	.s2_stb_i(grid_stb),
	.s2_ack_o(ack_s2_bridge1),
	.s2_sel_i(grid_sel << {grid_adr[3:2],2'b0}),
	.s2_we_i(grid_we),
	.s2_adr_i(grid_adr),
	.s2_dat_i({4{grid_dato}}),
	.s2_dat_o(br1_s2_cdato),
*/
	.m_cyc_o(br1_cyc),
	.m_stb_o(br1_stb),
	.m_ack_i(br1_ack),
	.m_we_o(br1_we),
	.m_sel_o(br1_sel),
	.m_adr_o(br1_adr),
	.m_dat_i(br1_dati),
	.m_dat_o(br1_dato),
	.m_sel32_o(br1_sel32),
	.m_adr32_o(br1_adr32),
	.m_dat32_o(br1_dat32)
);

IOBridge64 u_bridge2
(
	.rst_i(rst),
	.clk_i(cpu_clk),

	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge2),
	.s1_sel_i(sel),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br2_cdato),

	.s2_cyc_i(cyc2),
	.s2_stb_i(stb2),
	.s2_ack_o(ack_bridge2a),
	.s2_sel_i(sel2),
	.s2_we_i(we2),
	.s2_adr_i(adr2),
	.s2_dat_i(dato2),
	.s2_dat_o(br2_cdato2),

	.m_cyc_o(br2_cyc),
	.m_stb_o(br2_stb),
	.m_ack_i(br2_ack),
	.m_we_o(br2_we),
	.m_sel_o(br2_sel),
	.m_adr_o(br2_adr),
	.m_dat_i(br2_dati),
	.m_dat_o(br2_dato),
	.m_sel32_o(br2_sel32),
	.m_adr32_o(br2_adr32),
	.m_dat32_o(br2_dat32),
	.m_dat8_o(br2_dat8)
);

PS2kbd u_kybd1
(
	// WISHBONE/SoC bus interface 
	.rst_i(rst),
	.clk_i(cpu_clk),	// system clock
	.cs_i(cs_kbd),
  .cyc_i(br2_cyc),
  .stb_i(br2_stb),
  .ack_o(kbd_ack),
  .we_i(br2_we),
  .adr_i(br2_adr32[3:0]),
  .dat_i(br2_dat8),
  .dat_o(kbd_dato),
  .kclk(kclk),
  .kd(kd),
	.db(),
	//-------------
  .irq(kbd_irq)
);

scratchmem uscr1
(
  .rst_i(rst),
  .clk_i(cpu_clk),
  .cti_i(3'b000),
  .bok_o(),
  .cs_i(cs_scr),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_scr),
  .we_i(we),
  .sel_i(sel),
  .adr_i(adr[15:0]),
  .dat_i(dato),
  .dat_o(scr_dato)
);


Thor2020 ucpu1
(
	.rst(rst),
	.clk(cpu_clk),
	.icyc_o(icyc),
	.istb_o(),
	.iack_i(icyc),
	.iadr_o(iadr),
	.idat_i(128'd0),
	.cyc_o(cyc),
	.stb_o(stb),
	.ack_i(ack1),
	.we_o(we),
	.sel_o(sel),
	.adr_o(adr),
	.dat_o(dato),
	.dat_i(dati)
);

IOBridge64 u_bridge3
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge3),
	.s1_sel_i(sel),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br3_cdato),

	.s2_cyc_i(cyc2),
	.s2_stb_i(stb2),
	.s2_ack_o(ack_bridge3a),
	.s2_sel_i(sel2),
	.s2_we_i(we2),
	.s2_adr_i(adr2),
	.s2_dat_i(dato2),
	.s2_dat_o(br3_cdato2),

	.m_cyc_o(br3_cyc),
	.m_stb_o(br3_stb),
	.m_ack_i(br3_ack),
	.m_we_o(br3_we),
	.m_sel_o(br3_sel),
	.m_adr_o(br3_adr),
	.m_dat_i(br3_dati),
	.m_dat_o(br3_dato),
	.m_sel32_o(br3_sel32),
	.m_adr32_o(br3_adr32),
	.m_dat32_o(br3_dat32),
	.m_dat8_o(br3_dat8)
);

wire br3_ack1 = rtc_ack|spi_ack|sdc_ack|pti_ack|uart_ack|via_ack|eeprom_ack;
reg br3_ack1a;
always @(posedge cpu_clk)
	br3_ack1a <= br3_ack1;
always @(posedge cpu_clk)
	br3_ack <= br3_ack1a & br3_ack1;

//wire [8:0] uart_rd_data_count;
//wire uart_tx_fifo_full;
wire [7:0] eeprom_cdato;

always @(posedge cpu_clk)
casez({cs_rtc,spi_ack,sdc_ack,cs_pti,cs_uart,cs_via,cs_eeprom})
7'b1??????:	br3_dati <= {8{rtc_cdato}};
7'b01?????:	br3_dati <= {8{spi_dato}};
7'b001????:	br3_dati <= {2{sdc_cdato}};
7'b0001???:	br3_dati <= {8{pti_cdato}};
7'b00001??:	br3_dati <= {2{uart_dato}};
7'b000001?:	br3_dati <= {2{via_dato}};
7'b0000001:	br3_dati <= {8{eeprom_cdato}};
default:	br3_dati <= br3_dati;
endcase

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

uart6551 uuart1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_uart),
	.irq_o(uart_irq),
	.cyc_i(br3_cyc),
	.stb_i(br3_stb),
	.ack_o(uart_ack),
	.we_i(br3_we),
	.sel_i(br3_sel32),
	.adr_i(br3_adr32[3:2]),
	.dat_i(br3_dat32),
	.dat_o(uart_dato),
	.cts_ni(1'b0),
	.rts_no(),
	.dsr_ni(1'b0),
	.dcd_ni(1'b0),
	.dtr_no(),
	.ri_ni(1'b1),
	.rxd_i(uart_rxd),
	.txd_o(uart_txd),
	.data_present(),
	.rxDRQ_o(),
	.txDRQ_o(),
	.xclk_i(clk14),
	.RxC_i(1'b0)
);


endmodule
