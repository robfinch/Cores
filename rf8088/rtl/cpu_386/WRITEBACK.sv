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
	case({cs_desc.db,w,rrr})
	5'b?0000:	eax[7:0] <= res[7:0];
	5'b?0001:	ecx[7:0] <= res[7:0];
	5'b?0010:	edx[7:0] <= res[7:0];
	5'b?0011:	ebx[7:0] <= res[7:0];
	5'b?0100:	eax[15:8] <= res[7:0];
	5'b?0101:	ecx[15:8] <= res[7:0];
	5'b?0110:	edx[15:8] <= res[7:0];
	5'b?0111:	ebx[15:8] <= res[7:0];
	5'b01000:	eax[15:0] <= res;
	5'b01001:	ecx[15:0] <= res;
	5'b01010:	edx[15:0] <= res;
	5'b01011:	begin ebx[15:0] <= res; $display("BX <- %h", res); end
	5'b01100:	esp[15:0] <= res;
	5'b01101:	ebp[15:0] <= res;
	5'b01110:	esi[15:0] <= res;
	5'b01111:	edi[15:0] <= res;
	5'b11000:	eax <= res;
	5'b11001:	ecx <= res;
	5'b11010:	edx <= res;
	5'b11011:	begin ebx <= res; $display("BX <- %h", res); end
	5'b11100:	esp <= res;
	5'b11101:	ebp <= res;
	5'b11110:	esi <= res;
	5'b11111:	edi <= res;
	endcase

// Write to segment register
//
if (wrsregs)
	case(rrr)
	3'd0:	es <= res;
	3'd1:	cs <= res;
	3'd2:	ss <= res;
	3'd3:	ds <= res;
	3'd4:	fs <= res;
	3'd5:	gs <= res;
	default:	;
	endcase
