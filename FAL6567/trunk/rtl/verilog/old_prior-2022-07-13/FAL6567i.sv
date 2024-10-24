// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567h.sv
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                
// Requires 134kB of block RAM
// ============================================================================
//
import FAL6567_pkg::*;

// 640x480 standard VGA timing is used, but the horizontal constants are multiplied
// by 1.299... to account for the use of a 32.71705MHz clock instead of 25.175.
// A five times clock (164MHz) is needed to drive the DVI interface.
// The 32.71705MHz clock was carefully selected as being on the high side of 32MHz
// given an input clock of 14.318MHz. Dividing 32.71705 by 32 gives a phi02 clock
// of 1.022MHz, really close to that normally supplied by the VIC-II.
//
module FAL6567h(cr_clk, phi02, rst_o, irq, aec, ba,
	cs_n, rw, ad, db, den_n, dir, ras_n, cas_n, lp_n,
	TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n
);
parameter pSymRasterEnable = 48;
parameter SIM = 0;

// Constants multiplied by 1.299... for 32.71705MHz clock
parameter phSyncOn  = 21;       //   16 front porch
parameter phSyncOff = 146;		//   96 sync
parameter phBlankOff = 208;		//   48 back porch
parameter phBorderOff = 307;	//    0 border
parameter phBorderOn = 947;	    //  640 display
parameter phBlankOn = 1040;		//    0 border
parameter phTotal = 1040; 		//  800 total clocks
parameter phSyncPol = 1;
// PAL Constants multiplied by 1.2533 for 31.55259 MHz clock
parameter phSyncOnPAL  = 20;       //   16 front porch
parameter phSyncOffPAL = 140;		//   96 sync
parameter phBlankOffPAL = 201;		//   48 back porch
parameter phBorderOffPAL = 282;	//    0 border
parameter phBorderOnPAL = 922;	    //  640 display
parameter phBlankOnPAL = 1003;		//    0 border
parameter phTotalPAL = 1003; 		//  800 total clocks
parameter phSyncPolPAL = 1;
//
parameter pvSyncOn  = 10;		//   10 front porch
parameter pvSyncOff = 12;		//    2 vertical sync
parameter pvBlankOff = 45;		//   33 back porch
parameter pvBorderOff = 85;		//    0 border	0
parameter pvBorderOn = 485;		//  480 display
parameter pvBlankOn = 525;  	//    0 border	0
parameter pvTotal = 525;		//  525 total scan lines
parameter pvSyncPol = 1;        // neg. polarity

input cr_clk;           // color reference clcck (14.31818)
output phi02;
output rst_o;
output irq;
output aec;
output ba;
input cs_n;
input rw;
inout [7:0] ad;
inout tri [11:0] db;
output den_n;
output dir;
output ras_n;
output cas_n;
input lp_n;

output TMDS_OUT_clk_p;
output TMDS_OUT_clk_n;
output [2:0] TMDS_OUT_data_p;
output [2:0] TMDS_OUT_data_n;


reg [3:0] p;
reg blank_n;
reg synclk;		// sync+lum clocking
reg colclk;		// color clocking
reg hSync, vSync;	// sync outputs

integer n;
wire cs = !cs_n;
wire clk200;
wire clk40;
wire clk28;
wire clk4x;
wire dot_clk;
wire clk164;	// 163.58525 MHz
wire clk33;		//  32.71705 MHz
reg [7:0] regShadow [127:0];

reg [7:0] ado;
wire vSync8,hSync8;
wire [3:0] pixelColor;
wire [3:0] color8;
wire [3:0] color40;
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
reg col80 = 1'b0;

reg [1:0] chip;
wire locked;
wire clken8;

wire phi0,phi1;
wire phi02,phis;
wire [31:0] phi02r;
wire mux;
wire enaData,enaSData;
wire vicRefresh;
wire vicAddrValid;
reg [7:0] dbo8;
wire [7:0] dbo33 = 8'h00;

wire badline;                   // flag bad line condition
reg den;                        // display enable
reg rsel, bmm, ecm;
reg csel, mcm, res;
wire [10:0] preRasterX;
wire [10:0] rasterX;
reg [10:0] rasterXMax;
wire [8:0] preRasterY;
wire [8:0] rasterY;
wire [8:0] nextRasterY;
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
reg ref5;

reg pixelBgFlag;

// Character mode vars
reg [10:0] vmndx;                  // video matrix index
reg [11:0] nextChar;
reg [11:0] charbuf [78:0];
wire [2:0] scanline;

reg [3:0] sprite;
reg [MIBCNT-1:0] MActive;
reg [7:0] MPtr [MIBCNT-1:0];
reg [5:0] MCnt [MIBCNT-1:0];
reg [8:0] mx [MIBCNT-1:0];
reg [7:0] my [MIBCNT-1:0];
reg [3:0] mc [MIBCNT-1:0];
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
reg [1:0] regpg;  // register set page for sprites

reg [4:0] ram_page;
reg [13:0] addr;
wire [13:0] vicAddr;
wire [31:0] stc;
wire stCycle = stc[31];
wire stCycle1 = stc[0];
wire stCycle2 = stc[1];
wire stCycle3 = stc[2];
wire [18:0] sc_ram_wadr, sc_ram_radr;
wire [7:0] sc_ram_dato;
reg sc_ram_rlatch;

reg [8:0] sprite1;
reg [3:0] sprite2,sprite3,sprite4,sprite5;
reg [10:0] rasterX3;

reg [11:0] shiftingChar,waitingChar,readChar;
wire [7:0] shiftingPixels;
reg [7:0] waitingPixels,readPixels;

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

assign irq = (ilp & elp) | (immc & emmc) | (imbc & embc) | (irst & erst); 
 
reg rasterIRQDone;

// VIC-II timing
wire hVicBlank;
wire vVicBlank;
wire vicBlank;
wire hVicBorder;
wire vVicBorder;
wire vicBorder;

reg rst_pal = 0;
wire pi_req;
reg pi_ack;
wire [7:0] pi_adr;
wire [7:0] pi_dat;

reg vwr;
reg [18:0] vadr;
reg [7:0] vdat;
reg [7:0] vdatr;

reg [21:0] rstcntr = 0;
wire xrst = SIM ? !rstcntr[3] : !rstcntr[21];
always_ff @(posedge cr_clk)
if (xrst)
  rstcntr <= rstcntr + 4'd1;

// Set Limits
// Yes, this is clocked because we want the outputs to come from ff's not
// combo logic.
always_ff @(posedge dot_clk)
case(chip)
CHIP6567R8:   rasterYMax = 9'd262;
CHIP6567OLD:  rasterYMax = 9'd261;
CHIP6569:     rasterYMax = 9'd311;
CHIP6572:     rasterYMax = 9'd311;
endcase
always_ff @(posedge dot_clk)
if (col80)
	case(chip)
	CHIP6567R8:   rasterXMax = {8'd129,3'b111};
	CHIP6567OLD:  rasterXMax = {8'd128,3'b111};
	CHIP6569:     rasterXMax = {8'd126,3'b111};
	CHIP6572:     rasterXMax = {8'd126,3'b111};
	endcase
else
	case(chip)
	CHIP6567R8:   rasterXMax = {8'd64,3'b111};
	CHIP6567OLD:  rasterXMax = {8'd63,3'b111};
	CHIP6569:     rasterXMax = {8'd62,3'b111};
	CHIP6572:     rasterXMax = {8'd62,3'b111};
	endcase

generate begin : gClkwiz
if (PAL)
FAL6567_clkwizpal u1
(
  // Clock out ports
  .clk160(clk164),     // output clk164
  .clk32(clk33),     // output clk33
  // Status and control signals
  .reset(xrst), // input reset
  .locked(locked),       // output locked
 // Clock in ports
  .clk_in1(cr_clk)
);      // input clk_in1
else
FAL6567_clkwiz40 uclk40
(
  // Clock out ports
  .clk200(clk200),     // output clk164
  .clk40(clk40),     // output clk33
  // Status and control signals
  .reset(xrst), // input reset
  .locked(locked1),       // output locked
 // Clock in ports
  .clk_in1(cr_clk)
);      // input clk_in1
FAL6567_clkwiz14 uclk14
(
  // Clock out ports
  .clk114(),     // output clk164
  .clk28(clk28), // output clk28
  .clk14(clk4x),
  .clk8(dot_clk),
  // Status and control signals
  .reset(xrst), // input reset
  .locked(locked2),       // output locked
 // Clock in ports
  .clk_in1(cr_clk)
);      // input clk_in1
end
endgenerate

wire rst = !(locked1&locked2);
assign rst_o = rst;

// We can put the tri-state logic in this module assuming it is the top one.
assign den_n = aec ? cs_n : 1'b0;
assign dir = aec ? rw : 1'b0;
assign db = rst ? 12'bz : (aec && !cs_n && rw) ? {4'h0,dbo8} : 12'bz;

always_ff @(posedge clk28)
	if (rst)
		chip <= db[9:8];
always_ff @(posedge clk28)
if (rst)
	ado <= 8'hFF;
else
	ado <= mux ? vicAddr[7:0] : {2'b11,vicAddr[13:8]};
assign ad = aec ? 8'bz : ado;

wire ras_nne;
wire phi02_pe;
edge_det ued2 (.rst(rst), .clk(clk28), .ce(1'b1), .i(ras_n), .ne(ras_nne), .pe());
edge_det ued3 (.rst(rst), .clk(clk28), .ce(1'b1), .i(phi02), .pe(phi02_pe), .ne());

//------------------------------------------------------------------------------
// Bus cycle type
//------------------------------------------------------------------------------

always_comb
begin
	case(vicCycle)
	VIC_SPRITE:
		if (MActive[sprite2])
			busCycle <= BUS_SPRITE;
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
	default:
		busCycle <= BUS_IDLE;
	endcase
end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

FAL6567i_Timing utim1 (
	.rst(rst),
	.clk28(clk28),
	.stc(stc),
	.phi02(phi02),
	.phi02r(phi02r),
	.busCycle(busCycle),
	.ras_n(ras_n),
	.mux(mux),
	.cas_n(cas_n),
	.enaData(enaData),
	.enaMCnt(enaMCnt)
);

//------------------------------------------------------------------------------
// Raster / Refresh counters
//------------------------------------------------------------------------------
always_ff @(posedge clk28)
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

FAL6567i_RasterXY urxy1
(
	.rst(rst),
	.clk8(clk8),
	.rasterXMax(rasterXMax),
	.rasterYMax(rasterYMax),
	.preRasterX(preRasterX),
	.rasterX(rasterX),
	.preRasterY(preRasterY),
	.rasterY(rasterY),
	.nextRasterY(nextRasterY)
);

//------------------------------------------------------------------------------
// Decode cycles
//------------------------------------------------------------------------------

FAL6567_CycleDecode ucycd1
(
	.chip(chip),
	.col80(col80),
	.preRasterX(preRasterX),
	.vicCycle(vicCycle)
);

wire [11:0] rasterX2 = {preRasterX,1'b0};
always_ff @(posedge clk8)
begin
	if (col80)
	  case(chip)
	  CHIP6567R8:   sprite1 <= rasterX2 - 11'h58E;
	  CHIP6567OLD:  sprite1 <= rasterX2 - 11'h57E;
	  default:      sprite1 <= rasterX2 - 11'h56E;
	  endcase
	else
	  case(chip)
	  CHIP6567R8:   sprite1 <= rasterX2 - 11'h2FE;
	  CHIP6567OLD:  sprite1 <= rasterX2 - 11'h2EE;
	  default:      sprite1 <= rasterX2 - 11'h2DE;
	  endcase
	sprite2 <= col80 ? sprite1[8:5] : {1'b0,sprite1[7:5]};
end

// Centre sprite number according to RAM timing.
always_ff @(posedge clk28)
begin
	sprite3 <= sprite2;
	sprite4 <= sprite3;
	sprite5 <= sprite4;
	sprite <= sprite5;
end

//wire ref5 = rasterX2[10:4]==7'h03;
always_ff @(posedge clk28)
	ref5 <= rasterX2[11:4]+2'd1==7'h03;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// register this?
//always_ff @(posedge clk33)
assign badline = preRasterY[2:0]==yscroll && den && (preRasterY >= (SIM ? 9'd1 : 9'h30) && preRasterY <= 9'hF7);

//------------------------------------------------------------------------------
// Bus available generator
//------------------------------------------------------------------------------

FAL6567i_BusAvailGen uba1
(
	.chip(chip),
	.rst(rst),
	.clk28(clk28),
	.col80(col80),
	.me(me),
	.my(my),
	.badline(badline),
	.rasterX2(rasterX2),
	.nextRasterY(nextRasterY),
	.MActive(MActive),
	.stCycle2(stCycle2),
	.ba(ba)
);

//------------------------------------------------------------------------------
// AEC
//
// AEC follows BA by three clock cycles.
//------------------------------------------------------------------------------
reg ba1,ba2,ba3;

always_ff @(posedge clk28)
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

integer n2;
always_ff @(posedge clk28)
if (phi02==`HIGH && enaData && (vicCycle==VIC_RC || vicCycle==VIC_CHAR)) begin
	if (badline)
		nextChar <= db;	// Grab all 12 bits
	else
		nextChar <= col80 ? charbuf[78] : charbuf[38];
	for (n2 = 78; n2 > 0; n2 = n2 -1)
		charbuf[n2] = charbuf[n2-1];
	charbuf[0] <= nextChar;
end

always_ff @(posedge clk28)
if (phi02==`LOW && enaData) begin
	if (vicCycle==VIC_CHAR || vicCycle==VIC_G) begin
		readPixels <= db[7:0];
		readChar <= nextChar;
	end
	waitingPixels <= readPixels;
	waitingChar <= readChar;
end

always_ff @(posedge clk28)
if (phis==`LOW && enaData && busCycle==BUS_SPRITE) begin
	if (MActive[sprite])
		MPtr[sprite] <= db[7:0];
	else
		MPtr[sprite] <= 8'd255;
end

//------------------------------------------------------------------------------
// Video matrix counter
//------------------------------------------------------------------------------
reg [10:0] vmndxStart;

always_ff @(posedge clk28)
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
		if (rasterX2[10:4]==7'h2C) begin
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

FAL6567i_ScanlineCounter uslc1
(
	.rst(rst),
	.clk28(clk28),
	.phi02(phi02),
	.enaData(enaData),
	.ref5(ref5),
	.badline(badline),
	.rasterX2(rasterX2),
	.scanline(scanline)
);

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
integer n3;
always_comb
	for (n3 = 0; n3 < MIBCNT; n3 = n3 + 1)
		MActive[n3] <= MCnt[n3] != 6'd63;

reg [MIBCNT-1:0] collision;
integer n4;
always_comb
	for (n4 = 0; n4 < MIBCNT; n4 = n4 + 1)
		collision[n4] = MCurrentPixel[n4][1];

// Sprite-sprite collision logic
always_ff @(posedge clk28)
if (rst)
	m2mhit <= `FALSE;
else begin
	if (immc_clr)
		immc <= `FALSE;
	if (ad[7:0]==8'h1E && regpg==2'b01 && phi02 && aec && cs && enaData) begin
		m2m[15:8] <= 8'h0;
	end
	if (ad[7:0]==8'h1E && regpg==2'b00 && phi02 && aec && cs && enaData) begin
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
integer n5;
always_ff @(posedge clk28)
if (rst)
	m2dhit <= `FALSE;
else begin
	if (imbc_clr)
		imbc <= `FALSE;
	if (ad[7:0]==8'h1F && regpg==2'b01 && phi02 && aec && cs && enaData) begin
		m2d[15:8] <= 8'h0;
	end
	if (ad[7:0]==8'h1F && regpg==2'b00 && phi02 && aec && cs && enaData) begin
		m2d[7:0] <= 8'h0;
		m2dhit <= `FALSE;
	end
	for (n5 = 0; n5 < MIBCNT; n5 = n5 + 1) begin
		if (collision[n5] & pixelBgFlag & ~vicBorder) begin
			m2d[n5] <= `TRUE;
			if (!m2dhit) begin
				m2dhit <= `TRUE;
				imbc <= `TRUE;
			end
		end
	end
end

integer n6;
always_ff @(posedge clk28)
begin
	for (n6 = 0; n6 < MIBCNT; n6 = n6 + 1) begin
		if (rasterX == 10)
			MShift[n6] <= `FALSE;
		else if (rasterX == (col80 ? {mx[n6],1'b0} : mx[n6]))
			MShift[n6] <= `TRUE;
	end
end

integer n7;
always_ff @(posedge clk28)
if (rst & SIM) begin
	for (n7 = 0; n7 < MIBCNT; n7 = n7 + 1) begin
		MCnt[n7] <= 6'd63;
	end
end
else begin
	// Trigger sprite accesses on the last character cycle
	// if the sprite Y coordinate will match.
	if (rasterX2==(col80 ? 11'h530 : 11'h2B0)) begin
		for (n7 = 0; n7 < MIBCNT; n7 = n7 + 1) begin
			if (!MActive[n7] && me[n7] && nextRasterY == my[n7])
				MCnt[n7] <= 6'd0;
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

// X expansion - when to clock the shift register
reg [1:0] mShiftCount[0:MIBCNT-1];

integer n8;
always_ff @(posedge clk28)
if (clken8) begin
	for (n8 = 0; n8 < MIBCNT; n8 = n8 + 1) begin
		if (MShift[n8]) begin
			case({mxe,mc[n8]})
			2'b00:	mShiftCount[n8] <= 2'd3;
			2'b01:	mShiftCount[n8][0] <= ~mShiftCount[n8][0];
			2'b10:	mShiftCount[n8][0] <= ~mShiftCount[n8][0];
			2'b11:	mShiftCount[n8] <= mShiftCount[n8] + 2'd1;
			endcase
		end
		else begin
			case({mxe,mc[n8]})
			2'b00:	mShiftCount[n8] <= 2'd3;
			2'b01:	mShiftCount[n8] <= 2'd2;
			2'b10:	mShiftCount[n8] <= 2'd2;
			2'b11:	mShiftCount[n8] <= 2'd0;
			endcase
		end
	end
end

// Y expansion
integer n10;
always_ff @(posedge clk28)
begin
	// Reset expansion flipflop once sprite becomes deactivated or
	// if no sprite Y expansion.
	for (n10 = 0; n10 < MIBCNT; n10 = n10 + 1) begin
		if (!mye[n10] || !MActive[n10])
			mye_ff[n10] <= 1'b0;
	end
	if (enaData && ref5 && !phi02) begin
		for (n10 = 0; n10 < MIBCNT; n10 = n10 + 1) begin
			if (MActive[n10] & mye[n10])
				mye_ff[n10] <= !mye_ff[n10];
		end  
	end
end


integer n9;
always_comb
	for (n9 = 0; n9 < MIBCNT; n9 = n9 + 1)
		mClkShift[n9] <= mShiftCount[n9]==2'd3;

// Handle sprite pixel loading / shifting
FAL6567i_SpritePixelShifter usprps1
(
	.clk28(clk28),
	.clk8(clk8),
	.phi02(phi02),
	.enaData(enaData),
	.sprite1(sprite1),
	.vicCycle(vicCycle),
	.MActive(MActive),
	.MShift(MShift),
	.mClkShift(mClkShift),
	.mmc(mmc),
	.db(db[7:0]),
	.sprite(sprite),
	.MCurrentPixel(MCurrentPixel)
);

//------------------------------------------------------------------------------
// Address Generation
//------------------------------------------------------------------------------

FAL6567_AddressGen uag1
(
	.clk33(clk33),
	.phi02(phi02),
	.col80(col80),
	.bmm(bmm),
	.ecm(ecm),
	.vicCycle(vicCycle),
	.refcntr(refcntr),
	.vm(vm),
	.vmndx(vmndx),
	.cb(cb),
	.scanline(scanline),
	.nextChar(nextChar),
	.sprite(sprite),
	.sprite1(sprite1),
	.MCnt(MCnt),
	.MPtr(MPtr),
	.vicAddr(vicAddr)
);

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
always_ff @(posedge clk33)
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
always_ff @(posedge clk33)
begin
  if (ilp_clr)
		ilp <= `LOW;
  if (rasterY == rasterYMax)
		lightPenHit <= `FALSE;
  else if (!lightPenHit && lp_n == `LOW) begin
		lightPenHit <= `TRUE; 
		ilp <= `HIGH; 
		lpx <= rasterX[9:2];
		lpy <= rasterY[8:1];
  end
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
	.rasterX(rasterX),
	.rasterY(rasterY),
	.hSync(hSync8),
	.vSync(vSync8),
	.cSync(Sync)
);

//------------------------------------------------------------------------------
// Video Blank Interval
//------------------------------------------------------------------------------

FAL6567_blank ublnk
(
	.chip(chip),
	.clk33(clk33),
	.col80(col80),
	.rasterX(rasterX),
	.rasterY(rasterY),
	.vBlank(vVicBlank),
	.hBlank(hVicBlank),
	.blank(vicBlank)
);

always_ff @(posedge clk33)
if (rst)
	blank_n <= 1'b0;
else
	blank_n <= blank;

//------------------------------------------------------------------------------
// Borders
//------------------------------------------------------------------------------

FAL6567_borders ubrdr1
(
	.clk33(clk33),
	.den(den),
	.col80(col80),
	.rsel(rsel),
	.csel(csel),
	.rasterX(rasterX),
	.rasterY(rasterY),
	.hBorder(hVicBorder),
	.vBorder(vVicBorder),
	.border(vicBorder)
);

//------------------------------------------------------------------------------
// Graphics mode pixel calc.
//------------------------------------------------------------------------------
reg loadPixels, shiftPixels;
reg clkShift;
wire ismc = mcm & (bmm | ecm | shiftingChar[11]);

always_comb
	loadPixels <= xscroll==rasterX[2:0];

always_ff @(posedge clk33)
if (clken8) begin
	if (loadPixels)
		clkShift <= ~(mcm & (bmm | ecm | waitingChar[11]));
	else
		clkShift <= ismc ? ~clkShift : clkShift;
end

always_ff @(posedge clk33)
if (clken8) begin
	if (loadPixels)
		shiftingChar <= waitingChar;
end

FAL6567_PixelShifter ups1
(
	.clk33(clk33),
	.clken8(clken8),
	.ismc(ismc),
	.load(loadPixels),
	.shift(clkShift),
	.pixels_i(waitingPixels),
	.pixels_o(shiftingPixels)
);

FAL6567_ComputePixelColor ucpc1
(
	.clk33(clk33),
	.clken8(clken8),
	.ecm(ecm),
	.bmm(bmm),
	.mcm(mcm),
	.pixelColor(pixelColor),
	.shiftingPixels(shiftingPixels),
	.shiftingChar(shiftingChar),
	.b0c(b0c),
	.b1c(b1c),
	.b2c(b2c),
	.b3c(b3c)
);

//------------------------------------------------------------------------------
// Output
//------------------------------------------------------------------------------

always_ff @(posedge clk33)
if (clken8)
	pixelBgFlag <= shiftingPixels[7];

FAL6567_ColorSelect ucs1
(
	.clk33(clk33),
	.clken8(clken8),
	.ecm(ecm),
	.bmm(bmm),
	.mcm(mcm),
	.pixelColor(pixelColor),
	.mdp(mdp), 
	.mmc(mmc),
	.pixelBgFlag(pixelBgFlag),
	.MCurrentPixel(MCurrentPixel),
	.mm0(mm0),
	.mm1(mm1),
	.mc(mc),
	.ec(ec),
	.vicBlank(vicBlank),
	.vicBorder(vicBorder),
	.color(color8)
);

FAL6567i_ScanConverter usc1
(
  .chip(chip),
  .clk40(clk40),
  .clk8(clk8),
  .col80(col80),
  .hSync8_i(hSync8),
  .vSync8_i(vSync8),
  .color_i(color8),
  .hSync40_i(hSync),
  .vSync40_i(vSync),
  .color_o(color40)
);

FAL6567_ColorROM ucrom1
(
	.clk(clk40),
	.ce(1'b1),
	.code(color40),
	.color(RGB)
);

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
	.vid_pData({RGB[23:16],RGB[7:0],RGB[15:8]}),
	.vid_pVDE(~blank),
	.vid_pHSync(hSync),    // hSync is neg going for 1366x768
	.vid_pVSync(vSync),
	.PixelClk(clk40),
	.SerialClk(clk200)
);


//------------------------------------------------------------------------------
// Register Interface
//
// VIC-II offers register feedback on all registers.
//------------------------------------------------------------------------------

integer n14;
always_ff @(posedge clk33)
if (rst) begin
	regpg <= 2'd0;
	col80 <= 1'b0;
	if (PAL) begin
		hSyncOn <= phSyncOnPAL;
		hSyncOff <= phSyncOffPAL;
		hBlankOff <= phBlankOffPAL;
		hBorderOff <= phBorderOffPAL;
		hBorderOn <= phBorderOnPAL;
		hBlankOn <= phBlankOnPAL;
		hTotal <= phTotalPAL;
	end
	else begin
		hSyncOn <= phSyncOn;
		hSyncOff <= phSyncOff;
		hBlankOff <= phBlankOff;
		hBorderOff <= phBorderOff;
		hBorderOn <= phBorderOn;
		hBlankOn <= phBlankOn;
		hTotal <= phTotal;
	end
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
	for (n14 = 0; n14 < MIBCNT; n14 = n14 + 1) begin
		mx[n14] = 9'd200;
		my[n14] = 8'd5;
	end
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
    8'h17:  case(regpg[0])
            1'd0: dbo8 <= mye[7:0];
            1'd1: dbo8 <= mye[15:8];
            endcase
    8'h18:  begin
            	dbo8[0] <= 1'b1;
            	dbo8[3:1] <= cb[13:11];
            	dbo8[7:4] <= vm[13:10];
            end
    8'h19:  dbo8 <= {irq,3'b111,ilp,immc,imbc,irst};
    8'h1A:  dbo8 <= {4'b1111,elp,emmc,embc,erst};
    8'h1B:  dbo8 <= mdp;
    8'h1C:  case(regpg[0])
            1'd0: dbo8 <= mmc[7:0];
            1'd1: dbo8 <= mmc[15:8];
            endcase
    8'h1D:  case(regpg[0])
            1'd0: dbo8 <= mxe[7:0];
            1'd1: dbo8 <= mxe[15:8];
            endcase
    8'h1E:  case(regpg[0])
            1'd0: dbo8 <= m2m[7:0];
            1'd1: dbo8 <= m2m[15:8];
            endcase
    8'h1F:  case(regpg[0])
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
    8'h32:  dbo8 <= {1'd0,col80,4'hF,regpg};
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
        8'h15:  case(regpg[0])
                1'd0: me[7:0] <= db;
                1'd1: me[15:8] <= db;
                endcase
        8'h16:  begin
                xscroll <= db[2:0];
                csel <= db[3];
                mcm <= db[4];
                res <= db[5];
                end  
        8'h17:  case(regpg[0])
                1'd0: mye[7:0] <= db;
                1'd1: mye[15:8] <= db;
                endcase
        8'h18:  begin
                	cb[13:11] <= db[3:1];
                	vm[13:10] <= db[7:4];
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
                regpg <= db[1:0];
                col80 <= db[6];
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

always_ff @(posedge clk33)
  blank <= #1 hBlank|vBlank;
always_ff @(posedge clk33)
  border <= #1 hBorder|vBorder;
always_ff @(posedge clk33)
	hSync <= #1 hSync1;
always_ff @(posedge clk33)
	vSync <= #1 vSync1;

endmodule

