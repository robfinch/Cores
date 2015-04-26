	data
	align	8
	fill.b	1,0x00
	align	8
	fill.b	16,0x00
	align	8
	fill.b	1984,0x00
	align	8
	align	8
	code
	align	16
public code GetScreenLocation_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_0
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	lw   	r3,1616[r3]
	      	mov  	r1,r3
console_2:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_0:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_2
endpublic

public code GetCurrAttr_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_3
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	lh   	r3,1640[r3]
	      	mov  	r1,r3
console_5:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_3:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_5
endpublic

public code SetCurrAttr_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_6
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	lh   	r5,24[bp]
	      	and  	r4,r5,#4294966272
	      	andi 	r4,r4,#4294967295
	      	sh   	r4,1640[r3]
console_8:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_6:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_8
endpublic

SetVideoReg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_11
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	blt  	r3,console_15
	      	lw   	r3,24[bp]
	      	cmp  	r4,r3,#11
	      	ble  	r4,console_13
console_15:
	      	push 	24[bp]
	      	pea  	console_10[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
console_16:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#16
console_13:
	      	     	         lw   r1,24[bp]
         lw   r2,32[bp]
         asl  r1,r1,#2
         sh   r2,$FFDA0000[r1]
     
	      	bra  	console_16
console_11:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_16
public code SetCursorPos_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_17
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lw   	r3,32[bp]
	      	andi 	r3,r3,#65535
	      	sc   	r3,1638[r11]
	      	lw   	r3,24[bp]
	      	andi 	r3,r3,#65535
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos_
console_19:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_17:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_19
endpublic

public code SetCursorCol_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_20
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lw   	r3,24[bp]
	      	andi 	r3,r3,#65535
	      	sc   	r3,1638[r11]
	      	bsr  	UpdateCursorPos_
console_22:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_20:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_22
endpublic

public code GetCursorPos_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_23
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lc   	r4,1638[r11]
	      	lc   	r6,1636[r11]
	      	asli 	r5,r6,#8
	      	or   	r3,r4,r5
	      	mov  	r1,r3
console_25:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_23:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_25
endpublic

public code GetTextCols_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_26
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	lc   	r3,1634[r3]
	      	mov  	r1,r3
console_28:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_26:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_28
endpublic

public code GetTextRows_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_29
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	lc   	r3,1632[r3]
	      	mov  	r1,r3
console_31:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_29:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_31
endpublic

public code AsciiToScreen_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#91
	      	bne  	r4,console_34
	      	ldi  	r1,#27
console_36:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
console_34:
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#93
	      	bne  	r4,console_37
	      	ldi  	r1,#29
	      	bra  	console_36
console_37:
	      	lc   	r3,24[bp]
	      	andi 	r3,r3,#255
	      	sc   	r3,24[bp]
	      	lc   	r3,24[bp]
	      	ori  	r3,r3,#256
	      	sc   	r3,24[bp]
	      	lc   	r4,24[bp]
	      	and  	r3,r4,#32
	      	bne  	r3,console_39
	      	lc   	r3,24[bp]
	      	mov  	r1,r3
	      	bra  	console_36
console_39:
	      	lc   	r4,24[bp]
	      	and  	r3,r4,#64
	      	bne  	r3,console_41
	      	lc   	r3,24[bp]
	      	mov  	r1,r3
	      	bra  	console_36
console_41:
	      	lc   	r4,24[bp]
	      	and  	r3,r4,#415
	      	andi 	r3,r3,#65535
	      	sc   	r3,24[bp]
	      	lc   	r3,24[bp]
	      	mov  	r1,r3
	      	bra  	console_36
endpublic

public code ScreenToAscii_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	andi 	r3,r3,#255
	      	sc   	r3,24[bp]
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#27
	      	bne  	r4,console_45
	      	ldi  	r1,#91
console_47:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
console_45:
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#29
	      	bne  	r4,console_48
	      	ldi  	r1,#93
	      	bra  	console_47
console_48:
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#27
	      	bge  	r4,console_50
	      	lc   	r3,24[bp]
	      	addui	r3,r3,#96
	      	sc   	r3,24[bp]
console_50:
	      	lc   	r3,24[bp]
	      	mov  	r1,r3
	      	bra  	console_47
endpublic

public code UpdateCursorPos_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_52
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lc   	r5,1636[r11]
	      	lc   	r6,1634[r11]
	      	mulu 	r4,r5,r6
	      	lc   	r5,1638[r11]
	      	addu 	r3,r4,r5
	      	sxc  	r3,r3
	      	sw   	r3,-16[bp]
	      	push 	-16[bp]
	      	push 	#11
	      	bsr  	SetVideoReg_
console_54:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_52:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_54
endpublic

public code HomeCursor_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_55
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	ldi  	r3,#0
	      	andi 	r3,r3,#65535
	      	sc   	r3,1638[r11]
	      	ldi  	r3,#0
	      	andi 	r3,r3,#65535
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos_
console_57:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_55:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_57
endpublic

public code CalcScreenLocation_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_58
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lc   	r5,1636[r11]
	      	lc   	r6,1634[r11]
	      	mulu 	r4,r5,r6
	      	lc   	r5,1638[r11]
	      	addu 	r3,r4,r5
	      	sxc  	r3,r3
	      	sw   	r3,-16[bp]
	      	push 	-16[bp]
	      	push 	#11
	      	bsr  	SetVideoReg_
	      	push 	r3
	      	bsr  	GetScreenLocation_
	      	pop  	r3
	      	mov  	r4,r1
	      	lw   	r6,-16[bp]
	      	asli 	r5,r6,#2
	      	addu 	r3,r4,r5
	      	mov  	r1,r3
console_60:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_58:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_60
endpublic

public code ClearScreen_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_61
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	bsr  	GetScreenLocation_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lc   	r4,1632[r11]
	      	lc   	r5,1634[r11]
	      	mul  	r3,r4,r5
	      	sw   	r3,-24[bp]
	      	push 	r3
	      	bsr  	GetCurrAttr_
	      	pop  	r3
	      	mov  	r4,r1
	      	push 	r3
	      	push 	r4
	      	push 	#32
	      	bsr  	AsciiToScreen_
	      	addui	sp,sp,#8
	      	pop  	r4
	      	pop  	r3
	      	mov  	r5,r1
	      	sxc  	r5,r5
	      	or   	r3,r4,r5
	      	sh   	r3,-36[bp]
	      	push 	-24[bp]
	      	lh   	r3,-36[bp]
	      	sxh  	r3,r3
	      	push 	r3
	      	push 	-8[bp]
	      	bsr  	memsetH_
	      	addui	sp,sp,#24
console_63:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_61:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_63
endpublic

public code ClearBmpScreen_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_64
	      	mov  	bp,sp
	      	push 	#524288
	      	push 	#0
	      	push 	#4194304
	      	bsr  	memsetW_
	      	addui	sp,sp,#24
console_66:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_64:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_66
endpublic

public code BlankLine_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_67
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	bsr  	GetScreenLocation_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r4,-8[bp]
	      	lc   	r7,1634[r11]
	      	lw   	r8,24[bp]
	      	mul  	r6,r7,r8
	      	asli 	r5,r6,#2
	      	addu 	r3,r4,r5
	      	sw   	r3,-8[bp]
	      	push 	r3
	      	bsr  	GetCurrAttr_
	      	pop  	r3
	      	mov  	r4,r1
	      	push 	r3
	      	push 	r4
	      	push 	#32
	      	bsr  	AsciiToScreen_
	      	addui	sp,sp,#8
	      	pop  	r4
	      	pop  	r3
	      	mov  	r5,r1
	      	sxc  	r5,r5
	      	or   	r3,r4,r5
	      	sh   	r3,-36[bp]
	      	lc   	r3,1634[r11]
	      	push 	r3
	      	lh   	r3,-36[bp]
	      	sxh  	r3,r3
	      	push 	r3
	      	push 	-8[bp]
	      	bsr  	memsetH_
	      	addui	sp,sp,#24
console_69:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_67:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_69
endpublic

public code ScrollUp_:
	      	     	         push  lr
         bsr   VBScrollUp
         rts
     
endpublic

public code IncrementCursorRow_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_73
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lc   	r3,1636[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	lc   	r3,1636[r11]
	      	lc   	r4,1632[r11]
	      	cmpu 	r5,r3,r4
	      	bge  	r5,console_75
	      	bsr  	UpdateCursorPos_
console_77:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_75:
	      	lc   	r3,1636[r11]
	      	subui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos_
	      	bsr  	ScrollUp_
	      	bra  	console_77
console_73:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_77
endpublic

public code IncrementCursorPos_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_78
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lc   	r3,1638[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1638[r11]
	      	lc   	r3,1638[r11]
	      	lc   	r4,1634[r11]
	      	cmpu 	r5,r3,r4
	      	bge  	r5,console_80
	      	bsr  	UpdateCursorPos_
console_82:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_80:
	      	ldi  	r3,#0
	      	andi 	r3,r3,#65535
	      	sc   	r3,1638[r11]
	      	bsr  	IncrementCursorRow_
	      	bra  	console_82
console_78:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_82
endpublic

public code DisplayChar_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_83
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#13
	      	beq  	r4,console_86
	      	cmp  	r4,r3,#10
	      	beq  	r4,console_87
	      	cmp  	r4,r3,#145
	      	beq  	r4,console_88
	      	cmp  	r4,r3,#144
	      	beq  	r4,console_89
	      	cmp  	r4,r3,#147
	      	beq  	r4,console_90
	      	cmp  	r4,r3,#146
	      	beq  	r4,console_91
	      	cmp  	r4,r3,#148
	      	beq  	r4,console_92
	      	cmp  	r4,r3,#153
	      	beq  	r4,console_93
	      	cmp  	r4,r3,#8
	      	beq  	r4,console_94
	      	cmp  	r4,r3,#12
	      	beq  	r4,console_95
	      	cmp  	r4,r3,#9
	      	beq  	r4,console_96
	      	bra  	console_97
console_86:
	      	ldi  	r3,#0
	      	andi 	r3,r3,#65535
	      	sc   	r3,1638[r11]
	      	bsr  	UpdateCursorPos_
	      	bra  	console_85
console_87:
	      	bsr  	IncrementCursorRow_
	      	bra  	console_85
console_88:
	      	lc   	r3,1638[r11]
	      	lc   	r5,1634[r11]
	      	subu 	r4,r5,#1
	      	cmpu 	r5,r3,r4
	      	bge  	r5,console_98
	      	lc   	r3,1638[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1638[r11]
	      	bsr  	UpdateCursorPos_
console_98:
	      	bra  	console_85
console_89:
	      	lc   	r3,1636[r11]
	      	cmpu 	r4,r3,#0
	      	ble  	r4,console_100
	      	lc   	r3,1636[r11]
	      	subui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos_
console_100:
	      	bra  	console_85
console_90:
	      	lc   	r3,1638[r11]
	      	cmpu 	r4,r3,#0
	      	ble  	r4,console_102
	      	lc   	r3,1638[r11]
	      	subui	r3,r3,#1
	      	sc   	r3,1638[r11]
	      	bsr  	UpdateCursorPos_
console_102:
	      	bra  	console_85
console_91:
	      	lc   	r3,1636[r11]
	      	lc   	r5,1632[r11]
	      	subu 	r4,r5,#1
	      	cmpu 	r5,r3,r4
	      	bge  	r5,console_104
	      	lc   	r3,1636[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos_
console_104:
	      	bra  	console_85
console_92:
	      	lc   	r3,1638[r11]
	      	bne  	r3,console_106
	      	ldi  	r3,#0
	      	andi 	r3,r3,#65535
	      	sc   	r3,1636[r11]
console_106:
	      	ldi  	r3,#0
	      	andi 	r3,r3,#65535
	      	sc   	r3,1638[r11]
	      	bsr  	UpdateCursorPos_
	      	bra  	console_85
console_93:
	      	bsr  	CalcScreenLocation_
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	lc   	r3,1638[r11]
	      	sw   	r3,-16[bp]
console_108:
	      	lw   	r3,-16[bp]
	      	lc   	r5,1634[r11]
	      	subu 	r4,r5,#1
	      	cmp  	r5,r3,r4
	      	bge  	r5,console_109
	      	lw   	r5,-16[bp]
	      	lc   	r6,1638[r11]
	      	subu 	r4,r5,r6
	      	asli 	r3,r4,#2
	      	lw   	r7,-16[bp]
	      	lc   	r8,1638[r11]
	      	subu 	r6,r7,r8
	      	asli 	r5,r6,#2
	      	addu 	r4,r5,r12
	      	lh   	r5,4[r4]
	      	sh   	r5,0[r12+r3]
console_110:
	      	inc  	-16[bp],#1
	      	bra  	console_108
console_109:
	      	lw   	r5,-16[bp]
	      	lc   	r6,1638[r11]
	      	subu 	r4,r5,r6
	      	asli 	r3,r4,#2
	      	push 	r3
	      	push 	r4
	      	bsr  	GetCurrAttr_
	      	pop  	r4
	      	pop  	r3
	      	mov  	r5,r1
	      	push 	r3
	      	push 	r4
	      	push 	r5
	      	push 	#32
	      	bsr  	AsciiToScreen_
	      	addui	sp,sp,#8
	      	pop  	r5
	      	pop  	r4
	      	pop  	r3
	      	mov  	r6,r1
	      	sxc  	r6,r6
	      	or   	r4,r5,r6
	      	sh   	r4,0[r12+r3]
	      	bra  	console_85
console_94:
	      	lc   	r3,1638[r11]
	      	cmpu 	r4,r3,#0
	      	ble  	r4,console_111
	      	lc   	r3,1638[r11]
	      	subui	r3,r3,#1
	      	sc   	r3,1638[r11]
	      	bsr  	CalcScreenLocation_
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	lc   	r3,1638[r11]
	      	sw   	r3,-16[bp]
console_113:
	      	lw   	r3,-16[bp]
	      	lc   	r5,1634[r11]
	      	subu 	r4,r5,#1
	      	cmp  	r5,r3,r4
	      	bge  	r5,console_114
	      	lw   	r5,-16[bp]
	      	lc   	r6,1638[r11]
	      	subu 	r4,r5,r6
	      	asli 	r3,r4,#2
	      	lw   	r7,-16[bp]
	      	lc   	r8,1638[r11]
	      	subu 	r6,r7,r8
	      	asli 	r5,r6,#2
	      	addu 	r4,r5,r12
	      	lh   	r5,4[r4]
	      	sh   	r5,0[r12+r3]
console_115:
	      	inc  	-16[bp],#1
	      	bra  	console_113
console_114:
	      	lw   	r5,-16[bp]
	      	lc   	r6,1638[r11]
	      	subu 	r4,r5,r6
	      	asli 	r3,r4,#2
	      	push 	r3
	      	push 	r4
	      	bsr  	GetCurrAttr_
	      	pop  	r4
	      	pop  	r3
	      	mov  	r5,r1
	      	push 	r3
	      	push 	r4
	      	push 	r5
	      	push 	#32
	      	bsr  	AsciiToScreen_
	      	addui	sp,sp,#8
	      	pop  	r5
	      	pop  	r4
	      	pop  	r3
	      	mov  	r6,r1
	      	sxc  	r6,r6
	      	or   	r4,r5,r6
	      	sh   	r4,0[r12+r3]
console_111:
	      	bra  	console_85
console_95:
	      	bsr  	ClearScreen_
	      	bsr  	HomeCursor_
	      	bra  	console_85
console_96:
	      	push 	#32
	      	bsr  	DisplayChar_
	      	addui	sp,sp,#8
	      	push 	#32
	      	bsr  	DisplayChar_
	      	addui	sp,sp,#8
	      	push 	#32
	      	bsr  	DisplayChar_
	      	addui	sp,sp,#8
	      	push 	#32
	      	bsr  	DisplayChar_
	      	addui	sp,sp,#8
	      	bra  	console_85
console_97:
	      	bsr  	CalcScreenLocation_
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	push 	r3
	      	bsr  	GetCurrAttr_
	      	pop  	r3
	      	mov  	r4,r1
	      	push 	r3
	      	push 	r4
	      	lc   	r5,24[bp]
	      	push 	r5
	      	bsr  	AsciiToScreen_
	      	addui	sp,sp,#8
	      	pop  	r4
	      	pop  	r3
	      	mov  	r5,r1
	      	sxc  	r5,r5
	      	or   	r3,r4,r5
	      	sh   	r3,[r12]
	      	bsr  	IncrementCursorPos_
	      	bra  	console_85
console_85:
console_116:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_83:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_116
endpublic

public code CRLF_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_117
	      	mov  	bp,sp
	      	push 	#13
	      	bsr  	DisplayChar_
	      	addui	sp,sp,#8
	      	push 	#10
	      	bsr  	DisplayChar_
	      	addui	sp,sp,#8
console_119:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_117:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_119
endpublic

public code DisplayString_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_120
	      	mov  	bp,sp
	      	push 	r11
	      	lw   	r11,24[bp]
console_122:
	      	lc   	r3,[r11]
	      	beq  	r3,console_123
	      	lc   	r3,[r11]
	      	push 	r3
	      	bsr  	DisplayChar_
	      	addui	sp,sp,#8
	      	addui	r11,r11,#2
	      	bra  	console_122
console_123:
console_124:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_120:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_124
endpublic

public code DisplayStringCRLF_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_125
	      	mov  	bp,sp
	      	push 	24[bp]
	      	bsr  	DisplayString_
	      	addui	sp,sp,#8
	      	bsr  	CRLF_
console_127:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_125:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_127
endpublic

	rodata
	align	16
	align	8
console_10:
	dc	98,97,100,32,118,105,100,101
	dc	111,32,114,101,103,110,111,58
	dc	32,37,100,0
;	global	GetScreenLocation_
;	global	outb_
;	global	outc_
;	global	outh_
	extern	IOFocusNdx_
	extern	DumpTaskList_
;	global	SetCursorCol_
;	global	outw_
;	global	GetCursorPos_
	extern	memsetH_
	extern	GetRunningTCB_
;	global	SetCursorPos_
	extern	memsetW_
;	global	SetRunningTCB_
;	global	HomeCursor_
;	global	AsciiToScreen_
;	global	ScreenToAscii_
;	global	CalcScreenLocation_
;	global	chkTCB_
	extern	GetRunningTCBPtr_
;	global	UnlockSemaphore_
;	global	UpdateCursorPos_
	extern	GetVecno_
	extern	GetJCBPtr_
;	global	CRLF_
	extern	getCPU_
;	global	LockSemaphore_
;	global	ScrollUp_
;	global	set_vector_
;	global	ClearScreen_
;	global	DisplayString_
;	global	DisplayChar_
;	global	IncrementCursorPos_
;	global	GetTextCols_
;	global	GetCurrAttr_
;	global	IncrementCursorRow_
;	global	SetCurrAttr_
;	global	ClearBmpScreen_
;	global	GetTextRows_
;	global	BlankLine_
;	global	DisplayStringCRLF_
;	global	RemoveFromTimeoutList_
;	global	SetBound50_
;	global	SetBound51_
;	global	SetBound48_
;	global	SetBound49_
;	global	InsertIntoTimeoutList_
;	global	RemoveFromReadyList_
	extern	printf_
;	global	InsertIntoReadyList_
