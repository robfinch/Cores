// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_AddressGen.sv
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

module FAL6567_AddressGen(clk33, phi02, col80, bmm, ecm, vicCycle, refcntr,
	vm, vmndx, cb, scanline, nextChar, sprite, sprite1, MCnt, MPtr, vicAddr);
input clk33;
input phi02;
input col80;
input bmm;
input ecm;
input [2:0] vicCycle;
input [7:0] refcntr;
input [13:0] vm;
input [10:0] vmndx;
input [13:0] cb;
input [2:0] scanline;
input [11:0] nextChar;
input [3:0] sprite;
input [8:0] sprite1;
input [5:0] MCnt [MIBCNT-1:0];
input [7:0] MPtr [MIBCNT-1:0];
output reg [13:0] vicAddr;

reg [13:0] addr;

always_comb
begin
	case(vicCycle)
	VIC_REF:
		addr <= {6'b111111,refcntr};
	VIC_RC:
		if (phi02==`HIGH)
			addr <= vm + vmndx;
		else    
			addr <= {6'b111111,refcntr};
	VIC_CHAR,VIC_G:
		begin
			if (phi02==`HIGH || col80)
				addr <= vm + vmndx;
			else begin
				if (bmm)
					addr <= {cb[13],12'd0} + {vmndx,scanline};
				else
					addr <= {cb[13:11],nextChar[7:0],scanline};
				if (ecm)
					addr[10:9] <= 2'b00;
			end
		end
	VIC_CHARBMP:
		if (phi02==`LOW)
			addr <= {cb[13:11],nextChar[7:0],scanline};
	VIC_SPRITE:
		if (phi02==`LOW && sprite1[4]) begin
			addr <= vm + {14'b00001111111,sprite[2:0]};
		end
		else
			addr <= {MPtr[sprite],MCnt[sprite]};
	default: addr <= 14'h3FFF;
	endcase
end

always_ff @(posedge clk33)
	vicAddr <= addr;

endmodule
