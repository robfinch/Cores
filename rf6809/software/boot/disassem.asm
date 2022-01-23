; ============================================================================
;        __
;   \\__/ o\    (C) 2013-2022  Robert Finch, Waterloo
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@opencores.org
;       ||
;  
;
; BSD 3-Clause License
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;                                                                          
; ============================================================================
;
farflag	EQU		$15F
asmbuf	EQU		$160	; to $17F
CharOutVec	EQU		$800
CharInVec	EQU		$804

; Disassembler
;
;
DIRECT	EQU	1
LSREL		EQU	2
IMMB		EQU	3
SREL		EQU	4
NDX			EQU	5
EXT			EQU	6
IMMW		EQU	7
FAREXT	EQU	8
TFREXG	EQU	9

distbl1:
	; 00 to 0F
	fcb		"NEG ", DIRECT
	fcb		"    ", 0
	fcb		"    ", 0
	fcb		"COM ", DIRECT
	fcb		"LSR ", DIRECT
	fcb		"    ", 0
	fcb		"ROR ", DIRECT
	fcb		"ASR ", DIRECT
	fcb		"ASL ", DIRECT
	fcb		"ROL ", DIRECT
	fcb		"DEC ", DIRECT
	fcb		"    ", 0
	fcb		"INC ", DIRECT
	fcb		"TST ", DIRECT
	fcb		"JMP ", DIRECT
	fcb		"CLR ", DIRECT
	
	; 10 to 1F
	fcb		"    ", 0
	fcb		"    ", 0
	fcb		"NOP ", 0
	fcb		"SYNC", 0
	fcb		"    ", 0
	fcb		"FAR ", 0
	fcb		"LBRA", LSREL
	fcb		"LBSR", LSREL
	fcb		"    ", 0
	fcb		"DAA ", 0
	fcb		"ORCC", IMMB
	fcb		"    ", 0
	fcb		"ANDC", IMMB
	fcb		"SEX ", 0
	fcb		"EXG ", TFREXG
	fcb		"TFR ", TFREXG
	
	; 20 to 2F
	fcb		"BRA ", SREL
	fcb		"BRN ", SREL
	fcb		"BHI ", SREL
	fcb		"BLS ", SREL
	fcb		"BHS ", SREL
	fcb		"BLO ", SREL
	fcb		"BNE ", SREL
	fcb		"BEQ ", SREL
	fcb		"BVC ", SREL
	fcb		"BVS ", SREL
	fcb		"BPL ", SREL
	fcb		"BMI ", SREL
	fcb		"BGE ", SREL
	fcb		"BLT ", SREL
	fcb		"BGT ", SREL
	fcb		"BLE ", SREL
	
	; 30 to 3F
	fcb		"LEAX", NDX
	fcb		"LEAY", NDX
	fcb		"LEAS",	NDX
	fcb		"LEAU", NDX
	fcb		"PSHS", IMMB
	fcb		"PULS", IMMB
	fcb		"PSHU", IMMB
	fcb		"PULU", IMMB
	fcb		"RTF ", 0
	fcb		"RTS ", 0
	fcb		"ABX ", 0
	fcb		"RTI ", 0
	fcb		"CWAI", IMMB
	fcb		"MUL ", 0
	fcb		"    ", 0
	fcb		"SWI ", 0

	; 40 to 4F
	fcb		"NEGA", 0
	fcb		"    ", 0
	fcb	  "    ", 0
	fcb		"COMA", 0
	fcb		"LSRA", 0
	fcb		"    ", 0
	fcb		"RORA", 0
	fcb		"ASRA", 0
	fcb		"ASLA", 0
	fcb		"ROLA", 0
	fcb		"DECA", 0
	fcb		"    ", 0
	fcb		"INCA", 0
	fcb		"TSTA", 0
	fcb		"    ", 0
	fcb		"CLRA", 0
	
	; 50 to 5F
	fcb		"NEGB", 0
	fcb		"    ", 0
	fcb	  "    ", 0
	fcb		"COMB", 0
	fcb		"LSRB", 0
	fcb		"    ", 0
	fcb		"RORB", 0
	fcb		"ASRB", 0
	fcb		"ASLB", 0
	fcb		"ROLB", 0
	fcb		"DECB", 0
	fcb		"    ", 0
	fcb		"INCB", 0
	fcb		"TSTB", 0
	fcb		"    ", 0
	fcb		"CLRB", 0
	
	; 60 to 6F
	fcb		"NEG ", NDX
	fcb		"    ", 0
	fcb	  "    ", 0
	fcb		"COM ", NDX
	fcb		"LSR ", NDX
	fcb		"    ", 0
	fcb		"ROR ", NDX
	fcb		"ASR ", NDX
	fcb		"ASL ", NDX
	fcb		"ROL ", NDX
	fcb		"DEC ", NDX
	fcb		"    ", 0
	fcb		"INC ", NDX
	fcb		"TST ", NDX
	fcb		"JMP ", NDX
	fcb		"CLR ", NDX

	; 70 to 7F
	fcb		"NEG ", EXT
	fcb		"    ", 0
	fcb	  "    ", 0
	fcb		"COM ", EXT
	fcb		"LSR ", EXT
	fcb		"    ", 0
	fcb		"ROR ", EXT
	fcb		"ASR ", EXT
	fcb		"ASL ", EXT
	fcb		"ROL ", EXT
	fcb		"DEC ", EXT
	fcb		"    ", 0
	fcb		"INC ", EXT
	fcb		"TST ", EXT
	fcb		"JMP ", EXT
	fcb		"CLR ", EXT

	; 80 to 8F
	fcb		"SUBA", IMMB
	fcb		"CMPA",	IMMB
	fcb		"SBCA", IMMB
	fcb		"SUBD", IMMW
	fcb		"ANDA", IMMB
	fcb		"BITA", IMMB
	fcb		"LDA ", IMMB
	fcb		"    ", 0
	fcb		"EORA", IMMB
	fcb		"ADCA", IMMB
	fcb		"ORA ", IMMB
	fcb		"ADDA", IMMB
	fcb		"CMPX", IMMW
	fcb		"BSR ", SREL
	fcb		"LDX ", IMMW
	fcb		"JMF ", FAREXT
	
	; 90 to 9F
	fcb		"SUBA", DIRECT
	fcb		"CMPA",	DIRECT
	fcb		"SBCA", DIRECT
	fcb		"SUBD", DIRECT
	fcb		"ANDA", DIRECT
	fcb		"BITA", DIRECT
	fcb		"LDA ", DIRECT
	fcb		"STA ", DIRECT
	fcb		"EORA", DIRECT
	fcb		"ADCA", DIRECT
	fcb		"ORA ", DIRECT
	fcb		"ADDA", DIRECT
	fcb		"CMPX", DIRECT
	fcb		"JSR ", DIRECT
	fcb		"LDX ", DIRECT
	fcb		"STX ", DIRECT

	; A0 to AF
	fcb		"SUBA", NDX
	fcb		"CMPA",	NDX
	fcb		"SBCA", NDX
	fcb		"SUBD", NDX
	fcb		"ANDA", NDX
	fcb		"BITA", NDX
	fcb		"LDA ", NDX
	fcb		"STA ", NDX
	fcb		"EORA", NDX
	fcb		"ADCA", NDX
	fcb		"ORA ", NDX
	fcb		"ADDA", NDX
	fcb		"CMPX", NDX
	fcb		"JSR ", NDX
	fcb		"LDX ", NDX
	fcb		"STX ", NDX

	; B0 to BF
	fcb		"SUBA", EXT
	fcb		"CMPA",	EXT
	fcb		"SBCA", EXT
	fcb		"SUBD", EXT
	fcb		"ANDA", EXT
	fcb		"BITA", EXT
	fcb		"LDA ", EXT
	fcb		"STA ", EXT
	fcb		"EORA", EXT
	fcb		"ADCA", EXT
	fcb		"ORA ", EXT
	fcb		"ADDA", EXT
	fcb		"CMPX", EXT
	fcb		"JSR ", EXT
	fcb		"LDX ", EXT
	fcb		"STX ", EXT
	
	; C0 to CF
	fcb		"SUBB", IMMB
	fcb		"CMPB",	IMMB
	fcb		"SBCb", IMMB
	fcb		"ADDD", IMMW
	fcb		"ANDB", IMMB
	fcb		"BITB", IMMB
	fcb		"LDB ", IMMB
	fcb		"    ", 0
	fcb		"EORB", IMMB
	fcb		"ADCB", IMMB
	fcb		"ORB ", IMMB
	fcb		"ADDB", IMMB
	fcb		"LDD ", IMMW
	fcb		"    ", SREL
	fcb		"LDU ", IMMW
	fcb		"JSF ", FAREXT

	; D0 to DF
	fcb		"SUBB", DIRECT
	fcb		"CMPB",	DIRECT
	fcb		"SBCB", DIRECT
	fcb		"ADDD", DIRECT
	fcb		"ANDB", DIRECT
	fcb		"BITB", DIRECT
	fcb		"LDB ", DIRECT
	fcb		"STB ", DIRECT
	fcb		"EORB", DIRECT
	fcb		"ADCB", DIRECT
	fcb		"ORB ", DIRECT
	fcb		"ADDB", DIRECT
	fcb		"LDD ", DIRECT
	fcb		"STD ", DIRECT
	fcb		"LDU ", DIRECT
	fcb		"STU ", DIRECT

	; E0 to EF	
	fcb		"SUBB", NDX
	fcb		"CMPB",	NDX
	fcb		"SBCB", NDX
	fcb		"ADDD", NDX
	fcb		"ANDB", NDX
	fcb		"BITB", NDX
	fcb		"LDB ", NDX
	fcb		"STB ", NDX
	fcb		"EORB", NDX
	fcb		"ADCB", NDX
	fcb		"ORB ", NDX
	fcb		"ADDB", NDX
	fcb		"LDD ", NDX
	fcb		"STD ", NDX
	fcb		"LDU ", NDX
	fcb		"STU ", NDX

	; F0 to FF
	fcb		"SUBB", EXT
	fcb		"CMPB",	EXT
	fcb		"SBCB", EXT
	fcb		"ADDD", EXT
	fcb		"ANDB", EXT
	fcb		"BITB", EXT
	fcb		"LDB ", EXT
	fcb		"STB ", EXT
	fcb		"EORB", EXT
	fcb		"ADCB", EXT
	fcb		"ORB ", EXT
	fcb		"ADDB", EXT
	fcb		"LDD ", EXT
	fcb		"STD ", EXT
	fcb		"LDU ", EXT
	fcb		"STU ", EXT

	; 120 to 12F
distbl2:
	fcb		"LBRA"
	fcb		"LBRN"
	fcb		"LBHI"
	fcb		"LBLS"
	fcb		"LBHS"
	fcb		"LBLO"
	fcb		"LBNE"
	fcb		"LBEQ"
	fcb		"LBVC"
	fcb		"LBVS"
	fcb		"LBPL"
	fcb		"LBMI"
	fcb		"LBGE"
	fcb		"LBLT"
	fcb		"LBGT"
	fcb		"LBLE"
	
distbl3:
	fcb		$13F
	fcb		$183
	fcb		$18C
	fcb		$18E
	fcb		$193
	fcb		$19C
	fcb		$19E
	fcb		$19F
	fcb		$1A3
	fcb		$1AC
	fcb		$1AE
	fcb		$1AF
	fcb		$1B3
	fcb		$1BC
	fcb		$1BE
	fcb		$1BF
	fcb		$1CE
	fcb		$1DE
	fcb		$1DF
	fcb		$1EE
	fcb		$1EF
	fcb		$1FE
	fcb		$1FF
	fcb		$23F
	fcb		$283
	fcb		$28C
	fcb		$293
	fcb		$29C
	fcb		$2A3
	fcb		$2AC
	fcb		$2B3
	fcb		$2BC

distbl4:	
	fcb		"SWI2", 0
	fcb		"CMPD", IMMW
	fcb		"CMPY", IMMW
	fcb		"LDY ", IMMW
	fcb		"CMPD", DIRECT
	fcb		"CMPY", DIRECT	
	fcb		"LDY ", DIRECT
	fcb		"STY ", DIRECT
	fcb		"CMPD", NDX
	fcb		"CMPY", NDX
	fcb		"LDY ", NDX
	fcb		"STY ", NDX
	fcb		"CMPD", EXT
	fcb		"CMPY", EXT
	fcb		"LDY ", EXT
	fcb		"STY ", EXT
	fcb		"LDS ", IMMW
	fcb		"LDS ", DIRECT
	fcb		"STS ", DIRECT
	fcb		"LDS ", NDX
	fcb		"STS ", NDX
	fcb		"LDS ", EXT
	fcb		"STS ", EXT
	fcb		"SWI3", 0
	fcb		"CMPU", IMMW
	fcb		"CMPS", IMMW
	fcb		"CMPU", DIRECT
	fcb		"CMPS", DIRECT
	fcb		"CMPU", NDX
	fcb		"CMPS", NDX
	fcb		"CMPU", EXT
	fcb		"CMPS", EXT

disassem:
	clr		farflag
	swi
	fcb		MF_GetRange
	swi
	fcb		MF_CRLF
	ldy		mon_r1+2
disLoop1:
	tfr		y,d
	swi
	fcb		MF_DisplayWordAsHex
	ldb		#' '
	swi
	fcb		MF_OUTCH
	ldb		,y+
	bitb	#$300
	lbne	dis1
	andb	#$FF			; mask off extra bits
	cmpb	#$15
	bne		dis20
	stb		farflag
	bra		disLoop1
dis20:
	ldx		#distbl1
dis23:
	lda		#5
	mul
	abx
	ldb		,x+
	swi
	fcb		MF_OUTCH
	ldb		,x+
	swi
	fcb		MF_OUTCH
	ldb		,x+
	swi
	fcb		MF_OUTCH
	ldb		,x+
	swi
	fcb		MF_OUTCH
	ldb		#' '
	swi
	fcb		MF_OUTCH
	ldb		,x+
	lbeq	disNextLine
	cmpb	#DIRECT
	bne		disNotDirect
	ldb		,y+
	swi
	fcb		MF_DisplayByteAsHex
	lbra	disNextLine
disNotDirect:
	cmpb	#LSREL
	bne		disNotLRel
dis21:
	ldd		,y++
dis2:
	leax	d,y
	tfr		x,d
	swi
	fcb		MF_DisplayWordAsHex
	lbra	disNextLine
disNotLRel:
	cmpb	#SREL
	bne		disNotRel
	ldb		,y+
	clra
	bra		dis2
disNotRel:
	cmpb	#NDX
	bne		disNotNdx
	ldb		,y+
	bitb	#$800
	bne		disNot9			; test for offset 9 mode
	pshs	b
	andb	#$1FF				; mask to offset bits
	clra							;
	bitb	#$100				; test for negative offset
	beq		dis3
	deca							; sign extend offset
	orb		#$E00
dis3:
	swi
	fcb		MF_DisplayWordAsHex
	ldb		#','
	swi
	fcb		MF_OUTCH
	puls	b
	bsr		disNdxReg
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNot9:
	pshs	b
	bitb	#$100			; check if indirect
	beq		dis4
	ldb		#'['
	swi
	fcb		MF_OUTCH
dis4:
	ldb		,s				; get back b
	andb	#15
	bne		disNotRplus
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis5
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis5:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	swi
	fcb		MF_OUTCH
	ldb		#'+'
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotRplus:
	cmpb	#1
	bne		disNotRplusplus	
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis6
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis6:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	swi
	fcb		MF_OUTCH
	ldb		#'+'
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotRplusplus:
	cmpb	#2
	bne		disNotRminus
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis7
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis7:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	swi
	fcb		MF_OUTCH
	ldb		#'-'
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotRminus:
	cmpb	#3
	bne		disNotRminusminus
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis8
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis8:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	swi
	fcb		MF_OUTCH
	ldb		#'-'
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotRminusminus:
	cmpb	#4
	bne		disNotR
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis9
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis9:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotR:
	cmpb	#5
	bne		disNotBOffs
	ldb		#'B'
	swi
	fcb		MF_OUTCH
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis10
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis10:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	swi
	fcb		MF_OUTCH
	ldb		#'-'
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotBOffs:
	cmpb	#6
	bne		disNotAOffs
	ldb		#'A'
	swi
	fcb		MF_OUTCH
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis11
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis11:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	swi
	fcb		MF_OUTCH
	ldb		#'-'
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotAOffs:
	cmpb	#8
	bne		disNotBO
	ldb		,y+
	sex
	swi
	fcb		MF_DisplayWordAsHex
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis12
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis12:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	swi
	fcb		MF_OUTCH
	ldb		#'-'
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotBO:
	cmpb	#9
	bne		disNotWO
	ldd		,y++
	swi
	fcb		MF_DisplayWordAsHex
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis13
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis13:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	swi
	fcb		MF_OUTCH
	ldb		#'-'
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotWO:
	cmpb	#10
	bne		disNotTO
	ldb		,y++
	swi
	fcb		MF_DisplayByteAsHex
	ldd		,y++
	swi
	fcb		MF_DisplayWordAsHex
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis14
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis14:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	swi
	fcb		MF_OUTCH
	ldb		#'-'
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotTO:
	cmpb	#11
	bne		disNotDOffs
	ldb		#'D'
	swi
	fcb		MF_OUTCH
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis15
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis15:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	swi
	fcb		MF_OUTCH
	ldb		#'-'
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotDOffs:
	cmpb	#12
	bne		disNotPBO
	ldb		,y+
	sex
	swi
	fcb		MF_DisplayWordAsHex
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis16
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis16:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	ldb		#'P'
	swi
	fcb		MF_OUTCH
	ldb		#'C'
	swi
	fcb		MF_OUTCH
	ldb		#'-'
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotPBO:
	cmpb	#13
	bne		disNotPWO	
	ldd		,y++
	swi
	fcb		MF_DisplayWordAsHex
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis17
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis17:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	ldb		#'P'
	swi
	fcb		MF_OUTCH
	ldb		#'C'
	swi
	fcb		MF_OUTCH
	ldb		#'-'
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotPWO:
	cmpb	#14
	bne		disNotPTO
	ldb		,y+
	swi
	fcb		MF_DisplayByteAsHex
	ldd		,y++
	swi
	fcb		MF_DisplayWordAsHex
	ldb		,s
	bitb	#$80			; outer indexed?
	beq		dis18
	ldb		#']'
	swi
	fcb		MF_OUTCH
dis18:
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	bsr		disNdxReg
	ldb		#'P'
	swi
	fcb		MF_OUTCH
	ldb		#'C'
	swi
	fcb		MF_OUTCH
	ldb		#'-'
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	puls	b
	bitb	#$100
	lbeq	disNextLine
	bitb	#$80
	lbne	disNextLine
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotPTO:
	ldb		#'['
	swi
	fcb		MF_OUTCH
	ldd		,y++
	swi
	fcb		MF_DisplayWordAsHex
	ldb		#']'
	swi
	fcb		MF_OUTCH
	lbra	disNextLine
disNotNdx:
	cmpb	#EXT
	bne		disNotExt
	tst		farflag
	beq		dis30
	ldb		,y++
	swi
	fcb		MF_DisplayByteAsHex
dis30:
	ldd		,y++
	swi
	fcb		MF_DisplayWordAsHex
	clr		farflag
	lbra	disNextLine
disNotExt:
	cmpb	#IMMB
	bne		disNotIMMB
	ldb		#'#'
	swi
	fcb		MF_OUTCH
	ldb		,y+
	swi
	fcb		MF_DisplayByteAsHex
	lbra	disNextLine
disNotIMMB:
	cmpb	#IMMW
	bne		disNotIMMW
	ldb		#'#'
	swi
	fcb		MF_OUTCH
	ldd		,y++
	swi
	fcb		MF_DisplayWordAsHex
	bra		disNextLine
disNotIMMW:
	cmpb	#TFREXG
	bne		disNotTfr
	ldb		,y+
	bsr		disTfrExg
	bra		disNextLine
disNotTfr:
dis1:
	cmpb	#$121
	blo		dis19
	cmpb	#$12F
	bhi		dis19
	andb	#$FF
	ldx		#distbl2
	aslb
	aslb
	abx
	ldb		,x+
	swi
	fcb		MF_OUTCH
	ldb		,x+
	swi
	fcb		MF_OUTCH
	ldb		,x+
	swi
	fcb		MF_OUTCH
	ldb		,x+
	swi
	fcb		MF_OUTCH
	ldb		#' '
	swi
	fcb		MF_OUTCH
	lbra	dis21
dis19:
	ldx		#0
dis24:
	cmpb	distbl3,x
	bne		dis25
	ldx		#distbl4
	lbra	dis23
dis25:
	inx
	cmpx	#31
	blo		dis24
	ldb		#'?'
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	swi
	fcb		MF_OUTCH
	bra		disNextLine
disNextLine:
	clr		farflag
	swi
	fcb		MF_CRLF
	cmpy	mon_r2+2
	lblo	disLoop1
disJmpMon:
	swi
	fcb		MF_Monitor
	bra		disJmpMon

disNdxRegs:
	fcb		'X','Y','S','U'
disTfrRegs:
	fcb		"D X Y U S PC    A B CCDP        "

disNdxReg:
	andb	#$600
	rolb
	rolb
	rolb
	rolb
	clra
	pshs	u
	tfr		d,u
	lda		disNdxRegs,u
	puls	u
	exg		a,b
	rts

disTfrReg:
	pshs	b,x
	ldx		#disTfrRegs
	aslb
	lda		b,x
	exg		a,b
	swi
	fcb		MF_OUTCH
	exg		a,b
	inx
	ldb		b,x
	cmpb	#' '
	beq		disTfr1
	swi
	fcb		MF_OUTCH
disTfr1:
	puls	b,x,pc
	
disTfrExg:
	pshs	b
	rolb
	rolb
	rolb
	rolb
	andb	#15
	bsr		disTfrReg
	ldb		#','
	swi
	fcb		MF_OUTCH
	ldb		,s
	andb	#15
	bsr		disTfrReg
	puls	b,pc

ASMO:
	pshs	d
	ldd		#ASMOUTCH
	std		CharOutVec
	puls	d,pc

ASMOO:
	pshs	d
''	ldd		#DisplayChar
	std		CharOutVec
	puls	d,pc

ASMOUTCH:
	stb		,u+
	rts

DumpAsmbuf:
	ldu		#asmbuf
dab2:
	ldb		,u+
	beq		dab1
	swi
	fcb		MF_OUTCH
	bra		dab2
dab1:
	rts
