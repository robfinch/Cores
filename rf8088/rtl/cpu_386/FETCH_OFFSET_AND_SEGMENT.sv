// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  FETCH_OFFSET_AND_SEGMENT.v
//  - Fetch 16 bit offset
//  - Fetch 16/32 bit segment
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
//  System Verilog 
//
// - bus is locked if immediate value is unaligned in memory
// - immediate values are the last operand to be fetched, hence
//   the state machine can transition into the EXECUTE state.
// - we also know the immediate value can't be the target of an
//   operation.
// ============================================================================

rf80386_pkg::FETCH_OFFSET:
	begin
		if (cs_desc.db) begin
			{selector[15:0],offset[31:0]} <= bundle[47:0];
			bundle <= bundle[127:48];
			eip <= eip + 4'd6;
		end
		else begin
			{selector[15:0],offset[15:0]} <= bundle[31:0];
			offset[31:16] <= 16'h0;
			bundle <= bundle[127:32];
			eip <= eip + 4'd4;
		end
		if (ir==`CALLF)
			tGoto(rf80386_pkg::CALLF);
		else
			tGoto(rf80386_pkg::JMPF);
	end
rf80386_pkg::JMPF:
	begin
		cs <= selector;
		eip <= offset;
		tGoto(rf80386_pkg::IFETCH);
	end
