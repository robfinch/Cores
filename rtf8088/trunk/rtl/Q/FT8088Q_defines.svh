// ============================================================================
//  8088 Compatible CPU.
//
//
//  2009,2010  Robert Finch
//  robfinch[remove]@FPGAfield.ca
//  Stratford
//
//
//
//  This source code is available for evaluation and validation purposes
//  only. This copyright statement and disclaimer must remain present in
//  the file.
//
//	NO WARRANTY.
//  THIS Work, IS PROVIDEDED "AS IS" WITH NO WARRANTIES OF ANY KIND, WHETHER
//  EXPRESS OR IMPLIED. The user must assume the entire risk of using the
//  Work.
//
//  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY
//  INCIDENTAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES WHATSOEVER RELATING TO
//  THE USE OF THIS WORK, OR YOUR RELATIONSHIP WITH THE AUTHOR.
//
//  IN ADDITION, IN NO EVENT DOES THE AUTHOR AUTHORIZE YOU TO USE THE WORK
//  IN APPLICATIONS OR SYSTEMS WHERE THE WORK'S FAILURE TO PERFORM CAN
//  REASONABLY BE EXPECTED TO RESULT IN A SIGNIFICANT PHYSICAL INJURY, OR IN
//  LOSS OF LIFE. ANY SUCH USE BY YOU IS ENTIRELY AT YOUR OWN RISK, AND YOU
//  AGREE TO HOLD THE AUTHOR AND CONTRIBUTORS HARMLESS FROM ANY CLAIMS OR
//  LOSSES RELATING TO SUCH UNAUTHORIZED USE.
//
//
//  Verilog 
//  Webpack 9.2i xc3s1000 4-ft256
//  2550 slices / 4900 LUTs / 61 MHz
//  650 ff's / 2 MULTs
//
// ============================================================================

//`define BYTES_ONLY	1'b1

//`define BIG_SEGS
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

`define TEST        8'b1000010?
`define ALU_I2R8	8'h80
`define ALU_I2R16	8'h81
`define MOV_RR8		8'h88
`define MOV_RR16	8'h89
`define MOV_MR8		8'h8A
`define MOV_MR16	8'h8B
`define MOV_S2R		8'h8C
`define LEA			8'h8D
`define MOV_R2S		8'h8E

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
`define IMUL	8'b1111011?
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
	101 =
	110 = 
	111 = 
*/
`define ADDRESS_INACTIVE	20'hFFFFF
`define DATA_INACTIVE		8'hFF

module wb8088(rst_i, clk_i, nmi_i, irq_i, busy_i, inta_o, lock_o, mio_o, cyc_o, stb_o, ack_i, we_o, adr_o, dat_i, dat_o);
// States

