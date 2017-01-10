`timescale 1ns / 1ps
//=============================================================================
//        __
//   \\__/ o\    (C) 2012-2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//
// rtfGraphicsAccelerator.v
// - performs line draw
// - pixel plotting
// - pixel fetch
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
//=============================================================================
//
`define NULL		8'd0
`define DRAW_PIXEL	8'd1
`define DRAW_LINE	8'd2
`define LINETO		8'd3
`define RECTANGLE	8'd4
`define RECTANGLE2	8'd5
`define RECTANGLE3	8'd6
`define RECTANGLE4	8'd7
`define GET_PIXEL	8'd8
`define FILL_RECT	8'd9
`define FILL_RECT2	8'd10
`define FILL_RECT3	8'd11
`define FILL_RECT4	8'd12
`define FILL_RECT5	8'd13
`define TRIANGLE	8'd14
`define TRIANGLE2	8'd15
`define TRIANGLE3	8'd16

`define ROP_COPY	4'd0
`define ROP_XOR		4'd1
`define ROP_AND		4'd2
`define ROP_OR		4'd3

module rtfGraphicsAccelerator (
rst_i,
clk_i,

s_cyc_i,
s_stb_i,
s_we_i,
s_ack_o,
s_sel_i,
s_adr_i,
s_dat_i,
s_dat_o,

m_cyc_o,
m_stb_o,
m_we_o,
m_ack_i,
m_sel_o,
m_adr_o,
m_dat_i,
m_dat_o
);
parameter PPL = 16'd1364;		// pixels per line
parameter IDLE = 8'd0;
parameter DRAWPIXEL = 8'd1;
parameter DL_SETPIXEL = 8'd2;
parameter DL_CALCE2 = 8'd3;
parameter DL_TEST = 8'd4;
parameter DL_TEST2 = 8'd5;
parameter DL_GETPIXEL = 8'd6;
parameter GETPIXEL = 8'd8;
parameter DL_PRECALC = 8'd9;
parameter DP_PRECALC = 8'd10;

input rst_i;
input clk_i;

input s_cyc_i;
input s_stb_i;
output s_ack_o;
input s_we_i;
input [3:0] s_sel_i;
input [31:0] s_adr_i;
input [31:0] s_dat_i;
output [31:0] s_dat_o;
reg [31:0] s_dat_o;

output m_cyc_o;
reg m_cyc_o;
output m_stb_o;
reg m_stb_o;
output m_we_o;
reg m_we_o;
input m_ack_i;
output [3:0] m_sel_o;
reg [3:0] m_sel_o;
output [31:0] m_adr_o;
reg [31:0] m_adr_o;
input [31:0] m_dat_i;
output [31:0] m_dat_o;
reg [31:0] m_dat_o;

reg [7:0] cmd;
reg [3:0] rop;
reg ps;						// pen select
reg [7:0] PenColor8;
reg [15:0] PenColor16;
reg [31:0] PenColor32;
reg [7:0] FillColor8;
reg [23:0] PenColor;
reg [23:0] FillColor;
reg [7:0] pxreg8;
reg [15:0] pxreg16;
reg [23:0] pxreg24;
reg [31:0] pxreg32;
reg [1:0] color_depth;
always @(color_depth)
	case(color_depth)
	2'b00:		pxreg24 <= {pxreg8[7:5],5'b0,pxreg8[4:2],5'b0,pxreg8[1:0],6'b0};
	2'b01:		pxreg24 <= {pxreg16[14:10],3'b000,pxreg16[9:5],3'b000,pxreg16[4:0],3'b000};
	default:	pxreg24 <= pxreg32[23:0];
	endcase
reg [13:0] x0,y0,x1,y1,x2,y2;
reg [13:0] x0a,y0a,x1a,y1a,x2a,y2a;
wire signed [13:0] absx1mx0 = (x1 < x0) ? x0-x1 : x1-x0;
wire signed [13:0] absy1my0 = (y1 < y0) ? y0-y1 : y1-y0;

reg [11:0] x0buf [0:2047];
reg [11:0] y0buf [0:2047];
reg [11:0] x1buf [0:2047];
reg [11:0] y1buf [0:2047];

/*wire [11:0] ytop = y0 < y1 && y0 < y2 ? y0 : y1 < y0 && y1 < y2 ? y1 : y2;
wire [11:0] xtop = y0 < y1 && y0 < y2 ? x0 : y1 < y0 && y1 < y2 ? x1 : x2;
wire [11:0] xleft = x0 < x1 && x0 < x2 ? x0 : x1 < x0 && x1 < x2 ? x1 : x2;
wire [11:0] yleft = x0 < x1 && x0 < x2 ? y0 : x1 < x0 && x1 < y2 ? x1 : y2;
*/
reg [11:0] ppl;
reg [13:0] cx,cy;			// graphics cursor position
wire [31:0] baseAddr = 32'h0040_0000;
wire [31:0] cyPPL = cy * ppl;
wire [31:0] offset = cyPPL + cx;
reg [31:0] offset2;
always @(color_depth)
	case(color_depth)
	2'b00:	offset2 <= offset;
	2'b01:	offset2 <= {offset,1'b0};
	2'b10:	offset2 <= 32'd0;	// not supported
	2'b11:	offset2 <= {offset,2'b00};
	endcase
wire [31:0] ma = baseAddr + offset2;
reg signed [13:0] dx,dy;
reg signed [13:0] sx,sy;
reg signed [13:0] err;
wire signed [13:0] e2 = err << 1;
reg [7:0] state;

wire cs = s_cyc_i && s_stb_i && (s_adr_i[31:12]==20'hFFDAE);
reg ack1;
always @(posedge clk_i)
	ack1 <= cs;

assign s_ack_o = cs ? (s_we_i ? 1'b1 : ack1):1'b0;

always @(posedge clk_i)
if (rst_i) begin
	m_cyc_o <= 1'b0;
	m_stb_o <= 1'b0;
	m_we_o <= 1'b0;
	m_sel_o <= 4'h0;
	m_dat_o <= 32'd0;
	m_adr_o <= 32'd0;
	s_dat_o <= 32'd0;

	x0 <= 14'd0;
	y0 <= 14'd0;
	x1 <= 14'd0;
	y1 <= 14'd0;
	x2 <= 14'd0;
	y2 <= 14'd0;
	cx <= 14'd0;
	cy <= 14'd0;
	color_depth <= 2'b00;
	ppl <= 12'd680;
	rop <= `ROP_COPY;
	cmd <= `NULL;
	state <= IDLE;
end
else begin
	if (cs & s_we_i) begin
		case(s_adr_i[9:2])
		8'd0:	begin
					PenColor[23:0] <= s_dat_i[23:0];
					PenColor8[7:5] <= s_dat_i[23:21];
					PenColor8[4:2] <= s_dat_i[15:13];
					PenColor8[1:0] <= s_dat_i[7:6];
					PenColor16[14:10] <= s_dat_i[23:19];
					PenColor16[9:5] <= s_dat_i[15:11];
					PenColor16[4:0] <= s_dat_i[7:3];
					PenColor32 <= s_dat_i;
				end
		8'd1:	begin
					FillColor[23:0] <= s_dat_i[23:0];
					FillColor8[7:5] <= s_dat_i[23:21];
					FillColor8[4:2] <= s_dat_i[15:13];
					FillColor8[1:0] <= s_dat_i[7:6];
				end
		8'd2:	x0 <= s_dat_i[13:0];
		8'd3:	y0 <= s_dat_i[13:0];
		8'd4:	x1 <= s_dat_i[13:0];
		8'd5:	y1 <= s_dat_i[13:0];
		8'd6:	x2 <= s_dat_i[13:0];
		8'd7:	y2 <= s_dat_i[13:0];
		8'd8:	
				begin
					ppl <= s_dat_i[11:0];
					color_depth <= s_dat_i[15:14];
				end
		8'd9:	rop <= s_dat_i[3:0];
		8'd15:	begin
				cmd <= s_dat_i[7:0];
`ifdef FILL_RECT
				case(s_dat_i[7:0])
				`FILL_RECT:
					begin
						if (x0 > x1) begin x1 <= x0; x0 <= x1; end
						if (y0 > y1) begin y1 <= y0; y0 <= y1; end
					end
				endcase
`endif
				end
		endcase
	end
	if (cs) begin
		case(s_adr_i[9:2])
		8'd13:	s_dat_o <= pxreg24;
		8'd14:	s_dat_o <= state;	// reg 14
		default:	s_dat_o <= 32'd0;
		endcase
	end
	else
		s_dat_o <= 32'd0;

case(state)
IDLE:
	begin
		cx <= x0;
		cy <= y0;
		dx <= absx1mx0;
		dy <= absy1my0;
		if (x0 < x1) sx <= 14'h0001; else sx <= 14'h3FFF;
		if (y0 < y1) sy <= 14'h0001; else sy <= 14'h3FFF;
		err <= absx1mx0-absy1my0;
		case(cmd)
		`GET_PIXEL:
			begin
			state <= GETPIXEL;
			cmd <= `NULL;
			end
		`DRAW_PIXEL:
			begin
			state <= DP_PRECALC;
			cmd <= `NULL;
			end
		`DRAW_LINE:
			begin
			state <= DL_PRECALC;
			cmd <= `NULL;
			end
		`LINETO:
			begin
			x1 <= x0;
			y1 <= y0;
			x0 <= cx;
			y0 <= cy;
			cmd <= `DRAW_LINE;
			end
		`RECTANGLE:
			begin
			x0a <= x0;
			y0a <= y0;
			x1a <= x1;
			y1a <= y1;
			y1 <= y0;
			cmd <= `RECTANGLE2;
			state <= DL_PRECALC;
			end
		`RECTANGLE2:
			begin
			x0 <= x1a;
			y0 <= y0a;
			x1 <= x1a;
			y1 <= y1a;
			cmd <= `RECTANGLE3;
			state <= DL_PRECALC;
			end
		`RECTANGLE3:
			begin
			y0 <= y1a;
			x0 <= x1a;
			x1 <= x0a;
			y1 <= y1a;
			cmd <= `RECTANGLE4;
			state <= DL_PRECALC;
			end
		`RECTANGLE4:
			begin
			x0 <= x0a;
			y0 <= y1a;
			x1 <= x0a;
			y1 <= y0a;
			cmd <= `NULL;
			state <= DL_PRECALC;
			end
		`TRIANGLE:
			begin
			x0a <= x0;
			y0a <= y0;
			x1a <= x1;
			y1a <= y1;
			x2a <= x2;
			y2a <= y2;
			cmd <= `TRIANGLE2;
			state <= DL_PRECALC;
			end
		`TRIANGLE2:
			begin
			x0 <= x1a;
			y0 <= y1a;
			x1 <= x2a;
			y1 <= y2a;
			cmd <= `TRIANGLE3;
			state <= DL_PRECALC;
			end
		`TRIANGLE3:
			begin
			y0 <= y0a;
			x0 <= x0a;
			x1 <= x2a;
			y1 <= y2a;
			cmd <= `NULL;
			state <= DL_PRECALC;
			end
`ifdef FILL_RECT
		`FILL_RECT:
			begin
			x0a <= x0;
			y0a <= y0;
			x1a <= x1;
			y1a <= y1;
			y1 <= y0;
			cmd <= `FILL_RECT2;
			state <= DL_SETPIXEL;
			end
		`FILL_RECT2:
			begin
			x0 <= x1a;
			y0 <= y0a;
			x1 <= x1a;
			y1 <= y1a;
			cmd <= `FILL_RECT3;
			state <= DL_SETPIXEL;
			end
		`FILL_RECT3:
			begin
			y0 <= y1a;
			x0 <= x1a;
			x1 <= x0a;
			y1 <= y1a;
			cmd <= `FILL_RECT4;
			state <= DL_SETPIXEL;
			end
		`FILL_RECT4:
			begin
			x0 <= x0a;
			y0 <= y1a;
			x1 <= x0a;
			y1 <= y0a;
			cmd <= `FILL_RECT5;
			state <= DL_SETPIXEL;
			end
		`FILL_RECT5:
			begin
				if (x0a>=x1a && y0a>=y1a) begin
					cmd <= `NULL;
					state <= IDLE;
				end
				else if (x0a>=x1a) begin
					y0 <= y0a + 14'd1;
					y1 <= y1a - 14'd1;
					x0 <= x0a;
					x1 <= x1a;
					cmd <= `FILL_RECT;
				end
				else if (y0a >= y1a) begin
					x0 <= x0a + 14'd1;
					x1 <= x1a - 14'd1;
					y0 <= y0a;
					y1 <= y1a;
					cmd <= `FILL_RECT;
				end
				else begin
					y0 <= y0a + 14'd1;
					y1 <= y1a - 14'd1;
					x0 <= x0a + 14'd1;
					x1 <= x1a - 14'd1;
					cmd <= `FILL_RECT;
				end
			end
`endif
		endcase
	end

DP_PRECALC:
	begin
		cx <= x0;
		cy <= y0;
		if (rop != `ROP_COPY)
			state <= GETPIXEL;
		else
			state <= DRAWPIXEL;
	end

GETPIXEL:
	if (!m_cyc_o) begin
		m_cyc_o <= 1'b1;
		m_stb_o <= 1'b1;
		wb_m_sel(color_depth,ma);
		m_adr_o <= {ma[31:2],2'b00};
	end
	else if (m_ack_i) begin
		wb_m_nack();
		state <= IDLE;
	end

DRAWPIXEL:
	if (!m_cyc_o)
		wb_m_write();
	else if (m_ack_i) begin
		wb_m_nack();
		state <= IDLE;
	end

// State to setup invariants for DRAWLINE
DL_PRECALC:
	begin
		cx <= x0;
		cy <= y0;
		dx <= absx1mx0;
		dy <= absy1my0;
		if (x0 < x1) sx <= 14'h0001; else sx <= 14'h3FFF;
		if (y0 < y1) sy <= 14'h0001; else sy <= 14'h3FFF;
		err <= absx1mx0-absy1my0;
		if (rop != `ROP_COPY)
			state <= DL_GETPIXEL;
		else
			state <= DL_SETPIXEL;
	end

DL_GETPIXEL:
	if (!m_cyc_o) begin
		m_cyc_o <= 1'b1;
		m_stb_o <= 1'b1;
		wb_m_sel(color_depth,ma);
		m_adr_o <= {ma[31:2],2'b00};
	end
	else if (m_ack_i) begin
		wb_m_nack();
		state <= DL_SETPIXEL;
	end

DL_SETPIXEL:
	if (!m_cyc_o)
		wb_m_write();
	else if (m_ack_i) begin
		wb_m_nack();
		if (cx==x1 && cy==y1)
			state <= IDLE;
		else
			state <= DL_TEST;
	end
DL_TEST:
	begin
		err <= err - ((e2 > -dy) ? dy : 14'd0) + ((e2 < dx) ? dx : 14'd0);
		if (e2 > -dy)
			cx <= cx + sx;
		if (e2 <  dx)
			cy <= cy + sy;
		if (rop != `ROP_COPY)
			state <= DL_GETPIXEL;
		else
			state <= DL_SETPIXEL;
	end

endcase
end

task wb_m_sel;
input [1:0] cd;
input [31:0] ad;
begin
	case(cd)
	2'b00:
		case(ad[1:0])
		2'd0:	m_sel_o <= 4'b0001;
		2'd1:	m_sel_o <= 4'b0010;
		2'd2:	m_sel_o <= 4'b0100;
		2'd3:	m_sel_o <= 4'b1000;
		endcase
	2'b01:
		m_sel_o <= ad[1] ? 4'b1100 : 4'b0011;
	default:	m_sel_o <= 4'b1111;
	endcase
end
endtask

task wb_m_write;
begin
	m_cyc_o <= 1'b1;
	m_stb_o <= 1'b1;
	m_we_o <= 1'b1;
	wb_m_sel(color_depth,ma);
	m_adr_o <= {ma[31:2],2'b00};
	case(rop)
	`ROP_COPY:
		case(color_depth)
		2'b00:	m_dat_o <= {4{PenColor8}};
		2'b01:	m_dat_o <= {2{PenColor16}};
		default:	m_dat_o <= PenColor32;
		endcase
	`ROP_XOR:
		case(color_depth)
		2'b00:	m_dat_o <= {4{PenColor8}} ^ {4{pxreg8}};
		2'b01:	m_dat_o <= {2{PenColor16}}  ^ {2{pxreg16}};
		default:	m_dat_o <= PenColor32 ^ pxreg32;
		endcase
	`ROP_AND:
		case(color_depth)
		2'b00:	m_dat_o <= {4{PenColor8}} & {4{pxreg8}};
		2'b01:	m_dat_o <= {2{PenColor16}}  & {2{pxreg16}};
		default:	m_dat_o <= PenColor32 & pxreg32;
		endcase
	`ROP_OR:
		case(color_depth)
		2'b00:	m_dat_o <= {4{PenColor8}} | {4{pxreg8}};
		2'b01:	m_dat_o <= {2{PenColor16}}  | {2{pxreg16}};
		default:	m_dat_o <= PenColor32 | pxreg32;
		endcase
	endcase
end
endtask

task wb_m_nack;
begin
	m_cyc_o <= 1'b0;
	m_stb_o <= 1'b0;
	m_sel_o <= 4'b0000;
	m_we_o <= 1'b0;
	case(m_sel_o)
	4'b0001:	pxreg8 <= m_dat_i[7:0];
	4'b0010:	pxreg8 <= m_dat_i[15:8];
	4'b0100:	pxreg8 <= m_dat_i[23:16];
	4'b1000:	pxreg8 <= m_dat_i[31:24];
	4'b0011:	pxreg16 <= m_dat_i[15:0];
	4'b1100:	pxreg16 <= m_dat_i[31:16];
	default:	pxreg32 <= m_dat_i;
	endcase
end
endtask

endmodule

//function line(x0, y0, x1, y1)
//   dx := abs(x1-x0)
//   dy := abs(y1-y0) 
//;   if x0 < x1 then sx := 1 else sx := -1
//;   if y0 < y1 then sy := 1 else sy := -1
//;   err := dx-dy
//; 
//;//   loop
//;     setPixel(x0,y0)
//;     if x0 = x1 and y0 = y1 exit loop
//;     e2 := 2*err
//;     if e2 > -dy then 
//;       err := err - dy
//;       x0 := x0 + sx
//;     end if
//;     if e2 <  dx then 
//;       err := err + dx
//;       y0 := y0 + sy 
//;     end if
//;   end loop
