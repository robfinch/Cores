`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	frisc_soc.v
//  - system on a chip
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
// ============================================================================
//
`define NSPRITES  8
`define CLK_FREQ  25000000

module friscv_soc(cpu_resetn, btnl, btnr, btnc, btnd, btnu, xclk, led, sw, an, ssg, 
  red, green, blue, hSync, vSync, UartTx, UartRx,
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
output reg [3:0] red;
output reg [3:0] green;
output reg [3:0] blue;
output hSync;
output vSync;
output UartTx;
input UartRx;
input [15:0] sw;
output [7:0] an;
output [7:0] ssg;
output [15:0] led;
reg [15:0] led;
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
wire [3:0] mas;
wire cyc;
wire stb;
wire we;
wire [3:0] sel;
wire [31:0] adr;
wire [31:0] dato;
wire [31:0] dati;
wire [127:0] net1,net2,net3,net4,net5,net14;
wire tc_ack,ack;
wire [31:0] tc1_dato;
wire [23:0] tc1_out;
wire [23:0] bm_rgbo;

wire bmack;
wire [31:0] s_bm_dato;
wire bm_cyc;
wire bm_stb;
wire bm_ack;
wire bm_we;
wire [31:0] bm_adr_o;
wire [127:0] bm_dat_i;
wire [127:0] mb_dat_o;

wire gfx_ack;
wire [31:0] gfx_dato;

wire gfx_w_cyc;
wire gfx_w_stb;
wire gfx_w_ack;
wire gfx_w_we;
wire [15:0] gfx_w_sel;
wire [31:0] gfx_w_adr;
wire [127:0] gfx_w_dat_i;
wire [127:0] gfx_w_dat_o;

wire gfx_r_clk;
wire gfx_r_cyc;
wire gfx_r_stb;
wire gfx_r_ack;
wire gfx_r_we;
wire [31:0] gfx_r_adr;
wire [127:0] gfx_r_dat_i;

wire spr_ack;
wire [31:0] spr_dato;
wire [23:0] spr_rgb;
wire spr_cyc;
wire spr_stb;
wire ack5;
wire [31:0] spr_adr;
wire [31:0] dato5;

wire mpmc_ack;
wire [31:0] mpmc_dato;
wire [7:0] uart_dato;
wire uart_ack;
wire uart_irq;
wire clk100, clk200, tm_clk;
wire clk, clk2x;
wire mem_ui_clk;
wire vclk;
wire locked;
wire pulse1024Hz, pulse30Hz;

always @*
case(sw[1:0])
2'd0: begin
      red <= tc1_out[23:20];
      green <= tc1_out[15:12];
      blue <= tc1_out[7:4]; 
      end
2'd1: begin
      red <= bm_rgbo[23:20];
      green <= bm_rgbo[15:12];
      blue <= bm_rgbo[7:4];
      end
2'd2: begin
      red <= spr_rgb[23:20];
      green <= spr_rgb[15:12];
      blue <= spr_rgb[7:4];
      end
endcase
//assign red = sw[0] ?   spr_rgb[23:20] : bm_rgbo[23:20];
//assign green = sw[0] ? spr_rgb[15:12] : bm_rgbo[15:12];
//assign blue = sw[0] ?  spr_rgb[7:4]   : bm_rgbo[7:4];

clkgen1366x768_Nexys4ddr #(.pClkFreq(`CLK_FREQ)) ucg1
(
	.xreset(xreset),
	.xclk(xclk),
	.rst(rst),
	.clk100(clk100),
	.clk25(),
//	.clk125(eth_gtxclk),
	.clk200(clk200),
	.tm_clk(tm_clk),
	.vclk(vclk),
	.sys_clk(clk),
	.sys_clk2x(clk2x),
//	.dram_clk(dram_clk),
	.locked(locked),
	.pulse1024Hz(pulse1024Hz),
	.pulse30Hz(pulse30Hz)
);

//VGASyncGen640x480_60Hz u4
WXGASyncGen1366x768_60Hz usg1
(
	.rst(rst),
	.clk(vclk),
	.hSync(hSync),
	.vSync(vSync),
	.blank(blank),
	.border(border)
);

wire bm_berr;
BusError #(.pTO(28'd500)) ubebm0
(
	.rst_i(rst),
	.clk_i(mem_ui_clk),
	.cyc_i(bm_cyc),
	.ack_i(bm_ack),
	.stb_i(bm_stb),
	.adr_i(bm_adr),
	.err_o(bm_berr)
);
/*
BitmapController1360x768x12 ubmp1
(
  .rst(rst),
  .s_clk(clk),
  .s_cyc(cyc),
  .s_stb(stb),
  .s_ack(bmack),
  .s_we(we),
  .s_adr(adr),
  .s_dati(dato),
  .s_dato(),
  .m_clk(mem_ui_clk),
  .m_cyc(bm_cyc),
  .m_stb(bm_stb),
  .m_ack(bm_ack|bm_berr),
  .m_adr(bm_adr_o),
  .m_dati(bm_dat_i),
  .vclk(vclk),
  .hSync(hSync),
  .vSync(vSync),
  .blank(blank),
  .border(),
  .rgbo(bm_rgbo)
);
*/
rtfBitmapController4 ubmc
(
  .rst_i(rst),
  .s_clk_i(clk),
  .s_cyc_i(cyc),
  .s_stb_i(stb),
  .s_ack_o(bmack),
  .s_we_i(we),
  .s_adr_i(adr),
  .s_dat_i(dato),
  .s_dat_o(s_bm_dato), 
  .m_clk_i(mem_ui_clk),
  .m_cyc_o(bm_cyc),
  .m_stb_o(bm_stb),
  .m_we_o(bm_we),
  .m_ack_i(bm_ack|bm_err),
  .m_adr_o(bm_adr),
  .m_dat_i(bm_dat_i),
  .m_dat_o(bm_dat_o),
  .xonoff(sw[2]),
  .vclk(vclk),
  .hsync(hSync),
  .vsync(vSync),
  .blank(blank),
  .rgbo(bm_rgbo)
);

rtfTextController3 #(.num(1), .pTextAddress(32'hFFD00000))  tc1
(
	.rst_i(rst),
	.clk_i(clk),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(tc_ack),
	.we_i(we),
	.adr_i(adr),
	.dat_i(dato),
	.dat_o(tcdato),
	.lp(),
	.curpos(),
	.vclk(vclk),
	.hsync(hSync),
	.vsync(vSync),
	.blank(blank),
	.border(border),
	.rgbIn(bm_rgbo),
	.rgbOut(tc1_out)
);

rtfSimpleUart uuart1
(
	// WISHBONE Slave interface
	.rst_i(rst),		    // reset
	.clk_i(clk),	    // eg 100.7MHz
	.cyc_i(cyc),		// cycle valid
	.stb_i(stb),		// strobe
	.we_i(we),			// 1 = write
	.adr_i(adr),		// register address
	.dat_i(dato[7:0]),	// data input bus
	.dat_o(uart_dato),	    // data output bus
	.ack_o(uart_ack),		// transfer acknowledge
	.vol_o(),		        // volatile register selected
  .irq_o(uart_irq),		// interrupt request
	//----------------
	.cts_ni(1'b0),		// clear to send - active low - (flow control)
	.rts_no(),	// request to send - active low - (flow control)
	.dsr_ni(1'b0),		// data set ready - active low
	.dcd_ni(1'b0),		// data carrier detect - active low
	.dtr_no(),	// data terminal ready - active low
	.rxd_i(UartRx),			// serial data in
	.txd_o(UartTx),			// serial data out
  .data_present_o(),
  .baud16_clk()
);

/*
gfx_top ugfx1
(
	.clk_i(clk),
	.wb_rst_i(rst),
	.wb_inta_o(),
	// Wishbone master signals (interfaces with video memory, write)
	.wbm_write_clk_i(mem_ui_clk),
	.wbm_write_cyc_o(gfx_w_cyc),
	.wbm_write_stb_o(gfx_w_stb),
	.wbm_write_sel_o(gfx_w_sel),
	.wbm_write_cti_o(),
	.wbm_write_bte_o(),
	.wbm_write_we_o(gfx_w_we),
	.wbm_write_adr_o(gfx_w_adr),
	.wbm_write_ack_i(gfx_w_ack),
	.wbm_write_err_i(0),
	.wbm_write_dat_i(gfx_w_dat_i),
	.wbm_write_dat_o(gfx_w_dat_o),
	// Wishbone master signals (interfaces with video memory, read)
	.wbm_read_clk_i(mem_ui_clk),
	.wbm_read_cyc_o(gfx_r_cyc),
	.wbm_read_stb_o(gfx_r_stb),
	.wbm_read_cti_o(),
	.wbm_read_bte_o(),
	.wbm_read_we_o(gfx_r_we),
	.wbm_read_adr_o(gfx_r_adr),
	.wbm_read_ack_i(gfx_r_ack),
	.wbm_read_err_i(0),
	.wbm_read_dat_i(gfx_r_dat_i),
	// Wishbone slave signals (interfaces with main bus/CPU)
	.wbs_clk_i(clk),
	.wbs_cyc_i(cyc),
	.wbs_stb_i(stb),
	.wbs_cti_i(),	// not used
	.wbs_bte_i(),	// not used
	.wbs_we_i(we),
	.wbs_adr_i(adr),
	.wbs_sel_i(sel),
	.wbs_ack_o(gfx_ack),
	.wbs_err_o(),
	.wbs_dat_i(dato),
	.wbs_dat_o(gfx_dato)
);
*/
assign gfx_ack = 1'b0;
/*
rtfSpriteController #(.pnSpr(`NSPRITES)) u_sc1
(
	// Bus Slave interface
	//------------------------------
	// Slave signals
	.rst_i(rst),			// reset
	.clk_i(clk),			// clock
	.s_cyc_i(cyc),	// cycle valid
	.s_stb_i(stb),	// data transfer
	.s_ack_o(spr_ack),	// transfer acknowledge
	.s_we_i(we),	// write
	.s_sel_i(sel),	// byte select
	.s_adr_i(adr),	// address
	.s_dat_i(dato),	// data input
	.s_dat_o(spr_dato),	// data output
	.vol_o(),			// volatile register
	//------------------------------
	// Bus Master Signals
	.m_clk_i(mem_ui_clk),
	.m_cyc_o(spr_cyc),	// cycle is valid
	.m_stb_o(spr_stb),	// strobe output
	.m_ack_i(ack5),	// input data is ready
	.m_adr_o(spr_adr),	// DMA address
	.m_dat_i(dato5),	// data input
	//--------------------------
	.vclk(vclk),				// video dot clock
	.hSync(hSync),				// horizontal sync pulse
	.vSync(vSync),				// vertical sync pulse
	.blank(blank),				// blanking signal
	.rgbIn(tc1_out),			// input pixel stream
	.rgbOut(spr_rgb),	// output pixel stream
	.irq(spr_irq)					// interrupt request
);
*/
assign spr_ack = 1'b0;

wire [11:0] fpga_temp;
FPGAMonitor u_tmpmon1
(
	.RST_I(rst),
	.CLK_I(clk100),
	.TEMP_O(fpga_temp)
);

mpmc2  #(.SIM("TRUE")) umpmc1 
(
.rst_i(rst),
.clk200MHz(clk200),
.fpga_temp(fpga_temp),
.mem_ui_clk(mem_ui_clk),


.cyc0(bm_cyc),
.stb0(bm_stb),
.ack0(bm_ack),
.we0(bm_we),
.adr0(bm_adr_o),
.dati0(bm_dat_o),
.dato0(bm_dat_i),
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

.cyc5(spr_cyc),
.stb5(spr_stb),
.ack5(ack5),
.adr5(spr_adr),
.dato5(dato5),

.cyc6(1'b0),
.stb6(1'b0),
.we6(1'b0),
.sel6(4'h0),
.adr6(32'h0),

.mas7(mas),
.cyc7(cyc),
.stb7(stb),
.ack7(mpmc_ack),
.we7(we),
.sel7(sel),
.adr7(adr),
.dati7(dato),
.dato7(mpmc_dato),
.sr7(1'b0),
.cr7(1'b0),
.rb7(),

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

reg [31:0] addb, ssdat;
always @(posedge clk)
    addb <= btnr ? dato : btnl ? adr : ssdat;

wire sseg_ack = cyc && stb && we && adr[31:4]==28'hFFDC008;
always @(posedge clk)
    if (sseg_ack)
        ssdat <= dato;

// Seven segment LED driver
seven_seg8 ssd0
(
	.rst(rst),
	.clk(clk),
	.dp({UartTx,UartRx,6'b000100}),
	.val(addb),
	.ssLedAnode(an),
	.ssLedSeg(ssg)
);

wire cs_leds = cyc && stb && (adr[31:8]==24'hFFDC06);
wire leds_ack = cs_leds;
always @(posedge clk)
if (rst)
    led <= 16'h0000;
else begin
	if (cs_leds && we)
		led[15:0] <= dato;
//    led[15] <= irq;
    led[14] <= pulse1024Hz;
    led[13] <= pulse30Hz;
end

assign ack = tc_ack|sseg_ack|leds_ack|uart_ack|mpmc_ack|bmack|gfx_ack|spr_ack;
assign dati = tcdato|{4{uart_dato}}|mpmc_dato|gfx_dato|spr_dato|s_bm_dato;

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

friscv_node um1 (2, rst, clk, tm_clk, net14, net1);
friscv_node um2 (3, rst, clk, tm_clk, net1, net2);
friscv_node um3 (4, rst, clk, tm_clk, net2, net3);
//friscv_node um4 (5, rst, clk, tm_clk, net3, net4);
//friscv_node um5 (6, rst, clk, tm_clk, net4, net5);

soci ugdi1 (
  .num(1),
  .rst(rst),
  .clk(clk),
  .neti(net3),
  .neto(net14),
  .mas(mas),
  .cyc(cyc),
  .stb(stb),
  .ack(ack),
  .err(1'b0),//berr),
  .we(we),
  .sel(sel),
  .adr(adr),
  .dati(dati),
  .dato(dato)
);

endmodule
