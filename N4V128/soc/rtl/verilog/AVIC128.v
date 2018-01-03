// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// AVIC128.v
// - audio/video interface circuit
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

`define CMDQ_WID	64
`define CMDQ_DEP	64
`define CMDDAT	31:0
`define CMDCMD	47:32

module AVIC128 (
	rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o,
	m_clk_i, m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o,
	vclk, hSync, vSync, de, rgb,
	aud0_out, aud1_out, aud2_out, aud3_out, aud_in,
	state
);
// WISHBONE slave port
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output reg ack_o;
input we_i;
input [3:0] sel_i;
input [11:0] adr_i;
input [31:0] dat_i;
output reg [31:0] dat_o;
// WISHBONE master port
input m_clk_i;
output reg m_cyc_o;
output m_stb_o;
input m_ack_i;
output reg m_we_o;
output reg [15:0] m_sel_o;
output reg [31:0] m_adr_o;
input [127:0] m_dat_i;
output reg [127:0] m_dat_o;
// Video Port
input vclk;
output hSync;
output vSync;
output reg de;
output reg [23:0] rgb;
// Audio ports
output reg [15:0] aud0_out;
output reg [15:0] aud1_out;
output reg [15:0] aud2_out;
output reg [15:0] aud3_out;
input [15:0] aud_in;
// Debugging
output reg [7:0] state;

parameter NSPR = 32;			// number of supported sprites
parameter pAckStyle = 1'b0;
parameter BUSTO = 8'd50;		// bus timeout in m_clk_i clock cycles

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

parameter LINE_RESET = 6'd0;
parameter DELAY = 6'd1;
parameter READ_ACC = 6'd2;
parameter READ_NACK = 6'd3;
parameter SPRITE_ACC = 6'd4;
parameter SPRITE_NACK = 6'd5;
parameter WAIT_RESET = 6'd6;
parameter ST_AUD0 = 6'd8;
parameter ST_AUD1 = 6'd9;
parameter ST_AUD2 = 6'd10;
parameter ST_AUD3 = 6'd11;
parameter ST_AUDI = 6'd12;
parameter OTHERS = 6'd13;
parameter ST_READ_FONT_TBL = 6'd15;
parameter ST_READ_FONT_TBL_NACK = 6'd16;
parameter ST_READ_GLYPH_ENTRY = 6'd17;
parameter ST_READ_GLYPH_ENTRY_NACK = 6'd18;
parameter ST_READ_CHAR_BITMAP = 6'd19;
parameter ST_READ_CHAR_BITMAP_NACK = 6'd20;
parameter ST_WRITE_CHAR = 6'd21;
parameter ST_WRITE_CHAR2 = 6'd22;
parameter ST_WRITE_CHAR2_NACK = 6'd23;
parameter ST_CMD = 6'd24;
parameter ST_PLOT = 6'd27;
parameter ST_PLOT_READ = 6'd28;
parameter ST_PLOT_WRITE = 8'd29;
parameter ST_LATCH_DATA = 8'd30;
parameter DELAY1 = 8'd31;
parameter DELAY2 = 8'd32;
parameter DELAY3 = 8'd33;
parameter DELAY4 = 8'd34;
parameter DL_PRECALC = 8'd35;
parameter DL_GETPIXEL = 8'd36;
parameter DL_SETPIXEL = 8'd37;
parameter DL_TEST = 8'd38;
parameter DL_RET = 8'd39;
parameter ST_BLTDMA2 = 8'd42;
parameter ST_BLTDMA2_NACK = 8'd43;
parameter ST_BLTDMA4 = 8'd44;
parameter ST_BLTDMA4_NACK = 8'd45;
parameter ST_BLTDMA6 = 8'd46;
parameter ST_BLTDMA6_NACK = 8'd47;
parameter ST_BLTDMA8 = 8'd48;
parameter ST_BLTDMA8_NACK = 8'd51;
parameter ST_FILLRECT = 8'd60;
parameter ST_FILLRECT_CLIP = 8'd61;
parameter ST_FILLRECT2 = 8'd62;
parameter ST_IDLE = 8'd63;

parameter HT_NONE = 3'd0;
parameter HT_LINE_FETCH = 3'd1;
parameter HT_SPRITE_FETCH = 3'd2;
parameter HT_OTHERS = 3'd3;

assign m_stb_o = m_cyc_o;

reg [31:0] TargetBase = 32'h100000;
reg [15:0] TargetWidth = 16'd600;
reg [15:0] TargetHeight = 16'd800;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg clipEnable;
reg [15:0] clipX0, clipY0, clipX1, clipY1;


integer n;

function [15:0] fixToInt;
input [31:0] nn;
	fixToInt = nn[31:16];
endfunction

// Integer part of a fixed point number
function [31:0] ipart;
input [31:0] nn;
    ipart = {nn[31:16],16'h0000};
endfunction

// Fractional part of a fixed point number
function [31:0] fpart;
input [31:0] nn;
    fpart = {16'h0,nn[15:0]};
endfunction

function [31:0] rfpart;
input [31:0] nn;
    rfpart = (32'h10000 - fpart(nn));
endfunction

// Round fixed point number (+0.5)
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
reg [20:0] blendR;
reg [20:0] blendG;
reg [20:0] blendB;
begin
	blendR = blend1(color1[`R],alpha) + blend1(color2[`R],(16'hFFFF-alpha));
	blendG = blend1(color1[`G],alpha) + blend1(color2[`G],(16'hFFFF-alpha));
	blendB = blend1(color1[`B],alpha) + blend1(color2[`B],(16'hFFFF-alpha));
	blend = {blendR[20:16],blendG[20:16],blendB[20:16]};
end
endfunction

function [127:0] fnClearPixel;
input [127:0] data;
input [31:0] addr;
begin
	fnClearPixel = data & ~(128'h0FFFF << {addr[3:1],4'h0});
end
endfunction

function [127:0] fnFlipPixel;
input [127:0] data;
input [31:0] addr;
begin
	fnFlipPixel = data ^ (128'h0FFFF << {addr[3:1],4'h0});
end
endfunction

function [127:0] fnShiftPixel;
input [15:0] color;
input [31:0] addr;
begin
	fnShiftPixel = ({112'h0,color} << {addr[3:1],4'h0});
end
endfunction

function fnClip;
input [15:0] x;
input [15:0] y;
begin
	fnClip = (x >= TargetWidth || y >= TargetHeight)
			 || (clipEnable && (x < clipX0 || x >= clipX1 || y < clipY0 || y >= clipY1))
			;
end
endfunction

wire eol;
wire eof;
wire border;
wire blank, vblank;
wire vbl_int;
reg [9:0] vbl_reg;

reg [11:0] hTotal = phTotal;
reg [11:0] vTotal = pvTotal;
reg [11:0] hSyncOn = phSyncOn, hSyncOff = phSyncOff;
reg [11:0] vSyncOn = pvSyncOn, vSyncOff = pvSyncOff;
reg [11:0] hBlankOn = phBlankOn, hBlankOff = phBlankOff;
reg [11:0] vBlankOn = pvBlankOn, vBlankOff = pvBlankOff;
reg [11:0] hBorderOn = phBorderOn, hBorderOff = phBorderOff;
reg [11:0] vBorderOn = pvBorderOn, vBorderOff = pvBorderOff;
wire [11:0] hctr, vctr;
reg [11:0] m_hctr, m_vctr;
reg [11:0] hstart = 12'hEFF;
reg [11:0] vstart = 12'hFE6;
reg [5:0] flashcnt;
reg [127:0] latched_data;
reg [31:0] irq_status;

reg [3:0] htask;
reg [31:0] ctrl;
reg [1:0] lowres = 2'b00;
reg [23:0] borderColor = 24'h000000;
reg rst_fifo;
reg rd_fifo;
wire [15:0] rgb_i;
reg lrst;						// line reset

function IsBinaryROP;
input [3:0] rop;
IsBinaryROP =  (((rop != 4'h1) &&
			(rop != 4'h0) &&
			(rop != 4'hF)));
endfunction

// The bus timeout depends on the clock frequency (m_clk_i) of the core
// relative to the memory controller's clock frequency (100MHz). So it's
// been made a core parameter.
reg [7:0] busto = BUSTO;
reg [7:0] tocnt;
reg [7:0] num_strips = 8'd100;

// Graphics cursor position
reg [15:0] gcx;
reg [15:0] gcy;

// Untransformed points
reg [31:0] up0x, up0y, up0z;
reg [31:0] up1x, up1y, up1z;
reg [31:0] up2x, up2y, up2z;
reg [31:0] up0xs, up0ys, up0zs;
reg [31:0] up1xs, up1ys, up1zs;
reg [31:0] up2xs, up2ys, up2zs;
// Points after transform
reg [31:0] p0x, p0y, p0z;
reg [31:0] p1x, p1y, p1z;
reg [31:0] p2x, p2y, p2z;

wire signed [31:0] absx1mx0 = (p1x < p0x) ? p0x-p1x : p1x-p0x;
wire signed [31:0] absy1my0 = (p1y < p0y) ? p0y-p1y : p1y-p0y;

// Cursor related registers
reg [31:0] collision;
reg [4:0] spriteno;
reg sprite;
reg [31:0] spriteEnable;
reg [31:0] spriteActive;
reg [11:0] sprite_pv [0:31];
reg [11:0] sprite_ph [0:31];
reg [3:0] sprite_pz [0:31];
reg [31:0] sprite_color [0:255];
reg [31:0] sprite_on;
reg [31:0] sprite_on_d1;
reg [31:0] sprite_on_d2;
reg [31:0] sprite_on_d3;
reg [31:0] spriteAddr [0:31];
reg [31:0] spriteWaddr [0:31];
reg [15:0] spriteMcnt [0:31];
reg [15:0] spriteWcnt [0:31];
reg [127:0] m_spriteBmp [0:31];
reg [127:0] spriteBmp [0:31];
reg [15:0] spriteColor [0:31];
reg [31:0] spriteLink1;
reg [7:0] spriteColorNdx [0:31];

reg sgLock;

reg [11:0] vpos;
reg [27:0] vndx;
// read access counter, controls number of consecutive reads
reg [7:0] rac;
reg [7:0] rac_limit = 8'd100;
reg [7:0] ngs;		// next graphic state
reg [7:0] state1,state2,state3,state4,state5,state6;
reg [7:0] strip_cnt;
reg [5:0] delay_cnt;
wire [31:0] douta;

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
reg [31:0] aud_ctrl;
wire aud_mix1 = aud_ctrl[5];
wire aud_mix3 = aud_ctrl[6];
//
//           3210 3210
// ---- ---- -fff -aaa
//             |    +--- amplitude modulate next channel
//             +-------- frequency modulate next channel
//
reg [31:0] aud0_adr;
reg [31:0] aud0_eadr;
reg [15:0] aud0_length;
reg [19:0] aud0_period;
reg [15:0] aud0_volume;
reg signed [15:0] aud0_dat;
reg signed [15:0] aud0_dat2;		// double buffering
reg [31:0] aud1_adr;
reg [31:0] aud1_eadr;
reg [15:0] aud1_length;
reg [19:0] aud1_period;
reg [15:0] aud1_volume;
reg signed [15:0] aud1_dat;
reg signed [15:0] aud1_dat2;
reg [31:0] aud2_adr;
reg [31:0] aud2_eadr;
reg [15:0] aud2_length;
reg [19:0] aud2_period;
reg [15:0] aud2_volume;
reg signed [15:0] aud2_dat;
reg signed [15:0] aud2_dat2;
reg [31:0] aud3_adr;
reg [31:0] aud3_eadr;
reg [15:0] aud3_length;
reg [19:0] aud3_period;
reg [15:0] aud3_volume;
reg signed [15:0] aud3_dat;
reg signed [15:0] aud3_dat2;
reg [31:0] audi_adr;
reg [31:0] audi_eadr;
reg [19:0] audi_length;
reg [19:0] audi_period;
reg [15:0] audi_volume;
reg signed [15:0] audi_dat;
reg rd_aud0;
reg rd_aud1;
reg rd_aud2;
reg rd_aud3;
wire aud0_fifo_empty;
wire aud1_fifo_empty;
wire aud2_fifo_empty;
wire aud3_fifo_empty;

wire [15:0] aud0_fifo_o;
wire [15:0] aud1_fifo_o;
wire [15:0] aud2_fifo_o;
wire [15:0] aud3_fifo_o;

reg [23:0] aud_test;
reg [31:0] aud0_wadr, aud1_wadr, aud2_wadr, aud3_wadr, audi_wadr;
reg [19:0] ch0_cnt, ch1_cnt, ch2_cnt, ch3_cnt, chi_cnt;
// The request counter keeps track of the number of times a request was issued
// without being serviced. There may be the occasional request missed by the
// timing budget. The counter allows the sample to remain on-track and in
// sync with other samples being read.
reg [5:0] aud0_req, aud1_req, aud2_req, aud3_req, audi_req;
// The following request signals pulse for 1 clock cycle only.
reg aud0_req2, aud1_req2, aud2_req2, aud3_req2, audi_req2;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Command queue vars.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [5:0] cmdq_ndx;
reg [63:0] cmdq_in;
wire [63:0] cmdq_out;
wire cmdp;				// command pulse
wire cmdpe;				// command pulse edge

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Text Blitting
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [31:0] font_tbl_adr;
reg [15:0] font_id;
reg [31:0] glyph_tbl_adr;
reg font_fixed;
reg [5:0] font_width;
reg [5:0] font_height;
reg tblit_active;
reg [7:0] tblit_state;
reg [31:0] tblit_adr;
reg [31:0] tgtaddr, tgtadr;
reg [15:0] tgtindex;
reg [15:0] charcode;
reg [31:0] charndx;
reg [31:0] charbmp;
reg [31:0] charbmpr;
reg [31:0] charBmpBase;
reg [5:0] pixhc, pixvc;
reg [31:0] charBoxX0, charBoxY0;

reg [15:0] alpha;
reg [15:0] penColor, fillColor;
reg [15:0] missColor = 16'h3c00;	// med red

reg zbuf;
reg [3:0] zlayer;

reg [11:0] ppl;
reg [31:0] cyPPL;
reg [31:0] offset;
reg [31:0] ma;

// Line draw vars
reg signed [15:0] dx,dy;
reg signed [15:0] sx,sy;
reg signed [15:0] err;
wire signed [15:0] e2 = err << 1;
// Anti-aliased line draw
reg steep;
reg [31:0] openColor;
reg [31:0] xend, yend, gradient, xgap;
reg [31:0] xpxl1, ypxl1, xpxl2, ypxl2;
reg [68:0] pixColorR, pixColorG, pixColorB;
reg [31:0] intery;
reg signed [31:0] dxa,dya;

reg [31:0] rdadr;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// blitter vars
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [7:0] blit_state;
reg [31:0] bltSrcWid, bltSrcWidx;
reg [31:0] bltDstWid, bltDstWidx;
//  ch  321033221100       
//  TBDzddddebebebeb
//  |||   |       |+- bitmap mode
//  |||   |       +-- channel enabled
//  |||   +---------- direction 0=normal,1=decrement
//  ||+-------------- done indicator
//  |+--------------- busy indicator
//  +---------------- trigger bit
reg [15:0] bltCtrl,bltCtrlx;
reg [15:0] bltA_shift, bltB_shift, bltC_shift;
reg [15:0] bltLWMask = 16'hFFFF;
reg [15:0] bltFWMask = 16'hFFFF;

reg [31:0] bltA_badr;               // base address
reg [31:0] bltA_mod;                // modulo
reg [31:0] bltA_cnt;
reg [31:0] bltA_badrx;               // base address
reg [31:0] bltA_modx;                // modulo
reg [31:0] bltA_cntx;
reg [31:0] bltA_wadr;				// working address
reg [31:0] bltA_wcnt;				// working count
reg [31:0] bltA_dcnt;				// working count
reg [31:0] bltA_hcnt;

reg [31:0] bltB_badr;
reg [31:0] bltB_mod;
reg [31:0] bltB_cnt;
reg [31:0] bltB_badrx;
reg [31:0] bltB_modx;
reg [31:0] bltB_cntx;
reg [31:0] bltB_wadr;				// working address
reg [31:0] bltB_wcnt;				// working count
reg [31:0] bltB_dcnt;				// working count
reg [31:0] bltB_hcnt;

reg [31:0] bltC_badr;
reg [31:0] bltC_mod;
reg [31:0] bltC_cnt;
reg [31:0] bltC_badrx;
reg [31:0] bltC_modx;
reg [31:0] bltC_cntx;
reg [31:0] bltC_wadr;				// working address
reg [31:0] bltC_wcnt;				// working count
reg [31:0] bltC_dcnt;				// working count
reg [31:0] bltC_hcnt;

reg [31:0] bltD_badr;
reg [31:0] bltD_mod;
reg [31:0] bltD_cnt;
reg [31:0] bltD_badrx;
reg [31:0] bltD_modx;
reg [31:0] bltD_cntx;
reg [31:0] bltD_wadr;				// working address
reg [31:0] bltD_wcnt;				// working count
reg [31:0] bltD_hcnt;

reg [15:0] blt_op;
reg [15:0] blt_opx;
reg [6:0] bitcnt;
reg [3:0] bitinc;
reg [1:0] blt_nch;

// May need to set the pipeline depth to zero if copying neighbouring pixels
// during a blit. So the app is allowed to control the pipeline depth. Depth
// should not be set >28.
reg [4:0] bltPipedepth = 5'd15;
reg [4:0] bltPipedepthx;
reg [31:0] bltinc;
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
reg  [15:0] bltA_datx, bltB_datx, bltC_datx, bltD_datx;
// Convert an input bit into a color (black or white) to allow use as a mask.
wire [15:0] bltA_in = bltCtrlx[0] ? (blt_bmpA[bitcnt] ? 16'h7FFF : 16'h0000) : blt_bmpA;
wire [15:0] bltB_in = bltCtrlx[2] ? (blt_bmpB[bitcnt] ? 16'h7FFF : 16'h0000) : blt_bmpB;
wire [15:0] bltC_in = bltCtrlx[4] ? (blt_bmpC[bitcnt] ? 16'h7FFF : 16'h0000) : blt_bmpC;
assign bltA_out = bltA_datx;
assign bltB_out = bltB_datx;
assign bltC_out = bltC_datx;

reg [15:0] bltab;
reg [15:0] bltabc;

// Perform alpha blending between the two colors.
wire [12:0] blndR = (bltB_out[`R] * bltA_out[7:0]) + (bltC_out[`R])*(8'hFF-bltA_out[7:0]);
wire [12:0] blndG = (bltB_out[`G] * bltA_out[7:0]) + (bltC_out[`G])*(8'hFF-bltA_out[7:0]);
wire [12:0] blndB = (bltB_out[`B] * bltA_out[7:0]) + (bltC_out[`B])*(8'hFF-bltA_out[7:0]);

always @*
	case(blt_opx[3:0])
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
	case(blt_opx[7:4])
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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Component declarations
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

VGASyncGen u1
(
	.rst(rst_i),
	.clk(vclk),
	.eol(eol),
	.eof(eof),
	.hSync(hSync),
	.vSync(vSync),
	.hCtr(hctr),
	.vCtr(vctr),
    .blank(blank),
    .vblank(vblank),
    .vbl_int(),
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

wire peack, neack;
edge_det u3 (.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(m_ack_i), .pe(peack), .ne(neack), .ee());
/*
AVIC_VideoFifo uavf1
(
	.wrst(rst_fifo),
	.wclk(m_clk_i),
	.wr((peack||tocnt==8'd1) && (state==READ_ACK)),
	.di((tocnt==8'd1) ? {8{missColor}} : m_dat_i),
	.rrst(rst_fifo),
	.rclk(vclk),
	.rd(rd_fifo),
	.dout(rgb_i),
	.cnt()
);
*/
AVIC128_VideoFifo u2
(
	.rst(rst_fifo),
	.wr_clk(m_clk_i),
	.rd_clk(vclk),
	.din((tocnt==8'd1) ? {8{missColor}} : latched_data),
	.wr_en(neack && (state==READ_NACK)),
	.rd_en(rd_fifo),
	.dout(rgb_i),
	.full(),
	.empty(),
	.wr_rst_busy(),
	.rd_rst_busy()
);

VIC128_AudioFifo u5
(
  .rst(rst_i),
  .wr_clk(m_clk_i),
  .rd_clk(m_clk_i),
  .din(m_dat_i),
  .wr_en((peack||tocnt==8'd1) && (state==ST_AUD0)),
  .rd_en(aud_ctrl[0] & rd_aud0),
  .dout(aud0_fifo_o),
  .full(),
  .empty(aud0_fifo_empty),
  .wr_rst_busy(),
  .rd_rst_busy()
);

VIC128_AudioFifo u6
(
  .rst(rst_i),
  .wr_clk(m_clk_i),
  .rd_clk(m_clk_i),
  .din(m_dat_i),
  .wr_en((peack||tocnt==8'd1) && (state==ST_AUD1)),
  .rd_en(aud_ctrl[1] & rd_aud1),
  .dout(aud1_fifo_o),
  .full(),
  .empty(aud1_fifo_empty),
  .wr_rst_busy(),
  .rd_rst_busy()
);

VIC128_AudioFifo u7
(
  .rst(rst_i),
  .wr_clk(m_clk_i),
  .rd_clk(m_clk_i),
  .din(m_dat_i),
  .wr_en((peack||tocnt==8'd1) && (state==ST_AUD2)),
  .rd_en(aud_ctrl[2] & rd_aud2),
  .dout(aud2_fifo_o),
  .full(),
  .empty(aud2_fifo_empty),
  .wr_rst_busy(),
  .rd_rst_busy()
);

VIC128_AudioFifo u8
(
  .rst(rst_i),
  .wr_clk(m_clk_i),
  .rd_clk(m_clk_i),
  .din(m_dat_i),
  .wr_en((peack||tocnt==8'd1) && (state==ST_AUD3)),
  .rd_en(aud_ctrl[3] & rd_aud3),
  .dout(aud3_fifo_o),
  .full(),
  .empty(aud3_fifo_empty),
  .wr_rst_busy(),
  .rd_rst_busy()
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Command queue
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire cs = cs_i & cyc_i & stb_i;
wire cs_cmdq = cs && adr_i[11:2]==10'b0110_1110_10 && cmdp && we_i;

vtdl #(.WID(`CMDQ_WID), .DEP(`CMDQ_DEP)) cmdq (.clk(clk_i), .ce(cs_cmdq), .a(cmdq_ndx), .d(cmdq_in), .q(cmdq_out));
// Here m_clk_i needs to be faster than clk_i.
edge_det ued1 (.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(cs_cmdq), .pe(cmdpe), .ne(), .ee());

// Command queue index signal
always @(posedge m_clk_i)
if (rst_i)
	cmdq_ndx <= 6'd0;
else begin
	if (cmdpe) begin
		if (cmdq_ndx < 6'd63)
			cmdq_ndx <= cmdq_ndx + 6'd1;
	end
	// A lot of other events to process before handling the command queue.
	// First check for audio DMA requests then check for outstanding
	// active graphics requests. Finally process the next command from
	// the queue.
	if (state==OTHERS) begin
		if (aud0_fifo_empty & aud_ctrl[0])
			;
		else if (aud1_fifo_empty & aud_ctrl[1])
			;
		else if (aud2_fifo_empty & aud_ctrl[2])
			;
		else if (aud3_fifo_empty & aud_ctrl[3])
			;
		else if (|audi_req)
			;
		else if (tblit_active)
 			;
 		else if (ctrl[14])
			;
		// Freeze command queue index if incrementing and descrmenting during
		// the same cycle.
		else if (|cmdq_ndx & cmdpe)
			cmdq_ndx <= cmdq_ndx;
		else if (|cmdq_ndx)
			cmdq_ndx <= cmdq_ndx - 6'd1;
	end
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// WISHBONE slave port - register interface.
// clk_i domain
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg rdy1, rdy2, rdy3, rdy4;

VIC128_ShadowRam u4
(
	.clka(clk_i),
	.ena(cs),
	.wea({4{cs & we_i & (rdy2|rdy3) & ~rdy4}} & sel_i),
	.addra(adr_i[11:2]),
	.dina(dat_i),
	.douta(douta)
);


reg [31:0] dat_ix;
wire peBltCtrl;
wire peBltAdatx;
wire peBltBdatx;
wire peBltCdatx;
wire peBltDdatx;
wire peBltDbadrx,peBltDmodx,peBltDcntx;
wire peBltDstWidx;
wire cs_bltCtrl = (cs & we_i & (rdy2|rdy3) & ~rdy4) && adr_i[11:2]==10'b0110_1100_11 && |sel_i[1:0];
wire cs_bltAdatx = (cs & we_i & (rdy2|rdy3) & ~rdy4) && adr_i[11:2]==10'b0110_1000_11 && |sel_i[1:0];
wire cs_bltBdatx = (cs & we_i & (rdy2|rdy3) & ~rdy4) && adr_i[11:2]==10'b0110_1001_11 && |sel_i[1:0];
wire cs_bltCdatx = (cs & we_i & (rdy2|rdy3) & ~rdy4) && adr_i[11:2]==10'b0110_1010_11 && |sel_i[1:0];
wire cs_bltDdatx = (cs & we_i & (rdy2|rdy3) & ~rdy4) && adr_i[11:2]==10'b0110_1011_11 && |sel_i[1:0];
wire cs_bltDbadrx = (cs & we_i & (rdy2|rdy3) & ~rdy4) && adr_i[11:2]==10'b0110_1011_00 && |sel_i[1:0];
wire cs_bltDbmodx = (cs & we_i & (rdy2|rdy3) & ~rdy4) && adr_i[11:2]==10'b0110_1011_01 && |sel_i[1:0];
wire cs_bltDbcntx = (cs & we_i & (rdy2|rdy3) & ~rdy4) && adr_i[11:2]==10'b0110_1011_10 && |sel_i[1:0];
wire cs_bltDstWidx = (cs & we_i & (rdy2|rdy3) & ~rdy4) && adr_i[11:2]==10'b0110_1100_01 && |sel_i[1:0];
edge_det ed2(.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(cs_bltCtrl), .pe(peBltCtrl), .ne(), .ee());
edge_det ed3(.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(cs_bltAdatx), .pe(peBltAdatx), .ne(), .ee());
edge_det ed4(.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(cs_bltBdatx), .pe(peBltBdatx), .ne(), .ee());
edge_det ed5(.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(cs_bltCdatx), .pe(peBltCdatx), .ne(), .ee());
edge_det ed6(.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(cs_bltDdatx), .pe(peBltDdatx), .ne(), .ee());
edge_det ed7(.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(cs_bltDbadrx), .pe(peBltDbadrx), .ne(), .ee());
edge_det ed8(.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(cs_bltDmodx), .pe(peBltDmodx), .ne(), .ee());
edge_det ed9(.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(cs_bltDcntx), .pe(peBltDcntx), .ne(), .ee());
edge_det ed10(.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(cs_bltDstWidx), .pe(peBltDstWidx), .ne(), .ee());

always @(posedge m_clk_i)
	dat_ix <= dat_i;

always @(posedge clk_i)
begin
	if (cs & we_i & (rdy2|rdy3) & ~rdy4)
		casez(adr_i[11:2])
		10'b00????????:	sprite_color[adr_i[9:2]] <= dat_i;
		10'b010?????00:	spriteAddr[adr_i[8:4]] <= dat_i;
		10'b010?????01:	begin
						if (|sel_i[1:0]) spriteMcnt[adr_i[8:4]] <= dat_i[15:0];
						if (sel_i[3]) sprite_pz[adr_i[8:4]] <= dat_i[31:24];
						end
		10'b010?????10:	begin
							if (|sel_i[1:0]) sprite_ph[adr_i[8:4]] <= dat_i[11:0];
							if (|sel_i[3:2]) sprite_pv[adr_i[8:4]] <= dat_i[27:16];
						end
						
		// Audio $600 to $65E
        10'b0110_0000_00:   aud0_adr <= dat_i;
        10'b0110_0000_01:   aud0_length <= dat_i[15:0];
        10'b0110_0000_10:   aud0_period <= dat_i[19:0];
        10'b0110_0000_11:   begin
                            if (|sel_i[1:0]) aud0_volume <= dat_i[15:0];
                            if (|sel_i[3:2]) aud0_dat <= dat_i[31:16];
                            end
        10'b0110_0001_00:   aud1_adr <= dat_i;
        10'b0110_0001_01:   aud1_length <= dat_i[15:0];
        10'b0110_0001_10:   aud1_period <= dat_i[19:0];
        10'b0110_0001_11:   begin
                            if (|sel_i[1:0]) aud1_volume <= dat_i[15:0];
                            if (|sel_i[3:2]) aud1_dat <= dat_i[31:16];
                            end
        10'b0110_0010_00:   aud2_adr <= dat_i;
        10'b0110_0010_01:   aud2_length <= dat_i[15:0];
        10'b0110_0010_10:   aud2_period <= dat_i[19:0];
        10'b0110_0010_11:   begin
                            if (|sel_i[1:0]) aud2_volume <= dat_i[15:0];
                            if (|sel_i[3:2]) aud2_dat <= dat_i[31:16];
                            end
        10'b0110_0011_00:   aud3_adr <= dat_i;
        10'b0110_0011_01:   aud3_length <= dat_i[15:0];
        10'b0110_0011_10:   aud3_period <= dat_i[19:0];
        10'b0110_0011_11:   begin
                            if (|sel_i[1:0]) aud3_volume <= dat_i[15:0];
                            if (|sel_i[3:2]) aud3_dat <= dat_i[31:16];
                            end
        10'b0110_0100_00:   audi_adr <= dat_i;
        10'b0110_0100_01:   audi_length <= dat_i[15:0];
        10'b0110_0100_10:   audi_period <= dat_i[19:0];
        10'b0110_0100_11:   begin
                            if (|sel_i[1:0]) audi_volume <= dat_i[15:0];
                            //if (|sel_i[3:2]) audi_dat <= dat_i[31:16];
                            end

        10'b0110_0101_00:    aud_ctrl <= dat_i;

		// Blitter: $680 to $6CC
		10'b0110_1000_00:	bltA_badr <= dat_i;
		10'b0110_1000_01:	bltA_mod <= dat_i;
		10'b0110_1000_10:	bltA_cnt <= dat_i;
		10'b0110_1001_00:	bltB_badr <= dat_i;
		10'b0110_1001_01:	bltB_mod <= dat_i;
		10'b0110_1001_10:	bltB_cnt <= dat_i;
		10'b0110_1010_00:	bltC_badr <= dat_i;
		10'b0110_1010_01:	bltC_mod <= dat_i;
		10'b0110_1010_10:	bltC_cnt <= dat_i;
		10'b0110_1011_00:	bltD_badr <= dat_i;
		10'b0110_1011_01:	bltD_mod <= dat_i;
		10'b0110_1011_10:	bltD_cnt <= dat_i;
		10'b0110_1011_11:	bltD_dat <= dat_i[15:0];

		10'b0110_1100_00:	bltSrcWid <= dat_i;
		10'b0110_1100_01:	bltDstWid <= dat_i;

		10'b0110_1100_10:	blt_op <= dat_i[15:0];
		10'b0110_1100_11:	begin
							if (sel_i[3]) bltPipedepth <= dat_i[29:24];
							if (|sel_i[1:0]) bltCtrl <= dat_i[15:0];
							end


		10'b0110_1110_00:	cmdq_in <= dat_i;
		10'b0110_1110_01:	cmdq_in[47:32] <= dat_i[15:0];
		10'b0110_1111_00:	font_tbl_adr <= dat_i;
		10'b0110_1111_01:	font_id <= dat_i[15:0];

		10'b0111_1011_00:	spriteEnable <= dat_i;
		10'b0111_1011_01:	spriteLink1 <= dat_i;

		// Sync generator control regs  $7C0 to $7DE      
        10'b0111_1100_00:		if (sgLock) begin
        						if (|sel_i[1:0]) hTotal <= dat_i[11:0];
        						if (|sel_i[3:2]) vTotal <= dat_i[27:16];
        					end
        10'b0111_1100_01:		if (sgLock) begin
        						if (|sel_i[1:0]) hSyncOn <= dat_i[11:0];
        						if (|sel_i[3:2]) hSyncOff <= dat_i[27:16];
        					end
        10'b0111_1100_10:		if (sgLock) begin
        						if (|sel_i[1:0]) vSyncOn <= dat_i[11:0];
        						if (|sel_i[3:2]) vSyncOff <= dat_i[27:16];
        					end
        10'b0111_1100_11:		if (sgLock) begin
        						if (|sel_i[1:0]) hBlankOn <= dat_i[11:0];
        						if (|sel_i[3:2]) hBlankOff <= dat_i[27:16];
        					end
        10'b0111_1101_00:		if (sgLock) begin
        						if (|sel_i[1:0]) vBlankOn <= dat_i[11:0];
        						if (|sel_i[3:2]) vBlankOff <= dat_i[27:16];
        					end
        10'b0111_1101_01:		begin
        					if (|sel_i[1:0]) hBorderOn <= dat_i[11:0];
        					if (|sel_i[3:2]) hBorderOff <= dat_i[27:16];
        					end
        10'b0111_1101_10:		begin
        					if (|sel_i[1:0]) vBorderOn <= dat_i[11:0];
        					if (|sel_i[3:2]) vBorderOff <= dat_i[27:16];
        					end
        10'b0111_1101_11:  	begin
        					if (|sel_i[1:0]) hstart <= dat_i[11:0];
        					if (|sel_i[3:2]) vstart <= dat_i[27:16];
        					end
        10'b0111_1110_00:		TargetBase <= dat_i;
        10'b0111_1110_10:		begin
        						if (|sel_i[3:2]) TargetWidth <= dat_i[31:16];
        						if (|sel_i[1:0]) TargetHeight <= dat_i[15:0];
        						end
        10'b0111_1111_00:   	begin
        						if (sel_i[2]) num_strips = dat_i[23:16];
        						if (sel_i[0]) lowres <= dat_i[1:0];   
        						end
        10'b0111_1111_01:		sgLock <= dat_i==32'hA1234567;
		default:	;	// do nothing
		endcase
    if (aud_test==24'hFFFFFF)
        aud_ctrl[14] <= 1'b0;
end
always @(posedge clk_i)
	case(adr_i[11:2])
	10'b0110_1100_11:	dat_o <= {bltPipedepth,8'h00,bltCtrlx};
	10'b0110_1110_10:	dat_o <= {26'd0,cmdq_ndx};
	10'b0111_1011_10:	dat_o <= collision;
	default:	dat_o <= douta;
	endcase

always @(posedge clk_i)
	rdy1 <= cs;
always @(posedge clk_i)
	rdy2 <= rdy1 & cs;
always @(posedge clk_i)
	rdy3 <= rdy2 & cs;
always @(posedge clk_i)
	rdy4 <= rdy3 & cs;
//assign ack_o = cs ? rdy4 : pAckStyle;
always @*
	ack_o <= rdy4;
edge_det ued20 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(rdy3), .pe(cmdp), .ne(), .ee());

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
always @*
case(font_width[4:3])
2'd0:	for (n = 0; n < 8; n = n + 1)
			charbmpr[n] = charbmp[7-n];
2'd1:	for (n = 0; n < 16; n = n + 1)
			charbmpr[n] = charbmp[15-n];
2'd2,2'd3:	for (n = 0; n < 32; n = n + 1)
			charbmpr[n] = charbmp[31-n];
endcase

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register blitter controls across clock domain.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
always @(posedge m_clk_i)
	bltA_badrx <= bltA_badr;
always @(posedge m_clk_i)
	bltA_modx <= bltA_mod;
always @(posedge m_clk_i)
	bltA_cntx <= bltA_cnt;
always @(posedge m_clk_i)
	bltB_badrx <= bltB_badr;
always @(posedge m_clk_i)
	bltB_modx <= bltB_mod;
always @(posedge m_clk_i)
	bltB_cntx <= bltB_cnt;
always @(posedge m_clk_i)
	bltC_badrx <= bltC_badr;
always @(posedge m_clk_i)
	bltC_modx <= bltC_mod;
always @(posedge m_clk_i)
	bltC_cntx <= bltC_cnt;
always @(posedge m_clk_i)
	bltSrcWidx <= bltSrcWid;
always @(posedge m_clk_i)
	blt_opx <= blt_op;
always @(posedge m_clk_i)
	bltPipedepthx <= bltPipedepth;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Audio
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge m_clk_i)
	if (ch0_cnt>=aud0_period || aud_ctrl[8])
		ch0_cnt <= 20'd1;
	else if (aud_ctrl[0])
		ch0_cnt <= ch0_cnt + 20'd1;
always @(posedge m_clk_i)
	if (ch1_cnt>= aud1_period || aud_ctrl[9])
		ch1_cnt <= 20'd1;
	else if (aud_ctrl[1])
		ch1_cnt <= ch1_cnt + (aud_ctrl[20] ? aud0_out[15:8] + 20'd1 : 20'd1);
always @(posedge m_clk_i)
	if (ch2_cnt>= aud2_period || aud_ctrl[10])
		ch2_cnt <= 20'd1;
	else if (aud_ctrl[2])
		ch2_cnt <= ch2_cnt + (aud_ctrl[21] ? aud1_out[15:8] + 20'd1 : 20'd1);
always @(posedge m_clk_i)
	if (ch3_cnt>= aud3_period || aud_ctrl[11])
		ch3_cnt <= 20'd1;
	else if (aud_ctrl[3])
		ch3_cnt <= ch3_cnt + (aud_ctrl[22] ? aud2_out[15:8] + 20'd1 : 20'd1);
always @(posedge m_clk_i)
	if (chi_cnt>=audi_period || aud_ctrl[12])
		chi_cnt <= 20'd1;
	else if (aud_ctrl[4])
		chi_cnt <= chi_cnt + 20'd1;

always @(posedge m_clk_i)
	aud0_dat2 <= aud0_fifo_o;
always @(posedge m_clk_i)
	aud1_dat2 <= aud1_fifo_o;
always @(posedge m_clk_i)
	aud2_dat2 <= aud2_fifo_o;
always @(posedge m_clk_i)
	aud3_dat2 <= aud3_fifo_o;

always @(posedge m_clk_i)
begin
	rd_aud0 <= `FALSE;
	rd_aud1 <= `FALSE;
	rd_aud2 <= `FALSE;
	rd_aud3 <= `FALSE;
	audi_req2 <= `FALSE;
// IF channel count == 1
// A count value of zero is not possible so there will be no requests unless
// the audio channel is enabled.
	if (ch0_cnt==aud_ctrl[0] && ~aud_ctrl[8])
		rd_aud0 <= `TRUE;
	if (ch1_cnt==aud_ctrl[1] && ~aud_ctrl[9])
		rd_aud1 <= `TRUE;
	if (ch2_cnt==aud_ctrl[2] && ~aud_ctrl[10])
		rd_aud2 <= `TRUE;
	if (ch3_cnt==aud_ctrl[3] && ~aud_ctrl[11])
		rd_aud3 <= `TRUE;
	if (chi_cnt==aud_ctrl[4] && ~aud_ctrl[12]) begin
		audi_req <= audi_req + 6'd2;
		audi_req2 <= `TRUE;
	end
	if (state==ST_AUDI)
	   audi_req <= 6'd0;
end

// Compute end of buffer address
always @(posedge m_clk_i)
begin
	aud0_eadr <= aud0_adr + aud0_length;
	aud1_eadr <= aud1_adr + aud1_length;
	aud2_eadr <= aud2_adr + aud2_length;
	aud3_eadr <= aud3_adr + aud3_length;
	audi_eadr <= audi_adr + audi_length;
end

wire signed [31:0] aud1_tmp;
wire signed [31:0] aud0_tmp = aud_mix1 ? ((aud0_dat2 * aud0_volume + aud1_tmp) >> 1): aud0_dat2 * aud0_volume;
wire signed [31:0] aud3_tmp;
wire signed [31:0] aud2_dat3 = aud_ctrl[17] ? aud2_dat2 * aud2_volume * aud1_dat2 : aud2_dat2 * aud2_volume;
wire signed [31:0] aud2_tmp = aud_mix3 ? ((aud2_dat3 + aud3_tmp) >> 1): aud2_dat3;

assign aud1_tmp = aud_ctrl[16] ? aud1_dat2 * aud1_volume * aud0_dat2 : aud1_dat2 * aud1_volume;
assign aud3_tmp = aud_ctrl[18] ? aud3_dat2 * aud3_volume * aud2_dat2 : aud3_dat2 * aud3_volume;
					

always @(posedge m_clk_i)
begin
	aud0_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[0] ? aud0_tmp >> 16 : 16'h0000;
	aud1_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[1] ? aud1_tmp >> 16 : 16'h0000;
	aud2_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[2] ? aud2_tmp >> 16 : 16'h0000;
	aud3_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[3] ? aud3_tmp >> 16 : 16'h0000;
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// RGB output display side
// clk clock domain
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Register hctr,vctr onto the m_clk_i domain
always @(posedge m_clk_i)
	m_hctr <= hctr;
always @(posedge m_clk_i)
	m_vctr <= vctr;

// widen vertical blank interrupt pulse
always @(posedge vclk)
	if (vbl_int)
		vbl_reg <= 10'h3FF;
	else
		vbl_reg <= {vbl_reg[8:0],1'b0};

always @(posedge vclk)
	if (eol & eof)
		flashcnt <= flashcnt + 6'd1;

// Generate fifo reset signal
always @(posedge m_clk_i)
	if (m_hctr >= 12'd1 && m_hctr < 12'd16)
		rst_fifo <= `TRUE;
	else
		rst_fifo <= `FALSE;

// Generate fifo read signal
always @(posedge vclk)
	if (hctr >= hBlankOff && hctr < hBlankOn && !vblank) begin
		case(lowres)
		2'd0: 	rd_fifo <= `TRUE;
		2'd1:	rd_fifo <= hctr[0];
		2'd2:	rd_fifo <= hctr[1:0]==2'b11;
		2'd3:	rd_fifo <= `TRUE;
		endcase
	end
	else
		rd_fifo <= `FALSE;

always @(posedge m_clk_i)
	cyPPL <= (gcy << lowres) * {TargetWidth,1'b0};
always @(posedge m_clk_i)
	offset <= cyPPL + {(gcx << lowres),1'b0};
always @(posedge m_clk_i)
	ma <= TargetBase + offset;


// Memory access state machine
always @(posedge m_clk_i)
if (rst_i) begin
	goto(WAIT_RESET);
	bltCtrlx[13] <= 1'b1;	// Blitter is "done" to begin with.
	aud_test <= 24'h0;
end
else begin

if (peBltCtrl)
	bltCtrlx <= dat_ix;
if (peBltAdatx)
	bltA_datx <= dat_ix;
if (peBltBdatx)
	bltB_datx <= dat_ix;
if (peBltCdatx)
	bltC_datx <= dat_ix;
if (peBltDdatx)
	bltD_datx <= dat_ix;
if (peBltDbadrx)
	bltD_badrx <= dat_ix;
if (peBltDmodx)
	bltD_modx <= dat_ix;
if (peBltDcntx)
	bltD_cntx <= dat_ix;
if (peBltDstWidx)
	bltDstWidx <= dat_ix;

p0x <= up0x;
p0y <= up0y;
p1x <= up1x;
p1y <= up1y;

// Channel reset
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

// Audio test mode generates about a 600Hz signal for 0.5 secs on all the
// audio channels.
if (aud_ctrl[14])
    aud_test <= aud_test + 24'd1;
if (aud_test==24'hFFFFFF) begin
    aud_test <= 24'h0;
end

if (audi_req2)
	audi_dat <= aud_in;

	// Pipeline the vertical calc.
	vpos <= m_vctr - vstart;
	vndx <= (vpos >> lowres) * {TargetWidth,1'b0};
	charndx <= (charcode << font_width[4:3]) * (font_height + 6'd1);



case(state)
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
DELAY4: goto(DELAY3);
DELAY3:	goto(DELAY2);
DELAY2:	goto(DELAY1);
DELAY1:	return();

OTHERS:
	// Audio takes precedence to avoid audio distortion.
	// Fortunately audio DMA is fast and infrequent.
	if (aud0_fifo_empty & aud_ctrl[0]) begin
	    m_cyc_o <= `HIGH;
	    m_sel_o <= 16'hFFFF;
		m_adr_o <= {aud0_wadr[31:4],4'h0};
		tocnt <= busto;
		aud0_wadr <= aud0_wadr + 32'd16;
		if (aud0_wadr + 32'd16 >= aud0_eadr) begin
			aud0_wadr <= aud0_adr;
			irq_status[8] <= 1'b1;
		end
		if (aud0_wadr < (aud0_eadr >> 1) &&
			(aud0_wadr + 32'd16 >= (aud0_eadr >> 1)))
			irq_status[4] <= 1'b1;
		goto(ST_AUD0);
	end
	else if (aud1_fifo_empty & aud_ctrl[1])	begin
	    m_cyc_o <= `HIGH;
	    m_sel_o <= 16'hFFFF;
		m_adr_o <= {aud1_wadr[31:4],4'h0};
		tocnt <= busto;
		aud1_wadr <= aud1_wadr + 32'd16;
		if (aud1_wadr + 32'd16 >= aud1_eadr) begin
			aud1_wadr <= aud1_adr;
			irq_status[9] <= 1'b1;
		end
		if (aud1_wadr < (aud1_eadr >> 1) &&
			(aud1_wadr + 32'd16 >= (aud1_eadr >> 1)))
			irq_status[5] <= 1'b1;
		goto(ST_AUD1);
	end
	else if (aud2_fifo_empty & aud_ctrl[2]) begin
	    m_cyc_o <= `HIGH;
	    m_sel_o <= 16'hFFFF;
		m_adr_o <= {aud2_wadr[31:4],4'h0};
		tocnt <= busto;
		aud2_wadr <= aud2_wadr + 32'd16;
		if (aud2_wadr + 32'd16 >= aud2_eadr) begin
			aud2_wadr <= aud2_adr;
			irq_status[10] <= 1'b1;
		end
		if (aud2_wadr < (aud2_eadr >> 1) &&
			(aud2_wadr + 32'd16 >= (aud2_eadr >> 1)))
			irq_status[6] <= 1'b1;
		goto(ST_AUD2);
	end
	else if (aud3_fifo_empty & aud_ctrl[3])	begin
	    m_cyc_o <= `HIGH;
	    m_sel_o <= 16'hFFFF;
		m_adr_o <= {aud3_wadr[31:4],4'h0};
		tocnt <= busto;
		aud3_wadr <= aud3_wadr + 32'd16;
		aud3_req <= 6'd0;
		if (aud3_wadr + 32'd16 >= aud3_eadr) begin
			aud3_wadr <= aud3_adr;
			irq_status[11] <= 1'b1;
		end
		if (aud3_wadr < (aud3_eadr >> 1) &&
			(aud3_wadr + 32'd16 >= (aud3_eadr >> 1)))
			irq_status[7] <= 1'b1;
		goto(ST_AUD3);
	end
	else if (|audi_req) begin
	    m_cyc_o <= `HIGH;
	    m_we_o <= `HIGH;
	    m_sel_o <= 16'd3 << {audi_wadr[3:1],1'b0};
		m_adr_o <= {audi_wadr[31:4],4'h0};
		m_dat_o <= {8{audi_dat}};
		tocnt <= busto;
		audi_wadr <= audi_wadr + audi_req;
		if (audi_wadr + audi_req >= audi_eadr) begin
			audi_wadr <= audi_adr + (audi_wadr + audi_req - audi_eadr);
			irq_status[12] <= 1'b1;
		end
		if (audi_wadr < (audi_eadr >> 1) &&
			(audi_wadr + audi_req >= (audi_eadr >> 1)))
			irq_status[3] <= 1'b1;
		goto(ST_AUDI);
	end

	else if (tblit_active)
		goto(tblit_state);
 
	else if (bltCtrlx[14]) begin
		if ((bltCtrlx[7:0] & 8'hAA)!=8'h00)
			case(blt_nch)
			2'd0:	goto(ST_BLTDMA2);
			2'd1:	goto(ST_BLTDMA4);
			2'd2:	goto(ST_BLTDMA6);
			2'd3:	goto(ST_BLTDMA8);
			endcase
		else begin // no channels are enabled
			bltCtrlx[14] <= 1'b0;
			bltCtrlx[13] <= 1'b1;
			return();
		end
	end
	else if (bltCtrlx[15]) begin
		bltCtrlx[15] <= 1'b0;
		bltCtrlx[14] <= 1'b1;
		bltCtrlx[13] <= 1'b0;
		bltA_wadr <= bltA_badrx;
		bltB_wadr <= bltB_badrx;
		bltC_wadr <= bltC_badrx;
		bltD_wadr <= bltD_badrx;
		bltA_wcnt <= 32'd1;
		bltB_wcnt <= 32'd1;
		bltC_wcnt <= 32'd1;
		bltD_wcnt <= 32'd1;
		bltA_dcnt <= 32'd1;
		bltB_dcnt <= 32'd1;
		bltC_dcnt <= 32'd1;
		bltA_hcnt <= 32'd1;
		bltB_hcnt <= 32'd1;
		bltC_hcnt <= 32'd1;
		bltD_hcnt <= 32'd1;
		if (bltCtrlx[1])
			blt_nch <= 2'b00;
		else if (bltCtrlx[3])
			blt_nch <= 2'b01;
		else if (bltCtrlx[5])
			blt_nch <= 2'b10;
		else if (bltCtrlx[7])
			blt_nch <= 2'b11;
		else begin
			bltCtrlx[15] <= 1'b0;
			bltCtrlx[14] <= 1'b0;
			bltCtrlx[13] <= 1'b1;
		end
		return();
	end

// 	else if (ctrl[14])
// 		goto(ngs);

	else if (|cmdq_ndx)
		goto(ST_CMD);
	
	else
		return();

ST_CMD:
	begin
		ctrl[7:0] <= cmdq_out[39:32];
//		ctrl[14] <= 1'b0;
		case(cmdq_out[39:32])
		8'd0:	begin
				tblit_active <= `TRUE;
				charcode <= cmdq_out[15:0];
				tblit_state <= ST_READ_FONT_TBL;	// draw character
				return();
				end
		8'd1:	begin
				ctrl[11:8] <= cmdq_out[7:4];	// raster op
				goto(ST_PLOT);
				end
		8'd2:	begin
				ctrl[11:8] <= cmdq_out[7:4];	// raster op
				goto(DL_PRECALC);				// draw line
				end
		8'd3:	begin
				ctrl[11:8] <= cmdq_out[7:4];	// raster op
				goto(ST_FILLRECT);
				end
/*
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
				call(ST_IDLE,DT_START);
				end
		8'd8:	begin	// Bezier Curve
				ctrl[11:8] <= cmdq_out[7:4];	// raster op
				fillCurve <= cmdq_out[1:0];
				state <= BC0;
				end
		8'd9:	state <= FF1;
		8'd11:	transform <= cmdq_out[0];
*/
		8'd12:	begin penColor <= cmdq_out[`CMDDAT]; return(); end
		8'd13:	begin fillColor <= cmdq_out[`CMDDAT]; return(); end
		8'd14:	begin alpha <= cmdq_out[`CMDDAT]; return(); end
		8'd16:	begin up0x <= cmdq_out[`CMDDAT]; return(); end
		8'd17:	begin up0y <= cmdq_out[`CMDDAT]; return(); end
		8'd18:	begin up0z <= cmdq_out[`CMDDAT]; return(); end
		8'd19:	begin up1x <= cmdq_out[`CMDDAT]; return(); end
		8'd20:	begin up1y <= cmdq_out[`CMDDAT]; return(); end
		8'd21:	begin up1z <= cmdq_out[`CMDDAT]; return(); end
		8'd22:	begin up2x <= cmdq_out[`CMDDAT]; return(); end
		8'd23:	begin up2y <= cmdq_out[`CMDDAT]; return(); end
		8'd24:	begin up2z <= cmdq_out[`CMDDAT]; return(); end
		
		8'd25:	begin clipX0 <= cmdq_out[15:0]; return(); end
		8'd26:	begin clipY0 <= cmdq_out[15:0]; return(); end
		8'd27:	begin clipX1 <= cmdq_out[15:0]; return(); end
		8'd28:	begin clipY1 <= cmdq_out[15:0]; return(); end
		8'd29:	begin clipEnable <= cmdq_out[0]; return(); end
/*
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
*/
		default:	return();
		endcase
	end

LINE_RESET:
	begin
		lrst <= `FALSE;
		strip_cnt <= 8'd0;
		rac <= 8'd0;
		if (rst_fifo)
			goto(LINE_RESET);
		else if (vblank)
			call(OTHERS,LINE_RESET);
		else begin
			m_cyc_o <= `LOW;
			m_sel_o <= 16'h0000;
			m_adr_o <= TargetBase + vndx;
			rdadr <= TargetBase + vndx;
			goto(READ_ACC);
		end
	end
	// Add a couple of extra cycles to the bus timeout since the memory
	// controller is fetching four lines on a cache miss rather than
	// just a single line for other accesses.
READ_ACC:
	begin
		m_cyc_o <= `HIGH;
		m_sel_o <= 16'hFFFF;
		m_adr_o <= rdadr;
		tocnt <= busto + 8'd2;
		call(ST_LATCH_DATA,READ_NACK);
	end
READ_NACK:
	if (~m_ack_i) begin
		strip_cnt <= strip_cnt + 8'd1;
		rac <= rac + 8'd1;
		rdadr <= rdadr + 32'd16;
		// If we read all the strips we needed to, then start reading sprite
		// data.
		goto(READ_ACC);
		if (strip_cnt==num_strips) begin
			spriteno <= 5'd0;
			for (n = 0; n < 32; n = n + 1)
				m_spriteBmp[n] <= 128'd0;
			goto(SPRITE_ACC);
		end
		// Check for too many consecutive memory accesses. Be nice to other
		// bus masters.
//			else if (rac < rac_limit)
//				goto(READ_ACC);
//			else begin
//				rac <= 8'd0;
//				call(OTHERS,READ_ACC);
//			end
	end
SPRITE_ACC:
	if (lrst)
		goto(LINE_RESET);
	// Bypass loading sprite data if it isn't enabled.
	else if (spriteActive[spriteno]) begin
		m_cyc_o <= `HIGH;
		m_sel_o <= 16'hFFFF;
		m_adr_o <= spriteWaddr[spriteno];
		tocnt <= busto;
		call(ST_LATCH_DATA,SPRITE_NACK);
	end
	else begin
		spriteno <= spriteno + 5'd1;
		rac <= rac + 8'd1;
		if (spriteno == 5'd31)
			goto(WAIT_RESET);
		else if (rac <= 8'd2)
			goto (SPRITE_ACC);
		else begin
			rac <= 8'd0;
			call(OTHERS,SPRITE_ACC);
		end
	end
SPRITE_NACK:
	if (~m_ack_i) begin
		if (tocnt==8'd1)
			m_spriteBmp[spriteno] <= {8{missColor}};
		else			
			m_spriteBmp[spriteno] <= latched_data;
		spriteno <= spriteno + 5'd1;
		rac <= rac + 8'd1;
		if (spriteno==5'd31)
			goto(WAIT_RESET);
		else if (rac <= 8'd2)
			goto (SPRITE_ACC);
		else begin
			rac <= 8'd0;
			call(OTHERS,SPRITE_ACC);
		end
	end
WAIT_RESET:
	if (lrst)
		goto(LINE_RESET);
	else
		call(OTHERS,WAIT_RESET);

ST_AUD0,
ST_AUD1,
ST_AUD2,
ST_AUD3,
ST_AUDI:
	begin
		tocnt <= tocnt - 8'd1;
		if (m_ack_i||tocnt==8'd1||!m_cyc_o) begin
			m_cyc_o <= `LOW;
			m_we_o <= `LOW;
			m_sel_o <= 16'h0000;
			return();
		end
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Generic data latching state.
// Implemented as a subroutine.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_LATCH_DATA:
	begin
		tocnt <= tocnt - 8'd1;
		if (m_ack_i||tocnt==8'd1||!m_cyc_o) begin
			latched_data <= m_dat_i;
			m_cyc_o <= `LOW;
			m_we_o <= `LOW;
			m_sel_o <= 16'h0000;
			return();
		end
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
// ---wwwww---wwwww
// ---wwwww---wwwww
// ---wwwww---wwwww
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_READ_FONT_TBL:
	begin
		pixhc <= 5'd0;
		pixvc <= 5'd0;
	    m_cyc_o <= `HIGH;
	    m_sel_o <= 16'hFFFF;
		m_adr_o <= {font_tbl_adr[31:4],4'b0} + {font_id,4'b00};
		tocnt <= busto;
		tblit_adr <= {font_tbl_adr[31:4],4'b0} + {font_id,4'b00};
		call(ST_LATCH_DATA,ST_READ_FONT_TBL_NACK);
	end
ST_READ_FONT_TBL_NACK:
	if (~m_ack_i) begin
		font_fixed <= latched_data[127];
		font_width <= latched_data[125:120];
		font_height <= latched_data[117:112];
		charBmpBase <= latched_data[63:32];
		glyph_tbl_adr <= latched_data[31:0];
		tblit_state <= ST_READ_GLYPH_ENTRY;
		return();
	end
ST_READ_GLYPH_ENTRY:
	begin
		charBoxX0 <= p0x;
		charBoxY0 <= p0y;
		charBmpBase <= charBmpBase + charndx;
		if (font_fixed) begin
			tblit_state <= ST_READ_CHAR_BITMAP;
			return();
		end
		else begin
			m_cyc_o <= `HIGH;
		    m_sel_o <= 16'hFFFF;
			m_adr_o <= {glyph_tbl_adr[31:4],4'h0} + {charcode[8:4],4'h0};
			tocnt <= busto;
			call(ST_LATCH_DATA,ST_READ_GLYPH_ENTRY_NACK);
		end
	end
ST_READ_GLYPH_ENTRY_NACK:
	if (~m_ack_i) begin
		font_width <= latched_data >> {charcode[3:0],3'b0};
		tblit_state <= ST_READ_CHAR_BITMAP;
		return();
	end
ST_READ_CHAR_BITMAP:
	begin
		m_cyc_o <= `HIGH;
	    m_sel_o <= 16'hFFFF;
		m_adr_o <= charBmpBase + (pixvc << font_width[4:3]);
		tocnt <= busto;
		call(ST_LATCH_DATA,ST_READ_CHAR_BITMAP_NACK);
	end
ST_READ_CHAR_BITMAP_NACK:
	if (~m_ack_i) begin
		case(font_width[4:3])
		2'd0:	charbmp <= (latched_data >> {m_adr_o[3:0],3'b0}) & 32'h0ff;
		2'd1:	charbmp <= (latched_data >> {m_adr_o[3:1],4'b0}) & 32'h0ffff;
		2'd2:	charbmp <= latched_data >> {m_adr_o[3:2],5'b0};
		2'd3:	charbmp <= latched_data >> {m_adr_o[3],6'b0};
		endcase
		tgtaddr <= {8'h00,fixToInt(charBoxY0)} * {4'h00,TargetWidth,1'b0} + TargetBase + {fixToInt(charBoxX0),1'b0};
		tgtindex <= {14'h00,pixvc} * {4'h00,TargetWidth,1'b0};
		tblit_state <= ST_WRITE_CHAR;
		return();
	end
ST_WRITE_CHAR:
	begin
		tgtadr <= tgtaddr + tgtindex + {14'h00,pixhc,1'b0};
		goto(ST_WRITE_CHAR2);
	end
ST_WRITE_CHAR2:
	begin
		if (~fillColor[`A]) begin
			if ((clipEnable && (fixToInt(charBoxX0) + pixhc < clipX0) || (fixToInt(charBoxX0) + pixhc >= clipX1) || (fixToInt(charBoxY0) + pixvc < clipY0)))
				;
			else if (fixToInt(charBoxX0) + pixhc >= TargetWidth)
				;
			else begin
				m_cyc_o <= `HIGH;
				m_we_o <= `HIGH;
				m_sel_o <= 16'd3 << {tgtadr[3:1],1'b0};
				m_adr_o <= tgtadr;
				m_dat_o <= {8{charbmp[0] ? penColor[15:0] : fillColor[15:0]}};
				tocnt <= busto;
			end
		end
		else begin
			if (charbmp[0]) begin
				if (zbuf) begin
					if (clipEnable && (fixToInt(charBoxX0) + pixhc < clipX0 || fixToInt(charBoxX0) + pixhc >= clipX1 || fixToInt(charBoxY0) + pixvc < clipY0))
						;
					else if (fixToInt(charBoxX0) + pixhc >= TargetWidth)
						;
					else begin
						m_cyc_o <= `HIGH;
						m_sel_o <= 16'd3 << {tgtadr[3:1],1'b0};
/*
						m_we_o <= `HIGH;
						m_adr_o <= tgtadr;
						m_dat_o <= {32{zlayer}};
*/				
						tocnt <= busto;
					end
				end
				else begin
					if (clipEnable && (fixToInt(charBoxX0) + pixhc < clipX0 || fixToInt(charBoxX0) + pixhc >= clipX1 || fixToInt(charBoxY0) + pixvc < clipY0))
						;
					else if (fixToInt(charBoxX0) + pixhc >= TargetWidth)
						;
					else begin
						m_cyc_o <= `HIGH;
						m_sel_o <= 16'd3 << {tgtadr[3:1],1'b0};
						m_we_o <= `HIGH;
						m_adr_o <= tgtadr;
						m_dat_o <= {8{penColor[15:0]}};
						tocnt <= busto;
					end
				end
			end
		end
		charbmp <= {1'b0,charbmp[31:1]};
		pixhc <= pixhc + 5'd1;
		if (pixhc==font_width) begin
			tblit_state <= ST_READ_CHAR_BITMAP;
		    pixhc <= 5'd0;
		    pixvc <= pixvc + 5'd1;
		    if (clipEnable && (fixToInt(charBoxY0) + pixvc + 16'd1 >= clipY1))
		    	tblit_active <= `FALSE;
		    else if (fixToInt(charBoxY0) + pixvc + 16'd1 >= TargetHeight)
		    	tblit_active <= `FALSE;
		    else if (pixvc==font_height)
		    	tblit_active <= `FALSE;
		end
		else
			tblit_state <= ST_WRITE_CHAR;
		call(ST_LATCH_DATA,ST_WRITE_CHAR2_NACK);
	end
ST_WRITE_CHAR2_NACK:
	if (~m_ack_i) begin
		if (!tblit_active)
			tblit_state <= OTHERS;
		return();
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Pixel plot acceleration states
// For binary raster operations a back-to-back read then write is performed.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_PLOT:
	begin
		gcx <= fixToInt(p0x);
		gcy <= fixToInt(p0y);
		if (IsBinaryROP(ctrl[11:8]))
			call(DELAY3,ST_PLOT_READ);
		else
			call(DELAY3,ST_PLOT_WRITE);
	end
ST_PLOT_READ:
    begin
	    m_cyc_o <= `HIGH;
		m_adr_o <= ma;
		tocnt <= busto;
		// The memory address doesn't change from read to write so
		// there's no need to wait for it to update, it's already
		// correct.
		call(ST_LATCH_DATA,ST_PLOT_WRITE);
    end
ST_PLOT_WRITE:
	begin
		tocnt <= busto;
		set_pixel(penColor[15:0],alpha,ctrl[11:8]);
		goto(ST_LATCH_DATA);
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Line draw states
// Line drawing may also be done by the blitter.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
/*
// State to setup invariants for DRAWLINE
DL_PRECALC:
	begin
		if (!ctrl[14]) begin
			ctrl[14] <= 1'b1;
			gcx <= fixToInt(p0x);
			gcy <= fixToInt(p0y);
			dx <= fixToInt(absx1mx0);
			dy <= fixToInt(absy1my0);
			if (p0x < p1x) sx <= 16'h0001; else sx <= 16'hFFFF;
			if (p0y < p1y) sy <= 16'h0001; else sy <= 16'hFFFF;
			err <= fixToInt(absx1mx0)-fixToInt(absy1my0);
		end
		else if (((ctrl[11:8] != 4'h1) &&
			(ctrl[11:8] != 4'h0) &&
			(ctrl[11:8] != 4'hF)) || zbuf)
			call(DELAY3,DL_GETPIXEL);
		else
			call(DELAY3,DL_SETPIXEL);
	end
DL_GETPIXEL:
	begin
		m_cyc_o <= `HIGH;
		m_sel_o <= 16'hFFFF;
		m_adr_o <= zbuf ? ma[19:3] : ma;
		tocnt <= busto;
		call(ST_LATCH_DATA,DL_SETPIXEL);
	end
DL_SETPIXEL:
	begin
		set_pixel(penColor,alpha,ctrl[11:8]);
		if (gcx==fixToInt(p1x) && gcy==fixToInt(p1y)) begin
			if (state1==OTHERS)
				ctrl[14] <= 1'b0;
			goto(DL_RET);
		end
		else
			goto(DL_TEST);
	end
DL_TEST:
	begin
		m_cyc_o <= `LOW;
		m_we_o <= `LOW;
		m_sel_o <= 16'h0000;
		tocnt <= busto;
		err <= err - ((e2 > -dy) ? dy : 16'd0) + ((e2 < dx) ? dx : 16'd0);
		if (e2 > -dy)
			gcx <= gcx + sx;
		if (e2 <  dx)
			gcy <= gcy + sy;
		pause(DL_PRECALC);
	end
DL_RET:
	if (m_ack_i) begin
		m_cyc_o <= `LOW;
		m_we_o <= `LOW;
		m_sel_o <= 16'h0000;
		pause(OTHERS);
	end
*/
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Blitter DMA
// Blitter has four DMA channels, three source channels and one destination
// channel.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

	// Blit channel A
ST_BLTDMA2:
	begin
	    m_cyc_o <= `HIGH;
		m_adr_o <= bltA_wadr;
		bltinc <= bltCtrl[8] ? 32'hFFFFFFFE : 32'd2;
		call(ST_LATCH_DATA,ST_BLTDMA2_NACK);
    end
ST_BLTDMA2_NACK:
	if (~m_ack_i) begin
		bltA_datx <= latched_data >> {bltA_wadr[3:1],4'h0};
		bltA_wadr <= bltA_wadr + bltinc;
	    bltA_hcnt <= bltA_hcnt + 32'd1;
	    if (bltA_hcnt==bltSrcWid) begin
		    bltA_hcnt <= 32'd1;
		    bltA_wadr <= bltA_wadr + bltA_modx + bltinc;
		end
        bltA_wcnt <= bltA_wcnt + 32'd1;
        bltA_dcnt <= bltA_dcnt + 32'd1;
        if (bltA_wcnt==bltA_cntx) begin
            bltA_wadr <= bltA_badrx;
            bltA_wcnt <= 32'd1;
            bltA_hcnt <= 32'd1;
        end
		if (bltA_dcnt==bltD_cntx)
			bltCtrlx[1] <= 1'b0;
		if (bltCtrlx[3])
			blt_nch <= 2'b01;
		else if (bltCtrlx[5])
			blt_nch <= 2'b10;
		else if (bltCtrlx[7])
			blt_nch <= 2'b11;
		else
			blt_nch <= 2'b00;
		return();
	end

	// Blit channel B
ST_BLTDMA4:
	begin
		m_cyc_o <= `HIGH;
		m_sel_o <= 16'h0003 << {bltB_wadr[3:1],1'b0};
		m_adr_o <= bltB_wadr;
		bltinc <= bltCtrlx[9] ? 32'hFFFFFFFE : 32'd2;
		call(ST_LATCH_DATA,ST_BLTDMA4_NACK);
	end
ST_BLTDMA4_NACK:
	if (~m_ack_i) begin
		bltB_datx <= latched_data >> {bltB_wadr[3:1],4'h0};
        bltB_wadr <= bltB_wadr + bltinc;
        bltB_hcnt <= bltB_hcnt + 32'd1;
        if (bltB_hcnt==bltSrcWidx) begin
            bltB_hcnt <= 32'd1;
            bltB_wadr <= bltB_wadr + bltB_modx + bltinc;
        end
        bltB_wcnt <= bltB_wcnt + 32'd1;
        bltB_dcnt <= bltB_dcnt + 32'd1;
        if (bltB_wcnt==bltB_cntx) begin
            bltB_wadr <= bltB_badrx;
            bltB_wcnt <= 32'd1;
            bltB_hcnt <= 32'd1;
        end
		if (bltB_dcnt==bltD_cntx)
			bltCtrlx[3] <= 1'b0;
		if (bltCtrlx[5])
			blt_nch <= 2'b10;
		else if (bltCtrlx[7])
			blt_nch <= 2'b11;
		else if (bltCtrlx[1])
			blt_nch <= 2'b00;
		else
			blt_nch <= 2'b01;
		return();
	end

	// Blit channel C
ST_BLTDMA6:
	begin
		m_cyc_o <= `HIGH;
		m_sel_o <= 16'h3 << {bltC_wadr[3:1],1'b0};
		m_adr_o <= bltC_wadr;
		bltinc <= bltCtrlx[10] ? 32'hFFFFFFFE : 32'd2;
		call(ST_LATCH_DATA,ST_BLTDMA6_NACK);		
	end
ST_BLTDMA6_NACK:
	if (~m_ack_i) begin
		bltC_datx <= latched_data >> {bltC_wadr[3:1],4'h0};
        bltC_wadr <= bltC_wadr + bltinc;
        bltC_hcnt <= bltC_hcnt + 32'd1;
        if (bltC_hcnt==bltSrcWidx) begin
            bltC_hcnt <= 32'd1;
            bltC_wadr <= bltC_wadr + bltC_modx + bltinc;
        end
        bltC_wcnt <= bltC_wcnt + 32'd1;
        bltC_dcnt <= bltC_dcnt + 32'd1;
        if (bltC_wcnt==bltC_cntx) begin
            bltC_wadr <= bltC_badrx;
            bltC_wcnt <= 32'd1;
            bltC_hcnt <= 32'd1;
        end
		if (bltC_dcnt==bltD_cntx)
			bltCtrlx[5] <= 1'b0;
		if (bltCtrlx[7])
			blt_nch <= 2'b11;
		else if (bltCtrlx[1])
			blt_nch <= 2'b00;
		else if (bltCtrlx[3])
			blt_nch <= 2'b01;
		else
			blt_nch <= 2'b10;
		return();
	end

	// Blit channel D
ST_BLTDMA8:
	begin
		m_cyc_o <= `HIGH;
		m_we_o <= `HIGH;
		m_sel_o <= 16'h0003 << {bltD_wadr[3:1],1'b0};
		m_adr_o <= bltD_wadr;
		// If there's no source then a fill operation muct be taking place.
		if (bltCtrlx[1]|bltCtrlx[3]|bltCtrlx[5])
			m_dat_o <= {8{bltabc}};
		else
			m_dat_o <= {8{16'h7c00}};// {8{bltD_datx}};	// fill color
		bltinc <= bltCtrlx[11] ? 32'hFFFFFFFE : 32'd2;
		call(ST_LATCH_DATA,ST_BLTDMA8_NACK);
	end
ST_BLTDMA8_NACK:
	if (~m_ack_i) begin
		bltD_wadr <= bltD_wadr + bltinc;
		bltD_wcnt <= bltD_wcnt + 32'd1;
		bltD_hcnt <= bltD_hcnt + 32'd1;
		if (bltD_hcnt==bltDstWidx) begin
			bltD_hcnt <= 32'd1;
			bltD_wadr <= bltD_wadr + bltD_modx + bltinc;
		end
		if (bltD_wcnt==bltD_cntx) begin
			bltCtrlx[14] <= 1'b0;
			bltCtrlx[13] <= 1'b1;
			bltCtrlx[7] <= 1'b0;
		end
		if (bltCtrlx[1])
			blt_nch <= 2'b00;
		else if (bltCtrlx[3])
			blt_nch <= 2'b01;
		else if (bltCtrlx[5])
			blt_nch <= 2'b10;
		else
			blt_nch <= 2'b11;
		return();
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Draw a filled rectangle, uses the blitter.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_FILLRECT:
	begin
		// Switching the points around will have the side effect
		// of switching the transformed points around as well.
		if (p1y < p0y) up0y <= up1y;
		if (p1x < p0x) up0x <= up1x;
		dx <= fixToInt(absx1mx0) + 16'd1;	// Order of points doesn't matter here.
		dy <= fixToInt(absy1my0) + 16'd1;
		// Wait for previous blit to finish
		// then delay 1 cycle for point switching
		if (bltCtrlx[13]||!(bltCtrlx[15]||bltCtrlx[14]))
			call(DELAY1,ST_FILLRECT_CLIP);
	end
ST_FILLRECT_CLIP:
	begin
		if (fixToInt(p0x) + dx > TargetWidth)
			dx <= TargetWidth - fixToInt(p0x);
		if (fixToInt(p0y) + dy > TargetHeight)
			dy <= TargetHeight - fixToInt(p0y);
		goto(ST_FILLRECT2);
	end
ST_FILLRECT2:
	begin
		bltD_badrx <= {8'h00,fixToInt(p0y)} * {TargetWidth,1'b0} + TargetBase + {fixToInt(p0x),1'b0};
		bltD_modx <= TargetWidth - dx;
		bltD_cntx <= dx * dy;
		bltDstWidx <= dx;
		bltD_datx <= fillColor[15:0];
		bltCtrlx[15:0] <= 16'h8080;
		return();
	end

default:    goto(WAIT_RESET);
endcase
    // Override any other state assignments
    if (m_hctr<=12'd16)
    	lrst <= `TRUE;

	case(sprite_on)
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
	default:	collision <= collision | sprite_on;
	endcase

end


// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #-1
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Compute when to shift sprite bitmaps.
// Set sprite active flag
// Increment working count and address

reg [31:0] spriteShift;
always @(posedge vclk)
    for (n = 0; n < NSPR; n = n + 1)
    begin
        spriteShift[n] <= `FALSE;
	    case(lowres)
	    2'd0,2'd3:	if (hctr >= sprite_ph[n]) spriteShift[n] <= `TRUE;
		2'd1:		if (hctr[11:1] >= sprite_ph[n]) spriteShift[n] <= `TRUE;
		2'd2:		if (hctr[11:2] >= sprite_ph[n]) spriteShift[n] <= `TRUE;
		endcase
	end

always @(posedge vclk)
    for (n = 0; n < NSPR; n = n + 1)
		spriteActive[n] = (spriteWcnt[n] <= spriteMcnt[n]) && spriteEnable[n];

always @(posedge vclk)
    for (n = 0; n < NSPR; n = n + 1)
	begin
	    case(lowres)
	    2'd0,2'd3:	if ((vctr == sprite_pv[n]) && (hctr == 12'h005)) spriteWcnt[n] <= 16'd0;
		2'd1:		if ((vctr[11:1] == sprite_pv[n]) && (hctr == 12'h005)) spriteWcnt[n] <= 16'd0;
		2'd2:		if ((vctr[11:2] == sprite_pv[n]) && (hctr == 12'h005)) spriteWcnt[n] <= 16'd0;
		endcase
		if (hctr==hTotal-12'd2)	// must be after image data fetch
    		if (spriteActive[n])
    		case(lowres)
    		2'd0,2'd3:	spriteWcnt[n] <= spriteWcnt[n] + 16'd32;
    		2'd1:		if (vctr[0]) spriteWcnt[n] <= spriteWcnt[n] + 16'd32;
    		2'd2:		if (vctr[1:0]==2'b11) spriteWcnt[n] <= spriteWcnt[n] + 16'd32;
    		endcase
	end

always @(posedge vclk)
    for (n = 0; n < NSPR; n = n + 1)
	begin
	    case(lowres)
	    2'd0,2'd3:	if ((vctr == sprite_pv[n]) && (hctr == 12'h005)) spriteWaddr[n] <= spriteAddr[n];
		2'd1:		if ((vctr[11:1] == sprite_pv[n]) && (hctr == 12'h005)) spriteWaddr[n] <= spriteAddr[n];
		2'd2:		if ((vctr[11:2] == sprite_pv[n]) && (hctr == 12'h005)) spriteWaddr[n] <= spriteAddr[n];
		endcase
		if (hctr==hTotal-12'd2)	// must be after image data fetch
		case(lowres)
   		2'd0,2'd3:	spriteWaddr[n] <= spriteWaddr[n] + 32'd16;
   		2'd1:		if (vctr[0]) spriteWaddr[n] <= spriteWaddr[n] + 32'd16;
   		2'd2:		if (vctr[1:0]==2'b11) spriteWaddr[n] <= spriteWaddr[n] + 32'd16;
   		endcase
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #0
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Get the sprite display status
// Load the sprite bitmap from ram
// Determine when sprite output should appear
// Shift the sprite bitmap
// Compute color indexes for all sprites

always @(posedge vclk)
begin
    for (n = 0; n < NSPR; n = n + 1)
        if (spriteActive[n] & spriteShift[n]) begin
            sprite_on[n] <=
                spriteLink1[n] ? |{ spriteBmp[(n+1)&31][127:124],spriteBmp[n][127:124]} : 
                |spriteBmp[n][127:124];
        end
        else
            sprite_on[n] <= 1'b0;
end

// Load / shift sprite bitmap
// Register sprite data back to vclk domain
always @(posedge vclk)
begin
	if (hctr==12'h5)
		for (n = 0; n < NSPR; n = n + 1)
			spriteBmp[n] <= m_spriteBmp[n];
    for (n = 0; n < NSPR; n = n + 1)
        if (spriteShift[n])
        	case(lowres)
        	2'd0,2'd3:	spriteBmp[n] <= {spriteBmp[n][123:0],4'h0};
        	2'd1:	if (hctr[0]) spriteBmp[n] <= {spriteBmp[n][123:0],4'h0};
        	2'd2:	if (&hctr[1:0]) spriteBmp[n] <= {spriteBmp[n][123:0],4'h0};
    		endcase
end

always @(posedge vclk)
for (n = 0; n < NSPR; n = n + 1)
if (spriteLink1[n])
    spriteColorNdx[n] <= {spriteBmp[(n+1)&31][127:124],spriteBmp[n][127:124]};
else
    spriteColorNdx[n] <= {n[3:0],spriteBmp[n][127:124]};

// Compute index into sprite color palette
// If none of the sprites are linked, each sprite has it's own set of colors.
// If the sprites are linked once the colors are available in groups.
// If the sprites are linked twice they all share the same set of colors.
// Pipelining register
reg blank1, blank2, blank3, blank4;
reg border1, border2, border3, border4;
reg any_sprite_on2, any_sprite_on3, any_sprite_on4;
reg [14:0] rgb_i3, rgb_i4;
reg [3:0] zb_i3, zb_i4;
reg [3:0] sprite_z1, sprite_z2, sprite_z3, sprite_z4;
reg [3:0] sprite_pzx;
// The color index from each sprite can be mux'ed into a single value used to
// access the color palette because output color is a priority chain. This
// saves having mulriple read ports on the color palette.
reg [31:0] spriteColorOut2; 
reg [31:0] spriteColorOut3;
reg [7:0] spriteClrNdx;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #1
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Mux color index
// Fetch sprite Z order

always @(posedge vclk)
    sprite_on_d1 <= sprite_on;
always @(posedge vclk)
    blank1 <= blank;
always @(posedge vclk)
    border1 <= border;

always @(posedge vclk)
begin
	spriteClrNdx <= 8'd0;
	for (n = NSPR-1; n >= 0; n = n -1)
		if (sprite_on[n])
			spriteClrNdx <= spriteColorNdx[n];
end
        
always @(posedge vclk)
begin
	sprite_z1 <= 4'hF;
	for (n = NSPR-1; n >= 0; n = n -1)
		if (sprite_on[n])
			sprite_z1 <= sprite_pz[n]; 
end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #2
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Lookup color from palette

always @(posedge vclk)
    sprite_on_d2 <= sprite_on_d1;
always @(posedge vclk)
    any_sprite_on2 <= |sprite_on_d1;
always @(posedge vclk)
    blank2 <= blank1;
always @(posedge vclk)
    border2 <= border1;
always @(posedge vclk)
    spriteColorOut2 <= sprite_color[spriteClrNdx];
always @(posedge vclk)
    sprite_z2 <= sprite_z1;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #3
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Compute alpha blending

wire [12:0] alphaRed = (rgb_i[`R] * spriteColorOut2[31:24]) + (spriteColorOut2[`R] * (9'h100 - spriteColorOut2[31:24]));
wire [12:0] alphaGreen = (rgb_i[`G] * spriteColorOut2[31:24]) + (spriteColorOut2[`G]  * (9'h100 - spriteColorOut2[31:24]));
wire [12:0] alphaBlue = (rgb_i[`B] * spriteColorOut2[31:24]) + (spriteColorOut2[`B]  * (9'h100 - spriteColorOut2[31:24]));
reg [14:0] alphaOut;

always @(posedge vclk)
    alphaOut <= {alphaRed[12:8],alphaGreen[12:8],alphaBlue[12:8]};
always @(posedge vclk)
    sprite_z3 <= sprite_z2;
always @(posedge vclk)
    any_sprite_on3 <= any_sprite_on2;
always @(posedge vclk)
    rgb_i3 <= rgb_i;
always @(posedge vclk)
    zb_i3 <= 4'hF;//zb_i;
always @(posedge vclk)
    blank3 <= blank2;
always @(posedge vclk)
    border3 <= border2;
always @(posedge vclk)
    spriteColorOut3 <= spriteColorOut2;

reg [14:0] flashOut;
wire [14:0] reverseVideoOut = spriteColorOut2[21] ? alphaOut ^ 15'h7FFF : alphaOut;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #4
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Compute flash output

always @(posedge vclk)
    flashOut <= spriteColorOut3[20] ? (((flashcnt[5:2] & spriteColorOut3[19:16])!=4'b000) ? reverseVideoOut : rgb_i3) : reverseVideoOut;
always @(posedge vclk)
    rgb_i4 <= rgb_i3;
always @(posedge vclk)
    sprite_z4 <= sprite_z3;
always @(posedge vclk)
    any_sprite_on4 <= any_sprite_on3;
always @(posedge vclk)
    zb_i4 <= zb_i3;
always @(posedge vclk)
    blank4 <= blank3;
always @(posedge vclk)
    border4 <= border3;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #5
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// final output registration

always @(posedge vclk)
	casez({blank4,border4,any_sprite_on4})
	3'b1??:		rgb <= 24'h0000;
	3'b01?:		rgb <= borderColor;
	3'b001:		rgb <= ((zb_i4 < sprite_z4) ? {rgb_i4[14:10],3'b0,rgb_i4[9:5],3'b0,rgb_i4[4:0],3'b0} :
											{flashOut[14:10],3'b0,flashOut[9:5],3'b0,flashOut[4:0],3'b0});
	3'b000:		rgb <= {rgb_i4[14:10],3'b0,rgb_i4[9:5],3'b0,rgb_i4[4:0],3'b0};
	endcase
always @(posedge vclk)
    de <= ~blank4;


// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Support tasks
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

task set_pixel;
input [15:0] color;
input [15:0] alpha;
input [3:0] rop;
begin
	m_cyc_o <= `LOW;
	m_we_o <= `LOW;
	m_sel_o <= 16'h0000;
	if (fnClip(gcx,gcy))
		;
/*
	else if (zbuf) begin
		m_cyc_o <= `HIGH;
		m_we_o <= `HIGH;
		m_sel_o <= 16'hFFFF;
		m_adr_o <= ma[31:1];
		m_dat_o <= latched_data & ~{128'b1111 << {ma[4:0],2'b0}} | ({124'b0,zlayer} << {ma[4:0],2'b0});
	end
*/
	else begin
		// The same operation is performed on all pixels, however the
		// data mask is set so that only the desired pixel is updated
		// in memory.
		m_cyc_o <= `HIGH;
		m_we_o <= `HIGH;
		m_sel_o <= 16'b11 << {ma[3:1],1'b0};
		m_adr_o <= ma;
		case(rop)
		4'd0:	m_dat_o <= {8{16'h0000}};
		4'd1:	m_dat_o <= {8{color}};
		4'd3:	m_dat_o <= {8{blend(color,latched_data>>{ma[3:1],4'h0},alpha)}};
		4'd4:	m_dat_o <= {8{color}} & latched_data;
		4'd5:	m_dat_o <= {8{color}} | latched_data;
		4'd6:	m_dat_o <= {8{color}} ^ latched_data;
		4'd7:	m_dat_o <= {8{color}} & ~latched_data;
		4'hF:	m_dat_o <= {8{16'h7FFF}};
		default:	m_dat_o <= {8{16'h0000}};
		endcase
	end
end
endtask


task goto;
input [7:0] st;
begin
	state <= st;
end
endtask

task return;
begin
	state4 <= state5;
	state3 <= state4;
	state2 <= state3;
	state1 <= state2;
	state <= state1;
end
endtask

task call;
input [7:0] st;
input [7:0] rst;
begin
	state1 <= rst;
	state2 <= state1;
	state3 <= state2;
	state4 <= state3;
	state5 <= state4;
	state <= st;
end
endtask

task pause;
input [7:0] st;
begin
	ngs <= st;
	return();
end
endtask

endmodule

