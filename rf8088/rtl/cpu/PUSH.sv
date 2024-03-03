// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  PUSH register to stack
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

PUSH:
	begin
		// Note SP is predecremented at the decode stage
		case(ir)
		`PUSH_AX: tWrite(sssp,ah);
		`PUSH_BX: tWrite(sssp,bh);
		`PUSH_CX: tWrite(sssp,ch);
		`PUSH_DX: tWrite(sssp,dh);
		`PUSH_SP: tWrite(sssp,sp[15:8]);
		`PUSH_BP: tWrite(sssp,bp[15:8]);
		`PUSH_SI: tWrite(sssp,si[15:8]);
		`PUSH_DI: tWrite(sssp,di[15:8]);
		`PUSH_CS: tWrite(sssp,cs[15:8]);
		`PUSH_DS: tWrite(sssp,ds[15:8]);
		`PUSH_SS: tWrite(sssp,ss[15:8]);
		`PUSH_ES: tWrite(sssp,es[15:8]);
		`PUSHF:   tWrite(sssp,flags[15:8]);
		8'hFF:	tWrite(sssp,a[15:8]);
		default:	tWrite(sssp,8'hFF);	// only gets here if there's a hardware error
		endcase
		tGoto(PUSH1);
	end
PUSH1:
	if (rty_i) begin
		case(ir)
		`PUSH_AX: tWrite(sssp,ah);
		`PUSH_BX: tWrite(sssp,bh);
		`PUSH_CX: tWrite(sssp,ch);
		`PUSH_DX: tWrite(sssp,dh);
		`PUSH_SP: tWrite(sssp,sp[15:8]);
		`PUSH_BP: tWrite(sssp,bp[15:8]);
		`PUSH_SI: tWrite(sssp,si[15:8]);
		`PUSH_DI: tWrite(sssp,di[15:8]);
		`PUSH_CS: tWrite(sssp,cs[15:8]);
		`PUSH_DS: tWrite(sssp,ds[15:8]);
		`PUSH_SS: tWrite(sssp,ss[15:8]);
		`PUSH_ES: tWrite(sssp,es[15:8]);
		`PUSHF:   tWrite(sssp,flags[15:8]);
		8'hFF:	tWrite(sssp,a[15:8]);
		default:	tWrite(sssp,8'hFF);	// only gets here if there's a hardware error
		endcase
	end
	else begin
		sp <= sp_dec;
		tGoto(PUSH2);
	end
PUSH2:
	begin
		case(ir)
		`PUSH_AX: tWrite(sssp,al);
		`PUSH_BX: tWrite(sssp,bl);
		`PUSH_CX: tWrite(sssp,cl);
		`PUSH_DX: tWrite(sssp,dl);
		`PUSH_SP: tWrite(sssp,sp[7:0]);
		`PUSH_BP: tWrite(sssp,bp[7:0]);
		`PUSH_SI: tWrite(sssp,si[7:0]);
		`PUSH_DI: tWrite(sssp,di[7:0]);
		`PUSH_CS: tWrite(sssp,cs[7:0]);
		`PUSH_DS: tWrite(sssp,ds[7:0]);
		`PUSH_SS: tWrite(sssp,ss[7:0]);
		`PUSH_ES: tWrite(sssp,es[7:0]);
		`PUSHF:   tWrite(sssp,flags[7:0]);
		8'hFF:	tWrite(sssp,a[7:0]);
		default:	tWrite(sssp,8'hFF);	// only gets here if there's a hardware error
		endcase
		tGoto(PUSH3);
	end
// Note stack pointer is decrement already in DECODE
//
PUSH3:
	if (rty_i) begin
		case(ir)
		`PUSH_AX: tWrite(sssp,al);
		`PUSH_BX: tWrite(sssp,bl);
		`PUSH_CX: tWrite(sssp,cl);
		`PUSH_DX: tWrite(sssp,dl);
		`PUSH_SP: tWrite(sssp,sp[7:0]);
		`PUSH_BP: tWrite(sssp,bp[7:0]);
		`PUSH_SI: tWrite(sssp,si[7:0]);
		`PUSH_DI: tWrite(sssp,di[7:0]);
		`PUSH_CS: tWrite(sssp,cs[7:0]);
		`PUSH_DS: tWrite(sssp,ds[7:0]);
		`PUSH_SS: tWrite(sssp,ss[7:0]);
		`PUSH_ES: tWrite(sssp,es[7:0]);
		`PUSHF:   tWrite(sssp,flags[7:0]);
		8'hFF:	tWrite(sssp,a[7:0]);
		default:	tWrite(sssp,8'hFF);	// only gets here if there's a hardware error
		endcase
	end
	else
		tGoto(IFETCH);
