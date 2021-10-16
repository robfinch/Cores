// ============================================================================
//        __
//   \\__/ o\    (C) 2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Thor2021_eval_branch.sv
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

import Thor2021_pkg::*;

module Thor2021_eval_branch(inst, a, b, takb);
input Instruction inst;
input Value a;
input Value b;
output reg takb;

always_comb
case(inst.br.opcode)
BEQ: 	takb = a == b;
BNE: 	takb = a != b;
BLT: 	takb = $signed(a) < $signed(b);
BGE:	takb = $signed(a) >= $signed(b);
BLE:	takb = $signed(a) <= $signed(b);
BGT:	takb = $signed(a) > $signed(b);
BLTU: takb = a < b;
BGEU: takb = a >= b;
BLEU:	takb = a <= b;
BGTU:	takb = a > b;
BBC:	takb = ~a[b[5:0]];
BBS:	takb =  a[b[5:0]];
BEQL: 	takb = a == b;
BNEL: 	takb = a != b;
BLTL: 	takb = $signed(a) < $signed(b);
BGEL:		takb = $signed(a) >= $signed(b);
BLEL:		takb = $signed(a) <= $signed(b);
BGTL:		takb = $signed(a) > $signed(b);
BLTUL: 	takb = a < b;
BGEUL: 	takb = a >= b;
BLEUL:	takb = a <= b;
BGTUL:	takb = a > b;
BBCL:		takb = ~a[b[5:0]];
BBSL:		takb =  a[b[5:0]];
default:  takb = 1'b0;
endcase

endmodule
