Cvaral		= $95		; current var address low byte
Cvarah		= Cvaral+1	; current var address high byte
numexp		= $A8		; string to float number exponent count
expcnt		= $A9		; string to float exponent count
Sendl			= $BA	; BASIC pointer temp low byte
Sendh			= $BB	; BASIC pointer temp low byte

Decss		= $3C0		; number to decimal string start
Decssp1		= Decss+1	; number to decimal string start
FP_ADD		EQU		1
FP_MUL		EQU		3
FP_DIV		EQU		4
FP_NEG		EQU		16
FP_CMDREG	EQU		$FEA20F
FAC1		EQU		$FEA200
FAC1_5		EQU		$FEA200
FAC1_4		EQU		$FEA202
FAC1_3		EQU		$FEA204
FAC1_2		EQU		$FEA206
FAC1_1		EQU		$FEA208
FAC1_msw	EQU		$FEA208
FAC1_e		EQU		$FEA20A
FAC2		EQU		$FEA210

; convert FAC1 to ASCII string result in (AY)
; not any more, moved scratchpad to page 0

LAB_296E
	LDY	#$01			; set index = 1
	BIT	FAC1_msw		; test FAC1 sign (b15)
	BPL	.0002		; branch if +ve
	LDA	#$2D			; else character = "-"
	STA	Decss,Y		; save leading character (" " or "-")
	LDA	#FP_NEG		; make the FAC positive
	JSR	FPCommandWait
	BRA	.0001
.0002:
	LDA	#$20			; character = " " (assume +ve)
	STA	Decss,Y
.0001:
	STY	Sendl			; save index
	INY				; increment index
	LDX	FAC1_e		; get FAC1 exponent
	BNE	LAB_2989		; branch if FAC1<>0

					; exponent was $00 so FAC1 is 0
	LDA	#'0'			; set character = "0"
	JMP	LAB_2A89		; save last character, [EOT] and exit

					; FAC1 is some non zero value
LAB_2989
	LDA	#$00			; clear (number exponent count)
	CPX	#$8001			; compare FAC1 exponent with $8001 (>1.00000)

	BCS	LAB_299A		; branch if FAC1=>1

					; FAC1<1
	PEA	A_MILLION		; multiply FAC * 1,000,000
	JSR	LOAD_FAC2		; do convert AY, FCA1*(AY)
	PLA					; get rid of parameter
	JSR	FP_MUL
	LDA	#$FFFA			; set number exponent count (-6)
LAB_299A
	STA	numexp		; save number exponent count
LAB_299C
	PEA	MAX_BEFORE_SCI	; set pointer low byte to 999999.4375 (max before sci note)
	JSR	LOAD_FAC2		; compare FAC1 with (AY)
	LDA FP_CMDREG
	BIT	#$08			; test equals bit
	BNE	LAB_29C3		; exit if FAC1 = (AY)
	BIT	#$04			; test greater than bit
	BNE	LAB_29B9		; go do /10 if FAC1 > (AY)

					; FAC1 < (AY)
LAB_29A7
	PEA CONST_9375		; set pointer to 99999.9375
	JSR	LOAD_FAC2		; compare FAC1 with (AY)
	LDA FP_CMDREG
	BIT #$08
	BNE	LAB_29B2		; branch if FAC1 = (AY) (allow decimal places)
	BIT #$04
	BNE	LAB_29C0		; branch if FAC1 > (AY) (no decimal places)

					; FAC1 <= (AY)
LAB_29B2
	JSR	MultiplyByTen	; multiply by 10
	DEC	numexp		; decrement number exponent count
	BRA	LAB_29A7		; go test again (branch always)

LAB_29B9
	JSR	DivideByTen		; divide by 10
	INC	numexp		; increment number exponent count
	BRA	LAB_299C		; go test again (branch always)

; now we have just the digits to do

LAB_29C0
	JSR	AddPoint5		; add 0.5 to FAC1 (round FAC1)
LAB_29C3
	JSR	FloatToFixed	; convert FAC1 floating-to-fixed
	LDX	#$01			; set default digits before dp = 1
	LDA	numexp		; get number exponent count
	CLC				; clear carry for add
	ADC	#$07			; up to 6 digits before point
	BMI	LAB_29D8		; if -ve then 1 digit before dp

	CMP	#$08			; A>=8 if n>=1E6
	BCS	LAB_29D9		; branch if >= $08

					; carry is clear
	ADC	#$FFFF			; take 1 from digit count
	TAX				; copy to A
	LDA	#$02			;.set exponent adjust

LAB_29D8
	SEC				; set carry for subtract
LAB_29D9
	SBC	#$02			; -2
	STA	expcnt		;.save exponent adjust
	STX	numexp		; save digits before dp count
	TXA				; copy to A
	BEQ	LAB_29E4		; branch if no digits before dp

	BPL	LAB_29F7		; branch if digits before dp

LAB_29E4
	LDY	Sendl			; get output string index
	LDA	#$2E			; character "."
	INY				; increment index
	STA	Decss,Y		; save to output string
	TXA				;.
	BEQ	LAB_29F5		;.

	LDA	#'0'			; character "0"
	INY				; increment index
	STA	Decss,Y		; save to output string
LAB_29F5
	STY	Sendl			; save output string index
LAB_29F7
	LDY	#$00			; clear index (point to 100,000)
	LDX	#$80			; 
LAB_29FB
	CLC
	LDA FAC1_5
	ADC LAB_2A9A+8,Y
	STA FAC1_5
	LDA FAC1_4
	ADC LAB_2A9A+6,Y
	STA FAC1_4
	LDA FAC1_3
	ADC LAB_2A9A+4,Y
	STA FAC1_3
	LDA FAC1_2
	ADC LAB_2A9A+2,Y
	STA FAC1_2
	LDA	FAC1_1
	ADC LAC_2A9A,Y
	STA FAC1_1
	INX				; 
	BCS	LAB_2A18		; 

	BPL	LAB_29FB		; not -ve so try again

	BMI	LAB_2A1A		; 

LAB_2A18
	BMI	LAB_29FB		; 

LAB_2A1A
	TXA				; 
	BCC	LAB_2A21		; 

	EOR	#$FFFF			; 
	ADC	#$000A			; 
LAB_2A21
	ADC	#'0'-1		; add "0"-1 to result
	PHA
	TYA				; increment index ..
	CLC				; .. to next less ..
	ADC	#12			; .. power of ten
	TAY
	PLA
	STY	Cvaral		; save as current var address low byte
	LDY	Sendl			; get output string index
	INY				; increment output string index
	TAX				; copy character to X
	AND	#$7F			; mask out top bit
	STA	Decss,Y		; save to output string
	DEC	numexp		; decrement # of characters before the dp
	BNE	LAB_2A3B		; branch if still characters to do

					; else output the point
	LDA	#$2E			; character "."
	INY				; increment output string index
	STA	Decss,Y		; save to output string
LAB_2A3B
	STY	Sendl			; save output string index
	LDY	Cvaral		; get current var address low byte
	TXA				; get character back
	EOR	#$FF			; 
	AND	#$80			; 
	TAX				; 
	CPY	#$48			; compare index with max
	BNE	LAB_29FB		; loop if not max

					; now remove trailing zeroes
	LDY	Sendl			; get output string index
LAB_2A4B
	LDA	Decss,Y		; get character from output string
	DEY				; decrement output string index
	CMP	#'0'			; compare with "0"
	BEQ	LAB_2A4B		; loop until non "0" character found

	CMP	#'.'			; compare with "."
	BEQ	LAB_2A58		; branch if was dp

					; restore last character
	INY				; increment output string index
LAB_2A58
	LDA	#$2B			; character "+"
	LDX	expcnt		; get exponent count
	BEQ	LAB_2A8C		; if zero go set null terminator and exit

					; exponent isn't zero so write exponent
	BPL	LAB_2A68		; branch if exponent count +ve

	LDA	#$00			; clear A
	SEC				; set carry for subtract
	SBC	expcnt		; subtract exponent count adjust (convert -ve to +ve)
	TAX				; copy exponent count to X
	LDA	#'-'			; character "-"
LAB_2A68
	STA	Decss+2,Y		; save to output string
	LDA	#$45			; character "E"
	STA	Decss+1,Y		; save exponent sign to output string
	TXA				; get exponent count back
	LDX	#'0'-1		; one less than "0" character
	SEC				; set carry for subtract
LAB_2A74
	INX				; increment 10's character
	SBC	#$0A			;.subtract 10 from exponent count
	BCS	LAB_2A74		; loop while still >= 0

	ADC	#':'			; add character ":" ($30+$0A, result is 10 less that value)
	STA	Decss+4,Y		; save to output string
	TXA				; copy 10's character
	STA	Decss+3,Y		; save to output string
	LDA	#$00			; set null terminator
	STA	Decss+5,Y		; save to output string
	BRA	LAB_2A91		; go set string pointer (AY) and exit (branch always)

LAB_2A89
	STA	Decss,Y		; save last character to output string

					; set null terminator and exit
LAB_2A8C
	LDA	#$00			; set null terminator
	STA	Decss+1,Y		; save after last character

LAB_2A91
;	LDA	#<Decssp1		; set result string low pointer
;	LDY	#>Decssp1		; set result string high pointer
	RTS

LAB_25FB:
	LDA		#FP_SWAP
	JSR		FPCommandWait
	LDY		#0
	LDX		#0
.0002:
	LDA		(3,SP),Y
	STA		FAC1,X
	INY
	INY
	INX
	INX
	CPX		#12
	BNE		.0002
	LDA		#FP_FIX2FLT
	JSR		FPCommandWait
FMUL:
	LDA		#FP_MUL
	JMP		FPcommandWait
	
LOAD_FAC2:
	LDY		#0
	LDX		#0
.0002:
	LDA		(3,SP),Y
	STA		FAC2,X
	INY
	INY
	INX
	INX
	CPX		#12
	BNE		.0002
	RTS
	
FloatToFixed:
	LDA		#FP_FLT2FIX
	JMP		FPCommandWait
	
AddPoint5:
	PEA		CONST_POINT5
	JSR		LOAD_FAC2
	PLA
	LDA		#FP_ADD
	JMP		FPCommandWait
	
MultiplyByTen:
	PEA		TEN_AS_FLOAT
	JSR		LOAD_FAC2
	PLA
	LDA		#FP_MUL
	JMP		FPCommandWait
	
DivideByTen:
	PEA		TEN_AS_FLOAT
	JSR		LOAD_FAC2
	PLA
	JSR		SwapFACs
	LDA		#FP_DIV
	JMP		FPCommandWait
	
SwapFACs:
	LDA		#FP_SWAP

; Issue a command to the FP unit and wait for it to complete
;
FPCommandWait:
	STA		FP_CMDREG
.0001:
	LDA		FP_CMDREG
	BIT		#$80
	BNE		.0001
	RTS

; 1,000,000 as a fixed point number
;
A_MILLON:	; $F4240
	dw		$0000
	dw		$4240
	dw		$000F
	dW		$0000
	dw		$0000
	dw		$0000

; The constant 999999.4375 as hex
; 01.11_1010_0001_0001_1111_1011_1000_00000000000000000000000000
MAX_BEFORE_SCI:
	dw  $0000
	dw  $0000
	dw	$0000
	dw	$FB80
	dw	$7A11
	dw	$8013

TEN_AS_FLOAT:
	dw	$0000
	dw	$0000
	dw	$0000
	dw	$0000
	dw	$5000
	dw	$8003

; 99999.9375
; 01.10_0001_1010_0111_1111_1100_000000000000000000000000000000
;
CONST_9375:
	dw	$0000
	dw	$0000
	dw	$0000
	dw	$FC00
	dw	$61A7
	dw	$8010

CONST_POINT5:
	dw	$0000
	dw	$0000
	dw	$0000
	dw	$0000
	dw	$4000
	dw	$7FFF

; This table is used in converting numbers to ASCII.

LAB_2A9A
LAB_2A9B = LAB_2A9A+1
LAB_2A9C = LAB_2A9B+1
;	.word	$FFFF,$F21F,$494C,$589C,$0000
;	.word	$0000,$0163,$4578,$5D8A,$0000
;	.word	$FFFF,$FFDC,$790D,$903F,$0000
;	.word	$0000,$0003,$8D7E,$A4C6,$8000
;	.word	$FFFF,$FFFF,$A50C,$EF85,$C000
;	.word	$0000,$0000,$0918,$4E72,$A000
;	.word	$FFFF,$FFFF,$FF17,$2B5A,$F000
;	.word	$0000,$0000,$0017,$4876,$E800
;	.word	$FFFF,$FFFF,$FFFD,$ABF4,$1C00
;	.word	$0000,$0000,$0000,$3B9A,$CA00
;	.word	$FFFF,$FFFF,$FFFF,$FF67,$6980
;	.word	$0000,$0000,$0000,$05F5,$E100		; 100000000
;	.word	$FFFF,$FFFF,$FFFF,$FF67,$6980		; -10000000
;	.word   $0000,$0000,$0000,$000F,$4240		; 1000000
	.word	$FFFF,$FFFF,$FFFF,$FFFE,$7960		; -100000
	.word	$0000,$0000,$0000,$0000,$2710		; 10000
	.word	$FFFF,$FFFF,$FFFF,$FFFF,$FC18		; -1000
	.word	$0000,$0000,$0000,$0000,$0064		; 100
	.word	$FFFF,$FFFF,$FFFF,$FFFF,$FFF6		; -10
	.word	$0000,$0000,$0000,$0000,$0001		; 1
