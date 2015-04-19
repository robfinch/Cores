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
	      	push 	#debugger_1
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_2
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_3
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_4
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_5
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_6
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_7
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_8
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_9
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_10
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_11
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_12
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_13
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_14
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	#debugger_15
	      	bsr  	printf_
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
public code dbg_GetCursorRow_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        ldi    r6,#3   ; Get cursor position
        sys    #410
        lsr    r1,r1,#8
    
debugger_19:
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
    
debugger_21:
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
     
debugger_23:
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
	      	beq  	r4,debugger_26
	      	cmp  	r4,r3,#1
	      	beq  	r4,debugger_27
	      	cmp  	r4,r3,#2
	      	beq  	r4,debugger_28
	      	cmp  	r4,r3,#3
	      	beq  	r4,debugger_29
	      	bra  	debugger_25
debugger_26:
	      	     	mfspr  r1,dbad0  
	      	bra  	debugger_25
debugger_27:
	      	     	mfspr  r1,dbad1  
	      	bra  	debugger_25
debugger_28:
	      	     	mfspr  r1,dbad2  
	      	bra  	debugger_25
debugger_29:
	      	     	mfspr  r1,dbad3  
	      	bra  	debugger_25
debugger_30:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
debugger_25:
	      	bra  	debugger_30
endpublic

public code dbg_SetDBAD_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,debugger_33
	      	cmp  	r4,r3,#1
	      	beq  	r4,debugger_34
	      	cmp  	r4,r3,#2
	      	beq  	r4,debugger_35
	      	cmp  	r4,r3,#3
	      	beq  	r4,debugger_36
	      	bra  	debugger_32
debugger_33:
	      	     	          lw    r1,32[bp]
          mtspr dbad0,r1
          
	      	bra  	debugger_32
debugger_34:
	      	     	          lw    r1,32[bp]
          mtspr dbad1,r1
          
	      	bra  	debugger_32
debugger_35:
	      	     	          lw    r1,32[bp]
          mtspr dbad2,r1
          
	      	bra  	debugger_32
debugger_36:
	      	     	          lw    r1,32[bp]
          mtspr dbad3,r1
          
	      	bra  	debugger_32
debugger_32:
debugger_37:
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
     
debugger_39:
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
     
debugger_41:
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
	      	ldi  	r11,#linendx_
	      	ldi  	r3,#-1
	      	sc   	r3,-2[bp]
	      	lw   	r3,[r11]
	      	cmp  	r4,r3,#84
	      	bge  	r4,debugger_43
	      	lw   	r4,[r11]
	      	asli 	r3,r4,#1
	      	lcu  	r4,linebuf_[r3]
	      	sc   	r4,-2[bp]
	      	inc  	[r11],#1
debugger_43:
	      	lcu  	r3,-2[bp]
	      	mov  	r1,r3
debugger_45:
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
debugger_47:
	      	lw   	r4,linendx_
	      	asli 	r3,r4,#1
	      	lcu  	r4,linebuf_[r3]
	      	sc   	r4,-2[bp]
	      	inc  	linendx_,#1
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#32
	      	beq  	r4,debugger_47
debugger_48:
debugger_49:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_ungetch_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,linendx_
	      	ble  	r3,debugger_51
	      	dec  	linendx_,#1
debugger_51:
debugger_53:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_nextNonSpace_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_54
	      	mov  	bp,sp
	      	subui	sp,sp,#8
debugger_55:
	      	lw   	r3,linendx_
	      	cmp  	r4,r3,#84
	      	bge  	r4,debugger_56
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#32
	      	bne  	r4,debugger_59
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#-1
	      	bne  	r4,debugger_57
debugger_59:
	      	lcu  	r3,-2[bp]
	      	mov  	r1,r3
debugger_60:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_57:
	      	bra  	debugger_55
debugger_56:
	      	ldi  	r1,#-1
	      	bra  	debugger_60
debugger_54:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_60
endpublic

public code dbg_nextSpace_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_61
	      	mov  	bp,sp
	      	subui	sp,sp,#8
debugger_62:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#-1
	      	bne  	r4,debugger_64
	      	bra  	debugger_63
debugger_64:
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#32
	      	bne  	r4,debugger_62
debugger_63:
	      	lcu  	r3,-2[bp]
	      	mov  	r1,r3
debugger_66:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_61:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_66
endpublic

	data
	align	8
	code
	align	16
public code dbg_getHexNumber_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_67
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	sw   	r0,-16[bp]
	      	sw   	r0,-24[bp]
	      	bsr  	dbg_nextNonSpace_
	      	dec  	linendx_,#1
debugger_68:
	      	ldi  	r3,#1
	      	beq  	r3,debugger_69
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmpu 	r4,r3,#48
	      	blt  	r4,debugger_70
	      	lcu  	r3,-2[bp]
	      	cmpu 	r4,r3,#57
	      	bgt  	r4,debugger_70
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#4
	      	lcu  	r6,-2[bp]
	      	subu 	r5,r6,#48
	      	or   	r3,r4,r5
	      	sw   	r3,-16[bp]
	      	bra  	debugger_71
debugger_70:
	      	lcu  	r3,-2[bp]
	      	cmpu 	r4,r3,#65
	      	blt  	r4,debugger_72
	      	lcu  	r3,-2[bp]
	      	cmpu 	r4,r3,#70
	      	bgt  	r4,debugger_72
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#4
	      	lcu  	r6,-2[bp]
	      	addu 	r5,r6,#-55
	      	or   	r3,r4,r5
	      	sw   	r3,-16[bp]
	      	bra  	debugger_73
debugger_72:
	      	lcu  	r3,-2[bp]
	      	cmpu 	r4,r3,#97
	      	blt  	r4,debugger_74
	      	lcu  	r3,-2[bp]
	      	cmpu 	r4,r3,#102
	      	bgt  	r4,debugger_74
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#4
	      	lcu  	r6,-2[bp]
	      	addu 	r5,r6,#-87
	      	or   	r3,r4,r5
	      	sw   	r3,-16[bp]
	      	bra  	debugger_75
debugger_74:
	      	lw   	r3,24[bp]
	      	lw   	r4,-16[bp]
	      	sw   	r4,[r3]
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
debugger_76:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
debugger_75:
debugger_73:
debugger_71:
	      	lw   	r4,-24[bp]
	      	addu 	r3,r4,#1
	      	sw   	r3,-24[bp]
	      	bra  	debugger_68
debugger_69:
	      	bra  	debugger_76
debugger_67:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_76
endpublic

	data
	align	8
	code
	align	16
public code dbg_ReadSetIB_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_79
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	ldi  	r11,#dbg_dbctrl_
	      	lw   	r3,24[bp]
	      	cmpu 	r4,r3,#3
	      	ble  	r4,debugger_80
debugger_82:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
debugger_80:
	      	bsr  	dbg_nextNonSpace_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#61
	      	bne  	r4,debugger_83
	      	pea  	-16[bp]
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	ble  	r3,debugger_85
	      	push 	-16[bp]
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD_
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r3,r4,r5
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r4,#196608
	      	lw   	r6,24[bp]
	      	asli 	r5,r6,#1
	      	asl  	r3,r4,r5
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_86
debugger_85:
	      	push 	#0
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD_
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r3,r4,r5
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r4,#196608
	      	lw   	r6,24[bp]
	      	asli 	r5,r6,#1
	      	asl  	r3,r4,r5
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
debugger_86:
	      	bra  	debugger_84
debugger_83:
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	bne  	r4,debugger_87
	      	lw   	r4,[r11]
	      	ldi  	r6,#196608
	      	lw   	r8,24[bp]
	      	asli 	r7,r8,#1
	      	asl  	r5,r6,r7
	      	and  	r3,r4,r5
	      	bne  	r3,debugger_89
	      	lw   	r4,[r11]
	      	ldi  	r6,#1
	      	lw   	r7,24[bp]
	      	asl  	r5,r6,r7
	      	ldi  	r7,#1
	      	lw   	r8,24[bp]
	      	asl  	r6,r7,r8
	      	seq  	r5,r5,r6
	      	and  	r3,r4,r5
	      	beq  	r3,debugger_89
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	push 	#debugger_77
	      	bsr  	printf_
	      	addui	sp,sp,#24
	      	bra  	debugger_90
debugger_89:
	      	push 	24[bp]
	      	push 	#debugger_78
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_90:
debugger_87:
debugger_84:
	      	bra  	debugger_82
debugger_79:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_82
endpublic

	data
	align	8
	code
	align	16
public code dbg_ReadSetDB_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_95
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	ldi  	r11,#dbg_dbctrl_
	      	lw   	r3,24[bp]
	      	cmpu 	r4,r3,#3
	      	ble  	r4,debugger_96
debugger_98:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
debugger_96:
	      	bsr  	dbg_nextNonSpace_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#61
	      	bne  	r4,debugger_99
	      	pea  	-16[bp]
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	ble  	r3,debugger_101
	      	push 	-16[bp]
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD_
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r3,r4,r5
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r4,#196608
	      	lw   	r6,24[bp]
	      	asli 	r5,r6,#1
	      	asl  	r3,r4,r5
	      	com  	r3,r3
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
	      	bra  	debugger_102
debugger_101:
	      	push 	#0
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD_
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r3,r4,r5
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r4,#196608
	      	lw   	r6,24[bp]
	      	asli 	r5,r6,#1
	      	asl  	r3,r4,r5
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
debugger_102:
	      	bra  	debugger_100
debugger_99:
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	bne  	r4,debugger_103
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
	      	bne  	r5,debugger_105
	      	lw   	r4,[r11]
	      	ldi  	r6,#1
	      	lw   	r7,24[bp]
	      	asl  	r5,r6,r7
	      	ldi  	r7,#1
	      	lw   	r8,24[bp]
	      	asl  	r6,r7,r8
	      	seq  	r5,r5,r6
	      	and  	r3,r4,r5
	      	beq  	r3,debugger_105
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	push 	#debugger_93
	      	bsr  	printf_
	      	addui	sp,sp,#24
	      	bra  	debugger_106
debugger_105:
	      	push 	24[bp]
	      	push 	#debugger_94
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_106:
debugger_103:
debugger_100:
	      	bra  	debugger_98
debugger_95:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_98
endpublic

	data
	align	8
	code
	align	16
public code dbg_ReadSetDSB_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_111
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	ldi  	r11,#dbg_dbctrl_
	      	lw   	r3,24[bp]
	      	cmpu 	r4,r3,#3
	      	ble  	r4,debugger_112
debugger_114:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
debugger_112:
	      	bsr  	dbg_nextNonSpace_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#61
	      	bne  	r4,debugger_115
	      	pea  	-16[bp]
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	ble  	r3,debugger_117
	      	push 	-16[bp]
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD_
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r3,r4,r5
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r4,#196608
	      	lw   	r6,24[bp]
	      	asli 	r5,r6,#1
	      	asl  	r3,r4,r5
	      	com  	r3,r3
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
	      	bra  	debugger_118
debugger_117:
	      	push 	#0
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD_
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r3,r4,r5
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r4,#196608
	      	lw   	r6,24[bp]
	      	asli 	r5,r6,#1
	      	asl  	r3,r4,r5
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
debugger_118:
	      	bra  	debugger_116
debugger_115:
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	bne  	r4,debugger_119
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
	      	bne  	r5,debugger_121
	      	lw   	r4,[r11]
	      	ldi  	r6,#1
	      	lw   	r7,24[bp]
	      	asl  	r5,r6,r7
	      	ldi  	r7,#1
	      	lw   	r8,24[bp]
	      	asl  	r6,r7,r8
	      	seq  	r5,r5,r6
	      	and  	r3,r4,r5
	      	beq  	r3,debugger_121
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	push 	#debugger_109
	      	bsr  	printf_
	      	addui	sp,sp,#24
	      	bra  	debugger_122
debugger_121:
	      	push 	24[bp]
	      	push 	#debugger_110
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_122:
debugger_119:
debugger_116:
	      	bra  	debugger_114
debugger_111:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_114
endpublic

DispRegs_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_134
	      	mov  	bp,sp
	      	push 	r11
	      	ldi  	r11,#regs_
	      	push 	32[r11]
	      	push 	24[r11]
	      	push 	16[r11]
	      	push 	8[r11]
	      	push 	#debugger_126
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	64[r11]
	      	push 	56[r11]
	      	push 	48[r11]
	      	push 	40[r11]
	      	push 	#debugger_127
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	96[r11]
	      	push 	88[r11]
	      	push 	80[r11]
	      	push 	72[r11]
	      	push 	#debugger_128
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	128[r11]
	      	push 	120[r11]
	      	push 	112[r11]
	      	push 	104[r11]
	      	push 	#debugger_129
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	160[r11]
	      	push 	152[r11]
	      	push 	144[r11]
	      	push 	136[r11]
	      	push 	#debugger_130
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	192[r11]
	      	push 	184[r11]
	      	push 	176[r11]
	      	push 	168[r11]
	      	push 	#debugger_131
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	224[r11]
	      	push 	216[r11]
	      	push 	208[r11]
	      	push 	200[r11]
	      	push 	#debugger_132
	      	bsr  	printf_
	      	addui	sp,sp,#40
	      	push 	248[r11]
	      	push 	240[r11]
	      	push 	232[r11]
	      	push 	#debugger_133
	      	bsr  	printf_
	      	addui	sp,sp,#32
debugger_135:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_134:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_135
DispReg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_138
	      	mov  	bp,sp
	      	lw   	r4,24[bp]
	      	asli 	r3,r4,#3
	      	push 	regs_[r3]
	      	push 	24[bp]
	      	push 	#debugger_137
	      	bsr  	printf_
	      	addui	sp,sp,#24
debugger_139:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
debugger_138:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_139
public code dbg_prompt_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_141
	      	mov  	bp,sp
	      	push 	#debugger_140
	      	bsr  	printf_
	      	addui	sp,sp,#8
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
endpublic

	data
	align	8
	code
	align	16
public code dbg_getDecNumber_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_143
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	lw   	r11,24[bp]
	      	bne  	r11,debugger_144
	      	ldi  	r1,#0
debugger_146:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#8
debugger_144:
	      	sw   	r0,-8[bp]
	      	sw   	r0,-24[bp]
debugger_147:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-10[bp]
	      	push 	r3
	      	bsr  	isdigit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,debugger_148
	      	ldi  	r4,#-48
	      	lw   	r6,-8[bp]
	      	mul  	r6,r6,#10
	      	lcu  	r7,-10[bp]
	      	addu 	r5,r6,r7
	      	addu 	r3,r4,r5
	      	sw   	r3,-8[bp]
	      	inc  	-24[bp],#1
	      	bra  	debugger_147
debugger_148:
	      	dec  	linendx_,#1
	      	lw   	r3,-8[bp]
	      	sw   	r3,[r11]
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
	      	bra  	debugger_146
debugger_143:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_146
endpublic

	data
	align	8
	code
	align	16
public code dbg_processReg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_149
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_151
	      	bra  	debugger_152
debugger_151:
	      	bsr  	DispRegs_
	      	bra  	debugger_150
debugger_152:
	      	lcu  	r3,-2[bp]
	      	push 	r3
	      	bsr  	isdigit_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,debugger_153
	      	dec  	linendx_,#1
	      	bsr  	dbg_getDecNumber_
	      	mov  	r3,r1
	      	sw   	r3,-16[bp]
	      	bsr  	dbg_nextNonSpace_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_156
	      	cmp  	r4,r3,#61
	      	beq  	r4,debugger_157
	      	bra  	debugger_158
debugger_156:
	      	push 	-16[bp]
	      	bsr  	DispReg_
debugger_159:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_157:
	      	pea  	-24[bp]
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-32[bp]
	      	lw   	r3,-32[bp]
	      	ble  	r3,debugger_160
	      	lw   	r4,-16[bp]
	      	asli 	r3,r4,#3
	      	lw   	r4,-24[bp]
	      	sw   	r4,regs_[r3]
debugger_160:
	      	bra  	debugger_159
debugger_158:
	      	bra  	debugger_159
debugger_155:
debugger_153:
	      	bra  	debugger_159
debugger_150:
	      	bra  	debugger_159
debugger_149:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_159
endpublic

public code dbg_parse_begin_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_162
	      	mov  	bp,sp
	      	push 	r11
	      	ldi  	r11,#linebuf_
	      	sw   	r0,linendx_
	      	lcu  	r3,[r11]
	      	cmp  	r4,r3,#68
	      	bne  	r4,debugger_163
	      	lcu  	r3,2[r11]
	      	cmp  	r4,r3,#66
	      	bne  	r4,debugger_163
	      	lcu  	r3,4[r11]
	      	cmp  	r4,r3,#71
	      	bne  	r4,debugger_163
	      	lcu  	r3,6[r11]
	      	cmp  	r4,r3,#62
	      	bne  	r4,debugger_163
	      	ldi  	r3,#4
	      	sw   	r3,linendx_
debugger_163:
	      	bsr  	dbg_parse_line_
	      	mov  	r3,r1
	      	mov  	r1,r3
debugger_165:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_162:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_165
endpublic

	data
	align	8
	code
	align	16
public code dbg_getDumpFormat_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_166
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	push 	r15
	      	lea  	r3,-32[bp]
	      	mov  	r11,r3
	      	ldi  	r12,#muol_
	      	ldi  	r13,#cursz_
	      	ldi  	r14,#curaddr_
	      	ldi  	r15,#curfmt_
	      	pea  	-24[bp]
	      	bsr  	dbg_getDecNumber_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	ble  	r3,debugger_167
	      	lw   	r3,-24[bp]
	      	sw   	r3,currep_
debugger_167:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-10[bp]
	      	lcu  	r3,-10[bp]
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_170
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_171
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_172
	      	bra  	debugger_169
debugger_170:
	      	ldi  	r3,#105
	      	sc   	r3,[r15]
	      	push 	r11
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	ble  	r3,debugger_173
	      	lw   	r3,[r11]
	      	sw   	r3,[r14]
debugger_173:
	      	bra  	debugger_169
debugger_171:
	      	ldi  	r3,#115
	      	sc   	r3,[r15]
	      	push 	r11
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	ble  	r3,debugger_175
	      	lw   	r3,[r11]
	      	sw   	r3,[r14]
debugger_175:
	      	bra  	debugger_169
debugger_172:
	      	ldi  	r3,#120
	      	sc   	r3,[r15]
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-10[bp]
	      	lcu  	r3,-10[bp]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_178
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_179
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_180
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_181
	      	bra  	debugger_182
debugger_178:
	      	ldi  	r3,#98
	      	sw   	r3,[r13]
	      	ldi  	r3,#16
	      	sw   	r3,[r12]
	      	bra  	debugger_177
debugger_179:
	      	ldi  	r3,#99
	      	sw   	r3,[r13]
	      	ldi  	r3,#8
	      	sw   	r3,[r12]
	      	bra  	debugger_177
debugger_180:
	      	ldi  	r3,#104
	      	sw   	r3,[r13]
	      	ldi  	r3,#4
	      	sw   	r3,[r12]
	      	bra  	debugger_177
debugger_181:
	      	ldi  	r3,#119
	      	sw   	r3,[r13]
	      	ldi  	r3,#2
	      	sw   	r3,[r12]
	      	bra  	debugger_177
debugger_182:
	      	dec  	linendx_,#1
debugger_177:
	      	push 	r11
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	ble  	r3,debugger_183
	      	lw   	r3,[r11]
	      	sw   	r3,[r14]
debugger_183:
	      	bra  	debugger_169
debugger_169:
debugger_185:
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
debugger_166:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_185
endpublic

	data
	align	8
	code
	align	16
public code dbg_parse_line_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_210
	      	mov  	bp,sp
	      	subui	sp,sp,#56
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	push 	r15
	      	push 	r16
	      	push 	r17
	      	ldi  	r11,#curaddr_
	      	ldi  	r12,#cmem_
	      	ldi  	r13,#currep_
	      	ldi  	r14,#cursz_
	      	ldi  	r15,#curfill_
	      	ldi  	r16,#curfmt_
	      	lea  	r3,-16[bp]
	      	mov  	r17,r3
debugger_211:
	      	lw   	r3,linendx_
	      	cmp  	r4,r3,#84
	      	bge  	r4,debugger_212
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#-1
	      	beq  	r4,debugger_214
	      	cmp  	r4,r3,#32
	      	beq  	r4,debugger_215
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_216
	      	cmp  	r4,r3,#113
	      	beq  	r4,debugger_217
	      	cmp  	r4,r3,#97
	      	beq  	r4,debugger_218
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_219
	      	cmp  	r4,r3,#100
	      	beq  	r4,debugger_220
	      	cmp  	r4,r3,#114
	      	beq  	r4,debugger_221
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_222
	      	cmp  	r4,r3,#102
	      	beq  	r4,debugger_223
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_224
	      	bra  	debugger_213
debugger_214:
debugger_225:
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
debugger_215:
	      	bra  	debugger_213
debugger_216:
	      	bsr  	dbg_DisplayHelp_
	      	bra  	debugger_213
debugger_217:
	      	ldi  	r1,#1
	      	bra  	debugger_225
debugger_218:
	      	lw   	r3,dbg_dbctrl_
	      	push 	r3
	      	bsr  	dbg_arm_
	      	bra  	debugger_213
debugger_219:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_227
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_228
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_229
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_230
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_231
	      	bra  	debugger_226
debugger_227:
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#196608
	      	bne  	r3,debugger_232
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#1
	      	cmp  	r4,r3,#1
	      	bne  	r4,debugger_232
	      	push 	#0
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_186
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_232:
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#3145728
	      	bne  	r3,debugger_234
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#2
	      	cmp  	r4,r3,#2
	      	bne  	r4,debugger_234
	      	push 	#1
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_187
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_234:
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#50331648
	      	bne  	r3,debugger_236
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#4
	      	cmp  	r4,r3,#4
	      	bne  	r4,debugger_236
	      	push 	#2
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_188
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_236:
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#805306368
	      	bne  	r3,debugger_238
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#8
	      	cmp  	r4,r3,#8
	      	bne  	r4,debugger_238
	      	push 	#3
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_189
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_238:
	      	bra  	debugger_226
debugger_228:
	      	push 	#0
	      	bsr  	dbg_ReadSetIB_
	      	bra  	debugger_226
debugger_229:
	      	push 	#1
	      	bsr  	dbg_ReadSetIB_
	      	bra  	debugger_226
debugger_230:
	      	push 	#2
	      	bsr  	dbg_ReadSetIB_
	      	bra  	debugger_226
debugger_231:
	      	push 	#3
	      	bsr  	dbg_ReadSetIB_
	      	bra  	debugger_226
debugger_226:
	      	bra  	debugger_213
debugger_220:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_241
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_242
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_243
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_244
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_245
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_246
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_247
	      	bra  	debugger_248
debugger_241:
	      	bsr  	dbg_nextSpace_
	      	push 	r17
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_249
	      	pea  	-24[bp]
	      	bsr  	dbg_getDecNumber_
	      	mov  	r3,r1
	      	sw   	r3,-56[bp]
	      	lw   	r3,-56[bp]
	      	ble  	r3,debugger_251
debugger_253:
	      	lw   	r3,-56[bp]
	      	ble  	r3,debugger_254
	      	push 	#0
	      	push 	r17
	      	bsr  	disassem_
	      	addui	sp,sp,#16
debugger_255:
	      	dec  	-56[bp],#1
	      	bra  	debugger_253
debugger_254:
	      	bra  	debugger_252
debugger_251:
	      	push 	#0
	      	push 	[r17]
	      	bsr  	disassem20_
	      	addui	sp,sp,#16
debugger_252:
debugger_249:
	      	bra  	debugger_240
debugger_242:
	      	push 	#debugger_190
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#196608
	      	cmp  	r4,r3,#196608
	      	bne  	r4,debugger_256
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#1
	      	cmp  	r4,r3,#1
	      	bne  	r4,debugger_256
	      	push 	#0
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_191
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_256:
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#3145728
	      	cmp  	r4,r3,#3145728
	      	bne  	r4,debugger_258
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#2
	      	cmp  	r4,r3,#2
	      	bne  	r4,debugger_258
	      	push 	#1
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_192
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_258:
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#50331648
	      	cmp  	r4,r3,#50331648
	      	bne  	r4,debugger_260
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#4
	      	cmp  	r4,r3,#4
	      	bne  	r4,debugger_260
	      	push 	#2
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_193
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_260:
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#805306368
	      	cmp  	r4,r3,#805306368
	      	bne  	r4,debugger_262
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#8
	      	cmp  	r4,r3,#8
	      	bne  	r4,debugger_262
	      	push 	#3
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_194
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_262:
	      	bra  	debugger_240
debugger_243:
	      	push 	#0
	      	bsr  	dbg_ReadSetDB_
	      	bra  	debugger_240
debugger_244:
	      	push 	#1
	      	bsr  	dbg_ReadSetDB_
	      	bra  	debugger_240
debugger_245:
	      	push 	#2
	      	bsr  	dbg_ReadSetDB_
	      	bra  	debugger_240
debugger_246:
	      	push 	#3
	      	bsr  	dbg_ReadSetDB_
	      	bra  	debugger_240
debugger_247:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
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
	      	bra  	debugger_264
debugger_265:
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#196608
	      	cmp  	r4,r3,#65536
	      	bne  	r4,debugger_270
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#1
	      	cmp  	r4,r3,#1
	      	bne  	r4,debugger_270
	      	push 	#0
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_195
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_270:
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#3145728
	      	cmp  	r4,r3,#1048576
	      	bne  	r4,debugger_272
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#2
	      	cmp  	r4,r3,#2
	      	bne  	r4,debugger_272
	      	push 	#1
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_196
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_272:
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#50331648
	      	cmp  	r4,r3,#16777216
	      	bne  	r4,debugger_274
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#4
	      	cmp  	r4,r3,#4
	      	bne  	r4,debugger_274
	      	push 	#2
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_197
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_274:
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#805306368
	      	cmp  	r4,r3,#268435456
	      	bne  	r4,debugger_276
	      	lw   	r4,dbg_dbctrl_
	      	and  	r3,r4,#8
	      	cmp  	r4,r3,#8
	      	bne  	r4,debugger_276
	      	push 	#3
	      	bsr  	dbg_GetDBAD_
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_198
	      	bsr  	printf_
	      	addui	sp,sp,#16
debugger_276:
	      	bra  	debugger_264
debugger_266:
	      	push 	#0
	      	bsr  	dbg_ReadSetDSB_
	      	bra  	debugger_264
debugger_267:
	      	push 	#1
	      	bsr  	dbg_ReadSetDSB_
	      	bra  	debugger_264
debugger_268:
	      	push 	#2
	      	bsr  	dbg_ReadSetDSB_
	      	bra  	debugger_264
debugger_269:
	      	push 	#3
	      	bsr  	dbg_ReadSetDSB_
	      	bra  	debugger_264
debugger_264:
	      	bra  	debugger_240
debugger_248:
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
	      	bra  	debugger_240
debugger_240:
	      	bra  	debugger_213
debugger_221:
	      	bsr  	dbg_processReg_
	      	bra  	debugger_213
debugger_222:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#115
	      	bne  	r4,debugger_278
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#45
	      	bne  	r4,debugger_280
	      	lw   	r3,dbg_dbctrl_
	      	andi 	r3,r3,#4611686018427387903
	      	sw   	r3,dbg_dbctrl_
	      	lw   	r3,dbg_dbctrl_
	      	push 	r3
	      	bsr  	dbg_arm_
	      	sw   	r0,ssm_
	      	bra  	debugger_281
debugger_280:
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#43
	      	beq  	r4,debugger_284
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#109
	      	bne  	r4,debugger_282
debugger_284:
	      	lw   	r3,dbg_dbctrl_
	      	ori  	r3,r3,#4611686018427387904
	      	sw   	r3,dbg_dbctrl_
	      	lw   	r3,dbg_dbctrl_
	      	push 	r3
	      	bsr  	dbg_arm_
	      	ldi  	r3,#1
	      	sw   	r3,ssm_
	      	ldi  	r1,#1
	      	bra  	debugger_225
debugger_282:
debugger_281:
debugger_278:
	      	bra  	debugger_213
debugger_223:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#47
	      	bne  	r4,debugger_285
	      	bsr  	dbg_getDumpFormat_
debugger_285:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#44
	      	bne  	r4,debugger_287
	      	lcu  	r3,[r16]
	      	cmp  	r4,r3,#120
	      	bne  	r4,debugger_289
	      	pea  	-40[bp]
	      	bsr  	dbg_getHexNumber_
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	bra  	debugger_290
debugger_289:
	      	pea  	-40[bp]
	      	bsr  	dbg_getDecNumber_
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
debugger_290:
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_291
	      	lw   	r3,-40[bp]
	      	sw   	r3,[r15]
debugger_291:
debugger_287:
	      	lcu  	r3,[r16]
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_294
	      	bra  	debugger_293
debugger_294:
	      	lw   	r3,[r14]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_296
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_297
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_298
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_299
	      	bra  	debugger_295
debugger_296:
	      	sw   	r0,-48[bp]
debugger_300:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_301
	      	lw   	r4,[r17]
	      	lw   	r5,-48[bp]
	      	addu 	r3,r4,r5
	      	lbu  	r4,[r15]
	      	sb   	r4,bmem_[r3]
debugger_302:
	      	inc  	-48[bp],#1
	      	bra  	debugger_300
debugger_301:
	      	bra  	debugger_295
debugger_297:
	      	sw   	r0,-48[bp]
debugger_303:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_304
	      	lw   	r6,[r17]
	      	asri 	r5,r6,#1
	      	lw   	r6,-48[bp]
	      	addu 	r4,r5,r6
	      	asli 	r3,r4,#1
	      	lcu  	r4,[r15]
	      	sc   	r4,[r3+r12]
debugger_305:
	      	inc  	-48[bp],#1
	      	bra  	debugger_303
debugger_304:
	      	bra  	debugger_295
debugger_298:
	      	sw   	r0,-48[bp]
debugger_306:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_307
	      	lw   	r6,[r17]
	      	asri 	r5,r6,#2
	      	lw   	r6,-48[bp]
	      	addu 	r4,r5,r6
	      	asli 	r3,r4,#2
	      	lhu  	r4,[r15]
	      	sh   	r4,hmem_[r3]
debugger_308:
	      	inc  	-48[bp],#1
	      	bra  	debugger_306
debugger_307:
	      	bra  	debugger_295
debugger_299:
	      	sw   	r0,-48[bp]
debugger_309:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_310
	      	lw   	r6,[r17]
	      	asri 	r5,r6,#3
	      	lw   	r6,-48[bp]
	      	addu 	r4,r5,r6
	      	asli 	r3,r4,#3
	      	lw   	r4,[r15]
	      	sw   	r4,wmem_[r3]
debugger_311:
	      	inc  	-48[bp],#1
	      	bra  	debugger_309
debugger_310:
	      	bra  	debugger_295
debugger_295:
debugger_293:
	      	bra  	debugger_213
debugger_224:
	      	bsr  	dbg_getchar_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#47
	      	bne  	r4,debugger_312
	      	bsr  	dbg_getDumpFormat_
debugger_312:
	      	lcu  	r3,[r16]
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_315
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_316
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_317
	      	bra  	debugger_314
debugger_315:
	      	push 	#debugger_199
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	sw   	r0,-48[bp]
debugger_318:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_319
	      	bsr  	getcharNoWait_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#3
	      	bne  	r4,debugger_321
	      	bra  	debugger_319
debugger_321:
	      	push 	#0
	      	push 	r11
	      	bsr  	disassem_
	      	addui	sp,sp,#16
debugger_320:
	      	inc  	-48[bp],#1
	      	bra  	debugger_318
debugger_319:
	      	bra  	debugger_314
debugger_316:
	      	sw   	r0,-48[bp]
debugger_323:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_324
	      	bsr  	getcharNoWait_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#3
	      	bne  	r4,debugger_326
	      	bra  	debugger_324
debugger_326:
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
	      	push 	#debugger_200
	      	bsr  	printf_
	      	addui	sp,sp,#8
debugger_325:
	      	inc  	-48[bp],#1
	      	bra  	debugger_323
debugger_324:
	      	bra  	debugger_314
debugger_317:
	      	sw   	r0,-48[bp]
debugger_328:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	cmp  	r5,r3,r4
	      	bge  	r5,debugger_329
	      	bsr  	getcharNoWait_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#3
	      	bne  	r4,debugger_331
	      	bra  	debugger_329
debugger_331:
	      	lw   	r3,-48[bp]
	      	lw   	r4,muol_
	      	modu 	r3,r3,r4
	      	bne  	r3,debugger_333
	      	lw   	r3,[r14]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_336
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_337
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_338
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_339
	      	bra  	debugger_335
debugger_336:
	      	lw   	r4,[r11]
	      	lw   	r5,-48[bp]
	      	addu 	r3,r4,r5
	      	push 	r3
	      	push 	#debugger_201
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_335
debugger_337:
	      	lw   	r4,[r11]
	      	lw   	r6,-48[bp]
	      	asli 	r5,r6,#1
	      	addu 	r3,r4,r5
	      	push 	r3
	      	push 	#debugger_202
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_335
debugger_338:
	      	lw   	r4,[r11]
	      	lw   	r6,-48[bp]
	      	asli 	r5,r6,#2
	      	addu 	r3,r4,r5
	      	push 	r3
	      	push 	#debugger_203
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_335
debugger_339:
	      	lw   	r4,[r11]
	      	lw   	r6,-48[bp]
	      	asli 	r5,r6,#3
	      	addu 	r3,r4,r5
	      	push 	r3
	      	push 	#debugger_204
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_335
debugger_335:
debugger_333:
	      	     	 right here ; 
	      	lw   	r3,[r14]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_341
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_342
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_343
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_344
	      	bra  	debugger_340
debugger_341:
	      	lw   	r4,[r11]
	      	lw   	r5,-48[bp]
	      	addu 	r3,r4,r5
	      	lbu  	r3,bmem_[r3]
	      	push 	r3
	      	push 	#debugger_205
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_340
debugger_342:
	      	lw   	r6,[r11]
	      	asri 	r5,r6,#1
	      	lw   	r6,-48[bp]
	      	addu 	r4,r5,r6
	      	asli 	r3,r4,#1
	      	lcu  	r3,[r3+r12]
	      	push 	r3
	      	push 	#debugger_206
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_340
debugger_343:
	      	lw   	r6,[r11]
	      	asri 	r5,r6,#2
	      	lw   	r6,-48[bp]
	      	addu 	r4,r5,r6
	      	asli 	r3,r4,#2
	      	lhu  	r3,hmem_[r3]
	      	push 	r3
	      	push 	#debugger_207
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_340
debugger_344:
	      	lw   	r6,[r11]
	      	asri 	r5,r6,#3
	      	lw   	r6,-48[bp]
	      	addu 	r4,r5,r6
	      	asli 	r3,r4,#3
	      	push 	wmem_[r3]
	      	push 	#debugger_208
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	debugger_340
debugger_340:
debugger_330:
	      	inc  	-48[bp],#1
	      	bra  	debugger_328
debugger_329:
	      	lw   	r3,[r14]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_346
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_347
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_348
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_349
	      	bra  	debugger_345
debugger_346:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r11]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_345
debugger_347:
	      	lw   	r4,-48[bp]
	      	asli 	r3,r4,#1
	      	lw   	r4,[r11]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_345
debugger_348:
	      	lw   	r4,-48[bp]
	      	asli 	r3,r4,#2
	      	lw   	r4,[r11]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_345
debugger_349:
	      	lw   	r4,-48[bp]
	      	asli 	r3,r4,#3
	      	lw   	r4,[r11]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_345
debugger_345:
	      	push 	#debugger_209
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	debugger_314
debugger_314:
debugger_213:
	      	bra  	debugger_211
debugger_212:
	      	ldi  	r1,#0
	      	bra  	debugger_225
debugger_210:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_225
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

	data
	align	8
	code
	align	16
public code debugger_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_353
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	ldi  	r11,#bmem_
	      	ldi  	r12,#ssm_
	      	ldi  	r13,#dbg_dbctrl_
	      	lw   	r3,32[bp]
	      	sw   	r3,[r13]
	      	ldi  	r14,#4291821568
	      	lw   	r4,24[bp]
	      	and  	r3,r4,#-4
	      	sw   	r3,24[bp]
	      	lw   	r3,24[bp]
	      	beq  	r3,debugger_354
	      	push 	24[bp]
	      	lw   	r4,24[bp]
	      	subu 	r3,r4,#16
	      	push 	r3
	      	bsr  	disassem20_
	      	addui	sp,sp,#16
debugger_354:
debugger_356:
	      	push 	#debugger_352
	      	bsr  	printf_
	      	addui	sp,sp,#8
debugger_358:
	      	bsr  	getchar_
	      	mov  	r3,r1
	      	sc   	r3,-2[bp]
	      	lw   	r3,[r12]
	      	beq  	r3,debugger_360
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#115
	      	bne  	r4,debugger_362
	      	lw   	r3,[r13]
	      	andi 	r3,r3,#4611686018426404862
	      	sw   	r3,[r13]
	      	lw   	r3,[r13]
	      	ori  	r3,r3,#4611686018427387904
	      	sw   	r3,[r13]
	      	push 	[r13]
	      	bsr  	dbg_arm_
debugger_364:
	      	pop  	r14
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_362:
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#45
	      	beq  	r4,debugger_367
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#3
	      	bne  	r4,debugger_365
debugger_367:
	      	sw   	r0,[r12]
	      	lw   	r3,[r13]
	      	andi 	r3,r3,#4611686018427387903
	      	sw   	r3,[r13]
	      	push 	[r13]
	      	bsr  	dbg_arm_
	      	bra  	debugger_364
debugger_365:
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#110
	      	bne  	r4,debugger_368
	      	ldi  	r3,#2
	      	sw   	r3,[r12]
	      	lw   	r3,[r13]
	      	andi 	r3,r3,#4611686018426404863
	      	sw   	r3,[r13]
	      	lw   	r3,[r13]
	      	ori  	r3,r3,#524289
	      	sw   	r3,[r13]
	      	lw   	r4,24[bp]
	      	lbu  	r4,[r4+r11]
	      	and  	r3,r4,#127
	      	cmp  	r4,r3,#124
	      	bne  	r4,debugger_370
	      	lw   	r5,24[bp]
	      	addu 	r4,r5,#4
	      	lbu  	r4,[r4+r11]
	      	and  	r3,r4,#127
	      	cmp  	r4,r3,#124
	      	bne  	r4,debugger_370
	      	inc  	24[bp],#12
	      	bra  	debugger_371
debugger_370:
	      	lw   	r4,24[bp]
	      	lbu  	r4,[r4+r11]
	      	and  	r3,r4,#127
	      	cmp  	r4,r3,#124
	      	bne  	r4,debugger_372
	      	inc  	24[bp],#8
	      	bra  	debugger_373
debugger_372:
	      	inc  	24[bp],#4
debugger_373:
debugger_371:
	      	push 	24[bp]
	      	push 	#0
	      	bsr  	dbg_SetDBAD_
	      	push 	[r13]
	      	bsr  	dbg_arm_
	      	bra  	debugger_364
debugger_368:
	      	bra  	debugger_361
debugger_360:
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#13
	      	bne  	r4,debugger_374
	      	bra  	debugger_359
debugger_374:
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#12
	      	bne  	r4,debugger_376
	      	     	                           bsr ClearScreen_
                       
	      	bsr  	dbg_HomeCursor_
	      	bra  	debugger_359
debugger_376:
	      	lcu  	r3,-2[bp]
	      	push 	r3
	      	bsr  	putch_
debugger_361:
	      	ldi  	r3,#1
	      	bne  	r3,debugger_358
debugger_359:
	      	bsr  	dbg_GetCursorRow_
	      	mov  	r3,r1
	      	sxb  	r3,r3
	      	sw   	r3,-16[bp]
	      	bsr  	dbg_GetCursorCol_
	      	mov  	r3,r1
	      	sxb  	r3,r3
	      	sw   	r3,-24[bp]
	      	sw   	r0,-40[bp]
debugger_378:
	      	lw   	r3,-40[bp]
	      	cmp  	r4,r3,#84
	      	bge  	r4,debugger_379
	      	lw   	r6,-16[bp]
	      	mul  	r6,r6,#84
	      	lw   	r7,-40[bp]
	      	addu 	r5,r6,r7
	      	asli 	r4,r5,#2
	      	lhu  	r4,0[r14+r4]
	      	and  	r3,r4,#1023
	      	push 	r3
	      	bsr  	CvtScreenToAscii_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	lw   	r5,-40[bp]
	      	asli 	r4,r5,#1
	      	sc   	r3,linebuf_[r4]
debugger_380:
	      	inc  	-40[bp],#1
	      	bra  	debugger_378
debugger_379:
	      	bsr  	dbg_parse_begin_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#1
	      	bne  	r4,debugger_381
	      	bra  	debugger_357
debugger_381:
	      	bra  	debugger_356
debugger_357:
	      	bra  	debugger_364
debugger_353:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_364
endpublic

public code dbg_init_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_383
	      	mov  	bp,sp
	      	push 	#dbg_irq_
	      	push 	#496
	      	bsr  	set_vector_
	      	addui	sp,sp,#16
	      	push 	#dbg_irq_
	      	push 	#495
	      	bsr  	set_vector_
	      	addui	sp,sp,#16
	      	sw   	r0,ssm_
	      	sw   	r0,bmem_
	      	sw   	r0,cmem_
	      	sw   	r0,hmem_
	      	sw   	r0,wmem_
	      	ldi  	r3,#65536
	      	sw   	r3,curaddr_
	      	ldi  	r3,#16
	      	sw   	r3,muol_
	      	ldi  	r3,#98
	      	sw   	r3,cursz_
	      	ldi  	r3,#120
	      	sc   	r3,curfmt_
	      	ldi  	r3,#1
	      	sw   	r3,currep_
	      	sw   	r0,dbg_dbctrl_
debugger_384:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_383:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_384
endpublic

	rodata
	align	16
	align	8
debugger_352:
	dc	13,10,68,66,71,62,0
debugger_209:
	dc	13,10,0
debugger_208:
	dc	37,48,49,54,88,32,0
debugger_207:
	dc	37,48,56,88,32,0
debugger_206:
	dc	37,48,52,88,32,0
debugger_205:
	dc	37,48,50,88,32,0
debugger_204:
	dc	13,10,37,48,54,88,32,0
debugger_203:
	dc	13,10,37,48,54,88,32,0
debugger_202:
	dc	13,10,37,48,54,88,32,0
debugger_201:
	dc	13,10,37,48,54,88,32,0
debugger_200:
	dc	13,10,0
debugger_199:
	dc	13,10,0
debugger_198:
	dc	100,115,50,61,37,48,56,88
	dc	13,10,0
debugger_197:
	dc	100,115,50,61,37,48,56,88
	dc	13,10,0
debugger_196:
	dc	100,115,49,61,37,48,56,88
	dc	13,10,0
debugger_195:
	dc	100,115,48,61,37,48,56,88
	dc	13,10,0
debugger_194:
	dc	100,50,61,37,48,56,88,13
	dc	10,0
debugger_193:
	dc	100,50,61,37,48,56,88,13
	dc	10,0
debugger_192:
	dc	100,49,61,37,48,56,88,13
	dc	10,0
debugger_191:
	dc	100,48,61,37,48,56,88,13
	dc	10,0
debugger_190:
	dc	13,10,0
debugger_189:
	dc	105,50,61,37,48,56,88,13
	dc	10,0
debugger_188:
	dc	105,50,61,37,48,56,88,13
	dc	10,0
debugger_187:
	dc	105,49,61,37,48,56,88,13
	dc	10,0
debugger_186:
	dc	105,48,61,37,48,56,88,13
	dc	10,0
debugger_140:
	dc	13,10,68,66,71,62,0
debugger_137:
	dc	114,37,100,61,37,88,13,10
	dc	0
debugger_133:
	dc	114,50,57,61,37,88,32,115
	dc	112,61,37,88,32,108,114,61
	dc	37,88,13,10,0
debugger_132:
	dc	114,50,53,61,37,88,32,114
	dc	50,54,61,37,88,32,114,50
	dc	55,61,37,88,32,114,50,56
	dc	61,37,88,13,10,0
debugger_131:
	dc	114,50,49,61,37,88,32,114
	dc	50,50,61,37,88,32,114,50
	dc	51,61,37,88,32,116,114,61
	dc	37,88,13,10,0
debugger_130:
	dc	114,49,55,61,37,88,32,114
	dc	49,56,61,37,88,32,114,49
	dc	57,61,37,88,32,114,50,48
	dc	61,37,88,13,10,0
debugger_129:
	dc	114,49,51,61,37,88,32,114
	dc	49,52,61,37,88,32,114,49
	dc	53,61,37,88,32,114,49,54
	dc	61,37,88,13,10,0
debugger_128:
	dc	114,57,61,37,88,32,114,49
	dc	48,61,37,88,32,114,49,49
	dc	61,37,88,32,114,49,50,61
	dc	37,88,13,10,0
debugger_127:
	dc	114,53,61,37,88,32,114,54
	dc	61,37,88,32,114,55,61,37
	dc	88,32,114,56,61,37,88,13
	dc	10,0
debugger_126:
	dc	13,10,114,49,61,37,88,32
	dc	114,50,61,37,88,32,114,51
	dc	61,37,88,32,114,52,61,37
	dc	88,13,10,0
debugger_110:
	dc	13,10,68,66,71,62,100,115
	dc	37,100,32,60,110,111,116,32
	dc	115,101,116,62,0
debugger_109:
	dc	13,10,68,66,71,62,100,115
	dc	37,100,61,37,48,56,88,13
	dc	10,0
debugger_94:
	dc	13,10,68,66,71,62,100,37
	dc	100,32,60,110,111,116,32,115
	dc	101,116,62,0
debugger_93:
	dc	13,10,68,66,71,62,100,37
	dc	100,61,37,48,56,88,13,10
	dc	0
debugger_78:
	dc	13,10,68,66,71,62,105,37
	dc	100,32,60,110,111,116,32,115
	dc	101,116,62,0
debugger_77:
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
