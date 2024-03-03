// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  RETFPOP: far return from subroutine and pop stack items
//  Fetch ip from stack
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
//  RETPOP: near return from subroutine and pop stack items
//  Fetch ip from stack
// ============================================================================

rf80386_pkg::RETFPOP:
	begin
		ad <= sssp;
		if (cs_desc.db)
			sel <= 16'h003F;
		else
			sel <= 16'h000F;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::RETFPOP1);
	end
rf80386_pkg::RETFPOP1:
	begin
		if (cs_desc.db) begin
			esp <= esp + 4'd6;
			{selector,eip} <= dat[47:0];
		end
		else begin
			esp <= esp + 4'd4;
			{selector,eip[15:0]} <= dat[31:0];
			eip[31:16] <= 16'h0;
		end
		tGoto(rf80386_pkg::RETFPOP2);
	end
rf80386_pkg::RETFPOP2:
	begin
		wrregs <= 1'b1;
		w <= 1'b1;
		rrr <= 3'd4;
		res <= esp + data32;
		cs <= selector;
		if (cs != selector)
			tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::IFETCH);
		else
			tGoto(rf80386_pkg::IFETCH);
	end
