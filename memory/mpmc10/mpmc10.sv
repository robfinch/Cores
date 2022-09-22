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
// 12000 LUTs, BRAM
// ============================================================================
//
//`define RED_SCREEN	1'b1

import mpmc10_pkg::*;

module mpmc10(
input rst,
input mem_ui_rst,
input mem_ui_clk,
output [31:0] app_waddr,
input app_rdy,
output app_en,
output [2:0] app_cmd,
output [28:0] app_addr,
input app_rd_data_valid,
output [15:0] app_wdf_mask,
output reg [127:0] app_wdf_data,
input app_wdf_rdy,
output app_wdf_wren,
input [127:0] app_rd_data,
input ch0clk, ch1clk, ch2clk, ch3clk, ch4clk, ch5clk, ch6clk, ch7clk,
input axi_request_readwrite128_t ch0i,
output axi_response_readwrite128_t ch0o,
input axi_request_readwrite256_t ch1i,
output axi_response_readwrite256_t ch1o,
input axi_request_readwrite256_t ch2i,
output axi_response_readwrite256_t ch2o,
input axi_request_readwrite256_t ch3i,
output axi_response_readwrite256_t ch3o,
input axi_request_readwrite256_t ch4i,
output axi_response_readwrite256_t ch4o,
input axi_request_readwrite256_t ch5i,
output axi_response_readwrite256_t ch5o,
input axi_request_readwrite256_t ch6i,
output axi_response_readwrite256_t ch6o,
input axi_request_readwrite256_t ch7i,
output axi_response_readwrite256_t ch7o
);
parameter NAR = 2;

axi_request_readwrite128_t ch0is;
axi_request_readwrite256_t ch1is;
axi_request_readwrite256_t ch2is;
axi_request_readwrite256_t ch3is;
axi_request_readwrite256_t ch4is;
axi_request_readwrite256_t ch5is;
axi_request_readwrite256_t ch6is;
axi_request_readwrite256_t ch7is;

axi_request_readwrite256_t req_fifoi;
axi_request_readwrite256_t req_fifoo;
axi_request_write256_t ld;

wire almost_full;
wire [4:0] cnt;
reg wr_fifo;
wire [3:0] prev_state;
wire [3:0] state;
wire rd_fifo;	// from state machine
reg [5:0] num_strips;	// from fifo
wire [5:0] req_strip_cnt;
wire [5:0] resp_strip_cnt;
wire [15:0] tocnt;
wire [31:0] app_waddr;
reg [31:0] adr;
reg [3:0] uch;		// update channel
wire [15:0] wmask;
wire [15:0] mem_wdf_mask2;
reg [127:0] dat128;
wire [255:0] dat256;
wire [3:0] resv_ch [0:NAR-1];
wire [31:0] resv_adr [0:NAR-1];
wire rb1;
reg [7:0] req;
wire [1:0] wway;

wire ch0_hit_s, ch5_hit_s;
wire ch0_hit_ne, ch5_hit_ne;
reg [8:0] ch0_cnt, ch5_cnt;

edge_det ued1 (.rst(rst), .clk(mem_ui_clk), .ce(1'b1), .i(ch0_hit_s), .pe(), .ne(ch0_hit_ne), .ee());
edge_det ued2 (.rst(rst), .clk(mem_ui_clk), .ce(1'b1), .i(ch5_hit_s), .pe(), .ne(ch5_hit_ne), .ee());

always_ff @(posedge mem_ui_clk)
if (rst)
	ch0_cnt <= 9'h100;
else begin
	if (ch0_hit_s)
		ch0_cnt <= 9'h100;
	else if (ch0_hit_ne)
		ch0_cnt <= 9'h000;
	else if (!ch0_cnt[8])
		ch0_cnt <= ch0_cnt + 2'd1;
end

always_ff @(posedge mem_ui_clk)
if (rst)
	ch5_cnt <= 9'h100;
else begin
	if (ch5_hit_s)
		ch5_cnt <= 9'h100;
	else if (ch5_hit_ne)
		ch5_cnt <= 9'h000;
	else if (!ch5_cnt[8])
		ch5_cnt <= ch5_cnt + 2'd1;
end

wire [2:0] req_sel;
always_comb
begin
	// A request for channel zero is allowed only every 256 clocks.
	req[0] <= (!ch0_hit_s & ch0_cnt[8]);
	req[1] <= ch1o.read.RRESP==AXI_DECERR || ch1is.write.AWVALID;
	req[2] <= ch2o.read.RRESP==AXI_DECERR || ch2is.write.AWVALID;
	req[3] <= ch3o.read.RRESP==AXI_DECERR || ch3is.write.AWVALID;
	req[4] <= ch4o.read.RRESP==AXI_DECERR || ch4is.write.AWVALID;
	req[5] <= (!ch5_hit_s & ch5_cnt[8]);
	req[6] <= ch6o.read.RRESP==AXI_DECERR || ch6is.write.AWVALID;
	req[7] <= ch7o.read.RRESP==AXI_DECERR || ch7is.write.AWVALID;
end

// Register signals onto mem_ui_clk domain
mpmc10_sync128 usyn0
(
	.clk(mem_ui_clk),
	.i(ch0i),
	.o(ch0is)
);
mpmc10_sync256 usyn1
(
	.clk(mem_ui_clk),
	.i(ch1i),
	.o(ch1is)
);
mpmc10_sync256 usyn2
(
	.clk(mem_ui_clk),
	.i(ch2i),
	.o(ch2is)
);
mpmc10_sync256 usyn3
(
	.clk(mem_ui_clk),
	.i(ch3i),
	.o(ch3is)
);
mpmc10_sync256 usyn4
(
	.clk(mem_ui_clk),
	.i(ch4i),
	.o(ch4is)
);
mpmc10_sync256 usyn5
(
	.clk(mem_ui_clk),
	.i(ch5i),
	.o(ch5is)
);
mpmc10_sync256 usyn6
(
	.clk(mem_ui_clk),
	.i(ch6i),
	.o(ch6is)
);
mpmc10_sync256 usyn7
(
	.clk(mem_ui_clk),
	.i(ch7i),
	.o(ch7is)
);

always_comb
begin
	ld.AWVALID <= req_fifoo.read.ARVALID && app_rd_data_valid && (req_fifoo.read.ARCH!=4'd0 && req_fifoo.read.ARCH!=4'd5);
	ld.AWADDR <= app_waddr;
	ld.AWWAY <= wway;
	ld.WDATA <= {app_waddr[31:13],8'h00,app_rd_data};	// modified=false,tag = high order address bits
	ld.WVALID <= app_rd_data_valid;
	ld.WSTRB <= {36{1'b1}};		// update all bytes
end

mpmc10_cache ucache1
(
	.rst(mem_ui_rst),
	.wclk(mem_ui_clk),
	.inv(),
	.wchi(req_fifoo.write),
	.wcho(),
	.ld(ld),
	.ch0clk(ch0clk),
	.ch1clk(ch1clk),
	.ch2clk(ch2clk),
	.ch3clk(ch3clk),
	.ch4clk(ch4clk),
	.ch5clk(ch5clk),
	.ch6clk(ch6clk),
	.ch7clk(ch7clk),
	.ch0i(),
	.ch1i(ch1is.read),
	.ch2i(ch2is.read),
	.ch3i(ch3is.read),
	.ch4i(ch4is.read),
	.ch5i(),
	.ch6i(ch6is.read),
	.ch7i(ch7is.read),
	.ch0o(),
	.ch1o(ch1o.read),
	.ch2o(ch2o.read),
	.ch3o(ch3o.read),
	.ch4o(ch4o.read),
	.ch5o(),
	.ch6o(ch6o.read),
	.ch7o(ch7o.read)
);

always_comb
begin
	ch1o.read.RVALID = ch1o.read.RRESP != AXI_DECERR;
	ch1o.read.RDATA = ch1o.read.RDATA;
end

always_comb
begin
	ch7o.read.RVALID = ch7o.read.RRESP != AXI_DECERR;
	ch7o.read.RDATA = ch7o.read.RDATA;
end

mpmc10_strm_read_cache ustrm0
(
	.rst(rst),
	.wclk(mem_ui_clk),
	.wr(uch==4'd0 && app_rd_data_valid),
	.wadr({app_waddr[31:4],4'h0}),
	.wdat(app_rd_data),
//	.inv(1'b0),
	.rclk(mem_ui_clk),
	.radr({ch0is.read.ARADDR[31:4],4'h0}),
	.rdat(ch0o.read.RDATA),
	.hit(ch0_hit_s)
);

mpmc10_strm_read_cache ustrm5
(
	.rst(rst),
	.wclk(mem_ui_clk),
	.wr(uch==4'd5 && app_rd_data_valid),
	.wadr({app_waddr[31:4],4'h0}),
	.wdat(app_rd_data),
//	.inv(1'b0),
	.rclk(mem_ui_clk),
	.radr({ch5is.read.ARADDR[31:4],4'h0}),
	.rdat(ch5o.read.RDATA),
	.hit(ch5_hit_s)
);

always_comb
begin
	ch0o.read.RVALID = ch0_hit_s;
end

always_comb
begin
	ch5o.read.RVALID = ch5_hit_s;
end

always_ff @(posedge mem_ui_clk)
if (rst) begin
end
else begin
	wr_fifo <= 1'b0;
	if (|req & ~almost_full)
		wr_fifo <= 1'b1;
end

roundRobin rr1
(
	.rst(rst),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.req(req),
	.lock(8'h00),
	.sel(),
	.sel_enc(req_sel)
);

always_comb
	case(req_sel)
	3'd0:	req_fifoi <= ch0is;
	3'd1:	req_fifoi <= ch1is;
	3'd2:	req_fifoi <= ch2is;
	3'd3:	req_fifoi <= ch3is;
	3'd4:	req_fifoi <= ch4is;
	3'd5:	req_fifoi <= ch5is;
	3'd6:	req_fifoi <= ch6is;
	3'd7:	req_fifoi <= ch7is;
	endcase

xpm_fifo_sync #(
  .DOUT_RESET_VALUE("0"),    // String
  .ECC_MODE("no_ecc"),       // String
  .FIFO_MEMORY_TYPE("distributed"), // String
  .FIFO_READ_LATENCY(1),     // DECIMAL
  .FIFO_WRITE_DEPTH(32),   // DECIMAL
  .FULL_RESET_VALUE(0),      // DECIMAL
  .PROG_EMPTY_THRESH(3),    // DECIMAL
  .PROG_FULL_THRESH(27),     // DECIMAL
  .RD_DATA_COUNT_WIDTH(5),   // DECIMAL
  .READ_DATA_WIDTH($bits(axi_request_readwrite256_t)),      // DECIMAL
  .READ_MODE("std"),         // String
  .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
  .USE_ADV_FEATURES("070F"), // String
  .WAKEUP_TIME(0),           // DECIMAL
  .WRITE_DATA_WIDTH($bits(axi_request_readwrite256_t)),     // DECIMAL
  .WR_DATA_COUNT_WIDTH(5)    // DECIMAL
)
xpm_fifo_sync_inst (
  .almost_empty(),   // 1-bit output: Almost Empty : When asserted, this signal indicates that
                                 // only one more read can be performed before the FIFO goes to empty.

  .almost_full(almost_full),     // 1-bit output: Almost Full: When asserted, this signal indicates that
                                 // only one more write can be performed before the FIFO is full.

  .data_valid(v),       // 1-bit output: Read Data Valid: When asserted, this signal indicates
                                 // that valid data is available on the output bus (dout).

  .dbiterr(),             // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
                                 // a double-bit error and data in the FIFO core is corrupted.

  .dout(req_fifoo),                   // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                 // when reading the FIFO.

  .empty(empty),                 // 1-bit output: Empty Flag: When asserted, this signal indicates that the
                                 // FIFO is empty. Read requests are ignored when the FIFO is empty,
                                 // initiating a read while empty is not destructive to the FIFO.

  .full(full),                   // 1-bit output: Full Flag: When asserted, this signal indicates that the
                                 // FIFO is full. Write requests are ignored when the FIFO is full,
                                 // initiating a write when the FIFO is full is not destructive to the
                                 // contents of the FIFO.

  .overflow(),           // 1-bit output: Overflow: This signal indicates that a write request
                                 // (wren) during the prior clock cycle was rejected, because the FIFO is
                                 // full. Overflowing the FIFO is not destructive to the contents of the
                                 // FIFO.

  .prog_empty(),       // 1-bit output: Programmable Empty: This signal is asserted when the
                                 // number of words in the FIFO is less than or equal to the programmable
                                 // empty threshold value. It is de-asserted when the number of words in
                                 // the FIFO exceeds the programmable empty threshold value.

  .prog_full(),         // 1-bit output: Programmable Full: This signal is asserted when the
                                 // number of words in the FIFO is greater than or equal to the
                                 // programmable full threshold value. It is de-asserted when the number of
                                 // words in the FIFO is less than the programmable full threshold value.

  .rd_data_count(), // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
                                 // number of words read from the FIFO.

  .rd_rst_busy(),     // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read
                                 // domain is currently in a reset state.

  .sbiterr(),             // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
                                 // and fixed a single-bit error.

  .underflow(),         // 1-bit output: Underflow: Indicates that the read request (rd_en) during
                                 // the previous clock cycle was rejected because the FIFO is empty. Under
                                 // flowing the FIFO is not destructive to the FIFO.

  .wr_ack(),               // 1-bit output: Write Acknowledge: This signal indicates that a write
                                 // request (wr_en) during the prior clock cycle is succeeded.

  .wr_data_count(cnt), 					// WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                 // the number of words written into the FIFO.

  .wr_rst_busy(),     					// 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                 // write domain is currently in a reset state.

  .din(req_fifoi),           // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                 // writing the FIFO.

  .injectdbiterr(1'b0), // 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                 // the ECC feature is used on block RAMs or UltraRAM macros.

  .injectsbiterr(1'b0), // 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                 // the ECC feature is used on block RAMs or UltraRAM macros.

  .rd_en(rd_fifo),               // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                 // signal causes data (on dout) to be read from the FIFO. Must be held
                                 // active-low when rd_rst_busy is active high.

  .rst(rst),                     // 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
                                 // unstable at the time of applying reset, but reset must be released only
                                 // after the clock(s) is/are stable.

  .sleep(1'b0),                  // 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo
                                 // block is in power saving mode.

  .wr_clk(mem_ui_clk),         	 // 1-bit input: Write clock: Used for write operation. wr_clk must be a
                                 // free running clock.

  .wr_en(wr_fifo)                  	 // 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                 // signal causes data (on din) to be written to the FIFO Must be held
                                 // active-low when rst or wr_rst_busy or rd_rst_busy is active high

);

always_comb
	uch <= req_fifoo.read.ARVALID ? req_fifoo.read.ARCH : req_fifoo.write.AWCH;
always_comb
	num_strips <= req_fifoo.read.ARVALID ? req_fifoo.read.ARLEN : req_fifoo.write.AWLEN;
always_comb
	adr <= req_fifoo.read.ARVALID ? req_fifoo.read.ARADDR : req_fifoo.write.AWADDR;

wire [2:0] app_addr3;	// dummy to make up 32-bits

mpmc10_addr_gen uag1
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

mpmc10_waddr_gen uwag1
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

mpmc10_set_write_mask uswm1
(
	.clk(mem_ui_clk),
	.state(state),
	.we(), 
	.sel(req_fifoo.write.WSTRB[31:0]),
	.adr(adr|{req_strip_cnt[0],4'h0}),
	.mask(wmask)
);

mpmc10_mask_select unsks1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.wmask(wmask),
	.mask(app_wdf_mask),
	.mask2(mem_wdf_mask2)
);

mpmc10_data_select uds1
(
	.clk(mem_ui_clk),
	.state(state),
	.dati(req_fifoo.write.WDATA),
	.dato(dat256)
);

always_comb
	dat128 <= req_strip_cnt[0] ? dat256[255:128] : dat256[127:0];

// Setting the data value. Unlike reads there is only a single strip involved.
// Force unselected byte lanes to $FF
reg [127:0] dat128x;
genvar g;
generate begin
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
//	else if (state==WRITE_TRAMP1)
//		app_wdf_data <= rmw_data;
end


mpmc10_state_machine usm1
(
	.rst(rst|mem_ui_rst),
	.clk(mem_ui_clk),
	.to(to),
	.rdy(app_rdy),
	.wdf_rdy(app_wdf_rdy),
	.fifo_empty(empty),
	.rd_fifo(rd_fifo),
	.fifo_out(req_fifoo),
	.state(state),
	.num_strips(num_strips),
	.req_strip_cnt(req_strip_cnt),
	.resp_strip_cnt(resp_strip_cnt),
	.rd_data_valid(app_rd_data_valid)
);

mpmc10_to_cnt utoc1
(
	.clk(mem_ui_clk),
	.state(state),
	.prev_state(prev_state),
	.to_cnt(tocnt)
);

mpmc10_prev_state upst1
(
	.clk(mem_ui_clk),
	.state(state),
	.prev_state(prev_state)
);

mpmc10_app_en_gen ueng1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_rdy),
	.strip_cnt(req_strip_cnt),
	.num_strips(num_strips),
	.en(app_en)
);

mpmc10_app_cmd_gen ucg1
(
	.clk(mem_ui_clk),
	.state(state),
	.cmd(app_cmd)
);

mpmc10_app_wdf_wren_gen uwreng1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_wdf_rdy),
	.wren(app_wdf_wren)
);

mpmc10_app_wdf_end_gen uwendg1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_wdf_rdy),
	.strip_cnt(req_strip_cnt),
	.num_strips(num_strips),
	.wend(app_wdf_end)
);

mpmc10_req_strip_cnt ursc1
(
	.clk(mem_ui_clk),
	.state(state),
	.wdf_rdy(app_wdf_rdy),
	.rdy(app_rdy),
	.num_strips(num_strips),
	.strip_cnt(req_strip_cnt)
);

mpmc10_resp_strip_cnt urespsc1
(
	.clk(mem_ui_clk),
	.state(state),
	.valid(app_rd_data_valid),
	.num_strips(num_strips),
	.strip_cnt(resp_strip_cnt)
);

// Reservation status bit
mpmc10_resv_bit ursb1
(
	.clk(mem_ui_clk),
	.state(state),
	.wch(req_fifoo.write.AWCH),
	.we(req_fifoo.write.AWVALID),
	.cr(req_fifoo.write.AWCR),
	.adr(req_fifoo.write.AWADDR),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.rb(rb1)
);

mpmc10_addr_resv_man #(.NAR(NAR)) ursvm1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.adr0(32'h0),
	.adr1(ch1is.read.ARADDR),
	.adr2(ch2is.read.ARADDR),
	.adr3(ch3is.read.ARADDR),
	.adr4(ch4is.read.ARADDR),
	.adr5(32'h0),
	.adr6(ch6is.read.ARADDR),
	.adr7(ch7is.read.ARADDR),
	.sr0(1'b0),
	.sr1(ch1is.read.ARSR & ch1is.read.ARVALID),
	.sr2(ch2is.read.ARSR & ch2is.read.ARVALID),
	.sr3(ch3is.read.ARSR & ch3is.read.ARVALID),
	.sr4(ch4is.read.ARSR & ch4is.read.ARVALID),
	.sr5(1'b0),
	.sr6(ch6is.read.ARSR & ch6is.read.ARVALID),
	.sr7(ch7is.read.ARSR & ch7is.read.ARVALID),
	.wch(req_fifoo.write.AWVALID ? req_fifoo.write.AWCH : 4'd15),
	.we(req_fifoo.read.ARVALID ? 1'b0 : req_fifoo.write.WVALID),
	.wadr(req_fifoo.write.AWADDR),
	.cr(req_fifoo.write.AWCR),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr)
);

endmodule
