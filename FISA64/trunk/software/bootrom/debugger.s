	bss
	align	8
public bss linendx_:
	fill.b	8,0x00

endpublic
	align	8
public bss linebuf_:
	fill.b	200,0x00

endpublic
	align	8
public bss dbg_stack_:
	fill.b	8192,0x00

endpublic
	align	8
public bss dbg_dbctrl_:
	fill.b	8,0x00

endpublic
	align	8
public bss regs_:
	fill.b	256,0x00

endpublic
	align	8
public bss cr0save_:
	fill.b	8,0x00

endpublic
	align	8
public bss ssm_:
	fill.b	8,0x00

endpublic
	align	8
public bss repcount_:
	fill.b	8,0x00

endpublic
	align	8
public bss curaddr_:
	fill.b	8,0x00

endpublic
	align	8
public bss cursz_:
	fill.b	8,0x00

endpublic
	align	8
public bss curfill_:
	fill.b	8,0x00

endpublic
	align	8
public bss curfmt_:
	fill.b	2,0x00

endpublic
	data
	align	8
	fill.b	6,0x00
	bss
	align	8
public bss currep_:
	fill.b	8,0x00

endpublic
	align	8
public bss muol_:
	fill.b	8,0x00

endpublic
	align	8
public bss bmem_:
	fill.b	8,0x00

endpublic
	align	8
public bss cmem_:
	fill.b	8,0x00

endpublic
	align	8
public bss hmem_:
	fill.b	8,0x00

endpublic
	align	8
public bss wmem_:
	fill.b	8,0x00

endpublic
	code
	align	16
dbg_DisplayHelp_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_16
	      	mov  	bp,sp
	      	pea  	debugger_1[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_2[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_3[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_4[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_5[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_6[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_7[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_8[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_9[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_10[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_11[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_12[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_13[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_14[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	pea  	debugger_15[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
debugger_18:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_16:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_18
public code dbg_GetCursorRow_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        ldi    r6,#3   ; Get cursor position
        sys    #410
        lsr    r1,r1,#8
    
debugger_21:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_GetCursorCol_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        ldi    r6,#3
        sys    #410
        and    r1,r1,#$FF
    
debugger_24:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_HomeCursor_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         ldi   r6,#2
         ldi   r1,#0
         ldi   r2,#0
         sys   #410
     
debugger_27:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_GetDBAD_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,debugger_31
	      	cmp  	r4,r3,#1
	      	beq  	r4,debugger_32
	      	cmp  	r4,r3,#2
	      	beq  	r4,debugger_33
	      	cmp  	r4,r3,#3
	      	beq  	r4,debugger_34
	      	bra  	debugger_30
debugger_31:
	      	     	mfspr  r1,dbad0  
	      	bra  	debugger_30
debugger_32:
	      	     	mfspr  r1,dbad1  
	      	bra  	debugger_30
debugger_33:
	      	     	mfspr  r1,dbad2  
	      	bra  	debugger_30
debugger_34:
	      	     	mfspr  r1,dbad3  
	      	bra  	debugger_30
debugger_35:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
debugger_30:
	      	bra  	debugger_35
endpublic

public code dbg_SetDBAD_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,debugger_39
	      	cmp  	r4,r3,#1
	      	beq  	r4,debugger_40
	      	cmp  	r4,r3,#2
	      	beq  	r4,debugger_41
	      	cmp  	r4,r3,#3
	      	beq  	r4,debugger_42
	      	bra  	debugger_38
debugger_39:
	      	     	          lw    r1,32[bp]
          mtspr dbad0,r1
          
	      	bra  	debugger_38
debugger_40:
	      	     	          lw    r1,32[bp]
          mtspr dbad1,r1
          
	      	bra  	debugger_38
debugger_41:
	      	     	          lw    r1,32[bp]
          mtspr dbad2,r1
          
	      	bra  	debugger_38
debugger_42:
	      	     	          lw    r1,32[bp]
          mtspr dbad3,r1
          
	      	bra  	debugger_38
debugger_38:
debugger_43:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#32
endpublic

public code dbg_arm_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw    r1,24[bp]
         mtspr dbctrl,r1
     
debugger_46:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
endpublic

public code CvtScreenToAscii_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw    r1,24[bp]
         ldi   r6,#$21         ; screen to ascii
         sys   #410
     
debugger_49:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
endpublic

public code dbg_getchar_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	lea  	r3,linendx_[gp]
	      	mov  	r11,r3
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lw   	r3,[r11]
	      	cmp  	r4,r3,#84
	      	bge  	r4,debugger_52
	      	lw   	r4,[r11]
	      	asli 	r3,r4,#1
	      	lea  	r4,linebuf_[gp]
	      	lcu  	r5,0[r4+r3]
	      	sc   	r5,-2[bp]
	      	inc  	[r11],#1
debugger_52:
	      	lc   	r3,-2[bp]
	      	mov  	r1,r3
debugger_54:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code ignore_blanks_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
debugger_57:
	      	lw   	r4,linendx_[gp]
	      	asli 	r3,r4,#1
	      	lea  	r4,linebuf_[gp]
	      	lcu  	r5,0[r4+r3]
	      	sc   	r5,-2[bp]
	      	inc  	linendx_[gp],#1
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#32
	      	beq  	r4,debugger_57
debugger_58:
debugger_59:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_ungetch_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,linendx_[gp]
	      	ble  	r3,debugger_62
	      	dec  	linendx_[gp],#1
debugger_62:
debugger_64:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_nextNonSpace_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_65
	      	mov  	bp,sp
	      	subui	sp,sp,#8
debugger_67:
	      	lw   	r3,linendx_[gp]
	      	cmp  	r4,r3,#84
	      	bge  	r4,debugger_68
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#32
	      	bne  	r4,debugger_71
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#-1
	      	bne  	r4,debugger_69
debugger_71:
	      	lc   	r3,-2[bp]
	      	mov  	r1,r3
debugger_72:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_69:
	      	bra  	debugger_67
debugger_68:
	      	ldi  	r1,#-1
	      	bra  	debugger_72
debugger_65:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_72
endpublic

public code dbg_nextSpace_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_73
	      	mov  	bp,sp
	      	subui	sp,sp,#8
debugger_75:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#-1
	      	bne  	r4,debugger_77
	      	bra  	debugger_76
debugger_77:
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#32
	      	bne  	r4,debugger_75
debugger_76:
	      	lc   	r3,-2[bp]
	      	mov  	r1,r3
debugger_79:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_73:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_79
endpublic

	data
	align	8
	code
	align	16
public code dbg_getHexNumber_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_80
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	sw   	r0,-16[bp]
	      	sw   	r0,-24[bp]
	      	bsr  	dbg_nextNonSpace_
	      	dec  	linendx_[gp],#1
debugger_82:
	      	ldi  	r3,#1
	      	beq  	r3,debugger_83
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmpu 	r4,r3,#48
	      	blt  	r4,debugger_84
	      	lc   	r3,-2[bp]
	      	cmpu 	r4,r3,#57
	      	bgt  	r4,debugger_84
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#4
	      	lc   	r6,-2[bp]
	      	subu 	r5,r6,#48
	      	or   	r3,r4,r5
	      	sw   	r3,-16[bp]
	      	bra  	debugger_85
debugger_84:
	      	lc   	r3,-2[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,debugger_86
	      	lc   	r3,-2[bp]
	      	cmpu 	r4,r3,#70
	      	bgt  	r4,debugger_86
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#4
	      	lc   	r6,-2[bp]
	      	addu 	r5,r6,#-55
	      	or   	r3,r4,r5
	      	sw   	r3,-16[bp]
	      	bra  	debugger_87
debugger_86:
	      	lc   	r3,-2[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,debugger_88
	      	lc   	r3,-2[bp]
	      	cmpu 	r4,r3,#102
	      	bgt  	r4,debugger_88
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#4
	      	lc   	r6,-2[bp]
	      	addu 	r5,r6,#-87
	      	or   	r3,r4,r5
	      	sw   	r3,-16[bp]
	      	bra  	debugger_89
debugger_88:
	      	lw   	r3,24[bp]
	      	lw   	r4,-16[bp]
	      	sw   	r4,[r3]
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
debugger_90:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
debugger_89:
debugger_87:
debugger_85:
	      	lw   	r4,-24[bp]
	      	addu 	r3,r4,#1
	      	sw   	r3,-24[bp]
	      	bra  	debugger_82
debugger_83:
	      	bra  	debugger_90
debugger_80:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_90
endpublic

	data
	align	8
	code
	align	16
public code dbg_ReadSetIB_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_93
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	lea  	r3,dbg_dbctrl_[gp]
	      	mov  	r11,r3
	      	bsr  	dbg_nextNonSpace_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#61
	      	bne  	r4,debugger_95
	      	pea  	-16[bp]
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	ble  	r3,debugger_97
	      	push 	-16[bp]
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD_
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r3,r4,r5
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r5,#196608
	      	lw   	r7,24[bp]
	      	asli 	r6,r7,#1
	      	asl  	r4,r5,r6
	      	com  	r3,r4
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_98
debugger_97:
	      	push 	#0
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD_
	      	ldi  	r5,#1
	      	lw   	r6,24[bp]
	      	asl  	r4,r5,r6
	      	com  	r3,r4
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r5,#196608
	      	lw   	r7,24[bp]
	      	asli 	r6,r7,#1
	      	asl  	r4,r5,r6
	      	com  	r3,r4
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
debugger_98:
	      	bra  	debugger_96
debugger_95:
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	bne  	r4,debugger_99
	      	lw   	r4,[r11]
	      	ldi  	r6,#196608
	      	lw   	r8,24[bp]
	      	asli 	r7,r8,#1
	      	asl  	r5,r6,r7
	      	and  	r3,r4,r5
	      	bne  	r3,debugger_101
	      	lw   	r4,[r11]
	      	ldi  	r6,#1
	      	lw   	r7,24[bp]
	      	asl  	r5,r6,r7
	      	ldi  	r7,#1
	      	lw   	r8,24[bp]
	      	asl  	r6,r7,r8
	      	cmp  	r7,r5,r6
	      	bne  	r7,debugger_103
	      	ldi  	r5,#1
	      	bra  	debugger_104
debugger_103:
	      	ldi  	r5,#0
debugger_104:
	      	and  	r3,r4,r5
	      	beq  	r3,debugger_101
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	pea  	debugger_91[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#24
	      	bra  	debugger_102
debugger_101:
	      	push 	24[bp]
	      	pea  	debugger_92[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_102:
debugger_99:
debugger_96:
debugger_105:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
debugger_93:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_105
endpublic

	data
	align	8
	code
	align	16
public code dbg_ReadSetDB_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_108
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	lea  	r3,dbg_dbctrl_[gp]
	      	mov  	r11,r3
	      	lw   	r3,24[bp]
	      	cmpu 	r4,r3,#3
	      	ble  	r4,debugger_110
debugger_112:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
debugger_110:
	      	bsr  	dbg_nextNonSpace_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#61
	      	bne  	r4,debugger_113
	      	pea  	-16[bp]
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	ble  	r3,debugger_115
	      	push 	-16[bp]
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD_
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r3,r4,r5
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r5,#196608
	      	lw   	r7,24[bp]
	      	asli 	r6,r7,#1
	      	asl  	r4,r5,r6
	      	com  	r3,r4
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r4,#196608
	      	lw   	r6,24[bp]
	      	asli 	r5,r6,#1
	      	asl  	r3,r4,r5
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_116
debugger_115:
	      	push 	#0
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD_
	      	ldi  	r5,#1
	      	lw   	r6,24[bp]
	      	asl  	r4,r5,r6
	      	com  	r3,r4
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r5,#196608
	      	lw   	r7,24[bp]
	      	asli 	r6,r7,#1
	      	asl  	r4,r5,r6
	      	com  	r3,r4
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
debugger_116:
	      	bra  	debugger_114
debugger_113:
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	bne  	r4,debugger_117
	      	lw   	r4,[r11]
	      	ldi  	r6,#196608
	      	lw   	r8,24[bp]
	      	asli 	r7,r8,#1
	      	asl  	r5,r6,r7
	      	and  	r3,r4,r5
	      	ldi  	r5,#196608
	      	lw   	r7,24[bp]
	      	asli 	r6,r7,#1
	      	asl  	r4,r5,r6
	      	cmp  	r5,r3,r4
	      	bne  	r5,debugger_119
	      	lw   	r4,[r11]
	      	ldi  	r6,#1
	      	lw   	r7,24[bp]
	      	asl  	r5,r6,r7
	      	ldi  	r7,#1
	      	lw   	r8,24[bp]
	      	asl  	r6,r7,r8
	      	cmp  	r7,r5,r6
	      	bne  	r7,debugger_121
	      	ldi  	r5,#1
	      	bra  	debugger_122
debugger_121:
	      	ldi  	r5,#0
debugger_122:
	      	and  	r3,r4,r5
	      	beq  	r3,debugger_119
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	pea  	debugger_106[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#24
	      	bra  	debugger_120
debugger_119:
	      	push 	24[bp]
	      	pea  	debugger_107[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_120:
debugger_117:
debugger_114:
	      	bra  	debugger_112
debugger_108:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_112
endpublic

	data
	align	8
	code
	align	16
public code dbg_ReadSetDSB_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_125
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	lea  	r3,dbg_dbctrl_[gp]
	      	mov  	r11,r3
	      	lw   	r3,24[bp]
	      	cmpu 	r4,r3,#3
	      	ble  	r4,debugger_127
debugger_129:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
debugger_127:
	      	bsr  	dbg_nextNonSpace_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#61
	      	bne  	r4,debugger_130
	      	pea  	-16[bp]
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	ble  	r3,debugger_132
	      	push 	-16[bp]
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD_
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r3,r4,r5
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r5,#196608
	      	lw   	r7,24[bp]
	      	asli 	r6,r7,#1
	      	asl  	r4,r5,r6
	      	com  	r3,r4
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r4,#65536
	      	lw   	r6,24[bp]
	      	asli 	r5,r6,#1
	      	asl  	r3,r4,r5
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_133
debugger_132:
	      	push 	#0
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD_
	      	ldi  	r5,#1
	      	lw   	r6,24[bp]
	      	asl  	r4,r5,r6
	      	com  	r3,r4
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r5,#196608
	      	lw   	r7,24[bp]
	      	asli 	r6,r7,#1
	      	asl  	r4,r5,r6
	      	com  	r3,r4
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
debugger_133:
	      	bra  	debugger_131
debugger_130:
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	bne  	r4,debugger_134
	      	lw   	r4,[r11]
	      	ldi  	r6,#196608
	      	lw   	r8,24[bp]
	      	asli 	r7,r8,#1
	      	asl  	r5,r6,r7
	      	and  	r3,r4,r5
	      	ldi  	r5,#65536
	      	lw   	r7,24[bp]
	      	asli 	r6,r7,#1
	      	asl  	r4,r5,r6
	      	cmp  	r5,r3,r4
	      	bne  	r5,debugger_136
	      	lw   	r4,[r11]
	      	ldi  	r6,#1
	      	lw   	r7,24[bp]
	      	asl  	r5,r6,r7
	      	ldi  	r7,#1
	      	lw   	r8,24[bp]
	      	asl  	r6,r7,r8
	      	cmp  	r7,r5,r6
	      	bne  	r7,debugger_138
	      	ldi  	r5,#1
	      	bra  	debugger_139
debugger_138:
	      	ldi  	r5,#0
debugger_139:
	      	and  	r3,r4,r5
	      	beq  	r3,debugger_136
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	pea  	debugger_123[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#24
	      	bra  	debugger_137
debugger_136:
	      	push 	24[bp]
	      	pea  	debugger_124[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_137:
debugger_134:
debugger_131:
	      	bra  	debugger_129
debugger_125:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_129
endpublic

DispRegs_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_149
	      	mov  	bp,sp
	      	push 	r11
	      	lea  	r3,regs_[gp]
	      	mov  	r11,r3
	      	push 	32[r11]
	      	push 	24[r11]
	      	push 	16[r11]
	      	push 	8[r11]
	      	pea  	debugger_141[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	64[r11]
	      	push 	56[r11]
	      	push 	48[r11]
	      	push 	40[r11]
	      	pea  	debugger_142[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	96[r11]
	      	push 	88[r11]
	      	push 	80[r11]
	      	push 	72[r11]
	      	pea  	debugger_143[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	128[r11]
	      	push 	120[r11]
	      	push 	112[r11]
	      	push 	104[r11]
	      	pea  	debugger_144[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	160[r11]
	      	push 	152[r11]
	      	push 	144[r11]
	      	push 	136[r11]
	      	pea  	debugger_145[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	192[r11]
	      	push 	184[r11]
	      	push 	176[r11]
	      	push 	168[r11]
	      	pea  	debugger_146[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	224[r11]
	      	push 	216[r11]
	      	push 	208[r11]
	      	push 	200[r11]
	      	pea  	debugger_147[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	248[r11]
	      	push 	240[r11]
	      	push 	232[r11]
	      	pea  	debugger_148[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#32
debugger_151:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_149:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_151
DispReg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_154
	      	mov  	bp,sp
	      	lw   	r4,24[bp]
	      	asli 	r3,r4,#3
	      	lea  	r4,regs_[gp]
	      	lw   	r3,0[r4+r3]
	      	push 	r3
	      	push 	24[bp]
	      	pea  	debugger_153[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#24
debugger_156:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
debugger_154:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_156
public code dbg_prompt_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_158
	      	mov  	bp,sp
	      	pea  	debugger_157[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
debugger_160:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_158:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_160
endpublic

	data
	align	8
	code
	align	16
public code dbg_getDecNumber_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_161
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	lw   	r11,24[bp]
	      	bne  	r11,debugger_163
	      	ldi  	r1,#0
debugger_165:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
debugger_163:
	      	sw   	r0,-8[bp]
	      	sw   	r0,-24[bp]
debugger_166:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-10[bp]
	      	push 	-10[bp]
	      	bsr  	isdigit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,debugger_167
	      	ldi  	r4,#-48
	      	lw   	r7,-8[bp]
	      	mul  	r6,r7,#10
	      	lc   	r7,-10[bp]
	      	addu 	r5,r6,r7
	      	addu 	r3,r4,r5
	      	sw   	r3,-8[bp]
	      	inc  	-24[bp],#1
	      	bra  	debugger_166
debugger_167:
	      	dec  	linendx_[gp],#1
	      	lw   	r3,-8[bp]
	      	sw   	r3,[r11]
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
	      	bra  	debugger_165
debugger_161:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_165
endpublic

	data
	align	8
	code
	align	16
public code dbg_processReg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_168
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_171
	      	bra  	debugger_172
debugger_171:
	      	bsr  	DispRegs_
	      	bra  	debugger_170
debugger_172:
	      	lc   	r3,-2[bp]
	      	push 	r3
	      	bsr  	isdigit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,debugger_173
	      	dec  	linendx_[gp],#1
	      	bsr  	dbg_getDecNumber_
	      	mov  	r3,r1
	      	sw   	r3,-16[bp]
	      	bsr  	dbg_nextNonSpace_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_176
	      	cmp  	r4,r3,#61
	      	beq  	r4,debugger_177
	      	bra  	debugger_178
debugger_176:
	      	push 	-16[bp]
	      	bsr  	DispReg_
debugger_179:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_177:
	      	pea  	-24[bp]
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-32[bp]
	      	lw   	r3,-32[bp]
	      	ble  	r3,debugger_180
	      	lw   	r4,-16[bp]
	      	asli 	r3,r4,#3
	      	lea  	r4,regs_[gp]
	      	lw   	r5,-24[bp]
	      	sw   	r5,0[r4+r3]
debugger_180:
	      	bra  	debugger_179
debugger_178:
	      	bra  	debugger_179
debugger_175:
debugger_173:
	      	bra  	debugger_179
debugger_170:
	      	bra  	debugger_179
debugger_168:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_179
endpublic

public code dbg_parse_begin_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_182
	      	mov  	bp,sp
	      	push 	r11
	      	lea  	r3,linebuf_[gp]
	      	mov  	r11,r3
	      	sw   	r0,linendx_[gp]
	      	lc   	r3,[r11]
	      	cmp  	r4,r3,#68
	      	bne  	r4,debugger_184
	      	lc   	r3,2[r11]
	      	cmp  	r4,r3,#66
	      	bne  	r4,debugger_184
	      	lc   	r3,4[r11]
	      	cmp  	r4,r3,#71
	      	bne  	r4,debugger_184
	      	lc   	r3,6[r11]
	      	cmp  	r4,r3,#62
	      	bne  	r4,debugger_184
	      	ldi  	r3,#4
	      	sw   	r3,linendx_[gp]
debugger_184:
	      	bsr  	dbg_parse_line_
	      	mov  	r3,r1
	      	mov  	r1,r3
debugger_186:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_182:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_186
endpublic

	data
	align	8
	code
	align	16
public code dbg_getDumpFormat_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_187
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	push 	r15
	      	lea  	r3,-32[bp]
	      	mov  	r11,r3
	      	lea  	r3,muol_[gp]
	      	mov  	r12,r3
	      	lea  	r3,cursz_[gp]
	      	mov  	r13,r3
	      	lea  	r3,curaddr_[gp]
	      	mov  	r14,r3
	      	lea  	r3,curfmt_[gp]
	      	mov  	r15,r3
	      	pea  	-24[bp]
	      	bsr  	dbg_getDecNumber_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	ble  	r3,debugger_189
	      	lw   	r3,-24[bp]
	      	sw   	r3,currep_[gp]
debugger_189:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-10[bp]
	      	lc   	r3,-10[bp]
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_192
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_193
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_194
	      	bra  	debugger_191
debugger_192:
	      	ldi  	r3,#105
	      	andi 	r3,r3,#65535
	      	sc   	r3,[r15]
	      	push 	r11
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	ble  	r3,debugger_195
	      	lw   	r3,[r11]
	      	sw   	r3,[r14]
debugger_195:
	      	bra  	debugger_191
debugger_193:
	      	ldi  	r3,#115
	      	andi 	r3,r3,#65535
	      	sc   	r3,[r15]
	      	push 	r11
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	ble  	r3,debugger_197
	      	lw   	r3,[r11]
	      	sw   	r3,[r14]
debugger_197:
	      	bra  	debugger_191
debugger_194:
	      	ldi  	r3,#120
	      	andi 	r3,r3,#65535
	      	sc   	r3,[r15]
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-10[bp]
	      	lc   	r3,-10[bp]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_200
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_201
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_202
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_203
	      	bra  	debugger_204
debugger_200:
	      	ldi  	r3,#98
	      	sw   	r3,[r13]
	      	ldi  	r3,#16
	      	sw   	r3,[r12]
	      	bra  	debugger_199
debugger_201:
	      	ldi  	r3,#99
	      	sw   	r3,[r13]
	      	ldi  	r3,#8
	      	sw   	r3,[r12]
	      	bra  	debugger_199
debugger_202:
	      	ldi  	r3,#104
	      	sw   	r3,[r13]
	      	ldi  	r3,#4
	      	sw   	r3,[r12]
	      	bra  	debugger_199
debugger_203:
	      	ldi  	r3,#119
	      	sw   	r3,[r13]
	      	ldi  	r3,#2
	      	sw   	r3,[r12]
	      	bra  	debugger_199
debugger_204:
	      	dec  	linendx_[gp],#1
debugger_199:
	      	push 	r11
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	ble  	r3,debugger_205
	      	lw   	r3,[r11]
	      	sw   	r3,[r14]
debugger_205:
	      	bra  	debugger_191
debugger_191:
debugger_207:
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
debugger_187:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_207
endpublic

	data
	align	8
	code
	align	16
public code dbg_parse_line_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_232
	      	mov  	bp,sp
	      	subui	sp,sp,#56
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	push 	r15
	      	push 	r16
	      	push 	r17
	      	lea  	r3,curaddr_[gp]
	      	mov  	r11,r3
	      	lea  	r3,cmem_[gp]
	      	mov  	r12,r3
	      	lea  	r3,currep_[gp]
	      	mov  	r13,r3
	      	lea  	r3,cursz_[gp]
	      	mov  	r14,r3
	      	lea  	r3,curfill_[gp]
	      	mov  	r15,r3
	      	lea  	r3,curfmt_[gp]
	      	mov  	r16,r3
	      	lea  	r3,-16[bp]
	      	mov  	r17,r3
debugger_234:
	      	lw   	r3,linendx_[gp]
	      	cmp  	r4,r3,#84
	      	bge  	r4,debugger_235
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#-1
	      	beq  	r4,debugger_237
	      	cmp  	r4,r3,#32
	      	beq  	r4,debugger_238
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_239
	      	cmp  	r4,r3,#113
	      	beq  	r4,debugger_240
	      	cmp  	r4,r3,#97
	      	beq  	r4,debugger_241
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_242
	      	cmp  	r4,r3,#100
	      	beq  	r4,debugger_243
	      	cmp  	r4,r3,#114
	      	beq  	r4,debugger_244
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_245
	      	cmp  	r4,r3,#102
	      	beq  	r4,debugger_246
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_247
	      	bra  	debugger_236
debugger_237:
debugger_248:
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
debugger_238:
	      	bra  	debugger_236
debugger_239:
	      	bsr  	dbg_DisplayHelp_
	      	bra  	debugger_236
debugger_240:
	      	ldi  	r1,#1
	      	bra  	debugger_248
debugger_241:
	      	push 	dbg_dbctrl_[gp]
	      	bsr  	dbg_arm_
	      	bra  	debugger_236
debugger_242:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_250
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_251
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_252
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_253
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_254
	      	bra  	debugger_249
debugger_250:
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#196608
	      	bne  	r3,debugger_255
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#1
	      	cmp  	r4,r3,#1
	      	bne  	r4,debugger_255
	      	push 	#0
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	pea  	debugger_208[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_255:
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#3145728
	      	bne  	r3,debugger_257
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#2
	      	cmp  	r4,r3,#2
	      	bne  	r4,debugger_257
	      	push 	#1
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	pea  	debugger_209[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_257:
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#50331648
	      	bne  	r3,debugger_259
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#4
	      	cmp  	r4,r3,#4
	      	bne  	r4,debugger_259
	      	push 	#2
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	pea  	debugger_210[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_259:
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#805306368
	      	bne  	r3,debugger_261
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#8
	      	cmp  	r4,r3,#8
	      	bne  	r4,debugger_261
	      	push 	#3
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	pea  	debugger_211[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_261:
	      	bra  	debugger_249
debugger_251:
	      	push 	#0
	      	bsr  	dbg_ReadSetIB_
	      	bra  	debugger_249
debugger_252:
	      	push 	#1
	      	bsr  	dbg_ReadSetIB_
	      	bra  	debugger_249
debugger_253:
	      	push 	#2
	      	bsr  	dbg_ReadSetIB_
	      	bra  	debugger_249
debugger_254:
	      	push 	#3
	      	bsr  	dbg_ReadSetIB_
	      	bra  	debugger_249
debugger_249:
	      	bra  	debugger_236
debugger_243:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_264
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_265
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_266
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_267
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_268
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_269
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_270
	      	bra  	debugger_271
debugger_264:
	      	bsr  	dbg_nextSpace_
	      	push 	r17
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_272
	      	pea  	-24[bp]
	      	bsr  	dbg_getDecNumber_
	      	mov  	r3,r1
	      	sw   	r3,-56[bp]
	      	lw   	r3,-56[bp]
	      	ble  	r3,debugger_274
debugger_276:
	      	lw   	r3,-56[bp]
	      	ble  	r3,debugger_277
	      	push 	#0
	      	push 	r17
	      	bsr  	disassem_
	      	addui	sp,sp,#16
debugger_278:
	      	dec  	-56[bp],#1
	      	bra  	debugger_276
debugger_277:
	      	bra  	debugger_275
debugger_274:
	      	push 	#0
	      	push 	[r17]
	      	bsr  	disassem20_
	      	addui	sp,sp,#16
debugger_275:
debugger_272:
	      	bra  	debugger_263
debugger_265:
	      	pea  	debugger_212[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#196608
	      	cmp  	r4,r3,#196608
	      	bne  	r4,debugger_279
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#1
	      	cmp  	r4,r3,#1
	      	bne  	r4,debugger_279
	      	push 	#0
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	pea  	debugger_213[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_279:
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#3145728
	      	cmp  	r4,r3,#3145728
	      	bne  	r4,debugger_281
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#2
	      	cmp  	r4,r3,#2
	      	bne  	r4,debugger_281
	      	push 	#1
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	pea  	debugger_214[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_281:
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#50331648
	      	cmp  	r4,r3,#50331648
	      	bne  	r4,debugger_283
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#4
	      	cmp  	r4,r3,#4
	      	bne  	r4,debugger_283
	      	push 	#2
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	pea  	debugger_215[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_283:
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#805306368
	      	cmp  	r4,r3,#805306368
	      	bne  	r4,debugger_285
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#8
	      	cmp  	r4,r3,#8
	      	bne  	r4,debugger_285
	      	push 	#3
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	pea  	debugger_216[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_285:
	      	bra  	debugger_263
debugger_266:
	      	push 	#0
	      	bsr  	dbg_ReadSetDB_
	      	bra  	debugger_263
debugger_267:
	      	push 	#1
	      	bsr  	dbg_ReadSetDB_
	      	bra  	debugger_263
debugger_268:
	      	push 	#2
	      	bsr  	dbg_ReadSetDB_
	      	bra  	debugger_263
debugger_269:
	      	push 	#3
	      	bsr  	dbg_ReadSetDB_
	      	bra  	debugger_263
debugger_270:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_288
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_289
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_290
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_291
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_292
	      	bra  	debugger_287
debugger_288:
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#196608
	      	cmp  	r4,r3,#65536
	      	bne  	r4,debugger_293
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#1
	      	cmp  	r4,r3,#1
	      	bne  	r4,debugger_293
	      	push 	#0
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	pea  	debugger_217[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_293:
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#3145728
	      	cmp  	r4,r3,#1048576
	      	bne  	r4,debugger_295
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#2
	      	cmp  	r4,r3,#2
	      	bne  	r4,debugger_295
	      	push 	#1
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	pea  	debugger_218[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_295:
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#50331648
	      	cmp  	r4,r3,#16777216
	      	bne  	r4,debugger_297
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#4
	      	cmp  	r4,r3,#4
	      	bne  	r4,debugger_297
	      	push 	#2
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	pea  	debugger_219[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_297:
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#805306368
	      	cmp  	r4,r3,#268435456
	      	bne  	r4,debugger_299
	      	lw   	r4,dbg_dbctrl_[gp]
	      	and  	r3,r4,#8
	      	cmp  	r4,r3,#8
	      	bne  	r4,debugger_299
	      	push 	#3
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	pea  	debugger_220[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_299:
	      	bra  	debugger_287
debugger_289:
	      	push 	#0
	      	bsr  	dbg_ReadSetDSB_
	      	bra  	debugger_287
debugger_290:
	      	push 	#1
	      	bsr  	dbg_ReadSetDSB_
	      	bra  	debugger_287
debugger_291:
	      	push 	#2
	      	bsr  	dbg_ReadSetDSB_
	      	bra  	debugger_287
debugger_292:
	      	push 	#3
	      	bsr  	dbg_ReadSetDSB_
	      	bra  	debugger_287
debugger_287:
	      	bra  	debugger_263
debugger_271:
	      	bsr  	dbg_nextSpace_
	      	push 	#0
	      	push 	#0
	      	bsr  	dbg_SetDBAD_
	      	push 	#0
	      	push 	#1
	      	bsr  	dbg_SetDBAD_
	      	push 	#0
	      	push 	#2
	      	bsr  	dbg_SetDBAD_
	      	push 	#0
	      	push 	#3
	      	bsr  	dbg_SetDBAD_
	      	push 	#0
	      	bsr  	dbg_arm_
	      	bra  	debugger_263
debugger_263:
	      	bra  	debugger_236
debugger_244:
	      	bsr  	dbg_processReg_
	      	bra  	debugger_236
debugger_245:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#115
	      	bne  	r4,debugger_301
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#45
	      	bne  	r4,debugger_303
	      	lw   	r3,dbg_dbctrl_[gp]
	      	andi 	r3,r3,#4611686018427387903
	      	sw   	r3,dbg_dbctrl_[gp]
	      	push 	dbg_dbctrl_[gp]
	      	bsr  	dbg_arm_
	      	sw   	r0,ssm_[gp]
	      	bra  	debugger_304
debugger_303:
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#43
	      	beq  	r4,debugger_307
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#109
	      	bne  	r4,debugger_305
debugger_307:
	      	lw   	r3,dbg_dbctrl_[gp]
	      	ori  	r3,r3,#4611686018427387904
	      	sw   	r3,dbg_dbctrl_[gp]
	      	push 	dbg_dbctrl_[gp]
	      	bsr  	dbg_arm_
	      	ldi  	r3,#1
	      	sw   	r3,ssm_[gp]
	      	ldi  	r1,#1
	      	bra  	debugger_248
debugger_305:
debugger_304:
debugger_301:
	      	bra  	debugger_236
debugger_246:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#47
	      	bne  	r4,debugger_308
	      	bsr  	dbg_getDumpFormat_
debugger_308:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#44
	      	bne  	r4,debugger_310
	      	lc   	r3,[r16]
	      	cmp  	r4,r3,#120
	      	bne  	r4,debugger_312
	      	pea  	-40[bp]
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	bra  	debugger_313
debugger_312:
	      	pea  	-40[bp]
	      	bsr  	dbg_getDecNumber_
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
debugger_313:
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_314
	      	lw   	r3,-40[bp]
	      	sw   	r3,[r15]
debugger_314:
debugger_310:
	      	lc   	r3,[r16]
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_317
	      	bra  	debugger_316
debugger_317:
	      	lw   	r3,[r14]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_319
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_320
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_321
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_322
	      	bra  	debugger_318
debugger_319:
	      	sw   	r0,-48[bp]
debugger_323:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_324
	      	lw   	r4,[r17]
	      	lw   	r5,-48[bp]
	      	addu 	r3,r4,r5
	      	lw   	r4,bmem_[gp]
	      	lb   	r5,[r15]
	      	andi 	r5,r5,#255
	      	sb   	r5,0[r4+r3]
debugger_325:
	      	inc  	-48[bp],#1
	      	bra  	debugger_323
debugger_324:
	      	bra  	debugger_318
debugger_320:
	      	sw   	r0,-48[bp]
debugger_326:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_327
	      	lw   	r6,[r17]
	      	asri 	r5,r6,#1
	      	lw   	r6,-48[bp]
	      	addu 	r4,r5,r6
	      	asli 	r3,r4,#1
	      	lw   	r4,[r12]
	      	lc   	r5,[r15]
	      	andi 	r5,r5,#65535
	      	sc   	r5,0[r4+r3]
debugger_328:
	      	inc  	-48[bp],#1
	      	bra  	debugger_326
debugger_327:
	      	bra  	debugger_318
debugger_321:
	      	sw   	r0,-48[bp]
debugger_329:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_330
	      	lw   	r6,[r17]
	      	asri 	r5,r6,#2
	      	lw   	r6,-48[bp]
	      	addu 	r4,r5,r6
	      	asli 	r3,r4,#2
	      	lw   	r4,hmem_[gp]
	      	lh   	r5,[r15]
	      	andi 	r5,r5,#4294967295
	      	sh   	r5,0[r4+r3]
debugger_331:
	      	inc  	-48[bp],#1
	      	bra  	debugger_329
debugger_330:
	      	bra  	debugger_318
debugger_322:
	      	sw   	r0,-48[bp]
debugger_332:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_333
	      	lw   	r6,[r17]
	      	asri 	r5,r6,#3
	      	lw   	r6,-48[bp]
	      	addu 	r4,r5,r6
	      	asli 	r3,r4,#3
	      	lw   	r4,wmem_[gp]
	      	lw   	r5,[r15]
	      	sw   	r5,0[r4+r3]
debugger_334:
	      	inc  	-48[bp],#1
	      	bra  	debugger_332
debugger_333:
	      	bra  	debugger_318
debugger_318:
debugger_316:
	      	bra  	debugger_236
debugger_247:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#47
	      	bne  	r4,debugger_335
	      	bsr  	dbg_getDumpFormat_
debugger_335:
	      	lc   	r3,[r16]
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_338
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_339
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_340
	      	bra  	debugger_337
debugger_338:
	      	pea  	debugger_221[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	sw   	r0,-48[bp]
debugger_341:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_342
	      	bsr  	getcharNoWait_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#3
	      	bne  	r4,debugger_344
	      	bra  	debugger_342
debugger_344:
	      	push 	#0
	      	push 	r11
	      	bsr  	disassem_
	      	addui	sp,sp,#16
debugger_343:
	      	inc  	-48[bp],#1
	      	bra  	debugger_341
debugger_342:
	      	bra  	debugger_337
debugger_339:
	      	sw   	r0,-48[bp]
debugger_346:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_347
	      	bsr  	getcharNoWait_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#3
	      	bne  	r4,debugger_349
	      	bra  	debugger_347
debugger_349:
	      	push 	r3
	      	push 	#84
	      	lw   	r7,[r11]
	      	asri 	r6,r7,#1
	      	asli 	r5,r6,#1
	      	lw   	r6,[r12]
	      	addu 	r4,r5,r6
	      	push 	r4
	      	bsr  	putstr_
	      	addui	sp,sp,#16
	      	pop  	r3
	      	mov  	r4,r1
	      	asli 	r3,r4,#1
	      	lw   	r4,[r11]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r11]
	      	pea  	debugger_222[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
debugger_348:
	      	inc  	-48[bp],#1
	      	bra  	debugger_346
debugger_347:
	      	bra  	debugger_337
debugger_340:
	      	sw   	r0,-48[bp]
debugger_351:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_352
	      	bsr  	getcharNoWait_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#3
	      	bne  	r4,debugger_354
	      	bra  	debugger_352
debugger_354:
	      	lw   	r4,-48[bp]
	      	lw   	r5,muol_[gp]
	      	modu 	r3,r4,r5
	      	bne  	r3,debugger_356
	      	lw   	r3,[r14]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_359
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_360
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_361
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_362
	      	bra  	debugger_358
debugger_359:
	      	lw   	r4,[r11]
	      	lw   	r5,-48[bp]
	      	addu 	r3,r4,r5
	      	push 	r3
	      	pea  	debugger_223[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_358
debugger_360:
	      	lw   	r4,[r11]
	      	lw   	r6,-48[bp]
	      	asli 	r5,r6,#1
	      	addu 	r3,r4,r5
	      	push 	r3
	      	pea  	debugger_224[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_358
debugger_361:
	      	lw   	r4,[r11]
	      	lw   	r6,-48[bp]
	      	asli 	r5,r6,#2
	      	addu 	r3,r4,r5
	      	push 	r3
	      	pea  	debugger_225[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_358
debugger_362:
	      	lw   	r4,[r11]
	      	lw   	r6,-48[bp]
	      	asli 	r5,r6,#3
	      	addu 	r3,r4,r5
	      	push 	r3
	      	pea  	debugger_226[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_358
debugger_358:
debugger_356:
	      	     	 right here ; 
	      	lw   	r3,[r14]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_364
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_365
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_366
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_367
	      	bra  	debugger_363
debugger_364:
	      	lw   	r4,[r11]
	      	lw   	r5,-48[bp]
	      	addu 	r3,r4,r5
	      	lw   	r4,bmem_[gp]
	      	lb   	r3,0[r4+r3]
	      	push 	r3
	      	pea  	debugger_227[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_363
debugger_365:
	      	lw   	r6,[r11]
	      	asri 	r5,r6,#1
	      	lw   	r6,-48[bp]
	      	addu 	r4,r5,r6
	      	asli 	r3,r4,#1
	      	lw   	r4,[r12]
	      	lc   	r3,0[r4+r3]
	      	push 	r3
	      	pea  	debugger_228[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_363
debugger_366:
	      	lw   	r6,[r11]
	      	asri 	r5,r6,#2
	      	lw   	r6,-48[bp]
	      	addu 	r4,r5,r6
	      	asli 	r3,r4,#2
	      	lw   	r4,hmem_[gp]
	      	lh   	r3,0[r4+r3]
	      	push 	r3
	      	pea  	debugger_229[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_363
debugger_367:
	      	lw   	r6,[r11]
	      	asri 	r5,r6,#3
	      	lw   	r6,-48[bp]
	      	addu 	r4,r5,r6
	      	asli 	r3,r4,#3
	      	lw   	r4,wmem_[gp]
	      	lw   	r3,0[r4+r3]
	      	push 	r3
	      	pea  	debugger_230[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_363
debugger_363:
debugger_353:
	      	inc  	-48[bp],#1
	      	bra  	debugger_351
debugger_352:
	      	lw   	r3,[r14]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_369
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_370
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_371
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_372
	      	bra  	debugger_368
debugger_369:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r11]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_368
debugger_370:
	      	lw   	r4,-48[bp]
	      	asli 	r3,r4,#1
	      	lw   	r4,[r11]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_368
debugger_371:
	      	lw   	r4,-48[bp]
	      	asli 	r3,r4,#2
	      	lw   	r4,[r11]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_368
debugger_372:
	      	lw   	r4,-48[bp]
	      	asli 	r3,r4,#3
	      	lw   	r4,[r11]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_368
debugger_368:
	      	pea  	debugger_231[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	debugger_337
debugger_337:
debugger_236:
	      	bra  	debugger_234
debugger_235:
	      	ldi  	r1,#0
	      	bra  	debugger_248
debugger_232:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_248
endpublic

public code dbg_irq_:
	      	     	         lea   sp,dbg_stack_+8192-8
         sw    r1,regs_+8
         sw    r2,regs_+16
         sw    r3,regs_+24
         sw    r4,regs_+32
         sw    r5,regs_+40
         sw    r6,regs_+48
         sw    r7,regs_+56
         sw    r8,regs_+64
         sw    r9,regs_+72
         sw    r10,regs_+80
         sw    r11,regs_+88
         sw    r12,regs_+96
         sw    r13,regs_+104
         sw    r14,regs_+112
         sw    r15,regs_+120
         sw    r16,regs_+128
         sw    r17,regs_+136
         sw    r18,regs_+144
         sw    r19,regs_+152
         sw    r20,regs_+160
         sw    r21,regs_+168
         sw    r22,regs_+176
         sw    r23,regs_+184
         sw    r24,regs_+192
         sw    r25,regs_+200
         sw    r26,regs_+208
         sw    r27,regs_+216
         sw    r28,regs_+224
         sw    r29,regs_+232
         sw    r30,regs_+240
         sw    r31,regs_+248
         mfspr r1,cr0
         sw    r1,cr0save_

         mfspr r1,dbctrl
         push  r1
         mtspr dbctrl,r0
         mfspr r1,dpc
         push  r1
         bsr   debugger_
         addui sp,sp,#16
         
         lw    r1,cr0save_
         mtspr cr0,r1
         lw    r1,regs_+8
         lw    r2,regs_+16
         lw    r3,regs_+24
         lw    r4,regs_+32
         lw    r5,regs_+40
         lw    r6,regs_+48
         lw    r7,regs_+56
         lw    r8,regs_+64
         lw    r9,regs_+72
         lw    r10,regs_+80
         lw    r11,regs_+88
         lw    r12,regs_+96
         lw    r13,regs_+104
         lw    r14,regs_+112
         lw    r15,regs_+120
         lw    r16,regs_+128
         lw    r17,regs_+136
         lw    r18,regs_+144
         lw    r19,regs_+152
         lw    r20,regs_+160
         lw    r21,regs_+168
         lw    r22,regs_+176
         lw    r23,regs_+184
         lw    r24,regs_+192
         lw    r25,regs_+200
         lw    r26,regs_+208
         lw    r27,regs_+216
         lw    r28,regs_+224
         lw    r29,regs_+232
         lw    r30,regs_+240
         lw    r31,regs_+248
         rtd
     
endpublic

public code debugger_task_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_376
	      	mov  	bp,sp
	      	push 	#0
	      	push 	#0
	      	bsr  	debugger_
	      	addui	sp,sp,#16
	      	ldi  	r1,#0
debugger_378:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_376:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_378
endpublic

	data
	align	8
	code
	align	16
public code debugger_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_380
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	lea  	r3,bmem_[gp]
	      	mov  	r11,r3
	      	lea  	r3,ssm_[gp]
	      	mov  	r12,r3
	      	lea  	r3,dbg_dbctrl_[gp]
	      	mov  	r13,r3
	      	lw   	r3,32[bp]
	      	sw   	r3,[r13]
	      	ldi  	r3,#4291821568
	      	mov  	r14,r3
	      	lw   	r4,24[bp]
	      	and  	r3,r4,#-4
	      	sw   	r3,24[bp]
	      	lw   	r3,24[bp]
	      	beq  	r3,debugger_382
	      	push 	24[bp]
	      	lw   	r4,24[bp]
	      	subu 	r3,r4,#16
	      	push 	r3
	      	bsr  	disassem20_
	      	addui	sp,sp,#16
debugger_382:
debugger_384:
	      	pea  	debugger_379[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
debugger_386:
	      	bsr  	getchar_
	      	mov  	r3,r1
	      	andi 	r3,r3,#65535
	      	sc   	r3,-2[bp]
	      	lw   	r3,[r12]
	      	beq  	r3,debugger_388
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#115
	      	bne  	r4,debugger_390
	      	lw   	r3,[r13]
	      	andi 	r3,r3,#4611686018426404862
	      	sw   	r3,[r13]
	      	lw   	r3,[r13]
	      	ori  	r3,r3,#4611686018427387904
	      	sw   	r3,[r13]
	      	push 	[r13]
	      	bsr  	dbg_arm_
debugger_392:
	      	pop  	r14
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_390:
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#45
	      	beq  	r4,debugger_395
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#3
	      	bne  	r4,debugger_393
debugger_395:
	      	sw   	r0,[r12]
	      	lw   	r3,[r13]
	      	andi 	r3,r3,#4611686018427387903
	      	sw   	r3,[r13]
	      	push 	[r13]
	      	bsr  	dbg_arm_
	      	bra  	debugger_392
debugger_393:
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#110
	      	bne  	r4,debugger_396
	      	ldi  	r3,#2
	      	sw   	r3,[r12]
	      	lw   	r3,[r13]
	      	andi 	r3,r3,#4611686018426404863
	      	sw   	r3,[r13]
	      	lw   	r3,[r13]
	      	ori  	r3,r3,#524289
	      	sw   	r3,[r13]
	      	lw   	r4,24[bp]
	      	lw   	r5,[r11]
	      	lb   	r4,0[r5+r4]
	      	and  	r3,r4,#127
	      	cmp  	r4,r3,#124
	      	bne  	r4,debugger_398
	      	lw   	r5,24[bp]
	      	addu 	r4,r5,#4
	      	lw   	r5,[r11]
	      	lb   	r4,0[r5+r4]
	      	and  	r3,r4,#127
	      	cmp  	r4,r3,#124
	      	bne  	r4,debugger_398
	      	inc  	24[bp],#12
	      	bra  	debugger_399
debugger_398:
	      	lw   	r4,24[bp]
	      	lw   	r5,[r11]
	      	lb   	r4,0[r5+r4]
	      	and  	r3,r4,#127
	      	cmp  	r4,r3,#124
	      	bne  	r4,debugger_400
	      	inc  	24[bp],#8
	      	bra  	debugger_401
debugger_400:
	      	inc  	24[bp],#4
debugger_401:
debugger_399:
	      	push 	24[bp]
	      	push 	#0
	      	bsr  	dbg_SetDBAD_
	      	push 	[r13]
	      	bsr  	dbg_arm_
	      	bra  	debugger_392
debugger_396:
	      	bra  	debugger_389
debugger_388:
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#13
	      	bne  	r4,debugger_402
	      	bra  	debugger_387
debugger_402:
	      	lc   	r3,-2[bp]
	      	cmp  	r4,r3,#12
	      	bne  	r4,debugger_404
	      	     	                           bsr ClearScreen_
                       
	      	bsr  	dbg_HomeCursor_
	      	bra  	debugger_387
debugger_404:
	      	lc   	r3,-2[bp]
	      	push 	r3
	      	bsr  	putch_
debugger_389:
	      	ldi  	r3,#1
	      	bne  	r3,debugger_386
debugger_387:
	      	bsr  	dbg_GetCursorRow_
	      	mov  	r3,r1
	      	sxb  	r3,r3
	      	sw   	r3,-16[bp]
	      	bsr  	dbg_GetCursorCol_
	      	mov  	r3,r1
	      	sxb  	r3,r3
	      	sw   	r3,-24[bp]
	      	sw   	r0,-40[bp]
debugger_406:
	      	lw   	r3,-40[bp]
	      	cmp  	r4,r3,#84
	      	bge  	r4,debugger_407
	      	lw   	r4,-40[bp]
	      	asli 	r3,r4,#1
	      	pea  	linebuf_[gp]
	      	push 	r4
	      	lw   	r9,-16[bp]
	      	mul  	r8,r9,#84
	      	lw   	r9,-40[bp]
	      	addu 	r7,r8,r9
	      	asli 	r6,r7,#2
	      	lh   	r6,0[r14+r6]
	      	and  	r5,r6,#1023
	      	push 	r5
	      	bsr  	CvtScreenToAscii_
	      	pop  	r4
	      	pop  	r3
	      	mov  	r5,r1
	      	sxc  	r5,r5
	      	andi 	r5,r5,#65535
	      	sc   	r5,0[r4+r3]
debugger_408:
	      	inc  	-40[bp],#1
	      	bra  	debugger_406
debugger_407:
	      	bsr  	dbg_parse_begin_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#1
	      	bne  	r4,debugger_409
	      	bra  	debugger_385
debugger_409:
	      	bra  	debugger_384
debugger_385:
	      	bra  	debugger_392
debugger_380:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_392
endpublic

public code dbg_init_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_411
	      	mov  	bp,sp
	      	     	            ldi   r1,#60
            sc    r1,LEDS
        
	      	push 	#dbg_irq_
	      	push 	#496
	      	bsr  	set_vector_
	      	     	            ldi   r1,#61
            sc    r1,LEDS
        
	      	push 	#dbg_irq_
	      	push 	#495
	      	bsr  	set_vector_
	      	     	            ldi   r1,#62
            sc    r1,LEDS
        
	      	sw   	r0,ssm_[gp]
	      	ldi  	r3,#0
	      	sw   	r3,bmem_[gp]
	      	ldi  	r3,#0
	      	sw   	r3,cmem_[gp]
	      	ldi  	r3,#0
	      	sw   	r3,hmem_[gp]
	      	ldi  	r3,#0
	      	sw   	r3,wmem_[gp]
	      	     	            ldi   r1,#66
            sc    r1,LEDS
        
	      	ldi  	r3,#65536
	      	sw   	r3,curaddr_[gp]
	      	ldi  	r3,#16
	      	sw   	r3,muol_[gp]
	      	ldi  	r3,#98
	      	sw   	r3,cursz_[gp]
	      	ldi  	r3,#120
	      	andi 	r3,r3,#65535
	      	sc   	r3,curfmt_[gp]
	      	ldi  	r3,#1
	      	sw   	r3,currep_[gp]
	      	sw   	r0,dbg_dbctrl_[gp]
	      	     	            ldi   r1,#69
            sc    r1,LEDS
        
debugger_413:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_411:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_413
endpublic

	rodata
	align	16
	align	8
debugger_379:
	dc	13,10,68,66,71,62,0
debugger_231:
	dc	13,10,0
debugger_230:
	dc	37,48,49,54,88,32,0
debugger_229:
	dc	37,48,56,88,32,0
debugger_228:
	dc	37,48,52,88,32,0
debugger_227:
	dc	37,48,50,88,32,0
debugger_226:
	dc	13,10,37,48,54,88,32,0
debugger_225:
	dc	13,10,37,48,54,88,32,0
debugger_224:
	dc	13,10,37,48,54,88,32,0
debugger_223:
	dc	13,10,37,48,54,88,32,0
debugger_222:
	dc	13,10,0
debugger_221:
	dc	13,10,0
debugger_220:
	dc	100,115,50,61,37,48,56,88
	dc	13,10,0
debugger_219:
	dc	100,115,50,61,37,48,56,88
	dc	13,10,0
debugger_218:
	dc	100,115,49,61,37,48,56,88
	dc	13,10,0
debugger_217:
	dc	100,115,48,61,37,48,56,88
	dc	13,10,0
debugger_216:
	dc	100,50,61,37,48,56,88,13
	dc	10,0
debugger_215:
	dc	100,50,61,37,48,56,88,13
	dc	10,0
debugger_214:
	dc	100,49,61,37,48,56,88,13
	dc	10,0
debugger_213:
	dc	100,48,61,37,48,56,88,13
	dc	10,0
debugger_212:
	dc	13,10,0
debugger_211:
	dc	105,50,61,37,48,56,88,13
	dc	10,0
debugger_210:
	dc	105,50,61,37,48,56,88,13
	dc	10,0
debugger_209:
	dc	105,49,61,37,48,56,88,13
	dc	10,0
debugger_208:
	dc	105,48,61,37,48,56,88,13
	dc	10,0
debugger_157:
	dc	13,10,68,66,71,62,0
debugger_153:
	dc	114,37,100,61,37,88,13,10
	dc	0
debugger_148:
	dc	114,50,57,61,37,88,32,115
	dc	112,61,37,88,32,108,114,61
	dc	37,88,13,10,0
debugger_147:
	dc	114,50,53,61,37,88,32,114
	dc	50,54,61,37,88,32,114,50
	dc	55,61,37,88,32,114,50,56
	dc	61,37,88,13,10,0
debugger_146:
	dc	114,50,49,61,37,88,32,114
	dc	50,50,61,37,88,32,114,50
	dc	51,61,37,88,32,116,114,61
	dc	37,88,13,10,0
debugger_145:
	dc	114,49,55,61,37,88,32,114
	dc	49,56,61,37,88,32,114,49
	dc	57,61,37,88,32,114,50,48
	dc	61,37,88,13,10,0
debugger_144:
	dc	114,49,51,61,37,88,32,114
	dc	49,52,61,37,88,32,114,49
	dc	53,61,37,88,32,114,49,54
	dc	61,37,88,13,10,0
debugger_143:
	dc	114,57,61,37,88,32,114,49
	dc	48,61,37,88,32,114,49,49
	dc	61,37,88,32,114,49,50,61
	dc	37,88,13,10,0
debugger_142:
	dc	114,53,61,37,88,32,114,54
	dc	61,37,88,32,114,55,61,37
	dc	88,32,114,56,61,37,88,13
	dc	10,0
debugger_141:
	dc	13,10,114,49,61,37,88,32
	dc	114,50,61,37,88,32,114,51
	dc	61,37,88,32,114,52,61,37
	dc	88,13,10,0
debugger_124:
	dc	13,10,68,66,71,62,100,115
	dc	37,100,32,60,110,111,116,32
	dc	115,101,116,62,0
debugger_123:
	dc	13,10,68,66,71,62,100,115
	dc	37,100,61,37,48,56,88,13
	dc	10,0
debugger_107:
	dc	13,10,68,66,71,62,100,37
	dc	100,32,60,110,111,116,32,115
	dc	101,116,62,0
debugger_106:
	dc	13,10,68,66,71,62,100,37
	dc	100,61,37,48,56,88,13,10
	dc	0
debugger_92:
	dc	13,10,68,66,71,62,105,37
	dc	100,32,60,110,111,116,32,115
	dc	101,116,62,0
debugger_91:
	dc	13,10,68,66,71,62,105,37
	dc	100,61,37,48,56,88,13,10
	dc	0
debugger_15:
	dc	13,10,68,66,71,62,0
debugger_14:
	dc	13,10,84,121,112,101,32,39
	dc	113,39,32,116,111,32,113,117
	dc	105,116,46,0
debugger_13:
	dc	13,10,97,114,109,32,100,101
	dc	98,117,103,103,105,110,103,32
	dc	109,111,100,101,32,117,115,105
	dc	110,103,32,116,104,101,32,39
	dc	97,39,32,99,111,109,109,97
	dc	110,100,46,0
debugger_12:
	dc	13,10,79,110,99,101,32,116
	dc	104,101,32,100,101,98,117,103
	dc	32,114,101,103,105,115,116,101
	dc	114,115,32,97,114,101,32,115
	dc	101,116,32,105,116,32,105,115
	dc	32,110,101,99,101,115,115,97
	dc	114,121,32,116,111,32,0
debugger_11:
	dc	13,10,83,101,116,116,105,110
	dc	103,32,97,32,114,101,103,105
	dc	115,116,101,114,32,116,111,32
	dc	122,101,114,111,32,119,105,108
	dc	108,32,99,108,101,97,114,32
	dc	116,104,101,32,98,114,101,97
	dc	107,112,111,105,110,116,46,0
debugger_10:
	dc	13,10,105,110,100,105,99,97
	dc	116,101,32,97,32,100,97,116
	dc	97,32,115,116,111,114,101,32
	dc	111,110,108,121,32,98,114,101
	dc	97,107,112,111,105,110,116,46
	dc	0
debugger_9:
	dc	13,10,98,114,101,97,107,112
	dc	111,105,110,116,46,32,80,114
	dc	101,102,105,120,32,116,104,101
	dc	32,114,101,103,105,115,116,101
	dc	114,32,110,117,109,98,101,114
	dc	32,119,105,116,104,32,39,100
	dc	115,39,32,116,111,0
debugger_8:
	dc	13,10,105,110,115,116,114,117
	dc	99,116,105,111,110,32,98,114
	dc	101,97,107,112,111,105,110,116
	dc	32,111,114,32,97,32,39,100
	dc	39,32,116,111,32,105,110,100
	dc	105,99,97,116,101,32,97,32
	dc	100,97,116,97,0
debugger_7:
	dc	13,10,80,114,101,102,105,120
	dc	32,116,104,101,32,114,101,103
	dc	105,115,116,101,114,32,110,117
	dc	109,98,101,114,32,119,105,116
	dc	104,32,97,110,32,39,105,39
	dc	32,116,111,32,105,110,100,105
	dc	99,97,116,101,32,97,110,0
debugger_6:
	dc	13,10,84,104,101,114,101,32
	dc	97,114,101,32,97,32,116,111
	dc	116,97,108,32,111,102,32,102
	dc	111,117,114,32,98,114,101,97
	dc	107,112,111,105,110,116,32,114
	dc	101,103,105,115,116,101,114,115
	dc	32,40,48,45,51,41,46,0
debugger_5:
	dc	13,10,68,66,71,62,105,49
	dc	61,49,50,51,52,53,54,55
	dc	56,32,32,32,32,32,119,105
	dc	108,108,32,97,115,115,105,103
	dc	110,32,49,50,51,52,53,54
	dc	55,56,32,116,111,32,105,49
	dc	0
debugger_4:
	dc	13,10,97,110,32,97,100,100
	dc	114,101,115,115,32,116,111,32
	dc	105,116,46,0
debugger_3:
	dc	13,10,70,111,108,108,111,119
	dc	105,110,103,32,97,32,98,114
	dc	101,97,107,112,111,105,110,116
	dc	32,114,101,103,105,115,116,101
	dc	114,32,119,105,116,104,32,97
	dc	110,32,39,61,39,32,97,115
	dc	115,105,103,110,115,32,0
debugger_2:
	dc	13,10,68,66,71,62,105,50
	dc	63,0
debugger_1:
	dc	13,10,39,63,39,32,113,117
	dc	101,114,105,101,115,32,116,104
	dc	101,32,115,116,97,116,117,115
	dc	32,111,102,32,97,32,98,114
	dc	101,97,107,112,111,105,110,116
	dc	32,114,101,103,105,115,116,101
	dc	114,32,97,115,32,105,110,58
	dc	0
;	global	bmem_
;	global	dbg_stack_
;	global	cmem_
;	global	hmem_
;	global	dbg_processReg_
;	global	dbg_parse_line_
;	global	regs_
	extern	putstr_
;	global	cr0save_
;	global	wmem_
;	global	dbg_GetDBAD_
;	global	dbg_ReadSetDB_
	extern	disassem20_
;	global	muol_
;	global	dbg_ReadSetIB_
;	global	dbg_SetDBAD_
;	global	dbg_getDumpFormat_
;	global	dbg_arm_
;	global	dbg_irq_
	extern	getchar_
;	global	linebuf_
;	global	curaddr_
	extern	isdigit_
;	global	curfill_
;	global	linendx_
;	global	dbg_dbctrl_
;	global	dbg_parse_begin_
;	global	dbg_ReadSetDSB_
	extern	putch_
;	global	dbg_prompt_
	extern	getcharNoWait_
;	global	cursz_
;	global	dbg_nextSpace_
;	global	CvtScreenToAscii_
	extern	set_vector_
;	global	dbg_init_
;	global	dbg_getDecNumber_
;	global	debugger_
;	global	dbg_GetCursorCol_
;	global	ssm_
;	global	debugger_task_
	extern	disassem_
;	global	dbg_getHexNumber_
;	global	ignore_blanks_
;	global	dbg_GetCursorRow_
;	global	dbg_nextNonSpace_
;	global	dbg_getchar_
;	global	repcount_
;	global	dbg_ungetch_
;	global	curfmt_
;	global	currep_
	extern	printf_
;	global	dbg_HomeCursor_
