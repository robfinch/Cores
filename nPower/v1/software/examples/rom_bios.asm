	.file	"rom_bios.c"
	.text
	.align	2
	.sdreg	r13
	.align	4
	.global	_main
_main:
	mflr	r11
	stwu	r1,-32(r1)
	stw	r11,36(r1)
	lis	r11,-36
	addi	r11,r11,1536
	stw	r11,12(r1)
	lis	r11,-48
	stw	r11,16(r1)
	bl	_SieveOfEratosthenes
	li	r11,170
	lwz	r12,12(r1)
	stw	r11,0(r12)
	lis	r11,20465
	addi	r11,r11,-4096
	stw	r11,8(r1)
	lwz	r11,8(r1)
	ori	r0,r11,65
	lwz	r11,16(r1)
	stw	r0,0(r11)
	lwz	r11,8(r1)
	ori	r10,r11,65
	lwz	r9,16(r1)
	stw	r10,4(r9)
	lwz	r11,8(r1)
	ori	r10,r11,65
	lwz	r9,16(r1)
	stw	r10,8(r9)
	lwz	r11,8(r1)
	ori	r10,r11,65
	lwz	r9,16(r1)
	stw	r10,12(r9)
rom_bios_1:
	lwz	r11,36(r1)
	addi	r1,r1,32
	mtlr	r11
	blr
	.type	_main,@function
	.size	_main,$-_main
# stacksize=32+??
	.global	_SieveOfEratosthenes
