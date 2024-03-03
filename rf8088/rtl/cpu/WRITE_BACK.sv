// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  WRITE_BACK state
//  - update the register file
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

if (wrregs)
	case({w,rrr})
	4'b0000:	ax[7:0] <= res[7:0];
	4'b0001:	cx[7:0] <= res[7:0];
	4'b0010:	dx[7:0] <= res[7:0];
	4'b0011:	bx[7:0] <= res[7:0];
	4'b0100:	ax[15:8] <= res[7:0];
	4'b0101:	cx[15:8] <= res[7:0];
	4'b0110:	dx[15:8] <= res[7:0];
	4'b0111:	bx[15:8] <= res[7:0];
	4'b1000:	ax <= res;
	4'b1001:	cx <= res;
	4'b1010:	dx <= res;
	4'b1011:	begin bx <= res; $display("BX <- %h", res); end
	4'b1100:	sp <= res;
	4'b1101:	bp <= res;
	4'b1110:	si <= res;
	4'b1111:	di <= res;
	endcase

// Write to segment register
//
if (wrsregs)
	case(rrr)
	3'd0:	es <= res;
	3'd1:	cs <= res;
	3'd2:	ss <= res;
	3'd3:	ds <= res;
	default:	;
	endcase
