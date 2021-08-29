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
output reg ack_o;
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
output reg MemT;
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
parameter WR0a = 4'd12;
parameter WR0b = 4'd13;
reg [31:0] memDat;
reg [3:0] sel;  // ring counter
reg [1:0] tmr;
reg [31:0] rdat [0:3];
reg [7:0] tdat;
reg [3:0] errcnt;
reg rc;
wire csi = cs_i & cyc_i & stb_i;

always @(posedge clk_i)
if (rst_i)
	state <= IDLE;
else begin
case(state)
IDLE:
	if (csi)
		state <= we_i ? WR0 : RD2;
RD1:
	if (sel[3:1]==3'b0)
		state <= RWDONE;
	else
		state <= RD2;
RD2:
	state <= we_i ? WR0 : RD1;
WR0:
	state <= WR0a;
WR0a:
	state <= WR0b;
WR0b:
	state <= WR1;
WR1:
	state <= WR2;
WR2:
	if (MemDB_i != MemDB_o) begin
		state <= WR0;
		if (errcnt==4'd10)
			state <= WR3;
	end
	else
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
WR0a:
	RamWEn <= LOW;
endcase
end

always @(posedge clk_i)
if (rst_i)
	RamOEn <= HIGH;
else begin
case(state)
IDLE:
	RamOEn <= we_i;
WR1:
	RamOEn <= LOW;
WR2:
	RamOEn <= HIGH;
RWDONE:
	RamOEn <= HIGH;
endcase
end

always @(posedge clk_i)
if (rst_i)
	MemT <= HIGH;
else begin
case(state)
IDLE:
	MemT <= ~we_i;
RD2:
	if (we_i)
		MemT <= LOW;
WR1:
	MemT <= HIGH;
WR2:
	MemT <= LOW;
RWDONE:
	MemT <= HIGH;
endcase
end

always @(posedge clk_i)
if (rst_i)
	dat_o <= 32'h0;
else
	dat_o <= rdat[0];

always @(posedge clk_i)
if (rst_i)
	ack_o <= LOW;
else begin
case(state)
IDLE:
	ack_o <= LOW;
// RD2 gives more time for address settling, variation in I/O delay.
// The write signal is checked here in case the write signal shows up delayed by
// a cycle.
RWDONE:
	ack_o <= HIGH;
RWNACK:
	if (!csi) begin
		ack_o <= LOW;
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
RD1:
	sel <= {1'b0,sel[3:1]};
WR3:
	sel <= {1'b0,sel[3:1]};
endcase
end

always @(posedge clk_i)
if (rst_i) begin
	badram <= 1'b0;
	errcnt <= 4'd0;
	rc <= 1'b1;
end
else
case(state)
IDLE:
	begin
		// Default action is to disable all bus drivers
		badram <= 1'b0;
		errcnt <= 4'd0;
		rdat[0] <= 32'h0;
		tmr <= 2'b00;
		MemAdr[18:2] <= adr_i[18:2];
		memDat <= dat_i;
		rc <= ~we_i;
		casez(sel_i)
		4'b???1:	begin MemAdr[1:0] <= 2'b00; end
		4'b??10:	begin MemAdr[1:0] <= 2'b01; end
		4'b?100:	begin MemAdr[1:0] <= 2'b10; end
		4'b1000:	begin MemAdr[1:0] <= 2'b11; end
		endcase
	end
	// For a read, after a clock cycle latch the input data.
	// Increment the memory address and count.
	// Simply stay in this state until the count expires.
/*
RD1c:
	begin
		case(MemAdr[1:0])
		2'd0:	rdat[tmr][7:0] <= MemDB;
		2'd1: rdat[tmr][15:8] <= MemDB;
		2'd2:	rdat[tmr][23:16] <= MemDB;
		2'd3:	rdat[tmr][31:24] <= MemDB;
		endcase
		tmr <= tmr + 2'd1;
	end
RD1b:
	begin
		case(MemAdr[1:0])
		2'd0:	rdat[tmr][7:0] <= MemDB;
		2'd1: rdat[tmr][15:8] <= MemDB;
		2'd2:	rdat[tmr][23:16] <= MemDB;
		2'd3:	rdat[tmr][31:24] <= MemDB;
		endcase
		tmr <= tmr + 2'd1;
	end
*/
RD1:
	begin
		case(MemAdr[1:0])
		2'd0:	rdat[tmr][7:0] <= MemDB_i;
		2'd1: rdat[tmr][15:8] <= MemDB_i;
		2'd2:	rdat[tmr][23:16] <= MemDB_i;
		2'd3:	rdat[tmr][31:24] <= MemDB_i;
		endcase
		MemAdr[1:0] <= MemAdr[1:0] + 2'd1;
	end

WR0:
  begin
	  case(MemAdr[1:0])
	  2'd0: MemDB_o <= memDat[7:0];
	  2'd1: MemDB_o <= memDat[15:8];
	  2'd2: MemDB_o <= memDat[23:16];
	  2'd3: MemDB_o <= memDat[31:24];
	  default:  ;
	  endcase
  end
WR2:
	begin
		if (MemDB_i != MemDB_o) begin
			errcnt <= errcnt + 2'd1;
			if (errcnt==4'd10) begin
				badram <= 1'b1;
			end
		end
	end
	// After another cycle increment the memory address and memory count.
	// If the count expired goto the done state, otherwise go back to the first
	// write state.
WR3:
	begin
		MemAdr[1:0] <= MemAdr[1:0] + 2'd1;
		if (sel[3:1]!=3'b0) begin
			errcnt <= 4'd0;
		end
	end
	// Here a read/write is done. Signal the processor.
RWDONE:
	begin
		badram <= 1'b0;
//		dat_o <= (rdat[0]&rdat[1])|(rdat[0]&rdat[2])|(rdat[1]&rdat[2]);
	end
default:
	;
endcase

endmodule
