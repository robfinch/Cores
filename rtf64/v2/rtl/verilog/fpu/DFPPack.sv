// ============================================================================
//        __
//   \\__/ o\    (C) 2020-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DPDPack.sv
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

module DFPPack128(i, o);
input DFP128U i;
output DFP128 o;

wire [109:0] enc_sig;
DPDEncodeN #(.N(11)) u1 (i.sig[131:0], enc_sig);

always @*
begin
	// sign
	o.sign <= i.sign;
	// combo
	if (i.qnan|i.snan)
		o.combo <= 5'b11111;
	else if (i.infinity)
		o.combo <= 5'b11110;
	else
		o.combo <= i.sig[135:132] > 4'h7 ? {2'b11,i.exp[13:12],i.sig[132]} : {i.exp[13:12],i.sig[134:132]};
	// exponent continuation
	if (i.qnan)
		o.expc <= {1'b0,i.exp[10:0]};
	else if (i.snan)
		o.expc <= {1'b1,i.exp[10:0]};
	else
		o.expc <= i.exp[11:0];
	// significand continuation
	o.sigc <= enc_sig;
end

endmodule

module DFPPack64(i, o);
input DFP64U i;
output DFP64 o;

wire [49:0] enc_sig;
DPDEncodeN #(.N(5)) u1 (i.sig[59:0], enc_sig);

always @*
begin
	// sign
	o.sign <= i.sign;
	// combo
	if (i.qnan|i.snan)
		o.combo <= 5'b11111;
	else if (i.infinity)
		o.combo <= 5'b11110;
	else
		o.combo <= i.sig[63:60] > 4'h7 ? {2'b11,i.exp[9:8],i.sig[60]} : {i.exp[9:8],i.sig[62:60]};
	// exponent continuation
	if (i.qnan)
		o.expc <= {1'b0,i.exp[6:0]};
	else if (i.snan)
		o.expc <= {1'b1,i.exp[6:0]};
	else
		o.expc <= i.exp[7:0];
	// significand continuation
	o.sigc <= enc_sig;
end

endmodule
