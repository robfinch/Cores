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

rf80386_pkg::DECODE:
	casez(ir)
	`MORE1: tGoto(rf80386_pkg::XI_FETCH);
	`MORE2: tGoto(rf80386_pkg::XI_FETCH);
	`EXTOP: tGoto(rf80386_pkg::XI_FETCH);

	`DEC_REG,`INC_REG:
		begin
			w <= 1'b1;
			rrr <= ir[2:0];
			tGoto(rf80386_pkg::REGFETCHA);
		end

	`LEA: tGoto(rf80386_pkg::EXECUTE);

	//-----------------------------------------------------------------
	// Immediate Loads
	//-----------------------------------------------------------------
	
	`MOV_I2AL,`MOV_I2DL,`MOV_I2CL,`MOV_I2BL,`MOV_I2AH,`MOV_I2DH,`MOV_I2CH,`MOV_I2BH:
			tGoto(rf80386_pkg::MOV_I2BYTREG);

	`MOV_I2AX,`MOV_I2DX,`MOV_I2CX,`MOV_I2BX,`MOV_I2SP,`MOV_I2BP,`MOV_I2SI,`MOV_I2DI:
		begin
			w <= 1'b1;
			rrr <= ir[2:0];
			if (cs_desc.db ? eip > 32'hFFFFFFFC : eip==32'hFFFF) begin
				int_num <= 8'h0d;
				tGoto(rf80386_pkg::INT2);
			end
			else
				tGoto(rf80386_pkg::FETCH_IMM16);
		end
	
	`XLAT:
		tGoto(rf80386_pkg::XLAT);

	//-----------------------------------------------------------------
	// Arithmetic Operations
	//-----------------------------------------------------------------
	`AAA,`AAS:
		begin
			tGoto(rf80386_pkg::IFETCH);
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
			tGoto(rf80386_pkg::FETCH_IMM8);
		end
	`ADD_AXI16,`ADC_AXI16,`SUB_AXI16,`SBB_AXI16,`AND_AXI16,`OR_AXI16,`XOR_AXI16,`CMP_AXI16,`TEST_AXI16:
		begin
			w <= 1'b1;
			a <= ax;
			rrr <= 3'd0;
			if (cs_desc.db ? eip > 32'hFFFFFFFC : eip==32'hFFFF) begin
				int_num <= 8'h0d;
				tGoto(rf80386_pkg::INT2);
			end
			else
				tGoto(rf80386_pkg::FETCH_IMM16);
		end
	`ALU_I2R8:
		begin
			tGoto(rf80386_pkg::FETCH_IMM8);
			a <= rrro;
		end
	`ALU_I2R16:
		begin
			tGoto(rf80386_pkg::FETCH_IMM16);
			a <= rrro;
		end
	`XCHG_AXR:
		begin
			tGoto(rf80386_pkg::IFETCH);
			wrregs <= 1'b1;
			w <= 1'b1;
			rrr <= ir[2:0];
			res <= eax;
			case(ir[2:0])
			3'd0:	eax <= eax;
			3'd1:	eax <= ecx;
			3'd2:	eax <= edx;
			3'd3:	eax <= ebx;
			3'd4:	eax <= esp;
			3'd5:	eax <= ebp;
			3'd6:	eax <= esi;
			3'd7:	eax <= edi;
			endcase
		end
	`CBW: begin eax[15:8] <= {8{eax[7]}}; tGoto(rf80386_pkg::IFETCH); end
	`CWD:
		begin
			tGoto(rf80386_pkg::IFETCH);
			wrregs <= 1'b1;
			w <= 1'b1;
			rrr <= 3'd2;
			res <= {16{eax[15]}};
		end

	//-----------------------------------------------------------------
	// String Operations
	//-----------------------------------------------------------------
	`LODSB: tGoto(rf80386_pkg::LODS);
	`LODSW: tGoto(rf80386_pkg::LODS);
	`STOSB: tGoto(rf80386_pkg::STOS);
	`STOSW: tGoto(rf80386_pkg::STOS);
	`MOVSB: tGoto(rf80386_pkg::MOVS);
	`MOVSW: tGoto(rf80386_pkg::MOVS);
	`CMPSB: tGoto(rf80386_pkg::CMPSB);
	`CMPSW: tGoto(rf80386_pkg::CMPSW);
	`SCASB: tGoto(rf80386_pkg::SCASB);
	`SCASW: tGoto(rf80386_pkg::SCASW);

	//-----------------------------------------------------------------
	// Stack Operations
	//-----------------------------------------------------------------
	`PUSH_REG: begin esp <= cs_desc.db ? esp - 4'd4 : esp - 4'd2; tGoto(rf80386_pkg::PUSH); end
	`PUSH_DS: begin esp <= esp - 4'd2; tGoto(rf80386_pkg::PUSH); end
	`PUSH_ES: begin esp <= esp - 4'd2; tGoto(rf80386_pkg::PUSH); end
	`PUSH_SS: begin esp <= esp - 4'd2; tGoto(rf80386_pkg::PUSH); end
	`PUSH_CS: begin esp <= esp - 4'd2; tGoto(rf80386_pkg::PUSH); end
	`PUSHF: begin esp <= cs_desc.db ? esp - 4'd4 : esp - 4'd2; tGoto(rf80386_pkg::PUSH); end
	`PUSHA:
		begin
			tsp <= esp; 
			if (cs_desc.db)
				esp <= esp - 4'd4;
			else
				esp <= esp - 4'd2;
			tGoto(rf80386_pkg::PUSHA);
		end
	`PUSHI,`PUSHI8:
		begin
			if (cs_desc.db)
				esp <= esp - 4'd4;
			else
				esp <= esp - 4'd2;
			tGoto(rf80386_pkg::PUSH);
		end
	`POP_REG: tGoto(rf80386_pkg::POP);
	`POP_DS: tGoto(rf80386_pkg::POP);
	`POP_ES: tGoto(rf80386_pkg::POP);
	`POP_SS: tGoto(rf80386_pkg::POP);
	`POPF: tGoto(rf80386_pkg::POP);
	`POPA:	tGoto(rf80386_pkg::POPA);
	`ENTER:	
		begin
			if (cs_desc.db)
				esp <= esp - 4'd4;
			else
				esp <= esp - 4'd2;
			tGoto(rf80386_pkg::ENTER);
		end
	`LEAVE:
		begin
			if (cs_desc.db) begin
				esp <= ebp;
				ad <= ebp;
			end
			else begin
				esp[15:0] <= ebp[15:0];
				ad <= ebp[15:0];
			end
			tGoto(rf80386_pkg::LEAVE);
		end

	//-----------------------------------------------------------------
	// Flow controls
	//-----------------------------------------------------------------
	`NOP: tGoto(rf80386_pkg::IFETCH);
	`HLT: if (pe_nmi | (irq_i & ie)) tGoto(rf80386_pkg::IFETCH);
	`WAI: if (!busy_i) tGoto(rf80386_pkg::IFETCH);
	`LOOP: begin ecx <= cx_dec; tGoto(rf80386_pkg::BRANCH1); end
	`LOOPZ: begin ecx <= cx_dec; tGoto(rf80386_pkg::BRANCH1); end
	`LOOPNZ: begin ecx <= cx_dec; tGoto(rf80386_pkg::BRANCH1); end
	`Jcc: tGoto(rf80386_pkg::BRANCH1);
	`JCXZ: tGoto(rf80386_pkg::BRANCH1);
	`JMPS: tGoto(rf80386_pkg::BRANCH1);
	`JMPF: tGoto(rf80386_pkg::FETCH_OFFSET);
	`CALL: begin esp <= sp_dec; tGoto(rf80386_pkg::FETCH_DISP16); end
	`CALLF: begin esp <= sp_dec; tGoto(rf80386_pkg::FETCH_OFFSET); end
	`RET: tGoto(rf80386_pkg::RETPOP);		// data16 is zero
	`RETPOP: tGoto(rf80386_pkg::FETCH_STK_ADJ1);
	`RETF: tGoto(rf80386_pkg::RETFPOP);	// data16 is zero
	`RETFPOP: tGoto(rf80386_pkg::FETCH_STK_ADJ1);
	`IRET: tGoto(rf80386_pkg::IRET1);
	`INT: tGoto(rf80386_pkg::INT);
	`INT3: begin int_num <= 8'd3; tGoto(rf80386_pkg::INT2); end
	`INTO:
		if (vf) begin
			int_num <= 8'd4;
			tGoto(rf80386_pkg::INT2);
		end
		else
			tGoto(rf80386_pkg::IFETCH);

	//-----------------------------------------------------------------
	// Flag register operations
	//-----------------------------------------------------------------
	`STI: begin ie <= 1'b1; tGoto(rf80386_pkg::IFETCH); end
	`CLI: begin ie <= 1'b0; tGoto(rf80386_pkg::IFETCH); end
	`STD: begin df <= 1'b1; tGoto(rf80386_pkg::IFETCH); end
	`CLD: begin df <= 1'b0; tGoto(rf80386_pkg::IFETCH); end
	`STC: begin cf <= 1'b1; tGoto(rf80386_pkg::IFETCH); end
	`CLC: begin cf <= 1'b0; tGoto(rf80386_pkg::IFETCH); end
	`CMC: begin cf <=  !cf; tGoto(rf80386_pkg::IFETCH); end
	`LAHF:
		begin
			eax[15] <= sf;
			eax[14] <= zf;
			eax[12] <= af;
			eax[10] <= pf;
			eax[8] <= cf;
			tGoto(rf80386_pkg::IFETCH);
		end
	`SAHF:
		begin
			sf <= ah[7];
			zf <= ah[6];
			af <= ah[4];
			pf <= ah[2];
			cf <= ah[0];
			tGoto(rf80386_pkg::IFETCH);
		end

	//-----------------------------------------------------------------
	// IO instructions
	// - fetch port number, then vector
	//-----------------------------------------------------------------
	`INB: tGoto(rf80386_pkg::INB);
	`INW: tGoto(rf80386_pkg::INW);
	`OUTB: tGoto(rf80386_pkg::OUTB);
	`OUTW: tGoto(rf80386_pkg::OUTW);
	`INB_DX: begin ea <= {`SEG_SHIFT,dx}; tGoto(rf80386_pkg::INB1); end
	`INW_DX: begin ea <= {`SEG_SHIFT,dx}; tGoto(rf80386_pkg::INW1); end
	`OUTB_DX: begin ea <= {`SEG_SHIFT,dx}; tGoto(rf80386_pkg::OUTB1); end
	`OUTW_DX: begin ea <= {`SEG_SHIFT,dx}; tGoto(rf80386_pkg::OUTW1); end
	`INSB: tGoto(rf80386_pkg::INSB);
	`OUTSB: tGoto(rf80386_pkg::OUTSB);
	`OUTSW: tGoto(rf80386_pkg::OUTSW);

	//-----------------------------------------------------------------
	// Control Prefix
	//-----------------------------------------------------------------
	`LOCK: begin lock_insn <= ir; tGoto(rf80386_pkg::IFETCH); end
	`REPZ,`REPNZ,`CS,`DS,`ES,`SS: tGoto(rf80386_pkg::IFETCH);

	//-----------------------------------------------------------------
	// disp16 instructions
	//-----------------------------------------------------------------
	`MOV_M2AL,`MOV_M2AX,`MOV_AL2M,`MOV_AX2M,`CALL,`JMP:
		begin
			if (cs_desc.db) begin
				disp16 <= bundle[31:0];
				bundle <= bundle[127:32];
				eip <= eip + 4'd4;
			end
			else begin
				disp16 <= bundle[15:0];
				bundle <= bundle[127:16];
				eip <= eip + 4'd2;
			end
			tGoto(rf80386_pkg::FETCH_DISP16b);
		end

	default:
		begin
		if (v) shftamt <= cl[4:0];
		else shftamt <= 4'd1;
		case(ir)
		8'hC0,8'hC1:
			begin
				shftamt <= bundle[7:0];
				eip <= eip + 2'd1;
			end
		endcase
		//-----------------------------------------------------------------
		// MOD/RM instructions
		//-----------------------------------------------------------------
		$display("Fetching mod/rm, w=",w);
		if (ir==`MOV_R2S || ir==`MOV_S2R)
			w <= 1'b1;
		if (ir==`LDS || ir==`LES)
			w <= 1'b1;
		if (fetch_modrm) begin
			mod   <= bundle[7:6];
			rrr   <= bundle[5:3];
			sreg3 <= bundle[5:3];
			TTT   <= bundle[5:3];
			rm    <= bundle[2:0];
			$display("Mod/RM=%b_%b_%b", dat_i[7:6],dat_i[5:3],dat_i[2:0]);
			bundle <= bundle[127:8];
			eip <= eip + 2'd1;
			tGoto(rf80386_pkg::EACALC);
		end
		else
			tGoto(rf80386_pkg::IFETCH);
		end
	endcase
