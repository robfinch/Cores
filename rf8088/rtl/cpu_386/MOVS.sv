// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  MOVSB,MOVSW
//  - moves a byte at a time to account for both bytes and words
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

rf80386_pkg::MOVS:
`include "check_for_ints.sv"
	else if (w && (cs_desc.db ? esi > 32'hFFFFFFFC : esi[15:0]==16'hFFFF)) begin
		ir <= `NOP;
		int_num <= 8'd13;
		tGoto(INT1);
	end
	else if ((repz|repnz) & cxz)
		tGoto(rf80386_pkg::IFETCH);
	else begin
		ad <= dssi;
		if (w)
			sel <= cs_desc.db ? 16'h000F : 16'h0003;
		else
			sel <= 16'h0001;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::MOVS1);
	end
rf80386_pkg::MOVS1:
	begin
		tGoto(rf80386_pkg::MOVS2);
		if (w) begin
			if (cs_desc.db) begin
				a[31:0] <= dat[31:0];
				esi <= df ? esi - 4'd4 : esi + 4'd4;
			end
			else begin
				a[15:0] <= dat[15:0];
				esi <= df ? esi - 4'd2 : esi + 4'd2;
			end
		end
		else begin
			a[7:0] <= dat;
			esi <= df ? esi - 4'd1 : esi + 4'd1;
		end
	end
rf80386_pkg::MOVS2:
	begin
		ad <= esdi;
		if (w) begin
			sel <= cs_desc.db ? 16'h000F : 16'h0003;
			dat <= cs_desc.db ? a[31:0] : {2{a[15:0]}};
		end
		else begin
			sel <= 16'h0001;
			dat <= {4{a[7:0]}};
		end
		tGosub(rf80386_pkg::STORE,rf80386_pkg::MOVS3);
	end
rf80386_pkg::MOVS3:
	begin
		if (w)
			edi <= df ? (cs_desc.db ? edi - 4'd4 : edi - 4'd2): 
									(cs_desc.db ? edi + 4'd4 : edi + 4'd2);
		else
			edi <= df ? edi - 4'd1 : edi + 4'd1;
		tGoto(rf80386_pkg::MOVS4);
	end
rf80386_pkg::MOVS4:
	begin
		if (repz|repnz) begin
			ecx <= cx_dec;
			tGoto(rf80386_pkg::MOVS);
		end
		else
			tGoto(rf80386_pkg::IFETCH);
	end
