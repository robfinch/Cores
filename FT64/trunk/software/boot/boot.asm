;
LEDS	equ		$FFDC0600

	code
	org		$FFFC0000
	jmp		brkrout
	org		$FFFC0100
start:
	ldi		r31,#$7FF8		; set stack pointer
	ldi		r1,#$12345678
	sw		r1,$400
	sw		r1,$800
	call	calltest
	; From Wikipedia
	; inst. 123 should execute in parallel with 456 due to 
	; renaming
start4:
	lw		r1,$400		; 1
	add		r1,r1,#2	; 2
	sw		r1,$408		; 3
	lw		r1,$800		; 4
	add		r1,r1,#4	; 5
	sw		r1,$808		; 6
;	bra		start4

	ldi		r31,#$7FF8		; set stack pointer
	ldi		r1,#$AAAA5555	; pick some data to write
	ldi		r3,#0
	ldi		r4,#start1
start1:
	shr		r2,r1,#12
	sh		r2,$FFDC0600	; write to LEDs
	add		r1,r1,#1
	add		r3,r3,#1
	cmp		r2,r3,#10	; stop after a few cycles
	bne		r2,r0,r4
	jal		r29,clearTxtScreen
start3:
	bra		start3

brkrout:
	rti

calltest:
	lw		r1,$400		; 1
	add		r1,r1,#2	; 2
	sw		r1,$400		; 3
	ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
clearTxtScreen:
		ldi		r4,#$0024
		sh		r4,LEDS
		ldi		r1,#$FFD00000	; text screen address
		ldi		r2,#2480		; number of chars 2480 (80x31)
		ldi		r3,#%000010000_111111111_0000100000
.cts1:
		sh		r3,[r1]
		add		r1,r1,#4
		sub		r2,r2,#1
		bne		r2,r0,.cts1
		jal		[r29]

// ----------------------------------------------------------------------------
// Fill the text screen with random characters and colors.
// ----------------------------------------------------------------------------

;RandomizeTextScreen:
;		ldi		r4,#TEXTSCR
;		ldi		r3,#24
;		stw		r3,LEDS
;.j1:
;		call	gen_rand[pc]
;		mov		r2,r1
;		call	gen_rand[pc]
;		modu	r1,r1,#2604
;		ldi		r4,#TEXTSCR
;		stt		r2,[r4+r1*4]
;		stt		r1,SEVENSEG
;		ldwu	r1,BUTTONS
;		bbc		r1,#2,.j1
;		ret

