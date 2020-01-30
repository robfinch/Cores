// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
module cs01memInterface(rst_i, clk_i,
	cs_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o, 
	RamCEn, RamWEn, RamOEn, MemAdr, MemDB);
input rst_i;
input clk_i;
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
reg [3:0] memCount;
reg [31:0] memDat;
reg memT;		// tri-state for write

always @(posedge clk_i)
if (rst_i) begin
	state <= IDLE;
	RamWEn <= HIGH;
	RamOEn <= HIGH;
	RamCEn <= HIGH;
	memCount <= 4'd0;
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
			MemAdr <= {adr_i[31:2],2'b0};
			memDat <= dat_i;
			memCount <= 4'd0;
			state <= we_i ? WR1 : RD2;
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
		case(memCount[1:0])
		2'd0:	dat_o[7:0] <= MemDB;
		2'd1: dat_o[15:8] <= MemDB;
		2'd2:	dat_o[23:16] <= MemDB;
		2'd3:	dat_o[31:24] <= MemDB;
		endcase
		MemAdr[1:0] <= MemAdr[1:0] + 2'd1;
		memCount <= memCount + 4'd1;
		if (memCount==4'd3)
			state <= RWDONE;
		else
			state <= RD2;
	end
	// Gives more time for address settling.
RD2:
	state <= RD1;

	// For a write cycle begin by enabling the ram's write input.
WR1:
	begin
		RamWEn <= ~sel_i[memCount];
		state <= WR2;
	end
	// AFter a cycle disable the write input. This will cause the ram to latch
	// the data.
WR2:
	begin
		RamWEn <= HIGH;
		state <= WR3;
	end
	// After another cycle, shift over the data to store to the ram.
	// increment the memory address and memory count.
	// If the count expired goto the done state, otherwise go back to the first
	// write state.
WR3:
	begin
		memDat <= {8'h00,memDat[31:8]};
		MemAdr[1:0] <= MemAdr[1:0] + 2'd1;
		memCount <= memCount + 2'd1;
		if (memCount==4'd3)
			state <= RWDONE;
		else
			state <= WR1;
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
assign MemDB = memT ? 8'bz : memDat[7:0];

endmodule
