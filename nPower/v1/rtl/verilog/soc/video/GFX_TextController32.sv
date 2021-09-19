// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	GFX_TextController32.sv
//		text controller, 32-bit bus interface
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
//  The controller expects a 128kB memory region to be reserved.
//
//  Memory Map:
//  00000-0FFFF   display ram
//  17F00-17FFF   controller registers
//  18000-1FFFF   character bitmap ram
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
//  48-52               nnnnn  yscroll
//  56-60               nnnnn  xscroll
// 02h
//	20- 0   cccccccc cccccccc  color code for transparent background RGB 7,7,7
//  63-32   cccc...cccc        border color ZRGB 8,8,8,8
// 03h
//   4- 0               eeeee	 cursor end
//   7- 5                 bbb  blink control
//                             BP: 00=no blink
//                             BP: 01=no display
//                             BP: 10=1/16 field rate blink
//                             BP: 11=1/32 field rate blink
//  12- 8               sssss  cursor start
//  15-14									 tt	 cursor image type (box, underline, sidebar, asterisk
//  47-32   aaaaaaaa aaaaaaaa	 cursor position
// 04h
//  15- 0   aaaaaaaa aaaaaaaa  start address (index into display memory)
// 05h
//  15-0    aaaaaaaa aaaaaaaa  font address
// 07h
//	150 - - aaaaaaaa aaaaaaaa  light pen position
//--------------------------------------------------------------------
//
// ============================================================================

//`define USE_CLOCK_GATE

module GFX_TextController32(
	rst_i, clk_i, cs_i,
	cti_i, cyc_i, stb_i, ack_o, wr_i, sel_i, adr_i, dat_i, dat_o,
	lp_i,
	dot_clk_i, hsync_i, vsync_i, blank_i, border_i, zrgb_i, zrgb_o, xonoff_i
);
parameter num = 4'd1;
parameter COLS = 8'd64;
parameter ROWS = 8'd33;

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
input  [ 3:0] sel_i;	// byte lane select
input  [16:0] adr_i;	// address
input  [31:0] dat_i;	// data input
output reg [31:0] dat_o;	// data output

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

integer n;
reg controller_enable;
reg [31:0] bkColor32, bkColor32d;	// background color
reg [31:0] fgColor32, fgColor32d;	// foreground color

wire pix;				  // pixel value from character generator 1=on,0=off

reg por;
wire vclk;
reg [63:0] rego;
reg [5:0] yscroll;
reg [5:0] xscroll;
reg [11:0] windowTop;
reg [11:0] windowLeft;
reg [ 7:0] numCols;
reg [ 7:0] numRows;
reg [ 7:0] charOutDelay;
reg [ 1:0] mode;
reg [ 5:0] maxRowScan;
reg [ 5:0] maxScanpix;
reg [ 5:0] cursorStart, cursorEnd;
reg [15:0] cursorPos;
reg [1:0] cursorType;
reg [15:0] fontAddress;
reg [15:0] startAddress;
reg [ 2:0] rBlink;
reg [31:0] bdrColor;		// Border color
reg [ 3:0] pixelWidth;	// horizontal pixel width in clock cycles
reg [ 3:0] pixelHeight;	// vertical pixel height in scan lines
reg ecm;                // extended color mode

wire [11:0] hctr;		// horizontal reference counter (counts clocks since hSync)
wire [11:0] scanline;	// scan line
reg [ 7:0] row;		// vertical reference counter (counts rows since vSync)
reg [ 7:0] col;		// horizontal column
reg [ 5:0] rowscan;	// scan line within row
reg [ 5:0] colscan;	// pixel column number within cell
wire nxt_row;			// when to increment the row counter
wire nxt_col;			// when to increment the column counter
reg [ 5:0] bcnt;		// blink timing counter
wire blink;
reg  iblank;
reg [5:0] maxScanlinePlusOne;

wire nhp;				// next horizontal pixel
wire ld_shft = nxt_col & nhp;


// display and timing signals
reg [15:0] txtAddr;		// index into memory
reg [15:0] penAddr;
wire [31:0] screen_ram_out;		// character code
wire [63:0] char_bmp;		// character ROM output
wire [17:0] txtBkColor;	// background color code
wire [17:0] txtFgColor;	// foreground color code
wire [3:0] txtZorder;
reg  [17:0] txtTcCode;	// transparent color code
reg  bgt, bgtd;

wire [31:0] tdat_o;

wire [2:0] scanindex = rowscan[2:0];

//--------------------------------------------------------------------
// bus interfacing
// Address Decoding
// I/O range Dx
//--------------------------------------------------------------------
// Register the inputs
reg cs_rom, cs_reg, cs_text, cs_any;
reg [16:0] radr_i;
reg [31:0] rdat_i;
reg rwr_i;
reg [3:0] rsel_i;
reg [3:0] wrs_i;
always @(posedge clk_i)
	cs_rom <= cs_i && cyc_i && stb_i && (adr_i[16:8] >  9'h17F);
always @(posedge clk_i)
	cs_reg <= cs_i && cyc_i && stb_i && (adr_i[16:8] == 9'h17F);
always @(posedge clk_i)
	cs_text <= cs_i && cyc_i && stb_i && (adr_i[16:8] < 9'h100);
always @(posedge clk_i)
	cs_any <= cs_i && cyc_i && stb_i;
always @(posedge clk_i)
	wrs_i <= {8{wr_i}} & sel_i;
always @(posedge clk_i)
	rwr_i <= wr_i;
always @(posedge clk_i)
	rsel_i <= sel_i;
always @(posedge clk_i)
	radr_i[16:2] <= adr_i[16:2];
// Recreate LSB's for charram
always @(posedge clk_i)
begin
  radr_i[0] <= sel_i[1]|sel_i[3];
  radr_i[1] <= |sel_i[3:2];
end
always @(posedge clk_i)
	rdat_i <= dat_i;	

// Register outputs
// The output is "sticky" to give more hold time.
always @(posedge clk_i)
	casez({cs_rom,cs_reg,cs_text})
	3'b01?:	dat_o <= rego;
	3'b001:	dat_o <= tdat_o;
	default:	dat_o <= dat_o;
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
	.o(ack_o)
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
always @(posedge vclk)
  if (ld_shft)
	  txtAddr <= startAddress + rowcol + col;

// Register read-back memory
// Allows reading back of register values by shadowing them with ram

wire [4:0] rrm_adr = radr_i[6:2];
wire [31:0] rrm_o;

regReadbackMem #(.WID(8)) rrm0L
(
  .wclk(clk_i),
  .adr(rrm_adr),
  .wce(cs_reg),
  .we(rwr_i & rsel_i[0]),
  .i(rdat_i[7:0]),
  .o(rrm_o[7:0])
);

regReadbackMem #(.WID(8)) rrm0H
(
  .wclk(clk_i),
  .adr(rrm_adr),
  .wce(cs_reg),
  .we(rwr_i & rsel_i[1]),
  .i(rdat_i[15:8]),
  .o(rrm_o[15:8])
);

regReadbackMem #(.WID(8)) rrm1L
(
  .wclk(clk_i),
  .adr(rrm_adr),
  .wce(cs_reg),
  .we(rwr_i & rsel_i[2]),
  .i(rdat_i[23:16]),
  .o(rrm_o[23:16])
);

regReadbackMem #(.WID(8)) rrm1H
(
  .wclk(clk_i),
  .adr(rrm_adr),
  .wce(cs_reg),
  .we(rwr_i & rsel_i[3]),
  .i(rdat_i[31:24]),
  .o(rrm_o[31:24])
);


wire [25:0] lfsr1_o;
lfsr #(26) ulfsr1(rst_i, dot_clk_i, 1'b1, 1'b0, lfsr1_o);
wire [31:0] lfsr_o = {2'h2,
												lfsr1_o[25:23],lfsr1_o[22:20],lfsr1_o[19:17],
												lfsr1_o[16:14],lfsr1_o[13:11],lfsr1_o[10:8],
												4'h00,lfsr1_o[7:0]
										};

/* The following code was for WB burst access to the text memory. About the
   only time burst access is used is for screen clear. This is just code bloat.
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
wire [15:0] bram_adr = radr_i[15:0];
syncRam16kx32 screen_ram1
(
  .clka(clk_i),
  .ena(cs_text),
  .wea(wrs_i),
  .addra(bram_adr[15:2]),
  .dina(rdat_i),
  .douta(tdat_o),
  .clkb(vclk),
  .enb(ld_shft|por),
  .web({8{por}}),
  .addrb(txtAddr[12:0]),
  .dinb(lfsr_o),
  .doutb(screen_ram_out)
);

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Character bitmap ROM/RAM
// - 32kB
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
char_ram charRam0
(
	.clk_i(clk_i),
	.cs_i(cs_rom),
	.we_i(1'b0),
	.adr_i(bram_adr[14:0]),
	.dat_i(rdat_i >> {bram_adr[2:0],3'b0}),
	.dot_clk_i(vclk),
	.ce_i(ld_shft),
	.fontAddress_i(fontAddress),
 	.char_code_i({8'h00,screen_ram_out[11:0]}),
	.maxScanpix_i(maxScanpix),
	.maxscanline_i(maxScanlinePlusOne),
	.scanline_i(rowscan),
	.bmp_o(char_bmp)
);

// pipeline delay - sync color with character bitmap output
wire [8:0] txtBkCode1;
wire [8:0] txtFgCode1;
wire [1:0] txtZorder1;

delay #(.WID(9),.DEP(3)) udlyb (.clk(vclk), .ce(ld_shft), .i(screen_ram_out[20:12]), .o(txtBkCode1));
delay #(.WID(9),.DEP(3)) udlyf (.clk(vclk), .ce(ld_shft), .i(screen_ram_out[29:21]), .o(txtFgCode1));
delay #(.WID(2),.DEP(3)) udlyz (.clk(vclk), .ce(ld_shft), .i(screen_ram_out[31:30]), .o(txtZorder1));


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
		case(rrm_adr)
		4'd14:		  rego <= penAddr;
		default:	rego <= rrm_o;
		endcase
	end
	else
		rego <= 32'h0000;


//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register write port
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk_i)
	if (rst_i) begin
	  por <= 1'b1;
	  controller_enable <= 1'b1;
    xscroll 		 <= 6'd0;
    yscroll 		 <= 6'd0;
    txtTcCode    <= 16'h1ff;
    bdrColor     <= 32'hFFBF2020;
    startAddress <= 16'h0000;
    fontAddress  <= 16'h0000;
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
      windowLeft   <= 12'd3964;//12'd3930;//12'd86;
      pixelWidth   <= 4'd0;		// 1280 pixels
      pixelHeight  <= 4'd0;		// 720 pixels
      numCols      <= COLS;
      numRows      <= ROWS;
      maxRowScan  <= 6'd17;
      maxScanpix   <= 6'd11;
      rBlink       <= 3'b111;		// 01 = non display
      charOutDelay <= 8'd7;
		end
		else if (num==4'd2) begin
      windowTop    <= 12'd4032;//12'd16;
      windowLeft   <= 12'd3720;//12'd86;
      pixelWidth   <= 4'd0;        // 800 pixels
      pixelHeight  <= 4'd0;        // 600 pixels
      numCols      <= 40;
      numRows      <= 25;
      maxRowScan  <= 6'd7;
      maxScanpix   <= 6'd7;
      rBlink       <= 3'b111;        // 01 = non display
      charOutDelay <= 8'd6;
		end
	end
	else begin
		
		if (bcnt > 6'd10)
			por <= 1'b0;
		
		if (cs_reg & rwr_i) begin	// register write ?
			$display("TC Write: r%d=%h", rrm_adr, rdat_i);
			case(rrm_adr)
			4'd0:	begin
					if (rsel_i[0]) numCols    <= rdat_i[7:0];
					if (rsel_i[1]) numRows    <= rdat_i[15:8];
					if (rsel_i[2]) charOutDelay <= rdat_i[23:16];
					end
			4'd1: begin
					if (rsel_i[0]) windowLeft[7:0] <= rdat_i[7:0];
					if (rsel_i[1]) windowLeft[11:8] <= rdat_i[11:8];
					if (rsel_i[2]) windowTop[7:0]  <= rdat_i[23:16];
					if (rsel_i[3]) windowTop[11:8]  <= rdat_i[27:24];
					end
			4'd2:
				begin
					if (rsel_i[0]) maxRowScan <= rdat_i[5:0];
					if (rsel_i[1]) begin
						pixelHeight <= rdat_i[15:12];
						pixelWidth  <= rdat_i[11:8];	// horizontal pixel width
					end
					if (rsel_i[2]) maxScanpix <= rdat_i[21:16];
					if (rsel_i[3]) por <= rdat_i[24];
					end
			4'd3:
				begin
					if (rsel_i[0]) controller_enable <= rdat_i[0];
					if (rsel_i[2]) yscroll <= rdat_i[21:16];
					if (rsel_i[3]) xscroll <= rdat_i[29:24];
				end
			4'd4:	// Color Control
				begin
					if (rsel_i[0]) txtTcCode[7:0] <= rdat_i[7:0];
					if (rsel_i[1]) txtTcCode[15:8] <= rdat_i[15:8];
					if (rsel_i[2]) txtTcCode[17:16] <= rdat_i[17:16];
				end
			4'd5:
				begin
					if (rsel_i[0]) bdrColor[7:0] <= dat_i[7:0];
					if (rsel_i[1]) bdrColor[15:8] <= dat_i[15:8];
					if (rsel_i[2]) bdrColor[23:16] <= dat_i[23:16];
					if (rsel_i[3]) bdrColor[31:24] <= dat_i[31:24];
				end
			4'd6:	// Cursor Control
				begin
					if (rsel_i[0]) begin
						cursorEnd <= rdat_i[4:0];	// scan line sursor starts on
						rBlink      <= rdat_i[7:5];
					end
					if (rsel_i[1]) begin
						cursorStart <= rdat_i[12:8];	// scan line cursor ends on
						cursorType  <= rdat_i[15:14];
					end
				end
			4'd7:
				begin
					if (rsel_i[0]) cursorPos[7:0] <= rdat_i[7:0];
					if (rsel_i[1]) cursorPos[15:8] <= rdat_i[15:8];
				end
			4'd8:	// Page flipping / scrolling
				begin
					if (rsel_i[0]) startAddress[7:0] <= rdat_i[7:0];
					if (rsel_i[1]) startAddress[15:8] <= rdat_i[15:8];
				end
		  4'd10:
		    begin
		      if (rsel_i[0]) fontAddress[7:0] <= rdat_i[7:0];
		      if (rsel_i[1]) fontAddress[15:8] <= rdat_i[15:8];
		    end
			default: ;
			endcase
		end
	end


//--------------------------------------------------------------------
//--------------------------------------------------------------------

// "Box" cursor bitmap
(* ram_style="block" *)
reg [31:0] curram [0:511];
reg [31:0] curout, curout1;
initial begin
	// Box cursor
  curram[0] = 8'b11111110;
  curram[1] = 8'b10000010;
  curram[2] = 8'b10000010;
  curram[3] = 8'b10000010;
  curram[4] = 8'b10000010;
  curram[5] = 8'b10000010;
  curram[6] = 8'b10010010;
  curram[7] = 8'b11111110;
	// vertical bar cursor
  curram[32] = 8'b11000000;
  curram[33] = 8'b10000000;
  curram[34] = 8'b10000000;
  curram[35] = 8'b10000000;
  curram[36] = 8'b10000000;
  curram[37] = 8'b10000000;
  curram[38] = 8'b10000000;
  curram[39] = 8'b11000000;
	// underline cursor
  curram[64] = 8'b00000000;
  curram[65] = 8'b00000000;
  curram[66] = 8'b00000000;
  curram[67] = 8'b00000000;
  curram[68] = 8'b00000000;
  curram[69] = 8'b00000000;
  curram[70] = 8'b00000000;
  curram[71] = 8'b11111111;
	// Asterisk
  curram[96] = 8'b00000000;
  curram[97] = 8'b00000000;
  curram[98] = 8'b00100100;
  curram[99] = 8'b00011000;
  curram[100] = 8'b01111110;
  curram[101] = 8'b00011000;
  curram[102] = 8'b00100100;
  curram[103] = 8'b00000000;
end
always @(posedge vclk)
  if (ld_shft)
	  curout1 <= curram[{cursorType,rowscan}];
always @(posedge vclk)
  curout <= curout1;

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
	rowscan <= 6'd0;
else begin
	if (pe_hsync & nvp) begin
		if (scanline==12'd0)
			rowscan <= yscroll;
		else if (rowscan==maxRowScan)
			rowscan <= 6'd0;
		else
			rowscan <= rowscan + 1'd1;
	end
end

assign nxt_col = colscan==maxScanpix;
always @(posedge vclk)
if (sym_rst)
	colscan <= 6'd0;
else begin
	if (nhp) begin
		if (hctr==12'd0)
			colscan <= xscroll;
		else if (nxt_col)
			colscan <= 6'd0;
		else
			colscan <= colscan + 1'd1;
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
	maxScanlinePlusOne <= maxRowScan + 1'd1;
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
	blink_en <= (cursorPos+3==txtAddr) && (rowscan >= cursorStart) && (rowscan <= cursorEnd);

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
    bkColor32 <= {txtZorder1,6'b00,txtBkCode1[8:6],5'b0,txtBkCode1[5:3],5'b0,txtBkCode1[2:0],5'b0};
always @(posedge vclk)
	if (nhp)
		bkColor32d <= bkColor32;

always @(posedge vclk)
  if (ld_shft)
    fgColor32 <= {txtZorder1,6'b00,txtFgCode1[8:6],5'b0,txtFgCode1[5:3],5'b0,txtFgCode1[2:0],5'b0};
always @(posedge vclk)
	if (nhp)
		fgColor32d <= fgColor32;

always @(posedge vclk)
	if (ld_shft)
		bgt <= txtBkCode1==txtTcCode;
always @(posedge vclk)
	if (nhp)
		bgtd <= bgt;

reg [63:0] charout1;
always @(posedge vclk)
	charout1 <= blink ? (char_bmp ^ curout) : char_bmp;

// Convert parallel to serial
ParallelToSerial ups1
(
	.rst(rst_i),
	.clk(vclk),
	.ce(nhp),
	.ld(ld_shft),
	.a(maxScanpix[5:3]),
	.qin(1'b0),
	.d(charout1),
	.qh(pix)
);

// Pipelining Effect:
// - character output is delayed by 2 or 3 character times relative to the video counters
//   depending on the resolution selected
// - this means we must adapt the blanking signal by shifting the blanking window
//   two or three character times.
always @(posedge vclk)
	if (nhp)	
		iblank <= (row >= numRows) || (col >= numCols + charOutDelay) || (col < charOutDelay);
	
wire bpix = hctr[2] ^ rowscan[4];// ^ blink;

// Choose between input RGB and controller generated RGB
// Select between foreground and background colours.
// Note the ungated dot clock must be used here, or output from other
// controllers would not be visible if the clock were gated off.
always @(posedge dot_clk_i)
	casez({controller_enable&xonoff_i,blank_i,iblank,border_i,bpix,pix})
	6'b?1????:	zrgb_o <= 32'h00000000;
	6'b1001??:	zrgb_o <= bdrColor;
	//6'b10010?:	zrgb_o <= 32'hFFBF2020;
	//6'b10011?:	zrgb_o <= 32'hFFDFDFDF;
	6'b1000?0:	zrgb_o <= ((zrgb_i[31:24] <= bkColor32d[31:24]) || bgtd) ? zrgb_i : bkColor32d;
	6'b1000?1:	zrgb_o <= fgColor32d; // ToDo: compare z-order
//	6'b1010?0:	zrgb_o <= bgtd ? zrgb_i : bkColor32d;
//	6'b1010?1:	zrgb_o <= fgColor32d;
	default:	zrgb_o <= zrgb_i;
	endcase

endmodule

