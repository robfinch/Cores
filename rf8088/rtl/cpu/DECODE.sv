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
//  DECODE
//  - decode / dispatch instruction
//
//=============================================================================

DECODE:
	casez(ir)
	`MORE1: tGoto(XI_FETCH);
	`MORE2: tGoto(XI_FETCH);
	`EXTOP: tGoto(XI_FETCH);

	`DEC_REG,`INC_REG:
		begin
			w <= 1'b1;
			rrr <= ir[2:0];
			tGoto(REGFETCHA);
		end

	`LEA: tGoto(EXECUTE);

	//-----------------------------------------------------------------
	// Immediate Loads
	//-----------------------------------------------------------------
	
	`MOV_I2AL,`MOV_I2DL,`MOV_I2CL,`MOV_I2BL,`MOV_I2AH,`MOV_I2DH,`MOV_I2CH,`MOV_I2BH:
			tGoto(MOV_I2BYTREG);

	`MOV_I2AX,`MOV_I2DX,`MOV_I2CX,`MOV_I2BX,`MOV_I2SP,`MOV_I2BP,`MOV_I2SI,`MOV_I2DI:
		begin
			w <= 1'b1;
			rrr <= ir[2:0];
			if (ip==16'hFFFF) begin
				int_num <= 8'h0d;
				tGoto(INT2);
			end
			else
				tGoto(FETCH_IMM16);
		end
	
	`XLAT:
		tGoto(XLAT);

	//-----------------------------------------------------------------
	// Arithmetic Operations
	//-----------------------------------------------------------------
	`AAA,`AAS:
		begin
			tGoto(IFETCH);
			wrregs <= 1'b1;
			w <= 1'b1;
			rrr <= 3'd0;
			res <= alu_o;
			af <= (al[3:0]>4'h9 || af);
			cf <= (al[3:0]>4'h9 || af);
		end
	`ADD_ALI8,`ADC_ALI8,`SUB_ALI8,`SBB_ALI8,`AND_ALI8,`OR_ALI8,`XOR_ALI8,`CMP_ALI8,`TEST_ALI8:
		begin
			w <= 1'b0;
			a <= {{8{al[7]}},al};
			rrr <= 3'd0;
			tGoto(FETCH_IMM8);
		end
	`ADD_AXI16,`ADC_AXI16,`SUB_AXI16,`SBB_AXI16,`AND_AXI16,`OR_AXI16,`XOR_AXI16,`CMP_AXI16,`TEST_AXI16:
		begin
			w <= 1'b1;
			a <= ax;
			rrr <= 3'd0;
			if (ip==16'hFFFF) begin
				int_num <= 8'h0d;
				tGoto(INT2);
			end
			else
				tGoto(FETCH_IMM16);
		end
	`ALU_I2R8:
		begin
			tGoto(FETCH_IMM8);
			a <= rrro;
		end
	`ALU_I2R16:
		begin
			tGoto(FETCH_IMM16);
			a <= rrro;
		end
	`XCHG_AXR:
		begin
			tGoto(IFETCH);
			wrregs <= 1'b1;
			w <= 1'b1;
			rrr <= ir[2:0];
			res <= ax;
			case(ir[2:0])
			3'd0:	ax <= ax;
			3'd1:	ax <= cx;
			3'd2:	ax <= dx;
			3'd3:	ax <= bx;
			3'd4:	ax <= sp;
			3'd5:	ax <= bp;
			3'd6:	ax <= si;
			3'd7:	ax <= di;
			endcase
		end
	`CBW: begin ax[15:8] <= {8{ax[7]}}; tGoto(IFETCH); end
	`CWD:
		begin
			tGoto(IFETCH);
			wrregs <= 1'b1;
			w <= 1'b1;
			rrr <= 3'd2;
			res <= {16{ax[15]}};
		end

	//-----------------------------------------------------------------
	// String Operations
	//-----------------------------------------------------------------
	`LODSB: tGoto(LODS);
	`LODSW: tGoto(LODS);
	`STOSB: tGoto(STOS);
	`STOSW: tGoto(STOS);
	`MOVSB: tGoto(MOVS);
	`MOVSW: tGoto(MOVS);
	`CMPSB: tGoto(CMPSB);
	`CMPSW: tGoto(CMPSW);
	`SCASB: tGoto(SCASB);
	`SCASW: tGoto(SCASW);

	//-----------------------------------------------------------------
	// Stack Operations
	//-----------------------------------------------------------------
	`PUSH_REG: begin sp <= sp_dec; tGoto(PUSH); end
	`PUSH_DS: begin sp <= sp_dec; tGoto(PUSH); end
	`PUSH_ES: begin sp <= sp_dec; tGoto(PUSH); end
	`PUSH_SS: begin sp <= sp_dec; tGoto(PUSH); end
	`PUSH_CS: begin sp <= sp_dec; tGoto(PUSH); end
	`PUSHF: begin sp <= sp_dec; tGoto(PUSH); end
	`POP_REG: tGoto(POP);
	`POP_DS: tGoto(POP);
	`POP_ES: tGoto(POP);
	`POP_SS: tGoto(POP);
	`POPF: tGoto(POP);

	//-----------------------------------------------------------------
	// Flow controls
	//-----------------------------------------------------------------
	`NOP: tGoto(IFETCH);
	`HLT: if (pe_nmi | (irq_i & ie)) tGoto(IFETCH);
	`WAI: if (!busy_i) tGoto(IFETCH);
	`LOOP: begin cx <= cx_dec; tGoto(BRANCH1); end
	`LOOPZ: begin cx <= cx_dec; tGoto(BRANCH1); end
	`LOOPNZ: begin cx <= cx_dec; tGoto(BRANCH1); end
	`Jcc: tGoto(BRANCH1);
	`JCXZ: tGoto(BRANCH1);
	`JMPS: tGoto(BRANCH1);
	`JMPF: tGoto(FETCH_OFFSET);
	`CALL: begin sp <= sp_dec; tGoto(FETCH_DISP16); end
	`CALLF: begin sp <= sp_dec; tGoto(FETCH_OFFSET); end
	`RET: tGoto(RETPOP);		// data16 is zero
	`RETPOP: tGoto(FETCH_STK_ADJ1);
	`RETF: tGoto(RETFPOP);	// data16 is zero
	`RETFPOP: tGoto(FETCH_STK_ADJ1);
	`IRET: tGoto(IRET1);
	`INT: tGoto(INT);
	`INT3: begin int_num <= 8'd3; tGoto(INT2); end
	`INTO:
		if (vf) begin
			int_num <= 8'd4;
			tGoto(INT2);
		end
		else
			tGoto(IFETCH);

	//-----------------------------------------------------------------
	// Flag register operations
	//-----------------------------------------------------------------
	`STI: begin ie <= 1'b1; tGoto(IFETCH); end
	`CLI: begin ie <= 1'b0; tGoto(IFETCH); end
	`STD: begin df <= 1'b1; tGoto(IFETCH); end
	`CLD: begin df <= 1'b0; tGoto(IFETCH); end
	`STC: begin cf <= 1'b1; tGoto(IFETCH); end
	`CLC: begin cf <= 1'b0; tGoto(IFETCH); end
	`CMC: begin cf <=  !cf; tGoto(IFETCH); end
	`LAHF:
		begin
			ax[15] <= sf;
			ax[14] <= zf;
			ax[12] <= af;
			ax[10] <= pf;
			ax[8] <= cf;
			tGoto(IFETCH);
		end
	`SAHF:
		begin
			sf <= ah[7];
			zf <= ah[6];
			af <= ah[4];
			pf <= ah[2];
			cf <= ah[0];
			tGoto(IFETCH);
		end

	//-----------------------------------------------------------------
	// IO instructions
	// - fetch port number, then vector
	//-----------------------------------------------------------------
	`INB: tGoto(INB);
	`INW: tGoto(INW);
	`OUTB: tGoto(OUTB);
	`OUTW: tGoto(OUTW);
	`INB_DX: begin ea <= {`SEG_SHIFT,dx}; tGoto(INB1); end
	`INW_DX: begin ea <= {`SEG_SHIFT,dx}; tGoto(INW1); end
	`OUTB_DX: begin ea <= {`SEG_SHIFT,dx}; tGoto(OUTB1); end
	`OUTW_DX: begin ea <= {`SEG_SHIFT,dx}; tGoto(OUTW1); end
	`INSB: tGoto(INSB);
	`OUTSB: tGoto(OUTSB);
	`OUTSW: tGoto(OUTSW);

	//-----------------------------------------------------------------
	// Control Prefix
	//-----------------------------------------------------------------
	`LOCK: begin lock_insn <= ir; tGoto(IFETCH); end
	`REPZ,`REPNZ,`CS,`DS,`ES,`SS: tGoto(IFETCH);

	//-----------------------------------------------------------------
	// disp16 instructions
	//-----------------------------------------------------------------
	`MOV_M2AL,`MOV_M2AX,`MOV_AL2M,`MOV_AX2M,`CALL,`JMP:
		begin
			code_read();
			tGoto(FETCH_DISP16_ACK);
		end

	default:
		begin
		if (v) shftamt <= cl[3:0];
		else shftamt <= 4'd1;
		//-----------------------------------------------------------------
		// MOD/RM instructions
		//-----------------------------------------------------------------
		$display("Fetching mod/rm, w=",w);
		if (ir==`MOV_R2S || ir==`MOV_S2R)
			w <= 1'b1;
		if (ir==`LDS || ir==`LES)
			w <= 1'b1;
		if (fetch_modrm) begin
			mod   <= dat_i[7:6];
			rrr   <= dat_i[5:3];
			sreg3 <= dat_i[5:3];
			TTT   <= dat_i[5:3];
			rm    <= dat_i[2:0];
			$display("Mod/RM=%b_%b_%b", dat_i[7:6],dat_i[5:3],dat_i[2:0]);
			bundle <= bundle[127:8];
			tGoto(EACALC);
		end
		else
			tGoto(IFETCH);
		end
	endcase
