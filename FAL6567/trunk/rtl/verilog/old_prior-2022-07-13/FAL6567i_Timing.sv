// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567i_Timing.sv
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

module FAL6567i_Timing(rst, clk28, stc, phi02, phi02r, busCycle, ras_n, mux, cas_n,
	enaData, enaMCnt);
input rst;
input clk28;
output reg [31:0] stc;
output reg phi02;
output reg [31:0] phi02r;
input [2:0] busCycle;
output ras_n;
output mux;
output cas_n;
output enaData;
output enaMCnt;

reg [31:0] rasr;
reg [31:0] muxr;
reg [31:0] casr;
reg [31:0] enaDatar;
wire stCycle = stc[31];
wire stCycle1 = stc[0];
wire stCycle2 = stc[1];
wire stCycle3 = stc[2];

// 1.022 MHz enable
always_ff @(posedge clk28)
if (rst)
	stc <= 28'b1000000000000000000000000000;
else
	stc <= {stc[26:0],stc[27]};

always_ff @(posedge clk28)
if (rst)
	phi02r <= 28'b0000000000000011111111111111;
else begin
	phi02r <= {phi02r[26:0],phi02r[27]};
end
always_ff @(posedge clk28)
	phi02 <= phi02r[0];
//assign phi02 = phi02r[32];

always_ff @(posedge clk28)
if (rst) begin
	rasr <= 28'b1111111111111111111100000000;
end
else begin
	if (stCycle2) begin
		case(busCycle)
		BUS_IDLE:   rasr <= 28'b1111111111111111111100000000;  // I
		BUS_SPRITE: rasr <= 28'b1111100000000011111100000000;  // S
		BUS_CG:     rasr <= 28'b1111100000000011111100000000;  // G,C
		BUS_G:      rasr <= 28'b1111100000000011111100000000;  // G,C
		BUS_REF:    rasr <= 28'b1111100000000011111100000000;  // R,C or R
		default:		rasr <= 28'hFFFFFFF;
		endcase
		end
	else
		rasr <= {rasr[26:0],1'b0};
end
assign ras_n = rasr[27];
  
always_ff @(posedge clk28)
if (rst) begin
	muxr <= 28'b1111111111111111111110000000;  // I
end
else begin
	if (stCycle1) begin
		case(busCycle)
		BUS_IDLE:   muxr <= 28'b1111111111111111111110000000;  // I
		BUS_SPRITE: muxr <= 28'b1111110000000011111110000000;  // S
		BUS_CG:     muxr <= 28'b1111110000000011111110000000;  // G,C
		BUS_G:      muxr <= 28'b1111110000000011111110000000;  // G,C
		BUS_REF:    muxr <= 28'b1111110000000011111110000000;  // R,C or R
		default:		muxr <= 28'hFFFFFFF;
		endcase
		end
	else
		muxr <= {muxr[26:0],1'b0};
end
assign mux = muxr[27];
  
always_ff @(posedge clk28)
if (rst) begin
	casr <= 28'b1111111100000011111111000000;  // R,C
end
else begin
	if (stCycle2) begin
		case(busCycle)
		BUS_IDLE:   casr <= 28'b1111111111111111111111000000;  // I - cycle
		BUS_SPRITE: casr <= 28'b1111111100000011111111000000;  // S
		BUS_CG:     casr <= 28'b1111111100000011111111000000;  // G,C
		BUS_G:      casr <= 28'b1111111100000011111111000000;  // G,C
		BUS_REF:    casr <= 28'b1111111111111111111111000000;  // R,C
		default:		casr <= 28'hFFFFFFF;
		endcase
	end
	else
		casr <= {casr[26:0],1'b0};
end
assign cas_n = casr[27];

always_ff @(posedge clk28)
if (rst) begin
	enaDatar <= 28'b0000000000000100000000000001;  // S - cycle
end
else begin
	if (stCycle2)
		enaDatar <= 28'b0000000000000100000000000001;  // S - cycle
	else
		enaDatar <= {enaDatar[26:0],1'b0};
end
assign enaData = enaDatar[26];
assign enaMCnt = enaDatar[26];

endmodule
