// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// CMPSW
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

CMPSW:
`include "check_for_ints.v"
	else begin
		tRead({seg_reg,`SEG_SHIFT} + si);
		tGoto(CMPSW1);
	end

CMPSW1:
	if (ack_i) begin
		if (df) begin
			si <= si_dec;
			a[15:8] <= dat_i;
		end
		else begin
			si <= si_inc;
			a[ 7:0] <= dat_i;
		end
		tGoto(CMPSW2);
	end
	else if (rty_i)
		tRead({seg_reg,`SEG_SHIFT} + si);

CMPSW2:
	begin
		tRead({seg_reg,`SEG_SHIFT} + si);
		tGoto(CMPSW3);
	end

CMPSW3:
	if (ack_i) begin
		if (df) begin
			si <= si_dec;
			a[7:0] <= dat_i;
		end
		else begin
			si <= si_inc;
			a[15:8] <= dat_i;
		end
		tGoto(CMPSW4);
	end
	else if (rty_i)
		tRead({seg_reg,`SEG_SHIFT} + si);

CMPSW4:
	begin
		tRead(esdi);
		tGoto(CMPSW5);
	end

CMPSW5:
	if (ack_i) begin
		if (df) begin
			di <= di_dec;
			b[15:8] <= dat_i;
		end
		else begin
			di <= di_inc;
			b[ 7:0] <= dat_i;
		end
		tGoto(CMPSW6);
	end
	else if (rty_i)
		tRead(esdi);

CMPSW6:
	begin
		tRead(esdi);
		tGoto(CMPSW7);
	end

CMPSW7:
	if (ack_i) begin
		if (df) begin
			di <= di_dec;
			b[7:0] <= dat_i;
		end
		else begin
			di <= di_inc;
			b[15:8] <= dat_i;
		end
		tGoto(CMPSW8);
	end
	else if (rty_i)
		tRead(esdi);

CMPSW8:
	begin
		pf <= pres;
		zf <= reszw;
		sf <= resnw;
		af <= carry   (1'b1,a[3],b[3],alu_o[3]);
		cf <= carry   (1'b1,a[15],b[15],alu_o[15]);
		vf <= overflow(1'b1,a[15],b[15],alu_o[15]);
		if ((repz & !cxz & zf) | (repnz & !cxz & !zf)) begin
			cx <= cx_dec;
			tGoto(CMPSW);
		end
		else
			tGoto(IFETCH);
	end
