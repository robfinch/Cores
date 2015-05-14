`timescale 1ns / 1ps
// ============================================================================
//  Bitmap Controller5
//  - Displays a bitmap from memory.
//
//
//        __
//   \\__/ o\    (C) 2008-2015  Robert Finch, Stratford
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
//		$0400000 - the second 4MiB of RAM
//
//
//	Verilog 1995
//
// ref: XC7a100t-1CSG324
// Minimum: (no rotozoom, no pixel cmd's)
// 1210 LUTs / 65 BRAMs / 600 FF's
// 80 MHz
// ============================================================================

// The following strips out both pixel_get and pixel_put when not defined.
//`define PIXEL_CMD	1'b1

// The following allows to included either ot both pixel_put and pixel get.
//`define PIXEL_GET	1'b1
//`define PIXEL_PUT	1'b1

//`define HFLIP	1'b1
//`define ROTOZOOM	1'b1

module rtfBitmapController5(
	rst_i,
	s_clk_i, s_cyc_i, s_stb_i, s_ack_o, s_we_i, s_adr_i, s_dat_i, s_dat_o, irq_o,
	m_clk_i, m_bte_o, m_cti_o, m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o,
	vclk, hsync, vsync, blank, rgbo, xonoff, refill
);
parameter pIOAddress = 32'hFFDC5000;
parameter BM_BASE_ADDR1 = 32'h0040_0000;
parameter BM_BASE_ADDR2 = 32'h0050_0000;
parameter REG_CTRL = 10'd0;
parameter REG_CTRL2 = 10'd1;
parameter REG_HDISPLAYED = 10'd2;
parameter REG_VDISPLAYED = 10'd3;
parameter REG_PAGE1ADDR = 10'd5;
parameter REG_PAGE2ADDR = 10'd6;
parameter REG_REFDELAY = 10'd7;
parameter REG_XY = 10'd8;
parameter REG_COLOR = 10'd9;
parameter REG_HSCALE = 10'd10;
parameter REG_VSCALE = 10'd11;
parameter REG_FETCHPERIOD = 10'd12;
parameter REG_NUMFETCHES = 10'd13;
parameter REG_PHETA = 10'd14;

parameter BPP6 = 3'd0;
parameter BPP8 = 3'd1;
parameter BPP9 = 3'd2;
parameter BPP12 = 3'd3;
parameter BPP15 = 3'd4;
parameter BPP16 = 3'd5;
parameter BPP24 = 3'd6;
parameter BPP32 = 3'd7;

// SYSCON
input rst_i;				// system reset

// Peripheral slave port
input s_clk_i;
input s_cyc_i;
input s_stb_i;
output s_ack_o;
input s_we_i;
input [31:0] s_adr_i;
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
input refill;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// IO registers
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg m_cyc_o;
reg [31:0] m_adr_o;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire cs = s_cyc_i && s_stb_i && (s_adr_i[31:12]==pIOAddress[31:12]);
reg ack,ack1;
always @(posedge s_clk_i)
begin
	ack1 <= cs;
	ack <= ack1 & cs;
end
assign s_ack_o = cs ? (s_we_i ? 1'b1 : ack) : 1'b0;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [11:0] hDisplayed,vDisplayed;
reg [23:0] hScale,vScale;
reg hFlip,vFlip;
reg [11:0] fetchPeriod;
reg [19:0] numFetches;
reg [31:0] bm_base_addr1,bm_base_addr2;
reg [2:0] color_depth;
wire [7:0] fifo_cnt;
reg [8:0] pheta;
reg onoff;
reg greyscale;
reg page;
reg pals;				// palette select
reg [11:0] hrefdelay;
reg [11:0] vrefdelay;
reg [11:0] hctr;		// horizontal reference counter
wire signed [11:0] hctr1 = hctr - hrefdelay;
reg [11:0] vctr;		// vertical reference counter
wire signed [11:0] vctr1 = vctr - vrefdelay;
reg [31:0] baseAddr;	// base address register
wire [127:0] rgbo1;
wire [31:0] rgbo2;
reg [31:0] rgbo3;
wire [31:0] pal_wo;
wire [31:0] pal_o;
reg [11:0] px;
reg [11:0] py;
reg [1:0] pcmd,pcmd_o;
reg [31:0] color;
reg [31:0] color_o;
reg rstcmd;

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
reg rstcmd1;
always @(posedge s_clk_i)
if (rst_i) begin
	page <= 1'b0;
	pals <= 1'b0;
	hScale <= 24'b0_100000000000;	// 1/2 display
	vScale <= 24'b0_010101010101;	// 1/3 display
	hFlip <= 1'b0;
	vFlip <= 1'b0;
	hDisplayed <= 12'd340;
	vDisplayed <= 12'd256;
	onoff <= 1'b1;
	color_depth <= BPP12;
	greyscale <= 1'b0;
	bm_base_addr1 <= BM_BASE_ADDR1;
	bm_base_addr2 <= BM_BASE_ADDR2;
	hrefdelay <= 12'd109;//12'd218;
	vrefdelay <= 12'd27;
	fetchPeriod <= 12'd90;	// good for 340x256 mode
	numFetches <= 20'd8703;
	pheta <= 9'd0;
end
else begin
	rstcmd1 <= rstcmd;
	if (rstcmd & ~rstcmd1)
		pcmd <= 2'b00;
	if (cs) begin
		if (s_we_i) begin
			casex(s_adr_i[11:2])
			REG_CTRL:
				begin
					onoff <= s_dat_i[0];
					color_depth <= s_dat_i[10:8];
					greyscale <= s_dat_i[11];
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
`ifdef PIXEL_CMD
			REG_XY:
				begin
					px <= s_dat_i[11: 0];
					py <= s_dat_i[27:16];
					pcmd <= s_dat_i[31:30];
				end
			REG_COLOR:
				color <= s_dat_i;
`endif
			REG_HSCALE:
				begin
					hScale <= s_dat_i[23:0];
					hFlip <= s_dat_i[31];
				end
			REG_VSCALE:
				begin
					vScale <= s_dat_i[23:0];
					vFlip <= s_dat_i[31];
				end
			REG_FETCHPERIOD:
				fetchPeriod <= s_dat_i[11:0];
			REG_NUMFETCHES:
				numFetches <= s_dat_i[19:0];
`ifdef ROTOZOOM
			REG_PHETA: pheta <= s_dat_i[8:0];
`endif
			endcase
		end
		casex(s_adr_i[11:2])
		REG_CTRL:
			begin
				s_dat_o[0] <= onoff;
				s_dat_o[10:8] <= color_depth;
				s_dat_o[11] <= greyscale;
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
		REG_REFDELAY:	s_dat_o <= {vrefdelay,4'h0,hrefdelay};
`ifdef PIXEL_CMD
		REG_XY:			s_dat_o <= {pcmd,2'b0,py,4'b0,px};
		REG_COLOR:		s_dat_o <= color_o;
`endif
		REG_HSCALE:	    s_dat_o <= {hFlip,7'b0,hScale};
		REG_VSCALE:	    s_dat_o <= {vFlip,7'b0,vScale};
		REG_FETCHPERIOD:s_dat_o <= fetchPeriod;
		REG_NUMFETCHES:	s_dat_o <= numFetches;
`ifdef ROTOZOOM
		REG_PHETA:		s_dat_o <= pheta;
`endif
		10'b1xxx_xxxx_xx:	s_dat_o <= pal_wo;
		endcase
	end
	else
		s_dat_o <= 32'd0;
end

assign irq_o = 1'b0;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Horizontal and Vertical timing reference counters
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire pe_hsync;
wire pe_vsync,pe_vsync2;
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

edge_det edv2
(
	.rst(rst_i),
	.clk(m_clk_i),
	.ce(1'b1),
	.i(vsync),
	.pe(pe_vsync2),
	.ne(),
	.ee()
);

always @(posedge vclk)
if (rst_i)
	hctr <= 4'd1;
else if (pe_hsync)
	hctr <= hFlip ? hDisplayed : 4'd1;
else
	hctr <= hFlip ? hctr - 4'd1 : hctr + 4'd1;

always @(posedge vclk)
if (rst_i)
	vctr <= 4'd1;
else if (pe_vsync)
	vctr <= vFlip ? vDisplayed : 4'd1;
else if (pe_hsync)
	vctr <= vFlip ? vctr - 4'd1 : vctr + 4'd1;

reg [12:0] sintbl [511:0];
initial begin
sintbl[0] <= {1'b0,12'd0};
sintbl[1] <= {1'b0,12'd71};
sintbl[2] <= {1'b0,12'd142};
sintbl[3] <= {1'b0,12'd214};
sintbl[4] <= {1'b0,12'd285};
sintbl[5] <= {1'b0,12'd356};
sintbl[6] <= {1'b0,12'd428};
sintbl[7] <= {1'b0,12'd499};
sintbl[8] <= {1'b0,12'd569};
sintbl[9] <= {1'b0,12'd640};
sintbl[10] <= {1'b0,12'd711};
sintbl[11] <= {1'b0,12'd781};
sintbl[12] <= {1'b0,12'd851};
sintbl[13] <= {1'b0,12'd921};
sintbl[14] <= {1'b0,12'd990};
sintbl[15] <= {1'b0,12'd1059};
sintbl[16] <= {1'b0,12'd1128};
sintbl[17] <= {1'b0,12'd1197};
sintbl[18] <= {1'b0,12'd1265};
sintbl[19] <= {1'b0,12'd1333};
sintbl[20] <= {1'b0,12'd1400};
sintbl[21] <= {1'b0,12'd1467};
sintbl[22] <= {1'b0,12'd1534};
sintbl[23] <= {1'b0,12'd1600};
sintbl[24] <= {1'b0,12'd1665};
sintbl[25] <= {1'b0,12'd1730};
sintbl[26] <= {1'b0,12'd1795};
sintbl[27] <= {1'b0,12'd1859};
sintbl[28] <= {1'b0,12'd1922};
sintbl[29] <= {1'b0,12'd1985};
sintbl[30] <= {1'b0,12'd2047};
sintbl[31] <= {1'b0,12'd2109};
sintbl[32] <= {1'b0,12'd2170};
sintbl[33] <= {1'b0,12'd2230};
sintbl[34] <= {1'b0,12'd2289};
sintbl[35] <= {1'b0,12'd2348};
sintbl[36] <= {1'b0,12'd2406};
sintbl[37] <= {1'b0,12'd2464};
sintbl[38] <= {1'b0,12'd2521};
sintbl[39] <= {1'b0,12'd2577};
sintbl[40] <= {1'b0,12'd2632};
sintbl[41] <= {1'b0,12'd2686};
sintbl[42] <= {1'b0,12'd2740};
sintbl[43] <= {1'b0,12'd2792};
sintbl[44] <= {1'b0,12'd2844};
sintbl[45] <= {1'b0,12'd2895};
sintbl[46] <= {1'b0,12'd2945};
sintbl[47] <= {1'b0,12'd2994};
sintbl[48] <= {1'b0,12'd3043};
sintbl[49] <= {1'b0,12'd3090};
sintbl[50] <= {1'b0,12'd3136};
sintbl[51] <= {1'b0,12'd3182};
sintbl[52] <= {1'b0,12'd3226};
sintbl[53] <= {1'b0,12'd3270};
sintbl[54] <= {1'b0,12'd3312};
sintbl[55] <= {1'b0,12'd3354};
sintbl[56] <= {1'b0,12'd3394};
sintbl[57] <= {1'b0,12'd3434};
sintbl[58] <= {1'b0,12'd3472};
sintbl[59] <= {1'b0,12'd3510};
sintbl[60] <= {1'b0,12'd3546};
sintbl[61] <= {1'b0,12'd3581};
sintbl[62] <= {1'b0,12'd3615};
sintbl[63] <= {1'b0,12'd3648};
sintbl[64] <= {1'b0,12'd3680};
sintbl[65] <= {1'b0,12'd3711};
sintbl[66] <= {1'b0,12'd3740};
sintbl[67] <= {1'b0,12'd3769};
sintbl[68] <= {1'b0,12'd3796};
sintbl[69] <= {1'b0,12'd3823};
sintbl[70] <= {1'b0,12'd3848};
sintbl[71] <= {1'b0,12'd3871};
sintbl[72] <= {1'b0,12'd3894};
sintbl[73] <= {1'b0,12'd3916};
sintbl[74] <= {1'b0,12'd3936};
sintbl[75] <= {1'b0,12'd3955};
sintbl[76] <= {1'b0,12'd3973};
sintbl[77] <= {1'b0,12'd3990};
sintbl[78] <= {1'b0,12'd4005};
sintbl[79] <= {1'b0,12'd4019};
sintbl[80] <= {1'b0,12'd4032};
sintbl[81] <= {1'b0,12'd4044};
sintbl[82] <= {1'b0,12'd4055};
sintbl[83] <= {1'b0,12'd4064};
sintbl[84] <= {1'b0,12'd4072};
sintbl[85] <= {1'b0,12'd4079};
sintbl[86] <= {1'b0,12'd4085};
sintbl[87] <= {1'b0,12'd4089};
sintbl[88] <= {1'b0,12'd4092};
sintbl[89] <= {1'b0,12'd4094};
sintbl[90] <= {1'b0,12'd4095};
sintbl[91] <= {1'b0,12'd4094};
sintbl[92] <= {1'b0,12'd4092};
sintbl[93] <= {1'b0,12'd4089};
sintbl[94] <= {1'b0,12'd4085};
sintbl[95] <= {1'b0,12'd4079};
sintbl[96] <= {1'b0,12'd4072};
sintbl[97] <= {1'b0,12'd4064};
sintbl[98] <= {1'b0,12'd4055};
sintbl[99] <= {1'b0,12'd4044};
sintbl[100] <= {1'b0,12'd4032};
sintbl[101] <= {1'b0,12'd4019};
sintbl[102] <= {1'b0,12'd4005};
sintbl[103] <= {1'b0,12'd3990};
sintbl[104] <= {1'b0,12'd3973};
sintbl[105] <= {1'b0,12'd3955};
sintbl[106] <= {1'b0,12'd3936};
sintbl[107] <= {1'b0,12'd3916};
sintbl[108] <= {1'b0,12'd3894};
sintbl[109] <= {1'b0,12'd3871};
sintbl[110] <= {1'b0,12'd3848};
sintbl[111] <= {1'b0,12'd3823};
sintbl[112] <= {1'b0,12'd3796};
sintbl[113] <= {1'b0,12'd3769};
sintbl[114] <= {1'b0,12'd3740};
sintbl[115] <= {1'b0,12'd3711};
sintbl[116] <= {1'b0,12'd3680};
sintbl[117] <= {1'b0,12'd3648};
sintbl[118] <= {1'b0,12'd3615};
sintbl[119] <= {1'b0,12'd3581};
sintbl[120] <= {1'b0,12'd3546};
sintbl[121] <= {1'b0,12'd3510};
sintbl[122] <= {1'b0,12'd3472};
sintbl[123] <= {1'b0,12'd3434};
sintbl[124] <= {1'b0,12'd3394};
sintbl[125] <= {1'b0,12'd3354};
sintbl[126] <= {1'b0,12'd3312};
sintbl[127] <= {1'b0,12'd3270};
sintbl[128] <= {1'b0,12'd3226};
sintbl[129] <= {1'b0,12'd3182};
sintbl[130] <= {1'b0,12'd3136};
sintbl[131] <= {1'b0,12'd3090};
sintbl[132] <= {1'b0,12'd3043};
sintbl[133] <= {1'b0,12'd2994};
sintbl[134] <= {1'b0,12'd2945};
sintbl[135] <= {1'b0,12'd2895};
sintbl[136] <= {1'b0,12'd2844};
sintbl[137] <= {1'b0,12'd2792};
sintbl[138] <= {1'b0,12'd2740};
sintbl[139] <= {1'b0,12'd2686};
sintbl[140] <= {1'b0,12'd2632};
sintbl[141] <= {1'b0,12'd2577};
sintbl[142] <= {1'b0,12'd2521};
sintbl[143] <= {1'b0,12'd2464};
sintbl[144] <= {1'b0,12'd2406};
sintbl[145] <= {1'b0,12'd2348};
sintbl[146] <= {1'b0,12'd2289};
sintbl[147] <= {1'b0,12'd2230};
sintbl[148] <= {1'b0,12'd2170};
sintbl[149] <= {1'b0,12'd2109};
sintbl[150] <= {1'b0,12'd2047};
sintbl[151] <= {1'b0,12'd1985};
sintbl[152] <= {1'b0,12'd1922};
sintbl[153] <= {1'b0,12'd1859};
sintbl[154] <= {1'b0,12'd1795};
sintbl[155] <= {1'b0,12'd1730};
sintbl[156] <= {1'b0,12'd1665};
sintbl[157] <= {1'b0,12'd1600};
sintbl[158] <= {1'b0,12'd1534};
sintbl[159] <= {1'b0,12'd1467};
sintbl[160] <= {1'b0,12'd1400};
sintbl[161] <= {1'b0,12'd1333};
sintbl[162] <= {1'b0,12'd1265};
sintbl[163] <= {1'b0,12'd1197};
sintbl[164] <= {1'b0,12'd1128};
sintbl[165] <= {1'b0,12'd1059};
sintbl[166] <= {1'b0,12'd990};
sintbl[167] <= {1'b0,12'd921};
sintbl[168] <= {1'b0,12'd851};
sintbl[169] <= {1'b0,12'd781};
sintbl[170] <= {1'b0,12'd711};
sintbl[171] <= {1'b0,12'd640};
sintbl[172] <= {1'b0,12'd569};
sintbl[173] <= {1'b0,12'd499};
sintbl[174] <= {1'b0,12'd428};
sintbl[175] <= {1'b0,12'd356};
sintbl[176] <= {1'b0,12'd285};
sintbl[177] <= {1'b0,12'd214};
sintbl[178] <= {1'b0,12'd142};
sintbl[179] <= {1'b0,12'd71};
sintbl[180] <= {1'b0,12'd0};
sintbl[181] <= {1'b1,12'd71};
sintbl[182] <= {1'b1,12'd142};
sintbl[183] <= {1'b1,12'd214};
sintbl[184] <= {1'b1,12'd285};
sintbl[185] <= {1'b1,12'd356};
sintbl[186] <= {1'b1,12'd428};
sintbl[187] <= {1'b1,12'd499};
sintbl[188] <= {1'b1,12'd569};
sintbl[189] <= {1'b1,12'd640};
sintbl[190] <= {1'b1,12'd711};
sintbl[191] <= {1'b1,12'd781};
sintbl[192] <= {1'b1,12'd851};
sintbl[193] <= {1'b1,12'd921};
sintbl[194] <= {1'b1,12'd990};
sintbl[195] <= {1'b1,12'd1059};
sintbl[196] <= {1'b1,12'd1128};
sintbl[197] <= {1'b1,12'd1197};
sintbl[198] <= {1'b1,12'd1265};
sintbl[199] <= {1'b1,12'd1333};
sintbl[200] <= {1'b1,12'd1400};
sintbl[201] <= {1'b1,12'd1467};
sintbl[202] <= {1'b1,12'd1534};
sintbl[203] <= {1'b1,12'd1600};
sintbl[204] <= {1'b1,12'd1665};
sintbl[205] <= {1'b1,12'd1730};
sintbl[206] <= {1'b1,12'd1795};
sintbl[207] <= {1'b1,12'd1859};
sintbl[208] <= {1'b1,12'd1922};
sintbl[209] <= {1'b1,12'd1985};
sintbl[210] <= {1'b1,12'd2047};
sintbl[211] <= {1'b1,12'd2109};
sintbl[212] <= {1'b1,12'd2170};
sintbl[213] <= {1'b1,12'd2230};
sintbl[214] <= {1'b1,12'd2289};
sintbl[215] <= {1'b1,12'd2348};
sintbl[216] <= {1'b1,12'd2406};
sintbl[217] <= {1'b1,12'd2464};
sintbl[218] <= {1'b1,12'd2521};
sintbl[219] <= {1'b1,12'd2577};
sintbl[220] <= {1'b1,12'd2632};
sintbl[221] <= {1'b1,12'd2686};
sintbl[222] <= {1'b1,12'd2740};
sintbl[223] <= {1'b1,12'd2792};
sintbl[224] <= {1'b1,12'd2844};
sintbl[225] <= {1'b1,12'd2895};
sintbl[226] <= {1'b1,12'd2945};
sintbl[227] <= {1'b1,12'd2994};
sintbl[228] <= {1'b1,12'd3043};
sintbl[229] <= {1'b1,12'd3090};
sintbl[230] <= {1'b1,12'd3136};
sintbl[231] <= {1'b1,12'd3182};
sintbl[232] <= {1'b1,12'd3226};
sintbl[233] <= {1'b1,12'd3270};
sintbl[234] <= {1'b1,12'd3312};
sintbl[235] <= {1'b1,12'd3354};
sintbl[236] <= {1'b1,12'd3394};
sintbl[237] <= {1'b1,12'd3434};
sintbl[238] <= {1'b1,12'd3472};
sintbl[239] <= {1'b1,12'd3510};
sintbl[240] <= {1'b1,12'd3546};
sintbl[241] <= {1'b1,12'd3581};
sintbl[242] <= {1'b1,12'd3615};
sintbl[243] <= {1'b1,12'd3648};
sintbl[244] <= {1'b1,12'd3680};
sintbl[245] <= {1'b1,12'd3711};
sintbl[246] <= {1'b1,12'd3740};
sintbl[247] <= {1'b1,12'd3769};
sintbl[248] <= {1'b1,12'd3796};
sintbl[249] <= {1'b1,12'd3823};
sintbl[250] <= {1'b1,12'd3848};
sintbl[251] <= {1'b1,12'd3871};
sintbl[252] <= {1'b1,12'd3894};
sintbl[253] <= {1'b1,12'd3916};
sintbl[254] <= {1'b1,12'd3936};
sintbl[255] <= {1'b1,12'd3955};
sintbl[256] <= {1'b1,12'd3973};
sintbl[257] <= {1'b1,12'd3990};
sintbl[258] <= {1'b1,12'd4005};
sintbl[259] <= {1'b1,12'd4019};
sintbl[260] <= {1'b1,12'd4032};
sintbl[261] <= {1'b1,12'd4044};
sintbl[262] <= {1'b1,12'd4055};
sintbl[263] <= {1'b1,12'd4064};
sintbl[264] <= {1'b1,12'd4072};
sintbl[265] <= {1'b1,12'd4079};
sintbl[266] <= {1'b1,12'd4085};
sintbl[267] <= {1'b1,12'd4089};
sintbl[268] <= {1'b1,12'd4092};
sintbl[269] <= {1'b1,12'd4094};
sintbl[270] <= {1'b1,12'd4095};
sintbl[271] <= {1'b1,12'd4094};
sintbl[272] <= {1'b1,12'd4092};
sintbl[273] <= {1'b1,12'd4089};
sintbl[274] <= {1'b1,12'd4085};
sintbl[275] <= {1'b1,12'd4079};
sintbl[276] <= {1'b1,12'd4072};
sintbl[277] <= {1'b1,12'd4064};
sintbl[278] <= {1'b1,12'd4055};
sintbl[279] <= {1'b1,12'd4044};
sintbl[280] <= {1'b1,12'd4032};
sintbl[281] <= {1'b1,12'd4019};
sintbl[282] <= {1'b1,12'd4005};
sintbl[283] <= {1'b1,12'd3990};
sintbl[284] <= {1'b1,12'd3973};
sintbl[285] <= {1'b1,12'd3955};
sintbl[286] <= {1'b1,12'd3936};
sintbl[287] <= {1'b1,12'd3916};
sintbl[288] <= {1'b1,12'd3894};
sintbl[289] <= {1'b1,12'd3871};
sintbl[290] <= {1'b1,12'd3848};
sintbl[291] <= {1'b1,12'd3823};
sintbl[292] <= {1'b1,12'd3796};
sintbl[293] <= {1'b1,12'd3769};
sintbl[294] <= {1'b1,12'd3740};
sintbl[295] <= {1'b1,12'd3711};
sintbl[296] <= {1'b1,12'd3680};
sintbl[297] <= {1'b1,12'd3648};
sintbl[298] <= {1'b1,12'd3615};
sintbl[299] <= {1'b1,12'd3581};
sintbl[300] <= {1'b1,12'd3546};
sintbl[301] <= {1'b1,12'd3510};
sintbl[302] <= {1'b1,12'd3472};
sintbl[303] <= {1'b1,12'd3434};
sintbl[304] <= {1'b1,12'd3394};
sintbl[305] <= {1'b1,12'd3354};
sintbl[306] <= {1'b1,12'd3312};
sintbl[307] <= {1'b1,12'd3270};
sintbl[308] <= {1'b1,12'd3226};
sintbl[309] <= {1'b1,12'd3182};
sintbl[310] <= {1'b1,12'd3136};
sintbl[311] <= {1'b1,12'd3090};
sintbl[312] <= {1'b1,12'd3043};
sintbl[313] <= {1'b1,12'd2994};
sintbl[314] <= {1'b1,12'd2945};
sintbl[315] <= {1'b1,12'd2895};
sintbl[316] <= {1'b1,12'd2844};
sintbl[317] <= {1'b1,12'd2792};
sintbl[318] <= {1'b1,12'd2740};
sintbl[319] <= {1'b1,12'd2686};
sintbl[320] <= {1'b1,12'd2632};
sintbl[321] <= {1'b1,12'd2577};
sintbl[322] <= {1'b1,12'd2521};
sintbl[323] <= {1'b1,12'd2464};
sintbl[324] <= {1'b1,12'd2406};
sintbl[325] <= {1'b1,12'd2348};
sintbl[326] <= {1'b1,12'd2289};
sintbl[327] <= {1'b1,12'd2230};
sintbl[328] <= {1'b1,12'd2170};
sintbl[329] <= {1'b1,12'd2109};
sintbl[330] <= {1'b1,12'd2047};
sintbl[331] <= {1'b1,12'd1985};
sintbl[332] <= {1'b1,12'd1922};
sintbl[333] <= {1'b1,12'd1859};
sintbl[334] <= {1'b1,12'd1795};
sintbl[335] <= {1'b1,12'd1730};
sintbl[336] <= {1'b1,12'd1665};
sintbl[337] <= {1'b1,12'd1600};
sintbl[338] <= {1'b1,12'd1534};
sintbl[339] <= {1'b1,12'd1467};
sintbl[340] <= {1'b1,12'd1400};
sintbl[341] <= {1'b1,12'd1333};
sintbl[342] <= {1'b1,12'd1265};
sintbl[343] <= {1'b1,12'd1197};
sintbl[344] <= {1'b1,12'd1128};
sintbl[345] <= {1'b1,12'd1059};
sintbl[346] <= {1'b1,12'd990};
sintbl[347] <= {1'b1,12'd921};
sintbl[348] <= {1'b1,12'd851};
sintbl[349] <= {1'b1,12'd781};
sintbl[350] <= {1'b1,12'd711};
sintbl[351] <= {1'b1,12'd640};
sintbl[352] <= {1'b1,12'd569};
sintbl[353] <= {1'b1,12'd499};
sintbl[354] <= {1'b1,12'd428};
sintbl[355] <= {1'b1,12'd356};
sintbl[356] <= {1'b1,12'd285};
sintbl[357] <= {1'b1,12'd214};
sintbl[358] <= {1'b1,12'd142};
sintbl[359] <= {1'b1,12'd71};
sintbl[360] <= {1'b0,12'd0};
sintbl[361] <= {1'b0,12'd71};
sintbl[362] <= {1'b0,12'd142};
sintbl[363] <= {1'b0,12'd214};
sintbl[364] <= {1'b0,12'd285};
sintbl[365] <= {1'b0,12'd356};
sintbl[366] <= {1'b0,12'd428};
sintbl[367] <= {1'b0,12'd499};
sintbl[368] <= {1'b0,12'd569};
sintbl[369] <= {1'b0,12'd640};
sintbl[370] <= {1'b0,12'd711};
sintbl[371] <= {1'b0,12'd781};
sintbl[372] <= {1'b0,12'd851};
sintbl[373] <= {1'b0,12'd921};
sintbl[374] <= {1'b0,12'd990};
sintbl[375] <= {1'b0,12'd1059};
sintbl[376] <= {1'b0,12'd1128};
sintbl[377] <= {1'b0,12'd1197};
sintbl[378] <= {1'b0,12'd1265};
sintbl[379] <= {1'b0,12'd1333};
sintbl[380] <= {1'b0,12'd1400};
sintbl[381] <= {1'b0,12'd1467};
sintbl[382] <= {1'b0,12'd1534};
sintbl[383] <= {1'b0,12'd1600};
sintbl[384] <= {1'b0,12'd1665};
sintbl[385] <= {1'b0,12'd1730};
sintbl[386] <= {1'b0,12'd1795};
sintbl[387] <= {1'b0,12'd1859};
sintbl[388] <= {1'b0,12'd1922};
sintbl[389] <= {1'b0,12'd1985};
sintbl[390] <= {1'b0,12'd2047};
sintbl[391] <= {1'b0,12'd2109};
sintbl[392] <= {1'b0,12'd2170};
sintbl[393] <= {1'b0,12'd2230};
sintbl[394] <= {1'b0,12'd2289};
sintbl[395] <= {1'b0,12'd2348};
sintbl[396] <= {1'b0,12'd2406};
sintbl[397] <= {1'b0,12'd2464};
sintbl[398] <= {1'b0,12'd2521};
sintbl[399] <= {1'b0,12'd2577};
sintbl[400] <= {1'b0,12'd2632};
sintbl[401] <= {1'b0,12'd2686};
sintbl[402] <= {1'b0,12'd2740};
sintbl[403] <= {1'b0,12'd2792};
sintbl[404] <= {1'b0,12'd2844};
sintbl[405] <= {1'b0,12'd2895};
sintbl[406] <= {1'b0,12'd2945};
sintbl[407] <= {1'b0,12'd2994};
sintbl[408] <= {1'b0,12'd3043};
sintbl[409] <= {1'b0,12'd3090};
sintbl[410] <= {1'b0,12'd3136};
sintbl[411] <= {1'b0,12'd3182};
sintbl[412] <= {1'b0,12'd3226};
sintbl[413] <= {1'b0,12'd3270};
sintbl[414] <= {1'b0,12'd3312};
sintbl[415] <= {1'b0,12'd3354};
sintbl[416] <= {1'b0,12'd3394};
sintbl[417] <= {1'b0,12'd3434};
sintbl[418] <= {1'b0,12'd3472};
sintbl[419] <= {1'b0,12'd3510};
sintbl[420] <= {1'b0,12'd3546};
sintbl[421] <= {1'b0,12'd3581};
sintbl[422] <= {1'b0,12'd3615};
sintbl[423] <= {1'b0,12'd3648};
sintbl[424] <= {1'b0,12'd3680};
sintbl[425] <= {1'b0,12'd3711};
sintbl[426] <= {1'b0,12'd3740};
sintbl[427] <= {1'b0,12'd3769};
sintbl[428] <= {1'b0,12'd3796};
sintbl[429] <= {1'b0,12'd3823};
sintbl[430] <= {1'b0,12'd3848};
sintbl[431] <= {1'b0,12'd3871};
sintbl[432] <= {1'b0,12'd3894};
sintbl[433] <= {1'b0,12'd3916};
sintbl[434] <= {1'b0,12'd3936};
sintbl[435] <= {1'b0,12'd3955};
sintbl[436] <= {1'b0,12'd3973};
sintbl[437] <= {1'b0,12'd3990};
sintbl[438] <= {1'b0,12'd4005};
sintbl[439] <= {1'b0,12'd4019};
sintbl[440] <= {1'b0,12'd4032};
sintbl[441] <= {1'b0,12'd4044};
sintbl[442] <= {1'b0,12'd4055};
sintbl[443] <= {1'b0,12'd4064};
sintbl[444] <= {1'b0,12'd4072};
sintbl[445] <= {1'b0,12'd4079};
sintbl[446] <= {1'b0,12'd4085};
sintbl[447] <= {1'b0,12'd4089};
sintbl[448] <= {1'b0,12'd4092};
sintbl[449] <= {1'b0,12'd4094};
sintbl[450] <= {1'b0,12'd4095};
sintbl[451] <= {1'b0,12'd4094};
sintbl[452] <= {1'b0,12'd4092};
sintbl[453] <= {1'b0,12'd4089};
sintbl[454] <= {1'b0,12'd4085};
sintbl[455] <= {1'b0,12'd4079};
sintbl[456] <= {1'b0,12'd4072};
sintbl[457] <= {1'b0,12'd4064};
sintbl[458] <= {1'b0,12'd4055};
sintbl[459] <= {1'b0,12'd4044};
sintbl[460] <= {1'b0,12'd4032};
sintbl[461] <= {1'b0,12'd4019};
sintbl[462] <= {1'b0,12'd4005};
sintbl[463] <= {1'b0,12'd3990};
sintbl[464] <= {1'b0,12'd3973};
sintbl[465] <= {1'b0,12'd3955};
sintbl[466] <= {1'b0,12'd3936};
sintbl[467] <= {1'b0,12'd3916};
sintbl[468] <= {1'b0,12'd3894};
sintbl[469] <= {1'b0,12'd3871};
sintbl[470] <= {1'b0,12'd3848};
sintbl[471] <= {1'b0,12'd3823};
sintbl[472] <= {1'b0,12'd3796};
sintbl[473] <= {1'b0,12'd3769};
sintbl[474] <= {1'b0,12'd3740};
sintbl[475] <= {1'b0,12'd3711};
sintbl[476] <= {1'b0,12'd3680};
sintbl[477] <= {1'b0,12'd3648};
sintbl[478] <= {1'b0,12'd3615};
sintbl[479] <= {1'b0,12'd3581};
sintbl[480] <= {1'b0,12'd3546};
sintbl[481] <= {1'b0,12'd3510};
sintbl[482] <= {1'b0,12'd3472};
sintbl[483] <= {1'b0,12'd3434};
sintbl[484] <= {1'b0,12'd3394};
sintbl[485] <= {1'b0,12'd3354};
sintbl[486] <= {1'b0,12'd3312};
sintbl[487] <= {1'b0,12'd3270};
sintbl[488] <= {1'b0,12'd3226};
sintbl[489] <= {1'b0,12'd3182};
sintbl[490] <= {1'b0,12'd3136};
sintbl[491] <= {1'b0,12'd3090};
sintbl[492] <= {1'b0,12'd3043};
sintbl[493] <= {1'b0,12'd2994};
sintbl[494] <= {1'b0,12'd2945};
sintbl[495] <= {1'b0,12'd2895};
sintbl[496] <= {1'b0,12'd2844};
sintbl[497] <= {1'b0,12'd2792};
sintbl[498] <= {1'b0,12'd2740};
sintbl[499] <= {1'b0,12'd2686};
sintbl[500] <= {1'b0,12'd2632};
sintbl[501] <= {1'b0,12'd2577};
sintbl[502] <= {1'b0,12'd2521};
sintbl[503] <= {1'b0,12'd2464};
sintbl[504] <= {1'b0,12'd2406};
sintbl[505] <= {1'b0,12'd2348};
sintbl[506] <= {1'b0,12'd2289};
sintbl[507] <= {1'b0,12'd2230};
sintbl[508] <= {1'b0,12'd2170};
sintbl[509] <= {1'b0,12'd2109};
sintbl[510] <= {1'b0,12'd2047};
sintbl[511] <= {1'b0,12'd1985};
end

// hScale and vScale are 24 bit fixed point numbers with 12 bits on each side
// of the decimal point.
reg [15:0] pixelCol;
reg [15:0] pixelRow;
reg signed [15:0] pixelColT1;
reg signed [15:0] pixelRowT1;
reg signed [15:-12] pixelColT2;
reg signed [15:-12] pixelRowT2;
reg signed [15:-12] pixelColT3;
reg signed [15:-12] pixelRowT3;
reg signed [12:0] sino,coso;
// Translate screen co-ordinates to center screen of 0,0
`ifdef ROTOZOOM
always @(posedge vclk)
	pixelColT1 = hctr1 - (hDisplayed >> 1);
always @(posedge vclk)
	pixelRowT1 = vctr1 - (vDisplayed >> 1);
// Lookup the sine and cosine
always @(posedge vclk)
	sino <= sintbl[pheta];
always @(posedge vclk)
	coso <= sintbl[pheta+9'd90];
// Do the roto
always @(posedge vclk)
	pixelColT2 = (coso[12] ? -(pixelColT1 * coso[11:0]) : (pixelColT1 * coso[11:0])) -
	             (sino[12] ? -(pixelRowT1 * sino[11:0]) : (pixelRowT1 * sino[11:0]));	// x' = x cos - y sin
always @(posedge vclk)
	pixelRowT2 = (coso[12] ? -(pixelRowT1 * coso[11:0]) : (pixelRowT1 * coso[11:0])) +
				 (sino[12] ? -(pixelColT1 * sino[11:0]) : (pixelColT1 * sino[11:0]));	// y' = y cos + x sin
// Translate co-ordinates back and zoom
always @(posedge vclk)
	pixelColT3 = (pixelColT2[15:0] + (hDisplayed >> 1)) * hScale;
always @(posedge vclk)
	pixelRowT3 = (pixelRowT2[15:0] + (vDisplayed >> 1)) * vScale;
`else
always @(posedge vclk)
	pixelColT3 = hctr1 * hScale;
always @(posedge vclk)
	pixelRowT3 = vctr1 * vScale;
`endif
always @(posedge vclk)
	pixelCol <= pixelColT3[15:0];
always @(posedge vclk)
	pixelRow <= pixelRowT3[15:0];

wire[31:0] grAddr,xyAddr;
reg [11:0] fetchCol;
reg [6:0] me1,mb1;
wire [6:0] mb,me,mb2,me2;
reg [31:4] strip_addr;
reg [127:0] mem_strip;
wire [127:0] mem_strip_o;
wire [31:0] mem_color;

gfx_CalcAddress u1
(
	.clk(vclk),
	.base_address_i(32'h0),
	.color_depth_i(color_depth),
	.hdisplayed_i(hDisplayed),
	.x_coord_i(pixelCol),
	.y_coord_i(pixelRow),
	.address_o(grAddr),
	.mb_o(mb2),
	.me_o(me2)
);

always @(posedge vclk)
	mb1 <= mb2;
always @(posedge vclk)
	me1 <= me2;
	
gfx_CalcAddress u2
(
	.clk(m_clk_i),
	.base_address_i(baseAddr),
	.color_depth_i(color_depth),
	.hdisplayed_i(hDisplayed),
	.x_coord_i(px),
	.y_coord_i(py),
	.address_o(xyAddr),
	.mb_o(mb),
	.me_o(me)
);

mem2color u3
(
	.mem_i(mem_strip),
	.mb_i(mb),
	.me_i(me),
	.color_o(mem_color)
);

color2mem u4
(
	.mem_i(mem_strip),
	.mb_i(mb),
	.me_i(me),
	.color_i(color),
	.mem_o(mem_strip_o)
);

mem2color u5
(
	.mem_i(rgbo1),
	.mb_i(mb1),
	.me_i(me1),
	.color_o(rgbo2)
);

always @(posedge vclk)
	rgbo3 <= rgbo2;

// The following bypasses loading the fifo when all the pixels from a scanline
// are buffered in the fifo and the pixel row doesn't change. Since the fifo
// pointers are reset at the beginning of a scanline, the fifo can be used like
// a cache.
wire blankEdge;
edge_det ed2(.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(blank), .pe(blankEdge), .ne(), .ee() );

assign m_bte_o = 2'b00;
assign m_cti_o = 3'b000;
assign m_stb_o = 1'b1;
assign m_sel_o = 16'hFFFF;

reg [31:0] adr;
reg [2:0] state;
parameter IDLE = 3'd1;
parameter LOADCOLOR = 3'd2;
parameter LOADSTRIP = 3'd3;
parameter STORESTRIP = 3'd4;
parameter ACKSTRIP = 3'd5;
parameter WAITLOAD = 3'd6;
parameter WAITRST = 3'd7;

reg [11:0] fetchDlyCnt;
reg [19:0] fetchCnt;
reg do_fetch;
always @(posedge m_clk_i)
if (rst_i) begin
	wb_nack();
	strip_addr <= 28'hFFFFFFF;
	rstcmd <= 1'b0;
	state <= IDLE;
	do_fetch <= 1'b0;
	fetchDlyCnt <= 12'h000;
	fetchCnt <= 20'h000;
end
else begin
	fetchDlyCnt <= fetchDlyCnt + 12'd1;
	if (fetchDlyCnt>=fetchPeriod && fetchCnt <= numFetches) begin
		fetchDlyCnt <= 12'h000;
		do_fetch <= 1'b1;
	end
	if (pe_vsync2 & refill) begin
		do_fetch <= 1'b0;
		fetchCnt <= 20'h000;
		fetchDlyCnt <= 12'h000;
		adr <= baseAddr;
	end
	case(state)
`ifdef PIXEL_CMD
	WAITRST:
		if (pcmd==2'b00) begin
			rstcmd <= 1'b0;
			state <= IDLE;
		end
		else
			rstcmd <= 1'b1;
`endif
	IDLE:
		if (do_fetch) begin
			do_fetch <= 1'b0;
			fetchCnt <= fetchCnt + 20'd1;
			m_cyc_o <= 1'b1;
			m_we_o <= 1'b0;
			m_adr_o <= adr;
			state <= WAITLOAD;
		end
`ifdef PIXEL_CMD
		else if (pcmd!=2'b00) begin
			if (xyAddr[31:4]!=strip_addr || 1) begin
				m_cyc_o <= 1'b1;
				m_we_o <= 1'b0;
				m_adr_o <= xyAddr;
				state <= LOADSTRIP;
			end
			else if (pcmd==2'b01)
				state <= LOADCOLOR;
`ifdef PIXEL_PUT
			else if (pcmd==2'b10)
				state <= STORESTRIP;
`endif
		end
`ifdef PIXEL_GET
	LOADCOLOR:
		begin
			color_o <= mem_color;
			rstcmd <= 1'b1;
			state <= WAITRST;
		end
`endif
	LOADSTRIP:
		if (m_ack_i) begin
			wb_nack();
			mem_strip <= m_dat_i;
			if (pcmd==2'b01)
				state <= LOADCOLOR;
`ifdef PIXEL_PUT
			else if (pcmd==2'b10)
				state <= STORESTRIP;
`endif
			else begin
				rstcmd <= 1'b1;
				state <= WAITRST;
			end
		end
`ifdef PIXEL_PUT
	STORESTRIP:
		begin
			rstcmd <= 1'b1;
			m_cyc_o <= 1'b1;
			m_we_o <= 1'b1;
			m_dat_o <= mem_strip_o;
			mem_strip <= mem_strip_o;
			state <= ACKSTRIP;
		end
	ACKSTRIP:
		if (m_ack_i) begin
			wb_nack();
			state <= WAITRST;
		end
`endif
`endif	// PIXEL_CMD
	WAITLOAD:
		if (m_ack_i) begin
			wb_nack();
			adr <= adr + 32'd16;
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

reg [23:0] rgbo4;
always @(posedge vclk)
	case(color_depth)
	BPP6:	rgbo4 <= greyscale ? {3{rgbo3[5:0],2'b00}} : {2'b00,rgbo3[5:0]};
	BPP8:	rgbo4 <= greyscale ? {3{rgbo3[7:0]}} : rgbo3[7:0];
	BPP9:	rgbo4 <= {rgbo3[8:6],5'b0,rgbo3[5:3],5'b0,rgbo3[2:0],5'b0};
	BPP12:	rgbo4 <= {rgbo3[11:8],4'h0,rgbo3[7:4],4'h0,rgbo3[3:0],4'h0};
	BPP15:	rgbo4 <= {rgbo3[14:10],3'b0,rgbo3[9:5],3'b0,rgbo3[4:0],3'b0};
	BPP16:	rgbo4 <= {rgbo3[15:11],3'b0,rgbo3[10:5],2'b0,rgbo3[4:0],3'b0};
	BPP24:	rgbo4 <= rgbo3[23:0];
	BPP32:	rgbo4 <= rgbo3[23:0];
	endcase

always @(posedge vclk)
	if (onoff && xonoff && !blank) begin
		if (color_depth[2:1]==2'b00 && !greyscale)
			rgbo <= pal_o;
		else
			rgbo <= rgbo4[23:0];
	end
	else
		rgbo <= 24'd0;

reg [13:0] vwa;
reg vwr;
reg [127:0] vdat;
always @(posedge m_clk_i)
	vwa <= m_adr_o[31:4] - baseAddr[31:4];
always @(posedge m_clk_i)
	vwr <= m_ack_i && state==WAITLOAD;
always @(posedge m_clk_i)
	vdat <= m_dat_i;

videobuf uvb1
(
	.wclk(m_clk_i),
	.wr(vwr),
	.wa(vwa),
	.i(vdat),
	.rclk(vclk),
	.ra(grAddr[17:4]),
	.o(rgbo1)
);

endmodule

// do a bitfield extract of color data
module mem2color(mem_i, mb_i, me_i, color_o);

input  [127:0] mem_i;
input [6:0] mb_i;
input [6:0] me_i;
output reg [31:0] color_o;

reg [127:0] mask;
reg [127:0] o1;
integer nn,n;
always @(mb_i or me_i or nn)
	for (nn = 0; nn < 128; nn = nn + 1)
		mask[nn] <= (nn >= mb_i) ^ (nn <= me_i) ^ (me_i >= mb_i);
always @*
begin
	for (n = 0; n < 128; n = n + 1)
		o1[n] = mask[n] ? mem_i[n] : 1'b0;
	color_o <= o1 >> mb_i;
end

endmodule

module color2mem(mem_i, mb_i, me_i, color_i, mem_o);
input [127:0] mem_i;
input [6:0] mb_i;
input [6:0] me_i;
input [31:0] color_i;
output reg [127:0] mem_o;

reg [127:0] o2;
reg [127:0] mask;
integer nn,n;
always @(mb_i or me_i or nn)
	for (nn = 0; nn < 128; nn = nn + 1)
		mask[nn] <= (nn >= mb_i) ^ (nn <= me_i) ^ (me_i >= mb_i);

always @*
begin
	o2 = color_i << mb_i;
	for (n = 0; n < 128; n = n + 1) mem_o[n] = (mask[n] ? o2[n] : mem_i[n]);
end

endmodule

module videobuf(wclk, wr, wa, i, rclk, ra, o);
input wclk;
input wr;
input [13:0] wa;
input [127:0] i;
input rclk;
input [13:0] ra;
output [127:0] o;

reg [127:0] vbuf [16383:0];

always @(posedge wclk)
	if (wr) vbuf[wa] <= i;
reg [13:0] rra;
always @(posedge rclk)
	rra <= ra;
assign o = vbuf[rra];

endmodule
