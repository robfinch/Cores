// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_BusAvailGen.sv
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

module FAL6567_BusAvailGen(chip, rst, clk33, col80, me, my, badline,
	rasterX2, nextRasterY, MActive, stCycle2, ba);
input [1:0] chip;
input rst;
input clk33;
input col80;
input [MIBCNT-1:0] me;
input [7:0] my [MIBCNT-1:0];
input badline;
input [11:0] rasterX2;
input [8:0] nextRasterY;
input [MIBCNT-1:0] MActive;
input stCycle2;
output reg ba;

reg [MIBCNT-1:0] balos = 16'h0000;

//always @(chip,n,me,my,nextRasterY,rasterX2,MActive,leg)
integer n1;
always_ff @(posedge clk33)
	for (n1 = 0; n1 < MIBCNT; n1 = n1 + 1) begin
		if (me[n1] && ((my[n1]==nextRasterY[7:0])||MActive[n1])) begin
			if (col80) begin
				case(chip)
				CHIP6567R8:   balos[n1] <= (rasterX2 >= 12'h550 + {n1,5'b0}) && (rasterX2 < 12'h5A0 + {n1,5'b0});
				CHIP6567OLD:  balos[n1] <= (rasterX2 >= 12'h540 + {n1,5'b0}) && (rasterX2 < 12'h590 + {n1,5'b0});
				default:      balos[n1] <= (rasterX2 >= 12'h530 + {n1,5'b0}) && (rasterX2 < 12'h580 + {n1,5'b0}); 
				endcase
			end
			else begin
				case(chip)
				CHIP6567R8:   balos[n1] <= (rasterX2 >= 12'h2D0 + {n1,5'b0}) && (rasterX2 < 12'h320 + {n1,5'b0});
				CHIP6567OLD:  balos[n1] <= (rasterX2 >= 12'h2C0 + {n1,5'b0}) && (rasterX2 < 12'h310 + {n1,5'b0});
				default:      balos[n1] <= (rasterX2 >= 12'h2B0 + {n1,5'b0}) && (rasterX2 < 12'h300 + {n1,5'b0}); 
				endcase
			end
		end
		else begin
			balos[n1] <= `FALSE;
		end
	end

reg [10:0] baloff;
always_ff @(posedge clk33)
if (col80)
	case(chip)
	2'b00:	baloff <= 11'h540;
	2'b01:	baloff <= 11'h530;
	2'b10:	baloff <= 11'h520;
	2'b11:	baloff <= 11'h520;
	endcase
else
	case(chip)
	2'b00:	baloff <= 11'h2C0;
	2'b01:	baloff <= 11'h2B0;
	2'b10:	baloff <= 11'h2A0;
	2'b11:	baloff <= 11'h2A0;
	endcase
wire balo = |balos | (badline && rasterX2 < baloff);


//------------------------------------------------------------------------------
// Bus available drives the processor's ready line. So the ready line is held
// inactive until the FPGA is loaded and the pll is locked.
//------------------------------------------------------------------------------

reg ba1;
always_ff @(posedge clk33)
if (rst) begin
	ba1 <= `LOW;
end
else begin
	if (stCycle2)
  	ba1 <= !balo;
end
always_ff @(posedge clk33)
	ba <= ba1;

endmodule
