/*
ORSoC GFX accelerator core
Copyright 2018, Robert Finch

TEXT BLITTER MODULE

 This file is part of orgfx.

 orgfx is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version. 

 orgfx is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License
 along with orgfx.  If not, see <http://www.gnu.org/licenses/>.

*/

module gfx_textblit64(rst_i, clk_i, clip_ack_i,
	char_i, char_code_i, char_pos_x_i, char_pos_y_i,
	char_x_o, char_y_o, char_write_o, char_ack_o,
	font_table_adr_i, font_id_i, read_request_o,
	textblit_ack_i, textblit_sel_o, textblit_adr_o, textblit_dat_i);
parameter point_width = 16;
input rst_i;
input clk_i;
input clip_ack_i;
input char_i;
input [15:0] char_code_i;
input [point_width-1:0] char_pos_x_i;
input [point_width-1:0] char_pos_y_i;
output reg [point_width-1:0] char_x_o;
output reg [point_width-1:0] char_y_o;
output reg char_write_o;
output reg char_ack_o;
input [31:0] font_table_adr_i;
input [15:0] font_id_i;
output reg read_request_o;
input textblit_ack_i;
output reg [7:0] textblit_sel_o;
output reg [31:0] textblit_adr_o;
input [63:0] textblit_dat_i;

reg [3:0] state;
reg [5:0] pixhc, pixvc;
reg [31:0] font_addr;
reg font_fixed;
reg [5:0] font_width;
reg [5:0] font_height;
reg [31:0] char_bmp_adr;
reg [63:0] char_bmp;
reg [31:0] char_ndx;
reg [31:0] glyph_table_adr;
reg [63:0] glyph_entry;
reg [2:0] alsb;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter ST_IDLE = 4'd0;
parameter ST_READ_FONTTBL1 = 4'd1;
parameter ST_READ_FONTTBL1_ACK = 4'd2;
parameter ST_READ_FONTTBL2 = 4'd3;
parameter ST_READ_FONTTBL2_ACK = 4'd4;
parameter ST_READ_GLYPH_ENTRY = 4'd5;
parameter ST_READ_GLYPH_ENTRY_ACK = 4'd6;
parameter ST_READ_GLYPH_ENTRY2 = 4'd7;
parameter ST_READ_CHAR_BITMAP = 4'd8;
parameter ST_READ_CHAR_BITMAP_ACK = 4'd9;
parameter ST_READ_CHAR_BITMAP2 = 4'd10;
parameter ST_WRITE_CHAR = 4'd11;
parameter ST_WAIT_ACK = 4'd12;

always @(posedge clk_i)
case(state)
ST_IDLE:
	if (char_i)
		state <= ST_READ_FONTTBL1;
ST_READ_FONTTBL1:
	state <= ST_READ_FONTTBL1_ACK;
ST_READ_FONTTBL1_ACK:
	if (textblit_ack_i)
		state <= ST_READ_FONTTBL2;
ST_READ_FONTTBL2:
	state <= ST_READ_FONTTBL2_ACK;
ST_READ_FONTTBL2_ACK:
	if (textblit_ack_i)
		state <= ST_READ_GLYPH_ENTRY;
ST_READ_GLYPH_ENTRY:
	if (font_fixed)
		state <= ST_READ_CHAR_BITMAP;
	else
		state <= ST_READ_GLYPH_ENTRY_ACK;
ST_READ_GLYPH_ENTRY_ACK:
	if (textblit_ack_i)
		state <= ST_READ_GLYPH_ENTRY2;
ST_READ_GLYPH_ENTRY2:
	state <= ST_READ_CHAR_BITMAP;
ST_READ_CHAR_BITMAP:
	state <= ST_READ_CHAR_BITMAP_ACK;
ST_READ_CHAR_BITMAP_ACK:
	if (textblit_ack_i)
		state <= ST_READ_CHAR_BITMAP2;
ST_READ_CHAR_BITMAP2:
	state <= ST_WRITE_CHAR;
ST_WRITE_CHAR:
	begin
		state <= ST_WAIT_ACK;
		if (pixhc==font_width) begin
			state <= ST_READ_CHAR_BITMAP;
	    if (pixvc==font_height)
	    	state <= ST_IDLE;
		end
	end
ST_WAIT_ACK:
	if (clip_ack_i)
		state <= ST_WRITE_CHAR;

endcase

always @(posedge clk_i)
casez(font_width[5:3])
3'b000:	char_ndx <= (char_code_i) * (font_height + 6'd1);
3'b001:	char_ndx <= (char_code_i << 3'd1) * (font_height + 6'd1);
3'b01?:	char_ndx <= (char_code_i << 3'd2) * (font_height + 6'd1);
3'b1??:	char_ndx <= (char_code_i << 3'd3) * (font_height + 6'd1);
endcase


// Font Table - An entry for each font
// 0 aaaaaaaaaaaaaaaa_aaaaaaaaaaaaaaaa		- char bitmap address
// 4 fwwwwwwhhhhhh---_aaaaaaaaaaaaaaaa		- width and height
// 8 aaaaaaaaaaaaaaaa_aaaaaaaaaaaaaaaa		- low order address offset bits
// C ----------------_aaaaaaaaaaaaaaaa		- address offset of gylph width table
//
// Glyph Table Entry
// --wwwwww--wwwwww_--wwwwww--wwwwww		- width
// --wwwwww--wwwwww_--wwwwww--wwwwww
// ...

always @(posedge clk_i)
begin
	char_write_o <= 1'b0;
	char_ack_o <= 1'b0;
case(state)
ST_READ_FONTTBL1:
	begin
		read_request_o <= 1'b1;
		textblit_sel_o <= 8'hFF;
		textblit_adr_o <= {font_table_adr_i[31:4],4'b0} + {font_id_i,4'b0};
	end
ST_READ_FONTTBL1_ACK:
	begin
		if (textblit_ack_i)
			read_request_o <= 1'b0;
		char_bmp_adr <= {textblit_dat_i[31:3],3'b0};
		font_fixed <= textblit_dat_i[63];
		font_width <= textblit_dat_i[62:57];
		font_height <= textblit_dat_i[56:51];
	end
ST_READ_FONTTBL2:
	begin
		read_request_o <= 1'b1;
		textblit_sel_o <= 8'hFF;
		textblit_adr_o <= textblit_adr_o + 8'd8;
	end
ST_READ_FONTTBL2_ACK:
	begin
		if (textblit_ack_i)
			read_request_o <= 1'b0;
		glyph_table_adr <= {textblit_dat_i[31:3],3'd0};
	end
ST_READ_GLYPH_ENTRY:
	begin
		char_bmp_adr <= char_bmp_adr + char_ndx;
		if (!font_fixed) begin
			read_request_o <= 1'b1;
			textblit_sel_o <= 8'hFF;
			textblit_adr_o <= glyph_table_adr + {char_code_i[15:3],3'b0};
		end
	end
ST_READ_GLYPH_ENTRY_ACK:
	begin
		if (textblit_ack_i)
			read_request_o <= 1'b0;
		glyph_entry <= textblit_dat_i;		
	end
ST_READ_GLYPH_ENTRY2:
		font_width <= glyph_entry >> {char_code_i[2:0],3'd0};
ST_READ_CHAR_BITMAP:
	begin
		read_request_o <= 1'b1;
		textblit_sel_o <= 8'hFF;
		alsb <= char_bmp_adr + (pixvc << font_width[4:3]);
		textblit_adr_o <= char_bmp_adr + (pixvc << font_width[4:3]);
		textblit_adr_o[2:0] <= 3'd0;
	end
ST_READ_CHAR_BITMAP_ACK:
	begin
		if (textblit_ack_i)
			read_request_o <= 1'b0;
		char_bmp <= textblit_dat_i;
	end
ST_READ_CHAR_BITMAP2:
	begin
		casez(font_width[5:3])
		3'b000:	char_bmp <= (char_bmp >> {alsb,3'b0}) & 64'h0ff;
		3'b001:	char_bmp <= (char_bmp >> {alsb[2:1],4'b0}) & 64'h0ffff;
		3'b01?:	char_bmp <= (char_bmp >> {alsb[2],5'b0}) & 64'h0ffffffff;
		3'b1??:	char_bmp <= char_bmp;
		endcase
	end
ST_WRITE_CHAR:
	begin
		char_x_o <= char_pos_x_i + pixhc;
		char_y_o <= char_pos_y_i + pixvc;
		if (pixhc != font_width || pixvc != font_height)
			char_write_o <= char_bmp[0];
		char_bmp <= {1'b0,char_bmp[63:1]};
		pixhc <= pixhc + 5'd1;
		if (pixhc==font_width) begin
		  pixhc <= 5'd0;
		  pixvc <= pixvc + 5'd1;
	    if (pixvc==font_height)
	    	char_ack_o <= 1'b1;
		end
	end
default:	;		
endcase
end

endmodule
