// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
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
// Uncommenting the following will allow the core to use clock gates and
// buffers. The video dot clock may be turned off to reduce power consumption
// if the controller is not in use.
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
//`define SUPPORT_LOWRES	1'b1
// If changing the following value to something other than 64 some of the code
// will need to be changed as well.
`define NSPRITE		64

module SpriteController32(clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o,
	m_clk_i, m_cyc_o, m_stb_o, m_ack_i, m_sel_o, m_adr_o, m_dat_i, m_spriteno_o,
	dot_clk_i, hsync_i, vsync_i, border_i, zrgb_i, zrgb_o, test
);
// Bus slave port
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [3:0] sel_i;
input [11:0] adr_i;
input [31:0] dat_i;
output reg [31:0] dat_o;
// Bus master port
input m_clk_i;
output reg m_cyc_o;
output m_stb_o;
input m_ack_i;
output [7:0] m_sel_o;
output reg [`ABITS] m_adr_o;
input [63:0] m_dat_i;
output reg [5:0] m_spriteno_o;
// Video port
input dot_clk_i;
input vsync_i;
input hsync_i;
input border_i;
input [31:0] zrgb_i;
output reg [31:0] zrgb_o;
input test;

parameter NSPR = `NSPRITE;
parameter IDLE = 2'd0;
parameter DATA_FETCH = 2'd1;
parameter MEM_ACCESS = 2'd2;

integer n;

reg controller_enable = 1'b1;
wire vclk;
reg [1:0] state = IDLE;
reg [1:0] lowres = 2'b00;
wire [5:0] flashcnt;
reg rst_collision = 1'b0;
reg [NSPR-1:0] collision, c_collision;
reg [5:0] spriteno = 5'd0;
reg sprite;
reg [NSPR-1:0] spriteEnable = 64'hFFFFFFFFFFFFFFFF;
reg [NSPR-1:0] spriteActive;
reg [11:0] sprite_pv [0:NSPR-1];
reg [11:0] sprite_ph [0:NSPR-1];
reg [3:0] sprite_pz [0:NSPR-1];
(* ram_style="distributed" *)
reg [37:0] sprite_color [0:255];
reg [NSPR-1:0] sprite_on;
reg [NSPR-1:0] sprite_on_d1;
reg [NSPR-1:0] sprite_on_d2;
reg [NSPR-1:0] sprite_on_d3;
(* ram_style="distributed" *)
reg [`ABITS] spriteAddr [0:NSPR-1];
reg [`ABITS] spriteWaddr [0:NSPR-1];
reg [15:0] spriteMcnt [0:NSPR-1];
reg [15:0] spriteWcnt [0:NSPR-1];
reg [63:0] m_spriteBmp [0:NSPR-1];
reg [63:0] spriteBmp [0:NSPR-1];
reg [NSPR-1:0] spriteLink1 = 32'h0;
reg [7:0] spriteColorNdx [0:NSPR-1];

initial begin
	for (n = 0; n < 256; n = n + 1) begin
		sprite_color[n] <= {6'h00,8'h00,n[7:5],5'd0,n[4:3],6'd0,n[2:0],5'd0};
//		sprite_color[n][31:0] <= {8'h00,n[7:5],5'd0,n[4:3],6'd0,n[2:0],5'd0};	// <- doesn't work
	end
	for (n = 0; n < NSPR; n = n + 1) begin
		if (n < 16) begin
			sprite_ph[n] <= 400 + n * 32;
			sprite_pv[n] <= 80 + n * 8;
		end
		else if (n < 32) begin
			sprite_ph[n] <= 400 + (n - 16) * 32;
			sprite_pv[n] <= 150 + (n - 16) * 8;
		end
		else if (n < 48) begin
			sprite_ph[n] <= 400 + (n - 32) * 32;
			sprite_pv[n] <= 220 + (n - 32) * 8;
		end
		else begin
			sprite_ph[n] <= 400 + (n - 48) * 32;
			sprite_pv[n] <= 290 + (n - 48) * 8;
		end
		sprite_pz[n] <= 8'h08;
		spriteMcnt[n] <= 80 * 32;
		spriteBmp[n] <= 64'hFFFFFFFFFFFFFFFF;
		spriteAddr[n] <= 32'h40000 + (n << 12);
	end
end

wire pe_hsync, pe_vsync;
wire [11:0] hctr, vctr;
reg [11:0] m_hctr, m_vctr;

reg cs;
reg we;
reg [7:0] sel;
reg [11:0] adr;
reg [63:0] dat;

wire clk;
`ifdef USE_CLOCK_GATE
BUFH uclk (.I(clk_i), .O(clk));
`else
assign clk = clk_i;
`endif

always @(posedge clk)
	cs <= cs_i & cyc_i & stb_i;
always @(posedge clk)
	we <= we_i;
always @(posedge clk)
	sel <= sel_i;
always @(posedge clk)
	adr <= adr_i;
always @(posedge clk)
	dat <= dat_i;

ack_gen #(
	.READ_STAGES(4),
	.WRITE_STAGES(0),
	.REGISTER_OUTPUT(1)
) uag1
(
	.clk_i(clk),
	.ce_i(1'b1),
	.i(cs),
	.we_i(cs & we),
	.o(ack_o)
);

(* ram_style="block" *)
reg [31:0] shadow_ram [0:1023];
reg [31:0] shadow_ramo;
reg [9:0] sradr;
always @(posedge clk)
	if (cs & we) begin
		if (|sel[1:0]) shadow_ram[adr[11:3]][15: 0] <= dat[15: 0];
		if (|sel[3:2]) shadow_ram[adr[11:3]][31:16] <= dat[31:16];
	end
always @(posedge clk)
	sradr <= adr[11:3];
always @(posedge clk)
	shadow_ramo <= shadow_ram[sradr];
always @(posedge clk)
case(adr[11:3])
9'b1010_0001_0:	dat_o <= c_collision;
default:	dat_o <= shadow_ramo;
endcase

always @(posedge clk)
begin
	rst_collision <= `FALSE;
	if (cs & we) begin
		casez(adr[11:2])
		10'b0???_????_?0:	sprite_color[adr[10:3]][31:0] <= dat[31:0];
		10'b0???_????_?1:	sprite_color[adr[10:3]][37:32] <= dat[5:0];
		10'b10??_????_00:	spriteAddr[adr[9:4]] <= dat[`ABITS];
		10'b10??_????_10:
			begin
				if (|sel[1:0]) sprite_ph[adr[9:4]] <= dat[11: 0];
				if (|sel[3:2]) sprite_pv[adr[9:4]] <= dat[27:16];
			end
		10'b10??_????_11:
			begin
				if (|sel[5:4]) sprite_pz[adr[9:4]] <= dat[7:0];
				if (|sel[7:6]) spriteMcnt[adr[9:4]] <= dat[31:16];
			end
		10'b1100_0000_00:	spriteEnable[31:0] <= dat[31:0];
		10'b1100_0000_01:	spriteEnable[63:32] <= dat[31:0];
		10'b1100_0000_10:	spriteLink1[31:0] <= dat[31:0];
		10'b1100_0000_11:	spriteLink1[63:32] <= dat[31:0];
		10'b1100_0001_00:	rst_collision <= `TRUE;
		10'b1100_0001_10:
			begin
				lowres <= dat[1:0];
				controller_enable <= dat[8];
			end
		default:	;
		endcase
	end
end

assign m_stb_o = m_cyc_o;
assign m_sel_o = 8'hFF;

wire clkm;
`ifdef USE_CLOCK_GATE
BUFHCE uclkm (.I(m_clk_i), .CE(controller_enable), .O(clkm));
`else
assign clkm = m_clk_i;
`endif

// Register hctr to m_clk_i domain
always @(posedge clkm)
	m_hctr <= hctr;

// State machine
always @(posedge clkm)
case(state)
IDLE:
	// dot_clk_i is likely faster than m_clk_i, so check for a trigger zone.
	if (m_hctr < 12'd10 && controller_enable)
		state <= DATA_FETCH;
DATA_FETCH:
	if (spriteActive[spriteno]) begin
		if (~m_ack_i)
			state <= MEM_ACCESS;
	end
	else if (spriteno==NSPR-1)
		state <= IDLE;
MEM_ACCESS:
	if (m_ack_i|test) begin
		if (spriteno==NSPR-1)
			state <= IDLE;
		else
			state <= DATA_FETCH;
	end
default:	state <= IDLE;
endcase

always @(posedge clkm)
case(state)
IDLE:
	m_cyc_o <= `LOW;
DATA_FETCH:
	if (!m_ack_i && spriteActive[spriteno]) begin
		m_cyc_o <= ~test;//`HIGH;
		m_adr_o <= spriteWaddr[spriteno];
		m_spriteno_o <= spriteno;
	end
MEM_ACCESS:
	if (m_ack_i|test) begin
		m_cyc_o <= `LOW;
		m_spriteBmp[spriteno] <= m_dat_i;
		if (test)
			m_spriteBmp[spriteno] <= 64'h00005555AAAAFFFF;
	end
default:	;
endcase

always @(posedge clkm)
case(state)
IDLE:
	spriteno <= 5'd0;
DATA_FETCH:
	if (!spriteActive[spriteno])
		spriteno <= spriteno + 5'd1;
MEM_ACCESS:
	if (m_ack_i|test)
		spriteno <= spriteno + 5'd1;
default:	;
endcase


// Register collision onto clk_i domain.
always @(posedge clk)
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

edge_det ued1 (.rst(1'b0), .clk(vclk), .ce(1'b1), .i(hsync_i), .pe(pe_hsync), .ne(), .ee());
edge_det ued2 (.rst(1'b0), .clk(vclk), .ce(1'b1), .i(vsync_i), .pe(pe_vsync), .ne(), .ee());

VT163 #(12) uhctr (.clk(vclk), .clr_n(1'b1), .ent(1'b1),     .enp(1'b1), .ld_n(!pe_hsync), .d(12'd0), .q(hctr), .rco());
VT163 #(12) uvctr (.clk(vclk), .clr_n(1'b1), .ent(pe_hsync), .enp(1'b1), .ld_n(!pe_vsync), .d(12'd0), .q(vctr), .rco());
VT163 # (6) ufctr (.clk(vclk), .clr_n(1'b1), .ent(pe_vsync), .enp(1'b1), .ld_n(1'b1),  .d( 6'd0), .q(flashcnt), .rco());

always @(posedge vclk)
begin
	if (rst_collision)
		collision <= 64'd0;
	else
		case(sprite_on)
		64'b0000000000000000000000000000000000000000000000000000000000000000,
		64'b0000000000000000000000000000000000000000000000000000000000000001,
		64'b0000000000000000000000000000000000000000000000000000000000000010,
		64'b0000000000000000000000000000000000000000000000000000000000000100,
		64'b0000000000000000000000000000000000000000000000000000000000001000,
		64'b0000000000000000000000000000000000000000000000000000000000010000,
		64'b0000000000000000000000000000000000000000000000000000000000100000,
		64'b0000000000000000000000000000000000000000000000000000000001000000,
		64'b0000000000000000000000000000000000000000000000000000000010000000,
		64'b0000000000000000000000000000000000000000000000000000000100000000,
		64'b0000000000000000000000000000000000000000000000000000001000000000,
		64'b0000000000000000000000000000000000000000000000000000010000000000,
		64'b0000000000000000000000000000000000000000000000000000100000000000,
		64'b0000000000000000000000000000000000000000000000000001000000000000,
		64'b0000000000000000000000000000000000000000000000000010000000000000,
		64'b0000000000000000000000000000000000000000000000000100000000000000,
		64'b0000000000000000000000000000000000000000000000001000000000000000,
		64'b0000000000000000000000000000000000000000000000010000000000000000,
		64'b0000000000000000000000000000000000000000000000100000000000000000,
		64'b0000000000000000000000000000000000000000000001000000000000000000,
		64'b0000000000000000000000000000000000000000000010000000000000000000,
		64'b0000000000000000000000000000000000000000000100000000000000000000,
		64'b0000000000000000000000000000000000000000001000000000000000000000,
		64'b0000000000000000000000000000000000000000010000000000000000000000,
		64'b0000000000000000000000000000000000000000100000000000000000000000,
		64'b0000000000000000000000000000000000000001000000000000000000000000,
		64'b0000000000000000000000000000000000000010000000000000000000000000,
		64'b0000000000000000000000000000000000000100000000000000000000000000,
		64'b0000000000000000000000000000000000001000000000000000000000000000,
		64'b0000000000000000000000000000000000010000000000000000000000000000,
		64'b0000000000000000000000000000000000100000000000000000000000000000,
		64'b0000000000000000000000000000000001000000000000000000000000000000,
		64'b0000000000000000000000000000000010000000000000000000000000000000,
		64'b0000000000000000000000000000000100000000000000000000000000000000,
		64'b0000000000000000000000000000001000000000000000000000000000000000,
		64'b0000000000000000000000000000010000000000000000000000000000000000,
		64'b0000000000000000000000000000100000000000000000000000000000000000,
		64'b0000000000000000000000000001000000000000000000000000000000000000,
		64'b0000000000000000000000000010000000000000000000000000000000000000,
		64'b0000000000000000000000000100000000000000000000000000000000000000,
		64'b0000000000000000000000001000000000000000000000000000000000000000,
		64'b0000000000000000000000010000000000000000000000000000000000000000,
		64'b0000000000000000000000100000000000000000000000000000000000000000,
		64'b0000000000000000000001000000000000000000000000000000000000000000,
		64'b0000000000000000000010000000000000000000000000000000000000000000,
		64'b0000000000000000000100000000000000000000000000000000000000000000,
		64'b0000000000000000001000000000000000000000000000000000000000000000,
		64'b0000000000000000010000000000000000000000000000000000000000000000,
		64'b0000000000000000100000000000000000000000000000000000000000000000,
		64'b0000000000000001000000000000000000000000000000000000000000000000,
		64'b0000000000000010000000000000000000000000000000000000000000000000,
		64'b0000000000000100000000000000000000000000000000000000000000000000,
		64'b0000000000001000000000000000000000000000000000000000000000000000,
		64'b0000000000010000000000000000000000000000000000000000000000000000,
		64'b0000000000100000000000000000000000000000000000000000000000000000,
		64'b0000000001000000000000000000000000000000000000000000000000000000,
		64'b0000000010000000000000000000000000000000000000000000000000000000,
		64'b0000000100000000000000000000000000000000000000000000000000000000,
		64'b0000001000000000000000000000000000000000000000000000000000000000,
		64'b0000010000000000000000000000000000000000000000000000000000000000,
		64'b0000100000000000000000000000000000000000000000000000000000000000,
		64'b0001000000000000000000000000000000000000000000000000000000000000,
		64'b0010000000000000000000000000000000000000000000000000000000000000,
		64'b0100000000000000000000000000000000000000000000000000000000000000,
		64'b1000000000000000000000000000000000000000000000000000000000000000:   ;
		default:	collision <= collision | sprite_on;
		endcase
end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #-1
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Compute when to shift sprite bitmaps.
// Set sprite active flag
// Increment working count and address

reg [NSPR-1:0] spriteShift;
always @(posedge vclk)
for (n = 0; n < NSPR; n = n + 1)
  spriteShift[n] <= ((hctr >> lowres) >= sprite_ph[n]);

always @(posedge vclk)
for (n = 0; n < NSPR; n = n + 1)
	spriteActive[n] <= (spriteWcnt[n] <= spriteMcnt[n]) && spriteEnable[n];

always @(posedge vclk)
for (n = 0; n < NSPR; n = n + 1)
	spriteWcnt[n] <= ((vctr >> lowres) - sprite_pv[n]) * 16'd32;

always @(posedge vclk)
for (n = 0; n < NSPR; n = n + 1)
	spriteWaddr[n] <= spriteAddr[n] + spriteWcnt[n][15:2];

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
        spriteLink1[n] ? |{spriteBmp[(n+1)&(NSPR-1)][63:62],spriteBmp[n][63:62]} : 
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
`ifdef SUPPORT_LOWRES    
    	case(lowres)
    	2'd0,2'd3:	spriteBmp[n] <= {spriteBmp[n][61:0],2'h0};
    	2'd1:	if (hctr[0]) spriteBmp[n] <= {spriteBmp[n][61:0],2'h0};
    	2'd2:	if (&hctr[1:0]) spriteBmp[n] <= {spriteBmp[n][61:0],2'h0};
			endcase
`else
			spriteBmp[n] <= {spriteBmp[n][61:0],2'h0};
`endif
end

always @(posedge vclk)
for (n = 0; n < NSPR; n = n + 1)
if (spriteLink1[n])
  spriteColorNdx[n] <= {n[3:0],spriteBmp[(n+1)&(NSPR-1)][63:62],spriteBmp[n][63:62]};
else if (spriteLink1[(n-1)&(NSPR-1)])
	spriteColorNdx[n] <= 8'h00;	// transparent
else
  spriteColorNdx[n] <= {n[5:0],spriteBmp[n][63:62]};

// Compute index into sprite color palette
// If none of the sprites are linked, each sprite has it's own set of colors.
// If the sprites are linked once the colors are available in groups.
// If the sprites are linked twice they all share the same set of colors.
// Pipelining register
reg border3, border4;
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
    border3 <= border_i;
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
    border4 <= border3;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #5
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// final output registration

always @(posedge dot_clk_i)
	casez({border4,any_sprite_on4 & controller_enable})
	2'b01:	zrgb_o <= (zb_i4 <= sprite_z4) ? zrgb_i4 : {sprite_z4,flashOut};
	2'b00:	zrgb_o <= zrgb_i4;
	2'b1?:	zrgb_o <= zrgb_i4;
	endcase

endmodule

