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
// timing. The dot clock is faster though at 33.3MHz. This allows a 640x400
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

parameter pSimRasterEnable = 48;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter SIM = 1'b1;

input [1:0] chip;
input clk100;
output phi02;
output irq;
output aec;
output ba;
input cs_n;
input rw;
inout [11:0] ad;
inout tri [11:0] db;
output ras_n;
output cas_n;
input lp_n;
output reg hSync, vSync;	// sync outputs
output [3:0] red;
output [3:0] green;
output [3:0] blue;

wire aec_n;
assign aec = !aec_n;
wire clk33;
wire irq_n;
assign irq = !irq_n;
wire [13:0] vicAddr;
reg [13:0] ado;
reg [6:0] ado1;
reg [7:0] p;
wire vSync8,hSync8;
wire [3:0] color8;
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

wire clken8;
reg [31:0] phi02r;
reg [31:0] clk1r;
reg [31:0] clk2r;
reg [31:0] clk8r;
reg [31:0] rasr;
reg [31:0] muxr;
reg [31:0] casr;
wire vicRefresh;
wire vicAddrValid;
wire [7:0] dbo8;
wire [7:0] dbo33 = 8'h00;

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

video_vicii_656x #(
  .registeredAddress(1'b1),
  .emulateRefresh(1'b1),
  .emulateLightPen(1'b1),
  .simRasterEnable(pSimRasterEnable)
) u3
(
  .rst(rst),
  .clk(clk33),
  .phi(phi02),
  .enaData(clk2r[29]),
  .enaPixel(clken8),
  .baSync(1'b0),
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
  .addrValid(aec_n)    
);

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
assign mux = muxr[31] & !(vicRefresh & !phi02);
  
always @(posedge clk33)
if (rst)
  casr <= 32'b11111111100000001111111110000000;
else
  casr <= {casr[30:0],casr[31]};
assign cas_n = casr[31] | (vicRefresh & !phi02);

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
end
else begin
  if (clken2 & phi02) begin
    if (cs_n==1'b0) begin
      if (wr) begin
        case(ad[5:0])
        6'h30:  regno <= db;
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
assign red = color24[23:20];
assign green = color24[15:12];
assign blue = color24[7:4];

endmodule

