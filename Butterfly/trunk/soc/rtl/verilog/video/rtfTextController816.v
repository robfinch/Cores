`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rtfTextController816.v
//		text controller
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
//	Text Controller
//
//	FEATURES
//
//	This core requires an external timing generator to provide horizontal
//	and vertical sync signals, but otherwise can be used as a display
//  controller on it's own. However, this core may also be embedded within
//  another core such as a VGA controller.
//
//	Window positions are referenced to the rising edge of the vertical and
//	horizontal sync pulses.
//
//	The core includes an embedded dual port RAM to hold the screen
//	characters.
//
//
//--------------------------------------------------------------------
// Registers
//
//      00 -         nnnnnnnn  number of columns (horizontal displayed number of characters)
//      01 -         nnnnnnnn  number of rows    (vertical displayed number of characters)
//      02 -       n nnnnnnnn  window left       (horizontal sync position - reference for left edge of displayed)
//      03 -       n nnnnnnnn  window top        (vertical sync position - reference for the top edge of displayed)
//      04 -         ---nnnnn  maximum scan line (char ROM max value is 7)
//		05 -         hhhhwwww  pixel size, hhhh=height,wwww=width
//      07 -       n nnnnnnnn  color code for transparent background
//      08 -         -BPnnnnn  cursor start / blink control
//                             BP: 00=no blink
//                             BP: 01=no display
//                             BP: 10=1/16 field rate blink
//                             BP: 11=1/32 field rate blink
//      09 -        ----nnnnn  cursor end
//      10 - aaaaaaaa aaaaaaaaa  start address (index into display memory)
//      11 - aaaaaaaa aaaaaaaaa  cursor position
//      12 - aaaaaaaa aaaaaaaaa  light pen position
//--------------------------------------------------------------------
//
// ============================================================================

module rtfTextController816(rst, clk, rdy, rw, vda, ad, db, vclk, hsync, vsync, blank, border, rgbIn, rgbOut);
parameter COLS = 12'd84;
parameter ROWS = 12'd31;
parameter pTextAddress = 32'h00FD0000;
parameter pBitmapAddress = 32'h00FE0000;
parameter pRegAddress = 32'h00FEA000;

input rst;
input clk;
output rdy;
input rw;
input vda;
input [31:0] ad;
inout tri [7:0] db;

// Video signals
input vclk;				// video dot clock
input hsync;			// end of scan line
input vsync;			// end of frame
input blank;			// blanking signal
input border;			// border area
input [24:0] rgbIn;		// input pixel stream
output reg [24:0] rgbOut;	// output pixel stream

wire [23:0] bkColor24;	// background color
wire [23:0] fgColor24;	// foreground color
wire [23:0] tcColor24;	// transparent color

wire pix;				// pixel value from character generator 1=on,0=off

reg por;
reg [7:0] dbo;
reg [7:0] rego;
reg [11:0] windowTop;
reg [11:0] windowLeft;
reg [11:0] numCols;
reg [11:0] numRows;
reg [11:0] charOutDelay;
reg [ 1:0] mode;
reg [ 4:0] maxScanline;
reg [ 4:0] maxScanpix;
reg [ 4:0] cursorStart, cursorEnd;
reg [15:0] cursorPos;
reg [1:0] cursorType;
reg [15:0] startAddress;
reg [ 2:0] rBlink;
reg [ 3:0] bdrColorReg;
reg [ 3:0] pixelWidth;	// horizontal pixel width in clock cycles
reg [ 3:0] pixelHeight;	// vertical pixel height in scan lines

wire [11:0] hctr;		// horizontal reference counter (counts clocks since hSync)
wire [11:0] scanline;	// scan line
wire [11:0] row;		// vertical reference counter (counts rows since vSync)
wire [11:0] col;		// horizontal column
reg  [ 4:0] rowscan;	// scan line within row
wire nxt_row;			// when to increment the row counter
wire nxt_col;			// when to increment the column counter
wire [ 5:0] bcnt;		// blink timing counter
wire blink;
reg  iblank;

wire nhp;				// next horizontal pixel
wire ld_shft = nxt_col & nhp;


// display and timing signals
reg [15:0] txtAddr;		// index into memory
reg [15:0] penAddr;
wire [7:0] txtOut;		// character code
wire [7:0] charOut;		// character ROM output
wire [3:0] txtBkColor;	// background color code
wire [3:0] txtFgColor;	// foreground color code
reg  [4:0] txtTcCode;	// transparent color code
reg  bgt;

wire [15:0] tdat_o;
wire [8:0] chdat_o;

wire [2:0] scanindex = scanline[2:0];

//--------------------------------------------------------------------
// Address Decoding
// I/O range Dx
//--------------------------------------------------------------------
wire cs_text = vda && (ad[31:16]==pTextAddress[31:16]);
wire cs_rom  = vda && (ad[31:12]==pBitmapAddress[31:12]);
wire cs_reg  = vda && (ad[31: 4]==pRegAddress[31:4]);
wire cs_any = cs_text|cs_rom|cs_reg;

// Register outputs
always @(posedge clk)
	if (cs_rom) dbo <= chdat_o;
	else if (cs_reg) dbo <= rego;
	else dbo <= ad[0] ? tdat_o[15:8] : tdat_o[7:0];

assign db = cs_any & rw ? dbo : {8{1'bz}};

wire rdy2;
WaitStates #(3) u_ws
(
	.rst(rst),
	.clk(clk),
	.cs(cs_any),
	.rdy(rdy2)
);

assign rdy = cs_any ? (rw ? rdy2 : 1'b1) : 1'b1;

//--------------------------------------------------------------------
// Video Memory
//--------------------------------------------------------------------
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Address Calculation:
//  - Simple: the row times the number of  cols plus the col plus the
//    base screen address
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [17:0] rowcol;
always @(posedge vclk)
    rowcol <= row * numCols;
always @(posedge vclk)
	txtAddr <= startAddress + rowcol[15:0] + col;
/*
RAMB16_S4_S4 ram0(
	.CLKA(clk), .ADDRA(ad[12:1]), .DIA(db[3:0]), .DOA(tdat_o[3:0]), .ENA(cs_text & ~ad[0]), .WEA(~rw), .SSRA(),
	.CLKB(vclk), .ADDRB(txtAddr[11:0]), .DIB(4'hF), .DOB(txtOut[3:0]), .ENB(ld_shft), .WEB(1'b0), .SSRB()  );
RAMB16_S4_S4 ram1(
	.CLKA(clk), .ADDRA(ad[12:1]), .DIA(db[7:4]), .DOA(tdat_o[7:4]), .ENA(cs_text & ~ad[0]), .WEA(~rw), .SSRA(),
	.CLKB(vclk), .ADDRB(txtAddr[11:0]), .DIB(4'hF), .DOB(txtOut[7:4]), .ENB(ld_shft), .WEB(1'b0), .SSRB()  );
RAMB16_S4_S4 ram2(
	.CLKA(clk), .ADDRA(ad[12:1]), .DIA(db[3:0]), .DOA(tdat_o[11:8]), .ENA(cs_text & ad[0]), .WEA(~rw), .SSRA(),
	.CLKB(vclk), .ADDRB(txtAddr[11:0]), .DIB(4'hF), .DOB(txtFgColor), .ENB(ld_shft), .WEB(1'b0), .SSRB()  );
RAMB16_S4_S4 ram3(
	.CLKA(clk), .ADDRA(ad[12:1]), .DIA(db[7:4]), .DOA(tdat_o[15:12]), .ENA(cs_text & ad[0]), .WEA(~rw), .SSRA(),
	.CLKB(vclk), .ADDRB(txtAddr[11:0]), .DIB(4'hF), .DOB(txtBkColor), .ENB(ld_shft), .WEB(1'b0), .SSRB()  );
*/

// text screen RAM
syncRam4kx9_1rw1r textRam0
(
	.wclk(clk),
	.wadr(ad[12:1]),
	.i({1'b1,db}),
	.wo(tdat_o[7:0]),
	.wce((cs_text|por) & ~ad[0]),
	.we(~rw|por),
	.wrst(1'b0),

	.rclk(vclk),
	.radr(txtAddr[11:0]),
	.o(txtOut),
	.rce(ld_shft),
	.rrst(1'b0)
);

// screen attribute RAM
syncRam4kx9_1rw1r colorRam
(
	.wclk(clk),
	.wadr(ad[12:1]),
	.i(db),
	.wo(tdat_o[15:8]),
	.wce((cs_text|por) & ad[0]),
	.we(~rw|por),
	.wrst(1'b0),

	.rclk(vclk),
	.radr(txtAddr[11:0]),
	.o({txtBkColor,txtFgColor}),
	.rce(ld_shft),
	.rrst(1'b0)
);


//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Character bitmap ROM
// - room for 512 characters
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
syncRam4kx9_1rw1r charRam0
(
	.wclk(clk),
	.wadr(ad[11:0]),
	.i(db),
	.wo(chdat_o),
	.wce(cs_rom),
	.we(1'b0),
	.wrst(1'b0),

	.rclk(vclk),
	.radr({1'b1,txtOut,rowscan[2:0]}),
	.o(charOut),
	.rce(ld_shft),
	.rrst(1'b0)
);

// pipeline delay - sync color with character bitmap output
reg [3:0] txtBkCode1;
reg [3:0] txtFgCode1;
always @(posedge vclk)
	if (nhp & ld_shft) txtBkCode1 <= txtBkColor;
always @(posedge vclk)
	if (nhp & ld_shft) txtFgCode1 <= txtFgColor;
//--------------------------------------------------------------------
// Registers
//
// RW   00 -         nnnnnnnn  number of columns (horizontal displayed number of characters)
// RW   01 -         nnnnnnnn  number of rows    (vertical displayed number of characters)
//  W   02 -         nnnnnnnn  window left       (horizontal sync position - reference for left edge of displayed)
//  W   03 -                n
//  W   04 -         nnnnnnnn  window top        (vertical sync position - reference for the top edge of displayed)
//  W   05 -                n
//  W   06 -         ---nnnnn  maximum scan line (char ROM max value is 7)
//	W	07 -         hhhhwwww  pixel size, hhhh=height,wwww=width
//  W   08 -            nnnnn  transparent color
//  W   09 -         -BPnnnnn  cursor start / blink control
//                             BP: 00=no blink
//                             BP: 01=no display
//                             BP: 10=1/16 field rate blink
//                             BP: 11=1/32 field rate blink
//  W   10 -        ----nnnnn  cursor end
//  W   11 -        aaaaaaaaa  start address (index into display memory)
//  W   12 -        aaaaaaaaa
//  W   13 -        aaaaaaaaa  cursor position
//  W   14 -        aaaaaaaaa
//--------------------------------------------------------------------

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register read port
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
always @(cs_reg or cursorPos or penAddr or ad or numCols or numRows)
	if (cs_reg) begin
		case(ad[3:0])
		4'd0:		rego <= numCols;
		4'd1:		rego <= numRows;
		4'd13:		rego <= cursorPos[7:0];
		4'd14:		rego <= cursorPos[15:8];
		default:	rego <= 16'h0000;
		endcase
	end
	else
		rego <= 8'h00;


//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register write port
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg interlace;
always @(posedge clk)
	if (rst) begin
	   por <= 1'b1;
// 104x63
/*
		windowTop    <= 12'd26;
		windowLeft   <= 12'd260;
		pixelWidth   <= 4'd0;
		pixelHeight  <= 4'd1;		// 525 pixels (408 with border)
*/
// 52x31
/*
		// 84x47
		windowTop    <= 12'd16;
		windowLeft   <= 12'd90;
		pixelWidth   <= 4'd1;		// 681 pixels
		pixelHeight  <= 4'd1;		// 384 pixels
*/
		// 56x31
		windowTop    <= 12'd16;
		windowLeft   <= 12'd84;
		pixelWidth   <= 4'd1;		// 683 pixels
		pixelHeight  <= 4'd2;		// 256 pixels
		numCols      <= COLS;
		numRows      <= ROWS;
		maxScanline  <= 5'd7;
		maxScanpix   <= 5'd7;
		rBlink       <= 3'b111;		// 01 = non display
		startAddress <= 16'h0000;
		cursorStart  <= 5'd00;
		cursorEnd    <= 5'd31;
		cursorPos    <= 16'h0003;
		cursorType 	 <= 2'b00;
		txtTcCode    <= 5'h1f;
		charOutDelay <= 12'd2;
	end
	else begin
		
		if (cs_reg & ~rw) begin	// register write ?
            por <= 1'b0;
			case(ad[3:0])
			4'd00:	begin
					numCols    <= db;		// horizontal displayed
					//charOutDelay <= dat_i[31:16];
					end
			4'd01:	numRows    <= db;
			4'd02:	windowLeft[7:0] <= db;
			4'd03:  windowLeft[11:8] <= db[3:0];
			4'd04:	windowTop[7:0] <= db;		// vertical sync position
			4'd05:  windowTop[8] <= db[0];
			4'd06:	maxScanline <= db[4:0];
			4'd07:	begin
					pixelHeight <= db[7:4];
					pixelWidth  <= db[3:0];	// horizontal pixel width
					end
			4'd08:	txtTcCode   <= db[4:0];
			4'd09:	begin
					cursorStart <= db[4:0];	// scan line sursor starts on
					rBlink      <= db[7:5];
					//cursorType  <= dat_i[9:8];
					end
			4'd10:	cursorEnd   <= db[4:0];	// scan line cursor ends on
			4'd11:	startAddress[7:0] <= db;
			4'd12:	startAddress[15:8] <= db;
			4'd13:	cursorPos[7:0] <= db;
			4'd14:	cursorPos[15:8] <= db;
			endcase
		end
	end


//--------------------------------------------------------------------
//--------------------------------------------------------------------

// "Box" cursor bitmap
reg [7:0] curout;
always @(scanindex or cursorType)
	case({cursorType,scanindex})
	// Box cursor
	5'b00_000:	curout = 8'b11111111;
	5'b00_001:	curout = 8'b10000001;
	5'b00_010:	curout = 8'b10000001;
	5'b00_011:	curout = 8'b10000001;
	5'b00_100:	curout = 8'b10000001;
	5'b00_101:	curout = 8'b10000001;
	5'b00_110:	curout = 8'b10011001;
	5'b00_111:	curout = 8'b11111111;
	// vertical bar cursor
	5'b01_000:	curout = 8'b11000000;
	5'b01_001:	curout = 8'b10000000;
	5'b01_010:	curout = 8'b10000000;
	5'b01_011:	curout = 8'b10000000;
	5'b01_100:	curout = 8'b10000000;
	5'b01_101:	curout = 8'b10000000;
	5'b01_110:	curout = 8'b10000000;
	5'b01_111:	curout = 8'b11000000;
	// underline cursor
	5'b10_000:	curout = 8'b00000000;
	5'b10_001:	curout = 8'b00000000;
	5'b10_010:	curout = 8'b00000000;
	5'b10_011:	curout = 8'b00000000;
	5'b10_100:	curout = 8'b00000000;
	5'b10_101:	curout = 8'b00000000;
	5'b10_110:	curout = 8'b00000000;
	5'b10_111:	curout = 8'b11111111;
	// Asterisk
	5'b11_000:	curout = 8'b00000000;
	5'b11_001:	curout = 8'b00000000;
	5'b11_010:	curout = 8'b00100100;
	5'b11_011:	curout = 8'b00011000;
	5'b11_100:	curout = 8'b01111110;
	5'b11_101:	curout = 8'b00011000;
	5'b11_110:	curout = 8'b00100100;
	5'b11_111:	curout = 8'b00000000;
	endcase


//-------------------------------------------------------------
// Video Stuff
//-------------------------------------------------------------

wire pe_hsync;
wire pe_vsync;
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

// Horizontal counter:
//
HVCounter uhv1
(
	.rst(rst_i),
	.vclk(vclk),
	.pixcce(1'b1),
	.sync(hsync),
	.cnt_offs(windowLeft),
	.pixsz(pixelWidth),
	.maxpix(maxScanpix),
	.nxt_pix(nhp),
	.pos(col),
	.nxt_pos(nxt_col),
	.ctr(hctr)
);


// Vertical counter:
//
HVCounter uhv2
(
	.rst(rst_i),
	.vclk(vclk),
	.pixcce(pe_hsync),
	.sync(vsync),
	.cnt_offs(windowTop),
	.pixsz(pixelHeight),
	.maxpix(maxScanline),
	.nxt_pix(nvp),
	.pos(row),
	.nxt_pos(nxt_row),
	.ctr(scanline)
);
always @(posedge vclk)
	rowscan <= scanline - row * (maxScanline+1);


// Blink counter
//
VT163 #(6) ub1
(
	.clk(vclk),
	.clr_n(!rst_i),
	.ent(pe_vsync),
	.enp(1'b1),
	.ld_n(1'b1),
	.d(6'd0),
	.q(bcnt),
	.rco()
);

wire blink_en = (cursorPos+2==txtAddr) && (scanline[4:0] >= cursorStart) && (scanline[4:0] <= cursorEnd);

VT151 ub2
(
	.e_n(!blink_en),
	.s(rBlink),
	.i0(1'b1), .i1(1'b0), .i2(bcnt[4]), .i3(bcnt[5]),
	.i4(1'b1), .i5(1'b0), .i6(bcnt[4]), .i7(bcnt[5]),
	.z(blink),
	.z_n()
);

rtfColorROM ufgcr
(
	.clk(vclk),
	.ce(nhp & ld_shft),
	.code(txtFgCode1),
	.color(fgColor24)
);

rtfColorROM ubkcr
(
	.clk(vclk),
	.ce(nhp & ld_shft),
	.code(txtBkCode1),
	.color(bkColor24)
);
/*
always @(posedge vclk)
	if (nhp & ld_shft)
		bkColor24 <= {txtBkCode1[8:6],5'h10,txtBkCode1[5:3],5'h10,txtBkCode1[2:0],5'h10};
always @(posedge vclk)
	if (nhp & ld_shft)
		fgColor24 <= {txtFgCode1[8:6],5'h10,txtFgCode1[5:3],5'h10,txtFgCode1[2:0],5'h10};
*/
always @(posedge vclk)
	if (nhp & ld_shft)
		bgt <= txtBkCode1==txtTcCode;


// Convert character bitmap to pixels
// For convenience, the character bitmap data in the ROM is in the
// opposite bit order to what's needed for the display. The following
// just alters the order without adding any hardware.
//
wire [7:0] charRev = {
	charOut[0],
	charOut[1],
	charOut[2],
	charOut[3],
	charOut[4],
	charOut[5],
	charOut[6],
	charOut[7]
};

wire [7:0] charout1 = blink ? (charRev ^ curout) : charRev;

// Convert parallel to serial
ParallelToSerial ups1
(
	.rst(rst_i),
	.clk(vclk),
	.ce(nhp),
	.ld(ld_shft),
	.qin(1'b0),
	.d(charout1),
	.qh(pix)
);


// Pipelining Effect:
// - character output is delayed by 2 or 3 character times relative to the video counters
//   depending on the resolution selected
// - this means we must adapt the blanking signal by shifting the blanking window
//   two or three character times.
wire bpix = hctr[1] ^ scanline[4];// ^ blink;
always @(posedge vclk)
	if (nhp)	
		iblank <= (row >= numRows) || (col >= numCols + charOutDelay) || (col < charOutDelay);
	

// Choose between input RGB and controller generated RGB
// Select between foreground and background colours.
always @(posedge vclk)
	if (nhp) begin
		casex({blank,iblank,border,bpix,pix})
		5'b1xxxx:	rgbOut <= 25'h0000000;
		5'b01xxx:	rgbOut <= rgbIn;
		5'b0010x:	rgbOut <= 24'hBF2020;
		5'b0011x:	rgbOut <= 24'hDFDFDF;
		5'b000x0:	rgbOut <= bgt ? rgbIn : bkColor24;
		5'b000x1:	rgbOut <= fgColor24;
		default:	rgbOut <= rgbIn;
		endcase
	end

endmodule
