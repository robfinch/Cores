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
RWNACK:
	if (!csi)
		state <= IDLE;
default:
	state <= IDLE;
endcase
end

always @(posedge clk_i)
if (rst_i) begin
	RamWEn <= HIGH;
	RamOEn <= HIGH;
	RamCEn <= HIGH;
	sel <= 4'b0;
	MemT <= HIGH;
	ack_o <= 1'b0;
	badram <= 1'b0;
	errcnt <= 4'd0;
	rc <= 1'b1;
end
else
case(state)
IDLE:
	begin
		// Default action is to disable all bus drivers
		ack_o <= LOW;
		badram <= 1'b0;
		errcnt <= 4'd0;
		RamWEn <= HIGH;
		RamCEn <= HIGH;
		RamOEn <= HIGH;
		MemT <= HIGH;
		rdat[0] <= 32'h0;
		if (csi) begin
			tmr <= 2'b00;
			MemAdr[18:2] <= adr_i[18:2];
			memDat <= dat_i;
			casez(sel_i)
			4'b???1:	begin MemAdr[1:0] <= 2'b00; sel <= sel_i; end
			4'b??10:	begin MemAdr[1:0] <= 2'b01; sel <= {1'b0,sel_i[3:1]}; end
			4'b?100:	begin MemAdr[1:0] <= 2'b10; sel <= {2'b0,sel_i[3:2]}; end
			4'b1000:	begin MemAdr[1:0] <= 2'b11; sel <= {3'b0,sel_i[3]}; end
			endcase
			RamCEn <= LOW;					// tell the ram it's selected
			// For a read cycle enable the ram's output drivers
			// For a write cycle send back an ack right away.
			if (!we_i) begin
				rc <= 1'b1;
				RamOEn <= LOW;
			end
			else begin
				rc <= 1'b0;
				ack_o <= HIGH;
				MemT <= LOW;
			end
		end
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
		sel <= {1'b0,sel[3:1]};
	end

// Gives more time for address settling, variation in I/O delay.
// The write signal is checked here in case the write signal shows up delayed by
// a cycle.
RD2:
	if (we_i) begin
		MemT <= LOW;
		RamOEn <= HIGH;
		if (!csi)
			ack_o <= LOW;
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
		RamWEn <= LOW;
		if (!csi)
			ack_o <= LOW;
  end
	// AFter a cycle disable the write input. This will cause the ram to latch
	// the data.
WR1:
	begin
		RamWEn <= HIGH;
		MemT <= HIGH;
		RamOEn <= LOW;
		if (!csi)
			ack_o <= LOW;
	end
WR2:
	begin
		if (MemDB_i != MemDB_o) begin
			MemT <= LOW;
			RamOEn <= HIGH;
			errcnt <= errcnt + 2'd1;
			if (errcnt==4'd10) begin
				badram <= 1'b1;
				RamCEn <= HIGH;
				RamWEn <= HIGH;
			end
		end
		else begin
			RamCEn <= HIGH;
			RamWEn <= HIGH;
		end
		if (!csi)
			ack_o <= LOW;
	end
	// After another cycle increment the memory address and memory count.
	// If the count expired goto the done state, otherwise go back to the first
	// write state.
WR3:
	begin
		RamCEn <= HIGH;
		RamWEn <= HIGH;
		MemAdr[1:0] <= MemAdr[1:0] + 2'd1;
		sel <= {1'b0,sel[3:1]};
		if (sel[3:1]!=3'b0)
			errcnt <= 4'd0;
		if (!csi)
			ack_o <= LOW;
	end
	// Here a read/write is done. Signal the processor.
RWDONE:
	begin
		badram <= 1'b0;
		RamOEn <= HIGH;
		MemT <= HIGH;
//		dat_o <= (rdat[0]&rdat[1])|(rdat[0]&rdat[2])|(rdat[1]&rdat[2]);
		dat_o <= rdat[0];
		if (rc)
			ack_o <= HIGH;
		else if (!csi)
			ack_o <= LOW;
	end
	// Wait until the processor is done with the read / write then go back to the
	// idle state to wait for another operation.
RWNACK:
	if (!csi) begin
		ack_o <= LOW;
	end
default:
	;
endcase

endmodule
