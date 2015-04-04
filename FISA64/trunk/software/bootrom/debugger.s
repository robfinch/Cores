	bss
	align	8
	align	8
public bss linendx:
	fill.b	8,0x00

endpublic
	align	8
public bss linebuf:
	fill.b	200,0x00

endpublic
	align	8
public bss dbg_stack:
	fill.b	32768,0x00

endpublic
	align	8
public bss dbg_dbctrl:
	fill.b	8,0x00

endpublic
	align	8
public bss regs:
	fill.b	256,0x00

endpublic
	align	8
public bss cr0save:
	fill.b	8,0x00

endpublic
	align	8
public bss ssm:
	fill.b	8,0x00

endpublic
	align	8
public bss repcount:
	fill.b	8,0x00

endpublic
	align	8
public bss curaddr:
	fill.b	8,0x00

endpublic
	align	8
public bss cursz:
	fill.b	8,0x00

endpublic
	align	8
public bss curfmt:
	fill.b	2,0x00

endpublic
	data
	align	8
	db	0
	align	8
	db	0
	align	8
	db	0
	align	8
	db	0
	align	8
	db	0
	align	8
	db	0
	bss
	align	8
	align	8
public bss currep:
	fill.b	8,0x00

endpublic
	align	8
public bss muol:
	fill.b	8,0x00

endpublic
	align	8
public bss bmem:
	fill.b	8,0x00

endpublic
	align	8
public bss cmem:
	fill.b	8,0x00

endpublic
	align	8
public bss hmem:
	fill.b	8,0x00

endpublic
	align	8
public bss wmem:
	fill.b	8,0x00

endpublic
	code
	align	16
dbg_DisplayHelp:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_16
	      	mov  	bp,sp
	      	push 	#debugger_1
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_2
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_3
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_4
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_5
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_6
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_7
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_8
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_9
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_10
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_11
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_12
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_13
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_14
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_15
	      	bsr  	printf
	      	addui	sp,sp,#8
debugger_17:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_16:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_17
public code GetVBR:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        mfspr r1,vbr
    
debugger_19:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code set_vector:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_20
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#511
	      	ble  	r3,debugger_21
debugger_23:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_21:
	      	lw   	r3,32[bp]
	      	beq  	r3,debugger_26
	      	lw   	r3,32[bp]
	      	and  	r3,r3,#3
	      	beq  	r3,debugger_24
debugger_26:
	      	bra  	debugger_23
debugger_24:
	      	lw   	r3,24[bp]
	      	asli 	r3,r3,#3
	      	push 	r3
	      	bsr  	GetVBR
	      	pop  	r3
	      	mov  	r4,r1
	      	lw   	r5,32[bp]
	      	sw   	r5,0[r4+r3]
	      	bra  	debugger_23
debugger_20:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_23
endpublic

public code dbg_GetCursorRow:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        ldi    r6,#3   ; Get cursor position
        sys    #410
    
debugger_28:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_GetCursorCol:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        ldi    r6,#3
        sys    #410
        mov    r1,r2
    
debugger_30:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_HomeCursor:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         ldi   r6,#2
         ldi   r1,#0
         ldi   r2,#0
         sys   #410
     
debugger_32:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_GetDBAD:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,debugger_35
	      	cmp  	r4,r3,#1
	      	beq  	r4,debugger_36
	      	cmp  	r4,r3,#2
	      	beq  	r4,debugger_37
	      	cmp  	r4,r3,#3
	      	beq  	r4,debugger_38
	      	bra  	debugger_34
debugger_35:
	      	     	mfspr  r1,dbad0  
	      	bra  	debugger_34
debugger_36:
	      	     	mfspr  r1,dbad1  
	      	bra  	debugger_34
debugger_37:
	      	     	mfspr  r1,dbad2  
	      	bra  	debugger_34
debugger_38:
	      	     	mfspr  r1,dbad3  
	      	bra  	debugger_34
debugger_39:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
debugger_34:
	      	bra  	debugger_39
endpublic

public code dbg_SetDBAD:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,debugger_42
	      	cmp  	r4,r3,#1
	      	beq  	r4,debugger_43
	      	cmp  	r4,r3,#2
	      	beq  	r4,debugger_44
	      	cmp  	r4,r3,#3
	      	beq  	r4,debugger_45
	      	bra  	debugger_41
debugger_42:
	      	     	          lw    r1,32[bp]
          mtspr dbad0,r1
          
	      	bra  	debugger_41
debugger_43:
	      	     	          lw    r1,32[bp]
          mtspr dbad1,r1
          
	      	bra  	debugger_41
debugger_44:
	      	     	          lw    r1,32[bp]
          mtspr dbad2,r1
          
	      	bra  	debugger_41
debugger_45:
	      	     	          lw    r1,32[bp]
          mtspr dbad3,r1
          
	      	bra  	debugger_41
debugger_41:
debugger_46:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_arm:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw    r1,24[bp]
         mtspr dbctrl,r1
     
debugger_48:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code CvtScreenToAscii:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw    r1,24[bp]
         ldi   r6,#$21         ; screen to ascii
         sys   #410
     
debugger_50:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_getchar:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	ldi  	r11,#linendx
	      	ldi  	r3,#-1
	      	sc   	r3,-2[bp]
	      	lw   	r3,[r11]
	      	cmp  	r3,r3,#84
	      	bge  	r3,debugger_52
	      	lw   	r3,[r11]
	      	asli 	r3,r3,#1
	      	lcu  	r4,linebuf[r3]
	      	sc   	r4,-2[bp]
	      	inc  	[r11],#1
debugger_52:
	      	lcu  	r3,-2[bp]
	      	mov  	r1,r3
debugger_54:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code ignore_blanks:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
debugger_56:
	      	lw   	r3,linendx
	      	asli 	r3,r3,#1
	      	lcu  	r4,linebuf[r3]
	      	sc   	r4,-2[bp]
	      	inc  	linendx,#1
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#32
	      	beq  	r3,debugger_56
debugger_57:
debugger_58:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_ungetch:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,linendx
	      	ble  	r3,debugger_60
	      	dec  	linendx,#1
debugger_60:
debugger_62:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_nextNonSpace:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_63
	      	mov  	bp,sp
	      	subui	sp,sp,#8
debugger_64:
	      	lw   	r3,linendx
	      	cmp  	r3,r3,#84
	      	bge  	r3,debugger_65
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#32
	      	bne  	r3,debugger_68
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#-1
	      	bne  	r3,debugger_66
debugger_68:
	      	lcu  	r3,-2[bp]
	      	mov  	r1,r3
debugger_69:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_66:
	      	bra  	debugger_64
debugger_65:
	      	ldi  	r1,#-1
	      	bra  	debugger_69
debugger_63:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_69
endpublic

public code dbg_getHexNumber:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_70
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	sw   	r0,-16[bp]
	      	sw   	r0,-24[bp]
	      	bsr  	dbg_nextNonSpace
	      	dec  	linendx,#1
debugger_71:
	      	ldi  	r3,#1
	      	beq  	r3,debugger_72
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#48
	      	blt  	r3,debugger_73
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#57
	      	bgt  	r3,debugger_73
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#4
	      	lcu  	r4,-2[bp]
	      	subu 	r4,r4,#48
	      	or   	r3,r3,r4
	      	sw   	r3,-16[bp]
	      	bra  	debugger_74
debugger_73:
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#65
	      	blt  	r3,debugger_75
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#70
	      	bgt  	r3,debugger_75
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#4
	      	lcu  	r4,-2[bp]
	      	addu 	r4,r4,#-55
	      	or   	r3,r3,r4
	      	sw   	r3,-16[bp]
	      	bra  	debugger_76
debugger_75:
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#97
	      	blt  	r3,debugger_77
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#102
	      	bgt  	r3,debugger_77
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#4
	      	lcu  	r4,-2[bp]
	      	addu 	r4,r4,#-87
	      	or   	r3,r3,r4
	      	sw   	r3,-16[bp]
	      	bra  	debugger_78
debugger_77:
	      	lw   	r3,24[bp]
	      	lw   	r4,-16[bp]
	      	sw   	r4,[r3]
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
debugger_79:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_78:
debugger_76:
debugger_74:
	      	lw   	r3,-24[bp]
	      	addu 	r3,r3,#1
	      	sw   	r3,-24[bp]
	      	bra  	debugger_71
debugger_72:
	      	bra  	debugger_79
debugger_70:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_79
endpublic

public code dbg_ReadSetIB:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_82
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	ldi  	r11,#dbg_dbctrl
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#3
	      	ble  	r3,debugger_83
debugger_85:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_83:
	      	bsr  	dbg_nextNonSpace
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#61
	      	bne  	r3,debugger_86
	      	pea  	-16[bp]
	      	bsr  	dbg_GetHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	ble  	r3,debugger_88
	      	push 	-16[bp]
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	ldi  	r3,#1
	      	lw   	r4,24[bp]
	      	asl  	r3,r3,r4
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#196608
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
debugger_88:
	      	bra  	debugger_87
debugger_86:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#63
	      	bne  	r3,debugger_90
	      	lw   	r3,[r11]
	      	ldi  	r4,#196608
	      	lw   	r5,24[bp]
	      	asli 	r5,r5,#1
	      	asl  	r4,r4,r5
	      	and  	r3,r3,r4
	      	bne  	r3,debugger_92
	      	lw   	r3,[r11]
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r4,r4,r5
	      	ldi  	r5,#1
	      	lw   	r6,24[bp]
	      	asl  	r5,r5,r6
	      	seq  	r4,r4,r5
	      	and  	r3,r3,r4
	      	beq  	r3,debugger_92
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	push 	#debugger_80
	      	bsr  	printf
	      	addui	sp,sp,#24
	      	bra  	debugger_93
debugger_92:
	      	push 	24[bp]
	      	push 	#debugger_81
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_93:
debugger_90:
debugger_87:
	      	bra  	debugger_85
debugger_82:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_85
endpublic

public code dbg_ReadSetDB:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_98
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	ldi  	r11,#dbg_dbctrl
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#3
	      	ble  	r3,debugger_99
debugger_101:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_99:
	      	bsr  	dbg_nextNonSpace
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#61
	      	bne  	r3,debugger_102
	      	pea  	-16[bp]
	      	bsr  	dbg_GetHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	ble  	r3,debugger_104
	      	push 	-16[bp]
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	ldi  	r3,#1
	      	lw   	r4,24[bp]
	      	asl  	r3,r3,r4
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#196608
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#196608
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
debugger_104:
	      	bra  	debugger_103
debugger_102:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#63
	      	bne  	r3,debugger_106
	      	lw   	r3,[r11]
	      	ldi  	r4,#196608
	      	lw   	r5,24[bp]
	      	asli 	r5,r5,#1
	      	asl  	r4,r4,r5
	      	and  	r3,r3,r4
	      	ldi  	r4,#196608
	      	lw   	r5,24[bp]
	      	asli 	r5,r5,#1
	      	asl  	r4,r4,r5
	      	cmp  	r3,r3,r4
	      	bne  	r3,debugger_108
	      	lw   	r3,[r11]
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r4,r4,r5
	      	ldi  	r5,#1
	      	lw   	r6,24[bp]
	      	asl  	r5,r5,r6
	      	seq  	r4,r4,r5
	      	and  	r3,r3,r4
	      	beq  	r3,debugger_108
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	push 	#debugger_96
	      	bsr  	printf
	      	addui	sp,sp,#24
	      	bra  	debugger_109
debugger_108:
	      	push 	24[bp]
	      	push 	#debugger_97
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_109:
debugger_106:
debugger_103:
	      	bra  	debugger_101
debugger_98:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_101
endpublic

public code dbg_ReadSetDSB:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_114
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	ldi  	r11,#dbg_dbctrl
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#3
	      	ble  	r3,debugger_115
debugger_117:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_115:
	      	bsr  	dbg_nextNonSpace
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#61
	      	bne  	r3,debugger_118
	      	pea  	-16[bp]
	      	bsr  	dbg_GetHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	ble  	r3,debugger_120
	      	push 	-16[bp]
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	ldi  	r3,#1
	      	lw   	r4,24[bp]
	      	asl  	r3,r3,r4
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#196608
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#65536
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
debugger_120:
	      	bra  	debugger_119
debugger_118:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#63
	      	bne  	r3,debugger_122
	      	lw   	r3,[r11]
	      	ldi  	r4,#196608
	      	lw   	r5,24[bp]
	      	asli 	r5,r5,#1
	      	asl  	r4,r4,r5
	      	and  	r3,r3,r4
	      	ldi  	r4,#65536
	      	lw   	r5,24[bp]
	      	asli 	r5,r5,#1
	      	asl  	r4,r4,r5
	      	cmp  	r3,r3,r4
	      	bne  	r3,debugger_124
	      	lw   	r3,[r11]
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r4,r4,r5
	      	ldi  	r5,#1
	      	lw   	r6,24[bp]
	      	asl  	r5,r5,r6
	      	seq  	r4,r4,r5
	      	and  	r3,r3,r4
	      	beq  	r3,debugger_124
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	push 	#debugger_112
	      	bsr  	printf
	      	addui	sp,sp,#24
	      	bra  	debugger_125
debugger_124:
	      	push 	24[bp]
	      	push 	#debugger_113
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_125:
debugger_122:
debugger_119:
	      	bra  	debugger_117
debugger_114:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_117
endpublic

DispRegs:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_137
	      	mov  	bp,sp
	      	push 	r11
	      	ldi  	r11,#regs
	      	push 	32[r11]
	      	push 	24[r11]
	      	push 	16[r11]
	      	push 	8[r11]
	      	push 	#debugger_129
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	64[r11]
	      	push 	56[r11]
	      	push 	48[r11]
	      	push 	40[r11]
	      	push 	#debugger_130
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	96[r11]
	      	push 	88[r11]
	      	push 	80[r11]
	      	push 	72[r11]
	      	push 	#debugger_131
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	128[r11]
	      	push 	120[r11]
	      	push 	112[r11]
	      	push 	104[r11]
	      	push 	#debugger_132
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	160[r11]
	      	push 	152[r11]
	      	push 	144[r11]
	      	push 	136[r11]
	      	push 	#debugger_133
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	192[r11]
	      	push 	184[r11]
	      	push 	176[r11]
	      	push 	168[r11]
	      	push 	#debugger_134
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	224[r11]
	      	push 	216[r11]
	      	push 	208[r11]
	      	push 	200[r11]
	      	push 	#debugger_135
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	248[r11]
	      	push 	240[r11]
	      	push 	232[r11]
	      	push 	#debugger_136
	      	bsr  	printf
	      	addui	sp,sp,#32
debugger_138:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_137:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_138
DispReg:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_141
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asli 	r3,r3,#3
	      	push 	regs[r3]
	      	push 	24[bp]
	      	push 	#debugger_140
	      	bsr  	printf
	      	addui	sp,sp,#24
debugger_142:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_141:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_142
public code dbg_prompt:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_144
	      	mov  	bp,sp
	      	push 	#debugger_143
	      	bsr  	printf
	      	addui	sp,sp,#8
debugger_145:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_144:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_145
endpublic

public code dbg_getDecNumber:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_146
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	lw   	r11,24[bp]
	      	bne  	r11,debugger_147
	      	ldi  	r1,#0
debugger_149:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_147:
	      	sw   	r0,-8[bp]
	      	sw   	r0,-24[bp]
debugger_150:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-10[bp]
	      	push 	r3
	      	bsr  	isdigit
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,debugger_151
	      	ldi  	r3,#-48
	      	lw   	r4,-8[bp]
	      	mul  	r4,r4,#10
	      	lcu  	r5,-10[bp]
	      	addu 	r4,r4,r5
	      	addu 	r3,r3,r4
	      	sw   	r3,-8[bp]
	      	inc  	-24[bp],#1
	      	bra  	debugger_150
debugger_151:
	      	dec  	linendx,#1
	      	lw   	r3,-8[bp]
	      	sw   	r3,[r11]
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
	      	bra  	debugger_149
debugger_146:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_149
endpublic

public code dbg_processReg:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_152
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_154
	      	bra  	debugger_155
debugger_154:
	      	bsr  	DispRegs
	      	bra  	debugger_153
debugger_155:
	      	lcu  	r3,-2[bp]
	      	push 	r3
	      	bsr  	isdigit
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,debugger_156
	      	dec  	linendx,#1
	      	bsr  	dbg_getDecNumber
	      	mov  	r3,r1
	      	sw   	r3,-16[bp]
	      	bsr  	dbg_nextNonSpace
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_159
	      	cmp  	r4,r3,#61
	      	beq  	r4,debugger_160
	      	bra  	debugger_161
debugger_159:
	      	push 	-16[bp]
	      	bsr  	DispReg
	      	addui	sp,sp,#8
debugger_162:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_160:
	      	pea  	-24[bp]
	      	bsr  	dbg_getHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-32[bp]
	      	lw   	r3,-32[bp]
	      	ble  	r3,debugger_163
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#3
	      	lw   	r4,-24[bp]
	      	sw   	r4,regs[r3]
debugger_163:
	      	bra  	debugger_162
debugger_161:
	      	bra  	debugger_162
debugger_158:
debugger_156:
	      	bra  	debugger_162
debugger_153:
	      	bra  	debugger_162
debugger_152:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_162
endpublic

public code dbg_parse_begin:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_165
	      	mov  	bp,sp
	      	push 	r11
	      	ldi  	r11,#linebuf
	      	sw   	r0,linendx
	      	lcu  	r3,[r11]
	      	cmp  	r3,r3,#68
	      	bne  	r3,debugger_166
	      	lcu  	r3,2[r11]
	      	cmp  	r3,r3,#66
	      	bne  	r3,debugger_166
	      	lcu  	r3,4[r11]
	      	cmp  	r3,r3,#71
	      	bne  	r3,debugger_166
	      	lcu  	r3,6[r11]
	      	cmp  	r3,r3,#62
	      	bne  	r3,debugger_166
	      	ldi  	r3,#4
	      	sw   	r3,linendx
debugger_166:
	      	bsr  	dbg_parse_line
	      	mov  	r3,r1
	      	mov  	r1,r3
debugger_168:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_165:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_168
endpublic

public code dbg_parse_line:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_189
	      	mov  	bp,sp
	      	subui	sp,sp,#56
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	push 	r15
	      	push 	r16
	      	push 	r17
	      	ldi  	r11,#muol
	      	ldi  	r12,#cursz
	      	ldi  	r13,#curaddr
	      	ldi  	r14,#curfmt
	      	ldi  	r15,#currep
	      	lea  	r3,-16[bp]
	      	mov  	r16,r3
	      	ldi  	r17,#dbg_dbctrl
debugger_190:
	      	lw   	r3,linendx
	      	cmp  	r3,r3,#84
	      	bge  	r3,debugger_191
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#-1
	      	beq  	r4,debugger_193
	      	cmp  	r4,r3,#32
	      	beq  	r4,debugger_194
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_195
	      	cmp  	r4,r3,#113
	      	beq  	r4,debugger_196
	      	cmp  	r4,r3,#97
	      	beq  	r4,debugger_197
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_198
	      	cmp  	r4,r3,#100
	      	beq  	r4,debugger_199
	      	cmp  	r4,r3,#114
	      	beq  	r4,debugger_200
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_201
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_202
	      	bra  	debugger_192
debugger_193:
debugger_203:
	      	pop  	r17
	      	pop  	r16
	      	pop  	r15
	      	pop  	r14
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_194:
	      	bra  	debugger_192
debugger_195:
	      	bsr  	dbg_DisplayHelp
	      	bra  	debugger_192
debugger_196:
	      	ldi  	r1,#1
	      	bra  	debugger_203
debugger_197:
	      	push 	[r17]
	      	bsr  	dbg_arm
	      	addui	sp,sp,#8
	      	bra  	debugger_192
debugger_198:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_205
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_206
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_207
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_208
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_209
	      	bra  	debugger_204
debugger_205:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#196608
	      	bne  	r3,debugger_210
	      	lw   	r3,[r17]
	      	and  	r3,r3,#1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_210
	      	push 	#0
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_169
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_210:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#3145728
	      	bne  	r3,debugger_212
	      	lw   	r3,[r17]
	      	and  	r3,r3,#2
	      	cmp  	r3,r3,#2
	      	bne  	r3,debugger_212
	      	push 	#1
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_170
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_212:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#50331648
	      	bne  	r3,debugger_214
	      	lw   	r3,[r17]
	      	and  	r3,r3,#4
	      	cmp  	r3,r3,#4
	      	bne  	r3,debugger_214
	      	push 	#2
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_171
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_214:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#805306368
	      	bne  	r3,debugger_216
	      	lw   	r3,[r17]
	      	and  	r3,r3,#8
	      	cmp  	r3,r3,#8
	      	bne  	r3,debugger_216
	      	push 	#3
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_172
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_216:
	      	bra  	debugger_204
debugger_206:
	      	push 	#0
	      	bsr  	dbg_ReadSetIB
	      	addui	sp,sp,#8
	      	bra  	debugger_204
debugger_207:
	      	push 	#1
	      	bsr  	dbg_ReadSetIB
	      	addui	sp,sp,#8
	      	bra  	debugger_204
debugger_208:
	      	push 	#2
	      	bsr  	dbg_ReadSetIB
	      	addui	sp,sp,#8
	      	bra  	debugger_204
debugger_209:
	      	push 	#3
	      	bsr  	dbg_ReadSetIB
	      	addui	sp,sp,#8
	      	bra  	debugger_204
debugger_204:
	      	bra  	debugger_192
debugger_199:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_219
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_220
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_221
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_222
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_223
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_224
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_225
	      	bra  	debugger_218
debugger_219:
debugger_226:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#-1
	      	bne  	r3,debugger_228
	      	bra  	debugger_227
debugger_228:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#32
	      	bne  	r3,debugger_226
debugger_227:
	      	push 	r16
	      	bsr  	dbg_getHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_230
	      	pea  	-24[bp]
	      	bsr  	dbg_getDecNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-56[bp]
	      	lw   	r3,-56[bp]
	      	ble  	r3,debugger_232
debugger_234:
	      	lw   	r3,-56[bp]
	      	ble  	r3,debugger_235
	      	push 	#0
	      	push 	r16
	      	bsr  	disassem
	      	addui	sp,sp,#16
debugger_236:
	      	dec  	-56[bp],#1
	      	bra  	debugger_234
debugger_235:
	      	bra  	debugger_233
debugger_232:
	      	push 	#0
	      	push 	[r16]
	      	bsr  	disassem20
	      	addui	sp,sp,#16
debugger_233:
debugger_230:
	      	bra  	debugger_218
debugger_220:
	      	push 	#debugger_173
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lw   	r3,[r17]
	      	and  	r3,r3,#196608
	      	cmp  	r3,r3,#196608
	      	bne  	r3,debugger_237
	      	lw   	r3,[r17]
	      	and  	r3,r3,#1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_237
	      	push 	#0
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_174
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_237:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#3145728
	      	cmp  	r3,r3,#3145728
	      	bne  	r3,debugger_239
	      	lw   	r3,[r17]
	      	and  	r3,r3,#2
	      	cmp  	r3,r3,#2
	      	bne  	r3,debugger_239
	      	push 	#1
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_175
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_239:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#50331648
	      	cmp  	r3,r3,#50331648
	      	bne  	r3,debugger_241
	      	lw   	r3,[r17]
	      	and  	r3,r3,#4
	      	cmp  	r3,r3,#4
	      	bne  	r3,debugger_241
	      	push 	#2
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_176
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_241:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#805306368
	      	cmp  	r3,r3,#805306368
	      	bne  	r3,debugger_243
	      	lw   	r3,[r17]
	      	and  	r3,r3,#8
	      	cmp  	r3,r3,#8
	      	bne  	r3,debugger_243
	      	push 	#3
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_177
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_243:
	      	bra  	debugger_218
debugger_221:
	      	push 	#0
	      	bsr  	dbg_ReadSetDB
	      	addui	sp,sp,#8
	      	bra  	debugger_218
debugger_222:
	      	push 	#1
	      	bsr  	dbg_ReadSetDB
	      	addui	sp,sp,#8
	      	bra  	debugger_218
debugger_223:
	      	push 	#2
	      	bsr  	dbg_ReadSetDB
	      	addui	sp,sp,#8
	      	bra  	debugger_218
debugger_224:
	      	push 	#3
	      	bsr  	dbg_ReadSetDB
	      	addui	sp,sp,#8
	      	bra  	debugger_218
debugger_225:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_246
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_247
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_248
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_249
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_250
	      	bra  	debugger_245
debugger_246:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#196608
	      	cmp  	r3,r3,#65536
	      	bne  	r3,debugger_251
	      	lw   	r3,[r17]
	      	and  	r3,r3,#1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_251
	      	push 	#0
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_178
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_251:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#3145728
	      	cmp  	r3,r3,#1048576
	      	bne  	r3,debugger_253
	      	lw   	r3,[r17]
	      	and  	r3,r3,#2
	      	cmp  	r3,r3,#2
	      	bne  	r3,debugger_253
	      	push 	#1
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_179
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_253:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#50331648
	      	cmp  	r3,r3,#16777216
	      	bne  	r3,debugger_255
	      	lw   	r3,[r17]
	      	and  	r3,r3,#4
	      	cmp  	r3,r3,#4
	      	bne  	r3,debugger_255
	      	push 	#2
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_180
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_255:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#805306368
	      	cmp  	r3,r3,#268435456
	      	bne  	r3,debugger_257
	      	lw   	r3,[r17]
	      	and  	r3,r3,#8
	      	cmp  	r3,r3,#8
	      	bne  	r3,debugger_257
	      	push 	#3
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_181
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_257:
	      	bra  	debugger_245
debugger_247:
	      	push 	#0
	      	bsr  	dbg_ReadSetDSB
	      	addui	sp,sp,#8
	      	bra  	debugger_245
debugger_248:
	      	push 	#1
	      	bsr  	dbg_ReadSetDSB
	      	addui	sp,sp,#8
	      	bra  	debugger_245
debugger_249:
	      	push 	#2
	      	bsr  	dbg_ReadSetDSB
	      	addui	sp,sp,#8
	      	bra  	debugger_245
debugger_250:
	      	push 	#3
	      	bsr  	dbg_ReadSetDSB
	      	addui	sp,sp,#8
	      	bra  	debugger_245
debugger_245:
	      	bra  	debugger_218
debugger_218:
	      	bra  	debugger_192
debugger_200:
	      	bsr  	dbg_processReg
	      	bra  	debugger_192
debugger_201:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#115
	      	bne  	r3,debugger_259
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#45
	      	bne  	r3,debugger_261
	      	lw   	r3,[r17]
	      	andi 	r3,r3,#-1
	      	sw   	r3,[r17]
	      	bra  	debugger_262
debugger_261:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#43
	      	beq  	r3,debugger_265
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#109
	      	bne  	r3,debugger_263
debugger_265:
	      	lw   	r3,[r17]
	      	ori  	r3,r3,#0
	      	sw   	r3,[r17]
	      	ldi  	r3,#1
	      	sw   	r3,ssm
debugger_263:
debugger_262:
debugger_259:
	      	bra  	debugger_192
debugger_202:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#47
	      	bne  	r3,debugger_266
	      	pea  	-40[bp]
	      	bsr  	dbg_getDecNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_268
	      	lw   	r3,-40[bp]
	      	sw   	r3,[r15]
debugger_268:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_271
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_272
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_273
	      	bra  	debugger_270
debugger_271:
	      	ldi  	r3,#105
	      	sc   	r3,[r14]
	      	push 	r16
	      	bsr  	dbg_getHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_274
	      	lw   	r3,[r16]
	      	sw   	r3,[r13]
debugger_274:
	      	bra  	debugger_270
debugger_272:
	      	ldi  	r3,#115
	      	sc   	r3,[r14]
	      	push 	r16
	      	bsr  	dbg_getHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_276
	      	lw   	r3,[r16]
	      	sw   	r3,[r13]
debugger_276:
	      	bra  	debugger_270
debugger_273:
	      	ldi  	r3,#120
	      	sc   	r3,[r14]
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_279
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_280
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_281
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_282
	      	bra  	debugger_283
debugger_279:
	      	ldi  	r3,#98
	      	sw   	r3,[r12]
	      	ldi  	r3,#16
	      	sw   	r3,[r11]
	      	bra  	debugger_278
debugger_280:
	      	ldi  	r3,#99
	      	sw   	r3,[r12]
	      	ldi  	r3,#8
	      	sw   	r3,[r11]
	      	bra  	debugger_278
debugger_281:
	      	ldi  	r3,#104
	      	sw   	r3,[r12]
	      	ldi  	r3,#4
	      	sw   	r3,[r11]
	      	bra  	debugger_278
debugger_282:
	      	ldi  	r3,#119
	      	sw   	r3,[r12]
	      	ldi  	r3,#2
	      	sw   	r3,[r11]
	      	bra  	debugger_278
debugger_283:
	      	dec  	linendx,#1
debugger_278:
	      	push 	r16
	      	bsr  	dbg_getHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_284
	      	lw   	r3,[r16]
	      	sw   	r3,[r13]
debugger_284:
	      	bra  	debugger_270
debugger_270:
debugger_266:
	      	lcu  	r3,[r14]
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_287
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_288
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_289
	      	bra  	debugger_286
debugger_287:
	      	push 	#debugger_182
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-48[bp]
debugger_290:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r15]
	      	cmp  	r3,r3,r4
	      	bge  	r3,debugger_291
	      	bsr  	getcharNoWait
	      	mov  	r3,r1
	      	cmp  	r3,r3,#3
	      	bne  	r3,debugger_293
	      	bra  	debugger_291
debugger_293:
	      	push 	#0
	      	push 	r13
	      	bsr  	disassem
	      	addui	sp,sp,#16
debugger_292:
	      	inc  	-48[bp],#1
	      	bra  	debugger_290
debugger_291:
	      	bra  	debugger_286
debugger_288:
	      	bra  	debugger_286
debugger_289:
	      	sw   	r0,-48[bp]
debugger_295:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r15]
	      	cmp  	r3,r3,r4
	      	bge  	r3,debugger_296
	      	bsr  	getcharNoWait
	      	mov  	r3,r1
	      	cmp  	r3,r3,#3
	      	bne  	r3,debugger_298
	      	bra  	debugger_296
debugger_298:
	      	lw   	r3,-48[bp]
	      	lw   	r4,muol
	      	modu 	r3,r3,r4
	      	bne  	r3,debugger_300
	      	lw   	r3,[r13]
	      	lw   	r4,-48[bp]
	      	addu 	r3,r3,r4
	      	push 	r3
	      	push 	#debugger_183
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_300:
	      	lw   	r3,[r12]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_303
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_304
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_305
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_306
	      	bra  	debugger_302
debugger_303:
	      	lw   	r3,[r13]
	      	lw   	r4,-48[bp]
	      	addu 	r3,r3,r4
	      	lw   	r4,bmem
	      	lbu  	r3,0[r4+r3]
	      	push 	r3
	      	push 	#debugger_184
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	debugger_302
debugger_304:
	      	lw   	r3,[r13]
	      	asri 	r3,r3,#1
	      	lw   	r4,-48[bp]
	      	addu 	r3,r3,r4
	      	asli 	r3,r3,#1
	      	lw   	r4,cmem
	      	lcu  	r3,0[r4+r3]
	      	push 	r3
	      	push 	#debugger_185
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	debugger_302
debugger_305:
	      	lw   	r3,[r13]
	      	asri 	r3,r3,#2
	      	lw   	r4,-48[bp]
	      	addu 	r3,r3,r4
	      	asli 	r3,r3,#2
	      	lw   	r4,hmem
	      	lhu  	r3,0[r4+r3]
	      	push 	r3
	      	push 	#debugger_186
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	debugger_302
debugger_306:
	      	lw   	r3,[r13]
	      	asri 	r3,r3,#3
	      	lw   	r4,-48[bp]
	      	addu 	r3,r3,r4
	      	asli 	r3,r3,#3
	      	push 	wmem
	      	push 	#debugger_187
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	debugger_302
debugger_302:
debugger_297:
	      	inc  	-48[bp],#1
	      	bra  	debugger_295
debugger_296:
	      	push 	#debugger_188
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	debugger_286
debugger_286:
debugger_192:
	      	bra  	debugger_190
debugger_191:
	      	ldi  	r1,#0
	      	bra  	debugger_203
debugger_189:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_203
endpublic

public code dbg_irq:
	      	     	         lea   sp,dbg_stack+4088
         sw    r1,regs+8
         sw    r2,regs+16
         sw    r3,regs+24
         sw    r4,regs+32
         sw    r5,regs+40
         sw    r6,regs+48
         sw    r7,regs+56
         sw    r8,regs+64
         sw    r9,regs+72
         sw    r10,regs+80
         sw    r11,regs+88
         sw    r12,regs+96
         sw    r13,regs+104
         sw    r14,regs+112
         sw    r15,regs+120
         sw    r16,regs+128
         sw    r17,regs+136
         sw    r18,regs+144
         sw    r19,regs+152
         sw    r20,regs+160
         sw    r21,regs+168
         sw    r22,regs+176
         sw    r23,regs+184
         sw    r24,regs+192
         sw    r25,regs+200
         sw    r26,regs+208
         sw    r27,regs+216
         sw    r28,regs+224
         sw    r29,regs+232
         sw    r30,regs+240
         sw    r31,regs+248
         mfspr r1,cr0
         sw    r1,cr0save

         mfspr r1,dbctrl
         push  r1
         mtspr dbctrl,r0
         mfspr r1,dpc
         push  r1
         bsr   debugger
         addui sp,sp,#16
         
         lw    r1,cr0save
         mtspr cr0,r1
         lw    r1,regs+8
         lw    r2,regs+16
         lw    r3,regs+24
         lw    r4,regs+32
         lw    r5,regs+40
         lw    r6,regs+48
         lw    r7,regs+56
         lw    r8,regs+64
         lw    r9,regs+72
         lw    r10,regs+80
         lw    r11,regs+88
         lw    r12,regs+96
         lw    r13,regs+104
         lw    r14,regs+112
         lw    r15,regs+120
         lw    r16,regs+128
         lw    r17,regs+136
         lw    r18,regs+144
         lw    r19,regs+152
         lw    r20,regs+160
         lw    r21,regs+168
         lw    r22,regs+176
         lw    r23,regs+184
;         lw    r24,regs+192
         lw    r25,regs+200
         lw    r26,regs+208
         lw    r27,regs+216
         lw    r28,regs+224
         lw    r29,regs+232
         lw    r30,regs+240
         lw    r31,regs+248
         rtd
     
endpublic

public code dbg_ssm:
	      	     	         lea   sp,dbg_stack+4088
         sw    r1,regs+8
         sw    r2,regs+16
         sw    r3,regs+24
         sw    r4,regs+32
         sw    r5,regs+40
         sw    r6,regs+48
         sw    r7,regs+56
         sw    r8,regs+64
         sw    r9,regs+72
         sw    r10,regs+80
         sw    r11,regs+88
         sw    r12,regs+96
         sw    r13,regs+104
         sw    r14,regs+112
         sw    r15,regs+120
         sw    r16,regs+128
         sw    r17,regs+136
         sw    r18,regs+144
         sw    r19,regs+152
         sw    r20,regs+160
         sw    r21,regs+168
         sw    r22,regs+176
         sw    r23,regs+184
         sw    r24,regs+192
         sw    r25,regs+200
         sw    r26,regs+208
         sw    r27,regs+216
         sw    r28,regs+224
         sw    r29,regs+232
         sw    r30,regs+240
         sw    r31,regs+248
         mfspr r1,cr0
         sw    r1,cr0save

         mfspr r1,dbctrl
         push  r1
         mtspr dbctrl,r0
         mfspr r1,dpc
         push  r1
         bsr   debugger
         addui sp,sp,#16
         
         lw    r1,cr0save
         mtspr cr0,r1
         lw    r1,regs+8
         lw    r2,regs+16
         lw    r3,regs+24
         lw    r4,regs+32
         lw    r5,regs+40
         lw    r6,regs+48
         lw    r7,regs+56
         lw    r8,regs+64
         lw    r9,regs+72
         lw    r10,regs+80
         lw    r11,regs+88
         lw    r12,regs+96
         lw    r13,regs+104
         lw    r14,regs+112
         lw    r15,regs+120
         lw    r16,regs+128
         lw    r17,regs+136
         lw    r18,regs+144
         lw    r19,regs+152
         lw    r20,regs+160
         lw    r21,regs+168
         lw    r22,regs+176
         lw    r23,regs+184
;         lw    r24,regs+192
         lw    r25,regs+200
         lw    r26,regs+208
         lw    r27,regs+216
         lw    r28,regs+224
         lw    r29,regs+232
         lw    r30,regs+240
         lw    r31,regs+248
         rtd
     
endpublic

public code debugger:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_312
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	ldi  	r11,#ssm
	      	ldi  	r12,#dbg_dbctrl
	      	lw   	r3,32[bp]
	      	sw   	r3,[r12]
	      	ldi  	r13,#-3145728
	      	lw   	r3,24[bp]
	      	and  	r3,r3,#-4
	      	sw   	r3,24[bp]
	      	lw   	r3,24[bp]
	      	beq  	r3,debugger_313
	      	push 	24[bp]
	      	push 	24[bp]
	      	bsr  	disassem20
	      	addui	sp,sp,#16
debugger_313:
debugger_315:
	      	push 	#debugger_311
	      	bsr  	printf
	      	addui	sp,sp,#8
debugger_317:
	      	bsr  	getchar
	      	mov  	r3,r1
	      	sc   	r3,-2[bp]
	      	lw   	r3,[r11]
	      	beq  	r3,debugger_319
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#115
	      	bne  	r3,debugger_321
	      	lw   	r3,[r12]
	      	ori  	r3,r3,#0
	      	sw   	r3,[r12]
	      	push 	[r12]
	      	bsr  	dbg_arm
	      	addui	sp,sp,#8
debugger_323:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_321:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#45
	      	beq  	r3,debugger_326
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#3
	      	bne  	r3,debugger_324
debugger_326:
	      	sw   	r0,[r11]
	      	lw   	r3,[r12]
	      	andi 	r3,r3,#-1
	      	sw   	r3,[r12]
	      	push 	[r12]
	      	bsr  	dbg_arm
	      	addui	sp,sp,#8
	      	bra  	debugger_323
debugger_324:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#110
	      	bne  	r3,debugger_327
	      	ldi  	r3,#2
	      	sw   	r3,[r11]
	      	lw   	r3,[r12]
	      	andi 	r3,r3,#-983041
	      	sw   	r3,[r12]
	      	lw   	r3,[r12]
	      	ori  	r3,r3,#524289
	      	sw   	r3,[r12]
	      	lw   	r3,24[bp]
	      	addu 	r3,r3,#4
	      	push 	r3
	      	push 	#0
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	push 	[r12]
	      	bsr  	dbg_arm
	      	addui	sp,sp,#8
	      	bra  	debugger_323
debugger_327:
	      	bra  	debugger_320
debugger_319:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#13
	      	bne  	r3,debugger_329
	      	bra  	debugger_318
debugger_329:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#12
	      	bne  	r3,debugger_331
	      	     	                           bsr ClearScreen
                       
	      	bsr  	dbg_HomeCursor
	      	bra  	debugger_318
debugger_331:
	      	lcu  	r3,-2[bp]
	      	push 	r3
	      	bsr  	putch
	      	addui	sp,sp,#8
debugger_320:
	      	ldi  	r3,#1
	      	bne  	r3,debugger_317
debugger_318:
	      	bsr  	dbg_GetCursorRow
	      	mov  	r3,r1
	      	sxb  	r3,r3
	      	sw   	r3,-16[bp]
	      	bsr  	dbg_GetCursorCol
	      	mov  	r3,r1
	      	sxb  	r3,r3
	      	sw   	r3,-24[bp]
	      	sw   	r0,-40[bp]
debugger_333:
	      	lw   	r3,-40[bp]
	      	cmp  	r3,r3,#84
	      	bge  	r3,debugger_334
	      	lw   	r3,-16[bp]
	      	mul  	r3,r3,#84
	      	lw   	r4,-40[bp]
	      	addu 	r3,r3,r4
	      	asli 	r3,r3,#2
	      	lhu  	r3,0[r13+r3]
	      	and  	r3,r3,#1023
	      	push 	r3
	      	bsr  	CvtScreenToAscii
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	lw   	r4,-40[bp]
	      	asli 	r4,r4,#1
	      	sc   	r3,linebuf[r4]
debugger_335:
	      	inc  	-40[bp],#1
	      	bra  	debugger_333
debugger_334:
	      	bsr  	dbg_parse_begin
	      	mov  	r3,r1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_336
	      	bra  	debugger_316
debugger_336:
	      	bra  	debugger_315
debugger_316:
	      	bra  	debugger_323
debugger_312:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_323
endpublic

public code dbg_init:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_338
	      	mov  	bp,sp
	      	push 	#dbg_irq
	      	push 	#496
	      	bsr  	set_vector
	      	addui	sp,sp,#16
	      	push 	#dbg_ssm
	      	push 	#495
	      	bsr  	set_vector
	      	addui	sp,sp,#16
	      	sw   	r0,ssm
	      	sw   	r0,bmem
	      	sw   	r0,cmem
	      	sw   	r0,hmem
	      	sw   	r0,wmem
	      	ldi  	r3,#65536
	      	sw   	r3,curaddr
	      	ldi  	r3,#16
	      	sw   	r3,muol
	      	ldi  	r3,#98
	      	sw   	r3,cursz
	      	ldi  	r3,#120
	      	sc   	r3,curfmt
	      	ldi  	r3,#1
	      	sw   	r3,currep
	      	sw   	r0,dbg_dbctrl
debugger_339:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_338:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_339
endpublic

	rodata
	align	16
	align	8
debugger_311:	; DBG>
	dc	13,10,68,66,71,62,0
debugger_188:
	dc	13,10,0
debugger_187:	; %016X 
	dc	37,48,49,54,88,32,0
debugger_186:	; %08X 
	dc	37,48,56,88,32,0
debugger_185:	; %04X 
	dc	37,48,52,88,32,0
debugger_184:	; %02X 
	dc	37,48,50,88,32,0
debugger_183:	; %06X 
	dc	13,10,37,48,54,88,32,0
debugger_182:
	dc	13,10,0
debugger_181:	; ds2=%08X
	dc	100,115,50,61,37,48,56,88
	dc	13,10,0
debugger_180:	; ds2=%08X
	dc	100,115,50,61,37,48,56,88
	dc	13,10,0
debugger_179:	; ds1=%08X
	dc	100,115,49,61,37,48,56,88
	dc	13,10,0
debugger_178:	; ds0=%08X
	dc	100,115,48,61,37,48,56,88
	dc	13,10,0
debugger_177:	; d2=%08X
	dc	100,50,61,37,48,56,88,13
	dc	10,0
debugger_176:	; d2=%08X
	dc	100,50,61,37,48,56,88,13
	dc	10,0
debugger_175:	; d1=%08X
	dc	100,49,61,37,48,56,88,13
	dc	10,0
debugger_174:	; d0=%08X
	dc	100,48,61,37,48,56,88,13
	dc	10,0
debugger_173:
	dc	13,10,0
debugger_172:	; i2=%08X
	dc	105,50,61,37,48,56,88,13
	dc	10,0
debugger_171:	; i2=%08X
	dc	105,50,61,37,48,56,88,13
	dc	10,0
debugger_170:	; i1=%08X
	dc	105,49,61,37,48,56,88,13
	dc	10,0
debugger_169:	; i0=%08X
	dc	105,48,61,37,48,56,88,13
	dc	10,0
debugger_143:	; DBG>
	dc	13,10,68,66,71,62,0
debugger_140:	; r%d=%X
	dc	114,37,100,61,37,88,13,10
	dc	0
debugger_136:	; r29=%X sp=%X lr=%X
	dc	114,50,57,61,37,88,32,115
	dc	112,61,37,88,32,108,114,61
	dc	37,88,13,10,0
debugger_135:	; r25=%X r26=%X r27=%X r28=%X
	dc	114,50,53,61,37,88,32,114
	dc	50,54,61,37,88,32,114,50
	dc	55,61,37,88,32,114,50,56
	dc	61,37,88,13,10,0
debugger_134:	; r21=%X r22=%X r23=%X tr=%X
	dc	114,50,49,61,37,88,32,114
	dc	50,50,61,37,88,32,114,50
	dc	51,61,37,88,32,116,114,61
	dc	37,88,13,10,0
debugger_133:	; r17=%X r18=%X r19=%X r20=%X
	dc	114,49,55,61,37,88,32,114
	dc	49,56,61,37,88,32,114,49
	dc	57,61,37,88,32,114,50,48
	dc	61,37,88,13,10,0
debugger_132:	; r13=%X r14=%X r15=%X r16=%X
	dc	114,49,51,61,37,88,32,114
	dc	49,52,61,37,88,32,114,49
	dc	53,61,37,88,32,114,49,54
	dc	61,37,88,13,10,0
debugger_131:	; r9=%X r10=%X r11=%X r12=%X
	dc	114,57,61,37,88,32,114,49
	dc	48,61,37,88,32,114,49,49
	dc	61,37,88,32,114,49,50,61
	dc	37,88,13,10,0
debugger_130:	; r5=%X r6=%X r7=%X r8=%X
	dc	114,53,61,37,88,32,114,54
	dc	61,37,88,32,114,55,61,37
	dc	88,32,114,56,61,37,88,13
	dc	10,0
debugger_129:	; r1=%X r2=%X r3=%X r4=%X
	dc	13,10,114,49,61,37,88,32
	dc	114,50,61,37,88,32,114,51
	dc	61,37,88,32,114,52,61,37
	dc	88,13,10,0
debugger_113:	; DBG>ds%d <not set>
	dc	13,10,68,66,71,62,100,115
	dc	37,100,32,60,110,111,116,32
	dc	115,101,116,62,0
debugger_112:	; DBG>ds%d=%08X
	dc	13,10,68,66,71,62,100,115
	dc	37,100,61,37,48,56,88,13
	dc	10,0
debugger_97:	; DBG>d%d <not set>
	dc	13,10,68,66,71,62,100,37
	dc	100,32,60,110,111,116,32,115
	dc	101,116,62,0
debugger_96:	; DBG>d%d=%08X
	dc	13,10,68,66,71,62,100,37
	dc	100,61,37,48,56,88,13,10
	dc	0
debugger_81:	; DBG>ib%d <not set>
	dc	13,10,68,66,71,62,105,98
	dc	37,100,32,60,110,111,116,32
	dc	115,101,116,62,0
debugger_80:	; DBG>ib%d=%08X
	dc	13,10,68,66,71,62,105,98
	dc	37,100,61,37,48,56,88,13
	dc	10,0
debugger_15:	; DBG>
	dc	13,10,68,66,71,62,0
debugger_14:	; Type 'q' to quit.
	dc	13,10,84,121,112,101,32,39
	dc	113,39,32,116,111,32,113,117
	dc	105,116,46,0
debugger_13:	; arm debugging mode using the 'a' command.
	dc	13,10,97,114,109,32,100,101
	dc	98,117,103,103,105,110,103,32
	dc	109,111,100,101,32,117,115,105
	dc	110,103,32,116,104,101,32,39
	dc	97,39,32,99,111,109,109,97
	dc	110,100,46,0
debugger_12:	; Once the debug registers are set it is necessary to 
	dc	13,10,79,110,99,101,32,116
	dc	104,101,32,100,101,98,117,103
	dc	32,114,101,103,105,115,116,101
	dc	114,115,32,97,114,101,32,115
	dc	101,116,32,105,116,32,105,115
	dc	32,110,101,99,101,115,115,97
	dc	114,121,32,116,111,32,0
debugger_11:	; Setting a register to zero will clear the breakpoint.
	dc	13,10,83,101,116,116,105,110
	dc	103,32,97,32,114,101,103,105
	dc	115,116,101,114,32,116,111,32
	dc	122,101,114,111,32,119,105,108
	dc	108,32,99,108,101,97,114,32
	dc	116,104,101,32,98,114,101,97
	dc	107,112,111,105,110,116,46,0
debugger_10:	; indicate a data store only breakpoint.
	dc	13,10,105,110,100,105,99,97
	dc	116,101,32,97,32,100,97,116
	dc	97,32,115,116,111,114,101,32
	dc	111,110,108,121,32,98,114,101
	dc	97,107,112,111,105,110,116,46
	dc	0
debugger_9:	; breakpoint. Prefix the register number with 'ds' to
	dc	13,10,98,114,101,97,107,112
	dc	111,105,110,116,46,32,80,114
	dc	101,102,105,120,32,116,104,101
	dc	32,114,101,103,105,115,116,101
	dc	114,32,110,117,109,98,101,114
	dc	32,119,105,116,104,32,39,100
	dc	115,39,32,116,111,0
debugger_8:	; instruction breakpoint or a 'd' to indicate a data
	dc	13,10,105,110,115,116,114,117
	dc	99,116,105,111,110,32,98,114
	dc	101,97,107,112,111,105,110,116
	dc	32,111,114,32,97,32,39,100
	dc	39,32,116,111,32,105,110,100
	dc	105,99,97,116,101,32,97,32
	dc	100,97,116,97,0
debugger_7:	; Prefix the register number with an 'i' to indicate an
	dc	13,10,80,114,101,102,105,120
	dc	32,116,104,101,32,114,101,103
	dc	105,115,116,101,114,32,110,117
	dc	109,98,101,114,32,119,105,116
	dc	104,32,97,110,32,39,105,39
	dc	32,116,111,32,105,110,100,105
	dc	99,97,116,101,32,97,110,0
debugger_6:	; There are a total of four breakpoint registers (0-3).
	dc	13,10,84,104,101,114,101,32
	dc	97,114,101,32,97,32,116,111
	dc	116,97,108,32,111,102,32,102
	dc	111,117,114,32,98,114,101,97
	dc	107,112,111,105,110,116,32,114
	dc	101,103,105,115,116,101,114,115
	dc	32,40,48,45,51,41,46,0
debugger_5:	; DBG>i1=12345678     will assign 12345678 to i1
	dc	13,10,68,66,71,62,105,49
	dc	61,49,50,51,52,53,54,55
	dc	56,32,32,32,32,32,119,105
	dc	108,108,32,97,115,115,105,103
	dc	110,32,49,50,51,52,53,54
	dc	55,56,32,116,111,32,105,49
	dc	0
debugger_4:	; an address to it.
	dc	13,10,97,110,32,97,100,100
	dc	114,101,115,115,32,116,111,32
	dc	105,116,46,0
debugger_3:	; Following a breakpoint register with an '=' assigns 
	dc	13,10,70,111,108,108,111,119
	dc	105,110,103,32,97,32,98,114
	dc	101,97,107,112,111,105,110,116
	dc	32,114,101,103,105,115,116,101
	dc	114,32,119,105,116,104,32,97
	dc	110,32,39,61,39,32,97,115
	dc	115,105,103,110,115,32,0
debugger_2:	; DBG>i2?
	dc	13,10,68,66,71,62,105,50
	dc	63,0
debugger_1:	; '?' queries the status of a breakpoint register as in:
	dc	13,10,39,63,39,32,113,117
	dc	101,114,105,101,115,32,116,104
	dc	101,32,115,116,97,116,117,115
	dc	32,111,102,32,97,32,98,114
	dc	101,97,107,112,111,105,110,116
	dc	32,114,101,103,105,115,116,101
	dc	114,32,97,115,32,105,110,58
	dc	0
;	global	dbg_dbctrl
;	global	GetVBR
;	global	dbg_parse_begin
;	global	dbg_ReadSetDSB
	extern	putch
;	global	dbg_prompt
	extern	getcharNoWait
;	global	cursz
;	global	CvtScreenToAscii
	extern	dbg_GetHexNumber
;	global	set_vector
;	global	dbg_init
;	global	dbg_getDecNumber
;	global	debugger
;	global	dbg_GetCursorCol
;	global	ssm
	extern	disassem
;	global	dbg_getHexNumber
;	global	ignore_blanks
;	global	dbg_GetCursorRow
;	global	dbg_nextNonSpace
;	global	dbg_getchar
;	global	repcount
;	global	dbg_ungetch
;	global	curfmt
;	global	currep
	extern	printf
;	global	dbg_HomeCursor
;	global	bmem
;	global	dbg_stack
;	global	cmem
;	global	hmem
;	global	dbg_processReg
;	global	dbg_parse_line
;	global	regs
;	global	cr0save
;	global	wmem
;	global	dbg_GetDBAD
;	global	dbg_ReadSetDB
	extern	disassem20
;	global	muol
;	global	dbg_ReadSetIB
;	global	dbg_SetDBAD
;	global	dbg_arm
;	global	dbg_irq
	extern	getchar
;	global	dbg_ssm
;	global	linebuf
;	global	curaddr
	extern	isdigit
;	global	linendx
