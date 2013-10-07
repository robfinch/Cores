`timescale 1ns / 1ps
// ============================================================================
//	(C) 2012,2013  Robert Finch
//	robfinch@<remove>opencores.org
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
`define NSPRITES	8
`define ETHMAC	2
`define PSG		4
//`define EPPCTRL	8
//`define TMPDEVICE	16
//`define UART	32
`define SDCARD	64
`define GACCEL	128
`define BMPCTRL		256
`define LEDS	512
`define RASTIRQ	1024
`define DATETIME	2048
//`define MMU			4096
//`define SUPPORT_FORTH	8192

`define CLK_FREQ	20000000

// Memory Ports
// 0: cpu read/write
// 1: ethernet controller read/write
// 2: bitmapped graphics controller read
// 3: graphics accelerate write
// 4: 
// 5: sprite graphics controller read
 
module rtf65002_sys(btn, clk, Led, sw, kclk, kd,
	HDMIOUTCLKP, HDMIOUTCLKN,
	HDMIOUTD0P,HDMIOUTD0N,
	HDMIOUTD1P,HDMIOUTD1N,
	HDMIOUTD2P,HDMIOUTD2N,
	HDMIOUTSCL,HDMIOUTSDA,
	BITCLK,AUDSDI,AUDSDO,AUDSYNC,AUDRST,
	DDR2CLK0,DDR2CLK1,DDR2CKE,DDR2RASN,DDR2CASN,DDR2WEN,DDR2RZQ,DDR2ZIO,
	DDR2BA,DDR2A,DDR2DQ,DDR2UDQS,DDR2UDQSN,DDR2LDQS,DDR2LDQSN,DDR2LDM,DDR2UDM,DDR2ODT,
	UartRx,UartTx,
	spiClkOut,spiDataIn,spiDataOut,spiCS_n,
	mdc,mdio,eth_rst,eth_col,eth_rs,eth_gtxclk,
	eth_txclk,eth_txerr,eth_txen,eth_txd,
	eth_rxclk,eth_rxerr,eth_rxdv,eth_rxd
);
input [5:0] btn;
input clk;
output [7:0] Led;
reg [7:0] Led;
input [7:0] sw;
inout kclk;
tri kclk;
inout kd;
tri kd;
output HDMIOUTCLKP;
output HDMIOUTCLKN;
output HDMIOUTD0P;
output HDMIOUTD0N;
output HDMIOUTD1P;
output HDMIOUTD1N;
output HDMIOUTD2P;
output HDMIOUTD2N;
inout HDMIOUTSCL;
inout HDMIOUTSDA;
tri HDMIOUTSCL;
tri HDMIOUTSDA;
input BITCLK;
output AUDSYNC;
output AUDRST;
output AUDSDO;
input AUDSDI; 
output DDR2CLK0;
output DDR2CLK1;
output DDR2CKE;
output DDR2RASN;
output DDR2CASN;
output DDR2WEN;
inout DDR2RZQ;
inout DDR2ZIO;
output [2:0] DDR2BA;
output [12:0] DDR2A;
inout [15:0] DDR2DQ;
inout DDR2UDQS;
inout DDR2UDQSN;
inout DDR2LDQS;
inout DDR2LDQSN;
output DDR2LDM;
output DDR2UDM;
output DDR2ODT;
input UartRx;
output UartTx;
output spiClkOut;
input spiDataIn;
output spiDataOut;
output spiCS_n;
output mdc;
inout mdio;
tri mdio;
output reg eth_rst;
input eth_col;
input eth_rs;
output eth_gtxclk;
input eth_txclk;
output eth_txerr;
output eth_txen;
output [7:0] eth_txd;
input eth_rxclk;
input eth_rxerr;
input eth_rxdv;
input [7:0] eth_rxd;

wire [3:0] TMDS;
wire [3:0] TMDSB;
assign HDMIOUTCLKP = TMDS[3];
assign HDMIOUTCLKN = TMDSB[3];
assign HDMIOUTD0P = TMDS[0];
assign HDMIOUTD0N = TMDSB[0];
assign HDMIOUTD1P = TMDS[1];
assign HDMIOUTD1N = TMDSB[1];
assign HDMIOUTD2P = TMDS[2];
assign HDMIOUTD2N = TMDSB[2];
//assign HDMIOUTSCL = 1'b0;
//assign HDMIOUTSDA = 1'b0;

wire xreset = ~btn[0];
wire clk100, clk25;
wire pixel_clk;
wire pixel_clk2;
wire pixel_clk10;
wire sys_clk;
wire pulse1000Hz,pulse100Hz;
wire p100ack,p1000ack;
wire locked;
wire rst;
wire dram_clk;

wire hsync;
wire vsync;
wire blank;
wire border;

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
wire [31:0] bm_dat_i;
wire [7:0] bm_rgb;

wire dt_ack;
wire [31:0] dt_dato;

wire spr_ack;
wire [31:0] spr_dato;
wire [23:0] spr_rgb;

wire kbd_rst;
wire kbd_irq;
wire kbd_ack;
wire [15:0] kbd_dato;
wire pic_ack;
wire [31:0] pic_dato;

wire tc_ack;
wire [31:0] tc_dato;
wire [23:0] tc_rgb;
wire uart_ack;
wire [7:0] uart_do;
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
wire em_cyc;
wire em_stb;
wire em_we;
wire em_ack;
wire [3:0] em_sel;
wire [31:0] em_adr;
wire [31:0] em_dato;
wire [31:0] em_s_dato;
wire [31:0] em_dati;
wire em_int;
wire em_erro;
wire bridge5_ack;
wire [31:0] bridge5_dato;

wire scrm_ack;
wire [31:0] scrm_dato;
wire btrm_ack;
wire [31:0] btrm_dato;
wire bas_ack;
wire [31:0] bas_dato;
wire for_ack;
wire [31:0] for_dato;

wire [2:0] cpu_cti;
wire [5:0] cpu_bl;
wire cpu_cyc;
wire cpu_stb;
wire cpu_we;
wire [3:0] cpu_sel;
wire [33:0] cpu_adr;
wire [31:0] cpu_dato;
wire cpu_irq1;
wire cpu_nmi;
wire [33:0] sys_adr;

wire bridge_ack;
wire [31:0] bridge_dato;
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

wire mmu_ack;
wire [15:0] mmu_dato;
wire [33:0] mem_adr;

wire iob1_ack;
wire [31:0] iob1_dato;
wire io1_cyc;
wire io1_stb;
wire io1_we;
wire io1_ack;
wire [3:0] io1_sel;
wire [33:0] io1_adr;
wire [31:0] io1_dati;
wire [31:0] io1_dato;

wire iob2_ack;
wire [31:0] iob2_dato;
wire io2_cyc;
wire io2_stb;
wire io2_we;
wire io2_ack;
wire [3:0] io2_sel;
wire [33:0] io2_adr;
wire [31:0] io2_dati;
wire [31:0] io2_dato;

wire iob3_ack;
wire [31:0] iob3_dato;
wire io3_cyc;
wire io3_stb;
wire io3_we;
wire io3_ack;
wire [3:0] io3_sel;
wire [33:0] io3_adr;
wire [31:0] io3_dati;
wire [31:0] io3_dato;

wire iob4_ack;
wire [31:0] iob4_dato;
wire io4_cyc;
wire io4_stb;
wire io4_we;
wire io4_ack;
wire [3:0] io4_sel;
wire [33:0] io4_adr;
wire [31:0] io4_dati;
wire [31:0] io4_dato;

wire cpu_ack =
	bridge_ack |
	sema_ack |
	scrm_ack |
	btrm_ack |
	bas_ack |
	for_ack |
	iob1_ack |
	iob2_ack |
	iob3_ack |
	iob4_ack
	;
wire [31:0] cpu_dati =
	sema_dato |
	bridge_dato |
	scrm_dato |
	btrm_dato |
	bas_dato |
	for_dato |
	iob1_dato |
	iob2_dato |
	iob3_dato |
	iob4_dato
	;

assign io1_ack =
	em_ack |
	spi_ack |
	uart_ack |
	mmu_ack
	;
assign io1_dati =
	em_s_dato |
	spi_dato |
	uart_do |
	mmu_dato
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
	tc_ack |
	spr_ack |
	ga_ack |
	rast_ack
	;
assign io3_dati =
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
	dt_ack |
	Leds_ack
	;
assign io4_dati =
	config_reco |
	pic_dato |
	kbd_dato |
	dt_dato
	;

clkgen1366x768 #(.pClkFreq(`CLK_FREQ)) u1
(
	.xreset(xreset),
	.xclk(clk),
	.rst(rst),
	.clk100(clk100),
	.clk50(sys_clk),
	.clk125(eth_gtxclk),
	.clk200(),
	.vclk(pixel_clk),
	.vclk2(pixel_clk2),
	.vclk10(pixel_clk10),
	.sys_clk(),
	.dram_clk(dram_clk),
	.locked(locked),
	.pulse1000Hz(pulse1000Hz),
	.pulse100Hz(pulse100Hz)
);

`ifdef LEDS
wire csLeds = io4_cyc && io4_stb && (io4_adr[33:10]==24'hFFDC_06);
assign Leds_ack = csLeds;
reg [7:0] cnt;
reg [7:0] Led1;	// help out the router by prociding extra reg
always @(posedge sys_clk)
if (rst) begin
	Led <= 8'h00;
	Led1 <= 8'h00;
end
else
begin
	if (csLeds & io4_we) begin
		Led1 <= io4_dato[7:0];
	end
	Led <= Led1;
end
`else
assign Leds_ack = 1'b0;
`endif

PS2KbdToAscii #(.pClkFreq(`CLK_FREQ)) ukbd1
(
	.rst_i(rst),
	.clk_i(sys_clk),
	.cyc_i(io4_cyc),
	.stb_i(io4_stb),
	.ack_o(kbd_ack),
	.we_i(io4_we),
	.adr_i(io4_adr),
	.dat_i(io4_dato[7:0]),
	.dat_o(kbd_dato),
	.kclk(kclk),
	.kd(kd),
	.irq(kbd_irq),
	.rst_o(kbd_rst)
);

dvi_out_native u2
(
	.reset(rst),
	.pll_lckd(locked),
	.clkin(pixel_clk),          // pixel clock, from bufg
	.clkx2in(pixel_clk2),       // pixel clock x2, from bufg
	.clkx10in(pixel_clk10),     // pixel clock x10, unbuffered
	.blue_din(blue),       		// Blue data in
	.green_din(green),      	// Green data in
	.red_din(red),        		// Red data in
	.hsync(hsync),			    // hsync data
	.vsync(vsync),  			// vsync data
	.de(!blank),           		// data enable
 	.TMDS(TMDS),
	.TMDSB(TMDSB)
);


//VGASyncGen640x480_60Hz u3
WXGASyncGen1366x768_60Hz u3
(
	.rst(rst),
	.clk(pixel_clk),
	.hSync(hsync),
	.vSync(vsync),
	.blank(blank),
	.border(border)
);

rtfTextController tc1 (
	.rst_i(rst),
	.clk_i(sys_clk),
	.cyc_i(io3_cyc),
	.stb_i(io3_stb),
	.ack_o(tc_ack),
	.we_i(io3_we),
	.adr_i(io3_adr),
	.dat_i(io3_dato),
	.dat_o(tc_dato),
	.lp(),
	.curpos(),
	.vclk(pixel_clk),
	.hsync(hsync),
	.vsync(vsync),
	.blank(blank),
	.border(border),
	.rgbIn(),
	.rgbOut(tc_rgb)
);

always @(sw,tc_rgb,bm_rgb,spr_rgb)
	if (sw[0]) begin
		red <= tc_rgb[23:16];
		green <= tc_rgb[15:8];
		blue <= tc_rgb[7:0];
	end
	else if (sw[1]) begin
		red <= {bm_rgb[7:5],5'b10000};
		green <= {bm_rgb[4:2],5'b10000};
		blue <= {bm_rgb[1:0],6'b100000};
	end
	else begin
		red <= spr_rgb[23:16];
		green <= spr_rgb[15:8];
		blue <= spr_rgb[7:0];
	end

wire c3_calib_done;
wire c3_sys_clk_p, c3_sys_clk_n;
wire c3_sys_clk = clk100;
wire c3_sys_rst_n = rst;
wire c3_rst0;

wire c3_p0_cmd_full;
wire c3_p0_cmd_empty;
wire c3_p0_cmd_en;
wire [2:0] c3_p0_cmd_instr;
wire [5:0] c3_p0_cmd_bl;
wire [31:0] c3_p0_wr_data;
wire [31:0] c3_p0_rd_data;
wire [29:0] c3_p0_cmd_byte_addr;
wire [3:0] c3_p0_wr_mask;
wire c3_p0_wr_full;
wire c3_p0_wr_empty;
wire [5:0] c3_p0_wr_count;
wire c3_p0_rd_empty;
wire c3_p0_rd_full;
wire c3_p0_rd_en;
wire c3_p0_wr_en;

wire c3_p1_cmd_full;
wire c3_p1_cmd_empty;
wire c3_p1_cmd_en;
wire [2:0] c3_p1_cmd_instr;
wire [5:0] c3_p1_cmd_bl;
wire [31:0] c3_p1_wr_data;
wire [31:0] c3_p1_rd_data;
wire [29:0] c3_p1_cmd_byte_addr;
wire [3:0] c3_p1_wr_mask;
wire c3_p1_wr_full;
wire c3_p1_wr_empty;
wire [5:0] c3_p1_wr_count;
wire c3_p1_rd_empty;
wire c3_p1_rd_full;
wire c3_p1_rd_en;
wire c3_p1_wr_en;

wire c3_clk0;

wire c3_p2_cmd_full;
wire c3_p2_cmd_empty;
wire c3_p2_cmd_en;
wire [2:0] c3_p2_cmd_instr;
wire [29:0] c3_p2_cmd_byte_addr;
wire [5:0] c3_p2_cmd_bl;
wire c3_p2_rd_en;
wire [31:0] c3_p2_rd_data;
wire c3_p2_rd_empty;

wire c3_p3_cmd_full;
wire c3_p3_cmd_en;
wire [2:0] c3_p3_cmd_instr;
wire [5:0] c3_p3_cmd_bl;
wire [29:0] c3_p3_cmd_byte_addr;
wire c3_p3_wr_en;
wire [3:0] c3_p3_wr_mask;
wire [31:0] c3_p3_wr_data;
wire c3_p3_wr_empty;
wire c3_p3_wr_full;

wire c3_p5_cmd_full;
wire c3_p5_cmd_empty;
wire c3_p5_cmd_en;
wire [2:0] c3_p5_cmd_instr;
wire [29:0] c3_p5_cmd_byte_addr;
wire [5:0] c3_p5_cmd_bl;
wire c3_p5_rd_en;
wire [31:0] c3_p5_rd_data;
wire c3_p5_rd_empty;


mig_39 # (
    .C3_P0_MASK_SIZE(4),
    .C3_P0_DATA_PORT_SIZE(32),
    .C3_P1_MASK_SIZE(4),
    .C3_P1_DATA_PORT_SIZE(32),
    .DEBUG_EN(0),
    .C3_MEMCLK_PERIOD(3200),
    .C3_CALIB_SOFT_IP("TRUE"),
    .C3_SIMULATION("FALSE"),
    .C3_RST_ACT_LOW(0),
    .C3_INPUT_CLK_TYPE("USER"),
    .C3_MEM_ADDR_ORDER("ROW_BANK_COLUMN"),
    .C3_NUM_DQ_PINS(16),
    .C3_MEM_ADDR_WIDTH(13),
    .C3_MEM_BANKADDR_WIDTH(3)
)
u_mig_39 (

    .c3_sys_clk           (clk100),
  .c3_sys_rst_n           (c3_sys_rst_n),                        

  .mcb3_dram_dq           (DDR2DQ),  
  .mcb3_dram_a            (DDR2A),  
  .mcb3_dram_ba           (DDR2BA),
  .mcb3_dram_ras_n        (DDR2RASN),                        
  .mcb3_dram_cas_n        (DDR2CASN),                        
  .mcb3_dram_we_n         (DDR2WEN),                          
  .mcb3_dram_odt          (DDR2ODT),
  .mcb3_dram_cke          (DDR2CKE),                          
  .mcb3_dram_ck           (DDR2CLK0),                          
  .mcb3_dram_ck_n         (DDR2CLK1),       
  .mcb3_dram_dqs          (DDR2LDQS),                          
  .mcb3_dram_dqs_n        (DDR2LDQSN),
  .mcb3_dram_udqs         (DDR2UDQS),    	// for X16 parts                        
  .mcb3_dram_udqs_n       (DDR2UDQSN),  	// for X16 parts
  .mcb3_dram_udm          (DDR2UDM),     // for X16 parts
  .mcb3_dram_dm           (DDR2LDM),

    .c3_clk0		        (c3_clk0),
  .c3_rst0		        (c3_rst0),
	
 
  .c3_calib_done          (c3_calib_done),
     .mcb3_rzq               (DDR2RZQ),
               
     .mcb3_zio               (DDR2ZIO),
    
	// CPU read/write port
   .c3_p0_cmd_clk                          (sys_clk),
   .c3_p0_cmd_en                           (c3_p0_cmd_en),
   .c3_p0_cmd_instr                        (c3_p0_cmd_instr),
   .c3_p0_cmd_bl                           (c3_p0_cmd_bl),
   .c3_p0_cmd_byte_addr                    (c3_p0_cmd_byte_addr),
   .c3_p0_cmd_empty                        (c3_p0_cmd_empty),
   .c3_p0_cmd_full                         (c3_p0_cmd_full),
   .c3_p0_wr_clk                           (sys_clk),
   .c3_p0_wr_en                            (c3_p0_wr_en),
   .c3_p0_wr_mask                          (c3_p0_wr_mask),
   .c3_p0_wr_data                          (c3_p0_wr_data),
   .c3_p0_wr_full                          (c3_p0_wr_full),
   .c3_p0_wr_empty                         (c3_p0_wr_empty),
   .c3_p0_wr_count                         (),
   .c3_p0_wr_underrun                      (),
   .c3_p0_wr_error                         (),
   .c3_p0_rd_clk                           (sys_clk),
   .c3_p0_rd_en                            (c3_p0_rd_en),
   .c3_p0_rd_data                          (c3_p0_rd_data),
   .c3_p0_rd_full                          (c3_p0_rd_full),
   .c3_p0_rd_empty                         (c3_p0_rd_empty),
   .c3_p0_rd_count                         (),
   .c3_p0_rd_overflow                      (),
   .c3_p0_rd_error                         (),

	// Ethmac port
   .c3_p1_cmd_clk                          (sys_clk),
   .c3_p1_cmd_en                           (c3_p1_cmd_en),
   .c3_p1_cmd_instr                        (c3_p1_cmd_instr),
   .c3_p1_cmd_bl                           (c3_p1_cmd_bl),
   .c3_p1_cmd_byte_addr                    (c3_p1_cmd_byte_addr),
   .c3_p1_cmd_empty                        (),
   .c3_p1_cmd_full                         (c3_p1_cmd_full),
   .c3_p1_wr_clk                           (sys_clk),
   .c3_p1_wr_en                            (c3_p1_wr_en),
   .c3_p1_wr_mask                          (c3_p1_wr_mask),
   .c3_p1_wr_data                          (c3_p1_wr_data),
   .c3_p1_wr_full                          (c3_p1_wr_full),
   .c3_p1_wr_empty                         (c3_p1_wr_empty),
   .c3_p1_wr_count                         (),
   .c3_p1_wr_underrun                      (),
   .c3_p1_wr_error                         (),
   .c3_p1_rd_clk                           (sys_clk),
   .c3_p1_rd_en                            (c3_p1_rd_en),
   .c3_p1_rd_data                          (c3_p1_rd_data),
   .c3_p1_rd_full                          (),
   .c3_p1_rd_empty                         (c3_p1_rd_empty),
   .c3_p1_rd_count                         (),
   .c3_p1_rd_overflow                      (),
   .c3_p1_rd_error                         (),
 
	// Bitmap controller read port
   .c3_p2_cmd_clk                          (pixel_clk),
   .c3_p2_cmd_en                           (c3_p2_cmd_en),
   .c3_p2_cmd_instr                        (c3_p2_cmd_instr),	// read with auto-precharge
   .c3_p2_cmd_bl                           (c3_p2_cmd_bl),		// burst length
   .c3_p2_cmd_byte_addr                    (c3_p2_cmd_byte_addr),
   .c3_p2_cmd_empty                        (),
   .c3_p2_cmd_full                         (c3_p2_cmd_full),
   .c3_p2_rd_clk                           (pixel_clk),
   .c3_p2_rd_en                            (c3_p2_rd_en),
   .c3_p2_rd_data                          (c3_p2_rd_data),
   .c3_p2_rd_full                          (),
   .c3_p2_rd_empty                         (c3_p2_rd_empty),
   .c3_p2_rd_count                         (),
   .c3_p2_rd_overflow                      (),
   .c3_p2_rd_error                         (),

	// Graphic accelerator write port
   .c3_p3_cmd_clk                          (sys_clk),
   .c3_p3_cmd_en                           (c3_p3_cmd_en),
   .c3_p3_cmd_instr                        (c3_p3_cmd_instr),
   .c3_p3_cmd_bl                           (c3_p3_cmd_bl),
   .c3_p3_cmd_byte_addr                    (c3_p3_cmd_byte_addr),
   .c3_p3_cmd_empty                        (),
   .c3_p3_cmd_full                         (c3_p3_cmd_full),
   .c3_p3_wr_clk                           (sys_clk),
   .c3_p3_wr_en                            (c3_p3_wr_en),
   .c3_p3_wr_mask						   (c3_p3_wr_mask),
   .c3_p3_wr_data                          (c3_p3_wr_data),
   .c3_p3_wr_full                          (c3_p3_wr_full),
   .c3_p3_wr_empty                         (c3_p3_wr_empty),
   .c3_p3_wr_count                         (),
   .c3_p3_wr_underrun                      (),
   .c3_p3_wr_error                         (),

   .c3_p4_cmd_clk                          (),
   .c3_p4_cmd_en                           (),
   .c3_p4_cmd_instr                        (),
   .c3_p4_cmd_bl                           (),
   .c3_p4_cmd_byte_addr                    (),
   .c3_p4_cmd_empty                        (),
   .c3_p4_cmd_full                         (),
   .c3_p4_rd_clk                           (),
   .c3_p4_rd_en                            (),
   .c3_p4_rd_data                          (),
   .c3_p4_rd_full                          (),
   .c3_p4_rd_empty                         (),
   .c3_p4_rd_count                         (),
   .c3_p4_rd_overflow                      (),
   .c3_p4_rd_error                         (),

	// Sprite image data read port
   .c3_p5_cmd_clk                          (sys_clk),
   .c3_p5_cmd_en                           (c3_p5_cmd_en),
   .c3_p5_cmd_instr                        (c3_p5_cmd_instr),
   .c3_p5_cmd_bl                           (c3_p5_cmd_bl),
   .c3_p5_cmd_byte_addr                    (c3_p5_cmd_byte_addr),
   .c3_p5_cmd_empty                        (),
   .c3_p5_cmd_full                         (c3_p5_cmd_full),
   .c3_p5_rd_clk                           (sys_clk),
   .c3_p5_rd_en                            (c3_p5_rd_en),
   .c3_p5_rd_data                          (c3_p5_rd_data),
   .c3_p5_rd_full                          (),
   .c3_p5_rd_empty                         (c3_p5_rd_empty),
   .c3_p5_rd_count                         (),
   .c3_p5_rd_overflow                      (),
   .c3_p5_rd_error                         ()
);

wire mden,mdi;
assign eth_txd[7:4] = 4'h0;		// not used
always @(posedge sys_clk)
	eth_rst <= ~(rst|btn[1]);
//assign eth_rst = ~(rst|btn[1]);
assign mdio = mden ? mdo : 1'bz;
assign mdi = mdio;
wire [31:0] em_s_dato1;
wire cs_ethmac = io1_cyc && io1_stb && io1_adr[33:14]==20'hFFDC2;
assign em_s_dato = cs_ethmac ? em_s_dato1 : 32'd0;
assign em_bl = 6'd3;	// defined in ethmac_defines

`ifdef ETHMAC
wire cs_bridge5 = em_adr[31:28]==4'h01;// || (thread_area_cs && thread_index!=8'h00);

WB32ToMIG32 u_bridge5
(
	.rst_i(rst),
	.clk_i(sys_clk),	// was pixel_clk

	// WISHBONE PORT
	.bte_i(em_bte),				// burst type extension
	.cti_i(em_cti),				// cycle type indicator
	.cyc_i(em_cyc & cs_bridge5),				// cycle in progress
	.stb_i(em_stb & cs_bridge5),				// data strobe
	.ack_o(bridge5_ack),			// acknowledge
	.we_i(em_we),				// write cycle
	.sel_i(em_sel),				// byte lane selects
	.adr_i(em_adr),				// address
	.dat_i(em_dato),			// data 
	.dat_o(bridge5_dato),
	.bl_i(em_bl),				// burst length

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

ethmac uemac1
(
  // WISHBONE common
  .wb_clk_i(sys_clk),
  .wb_rst_i(rst),

  // WISHBONE slave
  .wb_adr_i(io1_adr[11:2]),
  .wb_sel_i(io1_sel),
  .wb_we_i(io1_we),
  .wb_cyc_i(io1_cyc),
  .wb_stb_i(cs_ethmac),
  .wb_ack_o(em_ack),
  .wb_err_o(em_erro),
  .wb_dat_i(io1_dato),
  .wb_dat_o(em_s_dato1),

  // WISHBONE master
  .m_wb_adr_o(em_adr),
  .m_wb_sel_o(em_sel),
  .m_wb_we_o(em_we), 
  .m_wb_dat_o(em_dato),
  .m_wb_dat_i(em_dati),
  .m_wb_cyc_o(em_cyc), 
  .m_wb_stb_o(em_stb),
  .m_wb_ack_i(bridge5_ack),
  .m_wb_err_i(), 
  .m_wb_cti_o(em_cti),
  .m_wb_bte_o(),

  //TX
  .mtx_clk_pad_i(eth_txclk),
  .mtxd_pad_o(eth_txd[3:0]),
  .mtxen_pad_o(eth_txen),
  .mtxerr_pad_o(eth_txerr),

  //RX
  .mrx_clk_pad_i(eth_rxclk),
  .mrxd_pad_i(eth_rxd[3:0]),
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
assign em_ack = 1'b0;
assign em_s_dato1 = 32'd0;
assign eth_dato1 = 32'd0;
assign eth_txd = 4'h0;
assign eth_txen = 1'b0;
assign eth_txerr = 1'b0;
assign mdc = 1'b0;
assign mdo = 1'b0;
assign mden = 1'b0;
`endif

`ifdef BMPCTRL
WB32ToMIG32 u_bridge1
(
	.rst_i(rst),
	.clk_i(pixel_clk),

	// WISHBONE PORT
	.bte_i(bm_bte),				// burst type extension
	.cti_i(bm_cti),				// cycle type indicator
	.cyc_i(bm_cyc),				// cycle in progress
	.stb_i(bm_stb),				// data strobe
	.ack_o(bm_ack),		// acknowledge
	.we_i(1'b0),				// write cycle
	.sel_i(4'hF),				// byte lane selects
	.adr_i(bm_adr_o[31:0]),			// address
	.dat_i(32'h0000_0000),			// data 
	.dat_o(bm_dat_i),
	.bl_i(bm_bl),				// burst length

	// MIG port
	.calib_done(c3_calib_done),
	.cmd_full(c3_p2_cmd_full),
	.cmd_en(c3_p2_cmd_en),
	.cmd_instr(c3_p2_cmd_instr),
	.cmd_bl(c3_p2_cmd_bl),
	.cmd_byte_addr(c3_p2_cmd_byte_addr),

	.rd_en(c3_p2_rd_en),
	.rd_data(c3_p2_rd_data),
	.rd_empty(c3_p2_rd_empty),

	.wr_en(),
	.wr_mask(),
	.wr_data(),
	.wr_empty(1'b1),
	.wr_full()
);

rtfBitmapController1364x768 ubmc
(
	.rst_i(rst),
	.clk_i(pixel_clk),
	.bte_o(bm_bte),
	.cti_o(bm_cti),
	.bl_o(bm_bl),
	.cyc_o(bm_cyc),
	.stb_o(bm_stb),
	.ack_i(bm_ack),
	.we_o(),
	.sel_o(),
	.adr_o(bm_adr_o),
	.dat_i(bm_dat_i),
	.dat_o(),
	.vclk(pixel_clk),
	.hSync(hsync),
	.vSync(vsync),
	.blank(blank),
	.rgbo(bm_rgb),
	.page(1'b0),
	.onoff(sw[6])
);
`else
`endif

wire [1:0] spr_bte;
wire [2:0] spr_cti;
wire [5:0] spr_bl;
wire spr_cyc;
wire spr_stb;
wire bridge4_ack;
wire spr_we;
wire [3:0] spr_sel;
wire [33:0] spr_adr;
wire [31:0] spr_dat;
wire bridge4_cs = spr_adr[33:28]==6'h1;

`ifdef SPRITE_CTRL
WB32ToMIG32 u_bridge4
(
	.rst_i(rst),
	.clk_i(sys_clk),

	// WISHBONE PORT
	.bte_i(spr_bte),			// burst type extension
	.cti_i(spr_cti),			// cycle type indicator
	.cyc_i(spr_cyc & bridge4_cs),			// cycle in progress
	.stb_i(spr_stb & bridge4_cs),			// data strobe
	.ack_o(bridge4_ack),		// acknowledge
	.we_i(spr_we),				// write cycle
	.sel_i(spr_sel),			// byte lane selects
	.adr_i(spr_adr[31:0]),			// address
	.dat_i(32'h0000_0000),		// data 
	.dat_o(spr_dat),
	.bl_i(spr_bl),				// burst length

	// MIG port
	.calib_done(c3_calib_done),
	.cmd_full(c3_p5_cmd_full),
	.cmd_en(c3_p5_cmd_en),
	.cmd_instr(c3_p5_cmd_instr),
	.cmd_bl(c3_p5_cmd_bl),
	.cmd_byte_addr(c3_p5_cmd_byte_addr),

	.rd_en(c3_p5_rd_en),
	.rd_data(c3_p5_rd_data),
	.rd_empty(c3_p5_rd_empty),

	.wr_en(),
	.wr_mask(),
	.wr_data(),
	.wr_empty(1'b1),
	.wr_full()
);

rtfSpriteController #(.pnSpr(`NSPRITES)) u_sc1
(
	// Bus Slave interface
	//------------------------------
	// Slave signals
	.rst_i(rst),			// reset
	.clk_i(sys_clk),			// clock
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
	.m_bte_o(spr_bte),
	.m_cti_o(spr_cti),
	.m_bl_o(spr_bl),
	.m_cyc_o(spr_cyc),	// cycle is valid
	.m_stb_o(spr_stb),	// strobe output
	.m_ack_i(bridge4_ack),	// input data is ready
	.m_we_o(spr_we),		// write (always inactive)
	.m_sel_o(spr_sel),	// byte select
	.m_adr_o(spr_adr),	// DMA address
	.m_dat_i(spr_dat),	// data input
	.m_dat_o(),	// data output (always zero)
	//--------------------------
	.vclk(pixel_clk),					// video dot clock
	.hSync(hsync),				// horizontal sync pulse
	.vSync(vsync),				// vertical sync pulse
	.blank(blank),				// blanking signal
	.rgbIn(tc_rgb),			// input pixel stream
	.rgbOut(spr_rgb),	// output pixel stream
	.irq(spr_irq)					// interrupt request
);
`endif

`ifdef GACCEL
WB32ToMIG32 u_bridge3
(
	.rst_i(rst),
	.clk_i(sys_clk),

	// WISHBONE PORT
	.bte_i(2'b00),				// burst type extension
	.cti_i(3'b000),				// cycle type indicator
	.cyc_i(ga_cyc),				// cycle in progress
	.stb_i(ga_stb),				// data strobe
	.ack_o(bridge3_ack),		// acknowledge
	.we_i(ga_we),				// write cycle
	.sel_i(ga_sel),				// byte lane selects
	.adr_i(ga_adr),			// address
	.dat_i(ga_dato),			// data 
	.dat_o(),
	.bl_i(6'd0),				// burst length

	// MIG port
	.calib_done(c3_calib_done),
	.cmd_full(c3_p3_cmd_full),
	.cmd_en(c3_p3_cmd_en),
	.cmd_instr(c3_p3_cmd_instr),
	.cmd_bl(c3_p3_cmd_bl),
	.cmd_byte_addr(c3_p3_cmd_byte_addr),

	.rd_en(),
	.rd_data(),
	.rd_empty(),

	.wr_en(c3_p3_wr_en),
	.wr_mask(c3_p3_wr_mask),
	.wr_data(c3_p3_wr_data),
	.wr_empty(c3_p3_wr_empty),
	.wr_full(c3_p3_wr_full)
);

rtfGraphicsAccelerator u_ga1
(
	.rst_i(rst),
	.clk_i(sys_clk),

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
	.clk_i(sys_clk),
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
	.clk_i(sys_clk),
	.s_cyc_i(cpu_cyc),
	.s_stb_i(cpu_stb),
	.s_ack_o(iob3_ack),
	.s_sel_i(cpu_sel),
	.s_we_i(cpu_we),
	.s_adr_i(cpu_adr),
	.s_dat_i(cpu_dato),
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
	.clk_i(sys_clk),	// eg 100.7MHz
	.cyc_i(io1_cyc),	// cycle valid
	.stb_i(io1_stb),	// strobe
	.we_i(io1_we),			// 1 = write
	.adr_i(io1_adr[33:2]),		// register address
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
	.clk_i(sys_clk),
	.s_cyc_i(cpu_cyc),
	.s_stb_i(cpu_stb),
	.s_ack_o(iob2_ack),
	.s_sel_i(cpu_sel),
	.s_we_i(cpu_we),
	.s_adr_i(cpu_adr),
	.s_dat_i(cpu_dato),
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
	.clk_i(sys_clk),
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
	.clk_i(sys_clk),
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

AC97 u_ac97
(
	.rst_i(rst),			// The clock here must be fast enough not to miss BITCLKs
	.clk_i(pixel_clk),		// 85.7 MHz clock
	.cyc_i(io2_cyc),
	.stb_i(io2_stb),
	.ack_o(ac97_ack),
	.we_i(io2_we),
	.adr_i(io2_adr),
	.dat_i(io2_dato[15:0]),
	.dat_o(ac97_dato),
	.PSGout(psg_out),
	.BIT_CLK(BITCLK),
	.SYNC(AUDSYNC),
	.SDATA_IN(AUDSDI),
	.SDATA_OUT(AUDSDO),
	.RESET(AUDRST)
);
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
	.clk_i(sys_clk),
	.s_cyc_i(cpu_cyc),
	.s_stb_i(cpu_stb),
	.s_ack_o(iob1_ack),
	.s_sel_i(cpu_sel),
	.s_we_i(cpu_we),
	.s_adr_i(cpu_adr),
	.s_dat_i(cpu_dato),
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
wire spi_cs = io1_cyc && io1_stb && io1_adr[33:10]==26'hFFDC05;
assign spi_dato = spi_cs ? spi_dato1 : 32'h00;

spiMaster uspi1
(
	.clk_i(sys_clk),
	.rst_i(rst),
	.address_i(io1_adr[7:2]),
	.data_i(io1_dato[7:0]),
	.data_o(spi_dato1),
	.strobe_i(spi_cs),
	.we_i(io1_we),
	.ack_o(spi_ack),

	// SPI logic clock
	// Sync to clk_i causes problems maybe
	.spiSysClk(sys_clk),	// 25MHz

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

wire cs_mem = cpu_adr[33:28]==6'h01;// || (thread_area_cs && thread_index!=8'h00);

WB32ToMIG32 u_bridge2
(
	.rst_i(rst),
	.clk_i(sys_clk),

	// WISHBONE PORT
	.bte_i(2'b00),					// burst type extension
	.cti_i(cpu_cti),					// cycle type indicator
	.cyc_i(cpu_cyc & cs_mem),				// cycle in progress
	.stb_i(cpu_stb & cs_mem),						// data strobe
	.ack_o(bridge_ack),						// acknowledge
	.we_i(cpu_we),							// write cycle
	.sel_i(cpu_sel),					// byte lane selects
	.adr_i(mem_adr),					// address
	.dat_i(cpu_dato),			// data 
	.dat_o(bridge_dato),
	.bl_i(cpu_bl),				// burst length

	// MIG port
	.calib_done(c3_calib_done),
	.cmd_full(c3_p0_cmd_full),
	.cmd_en(c3_p0_cmd_en),
	.cmd_instr(c3_p0_cmd_instr),
	.cmd_bl(c3_p0_cmd_bl),
	.cmd_byte_addr(c3_p0_cmd_byte_addr),

	.rd_en(c3_p0_rd_en),
	.rd_data(c3_p0_rd_data),
	.rd_empty(c3_p0_rd_empty),

	.wr_en(c3_p0_wr_en),
	.wr_mask(c3_p0_wr_mask),
	.wr_data(c3_p0_wr_data),
	.wr_empty(c3_p0_wr_empty),
	.wr_full(c3_p0_wr_full)
);

wire km;

`ifdef MMU
SimpleMMU smmu1
(
	.num(3'd0),
	.rst_i(rst),
	.clk_i(sys_clk),
	.dma_i(1'b0),
	.kernel_mode(km),
	.me(1'b1),
	.cyc_i(io1_cyc),
	.stb_i(io1_stb),
	.ack_o(mmu_ack),
	.we_i(io1_we),
	.adr_i(io1_adr),
	.dat_i(io1_dato[15:0]),
	.dat_o(mmu_dato),
	.ea_i(cpu_adr),
	.ea_o(mem_adr)
);
`else
assign mem_adr = cpu_adr;
assign mmu_ack = 1'b0;
assign mmu_dato = 16'h0000;
`endif

`ifdef DATETIME
rtfDatetime udt1
(
	// Syscon
	.rst_i(rst),		// reset
	.clk_i(sys_clk),	// system clock

	// System bus
	.cyc_i(io4_cyc),	// valid bus cycle
	.stb_i(io4_stb),	// data transfer strobe
	.ack_o(dt_ack),		// transfer acknowledge
	.we_i(io4_we),		// 1=write
	.sel_i(io4_sel),	// byte select
	.adr_i(io4_adr),	// address
	.dat_i(io4_dato),	// data input
	.dat_o(dt_dato),	// data output

	.tod(pulse100Hz),	// tod pulse (eg 60 Hz)
	.alarm()			// alarm match
);
`else
assign dt_ack = 1'b0;
assign dt_dato = 32'h0;
`endif

IOBridge uio4 
(
	.rst_i(rst),
	.clk_i(sys_clk),
	.s_cyc_i(cpu_cyc),
	.s_stb_i(cpu_stb),
	.s_ack_o(iob4_ack),
	.s_sel_i(cpu_sel),
	.s_we_i(cpu_we),
	.s_adr_i(cpu_adr),
	.s_dat_i(cpu_dato),
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

wire berr;
BusError ube1
(
	.rst_i(rst),
	.clk_i(sys_clk),
	.cyc_i(cpu_cyc),
	.ack_i(cpu_ack),
	.stb_i(cpu_stb),
	.adr_i(cpu_adr),
	.err_o(berr)
);

scratchmem uscm1
(
	.rst_i(rst),
	.clk_i(sys_clk),
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
	.clk_i(sys_clk),
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

basic_rom ubasr1
(
	.rst_i(rst),
	.clk_i(sys_clk),
	.cti_i(cpu_cti),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(bas_ack),
	.adr_i(cpu_adr),
	.dat_o(bas_dato),
	.perr()
);

wire perr;
bootrom ubr1
(
	.rst_i(rst),
	.clk_i(sys_clk),
	.cti_i(cpu_cti),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(btrm_ack),
	.adr_i(cpu_adr),
	.dat_o(btrm_dato),
	.perr(perr)
);

sema_mem usm1
(
	.rst_i(rst),
	.clk_i(sys_clk),
	.cyc_i(cpu_cyc),
	.stb_i(cpu_stb),
	.ack_o(sema_ack),
	.we_i(cpu_we),
	.adr_i(cpu_adr),
	.dat_i(cpu_dato),
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

RTF65002PIC u_pic
(
	.rst_i(rst),		// reset
	.clk_i(sys_clk),	// system clock
	.cyc_i(io4_cyc),	// cycle valid
	.stb_i(io4_stb),	// strobe
	.ack_o(pic_ack),	// transfer acknowledge
	.we_i(io4_we),		// write
	.adr_i(io4_adr),	// address
	.dat_i(io4_dato),
	.dat_o(pic_dato),
	.vol_o(),			// volatile register selected
	.i1(kbd_rst),
	.i2(pulse1000Hz),
	.i3(pulse100Hz),
	.i4(em_int),
	.i5(),
	.i6(),
	.i7(),
	.i8(uart_irq),
	.i9(),
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

assign cpu_irq = cpu_irq1 & sw[7];

rtf65002d ucpu1 (
	.rst_md(1'b0),	// native mode on reset
	.rst_i(rst),
	.clk_i(sys_clk),
	.nmi_i(cpu_nmi),
	.irq_i(cpu_irq),
	.irq_vect(vecno),
	.bte_o(), 
	.cti_o(cpu_cti),
	.bl_o(cpu_bl),
	.lock_o(), 
	.cyc_o(cpu_cyc),
	.stb_o(cpu_stb),
	.ack_i(cpu_ack),
	.err_i(berr),
	.we_o(cpu_we),
	.sel_o(cpu_sel),
	.adr_o(cpu_adr),
	.dat_i(cpu_dati),
	.dat_o(cpu_dato),
	.km_o(km)
);

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

assign config_rec_ack = io4_cyc && io4_stb && io4_adr[33:4]==30'b1111_1111_1101_1100_1111_1111_1111_00;	// $FFDCFFF0-$FFDCFFF3
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
