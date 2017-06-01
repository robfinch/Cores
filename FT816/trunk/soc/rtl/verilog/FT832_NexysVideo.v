`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT832_NexysVideo.v
//  - Top Module for 32 bit CPU
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

`define TRUE 	1'b1
`define FALSE	1'b0

`define CLK_FREQ    25000000

module FT832_NexysVideo(cpu_resetn, btnl, btnr, btnc, btnd, btnu, xclk, led, sw,
    kclk, kd,
    TMDS_OUT_clk_n, TMDS_OUT_clk_p,
    TMDS_OUT_data_n, TMDS_OUT_data_p,
    spiClkOut, spiDataIn, spiDataOut, spiCS_n,
    rtc_clk, rtc_data
    /* 
    //UartTx, UartRx,
    ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_reset_n,ddr3_ras_n,ddr3_cas_n,ddr3_we_n,
    ddr3_ba,ddr3_addr,ddr3_dq,ddr3_dqs_p,ddr3_dqs_n,ddr3_dm,ddr3_odt
    */
);
parameter SIM="FALSE";
parameter SIM_BYPASS_INIT_CAL = "OFF";
input cpu_resetn;
input btnl;
input btnr;
input btnc;
input btnd;
input btnu;
input xclk;
input [7:0] sw;
output [7:0] led;
reg [7:0] led;
inout kclk;
tri kclk;
inout kd;
tri kd;
output TMDS_OUT_clk_n;
output TMDS_OUT_clk_p;
output [2:0] TMDS_OUT_data_n;
output [2:0] TMDS_OUT_data_p;
output spiCS_n;
output spiClkOut;
output spiDataOut;
input spiDataIn;
inout rtc_clk;
inout rtc_data;

//output UartTx;
//input UartRx;
/*
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
*/
wire xreset = ~cpu_resetn;
wire irq = ~btnu;

//reg [32:0] rommem [4095:0];
wire rw;
wire vda,vpa;
wire [31:0] ad;
tri [7:0] db;
wire cs0,cs1,cs4,cs5,cs6;
wire rst;
wire vclk,vclk2,vclk10;
wire blank,border,hSync,vSync;
wire [24:0] tc_rgb, tc2_rgb;
wire clk100,clk200u,clk85u,clk,sys_clk,clko,clk50;
wire ub_sys_clk;
wire mem_ui_clk;
wire mpmc_rdy;
wire [7:0] mpmc_dato;
reg [7:0] mpmc_dati;
reg [31:0] mpmc_ad;
reg mpmc_rw;
reg mpmc_cs;
reg mpmc_vda,mpmc_vpa;
wire [7:0] cpu_dato;
wire [7:0] red, blue,green;
wire [7:0] spi_dato;
wire spi_rdy;
wire [7:0] i2c_dato;
wire i2c_rdy;

wire cs_basic = ~cs5;//(vpa|vda) && ad[31:14]==18'h000B;    // $1Cxxx
wire cs_ram = (~cs6) && ad[31:20]!=12'h00F && !cs_basic;// && ad[23:15]!=9'h000;
wire cs_rom = ~cs4;//(vpa|vda) && ad[23:15]==9'h1;
wire cs_kbd = ad[31:4]==28'h00FEA11;
wire cs_psg = ad[31:12]==20'h00FEB;
wire cs_spi = vda && (ad[31:8]==24'h00FEC0);
wire cs_i2c = ad[31:8]==24'h00FEC1;

wire kbd_rdy;
wire psg_rdy;

/*WaitStates #(.WAIT_STATES(3)) u_wait_rom
(
	.rst(rst),
	.clk(clko),
	.cs(rom_cs),
	.rdy(rom_rdy)
);*/

/*
wire [7:0] romo;
bootrom ubr
(
    .clk(clko),
    .ad(ad[13:0]),
    .o(romo)
);
*/
wire [7:0] basromo;
basicrom ubasr
(
    .clk(clko),
    .ad(ad[13:0]),
    .o(basromo)
);


wire [31:0] romo;
syncRom4kx32 urom (
	.clk(clko),
	.cs(~cs_rom),  // active low here
	.ce(1'b1),
	.adr(ad[13:2]),
	.data(romo)
);
defparam
`include "..\..\software\asm\FTBios816.vdp"

reg [7:0] ramdo;

wire locked;
wire clk_fb;


clkgen1366x768_Nexys4ddr #(.pClkFreq(`CLK_FREQ)) ucg1
(
	.xreset(xreset),
	.xclk(xclk),
	.rst(rst),
	.clk100(clk100),
	.clk25(),
	.clk50(clk50),
//	.clk125(eth_gtxclk),
	.clk200(clk200),
	.clk300(clk300),
	.vclk(vclk),
	.sys_clk(ub_sys_clk),
//	.dram_clk(dram_clk),
	.locked(locked),
	.pulse1000Hz(pulse1000Hz),
	.pulse100Hz(pulse100Hz)
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

wire tc_rdy;
rtfTextController816 tc1
(
	.rst(rst),
	.clk(clko),
	.rdy(tc_rdy),
	.rw(rw),
	.vda(vda),
	.ad(ad),
	.db(db),
	.vclk(vclk),
	.hsync(hSync),
	.vsync(vSync),
	.blank(blank),
	.border(border),
	.rgbIn(25'h0),
	.rgbOut(tc_rgb)
);

wire tc2_rdy;
rtfTextController816 #(.pTextAddress(32'h00FB0000), .pRegAddress(32'h00FEA010)) tc2
(
	.rst(rst),
	.clk(clko),
	.rdy(tc2_rdy),
	.rw(rw),
	.vda(vda),
	.ad(ad),
	.db(db),
	.vclk(vclk),
	.hsync(hSync),
	.vsync(vSync),
	.blank(blank),
	.border(border),
	.rgbIn(tc_rgb),
	.rgbOut(tc2_rgb)
);

assign red = sw[1] ? tc_rgb[23:16] : tc2_rgb[23:16];
assign green = sw[1] ? tc_rgb[15:8] : tc2_rgb[15:8];
assign blue = sw[1] ? tc_rgb[7:0] : tc2_rgb[7:0];

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

spiMaster uspi1
(
  .clk_i(clko),
  .rst_i(rst),
  .address_i(ad[7:0]),
  .data_i(db),
  .data_o(spi_dato),
  .strobe_i(cs_spi),
  .we_i(~rw),
  .ack_o(),
  .rdy_o(spi_rdy),

  // SPI logic clock
  .spiSysClk(clko),

  //SPI bus
  .spiClkOut(spiClkOut),
  .spiDataIn(spiDataIn),
  .spiDataOut(spiDataOut),
  .spiCS_n(spiCS_n)
);

wire i2c_scl_pado;
wire i2c_scl_paden;
wire i2c_sda_pado;
wire i2c_sda_paden;

i2c_master_top ui2c1
(
	.wb_clk_i(clko),
	.wb_rst_i(rst),
	.arst_i(~rst), // signal is active low
	.cs_i(cs_i2c),
	.rdy_o(i2c_rdy),
	.wb_adr_i(ad[3:0]),
	.wb_dat_i(db),
	.wb_dat_o(i2c_dato),
	.wb_we_i(~rw),
	.wb_stb_i(vda),
	.wb_cyc_i(vda),
	.wb_ack_o(),
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

wire [7:0] psg_dato;
wire [17:0] psg_out;
PSG32 #(.BUS_WID(8)) usnd1
(
    .rst_i(rst),
    .clk_i(clko),
    .clk50_i(clk50),
    .cs_i(cs_psg),
    .cyc_i(vda),
    .stb_i(vda),
    .ack_o(),
    .rdy_o(psg_rdy),
    .we_i(~rw),
    .adr_i(ad[8:0]),
    .dat_i(db),
    .dat_o(psg_dato),
	.m_adr_o(),
	.m_dat_i(),
	.o(psg_out)
);

wire daco;
PSGPWMDac udac1
(
    .rst(rst),
    .clk(clk200),
    .i(psg_out[17:6]),
    .o(daco)
);
assign aud_sd = 1'b1;
assign aud_pwm = daco ? 1'bz : 1'b0;

wire kbd_rst;
wire kbd_cs = vda && ad[31:4]==28'h00FEA11;
wire [7:0] kbd_dato;
wire kbda;

Ps2Keyboard u_ps2kbd
(
	.rst_i(rst),
	.clk_i(xclk), // 100 MHz
	.cs(cs_kbd),
	.rdy(kbd_rdy),
	.vda(vda),
	.rw(rw),
	.ad(ad[1:0]),
	.dati(db),
	.dato(kbd_dato),
	.kclk(kclk),
	.kd(kd)
);

PRNG u_prng
(
	.rst(rst),
	.clk(clko),
	.vda(vda),
	.rw(rw),
	.ad(ad),
	.db(db),
	.rdy(prng_rdy)
);

wire cs_flt = vda & (ad[31:8]==24'h00FEA2);
wire flt_rdy;
FT816Float u_flt
(
	.rst(rst),
	.clk(clko),
	.vda(vda),
	.rw(rw),
	.ad(ad),
	.db(db),
	.rdy(flt_rdy)
);

always @(posedge clko)
if (~locked)
	led <= 8'h00;
else begin
	if (~cs0 && ~rw && ad[7:0]==8'h00)
		led[7:0] <= db;
end

/*
reg rom_rdy;
always @(posedge clk)
    rom_rdy <= rom_cs;
*/
reg rrdy1,rrdy2,ramrdy;
always @(posedge clko)
    rrdy1 <= cs_ram;
always @(posedge clko)
    rrdy2 <= rrdy1 & cs_ram;
always @(posedge clko)
    ramrdy <= rrdy2 & cs_ram;
wire ram_rdy = cs_ram ? (~rw ? 1'b1 : ramrdy) : 1'b1;

wire [7:0] ramo;
ram1024k uram1 (
  .clka(clko),    // input wire clka
  .ena(cs_ram),      // input wire ena
  .wea(~rw),      // input wire [0 : 0] wea
  .addra(ad),  // input wire [19 : 0] addra
  .dina(db),    // input wire [7 : 0] dina
  .douta(ramo)  // output wire [7 : 0] douta
);

    
reg [7:0] ro;
always @(posedge clko)
case(ad[1:0])
2'd0:	ro <= romo[7:0];
2'd1:	ro <= romo[15:8];
2'd2:	ro <= romo[23:16];
2'd3:	ro <= romo[31:24];
endcase

reg [7:0] db1;
always @*
    if (~cs1) db1 <= sw;
    else if (cs_rom) db1 <= ro;
    else if (cs_basic) db1 <= basromo;
    else if (cs_ram) db1 <= ramo;
    else if (cs_psg) db1 <= psg_dato;
    else if (cs_kbd) db1 <= kbd_dato;
    else if (cs_spi) db1 <= spi_dato;
    else if (cs_i2c) db1 <= i2c_dato;
    else db1 <= 8'h00;

assign db = rw ? db1 : 8'bz;

//assign db = (rw & ram_cs) ? ramdo : {8{1'bz}};
//wire ram_rdy = (~cs6 && 0) ? (~rw ? 1'b1 : ramrdy) : 1'b1;
//wire rm_rdy = rom_cs ? rom_rdy : 1'b1;

FT832mpu u1
(
	.rst(~rst),
	.clk(ub_sys_clk),
	.clko(clko),
	.phi11(),
	.phi12(),
	.phi81(),
	.phi82(),
	.rdy(prng_rdy & tc_rdy & tc2_rdy & flt_rdy & psg_rdy & ram_rdy & kbd_rdy & spi_rdy & i2c_rdy),
	.e(),
	.mx(),
	.nmi(~kbd_rst),
	.irq1(1'b1),
	.irq2(1'b1),
	.irq3(~btnu),
	.abort(1'b1),
	.be(1'b1),
	.vpa(vpa),
	.vda(vda),
	.mlb(),
	.vpb(),
	.rw(rw),
	.ad(ad),
	.db(db),
	.cs0(cs0),
	.cs1(cs1),
	.cs2(),
	.cs3(),
	.cs4(cs4),
	.cs5(cs5),
	.cs6(cs6)
);

endmodule
