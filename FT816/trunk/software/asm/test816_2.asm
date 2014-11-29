TickCount	EQU		$4
VIDBUF		EQU		$FD0000
PRNG		EQU		$FEA100

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
	lda		#$FEA1		; select $FEA1xx I/O
	sta		$F006
	stz		TickCount
	ldy     #1736
	ldx		#0
	lda		#$CE20
.st0004:
	lda		PRNG+8		; get a 16 bit random number
	sta		PRNG+14		; advance the PRNG
	and		#$7FE
	tax
	lda		PRNG+8		; get a 16 bit random number
	sta		PRNG+14		; advance the PRNG
	sta		VIDBUF,x
	bra		.st0004
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
	inc		TickCount
	pla
	rti

	.org	$FFEE		; IRQ vector
	dw		IRQRout

	.org	$FFFC
	dw		$E000
