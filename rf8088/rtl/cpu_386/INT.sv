// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  INT.v
//  - Interrupt handling
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
//
// Fetch interrupt number from instruction stream

INT:
	begin
		sp <= sp_dec;		// pre-decrement
		ip <= ip + 2'd1;
		int_num <= bundle[7:0];
		state <= INT2;
	end
INT2:
	begin
		tRead({int_num,2'b00});
		cyc_done <= FALSE;
		tGoto(INT3);
	end
INT3:
	if (ack_i) begin
		offset[7:0] <= dat_i;
		tGoto(INT4);
	end
	else if (rty_i && !cyc_done)
		tRead({int_num,2'b00});
	else
		cyc_done <= TRUE;
INT4:
	begin
		tRead(adr_o_inc);
		cyc_done <= FALSE;
		tGoto(INT5);
	end
INT5:
	if (ack_i) begin
		offset[15:8] <= dat_i;
		tGoto(INT6);
	end
	else if (rty_i && !cyc_done)
		tRead(adr_o);
	else
		cyc_done <= TRUE;
INT6:
	begin
		tRead(adr_o_inc);
		cyc_done <= FALSE;
		tGoto(INT7);
	end
INT7:
	if (ack_i) begin
		selector[7:0] <= dat_i;
		tGoto(INT8);
	end
	else if (rty_i && !cyc_done)
		tRead(adr_o);
	else
		cyc_done <= TRUE;
INT8:
	begin
		tRead(adr_o_inc);
		cyc_done <= FALSE;
		tGoto(INT9);
	end
INT9:
	if (ack_i) begin
		selector[15:8] <= dat_i;
		tGoto(INT10);
	end
	else if (rty_i && !cyc_done)
		tRead(adr_o);
	else
		cyc_done <= TRUE;
INT10:
	begin
		tWrite(sssp,flags[15:8]);
		tGoto(INT11);
	end
INT11:
	if (rty_i)
		tWrite(sssp,flags[15:8]);
	else begin
		sp <= sp_dec;
		tGoto(INT12);
	end
INT12:
	begin
		tWrite(sssp,flags[7:0]);
		tGoto(INT13);
	end
INT13:
	if (rty_i)
		tWrite(sssp,flags[7:0]);
	else begin
		sp <= sp_dec;
		tGoto(INT14);
	end
INT14:
	begin
		tWrite(sssp,cs[15:8]);
		tGoto(INT15);
	end
INT15:
	if (rty_i)
		tWrite(sssp,cs[15:8]);
	else begin
		sp <= sp_dec;
		tGoto(INT16);
	end
INT16:
	begin
		tWrite(sssp,cs[7:0]);
		tGoto(INT17);
	end
INT17:
	if (rty_i)
		tWrite(sssp,cs[7:0]);
	else begin
		sp <= sp_dec;
		tGoto(INT18);
	end
INT18:
	begin
		tWrite(sssp,ir_ip[15:8]);
		tGoto(INT19);
	end
INT19:
	if (rty_i)
		tWrite(sssp,ir_ip[15:8]);
	else begin
		sp <= sp_dec;
		tGoto(INT20);
	end
INT20:
	begin
		tWrite(sssp,ir_ip[7:0]);
		tGoto(INT21);
	end
INT21:
	if (rty_i)
		tWrite(sssp,ir_ip[7:0]);
	else begin
		cs <= selector;
		ip <= offset;
		tGoto(rf8088_pkg::IFETCH);
	end
