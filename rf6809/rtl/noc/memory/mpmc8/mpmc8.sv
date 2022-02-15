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
output reg rb1;

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
output reg rb7;

// MIG interface signals
input mem_ui_rst;
input mem_ui_clk;
input calib_complete;
output rstn;
output [AMSB:0] app_addr;
output [2:0] app_cmd;
output reg app_en;
output reg [127:0] app_wdf_data;
output reg [15:0] app_wdf_mask;
output app_wdf_end;
output app_wdf_wren;
input [127:0] app_rd_data;
input app_rd_data_valid;
input app_rd_data_end;
input app_rdy;
input app_wdf_rdy;

// Debugging
output reg [3:0] ch;
output reg [3:0] state;
reg [3:0] next_state;

integer n;
integer n1;
integer n2;

wire [31:0] app_waddr;
wire [31:0] adr;
reg [127:0] dat128;
reg [15:0] wmask;
reg [127:0] rmw_data;

reg [3:0] nch;
reg do_wr;
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

// For address reservation below
reg [7:0] match;
always @(posedge mem_ui_clk)
if (rst_i)
	match <= 8'h00;
else begin
	if (match >= NAR)
		match <= 8'h00;
	else
		match <= match + 8'd1;
end

// Cross clock domain signals
reg cs0xx;
reg we0xx;
reg [C0W/8-1:0] sel0xx;
reg [31:0] adr0xx;
reg [C0W-1:0] dati0xx;

reg cs1xx;
reg we1xx;
reg [15:0] sel1xx;
reg [31:0] adr1xx;
reg [127:0] dati1xx;
reg sr1xx;
reg cr1xx;

reg cs2xx;
reg we2xx;
reg [C2W/8-1:0] sel2xx;
reg [31:0] adr2xx;
reg [C2W-1:0] dati2xx;

reg cs3xx;
reg we3xx;
reg [C3W/8-1:0] sel3xx;
reg [31:0] adr3xx;
reg [C3W-1:0] dati3xx;

reg cs4xx;
reg we4xx;
reg [C4W/8-1:0] sel4xx;
reg [31:0] adr4xx;
reg [C4W-1:0] dati4xx;

reg cs5xx;
reg we5xx;
reg [C5W/8-1:0] sel5xx;
reg [31:0] adr5xx;
reg [C5W-1:0] dati5xx;
reg [5:0] spritenoxx;

reg cs6xx;
reg we6xx;
reg [C6W/8-1:0] sel6xx;
reg [31:0] adr6xx;
reg [C6W-1:0] dati6xx;

reg cs7xx;
reg we7xx;
reg [C7W/8-1:0] sel7xx;
reg [31:0] adr7xx;
reg [C7W-1:0] dati7xx;
reg sr7xx;
reg cr7xx;

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

wire [127:0] ch0_rdat;
wire [127:0] ch1_rdat;
wire [127:0] ch2_rdat;
wire [127:0] ch3_rdat;
wire [127:0] ch4_rdat;
wire [127:0] ch5_rdat;
wire [127:0] ch6_rdat;
wire [127:0] ch7_rdat;
wire ch0_hit, ch1_hit, ch2_hit, ch3_hit;
wire ch4_hit, ch5_hit, ch6_hit, ch7_hit;
wire ch0_hitd, ch1_hitd, ch2_hitd, ch3_hitd;
wire ch4_hitd, ch5_hitd, ch6_hitd, ch7_hitd;

mpmc8_read_cache rc0 (
	.rst(rst_i),
	.wclk(mem_ui_clk),
	.wr(app_rd_data_valid && !(ch==4'd0 || ch==4'd3 || ch==4'd5)),
	.wadr({app_waddr[31:4],4'h0}),
	.wdat(app_rd_data),
	.inv(state==WRITE_DATA0),
	.rclk0(1'b0),
	.radr0(32'h0),
	.rdat0(),
	.hit0(),
	.rclk1(clk1),
	.radr1({adr1[31:4],4'h0}),
	.rdat1(ch1_rdat),
	.hit1(ch1_hit),
	.rclk2(clk2),
	.radr2({adr2[31:4],4'h0}),
	.rdat2(ch2_rdat),
	.hit2(ch2_hit),
	.rclk3(1'b0),
	.radr3(32'd0),
	.rdat3(),
	.hit3(),
	.rclk4(clk4),
	.radr4({adr4[31:4],4'h0}),
	.rdat4(ch4_rdat),
	.hit4(ch4_hit),
	.rclk5(1'b0),
	.radr5(32'h0),
	.rdat5(),
	.hit5(),
	.rclk6(clk6),
	.radr6({adr6[31:4],4'h0}),
	.rdat6(ch6_rdat),
	.hit6(ch6_hit),
	.rclk7(clk7),
	.radr7({adr7[31:4],4'h0}),
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
	.rclk(clk0),
	.radr({adr0[31:4],4'h0}),
	.rdat(ch0_rdat),
	.hit(ch0_hit)
);

mpmc8_strm_read_cache ustrm3
(
	.rst(rst_i),
	.wclk(mem_ui_clk),
	.wr(ch==4'd3 && app_rd_data_valid),
	.wadr({app_waddr[31:4],4'h0}),
	.wdat(app_rd_data),
	.inv(1'b0),
	.rclk(clk3),
	.radr({adr3[31:4],4'h0}),
	.rdat(ch3_rdat),
	.hit(ch3_hit)
);

mpmc8_strm_read_cache ustrm5
(
	.rst(rst_i),
	.wclk(mem_ui_clk),
	.wr(ch==4'd5 && app_rd_data_valid),
	.wadr({app_waddr[31:4],4'h0}),
	.wdat(app_rd_data),
	.inv(1'b0),
	.rclk(clk5),
	.radr({adr5[31:4],4'h0}),
	.rdat(ch5_rdat),
	.hit(ch5_hit)
);

// Register signals onto mem_ui_clk domain
always_ff @(posedge mem_ui_clk)
begin
	cs0xx <= cs0;
	we0xx <= we0;
	sel0xx <= sel0;
	adr0xx <= adr0;
	dati0xx <= dati0;
end

always_ff @(posedge mem_ui_clk)
begin
	cs1xx <= ics1;
	we1xx <= we1;
	sel1xx <= sel1;
	adr1xx <= adr1;
	dati1xx <= dati1;
	sr1xx <= sr1;
	cr1xx <= cr1;
end

always_ff @(posedge mem_ui_clk)
begin
	cs2xx <= cs2;
	we2xx <= we2;
	sel2xx <= sel2;
	adr2xx <= adr2;
	dati2xx <= dati2;
end

always_ff @(posedge mem_ui_clk)
begin
	cs3xx <= cs3;
	we3xx <= we3;
	sel3xx <= sel3;
	adr3xx <= adr3;
	dati3xx <= dati3;
end

always_ff @(posedge mem_ui_clk)
begin
	cs4xx <= cs4;
	we4xx <= we4;
	sel4xx <= sel4;
	adr4xx <= adr4;
	dati4xx <= dati4;
end

always_ff @(posedge mem_ui_clk)
begin
	cs5xx <= cs5;
	sel5xx <= sel5;
	adr5xx <= adr5;
	spritenoxx <= spriteno;
end

always_ff @(posedge mem_ui_clk)
begin
	cs6xx <= cs6;
	we6xx <= we6;
	sel6xx <= sel6;
	adr6xx <= adr6;
	dati6xx <= dati6;
end

always_ff @(posedge mem_ui_clk)
begin
	cs7xx <= ics7;
	we7xx <= we7;
	sel7xx <= sel7;
	adr7xx <= adr7;
	dati7xx <= dati7;
	sr7xx <= sr7;
	cr7xx <= cr7;
end

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

// There is an additional cycle to shift the data into place after reading from
// the cache. Delay the hit status a couple of cycles,
ft_delay #(.WID(8), .DEP(2)) udly1
(
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i({ch0_hit,ch1_hit,ch2_hit,ch3_hit,ch4_hit,ch5_hit,ch6_hit,ch7_hit}),
	.o({ch0_hitd,ch1_hitd,ch2_hitd,ch3_hitd,ch4_hitd,ch5_hitd,ch6_hitd,ch7_hitd})
); 

// Detect cache hits on read caches
// For the sprite channel, reading the 64-bits of a strip not beginning at
// a 64-byte aligned paragraph only checks for the 64 bit address adr[5:3].
// It's assumed that a 4x128-bit strips were read the by the previous access.
// It's also assumed that the strip address won't match because there's more
// than one sprite and sprite accesses are essentially random.
wire ch0_taghit = cs0xx && !we0xx && ch0_hitd;
wire ch1_taghit = ics1 && !we1xx && cs1xx && ch1_hitd;
wire ch2_taghit = !we2xx && cs2xx && ch2_hitd;
wire ch3_taghit = !we3xx && cs3xx && ch3_hitd;
wire ch4_taghit = !we4xx && cs4xx && ch4_hitd;
wire ch5_taghit = cs5xx && ch5_hitd;
wire ch6_taghit = !we6xx && cs6xx && ch6_hitd;
wire ch7_taghit = cs7xx && !we7xx && ch7_hitd;

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
// This prioritizes the channel during the IDLE state.
// During an elevate cycle the channel priorities are reversed.
always_ff @(posedge mem_ui_clk)
begin
	if (elevate) begin
		if (cs7xx & we7xx)
			nch <= 3'd7;
		else if (cs6xx & we6xx)
			nch <= 3'd6;
		else if (cs5xx & we5xx)
			nch <= 3'd5;
		else if (cs4xx & we4xx)
			nch <= 3'd4;
		else if (cs3xx & we3xx)
			nch <= 3'd3;
		else if (cs2xx & we2xx)
			nch <= 3'd2;
		else if (cs1xx & we1xx)
			nch <= 3'd1;
		else if (cs0xx & we0xx)
			nch <= 3'd0;
		else if (cs7xx & ~ch7_taghit)
			nch <= 3'd7;
		else if (cs6xx & ~ch6_taghit)
			nch <= 3'd6;
		else if (cs5xx & ~ch5_taghit)
			nch <= 3'd5;
		else if (cs4xx & ~ch4_taghit)
			nch <= 3'd4;
		else if (cs3xx & ~ch3_taghit)
			nch <= 3'd3;
		else if (cs2xx & ~ch2_taghit)
			nch <= 3'd2;
		else if (cs1xx & ~ch1_taghit)
			nch <= 3'd1;
		else if (cs0xx & ~ch0_taghit)
			nch <= 3'd0;
		else
			nch <= 4'hF;
	end
	// Channel 0 read or write takes precedence
	else if (cs0xx & we0xx)
		nch <= 3'd0;
	else if (cs0xx & ~ch0_taghit)
		nch <= 3'd0;
	else if (cs1xx & we1xx)
		nch <= 3'd1;
	else if (cs2xx & we2xx)
		nch <= 3'd2;
	else if (cs3xx & we3xx)
		nch <= 3'd3;
	else if (cs4xx & we4xx)
		nch <= 3'd4;
	else if (cs6xx & we6xx)
		nch <= 3'd6;
	else if (cs7xx & we7xx)
		nch <= 3'd7;
	// Reads, writes detected above
	else if (cs1xx & ~ch1_taghit)
		nch <= 3'd1;
	else if (cs2xx & ~ch2_taghit)
		nch <= 3'd2;
	else if (cs3xx & ~ch3_taghit)
		nch <= 3'd3;
	else if (cs4xx & ~ch4_taghit)
		nch <= 3'd4;
	else if (cs5xx & ~ch5_taghit)
		nch <= 3'd5;
	else if (cs6xx & ~ch6_taghit)
		nch <= 3'd6;
	else if (cs7xx & ~ch7_taghit)
		nch <= 3'd7;
	// Nothing selected
	else
		nch <= 4'hF;
end

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
reg [15:0] mem_wdf_mask2;
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
always_ff @(posedge mem_ui_clk)
if (state==IDLE) begin
	num_strips <= 3'd0;
	case(nch)
	3'd0:	if (!we0xx) num_strips <= 3'd7;		//7
	3'd1:	if (!we1xx)	num_strips <= 3'd1;		//1
	3'd2:	;
	3'd3:	;
	3'd4:	;
	3'd5:	num_strips <= 3'd3;	//3
	3'd6:	;
	3'd7:	if (!we7xx) num_strips <= 3'd3;
	default:	;
	endcase
end

// Setting the data mask. Values are enabled when the data mask is zero.
always_ff @(posedge mem_ui_clk)
if (mem_ui_rst)
  mem_wdf_mask2 <= 16'h0000;
else begin
	if (state==PRESET1)
		case(ch)
		3'd0:	mem_wdf_mask2 <= wmask0;
		3'd1:	mem_wdf_mask2 <= wmask1;
		3'd2:	mem_wdf_mask2 <= wmask2;
		3'd3:	mem_wdf_mask2 <= wmask3;
		3'd4:	mem_wdf_mask2 <= wmask4;
		3'd5:	mem_wdf_mask2 <= wmask5;
		3'd6:	mem_wdf_mask2 <= wmask6;
		3'd7:	mem_wdf_mask2 <= wmask7;
		default:	mem_wdf_mask2 <= 16'h0000;
		endcase
	// For RMW cycle all bytes are writtten.
	else if (state==WRITE_TRAMP1)
		mem_wdf_mask2 <= 16'h0000;
end
always_ff @(posedge mem_ui_clk)
if (mem_ui_rst)
  app_wdf_mask <= 16'h0000;
else begin
	if (state==PRESET2)
		app_wdf_mask <= mem_wdf_mask2;
end

// Setting output data. Force output data to zero when not selected to allow
// wire-oring the data.
always_ff @(posedge clk0)
`ifdef RED_SCREEN
if (cs0) begin
	if (C0W==128)
		dato0 <= 128'h7C007C007C007C007C007C007C007C00;
	else if (C0W==64)
		dato0 <= 64'h7C007C007C007C00;
	else if (C0W==32)
		dato0 <= 32'h7C007C00;
	else if (C0W==16)
		dato0 <= 16'h7C00;
	else
		dato0 <= 8'hE0;
end
else
	dato0 <= {C0W{1'b0}};
`else
	tDato(C0W,cs0,adr0[3:0],ch0_rdat,dato0);
`endif

always_ff @(posedge clk1)
	tDato(C1W,cs1,adr1[3:0],ch1_rdat,dato1);
always_ff @(posedge clk2)
	tDato(C2W,cs2,adr2[3:0],ch2_rdat,dato2);
always_ff @(posedge clk3)
	tDato(C3W,cs3,adr3[3:0],ch3_rdat,dato3);
always_ff @(posedge clk4)
	tDato(C4W,cs4,adr4[3:0],ch4_rdat,dato4);
always_ff @(posedge clk5)
	tDato(C5W,cs5,adr5[3:0],ch5_rdat,dato5);
always_ff @(posedge clk6)
	tDato(C6W,cs6,adr6[3:0],ch6_rdat,dato6);
always_ff @(posedge clk7)
	tDato(C7R,cs7,adr7[3:0],ch7_rdat,dato7);

task tDato;
input [7:0] widi;
input csi;
input [3:0] adri;
input [127:0] dati;
output [127:0] dato;
begin
if (csi) begin
	if (widi==8'd128)
		dato <= dati;
	else if (widi==8'd64)
		dato <= dati >> {adri[3],6'h0};
	else if (widi==8'd32)
		dato <= dati >> {adri[3:2],5'h0};
	else if (widi==8'd16)
		dato <= dati >> {adri[3:1],4'h0};
	else
		dato <= dati >> {adri[3:0],3'h0};
end
else
	dato <= 'b0;
end
endtask

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
	.ack(acki0)
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
	.ack(acki1)
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
	.ack(acki2)
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
	.ack(acki3)
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
	.ack(acki4)
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
	.ack(acki5)
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
	.ack(acki6)
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
	.ack(acki7)
);

wire ne_data_valid;
edge_det ued1 (.rst(rst_i), .clk(mem_ui_clk), .ce(1'b1), .i(app_rd_data_valid), .pe(), .ne(ne_data_valid), .ee());

// State machine
always_ff @(posedge mem_ui_clk)
	state <= next_state;

reg xit_rd_cmd;
always_comb
begin
	xit_rd_cmd = FALSE;
	if (app_rdy == TRUE) begin
		if (req_strip_cnt==num_strips)
			xit_rd_cmd = TRUE;
	end
  if (app_rd_data_valid) begin
  	if (resp_strip_cnt==num_strips)
  		xit_rd_cmd = TRUE;
	end
end

integer n3;
always_comb
if (rst_i|mem_ui_rst)
	next_state <= IDLE;
else begin
case(state)
IDLE:
	begin
		next_state <= IDLE;
	  // According to the docs there's no need to wait for calib complete.
	  // Calib complete goes high in sim about 111 us.
	  // Simulation setting must be set to FAST.
		//if (calib_complete)
		case(nch)
		3'd0:	if (!acki0) next_state <= PRESET1;
		3'd1:
			if (!acki1) begin
		    if (cr1xx) begin
	        next_state <= IDLE;
		    	for (n3 = 0; n3 < NAR; n3 = n3 + 1)
	        	if ((resv_ch[n3]==4'd1) && (resv_adr[n3][31:4]==adr1xx[31:4]))
	          	next_state <= PRESET1;
		    end
		    else
	        next_state <= PRESET1;
	    end
		3'd2:	if (!acki2) next_state <= PRESET1;
		3'd3:	if (!acki3) next_state <= PRESET1;
		3'd4:	if (!acki4) next_state <= PRESET1;
		3'd5:	if (!acki5) next_state <= PRESET1;
		3'd6:	if (!acki6) next_state <= PRESET1;
		3'd7:
			if (!acki7) begin
		    if (cr7xx) begin
	        next_state <= IDLE;
		    	for (n3 = 0; n3 < NAR; n3 = n3 + 1)
		        if ((resv_ch[n3]==4'd7) && (resv_adr[n3][31:4]==adr7xx[31:4]))
	            next_state <= PRESET1;
		    end
		    else
	        next_state <= PRESET1;
	    end
		default:	;	// no channel selected -> stay in IDLE state
		endcase
	end
// If an ack is received during a preset cycle it is likely a read cycle that
// acked a cycle late. Abort the cycle.
PRESET1:
	case(ch)
	4'd0:	if (ch0_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd1:	if (ch1_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd2:	if (ch2_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd3:	if (ch3_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd4:	if (ch4_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd5:	if (ch5_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd6:	if (ch6_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd7:	if (ch7_taghit) next_state <= IDLE; else next_state <= PRESET2;
	default:	next_state <= PRESET2;
	endcase
// The valid data, data mask and address are placed in app_wdf_data, app_wdf_mask,
// and memm_addr ahead of time.
PRESET2:
	case(ch)
	4'd0:	if (ch0_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd1:	if (ch1_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd2:	if (ch2_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd3:	if (ch3_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd4:	if (ch4_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd5:	if (ch5_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd6:	if (ch6_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd7:	if (ch7_taghit) next_state <= IDLE; else next_state <= PRESET3;
	default:	next_state <= PRESET3;
	endcase
// PRESET3 determines the read or write command
PRESET3:
	if (do_wr && !RMW)
		next_state <= WRITE_DATA0;
	else begin
		next_state <= READ_DATA0;
		case(ch)
		4'd0:	if (ch0_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd1:	if (ch1_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd2:	if (ch2_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd3:	if (ch3_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd4:	if (ch4_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd5:	if (ch5_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd6:	if (ch6_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd7:	if (ch7_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		default:	next_state <= READ_DATA0;
		endcase
	end

// Write data to the data fifo
// Write occurs when app_wdf_wren is true and app_wdf_rdy is true
WRITE_DATA0:
	// Issue a write command if the fifo is full.
//	if (!app_wdf_rdy)
//		next_state <= WRITE_DATA1;
//	else 
	if (app_wdf_rdy)// && req_strip_cnt==num_strips)
		next_state <= WRITE_DATA1;
	else
		next_state <= WRITE_DATA0;
WRITE_DATA1:
	next_state <= WRITE_DATA2;
WRITE_DATA2:
	if (app_rdy)
		next_state <= WRITE_DATA3;
	else
		next_state <= WRITE_DATA2;
WRITE_DATA3:
	next_state <= IDLE;
	/*
	if (req_strip_cnt==num_strips)
		next_state <= IDLE;
	else
		next_state <= WRITE_DATA0;
	*/
// There could be multiple read requests submitted before any response occurs.
// Stay in the SET_CMD_RD until all requested strips have been processed.
READ_DATA0:
	next_state <= READ_DATA1;
// Could it take so long to do the request that we start getting responses
// back?
READ_DATA1:
	if (app_rdy && req_strip_cnt==num_strips)
		next_state <= READ_DATA2;
	else
		next_state <= READ_DATA1;
// Wait for incoming responses, but only for so long to prevent a hang.
READ_DATA2:
	if (app_rd_data_valid && resp_strip_cnt==num_strips)
		next_state <= WAIT_NACK;
	else
		next_state <= READ_DATA2;

WAIT_NACK:
	// If we're not seeing a nack and there is a channel selected, then the
	// cache tag must not have updated correctly.
	// For writes, assume a nack by now.
	next_state <= IDLE;
	/*
	case(ch)
	3'd0:	if (ne_acki0) next_state <= IDLE;
	3'd1:	if (ne_acki1) next_state <= IDLE;
	3'd2:	if (ne_acki2) next_state <= IDLE;
	3'd3:	if (ne_acki3) next_state <= IDLE;
	3'd4:	if (ne_acki4) next_state <= IDLE;
	3'd5:	if (ne_acki5) next_state <= IDLE;
	3'd6:	if (ne_acki6) next_state <= IDLE;
	3'd7:	if (ne_acki7) next_state <= IDLE;
	default:	next_state <= IDLE;
	endcase
	*/
default:	next_state <= IDLE;
endcase


// Is the state machine hung?
if (tocnt[9])
	next_state <= IDLE;
end

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

// Write operation indicator
integer n4;
always_ff @(posedge mem_ui_clk)
begin
	if (state==IDLE) begin
		do_wr <= FALSE;
		case(nch)
		3'd0:	do_wr <= we0xx;
		3'd1:
			if (we1xx) begin
			    if (cr1xx) begin
			    	for (n4 = 0; n4 < NAR; n4 = n4 + 1)
			        if ((resv_ch[n4]==4'd1) && (resv_adr[n4][31:4]==adr1xx[31:4]))
		            do_wr <= TRUE;
			    end
			    else
		        do_wr <= TRUE;
			end
		3'd2:	do_wr <= we2;
		3'd3:	do_wr <= we3;
		3'd4:	do_wr <= we4;
		3'd6:	do_wr <= we6;
		3'd7:
			if (we7xx) begin
			    if (cr7xx) begin
			    	for (n4 = 0; n4 < NAR; n4 = n4 + 1)
			        if ((resv_ch[n4]==4'd7) && (resv_adr[n4][31:4]==adr7xx[31:4]))
		            do_wr <= TRUE;
			    end
			    else
		        do_wr <= TRUE;
			end
	    default:	;
	    endcase
	end
end

// Reservation status bit
integer n5;
always_ff @(posedge mem_ui_clk)
if (state==IDLE) begin
  if (cs1xx & we1xx & ~acki1) begin
    if (cr1xx) begin
      rb1 <= FALSE;
    	for (n5 = 0; n5 < NAR; n5 = n5 + 1)
	      if ((resv_ch[n5]==4'd1) && (resv_adr[n5][31:4]==adr1xx[31:4]))
  	      rb1 <= TRUE;
    end
  end
end

integer n6;
always_ff @(posedge mem_ui_clk)
if (state==IDLE) begin
  if (cs7xx & we7xx & ~acki7) begin
    if (cr7xx) begin
      rb7 <= FALSE;
    	for (n6 = 0; n6 < NAR; n6 = n6 + 1)
	      if ((resv_ch[n6]==4'd7) && (resv_adr[n6][31:4]==adr7xx[31:4]))
  	      rb7 <= TRUE;
    end
  end
end

// Managing address reservations
integer n7;
always_ff @(posedge mem_ui_clk)
if (mem_ui_rst) begin
	resv_to_cnt <= 20'd0;
	toggle <= FALSE;
	toggle_sr <= FALSE;
 	for (n7 = 0; n7 < NAR; n7 = n7 + 1)
		resv_ch[n7] <= 4'hF;
end
else begin
	resv_to_cnt <= resv_to_cnt + 20'd1;

	if (sr1x & sr7x) begin
		if (toggle_sr) begin
			reserve_adr(4'h1,adr1xx);
			toggle_sr <= 1'b0;
		end
		else begin
			reserve_adr(4'h7,adr7xx);
			toggle_sr <= 1'b1;
		end
	end
	else begin
		if (sr1x)
			reserve_adr(4'h1,adr1xx);
		if (sr7x)
			reserve_adr(4'h7,adr7xx);
	end

	if (state==IDLE) begin
		if (cs1xx & we1xx & ~acki1) begin
		    toggle <= 1'b1;
		    if (cr1xx) begin
		    	for (n7 = 0; n7 < NAR; n7 = n7 + 1)
		        if ((resv_ch[n7]==4'd1) && (resv_adr[n7][31:4]==adr1xx[31:4]))
		            resv_ch[n7] <= 4'hF;
		    end
		end
		else if (cs7xx & we7xx & ~acki7) begin
		    toggle <= 1'b1;
		    if (cr7xx) begin
		    	for (n7 = 0; n7 < NAR; n7 = n7 + 1)
		        if ((resv_ch[n7]==4'd7) && (resv_adr[n7][31:4]==adr7xx[31:4]))
		            resv_ch[n7] <= 4'hF;
		    end
		end
		else if (!we1xx & cs1xx & ~ch1_taghit & (cs7xx ? toggle : 1'b1))
			toggle <= 1'b0;
		else if (!we7xx & cs7xx & ~ch7_taghit)
			toggle <= 1'b1;
	end
end

integer empty_resv;
function resv_held;
input [3:0] ch;
input [31:0] adr;
integer n8;
begin
	resv_held = FALSE;
 	for (n8 = 0; n8 < NAR; n8 = n8 + 1)
 		if (resv_ch[n8]==ch && resv_adr[n8]==adr)
 			resv_held = TRUE;
end
endfunction

// Find an empty reservation bucket
integer n9;
always_comb
begin
	empty_resv <= -1;
 	for (n9 = 0; n9 < NAR; n9 = n9 + 1)
		if (resv_ch[n9]==4'hF)
			empty_resv <= n9;
end

// Two reservation buckets are allowed for. There are two (or more) CPU's in the
// system and as long as they are not trying to control the same resource (the
// same semaphore) then they should be able to set a reservation. Ideally there
// could be more reservation buckets available, but it starts to be a lot of
// hardware.
task reserve_adr;
input [3:0] ch;
input [31:0] adr;
begin
	// Ignore an attempt to reserve an address that's already reserved. The LWAR
	// instruction is usually called in a loop and we don't want it to use up
	// all address reservations.
	if (!resv_held(ch,adr)) begin
		if (empty_resv >= 0) begin
			resv_ch[empty_resv] <= ch;
			resv_adr[empty_resv] <= adr;
		end
		// Here there were no free reservation buckets, so toss one of the
		// old reservations out.
		else begin
			resv_ch[match] <= ch;
			resv_adr[match] <= adr;
		end
	end
end
endtask

endmodule
