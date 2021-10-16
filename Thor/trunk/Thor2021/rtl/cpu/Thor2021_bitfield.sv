// ============================================================================
//        __
//   \\__/ o\    (C) 2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Thor2021_bitfield.sv
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

module Thor2021_bitfield(ir, a, b, c, o);
input Instruction ir;
input Value a;
input Value b;
input Value c;
output Value o;

reg [127:0] o1, o2;
wire [5:0] mw = ir[42:37];
wire [5:0] me = ir[42:37];
wire [5:0] mb = c[5:0];
wire [3:0] func = ir[47:44];
Value imm = ir[28:21];
Value mask;
wire [6:0] ffoo;

ffo96 u1 ({32'h0,o1},ffoo);

integer nn, n;
always @*
	for (nn = 0; nn < $bits(Value); nn = nn + 1)
		mask[nn] <= (nn >= mb) ^ (nn <= me) ^ (me >= mb);

always_comb
begin
	o1 = 128'd0;
	o2 = 128'd0;
	case(ir.any.opcode)
	BTFLD:
		case(func)
		BFCLR:	begin for (n = 0; n < $bits(Value); n = n + 1) o[n] = mask[n] ?  1'b0 : a[n]; end
		BFSET:	begin for (n = 0; n < $bits(Value); n = n + 1) o[n] = mask[n] ?  1'b1 : a[n]; end
		BFCHG:	begin for (n = 0; n < $bits(Value); n = n + 1) o[n] = mask[n] ? ~a[n] : a[n]; end
		// The following does SRL,SRA and ROR
		BFEXT:
			begin
				o1 = {b,a} >> mb;
				for (n = 0; n < $bits(Value); n = n + 1)
					if (n > mw)
						o[n] = ir[35] ? o1[mw] : 1'b0;
					else
						o[n] = o1[n];
			end
		BFINS:
			begin
				o1 = {64'd0,b} << mb;
				for (n = 0; n < $bits(Value); n = n + 1) o[n] = (mask[n] ? o1[n] : a[n]);
			end
		BFINSI:
			begin
				o1 = {64'd0,imm} << mb;
				for (n = 0; n < $bits(Value); n = n + 1) o[n] = (mask[n] ? o1[n] : a[n]);
			end
		BFFFO:
			begin
				for (n = 0; n < $bits(Value); n = n + 1)
					o1[n] = mask[n] ? a[n] : 1'b0;
				o = (ffoo==7'd127) ? -64'd1 : ffoo - mb;	// ffoo returns 127 if no one was found
			end
		default:	o = 64'd0;
		endcase
	default:	o = 64'd0;
	endcase
end
endmodule
