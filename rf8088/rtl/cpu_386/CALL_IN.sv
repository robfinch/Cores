// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// CALL NEAR Indirect
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

CALL_IN:
	begin
		tWrite(sssp,ip[15:8]);
		tGoto(CALL_IN1);
	end
CALL_IN1:
	if (rty_i)
		tWrite(sssp,ip[15:8]);
	else begin
		sp <= sp_dec;
		tGoto(CALL_IN2);
	end
CALL_IN2:
	begin
		tWrite(sssp,ip[7:0]);
		tGoto(CALL_IN3);
	end
CALL_IN3:
	if (rty_i)
		tWrite(sssp,ip[7:0]);
	else begin
		sp <= sp_dec;
		ea <= {cs,`SEG_SHIFT}+b;
		if (mod==2'b11) begin
			ip <= b;
			tGoto(rf8088_pkg::IFETCH);
		end
		else 
			tGoto(CALL_IN4);
	end
CALL_IN4:
	begin
		tRead(ea);
		cyc_done <= FALSE;
		tGoto(CALL_IN5);
	end
CALL_IN5:
	if (ack_i) begin
		b[7:0] <= dat_i;
		tGoto(CALL_IN6);
	end
	else if (rty_i && !cyc_done)
		tRead(ea);
	else
		cyc_done <= TRUE;
CALL_IN6:
	begin
		tRead(ea_inc);
		cyc_done <= FALSE;
		tGoto(CALL_IN7);
	end
CALL_IN7:
	if (ack_i) begin
		tGoto(CALL_IN8);
		b[15:8] <= dat_i;
	end
	else if (rty_i && !cyc_done)
		tRead(ea_inc);
	else
		cyc_done <= TRUE;
CALL_IN8:
	begin
		ip <= b;
		tGoto(rf8088_pkg::IFETCH);
	end

