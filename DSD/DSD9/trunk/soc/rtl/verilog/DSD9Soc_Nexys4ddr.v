// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// DSD7Soc_Nexys4ddr.v
//  - Top Module for 32 bit DSD7 SoC
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
`define CLK_FREQ    37500000
`define SPRITE_CTRL     1
`define NSPRITES        8
`define PSG             4

module DSD9Soc_Nexys4ddr(cpu_resetn, btnl, btnr, btnc, btnd, btnu, xclk, led, sw, an, ssg, kclk, kd,
    red, green, blue, hSync, vSync,
    UartTx, UartRx,
	aud_pwm, aud_sd,
	ddr2_ck_p,ddr2_ck_n,ddr2_cke,ddr2_cs_n,ddr2_ras_n,ddr2_cas_n,ddr2_we_n,
    ddr2_ba,ddr2_addr,ddr2_dq,ddr2_dqs_p,ddr2_dqs_n,ddr2_dm,ddr2_odt
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
input [15:0] sw;
output [7:0] an;
output [7:0] ssg;
output [15:0] led;
reg [15:0] led;
inout kclk;
tri kclk;
inout kd;
tri kd;
output [3:0] red;
output [3:0] green;
output [3:0] blue;
output hSync;
output vSync;
output UartTx;
input UartRx;
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

wire xreset = ~cpu_resetn;
wire rst;
wire clk100,clk200,clk300;
wire vclk;
wire clk,clk2x,clk2d;
wire locked;
wire pulse1024Hz;
wire mem_ui_clk;

wire cyc;
wire stb;
wire vda;
wire [15:0] sel;
wire [15:0] wsel;
wire wr;
wire [31:0] adr;
wire [127:0] dato;
reg [127:0] dati;
wire ack;
wire resvo,resvi,cres,irq;
wire [5:0] state;

wire blank;
wire border;
wire kbd_irq;
wire vb1_ack;
wire [127:0] vb1_dato;
wire video_cyc;
wire video_stb;
wire video_wr;
wire [3:0] video_sel;
wire [31:0] video_adr;
wire [31:0] video_dato;
wire tc1_ack,tc2_ack,bmc_ack,spr_ack;
wire tc1_cs,tc2_cs,bmc_cs;
wire [31:0] tc1_dato,tc2_dato,bmc_dato,spr_dato;
wire [23:0] tc1_rgb, tc2_rgb, bmc_rgb, lg_rgb, spr_rgb;
wire scr_ack,br_ack;
wire [127:0] scr_dat,br_dat;
wire br_cs;
wire scr_cs;
wire mpmc_cs;

wire iob1_cyc;
wire iob1_stb;
wire iob1_ack;
wire iob1_wr;
wire [31:0] iob1_adr;
wire [31:0] iob1_dat;
wire [127:0] iob1_dato;

wire [127:0] ram_dato;
wire ram_ack;

wire bm_cyc;
wire bm_stb;
wire bm_wr;
wire bm_ack;
wire [15:0] bm_sel;
wire [31:0] bm_adr;
wire [127:0] bm_dato;
wire [127:0] bm_dati;

wire spr_cyc;
wire spr_stb;
wire ack5;
wire [31:0] spr_adr;
wire [31:0] spr_dat;
wire spr_irq;

reg [4:0] btns_dat;
reg [15:0] sw_dat;
wire lg_ack;

wire psg_ack;
wire [31:0] psg_dato;
wire cwt_ack;
wire [15:0] cwt_dato;

// -----------------------------------------------------------------------------
// Clock / Timing Generators
// -----------------------------------------------------------------------------

clkgen1366x768_Nexys4ddr #(.pClkFreq(`CLK_FREQ)) ucg1
(
	.xreset(xreset),
	.xclk(xclk),
	.rst(rst),
	.sys_halfclk(clk2d),
	.clk25(),
//	.clk125(eth_gtxclk),
	.clk200(clk200),
	.clk300(clk300),
	.vclk(vclk),
	.sys_clk(clk),
	.sys_clk2x(clk2x),
//	.dram_clk(dram_clk),
	.locked(locked),
	.pulse1024Hz(pulse1024Hz),
	.pulse30Hz()
);

//VGASyncGen640x480_60Hz u4
WXGASyncGen1366x768_60Hz u4
(
	.rst(rst),
	.clk(vclk),
	.hSync(hSync),
	.vSync(vSync),
	.blank(blank),
	.border(border)
);

// -----------------------------------------------------------------------------
// Address Decoding
// -----------------------------------------------------------------------------
wire cs_kbd  = iob1_adr[31:4]==28'hFFDC000;
wire cs_btns = iob1_cyc && iob1_stb && (iob1_adr[31:4]==28'hFFDC009);
wire cs_leds = iob1_cyc && iob1_stb && (iob1_adr[31:4]==28'hFFDC060);
wire cs_sseg = iob1_cyc && iob1_stb && (iob1_adr[31:4]==28'hFFDC008);
wire cs_psg = (iob1_adr[31:12]==20'hFFD50);
wire cs_cwt = (iob1_adr[31:16]==16'hFFD6);

wire cs_bmc = video_adr[31:12]==20'hFFDC5;
wire cs_tc1 = video_adr[31:16]==16'hFFD0;
wire cs_tc2 = video_adr[31:16]==16'hFFD1;
wire cs_lg  = video_adr[31: 8]==24'hFFD300;
wire cs_spr_ram = (video_adr[31:16]==16'hFFD8 || video_adr[31:16]==16'hFFD9);
wire cs_spr_reg = (video_adr[31:12]==20'hFFDAD);

wire cs_scr = adr[31:14]==18'h0000;
wire cs_br  = adr[31:18]==14'h3FFF;
wire cs_ram = (adr[31:28]==4'h0 || adr[31:27]==5'h1E) && !cs_scr;

// -----------------------------------------------------------------------------
// Buttons
// -----------------------------------------------------------------------------
wire btnu_db,btnd_db,btnl_db,btnr_db,btnc_db;
BtnDebounce bdbu(.clk(clk), .btn_i(btnu), .o(btnu_db));
BtnDebounce bdbd(.clk(clk), .btn_i(btnd), .o(btnd_db));
BtnDebounce bdbl(.clk(clk), .btn_i(btnl), .o(btnl_db));
BtnDebounce bdbr(.clk(clk), .btn_i(btnr), .o(btnr_db));
BtnDebounce bdbc(.clk(clk), .btn_i(btnc), .o(btnc_db));

wire btns_ack = cs_btns;
always @*
    btns_dat <= {27'h0,btnc_db,btnu_db,btnd_db,btnl_db,btnr_db};

// -----------------------------------------------------------------------------
// And LEDs and switches
// -----------------------------------------------------------------------------
wire leds_ack = cs_leds;
always @(posedge clk)
if (rst)
    led <= 16'h0000;
else begin
	if (cs_leds && iob1_wr)
		led[15:0] <= iob1_dat;
//    led[15] <= irq;
//    led[14] <= pulse1024Hz;
      led[13] <= tc1_ack;
end
always @*
    sw_dat <= sw;


// -----------------------------------------------------------------------------
// Seven Segment display
// -----------------------------------------------------------------------------
reg [31:0] addb, ssdat;
always @(posedge clk)
    addb <= sw[15] ? state : btnr ? dato : btnl ? adr : ssdat;

wire sseg_ack = cs_sseg && iob1_wr;
always @(posedge clk)
    if (sseg_ack)
        ssdat <= iob1_dat;


// Seven segment LED driver
seven_seg8 ssd0
(
	.rst(rst),		// reset
	.clk(clk),		// clock
//	.dp(4'b0100),
//	.val(16'h6400),
	.dp({UartTx,UartRx,2'b00,irq,resvo,cres,resvi}),
	.val(addb),
//	.val(ssval),
	.ssLedAnode(an),
	.ssLedSeg(ssg)
);

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
    .cyc_i(iob1_cyc),
    .stb_i(iob1_stb),
    .ack_o(kbd_ack),
    .we_i(iob1_wr),
    .adr_i(iob1_adr[3:0]),
    .dat_i(iob1_dat[7:0]),
    .dat_o(kbd_dato),
    .kclk(kclk),
    .kd(kd),
    .irq_o(kbd_irq)
);

reg [31:0] iob1_dati;
always @*
casex({cs_kbd,cs_leds,cs_btns,cs_sseg,cs_psg,cs_cwt})
6'b1xxxxx:    iob1_dati = {4{kbd_dato}};
6'b01xxxx:    iob1_dati = sw_dat;
6'b001xxx:    iob1_dati = btns_dat;
6'b0001xx:    iob1_dati = 32'h0;
6'b00001x:    iob1_dati = psg_dato;
6'b000001:    iob1_dati = {2{cwt_dato}};
default:    iob1_dati = 32'h0;
endcase

IOBridge iob1
(
    .rst_i(rst),
    .clk_i(clk),

    .s_cyc_i(cyc),
    .s_stb_i(stb),
    .s_ack_o(iob1_ack),
    .s_sel_i(sel),
    .s_we_i(wr),
    .s_adr_i(adr),
    .s_dat_i(dato),
    .s_dat_o(iob1_dato),
    
	.m_cyc_o(iob1_cyc),
	.m_stb_o(iob1_stb),
	.m_ack_i(kbd_ack|sseg_ack|leds_ack|btns_ack|psg_ack|cwt_ack),
	.m_we_o(iob1_wr),
	.m_sel_o(),
	.m_adr_o(iob1_adr),
	.m_dat_i(iob1_dati),
	.m_dat_o(iob1_dat)
);

reg [31:0] video_dati;
always @*
casex({tc2_cs,tc1_cs,cs_bmc,cs_spr_ram|cs_spr_reg})
4'b1xxx:  video_dati = tc2_dato;
4'b01xx:  video_dati = tc1_dato;
4'b001x:  video_dati = bmc_dato;
4'b0001:  video_dati = spr_dato;
default:    video_dati = 32'h0;
endcase

IOBridge vb1
(
    .rst_i(rst),
    .clk_i(clk),

    .s_cyc_i(cyc),
    .s_stb_i(stb),
    .s_ack_o(vb1_ack),
    .s_sel_i(sel),
    .s_we_i(wr),
    .s_adr_i(adr),
    .s_dat_i(dato),
    .s_dat_o(vb1_dato),
    
	.m_cyc_o(video_cyc),
	.m_stb_o(video_stb),
	.m_ack_i(tc1_ack|tc2_ack|bmc_ack|lg_ack|spr_ack),
	.m_we_o(video_wr),
	.m_sel_o(video_sel),
	.m_adr_o(video_adr),
	.m_dat_i(video_dati),
	.m_dat_o(video_dato)
);

lifegame ulg1
(
    .rst_i(rst),
    .clk_i(clk),
    .cs_i(cs_lg),
    .cyc_i(video_cyc),
    .stb_i(video_stb),
    .ack_o(lg_ack),
    .we_i(video_wr),
    .adr_i(video_adr[7:0]),
    .dat_i(video_dato),
    .dat_o(),
    .vclk(vclk),
    .vsync(vSync),
    .hsync(hSync),
    .rgb_i(tc2_rgb),
    .rgb_o(lg_rgb)
);

DSD9_TextController #(.num(1)) tc1
(
	.rst_i(rst),
	.clk_i(clk),
	.cs_i(cs_tc1),
	.cyc_i(video_cyc),
	.stb_i(video_stb),
	.ack_o(tc1_ack),
	.wr_i(video_wr),
	.adr_i(video_adr[15:0]),
	.dat_i(video_dato),
	.dat_o(tc1_dato),
	.lp(),
	.curpos(),
	.vclk(vclk),
	.hsync(hSync),
	.vsync(vSync),
	.blank(blank),
	.border(border),
	.rgbIn(bmc_rgb),
	.rgbOut(tc1_rgb)
);

DSD9_TextController #(.num(2)) tc2
(
	.rst_i(rst),
	.clk_i(clk),
	.cs_i(cs_tc2),
	.cyc_i(video_cyc),
	.stb_i(video_stb),
	.ack_o(tc2_ack),
	.wr_i(video_wr),
	.adr_i(video_adr[15:0]),
	.dat_i(video_dato),
	.dat_o(tc2_dato),
	.lp(),
	.curpos(),
	.vclk(vclk),
	.hsync(hSync),
	.vsync(vSync),
	.blank(blank),
	.border(border),
	.rgbIn(sw[4] ? spr_rgb : tc1_rgb),
	.rgbOut(tc2_rgb)
);

assign red = sw[3] ? lg_rgb[23:20] : sw[2] ? bmc_rgb[23:20] : sw[1] ? tc1_rgb[23:20] : tc2_rgb[23:20];
assign green = sw[3] ? lg_rgb[15:12] : sw[2] ? bmc_rgb[15:12] : sw[1] ? tc1_rgb[15:12] : tc2_rgb[15:12];
assign blue = sw[3] ? lg_rgb[7:4] : sw[2] ? bmc_rgb[7:4] : sw[1] ? tc1_rgb[7:4] : tc2_rgb[7:4];

DSD9_BitmapController ubmc1
(
	.rst_i(rst),
	.s_clk_i(clk),
	.s_cs_i(cs_bmc),
	.s_cyc_i(video_cyc),
	.s_stb_i(video_stb),
	.s_ack_o(bmc_ack),
	.s_we_i(video_wr),
	.s_adr_i(video_adr[11:0]),
	.s_dat_i(video_dato),
	.s_dat_o(bmc_dato),
	.irq_o(),

	.m_clk_i(mem_ui_clk),
	.m_bte_o(),
	.m_cti_o(),
	.m_cyc_o(bm_cyc),
	.m_stb_o(bm_stb),
	.m_ack_i(bm_ack),
	.m_we_o(bm_wr),
	.m_sel_o(bm_sel),
	.m_adr_o(bm_adr),
	.m_dat_i(bm_dati),
	.m_dat_o(bm_dato),
	
	.vclk(vclk),
	.hsync(hSync),
	.vsync(vSync),
	.blank(blank),
	.rgbo(bmc_rgb),
	.xonoff(sw[0])
);

`ifdef SPRITE_CTRL

DSD9_SpriteController #(.pnSpr(`NSPRITES)) u_sc1
(
	// Bus Slave interface
	//------------------------------
	// Slave signals
	.rst_i(rst),			// reset
	.clk_i(clk),			// clock
	.s_cs_ram_i(cs_spr_ram),
	.s_cs_reg_i(cs_spr_reg),
	.s_cyc_i(video_cyc),	// cycle valid
	.s_stb_i(video_stb),	// data transfer
	.s_ack_o(spr_ack),	// transfer acknowledge
	.s_we_i(video_wr),	// write
	.s_sel_i(video_sel),	// byte select
	.s_adr_i(video_adr[16:0]),	// address
	.s_dat_i(video_dato),	// data input
	.s_dat_o(spr_dato),	// data output
	//------------------------------
	// Bus Master Signals
	.m_clk_i(clk),
	.m_cyc_o(spr_cyc),	// cycle is valid
	.m_stb_o(spr_stb),	// strobe output
	.m_ack_i(ack5),	// input data is ready
	.m_adr_o(spr_adr),	// DMA address
	.m_dat_i(spr_dat),	// data input
	//--------------------------
	.vclk(vclk),				// video dot clock
	.hSync(hSync),				// horizontal sync pulse
	.vSync(vSync),				// vertical sync pulse
	.blank(blank),				// blanking signal
	.rgbPriority({tc1_rgb[19],tc1_rgb[3]}),
	.rgbIn(tc1_rgb),			// input pixel stream
	.rgbOut(spr_rgb),	// output pixel stream
	.irq(spr_irq)					// interrupt request
);
`endif

`ifdef PSG
wire psg_cyc;
wire psg_stb;
wire pwt_ack;
wire [13:0] psg_adr;
wire [11:0] pwt_dato;
wire [17:0] psg_out;

PSG32 u_psg
(
	.rst_i(rst),
	.clk_i(clk),
	.cs_i(cs_psg),
	.cyc_i(iob1_cyc),
	.stb_i(iob1_stb),
	.ack_o(psg_ack),
	.we_i(iob1_wr),
	.adr_i(iob1_adr[7:0]),
	.dat_i(iob1_dat),
	.dat_o(psg_dato),
	.m_adr_o(psg_adr),
	.m_dat_i(pwt_dato),
	.o(psg_out)
);

/*
WaveTblMem u_wt1
(
	.rst_i(rst),
	.clk_i(clk),
	.cs_i(cs_cwt),
	.cpu_cyc_i(iob1_cyc),
	.cpu_stb_i(iob1_stb),
	.cpu_ack_o(cwt_ack),
	.cpu_we_i(iob1_wr),
	.cpu_adr_i(iob1_adr),
	.cpu_dat_i(iob1_dat[15:0]),
	.cpu_dat_o(cwt_dato),
	.psg_cyc_i(psg_cyc),
	.psg_stb_i(psg_stb),
	.psg_ack_o(pwt_ack),
	.psg_adr_i(psg_adr),
	.psg_dat_o(pwt_dato)
);
*/
assign cwt_ack = 1'b0;
assign cwt_dato = 32'h00;
assign pwt_ack = 1'b0;
assign pwt_dato = 16'h00;

wire [31:0] acc;

PSGHarmonicSynthesizer uhs1
(
    .rst(rst),
    .clk(clk),
    .test(1'b0),
    .sync(1'b0),
    .freq({32'd91626}), //800 Hz
    .o(acc)
);

wire ds_daco;
wire pwm_daco;
PSGPWMDac #(12) udac2
(
    .rst(rst),
    .clk(clk200),
    .i(sw[14]?acc[27:16]:psg_out[17:6]),
    .o(pwm_daco)
);
assign aud_sd = sw[13];
assign aud_pwm = pwm_daco ? 1'bz : 1'b0;

/*
ds_dac  #(18) udac1
(
	.rst(rst),
	.clk(clk200),
	.di(sw[14]?acc[27:16]:psg_out),
	.o(ds_daco)
);
assign aud_sd = sw[13];
assign aud_pwm = ds_daco ? 1'bz : 1'b0;
*/

`else
assign psg_ack = 1'b0;
assign psg_dato = 16'h0000;
assign aud_sd = 1'b0;
assign aud_pwm = 1'b0;
`endif

wire [11:0] fpga_temp;
FPGAMonitor #(.CLOCKFREQ(75)) u_tmpmon1
(
	.RST_I(rst),
	.CLK_I(clk2x),
	.TEMP_O(fpga_temp)
);

mpmc2 #(.SIM(SIM),.SIM_BYPASS_INIT_CAL(SIM_BYPASS_INIT_CAL)) umpmc1
(
.rst_i(rst),
.clk200MHz(clk200),
.fpga_temp(fpga_temp),
.mem_ui_clk(mem_ui_clk),

.cyc0(bm_cyc),
.stb0(bm_stb),
.ack0(bm_ack),
.sel0(bm_sel),
.we0(bm_wr),
.adr0(bm_adr),
.dati0(bm_dato),
.dato0(bm_dati),
/*
.cyc1(p1_cpu_cyc & p1_cs_mem),
.stb1(p1_cpu_stb & p1_cs_mem),
.ack1(p1_dram_ack),
.we1(p1_cpu_we),
.sel1(p1_cpu_sel),
.adr1({p1_cpu_adr[31:3],3'b000}),
.dati1(p1_cpu_dato),
.dato1(p1_dram_dato),
.sr1(p1_sr),
.cr1(p1_cr),
.rb1(p1_rb),

.cyc2(em_m_cyc & FALSE),
.stb2(em_m_stb),
.ack2(em_m_ack),
.we2(1'b0),//em_m_we),
.sel2(em_m_sel),
.adr2(em_m_adr),
.dati2(em_m_dato),
.dato2(em_m_dati),

.cyc3(gfx_w_cyc),
.stb3(gfx_w_stb),
.ack3(gfx_w_ack),
.we3(gfx_w_we),
.sel3(gfx_w_sel),
.adr3(gfx_w_adr),
.dati3(gfx_w_dat_o),
.dato3(gfx_w_dat_i),

.cyc4(gfx_r_cyc),
.stb4(gfx_r_stb),
.ack4(gfx_r_ack),
.sel4(16'hFFFF),
.we4(gfx_r_we),
.adr4(gfx_r_adr),
.dati4(),
.dato4(gfx_r_dat_i),
*/
.cyc5(spr_cyc),
.stb5(spr_stb),
.ack5(ack5),
.adr5(spr_adr),
.dato5(spr_dat),
/*
.cyc6(sdc_cyc && 0),
.stb6(sdc_stb && 0),
.ack6(sdc_ack),
.we6(sdc_we && 0),
.sel6(sdc_sel),
.adr6(sdc_adr),
.dati6(sdc_dato),
.dato6(sdc_dati),
*/

.cyc1(1'b0),
.stb1(1'b0),
.we1(1'b0),
.sel1(16'h00),
.adr1(32'h0),

.cyc2(1'b0),
.stb2(1'b0),
.we2(1'b0),
.sel2(4'h0),
.adr2(32'h0),

.cyc3(1'b0),
.stb3(1'b0),
.we3(1'b0),
.sel3(16'h0000),
.adr3(32'h0),

.cyc4(1'b0),
.stb4(1'b0),
.we4(1'b0),
.adr4(32'h0),

.cyc6(1'b0),
.stb6(1'b0),
.we6(1'b0),
.sel6(4'h0),
.adr6(32'h0),

.cyc7(cyc),
.stb7(stb),
.cs7(cs_ram),
.ack7(ram_ack),
.we7(wr),
.sel7(sel),
.adr7(adr),
.dati7(dato),
.dato7(ram_dato),
.sr7(resvo),
.cr7(cres),
.rb7(resvi),

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

scratchram uscr1
(
    .rst_i(rst),
    .clk_i(clk),
    .cs_i(cs_scr),
    .cyc_i(cyc),
    .stb_i(stb),
    .wr_i(wr),
    .ack_o(scr_ack),
    .sel_i(wsel),
    .adr_i(adr[13:0]),
    .dat_i(dato),
    .dat_o(scr_dat)
);

bootrom ubr1
(
    .rst_i(rst),
    .clk_i(clk),
    .cs_i(cs_br),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(br_ack),
    .adr_i(adr[16:0]),
    .dat_o(br_dat)
);

wire berr;
BusError #(.pTO(28'd50000)) ube0
(
	.rst_i(rst),
	.clk_i(clk),
	.cyc_i(cyc),
	.ack_i(ack),
	.stb_i(stb),
	.adr_i(adr),
	.err_o(berr)
);

DSD9_mpu u1
(
    .hartid_i(80'd1),
    .rst_i(rst),
    .clk_i(clk),
    .clk2x_i(clk2x),
    .clk2d_i(clk2d),
    .i28(spr_irq),
    .i30(btnc_db),
    .i31(kbd_irq),
    .irq_o(irq),
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .err_i(berr),
    .wr_o(wr),
    .sel_o(sel),
    .wsel_o(wsel),
    .adr_o(adr),
    .dat_i(dati),
    .dat_o(dato),
    .sr_o(resvo),
    .cr_o(cres),
    .rb_i(resvi),
    // Diagnostic
    .state_o(state)
);

always @*
casex({cs_br,cs_scr,cs_ram,vb1_ack,iob1_ack})
5'b1xxxx: dati = br_dat;
5'b01xxx: dati = scr_dat;
5'b001xx: dati = ram_dato;
5'b0001x: dati = vb1_dato;
5'b00001: dati = iob1_dato;
default:    dati = 32'h0;
endcase
//assign dati = vb1_dato|iob1_dato|scr_dat|br_dat|ram_dato;
assign ack = vb1_ack|iob1_ack|scr_ack|br_ack|ram_ack;

endmodule
