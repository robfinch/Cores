// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rtf64-defines.sv
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================

`define R3A   8'h01
`define R2    8'h02
`define R3B   8'h03
`define ADD   8'h04
`define SUB   8'h05
`define SUBF  8'h05
`define MUL   8'h06
`define CMP   8'h07
`define CMP_CPY   3'd0
`define CMP_AND   3'd1
`define CMP_OR    3'd2
`define CMP_ANDCM 3'd3
`define CMP_ORCM  3'd4
`define AND   8'h08
`define OR    8'h09
`define EOR   8'h0A
`define BIT   8'h0B
`define SHIFT 8'h0C
`define SET   8'h0D
`define MULU  8'h0E
`define CSR   8'h0F
`define DIV   8'h10
`define DIVU  8'h11
`define DIVSU 8'h12
`define R2B   8'h13
`define MULFI 8'h15
`define MULSU 8'h16
`define PERM  8'h17
`define REM   8'h18
`define REMU  8'h19
`define BYTNDX  8'h1A
`define WYDNDX  8'h1B
`define EXT   8'h1C
`define DEP   8'h1D
`define DEPI  8'h1E
`define FFO   8'h1F
`define REMSU 8'h20
`define DIVR  8'h21
`define CHK   8'h22
`define SAND  8'h24
`define SOR   8'h25
`define SEQ   8'h26
`define SNE   8'h27
`define SLT   8'h28
`define SGE   8'h29
`define SLE   8'h2A
`define SGT   8'h2B
`define SLTU  8'h2C
`define SGEU  8'h2D
`define SLEU  8'h2E
`define SGTU  8'h2F
`define ADD5  8'h30
`define OR5   8'h31
`define ADD22 8'h32
`define ADD2R 8'h33
`define OR2R  8'h34
`define ADC2R 8'h35
`define GCSUB10 8'h36
`define GCSUB   8'h37
`define ADDUI 8'b0011100?
`define ANDUI 8'h0011101?
`define ORUI  8'h0011110?
`define AUIIP 8'h0011111?
`define JAL   8'h40
`define BLR   8'h40
`define JMP   8'h41
`define JSR   8'h42
`define RTS   8'h43
`define RTL   8'h44
`define RTE   8'h45
`define BEQ   8'h46
`define BNE   8'h47
`define BMI   8'h48
`define BLT   8'h48
`define BPL   8'h49
`define BGE   8'h49
`define BLE   8'h4A
`define BGT   8'h4B
`define BLTU  8'h4C
`define BGEU  8'h4D
`define BLEU  8'h4E
`define BGTU  8'h4F
`define BVS   8'h50
`define BVC   8'h51
`define BOD   8'h52
`define BEQI  8'h53
`define BPS   8'h54
`define BRA   8'h55
`define BEQZ  8'h56
`define BNEZ  8'h57
`define BBC		8'h58
`define BBS		8'h59
`define BCS   8'h4C
`define BCC   8'h4D
`define RTX   8'h5D
`define JSR18 8'h5E
`define BT    8'h5F
`define CI    8'h6?
`define GCSUB 8'h75
`define BRK   8'h78
`define NOP   8'h79
`define OSR2  8'h7A
`define CACHE   5'h02
`define PUSHQ   5'h08
`define POPQ    5'h09
`define PEEKQ   5'h0A
`define STATQ   5'h0B
`define SETKEY  5'h0C
`define GCCLR   5'h0D
`define REX     5'h10
`define PFI     5'h11
`define WFI     5'h12
`define MVMAP   5'h1C
`define MVSEG   5'h1D
`define TLBRW   5'h1E
`define MVCI    5'h1F
`define LDBS  8'h80
`define LDBUS 8'h81
`define LDWS  8'h82
`define LDWUS 8'h83
`define LDTS  8'h84   
`define LDTUS 8'h85
`define LDOS  8'h86
`define LDORS 8'h87
`define LDOT  8'h88
`define LEAS  8'h89
`define POP   8'h8A
`define PLDOS	8'h8B
`define FLDOS 8'h8E
`define UNLINK  8'h8F
`define LEA   8'h91
`define PLDO  8'h92
`define FLDO  8'h93
`define LDM   8'h97
`define LDB   8'h98
`define LDBU  8'h99
`define LDW   8'h9A
`define LDWU  8'h9B
`define LDT   8'h9C   
`define LDTU  8'h9D
`define LDO   8'h9E
`define LDOR  8'h9F
`define STBS    8'hA0
`define STWS    8'hA1
`define STTS    8'hA2
`define STOS    8'hA3
`define STOCS   8'hA4
`define STPTRS  8'hA5
`define STOTS   8'hA6
`define STOT    8'hA8
`define PUSHC   8'hA9
`define PUSH    8'hAA
`define FSTOS   8'hAB
`define PSTOS	  8'hAC
`define LINK    8'hAD
`define FSTO    8'hB2
`define PSTO    8'hB3
`define STM     8'hB7
`define STB     8'hB8
`define STW     8'hB9
`define STT     8'hBA
`define STO     8'hBB
`define STOC    8'hBC
`define STPTR   8'hBD

// Shift operations
`define ASL   4'h0
`define LSR   4'h1
`define ROL   4'h2
`define ROR   4'h3
`define ASR   4'h5
`define ASLX  4'h5
`define LSRX  4'h6
`define ASLI  4'h8
`define LSRI  4'h9
`define ROLI  4'hA
`define RORI  4'hB
`define ASRI  4'hC
`define ASLXI 4'hD
`define LSRXI 4'hE

// 1r operations
`define CNTLZR1 5'h00
`define CNTLOR1 5'h01
`define CNTPOPR1  5'h02
`define COMR1   5'h03
`define NOTR1   5'h04
`define NEGR1   5'h05
`define TST1    5'h0B

// 2r operations
`define ANDR2   5'h00
`define ORR2    5'h01
`define EORR2   5'h02
`define BMMR2   5'h03
`define ADDR2   5'h04
`define SUBR2   5'h05
`define MULR2   5'h06
`define CMPR2   5'h07
`define NANDR2  5'h08
`define NORR2   5'h09
`define ENORR2  5'h0A
`define BITR2   5'h0B
`define R1      5'h0C
`define MOV     5'h0D
`define MULUR2  5'h0E
`define MULHR2  5'h0F
`define DIVR2   5'h10
`define DIVUR2  5'h11
`define DIVSUR2 5'h12
`define REMR2   5'h13
`define REMUR2  5'h14
`define REMSUR2 5'h15
`define MULSUR2 5'h16
`define PERMR2  5'h17
`define PTRDIFR2  5'h18
`define DIFR2   5'h19
`define BYTNDX2  5'h1A
`define WYDNDX2  5'h1B
`define MULF    5'h1C
`define MULSUHR2 5'h1D
`define MULUHR2 5'h1E
`define RGFR2   5'h1F

`define CMPR2B  5'h14
`define CMPUR2B 5'h15
`define CHKR2B  5'h28

// 2r set operations
`define SEQR2   3'd0
`define SNER2   3'd1
`define SANDR2  3'd2
`define SORR2   3'd3
`define SLTR2   3'd4
`define SGER2   3'd5
`define SLTUR2  3'd6
`define SGEUR2  3'd7

// 3r operations
`define MINR3A 3'h0
`define MAXR3A 3'h1
`define MAJR3A 3'h2
`define MUXR3A 3'h3
`define ADDR3A 3'h4
`define SUBR3A 3'h5
`define FLIPR3A  3'h7
`define ANDR3B 3'h0
`define ORR3B  3'h1
`define EORR3B 3'h2
`define DEPR3B   3'h3
`define EXTR3B   3'h4
`define EXTUR3B  3'h5
`define BLENDR3B 3'h6
`define RGFR3B   3'h7

// 2r Loads
`define LDBX   5'd0
`define LDBUX  5'd1
`define LDWX   5'd2
`define LDWUX  5'd3
`define LDTX   5'd4
`define LDTUX  5'd5
`define LDOX   5'd6
`define LDORX  5'd7
`define LDOTX  5'd8
`define LEAX   5'd9
`define FLDOX	 5'd14

// 2r Stores
`define STBX    5'd0
`define STWX    5'd1
`define STTX    5'd2
`define STOX    5'd3
`define STOCX   5'd4
`define STPTRX  5'd5
`define STOTX   5'd8
`define FSTOX		5'd11

`define PFDP    8'hE1
`define POSIT   8'hE2
`define PST2    8'hE2
`define PMA     8'hE4
`define PMS     8'hE5
`define PNMA    8'hE6
`define PNMS    8'hE7

`define FLOAT   8'hF2
`define FLT2    8'hF2
`define FMA     8'hF4
`define FMS     8'hF5
`define FNMA    8'hF6
`define FNMS    8'hF7
// {FLT2} 2r
`define FLT1    5'h01
`define FMIN    5'h02
`define FMAX    5'h03
`define FADD    5'h04
`define FSUB    5'h05
`define FMUL    5'h08
`define FDIV    5'h09
`define FCMP    5'h10
`define FSEQ    5'h11
`define FSLT    5'h12
`define FSLE    5'h13
`define CPYSGN  5'h18
`define SGNINV  5'h19
`define SGNAND  5'h1A
`define SGNOR   5'h1B
`define SGNEOR  5'h1C
`define SGNENOR 5'h1D
// {FLT1} 1r
`define FMOV    5'h00
`define FTOI    5'h02
`define ITOF    5'h03
`define FCVT2I	5'h02
`define FCVT2F	5'h03
`define FSIGN   5'h06
`define FMAN    5'h07
`define FS2D		5'h09
`define FSTAT   5'h0C
`define FSQRT		5'h0D
`define ISNAN   5'h0E
`define FINITE  5'h0F
`define FD2S		5'h19
`define FCLASS	5'h1E
`define UNORD   5'h1F
// {PST2}
`define PST1    5'h01
`define PMIN    5'h02
`define PMAX    5'h03
`define PADD    5'h04
`define PSUB    5'h05
`define PMUL    5'h08
`define PDIV    5'h09
`define PSEQ    5'h11
`define PSLT    5'h12
`define PSLE    5'h13
// {PST1} 1r
`define PTOI    5'h02
`define ITOP    5'h03

`define LOAD    8'b100?????
`define STORE   8'b101?????
`define NOP_INSN  8'h79

`define OPCODE  7:0
`define FUNCT5  30:26
`define AMODE   30

`define FLT_BT  8'd55

