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
// An 800x480 display format is created for VGA using the 640x480 standard VGA
// timing. The dot clock is faster though at 31.5MHz. This allows a 640x400
// display area with a border to be created. This is double the horizontal and
// vertical resolution of the VIC-II. 
//
module FAL6567(chip, xrst, rst_n_o, clk100, clk8, phi02, aec, ba, cs_n, rw, ad, mad, db, ras_n, cas_n, hSync, vSync, red, green, blue);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;

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

parameter MIB0P  = 9'd58;
parameter MIB0S0 = 9'd59;
parameter MIB0S1 = 9'd60;
parameter MIB0S2 = 9'd61;
parameter MIB1P  = 9'd62;
parameter MIB1S0 = 9'd63;
parameter MIB1S1 = 9'd64;
parameter MIB1S2 = 9'd65;
parameter MIB2P  = 9'd1;
parameter MIB2S0 = 9'd2;
parameter MIB2S1 = 9'd3;
parameter MIB2S2 = 9'd4;
parameter MIB3P  = 9'd5;
parameter MIB3S0 = 9'd6;
parameter MIB3S1 = 9'd7;
parameter MIB3S2 = 9'd8;
parameter MIB4P  = 9'd8;
parameter MIB4S0 = 9'd10;
parameter MIB4S1 = 9'd11;
parameter MIB4S2 = 9'd12;
parameter MIB5P  = 9'd13;
parameter MIB5S0 = 9'd14;
parameter MIB5S1 = 9'd15;
parameter MIB5S2 = 9'd16;
parameter MIB6P  = 9'd17;
parameter MIB6S0 = 9'd18;
parameter MIB6S1 = 9'd19;
parameter MIB6S2 = 9'd20;
parameter MIB7P  = 9'd21;
parameter MIB7S0 = 9'd22;
parameter MIB7S1 = 9'd23;
parameter MIB7S2 = 9'd24;

parameter REFRSH1 = 9'd25;
parameter REFRSH2 = 9'd26;
parameter REFRSH3 = 9'd27;
parameter REFRSH4 = 9'd28;
parameter REFRSH5 = 9'd29;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

input [1:0] chip;
input xrst;
output rst_n_o;
input clk100;
input clk8;
output phi02;
output reg aec;
output reg ba;
input cs_n;
input rw;
inout [15:0] ad;
input [1:0] mad;          // multiplexed address a6,a7,a14,a15 from system
inout tri [11:0] db;
output ras_n;
output cas_n;
output reg hSync, vSync;	// sync outputs
output [3:0] red;
output [3:0] green;
output [3:0] blue;

integer n;
reg [7:0] sysram [0:65535];
reg [3:0] colorram [0:1023];
reg [13:0] ado;
reg [6:0] ado1;
reg [7:0] p;
wire vclk;
reg blank;			// blanking output
reg border;
wire vBlank, hBlank;
wire vBorder, hBorder;
wire hSync1,vSync1;
reg hSyncOn, hSyncOff;
reg vSyncOn, vSyncOff;
reg hBorderOn, hBorderOff;
reg hBlankOn, hBlankOff;
reg vBorderOn, vBorderOff;
reg vBlankOn, vBlankOff;
reg [11:0] hTotal;
reg [11:0] vTotal;
wire [11:0] vCtr, hCtr;
reg hSyncPol;
reg vSyncPol;
wire wr = !rw;
wire eol1 = hCtr==hTotal;
wire eof1 = vCtr==vTotal && eol1;

reg [8:0] state;
reg bct;  // bus cycle theft enable
reg den;
reg rsel, bmm, ecm;
reg csel, mcm, res;
reg [7:0] refcntr;
reg [7:0] phi02r;
reg [7:0] rasr;
reg [7:0] casr;
reg [7:0] hce;
reg [6:0] colCtr;
reg [10:0] rasterX;
reg [10:0] rasterXMax;
wire [10:0] rasterVX = hCtr[11:1];
wire [10:0] rasterVY = vCtr[11:1];
reg [8:0] rasterY;
reg [8:0] nextRasterY;
reg [8:0] rasterCmp;
reg [8:0] rasterYMax;
reg [8:0] nextRaster;
reg [2:0] yscroll;
reg [2:0] xscroll;
wire [7:0] selp;
wire [7:0] sels;
reg [MIBCNT-1:0] sprrst;
reg [MIBCNT-1:0] MActive;
reg [5:0] mcnt [0:MIBCNT-1];
reg [8:0] mx [0:MIBCNT-1];
reg [7:0] my [0:MIBCNT-1];
reg [MIBCNT-1:0] me;
reg [MIBCNT-1:0] mye;
reg [MIBCNT-1:0] mxe, mxe_ff;
reg [MIBCNT-1:0] mdp;
reg [MIBCNT-1:0] mc, mc_ff;
reg [MIBCNT-1:0] MShift;
reg [MIBCNT-1:0] MPixels[23:0];
reg [MIBCNT-1:0] MCurrentPixel[1:0];
reg [13:0] cb;
reg [13:0] vm;
reg [5:0] regno;
reg [2:0] regpg;
wire locked;
wire balo;

reg [4:0] wrhead,wrtail;
reg [15:0] writeadr [31:0];
reg [7:0] writebuf [31:0];

reg [7:0] idb;
reg [11:0] sysdati;
reg [15:0] sysadr, sysadri;

/*
reg [19:0] rstcntr;
wire xrst = !rstcntr[19];
always @(posedge clk8)
if (xrst)
  rstcntr <= rstcntr + 4'd1;
*/
FAL6567_clkgen u1
(
  .rst(xrst),
  .xclk(clk100),
  .clk33(vclk),
  .locked(locked)
);

wire rst = !locked;
assign rst_n_o = !rst;

// Set Limits
always @(chip)
case(chip)
CHIP6567R8:   begin rasterYMax = 9'd262; rasterXMax = {7'd65,3'b111}; end
CHIP6567OLD:  begin rasterYMax = 9'd261; rasterXMax = {7'd64,3'b111}; end
CHIP6569:     begin rasterYMax = 9'd311; rasterXMax = {7'd63,3'b111}; end
CHIP6572:     begin rasterYMax = 9'd311; rasterXMax = {7'd63,3'b111}; end
endcase

always @(posedge vclk)
if (rst)
  clken8 <= 4'b1000;
else
  clken8 <= {clken8[2:0],clken8[3]};

always @(posedge vclk)
if (rst)
  clk2r <= 16'b1000000000000000;
else
  clk2r <= {clk2r[14:0],clk2r[15]};
assign clken2 = clk2r[15];

always @(posedge vclk)
if (rst)
  clk1r <= 32'b10000000000000000000000000000000;
else
  clk1r <= {clk1r[30:0],clk1r[31]};
assign clken1 = clk1r[31];
assign clken1x = clk1r[15];

always @(posedge vclk)
if (rst)
  phi02r <= 32'b00000000000000001111111111111111;
else
  phi02r <= {phi02r[30:0],phi02r[31]};
assign phi02 = phi02r[31];

always @(posedge vclk)
if (rst)
  rasr <= 32'b11111100000000001111110000000000;
else
  rasr <= {rasr[30:0],rasr[31]};
assign ras_n = rasr[31];
  
always @(posedge vclk)
if (rst)
  muxr <= 32'b11111110000000001111111000000000;
else
  muxr <= {muxr[30:0],muxr[31]};
assign mux = muxr[31] & !(vicRefresh & phi02);
  
always @(posedge vclk)
if (rst)
  casr <= 32'b11111111100000001111111110000000;
else
  casr <= {casr[30:0],casr[31]};
assign cas_n = casr[31] | (vicRefresh & phi02);

//------------------------------------------------------------------------------
// Capture the system address and data
//------------------------------------------------------------------------------
reg wr_sys;
always @(posedge vclk)
begin
  if (aec) begin
    if (!rasr[31] && rasr[0])
      sysadri[15:8] <= {mad,ad[5:0]};
    if (!casr[31] && casr[0])
      sysadri[7:0] <= ad[7:0];
    if (phi02r[31] && !phi02r[30]) begin
      if (!rw) begin
        wrhead <= wrhead + 1;
        writeadr[wrhead] <= sysadri;
        writebuf[wrhead] <= db;
      end
    end
  end
end

//------------------------------------------------------------------------------
// Capture data being written to system memory.
//------------------------------------------------------------------------------
always @(posedge vclk)
if ((hCtr & 12'h1F)==12'd9) begin
  if (wr_sys) begin
    if (sysadr[15:10]==6'b110110) // D800-DBFF
      colorram[sysadr[9:0]] <= sysdati[3:0];
    else
      sysram[sysadr] <= sysdati[7:0];
  end
end

always @(posedge vclk)
  idb <= sysram[sysadr];

//------------------------------------------------------------------------------
// Raster / Refresh counters
//------------------------------------------------------------------------------
wire [6:0] cycle = rasterX[9:3];
wire AB = rasterX[2];
wire selref = cycle >= 7'd11 && cycle <= 7'd15 && !AB;
always @(posedge vclk)
if (rst) begin
  rasterX <= {7'd1,3'd0};
  rasterY <= 9'd0;
  nextRasterY <= 9'd0;
  refcntr <= 8'd255;
end
else begin
  if (clken8) begin
    if (rasterX==10'd88 || rasterX==10'd96 || rasterX==10'd104 || rasterX==10'd112 || rasterX==10'd120)
      refcntr <= refcntr - 8'd1;
    if (rasterX=={7'd1,3'd0})
      nextRasterY <= rasterY + 9'd1;
    if (rasterX==rasterXMax) begin
      rasterX <= {7'd1,3'd0};
      if (rasterY==rasterYMax)
        rasterY <= 9'd0;
      else
        rasterY <= rasterY + 9'd1;
    end
    else
      rasterX <= rasterX + 8'd1;
  end  
end

//------------------------------------------------------------------------------

wire vBorder = rsel ? rasterY < 9'd52 || rasterY > 9'd243 : rasterY < 9'd48 || rasterY > 9'd247;
wire vBorder1 = rasterY < 9'd47 || rasterY > 9'd247;
wire BadLine = rasterY[2:0]==yscroll && den && !vBorder1;

//------------------------------------------------------------------------------
// Sprite control
//------------------------------------------------------------------------------
always @(n,hCtr,MActive,rasterVY)
for (n = 0; n < MIBCNT; n = n + 1)
begin
  sprrst[n] <= !MActive[n] && my[n]==rasterVY && (hCtr=={n+1,3'd0});
  selp[n] <= (hCtr=={n+1,3'd0});
  sels[n] <= (hCtr=={n+1,3'd2}|hCtr=={n+1,3'd4}|hCtr=={n+1,3'd6});
end

//------------------------------------------------------------------------------
// BA - bus available
// Compute when to pull bus available low
// 3 clock cycles before a sprite access or
// during character pointer fetchs on badlines
//------------------------------------------------------------------------------
wire balo0 = ((my[0]==nextRasterY)||MActive[0]) && cycle>=8'd56 && cycle < 8'd61 && me[0];
wire balo1 = ((my[1]==nextRasterY)||MActive[1]) && cycle>=8'd58 && cycle < 8'd63 && me[1];
wire balo2 = ((my[2]==nextRasterY)||MActive[2]) && cycle>=8'd60 && cycle < 8'd65 && me[2];
wire balo3 = ((my[3]==nextRasterY)||MActive[3]) && (cycle>=8'd62 || cycle < 8'd01) && me[3];
wire balo4 = ((my[4]==nextRasterY)||MActive[4]) && (cycle>=8'd64 || cycle < 8'd03) && me[4];
wire balo5 = ((my[5]==rasterY)||MActive[5]) && (cycle>=8'd0 || cycle < 8'd05) && me[5];
wire balo6 = ((my[6]==rasterY)||MActive[6]) && (cycle>=8'd2 || cycle < 8'd07) && me[6];
wire balo7 = ((my[7]==rasterY)||MActive[7]) && (cycle>=8'd4 || cycle < 8'd09) && me[7];

wire baloc = BadLine && cycle >= 8'd12 && cycle <= 8'd54; 
assign balo = balo0|balo1|balo2|balo3|balo4|balo5|balo6|balo7|baloc; 

always @(posedge vclk)
if (rst) begin
  ba <= 1'b1;
end
else begin
  if (clken1)
    ba <= !balo;
end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
wire aelo0 = my[0]==nextRasterY && rasterX[10:2] >= 9'd117 && rasterX[10:2] <= 9'd120 && me[0];
wire aelo1 = my[1]==nextRasterY && rasterX[10:2] >= 9'd121 && rasterX[10:2] <= 9'd124 && me[1];
wire aelo2 = my[2]==nextRasterY && rasterX[10:2] >= 9'd125 && rasterX[10:2] <= 9'd128 && me[2];
wire aelo3 = (my[3]==nextRasterY && rasterX[10:2] >= 9'd129 && me[3]) || (my[3]==rasterY && rasterX[10:2] <= 9'd2 && me[3]);
wire aelo4 = my[4]==rasterY && rasterX[10:2] >= 9'd3 && rasterX[10:2] <= 9'd6 && me[4];
wire aelo5 = my[5]==rasterY && rasterX[10:2] >= 9'd7 && rasterX[10:2] <= 9'd10 && me[5];
wire aelo6 = my[6]==rasterY && rasterX[10:2] >= 9'd11 && rasterX[10:2] <= 9'd14 && me[6];
wire aelo7 = my[7]==rasterY && rasterX[10:2] >= 9'd15 && rasterX[10:2] <= 9'd18 && me[7];
wire aeloc = BadLine && rasterX[10:2] >= 9'd26 && rasterX[10:2] <= 9'd106; 
assign aelo = aelo0|aelo1|aelo2|aelo3|aelo4|aelo5|aelo6|aelo7|aeloc|hce[7]; 

always @(posedge vclk)
if (rst) begin
  aec <= 1'b1;
end
else begin
  if (clken2)
    aec <= aelo;
end

//------------------------------------------------------------------------------
// MIB data index counter
//------------------------------------------------------------------------------

reg [MIBCNT-1:0] vcsels;
always @(n,hCtr)
for (n = 0; n < MIBCNT; n = n + 1)
  sels[n] <= (hCtr=={n+1,3'd2}|hCtr=={n+1,3'd4}|hCtr=={n+1,3'd6});

always @(posedge vclk)
if (rst) begin
    for (n = 0; n < MIBCNT; n = n + 1)
    begin
      mcnt[n] = 6'd63;
    end
end
else begin
  if (sprrst[n]) mcnt[n] <= 6'd0;
  for (n = 0; n < MIBCNT; n = n + 1)
  begin
    if (vcsels[n] && mcnt[n] != 6'd63) 
      mcnt[n] = mcnt[n] + 6'd1;
  end
end

// Active sprites
always @*
for (n = 0; n < MIBCNT; n = n + 1)
begin
  MActive[n] = FALSE;
  if (mcnt[n] != 6'd63)
    MActive[n] = TRUE;
end

//------------------------------------------------------------------------------
// External Address Generator
//
// For now all we care about for external addresses are system ram refresh
// address.
//------------------------------------------------------------------------------
always @(posedge vclk)
if (rst) begin
  ado <= 14'h3FFF;
end
else begin
  ado <= {6'd0,refcntr};
end

wire [7:0] idb = sysram[sysadr];

wire [5:0] cgcol = hCtr[12:4]-8'd19;
wire [4:0] cgrow = vCtr[12:4]-8'd03;
wire [10:0] cgpos = cgrow * 6'd40 + cgcol;

//------------------------------------------------------------------------------
// Select address for internal ram
//------------------------------------------------------------------------------
always @(posedge vclk)
if (rst)
  wrtail <= 6'd0;
else begin
  if (hCtr > hBorderOn) begin
    if (wrtail != wrhead) begin
      sysadr <= writeadr[wrtail];
      sysdat <= writebuf[wrtail];
      wrtail <= wrtail + 1;
    end
  end
  else begin
    for (n = 0; n < MIBCNT; n = n + 1)
    begin
      if (hCtr=={n+1,3'd0})
        sysadr <= {ad[15:14],vm} + {6'b111111,~n[3],n[2:0]};
      else if (hCtr=={n+1,3'd2})
        sysadr <= {ad[15:14],idb,MCnt[n]};
      else if (hCtr=={n+1,3'd4})
        sysadr <= {ad[15:14],idb,MCnt[n]};
      else if (hCtr=={n+1,3'd6})
        sysadr <= {ad[15:14],idb,MCnt[n]};
      else begin
        if (hCtr[3:0]==4'd0)
          sysadr <= {ad[15:14],vm} + cgpos[9:0];
      end
    end
  end
end

always @(posedge vclk)
if (rst) begin
end
else begin
  if (hCtr[0]) begin
    for (n = 0; n < MIBCNT; n = n + 1)
    begin
      if (rasterVX < 11'd10)
        MShift[n] = FALSE;
      if (rasterVX==mx[n])
        MShift[n] = TRUE;

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

      if (MActive[n]) begin
        case({rasterVXn})
        MPixels[n] <= {MPixels[n][15:0],idb};
        endcase
      end
    end
  end
end

always @(posedge vclk)
if (rst) begin
  regpg <= 3'd0;
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
  bct <= 1'b1;
end
else begin
  if (phi02r[31]&&!phi02r[30]) begin
    if (cs_n==1'b0) begin
      if (!rw) begin
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
        8'd15:  case(regpg)
                3'd0: me[7:0] <= db;
                3'd1: me[15:8] <= db;
                3'd2: me[23:16] <= db;
                3'd3: me[31:24] <= db;
                3'd4: me[39:23] <= db;
                3'd5: me[47:40] <= db;
                3'd6: me[55:48] <= db;
                3'd7: me[63:56] <= db;
                endcase
        8'h16:  begin
                xscroll <= db[2:0];
                csel <= db[3];
                mcm <= db[4];
                res <= db[5];
                end  
        8'd17:  case(regpg)
                3'd0: mye[7:0] <= db;
                3'd1: mye[15:8] <= db;
                3'd2: mye[23:16] <= db;
                3'd3: mye[31:24] <= db;
                3'd4: mye[39:23] <= db;
                3'd5: mye[47:40] <= db;
                3'd6: mye[55:48] <= db;
                3'd7: mye[63:56] <= db;
                endcase
        8'd18:  begin
                cb[13:11] <= db[3:1];
                vm[13:10] <= db[7:4];
                end
        8'd19:  begin
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
                elpc <= db[3];
                end
        8'h1B:  mdp <= db;
        8'h1C:  mmc <= db;
        8'h1D:  mxe <= db;
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

        6'h30:  regno <= db;
        6'h32:  regpg <= db[2:0];
        6'h33:  bct <= db[0];
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

counter #(12) u1 (.rst(rst), .clk(vclk), .ce(1'b1), .ld(eol1), .d(12'd1), .q(hCtr) );
counter #(12) u2 (.rst(rst), .clk(vclk), .ce(eol1),  .ld(eof1), .d(12'd1), .q(vCtr) );

always @(posedge vclk)
    blank <= #1 hBlank|vBlank;
always @(posedge vclk)
    border <= #1 hBorder|vBorder;
always @(posedge vclk)
	hSync <= #1 hSync1;
always @(posedge vclk)
	vSync <= #1 vSync1;

endmodule

