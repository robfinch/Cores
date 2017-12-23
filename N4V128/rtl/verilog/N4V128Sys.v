// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	N4V128Sys.v
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
module N4V128Sys(cpu_resetn, xclk, led, btnu, btnd, btnl, btnr, btnc, sw,
    kd, kclk,
    TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n,
    ac_mclk, ac_adc_sdata, ac_dac_sdata, ac_bclk, ac_lrclk, scl, sda,
    oled_sdin, oled_sclk, oled_dc, oled_res, oled_vbat, oled_vdd,
    rtc_clk, rtc_data,
    ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_reset_n,ddr3_ras_n,ddr3_cas_n,ddr3_we_n,
    ddr3_ba,ddr3_addr,ddr3_dq,ddr3_dqs_p,ddr3_dqs_n,ddr3_dm,ddr3_odt
);
input cpu_resetn;
input xclk;
output [7:0] led;
input btnu;
input btnd;
input btnl;
input btnr;
input btnc;
input [7:0] sw;
inout tri kd;
inout tri kclk;
output TMDS_OUT_clk_p;
output TMDS_OUT_clk_n;
output [2:0] TMDS_OUT_data_p;
output [2:0] TMDS_OUT_data_n;

output ac_mclk;
input ac_adc_sdata;
output ac_dac_sdata;
inout ac_bclk;
inout ac_lrclk;
inout scl;
inout sda;
inout rtc_clk;
inout rtc_data;

output oled_sdin;
output oled_sclk;
output oled_dc;
output oled_res;
output oled_vbat;
output oled_vdd;

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

wire clk200,clk100,clk40,cpu_clk,clk12;
wire clk80, clk20;
wire mem_ui_clk;
wire locked;
wire rst = ~locked;
wire btnud,btndd,btnld,btnrd,btncd;
wire [7:0] gst;

wire hSync, vSync;
wire vde;
wire [23:0] rgb;
wire [7:0] red = rgb[23:16];
wire [7:0] green = rgb[15:8];
wire [7:0] blue = rgb[7:0];

wire [15:0] aud0, aud2;
reg [15:0] audi;
wire [3:0] dram_state;
wire [2:0] dram_ch;
wire [7:0] cpu_state;
wire cpu_cyc;
wire cpu_stb;
wire cpu_ack;
wire cpu_we;
wire [15:0] cpu_sel;
wire [31:0] cpu_addr;
wire [127:0] cpu_dat_o;
reg [127:0] cpu_dat_i;
wire cpu_sr, cpu_cr, cpu_rb;
wire [3:0] cpu_sel4 = cpu_sel[15:12]|cpu_sel[11:8]|cpu_sel[7:4]|cpu_sel[3:0];

wire vm_cyc;
wire vm_stb;
wire vm_ack;
wire vm_we;
wire [15:0] vm_sel;
wire [31:0] vm_adr;
wire [127:0] vm_dat_i;
wire [127:0] vm_dat_o;

wire dram_ack, stack_ack, vic_ack, br_ack, kbd_ack, rand_ack, i2c_ack, i2c2_ack, gpio_ack;
wire [127:0] br_data_o, dram_data_o, stack_data_o;
wire [31:0] vic_dat_o, rand_data_o;
wire [7:0] kbd_data_o,i2c_data_o,i2c2_data_o;

// Address decoding
wire cs_boot = cpu_addr[31:16]==16'hFFFC
				|| cpu_addr[31:16]==16'hFFFD
				|| cpu_addr[31:16]==16'hFFFE;
wire cs_dram = cpu_addr[31:29]==3'b000;
wire cs_stack= cpu_addr[31:16]==16'hFF40;
wire cs_vic  = cpu_addr[31:12]==20'hFFE00;
wire cs_led  = cpu_addr[31:4]==28'hFFDC060;
wire cs_rand = cpu_addr[31:4]==28'hFFDC0C0;
wire cs_kbd  = cpu_addr[31:4]==28'hFFDC000;
wire cs_i2c  = cpu_addr[31:4]==28'hFFDC0E0;
wire cs_i2c2 = cpu_addr[31:4]==28'hFFDC0E1;
wire cs_gpio = cpu_addr[31:4]==28'hFFDC070;

always @*
casez(cpu_addr)
32'h0???????:   cpu_dat_i <= dram_data_o;
32'h1???????:   cpu_dat_i <= dram_data_o;
32'hFF40????:   cpu_dat_i <= stack_data_o;
32'hFFDC000?:   cpu_dat_i <= {16{kbd_data_o}};
32'hFFDC060?:   cpu_dat_i <= {112'h0000,sw,3'b0,btnud,btndd,btnld,btnrd,btncd};
32'hFFDC0C0?:   cpu_dat_i <= {4{rand_data_o}};
32'hFFDC0E0?:   cpu_dat_i <= {16{i2c_data_o}};
32'hFFDC0E1?:   cpu_dat_i <= {16{i2c2_data_o}};
32'hFFE00???:   cpu_dat_i <= {4{vic_dat_o}};
32'hFFFC????:   cpu_dat_i <= br_data_o;
32'hFFFD????:   cpu_dat_i <= br_data_o;
32'hFFFE????:   cpu_dat_i <= br_data_o;
default:        cpu_dat_i <= 128'h0000;
endcase

reg led_ack, led_ack1;
always @(posedge cpu_clk)
    led_ack1 <= cs_led & cpu_cyc & cpu_stb;
always @*
	led_ack <= cs_led ? led_ack1 : 1'b0;
assign cpu_ack = dram_ack
					| stack_ack
					| vic_ack 
					| br_ack 
					| kbd_ack 
					| led_ack 
					| rand_ack
                    | i2c_ack 
                    | i2c2_ack
                    | gpio_ack
                    ; 

BtnDebounce ubdb1 (clk40, btnu, btnud);
BtnDebounce ubdb2 (clk40, btnd, btndd);
BtnDebounce ubdb3 (clk40, btnl, btnld);
BtnDebounce ubdb4 (clk40, btnr, btnrd);
BtnDebounce ubdb5 (clk40, btnc, btncd);

reg [7:0] ledo;
always @(posedge cpu_clk)
    if (cs_led & cpu_stb & cpu_we)
        ledo <= cpu_dat_o[7:0];

OLED uoled1
(
	.rst(rst),
	.clk(xclk_bufg),
	.adr(cpu_addr),
	.dat(cpu_dat_o),
	.st(cpu_state),
	.dst({dram_ch,dram_state}),
	.gst(gst),
	.btn(btncd),
	.SDIN(oled_sdin),
	.SCLK(oled_sclk),
	.DC(oled_dc),
	.RES(oled_res),
	.VBAT(oled_vbat),
	.VDD(oled_vdd)
);

IBUFG #(.IBUF_LOW_PWR(0),.IOSTANDARD("DEFAULT")) ubg1
(
    .I(xclk),
    .O(xclk_bufg)
);

N4V128_Clockgen ucg1
(
    // Clock out ports
    .clk_out1(clk100),
    .clk_out2(clk200),
    .clk_out3(clk40),
    .clk_out4(cpu_clk),
    .clk_out5(clk12),
    .clk_out6(clk80),
    .clk_out7(clk20),
    // Status and control signals
    .reset(~cpu_resetn),
    .locked(locked),
   // Clock in ports
    .clk_in1(xclk_bufg)
);

// The following core supplied by Digilent as part of the NexysVideo examples.
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
    .vid_pVDE(vde),
    .vid_pHSync(hSync),
    .vid_pVSync(vSync),
    .PixelClk(clk40),
    .SerialClk(clk200)
);

AVIC128 uvic1
(
	// Slave port
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_vic),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(vic_ack),
	.we_i(cpu_we),
	.sel_i(cpu_sel4),
	.adr_i(cpu_addr),
	.dat_i(cpu_dat_o[31:0]),
	.dat_o(vic_dat_o),
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

FT64seq ucpu1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cyc_o(cpu_cyc),
	.stb_o(cpu_stb),
	.ack_i(cpu_ack),
	.sel_o(cpu_sel),
	.we_o(cpu_we),
	.adr_o(cpu_addr),
	.dat_i(cpu_dat_i),
	.dat_o(cpu_dat_o),
	.state(cpu_state)
);
/*
DSD9_mpu umpu1
(
	.hartid_i(80'h01),
	.rst_i(rst),
	.refclk_i(),
	.clk_i(cpu_clk),
	.clk2x_i(clk80),
	.clk2d_i(clk20),
    .i1(),
    .i2(),
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
    .i16(),
    .i17(),
    .i18(),
    .i19(),
    .i20(),
    .i21(),
    .i22(),
    .i23(),
    .i24(),
    .i25(),
    .i26(),
    .i27(),
    .i28(),
    .i29(),
    .i30(),
    .i31(),
    .irq_o(),
    .cyc_o(cpu_cyc),
    .stb_o(cpu_stb),
    .wr_o(cpu_we),
    .sel_o(cpu_sel),
    .wsel_o(),
    .ack_i(cpu_ack),
    .err_i(),
    .adr_o(cpu_addr),
    .dat_i(cpu_dat_i),
    .dat_o(cpu_dat_o),
    .sr_o(cpu_sr),
    .cr_o(cpu_cr),
    .rb_i(cpu_rb),
    .state_o(),
    .trigger_o()
);
*/

bootrom ubr1
(
    .clk_i(cpu_clk),
    .cs_i(cs_boot),
    .cyc_i(cpu_cyc),
    .stb_i(cpu_stb),
    .ack_o(br_ack),
    .adr_i(cpu_addr[16:0]),
    .dat_o(br_data_o)
);


reg rdy1,rdy2,rdy3;
always @(posedge cpu_clk)
    rdy1 <= cs_stack & cpu_cyc & cpu_stb;
always @(posedge cpu_clk)
    rdy2 <= rdy1 & cs_stack & cpu_cyc & cpu_stb;
always @(posedge cpu_clk)
    rdy3 <= rdy2 & cs_stack & cpu_cyc & cpu_stb;
assign stack_ack = ((cs_stack & cpu_cyc & cpu_stb) ? (cpu_we ? 1'b1 : rdy3) : 1'b0);

stackram ustk1
(
    .clka(cpu_clk),
    .ena(1'b1),
    .wea({16{cs_stack & cpu_stb & cpu_we}} & cpu_sel),
    .addra(cpu_addr[12:4]),
    .dina(cpu_dat_o),
    .douta(stack_data_o)
);

mpmc6 umc1
(
	.rst_i(rst),
	.clk100MHz(xclk_bufg),
	.clk200MHz(clk200),
	.clk(cpu_clk),
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
	.cyc7(cpu_cyc),
	.stb7(cpu_stb),
	.ack7(dram_ack),
	.we7(cpu_we),
	.sel7(cpu_sel),
	.adr7(cpu_addr),
	.dati7(cpu_dat_o),
	.dato7(dram_data_o),
	.sr7(cpu_sr),
	.cr7(cpu_cr),
	.rb7(cpu_rb),

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
	.state(dram_state),
	.ch(dram_ch)
);


random	uprg1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_rand),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(rand_ack),
	.we_i(cpu_we),
	.adr_i(cpu_addr[3:0]),
	.dat_i(cpu_dat_o[31:0]),
	.dat_o(rand_data_o)
);

Ps2Keyboard ukbd1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_kbd),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(kbd_ack),
	.we_i(cpu_we),
	.adr_i(cpu_addr[5:2]),
	.dat_i(cpu_dat_o[7:0]),
	.dat_o(kbd_data_o),
	.kclk(kclk),
	.kd(kd),
	.irq_o()
);

wire ac_sclk_oe, ac_sda_oe;
wire ac_sclko, ac_sdao;
assign scl = ~ac_sclk_oe ? ac_sclko : 1'bz;
assign sda = ~ac_sda_oe ? ac_sdao : 1'bz;

i2c_master_top ui2c1
(
	.wb_clk_i(cpu_clk),
	.wb_rst_i(rst),
	.arst_i(~rst),
	.cs_i(cs_i2c),
	.wb_adr_i(cpu_addr[3:1]),
	.wb_dat_i(cpu_dat_o[7:0]),
	.wb_dat_o(i2c_data_o),
	.wb_we_i(cpu_we),
	.wb_cyc_i(cpu_cyc),
	.wb_stb_i(cpu_stb),
	.wb_ack_o(i2c_ack),
	.wb_inta_o(),
	.scl_pad_i(scl),
	.scl_pad_o(ac_sclko),
	.scl_padoen_o(ac_sclk_oe),
	.sda_pad_i(sda),
	.sda_pad_o(ac_sdao),
	.sda_padoen_o(ac_sda_oe)
);

wire rtc_clko, rtc_datao;
wire rtc_clk_en,rtc_data_en;
assign rtc_clk = rtc_clk_en ? 1'bz : rtc_clko;
assign rtc_data = rtc_data_en ? 1'bz : rtc_datao;
i2c_master_top ui2c2
(
	.wb_clk_i(cpu_clk),
	.wb_rst_i(rst),
	.arst_i(~rst),
	.cs_i(cs_i2c2),
	.wb_adr_i(cpu_addr[3:1]),
	.wb_dat_i(cpu_dat_o[7:0]),
	.wb_dat_o(i2c2_data_o),
	.wb_we_i(cpu_we),
	.wb_stb_i(cpu_stb),
	.wb_cyc_i(cpu_cyc),
	.wb_ack_o(i2c2_ack),
	.wb_inta_o(),
	.scl_pad_i(rtc_clk),
	.scl_pad_o(rtc_clko),
	.scl_padoen_o(rtc_clk_en),
	.sda_pad_i(rtc_data),
	.sda_pad_o(rtc_datao),
	.sda_padoen_o(rtc_data_en)
);

assign led = btndd ? cpu_addr[23:16] :
			 btnrd ? cpu_addr[15:8] :
			 btnld ? cpu_addr[7:0] :
			 ledo;

//assign led[1] = sel_boot;
//assign led[0] = vSync;
//assign led[1] = locked;
/*
assign led[1:0] = 2'h0;
assign led[6] = locked;
assign led[5] = cpu_clk;
assign led[4] = ~cpu_resetn;
assign led[3] = vSync;
assign led[2] = hSync;
*/
reg en_tx;
reg en_rx;

always @(posedge cpu_clk)
	if (cs_gpio & cpu_we & cpu_stb) begin
		en_tx <= cpu_dat_o[1];
		en_rx <= cpu_dat_o[0];
	end
assign gpio_ack = cs_gpio & cpu_stb;

wire en_rxtx = en_tx|en_rx;
reg [3:0] bclk;
reg [63:0] lrclk;
reg [31:0] ldato, rdato, ain;
reg [63:0] sdato;
assign ac_mclk = clk12;
assign ac_bclk = en_rxtx ? bclk[3] : 1'bz;
assign ac_lrclk = en_rxtx ? lrclk[63] : 1'bz;
assign ac_dac_sdata = en_tx ? sdato[31] : 1'b0;

always @(posedge clk12)
if (rst)
    bclk <= 4'b0011;
else
    bclk <= {bclk[2:0],bclk[3]};

always @(posedge clk12)
if (rst)
    lrclk <= 64'hFFFFFFFF00000000;
else
    lrclk <= {lrclk[62:0],lrclk[63]};

always @(posedge clk12)
if (rst)
    sdato <= {1'b0,aud0,16'h0000,aud2[15:1]};
else begin
    if (bclk==4'b1001) begin
        if (lrclk==64'h800000007FFFFFFF)
            sdato <= {aud0,16'h0000,aud2,16'h0000};
        else
            sdato <= {sdato[62:0],1'b0};
    end
    if (bclk==4'b1100) begin
        ain <= {ain[30:0],ac_adc_sdata};
        if (lrclk==64'hFFFFFFFC00000003 || lrclk==64'h00000003FFFFFFFC)
            audi <= {ain[14:0],ac_adc_sdata};
    end
end


endmodule

