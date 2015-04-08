	code
	align	16
public code GetScreenLocation:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_0
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	lw   	r3,1616[r3]
	      	mov  	r1,r3
console_1:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_0:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_1
endpublic

public code GetCurrAttr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_2
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	lhu  	r3,1640[r3]
	      	mov  	r1,r3
console_3:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_2:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_3
endpublic

public code SetCurrAttr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_4
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	lhu  	r4,24[bp]
	      	sh   	r4,1640[r3]
console_5:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_4:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_5
endpublic

public code SetVideoReg:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw   r1,24[bp]
         lw   r2,32[bp]
         asl  r1,r1,#2
         sh   r2,$FFDA0000[r1]
     
console_7:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code SetCursorPos:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_8
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lw   	r3,32[bp]
	      	sc   	r3,1638[r11]
	      	lw   	r3,24[bp]
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos
console_9:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_8:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_9
endpublic

public code SetCursorCol:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_10
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lw   	r3,24[bp]
	      	sc   	r3,1638[r11]
	      	bsr  	UpdateCursorPos
console_11:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_10:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_11
endpublic

public code GetCursorPos:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_12
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lcu  	r3,1638[r11]
	      	lcu  	r4,1636[r11]
	      	asli 	r4,r4,#8
	      	or   	r3,r3,r4
	      	mov  	r1,r3
console_13:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_12:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_13
endpublic

public code AsciiToScreen:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmp  	r3,r3,#91
	      	bne  	r3,console_15
	      	ldi  	r1,#27
console_17:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
console_15:
	      	lcu  	r3,24[bp]
	      	cmp  	r3,r3,#93
	      	bne  	r3,console_18
	      	ldi  	r1,#29
	      	bra  	console_17
console_18:
	      	lcu  	r3,24[bp]
	      	andi 	r3,r3,#255
	      	sc   	r3,24[bp]
	      	lcu  	r3,24[bp]
	      	ori  	r3,r3,#256
	      	sc   	r3,24[bp]
	      	lcu  	r3,24[bp]
	      	and  	r3,r3,#32
	      	bne  	r3,console_20
	      	lcu  	r3,24[bp]
	      	mov  	r1,r3
	      	bra  	console_17
console_20:
	      	lcu  	r3,24[bp]
	      	and  	r3,r3,#64
	      	bne  	r3,console_22
	      	lcu  	r3,24[bp]
	      	mov  	r1,r3
	      	bra  	console_17
console_22:
	      	lcu  	r3,24[bp]
	      	and  	r3,r3,#415
	      	sc   	r3,24[bp]
	      	lcu  	r3,24[bp]
	      	mov  	r1,r3
	      	bra  	console_17
endpublic

public code ScreenToAscii:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	andi 	r3,r3,#255
	      	sc   	r3,24[bp]
	      	lcu  	r3,24[bp]
	      	cmp  	r3,r3,#27
	      	bne  	r3,console_25
	      	ldi  	r1,#91
console_27:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
console_25:
	      	lcu  	r3,24[bp]
	      	cmp  	r3,r3,#29
	      	bne  	r3,console_28
	      	ldi  	r1,#93
	      	bra  	console_27
console_28:
	      	lcu  	r3,24[bp]
	      	cmpu 	r3,r3,#27
	      	bge  	r3,console_30
	      	lcu  	r3,24[bp]
	      	addui	r3,r3,#96
	      	sc   	r3,24[bp]
console_30:
	      	lcu  	r3,24[bp]
	      	mov  	r1,r3
	      	bra  	console_27
endpublic

public code UpdateCursorPos:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_32
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lcu  	r3,1636[r11]
	      	lcu  	r4,1634[r11]
	      	mulu 	r3,r3,r4
	      	lcu  	r4,1638[r11]
	      	addu 	r3,r3,r4
	      	sxc  	r3,r3
	      	sw   	r3,-16[bp]
	      	push 	-16[bp]
	      	push 	#11
	      	bsr  	SetVideoReg
	      	addui	sp,sp,#16
console_33:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_32:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_33
endpublic

public code HomeCursor:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_34
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	sc   	r0,1638[r11]
	      	sc   	r0,1636[r11]
	      	bsr  	UpdateCursorPos
console_35:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_34:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_35
endpublic

public code CalcScreenLocation:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_36
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lcu  	r3,1636[r11]
	      	lcu  	r4,1634[r11]
	      	mulu 	r3,r3,r4
	      	lcu  	r4,1638[r11]
	      	addu 	r3,r3,r4
	      	sxc  	r3,r3
	      	sw   	r3,-16[bp]
	      	push 	-16[bp]
	      	push 	#11
	      	bsr  	SetVideoReg
	      	addui	sp,sp,#16
	      	bsr  	GetScreenLocation
	      	mov  	r3,r1
	      	lw   	r4,-16[bp]
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	mov  	r1,r3
console_37:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_36:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_37
endpublic

public code ClearScreen:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_38
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	bsr  	GetScreenLocation
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lcu  	r3,1632[r11]
	      	lcu  	r4,1634[r11]
	      	mul  	r3,r3,r4
	      	sw   	r3,-24[bp]
	      	bsr  	GetCurrAttr
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#32
	      	bsr  	AsciiToScreen
	      	addui	sp,sp,#8
	      	pop  	r3
	      	mov  	r4,r1
	      	sxc  	r4,r4
	      	or   	r3,r3,r4
	      	sh   	r3,-36[bp]
	      	push 	-24[bp]
	      	lh   	r3,-36[bp]
	      	sxh  	r3,r3
	      	push 	r3
	      	push 	-8[bp]
	      	bsr  	memsetH
	      	addui	sp,sp,#24
console_39:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_38:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_39
endpublic

public code BlankLine:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_40
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	bsr  	GetScreenLocation
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	lcu  	r4,1634[r11]
	      	lw   	r5,24[bp]
	      	mul  	r4,r4,r5
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	sw   	r3,-8[bp]
	      	bsr  	GetCurrAttr
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#32
	      	bsr  	AsciiToScreen
	      	addui	sp,sp,#8
	      	pop  	r3
	      	mov  	r4,r1
	      	sxc  	r4,r4
	      	or   	r3,r3,r4
	      	sh   	r3,-36[bp]
	      	lcu  	r3,1634[r11]
	      	push 	r3
	      	lh   	r3,-36[bp]
	      	sxh  	r3,r3
	      	push 	r3
	      	push 	-8[bp]
	      	bsr  	memsetH
	      	addui	sp,sp,#24
console_41:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_40:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_41
endpublic

public code ScrollUp:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_42
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	bsr  	GetScreenLocation
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lcu  	r3,1632[r11]
	      	subu 	r3,r3,#1
	      	lcu  	r4,1634[r11]
	      	sxc  	r4,r4
	      	mul  	r3,r3,r4
	      	sw   	r3,-24[bp]
	      	push 	-24[bp]
	      	lcu  	r3,1634[r11]
	      	asli 	r3,r3,#2
	      	lw   	r4,-8[bp]
	      	addu 	r3,r3,r4
	      	push 	r3
	      	push 	-8[bp]
	      	bsr  	memcpyH
	      	addui	sp,sp,#24
	      	lcu  	r3,1632[r11]
	      	subu 	r3,r3,#1
	      	push 	r3
	      	bsr  	BlankLine
	      	addui	sp,sp,#8
console_43:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_42:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_43
endpublic

public code IncrementCursorPos:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_44
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lcu  	r3,1638[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1638[r11]
	      	lcu  	r3,1638[r11]
	      	lcu  	r4,1634[r11]
	      	cmpu 	r3,r3,r4
	      	bge  	r3,console_45
	      	bsr  	UpdateCursorPos
console_47:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_45:
	      	sc   	r0,1638[r11]
	      	lcu  	r3,1636[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	lcu  	r3,1636[r11]
	      	lcu  	r4,1632[r11]
	      	cmpu 	r3,r3,r4
	      	bge  	r3,console_48
	      	bsr  	UpdateCursorPos
	      	bra  	console_47
console_48:
	      	lcu  	r3,1636[r11]
	      	subui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	bsr  	ScrollUp
	      	bra  	console_47
console_44:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_47
endpublic

public code DisplayChar:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_50
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lcu  	r3,24[bp]
	      	cmp  	r4,r3,#13
	      	beq  	r4,console_52
	      	cmp  	r4,r3,#10
	      	beq  	r4,console_53
	      	cmp  	r4,r3,#145
	      	beq  	r4,console_54
	      	cmp  	r4,r3,#144
	      	beq  	r4,console_55
	      	cmp  	r4,r3,#147
	      	beq  	r4,console_56
	      	cmp  	r4,r3,#146
	      	beq  	r4,console_57
	      	cmp  	r4,r3,#148
	      	beq  	r4,console_58
	      	cmp  	r4,r3,#153
	      	beq  	r4,console_59
	      	cmp  	r4,r3,#8
	      	beq  	r4,console_60
	      	cmp  	r4,r3,#9
	      	beq  	r4,console_61
	      	bra  	console_62
console_52:
	      	sc   	r0,1638[r11]
	      	bsr  	UpdateCursorPos
	      	bra  	console_51
console_53:
	      	lcu  	r3,1636[r11]
	      	lcu  	r4,1632[r11]
	      	cmpu 	r3,r3,r4
	      	bge  	r3,console_63
	      	lcu  	r3,1636[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos
	      	bra  	console_64
console_63:
	      	bsr  	ScrollUp
console_64:
	      	bra  	console_51
console_54:
	      	lcu  	r3,1638[r11]
	      	lcu  	r4,1634[r11]
	      	cmpu 	r3,r3,r4
	      	bge  	r3,console_65
	      	lcu  	r3,1638[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1638[r11]
	      	bsr  	UpdateCursorPos
console_65:
	      	bra  	console_51
console_55:
	      	lcu  	r3,1636[r11]
	      	cmpu 	r3,r3,#0
	      	ble  	r3,console_67
	      	lcu  	r3,1636[r11]
	      	subui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos
console_67:
	      	bra  	console_51
console_56:
	      	lcu  	r3,1638[r11]
	      	cmpu 	r3,r3,#0
	      	ble  	r3,console_69
	      	lcu  	r3,1638[r11]
	      	subui	r3,r3,#1
	      	sc   	r3,1638[r11]
	      	bsr  	UpdateCursorPos
console_69:
	      	bra  	console_51
console_57:
	      	lcu  	r3,1636[r11]
	      	lcu  	r4,1632[r11]
	      	cmpu 	r3,r3,r4
	      	bge  	r3,console_71
	      	lcu  	r3,1636[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos
console_71:
	      	bra  	console_51
console_58:
	      	lcu  	r3,1638[r11]
	      	bne  	r3,console_73
	      	sc   	r0,1636[r11]
console_73:
	      	sc   	r0,1638[r11]
	      	bsr  	UpdateCursorPos
	      	bra  	console_51
console_59:
	      	bsr  	CalcScreenLocation
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	lcu  	r3,1638[r11]
	      	sxc  	r3,r3
	      	sw   	r3,-16[bp]
console_75:
	      	lw   	r3,-16[bp]
	      	lcu  	r4,1634[r11]
	      	subu 	r4,r4,#1
	      	cmp  	r3,r3,r4
	      	bge  	r3,console_76
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#2
	      	addu 	r3,r3,r12
	      	lw   	r4,-16[bp]
	      	asli 	r4,r4,#2
	      	lh   	r5,4[r3]
	      	sh   	r5,0[r12+r4]
console_77:
	      	inc  	-16[bp],#1
	      	bra  	console_75
console_76:
	      	bsr  	GetCurrAttr
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#32
	      	bsr  	AsciiToScreen
	      	addui	sp,sp,#8
	      	pop  	r3
	      	mov  	r4,r1
	      	sxc  	r4,r4
	      	or   	r3,r3,r4
	      	lw   	r4,-16[bp]
	      	asli 	r4,r4,#2
	      	sh   	r3,0[r12+r4]
	      	bra  	console_51
console_60:
	      	lcu  	r3,1638[r11]
	      	cmpu 	r3,r3,#0
	      	ble  	r3,console_78
	      	lcu  	r3,1638[r11]
	      	subui	r3,r3,#1
	      	sc   	r3,1638[r11]
	      	bsr  	CalcScreenLocation
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	lcu  	r3,1638[r11]
	      	sxc  	r3,r3
	      	sw   	r3,-16[bp]
console_80:
	      	lw   	r3,-16[bp]
	      	lcu  	r4,1634[r11]
	      	subu 	r4,r4,#1
	      	cmp  	r3,r3,r4
	      	bge  	r3,console_81
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#2
	      	addu 	r3,r3,r12
	      	lw   	r4,-16[bp]
	      	asli 	r4,r4,#2
	      	lh   	r5,4[r3]
	      	sh   	r5,0[r12+r4]
console_82:
	      	inc  	-16[bp],#1
	      	bra  	console_80
console_81:
	      	bsr  	GetCurrAttr
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#32
	      	bsr  	AsciiToScreen
	      	addui	sp,sp,#8
	      	pop  	r3
	      	mov  	r4,r1
	      	sxc  	r4,r4
	      	or   	r3,r3,r4
	      	lw   	r4,-16[bp]
	      	asli 	r4,r4,#2
	      	sh   	r3,0[r12+r4]
console_78:
	      	bra  	console_51
console_61:
	      	push 	#32
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
	      	push 	#32
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
	      	push 	#32
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
	      	push 	#32
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
	      	bra  	console_51
console_62:
	      	bsr  	CalcScreenLocation
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	bsr  	GetCurrAttr
	      	mov  	r3,r1
	      	push 	r3
	      	lcu  	r4,24[bp]
	      	push 	r4
	      	bsr  	AsciiToScreen
	      	addui	sp,sp,#8
	      	pop  	r3
	      	mov  	r4,r1
	      	sxc  	r4,r4
	      	or   	r3,r3,r4
	      	sh   	r3,[r12]
	      	bsr  	IncrementCursorPos
	      	bra  	console_51
console_51:
console_83:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_50:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_83
endpublic

public code CRLF:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_84
	      	mov  	bp,sp
	      	push 	#13
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
	      	push 	#10
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
console_85:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_84:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_85
endpublic

public code DisplayString:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_86
	      	mov  	bp,sp
	      	push 	r11
	      	lw   	r11,24[bp]
console_87:
	      	lcu  	r3,[r11]
	      	beq  	r3,console_88
	      	lcu  	r3,[r11]
	      	push 	r3
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
	      	addui	r11,r11,#2
	      	bra  	console_87
console_88:
console_89:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_86:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_89
endpublic

public code DisplayStringCRLF:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_90
	      	mov  	bp,sp
	      	push 	24[bp]
	      	bsr  	DisplayString
	      	addui	sp,sp,#8
	      	bsr  	CRLF
console_91:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_90:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_91
endpublic

	rodata
	align	16
	align	8
;	global	HomeCursor
;	global	AsciiToScreen
;	global	ScreenToAscii
;	global	CalcScreenLocation
;	global	UpdateCursorPos
	extern	GetJCBPtr
;	global	CRLF
;	global	ScrollUp
;	global	set_vector
;	global	SetVideoReg
;	global	ClearScreen
;	global	DisplayString
;	global	DisplayChar
;	global	IncrementCursorPos
;	global	GetCurrAttr
;	global	SetCurrAttr
;	global	BlankLine
;	global	DisplayStringCRLF
;	global	GetScreenLocation
	extern	IOFocusNdx
;	global	SetCursorCol
;	global	GetCursorPos
	extern	memsetH
	extern	memcpyH
	extern	GetRunningTCB
;	global	SetCursorPos
