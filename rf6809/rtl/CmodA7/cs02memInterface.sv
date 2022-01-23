// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
module cs02memInterface(rst_i, clk_i, cpuclk_i,
	cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o, 
	RamCEn, RamWEn, RamOEn, MemAdr, MemDBo, MemDBi);
input rst_i;
input clk_i;          // 100 MHz
input cpuclk_i;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [23:0] adr_i;
input [11:0] dat_i;
output reg [11:0] dat_o;
output reg RamCEn;
output reg RamWEn;
output reg RamOEn;
output reg [18:0] MemAdr;
output reg [7:0] MemDBo;
input [7:0] MemDBi;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;

reg [3:0] state;
parameter IDLE = 4'd0;
parameter WRF1 = 4'd1;
parameter WRF2 = 4'd2;
parameter WRF3 = 4'd3;
parameter WRF4 = 4'd4;
parameter WRF5 = 4'd5;
parameter WRF6 = 4'd6;
parameter WRF7 = 4'd7;
parameter WRF8 = 4'd8;
parameter RRF1 = 4'd9;
parameter RRF2 = 4'd10;
parameter RRF3 = 4'd11;
parameter RRF4 = 4'd12;

wire cs = cs_i & stb_i & cyc_i;
reg ack;
wire hit;

ack_gen #(
	.READ_STAGES(2),
	.WRITE_STAGES(1),
	.REGISTER_OUTPUT(1)
) uag1
(
	.rst_i(rst_i),
	.clk_i(cpuclk_i),
	.ce_i(1'b1),
	.i(cs & hit & ~we_i),
	.we_i(cs & ack),
	.o(ack_o),
	.rid_i(0),
	.wid_i(0),
	.rid_o(),
	.wid_o()
);

reg wrc, inv;
wire [11:0] rdat;

A709_ReadCache urc1
(
	.rst(rst_i),
	.wclk(clk_i),
	.wr(wrc),
	.wa({5'h0,MemAdr[18:0]}),
	.wd(MemDBi[5:0]),
	.rclk(cpuclk_i),
	.ra(adr_i),
	.rd(rdat),
	.hit(hit),
	.inv(inv),
	.ia(adr_i)
);

always_ff @(posedge cpuclk_i)
if (cs)
	dat_o <= rdat;
else
	dat_o <= 12'h0;
	
reg [31:0] ctr;	// ring counter

always_ff @(posedge clk_i)
if (rst_i) begin
	state <= IDLE;
	RamWEn <= HIGH;
	RamOEn <= HIGH;
	RamCEn <= HIGH;
	wrc <= 1'b0;
	ack <= 1'b0;
	inv <= 1'b0;
	ctr <= 33'h1;
end
else begin
wrc <= 1'b0;
inv <= 1'b0;
case(state)
IDLE:
	begin
		RamWEn <= HIGH;
		RamCEn <= HIGH;
		RamOEn <= HIGH;
		MemAdr[18:0] <= {adr_i[17:0],1'b0};
		MemDBo <= {2'b0,dat_i[5:0]};
		if (cs & we_i) begin
			inv <= 1'b1;
			RamCEn <= LOW;
			state <= WRF1;
		end
		// Initiate a read, it might take several cycles before hit goes high,
		// so test for a hit at each stage.
		else if (cs & !hit) begin
			RamCEn <= LOW;
			RamOEn <= LOW;
			MemAdr[4:0] <= 5'h0;
			ctr <= 33'h1;
			state <= RRF1;
		end
	end
WRF1:
	begin
		RamWEn <= LOW;
		state <= WRF2;
	end
WRF2:
	begin
		state <= WRF3;
	end
WRF3:
	begin
		RamWEn <= HIGH;
		state <= WRF4;
	end
WRF4:
	begin
		MemAdr[0] <= 1'b1;
		MemDBo <= {2'b0,dat_i[11:6]};
		state <= WRF5;
	end
WRF5:
	begin
		RamWEn <= LOW;
		state <= WRF6;
	end
WRF6:
	begin
		state <= WRF7;
	end
WRF7:
	begin
		RamWEn <= HIGH;
		ack <= 1'b1;
		state <= WRF8;
	end
WRF8:
	if (!cs) begin
		ack <= 1'b0;
		state <= IDLE;
	end
RRF1:
	begin
		if (hit)
			state <= IDLE;
		else
			state <= RRF2;
	end
RRF2:
	begin
		wrc <= 1'b1;
		if (hit)
			state <= IDLE;
		else if (ctr[31])
			state <= RRF4;
		else
			state <= RRF3;
	end
RRF3:
	begin
		MemAdr[4:0] <= MemAdr[4:0] + 2'd1;
		ctr <= {ctr[30:0],ctr[31]};
		if (hit)
			state <= IDLE;
		else
			state <= RRF1;
	end
RRF4:
	begin
		wrc <= 1'b1;
		state <= IDLE;
	end
default:
	state <= IDLE;
endcase
end
endmodule

module A709_ReadCache(rst, wclk, wr, wa, wd, rclk, ra, rd, hit, inv, ia);
input rst;
input wclk;
input wr;
input [24:0] wa;
input [5:0] wd;
input rclk;
input [23:0] ra;
output reg [11:0] rd;
output reg hit;
input inv;
input [23:0] ia;

reg [11:0] mem [0:2047];
reg [10:0] rra;

always_ff @(posedge rclk)
	rra <= ra[10:0];
always_ff @(posedge rclk)
	rd <= mem[rra];
always_ff @(posedge wclk)
	if (wr & ~wa[0]) mem[wa[11:1]][5:0] <= wd;
always_ff @(posedge wclk)
	if (wr &  wa[0]) mem[wa[11:1]][11:6] <= wd;

reg [19:0] tagmem [127:0];
reg [127:0] valid;

reg [23:0] iar;
reg invr;
// register onto wclk domain
always_ff @(posedge wclk)
	iar <= ia;
always_ff @(posedge wclk)
	invr <= inv;

always_ff @(posedge wclk)
	if (wr && wa[4:0]==5'h1F)
		tagmem[wa[11:5]] <= wa[24:5];

always_ff @(posedge wclk)
if (rst)
	valid <= 128'd0;
else begin
if (invr)
	valid[iar[10:4]] <= tagmem[iar[10:4]]!=iar[23:4];
else if (wr && wa[4:0]==5'h1F)
	valid[wa[11:5]] <= 1'b1;
end

always_ff @(posedge rclk)
	hit <= valid[ra[10:4]] && tagmem[ra[10:4]]==ra[23:4];

endmodule
