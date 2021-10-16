// ============================================================================
//        __
//   \\__/ o\    (C) 2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Thor2021_agen.sv
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

module Thor2021_agen(rst,clk,ir,ia,ib,ic,imm,step,ea);
input rst;
input clk;
input Instruction ir;
input Value ia;
input Value ib;
input Value ic;
input Value imm;
input [5:0] step;
output Address ea;

reg [1:0] Sc;
always_comb
	case(ir.r2.opcode)
	LDxX:	Sc = ir.nld.Sc;
	STxX:	Sc = ir.nst.Sc;
	default:	Sc = 2'd0;
	endcase

always @(posedge clk)
if (rst)
	ea <= 32'd0;
else begin
	case(ir.r2.opcode)
	LDB,LDBU,LDBL,LDBUL:	ea <= imm + ia.val + (ir.r2.v ? ib.val * step : 1'd0);
	LDW,LDWU,LDWL,LDWUL:	ea <= imm + ia.val + (ir.r2.v ? ib.val * step : 1'd0);
	LDT,LDTU,LDTL,LDTUL:	ea <= imm + ia.val + (ir.r2.v ? ib.val * step : 1'd0);
	LDO,LDOL:							ea <= imm + ia.val + (ir.r2.v ? ib.val * step : 1'd0);
	STB,STW,STT,STO:			ea <= imm + ia.val + (ir.r2.v ? ic.val * step : 1'd0);
	STBL,STWL,STTL,STOL:	ea <= imm + ia.val + (ir.r2.v ? ic.val * step : 1'd0);
	LDxX:	ea <= ia.val + (ib.val << Sc);
	STxX:	ea <- ia.val + (ic.val << Sc);
	SYS:	ea <= ia.val;	// CSAVE / CRESTORE
	default:	ea <= 64'd0;
	endcase
end

endmodule
