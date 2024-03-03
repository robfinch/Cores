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

rf80386_pkg::POP:
	begin
		ad <= sssp;
		case(ir)
		`POP_AX,`POP_CX,`POP_BX,`POP_DX,
		`POP_SI,`POP_DI,`POP_BP,`POP_SP:
			sel <= cs_desc.db ? 16'h000F : 16'h0003;
		`POP_SS,`POP_ES,`POP_DS:
			sel <= 16'h0003;
		`POPF:
			sel <= cs_desc.db ? 16'h000F : 16'h0003;
		`POP_MEM:
			sel <= cs_desc.db ? 16'h000F : 16'h0003;
		default: ;
		endcase
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::POP1);
		w <= 1'b1;
		rrr <= ir[2:0];
	end
rf80386_pkg::POP1:
	begin
		tGoto(rf80386_pkg::IFETCH);
		res[31:0] <= dat[31:0];
		selector <= dat[15:0];
		case(ir)
		`POP_AX,`POP_CX,`POP_BX,`POP_DX,
		`POP_SI,`POP_DI,`POP_BP,`POP_SP:
			begin
				esp <= cs_desc.db ? esp + 4'd4 : esp + 4'd2;
				wrregs <= 1'b1;
			end
		`POP_SS:
			begin
				esp <= esp + 4'd2;
				if (dat[15:0] != ss)
					tGosub(rf80386_pkg::LOAD_SS_DESC,rf80386_pkg::IFETCH);
			end
		`POP_ES:
			begin
				esp <= esp + 4'd2;
				if (dat[15:0] != es)
					tGosub(rf80386_pkg::LOAD_ES_DESC,rf80386_pkg::IFETCH);
			end
		`POP_DS:
			begin
				esp <= esp + 4'd2;
				if (dat[15:0] != ds)
					tGosub(rf80386_pkg::LOAD_DS_DESC,rf80386_pkg::IFETCH);
			end
		`POPF:
			esp <= cs_desc.db ? esp + 4'd4 : esp + 4'd2;
		`POP_MEM:
			begin
				esp <= cs_desc.db ? esp + 4'd4 : esp + 4'd2;
				tGoto(rf80386_pkg::STORE_DATA);
			end
		default: ;
		endcase
		case(ir)
		`POP_SS: begin rrr <= 3'd2; wrsregs <= 1'b1; end
		`POP_ES: begin rrr <= 3'd0; wrsregs <= 1'b1; end
		`POP_DS: begin rrr <= 3'd3; wrsregs <= 1'b1; end
		`POPF:
			begin
				cf <= dat[0];
				pf <= dat[2];
				af <= dat[4];
				zf <= dat[6];
				sf <= dat[7];
				tf <= dat[8];
				ie <= dat[9];
				df <= dat[10];
				vf <= dat[11];
			end
		default: ;
		endcase
	end
