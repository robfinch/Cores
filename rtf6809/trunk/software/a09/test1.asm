
	org		$0000F000

	leas	$3FFF
	ldx		#>msgHello
	stx		$10
	ldx		#<MsgHello
	stx		$12
	jsr		far putstr

msgHello
	fcc	'Hello World!'
	fcb	0

putstr
	ldx		#0
	bra		ps4
ps2:
	inc		$13
	bne		ps4
	inc		$12
	bne		ps4
	inc		$11
	bne		ps4
	inc		$10
ps4:
	lda		far [$10]
	beq		ps1
	sta		$FFD00000,x
	leax	4,x
	bne		ps2
ps1:
	rtf

	org		$FFFC
	fcw		$F000
	fcw		$F000
