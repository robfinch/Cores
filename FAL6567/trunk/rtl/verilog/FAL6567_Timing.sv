// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_Timing.sv
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
import FAL6567_pkg::*;

module FAL6567_Timing(rst, clk33, clken8, stc, phi02, phi02r, busCycle, ras_n, mux, cas_n,
	enaData, enaMCnt);
input rst;
input clk33;
output clken8;
output reg [31:0] stc;
output reg phi02;
output reg [31:0] phi02r;
input [2:0] busCycle;
output reg ras_n;
output reg mux;
output reg cas_n;
output reg enaData;
output enaMCnt;

reg [31:0] clk8r;
reg [31:0] rasr;
reg [31:0] muxr;
reg [31:0] casr;
reg [31:0] enaDatar;
wire stCycle = stc[31];
wire stCycle1 = stc[0];
wire stCycle2 = stc[1];
wire stCycle3 = stc[2];

// 8.18 MHz enable
always_ff @(posedge clk33)
if (rst) begin
	clk8r <= 32'b10001000100010001000100010001000;
end
else begin
	if (stCycle)
		clk8r <= 32'b00010001000100010001000100010001;
	else
		clk8r <= {clk8r[30:0],clk8r[31]};
end
assign clken8 = clk8r[31];

// 1.022 MHz enable
always_ff @(posedge clk33)
if (rst)
	stc <= 32'b10000000000000000000000000000000;
else
	stc <= {stc[30:0],stc[31]};

always_ff @(posedge clk33)
if (rst)
	phi02r <= 32'b00000000000000001111111111111111;
else begin
	if (stCycle2)
		phi02r <= 32'b00000000000000001111111111111111;
	else
		phi02r <= {phi02r[30:0],1'b0};
end
reg phi02a;
always_ff @(posedge clk33)
	phi02 <= phi02r[31];
//assign phi02 = phi02r[32];

// RAS precharge time = 4*30.6=122.2 ns
// RAS active time = 12*30.6 = 366.7 ns
always_ff @(posedge clk33)
if (rst) begin
	rasr <= 32'b11111111111111111111000000000000;
end
else begin
	if (stCycle2) begin
		case(busCycle)
		BUS_IDLE:   rasr <= 32'b11111111111111111111000000000000;  // I
		BUS_SPRITE: rasr <= 32'b11110000000000001111000000000000;  // S
		BUS_CG:     rasr <= 32'b11110000000000001111000000000000;  // G,C
		BUS_G:      rasr <= 32'b11110000000000001111000000000000;  // G,C
		BUS_REF:    rasr <= 32'b11110000000000001111000000000000;  // R,C or R
		default:		rasr <= 32'hFFFFFFFF;
		endcase
		end
	else
		rasr <= {rasr[30:0],1'b0};
end
reg ras1;
always_ff @(posedge clk33)
	ras1 <= rasr[31];
always_ff @(negedge clk33)
	ras_n <= ras1;

always_ff @(posedge clk33)
if (rst) begin
	muxr <= 32'b11111111111111111111100000000000;  // I
end
else begin
	if (stCycle2) begin
		case(busCycle)
		BUS_IDLE:   muxr <= 32'b11111111111111111111100000000000;  // I
		BUS_SPRITE: muxr <= 32'b11111000000000001111100000000000;  // S
		BUS_CG:     muxr <= 32'b11111000000000001111100000000000;  // G,C
		BUS_G:      muxr <= 32'b11111000000000001111100000000000;  // G,C
		BUS_REF:    muxr <= 32'b11111111111111111111100000000000;  // R,C or R
		default:		muxr <= 32'hFFFFFFFF;
		endcase
		end
	else
		muxr <= {muxr[30:0],1'b0};
end
reg mux1;
always_ff @(posedge clk33)
	mux1 <= muxr[31];
always_ff @(negedge clk33)
	mux <= mux1;
  
// CAS active time = 10*30.6 = 305.6 ns
always_ff @(posedge clk33)
if (rst) begin
	casr <= 32'b11111111111000001111111111100000;  // R,C
end
else begin
	if (stCycle2) begin
		case(busCycle)
		BUS_IDLE:   casr <= 32'b11111111111111111111110000000000;  // I - cycle
		BUS_SPRITE: casr <= 32'b11111100000000001111110000000000;  // S
		BUS_CG:     casr <= 32'b11111100000000001111110000000000;  // G,C
		BUS_G:      casr <= 32'b11111100000000001111110000000000;  // G,C
		BUS_REF:    casr <= 32'b11111111111111111111110000000000;  // R,C
		default:		casr <= 32'hFFFFFFFF;
		endcase
	end
	else
		casr <= {casr[30:0],1'b0};
end
reg cas1;
always_ff @(posedge clk33)
	cas1 <= casr[31];
always_ff @(negedge clk33)
	cas_n <= cas1;

always_ff @(posedge clk33)
if (rst) begin
	enaDatar <= 32'b00000000000000010000000000000001;  // S - cycle
end
else begin
	if (stCycle2)
		enaDatar <= 32'b00000000000000010000000000000001;  // S - cycle
	else
		enaDatar <= {enaDatar[30:0],1'b0};
end
always_ff @(posedge clk33)
	enaData <= enaDatar[31];
assign enaMCnt = enaDatar[31];

endmodule
