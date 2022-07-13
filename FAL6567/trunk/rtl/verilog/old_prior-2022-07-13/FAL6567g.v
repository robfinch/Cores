// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
//	FAL6567g.v
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
`define TRUE  1'b1
`define FALSE 1'b0
`define LOW   1'b0
`define HIGH  1'b1
`define TURBO2	1'b1

// An 800x480 display format is created for VGA using the 640x480 standard VGA
// timing. The dot clock is faster though at 32.727MHz. This allows a 640x400
// display area with a border to be created. This is double the horizontal and
// vertical resolution of the VIC-II. 
//
module FAL6567g(cr_clk, phi02, rst_o, irq, aec, ba, cs_n, rw, ad, db, den_n, dir, ras_n, cas_n, lp_n, hSync, vSync,
		pclk, palwr_n, p, blank_n, synclk, colclk,
		ram_adr, ram_dat, ram_we, ram_ce, ram_oe, casram_n,
		Sync, comp, colorBurst
	);
parameter PAL = 1'b0;
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;
parameter LEGACY = 1'b1;
parameter MIBCNT = 16;

// Constants multiplied by 1.31 for 32.7272MHz clock
parameter phSyncOn  = 21;       //   16 front porch
parameter phSyncOff = 147;		//   96 sync
parameter phBlankOff = 209;		//   48 back porch
parameter phBorderOff = 308;	//    0 border
parameter phBorderOn = 948;	    //  640 display
parameter phBlankOn = 1047;		//    0 border
parameter phTotal = 1047; 		//  800 total clocks
parameter phSyncPol = 1;
//
parameter pvSyncOn  = 10;		//   10 front porch
parameter pvSyncOff = 12;		//    2 vertical sync
parameter pvBlankOff = 45;		//   33 back porch
parameter pvBorderOff = 85;		//    0 border	0
parameter pvBorderOn = 485;		//  480 display
parameter pvBlankOn = 525;  	//    0 border	0
parameter pvTotal = 525;		//  525 total scan lines
parameter pvSyncPol = 1;        // neg. polarity

parameter pSimRasterEnable = 48;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter SIM = 1'b0;

parameter BUS_IDLE = 0;
parameter BUS_SPRITE = 1;
parameter BUS_REF = 2;
parameter BUS_CG = 3;
parameter BUS_G = 4;
parameter BUS_LS = 5;

parameter VIC_IDLE = 0;   // idle cycle
parameter VIC_SPRITE = 1; // sprite cycle
parameter VIC_REF = 2;   // refresh cycle
parameter VIC_RC = 3;
parameter VIC_CHAR = 4;  // character acccess cycle
parameter VIC_G = 5;
parameter VIC_PAL = 6;	// palette initialization

input cr_clk;           // color reference clcck (14.31818)
output phi02;
output rst_o;
output irq;
output aec;
output reg ba;
input cs_n;
input rw;
inout [11:0] ad;
inout tri [11:0] db;
output den_n;
output dir;
output ras_n;
output cas_n;
input lp_n;
output reg hSync, vSync;	// sync outputs

output pclk;
output reg [3:0] p;
output reg blank_n;
output palwr_n;

output reg synclk;		// sync+lum clocking
output reg colclk;		// color clocking

output reg [18:0] ram_adr;
inout [7:0] ram_dat;
output reg ram_we;
output reg ram_oe;
output reg ram_ce;
input casram_n;

output Sync;
output reg [4:0] comp;
output colorBurst;


reg [1:0] chip;// = CHIP6567R8;
integer n;
wire cs = !cs_n;
wire clk32, clk33;	// 32.73 or 38.18 MHz
wire clk33_120, clk33_240;
wire clk57, dotclk;
reg [7:0] regShadow [127:0];

reg [7:0] ado;
wire vSync8,hSync8;
reg [3:0] pixelColor;
reg [3:0] color8;
wire [3:0] color33;
wire [23:0] RGB;
reg blank;			// blanking output
reg border;
wire vBlank, hBlank;
wire vBorder, hBorder;
wire hSync1,vSync1;
reg [11:0] hSyncOn, hSyncOff;
reg [11:0] vSyncOn, vSyncOff;
reg [11:0] hBorderOn, hBorderOff;
reg [11:0] hBlankOn, hBlankOff;
reg [11:0] vBorderOn, vBorderOff;
reg [11:0] vBlankOn, vBlankOff;
reg [11:0] hTotal;
reg [11:0] vTotal;
wire [11:0] vCtr, hCtr;
reg hSyncPol;
reg vSyncPol;
wire wr = !rw;
wire eol1 = hCtr==hTotal;
wire eof1 = vCtr==vTotal && eol1;

wire locked;
wire clken8;

reg [31:0] phi02r,phisr;
wire phi0,phi1;
reg phi02,phis;
reg [31:0] clk8r;
wire mux;
reg [31:0] rasr;
reg [31:0] muxr;
reg [31:0] casr;
reg [31:0] enaDatar,enaSDatar;
wire enaData,enaSData;
wire vicRefresh;
wire vicAddrValid;
reg [7:0] dbo8;
wire [7:0] dbo33 = 8'h00;

reg turbo = 0;
reg turbo2 = 0;
reg palette_inited;
reg [3:0] cram [0:1023];
wire [3:0] cram_dat = cram[ram_adr[9:0]];

wire badline;                   // flag bad line condition
reg den;                        // display enable
reg rsel, bmm, ecm;
reg csel, mcm, res;
reg [17:0] pixadr;				// pixel address for scan conversion
reg [10:0] preRasterX;
reg [10:0] rasterX;
reg [10:0] rasterXMax;
reg [8:0] preRasterY;
reg [8:0] rasterY;
reg [8:0] nextRasterY;
reg [8:0] rasterCmp;
reg [8:0] rasterYMax;
reg [8:0] nextRaster;
reg [2:0] yscroll;
reg [2:0] xscroll;
reg [7:0] lpx, lpy;

// color regs
reg [3:0] ec;
reg [3:0] mm0,mm1;
reg [3:0] b0c,b1c,b2c,b3c;

reg [2:0] vicCycleNext,vicCycle;  // cycle the VIC state machine is in
reg [2:0] busCycle;              // BUS cycle type
reg [7:0] refcntr;

reg pixelBgFlag;

// Character mode vars
reg [10:0] vmndx;                  // video matrix index
reg [11:0] nextChar;
reg [11:0] charbuf [78:0];
reg [2:0] scanline;

reg [3:0] sprite;
reg [MIBCNT-1:0] MActive;
reg [MIBCNT-1:0] MPtr [7:0];
reg [5:0] MCnt [0:MIBCNT-1];
reg [8:0] mx [0:MIBCNT-1];
reg [7:0] my [0:MIBCNT-1];
reg [3:0] mc [0:MIBCNT-1];
reg [MIBCNT-1:0] mmc;
reg [MIBCNT-1:0] me;
reg [MIBCNT-1:0] mye, mye_ff;
reg [MIBCNT-1:0] mxe, mClkShift;
reg [MIBCNT-1:0] mdp;
reg [MIBCNT-1:0] MShift;
reg [23:0] MPixels [MIBCNT-1:0];
reg [1:0] MCurrentPixel [MIBCNT-1:0];
reg [MIBCNT-1:0] m2m, m2d;
reg m2mhit, m2dhit;
reg [13:0] cb;
reg [13:0] vm;
reg [5:0] regno;
reg regpg;        // register set page for sprites
reg leg;          // legacy compatibility

reg [MIBCNT-1:0] balos = 16'h0000;

reg [4:0] ram_page;
reg [13:0] addr;
reg [13:0] vicAddr;
reg [32:0] stc;
wire stCycle = stc[31];
wire stCycle1 = stc[0];
wire stCycle2 = stc[1];
wire stCycle3 = stc[2];
wire [18:0] sc_ram_wadr, sc_ram_radr;
wire [7:0] sc_ram_dato;
reg sc_ram_rlatch;

reg [7:0] sprite1;
reg [3:0] sprite2,sprite3,sprite4,sprite5;
reg [10:0] rasterX3;

reg [11:0] shiftingChar,waitingChar,readChar;
reg [7:0] shiftingPixels,waitingPixels,readPixels;

// Interrupt bits
reg irst;
reg ilp;
reg immc;
reg imbc;

reg irst_clr;
reg imbc_clr;
reg immc_clr;
reg ilp_clr;
reg irq_clr;

reg erst;
reg embc;
reg emmc;
reg elp;

wire [7:0] dbFlt;

assign irq = (ilp & elp) | (immc & emmc) | (imbc & embc) | (irst & erst); 
 
reg rasterIRQDone;

// Write signal for external palette ram.
reg palwr_nr;
assign palwr_n = (~cs_n && ~rw && ad[7:2]==6'b001111 && ~cas_n && aec && phi02 && ~palwr_nr) ? 1'b0 : palwr_nr;

// VIC-II timing
reg hVicBlank;
reg vVicBlank;
reg hVicBorder;
reg vVicBorder;
wire vicBorder = hVicBorder | vVicBorder;

reg rst_pal = 0;
wire pi_req;
reg pi_ack;
wire [7:0] pi_adr;
wire [7:0] pi_dat;

reg vwr;
reg [18:0] vadr;
reg [7:0] vdat;
reg [7:0] vdatr;

wire ft816_rw;
wire [7:0] ft816_db;
wire [23:0] ft816_ad;

reg [21:0] rstcntr = 0;
wire xrst = SIM ? !rstcntr[3] : !rstcntr[21];
always @(posedge cr_clk)
if (xrst)
  rstcntr <= rstcntr + 4'd1;

// Set Limits
always @*
if (turbo2)
case(chip)
CHIP6567R8:   begin rasterYMax = 9'd262; rasterXMax = 10'd607; end
CHIP6567OLD:  begin rasterYMax = 9'd261; rasterXMax = 10'd607; end
CHIP6569:     begin rasterYMax = 9'd311; rasterXMax = 10'd607; end
CHIP6572:     begin rasterYMax = 9'd311; rasterXMax = 10'd607; end
endcase
else
case(chip)
CHIP6567R8:   begin rasterYMax = 9'd262; rasterXMax = {7'd64,3'b111}; end
CHIP6567OLD:  begin rasterYMax = 9'd261; rasterXMax = {7'd63,3'b111}; end
CHIP6569:     begin rasterYMax = 9'd311; rasterXMax = {7'd62,3'b111}; end
CHIP6572:     begin rasterYMax = 9'd311; rasterXMax = {7'd62,3'b111}; end
endcase

FAL6567_clkgen #(PAL) u1
(
	.rst(xrst),
	.xclk(cr_clk),
	.clk33(clk33),
	.clk33_120(clk33_120),
	.clk33_240(clk33_240),
	.turbo2(turbo2),
	.dcrate(1'b0),
	.dotclk(dotclk),
	.clk57(clk57),
	.locked(locked)
);

wire rst = !locked;
assign rst_o = rst;

assign den_n = aec ? cs_n : ~palwr_nr;
assign dir = aec ? rw : 1'b0;
assign db = rst ? 12'bz : ~palwr_nr ? {4'h0,pi_dat} : (aec && !cs_n && rw) ? (ad[7:0] < 8'h33 ? {4'h0,dbo8} : {4'h0,dbFlt}) : 12'bz;

// Generate color burst clock
reg [3:0] burstClk16x = 4'h0;
wire burstClk;
always @(posedge clk57)
	burstClk16x <= burstClk16x + 4'd1;
assign burstClk = burstClk16x[3];
	
always @(posedge clk33)
if (rst)
   	chip <= db[9:8];
always @(posedge clk33)
if (rst)
  	ado <= 8'hFF;
else
  	ado <= mux ? {2'b11,vicAddr[13:8]} : vicAddr[7:0];
assign ad = aec ? 12'bz : {vicAddr[11:8],ado};

wire casram_npe, casram_nne;
wire ras_nne;
wire phi02_pe;
reg [7:0] cpu_dat;
reg cpu_wrote;
reg cpu_access;
reg [7:0] col_adr, row_adr;
reg [7:0] ram_dato;
reg rst_cpu_access;
edge_det ued1 (.rst(rst), .clk(clk33), .ce(1'b1), .i(casram_n), .pe(casram_npe), .ne(casram_nne));
edge_det ued2 (.rst(rst), .clk(clk33), .ce(1'b1), .i(ras_n), .ne(ras_nne), .pe());
edge_det ued3 (.rst(rst), .clk(clk33), .ce(1'b1), .i(phi02), .pe(phi02_pe), .ne());
wire phi02_1, phi02_2, phi02_3;
delay1 #1 udly1 (.clk(clk33), .ce(1'b1), .i(phi02_pe), .o(phi02_1));
delay2 #1 udly2 (.clk(clk33), .ce(1'b1), .i(phi02_pe), .o(phi02_2));
delay3 #1 udly3 (.clk(clk33), .ce(1'b1), .i(phi02_pe), .o(phi02_3));

FAL6567_PaletteInit upali1
(
	.rst(rst),
	.clk(clk33),
	.rst_pal(rst_pal),
	.req(pi_req),
	.ack(pi_ack),
	.adr(pi_adr),
	.dat(pi_dat)
);

always @(posedge clk33)
	if (phi02 & casram_nne)
		cpu_access <= 1'b1;
	else if (rst_cpu_access)
		cpu_access <= 1'b0;
always @(posedge clk33)
	if (phi02 & casram_npe)
		col_adr <= ad[7:0];
always @(posedge clk33)
	if (phi02 & ras_nne)
		row_adr <= ad[7:0];
always @(posedge clk33)
	if (phi02 & casram_npe)
		cpu_dat <= db;
always @(posedge clk33)
	if (phi02 & casram_npe)
		cpu_wrote <= rw;
wire [15:0] cpu_adr = {row_adr,col_adr};

always @(posedge clk33)
case(stc[31:29])
3'b100:	ram_adr <= {3'b0,cpu_adr};
3'b010:	ram_adr <= {ram_page,vicAddr};
3'b001:	ram_adr <= vadr;
default:	ram_adr <= ft816_ad[18:0];
endcase

always @(posedge clk33)
case(stc[31:29])
3'b100:	if (cpu_wrote & cpu_access)
			ram_dato <= cpu_dat;
3'b001:	ram_dato <= vdat;
default:	ram_dato <= ft816_db;
endcase

reg vwr1;
always @(posedge clk33)
if (vwr)
	vwr1 <= 1'b1;
else if (stc[26])
	vwr1 <= 1'b0;

reg ram_we1;
always @(posedge clk33)
case(stc[31:29])
3'b100:	ram_we1 <= ~(cpu_wrote & cpu_access);
3'b010:	ram_we1 <= 1'b1;
3'b001:	ram_we1 <= ~vwr1;
default:	ram_we1 <= ft816_rw;
endcase
always @*
	ram_we <= ram_we1 | clk33_240;

always @(posedge clk33)
case(stc[31:29])
3'b100:	ram_oe <= cpu_access ? (cpu_wrote ? 1'b1 : 1'b0) : 1'b1;
3'b010:	ram_oe <= 1'b0;
3'b001:	ram_oe <= vwr1;
default:	ram_oe <= ~ft816_rw;
endcase

always @(posedge clk33)
case(stc[31:29])
3'b100:	ram_ce <= ~cpu_access;
3'b010:	ram_ce <= 1'b0;
3'b001:	ram_ce <= 1'b0;
default:	ram_ce <= ~(ft816_ad[23:19]==5'h0);
endcase

always @(posedge clk33)
if (stc[31:28]==4'b0001)
	vdatr <= ram_dat;

always @(posedge clk33)
	if (phi02_pe)
		rst_cpu_access <= cpu_access;

assign ram_dat = ram_we1 ? ram_dato : 8'bz;
always @(posedge clk33)
	if (ram_we1 && ram_adr[15:10]==6'b110110)
		cram[ram_adr[9:0]] <= ram_dato[3:0];

FAL6567_ScanConverter u2
(
	.chip(chip),
	.clken8(clken8),
	.clk33(clk33),
	.hSync8_i(hSync8),
	.vSync8_i(vSync8),
	.color_i(color8),
	.hSync33_i(hSync),
	.vSync33_i(vSync),
	.color_o(color33)
);


//------------------------------------------------------------------------------
// '816 system components
//------------------------------------------------------------------------------

wire ft816_cs_vic = ft816_ad[23:10]==14'b1011_0000_1101_00;
wire ft816_cs_flt = ft816_ad[23:10]==14'b1011_0000_1110_00;

assign dbFlt = ft816_rw ? 8'bz : ft816_db;
FAL6567Float uflt1 (rst_o, clk33, ft816_cs_flt, ft816_cs_flt, ~ft816_rw, ft816_ad[7:0], dbFlt);

reg [7:0] ft816_dbi;
always @*
casez({ft816_cs_vic,ft816_cs_flt})
2'b1?:	ft816_dbi <= dbo8;
2'b01:	ft816_dbi <= dbFlt;
default:	ft816_dbi <= ram_dat;
endcase

assign ft816_db = ft816_rw ? ft816_dbi : 8'bz;

reg ft816_rst;
wire ft816_clk;
BUFGMUX ubg2 (.S(|stc[27:0]), .I0(1'b0), .I1(clk33), .O(ft816_clk));

FT816 ucpu1
(
	.rst(ft816_rst),	// active low
	.clk(ft816_clk),
	.clko(),
	.cyc(),
	.phi11(),
	.phi12(),
	.phi81(),
	.phi82(),
	.nmi(),
	.irq(irq),
	.abort(),
	.e(),
	.mx(),
	.rdy(1'b1),
	.be(1'b1),
	.vpa(),
	.vda(),
	.mlb(),
	.vpb(),
	.rw(ft816_rw),
	.ad(ft816_ad),
	.db(ft816_db),
	.err_i(1'b0),
	.rty_i(1'b0)
);


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

assign pclk = clk33;

always @(posedge clk33)
	p <= color33;

always @(posedge clk33)
if (rst)
	blank_n <= 1'b0;
else
	blank_n <= blank;

always @(posedge clk33)
if (rst) begin
	clk8r <= 32'b10001000100010001000100010001000;
end
else begin
	if (stCycle)
		clk8r <= 32'b00010001000100010001000100010001;
	else
		clk8r <= {clk8r[30:0],clk8r[31]};
end
assign clken8 = clk8r[31];

always @(posedge clk33)
if (rst)
	stc <= 32'b10000000000000000000000000000000;
else
	stc <= {stc[30:0],stc[31]};

always @(posedge clk33)
if (rst)
	phi02r <= 32'b00000000000000001111111111111111;
else begin
	phi02r <= {phi02r[30:0],phi02r[31]};
end
always @(posedge clk33)
	phi02 <= phi02r[0];
//assign phi02 = phi02r[32];

always @(posedge clk33)
if (rst)
	phisr <= 32'b00000000000000000000011111111111;
else
	phisr <= {phisr[30:0],phisr[31]};
always @(posedge clk33)
	phis <= phisr[1];

always @(posedge clk33)
if (rst) begin
	rasr <= 32'b11111111111111111111111110000000;
end
else begin
	if (stCycle2) begin
		case(busCycle)
		BUS_IDLE:   rasr <= 32'b11111111111111111111111000000000;  // I
		BUS_LS:     rasr <= 32'b11111100000000001111111000000000;  // S
		BUS_SPRITE: rasr <= 32'b11100000000000000000011110000000;  // S - cycle
		BUS_CG:     rasr <= 32'b11111100000000001111111000000000;  // G,C
		BUS_G:      rasr <= 32'b11111100000000001111111000000000;  // G,C
		BUS_REF:    rasr <= 32'b11111100000000001111111000000000;  // R,C or R
		endcase
		end
	else
		rasr <= {rasr[30:0],1'b0};
end
assign ras_n = rasr[31];
  
always @(posedge clk33)
if (rst) begin
	muxr <= 32'b11111111111111111111111100000000;  // I
end
else begin
	if (stCycle1) begin
		case(busCycle)
		BUS_IDLE:   muxr <= 32'b11111111111111111111111100000000;  // I
		BUS_LS:     muxr <= 32'b11111110000000001111111100000000;  // S
		BUS_SPRITE: muxr <= 32'b11110000000000000000011111000000;  // S - cycle
		BUS_CG:     muxr <= 32'b11111110000000001111111100000000;  // G,C
		BUS_G:      muxr <= 32'b11111110000000001111111100000000;  // G,C
		BUS_REF:    muxr <= 32'b00000000000000001111111100000000;  // R,C or R
		endcase
		end
	else
		muxr <= {muxr[30:0],1'b0};
end
assign mux = muxr[31];
  
always @(posedge clk33)
if (rst) begin
	casr <= 32'b11111111111000001111111111100000;  // R,C
end
else begin
	if (stCycle2) begin
		case(busCycle)
		BUS_IDLE:   casr <= 32'b11111111111111111111111110000000;  // I - cycle
		//    CHAR5_CYCLE:  casr <= 33'b111111000011000011000011000110000;  // G,C
		//    CHAR6_CYCLE:  casr <= 33'b110001100001100011000011000110000;  // G,C
		BUS_LS:     casr <= 32'b11111111000000001111111110000000;  // S
		BUS_SPRITE: casr <= 32'b11111000011000011000011111100000;  // S - cycle
		BUS_CG:     casr <= 32'b11111111000000001111111110000000;  // G,C
		BUS_G:      casr <= 32'b11111111000000001111111110000000;  // G,C
		BUS_REF:    casr <= 32'b11111111111111111111111110000000;  // R,C
		endcase
	end
	else
		casr <= {casr[30:0],1'b0};
end
assign cas_n = casr[31];

always @(posedge clk33)
if (rst) begin
	enaDatar <= 32'b00000000000000010000000000000001;  // S - cycle
end
else begin
	if (stCycle2)
		enaDatar <= 32'b00000000000000010000000000000001;  // S - cycle
	else
		enaDatar <= {enaDatar[30:0],1'b0};
end
assign enaData = enaDatar[30];

always @(posedge clk33)
if (rst) begin
	enaSDatar <= 32'b00000000100000100000100000000001;  // S - cycle
end
else begin
	if (stCycle2)
		enaSDatar <= 32'b00000000100000100000100000000001;  // S - cycle
	else
		enaSDatar <= {enaSDatar[30:0],1'b0};
end
assign enaSData = enaSDatar[31];
wire enaMCnt = enaSDatar[30];

//------------------------------------------------------------------------------
// Bus cycle type
//------------------------------------------------------------------------------

always @*
begin
	case(vicCycle)
	VIC_SPRITE:
		if (MActive[sprite2]) begin
			if (leg)
				busCycle <= BUS_LS;
			else 
				busCycle <= BUS_SPRITE;
		end
		else
			busCycle <= BUS_IDLE;
	VIC_REF,VIC_RC:
		busCycle <= BUS_REF;
	VIC_CHAR,VIC_G,VIC_PAL:
		if (badline)
			busCycle <= BUS_CG;
		else
			busCycle <= BUS_G;
	VIC_IDLE:
		busCycle <= BUS_IDLE;
	endcase
end

//------------------------------------------------------------------------------
// Raster / Refresh counters
//------------------------------------------------------------------------------
always @(posedge clk33)
if (rst) begin
	refcntr <= 8'd255;
end
else begin
	if (stCycle) begin
		if (vicCycle==VIC_REF || vicCycle==VIC_RC)
			refcntr <= refcntr - 8'd1;
	end
end

//------------------------------------------------------------------------------
// VIC-II cycling machine.
//
// VIC-II is very simple with only four types of cycles. The timing is adjusted
// in various chip versions by adding a varying number of IDLE cycles after the
// CHAR fetches. The total number of cycles varies from 63 to 65.
// The cycles are synchronized to the raster timing.
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Create an advanced raster signal.
//
// Complicated by the fact that bus available must go low three cycles before
// the cpu gives up the bus. On a bad line this would place the ba starting
// low on the line previous scanline. So that the ba low doesn't cross a
// complicated counter boundary we fudge things by having the counter count
// in advance of the normal rasterX. This mean we need to delay the signal
// to get back where we should be.
//------------------------------------------------------------------------------
always @(posedge clk33)
if (rst) begin
	preRasterX <= 11'd0;
end
else begin
	if (clken8) begin
		if (preRasterX==rasterXMax)
			preRasterX <= 11'd0;
		else
			preRasterX <= preRasterX + 11'd1;
	end  
end

always @(posedge clk33)
if (rst) begin
	rasterX <= 10'd0;
end
else begin
	if (clken8) begin
		if (preRasterX==10'h14)
			rasterX <= 10'h0;
		else
			rasterX <= rasterX + 10'd1;
	end  
end

always @(posedge clk33)
if (rst) begin
	preRasterY <= 9'd0;
end
else begin
	if (clken8) begin
		if (preRasterX==rasterXMax) begin
			if (preRasterY==rasterYMax)
				preRasterY <= 9'd0;
			else
				preRasterY <= preRasterY + 9'd1;
		end
	end  
end

always @(posedge clk33)
if (rst) begin
	rasterY <= 9'd0;
end
else begin
	if (clken8) begin
		if (preRasterX==10'h14) begin
			rasterY <= preRasterY;
		end
	end  
end

always @(posedge clk33)
if (rst) begin
	nextRasterY <= 9'd0;
end
else begin
	if (clken8) begin
		if (rasterX==10'd0) begin
			nextRasterY <= rasterY + 9'd1;
		end
	end  
end

//------------------------------------------------------------------------------
// Decode cycles
//------------------------------------------------------------------------------

wire [10:0] rasterX2 = {preRasterX,1'b0};
always @*
if (pi_req)
	vicCycle <= VIC_PAL;
else
casez(rasterX2)
11'h00?: vicCycle <= VIC_REF;
11'h01?: vicCycle <= VIC_REF;
11'h02?: vicCycle <= VIC_REF;
11'h03?: vicCycle <= VIC_REF;
11'h04?: vicCycle <= VIC_RC;
11'h05?: vicCycle <= VIC_CHAR;
11'h06?: vicCycle <= VIC_CHAR;
11'h07?: vicCycle <= VIC_CHAR;
11'h08?: vicCycle <= VIC_CHAR;
11'h09?: vicCycle <= VIC_CHAR;
11'h0A?: vicCycle <= VIC_CHAR;
11'h0B?: vicCycle <= VIC_CHAR;
11'h0C?: vicCycle <= VIC_CHAR;
11'h0D?: vicCycle <= VIC_CHAR;
11'h0E?: vicCycle <= VIC_CHAR;
11'h0F?: vicCycle <= VIC_CHAR;
11'h10?: vicCycle <= VIC_CHAR;
11'h11?: vicCycle <= VIC_CHAR;
11'h12?: vicCycle <= VIC_CHAR;
11'h13?: vicCycle <= VIC_CHAR;
11'h14?: vicCycle <= VIC_CHAR;
11'h15?: vicCycle <= VIC_CHAR;
11'h16?: vicCycle <= VIC_CHAR;
11'h17?: vicCycle <= VIC_CHAR;
11'h18?: vicCycle <= VIC_CHAR;
11'h19?: vicCycle <= VIC_CHAR;
11'h1A?: vicCycle <= VIC_CHAR;
11'h1B?: vicCycle <= VIC_CHAR;
11'h1C?: vicCycle <= VIC_CHAR;
11'h1D?: vicCycle <= VIC_CHAR;
11'h1E?: vicCycle <= VIC_CHAR;
11'h1F?: vicCycle <= VIC_CHAR;
11'h20?: vicCycle <= VIC_CHAR;
11'h21?: vicCycle <= VIC_CHAR;
11'h22?: vicCycle <= VIC_CHAR;
11'h23?: vicCycle <= VIC_CHAR;
11'h24?: vicCycle <= VIC_CHAR;
11'h25?: vicCycle <= VIC_CHAR;
11'h26?: vicCycle <= VIC_CHAR;
11'h27?: vicCycle <= VIC_CHAR;
11'h28?: vicCycle <= VIC_CHAR;
11'h29?: vicCycle <= VIC_CHAR;
11'h2A?: vicCycle <= VIC_CHAR;
default:
if (turbo2)
casez(rasterX2)
11'h2B?: vicCycle <= VIC_CHAR;
11'h2C?: vicCycle <= VIC_CHAR;
11'h2D?: vicCycle <= VIC_CHAR;
11'h2E?: vicCycle <= VIC_CHAR;
11'h2F?: vicCycle <= VIC_CHAR;
11'h30?: vicCycle <= VIC_CHAR;
11'h31?: vicCycle <= VIC_CHAR;
11'h32?: vicCycle <= VIC_CHAR;
11'h33?: vicCycle <= VIC_G;
11'h34?: vicCycle <= VIC_IDLE;
11'h35?: vicCycle <= VIC_IDLE;
11'h36?: vicCycle <= VIC_IDLE;
11'h37?: vicCycle <= VIC_IDLE;
11'h38?: vicCycle <= VIC_SPRITE;
11'h39?: vicCycle <= VIC_SPRITE;
11'h3A?: vicCycle <= VIC_SPRITE;
11'h3B?: vicCycle <= VIC_SPRITE;
11'h3C?: vicCycle <= VIC_SPRITE;
11'h3D?: vicCycle <= VIC_SPRITE;
11'h3E?: vicCycle <= VIC_SPRITE;
11'h3F?: vicCycle <= VIC_SPRITE;
11'h40?: vicCycle <= VIC_SPRITE;
11'h41?: vicCycle <= VIC_SPRITE;
11'h42?: vicCycle <= VIC_SPRITE;
11'h43?: vicCycle <= VIC_SPRITE;
11'h44?: vicCycle <= VIC_SPRITE;
11'h45?: vicCycle <= VIC_SPRITE;
11'h46?: vicCycle <= VIC_SPRITE;
11'h47?: vicCycle <= VIC_SPRITE;
11'h48?: vicCycle <= VIC_IDLE;
11'h49?: vicCycle <= VIC_IDLE;
11'h4A?: vicCycle <= VIC_IDLE;
11'h4B?: vicCycle <= VIC_REF;
default: vicCycle <= VIC_IDLE;
endcase
else
casez(rasterX2)
11'h2B?: vicCycle <= VIC_G;
11'h2C?: vicCycle <= VIC_IDLE;
11'h2D?: vicCycle <= VIC_IDLE;
11'h2E?:
        case(chip)
        CHIP6567R8:   vicCycle <= VIC_IDLE;
        CHIP6567OLD:  vicCycle <= VIC_IDLE;
        default:      vicCycle <= VIC_SPRITE;
        endcase
11'h2F?:
        case(chip)
        CHIP6567R8:   vicCycle <= VIC_IDLE;
        CHIP6567OLD:  vicCycle <= VIC_SPRITE;
        default:      vicCycle <= VIC_SPRITE;
        endcase
11'h30?:  vicCycle <= VIC_SPRITE;
11'h31?:  vicCycle <= VIC_SPRITE;
11'h32?:  vicCycle <= VIC_SPRITE;
11'h33?:  vicCycle <= VIC_SPRITE;
11'h34?:  vicCycle <= VIC_SPRITE;
11'h35?:  vicCycle <= VIC_SPRITE;
11'h36?:  vicCycle <= VIC_SPRITE;
11'h37?:  vicCycle <= VIC_SPRITE;
11'h38?:  vicCycle <= VIC_SPRITE;
11'h39?:  vicCycle <= VIC_SPRITE;
11'h3A?:  vicCycle <= VIC_SPRITE;
11'h3B?:  vicCycle <= VIC_SPRITE;
11'h3C?:  vicCycle <= VIC_SPRITE;
11'h3D?:  vicCycle <= VIC_SPRITE;
11'h3E?:
        case(chip)
        CHIP6567R8:   vicCycle <= VIC_SPRITE;
        CHIP6567OLD:  vicCycle <= VIC_SPRITE;
        default:      vicCycle <= VIC_REF;
        endcase
11'h3F?:
        case(chip)
        CHIP6567R8:   vicCycle <= VIC_SPRITE;
        CHIP6567OLD:  vicCycle <= VIC_REF;
        default:      vicCycle <= VIC_REF;
        endcase
11'h40?:  vicCycle <= VIC_REF;
default:  vicCycle <= VIC_IDLE;
endcase
endcase

always @(posedge clk33)
if (clken8) begin
	if (turbo2)
	    case(chip)
	    CHIP6567R8:   sprite1 <= rasterX2 - 11'h37E;
	    CHIP6567OLD:  sprite1 <= rasterX2 - 11'h37E;
	    default:      sprite1 <= rasterX2 - 11'h37E;
	    endcase
	else
	    case(chip)
	    CHIP6567R8:   sprite1 <= rasterX2 - 11'h2FE;
	    CHIP6567OLD:  sprite1 <= rasterX2 - 11'h2EE;
	    default:      sprite1 <= rasterX2 - 11'h2DE;
	    endcase
    if (leg)
		sprite2 <= sprite1[7:5];
    else
		sprite2 <= sprite1[7:4];
end

// Centre sprite number according to RAM timing.
always @(posedge clk33)
begin
	sprite3 <= sprite2;
	sprite4 <= sprite3;
	sprite5 <= sprite4;
	sprite <= sprite5;
end

wire ref5 = rasterX2[10:4]==7'h03;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

assign badline = preRasterY[2:0]==yscroll && den && (preRasterY >= (SIM ? 9'd1 : 9'h30) && preRasterY <= 9'hF7);

//------------------------------------------------------------------------------
// Bus available generator
//------------------------------------------------------------------------------

//always @(chip,n,me,my,nextRasterY,rasterX2,MActive,leg)
always @(posedge clk33)
	for (n = 0; n < MIBCNT; n = n + 1) begin
		if (me[n] && ((my[n]==nextRasterY)||MActive[n])) begin
			if (turbo2) begin
				if (leg)
					case(chip)
					CHIP6567R8:   balos[n] <= (rasterX2 >= 11'h350 + {n,5'b0}) && (rasterX2 < 11'h3A0 + {n,5'b0});
					CHIP6567OLD:  balos[n] <= (rasterX2 >= 11'h350 + {n,5'b0}) && (rasterX2 < 11'h3A0 + {n,5'b0});
					default:      balos[n] <= (rasterX2 >= 11'h350 + {n,5'b0}) && (rasterX2 < 11'h3A0 + {n,5'b0}); 
					endcase
				else
					case(chip)
					CHIP6567R8:   balos[n] <= (rasterX2 >= 11'h350 + {n,4'b0}) && (rasterX2 < 11'h390 + {n,4'b0});
					CHIP6567OLD:  balos[n] <= (rasterX2 >= 11'h350 + {n,4'b0}) && (rasterX2 < 11'h390 + {n,4'b0});
					default:      balos[n] <= (rasterX2 >= 11'h350 + {n,4'b0}) && (rasterX2 < 11'h390 + {n,4'b0});
					endcase
			end
			else begin
				if (leg)
					case(chip)
					CHIP6567R8:   balos[n] <= (rasterX2 >= 11'h2D0 + {n,5'b0}) && (rasterX2 < 11'h320 + {n,5'b0});
					CHIP6567OLD:  balos[n] <= (rasterX2 >= 11'h2C0 + {n,5'b0}) && (rasterX2 < 11'h310 + {n,5'b0});
					default:      balos[n] <= (rasterX2 >= 11'h2B0 + {n,5'b0}) && (rasterX2 < 11'h300 + {n,5'b0}); 
					endcase
				else
					case(chip)
					CHIP6567R8:   balos[n] <= (rasterX2 >= 11'h2D0 + {n,4'b0}) && (rasterX2 < 11'h310 + {n,4'b0});
					CHIP6567OLD:  balos[n] <= (rasterX2 >= 11'h2C0 + {n,4'b0}) && (rasterX2 < 11'h300 + {n,4'b0});
					default:      balos[n] <= (rasterX2 >= 11'h2B0 + {n,4'b0}) && (rasterX2 < 11'h2F0 + {n,4'b0}); 
					endcase
			end
		end
		else begin
			balos[n] <= `FALSE;
		end
	end

reg [10:0] baloff;
always @(posedge clk33)
case({turbo2,chip})
3'b000:	baloff <= 11'h2C0;
3'b001:	baloff <= 11'h2B0;
3'b010:	baloff <= 11'h2A0;
3'b011:	baloff <= 11'h2A0;
default:	baloff <= 11'h340;
endcase
wire balo = |balos | (badline && rasterX2 < baloff);


//------------------------------------------------------------------------------
// Bus available drives the processor's ready line. So the ready line is held
// inactive until the FPGA is loaded and the pll is locked.
//------------------------------------------------------------------------------

always @(posedge clk33)
if (rst) begin
	ba <= `LOW;
end
else begin
	if (turbo)
		ba <= 1'b1;
	else if (stCycle2)
    	ba <= !balo;
end

//------------------------------------------------------------------------------
// AEC
//
// AEC follows BA by three clock cycles.
//------------------------------------------------------------------------------
reg ba1,ba2,ba3;

always @(posedge clk33)
if (rst) begin
	ba1 <= `LOW;
	ba2 <= `LOW;
	ba3 <= `LOW;
end
else begin
	if (stCycle2) begin
		ba1 <= ba;
		ba2 <= ba1 | ba;
		ba3 <= ba2 | ba;
	end
end

assign aec = ba ? phi02 : ba3 & phi02;

//------------------------------------------------------------------------------
// Databus loading
//------------------------------------------------------------------------------

always @(posedge clk33)
if (phi02==`HIGH && enaData && (vicCycle==VIC_RC || vicCycle==VIC_CHAR)) begin
	if (badline)
		nextChar <= turbo ? {cram_dat,ram_dat} : db;
	else
		nextChar <= turbo2 ? charbuf[46] : charbuf[38];
	if (turbo2)
		for (n = 46; n > 0; n = n -1)
			charbuf[n] = charbuf[n-1];
	else
		for (n = 38; n > 0; n = n -1)
			charbuf[n] = charbuf[n-1];
	charbuf[0] <= nextChar;
end

always @(posedge clk33)
if (phi02==`LOW && enaData) begin
	if (vicCycle==VIC_CHAR || vicCycle==VIC_G) begin
		readPixels <= turbo ? ram_dat : db[7:0];
		readChar <= nextChar;
	end
	waitingPixels <= readPixels;
	waitingChar <= readChar;
end

always @(posedge clk33)
if (phis==`LOW && enaSData==1'b1 && busCycle==BUS_SPRITE) begin
	if (MActive[sprite])
		MPtr[sprite] <= turbo ? ram_dat : db[7:0];
	else
		MPtr[sprite] <= 8'd255;
end

//------------------------------------------------------------------------------
// Video matrix counter
//------------------------------------------------------------------------------
reg [10:0] vmndxStart;

always @(posedge clk33)
if (rst) begin
	vmndx <= 11'd0;
	vmndxStart <= 11'd0;
end
else begin
	if (phi02 && enaData) begin
		if (rasterY==rasterYMax)
			vmndx <= 11'd0;
		if ((vicCycle==VIC_CHAR||vicCycle==VIC_G) && badline)
			vmndx <= vmndx + 1;
		if (rasterX2[10:4]==(turbo2 ? 7'h34 : 7'h2C)) begin
			if (scanline==3'd7)
				vmndxStart <= vmndx;
			else
				vmndx <= vmndxStart;
		end
	end
end

//------------------------------------------------------------------------------
// Scanline counter
//
// The scanline counter provides the three LSB's of the character bitmap data
// or the bitmapped mode address.
//------------------------------------------------------------------------------

always @(posedge clk33)
if (rst) begin
	scanline <= 3'd0;
end
else begin
	if (phi02==`LOW && enaData) begin
		if (ref5) begin
			if (badline)
				scanline <= 3'd0;
		end
		if (rasterX2[10:4]==(turbo2 ? 7'h34 : 7'h2C))
			scanline <= scanline + 3'd1;
	end
end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
always @*
	for (n = 0; n < MIBCNT; n = n + 1)
		MActive[n] <= MCnt[n] != 6'd63;

reg [MIBCNT-1:0] collision;
always @*
	for (n = 0; n < MIBCNT; n = n + 1)
		collision[n] = MCurrentPixel[n][1];

// Sprite-sprite collision logic
always @(posedge clk33)
if (rst)
	m2mhit <= `FALSE;
else begin
	if (immc_clr)
		immc <= `FALSE;
	if (ad[7:0]==8'h1E && regpg && phi02 && aec && cs && enaData) begin
		m2m[15:8] <= 8'h0;
	end
	if (ad[7:0]==8'h1E && !regpg && phi02 && aec && cs && enaData) begin
		m2m[7:0] <= 8'h0;
		m2mhit <= `FALSE;
	end
	case(collision)
	16'b0000000000000000,
	16'b0000000000000001,
	16'b0000000000000010,
	16'b0000000000000100,
	16'b0000000000001000,
	16'b0000000000010000,
	16'b0000000000100000,
	16'b0000000001000000,
	16'b0000000010000000,
	16'b0000000100000000,
	16'b0000001000000000,
	16'b0000010000000000,
	16'b0000100000000000,
	16'b0001000000000000,
	16'b0010000000000000,
	16'b0100000000000000,
	16'b1000000000000000:
	;
	default:
		begin
			m2m <= m2m | collision;
			if (!m2mhit) begin
				immc <= `TRUE;
				m2mhit <= `TRUE;
			end
		end
	endcase
end

// Sprite-background collision logic
always @(posedge clk33)
if (rst)
	m2dhit <= `FALSE;
else begin
	if (imbc_clr)
		imbc <= `FALSE;
	if (ad[7:0]==8'h1F && regpg && phi02 && aec && cs && enaData) begin
		m2d[15:8] <= 8'h0;
	end
	if (ad[7:0]==8'h1F && !regpg && phi02 && aec && cs && enaData) begin
		m2d[7:0] <= 8'h0;
		m2dhit <= `FALSE;
	end
	for (n = 0; n < MIBCNT; n = n + 1) begin
		if (collision[n] & pixelBgFlag & ~vicBorder) begin
			m2d[n] <= `TRUE;
			if (!m2dhit) begin
				m2dhit <= `TRUE;
				imbc <= `TRUE;
			end
		end
	end
end

always @(posedge clk33)
begin
	for (n = 0; n < MIBCNT; n = n + 1) begin
		if (rasterX == 10)
			MShift[n] <= `FALSE;
		else if (rasterX == mx[n])
			MShift[n] <= `TRUE;
	end
end

always @(posedge clk33)
if (rst & SIM) begin
	for (n = 0; n < MIBCNT; n = n + 1) begin
		MCnt[n] <= 6'd63;
	end
end
else begin
	// Trigger sprite accesses on the last character cycle
	// if the sprite Y coordinate will match.
	if (rasterX2==(turbo2 ? 11'h330 : 11'h2B0)) begin
		for (n = 0; n < MIBCNT; n = n + 1) begin
			if (!MActive[n] && me[n] && nextRasterY == my[n])
				MCnt[n] <= 6'd0;
		end    
	end

	// If Y expansion is on, backup the MIB data counter by three every
	// other scanline.
	if (enaData && ref5 && !phi02) begin
		for (n = 0; n < MIBCNT; n = n + 1) begin
			if (MActive[n] & mye[n]) begin
				if (!mye_ff[n])
					MCnt[n] <= MCnt[n] - 6'd3;
			end
		end  
	end

	if (leg) begin
		if (sprite1[4]) begin
			if (vicCycle==VIC_SPRITE && phi02 && enaData) begin
				if (MActive[sprite])
					MCnt[sprite] <= MCnt[sprite] + 6'd1;
			end 
		end
		else begin
			if (vicCycle==VIC_SPRITE && enaData) begin
				if (MActive[sprite])
					MCnt[sprite] <= MCnt[sprite] + 6'd1;
			end
		end
	end
	else begin
		if (!phis && enaMCnt && vicCycle==VIC_SPRITE) begin
			if (MActive[sprite])
				MCnt[sprite] <= MCnt[sprite] + 6'd1;
		end
	end
end

// X expansion - when to clock the shift register
reg [1:0] mShiftCount[0:MIBCNT-1];

always @(posedge clk33)
if (clken8) begin
	for (n = 0; n < MIBCNT; n = n + 1) begin
		if (MShift[n]) begin
			case({mxe,mc[n]})
			2'b00:	mShiftCount[n] <= 2'd3;
			2'b01:	mShiftCount[n][0] <= ~mShiftCount[n][0];
			2'b10:	mShiftCount[n][0] <= ~mShiftCount[n][0];
			2'b11:	mShiftCount[n] <= mShiftCount[n] + 2'd1;
			endcase
		end
		else begin
			case({mxe,mc[n]})
			2'b00:	mShiftCount[n] <= 2'd3;
			2'b01:	mShiftCount[n] <= 2'd2;
			2'b10:	mShiftCount[n] <= 2'd2;
			2'b11:	mShiftCount[n] <= 2'd0;
			endcase
		end
	end
end
always @*
	for (n = 0; n < MIBCNT; n = n + 1)
		mClkShift[n] <= mShiftCount[n]==2'd3;

// Y expansion
always @(posedge clk33)
begin
	// Reset expansion flipflop once sprite becomes deactivated or
	// if no sprite Y expansion.
	for (n = 0; n < MIBCNT; n = n + 1) begin
		if (!mye[n] || !MActive[n])
			mye_ff[n] <= 1'b0;
	end
	if (enaData && ref5 && !phi02) begin
		for (n = 0; n < MIBCNT; n = n + 1) begin
			if (MActive[n] & mye[n])
				mye_ff[n] <= !mye_ff[n];
		end  
	end
end

// Handle sprite pixel loading / shifting
always @(posedge clk33)
begin
	if (clken8) begin
		for (n = 0; n < MIBCNT; n = n + 1) begin
			if (MShift[n]) begin
				if (mClkShift[n]) begin
					if (mc[n])
						MPixels[n] <= {MPixels[n][21:0],2'b0};
					else
						MPixels[n] <= {MPixels[n][22:0],1'b0};
				end
			end
		end  
	end
	if (leg) begin
		if (sprite1[4]) begin
			if (vicCycle==VIC_SPRITE && phi02 && enaData) begin
				if (MActive[sprite])
					MPixels[sprite] <= {MPixels[sprite][15:0],db[7:0]};
			end 
		end
		else begin
			if (vicCycle==VIC_SPRITE && enaData) begin
				if (MActive[sprite])
					MPixels[sprite] <= {MPixels[sprite][15:0],db[7:0]};
			end
		end
	end
	else begin
		if (phis==`LOW && enaSData && vicCycle==VIC_SPRITE) begin
			if (MActive[sprite])
				MPixels[sprite] <= {MPixels[sprite][15:0],db[7:0]};
		end
	end
end

// Adds a pipeline delay of one to the sprite pixel
always @(posedge clk33)
if (clken8) begin
	for (n = 0; n < MIBCNT; n = n + 1) begin
		if (MShift[n])
			MCurrentPixel[n] <= MPixels[n][23:22];
		else
			MCurrentPixel[n] <= 2'b00;
	end  
end


//------------------------------------------------------------------------------
// Address Generation
//------------------------------------------------------------------------------

always @*
begin
	case(vicCycle)
	VIC_PAL:
		addr <= {8'h00,pi_adr};
	VIC_REF:
		addr <= {6'b111111,refcntr};
	VIC_RC:
		if (phi02==`HIGH)
			addr <= vm + vmndx;
		else    
			addr <= {6'b111111,refcntr};
	VIC_CHAR,VIC_G:
		begin
			if (phi02==`HIGH)
				addr <= vm + vmndx;
			else begin
				if (bmm)
					addr <= {cb[13],12'd0} + {vmndx,scanline};
				else
					addr <= {cb[13:11],nextChar[7:0],scanline};
				if (ecm)
					addr[10:9] <= 2'b00;
			end
		end
	VIC_SPRITE:
		if (leg) begin
			if (phi02==`LOW && sprite1[4])
				addr <= vm + ((turbo2 ? 14'b11111111000 : 14'b1111111000) | sprite[2:0]);
			else
				addr <= {MPtr[sprite],MCnt[sprite]};
		end
			else begin
			if (!phis)
				addr <= {MPtr[sprite],MCnt[sprite]};
			else
				addr <= vm + ((turbo2 ? 14'b11111110000 : 14'b1111110000) | {~sprite[3],sprite[2:0]});
		end
	default: addr <= 14'h3FFF;
	endcase
end

always @(posedge clk33)
	vicAddr <= addr;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
always @(posedge clk33)
if (stc[2])
	palwr_nr <= ~(vicCycle==VIC_PAL && pi_req);
else if (stc[17])
	palwr_nr <= 1'b1;

always @(posedge clk33)
if (stc[17])
	pi_ack <= palwr_nr==1'b0;
else
	pi_ack <= 1'b0;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
always @(posedge clk33)
begin
	if (phi02 && enaData && vicCycle == VIC_SPRITE && sprite == 2)
		rasterIRQDone <= `FALSE;
	if (irst_clr)
		irst <= 1'b0;
	if (rasterIRQDone == 1'b0 && rasterY == rasterCmp) begin
		rasterIRQDone <= `TRUE;
		irst <= 1'b1;
	end
end

//------------------------------------------------------------------------------
// Light pen
//
// The light pen only allows one hit per frame. It's the first hit that counts.
//------------------------------------------------------------------------------

reg lightPenHit;
always @(posedge clk33)
begin
    if (ilp_clr)
		ilp <= `LOW;
    if (rasterY == rasterYMax)
		lightPenHit <= `FALSE;
    else if (!lightPenHit && lp_n == `LOW) begin
		lightPenHit <= `TRUE; 
		ilp <= `HIGH; 
		lpx <= rasterX[8:1];
		lpy <= rasterY[7:0];
    end
end

//------------------------------------------------------------------------------
// Video Blank Interval
//------------------------------------------------------------------------------
always @(posedge clk33)
begin
	vVicBlank <= `FALSE;
	case(chip)
	CHIP6567R8,CHIP6567OLD:
		if (rasterY <= 40)
			vVicBlank <= `TRUE;
	CHIP6569,CHIP6572:
		if (rasterY >= 300 || rasterY < 15)
			vVicBlank <= `TRUE;
	endcase
end

reg [9:0] hVicBlankOff;
reg [9:0] hVicBlankOn;
always @(posedge clk33)
	hVicBlankOff <= turbo2 ? 10'd88 : 10'd103;
always @(posedge clk33)
	hVicBlankOn <= turbo2 ? 10'd508 : 10'd592;

always @(posedge clk33)
begin
	hVicBlank <= `FALSE;
	if (rasterX < hVicBlankOff)		// 15%
		hVicBlank <= `TRUE;
	else if (rasterX >= hVicBlankOn)	// 97.2%
		hVicBlank <= `TRUE;
end

//------------------------------------------------------------------------------
// Video Sync Interval
// - Video sync still needs to be generated as a reference point for the 
//   scan converter. Although it's not otherwise used it may be in the future
//   output, so it's generated accurately.
//------------------------------------------------------------------------------

FAL6567_sync usg1
(
	.chip(chip),
	.rst(rst),
	.clk(clk33),
	.turbo2(turbo2),
	.rasterX(rasterX),
	.rasterY(rasterY),
	.hSync(hSync8),
	.vSync(vSync8),
	.cSync(Sync)
);

//------------------------------------------------------------------------------
// Color burst window.
// - determines when color burst should be output. Not needed for the current
//   version of the core which only outputs VGA.
//------------------------------------------------------------------------------

reg [9:0] burstWindowBegin;
reg [9:0] burstWindowEnd;
// 504
always @(posedge clk33)
case(chip)
CHIP6567R8,CHIP6567OLD:
	burstWindowBegin <= turbo2 ? 10'd50 : 10'd43;
CHIP6569,CHIP6572:
	burstWindowBegin <= turbo2 ? 10'd53 : 10'd44;
endcase
always @(posedge clk33)
case(chip)
CHIP6567R8,CHIP6567OLD:
	burstWindowEnd <= turbo2 ? 10'd74 : 10'd63;
CHIP6569,CHIP6572:
	burstWindowEnd <= turbo2 ? 10'd95 : 10'd62;
endcase
reg burstWindow;
always @(posedge clk33)
begin
	if (rasterX >= burstWindowBegin && rasterX < burstWindowEnd && rasterY > 8)
		burstWindow <= `TRUE;
	else
		burstWindow <= `FALSE;
end

BUFGMUX ubgbrst (.S(burstWindow|burstClk), .I0(1'b0), .I1(burstClk), .O(colorBurst));


//------------------------------------------------------------------------------
// Borders
//------------------------------------------------------------------------------

always @(posedge clk33)
begin
	vVicBorder <= `TRUE;
	if (den) begin
		if (rsel) begin
			if (rasterY >= 51 && rasterY <= 251)
				vVicBorder <= `FALSE;
		end
		else begin
			if (rasterY >= 55 && rasterY <= 247)
				vVicBorder <= `FALSE;
		end
	end
end

always @(posedge clk33)
begin
	hVicBorder <= `TRUE;
	if (den) begin
		if (csel) begin
			if (rasterX >= 25 && rasterX <= (turbo2 ? 409 : 345))
				hVicBorder <= `FALSE;
		end
		else begin
			if (rasterX >= 32 && rasterX <= (turbo2 ? 396 : 336))
				hVicBorder <= `FALSE;
		end
	end
end


//------------------------------------------------------------------------------
// Graphics mode pixel calc.
//------------------------------------------------------------------------------
reg loadPixels, shiftPixels;
reg clkShift;
wire ismc = mcm & (bmm | ecm | shiftingChar[11]);

always @*
	loadPixels <= xscroll==rasterX[2:0];

always @(posedge clk33)
if (clken8) begin
	if (loadPixels)
		clkShift <= ~(mcm & (bmm | ecm | waitingChar[11]));
	else
		clkShift <= ismc ? ~clkShift : clkShift;
end

always @(posedge clk33)
if (clken8) begin
	if (loadPixels)
		shiftingChar <= waitingChar;
end

// Pixel shifter
always @(posedge clk33)
if (clken8) begin
	if (loadPixels)
		shiftingPixels <= waitingPixels;
	else if (clkShift) begin
		if (ismc)
			shiftingPixels <= {shiftingPixels[5:0],2'b0};
		else
			shiftingPixels <= {shiftingPixels[6:0],1'b0};
	end
end

always @(posedge clk33)
if (clken8)
	pixelBgFlag <= shiftingPixels[7];

// Compute pixel color
always @(posedge clk33)
if (clken8) begin
	pixelColor <= 4'h0; // black
	case({ecm,bmm,mcm})
	3'b000:	// Text mode
		pixelColor <= shiftingPixels[7] ? shiftingChar[11:8] : b0c;
	3'b001:	// Multi-color text mode
		if (shiftingChar[11])
			case(shiftingPixels[7:6])
			2'b00:  pixelColor <= b0c;
			2'b01:  pixelColor <= b1c;
			2'b10:  pixelColor <= b2c;
			2'b11:  pixelColor <= shiftingChar[10:8];
			endcase
		else
			pixelColor <= shiftingPixels[7] ? shiftingChar[11:8] : b0c;
	3'b010,3'b110: 
		pixelColor <= shiftingPixels[7] ? shiftingChar[7:4] : shiftingChar[3:0];
	3'b011,3'b111:
		case(shiftingPixels[7:6])
		2'b00:  pixelColor <= b0c;
		2'b01:  pixelColor <= shiftingChar[7:4];
		2'b10:  pixelColor <= shiftingChar[3:0];
		2'b11:  pixelColor <= shiftingChar[11:8];
		endcase
	3'b100:
		case({shiftingPixels[7],shiftingChar[7:6]})
		3'b000:  pixelColor <= b0c;
		3'b001:  pixelColor <= b1c;
		3'b010:  pixelColor <= b2c;
		3'b011:  pixelColor <= b3c;
		default:  pixelColor <= shiftingChar[11:8];
		endcase
	3'b101:
		if (shiftingChar[11])
			case(shiftingPixels[7:6])
			2'b00:  pixelColor <= b0c;
			2'b01:  pixelColor <= b1c;
			2'b10:  pixelColor <= b2c;
			2'b11:  pixelColor <= shiftingChar[11:8];
			endcase
		else
			case({shiftingPixels[7],shiftingChar[7:6]})
			3'b000:  pixelColor <= b0c;
			3'b001:  pixelColor <= b1c;
			3'b010:  pixelColor <= b2c;
			3'b011:  pixelColor <= b3c;
			default:  pixelColor <= shiftingChar[11:8];
			endcase
	endcase
end

//------------------------------------------------------------------------------
// Output color selection
//------------------------------------------------------------------------------

reg [3:0] color_code;

always @(posedge clk33)
begin
	// Force the output color to black for "illegal" modes
	case({ecm,bmm,mcm})
	3'b101,3'b110,3'b111:
		color_code <= 4'h0;
	default: color_code <= pixelColor;
	endcase
	// See if the mib overrides the output
	for (n = 0; n < MIBCNT; n = n + 1) begin
		if (!mdp[n] || !pixelBgFlag) begin
			if (mmc[n]) begin  // multi-color mode ?
				case(MCurrentPixel[n])
				2'b00:  ;
				2'b01:  color_code <= mm0;
				2'b10:  color_code <= mc[n];
				2'b11:  color_code <= mm1;
				endcase
			end
			else if (MCurrentPixel[n][1])
				color_code <= mc[n];
		end
	end
end

always @(posedge clk33)
if (clken8) begin
    if (vicBorder)
		color8 <= ec;
    else
		color8 <= color_code;
end

FAL6567_ColorROM ucrom1
(
	.clk(clk33),
	.ce(1'b1),
	.code(color8),
	.color(RGB)
);

wire [4:0] comp1;
RGB2Composite urgb2c1
(
	.clk(clk57),
	.ph(burstClk16x),
	.r(RGB[23:16]),
	.g(RGB[15:8]),
	.b(RGB[7:0]),
	.co(comp1)
);
always @(posedge clk57)
	comp <= (hVicBlank|vVicBlank) ? 5'd0 : comp1;

//------------------------------------------------------------------------------
// Register Interface
//
// VIC-II offers register feedback on all registers.
//------------------------------------------------------------------------------

always @(posedge clk33)
if (rst) begin
	ft816_rst <= 1'b0;	// active low
	turbo <= 1'b0;
	ram_page <= 5'd0;
	rst_pal <= 1'b0;
	regpg <= 1'd0;
	leg <= LEGACY;
	hSyncOn <= phSyncOn;
	hSyncOff <= phSyncOff;
	hBlankOff <= phBlankOff;
	hBorderOff <= phBorderOff;
	hBorderOn <= phBorderOn;
	hBlankOn <= phBlankOn;
	hTotal <= phTotal;
	hSyncPol <= phSyncPol;
	vSyncOn <= pvSyncOn;
	vSyncOff <= pvSyncOff;
	vBlankOff <= pvBlankOff;
	vBorderOff <= pvBorderOff;
	vBorderOn <= pvBorderOn;
	vBlankOn <= pvBlankOn;
	vTotal <= pvTotal;
	vSyncPol <= pvSyncPol;
	vm[9:0] <= 10'd0;
	cb[10:0] <= 11'b0;
	ec <= 4'h6;
	yscroll <= 3'd0;
	xscroll <= 3'd0;
	den = `TRUE;
	me <= 16'h0;
	for (n = 0; n < MIBCNT; n = n + 1) begin
		mx[n] = 9'd200;
		my[n] = 8'd5;
	end
	vdat <= 8'h00;
	vadr <= 19'h00000;
	vwr <= 1'b0;
end
else begin
	vwr <= 1'b0;
	rst_pal <= 1'b0;
  if (phi02 && cs_n==`LOW) begin
    dbo8 <= 8'hFF;
    case(ad[7:0])
    8'h00:  dbo8 <= mx[{regpg,3'd0}][7:0];
    8'h01:  dbo8 <= my[{regpg,3'd0}];
    8'h02:  dbo8 <= mx[{regpg,3'd1}][7:0];
    8'h03:  dbo8 <= my[{regpg,3'd1}];
    8'h04:  dbo8 <= mx[{regpg,3'd2}][7:0];
    8'h05:  dbo8 <= my[{regpg,3'd2}];
    8'h06:  dbo8 <= mx[{regpg,3'd3}][7:0];
    8'h07:  dbo8 <= my[{regpg,3'd3}];
    8'h08:  dbo8 <= mx[{regpg,3'd4}][7:0];
    8'h09:  dbo8 <= my[{regpg,3'd4}];
    8'h0A:  dbo8 <= mx[{regpg,3'd5}][7:0];
    8'h0B:  dbo8 <= my[{regpg,3'd5}];
    8'h0C:  dbo8 <= mx[{regpg,3'd6}][7:0];
    8'h0D:  dbo8 <= my[{regpg,3'd6}];
    8'h0E:  dbo8 <= mx[{regpg,3'd7}][7:0];
    8'h0F:  dbo8 <= my[{regpg,3'd7}];
    8'h10:  begin
        dbo8[0] <= mx[{regpg,3'd0}][8];
        dbo8[1] <= mx[{regpg,3'd1}][8];
        dbo8[2] <= mx[{regpg,3'd2}][8];
        dbo8[3] <= mx[{regpg,3'd3}][8];
        dbo8[4] <= mx[{regpg,3'd4}][8];
        dbo8[5] <= mx[{regpg,3'd5}][8];
        dbo8[6] <= mx[{regpg,3'd6}][8];
        dbo8[7] <= mx[{regpg,3'd7}][8];
        end
    8'h11:  begin
            dbo8[2:0] <= yscroll;
            dbo8[3] <= rsel;
            dbo8[4] <= den;
            dbo8[5] <= bmm;
            dbo8[6] <= ecm;
            end
    8'h12:  dbo8 <= rasterY[7:0];
    8'h13:  dbo8 <= lpx;
    8'h14:  dbo8 <= lpy;
    8'h15:  case(regpg)
            1'd0: dbo8 <= me[7:0];
            1'd1: dbo8 <= me[15:8];
            endcase
    8'h16:  dbo8 <= {2'b11,res,mcm,csel,xscroll};
    8'h17:  case(regpg)
            1'd0: dbo8 <= mye[7:0];
            1'd1: dbo8 <= mye[15:8];
            endcase
    8'h18:  begin
    		if (regpg) begin
    			dbo8 <= {3'd0,ram_page};
    		end
    		else begin
            	dbo8[0] <= 1'b1;
            	dbo8[3:1] <= cb[13:11];
            	dbo8[7:4] <= vm[13:10];
        	end
            end
    8'h19:  dbo8 <= {irq,3'b111,ilp,immc,imbc,irst};
    8'h1A:  dbo8 <= {4'b1111,elp,emmc,embc,erst};
    8'h1B:  dbo8 <= mdp;
    8'h1C:  case(regpg)
            1'd0: dbo8 <= mmc[7:0];
            1'd1: dbo8 <= mmc[15:8];
            endcase
    8'h1D:  case(regpg)
            1'd0: dbo8 <= mxe[7:0];
            1'd1: dbo8 <= mxe[15:8];
            endcase
    8'h1E:  case(regpg)
            1'd0: dbo8 <= m2m[7:0];
            1'd1: dbo8 <= m2m[15:8];
            endcase
    8'h1F:  case(regpg)
            1'd0: dbo8 <= m2d[7:0];
            1'd1: dbo8 <= m2d[15:0];
            endcase
    8'h20:  dbo8[3:0] <= ec;
    8'h21:  dbo8[3:0] <= b0c;
    8'h22:  dbo8[3:0] <= b1c;
    8'h23:  dbo8[3:0] <= b2c;
    8'h24:  dbo8[3:0] <= b3c;
    8'h25:  dbo8[3:0] <= mm0;
    8'h26:  dbo8[3:0] <= mm1;
    8'h27:  dbo8[3:0] <= mc[{regpg,3'd0}];
    8'h28:  dbo8[3:0] <= mc[{regpg,3'd1}];
    8'h29:  dbo8[3:0] <= mc[{regpg,3'd2}];
    8'h2A:  dbo8[3:0] <= mc[{regpg,3'd3}];
    8'h2B:  dbo8[3:0] <= mc[{regpg,3'd4}];
    8'h2C:  dbo8[3:0] <= mc[{regpg,3'd5}];
    8'h2D:  dbo8[3:0] <= mc[{regpg,3'd6}];
    8'h2E:  dbo8[3:0] <= mc[{regpg,3'd7}];
    8'h32:  dbo8 <= {leg,turbo,5'h1F,regpg};
    8'h3A:	dbo8 <= 8'h46;
    8'h3B:	dbo8 <= 8'h49;
    8'h34:	dbo8 <= vdatr;
    8'h35:	dbo8 <= vadr[7:0];
    8'h36:	dbo8 <= vadr[15:8];
    8'h37:	dbo8 <= {5'h0,vadr[18:16]};
    default:  dbo8 <= 8'hFF;
    endcase
  end
  if (phi02r[31] & ~phi02r[30]) begin // when phi02 transitions from high to low
    irst_clr <= `FALSE;
    imbc_clr <= `FALSE;
    immc_clr <= `FALSE;
    ilp_clr <= `FALSE;
    if (cs_n==`LOW) begin
      if (wr) begin
        case(ad[7:0])
        8'h00:  mx[{regpg,3'd0}][7:0] <= db;
        8'h01:  my[{regpg,3'd0}] <= db;
        8'h02:  mx[{regpg,3'd1}][7:0] <= db;
        8'h03:  my[{regpg,3'd1}] <= db;
        8'h04:  mx[{regpg,3'd2}][7:0] <= db;
        8'h05:  my[{regpg,3'd2}] <= db;
        8'h06:  mx[{regpg,3'd3}][7:0] <= db;
        8'h07:  my[{regpg,3'd3}] <= db;
        8'h08:  mx[{regpg,3'd4}][7:0] <= db;
        8'h09:  my[{regpg,3'd4}] <= db;
        8'h0A:  mx[{regpg,3'd5}][7:0] <= db;
        8'h0B:  my[{regpg,3'd5}] <= db;
        8'h0C:  mx[{regpg,3'd6}][7:0] <= db;
        8'h0D:  my[{regpg,3'd6}] <= db;
        8'h0E:  mx[{regpg,3'd7}][7:0] <= db;
        8'h0F:  my[{regpg,3'd7}] <= db;
        8'h10:  begin
                mx[{regpg,3'd0}][8] <= db[0];
                mx[{regpg,3'd1}][8] <= db[1];
                mx[{regpg,3'd2}][8] <= db[2];
                mx[{regpg,3'd3}][8] <= db[3];
                mx[{regpg,3'd4}][8] <= db[4];
                mx[{regpg,3'd5}][8] <= db[5];
                mx[{regpg,3'd6}][8] <= db[6];
                mx[{regpg,3'd7}][8] <= db[7];
                end
        8'h11:  begin
                yscroll <= db[2:0];
                rsel <= db[3];
                den <= db[4];
                bmm <= db[5];
                ecm <= db[6];
                rasterCmp[8] <= db[7];
                end
        8'h12:  rasterCmp[7:0] <= db;
        8'h13:  ; // light pen x
        8'h14:  ; // light pen y
        8'h15:  case(regpg)
                1'd0: me[7:0] <= db;
                1'd1: me[15:8] <= db;
                endcase
        8'h16:  begin
                xscroll <= db[2:0];
                csel <= db[3];
                mcm <= db[4];
                res <= db[5];
                end  
        8'h17:  case(regpg)
                1'd0: mye[7:0] <= db;
                1'd1: mye[15:8] <= db;
                endcase
        8'h18:  begin
        		if (regpg)
        			ram_page <= db[4:0];
        		else begin
                	cb[13:11] <= db[3:1];
                	vm[13:10] <= db[7:4];
            	end
                end
        8'h19:  begin
                irst_clr <= db[0];
                imbc_clr <= db[1];
                immc_clr <= db[2];
                ilp_clr <= db[3];
                irq_clr <= db[7];
                end
        8'h1A:  begin
                erst <= db[0];
                embc <= db[1];
                emmc <= db[2];
                elp <= db[3];
                end
        8'h1B:  mdp <= db;
        8'h1C:  case(regpg)
                1'd0: mmc[7:0] <= db;
                1'd1: mmc[15:8] <= db;
                endcase
        8'h1D:  case(regpg)
                1'd0: mxe[7:0] <= db;
                1'd1: mxe[15:8] <= db;
                endcase
        8'h1E:  ; // mm collision
        8'h1F:  ; // md collision
        8'h20:  ec <= db[3:0];  // exterior (border color)
        8'h21:  b0c <= db[3:0]; // background color #0
        8'h22:  b1c <= db[3:0];
        8'h23:  b2c <= db[3:0];
        8'h24:  b3c <= db[3:0];
        8'h25:  mm0 <= db[3:0];
        8'h26:  mm1 <= db[3:0];
        8'h27:  mc[{regpg,3'd0}] <= db[3:0];
        8'h28:  mc[{regpg,3'd1}] <= db[3:0];
        8'h29:  mc[{regpg,3'd2}] <= db[3:0];
        8'h2A:  mc[{regpg,3'd3}] <= db[3:0];
        8'h2B:  mc[{regpg,3'd4}] <= db[3:0];
        8'h2C:  mc[{regpg,3'd5}] <= db[3:0];
        8'h2D:  mc[{regpg,3'd6}] <= db[3:0];
        8'h2E:  mc[{regpg,3'd7}] <= db[3:0];

        8'h30:  regno <= db[5:0];
        8'h32:  begin
                regpg <= db[0];
                if (db[4])
                	rst_pal <= 1'b1;
`ifdef TURBO2                
                turbo2 <= db[5];
                if (db[5]) begin
                	hSyncOn <= 12'd24;
                	hSyncOff <= 12'd171;
                	hBlankOff <= 12'd244;
                	hBorderOff <= 12'd349;
                	hBorderOn <= 12'd1117;
                	hBlankOn <= 12'd1222;
                	hTotal <= 12'd1222;
                	hSyncPol <= 1'b1;
	            end
	            else begin
                	hSyncOn <= 12'd21;
                	hSyncOff <= 12'd147;
                	hBlankOff <= 12'd209;
                	hBorderOff <= 12'd308;
                	hBorderOn <= 12'd948;
                	hBlankOn <= 12'd1047;
                	hTotal <= 12'd1047;
                	hSyncPol <= 1'b1;
	            end
`else
				turbo2 <= 1'b0;                
`endif             
                turbo <= db[6];
                leg <= db[7];
                end
        8'h31:
          case(regno)
        6'h00:  hSyncOn[7:0] <= db;
        6'h01:  hSyncOn[11:8] <= db[3:0];
        6'h02:  hSyncOff[7:0] <= db;
        6'h03:  hSyncOff[11:8] <= db[3:0];
        6'h04:  hBlankOff[7:0] <= db;
        6'h05:  hBlankOff[11:8] <= db[3:0];
        6'h06:  hBorderOff[7:0] <= db;
        6'h07:  hBorderOff[11:8] <= db[3:0];
        6'h08:  hBorderOn[7:0] <= db;
        6'h09:  hBorderOn[11:8] <= db[3:0];
        6'h0A:  hBlankOn[7:0] <= db;
        6'h0B:  hBlankOn[11:8] <= db[3:0];
        6'h0C:  hTotal[7:0] <= db;
        6'h0D:  hTotal[11:8] <= db[3:0];
        6'h0F:  begin
                hSyncPol <= db[0];
                vSyncPol <= db[1];
                end
        6'h10:  vSyncOn[7:0] <= db;
        6'h11:  vSyncOn[11:8] <= db[3:0];
        6'h12:  vSyncOff[7:0] <= db;
        6'h13:  vSyncOff[11:8] <= db[3:0];
        6'h14:  vBlankOff[7:0] <= db;
        6'h15:  vBlankOff[11:8] <= db[3:0];
        6'h16:  vBorderOff[7:0] <= db;
        6'h17:  vBorderOff[11:8] <= db[3:0];
        6'h18:  vBorderOn[7:0] <= db;
        6'h19:  vBorderOn[11:8] <= db[3:0];
        6'h1A:  vBlankOn[7:0] <= db;
        6'h1B:  vBlankOn[11:8] <= db[3:0];
        6'h1C:  vTotal[7:0] <= db;
        6'h1D:  vTotal[11:8] <= db[3:0];
        endcase
        8'h34:  vdat <= db[7:0];
        8'h35:	vadr[7:0] <= db[7:0];
        8'h36:	vadr[15:8] <= db[7:0];
        8'h37:	begin
        		vadr[18:16] <= db[2:0];
        		vwr <= db[7];
        		end
        8'h38:	begin
        		ft816_rst <= db[0];
        		end
        endcase
      end
    end
  end
end

assign vSync1 = (vCtr >= vSyncOn && vCtr < vSyncOff) ^ vSyncPol;
assign hSync1 = (hCtr >= hSyncOn && hCtr < hSyncOff) ^ hSyncPol;
assign vBlank = vCtr >= vBlankOn || vCtr < vBlankOff;
assign hBlank = hCtr >= hBlankOn || hCtr < hBlankOff;
assign vBorder = vCtr >= vBorderOn || vCtr < vBorderOff;
assign hBorder = hCtr >= hBorderOn || hCtr < hBorderOff;

counter #(12) u4 (.rst(rst), .clk(clk33), .ce(1'b1), .ld(eol1), .d(12'd1), .q(hCtr) );
counter #(12) u5 (.rst(rst), .clk(clk33), .ce(eol1),  .ld(eof1), .d(12'd1), .q(vCtr) );

always @(posedge clk33)
    blank <= #1 hBlank|vBlank;
always @(posedge clk33)
    border <= #1 hBorder|vBorder;
always @(posedge clk33)
	hSync <= #1 hSync1;
always @(posedge clk33)
	vSync <= #1 vSync1;

endmodule

