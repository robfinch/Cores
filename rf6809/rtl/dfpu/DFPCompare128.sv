// ============================================================================
//        __
//   \\__/ o\    (C) 2020-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPCompare128.sv
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

module DFPCompare128(a, b, o);
input DFP128 a;
input DFP128 b;
output reg [11:0] o ='d0;
localparam N=34;			// number of BCD digits

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

DFP128U au;
DFP128U bu;

DFPUnpack128 u00 (a, au);
DFPUnpack128 u01 (b, bu);

reg sa, sb;
always_comb
	sa = au.sign;
always_comb
	sb = bu.sign;
wire az = ~|{au.exp,au.sig};
wire bz = ~|{bu.exp,bu.sig};
wire unordered = au.nan | bu.nan;

wire eq = !unordered & ((az & bz) || (a==b));	// special test for zero
wire gt1 = {au.exp,au.sig} > {bu.exp,bu.sig};
wire lt1 = {au.exp,au.sig} < {bu.exp,bu.sig};

wire lt = sa ^ sb ? sa & !(az & bz): sa ? gt1 : lt1;

always_comb
begin
	o[0] = eq;
	o[1] = lt;
	o[2] = lt|eq;
	o[3] = lt1;
	o[4] = unordered;
	o[5] = ~eq;
	o[6] = ~lt;
	o[7] = ~(lt|eq);
	o[8] = ~lt1;
	o[9] = ~unordered;
	o[10] = 1'b0;
	o[11] = lt;
end

// an unorder comparison will signal a nan exception
//assign nanx = op!=`FCOR && op!=`FCUN && unordered;

endmodule
