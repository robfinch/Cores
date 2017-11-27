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

integer n;
reg [5:0] state = ST_IDLE;
reg [19:0] bmpBase = 20'h00000;		// base address of bitmap
reg [19:0] charBmpBase = 20'hB8000;	// base address of character bitmaps
reg [11:0] hstart = 12'hEB3;		// -333
reg [11:0] vstart = 12'hFB0;		// -80
reg [11:0] hpos;
reg [11:0] vpos;
reg [11:0] bitmapWidth = 12'd640;
reg [8:0] borderColor;
wire [9:0] rgb_i;					// internal rgb output from ram

wire [19:0] rdndx;					// video read index
reg [19:0] ram_addr;
reg [9:0] ram_data_i;
wire [9:0] ram_data_o;
reg ram_we;

reg [ 9:0] pixcnt;
reg [3:0] pixhc,pixvc;

reg [19:0] blt_addr [0:63];			// base address of BLT bitmap
reg [ 9:0] blt_pix  [0:63];			// number of pixels in BLT
reg [ 9:0] blt_hmax [0:63];			// horizontal size of BLT
reg [ 9:0] blt_x	[0:63];			// BLT's x position
reg [ 9:0] blt_y	[0:63];			// BLT's y position
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
reg [3:0] loopcnt;

reg [ 8:0] charcode;                // character code being processed
reg [ 9:0] charbmp;					// hold character bitmap scanline
reg [8:0] fgcolor,bkcolor;			// character colors
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

assign rdndx = {bmpBase[19:12],hpos} + {8'h00,vpos} * {8'h00,bitmapWidth};

always @(posedge clk)
	rgb <= blank ? 9'h000 : border ? borderColor : rgb_i[8:0];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [4:0] chrq_ndx;

reg ack,rdy;
reg rwsr;							// read / write shadow ram
wire chrp = rwsr & ~rdy;			// chrq pulse
wire cs_reg = cyc_i & stb_i & cs_i;
wire cs_ram = cyc_i & stb_i & cs_ram_i;

wire cs_chrq = cs_reg && adr_i[10:1]==10'b100_0010_111 && chrp && we_i;

reg [58:0] chrq_in;
wire [58:0] chrq_out;

vtdl #(.WID(59), .DEP(32)) char_q (.clk(clk_i), .ce(cs_chrq), .a(chrq_ndx), .d(chrq_in), .q(chrq_out));

wire [8:0] charcode_qo = chrq_out[8:0];
wire [8:0] charfg_qo = chrq_out[17:9];
wire [8:0] charbk_qo = chrq_out[26:18];
wire [11:0] charx_qo = chrq_out[38:27];
wire [11:0] chary_qo = chrq_out[50:39];
wire [3:0] charxm_qo = chrq_out[54:51];
wire [3:0] charym_qo = chrq_out[58:55];

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
		10'b100_0010_000:	chrq_in[8:0] <= dat_i[8:0];
		10'b100_0010_001:	chrq_in[17:9] <= dat_i[8:0];
		10'b100_0010_010:	chrq_in[26:18] <= dat_i[8:0];
		10'b100_0010_011:	chrq_in[38:27] <= dat_i[11:0];
		10'b100_0010_100:	chrq_in[50:39] <= dat_i[11:0];
		10'b100_0010_101:   chrq_in[58:51] <= {dat_i[11:8],dat_i[3:0]};
		10'b100_0010_110: chrq_ndx <= dat_i[4:0];
		default:	;	// do nothing
		endcase
	end
	else begin
		case(adr_i[10:1])
		10'b1000010110:	dat_o <= {11'h00,chrq_ndx};
		default:	dat_o <= srdo;
		endcase
	end
end
if (cs_chrq)
	chrq_ndx <= chrq_ndx + 5'd1;

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

		else if (|chrq_ndx) begin
			chrq_ndx <= chrq_ndx - 5'd1;
			state <= ST_CHAR_INIT;
		end

		else if (|blt_dirty) begin
			for (n = 0; n < 64; n = n + 1)
				if (blt_dirty[n])
					bltno <= n;
			tgtaddr <= bmpBase;
			loopcnt <= 4'h0;
			state <= ST_BLT_INIT;
		end
	end

ST_RW:
	begin
	    ram_we <= `LOW;
		ack <= `HIGH;
		dat_o <= {6'd0,ram_data_o};
		if (~cs_ram) begin
			ack <= `LOW;
			state <= ST_IDLE;
		end
	end

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
		tgtaddr <= {8'h00,chary_qo} * bitmapWidth + {bmpBase[19:12],charx_qo};
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
		tgtindex <= pixvc * bitmapWidth;
		state <= ST_WRITE_CHAR;
	end
ST_WRITE_CHAR:
	begin
		ram_we <= `HIGH;
		ram_addr <= tgtaddr + tgtindex + pixhc;
		ram_data_i <= charbmp[pixxm] ? fgcolor : bkcolor;
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
default:
	state <= ST_IDLE;
endcase
end
endmodule
