; Triple precision floating point routines for the 65816
; Based on code originally posted in
;
;Dr. Dobb's Journal, August 1976, pages 17-19.
;
;Floating Point Routines for the 6502
;
;by Roy Rankin, Department of Mechanical Engineering,
;   Stanford University, Stanford, CA 94305
;   (415) 497-1822;
;
;and
;
;   Steve Wozniak, Apple Computer Company
;   770 Welch Road, Suite 154
;   Palo Alto, CA  94304
;   (415) 326-4248
;
;
;    In the Exponent:
;    0000 Represents -32768
;          ...
;    7FFF Represents -1
;    8000 Represents 0
;    8001 Represents +1
;          ...
;    FFFF Represents +32767
;
;
;  Exponent          Two's Complement Mantissa
;  SEEEEEEEEEEEEEEE  SM.MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMM  MMMMMMMMMMMMMMMM  MMMMMMMMMMMMMMMM  MMMMMMMMMMMMMMMM
;         n                  n+2              n+4               n+6               n+8               n+10
;
SIGN	=4
X2		=6
M2		=8
X1		=18
M1		=20
EEE		=30
Z		=42
T		=54
SEXP	=66
INT		=78

;
		cpu		W65C816S
		ORG 	$D200
		MEM		16
		NDX		16
;
;     BASIC FLOATING POINT ROUTINES
;
ADD    	CLC         	; CLEAR CARRY
        LDX 	#8  	;  INDEX FOR 10-BYTE ADD
.ADD1  	LDA 	M1,X
        ADC 	M2,X    ; ADD A BYTE OF MANT2 TO MANT1
        STA 	M1,X
        DEX         	; ADVANCE INDEX TO NEXT MORE SIGNIF.BYTE
		DEX
        BPL 	.ADD1    ; LOOP UNTIL DONE.
        RTS         	; RETURN

MD1    	ASL 	SIGN    ; CLEAR LSB OF SIGN
        JSR 	ABSWAP  ; ABS VAL OF MANT1, THEN SWAP MANT2
ABSWAP 	BIT 	M1      ; MANT1 NEG?
        BPL 	ABSWP1  ; NO,SWAP WITH MANT2 AND RETURN
        JSR 	FCOMPL  ; YES, COMPLIMENT IT.
        INC 	SIGN    ; INCR SIGN, COMPLEMENTING LSB
ABSWP1 	SEC         	; SET CARRY FOR RETURN TO MUL/DIV
;
;     SWAP EXP/MANT1 WITH EXP/MANT2
;
SWAP	LDX		#12		; index for 12-byte swap
.SWAP1	STY		EEE-2,X
		LDA		X1-2,X
		LDY		X2-2,X
		STY		X1-2,X
		STA		X2-2,X
		DEX
		DEX
		BNE		.SWAP1
		RTS
;
;
;
;     CONVERT 64 BIT INTEGER IN M1(HIGH) TO M1+6(LOW) TO F.P.
;     RESULT IN EXP/MANT1.  EXP/MANT2 UNEFFECTED
;
;
		ALIGN	16
FLOAT	PHD				; save DPR
		LDA		#$400	; and set it to $400
		TCD
		LDA 	#$803E
        STA 	X1     ; SET EXPN TO 62 DEC
		STZ 	M1+8	; CLEAR LOW ORDER WORD
        BRA 	NORM   ; NORMALIZE RESULT
NORM1  	DEC 	X1     ; DECREMENT EXP1
        ASL 	M1+8
		ROL		M1+6
		ROL		M1+4
        ROL 	M1+2   ; SHIFT MANT1 (3 BYTES) LEFT
        ROL 	M1
NORM   	LDA 	M1     ; HIGH ORDER MANT1 BYTE
        ASL         	; UPPER TWO BITS UNEQUAL?
        EOR 	M1
        BMI 	.RTS1    ; YES,RETURN WITH MANT1 NORMALIZED
        LDA 	X1      ; EXP1 ZERO?
        BNE 	NORM1   ; NO, CONTINUE NORMALIZING
.RTS1	PLD				; get back DPR
		RTS         	; RETURN
;
;
;     EXP/MANT2-EXP/MANT1 RESULT IN EXP/MANT1
;
		ALIGN	16
FSUB	PHD
		LDA		#$400
		TCD
		JSR		FCOMPL	; complement mant1 clears carry unless zero
SWPALG	JSR		ALGNSW	; right shift mant1 or swap with mant2 on carry
		BRA		FADD1
;
;     ADD EXP/MANT1 AND EXP/MANT2 RESULT IN EXP/MANT1
;
		ALIGN	16
FADD	PHD
		LDA		#$400
		TCD
FADD1	LDA		X2		; If exponents are unequal, swap addends or align mantissas
		CMP		X1
		BNE		SWPALG
		JSR		ADD		; add aligned mantissas
ADDEND	BVC		NORM	; no overflow, normalize results
		BVS		RTLOG	; overflow: shift mant1 right, note carry is correct sign
ALGNSW	BCC		SWAP	; swap if carry clear, else shift right arith.
RTAR	LDA		M1		; Sign of MANT1 into carry for
		ASL				; right arith shift
RTLOG	INC		X1
		BEQ		OVFL
RTLOG1	LDX		#$EC	; Index for 10 word right shift
ROR1	LDA		#$8000
		BCS		ROR2
		ASL
ROR2	LSR		EEE+10,X
		ORA		EEE+10,X
		STA		EEE+10,X
		INX				; advance to next word of shift
		INX
		BNE		ROR1	; Loop until done
		PLD
		RTS	
;
;
;     EXP/MANT1 X EXP/MANT2 RESULT IN EXP/MANT1
;
		ALIGN	16
FMUL	PHD				; save direct page
		LDA		#$400	; set to $400
		TCD
		JSR		MD1		; ABS. val of Mant1, mant2
		ADC		X1		; ADD EXP1 TO EXP2 FOR PRODUCT EXPONENT
		JSR		MD2		; CHECK PRODUCT EXP AND PREPARE FOR MUL
		CLC
MUL1	JSR		RTLOG1	; MANT1 AND E RIGHT.(PRODUCT AND MPLIER)
		BCC		MUL2	; IF CARRY CLEAR, SKIP PARTIAL PRODUCT
		JSR		ADD		; ADD MULTIPLICAN TO PRODUCT
MUL2	DEY				; NEXT MUL ITERATION
		BPL		MUL1
MDEND	LSR 	SIGN   	; TEST SIGN (EVEN/ODD)
NORMX	BCC 	NORM   	; IF EXEN, NORMALIZE PRODUCT, ELSE COMPLEMENT
FCOMPL 	SEC         	; SET CARRY FOR SUBTRACT
		LDX		#10		; index for 10 byte subtraction
COMPL1 	LDA 	#0    	; CLEAR A
        SBC 	X1,X    ; SUBTRACT BYTE OF EXP1
        STA 	X1,X    ; RESTORE IT
        DEX         	; NEXT MORE SIGNIFICANT BYTE
		DEX
        BNE 	COMPL1  ; LOOP UNTIL DONE
        BRA 	ADDEND  ; NORMALIZE (OR SHIFT RIGHT IF OVERFLOW)
;
;
;     EXP/MANT2 / EXP/MANT1 RESULT IN EXP/MANT1
;
		ALIGN	16
FDIV   	PHD
		LDA		#$400
		TCD
		JSR 	MD1     ; TAKE ABS VAL OF MANT1, MANT2
		SBC 	X1      ; SUBTRACT EXP1 FROM EXP2
		JSR 	MD2     ; SAVE AS QUOTIENT EXP
DIV1   	SEC         	; SET CARRY FOR SUBTRACT
        LDX 	#8    	; INDEX FOR 10-BYTE INSTRUCTION
DIV2   	LDA 	M2,X
        SBC 	EEE,X     ; SUBTRACT A BYTE OF E FROM MANT2
        PHA         	; SAVE ON STACK
        DEX         	; NEXT MORE SIGNIF BYTE
		DEX
		BPL 	DIV2    ; LOOP UNTIL DONE
        LDX 	#$F6    ; INDEX FOR 10-BYTE CONDITIONAL MOVE
DIV3   	PLA         	; PULL A BYTE OF DIFFERENCE OFF STACK
        BCC 	DIV4    ; IF MANT2<E THEN DONT RESTORE MANT2
        STA 	M2+10,X
DIV4   	INX         	; NEXT LESS SIGNIF BYTE
		INX
		BNE 	DIV3    ; LOOP UNTIL DONE
		ROL		M1+8
		ROL		M1+6
        ROL 	M1+4
        ROL 	M1+2    ; ROLL QUOTIENT LEFT, CARRY INTO LSB
        ROL 	M1
        ASL 	M2+8
		ROL		M2+6
		ROL		M2+4
        ROL 	M2+2    ; SHIFT DIVIDEND LEFT
        ROL 	M2
        BCS 	OVFL    ; OVERFLOW IS DUE TO UNNORMALIZED DIVISOR
        DEY         	; NEXT DIVIDE ITERATION
        BNE 	DIV1    ; LOOP UNTIL DONE 47 ITERATIONS
        BRA 	MDEND   ; NORMALIZE QUOTIENT AND CORRECT SIGN
MD2    	STZ		M1+8
		STZ		M1+6
		STZ 	M1+4
        STZ 	M1+2    ; CLR MANT1 (10 BYTES) FOR MUL/DIV
        STZ 	M1
        BCS 	OVCHK   ; IF EXP CALC SET CARRY, CHECK FOR OVFL
        BMI 	MD3     ; IF NEG NO UNDERFLOW
        PLA         	; POP ONE
        PLA         	; RETURN LEVEL
        BRA 	NORMX   ; CLEAR X1 AND RETURN
MD3    	EOR 	#$8000	; COMPLIMENT SIGN BIT OF EXP
        STA 	X1      ; STORE IT
        LDY 	#$4F    ; COUNT FOR 80 MUL OR 79 DIV ITERATIONS
        RTS         	; RETURN
OVCHK  	BPL 	MD3     ; IF POS EXP THEN NO OVERFLOW
OVFL   	PLD
		BRK
;
;
;     CONVERT EXP/MANT1 TO INTEGER IN M1 (HIGH) AND M1+2(LOW)
;      EXP/MANT2 UNEFFECTED
;
		ALIGN	16
FIX		PHD
		LDA		#$400
		TCD
		BRA		.FIX1
.FIX2	JSR		RTAR		; shift mant1 right and increment exponent
.FIX1	LDA		X1
		CMP		#$803E		; adjust this constant (is exponent 62 ?)
		BNE		.FIX2
		PLD
		RTS

;                       ENDDr. Dobb's Journal, November/December 1976, page 57.

