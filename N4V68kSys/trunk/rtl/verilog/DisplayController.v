// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// DisplayController.v
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

//`define USE_FIFO

module DisplayController(
	clk200_i,
	rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o,
	cs_i, cs_ram_i, irq_o,
	clk, eol, eof, blank, border, vbl_int, rgb,
	aud0_out, aud1_out, aud2_out, aud3_out
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
parameter ST_AUD0_1 = 7'd65;
parameter ST_AUD0_2 = 7'd66;
parameter ST_AUD0_3 = 7'd67;
parameter ST_AUD1 = 7'd68;
parameter ST_AUD1_1 = 7'd69;
parameter ST_AUD1_2 = 7'd70;
parameter ST_AUD1_3 = 7'd71;
parameter ST_AUD2 = 7'd72;
parameter ST_AUD2_1 = 7'd73;
parameter ST_AUD2_2 = 7'd74;
parameter ST_AUD2_3 = 7'd75;
parameter ST_AUD3 = 7'd76;
parameter ST_AUD3_1 = 7'd77;
parameter ST_AUD3_2 = 7'd78;
parameter ST_AUD3_3 = 7'd79;

integer n;
reg [6:0] state = ST_IDLE;
reg [15:0] irq_en = 16'h0;
reg [15:0] irq_status;
assign irq_o = |(irq_status & irq_en);

// ctrl
// -b--- rrrr ---- cccc
//  |      |         +-- grpahics command
//  |      +------------ raster op
// +-------------------- busy indicator
reg [15:0] ctrl;
reg lowres = `TRUE;
reg [19:0] bmpBase = 20'h00000;		// base address of bitmap
reg [19:0] charBmpBase = 20'h5C000;	// base address of character bitmaps
reg [11:0] hstart = 12'hEB3;		// -333
reg [11:0] vstart = 12'hFB0;		// -80
reg [11:0] hpos;
reg [11:0] vpos;
reg [4:0] fpos;
reg [11:0] bitmapWidth = 12'd320;
reg [15:0] borderColor;
wire [15:0] rgb_i;					// internal rgb output from ram

reg [104:0] cmdq_in;
wire [104:0] cmdq_out;

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
reg cursor;
reg [11:0] cursor_v;
reg [11:0] cursor_h;
reg [4:0] cx, cy;
reg [15:0] cursor_color;
reg [3:0] flashrate;

reg [3:0] cursor_sv;				// cursor size
reg [3:0] cursor_sh;
reg [15:0] cursor_bmp [0:15];
reg [19:0] rdndx;					// video read index
reg [19:0] ram_addr;
reg [15:0] ram_data_i;
wire [15:0] ram_data_o;
reg [1:0] ram_we;

reg [ 9:0] pixcnt;
reg [3:0] pixhc,pixvc;
reg [3:0] bitcnt, bitinc;

reg [19:0] bltSrcWid;
reg [19:0] bltDstWid;
reg [19:0] bltCount;
//  ch  321033221100       
//  TBD-ddddebebebeb
//  |||   |       |+- bitmap mode
//  |||   |       +-- channel enabled
//  |||   +---------- direction 0=normal,1=decrement
//  ||+-------------- done indicator
//  |+--------------- busy indicator
//  +---------------- trigger bit
reg [15:0] bltCtrl;

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

//      3210      3210
// ---- rrrr ---- eeee
//        |         +--- channel enables
//        +------------- chennel reset
//
// The channel needs to be reset for use as this loads the working address
// register with the audio sample base address.
//
reg [15:0] aud_ctrl;
reg [19:0] aud0_adr;
reg [15:0] aud0_length;
reg [15:0] aud0_period;
reg [15:0] aud0_volume;
reg [15:0] aud0_dat;
reg [19:0] aud1_adr;
reg [15:0] aud1_length;
reg [15:0] aud1_period;
reg [15:0] aud1_volume;
reg [15:0] aud1_dat;
reg [19:0] aud2_adr;
reg [15:0] aud2_length;
reg [15:0] aud2_period;
reg [15:0] aud2_volume;
reg [15:0] aud2_dat;
reg [19:0] aud3_adr;
reg [15:0] aud3_length;
reg [15:0] aud3_period;
reg [15:0] aud3_volume;
reg [15:0] aud3_dat;

// May need to set the pipeline depth to zero if copying neighbouring pixels
// during a blit. So the app is allowed to control the pipeline depth. Depth
// should not be set >28.
reg [4:0] bltPipedepth = 5'd15;
reg [19:0] bltinc;
reg [4:0] bltAa,bltBa,bltCa;
reg [18:0] wrA, wrB, wrC;
reg [15:0] blt_bmpA;
reg [15:0] blt_bmpB;
reg [15:0] blt_bmpC;

wire [15:0] bltA_out, bltB_out, bltC_out;
reg  [15:0] bltD_dat;
wire [15:0] bltA_in = bltCtrl[0] ? (blt_bmpA[bitcnt] ? 16'h7FFF : 16'h0000) : blt_bmpA;
wire [15:0] bltB_in = bltCtrl[2] ? (blt_bmpB[bitcnt] ? 16'h7FFF : 16'h0000) : blt_bmpB;
wire [15:0] bltC_in = bltCtrl[4] ? (blt_bmpC[bitcnt] ? 16'h7FFF : 16'h0000) : blt_bmpC;

reg srstA, srstB, srstC;
reg bltRdf;

`ifdef USE_FIFO
bltFifo ubfA
(
  .clk(clk_i),
  .srst(srstA),
  .din(bltA_in),
  .wr_en(wrA[0]),
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
  .wr_en(wrB[0]),
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
  .wr_en(wrC[0]),
  .rd_en(bltRdf),
  .dout(bltC_out),
  .full(),
  .empty()
);
`else
vtdl #(.WID(16), .DEP(32)) bltA (.clk(clk_i), .ce(wrA[0]), .a(bltAa), .d(bltA_in), .q(bltA_out));
vtdl #(.WID(16), .DEP(32)) bltB (.clk(clk_i), .ce(wrB[0]), .a(bltBa), .d(bltB_in), .q(bltB_out));
vtdl #(.WID(16), .DEP(32)) bltC (.clk(clk_i), .ce(wrC[0]), .a(bltCa), .d(bltC_in), .q(bltC_out));
`endif

reg [15:0] bltab;
reg [15:0] bltabc;
always @*
	case(blt_op[3:0])
	4'h1:	bltab <= bltA_out;
	4'h2:	bltab <= bltB_out;
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
reg [15:0] charbmp;					// hold character bitmap scanline
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
	.clkb(clk),
	.enb(1'b1),
	.web(1'b0),
	.addrb(rdndx),
	.dinb(16'h0000),
	.doutb(rgb_i)
);

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

always @(posedge clk)
	if ((hpos >> lowres) == cursor_h)
		cx <= 0;
	else
		cx <= cx + 5'd1;
always @(posedge clk)
	if ((vpos >> lowres) == cursor_v)
		cy <= 0;
	else if (eol)
		cy <= cy + 5'd1;

always @(posedge clk)
	if ((flashcnt[5:2] & flashrate[3:0])!=4'b000 || flashrate[4]) begin
		if (lowres) begin
			if ((vpos[11:1] >= cursor_v && vpos[11:1] <= cursor_v + cursor_sv) &&
				(hpos[11:1] >= cursor_h && hpos[11:1] <= cursor_h + cursor_sh))
				cursor <= cursor_bmp[cy[4:1]][cx[4:1]];
			else
				cursor <= 1'b0;
		end
		else begin
			if ((vpos >= cursor_v && vpos <= cursor_v + cursor_sv) &&
				(hpos >= cursor_h && hpos <= cursor_h + cursor_sh))
				cursor <= cursor_bmp[cy[3:0]][cx[3:0]];
			else
				cursor <= 1'b0;
		end
	end
	else
		cursor <= 1'b0;

always @(posedge clk)
	if (lowres)
		rdndx <= {9'h00,vpos[11:1]} * {8'h00,bitmapWidth} + {bmpBase[19:12],1'b0,hpos[11:1]};
	else
		rdndx <= {8'h00,vpos} * {8'h00,bitmapWidth} + {bmpBase[19:12],hpos};

always @(posedge clk)
	rgb <= 	blank ? 15'h0000 :
		   	border ? borderColor :
       		cursor ? (cursor_color[15] ? rgb_i[14:0] ^ 15'h7FFF : cursor_color) :
			rgb_i[14:0];

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

reg [19:0] aud0_wadr, aud1_wadr, aud2_wadr, aud3_wadr;
reg [19:0] ch0_cnt, ch1_cnt, ch2_cnt, ch3_cnt;
// The request counter keeps track of the number of times a request was issued
// without being serviced. There may be the occasional request missed by the
// timing budget. The counter allows the sample to remain on-track and in
// sync with other samples being read.
reg [5:0] aud0_req, aud1_req, aud2_req, aud3_req;

always @(posedge clk_i)
	if (ch0_cnt>=aud0_period || aud_ctrl[8])
		ch0_cnt <= 20'd1;
	else if (aud_ctrl[0])
		ch0_cnt <= ch0_cnt + 20'd1;
always @(posedge clk_i)
	if (ch1_cnt>=aud1_period || aud_ctrl[9])
		ch1_cnt <= 20'd1;
	else if (aud_ctrl[1])
		ch1_cnt <= ch1_cnt + 20'd1;
always @(posedge clk_i)
	if (ch2_cnt>=aud2_period || aud_ctrl[10])
		ch2_cnt <= 20'd1;
	else if (aud_ctrl[2])
		ch2_cnt <= ch2_cnt + 20'd1;
always @(posedge clk_i)
	if (ch3_cnt>=aud3_period || aud_ctrl[11])
		ch3_cnt <= 20'd1;
	else if (aud_ctrl[3])
		ch3_cnt <= ch3_cnt + 20'd1;

wire [31:0] aud0_tmp = aud0_dat * aud0_volume;
wire [31:0] aud1_tmp = aud1_dat * aud1_volume;
wire [31:0] aud2_tmp = aud2_dat * aud2_volume;
wire [31:0] aud3_tmp = aud3_dat * aud3_volume;

always @*
begin
	aud0_out <= aud_ctrl[0] ? aud0_tmp >> 16 : 16'h0000;
	aud1_out <= aud_ctrl[1] ? aud1_tmp >> 16 : 16'h0000;
	aud2_out <= aud_ctrl[2] ? aud2_tmp >> 16 : 16'h0000;
	aud3_out <= aud_ctrl[3] ? aud3_tmp >> 16 : 16'h0000;
end

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
	ack_o <= (cs_reg ? rdy2 : cs_ram ? ack : 1'b0) & ~ack_o;

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
reg reg_cs;
reg reg_we;
reg [10:0] reg_adr;
reg [15:0] reg_dat;
	
always @(posedge clk_i)
if (rst_i) begin
	bltCtrl <= 16'b0010_0000_0000_0000;
end
else begin
reg_copper <= `FALSE;
reg_cs <= cs_reg;
reg_we <= we_i;
reg_adr <= adr_i[10:0];
reg_dat <= dat_i;
if (reg_cs|reg_copper) begin
	if (reg_we) begin
		casex(reg_adr[10:1])
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
		
		10'b100_0100_000:	cursor_h <= reg_dat[11:0];
		10'b100_0100_001:	cursor_v <= reg_dat[11:0];
		10'b100_0100_010:	begin
								cursor_sh <= reg_dat[3:0];
								cursor_sv <= reg_dat[11:8];
							end
		10'b100_0100_011:	cursor_color <= reg_dat[15:0];
		10'b100_0100_100:	flashrate <= reg_dat[4:0];
		10'b100_011x_xxx:	cursor_bmp[reg_adr[4:1]] <= reg_dat;
	
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
		default:	;	// do nothing
		endcase
	end
	else begin
		case(reg_adr[10:1])
		10'b1000010110:	dat_o <= {11'h00,cmdq_ndx};
		10'b1001010110:	dat_o <= bltCtrl;
		10'b1011000001:	dat_o <= irq_status;
		default:	dat_o <= srdo;
		endcase
	end
end

if (aud_ctrl[8])
	aud0_wadr <= aud0_adr;
if (aud_ctrl[9])
	aud1_wadr <= aud1_adr;
if (aud_ctrl[10])
	aud2_wadr <= aud2_adr;
if (aud_ctrl[11])
	aud3_wadr <= aud3_adr;
// IF channel count == 1
// A count value of zero is not possible so there will be no requests unless
// the audio channel is enabled.
if (ch0_cnt==aud_ctrl[0] & ~aud_ctrl[8])
	aud0_req <= aud0_req + 6'd1;
if (ch1_cnt==aud_ctrl[1] & ~aud_ctrl[9])
	aud1_req <= aud1_req + 6'd1;
if (ch2_cnt==aud_ctrl[2] & ~aud_ctrl[10])
	aud2_req <= aud2_req + 6'd1;
if (ch3_cnt==aud_ctrl[3] & ~aud_ctrl[11])
	aud3_req <= aud3_req + 6'd1;

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

case(state)
ST_IDLE:
	begin
		ram_we <= {2{`LOW}};
		ack <= `LOW;
		
		if (|aud0_req) begin
			state <= ST_AUD0;
		end
		else if (|aud1_req) begin
			state <= ST_AUD1;
		end
		else if (|aud2_req) begin
			state <= ST_AUD2;
		end
		else if (|aud3_req) begin
			state <= ST_AUD3;
		end
		else if (cs_ram) begin
			ram_data_i <= dat_i;
			ram_addr <= adr_i[20:1];
			ram_we <= {2{we_i}} & sel_i;
			state <= ST_RW;
		end
		
		else if (copper_state==2'b01 && copper_en) begin
			state <= ST_COPPER_IFETCH;
		end

		// busy with a graphics command ?
		else if (ctrl[14]) begin
//			bltCtrl[13] <= 1'b0;
			case(ctrl[3:0])
			4'd2:	state <= DL_PRECALC;
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
			srcA_wcnt <= 20'd0;
			srcB_wcnt <= 20'd0;
			srcC_wcnt <= 20'd0;
			dstD_wcnt <= 20'd0;
			srcA_dcnt <= 20'd0;
			srcB_dcnt <= 20'd0;
			srcC_dcnt <= 20'd0;
			srcA_hcnt <= 20'd0;
			srcB_hcnt <= 20'd0;
			srcC_hcnt <= 20'd0;
			dstD_hcnt <= 20'd0;
			if (bltCtrl[1])
				state <= ST_BLTDMA1;
			else if (bltCtrl[3])
				state <= ST_BLTDMA3;
			else if (bltCtrl[5])
				state <= ST_BLTDMA5;
			else
				state <= ST_BLTDMA7;
		end
	end

ST_CMD:
	begin
		ctrl[3:0] <= cmd_qo[3:0];
		ctrl[14] <= 1'b0;
		case(cmd_qo[3:0])
		4'd0:	state <= ST_CHAR_INIT;	// draw character
		4'd1:	state <= ST_PLOT;
		4'd2:	begin
				ctrl[11:8] <= cmdq_out[12:9];	// raster op
				state <= DL_INIT;			// draw line
				end
		default:	state <= ST_IDLE;
		endcase
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Standard RAM read/write
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_RW:	state <= ST_RW2;
ST_RW2:
	begin
        ack <= `HIGH;
        dat_o <= ram_data_o;
        if (~cs_ram) begin
            ram_we <= {2{`LOW}};
            ack <= `LOW;
            state <= ST_IDLE;
        end
    end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Audio DMA states
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_AUD0:
	begin
		ram_addr <= aud0_wadr;
		aud0_wadr <= aud0_wadr + aud0_req;
		aud0_req <= 6'd0;
		if (aud0_wadr + aud0_req >= aud0_adr + aud0_length) begin
			aud0_wadr <= aud0_adr + (aud0_wadr + aud0_req - (aud0_adr + aud0_length));
		end
		state <= ST_AUD0_1;
	end
ST_AUD0_1:	state <= ST_AUD0_2;
ST_AUD0_2:	state <= ST_AUD0_3;
ST_AUD0_3:
	begin
		aud0_dat <= ram_data_o;
		state <= ST_IDLE;
	end

ST_AUD1:
	begin
		ram_addr <= aud1_wadr;
		aud1_wadr <= aud1_wadr + aud1_req;
		aud1_req <= 6'd0;
		if (aud1_wadr + aud1_req >= aud1_adr + aud1_length) begin
			aud1_wadr <= aud1_adr + (aud1_wadr + aud1_req - (aud1_adr + aud1_length));
		end
		state <= ST_AUD1_1;
	end
ST_AUD1_1:	state <= ST_AUD1_2;
ST_AUD1_2:	state <= ST_AUD1_3;
ST_AUD1_3:
	begin
		aud1_dat <= ram_data_o;
		state <= ST_IDLE;
	end

ST_AUD2:
	begin
		ram_addr <= aud2_wadr;
		aud2_wadr <= aud2_wadr + aud2_req;
		aud2_req <= 6'd0;
		if (aud2_wadr + aud2_req >= aud2_adr + aud2_length) begin
			aud2_wadr <= aud2_adr + (aud2_wadr + aud2_req - (aud2_adr + aud2_length));
		end
		state <= ST_AUD2_1;
	end
ST_AUD2_1:	state <= ST_AUD2_2;
ST_AUD2_2:	state <= ST_AUD2_3;
ST_AUD2_3:
	begin
		aud2_dat <= ram_data_o;
		state <= ST_IDLE;
	end

ST_AUD3:
	begin
		ram_addr <= aud3_wadr;
		aud3_wadr <= aud3_wadr + aud3_req;
		aud3_req <= 6'd0;
		if (aud3_wadr + aud3_req >= aud3_adr + aud3_length) begin
			aud3_wadr <= aud3_adr + (aud3_wadr + aud3_req - (aud3_adr + aud3_length));
		end
		state <= ST_AUD3_1;
	end
ST_AUD3_1:	state <= ST_AUD3_2;
ST_AUD3_2:	state <= ST_AUD3_3;
ST_AUD3_3:
	begin
		aud3_dat <= ram_data_o;
		state <= ST_IDLE;
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Pixel plot acceleration states
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_PLOT:
	begin
		bkcolor <= charbk_qo;
		tgtaddr <= {8'h00,cmdy1_qo} * {8'h00,bitmapWidth} + {bmpBase[19:12],cmdx1_qo};
		state <= charbk_qo[9] ? ST_PLOT_READ : ST_PLOT_WRITE;
	end
ST_PLOT_READ:
	begin
		ram_addr <= tgtaddr;
		state <= ST_PLOT_READ2;
	end
ST_PLOT_READ2:
	state <= ST_PLOT_READ3;
ST_PLOT_READ3:
	state <= ST_PLOT_WRITE;
ST_PLOT_WRITE:
	begin
		ram_we <= {2{`HIGH}};
		if (bkcolor[`A]) begin
			ram_data_i[`R] <= ram_data_o[`R] >> bkcolor[2:0];
			ram_data_i[`G] <= ram_data_o[`G] >> bkcolor[5:3];
			ram_data_i[`B] <= ram_data_o[`B] >> bkcolor[8:6];
		end
		else
			ram_data_i <= bkcolor;
		state <= ST_IDLE;
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Character draw acceleration states
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

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
ST_READ_CHAR_BITMAP:
	begin
		ram_addr <= charBmpBase + charcode * (pixym + 4'd1) + pixvc;
		state <= ST_READ_CHAR_BITMAP2;
	end
	// Two ram wait states
ST_READ_CHAR_BITMAP2:
	state <= ST_READ_CHAR_BITMAP3;
ST_READ_CHAR_BITMAP3:
	state <= ST_READ_CHAR_BITMAP_DAT;
ST_READ_CHAR_BITMAP_DAT:
	begin
		charbmp <= ram_data_o;
		state <= ST_CALC_INDEX;
	end
ST_CALC_INDEX:
	begin
		tgtindex <= {14'h00,pixvc} * {8'h00,bitmapWidth} + {14'h00,pixhc};
		state <= ST_WRITE_CHAR;
	end
ST_WRITE_CHAR:
	begin
		ram_addr <= tgtaddr + tgtindex;
		if (~bkcolor[`A]) begin
			ram_we <= {2{`HIGH}};
			ram_data_i <= charbmp[pixxm] ? fgcolor : bkcolor;
		end
		else begin
			if (charbmp[pixxm]) begin
				ram_we <= {2{`HIGH}};
				ram_data_i <= fgcolor;
			end
		end
		state <= ST_NEXT;
	end
ST_NEXT:
	begin
	    state <= ST_CALC_INDEX;
		ram_we <= {2{`LOW}};
		charbmp <= {charbmp[15:0],1'b0};
		pixhc <= pixhc + 4'd1;
		if (pixhc==pixxm) begin
		    state <= ST_READ_CHAR_BITMAP;
		    pixhc <= 4'd0;
		    pixvc <= pixvc + 4'd1;
		    if (pixvc==pixym) begin
		        state <= ST_IDLE;
		    end
		end
//		pixcnt <= pixcnt + 10'd1;
//		state <= pixcnt==10'd63 ? ST_IDLE :
//			pixcnt[2:0]==3'd7 ? ST_READ_CHAR_BITMAP :
//			ST_CALC_INDEX;
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_BLTDMA1:
	begin
		ram_we <= {2{`LOW}};
		bitcnt <= bltCtrl[0] ? 3'd7 : 3'd0;
		bitinc <= bltCtrl[0] ? 3'd1 : 3'd0;
		bltinc <= bltCtrl[8] ? 20'hFFFFF : 20'd1;
		loopcnt <= bltPipedepth + 5'd3;
		wrA <= 19'b1111111111111111000;
		bltAa <= 5'd0;
		srstA <= `FALSE;
		state <= ST_BLTDMA2;
	end
ST_BLTDMA2:
	begin
		ram_addr <= srcA_wadr;
		if (loopcnt > 5'd2) begin
			bitcnt <= bitcnt - bitinc;	// bitinc = 3'd0 unless bitmap
			if (bitcnt==3'd0)
				srcA_wadr <= srcA_wadr + bltinc;
			srcA_wcnt <= srcA_wcnt + 20'd1;
			srcA_dcnt <= srcA_dcnt + 20'd1;
			srcA_hcnt <= srcA_hcnt + 20'd1;
			if (srcA_wcnt==srcA_cnt) begin
                srcA_wadr <= srcA_badr;
                srcA_wcnt <= 20'd0;
                srcA_hcnt <= 20'd0;
				bitcnt <= bltCtrl[0] ? 3'd7 : 3'd0;
            end
			else if (srcA_hcnt==bltSrcWid) begin
				srcA_hcnt <= 20'd0;
				srcA_wadr <= srcA_wadr + srcA_mod + bltinc;
				bitcnt <= bltCtrl[0] ? 3'd7 : 3'd0;
			end
		end
		wrA <= {1'b0,wrA[18:1]};
		if (wrA[0])
			bltAa <= bltAa + 5'd1;
		blt_bmpA <= ram_data_o;
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
		bitcnt <= bltCtrl[2] ? 3'd7 : 3'd0;
		bitinc <= bltCtrl[2] ? 3'd1 : 3'd0;
		bltinc <= bltCtrl[9] ? 20'hFFFFF : 20'd1;
		loopcnt <= bltPipedepth + 5'd3;
		wrB <= 19'b1111111111111111000;
		bltBa <= 5'd0;
		srstB <= `FALSE;
		state <= ST_BLTDMA4;
	end
ST_BLTDMA4:
	begin
		ram_addr <= srcB_wadr;
		if (loopcnt > 5'd2) begin
			bitcnt <= bitcnt - bitinc;	// bitinc = 3'd0 unless bitmap
			if (bitcnt==3'd0)
				srcB_wadr <= srcB_wadr + bltinc;
			srcB_wcnt <= srcB_wcnt + 20'd1;
			srcB_dcnt <= srcB_dcnt + 20'd1;
			srcB_hcnt <= srcB_hcnt + 20'd1;
			if (srcB_wcnt==srcB_cnt) begin
                srcB_wadr <= srcB_badr;
                srcB_wcnt <= 20'd0;
                srcB_hcnt <= 20'd0;
                bitcnt <= bltCtrl[2] ? 3'd7 : 3'd0;
            end
			else if (srcB_hcnt==bltSrcWid) begin
				srcB_hcnt <= 20'd0;
				srcB_wadr <= srcB_wadr + srcB_mod + bltinc;
				bitcnt <= bltCtrl[2] ? 3'd7 : 3'd0;
			end
		end
		wrB <= {1'b0,wrB[18:1]};
		if (wrB[0])
			bltBa <= bltBa + 5'd1;
		blt_bmpB <= ram_data_o;
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
		bitcnt <= bltCtrl[4] ? 3'd7 : 3'd0;
		bitinc <= bltCtrl[4] ? 3'd1 : 3'd0;
		bltinc <= bltCtrl[10] ? 20'hFFFFF : 20'd1;
		loopcnt <= bltPipedepth + 5'd3;
		wrC <= 19'b1111111111111111000;
		bltCa <= 5'd0;
		srstC <= `FALSE;
		state <= ST_BLTDMA6;
	end
ST_BLTDMA6:
	begin
		ram_addr <= srcC_wadr;
		if (loopcnt > 5'd2) begin
			bitcnt <= bitcnt - bitinc;	// bitinc = 3'd0 unless bitmap
			if (bitcnt==3'd0)
				srcC_wadr <= srcC_wadr + bltinc;
			srcC_wcnt <= srcC_wcnt + 20'd1;
			srcC_dcnt <= srcC_dcnt + 20'd1;
			srcC_hcnt <= srcC_hcnt + 20'd1;
			if (srcC_wcnt==srcC_cnt) begin
                srcC_wadr <= srcC_badr;
                srcC_wcnt <= 20'd0;
                srcC_hcnt <= 20'd0;
                bitcnt <= bltCtrl[4] ? 3'd7 : 3'd0;
            end
			else if (srcC_hcnt==bltSrcWid) begin
				srcC_hcnt <= 20'd0;
				srcC_wadr <= srcC_wadr + srcC_mod + bltinc;
				bitcnt <= bltCtrl[4] ? 3'd7 : 3'd0;
			end
		end
		wrC <= {1'b0,wrC[18:1]};
		if (wrC[0])
			bltCa <= bltCa + 5'd1;
		blt_bmpC <= ram_data_o;
		loopcnt <= loopcnt - 5'd1;
		if (loopcnt==5'd0 || srcC_dcnt==dstD_cnt)
			state <= ST_BLTDMA7;
	end
	// Do channel D
ST_BLTDMA7:
	begin
		bitcnt <= bltCtrl[6] ? 3'd7 : 3'd0;
		bitinc <= bltCtrl[6] ? 3'd1 : 3'd0;
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
		ram_we <= {2{`HIGH}};
		ram_addr <= dstD_wadr;
		// If there's no source then a fill operation muct be taking place.
		if (bltCtrl[1]|bltCtrl[3]|bltCtrl[5]) begin
/*		if (dstD_ctrl[0])
			ram_data_i <= bltabc[bitcnt] ? 10'h1FF : 10'h000;
		else
*/			ram_data_i <= bltabc;
		end
		else
			ram_data_i <= bltD_dat;	// fill color
		bitcnt <= bitcnt - bitinc;	// bitinc = 3'd0 unless bitmap
		if (bitcnt==3'd0)
			dstD_wadr <= dstD_wadr + bltinc;
		dstD_wcnt <= dstD_wcnt + 20'd1;
		dstD_hcnt <= dstD_hcnt + 20'd1;
		if (dstD_hcnt==bltDstWid) begin
			dstD_hcnt <= 20'd0;
			dstD_wadr <= dstD_wadr + dstD_mod + bltinc;
			bitcnt <= bltCtrl[6] ? 3'd7 : 3'd0;
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
		else if ((ctrl[11:8] != 4'h1) &&
			(ctrl[11:8] != 4'h0) &&
			(ctrl[11:8] != 4'hF))
			state <= DL_GETPIXEL;
		else
			state <= DL_SETPIXEL;
	end
DL_GETPIXEL:
	begin
		ram_addr <= ma;
		state <= DL_GETPIXEL2;
	end
DL_GETPIXEL2:
	state <= DL_GETPIXEL3;
DL_GETPIXEL3:
	state <= DL_SETPIXEL;
DL_SETPIXEL:
	begin
		ram_addr <= ma;
		ram_we <= {2{`HIGH}};
		case(ctrl[11:8])
		4'd0:	ram_data_i <= 16'h0000;
		4'd1:	ram_data_i <= bkcolor;
		4'd4:	ram_data_i <= bkcolor & ram_data_o;
		4'd5:	ram_data_i <= bkcolor | ram_data_o;
		4'd6:	ram_data_i <= bkcolor ^ ram_data_o;
		4'd7:	ram_data_i <= bkcolor & ~ram_data_o;
		4'hF:	ram_data_i <= 16'h7FFF;
		endcase
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
		state <= ST_COPPER_IFETCH4;
	end
ST_COPPER_IFETCH4:
	begin
		ram_addr <= ram_addr + 20'd1;
		copper_ir[15:0] <= ram_data_o;
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
		ram_addr <= ram_addr + 20'd1;
		copper_ir[47:32] <= ram_data_o;
		state <= ST_COPPER_IFETCH7;
	end
ST_COPPER_IFETCH7:
	begin
		copper_pc <= copper_pc + 20'd4;
		ram_addr <= ram_addr + 20'd1;
		copper_ir[63:48] <= ram_data_o;
		state <= ST_COPPER_EXECUTE;
	end
ST_COPPER_EXECUTE:
	begin
		case(copper_ir[63:62])
		2'd00:	// WAIT
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
		2'd01:	// MOVE
			begin
				reg_copper <= `TRUE;
				reg_we <= {2{`HIGH}};
				reg_adr <= copper_ir[42:32];
				reg_dat <= copper_ir[15:0];
				state <= ST_IDLE;
			end
		2'd10:	// SKIP
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
		2'd11:	// JUMP
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
endmodule

