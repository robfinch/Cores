// ============================================================================
//        __
//   \\__/ o\    (C) 2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Thor2021_ialign.sv
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
//
// Input a cache line and address and output a single instruction.
// ============================================================================

import Thor2021_pkg::*;

module Thor2021_ialign(ip, cacheline, o0, o1, o2);
input Address ip;
input [511+$bits(Instruction)-8:0] cacheline;
output sInstAlignOut o0;
output sInstAlignOut o1;
output sInstAlignOut o2;

reg [$bits(Instruction)*3-1:0] ibundle;
Instruction insn0, insn1, insn2;
wire [3:0] L0, L1, L2;

Thor2021_inslength u1 (insn0, L0);
Thor2021_inslength u2 (insn1, L1);
Thor2021_inslength u3 (insn2, L2);

always_comb
	ibundle = cacheline >> {ip[5:0],3'd0};
always_comb
	insn0 = ibundle[63:0];
always_comb
	insn1 = ibundle >> {L0,3'b0};
always_comb
	insn2 = ibundle >> {L0+L1,3'b0};

always_comb
begin
	o0.ir = insn0;
	o0.ip = ip;
	o0.len = L0;
end

always_comb
begin
	o1.ir = insn1;
	o1.ip = {ip.sel,ip.offs + L0};
	o1.len = L1;
end

always_comb
begin
	o2.ir = insn1;
	o2.ip = {ip.sel,ip.offs + L0 + L1};
	o2.len = L2;
end

endmodule
