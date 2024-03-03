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

rf80386_pkg::JUMP_VECTOR1:
	begin
		ad <= ea;
		if (cs_desc.db)
			sel <= 16'h003F;
		else
			sel <= 16'h000F;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::JUMP_VECTOR2);
	end
rf80386_pkg::JUMP_VECTOR2:
	begin
		if (cs_desc.db) begin
			offset <= dat[31:0];
			selector <= dat[47:32];
		end
		else begin
			offset <= dat[15:0];
			selector <= dat[31:16];
		end
		tGoto(rf80386_pkg::JUMP_VECTOR3);
	end
JUMP_VECTOR3:
	begin
		eip <= offset;
		cs <= selector;
		if (cs != selector)
			tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::IFETCH);
		else
			tGoto(rf80386_pkg::IFETCH);
	end
