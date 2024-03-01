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
// ============================================================================

package rf8088_pkg;

`ifdef BIG_SEGS
`define SEG_SHIFT		8'b0
`define AMSB			23
`define CS_RESET		16'hFF00
`else
`define SEG_SHIFT		4'b0
`define AMSB			19
`define CS_RESET		16'hF000
`endif

// Opcodes
//
`define MOV_RR	8'b1000100?
`define MOV_MR	8'b1000101?
`define MOV_IM	8'b1100011?
`define MOV_MA	8'b1010000?
`define MOV_AM	8'b0101001?

`define ADD			8'b000000??
`define ADD_ALI8	8'h04
`define ADD_AXI16	8'h05
`define PUSH_ES		8'h06
`define POP_ES		8'h07
`define OR          8'b000010??
`define AAD			8'h0A
`define AAM			8'h0A
`define OR_ALI8		8'h0C
`define OR_AXI16	8'h0D
`define PUSH_CS     8'h0E
`define EXTOP		8'h0F	// extended opcode

`define ADC			8'b000100??
`define ADC_ALI8	8'h14
`define ADC_AXI16	8'h15
`define PUSH_SS     8'h16
`define POP_SS		8'h17
`define SBB         8'b000110??
`define SBB_ALI8	8'h1C
`define SBB_AXI16	8'h1D
`define PUSH_DS     8'h1E
`define POP_DS		8'h1F

`define AND			8'b001000??
`define AND_ALI8	8'h24
`define AND_AXI16	8'h25
`define ES			8'h26
`define DAA			8'h27
`define SUB     	8'b001010??
`define SUB_ALI8	8'h2C
`define SUB_AXI16	8'h2D
`define CS			8'h2E
`define DAS			8'h2F

`define XOR     	8'b001100??
`define XOR_ALI8	8'h34
`define XOR_AXI16	8'h35
`define SS			8'h36
`define AAA			8'h37
`define CMP			8'b001110??
`define CMP_ALI8	8'h3C
`define CMP_AXI16	8'h3D
`define DS			8'h3E
`define AAS			8'h3F

`define INC_REG 8'b01000???
`define INC_AX	8'h40
`define INC_CX	8'h41
`define INC_DX	8'h42
`define INC_BX	8'h43
`define INC_SP	8'h44
`define INC_BP	8'h45
`define INC_SI	8'h46
`define INC_DI	8'h47
`define DEC_REG	8'b01001???
`define DEC_AX	8'h48
`define DEC_CX	8'h49
`define DEC_DX	8'h4A
`define DEC_BX	8'h4B
`define DEC_SP	8'h4C
`define DEC_BP	8'h4D
`define DEC_SI	8'h4E
`define DEC_DI	8'h4F

`define PUSH_REG	8'b01010???
`define PUSH_AX 8'h50
`define PUSH_CX	8'h51
`define PUSH_DX	8'h52
`define PUSH_BX	8'h53
`define PUSH_SP 8'h54
`define PUSH_BP 8'h55
`define PUSH_SI 8'h56
`define PUSH_DI 8'h57
`define POP_REG		8'b01011???
`define POP_AX	8'h58
`define POP_CX	8'h59
`define POP_DX	8'h5A
`define POP_BX	8'h5B
`define POP_SP  8'h5C
`define POP_BP  8'h5D
`define POP_SI  8'h5E
`define POP_DI  8'h5F

`define PUSHA	8'h60
`define POPA	8'h61
`define BOUND	8'h62
`define ARPL	8'h63
`define FS		8'h64
`define GS		8'h65
`define INSB	8'h6C
`define INSW	8'h6D
`define OUTSB	8'h6E
`define OUTSW	8'h6F

`define Jcc		8'b0111????
`define JO		8'h70
`define JNO		8'h71
`define JB		8'h72
`define JAE		8'h73
`define JE		8'h74
`define JNE		8'h75
`define JBE		8'h76
`define JA		8'h77
`define JS		8'h78
`define JNS		8'h79
`define JP		8'h7A
`define JNP		8'h7B
`define JL		8'h7C
`define JNL		8'h7D
`define JLE		8'h7E
`define JNLE	8'h7F

`define JNA		8'h76
`define JNAE	8'h72
`define JNB     8'h73
`define JNBE    8'h77
`define JC      8'h72
`define JNC     8'h73
`define JG		8'h7F
`define JNG		8'h7E
`define JGE		8'h7D
`define JNGE	8'h7C
`define JPE     8'h7A
`define JPO     8'h7B

`define ALU_I2R8	8'h80
`define ALU_I2R16	8'h81
`define TEST        8'b1000010?
`define XCHG_MEM	8'h86
`define MOV_RR8		8'h88
`define MOV_RR16	8'h89
`define MOV_MR8		8'h8A
`define MOV_MR16	8'h8B
`define MOV_S2R		8'h8C
`define LEA			8'h8D
`define MOV_R2S		8'h8E
`define POP_MEM		8'h8F

`define XCHG_AXR	8'b10010???
`define NOP			8'h90
`define CBW			8'h98
`define CWD			8'h99
`define CALLF		8'h9A
`define WAI         8'h9B
`define PUSHF		8'h9C
`define POPF		8'h9D
`define SAHF		8'h9E
`define LAHF		8'h9F

`define MOV_M2AL	8'hA0
`define MOV_M2AX	8'hA1
`define MOV_AL2M	8'hA2
`define MOV_AX2M	8'hA3

`define MOVSB		8'hA4
`define MOVSW		8'hA5
`define CMPSB		8'hA6
`define CMPSW		8'hA7
`define TEST_ALI8	8'hA8
`define TEST_AXI16	8'hA9
`define STOSB		8'hAA
`define STOSW		8'hAB
`define LODSB		8'hAC
`define LODSW		8'hAD
`define SCASB		8'hAE
`define SCASW		8'hAF

`define MOV_I2BYTREG	8'h1011_0???
`define MOV_I2AL	8'hB0
`define MOV_I2CL	8'hB1
`define MOV_I2DL	8'hB2
`define MOV_I2BL	8'hB3
`define MOV_I2AH	8'hB4
`define MOV_I2CH	8'hB5
`define MOV_I2DH	8'hB6
`define MOV_I2BH	8'hB7
`define MOV_I2AX	8'hB8
`define MOV_I2CX	8'hB9
`define MOV_I2DX	8'hBA
`define MOV_I2BX	8'hBB
`define MOV_I2SP	8'hBC
`define MOV_I2BP	8'hBD
`define MOV_I2SI	8'hBE
`define MOV_I2DI	8'hBF

`define RETPOP		8'hC2
`define RET			8'hC3
`define LES			8'hC4
`define LDS			8'hC5
`define MOV_I8M		8'hC6
`define MOV_I16M	8'hC7
`define LEAVE		8'hC9
`define RETFPOP		8'hCA
`define RETF		8'hCB
`define INT3		8'hCC
`define INT     	8'hCD
`define INTO		8'hCE
`define IRET		8'hCF

`define RCL_81	8'hD0
`define RCL_161	8'hD1
`define MORE1	8'hD4
`define MORE2	8'hD5
`define XLAT    8'hD7

`define LOOPNZ	8'hE0
`define LOOPZ	8'hE1
`define LOOP	8'hE2
`define JCXZ	8'hE3
`define INB		8'hE4
`define INW		8'hE5
`define OUTB	8'hE6
`define OUTW	8'hE7
`define CALL	8'hE8
`define JMP 	8'hE9
`define JMPF	8'hEA
`define JMPS	8'hEB
`define INB_DX	8'hEC
`define INW_DX	8'hED
`define OUTB_DX	8'hEE
`define OUTW_DX	8'hEF

`define LOCK	8'hF0
`define REPNZ	8'hF2
`define REPZ	8'hF3
`define HLT		8'hF4
`define CMC		8'hF5
//`define IMUL	8'b1111011x
`define CLC		8'hF8
`define STC		8'hF9
`define CLI		8'hFA
`define STI		8'hFB
`define CLD		8'hFC
`define STD		8'hFD
`define GRPFF	8'b1111111?

// extended opcodes
// "OF"
`define LLDT	8'h00
`define LxDT	8'h01
`define LAR		8'h02
`define LSL		8'h03
`define CLTS	8'h06

`define LSS		8'hB2
`define LFS		8'hB4
`define LGS		8'hB5

`define INITIATE_CODE_READ		cyc_type <= `CT_CODE; cyc_o <= 1'b1; stb_o <= 1'b1; we_o <= 1'b0; adr_o <= csip;
`define TERMINATE_CYCLE			cyc_type <= `CT_PASSIVE; cyc_o <= 1'b0; stb_o <= 1'b0; we_o <= 1'b0;
`define TERMINATE_CODE_READ		cyc_type <= `CT_PASSIVE; cyc_o <= 1'b0; stb_o <= 1'b0; we_o <= 1'b0; ip <= ip_inc;
`define PAUSE_CODE_READ			cyc_type <= `CT_PASSIVE; stb_o <= 1'b0; ip <= ip_inc;
`define CONTINUE_CODE_READ		cyc_type <= `CT_CODE; stb_o <= 1'b1; adr_o <= csip;
`define INITIATE_STACK_WRITE	cyc_type <= `CT_WRMEM; cyc_o <= 1'b1; stb_o <= 1'b1; we_o <= 1'b1; adr_o <= sssp;
`define PAUSE_STACK_WRITE		cyc_type <= `CT_PASSIVE; sp <= sp_dec; stb_o <= 1'b0; we_o <= 1'b0;

`define INITIATE_STACK_POP		cyc_type <= `CT_RDMEM; lock_o <= 1'b1; cyc_o <= 1'b1; stb_o <= 1'b1; adr_o <= sssp;
`define COMPLETE_STACK_POP		cyc_type <= `CT_PASSIVE; lock_o <= bus_locked; cyc_o <= 1'b0; stb_o <= 1'b0; sp <= sp_inc;
`define PAUSE_STACK_POP			cyc_type <= `CT_PASSIVE; stb_o <= 1'b0; sp <= sp_inc;
`define CONTINUE_STACK_POP		cyc_type <= `CT_RDMEM; stb_o <= 1'b1; adr_o <= sssp;


/*
Some modrm codes specify register-immediate or memory-immediate operations.
The operation to be performed is coded in the rrr field as only one register
spec (rm) is required.

80/81/83
	rrr   Operation
	---------------
	000 = ADD
	001 = OR
	010 = ADC
	011 = SBB
	100 = AND
	101 = SUB
	110 = XOR
	111 = CMP
FE/FF	
	000 = INC
	001 = DEC
	010 = CALL
	011 =
	100 =
	101 =
	110 =
	111 = 
F6/F7:
	000 = TEST
	001 = 
	010 = NOT
	011 = NEG
	100 = MUL
	101 = IMUL
	110 = DIV
	111 = IDIV
*/
`define ADDRESS_INACTIVE	20'hFFFFF
`define DATA_INACTIVE		8'hFF

// States
typedef enum logic [8:0] {
	IFETCH = 9'd1,
  IFETCH_ACK,
  XI_FETCH,
  XI_FETCH_ACK,
  REGFETCHA,
  DECODE,
  DECODER2,
  DECODER3,

  FETCH_VECTOR,
  FETCH_IMM8,
  FETCH_IMM8_ACK,
  FETCH_IMM16,
  FETCH_IMM16_ACK,
  FETCH_IMM16a,
  FETCH_IMM16a_ACK,

  MOV_I2BYTREG,

  FETCH_DISP8,
  FETCH_DISP16,
  FETCH_DISP16_ACK,
  FETCH_DISP16a,
  FETCH_DISP16a_ACK,
  FETCH_DISP16b,

  FETCH_OFFSET,
  FETCH_OFFSET1,
  FETCH_OFFSET2,
  FETCH_OFFSET3,
  FETCH_SEGMENT,
  FETCH_SEGMENT1,
  FETCH_SEGMENT2,
  FETCH_SEGMENT3,
  FETCH_STK_ADJ1,
  FETCH_STK_ADJ1_ACK,
  FETCH_STK_ADJ2,
  FETCH_STK_ADJ2_ACK,
  FETCH_DATA,
  FETCH_DATA1,

  BRANCH1,
  BRANCH2,
  BRANCH3,

  PUSHA,
  PUSHA1,
  POPA,
  POPA1,
  RET,
  RETF,
  RETF1,
  JMPF,

  CALLF,
  CALLF1,
  CALLF2,
  CALLF3,
  CALLF4,
  CALLF5,
  CALLF6,
  CALLF7,

  CALL,
  CALL1,
  CALL2,
  CALL3,

  PUSH,
  PUSH1,
  PUSH2,
  PUSH3,

  IRET,
  IRET1,
  IRET2,

  POP,
  POP1,
  POP2,
  POP3,

  CALL_IN,
  CALL_IN1,
  CALL_IN2,
  CALL_IN3,
  CALL_IN4,

  STOS,
  STOS1,
  STOS2,

  MOVS,
  MOVS1,
  MOVS2,
  MOVS3,
  MOVS4,
  MOVS5,
  MOVS6,
  MOVS7,

  WRITE_REG,

  EACALC,
  EACALC1,
  EACALC_DISP8,
  EACALC_DISP8_ACK,
  EACALC_DISP16,
  EACALC_DISP16_ACK,
  EACALC_DISP16a,
  EACALC_DISP16a_ACK,
  EXECUTE,

  INB,
  INB1,
  INB2,
  INB3,
  INW,
  INW1,
  INW2,
  INW3,
  INW4,
  INW5,

  OUTB,
  OUTB_NACK,
  OUTB1,
  OUTB1_NACK,
  OUTW,
  OUTW_NACK,
  OUTW1,
  OUTW1_NACK,
  OUTW2,
  OUTW2_NACK,
  FETCH_PORTNUMBER,

  INVALID_OPCODE,
  IRQ1,

  JUMP_VECTOR1,
  JUMP_VECTOR2,
  JUMP_VECTOR3,
  JUMP_VECTOR4,
  JUMP_VECTOR5,
  JUMP_VECTOR6,
  JUMP_VECTOR7,
  JUMP_VECTOR8,
  JUMP_VECTOR9,

  STORE_DATA,
  STORE_DATA1,
  STORE_DATA2,
  STORE_DATA3,

  INTO,
  FIRST,

  INTA0,
  INTA1,
  INTA2,
  INTA3,

  RETPOP,
  RETPOP_NACK,
  RETPOP1,
  RETPOP1_NACK,

  RETFPOP,
  RETFPOP1,
  RETFPOP2,
  RETFPOP3,
  RETFPOP4,
  RETFPOP5,
  RETFPOP6,
  RETFPOP7,
  RETFPOP8,

  XLAT_ACK,

  FETCH_DESC,
  FETCH_DESC1,
  FETCH_DESC2,
  FETCH_DESC3,
  FETCH_DESC4,
  FETCH_DESC5,

  INSB,
  INSB1,
  OUTSB,
  OUTSB1,

  SCASB,
  SCASB1,
  SCASW,
  SCASW1,
  SCASW2,

  CMPSW,
  CMPSW1,
  CMPSW2,
  CMPSW3,
  CMPSW4,
  CMPSW5,
  CMPSW6,
  CMPSW7,
  CMPSW8,

  LODS,
  LODS_NACK,
  LODS1,
  LODS1_NACK,

  INSW,
  INSW1,
  INSW2,
  INSW3,

  OUTSW,
  OUTSW1,
  OUTSW2,
  OUTSW3,

  CALL_FIN,
  CALL_FIN1,
  CALL_FIN2,
  CALL_FIN3,
  CALL_FIN4,

  DIVIDE1,
  DIVIDE1a,
  DIVIDE2,
  DIVIDE2a,
  DIVIDE3,

  INT,
  INT1,
  INT2,
  INT3,
  INT4,
  INT5,
  INT6,
  INT7,
  INT8,
  INT9,
  INT10,
  INT11,
  INT12,
  INT13,
  INT14,

  IRET3,
  IRET4,
  IRET5,
  IRET6,
  IRET7,
  IRET8,
  IRET9,
  IRET10,
  IRET11,
  IRET12,

  INSB2,
  OUTSB2,
  XCHG_MEM,

  CMPSB,
  CMPSB1,
  CMPSB2,
  CMPSB3,
  CMPSB4
} e_8088state;

endpackage
