	code
	align	16
public code putch_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        push    r6
		lw		r1,24[bp]
		ldi     r6,#14    ; Teletype output function
        sys     #410      ; Video BIOS call
        pop     r6
	
stdio_2:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
endpublic

public code putnum_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_3
	      	mov  	bp,sp
	      	subui	sp,sp,#424
	      	push 	r11
	      	lea  	r3,-418[bp]
	      	mov  	r11,r3
	      	lw   	r3,32[bp]
	      	blt  	r3,stdio_7
	      	lw   	r3,32[bp]
	      	cmp  	r4,r3,#200
	      	ble  	r4,stdio_5
stdio_7:
	      	sw   	r0,32[bp]
stdio_5:
	      	lw   	r3,24[bp]
	      	bge  	r3,stdio_8
	      	ldi  	r3,#45
	      	bra  	stdio_9
stdio_8:
	      	ldi  	r4,#43
	      	mov  	r3,r4
stdio_9:
	      	andi 	r3,r3,#65535
	      	sc   	r3,-18[bp]
	      	lw   	r3,24[bp]
	      	bge  	r3,stdio_10
	      	lw   	r4,24[bp]
	      	neg  	r3,r4
	      	sw   	r3,24[bp]
stdio_10:
	      	sw   	r0,-8[bp]
stdio_12:
	      	lw   	r4,-8[bp]
	      	and  	r3,r4,#3
	      	cmp  	r4,r3,#3
	      	bne  	r4,stdio_14
	      	lc   	r3,40[bp]
	      	beq  	r3,stdio_14
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lcu  	r4,40[bp]
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
stdio_14:
	      	lw   	r4,24[bp]
	      	mod  	r3,r4,#10
	      	sw   	r3,-16[bp]
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-16[bp]
	      	addu 	r4,r5,#48
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	lw   	r4,24[bp]
	      	divs 	r3,r4,#10
	      	sw   	r3,24[bp]
	      	inc  	-8[bp],#1
	      	lw   	r3,24[bp]
	      	beq  	r3,stdio_16
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#18
	      	ble  	r4,stdio_12
stdio_16:
stdio_13:
	      	lc   	r3,-18[bp]
	      	cmp  	r4,r3,#45
	      	bne  	r4,stdio_17
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lcu  	r4,-18[bp]
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
stdio_17:
stdio_19:
	      	lw   	r3,-8[bp]
	      	lw   	r4,32[bp]
	      	cmp  	r5,r3,r4
	      	bge  	r5,stdio_20
	      	lc   	r3,48[bp]
	      	push 	r3
	      	bsr  	putch_
stdio_21:
	      	dec  	32[bp],#1
	      	bra  	stdio_19
stdio_20:
stdio_22:
	      	lw   	r3,-8[bp]
	      	ble  	r3,stdio_23
	      	dec  	-8[bp],#1
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lc   	r3,0[r11+r3]
	      	push 	r3
	      	bsr  	putch_
	      	bra  	stdio_22
stdio_23:
stdio_24:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#32
stdio_3:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_24
endpublic

public code puthexnum_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_25
	      	mov  	bp,sp
	      	subui	sp,sp,#424
	      	push 	r11
	      	lea  	r3,-418[bp]
	      	mov  	r11,r3
	      	lw   	r3,32[bp]
	      	blt  	r3,stdio_29
	      	lw   	r3,32[bp]
	      	cmp  	r4,r3,#200
	      	ble  	r4,stdio_27
stdio_29:
	      	sw   	r0,32[bp]
stdio_27:
	      	sw   	r0,-8[bp]
	      	lw   	r3,24[bp]
	      	bge  	r3,stdio_30
	      	ldi  	r3,#45
	      	bra  	stdio_31
stdio_30:
	      	ldi  	r4,#43
	      	mov  	r3,r4
stdio_31:
	      	andi 	r3,r3,#65535
	      	sc   	r3,-18[bp]
	      	lw   	r3,24[bp]
	      	bge  	r3,stdio_32
	      	lw   	r4,24[bp]
	      	neg  	r3,r4
	      	sw   	r3,24[bp]
stdio_32:
stdio_34:
	      	lw   	r4,24[bp]
	      	and  	r3,r4,#15
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#10
	      	bge  	r4,stdio_36
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-16[bp]
	      	addu 	r4,r5,#48
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	bra  	stdio_37
stdio_36:
	      	lw   	r3,40[bp]
	      	beq  	r3,stdio_38
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-16[bp]
	      	subu 	r4,r5,#-55
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	bra  	stdio_39
stdio_38:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-16[bp]
	      	subu 	r4,r5,#-87
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
stdio_39:
stdio_37:
	      	lw   	r4,24[bp]
	      	asri 	r3,r4,#4
	      	sw   	r3,24[bp]
	      	inc  	-8[bp],#1
	      	lw   	r3,24[bp]
	      	beq  	r3,stdio_40
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#18
	      	blt  	r4,stdio_34
stdio_40:
stdio_35:
	      	lc   	r3,-18[bp]
	      	cmp  	r4,r3,#45
	      	bne  	r4,stdio_41
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lcu  	r4,-18[bp]
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
stdio_41:
stdio_43:
	      	lw   	r3,-8[bp]
	      	lw   	r4,32[bp]
	      	cmp  	r5,r3,r4
	      	bge  	r5,stdio_44
	      	lc   	r3,-18[bp]
	      	cmp  	r4,r3,#45
	      	bne  	r4,stdio_45
	      	ldi  	r3,#32
	      	bra  	stdio_46
stdio_45:
	      	lc   	r4,48[bp]
	      	mov  	r3,r4
stdio_46:
	      	push 	r3
	      	bsr  	putch_
	      	dec  	32[bp],#1
	      	bra  	stdio_43
stdio_44:
stdio_47:
	      	lw   	r3,-8[bp]
	      	ble  	r3,stdio_48
	      	dec  	-8[bp],#1
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lc   	r3,0[r11+r3]
	      	push 	r3
	      	bsr  	putch_
	      	bra  	stdio_47
stdio_48:
stdio_49:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#32
stdio_25:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_49
endpublic

public code putstr_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_50
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	lw   	r11,24[bp]
	      	sw   	r11,-8[bp]
stdio_52:
	      	lc   	r3,[r11]
	      	beq  	r3,stdio_53
	      	lw   	r3,32[bp]
	      	ble  	r3,stdio_53
	      	lc   	r3,[r11]
	      	push 	r3
	      	bsr  	putch_
stdio_54:
	      	addui	r11,r11,#2
	      	dec  	32[bp],#1
	      	bra  	stdio_52
stdio_53:
	      	lw   	r5,-8[bp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#1
	      	mov  	r1,r3
stdio_55:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#16
stdio_50:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_55
endpublic

public code putstr2_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        push    r6
        lw      r1,24[bp]
        ldi     r6,#$1B   ; Video BIOS DisplayString16 function
        sys     #410
        pop     r6
    
stdio_58:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
endpublic

public code getcharNoWait_:
	      	     	        push    lr
        bsr     KeybdGetBufferedCharNoWait_
        pop     lr
        rtl
        push    r6
        ld      r6,#3    ; KeybdGetCharNoWait
        sys     #10
        pop     r6
        rtl
	
endpublic

public code getchar_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_62
	      	mov  	bp,sp
	      	subui	sp,sp,#8
stdio_64:
	      	bsr  	getcharNoWait_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#-1
	      	beq  	r4,stdio_64
stdio_65:
	      	lw   	r4,-8[bp]
	      	and  	r3,r4,#255
	      	mov  	r1,r3
stdio_66:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
stdio_62:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_66
endpublic

public code printf_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_68
	      	mov  	bp,sp
	      	subui	sp,sp,#48
	      	push 	r11
	      	push 	r12
	      	lea  	r3,24[bp]
	      	mov  	r11,r3
	      	mov  	r12,r11
stdio_70:
	      	lw   	r3,[r11]
	      	lc   	r3,[r3]
	      	beq  	r3,stdio_71
	      	ldi  	r3,#32
	      	andi 	r3,r3,#65535
	      	sc   	r3,-42[bp]
	      	lw   	r3,[r11]
	      	lc   	r3,[r3]
	      	cmp  	r4,r3,#37
	      	bne  	r4,stdio_73
	      	sw   	r0,-16[bp]
	      	ldi  	r3,#65535
	      	sw   	r3,-24[bp]
	      	inc  	[r11],#2
stdio_67:
	      	lw   	r3,[r11]
	      	lc   	r3,[r3]
	      	cmp  	r4,r3,#37
	      	beq  	r4,stdio_76
	      	cmp  	r4,r3,#99
	      	beq  	r4,stdio_77
	      	cmp  	r4,r3,#100
	      	beq  	r4,stdio_78
	      	cmp  	r4,r3,#101
	      	beq  	r4,stdio_79
	      	cmp  	r4,r3,#69
	      	beq  	r4,stdio_79
	      	cmp  	r4,r3,#120
	      	beq  	r4,stdio_80
	      	cmp  	r4,r3,#88
	      	beq  	r4,stdio_81
	      	cmp  	r4,r3,#115
	      	beq  	r4,stdio_82
	      	cmp  	r4,r3,#48
	      	beq  	r4,stdio_83
	      	cmp  	r4,r3,#57
	      	beq  	r4,stdio_84
	      	cmp  	r4,r3,#56
	      	beq  	r4,stdio_84
	      	cmp  	r4,r3,#55
	      	beq  	r4,stdio_84
	      	cmp  	r4,r3,#54
	      	beq  	r4,stdio_84
	      	cmp  	r4,r3,#53
	      	beq  	r4,stdio_84
	      	cmp  	r4,r3,#52
	      	beq  	r4,stdio_84
	      	cmp  	r4,r3,#51
	      	beq  	r4,stdio_84
	      	cmp  	r4,r3,#50
	      	beq  	r4,stdio_84
	      	cmp  	r4,r3,#49
	      	beq  	r4,stdio_84
	      	cmp  	r4,r3,#46
	      	beq  	r4,stdio_85
	      	bra  	stdio_75
stdio_76:
	      	push 	#37
	      	bsr  	putch_
	      	bra  	stdio_75
stdio_77:
	      	addui	r12,r12,#8
	      	push 	[r12]
	      	bsr  	putch_
	      	bra  	stdio_75
stdio_78:
	      	addui	r12,r12,#8
	      	lc   	r3,-42[bp]
	      	push 	r3
	      	push 	#0
	      	push 	-16[bp]
	      	push 	[r12]
	      	bsr  	putnum_
	      	bra  	stdio_75
stdio_79:
	      	addui	r12,r12,#8
	      	lw   	r3,[r12]
	      	sw   	r3,-40[bp]
	      	lw   	r3,[r11]
	      	lc   	r3,[r3]
	      	push 	r3
	      	push 	-24[bp]
	      	push 	-16[bp]
	      	push 	-40[bp]
	      	bsr  	prtdbl_
	      	bra  	stdio_75
stdio_80:
	      	addui	r12,r12,#8
	      	lc   	r3,-42[bp]
	      	push 	r3
	      	push 	#0
	      	push 	-16[bp]
	      	push 	[r12]
	      	bsr  	puthexnum_
	      	bra  	stdio_75
stdio_81:
	      	addui	r12,r12,#8
	      	lc   	r3,-42[bp]
	      	push 	r3
	      	push 	#1
	      	push 	-16[bp]
	      	push 	[r12]
	      	bsr  	puthexnum_
	      	bra  	stdio_75
stdio_82:
	      	addui	r12,r12,#8
	      	push 	-24[bp]
	      	push 	[r12]
	      	bsr  	putstr_
	      	mov  	r3,r1
	      	sw   	r3,-32[bp]
	      	bra  	stdio_75
stdio_83:
	      	ldi  	r3,#48
	      	andi 	r3,r3,#65535
	      	sc   	r3,-42[bp]
stdio_84:
	      	lw   	r4,[r11]
	      	lc   	r4,[r4]
	      	subu 	r3,r4,#48
	      	sw   	r3,-16[bp]
	      	inc  	[r11],#2
stdio_86:
	      	lw   	r3,[r11]
	      	lc   	r3,[r3]
	      	push 	r3
	      	bsr  	isdigit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,stdio_87
	      	lw   	r3,-16[bp]
	      	muli 	r3,r3,#10
	      	sw   	r3,-16[bp]
	      	lw   	r4,[r11]
	      	lc   	r4,[r4]
	      	subu 	r3,r4,#48
	      	lw   	r4,-16[bp]
	      	addu 	r4,r4,r3
	      	sw   	r4,-16[bp]
	      	inc  	[r11],#2
	      	bra  	stdio_86
stdio_87:
	      	lw   	r3,[r11]
	      	lc   	r3,[r3]
	      	cmp  	r4,r3,#46
	      	beq  	r4,stdio_88
	      	bra  	stdio_67
stdio_88:
stdio_85:
	      	inc  	[r11],#2
	      	lw   	r3,[r11]
	      	lc   	r3,[r3]
	      	push 	r3
	      	bsr  	isdigit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,stdio_90
	      	bra  	stdio_67
stdio_90:
	      	lw   	r4,[r11]
	      	lc   	r4,[r4]
	      	subu 	r3,r4,#48
	      	sw   	r3,-24[bp]
	      	inc  	[r11],#2
stdio_92:
	      	lw   	r3,[r11]
	      	lc   	r3,[r3]
	      	push 	r3
	      	bsr  	isdigit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,stdio_93
	      	lw   	r3,-24[bp]
	      	muli 	r3,r3,#10
	      	sw   	r3,-24[bp]
	      	lw   	r4,[r11]
	      	lc   	r4,[r4]
	      	subu 	r3,r4,#48
	      	lw   	r4,-24[bp]
	      	addu 	r4,r4,r3
	      	sw   	r4,-24[bp]
	      	inc  	[r11],#2
	      	bra  	stdio_92
stdio_93:
	      	bra  	stdio_67
stdio_75:
	      	bra  	stdio_74
stdio_73:
	      	lw   	r3,[r11]
	      	lc   	r3,[r3]
	      	push 	r3
	      	bsr  	putch_
stdio_74:
stdio_72:
	      	inc  	[r11],#2
	      	bra  	stdio_70
stdio_71:
stdio_94:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
stdio_68:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_94
endpublic

	rodata
	align	16
	align	8
;	global	putnum_
;	global	putstr_
;	global	getchar_
;	global	putstr2_
	extern	isdigit_
;	global	puthexnum_
;	global	putch_
;	global	getcharNoWait_
	extern	prtdbl_
;	global	printf_
