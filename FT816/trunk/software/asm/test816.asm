	cpu		W65C816S
	.org	$E000

start:
	sei
	cld
	clc					; switch to '816 mode
	xce
	rep		#$30		; set 16 bit regs & mem
	ndx 	16
	mem		16
	lda		#$1FFF		; set top of stack
	tas
	cli
	lda		#$0070		; program chip selects for I/O
	sta		$F000		; at $007000
	lda		#$0071
	sta		$F002
	jsr		echo_switch
	ldy		#$0000
.st0001:
	ldx		#$0000
.st0002:
	inx
	bne		.st0002
	jsr		echo_switch
	iny
	bra		.st0001

echo_switch:
	lda		$7100
	sta		$7000
	rts

IRQRout:
	pha
	lda		#$AA
	sta		$7000
	pla
	rti

	.org	$FFEE		; IRQ vector
	dw		IRQRout

	.org	$FFFC
	dw		$E000
