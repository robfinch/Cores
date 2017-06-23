// ============================================================================
//  Bitmap Controller
//  - Displays a bitmap from memory.
//
//
//        __
//   \\__/ o\    (C) 2008-2017  Robert Finch, Waterloo
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
//		$0200000 - the second 4MiB of RAM
//
//
//	Verilog 1995
//
// ============================================================================

module BitmapController(
	rst_i,
	s_clk_i, s_cs_i, s_cyc_i, s_stb_i, s_ack_o, s_we_i, s_adr_i, s_dat_i, s_dat_o, irq_o,
	m_clk_i, m_bte_o, m_cti_o, m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o,
	vclk, hsync, vsync, blank, rgbo, xonoff
);
parameter pIOAddress = 32'hFFDC5000;
parameter BM_BASE_ADDR1 = 32'h0020_0000;
parameter BM_BASE_ADDR2 = 32'h0028_0000;
parameter REG_CTRL = 10'd0;
parameter REG_CTRL2 = 10'd1;
parameter REG_HDISPLAYED = 10'd2;
parameter REG_VDISPLAYED = 10'd3;
parameter REG_PAGE1ADDR = 10'd5;
parameter REG_PAGE2ADDR = 10'd6;
parameter REG_REFDELAY = 10'd7;
parameter REG_MAP = 10'd8;
parameter REG_PX = 10'd9;
parameter REG_PY = 10'd10;
parameter REG_COLOR = 10'd11;
parameter REG_PCMD = 10'd12;
parameter REG_RAMA = 10'd13;
parameter REG_RAMD = 10'd14;

parameter BPP6 = 3'd0;
parameter BPP8 = 3'd1;
parameter BPP12 = 3'd2;
parameter BPP16 = 3'd3;
parameter BPP24 = 3'd4;
parameter BPP32 = 3'd5;

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

parameter PCMD_NONE = 3'b000;
parameter PCMD_GET_PIXEL = 3'b001;
parameter PCMD_SET_PIXEL = 3'b010;
parameter PCMD_RD_MEM = 3'b011;
parameter PCMD_WR_MEM = 3'b100;

// The following parameter inserts an extra cycle of setup time for the
// address and write control signals if true.
parameter EXTRA_SUT = 1'b0; // extra setup time

// SYSCON
input rst_i;				// system reset

// Peripheral slave port
input s_clk_i;
input s_cs_i;
input s_cyc_i;
input s_stb_i;
output s_ack_o;
input s_we_i;
input [11:0] s_adr_i;
input [31:0] s_dat_i;
output [31:0] s_dat_o;
reg [31:0] s_dat_o;
output irq_o;

// Video Master Port
// Used to read memory via burst access
input m_clk_i;				// system bus interface clock
output [1:0] m_bte_o;
output [2:0] m_cti_o;
output m_cyc_o;			// video burst request
output m_stb_o;
output reg m_we_o;
output [15:0] m_sel_o;
input  m_ack_i;			// vid_acknowledge from memory
output [31:0] m_adr_o;	// address for memory access
input  [127:0] m_dat_i;	// memory data input
output reg [127:0] m_dat_o;

// Video
input vclk;				// Video clock 85.71 MHz
input hsync;				// start/end of scan line
input vsync;				// start/end of frame
input blank;			// blank the output
output [23:0] rgbo;		// 24-bit RGB output
reg [23:0] rgbo;

input xonoff;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// IO registers
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg m_cyc_o;
reg [31:0] m_adr_o;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire cs = s_cyc_i & s_stb_i & s_cs_i;
reg ack,ack1;
always @(posedge s_clk_i)
begin
	ack1 <= cs;
	ack <= ack1 & cs;
end
assign s_ack_o = cs ? (s_we_i ? 1'b1 : ack) : 1'b0;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
integer n;
reg [11:0] hDisplayed,vDisplayed;
reg [31:0] bm_base_addr1,bm_base_addr2;
reg [2:0] color_depth;
wire [7:0] fifo_cnt;
reg onoff;
reg [2:0] hres,vres;
reg greyscale;
reg page;
reg pals;				// palette select
reg [11:0] hrefdelay;
reg [11:0] vrefdelay;
reg [11:0] map;     // memory access period
reg [11:0] mapctr;
reg [11:0] hctr;		// horizontal reference counter
wire [11:0] hctr1 = hctr - hrefdelay;
reg [11:0] vctr;		// vertical reference counter
wire [11:0] vctr1 = vctr - vrefdelay;
reg [31:0] baseAddr;	// base address register
wire [127:0] rgbo1;
reg [11:0] pixelRow;
reg [11:0] pixelCol;
wire [31:0] pal_wo;
wire [31:0] pal_o;
reg [11:0] px;
reg [11:0] py;
reg [2:0] pcmd,pcmd_o;
reg [3:0] raster_op;
reg [31:0] color;
reg [31:0] color_o;
reg [31:0] rama;
reg [15:0] ramd,ramd_o;
reg rstcmd,rstcmd1;

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


always @(page or bm_base_addr1 or bm_base_addr2)
	baseAddr = page ? bm_base_addr2 : bm_base_addr1;

// Color palette RAM for 8bpp modes
syncRam512x32_1rw1r upal1
(
	.wrst(1'b0),
	.wclk(s_clk_i),
	.wce(cs & s_adr_i[11]),
	.we(s_we_i),
	.wadr(s_adr_i[10:2]),
	.i(s_dat_i),
	.wo(pal_wo),
	.rrst(1'b0),
	.rclk(vclk),
	.rce(1'b1),
	.radr({pals,rgbo4[7:0]}),
	.o(pal_o)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
always @(posedge s_clk_i)
if (rst_i) begin
	page <= 1'b0;
	pals <= 1'b0;
	hres <= 3'd4;
	vres <= 3'd3;
	hDisplayed <= 12'd340;
	vDisplayed <= 12'd256;
	onoff <= 1'b1;
	color_depth <= BPP16;
	greyscale <= 1'b0;
	bm_base_addr1 <= BM_BASE_ADDR1;
	bm_base_addr2 <= BM_BASE_ADDR2;
	hrefdelay <= 12'd54;//12'd218;
	vrefdelay <= 12'd8;//12'd27;
	map <= 12'd0;
	pcmd <= PCMD_NONE;
	rstcmd1 <= 1'b0;
end
else begin
	rstcmd1 <= rstcmd;
  if (rstcmd & ~rstcmd1)
    pcmd <= 2'b00;
	if (cs_edge) begin
		if (s_we_i) begin
			casex(s_adr_i[11:2])
			REG_CTRL:
				begin
					onoff <= s_dat_i[0];
					color_depth <= s_dat_i[10:8];
					greyscale <= s_dat_i[11];
					hres <= s_dat_i[18:16];
					vres <= s_dat_i[21:19];
				end
			REG_CTRL2:
				begin
					page <= s_dat_i[16];
					pals <= s_dat_i[17];
				end
			REG_HDISPLAYED:	hDisplayed <= s_dat_i[11:0];
			REG_VDISPLAYED:	vDisplayed <= s_dat_i[11:0];
			REG_PAGE1ADDR:	bm_base_addr1 <= s_dat_i;
			REG_PAGE2ADDR:	bm_base_addr2 <= s_dat_i;
			REG_REFDELAY:
				begin
					hrefdelay <= s_dat_i[11:0];
					vrefdelay <= s_dat_i[27:16];
				end
			REG_MAP:   map <= s_dat_i[11:0];
			REG_PX:    px <= s_dat_i[11:0];
			REG_PY:    py <= s_dat_i[11:0];
			REG_PCMD:  begin
			           pcmd <= s_dat_i[2:0];
			           raster_op <= s_dat_i[19:16];
			           end
            REG_COLOR: color <= s_dat_i;
			REG_RAMA:  rama <= s_dat_i;
			REG_RAMD:  ramd <= s_dat_i[15:0];
      default:  ;
			endcase
		end
	end
    casex(s_adr_i[11:2])
    REG_CTRL:
        begin
            s_dat_o[0] <= onoff;
            s_dat_o[10:8] <= color_depth;
            s_dat_o[11] <= greyscale;
            s_dat_o[18:16] <= hres;
            s_dat_o[21:19] <= vres;
        end
    REG_CTRL2:	
        begin
            s_dat_o[16] <= page;
            s_dat_o[17] <= pals;
        end
    REG_HDISPLAYED:	s_dat_o <= hDisplayed;
    REG_VDISPLAYED:	s_dat_o <= vDisplayed;
    REG_PAGE1ADDR:	s_dat_o <= bm_base_addr1;
    REG_PAGE2ADDR:	s_dat_o <= bm_base_addr2;
    REG_REFDELAY:	  s_dat_o <= {vrefdelay,4'h0,hrefdelay};
    REG_MAP:        s_dat_o <= map;
    REG_PX:			    s_dat_o <= px;
    REG_PY:			    s_dat_o <= py;
    REG_COLOR:      s_dat_o <= color_o;
    REG_PCMD:			  begin
                    s_dat_o <= pcmd;
                    end
    REG_RAMD:       s_dat_o <= ramd_o;
    10'b1xxx_xxxx_xx:	s_dat_o <= pal_wo;
    default:        s_dat_o <= 32'd0;
    endcase
end

assign irq_o = 1'b0;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Horizontal and Vertical timing reference counters
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire pe_hsync, pe_hsync2;
wire pe_vsync;
edge_det edh1
(
	.rst(rst_i),
	.clk(vclk),
	.ce(1'b1),
	.i(hsync),
	.pe(pe_hsync),
	.ne(),
	.ee()
);

edge_det edh2
(
	.rst(rst_i),
	.clk(m_clk_i),
	.ce(1'b1),
	.i(hsync),
	.pe(pe_hsync2),
	.ne(),
	.ee()
);

edge_det edv1
(
	.rst(rst_i),
	.clk(vclk),
	.ce(1'b1),
	.i(vsync),
	.pe(pe_vsync),
	.ne(),
	.ee()
);

reg [3:0] hc;
always @(posedge vclk)
if (rst_i)
	hc <= 4'd1;
else if (pe_hsync) begin
	hc <= 4'd1;
	pixelCol <= -hrefdelay;
end
else begin
	if (hc==hres) begin
		hc <= 4'd1;
		pixelCol <= pixelCol + 1;
	end
	else
		hc <= hc + 4'd1;
end

reg [3:0] vc;
always @(posedge vclk)
if (rst_i)
	vc <= 4'd1;
else if (pe_vsync) begin
	vc <= 4'd1;
	pixelRow <= -vrefdelay;
end
else begin
	if (pe_hsync) begin
		vc <= vc + 4'd1;
		if (vc==vres) begin
			vc <= 4'd1;
			pixelRow <= pixelRow + 1;
		end
	end
end

// Bits per pixel minus one.
reg [4:0] bpp;
always @(color_depth)
case(color_depth)
BPP6: bpp = 5;
BPP8:	bpp = 7;
BPP12:	bpp = 11;
BPP16:	bpp = 15;
BPP24:	bpp = 23;
BPP32:	bpp = 31;
endcase

reg [4:0] shifts;
always @(color_depth)
case(color_depth)
BPP6:   shifts = 5'd21;
BPP8: 	shifts = 5'd16;
BPP12:	shifts = 5'd10;
BPP16:	shifts = 5'd8;
BPP24:	shifts = 5'd5;
BPP32:	shifts = 5'd4;
default:  shifts = 5'd16;
endcase

wire vFetch = pixelRow < vDisplayed;
wire fifo_rrst = pixelCol==12'hFFF;
wire fifo_wrst = pe_hsync2;

wire[31:0] grAddr,xyAddr;
reg [11:0] fetchCol;
wire [6:0] mb,me;
reg [127:0] mem_strip;
wire [127:0] mem_strip_o;
wire [31:0] mem_color;

gfx_CalcAddress u1
(
  .clk(m_clk_i),
	.base_address_i(baseAddr),
	.color_depth_i({1'b0,color_depth}),
	.hdisplayed_i(hDisplayed),
	.x_coord_i(12'b0),
	.y_coord_i(pixelRow),
	.address_o(grAddr),
	.mb_o(),
	.me_o()
);

gfx_CalcAddress u2
(
  .clk(m_clk_i),
	.base_address_i(baseAddr),
	.color_depth_i({1'b0,color_depth}),
	.hdisplayed_i(hDisplayed),
	.x_coord_i(px),
	.y_coord_i(py),
	.address_o(xyAddr),
	.mb_o(mb),
	.me_o(me)
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
edge_det ed2(.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(blank), .pe(blankEdge), .ne(), .ee() );
reg do_loads;
reg [11:0] opixelRow;
reg load_fifo;
always @(posedge m_clk_i)
	//load_fifo <= fifo_cnt < 10'd1000 && vFetch && onoff && xonoff && !m_cyc_o && do_loads;
	load_fifo <= /*fifo_cnt < 8'd224 &&*/ vFetch && onoff && xonoff && fetchCol < hDisplayed && !m_cyc_o && do_loads && memreq;
// The following table indicates the number of pixel that will fit into the
// video fifo. 
reg [11:0] hCmp;
always @(color_depth)
case(color_depth)
BPP6: hCmp = 12'd4095;
BPP8:	hCmp = 12'd4095;    // must be 12 bits
BPP12:	hCmp = 12'd2559;
BPP16:	hCmp = 12'd2048;
BPP24:	hCmp = 12'd1279;
BPP32:	hCmp = 12'd1024;
default:	hCmp = 12'd1024;
endcase
always @(posedge m_clk_i)
	// if hDisplayed > hCmp we always load because the fifo isn't large enough to act as a cache.
	if (!(hDisplayed < hCmp))
		do_loads <= 1'b1;
	// otherwise load the fifo only when the row changes to conserve memory bandwidth
	else if (vc==4'd1)//pixelRow != opixelRow)
		do_loads <= 1'b1;
	else if (blankEdge)
		do_loads <= 1'b0;

assign m_bte_o = 2'b00;
assign m_cti_o = 3'b000;
assign m_stb_o = 1'b1;
assign m_sel_o = 16'hFFFF;

reg [31:0] adr;
reg [3:0] state;
reg [127:0] icolor1;
parameter IDLE = 4'd1;
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
parameter CYC = 4'd12;
parameter CYC1 = 4'd13;
parameter ST_RDMEM = 4'd14;
parameter ST_WRMEM = 4'd15;

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
endcase
endfunction

always @(posedge m_clk_i)
	if (fifo_wrst)
		adr <= grAddr;
  else begin
    if (state==WAITLOAD && m_ack_i)
      adr <= adr + 32'd16;
  end

always @(posedge m_clk_i)
	if (fifo_wrst)
		fetchCol <= 12'd0;
  else begin
    if (state==WAITLOAD && m_ack_i)
      fetchCol <= fetchCol + shifts;
  end

always @(posedge m_clk_i)
if (rst_i) begin
	wb_nack();
  rstcmd <= 1'b0;
  state <= IDLE;
end
else begin
	case(state)
  WAITRST:
    if (pcmd==PCMD_NONE) begin
      rstcmd <= 1'b0;
      state <= IDLE;
    end
    else
      rstcmd <= 1'b1;
  IDLE:
    if (load_fifo) begin
      if (!EXTRA_SUT) begin
        m_cyc_o <= 1'b1;
        state <= WAITLOAD;
      end
      else
        state <= CYC1;
      m_we_o <= 1'b0;
      m_adr_o <= adr;
    end
    // The adr_o[5:4]==2'b11 causes the controller to wait until all four
    // 128 bit strips from the memory controller have been processed. Otherwise
    // there would be cache thrashing in the memory controller and the memory
    // bandwidth available would be greatly reduced. However fetches are also
    // allowed when loads are not active or all strips for the current scan-
    // line have been fetched.
    else if (pcmd!=PCMD_NONE && (m_adr_o[5:4]==2'b11 || !(vFetch && onoff && xonoff && fetchCol < hDisplayed) || !do_loads)) begin
      m_we_o <= 1'b0;
      case(pcmd)
      PCMD_RD_MEM,PCMD_WR_MEM:  m_adr_o <= {rama[31:4],4'h0};
      default:  m_adr_o <= xyAddr;
      endcase
      
      if (!EXTRA_SUT) begin
        m_cyc_o <= 1'b1;
        state <= LOADSTRIP;
      end
      else
        state <= CYC;
    end
  CYC1:
    begin
      m_cyc_o <= 1'b1;
      state <= WAITLOAD;
    end
  CYC:
    begin
      m_cyc_o <= 1'b1;
      state <= LOADSTRIP;
    end
  LOADSTRIP:
    if (m_ack_i) begin
      wb_nack();
      mem_strip <= m_dat_i;
      icolor1 <= {96'b0,color} << mb;
      rstcmd <= 1'b1;
      case(pcmd)
      PCMD_GET_PIXEL:   state <= ICOLOR3;
      PCMD_SET_PIXEL:   state <= ICOLOR2;
      PCMD_RD_MEM:      state <= ST_RDMEM;
      PCMD_WR_MEM:      state <= ST_WRMEM;
      default:          state <= WAITRST;
      endcase
    end
  ST_RDMEM:
     begin
         ramd_o <= mem_strip >> {rama[3:1],4'h0};
         state <= pcmd == PCMD_NONE ? IDLE : WAITRST;
         if (pcmd==PCMD_NONE)
           rstcmd <= 1'b0;
     end
  ST_WRMEM:
    begin
        case(rama[3:1])
        3'd0:   m_dat_o <= {mem_strip[127:16],ramd};
        3'd1:   m_dat_o <= {mem_strip[127:32],ramd,mem_strip[15:0]};
        3'd2:   m_dat_o <= {mem_strip[127:48],ramd,mem_strip[31:0]};
        3'd3:   m_dat_o <= {mem_strip[127:64],ramd,mem_strip[47:0]};
        3'd4:   m_dat_o <= {mem_strip[127:80],ramd,mem_strip[63:0]};
        3'd5:   m_dat_o <= {mem_strip[127:96],ramd,mem_strip[79:0]};
        3'd6:   m_dat_o <= {mem_strip[127:112],ramd,mem_strip[95:0]};
        3'd7:   m_dat_o <= {ramd,mem_strip[111:0]};
        endcase
        state <= STORESTRIP;
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
      state <= pcmd == PCMD_NONE ? IDLE : WAITRST;
      if (pcmd==PCMD_NONE)
        rstcmd <= 1'b0;
    end
  // Registered inline color2mem
  ICOLOR2:
    begin
      for (n = 0; n < 128; n = n + 1)
        m_dat_o[n] <= (n >= mb && n <= me) ? rastop(raster_op, mem_strip[n], icolor1[n]) : mem_strip[n];
      state <= STORESTRIP;
    end
  STORESTRIP:
    begin
      m_cyc_o <= 1'b1;
      m_we_o <= 1'b1;
      state <= ACKSTRIP;
    end
  ACKSTRIP:
    if (m_ack_i) begin
      wb_nack();
      state <= pcmd == PCMD_NONE ? IDLE : WAITRST;
      if (pcmd==PCMD_NONE)
        rstcmd <= 1'b0;
    end
  WAITLOAD:
    if (m_ack_i) begin
      wb_nack();
      state <= IDLE;
    end
  endcase
end

task wb_nack;
begin
	m_cyc_o <= 1'b0;
	m_we_o <= 1'b0;
end
endtask

reg [11:0] pixelColD1;
reg [23:0] rgbo2,rgbo4;
reg [127:0] rgbo3;
always @(posedge vclk)
case(color_depth)
BPP6:	rgbo4 <= greyscale ? {3{rgbo3[5:0],2'b00}} : rgbo3[5:0];
BPP8:	rgbo4 <= greyscale ? {3{rgbo3[7:0]}} : rgbo3[7:0];
BPP12:	rgbo4 <= {rgbo3[11:8],4'h0,rgbo3[7:4],4'h0,rgbo3[3:0],4'h0};
BPP16:	rgbo4 <= {rgbo3[15:11],3'b0,rgbo3[10:5],2'b0,rgbo3[4:0],3'b0};
BPP24:	rgbo4 <= rgbo3[23:0];
BPP32:	rgbo4 <= rgbo3[23:0];
endcase

reg rd_fifo,rd_fifo1,rd_fifo2;
reg de;
always @(posedge vclk)
	if (rd_fifo1)
		de <= ~blank;

always @(posedge vclk)
	if (onoff && xonoff && !blank) begin
		if (color_depth[2:1]==2'b00 && !greyscale)
			rgbo <= pal_o;
		else
			rgbo <= rgbo4[23:0];
	end
	else
		rgbo <= 24'd0;

// Before the hrefdelay expires, pixelCol will be negative, which is greater
// than hDisplayed as the value is unsigned. That means that fifo reading is
// active only during the display area 0 to hDisplayed.
wire shift1 = hc==hres;
reg [4:0] shift_cnt;
always @(posedge vclk)
if (pe_hsync)
	shift_cnt <= 5'd1;
else begin
	if (shift1) begin
		if (pixelCol==12'hFFF)
			shift_cnt <= shifts;
		else if (!pixelCol[11]) begin
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
always @(posedge vclk) pixelColD1 <= pixelCol;
reg shift,shift2;
always @(posedge vclk) shift2 <= shift1;
always @(posedge vclk) shift <= shift2;
always @(posedge vclk) rd_fifo2 <= next_strip;
always @(posedge vclk) rd_fifo <= rd_fifo2;
always @(posedge vclk)
	if (rd_fifo)
		rgbo3 <= rgbo1;
	else if (shift) begin
		case(color_depth)
		BPP6:	rgbo3 <= {rgbo3[127:6]};
		BPP8:	rgbo3 <= {rgbo3[127:8]};
		BPP12:	rgbo3 <= {rgbo3[127:12]};
		BPP16:	rgbo3 <= {rgbo3[127:16]};
		BPP24:	rgbo3 <= {rgbo3[127:24]};
		BPP32:	rgbo3 <= {rgbo3[127:32]};
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

rtfVideoFifo3 uf1
(
	.wrst(fifo_wrst),
	.wclk(m_clk_i),
	.wr(m_ack_i && state==WAITLOAD),
	.di(m_dat_i),
	.rrst(fifo_rrst),
	.rclk(vclk),
	.rd(rd_fifo),
	.dout(rgbo1),
	.cnt(fifo_cnt)
);

endmodule
