`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// 5000 LUTs, 28 BRAM
// ============================================================================
//
//`define RED_SCREEN	1'b1
import mpmc8_pkg::*;

module mpmc8(
rst_i, clk100MHz,
clk0, cyc0, stb0, ack0, we0, sel0, adr0, dati0, dato0,
clk1, cs1, cyc1, stb1, ack1, we1, sel1, adr1, dati1, dato1, sr1, cr1, rb1,
clk2, cyc2, stb2, ack2, we2, sel2, adr2, dati2, dato2,
clk3, cyc3, stb3, ack3, we3, sel3, adr3, dati3, dato3,
clk4, cyc4, stb4, ack4, we4, sel4, adr4, dati4, dato4,
clk5, cyc5, stb5, ack5, sel5, adr5, dato5, spriteno,
clk6, cyc6, stb6, ack6, we6, sel6, adr6, dati6, dato6,
clk7, cs7, cyc7, stb7, ack7, we7, sel7, adr7, dati7, dato7, sr7, cr7, rb7,
mem_ui_rst, mem_ui_clk, calib_complete,
rstn, app_addr, app_cmd, app_en, app_wdf_data, app_wdf_end, app_wdf_mask, app_wdf_wren,
app_rd_data, app_rd_data_valid, app_rd_data_end, app_rdy, app_wdf_rdy,
ch, state
);
input rst_i;
input clk100MHz;

// Channel 0 is reserved for bitmapped graphics display.
//
parameter C0W = 128;	// Channel zero width
parameter STREAM0 = TRUE;
input clk0;
input cyc0;
input stb0;
output ack0;
input [C0W/8-1:0] sel0;
input we0;
input [31:0] adr0;
input [C0W-1:0] dati0;
output reg [C0W-1:0] dato0;
reg [C0W-1:0] dato0n;

// Channel 1 is reserved for cpu1
parameter C1W = 128;
input clk1;
input cs1;
input cyc1;
input stb1;
output ack1;
input we1;
input [C1W/8-1:0] sel1;
input [31:0] adr1;
input [C1W-1:0] dati1;
output reg [C1W-1:0] dato1;
input sr1;
input cr1;
output rb1;

// Channel 2 is reserved for the ethernet controller
parameter C2W = 32;
input clk2;
input cyc2;
input stb2;
output ack2;
input we2;
input [C2W/8-1:0] sel2;
input [31:0] adr2;
input [C2W-1:0] dati2;
output reg [C2W-1:0] dato2;

// Channel 3 is reserved for the audio controller
parameter C3W = 16;
parameter STREAM3 = TRUE;
input clk3;
input cyc3;
input stb3;
output ack3;
input we3;
input [C3W/8-1:0] sel3;
input [31:0] adr3;
input [C3W-1:0] dati3;
output reg [C3W-1:0] dato3;

// Channel 4 is reserved for the graphics controller
parameter C4W = 128;
input clk4;
input cyc4;
input stb4;
output ack4;
input we4;
input [C4W/8-1:0] sel4;
input [31:0] adr4;
input [C4W-1:0] dati4;
output reg [C4W-1:0] dato4;

// Channel 5 is reserved for sprite DMA, which is read-only
parameter C5W = 64;
parameter STREAM5 = TRUE;
input clk5;
input cyc5;
input stb5;
output ack5;
input [C5W/8-1:0] sel5;
input [5:0] spriteno;
input [31:0] adr5;
output reg [C5W-1:0] dato5;

// Channel 6 is reserved for the SD/MMC controller
parameter C6W = 128;
input clk6;
input cyc6;
input stb6;
output ack6;
input we6;
input [C6W/8-1:0] sel6;
input [31:0] adr6;
input [C6W-1:0] dati6;
output reg [C6W-1:0] dato6;

// Channel 7 is reserved for the cpu
parameter C7W = 16;
parameter C7R = 16;
input clk7;
input cs7;
input cyc7;
input stb7;
output ack7;
input we7;
input [C7W/8-1:0] sel7;
input [31:0] adr7;
input [C7W-1:0] dati7;
output reg [C7R-1:0] dato7;
input sr7;
input cr7;
output rb7;

// MIG interface signals
input mem_ui_rst;
input mem_ui_clk;
input calib_complete;
output rstn;
output [AMSB:0] app_addr;
output [2:0] app_cmd;
output reg app_en;
output reg [127:0] app_wdf_data;
output [15:0] app_wdf_mask;
output app_wdf_end;
output app_wdf_wren;
input [127:0] app_rd_data;
input app_rd_data_valid;
input app_rd_data_end;
input app_rdy;
input app_wdf_rdy;

// Debugging
output reg [3:0] ch;
output [3:0] state;

integer n;
integer n1;
integer n2;

wire [31:0] app_waddr;
wire [31:0] adr;
reg [127:0] dat128;
reg [15:0] wmask;
reg [127:0] rmw_data;

reg [3:0] nch;
reg [5:0] sreg;
reg rstn;
reg elevate = 1'b0;
reg [5:0] elevate_cnt = 6'h00;
reg [5:0] nack_to = 6'd0;
reg [5:0] spriteno_r;

wire cs0 = cyc0 && stb0 && adr0[31:29]==3'h0;
wire ics1 = cyc1 & stb1 & cs1;
wire cs2 = cyc2 && stb2 && adr2[31:29]==3'h0;
wire cs3 = cyc3 && stb3 && adr3[31:29]==3'h0;
wire cs4 = cyc4 && stb4 && adr4[31:29]==3'h0;
wire cs5 = cyc5 && stb5 && adr5[31:29]==3'h0;
wire cs6 = cyc6 && stb6 && adr6[31:29]==3'h0;
wire ics7 = cyc7 & stb7 & cs7;

reg acki0,acki1,acki2,acki3,acki4,acki5,acki6,acki7;
wire do_wr;
wire do_wr0;
wire do_wr1;
wire do_wr2;
wire do_wr3;
wire do_wr4;
wire do_wr5;
wire do_wr6;
wire do_wr7;

reg [2:0] num_strips;
wire [2:0] req_strip_cnt;		// count of requested strips
wire [2:0] resp_strip_cnt;		// count of response strips
reg [AMSB:0] app_addr;

reg [15:0] refcnt;				// refreshing not used, its automnatic
reg refreq;
wire refack;
wire [15:0] tocnt;					// memory access timeout counter

reg [3:0] resv_ch [0:NAR-1];
reg [31:0] resv_adr [0:NAR-1];

// Cross clock domain signals
wire cs0xx;
wire we0xx;
wire [C0W/8-1:0] sel0xx;
wire [31:0] adr0xx;
wire [C0W-1:0] dati0xx;

wire cs1xx;
wire we1xx;
wire [15:0] sel1xx;
wire [31:0] adr1xx;
wire [127:0] dati1xx;
wire sr1xx;
wire cr1xx;

wire cs2xx;
wire we2xx;
wire [C2W/8-1:0] sel2xx;
wire [31:0] adr2xx;
wire [C2W-1:0] dati2xx;

wire cs3xx;
wire we3xx;
wire [C3W/8-1:0] sel3xx;
wire [31:0] adr3xx;
wire [C3W-1:0] dati3xx;

wire cs4xx;
wire we4xx;
wire [C4W/8-1:0] sel4xx;
wire [31:0] adr4xx;
wire [C4W-1:0] dati4xx;

wire cs5xx;
wire we5xx;
wire [C5W/8-1:0] sel5xx;
wire [31:0] adr5xx;
wire [C5W-1:0] dati5xx;
wire [5:0] spritenoxx;

wire cs6xx;
wire we6xx;
wire [C6W/8-1:0] sel6xx;
wire [31:0] adr6xx;
wire [C6W-1:0] dati6xx;

wire cs7xx;
wire we7xx;
wire [C7W/8-1:0] sel7xx;
wire [31:0] adr7xx;
wire [C7W-1:0] dati7xx;
wire sr7xx;
wire cr7xx;

reg [7:0] to_cnt;

// Terminate the ack signal as soon as the circuit select goes away.
assign ack0 = acki0 & cs0;
assign ack1 = acki1 & ics1;
assign ack2 = acki2 & cs2;
assign ack3 = acki3 & cs3;
assign ack4 = acki4 & cs4;
assign ack5 = acki5 & cs5;
assign ack6 = acki6 & cs6;
assign ack7 = acki7 & ics7;

wire pre_ack0;
wire pre_ack1;
wire pre_ack2;
wire pre_ack3;
wire pre_ack4;
wire pre_ack5;
wire pre_ack6;
wire pre_ack7;

// Used to transition state to IDLE at end of access
// We dont transition to idle until a negative edge is seen on ack
wire ne_acki0;
wire ne_acki1;
wire ne_acki2;
wire ne_acki3;
wire ne_acki4;
wire ne_acki5;
wire ne_acki6;
wire ne_acki7;
wire pe_acki0;
wire pe_acki1;
wire pe_acki2;
wire pe_acki3;
wire pe_acki4;
wire pe_acki5;
wire pe_acki6;
wire pe_acki7;
edge_det ed_acki0 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki0), .pe(pe_acki0), .ne(ne_acki0), .ee());
edge_det ed_acki1 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki1), .pe(pe_acki1), .ne(ne_acki1), .ee());
edge_det ed_acki2 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki2), .pe(pe_acki2), .ne(ne_acki2), .ee());
edge_det ed_acki3 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki3), .pe(pe_acki3), .ne(ne_acki3), .ee());
edge_det ed_acki4 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki4), .pe(pe_acki4), .ne(ne_acki4), .ee());
edge_det ed_acki5 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki5), .pe(pe_acki5), .ne(ne_acki5), .ee());
edge_det ed_acki6 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki6), .pe(pe_acki6), .ne(ne_acki6), .ee());
edge_det ed_acki7 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(acki7), .pe(pe_acki7), .ne(ne_acki7), .ee());

wire [127:0] ch0_rdat_c, ch0_rdat_s, ch0_rdat;
wire [127:0] ch1_rdat;
wire [127:0] ch2_rdat;
wire [127:0] ch3_rdat, ch3_rdat_c, ch3_rdat_s;
wire [127:0] ch4_rdat;
wire [127:0] ch5_rdat, ch5_rdat_s, ch5_rdat_c;
wire [127:0] ch6_rdat;
wire [127:0] ch7_rdat;
reg [127:0] ch0_rdatr;
reg [127:0] ch1_rdatr;
reg [127:0] ch2_rdatr;
reg [127:0] ch3_rdatr;
reg [127:0] ch4_rdatr;
reg [127:0] ch5_rdatr;
reg [127:0] ch6_rdatr;
reg [127:0] ch7_rdatr;
wire ch0_hit_c, ch0_hit_s;
wire ch3_hit_c, ch3_hit_s;
wire ch5_hit_c, ch5_hit_s;
wire ch0_hit, ch1_hit, ch2_hit, ch3_hit;
wire ch4_hit, ch5_hit, ch6_hit, ch7_hit;

mpmc8_read_cache rc0 (
	.rst(rst_i),
	.wclk(mem_ui_clk),
	.wr(app_rd_data_valid && !((STREAM0 && ch==4'd0) || (STREAM3 && ch==4'd3) || (STREAM5 && ch==4'd5))),
	.wadr({app_waddr[31:4],4'h0}),
	.wdat(app_rd_data),
	.inv(state==WRITE_DATA0),
	.rclk0(STREAM0 ? 1'b0 : clk0),
	.radr0(STREAM0 ? 32'h0 : {adr0xx[31:4],4'h0}),
	.rdat0(ch0_rdat_c),
	.hit0(ch0_hit_c),
	.rclk1(mem_ui_clk),
	.radr1({adr1xx[31:4],4'h0}),
	.rdat1(ch1_rdat),
	.hit1(ch1_hit),
	.rclk2(mem_ui_clk),
	.radr2({adr2xx[31:4],4'h0}),
	.rdat2(ch2_rdat),
	.hit2(ch2_hit),
	.rclk3(STREAM3 ? 1'b0 : mem_ui_clk),
	.radr3(STREAM3 ? 32'h0 : {adr3xx[31:4],4'h0}),
	.rdat3(ch3_rdat_c),
	.hit3(ch3_hit_c),
	.rclk4(mem_ui_clk),
	.radr4({adr4xx[31:4],4'h0}),
	.rdat4(ch4_rdat),
	.hit4(ch4_hit),
	.rclk5(STREAM5 ? 1'b0 : mem_ui_clk),
	.radr5(STREAM5 ? 32'h0 : {adr5xx[31:4],4'h0}),
	.rdat5(ch5_rdat_c),
	.hit5(ch5_hit_c),
	.rclk6(mem_ui_clk),
	.radr6({adr6xx[31:4],4'h0}),
	.rdat6(ch6_rdat),
	.hit6(ch6_hit),
	.rclk7(mem_ui_clk),
	.radr7({adr7xx[31:4],4'h0}),
	.rdat7(ch7_rdat),
	.hit7(ch7_hit)
);

mpmc8_strm_read_cache ustrm0
(
	.rst(rst_i),
	.wclk(mem_ui_clk),
	.wr(ch==4'd0 && app_rd_data_valid),
	.wadr({app_waddr[31:4],4'h0}),
	.wdat(app_rd_data),
	.inv(1'b0),
	.rclk(mem_ui_clk),
	.radr({adr0xx[31:4],4'h0}),
	.rdat(ch0_rdat_s),
	.hit(ch0_hit_s)
);

mpmc8_strm_read_cache ustrm3
(
	.rst(rst_i),
	.wclk(mem_ui_clk),
	.wr(ch==4'd3 && app_rd_data_valid),
	.wadr({app_waddr[31:4],4'h0}),
	.wdat(app_rd_data),
	.inv(1'b0),
	.rclk(mem_ui_clk),
	.radr({adr3xx[31:4],4'h0}),
	.rdat(ch3_rdat_s),
	.hit(ch3_hit_s)
);

mpmc8_spr_read_cache usprrc5
(
	.rst(rst_i),
	.wclk(mem_ui_clk),
	.spr_num(spriteno[4:0]),
	.wr(ch==4'd5 && app_rd_data_valid),
	.wadr({app_waddr[31:4],4'h0}),
	.wdat(app_rd_data),
	.inv(1'b0),
	.rclk(mem_ui_clk),
	.radr({adr5xx[31:4],4'h0}),
	.rdat(ch5_rdat_s),
	.hit(ch5_hit_s)
);

assign ch0_hit = STREAM0 ? ch0_hit_s : ch0_hit_c;
assign ch0_rdat = STREAM0 ? ch0_rdat_s : ch0_rdat_c;
assign ch3_hit = STREAM3 ? ch3_hit_s : ch3_hit_c;
assign ch3_rdat = STREAM3 ? ch3_rdat_s : ch3_rdat_c;
assign ch5_hit = STREAM5 ? ch5_hit_s : ch5_hit_c;
assign ch5_rdat = STREAM5 ? ch5_rdat_s : ch5_rdat_c;

// Register signals onto mem_ui_clk domain
mpmc8_sync #(.W(C0W)) usyn0
(
	.clk(mem_ui_clk),
	.cs_i(cs0),
	.we_i(we0),
	.sel_i(sel0),
	.adr_i(adr0),
	.dati_i(dati0),
	.sr_i(1'b0),
	.cr_i(1'b0),
	.cs_o(cs0xx),
	.we_o(we0xx),
	.sel_o(sel0xx),
	.adr_o(adr0xx),
	.dati_o(dati0xx),
	.sr_o(),
	.cr_o()
);

mpmc8_sync #(.W(C1W)) usyn1
(
	.clk(mem_ui_clk),
	.cs_i(ics1),
	.we_i(we1),
	.sel_i(sel1),
	.adr_i(adr1),
	.dati_i(dati1),
	.sr_i(sr1),
	.cr_i(cr1),
	.cs_o(cs1xx),
	.we_o(we1xx),
	.sel_o(sel1xx),
	.adr_o(adr1xx),
	.dati_o(dati1xx),
	.sr_o(sr1xx),
	.cr_o(cr1xx)
);

mpmc8_sync #(.W(C2W)) usyn2
(
	.clk(mem_ui_clk),
	.cs_i(cs2),
	.we_i(we2),
	.sel_i(sel2),
	.adr_i(adr2),
	.dati_i(dati2),
	.sr_i(1'b0),
	.cr_i(1'b0),
	.cs_o(cs2xx),
	.we_o(we2xx),
	.sel_o(sel2xx),
	.adr_o(adr2xx),
	.dati_o(dati2xx),
	.sr_o(),
	.cr_o()
);

mpmc8_sync #(.W(C3W)) usyn3
(
	.clk(mem_ui_clk),
	.cs_i(cs3),
	.we_i(we3),
	.sel_i(sel3),
	.adr_i(adr3),
	.dati_i(dati3),
	.sr_i(1'b0),
	.cr_i(1'b0),
	.cs_o(cs3xx),
	.we_o(we3xx),
	.sel_o(sel3xx),
	.adr_o(adr3xx),
	.dati_o(dati3xx),
	.sr_o(),
	.cr_o()
);

mpmc8_sync #(.W(C4W)) usyn4
(
	.clk(mem_ui_clk),
	.cs_i(cs4),
	.we_i(we4),
	.sel_i(sel4),
	.adr_i(adr4),
	.dati_i(dati4),
	.sr_i(1'b0),
	.cr_i(1'b0),
	.cs_o(cs4xx),
	.we_o(we4xx),
	.sel_o(sel4xx),
	.adr_o(adr4xx),
	.dati_o(dati4xx),
	.sr_o(),
	.cr_o()
);

mpmc8_sync #(.W(C5W)) usyn5
(
	.clk(mem_ui_clk),
	.cs_i(cs5),
	.we_i(1'b0),
	.sel_i(sel5),
	.adr_i(adr5),
	.dati_i(dati5),
	.sr_i(1'b0),
	.cr_i(1'b0),
	.cs_o(cs5xx),
	.we_o(),
	.sel_o(sel5xx),
	.adr_o(adr5xx),
	.dati_o(dati5xx),
	.sr_o(),
	.cr_o()
);

mpmc8_sync #(.W(C6W)) usyn6
(
	.clk(mem_ui_clk),
	.cs_i(cs6),
	.we_i(we6),
	.sel_i(sel6),
	.adr_i(adr6),
	.dati_i(dati6),
	.sr_i(1'b0),
	.cr_i(1'b0),
	.cs_o(cs6xx),
	.we_o(we6xx),
	.sel_o(sel6xx),
	.adr_o(adr6xx),
	.dati_o(dati6xx),
	.sr_o(),
	.cr_o()
);

mpmc8_sync #(.W(C7R)) usyn7
(
	.clk(mem_ui_clk),
	.cs_i(cs7),
	.we_i(we7),
	.sel_i(sel7),
	.adr_i(adr7),
	.dati_i(dati7),
	.sr_i(sr7),
	.cr_i(cr7),
	.cs_o(cs7xx),
	.we_o(we7xx),
	.sel_o(sel7xx),
	.adr_o(adr7xx),
	.dati_o(dati7xx),
	.sr_o(sr7xx),
	.cr_o(cr7xx)
);

reg [23:0] rst_ctr;
always @(posedge clk100MHz)
if (rst_i)
	rst_ctr <= 24'd0;
else begin
	if (!rst_ctr[15])
		rst_ctr <= rst_ctr + 2'd1;
	rstn <= rst_ctr[15];
end

reg toggle;	// CPU1 / CPU0 priority toggle
reg toggle_sr;
reg [19:0] resv_to_cnt;
reg sr1x,sr7x;
reg [127:0] dati128;

// Detect cache hits on read caches
// For the sprite channel, reading the 64-bits of a strip not beginning at
// a 64-byte aligned paragraph only checks for the 64 bit address adr[5:3].
// It's assumed that a 4x128-bit strips were read the by the previous access.
// It's also assumed that the strip address won't match because there's more
// than one sprite and sprite accesses are essentially random.
wire ch0_taghit = cs0xx && !we0xx && ch0_hit;
wire ch1_taghit = ics1 && !we1xx && cs1xx && ch1_hit;
wire ch2_taghit = !we2xx && cs2xx && ch2_hit;
wire ch3_taghit = !we3xx && cs3xx && ch3_hit;
wire ch4_taghit = !we4xx && cs4xx && ch4_hit;
wire ch5_taghit = cs5xx && ch5_hit;
wire ch6_taghit = !we6xx && cs6xx && ch6_hit;
wire ch7_taghit = cs7xx && !we7xx && ch7_hit;

always_comb
begin
	sr1x = FALSE;
  if (ch1_taghit)
    sr1x = sr1xx;
end
always_comb
begin
	sr7x = FALSE;
  if (ch7_taghit)
    sr7x = sr7xx;
end

// Select the channel
mpmc8_ch_prioritize uchp1
(
	.clk(mem_ui_clk),
	.elevate(elevate),
	.cs0(cs0xx),
	.cs1(cs1xx),
	.cs2(cs2xx),
	.cs3(cs3xx),
	.cs4(cs4xx),
	.cs5(cs5xx),
	.cs6(cs6xx),
	.cs7(cs7xx),
	.we0(we0xx),
	.we1(we1xx),
	.we2(we2xx),
	.we3(we3xx),
	.we4(we4xx),
	.we5(1'b0),
	.we6(we6xx),
	.we7(we7xx),
	.ch0_taghit(ch0_taghit),
	.ch1_taghit(ch1_taghit),
	.ch2_taghit(ch2_taghit),
	.ch3_taghit(ch3_taghit),
	.ch4_taghit(ch4_taghit),
	.ch5_taghit(ch5_taghit),
	.ch6_taghit(ch6_taghit),
	.ch7_taghit(ch7_taghit),
	.ch(nch)
);


// This counter used to periodically reverse channel priorities to help ensure
// that a particular channel isn't permanently blocked by other higher priority
// ones.
always_ff @(posedge mem_ui_clk)
if (state==PRESET1) begin
	elevate_cnt <= elevate_cnt + 6'd1;
	elevate <= elevate_cnt == 6'd63;
end

always_ff @(posedge mem_ui_clk)
if (state==IDLE || (state==PRESET1 && do_wr))
	ch <= nch;

mpmc8_addr_select uadrs1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.ch(nch),
	.we0(we0xx),
	.we1(we1xx),
	.we2(we2xx),
	.we3(we3xx),
	.we4(we4xx),
	.we5(1'b0),
	.we6(we6xx),
	.we7(we7xx),
	.adr0(adr0xx),
	.adr1(adr1xx),
	.adr2(adr2xx),
	.adr3(adr3xx),
	.adr4(adr4xx),
	.adr5(adr5xx),
	.adr6(adr6xx),
	.adr7(adr7xx),
	.adr(adr)
);

wire [2:0] app_addr3;

mpmc8_addr_gen uagen1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_rdy),
	.num_strips(num_strips),
	.strip_cnt(req_strip_cnt),
	.addr_base(adr),
	.addr({app_addr3,app_addr})
);

mpmc8_waddr_gen uwadgen1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.valid(app_rd_data_valid),
	.num_strips(num_strips),
	.strip_cnt(resp_strip_cnt),
	.addr_base(adr),
	.addr(app_waddr)
);

// Setting the write mask
reg [15:0] wmask0;
reg [15:0] wmask1;
reg [15:0] wmask2;
reg [15:0] wmask3;
reg [15:0] wmask4;
reg [15:0] wmask5;
reg [15:0] wmask6;
reg [15:0] wmask7;

always_ff @(posedge mem_ui_clk)
	tMask(C0W,we0xx,{15'd0,sel0xx},adr0xx[3:0],wmask0);
always_ff @(posedge mem_ui_clk)
	tMask(C1W,we1xx,{15'd0,sel1xx},adr1xx[3:0],wmask1);
always_ff @(posedge mem_ui_clk)
	tMask(C2W,we2xx,{15'd0,sel2xx},adr2xx[3:0],wmask2);
always_ff @(posedge mem_ui_clk)
	tMask(C3W,we3xx,{15'd0,sel3xx},adr3xx[3:0],wmask3);
always_ff @(posedge mem_ui_clk)
	tMask(C4W,we4xx,{15'd0,sel4xx},adr4xx[3:0],wmask4);
always_ff @(posedge mem_ui_clk)
	tMask(C5W,1'b0,16'd0,4'h0,wmask5);
always_ff @(posedge mem_ui_clk)
	tMask(C6W,we6xx,{15'd0,sel6xx},adr6xx[3:0],wmask6);
always_ff @(posedge mem_ui_clk)
	tMask(C7W,we7xx,{15'd0,sel7xx},adr7xx[3:0],wmask7);

task tMask;
input [7:0] widi;
input wei;
input [15:0] seli;
input [3:0] adri;
output [15:0] masko;
begin
if (state==IDLE)
	if (wei) begin
		if (widi==8'd128)
			masko <= ~seli;
		else if (widi==8'd64)
			masko <= ~({8'd0,seli[7:0]} << {adri[3],3'b0});
		else if (widi==8'd32)
			masko <= ~({12'd0,seli[3:0]} << {adri[3:2],2'b0});
		else if (widi==8'd16)
			masko <= ~({14'd0,seli[1:0]} << {adri[3:1],1'b0});
		else
			masko <= ~({15'd0,seli[0]} << adri[3:0]);
	end
	else
		masko <= 16'h0000;	// read all bytes
end
endtask

// Setting the write data
// Repeat the data across lanes when less than 128-bit.
always_ff @(posedge mem_ui_clk)
if (state==IDLE) begin
	case(nch)
	3'd0:	dat128 <= {(128/C0W){dati0xx}};
	3'd1:	dat128 <= {(128/C1W){dati1xx}};
	3'd2:	dat128 <= {(128/C2W){dati2xx}};
	3'd3:	dat128 <= {(128/C3W){dati3xx}};
	3'd4:	dat128 <= {(128/C4W){dati4xx}};
	3'd5:	;	// channel is read-only
	3'd6:	dat128 <= {(128/C6W){dati6xx}};
	3'd7:	dat128 <= {(128/C7W){dati7xx}};
	default:	dat128 <= {2{dati7xx}};
	endcase
end

// Setting the data value. Unlike reads there is only a single strip involved.
// Force unselected byte lanes to $FF
wire [15:0] mem_wdf_mask2;
reg [127:0] dat128x;
genvar g;
generate begin : gMemData
	for (g = 0; g < 16; g = g + 1)
		always_comb
			if (mem_wdf_mask2[g])
				dat128x[g*8+7:g*8] = 8'hFF;
			else
				dat128x[g*8+7:g*8] = dat128[g*8+7:g*8];
end
endgenerate

always_ff @(posedge mem_ui_clk)
if (mem_ui_rst)
  app_wdf_data <= 128'd0;
else begin
	if (state==PRESET2)
		app_wdf_data <= dat128x;
	else if (state==WRITE_TRAMP1)
		app_wdf_data <= rmw_data;
end

generate begin : gRMW
for (g = 0; g < 16; g = g + 1) begin
	always_ff @(posedge mem_ui_clk)
	begin
		if (state==WRITE_TRAMP) begin
			if (app_wdf_mask[g])
				rmw_data[g*8+7:g*8] <= app_wdf_data[g*8+7:g*8];
			else
				rmw_data[g*8+7:g*8] <= app_rd_data[g*8+7:g*8];
		end
	end
end
end
endgenerate

always_ff @(posedge mem_ui_clk)
if (state==IDLE)
	spriteno_r <= spritenoxx;

// Setting burst length
mpmc8_set_num_strips usns1
(
	.clk(mem_ui_clk),
	.state(state),
	.ch(nch),
	.we0(we0xx),
	.we1(we1xx),
	.we2(we2xx),
	.we3(we3xx),
	.we4(we4xx),
	.we5(we5xx),
	.we6(we6xx),
	.we7(we7xx),
	.num_strips(num_strips)
);

// Setting the data mask. Values are enabled when the data mask is zero.
mpmc8_mask_select umsks1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.ch(ch),
	.wmask0(wmask0),
	.wmask1(wmask1),
	.wmask2(wmask2),
	.wmask3(wmask3),
	.wmask4(wmask4),
	.wmask5(wmask5),
	.wmask6(wmask6),
	.wmask7(wmask7),
	.mask(app_wdf_mask),
	.mask2(mem_wdf_mask2)
);

// Setting output data. Force output data to zero when not selected to allow
// wire-oring the data.
mpmc8_data_output udo1
(
	.clk0(clk0), .cs0(cs0), .adr0(adr0), .ch0_rdat(ch0_rdat), .dato0(dato0),
	.clk1(clk1), .cs1(cs1), .adr1(adr1), .ch1_rdat(ch1_rdat), .dato1(dato1),
	.clk2(clk2), .cs2(cs2), .adr2(adr2), .ch2_rdat(ch2_rdat), .dato2(dato2),
	.clk3(clk3), .cs3(cs3), .adr3(adr3), .ch3_rdat(ch3_rdat), .dato3(dato3),
	.clk4(clk4), .cs4(cs4), .adr4(adr4), .ch4_rdat(ch4_rdat), .dato4(dato4),
	.clk5(clk5), .cs5(cs5), .adr5(adr5), .ch5_rdat(ch5_rdat), .dato5(dato5),
	.clk6(clk6), .cs6(cs6), .adr6(adr6), .ch6_rdat(ch6_rdat), .dato6(dato6),
	.clk7(clk7), .cs7(cs7), .adr7(adr7), .ch7_rdat(ch7_rdat), .dato7(dato7)
);

mpmc8_ack_gen #(.N(0)) uackg0
(
	.rst(rst_i|mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.ch(ch),
	.cs(cs0),
	.adr(adr0xx),
	.cr(1'b0),
	.wr(do_wr),
	.to(tocnt[9]),
	.taghit(ch0_taghit),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.ack(acki0),
	.pre_ack(pre_ack0)
);

mpmc8_ack_gen #(.N(1)) uackg1
(
	.rst(rst_i|mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.ch(ch),
	.cs(cs1&ics1),
	.adr(adr1xx),
	.cr(cr1xx),
	.wr(do_wr),
	.to(tocnt[9]),
	.taghit(ch1_taghit),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.ack(acki1),
	.pre_ack(pre_ack1)
);

mpmc8_ack_gen #(.N(2)) uackg2
(
	.rst(rst_i|mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.ch(ch),
	.cs(cs2),
	.adr(adr2xx),
	.cr(1'b0),
	.wr(do_wr),
	.to(tocnt[9]),
	.taghit(ch2_taghit),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.ack(acki2),
	.pre_ack(pre_ack2)
);

mpmc8_ack_gen #(.N(3)) uackg3
(
	.rst(rst_i|mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.ch(ch),
	.cs(cs3),
	.adr(adr3xx),
	.cr(1'b0),
	.wr(do_wr),
	.to(tocnt[9]),
	.taghit(ch3_taghit),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.ack(acki3),
	.pre_ack(pre_ack3)
);

mpmc8_ack_gen #(.N(4)) uackg4
(
	.rst(rst_i|mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.ch(ch),
	.cs(cs4),
	.adr(adr4xx),
	.cr(1'b0),
	.wr(do_wr),
	.to(tocnt[9]),
	.taghit(ch4_taghit),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.ack(acki4),
	.pre_ack(pre_ack4)
);

mpmc8_ack_gen #(.N(5)) uackg5
(
	.rst(rst_i|mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.ch(ch),
	.cs(cs5),
	.adr(adr5xx),
	.cr(1'b0),
	.wr(do_wr),
	.to(tocnt[9]),
	.taghit(ch5_taghit),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.ack(acki5),
	.pre_ack(pre_ack5)
);

mpmc8_ack_gen #(.N(6)) uackg6
(
	.rst(rst_i|mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.ch(ch),
	.cs(cs6),
	.adr(adr6xx),
	.cr(1'b0),
	.wr(do_wr),
	.to(tocnt[9]),
	.taghit(ch6_taghit),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.ack(acki6),
	.pre_ack(pre_ack6)
);

mpmc8_ack_gen #(.N(7)) uackg7
(
	.rst(rst_i|mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.ch(ch),
	.cs(ics7),
	.adr(adr7xx),
	.cr(cr7xx),
	.wr(do_wr),
	.to(tocnt[9]),
	.taghit(ch7_taghit),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.ack(acki7),
	.pre_ack(pre_ack7)
);

wire ne_data_valid;
edge_det ued1 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(app_rd_data_valid), .pe(), .ne(ne_data_valid), .ee());

mpmc8_state_machine ustmac1
(
	.rst(rst_i|mem_ui_rst),
	.clk(mem_ui_clk),
	.ch(nch), 
	.acki0(acki0),
	.acki1(acki1),
	.acki2(acki2),
	.acki3(acki3),
	.acki4(acki4),
	.acki5(acki5),
	.acki6(acki6),
	.acki7(acki7),
	.ch0_taghit(ch0_taghit),
	.ch1_taghit(ch1_taghit),
	.ch2_taghit(ch2_taghit),
	.ch3_taghit(ch3_taghit),
	.ch4_taghit(ch4_taghit),
	.ch5_taghit(ch5_taghit),
	.ch6_taghit(ch6_taghit),
	.ch7_taghit(ch7_taghit),
	.wdf_rdy(app_wdf_rdy),
	.rdy(app_rdy),
	.do_wr(do_wr),
	.rd_data_valid(app_rd_data_valid),
	.num_strips(num_strips),
	.req_strip_cnt(req_strip_cnt),
	.resp_strip_cnt(resp_strip_cnt),
	.to(tocnt[9]),
	.cr1(cr1xx),
	.cr7(cr7xx),
	.adr1(adr1xx),
	.adr7(adr7xx),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.state(state)
);


wire [3:0] prev_state;

mpmc8_to_cnt utoc1
(
	.clk(mem_ui_clk),
	.state(state),
	.prev_state(prev_state),
	.to_cnt(tocnt)
);

mpmc8_prev_state upst1
(
	.clk(mem_ui_clk),
	.state(state),
	.prev_state(prev_state)
);

mpmc8_app_en_gen ueng1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_rdy),
	.strip_cnt(req_strip_cnt),
	.num_strips(num_strips),
	.en(app_en)
);

mpmc8_app_cmd_gen ucg1
(
	.clk(mem_ui_clk),
	.state(state),
	.cmd(app_cmd)
);

mpmc8_app_wdf_wren_gen uwreng1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_wdf_rdy),
	.wren(app_wdf_wren)
);

mpmc8_app_wdf_end_gen uwendg1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_wdf_rdy),
	.wend(app_wdf_end)
);

mpmc8_req_strip_cnt ursc1
(
	.clk(mem_ui_clk),
	.state(state),
	.wdf_rdy(app_wdf_rdy),
	.rdy(app_rdy),
	.num_strips(num_strips),
	.strip_cnt(req_strip_cnt)
);

mpmc8_resp_strip_cnt urespsc1
(
	.clk(mem_ui_clk),
	.state(state),
	.valid(app_rd_data_valid),
	.num_strips(num_strips),
	.strip_cnt(resp_strip_cnt)
);


mpmc8_do_wr udowr0
(
	.we(we0xx),
	.cr(1'b0),
	.adr(adr0xx),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.do_wr(do_wr0)
);

mpmc8_do_wr udowr1
(
	.we(we1xx),
	.cr(cr1xx),
	.adr(adr1xx),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.do_wr(do_wr1)
);

mpmc8_do_wr udowr2
(
	.we(we2xx),
	.cr(1'b0),
	.adr(adr2xx),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.do_wr(do_wr2)
);

mpmc8_do_wr udowr3
(
	.we(we3xx),
	.cr(1'b0),
	.adr(adr3xx),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.do_wr(do_wr3)
);

mpmc8_do_wr udowr4
(
	.we(we4xx),
	.cr(1'b0),
	.adr(adr4xx),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.do_wr(do_wr4)
);

mpmc8_do_wr udowr5
(
	.we(1'b0),
	.cr(1'b0),
	.adr(adr5xx),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.do_wr(do_wr5)
);

mpmc8_do_wr udowr6
(
	.we(we6xx),
	.cr(1'b0),
	.adr(adr6xx),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.do_wr(do_wr6)
);

mpmc8_do_wr udowr7
(
	.we(we7xx),
	.cr(cr7xx),
	.adr(adr7xx),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.do_wr(do_wr7)
);

mpmc8_do_wr_select udws1
(
	.clk(mem_ui_clk),
	.state(state),
	.ch(nch),
	.wr0(do_wr0),
	.wr1(do_wr1),
	.wr2(do_wr2),
	.wr3(do_wr3),
	.wr4(do_wr4),
	.wr5(do_wr5),
	.wr6(do_wr6),
	.wr7(do_wr7),
	.wr(do_wr)
);

// Reservation status bit
mpmc8_resv_bit ursb1
(
	.clk(mem_ui_clk),
	.state(state),
	.cs(cs1xx),
	.we(we1xx),
	.ack(acki1),
	.cr(cr1xx),
	.adr(adr1xx),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.rb(rb1)
);

mpmc8_resv_bit ursb7
(
	.clk(mem_ui_clk),
	.state(state),
	.cs(cs7xx),
	.we(we7xx),
	.ack(acki7),
	.cr(cr7xx),
	.adr(adr7xx),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.rb(rb7)
);

// Managing address reservations
mpmc8_addr_resv_man uarman1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.cs1(cs1xx),
	.ack1(acki1),
	.we1(we1xx),
	.adr1(adr1xx),
	.sr1(sr1x),
	.cr1(cr1xx),
	.ch1_taghit(ch1_taghit),
	.cs7(cs7xx),
	.ack7(acki7),
	.we7(we7xx),
	.adr7(adr7xx),
	.sr7(sr7x),
	.cr7(cr7xx),
	.ch7_taghit(ch7_taghit),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr)
);

endmodule
