// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DPDDecode.sv
//
// An encoding described in:
// 	Densely Packed Decimal Encoding, by Mike Cowlishaw, in 
// 	IEE Proceedings – Computers and Digital Techniques, ISSN 1350-2387,
// 	Vol. 149, No. 3, pp102–104, IEE, May 2002
//
// See: http://speleotrove.com/decimal/DPDecimal.html
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

module DPDDecode(i, o);
input [9:0] i;
output [11:0] o;

wire a,b,c,d,e,f,g,h,ii,j,k,m;
wire y,x,w,v,u,t,s,r,q,p;

assign {p,q,r,s,t,u,v,w,x,y} = i;

assign a = (v & w) & (~s | t | ~x);
assign b = p & (~v | ~w | (s & ~t & x));
assign c = q & (~v | ~w | (s & ~t & x));
assign d = r;
assign e = v & ((~w & x) | (~t & x) | (s & x));
assign f = (s & (~v | ~x)) | (p & ~s & t & v & w & x);
assign g = (t & (~v | ~x)) | (q & ~s & t & w);
assign h = u;
assign ii = v & ((~w & ~x) | (w & x & (s | t)));
assign j = (~v & w) | (s & v & ~w & x) | (p & w & (~x | (~s & ~t)));
assign k = (~v & x) | (t & ~w & x) | (q & v & w & (~x | (~s & ~t)));
assign m = y;

assign o = {a,b,c,d,e,f,g,h,ii,j,k,m};
 
endmodule

module DPDDecodeN(i, o);
parameter N=11;
input [N*10-1:0] i;
output [N*12-1:0] o;

genvar g;

generate begin : gDPD
	for (g = 0; g < N; g = g + 1)
		DPDDecode u1 (i[g*10+9:g*10], o[g*12+11:g*12]);
end
endgenerate

endmodule
