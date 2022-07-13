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
// timing. The dot clock is faster though at 33.333MHz. This allows a 640x400
// display area with a border to be created. This is double the horizontal and
// vertical resolution of the VIC-II. 
//
module FAL6567(chip, clk100, phi02, irq, aec, ba, cs_n, rw, ad, db, ras_n, cas_n, lp_n, hSync, vSync, red, green, blue);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;

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
parameter SIM = 1'b1;

input [1:0] chip;
input clk100;
output phi02;
output irq;
output reg aec;
output reg ba;
input cs_n;
input rw;
inout [13:0] ad;
inout tri [11:0] db;
output ras_n;
output cas_n;
input lp_n;
output reg hSync, vSync;	// sync outputs
output [3:0] red;
output [3:0] green;
output [3:0] blue;

integer n;
wire clk33;
wire irq_n;
assign irq = !irq_n;
reg [13:0] ado;
reg [13:0] ado1;
reg [7:0] p;
reg vSync8,hSync8;
reg [3:0] color8;
wire [3:0] color33;
reg blank;			// blanking output
reg border;
reg [7:0] regno;
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

reg [8:0] state;
reg den;
reg rsel, bmm, ecm;
reg csel, mcm, res;
reg mcmff;
reg [7:0] refcntr;
reg [31:0] phi02r;
reg [31:0] rasr;
reg [31:0] casr;
reg [31:0] hce;
reg [10:0] rasterX;
wire [7:0] column = rasterX[10:3];
reg [10:0] rasterXMax;
reg [8:0] rasterY;
reg [8:0] nextRasterY;
reg [8:0] rasterCmp;
reg [8:0] rasterYMax;
reg [8:0] nextRaster;
reg [2:0] yscroll;
reg [2:0] xscroll;
reg [9:0] charCount;
reg [5:0] charCountX;
reg [2:0] charRow;
reg [7:0] charBmp;
wire [15:0] selp;
wire [15:0] sels;
wire [15:0] selsa;
wire [15:0] selsb;
wire [15:0] selsc;
wire [15:0] selsd;
wire [15:0] sprrst;
reg [7:0] mbuf [0:15][0:63];
reg [15:0] mactive;
reg [5:0] mcnt [0:15];
reg [8:0] mx [0:15];
reg [7:0] my [0:15];
reg [15:0] me;
reg [15:0] mye;
reg [15:0] myeff;
reg [15:0] mxe;
reg [15:0] mxeff;
reg [7:0] mdp;
reg [15:0] mmc;
reg [3:0] mc [0:15];
reg [3:0] mm0;
reg [3:0] mm1;
reg [23:0] mshift [0:7];
reg [13:11] cb;
reg [13:10] vm;
reg [15:0] charbuf [0:63];
wire locked;
wire balo;
// Interrupt enable
reg erst;
reg embc;
reg emmc;
reg elpc;

reg irst_clr;
reg imbc_clr;
reg immc_clr;
reg ilp_clr;
reg irq_clr;

// colors
reg [3:0] ec;
reg [3:0] b0c, b1c, b2c, b3c;
reg [3:0] colorChar;
reg [4:0] mcolor [0:15];

reg [31:0] clk1r;
reg [31:0] clk2r;
reg [31:0] clk8r;
wire clken1, clken1x;
wire clken2;
wire clken8;
reg [31:0] muxr;
wire vicRefresh;
wire [7:0] dbo8;
wire [7:0] dbo33 = 8'h00;

assign db = (aec && !cs_n && rw) ? (ad[5:0] < 6'h30 ? {4'h0,dbo8} : {4'h0,dbo33}) : 12'bz;   

reg [21:0] rstcntr;
wire xrst = SIM ? !rstcntr[3] : !rstcntr[21];
always @(posedge clk33)
if (xrst)
  rstcntr <= rstcntr + 4'd1;

FAL6567_clkgen u1
(
  .rst(xrst),
  .xclk(clk100),
  .clk33(clk33),
  .locked(locked)
);

wire rst = !locked;

// Set Limits
always_ff @(posedge clk33)
case(chip)
CHIP6567R8:   begin rasterYMax = 9'd262; rasterXMax = {7'd64,3'b111}; end
CHIP6567OLD:  begin rasterYMax = 9'd261; rasterXMax = {7'd63,3'b111}; end
CHIP6569:     begin rasterYMax = 9'd311; rasterXMax = {7'd62,3'b111}; end
CHIP6572:     begin rasterYMax = 9'd311; rasterXMax = {7'd62,3'b111}; end
endcase

// Raster counters

always @(posedge clk33)
if (rst) begin
  rasterX <= 11'd0;
  rasterY <= 9'd0;
  nextRasterY <= 9'd0;
end
else begin
  if (clken8) begin
    if (rasterX==10'd400)
      nextRasterY <= rasterY + 9'd1;
    if (rasterX==rasterXMax) begin
      rasterX <= 10'd0;
      if (rasterY==rasterYMax)
        rasterY <= 9'd0;
      else
        rasterY <= rasterY + 9'd1;
    end
    else
      rasterX <= rasterX + 3'd1;
  end  
end
wire hSync8p = rasterX >= 10'd415 && rasterX <= 10'd450;
wire vSync8p = rasterY >= 9'd17 && rasterY <= 9'd20; 
assign vBorder = rsel ? rasterY < 9'd52 || rasterY > 9'd243 : rasterY < 9'd48 || rasterY > 9'd247;
assign hBorder = csel ? rasterX < {8'd32,2'b00} || rasterX > {8'd107,2'b00} : rasterX < {8'd30,2'b00} || rasterX > {8'd109,2'b00};
wire vBorder1 = SIM ? 1'b0 : rasterY < 9'd47 || rasterY > 9'd247;
wire BadLine = rasterY[2:0]==yscroll && den && !vBorder1;

always @(posedge clk33)
  hSync8 <= hSync8p;
always @(posedge clk33)
  vSync8 <= vSync8p;
 
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
/*
video_vicii_656x #(
  .emulateRefresh(1'b1),
  .emulateLightPen(1'b1)
) u3
(
  .clk(clk8),
  .phi(phi02),
  .enaData(),
  .enaPixel(1'b1),  // pixel clock enable
  .baSync(),
  .ba(ba),
  .mode6569(chip==CHIP6569),
  .mode6567old(chip==CHIP6567OLD),
  .mode6567R8(chip==CHIP6567R8),
  .mode6572(chip==CHIP6572),
  .cs(!cs_n),
  .we(wr),
  .rd(rw),
  .lp_n(lp_n),
  .aRegisters(ad[5:0]),
  .diRegisters(db[7:0]),
  .di(db[7:0]),
  .diColor(db[11:8]),
  .do(dbo8),
  .vicAddr(vicAddr),
  .irq_n(irq_n),
  // Video Outputs
  .hSync(hSync8),
  .vSync(vSync8),
  .colorIndex(color8),
  // Debug outputs
  .debugX(),
  .debugY(),
  .vicRefresh(vicRefresh),
  .addrValid()    
);
*/
always @(posedge clk33)
if (rst)
  clk8r <= 32'b10001000100010001000100010001000;
else
  clk8r <= {clk8r[30:0],clk8r[31]};
assign clken8 = clk8r[31];

always @(posedge clk33)
if (rst)
  clk2r <= 32'b10000000000000001000000000000000;
else
  clk2r <= {clk2r[30:0],clk2r[31]};
assign clken2 = clk2r[31];

always @(posedge clk33)
if (rst)
  clk1r <= 32'b00000000000000001000000000000000;
else
  clk1r <= {clk1r[30:0],clk1r[31]};
assign clken1 = clk1r[31];
assign clken1x = clk1r[15];

always @(posedge clk33)
if (rst)
  phi02r <= 32'b00000000000000001111111111111111;
else
  phi02r <= {phi02r[30:0],phi02r[31]};
assign phi02 = phi02r[31];

always @(posedge clk33)
if (rst)
  rasr <= 32'b11111100000000001111110000000000;
else
  rasr <= {rasr[30:0],rasr[31]};
assign ras_n = rasr[31];
  
always @(posedge clk33)
if (rst)
  muxr <= 32'b11111110000000001111111000000000;
else
  muxr <= {muxr[30:0],muxr[31]};
assign mux = muxr[31];
  
assign vicRefresh = rasterX > {8'd19,2'b11} && rasterX <= {8'd29,2'b11};

always @(posedge clk33)
if (rst)
  casr <= 32'b11111111100000001111111110000000;
else
  casr <= {casr[30:0],casr[31]};
assign cas_n = casr[31] | vicRefresh & !phi02;

always @(posedge clk33)
if (rst)
  refcntr <= 8'h00;
else begin
  if (clken1) begin
    if (vicRefresh)
        refcntr <= refcntr + 8'd1;
  end
end

// Active sprites
always @*
begin
for (n = 0; n < 8; n = n + 1)
begin
  mactive[n] = FALSE;
  if (mcnt[n] != 6'd63)
    mactive[n] = TRUE;
end
  mactive[8] = rasterY >= 9'd2 && rasterY <= 9'd22;
  mactive[9] = rasterY >= 9'd2 && rasterY <= 9'd22;
  mactive[10] = rasterY >= 9'd2 && rasterY <= 9'd22;
  mactive[11] = rasterY >= 9'd2 && rasterY <= 9'd22;
  mactive[12] = rasterY >= 9'd2 && rasterY <= 9'd22;
  mactive[13] = rasterY >= 9'd2 && rasterY <= 9'd22;
  mactive[14] = rasterY >= 9'd2 && rasterY <= 9'd22;
  mactive[15] = rasterY >= 9'd2 && rasterY <= 9'd22;
end

assign sprrst[0] = !mactive[0] && my[0]==nextRasterY && rasterX[9:2]==8'd115 && me[0];
assign sprrst[1] = !mactive[1] && my[1]==nextRasterY && rasterX[9:2]==8'd119 && me[1];
assign sprrst[2] = !mactive[2] && my[2]==nextRasterY && rasterX[9:2]==8'd123 && me[2];
assign sprrst[3] = !mactive[3] && my[3]==nextRasterY && rasterX[9:2]==8'd127 && me[3];
assign sprrst[4] = !mactive[4] && my[4]==rasterY && rasterX[9:2]==8'd1 && me[4];
assign sprrst[5] = !mactive[5] && my[5]==rasterY && rasterX[9:2]==8'd5 && me[5];
assign sprrst[6] = !mactive[6] && my[6]==rasterY && rasterX[9:2]==8'd9 && me[6];
assign sprrst[7] = !mactive[7] && my[7]==rasterY && rasterX[9:2]==8'd13 && me[7];
assign sprrst[8] = rasterY==9'd2 && rasterX[9:2]==8'd31 && me[8];
assign sprrst[9] = rasterY==9'd2 && rasterX[9:2]==8'd35 && me[9];
assign sprrst[10] = rasterY==9'd2 && rasterX[9:2]==8'd39 && me[10];
assign sprrst[11] = rasterY==9'd2 && rasterX[9:2]==8'd43 && me[11];
assign sprrst[12] = rasterY==9'd2 && rasterX[9:2]==8'd47 && me[12];
assign sprrst[13] = rasterY==9'd2 && rasterX[9:2]==8'd51 && me[13];
assign sprrst[14] = rasterY==9'd2 && rasterX[9:2]==8'd55 && me[14];
assign sprrst[15] = rasterY==9'd2 && rasterX[9:2]==8'd59 && me[15];

// cycle 'p' select
assign selp[0] = mactive[0] && rasterX[9:2] == 8'd117 && me[0];
assign selp[1] = mactive[1] && rasterX[9:2] == 8'd121 && me[1];
assign selp[2] = mactive[2] && rasterX[9:2] == 8'd125 && me[2];
assign selp[3] = mactive[3] && rasterX[9:2] == 8'd129 && me[3];
assign selp[4] = mactive[4] && rasterX[9:2] == 8'd3 && me[4];
assign selp[5] = mactive[5] && rasterX[9:2] == 8'd7 && me[5];
assign selp[6] = mactive[6] && rasterX[9:2] == 8'd11 && me[6];
assign selp[7] = mactive[7] && rasterX[9:2] == 8'd15 && me[7];
assign selp[8] = mactive[8] && rasterX[9:2] == 8'd33 && me[8];
assign selp[9] = mactive[9] && rasterX[9:2] == 8'd37 && me[9];
assign selp[10] = mactive[10] && rasterX[9:2] == 8'd41 && me[10];
assign selp[11] = mactive[11] && rasterX[9:2] == 8'd45 && me[11];
assign selp[12] = mactive[12] && rasterX[9:2] == 8'd49 && me[12];
assign selp[13] = mactive[13] && rasterX[9:2] == 8'd53 && me[13];
assign selp[14] = mactive[14] && rasterX[9:2] == 8'd57 && me[14];
assign selp[15] = mactive[15] && rasterX[9:2] == 8'd61 && me[15];

// cycle 's' select
assign sels[0] = mactive[0] && rasterX[9:2] >= 9'd118 && rasterX[9:2] <= 9'd120 && me[0];
assign sels[1] = mactive[1] && rasterX[9:2] >= 9'd122 && rasterX[9:2] <= 9'd124 && me[1];
assign sels[2] = mactive[2] && rasterX[9:2] >= 9'd126 && rasterX[9:2] <= 9'd128 && me[2];
assign sels[3] = mactive[3] && rasterX[9:2] >= 9'd0 && rasterX[9:2] <= 9'd2 && me[3];
assign sels[4] = mactive[4] && rasterX[9:2] >= 9'd4 && rasterX[9:2] <= 9'd6 && me[4];
assign sels[5] = mactive[5] && rasterX[9:2] >= 9'd8 && rasterX[9:2] <= 9'd10 && me[5];
assign sels[6] = mactive[6] && rasterX[9:2] >= 9'd12 && rasterX[9:2] <= 9'd14 && me[6];
assign sels[7] = mactive[7] && rasterX[9:2] >= 9'd16 && rasterX[9:2] <= 9'd18 && me[7];
assign sels[8] = mactive[8] && rasterX[9:2] >= 9'd34 && rasterX[9:2] <= 9'd36 && me[8];
assign sels[9] = mactive[9] && rasterX[9:2] >= 9'd38 && rasterX[9:2] <= 9'd40 && me[9];
assign sels[10] = mactive[10] && rasterX[9:2] >= 9'd42 && rasterX[9:2] <= 9'd44 && me[10];
assign sels[11] = mactive[11] && rasterX[9:2] >= 9'd46 && rasterX[9:2] <= 9'd48 && me[11];
assign sels[12] = mactive[12] && rasterX[9:2] >= 9'd50 && rasterX[9:2] <= 9'd52 && me[12];
assign sels[13] = mactive[13] && rasterX[9:2] >= 9'd54 && rasterX[9:2] <= 9'd56 && me[13];
assign sels[14] = mactive[14] && rasterX[9:2] >= 9'd58 && rasterX[9:2] <= 9'd60 && me[14];
assign sels[15] = mactive[15] && rasterX[9:2] >= 9'd62 && rasterX[9:2] <= 9'd64 && me[15];

assign selsa[0] = rasterX[9:2] == 8'd118;
assign selsb[0] = rasterX[9:2] == 8'd119;
assign selsc[0] = rasterX[9:2] == 8'd120;
assign selsd[0] = rasterX[9:2] == 8'd121;

assign selsa[1] = rasterX[9:2] == 8'd122;
assign selsb[1] = rasterX[9:2] == 8'd123;
assign selsc[1] = rasterX[9:2] == 8'd124;
assign selsd[1] = rasterX[9:2] == 8'd125;

assign selsa[2] = rasterX[9:2] == 8'd126;
assign selsb[2] = rasterX[9:2] == 8'd127;
assign selsc[2] = rasterX[9:2] == 8'd128;
assign selsd[2] = rasterX[9:2] == 8'd129;

assign selsa[3] = rasterX[9:2] == 8'd0;
assign selsb[3] = rasterX[9:2] == 8'd1;
assign selsc[3] = rasterX[9:2] == 8'd2;
assign selsd[3] = rasterX[9:2] == 8'd3;

assign selsa[4] = rasterX[9:2] == 8'd4;
assign selsb[4] = rasterX[9:2] == 8'd5;
assign selsc[4] = rasterX[9:2] == 8'd6;
assign selsd[4] = rasterX[9:2] == 8'd7;

assign selsa[5] = rasterX[9:2] == 8'd8;
assign selsb[5] = rasterX[9:2] == 8'd9;
assign selsc[5] = rasterX[9:2] == 8'd10;
assign selsd[5] = rasterX[9:2] == 8'd11;

assign selsa[6] = rasterX[9:2] == 8'd12;
assign selsb[6] = rasterX[9:2] == 8'd13;
assign selsc[6] = rasterX[9:2] == 8'd14;
assign selsd[6] = rasterX[9:2] == 8'd15;

assign selsa[7] = rasterX[9:2] == 8'd16;
assign selsb[7] = rasterX[9:2] == 8'd17;
assign selsc[7] = rasterX[9:2] == 8'd18;
assign selsd[7] = rasterX[9:2] == 8'd19;

wire selr =    rasterX[9:2] == 8'd20
            || rasterX[9:2] == 8'd22
            || rasterX[9:2] == 8'd24
            || rasterX[9:2] == 8'd26
            || rasterX[9:2] == 8'd28;

assign selsa[8] = rasterX[9:2] == 8'd34;
assign selsb[8] = rasterX[9:2] == 8'd35;
assign selsc[8] = rasterX[9:2] == 8'd36;
assign selsd[8] = rasterX[9:2] == 8'd37;

assign selsa[9] = rasterX[9:2] == 8'd38;
assign selsb[9] = rasterX[9:2] == 8'd39;
assign selsc[9] = rasterX[9:2] == 8'd40;
assign selsd[9] = rasterX[9:2] == 8'd41;

assign selsa[10] = rasterX[9:2] == 8'd42;
assign selsb[10] = rasterX[9:2] == 8'd43;
assign selsc[10] = rasterX[9:2] == 8'd44;
assign selsd[10] = rasterX[9:2] == 8'd45;

wire balo0 = mactive[0] && rasterX[9:2] >= 9'd110 && rasterX[9:2] <= 9'd119;
wire balo1 = mactive[1] && rasterX[9:2] >= 9'd114 && rasterX[9:2] <= 9'd123;
wire balo2 = mactive[2] && rasterX[9:2] >= 9'd118 && rasterX[9:2] <= 9'd127;
wire balo3 = mactive[3] && (rasterX[9:2] >= 9'd122 || rasterX[9:2] <= 9'd1);
wire balo4 = mactive[4] && (rasterX[9:2] >= 9'd126 || rasterX[9:2] <= 9'd5);
wire balo5 = mactive[5] && rasterX[9:2] >= 9'd0 && rasterX[9:2] <= 9'd9;
wire balo6 = mactive[6] && rasterX[9:2] >= 9'd4 && rasterX[9:2] <= 9'd13;
wire balo7 = mactive[7] && rasterX[9:2] >= 9'd8 && rasterX[9:2] <= 9'd17;
wire baloc = BadLine && rasterX[9:2] >= 8'd22 && rasterX[9:2] <= 8'd107; 
assign balo = balo0|balo1|balo2|balo3|balo4|balo5|balo6|balo7|baloc; 

always @(posedge clk33)
if (rst)
  ba <= 1'b1;
else begin
  if (clken8)
    ba <= !balo;
end

wire aelo0 = mactive[0] && rasterX[9:2] >= 8'd117 && rasterX[9:2] <= 8'd120;
wire aelo1 = mactive[1] && rasterX[9:2] >= 8'd121 && rasterX[9:2] <= 8'd124;
wire aelo2 = mactive[1] && rasterX[9:2] >= 8'd125 && rasterX[9:2] <= 8'd128;
wire aelo3 = mactive[3] && (rasterX[9:2] >= 8'd129 || rasterX[9:2] <= 8'd2);
wire aelo4 = mactive[4] && rasterX[9:2] >= 8'd3 && rasterX[9:2] <= 9'd6;
wire aelo5 = mactive[5] && rasterX[9:2] >= 8'd7 && rasterX[9:2] <= 9'd10;
wire aelo6 = mactive[6] && rasterX[9:2] >= 8'd11 && rasterX[9:2] <= 8'd14;
wire aelo7 = mactive[7] && rasterX[9:2] >= 8'd15 && rasterX[9:2] <= 9'd18;
wire aeloc = BadLine && rasterX[9:2] >= 8'd28 && rasterX[9:2] <= 8'd108; 
assign aelo = aelo0|aelo1|aelo2|aelo3|aelo4|aelo5|aelo6|aelo7|aeloc|phi02r[15]; 

wire selc = BadLine && rasterX[9:2] >= 8'd29 && rasterX[9:2] <= 8'd107 && rasterX[2];
wire selg = rasterX[9:2] >= 8'd30 && rasterX[9:2] <= 8'd110 && !rasterX[2] && den && !vBorder1;
wire ldg = rasterX[9:2] >= 8'd31 && rasterX[9:2] <= 8'd111 && rasterX[2] && den && !vBorder1;

always @(posedge clk33)
if (rst)
  aec <= 1'b1;
else begin
  if (clken8)//(!phi02r[30]&phi02r[31])||(!phi02r[14]&phi02r[15]))
    aec <= !aelo;
end

// Video matrix counter

always @(posedge clk33)
if (rst)
  charCount <= 10'd0;
else begin
  if (clken8) begin
    if (rasterY==9'd8)
      charCount <= 10'd0;
    if (selc && rasterX[2:0]==3'b100)
      charCount <= charCount + 10'd1;
  end
end

// Address generation

always @(posedge clk33)
if (rst) begin
  ado <= 14'h3FFF;
end
else begin
  if (clken2) begin
    ado <= 14'h3FFF;
    for (n = 0; n < 8; n = n + 1)
    begin
      if (selp[n])
        ado <= vm + {7'b1111111,n[2:0]};
      if (sels[n]) begin
         if (selsa[n]) begin p <= db; ado <= {db[7:0],mcnt[n]}; end
         if (selsb[n]) ado <= {p,mcnt[n]+6'd1}; 
         if (selsc[n]) ado <= {p,mcnt[n]+6'd2}; 
      end
    end
    if (selc) ado <= {vm,charCount};
    if (BadLine && selg) begin
      ado <= {cb,ecm ? {2'b00,db[5:0]} : db,charRow};
    end
    else if (selg) begin
      if (bmm)
        ado <= {cb[2],charCount,charRow};
      else
        ado <= {cb,charbuf[charCountX],charRow};
    end
  end
end

// Character pointer and color capture

always @(posedge clk33)
if (rst) begin
end
else begin
  if (clken2) begin
    if (BadLine && selg) begin
      if (ecm) begin
        case(ado[10:9])
        2'b00:  charbuf[charCountX] <= {b0c,db};
        2'b01:  charbuf[charCountX] <= {b1c,db};
        2'b10:  charbuf[charCountX] <= {b2c,db};
        2'b11:  charbuf[charCountX] <= {b3c,db};
        endcase
      end
      else
        charbuf[charCountX] <= {b0c,db};
    end
  end
end

reg selrd1;
always @(posedge clk33)
  if (clken2)
    selrd1 <= selr;

always @(posedge clk33)
if (rst)
  ado1 <= 14'h3FFF;
else
  ado1 <= selrd1 ? {6'h3F,refcntr} : mux ? {ado[13:8],2'b11,ado[13:8]} : ado[13:0];
assign ad = aec ? 14'bz : ado1;

always @(posedge clk33)
begin
  if (clken2) begin
    for (n = 0; n < 8; n = n + 1)
    begin
      if (sels[n]) begin
         if (selsb[n]) mshift[n][23:16] <= db[7:0];
         else if (selsc[n]) mshift[n][15:8] <= db[7:0]; 
         else if (selsd[n]) mshift[n][7:0] <= db[7:0]; 
      end
    end
  end
  if (clken8) begin
    for (n = 0; n < 8; n = n + 1)
    begin
      if (mx[n]<=rasterX[n]) begin
        if ((mxe[n] && mxeff[n]) || !mxe[n]) begin
          if (mmc[n])
            mshift[n] <= mshift[n] << 2;
          else
            mshift[n] <= mshift[n] << 1;
        end
      end
    end
  end
end

always @(posedge clk33)
if (clken8)
  for (n = 0; n < 16; n = n + 1)
  begin
    if (mmc[n])
      case(mshift[n][23:22])
      2'd0: mcolor[n] <= 5'b10000;
      2'd1: mcolor[n] <= mm0;
      2'd2: mcolor[n] <= mc[n];
      2'd3: mcolor[n] <= mm1;
      endcase
    else
      mcolor[n] <= mshift[n][23] ? mc[n] : 5'b10000;
  end 
  
// Counters
always @(posedge clk33)
if (rst) begin
  if (SIM) begin
    for (n = 0; n < 8; n = n + 1)
      mcnt[n] <= 6'h3F;
  end
end
else begin
  for (n = 0; n < 8; n = n + 1)
  if (clken2) begin
    if (sprrst[n])
      mcnt[n] <= 6'd0;
    if (selsd[n] && mactive[n]) begin
      if (mye[n] && !myeff[n])
        mcnt[n] <= mcnt[n] + 6'd0;
      else
        mcnt[n] <= mcnt[n] + 6'd3;
    end
  end
end

// Y-Expand FF
always @(posedge clk33)
if (rst)
  myeff <= 8'h00;
else begin
  for (n = 0; n < 8; n = n + 1)
  if (clken2) begin
    if (sprrst[n])
      myeff[n] <= 1'b0;
    if (selsd[n]) begin
      if (mye[n] && !myeff[n])
        myeff[n] <= 1'b1;
      else
        myeff[n] <= 1'b0;
    end
  end
end

// X-Expand FF
always @(posedge clk33)
if (rst)
  mxeff <= 8'h00;
else begin
  for (n = 0; n < 8; n = n + 1)
  begin
    if (clken2) begin
      if (sprrst[n])
        mxeff[n] <= 1'b0;
    end
    if (clken8) begin
      if (mx[n]<=rasterX[n]) begin
        if (mxe[n] && !mxeff[n])
          mxeff[n] <= 1'b1;
        else
          mxeff[n] <= 1'b0;
      end
    end
  end
end

reg [7:0] charBmp1;
always @(posedge clk33)
if (clken8) begin
  if (ldg && rasterX[1:0]==2'b11) begin
    charBmp1 <= db[7:0];
  end
  if (rasterX[2:0]==xscroll) begin
    mcmff <= 1'b0;
    charBmp <= charBmp1;
  end
  else begin
    if (mcm) begin
      if (mcmff) begin
        mcmff <= 1'b0;
        charBmp <= {charBmp[5:0],2'b0};
      end
      else
        mcmff <= 1'b1;
    end
    else
      charBmp <= {charBmp[6:0],1'b0};
  end
end

always @(posedge clk33)
if (clken8) begin
  if (mcm)
    case(charBmp[7:6])
    2'b00:  colorChar <= charbuf[charCountX-6'd1][15:12];
    2'b01:  colorChar <= charbuf[charCountX-6'd1][7:4];
    2'b10:  colorChar <= charbuf[charCountX-6'd1][3:0];
    2'b11:  colorChar <= charbuf[charCountX-6'd1][11:8];
    endcase
  else
    colorChar <= charBmp[7] ? charbuf[charCountX-6'd1][11:8] : charbuf[charCountX-6'd1][15:12];
end

always @(posedge clk33)
  if (vBorder|hBorder)
    color8 <= ec;
  else
    color8 <= colorChar;

always @(posedge clk33)
if (rst) begin
  charCountX <= 6'd1;
end
else begin
  if (clken8) begin
    if (rasterX==10'd0)
      charCountX <= 6'd1;
    if (selg && rasterX[2:0]==3'b011)
      charCountX <= charCountX + 6'd1;
  end
end

always @(posedge clk33)
if (clken8) begin
  if (rasterX == 10'd456) // 58
    charRow <= charRow + 3'd1;
  if (BadLine && rasterX < 10'd114)
    charRow <= 3'd0;
end

always @(posedge clk33)
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
  regno <= 6'h3F;
  if (SIM) begin
    for (n = 0; n < 8; n =  n + 1)
    begin
      mx[n] <= 9'h0;
      my[n] <= 8'h00;
      me[n] <= 1'b1;
      yscroll <= 3'b0;
      xscroll <= 3'b0;
    end
    b0c <= 4'd0;
    b1c <= 4'd6;
    b2c <= 4'd12;
    b3c <= 4'd15;
    ec <= 4'd6; // BLUE
  end
  vm <= 4'h2;
  cb <= 3'h0;
  mcm <= 1'b0;
  den <= 1'b1;
  bmm <= 1'b0;
  ecm <= 1'b0;
  rsel <= 1'b0;
  csel <= 1'b0;
end
else begin
  if (clken1x) begin
    if (cs_n==1'b0) begin
      if (wr) begin
        case(ad[5:0])
        6'h00:  mx[0][7:0] <= db;
        6'h01:  my[0] <= db;
        6'h02:  mx[1][7:0] <= db;
        6'h03:  my[1] <= db;
        6'h04:  mx[2][7:0] <= db;
        6'h05:  my[2] <= db;
        6'h06:  mx[3][7:0] <= db;
        6'h07:  my[3] <= db;
        6'h08:  mx[4][7:0] <= db;
        6'h09:  my[4] <= db;
        6'h0A:  mx[5][7:0] <= db;
        6'h0B:  my[5] <= db;
        6'h0C:  mx[6][7:0] <= db;
        6'h0D:  my[6] <= db;
        6'h0E:  mx[7][7:0] <= db;
        6'h0F:  my[7] <= db;
        6'h10:  begin
                mx[0][8] <= db[0];
                mx[1][8] <= db[1];
                mx[2][8] <= db[2];
                mx[3][8] <= db[3];
                mx[4][8] <= db[4];
                mx[5][8] <= db[5];
                mx[6][8] <= db[6];
                mx[7][8] <= db[7];
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
        6'h15:  me <= db;
        6'h16:  begin
                xscroll <= db[2:0];
                csel <= db[3];
                mcm <= db[4];
                res <= db[5];
                end  
        6'd17:  mye <= db;
        6'd18:  begin
                cb <= db[3:1];
                vm <= db[7:4];
                end
        6'd19:  begin
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
                elpc <= db[3];
                end
        6'h1B:  mdp <= db;
        6'h1C:  mmc <= db;
        6'h1D:  mxe <= db;
        6'h1E:  ; // mm collision
        6'h1F:  ; // md collision
        6'h20:  ec <= db[3:0];  // exterior (border color)
        6'h21:  b0c <= db[3:0]; // background color #0
        6'h22:  b1c <= db[3:0];
        6'h23:  b2c <= db[3:0];
        6'h24:  b3c <= db[3:0];
        6'h25:  mm0 <= db[3:0];
        6'h26:  mm1 <= db[3:0];
        6'h27:  mc[0] <= db[3:0];
        6'h28:  mc[1] <= db[3:0];
        6'h29:  mc[2] <= db[3:0];
        6'h2A:  mc[3] <= db[3:0];
        6'h2B:  mc[4] <= db[3:0];
        6'h2C:  mc[5] <= db[3:0];
        6'h2D:  mc[6] <= db[3:0];
        6'h2E:  mc[7] <= db[3:0];
        6'h30:  regno <= db;
        6'h31:
          case(regno)
          7'h0:  hSyncOn[7:0] <= db;
          7'h1:  hSyncOn[11:8] <= db[3:0];
          7'h2:  hSyncOff[7:0] <= db;
          7'h3:  hSyncOff[11:8] <= db[3:0];
          7'h4:  hBlankOff[7:0] <= db;
          7'h5:  hBlankOff[11:8] <= db[3:0];
          7'h6:  hBorderOff[7:0] <= db;
          7'h7:  hBorderOff[11:8] <= db[3:0];
          7'h8:  hBorderOn[7:0] <= db;
          7'h9:  hBorderOn[11:8] <= db[3:0];
          7'hA:  hBlankOn[7:0] <= db;
          7'hB:  hBlankOn[11:8] <= db[3:0];
          7'hC:  hTotal[7:0] <= db;
          7'hD:  hTotal[11:8] <= db[3:0];
          7'hF:  begin
                  hSyncPol <= db[0];
                  vSyncPol <= db[1];
                  end
          7'h10:  vSyncOn[7:0] <= db;
          7'h11:  vSyncOn[11:8] <= db[3:0];
          7'h12:  vSyncOff[7:0] <= db;
          7'h13:  vSyncOff[11:8] <= db[3:0];
          7'h14:  vBlankOff[7:0] <= db;
          7'h15:  vBlankOff[11:8] <= db[3:0];
          7'h16:  vBorderOff[7:0] <= db;
          7'h17:  vBorderOff[11:8] <= db[3:0];
          7'h18:  vBorderOn[7:0] <= db;
          7'h19:  vBorderOn[11:8] <= db[3:0];
          7'h1A:  vBlankOn[7:0] <= db;
          7'h1B:  vBlankOn[11:8] <= db[3:0];
          7'h1C:  vTotal[7:0] <= db;
          7'h1D:  vTotal[11:8] <= db[3:0];

          7'h20:  mx[8][7:0] <= db;
          7'h21:  my[8] <= db;
          7'h22:  mx[9][7:0] <= db;
          7'h23:  my[9] <= db;
          7'h24:  mx[10][7:0] <= db;
          7'h25:  my[10] <= db;
          7'h26:  mx[11][7:0] <= db;
          7'h27:  my[11] <= db;
          7'h28:  mx[12][7:0] <= db;
          7'h29:  my[12] <= db;
          7'h2A:  mx[13][7:0] <= db;
          7'h2B:  my[13] <= db;
          7'h2C:  mx[14][7:0] <= db;
          7'h2D:  my[14] <= db;
          7'h2E:  mx[15][7:0] <= db;
          7'h2F:  my[16] <= db;
          7'h30:  begin
                  mx[8][8] <= db[0];
                  mx[9][8] <= db[1];
                  mx[10][8] <= db[2];
                  mx[11][8] <= db[3];
                  mx[12][8] <= db[4];
                  mx[13][8] <= db[5];
                  mx[14][8] <= db[6];
                  mx[15][8] <= db[7];
                  end
          7'h35:  me[15:8] <= db;
          7'd37:  mye[15:8] <= db;
          7'h3C:  mmc[15:8] <= db;
          7'h3D:  mxe[15:8] <= db;
          7'h47:  mc[8] <= db[3:0];
          7'h48:  mc[9] <= db[3:0];
          7'h49:  mc[10] <= db[3:0];
          7'h4A:  mc[11] <= db[3:0];
          7'h4B:  mc[12] <= db[3:0];
          7'h4C:  mc[13] <= db[3:0];
          7'h4D:  mc[14] <= db[3:0];
          7'h4E:  mc[15] <= db[3:0];
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
assign red = color24[23:20];
assign green = color24[15:12];
assign blue = color24[7:4];

endmodule
