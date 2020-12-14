	.file	"SieveOfE.c"
	.text
	.align	2
	.sdreg	r13
	.align	4
	.global	_SieveOfEratosthenes
_SieveOfEratosthenes:
	stwu	r1,-32(r1)
	lis	r11,-192
	stw	r11,24(r1)
	li	r11,0
	stw	r11,8(r1)
	b	SieveOfE_3
SieveOfE_2:
	lwz	r11,24(r1)
	lwz	r12,8(r1)
	add	r10,r11,r12
	li	r11,1
	stb	r11,0(r10)
SieveOfE_5:
	lwz	r11,8(r1)
	addi	r0,r11,1
	stw	r0,8(r1)
SieveOfE_3:
	lwz	r11,8(r1)
	cmpwi	cr0,r11,1024
	blt	cr0,SieveOfE_2
SieveOfE_4:
	li	r11,2
	stw	r11,12(r1)
	b	SieveOfE_7
SieveOfE_6:
	lwz	r11,24(r1)
	lwz	r12,12(r1)
	add	r10,r11,r12
	lbz	r11,0(r10)
	extsb.	cr0,r11
	beq	cr0,SieveOfE_11
	li	r11,0
	stw	r11,16(r1)
	li	r11,0
	stw	r11,20(r1)
	b	SieveOfE_13
SieveOfE_12:
	lwz	r11,12(r1)
	lwz	r12,12(r1)
	mullw	r10,r11,r12
	lwz	r11,20(r1)
	lwz	r12,12(r1)
	mullw	r9,r11,r12
	add	r10,r10,r9
	stw	r10,16(r1)
	lwz	r11,24(r1)
	lwz	r12,16(r1)
	add	r10,r11,r12
	li	r11,0
	stb	r11,0(r10)
SieveOfE_15:
	lwz	r11,20(r1)
	addi	r0,r11,1
	stw	r0,20(r1)
SieveOfE_13:
	lwz	r11,16(r1)
	cmpwi	cr0,r11,1024
	blt	cr0,SieveOfE_12
SieveOfE_14:
SieveOfE_11:
SieveOfE_9:
	lwz	r11,12(r1)
	addi	r0,r11,1
	stw	r0,12(r1)
SieveOfE_7:
	lwz	r11,12(r1)
	cmpwi	cr0,r11,32
	blt	cr0,SieveOfE_6
SieveOfE_8:
SieveOfE_16:
SieveOfE_19:
	b	SieveOfE_16
SieveOfE_18:
SieveOfE_1:
	addi	r1,r1,32
	blr
	.type	_SieveOfEratosthenes,@function
	.size	_SieveOfEratosthenes,$-_SieveOfEratosthenes
# stacksize=32
	.set	___stack_SieveOfEratosthenes,32
