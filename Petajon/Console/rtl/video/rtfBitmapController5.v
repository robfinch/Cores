// ============================================================================
// rtfBitmapController5
//  Bitmap Controller (Frame Buffer Display)
//  - Displays a bitmap from memory.
//
//
//        __
//   \\__/ o\    (C) 2008-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
//
//  The default base screen address is:
//		$0200000 - the third meg of RAM
//
//
//	Verilog 1995
//
// ============================================================================

//`define USE_CLOCK_GATE	1'b1
`define INTERNAL_SYNC_GEN	1'b1

`define ABITS	31:0
`define HIGH	1'b1
`define LOW		1'b0
`define TRUE	1'b1
`define FALSE	1'b0

module rtfBitmapController5(
	rst_i, irq_o,
	s_clk_i, s_cs_i, s_cyc_i, s_stb_i, s_ack_o, s_we_i, s_sel_i, s_adr_i, s_dat_i, s_dat_o,
	m_clk_i, m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o,
	dot_clk_i, zrgb_o, xonoff_i
`ifdef INTERNAL_SYNC_GEN
	, hsync_o, vsync_o, blank_o, border_o, hctr_o, vctr_o, fctr_o, vblank_o
`else
	, hsync_i, vsync_i, blank_i
`endif
);
parameter MDW = 128;		// Bus master data width
parameter MAP = 12'd0;
parameter BM_BASE_ADDR1 = 32'h0020_0000;
parameter BM_BASE_ADDR2 = 32'h0028_0000;
parameter REG_CTRL = 9'd0;
parameter REG_REFDELAY = 9'd1;
parameter REG_PAGE1ADDR = 9'd2;
parameter REG_PAGE2ADDR = 9'd3;
parameter REG_PXYZ = 9'd4;
parameter REG_PCOLCMD = 9'd5;
parameter REG_TOTAL = 9'd8;
parameter REG_SYNC_ONOFF = 9'd9;
parameter REG_BLANK_ONOFF = 9'd10;
parameter REG_BORDER_ONOFF = 9'd11;
parameter REG_RASTCMP = 9'd12;
parameter REG_BMPSIZE = 9'd13;
parameter REG_OOB_COLOR = 9'd14;
parameter REG_WINDOW = 9'd15;

parameter BPP4 = 3'd0;
parameter BPP8 = 3'd1;
parameter BPP12 = 3'd2;
parameter BPP16 = 3'd3;
parameter BPP20 = 3'd4;
parameter BPP32 = 3'd7;

parameter OPBLACK = 4'd0;
parameter OPCOPY = 4'd1;
parameter OPINV = 4'd2;
parameter OPAND = 4'd4;
parameter OPOR = 4'd5;
parameter OPXOR = 4'd6;
parameter OPANDN = 4'd7;
parameter OPNAND = 4'd8;
parameter OPNOR = 4'd9;
parameter OPXNOR = 4'd10;
parameter OPORN = 4'd11;
parameter OPWHITE = 4'd15;

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


// SYSCON
input rst_i;				// system reset
output irq_o;

// Peripheral IO slave port
input s_clk_i;
input s_cs_i;
input s_cyc_i;
input s_stb_i;
output s_ack_o;
input s_we_i;
input [7:0] s_sel_i;
input [11:0] s_adr_i;
input [63:0] s_dat_i;
output [63:0] s_dat_o;
reg [63:0] s_dat_o;

// Video Memory Master Port
// Used to read memory via burst access
input m_clk_i;				// system bus interface clock
output m_cyc_o;			// video burst request
output m_stb_o;
output reg m_we_o;
output [MDW/8-1:0] m_sel_o;
input  m_ack_i;			// vid_acknowledge from memory
output [`ABITS] m_adr_o;	// address for memory access
input  [MDW-1:0] m_dat_i;	// memory data input
output reg [MDW-1:0] m_dat_o;

// Video
input dot_clk_i;		// Video clock 80 MHz
`ifdef INTERNAL_SYNC_GEN
output hsync_o;
output vsync_o;
output blank_o;
output vblank_o;
output border_o;
output [11:0] hctr_o;
output [11:0] vctr_o;
output [5:0] fctr_o;
`else
input hsync_i;			// start/end of scan line
input vsync_i;			// start/end of frame
input blank_i;			// blank the output
`endif
output [31:0] zrgb_o;		// 24-bit RGB output + z-order
reg [31:0] zrgb_o;

input xonoff_i;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// IO registers
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg irq_o;
reg m_cyc_o;
reg [31:0] m_adr_o;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire vclk;
reg cs;
reg we;
reg [7:0] sel;
reg [11:0] adri;
reg [63:0] dat;

always @(posedge s_clk_i)
	cs <= s_cyc_i & s_stb_i & s_cs_i;
always @(posedge s_clk_i)
	we <= s_we_i;
always @(posedge s_clk_i)
	sel <= s_sel_i;
always @(posedge s_clk_i)
	adri <= s_adr_i;
always @(posedge s_clk_i)
	dat <= s_dat_i;

ack_gen #(
	.READ_STAGES(2),
	.WRITE_STAGES(0),
	.REGISTER_OUTPUT(1)
) uag1
(
	.clk_i(s_clk_i),
	.ce_i(1'b1),
	.i(cs),
	.we_i(s_cyc_i & s_stb_i & s_cs_i & s_we_i),
	.o(s_ack_o)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
integer n;
reg [11:0] rastcmp;
reg [`ABITS] bm_base_addr1,bm_base_addr2;
reg [2:0] color_depth;
wire [7:0] fifo_cnt;
reg onoff;
reg [2:0] hres,vres;
reg greyscale;
reg page;
reg pals;				// palette select
reg [15:0] hrefdelay;
reg [15:0] vrefdelay;
reg [15:0] windowLeft;
reg [15:0] windowTop;
reg [11:0] windowWidth,windowHeight;
reg [11:0] map;     // memory access period
reg [11:0] mapctr;
reg [15:0] bmpWidth;		// scan line increment (pixels)
reg [15:0] bmpHeight;
reg [`ABITS] baseAddr;	// base address register
wire [MDW-1:0] rgbo1, rgbo1e, rgbo1o, rgbo1m;
reg [15:0] pixelRow;
reg [15:0] pixelCol;
wire [31:0] pal_wo;
wire [31:0] pal_o;
reg [15:0] px;
reg [15:0] py;
reg [7:0] pz;
reg [1:0] pcmd,pcmd_o;
reg [3:0] raster_op;
reg [31:0] oob_color;
reg [31:0] color;
reg [31:0] color_o;
reg rstcmd,rstcmd1;
reg [11:0] hTotal = phTotal;
reg [11:0] vTotal = pvTotal;
reg [11:0] hSyncOn = phSyncOn, hSyncOff = phSyncOff;
reg [11:0] vSyncOn = pvSyncOn, vSyncOff = pvSyncOff;
reg [11:0] hBlankOn = phBlankOn, hBlankOff = phBlankOff;
reg [11:0] vBlankOn = pvBlankOn, vBlankOff = pvBlankOff;
reg [11:0] hBorderOn = phBorderOn, hBorderOff = phBorderOff;
reg [11:0] vBorderOn = pvBorderOn, vBorderOff = pvBorderOff;
reg sgLock;
wire pe_hsync, pe_hsync2;
wire pe_vsync;

`ifdef INTERNAL_SYNC_GEN
wire hsync_i, vsync_i, blank_i;

VGASyncGen usg1
(
	.rst(rst_i),
	.clk(vclk),
	.eol(),
	.eof(),
	.hSync(hsync_o),
	.vSync(vsync_o),
	.hCtr(hctr_o),
	.vCtr(vctr_o),
  .blank(blank_o),
  .vblank(vblank),
  .vbl_int(),
  .border(border_o),
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
assign hsync_i = hsync_o;
assign vsync_i = vsync_o;
assign blank_i = blank_o;
assign vblank_o = vblank;
`endif

edge_det edcs1
(
	.rst(rst_i),
	.clk(s_clk_i),
	.ce(1'b1),
	.i(cs),
	.pe(cs_edge),
	.ne(),
	.ee()
);

// Frame counter
//
VT163 #(6) ub1
(
	.clk(vclk),
	.clr_n(!rst_i),
	.ent(pe_vsync),
	.enp(1'b1),
	.ld_n(1'b1),
	.d(6'd0),
	.q(fctr_o),
	.rco()
);

reg rst_irq;
always @(posedge vclk)
if (rst_i)
	irq_o <= `LOW;
else begin
	if (hctr_o==12'd02 && rastcmp==vctr_o)
		irq_o <= `HIGH;
	else if (rst_irq)
		irq_o <= `LOW;
end

always @(page or bm_base_addr1 or bm_base_addr2)
	baseAddr = page ? bm_base_addr2 : bm_base_addr1;

// Color palette RAM for 8bpp modes
syncRam1024x32_1rw1r upal1
(
  .clka(s_clk_i),    // input wire clka
  .ena(cs & adri[11]),      // input wire ena
  .wea(we),      // input wire [3 : 0] wea
  .addra({2'b0,adri[10:3]}),  // input wire [8 : 0] addra
  .dina(dat[31:0]),    // input wire [31 : 0] dina
  .douta(pal_wo),  // output wire [31 : 0] douta
  .clkb(vclk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [3 : 0] web
  .addrb({3'b0,pals,rgbo4[5:0]}),  // input wire [8 : 0] addrb
  .dinb(32'h0),    // input wire [31 : 0] dinb
  .doutb(pal_o)  // output wire [31 : 0] doutb
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
always @(posedge s_clk_i)
if (rst_i) begin
	page <= 1'b0;
	pals <= 1'b0;
	hres <= 3'd2;
	vres <= 3'd2;
	windowWidth <= 12'd400;
	windowHeight <= 12'd300;
	onoff <= 1'b1;
	color_depth <= BPP16;
	greyscale <= 1'b0;
	bm_base_addr1 <= BM_BASE_ADDR1;
	bm_base_addr2 <= BM_BASE_ADDR2;
	hrefdelay = 16'hFF99;//12'd103;
	vrefdelay = 16'hFFF3;//12'd13;
	windowLeft <= 16'h0;
	windowTop <= 16'h0;
	windowWidth <= 16'd400;
	windowHeight <= 16'd300;
	bmpWidth <= 16'd400;
	bmpHeight <= 16'd300;
	map <= MAP;
	pcmd <= 2'b00;
	rstcmd1 <= 1'b0;
	rst_irq <= 1'b0;
	rastcmp <= 12'hFFF;
	oob_color <= 32'h00003C00;
end
else begin
	rstcmd1 <= rstcmd;
	rst_irq <= 1'b0;
  if (rstcmd & ~rstcmd1)
    pcmd <= 2'b00;
	if (cs_edge) begin
		if (we) begin
			casez(adri[11:3])
			REG_CTRL:
				begin
					if (sel[0]) onoff <= dat[0];
					if (sel[1]) begin
					color_depth <= dat[10:8];
					greyscale <= dat[12];
					end
					if (sel[2]) begin
					hres <= dat[18:16];
					vres <= dat[22:20];
					end
					if (sel[3]) begin
					page <= dat[24];
					pals <= dat[25];
					end
					if (|sel[7:6]) map <= dat[59:48];
				end
			REG_REFDELAY:
				begin
					if (|sel[1:0])	hrefdelay <= dat[15:0];
					if (|sel[3:2])  vrefdelay <= dat[32:16];
				end
			REG_PAGE1ADDR:	bm_base_addr1 <= dat;
			REG_PAGE2ADDR:	bm_base_addr2 <= dat;
			REG_PXYZ:
				begin
					if (|sel[1:0])	px <= dat[15:0];
					if (|sel[3:2])	py <= dat[31:16];
					if (|sel[  4])	pz <= dat[39:32];
				end
			REG_PCOLCMD:
				begin
					if (sel[0]) pcmd <= dat[1:0];
			    if (sel[2]) raster_op <= dat[19:16];
			    if (|sel[7:4]) color <= dat[63:32];
			  end
			REG_RASTCMP:	
				begin
					if (sel[0]) rastcmp[7:0] <= dat[7:0];
					if (sel[1]) rastcmp[11:8] <= dat[11:8];
					if (sel[7]) rst_irq <= dat[63];
				end
			REG_BMPSIZE:
				begin
					if (|sel[1:0]) bmpWidth <= dat[15:0];
					if (|sel[5:4]) bmpHeight <= dat[47:32];
				end
			REG_OOB_COLOR:
				if (|sel[3:0]) oob_color <= dat[31:0];
			REG_WINDOW:
				begin
					if (|sel[1:0])	windowWidth <= dat[11:0];
					if (|sel[3:2])  windowHeight <= dat[27:16];
					if (|sel[5:4])	windowLeft <= dat[47:32];
					if (|sel[7:6])  windowTop <= dat[63:48];
				end

`ifdef INTERNAL_SYNC_GEN
			REG_TOTAL:
				begin
					if (!sgLock) begin
						if (|sel[1:0]) hTotal <= dat[11:0];
						if (|sel[3:2]) vTotal <= dat[27:16];
					end
					if (|sel[7:4]) begin
						if (dat[63:32]==32'hA1234567)
							sgLock <= 1'b0;
						else if (dat[63:32]==32'h7654321A)
							sgLock <= 1'b1;
					end
				end
			REG_SYNC_ONOFF:
				if (!sgLock) begin
					if (|sel[1:0]) hSyncOff <= dat[11:0];
					if (|sel[3:2]) hSyncOn <= dat[27:16];
					if (|sel[5:4]) vSyncOff <= dat[43:32];
					if (|sel[7:6]) vSyncOn <= dat[59:48];
				end
			REG_BLANK_ONOFF:
				if (!sgLock) begin
					if (|sel[1:0]) hBlankOff <= dat[11:0];
					if (|sel[3:2]) hBlankOn <= dat[27:16];
					if (|sel[5:4]) vBlankOff <= dat[43:32];
					if (|sel[7:6]) vBlankOn <= dat[59:48];
				end
			REG_BORDER_ONOFF:
				begin
					if (|sel[1:0]) hBorderOff <= dat[11:0];
					if (|sel[3:2]) hBorderOn <= dat[27:16];
					if (|sel[5:4]) vBorderOff <= dat[43:32];
					if (|sel[7:6]) vBorderOn <= dat[59:48];
				end
`endif
      default:  ;
			endcase
		end
	end
  casez(adri[11:3])
  REG_CTRL:
      begin
          s_dat_o[0] <= onoff;
          s_dat_o[10:8] <= color_depth;
          s_dat_o[12] <= greyscale;
          s_dat_o[18:16] <= hres;
          s_dat_o[22:20] <= vres;
          s_dat_o[24] <= page;
          s_dat_o[25] <= pals;
          s_dat_o[47:32] <= bmpWidth;
          s_dat_o[59:48] <= map;
      end
  REG_REFDELAY:		s_dat_o <= {32'h0,vrefdelay,hrefdelay};
  REG_PAGE1ADDR:	s_dat_o <= bm_base_addr1;
  REG_PAGE2ADDR:	s_dat_o <= bm_base_addr2;
  REG_PXYZ:		    s_dat_o <= {20'h0,pz,py,px};
  REG_PCOLCMD:    s_dat_o <= {color_o,12'd0,raster_op,14'd0,pcmd};
  REG_OOB_COLOR:	s_dat_o <= {32'h0,oob_color};
  REG_WINDOW:			s_dat_o <= {windowTop,windowLeft,4'h0,windowHeight,4'h0,windowWidth};
  9'b10??_????_?:	s_dat_o <= {32'h0,pal_wo};
  default:        s_dat_o <= 64'd0;
  endcase
end

//`ifdef USE_CLOCK_GATE
//BUFHCE ucb1
//(
//	.I(dot_clk_i),
//	.CE(onoff),
//	.O(vclk)
//);
//`else
assign vclk = dot_clk_i;
//`endif


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Horizontal and Vertical timing reference counters
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire lef;	// load even fifo
wire lof;	// load odd fifo

edge_det edh1
(
	.rst(rst_i),
	.clk(vclk),
	.ce(1'b1),
	.i(hsync_i),
	.pe(pe_hsync),
	.ne(),
	.ee()
);

edge_det edh2
(
	.rst(1'b0),
	.clk(m_clk_i),
	.ce(1'b1),
	.i(hsync_i),
	.pe(pe_hsync2),
	.ne(),
	.ee()
);

edge_det edv1
(
	.rst(rst_i),
	.clk(vclk),
	.ce(1'b1),
	.i(vsync_i),
	.pe(pe_vsync),
	.ne(),
	.ee()
);

reg [3:0] hc = 4'd1;
always @(posedge vclk)
if (pe_hsync) begin
	hc <= 4'd1;
	pixelCol <= hrefdelay;
end
else begin
	if (hc==hres) begin
		hc <= 4'd1;
		pixelCol <= pixelCol + 16'd1;
	end
	else
		hc <= hc + 4'd1;
end

reg [3:0] vc = 4'd1;
always @(posedge vclk)
if (pe_vsync) begin
	vc <= 4'd1;
	pixelRow <= vrefdelay;
end
else begin
	if (pe_hsync) begin
		vc <= vc + 4'd1;
		if (vc==vres) begin
			vc <= 4'd1;
			pixelRow <= pixelRow + 16'd1;
		end
	end
end
assign lef = ~pixelRow[0];
assign lof =  pixelRow[0];

// Bits per pixel minus one.
reg [4:0] bpp;
always @(color_depth)
case(color_depth)
BPP4: bpp = 3;
BPP8:	bpp = 7;
BPP12: bpp = 11;
BPP16:	bpp = 15;
BPP20:	bpp = 19;
BPP32:	bpp = 31;
default:	bpp = 15;
endcase

reg [5:0] shifts;
always @(color_depth)
case(MDW)
128:
	case(color_depth)
	BPP4:   shifts = 6'd32;
	BPP8: 	shifts = 6'd16;
	BPP12:	shifts = 6'd10;
	BPP16:	shifts = 6'd8;
	BPP20:	shifts = 6'd6;
	BPP32:	shifts = 6'd4;
	default:  shifts = 6'd8;
	endcase
64:
	case(color_depth)
	BPP4:   shifts = 6'd16;
	BPP8: 	shifts = 6'd8;
	BPP12:	shifts = 6'd5;
	BPP16:	shifts = 6'd4;
	BPP20:	shifts = 6'd3;
	BPP32:	shifts = 6'd2;
	default:  shifts = 6'd4;
	endcase
32:
	case(color_depth)
	BPP4:   shifts = 6'd8;
	BPP8: 	shifts = 6'd4;
	BPP12:	shifts = 6'd2;
	BPP16:	shifts = 6'd2;
	BPP20:	shifts = 6'd1;
	BPP32:	shifts = 6'd1;
	default:  shifts = 6'd2;
	endcase
default:
	begin
	$display("rtfBitmapController5: Bad master bus width");
	$finish;
	end
endcase

wire vFetch = !vblank;//pixelRow < windowHeight;
wire fifo_rrst = pixelCol==16'hFFFF;
wire fifo_wrst = pe_hsync2 && vc==4'd1;

wire[31:0] grAddr,xyAddr;
reg [11:0] fetchCol;
localparam CMS = MDW==128 ? 6 : MDW==64 ? 5 : 4;
wire [CMS:0] mb,me,ce;
reg [MDW-1:0] mem_strip;
wire [MDW-1:0] mem_strip_o;
wire [31:0] mem_color;

// Compute fetch address
gfx_CalcAddress6 #(MDW) u1
(
  .clk(m_clk_i),
	.base_address_i(baseAddr),
	.color_depth_i(color_depth),
	.bmp_width_i(bmpWidth),
	.x_coord_i(windowLeft),
	.y_coord_i(windowTop + pixelRow),
	.address_o(grAddr),
	.mb_o(),
	.me_o(),
	.ce_o()
);

// Compute address for get/set pixel
gfx_CalcAddress6 #(MDW) u2
(
  .clk(m_clk_i),
	.base_address_i(baseAddr),
	.color_depth_i(color_depth),
	.bmp_width_i(bmpWidth),
	.x_coord_i(px),
	.y_coord_i(py),
	.address_o(xyAddr),
	.mb_o(mb),
	.me_o(me),
	.ce_o(ce)
);

always @(posedge m_clk_i)
if (pe_hsync2)
  mapctr <= 12'hFFE;
else begin
  if (mapctr == map)
    mapctr <= 12'd0;
  else
    mapctr <= mapctr + 12'd1;
end
wire memreq = mapctr==12'd0;

// The following bypasses loading the fifo when all the pixels from a scanline
// are buffered in the fifo and the pixel row doesn't change. Since the fifo
// pointers are reset at the beginning of a scanline, the fifo can be used like
// a cache.
wire blankEdge;
edge_det ed2(.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(blank_i), .pe(blankEdge), .ne(), .ee() );
reg do_loads;
reg load_fifo = 1'b0;
always @(posedge m_clk_i)
	//load_fifo <= fifo_cnt < 10'd1000 && vFetch && onoff && xonoff && !m_cyc_o && do_loads;
	load_fifo <= /*fifo_cnt < 8'd224 &&*/ vFetch && onoff && xonoff_i && (fetchCol < windowWidth) && memreq;
// The following table indicates the number of pixel that will fit into the
// video fifo. 
reg [11:0] hCmp;
always @(color_depth)
case(color_depth)
BPP4: hCmp = 12'd4095;    // must be 12 bits
BPP8:	hCmp = 12'd2048;
BPP12: hCmp = 12'd1536;
BPP16:	hCmp = 12'd1024;
BPP20:	hCmp = 12'd768;
BPP32:	hCmp = 12'd512;
default:	hCmp = 12'd1024;
endcase
/*
always @(posedge m_clk_i)
	// if windowWidth > hCmp we always load because the fifo isn't large enough to act as a cache.
	if (!(windowWidth < hCmp))
		do_loads <= 1'b1;
	// otherwise load the fifo only when the row changes to conserve memory bandwidth
	else if (vc==4'd1)//pixelRow != opixelRow)
		do_loads <= 1'b1;
	else if (blankEdge)
		do_loads <= 1'b0;
*/
assign m_stb_o = m_cyc_o;
assign m_sel_o = MDW==128 ? 16'hFFFF : MDW==64 ? 8'hFF : 4'hF;

reg [31:0] adr;
reg [3:0] state;
reg [127:0] icolor1;
parameter IDLE = 4'd0;
parameter LOADCOLOR = 4'd2;
parameter LOADSTRIP = 4'd3;
parameter STORESTRIP = 4'd4;
parameter ACKSTRIP = 4'd5;
parameter WAITLOAD = 4'd6;
parameter WAITRST = 4'd7;
parameter ICOLOR1 = 4'd8;
parameter ICOLOR2 = 4'd9;
parameter ICOLOR3 = 4'd10;
parameter ICOLOR4 = 4'd11;
parameter WAIT_NACK = 4'd12;
parameter LOAD_OOB = 4'd13;

function rastop;
input [3:0] op;
input a;
input b;
case(op)
OPBLACK: rastop = 1'b0;
OPCOPY:  rastop = b;
OPINV:   rastop = ~a;
OPAND:   rastop = a & b;
OPOR:    rastop = a | b;
OPXOR:   rastop = a ^ b;
OPANDN:  rastop = a & ~b;
OPNAND:  rastop = ~(a & b);
OPNOR:   rastop = ~(a | b);
OPXNOR:  rastop = ~(a ^ b);
OPORN:   rastop = a | ~b;
OPWHITE: rastop = 1'b1;
default:	rastop = 1'b0;
endcase
endfunction

always @(posedge m_clk_i)
	if (fifo_wrst)
		adr <= grAddr;
  else begin
    if ((state==WAITLOAD && m_ack_i) || state==LOAD_OOB)
    	case(MDW)
    	32:		adr <= adr + 32'd4;
    	64:		adr <= adr + 32'd8;
    	default:	adr <= adr + 32'd16;
    	endcase
  end

always @(posedge m_clk_i)
	if (fifo_wrst)
		fetchCol <= 12'd0;
  else begin
    if ((state==WAITLOAD && m_ack_i) || state==LOAD_OOB)
      fetchCol <= fetchCol + shifts;
  end

// Check for legal (positive) coordinates
// Illegal coordinates result in a red display
wire [15:0] xcol = fetchCol;
wire legal_x = ~&xcol[15:12] && xcol < bmpWidth;
wire legal_y = ~&pixelRow[15:12] && pixelRow < bmpHeight;

reg modd;
always @*
	case(MDW)
	32:	modd <= m_adr_o[5:2]==4'hF;
	64:	modd <= m_adr_o[5:3]==3'h7;
	default:	modd <= m_adr_o[5:4]==2'h3;
	endcase

always @(posedge m_clk_i)
if (rst_i) begin
	wb_nack();
  rstcmd <= 1'b0;
  state <= IDLE;
end
else begin
	case(state)
  WAITRST:
    if (pcmd==2'b00 && ~m_ack_i) begin
      rstcmd <= 1'b0;
      state <= IDLE;
    end
    else
      rstcmd <= 1'b1;
  IDLE:
  	if (load_fifo && !(legal_x && legal_y))
 			state <= LOAD_OOB;
    else if (load_fifo & ~m_ack_i) begin
      m_cyc_o <= `HIGH;
      m_we_o <= `LOW;
      m_adr_o <= adr;
      state <= WAITLOAD;
    end
    // The adr_o[5:3]==3'b111 causes the controller to wait until all eight
    // 64 bit strips from the memory controller have been processed. Otherwise
    // there would be cache thrashing in the memory controller and the memory
    // bandwidth available would be greatly reduced. However fetches are also
    // allowed when loads are not active or all strips for the current scan-
    // line have been fetched.
    else if (pcmd!=2'b00 && (modd || !(vFetch && onoff && xonoff_i && fetchCol < windowWidth))) begin
      m_cyc_o <= `HIGH;
      m_we_o <= `LOW;
      m_adr_o <= xyAddr;
      state <= LOADSTRIP;
    end
  LOADSTRIP:
    if (m_ack_i) begin
      wb_nack();
      mem_strip <= m_dat_i;
      icolor1 <= {96'b0,color} << mb;
      rstcmd <= 1'b1;
      if (pcmd==2'b01)
        state <= ICOLOR3;
      else if (pcmd==2'b10)
        state <= ICOLOR2;
      else begin
        state <= WAITRST;
      end
    end
  // Registered inline mem2color
  ICOLOR3:
    begin
      color_o <= mem_strip >> mb;
      state <= ICOLOR4;
    end
  ICOLOR4:
    begin
      for (n = 0; n < 32; n = n + 1)
        color_o[n] <= (n <= bpp) ? color_o[n] : 1'b0;
      state <= pcmd == 2'b0 ? (~m_ack_i ? IDLE : WAITRST) : WAITRST;
      if (pcmd==2'b00)
        rstcmd <= 1'b0;
    end
  // Registered inline color2mem
  ICOLOR2:
    begin
      for (n = 0; n < MDW; n = n + 1)
        m_dat_o[n] <= (n >= mb && n <= me)
        	? ((n <= ce) ?	rastop(raster_op, mem_strip[n], icolor1[n]) : icolor1[n])
        	: mem_strip[n];
      state <= STORESTRIP;
    end
  STORESTRIP:
    if (~m_ack_i) begin
      m_cyc_o <= `HIGH;
      m_we_o <= `HIGH;
      state <= ACKSTRIP;
    end
  ACKSTRIP:
    if (m_ack_i) begin
      wb_nack();
      state <= pcmd == 2'b0 ? IDLE : WAITRST;
      if (pcmd==2'b00)
        rstcmd <= 1'b0;
    end
  WAITLOAD:
    if (m_ack_i) begin
      wb_nack();
      state <= IDLE;
    end
  LOAD_OOB:
  	state <= IDLE;
  WAIT_NACK:
  	if (~m_ack_i)
  		state <= IDLE;
  default:	state <= IDLE;
  endcase
end

task wb_nack;
begin
	m_cyc_o <= `LOW;
	m_we_o <= `LOW;
end
endtask

reg [31:0] rgbo2,rgbo4;
reg [MDW-1:0] rgbo3;
always @(posedge vclk)
case(color_depth)
BPP4:	rgbo4 <= {rgbo3[3],7'h00,21'd0,rgbo3[2:0]};	// feeds into palette
BPP8:	rgbo4 <= {rgbo3[7:6],6'h00,18'h0,rgbo3[5:0]};		// feeds into palette
BPP12:	rgbo4 <= {rgbo3[11:9],5'd0,rgbo3[8:6],5'd0,rgbo3[5:3],5'd0,rgbo3[2:0],5'd0};
BPP16:	rgbo4 <= {rgbo3[15:12],4'b0,rgbo3[11:8],4'b0,rgbo3[7:4],4'b0,rgbo3[3:0],4'b0};
BPP20:	rgbo4 <= {rgbo3[19:15],3'b0,rgbo3[14:10],4'b0,rgbo3[9:5],3'b0,rgbo3[4:0],3'b0};
BPP32:	rgbo4 <= rgbo3;
default:	rgbo4 <= {rgbo3[15:12],4'b0,rgbo3[11:8],4'b0,rgbo3[7:4],4'b0,rgbo3[3:0],4'b0};
endcase

reg rd_fifo,rd_fifo1,rd_fifo2;
reg de;
always @(posedge vclk)
	if (rd_fifo1)
		de <= ~blank_i;

always @(posedge vclk)
	if (onoff && xonoff_i && !blank_i) begin
		if (color_depth[2:1]==2'b00) begin
			if (!greyscale)
				zrgb_o <= pal_o[31:0];
			else
				zrgb_o <= {pal_o[31:24],{3{pal_o[7:0]}}};
		end
		else
			zrgb_o <= rgbo4;
	end
	else
		zrgb_o <= 32'hFF000000;

// Before the hrefdelay expires, pixelCol will be negative, which is greater
// than windowWidth as the value is unsigned. That means that fifo reading is
// active only during the display area 0 to windowWidth.
wire shift1 = hc==hres;
reg [5:0] shift_cnt;
always @(posedge vclk)
if (pe_hsync)
	shift_cnt <= 5'd1;
else begin
	if (shift1) begin
		if (pixelCol==16'hFFFF)
			shift_cnt <= shifts;
		else if (!pixelCol[15]) begin
			shift_cnt <= shift_cnt + 5'd1;
			if (shift_cnt==shifts)
				shift_cnt <= 5'd1;
		end
		else
			shift_cnt <= 5'd1;
	end
end

wire next_strip = (shift_cnt==shifts) && (hc==hres);

wire vrd;
reg shift,shift2;
always @(posedge vclk) shift2 <= shift1;
always @(posedge vclk) shift <= shift2;
always @(posedge vclk) rd_fifo2 <= next_strip;
always @(posedge vclk) rd_fifo <= rd_fifo2;
always @(posedge vclk)
	if (rd_fifo)
		rgbo3 <= lef ? rgbo1o : rgbo1e;
	else if (shift) begin
		case(color_depth)
		BPP4:	rgbo3 <= {4'h0,rgbo3[MDW-1:4]};
		BPP8:	rgbo3 <= {8'h0,rgbo3[MDW-1:8]};
		BPP12: rgbo3 <= {12'h0,rgbo3[MDW-1:12]};
		BPP16:	rgbo3 <= {16'h0,rgbo3[MDW-1:16]};
		BPP20:	rgbo3 <= {20'h0,rgbo3[MDW-1:20]};
		BPP32:	rgbo3 <= {32'h0,rgbo3[MDW-1:32]};
		default: rgbo3 <= {16'h0,rgbo3[MDW-1:16]};
		endcase
	end


/* Debugging
wire [127:0] dat;
assign dat[11:0] = pixelRow[0] ? 12'hEA4 : 12'h000;
assign dat[23:12] = pixelRow[1] ? 12'hEA4 : 12'h000;
assign dat[35:24] = pixelRow[2] ? 12'hEA4 : 12'h000;
assign dat[47:36] = pixelRow[3] ? 12'hEA4 : 12'h000;
assign dat[59:48] = pixelRow[4] ? 12'hEA4 : 12'h000;
assign dat[71:60] = pixelRow[5] ? 12'hEA4 : 12'h000;
assign dat[83:72] = pixelRow[6] ? 12'hEA4 : 12'h000;
assign dat[95:84] = pixelRow[7] ? 12'hEA4 : 12'h000;
assign dat[107:96] = pixelRow[8] ? 12'hEA4 : 12'h000;
assign dat[119:108] = pixelRow[9] ? 12'hEA4 : 12'h000;
*/

reg [MDW-1:0] oob_dat;
always @*
case(color_depth)
BPP4:	oob_dat <= {MDW/4{oob_color[3:0]}};
BPP8:	oob_dat <= {MDW/8{oob_color[7:0]}};
BPP12:	oob_dat <= {MDW/12{oob_color[11:0]}};
BPP16:	oob_dat <= {MDW/16{oob_color[15:0]}};
BPP20:	oob_dat <= {MDW/20{oob_color[19:0]}};
BPP32:	oob_dat <= {MDW/32{oob_color[31:0]}};
default:	oob_dat <= {MDW/16{oob_color[15:0]}};
endcase

rtfVideoFifo3 #(MDW) uf1
(
	.wrst(fifo_wrst),
	.wclk(m_clk_i),
	.wr(((m_ack_i && state==WAITLOAD) || state==LOAD_OOB) && lef),
	.di((state==LOAD_OOB) ? oob_dat : m_dat_i),
	.rrst(fifo_rrst),
	.rclk(vclk),
	.rd(rd_fifo & lof),
	.dout(rgbo1e),
	.cnt()
);

rtfVideoFifo3 #(MDW) uf2
(
	.wrst(fifo_wrst),
	.wclk(m_clk_i),
	.wr(((m_ack_i && state==WAITLOAD) || state==LOAD_OOB) && lof),
	.di((state==LOAD_OOB) ? oob_dat : m_dat_i),
	.rrst(fifo_rrst),
	.rclk(vclk),
	.rd(rd_fifo & lef),
	.dout(rgbo1o),
	.cnt()
);

endmodule
