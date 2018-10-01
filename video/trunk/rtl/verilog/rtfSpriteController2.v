// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// rtfSpriteController2.v
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
//`define USE_CLOCK_GATE	1'b1

`define TRUE	1'b1
`define FALSE	1'b0
`define HIGH	1'b1
`define LOW		1'b0

`define ABITS	31:0
// The cycle at which it's safe to update the working count and address.
// A good value is just before the end of the scan, but that depends on
// display resolution.
`define SPR_WCA	12'd638

module rtfSpriteController2(rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o,
	m_clk_i, m_cyc_o, m_stb_o, m_ack_i, m_sel_o, m_adr_o, m_dat_i,
	dot_clk_i, hsync_i, vsync_i, zrgb_i, zrgb_o, test
);
// Bus slave port
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [7:0] sel_i;
input [11:0] adr_i;
input [63:0] dat_i;
output reg [63:0] dat_o;
// Bus master port
input m_clk_i;
output reg m_cyc_o;
output m_stb_o;
input m_ack_i;
output [7:0] m_sel_o;
output reg [`ABITS] m_adr_o;
input [63:0] m_dat_i;
// Video port
input dot_clk_i;
input vsync_i;
input hsync_i;
input [31:0] zrgb_i;
output reg [31:0] zrgb_o;
input test;

parameter NSPR = 32;
parameter IDLE = 3'd0;
parameter DATA_FETCH = 3'd1;
parameter MEM_ACCESS = 3'd2;
parameter WAIT_NACK = 3'd3;
parameter NEXT_SPRITE = 3'd4;

integer n;

reg controller_enable;
wire vclk;
reg [2:0] state;
reg [1:0] lowres;
wire [5:0] flashcnt;
reg rst_collision;
reg [31:0] collision, c_collision;
reg [4:0] spriteno;
reg sprite;
reg [31:0] spriteEnable;
reg [31:0] spriteActive;
reg [11:0] sprite_pv [0:31];
reg [11:0] sprite_ph [0:31];
reg [3:0] sprite_pz [0:31];
(* ram_style="distributed" *)
reg [37:0] sprite_color [0:255];
reg [31:0] sprite_on;
reg [31:0] sprite_on_d1;
reg [31:0] sprite_on_d2;
reg [31:0] sprite_on_d3;
(* ram_style="distributed" *)
reg [`ABITS] spriteAddr [0:31];
reg [`ABITS] spriteWaddr [0:31];
reg [15:0] spriteMcnt [0:31];
reg [15:0] spriteWcnt [0:31];
reg [63:0] m_spriteBmp [0:31];
reg [63:0] spriteBmp [0:31];
reg [31:0] spriteLink1;
reg [7:0] spriteColorNdx [0:31];

initial begin
	for (n = 0; n < 256; n = n + 1) begin
		sprite_color[n][31:0] <= {8'h00,n[7:5],5'd0,n[4:3],6'd0,n[2:0],5'd0};
	end
	for (n = 0; n < 32; n = n + 1) begin
		sprite_ph[n] <= 260 + n * 40;
		sprite_pv[n] <= 41 + n * 20;
		sprite_pz[n] <= 8'h00;
		spriteMcnt[n] <= 60 * 32;
		spriteBmp[n] <= 64'hFFFFFFFFFFFFFFFF;
		spriteAddr[n] <= 32'h40000 + (n << 12);
	end
end

wire pe_hsync, pe_vsync;
wire [11:0] hctr, vctr;
reg [11:0] m_hctr, m_vctr;

// Generate acknowledge signal
wire cs = cs_i & cyc_i & stb_i;
reg rdy1,rdy2,rdy3,rdy4;
always @(posedge clk_i)
	rdy1 <= cs;
always @(posedge clk_i)
	rdy2 <= rdy1 & cs;
always @(posedge clk_i)
	rdy3 <= rdy2 & cs;
always @(posedge clk_i)
	rdy4 <= rdy3 & cs;
assign ack_o = (cs & we_i) ? 1'b1 : rdy4;

(* ram_style="block" *)
reg [63:0] shadow_ram [0:511];
reg [63:0] shadow_ramo;
reg [8:0] sradr;
always @(posedge clk_i)
	if (cs & we_i) begin
		if (sel_i[0]) shadow_ram[adr_i[11:3]][ 7: 0] <= dat_i;
		if (sel_i[1]) shadow_ram[adr_i[11:3]][15: 8] <= dat_i;
		if (sel_i[2]) shadow_ram[adr_i[11:3]][23:16] <= dat_i;
		if (sel_i[3]) shadow_ram[adr_i[11:3]][31:24] <= dat_i;
		if (sel_i[4]) shadow_ram[adr_i[11:3]][39:32] <= dat_i;
		if (sel_i[5]) shadow_ram[adr_i[11:3]][47:40] <= dat_i;
		if (sel_i[6]) shadow_ram[adr_i[11:3]][55:48] <= dat_i;
		if (sel_i[7]) shadow_ram[adr_i[11:3]][63:56] <= dat_i;
	end
always @(posedge clk_i)
	sradr <= adr_i[11:3];
always @(posedge clk_i)
	shadow_ramo <= shadow_ram[sradr];
always @(posedge clk_i)
case(adr_i[11:3])
9'b1010_0001_0:	dat_o <= c_collision;
default:	dat_o <= shadow_ramo;
endcase

always @(posedge clk_i)
if (rst_i) begin
	rst_collision <= `FALSE;
	controller_enable <= `TRUE;
	spriteEnable <= 32'hFFFFFFFF;
	spriteLink1 <= 32'h0;
end
else begin
	rst_collision <= `FALSE;
	if (cs & we_i) begin
		casez(adr_i[11:3])
		9'b0???_????_?:	sprite_color[adr_i[10:3]] <= dat_i[37:0];
		9'b100?_????_0:	spriteAddr[adr_i[8:4]] <= dat_i[`ABITS];
		9'b100?_????_1:
			begin
				if (|sel_i[1:0]) sprite_ph[adr_i[8:4]] <= dat_i[11: 0];
				if (|sel_i[3:2]) sprite_pv[adr_i[8:4]] <= dat_i[27:16];
				if ( sel_i[  4]) sprite_pz[adr_i[8:4]] <= dat_i[39:32];
				if (|sel_i[7:6]) spriteMcnt[adr_i[8:4]] <= dat_i[63:48];
			end
		9'b1010_0000_0:	spriteEnable <= dat_i[31:0];
		9'b1010_0000_1:	spriteLink1 <= dat_i[31:0];
		9'b1010_0001_0:	rst_collision <= `TRUE;
		9'b1010_0001_1:
			begin
				lowres <= dat_i[1:0];
				controller_enable <= dat_i[8];
			end
		endcase
	end
end

assign m_stb_o = m_cyc_o;
assign m_sel_o = 8'hFF;

// Register hctr to m_clk_i domain
always @(posedge m_clk_i)
	m_hctr <= hctr;

// State machine
always @(posedge m_clk_i)
if (rst_i)
	state <= IDLE;
else begin
	case(state)
	IDLE:
		// dot_clk_i is likely faster than m_clk_i, so check for a trigger zone.
		if (m_hctr < 12'd10 && controller_enable)
			state <= DATA_FETCH;
	DATA_FETCH:
		if (spriteActive[spriteno])
			state <= MEM_ACCESS;
		else
			state <= NEXT_SPRITE;
	MEM_ACCESS:
		if (m_ack_i)
			state <= WAIT_NACK;
	WAIT_NACK:
		if (~m_ack_i)
			state <= NEXT_SPRITE;
	NEXT_SPRITE:
		if (spriteno==5'd31)
			state <= IDLE;
		else
			state <= DATA_FETCH;
	endcase
end

always @(posedge m_clk_i)
if (rst_i) begin
	m_cyc_o <= `LOW;
	spriteno <= 5'd0;
end
else begin
	case(state)
	IDLE:
		spriteno <= 5'd0;
	DATA_FETCH:
		if (spriteActive[spriteno]) begin
			m_cyc_o <= `HIGH;
			m_adr_o <= spriteWaddr[spriteno];
		end
	MEM_ACCESS:
		if (m_ack_i) begin
			m_cyc_o <= `LOW;
			m_spriteBmp[spriteno] <= dat_i;
			if (test)
				m_spriteBmp[spriteno] <= 64'h00005555AAAAFFFF;
		end
	NEXT_SPRITE:
		spriteno <= spriteno + 5'd1;
	endcase
end

// Register collision onto clk_i domain.
always @(posedge clk_i)
	c_collision <= collision;

`ifdef USE_CLOCK_GATE
BUFHCE ucb1
(
	.I(dot_clk_i),
	.CE(controller_enable),
	.O(vclk)
);
`else
assign vclk = dot_clk_i;
`endif

edge_det ued1 (.clk(vclk), .ce(1'b1), .i(hsync_i), .pe(pe_hsync), .ne(), .ee());
edge_det ued2 (.clk(vclk), .ce(1'b1), .i(vsync_i), .pe(pe_vsync), .ne(), .ee());

VT163 #(12) uhctr (.clk(vclk), .clr_n(!rst_i), .ent(1'b1),     .enp(1'b1), .ld_n(!pe_hsync), .d(12'd0), .q(hctr), .rco());
VT163 #(12) uvctr (.clk(vclk), .clr_n(!rst_i), .ent(pe_hsync), .enp(1'b1), .ld_n(!pe_vsync), .d(12'd0), .q(vctr), .rco());
VT163 # (6) ufctr (.clk(vclk), .clr_n(!rst_i), .ent(pe_vsync), .enp(1'b1), .ld_n(1'b1),  .d( 6'd0), .q(flashcnt), .rco());

always @(posedge vclk)
begin
	if (rst_collision)
		collision <= 32'd0;
	else
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
		// The following assumes there are at least 640 clocks in a scan line.
		if (hctr==`SPR_WCA)	// must be after image data fetch
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
		if (hctr==`SPR_WCA)	// must be after image data fetch
		case(lowres)
   		2'd0,2'd3:	spriteWaddr[n] <= spriteWaddr[n] + 32'd8;
   		2'd1:		if (vctr[0]) spriteWaddr[n] <= spriteWaddr[n] + 32'd8;
   		2'd2:		if (vctr[1:0]==2'b11) spriteWaddr[n] <= spriteWaddr[n] + 32'd8;
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
        spriteLink1[n] ? |{spriteBmp[(n+1)&31][63:62],spriteBmp[n][63:62]} : 
        |spriteBmp[n][63:62];
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
    	2'd0,2'd3:	spriteBmp[n] <= {spriteBmp[n][61:0],2'h0};
    	2'd1:	if (hctr[0]) spriteBmp[n] <= {spriteBmp[n][61:0],2'h0};
    	2'd2:	if (&hctr[1:0]) spriteBmp[n] <= {spriteBmp[n][61:0],2'h0};
			endcase
end

always @(posedge vclk)
for (n = 0; n < NSPR; n = n + 1)
if (spriteLink1[n])
  spriteColorNdx[n] <= {n[3:0],spriteBmp[(n+1)&31][63:62],spriteBmp[n][63:62]};
else if (spriteLink1[(n-1)&31])
	spriteColorNdx[n] <= 8'h00;	// transparent
else
  spriteColorNdx[n] <= {1'b0,n[4:0],spriteBmp[n][63:62]};

// Compute index into sprite color palette
// If none of the sprites are linked, each sprite has it's own set of colors.
// If the sprites are linked once the colors are available in groups.
// If the sprites are linked twice they all share the same set of colors.
// Pipelining register
reg blank1, blank2, blank3, blank4;
reg border1, border2, border3, border4;
reg any_sprite_on2, any_sprite_on3, any_sprite_on4;
reg [31:0] zrgb_i3, zrgb_i4;
reg [7:0] zb_i3, zb_i4;
reg [7:0] sprite_z1, sprite_z2, sprite_z3, sprite_z4;
reg [7:0] sprite_pzx;
// The color index from each sprite can be mux'ed into a single value used to
// access the color palette because output color is a priority chain. This
// saves having mulriple read ports on the color palette.
reg [37:0] spriteColorOut2; 
reg [37:0] spriteColorOut3;
reg [7:0] spriteClrNdx;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #1
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Mux color index
// Fetch sprite Z order

always @(posedge vclk)
    sprite_on_d1 <= sprite_on;

always @(posedge vclk)
begin
	spriteClrNdx <= 8'd0;
	for (n = NSPR-1; n >= 0; n = n -1)
		if (sprite_on[n])
			spriteClrNdx <= spriteColorNdx[n];
end
        
always @(posedge vclk)
begin
	sprite_z1 <= 8'hff;
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

wire [15:0] alphaRed = (zrgb_i[23:16] * spriteColorOut2[31:24]) + (spriteColorOut2[23:16] * (9'h100 - spriteColorOut2[31:24]));
wire [15:0] alphaGreen = (zrgb_i[15:8] * spriteColorOut2[31:24]) + (spriteColorOut2[15:8]  * (9'h100 - spriteColorOut2[31:24]));
wire [15:0] alphaBlue = (zrgb_i[7:0] * spriteColorOut2[31:24]) + (spriteColorOut2[7:0]  * (9'h100 - spriteColorOut2[31:24]));
reg [23:0] alphaOut;

always @(posedge vclk)
    alphaOut <= {alphaRed[15:8],alphaGreen[15:8],alphaBlue[15:8]};
always @(posedge vclk)
    sprite_z3 <= sprite_z2;
always @(posedge vclk)
    any_sprite_on3 <= any_sprite_on2;
always @(posedge vclk)
    zrgb_i3 <= zrgb_i;
always @(posedge vclk)
    zb_i3 <= zrgb_i[31:24];
always @(posedge vclk)
    blank3 <= blank2;
always @(posedge vclk)
    border3 <= border2;
always @(posedge vclk)
    spriteColorOut3 <= spriteColorOut2;

reg [23:0] flashOut;
wire [23:0] reverseVideoOut = spriteColorOut2[37] ? alphaOut ^ 24'hFFFFFF : alphaOut;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #4
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Compute flash output

always @(posedge vclk)
    flashOut <= spriteColorOut3[36] ? (((flashcnt[5:2] & spriteColorOut3[35:32])!=4'b0000) ? reverseVideoOut : zrgb_i3) : reverseVideoOut;
always @(posedge vclk)
    zrgb_i4 <= zrgb_i3;
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

always @(posedge dot_clk_i)
	case(any_sprite_on4 & controller_enable)
	1'b1:		zrgb_o <= (zb_i4 < sprite_z4) ? zrgb_i4 : {sprite_z4,flashOut};
	1'b0:		zrgb_o <= zrgb_i4;
	endcase

endmodule

