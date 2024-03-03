// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
//  DECODER2.v
//  - Extended opcode decoder
//
//=============================================================================

DECODER2:
	begin
		tGoto(rf80386_pkg::IFETCH);
		case(ir)
		`MORE1:
			casez(ir2)
			`AAM:
				begin
					wrregs <= 1'b1;
					w <= 1'b1;
					rrr <= 3'd0;
					res <= alu_o;
					sf <= 1'b0;
					zf <= reszb;
					pf <= pres;
				end
			default:	;
			endcase
		`MORE2:
			casez(ir2)
			`AAD:
				begin
					wrregs <= 1'b1;
					w <= 1'b1;
					rrr <= 3'd0;
					res <= alu_o;
					sf <= 1'b0;
					zf <= reszw;
					pf <= pres;
				end
			default:	;
			endcase
		`EXTOP:
			casez(ir2)
			`LxDT:
				begin
					w <= 1'b1;
					mod   <= bundle[7:6];
					rrr   <= bundle[5:3];
					sreg3 <= bundle[5:3];
					TTT   <= bundle[5:3];
					rm    <= bundle[2:0];
					$display("Mod/RM=%b_%b_%b", dat_i[7:6],dat_i[5:3],dat_i[2:0]);
					bundle <= bundle[127:8];
					eip <= ip_inc;
					tGoto(rf80386_pkg::EACALC);		// override state transition
				end
			default:	;
			endcase
		default:	;
		endcase
	end

