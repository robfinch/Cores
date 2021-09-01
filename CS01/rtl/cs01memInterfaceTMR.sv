// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2021  Robert Finch, Waterloo
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
module cs01memInterface(rst_i, clk_i,
	cs_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o, 
	RamCEn, RamWEn, RamOEn, MemAdr, MemDB_o, MemDB_i, MemT, badram);
input rst_i;
input clk_i;          // 100 MHz
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [3:0] sel_i;
input [31:0] adr_i;
input [31:0] dat_i;
output reg [31:0] dat_o;
output reg RamCEn;
output reg RamWEn;
output reg RamOEn;
output reg [18:0] MemAdr;
output reg [7:0] MemDB_o;
input [7:0] MemDB_i;
output reg [7:0] MemT;
output reg badram;

parameter HIGH = 1'b1;
parameter LOW = 1'b0;

reg [3:0] state, stkstate;
parameter IDLE = 4'd0;
parameter RD1 = 4'd1;
parameter WR1 = 4'd2;
parameter WR2 = 4'd3;
parameter WR3 = 4'd4;
parameter RWDONE = 4'd5;
parameter RWNACK = 4'd6;
parameter RD2 = 4'd7;
parameter WR0 = 4'd8;
parameter RD1a = 4'd9;
parameter RD1b = 4'd10;
parameter RD1c = 4'd11;
reg [31:0] memDat;
reg [3:0] sel;  // ring counter
reg [7:0] tdat;
reg ack;

wire csi = cs_i & cyc_i & stb_i;
// Setup ack_o so that it goes low as soon as cs goes away.
assign ack_o = ack & csi;

// State machine.
always @(posedge clk_i)
if (rst_i)
	state <= IDLE;
else begin
case(state)
IDLE:
	if (csi)
		state <= we_i ? WR0 : RD2;
RD1:
	state <= RD1a;
RD1a:
	if (sel[3:1]==3'b0)
		state <= RWDONE;
	else
		state <= RD2;
// RD2 gives more time for address settling, variation in I/O delay.
RD2:
	state <= RD1;
WR0:
	state <= WR1;
WR1:
	state <= WR3;
WR3:
	if (sel[3:1]==3'b0)
		state <= RWDONE;
	else
		state <= WR0;
RWDONE:
	state <= RWNACK;
// Wait until the processor is done with the read / write then go back to the
// idle state to wait for another operation.
RWNACK:
	if (!csi)
		state <= IDLE;
default:
	state <= IDLE;
endcase
end

// RamCEn is used to reduce power requirements. If the RAM is sitting idle then
// the chip enable will be inactive. The RAM consumes much less power when
// inactive.
always @(posedge clk_i)
if (rst_i)
	RamCEn <= HIGH;
else begin
case(state)
IDLE:
	// Tell the ram it's selected, move out of low-power mode.
	if (csi)
		RamCEn <= LOW;					
RWDONE:
	RamCEn <= HIGH;
endcase
end

// Write pulses low for a single cycle during a write operation. The clock
// must have a period of at least 8.0 ns (125MHz or slower).
always @(posedge clk_i)
if (rst_i)
	RamWEn <= HIGH;
else begin
// AFter a cycle disable the write input. This will cause the ram to latch
// the data.
RamWEn <= HIGH;
case(state)
WR0:
	RamWEn <= LOW;
endcase
end

always @(posedge clk_i)
if (rst_i)
	RamOEn <= HIGH;
else begin
case(state)
IDLE:
	RamOEn <= we_i | ~csi;
RWDONE:
	RamOEn <= HIGH;
endcase
end

// External tri-state drive goes active one cycle before write, and inactive
// one cycle after.
always @(posedge clk_i)
if (rst_i)
	MemT <= 8'hFF;
else begin
case(state)
IDLE:
	MemT <= (we_i & csi) ? 8'h00 : 8'hFF;
RWDONE:
	MemT <= 8'hFF;
endcase
end

always @(posedge clk_i)
if (rst_i)
	ack <= LOW;
else begin
case(state)
IDLE:
	ack <= LOW;
RWDONE:
	ack <= HIGH;
RWNACK:
	if (!csi) begin
		ack <= LOW;
	end
endcase
end

always @(posedge clk_i)
if (rst_i)
	sel <= 4'h0;
else begin
case(state)
IDLE:
	casez(sel_i)
	4'b???1:	sel <= sel_i;
	4'b??10:	sel <= {1'b0,sel_i[3:1]};
	4'b?100:	sel <= {2'b0,sel_i[3:2]};
	4'b1000:	sel <= {3'b0,sel_i[3]};
	endcase
RD1a:
	sel <= {1'b0,sel[3:1]};
WR3:
	sel <= {1'b0,sel[3:1]};
endcase
end

// Hold the bus at zero unless a read access is taking place. This should allow
// a wire-or of the bus with other sources.
always @(posedge clk_i)
if (rst_i)
	dat_o <= 32'h0;
else begin
case(state)
IDLE:
	dat_o <= 32'h0;
RD1:
	case(MemAdr[1:0])
	2'd0:	dat_o[7:0] <= MemDB_i;
	2'd1: dat_o[15:8] <= MemDB_i;
	2'd2: dat_o[23:16] <= MemDB_i;
	2'd3:	dat_o[31:24] <= MemDB_i;
	endcase
RWNACK:
	if (!csi)
		dat_o <= 32'h0;
default:	;
endcase
end

always @(posedge clk_i)
if (rst_i)
	memDat <= 32'h0;
else begin
case(state)
IDLE:
	memDat <= dat_i;
default:	;
endcase
end

always @(posedge clk_i)
if (rst_i)
	MemDB_o <= 8'h00;
else
case(state)
IDLE:
	MemDB_o <= 8'h00;
WR0:
  case(MemAdr[1:0])
  2'd0: MemDB_o <= memDat[7:0];
  2'd1: MemDB_o <= memDat[15:8];
  2'd2: MemDB_o <= memDat[23:16];
  2'd3: MemDB_o <= memDat[31:24];
  default:  ;
  endcase
RWNACK:
	MemDB_o <= 8'h00;
default:	;
endcase

// The address is allowed to start in the middle of a word to improve
// performance of byte and wyde accesses.

always @(posedge clk_i)
if (rst_i)
	MemAdr <= 19'h0;
else
case(state)
IDLE:
	begin
		MemAdr[18:2] <= adr_i[18:2];
		casez(sel_i)
		4'b???1:	begin MemAdr[1:0] <= 2'b00; end
		4'b??10:	begin MemAdr[1:0] <= 2'b01; end
		4'b?100:	begin MemAdr[1:0] <= 2'b10; end
		4'b1000:	begin MemAdr[1:0] <= 2'b11; end
		endcase
	end

RD1a:
	MemAdr[1:0] <= MemAdr[1:0] + 2'd1;

WR3:
	MemAdr[1:0] <= MemAdr[1:0] + 2'd1;

RWNACK:
	MemAdr <= 19'h0;	
default:	;
endcase

endmodule
