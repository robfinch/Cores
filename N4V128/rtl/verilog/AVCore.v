// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// AVCore.v
// - audio / video controller
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

`define A		31:24
`define R		23:16
`define G		15:8
`define B		7:0

`define BLACK	32'h00000000
`define WHITE	32'h00FFFFFF


module AVCore(
	rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o,
	cs_i, cs_ram_i, irq_o,
	acyc_o, astb_o, aack_i, awe_o, asel_o, aadr_o, adat_i, adat_o,
	clk, hSync, vSync, blank_o, rgb,
	aud0_out, aud1_out, aud2_out, aud3_out, aud_in
);
parameter pAckStyle = 1'b0;

// Wishbone slave port
input rst_i;
input clk_i;
input cyc_i;
input stb_i;
output reg ack_o;
input we_i;
input [3:0] sel_i;
input [23:0] adr_i;
input [31:0] dat_i;
output [31:0] dat_o;

input cs_i;							// circuit select
input cs_ram_i;
output irq_o;

output reg acyc_o;
output reg astb_o;
input aack_i;
output reg awe_o;
output reg [15:0] asel_o;
output reg [31:0] aadr_o;
input [127:0] adat_i;
output reg [127:0] adat_o;

// Video port
input clk;
output hSync;
output vSync;
output reg blank_o;
output reg [23:0] rgb;

output reg [15:0] aud0_out;
output reg [15:0] aud1_out;
output reg [15:0] aud2_out;
output reg [15:0] aud3_out;
input [15:0] aud_in;

// Sync Generator defaults: 800x600 60Hz
parameter phSyncOn  = 40;		//   40 front porch
parameter phSyncOff = 168;		//  128 sync
parameter phBlankOff = 252;	//256	//   88 back porch
//parameter phBorderOff = 336;	//   80 border
parameter phBorderOff = 256;	//   80 border
//parameter phBorderOn = 976;		//  640 display
parameter phBorderOn = 1056;		//  640 display
parameter phBlankOn = 1052;		//   80 border
parameter phTotal = 1056;		// 1056 total clocks
parameter pvSyncOn  = 1;		//    1 front porch
parameter pvSyncOff = 5;		//    4 vertical sync
parameter pvBlankOff = 28;		//   23 back porch
parameter pvBorderOff = 28;		//   44 border	0
//parameter pvBorderOff = 72;		//   44 border	0
parameter pvBorderOn = 628;		//  512 display
//parameter pvBorderOn = 584;		//  512 display
parameter pvBlankOn = 628;  	//   44 border	0
parameter pvTotal = 628;		//  628 total scan lines

wire eol;
wire eof;
wire border;
wire blank, vblank;
wire vbl_int;
reg [9:0] vbl_reg;
reg sgLock = 1'b0;
reg [11:0] hTotal = phTotal;
reg [11:0] vTotal = pvTotal;
reg [11:0] hSyncOn = phSyncOn, hSyncOff = phSyncOff;
reg [11:0] vSyncOn = pvSyncOn, vSyncOff = pvSyncOff;
reg [11:0] hBlankOn = phBlankOn, hBlankOff = phBlankOff;
reg [11:0] vBlankOn = pvBlankOn, vBlankOff = pvBlankOff;
reg [11:0] hBorderOn = phBorderOn, hBorderOff = phBorderOff;
reg [11:0] vBorderOn = pvBorderOn, vBorderOff = pvBorderOff;

// ctrl
// -b--- rrrr ---- cccc
//  |      |         +-- grpahics command
//  |      +------------ raster op
// +-------------------- busy indicator
reg [15:0] ctrl;
reg [1:0] lowres = 2'b01;
reg [19:0] TargetBase = 20'h00000;		// base address of bitmap
reg [15:0] TargetWidth = 16'd400;
reg [15:0] TargetHeight = 16'd300;
reg [19:0] charBmpBase = 20'h5C000;	// base address of character bitmaps
reg [11:0] hstart = 12'hEFF;		// -261
reg [11:0] vstart = 12'hFE6;		// -41
reg [11:0] hpos;
reg [11:0] vpos;
wire [11:0] vctr;
wire [11:0] hctr;
reg [4:0] fpos;
reg [15:0] borderColor;
wire [31:0] rgb_i;					// internal rgb output from ram

reg [8:0] linendx;
reg [127:0] linebuf [0:511];

// Cursor related registers
reg [31:0] collision;
reg cursor;
reg [31:0] cursorEnable;
reg [31:0] cursorActive;
reg [11:0] cursor_pv [0:31];
reg [11:0] cursor_ph [0:31];
reg [3:0] cursor_pz [0:31];
reg [31:0] cursor_color [0:63];
reg [31:0] cursor_on;
reg [31:0] cursor_on_d1;
reg [31:0] cursor_on_d2;
reg [31:0] cursor_on_d3;
reg [19:0] cursorAddr [0:31];
reg [19:0] cursorWaddr [0:31];
reg [15:0] cursorMcnt [0:31];
reg [15:0] cursorWcnt [0:31];
reg [63:0] cursorBmp [0:31];
reg [15:0] cursorColor [0:31];
reg [31:0] cursorLink1;
reg [31:0] cursorLink2;
reg [5:0] cursorColorNdx [0:31];
reg [9:0] cursor_szv [0:31];
reg [5:0] cursor_szh [0:31];


VGASyncGen usg1
(
	.rst(rst_i),
	.clk(clk),
	.eol(eol),
	.eof(eof),
	.hSync(hSync),
	.vSync(vSync),
	.hCtr(hctr),
	.vCtr(vctr),
    .blank(blank),
    .vblank(vblank),
    .vbl_int(vbl_int),
    .border(border),
    .hTotal_i(hTotal),
    .vTotal_i(vTotal),
    .hSyncOn_i(hSyncOn),
    .hSyncOff_i(hSyncOff),
    .vSyncOn_i(vSyncOn),
    .vSyncOff_i(vSyncOff),
    .hBlankOn_i(hBlankOn),
    .hBlankOff_i(hBlankOff),
    .vBlankOn_i(vBlankOn),
    .vBlankOff_i(vBlankOff),
    .hBorderOn_i(hBorderOn),
    .hBorderOff_i(hBorderOff),
    .vBorderOn_i(vBorderOn),
    .vBorderOff_i(vBorderOff)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// RGB output display side
// clk clock domain
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// widen vertical blank interrupt pulse
always @(posedge clk)
	if (vbl_int)
		vbl_reg <= 10'h3FF;
	else
		vbl_reg <= {vbl_reg[8:0],1'b0};

always @(posedge clk)
	if (eol & eof) begin
		fpos <= fpos + 5'd1;
		flashcnt <= flashcnt + 6'd1;
	end

// Compute display ram index
reg [5:0] rstate;
reg [3:0] burst_cnt;
reg [5:0] bcnt;
reg noMoreSpritesActive;
parameter RS_IDLE = 6'd0;

// Register hctr onto the clk_i domain
always @(posedge clk_i)
	hctrr <= hctr;

always @(posedge clk_i)
begin
	case(rstate)
	RS_IDLE:
		begin
			linendx <= 9'd0;
			bcnt <= 5'd0;
			sprno <= 5'd0;
			// Wait for beginning of line
			if (hctrr > 12'd1 && hctrr < 12'd30)
				rstate <= SPRITE_FETCH;
			else if (hctrr < hTotal - 12'd80)
				rstate <= RS_OTHER;
		end
	SPRITE_FETCH:
		if (!acyc_o) begin
			acyc_o <= `HIGH;
			astb_o <= `HIGH;
			awe_o <= `LOW;
			asel_o <= 16'hFFFF;
			aadr_o <= cursorWaddr[sprno];
		end
		else if (aack_i) begin
			acyc_o <= `LOW;
			astb_o <= `LOW;
			cursorBmp[sprno] <= adat_i;
			noMoreSpritesActive <= `TRUE;
			for (n = 31; n >= 0; n = n - 1)
				if (n >= sprno + 1)
				if (cursorActive[n]) begin
					sprno <= n;
					noMoreSpritesActive <= `FALSE;
				end
			// If last sprite data fetched or timing budget exceeded.
			if (sprno == 5'd31 || noMoreSpritesActive || (hctrr > hBlankOff - 12'd80)) begin
				rstate <= LINE_FETCH1;
			end
		end
	LINE_FETCH1:
		begin
			aadr_o <= TargetBase + {(vctrr - vstart) * {TargetWidth[15:6],6'b00},2'b00};
			rstate <= LINE_FETCH2;
		end
	LINE_FETCH2:
		if (!acyc_o) begin
			acyc_o <= `HIGH;
			astb_o <= `HIGH;
			awe_o <= `LOW;
			asel_o <= 16'hFFFF;
			burst_cnt <= 4'd0;
		end
		else if (aack_i) begin
			aadr_o <= aadro + 32'd16;
			linebuf[linendx] <= adat_i;
			linendx <= linendx + 9'd1;
			burst_cnt <= burst_cnt + 4'd1;
			if (burst_cnt==4'd15) begin
				acyc_o <= `LOW;
				astb_o <= `LOW;
				rstate <= RS_OTHER;
			end
		end
	RS_OTHER:
		begin
			// Audio takes precedence to avoid audio distortion.
			// Fortunately audio DMA is fast and infrequent.
			if (|aud0_req) begin
			    acyc_o <= `HIGH;
			    astb_o <= `HIGH;
			    awe_o <= `LOW;
			    asel_o <= 16'hFFFF;
			    aadr_o <= aud0_wadr;
				aud0_wadr <= aud0_wadr + aud0_req;
				aud0_req <= 6'd0;
				if (aud0_wadr + aud0_req >= aud0_adr + aud0_length) begin
					aud0_wadr <= aud0_adr + (aud0_wadr + aud0_req - (aud0_adr + aud0_length));
					irq_status[8] <= 1'b1;
				end
				if (aud0_wadr < ((aud0_adr + aud0_length) >> 1) &&
					(aud0_wadr + aud0_req >= ((aud0_adr + aud0_length) >> 1)))
					irq_status[4] <= 1'b1;
				state <= ST_AUD0;
			end
			else if (|aud1_req)	begin
			    acyc_o <= `HIGH;
			    astb_o <= `HIGH;
			    awe_o <= `LOW;
			    asel_o <= 16'hFFFF;
				aadr_o <= aud1_wadr;
				aud1_wadr <= aud1_wadr + aud1_req;
				aud1_req <= 6'd0;
				if (aud1_wadr + aud1_req >= aud1_adr + aud1_length) begin
					aud1_wadr <= aud1_adr + (aud1_wadr + aud1_req - (aud1_adr + aud1_length));
					irq_status[9] <= 1'b1;
				end
				if (aud1_wadr < ((aud1_adr + aud1_length) >> 1) &&
					(aud1_wadr + aud1_req >= ((aud1_adr + aud1_length) >> 1)))
					irq_status[5] <= 1'b1;
				state <= ST_AUD1;
			end
			else if (|aud2_req) begin
			    acyc_o <= `HIGH;
			    astb_o <= `HIGH;
			    awe_o <= `LOW;
			    asel_o <= 16'hFFFF;
				aadr_o <= aud2_wadr;
				aud2_wadr <= aud2_wadr + aud2_req;
				aud2_req <= 6'd0;
				if (aud2_wadr + aud2_req >= aud2_adr + aud2_length) begin
					aud2_wadr <= aud2_adr + (aud2_wadr + aud2_req - (aud2_adr + aud2_length));
					irq_status[10] <= 1'b1;
				end
				if (aud2_wadr < ((aud2_adr + aud2_length) >> 1) &&
					(aud2_wadr + aud2_req >= ((aud2_adr + aud2_length) >> 1)))
					irq_status[6] <= 1'b1;
				state <= ST_AUD2;
			end
			else if (|aud3_req)	begin
			    acyc_o <= `HIGH;
			    astb_o <= `HIGH;
			    awe_o <= `LOW;
			    asel_o <= 16'hFFFF;
				aadr_o <= aud3_wadr;
				aud3_wadr <= aud3_wadr + aud3_req;
				aud3_req <= 6'd0;
				if (aud3_wadr + aud3_req >= aud3_adr + aud3_length) begin
					aud3_wadr <= aud3_adr + (aud3_wadr + aud3_req - (aud3_adr + aud3_length));
					irq_status[11] <= 1'b1;
				end
				if (aud3_wadr < ((aud3_adr + aud3_length) >> 1) &&
					(aud3_wadr + aud3_req >= ((aud3_adr + aud3_length) >> 1)))
					irq_status[7] <= 1'b1;
				state <= ST_AUD3;
			end
			else if (|audi_req) begin
			    acyc_o <= `HIGH;
			    astb_o <= `HIGH;
			    awe_o <= `HIGH;
			    case(audi_wadr[2:0])
			    3'd0:	asel_o <= 16'h0003;
			    3'd1;	asel_o <= 16'h000C;
			    3'd2:	asel_o <= 16'h0030;
			    3'd3:	asel_o <= 16'h00C0;
			    3'd4:	asel_o <= 16'h0300;
			    3'd5:	asel_o <= 16'h0C00;
			    3'd6:	asel_o <= 16'h3000;
			    3'd7:	asel-o <= 16'hC000;
				endcase
				aadr_o <= audi_wadr;
				ram_data_i <= audi_dat;
				audi_wadr <= audi_wadr + audi_req;
				audi_req <= 6'd0;
				if (audi_wadr + audi_req >= audi_adr + audi_length) begin
					audi_wadr <= audi_adr + (audi_wadr + audi_req - (audi_adr + audi_length));
					irq_status[12] <= 1'b1;
				end
				if (audi_wadr < ((audi_adr + audi_length) >> 1) &&
					(audi_wadr + audi_req >= ((audi_adr + audi_length) >> 1)))
					irq_status[3] <= 1'b1;
				state <= ST_AUDI;
`ifdef AUD_PLOT
				if (aud_ctrl[7])
					state <= ST_AUD_PLOT;
`endif
			end
			else begin
				if (bcnt < 5'd22)
					rstate <= LINE_FETCH1;
				else
					rstate <= RS_IDLE;
			end
		end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Audio DMA states
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

	ST_AUD0:
		if (aack_i) begin
			acyc_o <= `LOW;
			astb_o <= `LOW;
			asel_o <= 16'h0000;
			aud0_dat <= adat_i;
			state <= bcnt < 5'd22 ? LINE_FETCH2 : RS_IDLE;
		end

	ST_AUD1:
		if (aack_i) begin
			acyc_o <= `LOW;
			astb_o <= `LOW;
			asel_o <= 16'h0000;
			aud1_dat <= adat_i;
			state <= bcnt < 5'd22 ? LINE_FETCH2 : RS_IDLE;
		end

	ST_AUD2:
		if (aack_i) begin
			acyc_o <= `LOW;
			astb_o <= `LOW;
			asel_o <= 16'h0000;
			aud2_dat <= adat_i;
			state <= bcnt < 5'd22 ? LINE_FETCH2 : RS_IDLE;
		end

	ST_AUD3:
		if (aack_i) begin
			acyc_o <= `LOW;
			astb_o <= `LOW;
			asel_o <= 16'h0000;
			aud4_dat <= adat_i;
			state <= bcnt < 5'd22 ? LINE_FETCH2 : RS_IDLE;
		end

	ST_AUDI:
		if (aack_i) begin
			acyc_o <= `LOW;
			astb_o <= `LOW;
			awe_o <= `LOW;
			asel_o <= 16'h0000;
			state <= bcnt < 5'd22 ? LINE_FETCH2 : RS_IDLE;
		end
	endcase
	
    casez({lowres,hpos})
    14'b??_1111_0011_1111: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0100_0001: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0100_0011: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0100_0101: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0100_0111: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0100_1001: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0100_1011: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0100_1101: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0100_1111: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0101_0001: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0101_0011: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0101_0101: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0101_0111: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0101_1001: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0101_1011: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0101_1101: rdndx <= cursorWaddr[{1'b0,hpos[4:1]}+5'd1];
    14'b??_1111_0101_1111: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0110_0001: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0110_0011: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0110_0101: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0110_0111: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0110_1001: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0110_1011: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0110_1101: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0110_1111: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0111_0001: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0111_0011: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0111_0101: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0111_0111: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0111_1001: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0111_1011: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b??_1111_0111_1101: rdndx <= cursorWaddr[{1'b1,hpos[4:1]}+5'd1];
    14'b00_1111_1111_1101: rdndx <= P0 + bmpBase;	// Px = vertical pos * bitmap width (above)
    14'b01_1111_1111_1101: rdndx <= P1 + bmpBase;
    14'b10_1111_1111_1101: rdndx <= P2 + bmpBase;
    14'b00_1111_1111_1110: rdndx <= rdndx + 20'd2;
    14'b00_1111_1111_1111: rdndx <= rdndx + 20'd2;
    14'b??_1111_1111_1111: rdndx <= rdndx + 20'd2;
    14'b??_1111_????_????: rdndx <= rdndx + 20'd2;	// <- indrement for sprite addressing
    14'b00_????_????_????: rdndx <= rdndx + 20'd2;
    14'b01_????_????_???1: rdndx <= rdndx + 20'd2;
    14'b10_????_????_??11: rdndx <= rdndx + 20'd2;
    //14'b10_????_????_??11: rdndx <= rdndx + 20'd1;
    default:    ;	// don't change rdndx
    endcase
end

/*    
    			if (hpos[11:8]==4'hF)	// sprite data load
                    rdndx <= rdndx + 20'd1;
                else casez({lowres,hpos[1:0]})
	                4'b00??: rdndx <= rdndx + 20'd1;
	                4'b01?1: rdndx <= rdndx + 20'd1;
	                4'b1011: rdndx <= rdndx + 20'd1;
	                default:	rdndx <= rdndx;
	            	endcase
*/
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #-1
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Compute when to shift cursor bitmaps.
// Set cursor active flag
// Increment working count and address

reg [31:0] cursorShift;
always @(posedge clk)
    for (n = 0; n < NSPR; n = n + 1)
    begin
        cursorShift[n] <= `FALSE;
	    case(lowres)
	    2'd0,2'd3:	if (hctr >= cursor_ph[n]) cursorShift[n] <= `TRUE;
		2'd1:		if (hctr[11:1] >= cursor_ph[n]) cursorShift[n] <= `TRUE;
		2'd2:		if (hctr[11:2] >= cursor_ph[n]) cursorShift[n] <= `TRUE;
		endcase
	end

always @(posedge clk)
    for (n = 0; n < NSPR; n = n + 1)
		cursorActive[n] = (cursorWcnt[n] < cursorMcnt[n]) && cursorEnable[n];

always @(posedge clk)
    for (n = 0; n < NSPR; n = n + 1)
	begin
	    case(lowres)
	    2'd0,2'd3:	if ((vctr == cursor_pv[n]) && (hctr == 12'h005)) cursorWcnt[n] <= 16'd0;
		2'd1:		if ((vctr[11:1] == cursor_pv[n]) && (hctr == 12'h005)) cursorWcnt[n] <= 16'd0;
		2'd2:		if ((vctr[11:2] == cursor_pv[n]) && (hctr == 12'h005)) cursorWcnt[n] <= 16'd0;
		endcase
		if (hpos==12'hFF8)	// must be after image data fetch
    		if (cursorActive[n])
    		case(lowres)
    		2'd0,2'd3:	cursorWcnt[n] <= cursorWcnt[n] + cursor_szh[n];
    		2'd1:		if (vctr[0]) cursorWcnt[n] <= cursorWcnt[n] + cursor_szh[n];
    		2'd2:		if (vctr[1:0]==2'b11) cursorWcnt[n] <= cursorWcnt[n] + cursor_szh[n];
    		endcase
	end

always @(posedge clk)
    for (n = 0; n < NSPR; n = n + 1)
	begin
	    case(lowres)
	    2'd0,2'd3:	if ((vctr == cursor_pv[n]) && (hctr == 12'h005)) cursorWaddr[n] <= cursorAddr[n];
		2'd1:		if ((vctr[11:1] == cursor_pv[n]) && (hctr == 12'h005)) cursorWaddr[n] <= cursorAddr[n];
		2'd2:		if ((vctr[11:2] == cursor_pv[n]) && (hctr == 12'h005)) cursorWaddr[n] <= cursorAddr[n];
		endcase
		if (hpos==12'hFF8)	// must be after image data fetch
		case(lowres)
   		2'd0,2'd3:	cursorWaddr[n] <= cursorWaddr[n] + 20'd4;
   		2'd1:		if (vctr[0]) cursorWaddr[n] <= cursorWaddr[n] + 20'd4;
   		2'd2:		if (vctr[1:0]==2'b11) cursorWaddr[n] <= cursorWaddr[n] + 20'd4;
   		endcase
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #0
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Get the cursor display status
// Load the cursor bitmap from ram
// Determine when cursor output should appear
// Shift the cursor bitmap
// Compute color indexes for all sprites

always @(posedge clk)
begin
    for (n = 0; n < NSPR; n = n + 1)
        if (cursorActive[n] & cursorShift[n]) begin
            cursor_on[n] <=
                cursorLink2[n] ? |{ cursorBmp[(n+2)&31][63:62],cursorBmp[(n+1)&31][63:62],cursorBmp[n][63:62]} :
                cursorLink1[n] ? |{ cursorBmp[(n+1)&31][63:62],cursorBmp[n][63:62]} : 
                |cursorBmp[n][63:62];
        end
        else
            cursor_on[n] <= 1'b0;
end

// Load / shift cursor bitmap
always @(posedge clk)
begin
    casez(hpos)
    12'b1111_01??_???0: cursorBmp[{hpos[5:1]}][63:32] <= rgb_i32;
    12'b1111_01??_???1: cursorBmp[{hpos[5:1]}][31:0] <= rgb_i32;
    endcase
    for (n = 0; n < NSPR; n = n + 1)
        if (cursorShift[n])
            cursorBmp[n] <= {cursorBmp[n][61:0],2'b00};
end

always @(posedge clk)
for (n = 0; n < NSPR; n = n + 1)
if (cursorLink2[n])
    cursorColorNdx[n] <= {cursorBmp[(n+2)&31][63:62],cursorBmp[(n+1)&31][63:62],cursorBmp[n][63:62]};
else if (cursorLink1[n])
    cursorColorNdx[n] <= {n[3:2],cursorBmp[(n+1)&31][63:62],cursorBmp[n][63:62]};
else
    cursorColorNdx[n] <= {n[3:0],cursorBmp[n][63:62]};

// Compute index into sprite color palette
// If none of the sprites are linked, each sprite has it's own set of colors.
// If the sprites are linked once the colors are available in groups.
// If the sprites are linked twice they all share the same set of colors.
// Pipelining register
reg blank1, blank2, blank3, blank4;
reg border1, border2, border3, border4;
reg any_cursor_on2, any_cursor_on3, any_cursor_on4;
reg [23:0] rgb_i3, rgb_i4;
reg [3:0] zb_i3, zb_i4;
reg [3:0] cursor_z1, cursor_z2, cursor_z3, cursor_z4;
reg [3:0] cursor_pzx;
// The color index from each sprite can be mux'ed into a single value used to
// access the color palette because output color is a priority chain. This
// saves having mulriple read ports on the color palette.
reg [31:0] cursorColorOut2; 
reg [31:0] cursorColorOut3;
reg [5:0] cursorClrNdx;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #1
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Mux color index
// Fetch cursor Z order

always @(posedge clk)
    cursor_on_d1 <= cursor_on;
always @(posedge clk)
    blank1 <= blank;
always @(posedge clk)
    border1 <= border;

always @(posedge clk)
begin
	cursorClrNdx <= 6'd0;
	for (n = NSPR-1; n >= 0; n = n -1)
		if (cursor_on[n])
			cursorClrNdx <= cursorColorNdx[n];
end
        
always @(posedge clk)
begin
	cursor_z1 <= 4'hF;
	for (n = NSPR-1; n >= 0; n = n -1)
		if (cursor_on[n])
			cursor_z1 <= cursor_pz[n]; 
end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #2
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Lookup color from palette

always @(posedge clk)
    cursor_on_d2 <= cursor_on_d1;
always @(posedge clk)
    any_cursor_on2 <= |cursor_on_d1;
always @(posedge clk)
    blank2 <= blank1;
always @(posedge clk)
    border2 <= border1;
always @(posedge clk)
    cursorColorOut2 <= cursor_color[cursorClrNdx];
always @(posedge clk)
    cursor_z2 <= cursor_z1;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #3
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Compute alpha blending

wire [12:0] alphaRed = (rgb_i[`R] * cursorColorOut2[31:24]) + (cursorColorOut2[`R] * (9'h100 - cursorColorOut2[31:24]));
wire [12:0] alphaGreen = (rgb_i[`G] * cursorColorOut2[31:24]) + (cursorColorOut2[`G]  * (9'h100 - cursorColorOut2[31:24]));
wire [12:0] alphaBlue = (rgb_i[`B] * cursorColorOut2[31:24]) + (cursorColorOut2[`B]  * (9'h100 - cursorColorOut2[31:24]));
reg [14:0] alphaOut;

always @(posedge clk)
    alphaOut <= {alphaRed[12:8],alphaGreen[12:8],alphaBlue[12:8]};
always @(posedge clk)
    cursor_z3 <= cursor_z2;
always @(posedge clk)
    any_cursor_on3 <= any_cursor_on2;
always @(posedge clk)
    rgb_i3 <= rgb_i;
always @(posedge clk)
    zb_i3 <= zb_i;
always @(posedge clk)
    blank3 <= blank2;
always @(posedge clk)
    border3 <= border2;
always @(posedge clk)
    cursorColorOut3 <= cursorColorOut2;

reg [14:0] flashOut;
wire [14:0] reverseVideoOut = cursorColorOut2[21] ? alphaOut ^ 15'h7FFF : alphaOut;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #4
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Compute flash output

always @(posedge clk)
    flashOut <= cursorColorOut3[20] ? (((flashcnt[5:2] & cursorColorOut3[19:16])!=4'b000) ? reverseVideoOut : rgb_i3) : reverseVideoOut;
always @(posedge clk)
    rgb_i4 <= rgb_i3;
always @(posedge clk)
    cursor_z4 <= cursor_z3;
always @(posedge clk)
    any_cursor_on4 <= any_cursor_on3;
always @(posedge clk)
    zb_i4 <= zb_i3;
always @(posedge clk)
    blank4 <= blank3;
always @(posedge clk)
    border4 <= border3;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #5
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// final output registration

always @(posedge clk)
	casez({blank4,border4,any_cursor_on4})
	3'b1??:		rgb <= 24'h000000;
	3'b01?:		rgb <= borderColor;
	3'b001:		rgb <= ((zb_i4 < cursor_z4) ? rgb_i4 : flashOut);
	3'b000:		rgb <= rgb_i4;
	endcase
always @(posedge clk)
    blank_o <= blank4;


endmodule
