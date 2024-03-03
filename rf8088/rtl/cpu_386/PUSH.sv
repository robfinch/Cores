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

rf80386_pkg::PUSH:
	begin
		// Note SP is predecremented at the decode stage
		if (cs_desc.db)
			case(ir)
			`PUSH_AX: begin ad <= sssp; sel <= 16'h000F; dat <= eax; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_BX: begin ad <= sssp; sel <= 16'h000F; dat <= ebx; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_CX: begin ad <= sssp; sel <= 16'h000F; dat <= ecx; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_DX: begin ad <= sssp; sel <= 16'h000F; dat <= edx; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_SP: begin ad <= sssp; sel <= 16'h000F; dat <= esp; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_BP: begin ad <= sssp; sel <= 16'h000F; dat <= ebp; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_SI: begin ad <= sssp; sel <= 16'h000F; dat <= esi; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_DI: begin ad <= sssp; sel <= 16'h000F; dat <= edi; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_CS: begin ad <= sssp; sel <= 16'h0003; dat <= cs; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_DS: begin ad <= sssp; sel <= 16'h0003; dat <= ds; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_SS: begin ad <= sssp; sel <= 16'h0003; dat <= ss; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_ES: begin ad <= sssp; sel <= 16'h0003; dat <= es; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSHF:   begin ad <= sssp; sel <= 16'h000F; dat <= flags[31:0]; tGosub(STORE,rf80386_pkg::IFETCH); end
			8'hFF:	begin ad <= sssp; sel <= 16'h000F; dat <= a[31:0]; tGosub(STORE,rf80386_pkg::IFETCH); end
			default:	tGoto(rf80386_pkg::RESET);	// only gets here if there's a hardware error
			endcase
		else
			case(ir)
			`PUSH_AX: begin ad <= sssp; sel <= 16'h0003; dat <= ax; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_BX: begin ad <= sssp; sel <= 16'h0003; dat <= bx; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_CX: begin ad <= sssp; sel <= 16'h0003; dat <= cx; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_DX: begin ad <= sssp; sel <= 16'h0003; dat <= dx; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_SP: begin ad <= sssp; sel <= 16'h0003; dat <= sp; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_BP: begin ad <= sssp; sel <= 16'h0003; dat <= bp; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_SI: begin ad <= sssp; sel <= 16'h0003; dat <= si; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_DI: begin ad <= sssp; sel <= 16'h0003; dat <= di; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_CS: begin ad <= sssp; sel <= 16'h0003; dat <= cs; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_DS: begin ad <= sssp; sel <= 16'h0003; dat <= ds; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_SS: begin ad <= sssp; sel <= 16'h0003; dat <= ss; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSH_ES: begin ad <= sssp; sel <= 16'h0003; dat <= es; tGosub(STORE,rf80386_pkg::IFETCH); end
			`PUSHF:   begin ad <= sssp; sel <= 16'h0003; dat <= flags[15:0]; tGosub(STORE,rf80386_pkg::IFETCH); end
			8'hFF:	begin ad <= sssp; sel <= 16'h0003; dat <= a[15:0]; tGosub(STORE,rf80386_pkg::IFETCH); end
			default:	tGoto(rf80386_pkg::RESET);	// only gets here if there's a hardware error
			endcase
	end
