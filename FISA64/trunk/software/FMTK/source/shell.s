	bss
	align	8
public bss sh_linendx_:
	fill.b	8,0x00

endpublic
	align	8
public bss sh_linebuf_:
	fill.b	200,0x00

endpublic
	code
	align	16
public code sh_getchar_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	lea  	r3,sh_linendx_[gp]
	      	mov  	r11,r3
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lw   	r3,[r11]
	      	cmp  	r4,r3,#84
	      	bge  	r4,shell_2
	      	lw   	r4,[r11]
	      	asli 	r3,r4,#1
	      	lea  	r4,sh_linebuf_[gp]
	      	lcu  	r5,0[r4+r3]
	      	sc   	r5,-2[bp]
	      	inc  	[r11],#1
shell_2:
	      	lc   	r3,-2[bp]
	      	mov  	r1,r3
shell_4:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code sh_nextNonSpace_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#shell_5
	      	mov  	bp,sp
	      	subui	sp,sp,#8
shell_7:
	      	lw   	r3,sh_linendx_[gp]
	      	cmp  	r4,r3,#84
	      	bge  	r4,shell_8
	      	bsr  	sh_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#32
	      	bne  	r4,shell_11
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#-1
	      	bne  	r4,shell_9
shell_11:
	      	lc   	r3,-2[bp]
	      	mov  	r1,r3
shell_12:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
shell_9:
	      	bra  	shell_7
shell_8:
	      	ldi  	r1,#-1
	      	bra  	shell_12
shell_5:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	shell_12
endpublic

	data
	align	8
	code
	align	16
public code sh_getHexNumber_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#shell_13
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	sw   	r0,-16[bp]
	      	sw   	r0,-24[bp]
	      	bsr  	sh_nextNonSpace_
	      	dec  	sh_linendx_[gp],#1
shell_15:
	      	ldi  	r3,#1
	      	beq  	r3,shell_16
	      	bsr  	sh_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmpu 	r4,r3,#48
	      	blt  	r4,shell_17
	      	lc   	r3,-2[bp]
	      	cmpu 	r4,r3,#57
	      	bgt  	r4,shell_17
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#4
	      	lc   	r6,-2[bp]
	      	subu 	r5,r6,#48
	      	or   	r3,r4,r5
	      	sw   	r3,-16[bp]
	      	bra  	shell_18
shell_17:
	      	lc   	r3,-2[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,shell_19
	      	lc   	r3,-2[bp]
	      	cmpu 	r4,r3,#70
	      	bgt  	r4,shell_19
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#4
	      	lc   	r6,-2[bp]
	      	addu 	r5,r6,#-55
	      	or   	r3,r4,r5
	      	sw   	r3,-16[bp]
	      	bra  	shell_20
shell_19:
	      	lc   	r3,-2[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,shell_21
	      	lc   	r3,-2[bp]
	      	cmpu 	r4,r3,#102
	      	bgt  	r4,shell_21
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#4
	      	lc   	r6,-2[bp]
	      	addu 	r5,r6,#-87
	      	or   	r3,r4,r5
	      	sw   	r3,-16[bp]
	      	bra  	shell_22
shell_21:
	      	lw   	r3,24[bp]
	      	lw   	r4,-16[bp]
	      	sw   	r4,[r3]
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
shell_23:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
shell_22:
shell_20:
shell_18:
	      	lw   	r4,-24[bp]
	      	addu 	r3,r4,#1
	      	sw   	r3,-24[bp]
	      	bra  	shell_15
shell_16:
	      	bra  	shell_23
shell_13:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	shell_23
endpublic

	data
	align	8
	code
	align	16
public code sh_getDecNumber_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#shell_24
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	lw   	r11,24[bp]
	      	bne  	r11,shell_26
	      	ldi  	r1,#0
shell_28:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
shell_26:
	      	sw   	r0,-8[bp]
	      	sw   	r0,-24[bp]
shell_29:
	      	bsr  	sh_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-10[bp]
	      	push 	-10[bp]
	      	bsr  	isdigit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,shell_30
	      	ldi  	r4,#-48
	      	lw   	r7,-8[bp]
	      	mul  	r6,r7,#10
	      	lc   	r7,-10[bp]
	      	addu 	r5,r6,r7
	      	addu 	r3,r4,r5
	      	sw   	r3,-8[bp]
	      	inc  	-24[bp],#1
	      	bra  	shell_29
shell_30:
	      	dec  	sh_linendx_[gp],#1
	      	lw   	r3,-8[bp]
	      	sw   	r3,[r11]
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
	      	bra  	shell_28
shell_24:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	shell_28
endpublic

	data
	align	8
	code
	align	16
public code sh_parse_line_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#shell_31
	      	mov  	bp,sp
	      	subui	sp,sp,#64
	      	push 	r11
	      	lea  	r3,-32[bp]
	      	mov  	r11,r3
	      	bsr  	sh_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#100
	      	beq  	r4,shell_34
	      	cmp  	r4,r3,#116
	      	beq  	r4,shell_35
	      	cmp  	r4,r3,#107
	      	beq  	r4,shell_36
	      	cmp  	r4,r3,#106
	      	beq  	r4,shell_37
	      	cmp  	r4,r3,#115
	      	beq  	r4,shell_38
	      	bra  	shell_33
shell_34:
	      	push 	#0
	      	push 	#0
	      	push 	#debugger_task_
	      	push 	#0
	      	push 	#32
	      	bsr  	FMTK_StartTask_
	      	addui	sp,sp,#40
	      	bra  	shell_33
shell_35:
	      	bsr  	DumpTaskList_
	      	ldi  	r1,#0
shell_39:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
shell_36:
	      	bsr  	sh_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#105
	      	bne  	r4,shell_40
	      	bsr  	sh_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#108
	      	bne  	r4,shell_42
	      	bsr  	sh_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#108
	      	bne  	r4,shell_44
shell_44:
shell_42:
shell_40:
	      	pea  	-24[bp]
	      	bsr  	sh_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	ble  	r3,shell_46
	      	push 	-24[bp]
	      	bsr  	FMTK_KillTask_
	      	addui	sp,sp,#8
shell_46:
	      	ldi  	r1,#0
	      	bra  	shell_39
shell_37:
	      	push 	r11
	      	bsr  	sh_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	ble  	r3,shell_48
	      	lw   	r3,[r11]
	      	jal  	lr,[r3]
shell_48:
	      	bra  	shell_33
shell_38:
	      	bsr  	sh_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#116
	      	bne  	r4,shell_50
	      	pea  	-40[bp]
	      	bsr  	sh_getDecNumber_
	      	mov  	r3,r1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	bgt  	r3,shell_52
	      	bra  	shell_33
shell_52:
	      	pea  	-48[bp]
	      	bsr  	sh_getDecNumber_
	      	mov  	r3,r1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	bgt  	r3,shell_54
	      	bra  	shell_33
shell_54:
	      	push 	r11
	      	bsr  	sh_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	bgt  	r3,shell_56
	      	bra  	shell_33
shell_56:
	      	pea  	-56[bp]
	      	bsr  	sh_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	bgt  	r3,shell_58
	      	bra  	shell_33
shell_58:
	      	pea  	-64[bp]
	      	bsr  	sh_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	bgt  	r3,shell_60
	      	bra  	shell_33
shell_60:
	      	push 	-64[bp]
	      	push 	-56[bp]
	      	push 	[r11]
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	bsr  	FMTK_StartTask_
	      	addui	sp,sp,#40
shell_50:
	      	bra  	shell_33
shell_33:
	      	ldi  	r1,#0
	      	bra  	shell_39
shell_31:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	shell_39
endpublic

public code sh_parse_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#shell_62
	      	mov  	bp,sp
	      	sw   	r0,sh_linendx_[gp]
	      	lc   	r3,sh_linebuf_[gp]
	      	cmp  	r4,r3,#36
	      	bne  	r4,shell_64
	      	lea  	r3,sh_linebuf_[gp]
	      	lc   	r3,2[r3]
	      	cmp  	r4,r3,#62
	      	bne  	r4,shell_64
	      	ldi  	r3,#2
	      	sw   	r3,sh_linendx_[gp]
shell_64:
	      	bsr  	sh_parse_line_
	      	mov  	r3,r1
	      	mov  	r1,r3
shell_66:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
shell_62:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	shell_66
endpublic

public code shell_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#shell_68
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	ldi  	r3,#4291821568
	      	mov  	r11,r3
shell_70:
	      	pea  	shell_67[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
shell_72:
	      	bsr  	getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-34[bp]
	      	lc   	r3,-34[bp]
	      	cmp  	r4,r3,#13
	      	bne  	r4,shell_74
	      	bra  	shell_73
shell_74:
	      	lc   	r3,-34[bp]
	      	push 	r3
	      	bsr  	putch_
	      	bra  	shell_72
shell_73:
	      	bsr  	dbg_GetCursorRow_
	      	mov  	r3,r1
	      	sw   	r3,-24[bp]
	      	bsr  	dbg_GetCursorCol_
	      	mov  	r3,r1
	      	sw   	r3,-32[bp]
	      	sw   	r0,-16[bp]
shell_76:
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#84
	      	bge  	r4,shell_77
	      	lw   	r4,-16[bp]
	      	asli 	r3,r4,#1
	      	pea  	sh_linebuf_[gp]
	      	push 	r4
	      	lw   	r9,-24[bp]
	      	mul  	r8,r9,#84
	      	lw   	r9,-16[bp]
	      	addu 	r7,r8,r9
	      	asli 	r6,r7,#2
	      	lh   	r6,0[r11+r6]
	      	and  	r5,r6,#1023
	      	push 	r5
	      	bsr  	CvtScreenToAscii_
	      	pop  	r4
	      	pop  	r3
	      	mov  	r5,r1
	      	sxc  	r5,r5
	      	andi 	r5,r5,#65535
	      	sc   	r5,0[r4+r3]
shell_78:
	      	inc  	-16[bp],#1
	      	bra  	shell_76
shell_77:
	      	bsr  	sh_parse_
	      	bra  	shell_70
shell_71:
shell_79:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
shell_68:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	shell_79
endpublic

	rodata
	align	16
	align	8
shell_67:
	dc	13,10,36,62,0
	extern	FMTK_KillTask_
	extern	DumpTaskList_
	extern	getchar_
	extern	isdigit_
;	global	sh_getDecNumber_
;	global	sh_getHexNumber_
;	global	sh_nextNonSpace_
;	global	sh_getchar_
;	global	shell_
;	global	sh_linebuf_
	extern	putch_
;	global	sh_linendx_
	extern	FMTK_StartTask_
;	global	CvtScreenToAscii_
	extern	dbg_GetCursorCol_
;	global	sh_parse_
	extern	debugger_task_
;	global	sh_parse_line_
	extern	dbg_GetCursorRow_
	extern	prtdbl_
	extern	printf_
