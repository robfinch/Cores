	code
	align	16
public code isxdigit_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,ctype_1
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#70
	      	bgt  	r4,ctype_1
	      	ldi  	r1,#1
ctype_3:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_1:
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,ctype_4
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#102
	      	bgt  	r4,ctype_4
	      	ldi  	r1,#1
	      	bra  	ctype_3
ctype_4:
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#48
	      	blt  	r4,ctype_6
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#57
	      	bgt  	r4,ctype_6
	      	ldi  	r1,#1
	      	bra  	ctype_3
ctype_6:
	      	ldi  	r1,#0
	      	bra  	ctype_3
endpublic

public code isdigit_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#48
	      	blt  	r4,ctype_9
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#57
	      	bgt  	r4,ctype_9
	      	ldi  	r1,#1
ctype_11:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_9:
	      	ldi  	r1,#0
	      	bra  	ctype_11
endpublic

public code isalpha_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,ctype_13
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#122
	      	bgt  	r4,ctype_13
	      	ldi  	r1,#1
ctype_15:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_13:
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,ctype_16
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#90
	      	bgt  	r4,ctype_16
	      	ldi  	r1,#1
	      	bra  	ctype_15
ctype_16:
	      	ldi  	r1,#0
	      	bra  	ctype_15
endpublic

public code isalnum_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#48
	      	blt  	r4,ctype_19
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#57
	      	bgt  	r4,ctype_19
	      	ldi  	r1,#1
ctype_21:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_19:
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,ctype_22
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#122
	      	bgt  	r4,ctype_22
	      	ldi  	r1,#1
	      	bra  	ctype_21
ctype_22:
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,ctype_24
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#90
	      	bgt  	r4,ctype_24
	      	ldi  	r1,#1
	      	bra  	ctype_21
ctype_24:
	      	ldi  	r1,#0
	      	bra  	ctype_21
endpublic

public code isspace_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmp  	r4,r3,#32
	      	bne  	r4,ctype_27
	      	ldi  	r1,#1
ctype_29:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_27:
	      	lcu  	r3,24[bp]
	      	cmp  	r4,r3,#9
	      	bne  	r4,ctype_30
	      	ldi  	r1,#1
	      	bra  	ctype_29
ctype_30:
	      	lcu  	r3,24[bp]
	      	cmp  	r4,r3,#10
	      	bne  	r4,ctype_32
	      	ldi  	r1,#1
	      	bra  	ctype_29
ctype_32:
	      	lcu  	r3,24[bp]
	      	cmp  	r4,r3,#13
	      	bne  	r4,ctype_34
	      	ldi  	r1,#1
	      	bra  	ctype_29
ctype_34:
	      	lcu  	r3,24[bp]
	      	cmp  	r4,r3,#12
	      	bne  	r4,ctype_36
	      	ldi  	r1,#1
	      	bra  	ctype_29
ctype_36:
	      	ldi  	r1,#0
	      	bra  	ctype_29
endpublic

public code tolower_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,ctype_39
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#90
	      	bgt  	r4,ctype_39
	      	lcu  	r4,24[bp]
	      	addu 	r3,r4,#32
	      	sc   	r3,24[bp]
ctype_39:
	      	lcu  	r3,24[bp]
	      	mov  	r1,r3
ctype_41:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code toupper_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,ctype_43
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#97
	      	bgt  	r4,ctype_43
	      	lcu  	r4,24[bp]
	      	addu 	r3,r4,#-32
	      	sc   	r3,24[bp]
ctype_43:
	      	lcu  	r3,24[bp]
	      	mov  	r1,r3
ctype_45:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code isupper_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,ctype_47
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#90
	      	bgt  	r4,ctype_47
	      	ldi  	r3,#1
	      	bra  	ctype_48
ctype_47:
	      	ldi  	r3,#0
ctype_48:
	      	mov  	r1,r3
ctype_49:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code islower_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,ctype_51
	      	lcu  	r3,24[bp]
	      	cmpu 	r4,r3,#122
	      	bgt  	r4,ctype_51
	      	ldi  	r3,#1
	      	bra  	ctype_52
ctype_51:
	      	ldi  	r3,#0
ctype_52:
	      	mov  	r1,r3
ctype_53:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code ispunct_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmp  	r4,r3,#94
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#58
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#47
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#46
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#45
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#44
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#43
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#42
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#93
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#92
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#91
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#63
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#62
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#61
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#60
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#59
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#41
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#40
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#39
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#38
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#37
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#35
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#34
	      	beq  	r4,ctype_56
	      	cmp  	r4,r3,#33
	      	beq  	r4,ctype_56
	      	bra  	ctype_57
ctype_56:
	      	ldi  	r1,#1
ctype_58:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_57:
	      	ldi  	r1,#0
	      	bra  	ctype_58
ctype_55:
	      	bra  	ctype_58
endpublic

public code isgraph_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#ctype_59
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	push 	r3
	      	bsr  	ispunct_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,ctype_62
	      	lcu  	r3,24[bp]
	      	push 	r3
	      	bsr  	isalnum_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,ctype_60
ctype_62:
	      	ldi  	r3,#1
	      	bra  	ctype_61
ctype_60:
	      	ldi  	r3,#0
ctype_61:
	      	mov  	r1,r3
ctype_63:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
ctype_59:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	ctype_63
endpublic

public code isprint_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#ctype_64
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	push 	r3
	      	bsr  	isgraph_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,ctype_67
	      	lcu  	r3,24[bp]
	      	cmp  	r4,r3,#32
	      	bne  	r4,ctype_65
ctype_67:
	      	ldi  	r3,#1
	      	bra  	ctype_66
ctype_65:
	      	ldi  	r3,#0
ctype_66:
	      	mov  	r1,r3
ctype_68:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
ctype_64:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	ctype_68
endpublic

public code iscntrl_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmp  	r4,r3,#7
	      	beq  	r4,ctype_71
	      	cmp  	r4,r3,#8
	      	beq  	r4,ctype_71
	      	cmp  	r4,r3,#10
	      	beq  	r4,ctype_71
	      	cmp  	r4,r3,#13
	      	beq  	r4,ctype_71
	      	cmp  	r4,r3,#12
	      	beq  	r4,ctype_71
	      	cmp  	r4,r3,#9
	      	beq  	r4,ctype_71
	      	bra  	ctype_72
ctype_71:
	      	ldi  	r1,#1
ctype_73:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_72:
	      	ldi  	r1,#0
	      	bra  	ctype_73
ctype_70:
	      	bra  	ctype_73
endpublic

	rodata
	align	16
	align	8
;	global	isalpha_
;	global	isspace_
;	global	isdigit_
;	global	isgraph_
;	global	isalnum_
;	global	iscntrl_
;	global	islower_
;	global	ispunct_
;	global	isupper_
;	global	isprint_
;	global	tolower_
;	global	toupper_
;	global	isxdigit_
