	data
	align	8
memmgnt_0:	; pam_
	fill.b	4096,0x00
	align	8
memmgnt_1:	; start_bit_
	fill.b	8,0x00
	bss
	align	8
public bss syspages_:
	fill.b	8,0x00

endpublic
	code
	align	16
setLotReg_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw    r1,24[bp]
         lw    r2,32[bp]
         mtspr 40,r1
         mtspr 41,r2
     
memmgnt_5:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#32
getPamBit_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lw   	r4,24[bp]
	      	and  	r3,r4,#31
	      	sw   	r3,-8[bp]
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#5
	      	asli 	r3,r4,#1
	      	sw   	r3,-16[bp]
	      	lw   	r6,-16[bp]
	      	asli 	r5,r6,#3
	      	lea  	r6,memmgnt_0[gp]
	      	lw   	r5,0[r6+r5]
	      	lw   	r7,-8[bp]
	      	asli 	r6,r7,#1
	      	asr  	r4,r5,r6
	      	and  	r3,r4,#3
	      	mov  	r1,r3
memmgnt_9:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
setPamBit_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#memmgnt_11
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lw   	r4,24[bp]
	      	and  	r3,r4,#31
	      	sw   	r3,-8[bp]
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#5
	      	asli 	r3,r4,#1
	      	sw   	r3,-16[bp]
	      	lw   	r4,-16[bp]
	      	asli 	r3,r4,#3
	      	lea  	r4,memmgnt_0[gp]
	      	ldi  	r7,#3
	      	lw   	r9,-8[bp]
	      	asli 	r8,r9,#1
	      	asl  	r6,r7,r8
	      	com  	r5,r6
	      	lw   	r6,0[r4+r3]
	      	and  	r6,r6,r5
	      	sw   	r6,0[r4+r3]
	      	lw   	r4,-16[bp]
	      	asli 	r3,r4,#3
	      	lea  	r4,memmgnt_0[gp]
	      	lw   	r7,32[bp]
	      	and  	r6,r7,#3
	      	lw   	r8,-8[bp]
	      	asli 	r7,r8,#1
	      	asl  	r5,r6,r7
	      	lw   	r6,0[r4+r3]
	      	or   	r6,r6,r5
	      	sw   	r6,0[r4+r3]
	      	lw   	r7,40[bp]
	      	and  	r6,r7,#1023
	      	asli 	r5,r6,#6
	      	lw   	r8,48[bp]
	      	and  	r7,r8,#7
	      	asli 	r6,r7,#3
	      	or   	r4,r5,r6
	      	or   	r3,r4,#6
	      	push 	r3
	      	lw   	r4,24[bp]
	      	asli 	r3,r4,#16
	      	push 	r3
	      	bsr  	setLotReg_
memmgnt_13:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
memmgnt_11:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	memmgnt_13
setPambits_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#memmgnt_15
	      	mov  	bp,sp
memmgnt_17:
	      	lw   	r3,40[bp]
	      	cmpu 	r4,r3,#0
	      	ble  	r4,memmgnt_18
	      	push 	56[bp]
	      	push 	48[bp]
	      	push 	32[bp]
	      	push 	24[bp]
	      	bsr  	setPambit_
	      	addui	sp,sp,#32
memmgnt_19:
	      	dec  	40[bp],#1
	      	inc  	24[bp],#1
	      	bra  	memmgnt_17
memmgnt_18:
memmgnt_20:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#40
memmgnt_15:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	memmgnt_20
find_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#memmgnt_22
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	lw   	r3,memmgnt_1[gp]
	      	sw   	r3,-8[bp]
memmgnt_24:
	      	lw   	r3,-8[bp]
	      	cmpu 	r4,r3,#2048
	      	bge  	r4,memmgnt_25
	      	push 	-8[bp]
	      	bsr  	getPamBit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,memmgnt_27
	      	lw   	r3,24[bp]
	      	sw   	r3,-16[bp]
	      	lw   	r3,-8[bp]
	      	sw   	r3,-24[bp]
memmgnt_29:
	      	push 	-8[bp]
	      	bsr  	getPamBit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,memmgnt_30
	      	lw   	r3,-16[bp]
	      	cmpu 	r4,r3,#0
	      	ble  	r4,memmgnt_30
	      	lw   	r3,-8[bp]
	      	cmpu 	r4,r3,#2048
	      	bge  	r4,memmgnt_30
	      	inc  	-8[bp],#1
	      	dec  	-16[bp],#1
	      	bra  	memmgnt_29
memmgnt_30:
	      	lw   	r3,-16[bp]
	      	cmpu 	r4,r3,#0
	      	bgt  	r4,memmgnt_31
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
memmgnt_33:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
memmgnt_31:
	      	lw   	r3,-8[bp]
	      	cmpu 	r4,r3,#2048
	      	blt  	r4,memmgnt_34
	      	ldi  	r1,#0
	      	bra  	memmgnt_33
memmgnt_34:
memmgnt_27:
memmgnt_26:
	      	inc  	-8[bp],#1
	      	bra  	memmgnt_24
memmgnt_25:
	      	ldi  	r1,#0
	      	bra  	memmgnt_33
memmgnt_22:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	memmgnt_33
round64k_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	addui	r3,r3,#65535
	      	sw   	r3,24[bp]
	      	lw   	r3,24[bp]
	      	andi 	r3,r3,#-65536
	      	sw   	r3,24[bp]
	      	lw   	r3,24[bp]
	      	mov  	r1,r3
memmgnt_39:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
	data
	align	8
memmgnt_40:
	db	1
	code
	align	16
public code sys_alloc_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#memmgnt_41
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	lb   	r3,memmgnt_40
	      	beq  	r3,memmgnt_44
	      	sb   	r0,memmgnt_40
	      	push 	#4096
	      	push 	#0
	      	pea  	memmgnt_0[gp]
	      	bsr  	memset_
	      	addui	sp,sp,#24
	      	lea  	r3,highest_data_word_[gp]
	      	sw   	r3,-8[bp]
	      	push 	-8[bp]
	      	bsr  	round64k_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r5,-8[bp]
	      	asri 	r4,r5,#16
	      	addu 	r3,r4,#8
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	cmpu 	r4,r3,#2048
	      	bge  	r4,memmgnt_45
	      	sw   	r0,-24[bp]
memmgnt_47:
	      	lw   	r3,-24[bp]
	      	lw   	r4,-16[bp]
	      	cmp  	r5,r3,r4
	      	bge  	r5,memmgnt_48
memmgnt_49:
	      	inc  	-24[bp],#1
	      	bra  	memmgnt_47
memmgnt_48:
	      	lw   	r3,-16[bp]
	      	sw   	r3,memmgnt_1[gp]
	      	lw   	r3,-16[bp]
	      	sw   	r3,syspages_[gp]
memmgnt_45:
memmgnt_44:
	      	push 	24[bp]
	      	bsr  	round64k_
	      	mov  	r3,r1
	      	sw   	r3,24[bp]
	      	lw   	r3,24[bp]
	      	bne  	r3,memmgnt_50
	      	ldi  	r1,#0
memmgnt_52:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#24
memmgnt_50:
	      	lw   	r4,24[bp]
	      	asri 	r3,r4,#16
	      	sw   	r3,-40[bp]
	      	push 	-40[bp]
	      	bsr  	find_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-32[bp]
	      	lw   	r3,-32[bp]
	      	bne  	r3,memmgnt_53
	      	ldi  	r1,#0
	      	bra  	memmgnt_52
memmgnt_53:
	      	push 	40[bp]
	      	push 	32[bp]
	      	push 	-40[bp]
	      	push 	#1
	      	push 	-32[bp]
	      	bsr  	setPamBits_
	      	addui	sp,sp,#40
	      	push 	40[bp]
	      	push 	32[bp]
	      	push 	#2
	      	lw   	r5,-32[bp]
	      	lw   	r6,-40[bp]
	      	addu 	r4,r5,r6
	      	subu 	r3,r4,#1
	      	push 	r3
	      	bsr  	setPamBit_
	      	addui	sp,sp,#32
	      	lw   	r4,-32[bp]
	      	asli 	r3,r4,#16
	      	mov  	r1,r3
	      	bra  	memmgnt_52
memmgnt_41:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	memmgnt_52
endpublic

public code sys_free_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#memmgnt_55
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lw   	r4,24[bp]
	      	and  	r3,r4,#65535
	      	beq  	r3,memmgnt_57
memmgnt_59:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
memmgnt_57:
	      	lw   	r4,24[bp]
	      	asri 	r3,r4,#16
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	lw   	r4,memmgnt_1[gp]
	      	cmpu 	r5,r3,r4
	      	blt  	r5,memmgnt_62
	      	lw   	r3,-8[bp]
	      	cmpu 	r4,r3,#2048
	      	blt  	r4,memmgnt_60
memmgnt_62:
	      	bra  	memmgnt_59
memmgnt_60:
memmgnt_63:
	      	push 	-8[bp]
	      	bsr  	getPamBit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#1
	      	beq  	r4,memmgnt_67
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#2
	      	bne  	r4,memmgnt_65
memmgnt_67:
	      	push 	#0
	      	push 	-8[bp]
	      	bsr  	setPamBit_
	      	addui	sp,sp,#16
memmgnt_65:
	      	push 	#0
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#16
	      	push 	r3
	      	bsr  	setLotReg_
	      	inc  	-8[bp],#1
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#1
	      	bne  	r4,memmgnt_68
	      	lw   	r3,-8[bp]
	      	cmpu 	r4,r3,#2048
	      	blt  	r4,memmgnt_63
memmgnt_68:
memmgnt_64:
	      	bra  	memmgnt_59
memmgnt_55:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	memmgnt_59
endpublic

	rodata
	align	16
	align	8
	extern	setPambit_
;	global	sys_alloc_
	extern	setPamBits_
	extern	highest_data_word_
;	global	sys_free_
;	global	syspages_
	extern	memset_
