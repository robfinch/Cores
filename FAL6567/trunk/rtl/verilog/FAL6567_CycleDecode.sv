// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_CycleDecode.sv
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

module FAL6567_CycleDecode(rst, clk, delay, enaData, phi02, chip, col80, preRasterX, vicCycle);
input rst;
input clk;
input [6:0] delay;
input enaData;
input phi02;
input [1:0] chip;
input col80;
input [10:0] preRasterX;
output reg [2:0] vicCycle;

wire [10:0] rasterX2 = {preRasterX,1'b0};
reg [10:0] vicCycNuma [0:127];
reg [10:0] vicCycNum;
integer n;
always_ff @(posedge clk)
if (rst) begin
	for (n = 0; n < 128; n = n + 1)
		vicCycNuma[n] <= 11'd0;
end
else begin
	if (!phi02 & enaData) begin
		vicCycNuma[0] <= rasterX2;
		for (n = 0; n < 128; n = n + 1)
			vicCycNuma[n+1] <= vicCycNuma[n];
	end
end

always_ff @(posedge clk)
if (rst)
	vicCycNum <= 11'd0;
else begin
	if (!phi02 & enaData)
		vicCycNum <= vicCycNuma[delay];
end

always_comb
if (col80) begin
	casez(vicCycNum)
	11'h00?: vicCycle <= VIC_REF;
	11'h01?: vicCycle <= VIC_REF;
	11'h02?: vicCycle <= VIC_REF;
	11'h03?: vicCycle <= VIC_REF;
	11'h04?: vicCycle <= VIC_RC;
	11'h05?: vicCycle <= VIC_CHAR;
	11'h06?: vicCycle <= VIC_CHAR;
	11'h07?: vicCycle <= VIC_CHAR;
	11'h08?: vicCycle <= VIC_CHAR;
	11'h09?: vicCycle <= VIC_CHAR;
	11'h0A?: vicCycle <= VIC_CHAR;
	11'h0B?: vicCycle <= VIC_CHAR;
	11'h0C?: vicCycle <= VIC_CHAR;
	11'h0D?: vicCycle <= VIC_CHAR;
	11'h0E?: vicCycle <= VIC_CHAR;
	11'h0F?: vicCycle <= VIC_CHAR;
	11'h10?: vicCycle <= VIC_CHAR;
	11'h11?: vicCycle <= VIC_CHAR;
	11'h12?: vicCycle <= VIC_CHAR;
	11'h13?: vicCycle <= VIC_CHAR;
	11'h14?: vicCycle <= VIC_CHAR;
	11'h15?: vicCycle <= VIC_CHAR;
	11'h16?: vicCycle <= VIC_CHAR;
	11'h17?: vicCycle <= VIC_CHAR;
	11'h18?: vicCycle <= VIC_CHAR;
	11'h19?: vicCycle <= VIC_CHAR;
	11'h1A?: vicCycle <= VIC_CHAR;
	11'h1B?: vicCycle <= VIC_CHAR;
	11'h1C?: vicCycle <= VIC_CHAR;
	11'h1D?: vicCycle <= VIC_CHAR;
	11'h1E?: vicCycle <= VIC_CHAR;
	11'h1F?: vicCycle <= VIC_CHAR;
	11'h20?: vicCycle <= VIC_CHAR;
	11'h21?: vicCycle <= VIC_CHAR;
	11'h22?: vicCycle <= VIC_CHAR;
	11'h23?: vicCycle <= VIC_CHAR;
	11'h24?: vicCycle <= VIC_CHAR;
	11'h25?: vicCycle <= VIC_CHAR;
	11'h26?: vicCycle <= VIC_CHAR;
	11'h27?: vicCycle <= VIC_CHAR;
	11'h28?: vicCycle <= VIC_CHAR;
	11'h29?: vicCycle <= VIC_CHAR;
	11'h2A?: vicCycle <= VIC_CHAR;
	
	11'h2B?: vicCycle <= VIC_CHAR;
	11'h2C?: vicCycle <= VIC_CHAR;
	11'h2D?: vicCycle <= VIC_CHAR;
	11'h2E?: vicCycle <= VIC_CHAR;
	11'h2F?: vicCycle <= VIC_CHAR;
	11'h30?: vicCycle <= VIC_CHAR;
	11'h31?: vicCycle <= VIC_CHAR;
	11'h32?: vicCycle <= VIC_CHAR;
	11'h33?: vicCycle <= VIC_CHAR;
	11'h34?: vicCycle <= VIC_CHAR;
	11'h35?: vicCycle <= VIC_CHAR;
	11'h36?: vicCycle <= VIC_CHAR;
	11'h37?: vicCycle <= VIC_CHAR;
	11'h38?: vicCycle <= VIC_CHAR;
	11'h39?: vicCycle <= VIC_CHAR;
	11'h3A?: vicCycle <= VIC_CHAR;
	11'h3B?: vicCycle <= VIC_CHAR;
	11'h3C?: vicCycle <= VIC_CHAR;
	11'h3D?: vicCycle <= VIC_CHAR;
	11'h3E?: vicCycle <= VIC_CHAR;
	11'h3F?: vicCycle <= VIC_CHAR;
	11'h40?: vicCycle <= VIC_CHAR;
	11'h41?: vicCycle <= VIC_CHAR;
	11'h42?: vicCycle <= VIC_CHAR;
	11'h43?: vicCycle <= VIC_CHAR;
	11'h44?: vicCycle <= VIC_CHAR;
	11'h45?: vicCycle <= VIC_CHAR;
	11'h46?: vicCycle <= VIC_CHAR;
	11'h47?: vicCycle <= VIC_CHAR;
	11'h48?: vicCycle <= VIC_CHAR;
	11'h49?: vicCycle <= VIC_CHAR;
	11'h4A?: vicCycle <= VIC_CHAR;
	11'h4B?: vicCycle <= VIC_CHAR;
	11'h4C?: vicCycle <= VIC_CHAR;
	11'h4D?: vicCycle <= VIC_CHAR;
	11'h4E?: vicCycle <= VIC_CHAR;
	11'h4F?: vicCycle <= VIC_CHAR;
	11'h50?: vicCycle <= VIC_CHAR;
	11'h51?: vicCycle <= VIC_CHAR;
	11'h52?: vicCycle <= VIC_CHAR;
	default:
	casez(vicCycNum)
	11'h53?: vicCycle <= VIC_G;
	11'h54?: vicCycle <= VIC_IDLE;
	11'h55?: vicCycle <= VIC_IDLE;
	11'h56?:
	        case(chip)
	        CHIP6567R8:   vicCycle <= VIC_IDLE;
	        CHIP6567OLD:  vicCycle <= VIC_IDLE;
	        default:      vicCycle <= VIC_SPRITE;
	        endcase
	11'h57?:
	        case(chip)
	        CHIP6567R8:   vicCycle <= VIC_IDLE;
	        CHIP6567OLD:  vicCycle <= VIC_SPRITE;
	        default:      vicCycle <= VIC_SPRITE;
	        endcase
	11'h58?:  vicCycle <= VIC_SPRITE;
	11'h59?:  vicCycle <= VIC_SPRITE;
	11'h5A?:  vicCycle <= VIC_SPRITE;
	11'h5B?:  vicCycle <= VIC_SPRITE;
	11'h5C?:  vicCycle <= VIC_SPRITE;
	11'h5D?:  vicCycle <= VIC_SPRITE;
	11'h5E?:  vicCycle <= VIC_SPRITE;
	11'h5F?:  vicCycle <= VIC_SPRITE;
	11'h60?:  vicCycle <= VIC_SPRITE;
	11'h61?:  vicCycle <= VIC_SPRITE;
	11'h62?:  vicCycle <= VIC_SPRITE;
	11'h63?:  vicCycle <= VIC_SPRITE;
	11'h64?:  vicCycle <= VIC_SPRITE;
	11'h65?:  vicCycle <= VIC_SPRITE;
	11'h66?:  vicCycle <= VIC_SPRITE;
	11'h67?:  vicCycle <= VIC_SPRITE;
	11'h68?:  vicCycle <= VIC_SPRITE;
	11'h69?:  vicCycle <= VIC_SPRITE;
	11'h6A?:  vicCycle <= VIC_SPRITE;
	11'h6B?:  vicCycle <= VIC_SPRITE;
	11'h6C?:  vicCycle <= VIC_SPRITE;
	11'h6D?:  vicCycle <= VIC_SPRITE;
	11'h6E?:  vicCycle <= VIC_SPRITE;
	11'h6F?:  vicCycle <= VIC_SPRITE;
	11'h70?:  vicCycle <= VIC_SPRITE;
	11'h71?:  vicCycle <= VIC_SPRITE;
	11'h72?:  vicCycle <= VIC_SPRITE;
	11'h73?:  vicCycle <= VIC_SPRITE;
	11'h74?:  vicCycle <= VIC_SPRITE;
	11'h75?:  vicCycle <= VIC_SPRITE;
	11'h76?:
	        case(chip)
	        CHIP6567R8:   vicCycle <= VIC_SPRITE;
	        CHIP6567OLD:  vicCycle <= VIC_SPRITE;
	        default:      vicCycle <= VIC_REF;
	        endcase
	11'h77?:
	        case(chip)
	        CHIP6567R8:   vicCycle <= VIC_SPRITE;
	        CHIP6567OLD:  vicCycle <= VIC_REF;
	        default:      vicCycle <= VIC_REF;
	        endcase
	11'h78?:  vicCycle <= VIC_REF;
	default:  vicCycle <= VIC_IDLE;
	endcase
	endcase
end
else begin
	casez(vicCycNum)
	11'h00?: vicCycle <= VIC_REF;
	11'h01?: vicCycle <= VIC_REF;
	11'h02?: vicCycle <= VIC_REF;
	11'h03?: vicCycle <= VIC_REF;
	11'h04?: vicCycle <= VIC_RC;
	11'h05?: vicCycle <= VIC_CHAR;
	11'h06?: vicCycle <= VIC_CHAR;
	11'h07?: vicCycle <= VIC_CHAR;
	11'h08?: vicCycle <= VIC_CHAR;
	11'h09?: vicCycle <= VIC_CHAR;
	11'h0A?: vicCycle <= VIC_CHAR;
	11'h0B?: vicCycle <= VIC_CHAR;
	11'h0C?: vicCycle <= VIC_CHAR;
	11'h0D?: vicCycle <= VIC_CHAR;
	11'h0E?: vicCycle <= VIC_CHAR;
	11'h0F?: vicCycle <= VIC_CHAR;
	11'h10?: vicCycle <= VIC_CHAR;
	11'h11?: vicCycle <= VIC_CHAR;
	11'h12?: vicCycle <= VIC_CHAR;
	11'h13?: vicCycle <= VIC_CHAR;
	11'h14?: vicCycle <= VIC_CHAR;
	11'h15?: vicCycle <= VIC_CHAR;
	11'h16?: vicCycle <= VIC_CHAR;
	11'h17?: vicCycle <= VIC_CHAR;
	11'h18?: vicCycle <= VIC_CHAR;
	11'h19?: vicCycle <= VIC_CHAR;
	11'h1A?: vicCycle <= VIC_CHAR;
	11'h1B?: vicCycle <= VIC_CHAR;
	11'h1C?: vicCycle <= VIC_CHAR;
	11'h1D?: vicCycle <= VIC_CHAR;
	11'h1E?: vicCycle <= VIC_CHAR;
	11'h1F?: vicCycle <= VIC_CHAR;
	11'h20?: vicCycle <= VIC_CHAR;
	11'h21?: vicCycle <= VIC_CHAR;
	11'h22?: vicCycle <= VIC_CHAR;
	11'h23?: vicCycle <= VIC_CHAR;
	11'h24?: vicCycle <= VIC_CHAR;
	11'h25?: vicCycle <= VIC_CHAR;
	11'h26?: vicCycle <= VIC_CHAR;
	11'h27?: vicCycle <= VIC_CHAR;
	11'h28?: vicCycle <= VIC_CHAR;
	11'h29?: vicCycle <= VIC_CHAR;
	11'h2A?: vicCycle <= VIC_CHAR;
	default:
	casez(vicCycNum)
	11'h2B?: vicCycle <= VIC_G;
	11'h2C?: vicCycle <= VIC_IDLE;
	11'h2D?: vicCycle <= VIC_IDLE;
	11'h2E?:
	        case(chip)
	        CHIP6567R8:   vicCycle <= VIC_IDLE;
	        CHIP6567OLD:  vicCycle <= VIC_IDLE;
	        default:      vicCycle <= VIC_SPRITE;
	        endcase
	11'h2F?:
	        case(chip)
	        CHIP6567R8:   vicCycle <= VIC_IDLE;
	        CHIP6567OLD:  vicCycle <= VIC_SPRITE;
	        default:      vicCycle <= VIC_SPRITE;
	        endcase
	11'h30?:  vicCycle <= VIC_SPRITE;
	11'h31?:  vicCycle <= VIC_SPRITE;
	11'h32?:  vicCycle <= VIC_SPRITE;
	11'h33?:  vicCycle <= VIC_SPRITE;
	11'h34?:  vicCycle <= VIC_SPRITE;
	11'h35?:  vicCycle <= VIC_SPRITE;
	11'h36?:  vicCycle <= VIC_SPRITE;
	11'h37?:  vicCycle <= VIC_SPRITE;
	11'h38?:  vicCycle <= VIC_SPRITE;
	11'h39?:  vicCycle <= VIC_SPRITE;
	11'h3A?:  vicCycle <= VIC_SPRITE;
	11'h3B?:  vicCycle <= VIC_SPRITE;
	11'h3C?:  vicCycle <= VIC_SPRITE;
	11'h3D?:  vicCycle <= VIC_SPRITE;
	11'h3E?:
	        case(chip)
	        CHIP6567R8:   vicCycle <= VIC_SPRITE;
	        CHIP6567OLD:  vicCycle <= VIC_SPRITE;
	        default:      vicCycle <= VIC_REF;
	        endcase
	11'h3F?:
	        case(chip)
	        CHIP6567R8:   vicCycle <= VIC_SPRITE;
	        CHIP6567OLD:  vicCycle <= VIC_REF;
	        default:      vicCycle <= VIC_REF;
	        endcase
	11'h40?:  vicCycle <= VIC_REF;
	default:  vicCycle <= VIC_IDLE;
	endcase
	endcase
end
endmodule
