// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Petajon-SoM.v
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
`define TEXT_CONTROLLER	1'b1
`define BMP_CONTROLLER	1'b1
`define SPRITE_CONTROLLER	1'b1
`define RANDOM_GEN	1'b1

module Petajon_SoM(sys_rst, sys_clk_i, clk8, clk14,
	led_1, /*init_calib_complete,*/
	FAD, FALE, FRD, FBEN, FCDIR, FBDIR, FRDYN, RDYN, FMRQ, MS, FINT, FINTA,
	KBDDAT, KBDCLK, MSEDAT, MSECLK,
	AUD, uart_rxd, uart_txd, randi,
	HCLKN, HCLKP, HD0N, HD0P, HD1N, HD1P, HD2N, HD2P,
	FTCLKN, FTCLKP, FTDAT0N, FTDAT0P, FTDAT1N, FTDAT1P, FTDAT2N, FTDAT2P, FTDAT3N, FTDAT3P,
	FTDAT4N, FTDAT4P, FTDAT5N, FTDAT5P, FTDAT6N, FTDAT6P, FTDAT7N, FTDAT7P, FTDAT8N, FTDAT8P, 
	FTDAT9N, FTDAT9P, FTDAT10N, FTDAT10P, 
	FRCLKN, FRCLKP, FRDAT0N, FRDAT0P, FRDAT1N, FRDAT1P, FRDAT2N, FRDAT2P, FRDAT3N, FRDAT3P, 
	FRDAT4N, FRDAT4P, FRDAT5N, FRDAT5P, FRDAT6N, FRDAT6P, FRDAT7N, FRDAT7P, FRDAT8N, FRDAT8P, 
	FRDAT9N, FRDAT9P, FRDAT10N, FRDAT10P, 
	FDIOWN, FDIORN, FCS1FXN, FCS3FXN, DRDYN, DDIR, DBENN, RESETN,
`ifndef SIM
    ,ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_reset_n,ddr3_ras_n,ddr3_cas_n,ddr3_we_n,
    ddr3_ba,ddr3_addr,ddr3_dq,ddr3_dqs_p,ddr3_dqs_n,ddr3_dm,ddr3_odt
`endif
);
input sys_rst;
input sys_clk_i;
output clk8;
output clk14;
output reg led_1;
//output init_calib_complete;
inout [7:0] FAD;
tri [7:0] FAD;
inout FALE;
tri FALE;
inout FRD;
tri FRD;
output FBEN;
reg FBEN;
output reg FCDIR;
output reg FBDIR;
input FRDYN;
output reg RDYN;
input [6:0] FMRQ;
output [2:0] MS;
output FINTA;
input FINT;
inout KBDDAT;
tri KBDDAT;
inout KBDCLK;
tri KBDCLK;
inout MSEDAT;
tri MSEDAT;
inout MSECLK;
tri MSECLK;
output AUD;
input uart_rxd;
output uart_txd;
input randi;
output HCLKN;
output HCLKP;
output HD0N;
output HD0P;
output HD1N;
output HD1P;
output HD2N;
output HD2P;
output FTCLKN;
output FTCLKP;
output FTDAT0N;
output FTDAT0P;
output FTDAT1N;
output FTDAT1P;
output FTDAT2N;
output FTDAT2P;
output FTDAT3N;
output FTDAT3P;
output FTDAT4N;
output FTDAT4P;
output FTDAT5N;
output FTDAT5P;
output FTDAT6N;
output FTDAT6P;
output FTDAT7N;
output FTDAT7P;
output FTDAT8N;
output FTDAT8P;
output FTDAT9N;
output FTDAT9P;
output FTDAT10N;
output FTDAT10P;
input FRCLKN;
input FRCLKP;
input FRDAT0N;
input FRDAT0P;
input FRDAT1N;
input FRDAT1P;
input FRDAT2N;
input FRDAT2P;
input FRDAT3N;
input FRDAT3P;
input FRDAT4N;
input FRDAT4P;
input FRDAT5N;
input FRDAT5P;
input FRDAT6N;
input FRDAT6P;
input FRDAT7N;
input FRDAT7P;
input FRDAT8N;
input FRDAT8P;
input FRDAT9N;
input FRDAT9P;
input FRDAT10N;
input FRDAT10P;
output FDIOWN;
output FDIORN;
output FCS1FXN;
output FCS3FXN;
input DRDYN;
output DDIR;
output DBENN;
input RESETN;

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

parameter LOW = 1'b0;
parameter HIGH = 1'b1;

reg [1:0] active_ch;
reg xcs;
reg xcyc;
reg xstb;
reg xack;
reg xwe;
reg [3:0] xsel;
reg [31:0] xadr;
reg [31:0] xdati;
reg [31:0] xdatil;
reg [31:0] FIRQ;
parameter C7W = 32;
wire [2:0] cti;
wire cyc;
wire stb, ack;
wire we;
wire [3:0] sel;
wire [31:0] adr;
reg [31:0] dati = 32'd0;
wire [31:0] dato;
wire sr,cr,rb;
wire pclk;
reg pack;
reg [31:0] pbus_dati;
wire [35:0] packeti0, packeti1, packeti2;
reg [35:0] packetir0, packetir1, packetir2;

wire br_ack;
wire [31:0] br_dato;
wire ack_scr;
wire [31:0] scr_dato;

parameter BMPW = 128;
wire bmp_ack;
wire [31:0] bmp_cdato;
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

wire spr_ack;
wire [63:0] spr_dato;
wire spr_cyc;
wire spr_stb;
wire spr_acki;
wire spr_we;
wire [7:0] spr_sel;
wire [31:0] spr_adr;
wire [63:0] spr_dati;
wire [31:0] spr_rgbo;
wire [5:0] spr_spriteno;

wire [15:0] aud0, aud1, aud2, aud3;
wire [15:0] audi;
wire aud_cyc;
wire aud_stb;
wire aud_acki;
wire aud_we;
wire [1:0] aud_sel;
wire [31:0] aud_adr;
wire [15:0] aud_dati;
wire [15:0] aud_dato;
wire aud_ack;
wire [31:0] aud_cdato;

wire br1_cyc;
wire br1_stb;
reg br1_ack = 1'b0;
wire br1_we;
wire [3:0] br1_sel;
wire [31:0] br1_adr;
wire [31:0] br1_cdato;
wire [31:0] br1_cdato2;
wire br1_s2_ack;
wire [31:0] br1_s2_cdato;
wire [31:0] br1_dato;
wire [7:0] br1_dat8;
reg [31:0] br1_dati = 32'd0;

wire ack_bridge2;
wire ack_bridge2a;
wire br2_cyc;
wire br2_stb;
reg br2_ack = 1'b0;
wire br2_we;
wire [3:0] br2_sel;
wire [31:0] br2_adr;
wire [31:0] br2_adr32;
wire [31:0] br2_cdato;
wire [31:0] br2_cdato2;
wire [31:0] br2_dato;
wire [7:0] br2_dat8;
reg [31:0] br2_dati = 32'd0;

wire br3_cyc;
wire br3_stb;
reg br3_ack = 1'b0;
wire br3_we;
wire [3:0] br3_sel;
wire [31:0] br3_adr;
wire [31:0] br3_cdato;
wire [31:0] br3_dato;
wire [7:0] br3_dat8;
reg [31:0] br3_dati = 32'd0;

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

wire kbd_ack;
wire [7:0] kbd_dato;
wire kbd_irq;
wire mse_ack;
wire [7:0] mse_dato;
wire mse_irq;
wire rnd_ack;
wire [31:0] rnd_dato;

wire ack_pic;
wire [31:0] pic_dato;
wire ack_sema;
wire [7:0] sema_dato;
wire ack_mut;
wire [63:0] mut_dato;
wire pmc_ack;
wire [31:0] pmc_dato;
wire uart_ack;
wire [31:0] uart_dato;
wire [31:0] randnum;

wire dram_ack1;

wire clk40, clk71, clk80, clk100, clk200, clk500;
wire cpu_clk = clk40;
wire rst, rstn;
wire [7:0] red, green, blue;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Clock generation.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire bsys_clk;
BUFGCE uclkb1 (.CE(1'b1), .I(sys_clk_i), .O(bsys_clk));


Petajon_clkgen ucg1
(
  .clk200(clk200),
  .clk100(clk100),
  .clk40(clk40),
  .clk14(clk14),			// 14.31818...
  .clk8(clk8),				// 8.1818181...
  .reset(sys_rst),
  .locked(locked),
  .clk_in1(bsys_clk)
);

assign rst = !locked;

Petajon_clkgen3 ucg3
(
	.clk500(clk500),
  .clk71(clk71),
  .reset(sys_rst),
  .locked(),
  .clk_in1(bsys_clk)
);


rgb2dvi #(
	.kGenerateSerialClk(1'b0),
	.kClkPrimitive("MMCM"),
	.kClkRange(3),
	.kRstActiveHigh(1'b1)
)
ur2d1 
(
	.TMDS_Clk_p(HCLKP),
	.TMDS_Clk_n(HCLKN),
	.TMDS_Data_p({HD2P,HD1P,HD0P}),
	.TMDS_Data_n({HD2N,HD1N,HD0N}),
	.aRst(rst),
	.aRst_n(~rst),
	.vid_pData({red,blue,green}),
	.vid_pVDE(~blank),
	.vid_pHSync(hSync),    // hSync is neg going for 1366x768
	.vid_pVSync(vSync),
	.PixelClk(clk40),
	.SerialClk(clk200)
);


reg [35:0] packet0;
OPCBusTransmitter #(
	.kGenerateSerialClk(1'b0),
	.kClkPrimitive("MMCM"),
	.kClkRange(2),
	.kRstActiveHigh(1'b1)
)
uopct1
(
	.TMDS_Clk_p(FTCLKP),
	.TMDS_Clk_n(FTCLKN),
	.TMDS_Data_p({FTDAT2P,FTDAT1P,FTDAT0P}),
	.TMDS_Data_n({FTDAT2N,FTDAT1N,FTDAT0N}),
	.aRst(rst),
	.aRst_n(~rst),
	.vid_pData(packet0),
	.vid_pVDE(1'b1),
	.vid_pHSync(1'b0),
	.vid_pVSync(1'b0),
	.PixelClk(clk71),
	.SerialClk(clk500)
);

reg [35:0] packet1;
OPCBusTransmitter #(
	.kGenerateSerialClk(1'b0),
	.kClkPrimitive("MMCM"),
	.kClkRange(2),
	.kRstActiveHigh(1'b1)
)
uopct2
(
	.TMDS_Clk_p(FTDAT3P),
	.TMDS_Clk_n(FTDAT3N),
	.TMDS_Data_p({FTDAT6P,FTDAT5P,FTDAT4P}),
	.TMDS_Data_n({FTDAT6N,FTDAT5N,FTDAT4N}),
	.aRst(rst),
	.aRst_n(~rst),
	.vid_pData(packet0),
	.vid_pVDE(1'b1),
	.vid_pHSync(1'b0),
	.vid_pVSync(1'b0),
	.PixelClk(clk71),
	.SerialClk(clk500)
);

reg [35:0] packet2;
OPCBusTransmitter #(
	.kGenerateSerialClk(1'b0),
	.kClkPrimitive("MMCM"),
	.kClkRange(2),
	.kRstActiveHigh(1'b1)
)
uopct3
(
	.TMDS_Clk_p(FTDAT7P),
	.TMDS_Clk_n(FTDAT7N),
	.TMDS_Data_p({FTDAT10P,FTDAT9P,FTDAT8P}),
	.TMDS_Data_n({FTDAT10N,FTDAT9N,FTDAT8N}),
	.aRst(rst),
	.aRst_n(~rst),
	.vid_pData(packet0),
	.vid_pVDE(1'b1),
	.vid_pHSync(1'b0),
	.vid_pVSync(1'b0),
	.PixelClk(clk71),
	.SerialClk(clk500)
);

OPCBusReceiver #
(
	.kEmulateDDC(1'b0),	// : boolean := true; --will emulate a DDC EEPROM with basic EDID, if set to yes 
	.kRstActiveHigh(1'b1),	// : boolean := true; --true, if active-high; false, if active-low
	.kAddBUFG(1'b1),	// : boolean := true; --true, if PixelClk should be re-buffered with BUFG 
	.kClkRange(2),// : natural := 2;  -- MULT_F = kClkRange*7 (choose >=120MHz=1, >=60MHz=2, >=40MHz=3)
	.kEdidFileName("900p_edid.txt"),//;  -- Select EDID file to use
	//-- 7-series specific
	.kIDLY_TapValuePs(78),// : natural := 78; --delay in ps per tap
	.kIDLY_TapWidth(5)// : natural := 5
) // number of bits for IDELAYE2 tap counter   
uopcr1
(
	// -- DVI 1.0 TMDS video interface
	.TMDS_Clk_p(FRCLKP),	// : in std_logic;
	.TMDS_Clk_n(FRCLKN),	// : in std_logic;
	.TMDS_Data_p({FRDAT2P,FRDAT1P,FRDAT0P}),// : in std_logic_vector(2 downto 0);
	.TMDS_Data_n({FRDAT2N,FRDAT1N,FRDAT0N}),// : in std_logic_vector(2 downto 0);

	//-- Auxiliary signals 
	.RefClk(clk200),// : in std_logic; --200 MHz reference clock for IDELAYCTRL, reset, lock monitoring etc.
	.aRst(rst),	// : in std_logic; --asynchronous reset; must be reset when RefClk is not within spec
	.aRst_n(~rst),	// : in std_logic; --asynchronous reset; must be reset when RefClk is not within spec

	//-- Video out
	.vid_pData(packeti0),// : out std_logic_vector(23 downto 0);
	.vid_pVDE(),	// : out std_logic;
	.vid_pHSync(),	// : out std_logic;
	.vid_pVSync(),	// : out std_logic;

	.PixelClk(pclk),	// : out std_logic; --pixel-clock recovered from the DVI interface

	.SerialClk(),	// : out std_logic; -- advanced use only; 5x PixelClk
	.aPixelClkLckd(),// : out std_logic; -- advanced use only; PixelClk and SerialClk stable

	//-- Optional DDC port
	.DDC_SDA_I(1'b1),// : in std_logic;
	.DDC_SDA_O(),// : out std_logic;
	.DDC_SDA_T(),// : out std_logic;
	.DDC_SCL_I(1'b1),// : in std_logic;
	.DDC_SCL_O(),// : out std_logic; 
	.DDC_SCL_T(),// : out std_logic;

	.pRst(rst),	// : in std_logic; -- synchronous reset; will restart locking procedure
	.pRst_n(~rst)	// : in std_logic -- synchronous reset; will restart locking procedure
);


OPCBusReceiver #
(
	.kEmulateDDC(1'b0),	// : boolean := true; --will emulate a DDC EEPROM with basic EDID, if set to yes 
	.kRstActiveHigh(1'b1),	// : boolean := true; --true, if active-high; false, if active-low
	.kAddBUFG(1'b1),	// : boolean := true; --true, if PixelClk should be re-buffered with BUFG 
	.kClkRange(2),// : natural := 2;  -- MULT_F = kClkRange*7 (choose >=120MHz=1, >=60MHz=2, >=40MHz=3)
	.kEdidFileName("900p_edid.txt"),//;  -- Select EDID file to use
	//-- 7-series specific
	.kIDLY_TapValuePs(78),// : natural := 78; --delay in ps per tap
	.kIDLY_TapWidth(5)// : natural := 5
) // number of bits for IDELAYE2 tap counter   
uopcr2
(
	// -- DVI 1.0 TMDS video interface
	.TMDS_Clk_p(FRDAT3P),	// : in std_logic;
	.TMDS_Clk_n(FRDAT3N),	// : in std_logic;
	.TMDS_Data_p({FRDAT6P,FRDAT5P,FRDAT4P}),// : in std_logic_vector(2 downto 0);
	.TMDS_Data_n({FRDAT6N,FRDAT5N,FRDAT4N}),// : in std_logic_vector(2 downto 0);

	//-- Auxiliary signals 
	.RefClk(clk200),// : in std_logic; --200 MHz reference clock for IDELAYCTRL, reset, lock monitoring etc.
	.aRst(rst),	// : in std_logic; --asynchronous reset; must be reset when RefClk is not within spec
	.aRst_n(~rst),	// : in std_logic; --asynchronous reset; must be reset when RefClk is not within spec

	//-- Video out
	.vid_pData(packeti1),// : out std_logic_vector(23 downto 0);
	.vid_pVDE(),	// : out std_logic;
	.vid_pHSync(),	// : out std_logic;
	.vid_pVSync(),	// : out std_logic;

	.PixelClk(pclk),	// : out std_logic; --pixel-clock recovered from the DVI interface

	.SerialClk(),	// : out std_logic; -- advanced use only; 5x PixelClk
	.aPixelClkLckd(),// : out std_logic; -- advanced use only; PixelClk and SerialClk stable

	//-- Optional DDC port
	.DDC_SDA_I(1'b1),// : in std_logic;
	.DDC_SDA_O(),// : out std_logic;
	.DDC_SDA_T(),// : out std_logic;
	.DDC_SCL_I(1'b1),// : in std_logic;
	.DDC_SCL_O(),// : out std_logic; 
	.DDC_SCL_T(),// : out std_logic;

	.pRst(rst),	// : in std_logic; -- synchronous reset; will restart locking procedure
	.pRst_n(~rst)	// : in std_logic -- synchronous reset; will restart locking procedure
);


OPCBusReceiver #
(
	.kEmulateDDC(1'b0),	// : boolean := true; --will emulate a DDC EEPROM with basic EDID, if set to yes 
	.kRstActiveHigh(1'b1),	// : boolean := true; --true, if active-high; false, if active-low
	.kAddBUFG(1'b1),	// : boolean := true; --true, if PixelClk should be re-buffered with BUFG 
	.kClkRange(2),// : natural := 2;  -- MULT_F = kClkRange*7 (choose >=120MHz=1, >=60MHz=2, >=40MHz=3)
	.kEdidFileName("900p_edid.txt"),//;  -- Select EDID file to use
	//-- 7-series specific
	.kIDLY_TapValuePs(78),// : natural := 78; --delay in ps per tap
	.kIDLY_TapWidth(5)// : natural := 5
) // number of bits for IDELAYE2 tap counter   
uopcr3
(
	// -- DVI 1.0 TMDS video interface
	.TMDS_Clk_p(FRDAT7P),	// : in std_logic;
	.TMDS_Clk_n(FRDAT7N),	// : in std_logic;
	.TMDS_Data_p({FRDAT10P,FRDAT9P,FRDAT8P}),// : in std_logic_vector(2 downto 0);
	.TMDS_Data_n({FRDAT10N,FRDAT9N,FRDAT8N}),// : in std_logic_vector(2 downto 0);

	//-- Auxiliary signals 
	.RefClk(clk200),// : in std_logic; --200 MHz reference clock for IDELAYCTRL, reset, lock monitoring etc.
	.aRst(rst),	// : in std_logic; --asynchronous reset; must be reset when RefClk is not within spec
	.aRst_n(~rst),	// : in std_logic; --asynchronous reset; must be reset when RefClk is not within spec

	//-- Video out
	.vid_pData(packeti2),// : out std_logic_vector(23 downto 0);
	.vid_pVDE(),	// : out std_logic;
	.vid_pHSync(),	// : out std_logic;
	.vid_pVSync(),	// : out std_logic;

	.PixelClk(pclk),	// : out std_logic; --pixel-clock recovered from the DVI interface

	.SerialClk(),	// : out std_logic; -- advanced use only; 5x PixelClk
	.aPixelClkLckd(),// : out std_logic; -- advanced use only; PixelClk and SerialClk stable

	//-- Optional DDC port
	.DDC_SDA_I(1'b1),// : in std_logic;
	.DDC_SDA_O(),// : out std_logic;
	.DDC_SDA_T(),// : out std_logic;
	.DDC_SCL_I(1'b1),// : in std_logic;
	.DDC_SCL_O(),// : out std_logic; 
	.DDC_SCL_T(),// : out std_logic;

	.pRst(rst),	// : in std_logic; -- synchronous reset; will restart locking procedure
	.pRst_n(~rst)	// : in std_logic -- synchronous reset; will restart locking procedure
);


reg [3:0] cnt64;
reg [5:0] state64;
parameter IDLE = 5'd0;
parameter ST1 = 5'd1;
parameter ST2 = 5'd2;
parameter ST3 = 5'd3;
parameter ST4 = 5'd4;
parameter ST5 = 5'd5;
parameter ST6 = 5'd6;
always @(posedge clk71)
begin
case(state64)
IDLE:
	begin
		packet0 <= 24'hFFFFFF;
		if (cyc & stb & master & cs_pbus) begin
			packet0 <= {4'h0,adr[31:12]};
			state64 <= we ? ST2 : ST6;
		end
	end
ST2:
	begin
		packet0 <= {4'h1,adr[11:0],dato[31:24]};
		state64 <= ST3;
	end
ST3:
	begin
		packet0 <= {4'h2,dato[23:4]};
		state64 <= ST4;
	end
ST4:
	begin
		packet0 <= {4'h3,dato[3:0],sel[3:0],12'hAAA};
		state64 <= ST5;
	end
ST5:
	begin
		packet0 <= 24'hFFFFFF;
		state64 <= IDLE;
	end
ST6:
	begin
		packet0 <= {4'h4,adr[11:0],sel[3:0],4'h5};
	end
default:	state64 <= IDLE;
endcase
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Address decode
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg cs_br;
wire cs_dram = adr[31:29]==3'h0;		// Main memory 512MB
always @*
	cs_br <= adr[31:16]==16'hFFFC		// Boot rom 192k
				|| adr[31:16]==16'hFFFD
				|| adr[31:16]==16'hFFFE;
wire cs_xbus = adr[31:28]==4'd1;			// external parallel
wire cs_pbus = |adr[31:28] && adr[31:24]!=8'hFF && !cs_xbus;	// external serial bus
wire cs_scr = adr[31:22]==10'b1111_1111_01;	// Scratchpad memory 64k
// No need to check for the $FFD in the top 12 address bits as these are 
// detected in the I/O bridges.
wire cs_tc1 = br1_adr[19:16]==4'h0	// FFD0xxxx Text Controller 128k
					||  br1_adr[19:16]==4'h1;
wire cs_spr = br1_adr[19:12]==8'hAD;	// FFDADxxx	Sprite Controller
wire cs_bmp = br1_adr[19:12]==8'hC5;	//          Bitmap Controller
wire cs_pic = br1_adr[19:8]==12'hC0F;
wire cs_sema = br1_adr[19:12]==8'hB0;
wire cs_mut = br1_adr[19:8]==12'hBFF;

wire cs_grnd = br2_adr[19:4]==12'hC0BF;	// RNG random number (low speed)
wire cs_rnd = br2_adr[19:8]==12'hC0C;		// PRNG random number generator
wire cs_kbd  = br2_adr[19:4]==16'hC000;		// keyboard controller
wire cs_mse  = br2_adr[19:4]==16'hC001;		// mouse controller
wire cs_aud  = br2_adr[19:8]==12'h510;		// audio controller
wire cs_pmc = br2_adr[19:4]==16'hC00F;
wire cs_uart = br2_adr[19:4]==16'hC0A0;

wire cs_bridge1 = (cs_tc1 | cs_spr | cs_bmp | cs_pic | cs_sema | cs_mut);
wire cs_bridge2 = (cs_rnd | cs_kbd | cs_mse | cs_aud | cs_uart | cs_grnd);
wire cs_bridge3 = 1'b0;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Bus bridge.
// Connect the internal and external busses.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire master = MS==3'd7;
reg [4:0] state;
parameter tALEw = 6'd4;
parameter tCMDw = 6'd4;

reg [31:0] FADO;
reg FALEO;
reg [3:0] FSELO;
reg FRDO;
wire bus_idle = state==IDLE && !(cyc & stb & master & cs_xbus);
reg [5:0] cnt;
wire cntdone = cnt[5];
always @(posedge clk80)
if (rst) begin
	xack <= LOW;
	FADO <= 32'h0;
	FALEO <= LOW;
	FSELO <= 4'h0;
	FBEN <= HIGH;		// Disable buffers
	FCDIR <= HIGH;	// Set direction to input
	FBDIR <= HIGH;
	FRDO <= HIGH;
	cnt <= 6'd0;
end
else
case(state)
IDLE:
	if (cyc & stb & master & cs_xbus) begin
		FBEN <= LOW;		// Enable buffers
		FADO <= adr;		// Place address
		FSELO <= sel;
		FCDIR <= LOW;	// Set direction to output
		FBDIR <= LOW;
		FRDO <= ~we;
		cnt <= tALEw;
		state <= ST1;
	end
ST1:
	begin
		cnt <= cnt - 2'd1;
		FALEO <= HIGH;
		if (cntdone) begin
			FALEO <= LOW;
			state <= ST2;
		end
	end
ST2:
	begin
		state <= ST3;
	end
ST3:
	begin
		FADO <= dato;
		// If it's a read cycle switch buffer direction.
		if (~we)
			FBDIR <= HIGH;
		state <= ST4;
		cnt <= tCMDw;
	end
ST4:
	begin
		if (~FRDYN)
			cnt <= cnt - 2'd1;
		if (cntdone) begin
			xack <= HIGH;
			FBDIR <= LOW;
			xdatil <= FAD;
			state <= ST5;
		end
	end	
ST5:
	begin
		FBEN <= HIGH;	// Disable buffers.
		state <= ST6;
		if (~(cyc & stb)) begin
			xack <= LOW;
			FCDIR <= HIGH;	// Set drivers back to input
			FBDIR <= HIGH;
			state <= IDLE;
		end
	end
default:	state <= IDLE;
endcase

assign FAD = FBDIR ? 32'bz : FADO;
assign FALE = FCDIR ? 1'bz : FALEO;
assign FSEL = FCDIR ? 4'bz : FSELO;
assign FRD = FCDIR ? 1'bz : FRDO;

always @(posedge clk80)
	if (~master & FALE) begin
		xadr <= FAD;
		xcs <= 1'b0;
	end
always @(posedge clk80)
	if (~FALE)
		xdati <= FAD;
always @(posedge clk80)
	if (~master)
		xsel <= FSEL;
	else
		xsel <= 4'h0;
always @(posedge clk80)
	if (~master)
		xwe <= ~FRD;
	else
		xwe <= LOW;
always @(posedge clk80)
	if (~master & FALE) begin
		xcyc <= HIGH;
		xstb <= HIGH;
	end
	else if (dram_ack1) begin
		xcyc <= LOW;
		xstb <= LOW;
	end
// ToDo: ready line

always @(posedge clk80)
	if (FINTA)
		FIRQ <= FAD;

always @(posedge clk71)
begin
	packetir0 <= packeti0;	// register across clock domain
	packetir1 <= packeti1;	// register across clock domain
	packetir2 <= packeti2;	// register across clock domain
case(active_ch)
2'd0:
	begin
	case(packetir0[35:32])
	4'hF:	;		// all ones = IDLE
	4'h5:
		begin
			pbus_dati[31:0] <= packetir0[31:0];
			pack <= 1'b1;
		end
	endcase
	if (~(cyc & stb & master & cs_pbus))
		pack <= 1'b0;
	end
2'd1:
	begin
	case(packetir1[35:32])
	4'hF:	;		// all ones = IDLE
	4'h5:
		begin
			pbus_dati[31:0] <= packetir1[31:0];
			pack <= 1'b1;
		end
	endcase
	if (~(cyc & stb & master & cs_pbus))
		pack <= 1'b0;
	end
2'd2:
	begin
	case(packetir2[35:32])
	4'hF:	;		// all ones = IDLE
	4'h5:
		begin
			pbus_dati[31:0] <= packetir2[31:0];
			pack <= 1'b1;
		end
	endcase
	if (~(cyc & stb & master & cs_pbus))
		pack <= 1'b0;
	end
endcase
end

Petajon_pmc upmc1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_pmc),
	.cyc_i(br2_cyc),
	.stb_i(br2_stb),
	.ack_o(pmc_ack),
	.wr_i(br2_we),
	.adr_i(br2_adr[3:0]),
	.dat_i(br2_dato),
	.dat_o(pmc_dato),
	.ref_clk_i(clk80),
	.bus_idle(bus_idle),
	.m0(FMRQ[0]),
	.m1(FMRQ[1]),
	.m2(FMRQ[2]),
	.m3(FMRQ[3]),
	.m4(FMRQ[4]),
	.m5(FMRQ[5]),
	.m6(FMRQ[6]),
	.m7(1'b0),
	.a0(),
	.a1(),
	.a2(),
	.a3(),
	.a4(),
	.a5(),
	.a6(),
	.a7(),
	.ms(MS)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

`ifdef TEXT_CONTROLLER
TextController32 #(.num(1)) tc1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_tc1),
	.cti_i(cti),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(tc1_ack),
	.wr_i(br1_we),
	.sel_i(br1_sel),
	.adr_i(br1_adr[16:0]),
	.dat_i(br1_dato),
	.dat_o(tc1_dato),
	.lp_i(),
	.dot_clk_i(clk40),
	.hsync_i(hSync),
	.vsync_i(vSync),
	.blank_i(blank),
	.border_i(border),
	.zrgb_i(bmp_rgb),
	.zrgb_o(tc1_rgb),
	.xonoff_i(1'b1)
);
//assign red = spr_rgbo[23:16];
//assign green = spr_rgbo[15:8];
//assign blue = spr_rgbo[7:0];
`endif

`ifdef BMP_CONTROLLER
BitmapController32 #(.MDW(BMPW)) ubmc1
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

`ifdef SPRITE_CONTROLLER
SpriteController32 usc2
(
	.clk_i(cpu_clk),
	.cs_i(cs_spr),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(spr_ack),
	.we_i(br1_we),
	.sel_i(br1_sel),
	.adr_i(br1_adr[11:0]),
	.dat_i(br1_dato),
	.dat_o(spr_dato),
	.m_clk_i(clk40),
	.m_cyc_o(spr_cyc),
	.m_stb_o(spr_stb),
	.m_ack_i(spr_acki),
	.m_sel_o(spr_sel),
	.m_adr_o(spr_adr),
	.m_dat_i(spr_dati),
	.m_spriteno_o(spr_spriteno),
	.dot_clk_i(clk40),
	.hsync_i(hSync),
	.vsync_i(vSync),
	.border_i(border),
	.zrgb_i(tc1_rgb),
	.zrgb_o(spr_rgbo),
	.test(1'b0)
);
`else
assign spr_ack = 1'b0;
assign spr_dato = 64'd0;
assign spr_cyc = 1'b0;
assign spr_stb = 1'b0;
assign spr_sel = 1'b0;
assign spr_adr = 1'b0;
assign spr_spriteno = 1'b0;
`endif

assign HS = hSync;
assign VS = vSync;
assign RED = spr_rgbo[23:20];
assign GREEN = spr_rgbo[15:12];
assign BLUE = spr_rgbo[7:4];

wire ack_bridge3, ack_br;
reg ack1 = 1'b0;
reg ack1a = 1'b0;
assign ack = ack_scr|ack_bridge1|ack_bridge2|ack_bridge3|ack_br|dram_ack|xack|pack;
//assign ack = ack_br;
always @(posedge cpu_clk)
	ack1a <= ack;
always @(posedge cpu_clk)
	ack1 <= ack1a & ack;
always @(posedge cpu_clk)
casez({cs_br,cs_scr,cs_bridge1,cs_bridge2,cs_dram,cs_bridge3,cs_xbus,cs_pbus})
8'b1???????: dati <= br_dato;
8'b01??????: dati <= scr_dato;
8'b001?????: dati <= br1_cdato;
8'b0001????: dati <= br2_cdato;
8'b00001???: dati <= dram_dato;
8'b000001??: dati <= br3_cdato;
8'b0000001?:	dati <= xdatil;
8'b00000001:	dati <= pbus_dati;
default:   dati <= dati;
endcase

wire br1_ack1 = tc1_ack|bmp_ack;
reg br1_ack1a;
always @(posedge cpu_clk)
	br1_ack1a <= br1_ack1;
always @(posedge cpu_clk)
	br1_ack <= br1_ack1a & br1_ack1;

always @(posedge cpu_clk)
casez({cs_tc1,cs_spr,cs_bmp,cs_pic,cs_sema,cs_mut})
6'b1?????:	br1_dati <= tc1_dato;
6'b01????:	br1_dati <= spr_dato;
6'b001???:	br1_dati <= bmp_cdato;
6'b0001??:	br1_dati <= {2{pic_dato}};
6'b00001?:	br1_dati <= {8{sema_dato}};
6'b000001:	br1_dati <= mut_dato;
default:	br1_dati <= br1_dati;
endcase

wire br2_ack1 = rnd_ack|kbd_ack|aud_ack|pmc_ack|uart_ack|cs_grnd;
reg br2_ack1a;
always @(posedge cpu_clk)
	br2_ack1a <= br2_ack1;
always @(posedge cpu_clk)
	br2_ack <= br2_ack1a & br2_ack1;

always @(posedge cpu_clk)
casez({cs_rnd,cs_kbd,aud_ack,cs_pmc,cs_uart,cs_grnd})
6'b1?????:	br2_dati <= rnd_dato;	// 32 bits reflected twice
6'b01????:	br2_dati <= {4{kbd_dato}};	// 8 bits reflect 8 times
6'b001???:	br2_dati <= aud_cdato;			// 64 bit peripheral
6'b0001??:	br2_dati <= pmc_dato;
6'b00001?:	br2_dati <= uart_dato;
6'b000001:	br2_dati <= randnum;
default:	br2_dati <= br2_dati;
endcase


IOBridge32 u_video_bridge
(
	.rst_i(rst),
	.clk_i(cpu_clk),

	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge1),
	.s1_sel_i(sel),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br1_cdato),

	.s2_cyc_i(1'b0),
	.s2_stb_i(1'b0),
	.s2_ack_o(ack_bridge1a),
	.s2_sel_i(xsel),
	.s2_we_i(xwe),
	.s2_adr_i(xadr),
	.s2_dat_i(xdati),
	.s2_dat_o(),

	.m_cyc_o(br1_cyc),
	.m_stb_o(br1_stb),
	.m_ack_i(br1_ack),
	.m_we_o(br1_we),
	.m_sel_o(br1_sel),
	.m_adr_o(br1_adr),
	.m_dat_i(br1_dati),
	.m_dat_o(br1_dato)
);

IOBridge32 u_bridge2
(
	.rst_i(rst),
	.clk_i(cpu_clk),

	.s1_cyc_i(cyc),
	.s1_stb_i(stb),
	.s1_ack_o(ack_bridge2),
	.s1_sel_i(sel),
	.s1_we_i(we),
	.s1_adr_i(adr),
	.s1_dat_i(dato),
	.s1_dat_o(br2_cdato),

	.s2_cyc_i(1'b0),
	.s2_stb_i(1'b0),
	.s2_ack_o(),
	.s2_sel_i(4'h0),
	.s2_we_i(1'b0),
	.s2_adr_i(32'h0),
	.s2_dat_i(32'h0),
	.s2_dat_o(),

	.m_cyc_o(br2_cyc),
	.m_stb_o(br2_stb),
	.m_ack_i(br2_ack),
	.m_we_o(br2_we),
	.m_sel_o(br2_sel),
	.m_adr_o(br2_adr),
	.m_dat_i(br2_dati),
	.m_dat_o(br2_dato),
	.m_dat8_o(br2_dat8)
);


PS2kbd u_kybd1
(
	// WISHBONE/SoC bus interface 
	.rst_i(rst),
	.clk_i(cpu_clk),	// system clock
	.cs_i(cs_kbd),
  .cyc_i(br2_cyc),
  .stb_i(br2_stb),
  .ack_o(kbd_ack),
  .we_i(br2_we),
  .adr_i(br2_adr[3:0]),
  .dat_i(br2_dat8),
  .dat_o(kbd_dato),
  .kclk(KBDCLK),
  .kd(KBDDAT),
	.db(),
	//-------------
  .irq(kbd_irq)
);

PS2kbd u_mse1
(
	// WISHBONE/SoC bus interface 
	.rst_i(rst),
	.clk_i(cpu_clk),	// system clock
	.cs_i(cs_mse),
  .cyc_i(br2_cyc),
  .stb_i(br2_stb),
  .ack_o(mse_ack),
  .we_i(br2_we),
  .adr_i(br2_adr[3:0]),
  .dat_i(br2_dat8),
  .dat_o(mse_dato),
  .kclk(MSECLK),
  .kd(MSEDAT),
	.db(),
	//-------------
  .irq(mse_irq)
);

GetRand ugr1(clk100, randi, randnum);

`ifdef RANDOM_GEN
random	uprg1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_rnd),
	.cyc_i(br2_cyc),
	.stb_i(br2_stb),
	.ack_o(rnd_ack),
	.we_i(br2_we),
	.adr_i(br2_adr[4:1]),
	.dat_i(br2_dat),
	.dat_o(rnd_dato)
);
`else
assign rnd_ack = 1'b0;
assign rnd_dato = 1'b0;
`endif

`ifndef SIM
mig_7series_1 uddr3
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
	.sys_clk_i(clk320),
    .clk_ref_i(clk200),
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

mpmc8 #(.C0W(BMPW), .C1W(16), .C6W(128), .C7W(64), .C8W(128), .C9W(64)) umc1
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
	.cs1(xcs),
	.cyc1(xcyc),
	.stb1(xstb),
	.ack1(dram_ack1),
	.we1(xwe),
	.sel1(xsel),
	.adr1(xadr[27:0]),
	.dati1(xdati),
	.dato1(xdato),
	.sr1(1'b0),
	.cr1(1'b0),
	.rb1(),
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

	.cyc5(spr_cyc),
	.stb5(spr_stb),
	.ack5(spr_acki),
	.adr5(spr_adr),
	.dato5(spr_dati),
	.spriteno(spr_spriteno),

	.cyc6(1'b0),
	.stb6(1'b0),
	.ack6(),
	.we6(1'b0),
	.sel6(16'd0),
	.adr6(32'd0),
	.dati6(128'd0),
	.dato6(),

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

bootrom #(32) ubr1
(
	.rst_i(rst),
  .clk_i(cpu_clk),

  .cti_i(3'b000),
  .bok_o(br_bok),
  .cs_i(cs_br),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(ack_br),
  .adr_i(adr[17:0]),
  .dat_o(br_dato),
  
  .cti1_i(3'b000),
  .bok1_o(),
  .cs1_i(1'b0),
  .cyc1_i(1'b0),
  .stb1_i(1'b0),
  .ack1_o(),
  .adr1_i(18'h0),
  .dat1_o()
);


wire [7:0] cause;
wire [2:0] pic_irq;

Petajon_pic upic1
(
	.rst_i(rst),		// reset
	.clk_i(cpu_clk),		// system clock
	.cs_i(cs_pic),
	.cyc_i(br1_cyc),
	.stb_i(br1_stb),
	.ack_o(ack_pic),
	.wr_i(br1_we),
	.adr_i(br1_adr[7:0]),
	.dat_i(br1_dat),
	.dat_o(pic_dato),
	.vol_o(),
	.i1(FIRQ[0]),
	.i2(FIRQ[1]),
	.i3(FIRQ[2]),
	.i4(FIRQ[3]),	// eth_irq
	.i5(FIRQ[4]),
	.i6(FIRQ[5]),
	.i7(FIRQ[6]),
	.i8(vb_irq),
	.i9(FIRQ[7]),
	.i10(FIRQ[8]),
	.i11(FIRQ[9]),
	.i12(1'b0),	// eth_int_b is active low
	.i13(FIRQ[10]),
	.i14(1'b0),
	.i15(1'b0),
	.i16(uart_irq),
	.i17(1'b0),
	.i18(1'b0),
	.i19(1'b0),
	.i20(1'b0),
	.i21(1'b0),
	.i22(1'b0),
	.i23(1'b0),
	.i24(1'b0),
	.i25(pti_dirq),
	.i26(pti_sirq),
	.i27(mse_irq),
	.i28(kbd_irq),
	.i29(1'b0),	// rtc_irq
	.i30(1'b0),
	.i31(via_irq),
	.irqo(pic_irq),
	.irqo2(),
	.nmii(1'b0),		// nmi input connected to nmi requester
	.nmio(),	// normally connected to the nmi of cpu
	.causeo(cause)
);

wire [3:0] ARID, AWID;

Petajon ucpu1
(
  .hartid_i(32'h0),
  .rst_i(rst),
  .clk_i(cpu_clk),
 
  .wc_clk_i(clk20),
	.irq_i(|pic_irq),
	.cause_i(cause),
  .cyc_o(cyc),
  .wb_stb_o(stb),
  .ack_i(ack1),
//  .err_i(err),
  .wb_we_o(we),
  .wb_sel_o(sel),
  .wb_adr_o(adr),
  .wb_dat_o(dato),
  .wb_dat_i(dati),
  .sr_o(sr),
  .cr_o(cr),
  .rb_i(rb),
  .AWID(AWID),
  .AWREADY(1'b1),
  .WREADY(1'b1),
  .BID(AWID),
  .BVALID(1'b1),
  .ARREADY(1'b1),
  .ARID(ARID),
  .RVALID(1'b1),
  .RREADY(),
  .RID(ARID),
  .RDATA(dati)
);

uart6551 uuart1
(
	.rst_i(rst),
	.clk_i(cpu_clk),
	.cs_i(cs_uart),
	.irq_o(uart_irq),
	.cyc_i(br2_cyc),
	.stb_i(br2_stb),
	.ack_o(uart_ack),
	.we_i(br2_we),
	.sel_i(br2_sel),
	.adr_i(br2_adr[3:2]),
	.dat_i(br2_dat),
	.dat_o(uart_dato),
	.cts_ni(1'b0),
	.rts_no(),
	.dsr_ni(1'b0),
	.dcd_ni(1'b0),
	.dtr_no(),
	.ri_ni(1'b1),
	.rxd_i(uart_rxd),
	.txd_o(uart_txd),
	.data_present(),
	.rxDRQ_o(),
	.txDRQ_o(),
	.xclk_i(clk14),
	.RxC_i(1'b0)
);


endmodule
