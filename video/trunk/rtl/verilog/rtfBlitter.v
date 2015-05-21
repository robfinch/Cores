// ============================================================================
//        __
//   \\__/ o\    (C) 2015  Robert Finch, Stratford
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
// ============================================================================
//
// General:
// The blitter image and bitmap registers must be setup, then the blitter
// will accept commands to be performed between images. The status register
// must be polled to determine when the blitter is finished an operation.
//
// The blitter command format is:
// | opcode2 | opcode1 | target,source1,source2 |
// |    6    |    6    |   6       6       6    |
//
// opcode 1 is applied between target and source1
// opcode 2 is applied to the result of opcode 1 and source 2
//
// opcode
// abrrrr
// ||++++ = raster operation
// |+---- = 1 = invert b operand
// +----- = 1 = invert a operand
//
// Raster operations
// 
// rrrr
// 0000 all zereo's
// 0001 A
// 0010 B
// 0011 A AND B
// 0100 A OR B
// 0101 A XOR B
// 0110 A ADD B
// 0111 A SUB B
// 1000 A MUL B
// 1111 all ones
//
// Image Descriptors
// - Normally there are numerous images associated with an application.
// - The blitter allows for 64 image descriptors to be registered at once.
// - The most time critical images may be resident others will have to be
//   swapped with memory.
//
// Regno
// 0x000   [12: 0] image x position within bitmap
//         [28:16] image y position within bitmap
// 0x004   [12: 0] image width in pixels
//         [28:16] image height in pixels
// 0x008   [31: 0] reserved
// 0x00C   [ 3: 0] image bitmap descriptor index
//         [ 9: 8] image corner
//         [16:16] pattern indicator
//
// 0x010 to 0x3FC	repeat of 0x000 to 0x00C for 63 more images
//
// Bitmap Desciptors
// - Bitmap descriptors describe the size and location of the bitmap in memory
// - Usually multiple images are stored in a bitmap and there may be multiple
//   bitmaps associated with an application.
// - The blitter stores descriptor information for up to 16 bitmaps.
// - There is usually a single target bitmap from which the display is rendered.
//
// Regno
// 0x800   [12: 0] bitmap width
//         [28:16] bitmap height
// 0x804   [31: 0] bitmap base address
// 0x808   [ 3: 0] bitmap color depth
//
// 0x810 to 0x8FC
//			Same as 0x800-0x80C but for 15 more bitmap descriptors
// 
// GLobal Registers
// 0xF00   [31: 0] command reg
// 0xF10   [31: 0] status reg
//
// Image Corner:
// - Determines which corner of the image to begin the transfer at. Useful when
//   source and destination images overlap.
//
// Pattern Indicator:
// - Indicates that the image is a pattern to be used to fill an area. In the
//   case of a pattern the pattern size may be smaller than the target fill
//   area. Indexes into the pattern will wrap around so that the pattern repeats
//   in the target fill area.
//
// 3200 LUTs (5120 LC's)
//
module rtfBlitter(rst_i,
	s_clk_i, s_cyc_i, s_stb_i, s_ack_o, s_we_i, s_sel_i, s_adr_i, s_dat_i, s_dat_o,
	m_clk_i, m_bte_o, m_cti_o, m_cyc_o, m_stb_o, m_ack_i, m_err_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o
);
input rst_i;

input s_clk_i;
input s_cyc_i;
input s_stb_i;
output s_ack_o;
input s_we_i;
input [3:0] s_sel_i;
input [31:0] s_adr_i;
input [31:0] s_dat_i;
output reg [31:0] s_dat_o;

input m_clk_i;
output [1:0] m_bte_o;
output [2:0] m_cti_o;
output reg m_cyc_o;
output m_stb_o;
input m_ack_i;
input m_err_i;
output reg m_we_o;
output [15:0] m_sel_o;
output reg [31:0] m_adr_o;
input [127:0] m_dat_i;
output reg [127:0] m_dat_o;

`include "gfx_bpp.v"

parameter ALLZEROS = 4'd0;
parameter PASS_A = 4'd1;
parameter PASS_B = 4'd2;
parameter AND = 4'd3;
parameter OR  = 4'd4;
parameter XOR = 4'd5;
parameter ADD = 4'd6;
parameter SUB = 4'd7;
parameter MUL = 4'd8;
parameter ALLONES = 4'd15;

reg [31:0] command;
reg [5:0] image_a,image_b,image_t;
reg [5:0] rop1,rop2;

reg [31:0] bitmap_base [15:0];
reg [11:0] bitmap_width [15:0];
reg [11:0] bitmap_height [15:0];
reg [ 3:0] bitmap_color_depth [15:0];

reg [12:0] image_x [63:0];
reg [12:0] image_y [63:0];
reg [12:0] image_width [63:0];
reg [12:0] image_height [63:0];
reg [3:0]  image_desc [63:0];
reg [1:0]  image_corner [63:0];
reg image_pattern [63:0];

reg [31:0] base_addr;
reg [3:0] color_depth;
reg [11:0] hdisplayed;
wire [6:0] mb, me;
reg signed [12:0] x_coord, y_coord, x_count, y_count;
reg signed [12:0] xb_count, yb_count;
wire [31:0] addr;
reg signed [12:0] x_limit,y_limit;
reg signed [12:0] x_inc,y_inc;
reg signed [12:0] x_start,y_start;

wire cs = s_cyc_i && s_stb_i && (s_adr_i[31:12]==20'hFFDAF);

reg [5:0] state;
parameter IDLE = 6'd1;
parameter FETCH_A = 6'd2;
parameter FETCH_A1 = 6'd3;
parameter FETCH_A2 = 6'd4;
parameter FETCH_A3 = 6'd5;
parameter FETCH_A4 = 6'd6;
parameter FETCH_B = 6'd8;
parameter FETCH_B1 = 6'd9;
parameter FETCH_B2 = 6'd10;
parameter FETCH_B3 = 6'd11;
parameter FETCH_B4 = 6'd12;
parameter FETCH_T = 6'd16;
parameter FETCH_T1 = 6'd17;
parameter FETCH_T2 = 6'd18;
parameter FETCH_T3 = 6'd19;
parameter FETCH_T4 = 6'd20;
parameter NEXT_PIXEL = 6'd24;
parameter NEXT_IMAGE = 6'd25;
parameter PROC_CMD = 6'd26;
parameter FETCH = 6'd27;
parameter STORE_T = 6'd28;
parameter STORE_T1 = 6'd29;
parameter ROP1 = 6'd30;
parameter ROP2 = 6'd31;

always @(posedge s_clk_i)
if (rst_i) begin
	s_dat_o <= 32'd0;
	command <= 32'd0;
end
else begin
	if (cs) begin
		if (s_we_i) begin
			casex(s_adr_i[11:0])
			12'b0xxx_xxx0_00xx:
				begin
				if (s_sel_i[0]) image_x[s_adr_i[10:5]] <= s_dat_i[12: 0];
				if (s_sel_i[2]) image_y[s_adr_i[10:5]] <= s_dat_i[28:16];
				end
			12'b0xxx_xxx0_01xx:
				begin
				if (s_sel_i[0]) image_width[s_adr_i[10:5]] <= s_dat_i[11: 0];
				if (s_sel_i[2]) image_height[s_adr_i[10:5]] <= s_dat_i[28:16];
				end
//			12'b0xxx_xxx0_10xx:
//				image_tc[s_adr_i[10:5]] <= s_dat_i;
			12'b0xxx_xxx0_11xx:
				begin
				if (s_sel_i[0]) image_desc[s_adr_i[10:5]] <= s_dat_i[3:0];
				if (s_sel_i[1]) image_corner[s_adr_i[10:5]] <= s_dat_i[9:8];
				if (s_sel_i[2]) image_pattern[s_adr_i[10:5]] <= s_dat_i[16];
				end
			12'b1000_xxxx_00xx:
				begin
				if (s_sel_i[0]) bitmap_width[s_adr_i[7:4]] <= s_dat_i[11:0];
				if (s_sel_i[2]) bitmap_height[s_adr_i[7:4]] <= s_dat_i[27:16];
				end
			12'b1000_xxxx_01xx:
				bitmap_base[s_adr_i[7:4]] <= s_dat_i;
			12'b1000_xxxx_10xx:
				bitmap_color_depth[s_adr_i[7:4]] <= s_dat_i[3:0];
			12'b1001_0000_00xx:
				command <= s_dat_i;
			endcase
		end
		casex(s_adr_i[11:0])
		12'b1001_0001_00xx:	s_dat_o <= {state==IDLE,31'd0};
		endcase
	end
	else
		s_dat_o <= 32'd0;
end

gfx_CalcAddress u1
(
	.clk(m_clk_i),
	.base_address_i(base_addr),
	.color_depth_i(color_depth),
	.hdisplayed_i(hdisplayed),
	.x_coord_i(x_coord[11:0]),
	.y_coord_i(y_coord[11:0]),
	.address_o(addr),
	.mb_o(mb),
	.me_o(me)
);

reg [127:0] mem_dat;
wire [31:0] pixel;
reg [31:0] color_a,color_b,color_t;
reg [31:0] color_a1,color_b1,color_c1,color_r1,color_t1,color_t2;
reg [31:0] r,t;
reg [9:0] rr,rg,rb,tr,tg,tb;
reg [9:0] color_r1r,color_r1g,color_r1b;
reg [9:0] color_t2r,color_t2g,color_t2b;

mem2color um2c
(
	.mem_i(mem_dat),
	.mb_i(mb),
	.me_i(me),
	.color_o(pixel)
);

wire [127:0] memo_dat;
color2mem uc2m
(
	.mem_i(mem_dat),
	.mb_i(mb),
	.me_i(me),
	.color_i(color_t2),
	.mem_o(memo_dat)
);

wire [9:0] color_t1r,color_t1g,color_t1b;
gfx_SplitColorR uscr1(color_depth, color_t1, color_t1r);
gfx_SplitColorG uscg1(color_depth, color_t1, color_t1g);
gfx_SplitColorB uscb1(color_depth, color_t1, color_t1b);

wire [9:0] color_a1r,color_a1g,color_a1b;
gfx_SplitColorR uscr2(color_depth, color_a1, color_a1r);
gfx_SplitColorG uscg2(color_depth, color_a1, color_a1g);
gfx_SplitColorB uscb2(color_depth, color_a1, color_a1b);

wire [9:0] color_b1r,color_b1g,color_b1b;
gfx_SplitColorR uscr3(color_depth, color_b1, color_b1r);
gfx_SplitColorG uscg3(color_depth, color_b1, color_b1g);
gfx_SplitColorB uscb3(color_depth, color_b1, color_b1b);

always @*
case(color_depth)
BPP3:	color_t2 <= {color_t2r[0],color_t2g[0],color_t2b[0]};
BPP6:	color_t2 <= {color_t2r[1:0],color_t2g[1:0],color_t2b[1:0]};
BPP8:	color_t2 <= {color_t2r[2:0],color_t2g[2:0],color_t2b[1:0]};
BPP9:	color_t2 <= {color_t2r[2:0],color_t2g[2:0],color_t2b[2:0]};
BPP12:	color_t2 <= {color_t2r[3:0],color_t2g[3:0],color_t2b[3:0]};
BPP15:	color_t2 <= {color_t2r[4:0],color_t2g[4:0],color_t2b[4:0]};
BPP16:	color_t2 <= {color_t2r[4:0],color_t2g[5:0],color_t2b[4:0]};
BPP18:	color_t2 <= {color_t2r[5:0],color_t2g[5:0],color_t2b[5:0]};
BPP21:	color_t2 <= {color_t2r[6:0],color_t2g[6:0],color_t2b[6:0]};
BPP24:	color_t2 <= {color_t2r[7:0],color_t2g[7:0],color_t2b[7:0]};
BPP27:	color_t2 <= {color_t2r[8:0],color_t2g[8:0],color_t2b[8:0]};
BPP30:	color_t2 <= {color_t2r[9:0],color_t2g[9:0],color_t2b[9:0]};
BPP32:	color_t2 <= {color_t2r[7:0],color_t2g[7:0],color_t2b[7:0]};
endcase

assign m_bte_o = 2'b00;
assign m_cti_o = 3'b000;
assign m_stb_o = 1'b1;
assign m_sel_o = 16'hFFFF;

reg [3:0] source_ndx;
reg [31:0] ocmd;

always @(posedge m_clk_i)
if (rst_i) begin
	state <= IDLE;
	ocmd <= 32'h0;
end
else begin
case(state)
IDLE:
	begin
		if (command != ocmd)
			state <= PROC_CMD;
	end

PROC_CMD:
	begin
		ocmd <= command;
		color_a <= 32'd0;
		color_b <= 32'd0;
		color_t <= 32'd0;
		image_a <= command[ 5: 0];
		image_b <= command[11: 6];
		image_t <= command[17:12];
		rop1 <= command[23:18];
		rop2 <= command[29:24];
		state <= NEXT_IMAGE;
	end

FETCH_A:
	begin
		source_ndx <= image_desc[image_a];
		state <= FETCH_A1;
	end
FETCH_A1:
	begin
		base_addr <= bitmap_base[source_ndx];
		color_depth <= bitmap_color_depth[source_ndx];
		hdisplayed <= bitmap_width[source_ndx];
		x_coord <= image_x[image_a] + x_count;
		y_coord <= image_y[image_a] + y_count;
		state <= FETCH_A2;
	end
FETCH_A2:
	begin
		m_cyc_o <= 1'b1;
		m_adr_o <= addr;
		state <= FETCH_A3;
	end
FETCH_A3:
	if (m_ack_i) begin
		m_cyc_o <= 1'b0;
		mem_dat <= m_dat_i;
		state <= FETCH_A4;
	end
FETCH_A4:
	begin
		if (color_depth==BPP1)
			color_a <= {32{pixel}};
		else
			color_a <= pixel;
		if (command[21:18]!=4'b0000 && command[21:18]!=4'hF && command[21:18]!=4'b0001)
			state <= FETCH_B;
		else
			state <= FETCH_T;
	end

FETCH_B:
	begin
		source_ndx <= image_desc[image_b];
		state <= FETCH_B1;
	end
FETCH_B1:
	begin
		base_addr <= bitmap_base[source_ndx];
		color_depth <= bitmap_color_depth[source_ndx];
		hdisplayed <= bitmap_width[source_ndx];
		x_coord <= image_x[image_b] + xb_count;
		y_coord <= image_y[image_b] + yb_count;
		state <= FETCH_B2;
	end
FETCH_B2:
	begin
		m_cyc_o <= 1'b1;
		m_adr_o <= addr;
		state <= FETCH_B3;
	end
FETCH_B3:
	if (m_ack_i) begin
		m_cyc_o <= 1'b0;
		mem_dat <= m_dat_i;
		state <= FETCH_B4;
	end
FETCH_B4:
	begin
		color_b <= pixel;
		state <= FETCH_T;
	end

FETCH_T:
	begin
		source_ndx <= image_desc[image_t];
		state <= FETCH_T1;
	end
FETCH_T1:
	begin
		base_addr <= bitmap_base[source_ndx];
		color_depth <= bitmap_color_depth[source_ndx];
		hdisplayed <= bitmap_width[source_ndx];
		x_coord <= image_x[image_t] + x_count;
		y_coord <= image_y[image_t] + y_count;
		state <= FETCH_T2;
	end
FETCH_T2:
	begin
		if (x_coord >= 0 && x_coord < image_width[image_t] &&
			y_coord >= 0 && y_coord < image_height[image_t]) begin
			m_cyc_o <= 1'b1;
			m_adr_o <= addr;
			state <= FETCH_T3;
		end
		else
			state <= NEXT_PIXEL;
	end
FETCH_T3:
	if (m_ack_i) begin
		m_cyc_o <= 1'b0;
		mem_dat <= m_dat_i;
		state <= FETCH_T4;
	end
FETCH_T4:
	begin
		color_t <= pixel;
		state <= ROP1;
	end

ROP1:
	begin
		color_t1 = command[22] ? ~color_t : color_t;
		color_a1 = command[23] ? ~color_a : color_a;
		case(command[21:18])
		ALLZEROS:
				begin
				rr <= 10'd0;
				rg <= 10'd0;
				rb <= 10'd0;
				end
		PASS_A:	begin
				rr <= color_t1r;
				rg <= color_t1g;
				rb <= color_t1b;
				end
		PASS_B:	begin
				rr <= color_a1r;
				rg <= color_a1g;
				rb <= color_a1b;
				end
		AND:	begin
				rr <= color_t1r & color_a1r;
				rg <= color_t1g & color_a1g;
				rb <= color_t1b & color_a1b;
				end
		OR:		begin
				rr <= color_t1r | color_a1r;
				rg <= color_t1g | color_a1g;
				rb <= color_t1b | color_a1b;
				end
		XOR:	begin
				rr <= color_t1r ^ color_a1r;
				rg <= color_t1g ^ color_a1g;
				rb <= color_t1b ^ color_a1b;
				end
		ADD:	begin
				rr <= color_t1r + color_a1r;
				rg <= color_t1g + color_a1g;
				rb <= color_t1b + color_a1b;
				end
		SUB:	begin
				rr <= color_t1r - color_a1r;
				rg <= color_t1g - color_a1g;
				rb <= color_t1b - color_a1b;
				end
		MUL:	begin
				rr <= color_t1r * color_a1r;
				rg <= color_t1g * color_a1g;
				rb <= color_t1b * color_a1b;
				end
		ALLONES:
				begin
				rr <= 10'h3FF;
				rg <= 10'h3FF;
				rb <= 10'h3FF;
				end
		endcase
		state <= ROP2;
	end

ROP2:
	begin
		color_r1r = command[29] ? ~rr : rr;
		color_r1g = command[29] ? ~rg : rg;
		color_r1b = command[29] ? ~rb : rb;
		color_b1 = command[28] ? ~color_b : color_b;
		case(command[27:24])
		ALLZEROS:
				begin
				tr = 10'd0;
				tg = 10'd0;
				tb = 10'd0;
				end
		PASS_A:	begin
				tr = color_r1r;
				tg = color_r1g;
				tb = color_r1b;
				end
		PASS_B:	begin
				tr = color_b1r;
				tg = color_b1g;
				tb = color_b1b;
				end
		AND:	begin
				tr = color_r1r & color_b1r;
				tg = color_r1g & color_b1g;
				tb = color_r1b & color_b1b;
				end
		OR:		begin
				tr = color_r1r | color_b1r;
				tg = color_r1g | color_b1g;
				tb = color_r1b | color_b1b;
				end
		XOR:	begin
				tr = color_r1r ^ color_b1r;
				tg = color_r1g ^ color_b1g;
				tb = color_r1b ^ color_b1b;
				end
		ADD:	begin
				tr = color_r1r + color_b1r;
				tg = color_r1g + color_b1g;
				tg = color_r1g + color_b1b;
				end
		SUB:	begin
				tr = color_r1r - color_b1r;
				tg = color_r1g - color_b1g;
				tb = color_r1b - color_b1b;
				end
		MUL:	begin
				tr = color_r1r * color_b1r;
				tg = color_r1r * color_b1g;
				tb = color_r1r * color_b1b;
				end
		ALLONES:
				begin
				tr = 10'h3FF;
				tg = 10'h3FF;
				tb = 10'h3FF;
				end
		endcase
		color_t2r = command[29] ? ~tr : tr;
		color_t2g = command[29] ? ~tg : tg;
		color_t2b = command[29] ? ~tb : tb;
		state <= STORE_T;
	end

STORE_T:
	begin
		m_cyc_o <= 1'b1;
		m_we_o <= 1'b1;
		m_adr_o <= addr;
		m_dat_o <= memo_dat;
		state <= STORE_T1;
	end
STORE_T1:
	if (m_ack_i) begin
		m_cyc_o <= 1'b0;
		state <= NEXT_PIXEL;
	end

NEXT_PIXEL:
	begin
		if (x_count==x_limit) begin
			x_count <= x_start;
			if (y_count==y_limit)
				state <= IDLE;
			else begin
				y_count <= y_count + y_inc;
				state <= FETCH;
			end
		end
		else begin
			x_count <= x_count + x_inc;
			state <= FETCH;
		end
		if (image_pattern[image_b]) begin
			if (xb_count==image_width[image_b]-13'd1) begin
				xb_count <= 13'd0;
				if (yb_count==image_height[image_b]-13'd1) begin
					yb_count <= 13'd0;
				end
				else
					yb_count <= yb_count + 13'd1;
			end
			else
				xb_count <= xb_count + 13'd1;
		end
	end

NEXT_IMAGE:
	begin
		xb_count <= 13'd0;
		yb_count <= 13'd0;
		case(image_corner[image_t])
		2'b00:
			begin
			x_coord <= image_x[image_t];
			y_coord <= image_y[image_t];
			x_start <= image_x[image_t];
			y_start <= image_y[image_t];
			x_limit <= image_width[image_t];
			y_limit <= image_height[image_t];
			x_inc <= 13'd1;
			y_inc <= 13'd1;
			x_count <= 13'd0;
			y_count <= 13'd0;
			end
		2'b01:
			begin
			x_coord <= image_width[image_t]-13'd1;
			y_coord <= image_y[image_t];
			x_start <= image_width[image_t]-13'd1;
			y_start <= image_y[image_t];
			x_limit <= image_x[image_t];
			y_limit <= image_height[image_t];
			x_inc <= 13'h1FFF;
			y_inc <= 13'd1;
			x_count <= image_width[image_t]-13'd1;
			y_count <= 13'd0;
			end
		2'b10:
			begin
			x_coord <= image_width[image_t]-13'd1;
			y_coord <= image_height[image_t]-13'd1;
			x_start <= image_width[image_t]-13'd1;
			y_start <= image_height[image_t]-13'd1;
			x_limit <= image_x[image_t];
			y_limit <= image_y[image_t];
			x_inc <= 13'h1FFF;
			y_inc <= 13'h1FFF;
			x_count <= image_width[image_t]-13'd1;
			y_count <= image_height[image_t]-13'd1;
			end
		2'b11:
			begin
			x_coord <= image_x[image_t];
			y_coord	<= image_height[image_t]-13'd1;
			x_start <= image_x[image_t];
			y_start	<= image_height[image_t]-13'd1;
			x_limit <= image_width[image_t];
			y_limit <= image_y[image_t];
			x_inc <= 13'h1;
			y_inc <= 13'h1FFF;
			x_count <= 13'd0;
			y_count <= image_height[image_t]-13'd1;
			end
		endcase
		state <= FETCH;
	end

FETCH:
	begin
		if (!image_pattern[image_b]) begin
			xb_count <= x_count;
			yb_count <= y_count;
		end
		if (command[21:18]!=PASS_B)
			state <= FETCH_A;
		else if (command[27:24]!=PASS_B)
			state <= FETCH_B;
		else
			state <= FETCH_T;
	end

endcase
end

endmodule

