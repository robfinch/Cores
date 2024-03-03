// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  RETPOP
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

RETPOP:
	begin
		tRead(sssp);
		cyc_done <= FALSE;
		tGoto(RETPOP_NACK);
	end
RETPOP_NACK:
	if (ack_i) begin
		sp <= sp_inc;
		ip[7:0] <= dat_i;
		tGoto(RETPOP1);
	end
	else if (rty_i && !cyc_done)
		tRead(sssp);
	else
		cyc_done <= TRUE;
RETPOP1:
	begin
		tRead(sssp);
		cyc_done <= FALSE;
		tGoto(RETPOP1_NACK);
	end
RETPOP1_NACK:
	if (ack_i) begin
		tGoto(rf8088_pkg::IFETCH);
		wrregs <= 1'b1;
		w <= 1'b1;
		rrr <= 3'd4;
		res <= sp_inc + data16;
//		sp    <= sp_inc + data16;
		ip[15:8] <= dat_i;
	end
	else if (rty_i && !cyc_done)
		tRead(sssp);
	else
		cyc_done <= TRUE;
