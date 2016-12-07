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
`define CLK_FREQ    25000000

module DSD7Soc_Nexys4ddr(cpu_resetn, btnl, btnr, btnc, btnd, btnu, xclk, led, sw, an, ssg, kclk, kd,
    red, green, blue, hSync, vSync,
    UartTx, UartRx,
	ddr2_ck_p,ddr2_ck_n,ddr2_cke,ddr2_cs_n,ddr2_ras_n,ddr2_cas_n,ddr2_we_n,
    ddr2_ba,ddr2_addr,ddr2_dq,ddr2_dqs_p,ddr2_dqs_n,ddr2_dm,ddr2_odt
);
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

wire clk100,clk200,clk300;
wire vclk;
wire clk,clk2x;
wire locked;
wire pulse1024Hz;
wire mem_ui_clk;

wire cyc;
wire stb;
wire vda;
wire [1:0] sel;
wire wr;
wire [31:0] adr;
wire [31:0] dato;
wire [31:0] dati;
wire ack;
wire resvo,resvi,cres,irq;
wire [5:0] state;

wire vb1_ack;
wire [31:0] vb1_dato;
wire video_cyc;
wire video_stb;
wire video_wr;
wire [31:0] video_adr;
wire [31:0] video_dato;
wire tc1_ack,tc2_ack,bmc_ack;
wire [31:0] tc1_dato,tc2_dato,bmc_dato;
wire [23:0] tc1_rgb, tc2_rgb, bmc_rgb;
wire scr_ack,br_ack;
wire [31:0] scr_dat,br_dat;

wire iob1_cyc;
wire iob1_stb;
wire iob1_ack;
wire iob1_wr;
wire [31:0] iob1_adr;
wire [31:0] iob1_dat,iob1_dato;

wire [31:0] mpmc_dato;
wire mpmc_ack;

wire bm_cyc;
wire bm_stb;
wire bm_wr;
wire bm_ack;
wire [15:0] bm_sel;
wire [31:0] bm_adr;
wire [127:0] bm_dato;
wire [127:0] bm_dati;

reg [4:0] btns_dat;
reg [15:0] sw_dat;

clkgen1366x768_Nexys4ddr #(.pClkFreq(`CLK_FREQ)) ucg1
(
	.xreset(xreset),
	.xclk(xclk),
	.rst(rst),
	.clk100(clk100),
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
// Buttons
// -----------------------------------------------------------------------------
wire btnu_db,btnd_db,btnl_db,btnr_db,btnc_db;
BtnDebounce bdbu(.clk(clk), .btn_i(btnu), .o(btnu_db));
BtnDebounce bdbd(.clk(clk), .btn_i(btnd), .o(btnd_db));
BtnDebounce bdbl(.clk(clk), .btn_i(btnl), .o(btnl_db));
BtnDebounce bdbr(.clk(clk), .btn_i(btnr), .o(btnr_db));
BtnDebounce bdbc(.clk(clk), .btn_i(btnc), .o(btnc_db));

wire cs_btns = iob1_cyc && iob1_stb && (iob1_adr[31:4]==28'hFFDC009);
wire btns_ack = cs_btns;
always @*
    if (cs_btns)
        btns_dat <= {27'h0,btnc_db,btnu_db,btnd_db,btnl_db,btnr_db};
    else
        btns_dat <= 32'h0;

// -----------------------------------------------------------------------------
// And LEDs and switches
// -----------------------------------------------------------------------------
wire cs_leds = iob1_cyc && iob1_stb && (iob1_adr[31:8]==24'hFFDC06);
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
    if (cs_leds)
        sw_dat <= sw;
    else
        sw_dat <= 32'h0;


// -----------------------------------------------------------------------------
// Seven Segment display
// -----------------------------------------------------------------------------
reg [31:0] addb, ssdat;
always @(posedge clk)
    addb <= sw[15] ? state : btnr ? dato : btnl ? adr : ssdat;

wire sseg_ack = iob1_cyc && iob1_stb && iob1_wr && iob1_adr[31:4]==28'hFFDC008;
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
    .cyc_i(iob1_cyc),
    .stb_i(iob1_stb),
    .ack_o(kbd_ack),
    .we_i(iob1_wr),
    .adr_i(iob1_adr),
    .dat_i(iob1_dat),
    .dat_o(kbd_dato),
    .kclk(kclk),
    .kd(kd),
    .irq_o(kbd_irq)
);

IOBridge iob1
(
    .rst_i(rst),
    .clk_i(clk),

    .s_cyc_i(cyc),
    .s_stb_i(stb),
    .s_ack_o(iob1_ack),
    .s_sel_i({{2{sel[1]}},{2{sel[0]}}}),
    .s_we_i(wr),
    .s_adr_i(adr),
    .s_dat_i(dato),
    .s_dat_o(iob1_dato),
    
	.m_cyc_o(iob1_cyc),
	.m_stb_o(iob1_stb),
	.m_ack_i(kbd_ack|sseg_ack|leds_ack|btns_ack),
	.m_we_o(iob1_wr),
	.m_sel_o(),
	.m_adr_o(iob1_adr),
	.m_dat_i({4{kbd_dato}}|btns_dat|sw_dat),
	.m_dat_o(iob1_dat)
);


IOBridge vb1
(
    .rst_i(rst),
    .clk_i(clk),

    .s_cyc_i(cyc),
    .s_stb_i(stb),
    .s_ack_o(vb1_ack),
    .s_sel_i({{2{sel[1]}},{2{sel[0]}}}),
    .s_we_i(wr),
    .s_adr_i(adr),
    .s_dat_i(dato),
    .s_dat_o(vb1_dato),
    
	.m_cyc_o(video_cyc),
	.m_stb_o(video_stb),
	.m_ack_i(tc1_ack|tc2_ack|bmc_ack),
	.m_we_o(video_wr),
	.m_sel_o(),
	.m_adr_o(video_adr),
	.m_dat_i(tc1_dato|tc2_dato|bmc_dato),
	.m_dat_o(video_dato)
);

DSD7_TextController #(.num(1)) tc1
(
	.rst_i(rst),
	.clk_i(clk),
	.cyc_i(video_cyc),
	.stb_i(video_stb),
	.ack_o(tc1_ack),
	.wr_i(video_wr),
	.adr_i(video_adr),
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

DSD7_TextController #(.num(2),.pTextAddress(32'hFFD10000),.pRegAddress(32'hFFDA0100)) tc2
(
	.rst_i(rst),
	.clk_i(clk),
	.cyc_i(video_cyc),
	.stb_i(video_stb),
	.ack_o(tc2_ack),
	.wr_i(video_wr),
	.adr_i(video_adr),
	.dat_i(video_dato),
	.dat_o(tc2_dato),
	.lp(),
	.curpos(),
	.vclk(vclk),
	.hsync(hSync),
	.vsync(vSync),
	.blank(blank),
	.border(border),
	.rgbIn(tc1_rgb),
	.rgbOut(tc2_rgb)
);

assign red =  sw[2] ? bmc_rgb[23:20] : sw[1] ? tc1_rgb[23:20] : tc2_rgb[23:20];
assign green = sw[2] ? bmc_rgb[15:12] : sw[1] ? tc1_rgb[15:12] : tc2_rgb[15:12];
assign blue = sw[2] ? bmc_rgb[7:4] : sw[1] ? tc1_rgb[7:4] : tc2_rgb[7:4];

DSD7_BitmapController ubmc1
(
	.rst_i(rst),
	.s_clk_i(clk),
	.s_cyc_i(video_cyc),
	.s_stb_i(video_stb),
	.s_ack_o(bmc_ack),
	.s_we_i(video_wr),
	.s_adr_i(video_adr),
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


wire [11:0] fpga_temp;
FPGAMonitor u_tmpmon1
(
	.RST_I(rst),
	.CLK_I(clk100),
	.TEMP_O(fpga_temp)
);

mpmc2 umpmc1
(
.rst_i(rst),
.clk200MHz(clk200),
.fpga_temp(fpga_temp),
.mem_ui_clk(mem_ui_clk),

.cyc0(bm_cyc),
.stb0(bm_stb),
.ack0(bm_ack),
.we0(bm_we),
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
.we4(gfx_r_we),
.adr4(gfx_r_adr),
.dati4(),
.dato4(gfx_r_dat_i),

.cyc5(spr_cyc & FALSE),
.stb5(spr_stb),
.ack5(ack5),
.adr5(spr_adr),
.dato5(spr_dat),

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
.sel1(8'h00),
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

.cyc5(1'b0),
.stb5(1'b0),
.adr5(32'h0),

.cyc6(1'b0),
.stb6(1'b0),
.we6(1'b0),
.sel6(4'h0),
.adr6(32'h0),

.cyc7(cyc),
.stb7(stb),
.ack7(mpmc_ack),
.we7(wr),
.sel7({{2{sel[1]}},{2{sel[0]}}}),
.adr7({adr[30:0],1'b0}),
.dati7(dato),
.dato7(mpmc_dato),
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
    .cyc_i(cyc),
    .stb_i(stb),
    .wr_i(wr),
    .ack_o(scr_ack),
    .sel_i(sel),
    .adr_i(adr),
    .dat_i(dato),
    .dat_o(scr_dat)
);

bootrom ubr1
(
    .rst_i(rst),
    .clk_i(clk),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(br_ack),
    .adr_i(adr),
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

DSD7_mpu u1
(
    .hartid_i(32'd1),
    .rst_i(rst),
    .clk_i(clk),
    .i30(btnc_db),
    .i31(kbd_irq),
    .irq_o(irq),
    .cyc_o(cyc),
    .stb_o(stb),
    .vda_o(vda),
    .vpa_o(vpa),
    .ack_i(ack),
    .err_i(berr),
    .wr_o(wr),
    .sel_o(sel),
    .adr_o(adr),
    .dat_i(dati),
    .dat_o(dato),
    .sr_o(resvo),
    .cr_o(cres),
    .rb_i(resvi),
    // Diagnostic
    .state(state)
);

assign dati = vb1_dato|iob1_dato|scr_dat|br_dat|mpmc_dato;
assign ack = vb1_ack|iob1_ack|scr_ack|br_ack|mpmc_ack;

endmodule
