// ============================================================================
// (C) 2016 Robert Finch
// rob<remove>@finitron.ca
// All Rights Reserved.
//
//	FAL6567.v
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

// An 800x480 display format is created for VGA using the 640x480 standard VGA
// timing. The dot clock is faster though at 33.3MHz. This allows a 640x400
// display area with a border to be created. This is double the horizontal and
// vertical resolution of the VIC-II. 
//
module FAL6567(chip, clk100, phi02, dotclk, rst_o, irq, aec, ba, cs_n, rw, ad, db, den_n, dir, ras_n, cas_n, lp_n, hSync, vSync, red, green, blue);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;
parameter LEGACY = 1'b1;
parameter MIBCNT = 16;

// Constants multiplied by 1.333 for 33.33MHz clock
parameter phSyncOn  = 21;     //   16 front porch
parameter phSyncOff = 146;		//   96 sync
parameter phBlankOff = 208;		//   48 back porch
parameter phBorderOff = 304;	//    0 border
parameter phBorderOn = 944;	  //  640 display
parameter phBlankOn = 1040;		//    0 border
parameter phTotal = 1040; 		//  800 total clocks
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
parameter SIM = 1'b1;

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

input [1:0] chip;
input clk100;
output phi02;
output dotclk;
output rst_o;
output irq;
output aec;
output reg ba;
input cs_n;
input rw;
inout [13:0] ad;
inout tri [11:0] db;
output den_n;
output dir;
output ras_n;
output cas_n;
input lp_n;
output reg hSync, vSync;	// sync outputs
output [1:0] red;
output [1:0] green;
output [1:0] blue;

integer n;
wire cs = !cs_n;
wire clk33;
reg [7:0] regShadow [127:0];

reg [13:0] ado;
reg [13:0] ado1;
reg [7:0] p;
wire vSync8,hSync8;
reg [3:0] pixelColor;
reg [3:0] color8;
wire [3:0] color33;
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

wire clken8;
reg [32:0] phi0r,phi1r,phi2r,phi02r,phisr;
wire phi0,phi1,phi2;
reg phi02,phis;
reg [32:0] clk3r;
reg [32:0] clk8r;
reg [32:0] rasr;
reg [32:0] muxr;
reg [32:0] casr;
reg [32:0] enaDatar,enaSDatar;
wire enaData,enaSData;
wire vicRefresh;
wire vicAddrValid;
reg [7:0] dbo8;
wire [7:0] dbo33 = 8'h00;

wire badline;                   // flag bad line condition
reg den;                        // display enable
reg rsel, bmm, ecm;
reg csel, mcm, res;
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
reg [9:0] vmndx;                  // video matrix index
reg [11:0] nextChar;
reg [11:0] charbuf [38:0];
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
reg [MIBCNT-1:0] mxe, mxe_ff;
reg [MIBCNT-1:0] mdp;
reg [MIBCNT-1:0] mc_ff;
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

reg [13:0] addr;
reg [13:0] vicAddr;

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
reg hVicBlank;
reg vVicBlank;
reg hVicBorder;
reg vVicBorder;
wire vicBorder = hVicBorder | vVicBorder;

reg [21:0] rstcntr;
wire xrst = SIM ? !rstcntr[3] : !rstcntr[21];
always @(posedge clk33)
if (xrst)
  rstcntr <= rstcntr + 4'd1;

// Set Limits
always @(chip)
case(chip)
CHIP6567R8:   begin rasterYMax = 9'd262; rasterXMax = {7'd64,3'b111}; end
CHIP6567OLD:  begin rasterYMax = 9'd261; rasterXMax = {7'd63,3'b111}; end
CHIP6569:     begin rasterYMax = 9'd311; rasterXMax = {7'd62,3'b111}; end
CHIP6572:     begin rasterYMax = 9'd311; rasterXMax = {7'd62,3'b111}; end
endcase

FAL6567_clkgen u1
(
  .rst(xrst),
  .xclk(clk100),
  .clk33(clk33),
  .locked(locked)
);

wire rst = !locked;
assign rst_o = rst;

assign den_n = aec ? cs_n : 1'b0;
assign dir = aec ? rw : 1'b0;
assign db = (aec && !cs_n && rw) ? (ad[5:0] < 6'h30 ? {4'h0,dbo8} : {4'h0,dbo33}) : 12'bz;   
always @(posedge clk33)
if (rst)
  ado1 <= 14'h3FFF;
else
  ado1 <= mux ? {vicAddr[13:8],2'b11,vicAddr[13:8]} : vicAddr[13:0];
assign ad = aec ? 14'bz : ado1;

FAL6567_ScanConverter u2
(
  .chip(chip),
  .clk33(clk33),
  .clken8(clken8),
  .hSync8_i(hSync8),
  .vSync8_i(vSync8),
  .color_i(color8),
  .hSync33_i(hSync),
  .vSync33_i(vSync),
  .color_o(color33)
);

always @(posedge clk33)
if (rst) begin
  clk8r <= 33'b100010001000100010001000100010000;
end
else begin
  if (stCycle)
    clk8r <= 33'b000010001000100010001000100010001;
  else
    clk8r <= {clk8r[31:0],1'b0};
end
assign clken8 = clk8r[32];
assign dotclk = clk8r[32];

reg [32:0] stc;
always @(posedge clk33)
if (rst)
  stc <= 33'b100000000000000000000000000000000;
else
  stc <= {stc[31:0],stc[32]};
wire stCycle = stc[32];
wire stCycle1 = stc[0];
wire stCycle2 = stc[1];
wire stCycle3 = stc[2];

always @(posedge clk33)
if (rst)
  clk3r <= 33'b100000000001000000000010000000000;
else
  clk3r <= {clk3r[31:0],clk3r[32]};

always @(posedge clk33)
if (rst)
  phi0r <= 33'b111111111110000000000000000000000;
else
  phi0r <= {phi0r[31:0],phi0r[32]};
assign phi0 = phi0r[32];

always @(posedge clk33)
if (rst)
  phi02r <= 33'b000000000000000001111111111111111;
else begin
  phi02r <= {phi02r[31:0],phi02r[32]};
end
always @(posedge clk33)
  phi02 <= phi02r[0];
//assign phi02 = phi02r[32];

always @(posedge clk33)
if (rst)
  phisr <= 33'b000000000001111111111111111111111;
else
  phisr <= {phisr[31:0],phisr[32]};
always @(posedge clk33)
  phis <= phisr[1];

always @(posedge clk33)
if (rst)
  phi1r <= 33'b000000000001111111111100000000000;
else
  phi1r <= {phi1r[31:0],phi1r[32]};
assign phi0 = phi1r[32];

always @(posedge clk33)
if (rst)
  phi2r <= 33'b000000000000000000000011111111111;
else
  phi2r <= {phi2r[31:0],phi2r[32]};
assign phi2 = phi2r[32];

always @(posedge clk33)
if (rst) begin
  rasr <= 33'b111111111111111111111111110000000;
end
else begin
  if (stCycle2) begin
    case(busCycle)
    BUS_IDLE:   rasr <= 33'b111111111111111111111111000000000;  // I
    BUS_LS:     rasr <= 33'b111111100000000001111111000000000;  // S
    BUS_SPRITE: rasr <= 33'b111100000001111000000000000000000;  // S - cycle
    BUS_CG:     rasr <= 33'b111111100000000001111111000000000;  // G,C
    BUS_G:      rasr <= 33'b111111100000000001111111000000000;  // G,C
    BUS_REF:    rasr <= 33'b111111100000000001111111000000000;  // R,C or R
    endcase
  end
  else
    rasr <= {rasr[31:0],1'b0};
end
assign ras_n = rasr[32];
  
always @(posedge clk33)
if (rst) begin
  muxr <= 33'b111111111111111111111111100000000;  // I
end
else begin
  if (stCycle1) begin
    case(busCycle)
    BUS_IDLE:   muxr <= 33'b111111111111111111111111100000000;  // I
    BUS_LS:     muxr <= 33'b111111110000000001111111100000000;  // S
    BUS_SPRITE: muxr <= 33'b111110000001111100000000000000000;  // S - cycle
    BUS_CG:     muxr <= 33'b111111110000000001111111100000000;  // G,C
    BUS_G:      muxr <= 33'b111111110000000001111111100000000;  // G,C
    BUS_REF:    muxr <= 33'b000000000000000001111111100000000;  // R,C or R
    endcase
  end
  else
    muxr <= {muxr[31:0],1'b0};
end
assign mux = muxr[32];
  
always @(posedge clk33)
if (rst) begin
  casr <= 33'b111111111111111110000011111100000;  // R,C
end
else begin
  if (stCycle2) begin
    case(busCycle)
    BUS_IDLE:   casr <= 33'b111111111111111111111111110000000;  // I - cycle
//    CHAR5_CYCLE:  casr <= 33'b111111000011000011000011000110000;  // G,C
//    CHAR6_CYCLE:  casr <= 33'b110001100001100011000011000110000;  // G,C
    BUS_LS:     casr <= 33'b111111111000000001111111110000000;  // S
    BUS_SPRITE: casr <= 33'b111111000001111110000110000110000;  // S - cycle
    BUS_CG:     casr <= 33'b111111111000000001111111110000000;  // G,C
    BUS_G:      casr <= 33'b111111111000000001111111110000000;  // G,C
    BUS_REF:    casr <= 33'b111111111111111111111111110000000;  // R,C
    endcase
  end
  else
    casr <= {casr[31:0],1'b0};
end
assign cas_n = casr[32];

always @(posedge clk33)
if (rst) begin
  enaDatar <= 33'b000000000000000010000000000000001;  // S - cycle
end
else begin
  if (stCycle2)
  enaDatar <= 33'b000000000000000010000000000000001;  // S - cycle
  else
    enaDatar <= {enaDatar[31:0],1'b0};
end
assign enaData = enaDatar[31];

always @(posedge clk33)
if (rst) begin
  enaSDatar <= 33'b000000000010000000001000001000001;  // S - cycle
end
else begin
  if (stCycle2)
    enaSDatar <= 33'b000000000010000000001000001000001;  // S - cycle
  else
    enaSDatar <= {enaSDatar[31:0],1'b0};
end
assign enaSData = enaSDatar[32];
wire enaMCnt = enaSDatar[31];

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
  VIC_CHAR,VIC_G:
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
// The cycles are synchornized to the raster timing.
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
  preRasterY <= 9'd0;
  preRasterX <= 11'd0;
  rasterX <= 10'd0;
  rasterY <= 9'd0;
  nextRasterY <= 9'd0;
end
else begin
  if (clken8) begin
    if (preRasterX==10'h14) begin
      rasterX <= 10'h0;
      rasterY <= preRasterY;
    end
    else
      rasterX <= rasterX + 10'd1;
    if (rasterX==10'd0) begin
      nextRasterY <= rasterY + 9'd1;
    end
    if (preRasterX==rasterXMax) begin
      preRasterX <= 11'd0;
      if (preRasterY==rasterYMax)
        preRasterY <= 9'd0;
      else
        preRasterY <= preRasterY + 9'd1;
    end
    else
      preRasterX <= preRasterX + 11'd1;
  end  
end

//------------------------------------------------------------------------------
// Decode cycles
//------------------------------------------------------------------------------

wire [10:0] rasterX2 = {preRasterX,1'b0};
always @(chip,rasterX2)
casex(rasterX2)
11'h00x: vicCycle <= VIC_REF;
11'h01x: vicCycle <= VIC_REF;
11'h02x: vicCycle <= VIC_REF;
11'h03x: vicCycle <= VIC_REF;
11'h04x: vicCycle <= VIC_RC;
11'h05x: vicCycle <= VIC_CHAR;
11'h06x: vicCycle <= VIC_CHAR;
11'h07x: vicCycle <= VIC_CHAR;
11'h08x: vicCycle <= VIC_CHAR;
11'h09x: vicCycle <= VIC_CHAR;
11'h0Ax: vicCycle <= VIC_CHAR;
11'h0Bx: vicCycle <= VIC_CHAR;
11'h0Cx: vicCycle <= VIC_CHAR;
11'h0Dx: vicCycle <= VIC_CHAR;
11'h0Ex: vicCycle <= VIC_CHAR;
11'h0Fx: vicCycle <= VIC_CHAR;
11'h10x: vicCycle <= VIC_CHAR;
11'h11x: vicCycle <= VIC_CHAR;
11'h12x: vicCycle <= VIC_CHAR;
11'h13x: vicCycle <= VIC_CHAR;
11'h14x: vicCycle <= VIC_CHAR;
11'h15x: vicCycle <= VIC_CHAR;
11'h16x: vicCycle <= VIC_CHAR;
11'h17x: vicCycle <= VIC_CHAR;
11'h18x: vicCycle <= VIC_CHAR;
11'h19x: vicCycle <= VIC_CHAR;
11'h1Ax: vicCycle <= VIC_CHAR;
11'h1Bx: vicCycle <= VIC_CHAR;
11'h1Cx: vicCycle <= VIC_CHAR;
11'h1Dx: vicCycle <= VIC_CHAR;
11'h1Ex: vicCycle <= VIC_CHAR;
11'h1Fx: vicCycle <= VIC_CHAR;
11'h20x: vicCycle <= VIC_CHAR;
11'h21x: vicCycle <= VIC_CHAR;
11'h22x: vicCycle <= VIC_CHAR;
11'h23x: vicCycle <= VIC_CHAR;
11'h24x: vicCycle <= VIC_CHAR;
11'h25x: vicCycle <= VIC_CHAR;
11'h26x: vicCycle <= VIC_CHAR;
11'h27x: vicCycle <= VIC_CHAR;
11'h28x: vicCycle <= VIC_CHAR;
11'h29x: vicCycle <= VIC_CHAR;
11'h2Ax: vicCycle <= VIC_CHAR;
11'h2Bx: vicCycle <= VIC_G;
11'h2Cx: vicCycle <= VIC_IDLE;
11'h2Dx: vicCycle <= VIC_IDLE;
11'h2Ex:
        case(chip)
        CHIP6567R8:   vicCycle <= VIC_IDLE;
        CHIP6567OLD:  vicCycle <= VIC_IDLE;
        default:      vicCycle <= VIC_SPRITE;
        endcase
11'h2Fx:
        case(chip)
        CHIP6567R8:   vicCycle <= VIC_IDLE;
        CHIP6567OLD:  vicCycle <= VIC_SPRITE;
        default:      vicCycle <= VIC_SPRITE;
        endcase
11'h30x:  vicCycle <= VIC_SPRITE;
11'h31x:  vicCycle <= VIC_SPRITE;
11'h32x:  vicCycle <= VIC_SPRITE;
11'h33x:  vicCycle <= VIC_SPRITE;
11'h34x:  vicCycle <= VIC_SPRITE;
11'h35x:  vicCycle <= VIC_SPRITE;
11'h36x:  vicCycle <= VIC_SPRITE;
11'h37x:  vicCycle <= VIC_SPRITE;
11'h38x:  vicCycle <= VIC_SPRITE;
11'h39x:  vicCycle <= VIC_SPRITE;
11'h3Ax:  vicCycle <= VIC_SPRITE;
11'h3Bx:  vicCycle <= VIC_SPRITE;
11'h3Cx:  vicCycle <= VIC_SPRITE;
11'h3Dx:  vicCycle <= VIC_SPRITE;
11'h3Ex:
        case(chip)
        CHIP6567R8:   vicCycle <= VIC_SPRITE;
        CHIP6567OLD:  vicCycle <= VIC_SPRITE;
        default:      vicCycle <= VIC_REF;
        endcase
11'h3Fx:
        case(chip)
        CHIP6567R8:   vicCycle <= VIC_SPRITE;
        CHIP6567OLD:  vicCycle <= VIC_REF;
        default:      vicCycle <= VIC_REF;
        endcase
11'h40x:  vicCycle <= VIC_REF;
default:  vicCycle <= VIC_IDLE;
endcase

reg [7:0] sprite1;
reg [3:0] sprite2,sprite3,sprite4,sprite5;
reg [10:0] rasterX3;

always @(posedge clk33)
begin
  if (clken8) begin
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

wire balo = |balos | (badline && rasterX2 < 11'h2C0);

always @(posedge clk33)
if (rst) begin
  ba <= 1'b1;
end
else begin
  if (stCycle2)
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
  ba1 <= `TRUE;
  ba2 <= `TRUE;
  ba3 <= `TRUE;
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
    nextChar <= db;
  else
    nextChar <= charbuf[38];
  for (n = 38; n > 0; n = n -1)
    charbuf[n] = charbuf[n-1];
  charbuf[0] <= nextChar;
end

always @(posedge clk33)
if (phi02==`LOW && enaData) begin
  if (vicCycle==VIC_CHAR || vicCycle==VIC_G) begin
    readPixels <= db[7:0];
    readChar <= nextChar;
  end
  waitingPixels <= readPixels;
  waitingChar <= readChar;
end

always @(posedge clk33)
if (phis==`LOW && enaSData==1'b1 && busCycle==BUS_SPRITE) begin
  if (MActive[sprite])
    MPtr[sprite] <= db[7:0];
  else
    MPtr[sprite] <= 8'd255;
end

//------------------------------------------------------------------------------
// Video matrix counter
//------------------------------------------------------------------------------
reg [9:0] vmndxStart;

always @(posedge clk33)
if (rst) begin
  vmndx <= 10'd0;
  vmndxStart <= 10'd0;
end
else begin
  if (phi02 && enaData) begin
    if (rasterY==rasterYMax)
      vmndx <= 10'd0;
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
    if (rasterX2[10:4]==7'h2C)
      scanline <= scanline + 3'd1;
  end
end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
always @*
  for (n = 0; n < 16; n = n + 1)
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
  if (ad[5:0]==6'h1E && regpg && phi02 && aec && cs && enaData) begin
    m2m[15:8] <= 8'h0;
  end
  if (ad[5:0]==6'h1E && !regpg && phi02 && aec && cs && enaData) begin
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
  if (ad[5:0]==6'h1F && regpg && phi02 && aec && cs && enaData) begin
    m2d[15:8] <= 8'h0;
  end
  if (ad[5:0]==6'h1F && !regpg && phi02 && aec && cs && enaData) begin
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
  if (rasterX2==11'h2B0) begin
    for (n = 0; n < MIBCNT; n = n + 1) begin
      if (!MActive[n] && me[n] && nextRasterY == my[n])
        MCnt[n] <= 6'd0;
    end    
  end

  // Reset expansion flipflop once sprite becomes deactivated or
  // if no sprite Y expansion.
  for (n = 0; n < MIBCNT; n = n + 1) begin
    if (!mye[n] || !MActive[n])
      mye_ff[n] <= 1'b0;
  end
  
  // If Y expansion is on, backup the MIB data counter by three every
  // other scanline.
  if (enaData && ref5 && !phi02) begin
    for (n = 0; n < MIBCNT; n = n + 1) begin
      if (MActive[n] & mye[n]) begin
        mye_ff[n] <= !mye_ff[n];
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
    if (phis && enaMCnt && vicCycle==VIC_SPRITE) begin
      if (MActive[sprite])
        MCnt[sprite] <= MCnt[sprite] + 6'd1;
    end
  end
end

always @(posedge clk33)
begin
  if (clken8) begin
    for (n = 0; n < MIBCNT; n = n + 1) begin
      if (MShift[n]) begin
        mxe_ff[n] <= !mxe_ff[n] & mxe[n];
        if (!mxe_ff[n]) begin
          mc_ff[n] <= !mc_ff[n] & mc[n];
          if (!mc_ff[n])
            MCurrentPixel[n] <= MPixels[n][23:22];
          MPixels[n] <= {MPixels[n][22:0],1'b0};
        end
      end
      else begin
        mxe_ff[n] <= 1'b0;
        mc_ff[n] <= 1'b0;
        MCurrentPixel[n] <= 2'b00;
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
    if (phis==`HIGH && enaSData && vicCycle==VIC_SPRITE) begin
      if (MActive[sprite])
        MPixels[sprite] <= {MPixels[sprite][15:0],db[7:0]};
    end
  end
end

//------------------------------------------------------------------------------
// Address Generation
//------------------------------------------------------------------------------

always @*
begin
  case(vicCycle)
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
          addr <= {cb[13],vmndx,scanline};
        else
          addr <= {cb[13:11],nextChar[7:0],scanline};
        if (ecm)
          addr[10:9] <= 2'b00;
      end
    end
  VIC_SPRITE:
    if (leg) begin
      if (phi02==`LOW && sprite1[4])
        addr <= {vm,7'b1111111,sprite[2:0]};
      else
        addr <= {MPtr[sprite],MCnt[sprite]};
    end
    else begin
      if (phis)
        addr <= {MPtr[sprite],MCnt[sprite]};
      else
        addr <= {vm,6'b111111,~sprite[3],sprite[2:0]};
    end
  default: addr <= 14'h3FFF;
  endcase
end

always @(posedge clk33)
  vicAddr <= addr;

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
    if (rasterY >= 13 && rasterY <= 40)
      vVicBlank <= `TRUE;
  CHIP6569,CHIP6572:
    if (rasterY >= 300 || rasterY < 15)
      vVicBlank <= `TRUE;
  endcase
end

always @(posedge clk33)
begin
  case (vicCycle)
  VIC_SPRITE:
    if (leg ? sprite>=3 : sprite>=6)
      hVicBlank <= `TRUE;
  default:
    hVicBlank <= `FALSE;
  endcase
end

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
      if (rasterX >= 25 && rasterX <= 345)
        hVicBorder <= `FALSE;
    end
    else begin
      if (rasterX >= 32 && rasterX <= 336)
        hVicBorder <= `FALSE;
    end
  end
end


//------------------------------------------------------------------------------
// Graphics mode pixel calc.
//------------------------------------------------------------------------------
reg ismc;
reg [11:0] shiftingChar,waitingChar,readChar;
reg [7:0] shiftingPixels,waitingPixels,readPixels;

always @(posedge clk33)
begin
  if (clken8) begin
    mc_ff <= !mc_ff;
    ismc = mcm & (bmm | ecm | shiftingChar[11]);
    if (xscroll==rasterX[2:0]) begin
      mc_ff <= 1'b0;
      shiftingChar <= waitingChar;
      shiftingPixels <= waitingPixels;
    end
    else if (!ismc)
      shiftingPixels <= {shiftingPixels[6:0],1'b0};
    else if (mc_ff)
      shiftingPixels <= {shiftingPixels[5:0],2'b0};
    pixelBgFlag <= shiftingPixels[7];
    pixelColor <= 4'h0; // black
    case({ecm,bmm,mcm})
    3'b000:
        pixelColor <= shiftingPixels[7] ? shiftingChar[11:8] : b0c;
    3'b001:
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
begin
  if (clken8) begin
    if (vicBorder)
      color8 <= ec;
    else
      color8 <= color_code;
  end
end

//------------------------------------------------------------------------------
// Register Interface
//
// VIC-II offers register feedback on all registers.
//------------------------------------------------------------------------------

always @(posedge clk33)
if (rst) begin
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
  yscroll <= 3'd0;
  den = `TRUE;
  me <= 16'h0;
  for (n = 0; n < MIBCNT; n = n + 1) begin
    mx[n] = 9'd200;
    my[n] = 8'd5;
  end
end
else begin
  if (phi02 && cs_n==`LOW) begin
    dbo8 <= 8'hFF;
    case(ad[5:0])
    6'h00:  dbo8 <= mx[{regpg,3'd0}][7:0];
    6'h01:  dbo8 <= my[{regpg,3'd0}];
    6'h02:  dbo8 <= mx[{regpg,3'd1}][7:0];
    6'h03:  dbo8 <= my[{regpg,3'd1}];
    6'h04:  dbo8 <= mx[{regpg,3'd2}][7:0];
    6'h05:  dbo8 <= my[{regpg,3'd2}];
    6'h06:  dbo8 <= mx[{regpg,3'd3}][7:0];
    6'h07:  dbo8 <= my[{regpg,3'd3}];
    6'h08:  dbo8 <= mx[{regpg,3'd4}][7:0];
    6'h09:  dbo8 <= my[{regpg,3'd4}];
    6'h0A:  dbo8 <= mx[{regpg,3'd5}][7:0];
    6'h0B:  dbo8 <= my[{regpg,3'd5}];
    6'h0C:  dbo8 <= mx[{regpg,3'd6}][7:0];
    6'h0D:  dbo8 <= my[{regpg,3'd6}];
    6'h0E:  dbo8 <= mx[{regpg,3'd7}][7:0];
    6'h0F:  dbo8 <= my[{regpg,3'd7}];
    6'h10:  begin
        dbo8[0] <= mx[{regpg,3'd0}][8];
        dbo8[1] <= mx[{regpg,3'd1}][8];
        dbo8[2] <= mx[{regpg,3'd2}][8];
        dbo8[3] <= mx[{regpg,3'd3}][8];
        dbo8[4] <= mx[{regpg,3'd4}][8];
        dbo8[5] <= mx[{regpg,3'd5}][8];
        dbo8[6] <= mx[{regpg,3'd6}][8];
        dbo8[7] <= mx[{regpg,3'd7}][8];
        end
    6'h11:  begin
            dbo8[2:0] <= yscroll;
            dbo8[3] <= rsel;
            dbo8[4] <= den;
            dbo8[5] <= bmm;
            dbo8[6] <= ecm;
            end
    6'h12:  dbo8 <= rasterY[7:0];
    6'h13:  dbo8 <= lpx;
    6'h14:  dbo8 <= lpy;
    6'h15:  case(regpg)
            1'd0: dbo8 <= me[7:0];
            1'd1: dbo8 <= me[15:8];
            endcase
    6'h16:  dbo8 <= {2'b11,res,mcm,csel,xscroll};
    6'h17:  case(regpg)
            1'd0: dbo8 <= mye[7:0];
            1'd1: dbo8 <= mye[15:8];
            endcase
    6'h18:  begin
            dbo8[0] <= 1'b1;
            dbo8[3:1] <= cb[13:11];
            dbo8[7:4] <= vm[13:10];
            end
    6'h19:  dbo8 <= {irq,3'b111,ilp,immc,imbc,irst};
    6'h1A:  dbo8 <= {4'b1111,elp,emmc,embc,erst};
    6'h1B:  dbo8 <= mdp;
    6'h1C:  begin  
            case(regpg)
            1'd0: dbo8 <= mmc[7:0];
            1'd1: dbo8 <= mmc[15:8];
            end
    6'h1D:  case(regpg)
            1'd0: dbo8 <= mxe[7:0];
            1'd1: dbo8 <= mxe[15:8];
            endcase
    6'h1E:  case(regpg)
            1'd0: dbo8 <= m2m[7:0];
            1'd1: dbo8 <= m2m[15:8];
            endcase
    6'h1F:  case(regpg)
            1'd0: dbo8 <= m2d[7:0];
            1'd1: dbo8 <= m2d[15:0];
            endcase
    6'h20:  dbo8[3:0] <= ec;
    6'h21:  dbo8[3:0] <= b0c;
    6'h22:  dbo8[3:0] <= b1c;
    6'h23:  dbo8[3:0] <= b2c;
    6'h24:  dbo8[3:0] <= b3c;
    6'h25:  dbo8[3:0] <= mm0;
    6'h26:  dbo8[3:0] <= mm1;
    6'h27:  dbo8[3:0] <= mc[{regpg,3'd0}];
    6'h28:  dbo8[3:0] <= mc[{regpg,3'd1}];
    6'h29:  dbo8[3:0] <= mc[{regpg,3'd2}];
    6'h2A:  dbo8[3:0] <= mc[{regpg,3'd3}];
    6'h2B:  dbo8[3:0] <= mc[{regpg,3'd4}];
    6'h2C:  dbo8[3:0] <= mc[{regpg,3'd5}];
    6'h2D:  dbo8[3:0] <= mc[{regpg,3'd6}];
    6'h2E:  dbo8[3:0] <= mc[{regpg,3'd7}];
    6'h32:  dbo8 <= {leg,7'h7F};
    default:  dbo8 <= 8'hFF;
    endcase
  end
  if (phi2r[32] & ~phi2r[31]) begin // when phi02 transitions from high to low
    irst_clr <= `FALSE;
    imbc_clr <= `FALSE;
    immc_clr <= `FALSE;
    ilp_clr <= `FALSE;
    if (cs_n==`LOW) begin
      if (wr) begin
        case(ad[5:0])
        6'h00:  mx[{regpg,3'd0}][7:0] <= db;
        6'h01:  my[{regpg,3'd0}] <= db;
        6'h02:  mx[{regpg,3'd1}][7:0] <= db;
        6'h03:  my[{regpg,3'd1}] <= db;
        6'h04:  mx[{regpg,3'd2}][7:0] <= db;
        6'h05:  my[{regpg,3'd2}] <= db;
        6'h06:  mx[{regpg,3'd3}][7:0] <= db;
        6'h07:  my[{regpg,3'd3}] <= db;
        6'h08:  mx[{regpg,3'd4}][7:0] <= db;
        6'h09:  my[{regpg,3'd4}] <= db;
        6'h0A:  mx[{regpg,3'd5}][7:0] <= db;
        6'h0B:  my[{regpg,3'd5}] <= db;
        6'h0C:  mx[{regpg,3'd6}][7:0] <= db;
        6'h0D:  my[{regpg,3'd6}] <= db;
        6'h0E:  mx[{regpg,3'd7}][7:0] <= db;
        6'h0F:  my[{regpg,3'd7}] <= db;
        6'h10:  begin
                mx[{regpg,3'd0}][8] <= db[0];
                mx[{regpg,3'd1}][8] <= db[1];
                mx[{regpg,3'd2}][8] <= db[2];
                mx[{regpg,3'd3}][8] <= db[3];
                mx[{regpg,3'd4}][8] <= db[4];
                mx[{regpg,3'd5}][8] <= db[5];
                mx[{regpg,3'd6}][8] <= db[6];
                mx[{regpg,3'd7}][8] <= db[7];
                end
        6'h11:  begin
                yscroll <= db[2:0];
                rsel <= db[3];
                den <= db[4];
                bmm <= db[5];
                ecm <= db[6];
                rasterCmp[8] <= db[7];
                end
        6'h12:  rasterCmp[7:0] <= db;
        6'h13:  ; // light pen x
        6'h14:  ; // light pen y
        6'h15:  case(regpg)
                1'd0: me[7:0] <= db;
                1'd1: me[15:8] <= db;
                endcase
        6'h16:  begin
                xscroll <= db[2:0];
                csel <= db[3];
                mcm <= db[4];
                res <= db[5];
                end  
        6'h17:  case(regpg)
                1'd0: mye[7:0] <= db;
                1'd1: mye[15:8] <= db;
                endcase
        6'h18:  begin
                cb[13:11] <= db[3:1];
                vm[13:10] <= db[7:4];
                end
        6'h19:  begin
                irst_clr <= db[0];
                imbc_clr <= db[1];
                immc_clr <= db[2];
                ilp_clr <= db[3];
                irq_clr <= db[7];
                end
        6'h1A:  begin
                erst <= db[0];
                embc <= db[1];
                emmc <= db[2];
                elp <= db[3];
                end
        6'h1B:  mdp <= db;
        6'h1C:  begin
                case(regpg)
                1'd0: mmc[7:0] <= db;
                1'd1: mmc[15:8] <= db;
                endcase
        6'h1D:  case(regpg)
                1'd0: mxe[7:0] <= db;
                1'd1: mxe[15:8] <= db;
                endcase
        6'h1E:  ; // mm collision
        6'h1F:  ; // md collision
        6'h20:  ec <= db[3:0];  // exterior (border color)
        6'h21:  b0c <= db[3:0]; // background color #0
        6'h22:  b1c <= db[3:0];
        6'h23:  b2c <= db[3:0];
        6'h24:  b3c <= db[3:0];
        6'h25:  mm0 <= db[3:0];
        6'h26:  mm1 <= db[3:0];
        6'h27:  mc[{regpg,3'd0}] <= db[3:0];
        6'h28:  mc[{regpg,3'd1}] <= db[3:0];
        6'h29:  mc[{regpg,3'd2}] <= db[3:0];
        6'h2A:  mc[{regpg,3'd3}] <= db[3:0];
        6'h2B:  mc[{regpg,3'd4}] <= db[3:0];
        6'h2C:  mc[{regpg,3'd5}] <= db[3:0];
        6'h2D:  mc[{regpg,3'd6}] <= db[3:0];
        6'h2E:  mc[{regpg,3'd7}] <= db[3:0];

        6'h30:  regno <= db[5:0];
        6'h32:  begin
                regpg <= db[0];
                leg <= db[7];
                end
        6'h31:
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

always @(posedge clk33)
    blank <= #1 hBlank|vBlank;
always @(posedge clk33)
    border <= #1 hBorder|vBorder;
always @(posedge clk33)
	hSync <= #1 hSync1;
always @(posedge clk33)
	vSync <= #1 vSync1;

wire [23:0] color24;

FAL6567_ColorROM u6
(
  .clk(clk33),
  .ce(1'b1),
  .code(color33),
  .color(color24)
);
assign red = color24[23:22];
assign green = color24[15:14];
assign blue = color24[7:6];

endmodule

