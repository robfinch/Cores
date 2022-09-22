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
import mpmc10_pkg::*;

module mpmc10_cache(input rst, wclk, inv, 
	input axi_request_write256_t wchi, 
	output axi_response_write_t wcho, 
	input axi_request_write256_t ld,
	input ch0clk, 
	input ch1clk, 
	input ch2clk, 
	input ch3clk, 
	input ch4clk, 
	input ch5clk, 
	input ch6clk, 
	input ch7clk, 
	input axi_request_read_t ch0i,
	input axi_request_read_t ch1i,
	input axi_request_read_t ch2i,
	input axi_request_read_t ch3i,
	input axi_request_read_t ch4i,
	input axi_request_read_t ch5i,
	input axi_request_read_t ch6i,
	input axi_request_read_t ch7i,
	output axi_response_read256_t ch0o,
	output axi_response_read256_t ch1o,
	output axi_response_read256_t ch2o,
	output axi_response_read256_t ch3o,
	output axi_response_read256_t ch4o,
	output axi_response_read256_t ch5o,
	output axi_response_read256_t ch6o,
	output axi_response_read256_t ch7o
);

integer n,n2,n3;

(* ram_style="distributed" *)
reg [127:0] vbit [0:CACHE_ASSOC-1];

reg [31:0] radrr0;
reg [31:0] radrr1;
reg [31:0] radrr2;
reg [31:0] radrr3;
reg [31:0] radrr4;
reg [31:0] radrr5;
reg [31:0] radrr6;
reg [31:0] radrr7;
reg [31:0] radrr8;

mpmc10_cache_line_t doutb [0:8][0:3];
mpmc10_cache_line_t wrdata, wdata;
reg [31:0] wadr;
reg [35:0] wstrb;
reg [1:0] wway;
reg wvalid;

reg [CACHE_ASSOC-1:0] vbito0a;
reg [CACHE_ASSOC-1:0] vbito1a;
reg [CACHE_ASSOC-1:0] vbito2a;
reg [CACHE_ASSOC-1:0] vbito3a;
reg [CACHE_ASSOC-1:0] vbito4a;
reg [CACHE_ASSOC-1:0] vbito5a;
reg [CACHE_ASSOC-1:0] vbito6a;
reg [CACHE_ASSOC-1:0] vbito7a;
reg [CACHE_ASSOC-1:0] vbito8a;

reg [CACHE_ASSOC-1:0] hit0a;
reg [CACHE_ASSOC-1:0] hit1a;
reg [CACHE_ASSOC-1:0] hit2a;
reg [CACHE_ASSOC-1:0] hit3a;
reg [CACHE_ASSOC-1:0] hit4a;
reg [CACHE_ASSOC-1:0] hit5a;
reg [CACHE_ASSOC-1:0] hit6a;
reg [CACHE_ASSOC-1:0] hit7a;
reg [CACHE_ASSOC-1:0] hit8a;

// Always ready to accept a read request.
assign ch0o.ARREADY = 1'b1;
assign ch1o.ARREADY = 1'b1;
assign ch2o.ARREADY = 1'b1;
assign ch3o.ARREADY = 1'b1;
assign ch4o.ARREADY = 1'b1;
assign ch5o.ARREADY = 1'b1;
assign ch6o.ARREADY = 1'b1;
assign ch7o.ARREADY = 1'b1;

always_ff @(posedge ch0clk) radrr0 <= ch0i.ARADDR;
always_ff @(posedge ch1clk) radrr1 <= ch1i.ARADDR;
always_ff @(posedge ch2clk) radrr2 <= ch2i.ARADDR;
always_ff @(posedge ch3clk) radrr3 <= ch3i.ARADDR;
always_ff @(posedge ch4clk) radrr4 <= ch4i.ARADDR;
always_ff @(posedge ch5clk) radrr5 <= ch5i.ARADDR;
always_ff @(posedge ch6clk) radrr6 <= ch6i.ARADDR;
always_ff @(posedge ch7clk) radrr7 <= ch7i.ARADDR;

always_ff @(posedge ch0clk) ch0o.RID <= ch0i.ARID;
always_ff @(posedge ch1clk) ch1o.RID <= ch1i.ARID;
always_ff @(posedge ch2clk) ch2o.RID <= ch2i.ARID;
always_ff @(posedge ch3clk) ch3o.RID <= ch3i.ARID;
always_ff @(posedge ch4clk) ch4o.RID <= ch4i.ARID;
always_ff @(posedge ch5clk) ch5o.RID <= ch5i.ARID;
always_ff @(posedge ch6clk) ch6o.RID <= ch6i.ARID;
always_ff @(posedge ch7clk) ch7o.RID <= ch7i.ARID;

reg [8:0] rclkp;
always_comb
begin
	rclkp[0] = ch0clk;
	rclkp[1] = ch1clk;
	rclkp[2] = ch2clk;
	rclkp[3] = ch3clk;
	rclkp[4] = ch4clk;
	rclkp[5] = ch5clk;
	rclkp[6] = ch6clk;
	rclkp[7] = ch7clk;
	rclkp[8] = wclk;
end

reg [6:0] radr [0:8];
always_comb
begin
	radr[0] = ch0i.ARADDR[11:5];
	radr[1] = ch1i.ARADDR[11:5];
	radr[2] = ch2i.ARADDR[11:5];
	radr[3] = ch3i.ARADDR[11:5];
	radr[4] = ch4i.ARADDR[11:5];
	radr[5] = ch5i.ARADDR[11:5];
	radr[6] = ch6i.ARADDR[11:5];
	radr[7] = ch7i.ARADDR[11:5];
	radr[8] = wchi.AWADDR[11:5];
end

   // xpm_memory_sdpram: Simple Dual Port RAM
   // Xilinx Parameterized Macro, version 2020.2

genvar gway,gport;

generate begin : gCacheRAM
	for (gport = 0; gport < 9; gport = gport + 1)
		for (gway = 0; gway < CACHE_ASSOC; gway = gway + 1)
   xpm_memory_sdpram #(
      .ADDR_WIDTH_A(7),               // DECIMAL
      .ADDR_WIDTH_B(7),               // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(8),        // DECIMAL
      .CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("independent_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE("none"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("block"),      // String
      .MEMORY_SIZE($bits(mpmc10_cache_line_t)*128),             // DECIMAL
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_B($bits(mpmc10_cache_line_t)),         // DECIMAL
      .READ_LATENCY_B(1),             // DECIMAL
      .READ_RESET_VALUE_B("0"),       // String
      .RST_MODE_A("SYNC"),            // String
      .RST_MODE_B("SYNC"),            // String
      .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A($bits(mpmc10_cache_line_t)),        // DECIMAL
      .WRITE_MODE_B("no_change")      // String
   )
   xpm_memory_sdpram_inst (
      .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port B.

      .doutb(doutb[gport][gway]),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(wadr[11:5]),        				// ADDR_WIDTH_A-bit input: Address for port A write operations.
      .addrb(radr[gport]),             // ADDR_WIDTH_B-bit input: Address for port B read operations.
      .clka(wclk),                 // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(rclkp[gport]),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(wdata),                // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(wvalid & |wstrb & wway==gway),          // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when write operations are initiated. Pipelined internally.

      .enb(1'b1),                      // 1-bit input: Memory enable signal for port B. Must be high on clock
                                       // cycles when read operations are initiated. Pipelined internally.

      .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rstb(rst),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(wstrb)                     // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

   );
end
endgenerate				
				
genvar g;
generate begin : gReaddat
	for (g = 0; g < CACHE_ASSOC; g = g + 1) begin
		always_ff @(posedge ch0clk) vbito0a[g] <= vbit[g][radrr0[11:5]];
		always_ff @(posedge ch1clk) vbito1a[g] <= vbit[g][radrr1[11:5]];
		always_ff @(posedge ch2clk) vbito2a[g] <= vbit[g][radrr2[11:5]];
		always_ff @(posedge ch3clk) vbito3a[g] <= vbit[g][radrr3[11:5]];
		always_ff @(posedge ch4clk) vbito4a[g] <= vbit[g][radrr4[11:5]];
		always_ff @(posedge ch5clk) vbito5a[g] <= vbit[g][radrr5[11:5]];
		always_ff @(posedge ch6clk) vbito6a[g] <= vbit[g][radrr6[11:5]];
		always_ff @(posedge ch7clk) vbito7a[g] <= vbit[g][radrr7[11:5]];
		always_ff @(posedge wclk) vbito8a[g] <= vbit[g][radrr8[11:5]];
		
		always_comb	hit0a[g] = (doutb[0][g].tag==radrr0[31:13]) && (vbito0a[g]==1'b1);
		always_comb	hit1a[g] = (doutb[1][g].tag==radrr1[31:13]) && (vbito1a[g]==1'b1);
		always_comb	hit2a[g] = (doutb[2][g].tag==radrr2[31:13]) && (vbito2a[g]==1'b1);
		always_comb	hit3a[g] = (doutb[3][g].tag==radrr3[31:13]) && (vbito3a[g]==1'b1);
		always_comb	hit4a[g] = (doutb[4][g].tag==radrr4[31:13]) && (vbito4a[g]==1'b1);
		always_comb	hit5a[g] = (doutb[5][g].tag==radrr5[31:13]) && (vbito5a[g]==1'b1);
		always_comb	hit6a[g] = (doutb[6][g].tag==radrr6[31:13]) && (vbito6a[g]==1'b1);
		always_comb	hit7a[g] = (doutb[7][g].tag==radrr7[31:13]) && (vbito7a[g]==1'b1);
		always_comb	hit8a[g] = (doutb[8][g].tag==radrr8[31:13]) && (vbito8a[g]==1'b1);
			
		always_comb ch0o.RLAST = 1'b1;
		always_comb ch1o.RLAST = 1'b1;
		always_comb ch2o.RLAST = 1'b1;
		always_comb ch3o.RLAST = 1'b1;
		always_comb ch4o.RLAST = 1'b1;
		always_comb ch5o.RLAST = 1'b1;
		always_comb ch6o.RLAST = 1'b1;
		always_comb ch7o.RLAST = 1'b1;
		
		always_comb ch0o.RVALID = 1'b1;
		always_comb ch1o.RVALID = 1'b1;
		always_comb ch2o.RVALID = 1'b1;
		always_comb ch3o.RVALID = 1'b1;
		always_comb ch4o.RVALID = 1'b1;
		always_comb ch5o.RVALID = 1'b1;
		always_comb ch6o.RVALID = 1'b1;
		always_comb ch7o.RVALID = 1'b1;
	end
end
endgenerate

always_comb
begin
	ch0o.RDATA <= 'd0;
	ch1o.RDATA <= 'd0;
	ch2o.RDATA <= 'd0;
	ch3o.RDATA <= 'd0;
	ch4o.RDATA <= 'd0;
	ch5o.RDATA <= 'd0;
	ch6o.RDATA <= 'd0;
	ch7o.RDATA <= 'd0;
	wrdata <= 'd0;
	for (n2 = 0; n2 < CACHE_ASSOC; n2 = n2 + 1) begin
		if (hit0a[n2]) ch0o.RDATA <= doutb[0][n2];
		if (hit1a[n2]) ch1o.RDATA <= doutb[1][n2];
		if (hit2a[n2]) ch2o.RDATA <= doutb[2][n2];
		if (hit3a[n2]) ch3o.RDATA <= doutb[3][n2];
		if (hit4a[n2]) ch4o.RDATA <= doutb[4][n2];
		if (hit5a[n2]) ch5o.RDATA <= doutb[5][n2];
		if (hit6a[n2]) ch6o.RDATA <= doutb[6][n2];
		if (hit7a[n2]) ch7o.RDATA <= doutb[7][n2];
		if (hit8a[n2]) wrdata <= doutb[8][n2];
	end
end

always_comb
begin
	ch0o.ARWAY <= 2'd0;
	ch1o.ARWAY <= 2'd0;
	ch2o.ARWAY <= 2'd0;
	ch3o.ARWAY <= 2'd0;
	ch4o.ARWAY <= 2'd0;
	ch5o.ARWAY <= 2'd0;
	ch6o.ARWAY <= 2'd0;
	ch7o.ARWAY <= 2'd0;
	wway <= 2'd0;
	for (n3 = 0; n3 < CACHE_ASSOC; n3 = n3 + 1) begin
		if (hit0a[n3]) ch0o.ARWAY <= n3;
		if (hit1a[n3]) ch1o.ARWAY <= n3;
		if (hit2a[n3]) ch2o.ARWAY <= n3;
		if (hit3a[n3]) ch3o.ARWAY <= n3;
		if (hit4a[n3]) ch4o.ARWAY <= n3;
		if (hit5a[n3]) ch5o.ARWAY <= n3;
		if (hit6a[n3]) ch6o.ARWAY <= n3;
		if (hit7a[n3]) ch7o.ARWAY <= n3;
		if (hit8a[n3]) wway <= n3;
	end
end

always_ff @(posedge wclk)
if (rst) begin
	for (n = 0; n < 4; n = n + 1)
		vbit[n] <= 'b0;	
end
else begin
	if (|wchi.WSTRB)
		vbit[wchi.AWWAY][wchi.AWADDR[11:5]] <= 1'b1;
	else if (inv)
		vbit[wchi.AWWAY][wchi.AWADDR[11:5]] <= 1'b0;
end

always_comb ch0o.RRESP = |hit0a ? AXI_OKAY : AXI_DECERR;
always_comb ch1o.RRESP = |hit1a ? AXI_OKAY : AXI_DECERR;
always_comb ch2o.RRESP = |hit2a ? AXI_OKAY : AXI_DECERR;
always_comb ch3o.RRESP = |hit3a ? AXI_OKAY : AXI_DECERR;
always_comb ch4o.RRESP = |hit4a ? AXI_OKAY : AXI_DECERR;
always_comb ch5o.RRESP = |hit5a ? AXI_OKAY : AXI_DECERR;
always_comb ch6o.RRESP = |hit6a ? AXI_OKAY : AXI_DECERR;
always_comb ch7o.RRESP = |hit7a ? AXI_OKAY : AXI_DECERR;

// Update the cache only if there was a write hit or if loading the cache line
// due to a read miss. For a read miss the entire line is updated, otherwise
// just the part of the line relevant to the write is updated.
always_ff @(posedge wclk)
begin
	wadr <= ld.AWVALID ? ld.AWADDR : wchi.AWADDR;
	wstrb <= ld.WVALID ? ld.WSTRB : wchi.WSTRB & {36{|hit8a}};
	wvalid <= ld.WVALID ? 1'b1 : wchi.WVALID & |hit8a;
end

// Merge write data into cache line.
generate begin : gWrData
	for (g = 0; g < 36; g = g + 1)
		always_comb
			if (ld.WVALID)
				wdata[g*8+7:g*8] <= ld.WDATA[g*8+7:g*8];
			else
				wdata[g*8+7:g*8] <= wstrb[g] ? wchi.WDATA[g*8+7:g*8] : wrdata[g*8+7:g*8];
end
endgenerate

// Writes take two clock cycles, 1 to read the RAM and find out if it is a
// write hit and a second clock to write the data.
reg awready;
always_ff @(posedge wclk)
if (rst)
	awready <= 1'b1;
else begin
	awready <= 1'b1;
	wcho.BRESP <= AXI_SLVERR;
	if (wchi.AWVALID)
		awready <= 1'b0;
	if (wchi.AWVALID & ~ld.AWVALID) begin
		wcho.BRESP <= AXI_OKAY;
		wcho.BID <= wchi.AWID;
		wcho.BVALID <= 1'b1;
	end
end
always_comb wcho.AWREADY = awready;

endmodule
