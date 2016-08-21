// ============================================================================
// (C) 2016 Robert Finch
// rob<remove>@finitron.ca
// All Rights Reserved.
//
//	FT6567.v
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

module FT6567(clk100, phi02, rst_o, irq, cs_n, vda, rw, ad, db,
  ram_ce, ram_we, ram_oe, ram_ad, ram_db, lp_n,
  hSync, vSync, red, green, blue);
parameter MIBCNT = 16;

// Constants for 25.0MHz clock
parameter phSyncOn  = 16;		//   16 front porch
parameter phSyncOff = 112;		//   96 sync
parameter phBlankOff = 160;		//   48 back porch
parameter phBorderOff = 160;	//    4 border
parameter phBorderOn = 800;		//  640 display
parameter phBlankOn = 800;		//    4 border
parameter phTotal = 800;		//  800 total clocks
parameter phSyncPol = 1;
// 47.7 = 60 * 795 kHz
parameter pvSyncOn  = 10;		//   10 front porch
parameter pvSyncOff = 12;		//    2 vertical sync
parameter pvBlankOff = 45;		//   33 back porch
parameter pvBorderOff = 45;		//    2 border	0
parameter pvBorderOn = 525;		//  480 display
parameter pvBlankOn = 525;  	//    1 border	0
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
parameter VIC_SL = 1;     // sprite pointer low fetch
parameter VIC_SH = 2;     // sprite pointer high fetch
parameter VIC_S1 = 3;     // sprite data fetch 1
parameter VIC_S2 = 4;     // sprite data fetch 2
parameter VIC_S3 = 5;     // sprite data fetch 3
parameter VIC_S4 = 6;     // sprite data fetch 4
parameter VIC_S5 = 7;     // sprite data fetch 5
parameter VIC_S6 = 8;     // sprite data fetch 6
parameter VIC_CF = 9;     // character pointer fetch
parameter VIC_CB = 10;    // character bitmap fetch
parameter VIC_LB = 11;    // linear bitmap mode access

input clk100;
output phi02;
output rst_o;
output irq;
input cs_n;
input vda;
input rw;
input [15:0] ad;
inout tri [7:0] db;
output reg ram_ce;
output reg ram_we;
output reg ram_oe;
output reg [18:0] ram_ad;
inout [7:0] ram_db;
input lp_n;
output reg hSync, vSync;	// sync outputs
output [1:0] red;
output [1:0] green;
output [1:0] blue;

integer n;
reg [23:0] adr;
wire cs = !cs_n;

wire clk12, clk25, clk50, clk100b;
reg [7:0] regShadow [127:0];

reg [7:0] p;
reg [5:0] pixelColor;
reg [5:0] color;
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

wire badline;                   // flag bad line condition
reg den;                        // display enable
reg rsel, bmm, ecm;
reg csel, mcm, res;
reg [2:0] mode;
reg [2:0] charsel;
reg [18:0] bmmadr;               // bits 15 to 18 of bitmap address
reg [11:0] rasterCmp;
reg [2:0] yscroll;
reg [2:0] xscroll;
reg [11:0] lpx, lpy;

// color regs
reg [3:0] ec;
reg [3:0] mm0,mm1;
reg [3:0] b0c,b1c,b2c,b3c;

reg [3:0] vicCycleNext,vicCycle;  // cycle the VIC state machine is in
reg [2:0] busCycle;              // BUS cycle type

reg pixelBgFlag;

// Character mode vars
reg [18:0] vmndx;                  // video matrix index
reg [15:0] nextChar;
reg [15:0] charbuf [78:0];
reg [2:0] scanline;

reg [3:0] sprite;
reg [MIBCNT-1:0] MActive;
reg [MIBCNT-1:0] MPtr [15:0];
reg [7:0] MCnt [0:MIBCNT-1];
reg [11:0] mx [0:MIBCNT-1];
reg [11:0] my [0:MIBCNT-1];
reg [5:0] mc [0:MIBCNT-1];
reg [MIBCNT-1:0] mmc;
reg [MIBCNT-1:0] me;
reg [MIBCNT-1:0] mye, mye_ff;
reg [MIBCNT-1:0] mxe, mxe_ff;
reg [MIBCNT-1:0] mdp;
reg [MIBCNT-1:0] mc_ff;
reg [MIBCNT-1:0] MShift;
reg [47:0] MPixels [MIBCNT-1:0];
reg [1:0] MCurrentPixel [MIBCNT-1:0];
reg [MIBCNT-1:0] m2m, m2d;
reg m2mhit, m2dhit;
reg [18:0] cb;
reg [18:0] vm;
reg [23:0] bma;
reg [23:0] vra;     // address of video ram - only bits [23:19] tested
reg [23:0] cra;
reg [23:0] chra;
reg vre, cre,chre;
reg [7:0] dbo8;
reg [18:0] vicAddr;

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

reg [21:0] rstcntr;
wire xrst = SIM ? !rstcntr[3] : !rstcntr[21];
always @(posedge clk25)
if (xrst)
  rstcntr <= rstcntr + 4'd1;

reg phi02d;
always @(posedge clk100b)
  phi02d <= phi02;

FT6567_clkgen u1
(
  .rst(xrst),
  .xclk(clk100),
  .clk12(clk12),
  .clk25(clk25),
  .clk50(clk50),
  .clk100b(clk100b),
  .locked(locked)
);

assign phi02 = clk12;
wire rst = !locked;
assign rst_o = rst;

// Latch address including bank from databus.
always @(posedge phi02)
  adr <= {db,ad};

reg [7:0] ram_dbl;
wire [7:0] chro0, chro1, cro0, cro1;
wire vra_cs = vda && vre && adr[23:19]==vra[23:19];
wire chr_cs = vda && che && adr[23:14]==chra[23:14];
wire cr_cs = vda && cre && adr[23:12]==cra[23:12];

assign db = (cs && rw && phi02) ? dbo8 : 8'bz;
assign db = (chr_cs && rw && phi02) ? chro0 : 8'bz;   
assign db = (cr_cs && rw && phi02) ? cro0 : 8'bz;   

assign dotclk = clk25;

FT6567Charram uchram
(
  .wclk(clk25),
  .wr(che && adr[23:14]==chra[23:14] && !rw && phi02d),
  .wa(adr[13:0]),
  .d(db),
  .rclk(~clk25),
  .ra0(adr[13:0]),
  .o0(chro0),
  .ra1(vicAddr[13:0]),
  .o1(chro1)
);

FT6567ColorRam uclrram
(
  .wclk(clk25),
  .wr(cre && adr[23:12]==cra[23:12] && !rw && phi02d),
  .wa(adr[11:0]),
  .d(db),
  .rclk(~clk25),
  .ra0(adr[11:0]),
  .o0(cro0),
  .ra1(vicAddr[11:0]),
  .o1(cro1)
);

//------------------------------------------------------------------------------
// Decode cycles
//------------------------------------------------------------------------------

wire [9:0] hCtr1 = hCtr - 10'd1;
always @(posedge clk25)
begin
  vicCycle <= VIC_IDLE;
  case(hCtr1)
  10'b000xxxx000: vicCycle <= VIC_SL; // sprite pointer fetch low
  10'b000xxxx001: vicCycle <= VIC_SH; // sprite pointer fetch high
  10'b000xxxx010: vicCycle <= VIC_S1; // sprite image data fetch
  10'b000xxxx011: vicCycle <= VIC_S2;
  10'b000xxxx100: vicCycle <= VIC_S3;
  10'b000xxxx101: vicCycle <= VIC_S4;
  10'b000xxxx110: vicCycle <= VIC_S5;
  10'b000xxxx111: vicCycle <= VIC_S6;
  default:
    if (hCtr1 >= 10'd152 && hCtr1 <= 10'd792) begin
      if (mode==3'b111)
        vicCycle <= VIC_LB;
      else begin
        if (hCtr1[2:0]==3'b000)
          vicCycle <= VIC_CF;
        else if (hCtr1[2:0]==3'b001)
          vicCycle <= VIC_CB;
      end
    end 
  endcase
end

always @(posedge clk25)
  sprite <= hCtr1[6:3];

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

assign badline = vCtr[2:0]==yscroll && den && (vCtr >= (SIM ? 10'd1 : 10'h85) && vCtr < 10'h485);

//------------------------------------------------------------------------------
// Databus loading
//------------------------------------------------------------------------------

always @(posedge clk50)
if (clk25) begin
  if (vicCycle==VIC_CF) begin
    if (badline)
      nextChar <= {cro1,ram_db};
    else
      nextChar <= charbuf[78];
    for (n = 78; n > 0; n = n -1)
      charbuf[n] = charbuf[n-1];
    charbuf[0] <= nextChar;
  end
end

always @(posedge clk50)
begin
  if (clk25) begin
    case(vicCycle)
    VIC_LB: readPixels <= ram_db;
    VIC_CF: readChar <= nextChar;
    VIC_CB: readPixels <= chro1;
    endcase
    waitingPixels <= readPixels;
    waitingChar <= readChar;
  end
end

always @(posedge clk50)
begin
  if (clk25) begin
    if (vicCycle==VIC_SL) begin
      if (MActive[sprite])
        MPtr[sprite][7:0] <= ram_db;
      else
        MPtr[sprite] <= 16'hFFFF;
    end
    else if (vicCycle==VIC_SH) begin
      if (MActive[sprite])
        MPtr[sprite][15:8] <= ram_db;
      else
        MPtr[sprite] <= 16'hFFFF;
    end
  end
end

//------------------------------------------------------------------------------
// Video matrix counter
//------------------------------------------------------------------------------
reg [18:0] vmndxStart;

always @(posedge clk25)
if (rst) begin
  vmndx <= 19'd0;
  vmndxStart <= 19'd0;
end
else begin
  begin
    if (vCtr==10'd0)
      vmndx <= 19'd0;
    if ((vicCycle==VIC_CF) && badline)
      vmndx <= vmndx + 1;
    else if (vicCycle==VIC_LB && !border)
      vmndx <= vmndx + 1;
    if (hCtr==hTotal && mode!=3'b111) begin
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

always @(posedge clk25)
if (rst) begin
  scanline <= 3'd0;
end
else begin
  begin
    if (hCtr==10'd0) begin
      if (badline)
        scanline <= 3'd0;
      else
        scanline <= scanline + 3'd1;
    end
  end
end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
always @*
  for (n = 0; n < MIBCNT; n = n + 1)
    MActive[n] <= MCnt[n] < 8'd252;

reg [MIBCNT-1:0] collision;
always @*
  for (n = 0; n < MIBCNT; n = n + 1)
    collision[n] = MCurrentPixel[n][1];

// Sprite-sprite collision logic
always @(posedge clk25)
if (rst)
  m2mhit <= `FALSE;
else begin
  if (immc_clr)
    immc <= `FALSE;
  if (adr[6:0]==7'h59 && clk12 && cs) begin
    m2m[15:8] <= 8'h0;
    m2mhit <= `FALSE;
  end
  if (adr[6:0]==6'h58 && clk12 && cs) begin
    m2m[7:0] <= 8'h0;
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
always @(posedge clk25)
if (rst)
  m2dhit <= `FALSE;
else begin
  if (imbc_clr)
    imbc <= `FALSE;
  if (adr[6:0]==7'h5B && phi02d && cs) begin
    m2d[15:8] <= 8'h0;
    m2dhit <= `FALSE;
  end
  if (adr[6:0]==6'h5A && phi02d && cs) begin
    m2d[7:0] <= 8'h0;
  end
  for (n = 0; n < MIBCNT; n = n + 1) begin
    if (collision[n] & pixelBgFlag & ~border) begin
      m2d[n] <= `TRUE;
      if (!m2dhit) begin
        m2dhit <= `TRUE;
        imbc <= `TRUE;
      end
    end
  end
end

always @(posedge clk25)
begin
  for (n = 0; n < MIBCNT; n = n + 1) begin
    if (hCtr == 10)
      MShift[n] <= `FALSE;
    else if (hCtr == mx[n])
      MShift[n] <= `TRUE;
  end
end

always @(posedge clk25)
if (rst & SIM) begin
  for (n = 0; n < MIBCNT; n = n + 1) begin
    MCnt[n] <= 8'd255;
  end
end
else begin
  // Trigger sprite accesses on the last character cycle
  // if the sprite Y coordinate will match.
  if (hCtr==10'h752) begin
    for (n = 0; n < MIBCNT; n = n + 1) begin
      if (!MActive[n] && me[n] && vCtr == my[n])
        MCnt[n] <= 8'd0;
    end    
  end

  // Reset expansion flipflop once sprite becomes deactivated or
  // if no sprite Y expansion.
  for (n = 0; n < MIBCNT; n = n + 1) begin
    if (!mye[n] || !MActive[n])
      mye_ff[n] <= 1'b0;
  end
  
  // If Y expansion is on, backup the MIB data counter by six every
  // other scanline.
  if (hCtr==10'd0) begin
    for (n = 0; n < MIBCNT; n = n + 1) begin
      if (MActive[n] & mye[n]) begin
        mye_ff[n] <= !mye_ff[n];
        if (!mye_ff[n])
          MCnt[n] <= MCnt[n] - 8'd6;
      end
    end  
  end

  if (vicCycle==VIC_S1 || vicCycle==VIC_S2 || vicCycle==VIC_S3 || vicCycle==VIC_S4 || vicCycle==VIC_S5 || vicCycle==VIC_S6) begin
    if (MActive[sprite])
      MCnt[sprite] <= MCnt[sprite] + 6'd1;
  end
end

always @(posedge clk50)
begin
  if (clk25) begin
    for (n = 0; n < MIBCNT; n = n + 1) begin
      if (MShift[n]) begin
        mxe_ff[n] <= !mxe_ff[n] & mxe[n];
        if (!mxe_ff[n]) begin
          mc_ff[n] <= !mc_ff[n] & mc[n];
          if (!mc_ff[n])
            MCurrentPixel[n] <= MPixels[n][47:46];
          MPixels[n] <= {MPixels[n][46:0],1'b0};
        end
      end
      else begin
        mxe_ff[n] <= 1'b0;
        mc_ff[n] <= 1'b0;
        MCurrentPixel[n] <= 2'b00;
      end
    end  
    if (vicCycle==VIC_S1 || vicCycle==VIC_S2 || vicCycle==VIC_S3 || vicCycle==VIC_S4 || vicCycle==VIC_S5 || vicCycle==VIC_S6) begin
      if (MActive[sprite])
        MPixels[sprite] <= {MPixels[sprite][39:0],ram_db};
    end
  end
end

//------------------------------------------------------------------------------
// video ram control
//
// The ram has an 8ns access time which is good because it allows sharing
// the ram between the cpu and the VIC on alternating clock cycles at high
// speed. The VIC needs access to the ram at a 25MHz rate. Using both phases
// of the clock allows 20ns for ram access. This is a fairly tight timing
// budget given that some ns is lost trasferring data through the FPGA.
//
// Note that reading the ram for the cpu is tricky because the ram is only
// accessed for 20 ns. The read back data has to be centred around the 
// falling edge of phi02. A minimum 10ns setup and hold time are required.
//------------------------------------------------------------------------------

// Register the ram control signals
always @(posedge clk100b)
begin
  ram_ad <= !clk25 ? adr : vicAddr;
  ram_ce <= !clk25 ? !vra_cs : !vre;
  ram_oe <= !clk25 ? !rw : 1'b0;
end

// The following clock logic centers a 10ns write pulse during the 20ns
// that the cpu has access to the ram.
always @(negedge clk100b)
  ram_we <= (!clk25 && clk12 && clk50) ? !(!rw && vra_cs) : 1'b1;

assign ram_db = (!clk25 && !rw) ? db : 8'bz;
assign db = (!clk25 && rw && vra_cs && phi02) ? ram_db : 8'bz;

//------------------------------------------------------------------------------
// Address Generation
//------------------------------------------------------------------------------

always @(posedge clk25)
begin
  case(vicCycle)
  VIC_CF: vicAddr <= vm + vmndx[11:0];
  VIC_CB: 
      begin
        if (bmm)
          vicAddr <= {bmmadr[18:15],vmndx[11:0],scanline};
        else
          vicAddr <= {charsel,nextChar[7:0],scanline};
      end
  VIC_LB: vicAddr <= {bmmadr[18],vmndx};
  VIC_SL: vicAddr <= {vm[18:12],7'b1111111,sprite,1'b0};
  VIC_SH: vicAddr <= {vm[18:12],7'b1111111,sprite,1'b1};
  VIC_S1,VIC_S2,VIC_S3,VIC_S4,VIC_S5,VIC_S6:
          vicAddr <= {MPtr[sprite],MCnt[sprite]};
  default: vicAddr <= 19'h7FFFF;
  endcase
end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
always @(posedge clk25)
	begin
			if (phi02d && vicCycle == VIC_SL && sprite == 2)
				rasterIRQDone <= `FALSE;
			if (irst_clr)
				irst <= 1'b0;
			if (rasterIRQDone == `FALSE && vCtr == rasterCmp) begin
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
always @(posedge clk25)
	begin
    if (ilp_clr)
      ilp <= `LOW;
    if (vCtr == 10'd0)
      lightPenHit <= `FALSE;
    else if (!lightPenHit && lp_n == `LOW) begin
      lightPenHit <= `TRUE; 
      ilp <= `HIGH; 
      lpx <= hCtr;
      lpy <= vCtr;
    end
  end

//------------------------------------------------------------------------------
// Graphics mode pixel calc.
//------------------------------------------------------------------------------
reg ismc;
reg [15:0] shiftingChar,waitingChar,readChar;
reg [7:0] shiftingPixels,waitingPixels,readPixels;

always @(posedge clk50)
begin
  if (clk25==`HIGH) begin
    mc_ff <= !mc_ff;
    ismc = mcm & (bmm | ecm | shiftingChar[15]);
    if (xscroll==hCtr[2:0]) begin
      mc_ff <= 1'b0;
      shiftingChar <= waitingChar;
      shiftingPixels <= waitingPixels;
    end
    else if (!ismc)
      shiftingPixels <= {shiftingPixels[6:0],1'b0};
    else if (mc_ff)
      shiftingPixels <= {shiftingPixels[5:0],2'b0};
    pixelBgFlag <= shiftingPixels[7];
    pixelColor <= 6'h0; // black
    case(mode)
    // Text mode
    3'b000:
        case({shiftingPixels[7],shiftingChar[15:14]})
        3'b000:  pixelColor <= b0c;
        3'b001:  pixelColor <= b1c;
        3'b010:  pixelColor <= b2c;
        3'b011:  pixelColor <= b3c;
        default:  pixelColor <= shiftingChar[13:8];
        endcase
    // Multi-color text mode
    3'b001:
        if (shiftingChar[15])
          case(shiftingPixels[7:6])
          2'b00:  pixelColor <= b0c;
          2'b01:  pixelColor <= b1c;
          2'b10:  pixelColor <= b2c;
          2'b11:  pixelColor <= shiftingChar[13:8];
          endcase
        else
          pixelColor <= shiftingPixels[7] ? shiftingChar[13:8] : b0c;
    // Low res bitmap mode
    3'b010,3'b110: 
        pixelColor <= shiftingPixels[7] ? shiftingChar[13:8] : shiftingChar[5:0];
      // Linear bitmap mode
      3'b111:
        begin   
          pixelColor <= ram_db[5:0];
          pixelBgFlag <= ram_db[7];
        end
    endcase
  end
end

//------------------------------------------------------------------------------
// Output color selection
//------------------------------------------------------------------------------

reg [5:0] color_code;

always @(posedge clk25)
begin
  // Force the output color to black for "illegal" modes
  case(mode)
  3'b101,3'b110:
    color_code <= 6'h0;
  default: color_code <= pixelColor;
  endcase
  // See if the mib overrides the output
  for (n = 0; n < MIBCNT; n = n + 1) begin
    if (!mdp[n] || !pixelBgFlag) begin
      if (mc[n]) begin  // multi-color mode ?
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

always @(posedge clk25)
begin
    if (border)
      color <= ec;
    else
      color <= color_code;
end

//------------------------------------------------------------------------------
// Register Interface
//
// VIC-II offers register feedback on all registers.
//------------------------------------------------------------------------------

always @(posedge clk25)
if (rst) begin
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
  mode <= 3'd0;
  vre <= 1'b0;
  cre <= 1'b0;
  chre <= 1'b0;
  vra[18:0] <= 19'd0;
  vm[11:0] <= 10'd0;
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
  if (phi02d) begin // when phi02 transitions from high to low
    irst_clr <= `FALSE;
    imbc_clr <= `FALSE;
    immc_clr <= `FALSE;
    ilp_clr <= `FALSE;
    if (cs_n==`LOW) begin
      if (wr) begin
        regShadow[adr[6:0]] <= db;
        case(adr[6:0])
        7'h00:  mx[4'd0][7:0] <= db;
        7'h01:  mx[4'd0][11:8] <= db[3:0];
        7'h02:  my[4'd0][7:0] <= db;
        7'h03:  my[4'd0][11:8] <= db[3:0];
        7'h04:  begin
                mc[4'd0] <= db[5:0];
                mmc[4'd0] <= db[7];
                end
        7'h05:  mx[4'd1][7:0] <= db;
        7'h06:  mx[4'd1][11:8] <= db[3:0];
        7'h07:  my[4'd1][7:0] <= db;
        7'h08:  my[4'd1][11:8] <= db[3:0];
        7'h09:  begin
                mc[4'd1] <= db[5:0];
                mmc[4'd1] <= db[7];
                end
        7'h0A:  mx[4'd2][7:0] <= db;
        7'h0B:  mx[4'd2][11:8] <= db[3:0];
        7'h0C:  my[4'd2][7:0] <= db;
        7'h0D:  my[4'd2][11:8] <= db[3:0];
        7'h0E:  begin
                mc[4'd2] <= db[5:0];
                mmc[4'd2] <= db[7];
                end
        7'h0F:  mx[4'd3][7:0] <= db;
        7'h10:  mx[4'd3][11:8] <= db[3:0];
        7'h11:  my[4'd3][7:0] <= db;
        7'h12:  my[4'd3][11:8] <= db[3:0];
        7'h13:  begin
                mc[4'd3] <= db[5:0];
                mmc[4'd3] <= db[7];
                end
        7'h14:  mx[4'd4][7:0] <= db;
        7'h15:  mx[4'd4][11:8] <= db[3:0];
        7'h16:  my[4'd4][7:0] <= db;
        7'h17:  my[4'd4][11:8] <= db[3:0];
        7'h18:  begin
                mc[4'd4] <= db[5:0];
                mmc[4'd4] <= db[7];
                end
        7'h19:  mx[4'd5][7:0] <= db;
        7'h1A:  mx[4'd5][11:8] <= db[3:0];
        7'h1B:  my[4'd5][7:0] <= db;
        7'h1C:  my[4'd5][11:8] <= db[3:0];
        7'h1D:  begin
                mc[4'd5] <= db[5:0];
                mmc[4'd5] <= db[7];
                end
        7'h1E:  mx[4'd6][7:0] <= db;
        7'h1F:  mx[4'd6][11:8] <= db[3:0];
        7'h20:  my[4'd6][7:0] <= db;
        7'h21:  my[4'd6][11:8] <= db[3:0];
        7'h22:  begin
                mc[4'd6] <= db[5:0];
                mmc[4'd6] <= db[7];
                end
        7'h23:  mx[4'd7][7:0] <= db;
        7'h24:  mx[4'd7][11:8] <= db[3:0];
        7'h25:  my[4'd7][7:0] <= db;
        7'h26:  my[4'd7][11:8] <= db[3:0];
        7'h27:  begin
                mc[4'd7] <= db[5:0];
                mmc[4'd7] <= db[7];
                end
        7'h28:  mx[4'd8][7:0] <= db;
        7'h29:  mx[4'd8][11:8] <= db[3:0];
        7'h2A:  my[4'd8][7:0] <= db;
        7'h2B:  my[4'd8][11:8] <= db[3:0];
        7'h2C:  begin
                mc[4'd8] <= db[5:0];
                mmc[4'd8] <= db[7];
                end
        7'h2D:  mx[4'd9][7:0] <= db;
        7'h2E:  mx[4'd9][11:8] <= db[3:0];
        7'h2F:  my[4'd9][7:0] <= db;
        7'h30:  my[4'd9][11:8] <= db[3:0];
        7'h31:  begin
                mc[4'd9] <= db[5:0];
                mmc[4'd9] <= db[7];
                end
        7'h32:  mx[4'd10][7:0] <= db;
        7'h33:  mx[4'd10][11:8] <= db[3:0];
        7'h34:  my[4'd10][7:0] <= db;
        7'h35:  my[4'd10][11:8] <= db[3:0];
        7'h36:  begin
                mc[4'd10] <= db[5:0];
                mmc[4'd10] <= db[7];
                end
        7'h37:  mx[4'd11][7:0] <= db;
        7'h38:  mx[4'd11][11:8] <= db[3:0];
        7'h39:  my[4'd11][7:0] <= db;
        7'h3A:  my[4'd11][11:8] <= db[3:0];
        7'h3B:  begin
                mc[4'd11] <= db[5:0];
                mmc[4'd11] <= db[7];
                end
        7'h3C:  mx[4'd12][7:0] <= db;
        7'h3D:  mx[4'd12][11:8] <= db[3:0];
        7'h3E:  my[4'd12][7:0] <= db;
        7'h3F:  my[4'd12][11:8] <= db[3:0];
        7'h40:  begin
                mc[4'd12] <= db[5:0];
                mmc[4'd12] <= db[7];
                end
        7'h41:  mx[4'd13][7:0] <= db;
        7'h42:  mx[4'd13][11:8] <= db[3:0];
        7'h43:  my[4'd13][7:0] <= db;
        7'h44:  my[4'd13][11:8] <= db[3:0];
        7'h45:  begin
                mc[4'd13] <= db[5:0];
                mmc[4'd13] <= db[7];
                end
        7'h46:  mx[4'd14][7:0] <= db;
        7'h47:  mx[4'd14][11:8] <= db[3:0];
        7'h48:  my[4'd14][7:0] <= db;
        7'h49:  my[4'd14][11:8] <= db[3:0];
        7'h4A:  begin
                mc[4'd14] <= db[5:0];
                mmc[4'd14] <= db[7];
                end
        7'h4B:  mx[4'd14][7:0] <= db;
        7'h4C:  mx[4'd14][11:8] <= db[3:0];
        7'h4D:  my[4'd14][7:0] <= db;
        7'h4E:  my[4'd14][11:8] <= db[3:0];
        7'h4F:  begin
                mc[4'd14] <= db[5:0];
                mmc[4'd14] <= db[7];
                end
        7'h50:  me[7:0] <= db;
        7'h51:  me[15:8] <= db;
        7'h52:  mye[7:0] <= db;
        7'h53:  mye[15:8] <= db;
        7'h54:  mxe[7:0] <= db;
        7'h55:  mxe[15:8] <= db;
        7'h56:  mdp[7:0] <= db;
        7'h57:  mdp[15:8] <= db;
        7'h58:  ; //m2m
        7'h59:  ;
        7'h5A:  ; // m2d
        7'h5B:  ;
        7'h5C:  begin  
                yscroll <= db[2:0];
                rsel <= db[3];
                den <= db[4];
                mode <= db[7:5];
                bmm <= db[5];
                ecm <= db[6];
                end
        7'h5D:  begin
                xscroll <= db[2:0];
                csel <= db[3];
                charsel <= db[6:4];
                end
        7'h5E:  rasterCmp[7:0] <= db;
        7'h5F:  rasterCmp[11:8] <= db[3:0];
        7'h60:  ; // light pen x
        7'h61:  ;
        7'h62:  ; // light pen y
        7'h63:  ;
        7'h64:  vm[18:12] <= db[6:0];
        7'h65:  begin
                irst_clr <= db[0];
                imbc_clr <= db[1];
                immc_clr <= db[2];
                ilp_clr <= db[3];
                irq_clr <= db[7];
                end
        7'h66:  begin
                erst <= db[0];
                embc <= db[1];
                emmc <= db[2];
                elp <= db[3];
                end
        7'h67:  ec <= db[5:0];  // exterior (border color)
        7'h68:  b0c <= db[5:0]; // background color #0
        7'h69:  b1c <= db[5:0];
        7'h6A:  b2c <= db[5:0];
        7'h6B:  b3c <= db[5:0];
        7'h6C:  mm0 <= db[5:0];
        7'h6D:  mm1 <= db[5:0];
        7'h6E:  bmmadr[18:15] <= db[7:4];
        7'h6F:  begin
                vra[23:19] <= db[7:3];
                vre <= db[0];
                end
        7'h70:  begin
                cra[15:12] <= db[7:4];
                cre <= db[0];
                end
        7'h71:  cra[23:16] <= db;
        7'h72:  begin
                chra[15:14] <= db[7:6];
                chre <= db[0];
                end
        7'h73:  chra[23:16] <= db;
        default:  ;
        endcase
      end
    end
  end
end

reg [11:0] vCtrLatch;

// Use 4x clock to give 3/4 bus cycle data setup time
always @(posedge clk50)
begin
  if (phi02d && cs_n==`LOW) begin
    case(adr[6:0])
    7'h58:  dbo8 <= m2m[7:0];
    7'h59:  dbo8 <= m2m[15:8];
    7'h5A:  dbo8 <= m2d[7:0];
    7'h5B:  dbo8 <= m2d[15:8];
    7'h5E:  begin
            dbo8 <= vCtr[7:0];
            vCtrLatch <= vCtr;
            end
    7'h5F:  dbo8 <= vCtrLatch[11:8];
    7'h60:  dbo8 <= lpx[7:0];
    7'h61:  dbo8 <= lpx[11:8];
    7'h62:  dbo8 <= lpy[7:0];
    7'h63:  dbo8 <= lpy[11:8];
    7'h65:  dbo8 <= {irq,3'b111,ilp,immc,imbc,irst};
    default:  dbo8 <= regShadow[adr[6:0]];
    endcase 
  end
end

assign vSync1 = (vCtr >= vSyncOn && vCtr < vSyncOff) ^ vSyncPol;
assign hSync1 = (hCtr >= hSyncOn && hCtr < hSyncOff) ^ hSyncPol;
assign vBlank = vCtr >= vBlankOn || vCtr < vBlankOff;
assign hBlank = hCtr >= hBlankOn || hCtr < hBlankOff;
assign vBorder = vCtr >= vBorderOn || vCtr < vBorderOff;
assign hBorder = hCtr >= hBorderOn || hCtr < hBorderOff;

counter #(12) u4 (.rst(rst), .clk(clk25), .ce(1'b1), .ld(eol1), .d(12'd1), .q(hCtr) );
counter #(12) u5 (.rst(rst), .clk(clk25), .ce(eol1),  .ld(eof1), .d(12'd1), .q(vCtr) );

always @(posedge clk25)
    blank <= #1 hBlank|vBlank;
always @(posedge clk25)
    border <= #1 hBorder|vBorder;
always @(posedge clk25)
	hSync <= #1 hSync1;
always @(posedge clk25)
	vSync <= #1 vSync1;

wire [23:0] color24;

FAL6567_ColorROM u6
(
  .clk(clk25),
  .ce(1'b1),
  .code(color33),
  .color(color24)
);
assign red = color24[23:20];
assign green = color24[15:12];
assign blue = color24[7:4];

endmodule

