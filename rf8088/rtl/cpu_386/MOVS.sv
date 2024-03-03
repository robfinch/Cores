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
		tRead(dssi);
		cyc_done <= FALSE;
		tGoto(rf80386_pkg::MOVS1);
	end
rf80386_pkg::MOVS1:
	if (ack_i) begin
		tGoto(rf80386_pkg::MOVS2);
		a[7:0] <= dat_i;
		si <= df ? si_dec : si_inc;
	end
	else if (rty_i && !cyc_done)
		tRead(dssi);
	else
		cyc_done <= TRUE;
	
rf80386_pkg::MOVS2:
	begin
		tWrite(esdi,a[7:0]);
		tGoto(rf80386_pkg::MOVS3);
	end
rf80386_pkg::MOVS3:
	if (rty_i)
		tWrite(esdi,a[7:0]);
	else begin
		di <= df ? di_dec : di_inc;
		tGoto(w ? rf80386_pkg::MOVS4 : rf80386_pkg::MOVS16);
	end
// read/write 2nd byte
rf80386_pkg::MOVS4:
	begin
		tRead(dssi);
		cyc_done <= FALSE;
		tGoto(rf80386_pkg::MOVS5);
	end
rf80386_pkg::MOVS5:
	if (ack_i) begin
		a[7:0] <= dat_i;
		si <= df ? si_dec : si_inc;
		tGoto(rf80386_pkg::MOVS6);
	end
	else if (rty_i && !cyc_done)
		tRead(dssi);
	else
		cyc_done <= TRUE;
rf80386_pkg::MOVS6:
	begin
		tWrite(esdi,a[7:0]);
		tGoto(rf80386_pkg::MOVS7);
	end
rf80386_pkg::MOVS7:
	if (rty_i)
		tWrite(esdi,a[7:0]);
	else begin
		di <= df ? di_dec : di_inc;
		tGoto(cs_desc.db ? rf80386_pkg::MOVS8 : rf80386_pkg::MOVS16);
	end
// read/write 3rd byte
rf80386_pkg::MOVS8:
	begin
		tRead(dssi);
		cyc_done <= FALSE;
		tGoto(rf80386_pkg::MOVS9);
	end
rf80386_pkg::MOVS9:
	if (ack_i) begin
		a[7:0] <= dat_i;
		si <= df ? si_dec : si_inc;
		tGoto(rf80386_pkg::MOVS10);
	end
	else if (rty_i && !cyc_done)
		tRead(dssi);
	else
		cyc_done <= TRUE;
rf80386_pkg::MOVS10:
	begin
		tWrite(esdi,a[7:0]);
		tGoto(rf80386_pkg::MOVS11);
	end
rf80386_pkg::MOVS11:
	if (rty_i)
		tWrite(esdi,a[7:0]);
	else begin
		di <= df ? di_dec : di_inc;
		tGoto(rf80386_pkg::MOVS12);
	end
// read/write 4th byte
rf80386_pkg::MOVS12:
	begin
		tRead(dssi);
		cyc_done <= FALSE;
		tGoto(rf80386_pkg::MOVS13);
	end
rf80386_pkg::MOVS13:
	if (ack_i) begin
		a[7:0] <= dat_i;
		si <= df ? si_dec : si_inc;
		tGoto(rf80386_pkg::MOVS14);
	end
	else if (rty_i && !cyc_done)
		tRead(dssi);
	else
		cyc_done <= TRUE;
rf80386_pkg::MOVS14:
	begin
		tWrite(esdi,a[7:0]);
		tGoto(rf80386_pkg::MOVS15);
	end
rf80386_pkg::MOVS15:
	if (rty_i)
		tWrite(esdi,a[7:0]);
	else begin
		di <= df ? di_dec : di_inc;
		tGoto(rf80386_pkg::MOVS16);
	end

rf80386_pkg::MOVS16:
	begin
		if (repz|repnz) begin
			ecx <= cx_dec;
			tGoto(rf80386_pkg::MOVS);
		end
		else
			tGoto(rf80386_pkg::IFETCH);
	end
