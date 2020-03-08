`define BMP_CONTROLLER	1'b1

module Petajon_SoM(sys_rst, sys_clk_i, clk8, clk14,
	tg_compare_error, led_1, init_calib_complete,
	FA, FD, FSBHE, FALE,
	KBDDAT, KBDCLK, MSEDAT, MSECLK,
	RED, GREEN, BLUE, HS, VS,
`ifndef SIM
    ,ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_reset_n,ddr3_ras_n,ddr3_cas_n,ddr3_we_n,
    ddr3_ba,ddr3_addr,ddr3_dq,ddr3_dqs_p,ddr3_dqs_n,ddr3_dm,ddr3_odt
`endif
);
input sys_rst;
input sys_clk_i;
output clk8;
output clk14;
output reg tg_compare_error;
output reg led_1;
output init_calib_complete;
input [26:0] FA;
inout [15:0] FD;
input FSBHE;
input FALE;
inout KBDDAT;
tri KBDDAT;
inout KBDCLK;
tri KBDCLK;
inout MSEDAT;
tri MSEDAT;
inout MSECLK;
tri MSECLK;
output [3:0] RED;
output [3:0] GREEN;
output [3:0] BLUE;
output HS;
output VS;

`ifndef SIM
output [0:0] ddr3_ck_p;
output [0:0] ddr3_ck_n;
output [0:0] ddr3_cke;
output ddr3_reset_n;
output ddr3_ras_n;
output ddr3_cas_n;
output ddr3_we_n;
output [2:0] ddr3_ba;
output [13:0] ddr3_addr;
inout [15:0] ddr3_dq;
inout [1:0] ddr3_dqs_p;
inout [1:0] ddr3_dqs_n;
output [1:0] ddr3_dm;
output [0:0] ddr3_odt;
`endif

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
wire hSync, vSync;

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

`ifndef SIM
wire mem_ui_rst;
wire calib_complete;
wire rstn;
wire [28:0] mem_addr;
wire [2:0] mem_cmd;
wire mem_en;
wire [127:0] mem_wdf_data;
wire [15:0] mem_wdf_mask;
wire mem_wdf_end;
wire mem_wdf_wren;
wire [127:0] mem_rd_data;
wire mem_rd_data_valid;
wire mem_rd_data_end;
wire mem_rdy;
wire mem_wdf_rdy;
wire [3:0] dram_state;
`endif

wire clk40, clk100, clk200;
wire cpu_clk = clk40;
wire rst, rstn;

Petajon_clkgen ucg1
(
  .clk200(clk200),
  .clk100(clk100),
  .clk40(clk40),
  .reset(sys_rst),
  .locked(locked),
  .clk_in1(sys_clk_i)
);

Petajon_clkgen2 ucg2
(
  .clk14(clk14),			// 14.31818...
  .clk8(clk8),				// 8.1818181...
  .reset(sys_rst),
  .locked(),
  .clk_in1(sys_clk_i)
);

assign rst = !locked;
assign rstn = locked;

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
	.xonoff_i(1'b1)
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
assign vb_irq = 1'b0;
`endif
assign HS = hSync;
assign VS = vSync;
assign RED = bmp_rgb[23:20];
assign GREEN = bmp_rgb[15:12];
assign BLUE = bmp_rgb[7:4];

`ifndef SIM
mig_7series_0 uddr3
(
	.ddr3_dq(ddr3_dq),
	.ddr3_dqs_p(ddr3_dqs_p),
	.ddr3_dqs_n(ddr3_dqs_n),
	.ddr3_addr(ddr3_addr),
	.ddr3_ba(ddr3_ba),
	.ddr3_ras_n(ddr3_ras_n),
	.ddr3_cas_n(ddr3_cas_n),
	.ddr3_we_n(ddr3_we_n),
	.ddr3_ck_p(ddr3_ck_p),
	.ddr3_ck_n(ddr3_ck_n),
	.ddr3_cke(ddr3_cke),
	.ddr3_dm(ddr3_dm),
	.ddr3_odt(ddr3_odt),
	.ddr3_reset_n(ddr3_reset_n),
	// Inputs
	.sys_clk_i(clk200),
//    .clk_ref_i(clk200),
	.sys_rst(rstn),
	// user interface signals
	.app_addr(mem_addr),
	.app_cmd(mem_cmd),
	.app_en(mem_en),
	.app_wdf_data(mem_wdf_data),
	.app_wdf_end(mem_wdf_end),
	.app_wdf_mask(mem_wdf_mask),
	.app_wdf_wren(mem_wdf_wren),
	.app_rd_data(mem_rd_data),
	.app_rd_data_end(mem_rd_data_end),
	.app_rd_data_valid(mem_rd_data_valid),
	.app_rdy(mem_rdy),
	.app_wdf_rdy(mem_wdf_rdy),
	.app_sr_req(1'b0),
	.app_sr_active(),
	.app_ref_req(1'b0),
	.app_ref_ack(),
	.app_zq_req(1'b0),
	.app_zq_ack(),
	.ui_clk(mem_ui_clk),
	.ui_clk_sync_rst(mem_ui_rst),
	.init_calib_complete(calib_complete)
);
`endif

mpmc8 #(.C0W(BMPW), .C1W(64), .C6W(128), .C7W(64), .C8W(128), .C9W(64)) umc1
(
	.tmr_i(1'b1),
	.rst_i(rst),
	.clk40MHz(clk40),
	.clk100MHz(clk100),
/*
	.cyc0(vm_cyc),
	.stb0(vm_stb),
	.ack0(vm_ack),
	.we0(vm_we),
	.sel0(vm_sel),
	.adr0(vm_adr),
	.dati0(vm_dat_o),
	.dato0(vm_dat_i),
*/
	.clk0(clk40),
	.cyc0(bmp_cyc),
	.stb0(bmp_stb),
	.ack0(bmp_acki),
	.we0(bmp_we),
	.sel0(bmp_sel),
	.adr0(bmp_adr),
	.dati0(bmp_dato),
	.dato0(bmp_dati),

	// CPU2
/*
	.cs1(cs_dram2),
	.cyc1(cyc2),
	.stb1(stb2),
	.ack1(dram_ack2),
	.we1(we2),
	.sel1(sel2),
	.adr1(adr2),
	.dati1(dato2),
	.dato1(dram_dato2),
	.sr1(sr2),
	.cr1(cr2),
	.rb1(rb2),
*/
/*	
	.cyc2(eth_cyc),
	.stb2(eth_stb),
	.ack2(eth_acki),
	.we2(eth_we),
	.sel2(eth_sel),
	.adr2(eth_adr),
	.dati2(eth_dato),
	.dato2(eth_dati),
*/
/*
cs1, cyc1, stb1, ack1, we1, sel1, adr1, dati1, dato1, sr1, cr1, rb1,
cyc2, stb2, ack2, we2, sel2, adr2, dati2, dato2,
cyc3, stb3, ack3, we3, sel3, adr3, dati3, dato3,
cyc4, stb4, ack4, we4, sel4, adr4, dati4, dato4,
cyc5, stb5, ack5, adr5, dato5,
cyc6, stb6, ack6, we6, sel6, adr6, dati6, dato6,
cs7, cyc7, stb7, ack7, we7, sel7, adr7, dati7, dato7, sr7, cr7, rb7,
*/
/*
	.cyc3(aud_cyc),
	.stb3(aud_stb),
	.ack3(aud_acki),
	.we3(aud_we),
	.sel3(aud_sel),
	.adr3(aud_adr),
	.dati3(aud_dato),
	.dato3(aud_dati),
*/
`ifdef ORSOC_GFX
	.cyc4(gfx00_cyc),
	.stb4(gfx00_stb),
	.ack4(gfx00_ack),
	.we4(gfx00_we),
	.sel4(gfx00_sel),
	.adr4(gfx00_adr),
	.dati4(gfx00_dato),
	.dato4(gfx00_dati),
`endif
`ifdef GRID_GFX
	.cyc4(grid_cyc),
	.stb4(grid_stb),
	.ack4(grid_dram_ack),
	.we4(grid_we),
	.sel4(grid_adr[3] ? {grid_sel,4'h0} : {4'h0,grid_sel}),
	.adr4(grid_adr),
	.dati4({2{grid_dato}}),
	.dato4(grid_dram_dati1),
`endif
/*
	.cyc5(spr_cyc),
	.stb5(spr_stb),
	.ack5(spr_acki),
	.adr5(spr_adr),
	.dato5(spr_dati),
	.spriteno(spr_spriteno),
*/
	.cyc6(1'b0),
	.stb6(1'b0),
	.ack6(),
	.we6(1'b0),
	.sel6(16'd0),
	.adr6(32'd0),
	.dati6(128'd0),
	.dato6(),
/*
	// CPU1
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
*/
/*
	.cyc8(pti_cyc),
	.stb8(pti_stb),
	.ack8(pti_acki),
	.we8(pti_we),
	.sel8(pti_sel),
	.adr8(pti_adr),
	.dati8(pti_dato),
	.dato8(pti_dati),
*/
	// CPU3
/*
	.cs9(cs_dram3),
	.cyc9(cyc3),
	.stb9(stb3),
	.ack9(dram_ack3),
	.we9(we3),
	.sel9(sel3),
	.adr9(adr3),
	.dati9(dato3),
	.dato9(dram_dato3),
	.sr9(1'b0),
	.cr9(1'b0),
	.rb9(rb3),
*/

	// MIG memory interface
	.rstn(rstn),
	.mem_ui_clk(mem_ui_clk),
	.mem_ui_rst(mem_ui_rst),
	.calib_complete(calib_complete),
	.mem_addr(mem_addr),
	.mem_cmd(mem_cmd),
	.mem_en(mem_en),
	.mem_wdf_data(mem_wdf_data),
	.mem_wdf_end(mem_wdf_end),
	.mem_wdf_mask(mem_wdf_mask),
	.mem_wdf_wren(mem_wdf_wren),
	.mem_rd_data(mem_rd_data),
	.mem_rd_data_end(mem_rd_data_end),
	.mem_rd_data_valid(mem_rd_data_valid),
	.mem_rdy(mem_rdy),
	.mem_wdf_rdy(mem_wdf_rdy),

	// Debugging	
	.state(dram_state),
	.ch()
);

assign init_calib_complete = calib_complete;

endmodule
