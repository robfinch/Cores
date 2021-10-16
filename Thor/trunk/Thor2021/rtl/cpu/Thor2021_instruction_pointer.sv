// ============================================================================
//        __
//   \\__/ o\    (C) 2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Thor2021_instruction_pointer.sv
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

module Thor2021_instruction_pointer(rst, clk, nxt_insn, nxt2_insn, insln1, insln2,
	branchmiss, slot_br, brtgt, ip_override, branch_ip, ca);
parameter RSTIP = 96'hFFC00007FFFFFFFFFFFC0100;
input rst;
input clk;
input nxt_insn;
input nxt_2insn;
input [3:0] insln1;
input [3:0] insln2;
input branchmiss;
input [1:0] slot_br;
input Address [1:0] brtgt;
input ip_override;
input Address branch_ip;
input Address [7:0] ca;

reg [95:0] next_ip;
reg [95:0] ip;

always_comb
if (rst)
	next_ip <= RSTIP;
else if (branchmiss)
	next_ip <= missip;
else if (nxt2_insn) begin
	next_ip <= ip + insln1 + insln2;
	if (slot_br[0])
		next_ip <= brtgt[0];
	else if (slot_br[1])
		next_ip <= brtgt[1];
	if (ip_override)
		next_ip <= branch_ip;
end
else if (nxt_insn) begin
	next_ip <= ip + insln1;
	if (slot_br[0])
		next_ip <= brtgt[0];
	else if (slot_br[1])
		next_ip <= brtgt[1];
	if (ip_override)
		next_ip <= branch_ip;
end
else
	next_ip <= ip;

always_ff @(posedge clk)
begin
	if (branchmiss) begin
		$display("==============================");
		$display("==============================");
		$display("Branch miss: tgt=%h",next_ip);
		$display("==============================");
		$display("==============================");
	end
	ip <= next_ip;
end

endmodule
