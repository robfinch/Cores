// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  LODS
//  Fetch string data from memory.
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

LODS:
	if (w && (si==16'hFFFF) && !df) begin
		ir <= `NOP;
		int_num <= 8'd13;
		tGoto(INT2);
	end
	else begin
		tRead({seg_reg,`SEG_SHIFT} + si);
		tGoto(LODS_NACK);
	end
LODS_NACK:
	if (ack_i) begin
		if (df) begin
			si <= si_dec;
			if (w)
				b[15:8] <= dat_i;
			else begin
				b[ 7:0] <= dat_i;
				b[15:8] <= {8{dat_i[7]}};
			end
		end
		else begin
			si <= si_inc;
			b[ 7:0] <= dat_i;
			b[15:8] <= {8{dat_i[7]}};
		end
		tGoto(w ? LODS1 : EXECUTE);
	end
	else if (rty_i)
		tRead({seg_reg,`SEG_SHIFT} + si);

LODS1:
	begin
		cyc_type <= `CT_RDMEM;
		stb_o <= 1'b1;
		adr_o <= {seg_reg,`SEG_SHIFT} + si;
		state <= LODS1_NACK;
	end
LODS1_NACK:
	if (ack_i) begin
		cyc_type <= `CT_PASSIVE;
		lock_o <= 1'b0;
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		if (df) begin
			si <= si_dec;
			b[7:0] <= dat_i;
		end
		else begin
			si <= si_inc;
			b[15:8] <= dat_i;
		end
		state <= EXECUTE;
	end

