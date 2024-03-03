// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  JUMP_VECTOR
//  - fetch 32 bit vector into selector:offset and jump to it
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

JUMP_VECTOR1:
	begin
		tRead(ea);	// ea set by EACALC
		cyc_done <= FALSE;
		tGoto(JUMP_VECTOR2);
	end
JUMP_VECTOR2:
	if (ack_i) begin
		ea <= ea_inc;
		offset[7:0] <= dat_i;
		tGoto(JUMP_VECTOR3);
	end
	else if (rty_i && !cyc_done)
		tRead(ea);
	else
		cyc_done <= TRUE;
JUMP_VECTOR3:
	begin
		tRead(ea);
		cyc_done <= FALSE;
		tGoto(JUMP_VECTOR4);
	end
JUMP_VECTOR4:
	if (ack_i) begin
		ea <= ea_inc;
		offset[15:8] <= dat_i;
		tGoto(JUMP_VECTOR5);
	end
	else if (rty_i && !cyc_done)
		tRead(ea);
	else
		cyc_done <= TRUE;
JUMP_VECTOR5:
	begin
		tRead(ea);
		cyc_done <= FALSE;
		tGoto(JUMP_VECTOR6);
	end
JUMP_VECTOR6:
	if (ack_i) begin
		ea <= ea_inc;
		selector[7:0] <= dat_i;
		tGoto(JUMP_VECTOR7);
	end
	else if (rty_i && !cyc_done)
		tRead(ea);
	else
		cyc_done <= TRUE;
JUMP_VECTOR7:
	begin
		tRead(ea);
		cyc_done <= FALSE;
		tGoto(JUMP_VECTOR8);
	end
JUMP_VECTOR8:
	if (ack_i) begin
		selector[15:8] <= dat_i;
		tGoto(JUMP_VECTOR9);
	end
	else if (rty_i && !cyc_done)
		tRead(ea);
	else
		cyc_done <= TRUE;
JUMP_VECTOR9:
	begin
		ip <= offset;
		cs <= selector;
		tGoto(IFETCH);
	end
