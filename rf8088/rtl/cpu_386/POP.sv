// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  POP register from stack
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

POP:
	begin
		tRead(sssp);
		w <= 1'b1;
		rrr <= ir[2:0];
		cyc_done <= FALSE;
		tGoto(POP1);
	end
POP1:
	if (ack_i) begin
		sp <= sp_inc;
		res[7:0] <= dat_i;
		case(ir)
		`POP_SS: begin rrr <= 3'd2; end
		`POP_ES: begin rrr <= 3'd0; end
		`POP_DS: begin rrr <= 3'd3; end
		`POPF:
			begin
				cf <= dat_i[0];
				pf <= dat_i[2];
				af <= dat_i[4];
				zf <= dat_i[6];
				sf <= dat_i[7];
			end
		default: ;
		endcase
		tGoto(POP2);
	end
	else if (rty_i && !cyc_done)
		tRead(sssp);
	else
		cyc_done <= TRUE;
POP2:
	begin
		tRead(sssp);
		cyc_done <= FALSE;
		tGoto(POP3);
	end
POP3:
	if (ack_i) begin
		tGoto(rf8088_pkg::IFETCH);
		sp <= sp_inc;
		res[15:8] <= dat_i;
		case(ir)
		`POP_AX,`POP_CX,`POP_BX,`POP_DX,
		`POP_SI,`POP_DI,`POP_BP,`POP_SP:
			wrregs <= 1'b1;
		`POP_SS,`POP_ES,`POP_DS:
			wrsregs <= 1'b1;
		`POPF:
			begin
				tf <= dat_i[0];
				ie <= dat_i[1];
				df <= dat_i[2];
				vf <= dat_i[3];
			end
		`POP_MEM:
			tGoto(STORE_DATA);
		default: ;
		endcase
	end
	else if (rty_i && !cyc_done)
		tRead(sssp);
	else
		cyc_done <= TRUE;
