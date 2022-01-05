// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfTextController.sv
//		text controller
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
//  The controller expects a 64kB memory region to be reserved.
//
//  Memory Map:
//  0000-3FFF   display ram
//  DF00-DFFF   controller registers
//  E000-FFFF   character bitmap ram
//
//--------------------------------------------------------------------
// Registers
//
// 00h
//	7 - 0		         cccccccc  number of columns (horizontal displayed number of characters)
//	15- 8		         rrrrrrrr	 number of rows (vertical displayed number of characters)
//  19-16                dddd  character output delay
//	43-32       nnnn nnnnnnnn  window left       (horizontal sync position - reference for left edge of displayed)
//	59-48       nnnn nnnnnnnn  window top        (vertical sync position - reference for the top edge of displayed)
// 01h
//	 4- 0               nnnnn  maximum scan line (char ROM max value is 7)
//  11- 8							   wwww	 pixel size - width 
//  15-12							   hhhh	 pixel size - height 
//  24                      r  reset state bit
//  32                      e  controller enable
//  40                      m  multi-color mode
//  48-52               nnnnn  yscroll
//  56-60               nnnnn  xscroll
// 02h
//	23- 0   cccccccc cccccccc  color code for transparent background RGB 8,8,8 (only RGB 7,7,7 used)
//  63-32   cccc...cccc        border color ZRGB 8,8,8,8
// 03h
//	23- 0   cccccccc cccccccc  tile color code 1
//  55-32   cccccccc cccccccc  tile color code 2
// 04h
//   4- 0               eeeee	 cursor end
//   7- 5                 bbb  blink control
//                             BP: 00=no blink
//                             BP: 01=no display
//                             BP: 10=1/16 field rate blink
//                             BP: 11=1/32 field rate blink
//  12- 8               sssss  cursor start
//  15-14									 tt	 cursor image type (box, underline, sidebar, asterisk
//  47-32   aaaaaaaa aaaaaaaa	 cursor position
// 05h
//  15- 0   aaaaaaaa aaaaaaaa  start address (index into display memory)
// 07h
//	150 - - aaaaaaaa aaaaaaaa  light pen position
//--------------------------------------------------------------------
//
// ============================================================================

//`define USE_CLOCK_GATE
`define INTERNAL_RAMS	1'b1

module rfTextController(
	rst_i, clk_i, cs_i,
	cti_i, cyc_i, stb_i, ack_o, wr_i, adr_i, dat_i, dat_o,
	txt_clk_o, txt_cyc_o, txt_stb_o, txt_ack_i, txt_we_o, txt_sel_o, txt_adr_o, txt_dat_o, txt_dat_i,
	cbm_clk_o, cbm_cyc_o, cbm_stb_o, cbm_ack_i, cbm_we_o, cbm_sel_o, cbm_adr_o, cbm_dat_o, cbm_dat_i,
	lp_i,
	dot_clk_i, hsync_i, vsync_i, blank_i, border_i, zrgb_i, zrgb_o, xonoff_i
);
parameter num = 4'd1;
parameter COLS = 8'd56;
parameter ROWS = 8'd29;

// Syscon
input  rst_i;			// reset
input  clk_i;			// clock

// Slave signals
input  cs_i;            // circuit select
input  [2:0] cti_i;
input  cyc_i;			// valid bus cycle
input  stb_i;           // data strobe
output ack_o;			// data acknowledge
input  wr_i;			// write
input  [15:0] adr_i;	// address
input  [7:0] dat_i;	// data input
output reg [7:0] dat_o;	// data output

// Master Signals
output txt_clk_o;
output reg txt_cyc_o;
output reg txt_stb_o;
input txt_ack_i;
output txt_we_o;
output [7:0] txt_sel_o;
output reg [16:0] txt_adr_o;
output [63:0] txt_dat_o;
input [63:0] txt_dat_i;

output cbm_clk_o;			// character bitmap data fetch clock
output reg cbm_cyc_o;
output reg cbm_stb_o;
input cbm_ack_i;
output cbm_we_o;
output [7:0] cbm_sel_o;
output reg [15:0] cbm_adr_o;
output [63:0] cbm_dat_o;
input [63:0] cbm_dat_i;

input lp_i;				// light pen

// Video signals
input dot_clk_i;		// video dot clock
input hsync_i;			// end of scan line
input vsync_i;			// end of frame
input blank_i;			// blanking signal
input border_i;			// border area
input [31:0] zrgb_i;		// input pixel stream
output reg [31:0] zrgb_o;	// output pixel stream
input xonoff_i;

reg controller_enable;
reg [31:0] bkColor32, bkColor32d;	// background color
reg [31:0] fgColor32, fgColor32d;	// foreground color

reg [63:0] pix;				// pixel value from character generator 1=on,0=off

reg por;
wire vclk;
assign txt_clk_o = vclk;
assign txt_we_o = por;
assign txt_sel_o = 8'hFF;
assign cbm_clk_o = vclk;
assign cbm_we_o = 1'b0;
assign cbm_sel_o = 8'hFF;

reg [63:0] rego;
reg [4:0] yscroll;
reg [4:0] xscroll;
reg [11:0] windowTop;
reg [11:0] windowLeft;
reg [ 7:0] numCols;
reg [ 7:0] numRows;
reg [ 7:0] charOutDelay;
reg [ 1:0] mode;
reg [ 4:0] maxRowScan;
reg [ 4:0] maxScanpix;
reg [1:0] tileWidth;		// width of tile in bytes (0=1,1=2,2=4,3=8)
reg [ 4:0] cursorStart, cursorEnd;
reg [15:0] cursorPos;
reg [1:0] cursorType;
reg [15:0] startAddress;
reg [ 2:0] rBlink;
reg [3:0] bdrCode;
wire [23:0] bdrColor;		// Border color
reg [ 3:0] pixelWidth;	// horizontal pixel width in clock cycles
reg [ 3:0] pixelHeight;	// vertical pixel height in scan lines
reg mcm;								// multi-color mode

wire [11:0] hctr;		// horizontal reference counter (counts clocks since hSync)
wire [11:0] scanline;	// scan line
reg [ 7:0] row;		// vertical reference counter (counts rows since vSync)
reg [ 7:0] col;		// horizontal column
reg [ 4:0] rowscan;	// scan line within row
reg [ 4:0] colscan;	// pixel column number within cell
wire nxt_row;			// when to increment the row counter
wire nxt_col;			// when to increment the column counter
reg [ 5:0] bcnt;		// blink timing counter
wire blink;
reg  iblank;
reg [4:0] maxScanlinePlusOne;

wire nhp;				// next horizontal pixel
wire ld_shft = nxt_col & nhp;


// display and timing signals
reg [15:0] txtAddr;		// index into memory
reg [15:0] penAddr;
wire [15:0] screen_ram_out;		// character code
wire [23:0] txtBkColor;	// background color code
wire [23:0] txtFgColor;	// foreground color code
wire [5:0] txtZorder;
reg  [3:0] txtTcCode;	// transparent color code
wire [23:0] txtTcColor;
reg [3:0] tileCode1;
reg [3:0] tileCode2;
wire [23:0] tileColor1;
wire [23:0] tileColor2;
reg  bgt, bgtd;

wire [7:0] tdat_o;
wire [8:0] chdat_o;

wire [2:0] scanindex = rowscan[2:0];

//--------------------------------------------------------------------
// bus interfacing
// Address Decoding
// I/O range Dx
//--------------------------------------------------------------------
// Register the inputs
reg cs_rom, cs_reg, cs_text, cs_any;
reg [15:0] radr_i;
reg [7:0] rdat_i;
reg rwr_i;
always_ff @(posedge clk_i)
	cs_rom <= cs_i && cyc_i && stb_i && (adr_i[15:8] > 8'hDF);
always_ff @(posedge clk_i)
	cs_reg <= cs_i && cyc_i && stb_i && (adr_i[15:8] == 8'hDF);
always_ff @(posedge clk_i)
	cs_text <= cs_i && cyc_i && stb_i && (adr_i[15:8] < 8'hDF);
always_ff @(posedge clk_i)
	cs_any <= cs_i && cyc_i && stb_i;
always_ff @(posedge clk_i)
	rwr_i <= wr_i;
always_ff @(posedge clk_i)
	radr_i <= adr_i;
always_ff @(posedge clk_i)
	rdat_i <= dat_i;	

// Register outputs
always @(posedge clk_i)
	casez({cs_rom,cs_reg,cs_text})
	3'b1??:	dat_o <= chdat_o;
	3'b01?:	dat_o <= rego;
	3'b001:	dat_o <= tdat_o;
	default:	dat_o <= 8'h0;
	endcase

//always @(posedge clk_i)
//	if (cs_text) begin
//		$display("TC WRite: %h %h", adr_i, dat_i);
//		$stop;
//	end

// - there is a four cycle latency for reads, an ack is generated
//   after the synchronous RAM read
// - writes can be acknowledged right away.

ack_gen #(
	.READ_STAGES(5),
	.WRITE_STAGES(1),
	.REGISTER_OUTPUT(1)
)
uag1 (
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(cs_any),
	.we_i(cs_any & rwr_i),
	.o(ack_o),
	.rid_i(0),
	.wid_i(0),
	.rid_o(),
	.wid_o()
);

//--------------------------------------------------------------------
//--------------------------------------------------------------------
`ifdef USE_CLOCK_GATE
BUFHCE ucb1 (.I(dot_clk_i), .CE(controller_enable), .O(vclk));
`else
assign vclk = dot_clk_i;
`endif

//--------------------------------------------------------------------
// Video Memory
//--------------------------------------------------------------------
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Address Calculation:
//  - Simple: the row times the number of  cols plus the col plus the
//    base screen address
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [15:0] rowcol;
always_ff @(posedge vclk)
	txtAddr <= startAddress + rowcol + col;

// Register read-back memory
// Allows reading back of register values by shadowing them with ram

wire [5:0] rrm_adr = radr_i[5:0];
wire [7:0] rrm_o;

regReadbackMem #(.WID(8)) rrm0L
(
  .wclk(clk_i),
  .adr(rrm_adr),
  .wce(cs_reg),
  .we(rwr_i),
  .i(rdat_i[7:0]),
  .o(rrm_o[7:0])
);

wire [23:0] lfsr_o;
lfsr #(24) ulfsr1(rst_i, dot_clk_i, 1'b1, 1'b0, lfsr_o);
assign m_dat_o = lfsr_o;									

/*
wire pe_cs;
edge_det u1(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs_text), .pe(pe_cs), .ne(), .ee() );

reg [14:0] ctr;
always @(posedge clk_i)
	if (pe_cs) begin
		if (cti_i==3'b000)
			ctr <= adr_i[16:3];
		else
			ctr <= adr_i[16:3] + 12'd1;
		cnt <= 3'b000;
	end
	else if (cs_text && cnt[2:0]!=3'b100 && cti_i!=3'b000) begin
		ctr <= ctr + 2'd1;
		cnt <= cnt + 3'd1;
	end

reg [13:0] radr;
always @(posedge clk_i)
	radr <= pe_cs ? adr_i[16:3] : ctr;
*/
// text screen RAM
wire [13:0] bram_adr = radr_i[13:0];

`ifdef INTERNAL_RAMS
rfTextControllerRam screen_ram1
(
  .clka(clk_i),
  .ena(cs_text),
  .wea(rwr_i),
  .addra(radr_i[13:0]),
  .dina(rdat_i),
  .douta(tdat_o),
  .clkb(vclk),
  .enb(ld_shft|por),
  .web(por),
  .addrb(txtAddr[12:0]),
  .dinb(lfsr_o[15:0]),
  .doutb(screen_ram_out)
);

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Character bitmap ROM
// - room for 512 8x8 characters
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire [63:0] char_bmp;		// character ROM output
char_ram charRam0
(
	.clk_i(clk_i),
	.cs_i(cs_rom),
	.we_i(1'b0),
	.adr_i(radr_i[12:0]),
	.dat_i(rdat_i),
	.dat_o(chdat_o),
	.dot_clk_i(vclk),
	.ce_i(ld_shft),
	.char_code_i(screen_ram_out[7:0]),
	.maxscanline_i(maxScanlinePlusOne),
	.scanline_i(rowscan[4:0]),
	.bmp_o(char_bmp[8:0])
);
assign char_bmp[63:9] = 55'h0;
`else
reg [63:0] char_bmp;		// character ROM output
`endif

reg [63:0] txt_dati;
reg [31:0] bmp_ndx;
`ifdef INTERNAL_RAMS
`else
always_ff @(posedge vclk)
	bmp_ndx <= (maxScanlinePlusOne * txt_dati[15:0] + rowscan[4:0]) << tileWidth;
always_ff @(posedge vclk)
begin
	if (ld_shft) begin
		txt_cyc_o <= 1'b1;
		txt_stb_o <= 1'b1;
		txt_adr_o <= {txtAddr[13:0],3'b0};
		cbm_cyc_o <= 1'b1;
		cbm_stb_o <= 1'b1;
		cbm_adr_o <= {bmp_ndx[31:3],3'b0};
	end
	if (txt_ack_i) begin
		txt_cyc_o <= 1'b0;
		txt_stb_o <= 1'b0;
		txt_dati <= txt_dat_i;
	end
	if (cbm_ack_i) begin
		cbm_cyc_o <= 1'b0;
		cbm_stb_o <= 1'b0;
		case(tileWidth)
		2'd0:	char_bmp <= cbm_dat_i >> {bmp_ndx[2:0],3'b0};
		2'd1:	char_bmp <= cbm_dat_i >> {bmp_ndx[2:1],4'b0};
		2'd2: char_bmp <= cbm_dat_i >> {bmp_ndx[2],5'b0};
		2'd3:	char_bmp <= cbm_dat_i;
		endcase
	end
end
`endif

/*
syncRam4kx9 charRam0
(
  .clka(clk_i),    // input wire clka
  .ena(cs_rom),      // input wire ena
  .wea(1'b0),//rwr_i),      // input wire [0 : 0] wea
  .addra(bram_adr),  // input wire [11 : 0] addra
  .dina(rdat_i[8:0]),    // input wire [8 : 0] dina
  .douta(chdat_o),  // output wire [8 : 0] douta
  .clkb(vclk),    // input wire clkb
  .enb(ld_shft),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb({screen_ram_out[8:0],scanline[2:0]}),  // input wire [11 : 0] addrb
  .dinb(9'h0),    // input wire [8 : 0] dinb
  .doutb(char_bmp)  // output wire [8 : 0] doutb
);
*/

// pipeline delay - sync color with character bitmap output
reg [5:0] txtZorder1;

wire [3:0] txtBkCode1 = screen_ram_out[11: 8];
wire [3:0] txtFgCode1 = screen_ram_out[15:12];
rfColorROM ucr1(vclk, ld_shft, {1'b0,txtBkCode1}, txtBkColor);
rfColorROM ucr2(vclk, ld_shft, {1'b0,txtFgCode1}, txtFgColor);
rfColorROM ucr3(vclk, 1'b1, {1'b0,txtTcCode}, txtTcColor);
rfColorROM ucr4(vclk, 1'b1, {1'b0,bdrCode}, bdrColor);
rfColorROM ucr5(vclk, ld_shft, {1'b0,tileCode1}, tileColor1);
rfColorROM ucr6(vclk, ld_shft, {1'b0,tileCode2}, tileColor2);

always @(posedge vclk)
	if (ld_shft) txtZorder1 <= 6'h3F;

//--------------------------------------------------------------------
// Light Pen
//--------------------------------------------------------------------
wire lpe;
edge_det u1 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(lp_i), .pe(lpe), .ne(), .ee() );

always @(posedge clk_i)
	if (rst_i)
		penAddr <= 32'h0000_0000;
	else begin
		if (lpe)
			penAddr <= txtAddr;
	end


//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register read port
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
always @*
	if (cs_reg) begin
		case(radr_i[5:0])
		6'd56:	  rego <= penAddr[15:8];
		6'd57:	  rego <= penAddr[ 7:0];
		default:	rego <= rrm_o;
		endcase
	end
	else
		rego <= 64'h0000;


//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register write port
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk_i)
	if (rst_i) begin
	  por <= 1'b1;
	  mcm <= 1'b0;
	  controller_enable <= 1'b1;
    xscroll 		 <= 5'd0;
    yscroll 		 <= 5'd0;
    txtTcCode    <= 4'hE;
    bdrCode      <= 4'hE;
    startAddress <= 16'h0000;
    cursorStart  <= 5'd00;
    cursorEnd    <= 5'd31;
    cursorPos    <= 16'h0003;
    cursorType 	 <= 2'b00;
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
		// 48x29
		if (num==4'd1) begin
      windowTop    <= 12'd4058;//12'd16;
      windowLeft   <= 12'd3930;//12'd86;
      pixelWidth   <= 4'd1;		// 800 pixels
      pixelHeight  <= 4'd1;		// 600 pixels
      numCols      <= COLS;
      numRows      <= ROWS;
      maxRowScan  <= 5'd9;
      maxScanpix   <= 5'd6;
      rBlink       <= 3'b111;		// 01 = non display
      charOutDelay <= 8'd4;
		end
		else if (num==4'd2) begin
      windowTop    <= 12'd4032;//12'd16;
      windowLeft   <= 12'd3720;//12'd86;
      pixelWidth   <= 4'd0;        // 800 pixels
      pixelHeight  <= 4'd0;        // 600 pixels
      numCols      <= 40;
      numRows      <= 25;
      maxRowScan  <= 5'd7;
      maxScanpix   <= 5'd7;
      rBlink       <= 3'b111;        // 01 = non display
      charOutDelay <= 8'd6;
		end
	end
	else begin
		
		if (bcnt > 6'd10)
			por <= 1'b0;
		
		if (cs_reg & rwr_i) begin	// register write ?
			$display("TC Write: r%d=%h", rrm_adr, rdat_i);
			case(radr_i[5:0])
			6'd0:	numCols <= rdat_i;
			6'd1:	numRows <= rdat_i;
			6'd2:	charOutDelay <= rdat_i;
			6'd4:	windowLeft[11:8] <= rdat_i[3:0];
			6'd5:	windowLeft[7:0] <= rdat_i;
			6'd6:	windowTop[11:8] <= rdat_i[3:0];
			6'd7:	windowTop[7:0] <= rdat_i;
			6'd8:	maxRowScan <= rdat_i[4:0];
			6'd9:
				begin
						pixelHeight <= rdat_i[7:4];
						pixelWidth  <= rdat_i[3:0];	// horizontal pixel width
				end
			6'd11:	por <= rdat_i[0];
			6'd12:	controller_enable <= rdat_i[0];
			6'd13:	mcm <= rdat_i[0];
			6'd14:	yscroll <= rdat_i[4:0];
			6'd15:	xscroll <= rdat_i[4:0];
			6'd16:	txtTcCode <= rdat_i;
			6'd20:	bdrCode <= rdat_i;
			6'd24:	tileCode1 <= rdat_i;
			6'd28:	tileCode2 <= rdat_i;
			6'd32:	
				begin
						cursorEnd <= rdat_i[4:0];	// scan line sursor starts on
						rBlink      <= rdat_i[7:5];
				end
			6'd33:
					begin
						cursorStart <= rdat_i[4:0];	// scan line cursor ends on
						cursorType  <= rdat_i[7:6];
					end
			6'd34:	cursorPos[15:8] <= rdat_i;
			6'd36:	cursorPos[ 7:0] <= rdat_i;
			6'd40:	startAddress[15:8] <= rdat_i;
			6'd41:	startAddress[ 7:0] <= rdat_i;
			default: ;
			endcase
		end
	end


//--------------------------------------------------------------------
//--------------------------------------------------------------------

// "Box" cursor bitmap
reg [7:0] curout;
always @*
	case({cursorType,scanindex})
	// Box cursor
	5'b00_000:	curout = 8'b11111110;
	5'b00_001:	curout = 8'b10000010;
	5'b00_010:	curout = 8'b10000010;
	5'b00_011:	curout = 8'b10000010;
	5'b00_100:	curout = 8'b10000010;
	5'b00_101:	curout = 8'b10000010;
	5'b00_110:	curout = 8'b10010010;
	5'b00_111:	curout = 8'b11111110;
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
	.i(hsync_i),
	.pe(pe_hsync),
	.ne(),
	.ee()
);

edge_det edv1
(
	.rst(rst_i),
	.clk(vclk),
	.ce(1'b1),
	.i(vsync_i),
	.pe(pe_vsync),
	.ne(),
	.ee()
);

// Horizontal counter:
//
/*
HVCounter uhv1
(
	.rst(rst_i),
	.vclk(vclk),
	.pixcce(1'b1),
	.sync(hsync_i),
	.cnt_offs(windowLeft),
	.pixsz(pixelWidth),
	.maxpix(maxScanpix),
	.nxt_pix(nhp),
	.pos(col),
	.nxt_pos(nxt_col),
	.ctr(hctr)
);
*/

// Vertical counter:
//
/*
HVCounter uhv2
(
	.rst(rst_i),
	.vclk(vclk),
	.pixcce(pe_hsync),
	.sync(vsync_i),
	.cnt_offs(windowTop),
	.pixsz(pixelHeight),
	.maxpix(maxRowScan),
	.nxt_pix(),
	.pos(row),
	.nxt_pos(nxt_row),
	.ctr(scanline)
);
*/

// We generally don't care about the exact reset point, unless debugging in
// simulation. The counters will eventually cycle to a proper state. A little
// bit of logic / routing can be avoided by omitting the reset.
`ifdef SIM
wire sym_rst = rst_i;
`else
wire sym_rst = 1'b0;
`endif

// Raw scanline counter
vid_counter #(12) u_vctr (.rst(sym_rst), .clk(vclk), .ce(pe_hsync), .ld(pe_vsync), .d(windowTop), .q(scanline), .tc());
vid_counter #(12) u_hctr (.rst(sym_rst), .clk(vclk), .ce(1'b1), .ld(pe_hsync), .d(windowLeft), .q(hctr), .tc());

// Vertical pixel height counter, synchronized to scanline #0
reg [3:0] vpx;
wire nvp = vpx==pixelHeight;
always @(posedge vclk)
if (sym_rst)
	vpx <= 4'b0;
else begin
	if (pe_hsync) begin
		if (scanline==12'd0)
			vpx <= 4'b0;
		else if (nvp)
			vpx <= 4'd0;
		else
			vpx <= vpx + 4'd1;
	end
end

reg [3:0] hpx;
assign nhp = hpx==pixelWidth;
always @(posedge vclk)
if (sym_rst)
	hpx <= 4'b0;
else begin
	if (hctr==12'd0)
		hpx <= 4'b0;
	else if (nhp)
		hpx <= 4'd0;
	else
		hpx <= hpx + 4'd1;
end

// The scanline row within a character bitmap
always @(posedge vclk)
if (sym_rst)
	rowscan <= 5'd0;
else begin
	if (pe_hsync & nvp) begin
		if (scanline==12'd0)
			rowscan <= yscroll;
		else if (rowscan==maxRowScan)
			rowscan <= 5'd0;
		else
			rowscan <= rowscan + 5'd1;
	end
end

assign nxt_col = colscan==maxScanpix;
always @(posedge vclk)
if (sym_rst)
	colscan <= 5'd0;
else begin
	if (nhp) begin
		if (hctr==12'd0)
			colscan <= xscroll;
		else if (nxt_col)
			colscan <= 5'd0;
		else
			colscan <= colscan + 5'd1;
	end
end

// The screen row
always @(posedge vclk)
if (sym_rst)
	row <= 8'd0;
else begin
	if (pe_hsync & nvp) begin
		if (scanline==12'd0)
			row <= 8'd0;
		else if (rowscan==maxRowScan)
			row <= row + 8'd1;
	end
end

// The screen column
always @(posedge vclk)
if (sym_rst)
	col <= 8'd0;
else begin
	if (hctr==12'd0)
		col <= 8'd0;
	else if (nhp) begin
		if (nxt_col)
			col <= col + 8'd1;
	end
end

// More useful, the offset of the start of the text display on a line.
always @(posedge vclk)
if (sym_rst)
	rowcol <= 16'd0;
else begin
	if (pe_hsync & nvp) begin
		if (scanline==12'd0)
			rowcol <= 8'd0;
		else if (rowscan==maxRowScan)
			rowcol <= rowcol + numCols;
	end
end

// Takes 3 clock for scanline to become stable, but should be stable before any
// chars are displayed.
reg [13:0] rxmslp1;
always @(posedge vclk)
	maxScanlinePlusOne <= maxRowScan + 4'd1;
//always @(posedge vclk)
//	rxmslp1 <= row * maxScanlinePlusOne;
//always @(posedge vclk)
//	scanline <= scanline - rxmslp1;


// Blink counter
//
always @(posedge vclk)
if (sym_rst)
	bcnt <= 6'd0;
else begin
	if (pe_vsync)
		bcnt <= bcnt + 6'd1;
end

reg blink_en;
always @(posedge vclk)
	blink_en <= (cursorPos+3==txtAddr) && (rowscan[4:0] >= cursorStart) && (rowscan[4:0] <= cursorEnd);

VT151 ub2
(
	.e_n(!blink_en),
	.s(rBlink),
	.i0(1'b1), .i1(1'b0), .i2(bcnt[4]), .i3(bcnt[5]),
	.i4(1'b1), .i5(1'b0), .i6(bcnt[4]), .i7(bcnt[5]),
	.z(blink),
	.z_n()
);

always @(posedge vclk)
	if (ld_shft)
		bkColor32 <= {txtZorder1,2'b00,txtBkColor};
always @(posedge vclk)
	if (nhp)
		bkColor32d <= bkColor32;
always @(posedge vclk)
	if (ld_shft)
		fgColor32 <= {txtZorder1,2'b00,txtFgColor};
always @(posedge vclk)
	if (nhp)
		fgColor32d <= fgColor32;

always @(posedge vclk)
	if (ld_shft)
		bgt <= txtBkCode1==txtTcCode;
always @(posedge vclk)
	if (nhp)
		bgtd <= bgt;

// Convert character bitmap to pixels
reg [63:0] charout1;
always @(posedge vclk)
	charout1 <= blink ? (char_bmp ^ curout) : char_bmp;

// Convert parallel to serial
always_ff @(posedge vclk)
if (rst_i) begin
	pix <= 64'd0;
end
else begin
	if (nhp) begin
		if (ld_shft)
			pix <= charout1;
		else begin
			if (mcm)
				pix <= {2'b00,pix[63:2]};
			else
				pix <= {1'b0,pix[63:1]};
		end
	end
end

reg [1:0] pix1;
always_ff @(posedge vclk)
	if (nhp)	
    pix1 <= pix[1:0];

// Pipelining Effect:
// - character output is delayed by 2 or 3 character times relative to the video counters
//   depending on the resolution selected
// - this means we must adapt the blanking signal by shifting the blanking window
//   two or three character times.
wire bpix = hctr[2] ^ rowscan[4];// ^ blink;
always_ff @(posedge vclk)
	if (nhp)	
		iblank <= (row >= numRows) || (col >= numCols + charOutDelay) || (col < charOutDelay);
	

// Choose between input RGB and controller generated RGB
// Select between foreground and background colours.
// Note the ungated dot clock must be used here, or output from other
// controllers would not be visible if the clock were gated off.
always_ff @(posedge dot_clk_i)
	casez({controller_enable&xonoff_i,blank_i,iblank,border_i,bpix,mcm,pix1})
	8'b01??????:	zrgb_o <= 32'h00000000;
	8'b11??????:	zrgb_o <= 32'h00000000;
	8'b1001????:	zrgb_o <= bdrColor;
	//6'b10010?:	zrgb_o <= 32'hFFBF2020;
	//6'b10011?:	zrgb_o <= 32'hFFDFDFDF;
	8'b1000?0?0:	zrgb_o <= (zrgb_i[31:24] > bkColor32d[31:24]) ? zrgb_i : bkColor32d;
//	8'b1000?0?0:	zrgb_o <= bkColor32d;
	8'b1000?0?1:	zrgb_o <= fgColor32d; // ToDo: compare z-order
	8'b1000?100:	zrgb_o <= (zrgb_i[31:24] > bkColor32d[31:24]) ? zrgb_i : bkColor32d;
	8'b1000?101:	zrgb_o <= fgColor32d;
	8'b1000?110:	zrgb_o <= {8'hFF,tileColor1};
	8'b1000?111:	zrgb_o <= {8'hFF,tileColor2};
//	6'b1010?0:	zrgb_o <= bgtd ? zrgb_i : bkColor32d;
//	6'b1010?1:	zrgb_o <= fgColor32d;
	default:	zrgb_o <= zrgb_i;
	endcase

endmodule

