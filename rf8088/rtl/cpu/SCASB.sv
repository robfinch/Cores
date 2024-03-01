// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  SCASB
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

SCASB:
`include "check_for_ints.v"
	else if ((repz|repnz) & cxz)
		tGoto(IFETCH);
	else begin
		tRead(esdi);
		cyc_done <= FALSE;
		tGoto(SCASB1);
	end
SCASB1:
	if (ack_i) begin
		tGoto(SCASB2);
		a <= al;
		b <= dat_i;
		if (df)
			di <= di_dec;
		else
			di <= di_inc;
	end
	else if (rty_i && !cyc_done)
		tRead(esdi);
	else
		cyc_done <= TRUE;
SCASB2:
	begin
		tGoto(IFETCH);
		pf <= pres;
		af <= carry   (1'b0,a[3],b[3],alu_o[3]);
		cf <= carry   (1'b0,a[7],b[7],alu_o[7]);
		vf <= overflow(1'b0,a[7],b[7],alu_o[7]);
		sf <= alu_o[7];
		zf <= reszb;
		if (repz|repnz)
			cx <= cx_dec;
		if ((repz & reszb) | (repnz & !reszb))
			tGoto(SCASB);
	end
