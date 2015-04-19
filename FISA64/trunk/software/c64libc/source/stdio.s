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
	
stdio_1:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
endpublic

public code putnum_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_2
	      	mov  	bp,sp
	      	subui	sp,sp,#424
	      	push 	r11
	      	lea  	r3,-418[bp]
	      	mov  	r11,r3
	      	lw   	r3,32[bp]
	      	blt  	r3,stdio_5
	      	lw   	r3,32[bp]
	      	cmp  	r4,r3,#200
	      	ble  	r4,stdio_3
stdio_5:
	      	sw   	r0,32[bp]
stdio_3:
	      	lw   	r3,24[bp]
	      	bge  	r3,stdio_6
	      	ldi  	r3,#45
	      	bra  	stdio_7
stdio_6:
	      	ldi  	r4,#43
	      	mov  	r3,r4
stdio_7:
	      	sc   	r3,-18[bp]
	      	lw   	r3,24[bp]
	      	bge  	r3,stdio_8
	      	lw   	r3,24[bp]
	      	neg  	r3,r3
	      	sw   	r3,24[bp]
stdio_8:
	      	sw   	r0,-8[bp]
stdio_10:
	      	lw   	r4,-8[bp]
	      	and  	r3,r4,#3
	      	cmp  	r4,r3,#3
	      	bne  	r4,stdio_12
	      	lcu  	r3,40[bp]
	      	sxc  	r3,r3
	      	beq  	r3,stdio_12
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lcu  	r4,40[bp]
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
stdio_12:
	      	lw   	r3,24[bp]
	      	mod  	r3,r3,#10
	      	sw   	r3,-16[bp]
	      	lw   	r4,-16[bp]
	      	addu 	r3,r4,#48
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#1
	      	sc   	r3,0[r11+r4]
	      	lw   	r3,24[bp]
	      	divs 	r3,r3,#10
	      	sw   	r3,24[bp]
	      	inc  	-8[bp],#1
	      	lw   	r3,24[bp]
	      	beq  	r3,stdio_14
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#18
	      	ble  	r4,stdio_10
stdio_14:
stdio_11:
	      	lcu  	r3,-18[bp]
	      	cmp  	r4,r3,#45
	      	bne  	r4,stdio_15
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lcu  	r4,-18[bp]
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
stdio_15:
stdio_17:
	      	lw   	r3,-8[bp]
	      	lw   	r4,32[bp]
	      	cmp  	r5,r3,r4
	      	bge  	r5,stdio_18
	      	lcu  	r3,48[bp]
	      	push 	r3
	      	bsr  	putch_
stdio_19:
	      	dec  	32[bp],#1
	      	bra  	stdio_17
stdio_18:
stdio_20:
	      	lw   	r3,-8[bp]
	      	ble  	r3,stdio_21
	      	dec  	-8[bp],#1
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lcu  	r3,0[r11+r3]
	      	push 	r3
	      	bsr  	putch_
	      	bra  	stdio_20
stdio_21:
stdio_22:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#32
stdio_2:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_22
endpublic

public code puthexnum_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_23
	      	mov  	bp,sp
	      	subui	sp,sp,#424
	      	push 	r11
	      	lea  	r3,-418[bp]
	      	mov  	r11,r3
	      	lw   	r3,32[bp]
	      	blt  	r3,stdio_26
	      	lw   	r3,32[bp]
	      	cmp  	r4,r3,#200
	      	ble  	r4,stdio_24
stdio_26:
	      	sw   	r0,32[bp]
stdio_24:
	      	sw   	r0,-8[bp]
	      	lw   	r3,24[bp]
	      	bge  	r3,stdio_27
	      	ldi  	r3,#45
	      	bra  	stdio_28
stdio_27:
	      	ldi  	r4,#43
	      	mov  	r3,r4
stdio_28:
	      	sc   	r3,-18[bp]
	      	lw   	r3,24[bp]
	      	bge  	r3,stdio_29
	      	lw   	r3,24[bp]
	      	neg  	r3,r3
	      	sw   	r3,24[bp]
stdio_29:
stdio_31:
	      	lw   	r4,24[bp]
	      	and  	r3,r4,#15
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#10
	      	bge  	r4,stdio_33
	      	lw   	r4,-16[bp]
	      	addu 	r3,r4,#48
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#1
	      	sc   	r3,0[r11+r4]
	      	bra  	stdio_34
stdio_33:
	      	lw   	r3,40[bp]
	      	beq  	r3,stdio_35
	      	lw   	r4,-16[bp]
	      	subu 	r3,r4,#-55
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#1
	      	sc   	r3,0[r11+r4]
	      	bra  	stdio_36
stdio_35:
	      	lw   	r4,-16[bp]
	      	subu 	r3,r4,#-87
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#1
	      	sc   	r3,0[r11+r4]
stdio_36:
stdio_34:
	      	lw   	r4,24[bp]
	      	asri 	r3,r4,#4
	      	sw   	r3,24[bp]
	      	inc  	-8[bp],#1
	      	lw   	r3,24[bp]
	      	beq  	r3,stdio_37
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#18
	      	blt  	r4,stdio_31
stdio_37:
stdio_32:
	      	lcu  	r3,-18[bp]
	      	cmp  	r4,r3,#45
	      	bne  	r4,stdio_38
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lcu  	r4,-18[bp]
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
stdio_38:
stdio_40:
	      	lw   	r3,-8[bp]
	      	lw   	r4,32[bp]
	      	cmp  	r5,r3,r4
	      	bge  	r5,stdio_41
	      	lcu  	r3,-18[bp]
	      	cmp  	r4,r3,#45
	      	bne  	r4,stdio_42
	      	ldi  	r3,#32
	      	bra  	stdio_43
stdio_42:
	      	lcu  	r4,48[bp]
	      	sxc  	r4,r4
	      	mov  	r3,r4
stdio_43:
	      	push 	r3
	      	bsr  	putch_
	      	dec  	32[bp],#1
	      	bra  	stdio_40
stdio_41:
stdio_44:
	      	lw   	r3,-8[bp]
	      	ble  	r3,stdio_45
	      	dec  	-8[bp],#1
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lcu  	r3,0[r11+r3]
	      	push 	r3
	      	bsr  	putch_
	      	bra  	stdio_44
stdio_45:
stdio_46:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#32
stdio_23:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_46
endpublic

public code putstr_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_47
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	lw   	r11,24[bp]
	      	sw   	r11,-8[bp]
stdio_48:
	      	lcu  	r3,[r11]
	      	beq  	r3,stdio_49
	      	lw   	r3,32[bp]
	      	ble  	r3,stdio_49
	      	lcu  	r3,[r11]
	      	push 	r3
	      	bsr  	putch_
stdio_50:
	      	addui	r11,r11,#2
	      	dec  	32[bp],#1
	      	bra  	stdio_48
stdio_49:
	      	lw   	r5,-8[bp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#1
	      	mov  	r1,r3
stdio_51:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#16
stdio_47:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_51
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
    
stdio_53:
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
	      	ldi  	xlr,#stdio_56
	      	mov  	bp,sp
	      	subui	sp,sp,#8
stdio_57:
	      	bsr  	getcharNoWait_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#-1
	      	beq  	r4,stdio_57
stdio_58:
	      	lw   	r4,-8[bp]
	      	and  	r3,r4,#255
	      	mov  	r1,r3
stdio_59:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
stdio_56:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_59
endpublic

public code printf_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_61
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	push 	r12
	      	lea  	r3,24[bp]
	      	mov  	r11,r3
	      	mov  	r12,r11
stdio_62:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	beq  	r3,stdio_63
	      	ldi  	r3,#32
	      	sc   	r3,-34[bp]
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	cmp  	r4,r3,#37
	      	bne  	r4,stdio_65
	      	sw   	r0,-16[bp]
	      	ldi  	r3,#65535
	      	sw   	r3,-24[bp]
	      	inc  	[r11],#2
stdio_60:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	cmp  	r4,r3,#37
	      	beq  	r4,stdio_68
	      	cmp  	r4,r3,#99
	      	beq  	r4,stdio_69
	      	cmp  	r4,r3,#100
	      	beq  	r4,stdio_70
	      	cmp  	r4,r3,#120
	      	beq  	r4,stdio_71
	      	cmp  	r4,r3,#88
	      	beq  	r4,stdio_72
	      	cmp  	r4,r3,#115
	      	beq  	r4,stdio_73
	      	cmp  	r4,r3,#48
	      	beq  	r4,stdio_74
	      	cmp  	r4,r3,#57
	      	beq  	r4,stdio_75
	      	cmp  	r4,r3,#56
	      	beq  	r4,stdio_75
	      	cmp  	r4,r3,#55
	      	beq  	r4,stdio_75
	      	cmp  	r4,r3,#54
	      	beq  	r4,stdio_75
	      	cmp  	r4,r3,#53
	      	beq  	r4,stdio_75
	      	cmp  	r4,r3,#52
	      	beq  	r4,stdio_75
	      	cmp  	r4,r3,#51
	      	beq  	r4,stdio_75
	      	cmp  	r4,r3,#50
	      	beq  	r4,stdio_75
	      	cmp  	r4,r3,#49
	      	beq  	r4,stdio_75
	      	cmp  	r4,r3,#46
	      	beq  	r4,stdio_76
	      	bra  	stdio_67
stdio_68:
	      	push 	#37
	      	bsr  	putch_
	      	bra  	stdio_67
stdio_69:
	      	addui	r12,r12,#8
	      	push 	[r12]
	      	bsr  	putch_
	      	bra  	stdio_67
stdio_70:
	      	addui	r12,r12,#8
	      	lcu  	r3,-34[bp]
	      	push 	r3
	      	push 	#0
	      	push 	-16[bp]
	      	push 	[r12]
	      	bsr  	putnum_
	      	bra  	stdio_67
stdio_71:
	      	addui	r12,r12,#8
	      	lcu  	r3,-34[bp]
	      	push 	r3
	      	push 	#0
	      	push 	-16[bp]
	      	push 	[r12]
	      	bsr  	puthexnum_
	      	bra  	stdio_67
stdio_72:
	      	addui	r12,r12,#8
	      	lcu  	r3,-34[bp]
	      	push 	r3
	      	push 	#1
	      	push 	-16[bp]
	      	push 	[r12]
	      	bsr  	puthexnum_
	      	bra  	stdio_67
stdio_73:
	      	addui	r12,r12,#8
	      	push 	-24[bp]
	      	push 	[r12]
	      	bsr  	putstr_
	      	mov  	r3,r1
	      	sw   	r3,-32[bp]
	      	bra  	stdio_67
stdio_74:
	      	ldi  	r3,#48
	      	sc   	r3,-34[bp]
stdio_75:
	      	lw   	r4,[r11]
	      	lcu  	r4,[r4]
	      	subu 	r3,r4,#48
	      	sw   	r3,-16[bp]
	      	inc  	[r11],#2
stdio_77:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	push 	r3
	      	bsr  	isdigit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,stdio_78
	      	lw   	r3,-16[bp]
	      	muli 	r3,r3,#10
	      	sw   	r3,-16[bp]
	      	lw   	r4,[r11]
	      	lcu  	r4,[r4]
	      	subu 	r3,r4,#48
	      	lw   	r4,-16[bp]
	      	addu 	r4,r4,r3
	      	sw   	r4,-16[bp]
	      	inc  	[r11],#2
	      	bra  	stdio_77
stdio_78:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	cmp  	r4,r3,#46
	      	beq  	r4,stdio_79
	      	bra  	stdio_60
stdio_79:
stdio_76:
	      	inc  	[r11],#2
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	push 	r3
	      	bsr  	isdigit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,stdio_81
	      	bra  	stdio_60
stdio_81:
	      	lw   	r4,[r11]
	      	lcu  	r4,[r4]
	      	subu 	r3,r4,#48
	      	sw   	r3,-24[bp]
	      	inc  	[r11],#2
stdio_83:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	push 	r3
	      	bsr  	isdigit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,stdio_84
	      	lw   	r3,-24[bp]
	      	muli 	r3,r3,#10
	      	sw   	r3,-24[bp]
	      	lw   	r4,[r11]
	      	lcu  	r4,[r4]
	      	subu 	r3,r4,#48
	      	lw   	r4,-24[bp]
	      	addu 	r4,r4,r3
	      	sw   	r4,-24[bp]
	      	inc  	[r11],#2
	      	bra  	stdio_83
stdio_84:
	      	bra  	stdio_60
stdio_67:
	      	bra  	stdio_66
stdio_65:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	push 	r3
	      	bsr  	putch_
stdio_66:
stdio_64:
	      	inc  	[r11],#2
	      	bra  	stdio_62
stdio_63:
stdio_85:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
stdio_61:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_85
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
;	global	printf_
