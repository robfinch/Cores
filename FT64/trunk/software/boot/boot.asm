;
	code
	org		$FFFC0000
	jmp		brkrout
	org		$FFFC0010
start:
	ldi		r1,#$AAAA5555
start1:
	shr		r2,r1,#12
	sh		r2,$FFDC0600
	add		r1,r1,#1
	bra		start1

brkrout:
	rti
