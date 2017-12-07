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
`define BASEADRH	120:105
`define BASEADRL	136:121
`define CMDQ_SZ		136
`define TXHANDLE	8:0
`define TXCOUNT		24:9
`define TXMOD		40:25
`define TXWIDTH		52:41

//`define USE_FIFO
`define AUD_PLOT
//`define ORGFX

module AVController(
	clk200_i,
	rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o,
	cs_i, cs_ram_i, irq_o,
	clk, eol, eof, blank, border, vbl_int, rgb,
	aud0_out, aud1_out, aud2_out, aud3_out, aud_in
);
input clk200_i;
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
input eol;
input eof;
input blank;
input border;
input vbl_int;
output reg [14:0] rgb;

output reg [15:0] aud0_out;
output reg [15:0] aud1_out;
output reg [15:0] aud2_out;
output reg [15:0] aud3_out;
input [15:0] aud_in;

parameter NSPR = 16;
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
parameter ST_AUD1 = 7'd68;
parameter ST_AUD2 = 7'd72;
parameter ST_AUD3 = 7'd76;
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

integer n;
reg [6:0] state = ST_IDLE;
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

// ctrl
// -b--- rrrr ---- cccc
//  |      |         +-- grpahics command
//  |      +------------ raster op
// +-------------------- busy indicator
reg [15:0] ctrl;
reg [1:0] lowres = 2'b01;
reg [19:0] bmpBase = 20'h00000;		// base address of bitmap
reg [19:0] charBmpBase = 20'h5C000;	// base address of character bitmaps
reg [11:0] hstart = 12'hF03;		// -253
reg [11:0] vstart = 12'hFD4;		// -44
reg [11:0] hpos;
reg [11:0] vpos;
reg [4:0] fpos;
reg [15:0] bitmapWidth = 16'd400;
reg [15:0] borderColor;
wire [15:0] rgb_i;					// internal rgb output from ram

reg [`CMDQ_SZ:0] cmdq_in;
wire [`CMDQ_SZ:0] cmdq_out;

reg zbuf;							// z buffer flag
reg [3:0] zlayer;
// Line draw
reg [13:0] x0,y0,x1,y1,x2,y2;
reg [13:0] x0a,y0a,x1a,y1a,x2a,y2a;
wire signed [13:0] absx1mx0 = (x1 < x0) ? x0-x1 : x1-x0;
wire signed [13:0] absy1my0 = (y1 < y0) ? y0-y1 : y1-y0;
reg [13:0] gcx,gcy;		// graphics cursor position
reg [11:0] ppl;
wire [19:0] cyPPL = gcy * bitmapWidth;
wire [19:0] offset = cyPPL + gcx;
wire [19:0] ma = bmpBase + offset;
reg signed [13:0] dx,dy;
reg signed [13:0] sx,sy;
reg signed [13:0] err;
wire signed [13:0] e2 = err << 1;

reg [5:0] flashcnt;

// Cursor related registers
reg [15:0] collision;
reg cursor;
reg [15:0] cursorEnable;
reg [11:0] cursor_pv [0:NSPR-1];
reg [11:0] cursor_ph [0:NSPR-1];
reg [3:0] cursor_pz [0:NSPR-1];
reg [9:0] cya [0:NSPR-1];
reg [22:0] cursor_color [0:63];
reg [15:0] cursor_on;
reg [15:0] cursor_on_d1;
reg [15:0] cursor_on_d2;
reg [15:0] cursor_on_d3;
reg [19:0] cursorAddr [0:NSPR-1];
reg [63:0] cursorBmp [0:NSPR-1];
reg [15:0] cursorColor [0:NSPR-1];
reg [15:0] cursorLink1;
reg [15:0] cursorLink2;
reg [5:0] cursorColorNdx [0:NSPR-1];
reg [9:0] cursor_szv [0:NSPR-1];
reg [4:0] cursor_szh [0:NSPR-1];
reg [15:0] cursor_bmp [0:NSPR-1];

reg [18:0] rdndx;					// video read index
reg [18:0] ram_addr;
reg [15:0] ram_data_i;
wire [15:0] ram_data_o;
wire [15:0] zbram_data_o;
reg [1:0] ram_we;
reg [1:0] zbram_we;

reg [19:0] font_tbl_adr;			// address of the font table
reg [15:0] font_id;
reg font_fixed;						// 1 = fixed width font
reg [4:0] font_height;
reg [4:0] font_width;
reg [19:0] glyph_tbl_adr;			// address of the glyph table

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

reg [19:0] srcA_badr;               // base address
reg [19:0] srcA_mod;                // modulo
reg [19:0] srcA_cnt;
reg [19:0] srcA_wadr;				// working address
reg [19:0] srcA_wcnt;				// working count
reg [19:0] srcA_dcnt;				// working count
reg [19:0] srcA_hcnt;

reg [19:0] srcB_badr;
reg [19:0] srcB_mod;
reg [19:0] srcB_cnt;
reg [19:0] srcB_wadr;				// working address
reg [19:0] srcB_wcnt;				// working count
reg [19:0] srcB_dcnt;				// working count
reg [19:0] srcB_hcnt;

reg [19:0] srcC_badr;
reg [19:0] srcC_mod;
reg [19:0] srcC_cnt;
reg [19:0] srcC_wadr;				// working address
reg [19:0] srcC_wcnt;				// working count
reg [19:0] srcC_dcnt;				// working count
reg [19:0] srcC_hcnt;

reg [19:0] dstD_badr;
reg [19:0] dstD_mod;
reg [19:0] dstD_cnt;
reg [19:0] dstD_wadr;				// working address
reg [19:0] dstD_wcnt;				// working count
reg [19:0] dstD_hcnt;

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

wire gfx_cyc;
wire gfx_stb;
wire gfx_we;
wire [31:0] gfx_adr;
wire [3:0] gfx_sel;
reg gfx_ack_i;
reg [31:0] gfx_dat_i;
wire [31:0] gfx_dat_o;

reg [15:0] gfxs_ctrl;
wire gfxs_ack_o;
wire [31:0] gfxs_dat_o;
reg [31:0] gfxs_ldat_o; // latched data out
reg [31:0] gfxs_dat_i;
reg [31:0] gfxs_adr_i;

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

reg srstA, srstB, srstC;
reg bltRdf;

`ifdef USE_FIFO
bltFifo ubfA
(
  .clk(clk_i),
  .srst(srstA),
  .din(bltA_in),
  .wr_en(wrA),
  .rd_en(bltRdf),
  .dout(bltA_out),
  .full(),
  .empty()
);

bltFifo ubfB
(
  .clk(clk_i),
  .srst(srstB),
  .din(bltB_in),
  .wr_en(wrB),
  .rd_en(bltRdf),
  .dout(bltB_out),
  .full(),
  .empty()
);

bltFifo ubfC
(
  .clk(clk_i),
  .srst(srstC),
  .din(bltC_in),
  .wr_en(wrC),
  .rd_en(bltRdf),
  .dout(bltC_out),
  .full(),
  .empty()
);
`else
vtdl #(.WID(16), .DEP(32)) bltA (.clk(clk_i), .ce(wrA), .a(bltAa), .d(bltA_in), .q(bltA_out1));
vtdl #(.WID(16), .DEP(32)) bltB (.clk(clk_i), .ce(wrB), .a(bltBa), .d(bltB_in), .q(bltB_out1));
vtdl #(.WID(16), .DEP(32)) bltC (.clk(clk_i), .ce(wrC), .a(bltCa), .d(bltC_in), .q(bltC_out1));
`endif

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

reg [19:0] blt_addr [0:63];			// base address of BLT bitmap
reg [ 9:0] blt_pix  [0:63];			// number of pixels in BLT
reg [ 9:0] blt_hmax [0:63];			// horizontal size of BLT
reg [11:0] blt_mod	[0:63];			// modulo value

reg [ 9:0] blt_x	[0:63];			// BLT's x position
reg [ 9:0] blt_y	[0:63];			// BLT's y position
reg [19:0] blt_cadr [0:63];			// current address
reg [ 9:0] blt_pc	[0:63];			// current pixel count
reg [ 9:0] blt_hctr	[0:63];			// current horizontal count
reg [ 9:0] blt_vctr	[0:63];			// current vertical count
reg [63:0] blt_dirty;				// dirty flag

// Intermediate hold registers
reg [19:0] tgtaddr;					// upper left corner of target in bitmap
reg [19:0] tgtindex;				// indexing of pixel from target address point
reg [19:0] blt_addrx;
reg [9:0] blt_pcx;
reg [9:0] blt_hctrx;
reg [9:0] blt_vctrx;
reg [5:0] bltno;					// working blit number
reg [15:0] bltcolor;					// blt color as read
reg [4:0] loopcnt;

reg [ 8:0] charcode;                // character code being processed
reg [31:0] charbmp;					// hold character bitmap scanline
reg [15:0] fgcolor;					// character colors
reg [15:0] bkcolor;					// top bit indicates overlay mode
reg [3:0] pixxm, pixym;             // maximum # pixels for char


chipram16 chipram1
(
	.clka(clk200_i),
	.ena(1'b1),
	.wea(ram_we),
	.addra(ram_addr),
	.dina(ram_data_i),
	.douta(ram_data_o),
	.clkb(clk200_i),
	.enb(1'b1),
	.web(1'b0),
	.addrb(rdndx),
	.dinb(16'h0000),
	.doutb(rgb_i)
);

wire [7:0] zbx2_i;
reg [3:0] zb_i;
zbram uzbram1
(
	.clka(clk200_i),
	.ena(1'b1),
	.wea(zbram_we),
	.addra(ram_addr),
	.dina(ram_data_i),
	.douta(zbram_data_o),
	.clkb(clk200_i),
	.enb(1'b1),
	.web(1'b0),
	.addrb(rdndx[18:3]),
	.dinb(2'h00),
	.doutb(zbx2_i)
);
always @*
	zb_i <= {zbx2_i >> rdndx[2:0],2'b00};

reg [1:0] copper_op;
reg copper_b;
reg [3:0] copper_f, copper_mf;
reg [11:0] copper_h, copper_v;
reg [11:0] copper_mh, copper_mv;
reg copper_go;

wire [28:0] cmppos = {fpos,vpos,hpos} & {copper_mf,copper_mv,copper_mh};

reg [15:0] rasti_en [0:63];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// RGB output display side
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk)
	if (eol)
		hpos <= hstart;
	else
		hpos <= hpos + 12'd1;

always @(posedge clk)
	if (eof)
		vpos <= vstart;
	else if (eol)
		vpos <= vpos + 12'd1;

always @(posedge clk)
	if (eof) begin
		fpos <= fpos + 5'd1;
		flashcnt <= flashcnt + 6'd1;
	end

// cya used to generate index into the core's memory
always @(posedge clk)
begin
	for (n = 0; n < NSPR; n = n + 1)
		if (((vpos >> lowres) == cursor_pv[n]) && (lowres[1] ? vpos[1:0]==2'b00 : lowres[0] ? vpos[0]==1'b0 : 1'b1)) begin
			cya[n] <= 10'd0;
		end
		else if (eol) begin
			cya[n] <= cya[n] + 10'd1;
	   end
end

// Load the cursor bitmap from ram
// Determine when cursor output should appear
// Shift the cursor bitmap
always @(posedge clk)
begin
    casex(hpos)
    12'b1111_10xx_xx00: cursorBmp[hpos[5:2]][63:48] <= rgb_i;
    12'b1111_10xx_xx01: cursorBmp[hpos[5:2]][47:32] <= rgb_i;
    12'b1111_10xx_xx10: cursorBmp[hpos[5:2]][31:16] <= rgb_i;
    12'b1111_10xx_xx11: cursorBmp[hpos[5:2]][15:0] <= rgb_i;
    endcase
    for (n = 0; n < NSPR; n = n + 1)
        if (((vpos >> lowres) >= cursor_pv[n] && (vpos >> lowres) <= cursor_pv[n] + cursor_szv[n]) &&
            ((hpos >> lowres) >= cursor_ph[n] && (hpos >> lowres) <= cursor_ph[n] + cursor_szh[n]) &&
            cursorEnable[n]) begin
            case(lowres)
            2'd0:   cursorBmp[n] <= {cursorBmp[n][61:0],2'b00};
            2'd1:   if (hpos[0])
                        cursorBmp[n] <= {cursorBmp[n][61:0],2'b00};
            2'd2:   if (hpos[1:0]==2'b11)
                        cursorBmp[n] <= {cursorBmp[n][61:0],2'b00};
            2'd3:   if (hpos[2:0]==3'b111)
                        cursorBmp[n] <= {cursorBmp[n][61:0],2'b00};
            endcase
            cursor_on[n] <=
                cursorLink2[n] ? |{ cursorBmp[(n+2)&15][63:62],cursorBmp[(n+1)&15][63:62],cursorBmp[n][63:62]} :
                cursorLink1[n] ? |{ cursorBmp[(n+1)&15][63:62],cursorBmp[n][63:62]} : 
                |cursorBmp[n][63:62];
        end
        else
            cursor_on[n] <= 1'b0;
end

// Compute display ram index
always @(posedge clk)
begin
    casex(hpos)
    12'hF7F:
    		rdndx <= cursorAddr[hpos[5:2]+3'd1] + {cya[hpos[5:2]+3'd1][9:0] >> lowres,2'b00};
    12'b1111_10xx_xx00: rdndx <= rdndx + 20'd1;
    12'b1111_10xx_xx01: rdndx <= rdndx + 20'd1;
    12'b1111_10xx_xx10: rdndx <= rdndx + 20'd1;
    12'b1111_10xx_xx11:
    		rdndx <= cursorAddr[hpos[5:2]+3'd1] + {cya[hpos[5:2]+3'd1][9:0] >> lowres,2'b00};
    default:
            rdndx <= {8'h00,vpos >> lowres} * {4'h00,bitmapWidth} + bmpBase + {8'h00,hpos >> lowres};
    endcase
end


// Compute index into sprite color palette
// If none of the sprites are linked, each sprite has it's own set of colors.
// If the sprites are linked once the colors are available in groups.
// If the sprites are linked twice they all share the same set of colors.

always @(posedge clk)
for (n = 0; n < NSPR; n = n + 1)
if (cursorLink2[n])
    cursorColorNdx[n] <= {cursorBmp[(n+2)&15][63:62],cursorBmp[(n+1)&15][63:62],cursorBmp[n][63:62]};
else if (cursorLink1[n])
    cursorColorNdx[n] <= {n[3:2],cursorBmp[(n+1)&15][63:62],cursorBmp[n][63:62]};
else
    cursorColorNdx[n] <= {n[3:0],cursorBmp[n][63:62]};

always @(posedge clk)
    cursor_on_d1 <= cursor_on;
reg [22:0] cursorColorOut; 
always @(posedge clk)
    cursorColorOut <= 
	       		cursor_color[
	       		cursor_on_d1[0] ? cursorColorNdx[0] :
	       		cursor_on_d1[1] ? cursorColorNdx[1] :
	       		cursor_on_d1[2] ? cursorColorNdx[2] :
	       		cursor_on_d1[3] ? cursorColorNdx[3] :
	       		cursor_on_d1[4] ? cursorColorNdx[4] :
	       		cursor_on_d1[5] ? cursorColorNdx[5] :
	       		cursor_on_d1[6] ? cursorColorNdx[6] :
	       		cursor_on_d1[7] ? cursorColorNdx[7] :
	       		cursor_on_d1[8] ? cursorColorNdx[8] :
	       		cursor_on_d1[9] ? cursorColorNdx[9] :
	       		cursor_on_d1[10] ? cursorColorNdx[10] :
	       		cursor_on_d1[11] ? cursorColorNdx[11] :
	       		cursor_on_d1[12] ? cursorColorNdx[12] :
	       		cursor_on_d1[13] ? cursorColorNdx[13] :
	       		cursor_on_d1[14] ? cursorColorNdx[14] :
	       		cursorColorNdx[15]];

reg [3:0] cursor_z1, cursor_z2;
always @(posedge clk)
    cursor_z1 <= 
	       		cursor_on_d1[0] ? cursor_pz[0] :
	       		cursor_on_d1[1] ? cursor_pz[1] :
	       		cursor_on_d1[2] ? cursor_pz[2] :
	       		cursor_on_d1[3] ? cursor_pz[3] :
	       		cursor_on_d1[4] ? cursor_pz[4] :
	       		cursor_on_d1[5] ? cursor_pz[5] :
	       		cursor_on_d1[6] ? cursor_pz[6] :
	       		cursor_on_d1[7] ? cursor_pz[7] :
	       		cursor_on_d1[8] ? cursor_pz[8] :
	       		cursor_on_d1[9] ? cursor_pz[9] :
	       		cursor_on_d1[10] ? cursor_pz[10] :
	       		cursor_on_d1[11] ? cursor_pz[11] :
	       		cursor_on_d1[12] ? cursor_pz[12] :
	       		cursor_on_d1[13] ? cursor_pz[13] :
	       		cursor_on_d1[14] ? cursor_pz[14] :
	       		cursor_pz[15];
always @(posedge clk)
	cursor_z2 <= cursor_z1;

wire [12:0] alphaRed = rgb_i[14:10] * cursorColorOut[7:0];
wire [12:0] alphaGreen = rgb_i[9:5] * cursorColorOut[7:0];
wire [12:0] alphaBlue = rgb_i[4:0] * cursorColorOut[7:0];
reg [14:0] alphaOut;

always @(posedge clk)
    cursor_on_d2 <= cursor_on_d1;
always @(posedge clk)
    alphaOut = cursorColorOut[22] ?
				{alphaRed[12:8],alphaGreen[12:8],alphaBlue[12:8]} :
				cursorColorOut[14:0];

wire [14:0] reverseVideoOut = cursorColorOut[21] ? alphaOut ^ 15'h7FFF : alphaOut;
wire [14:0] flashOut = cursorColorOut[20] ? (((flashcnt[5:2] & cursorColorOut[19:16])!=4'b000) ? reverseVideoOut : rgb_i) : reverseVideoOut;

always @(posedge clk)
	rgb <= 	blank ? 15'h0000 :
		   	border ? borderColor :
//       		cursor ? (cursor_color0[15] ? rgb_i[14:0] ^ 15'h7FFF : cursor_color0) :
       		|cursor_on_d2 ? (zb_i < cursor_z2 ? rgb_i[14:0] : flashOut) : rgb_i[14:0];

reg ack,rdy;
reg rwsr;							// read / write shadow ram
wire chrp = rwsr & ~rdy;			// chrq pulse
wire cs_reg = cyc_i & stb_i & cs_i;
wire cs_ram = cyc_i & stb_i & cs_ram_i;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Command queue
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [4:0] cmdq_ndx;

wire cs_cmdq = cs_reg && adr_i[10:1]==10'b100_0010_111 && chrp && we_i;
wire cs_gfx = cs_reg && adr_i[10:1]==10'b111_0000_100;


vtdl #(.WID(105), .DEP(32)) char_q (.clk(clk_i), .ce(cs_cmdq), .a(cmdq_ndx), .d(cmdq_in), .q(cmdq_out));

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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
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
		TextureDesc[hwTexture] <= {
			cmdq_out[`TXMOD],
			cmdq_out[`TXWIDTH],
			cmdq_out[`TXCOUNT],
			cmdq_out[`BASEADRH],
			cmdq_out[`BASEADRL]
		};
wire [75:0] TextureDesco = TextureDesc[hrTexture];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [9:0] sra;						// shadow ram address
reg [15:0] shadow_ram [0:1023];		// register shadow ram
wire [15:0] srdo;					// shadow ram data out
always @(posedge clk_i)
	sra <= adr_i[10:1];
always @(posedge clk_i)
	if (cs_reg & we_i & rwsr)
		shadow_ram[sra] <= dat_i;
assign srdo = shadow_ram[sra];

reg rdy2;
always @(posedge clk_i)
	rwsr <= cs_reg;
always @(posedge clk_i)
	rdy <= rwsr & cs_reg;
always @(posedge clk_i)
	rdy2 <= rdy & cs_reg;
always @(posedge clk_i)
	ack_o <= (cs_gfx|cs_ram) ? ack & ~ack_o: cs_reg ? rdy2 & ~ack_o : 1'b0;

// Widen the eof pulse so it can be seen by clk_i
reg [11:0] vrst;
always @(posedge clk)
	if (eof)
		vrst <= 12'hFFF;
	else
		vrst <= {vrst[10:0],1'b0};

reg bltDone1;
reg [15:0] copper_ctrl;
wire copper_en = copper_ctrl[0];
reg [63:0] copper_ir;
reg [19:0] copper_pc;
reg [1:0] copper_state;
reg [19:0] copper_adr [0:15];
reg reg_copper;
reg reg_cs, reg_cs_gfx;
reg reg_we;
reg [10:0] reg_adr;
reg [15:0] reg_dat;
	
always @(posedge clk_i)
if (rst_i) begin
	state <= ST_IDLE;
	aud_test <= 24'h0;
	bltCtrl <= 16'b0010_0000_0000_0000;
end
else begin
reg_copper <= `FALSE;
reg_cs <= cs_reg;
reg_cs_gfx <= cs_gfx;
reg_we <= we_i;
reg_adr <= adr_i[10:0];
reg_dat <= dat_i;
if (reg_cs|reg_copper) begin
	if (reg_we) begin
		casex(reg_adr[10:1])
		10'b000xxxxxx0:   cursor_color[reg_adr[7:2]][22:16] <= reg_dat[6:0];
		10'b000xxxxxx1:   cursor_color[reg_adr[7:2]][15:0] <= reg_dat;
		10'b0010000000:   cursorLink1 <= reg_dat;
		10'b0010000001:   cursorLink2 <= reg_dat;
		10'b0010000010:   collision <= reg_dat;
		10'b0010000011:   cursorEnable <= reg_dat;
        10'b010_xxxx_000:   cursorAddr[reg_adr[7:4]][19:16] <= reg_dat[3:0];
        10'b010_xxxx_001:   cursorAddr[reg_adr[7:4]][15:0] <= reg_dat;
        10'b010_xxxx_010:   cursor_ph[reg_adr[7:4]] <= reg_dat[11:0];
        10'b010_xxxx_011:   cursor_pv[reg_adr[7:4]] <= reg_dat[11:0];
        10'b010_xxxx_100:   begin
                                cursor_szh[reg_adr[7:4]] <= reg_dat[4:0];
                                cursor_szv[reg_adr[7:4]] <= reg_dat[15:6];
                            end
        10'b010_xxxx_101:	cursor_pz[reg_adr[7:4]] <= reg_dat[3:0];
/*                          
		10'b0xxxxxx000:	begin
						blt_addr[reg_adr[9:4]][19:4] <= reg_dat;
						blt_addr[reg_adr[9:4]][3:0] <= 4'h0;
						end
		10'b0xxxxxx001:	blt_pix[reg_adr[9:4]] <= reg_dat[9:0];
		10'b0xxxxxx010:	blt_hmax[reg_adr[9:4]] <= reg_dat[9:0];
		10'b0xxxxxx011:	blt_x[reg_adr[9:4]] <= reg_dat[9:0];
		10'b0xxxxxx100:	blt_y[reg_adr[9:4]] <= reg_dat[9:0];
		10'b0xxxxxx101:	blt_pc[reg_adr[9:4]] <= reg_dat[9:0];
		10'b0xxxxxx110:	blt_hctr[reg_adr[9:4]] <= reg_dat[9:0];
		10'b0xxxxxx111:	blt_vctr[reg_adr[9:4]] <= reg_dat[9:0];
*/
		10'b1000000000:	bmpBase[19:16] <= reg_dat[3:0];
		10'b1000000001:	bmpBase[15:0] <= reg_dat;
		10'b1000000010:	charBmpBase[19:16] <= reg_dat[3:0];
		10'b1000000011:	charBmpBase[15:0] <= reg_dat;
		// Clear dirty bits
		10'b1000000100:	blt_dirty[15:0] <= blt_dirty[15:0] & ~reg_dat;
		10'b1000000101: blt_dirty[31:16] <= blt_dirty[31:16] & ~reg_dat;
		10'b1000000110:	blt_dirty[47:32] <= blt_dirty[47:32] & ~reg_dat;
		10'b1000000111:	blt_dirty[63:48] <= blt_dirty[63:48] & ~reg_dat;
		// Set dirty bits
		10'b1000001000:	blt_dirty[15:0] <= blt_dirty[15:0] | reg_dat;
		10'b1000001001: blt_dirty[31:16] <= blt_dirty[31:16] | reg_dat;
		10'b1000001010:	blt_dirty[47:32] <= blt_dirty[47:32] | reg_dat;
		10'b1000001011:	blt_dirty[63:48] <= blt_dirty[63:48] | reg_dat;

		10'b100_0010_000:	cmdq_in[`CHARCODE] <= reg_dat[8:0];	// char code
		10'b100_0010_001:	cmdq_in[`FGCOLOR] <= reg_dat;	// fgcolor
		10'b100_0010_010:	cmdq_in[`BKCOLOR] <= reg_dat;	// bkcolor
		10'b100_0010_011:	cmdq_in[`X0POS] <= reg_dat[11:0];	// xpos1
		10'b100_0010_100:	cmdq_in[`Y0POS] <= reg_dat[11:0];	// ypos1
		10'b100_0010_101:   begin
							cmdq_in[`CHARXM] <= reg_dat[3:0];	// fntsz
							cmdq_in[`CHARYM] <= reg_dat[11:8];	// fntsz
							end
		10'b100_0010_110: 	cmdq_ndx <= reg_dat[4:0];
		10'b100_0010_111:	cmdq_in[`CMD] <= reg_dat[7:0];	// cmd
		10'b100_0011_000:	cmdq_in[`X1POS] <= reg_dat[11:0];	// xpos2
		10'b100_0011_001:	cmdq_in[`Y1POS] <= reg_dat[11:0];	// ypos2
		10'b100_0011_010:	cmdq_in[`BASEADRH] <= reg_dat;
		10'b100_0011_011:	cmdq_in[`BASEADRL] <= reg_dat;
		10'b100_0011_110:	zlayer <= reg_dat[3:0];
		10'b100_0011_111:	zbuf <= reg_dat[0];
		
		10'b100_1000_000:	srcA_badr[19:16] <= reg_dat[3:0];
		10'b100_1000_001:	srcA_badr[15: 0] <= reg_dat;
		10'b100_1000_010:	srcA_mod[19:16] <= reg_dat[3:0];
		10'b100_1000_011:	srcA_mod[15: 0] <= reg_dat;
		10'b100_1000_100:	srcB_badr[19:16] <= reg_dat[3:0];
		10'b100_1000_101:	srcB_badr[15: 0] <= reg_dat;
		10'b100_1000_110:	srcB_mod[19:16] <= reg_dat[3:0];
		10'b100_1000_111:	srcB_mod[15: 0] <= reg_dat;
		10'b100_1001_000:	srcC_badr[19:16] <= reg_dat[3:0];
		10'b100_1001_001:	srcC_badr[15: 0] <= reg_dat;
		10'b100_1001_010:	srcC_mod[19:16] <= reg_dat[3:0];
		10'b100_1001_011:	srcC_mod[15: 0] <= reg_dat;
		10'b100_1001_100:	dstD_badr[19:16] <= reg_dat[3:0];
		10'b100_1001_101:	dstD_badr[15: 0] <= reg_dat;
		10'b100_1001_110:	dstD_mod[19:16] <= reg_dat[3:0];
		10'b100_1001_111:	dstD_mod[15: 0] <= reg_dat;
		10'b100_1010_000:	bltSrcWid[19:16] <= reg_dat[3:0];
		10'b100_1010_001:	bltSrcWid[15:0] <= reg_dat;
		10'b100_1010_010:	bltDstWid[19:16] <= reg_dat[3:0];
		10'b100_1010_011:	bltDstWid[15:0] <= reg_dat;
		10'b100_1010_100:	bltD_dat <= reg_dat;
		10'b100_1010_101:   bltPipedepth <= reg_dat[4:0];
		10'b100_1010_110:	bltCtrl <= reg_dat;
		10'b100_1010_111:	blt_op <= reg_dat;
		10'b100_1011_000:   srcA_cnt[19:16] <= reg_dat[3:0];
		10'b100_1011_001:   srcA_cnt[15:0] <= reg_dat;
		10'b100_1011_010:   srcB_cnt[19:16] <= reg_dat[3:0];
        10'b100_1011_011:   srcB_cnt[15:0] <= reg_dat;
		10'b100_1011_100:   srcC_cnt[19:16] <= reg_dat[3:0];
        10'b100_1011_101:   srcC_cnt[15:0] <= reg_dat;
		10'b100_1011_110:   dstD_cnt[19:16] <= reg_dat[3:0];
        10'b100_1011_111:   dstD_cnt[15:0] <= reg_dat;
		10'b100_110x_xx0:	copper_adr[reg_adr[4:2]][19:16] <= reg_dat[3:0];
		10'b100_110x_xx1:	copper_adr[reg_adr[4:2]][15:0] <= reg_dat;
		10'b100_1110_000:	copper_ctrl <= reg_dat;
		10'b101_0xxx_xxx:	rasti_en[reg_adr[6:1]] <= reg_dat;
		10'b101_1000_000:	irq_en <= reg_dat;
		10'b101_1000_001:	irq_status <= irq_status & ~reg_dat;
        10'b101_1000_010:	aud_ctrl <= reg_dat;
        10'b101_1000_011:   aud_ctrl2 <= reg_dat;
        10'b101_1000_100:   bitmapWidth <= reg_dat;
        10'b101_1000_110:   hstart <= reg_dat[11:0];   
        10'b101_1000_111:   vstart <= reg_dat[11:0];

		10'b101_1001_000:	font_tbl_adr[19:16] <= reg_dat[3:0];
		10'b101_1001_001:	font_tbl_adr[15:0] <= reg_dat;
		10'b101_1001_010:	font_id <= reg_dat;
		10'b101_1001_100:	bltA_dat <= reg_dat;
		10'b101_1001_101:	bltB_dat <= reg_dat;
		10'b101_1001_110:	bltC_dat <= reg_dat;
		10'b101_1010_000:	bltA_shift <= reg_dat;
		10'b101_1010_001:	bltB_shift <= reg_dat;
		10'b101_1010_010:	bltC_shift <= reg_dat;
		10'b101_1010_100:   bltFWMask <= reg_dat;
        10'b101_1010_101:   bltLWMask <= reg_dat;

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

        10'b110_0101_000:   lowres <= reg_dat[1:0];   
/*        
        10'b110_1xxx_000:	cursorAddr[reg_adr[6:4]][19:16] <= reg_dat[3:0];
        10'b110_1xxx_001:	cursorAddr[reg_adr[6:4]][15:0] <= reg_dat;
		10'b110_1xxx_010:	cursor_ph[reg_adr[6:4]] <= reg_dat[11:0];
		10'b110_1xxx_011:	cursor_pv[reg_adr[6:4]] <= reg_dat[11:0];
		10'b110_1xxx_100:	begin
								cursor_szh[reg_adr[6:4]] <= reg_dat[4:0];
								cursor_szv[reg_adr[6:4]] <= reg_dat[12:8];
							end
*/
		10'b111_0000_000:	gfxs_adr_i[31:16] <= reg_dat;
		10'b111_0000_001:	gfxs_adr_i[15:0] <= reg_dat;
        10'b111_0000_010:	gfxs_dat_i[31:16] <= reg_dat;
        10'b111_0000_011:	gfxs_dat_i[15:0] <= reg_dat;
        10'b111_0000_100:	gfxs_ctrl <= reg_dat;
        
		default:	;	// do nothing
		endcase
	end
	else begin
		case(reg_adr[10:1])
		10'b0010000010: dat_o <= collision;
		10'b1000010110:	dat_o <= {11'h00,cmdq_ndx};
		10'b1001010110:	dat_o <= bltCtrl;
		10'b1011000001:	dat_o <= irq_status;
		10'b1110000010:	dat_o <= gfxs_ldat_o[31:16];
		10'b1110000011:	dat_o <= gfxs_ldat_o[15:0];
		default:	dat_o <= srdo;
		endcase
	end
end

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
if (vbl_int)
	irq_status[0] <= `TRUE;
if (bltCtrl[13] & ~bltDone1)
	irq_status[1] <= `TRUE;
if (hpos==12'd977 && rasti_en[vpos[9:4]][vpos[3:0]])
	irq_status[2] <= `TRUE;
	
if (cs_cmdq)
	cmdq_ndx <= cmdq_ndx + 5'd1;

if (copper_state==2'b10 && (cmppos > {copper_f,copper_v,copper_h})&&(copper_b ? bltCtrl[13] : 1'b1))
	copper_state <= 2'b01;

case(cursor_on)
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
16'b1000000000000000:	;
default:	collision <= collision | cursor_on;
endcase

case(state)
ST_IDLE:
	begin
		ram_we <= {2{`LOW}};
		zbram_we <= {2{`LOW}};
		ack <= `LOW;
		
		// Audio takes precedence to avoid audio distortion.
		// Fortunately audio DMA is fast and infrequent.
		if (|aud0_req) begin
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
			srstA <= `TRUE;
			srstB <= `TRUE;
			srstC <= `TRUE;
			if (bltCtrl[1])
				state <= ST_BLTDMA1;
			else if (bltCtrl[3])
				state <= ST_BLTDMA3;
			else if (bltCtrl[5])
				state <= ST_BLTDMA5;
			else
				state <= ST_BLTDMA7;
		end
		else if (bltCtrl[15]) begin
			bltCtrl[15] <= 1'b0;
			bltCtrl[14] <= 1'b1;
			bltCtrl[13] <= 1'b0;
			bltAa <= 5'd0;
			bltBa <= 5'd0;
			bltCa <= 5'd0;
			srstA <= `TRUE;
			srstB <= `TRUE;
			srstC <= `TRUE;
			srcA_wadr <= srcA_badr;
			srcB_wadr <= srcB_badr;
			srcC_wadr <= srcC_badr;
			dstD_wadr <= dstD_badr;
			srcA_wcnt <= 20'd1;
			srcB_wcnt <= 20'd1;
			srcC_wcnt <= 20'd1;
			dstD_wcnt <= 20'd1;
			srcA_dcnt <= 20'd1;
			srcB_dcnt <= 20'd1;
			srcC_dcnt <= 20'd1;
			srcA_hcnt <= 20'd1;
			srcB_hcnt <= 20'd1;
			srcC_hcnt <= 20'd1;
			dstD_hcnt <= 20'd1;
			bltA_residue <= 16'h0000;
			bltB_residue <= 16'h0000;
			bltC_residue <= 16'h0000;
			if (bltCtrl[1])
				state <= ST_BLTDMA1;
			else if (bltCtrl[3])
				state <= ST_BLTDMA3;
			else if (bltCtrl[5])
				state <= ST_BLTDMA5;
			else
				state <= ST_BLTDMA7;
		end

		// busy with a graphics command ?
		else if (ctrl[14]) begin
//			bltCtrl[13] <= 1'b0;
			case(ctrl[3:0])
			4'd0:	state <= ST_READ_CHAR_BITMAP;
			4'd2:	state <= DL_PRECALC;
			default:	ctrl[14] <= 1'b0;
			endcase
		end

		else if (|cmdq_ndx) begin
			cmdq_ndx <= cmdq_ndx - 5'd1;
			state <= ST_CMD;
		end

		else if (|blt_dirty) begin
			for (n = 0; n < 64; n = n + 1)
				if (blt_dirty[n])
					bltno <= n;
			tgtaddr <= bmpBase;
			loopcnt <= 4'h0;
			state <= ST_BLT_INIT;
		end
		
		else if (gfxs_ctrl[0]) begin
			state <= ST_GFXS_RW;
		end

		else if (gfx_cyc) begin
			ram_we <= {2{gfx_we}} & gfx_sel;
			ram_addr <= gfx_adr[19:1];
			ram_data_i <= gfx_dat_o;
			state <= ST_GFX_RW;
		end
	end

ST_CMD:
	begin
		ctrl[3:0] <= cmd_qo[3:0];
		ctrl[14] <= 1'b0;
		case(cmd_qo[3:0])
		4'd0:	state <= ST_READ_FONT_TBL;	// draw character
		4'd1:	state <= ST_PLOT;
		4'd2:	begin
				ctrl[11:8] <= cmdq_out[12:9];	// raster op
				state <= DL_INIT;			// draw line
				end
		4'd3:	state <= ST_FILLRECT;
		4'd4:	begin
				wrtx <= 1'b1;
				hwTexture <= cmdq_out[`TXHANDLE];
				state <= ST_IDLE;
				end
		4'd5:	begin
				hrTexture <= cmdq_out[`TXHANDLE];
				state <= ST_TILERECT;
				end
		default:	state <= ST_IDLE;
		endcase
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Standard RAM read/write
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_RW:
	begin
        ack <= `HIGH;
        if (zbuf)
        	dat_o <= zbram_data_o;
        else
        	dat_o <= ram_data_o;
        if (~cs_ram) begin
            ram_we <= {2{`LOW}};
            zbram_we <= {2{`LOW}};
            ack <= `LOW;
            state <= ST_IDLE;
        end
    end

ST_GFX_RW:
	begin
        gfx_ack_i <= `HIGH;
        gfx_dat_i <= ram_data_o;
        if (!gfx_cyc) begin
            ram_we <= {2{`LOW}};
            gfx_ack_i <= `LOW;
            state <= ST_IDLE;
        end
    end

ST_GFXS_RW:
	if (gfxs_ack_o) begin
	    ack <= `HIGH;
	    gfxs_ldat_o <= gfxs_dat_o;
	    dat_o <= gfxs_adr_i[1] ? gfxs_dat_o[31:16] : gfxs_dat_o[15:0];
		gfxs_ctrl <= 16'h0000;
        state <= ST_GFXS_RW2;
    end
ST_GFXS_RW2:
    if (~cs_reg) begin
        ack <= `LOW;
        state <= ST_IDLE;
    end  
  
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Audio DMA states
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_AUD0:
	begin
		aud0_dat <= ram_data_o;
		state <= ST_IDLE;
	end
ST_AUD1:
	begin
		aud1_dat <= ram_data_o;
		state <= ST_IDLE;
	end
ST_AUD2:
	begin
		aud2_dat <= ram_data_o;
		state <= ST_IDLE;
	end
ST_AUD3:
	begin
		aud3_dat <= ram_data_o;
		state <= ST_IDLE;
	end
`ifdef AUD_PLOT
ST_AUD_PLOT:
	begin
		bkcolor <= 16'h7FFF;
		tgtaddr <= {12'h00,audi_dat[15:8]^8'h80} * {4'h00,bitmapWidth} + bmpBase + audi_wadr[7:0];
		state <= ST_AUD_PLOT_WRITE;
	end
ST_AUD_PLOT_WRITE:
	begin
		ram_we <= 2'b11;
		ram_addr <= tgtaddr;
		ram_data_i <= bkcolor;
		state <= ST_IDLE;
	end
`endif

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Pixel plot acceleration states
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_PLOT:
	begin
		bkcolor <= charbk_qo;
		tgtaddr <= {8'h00,cmdy1_qo} * {4'h00,bitmapWidth} + bmpBase + cmdx1_qo;
		state <= charbk_qo[9]|zbuf ? ST_PLOT_READ : ST_PLOT_WRITE;
	end
ST_PLOT_READ:
	begin
		ram_addr <= zbuf ? tgtaddr[19:3] : tgtaddr;
		state <= ST_PLOT_WRITE;
	end
ST_PLOT_WRITE:
	begin
		ram_addr <= zbuf ? tgtaddr[19:3] : tgtaddr;
		if (zbuf) begin
			zbram_we <= 2'b11;
			ram_data_i <= (zbram_data_o & ~(2'b11 << {tgtaddr[2:0],1'b0})) | (zlayer << {tgtaddr[2:0],1'b0});
		end
		else begin
			ram_we <= 2'b11;
			if (bkcolor[`A]) begin
				ram_data_i[`R] <= ram_data_o[`R] >> bkcolor[2:0];
				ram_data_i[`G] <= ram_data_o[`G] >> bkcolor[5:3];
				ram_data_i[`B] <= ram_data_o[`B] >> bkcolor[8:6];
			end
			else
				ram_data_i <= bkcolor;
		end
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
		charcode <= charcode_qo;
		fgcolor <= charfg_qo;
		bkcolor <= charbk_qo;
		ram_addr <= {font_tbl_adr[18:2],2'b0} + {font_id,2'b00};
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
		tgtaddr <= {8'h00,cmdy1_qo} * {4'h00,bitmapWidth} + bmpBase + cmdx1_qo;
		charBmpBase <= charBmpBase + (charcode << font_width[4]) * (font_height + 7'd1);
		if (font_fixed) begin
			ctrl[14] <= 1'b1;
			state <= ST_IDLE;
		end
		else begin
			ram_addr <= glyph_tbl_adr + charcode[8:1];
			state <= ST_READ_GLYPH_ENTRY;
		end
	end
ST_READ_GLYPH_ENTRY:
	begin
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
		bkcolor <= charbk_qo;
		pixxm <= charxm_qo;
		pixym <= charym_qo;
		tgtaddr <= {8'h00,cmdy1_qo} * {8'h00,bitmapWidth} + {bmpBase[19:12],cmdx1_qo};
		state <= ST_READ_CHAR_BITMAP;
	end
*/
ST_READ_CHAR_BITMAP:
	begin
//		ram_addr <= charBmpBase + charcode * (pixym + 4'd1) + pixvc;
		ram_addr <= charBmpBase + (pixvc << font_width[4]);
		state <= ST_READ_CHAR_BITMAP_DAT;
	end
ST_READ_CHAR_BITMAP_DAT:
	begin
		ram_addr <= ram_addr + 19'd1;
		charbmp[15:0] <= ram_data_o;
		tgtindex <= {14'h00,pixvc} * {4'h00,bitmapWidth};
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
		if (~bkcolor[`A]) begin
			ram_we <= 2'b11;
			ram_data_i <= charbmp[font_width] ? fgcolor : bkcolor;
		end
		else begin
			if (charbmp[font_width]) begin
				if (zbuf) begin
					zbram_we <= 2'b11;
					ram_data_i <= zlayer;
				end
				else begin
					ram_we <= 2'b11;
					ram_data_i <= fgcolor;
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
	        state <= ST_IDLE;
		    pixhc <= 5'd0;
		    pixvc <= pixvc + 5'd1;
		    if (pixvc==font_height)
		    	ctrl[14] <= 1'b0;
		end
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Blitter DMA
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_BLTDMA1:
	begin
		ram_we <= {2{`LOW}};
		zbram_we <= {2{`LOW}};
		bitcnt <= bltCtrl[0] ? 4'd15 : 4'd0;
        bitinc <= bltCtrl[0] ? 4'd1 : 4'd0;
		bltinc <= bltCtrl[8] ? 20'hFFFFF : 20'd1;
	    loopcnt <= bltPipedepth + 5'd1;
		bltAa <= 5'd0;
		srstA <= `FALSE;
		state <= ST_BLTDMA2;
	end
ST_BLTDMA2:
	begin
		if (loopcnt > 5'd0) begin
			ram_addr <= srcA_wadr;
			if (bitcnt==4'd0) begin
        		srcA_wadr <= srcA_wadr + bltinc;
			    srcA_hcnt <= srcA_hcnt + 20'd1;
			    if (srcA_hcnt==bltSrcWid) begin
				    srcA_hcnt <= 20'd1;
				    srcA_wadr <= srcA_wadr + srcA_mod + bltinc;
					bitcnt <= bltCtrl[0] ? 4'd15 : 4'd0;
				end
                srcA_wcnt <= srcA_wcnt + 20'd1;
                srcA_dcnt <= srcA_dcnt + 20'd1;
                if (srcA_wcnt==srcA_cnt) begin
                    srcA_wadr <= srcA_badr;
                    srcA_wcnt <= 20'd1;
                    srcA_hcnt <= 20'd1;
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
                        & ((srcA_hcnt==bltSrcWid) ? bltLWMask : 16'hFFFF)
                        & ((srcA_hcnt==20'd1) ? bltFWMask : 16'hFFFF);
            bltA_residue <= bltCtrl[8] ? (zbuf ? zbram_data_o : ram_data_o) >> (5'd16-bltA_shift[3:0]) :
            			(zbuf ? zbram_data_o : ram_data_o) << (5'd16-bltA_shift[3:0]);
        end
		loopcnt <= loopcnt - 5'd1;
		if (loopcnt==5'd0 || srcA_dcnt==dstD_cnt) begin
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
		loopcnt <= bltPipedepth + 5'd1;
		bltBa <= 5'd0;
		srstB <= `FALSE;
		state <= ST_BLTDMA4;
	end
ST_BLTDMA4:
	begin
		if (loopcnt > 5'd0) begin
			ram_addr <= srcB_wadr;
			if (bitcnt==4'd0) begin
                srcB_wadr <= srcB_wadr + bltinc;
                srcB_hcnt <= srcB_hcnt + 20'd1;
                if (srcB_hcnt==bltSrcWid) begin
                    srcB_hcnt <= 20'd1;
                    srcB_wadr <= srcB_wadr + srcB_mod + bltinc;
					bitcnt <= bltCtrl[2] ? 4'd15 : 4'd0;
                end
                srcB_wcnt <= srcB_wcnt + 20'd1;
                srcB_dcnt <= srcB_dcnt + 20'd1;
                if (srcB_wcnt==srcB_cnt) begin
                    srcB_wadr <= srcB_badr;
                    srcB_wcnt <= 20'd1;
                    srcB_hcnt <= 20'd1;
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
		if (loopcnt==5'd0 || srcB_dcnt==dstD_cnt) begin
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
		loopcnt <= bltPipedepth + 5'd1;
		bltCa <= 5'd0;
		srstC <= `FALSE;
		state <= ST_BLTDMA6;
	end
ST_BLTDMA6:
	begin
		if (loopcnt > 5'd0) begin
			ram_addr <= srcC_wadr;
			if (bitcnt==4'd0) begin
                srcC_wadr <= srcC_wadr + bltinc;
                srcC_hcnt <= srcC_hcnt + 20'd1;
                if (srcC_hcnt==bltSrcWid) begin
                    srcC_hcnt <= 20'd1;
                    srcC_wadr <= srcC_wadr + srcC_mod + bltinc;
					bitcnt <= bltCtrl[4] ? 4'd15 : 4'd0;
                end
                srcC_wcnt <= srcC_wcnt + 20'd1;
                srcC_dcnt <= srcC_dcnt + 20'd1;
                if (srcC_wcnt==srcC_cnt) begin
                    srcC_wadr <= srcC_badr;
                    srcC_wcnt <= 20'd1;
                    srcC_hcnt <= 20'd1;
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
		if (loopcnt==5'd0 || srcC_dcnt==dstD_cnt)
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
		ram_addr <= dstD_wadr;
		// If there's no source then a fill operation muct be taking place.
		if (bltCtrl[1]|bltCtrl[3]|bltCtrl[5])
			ram_data_i <= bltabc;
		else
			ram_data_i <= bltD_dat;	// fill color
		dstD_wadr <= dstD_wadr + bltinc;
		dstD_wcnt <= dstD_wcnt + 20'd1;
		dstD_hcnt <= dstD_hcnt + 24'd1;
		if (dstD_hcnt==bltDstWid) begin
			dstD_hcnt <= 24'd1;
			dstD_wadr <= dstD_wadr + dstD_mod + bltinc;
		end
		bltAa <= bltAa - 5'd1;	// move to next queue entry
		bltBa <= bltBa - 5'd1;
		bltCa <= bltCa - 5'd1;
		loopcnt <= loopcnt - 5'd1;
		if (dstD_wcnt==dstD_cnt) begin
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
// Blit draw states
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_BLT_INIT:
	begin
		blt_addrx <= blt_addr[bltno];
		blt_pcx <= blt_pc[bltno];
		blt_hctrx <= blt_hctr[bltno];
		blt_vctrx <= blt_vctr[bltno];
		state <= ST_READ_BLT_BITMAP;
	end
ST_READ_BLT_BITMAP:
	begin
		ram_addr <= blt_addrx + blt_pcx;
		state <= ST_READ_BLT_BITMAP2;
	end
	// Two ram read wait states
ST_READ_BLT_BITMAP2:
	state <= ST_READ_BLT_BITMAP3;
ST_READ_BLT_BITMAP3:
	state <= ST_READ_BLT_BITMAP_DAT;
ST_READ_BLT_BITMAP_DAT:
	begin
		bltcolor <= ram_data_o;
		tgtindex <= blt_vctrx * bitmapWidth;
		state <= ram_data_o[`A] ? ST_READ_BLT_PIX : ST_WRITE_BLT_PIX;
	end
ST_READ_BLT_PIX:
	begin
		ram_addr <= tgtaddr + tgtindex + blt_hctrx;
		state <= ST_READ_BLT_PIX2;
	end
	// Two ram read wait states
ST_READ_BLT_PIX2:
	state <= ST_READ_BLT_PIX3;
ST_READ_BLT_PIX3:
	state <= ST_WRITE_BLT_PIX;
ST_WRITE_BLT_PIX:
	begin
		ram_we <= `HIGH;
		ram_addr <= tgtaddr + tgtindex + blt_hctrx;
		if (bltcolor[`A]) begin
			ram_data_i[`R] <= ram_data_o[`R] >> bltcolor[2:0];
			ram_data_i[`G] <= ram_data_o[`G] >> bltcolor[5:3];
			ram_data_i[`B] <= ram_data_o[`B] >> bltcolor[8:6];
		end
		else
			ram_data_i <= bltcolor;
		state <= ST_BLT_NEXT;
	end
ST_BLT_NEXT:
	begin
		// Default to reading next
		state <= ST_READ_BLT_BITMAP;
		ram_we <= `LOW;
		blt_pcx <= blt_pcx + 10'd1;
		blt_hctrx <= blt_hctrx + 10'd1;
		if (blt_hctrx==blt_hmax[bltno]) begin
			blt_hctrx <= 10'd0;
			blt_vctrx <= blt_vctrx + 10'd1;
		end
		// If max count reached no longer dirty
		// reset counters and return to IDLE state
		if (blt_pcx==blt_pix[bltno]) begin
			blt_dirty[bltno] <= `FALSE;
			blt_hctr[bltno] <= 10'd0;
			blt_vctr[bltno] <= 10'd0;
			blt_pc[bltno] <= 10'd0;
			state <= ST_IDLE;
		end
		// Limit the number of consecutive DMA cycles without
		// going back to the IDLE state.
		// Copy the intermediate state back to the registers
		// so that the DMA may continue next time.
		loopcnt <= loopcnt + 4'd1;
		if (loopcnt==4'd7) begin
			blt_pc[bltno] <= blt_pcx;
			blt_hctr[bltno] <= blt_hctrx;
			blt_vctr[bltno] <= blt_vctrx;
			state <= ST_IDLE;
		end
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Line draw states
// Line drawing may also be done by the blitter.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

DL_INIT:
	begin
		bkcolor <= cmdq_out[`BKCOLOR];
		x0 <= cmdq_out[`X0POS];
		y0 <= cmdq_out[`Y0POS];
		x1 <= cmdq_out[`X1POS];
		y1 <= cmdq_out[`Y1POS];
		state <= DL_PRECALC;
	end

// State to setup invariants for DRAWLINE
DL_PRECALC:
	begin
		loopcnt <= 5'd17;
		if (!ctrl[14]) begin
			ctrl[14] <= 1'b1;
			gcx <= x0;
			gcy <= y0;
			dx <= absx1mx0;
			dy <= absy1my0;
			if (x0 < x1) sx <= 14'h0001; else sx <= 14'h3FFF;
			if (y0 < y1) sy <= 14'h0001; else sy <= 14'h3FFF;
			err <= absx1mx0-absy1my0;
		end
		else if (((ctrl[11:8] != 4'h1) &&
			(ctrl[11:8] != 4'h0) &&
			(ctrl[11:8] != 4'hF)) || zbuf)
			state <= DL_GETPIXEL;
		else
			state <= DL_SETPIXEL;
	end
DL_GETPIXEL:
	begin
		ram_addr <= zbuf ? ma[19:3] : ma;
		state <= DL_SETPIXEL;
	end
DL_SETPIXEL:
	begin
		ram_addr <= zbuf ? ma[19:3] : ma;
		if (zbuf) begin
			zbram_we <= 2'b11;
			ram_data_i <= zbram_data_o & ~{2'b11 << {ma[2:0],1'b0}} | zlayer << {ma[2:0],1'b0};
		end
		else begin
			ram_we <= 2'b11;
			case(ctrl[11:8])
			4'd0:	ram_data_i <= 16'h0000;
			4'd1:	ram_data_i <= bkcolor;
			4'd4:	ram_data_i <= bkcolor & ram_data_o;
			4'd5:	ram_data_i <= bkcolor | ram_data_o;
			4'd6:	ram_data_i <= bkcolor ^ ram_data_o;
			4'd7:	ram_data_i <= bkcolor & ~ram_data_o;
			4'hF:	ram_data_i <= 16'h7FFF;
			endcase
		end
		loopcnt <= loopcnt - 5'd1;
		if (gcx==x1 && gcy==y1) begin
			state <= ST_IDLE;
			ctrl[14] <= 1'b0;
//			bltCtrl[13] <= 1'b1;
		end
		else
			state <= DL_TEST;
	end
DL_TEST:
	begin
		ram_we <= {2{`LOW}};
		zbram_we <= {2{`LOW}};
		err <= err - ((e2 > -dy) ? dy : 14'd0) + ((e2 < dx) ? dx : 14'd0);
		if (e2 > -dy)
			gcx <= gcx + sx;
		if (e2 <  dx)
			gcy <= gcy + sy;
		if (loopcnt==5'd0)
			state <= ST_IDLE;
		else if ((ctrl[11:8] != 4'h1) &&
			(ctrl[11:8] != 4'h0) &&
			(ctrl[11:8] != 4'hF))
			state <= DL_GETPIXEL;
		else
			state <= DL_SETPIXEL;
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Draw a filled rectangle, uses the blitter.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_FILLRECT:
	begin
		bkcolor <= cmdq_out[`BKCOLOR];
		x0 <= cmdq_out[`X0POS];
		y0 <= cmdq_out[`Y0POS];
		x1 <= cmdq_out[`X1POS];
		y1 <= cmdq_out[`Y1POS];
		state <= ST_FILLRECT1;
	end
ST_FILLRECT1:
	begin
		if (y1 < y0) y0 <= y1;
		if (x1 < x0) x0 <= x1;
		dx <= absx1mx0 + 12'd1;
		dy <= absy1my0 + 12'd1;
		if (bltCtrl[13])
			state <= ST_FILLRECT2;
	end
ST_FILLRECT2:
	begin
		dstD_badr <= {8'h00,y0} * bitmapWidth + bmpBase + x0[11:0];
		dstD_mod <= bitmapWidth - dx;
		dstD_cnt <= dx * dy;
		bltDstWid <= dx;
		bltD_dat <= bkcolor;
		bltCtrl <= 16'h8080;
		ctrl[14] <= 1'b0;
		state <= ST_IDLE;
	end

ST_TILERECT:
	begin
		bkcolor <= cmdq_out[`BKCOLOR];
		x0 <= cmdq_out[`X0POS];
		y0 <= cmdq_out[`Y0POS];
		x1 <= cmdq_out[`X1POS];
		y1 <= cmdq_out[`Y1POS];
		state <= ST_TILERECT1;
	end
ST_TILERECT1:
	begin
		if (y1 < y0) y0 <= y1;
		if (x1 < x0) x0 <= x1;
		dx <= absx1mx0 + 12'd1;
		dy <= absy1my0 + 12'd1;
		if (bltCtrl[13])
			state <= ST_TILERECT2;
	end
ST_TILERECT2:
	begin
		srcA_badr <= TextureDesco[19:0];
		srcA_mod <= TextureDesco[75:64];
		srcA_cnt <= TextureDesco[47:32];
		bltSrcWid <= TextureDesco[63:48];
		dstD_badr <= {8'h00,y0} * bitmapWidth + bmpBase + x0[11:0];
		dstD_mod <= bitmapWidth - dx;
		dstD_cnt <= dx * dy;
		bltDstWid <= dx;
		bltD_dat <= bkcolor;
		bltCtrl <= 16'h8082;
		ctrl[14] <= 1'b0;
		state <= ST_IDLE;
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Copper
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_COPPER_IFETCH:
	begin
		ram_addr <= copper_pc;
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

`ifdef ORGFX
gfx_top ugfx1
(
	.wb_clk_i(clk_i),
	.wb_rst_i(rst_i),
	.wb_inta_o(),
	  // Wishbone master signals (interfaces with video memory, write)
  	.wbm_cyc_o(gfx_cyc),
  	.wbm_stb_o(gfx_stb),
  	.wbm_cti_o(),
  	.wbm_bte_o(),
  	.wbm_we_o(gfx_we),
  	.wbm_adr_o(gfx_adr),
  	.wbm_sel_o(gfx_sel),
  	.wbm_ack_i(gfx_ack_i),
  	.wbm_err_i(),
  	.wbm_dat_i(gfx_dat_i),
  	.wbm_dat_o(gfx_dat_o),
	 // Wishbone slave signals (interfaces with main bus/CPU)
  	.wbs_cyc_i(gfxs_ctrl[0]),
  	.wbs_stb_i(gfxs_ctrl[1]),
  	.wbs_cti_i(),
  	.wbs_bte_i(),
  	.wbs_we_i(gfxs_ctrl[2]),
  	.wbs_adr_i(gfxs_adr_i),
  	.wbs_sel_i(gfxs_ctrl[7:4]),
  	.wbs_ack_o(gfxs_ack_o),
  	.wbs_err_o(),
  	.wbs_dat_i(gfxs_dat_i),
  	.wbs_dat_o(gfxs_dat_o)
);
`endif

endmodule
