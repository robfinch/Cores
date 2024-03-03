// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  IRET
//  - return from interrupt
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
//  System Verilog 
//
//  IRET: return from interrupt
//  Fetch cs:ip from stack
//  pop ip
//  pop cs
//  pop flags
// ============================================================================
//
rf80386_pkg::IRET1:
	begin
		ad <= sssp;
		sel <= 16'h03FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::IRET2);
	end
rf80386_pkg::IRET2:
	begin
		esp <= esp + 4'd10;
		eip <= dat[31:0];
		selector <= dat[47:32];
		cf <= dat_i[48];
		pf <= dat_i[50];
		af <= dat_i[52];
		zf <= dat_i[54];
		sf <= dat_i[55];
		tf <= dat_i[56];
		ie <= dat_i[57];
		df <= dat_i[58];
		vf <= dat_i[59];
		tGoto(rf80386_pkg::IRET3);
	end
rf80386_pkg::IRET3:
	begin
		cs <= selector;
		if (cs != selector)
			tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::IFETCH);
		else
			tGoto(rf80386_pkg::IFETCH);
	end
