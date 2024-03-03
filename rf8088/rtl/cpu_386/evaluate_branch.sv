// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  EVALUATE_BRANCH.sv
//  Evaluate branch condition
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

`ifndef JMPS
`define JMPS	8'hEB
`endif

`ifndef JO
`define JO		8'h70
`define JNO		8'h71
`define JB		8'h72
`define JAE		8'h73
`define JE		8'h74
`define JNE		8'h75
`define JBE		8'h76
`define JA		8'h77
`define JS		8'h78
`define JNS		8'h79
`define JP		8'h7A
`define JNP		8'h7B
`define JL		8'h7C
`define JNL		8'h7D
`define JLE		8'h7E
`define JNLE	8'h7F

`define JNA		8'h76
`define JNAE	8'h72
`define JNB     8'h73
`define JNBE    8'h77
`define JC      8'h72
`define JNC     8'h73
`define JG		8'h7F
`define JNG		8'h7E
`define JGE		8'h7D
`define JNGE	8'h7C
`define JPE     8'h7A
`define JPO     8'h7B

`define LOOPNZ	8'hE0
`define LOOPZ	8'hE1
`define LOOP	8'hE2
`define JCXZ	8'hE3

`endif

module evaluate_branch(ir,cx,zf,cf,sf,vf,pf,take_br);
input [7:0] ir;
input [15:0] cx;
input zf,cf,sf,vf,pf;
output take_br;

reg take_br;
wire cxo = cx==16'h0001;	// CX is one
wire cxz = cx==16'h0000;	// CX is zero

always_comb
	case(ir)
	`JMPS:		take_br <= 1'b1;
	`JP:		take_br <=  pf;
	`JNP:		take_br <= !pf;
	`JO:		take_br <=  vf;
	`JNO:		take_br <= !vf;
	`JE:		take_br <=  zf;
	`JNE:		take_br <= !zf;
	`JAE:		take_br <= !cf;
	`JB:		take_br <=  cf;
	`JS:		take_br <=  sf;
	`JNS:		take_br <= !sf;
	`JBE:		take_br <=  cf | zf;
	`JA:		take_br <= !cf & !zf;
	`JL:		take_br <= sf ^ vf;
	`JNL:		take_br <= !(sf ^ vf);
	`JLE:		take_br <= (sf ^ vf) | zf;
	`JNLE:		take_br <= !((sf ^ vf) | zf);
	`JCXZ:		take_br <= cxz;
	`LOOP:		take_br <= !cxo;
	`LOOPZ:		take_br <= !cxo && zf;
	`LOOPNZ:	take_br <= !cxo && !zf;
	default:	take_br <= 1'b0;
	endcase

endmodule
