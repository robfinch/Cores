	code
	align	16
public code isxdigit_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,ctype_2
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#70
	      	bgt  	r4,ctype_2
	      	ldi  	r1,#1
ctype_4:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_2:
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,ctype_5
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#102
	      	bgt  	r4,ctype_5
	      	ldi  	r1,#1
	      	bra  	ctype_4
ctype_5:
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#48
	      	blt  	r4,ctype_7
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#57
	      	bgt  	r4,ctype_7
	      	ldi  	r1,#1
	      	bra  	ctype_4
ctype_7:
	      	ldi  	r1,#0
	      	bra  	ctype_4
endpublic

public code isdigit_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#48
	      	blt  	r4,ctype_11
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#57
	      	bgt  	r4,ctype_11
	      	ldi  	r1,#1
ctype_13:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_11:
	      	ldi  	r1,#0
	      	bra  	ctype_13
endpublic

public code isalpha_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,ctype_16
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#122
	      	bgt  	r4,ctype_16
	      	ldi  	r1,#1
ctype_18:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_16:
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,ctype_19
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#90
	      	bgt  	r4,ctype_19
	      	ldi  	r1,#1
	      	bra  	ctype_18
ctype_19:
	      	ldi  	r1,#0
	      	bra  	ctype_18
endpublic

public code isalnum_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#48
	      	blt  	r4,ctype_23
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#57
	      	bgt  	r4,ctype_23
	      	ldi  	r1,#1
ctype_25:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_23:
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,ctype_26
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#122
	      	bgt  	r4,ctype_26
	      	ldi  	r1,#1
	      	bra  	ctype_25
ctype_26:
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,ctype_28
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#90
	      	bgt  	r4,ctype_28
	      	ldi  	r1,#1
	      	bra  	ctype_25
ctype_28:
	      	ldi  	r1,#0
	      	bra  	ctype_25
endpublic

public code isspace_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#32
	      	bne  	r4,ctype_32
	      	ldi  	r1,#1
ctype_34:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_32:
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#9
	      	bne  	r4,ctype_35
	      	ldi  	r1,#1
	      	bra  	ctype_34
ctype_35:
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#10
	      	bne  	r4,ctype_37
	      	ldi  	r1,#1
	      	bra  	ctype_34
ctype_37:
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#13
	      	bne  	r4,ctype_39
	      	ldi  	r1,#1
	      	bra  	ctype_34
ctype_39:
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#12
	      	bne  	r4,ctype_41
	      	ldi  	r1,#1
	      	bra  	ctype_34
ctype_41:
	      	ldi  	r1,#0
	      	bra  	ctype_34
endpublic

public code tolower_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,ctype_45
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#90
	      	bgt  	r4,ctype_45
	      	lc   	r4,24[bp]
	      	addu 	r3,r4,#32
	      	andi 	r3,r3,#65535
	      	sc   	r3,24[bp]
ctype_45:
	      	lc   	r3,24[bp]
	      	mov  	r1,r3
ctype_47:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code toupper_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,ctype_50
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#97
	      	bgt  	r4,ctype_50
	      	lc   	r4,24[bp]
	      	addu 	r3,r4,#-32
	      	andi 	r3,r3,#65535
	      	sc   	r3,24[bp]
ctype_50:
	      	lc   	r3,24[bp]
	      	mov  	r1,r3
ctype_52:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code isupper_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,ctype_55
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#90
	      	bgt  	r4,ctype_55
	      	ldi  	r3,#1
	      	bra  	ctype_56
ctype_55:
	      	ldi  	r3,#0
ctype_56:
	      	mov  	r1,r3
ctype_57:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code islower_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,ctype_60
	      	lc   	r3,24[bp]
	      	cmpu 	r4,r3,#122
	      	bgt  	r4,ctype_60
	      	ldi  	r3,#1
	      	bra  	ctype_61
ctype_60:
	      	ldi  	r3,#0
ctype_61:
	      	mov  	r1,r3
ctype_62:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code ispunct_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#94
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#58
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#47
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#46
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#45
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#44
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#43
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#42
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#93
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#92
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#91
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#63
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#62
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#61
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#60
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#59
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#41
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#40
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#39
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#38
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#37
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#35
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#34
	      	beq  	r4,ctype_66
	      	cmp  	r4,r3,#33
	      	beq  	r4,ctype_66
	      	bra  	ctype_67
ctype_66:
	      	ldi  	r1,#1
ctype_68:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_67:
	      	ldi  	r1,#0
	      	bra  	ctype_68
ctype_65:
	      	bra  	ctype_68
endpublic

public code isgraph_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#ctype_69
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	push 	r3
	      	bsr  	ispunct_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,ctype_73
	      	lc   	r3,24[bp]
	      	push 	r3
	      	bsr  	isalnum_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,ctype_71
ctype_73:
	      	ldi  	r3,#1
	      	bra  	ctype_72
ctype_71:
	      	ldi  	r3,#0
ctype_72:
	      	mov  	r1,r3
ctype_74:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
ctype_69:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	ctype_74
endpublic

public code isprint_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#ctype_75
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	push 	r3
	      	bsr  	isgraph_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,ctype_79
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#32
	      	bne  	r4,ctype_77
ctype_79:
	      	ldi  	r3,#1
	      	bra  	ctype_78
ctype_77:
	      	ldi  	r3,#0
ctype_78:
	      	mov  	r1,r3
ctype_80:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
ctype_75:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	ctype_80
endpublic

public code iscntrl_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lc   	r3,24[bp]
	      	cmp  	r4,r3,#7
	      	beq  	r4,ctype_84
	      	cmp  	r4,r3,#8
	      	beq  	r4,ctype_84
	      	cmp  	r4,r3,#10
	      	beq  	r4,ctype_84
	      	cmp  	r4,r3,#13
	      	beq  	r4,ctype_84
	      	cmp  	r4,r3,#12
	      	beq  	r4,ctype_84
	      	cmp  	r4,r3,#9
	      	beq  	r4,ctype_84
	      	bra  	ctype_85
ctype_84:
	      	ldi  	r1,#1
ctype_86:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
ctype_85:
	      	ldi  	r1,#0
	      	bra  	ctype_86
ctype_83:
	      	bra  	ctype_86
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
