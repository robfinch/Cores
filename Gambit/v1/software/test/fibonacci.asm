; Fibonacci calculator in 6502 asm
; originally by Pedro Franceschi (pedrohfranceschi@gmail.com)
; ported to Gambit
; the accumulator in the end will hold the Nth fibonacci number

org	$FFFFFFFFFFFFC000

LDI	r2,#$FD
LDI	r2,#$01	; x = 1
ST	r2,$00

LDI	r3,#$10		; calculates 16th fibonacci number (13 = D in hex) (CHANGE HERE IF YOU WANT TO CALCULATE ANOTHER NUMBER)
OR	r1,r3,r0	; transfer y register to accumulator
SUB	r3,r3,#3	; handles the algorithm iteration counting

LDI	r1,#$2		; a = 2
ST	r1,$04		; stores a

loop: 
	LD	r2,$04		; x = a
	ADD	r1,r1,r2	; a += x
	ST	r1,$04		; stores a
	ST	r2,$00		; stores x
	SUB	r3,r3,#1	; y -= 1
  BNE loop			; jumps back to loop if Z bit != 0 (y's decremention isn't zero yet)

org $FFFFFFFFFFFFFFFC
	dcw	$FFFFFFFFFC000
;	dcw	$0

