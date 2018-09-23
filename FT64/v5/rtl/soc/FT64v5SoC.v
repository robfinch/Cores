// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64SoC.v
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
//`define SIM
`define AVIC

module FT64v5SoC(cpu_resetn, xclk, led, sw,
    TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n
`ifndef SIM
    ,ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_reset_n,ddr3_ras_n,ddr3_cas_n,ddr3_we_n,
    ddr3_ba,ddr3_addr,ddr3_dq,ddr3_dqs_p,ddr3_dqs_n,ddr3_dm,ddr3_odt
`endif
//    gtp_clk_p, gtp_clk_n,
//    dp_tx_hp_detect, dp_tx_aux_p, dp_tx_aux_n, dp_rx_aux_p, dp_rx_aux_n,
//    dp_tx_lane0_p, dp_tx_lane0_n, dp_tx_lane1_p, dp_tx_lane1_n
);
input cpu_resetn;
input xclk;
output reg [7:0] led;
input [7:0] sw;
output TMDS_OUT_clk_p;
output TMDS_OUT_clk_n;
output [2:0] TMDS_OUT_data_p;
output [2:0] TMDS_OUT_data_n;
`ifndef SIM
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
`endif
//input gtp_clk_p;
//input gtp_clk_n;
//input dp_tx_hp_detect;
//output dp_tx_aux_p;
//output dp_tx_aux_n;
//input dp_rx_aux_p;
//input dp_rx_aux_n;
//output dp_tx_lane0_p;
//output dp_tx_lane0_n;
//output dp_tx_lane1_p;
//output dp_tx_lane1_n;

wire rst;
wire xrst = ~cpu_resetn;
wire clk20, clk40, clk50, clk80, clk100, clk200, clk400;
wire xclk_bufg;
wire hSync, vSync, blank, border;
wire [7:0] red, blue, green;

wire [2:0] cti;
wire cyc, stb, ack;
wire we;
wire [7:0] sel;
wire [31:0] adr;
reg [63:0] dati;
wire [63:0] dato;
wire sr,cr,rb;

wire [23:0] tc1_rgb;
wire tc1_ack;
wire [31:0] tc1_dato;
wire ack_scr, ack_br;
wire [63:0] scr_dato, br_dato;
wire rnd_ack;
wire [31:0] rnd_dato;
wire dram_ack;
wire [63:0] dram_dato;
wire avic_ack;
wire [63:0] avic_dato;

NexysVideoClkgen ucg1
 (
  // Clock out ports
  .clk100(clk100),
  .clk400(clk400),
  .clk80(clk80),
  .clk20(clk20),
  .clk40(clk40),
  .clk200(clk200),
  // Status and control signals
  .reset(xrst), 
  .locked(locked),       // output locked
 // Clock in ports
  .clk_in1(xclk_bufg)
);
assign rst = !locked;

`ifndef AVIC
WXGASyncGen1280x768_60Hz u4
(
	.rst(rst),
	.clk(clk80),
	.hSync(hSync),
	.vSync(vSync),
	.blank(blank),
	.border(border)
);
`endif

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

//top_level udp1
//(
//    .clk100(clk100),
//    .debug(),
//    .gtptxp({dp_tx_lane1_p,dp_tx_lane0_p}),
//    .gtptxn({dp_tx_lane1_n,dp_tx_lane0_n}),
//    .refclk0_p(gtp_clk_p),
//    .refclk0_n(gtp_clk_n), 
//    .refclk1_p(gtp_clk_p),
//    .refclk1_n(gtp_clk_n),
//    .dp_tx_hp_detect(dp_tx_hp_detect),
//    .dp_tx_aux_p(dp_tx_aux_p),
//    .dp_tx_aux_n(dp_tx_aux_n),
//    .dp_rx_aux_p(dp_rx_aux_p),
//    .dp_rx_aux_n(dp_rx_aux_n)
//);

wire cs_dram = adr[31:29]==3'h0;
wire cs_br = adr[31:18]==14'h3FFF;
wire cs_tc1 = adr[31:16]==16'hFFD0;
wire cs_scr = adr[31:20]==12'hFF4;
wire cs_rnd = adr[31:4]==28'hFFDC0C0;
wire cs_avic = adr[31:13]==19'b1111_1111_1101_1100_110;	// FFDCC000-FFDCDFFF
wire cs_led = cyc && stb && (adr[31:4]==28'hFFDC060);

`ifdef TEXT_CONTROLLER
FT64_TextController #(.num(1)) tc1
(
	.rst_i(rst),
	.clk_i(clk20),
	.cs_i(cs_tc1),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(tc1_ack),
	.wr_i(we),
	.adr_i(adr[15:0]),
	.dat_i(dato[31:0]),
	.dat_o(tc1_dato),
	.lp(),
	.curpos(),
	.vclk(clk80),
	.hsync(hSync),
	.vsync(vSync),
	.blank(blank),
	.border(border),
	.rgbIn(24'd0),
	.rgbOut(tc1_rgb)
);
assign red = tc1_rgb[23:16];
assign green = tc1_rgb[15:8];
assign blue = tc1_rgb[7:0];
`endif

wire [23:0] rgb;
wire vde;
wire vm_cyc, vm_stb, vm_ack, vm_we;
wire [15:0] vm_sel;
wire [31:0] vm_adr;
wire [127:0] vm_dat_o;
wire [127:0] vm_dat_i;
wire [15:0] aud0, aud1, aud2, aud3;
reg [15:0] audi = 16'h0000;
wire [7:0] gst;

`ifndef SIM
AVIC128 uavic1
(
	// Slave port
	.rst_i(rst),
	.clk_i(clk20),
	.cs_i(cs_avic),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(avic_ack),
	.we_i(we),
	.sel_i(sel),
	.adr_i(adr[12:0]),
	.dat_i(dato),
	.dat_o(avic_dat_o),
	// Bus master
	.m_clk_i(clk40),
	.m_cyc_o(vm_cyc),
	.m_stb_o(vm_stb),
	.m_ack_i(vm_ack),
	.m_we_o(vm_we),
	.m_sel_o(vm_sel),
	.m_adr_o(vm_adr),
	.m_dat_i(vm_dat_i),
	.m_dat_o(vm_dat_o),
	// Video port
	.vclk(clk40),
	.hSync(hSync),
	.vSync(vSync),
	.de(vde),
	.rgb(rgb),
	// Audio ports
	.aud0_out(aud0),
	.aud1_out(aud1),
	.aud2_out(aud2),
	.aud3_out(aud3),
	.aud_in(audi),
	// Debug
	.state(gst)
);
assign red = rgb[23:16];
assign green = rgb[15:8];
assign blue = rgb[7:0];
assign blank = ~vde;
`endif

wire ack_led = cs_led;
always @(posedge clk20)
begin
led[0] <= cs_br;
led[1] <= cs_scr;
if (cs_led)
    led <= dato[7:0];
end
wire [7:0] led_dato = sw;

assign ack = ack_scr|ack_led|tc1_ack|ack_br|rnd_ack|dram_ack|avic_ack;
always @*
casez({cs_br,cs_tc1,cs_scr,cs_led,cs_rnd,cs_dram,cs_avic})
7'b1??????: dati <= br_dato;
7'b01?????: dati <= {2{tc1_dato}};
7'b001????: dati <= scr_dato;
7'b0001???: dati <= {8{led_dato}};
7'b00001??: dati <= {2{rnd_dato}};
7'b000001?:	dati <= dram_dato;
7'b000000?:	dati <= avic_dato;
default:    dati <= {2{32'h1C}}; // NOP
endcase

IBUFG #(.IBUF_LOW_PWR("FALSE"),.IOSTANDARD("DEFAULT")) ubg1
(
    .I(xclk),
    .O(xclk_bufg)
);

`ifdef SIM
mainmem_sim umm1
(
	.rst_i(rst),
	.clk_i(clk20),
	.cti_i(cti),
	.cs_i(cs_dram),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(dram_ack),
	.we_i(we),
	.sel_i(sel),
	.adr_i(adr[28:0]),
	.dat_i(dato),
	.dat_o(dram_dato)
);
`endif

`ifndef SIM
mpmc6 umc1
(
	.rst_i(rst),
	.clk100MHz(xclk_bufg),
	.clk200MHz(clk200),
	.mem_ui_clk(mem_ui_clk),

	.cyc0(vm_cyc),
	.stb0(vm_stb),
	.ack0(vm_ack),
	.we0(vm_we),
	.sel0(vm_sel),
	.adr0(vm_adr),
	.dati0(vm_dat_o),
	.dato0(vm_dat_i),

/*
cs1, cyc1, stb1, ack1, we1, sel1, adr1, dati1, dato1, sr1, cr1, rb1,
cyc2, stb2, ack2, we2, sel2, adr2, dati2, dato2,
cyc3, stb3, ack3, we3, sel3, adr3, dati3, dato3,
cyc4, stb4, ack4, we4, sel4, adr4, dati4, dato4,
cyc5, stb5, ack5, adr5, dato5,
cyc6, stb6, ack6, we6, sel6, adr6, dati6, dato6,
cs7, cyc7, stb7, ack7, we7, sel7, adr7, dati7, dato7, sr7, cr7, rb7,
*/
	.cs7(cs_dram),
	.cyc7(cyc),
	.stb7(stb),
	.ack7(dram_ack),
	.we7(we),
	.sel7(sel),
	.adr7(adr),
	.dati7(dato),
	.dato7(dram_dato),
	.sr7(sr),
	.cr7(cr),
	.rb7(rb),

	// DDR3 interface
	.ddr3_dq(ddr3_dq),
	.ddr3_dqs_n(ddr3_dqs_n),
	.ddr3_dqs_p(ddr3_dqs_p),
	.ddr3_addr(ddr3_addr),
	.ddr3_ba(ddr3_ba),
	.ddr3_ras_n(ddr3_ras_n),
	.ddr3_cas_n(ddr3_cas_n),
	.ddr3_we_n(ddr3_we_n),
	.ddr3_ck_p(ddr3_ck_p),
	.ddr3_ck_n(ddr3_ck_n),
	.ddr3_cke(ddr3_cke),
	.ddr3_reset_n(ddr3_reset_n),
	.ddr3_dm(ddr3_dm),
	.ddr3_odt(ddr3_odt),
	// Debugging	
	.state(),
	.ch()
);
`endif


scratchmem uscr1
(
    .rst_i(rst),
    .clk_i(clk20),
    .cti_i(cti),
    .cs_i(cs_scr),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(ack_scr),
    .we_i(we),
    .sel_i(sel),
    .adr_i(adr[14:0]),
    .dat_i(dato),
    .dat_o(scr_dato)
);

bootrom #(64) ubr1
(
    .rst_i(rst),
    .clk_i(clk20),
    .cti_i(cti),
    .cs_i(cs_br),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(ack_br),
    .adr_i(adr[17:0]),
    .dat_o(br_dato)
);

FT64_mpu ucpu1
(
    .hartid_i(64'h1),
    .rst_i(rst),
    .clk_i(clk20),
    .clk4x_i(clk40),
    .tm_clk_i(clk20),
    .i1(1'b0),
    .i2(1'b0),
    .i3(1'b0),
    .i4(1'b0),
    .i5(1'b0),
    .i6(1'b0),
    .i7(1'b0),
    .i8(1'b0),
    .i9(1'b0),
    .i10(1'b0),
    .i11(1'b0),
    .i12(1'b0),
    .i13(1'b0),
    .i14(1'b0),
    .i15(1'b0),
    .i16(1'b0),
    .i17(1'b0),
    .i18(1'b0),
    .i19(1'b0),
    .i20(1'b0),
    .i21(1'b0),
    .i22(1'b0),
    .i23(1'b0),
    .i24(1'b0),
    .i25(1'b0),
    .i26(1'b0),
    .i27(1'b0),
    .i28(1'b0),
    .i29(1'b0),
    .irq_o(),
    .cti_o(cti),
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .err_i(1'b0),
    .we_o(we),
    .sel_o(sel),
    .adr_o(adr),
    .dat_o(dato),
    .dat_i(dati),
    .sr_o(sr),
    .cr_o(cr),
    .rb_i(rb)
);

random	uprg1
(
	.rst_i(rst),
	.clk_i(clk20),
	.cs_i(cs_rnd),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(rnd_ack),
	.we_i(we),
	.adr_i(adr[3:0]|(|sel[7:4]<<2)),
	.dat_i(|sel[7:4] ? dato[63:32] : dato[31:0]),
	.dat_o(rnd_dato)
);

endmodule
