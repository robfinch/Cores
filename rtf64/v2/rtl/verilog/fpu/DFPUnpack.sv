// ============================================================================
//        __
//   \\__/ o\    (C) 2020-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DPDUnpack.sv
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

import DFPPkg::*;

module DFPUnpack128(i, o);
input DFP128 i;
output DFP128U o;

assign o.sign = i.sign;
assign o.exp = {i.combo[4:3]==2'b11 ? i.combo[2:1] : i.combo[4:3],i.expc};
assign o.nan = i.combo==5'b11111;
assign o.qnan = i.combo==5'b11111 && i.expc[11]==1'b0;
assign o.snan = i.combo==5'b11111 && i.expc[11]==1'b1;
assign o.infinity = i.combo==5'b11110;
DPDDecodeN #(.N(11)) u1 (i.sigc, o.sig[131:0]);
assign o.sig[135:132] = i.combo[4:3]==2'b11 ? {3'b100,i.combo[0]} : {1'b0,i.combo[2:0]};
endmodule

module DFPUnpack64(i, o);
input DFP64 i;
output DFP64U o;

assign o.sign = i.sign;
assign o.exp = {i.combo[4:3]==2'b11 ? i.combo[2:1] : i.combo[4:3],i.expc};
assign o.nan = i.combo==5'b11111;
assign o.qnan = i.combo==5'b11111 && i.expc[7]==1'b0;
assign o.snan = i.combo==5'b11111 && i.expc[7]==1'b1;
assign o.infinity = i.combo==5'b11110;
DPDDecodeN #(.N(5)) u1 (i.sigc, o.sig[59:0]);
assign o.sig[63:60] = i.combo[4:3]==2'b11 ? {3'b100,i.combo[0]} : {1'b0,i.combo[2:0]};

endmodule
