`timescale 1ns / 1ps
// ============================================================================
//	(C) 2012,2013,2014,2015  Robert Finch
//	robfinch@<remove>finitron.ca
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
`define SPRITE_CTRL	1
`define NSPRITES	32
//`define ETHMAC	2
`define PSG		4
//`define EPPCTRL	8
//`define TMPDEVICE	16
`define UART	32
`define SDCARD	64
`define GACCEL	128
`define BMPCTRL		256
`define LEDS	512
//`define RASTIRQ	1024
//`define DATETIME	2048
//`define MMU			4096
//`define SUPPORT_FORTH	8192
`define DUAL_CORE	2

`define CLK_FREQ	16666667

// Memory Ports
// 0: cpu read/write
// 1: ethernet controller/epp read/write/mmu read/write
// 2: bitmapped/sprite graphics controller read
// 3: graphics accelerate write
// 4: 
// 5:
 
module FISA64_sys(cpu_resetn, btnl, btnr, btnc, btnu, btnd,
	clk, led, sw, an, ssg, kclk, kd,
	vga_r, vga_g, vga_b, vga_hs, vga_vs,
	led16_r, led16_g, led16_b,
	aud_pwm, aud_sd,
//	BITCLK,AUDSDI,AUDSDO,AUDSYNC,AUDRST,
	ddr2_ck_p,ddr2_ck_n,ddr2_cke,ddr2_cs_n,ddr2_ras_n,ddr2_cas_n,ddr2_we_n,
	ddr2_ba,ddr2_addr,ddr2_dq,ddr2_dqs_p,ddr2_dqs_n,ddr2_dm,ddr2_odt,
	UartRx,UartTx,
//	eppAstb,eppDstb,eppWr,eppDB,eppWait,eppRst,
	spiClkOut,spiDataIn,spiDataOut,spiCS_n,
	sd_clk, sd_card_detect, sd_write_prot, sd_cmd, sd_dat,
//	mdc,mdio,eth_rstn,eth_clk,eth_txen,eth_txd,
//	eth_rxerr,eth_crs_dv,eth_rxd,
//	rst1626,clk1626,dq1626
	scl, sda
);
input cpu_resetn;
input btnl;
input btnr;
input btnc;
input btnu;
input btnd;
input clk;
output [15:0] led;
reg [15:0] led;
input [15:0] sw;
output [7:0] an;
output [7:0] ssg;
inout kclk;
tri kclk;
inout kd;
tri kd;
output [3:0] vga_r;
output [3:0] vga_g;
output [3:0] vga_b;
output vga_hs;
output vga_vs;
output led16_r;
output led16_g;
output led16_b;
inout tri aud_pwm;
output aud_sd;
output ddr2_ck_p;
output ddr2_ck_n;
output ddr2_cke;
output ddr2_cs_n;
output ddr2_ras_n;
output ddr2_cas_n;
output ddr2_we_n;
output [2:0] ddr2_ba;
output [12:0] ddr2_addr;
inout [15:0] ddr2_dq;
inout [1:0] ddr2_dqs_p;
inout [1:0] ddr2_dqs_n;
output [1:0] ddr2_dm;
output ddr2_odt;

inout tri scl;
inout tri sda;

input UartRx;
output UartTx;
//input eppAstb;
//input eppDstb;
//input eppWr;
//inout [7:0] eppDB;
//output eppWait;
//input eppRst;
output spiClkOut;
input spiDataIn;
output spiDataOut;
output spiCS_n;

output sd_clk;
input sd_card_detect;
inout tri sd_cmd;
inout tri [3:0] sd_dat;
input sd_write_prot;

//output mdc;
//inout mdio;
//tri mdio;
//output reg eth_rst;
//input eth_col;
//input eth_rs;
//output eth_clk;
//output eth_txerr;
//output eth_txen;
//output [1:0] eth_txd;
//input eth_rxerr;
//input eth_crs_dv;
//input [1:0] eth_rxd;

//output rst1626;
//output clk1626;
//inout dq1626;
//tri dq1626;

wire xreset = ~cpu_resetn;
wire clk100, clk200, clk86, clk25, ub_clk50, clk50, p1_clk50;
wire pixel_clk;
wire pixel_clk2;
wire pixel_clk10;
wire sys_clk;
wire cpu_clk;
wire pulse1024Hz,pulse60Hz;
wire p60ack,p1000ack;
wire locked;
wire rst;
wire dram_clk;
wire bmp_clk;

wire hsync;
wire vsync;
wire blank;
wire border;

assign vga_hs = hsync;
assign vga_vs = vsync;
assign led16_r = pulse60Hz;
assign led16_g = pulse1024Hz;
assign led16_b = cpu_irq;

reg [7:0] blue, green, red;
//assign blue = 8'h00;
//assign red = 8'h00;
//assign green = {8{!blank}}
wire [63:0] config_rec;
reg [31:0] config_reco;
wire config_rec_ack;
wire Leds_ack;
wire [1:0] bm_bte;
wire [2:0] bm_cti;
wire [5:0] bm_bl;
wire bm_cyc;
wire bm_stb;
wire bm_ack;
wire [31:0] bm_adr_o;
wire [127:0] bm_dat_i;
wire [23:0] bm_rgb;
wire ub_sys_clk;

wire dt_ack;
wire [31:0] dt_dato;

wire spr_ack;
wire [31:0] spr_dato;
wire [23:0] spr_rgb;

wire kbd_rst;
wire kbd_irq;
wire kbd_ack;
wire [7:0] kbd_dato;
wire pic_ack;
wire [31:0] pic_dato;
wire pic2_ack;
wire [31:0] pic2_dato;

wire tc_ack;
wire [31:0] tc_dato;
wire [23:0] tc_rgb;
wire uart_ack;
wire [7:0] uart_dato;
wire psg_ack;
wire [15:0] psg_dato;

wire ga_cyc;
wire ga_stb;
wire bridge3_ack;
wire ga_ack;
wire [3:0] ga_sel;
wire [31:0] ga_adr;
wire [31:0] ga_dato;
wire [31:0] ga_s_dato;
wire rast_irq;
wire rast_ack;
wire [15:0] rast_dato;
wire spi_ack;
wire [31:0] spi_dato;

wire [1:0] em_bte;
wire [2:0] em_cti;
wire [5:0] em_bl;
wire em_m_cyc;
wire em_m_stb;
wire em_m_we;
wire em_m_ack;
wire [3:0] em_m_sel;
wire [31:0] em_m_adr;
wire [31:0] em_m_dato;
wire [31:0] em_s_dato;
wire [31:0] em_m_dati;
wire em_s_ack;
wire em_int;
wire em_erro;
wire bridge5_ack;
wire [31:0] bridge5_dato;

wire scrm_ack;
wire [63:0] scrm_dato;
wire btrm_ack;
wire [63:0] btrm_dato;
wire bas_ack;
wire [63:0] bas_dato;
wire for_ack;
wire [63:0] for_dato;

wire [31:0] s_sdc_dato;
wire s_sdc_ack;
wire [31:0] sdc_adr;
wire [3:0] sdc_sel;
wire [31:0] sdc_dato;
wire [31:0] sdc_dati;
wire sdc_cyc;
wire sdc_stb;
wire sdc_ack;
wire sdc_we;
wire [2:0] sdc_cti;
wire [1:0] sdc_bte;

wire [2:0] cpu_cti;
wire [5:0] cpu_bl;
wire cpu_cyc;
wire cpu_stb;
wire cpu_we;
wire [7:0] cpu_sel;
wire [31:0] cpu_adr;
wire [63:0] cpu_dato;
wire cpu_irq;
wire cpu_irq1;
wire cpu_nmi;
wire p1_cpu_cyc;
wire p1_cpu_stb;
wire p1_cpu_we;
wire [7:0] p1_cpu_sel;
wire [31:0] p1_cpu_adr;
wire [63:0] p1_cpu_dato;
wire p0_sr,p0_cr,p0_rb;
wire p1_sr,p1_cr,p1_rb;
wire p1_btrm_ack;
wire p1_dram_ack;
wire [63:0] p1_btrm_dato;
wire [63:0] p1_dram_dato;
wire [31:0] sys_adr;

wire bridge_ack;
wire [63:0] bridge_dato;
reg [7:0] thread_index;
wire thr_ack;
wire [31:0] thr_dato;
wire thread_area_cs;

wire sema_ack;
wire [7:0] sema_dato;
wire ac97_ack;
wire [15:0] ac97_dato;
wire cwt_ack;
wire [15:0] cwt_dato;

wire mmu1_ack,mmu2_ack;
wire [15:0] mmu1_dato,mmu2_dato;
wire [31:0] mem_adr;
wire tmp_ack;
wire [15:0] tmp_dato;
wire bmp_ack;
wire [31:0] bmp_dato;

wire epp_cyc;
wire epp_stb;
wire epp_ack;
wire epp_we;
wire [3:0] epp_sel;
wire [31:0] epp_adr;
wire [31:0] epp_dati;
wire [31:0] epp_dato;

wire mmu_cyc;
wire mmu_stb;
wire mmu_we;
wire mmu_ack;
wire [3:0] mmu_sel;
wire [31:0] mmu_adr;
wire [31:0] mmu_dati;
wire [31:0] mmu_dato;

wire [2:0] txt_cti;
wire txt_cyc;
wire txt_stb;
wire txt_ack;
wire txt_we;
wire [3:0] txt_sel;
wire [31:0] txt_adr;
wire [31:0] txt_dati;
wire [31:0] txt_dato;

wire [7:0] i2c_dato;
wire i2c_ack;
wire [63:0] rand_dato;
wire rand_ack;

wire iob1_ack;
wire [31:0] iob1_dato;
wire io1_cyc;
wire io1_stb;
wire io1_we;
wire io1_ack;
wire [3:0] io1_sel;
wire [31:0] io1_adr;
wire [31:0] io1_dati;
wire [31:0] io1_dato;

wire iob2_ack;
wire [31:0] iob2_dato;
wire io2_cyc;
wire io2_stb;
wire io2_we;
wire io2_ack;
wire [3:0] io2_sel;
wire [31:0] io2_adr;
wire [31:0] io2_dati;
wire [31:0] io2_dato;

wire iob3_ack;
wire [31:0] iob3_dato;
wire io3_cyc;
wire io3_stb;
wire io3_we;
wire io3_ack;
wire [3:0] io3_sel;
wire [31:0] io3_adr;
wire [31:0] io3_dati;
wire [31:0] io3_dato;

wire iob4_ack;
wire [31:0] iob4_dato;
wire io4_cyc;
wire io4_stb;
wire io4_we;
wire io4_ack;
wire [3:0] io4_sel;
wire [31:0] io4_adr;
wire [31:0] io4_dati;
wire [31:0] io4_dato;

wire iob5_ack;
wire [63:0] iob5_dato;
wire io5_cyc;
wire io5_stb;
wire io5_we;
wire io5_ack;
wire [7:0] io5_sel;
wire [31:0] io5_adr;
wire [63:0] io5_dati;
wire [63:0] io5_dato;

wire flt_ack;
wire [31:0] flt_dato;
wire p1_cs_mem;

wire [31:0] io_adr = cpu_adr[31:0];

wire cpu_ack =
	bridge_ack |
	sema_ack |
	scrm_ack |
	btrm_ack |
	for_ack |
	iob1_ack |
	iob2_ack |
	iob3_ack |
	iob4_ack |
	iob5_ack |
	flt_ack
	;
wire [63:0] cpu_dati =
	sema_dato |
	bridge_dato |
	scrm_dato |
	btrm_dato |
	for_dato |
	{2{iob1_dato}} |
	{2{iob2_dato}} |
	{2{iob3_dato}} |
	{2{iob4_dato}} |
	iob5_dato |
	flt_dato
	;
wire p1_cpu_ack =
    pic2_ack |
	p1_btrm_ack |
	p1_dram_ack
	;
wire [63:0] p1_cpu_dati =
    {2{pic2_dato}} |
	p1_btrm_dato |
	p1_dram_dato
	;
assign io1_ack =
	em_s_ack |
	spi_ack |
	uart_ack |
	s_sdc_ack
	;
assign io1_dati =
	em_s_dato |
	spi_dato |
	{4{uart_dato}} |
	s_sdc_dato
	;
// Audio bridge
assign io2_ack =
	psg_ack |
	ac97_ack |
	cwt_ack
	;
assign io2_dati =
	psg_dato |
	ac97_dato |
	cwt_dato
	;
// Video bridge
assign io3_ack =
	bmp_ack |
	tc_ack |
	spr_ack |
	ga_ack |
	rast_ack
	;
assign io3_dati =
	bmp_dato |
	tc_dato |
	spr_dato |
	ga_s_dato |
	rast_dato
	;
// Low frequency bridge
assign io4_ack =
	config_rec_ack |
	pic_ack |
	kbd_ack |
	tmp_ack |
	Leds_ack |
	i2c_ack
	;
assign io4_dati =
	config_reco |
	pic_dato |
	{4{kbd_dato}} |
	tmp_dato |
	{4{i2c_dato}}
	;
assign io5_ack =
	rand_ack |
	dt_ack
	;
assign io5_dati =
	rand_dato |
	dt_dato
	;

wire [11:0] fpga_temp;
FPGAMonitor u_tmpmon1
(
	.RST_I(rst),
	.CLK_I(clk100),
	.TEMP_O(fpga_temp)
);

  clkgenNexys4ddr u1
   (// Clock in ports
    .CLK_IN(clk),      // IN
    // Clock out ports
    .CLK100(clk100),     // OUT
    .CLK86(clk86),     // OUT
    .CLK200(clk200),     // OUT
    .CLK50(ub_clk50),     // OUT
	.CLK25(clk25),		// OUT SPI clock
	.CLK50ETH(eth_clk),
    // Status and control signals
    .RESET(xreset),// IN
    .LOCKED(locked));      // OUT

assign rst = !locked;

sys_pulse #(.pClkFreq(25000000)) upulse1
(
	.rst(rst),
	.clk50(clk25),
	.pulse1024Hz(pulse1024Hz),
	.pulse30Hza(pulse30Hza),
	.pulse30Hzb(pulse30Hzb)
);

`ifdef LEDS
wire csLeds = io4_cyc && io4_stb && (io4_adr[31:8]==24'hFFDC_06);
assign Leds_ack = csLeds;
reg [7:0] cnt;
reg [15:0] Led1;	// help out the router by providing extra reg
always @(posedge clk50)
if (rst) begin
	led <= 16'h0000;
	Led1 <= 16'h0000;
end
else
begin
	if (csLeds & io4_we) begin
		Led1 <= io4_dato[15:0];
	end
	led <= Led1;
	//Led[0] <= cpu_irq1;
end
`else
assign Leds_ack = 1'b0;
`endif

// Seven segment LED driver
seven_seg8 ssd0
(
	.rst(rst),		// reset
	.clk(clk50),		// clock
//	.dp(4'b0100),
//	.val(16'h6400),
	.dp({8'd0}),
	.val(btnl ? cpu_dato : io_adr),
//	.val(ssval),
	.ssLedAnode(an),
	.ssLedSeg(ssg)
);

/*
`ifdef TMPDEVICE
wire d1626,q1626,en1626;
assign dq1626 = en1626 ? q1626 : 1'bz;
assign d1626 = dq1626;

ds1626io #(.pClkFreq(`CLK_FREQ)) utmp
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cyc_i(io4_cyc),
	.stb_i(io4_stb),
	.ack_o(tmp_ack),
	.we_i(io4_we),
	.adr_i(io4_adr),
	.dat_i(io4_dato[15:0]),
	.dat_o(tmp_dato), 
	.rst1626(rst1626),
	.clk1626(clk1626),
	.d1626(d1626),
	.q1626(q1626),
	.en1626(en1626)
);
`else
assign dq1626 = 1'bz;
assign rst1626 = 1'b0;
assign clk1626 = 1'b0;
`endif
*/

Ps2Keyboard ukbd1
(
	// WISHBONE/SoC bus interface 
	.rst_i(rst),
	.clk_i(clk50),	// system clock
	.cyc_i(io4_cyc),
	.stb_i(io4_stb),
	.ack_o(kbd_ack),
	.we_i(io4_we),
	.adr_i(io4_adr),
	.dat_i(io4_dato[7:0]),
	.dat_o(kbd_dato),
	//-------------
	.kclk(kclk),
	.kd(kd),
	.irq_o(kbd_irq)
);

//VGASyncGen640x480_60Hz u3
WXGASyncGen1366x768_60Hz u3
(
	.rst(rst),
	.clk(clk86),
	.hSync(hsync),
	.vSync(vsync),
	.blank(blank),
	.border(border)
);

rtfTextController3 tc1 (
	.rst_i(rst),
	.clk_i(clk50),
	.cyc_i(io3_cyc),
	.stb_i(io3_stb),
	.ack_o(tc_ack),
	.we_i(io3_we),
	.adr_i(io3_adr),
	.dat_i(io3_dato),
	.dat_o(tc_dato),

	.lp(),
	.curpos(),
	.vclk(clk86),
	.hsync(hsync),
	.vsync(vsync),
	.blank(blank),
	.border(border),
	.rgbIn(bm_rgb),
	.rgbOut(tc_rgb)
);

always @(sw,tc_rgb,bm_rgb,spr_rgb)
	if (sw[0]) begin
		red <= tc_rgb[23:16];
		green <= tc_rgb[15:8];
		blue <= tc_rgb[7:0];
	end
	else if (sw[1]) begin
		red <= bm_rgb[23:16];
		green <= bm_rgb[15:8];
		blue <= bm_rgb[7:0];
	end
	else begin
		red <= spr_rgb[23:16];
		green <= spr_rgb[15:8];
		blue <= spr_rgb[7:0];
	end

assign vga_r = red[7:4];
assign vga_g = green[7:4];
assign vga_b = blue[7:4];

wire spr_cyc;
wire spr_stb;
wire bridge4_ack;
wire spr_we;
wire [3:0] spr_sel;
wire [31:0] spr_adr;
wire [31:0] spr_dat;

wire mem_ui_clk;
wire ack5;
wire cs_mem;

mpmc umpmc1
(
.rst_i(rst),
.clk200MHz(clk200),
.fpga_temp(fpga_temp),
.mem_ui_clk(mem_ui_clk),

.cyc0(bm_cyc),
.stb0(bm_stb),
.ack0(bm_ack),
.adr0(bm_adr_o),
.dato0(bm_dat_i),

.cyc1(p1_cpu_cyc & p1_cs_mem),
.stb1(p1_cpu_stb),
.ack1(p1_dram_ack),
.we1(p1_cpu_we),
.sel1(p1_cpu_sel),
.adr1(p1_cpu_adr),
.dati1(p1_cpu_dato),
.dato1(p1_dram_dato),
.sr1(p1_sr),
.cr1(p1_cr),
.rb1(p1_rb),

.cyc2(em_m_cyc),
.stb2(em_m_stb),
.ack2(em_m_ack),
.we2(em_m_we),
.sel2(em_m_sel),
.adr2(em_m_adr),
.dati2(em_m_dato),
.dato2(em_m_dati),

.cyc3(ga_cyc),
.stb3(ga_stb),
.ack3(bridge3_ack),
.we3(ga_we),
.sel3(ga_sel),
.adr3(ga_adr),
.dati3(ga_dato),
.dato3(),

.cyc4(), .stb4(), .ack4(), .we4(), .adr4(), .dati4(), .dato4(),

.cyc5(spr_cyc),
.stb5(spr_stb),
.ack5(ack5),
.adr5(spr_adr),
.dato5(spr_dat),

.cyc6(sdc_cyc),
.stb6(sdc_stb),
.ack6(sdc_ack),
.we6(sdc_we),
.sel6(sdc_sel),
.adr6(sdc_adr),
.dati6(sdc_dato),
.dato6(sdc_dati),

.cyc7(cpu_cyc & cs_mem),
.stb7(cpu_stb & cs_mem),
.ack7(bridge_ack),
.we7(cpu_we),
.sel7(cpu_sel),
.adr7(mem_adr),
.dati7(cpu_dato),
.dato7(bridge_dato),
.sr7(p0_sr),
.cr7(p0_cr),
.rb7(p0_rb),

.ddr2_dq(ddr2_dq),
.ddr2_dqs_n(ddr2_dqs_n),
.ddr2_dqs_p(ddr2_dqs_p),
.ddr2_addr(ddr2_addr),
.ddr2_ba(ddr2_ba),
.ddr2_ras_n(ddr2_ras_n),
.ddr2_cas_n(ddr2_cas_n),
.ddr2_we_n(ddr2_we_n),
.ddr2_ck_p(ddr2_ck_p),
.ddr2_ck_n(ddr2_ck_n),
.ddr2_cke(ddr2_cke),
.ddr2_cs_n(ddr2_cs_n),
.ddr2_dm(ddr2_dm),
.ddr2_odt(ddr2_odt)
);


/*
wire mden,mdi;
assign eth_txd[7:2] = 6'h0;		// not used
always @(posedge eth_clk)
	eth_rstn <= ~(rst|btnu);
//assign eth_rst = ~(rst|btn[1]);
assign mdio = mden ? mdo : 1'bz;
assign mdi = mdio;
wire [31:0] em_s_dato1;
wire cs_ethmac = io1_cyc && io1_stb && io1_adr[31:12]==20'hFFDC2;
assign em_s_dato = cs_ethmac ? em_s_dato1 : 32'd0;
assign em_bl = 6'd3;	// defined in ethmac_defines

wire cs_bridge5 = em_adr[31:28]==4'h01;// || (thread_area_cs && thread_index!=8'h00);
*/
/*
WB32ToMIG32x2 u_bridge5
(
	.rst_i(rst),
	.clk_i(sys_clk),	// was pixel_clk
`ifdef ETHMAC
	// WISHBONE PORT
	.c1_bte_i(em_bte),				// burst type extension
	.c1_cti_i(em_cti),				// cycle type indicator
	.c1_cyc_i(em_cyc & cs_bridge5),				// cycle in progress
	.c1_stb_i(em_stb & cs_bridge5),				// data strobe
	.c1_ack_o(bridge5_ack),			// acknowledge
	.c1_we_i(em_we),				// write cycle
	.c1_sel_i(em_sel),				// byte lane selects
	.c1_adr_i(em_adr),				// address
	.c1_dat_i(em_dato),			// data 
	.c1_dat_o(em_dati),
	.c1_bl_i(em_bl),				// burst length
`endif
	// WISHBONE PORT
	.c2_bte_i(2'b00),				// burst type extension
	.c2_cti_i(3'b000),				// cycle type indicator

	.c2_cyc_i(mmu_cyc),				// cycle in progress
	.c2_stb_i(mmu_stb),				// data strobe
	.c2_ack_o(mmu_ack),			// acknowledge
	.c2_we_i(mmu_we),				// write cycle
	.c2_sel_i(mmu_sel),				// byte lane selects
	.c2_adr_i(mmu_adr),				// address
	.c2_dat_i(mmu_dato),			// data 
	.c2_dat_o(mmu_dati),
	.c2_bl_i(6'd0),				// burst length

	.c1_cyc_i(epp_cyc),				// cycle in progress
	.c1_stb_i(epp_stb),				// data strobe
	.c1_ack_o(epp_ack),			// acknowledge
	.c1_we_i(epp_we),				// write cycle
	.c1_sel_i(epp_sel),				// byte lane selects
	.c1_adr_i(epp_adr),				// address
	.c1_dat_i(epp_dato),			// data 
	.c1_dat_o(epp_dati),
	.c1_bl_i(6'd0),				// burst length

	// MIG port
	.calib_done(c3_calib_done),
	.cmd_full(c3_p1_cmd_full),
	.cmd_en(c3_p1_cmd_en),
	.cmd_instr(c3_p1_cmd_instr),
	.cmd_bl(c3_p1_cmd_bl),
	.cmd_byte_addr(c3_p1_cmd_byte_addr),

	.rd_en(c3_p1_rd_en),
	.rd_data(c3_p1_rd_data),
	.rd_empty(c3_p1_rd_empty),

	.wr_en(c3_p1_wr_en),
	.wr_mask(c3_p1_wr_mask),
	.wr_data(c3_p1_wr_data),
	.wr_empty(c3_p1_wr_empty),
	.wr_full(c3_p1_wr_full)
);

`ifdef ETHMAC
ethmac uemac1
(
  // WISHBONE common
  .wb_clk_i(cpu_clk),
  .wb_rst_i(rst),

  // WISHBONE slave
  .wb_adr_i(io1_adr[11:2]),
  .wb_sel_i(io1_sel),
  .wb_we_i(io1_we),
  .wb_cyc_i(io1_cyc),
  .wb_stb_i(cs_ethmac),
  .wb_ack_o(em_s_ack),
  .wb_err_o(em_erro),
  .wb_dat_i(io1_dato),
  .wb_dat_o(em_s_dato1),

  // WISHBONE master
  .m_wb_adr_o(em_m_adr),
  .m_wb_sel_o(em_m_sel),
  .m_wb_we_o(em_m_we), 
  .m_wb_dat_o(em_m_dato),
  .m_wb_dat_i(em_m_dati),
  .m_wb_cyc_o(em_m_cyc), 
  .m_wb_stb_o(em_m_stb),
  .m_wb_ack_i(em_m_ack),
  .m_wb_err_i(), 
  .m_wb_cti_o(),
  .m_wb_bte_o(),

  //TX
  .mtx_clk_pad_i(eth_clk),
  .mtxd_pad_o(eth_txd[1:0]),
  .mtxen_pad_o(eth_txen),
  .mtxerr_pad_o(eth_txerr),

  //RX
  .mrx_clk_pad_i(eth_clk),
  .mrxd_pad_i({2'b0,eth_rxd[1:0]}),
  .mrxdv_pad_i(eth_rxdv),
  .mrxerr_pad_i(eth_rxerr),
  .mcoll_pad_i(eth_col),
  .mcrs_pad_i(eth_rs),
  
  // MIIM
  .mdc_pad_o(mdc),
  .md_pad_i(mdi),
  .md_pad_o(mdo),
  .md_padoe_o(mden),

  .int_o(em_int)

  // Bist
`ifdef ETH_BIST
  ,
  // debug chain signals
  .mbist_si_i(),       // bist scan serial in
  .mbist_so_o(),       // bist scan serial out
  .mbist_ctrl_i()        // bist chain shift control
`endif

);
`else
//assign em_bte = 2'b00;
//assign em_cti = 3'b000;
//assign em_bl = 6'd0;
//assign em_cyc = 1'b0;
//assign em_stb = 1'b0;
//assign em_we = 1'b0;
//assign em_sel = 4'd0;
//assign em_adr = 32'd0;
//assign em_dato = 32'd0;
//assign em_ack = 1'b0;
assign em_s_dato1 = 32'd0;
assign eth_dato1 = 32'd0;
assign eth_txd = 4'h0;
assign eth_txen = 1'b0;
assign eth_txerr = 1'b0;
assign mdc = 1'b0;
assign mdo = 1'b0;
assign mden = 1'b0;
`endif
*/
/*
wire [7:0] busEppOut;
wire [7:0] busEppIn;
wire ctlEppDwrOut;
wire ctlEppRdcycleOut;
wire [7:0] regEppAdrOut;
wire HandShareReqIn;
wire ctlEppStartOut;
wire ctlEppDoneIn;

//wire epp_DBT;
//wire [7:0] epp_DBO;
//assign eppDB = epp_DBT ? epp_DBO : 8'hzz;
//assign epp_DBI = eppDB;
//assign eppRst = rst;

//
//usb_epp_imp uepp1
//(
//	.DB_O(epp_DBO),
//	.DB_I(epp_DBI),
//	.DB_T(epp_DBT),
//	.EPP_write(eppWr),
//	.ASTB(eppAstb),
//	.DSTB(eppDstb),
//	.BUSY(eppWait),
//	.EPP_Irpt(),
//	.INT_USB()			// not used
//	.EppRst(eppRst),
//    .Bus2IP_Clk(sys_clk),
//    .Bus2IP_Reset(rst),
//    .Bus2IP_Data()                    : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
//    .Bus2IP_BE                      : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
//    .Bus2IP_RdCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
//    .Bus2IP_WrCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
//    .IP2Bus_Data                    : out std_logic_vector(0 to C_SLV_DWIDTH-1);
//    .IP2Bus_RdAck                   : out std_logic;
//    .IP2Bus_WrAck                   : out std_logic;
//    .IP2Bus_Error                   : out std_logic
//);


`ifdef EPPCTRL
// Epp interface circuit courtesy Diligent
//
EppCtrl ueppctrl
(
	.clk(sys_clk),
	.EppAstb(eppAstb),
	.EppDstb(eppDstb),
	.EppWr(eppWr),
	.EppRst(eppRst),
	.EppDB(eppDB),
	.EppWait(eppWait),
	
	.busEppOut(busEppOut),
	.busEppIn(busEppIn),
	.ctlEppDwrOut(ctlEppDwrOut),
	.ctlEppRdCycleOut(ctlEppRdCycleOut),
	.regEppAdrOut(regEppAdrOut),
	.HandShakeReqIn(HandShakeReqIn),
	.ctlEppStartOut(ctlEppStartOut),
	.ctlEppDoneIn(ctlEppDoneIn)
);

EppToWB ueppwb1
(
	.rst_i(rst),
	.clk_i(sys_clk),

	.eppWr(ctlEppDwrOut),
	.eppRd(ctlEppRdCycleOut),
	.eppAdr(regEppAdrOut),
	.eppDati(busEppOut),
	.eppDato(busEppIn),
	.eppHSReq(HandShakeReqIn),
	.eppDone(ctlEppDoneIn),
	.eppStart(ctlEppStartOut),
	
	.cyc_o(epp_cyc),
	.stb_o(epp_stb),
	.ack_i(epp_ack),
	.we_o(epp_we),
	.sel_o(epp_sel),
	.adr_o(epp_adr),
	.dat_i(epp_dati),
	.dat_o(epp_dato)
);

`else
assign eppDB = 8'hzz;
assign eppWait = 1'b0;
`endif
*/

wire bridge4_cs = spr_adr[31:28]==4'h1;

`ifdef BMPCTRL
rtfBitmapController2 ubmc
(
	.rst_i(rst),

	.s_clk_i(clk50),
	.s_cyc_i(io3_cyc),
	.s_stb_i(io3_stb),
	.s_ack_o(bmp_ack),
	.s_we_i(io3_we),
	.s_adr_i(io3_adr),
	.s_dat_i(io3_dato),
	.s_dat_o(bmp_dato),

	.m_clk_i(clk50),//mem_ui_clk),
	.m_cyc_o(bm_cyc),
	.m_stb_o(bm_stb),
	.m_ack_i(bm_ack),
	.m_adr_o(bm_adr_o),
	.m_dat_i(bm_dat_i),

	.vclk(clk86),
	.hSync(hsync),
	.vSync(vsync),
	.blank(blank),
	.rgbo(bm_rgb),
	.xonoff(sw[15])
);
`else
`endif


`ifdef SPRITE_CTRL

FTSpriteController #(.pnSpr(`NSPRITES)) u_sc1
(
	// Bus Slave interface
	//------------------------------
	// Slave signals
	.rst_i(rst),			// reset
	.clk_i(clk50),			// clock
	.s_cyc_i(io3_cyc),	// cycle valid
	.s_stb_i(io3_stb),	// data transfer
	.s_ack_o(spr_ack),	// transfer acknowledge
	.s_we_i(io3_we),	// write
	.s_sel_i(io3_sel),	// byte select
	.s_adr_i(io3_adr),	// address
	.s_dat_i(io3_dato),	// data input
	.s_dat_o(spr_dato),	// data output
	.vol_o(),			// volatile register
	//------------------------------
	// Bus Master Signals
	.m_clk_i(mem_ui_clk),
	.m_cyc_o(spr_cyc),	// cycle is valid
	.m_stb_o(spr_stb),	// strobe output
	.m_ack_i(ack5),	// input data is ready
	.m_adr_o(spr_adr),	// DMA address
	.m_dat_i(spr_dat),	// data input
	//--------------------------
	.vclk(clk86),				// video dot clock
	.hSync(hsync),				// horizontal sync pulse
	.vSync(vsync),				// vertical sync pulse
	.blank(blank),				// blanking signal
	.rgbIn(tc_rgb),			// input pixel stream
	.rgbOut(spr_rgb),	// output pixel stream
	.irq(spr_irq)					// interrupt request
);
`endif

`ifdef GACCEL
rtfGraphicsAccelerator u_ga1
(
	.rst_i(rst),
	.clk_i(clk50),

	.s_cyc_i(io3_cyc),
	.s_stb_i(io3_stb),
	.s_we_i(io3_we),
	.s_ack_o(ga_ack),
	.s_sel_i(io3_sel),
	.s_adr_i(io3_adr),
	.s_dat_i(io3_dato),
	.s_dat_o(ga_s_dato),

	.m_cyc_o(ga_cyc),
	.m_stb_o(ga_stb),
	.m_we_o(ga_we),
	.m_ack_i(bridge3_ack),
	.m_sel_o(ga_sel),
	.m_adr_o(ga_adr),
	.m_dat_i(),
	.m_dat_o(ga_dato)
);
`else
assign ga_ack = 1'b0;
assign ga_s_dato = 32'd0;
`endif

`ifdef RASTIRQ
RasterIRQ urasti
(
	.rst_i(rst),
	.clk_i(clk50),
	.irq_o(rast_irq),
	.cyc_i(io3_cyc),
	.stb_i(io3_stb),
	.ack_o(rast_ack),
	.we_i(io3_we),
	.adr_i(io3_adr),
	.dat_i(io3_dato[15:0]),
	.dat_o(rast_dato),
	.vclk(pixel_clk),
	.hsync(hsync),
	.vsync(vsync)
);
`else
assign rast_irq = 1'b0;
assign rast_ack = 1'b0;
assign rast_dato = 16'h0000;
`endif

IOBridge uio3 
(
	.rst_i(rst),
	.clk_i(clk50),
	.s_cyc_i(cpu_cyc),
	.s_stb_i(cpu_stb),
	.s_ack_o(iob3_ack),
	.s_sel_i(cpu_sel[7:4]|cpu_sel[3:0]),
	.s_we_i(cpu_we),
	.s_adr_i(io_adr),
	.s_dat_i(cpu_dato[31:0]),
	.s_dat_o(iob3_dato),
	.m_cyc_o(io3_cyc),
	.m_stb_o(io3_stb),
	.m_ack_i(io3_ack),
	.m_we_o(io3_we),
	.m_sel_o(io3_sel),
	.m_adr_o(io3_adr),
	.m_dat_i(io3_dati),
	.m_dat_o(io3_dato)
);

`ifdef UART
rtfSimpleUart #(.pClkFreq(`CLK_FREQ)) uuart
(
	// WISHBONE Slave interface
	.rst_i(rst),		// reset
	.clk_i(clk50),	// eg 100.7MHz
	.cyc_i(io1_cyc),	// cycle valid
	.stb_i(io1_stb),	// strobe
	.we_i(io1_we),			// 1 = write
	.adr_i(io1_adr),		// register address
	.dat_i(io1_dato[7:0]),	// data input bus
	.dat_o(uart_dato),	// data output bus
	.ack_o(uart_ack),		// transfer acknowledge
	.vol_o(),		// volatile register selected
	.irq_o(uart_irq),		// interrupt request
	//----------------
	.cts_ni(1'b0),		// clear to send - active low - (flow control)
	.rts_no(),			// request to send - active low - (flow control)
	.dsr_ni(1'b0),		// data set ready - active low
	.dcd_ni(1'b0),		// data carrier detect - active low
	.dtr_no(),			// data terminal ready - active low
	.rxd_i(UartRx),			// serial data in
	.txd_o(UartTx),			// serial data out
	.data_present_o()
);
`else
assign uart_ack = 1'b0;
assign uart_dato = 8'h00;
assign UartRx = 1'bz;
assign UartTx = 1'b0;
`endif

IOBridge uio2 
(
	.rst_i(rst),
	.clk_i(clk50),
	.s_cyc_i(cpu_cyc),
	.s_stb_i(cpu_stb),
	.s_ack_o(iob2_ack),
	.s_sel_i(cpu_sel[7:4]|cpu_sel[3:0]),
	.s_we_i(cpu_we),
	.s_adr_i(io_adr),
	.s_dat_i(cpu_dato[31:0]),
	.s_dat_o(iob2_dato),
	.m_cyc_o(io2_cyc),
	.m_stb_o(io2_stb),
	.m_ack_i(io2_ack),
	.m_we_o(io2_we),
	.m_sel_o(io2_sel),
	.m_adr_o(io2_adr),
	.m_dat_i(io2_dati),
	.m_dat_o(io2_dato)
);

`ifdef PSG
wire psg_cyc;
wire psg_stb;
wire pwt_ack;
wire [14:0] psg_adr;
wire [11:0] pwt_dato;
wire [17:0] psg_out;

PSG16 #(.pClkDivide(`CLK_FREQ/1000000)) u_psg
(
	.rst_i(rst),
	.clk_i(clk50),
	.cyc_i(io2_cyc),
	.stb_i(io2_stb),
	.ack_o(psg_ack),
	.we_i(io2_we),
	.adr_i(io2_adr),
	.dat_i(io2_dato[15:0]),
	.dat_o(psg_dato),
	.vol_o(),
	.bg(), 
	.m_cyc_o(psg_cyc),
	.m_stb_o(psg_stb),
	.m_ack_i(pwt_ack),
	.m_we_o(),
	.m_adr_o(psg_adr),
	.m_dat_i(pwt_dato),
	.o(psg_out)
);

WaveTblMem u_wt1
(
	.rst_i(rst),
	.clk_i(clk50),
	.cpu_cyc_i(io2_cyc),
	.cpu_stb_i(io2_stb),
	.cpu_ack_o(cwt_ack),
	.cpu_we_i(io2_we),
	.cpu_adr_i(io2_adr),
	.cpu_dat_i(io2_dato[15:0]),
	.cpu_dat_o(cwt_dato),
	.psg_cyc_i(psg_cyc),
	.psg_stb_i(psg_stb),
	.psg_ack_o(pwt_ack),
	.psg_adr_i(psg_adr),
	.psg_dat_o(pwt_dato)
);

wire ds_daco;
ds_dac  #(18) udac1
(
	.rst(rst),
	.clk(clk200),
	.di(psg_out),
	.o(ds_daco)
);

assign aud_sd = sw[15];
assign aud_pwm = ds_daco ? 1'bz : 1'b0;

`else
assign psg_ack = 1'b0;
assign psg_dato = 16'h0000;
assign AUDSYNC = 1'b0;
assign AUDRST = 1'b0;
assign AUDSDO = 1'b0;
`endif

IOBridge uio1 
(
	.rst_i(rst),
	.clk_i(clk50),
	.s_cyc_i(cpu_cyc),
	.s_stb_i(cpu_stb),
	.s_ack_o(iob1_ack),
	.s_sel_i(cpu_sel[7:4]|cpu_sel[3:0]),
	.s_we_i(cpu_we),
	.s_adr_i(io_adr),
	.s_dat_i(cpu_dato[31:0]),
	.s_dat_o(iob1_dato),
	.m_cyc_o(io1_cyc),
	.m_stb_o(io1_stb),
	.m_ack_i(io1_ack),
	.m_we_o(io1_we),
	.m_sel_o(io1_sel),
	.m_adr_o(io1_adr),
	.m_dat_i(io1_dati),
	.m_dat_o(io1_dato)
);

`ifdef SDCARD
wire [7:0] spi_dato1;
wire spi_cs = io1_cyc && io1_stb && io1_adr[31:8]==24'hFFDC05;
assign spi_dato = spi_cs ? {4{spi_dato1}} : 32'h00;

spiMaster #(.pClkFreq(`CLK_FREQ)) uspi1
(
	.clk_i(clk50),
	.rst_i(rst),
	.address_i(io1_adr[7:2]),
	.data_i(io1_dato[7:0]),
	.data_o(spi_dato1),
	.strobe_i(spi_cs),
	.we_i(io1_we),
	.ack_o(spi_ack),

	// SPI logic clock
	// Sync to clk_i causes problems maybe
	.spiSysClk(clk25),	// 25MHz

	//SPI bus
	.spiClkOut(spiClkOut),
	.spiDataIn(spiDataIn),
	.spiDataOut(spiDataOut),
	.spiCS_n(spiCS_n)
);
`else
assign spi_ack = 1'b0;
assign spi_dato = 8'h00;
assign spiClkOut = 1'b0;
assign spiDataIn = 1'bz;
assign spiDataOut = 1'b0;
assign spiCS_n = 1'b1;
`endif

assign cs_mem = cpu_adr[31:28]==4'h0 && cpu_adr[31:15]!=17'h000000 && cpu_adr[31:16]!=16'b00001;// || (thread_area_cs && thread_index!=8'h00);
assign p1_cs_mem = p1_cpu_adr[31:28]==4'h0 && p1_cpu_adr[31:16]!=16'b00001;// || (thread_area_cs && thread_index!=8'h00);

wire km;

assign mem_adr = {cpu_adr[31:2],2'b00};
//assign mmu_ack = 1'b0;
//assign mmu_dato = 16'h0000;

wire scl_pad_o;
wire scl_padoen_o;
wire sda_pad_o;
wire sda_padoen_o;

i2c_master_top u_i2c1
(
	.wb_clk_i(clk50),
	.wb_rst_i(rst),
	.arst_i(1'b1),
	.wb_adr_i(io4_adr),
	.wb_dat_i(io4_dato[7:0]),
	.wb_dat_o(i2c_dato),
	.wb_we_i(io4_we),
	.wb_stb_i(io4_stb),
	.wb_cyc_i(io4_cyc),
	.wb_ack_o(i2c_ack),
	.wb_inta_o(),
	.scl_pad_i(scl),
	.scl_pad_o(scl_pad_o),
	.scl_padoen_o(scl_padoen_o),
	.sda_pad_i(sda),
	.sda_pad_o(sda_pad_o),
	.sda_padoen_o(sda_padoen_o)
);

assign scl = scl_padoen_o ? 1'bz : scl_pad_o;
assign sda = sda_padoen_o ? 1'bz : sda_pad_o;

wire sd_cmd_out;
wire [3:0] sd_dat_out;
wire sd_cmd_oe;
wire sd_dat_oe;

sdc_controller usdcc1
(
  // WISHBONE common
  .wb_clk_i(clk50),
  .wb_rst_i(rst),
  .wb_dat_i(io1_dato),
  .wb_dat_o(s_sdc_dato), 

  // WISHBONE slave
  .wb_adr_i(io1_adr),
  .wb_sel_i(io1_sel),
  .wb_we_i(io1_we),
  .wb_cyc_i(io1_cyc),
  .wb_stb_i(io1_stb),
  .wb_ack_o(s_sdc_ack), 

  // WISHBONE master
  .m_wb_adr_o(sdc_adr),
  .m_wb_sel_o(sdc_sel),
  .m_wb_we_o(sdc_we), 
  .m_wb_dat_o(sdc_dato),
  .m_wb_dat_i(sdc_dati),
  .m_wb_cyc_o(sdc_cyc), 
  .m_wb_stb_o(sdc_stb),
  .m_wb_ack_i(sdc_ack), 
  .m_wb_cti_o(),
  .m_wb_bte_o(),

  //SD BUS
  .sd_cmd_dat_i(sd_cmd),
  .sd_cmd_out_o(sd_cmd_out),
  .sd_cmd_oe_o(sd_cmd_oe),
  .card_detect(sd_card_detect),
  .sd_dat_dat_i(sd_dat),
  .sd_dat_out_o(sd_dat_out),
  .sd_dat_oe_o(sd_dat_oe),
  .sd_clk_o_pad(sd_clk)
 
//  `ifdef SDC_CLK_SEP
//   ,sd_clk_i_pad
//  `endif
//  `ifdef SDC_IRQ_ENABLE
//   ,int_a, int_b, int_c  
//  `endif
);

assign sd_cmd = sd_cmd_oe ? sd_cmd_out : 1'bz;
assign sd_dat = sd_dat_oe ? sd_dat_out : 4'bz;

`ifdef DATETIME
rtfDatetime udt1
(
	// Syscon
	.rst_i(rst),		// reset
	.clk_i(clk50),	// system clock

	// System bus
	.cyc_i(io4_cyc),	// valid bus cycle
	.stb_i(io4_stb),	// data transfer strobe
	.ack_o(dt_ack),		// transfer acknowledge
	.we_i(io4_we),		// 1=write
	.sel_i(io4_sel),	// byte select
	.adr_i(io4_adr),	// address
	.dat_i(io4_dato),	// data input
	.dat_o(dt_dato),	// data output

	.tod(pulse60Hz),	// tod pulse (eg 60 Hz)
	.alarm()			// alarm match
);
`else
assign dt_ack = 1'b0;
assign dt_dato = 32'h0;
`endif

rtfRandom urand1
(	
	.rst_i(rst),
	.clk_i(clk50),
	.cyc_i(io5_cyc),
	.stb_i(io5_stb),
	.ack_o(rand_ack),
	.we_i(io5_we),
	.adr_i(io5_adr),
	.dat_i(io5_dato),
	.dat_o(rand_dato),
	.vol_o()
);


IOBridge uio4 
(
	.rst_i(rst),
	.clk_i(clk50),
	.s_cyc_i(cpu_cyc),
	.s_stb_i(cpu_stb),
	.s_ack_o(iob4_ack),
	.s_sel_i(cpu_sel[7:4]|cpu_sel[3:0]),
	.s_we_i(cpu_we),
	.s_adr_i(io_adr),
	.s_dat_i(cpu_dato[31:0]),
	.s_dat_o(iob4_dato),
	.m_cyc_o(io4_cyc),
	.m_stb_o(io4_stb),
	.m_ack_i(io4_ack),
	.m_we_o(io4_we),
	.m_sel_o(io4_sel),
	.m_adr_o(io4_adr),
	.m_dat_i(io4_dati),
	.m_dat_o(io4_dato)
);

IOBridge64 uio5 
(
	.rst_i(rst),
	.clk_i(clk50),
	.s_cyc_i(cpu_cyc),
	.s_stb_i(cpu_stb),
	.s_ack_o(iob5_ack),
	.s_sel_i(cpu_sel),
	.s_we_i(cpu_we),
	.s_adr_i(io_adr),
	.s_dat_i(cpu_dato),
	.s_dat_o(iob5_dato),
	.m_cyc_o(io5_cyc),
	.m_stb_o(io5_stb),
	.m_ack_i(io5_ack),
	.m_we_o(io5_we),
	.m_sel_o(io5_sel),
	.m_adr_o(io5_adr),
	.m_dat_i(io5_dati),
	.m_dat_o(io5_dato)
);

wire berr;
BusError ube0
(
	.rst_i(rst),
	.clk_i(clk50),
	.cyc_i(cpu_cyc),
	.ack_i(cpu_ack),
	.stb_i(cpu_stb),
	.adr_i(cpu_adr),
	.err_o(berr)
);

wire p1_berr;
BusError ube1
(
	.rst_i(rst),
	.clk_i(p1_clk50),
	.cyc_i(p1_cpu_cyc),
	.ack_i(p1_cpu_ack),
	.stb_i(p1_cpu_stb),
	.adr_i(p1_cpu_adr),
	.err_o(p1_berr)
);

scratchmem uscm1
(
	.rst_i(rst),
	.clk_i(clk50),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(scrm_ack),
	.we_i(cpu_we),
	.sel_i(cpu_sel),
	.adr_i(cpu_adr),
	.dat_i(cpu_dato),
	.dat_o(scrm_dato)
);

`ifdef SUPPORT_FORTH
forth_rom ufigr1
(
	.rst_i(rst),
	.clk_i(clk50),
	.cti_i(cpu_cti),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(for_ack),
	.adr_i(cpu_adr),
	.dat_o(for_dato),
	.perr()
);
`else
assign for_ack = 1'b0;
assign for_dato = 32'h0;
`endif


wire perr;
bootrom_dp ubr1
(
	.rst_i(rst),
	.clk_i(clk50),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(btrm_ack),
	.adr_i(cpu_adr),
	.dat_o(btrm_dato),
	.perr(perr),
	.p1_clk_i(p1_clk50),
	.p1_cyc_i(p1_cpu_cyc),
	.p1_stb_i(p1_cpu_stb),
	.p1_ack_o(p1_btrm_ack),
	.p1_adr_i(p1_cpu_adr),
	.p1_dat_o(p1_btrm_dato),
	.p1_perr(p1_perr)
);

sema_mem usm1
(
	.rst_i(rst),
	.clk_i(clk50),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(sema_ack),
	.we_i(cpu_we),
	.adr_i(cpu_adr),
	.dat_i(cpu_dato[7:0]),
	.dat_o(sema_dato)
);


//assign thr_ack = cpu_cyc && cpu_stb && cpu_adr[33:2]==32'hFFDD0008;
//always @(posedge sys_clk)
//if (rst)
//	thread_index <= 8'h00;
//else begin
//	if (thr_ack & cpu_we)
//		thread_index <= cpu_dato[7:0];
//end
//assign thr_dato = thr_ack ? thread_index : 32'd0;
//assign thread_area_cs = cpu_adr[33:14]==20'h00000;

//assign sys_adr = thread_area_cs ? {cpu_adr[33:22],thread_index,cpu_adr[13:0]} : cpu_adr;
assign sys_adr = cpu_adr;

wire [8:0] vecno;
assign kbd_rst = 1'b0;
wire p1_sri;

FISA64_pic u_pic
(
	.rst_i(rst),		// reset
	.clk_i(ub_clk50),		// system clock
	.cyc_i(io4_cyc),	// cycle valid
	.stb_i(io4_stb),	// strobe
	.ack_o(pic_ack),	// transfer acknowledge
	.we_i(io4_we),		// write
	.adr_i(io4_adr),	// address
	.dat_i(io4_dato),
	.dat_o(pic_dato),
	.vol_o(),			// volatile register selected
	.i1(kbd_rst),
	.i2(pulse1024Hz),
	.i3(pulse30Hza),
	.i4(em_int),
	.i5(),
	.i6(),
	.i7(),
	.i8(uart_irq),
	.i9(p1_sri),
	.i10(),
	.i11(),
	.i12(),
	.i13(rast_irq),
	.i14(spr_irq),
	.i15(kbd_irq),
	.irqo(cpu_irq1),	// normally connected to the processor irq
	.nmii(perr),	// nmi input connected to nmi requester
	.nmio(cpu_nmi),	// normally connected to the nmi of cpu
	.vecno(vecno)
);

wire [8:0] p1_vecno;
wire p1_cpu_irq;

FISA64_pic u_pic2
(
	.rst_i(rst),		// reset
	.clk_i(ub_clk50),		// system clock
	.cyc_i(p1_cpu_cyc),	// cycle valid
	.stb_i(p1_cpu_stb),	// strobe
	.ack_o(pic2_ack),	// transfer acknowledge
	.we_i(p1_cpu_we),		// write
	.adr_i(p1_cpu_adr),	// address
	.dat_i(p1_cpu_dato),
	.dat_o(pic2_dato),
	.vol_o(),			// volatile register selected
	.i1(kbd_rst),
	.i2(),
	.i3(pulse30Hzb),
	.i4(),
	.i5(),
	.i6(),
	.i7(),
	.i8(),
	.i9(),
	.i10(),
	.i11(),
	.i12(),
	.i13(),
	.i14(),
	.i15(),
	.irqo(p1_cpu_irq),	// normally connected to the processor irq
	.nmii(),	// nmi input connected to nmi requester
	.nmio(),	// normally connected to the nmi of cpu
	.vecno(p1_vecno)
);

assign cpu_irq = cpu_irq1 & sw[7];

FISA64 ucpu0 (
	.core_num(0),
	.rst_i(rst),
	.clk_i(ub_clk50),
	.clk_o(clk50),
//	.nmi_i(cpu_nmi),
	.irq_i(cpu_irq),
	.vect_i(vecno),
	.sri_o(),
	.bte_o(), 
	.cti_o(cpu_cti),
	.bl_o(cpu_bl),
	.cyc_o(cpu_cyc),
	.stb_o(cpu_stb),
	.ack_i(cpu_ack),
	.err_i(berr),
	.we_o(cpu_we),
	.sel_o(cpu_sel),
	.adr_o(cpu_adr),
	.dat_i(cpu_dati),
	.dat_o(cpu_dato),
	.sr_o(p0_sr),
	.cr_o(p0_cr),
	.rb_i(p0_rb)
);

`ifdef DUAL_CORE
FISA64 ucpu1 (
	.core_num(1),
	.rst_i(rst),
	.clk_i(ub_clk50),
	.clk_o(p1_clk50),
//	.nmi_i(cpu_nmi),
	.irq_i(p1_cpu_irq),
	.vect_i(p1_vecno),
	.sri_o(p1_sri),
	.bte_o(), 
	.cti_o(),
	.bl_o(),
	.cyc_o(p1_cpu_cyc),
	.stb_o(p1_cpu_stb),
	.ack_i(p1_cpu_ack),
	.err_i(p1_berr),
	.we_o(p1_cpu_we),
	.sel_o(p1_cpu_sel),
	.adr_o(p1_cpu_adr),
	.dat_i(p1_cpu_dati),
	.dat_o(p1_cpu_dato),
	.sr_o(p1_sr),
	.cr_o(p1_cr),
	.rb_i(p1_rb)
);
`else
assign p1_clk50 = 1'b0;
assign p1_cpu_cyc = 1'b0;
assign p1_cpu_stb = 1'b0;
assign p1_cpu_we = 1'b0;
assign p1_cpu_adr = 32'd0;
assign p1_cpu_dato = 32'd0;
assign p1_sr = 1'b0;
assign p1_cr = 1'b0;
`endif

/*
assign p1_clk50 = 1'b0;
assign p1_cpu_cyc = 1'b0;
assign p1_cpu_stb = 1'b0;
assign p1_cpu_sel = 8'h00;
assign p1_cpu_adr = 32'd0;
assign p1_cpu_dato = 64'd0;
*/
/*
Table888Float u_flt
(
	.rst_i(rst),
	.clk_i(sys_clk),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(flt_ack),
	.we_i(cpu_we),
	.adr_i(io_adr),
	.dat_i(cpu_dato),
	.dat_o(flt_dato)
);
*/

`ifdef SPRITE_CTRL
assign config_rec[0] = 1'b1;
`else
assign config_rec[0] = 1'b0;
`endif

`ifdef ETHMAC
assign config_rec[1] = 1'b1;
`else
assign config_rec[1] = 1'b0;
`endif

`ifdef PSG
assign config_rec[2] = 1'b1;
`else
assign config_rec[2] = 1'b0;
`endif

`ifdef EPPCTRL
assign config_rec[3] = 1'b1;
`else
assign config_rec[3] = 1'b0;
`endif

`ifdef TMPDEVICE
assign config_rec[4] = 1'b1;
`else
assign config_rec[4] = 1'b0;
`endif

`ifdef UART
assign config_rec[5] = 1'b1;
`else
assign config_rec[5] = 1'b0;
`endif

`ifdef SDCARD
assign config_rec[6] = 1'b1;
`else
assign config_rec[6] = 1'b0;
`endif

`ifdef GACCEL
assign config_rec[7] = 1'b1;
`else
assign config_rec[7] = 1'b0;
`endif

`ifdef BMPCTRL
assign config_rec[8] = 1'b1;
`else
assign config_rec[8] = 1'b0;
`endif

`ifdef LEDS
assign config_rec[9] = 1'b1;
`else
assign config_rec[9] = 1'b0;
`endif

`ifdef RASTIRQ
assign config_rec[10] = 1'b1;
`else
assign config_rec[10] = 1'b0;
`endif

`ifdef DATETIME
assign config_rec[11] = 1'b1;
`else
assign config_rec[11] = 1'b0;
`endif

`ifdef MMU
assign config_rec[12] = 1'b1;
`else
assign config_rec[12] = 1'b0;
`endif

assign config_rec[31:13] = 19'd0;
assign config_rec[63:32] = `CLK_FREQ;

assign config_rec_ack = io4_cyc && io4_stb && io4_adr[31:4]==28'b1111_1111_1101_1100_1111_1111_1111;	// $FFDCFFF0-$FFDCFFF7
always @(config_rec_ack,config_rec,io4_adr)
if (config_rec_ack)
	case(io4_adr[3:2])
	2'd00:	config_reco <= config_rec[31:0];
	2'd01:	config_reco <= config_rec[63:32];
	default:	config_reco <= 32'd0;
	endcase
else
	config_reco <= 32'd0;

endmodule
