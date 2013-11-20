	data
	align	8
	db	0,0,0,0,0,0
	bss
	align	8
public sprX:
	dcb.b	10,0xff
public sprY:
	dcb.b	10,0xff
public sprDX:
	dcb.b	10,0xff
public sprDY:
	dcb.b	10,0xff
public pacmanX:
	dcb.b	2,0xff
public pacmanY:
	dcb.b	2,0xff
	data
	align	8
	db	0,0,0,0
	bss
	align	8
public score:
	dcb.b	8,0xff
	data
	align	8
public map:
	dc	1,1,1,1,1,1,1,1
	dc	1,1,1,1,1,1,1,1
	dc	1,1,1,1,1,1,1,1
	dc	1,1,1,1,0,0,0,0
	dc	0,0,0,0,0,0,0,0
	dc	1,0,0,0,0,0,0,0
	dc	0,0,0,0,0,1,1,0
	dc	1,1,1,1,0,1,1,1
	dc	1,1,0,1,0,1,1,1
	dc	1,1,0,1,1,1,1,0
	dc	1,1,0,1,0,0,1,0
	dc	1,0,0,0,1,0,1,0
	dc	1,0,0,0,1,0,1,0
	dc	0,1,0,1,1,0,1,1
	dc	1,1,0,1,1,1,1,1
	dc	0,1,0,1,1,1,1,1
	dc	0,1,1,1,1,0,1,1
	dc	0,0,0,0,0,0,0,0
	dc	0,0,0,0,0,0,0,0
	dc	0,0,0,0,0,0,0,0
	dc	0,1,1,0,1,1,1,1
	dc	0,1,0,1,1,1,1,1
	dc	1,1,1,1,0,1,0,1
	dc	1,1,1,0,1,1,0,0
	dc	0,0,0,0,1,0,0,0
	dc	0,0,1,0,0,0,0,0
	dc	1,0,0,0,0,0,0,1
	dc	1,1,1,1,1,1,0,1
	dc	1,1,1,1,0,1,0,1
	dc	1,1,1,1,0,1,1,1
	dc	1,1,1,0,0,0,0,0
	dc	1,0,0,0,0,0,0,0
	dc	1,0,0,0,0,0,1,0
	dc	0,0,0,0,0,0,0,0
	dc	0,0,0,1,0,1,1,1
	dc	1,1,0,1,0,1,1,1
	dc	1,1,0,1,0,0,0,0
	dc	0,0,0,0,0,0,1,0
	dc	1,0,0,0,0,0,0,0
	dc	0,0,0,0,1,0,1,0
	dc	0,0,0,0,0,0,0,0
	dc	0,1,0,1,0,1,1,2
	dc	2,2,2,2,1,1,0,1
	dc	0,1,0,0,0,0,0,1
	dc	1,1,1,1,1,0,1,0
	dc	1,0,0,0,0,0,0,0
	dc	1,0,1,0,1,1,1,1
	dc	1,1,3,0,0,0,0,0
	dc	0,0,0,1,0,0,0,0
	dc	0,0,0,1,0,0,0,0
	dc	0,0,0,0,3,1,1,1
	dc	1,1,1,0,1,0,1,0
	dc	0,0,0,0,0,0,1,0
	dc	1,0,1,1,1,1,1,1
	dc	0,0,0,0,0,1,0,1
	dc	0,1,1,1,1,1,1,1
	dc	1,1,0,1,0,1,0,0
	dc	0,0,0,0,0,0,0,0
	dc	1,0,1,0,0,0,0,0
	dc	0,0,0,0,0,0,1,0
	dc	1,0,0,0,0,0,1,1
	dc	1,1,1,1,0,1,0,1
	dc	1,1,1,1,1,1,1,1
	dc	0,1,0,1,1,1,1,1
	dc	1,1,0,0,0,0,0,0
	dc	0,0,0,0,0,0,1,0
	dc	0,0,0,0,0,0,0,0
	dc	0,0,0,1,1,0,1,1
	dc	0,1,1,1,1,1,1,1
	dc	0,1,0,1,1,1,1,1
	dc	1,1,0,1,1,0,1,1
	dc	0,0,1,0,0,0,0,0
	dc	0,0,0,0,0,0,0,0
	dc	0,0,0,0,0,0,1,0
	dc	0,1,1,1,0,1,0,1
	dc	0,1,1,1,1,1,1,1
	dc	1,1,1,1,1,1,0,1
	dc	0,1,0,1,1,1,0,0
	dc	0,0,1,0,0,0,0,0
	dc	0,0,1,0,0,0,0,0
	dc	0,0,1,0,0,0,0,1
	dc	1,0,1,1,1,1,1,1
	dc	1,1,1,1,0,1,0,1
	dc	1,1,1,1,1,1,1,1
	dc	1,0,1,1,0,0,0,0
	dc	0,0,0,0,0,0,0,0
	dc	0,0,0,0,0,0,0,0
	dc	0,0,0,0,0,1,1,1
	dc	1,1,1,1,1,1,1,1
	dc	1,1,1,1,1,1,1,1
	dc	1,1,1,1,1,1,1,1
	dc	1
	code
	align	16
public AsciiToScreen:
	      	subui	sp,sp,#32
	      	sw   	bp,[sp]
	      	sws  	pregs,24[sp]
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	sw   	r11,[sp]
	      	sw   	r12,8[sp]
	      	lc   	r3,24[bp]
	      	mov  	r11,r3
	      	ldi  	r12,#256
	      	and  	r3,r11,#255
	      	mov  	r11,r3
	      	cmp  	p0,r11,#65
	p0.ge	bra  	L_2
	      	or   	r3,r11,r12
	      	mov  	r1,r3
L_4:
	      	lw   	r12,8[sp]
	      	lw   	r11,[sp]
	      	addui	sp,sp,#16
	      	mov  	sp,bp
	      	lw   	bp,[sp]
	      	lws  	pregs,24[sp]
	      	addui	sp,sp,#32
	      	rts  
L_2:
	      	cmp  	p0,r11,#90
	p0.le	bra  	L_0
L_5:
	      	cmp  	p0,r11,#122
	p0.gt	or   	r3,r11,r12
	p0.gt	mov  	r1,r3
	p0.gt	bra  	L_4
L_7:
	      	cmp  	p0,r11,#97
	p0.lt	or   	r3,r11,r12
	p0.lt	mov  	r1,r3
	p0.lt	bra  	L_4
L_9:
L_0:
	      	subu 	r3,r11,#96
	      	mov  	r11,r3
	      	or   	r3,r11,r12
	      	mov  	r11,r3
	      	mov  	r1,r11
	      	bra  	L_4
L_1:
public MapToChar:
	      	subui	sp,sp,#32
	      	sw   	bp,[sp]
	      	sws  	pregs,24[sp]
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	or   	r1,r3,r0
	      	cmp  	p0,r1,#0
	p0.eq	bra  	L_13
	      	cmp  	p0,r1,#1
	p0.eq	bra  	L_14
	      	cmp  	p0,r1,#2
	p0.eq	bra  	L_15
	      	cmp  	p0,r1,#3
	p0.eq	bra  	L_16
	      	cmp  	p0,r1,#4
	p0.eq	bra  	L_17
	      	bra  	L_12
L_13:
	      	ldi  	r1,#46
L_18:
	      	mov  	sp,bp
	      	lw   	bp,[sp]
	      	lws  	pregs,24[sp]
	      	addui	sp,sp,#32
	      	rts  
L_14:
	      	ldi  	r1,#35
	      	bra  	L_18
L_15:
	      	ldi  	r1,#45
	      	bra  	L_18
L_16:
	      	ldi  	r1,#63
	      	bra  	L_18
L_17:
	      	ldi  	r1,#32
	      	bra  	L_18
L_12:
	      	ldi  	r1,#63
	      	bra  	L_18
L_11:
public setRandDir:
	      	subui	sp,sp,#32
	      	sw   	bp,[sp]
	      	sws  	xlr,8[sp]
	      	sws  	lr,16[sp]
	      	sws  	pregs,24[sp]
	      	ldis 	xlr,#L_19
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	sw   	r11,[sp]
	      	subui	sp,sp,#8
	      	sws  	br9,[sp]
	      	lw   	r3,24[bp]
	      	mov  	r11,r3
	      	ldis 	br9,#rand
	      	subui	sp,sp,#8
	      	ldi  	r3,#100
	      	sw   	r3,[sp]
	      	jsr  	lr,[br9]
	      	addui	sp,sp,#8
	      	cmp  	p0,r1,#50
	p0.le	bra  	L_20
	      	subui	sp,sp,#8
	      	ldi  	r3,#3
	      	sw   	r3,[sp]
	      	jsr  	lr,[br9]
	      	addui	sp,sp,#8
	      	subu 	r3,r1,#1
	      	shli 	r4,r11,#1
	      	sc   	r3,sprDY[r4]
	      	ldi  	r3,#0
	      	shli 	r4,r11,#1
	      	sc   	r3,sprDX[r4]
	      	bra  	L_21
L_20:
	      	subui	sp,sp,#8
	      	sw   	r4,[sp]
	      	subui	sp,sp,#8
	      	ldi  	r3,#3
	      	sw   	r3,[sp]
	      	jsr  	lr,[br9]
	      	addui	sp,sp,#8
	      	lw   	r4,[sp]
	      	addui	sp,sp,#8
	      	subu 	r3,r1,#1
	      	shli 	r4,r11,#1
	      	sc   	r3,sprDX[r4]
	      	ldi  	r3,#0
	      	shli 	r4,r11,#1
	      	sc   	r3,sprDY[r4]
L_21:
L_22:
	      	lws  	br9,[sp]
	      	addui	sp,sp,#8
	      	lw   	r11,[sp]
	      	addui	sp,sp,#8
	      	mov  	sp,bp
	      	lw   	bp,[sp]
	      	lws  	xlr,8[sp]
	      	lws  	lr,16[sp]
	      	lws  	pregs,24[sp]
	      	addui	sp,sp,#32
	      	rts  
L_19:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	L_22
public RedrawMap:
	      	subui	sp,sp,#32
	      	sw   	bp,[sp]
	      	sws  	xlr,8[sp]
	      	sws  	lr,16[sp]
	      	sws  	pregs,24[sp]
	      	ldis 	xlr,#L_23
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	subui	sp,sp,#40
	      	sw   	r11,[sp]
	      	sw   	r12,8[sp]
	      	sw   	r13,16[sp]
	      	sw   	r14,24[sp]
	      	sw   	r15,32[sp]
	      	ldi  	r3,#13631488
	      	mov  	r15,r3
	      	ldi  	r3,#0
	      	mov  	r12,r3
L_24:
	      	cmp  	p0,r12,#27
	p0.ge	bra  	L_25
	      	ldi  	r3,#0
	      	mov  	r11,r3
L_26:
	      	cmp  	p1,r11,#27
	p1.ge	bra  	L_27
	      	mului	r3,r12,#54
	      	shli 	r4,r11,#1
	      	addu 	r5,r4,#map
	      	lc   	r3,[r5+r3]
	      	mov  	r14,r3
	      	subui	sp,sp,#16
	      	sw   	r4,8[sp]
	      	sw   	r6,[sp]
	      	subui	sp,sp,#8
	      	sw   	r14,[sp]
	      	jsr  	MapToChar
	      	addui	sp,sp,#8
	      	lw   	r4,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	mov  	r13,r1
	      	subui	sp,sp,#16
	      	sw   	r4,8[sp]
	      	sw   	r6,[sp]
	      	subui	sp,sp,#16
	      	subui	sp,sp,#16
	      	sw   	r4,8[sp]
	      	sw   	r6,[sp]
	      	subui	sp,sp,#8
	      	sw   	r13,[sp]
	      	jsr  	AsciiToScreen
	      	addui	sp,sp,#8
	      	lw   	r4,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	sw   	r1,8[sp]
	      	mulsi	r3,r12,#84
	      	addu 	r4,r3,r11
	      	shli 	r3,r4,#1
	      	addu 	r4,r3,r15
	      	sw   	r4,[sp]
	      	jsr  	outc
	      	addui	sp,sp,#16
	      	lw   	r4,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	addui	r11,r11,#1
	      	bra  	L_26
L_27:
	      	addui	r12,r12,#1
	      	bra  	L_24
L_25:
	      	subui	sp,sp,#8
	      	sw   	r6,[sp]
	      	subui	sp,sp,#16
	      	ldi  	r3,#2
	      	sw   	r3,8[sp]
	      	ldi  	r3,#30
	      	sw   	r3,[sp]
	      	jsr  	setCursorPos
	      	addui	sp,sp,#16
	      	lw   	r6,[sp]
	      	addui	sp,sp,#8
	      	subui	sp,sp,#8
	      	sw   	r6,[sp]
	      	subui	sp,sp,#8
	      	lw   	r3,score
	      	sw   	r3,[sp]
	      	jsr  	putnum
	      	addui	sp,sp,#8
	      	lw   	r6,[sp]
	      	addui	sp,sp,#8
L_28:
	      	lw   	r15,32[sp]
	      	lw   	r14,24[sp]
	      	lw   	r13,16[sp]
	      	lw   	r12,8[sp]
	      	lw   	r11,[sp]
	      	addui	sp,sp,#40
	      	mov  	sp,bp
	      	lw   	bp,[sp]
	      	lws  	xlr,8[sp]
	      	lws  	lr,16[sp]
	      	lws  	pregs,24[sp]
	      	addui	sp,sp,#32
	      	rts  
L_23:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	L_28
public main:
	      	subui	sp,sp,#32
	      	sw   	bp,[sp]
	      	sws  	xlr,8[sp]
	      	sws  	lr,16[sp]
	      	sws  	pregs,24[sp]
	      	ldis 	xlr,#L_31
	      	mov  	bp,sp
	      	subui	sp,sp,#56
	      	subui	sp,sp,#32
	      	sw   	r11,[sp]
	      	sw   	r12,8[sp]
	      	sw   	r13,16[sp]
	      	sw   	r14,24[sp]
	      	subui	sp,sp,#16
	      	sws  	br9,[sp]
	      	sws  	br10,8[sp]
	      	ldis 	br9,#pacmanX
	      	ldis 	br10,#IsLegalPos
	      	ldi  	r3,#13631488
	      	sw   	r3,-48[bp]
	      	ldi  	r3,#0
	      	sw   	r3,score
	      	subui	sp,sp,#16
	      	sw   	r4,8[sp]
	      	sw   	r6,[sp]
	      	subui	sp,sp,#8
	      	ldi  	r3,#L_29
	      	sw   	r3,[sp]
	      	jsr  	printf
	      	addui	sp,sp,#8
	      	lw   	r4,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	subui	sp,sp,#8
	      	sw   	r6,[sp]
	      	jsr  	RedrawMap
	      	lw   	r6,[sp]
	      	addui	sp,sp,#8
	      	ldi  	r3,#0
	      	mov  	r13,r3
L_32:
	      	cmp  	p0,r13,#6
	p0.ge	bra  	L_33
	      	subui	sp,sp,#16
	      	sw   	r4,8[sp]
	      	sw   	r6,[sp]
	      	subui	sp,sp,#24
	      	ldi  	r3,#15
	      	sw   	r3,16[sp]
	      	ldi  	r3,#15
	      	sw   	r3,8[sp]
	      	sw   	r13,[sp]
	      	jsr  	setSpriteSize
	      	addui	sp,sp,#24
	      	lw   	r4,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	addui	r13,r13,#1
	      	bra  	L_32
L_33:
	      	subui	sp,sp,#8
	      	sw   	r6,[sp]
	      	subui	sp,sp,#8
	      	ldi  	r3,#0
	      	sw   	r3,[sp]
	      	jsr  	setKeyboardEcho
	      	addui	sp,sp,#8
	      	lw   	r6,[sp]
	      	addui	sp,sp,#8
	      	subui	sp,sp,#8
	      	sw   	r6,[sp]
	      	jsr  	resetGhosts
	      	lw   	r6,[sp]
	      	addui	sp,sp,#8
	      	subui	sp,sp,#8
	      	sw   	r6,[sp]
	      	subui	sp,sp,#8
	      	ldi  	r3,#0
	      	sw   	r3,[sp]
	      	jsr  	setRandDir
	      	addui	sp,sp,#8
	      	lw   	r6,[sp]
	      	addui	sp,sp,#8
	      	subui	sp,sp,#8
	      	sw   	r6,[sp]
	      	subui	sp,sp,#8
	      	ldi  	r3,#1
	      	sw   	r3,[sp]
	      	jsr  	setRandDir
	      	addui	sp,sp,#8
	      	lw   	r6,[sp]
	      	addui	sp,sp,#8
	      	subui	sp,sp,#8
	      	sw   	r6,[sp]
	      	subui	sp,sp,#8
	      	ldi  	r3,#2
	      	sw   	r3,[sp]
	      	jsr  	setRandDir
	      	addui	sp,sp,#8
	      	lw   	r6,[sp]
	      	addui	sp,sp,#8
	      	subui	sp,sp,#8
	      	sw   	r6,[sp]
	      	subui	sp,sp,#8
	      	ldi  	r3,#3
	      	sw   	r3,[sp]
	      	jsr  	setRandDir
	      	addui	sp,sp,#8
	      	lw   	r6,[sp]
	      	addui	sp,sp,#8
	      	subui	sp,sp,#8
	      	sw   	r6,[sp]
	      	jsr  	resetPacman
	      	lw   	r6,[sp]
	      	addui	sp,sp,#8
	      	subui	sp,sp,#8
	      	sw   	r6,[sp]
	      	jsr  	turnOnSprites
	      	lw   	r6,[sp]
	      	addui	sp,sp,#8
L_34:
	      	ldi  	r3,#0
	      	mov  	r13,r3
L_36:
	      	cmp  	p0,r13,#4
	p0.ge	bra  	L_37
	      	subui	sp,sp,#16
	      	sw   	r4,8[sp]
	      	sw   	r6,[sp]
	      	subui	sp,sp,#8
	      	sw   	r13,[sp]
	      	jsr  	moveGhost
	      	addui	sp,sp,#8
	      	lw   	r4,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	addui	r13,r13,#1
	      	bra  	L_36
L_37:
	      	subui	sp,sp,#16
	      	sw   	r4,8[sp]
	      	sw   	r6,[sp]
	      	jsr  	getchar2
	      	lw   	r4,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	mov  	r14,r1
	      	or   	r1,r14,r0
	      	cmp  	p0,r1,#113
	p0.eq	bra  	L_39
	      	cmp  	p0,r1,#81
	p0.eq	bra  	L_39
	      	cmp  	p0,r1,#144
	p0.eq	bra  	L_40
	      	cmp  	p0,r1,#147
	p0.eq	bra  	L_41
	      	cmp  	p0,r1,#145
	p0.eq	bra  	L_42
	      	cmp  	p0,r1,#146
	p0.eq	bra  	L_43
	      	bra  	L_38
L_39:
	      	bra  	L_30
L_40:
	      	lc   	r3,pacmanY
	      	subu 	r4,r3,#4
	      	mov  	r12,r4
	      	subui	sp,sp,#16
	      	sw   	r5,8[sp]
	      	sw   	r6,[sp]
	      	subui	sp,sp,#16
	      	sw   	r12,8[sp]
	      	lw   	r3,br9
	      	lc   	r3,[r3]
	      	sw   	r3,[sp]
	      	jsr  	lr,[br10]
	      	addui	sp,sp,#16
	      	lw   	r5,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	tst  	p1,r1
	p1.ne	sc   	r12,pacmanY
L_44:
	      	bra  	L_38
L_41:
	      	lw   	r3,br9
	      	lc   	r3,[r3]
	      	subu 	r4,r3,#4
	      	mov  	r11,r4
	      	subui	sp,sp,#16
	      	sw   	r5,8[sp]
	      	sw   	r6,[sp]
	      	subui	sp,sp,#16
	      	lc   	r3,pacmanY
	      	sw   	r3,8[sp]
	      	sw   	r11,[sp]
	      	jsr  	lr,[br10]
	      	addui	sp,sp,#16
	      	lw   	r5,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	tst  	p1,r1
	p1.ne	lw   	r3,br9
	p1.ne	sc   	r11,[r3]
L_46:
	      	bra  	L_38
L_42:
	      	lw   	r3,br9
	      	lc   	r3,[r3]
	      	addu 	r4,r3,#4
	      	mov  	r11,r4
	      	subui	sp,sp,#16
	      	sw   	r5,8[sp]
	      	sw   	r6,[sp]
	      	subui	sp,sp,#16
	      	lc   	r3,pacmanY
	      	sw   	r3,8[sp]
	      	sw   	r11,[sp]
	      	jsr  	lr,[br10]
	      	addui	sp,sp,#16
	      	lw   	r5,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	tst  	p1,r1
	p1.ne	lw   	r3,br9
	p1.ne	sc   	r11,[r3]
L_48:
	      	bra  	L_38
L_43:
	      	lc   	r3,pacmanY
	      	addu 	r4,r3,#4
	      	mov  	r12,r4
	      	subui	sp,sp,#16
	      	sw   	r5,8[sp]
	      	sw   	r6,[sp]
	      	subui	sp,sp,#16
	      	sw   	r12,8[sp]
	      	lw   	r3,br9
	      	lc   	r3,[r3]
	      	sw   	r3,[sp]
	      	jsr  	lr,[br10]
	      	addui	sp,sp,#16
	      	lw   	r5,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	tst  	p1,r1
	p1.ne	sc   	r12,pacmanY
L_50:
	      	bra  	L_38
L_38:
	      	subui	sp,sp,#16
	      	sw   	r5,8[sp]
	      	sw   	r6,[sp]
	      	subui	sp,sp,#24
	      	lc   	r3,pacmanY
	      	sw   	r3,16[sp]
	      	lw   	r3,br9
	      	lc   	r3,[r3]
	      	sw   	r3,8[sp]
	      	ldi  	r3,#4
	      	sw   	r3,[sp]
	      	jsr  	setSpritePos
	      	addui	sp,sp,#24
	      	lw   	r5,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	lw   	r3,br9
	      	lc   	r3,[r3]
	      	subui	sp,sp,#24
	      	sw   	r4,16[sp]
	      	sw   	r5,8[sp]
	      	sw   	r6,[sp]
	      	jsr  	hSyncOffset
	      	lw   	r4,16[sp]
	      	lw   	r5,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#24
	      	subu 	r4,r3,r1
	      	shri 	r3,r4,#4
	      	mov  	r11,r3
	      	cmp  	p0,r11,#27
	p0.gt	ldi  	r3,#27
	p0.gt	mov  	r11,r3
L_52:
	      	lc   	r3,pacmanY
	      	subui	sp,sp,#16
	      	sw   	r4,8[sp]
	      	sw   	r6,[sp]
	      	jsr  	vSyncOffset
	      	lw   	r4,8[sp]
	      	lw   	r6,[sp]
	      	addui	sp,sp,#16
	      	subu 	r4,r3,r1
	      	shri 	r3,r4,#4
	      	mov  	r12,r3
	      	cmp  	p0,r12,#27
	p0.gt	ldi  	r3,#27
	p0.gt	mov  	r12,r3
L_54:
	      	mului	r3,r12,#54
	      	shli 	r4,r11,#1
	      	addu 	r5,r4,#map
	      	lc   	r3,[r5+r3]
	      	cmp  	p0,r3,#0
	p0.ne	bra  	L_56
	      	lw   	r3,score
	      	addui	r3,r3,#10
	      	sw   	r3,score
	      	ldi  	r3,#4
	      	mului	r4,r12,#54
	      	shli 	r5,r11,#1
	      	addu 	r6,r5,#map
	      	sc   	r3,[r6+r4]
	      	subui	sp,sp,#16
	      	sw   	r4,8[sp]
	      	sw   	r7,[sp]
	      	jsr  	RedrawMap
	      	lw   	r4,8[sp]
	      	lw   	r7,[sp]
	      	addui	sp,sp,#16
L_56:
	      	bra  	L_34
L_35:
L_30:
	      	subui	sp,sp,#16
	      	sw   	r4,8[sp]
	      	sw   	r7,[sp]
	      	subui	sp,sp,#8
	      	ldi  	r3,#1
	      	sw   	r3,[sp]
	      	jsr  	setKeyboardEcho
	      	addui	sp,sp,#8
	      	lw   	r4,8[sp]
	      	lw   	r7,[sp]
	      	addui	sp,sp,#16
L_58:
	      	lws  	br10,8[sp]
	      	lws  	br9,[sp]
	      	addui	sp,sp,#16
	      	lw   	r14,24[sp]
	      	lw   	r13,16[sp]
	      	lw   	r12,8[sp]
	      	lw   	r11,[sp]
	      	addui	sp,sp,#32
	      	mov  	sp,bp
	      	lw   	bp,[sp]
	      	lws  	xlr,8[sp]
	      	lws  	lr,16[sp]
	      	lws  	pregs,24[sp]
	      	addui	sp,sp,#32
	      	rts  
L_31:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	L_58
public hSyncOffset:
	      	ldi  	r1,#216
L_60:
	      	rts  
L_59:
public vSyncOffset:
	      	ldi  	r1,#18
L_62:
	      	rts  
L_61:
public IsLegalPos:
	      	subui	sp,sp,#32
	      	sw   	bp,[sp]
	      	sws  	xlr,8[sp]
	      	sws  	lr,16[sp]
	      	sws  	pregs,24[sp]
	      	ldis 	xlr,#L_63
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	sw   	r11,[sp]
	      	sw   	r12,8[sp]
	      	subui	sp,sp,#8
	      	sws  	br9,[sp]
	      	lw   	r3,32[bp]
	      	mov  	r11,r3
	      	lw   	r3,24[bp]
	      	mov  	r12,r3
	      	ldis 	br9,#map
	      	subui	sp,sp,#8
	      	sw   	r7,[sp]
	      	jsr  	hSyncOffset
	      	lw   	r7,[sp]
	      	addui	sp,sp,#8
	      	subu 	r3,r12,r1
	      	shri 	r4,r3,#4
	      	mov  	r12,r4
	      	subui	sp,sp,#16
	      	sw   	r5,8[sp]
	      	sw   	r7,[sp]
	      	jsr  	vSyncOffset
	      	lw   	r5,8[sp]
	      	lw   	r7,[sp]
	      	addui	sp,sp,#16
	      	subu 	r3,r11,r1
	      	shri 	r4,r3,#4
	      	mov  	r11,r4
	      	cmp  	p0,r12,#27
	p0.gt	ldi  	r3,#27
	p0.gt	mov  	r12,r3
L_64:
	      	cmp  	p0,r11,#27
	p0.gt	ldi  	r3,#27
	p0.gt	mov  	r11,r3
L_66:
	      	mului	r3,r11,#54
	      	shli 	r4,r12,#1
	      	lw   	r5,br9
	      	addu 	r6,r4,r5
	      	lc   	r3,[r6+r3]
	      	cmp  	p15,r3,#0
	p15.ne	ldi  	r3,#1
	p15.eq	ldi  	r3,#0
	      	mului	r5,r11,#54
	      	shli 	r4,r12,#1
	      	lw   	r7,br9
	      	addu 	r8,r4,r7
	      	lc   	r5,[r8+r5]
	      	cmp  	p15,r5,#2
	p15.ne	ldi  	r5,#1
	p15.eq	ldi  	r5,#0
	      	or   	r7,r3,r5
	      	tst  	p15,r7
	p15.ne	ldi  	r3,#1
	p15.eq	ldi  	r3,#0
	      	mului	r5,r11,#54
	      	shli 	r7,r12,#1
	      	lw   	r4,br9
	      	addu 	r9,r7,r4
	      	lc   	r5,[r9+r5]
	      	cmp  	p15,r5,#4
	p15.ne	ldi  	r5,#1
	p15.eq	ldi  	r5,#0
	      	or   	r4,r3,r5
	      	tst  	p15,r4
	p15.ne	ldi  	r3,#1
	p15.eq	ldi  	r3,#0
	      	mov  	r1,r3
L_68:
	      	lws  	br9,[sp]
	      	addui	sp,sp,#8
	      	lw   	r12,8[sp]
	      	lw   	r11,[sp]
	      	addui	sp,sp,#16
	      	mov  	sp,bp
	      	lw   	bp,[sp]
	      	lws  	xlr,8[sp]
	      	lws  	lr,16[sp]
	      	lws  	pregs,24[sp]
	      	addui	sp,sp,#32
	      	rts  
L_63:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	L_68
public resetPacman:
	      	ldi  	r3,#144
	      	subui	sp,sp,#32
	      	sw   	r4,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	jsr  	hSyncOffset
	      	lw   	r4,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#32
	      	addu 	r4,r3,r1
	      	sc   	r4,pacmanX
	      	ldi  	r3,#224
	      	subui	sp,sp,#40
	      	sw   	r4,32[sp]
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	jsr  	vSyncOffset
	      	lw   	r4,32[sp]
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#40
	      	addu 	r4,r3,r1
	      	sc   	r4,pacmanY
	      	subui	sp,sp,#32
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#24
	      	lc   	r3,pacmanY
	      	sw   	r3,16[sp]
	      	lc   	r3,pacmanX
	      	sw   	r3,8[sp]
	      	ldi  	r3,#4
	      	sw   	r3,[sp]
	      	jsr  	setSpritePos
	      	addui	sp,sp,#24
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#32
L_70:
	      	rts  
L_69:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	L_70
public resetGhosts:
	      	subui	sp,sp,#16
	      	sws  	br9,[sp]
	      	sws  	br10,8[sp]
	      	ldis 	br9,#sprY
	      	ldis 	br10,#sprX
	      	ldi  	r3,#208
	      	subui	sp,sp,#40
	      	sw   	r4,32[sp]
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	jsr  	hSyncOffset
	      	lw   	r4,32[sp]
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#40
	      	addu 	r4,r3,r1
	      	lw   	r3,br10
	      	sc   	r4,[r3]
	      	ldi  	r3,#224
	      	subui	sp,sp,#40
	      	sw   	r4,32[sp]
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	jsr  	vSyncOffset
	      	lw   	r4,32[sp]
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#40
	      	addu 	r4,r3,r1
	      	lw   	r3,br9
	      	sc   	r4,[r3]
	      	ldi  	r3,#224
	      	subui	sp,sp,#40
	      	sw   	r4,32[sp]
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	jsr  	hSyncOffset
	      	lw   	r4,32[sp]
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#40
	      	addu 	r4,r3,r1
	      	lw   	r3,br10
	      	sc   	r4,2[r3]
	      	ldi  	r3,#224
	      	subui	sp,sp,#40
	      	sw   	r4,32[sp]
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	jsr  	vSyncOffset
	      	lw   	r4,32[sp]
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#40
	      	addu 	r4,r3,r1
	      	lw   	r3,br9
	      	sc   	r4,2[r3]
	      	ldi  	r3,#240
	      	subui	sp,sp,#40
	      	sw   	r4,32[sp]
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	jsr  	hSyncOffset
	      	lw   	r4,32[sp]
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#40
	      	addu 	r4,r3,r1
	      	lw   	r3,br10
	      	sc   	r4,4[r3]
	      	ldi  	r3,#224
	      	subui	sp,sp,#40
	      	sw   	r4,32[sp]
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	jsr  	vSyncOffset
	      	lw   	r4,32[sp]
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#40
	      	addu 	r4,r3,r1
	      	lw   	r3,br9
	      	sc   	r4,4[r3]
	      	ldi  	r3,#256
	      	subui	sp,sp,#40
	      	sw   	r4,32[sp]
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	jsr  	hSyncOffset
	      	lw   	r4,32[sp]
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#40
	      	addu 	r4,r3,r1
	      	lw   	r3,br10
	      	sc   	r4,6[r3]
	      	ldi  	r3,#224
	      	subui	sp,sp,#40
	      	sw   	r4,32[sp]
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	jsr  	vSyncOffset
	      	lw   	r4,32[sp]
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#40
	      	addu 	r4,r3,r1
	      	lw   	r3,br9
	      	sc   	r4,6[r3]
	      	ldi  	r3,#0
	      	sc   	r3,sprDX
	      	ldi  	r3,#0
	      	sc   	r3,sprDY
	      	ldi  	r3,#0
	      	ldi  	r4,#sprDX
	      	sc   	r3,2[r4]
	      	ldi  	r3,#0
	      	ldi  	r4,#sprDY
	      	sc   	r3,2[r4]
	      	ldi  	r3,#0
	      	ldi  	r4,#sprDX
	      	sc   	r3,4[r4]
	      	ldi  	r3,#0
	      	ldi  	r4,#sprDY
	      	sc   	r3,4[r4]
	      	ldi  	r3,#0
	      	ldi  	r4,#sprDX
	      	sc   	r3,6[r4]
	      	ldi  	r3,#0
	      	ldi  	r4,#sprDY
	      	sc   	r3,6[r4]
	      	subui	sp,sp,#32
	      	sw   	r4,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#24
	      	lw   	r3,br9
	      	lc   	r3,[r3]
	      	sw   	r3,16[sp]
	      	lw   	r3,br10
	      	lc   	r3,[r3]
	      	sw   	r3,8[sp]
	      	ldi  	r3,#0
	      	sw   	r3,[sp]
	      	jsr  	setSpritePos
	      	addui	sp,sp,#24
	      	lw   	r4,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#32
	      	subui	sp,sp,#24
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#24
	      	lw   	r3,br9
	      	lc   	r3,2[r3]
	      	sw   	r3,16[sp]
	      	lw   	r3,br10
	      	lc   	r3,2[r3]
	      	sw   	r3,8[sp]
	      	ldi  	r3,#1
	      	sw   	r3,[sp]
	      	jsr  	setSpritePos
	      	addui	sp,sp,#24
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#24
	      	subui	sp,sp,#24
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#24
	      	lw   	r3,br9
	      	lc   	r3,4[r3]
	      	sw   	r3,16[sp]
	      	lw   	r3,br10
	      	lc   	r3,4[r3]
	      	sw   	r3,8[sp]
	      	ldi  	r3,#2
	      	sw   	r3,[sp]
	      	jsr  	setSpritePos
	      	addui	sp,sp,#24
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#24
	      	subui	sp,sp,#24
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#24
	      	lw   	r3,br9
	      	lc   	r3,6[r3]
	      	sw   	r3,16[sp]
	      	lw   	r3,br10
	      	lc   	r3,6[r3]
	      	sw   	r3,8[sp]
	      	ldi  	r3,#3
	      	sw   	r3,[sp]
	      	jsr  	setSpritePos
	      	addui	sp,sp,#24
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#24
L_72:
	      	lws  	br10,8[sp]
	      	lws  	br9,[sp]
	      	addui	sp,sp,#16
	      	rts  
L_71:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	L_72
public moveGhost:
	      	subui	sp,sp,#32
	      	sw   	bp,[sp]
	      	sws  	xlr,8[sp]
	      	sws  	lr,16[sp]
	      	sws  	pregs,24[sp]
	      	ldis 	xlr,#L_73
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	subui	sp,sp,#24
	      	sw   	r11,[sp]
	      	sw   	r12,8[sp]
	      	sw   	r13,16[sp]
	      	subui	sp,sp,#16
	      	sws  	br9,[sp]
	      	sws  	br10,8[sp]
	      	lw   	r3,24[bp]
	      	mov  	r11,r3
	      	ldis 	br9,#sprY
	      	ldis 	br10,#sprX
	      	shli 	r3,r11,#1
	      	lw   	r4,br10
	      	lc   	r3,[r4+r3]
	      	shli 	r5,r11,#1
	      	lc   	r5,sprDX[r5]
	      	addu 	r6,r3,r5
	      	mov  	r13,r6
	      	shli 	r3,r11,#1
	      	lw   	r4,br9
	      	lc   	r3,[r4+r3]
	      	shli 	r5,r11,#1
	      	lc   	r5,sprDY[r5]
	      	addu 	r6,r3,r5
	      	mov  	r12,r6
	      	subui	sp,sp,#32
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#16
	      	sw   	r12,8[sp]
	      	sw   	r13,[sp]
	      	jsr  	IsLegalPos
	      	addui	sp,sp,#16
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#32
	      	tst  	p0,r1
	p0.eq	bra  	L_74
	      	shli 	r3,r11,#1
	      	lw   	r4,br10
	      	sc   	r13,[r4+r3]
	      	shli 	r3,r11,#1
	      	lw   	r4,br9
	      	sc   	r12,[r4+r3]
	      	bra  	L_75
L_74:
	      	subui	sp,sp,#32
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#8
	      	sw   	r11,[sp]
	      	jsr  	setRandDir
	      	addui	sp,sp,#8
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#32
L_75:
	      	subui	sp,sp,#32
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#8
	      	ldi  	r3,#100
	      	sw   	r3,[sp]
	      	jsr  	rand
	      	addui	sp,sp,#8
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#32
	      	cmp  	p0,r1,#96
	p0.le	bra  	L_76
	      	subui	sp,sp,#32
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#8
	      	sw   	r11,[sp]
	      	jsr  	setRandDir
	      	addui	sp,sp,#8
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#32
L_76:
	      	subui	sp,sp,#32
	      	sw   	r5,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#24
	      	shli 	r3,r11,#1
	      	lw   	r4,br9
	      	lc   	r3,[r4+r3]
	      	sw   	r3,16[sp]
	      	shli 	r3,r11,#1
	      	lw   	r5,br10
	      	lc   	r3,[r5+r3]
	      	sw   	r3,8[sp]
	      	sw   	r11,[sp]
	      	jsr  	setSpritePos
	      	addui	sp,sp,#24
	      	lw   	r5,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#32
L_78:
	      	lws  	br10,8[sp]
	      	lws  	br9,[sp]
	      	addui	sp,sp,#16
	      	lw   	r13,16[sp]
	      	lw   	r12,8[sp]
	      	lw   	r11,[sp]
	      	addui	sp,sp,#24
	      	mov  	sp,bp
	      	lw   	bp,[sp]
	      	lws  	xlr,8[sp]
	      	lws  	lr,16[sp]
	      	lws  	pregs,24[sp]
	      	addui	sp,sp,#32
	      	rts  
L_73:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	L_78
public setSpritePos:
	      	subui	sp,sp,#32
	      	sw   	bp,[sp]
	      	sws  	xlr,8[sp]
	      	sws  	lr,16[sp]
	      	sws  	pregs,24[sp]
	      	ldis 	xlr,#L_79
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	sw   	r5,32[sp]
	      	sw   	r6,24[sp]
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#16
	      	lw   	r3,40[bp]
	      	shli 	r4,r3,#16
	      	lw   	r3,32[bp]
	      	or   	r5,r4,r3
	      	sw   	r5,8[sp]
	      	ldi  	r5,#14340096
	      	lw   	r3,24[bp]
	      	shli 	r4,r3,#4
	      	addu 	r3,r5,r4
	      	sw   	r3,[sp]
	      	jsr  	outh
	      	addui	sp,sp,#16
	      	lw   	r5,32[sp]
	      	lw   	r6,24[sp]
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#40
L_80:
	      	mov  	sp,bp
	      	lw   	bp,[sp]
	      	lws  	xlr,8[sp]
	      	lws  	lr,16[sp]
	      	lws  	pregs,24[sp]
	      	addui	sp,sp,#32
	      	rts  
L_79:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	L_80
public setSpriteSize:
	      	subui	sp,sp,#32
	      	sw   	bp,[sp]
	      	sws  	xlr,8[sp]
	      	sws  	lr,16[sp]
	      	sws  	pregs,24[sp]
	      	ldis 	xlr,#L_81
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#16
	      	lw   	r3,40[bp]
	      	and  	r4,r3,#63
	      	shli 	r3,r4,#8
	      	lw   	r4,32[bp]
	      	and  	r5,r4,#63
	      	or   	r4,r3,r5
	      	sw   	r4,8[sp]
	      	ldi  	r4,#14340100
	      	lw   	r5,24[bp]
	      	shli 	r3,r5,#4
	      	addu 	r5,r4,r3
	      	sw   	r5,[sp]
	      	jsr  	outh
	      	addui	sp,sp,#16
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#24
L_82:
	      	mov  	sp,bp
	      	lw   	bp,[sp]
	      	lws  	xlr,8[sp]
	      	lws  	lr,16[sp]
	      	lws  	pregs,24[sp]
	      	addui	sp,sp,#32
	      	rts  
L_81:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	L_82
public turnOnSprites:
	      	subui	sp,sp,#24
	      	sw   	r7,16[sp]
	      	sw   	r9,8[sp]
	      	sw   	r10,[sp]
	      	subui	sp,sp,#16
	      	ldi  	r3,#255
	      	sw   	r3,8[sp]
	      	ldi  	r3,#14340336
	      	sw   	r3,[sp]
	      	jsr  	outb
	      	addui	sp,sp,#16
	      	lw   	r7,16[sp]
	      	lw   	r9,8[sp]
	      	lw   	r10,[sp]
	      	addui	sp,sp,#24
L_84:
	      	rts  
L_83:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	L_84
public setKeyboardEcho:
	      	subui	sp,sp,#32
	      	sw   	bp,[sp]
	      	sws  	pregs,24[sp]
	      	mov  	bp,sp
	      	     			lw		r1,#0x01
		lw		r2,24[bp]
		syscall	#417
	
L_86:
	      	mov  	sp,bp
	      	lw   	bp,[sp]
	      	lws  	pregs,24[sp]
	      	addui	sp,sp,#32
	      	rts  
L_85:
public setCursorPos:
	      	subui	sp,sp,#32
	      	sw   	bp,[sp]
	      	sws  	pregs,24[sp]
	      	mov  	bp,sp
	      	     			lw		r1,#0x02
		lw		r2,24[bp]
		lw		r3,32[bp]
		syscall	#410
	
L_88:
	      	mov  	sp,bp
	      	lw   	bp,[sp]
	      	lws  	pregs,24[sp]
	      	addui	sp,sp,#32
	      	rts  
L_87:
	align	8
L_29:	; 


























	dc	13,10,10,10,10,10,10,10
	dc	10,10,10,10,10,10,10,10
	dc	10,10,10,10,10,10,10,10
	dc	10,10,10,0
;	global	fread
;	global	fsetpos
;	global	sprintf
;	global	fgetc
;	global	vprintf
;	global	scanf
;	global	AsciiToScreen
;	global	fseek
	extern	getchar2
;	global	ftell
;	global	fopen
;	global	srand
;	global	fgets
;	global	score
;	global	fputc
;	global	putch
;	global	fputs
;	global	inb
;	global	map
;	global	inw
;	global	clearerr
	extern	_Files
;	global	_Fgpos
;	global	setSpriteSize
;	global	MapToChar
;	global	_Fspos
;	global	hSyncOffset
;	global	vfprintf
;	global	turnOnSprites
;	global	fscanf
;	global	resetPacman
;	global	rename
;	global	vSyncOffset
;	global	fclose
;	global	sscanf
;	global	RedrawMap
;	global	ungetc
;	global	fflush
;	global	rewind
;	global	setbuf
;	global	tmpnam
;	global	remove
;	global	ferror
;	global	fwrite
;	global	printf
;	global	perror
;	global	resetGhosts
;	global	feof
;	global	inch
;	global	getc
;	global	rand
;	global	main
;	global	putnum
;	global	sprX
;	global	inbu
;	global	sprY
;	global	incu
;	global	putstr
;	global	gets
;	global	outb
;	global	outc
;	global	putc
;	global	moveGhost
;	global	outh
;	global	pacmanX
;	global	pacmanY
;	global	puts
;	global	outw
;	global	IsLegalPos
;	global	getchar
;	global	freopen
;	global	setRandDir
;	global	tmpfile
;	global	sprDX
;	global	sprDY
;	global	setSpritePos
;	global	putchar
;	global	fgetpos
;	global	fprintf
;	global	setCursorPos
;	global	setKeyboardEcho
;	global	setvbuf
