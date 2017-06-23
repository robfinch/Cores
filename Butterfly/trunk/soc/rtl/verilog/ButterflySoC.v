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
module ButterflySoC(cpu_resetn, xclk, btnl, btnr, btnc, btnd, btnu, led, sw,
    kclk, kd,
    TMDS_OUT_clk_n, TMDS_OUT_clk_p,
    TMDS_OUT_data_n, TMDS_OUT_data_p, 
//    rs485_re_n, rs485_txd, rs485_rxd, rs485_de,
    rtc_clk, rtc_data,
    TMDS_IN_clk_n, TMDS_IN_clk_p,
    TMDS_IN_data_n, TMDS_IN_data_p, 
    eth_mdio, eth_mdc, eth_rst_b, eth_rxclk, eth_rxd, eth_rxctl, eth_txclk, eth_txd, eth_txctl,
    ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_reset_n,ddr3_ras_n,ddr3_cas_n,ddr3_we_n,
    ddr3_ba,ddr3_addr,ddr3_dq,ddr3_dqs_p,ddr3_dqs_n,ddr3_dm,ddr3_odt
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
input TMDS_IN_clk_n;
input TMDS_IN_clk_p;
input [2:0] TMDS_IN_data_n;
input [2:0] TMDS_IN_data_p;
inout tri rtc_clk;
inout tri rtc_data;
//output rs485_re_n;
//output rs485_txd;
//input rs485_rxd;
//output rs485_de;
inout eth_mdio;
output eth_mdc;
output eth_rst_b;
input eth_rxclk;
inout [3:0] eth_rxd;
input eth_rxctl;
output eth_txclk;
output [3:0] eth_txd;
output eth_txctl;

output [0:0] ddr3_ck_p;
output [0:0] ddr3_ck_n;
output [0:0] ddr3_cke;
output ddr3_reset_n;
output ddr3_ras_n;
output ddr3_cas_n;
output ddr3_we_n;
output [2:0] ddr3_ba;
output [14:0] ddr3_addr;
inout [15:0] ddr3_dq;
inout [1:0] ddr3_dqs_p;
inout [1:0] ddr3_dqs_n;
output [1:0] ddr3_dm;
output [0:0] ddr3_odt;

wire xreset = ~cpu_resetn;
wire rst;
wire clk, clk100, clk80, clk200, clk400, clk1200;
wire mem_ui_clk;
wire hSync,vSync;
wire blank,border;
wire [7:0] red, green, blue;
wire [7:0] tc1_dato,tc2_dato;
wire tc1_ack,tc2_ack;
wire [23:0] tc1_rgb;
wire [23:0] tc2_rgb;
wire [23:0] b_rgb;
wire eth_ack,eth_ramack;
wire [7:0] eth_dato;
wire [7:0] eth_ramdato;

wire cyc11,stb11,we11;
wire [15:0] adr11;
wire [7:0] dato11;
wire cyc21,stb21,we21;
wire [15:0] adr21;
wire [7:0] dato21;
wire cyc31,stb31,we31;
wire [15:0] adr31;
wire [7:0] dato31;
wire cyc41,stb41,we41;
wire [15:0] adr41;
wire [7:0] dato41;
wire cyc42,stb42,we42;
wire [15:0] adr42;
wire [7:0] dato42;

wire b_cyc;
wire b_stb;
wire b_ack;
wire b_we;
wire [31:0] b_adr;
wire [127:0] b_dati;
wire [127:0] b_dato;

clkgen u2
(
    .xreset(xreset),
    .xclk(xclk),
    .rst(rst),
    .clk25(eth_txclk),
    .clk100(clk100),
    .clk200(clk200),
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
wire cs_eth = adr31[15:12]==4'hA;
wire cs_leds3 = (adr31[15:4]==12'hB20) && cyc31 && stb31;
wire cs_ethram = adr31[15:14]==2'b01;   //$4000-$7FFF
wire cs_i2c = adr41[15:4]==12'hB30;

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
        led[2:0] <= dato11[2:0];
always @(posedge clk)
    if (cs_leds2 & we42)
        led[5:3] <= dato42[2:0];
always @(posedge clk)
    if (cs_leds3 & we31)
        led[7:6] <= dato31[1:0];

wire leds_ack = cs_leds;
wire leds_ack2 = cs_leds2;
wire leds_ack3 = cs_leds3;

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
assign red = sw[1] ? b_rgb[23:16] : sw[0] ? tc2_rgb[23:16] : tc1_rgb[23:16];
assign green = sw[1] ? b_rgb[15:8] : sw[0] ? tc2_rgb[15:8] : tc1_rgb[15:8];
assign blue = sw[1] ? b_rgb[7:0] : sw[0] ? tc2_rgb[7:0] : tc1_rgb[7:0];

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
    .kd(kd)
);

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

wire eth_rxclk25, eth_txclk25;
wire eth_m10 = 1'b0;
wire eth_m100 = 1'b1;
wire eth_rxcrs;
wire eth_rxdv;
wire [3:0] eth_rxdi;
wire eth_rxerri;
wire eth_rxcoli;
wire eth_txeno;
wire [3:0] eth_txdo;
assign eth_rst_b = ~rst;
wire eth_wbm_cyc;
wire eth_wbm_stb;
wire eth_wbm_we;
wire eth_wbm_ack;
wire [3:0] eth_wbm_sel;
wire [31:2] eth_wbm_adr;
wire [31:0] eth_wbm_dato;
wire [31:0] eth_wbm_dati;
wire eth_wbm_cs_ram = eth_wbm_adr[31:14]==18'h01 && eth_wbm_cyc && eth_wbm_stb;
wire eth_md_pad_o;
wire mden;

reg eth_rdy1, eth_rdy2;
reg eth_wbm_rdy1, eth_wbm_rdy2;
always @(posedge clk)
    eth_rdy1 <= cs_ethram;
always @(posedge clk)
    eth_rdy2 <= eth_rdy1 & cs_ethram;
always @(posedge clk)
    eth_wbm_rdy1 <= eth_wbm_cs_ram;
always @(posedge clk)
    eth_wbm_rdy2 <= eth_wbm_rdy1 & eth_wbm_cs_ram;
assign eth_wbm_ack = eth_wbm_cs_ram ? (eth_wbm_we ? 1'b1 : eth_wbm_rdy2) : 1'b0; 
assign eth_ramack = cs_ethram ? (we31 ? 1'b1 : eth_rdy2) : 1'b0;

// 16kB true dual-ported ethernet buffer ram
eth_rambuf uethram1
(
  .clka(clk),    // input wire clka
  .ena(cs_ethram),      // input wire ena
  .wea(we31),      // input wire [0 : 0] wea
  .addra(adr31[13:0]),  // input wire [13 : 0] addra
  .dina(dato31),    // input wire [7 : 0] dina
  .douta(eth_ramdato),  // output wire [7 : 0] douta
  .clkb(clk),    // input wire clkb
  .enb(eth_wbm_cs_ram),      // input wire enb
  .web({4{eth_wbm_we}} & eth_wbm_sel),      // input wire [3 : 0] web
  .addrb(eth_wbm_adr[13:2]),  // input wire [11 : 0] addrb
  .dinb(eth_wbm_dato),    // input wire [31 : 0] dinb
  .doutb(eth_wbm_dati)  // output wire [31 : 0] doutb
);

ethmac uethmac1
(
  .cs_i(cs_eth),

  // WISHBONE common
  .wb_clk_i(clk),
  .wb_rst_i(rst),
  .wb_dat_i(dato31),
  .wb_dat_o(eth_dato), 

  // WISHBONE slave
  .wb_adr_i(adr31[11:0]),
  .wb_we_i(we31),
  .wb_cyc_i(cyc31),
  .wb_stb_i(stb31),
  .wb_ack_o(eth_ack),
  .wb_err_o(), 

  // WISHBONE master
  .m_wb_adr_o(eth_wbm_adr),
  .m_wb_sel_o(eth_wbm_sel),
  .m_wb_we_o(eth_wbm_we), 
  .m_wb_dat_o(eth_wbm_dato),
  .m_wb_dat_i(eth_wbm_dati),
  .m_wb_cyc_o(eth_wbm_cyc), 
  .m_wb_stb_o(eth_wbm_stb),
  .m_wb_ack_i(eth_wbm_ack),
  .m_wb_err_i(), 

  .m_wb_cti_o(),
  .m_wb_bte_o(), 

  //TX
  .mtx_clk_pad_i(eth_txclk),
  .mtxd_pad_o(eth_txd),
  .mtxen_pad_o(eth_txctl),
  .mtxerr_pad_o(),

  //RX
  .mrx_clk_pad_i(eth_rxclk),
  .mrxd_pad_i(eth_rxdi),
  .mrxdv_pad_i(eth_rxctl),
  .mrxerr_pad_i(),
  .mcoll_pad_i(),
  .mcrs_pad_i(),
  
  // MIIM
  .mdc_pad_o(eth_mdc),
  .md_pad_i(eth_mdio),
  .md_pad_o(eth_md_pad_o),
  .md_padoe_o(mden),

  .int_o()
);
assign eth_mdio = mden ? eth_md_pad_o : 1'bz;

/*
MII2RMIIRx umii2
(
    .rst(rst),
    .clk50(clk50),
    .clk25(eth_rxclk25),
    .m100(eth_m100),
    .m10(eth_m10),
	.rx_crs_dv_i(eth_crsdv),
	.rxd_i(eth_rxd),
	.rx_err_i(eth_rxerr),
	.rx_col_i(),
	.rx_rs_i(),

	.rx_crs_o(eth_rxcrs),
	.rx_dv_o(eth_rxdv),
	.rxd_o(eth_rxdi),
	.rx_err_o(eth_rxerri),
	.rx_col_o(eth_rxcoli),
	.rx_rs_o()
);

MII2RMIITx umii1
(
    .rst(rst),
    .clk50(clk50),
    .clk25(eth_txclk25),
    .m100(eth_m100),
    .m10(eth_m10),
    .tx_en_i(eth_txeno),
    .tx_en_o(eth_txen),
    .txd_i(eth_txdo),
    .txd_o(eth_txd)
);
*/
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

wire i2c_scl_pado;
wire i2c_scl_paden;
wire i2c_sda_pado;
wire i2c_sda_paden;
wire i2c_ack;
wire [7:0] i2c_dato;

i2c_master_top ui2c1
(
	.wb_clk_i(clk),
	.wb_rst_i(rst),
	.arst_i(~rst), // signal is active low
	.cs_i(cs_i2c),
	.rdy_o(),
	.wb_adr_i(adr41[3:0]),
	.wb_dat_i(dato41),
	.wb_dat_o(i2c_dato),
	.wb_we_i(we41),
	.wb_stb_i(stb41),
	.wb_cyc_i(cyc41),
	.wb_ack_o(i2c_ack),
	.wb_inta_o(),
	.scl_pad_i(rtc_clk),
	.scl_pad_o(i2c_scl_pado),
	.scl_padoen_o(i2c_scl_paden),
	.sda_pad_i(rtc_data),
	.sda_pad_o(i2c_sda_pado),
	.sda_padoen_o(i2c_sda_paden)
);

assign rtc_clk = ~i2c_scl_paden ? i2c_scl_pado : 1'bz;
assign rtc_data = ~i2c_sda_paden ? i2c_sda_pado : 1'bz;

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

DDRcontrol uddr3
(
      .clk_200MHz_i(clk200),
      .ui_clk(mem_ui_clk),
      .rst_i(rst),
      .cs_ram(b_cyc & b_stb),
      .ram_a(b_adr[28:0]),
      .ram_dq_i(b_dato),
      .ram_dq_o(b_dati),
      .ram_cen(!(b_cyc & b_stb)),
      .ram_oen(b_we),
      .ram_wen(~b_we),
      .ram_bs(16'hFFFF),
      .ram_ack(b_ack),
      
      .ddr3_addr(ddr3_addr),
      .ddr3_ba(ddr3_ba),
      .ddr3_ras_n(ddr3_ras_n),
      .ddr3_cas_n(ddr3_cas_n),
      .ddr3_reset_n(ddr3_reset_n),
      .ddr3_we_n(ddr3_we_n),
      .ddr3_ck_p(ddr3_ck_p),
      .ddr3_ck_n(ddr3_ck_n),
      .ddr3_cke(ddr3_cke),
      .ddr3_dm(ddr3_dm),
      .ddr3_odt(ddr3_odt),
      .ddr3_dq(ddr3_dq),
      .ddr3_dqs_p(ddr3_dqs_p),
      .ddr3_dqs_n(ddr3_dqs_n)
);

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

grid u1
(
    .rst_i(rst),
    .clk_i(clk),
    .clk100(clk100),
    .clk200(clk200),
    .clk400(clk400),

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

    .cyc31(cyc31),
    .stb31(stb31),
    .ack31(eth_ack|eth_ramack|leds_ack3),
    .we31(we31),
    .adr31(adr31),
    .dati31(cs_ethram ? eth_ramdato : eth_dato),
    .dato31(dato31), 

    .cyc41(cyc41),
    .stb41(stb41),
    .ack41(i2c_ack),
    .we41(we41),
    .adr41(adr41),
    .dati41(i2c_dato),
    .dato41(dato41), 

    .cyc42(cyc42),
    .stb42(stb42),
    .ack42(tc2_ack|leds_ack2),
    .we42(we42),
    .adr42(adr42),
    .dati42(tc2_dato),
    .dato42(dato42),

    .gr_clki_p(TMDS_IN_clk_p),
    .gr_clki_n(TMDS_IN_clk_n),
    .gr_seri_p(TMDS_IN_data_p),
    .gr_seri_n(TMDS_IN_data_n),
    .gr_clko_p(),
    .gr_clko_n(),
    .gr_sero_p(),
    .gr_sero_n(),

    .mem_ui_clk(mem_ui_clk),
    .b_cyc(b_cyc),
    .b_stb(b_stb),
    .b_ack(b_ack),
    .b_we(b_we),
    .b_adr(b_adr),
    .b_dati(b_dati),
    .b_dato(b_dato),
    .vclk(clk80),
    .hsync(hSync),
    .vsync(vSync),
    .blank(blank),
    .rgbo(b_rgb)

//    .TMDS_OUT_clk_n(),
//    .TMDS_OUT_clk_p(),
//    .TMDS_OUT_data_n(),
//    .TMDS_OUT_data_p(), 
//    .TMDS_IN_clk_n(TMDS_IN_clk_n),
//    .TMDS_IN_clk_p(TMDS_IN_clk_p),
//    .TMDS_IN_data_n(TMDS_IN_data_n),
//    .TMDS_IN_data_p(TMDS_IN_data_p) 

);
/*
assign rs485_re_n = 1'b0;
assign rs485_de = 1'b1;
*/
endmodule
