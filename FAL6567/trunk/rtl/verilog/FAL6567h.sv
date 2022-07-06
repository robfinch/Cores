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
// Requires 67kB of block RAM          
// ============================================================================
//
`define TRUE  1'b1
`define FALSE 1'b0
`define LOW   1'b0
`define HIGH  1'b1

// 640x480 standard VGA timing is used, but the horizontal constants are multiplied
// by 1.299... to account for the use of a 32.71705MHz clock instead of 25.175.
// A five times clock (164MHz) is needed to drive the DVI interface.
// The 32.71705MHz clock was carefully selected as being on the high side of 32MHz
// given an input clock of 14.318MHz. Dividing 32.71705 by 32 gives a phi02 clock
// of 1.022MHz, really close to that normally supplied by the VIC-II.
//
module FAL6567h(chip_i, cr_clk, phi02, rst_o, irq, aec, ba,
	cs_n, rw, ad, db, den_n, dir, ras_n, cas_n, lp_n,
	TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n
);
parameter PAL = 1'b0;
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;
parameter LEGACY = 1'b1;
parameter MIBCNT = 16;

// Constants multiplied by 1.299... for 32.71705MHz clock
parameter phSyncOn  = 21;       //   16 front porch
parameter phSyncOff = 146;		//   96 sync
parameter phBlankOff = 208;		//   48 back porch
parameter phBorderOff = 307;	//    0 border
parameter phBorderOn = 947;	    //  640 display
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

input [1:0] chip_i;			// = CHIP6567R8; (pull downs)
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

output TMDS_OUT_clk_p;
output TMDS_OUT_clk_n;
output [2:0] TMDS_OUT_data_p;
output [2:0] TMDS_OUT_data_n;

output reg [18:0] ram_adr;
inout [7:0] ram_dat;
output reg ram_we;
output reg ram_oe;
output reg ram_ce;
input casram_n;

output Sync;
output reg [4:0] comp;
output colorBurst;


reg [3:0] p;
reg blank_n;
reg synclk;		// sync+lum clocking
reg colclk;		// color clocking
reg hSync, vSync;	// sync outputs

integer n;
wire cs = !cs_n;
wire clk164;	// 163.58525 MHz
wire clk33;		//  32.71705 MHz
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
reg [10:0] vmndx;                  // video matrix index
reg [11:0] nextChar;
reg [11:0] charbuf [78:0];
reg [2:0] scanline;

reg [4:0] sprite;
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
reg [1:0] regpg;  // register set page for sprites
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

assign irq = (ilp & elp) | (immc & emmc) | (imbc & embc) | (irst & erst); 
 
reg rasterIRQDone;

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

reg [21:0] rstcntr = 0;
wire xrst = SIM ? !rstcntr[3] : !rstcntr[21];
always_ff @(posedge cr_clk)
if (xrst)
  rstcntr <= rstcntr + 4'd1;

// Set Limits
always_ff @(posedge clk33)
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
	.clk164(clk164),
	.clk33(clk33),
	.locked(locked)
);

wire rst = !locked;
assign rst_o = rst;

assign den_n = aec ? cs_n : 1'b0;
assign dir = aec ? rw : 1'b0;
assign db = rst ? 12'bz : (aec && !cs_n && rw) ? {4'h0,dbo8} : 12'bz;

reg [1:0] chip;
always_ff @(posedge clk33)
	chip <= chip_i;
always_ff @(posedge clk33)
if (rst)
	ado <= 8'hFF;
else
	ado <= mux ? {2'b11,vicAddr[13:8]} : vicAddr[7:0];
assign ad = aec ? 12'bz : {vicAddr[11:8],ado};

wire ras_nne;
wire phi02_pe;
edge_det ued2 (.rst(rst), .clk(clk33), .ce(1'b1), .i(ras_n), .ne(ras_nne), .pe());
edge_det ued3 (.rst(rst), .clk(clk33), .ce(1'b1), .i(phi02), .pe(phi02_pe), .ne());

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

always_ff @(posedge clk33)
if (rst)
	blank_n <= 1'b0;
else
	blank_n <= blank;

always_ff @(posedge clk33)
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

always_ff @(posedge clk33)
if (rst)
	stc <= 32'b10000000000000000000000000000000;
else
	stc <= {stc[30:0],stc[31]};

always_ff @(posedge clk33)
if (rst)
	phi02r <= 32'b00000000000000001111111111111111;
else begin
	phi02r <= {phi02r[30:0],phi02r[31]};
end
always_ff @(posedge clk33)
	phi02 <= phi02r[0];
//assign phi02 = phi02r[32];

always_ff @(posedge clk33)
if (rst)
	phisr <= 32'b00000000000000000000011111111111;
else
	phisr <= {phisr[30:0],phisr[31]};
always @(posedge clk33)
	phis <= phisr[1];

always_ff @(posedge clk33)
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
		default:		rasr <= 32'hFFFFFFFF;
		endcase
		end
	else
		rasr <= {rasr[30:0],1'b0};
end
assign ras_n = rasr[31];
  
always_ff @(posedge clk33)
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
		default:		muxr <= 32'hFFFFFFFF;
		endcase
		end
	else
		muxr <= {muxr[30:0],1'b0};
end
assign mux = muxr[31];
  
always_ff @(posedge clk33)
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
		default:		casr <= 32'hFFFFFFFF;
		endcase
	end
	else
		casr <= {casr[30:0],1'b0};
end
assign cas_n = casr[31];

always_ff @(posedge clk33)
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

always_ff @(posedge clk33)
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

always_comb
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
always_ff @(posedge clk33)
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
always_ff @(posedge clk33)
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

always_ff @(posedge clk33)
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

always_ff @(posedge clk33)
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

always_ff @(posedge clk33)
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

always_ff @(posedge clk33)
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
always_comb
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

always_ff @(posedge clk33)
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

// Centre sprite number according to RAM timing.
always_ff @(posedge clk33)
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
integer n1;
always_ff @(posedge clk33)
	for (n1 = 0; n1 < MIBCNT; n1 = n1 + 1) begin
		if (me[n1] && ((my[n1]==nextRasterY)||MActive[n1])) begin
			if (leg)
				case(chip)
				CHIP6567R8:   balos[n1] <= (rasterX2 >= 11'h2D0 + {n1,5'b0}) && (rasterX2 < 11'h320 + {n1,5'b0});
				CHIP6567OLD:  balos[n1] <= (rasterX2 >= 11'h2C0 + {n1,5'b0}) && (rasterX2 < 11'h310 + {n1,5'b0});
				default:      balos[n1] <= (rasterX2 >= 11'h2B0 + {n1,5'b0}) && (rasterX2 < 11'h300 + {n1,5'b0}); 
				endcase
			else
				case(chip)
				CHIP6567R8:   balos[n1] <= (rasterX2 >= 11'h2D0 + {n1,4'b0}) && (rasterX2 < 11'h310 + {n1,4'b0});
				CHIP6567OLD:  balos[n1] <= (rasterX2 >= 11'h2C0 + {n1,4'b0}) && (rasterX2 < 11'h300 + {n1,4'b0});
				default:      balos[n1] <= (rasterX2 >= 11'h2B0 + {n1,4'b0}) && (rasterX2 < 11'h2F0 + {n1,4'b0}); 
				endcase
		end
		else begin
			balos[n1] <= `FALSE;
		end
	end

reg [10:0] baloff;
always_ff @(posedge clk33)
case(chip)
2'b00:	baloff <= 11'h2C0;
2'b01:	baloff <= 11'h2B0;
2'b10:	baloff <= 11'h2A0;
2'b11:	baloff <= 11'h2A0;
endcase
wire balo = |balos | (badline && rasterX2 < baloff);


//------------------------------------------------------------------------------
// Bus available drives the processor's ready line. So the ready line is held
// inactive until the FPGA is loaded and the pll is locked.
//------------------------------------------------------------------------------

always_ff @(posedge clk33)
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

always_ff @(posedge clk33)
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
always_ff @(posedge clk33)
if (phi02==`HIGH && enaData && (vicCycle==VIC_RC || vicCycle==VIC_CHAR)) begin
	if (badline)
		nextChar <= db;
	else
		nextChar <= charbuf[38];
	for (n2 = 38; n2 > 0; n2 = n2 -1)
		charbuf[n2] = charbuf[n2-1];
	charbuf[0] <= nextChar;
end

always_ff @(posedge clk33)
if (phi02==`LOW && enaData) begin
	if (vicCycle==VIC_CHAR || vicCycle==VIC_G) begin
		readPixels <= db[7:0];
		readChar <= nextChar;
	end
	waitingPixels <= readPixels;
	waitingChar <= readChar;
end

always_ff @(posedge clk33)
if (phis==`LOW && enaSData==1'b1 && busCycle==(leg ? BUS_LS : BUS_SPRITE)) begin
	if (MActive[sprite])
		MPtr[sprite] <= db[7:0];
	else
		MPtr[sprite] <= 8'd255;
end

//------------------------------------------------------------------------------
// Video matrix counter
//------------------------------------------------------------------------------
reg [10:0] vmndxStart;

always_ff @(posedge clk33)
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

always_ff @(posedge clk33)
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
always_ff @(posedge clk33)
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
always_ff @(posedge clk33)
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
always_ff @(posedge clk33)
begin
	for (n6 = 0; n6 < MIBCNT; n6 = n6 + 1) begin
		if (rasterX == 10)
			MShift[n6] <= `FALSE;
		else if (rasterX == mx[n6])
			MShift[n6] <= `TRUE;
	end
end

integer n7;
always_ff @(posedge clk33)
if (rst & SIM) begin
	for (n7 = 0; n7 < MIBCNT; n7 = n7 + 1) begin
		MCnt[n7] <= 6'd63;
	end
end
else begin
	// Trigger sprite accesses on the last character cycle
	// if the sprite Y coordinate will match.
	if (rasterX2==11'h2B0) begin
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

integer n8;
always_ff @(posedge clk33)
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

integer n9;
always_comb
	for (n9 = 0; n9 < MIBCNT; n9 = n9 + 1)
		mClkShift[n9] <= mShiftCount[n9]==2'd3;

// Y expansion
integer n10;
always_ff @(posedge clk33)
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


// Handle sprite pixel loading / shifting
integer n11;
always_ff @(posedge clk33)
begin
	if (clken8) begin
		for (n11 = 0; n11 < MIBCNT; n11 = n11 + 1) begin
			if (MShift[n11]) begin
				if (mClkShift[n11]) begin
					if (mc[n11])
						MPixels[n11] <= {MPixels[n11][21:0],2'b0};
					else
						MPixels[n11] <= {MPixels[n11][22:0],1'b0};
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
integer n12;
always_ff @(posedge clk33)
if (clken8) begin
	for (n12 = 0; n12 < MIBCNT; n12 = n12 + 1) begin
		if (MShift[n12])
			MCurrentPixel[n12] <= MPixels[n12][23:22];
		else
			MCurrentPixel[n12] <= 2'b00;
	end  
end


//------------------------------------------------------------------------------
// Address Generation
//------------------------------------------------------------------------------

always_comb
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
				addr <= vm + (14'b1111111000 | sprite[2:0]);
			else
				addr <= {MPtr[sprite],MCnt[sprite]};
		end
			else begin
			if (!phis)
				addr <= {MPtr[sprite],MCnt[sprite]};
			else
				addr <= vm + (14'b1111110000 | {~sprite[3],sprite[2:0]});
		end
	default: addr <= 14'h3FFF;
	endcase
end

always_ff @(posedge clk33)
	vicAddr <= addr;

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
// Video Blank Interval
//------------------------------------------------------------------------------
always_ff @(posedge clk33)
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
always_ff @(posedge clk33)
	hVicBlankOff <= 10'd103;
always_ff @(posedge clk33)
	hVicBlankOn <= 10'd592;

always_ff @(posedge clk33)
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
	.rasterX(rasterX),
	.rasterY(rasterY),
	.hSync(hSync8),
	.vSync(vSync8),
	.cSync(Sync)
);

//------------------------------------------------------------------------------
// Borders
//------------------------------------------------------------------------------

always_ff @(posedge clk33)
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

always_ff @(posedge clk33)
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

// Pixel shifter
always_ff @(posedge clk33)
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

always_ff @(posedge clk33)
if (clken8)
	pixelBgFlag <= shiftingPixels[7];

// Compute pixel color
always_ff @(posedge clk33)
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
integer n13;
always_ff @(posedge clk33)
begin
	// Force the output color to black for "illegal" modes
	case({ecm,bmm,mcm})
	3'b101,3'b110,3'b111:
		color_code <= 4'h0;
	default: color_code <= pixelColor;
	endcase
	// See if the mib overrides the output
	for (n13 = 0; n13 < MIBCNT; n13 = n13 + 1) begin
		if (!mdp[n13] || !pixelBgFlag) begin
			if (mmc[n13]) begin  // multi-color mode ?
				case(MCurrentPixel[n13])
				2'b00:  ;
				2'b01:  color_code <= mm0;
				2'b10:  color_code <= mc[n13];
				2'b11:  color_code <= mm1;
				endcase
			end
			else if (MCurrentPixel[n13][1])
				color_code <= mc[n13];
		end
	end
end

always_ff @(posedge clk33)
if (clken8) begin
  if (vicBorder)
		color8 <= ec;
  else
		color8 <= color_code;
end

FAL6567_ScanConverter usc1
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

FAL6567_ColorROM ucrom1
(
	.clk(clk33),
	.ce(1'b1),
	.code(color33),
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
	.vid_pData({RGB[23:16],RBG[7:0],RGB[15:8]}),
	.vid_pVDE(~blank),
	.vid_pHSync(hSync),    // hSync is neg going for 1366x768
	.vid_pVSync(vSync),
	.PixelClk(clk33),
	.SerialClk(clk164)
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
    8'h32:  dbo8 <= {leg,1'b0,4'hF,regpg};
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

