	cpu		W65C816S
	.org	$E000

start:
	clc					; switch to '816 mode
	xce
	rep		#$30		; set 16 bit regs & mem
	ndx 	16
	mem		16
	lda		#$0070		; program chip selects for I/O
	sta		$F000		; at $007000
	lda		#$0071
	sta		$F002
	ldy		#$0000
.st0001:
	ldx		#$0000
.st0002:
	inx
	bne		.st0002
	lda		$7100
	sta		$7000
	iny
	bra		.st0001

	.org	$FFFC
	dw		$E000
