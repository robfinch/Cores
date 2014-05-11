	bss
	align	8
public numbers:
	fill.w	1500000,0xffffffff
public primes:
	fill.w	100000,0xffffffff
	code
	align	16
public main:
	sub  	sp,#2
	st   	r14,0,sp
	st   	r12,1,sp
	lea  	r12,L_7
	tsr  	sp,r14
	sub  	sp,#5
	sub  	sp,#2
	st   	r3,0,sp
	st   	r4,1,sp
	     			jsr	(0xFFFF8014>>2)
	
L_2:
	jsr  	get_tick
	ld   	r5,r1
	st   	r5,-4,r14
	ld   	r5,-4,r14
	push 	r5
	ld   	r5,#L_3>>2
	push 	r5
	jsr  	printf
	sub  	sp,#-2
	ld   	r5,r1
	ld   	r5,#1500000
	st   	r5,-3,r14
	ld   	r5,#0
	ld   	r3,r5
L_8:
	ld   	r5,-3,r14
	cmp  	r3,r5
	bge  	L_9
	add  	r5,r3,#2
	st   	r5,numbers,r3
	add  	r3,r3,#1
	bra  	L_8
L_9:
	ld   	r5,#0
	ld   	r3,r5
L_10:
	ld   	r5,-3,r14
	cmp  	r3,r5
	bge  	L_11
	ld   	r5,numbers,r3
	cmp  	r5,#-1
	beq  	L_12
	ld   	r7,numbers,r3
	asl  	r6,r7,#1
	sub  	r5,r6,#2
	ld   	r4,r5
L_14:
	ld   	r5,-3,r14
	cmp  	r4,r5
	bge  	L_15
	ld   	r5,#-1
	st   	r5,numbers,r4
	ld   	r5,numbers,r3
	add  	r4,r4,r5
	bra  	L_14
L_15:
L_12:
	add  	r3,r3,#1
	bra  	L_10
L_11:
	ld   	r5,#0
	ld   	r4,r5
	ld   	r5,#0
	ld   	r3,r5
L_16:
	ld   	r5,-3,r14
	cmp  	r3,r5
	bge  	L_17
	cmp  	r4,#100000
	bge  	L_17
	ld   	r5,numbers,r3
	cmp  	r5,#-1
	beq  	L_18
	add  	r4,r4,#1
	ld   	r5,numbers,r3
	st   	r5,primes,r4
L_18:
	add  	r3,r3,#1
	bra  	L_16
L_17:
	jsr  	get_tick
	ld   	r5,r1
	st   	r5,-5,r14
	ld   	r6,-5,r14
	sub  	r5,r6,-4,r14
	push 	r5
	ld   	r5,#L_4>>2
	push 	r5
	jsr  	printf
	sub  	sp,#-2
	ld   	r5,r1
	ld   	r5,#L_5>>2
	push 	r5
	jsr  	printf
	sub  	sp,#-1
	ld   	r5,r1
	jsr  	getchar
	ld   	r5,r1
	ld   	r5,#0
	ld   	r3,r5
L_20:
	cmp  	r3,#100000
	bge  	L_21
	ld   	r5,primes,r3
	push 	r5
	ld   	r5,#L_6>>2
	push 	r5
	jsr  	printf
	sub  	sp,#-2
	ld   	r5,r1
	add  	r3,r3,#1
	bra  	L_20
L_21:
	ld   	r1,#0
L_22:
	ld   	r4,1,sp
	ld   	r3,0,sp
	sub  	sp,#-2
	trs  	r14,sp
	ld   	r14,0,sp
	ld   	r12,1,sp
	sub  	sp,#-2
	rts  
L_7:
	pop  	r0
	ld   	r12,1,r14
	push 	r12
	bra  	L_22
public printf:
	sub  	sp,#2
	st   	r14,0,sp
	st   	r12,1,sp
	lea  	r12,L_23
	tsr  	sp,r14
	sub  	sp,#1
	sub  	sp,#2
	st   	r3,0,sp
	st   	r4,1,sp
	ld   	r4,3,r14
	lea  	r5,3,r14
	ld   	r3,r5
L_24:
	cmp  	r0,(r4)
	beq  	L_25
	ld   	r5,(r4)
	cmp  	r5,#37
	bne  	L_26
	add  	r4,r4,#1
	lda  	(r4)
	cmp  	#37
	beq  	L_29
	cmp  	#99
	beq  	L_30
	cmp  	#100
	beq  	L_31
	cmp  	#115
	beq  	L_32
	bra  	L_28
L_29:
	ld   	r5,#37
	push 	r5
	jsr  	putch
	sub  	sp,#-1
	ld   	r5,r1
	bra  	L_28
L_30:
	add  	r3,r3,#1
	ld   	r5,(r3)
	push 	r5
	jsr  	putch
	sub  	sp,#-1
	ld   	r5,r1
	bra  	L_28
L_31:
	add  	r3,r3,#1
	ld   	r5,(r3)
	push 	r5
	jsr  	putnum
	sub  	sp,#-1
	ld   	r5,r1
	bra  	L_28
L_32:
	add  	r3,r3,#1
	ld   	r5,(r3)
	push 	r5
	jsr  	putstr
	sub  	sp,#-1
	ld   	r5,r1
L_28:
	bra  	L_27
L_26:
	ld   	r5,(r4)
	push 	r5
	jsr  	putch
	sub  	sp,#-1
	ld   	r5,r1
L_27:
	add  	r4,r4,#1
	bra  	L_24
L_25:
L_33:
	ld   	r4,1,sp
	ld   	r3,0,sp
	sub  	sp,#-2
	trs  	r14,sp
	ld   	r14,0,sp
	ld   	r12,1,sp
	sub  	sp,#-2
	rts  
L_23:
	pop  	r0
	ld   	r12,1,r14
	push 	r12
	bra  	L_33
public getchar:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	     	gc1:
		jsr		($FFFF800C>>2)
		cmp		#-1
		beq		gc1
	
L_35:
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_34:
public putch:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	     			ld		r1,3,sp
		jsr		($FFFF8000>>2)
	
L_37:
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_36:
public putnum:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	     			ld		r1,3,sp
		ld		r2,#5
		jsl		$FFFFF5A4
		;jsr		($FFFF8048>>2)
	
L_39:
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_38:
public putstr:
	sub  	sp,#2
	st   	r14,0,sp
	st   	r12,1,sp
	lea  	r12,L_40
	tsr  	sp,r14
	sub  	sp,#1
	st   	r3,0,sp
	ld   	r3,3,r14
L_41:
	cmp  	r0,(r3)
	beq  	L_42
	ld   	r5,(r3)
	push 	r5
	jsr  	putch
	sub  	sp,#-1
	add  	r3,r3,#1
	bra  	L_41
L_42:
L_43:
	ld   	r3,0,sp
	sub  	sp,#-1
	trs  	r14,sp
	ld   	r14,0,sp
	ld   	r12,1,sp
	sub  	sp,#-2
	rts  
L_40:
	pop  	r0
	ld   	r12,1,r14
	push 	r12
	bra  	L_43
public get_tick:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	     			tsr		tick,r1
	
L_45:
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_44:
public disable_ints:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	     			lda		#0x8001
		sta		0xFFDC0FF2
	
L_47:
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_46:
public enable_ints:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	     			lda		#0x800F
		sta		0xFFDC0FF2
	
L_49:
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_48:
	align	8
L_6:	; %d
	dw	37,100,13,10,0
L_5:	; Press a key to list primes.
	dw	80,114,101,115,115,32,97,32
	dw	107,101,121,32,116,111,32,108
	dw	105,115,116,32,112,114,105,109
	dw	101,115,46,0
L_4:	; Clock ticks %d
	dw	67,108,111,99,107,32,116,105
	dw	99,107,115,32,37,100,13,10
	dw	0
L_3:	; Start tick %d
	dw	13,10,83,116,97,114,116,32
	dw	116,105,99,107,32,37,100,13
	dw	10,0
;	global	putch
;	global	get_tick
;	global	enable_ints
;	global	primes
;	global	printf
;	global	main
;	global	putnum
;	global	putstr
;	global	getchar
;	global	disable_ints
;	global	numbers
