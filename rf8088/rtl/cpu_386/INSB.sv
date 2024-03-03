// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  INSB
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

rf80386_pkg::INSB:
`include "check_for_ints.sv"
	else if (repdone)
		tGoto(rf80386_pkg::IFETCH);
	else begin
		if (cs_desc.db)
			ea <= edx;
		else
			ea <= dx;
		sel <= 16'h0001;
		tGosub(rf80386_pkg::LOAD_IO,rf80386_pkg::INSB1);
	end
rf80386_pkg::INSB1:
	begin
		res[7:0] <= dat;
		tGoto(rf80386_pkg::INSB2);
	end
rf80386_pkg::INSB2:
	begin
		ea <= esdi;
		dat <= res[7:0];
		sel <= 16'h0001;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::INSB3);
	end
rf80386_pkg::INSB3:
	begin
		if (df)
			edi <= edi - 16'd1;
		else
			edi <= edi + 16'd1;
		if (repz|repnz)
			ecx <= cx_dec;
		tGoto(repz|repnz ? rf80386_pkg::INSB : rf80386_pkg::IFETCH);
	end
