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

rf80386_pkg::CMPSW:
  if (pe_nmi & checkForInts) begin
    rst_nmi <= 1'b1;
    int_num <= 8'h02;
    ir <= `NOP;
    tGoto(rf80386_pkg::INT2);
  end
  else if (irq_i & ie & checkForInts) begin
    ir <= `NOP;
    tGoto(rf80386_pkg::INTA0);
  end
	else begin
		tRead(seg_reg + (cs_desc.db ? esi : si));
		cyc_done <= FALSE;
		tGoto(rf80386_pkg::CMPSW1);
	end

rf80386_pkg::CMPSW1:
	if (ack_i) begin
		if (df) begin
			esi <= si_dec;
			if (cs_desc.db)
				a[31:24] <= dat_i;
			else
				a[15:8] <= dat_i;
		end
		else begin
			esi <= si_inc;
			a[ 7:0] <= dat_i;
		end
		tGoto(rf80386_pkg::CMPSW2);
	end
	else if (rty_i && !cyc_done)
		tRead(seg_reg + (cs_desc.db ? esi : si));
	else
		cyc_done <= TRUE;

rf80386_pkg::CMPSW2:
	begin
		tRead(seg_reg + (cs_desc.db ? esi : si));
		cyc_done <= FALSE;
		tGoto(rf80386_pkg::CMPSW3);
	end

rf80386_pkg::CMPSW3:
	if (ack_i) begin
		if (df) begin
			si <= si_dec;
			if (cs_desc.db)
				a[23:16] <= dat_i;
			else
				a[7:0] <= dat_i;
		end
		else begin
			si <= si_inc;
			a[15:8] <= dat_i;
		end
		tGoto(cd_desc.db ? CMPSW4 : CMPSW8);
	end
	else if (rty_i && !cyc_done)
		tRead(seg_reg + (cs_desc.db ? esi : si));
	else
		cyc_done <= TRUE;

CMPSW4:
	begin
		tRead(seg_reg + esi);
		cyc_done <= FALSE;
		tGoto(rf80386_pkg::CMPSW5);
	end

rf80386_pkg::CMPSW5:
	if (ack_i) begin
		if (df) begin
			si <= si_dec;
			a[15:8] <= dat_i;
		end
		else begin
			si <= si_inc;
			a[23:16] <= dat_i;
		end
		tGoto(rf80386_pkg::CMPSW6);
	end
	else if (rty_i && !cyc_done)
		tRead(seg_reg + esi);
	else
		cyc_done <= TRUE;

rf80386_pkg::CMPSW6:
	begin
		tRead(seg_reg + esi);
		cyc_done <= FALSE;
		tGoto(rf80386_pkg::CMPSW7);
	end

rf80386_pkg::CMPSW7:
	if (ack_i) begin
		if (df) begin
			si <= si_dec;
			a[7:0] <= dat_i;
		end
		else begin
			si <= si_inc;
			a[31:24] <= dat_i;
		end
		tGoto(rf80386_pkg::CMPSW8);
	end
	else if (rty_i && !cyc_done)
		tRead(seg_reg + esi);
	else
		cyc_done <= TRUE;

rf80386_pkg::CMPSW8:
	begin
		tRead(esdi);
		cyc_done <= FALSE;
		tGoto(rf80386_pkg::CMPSW9);
	end

rf80386_pkg::CMPSW9:
	if (ack_i) begin
		if (df) begin
			di <= di_dec;
			if (cs_desc.db)
				b[31:24] <= dat_i;
			else
				b[15:8] <= dat_i;
		end
		else begin
			di <= di_inc;
			b[ 7:0] <= dat_i;
		end
		tGoto(rf80386_pkg::CMPSW10);
	end
	else if (rty_i && !cyc_done)
		tRead(esdi);
	else
		cyc_done <= TRUE;

rf80386_pkg::CMPSW10:
	begin
		tRead(esdi);
		cyc_done <= FALSE;
		tGoto(rf80386_pkg::CMPSW11);
	end

rf80386_pkg::CMPSW11:
	if (ack_i) begin
		if (df) begin
			di <= di_dec;
			if (cs_desc.db)
				b[23:16] <= dat_i;
			else
				b[7:0] <= dat_i;
		end
		else begin
			di <= di_inc;
			b[15:8] <= dat_i;
		end
		tGoto(cs_desc.db ? rf80386_pkg::CMPSW12 : rf80386_pkg::CMPSW16);
	end
	else if (rty_i && !cyc_done)
		tRead(esdi);
	else
		cyc_done <= TRUE;

rf80386_pkg::CMPSW12:
	begin
		tRead(esdi);
		cyc_done <= FALSE;
		tGoto(rf80386_pkg::CMPSW13);
	end

rf80386_pkg::CMPSW13:
	if (ack_i) begin
		if (df) begin
			di <= di_dec;
			b[15:8] <= dat_i;
		end
		else begin
			di <= di_inc;
			b[23:16] <= dat_i;
		end
		tGoto(rf80386_pkg::CMPSW14);
	end
	else if (rty_i && !cyc_done)
		tRead(esdi);
	else
		cyc_done <= TRUE;

rf80386_pkg::CMPSW14:
	begin
		tRead(esdi);
		cyc_done <= FALSE;
		tGoto(rf80386_pkg::CMPSW15);
	end

rf80386_pkg::CMPSW15:
	if (ack_i) begin
		if (df) begin
			di <= di_dec;
			b[7:0] <= dat_i;
		end
		else begin
			di <= di_inc;
			b[31:24] <= dat_i;
		end
		tGoto(rf80386_pkg::CMPSW16);
	end
	else if (rty_i && !cyc_done)
		tRead(esdi);
	else
		cyc_done <= TRUE;

rf80386_pkg::CMPSW16:
	begin
		pf <= pres;
		zf <= reszw;
		sf <= resnw;
		af <= carry   (1'b1,a[3],b[3],alu_o[3]);
		if (cs_desc.db) begin
			cf <= carry   (1'b1,a[31],b[31],alu_o[31]);
			vf <= overflow(1'b1,a[31],b[31],alu_o[31]);
		end
		else begin
			cf <= carry   (1'b1,a[15],b[15],alu_o[15]);
			vf <= overflow(1'b1,a[15],b[15],alu_o[15]);
		end
		if ((repz & !cxz & zf) | (repnz & !cxz & !zf)) begin
			ecx <= cx_dec;
			tGoto(rf80386_pkg::CMPSW);
		end
		else
			tGoto(rf8088_pkg::IFETCH);
	end
