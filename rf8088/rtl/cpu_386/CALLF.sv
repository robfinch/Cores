// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  CALL FAR and CALL FAR indirect
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

CALLF:
	begin
		tWrite(sssp,cs[15:8]);
		tGoto(CALLF1);
	end
CALLF1:
	if (rty_i)
		tWrite(sssp,cs[15:8]);
	else begin
		sp <= sp_dec;
		tGoto(CALLF2);
	end
CALLF2:
	begin
		tWrite(sssp,cs[7:0]);
		tGoto(CALLF3);
	end
CALLF3:
	if (rty_i)
		tWrite(sssp,cs[7:0]);
	else begin
		sp <= sp_dec;
		tGoto(CALLF4);
	end
CALLF4:
	begin
		tWrite(sssp,ip[15:8]);
		tGoto(CALLF5);
	end
CALLF5:
	if (rty_i)
		tWrite(sssp,ip[15:8]);
	else begin
		sp <= sp_dec;
		tGoto(CALLF6);
	end
CALLF6:
	begin
		tWrite(sssp,ip[7:0]);
		tGoto(CALLF7);
	end
CALLF7:
	if (rty_i)
		tWrite(sssp,ip[7:0]);
	else begin
		sp <= sp_dec;
		if (ir==8'hFF && rrr==3'b011)	// CALL FAR indirect
			tGoto(JUMP_VECTOR1);
		else begin
			cs <= selector;
			ip <= offset;
			tGoto(rf8088_pkg::IFETCH);
		end
	end
