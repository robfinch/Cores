`timescale 1ns / 1ps
// ============================================================================
//  Bitmap Controller (1364h x 768v x 8bpp):
//  - Displays a bitmap from memory.
//  - the video mode timing to be 1366x768
//
//
//	(C) 2008-2013  Robert Finch
//	robfinch<remove>@opencores.org
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
//		$200000 - the second 2MiB of RAM
//
//
//	Verilog 1995
//
// ============================================================================

module rtfBitmapController1364x768(
	rst_i, clk_i, bte_o, cti_o, bl_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o,
	vclk, hSync, vSync, blank, rgbo, page, onoff
);
parameter BM_BASE_ADDR1 = 32'h0410_0000;
parameter BM_BASE_ADDR2 = 32'h0414_0000;

// SYSCON
input rst_i;				// system reset
input clk_i;				// system bus interface clock

// Video Master Port
// Used to read memory via burst access
output [1:0] bte_o;
output [2:0] cti_o;
output [5:0] bl_o;
output cyc_o;			// video burst request
output stb_o;
input  ack_i;			// vid_acknowledge from memory
output we_o;
output [ 3:0] sel_o;
output [33:0] adr_o;	// address for memory access
input  [31:0] dat_i;	// memory data input
output [31:0] dat_o;

// Video
input vclk;				// Video clock 85.71 MHz
input hSync;			// start/end of scan line
input vSync;			// start/end of frame
input blank;			// blank the output
output [7:0] rgbo;		// 8-bit RGB output
reg [7:0] rgbo;

input page;				// which page to display
input onoff;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// IO registers
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [1:0] bte_o;
reg [2:0] cti_o;
reg [5:0] bl_o;
reg sync_o;
reg cyc_o;
reg stb_o;
reg we_o;
reg [3:0] sel_o;
reg [33:0] adr_o;
reg [31:0] dat_o;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [1:0] hres;
reg [11:0] hctr;		// horizontal reference counter
wire [11:0] hctr1 = hctr - 12'd212;
reg [11:0] vctr;		// vertical reference counter
wire [11:0] vctr1 = vctr - 12'd27;
reg [33:0] baseAddr;	// base address register
wire [7:0] rgbo1;
reg [11:0] pixelRow;
reg [11:0] pixelCol;

always @(page)
	baseAddr = page ? {BM_BASE_ADDR2,2'b00} : {BM_BASE_ADDR1,2'b00};

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Horizontal and Vertical timing reference counters
// - The memory fetch address is determined from these counters.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire hSyncEdge, vSyncEdge;
edge_det ed0(.rst(rst_i), .clk(vclk), .ce(1'b1), .i(hSync), .pe(hSyncEdge), .ne(), .ee() );
edge_det ed1(.rst(rst_i), .clk(vclk), .ce(1'b1), .i(vSync), .pe(vSyncEdge), .ne(), .ee() );

always @(posedge vclk)
if (rst_i)        	hctr <= 1;
else if (hSyncEdge) hctr <= 1;
else            	hctr <= hctr + 1;

always @(posedge vclk)
if (rst_i)        	vctr <= 1;
else if (vSyncEdge) vctr <= 1;
else if (hSyncEdge) vctr <= vctr + 1;


// Pixel row and column are derived from the horizontal and vertical counts.

always @(vctr1)
	pixelRow = vctr1[11:0];
always @(hctr1)
	case(hres)
	2'b00:		pixelCol = hctr1[11:0];
	2'b01:		pixelCol = hctr1[11:1];
	2'b10:		pixelCol = hctr1[11:2];
	default:	pixelCol = hctr1[11:2];
	endcase
	

wire vFetch = vctr1 < 12'd768;

// Video Request Block
// 1364x768
// There are 1800 clock available on a scan line. For simplicity we
// use only 1364 of 1366 pixel on the display. 1364 is a multiple
// of four bytes, which is the unit being burst fetched.
// - 1364 =5*256+84 bytes
//  6 burst accesses are required, with the last burst being only for
//  21 data words (84 bytes). This means we have a budget of about 300
// pixel clock cycles per burst. (1800/6). It only takes about 70 clock
// cycles to read 64 words. 85/800 < 11% Less than 11% of memory
// bandwidth is used.
// Burst length is set to 64. The burst controller should be able
// to fetch a word (32 bits) every clock cycle, plus some overhead
// for memory latency. The memory clock is much faster than the system
// clock. 
// - 
// - Issue a request for access to memory every 300 clock cycles
// - Reset the request flag once an access has been initiated.
// - 1364 bytes (pixels) are read per scan line

reg [4:0] vreq;

// Request must be from vclk domain. vid_req will be active for numerous
// clock cycles as a burst type fetch is used. The ftch and vFetch may
// only be active for a single video clock cycle. vclk must be used so
// these signals are not missed due to a clock domain crossing. We luck
// out here because of the length of time vid_req is active.
//
always @(posedge vclk)
begin
	if (vFetch) begin
		case(hres)
		// - 1364 =5*256+84 bytes
		2'b00:
			begin
			if (hctr==12'd16 ) vreq <= 5'b10000;
			if (hctr==12'd316) vreq <= 5'b10001;
			if (hctr==12'd616) vreq <= 5'b10010;
			if (hctr==12'd916) vreq <= 5'b10011;
			if (hctr==12'd1216) vreq <= 5'b10100;
			if (hctr==12'd1516) vreq <= 5'b10101;
			end
		// - 680 =2*256+168 bytes
		2'b01:
			begin
			if (hctr==12'd16 ) vreq <= 5'b10000;
			if (hctr==12'd616) vreq <= 5'b10001;
			if (hctr==12'd1216) vreq <= 5'b10010;
			end
		// 340 = 256 + 84
		2'b10:
			begin
			if (hctr==12'd16 ) vreq <= 5'b10000;
			if (hctr==12'd1216) vreq <= 5'b10001;
			end
		default:
			begin
			if (hctr==12'd16 ) vreq <= 5'b10000;
			if (hctr==12'd1216) vreq <= 5'b10001;
			end
		endcase
	end
	if (cyc_o) vreq[4] <= 1'b0;
end
	
// Cross the clock domain with the request signal
reg do_cyc;
always @(posedge clk_i)
	do_cyc <= vreq[4] & onoff;

reg [10:0] rmul;
always @(hres)
	case(hres)
	2'b00:	rmul = 11'd1364;
	2'b01:	rmul = 11'd680;
	2'b10:	rmul = 11'd340;
	default:	rmul = 11'd340;
	endcase
wire[23:0] rowOffset = pixelRow * rmul;
reg [11:0] fetchCol;

// - read from assigned video memory address, using burst mode reads
// - 64 pixels at a time are read
// - video data is fetched one pixel row in advance
//
reg [5:0] bcnt;
wire [5:0] bcnt_inc = bcnt + 6'd1;
always @(posedge clk_i)
if (rst_i) begin
	hres <= 2'b00;
	bte_o <= 2'b00;		// linear burst
	cti_o <= 3'b000;	// classic cycle
	bl_o <= 6'd0;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	sel_o <= 4'b0000;
	we_o <= 1'b0;
	adr_o <= 34'h0000_0000;
	dat_o <= 32'h0000_0000;
	fetchCol <= 12'd0;
	bcnt <= 6'd0;
end
else begin
	if (do_cyc & !cyc_o) begin
		cti_o <= 3'b001;	// constant address burst
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		bcnt <= 6'd0;
		bl_o <= vreq==5'b10101 ? 6'd20: 6'd63;
		fetchCol <= {vreq[3:0],8'h00};
		adr_o <= baseAddr + rowOffset + rmul + {vreq[3:0],8'h00};
	end
	if (cyc_o & ack_i) begin
		fetchCol <= fetchCol + 12'd4;
		bcnt <= bcnt_inc;
		if (bl_o==bcnt_inc)
			cti_o <= 3'b111;	// end of burst
		if (bl_o==bcnt) begin
			cti_o <= 3'b000;	// classic cycles again
			bl_o <= 6'd0;
			cyc_o <= 1'b0;
			stb_o <= 1'b0;
			sel_o <= 4'b0000;
			adr_o <= 34'h0000_0000;
		end
	end
end


always @(posedge vclk)
	rgbo <= onoff ? rgbo1 : 8'h00;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Video Line Buffer
// - gets written in bursts, but read continuously
// - buffer is used as two halves - one half is displayed (read) while
//   the other is fetched (write).
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//
rtfBitmapLineBuffer u5
(
	.wclk(clk_i),
	.we(cyc_o & ack_i),
	.wadr({~pixelRow[0],fetchCol[10:2]}),
	.d(dat_i),
	.rclk(vclk),
	.radr({pixelRow[0],pixelCol[10:0]}),
	.q(rgbo1)
);

endmodule

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Storage for 4096x8 bit pixels (4096x8 data)
// 4096x8 read side, 1024x32 write side
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//
module rtfBitmapLineBuffer(wclk, we, wadr, d, rclk, radr, q);
input wclk;
input we;
input [9:0] wadr;
input [31:0] d;
input rclk;
input [11:0] radr;
output [7:0] q;
reg [7:0] q;

reg [31:0] mem [0:1023];
reg [31:0] memo;
reg [11:0] rradr;

always @(posedge wclk)
	if (we) mem[wadr] <= d;

always @(posedge rclk)
	rradr <= radr;

always @(rradr)
	memo <= mem[rradr[11:2]];

always @(rradr or memo)
	case(rradr[1:0])
	2'b00:	q <= memo[ 7: 0];
	2'b01:	q <= memo[15: 8];
	2'b10:	q <= memo[23:16];
	2'b11:	q <= memo[31:24];
	endcase

endmodule
