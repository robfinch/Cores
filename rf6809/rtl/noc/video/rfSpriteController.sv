`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2005-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfSpriteController.v
//		sprite / hardware cursor controller
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
//
//	Sprite Controller
//
//	FEATURES
//	- parameterized number of sprites 1,2,4,6,8,14 or 32
//	- sprite image cache buffers
//		- each image cache is capable of holding multiple
//		  sprite images
//		- an embedded DMA controller is used for sprite reload
//	- programmable image offset within cache
//	- programmable sprite width,height, and pixel size
//		- sprite width and height may vary from 1 to 64 as long
//		  as the product doesn't exceed 4096.
//	    - pixels may be programmed to be 1,2,3 or 4 video clocks
//	      both height and width are programmable
//	- programmable sprite position
//	- programmable 8, 16 or 32 bits for color
//		eg 32k color + 1 bit alpha blending indicator (1,5,5,5)
//	- fixed display and DMA priority
//	    sprite 0 highest, sprite 31 lowest
//	- graphics plane control
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
//	04:	SZ	- size register
//			bits
//			[ 7: 0]	width of sprite in pixels - 1
//			[15: 8]	height of sprite in pixels -1
//			[19:16]	size of horizontal pixels - 1 in clock cycles
//			[23:20]	size of vertical pixels in scan-lines - 1
//				* the product of width * height cannot exceed 2048 !
//				if it does, the display will begin repeating
//			[27:24] output plane
//			[31:30] color depth 01=RGB332,10=RGB555+A,11=RGB888+A
//				
//	08: ADR	[31:12] 20 bits sprite image address bits
//			This registers contain the high order address bits of the
//          location of the sprite image in system memory.
//			The DMA controller will assign the low order 12 bits
//			during DMA.
//		    [11:0] image offset bits [11:0]
//			offset of the sprite image within the sprite image cache
//			typically zero
//	
//	0C: TC	[23:0]	transparent color
//			This register identifies which color of the sprite
//			is transparent
//
//
//
//	0C-1FC:	registers reserved for up to thirty-one other sprites
//
//	200:		DMA burst reg sprite 0
//				[8:0]  burst start
//				[24:16] burst end
//	...
//	27C:		DMA burst reg sprite 31
//
//	Global status and control
//	3C0: EN [31:0] sprite enable register
//  3C4: IE	[31:0] sprite interrupt enable / status
//	3C8: SCOL	[31:0] sprite-sprite collision register
//	3CC: BCOL	[31:0] sprite-background collision register
//	3D0: DT		[31:0] sprite DMA trigger on
//	3D4: DT		[31:0] sprite DMA trigger off
//	3D8: VDT	[31:0] sprite vertical sync DMA trigger
//	3EC: BC	    [23:0] background color
//  3FC: ADDR	[31:0] sprite DMA address bits [63:32]
//
//=============================================================================

module rfSpriteController(
// Bus Slave interface
//------------------------------
// Slave signals
input rst_i,			// reset
input s_clk_i,			// clock
input         s_cs_i,
input         s_cyc_i,	// cycle valid
input         s_stb_i,	// data transfer
output        s_ack_o,	// transfer acknowledge
input         s_we_i,	// write
input  [ 3:0] s_sel_i,	// byte select
input  [ 9:0] s_adr_i,	// address
input  [31:0] s_dat_i,	// data input
output reg [7:0] s_dat_o,	// data output
//------------------------------
// Bus Master Signals
input m_clk_i,				// clock
output [1:0]  m_bte_o,
output [2:0]  m_cti_o,
output reg    m_cyc_o,	// cycle is valid
output        m_stb_o,	// strobe output
input         m_ack_i,	// input data is ready
input         m_err_i,	
output        m_we_o,
output [7:0] m_sel_o,
output reg [31:0] m_adr_o,	// DMA address
input  [63:0] m_dat_i,	// data input
output [63:0] m_dat_o,
output [4:0] m_spriteno_o,
//--------------------------
input dot_clk_i,		// video dot clock
input hsync_i,			// horizontal sync pulse
input vsync_i,			// vertical sync pulse
input blank_i,			// blanking signal
//input [3:0] rgbPlane_i,		// 0 = background, higher numbers closer to front
input [31:0] zrgb_i,			// input pixel stream
//output reg [3:0] rgbPlane_o,
output [31:0] zrgb_o,	// output pixel stream
output irq,					// interrupt request
input test
);

reg m_soc_o;
wire vclk = dot_clk_i;
wire hSync = hsync_i;
wire vSync = vsync_i;
wire [31:0] zrgbIn = zrgb_i;
reg [31:0] zrgbOut;
assign zrgb_o = zrgbOut;

//--------------------------------------------------------------------
// Core Parameters
//--------------------------------------------------------------------
parameter pnSpr = 32;		// number of sprites
parameter phBits = 12;		// number of bits in horizontal timing counter
parameter pvBits = 12;		// number of bits in vertical timing counter
localparam pnSprm = pnSpr-1;


//--------------------------------------------------------------------
// Variable Declarations
//--------------------------------------------------------------------

reg [9:0] adr_i;
reg [31:0] dat_i;
reg we_i;
reg [3:0] sel_i;

wire [4:0] sprN = adr_i[8:4];

reg [phBits-1:0] hctr;		// horizontal reference counter (counts dots since hSync)
reg [pvBits-1:0] vctr;		// vertical reference counter (counts scanlines since vSync)
reg sprSprIRQ;
reg sprBkIRQ;

reg [31:0] out;			// sprite output
reg outact;				// sprite output is active
reg [3:0] outplane;
reg [pnSprm:0] bkCollision;		// sprite-background collision
reg [23:0] bgTc;		// background transparent color
reg [23:0] bkColor;		// background color


reg [pnSprm:0] sprWe;	// block ram write enable for image cache update
reg [pnSprm:0] sprRe;	// block ram read enable for image cache update

// Global control registers
reg [31:0] sprEn;   	// enable sprite
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
reg [31:0] sprSprCollision;
reg [pnSprm:0] sprSprCollision1;
reg [31:0] sprBkCollision;
reg [pnSprm:0] sprBkCollision1;
reg [23:0] sprTc [pnSprm:0];		// sprite transparent color code
// How big the pixels are:
// 1 to 16 video clocks
reg [3:0] hSprRes [pnSprm:0];		// sprite horizontal resolution
reg [3:0] vSprRes [pnSprm:0];		// sprite vertical resolution
reg [7:0] sprWidth [pnSprm:0];		// number of pixels in X direction
reg [7:0] sprHeight [pnSprm:0];		// number of vertical pixels
reg [3:0] sprPlane [pnSprm:0];		// output plane sprite is in
reg [1:0] sprColorDepth [pnSprm:0];
reg [1:0] colorBits;
// Sprite DMA control
reg [8:0] sprBurstStart [pnSprm:0];
reg [8:0] sprBurstEnd	[pnSprm:0];
reg [31:0] vSyncT;								// DMA on vSync

// display and timing signals
reg [31:0] hSprReset;   // horizontal reset
reg [31:0] vSprReset;   // vertical reset
reg [31:0] hSprDe;		// sprite horizontal display enable
reg [31:0] vSprDe;		// sprite vertical display enable
reg [31:0] sprDe;			// display enable
reg [phBits-1:0] hSprPos [pnSprm:0];	// sprite horizontal position
reg [pvBits-1:0] vSprPos [pnSprm:0];	// sprite vertical position
reg [7:0] hSprCnt [pnSprm:0];	// sprite horizontal display counter
reg [7:0] vSprCnt [pnSprm:0];	// vertical display counter
reg [11:0] sprImageOffs [pnSprm:0];	// offset within sprite memory
reg [12:0] sprAddr [pnSprm:0];	// index into sprite memory (pixel number)
reg [9:0] sprAddr1 [pnSprm:0];	// index into sprite memory
reg [9:0] sprAddr2 [pnSprm:0];	// index into sprite memory
reg [9:0] sprAddr3 [pnSprm:0];	// index into sprite memory
reg [9:0] sprAddr4 [pnSprm:0];	// index into sprite memory
reg [11:0] sprAddrB [pnSprm:0];	// backup address cache for rescan
wire [31:0] sprOut4 [pnSprm:0];	// sprite image data output
reg [31:0] sprOut [pnSprm:0];	// sprite image data output
reg [31:0] sprOut5 [pnSprm:0];	// sprite image data output

// DMA access
reg [31:12] sprSysAddr [pnSprm:0];	// system memory address of sprite image (low bits)
reg [4:0] dmaOwner;			// which sprite has the DMA channel
reg [31:0] sprDt;		// DMA trigger register
reg dmaActive;				// this flag indicates that a block DMA transfer is active

genvar g;

//--------------------------------------------------------------------
// DMA control / bus interfacing
//--------------------------------------------------------------------
reg cs_regs;
always_ff @(posedge s_clk_i)
	cs_regs <= s_cyc_i & s_stb_i & s_cs_i;
always_ff @(posedge s_clk_i)
	adr_i <= s_adr_i;
always_ff @(posedge s_clk_i)
	dat_i <= s_dat_i;
always_ff @(posedge s_clk_i)
	we_i <= s_we_i;
always_ff @(posedge s_clk_i)
	sel_i <= s_sel_i;

ack_gen #(
	.READ_STAGES(3),
	.WRITE_STAGES(1),
	.REGISTER_OUTPUT(1)
)
uag1 (
	.clk_i(s_clk_i),
	.ce_i(1'b1),
	.i(cs_regs),
	.we_i(cs_regs & we_i),
	.o(s_ack_o)
);

assign irq = sprSprIRQ|sprBkIRQ;

//--------------------------------------------------------------------
// DMA control / bus interfacing
//--------------------------------------------------------------------

reg [5:0] dmaStart;
reg [8:0] cob;	// count of burst cycles

assign m_bte_o = 2'b00;
assign m_cti_o = 3'b000;
assign m_stb_o = m_cyc_o;
assign m_we_o = 1'b0;
assign m_sel_o = {8{m_cyc_o}};
assign m_dat_o = 64'h0;
assign m_spriteno_o = dmaOwner;

reg [2:0] mstate;
parameter IDLE = 3'd0;
parameter ACTIVE = 3'd1;
parameter ACK = 3'd2;
parameter NACK = 3'd3;

wire pe_m_ack_i;
edge_det ued2 (.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(m_ack_i), .pe(pe_m_ack_i), .ne(), .ee());

always_ff @(posedge m_clk_i)
if (rst_i)
	mstate <= IDLE;
else begin
	case(mstate)
	IDLE:
		if (|sprDt)
			mstate <= ACTIVE;
	ACTIVE:
		mstate <= ACK;
	ACK:
		if (m_ack_i | m_err_i)
			mstate <= NACK;
	NACK:
		if (~(m_ack_i|m_err_i))
			mstate <= cob==sprBurstEnd[dmaOwner] ? IDLE : ACTIVE;
	default:
		mstate <= IDLE;
	endcase
end

integer n30;
always_ff @(posedge m_clk_i)
begin
	case(mstate)
	IDLE:
		begin
			dmaOwner <= 5'd0;
			for (n30 = pnSprm; n30 >= 0; n30 = n30 - 1)
				if (sprDt[n30])
					dmaOwner <= n30;
		end
	default:	;
	endcase
end

always_ff @(posedge m_clk_i)
if (rst_i)
	dmaStart <= 6'b0;
else begin
	dmaStart <= {dmaStart[4:0],1'b0};
	case(mstate)
	IDLE:
		if (|sprDt)
			dmaStart <= 6'h3F;
	default:	;
	endcase
end

integer n32;
always_ff @(posedge m_clk_i)
begin
	case(mstate)
	IDLE:
		for (n32 = pnSprm; n32 >= 0; n32 = n32 - 1)
			if (sprDt[n32])
				cob <= sprBurstStart[n32];
	ACTIVE:
		cob <= cob + 2'd1;
	default:	;
	endcase
end

always_ff @(posedge m_clk_i)
if (rst_i)
	wb_m_nack();
else begin
	case(mstate)
	IDLE:
		wb_m_nack();
	ACTIVE:
		begin
			m_cyc_o <= 1'b1;
			m_adr_o <= {sprSysAddr[dmaOwner],cob[8:0],3'h0};
		end
	ACK:
		if (m_ack_i|m_err_i)
			wb_m_nack();
	endcase
end

task wb_m_nack;
begin
	m_cyc_o <= 1'b0;
	m_adr_o <= 32'h0;
end
endtask


// generate a write enable strobe for the sprite image memory
integer n1;
always_ff @(posedge m_clk_i)
for (n1 = 0; n1 < pnSpr; n1 = n1 + 1)
	sprWe[n1] <= (dmaOwner==n1 && m_ack_i);

reg [8:0] m_adr_or;
reg [63:0] m_dat_ir;
always_ff @(posedge m_clk_i)
if (m_ack_i)
	m_adr_or <= m_adr_o[11:3];
always_ff @(posedge m_clk_i)
if (m_ack_i) begin
	if (test)
		m_dat_ir <= {4{1'b0,dmaOwner,10'b0}};
	else
		m_dat_ir <= m_dat_i;
end

//--------------------------------------------------------------------
//--------------------------------------------------------------------

reg [7:0] reg_shadow [0:1023];
reg [9:0] radr;
always_ff @(posedge s_clk_i)
begin
    if (cs_regs & we_i)  reg_shadow[adr_i[9:0]] <= dat_i;
end
always @(posedge s_clk_i)
    radr <= adr_i[9:0];
wire [7:0] reg_shadow_o = reg_shadow[radr];

// register/sprite memory output mux
always_ff @(posedge s_clk_i)
	if (cs_regs)
		case (adr_i[9:0])		// synopsys full_case parallel_case
		10'b1111000000:	s_dat_o <= sprEn[31:24];
		10'b1111000001:	s_dat_o <= sprEn[23:16];
		10'b1111000010:	s_dat_o <= sprEn[15: 8];
		10'b1111000011:	s_dat_o <= sprEn[ 7: 0];
		10'b1111000100:	s_dat_o <= {6'b0,sprBkIe,sprSprIe};
		10'b1111000101:	s_dat_o <= {sprBkIRQPending|sprSprIRQPending,5'b0,sprBkIRQPending,sprSprIRQPending};
		10'b1111001000:	s_dat_o <= sprSprCollision[31:24];
		10'b1111001001:	s_dat_o <= sprSprCollision[23:16];
		10'b1111001010:	s_dat_o <= sprSprCollision[15: 8];
		10'b1111001011:	s_dat_o <= sprSprCollision[ 7: 0];
		10'b1111001100:	s_dat_o <= sprBkCollision[31:24];
		10'b1111001101:	s_dat_o <= sprBkCollision[23:16];
		10'b1111001110:	s_dat_o <= sprBkCollision[15: 8];
		10'b1111001111:	s_dat_o <= sprBkCollision[ 7: 0];
		10'b1111010000:	s_dat_o <= sprDt[31:24];
		10'b1111010001:	s_dat_o <= sprDt[23:16];
		10'b1111010010:	s_dat_o <= sprDt[15: 8];
		10'b1111010011:	s_dat_o <= sprDt[ 7: 0];
		default:	s_dat_o <= reg_shadow_o;
		endcase
	else
		s_dat_o <= 8'h0;


// vclk -> clk_i
always @(posedge s_clk_i)
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
reg vSync1;
integer n33;
always_ff @(posedge s_clk_i)
if (rst_i) begin
	vSyncT <= 32'hFFFFFFFF;
	sprEn <= 32'hFFFFFFFF;
	sprDt <= 0;
  for (n33 = 0; n33 < pnSpr; n33 = n33 + 1) begin
		sprSysAddr[n33] <= 20'b0000_0000_0011_0000_0000 + n33;	//0030_0000
	end
	sprSprIe <= 0;
	sprBkIe  <= 0;

  // Set reasonable starting positions on the screen
  // so that the sprites might be visible for testing
  for (n33 = 0; n33 < pnSpr; n33 = n33 + 1) begin
    hSprPos[n33] <= 200 + (n33 & 7) * 70;
    vSprPos[n33] <= 100 + (n33 >> 3) * 100;
    sprTc[n33] <= 24'h396739;
		sprWidth[n33] <= 8'd56;  // 56x36 sprites
		sprHeight[n33] <= 8'd36;
		hSprRes[n33] <= 0;	// our standard display
		vSprRes[n33] <= 0;
		sprImageOffs[n33] <= 0;
		sprPlane[n33] <= 4'hF;//n[3:0];
		sprBurstStart[n33] <= 9'h000;
		sprBurstEnd[n33] <= 9'h1FF;
		sprColorDepth[n33] <= 2'b10;
	end
  hSprPos[0] <= 210;
  vSprPos[0] <= 72;

  bgTc <= 24'h08_08_08;
  bkColor <= 24'hFF_FF_60;
end
else begin
	vSync1 <= vSync;
	if (vSync & ~vSync1)
		sprDt <= sprDt | vSyncT;

	// clear DMA trigger bit once DMA is recognized
	if (dmaStart[5])
		sprDt[dmaOwner] <= 1'b0;

	if (cs_regs & we_i) begin

		casez (adr_i[9:2])
		8'b100?????:
			begin
				if (&sel_i[1:0]) sprBurstStart[adr_i[6:2]] <= dat_i[8:0];
				if (&sel_i[3:2]) sprBurstEnd[adr_i[6:2]] <= dat_i[24:16];
			end
		8'b11110000:	// 3C0
			begin
				if (sel_i[0]) sprEn[7:0] <= dat_i[7:0];
				if (sel_i[1]) sprEn[15:8] <= dat_i[15:8];
				if (sel_i[2]) sprEn[23:16] <= dat_i[23:16];
				if (sel_i[3]) sprEn[31:24] <= dat_i[31:24];
			end
		8'b11110001:	// 3C4
			if (sel_i[0]) begin
				sprSprIe <= dat_i[0];
				sprBkIe <= dat_i[1];
			end
		// update DMA trigger
		// s_dat_i[7:0] indicates which triggers to set  (1=set,0=ignore)
		// s_dat_i[7:0] indicates which triggers to clear (1=clear,0=ignore)
		8'b11110100:	// 3D0
			begin
				if (sel_i[0])	sprDt[7:0] <= sprDt[7:0] | dat_i[7:0];
				if (sel_i[1]) sprDt[15:8] <= sprDt[15:8] | dat_i[15:8];
				if (sel_i[2]) sprDt[23:16] <= sprDt[23:16] | dat_i[23:16];
				if (sel_i[3])	sprDt[31:24] <= sprDt[31:24] | dat_i[31:24];
			end
		8'b11110101:	// 3D4
			begin
				if (sel_i[0])	sprDt[7:0] <= sprDt[7:0] & ~dat_i[7:0];
				if (sel_i[1]) sprDt[15:8] <= sprDt[15:8] & ~dat_i[15:8];
				if (sel_i[2]) sprDt[23:16] <= sprDt[23:16] & ~dat_i[23:16];
				if (sel_i[3])	sprDt[31:24] <= sprDt[31:24] & ~dat_i[31:24];
			end
		8'b11110110:	// 3D8
			begin
				if (sel_i[0])	vSyncT[7:0] <= dat_i[7:0];
				if (sel_i[1]) vSyncT[15:8] <= dat_i[15:8];
				if (sel_i[2]) vSyncT[23:16] <= dat_i[23:16];
				if (sel_i[3])	vSyncT[31:24] <= dat_i[31:24];
			end
		8'b11111010:	// 3E8
			begin
				if (sel_i[0])	bgTc[7:0] <= dat_i[7:0];
				if (sel_i[1])	bgTc[15:8] <= dat_i[15:8];
				if (sel_i[2])	bgTc[23:16] <= dat_i[23:16];
			end
		8'b11111011:	// 3EC
			begin
				if (sel_i[0]) bkColor[7:0] <= dat_i[7:0];
				if (sel_i[1]) bkColor[15:8] <= dat_i[15:8];
				if (sel_i[2]) bkColor[23:16] <= dat_i[23:16];
			end
		8'b0?????00:
			 begin
	    		if (sel_i[0]) hSprPos[sprN][ 7:0] <= dat_i[ 7: 0];
	    		if (sel_i[1]) hSprPos[sprN][10:8] <= dat_i[10: 8];
	    		if (sel_i[2]) vSprPos[sprN][ 7:0] <= dat_i[23:16];
	    		if (sel_i[3]) vSprPos[sprN][10:8] <= dat_i[26:24];
    		end
    8'b0?????01:
			begin
    		if (sel_i[0]) begin
					sprWidth[sprN] <= dat_i[7:0];
        end
    		if (sel_i[1]) begin
					sprHeight[sprN] <= dat_i[15:8];
        end
				if (sel_i[2]) begin
        	hSprRes[sprN] <= dat_i[19:16];
        	vSprRes[sprN] <= dat_i[23:20];
				end
				if (sel_i[3]) begin
					sprPlane[sprN] <= dat_i[27:24];
					sprColorDepth[sprN] <= dat_i[31:30];
				end
			end
		8'b0?????10:
			begin	// DMA address set on clk_i domain
        if (sel_i[0]) sprImageOffs[sprN][ 7:0] <= dat_i[7:0];
        if (sel_i[1]) sprImageOffs[sprN][10:8] <= dat_i[11:8];
				if (sel_i[1]) sprSysAddr[sprN][15:12] <= dat_i[15:12];
				if (sel_i[2]) sprSysAddr[sprN][23:16] <= dat_i[23:16];
				if (sel_i[3]) sprSysAddr[sprN][31:24] <= dat_i[31:24];
			end
		8'b0?????11:
			begin
				if (sel_i[0]) sprTc[sprN][ 7:0] <= dat_i[ 7:0];
				if (sel_i[1]) sprTc[sprN][15:8] <= dat_i[15:8];
				if (sel_i[2]) sprTc[sprN][23:16] <= dat_i[23:16];
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

integer n2;
always_ff @(posedge vclk)
for (n2 = 0; n2 < pnSpr; n2 = n2 + 1)
case(sprColorDepth[n2])
2'd1:	sprAddr1[n2] <= sprAddr[n2][11:2];
2'd2:	sprAddr1[n2] <= sprAddr[n2][10:1];
2'd3:	sprAddr1[n2] <= sprAddr[n2][ 9:0];
default:	;
endcase

integer n4, n5, n27;
always_ff @(posedge vclk)
for (n4 = 0; n4 < pnSpr; n4 = n4 + 1)
	sprAddr2[n4] <= sprAddr1[n4];
always_ff @(posedge vclk)
for (n5 = 0; n5 < pnSpr; n5 = n5 + 1)
	sprAddr3[n5] <= sprAddr2[n5];
always_ff @(posedge vclk)
for (n27 = 0; n27 < pnSpr; n27 = n27 + 1)
	sprAddr4[n27] <= sprAddr3[n27];

// The pixels are displayed from most signicant to least signicant bits of the 
// word. Display order is opposite to memory storage. So, the least significant
// address bits are flipped to get the correct display.
integer n3;
always_ff @(posedge vclk)
for (n3 = 0; n3 < pnSpr; n3 = n3 + 1)
case(sprColorDepth[n3])
2'd1:
	case(~sprAddr4[n3][1:0])
	2'd3:	sprOut5[n3] <= sprOut4[n3][31:24];
	2'd2:	sprOut5[n3] <= sprOut4[n3][23:16];
	2'd1:	sprOut5[n3] <= sprOut4[n3][15:8];
	2'd0:	sprOut5[n3] <= sprOut4[n3][7:0];
	endcase
2'd2:
	case(~sprAddr4[n3][0])
	1'd0:	sprOut5[n3] <= {sprOut4[n3][15],16'h0000,sprOut4[n3][14:0]};
	1'd1:	sprOut5[n3] <= {sprOut4[n3][31],16'h0000,sprOut4[n3][30:16]};
	endcase
2'd3:
	sprOut5[n3] <= sprOut4[n3];
default:	;
endcase

generate
for (g = 0; g < pnSpr; g = g + 1) begin : sprRam
	SpriteRam sprRam0
	(
		.clka(m_clk_i),
		.addra(m_adr_or),
		.dina(m_dat_ir),
		.ena(sprWe[g]),
		.wea(sprWe[g]),
		// Core reg and output reg 3 clocks from read address
		.clkb(vclk),
		.addrb(sprAddr1[g]),
		.doutb(sprOut4[g]),
		.enb(1'b1)
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

always_ff @(posedge vclk)
if (hSyncEdge) hctr <= {phBits{1'b0}};
else hctr <= hctr + 2'd1;

always_ff @(posedge vclk)
if (vSyncEdge) vctr <= {pvBits{1'b0}};
else if (hSyncEdge) vctr <= vctr + 2'd1;

// track sprite horizontal reset
integer n19;
always_ff @(posedge vclk)
for (n19 = 0; n19 < pnSpr; n19 = n19 + 1)
	hSprReset[n19] <= hctr==hSprPos[n19];

// track sprite vertical reset
integer n20;
always_ff @(posedge vclk)
for (n20 = 0; n20 < pnSpr; n20 = n20 + 1)
	vSprReset[n20] <= vctr==vSprPos[n20];

integer n21;
always_comb
for (n21 = 0; n21 < pnSpr; n21 = n21 + 1)
	sprDe[n21] <= hSprDe[n21] & vSprDe[n21];


// take care of sprite size scaling
// video clock division
reg [31:0] hSprNextPixel;
reg [31:0] vSprNextPixel;
reg [3:0] hSprPt [31:0];   // horizontal pixel toggle
reg [3:0] vSprPt [31:0];   // vertical pixel toggle
integer n17;
always_comb
for (n17 = 0; n17 < pnSpr; n17 = n17 + 1)
    hSprNextPixel[n17] = hSprPt[n17]==hSprRes[n17];
integer n18;
always_comb
for (n18 = 0; n18 < pnSpr; n18 = n18 + 1)
    vSprNextPixel[n18] = vSprPt[n18]==vSprRes[n18];

// horizontal pixel toggle counter
integer n6;
always_ff @(posedge vclk)
for (n6 = 0; n6 < pnSpr; n6 = n6 + 1)
	if (hSprReset[n6])
		hSprPt[n6] <= 4'd0;
  else if (hSprNextPixel[n6])
    hSprPt[n6] <= 4'd0;
  else
    hSprPt[n6] <= hSprPt[n6] + 2'd1;

// vertical pixel toggle counter
integer n7;
always_ff @(posedge vclk)
for (n7 = 0; n7 < pnSpr; n7 = n7 + 1)
  if (hSprReset[n7]) begin
  	if (vSprReset[n7])
  		vSprPt[n7] <= 4'd0;
    else if (vSprNextPixel[n7])
      vSprPt[n7] <= 4'd0;
    else
      vSprPt[n7] <= vSprPt[n7] + 2'd1;
  end


// clock sprite image address counters
integer n8;
always_ff @(posedge vclk)
for (n8 = 0; n8 < pnSpr; n8 = n8 + 1) begin
    // hReset and vReset - top left of sprite,
    // reset address to image offset
	if (hSprReset[n8] & vSprReset[n8]) begin
		sprAddr[n8]  <= sprImageOffs[n8];
		sprAddrB[n8] <= sprImageOffs[n8];
	end
	// hReset:
	//  If the next vertical pixel
	//      set backup address to current address
	//  else
	//      set current address to backup address
	//      in order to rescan the line
	else if (hSprReset[n8]) begin
		if (vSprNextPixel[n8])
			sprAddrB[n8] <= sprAddr[n8];
		else
			sprAddr[n8]  <= sprAddrB[n8];
	end
	// Not hReset or vReset - somewhere on the sprite scan line
	// just advance the address when the next pixel should be
	// fetched
	else if (hSprDe[n8] & hSprNextPixel[n8])
		sprAddr[n8] <= sprAddr[n8] + 2'd1;
end


// clock sprite column (X) counter
integer n9;
always_ff @(posedge vclk)
for (n9 = 0; n9 < pnSpr; n9 = n9 + 1)
	if (hSprReset[n9])
		hSprCnt[n9] <= 8'd1;
	else if (hSprNextPixel[n9])
		hSprCnt[n9] <= hSprCnt[n9] + 2'd1;


// clock sprite horizontal display enable
integer n10;
always_ff @(posedge vclk)
for (n10 = 0; n10 < pnSpr; n10 = n10 + 1) begin
	if (hSprReset[n10])
		hSprDe[n10] <= 1'b1;
	else if (hSprNextPixel[n10]) begin
		if (hSprCnt[n10] == sprWidth[n10])
			hSprDe[n10] <= 1'b0;
	end
end


// clock the sprite row (Y) counter
integer n11;
always_ff @(posedge vclk)
for (n11 = 0; n11 < pnSpr; n11 = n11 + 1)
	if (hSprReset[n11]) begin
		if (vSprReset[n11])
			vSprCnt[n11] <= 8'd1;
		else if (vSprNextPixel[n11])
			vSprCnt[n11] <= vSprCnt[n11] + 2'd1;
	end


// clock sprite vertical display enable
integer n12;
always_ff @(posedge vclk)
for (n12 = 0; n12 < pnSpr; n12 = n12 + 1) begin
	if (hSprReset[n12]) begin
		if (vSprReset[n12])
			vSprDe[n12] <= 1'b1;
		else if (vSprNextPixel[n12]) begin
			if (vSprCnt[n12] == sprHeight[n12])
				vSprDe[n12] <= 1'b0;
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
reg [31:0] sprDe1, sprDe2, sprDe3, sprDe4, sprDe5, sprDe6;
reg [31:0] sproact;
integer n13;
always_ff @(posedge vclk)
for (n13 = 0; n13 < pnSpr; n13 = n13 + 1)
	sprDe1[n13] <= sprDe[n13];
integer n22;
always_ff @(posedge vclk)
for (n22 = 0; n22 < pnSpr; n22 = n22 + 1)
	sprDe2[n22] <= sprDe1[n22];
integer n23;
always_ff @(posedge vclk)
for (n23 = 0; n23 < pnSpr; n23 = n23 + 1)
	sprDe3[n23] <= sprDe2[n23];
integer n24;
always_ff @(posedge vclk)
for (n24 = 0; n24 < pnSpr; n24 = n24 + 1)
	sprDe4[n24] <= sprDe3[n24];
integer n25;
always_ff @(posedge vclk)
for (n25 = 0; n25 < pnSpr; n25 = n25 + 1)
	sprDe5[n25] <= sprDe4[n25];
integer n26;
always_ff @(posedge vclk)
for (n26 = 0; n26 < pnSpr; n26 = n26 + 1)
	sprDe6[n26] <= sprDe5[n26];


// Detect which sprite outputs are active
// The sprite output is active if the current display pixel
// address is within the sprite's area, the sprite is enabled,
// and it's not a transparent pixel that's being displayed.
integer n14;
always_ff @(posedge vclk)
for (n14 = 0; n14 < pnSpr; n14 = n14 + 1)
	sproact[n14] <= sprEn[n14] && sprDe5[n14] && sprTc[n14]!=sprOut5[n14];
integer n15;
always_ff @(posedge vclk)
for (n15 = 0; n15 < pnSpr; n15 = n15 + 1)
	sprOut[n15] <= sprOut5[n15];

// register sprite activity flag
// The image combiner uses this flag to know what to do with
// the sprite output.
always_ff @(posedge vclk)
	outact <= |sproact;

// Display data comes from the active sprite with the
// highest display priority.
// Make sure that alpha blending is turned off when
// no sprite is active.
integer n16;
always_ff @(posedge vclk)
begin
	out <= 32'h0080;	// alpha blend max (and off)
	outplane <= 4'h0;
	colorBits <= 2'b00;
	for (n16 = pnSprm; n16 >= 0; n16 = n16 - 1)
		if (sproact[n16]) begin
			out <= sprOut[n16];
			outplane <= sprPlane[n16];
			colorBits <= sprColorDepth[n16];
		end
end


// combine the text / graphics color output with sprite color output
// blend color output
wire [23:0] blendedColor = {
 	fnBlend(out[7:0],zrgbIn[23:16]),		// R
 	fnBlend(out[7:0],zrgbIn[15: 8]),		// G
 	fnBlend(out[7:0],zrgbIn[ 7: 0])};	// B


always_ff @(posedge vclk)
if (blank_i)
	zrgbOut <= 0;
else begin
	if (outact) begin
		if (zrgbIn[31:28] > outplane) begin			// rgb input is in front of sprite
			zrgbOut <= zrgbIn;
		end
		else 
		if (!out[31]) begin			// a sprite is displayed without alpha blending
			case(colorBits)
			2'd0:	zrgbOut <= {outplane,4'h0,out[7:5],5'b0,out[4:2],5'b0,out[1:0],6'b0};
			2'd1:	zrgbOut <= {outplane,4'h0,out[7:5],5'b0,out[4:2],5'b0,out[1:0],6'b0};
			2'd2:	zrgbOut <= {outplane,4'h0,out[14:10],3'b0,out[9:5],3'b0,out[4:0],3'b0};
			2'd3:	zrgbOut <= {outplane,4'h0,out[23:16],out[15:8],out[7:0]};
			endcase
		end
		else
			zrgbOut <= {outplane,4'h0,blendedColor};
	end
	else
		zrgbOut <= zrgbIn;
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
else if (pnSpr==16)
	case (sproact)
	16'h0000,
	16'h0001,
	16'h0002,
	16'h0004,
	16'h0008,
	16'h0010,
	16'h0020,
	16'h0040,
	16'h0080,
	16'h0100,
	16'h0200,
	16'h0400,
	16'h0800,
	16'h1000,
	16'h2000,
	16'h4000,
	16'h8000:	sprCollision = 0;
	default:	sprCollision = 1;
	endcase
else if (pnSpr==32)
	case (sproact)
	32'h00000000,
	32'h00000001,
	32'h00000002,
	32'h00000004,
	32'h00000008,
	32'h00000010,
	32'h00000020,
	32'h00000040,
	32'h00000080,
	32'h00000100,
	32'h00000200,
	32'h00000400,
	32'h00000800,
	32'h00001000,
	32'h00002000,
	32'h00004000,
	32'h00008000,
	32'h00010000,
	32'h00020000,
	32'h00040000,
	32'h00080000,
	32'h00100000,
	32'h00200000,
	32'h00400000,
	32'h00800000,
	32'h01000000,
	32'h02000000,
	32'h04000000,
	32'h08000000,
	32'h10000000,
	32'h20000000,
	32'h40000000,
	32'h80000000:		sprCollision = 0;
	default:			sprCollision = 1;
	endcase
end
endgenerate

// Detect when a sprite-background collision has occurred
integer n31;
always_comb
for (n31 = 0; n31 < pnSpr; n31 = n31 + 1)
	bkCollision[n31] <=
		sproact[n31] && zrgbIn[31:28]==sprPlane[n31];

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
	if ((sprSprCollision1==0)||(cs_regs && sel_i[0] && adr_i[9:2]==8'b11110010)) begin
		sprSprIRQPending1 <= 1;
		sprSprIRQ1 <= sprSprIe;
		sprSprCollision1 <= sproact;
	end
	else
		sprSprCollision1 <= sprSprCollision1|sproact;
end
else if (cs_regs && sel_i[0] && adr_i[9:2]==8'b11110010) begin
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
else if (|bkCollision) begin
	// Is the register being cleared at the same time
	// a collision occurss ?
	// isFirstCollision
	if ((sprBkCollision1==0) || (cs_regs && sel_i[0] && adr_i[9:2]==8'b11110011)) begin	
		sprBkIRQ1 <= sprBkIe;
		sprBkCollision1 <= bkCollision;
		sprBkIRQPending1 <= 1;
	end
	else
		sprBkCollision1 <= sprBkCollision1|bkCollision;
end
else if (cs_regs && sel_i[0] && adr_i[9:2]==8'b11110011) begin
	sprBkCollision1 <= 0;
	sprBkIRQPending1 <= 0;
	sprBkIRQ1 <= 0;
end

endmodule

/*
module SpriteRam32 (
	clka, adra, dia, doa, cea, wea,
	clkb, adrb, dib, dob, ceb, web
);
input clka;
input [9:0] adra;
input [31:0] dia;
output [31:0] doa;
input cea;
input wea;
input clkb;
input [9:0] adrb;
input [31:0] dib;
output [31:0] dob;
input ceb;
input web;

reg [31:0] mem [0:1023];
reg [9:0] radra;
reg [9:0] radrb;

always @(posedge clka)	if (cea) radra <= adra;
always @(posedge clkb) 	if (ceb) radrb <= adrb;
assign doa = mem [radra];
assign dob = mem [radrb];
always @(posedge clka)
	if (cea & wea) mem[adra] <= dia;
always @(posedge clkb)
	if (ceb & web) mem[adrb] <= dib;

endmodule

*/
