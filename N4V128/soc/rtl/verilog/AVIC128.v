// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// AVIC128.v
// - audio/video interface circuit
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

`define A		15
`define R		14:10
`define G		9:5
`define B		4:0

`define BLACK	16'h0000
`define WHITE	16'h7FFF

module AVIC128 (
	rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o,
	m_clk_i, m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o,
	vclk, hSync, vSync, de, rgb,
	aud0_out, aud1_out, aud2_out, aud3_out, aud_in
);
// WISHBONE slave port
input rst_i;
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
// WISHBONE master port
input m_clk_i;
output reg m_cyc_o;
output m_stb_o;
input m_ack_i;
output reg m_we_o;
output reg [15:0] m_sel_o;
output reg [31:0] m_adr_o;
input [127:0] m_dat_i;
output reg [127:0] m_dat_o;
// Video Port
input vclk;
output hSync;
output vSync;
output reg de;
output reg [23:0] rgb;
// Audio ports
output reg [15:0] aud0_out;
output reg [15:0] aud1_out;
output reg [15:0] aud2_out;
output reg [15:0] aud3_out;
input [15:0] aud_in;


parameter NSPR = 32;			// number of supported sprites
parameter pAckStyle = 1'b0;

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

parameter LINE_RESET = 6'd0;
parameter DELAY = 6'd1;
parameter READ_ACC = 6'd2;
parameter READ_ACK = 6'd3;
parameter SPRITE_ACC = 6'd4;
parameter SPRITE_ACK = 6'd5;
parameter WAIT_RESET = 6'd6;
parameter ST_AUD0 = 6'd8;
parameter ST_AUD1 = 6'd9;
parameter ST_AUD2 = 6'd10;
parameter ST_AUD3 = 6'd11;
parameter ST_AUDI = 6'd12;
parameter OTHERS = 6'd13;

assign m_stb_o = m_cyc_o;

integer n;

wire eol;
wire eof;
wire border;
wire blank, vblank;
wire vbl_int;
reg [9:0] vbl_reg;

reg [11:0] hTotal = phTotal;
reg [11:0] vTotal = pvTotal;
reg [11:0] hSyncOn = phSyncOn, hSyncOff = phSyncOff;
reg [11:0] vSyncOn = pvSyncOn, vSyncOff = pvSyncOff;
reg [11:0] hBlankOn = phBlankOn, hBlankOff = phBlankOff;
reg [11:0] vBlankOn = pvBlankOn, vBlankOff = pvBlankOff;
reg [11:0] hBorderOn = phBorderOn, hBorderOff = phBorderOff;
reg [11:0] vBorderOn = pvBorderOn, vBorderOff = pvBorderOff;
wire [11:0] hctr, vctr;
reg [11:0] m_hctr, m_vctr;
reg [11:0] hstart = 12'hEFF;
reg [11:0] vstart = 12'hFE6;
reg [5:0] flashcnt;

reg [31:0] irq_status;

reg [1:0] lowres = 2'b00;
reg [23:0] borderColor;
reg rst_fifo;
reg rd_fifo;
wire [15:0] rgb_i;
reg lrst;						// line reset

// Cursor related registers
reg [31:0] collision;
reg [4:0] spriteno;
reg sprite;
reg [31:0] spriteEnable;
reg [31:0] spriteActive;
reg [11:0] sprite_pv [0:31];
reg [11:0] sprite_ph [0:31];
reg [3:0] sprite_pz [0:31];
reg [31:0] sprite_color [0:255];
reg [31:0] sprite_on;
reg [31:0] sprite_on_d1;
reg [31:0] sprite_on_d2;
reg [31:0] sprite_on_d3;
reg [31:0] spriteAddr [0:31];
reg [31:0] spriteWaddr [0:31];
reg [15:0] spriteMcnt [0:31];
reg [15:0] spriteWcnt [0:31];
reg [127:0] m_spriteBmp [0:31];
reg [127:0] spriteBmp [0:31];
reg [15:0] spriteColor [0:31];
reg [31:0] spriteLink1;
reg [7:0] spriteColorNdx [0:31];

reg [31:0] TargetBase = 32'h100000;
reg [15:0] TargetWidth = 16'd600;
reg sgLock;

reg [11:0] vpos;
reg [27:0] vndx;
// read access counter, controls number of consecutive reads
reg [3:0] rac;
reg [3:0] rac_limit = 4'd4;
reg [5:0] state;
reg [5:0] retstate;
reg [7:0] strip_cnt;
reg [5:0] delay_cnt;
reg [7:0] num_strips = 8'd100;
wire [31:0] douta;

//     i3210   31 i3210
// -t- rrrrr p mm eeeee
//  |    |   |  |   +--- channel enables
//  |    |   |  +------- mix channels 1 into 0, 3 into 2
//  |    |   +---------- input plot mode
//  |    +-------------- chennel reset
//  +------------------- test mode
//
// The channel needs to be reset for use as this loads the working address
// register with the audio sample base address.
//
reg [31:0] aud_ctrl;
wire aud_mix1 = aud_ctrl[5];
wire aud_mix3 = aud_ctrl[6];
//
//           3210 3210
// ---- ---- -fff -aaa
//             |    +--- amplitude modulate next channel
//             +-------- frequency modulate next channel
//
reg [31:0] aud0_adr;
reg [15:0] aud0_length;
reg [19:0] aud0_period;
reg [15:0] aud0_volume;
reg signed [15:0] aud0_dat;
reg signed [15:0] aud0_dat2;		// double buffering
reg [31:0] aud1_adr;
reg [15:0] aud1_length;
reg [19:0] aud1_period;
reg [15:0] aud1_volume;
reg signed [15:0] aud1_dat;
reg signed [15:0] aud1_dat2;
reg [31:0] aud2_adr;
reg [15:0] aud2_length;
reg [19:0] aud2_period;
reg [15:0] aud2_volume;
reg signed [15:0] aud2_dat;
reg signed [15:0] aud2_dat2;
reg [31:0] aud3_adr;
reg [15:0] aud3_length;
reg [19:0] aud3_period;
reg [15:0] aud3_volume;
reg signed [15:0] aud3_dat;
reg signed [15:0] aud3_dat2;
reg [31:0] audi_adr;
reg [19:0] audi_length;
reg [19:0] audi_period;
reg signed [15:0] audi_dat;
reg rd_aud0;
reg rd_aud1;
reg rd_aud2;
reg rd_aud3;
wire aud0_fifo_empty;
wire aud1_fifo_empty;
wire aud2_fifo_empty;
wire aud3_fifo_empty;

wire [15:0] aud0_fifo_o;
wire [15:0] aud1_fifo_o;
wire [15:0] aud2_fifo_o;
wire [15:0] aud3_fifo_o;

VGASyncGen u1
(
	.rst(rst_i),
	.clk(vclk),
	.eol(eol),
	.eof(eof),
	.hSync(hSync),
	.vSync(vSync),
	.hCtr(hctr),
	.vCtr(vctr),
    .blank(blank),
    .vblank(),
    .vbl_int(),
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

wire peack;
edge_det u3 (.rst(rst_i), .clk(m_clk_i), .ce(1'b1), .i(m_ack_i), .pe(peack), .ne(), .ee());

N4V128_VideoFifo u2
(
	.rst(rst_fifo),
	.wr_clk(m_clk_i),
	.rd_clk(m_clk_i),
	.din(m_dat_i),
	.wr_en(peack && state==READ_ACK),
	.rd_en(rd_fifo),
	.dout(rgb_i),
	.full(),
	.empty(),
	.wr_rst_busy(),
	.rd_rst_busy()
);

VIC128_AudioFifo u5
(
  .rst(aud_ctrl[8]),
  .wr_clk(m_clk_i),
  .rd_clk(m_clk_i),
  .din(m_dat_i),
  .wr_en(peack && (state==ST_AUD0)),
  .rd_en(aud_ctrl[0] & rd_aud0),
  .dout(aud0_fifo_o),
  .full(),
  .empty(aud0_fifo_empty),
  .wr_rst_busy(),
  .rd_rst_busy()
);

VIC128_AudioFifo u6
(
  .rst(aud_ctrl[9]),
  .wr_clk(m_clk_i),
  .rd_clk(m_clk_i),
  .din(m_dat_i),
  .wr_en(peack && (state==ST_AUD1)),
  .rd_en(aud_ctrl[1] & rd_aud1),
  .dout(aud1_fifo_o),
  .full(),
  .empty(aud1_fifo_empty),
  .wr_rst_busy(),
  .rd_rst_busy()
);

VIC128_AudioFifo u7
(
  .rst(aud_ctrl[10]),
  .wr_clk(m_clk_i),
  .rd_clk(m_clk_i),
  .din(m_dat_i),
  .wr_en(peack && (state==ST_AUD2)),
  .rd_en(aud_ctrl[2] & rd_aud2),
  .dout(aud2_fifo_o),
  .full(),
  .empty(aud2_fifo_empty),
  .wr_rst_busy(),
  .rd_rst_busy()
);

VIC128_AudioFifo u8
(
  .rst(aud_ctrl[11]),
  .wr_clk(m_clk_i),
  .rd_clk(m_clk_i),
  .din(m_dat_i),
  .wr_en(peack && (state==ST_AUD3)),
  .rd_en(aud_ctrl[3] & rd_aud3),
  .dout(aud3_fifo_o),
  .full(),
  .empty(aud3_fifo_empty),
  .wr_rst_busy(),
  .rd_rst_busy()
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// WISHBONE slave port - register interface.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire cs = cs_i & cyc_i & stb_i;

VIC128_ShadowRam u4
(
	.clka(clk_i),
	.ena(cs),
	.wea({4{cs & we_i}} & sel_i),
	.addra(adr_i[11:2]),
	.dina(dat_i),
	.douta(douta)
);


always @(posedge clk_i)
begin
	if (cs & we_i)
		casez(adr_i[11:2])
		10'b00????????:	sprite_color[adr_i[9:2]] <= dat_i;
		10'b010?????00:	spriteAddr[adr_i[8:4]] <= dat_i;
		10'b010?????01:	spriteMcnt[adr_i[8:4]] <= dat_i[15:0];
		10'b010?????10:	begin
							if (|sel_i[1:0]) sprite_ph[adr_i[8:4]] <= dat_i[11:0];
							if (|sel_i[3:2]) sprite_pv[adr_i[8:4]] <= dat_i[27:16];
						end
		// Audio $600 to $65E
		10'b0110_0000_00:   aud0_adr <= dat_i;
		10'b0110_0000_01:   aud0_length <= dat_i[15:0];
		10'b0110_0000_10:   aud0_period <= dat_i[19:0];
		10'b0110_0000_11:   begin
							if (|sel_i[1:0]) aud0_volume <= dat_[15:0];
							if (|sel_i[3:2]) aud0_dat <= dat_i[31:16];
							end
		10'b0110_0001_00:   aud1_adr <= dat_i;
		10'b0110_0001_01:   aud1_length <= dat_i[15:0];
		10'b0110_0001_10:   aud1_period <= dat_i[19:0];
		10'b0110_0001_11:   begin
							if (|sel_i[1:0]) aud1_volume <= dat_[15:0];
							if (|sel_i[3:2]) aud1_dat <= dat_i[31:16];
							end
		10'b0110_0010_00:   aud2_adr <= dat_i;
		10'b0110_0010_01:   aud2_length <= dat_i[15:0];
		10'b0110_0010_10:   aud2_period <= dat_i[19:0];
		10'b0110_0010_11:   begin
							if (|sel_i[1:0]) aud2_volume <= dat_[15:0];
							if (|sel_i[3:2]) aud2_dat <= dat_i[31:16];
							end
		10'b0110_0011_00:   aud3_adr <= dat_i;
		10'b0110_0011_01:   aud3_length <= dat_i[15:0];
		10'b0110_0011_10:   aud3_period <= dat_i[19:0];
		10'b0110_0011_11:   begin
							if (|sel_i[1:0]) aud3_volume <= dat_[15:0];
							if (|sel_i[3:2]) aud3_dat <= dat_i[31:16];
							end
		10'b0110_0100_00:   audi_adr <= dat_i;
		10'b0110_0100_01:   audi_length <= dat_i[15:0];
		10'b0110_0100_10:   audi_period <= dat_i[19:0];
		10'b0110_0100_11:   begin
							if (|sel_i[1:0]) audi_volume <= dat_[15:0];
							if (|sel_i[3:2]) audi_dat <= dat_i[31:16];
							end

        10'b0110_0101_00:	aud_ctrl <= dat_i;

						
		10'b0111_1011_00:	spriteEnable <= dat_i;
		10'b0111_1011_01:	spriteLink1 <= dat_i;

		// Sync generator control regs  $7C0 to $7DE      
        10'b0111_1100_00:		if (sgLock) begin
        						if (|sel_i[1:0]) hTotal <= dat_i[11:0];
        						if (|sel_i[3:2]) vTotal <= dat_i[27:16];
        					end
        10'b0111_1100_01:		if (sgLock) begin
        						if (|sel_i[1:0]) hSyncOn <= dat_i[11:0];
        						if (|sel_i[3:2]) hSyncOff <= dat_i[27:16];
        					end
        10'b0111_1100_10:		if (sgLock) begin
        						if (|sel_i[1:0]) vSyncOn <= dat_i[11:0];
        						if (|sel_i[3:2]) vSyncOff <= dat_i[27:16];
        					end
        10'b0111_1100_11:		if (sgLock) begin
        						if (|sel_i[1:0]) hBlankOn <= dat_i[11:0];
        						if (|sel_i[3:2]) hBlankOff <= dat_i[27:16];
        					end
        10'b0111_1101_00:		if (sgLock) begin
        						if (|sel_i[1:0]) vBlankOn <= dat_i[11:0];
        						if (|sel_i[3:2]) vBlankOff <= dat_i[27:16];
        					end
        10'b0111_1101_01:		begin
        					if (|sel_i[1:0]) hBorderOn <= dat_i[11:0];
        					if (|sel_i[3:2]) hBorderOff <= dat_i[27:16];
        					end
        10'b0111_1101_10:		begin
        					if (|sel_i[1:0]) vBorderOn <= dat_i[11:0];
        					if (|sel_i[3:2]) vBorderOff <= dat_i[27:16];
        					end
        10'b0111_1101_11:  	begin
        					if (|sel_i[1:0]) hstart <= dat_i[11:0];
        					if (|sel_i[3:2]) vstart <= dat_i[27:16];
        					end
        10'b0111_1111_00:   	lowres <= dat_i[1:0];   
        10'b0111_1111_01:		sgLock <= dat_i==32'hA1234567;
		default:	;	// do nothing
		endcase
end
always @(posedge clk_i)
	casez(adr_i[11:2])
	10'b0111_1011_010:	dat_o <= collision;
	default:	dat_o <= douta;
	endcase

reg rdy1, rdy2, rdy3;
always @(posedge clk_i)
	rdy1 <= cs;
always @(posedge clk_i)
	rdy2 <= rdy1 & cs;
always @(posedge clk_i)
	rdy3 <= rdy2 & cs;
assign ack_o = cs ? rdy3 : pAckStyle;
	
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Audio
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [23:0] aud_test;
reg [19:0] aud0_wadr, aud1_wadr, aud2_wadr, aud3_wadr, audi_wadr;
reg [19:0] ch0_cnt, ch1_cnt, ch2_cnt, ch3_cnt, chi_cnt;
// The request counter keeps track of the number of times a request was issued
// without being serviced. There may be the occasional request missed by the
// timing budget. The counter allows the sample to remain on-track and in
// sync with other samples being read.
reg [5:0] aud0_req, aud1_req, aud2_req, aud3_req, audi_req;
// The following request signals pulse for 1 clock cycle only.
reg aud0_req2, aud1_req2, aud2_req2, aud3_req2, audi_req2;

always @(posedge m_clk_i)
	if (ch0_cnt>=aud0_period || aud_ctrl[8])
		ch0_cnt <= 20'd1;
	else if (aud_ctrl[0])
		ch0_cnt <= ch0_cnt + 20'd1;
always @(posedge m_clk_i)
	if (ch1_cnt>= aud1_period || aud_ctrl[9])
		ch1_cnt <= 20'd1;
	else if (aud_ctrl[1])
		ch1_cnt <= ch1_cnt + (aud_ctrl[20] ? aud0_out[15:8] + 20'd1 : 20'd1);
always @(posedge m_clk_i)
	if (ch2_cnt>= aud2_period || aud_ctrl[10])
		ch2_cnt <= 20'd1;
	else if (aud_ctrl[2])
		ch2_cnt <= ch2_cnt + (aud_ctrl[21] ? aud1_out[15:8] + 20'd1 : 20'd1);
always @(posedge m_clk_i)
	if (ch3_cnt>= aud3_period || aud_ctrl[11])
		ch3_cnt <= 20'd1;
	else if (aud_ctrl[3])
		ch3_cnt <= ch3_cnt + (aud_ctrl[22] ? aud2_out[15:8] + 20'd1 : 20'd1);
always @(posedge m_clk_i)
	if (chi_cnt>=audi_period || aud_ctrl[12])
		chi_cnt <= 20'd1;
	else if (aud_ctrl[4])
		chi_cnt <= chi_cnt + 20'd1;

always @(posedge m_clk_i)
	aud0_dat2 <= aud0_fifo_o;
always @(posedge m_clk_i)
	aud1_dat2 <= aud1_fifo_o;
always @(posedge m_clk_i)
	aud2_dat2 <= aud2_fifo_o;
always @(posedge m_clk_i)
	aud3_dat2 <= aud3_fifo_o;

always @(posedge m_clk_i)
begin
	rd_aud0 <= `FALSE;
	rd_aud1 <= `FALSE;
	rd_aud2 <= `FALSE;
	rd_aud3 <= `FALSE;
	audi_req2 <= `FALSE;
// IF channel count == 1
// A count value of zero is not possible so there will be no requests unless
// the audio channel is enabled.
	if (ch0_cnt==aud_ctrl[0] && ~aud_ctrl[8])
		rd_aud0 <= `TRUE;
	if (ch1_cnt==aud_ctrl[1] && ~aud_ctrl[9])
		rd_aud1 <= `TRUE;
	if (ch2_cnt==aud_ctrl[2] && ~aud_ctrl[10])
		rd_aud2 <= `TRUE;
	if (ch3_cnt==aud_ctrl[3] && ~aud_ctrl[11])
		rd_aud3 <= `TRUE;
	if (chi_cnt==aud_ctrl[4] && ~aud_ctrl[12]) begin
		audi_req <= audi_req + 6'd1;
		audi_req2 <= 1'b1;
	end
end

wire signed [31:0] aud1_tmp;
wire signed [31:0] aud0_tmp = aud_mix1 ? ((aud0_dat2 * aud0_volume + aud1_tmp) >> 1): aud0_dat2 * aud0_volume;
wire signed [31:0] aud3_tmp;
wire signed [31:0] aud2_dat3 = aud_ctrl[17] ? aud2_dat2 * aud2_volume * aud1_dat2 : aud2_dat2 * aud2_volume;
wire signed [31:0] aud2_tmp = aud_mix3 ? ((aud2_dat3 + aud3_tmp) >> 1): aud2_dat3;

assign aud1_tmp = aud_ctrl[16] ? aud1_dat2 * aud1_volume * aud0_dat2 : aud1_dat2 * aud1_volume;
assign aud3_tmp = aud_ctrl[18] ? aud3_dat2 * aud3_volume * aud2_dat2 : aud3_dat2 * aud3_volume;
					

always @(posedge m_clk_i)
begin
	aud0_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[0] ? aud0_tmp >> 16 : 16'h0000;
	aud1_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[1] ? aud1_tmp >> 16 : 16'h0000;
	aud2_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[2] ? aud2_tmp >> 16 : 16'h0000;
	aud3_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[3] ? aud3_tmp >> 16 : 16'h0000;
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// RGB output display side
// clk clock domain
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Register hctr,vctr onto the m_clk_i domain
always @(posedge m_clk_i)
	m_hctr <= hctr;
always @(posedge m_clk_i)
	m_vctr <= vctr;

// widen vertical blank interrupt pulse
always @(posedge vclk)
	if (vbl_int)
		vbl_reg <= 10'h3FF;
	else
		vbl_reg <= {vbl_reg[8:0],1'b0};

always @(posedge vclk)
	if (eol & eof)
		flashcnt <= flashcnt + 6'd1;

// Generate fifo reset signal
always @(posedge m_clk_i)
	if (m_hctr >= 12'd1 && m_hctr < 12'd16)
		rst_fifo <= `TRUE;
	else
		rst_fifo <= `FALSE;

// Generate fifo read signal
always @(posedge vclk)
	if (hctr >= hBlankOff && hctr < hBlankOn)
		rd_fifo <= `TRUE;
	else
		rd_fifo <= `FALSE;

// Memory access state machine
always @(posedge m_clk_i)
if (rst_i)
	aud_test <= 24'h0;
else begin

// Channel reset
if (aud_ctrl[8])
	aud0_wadr <= aud0_adr;
if (aud_ctrl[9])
	aud1_wadr <= aud1_adr;
if (aud_ctrl[10])
	aud2_wadr <= aud2_adr;
if (aud_ctrl[11])
	aud3_wadr <= aud3_adr;
if (aud_ctrl[12])
	audi_wadr <= audi_adr;

// Audio test mode generates about a 600Hz signal for 0.5 secs on all the
// audio channels.
if (aud_ctrl[14])
    aud_test <= aud_test + 24'd1;
if (aud_test==24'hFFFFFF) begin
    aud_test <= 24'h0;
    aud_ctrl[14] <= 1'b0;
end

if (audi_req2)
	audi_dat <= aud_in;


	// Pipeline the vertical calc.
	vpos <= m_vctr - vstart;
	vndx <= vpos * TargetWidth;
case(state)
OTHERS:
	// Audio takes precedence to avoid audio distortion.
	// Fortunately audio DMA is fast and infrequent.
	if (aud0_fifo_empty & aud_ctrl[0]) begin
	    m_cyc_o <= `HIGH;
	    m_sel_o <= 16'hFFFF;
		m_adr_o <= {aud0_wadr[31:4],4'h0};
		aud0_wadr <= aud0_wadr + 32'd16;
		if (aud0_wadr + 32'd16 >= aud0_adr + aud0_length) begin
			aud0_wadr <= aud0_adr;
			irq_status[8] <= 1'b1;
		end
		if (aud0_wadr < ((aud0_adr + aud0_length) >> 1) &&
			(aud0_wadr + 32'd16 >= ((aud0_adr + aud0_length) >> 1)))
			irq_status[4] <= 1'b1;
		goto(ST_AUD0);
	end
	else if (aud1_fifo_empty & aud_ctrl[1])	begin
	    m_cyc_o <= `HIGH;
	    m_sel_o <= 16'hFFFF;
		m_adr_o <= {aud1_wadr[31:4],4'h0};
		aud1_wadr <= aud1_wadr + 32'd16;
		if (aud1_wadr + 32'd16 >= aud1_adr + aud1_length) begin
			aud1_wadr <= aud1_adr;
			irq_status[9] <= 1'b1;
		end
		if (aud1_wadr < ((aud1_adr + aud1_length) >> 1) &&
			(aud1_wadr + 32'd16 >= ((aud1_adr + aud1_length) >> 1)))
			irq_status[5] <= 1'b1;
		goto(ST_AUD1);
	end
	else if (aud2_fifo_empty & aud_ctrl[2]) begin
	    m_cyc_o <= `HIGH;
	    m_sel_o <= 16'hFFFF;
		m_adr_o <= {aud2_wadr[31:4],4'h0};
		aud2_wadr <= aud2_wadr + 32'd16;
		if (aud2_wadr + 32'd16 >= aud2_adr + aud2_length) begin
			aud2_wadr <= aud2_adr;
			irq_status[10] <= 1'b1;
		end
		if (aud2_wadr < ((aud2_adr + aud2_length) >> 1) &&
			(aud2_wadr + 32'd16 >= ((aud2_adr + aud2_length) >> 1)))
			irq_status[6] <= 1'b1;
		goto(ST_AUD2);
	end
	else if (aud3_fifo_empty & aud_ctrl[3])	begin
	    m_cyc_o <= `HIGH;
	    m_sel_o <= 16'hFFFF;
		m_adr_o <= {aud3_wadr[31:4],4'h0};
		aud3_wadr <= aud3_wadr + 32'd16;
		aud3_req <= 6'd0;
		if (aud3_wadr + 32'd16 >= aud3_adr + aud3_length) begin
			aud3_wadr <= aud3_adr;
			irq_status[11] <= 1'b1;
		end
		if (aud3_wadr < ((aud3_adr + aud3_length) >> 1) &&
			(aud3_wadr + 32'd16 >= ((aud3_adr + aud3_length) >> 1)))
			irq_status[7] <= 1'b1;
		goto(ST_AUD3);
	end
	else if (|audi_req) begin
	    m_cyc_o <= `HIGH;
	    m_we_o <= `HIGH;
	    m_sel_o <= 16'd3 << {audi_wadr[3:1],1'b0};
		m_adr_o <= {audi_wadr[31:4],4'h0};
		m_dat_o <= {8{audi_dat}};
		audi_wadr <= audi_wadr + audi_req;
		audi_req <= 6'd0;
		if (audi_wadr + audi_req >= audi_adr + audi_length) begin
			audi_wadr <= audi_adr + (audi_wadr + audi_req - (audi_adr + audi_length));
			irq_status[12] <= 1'b1;
		end
		if (audi_wadr < ((audi_adr + audi_length) >> 1) &&
			(audi_wadr + audi_req >= ((audi_adr + audi_length) >> 1)))
			irq_status[3] <= 1'b1;
		goto(ST_AUDI);
	end
LINE_RESET:
	begin
		lrst <= `FALSE;
		strip_cnt <= 8'd0;
		rac <= 4'd0;
		if (vblank)
			call(OTHERS,LINE_RESET);
		else begin
			m_cyc_o <= `LOW;
			m_sel_o <= 16'h0000;
			m_adr_o <= TargetBase + vndx;
			goto(READ_ACC);
		end
	end
READ_ACC:
	begin
		m_cyc_o <= `HIGH;
		m_sel_o <= 16'hFFFF;
		goto(READ_ACK);
	end
READ_ACK:
	if (m_ack_i) begin
		strip_cnt <= strip_cnt + 8'd1;
		rac <= rac + 6'd1;
		m_cyc_o <= `LOW;
		m_sel_o <= 16'h0000;
		m_adr_o <= m_adr_o + 32'd16;
		// If we read all the strips we needed to, then start reading sprite
		// data.
		if (strip_cnt==num_strips) begin
			spriteno <= 5'd0;
			for (n = 0; n < 32; n = n + 1)
				m_spriteBmp[n] <= 128'd0;
			goto(SPRITE_ACC);
		end
		// Check for too many consecutive memory accesses. Be nice to other
		// bus masters.
		else if (rac < rac_limit)
			goto(READ_ACC);
		else begin
			delay_cnt <= 6'd32;
			rac <= 4'd0;
			call(OTHERS,READ_ACC);
		end
	end
SPRITE_ACC:
	begin
		m_cyc_o <= `HIGH;
		m_sel_o <= 16'hFFFF;
		m_adr_o <= spriteWaddr[spriteno];
	end
SPRITE_ACK:
	if (m_ack_i) begin
		m_cyc_o <= `LOW;
		m_sel_o <= 16'h0000;
		m_adr_o <= 32'hFFFFFFFF;
		m_spriteBmp[spriteno] <= m_dat_i;
		spriteno <= spriteno + 5'd1;
		rac <= rac + 4'd1;
		if (spriteno==5'd31)
			goto(WAIT_RESET);
		else if (rac <= 4'd2)
			goto (SPRITE_ACC);
		else begin
			delay_cnt <= 6'd32;
			rac <= 4'd0;
			call(OTHERS,SPRITE_ACC);
		end
	end
WAIT_RESET:
	if (lrst)
		goto(LINE_RESET);
	else
		call(OTHERS,WAIT_RESET);

ST_AUD0,
ST_AUD1,
ST_AUD2,
ST_AUD3,
ST_AUDI:
	if (m_ack_i) begin
		m_cyc_o <= `LOW;
		m_we_o <= `LOW;
		m_sel_o <= 16'h0000;
		m_adr_o <= 32'hFFFFFFFF;
		return();
	end

default:    goto(WAIT_RESET);
endcase
    // Override any other state assignments
    if (m_hctr==12'd5)
    	lrst <= `TRUE;

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
		spriteActive[n] = (spriteWcnt[n] < spriteMcnt[n]) && spriteEnable[n];

always @(posedge vclk)
    for (n = 0; n < NSPR; n = n + 1)
	begin
	    case(lowres)
	    2'd0,2'd3:	if ((vctr == sprite_pv[n]) && (hctr == 12'h005)) spriteWcnt[n] <= 16'd0;
		2'd1:		if ((vctr[11:1] == sprite_pv[n]) && (hctr == 12'h005)) spriteWcnt[n] <= 16'd0;
		2'd2:		if ((vctr[11:2] == sprite_pv[n]) && (hctr == 12'h005)) spriteWcnt[n] <= 16'd0;
		endcase
		if (hctr==hTotal-12'd2)	// must be after image data fetch
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
		if (hctr==hTotal-12'd2)	// must be after image data fetch
		case(lowres)
   		2'd0,2'd3:	spriteWaddr[n] <= spriteWaddr[n] + 32'd16;
   		2'd1:		if (vctr[0]) spriteWaddr[n] <= spriteWaddr[n] + 32'd16;
   		2'd2:		if (vctr[1:0]==2'b11) spriteWaddr[n] <= spriteWaddr[n] + 32'd16;
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
                spriteLink1[n] ? |{ spriteBmp[(n+1)&31][127:124],spriteBmp[n][127:124]} : 
                |spriteBmp[n][127:124];
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
            spriteBmp[n] <= {spriteBmp[n][123:0],4'h0};
end

always @(posedge vclk)
for (n = 0; n < NSPR; n = n + 1)
if (spriteLink1[n])
    spriteColorNdx[n] <= {n[3:2],spriteBmp[(n+1)&31][127:124],spriteBmp[n][127:124]};
else
    spriteColorNdx[n] <= {n[3:0],spriteBmp[n][127:124]};

// Compute index into sprite color palette
// If none of the sprites are linked, each sprite has it's own set of colors.
// If the sprites are linked once the colors are available in groups.
// If the sprites are linked twice they all share the same set of colors.
// Pipelining register
reg blank1, blank2, blank3, blank4;
reg border1, border2, border3, border4;
reg any_sprite_on2, any_sprite_on3, any_sprite_on4;
reg [14:0] rgb_i3, rgb_i4;
reg [3:0] zb_i3, zb_i4;
reg [3:0] sprite_z1, sprite_z2, sprite_z3, sprite_z4;
reg [3:0] sprite_pzx;
// The color index from each sprite can be mux'ed into a single value used to
// access the color palette because output color is a priority chain. This
// saves having mulriple read ports on the color palette.
reg [31:0] spriteColorOut2; 
reg [31:0] spriteColorOut3;
reg [7:0] spriteClrNdx;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #1
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Mux color index
// Fetch sprite Z order

always @(posedge vclk)
    sprite_on_d1 <= sprite_on;
always @(posedge vclk)
    blank1 <= blank;
always @(posedge vclk)
    border1 <= border;

always @(posedge vclk)
begin
	spriteClrNdx <= 6'd0;
	for (n = NSPR-1; n >= 0; n = n -1)
		if (sprite_on[n])
			spriteClrNdx <= spriteColorNdx[n];
end
        
always @(posedge vclk)
begin
	sprite_z1 <= 4'hF;
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

wire [12:0] alphaRed = (rgb_i[`R] * spriteColorOut2[31:24]) + (spriteColorOut2[`R] * (9'h100 - spriteColorOut2[31:24]));
wire [12:0] alphaGreen = (rgb_i[`G] * spriteColorOut2[31:24]) + (spriteColorOut2[`G]  * (9'h100 - spriteColorOut2[31:24]));
wire [12:0] alphaBlue = (rgb_i[`B] * spriteColorOut2[31:24]) + (spriteColorOut2[`B]  * (9'h100 - spriteColorOut2[31:24]));
reg [14:0] alphaOut;

always @(posedge vclk)
    alphaOut <= {alphaRed[12:8],alphaGreen[12:8],alphaBlue[12:8]};
always @(posedge vclk)
    sprite_z3 <= sprite_z2;
always @(posedge vclk)
    any_sprite_on3 <= any_sprite_on2;
always @(posedge vclk)
    rgb_i3 <= rgb_i;
always @(posedge vclk)
    zb_i3 <= 4'hF;//zb_i;
always @(posedge vclk)
    blank3 <= blank2;
always @(posedge vclk)
    border3 <= border2;
always @(posedge vclk)
    spriteColorOut3 <= spriteColorOut2;

reg [14:0] flashOut;
wire [14:0] reverseVideoOut = spriteColorOut2[21] ? alphaOut ^ 15'h7FFF : alphaOut;

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// clock edge #4
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Compute flash output

always @(posedge vclk)
    flashOut <= spriteColorOut3[20] ? (((flashcnt[5:2] & spriteColorOut3[19:16])!=4'b000) ? reverseVideoOut : rgb_i3) : reverseVideoOut;
always @(posedge vclk)
    rgb_i4 <= rgb_i3;
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

always @(posedge vclk)
	casez({blank4,border4,any_sprite_on4})
	3'b1??:		rgb <= 24'h0000;
	3'b01?:		rgb <= borderColor;
	3'b001:		rgb <= ((zb_i4 < sprite_z4) ? {rgb_i4[14:10],3'b0,rgb_i4[9:5],3'b0,rgb_i4[4:0],3'b0} :
											{flashOut[14:10],3'b0,flashOut[9:5],3'b0,flashOut[4:0],3'b0});
	3'b000:		rgb <= {rgb_i4[14:10],3'b0,rgb_i4[9:5],3'b0,rgb_i4[4:0],3'b0};
	endcase
always @(posedge vclk)
    de <= ~blank4;


// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Support tasks
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

task goto;
input [3:0] st;
begin
	state <= st;
end
endtask

task return;
begin
	state <= retstate;
end
endtask

task call;
input [3:0] st;
input [3:0] rst;
begin
	retstate <= rst;
	state <= st;
end
endtask

endmodule
