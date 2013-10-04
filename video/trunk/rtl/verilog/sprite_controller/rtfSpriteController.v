`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2005-2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//
//	rtfSpriteController.v
//		sprite / hardware cursor controller
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
//	Sprite Controller
//
//	FEATURES
//	- parameterized number of sprites 1,2,4,6,8 or 14
//	- sprite image cache buffers
//		- each image cache is capable of holding multiple
//		  sprite images
//		- cache may be accessed like a memory by the processor
//		- an embedded DMA controller may also be used for
//			sprite reload
//	- programmable image offset within cache
//	- programmable sprite width,height, and pixel size
//		- sprite width and height may vary from 1 to 64 as long
//		  as the product doesn't exceed 2048.
//	    - pixels may be programmed to be 1,2,3 or 4 video clocks
//	      both height and width are programmable
//	- programmable sprite position
//	- 8 or 16 bits for color
//		eg 32k color + 1 bit alpha blending indicator (1,5,5,5)
//	- fixed display and DMA priority
//	    sprite 0 highest, sprite 13 lowest
//
//		This core requires an external timing generator to
//	provide horizontal and vertical sync signals, but
//	otherwise can be used as a display controller on it's
//	own. However, normally this core would be embedded
//	within another core such as a VGA controller. Sprite
//	positions are referenced to the rising edge of the
//	vertical and horizontal sync pulses.
//		The core includes an embedded dual port RAM to hold the
//	sprite images. The image RAM is updated using a built in DMA
//	controller. The DMA controller uses 32 bit accesses to fill
//	the sprite buffers. The circuit features an automatic bus
//  transaction timeout; if the system bus hasn't responded
//  within 20 clock cycles, the DMA controller moves onto the
//  next address.
//		The controller uses a ram underlay to cache the values
//	of the registers. This is a lot cheaper resource wise than
//	using a 32 to 1 multiplexor (well at least for an FPGA).
//
//	All registers are 32 bits wide
//
//	These registers repeat in incrementing block of four registers
//	and pertain to each sprite
//	00:	- position register
//		HPOS    [11: 0]	horizontal position (hctr value)
//	    VPOS	[27:16]	vertical position (vctr value)
//
//	04:	SZ	- size and offset register
//			bits
//			[ 5: 0]	width of sprite in pixels - 1
//			[ 7: 6]	size of horizontal pixels - 1 in clock cycles
//			[13: 8]	height of sprite in pixels -1
//			[15:14]	size of vertical pixels in scan-lines - 1
//				* the product of width * height cannot exceed 2048 !
//				if it does, the display will begin repeating
//				
//		OFFS	[26:16] image offset bits [10:0]
//			offset of the sprite image within the sprite image cache
//			typically zero
//
//	08: ADR	21 bits sprite image address bits [31:11]
//			This registers contain the low order address bits of the
//          location of the sprite image in system memory.
//			The DMA controller will assign the low order 11 bits
//			during DMA.
//	
//	0C: TC	[7:0]	transparent color
//			This register identifies which color of the sprite
//			is transparent
//
//
//	0C-DC:	registers reserved for up to thirteen other sprites
//
//	Global status and control
//	E8: BTC	[23:0] background transparent color
//	EC: BC	[23:0] background color
//	F0: EN	[13:0] sprite enable register
//		IE	[29:16] sprite interrupt enable / status
//	F4: SCOL	[13:0] sprite-sprite collision register
//		BCOL	[29:16] sprite-background collision register
//	F8: DT		[13:0] sprite DMA trigger
//  FC: ADDR	[31:0] sprite DMA address bits [63:32]
//
//
//	1635 LUTs/ 1112 slices/ 82MHz - Spartan3e-4 (8 sprites)
//	3 8x8 multipliers (for alpha blending)
//	14 block rams
//=============================================================== */

`define VENDOR_XILINX	// block ram vendor (only one defined for now)

module rtfSpriteController(
// Bus Slave interface
//------------------------------
// Slave signals
input rst_i,			// reset
input clk_i,			// clock
input         s_cyc_i,	// cycle valid
input         s_stb_i,	// data transfer
output        s_ack_o,	// transfer acknowledge
input         s_we_i,	// write
input  [ 3:0] s_sel_i,	// byte select
input  [33:0] s_adr_i,	// address
input  [31:0] s_dat_i,	// data input
output reg [31:0] s_dat_o,	// data output
output vol_o,			// volatile register
//------------------------------
// Bus Master Signals
output reg [1:0] m_bte_o,	// burst type
output reg [2:0] m_cti_o,	// cycle type
output reg [5:0] m_bl_o,	// burst length
output reg    m_cyc_o,	// cycle is valid
output reg    m_stb_o,	// strobe output
input         m_ack_i,	// input data is ready
output reg    m_we_o,		// write (always inactive)
output reg [ 3:0] m_sel_o,	// byte select
output reg [33:0] m_adr_o,	// DMA address
input  [31:0] m_dat_i,	// data input
output reg [31:0] m_dat_o,	// data output (always zero)
//--------------------------
input vclk,					// video dot clock
input hSync,				// horizontal sync pulse
input vSync,				// vertical sync pulse
input blank,				// blanking signal
input [24:0] rgbIn,			// input pixel stream
output reg [23:0] rgbOut,	// output pixel stream
output irq					// interrupt request
);

reg m_soc_o;

//--------------------------------------------------------------------
// Core Parameters
//--------------------------------------------------------------------
parameter pnSpr = 14;		// number of sprites
parameter phBits = 11;		// number of bits in horizontal timing counter
parameter pvBits = 11;		// number of bits in vertical timing counter
parameter pColorBits = 8;	// number of bits used for color data
localparam pnSprm = pnSpr-1;


//--------------------------------------------------------------------
// Variable Declarations
//--------------------------------------------------------------------

wire [3:0] sprN = s_adr_i[6:3];

reg [phBits-1:0] hctr;		// horizontal reference counter (counts dots since hSync)
reg [pvBits-1:0] vctr;		// vertical reference counter (counts scanlines since vSync)
reg sprSprIRQ;
reg sprBkIRQ;

reg [15:0] out;			// sprite output
reg outact;				// sprite output is active
wire bkCollision;		// sprite-background collision
reg [23:0] bgTc;		// background transparent color
reg [23:0] bkColor;		// background color


reg [pnSprm:0] sprWe;	// block ram write enable for image cache update
reg [pnSprm:0] sprRe;	// block ram read enable for image cache update

// Global control registers
reg [15:0] sprEn;   	// enable sprite
reg [pnSprm:0] sprCollision;	    // sprite-sprite collision
reg sprSprIe;			// sprite-sprite interrupt enable
reg sprBkIe;            // sprite-background interrupt enable
reg sprSprIRQPending;   // sprite-sprite collision interrupt pending
reg sprBkIRQPending;    // sprite-background collision interrupt pending
reg sprSprIRQPending1;  // sprite-sprite collision interrupt pending
reg sprBkIRQPending1;   // sprite-background collision interrupt pending
reg sprSprIRQ1;			// vclk domain regs
reg sprBkIRQ1;

// Sprite control registers
reg [15:0] sprSprCollision;
reg [pnSprm:0] sprSprCollision1;
reg [15:0] sprBkCollision;
reg [pnSprm:0] sprBkCollision1;
reg [pColorBits-1:0] sprTc [pnSprm:0];		// sprite transparent color code
// How big the pixels are:
// 1,2,3,or 4 video clocks
reg [1:0] hSprRes [pnSprm:0];		// sprite horizontal resolution
reg [1:0] vSprRes [pnSprm:0];		// sprite vertical resolution
reg [5:0] sprWidth [pnSprm:0];		// number of pixels in X direction
reg [5:0] sprHeight [pnSprm:0];		// number of vertical pixels

// display and timing signals
reg [13:0] hSprReset;   // horizontal reset
reg [13:0] vSprReset;   // vertical reset
reg [13:0] hSprDe;		// sprite horizontal display enable
reg [13:0] vSprDe;		// sprite vertical display enable
reg [13:0] sprDe;			// display enable
reg [phBits-1:0] hSprPos [pnSprm:0];	// sprite horizontal position
reg [pvBits-1:0] vSprPos [pnSprm:0];	// sprite vertical position
reg [5:0] hSprCnt [pnSprm:0];	// sprite horizontal display counter
reg [5:0] vSprCnt [pnSprm:0];	// vertical display counter
reg [10:0] sprImageOffs [pnSprm:0];	// offset within sprite memory
reg [10:0] sprAddr [pnSprm:0];	// index into sprite memory
reg [10:0] sprAddrB [pnSprm:0];	// backup address cache for rescan
wire [pColorBits-1:0] sprOut [pnSprm:0];	// sprite image data output

// DMA access
reg [33:32] sprSysAddrHx;	// high order 32 bits of sprite memory address
reg [26:11] sprSysAddrL [pnSprm:0];	// system memory address of sprite image (low bits)
reg [31:27] sprSysAddrH [pnSprm:0];	// system memory address of sprite image (high bits)
reg [3:0] dmaOwner;			// which sprite has the DMA channel
reg [15:0] sprDt;		// DMA trigger register
reg dmaActive;				// this flag indicates that a block DMA transfer is active

integer n;

//--------------------------------------------------------------------
// DMA control / bus interfacing
//--------------------------------------------------------------------
wire cs_ram = s_cyc_i && s_stb_i && (s_adr_i[33:18]==16'hFFD8);
wire cs_regs = s_cyc_i && s_stb_i && (s_adr_i[33:10]==24'hFFDAD0);

reg sprRdy;
always @(posedge clk_i)
	sprRdy = (cs_ram|cs_regs);

//assign s_ack_o = cs_regs ? 1'b1 : cs_ram ? (s_we_i ? 1 : sprRamRdy) : 0;
assign s_ack_o = (cs_regs|cs_ram) ? (s_we_i ? 1'b1 : sprRdy) : 1'b0;
assign vol_o = cs_regs & s_adr_i[8:2]>7'd111;
assign irq = sprSprIRQ|sprBkIRQ;

//--------------------------------------------------------------------
// DMA control / bus interfacing
//--------------------------------------------------------------------
reg dmaStart;

wire btout;
wire sbi_rdy1 = m_ack_i|btout;
busTimeoutCtr #(20) br0(
	.rst(rst_i),
	.crst(1'b0),
	.clk(clk_i),
	.ce(1'b1),
	.req(m_soc_o),
	.rdy(m_ack_i),
	.timeout(btout)
);

reg [4:0] cob;	// count of burst cycles

always @(posedge clk_i)
if (rst_i) begin
	dmaStart <= 1'b0;
	dmaActive <= 1'b0;
	dmaOwner <= 4'd0;
	m_bte_o <= 2'b00;
	m_cti_o <= 3'b000;
	m_bl_o <= 6'd63;
	m_soc_o <= 1'b0;
	m_cyc_o <= 1'b0;
	m_stb_o <= 1'b0;
	m_we_o <= 1'b0;
	m_sel_o <= 4'h0;
	m_adr_o <= 34'd0;
	m_dat_o <= 32'd0;
	cob <= 5'd0;
end
else begin
	dmaStart <= 1'b0;
	m_soc_o <= 1'b0;
	if (!dmaActive) begin
		cob <= 5'd0;
		dmaStart <= |sprDt;
		dmaActive <= |sprDt;
		dmaOwner  <= 0;
		for (n = pnSprm; n >= 0; n = n - 1)
			if (sprDt[n]) dmaOwner <= n;
	end
	else begin
		if (!m_cyc_o) begin
			m_bte_o <= 2'b00;
			m_cti_o <= 3'b010;
			m_cyc_o <= 1'b1;
			m_stb_o <= 1'b1;
			m_sel_o <= 4'b1111;
			m_bl_o <= 6'd63;
			m_adr_o <= {sprSysAddrHx[33:32],sprSysAddrH[dmaOwner],sprSysAddrL[dmaOwner],cob[2:0],8'h00};
			m_soc_o <= 1'b1;
			cob <= cob + 5'd1;
		end
		else if (m_ack_i|btout) begin
			m_soc_o <= 1'b1;
			m_adr_o[7:0] <= m_adr_o[7:0] + 8'd4;
			// Flag last cycle of burst
			if (m_adr_o[7:0]==8'hF8)
				m_cti_o <= 3'b111;
			if (m_adr_o[7:0]==8'hFC) begin
				m_soc_o <= 1'b0;
				m_cyc_o <= 1'b0;
				m_stb_o <= 1'b0;
				m_sel_o <= 4'b0000;
				m_cti_o <= 3'b000;
				m_adr_o <= 44'd0;
				if (cob==5'd8)
					dmaActive <= 1'b0;
			end
		end
	end
end

// generate a write enable strobe for the sprite image memory
always @(dmaOwner, dmaActive, s_adr_i, cs_ram, s_we_i, m_ack_i)
for (n = 0; n < pnSpr; n = n + 1)
	sprWe[n] = (dmaOwner==n && dmaActive && m_ack_i)||(cs_ram && s_we_i && s_adr_i[14:11]==n);

always @(cs_ram, s_adr_i)
for (n = 0; n < pnSpr; n = n + 1)
	sprRe[n] = cs_ram && s_adr_i[14:11]==n;

wire [31:0] sr_dout [pnSprm:0];
reg [31:0] sr_dout_all;

generate
begin : gSrDout
always @(pnSpr)
if (pnSpr==1)
	sr_dout_all <= sr_dout[0];
else if (pnSpr==2)
	sr_dout_all <= sr_dout[0]|sr_dout[1];
else if (pnSpr==4)
	sr_dout_all <= sr_dout[0]|sr_dout[1]|sr_dout[2]|sr_dout[3];
else if (pnSpr==6)
	sr_dout_all <= sr_dout[0]|sr_dout[1]|sr_dout[2]|sr_dout[3]|sr_dout[4]|sr_dout[5];
else if (pnSpr==8)
	sr_dout_all <= sr_dout[0]|sr_dout[1]|sr_dout[2]|sr_dout[3]|sr_dout[4]|sr_dout[5]|sr_dout[6]|sr_dout[7];//|
else if (pnSpr==14)
	sr_dout_all <= sr_dout[0]|sr_dout[1]|sr_dout[2]|sr_dout[3]|sr_dout[4]|sr_dout[5]|sr_dout[6]|sr_dout[7]|
							sr_dout[8]|sr_dout[9]|sr_dout[10]|sr_dout[11]|sr_dout[12]|sr_dout[13];
end
endgenerate

// register/sprite memory output mux
always @(posedge clk_i)
	if (cs_ram)
		s_dat_o <= sr_dout_all;
	else if (cs_regs)
		case (s_adr_i[8:2])		// synopsys full_case parallel_case
		7'd120:	s_dat_o <= sprEn;
		7'd121:	s_dat_o <= {sprBkIRQPending|sprSprIRQPending,5'b0,sprBkIRQPending,sprSprIRQPending,6'b0,sprBkIe,sprSprIe};
		7'd122:	s_dat_o <= sprSprCollision;
		7'd123:	s_dat_o <= sprBkCollision;
		7'd124:	s_dat_o <= sprDt;
		default:	s_dat_o <= 32'd0;
		endcase
	else
		s_dat_o <= 32'd0;


// vclk -> clk_i
always @(posedge clk_i)
begin
	sprSprIRQ <= sprSprIRQ1;
	sprBkIRQ <= sprBkIRQ1;
	sprSprIRQPending <= sprSprIRQPending1;
	sprBkIRQPending <= sprBkIRQPending1;
	sprSprCollision <= sprSprCollision1;
	sprBkCollision <= sprBkCollision1;
end


// register updates
// on the clk_i domain
always @(posedge clk_i)
if (rst_i) begin
	sprEn <= {pnSpr{1'b0}};
	sprDt <= 0;
    for (n = 0; n < pnSpr; n = n + 1) begin
		sprSysAddrL[n] <= 5'b0100_0 + n;	//xxxx_4000
		sprSysAddrH[n] <= 16'h1000;			//1000_xxxx
	end
	sprSprIe <= 0;
	sprBkIe  <= 0;

    // Set reasonable starting positions on the screen
    // so that the sprites might be visible for testing
    for (n = 0; n < pnSpr; n = n + 1) begin
        hSprPos[n] <= 440 + n * 50;
        vSprPos[n] <= 200;
        sprTc[n] <= 16'h6739;
		sprWidth[n] <= 47;  // 48x42 sprites
		sprHeight[n] <= 41;
		hSprRes[n] <= 0;	// our standard display
		vSprRes[n] <= 0;
		sprImageOffs[n] <= 0;
	end
    hSprPos[0] <= 290;
    vSprPos[0] <= 72;

    bgTc <= 24'h00_00_00;
    bkColor <= 24'hFF_FF_60;
end
else begin
	// clear DMA trigger bit once DMA is recognized
	if (dmaStart)
		sprDt[dmaOwner] <= 1'b0;

	if (cs_regs & s_we_i) begin

		casex (s_adr_i[8:2])

		7'd116,7'd117:	bgTc <= s_dat_i[23:0];
		7'd118,7'd119:	bkColor <= s_dat_i[23:0];
		7'd120,7'd121:
			begin
				if (s_sel_i[0]) sprEn[7:0] <= s_dat_i[7:0];
				if (s_sel_i[1]) sprEn[13:8] <= s_dat_i[13:8];
				if (s_sel_i[2]) begin
					sprSprIe <= s_dat_i[16];
					sprBkIe <= s_dat_i[17];
				end
			end
		// update DMA trigger
		// s_dat_i[7:0] indicates which triggers to set  (1=set,0=ignore)
		// s_dat_i[7:0] indicates which triggers to clear (1=clear,0=ignore)
		7'd124,7'd125:	
			begin
				if (s_sel_i[0])	sprDt[7:0] <= sprDt[7:0] | s_dat_i[7:0];
				if (s_sel_i[1]) sprDt[13:8] <= sprDt[13:8] | s_dat_i[13:8];
				if (s_sel_i[2]) sprDt[7:0] <= sprDt[7:0] & ~s_dat_i[23:16];
				if (s_sel_i[3])	sprDt[13:8] <= sprDt[13:8] & ~s_dat_i[29:24];
			end
		7'd126,7'd127:	sprSysAddrHx[33:32] <= s_dat_i[ 1: 0];
		7'bxxxx00x:
			 begin
	    		if (s_sel_i[0]) hSprPos[sprN][ 7:0] <= s_dat_i[ 7: 0];
	    		if (s_sel_i[1]) hSprPos[sprN][10:8] <= s_dat_i[10: 8];
	    		if (s_sel_i[2]) vSprPos[sprN][ 7:0] <= s_dat_i[23:16];
	    		if (s_sel_i[3]) vSprPos[sprN][10:8] <= s_dat_i[26:24];
    		end
    	7'bxxxx01x:
			begin
	    		if (s_sel_i[0]) begin
					sprWidth[sprN] <= s_dat_i[5:0];
	            	hSprRes[sprN] <= s_dat_i[7:6];
	            end
	    		if (s_sel_i[1]) begin
					sprHeight[sprN] <= s_dat_i[13:8];
	            	vSprRes[sprN] <= s_dat_i[15:14];
	            end
	            if (s_sel_i[2]) sprImageOffs[sprN][ 7:0] <= s_dat_i[23:16];
	            if (s_sel_i[3]) sprImageOffs[sprN][10:8] <= s_dat_i[26:24];
			end
		7'bxxxx10x:
			begin	// DMA address set on clk_i domain
				if (s_sel_i[0]) sprSysAddrL[sprN][18:11] <= s_dat_i[ 7: 0];
				if (s_sel_i[1]) sprSysAddrL[sprN][26:19] <= s_dat_i[15: 8];
				if (s_sel_i[2]) sprSysAddrH[sprN][31:27] <= s_dat_i[23:16];
			end
		7'bxxxx11x:
			begin
				if (s_sel_i[0]) sprTc[sprN][ 7:0] <= s_dat_i[ 7:0];
				if (pColorBits>8)
					if (s_sel_i[1]) sprTc[sprN][15:8] <= s_dat_i[15:8];
			end

		default:	;
		endcase
	
	end
end

//-------------------------------------------------------------
// Sprite Image Cache RAM
// This RAM is dual ported with an SoC side and a display
// controller side.
//-------------------------------------------------------------
wire [10:2] sr_adr = m_cyc_o ? m_adr_o[10:2] : s_adr_i[10:2];
wire [31:0] sr_din = m_cyc_o ? m_dat_i[31:0] : s_dat_i[31:0];
wire sr_ce = m_cyc_o ? sbi_rdy1 : cs_ram;

// Note: the sprite output can't be zeroed out using the rst input!!!
// We need to know what the output is to determine if it's the 
// transparent color.
genvar g;
generate
	for (g = 0; g < pnSpr; g = g + 1)
	begin : genSpriteRam
		if (pColorBits==8)
			rtfSpriteRam8 sprRam0
			(
				.clka(vclk),
				.adra(sprAddr[g]),
				.doa(sprOut[g]),
				.cea(1'b1),

				.clkb(~clk_i),
				.adrb(sr_adr),
				.dib(sr_din),
				.dob(sr_dout[g]),
				.ceb(sr_ce),
				.web(sprWe[g]),
				.rstb(!sprRe[g])
			);
		else if (pColorBits==16)
			rtfSpriteRam16 sprRam0
			(
				.clka(vclk),
				.adra(sprAddr[g]),
				.doa(sprOut[g]),
				.cea(1'b1),
				
				.clkb(~clk_i),
				.adrb(sr_adr),
				.dib(sr_din),
				.dob(sr_dout[g]),
				.ceb(sr_ce),
				.web(sprWe[g]),
				.rstb(!sprRe[g])
			);
	end
endgenerate



//-------------------------------------------------------------
// Timing counters and addressing
// Sprites are like miniature bitmapped displays, they need
// all the same timing controls.
//-------------------------------------------------------------

// Create a timing reference using horizontal and vertical
// sync
wire hSyncEdge, vSyncEdge;
edge_det ed0(.rst(rst_i), .clk(vclk), .ce(1'b1), .i(hSync), .pe(hSyncEdge), .ne(), .ee() );
edge_det ed1(.rst(rst_i), .clk(vclk), .ce(1'b1), .i(vSync), .pe(vSyncEdge), .ne(), .ee() );

always @(posedge vclk)
if (rst_i)        	hctr <= 0;
else if (hSyncEdge) hctr <= 0;
else            	hctr <= hctr + 1;

always @(posedge vclk)
if (rst_i)        	vctr <= 0;
else if (vSyncEdge) vctr <= 0;
else if (hSyncEdge) vctr <= vctr + 1;

// track sprite horizontal reset
always @(posedge vclk)
for (n = 0; n < pnSpr; n = n + 1)
	hSprReset[n] <= hctr==hSprPos[n];

// track sprite vertical reset
always @(posedge vclk)
for (n = 0; n < pnSpr; n = n + 1)
	vSprReset[n] <= vctr==vSprPos[n];

always @(hSprDe, vSprDe)
for (n = 0; n < 14; n = n + 1)
	sprDe[n] <= hSprDe[n] & vSprDe[n];


// take care of sprite size scaling
// video clock division
reg [13:0] hSprNextPixel;
reg [13:0] vSprNextPixel;
reg [1:0] hSprPt [13:0];   // horizontal pixel toggle
reg [1:0] vSprPt [13:0];   // vertical pixel toggle
always @(n)
for (n = 0; n < pnSpr; n = n + 1)
    hSprNextPixel[n] = hSprPt[n]==hSprRes[n];
always @(n)
for (n = 0; n < pnSpr; n = n + 1)
    vSprNextPixel[n] = vSprPt[n]==vSprRes[n];

// horizontal pixel toggle counter
always @(posedge vclk)
for (n = 0; n < pnSpr; n = n + 1)
	if (hSprReset[n])
		hSprPt[n] <= 0;
    else if (hSprNextPixel[n])
        hSprPt[n] <= 0;
    else
        hSprPt[n] <= hSprPt[n] + 1;

// vertical pixel toggle counter
always @(posedge vclk)
for (n = 0; n < pnSpr; n = n + 1)
    if (hSprReset[n]) begin
    	if (vSprReset[n])
    		vSprPt[n] <= 0;
        else if (vSprNextPixel[n])
            vSprPt[n] <= 0;
        else
            vSprPt[n] <= vSprPt[n] + 1;
    end


// clock sprite image address counters
always @(posedge vclk)
for (n = 0; n < pnSpr; n = n + 1) begin
    // hReset and vReset - top left of sprite,
    // reset address to image offset
	if (hSprReset[n] & vSprReset[n]) begin
		sprAddr[n]  <= sprImageOffs[n];
		sprAddrB[n] <= sprImageOffs[n];
	end
	// hReset:
	//  If the next vertical pixel
	//      set backup address to current address
	//  else
	//      set current address to backup address
	//      in order to rescan the line
	else if (hSprReset[n]) begin
		if (vSprNextPixel[n])
			sprAddrB[n] <= sprAddr[n];
		else
			sprAddr[n]  <= sprAddrB[n];
	end
	// Not hReset or vReset - somewhere on the sprite scan line
	// just advance the address when the next pixel should be
	// fetched
	else if (sprDe[n] & hSprNextPixel[n])
		sprAddr[n] <= sprAddr[n] + 1;
end


// clock sprite column (X) counter
always @(posedge vclk)
for (n = 0; n < pnSpr; n = n + 1)
	if (hSprReset[n])
		hSprCnt[n] <= 0;
	else if (hSprNextPixel[n])
		hSprCnt[n] <= hSprCnt[n] + 1;


// clock sprite horizontal display enable
always @(posedge vclk)
for (n = 0; n < pnSpr; n = n + 1) begin
	if (hSprReset[n])
		hSprDe[n] <= 1;
	else if (hSprNextPixel[n]) begin
		if (hSprCnt[n] == sprWidth[n])
			hSprDe[n] <= 0;
	end
end


// clock the sprite row (Y) counter
always @(posedge vclk)
for (n = 0; n < pnSpr; n = n + 1)
	if (hSprReset[n]) begin
		if (vSprReset[n])
			vSprCnt[n] <= 0;
		else if (vSprNextPixel[n])
			vSprCnt[n] <= vSprCnt[n] + 1;
	end


// clock sprite vertical display enable
always @(posedge vclk)
for (n = 0; n < pnSpr; n = n + 1) begin
	if (hSprReset[n]) begin
		if (vSprReset[n])
			vSprDe[n] <= 1;
		else if (vSprNextPixel[n]) begin
			if (vSprCnt[n] == sprHeight[n])
				vSprDe[n] <= 0;
		end
	end
end


//-------------------------------------------------------------
// Output stage
//-------------------------------------------------------------

// function used for color blending
// given an alpha and a color component, determine the resulting color
// this blends towards black or white
// alpha is eight bits ranging between 0 and 1.999...
// 1 bit whole, 7 bits fraction
function [7:0] fnBlend;
input [7:0] alpha;
input [7:0] colorbits;

begin
	fnBlend = (({8'b0,colorbits} * alpha) >> 7);
end
endfunction


// pipeline delays for display enable
reg [14:0] sprDe1;
reg [14:0] sproact;
always @(posedge vclk)
for (n = 0; n < pnSpr; n = n + 1) begin
	sprDe1[n] <= sprDe[n];
end


// Detect which sprite outputs are active
// The sprite output is active if the current display pixel
// address is within the sprite's area, the sprite is enabled,
// and it's not a transparent pixel that's being displayed.
always @(n, sprEn, sprDe1)
for (n = 0; n < pnSpr; n = n + 1)
	sproact[n] <= sprEn[n] && sprDe1[n] && sprTc[n]!=sprOut[n];

// register sprite activity flag
// The image combiner uses this flag to know what to do with
// the sprite output.
always @(posedge vclk)
outact = |sproact;

// Display data comes from the active sprite with the
// highest display priority.
// Make sure that alpha blending is turned off when
// no sprite is active.
always @(posedge vclk)
begin
	out = 16'h0080;	// alpha blend max (and off)
	for (n = pnSprm; n >= 0; n = n - 1)
		if (sproact[n]) out = sprOut[n];
end


// combine the text / graphics color output with sprite color output
// blend color output
wire [23:0] blendedColor = {
 	fnBlend(out[7:0],rgbIn[23:16]),		// R
 	fnBlend(out[7:0],rgbIn[15: 8]),		// G
 	fnBlend(out[7:0],rgbIn[ 7: 0])};	// B


// display color priority bit [24] 1=display is over sprite
always @(posedge vclk)
if (blank)
	rgbOut <= 0;
else begin
	if (rgbIn[24] && rgbIn[23:0] != bgTc)	// color is in front of sprite
		rgbOut <= rgbIn[23:0];
	else if (outact) begin
		if (!out[15]) begin			// a sprite is displayed without alpha blending
			if (pColorBits==8)
				rgbOut <= {out[7:5],5'b0,out[4:2],5'b0,out[1:0],6'b0};
			else
				rgbOut <= {out[14:10],3'b0,out[9:5],3'b0,out[4:0],3'b0};
		end
		else
			rgbOut <= blendedColor;
	end else
		rgbOut <= rgbIn[23:0];
end


//--------------------------------------------------------------------
// Collision logic
//--------------------------------------------------------------------

// Detect when a sprite-sprite collision has occurred. The criteria
// for this is that a pixel from the sprite is being displayed, while
// there is a pixel from another sprite that could be displayed at the
// same time.

//--------------------------------------------------------------------
// Note this case has to be modified for the number of sprites
//--------------------------------------------------------------------
generate
begin : gSprsColliding
always @(pnSpr or sproact)
if (pnSpr==1)
	sprCollision = 0;
else if (pnSpr==2)
	case (sproact)
	2'b00,
	2'b01,
	2'b10:	sprCollision = 0;
	2'b11:	sprCollision = 1;
	endcase
else if (pnSpr==4)
	case (sproact)
	4'b0000,
	4'b0001,
	4'b0010,
	4'b0100,
	4'b1000:	sprCollision = 0;
	default:	sprCollision = 1;
	endcase
else if (pnSpr==6)
	case (sproact)
	6'b000000,
	6'b000001,
	6'b000010,
	6'b000100,
	6'b001000,
	6'b010000,
	8'b100000:	sprCollision = 0;
	default:	sprCollision = 1;
	endcase
else if (pnSpr==8)
	case (sproact)
	8'b00000000,
	8'b00000001,
	8'b00000010,
	8'b00000100,
	8'b00001000,
	8'b00010000,
	8'b00100000,
	8'b01000000,
	8'b10000000:	sprCollision = 0;
	default:		sprCollision = 1;
	endcase
else if (pnSpr==14)
	case (sproact)
	14'b00000000000000,
	14'b00000000000001,
	14'b00000000000010,
	14'b00000000000100,
	14'b00000000001000,
	14'b00000000010000,
	14'b00000000100000,
	14'b00000001000000,
	14'b00000010000000,
	14'b00000100000000,
	14'b00001000000000,
	14'b00010000000000,
	14'b00100000000000,
	14'b01000000000000,
	14'b10000000000000:	sprCollision = 0;
	default:			sprCollision = 1;
	endcase
end
endgenerate

// Detect when a sprite-background collision has occurred
assign bkCollision = (rgbIn[24] && rgbIn[23:0] != bgTc) ? 0 :
		outact && rgbIn[23:0] != bkColor;

// Load the sprite collision register. This register continually
// accumulates collision bits until reset by reading the register.
// Set the collision IRQ on the first collision and don't set it
// again until after the collision register has been read.
always @(posedge vclk)
if (rst_i) begin
	sprSprIRQPending1 <= 0;
	sprSprCollision1 <= 0;
	sprSprIRQ1 <= 0;
end
else if (sprCollision) begin
	// isFirstCollision
	if ((sprSprCollision1==0)||(cs_regs && s_sel_i[0] && s_adr_i[8:2]==7'd122)) begin
		sprSprIRQPending1 <= 1;
		sprSprIRQ1 <= sprSprIe;
		sprSprCollision1 <= sproact;
	end
	else
		sprSprCollision1 <= sprSprCollision1|sproact;
end
else if (cs_regs && s_sel_i[0] && s_adr_i[8:2]==7'd122) begin
	sprSprCollision1 <= 0;
	sprSprIRQPending1 <= 0;
	sprSprIRQ1 <= 0;
end


// Load the sprite background collision register. This register
// continually accumulates collision bits until reset by reading
// the register.
// Set the collision IRQ on the first collision and don't set it
// again until after the collision register has been read.
// Note the background collision indicator is externally supplied,
// it will come from the color processing logic.
always @(posedge vclk)
if (rst_i) begin
	sprBkIRQPending1 <= 0;
	sprBkCollision1 <= 0;
	sprBkIRQ1 <= 0;
end
else if (bkCollision) begin
	// Is the register being cleared at the same time
	// a collision occurss ?
	// isFirstCollision
	if ((sprBkCollision1==0) || (cs_regs && s_sel_i[0] && s_adr_i[8:2]==7'd123)) begin	
		sprBkIRQ1 <= sprBkIe;
		sprBkCollision1 <= sproact;
		sprBkIRQPending1 <= 1;
	end
	else
		sprBkCollision1 <= sprBkCollision1|sproact;
end
else if (cs_regs && s_sel_i[0] && s_adr_i[8:2]==7'd123) begin
	sprBkCollision1 <= 0;
	sprBkIRQPending1 <= 0;
	sprBkIRQ1 <= 0;
end

endmodule

// Sprite RAM for eight bit color depth
module rtfSpriteRam8 (
	clka, adra, doa, cea,
	clkb, adrb, dib, dob, ceb, web, rstb
);
input clka;
input [10:0] adra;
output [7:0] doa;
reg [7:0] doa;
input cea;
input clkb;
input [8:0] adrb;
input [31:0] dib;
output [31:0] dob;
input ceb;
input web;
input rstb;

reg [31:0] mem [0:511];
reg [10:0] radra;
reg [8:0] radrb;

always @(posedge clka)	if (cea) radra <= adra;
always @(posedge clkb) 	if (ceb) radrb <= adrb;
always @(radra)
	case(radra[1:0])
	2'b00:	doa <= mem[radra[10:2]][ 7: 0];
	2'b01:	doa <= mem[radra[10:2]][15: 8];
	2'b10:	doa <= mem[radra[10:2]][23:16];
	2'b11:	doa <= mem[radra[10:2]][31:24];
	endcase
assign dob = rstb ? 32'd0 : mem [radrb];
always @(posedge clkb)
	if (ceb & web) mem[adrb] <= dib;

endmodule

// Sprite RAM for sixteen bit color depth
module rtfSpriteRam16 (
	clka, adra, doa, cea,
	clkb, adrb, dib, dob, ceb, web, rstb
);
input clka;
input [9:0] adra;
output [15:0] doa;
reg [15:0] doa;
input cea;
input clkb;
input [8:0] adrb;
input [31:0] dib;
output [31:0] dob;
input ceb;
input web;
input rstb;

reg [31:0] mem [0:511];
reg [9:0] radra;
reg [8:0] radrb;

always @(posedge clka)	if (cea) radra <= adra;
always @(posedge clkb) 	if (ceb) radrb <= adrb;
always @(radra)
	case(radra[1])
	1'b0:	doa <= mem[radra[9:1]][15: 0];
	1'b1:	doa <= mem[radra[9:1]][31:16];
	endcase
assign dob = rstb ? 32'd0 : mem [radrb];
always @(posedge clkb)
	if (ceb & web) mem[adrb] <= dib;

endmodule

