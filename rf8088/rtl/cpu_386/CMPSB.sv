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
//  CMPSB
//
//=============================================================================
//
rf80386_pkg::CMPSB:
	begin
		ad <= seg_reg + (cs_desc.db ? esi : si);
		sel <= 16'h0001;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::CMPSB1);
	end
rf80386_pkg::CMPSB1:
	begin
		tGoto(rf80386_pkg::CMPSB2);
		a[ 7:0] <= dat[7:0];
		a[31:8] <= {24{dat[7]}};
	end
rf80386_pkg::CMPSB2:
	begin
		ad <= esdi;
		sel <= 16'h0001;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::CMPSB3);
	end
rf80386_pkg::CMPSB3:
	begin
		tGoto(rf80386_pkg::CMPSB4);
		b[ 7:0] <= dat[7:0];
		b[31:8] <= {24{dat[7]}};
	end
rf80386_pkg::CMPSB4:
	begin
		pf <= pres;
		zf <= reszb;
		sf <= resnb;
		af <= carry   (1'b1,a[3],b[3],alu_o[3]);
		cf <= carry   (1'b1,a[7],b[7],alu_o[7]);
		vf <= overflow(1'b1,a[7],b[7],alu_o[7]);
		if (df) begin
			esi <= si_dec;
			edi <= di_dec;
		end
		else begin
			esi <= si_inc;
			edi <= di_inc;
		end
		if ((repz & !cxz & zf) | (repnz & !cxz & !zf)) begin
			ecx <= cx_dec;
			eip <= ir_ip;
			tGoto(rf80386_pkg::IFETCH);
		end
		else
			tGoto(rf80386_pkg::IFETCH);
	end
