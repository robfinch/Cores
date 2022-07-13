// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FAL6567_sync.v
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
`define TRUE	1'b1
`define FALSE	1'b0

module FAL6567_sync(chip, rst, clk, rasterX, rasterY, hSync, vSync, cSync, burstWindow);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;
input [1:0] chip;
input rst;
input clk;
input [10:0] rasterX;
input [8:0] rasterY;
output reg hSync;
output reg vSync;
output reg cSync;
output reg burstWindow;

always_ff @(posedge clk)
if (rst)
	vSync <= `FALSE;
else begin
	case(chip)
	CHIP6567R8,CHIP6567OLD:
		if (rasterY >= 3 && rasterY < 6)
			vSync <= `TRUE;
		else
			vSync <= `FALSE;
	CHIP6569,CHIP6572:
		if (rasterY >= 313 || rasterY < 3)
			vSync <= `TRUE;
		else
			vSync <= `FALSE;
	endcase
end

reg [9:0] hSyncWidth;
always_ff @(posedge clk)
case(chip)
CHIP6567R8,CHIP6567OLD:
	hSyncWidth <= 11'd42;
CHIP6569,CHIP6572:
	hSyncWidth <= 11'd37;
endcase
always_ff @(posedge clk)
begin
	hSync <= `FALSE;
	if (rasterX < hSyncWidth)	// 8%
		hSync <= `TRUE;
end

// Compute Equalization pulses
wire EQ, SE;
EqualizationPulse ueqp1
(
	.chip(chip),
	.rasterX(rasterX),
	.EQ(EQ)
);

// Compute Serration pulses
SerrationPulse usep1
(
	.chip(chip),
	.rasterX(rasterX),
	.SE(SE)
);

// Compute composite sync.
// sync is negative going
always_ff @(posedge clk)
case(chip)
CHIP6567R8,CHIP6567OLD,
CHIP6569,CHIP6572:
	case(rasterY)
	9'd0:	cSync <= ~EQ;
	9'd1:	cSync <= ~EQ;
	9'd2:	cSync <= ~EQ;
	9'd3:	cSync <= ~SE;
	9'd4:	cSync <= ~SE;
	9'd5:	cSync <= ~SE;
	9'd6:	cSync <= ~EQ;
	9'd7:	cSync <= ~EQ;
	9'd8:	cSync <= ~EQ;
	default:
			cSync <= ~hSync;
	endcase
endcase

//------------------------------------------------------------------------------
// Color burst window.
// - determines when color burst should be output.
//------------------------------------------------------------------------------

reg [10:0] burstWindowBegin;
reg [10:0] burstWindowEnd;
// 504
always @(posedge clk)
case(chip)
CHIP6567R8,CHIP6567OLD:
	burstWindowBegin <= 11'd43;
CHIP6569,CHIP6572:
	burstWindowBegin <= 11'd44;
endcase
always @(posedge clk)
case(chip)
CHIP6567R8,CHIP6567OLD:
	burstWindowEnd <= 11'd63;
CHIP6569,CHIP6572:
	burstWindowEnd <= 11'd62;
endcase
reg burstWindow;
always @(posedge clk)
begin
	if (rasterX >= burstWindowBegin && rasterX < burstWindowEnd && rasterY > 8)
		burstWindow <= `TRUE;
	else
		burstWindow <= `FALSE;
end

endmodule
