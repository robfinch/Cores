// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  IRET
//  - return from interrupt
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
//  IRET: return from interrupt
//  Fetch cs:ip from stack
//  pop ip
//  pop cs
//  pop flags
// ============================================================================
//
IRET1:
	begin
		tRead(sssp);
		cyc_done <= FALSE;
		tGoto(IRET2);
	end
IRET2:
	if (ack_i) begin
		sp <= sp_inc;
		ip[7:0] <= dat_i;
		tGoto(IRET3);
	end
	else if (rty_i && !cyc_done)
		tRead(sssp);
	else
		cyc_done <= TRUE;
IRET3:
	begin
		tRead(sssp);
		cyc_done <= FALSE;
		tGoto(IRET4);
	end
IRET4:
	if (ack_i) begin
		sp <= sp_inc;
		ip[15:8] <= dat_i;
		tGoto(IRET5);
	end
	else if (rty_i && !cyc_done)
		tRead(sssp);
	else
		cyc_done <= TRUE;
IRET5:
	begin
		tRead(sssp);
		cyc_done <= FALSE;
		tGoto(IRET6);
	end
IRET6:
	if (ack_i) begin
		sp <= sp_inc;
		cs[7:0] <= dat_i;
		tGoto(IRET5);
	end
	else if (rty_i && !cyc_done)
		tRead(sssp);
	else
		cyc_done <= TRUE;
IRET7:
	begin
		tRead(sssp);
		cyc_done <= FALSE;
		tGoto(IRET8);
	end
IRET8:
	if (ack_i) begin
		sp <= sp_inc;
		cs[15:8] <= dat_i;
		tGoto(IRET9);
	end
	else if (rty_i && !cyc_done)
		tRead(sssp);
	else
		cyc_done <= TRUE;
IRET9:
	begin
		tRead(sssp);
		cyc_done <= FALSE;
		tGoto(IRET10);
	end
IRET10:
	if (ack_i) begin
		sp <= sp_inc;
		cf <= dat_i[0];
		pf <= dat_i[2];
		af <= dat_i[4];
		zf <= dat_i[6];
		sf <= dat_i[7];
		tGoto(IRET11);
	end
	else if (rty_i && !cyc_done)
		tRead(sssp);
	else
		cyc_done <= TRUE;
IRET11:
	begin
		tRead(sssp);
		cyc_done <= FALSE;
		tGoto(IRET12);
	end
IRET12:
	if (ack_i) begin
		sp <= sp_inc;
		tf <= dat_i[0];
		ie <= dat_i[1];
		df <= dat_i[2];
		vf <= dat_i[3];
		tGoto(rf8088_pkg::IFETCH);
	end
	else if (rty_i && !cyc_done)
		tRead(sssp);
	else
		cyc_done <= TRUE;
