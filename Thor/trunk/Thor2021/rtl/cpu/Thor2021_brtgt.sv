// ============================================================================
//        __
//   \\__/ o\    (C) 2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Thor2021_brtgt.sv
//	Compute a branch target.
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

module Thor2021_brtgt(ir, ca, tgt);
input Instruction ir;
input Address [7:0] ca;
output Address tgt;

parameter RSTIP = 64'hFFC00007FFFC0100;

always_comb
case(ir.any.opcode)
RTS:	tgt = {ca[{1'b0,ir[10:9]}].sel,ca[{1'b0,ir[10:9]}].offs + ir[15:11]};
RTE:	tgt = {ca[6].sel,ca[6].offs + ir[20:9]};
BEQ,BNE,BLT,BGE,BLE,BGT,BLTU,BGEU,BLEU,BGTU,BBC,BBS:
	tgt = {ca[ir.br.Ca].sel,ca[ir.br.Ca].offs + {{54{ir.br.tgthi[7]}},ir.br.tgthi[7:0],ir.br.tgtlo}};
BEQL,BNEL,BLTL,BGEL,BLEL,BGTL,BLTUL,BGEUL,BLEUL,BGTUL,BBCL,BBSL:
	tgt = {ca[ir.br.Ca].sel,ca[ir.br.Ca].offs + {{38{ir.br.tgthi[23]}},ir.br.tgthi[23:0],ir.br.tgtlo}};
BRA:
	tgt = {ca[ir.br.Ca].sel,ca[ir.br.Ca].offs + {{38{ir.br.tgthi[7]}},ir.br.tgthi[7:0],ir.br.Tb,ir.br.Rb,ir.br.Ra,ir.br.tgtlo}};
BRAL:
	tgt = {ca[ir.br.Ca].sel,ca[ir.br.Ca].offs + {{24{ir.br.tgthi[23]}},ir.br.tgthi[23:0],ir.br.Tb,ir.br.Rb,ir.br.Ra,ir.br.tgtlo}};
default:	tgt = RSTIP;
endcase

endmodule

// Compute IP relative target
// IP relative targets can be detected during the fetch phase, because the IP is known.
module Thor2021_ipr_brtgt(ir, ip, tgt);
input Instruction ir;
input Address ip;
output Address tgt;

parameter RSTIP = 64'hFFC00007FFFC0100;

always_comb
case(ir.any.opcode)
BEQ,BNE,BLT,BGE,BLE,BGT,BLTU,BGEU,BLEU,BGTU,BBC,BBS:
	tgt = {ip.sel,ip.offs + {{54{ir.br.tgthi[7]}},ir.br.tgthi[7:0],ir.br.tgtlo}};
BEQL,BNEL,BLTL,BGEL,BLEL,BGTL,BLTUL,BGEUL,BLEUL,BGTUL,BBCL,BBSL:
	tgt = {ip.sel,ip.offs + {{38{ir.br.tgthi[23]}},ir.br.tgthi[23:0],ir.br.tgtlo}};
BRA:
	tgt = {ip.sel,ip.offs + {{38{ir.br.tgthi[7]}},ir.br.tgthi[7:0],ir.br.Tb,ir.br.Rb,ir.br.Ra,ir.br.tgtlo}};
BRAL:
	tgt = {ip.sel,ip.offs + {{24{ir.br.tgthi[23]}},ir.br.tgthi[23:0],ir.br.Tb,ir.br.Rb,ir.br.Ra,ir.br.tgtlo}};
default:	tgt = RSTIP;
endcase

endmodule
