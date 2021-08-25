// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
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
	RamCEn, RamWEn, RamOEn, MemAdr, MemDB);
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
inout [7:0] MemDB;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;

reg [3:0] state;
parameter IDLE = 4'd0;
parameter RD1 = 4'd1;
parameter WR1 = 4'd2;
parameter WR2 = 4'd3;
parameter WR3 = 4'd4;
parameter RWDONE = 4'd5;
parameter RWNACK = 4'd6;
parameter RD2 = 4'd7;
parameter WR0 = 4'd8;
reg [31:0] memDat;
reg [7:0] memDato;
reg memT;		    // tri-state for write
reg [3:0] sel;  // ring counter

always @(posedge clk_i)
if (rst_i) begin
	state <= IDLE;
	RamWEn <= HIGH;
	RamOEn <= HIGH;
	RamCEn <= HIGH;
	sel <= 4'b0;
	memT <= HIGH;
	ack_o <= 1'b0;
end
else
case(state)
IDLE:
	begin
		// Default action is to disable all bus drivers
		RamWEn <= HIGH;
		RamCEn <= HIGH;
		RamOEn <= HIGH;
		memT <= HIGH;
		if (cs_i & cyc_i & stb_i) begin
			RamCEn <= LOW;											// tell the ram it's selected
			MemAdr[18:2] <= adr_i[18:2];
			memDat <= dat_i;
			casez(sel_i)
			4'b???1:	begin MemAdr[1:0] <= 2'b00; sel <= sel_i; end
			4'b??10:	begin MemAdr[1:0] <= 2'b01; sel <= {1'b0,sel_i[3:1]}; end
			4'b?100:	begin MemAdr[1:0] <= 2'b10; sel <= {2'b0,sel_i[3:2]}; end
			4'b1000:	begin MemAdr[1:0] <= 2'b11; sel <= {3'b0,sel_i[3]}; end
			endcase
			state <= we_i ? WR0 : RD2;
			if (!we_i)						// For a read cycle enable the ram's output drivers
				RamOEn <= LOW;
			else
				memT <= LOW;
		end
	end
	// For a read, after a clock cycle latch the input data.
	// Increment the memory address and count.
	// Simply stay in this state until the count expires.
RD1:
	begin
		case(MemAdr[1:0])
		2'd0:	dat_o[7:0] <= MemDB;
		2'd1: dat_o[15:8] <= MemDB;
		2'd2:	dat_o[23:16] <= MemDB;
		2'd3:	dat_o[31:24] <= MemDB;
		endcase
		MemAdr[1:0] <= MemAdr[1:0] + 2'd1;
		sel <= {1'b0,sel[3:1]};
		if (sel[3:1]==3'b0)
			state <= RWDONE;
		else
			state <= RD2;
	end
	// Gives more time for address settling, variation in I/O delay.
RD2:
	state <= RD1;

WR0:
  begin
	  case(MemAdr[1:0])
	  2'd0: memDato <= memDat[7:0];
	  2'd1: memDato <= memDat[15:8];
	  2'd2: memDato <= memDat[23:16];
	  2'd3: memDato <= memDat[31:24];
	  default:  ;
	  endcase
		RamWEn <= ~sel_i[MemAdr[1:0]];
	  state <= WR2;
  end
	// For a write cycle begin by enabling the ram's write input.
WR1:
	begin
		state <= WR2;
	end
	// AFter a cycle disable the write input. This will cause the ram to latch
	// the data.
WR2:
	begin
		RamWEn <= HIGH;
		state <= WR3;
	end
	// After another cycle increment the memory address and memory count.
	// If the count expired goto the done state, otherwise go back to the first
	// write state.
WR3:
	begin
		MemAdr[1:0] <= MemAdr[1:0] + 2'd1;
		sel <= {1'b0,sel[3:1]};
		if (sel[3:1]==3'b0)
			state <= RWDONE;
		else
			state <= WR0;
	end
	// Here a read/write is done. Signal the processor.
RWDONE:
	begin
		ack_o <= HIGH;
		state <= RWNACK;
	end
	// Wait until the processor is done with the read / write then go back to the
	// idle state to wait for another operation.
RWNACK:
	if (!(cs_i & cyc_i & stb_i)) begin
		memT <= HIGH;
		ack_o <= LOW;
		state <= IDLE;
	end
default:
	state <= IDLE;
endcase

// Assign the memory bus tri-state unless a write is occuring.
// Reading the ram will override the tri-state drivers.
assign MemDB = memT ? 8'bz : memDato;

endmodule
