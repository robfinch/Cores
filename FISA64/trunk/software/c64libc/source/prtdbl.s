	code
	align	16
public code sprtdbl_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#48
	      	push 	r11
	      	lw   	r11,24[bp]
	      	sw   	r0,-8[bp]
	      	lfd  	fp3,32[bp]
	      	ldi  	fp4,#0x0
	      	fcmp 	r3,fp3,fp4
	      	bge  	r3,prtdbl_4
	      	lfd  	fp4,32[bp]
	      	fneg 	fp3,fp4
	      	sfd  	fp3,32[bp]
	      	ldi  	r3,#45
	      	andi 	r3,r3,#65535
	      	sc   	r3,[r11]
	      	inc  	-8[bp],#1
prtdbl_4:
	      	lfd  	fp3,32[bp]
	      	ldi  	fp4,#0x4046800000000000
	      	fcmp 	r3,fp3,fp4
	      	bne  	r3,prtdbl_6
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#48
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#0
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
prtdbl_8:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#56
prtdbl_6:
	      	sw   	r0,-16[bp]
prtdbl_9:
	      	lfd  	fp3,32[bp]
	      	ldi  	fp4,#0x3ff0000000000000
	      	fcmp 	r3,fp3,fp4
	      	bge  	r3,prtdbl_10
	      	ldi  	fp3,#0x412e848000000000
	      	lfd  	fp4,32[bp]
	      	fmul 	fp4,fp4,fp3
	      	sfd  	fp4,32[bp]
	      	dec  	-16[bp],#6
	      	bra  	prtdbl_9
prtdbl_10:
prtdbl_11:
	      	lfd  	fp3,32[bp]
	      	ldi  	fp4,#0x40f86a0000000000
	      	fcmp 	r3,fp3,fp4
	      	ble  	r3,prtdbl_12
	      	lfd  	fp3,32[bp]
	      	ldi  	fp4,#0x4024000000000000
	      	fdiv 	fp3,fp3,fp4
	      	sfd  	fp3,32[bp]
	      	lw   	r3,fp3
	      	inc  	-16[bp],#1
	      	bra  	prtdbl_11
prtdbl_12:
prtdbl_13:
	      	lfd  	fp3,32[bp]
	      	ldi  	fp4,#0x40f86a0000000000
	      	fcmp 	r3,fp3,fp4
	      	bge  	r3,prtdbl_14
	      	ldi  	fp3,#0x4024000000000000
	      	lfd  	fp4,32[bp]
	      	fmul 	fp4,fp4,fp3
	      	sfd  	fp4,32[bp]
	      	dec  	-16[bp],#1
	      	bra  	prtdbl_13
prtdbl_14:
	      	ldi  	r3,#1
	      	sw   	r3,-48[bp]
	      	lw   	r4,-16[bp]
	      	addu 	r3,r4,#7
	      	sw   	r3,-24[bp]
	      	lw   	r4,-16[bp]
	      	addu 	r3,r4,#7
	      	blt  	r3,prtdbl_15
	      	lw   	r4,-16[bp]
	      	addu 	r3,r4,#7
	      	cmp  	r4,r3,#8
	      	bge  	r4,prtdbl_15
	      	lw   	r4,-16[bp]
	      	addu 	r3,r4,#7
	      	sw   	r3,-48[bp]
	      	dec  	-48[bp],#1
	      	ldi  	r3,#2
	      	sw   	r3,-24[bp]
prtdbl_15:
prtdbl_0:
	      	dec  	-24[bp],#2
	      	lw   	r3,-48[bp]
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	bgt  	r3,prtdbl_17
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#46
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
	      	lw   	r3,-16[bp]
	      	bge  	r3,prtdbl_19
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#48
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
prtdbl_19:
prtdbl_17:
	      	sw   	r0,-40[bp]
prtdbl_21:
	      	lw   	r3,-40[bp]
	      	cmp  	r4,r3,#16
	      	bge  	r4,prtdbl_22
	      	lw   	r3,48[bp]
	      	ble  	r3,prtdbl_22
	      	sw   	r0,-32[bp]
prtdbl_24:
	      	lfd  	fp3,32[bp]
	      	ldi  	fp4,#0x40f86a0000000000
	      	fcmp 	r3,fp3,fp4
	      	ble  	r3,prtdbl_25
	      	ldi  	fp3,#0x40f86a0000000000
	      	lfd  	fp4,32[bp]
	      	fsub 	fp4,fp4,fp3
	      	sfd  	fp4,32[bp]
	      	inc  	-32[bp],#1
	      	bra  	prtdbl_24
prtdbl_25:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-32[bp]
	      	addu 	r4,r5,#48
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
	      	dec  	-16[bp],#1
	      	lw   	r3,-16[bp]
	      	bne  	r3,prtdbl_26
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#46
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
	      	bra  	prtdbl_27
prtdbl_26:
	      	lw   	r3,-16[bp]
	      	bge  	r3,prtdbl_28
	      	dec  	48[bp],#1
prtdbl_28:
prtdbl_27:
	      	ldi  	fp3,#0x4024000000000000
	      	lfd  	fp4,32[bp]
	      	fmul 	fp4,fp4,fp3
	      	sfd  	fp4,32[bp]
prtdbl_23:
	      	inc  	-40[bp],#1
	      	bra  	prtdbl_21
prtdbl_22:
prtdbl_30:
	      	dec  	-8[bp],#1
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lc   	r3,0[r11+r3]
	      	cmp  	r4,r3,#48
	      	beq  	r4,prtdbl_30
prtdbl_31:
	      	inc  	-8[bp],#1
	      	lw   	r3,-24[bp]
	      	bne  	r3,prtdbl_32
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#0
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	bra  	prtdbl_1
prtdbl_32:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lcu  	r4,56[bp]
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
	      	lw   	r3,-24[bp]
	      	bge  	r3,prtdbl_34
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#45
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
	      	lw   	r4,-24[bp]
	      	neg  	r3,r4
	      	sw   	r3,-24[bp]
	      	bra  	prtdbl_35
prtdbl_34:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#43
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
prtdbl_35:
	      	sw   	r0,-32[bp]
prtdbl_36:
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#1000
	      	ble  	r4,prtdbl_37
	      	lw   	r3,-24[bp]
	      	subui	r3,r3,#1000
	      	sw   	r3,-24[bp]
	      	inc  	-32[bp],#1
	      	bra  	prtdbl_36
prtdbl_37:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-32[bp]
	      	addu 	r4,r5,#48
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
	      	sw   	r0,-32[bp]
prtdbl_38:
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#100
	      	ble  	r4,prtdbl_39
	      	lw   	r3,-24[bp]
	      	subui	r3,r3,#100
	      	sw   	r3,-24[bp]
	      	inc  	-32[bp],#1
	      	bra  	prtdbl_38
prtdbl_39:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-32[bp]
	      	addu 	r4,r5,#48
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
	      	sw   	r0,-32[bp]
prtdbl_40:
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#10
	      	ble  	r4,prtdbl_41
	      	dec  	-24[bp],#10
	      	inc  	-32[bp],#1
	      	bra  	prtdbl_40
prtdbl_41:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-32[bp]
	      	addu 	r4,r5,#48
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
	      	sw   	r0,-32[bp]
prtdbl_42:
	      	lw   	r3,-24[bp]
	      	ble  	r3,prtdbl_43
	      	dec  	-24[bp],#1
	      	inc  	-32[bp],#1
	      	bra  	prtdbl_42
prtdbl_43:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-32[bp]
	      	addu 	r4,r5,#48
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#0
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
prtdbl_1:
	      	lw   	r3,40[bp]
	      	ble  	r3,prtdbl_44
	      	lw   	r3,-8[bp]
	      	lw   	r4,40[bp]
	      	cmp  	r5,r3,r4
	      	bge  	r5,prtdbl_46
	      	ldi  	r3,#29
	      	sw   	r3,-40[bp]
prtdbl_48:
	      	lw   	r3,-40[bp]
	      	lw   	r5,40[bp]
	      	lw   	r6,-8[bp]
	      	subu 	r4,r5,r6
	      	cmp  	r5,r3,r4
	      	blt  	r5,prtdbl_49
	      	lw   	r4,-40[bp]
	      	asli 	r3,r4,#1
	      	lw   	r6,-40[bp]
	      	lw   	r8,40[bp]
	      	lw   	r9,-8[bp]
	      	subu 	r7,r8,r9
	      	subu 	r5,r6,r7
	      	asli 	r4,r5,#1
	      	lcu  	r5,0[r11+r4]
	      	sc   	r5,0[r11+r3]
prtdbl_50:
	      	dec  	-40[bp],#1
	      	bra  	prtdbl_48
prtdbl_49:
prtdbl_51:
	      	lw   	r3,-40[bp]
	      	blt  	r3,prtdbl_52
	      	lw   	r4,-40[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#32
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
prtdbl_53:
	      	dec  	-40[bp],#1
	      	bra  	prtdbl_51
prtdbl_52:
prtdbl_46:
prtdbl_44:
	      	lw   	r3,40[bp]
	      	bge  	r3,prtdbl_54
	      	lw   	r4,40[bp]
	      	neg  	r3,r4
	      	sw   	r3,40[bp]
prtdbl_56:
	      	lw   	r3,-8[bp]
	      	lw   	r4,40[bp]
	      	cmp  	r5,r3,r4
	      	bge  	r5,prtdbl_57
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#32
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
	      	bra  	prtdbl_56
prtdbl_57:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#0
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
prtdbl_54:
	      	lw   	r3,-8[bp]
	      	mov  	r1,r3
	      	bra  	prtdbl_8
endpublic

	data
	align	8
prtdbl_58:	; buf_
	fill.b	400,0x00
	code
	align	16
public code prtdbl_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#prtdbl_59
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,32[bp]
	      	cmp  	r4,r3,#199
	      	ble  	r4,prtdbl_61
	      	ldi  	r3,#199
	      	sw   	r3,32[bp]
prtdbl_61:
	      	lw   	r3,32[bp]
	      	cmp  	r4,r3,#-199
	      	bge  	r4,prtdbl_63
	      	ldi  	r3,#-199
	      	sw   	r3,32[bp]
prtdbl_63:
	      	lc   	r3,48[bp]
	      	push 	r3
	      	push 	40[bp]
	      	push 	32[bp]
	      	push 	24[bp]
	      	pea  	prtdbl_58[gp]
	      	bsr  	sprtdbl_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	push 	32[bp]
	      	pea  	prtdbl_58[gp]
	      	bsr  	putstr_
	      	lw   	r3,-8[bp]
	      	mov  	r1,r3
prtdbl_65:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#32
prtdbl_59:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	prtdbl_65
endpublic

	rodata
	align	16
	align	8
	extern	putstr_
	extern	putchar_
;	global	sprtdbl_
;	global	prtdbl_
