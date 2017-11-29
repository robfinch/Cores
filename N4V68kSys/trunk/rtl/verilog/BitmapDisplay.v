// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// BitmapDisplay.v
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

module BitmapDisplay(
	rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o,
	cs_i, cs_ram_i,
	clk, eol, eof, blank, border, rgb
);
// Wishbone slave port
input rst_i;
input clk_i;
input cyc_i;
input stb_i;
output reg ack_o;
input we_i;
input sel_i;
input [23:0] adr_i;
input [15:0] dat_i;
output reg [15:0] dat_o;

input cs_i;							// circuit select
input cs_ram_i;

// Video port
input clk;
input eol;
input eof;
input blank;
input border;
output reg [8:0] rgb;

parameter ST_IDLE = 6'd0;
parameter ST_RW = 6'd1;
parameter ST_CHAR_INIT = 6'd2;
parameter ST_READ_CHAR_BITMAP = 6'd3;
parameter ST_READ_CHAR_BITMAP2 = 6'd4;
parameter ST_READ_CHAR_BITMAP3 = 6'd5;
parameter ST_READ_CHAR_BITMAP_DAT = 6'd6;
parameter ST_CALC_INDEX = 6'd7;
parameter ST_WRITE_CHAR = 6'd8;
parameter ST_NEXT = 6'd9;
parameter ST_BLT_INIT = 6'd10;
parameter ST_READ_BLT_BITMAP = 6'd11;
parameter ST_READ_BLT_BITMAP2 = 6'd12;
parameter ST_READ_BLT_BITMAP3 = 6'd13;
parameter ST_READ_BLT_BITMAP_DAT = 6'd14;
parameter ST_CALC_BLT_INDEX = 6'd15;
parameter ST_READ_BLT_PIX = 6'd16;
parameter ST_READ_BLT_PIX2 = 6'd17;
parameter ST_READ_BLT_PIX3= 6'd18;
parameter ST_WRITE_BLT_PIX = 6'd19;
parameter ST_BLT_NEXT = 6'd20;
parameter ST_PLOT = 6'd21;
parameter ST_PLOT_READ = 6'd22;
parameter ST_PLOT_READ2 = 6'd23;
parameter ST_PLOT_READ3 = 6'd24;
parameter ST_PLOT_WRITE = 6'd25;
parameter ST_BLTDMA = 6'd30;
parameter ST_BLTDMA1 = 6'd31;
parameter ST_BLTDMA2 = 6'd32;
parameter ST_BLTDMA3 = 6'd33;
parameter ST_BLTDMA4 = 6'd34;
parameter ST_BLTDMA5 = 6'd35;
parameter ST_BLTDMA6 = 6'd36;
parameter ST_BLTDMA7 = 6'd37;
parameter ST_BLTDMA8 = 6'd38;
parameter DL_INIT = 6'd40;
parameter DL_PRECALC = 6'd41;
parameter DL_GETPIXEL = 6'd42;
parameter DL_GETPIXEL2 = 6'd43;
parameter DL_GETPIXEL3 = 6'd44;
parameter DL_SETPIXEL = 6'd45;
parameter DL_TEST = 6'd46;
parameter ST_CMD = 6'd47;

integer n;
reg [5:0] state = ST_IDLE;
// ctrl
// -b--- rrrr ---- cccc
//  |      |         +-- grpahics command
//  |      +------------ raster op
// +-------------------- busy indicator
reg [15:0] ctrl;
reg [19:0] bmpBase = 20'h00000;		// base address of bitmap
reg [19:0] charBmpBase = 20'hB8000;	// base address of character bitmaps
reg [11:0] hstart = 12'hEB3;		// -333
reg [11:0] vstart = 12'hFB0;		// -80
reg [11:0] hpos;
reg [11:0] vpos;
reg [11:0] bitmapWidth = 12'd640;
reg [8:0] borderColor;
wire [9:0] rgb_i;					// internal rgb output from ram

reg [91:0] cmdq_in;
wire [91:0] cmdq_out;

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
reg [3:0] cx, cy;
reg [9:0] cursor_color;
reg [3:0] flashrate;

reg [3:0] cursor_sv;				// cursor size
reg [3:0] cursor_sh;
reg [9:0] cursor_bmp [0:15];
reg [19:0] rdndx;					// video read index
reg [19:0] ram_addr;
reg [9:0] ram_data_i;
wire [9:0] ram_data_o;
reg ram_we;

reg [ 9:0] pixcnt;
reg [3:0] pixhc,pixvc;
reg [2:0] bitcnt, bitinc;

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
reg [19:0] srcA_wadr;				// working address
reg [19:0] srcA_wcnt;				// working count
reg [19:0] srcA_hcnt;

reg [19:0] srcB_badr;
reg [19:0] srcB_mod;
reg [19:0] srcB_wadr;				// working address
reg [19:0] srcB_wcnt;				// working count
reg [19:0] srcB_hcnt;

reg [19:0] srcC_badr;
reg [19:0] srcC_mod;
reg [19:0] srcC_wadr;				// working address
reg [19:0] srcC_wcnt;				// working count
reg [19:0] srcC_hcnt;

reg [19:0] dstD_badr;
reg [19:0] dstD_mod;
reg [19:0] dstD_wadr;				// working address
reg [19:0] dstD_wcnt;				// working count
reg [19:0] dstD_hcnt;

reg [15:0] blt_op;

// May need to set the pipeline depth to zero if copying neighbouring pixels
// during a blit. So the app is allowed to control the pipeline depth. Depth
// should not be set >28.
reg [4:0] bltPipedepth = 5'd15;
reg [19:0] bltinc;
reg [4:0] bltAa,bltBa,bltCa;
reg [18:0] wrA, wrB, wrC;
reg [9:0] blt_bmpA;
reg [9:0] blt_bmpB;
reg [9:0] blt_bmpC;
reg srst;
wire [9:0] bltA_out, bltB_out, bltC_out;
wire [9:0] bltA_in = bltCtrl[0] ? (blt_bmpA[bitcnt] ? 10'h1FF : 10'h000) : blt_bmpA;
wire [9:0] bltB_in = bltCtrl[2] ? (blt_bmpB[bitcnt] ? 10'h1FF : 10'h000) : blt_bmpB;
wire [9:0] bltC_in = bltCtrl[4] ? (blt_bmpC[bitcnt] ? 10'h1FF : 10'h000) : blt_bmpC;
vtdl #(.WID(10), .DEP(32)) bltA (.clk(clk_i), .ce(wrA[0]), .a(bltAa), .d(bltA_in), .q(bltA_out));
vtdl #(.WID(10), .DEP(32)) bltB (.clk(clk_i), .ce(wrB[0]), .a(bltBa), .d(bltB_in), .q(bltB_out));
vtdl #(.WID(10), .DEP(32)) bltC (.clk(clk_i), .ce(wrC[0]), .a(bltCa), .d(bltC_in), .q(bltC_out));

reg [9:0] bltab;
reg [9:0] bltabc;
always @*
	case(blt_op[3:0])
	4'h0:	bltab = 10'h000;
	4'h1:	bltab = bltA_out;
	4'h2:	bltab = bltB_out;
	4'h8:	bltab = bltA_out & bltB_out;
	4'h9:	bltab = bltA_out | bltB_out;
	4'hA:	bltab = bltA_out ^ bltB_out;
	4'hB:	bltab = bltA_out & ~bltB_out;
	4'hF:	bltab = 10'h1FF;
	endcase
always @*
	case(blt_op[7:4])
	4'h0:	bltabc = 10'h000;
	4'h1:	bltabc = bltab;
	4'h2:	bltabc = bltC_out;
	4'h8:	bltabc = bltab & bltC_out;
	4'h9:	bltabc = bltab | bltC_out;
	4'hA:	bltabc = bltab ^ bltC_out;
	4'hB:	bltabc = bltab & ~bltC_out;
	4'hF:	bltabc = 10'h1FF;
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
reg [9:0] bltcolor;					// blt color as read
reg [4:0] loopcnt;

reg [ 8:0] charcode;                // character code being processed
reg [ 9:0] charbmp;					// hold character bitmap scanline
reg [8:0] fgcolor;					// character colors
reg [9:0] bkcolor;					// top bit indicates overlay mode
reg [3:0] pixxm, pixym;             // maximum # pixels for char


chipram chipram1
(
	.clka(clk_i),
	.ena(1'b1),
	.wea(ram_we),
	.addra(ram_addr),
	.dina(ram_data_i),
	.douta(ram_data_o),
	.clkb(clk),
	.enb(1'b1),
	.web(1'b0),
	.addrb(rdndx),
	.dinb(9'h000),
	.doutb(rgb_i)
);

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
	if (eof)
		flashcnt <= flashcnt + 6'd1;

always @(posedge clk)
	if (hpos == cursor_h)
		cx <= 0;
	else
		cx <= cx + 4'd1;
always @(posedge clk)
	if (vpos == cursor_v)
		cy <= 0;
	else if (eol)
		cy <= cy + 4'd1;

always @(posedge clk)
	if ((flashcnt[5:2] & flashrate[3:0])!=4'b000 || flashrate[4]) begin
		if ((vpos >= cursor_v && vpos <= cursor_v + cursor_sv) &&
			(hpos >= cursor_h && hpos <= cursor_h + cursor_sh))
			cursor <= cursor_bmp[cy][cx];
		else
			cursor <= 1'b0;
	end
	else
		cursor <= 1'b0;

always @(posedge clk)
	rdndx <= {8'h00,vpos} * {8'h00,bitmapWidth} + {bmpBase[19:12],hpos};

always @(posedge clk)
	rgb <= 	blank ? 9'h000 :
		   	border ? borderColor :
       		cursor ? (
				cursor_color[9] ? rgb_i[8:0] ^ 9'h1FF : cursor_color) :
			rgb_i[8:0];

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


vtdl #(.WID(92), .DEP(32)) char_q (.clk(clk_i), .ce(cs_cmdq), .a(cmdq_ndx), .d(cmdq_in), .q(cmdq_out));

wire [8:0] charcode_qo = cmdq_out[8:0];
wire [8:0] charfg_qo = cmdq_out[17:9];
wire [9:0] charbk_qo = cmdq_out[27:18];
wire [11:0] cmdx1_qo = cmdq_out[39:28];
wire [11:0] cmdy1_qo = cmdq_out[51:40];
wire [3:0] charxm_qo = cmdq_out[55:52];
wire [3:0] charym_qo = cmdq_out[59:56];
wire [7:0] cmd_qo = cmdq_out[67:60];
wire [11:0] cmdx2_qo = cmdq_out[79:68];
wire [11:0] cmdy2_qo = cmdq_out[91:80];

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

always @(posedge clk_i)
	rwsr <= cs_reg;
always @(posedge clk_i)
	rdy <= rwsr & cs_reg;
always @(posedge clk_i)
	ack_o <= (cs_reg ? rdy : cs_ram ? ack : 1'b0) & ~ack_o;

// Widen the eof pulse so it can be seen by clk_i
reg [11:0] vrst;
always @(posedge clk)
	if (eof)
		vrst <= 12'hFFF;
	else
		vrst <= {vrst[10:0],1'b0};
	
always @(posedge clk_i)
begin

if (cs_reg) begin
	if (we_i) begin
		casex(adr_i[10:1])
		10'b0xxxxxx000:	begin
						blt_addr[adr_i[9:4]][19:4] <= dat_i;
						blt_addr[adr_i[9:4]][3:0] <= 4'h0;
						end
		10'b0xxxxxx001:	blt_pix[adr_i[9:4]] <= dat_i[9:0];
		10'b0xxxxxx010:	blt_hmax[adr_i[9:4]] <= dat_i[9:0];
		10'b0xxxxxx011:	blt_x[adr_i[9:4]] <= dat_i[9:0];
		10'b0xxxxxx100:	blt_y[adr_i[9:4]] <= dat_i[9:0];
		10'b0xxxxxx101:	blt_pc[adr_i[9:4]] <= dat_i[9:0];
		10'b0xxxxxx110:	blt_hctr[adr_i[9:4]] <= dat_i[9:0];
		10'b0xxxxxx111:	blt_vctr[adr_i[9:4]] <= dat_i[9:0];
		10'b1000000000:	begin
							bmpBase[19:12] <= dat_i[7:0];
							bmpBase[11:0] <= 12'h000;
						end
		10'b1000000001:	begin
							charBmpBase[19:12] <= dat_i[7:0];
							charBmpBase[11:0] <= 12'h000;
						end
		// Clear dirty bits
		10'b1000000100:	blt_dirty[15:0] <= blt_dirty[15:0] & ~dat_i;
		10'b1000000101: blt_dirty[31:16] <= blt_dirty[31:16] & ~dat_i;
		10'b1000000110:	blt_dirty[47:32] <= blt_dirty[47:32] & ~dat_i;
		10'b1000000111:	blt_dirty[63:48] <= blt_dirty[63:48] & ~dat_i;
		// Set dirty bits
		10'b1000001000:	blt_dirty[15:0] <= blt_dirty[15:0] | dat_i;
		10'b1000001001: blt_dirty[31:16] <= blt_dirty[31:16] | dat_i;
		10'b1000001010:	blt_dirty[47:32] <= blt_dirty[47:32] | dat_i;
		10'b1000001011:	blt_dirty[63:48] <= blt_dirty[63:48] | dat_i;
		10'b100_0010_000:	cmdq_in[8:0] <= dat_i[8:0];		// char code
		10'b100_0010_001:	cmdq_in[17:9] <= dat_i[8:0];	// fgcolor
		10'b100_0010_010:	cmdq_in[27:18] <= dat_i[9:0];	// bkcolor
		10'b100_0010_011:	cmdq_in[39:28] <= dat_i[11:0];	// xpos1
		10'b100_0010_100:	cmdq_in[51:40] <= dat_i[11:0];	// ypos1
		10'b100_0010_101:   cmdq_in[59:52] <= {dat_i[11:8],dat_i[3:0]};	// fntsz
		10'b100_0010_110: cmdq_ndx <= dat_i[4:0];
		10'b100_0010_111:	cmdq_in[67:60] <= dat_i[7:0];	// cmd
		10'b100_0011_000:	cmdq_in[79:68] <= dat_i[11:0];	// xpos2
		10'b100_0011_001:	cmdq_in[91:80] <= dat_i[11:0];	// ypos2
		10'b100_0100_000:	cursor_h <= dat_i[11:0];
		10'b100_0100_001:	cursor_v <= dat_i[11:0];
		10'b100_0100_010:	begin
								cursor_sh <= dat_i[3:0];
								cursor_sv <= dat_i[11:8];
							end
		10'b100_0100_011:	begin
								cursor_color <= dat_i[9:0];
								flashrate <= dat_i[15:11];
							end
		10'b100_011x_xxx:	cursor_bmp[adr_i[4:1]] <= dat_i[9:0];
	
		10'b100_1000_000:	srcA_badr[19:16] <= dat_i[3:0];
		10'b100_1000_001:	srcA_badr[15: 0] <= dat_i;
		10'b100_1000_010:	srcA_mod[19:16] <= dat_i[3:0];
		10'b100_1000_011:	srcA_mod[15: 0] <= dat_i;
		10'b100_1000_100:	srcB_badr[19:16] <= dat_i[3:0];
		10'b100_1000_101:	srcB_badr[15: 0] <= dat_i;
		10'b100_1000_110:	srcB_mod[19:16] <= dat_i[3:0];
		10'b100_1000_111:	srcB_mod[15: 0] <= dat_i;
		10'b100_1001_000:	srcC_badr[19:16] <= dat_i[3:0];
		10'b100_1001_001:	srcC_badr[15: 0] <= dat_i;
		10'b100_1001_010:	srcC_mod[19:16] <= dat_i[3:0];
		10'b100_1001_011:	srcC_mod[15: 0] <= dat_i;
		10'b100_1001_100:	dstD_badr[19:16] <= dat_i[3:0];
		10'b100_1001_101:	dstD_badr[15: 0] <= dat_i;
		10'b100_1001_110:	dstD_mod[19:16] <= dat_i[3:0];
		10'b100_1001_111:	dstD_mod[15: 0] <= dat_i;
		10'b100_1010_000:	bltSrcWid[19:16] <= dat_i[3:0];
		10'b100_1010_001:	bltSrcWid[15:0] <= dat_i;
		10'b100_1010_010:	bltDstWid[19:16] <= dat_i[3:0];
		10'b100_1010_011:	bltDstWid[15:0] <= dat_i;
		10'b100_1010_100:	bltCount[19:16] <= dat_i[3:0];
		10'b100_1010_101:	bltCount[15:0] <= dat_i;
		10'b100_1010_110:	bltCtrl <= dat_i;
		10'b100_1010_111:	blt_op <= dat_i;
		10'b100_1011_000:   bltPipedepth <= dat_i[4:0];
		default:	;	// do nothing
		endcase
	end
	else begin
		case(adr_i[10:1])
		10'b1000010110:	dat_o <= {11'h00,cmdq_ndx};
		10'b1001010110:	dat_o <= bltCtrl;
		default:	dat_o <= srdo;
		endcase
	end
end
if (cs_cmdq)
	cmdq_ndx <= cmdq_ndx + 5'd1;

case(state)
ST_IDLE:
	begin
		ram_we <= `LOW;
		ack <= `LOW;
		if (cs_ram) begin
			ram_data_i <= dat_i[9:0];
			ram_addr <= adr_i[20:1];
			ram_we <= we_i;
			state <= ST_RW;
		end

		// busy with a graphics command ?
		else if (ctrl[14]) begin
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
			srcA_wadr <= srcA_badr;
			srcB_wadr <= srcB_badr;
			srcC_wadr <= srcC_badr;
			dstD_wadr <= dstD_badr;
			srcA_wcnt <= 20'd0;
			srcB_wcnt <= 20'd0;
			srcC_wcnt <= 20'd0;
			dstD_wcnt <= 20'd0;
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

ST_RW:
	begin
		ack <= `HIGH;
		dat_o <= {6'd0,ram_data_o};
		if (~cs_ram) begin
		    ram_we <= `LOW;
			ack <= `LOW;
			state <= ST_IDLE;
		end
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
		ram_we <= `HIGH;
		if (bkcolor[9]) begin
			ram_data_i[2:0] <= ram_data_o[2:0] >> bkcolor[1:0];
			ram_data_i[5:3] <= ram_data_o[5:3] >> bkcolor[3:2];
			ram_data_i[8:6] <= ram_data_o[8:6] >> bkcolor[5:4];
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
		if (~bkcolor[9]) begin
			ram_we <= `HIGH;
			ram_data_i <= charbmp[pixxm] ? fgcolor : bkcolor;
		end
		else begin
			if (charbmp[pixxm]) begin
				ram_we <= `HIGH;
				ram_data_i <= fgcolor;
			end
		end
		state <= ST_NEXT;
	end
ST_NEXT:
	begin
	    state <= ST_CALC_INDEX;
		ram_we <= `LOW;
		charbmp <= {charbmp[9:0],1'b0};
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
		ram_we <= `LOW;
		bitcnt <= bltCtrl[0] ? 3'd7 : 3'd0;
		bitinc <= bltCtrl[0] ? 3'd1 : 3'd0;
		bltinc <= bltCtrl[8] ? 20'hFFFFF : 20'd1;
		loopcnt <= bltPipedepth + 5'd3;
		wrA <= 19'b1111111111111111000;
		bltAa <= 5'd0;
		state <= ST_BLTDMA2;
	end
ST_BLTDMA2:
	begin
		if (loopcnt > 5'd2) begin
			ram_addr <= srcA_wadr;
			bitcnt <= bitcnt - bitinc;	// bitinc = 3'd0 unless bitmap
			if (bitcnt==3'd0)
				srcA_wadr <= srcA_wadr + bltinc;
			srcA_wcnt <= srcA_wcnt + 20'd1;
			srcA_hcnt <= srcA_hcnt + 20'd1;
			if (srcA_hcnt==bltSrcWid) begin
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
		if (loopcnt==5'd0 || srcA_wcnt==bltCount) begin
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
	    srst <= `FALSE;
		ram_we <= `LOW;
		bitcnt <= bltCtrl[2] ? 3'd7 : 3'd0;
		bitinc <= bltCtrl[2] ? 3'd1 : 3'd0;
		bltinc <= bltCtrl[9] ? 20'hFFFFF : 20'd1;
		loopcnt <= bltPipedepth + 5'd3;
		wrB <= 19'b1111111111111111000;
		bltBa <= 5'd0;
		state <= ST_BLTDMA4;
	end
ST_BLTDMA4:
	begin
		if (loopcnt > 5'd2) begin
			ram_addr <= srcB_wadr;
			bitcnt <= bitcnt - bitinc;	// bitinc = 3'd0 unless bitmap
			if (bitcnt==3'd0)
				srcB_wadr <= srcB_wadr + bltinc;
			srcB_wcnt <= srcB_wcnt + 20'd1;
			srcB_hcnt <= srcB_hcnt + 20'd1;
			if (srcB_hcnt==bltSrcWid) begin
				srcB_hcnt <= 20'd0;
				srcB_wadr <= srcB_wadr + srcB_mod + bltinc;
				bitcnt <= bltCtrl[2] ? 3'd7 : 3'd0;
			end
			wrB <= {1'b0,wrB[17:1]};
		end
		if (wrB[0])
			bltBa <= bltBa + 5'd1;
		blt_bmpB <= ram_data_o;
		loopcnt <= loopcnt - 5'd1;
		if (loopcnt==5'd0 || srcB_wcnt==bltCount) begin
			if (bltCtrl[5])
				state <= ST_BLTDMA5;
			else
				state <= ST_BLTDMA7;
		end
	end
	// Do channel C
ST_BLTDMA5:
	begin
	    srst <= `FALSE;
		ram_we <= `LOW;
		bitcnt <= bltCtrl[4] ? 3'd7 : 3'd0;
		bitinc <= bltCtrl[4] ? 3'd1 : 3'd0;
		bltinc <= bltCtrl[10] ? 20'hFFFFF : 20'd1;
		loopcnt <= bltPipedepth + 5'd3;
		wrC <= 19'b1111111111111111000;
		bltCa <= 5'd0;
		state <= ST_BLTDMA6;
	end
ST_BLTDMA6:
	begin
		if (loopcnt > 5'd2) begin
			ram_addr <= srcC_wadr;
			bitcnt <= bitcnt - bitinc;	// bitinc = 3'd0 unless bitmap
			if (bitcnt==3'd0)
				srcC_wadr <= srcC_wadr + bltinc;
			srcC_wcnt <= srcC_wcnt + 20'd1;
			srcC_hcnt <= srcC_hcnt + 20'd1;
			if (srcC_hcnt==bltSrcWid) begin
				srcC_hcnt <= 20'd0;
				srcC_wadr <= srcC_wadr + srcC_mod + bltinc;
				bitcnt <= bltCtrl[4] ? 3'd7 : 3'd0;
			end
			wrC <= {1'b0,wrC[17:1]};
		end
		if (wrC[0])
			bltCa <= bltCa + 4'd1;
		blt_bmpC <= ram_data_o;
		loopcnt <= loopcnt - 5'd1;
		if (loopcnt==5'd0 || srcC_wcnt==bltCount)
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
		state <= ST_BLTDMA8;
	end
ST_BLTDMA8:
	begin
		ram_we <= `HIGH;
		ram_addr <= dstD_wadr;
		// If there's no source then a fill operation muct be taking place.
		if (bltCtrl[1]|bltCtrl[3]|bltCtrl[5]) begin
/*		if (dstD_ctrl[0])
			ram_data_i <= bltabc[bitcnt] ? 10'h1FF : 10'h000;
		else
*/			ram_data_i <= bltabc;
		end
		else
			ram_data_i <= cmdq_in[27:18]; 	// fill color
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
		if (dstD_wcnt==bltCount) begin
			state <= ST_IDLE;
			bltCtrl[14] <= 1'b0;
			bltCtrl[13] <= 1'b1;
		end
		else if (loopcnt==5'd0) begin
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
		state <= ram_data_o[9] ? ST_READ_BLT_PIX : ST_WRITE_BLT_PIX;
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
		if (bltcolor[9]) begin
			ram_data_i[2:0] <= ram_data_o[2:0] >> bltcolor[1:0];
			ram_data_i[5:3] <= ram_data_o[5:3] >> bltcolor[3:2];
			ram_data_i[8:6] <= ram_data_o[8:6] >> bltcolor[5:4];
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
		bkcolor <= cmdq_out[27:18];
		x0 <= cmdq_out[39:28];
		y0 <= cmdq_out[51:40];
		x1 <= cmdq_out[79:68];
		y1 <= cmdq_out[91:80];
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
		ram_we <= `HIGH;
		case(ctrl[11:8])
		4'd0:	ram_data_i <= 10'h000;
		4'd1:	ram_data_i <= bkcolor;
		4'd4:	ram_data_i <= bkcolor & ram_data_o;
		4'd5:	ram_data_i <= bkcolor | ram_data_o;
		4'd6:	ram_data_i <= bkcolor ^ ram_data_o;
		4'd7:	ram_data_i <= bkcolor & ~ram_data_o;
		4'hF:	ram_data_i <= 10'h1FF;
		endcase
		loopcnt <= loopcnt - 5'd1;
		if (gcx==x1 && gcy==y1) begin
			state <= ST_IDLE;
			ctrl[14] <= 1'b0;
		end
		else
			state <= DL_TEST;
	end
DL_TEST:
	begin
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


default:
	state <= ST_IDLE;
endcase
end
endmodule

