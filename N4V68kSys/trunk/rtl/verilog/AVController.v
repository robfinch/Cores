// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// AVController.v
// - audio / video controller
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
`define TRUE	1'b1
`define FALSE	1'b0
`define HIGH	1'b1
`define LOW		1'b0

`define A		15
`define R		14:10
`define G		9:5
`define B		4:0

`define BLACK	16'h0000
`define WHITE	16'h7FFF

`define CLIPEN		0
`define CMDDAT		31:0
`define CMDCMD		47:32

`define CHARCODE	8:0
`define FGCOLOR		24:9
`define BKCOLOR		40:25
`define X0POS		52:41
`define Y0POS		64:53
`define CHARXM		68:65
`define CHARYM		72:69
`define CMD			80:73
`define X1POS		92:81
`define Y1POS		104:93
`define X2POS		116:105
`define Y2POS		128:117
`define BASEADRH	120:105
`define BASEADRL	136:121
`define CMDQ_WID	64
`define CMDQ_DEP    32
`define TXHANDLE	8:0
`define TXCOUNT		24:9
`define TXMOD		40:25
`define TXWIDTH		52:41

`define AUD_PLOT

module AVController(
	rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o,
	cs_i, cs_ram_i, irq_o,
	clk, hSync, vSync, blank_o, rgb,
	aud0_out, aud1_out, aud2_out, aud3_out, aud_in
);
parameter pAckStyle = 1'b0;

// Wishbone slave port
input rst_i;
input clk_i;
input cyc_i;
input stb_i;
output reg ack_o;
input we_i;
input [1:0] sel_i;
input [23:0] adr_i;
input [15:0] dat_i;
output reg [15:0] dat_o;

input cs_i;							// circuit select
input cs_ram_i;
output irq_o;

// Video port
input clk;
output hSync;
output vSync;
output reg blank_o;
output reg [14:0] rgb;

output reg [15:0] aud0_out;
output reg [15:0] aud1_out;
output reg [15:0] aud2_out;
output reg [15:0] aud3_out;
input [15:0] aud_in;

// Sync Generator defaults: 800x600 60Hz
parameter phSyncOn  = 40;		//   40 front porch
parameter phSyncOff = 168;		//  128 sync
parameter phBlankOff = 252;	//256	//   88 back porch
//parameter phBorderOff = 336;	//   80 border
parameter phBorderOff = 256;	//   80 border
//parameter phBorderOn = 976;		//  640 display
parameter phBorderOn = 1056;		//  640 display
parameter phBlankOn = 1052;		//   80 border
parameter phTotal = 1056;		// 1056 total clocks
parameter pvSyncOn  = 1;		//    1 front porch
parameter pvSyncOff = 5;		//    4 vertical sync
parameter pvBlankOff = 28;		//   23 back porch
parameter pvBorderOff = 28;		//   44 border	0
//parameter pvBorderOff = 72;		//   44 border	0
parameter pvBorderOn = 628;		//  512 display
//parameter pvBorderOn = 584;		//  512 display
parameter pvBlankOn = 628;  	//   44 border	0
parameter pvTotal = 628;		//  628 total scan lines


parameter NSPR = 32;
parameter ST_IDLE = 7'd0;
parameter ST_RW = 7'd1;
parameter ST_CHAR_INIT = 7'd2;
parameter ST_READ_CHAR_BITMAP = 7'd3;
parameter ST_READ_CHAR_BITMAP2 = 7'd4;
parameter ST_READ_CHAR_BITMAP3 = 7'd5;
parameter ST_READ_CHAR_BITMAP_DAT = 7'd6;
parameter ST_CALC_INDEX = 7'd7;
parameter ST_WRITE_CHAR = 7'd8;
parameter ST_NEXT = 7'd9;
parameter ST_BLT_INIT = 7'd10;
parameter ST_READ_BLT_BITMAP = 7'd11;
parameter ST_READ_BLT_BITMAP2 = 7'd12;
parameter ST_READ_BLT_BITMAP3 = 7'd13;
parameter ST_READ_BLT_BITMAP_DAT = 7'd14;
parameter ST_CALC_BLT_INDEX = 7'd15;
parameter ST_READ_BLT_PIX = 7'd16;
parameter ST_READ_BLT_PIX2 = 7'd17;
parameter ST_READ_BLT_PIX3= 7'd18;
parameter ST_WRITE_BLT_PIX = 7'd19;
parameter ST_BLT_NEXT = 7'd20;
parameter ST_PLOT = 7'd21;
parameter ST_PLOT_READ = 7'd22;
parameter ST_PLOT_READ2 = 7'd23;
parameter ST_PLOT_READ3 = 7'd24;
parameter ST_PLOT_WRITE = 7'd25;
parameter ST_FILLRECT_CLIP = 7'd26;
parameter ST_TILERECT_CLIP = 7'd27;
parameter ST_BLTDMA = 7'd30;
parameter ST_BLTDMA1 = 7'd31;
parameter ST_BLTDMA2 = 7'd32;
parameter ST_BLTDMA3 = 7'd33;
parameter ST_BLTDMA4 = 7'd34;
parameter ST_BLTDMA5 = 7'd35;
parameter ST_BLTDMA6 = 7'd36;
parameter ST_BLTDMA7 = 7'd37;
parameter ST_BLTDMA8 = 7'd38;
parameter DL_INIT = 7'd40;
parameter DL_PRECALC = 7'd41;
parameter DL_GETPIXEL = 7'd42;
parameter DL_GETPIXEL2 = 7'd43;
parameter DL_GETPIXEL3 = 7'd44;
parameter DL_SETPIXEL = 7'd45;
parameter DL_TEST = 7'd46;
parameter ST_CMD = 7'd47;
parameter ST_COPPER_IFETCH = 7'd50;
parameter ST_COPPER_IFETCH1 = 7'd51;
parameter ST_COPPER_IFETCH2 = 7'd52;
parameter ST_COPPER_IFETCH3 = 7'd53;
parameter ST_COPPER_IFETCH4 = 7'd54;
parameter ST_COPPER_IFETCH5 = 7'd55;
parameter ST_COPPER_IFETCH6 = 7'd56;
parameter ST_COPPER_IFETCH7 = 7'd57;
parameter ST_COPPER_IFETCH8 = 7'd58;
parameter ST_COPPER_IFETCH9 = 7'd59;
parameter ST_COPPER_EXECUTE = 7'd60;
parameter ST_COPPER_SKIP	= 7'd61;
parameter ST_RW2 = 7'd62;
parameter ST_AUD0 = 7'd64;
parameter ST_AUD02 = 7'd65;
parameter ST_AUD03 = 7'd66;
parameter ST_AUD1 = 7'd68;
parameter ST_AUD12 = 7'd69;
parameter ST_AUD13 = 7'd70;
parameter ST_AUD2 = 7'd72;
parameter ST_AUD22 = 7'd73;
parameter ST_AUD23 = 7'd74;
parameter ST_AUD3 = 7'd76;
parameter ST_AUD32 = 7'd77;
parameter ST_AUD33 = 7'd78;
parameter ST_FILLRECT = 7'd80;
parameter ST_FILLRECT1 = 7'd81;
parameter ST_FILLRECT2 = 7'd82;
parameter ST_TILERECT = 7'd83;
parameter ST_TILERECT1 = 7'd84;
parameter ST_TILERECT2 = 7'd85;
parameter ST_READ_FONT_TBL = 7'd90;
parameter ST_READ_FONT_TBL2 = 7'd91;
parameter ST_READ_FONT_TBL3 = 7'd92;
parameter ST_READ_FONT_TBL4 = 7'd93;
parameter ST_READ_FONT_TBL5 = 7'd94;
parameter ST_READ_GLYPH_ENTRY = 7'd95;
parameter ST_READ_GLYPH_ENTRY2 = 7'd96;
parameter ST_READ_CHAR_BITMAP_DAT2 = 7'd97;
parameter ST_AUD_PLOT = 7'd98;
parameter ST_AUD_PLOT_WRITE = 7'd99;
parameter ST_GFX_RW = 7'd100;
parameter ST_GFXS_RW = 7'd101;
parameter ST_GFXS_RW2 = 7'd102;
parameter ST_READ_FONT_TBL6 = 7'd103;
parameter ST_PLOT_RET = 7'd104;
parameter ST_AUD_PLOT_RET = 7'd105;
parameter ST_READ_CHAR_BITMAP_DAT3 = 7'd106;
parameter ST_READ_CHAR_BITMAP_DAT4 = 7'd107;
parameter ST_READ_FONT_TBL1 = 7'd108;
parameter ST_READ_FONT_TBL1a = 7'd109;
parameter ST_READ_GLYPH_ENTRY3 = 7'd110;
parameter DT_SORT = 7'd111;
parameter DT_SLOPE1 = 7'd112;
parameter DT_SLOPE1a = 7'd113;
parameter DT_SLOPE2 = 7'd114;
parameter DT_LINE1 = 7'd115;
parameter DT_LINE2 = 7'd116;
parameter DT_SETPIXEL = 7'd117;
parameter DT_INCY = 7'd118;
parameter DT1 = 7'd119;
parameter DT2 = 7'd120;
parameter DT3 = 7'd121;
parameter DT4 = 7'd122;
parameter DT5 = 7'd123;
parameter DT6 = 7'd124;
parameter DT_GETPIXEL = 7'd125;
parameter DT_GETPIXEL2 = 7'd126;
parameter DT_GETPIXEL3 = 7'd127;
parameter BC0 = 8'd128;
parameter BC1 = 8'd129;
parameter BC2 = 8'd130;
parameter BC3 = 8'd131;
parameter BC4 = 8'd132;
parameter BC5 = 8'd133;
parameter BC6 = 8'd134;
parameter BC7 = 8'd135;
parameter BC8 = 8'd136;
parameter BC5a = 8'd137;
parameter BC9 = 8'd138;
parameter DT_START = 8'd139;
parameter HL_LINE = 8'd140;
parameter HL_GETPIXEL = 8'd141;
parameter HL_GETPIXEL2 = 8'd142;
parameter HL_GETPIXEL3 = 8'd143;
parameter HL_SETPIXEL = 8'd144;
parameter GETPIXEL = 8'd145;
parameter GETPIXEL2 = 8'd146;
parameter GETPIXEL3 = 8'd147;
parameter SETPIXEL = 8'd148;
parameter DELAY2 = 8'd149;
parameter DELAY2a = 8'd150;
parameter DELAY2b = 8'd151;
parameter DAAL1 = 8'd155;
parameter DAAL2 = 8'd156;
parameter DAAL3 = 8'd157;
parameter DAAL4 = 8'd158;
parameter DAAL5 = 8'd159;
parameter DAAL6 = 8'd160;
parameter DAAL7 = 8'd161;
parameter DAAL8 = 8'd162;
parameter DAAL9 = 8'd163;
parameter DAAL10 = 8'd164;
parameter DAAL11 = 8'd165;
parameter DAAL12 = 8'd166;
parameter DAAL13 = 8'd167;
parameter DAAL14 = 8'd168;
parameter DAAL15 = 8'd169;
parameter DAAL16 = 8'd170;
parameter DAAL17 = 8'd171;
parameter DT7 = 8'd172;
parameter DT8 = 8'd173;
parameter DT9 = 8'd174;
parameter DT10 = 8'd175;
parameter DAAL7a = 8'd176;
parameter DAAL8a = 8'd177;
parameter DAAL11a = 8'd178;
parameter DAAL12a = 8'd179;
parameter DAAL15a = 8'd180;
parameter DAAL16a = 8'd181;

integer n;
reg [7:0] state = ST_IDLE;
reg [7:0] retstate = ST_IDLE;	// subroutine return
reg [7:0] retstate2 = ST_IDLE;	// subroutine return
reg [7:0] retstate3 = ST_IDLE;
reg [7:0] retstate4 = ST_IDLE;
reg [7:0] ngs = ST_IDLE;		// next graphic state for continue
wire eol;
wire eof;
wire border;
wire blank, vblank;
wire vbl_int;
reg [9:0] vbl_reg;
reg sgLock = 1'b0;
reg [11:0] hTotal = phTotal;
reg [11:0] vTotal = pvTotal;
reg [11:0] hSyncOn = phSyncOn, hSyncOff = phSyncOff;
reg [11:0] vSyncOn = pvSyncOn, vSyncOff = pvSyncOff;
reg [11:0] hBlankOn = phBlankOn, hBlankOff = phBlankOff;
reg [11:0] vBlankOn = pvBlankOn, vBlankOff = pvBlankOff;
reg [11:0] hBorderOn = phBorderOn, hBorderOff = phBorderOff;
reg [11:0] vBorderOn = pvBorderOn, vBorderOff = pvBorderOff;

// Interrupt sources
//    i3210 3210i
// ---aaaaa aaaaarbv
//      |     |  ||+-- vertical blank  
//      |     |  |+--- blitter done
//      |     |  +---- raster
//      |     +------- audio channel low buffer empty
//      +------------- audio channel high buffer empty

reg [15:0] irq_en = 16'h0;
reg [15:0] irq_status;
assign irq_o = |(irq_status & irq_en);

wire [31:0] cap = {27'h000,NSPR[4:0]};

// ctrl
// -b--- rrrr ---- cccc
//  |      |         +-- grpahics command
//  |      +------------ raster op
// +-------------------- busy indicator
reg [15:0] ctrl;
reg [1:0] lowres = 2'b01;
reg [19:0] TargetBase = 20'h00000;		// base address of bitmap
reg [19:0] charBmpBase = 20'h5C000;	// base address of character bitmaps
reg [11:0] hstart = 12'hEFF;		// -261
reg [11:0] vstart = 12'hFE6;		// -41
reg [11:0] hpos;
reg [11:0] vpos;
wire [11:0] vctr;
wire [11:0] hctr;
reg [4:0] fpos;
reg [15:0] TargetWidth = 16'd400;
reg [15:0] TargetHeight = 16'd300;
reg [15:0] borderColor;
wire [15:0] rgb_i;					// internal rgb output from ram

reg [4:0] cmdq_ndx;
reg [`CMDQ_WID-1:0] cmdq_in;
wire [`CMDQ_WID-1:0] cmdq_out;

reg [15:0] clipX0, clipY0, clipX1, clipY1;
reg clipEnable;

reg zbuf;							// z buffer flag
reg [3:0] zlayer;


// Untransformed points
reg [31:0] up0x, up0y, up0z;
reg [31:0] up1x, up1y, up1z;
reg [31:0] up2x, up2y, up2z;
reg [31:0] up0xs, up0ys, up0zs;
reg [31:0] up1xs, up1ys, up1zs;
reg [31:0] up2xs, up2ys, up2zs;
// Points after transform
reg [31:0] p0x, p0y, p0z, p1x, p1y, p1z, p2x, p2y, p2z;

// Point Transform
reg transform, otransform;
reg [31:0] aa, ab, ac, at;
reg [31:0] ba, bb, bc, bt;
reg [31:0] ca, cb, cc, ct;
wire signed [63:0] aax0 = aa * up0x;
wire signed [63:0] aby0 = ab * up0y;
wire signed [63:0] acz0 = ac * up0z;
wire signed [63:0] bax0 = ba * up0x;
wire signed [63:0] bby0 = bb * up0y;
wire signed [63:0] bcz0 = bc * up0z;
wire signed [63:0] cax0 = ca * up0x;
wire signed [63:0] cby0 = cb * up0y;
wire signed [63:0] ccz0 = cc * up0z;
wire signed [63:0] aax1 = aa * up1x;
wire signed [63:0] aby1 = ab * up1y;
wire signed [63:0] acz1 = ac * up1z;
wire signed [63:0] bax1 = ba * up1x;
wire signed [63:0] bby1 = bb * up1y;
wire signed [63:0] bcz1 = bc * up1z;
wire signed [63:0] cax1 = ca * up1x;
wire signed [63:0] cby1 = cb * up1y;
wire signed [63:0] ccz1 = cc * up1z;
wire signed [63:0] aax2 = aa * up2x;
wire signed [63:0] aby2 = ab * up2y;
wire signed [63:0] acz2 = ac * up2z;
wire signed [63:0] bax2 = ba * up2x;
wire signed [63:0] bby2 = bb * up2y;
wire signed [63:0] bcz2 = bc * up2z;
wire signed [63:0] cax2 = ca * up2x;
wire signed [63:0] cby2 = cb * up2y;
wire signed [63:0] ccz2 = cc * up2z;

wire signed [63:0] x0_prime = aax0 + aby0 + acz0 + {at,16'h0000};
wire signed [63:0] y0_prime = bax0 + bby0 + bcz0 + {bt,16'h0000};
wire signed [63:0] z0_prime = cax0 + cby0 + ccz0 + {ct,16'h0000};
wire signed [63:0] x1_prime = aax1 + aby1 + acz1 + {at,16'h0000};
wire signed [63:0] y1_prime = bax1 + bby1 + bcz1 + {bt,16'h0000};
wire signed [63:0] z1_prime = cax1 + cby1 + ccz1 + {ct,16'h0000};
wire signed [63:0] x2_prime = aax2 + aby2 + acz2 + {at,16'h0000};
wire signed [63:0] y2_prime = bax2 + bby2 + bcz2 + {bt,16'h0000};
wire signed [63:0] z2_prime = cax2 + cby2 + ccz2 + {ct,16'h0000};

always @(posedge clk_i)
	p0x <= transform ? x0_prime[47:16] : up0x;
always @(posedge clk_i)
	p0y <= transform ? y0_prime[47:16] : up0y;
always @(posedge clk_i)
	p0z <= transform ? z0_prime[47:16] : up0z;
always @(posedge clk_i)
	p1x <= transform ? x1_prime[47:16] : up1x;
always @(posedge clk_i)
	p1y <= transform ? y1_prime[47:16] : up1y;
always @(posedge clk_i)
	p1z <= transform ? z1_prime[47:16] : up1z;
always @(posedge clk_i)
	p2x <= transform ? x2_prime[47:16] : up2x;
always @(posedge clk_i)
	p2y <= transform ? y2_prime[47:16] : up2y;
always @(posedge clk_i)
	p2z <= transform ? z2_prime[47:16] : up2z;
/*
wire [11:0] x0 = p0x[27:16];
wire [11:0] y0 = p0y[27:16];
wire [11:0] z0 = p0z[27:16];
wire [11:0] x1 = p1x[27:16];
wire [11:0] y1 = p1y[27:16];
wire [11:0] z1 = p1z[27:16];
wire [11:0] x2 = p2x[27:16];
wire [11:0] y2 = p2y[27:16];
wire [11:0] z2 = p2z[27:16];
*/

reg [31:0] maxX, maxY, minX, minY;

// Line draw
reg [13:0] x0,y0,x1,y1,x2,y2;
reg [13:0] x0a,y0a,x1a,y1a,x2a,y2a;
wire signed [31:0] absx1mx0 = (p1x < p0x) ? p0x-p1x : p1x-p0x;
wire signed [31:0] absy1my0 = (p1y < p0y) ? p0y-p1y : p1y-p0y;
reg [15:0] gcx,gcy;		// graphics cursor position
reg [11:0] ppl;
wire [19:0] cyPPL = gcy * TargetWidth;
wire [19:0] offset = cyPPL + gcx;
wire [19:0] ma = TargetBase + offset;
reg signed [15:0] dx,dy;
reg signed [15:0] sx,sy;
reg signed [15:0] err;
wire signed [15:0] e2 = err << 1;
// Anti-aliased
reg steep;
reg [31:0] openColor;
reg [31:0] xend, yend, gradient, xgap;
reg [31:0] xpxl1, ypxl1, xpxl2, ypxl2;
reg [68:0] pixColorR, pixColorG, pixColorB;
reg [31:0] intery;
reg signed [31:0] dxa,dya;

function [31:0] ipart;
input [31:0] nn;
    ipart = {nn[31:16],16'h0000};
endfunction

function [31:0] fpart;
input [31:0] nn;
    fpart = {16'h0,nn[15:0]};
endfunction

function [31:0] rfpart;
input [31:0] nn;
    rfpart = (32'h10000 - fpart(nn));
endfunction

function [31:0] round;
input [31:0] nn;
    round = ipart(nn + 32'h8000); 
endfunction

function [20:0] blend1;
input [4:0] comp;
input [15:0] alpha;
	blend1 = comp * alpha;
endfunction

function [15:0] blend;
input [15:0] color1;
input [15:0] color2;
input [15:0] alpha;
reg [63:0] blend2;
begin
	blend2 =
		{blend1(color1[`R],alpha),blend1(color1[`G],alpha),blend1(color1[`B],alpha)} +
		{blend1(color2[`R],(16'hFFFF-alpha)),
		 blend1(color2[`G],(16'hFFFF-alpha)),
		 blend1(color2[`B],(16'hFFFF-alpha))};
	blend = {blend2[62:58],blend2[41:37],blend2[20:16]};
end
endfunction


// Triangle draw
reg fbt;	// flat bottom=1 or top=0 triangle
reg [7:0] trimd;	// timer for mult
reg [31:0] v0x, v0y, v1x, v1y, v2x, v2y, v3x, v3y;
reg [31:0] w0x, w0y, w1x, w1y, w2x, w2y;
reg signed [31:0] invslope0, invslope1;
reg [31:0] curx0, curx1, cdx, endx;

// Bezier Curves
reg [1:0] fillCurve;
reg [31:0] bv0x, bv0y, bv1x, bv1y, bv2x, bv2y;
reg [31:0] bezierT, bezier1mT, bezierInc = 32'h0100;
reg [63:0] bezier1mTP0xw, bezier1mTP1xw;
reg [63:0] bezier1mTP0yw, bezier1mTP1yw;
reg [63:0] bezierTP1x, bezierTP2x;
reg [63:0] bezierTP1y, bezierTP2y;
reg [31:0] bezierP0plusP1x, bezierP1plusP2x;
reg [31:0] bezierP0plusP1y, bezierP1plusP2y;
reg [63:0] bezierBxw, bezierByw;

reg [5:0] flashcnt;

// Cursor related registers
reg [31:0] collision;
reg cursor;
reg [31:0] cursorEnable;
reg [31:0] cursorActive;
reg [11:0] cursor_pv [0:31];
reg [11:0] cursor_ph [0:31];
reg [3:0] cursor_pz [0:31];
reg [9:0] cya [0:31];
reg [31:0] cursor_color [0:63];
reg [31:0] cursor_on;
reg [31:0] cursor_on_d1;
reg [31:0] cursor_on_d2;
reg [31:0] cursor_on_d3;
reg [19:0] cursorAddr [0:31];
reg [19:0] cursorWaddr [0:31];
reg [15:0] cursorMcnt [0:31];
reg [15:0] cursorWcnt [0:31];
reg [63:0] cursorBmp [0:31];
reg [15:0] cursorColor [0:31];
reg [31:0] cursorLink1;
reg [31:0] cursorLink2;
reg [5:0] cursorColorNdx [0:31];
reg [9:0] cursor_szv [0:31];
reg [5:0] cursor_szh [0:31];

reg [18:0] rdndx;					// video read index
reg [18:0] lndx;					// line index
wire rdce = ~vblank;
reg [18:0] ram_addr;
reg [15:0] ram_data_i;
wire [15:0] ram_data_o;
wire [15:0] zbram_data_o;
reg ram_ce;
reg [1:0] ram_we;
reg [1:0] zbram_we;

reg [19:0] font_tbl_adr;			// address of the font table
reg [15:0] font_id;
reg font_fixed;						// 1 = fixed width font
reg [4:0] font_height;
reg [4:0] font_width;
reg [19:0] glyph_tbl_adr;			// address of the glyph table
reg [31:0] charBoxX0, charBoxX1, charBoxY0, charBoxY1;

reg [9:0] pixcnt;
reg [4:0] pixhc,pixvc;
reg [3:0] bitcnt, bitinc;

reg [19:0] bltSrcWid;
reg [19:0] bltDstWid;
reg [19:0] bltCount;
//  ch  321033221100       
//  TBDzddddebebebeb
//  |||   |       |+- bitmap mode
//  |||   |       +-- channel enabled
//  |||   +---------- direction 0=normal,1=decrement
//  ||+-------------- done indicator
//  |+--------------- busy indicator
//  +---------------- trigger bit
reg [15:0] bltCtrl;
reg [15:0] bltA_shift, bltB_shift, bltC_shift;
reg [15:0] bltLWMask = 16'hFFFF;
reg [15:0] bltFWMask = 16'hFFFF;

reg [19:0] bltA_badr;               // base address
reg [19:0] bltA_mod;                // modulo
reg [19:0] bltA_cnt;
reg [19:0] bltA_wadr;				// working address
reg [19:0] bltA_wcnt;				// working count
reg [19:0] bltA_dcnt;				// working count
reg [19:0] bltA_hcnt;

reg [19:0] bltB_badr;
reg [19:0] bltB_mod;
reg [19:0] bltB_cnt;
reg [19:0] bltB_wadr;				// working address
reg [19:0] bltB_wcnt;				// working count
reg [19:0] bltB_dcnt;				// working count
reg [19:0] bltB_hcnt;

reg [19:0] bltC_badr;
reg [19:0] bltC_mod;
reg [19:0] bltC_cnt;
reg [19:0] bltC_wadr;				// working address
reg [19:0] bltC_wcnt;				// working count
reg [19:0] bltC_dcnt;				// working count
reg [19:0] bltC_hcnt;

reg [19:0] bltD_badr;
reg [19:0] bltD_mod;
reg [19:0] bltD_cnt;
reg [19:0] bltD_wadr;				// working address
reg [19:0] bltD_wcnt;				// working count
reg [19:0] bltD_hcnt;

reg [15:0] blt_op;

//     i3210   31 i3210
// -t- rrrrr p mm eeeee
//  |    |   |  |   +--- channel enables
//  |    |   |  +------- mix channels 1 into 0, 3 into 2
//  |    |   +---------- input plot mode
//  |    +-------------- chennel reset
//  +------------------- test mode
//
// The channel needs to be reset for use as this loads the working address
// register with the audio sample base address.
//
reg [15:0] aud_ctrl;
wire aud_mix1 = aud_ctrl[5];
wire aud_mix3 = aud_ctrl[6];
//
//           3210 3210
// ---- ---- -fff -aaa
//             |    +--- amplitude modulate next channel
//             +-------- frequency modulate next channel
//
reg [15:0] aud_ctrl2;
reg [19:0] aud0_adr;
reg [15:0] aud0_length;
reg [15:0] aud0_period;
reg [15:0] aud0_volume;
reg signed [15:0] aud0_dat;
reg signed [15:0] aud0_dat2;		// double buffering
reg [19:0] aud1_adr;
reg [15:0] aud1_length;
reg [15:0] aud1_period;
reg [15:0] aud1_volume;
reg signed [15:0] aud1_dat;
reg signed [15:0] aud1_dat2;
reg [19:0] aud2_adr;
reg [15:0] aud2_length;
reg [15:0] aud2_period;
reg [15:0] aud2_volume;
reg signed [15:0] aud2_dat;
reg signed [15:0] aud2_dat2;
reg [19:0] aud3_adr;
reg [15:0] aud3_length;
reg [15:0] aud3_period;
reg [15:0] aud3_volume;
reg signed [15:0] aud3_dat;
reg signed [15:0] aud3_dat2;
reg [19:0] audi_adr;
reg [19:0] audi_length;
reg [15:0] audi_period;
reg signed [15:0] audi_dat;

// May need to set the pipeline depth to zero if copying neighbouring pixels
// during a blit. So the app is allowed to control the pipeline depth. Depth
// should not be set >28.
reg [4:0] bltPipedepth = 5'd15;
reg [19:0] bltinc;
reg [4:0] bltAa,bltBa,bltCa;
reg wrA, wrB, wrC;
reg [15:0] blt_bmpA;
reg [15:0] blt_bmpB;
reg [15:0] blt_bmpC;
reg [15:0] bltA_residue;
reg [15:0] bltB_residue;
reg [15:0] bltC_residue;
reg [15:0] bltD_residue;

wire [15:0] bltA_out, bltB_out, bltC_out;
wire [15:0] bltA_out1, bltB_out1, bltC_out1;
reg  [15:0] bltA_dat, bltB_dat, bltC_dat, bltD_dat;
// Convert an input bit into a color (black or white) to allow use as a mask.
wire [15:0] bltA_in = bltCtrl[0] ? (blt_bmpA[bitcnt] ? 16'h7FFF : 16'h0000) : blt_bmpA;
wire [15:0] bltB_in = bltCtrl[2] ? (blt_bmpB[bitcnt] ? 16'h7FFF : 16'h0000) : blt_bmpB;
wire [15:0] bltC_in = bltCtrl[4] ? (blt_bmpC[bitcnt] ? 16'h7FFF : 16'h0000) : blt_bmpC;
// If the channel is disabled use the dat registers as the source of data.
assign bltA_out = bltCtrl[1] ? bltA_out1 : bltA_dat;
assign bltB_out = bltCtrl[3] ? bltB_out1 : bltB_dat;
assign bltC_out = bltCtrl[5] ? bltC_out1 : bltC_dat;

reg [1:0] copper_op;
reg copper_b;
reg [3:0] copper_f, copper_mf;
reg [11:0] copper_h, copper_v;
reg [11:0] copper_mh, copper_mv;
reg copper_go;
reg [15:0] copper_ctrl;
wire copper_en = copper_ctrl[0];
reg [63:0] copper_ir;
reg [19:0] copper_pc;
reg [1:0] copper_state;
reg [19:0] copper_adr [0:15];
reg reg_copper;

reg srstA, srstB, srstC;
reg bltRdf;

// Intermediate hold registers
reg [19:0] tgtaddr;					// upper left corner of target in bitmap
reg [19:0] tgtindex;				// indexing of pixel from target address point
reg [4:0] loopcnt;
reg [15:0] charcode;                // character code being processed
reg [31:0] charbmp;					// hold character bitmap scanline
reg [15:0] fgcolor;					// character colors
reg [31:0] penColor;					// top bit indicates overlay mode
reg [31:0] fillColor;
reg [3:0] pixxm, pixym;             // maximum # pixels for char

reg ack,rdy,rdy2;
reg rwsr;							// read / write shadow ram
wire chrp = rdy & ~rdy2;			// chrq pulse
wire cs_reg = cyc_i & stb_i & cs_i;
wire cs_ram = cyc_i & stb_i & cs_ram_i;


VGASyncGen usg1
(
	.rst(rst_i),
	.clk(clk),
	.eol(eol),
	.eof(eof),
	.hSync(hSync),
	.vSync(vSync),
	.hCtr(hctr),
	.vCtr(vctr),
    .blank(blank),
    .vblank(vblank),
    .vbl_int(vbl_int),
    .border(border),
    .hTotal_i(hTotal),
    .vTotal_i(vTotal),
    .hSyncOn_i(hSyncOn),
    .hSyncOff_i(hSyncOff),
    .vSyncOn_i(vSyncOn),
    .vSyncOff_i(vSyncOff),
    .hBlankOn_i(hBlankOn),
    .hBlankOff_i(hBlankOff),
    .vBlankOn_i(vBlankOn),
    .vBlankOff_i(vBlankOff),
    .hBorderOn_i(hBorderOn),
    .hBorderOff_i(hBorderOff),
    .vBorderOn_i(vBorderOn),
    .vBorderOff_i(vBorderOff)
);

wire [7:0] zbx2_i;
reg [3:0] zb_i;
wire [18:0] P0, P1, P2;

multRndx umul0 (
  .CLK(clk),
  .A(vpos),
  .B(TargetWidth),
  .P(P0)
);
multRndx umul1 (
  .CLK(clk),
  .A({1'b0,vpos[11:1]}),
  .B(TargetWidth),
  .P(P1)
);
multRndx umul2 (
  .CLK(clk),
  .A({2'b00,vpos[11:2]}),
  .B(TargetWidth),
  .P(P2)
);

reg div_ld;
reg signed [31:0] div_a, div_b;
wire signed [63:0] div_qo;
wire div_idle;

AVDivider #(.WID(64)) udiv1
(
	.rst(rst_i),
	.clk(clk_i),
	.ld(div_ld),
	.abort(1'b0),
	.sgn(1'b1),
	.sgnus(1'b0),
	.a({{16{div_a[31]}},div_a,16'h0}),
	.b({{32{div_b[31]}},div_b}),
	.qo(div_qo),
	.ro(),
	.dvByZr(),
	.done(),
	.idle(div_idle)
);

wire [63:0] trimult;
AVTriMult umul3
(
  .CLK(clk_i),
  .A(div_qo[31:0]),
  .B(v2x-v0x),
  .P(trimult)
);

chipram16 chipram1
(
	.clka(clk_i),
	.ena(ram_ce),
	.wea(ram_we),
	.addra(ram_addr),
	.dina(ram_data_i),
	.douta(ram_data_o),
	.clkb(clk),
	.enb(rdce),
	.web(1'b0),
	.addrb(rdndx),
	.dinb(16'h0000),
	.doutb(rgb_i)
);

zbram uzbram1
(
	.clka(clk_i),
	.ena(ram_ce),
	.wea(zbram_we),
	.addra(ram_addr),
	.dina(ram_data_i),
	.douta(zbram_data_o),
	.clkb(clk),
	.enb(rdce),
	.web(1'b0),
	.addrb(rdndx[18:3]),
	.dinb(2'h00),
	.doutb(zbx2_i)
);
always @*
	zb_i <= {zbx2_i >> rdndx[2:0],1'b0};
    
vtdl #(.WID(16), .DEP(32)) bltA (.clk(clk_i), .ce(wrA), .a(bltAa), .d(bltA_in), .q(bltA_out1));
vtdl #(.WID(16), .DEP(32)) bltB (.clk(clk_i), .ce(wrB), .a(bltBa), .d(bltB_in), .q(bltB_out1));
vtdl #(.WID(16), .DEP(32)) bltC (.clk(clk_i), .ce(wrC), .a(bltCa), .d(bltC_in), .q(bltC_out1));

reg [15:0] bltab;
reg [15:0] bltabc;

// Perform alpha blending between the two colors.
wire [12:0] blndR = (bltB_out[`R] * bltA_out[7:0]) + (bltC_out[`R])*(8'hFF-bltA_out[7:0]);
wire [12:0] blndG = (bltB_out[`G] * bltA_out[7:0]) + (bltC_out[`G])*(8'hFF-bltA_out[7:0]);
wire [12:0] blndB = (bltB_out[`B] * bltA_out[7:0]) + (bltC_out[`B])*(8'hFF-bltA_out[7:0]);

always @*
	case(blt_op[3:0])
	4'h1:	bltab <= bltA_out;
	4'h2:	bltab <= bltB_out;
	4'h3:	bltab <= ~bltA_out;
	4'h4:	bltab <= ~bltB_out;
	4'h8:	bltab <= bltA_out & bltB_out;
	4'h9:	bltab <= bltA_out | bltB_out;
	4'hA:	bltab <= bltA_out ^ bltB_out;
	4'hB:	bltab <= bltA_out & ~bltB_out;
	4'hF:	bltab <= `WHITE;
	default:bltab <= `BLACK;
	endcase
always @*
	case(blt_op[7:4])
	4'h1:	bltabc <= bltab;
	4'h2:	bltabc <= bltC_out;
	4'h3:	if (bltab[`A]) begin
				bltabc[`R] <= bltC_out[`R] >> bltab[2:0];
				bltabc[`G] <= bltC_out[`G] >> bltab[5:3];
				bltabc[`B] <= bltC_out[`B] >> bltab[8:6];
			end
			else
				bltabc <= bltab;
	4'h4:	bltabc <= {blndR[12:8],blndG[12:8],blndB[12:8]};
	4'h7:   bltabc <= (bltC_out & ~bltB_out) | bltA_out; 
	4'h8:	bltabc <= bltab & bltC_out;
	4'h9:	bltabc <= bltab | bltC_out;
	4'hA:	bltabc <= bltab ^ bltC_out;
	4'hB:	bltabc <= bltab & ~bltC_out;
	4'hF:	bltabc <= `WHITE;
	default:bltabc <= `BLACK;
	endcase

wire [28:0] cmppos = {fpos,vpos,hpos} & {copper_mf,copper_mv,copper_mh};

reg [15:0] rasti_en [0:63];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// RGB output display side
// clk clock domain
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// widen vertical blank interrupt pulse
always @(posedge clk)
	if (vbl_int)
		vbl_reg <= 10'h3FF;
	else
		vbl_reg <= {vbl_reg[8:0],1'b0};

always @(posedge clk)
	if (eol)
		hpos <= hstart;
	else
		hpos <= hpos + 12'd1;

always @(posedge clk)
	if (eol) begin
		if (eof)
			vpos <= vstart;
		else
			vpos <= vpos + 12'd1;
	end

always @(posedge clk)
	if (eol & eof) begin
		fpos <= fpos + 5'd1;
		flashcnt <= flashcnt + 6'd1;
	end

// Compute display ram index
always @(posedge clk)
begin
    casez({lowres,hpos})
    14'b??_1111_0011_1101: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0100_0001: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0100_0101: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0100_1001: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0100_1101: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0101_0001: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0101_0101: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0101_1001: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0101_1101: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0110_0001: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0110_0101: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0110_1001: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0110_1101: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0111_0001: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0111_0101: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0111_1001: rdndx <= cursorWaddr[{1'b0,hpos[5:2]}+5'd1];
    14'b??_1111_0111_1101: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1000_0001: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1000_0101: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1000_1001: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1000_1101: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1001_0001: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1001_0101: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1001_1001: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1001_1101: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1010_0001: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1010_0101: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1010_1001: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1010_1101: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1011_0001: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1011_0101: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b??_1111_1011_1001: rdndx <= cursorWaddr[{1'b1,hpos[5:2]}+5'd1];
    14'b00_1111_1111_1101: rdndx <= P0 + TargetBase;	// Px = vertical pos * bitmap width (above)
    14'b01_1111_1111_1101: rdndx <= P1 + TargetBase;
    14'b10_1111_1111_1101: rdndx <= P2 + TargetBase;
    14'b00_1111_1111_1110: rdndx <= rdndx + 20'd1;
    14'b00_1111_1111_1111: rdndx <= rdndx + 20'd1;
    14'b??_1111_1111_1111: rdndx <= rdndx + 20'd1;
    14'b??_1111_????_????: rdndx <= rdndx + 20'd1;	// <- indrement for sprite addressing
    14'b00_????_????_????: rdndx <= rdndx + 20'd1;
    14'b01_????_????_???1: rdndx <= rdndx + 20'd1;
    14'b10_????_????_??11: rdndx <= rdndx + 20'd1;
    //14'b10_????_????_??11: rdndx <= rdndx + 20'd1;
    default:    ;	// don't change rdndx
    endcase
end

/*    
    			if (hpos[11:8]==4'hF)	// sprite data load
                    rdndx <= rdndx + 20'd1;
                else casez({lowres,hpos[1:0]})
	                4'b00??: rdndx <= rdndx + 20'd1;
	                4'b01?1: rdndx <= rdndx + 20'd1;
	                4'b1011: rdndx <= rdndx + 20'd1;
	                default:	rdndx <= rdndx;
	            	endcase
*/
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #-1
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Compute when to shift cursor bitmaps.
// Set cursor active flag
// Increment working count and address

reg [31:0] cursorShift;
always @(posedge clk)
    for (n = 0; n < NSPR; n = n + 1)
    begin
        cursorShift[n] <= `FALSE;
	    case(lowres)
	    2'd0,2'd3:	if (hctr >= cursor_ph[n]) cursorShift[n] <= `TRUE;
		2'd1:		if (hctr[11:1] >= cursor_ph[n]) cursorShift[n] <= `TRUE;
		2'd2:		if (hctr[11:2] >= cursor_ph[n]) cursorShift[n] <= `TRUE;
		endcase
	end

always @(posedge clk)
    for (n = 0; n < NSPR; n = n + 1)
		cursorActive[n] = (cursorWcnt[n] < cursorMcnt[n]) && cursorEnable[n];

always @(posedge clk)
    for (n = 0; n < NSPR; n = n + 1)
	begin
	    case(lowres)
	    2'd0,2'd3:	if ((vctr == cursor_pv[n]) && (hctr == 12'h005)) cursorWcnt[n] <= 16'd0;
		2'd1:		if ((vctr[11:1] == cursor_pv[n]) && (hctr == 12'h005)) cursorWcnt[n] <= 16'd0;
		2'd2:		if ((vctr[11:2] == cursor_pv[n]) && (hctr == 12'h005)) cursorWcnt[n] <= 16'd0;
		endcase
		if (hpos==12'hFF8)	// must be after image data fetch
    		if (cursorActive[n])
    		case(lowres)
    		2'd0,2'd3:	cursorWcnt[n] <= cursorWcnt[n] + cursor_szh[n];
    		2'd1:		if (vctr[0]) cursorWcnt[n] <= cursorWcnt[n] + cursor_szh[n];
    		2'd2:		if (vctr[1:0]==2'b11) cursorWcnt[n] <= cursorWcnt[n] + cursor_szh[n];
    		endcase
	end

always @(posedge clk)
    for (n = 0; n < NSPR; n = n + 1)
	begin
	    case(lowres)
	    2'd0,2'd3:	if ((vctr == cursor_pv[n]) && (hctr == 12'h005)) cursorWaddr[n] <= cursorAddr[n];
		2'd1:		if ((vctr[11:1] == cursor_pv[n]) && (hctr == 12'h005)) cursorWaddr[n] <= cursorAddr[n];
		2'd2:		if ((vctr[11:2] == cursor_pv[n]) && (hctr == 12'h005)) cursorWaddr[n] <= cursorAddr[n];
		endcase
		if (hpos==12'hFF8)	// must be after image data fetch
		case(lowres)
   		2'd0,2'd3:	cursorWaddr[n] <= cursorWaddr[n] + 20'd4;
   		2'd1:		if (vctr[0]) cursorWaddr[n] <= cursorWaddr[n] + 20'd4;
   		2'd2:		if (vctr[1:0]==2'b11) cursorWaddr[n] <= cursorWaddr[n] + 20'd4;
   		endcase
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #0
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Get the cursor display status
// Load the cursor bitmap from ram
// Determine when cursor output should appear
// Shift the cursor bitmap
// Compute color indexes for all sprites

always @(posedge clk)
begin
    for (n = 0; n < NSPR; n = n + 1)
        if (cursorActive[n] & cursorShift[n]) begin
            cursor_on[n] <=
                cursorLink2[n] ? |{ cursorBmp[(n+2)&31][63:62],cursorBmp[(n+1)&31][63:62],cursorBmp[n][63:62]} :
                cursorLink1[n] ? |{ cursorBmp[(n+1)&31][63:62],cursorBmp[n][63:62]} : 
                |cursorBmp[n][63:62];
        end
        else
            cursor_on[n] <= 1'b0;
end

// Load / shift cursor bitmap
always @(posedge clk)
begin
    casez(hpos)
    12'b1111_01??_??00: cursorBmp[{1'b0,hpos[5:2]}][63:48] <= rgb_i;
    12'b1111_01??_??01: cursorBmp[{1'b0,hpos[5:2]}][47:32] <= rgb_i;
    12'b1111_01??_??10: cursorBmp[{1'b0,hpos[5:2]}][31:16] <= rgb_i;
    12'b1111_01??_??11: cursorBmp[{1'b0,hpos[5:2]}][15:0] <= rgb_i;
    12'b1111_10??_??00: cursorBmp[{1'b1,hpos[5:2]}][63:48] <= rgb_i;
    12'b1111_10??_??01: cursorBmp[{1'b1,hpos[5:2]}][47:32] <= rgb_i;
    12'b1111_10??_??10: cursorBmp[{1'b1,hpos[5:2]}][31:16] <= rgb_i;
    12'b1111_10??_??11: cursorBmp[{1'b1,hpos[5:2]}][15:0] <= rgb_i;
    endcase
    for (n = 0; n < NSPR; n = n + 1)
        if (cursorShift[n])
            cursorBmp[n] <= {cursorBmp[n][61:0],2'b00};
end

always @(posedge clk)
for (n = 0; n < NSPR; n = n + 1)
if (cursorLink2[n])
    cursorColorNdx[n] <= {cursorBmp[(n+2)&31][63:62],cursorBmp[(n+1)&31][63:62],cursorBmp[n][63:62]};
else if (cursorLink1[n])
    cursorColorNdx[n] <= {n[3:2],cursorBmp[(n+1)&31][63:62],cursorBmp[n][63:62]};
else
    cursorColorNdx[n] <= {n[3:0],cursorBmp[n][63:62]};

// Compute index into sprite color palette
// If none of the sprites are linked, each sprite has it's own set of colors.
// If the sprites are linked once the colors are available in groups.
// If the sprites are linked twice they all share the same set of colors.
// Pipelining register
reg blank1, blank2, blank3, blank4;
reg border1, border2, border3, border4;
reg any_cursor_on2, any_cursor_on3, any_cursor_on4;
reg [14:0] rgb_i3, rgb_i4;
reg [3:0] zb_i3, zb_i4;
reg [3:0] cursor_z1, cursor_z2, cursor_z3, cursor_z4;
reg [3:0] cursor_pzx;
// The color index from each sprite can be mux'ed into a single value used to
// access the color palette because output color is a priority chain. This
// saves having mulriple read ports on the color palette.
reg [31:0] cursorColorOut2; 
reg [31:0] cursorColorOut3;
reg [5:0] cursorClrNdx;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #1
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Mux color index
// Fetch cursor Z order

always @(posedge clk)
    cursor_on_d1 <= cursor_on;
always @(posedge clk)
    blank1 <= blank;
always @(posedge clk)
    border1 <= border;

always @(posedge clk)
begin
	cursorClrNdx <= 6'd0;
	for (n = NSPR-1; n >= 0; n = n -1)
		if (cursor_on[n])
			cursorClrNdx <= cursorColorNdx[n];
end
        
always @(posedge clk)
begin
	cursor_z1 <= 4'hF;
	for (n = NSPR-1; n >= 0; n = n -1)
		if (cursor_on[n])
			cursor_z1 <= cursor_pz[n]; 
end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #2
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Lookup color from palette

always @(posedge clk)
    cursor_on_d2 <= cursor_on_d1;
always @(posedge clk)
    any_cursor_on2 <= |cursor_on_d1;
always @(posedge clk)
    blank2 <= blank1;
always @(posedge clk)
    border2 <= border1;
always @(posedge clk)
    cursorColorOut2 <= cursor_color[cursorClrNdx];
always @(posedge clk)
    cursor_z2 <= cursor_z1;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #3
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Compute alpha blending

wire [12:0] alphaRed = (rgb_i[`R] * cursorColorOut2[31:24]) + (cursorColorOut2[`R] * (9'h100 - cursorColorOut2[31:24]));
wire [12:0] alphaGreen = (rgb_i[`G] * cursorColorOut2[31:24]) + (cursorColorOut2[`G]  * (9'h100 - cursorColorOut2[31:24]));
wire [12:0] alphaBlue = (rgb_i[`B] * cursorColorOut2[31:24]) + (cursorColorOut2[`B]  * (9'h100 - cursorColorOut2[31:24]));
reg [14:0] alphaOut;

always @(posedge clk)
    alphaOut <= {alphaRed[12:8],alphaGreen[12:8],alphaBlue[12:8]};
always @(posedge clk)
    cursor_z3 <= cursor_z2;
always @(posedge clk)
    any_cursor_on3 <= any_cursor_on2;
always @(posedge clk)
    rgb_i3 <= rgb_i;
always @(posedge clk)
    zb_i3 <= zb_i;
always @(posedge clk)
    blank3 <= blank2;
always @(posedge clk)
    border3 <= border2;
always @(posedge clk)
    cursorColorOut3 <= cursorColorOut2;

reg [14:0] flashOut;
wire [14:0] reverseVideoOut = cursorColorOut2[21] ? alphaOut ^ 15'h7FFF : alphaOut;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #4
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Compute flash output

always @(posedge clk)
    flashOut <= cursorColorOut3[20] ? (((flashcnt[5:2] & cursorColorOut3[19:16])!=4'b000) ? reverseVideoOut : rgb_i3) : reverseVideoOut;
always @(posedge clk)
    rgb_i4 <= rgb_i3;
always @(posedge clk)
    cursor_z4 <= cursor_z3;
always @(posedge clk)
    any_cursor_on4 <= any_cursor_on3;
always @(posedge clk)
    zb_i4 <= zb_i3;
always @(posedge clk)
    blank4 <= blank3;
always @(posedge clk)
    border4 <= border3;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #5
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// final output registration

always @(posedge clk)
	casez({blank4,border4,any_cursor_on4})
	3'b1??:		rgb <= 15'h0000;
	3'b01?:		rgb <= borderColor;
	3'b001:		rgb <= ((zb_i4 < cursor_z4) ? rgb_i4 : flashOut);
	3'b000:		rgb <= rgb_i4;
	endcase
always @(posedge clk)
    blank_o <= blank4;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Command queue
// clk_i clock domain
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg bltDone1;
reg reg_cs;
reg reg_we;
reg [10:0] reg_adr;
reg [15:0] reg_dat;

//wire cs_cmdq = cs_reg && adr_i[10:1]==10'b100_0010_111 && chrp && we_i;
wire cs_cmdq = reg_cs && reg_adr[10:1]==10'b100_0100_100 && chrp && reg_we;


vtdl #(.WID(`CMDQ_WID), .DEP(`CMDQ_DEP)) char_q (.clk(clk_i), .ce(cs_cmdq), .a(cmdq_ndx), .d(cmdq_in), .q(cmdq_out));
/*
wire [8:0] charcode_qo = cmdq_out[`CHARCODE];
wire [15:0] charfg_qo = cmdq_out[`FGCOLOR];
wire [15:0] charbk_qo = cmdq_out[`BKCOLOR];
wire [11:0] cmdx1_qo = cmdq_out[`X0POS];
wire [11:0] cmdy1_qo = cmdq_out[`Y0POS];
wire [3:0] charxm_qo = cmdq_out[`CHARXM];
wire [3:0] charym_qo = cmdq_out[`CHARYM];
wire [7:0] cmd_qo = cmdq_out[`CMD];
wire [11:0] cmdx2_qo = cmdq_out[`X1POS];
wire [11:0] cmdy2_qo = cmdq_out[`Y1POS];
wire [11:0] cmdx3_qo = cmdq_out[`X2POS];
wire [11:0] cmdy3_qo = cmdq_out[`Y2POS];
*/
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Audio
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [23:0] aud_test;
reg [19:0] aud0_wadr, aud1_wadr, aud2_wadr, aud3_wadr, audi_wadr;
reg [19:0] ch0_cnt, ch1_cnt, ch2_cnt, ch3_cnt, chi_cnt;
// The request counter keeps track of the number of times a request was issued
// without being serviced. There may be the occasional request missed by the
// timing budget. The counter allows the sample to remain on-track and in
// sync with other samples being read.
reg [5:0] aud0_req, aud1_req, aud2_req, aud3_req, audi_req;
// The following request signals pulse for 1 clock cycle only.
reg aud0_req2, aud1_req2, aud2_req2, aud3_req2, audi_req2;

always @(posedge clk_i)
	if (ch0_cnt>=aud0_period || aud_ctrl[8])
		ch0_cnt <= 20'd1;
	else if (aud_ctrl[0])
		ch0_cnt <= ch0_cnt + 20'd1;
always @(posedge clk_i)
	if (ch1_cnt>= aud1_period || aud_ctrl[9])
		ch1_cnt <= 20'd1;
	else if (aud_ctrl[1])
		ch1_cnt <= ch1_cnt + (aud_ctrl2[4] ? aud0_out[15:8] + 20'd1 : 20'd1);
always @(posedge clk_i)
	if (ch2_cnt>= aud2_period || aud_ctrl[10])
		ch2_cnt <= 20'd1;
	else if (aud_ctrl[2])
		ch2_cnt <= ch2_cnt + (aud_ctrl2[5] ? aud1_out[15:8] + 20'd1 : 20'd1);
always @(posedge clk_i)
	if (ch3_cnt>= aud3_period || aud_ctrl[11])
		ch3_cnt <= 20'd1;
	else if (aud_ctrl[3])
		ch3_cnt <= ch3_cnt + (aud_ctrl2[6] ? aud2_out[15:8] + 20'd1 : 20'd1);
always @(posedge clk_i)
	if (chi_cnt>=audi_period || aud_ctrl[12])
		chi_cnt <= 20'd1;
	else if (aud_ctrl[4])
		chi_cnt <= chi_cnt + 20'd1;

// Double buffering to eliminate "jitter" distortion
always @(posedge clk_i)
	if (aud0_req2)
		aud0_dat2 <= aud0_dat;
always @(posedge clk_i)
	if (aud1_req2)
		aud1_dat2 <= aud1_dat;
always @(posedge clk_i)
	if (aud2_req2)
		aud2_dat2 <= aud2_dat;
always @(posedge clk_i)
	if (aud3_req2)
		aud3_dat2 <= aud3_dat;
	
wire signed [31:0] aud1_tmp;
wire signed [31:0] aud0_tmp = aud_mix1 ? ((aud0_dat2 * aud0_volume + aud1_tmp) >> 1): aud0_dat2 * aud0_volume;
wire signed [31:0] aud3_tmp;
wire signed [31:0] aud2_dat3 = aud_ctrl2[1] ? aud2_dat2 * aud2_volume * aud1_dat2 : aud2_dat2 * aud2_volume;
wire signed [31:0] aud2_tmp = aud_mix3 ? ((aud2_dat3 + aud3_tmp) >> 1): aud2_dat3;

assign aud1_tmp = aud_ctrl2[0] ? aud1_dat2 * aud1_volume * aud0_dat2 : aud1_dat2 * aud1_volume;
assign aud3_tmp = aud_ctrl2[2] ? aud3_dat2 * aud3_volume * aud2_dat2 : aud3_dat2 * aud3_volume;
					

always @(posedge clk_i)
begin
	aud0_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[0] ? aud0_tmp >> 16 : 16'h0000;
	aud1_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[1] ? aud1_tmp >> 16 : 16'h0000;
	aud2_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[2] ? aud2_tmp >> 16 : 16'h0000;
	aud3_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[3] ? aud3_tmp >> 16 : 16'h0000;
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg wrtx;
reg [8:0] hwTexture;	// write texture handle
reg [8:0] hrTexture;
reg [75:0] TextureDesc [0:511];
always @(posedge clk_i)
	if (wrtx)
		TextureDesc[hwTexture] <= { 16'hFFFF
		/*
			cmdq_out[`TXMOD],
			cmdq_out[`TXWIDTH],
			cmdq_out[`TXCOUNT],
			cmdq_out[`BASEADRH],
			cmdq_out[`BASEADRL]
		*/
		};
wire [75:0] TextureDesco = TextureDesc[hrTexture];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [15:0] shadow_ram [0:1023];		// register shadow ram
wire [15:0] srdo;					// shadow ram data out
always @(posedge clk_i)
	if ((reg_cs|reg_copper) & reg_we)
		shadow_ram[reg_adr[10:1]] <= reg_dat;
assign srdo = shadow_ram[reg_adr[10:1]];

always @(posedge clk_i)
	rwsr <= cs_reg & ~reg_copper;
always @(posedge clk_i)
	rdy <= rwsr & cs_reg & ~reg_copper;
always @(posedge clk_i)
	rdy2 <= rdy & cs_reg & ~reg_copper;
always @*	//(posedge clk_i)
	ack_o <= cs_ram_i ? ack : cs_i ? rdy2 : pAckStyle;

// Widen the eof pulse so it can be seen by clk_i
reg [11:0] vrst;
always @(posedge clk)
	if (eof)
		vrst <= 12'hFFF;
	else
		vrst <= {vrst[10:0],1'b0};

wire pe_vbl;
edge_det ued1 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(vbl_reg), .pe(pe_vbl), .ne(), .ee());

always @(posedge clk_i)
if (rst_i) begin
	state <= ST_IDLE;
	aud_test <= 24'h0;
	bltCtrl <= 16'b0010_0000_0000_0000;
	ctrl <= 16'h0000;
	ack <= pAckStyle;
end
else begin
div_ld <= `FALSE;
reg_copper <= `FALSE;
reg_cs <= cs_reg;
reg_we <= we_i;
reg_adr <= adr_i[10:0];
reg_dat <= dat_i;
if (reg_cs|reg_copper) begin
	if (reg_we) begin
		casez(reg_adr[10:1])
		10'b000??????0:   cursor_color[reg_adr[7:2]][31:16] <= reg_dat;
		10'b000??????1:   cursor_color[reg_adr[7:2]][15:0] <= reg_dat;
		10'b0010000000:   cursorLink1[31:16] <= reg_dat;
		10'b0010000001:   cursorLink1[15:0] <= reg_dat;
		10'b0010000010:   cursorLink2[31:16] <= reg_dat;
		10'b0010000011:   cursorLink2[15:0] <= reg_dat;
		10'b0010000100:   cursorEnable[31:16] <= reg_dat;
		10'b0010000101:   cursorEnable[15:0] <= reg_dat;
		10'b0010000110:   collision[31:16] <= reg_dat;
		10'b0010000111:   collision[15:0] <= reg_dat;
        10'b01?_????_000:   cursorAddr[reg_adr[8:4]][19:16] <= reg_dat[3:0];
        10'b01?_????_001:   cursorAddr[reg_adr[8:4]][15:0] <= reg_dat;
        10'b01?_????_010:   cursor_ph[reg_adr[8:4]] <= reg_dat[11:0];
        10'b01?_????_011:   cursor_pv[reg_adr[8:4]] <= reg_dat[11:0];
        10'b01?_????_100:   begin
                                cursor_szh[reg_adr[8:4]] <= {1'b0,reg_dat[4:0]} + 6'd1;
                                cursor_szv[reg_adr[8:4]] <= reg_dat[15:6];
                            end
        10'b01?_????_101:	cursor_pz[reg_adr[8:4]] <= reg_dat[3:0];
        10'b01?_????_110:	cursorMcnt[reg_adr[8:4]] <= reg_dat;

		10'b100_0000_000:	TargetBase[19:16] <= reg_dat[3:0];
		10'b100_0000_001:	TargetBase[15:0] <= reg_dat;
        10'b100_0000_011:   TargetWidth <= reg_dat;
        10'b100_0000_101:	TargetHeight <= reg_dat;

		10'b100_0001_000:	font_tbl_adr[19:16] <= reg_dat[3:0];
		10'b100_0001_001:	font_tbl_adr[15:0] <= reg_dat;
		10'b100_0001_010:	font_id <= reg_dat;
/*
	 	10'b100_0010_000:	cmdq_in[`CHARCODE] <= reg_dat[8:0];	// char code
		10'b100_0010_001:	cmdq_in[`FGCOLOR] <= reg_dat;	// fgcolor
		10'b100_0010_010:	cmdq_in[`BKCOLOR] <= reg_dat;	// penColor
		10'b100_0010_011:	cmdq_in[`X0POS] <= reg_dat[11:0];	// xpos1
		10'b100_0010_100:	cmdq_in[`Y0POS] <= reg_dat[11:0];	// ypos1
		10'b100_0010_101:   begin
							cmdq_in[`CHARXM] <= reg_dat[3:0];	// fntsz
							cmdq_in[`CHARYM] <= reg_dat[11:8];	// fntsz
							end
		10'b100_0010_111:	cmdq_in[`CMD] <= reg_dat[7:0];	// cmd
		10'b100_0011_000:	cmdq_in[`X1POS] <= reg_dat[11:0];	// xpos2
		10'b100_0011_001:	cmdq_in[`Y1POS] <= reg_dat[11:0];	// ypos2
		10'b100_0011_010:	cmdq_in[`X2POS] <= reg_dat[11:0];	// xpos2
		10'b100_0011_011:	cmdq_in[`Y2POS] <= reg_dat[11:0];	// ypos2
//		10'b100_0011_010:	cmdq_in[`BASEADRH] <= reg_dat;
//		10'b100_0011_011:	cmdq_in[`BASEADRL] <= reg_dat;
*/
		10'b100_0010_110: 	cmdq_ndx <= reg_dat[4:0];
		10'b100_0011_110:	zlayer <= reg_dat[3:0];
		10'b100_0011_111:	begin
							zbuf <= reg_dat[0];
							clipEnable <= reg_dat[15];
							end
		10'b100_0100_000:	cmdq_in[31:16] <= reg_dat;
		10'b100_0100_001:	cmdq_in[15:0] <= reg_dat;
		10'b100_0100_011:	cmdq_in[47:32] <= reg_dat;
/*							
		10'b100_0100_000:   aa[31:16] <= reg_dat;
		10'b100_0100_001:   aa[15:0] <= reg_dat;					
		10'b100_0100_010:   ab[31:16] <= reg_dat;
        10'b100_0100_011:   ab[15:0] <= reg_dat;
		10'b100_0100_100:   ac[31:16] <= reg_dat;
        10'b100_0100_101:   ac[15:0] <= reg_dat;
		10'b100_0100_110:   at[31:16] <= reg_dat;
        10'b100_0100_111:   at[15:0] <= reg_dat;
 		10'b100_0101_000:   ba[31:16] <= reg_dat;
		10'b100_0101_001:   ba[15:0] <= reg_dat;					
		10'b100_0101_010:   bb[31:16] <= reg_dat;
        10'b100_0101_011:   bb[15:0] <= reg_dat;
		10'b100_0101_100:   bc[31:16] <= reg_dat;
        10'b100_0101_101:   bc[15:0] <= reg_dat;
		10'b100_0101_110:   bt[31:16] <= reg_dat;
        10'b100_0101_111:   bt[15:0] <= reg_dat;
		10'b100_0110_000:   ca[31:16] <= reg_dat;
        10'b100_0110_001:   ca[15:0] <= reg_dat;                    
        10'b100_0110_010:   cb[31:16] <= reg_dat;
        10'b100_0110_011:   cb[15:0] <= reg_dat;
        10'b100_0110_100:   cc[31:16] <= reg_dat;
        10'b100_0110_101:   cc[15:0] <= reg_dat;
        10'b100_0110_110:   ct[31:16] <= reg_dat;
        10'b100_0110_111:   ct[15:0] <= reg_dat;
*/
		10'b100_1000_000:	bltA_badr[19:16] <= reg_dat[3:0];
		10'b100_1000_001:	bltA_badr[15: 0] <= reg_dat;
		10'b100_1000_010:	bltA_mod[19:16] <= reg_dat[3:0];
		10'b100_1000_011:	bltA_mod[15: 0] <= reg_dat;
		10'b100_1000_100:	bltB_badr[19:16] <= reg_dat[3:0];
		10'b100_1000_101:	bltB_badr[15: 0] <= reg_dat;
		10'b100_1000_110:	bltB_mod[19:16] <= reg_dat[3:0];
		10'b100_1000_111:	bltB_mod[15: 0] <= reg_dat;
		10'b100_1001_000:	bltC_badr[19:16] <= reg_dat[3:0];
		10'b100_1001_001:	bltC_badr[15: 0] <= reg_dat;
		10'b100_1001_010:	bltC_mod[19:16] <= reg_dat[3:0];
		10'b100_1001_011:	bltC_mod[15: 0] <= reg_dat;
		10'b100_1001_100:	bltD_badr[19:16] <= reg_dat[3:0];
		10'b100_1001_101:	bltD_badr[15: 0] <= reg_dat;
		10'b100_1001_110:	bltD_mod[19:16] <= reg_dat[3:0];
		10'b100_1001_111:	bltD_mod[15: 0] <= reg_dat;
		10'b100_1010_000:	bltSrcWid[19:16] <= reg_dat[3:0];
		10'b100_1010_001:	bltSrcWid[15:0] <= reg_dat;
		10'b100_1010_010:	bltDstWid[19:16] <= reg_dat[3:0];
		10'b100_1010_011:	bltDstWid[15:0] <= reg_dat;
		10'b100_1010_100:	bltD_dat <= reg_dat;
		10'b100_1010_101:   bltPipedepth <= reg_dat[4:0];
		10'b100_1010_110:	bltCtrl <= reg_dat;
		10'b100_1010_111:	blt_op <= reg_dat;
		10'b100_1011_000:   bltA_cnt[19:16] <= reg_dat[3:0];
		10'b100_1011_001:   bltA_cnt[15:0] <= reg_dat;
		10'b100_1011_010:   bltB_cnt[19:16] <= reg_dat[3:0];
        10'b100_1011_011:   bltB_cnt[15:0] <= reg_dat;
		10'b100_1011_100:   bltC_cnt[19:16] <= reg_dat[3:0];
        10'b100_1011_101:   bltC_cnt[15:0] <= reg_dat;
		10'b100_1011_110:   bltD_cnt[19:16] <= reg_dat[3:0];
        10'b100_1011_111:   bltD_cnt[15:0] <= reg_dat;

		10'b100_110?_??0:	copper_adr[reg_adr[4:2]][19:16] <= reg_dat[3:0];
		10'b100_110?_??1:	copper_adr[reg_adr[4:2]][15:0] <= reg_dat;
		10'b100_1110_000:	copper_ctrl <= reg_dat;

		10'b101_0???_???:	rasti_en[reg_adr[6:1]] <= reg_dat;
		10'b101_1000_000:	irq_en <= reg_dat;
		10'b101_1000_001:	irq_status <= irq_status & ~reg_dat;

		10'b101_1001_100:	bltA_dat <= reg_dat;
		10'b101_1001_101:	bltB_dat <= reg_dat;
		10'b101_1001_110:	bltC_dat <= reg_dat;
		10'b101_1010_000:	bltA_shift <= reg_dat;
		10'b101_1010_001:	bltB_shift <= reg_dat;
		10'b101_1010_010:	bltC_shift <= reg_dat;
		10'b101_1010_100:   bltFWMask <= reg_dat;
        10'b101_1010_101:   bltLWMask <= reg_dat;

		// Audio $600 to $65E
		10'b110_0000_000:   aud0_adr[19:16] <= reg_dat[3:0];
		10'b110_0000_001:   aud0_adr[15:0] <= reg_dat;
		10'b110_0000_010:   aud0_length <= reg_dat;
		10'b110_0000_011:   aud0_period <= reg_dat;
		10'b110_0000_100:   aud0_volume <= reg_dat;
		10'b110_0000_101:   aud0_dat <= reg_dat;
		10'b110_0001_000:   aud1_adr[19:16] <= reg_dat[3:0];
        10'b110_0001_001:   aud1_adr[15:0] <= reg_dat;
        10'b110_0001_010:   aud1_length <= reg_dat;
        10'b110_0001_011:   aud1_period <= reg_dat;
        10'b110_0001_100:   aud1_volume <= reg_dat;
        10'b110_0001_101:   aud1_dat <= reg_dat;
		10'b110_0010_000:   aud2_adr[19:16] <= reg_dat[3:0];
        10'b110_0010_001:   aud2_adr[15:0] <= reg_dat;
        10'b110_0010_010:   aud2_length <= reg_dat;
        10'b110_0010_011:   aud2_period <= reg_dat;
        10'b110_0010_100:   aud2_volume <= reg_dat;
        10'b110_0010_101:   aud2_dat <= reg_dat;
		10'b110_0011_000:   aud3_adr[19:16] <= reg_dat[3:0];
        10'b110_0011_001:   aud3_adr[15:0] <= reg_dat;
        10'b110_0011_010:   aud3_length <= reg_dat;
        10'b110_0011_011:   aud3_period <= reg_dat;
        10'b110_0011_100:   aud3_volume <= reg_dat;
        10'b110_0011_101:   aud3_dat <= reg_dat;
        10'b110_0100_000:	audi_adr[19:16] <= reg_dat[3:0];
        10'b110_0100_001:	audi_adr[15:0] <= reg_dat;
        10'b110_0100_010:	audi_length <= reg_dat;
        10'b110_0100_011:	audi_period <= reg_dat;
        10'b110_0100_101:	audi_dat <= reg_dat;
        10'b110_0101_000:	aud_ctrl <= reg_dat;
        10'b110_0101_001:   aud_ctrl2 <= reg_dat;
		
		// Sync generator control regs  $7C0 to $7DE      
        10'b111_1100_000:	if (sgLock) hTotal <= reg_dat[11:0];
        10'b111_1100_001:	if (sgLock) vTotal <= reg_dat[11:0];
        10'b111_1100_010:	if (sgLock) hSyncOn <= reg_dat[11:0];
        10'b111_1100_011:	if (sgLock) hSyncOff <= reg_dat[11:0];
        10'b111_1100_100:	if (sgLock) vSyncOn <= reg_dat[11:0];
        10'b111_1100_101:	if (sgLock) vSyncOff <= reg_dat[11:0];
        10'b111_1100_110:	if (sgLock) hBlankOn <= reg_dat[11:0];
        10'b111_1100_111:	if (sgLock) hBlankOff <= reg_dat[11:0];
        10'b111_1101_000:	if (sgLock) vBlankOn <= reg_dat[11:0];
        10'b111_1101_001:	if (sgLock) vBlankOff <= reg_dat[11:0];
        10'b111_1101_010:	hBorderOn <= reg_dat[11:0];
        10'b111_1101_011:	hBorderOff <= reg_dat[11:0];
        10'b111_1101_100:	vBorderOn <= reg_dat[11:0];
        10'b111_1101_101:	vBorderOff <= reg_dat[11:0];
        10'b111_1101_110:   hstart <= reg_dat[11:0];   
        10'b111_1101_111:   vstart <= reg_dat[11:0];
        10'b111_1111_000:   lowres <= reg_dat[1:0];   
        10'b111_1111_001:	sgLock <= reg_dat==16'hA123;
		default:	;	// do nothing
		endcase
	end
end
if (cs_ram) begin
    if (zbuf)
    	dat_o <= zbram_data_o;
    else
    	dat_o <= ram_data_o;
end
else // if(cs_reg)
	case(adr_i[10:1])
	10'b0010000110: dat_o <= collision[31:16];
	10'b0010000111: dat_o <= collision[15:0];
	10'b1000010110:	dat_o <= {11'h00,cmdq_ndx};
	10'b1001010110:	dat_o <= bltCtrl;
	10'b1011000001:	dat_o <= irq_status;
	10'b1111110000:	dat_o <= {4'h0,hpos};
	10'b1111110001:	dat_o <= {4'h0,vpos};
	10'b1111111110: dat_o <= cap[31:16];
	10'b1111111111: dat_o <= cap[15:0];   
	default:	dat_o <= srdo;
	endcase

wrtx <= 1'b0;
wrA <= 1'b0;
wrB <= 1'b0;
wrC <= 1'b0;
aud0_req2 <= 1'b0;
aud1_req2 <= 1'b0;
aud2_req2 <= 1'b0;
aud3_req2 <= 1'b0;
audi_req2 <= 1'b0;

if (aud_ctrl[8])
	aud0_wadr <= aud0_adr;
if (aud_ctrl[9])
	aud1_wadr <= aud1_adr;
if (aud_ctrl[10])
	aud2_wadr <= aud2_adr;
if (aud_ctrl[11])
	aud3_wadr <= aud3_adr;
if (aud_ctrl[12])
	audi_wadr <= audi_adr;
// IF channel count == 1
// A count value of zero is not possible so there will be no requests unless
// the audio channel is enabled.
if (ch0_cnt==aud_ctrl[0] & ~aud_ctrl[8]) begin
	aud0_req <= aud0_req + 6'd1;
	aud0_req2 <= 1'b1;
end
if (ch1_cnt==aud_ctrl[1] & ~aud_ctrl[9]) begin
	aud1_req <= aud1_req + 6'd1;
	aud1_req2 <= 1'b1;
end
if (ch2_cnt==aud_ctrl[2] & ~aud_ctrl[10]) begin
	aud2_req <= aud2_req + 6'd1;
	aud2_req2 <= 1'b1;
end
if (ch3_cnt==aud_ctrl[3] & ~aud_ctrl[11]) begin
	aud3_req <= aud3_req + 6'd1;
	aud3_req2 <= 1'b1;
end
if (chi_cnt==aud_ctrl[4] & ~aud_ctrl[12]) begin
	audi_req <= audi_req + 6'd1;
	audi_req2 <= 1'b1;
end

// Audio test mode generates about a 600Hz signal for 0.5 secs on all the
// audio channels.
if (aud_ctrl[14])
    aud_test <= aud_test + 24'd1;
if (aud_test==24'hFFFFFF) begin
    aud_test <= 24'h0;
    aud_ctrl[14] <= 1'b0;
end

if (audi_req2)
	audi_dat <= aud_in;

//if (bltCtrl[1]) bltA_dat <= bltA_out1;
//if (bltCtrl[3]) bltB_dat <= bltB_out1;
//if (bltCtrl[5]) bltC_dat <= bltC_out1;

bltDone1 <= bltCtrl[13];
if (pe_vbl)
	irq_status[0] <= `TRUE;
if (bltCtrl[13] & ~bltDone1)
	irq_status[1] <= `TRUE;
if (hctr==12'd02 && rasti_en[vctr[9:4]][vctr[3:0]])
	irq_status[2] <= `TRUE;
	
if (cs_cmdq)
	cmdq_ndx <= cmdq_ndx + 5'd1;

if (copper_state==2'b10 && (cmppos > {copper_f,copper_v,copper_h})&&(copper_b ? bltCtrl[13] : 1'b1))
	copper_state <= 2'b01;

case(cursor_on)
32'b00000000000000000000000000000000,
32'b00000000000000000000000000000001,
32'b00000000000000000000000000000010,
32'b00000000000000000000000000000100,
32'b00000000000000000000000000001000,
32'b00000000000000000000000000010000,
32'b00000000000000000000000000100000,
32'b00000000000000000000000001000000,
32'b00000000000000000000000010000000,
32'b00000000000000000000000100000000,
32'b00000000000000000000001000000000,
32'b00000000000000000000010000000000,
32'b00000000000000000000100000000000,
32'b00000000000000000001000000000000,
32'b00000000000000000010000000000000,
32'b00000000000000000100000000000000,
32'b00000000000000001000000000000000,
32'b00000000000000010000000000000000,
32'b00000000000000100000000000000000,
32'b00000000000001000000000000000000,
32'b00000000000010000000000000000000,
32'b00000000000100000000000000000000,
32'b00000000001000000000000000000000,
32'b00000000010000000000000000000000,
32'b00000000100000000000000000000000,
32'b00000001000000000000000000000000,
32'b00000010000000000000000000000000,
32'b00000100000000000000000000000000,
32'b00001000000000000000000000000000,
32'b00010000000000000000000000000000,
32'b00100000000000000000000000000000,
32'b01000000000000000000000000000000,
32'b10000000000000000000000000000000:   ;
default:	collision <= collision | cursor_on;
endcase

case(state)
ST_IDLE:
	begin
	    ram_ce <= `LOW;
		ram_we <= {2{`LOW}};
		zbram_we <= {2{`LOW}};
		ack <= `LOW;
		
		// Audio takes precedence to avoid audio distortion.
		// Fortunately audio DMA is fast and infrequent.
		if (|aud0_req) begin
		    ram_ce <= `HIGH;
			ram_addr <= aud0_wadr;
			aud0_wadr <= aud0_wadr + aud0_req;
			aud0_req <= 6'd0;
			if (aud0_wadr + aud0_req >= aud0_adr + aud0_length) begin
				aud0_wadr <= aud0_adr + (aud0_wadr + aud0_req - (aud0_adr + aud0_length));
				irq_status[8] <= 1'b1;
			end
			if (aud0_wadr < ((aud0_adr + aud0_length) >> 1) &&
				(aud0_wadr + aud0_req >= ((aud0_adr + aud0_length) >> 1)))
				irq_status[4] <= 1'b1;
			state <= ST_AUD0;
		end
		else if (|aud1_req)	begin
		    ram_ce <= `HIGH;
			ram_addr <= aud1_wadr;
			aud1_wadr <= aud1_wadr + aud1_req;
			aud1_req <= 6'd0;
			if (aud1_wadr + aud1_req >= aud1_adr + aud1_length) begin
				aud1_wadr <= aud1_adr + (aud1_wadr + aud1_req - (aud1_adr + aud1_length));
				irq_status[9] <= 1'b1;
			end
			if (aud1_wadr < ((aud1_adr + aud1_length) >> 1) &&
				(aud1_wadr + aud1_req >= ((aud1_adr + aud1_length) >> 1)))
				irq_status[5] <= 1'b1;
			state <= ST_AUD1;
		end
		else if (|aud2_req) begin
		    ram_ce <= `HIGH;
			ram_addr <= aud2_wadr;
			aud2_wadr <= aud2_wadr + aud2_req;
			aud2_req <= 6'd0;
			if (aud2_wadr + aud2_req >= aud2_adr + aud2_length) begin
				aud2_wadr <= aud2_adr + (aud2_wadr + aud2_req - (aud2_adr + aud2_length));
				irq_status[10] <= 1'b1;
			end
			if (aud2_wadr < ((aud2_adr + aud2_length) >> 1) &&
				(aud2_wadr + aud2_req >= ((aud2_adr + aud2_length) >> 1)))
				irq_status[6] <= 1'b1;
			state <= ST_AUD2;
		end
		else if (|aud3_req)	begin
		    ram_ce <= `HIGH;
			ram_addr <= aud3_wadr;
			aud3_wadr <= aud3_wadr + aud3_req;
			aud3_req <= 6'd0;
			if (aud3_wadr + aud3_req >= aud3_adr + aud3_length) begin
				aud3_wadr <= aud3_adr + (aud3_wadr + aud3_req - (aud3_adr + aud3_length));
				irq_status[11] <= 1'b1;
			end
			if (aud3_wadr < ((aud3_adr + aud3_length) >> 1) &&
				(aud3_wadr + aud3_req >= ((aud3_adr + aud3_length) >> 1)))
				irq_status[7] <= 1'b1;
			state <= ST_AUD3;
		end
		else if (|audi_req) begin
		    ram_ce <= `HIGH;
			ram_we <= 2'b11;
			ram_addr <= audi_wadr;
			ram_data_i <= audi_dat;
			audi_wadr <= audi_wadr + audi_req;
			audi_req <= 6'd0;
			if (audi_wadr + audi_req >= audi_adr + audi_length) begin
				audi_wadr <= audi_adr + (audi_wadr + audi_req - (audi_adr + audi_length));
				irq_status[12] <= 1'b1;
			end
			if (audi_wadr < ((audi_adr + audi_length) >> 1) &&
				(audi_wadr + audi_req >= ((audi_adr + audi_length) >> 1)))
				irq_status[3] <= 1'b1;
`ifdef AUD_PLOT
			if (aud_ctrl[7])
				state <= ST_AUD_PLOT;
`endif
		end
		else if (cs_ram) begin
		    ram_ce <= `HIGH;
			ram_data_i <= dat_i;
			ram_addr <= adr_i[19:1];
			if (zbuf)
				zbram_we <= {{2{we_i}} & sel_i};
			else
				ram_we <= {{2{we_i}} & sel_i};
			state <= ST_RW;
		end
		
		else if (copper_state==2'b01 && copper_en) begin
			state <= ST_COPPER_IFETCH;
		end

		else if (bltCtrl[14]) begin
			bltAa <= 5'd0;
			bltBa <= 5'd0;
			bltCa <= 5'd0;
			if (bltCtrl[1])
				state <= ST_BLTDMA1;
			else if (bltCtrl[3])
				state <= ST_BLTDMA3;
			else if (bltCtrl[5])
				state <= ST_BLTDMA5;
			else if (bltCtrl[7])
				state <= ST_BLTDMA7;
			else begin
				bltCtrl[15] <= 1'b0;
				bltCtrl[14] <= 1'b0;
				bltCtrl[13] <= 1'b1;
			end
		end
		else if (bltCtrl[15]) begin
			bltCtrl[15] <= 1'b0;
			bltCtrl[14] <= 1'b1;
			bltCtrl[13] <= 1'b0;
			bltAa <= 5'd0;
			bltBa <= 5'd0;
			bltCa <= 5'd0;
			bltA_wadr <= bltA_badr;
			bltB_wadr <= bltB_badr;
			bltC_wadr <= bltC_badr;
			bltD_wadr <= bltD_badr;
			bltA_wcnt <= 20'd1;
			bltB_wcnt <= 20'd1;
			bltC_wcnt <= 20'd1;
			bltD_wcnt <= 20'd1;
			bltA_dcnt <= 20'd1;
			bltB_dcnt <= 20'd1;
			bltC_dcnt <= 20'd1;
			bltA_hcnt <= 20'd1;
			bltB_hcnt <= 20'd1;
			bltC_hcnt <= 20'd1;
			bltD_hcnt <= 20'd1;
			bltA_residue <= 16'h0000;
			bltB_residue <= 16'h0000;
			bltC_residue <= 16'h0000;
			if (bltCtrl[1])
				state <= ST_BLTDMA1;
			else if (bltCtrl[3])
				state <= ST_BLTDMA3;
			else if (bltCtrl[5])
				state <= ST_BLTDMA5;
			else if (bltCtrl[7])
				state <= ST_BLTDMA7;
			else begin
				bltCtrl[15] <= 1'b0;
				bltCtrl[14] <= 1'b0;
				bltCtrl[13] <= 1'b1;
			end
		end

		// busy with a graphics command ?
		else if (ctrl[14]) begin
//			bltCtrl[13] <= 1'b0;
			case(ctrl[7:0])
			8'd0:	state <= ST_READ_CHAR_BITMAP;
			8'd2:	state <= DL_PRECALC;
			8'd6:	state <= ngs;
			8'd8:   state <= ngs;
			default:	ctrl[14] <= 1'b0;
			endcase
		end

		else if (|cmdq_ndx) begin
			cmdq_ndx <= cmdq_ndx - 5'd1;
			state <= ST_CMD;
		end
    end

ST_CMD:
	begin
		state <= ST_IDLE;
		ctrl[7:0] <= cmdq_out[39:32];
		ctrl[14] <= 1'b0;
		case(cmdq_out[39:32])
		8'd0:	begin
				charcode <= cmdq_out[15:0];
				state <= ST_READ_FONT_TBL;	// draw character
				end
		8'd1:	state <= ST_PLOT;
		8'd2:	begin
				ctrl[11:8] <= cmdq_out[7:4];	// raster op
				state <= DL_INIT;			// draw line
				end
		8'd3:	begin
				ctrl[11:8] <= cmdq_out[7:4];	// raster op
				state <= ST_FILLRECT;
				end
		8'd4:	begin
				wrtx <= 1'b1;
				hwTexture <= cmdq_out[`TXHANDLE];
				state <= ST_IDLE;
				end
		8'd5:	begin
				hrTexture <= cmdq_out[`TXHANDLE];
				ctrl[11:8] <= cmdq_out[7:4];	// raster op
				state <= ST_TILERECT;
				end
		8'd6:	begin	// Draw triangle
				ctrl[11:8] <= cmdq_out[7:4];	// raster op
				state <= DT_START;
				retstate2 <= ST_IDLE;
				end
		8'd7:	begin	// Set clip region
			/*
				clipEnable <= cmdq_out[`CLIPEN];
				clipX0 <= cmdq_out[`X0POS];
				clipY0 <= cmdq_out[`Y0POS];
				clipX1 <= cmdq_out[`X1POS];
				clipY1 <= cmdq_out[`Y1POS];
			*/
				end
		8'd8:	begin	// Bezier Curve
				ctrl[11:8] <= cmdq_out[7:4];	// raster op
				fillCurve <= cmdq_out[1:0];
				state <= BC0;
				end
		8'd9:	transform <= cmdq_out[0];
		8'd12:	penColor <= cmdq_out[`CMDDAT];
		8'd13:	fillColor <= cmdq_out[`CMDDAT];
		8'd16:	up0x <= cmdq_out[`CMDDAT];
		8'd17:	up0y <= cmdq_out[`CMDDAT];
		8'd18:	up0z <= cmdq_out[`CMDDAT];
		8'd19:	up1x <= cmdq_out[`CMDDAT];
		8'd20:	up1y <= cmdq_out[`CMDDAT];
		8'd21:	up1z <= cmdq_out[`CMDDAT];
		8'd22:	up2x <= cmdq_out[`CMDDAT];
		8'd23:	up2y <= cmdq_out[`CMDDAT];
		8'd24:	up2z <= cmdq_out[`CMDDAT];
		8'd32:	aa <= cmdq_out[`CMDDAT];
		8'd33:	ab <= cmdq_out[`CMDDAT];
		8'd34:	ac <= cmdq_out[`CMDDAT];
		8'd35:	at <= cmdq_out[`CMDDAT];
		8'd36:	ba <= cmdq_out[`CMDDAT];
		8'd37:	bb <= cmdq_out[`CMDDAT];
		8'd38:	bc <= cmdq_out[`CMDDAT];
		8'd39:	bt <= cmdq_out[`CMDDAT];
		8'd40:	ca <= cmdq_out[`CMDDAT];
		8'd41:	cb <= cmdq_out[`CMDDAT];
		8'd42:	cc <= cmdq_out[`CMDDAT];
		8'd43:	ct <= cmdq_out[`CMDDAT];
		default:	state <= ST_IDLE;
		endcase
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Standard RAM read/write
// - ram reads take two cycles hence the extra RW2 state
// - on a write the ack signal can go high a cycle sooner.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_RW:
	begin
		if (|ram_we)
			ack <= `HIGH;
	    ram_ce <= `LOW;
        ram_we <= {2{`LOW}};
        zbram_we <= {2{`LOW}};
        state <= ST_RW2;
    end
ST_RW2:
	begin
		ack <= `HIGH;
        if (~cs_ram) begin
            ack <= `LOW;
            state <= ST_IDLE;
        end
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Audio DMA states
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_AUD0:
	state <= ST_AUD02;
ST_AUD02:
    state <= ST_AUD03;
ST_AUD03:
	begin
	    ram_ce <= `LOW;
        aud0_dat <= ram_data_o;
        state <= ST_IDLE;
    end

ST_AUD1:
	state <= ST_AUD12;
ST_AUD12:
    state <= ST_AUD13;
ST_AUD13:
	begin
	    ram_ce <= `LOW;
        aud1_dat <= ram_data_o;
        state <= ST_IDLE;
    end

ST_AUD2:
	state <= ST_AUD22;
ST_AUD22:
    state <= ST_AUD23;
ST_AUD23:
	begin
	    ram_ce <= `LOW;
        aud2_dat <= ram_data_o;
        state <= ST_IDLE;
    end

ST_AUD3:
	state <= ST_AUD32;
ST_AUD32:
    state <= ST_AUD33;
ST_AUD33:
	begin
	    ram_ce <= `LOW;
        aud3_dat <= ram_data_o;
        state <= ST_IDLE;
    end

`ifdef AUD_PLOT
ST_AUD_PLOT:
	begin
		penColor <= 16'h7FFF;
		tgtaddr <= {12'h00,audi_dat[15:8]^8'h80} * {4'h00,TargetWidth} + TargetBase + audi_wadr[7:0];
		state <= ST_AUD_PLOT_WRITE;
	end
ST_AUD_PLOT_WRITE:
	begin
	    ram_ce <= `HIGH;
		ram_we <= 2'b11;
		ram_addr <= tgtaddr;
		ram_data_i <= penColor;
		state <= ST_AUD_PLOT_RET;
	end
ST_AUD_PLOT_RET:
    begin
	    ram_ce <= `LOW;
        ram_we <= 2'b00;
		state <= ST_IDLE;
    end
`endif

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Pixel plot acceleration states
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_PLOT:
	begin
		//penColor <= charbk_qo;
		tgtaddr <= {8'h00,p0y} * {4'h00,TargetWidth} + TargetBase + p0x;
		state <= (penColor[`A]|zbuf) ? ST_PLOT_READ : ST_PLOT_WRITE;
	end
ST_PLOT_READ:
    begin
	    ram_ce <= `HIGH;
		ram_addr <= zbuf ? tgtaddr[19:3] : tgtaddr;
		push_go(ST_PLOT_WRITE,DELAY2);
    end
ST_PLOT_WRITE:
	begin
		//set_pixel(penColor);
		ram_addr <= zbuf ? tgtaddr[19:3] : tgtaddr;
		if (zbuf) begin
			zbram_we <= 2'b11;
			ram_data_i <= (zbram_data_o & ~(2'b11 << {tgtaddr[2:0],1'b0})) | (zlayer << {tgtaddr[2:0],1'b0});
		end
		else begin
			ram_we <= 2'b11;
			if (penColor[`A]) begin
				ram_data_i[`R] <= ram_data_o[`R] >> penColor[2:0];
				ram_data_i[`G] <= ram_data_o[`G] >> penColor[5:3];
				ram_data_i[`B] <= ram_data_o[`B] >> penColor[8:6];
			end
			else
				ram_data_i <= penColor;
		end
		state <= ST_PLOT_RET;
	end
	// Disable write signal while address and data are still valid.
ST_PLOT_RET:
    begin
	    ram_ce <= `LOW;
        ram_we <= 2'b00;
		state <= ST_IDLE;
    end
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Character draw acceleration states
//
// Font Table - An entry for each font
// fwwwwwhhhhh-aaaa		- width and height
// aaaaaaaaaaaaaaaa		- char bitmap address
// ------------aaaa		- address offset of gylph width table
// aaaaaaaaaaaaaaaa		- low order address offset bits
//
// Glyph Table Entry
// ---wwwww---wwwww		- width
// ---wwwww---wwwww		- 
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_READ_FONT_TBL:
	begin
		pixhc <= 5'd0;
		pixvc <= 5'd0;
		//charcode <= charcode_qo;
		//fgcolor <= charfg_qo;
		//penColor <= charbk_qo;
	    ram_ce <= `HIGH;
		ram_addr <= {font_tbl_adr[18:2],2'b0} + {font_id,2'b00};
		state <= ST_READ_FONT_TBL1;
	end
ST_READ_FONT_TBL1:
    begin
		ram_addr <= ram_addr + 19'd1;
        state <= ST_READ_FONT_TBL1a;
    end
ST_READ_FONT_TBL1a:
    begin
		ram_addr <= ram_addr + 19'd1;
        state <= ST_READ_FONT_TBL2;
    end
ST_READ_FONT_TBL2:
	begin
		ram_addr <= ram_addr + 19'd1;
		font_fixed <= ram_data_o[15];
		font_width <= ram_data_o[14:10];
		font_height <= ram_data_o[9:5];
		charBmpBase[19:16] <= ram_data_o[3:0];
		state <= ST_READ_FONT_TBL3;
	end
ST_READ_FONT_TBL3:
	begin
		ram_addr <= ram_addr + 19'd1;
		charBmpBase[15:0] <= ram_data_o;
		state <= font_fixed ? ST_READ_FONT_TBL6 : ST_READ_FONT_TBL4;
	end
ST_READ_FONT_TBL4:
	begin
		ram_addr <= ram_addr + 19'd1;
		glyph_tbl_adr[19:16] <= ram_data_o[3:0];
		state <= ST_READ_FONT_TBL5;
	end
ST_READ_FONT_TBL5:
	begin
		ram_addr <= ram_addr + 19'd1;
		glyph_tbl_adr[15:0] <= ram_data_o;
		state <= ST_READ_FONT_TBL6;
	end
ST_READ_FONT_TBL6:
	begin
		charBoxX0 <= p0x;
		charBoxY0 <= p0y;
		charBmpBase <= charBmpBase + (charcode << font_width[4]) * (font_height + 7'd1);
		if (font_fixed) begin
    	    ram_ce <= `LOW;
			ctrl[14] <= 1'b1;
			state <= ST_IDLE;
		end
		else begin
			ram_addr <= glyph_tbl_adr + charcode[8:1];
			state <= ST_READ_GLYPH_ENTRY;
		end
	end
ST_READ_GLYPH_ENTRY:
    state <= ST_READ_GLYPH_ENTRY2;
ST_READ_GLYPH_ENTRY2:
    state <= ST_READ_GLYPH_ENTRY3;
ST_READ_GLYPH_ENTRY3:
	begin
	    ram_ce <= `LOW;
		font_width <= ram_data_o >> {charcode[0],3'b0};
		ctrl[14] <= 1'b1;
		state <= ST_IDLE;
	end
/*
ST_CHAR_INIT:
	begin
//		pixcnt <= 10'h000;
		pixhc <= 4'd0;
		pixvc <= 4'd0;
		charcode <= charcode_qo;
		fgcolor <= charfg_qo;
		penColor <= charbk_qo;
		pixxm <= charxm_qo;
		pixym <= charym_qo;
		tgtaddr <= {8'h00,cmdy1_qo} * {8'h00,TargetWidth} + {TargetBase[19:12],cmdx1_qo};
		state <= ST_READ_CHAR_BITMAP;
	end
*/
ST_READ_CHAR_BITMAP:
	begin
//		ram_addr <= charBmpBase + charcode * (pixym + 4'd1) + pixvc;
	    ram_ce <= `HIGH;
		ram_addr <= charBmpBase + (pixvc << font_width[4]);
		state <= ST_READ_CHAR_BITMAP2;
	end
ST_READ_CHAR_BITMAP2:
    begin
		ram_addr <= ram_addr + 19'd1; // in case of second word
		state <= ST_READ_CHAR_BITMAP3;
    end
ST_READ_CHAR_BITMAP3:
		state <= ST_READ_CHAR_BITMAP_DAT;
ST_READ_CHAR_BITMAP_DAT:
	begin
		charbmp[15:0] <= ram_data_o;
		tgtaddr <= {8'h00,charBoxY0[31:16]} * {4'h00,TargetWidth} + TargetBase + charBoxX0[31:16];
		tgtindex <= {14'h00,pixvc} * {4'h00,TargetWidth};
		state <= font_width[4] ? ST_READ_CHAR_BITMAP_DAT2 : ST_WRITE_CHAR;
	end
ST_READ_CHAR_BITMAP_DAT2:
	begin
		charbmp[31:16] <= ram_data_o;
		state <= ST_WRITE_CHAR;
	end
ST_WRITE_CHAR:
	begin
		ram_addr <= tgtaddr + tgtindex + {14'h00,pixhc};
		if (~fillColor[`A]) begin
			if (clipEnable && (charBoxX0[31:16] + pixhc < clipX0 || charBoxX0[31:16] + pixhc >= clipX1 || charBoxY0[31:16] + pixvc < clipY0))
				;
			else if (charBoxX0[31:16] + pixhc >= TargetWidth)
				;
			else begin
				ram_we <= 2'b11;
				ram_data_i <= charbmp[font_width] ? penColor[15:0] : fillColor[15:0];
			end
		end
		else begin
			if (charbmp[font_width]) begin
				if (zbuf) begin
					if (clipEnable && (charBoxX0[31:16] + pixhc < clipX0 || charBoxX0[31:16] + pixhc >= clipX1 || charBoxY0[31:16] + pixvc < clipY0))
						;
					else if (charBoxX0[31:16] + pixhc >= TargetWidth)
						;
					else begin
						zbram_we <= 2'b11;
						ram_data_i <= zlayer;
					end
				end
				else begin
					if (clipEnable && (charBoxX0[31:16] + pixhc < clipX0 || charBoxX0[31:16] + pixhc >= clipX1 || charBoxY0[31:16] + pixvc < clipY0))
						;
					else if (charBoxX0[31:16] + pixhc >= TargetWidth)
						;
					else begin
						ram_we <= {2{charBoxX0[31:16] + pixhc < TargetWidth}};
						ram_data_i <= penColor[15:0];
					end
				end
			end
			else begin
				ram_we <= {2{`LOW}};
				zbram_we <= {2{`LOW}};
			end
		end
		charbmp <= {charbmp[30:0],1'b0};
		pixhc <= pixhc + 5'd1;
		if (pixhc==font_width) begin
	        state <= ST_PLOT_RET;
		    pixhc <= 5'd0;
		    pixvc <= pixvc + 5'd1;
		    if (clipEnable && (charBoxY0[31:16] + pixvc + 16'd1 >= clipY1))
		    	ctrl[14] <= 1'b0;
		    else if (charBoxY0[31:16] + pixvc + 16'd1 >= TargetHeight)
		    	ctrl[14] <= 1'b0;
		    else if (pixvc==font_height)
		    	ctrl[14] <= 1'b0;
		end
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Blitter DMA
// Blitter has four DMA channels, three source channels and one destination
// channel.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_BLTDMA1:
	begin
		ram_we <= {2{`LOW}};
		zbram_we <= {2{`LOW}};
		bitcnt <= bltCtrl[0] ? 4'd15 : 4'd0;
        bitinc <= bltCtrl[0] ? 4'd1 : 4'd0;
		bltinc <= bltCtrl[8] ? 20'hFFFFF : 20'd1;
	    loopcnt <= bltPipedepth + 5'd3;
		bltAa <= 5'd0;
		srstA <= `FALSE;
		state <= ST_BLTDMA2;
	end
ST_BLTDMA2:
	begin
		if (loopcnt > 5'd2) begin
    	    ram_ce <= `HIGH;
			ram_addr <= bltA_wadr;
			if (bitcnt==4'd0) begin
        		bltA_wadr <= bltA_wadr + bltinc;
			    bltA_hcnt <= bltA_hcnt + 20'd1;
			    if (bltA_hcnt==bltSrcWid) begin
				    bltA_hcnt <= 20'd1;
				    bltA_wadr <= bltA_wadr + bltA_mod + bltinc;
					bitcnt <= bltCtrl[0] ? 4'd15 : 4'd0;
				end
                bltA_wcnt <= bltA_wcnt + 20'd1;
                bltA_dcnt <= bltA_dcnt + 20'd1;
                if (bltA_wcnt==bltA_cnt) begin
                    bltA_wadr <= bltA_badr;
                    bltA_wcnt <= 20'd1;
                    bltA_hcnt <= 20'd1;
					bitcnt <= bltCtrl[0] ? 4'd15 : 4'd0;
                end
            end
        end
		if (loopcnt < bltPipedepth + 5'd1) begin
			wrA <= 1'b1;
			bltAa <= bltAa + 5'd1;
            //blt_bmpA <= ram_data_o;
            blt_bmpA <=   ((bltCtrl[8] ? ((zbuf ? zbram_data_o : ram_data_o) << bltA_shift[3:0]) | bltA_residue :
            				 ((zbuf ? zbram_data_o : ram_data_o) >> bltA_shift[3:0])| bltA_residue ))
                        & ((bltA_hcnt==bltSrcWid) ? bltLWMask : 16'hFFFF)
                        & ((bltA_hcnt==20'd1) ? bltFWMask : 16'hFFFF);
            bltA_residue <= bltCtrl[8] ? (zbuf ? zbram_data_o : ram_data_o) >> (5'd16-bltA_shift[3:0]) :
            			(zbuf ? zbram_data_o : ram_data_o) << (5'd16-bltA_shift[3:0]);
        end
		loopcnt <= loopcnt - 5'd1;
		if (loopcnt==5'd0 || bltA_dcnt==bltD_cnt) begin
			if (bltCtrl[3])
				state <= ST_BLTDMA3;
			else if (bltCtrl[5])
				state <= ST_BLTDMA5;
			else
				state <= ST_BLTDMA7;
		end
	end
	// Do channel B
ST_BLTDMA3:
	begin
		ram_we <= {2{`LOW}};
		zbram_we <= {2{`LOW}};
		bitcnt <= bltCtrl[2] ? 4'd15 : 4'd0;
        bitinc <= bltCtrl[2] ? 4'd1 : 4'd0;
		bltinc <= bltCtrl[9] ? 20'hFFFFF : 20'd1;
		loopcnt <= bltPipedepth + 5'd3;
		bltBa <= 5'd0;
		srstB <= `FALSE;
		state <= ST_BLTDMA4;
	end
ST_BLTDMA4:
	begin
		if (loopcnt > 5'd2) begin
    	    ram_ce <= `HIGH;
			ram_addr <= bltB_wadr;
			if (bitcnt==4'd0) begin
                bltB_wadr <= bltB_wadr + bltinc;
                bltB_hcnt <= bltB_hcnt + 20'd1;
                if (bltB_hcnt==bltSrcWid) begin
                    bltB_hcnt <= 20'd1;
                    bltB_wadr <= bltB_wadr + bltB_mod + bltinc;
					bitcnt <= bltCtrl[2] ? 4'd15 : 4'd0;
                end
                bltB_wcnt <= bltB_wcnt + 20'd1;
                bltB_dcnt <= bltB_dcnt + 20'd1;
                if (bltB_wcnt==bltB_cnt) begin
                    bltB_wadr <= bltB_badr;
                    bltB_wcnt <= 20'd1;
                    bltB_hcnt <= 20'd1;
					bitcnt <= bltCtrl[2] ? 4'd15 : 4'd0;
                end
            end
		end
		if (loopcnt < bltPipedepth + 5'd1) begin
			wrB <= 1'b1;
			bltBa <= bltBa + 5'd1;
            blt_bmpB <=   ((bltCtrl[9] ? ((zbuf ? zbram_data_o : ram_data_o) << bltB_shift[3:0]) | bltB_residue :
            				 ((zbuf ? zbram_data_o : ram_data_o) >> bltB_shift[3:0])| bltB_residue ));
            bltB_residue <= bltCtrl[9] ? (zbuf ? zbram_data_o : ram_data_o) >> (5'd16-bltB_shift[3:0]) :
            			(zbuf ? zbram_data_o : ram_data_o) << (5'd16-bltB_shift[3:0]);
//            blt_bmpB <=   (((zbuf ? zbram_data_o : ram_data_o) >> bltB_shift[3:0]) | bltB_residue);
		end
		loopcnt <= loopcnt - 5'd1;
		if (loopcnt==5'd0 || bltB_dcnt==bltD_cnt) begin
			if (bltCtrl[5])
				state <= ST_BLTDMA5;
			else
				state <= ST_BLTDMA7;
		end
	end
	// Do channel C
ST_BLTDMA5:
	begin
		ram_we <= {2{`LOW}};
		zbram_we <= {2{`LOW}};
		bitcnt <= bltCtrl[4] ? 4'd15 : 4'd0;
        bitinc <= bltCtrl[4] ? 4'd1 : 4'd0;
		bltinc <= bltCtrl[10] ? 20'hFFFFF : 20'd1;
		loopcnt <= bltPipedepth + 5'd3;
		bltCa <= 5'd0;
		srstC <= `FALSE;
		state <= ST_BLTDMA6;
	end
ST_BLTDMA6:
	begin
		if (loopcnt > 5'd2) begin
    	    ram_ce <= `HIGH;
			ram_addr <= bltC_wadr;
			if (bitcnt==4'd0) begin
                bltC_wadr <= bltC_wadr + bltinc;
                bltC_hcnt <= bltC_hcnt + 20'd1;
                if (bltC_hcnt==bltSrcWid) begin
                    bltC_hcnt <= 20'd1;
                    bltC_wadr <= bltC_wadr + bltC_mod + bltinc;
					bitcnt <= bltCtrl[4] ? 4'd15 : 4'd0;
                end
                bltC_wcnt <= bltC_wcnt + 20'd1;
                bltC_dcnt <= bltC_dcnt + 20'd1;
                if (bltC_wcnt==bltC_cnt) begin
                    bltC_wadr <= bltC_badr;
                    bltC_wcnt <= 20'd1;
                    bltC_hcnt <= 20'd1;
					bitcnt <= bltCtrl[4] ? 4'd15 : 4'd0;
                end
            end
		end
		if (loopcnt < bltPipedepth + 5'd1) begin
			wrC <= 1'b1;
			bltCa <= bltCa + 5'd1;
            blt_bmpC <=   ((bltCtrl[10] ? ((zbuf ? zbram_data_o : ram_data_o) << bltC_shift[3:0]) | bltC_residue :
            				 ((zbuf ? zbram_data_o : ram_data_o) >> bltC_shift[3:0])| bltC_residue ));
            bltC_residue <= bltCtrl[10] ? (zbuf ? zbram_data_o : ram_data_o) >> (5'd16-bltC_shift[3:0]) :
            			(zbuf ? zbram_data_o : ram_data_o) << (5'd16-bltC_shift[3:0]);
		end
		loopcnt <= loopcnt - 5'd1;
		if (loopcnt==5'd0 || bltC_dcnt==bltD_cnt)
			state <= ST_BLTDMA7;
	end
	// Do channel D
ST_BLTDMA7:
	begin
		bltinc <= bltCtrl[11] ? 20'hFFFFF : 20'd1;
		loopcnt <= bltPipedepth;
		bltAa <= bltAa - 5'd1;	// move to next queue entry
        bltBa <= bltBa - 5'd1;
        bltCa <= bltCa - 5'd1;
        bltRdf <= `TRUE;
		state <= ST_BLTDMA8;
	end
ST_BLTDMA8:
	begin
	    if (zbuf)
		    zbram_we <= 2'b11;
		else
		    ram_we <= 2'b11;
	    ram_ce <= `HIGH;
		ram_addr <= bltD_wadr;
		// If there's no source then a fill operation muct be taking place.
		if (bltCtrl[1]|bltCtrl[3]|bltCtrl[5])
			ram_data_i <= bltabc;
		else
			ram_data_i <= bltD_dat;	// fill color
		bltD_wadr <= bltD_wadr + bltinc;
		bltD_wcnt <= bltD_wcnt + 20'd1;
		bltD_hcnt <= bltD_hcnt + 24'd1;
		if (bltD_hcnt==bltDstWid) begin
			bltD_hcnt <= 24'd1;
			bltD_wadr <= bltD_wadr + bltD_mod + bltinc;
		end
		bltAa <= bltAa - 5'd1;	// move to next queue entry
		bltBa <= bltBa - 5'd1;
		bltCa <= bltCa - 5'd1;
		loopcnt <= loopcnt - 5'd1;
		if (bltD_wcnt==bltD_cnt) begin
			bltRdf <= `FALSE;
			state <= ST_IDLE;
			bltCtrl[14] <= 1'b0;
			bltCtrl[13] <= 1'b1;
		end
		else if (loopcnt==5'd0) begin
			bltRdf <= `FALSE;
			state <= ST_IDLE;
        end
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
DELAY2:	go(DELAY2a);
DELAY2a: go(DELAY2b);
DELAY2b: ret();
	

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Pixel fetch / plot
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
/*
GETPIXEL:
	begin
	    ram_ce <= `HIGH;
		ram_addr <= zbuf ? ma[19:3] : ma;
		push_go(SETPIXEL,DELAY2);
	end
SETPIXEL:
	begin
		set_pixel(penColor);
		ret();
	end
*/
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Line draw states
// Line drawing may also be done by the blitter.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

DL_INIT:
	begin
		push_go(ST_IDLE,DL_PRECALC);
	end

// State to setup invariants for DRAWLINE
DL_PRECALC:
	begin
		loopcnt <= 5'd17;
		if (!ctrl[14]) begin
			ctrl[14] <= 1'b1;
			gcx <= p0x[31:16];
			gcy <= p0y[31:16];
			dx <= absx1mx0[31:16];
			dy <= absy1my0[31:16];
			if (p0x < p1x) sx <= 16'h0001; else sx <= 16'hFFFF;
			if (p0y < p1y) sy <= 16'h0001; else sy <= 16'hFFFF;
			err <= absx1mx0[31:16]-absy1my0[31:16];
		end
		else if (((ctrl[11:8] != 4'h1) &&
			(ctrl[11:8] != 4'h0) &&
			(ctrl[11:8] != 4'hF)) || zbuf)
			go(DL_GETPIXEL);
		else
			go(DL_SETPIXEL);
	end
DL_GETPIXEL:
	begin
	    ram_ce <= `HIGH;
		ram_addr <= zbuf ? ma[19:3] : ma;
		push_go(DL_SETPIXEL,DELAY2);
	end
DL_SETPIXEL:
	begin
		set_pixel(penColor,0,ctrl[11:8]);
		loopcnt <= loopcnt - 5'd1;
		if (gcx==p1x[31:16] && gcy==p1y[31:16]) begin
			if (retstate==ST_IDLE)
				ctrl[14] <= 1'b0;
			ret();
		end
		else
			go(DL_TEST);
	end
DL_TEST:
	begin
		ram_we <= {2{`LOW}};
		zbram_we <= {2{`LOW}};
		err <= err - ((e2 > -dy) ? dy : 16'd0) + ((e2 < dx) ? dx : 16'd0);
		if (e2 > -dy)
			gcx <= gcx + sx;
		if (e2 <  dx)
			gcy <= gcy + sy;
		if (loopcnt==5'd0) begin
			if ((ctrl[11:8] != 4'h1) &&
				(ctrl[11:8] != 4'h0) &&
				(ctrl[11:8] != 4'hF))
				pause(DL_GETPIXEL);
			else
				pause(DL_SETPIXEL);
		end
		else if ((ctrl[11:8] != 4'h1) &&
			(ctrl[11:8] != 4'h0) &&
			(ctrl[11:8] != 4'hF))
			go(DL_GETPIXEL);
		else
			go(DL_SETPIXEL);
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Draw line with anti-aliasing.
// Needs to read the underlying color and mix the two.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

DAAL1:
    begin
    	steep <= absy1my0 > absx1mx0;
        if (absy1my0 > absx1mx0) begin
            up0x <= up0y;
            up0y <= up0x;
            up1x <= up1y;
            up1y <= up1x;
        end
        push_go(DAAL3,DELAY2);
    end
DAAL3:
    begin
        if (p0x > p1x) begin
            up0x <= up1x;
            up1x <= up0x;
            up0y <= up1y;
            up1y <= up0y;
        end
        push_go(DAAL4,DELAY2);
    end
DAAL4:
    begin
        div_a <= p1y - p0y; // dy
        div_b <= p1x - p0x; // dx
        div_ld <= `TRUE;	// gradient = dy/dx
        pause(DAAL5);
    end
DAAL5:
    if (div_idle) begin
        if (div_b == 32'h0) // dx
            gradient <= 32'h10000;
        else
            gradient <= div_qo;
        go(DAAL6);
    end
DAAL6:
    begin
        //xend <= {p0x[31:16],16'h8000}; // + 0.5
        yend <= p0y + gradient * (round(p0x) - p0x);
        xgap <= rfpart(p0x + 32'h8000);
        xpxl1 <= round(p0x);
        ypxl1 <= ipart(p0y + gradient * (round(p0x) - p0x));
        go(DAAL7);
    end
DAAL7:
    begin
        if (steep) begin
            gcx <= ypxl1[31:16];
            gcy <= xpxl1[31:16]; 
        end
        else begin
            gcx <= xpxl1[31:16];
            gcy <= ypxl1[31:16]; 
        end
        go(DAAL7a);
    end
DAAL7a:
	begin
	    ram_ce <= `HIGH;
		ram_addr <= zbuf ? ma[19:3] : ma;
		push_go(DAAL8,DELAY2);
	end
DAAL8:
    begin
        set_pixel(penColor,(rfpart(yend) * xgap) >> 16,4'd3);
        if (steep) begin
            gcx <= ypxl1[31:16] + 16'd1;
            gcy <= xpxl1[31:16];
        end
        else begin
            gcx <= xpxl1[31:16] + 16'd1;
            gcy <= ypxl1[31:16];
        end
        go(DAAL8a);
    end
DAAL8a:
	begin
	    ram_ce <= `HIGH;
		ram_addr <= zbuf ? ma[19:3] : ma;
		push_go(DAAL9,DELAY2);
	end
DAAL9:
    begin
        set_pixel(penColor,(fpart(yend) * xgap) >> 16,4'd3);
        intery <= yend + gradient;
        go(DAAL10);
    end
DAAL10:
    begin
        //xend <= round(p1x); // + 0.5
        yend <= p1y + gradient * (round(p1x) - p1x);
        xgap <= rfpart(p1x + 32'h8000);
        xpxl2 <= round(p1x);
        ypxl2 <= ipart(p1y + gradient * (round(p1x) - p1x));
        go(DAAL11);
    end
DAAL11:
    begin
        if (steep) begin
            gcx <= ypxl2[31:16];
            gcy <= xpxl2[31:16]; 
        end
        else begin
            gcx <= xpxl2[31:16];
            gcy <= ypxl2[31:16]; 
        end
        go(DAAL11a);
    end
DAAL11a:
	begin
	    ram_ce <= `HIGH;
		ram_addr <= zbuf ? ma[19:3] : ma;
		push_go(DAAL12,DELAY2);
	end
DAAL12:
    begin
        set_pixel(penColor,(rfpart(yend) * xgap) >> 16,4'd3);
        if (steep) begin
            gcx <= ypxl2[31:16] + 16'd1;
            gcy <= xpxl2[31:16];
        end
        else begin
            gcx <= xpxl2[31:16] + 16'd1;
            gcy <= ypxl2[31:16];
        end
        go(DAAL12a);
    end
DAAL12a:
	begin
	    ram_ce <= `HIGH;
		ram_addr <= zbuf ? ma[19:3] : ma;
		push_go(DAAL13,DELAY2);
	end
DAAL13:
    begin
        set_pixel(penColor,(fpart(yend) * xgap) >> 16,4'd3);
        curx0 <= xpxl1 + 32'h10000;
        curx1 <= xpxl2 - 32'h10000;
        loopcnt <= 5'd31;
        go(DAAL15);
    end
DAAL15:
    begin
        if (steep) begin
            gcx <= intery[31:16];
            gcy <= curx0[31:16];
        end
        else begin
            gcy <= intery[31:16];
            gcx <= curx0[31:16];
        end
        go(DAAL15a);
    end
DAAL15a:
	begin
	    ram_ce <= `HIGH;
		ram_addr <= zbuf ? ma[19:3] : ma;
		push_go(DAAL16,DELAY2);
	end
DAAL16:
    begin
        set_pixel(penColor,rfpart(intery),4'd3);
        if (steep) begin
            gcx <= intery[31:16] + 16'd1;
            gcy <= curx0[31:16];
        end
        else begin
            gcy <= intery[31:16] + 16'd1;
            gcx <= curx0[31:16];
        end
        curx0 <= curx0 + 32'h10000;
        intery <= intery + gradient;
        go(DAAL16a);
    end
DAAL16a:
	begin
	    ram_ce <= `HIGH;
		ram_addr <= zbuf ? ma[19:3] : ma;
		push_go(DAAL17,DELAY2);
	end
DAAL17:
    begin
        set_pixel(penColor,fpart(intery),4'd3);
        loopcnt <= loopcnt - 5'd1;
        if (curx0 >= curx1)
            ret();
        else if (loopcnt==5'd0)
            pause(DAAL15a);
        else
            go(DAAL15a);
        if (steep) begin
            gcx <= intery[31:16];
            gcy <= curx0[31:16];
        end
        else begin
            gcy <= intery[31:16];
            gcx <= curx0[31:16];
        end
    end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Draw horizontal line
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

// Swap the x-coordinate so that the line is always drawn left to right.
HL_LINE:
	begin
		loopcnt <= 5'd31;
		if (curx0 <= curx1) begin
    		gcx <= curx0[31:16];
    		endx <= curx1;
    	end
    	else begin
    	    gcx <= curx1[31:16];
    	    endx <= curx0;
    	end
		if (((ctrl[11:8] != 4'h1) &&
            (ctrl[11:8] != 4'h0) &&
            (ctrl[11:8] != 4'hF)) || zbuf)
            go(HL_GETPIXEL);
        else
            go(HL_SETPIXEL);
	end
HL_GETPIXEL:
    begin
        ram_ce <= `HIGH;
        ram_addr <= zbuf ? ma[19:3] : ma;
        push_go(HL_SETPIXEL,DELAY2);
    end
HL_SETPIXEL:
	begin
		set_pixel(fillColor,0,ctrl[11:8]);
		loopcnt <= loopcnt - 5'd1;
		gcx <= gcx + 16'd1;
		if (gcx>=endx[31:16])
			ret();
		else if (loopcnt==5'd0) begin
            if (((ctrl[11:8] != 4'h1) &&
                (ctrl[11:8] != 4'h0) &&
                (ctrl[11:8] != 4'hF)) || zbuf)
                pause(HL_GETPIXEL);
            else
            	pause(HL_SETPIXEL);
		end
		else if (((ctrl[11:8] != 4'h1) &&
            (ctrl[11:8] != 4'h0) &&
            (ctrl[11:8] != 4'hF)) || zbuf)
            go(HL_GETPIXEL);
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Filled Triangle drawing
// Uses the standard method for drawing filled triangles.
// Requires some fixed point math and division / multiplication.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

// First step - sort vertices
DT_START:								// allows p?? to update
    begin
    up0xs <= up0x;
    up0ys <= up0y;
    up0zs <= up0z;
    up1xs <= up1x;
    up1ys <= up1y;
    up1zs <= up1z;
    up2xs <= up2x;
    up2ys <= up2y;
    up2zs <= up2z;
	go(DT_SORT);
	end

DT_SORT:
	begin
		ctrl[14] <= 1'b1;				// set busy indicator
		if (p0y == p1y && p0y == p2y) begin
		   if (p0x < p1x && p0x < p2x)
		       curx0 <= p0x;
		   else if (p1x < p2x)
		       curx0 <= p1x;
		   else
		       curx0 <= p2x;
		   if (p0x > p1x && p0x > p2x)
		       curx1 <= p0x;
		   else if (p1x > p2x)
		       curx1 <= p1x;
		   else
		       curx1 <= p2x;
		   gcy <= p0y[31:16];
           go(HL_LINE);
		end
		else if (p0y <= p1y && p0y <= p2y) begin
		    minY <= p0y;
			v0x <= p0x;
			v0y <= p0y;
			if (p1y <= p2y) begin
				v1x <= p1x;
				v1y <= p1y;
				v2x <= p2x;
				v2y <= p2y;
				maxY <= p2y;
			end
			else begin
				v1x <= p2x;
				v1y <= p2y;
				v2x <= p1x;
				v2y <= p1y;
				maxY <= p1y;
			end
		end
		else if (p1y <= p2y) begin
		    minY <= p1y;
			v0y <= p1y;
			v0x <= p1x;
			if (p0y <= p2y) begin
				v1y <= p0y;
				v1x <= p0x;
				v2y <= p2y;
				v2x <= p2x;
				maxY <= p2y;
			end
			else begin
				v1y <= p2y;
				v1x <= p2x;
				v2y <= p0y;
				v2x <= p0x;
				maxY <= p0y;
			end
		end
		// y2 < y0 && y2 < y1
		else begin
			v0y <= p2y;
			v0x <= p2x;
			minY <= p2y;
			if (p0y <= p1y) begin
				v1y <= p0y;
				v1x <= p0x;
				v2y <= p1y;
				v2x <= p1x;
				maxY <= p1y;
			end
			else begin
				v1y <= p1y;
				v1x <= p1x;
				v2y <= p0y;
				v2x <= p0x;
				maxY <= p0y;
			end
		end
		// Determine minium and maximum X coord.
		if (p0x <= p1x && p0x <= p2x) begin
		    minX <= p0x;
		    if (p1x <= p2x)
		        maxX <= p2x;
		    else
		        maxX <= p1x;
		end
		else if (p1x <= p2x) begin
		    minX <= p1x;
		    if (p0x <= p2x)
		        maxX <= p2x;
		    else
		        maxX <= p0x;
		end
		else begin
		    minX <= p2x;
		    if (p0x < p1x)
		        maxX <= p1x;
		    else
		        maxX <= p0x;
		end
		    
		go(DT1);
	end

// Flat bottom (FB) or flat top (FT) triangle drawing
// Calc inv slopes
DT_SLOPE1:
	begin
		div_ld <= `TRUE;
		trimd <= 8'hE0;
		if (fbt) begin
			div_a <= w1x - w0x;
			div_b <= w1y - w0y;
		end
		else begin
			div_a <= w2x - w0x;
			div_b <= w2y - w0y;
		end
		pause(DT_SLOPE1a);
	end
DT_SLOPE1a:
	begin
		trimd <= {trimd[6:0],1'b0};
		if (div_idle && trimd==8'h00) begin
			invslope0 <= div_qo[31:0];
			if (fbt) begin
				div_a <= w2x - w0x;
				div_b <= w2y - w0y;
			end
			else begin
				div_a <= w2x - w1x;
				div_b <= w2y - w1y;
			end
			div_ld <= `TRUE;
    		trimd <= 8'hE0;
			pause(DT_SLOPE2);
		end
	end
DT_SLOPE2:
	begin
		trimd <= {trimd[6:0],1'b0};
		if (div_idle && trimd==8'h00) begin
			invslope1 <= div_qo[31:0];
		    if (fbt) begin
			    curx0 <= w0x;
		   	    curx1 <= w0x;
				gcy <= w0y[31:16];
				push_go(DT_INCY,HL_LINE);
			end
			else begin
			    curx0 <= w2x;
		        curx1 <= w2x;
		        gcy <= w2y[31:16];
				push_go(DT_INCY,HL_LINE);
			end
		end
	end
DT_INCY:
	begin
		if (fbt) begin
		    if (curx0 + invslope0 < minX)
		        curx0 <= minX;
		    else if (curx0 + invslope0 > maxX)
		        curx0 <= maxX;
		    else
			    curx0 <= curx0 + invslope0;
			if (curx1 + invslope1 < minX)
			    curx1 <= minX;
			else if (curx1 + invslope1 > maxX)
			    curx1 <= maxX;
			else
			    curx1 <= curx1 + invslope1;
			gcy <= gcy + 12'd1;
			if (gcy>=w1y[31:16])
				ret();
			else
				push_go(DT_INCY,HL_LINE);
		end
		else begin
		    if (curx0 - invslope0 < minX)
                curx0 <= minX;
            else if (curx0 - invslope0 > maxX)
                curx0 <= maxX;
            else
                curx0 <= curx0 - invslope0;
            if (curx1 - invslope1 < minX)
                curx1 <= minX;
            else if (curx1 - invslope1 > maxX)
                curx1 <= maxX;
            else
                curx1 <= curx1 - invslope1;
			gcy <= gcy - 12'd1;
			if (gcy<w0y[31:16])
				ret();
			else
				push_go(DT_INCY,HL_LINE);
		end
	end

DT1:
	begin
		// Simple case of flat bottom
		if (v1y==v2y) begin
			fbt <= 1'b1;
			w0x <= v0x;
			w0y <= v0y;
			w1x <= v1x;
			w1y <= v1y;
			w2x <= v2x;
			w2y <= v2y;
			push_go(DT6,DT_SLOPE1);
		end
		// Simple case of flat top
		else if (v0y==v1y) begin
			fbt <= 1'b0;
			w0x <= v0x;
			w0y <= v0y;
			w1x <= v1x;
			w1y <= v1y;
			w2x <= v2x;
			w2y <= v2y;
			push_go(DT6,DT_SLOPE1);
		end
		// Need to calculte 4th vertice
		else begin
			div_ld <= `TRUE;
			div_a <= v1y - v0y;
			div_b <= v2y - v0y;
			trimd <= 8'hE0;
			pause(DT2);
		end
	end
DT2:
	begin
		trimd <= {trimd[6:0],1'b0};
		if (div_idle && trimd==8'h00) begin
			trimd <= 8'b11111111;
			v3y <= v1y;
			go(DT3);
		end
	end
DT3:
	begin
		trimd <= {trimd[6:0],1'b0};
		if (trimd==8'h00) begin
			v3x <= v0x + trimult[47:16];
			v3x[15:0] <= 16'h0000;
			go(DT4);
		end
	end
DT4:
	begin
		fbt <= 1'b1;
		w0x <= v0x;
		w0y <= v0y;
		w1x <= v1x;
		w1y <= v1y;
		w2x <= v3x;
		w2y <= v3y;
		push_go(DT5,DT_SLOPE1);
	end
DT5:
	begin
		fbt <= 1'b0;
		w0x <= v1x;
		w0y <= v1y;
		w1x <= v3x;
		w1y <= v3y;
		w2x <= v2x;
		w2y <= v2y;
		push_go(DT6,DT_SLOPE1);
	end
DT6:
	begin
		ngs <= ST_IDLE;
		if (retstate==ST_IDLE) begin
	        ctrl[14] <= 1'b0;
	        ret();
		    //go(DT7);
		end
		else
 		    ret();
	end

// Outline the triangle with anti-aliased lines
/*
DT7:
    begin
        openColor <= penColor;
        penColor <= fillColor;
        up0x <= up0xs;
        up0y <= up0ys;
        up1x <= up1xs;
        up1y <= up1ys;
        push_go(DT8,DAAL1);
    end
DT8:
    begin
        up0x <= up1xs;
        up0y <= up1ys;
        up1x <= up2xs;
        up1y <= up2ys;
        push_go(DT9,DAAL1);
    end
DT9:
    begin
        up0x <= up2xs;
        up0y <= up2ys;
        up1x <= up0xs;
        up1y <= up0ys;
        push_go(DT10,DAAL1);
    end
DT10:
    begin
        penColor <= openColor;
        ctrl[14] <= 1'b0;
        ret();
    end
*/

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Bezier Curve
// B(t) = (1-t)[(1-t)P0+tP1] + t[(1-t)P1 + tP2], 0 <= t <= 1.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

BC0:
	begin
	ctrl[14] <= 1'b1;
	bv0x <= p0x;
	bv0y <= p0y;
	bv1x <= p1x;
	bv1y <= p1y;
	bv2x <= p2x;
	bv2y <= p2y;
	bezierT <= 32'h0;
	otransform <= transform;
	transform <= `FALSE;
	up0x <= p0x;
	up0y <= p0y;
	go(BC1);
	end
BC1:
	begin
	bezier1mT <= 32'h10000 - bezierT;
	go(BC2);
	end
BC2:
	begin
	bezier1mTP0xw <= bezier1mT * bv0x;
	bezier1mTP1xw <= bezier1mT * bv1x;
	bezierTP1x <= bezierT * bv1x;
	bezierTP2x <= bezierT * bv2x;
	bezier1mTP0yw <= bezier1mT * bv0y;
	bezier1mTP1yw <= bezier1mT * bv1y;
	bezierTP1y <= bezierT * bv1y;
	bezierTP2y <= bezierT * bv2y;
	go(BC3);
	end
BC3:
	begin
	bezierP0plusP1x <= bezier1mTP0xw[47:16] + bezierTP1x[47:16];
	bezierP1plusP2x <= bezier1mTP1xw[47:16] + bezierTP2x[47:16];
	bezierP0plusP1y <= bezier1mTP0yw[47:16] + bezierTP1y[47:16];
	bezierP1plusP2y <= bezier1mTP1yw[47:16] + bezierTP2y[47:16];
	go(BC4);
	end
BC4:
	begin
	bezierBxw <= bezier1mT * bezierP0plusP1x + bezierT * bezierP1plusP2x;
	bezierByw <= bezier1mT * bezierP0plusP1y + bezierT * bezierP1plusP2y;
	go(BC5);
	end
BC5:
	begin
	up1x <= bezierBxw[47:16];
	up1y <= bezierByw[47:16];
    if (fillCurve[1]) begin
        up2x <= bv1x;
        up2y <= bv1y;
    end
	go(BC5a);
	end
BC5a:
	begin
	ctrl[14] <= 1'b0;
	push_go(|fillCurve ? BC6 : BC7,DL_PRECALC);
	end
BC6:
    begin
	ctrl[14] <= 1'b0;
	push_go(BC7,DT_START);
    end
BC7:
	begin
	go(BC1);
    up0x <= up1x;
    up0y <= up1y;
    bezierT <= bezierT + bezierInc;
    if (bezierT >= 32'h10000) begin
    	up1x <= up2x;
    	up1y <= up2y;
    	push_go(BC8,|fillCurve ? DT_START : DL_PRECALC);
    	//go(BC8);
    end
	end
BC8:
	begin
    ctrl[14] <= 1'b0;
    //push_go(BC9,DL_PRECALC);
    go(BC9);
    end
BC9:
	begin
    ctrl[14] <= 1'b0;
    transform <= otransform;
    go(ST_IDLE);
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Draw a filled rectangle, uses the blitter.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_FILLRECT:
	begin
		state <= ST_FILLRECT1;
	end
ST_FILLRECT1:
	begin
		// Switching the points around will have the side effect
		// of switching the transformed points around as well.
		if (p1y < p0y) up0y <= up1y;
		if (p1x < p0x) up0x <= up1x;
		dx <= absx1mx0[31:16] + 12'd1;
		dy <= absy1my0[31:16] + 12'd1;
		if (bltCtrl[13])
			state <= ST_FILLRECT_CLIP;
	end
ST_FILLRECT_CLIP:
	begin
		if (p0x[31:16] + dx > TargetWidth)
			dx <= TargetWidth - p0x[31:16];
		if (p0y[31:16] + dy > TargetHeight)
			dy <= TargetHeight - p0y[31:16];
		state <= ST_FILLRECT2;
	end
ST_FILLRECT2:
	begin
		bltD_badr <= {8'h00,p0y[31:16]} * TargetWidth + TargetBase + p0x[31:16];
		bltD_mod <= TargetWidth - dx;
		bltD_cnt <= dx * dy;
		bltDstWid <= dx;
		bltD_dat <= fillColor[15:0];
		bltCtrl <= 16'h8080;
		ctrl[14] <= 1'b0;
		state <= ST_IDLE;
	end

ST_TILERECT:
	begin
		state <= ST_TILERECT1;
	end
ST_TILERECT1:
	begin
		// Switching the points around will have the side effect
		// of switching the transformed points around as well.
		if (p1y < p0y) up0y <= up1y;
		if (p1x < p0x) up0x <= up1x;
		dx <= absx1mx0[31:16] + 12'd1;
		dy <= absy1my0[31:16] + 12'd1;
		if (bltCtrl[13])
			state <= ST_TILERECT_CLIP;
	end
ST_TILERECT_CLIP:
	begin
		if (p0x[31:16] + dx > TargetWidth)
			dx <= TargetWidth - p0x[31:16];
		if (p0y[31:16] + dy > TargetHeight)
			dy <= TargetHeight - p0y[31:16];
		state <= ST_TILERECT2;
	end
ST_TILERECT2:
	begin
		bltA_badr <= TextureDesco[19:0];
		bltA_mod <= TextureDesco[75:64];
		bltA_cnt <= TextureDesco[47:32];
		bltSrcWid <= TextureDesco[63:48];
		bltD_badr <= {8'h00,p0y[31:16]} * TargetWidth + TargetBase + p0x[31:16];
		bltD_mod <= TargetWidth - dx;
		bltD_cnt <= dx * dy;
		bltDstWid <= dx;
		bltD_dat <= penColor;
		bltCtrl <= 16'h8082;
		ctrl[14] <= 1'b0;
		state <= ST_IDLE;
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Copper
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_COPPER_IFETCH:
	begin
	    ram_ce <= `HIGH;
		ram_addr <= copper_pc;
		copper_pc <= copper_pc + 20'd4;
		state <= ST_COPPER_IFETCH2;
	end
ST_COPPER_IFETCH2:
	begin
		ram_addr <= ram_addr + 20'd1;
		state <= ST_COPPER_IFETCH3;
	end
ST_COPPER_IFETCH3:
	begin
		ram_addr <= ram_addr + 20'd1;
		copper_ir[63:48] <= ram_data_o;
		state <= ST_COPPER_IFETCH5;
	end
ST_COPPER_IFETCH4:
	begin
		ram_addr <= ram_addr + 20'd1;
		copper_ir[47:32] <= ram_data_o;
		state <= ST_COPPER_IFETCH5;
	end
ST_COPPER_IFETCH5:
	begin
		ram_addr <= ram_addr + 20'd1;
		copper_ir[31:16] <= ram_data_o;
		state <= ST_COPPER_IFETCH6;
	end
ST_COPPER_IFETCH6:
	begin
		copper_ir[15:0] <= ram_data_o;
		state <= ST_COPPER_EXECUTE;
	end
ST_COPPER_EXECUTE:
	begin
	    ram_ce <= `LOW;
		case(copper_ir[63:62])
		2'b00:	// WAIT
			begin
				copper_b <= copper_ir[58];
				copper_f <= copper_ir[57:53];
				copper_v <= copper_ir[52:41];
				copper_h <= copper_ir[40:29];
				copper_mf <= copper_ir[28:24];
				copper_mv <= copper_ir[23:12];
				copper_mh <= copper_ir[11:0];
				copper_state <= 2'b10;
				state <= ST_IDLE;
			end
		2'b01:	// MOVE
			begin
				reg_copper <= `TRUE;
				reg_we <= {2{`HIGH}};
				reg_adr <= copper_ir[42:32];
				reg_dat <= copper_ir[15:0];
				state <= ST_IDLE;
			end
		2'b10:	// SKIP
			begin
				copper_b <= copper_ir[58];
				copper_f <= copper_ir[57:53];
				copper_v <= copper_ir[52:41];
				copper_h <= copper_ir[40:29];
				copper_mf <= copper_ir[28:24];
				copper_mv <= copper_ir[23:12];
				copper_mh <= copper_ir[11:0];
				state <= ST_COPPER_SKIP;
			end
		2'b11:	// JUMP
			begin
				copper_adr[copper_ir[55:52]] <= copper_pc;
				casex({copper_ir[51:49],bltCtrl[13]})
				4'b000x:	copper_pc <= copper_ir[19:0];
				4'b0010:	copper_pc <= copper_pc - 20'd4;
				4'b0011:	copper_pc <= copper_ir[19:0];
				4'b0100:	copper_pc <= copper_ir[19:0];
				4'b0101:	copper_pc <= copper_pc - 20'd4;
				4'b100x:	copper_pc <= copper_adr[copper_ir[47:44]];
				4'b1010:	copper_pc <= copper_pc - 20'd4;
				4'b1011:	copper_pc <= copper_adr[copper_ir[47:44]];
				4'b1100:	copper_pc <= copper_adr[copper_ir[47:44]];
				4'b1101:	copper_pc <= copper_pc - 20'd4;
				default:	copper_pc <= copper_ir[19:0];
				endcase
				state <= ST_IDLE;
			end
		endcase
	end
ST_COPPER_SKIP:
	begin
		if ((cmppos > {copper_f,copper_v,copper_h})&&(copper_b ? bltCtrl[13] : 1'b1))
			copper_pc <= copper_pc + 20'd4;
		state <= ST_IDLE;
	end
default:
	state <= ST_IDLE;
endcase
if (hpos==12'd1 && vpos==12'd1 && (fpos==4'd1 || copper_ctrl[1])) begin
	copper_pc <= copper_adr[0];
	copper_state <= {1'b0,copper_en};
end
end

task set_pixel;
input [15:0] color;
input [15:0] alpha;
input [3:0] rop;
begin
	ram_we <= 2'b00;
	zbram_we <= 2'b00;
    ram_ce <= `HIGH;
	ram_addr <= zbuf ? ma[19:3] : ma;
	if (zbuf) begin
		if (clipEnable && (gcx < clipX0 || gcx >= clipX1 || gcy < clipY0 || gcy >= clipY1))
			;
		else if (gcx >= TargetWidth || gcy >= TargetHeight)
			;
		else begin
			zbram_we <= 2'b11;
			ram_data_i <= zbram_data_o & ~{2'b11 << {ma[2:0],1'b0}} | (zlayer << {ma[2:0],1'b0});
		end
	end
	else begin
		if (clipEnable && (gcx < clipX0 || gcx >= clipX1 || gcy < clipY0 || gcy >= clipY1))
			;
		else if (gcx >= TargetWidth || gcy >= TargetHeight)
			;
		else begin
			ram_we <= 2'b11;
			case(rop)
			4'd0:	ram_data_i <= 16'h0000;
			4'd1:	ram_data_i <= color;
			4'd3:	ram_data_i <= blend(color,ram_data_o,alpha);
			4'd4:	ram_data_i <= color & ram_data_o;
			4'd5:	ram_data_i <= color | ram_data_o;
			4'd6:	ram_data_i <= color ^ ram_data_o;
			4'd7:	ram_data_i <= color & ~ram_data_o;
			4'hF:	ram_data_i <= 16'h7FFF;
			endcase
		end
	end
end
endtask

task go;
input [7:0] st;
begin
	state <= st;
end
endtask

task push_go;
input [7:0] rst;
input [7:0] nst;
begin
	retstate4 <= retstate3;
	retstate3 <= retstate2;
	retstate2 <= retstate;
	retstate <= rst;
	state <= nst;
end
endtask

task ret;
begin
	state <= retstate;
	retstate <= retstate2;
	retstate2 <= retstate3;
	retstate3 <= retstate4;
	retstate4 <= ST_IDLE;
end
endtask

task pause;
input [7:0] st;
begin
	ngs <= st;
	state <= ST_IDLE;
end
endtask

endmodule
