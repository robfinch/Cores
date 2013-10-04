`timescale 1ns / 1ps
//=============================================================================
//        __
//   \\__/ o\    (C) 2012-2013  Robert Finch, Stratford
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
parameter GETPIXEL = 8'd8;

input rst_i;
input clk_i;

input s_cyc_i;
input s_stb_i;
output s_ack_o;
input s_we_i;
input [3:0] s_sel_i;
input [33:0] s_adr_i;
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
reg ps;						// pen select
reg [7:0] PenColor8;
reg [7:0] FillColor8;
reg [23:0] PenColor;
reg [23:0] FillColor;
reg [7:0] pxreg8;
wire [23:0] pxreg24 = {pxreg8[7:5],5'b0,pxreg8[4:2],5'b0,pxreg8[1:0],6'b0};
reg [15:0] x0,y0,x1,y1,x2,y2;
reg [15:0] x0a,y0a,x1a,y1a;

reg [11:0] x0buf [0:2047];
reg [11:0] y0buf [0:2047];
reg [11:0] x1buf [0:2047];
reg [11:0] y1buf [0:2047];

/*wire [11:0] ytop = y0 < y1 && y0 < y2 ? y0 : y1 < y0 && y1 < y2 ? y1 : y2;
wire [11:0] xtop = y0 < y1 && y0 < y2 ? x0 : y1 < y0 && y1 < y2 ? x1 : x2;
wire [11:0] xleft = x0 < x1 && x0 < x2 ? x0 : x1 < x0 && x1 < x2 ? x1 : x2;
wire [11:0] yleft = x0 < x1 && x0 < x2 ? y0 : x1 < x0 && x1 < y2 ? x1 : y2;
*/
reg [15:0] cx,cy;			// graphics cursor position
wire [31:0] cyPPL = cy * PPL;
wire [31:0] ma = 32'h0040_0000 + cyPPL + cx;
reg signed [15:0] dx,dy;
reg signed [15:0] sx,sy;
reg signed [15:0] err;
wire signed [15:0] e2 = err << 1;
reg [7:0] state;

reg ack1;
always @(posedge clk_i)
	ack1 <= cs;

wire cs = s_cyc_i && s_stb_i && (s_adr_i[33:10]==24'hFFDAE0);
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

	x0 <= 16'd0;
	y0 <= 16'd0;
	x1 <= 16'd0;
	y1 <= 16'd0;
	x2 <= 16'd0;
	y2 <= 16'd0;
	cx <= 16'd0;
	cy <= 16'd0;
	state <= IDLE;
end
else begin
	if (cs & s_we_i) begin
		case(s_adr_i[5:2])
		8'd0:	begin
					PenColor[23:0] <= s_dat_i[23:0];
					PenColor8[7:5] <= s_dat_i[23:21];
					PenColor8[4:2] <= s_dat_i[15:13];
					PenColor8[1:0] <= s_dat_i[7:6];
				end
		8'd1:	begin
					FillColor[23:0] <= s_dat_i[23:0];
					FillColor8[7:5] <= s_dat_i[23:21];
					FillColor8[4:2] <= s_dat_i[15:13];
					FillColor8[1:0] <= s_dat_i[7:6];
				end
		8'd2:	x0 <= s_dat_i[15:0];
		8'd3:	y0 <= s_dat_i[15:0];
		8'd4:	x1 <= s_dat_i[15:0];
		8'd5:	y1 <= s_dat_i[15:0];
		8'd6:	x2 <= s_dat_i[15:0];
		8'd7:	y2 <= s_dat_i[15:0];
		8'd15:	cmd <= s_dat_i[15:0];
		endcase
	end
	if (cs) begin
		case(s_adr_i[5:2])
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
		dx <= x1 < x0 ? x0-x1 : x1-x0;
		dy <= y1 < y0 ? y0-y1 : y1-y0;
		sx <= x0 < x1 ? 1 : -1;
		sy <= y0 < y1 ? 1 : -1;
		err <= dx-dy;
		case(cmd)
		`GET_PIXEL:
			begin
			state <= GETPIXEL;
			cmd <= `NULL;
			end
		`DRAW_PIXEL:
			begin
			state <= DRAWPIXEL;
			cmd <= `NULL;
			end
		`DRAW_LINE:
			begin
			state <= DL_SETPIXEL;
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
			state <= DL_SETPIXEL;
			end
		`RECTANGLE2:
			begin
			x0 <= x1a;
			y0 <= y0a;
			x1 <= x1a;
			y1 <= y1a;
			cmd <= `RECTANGLE3;
			state <= DL_SETPIXEL;
			end
		`RECTANGLE3:
			begin
			y0 <= y1a;
			x0 <= x1a;
			x1 <= x0a;
			y1 <= y1a;
			cmd <= `RECTANGLE4;
			state <= DL_SETPIXEL;
			end
		`RECTANGLE4:
			begin
			x0 <= x0a;
			y0 <= y1a;
			x1 <= x0a;
			y1 <= y0a;
			cmd <= `NULL;
			state <= DL_SETPIXEL;
			end
		endcase
	end

GETPIXEL:
	if (!m_cyc_o) begin
		m_cyc_o <= 1'b1;
		m_stb_o <= 1'b1;
		case(ma[1:0])
		2'd0:	m_sel_o <= 4'b0001;
		2'd1:	m_sel_o <= 4'b0010;
		2'd2:	m_sel_o <= 4'b0100;
		2'd3:	m_sel_o <= 4'b1000;
		endcase
		m_adr_o <= {ma[31:2],2'b00};
	end
	else if (m_ack_i) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_sel_o <= 4'b0000;
		case(m_sel_o)
		4'b0001:	pxreg8 <= m_dat_i[7:0];
		4'b0010:	pxreg8 <= m_dat_i[15:8];
		4'b0100:	pxreg8 <= m_dat_i[23:16];
		4'b1000:	pxreg8 <= m_dat_i[31:24];
		endcase
		state <= IDLE;
	end

DRAWPIXEL:
	if (!m_cyc_o) begin
		m_cyc_o <= 1'b1;
		m_stb_o <= 1'b1;
		m_we_o <= 1'b1;
		case(ma[1:0])
		2'd0:	m_sel_o <= 4'b0001;
		2'd1:	m_sel_o <= 4'b0010;
		2'd2:	m_sel_o <= 4'b0100;
		2'd3:	m_sel_o <= 4'b1000;
		endcase
		m_adr_o <= {ma[31:2],2'b00};
		m_dat_o <= {4{PenColor8}};
	end
	else if (m_ack_i) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_sel_o <= 4'b0000;
		m_we_o <= 1'b0;
		state <= IDLE;
	end

DL_SETPIXEL:
	if (!m_cyc_o) begin
		m_cyc_o <= 1'b1;
		m_stb_o <= 1'b1;
		m_we_o <= 1'b1;
		case(ma[1:0])
		2'd0:	m_sel_o <= 4'b0001;
		2'd1:	m_sel_o <= 4'b0010;
		2'd2:	m_sel_o <= 4'b0100;
		2'd3:	m_sel_o <= 4'b1000;
		endcase
		m_adr_o <= {ma[31:2],2'b00};
		m_dat_o <= {4{PenColor8}};
	end
	else if (m_ack_i) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_sel_o <= 2'b00;
		m_we_o <= 1'b0;
		if (cx==x1 && cy==y1)
			state <= IDLE;
		else
			state <= DL_TEST;
	end
DL_TEST:
	begin
		err <= err + ((e2 > -dy) ? -dy : 16'd0) + ((e2 < dx) ? dx : 16'd0);
		cx <= (e2 > -dy) ? cx + sx : cx;
		cy <= (e2 <  dx) ? cy + sy : cy;
		state <= DL_SETPIXEL;
	end

endcase
end

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
