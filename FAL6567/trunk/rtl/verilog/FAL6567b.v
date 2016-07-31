
// An 800x480 display format is created for VGA using the 640x480 standard VGA
// timing. The dot clock is faster though at 31.5MHz. This allows a 640x400
// display area with a border to be created. This is double the horizontal and
// vertical resolution of the VIC-II. 
//
module FAL6567(chip, clk100, clk8, phi02, aec, ba, cs_n, rw, ad, db, ras_n, cas_n, hSync, vSync, red, green, blue);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;

// Constants multiplied by 1.25 for 31.5MHz clock
parameter phSyncOn  = 20;     //   16 front porch
parameter phSyncOff = 140;		//   96 sync
parameter phBlankOff = 200;		//   48 back porch
parameter phBorderOff = 280;	//    0 border
parameter phBorderOn = 920;	  //  640 display
parameter phBlankOn = 1000;		//    0 border
parameter phTotal = 1000; 		//  800 total clocks
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
input clk100;
input clk8;
output phi02;
output reg aec;
output reg ba;
input cs_n;
input rw;
inout [11:0] ad;
inout tri [11:0] db;
output ras_n;
output cas_n;
output reg hSync, vSync;	// sync outputs
output [3:0] red;
output [3:0] green;
output [3:0] blue;

integer n;
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
reg [8:0] rasterY;
reg [8:0] nextRasterY;
reg [8:0] rasterCmp;
reg [8:0] rasterYMax;
reg [8:0] nextRaster;
reg [2:0] yscroll;
reg [2:0] xscroll;
wire [7:0] selp;
wire [7:0] sels;
wire [7:0] sprrst;
reg [7:0] mactive;
reg [5:0] mcnt [0:7];
reg [8:0] mx [0:7];
reg [7:0] my [0:7];
reg [7:0] me;
reg [7:0] mye;
reg [7:0] mxe;
reg [7:0] mdp;
reg [7:0] mmc;
reg [13:0] cb;
reg [13:0] vm;
wire locked;
wire balo;

wire selRefcntr = colCtr >= 7'd10 && colCtr <= 7'd14;

reg [19:0] rstcntr;
wire xrst = !rstcntr[19];
always @(posedge clk8)
if (xrst)
  rstcntr <= rstcntr + 4'd1;

FAL6567_clkgen u1
(
  .rst(xrst),
  .xclk(clk100),
  .clk31(vclk),
  .locked(locked)
);

wire rst = !locked;

// Set Limits
always @(chip)
case(chip)
CHIP6567R8:   begin rasterYMax = 9'd262; rasterXMax = {7'd64,3'b111}; end
CHIP6567OLD:  begin rasterYMax = 9'd261; rasterXMax = {7'd63,3'b111}; end
CHIP6569:     begin rasterYMax = 9'd311; rasterXMax = {7'd62,3'b111}; end
CHIP6572:     begin rasterYMax = 9'd311; rasterXMax = {7'd62,3'b111}; end
endcase

// Raster counters

always @(posedge clk8)
if (rst) begin
  rasterX <= 11'd0;
  rasterY <= 9'd0;
  nextRasterY <= 9'd0;
  refcntr <= 8'd255;
end
else begin
  if (rasterX==10'd88 || rasterX==10'd96 || rasterX==10'd104 || rasterX==10'd112 || rasterX==10'd120)
    refcntr <= refcntr - 8'd1;
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
    rasterX <= rasterX + 8'd1;  
end
wire vBorder = rsel ? rasterY < 9'd52 || rasterY > 9'd243 : rasterY < 9'd48 || rasterY > 9'd247;
wire vBorder1 = rasterY < 9'd47 || rasterY > 9'd247;
wire BadLine = rasterY[2:0]==yscroll && den && !vBorder1;

always @(posedge clk8)
if (rst)
  phi02r <= 8'h0F;
else
  phi02r <= {phi02r[6:0],phi02r[7]};
assign phi02 = phi02r[7];

always @(posedge clk8)
  if (rst)
    rasr <= 8'h88;
  else
    rasr <= {rasr[6:0],rasr[7]};
assign ras_n = rasr[7];
  
always @(posedge clk8)
  if (rst)
    casr <= 8'hCC;
  else
    casr <= {casr[6:0],casr[7]};
assign cas_n = casr[7];

always @(posedge clk8)
  if (rst)
    hce <= 8'h01;
  else
    hce <= {hce[6:0],hce[7]};

always @(posedge clk8)
if (rst)
  ba <= 1'd1;
else begin
  if (hce[7]) begin
    if (colCtr==7'd10)
      ba <= 1'b1;
    else if (colCtr==7'd56)
      ba <= 1'b0;
  end
end

always @(posedge clk8)
if (rst)
  refcntr <= 8'd0;
else begin
  if (hce[7]) begin
    if (colCtr >= 7'd10 && colCtr <= 7'd14)
        refcntr <= refcntr + 8'd1;
  end
end

assign sprrst[0] = !mactive[0] && my[0]==nextRasterY && rasterX[9:2]==8'd115 && me[0];
assign sprrst[1] = !mactive[1] && my[1]==nextRasterY && rasterX[9:2]==8'd119 && me[1];
assign sprrst[2] = !mactive[2] && my[2]==nextRasterY && rasterX[9:2]==8'd123 && me[2];
assign sprrst[3] = !mactive[3] && my[3]==nextRasterY && rasterX[9:2]==8'd127 && me[3];
assign sprrst[4] = !mactive[4] && my[4]==rasterY && rasterX[9:2]==8'd1 && me[4];
assign sprrst[5] = !mactive[5] && my[5]==rasterY && rasterX[9:2]==8'd5 && me[5];
assign sprrst[6] = !mactive[6] && my[6]==rasterY && rasterX[9:2]==8'd9 && me[6];
assign sprrst[7] = !mactive[7] && my[7]==rasterY && rasterX[9:2]==8'd13 && me[7];

// cycle 'p' select
assign selp[0] = mactive[0] && rasterX[9:2] == 8'd117 && me[0];
assign selp[1] = mactive[1] && rasterX[9:2] == 8'd121 && me[1];
assign selp[2] = mactive[2] && rasterX[9:2] == 8'd125 && me[2];
assign selp[3] = mactive[3] && rasterX[9:2] == 8'd129 && me[3];
assign selp[4] = mactive[4] && rasterX[9:2] == 8'd3 && me[4];
assign selp[5] = mactive[5] && rasterX[9:2] == 8'd7 && me[5];
assign selp[6] = mactive[6] && rasterX[9:2] == 8'd11 && me[6];
assign selp[7] = mactive[7] && rasterX[9:2] == 8'd15 && me[7];

// cycle 's' select
assign sels[0] = mactive[0] && rasterX[9:2] >= 9'd118 && rasterX[9:2] <= 9'd120 && me[0];
assign sels[1] = mactive[1] && rasterX[9:2] >= 9'd122 && rasterX[9:2] <= 9'd124 && me[1];
assign sels[2] = mactive[2] && rasterX[9:2] >= 9'd126 && rasterX[9:2] <= 9'd128 && me[2];
assign sels[3] = mactive[3] && rasterX[9:2] >= 9'd0 && rasterX[9:2] <= 9'd2 && me[3];
assign sels[4] = mactive[4] && rasterX[9:2] >= 9'd4 && rasterX[9:2] <= 9'd6 && me[4];
assign sels[5] = mactive[5] && rasterX[9:2] >= 9'd8 && rasterX[9:2] <= 9'd10 && me[5];
assign sels[6] = mactive[6] && rasterX[9:2] >= 9'd12 && rasterX[9:2] <= 9'd14 && me[6];
assign sels[7] = mactive[7] && rasterX[9:2] >= 9'd16 && rasterX[9:2] <= 9'd18 && me[7];

wire sels0a = rasterX[9:2] == 9'd118;
wire sels0b = rasterX[9:2] == 9'd119;
wire sels0c = rasterX[9:2] == 9'd120;

wire sels1a = rasterX[9:2] == 9'd122;
wire sels1b = rasterX[9:2] == 9'd123;
wire sels1c = rasterX[9:2] == 9'd124;

wire sels2a = rasterX[9:2] == 9'd126;
wire sels2b = rasterX[9:2] == 9'd127;
wire sels2c = rasterX[9:2] == 9'd128;

wire sels3a = rasterX[9:2] == 9'd0;
wire sels3b = rasterX[9:2] == 9'd1;
wire sels3c = rasterX[9:2] == 9'd2;

wire sels4a = rasterX[9:2] == 9'd4;
wire sels4b = rasterX[9:2] == 9'd5;
wire sels4c = rasterX[9:2] == 9'd6;

wire sels5a = rasterX[9:2] == 9'd8;
wire sels5b = rasterX[9:2] == 9'd9;
wire sels5c = rasterX[9:2] == 9'd10;

wire sels6a = rasterX[9:2] == 9'd12;
wire sels6b = rasterX[9:2] == 9'd13;
wire sels6c = rasterX[9:2] == 9'd14;

wire sels7a = rasterX[9:2] == 9'd16;
wire sels7b = rasterX[9:2] == 9'd17;
wire sels7c = rasterX[9:2] == 9'd18;

wire balo0 = mactive[0] && rasterX[9:2] >= 9'd111 && rasterX[9:2] <= 9'd120;
wire balo1 = mactive[1] && rasterX[9:2] >= 9'd115 && rasterX[9:2] <= 9'd124;
wire balo2 = mactive[2] && rasterX[9:2] >= 9'd119 && rasterX[9:2] <= 9'd128;
wire balo3 = mactive[3] && (rasterX[9:2] >= 9'd123 || rasterX[9:2] <= 9'd2);
wire balo4 = mactive[4] && (rasterX[9:2] >= 9'd127 || rasterX[9:2] <= 9'd6);
wire balo5 = mactive[5] && rasterX[9:2] >= 9'd1 && rasterX[9:2] <= 9'd10;
wire balo6 = mactive[6] && rasterX[9:2] >= 9'd5 && rasterX[9:2] <= 9'd14;
wire balo7 = mactive[7] && rasterX[9:2] >= 9'd9 && rasterX[9:2] <= 9'd18;
wire baloc = BadLine && rasterX[9:2] >= 8'd20 && rasterX[9:2] <= 8'd106; 
assign balo = balo0|balo1|balo2|balo3|balo4|balo5|balo6|balo7|baloc; 

always @(posedge clk8)
if (rst) begin
  ba <= 1'b1;
end
else begin
  if (hce[7])
    ba <= !balo;
end

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

always @(posedge clk8)
if (rst) begin
  aec <= 1'b1;
end
else begin
  if (hce[7]|hce[3])
    aec <= aelo;
end

always @(posedge clk8)
if (rst) begin
end
else begin
  if (hce[7]|hce[3]) begin
    for (n = 0; n < 8; n = n + 1)
    begin
      if (sprrst[n]) mcnt[n] <= 6'd0;
      if (selp[n]) ado <= vm + {7'b1111111,n[2:0]};
    end
    if (sels[0]) begin
       if (sels0a) begin p <= db; ado <= {db[7:0],mcnt[0]}; end
       if (sels0b) ado <= {p,mcnt[0]}; 
       if (sels0c) ado <= {p,mcnt[0]}; 
    end
    if (sels[1]) begin
       if (sels1a) begin p <= db; ado <= {db[7:0],mcnt[1]}; end
       if (sels1b) ado <= {p,mcnt[1]}; 
       if (sels1c) ado <= {p,mcnt[1]}; 
    end
    if (sels[2]) begin
       if (sels2a) begin p <= db; ado <= {db[7:0],mcnt[2]}; end
       if (sels2b) ado <= {p,mcnt[2]}; 
       if (sels2c) ado <= {p,mcnt[2]}; 
    end
    if (sels[3]) begin
       if (sels3a) begin p <= db; ado <= {db[7:0],mcnt[3]}; end
       if (sels3b) ado <= {p,mcnt[3]}; 
       if (sels3c) ado <= {p,mcnt[3]}; 
    end
    if (sels[4]) begin
       if (sels4a) begin p <= db; ado <= {db[7:0],mcnt[4]}; end
       if (sels4b) ado <= {p,mcnt[4]}; 
       if (sels4c) ado <= {p,mcnt[4]}; 
    end
    if (sels[5]) begin
       if (sels5a) begin p <= db; ado <= {db[7:0],mcnt[5]}; end
       if (sels5b) ado <= {p,mcnt[5]}; 
       if (sels5c) ado <= {p,mcnt[5]}; 
    end
    if (sels[6]) begin
       if (sels6a) begin p <= db; ado <= {db[7:0],mcnt[6]}; end
       if (sels6b) ado <= {p,mcnt[6]}; 
       if (sels6c) ado <= {p,mcnt[6]}; 
    end
    if (sels[7]) begin
       if (sels7a) begin p <= db; ado <= {db[7:0],mcnt[7]}; end
       if (sels7b) ado <= {p,mcnt[7]}; 
       if (sels7c) ado <= {p,mcnt[7]}; 
    end
  end
end

// Active sprites
always @*
for (n = 0; n < 8; n = n + 1)
begin
  mactive[n] = FALSE;
  if (mcnt[n] != 6'd63)
    mactive[n] = TRUE;
end

always @(posedge clk8)
if (rst) begin
end
else begin
end

always @(posedge clk8)
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
  vm[9:0] <= 10'd0;
  cb[10:0] <= 11'b0;
end
else begin
  if (hce[7]) begin
    if (cs_n==1'b0) begin
      if (!rw) begin
        case(ad[7:0])
        8'h00:  mx[0][7:0] <= db;
        8'h01:  my[0] <= db;
        8'h02:  mx[1][7:0] <= db;
        8'h03:  my[1] <= db;
        8'h04:  mx[2][7:0] <= db;
        8'h05:  my[2] <= db;
        8'h06:  mx[3][7:0] <= db;
        8'h07:  my[3] <= db;
        8'h08:  mx[4][7:0] <= db;
        8'h09:  my[4] <= db;
        8'h0A:  mx[5][7:0] <= db;
        8'h0B:  my[5] <= db;
        8'h0C:  mx[6][7:0] <= db;
        8'h0D:  my[6] <= db;
        8'h0E:  mx[7][7:0] <= db;
        8'h0F:  my[7] <= db;
        8'h10:  begin
                mx[0][8] <= db[0];
                mx[1][8] <= db[1];
                mx[2][8] <= db[2];
                mx[3][8] <= db[3];
                mx[4][8] <= db[4];
                mx[5][8] <= db[5];
                mx[6][8] <= db[6];
                mx[7][8] <= db[7];
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
        8'h15:  me <= db;
        8'h16:  begin
                xscroll <= db[2:0];
                csel <= db[3];
                mcm <= db[4];
                res <= db[5];
                end  
        8'd17:  mye <= db;
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
        8'h27:  mc[0] <= db[3:0];
        8'h28:  mc[1] <= db[3:0];
        8'h29:  mc[2] <= db[3:0];
        8'h2A:  mc[3] <= db[3:0];
        8'h2B:  mc[4] <= db[3:0];
        8'h2C:  mc[5] <= db[3:0];
        8'h2D:  mc[6] <= db[3:0];
        8'h2E:  mc[7] <= db[3:0];

        8'h30:  hSyncOn[7:0] <= db;
        8'h31:  hSyncOn[11:8] <= db[3:0];
        8'h32:  hSyncOff[7:0] <= db;
        8'h33:  hSyncOff[11:8] <= db[3:0];
        8'h34:  hBlankOff[7:0] <= db;
        8'h35:  hBlankOff[11:8] <= db[3:0];
        8'h36:  hBorderOff[7:0] <= db;
        8'h37:  hBorderOff[11:8] <= db[3:0];
        8'h38:  hBorderOn[7:0] <= db;
        8'h39:  hBorderOn[11:8] <= db[3:0];
        8'h3A:  hBlankOn[7:0] <= db;
        8'h3B:  hBlankOn[11:8] <= db[3:0];
        8'h3C:  hTotal[7:0] <= db;
        8'h3D:  hTotal[11:8] <= db[3:0];
        8'h3F:  begin
                hSyncPol <= db[0];
                vSyncPol <= db[1];
                end
        8'h40:  vSyncOn[7:0] <= db;
        8'h41:  vSyncOn[11:8] <= db[3:0];
        8'h42:  vSyncOff[7:0] <= db;
        8'h43:  vSyncOff[11:8] <= db[3:0];
        8'h44:  vBlankOff[7:0] <= db;
        8'h45:  vBlankOff[11:8] <= db[3:0];
        8'h46:  vBorderOff[7:0] <= db;
        8'h47:  vBorderOff[11:8] <= db[3:0];
        8'h48:  vBorderOn[7:0] <= db;
        8'h49:  vBorderOn[11:8] <= db[3:0];
        8'h4A:  vBlankOn[7:0] <= db;
        8'h4B:  vBlankOn[11:8] <= db[3:0];
        8'h4C:  vTotal[7:0] <= db;
        8'h4D:  vTotal[11:8] <= db[3:0];
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

