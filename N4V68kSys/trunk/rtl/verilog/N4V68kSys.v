// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	N4V68kSys.v
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
//`define MMU 1'b1
//`define FT68k

module N4V68kSys(cpu_resetn, xclk, led, btnu, btnd, btnl, btnr, btnc, sw,
    kd, kclk,
    TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n,
    ac_mclk, ac_adc_sdata, ac_dac_sdata, ac_bclk, ac_lrclk, scl, sda,
    rtc_clk, rtc_data,
    oled_sdin, oled_sclk, oled_dc, oled_res, oled_vbat, oled_vdd,
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

parameter SIM = 1'b0;

wire cpu_resetnd;
wire clk200,clk40,clk12;
wire locked;
wire cpu_clk;// = clk40;
wire _cpu_reset;
wire rst = ~locked;
wire [2:0] _cpu_ipl;
wire dram_ack;
wire [15:0] dram_data_o;
wire _cpu_as;
wire _cpu_lds;
wire _cpu_uds;
wire cpu_r_w;
wire cpu_ack;
wire cpu_dd;
wire [31:0] cpu_addr, cpu_addr1;
wire cpu_cyc, cpu_cyc1;
wire cpu_stb, cpu_stb1;
wire cpu_dtack, cpu_ack1;
wire cpu_we, cpu_we1;
wire [15:0] cpu_data_o, cpu_data_out, cpu_dat_o1;
wire [15:0] cpu_data =  cpu_r_w ? 16'bz : cpu_data_o; //cpu_dd ? cpu_data_o : 16'bz;
wire [15:0] cpu_data_i, cpu_dat_i1;
reg [15:0] cpu_data_in;
wire [1:0] cpu_sel, cpu_sel1;

//assign _cpu_reset = locked ? 1'b1 : 1'b0;

wire eol, eof;
wire hSync, vSync;
wire hSync_n = ~hSync;
wire vSync_n = ~vSync;
wire [7:0] red;
wire [7:0] green;
wire [7:0] blue;
wire blank, border;

wire vdg_ack;
wire [15:0] vdg_data_o;
wire [14:0] vdg_rgb;

wire _ram_bhe,_ram_ble;
wire _ram_we,_ram_oe;
wire _ram_ce;
wire [15:0] ram_data;
wire [15:0] ram_data_i = ram_data;
wire [15:0] ram_data_o;
assign ram_data = _ram_we ? (&_ram_ce ? 16'd0000 : ram_data_o) : 16'bz;
wire [31:1] ram_addr,ram_addr1;
wire [15:0] chip_ram_dat_o;

wire [15:0] stack_data_o;
wire br_ack;
wire [15:0] br_data_o;

wire rand_ack;
wire [15:0] rand_data_o;
wire kbd_ack;
wire [7:0] kbd_data_o;
wire i2c_ack, i2c2_ack;
wire [7:0] i2c_data_o;
wire [7:0] i2c2_data_o;

wire sel_boot;
reg [7:0] ledo;
wire gpio_ack;

wire [15:0] aud0, aud1, aud2, aud3;
reg [15:0] audi;

// Address decoding
wire cs_boot = cpu_addr[31:16]==16'hFFFC || cpu_addr[31:3]==29'h0;
wire cs_dram = cpu_addr[31:29]==3'b000 && !cs_boot;
wire cs_stack = cpu_addr[31:20]==12'hFF4;
wire cs_vdg_reg = cpu_addr[31:12]==20'hFFE00;
wire cs_vdg_ram = cpu_addr[31:22]==10'b1111_1111_10;
wire cs_led  = cpu_addr[31:4]==28'hFFDC060;
wire cs_rand = cpu_addr[31:4]==28'hFFDC0C0;
wire cs_kbd  = cpu_addr[31:4]==28'hFFDC000;
wire cs_i2c  = cpu_addr[31:4]==28'hFFDC0E0;
wire cs_i2c2 = cpu_addr[31:4]==28'hFFDC0E1;
wire cs_gpio = cpu_addr[31:4]==28'hFFDC070;

always @*
casez(cpu_addr)
32'b00000???:   cpu_data_in <= br_data_o;
32'h0???????:   cpu_data_in <= dram_data_o;
32'h1???????:   cpu_data_in <= dram_data_o;
32'hFF40????:   cpu_data_in <= stack_data_o;
32'hFF8?????:   cpu_data_in <= vdg_data_o;
32'hFF9?????:   cpu_data_in <= vdg_data_o;
32'hFFA?????:   cpu_data_in <= vdg_data_o;
32'hFFB?????:   cpu_data_in <= vdg_data_o;
32'hFFDC000?:   cpu_data_in <= {2{kbd_data_o}};
32'hFFDC060?:   cpu_data_in <= sw;
32'hFFDC0C0?:   cpu_data_in <= rand_data_o;
32'hFFDC0E0?:   cpu_data_in <= {2{i2c_data_o}};
32'hFFDC0E1?:   cpu_data_in <= {2{i2c2_data_o}};
32'hFFE00???:   cpu_data_in <= vdg_data_o;
32'hFFFC????:   cpu_data_in <= br_data_o;
32'hFFFD????:   cpu_data_in <= br_data_o;
32'hFFFE????:   cpu_data_in <= br_data_o;
default:        cpu_data_in <= 16'h0000;
endcase
/*
assign cpu_data_in = cs_led ? sw :
                     cs_dram ? dram_data_o :
                     cs_stack ? stack_data_o :
                     cs_boot ? br_data_o :
                     (cs_vdg_reg|cs_vdg_ram) ? vdg_data_o :
                     cs_rand ? rand_data_o :
                     cs_kbd ? {2{kbd_data_o}} :
                     cs_i2c ? {2{i2c_data_o}} :
                     cs_i2c2 ? {2{i2c2_data_o}} :
                     16'h0000
                    ;
*/
wire stack_ack; 
reg led_ack, led_ack1;
always @(posedge cpu_clk)
    led_ack1 <= cs_led & cpu_cyc & cpu_stb;
always @*
	led_ack <= cs_led ? led_ack1 : 1'b0;
assign cpu_ack = dram_ack
					| stack_ack
					| vdg_ack 
					| br_ack 
					| kbd_ack 
					| led_ack 
					| rand_ack
                    | i2c_ack 
                    | i2c2_ack
                    | gpio_ack
                    ; 

assign _cpu_ipl = 3'b111;

wire btnud, btndd, btnld, btnrd, btncd;
wire cpu_resetnd;
BtnDebounce ubdb0 (clk40, cpu_resetn, cpu_resetnd);
BtnDebounce ubdb1 (clk40, btnu, btnud);
BtnDebounce ubdb2 (clk40, btnd, btndd);
BtnDebounce ubdb3 (clk40, btnl, btnld);
BtnDebounce ubdb4 (clk40, btnr, btnrd);
BtnDebounce ubdb5 (clk40, btnc, btncd);

always @(posedge cpu_clk)
    if (cs_led & cpu_stb & cpu_we)
        ledo <= cpu_data_out[7:0];

OLED uoled1
(
	.rst(rst),
	.clk(xclk),
	.adr(cpu_addr),
	.dat(cpu_data_out),
	.SDIN(oled_sdin),
	.SCLK(oled_sclk),
	.DC(oled_dc),
	.RES(oled_res),
	.VBAT(oled_vbat),
	.VDD(oled_vdd)
);


clk_wiz_0 ucg1
(
    // Clock out ports
    .clk_out1(),
    .clk_out2(clk200),
    .clk_out3(clk40),
    .clk_out4(cpu_clk),
    .clk_out5(clk12),
    // Status and control signals
    .reset(~cpu_resetn),
    .locked(locked),
   // Clock in ports
    .clk_in1(xclk)
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
    .vid_pVDE(~blank),
    .vid_pHSync(hSync),
    .vid_pVSync(vSync),
    .PixelClk(clk40),
    .SerialClk(clk200)
);

`ifdef FT68k
FT68000x16 uft68k
(
	.rst_i(rst),
	.rst_o(),
	.clk_i(cpu_clk),
	.nmi_i(),
	.ipl_i(),
	.lock_o(),
	.bsz_i(),
	.cyc_o(cpu_cyc1),
	.stb_o(cpu_stb1),
	.ack_i(cpu_ack1),
	.err_i(),
	.we_o(cpu_we1),
	.sel_o(cpu_sel1),
	.fc_o(),
	.adr_o(cpu_addr1),
	.dat_i(cpu_dat_i1),
	.dat_o(cpu_dat_o1)
);
`else
TG68 utg68k
(        
	.clk(cpu_clk),
	.reset(~rst),
    .clkena_in(1'b1),
    .data_in(cpu_data_i),
    .IPL(_cpu_ipl),
    .dtack(_cpu_dtack),
//    .berr(1'b1),
    .addr(cpu_addr1),
    .data_out(cpu_data_o),
    .as(_cpu_as),
    .uds(_cpu_uds),
    .lds(_cpu_lds),
    .rw(cpu_r_w),
    .drive_data(cpu_dd)
);
`endif

`ifdef MMU
N4Vmmu ummu1
(
	.clk_i(cpu_clk),

	.cpu_cyc_i(~_cpu_as),
	.cpu_stb_i(~(_cpu_uds&_cpu_lds)),
	.cpu_ack_o(cpu_dtack),
	.cpu_we_i(~cpu_r_w),
	.cpu_sel_i(~{_cpu_uds,_cpu_lds}),
	.cpu_adr_i(cpu_addr1),
	.cpu_dat_o(cpu_data_i),
	.cpu_dat_i(cpu_data_o),

	.cyc_o(cpu_cyc),
	.stb_o(cpu_stb),
	.ack_i(cpu_ack),
	.we_o(cpu_we),
	.sel_o(cpu_sel),
	.adr_o(cpu_addr),
	.dat_i(cpu_data_in),
	.dat_o(cpu_data_out)
);
assign _cpu_dtack = ~cpu_dtack;
`else
`ifdef FT68k
assign cpu_cyc = cpu_cyc1;
assign cpu_stb = cpu_stb1;
assign cpu_ack1 = cpu_ack;
assign cpu_sel = cpu_sel1;
assign cpu_we = cpu_we1;
assign cpu_addr = cpu_addr1;
assign cpu_dat_i1 = cpu_data_in;
assign cpu_data_out = cpu_dat_o1;
`else
assign cpu_cyc = ~_cpu_as;
assign cpu_stb = ~(_cpu_uds&_cpu_lds);
assign _cpu_dtack = ~cpu_ack;
assign cpu_we = ~cpu_r_w;
assign cpu_sel = ~{_cpu_uds,_cpu_lds};
assign cpu_addr = cpu_addr1;
assign cpu_data_i = cpu_data_in;
assign cpu_data_out = cpu_data_o;
`endif
`endif

bootrom ubr1
(
    .clk_i(cpu_clk),
    .cs_i(cs_boot),
    .cyc_i(cpu_cyc),
    .stb_i(cpu_stb),
    .ack_o(br_ack),
    .adr_i(cpu_addr[15:0]),
    .dat_o(br_data_o)
);


reg rdy1,rdy2,rdy3;
always @(posedge cpu_clk)
    rdy1 <= cs_stack & cpu_cyc & cpu_stb;
always @(posedge cpu_clk)
    rdy2 <= rdy1 & cs_stack & cpu_cyc & cpu_stb;
always @(posedge cpu_clk)
    rdy3 <= rdy2 & cs_stack & cpu_cyc & cpu_stb;
assign stack_ack = (cs_stack ? rdy3 : 1'b0);

stackram ustk1
(
    .clka(cpu_clk),
    .ena(1'b1),
    .wea({2{cs_stack & cpu_stb & cpu_we}} & cpu_sel),
    .addra(cpu_addr[16:1]),
    .dina(cpu_data_out),
    .douta(stack_data_o)
);

DDRcontrol2 DDRCtrl1
(
	// Common
	.clk_200MHz_i(clk200),	// 200 MHz system clock
	.cpu_clk(cpu_clk),
	.rst_i(rst),              // active high system reset

	// RAM interface
	.cs_i(cs_dram),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(dram_ack),
	.sel_i(cpu_sel),
	.we_i(cpu_we),
	.adr_i(cpu_addr[28:1]),
	.dat_i(cpu_data_out),
	.dat_o(dram_data_o),
      
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
	.ddr3_odt(ddr3_odt)
);

AVController uvdg1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(vdg_ack),
	.we_i(cpu_we),
	.sel_i(cpu_sel),
	.adr_i(cpu_addr[23:0]),
	.dat_i(cpu_data_out),
	.dat_o(vdg_data_o),
	.cs_i(cs_vdg_reg),
	.cs_ram_i(cs_vdg_ram),
	// Video port
	.clk(clk40),
	.hSync(hSync),
	.vSync(vSync),
	.blank_o(blank),
	.rgb(vdg_rgb),
	// Audio port
	.aud0_out(aud0),
	.aud1_out(aud1),
	.aud2_out(aud2),
	.aud3_out(aud3),
	.aud_in(audi)
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
	.dat_i(cpu_data_out),
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
	.adr_i(cpu_addr[3:0]),
	.dat_i(cpu_sel[1] ? cpu_data_out[15:8] : cpu_data_out[7:0]),
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
	.wb_dat_i(cpu_data_out[7:0]),
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
	.wb_dat_i(cpu_data_out[7:0]),
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
assign red = {vdg_rgb[14:10],3'h0};
assign green = {vdg_rgb[9:5],3'h0};
assign blue = {vdg_rgb[4:0],3'h0};

reg en_tx;
reg en_rx;

always @(posedge cpu_clk)
	if (cs_gpio & cpu_we) begin
		en_tx <= cpu_data_out[1];
		en_rx <= cpu_data_out[0];
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
    sdato <= {1'b0,aud0,16'h0000,aud1[15:1]};
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
