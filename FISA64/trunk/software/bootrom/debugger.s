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
public bss dbctrl:
	fill.b	8,0x00

endpublic
	code
	align	16
public code dbg_DisplayHelp:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_15
	      	mov  	bp,sp
	      	push 	#debugger_0
	      	bsr  	printf
	      	addui	sp,sp,#8
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
debugger_16:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_15:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_16
endpublic

public code GetVBR:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        mfspr r1,vbr
    
debugger_18:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code set_vector:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_19
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#511
	      	ble  	r3,debugger_20
debugger_22:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_20:
	      	lw   	r3,32[bp]
	      	beq  	r3,debugger_25
	      	lw   	r3,32[bp]
	      	and  	r3,r3,#3
	      	beq  	r3,debugger_23
debugger_25:
	      	bra  	debugger_22
debugger_23:
	      	lw   	r3,24[bp]
	      	asli 	r3,r3,#3
	      	push 	r3
	      	bsr  	GetVBR
	      	pop  	r3
	      	mov  	r4,r1
	      	lw   	r5,32[bp]
	      	sw   	r5,0[r4+r3]
	      	bra  	debugger_22
debugger_19:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_22
endpublic

public code dbg_GetCursorRow:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lbu    r1,TCB_hJCB[tr]
        mulu   r1,#JCB_Size
        addui  r1,r1,#JCB_Array
        lbu    r1,JCB_CursorRow[r1]
    
debugger_27:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_GetCursorCol:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lbu    r1,TCB_hJCB[tr]
        mulu   r1,#JCB_Size
        addui  r1,r1,#JCB_Array
        lbu    r1,JCB_CursorCol[r1]
    
debugger_29:
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
	      	beq  	r4,debugger_32
	      	cmp  	r4,r3,#1
	      	beq  	r4,debugger_33
	      	cmp  	r4,r3,#2
	      	beq  	r4,debugger_34
	      	cmp  	r4,r3,#3
	      	beq  	r4,debugger_35
	      	bra  	debugger_31
debugger_32:
	      	     	mfspr  r1,dbad0  
	      	bra  	debugger_31
debugger_33:
	      	     	mfspr  r1,dbad1  
	      	bra  	debugger_31
debugger_34:
	      	     	mfspr  r1,dbad2  
	      	bra  	debugger_31
debugger_35:
	      	     	mfspr  r1,dbad3  
	      	bra  	debugger_31
debugger_36:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
debugger_31:
	      	bra  	debugger_36
endpublic

public code dbg_SetDBAD:
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
	      	rtl  	#16
endpublic

public code dbg_arm:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw    r1,24[bp]
         mtspr dbctrl,r1
     
debugger_45:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code CvtScreenToAscii:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw    r1,24[bp]
         bsr   ScreenToAscii
     
debugger_47:
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
	      	bge  	r3,debugger_49
	      	lw   	r3,[r11]
	      	asli 	r3,r3,#1
	      	lcu  	r4,linebuf[r3]
	      	sc   	r4,-2[bp]
	      	inc  	[r11],#1
debugger_49:
	      	lcu  	r3,-2[bp]
	      	mov  	r1,r3
debugger_51:
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
debugger_53:
	      	lw   	r3,linendx
	      	asli 	r3,r3,#1
	      	lcu  	r4,linebuf[r3]
	      	sc   	r4,-2[bp]
	      	inc  	linendx,#1
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#32
	      	beq  	r3,debugger_53
debugger_54:
debugger_55:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_ungetch:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,linendx
	      	ble  	r3,debugger_57
	      	dec  	linendx,#1
debugger_57:
debugger_59:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_nextNonSpace:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_60
	      	mov  	bp,sp
	      	subui	sp,sp,#8
debugger_61:
	      	lw   	r3,linendx
	      	cmp  	r3,r3,#84
	      	bge  	r3,debugger_62
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#32
	      	bne  	r3,debugger_65
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#-1
	      	bne  	r3,debugger_63
debugger_65:
	      	lcu  	r3,-2[bp]
	      	mov  	r1,r3
debugger_66:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_63:
	      	bra  	debugger_61
debugger_62:
	      	ldi  	r1,#-1
	      	bra  	debugger_66
debugger_60:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_66
endpublic

public code dbg_GetHexNumber:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_67
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	sw   	r0,-16[bp]
	      	sw   	r0,-24[bp]
debugger_68:
	      	ldi  	r3,#1
	      	beq  	r3,debugger_69
	      	lw   	r3,-16[bp]
	      	asl  	r3,r3,#4
	      	sw   	r3,-16[bp]
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#48
	      	blt  	r3,debugger_70
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#57
	      	bgt  	r3,debugger_70
	      	lw   	r3,-16[bp]
	      	lcu  	r4,-2[bp]
	      	subu 	r4,r4,#48
	      	or   	r3,r3,r4
	      	sw   	r3,-16[bp]
	      	bra  	debugger_71
debugger_70:
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#65
	      	blt  	r3,debugger_72
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#70
	      	bgt  	r3,debugger_72
	      	lw   	r3,-16[bp]
	      	lcu  	r4,-2[bp]
	      	addu 	r4,r4,#-55
	      	or   	r3,r3,r4
	      	sw   	r3,-16[bp]
	      	bra  	debugger_73
debugger_72:
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#97
	      	blt  	r3,debugger_74
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#102
	      	bgt  	r3,debugger_74
	      	lw   	r3,-16[bp]
	      	lcu  	r4,-2[bp]
	      	addu 	r4,r4,#-92
	      	or   	r3,r3,r4
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
	      	rtl  	#0
debugger_75:
debugger_73:
debugger_71:
	      	bra  	debugger_68
debugger_69:
	      	bra  	debugger_76
debugger_67:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_76
endpublic

public code dbg_ReadSetIB:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_79
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	ldi  	r11,#dbctrl
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#3
	      	ble  	r3,debugger_80
debugger_82:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_80:
	      	bsr  	dbg_nextNonSpace
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#61
	      	bne  	r3,debugger_83
	      	pea  	-16[bp]
	      	bsr  	dbg_GetHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	ble  	r3,debugger_85
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
debugger_85:
	      	bra  	debugger_84
debugger_83:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#63
	      	bne  	r3,debugger_87
	      	lw   	r3,[r11]
	      	ldi  	r4,#196608
	      	lw   	r5,24[bp]
	      	asli 	r5,r5,#1
	      	asl  	r4,r4,r5
	      	and  	r3,r3,r4
	      	bne  	r3,debugger_89
	      	lw   	r3,[r11]
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r4,r4,r5
	      	ldi  	r5,#1
	      	lw   	r6,24[bp]
	      	asl  	r5,r5,r6
	      	seq  	r4,r4,r5
	      	and  	r3,r3,r4
	      	beq  	r3,debugger_89
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	push 	#debugger_77
	      	bsr  	printf
	      	addui	sp,sp,#24
	      	bra  	debugger_90
debugger_89:
	      	push 	24[bp]
	      	push 	#debugger_78
	      	bsr  	printf
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

public code dbg_ReadSetDB:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_95
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	ldi  	r11,#dbctrl
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#3
	      	ble  	r3,debugger_96
debugger_98:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_96:
	      	bsr  	dbg_nextNonSpace
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#61
	      	bne  	r3,debugger_99
	      	pea  	-16[bp]
	      	bsr  	dbg_GetHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	ble  	r3,debugger_101
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
debugger_101:
	      	bra  	debugger_100
debugger_99:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#63
	      	bne  	r3,debugger_103
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
	      	bne  	r3,debugger_105
	      	lw   	r3,[r11]
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r4,r4,r5
	      	ldi  	r5,#1
	      	lw   	r6,24[bp]
	      	asl  	r5,r5,r6
	      	seq  	r4,r4,r5
	      	and  	r3,r3,r4
	      	beq  	r3,debugger_105
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	push 	#debugger_93
	      	bsr  	printf
	      	addui	sp,sp,#24
	      	bra  	debugger_106
debugger_105:
	      	push 	24[bp]
	      	push 	#debugger_94
	      	bsr  	printf
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

public code dbg_ReadSetDSB:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_111
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	ldi  	r11,#dbctrl
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#3
	      	ble  	r3,debugger_112
debugger_114:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_112:
	      	bsr  	dbg_nextNonSpace
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#61
	      	bne  	r3,debugger_115
	      	pea  	-16[bp]
	      	bsr  	dbg_GetHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	ble  	r3,debugger_117
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
debugger_117:
	      	bra  	debugger_116
debugger_115:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#63
	      	bne  	r3,debugger_119
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
	      	bne  	r3,debugger_121
	      	lw   	r3,[r11]
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r4,r4,r5
	      	ldi  	r5,#1
	      	lw   	r6,24[bp]
	      	asl  	r5,r5,r6
	      	seq  	r4,r4,r5
	      	and  	r3,r3,r4
	      	beq  	r3,debugger_121
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	push 	#debugger_109
	      	bsr  	printf
	      	addui	sp,sp,#24
	      	bra  	debugger_122
debugger_121:
	      	push 	24[bp]
	      	push 	#debugger_110
	      	bsr  	printf
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

public code dbg_prompt:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_126
	      	mov  	bp,sp
	      	push 	#debugger_125
	      	bsr  	printf
	      	addui	sp,sp,#8
debugger_127:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_126:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_127
endpublic

public code dbg_parse_line:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_144
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	ldi  	r11,#dbctrl
	      	ldi  	r12,#linebuf
	      	ldi  	r13,#linendx
	      	sw   	r0,[r13]
	      	lcu  	r3,[r12]
	      	cmp  	r3,r3,#68
	      	bne  	r3,debugger_145
	      	lcu  	r3,2[r12]
	      	cmp  	r3,r3,#66
	      	bne  	r3,debugger_145
	      	lcu  	r3,4[r12]
	      	cmp  	r3,r3,#71
	      	bne  	r3,debugger_145
	      	lcu  	r3,6[r12]
	      	cmp  	r3,r3,#62
	      	bne  	r3,debugger_145
	      	ldi  	r3,#4
	      	sw   	r3,[r13]
debugger_145:
	      	lw   	r3,[r13]
	      	asli 	r3,r3,#1
	      	lcu  	r4,0[r12+r3]
	      	sc   	r4,-2[bp]
	      	inc  	[r13],#1
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_148
	      	cmp  	r4,r3,#113
	      	beq  	r4,debugger_149
	      	cmp  	r4,r3,#97
	      	beq  	r4,debugger_150
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_151
	      	cmp  	r4,r3,#100
	      	beq  	r4,debugger_152
	      	bra  	debugger_147
debugger_148:
	      	bsr  	dbg_DisplayHelp
	      	bra  	debugger_147
debugger_149:
	      	ldi  	r1,#1
debugger_153:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_150:
	      	push 	[r11]
	      	bsr  	dbg_arm
	      	addui	sp,sp,#8
	      	bra  	debugger_147
debugger_151:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_155
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_156
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_157
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_158
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_159
	      	bra  	debugger_154
debugger_155:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#196608
	      	bne  	r3,debugger_160
	      	lw   	r3,[r11]
	      	and  	r3,r3,#1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_160
	      	push 	#0
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_128
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_160:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#3145728
	      	bne  	r3,debugger_162
	      	lw   	r3,[r11]
	      	and  	r3,r3,#2
	      	cmp  	r3,r3,#2
	      	bne  	r3,debugger_162
	      	push 	#1
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_129
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_162:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#50331648
	      	bne  	r3,debugger_164
	      	lw   	r3,[r11]
	      	and  	r3,r3,#4
	      	cmp  	r3,r3,#4
	      	bne  	r3,debugger_164
	      	push 	#2
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_130
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_164:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#805306368
	      	bne  	r3,debugger_166
	      	lw   	r3,[r11]
	      	and  	r3,r3,#8
	      	cmp  	r3,r3,#8
	      	bne  	r3,debugger_166
	      	push 	#3
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_131
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_166:
	      	bra  	debugger_154
debugger_156:
	      	push 	#0
	      	bsr  	dbg_ReadSetIB
	      	addui	sp,sp,#8
	      	bra  	debugger_154
debugger_157:
	      	push 	#1
	      	bsr  	dbg_ReadSetIB
	      	addui	sp,sp,#8
	      	bra  	debugger_154
debugger_158:
	      	push 	#2
	      	bsr  	dbg_ReadSetIB
	      	addui	sp,sp,#8
	      	bra  	debugger_154
debugger_159:
	      	push 	#3
	      	bsr  	dbg_ReadSetIB
	      	addui	sp,sp,#8
	      	bra  	debugger_154
debugger_154:
	      	bra  	debugger_147
debugger_152:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_169
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_170
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_171
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_172
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_173
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_174
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_175
	      	bra  	debugger_168
debugger_169:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#196608
	      	cmp  	r3,r3,#196608
	      	bne  	r3,debugger_176
	      	lw   	r3,[r11]
	      	and  	r3,r3,#1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_176
	      	push 	#0
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_132
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_176:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#3145728
	      	cmp  	r3,r3,#3145728
	      	bne  	r3,debugger_178
	      	lw   	r3,[r11]
	      	and  	r3,r3,#2
	      	cmp  	r3,r3,#2
	      	bne  	r3,debugger_178
	      	push 	#1
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_133
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_178:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#50331648
	      	cmp  	r3,r3,#50331648
	      	bne  	r3,debugger_180
	      	lw   	r3,[r11]
	      	and  	r3,r3,#4
	      	cmp  	r3,r3,#4
	      	bne  	r3,debugger_180
	      	push 	#2
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_134
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_180:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#805306368
	      	cmp  	r3,r3,#805306368
	      	bne  	r3,debugger_182
	      	lw   	r3,[r11]
	      	and  	r3,r3,#8
	      	cmp  	r3,r3,#8
	      	bne  	r3,debugger_182
	      	push 	#3
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_135
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_182:
	      	bra  	debugger_168
debugger_170:
	      	push 	#0
	      	bsr  	dbg_ReadSetDB
	      	addui	sp,sp,#8
	      	bra  	debugger_168
debugger_171:
	      	push 	#1
	      	bsr  	dbg_ReadSetDB
	      	addui	sp,sp,#8
	      	bra  	debugger_168
debugger_172:
	      	push 	#2
	      	bsr  	dbg_ReadSetDB
	      	addui	sp,sp,#8
	      	bra  	debugger_168
debugger_173:
	      	push 	#3
	      	bsr  	dbg_ReadSetDB
	      	addui	sp,sp,#8
	      	bra  	debugger_168
debugger_174:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#196608
	      	cmp  	r3,r3,#196608
	      	bne  	r3,debugger_184
	      	lw   	r3,[r11]
	      	and  	r3,r3,#1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_184
	      	push 	#0
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_136
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_184:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#3145728
	      	cmp  	r3,r3,#3145728
	      	bne  	r3,debugger_186
	      	lw   	r3,[r11]
	      	and  	r3,r3,#2
	      	cmp  	r3,r3,#2
	      	bne  	r3,debugger_186
	      	push 	#1
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_137
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_186:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#50331648
	      	cmp  	r3,r3,#50331648
	      	bne  	r3,debugger_188
	      	lw   	r3,[r11]
	      	and  	r3,r3,#4
	      	cmp  	r3,r3,#4
	      	bne  	r3,debugger_188
	      	push 	#2
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_138
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_188:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#805306368
	      	cmp  	r3,r3,#805306368
	      	bne  	r3,debugger_190
	      	lw   	r3,[r11]
	      	and  	r3,r3,#8
	      	cmp  	r3,r3,#8
	      	bne  	r3,debugger_190
	      	push 	#3
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_139
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_190:
	      	bra  	debugger_168
debugger_175:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_193
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_194
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_195
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_196
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_197
	      	bra  	debugger_192
debugger_193:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#196608
	      	cmp  	r3,r3,#65536
	      	bne  	r3,debugger_198
	      	lw   	r3,[r11]
	      	and  	r3,r3,#1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_198
	      	push 	#0
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_140
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_198:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#3145728
	      	cmp  	r3,r3,#1048576
	      	bne  	r3,debugger_200
	      	lw   	r3,[r11]
	      	and  	r3,r3,#2
	      	cmp  	r3,r3,#2
	      	bne  	r3,debugger_200
	      	push 	#1
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_141
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_200:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#50331648
	      	cmp  	r3,r3,#16777216
	      	bne  	r3,debugger_202
	      	lw   	r3,[r11]
	      	and  	r3,r3,#4
	      	cmp  	r3,r3,#4
	      	bne  	r3,debugger_202
	      	push 	#2
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_142
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_202:
	      	lw   	r3,[r11]
	      	and  	r3,r3,#805306368
	      	cmp  	r3,r3,#268435456
	      	bne  	r3,debugger_204
	      	lw   	r3,[r11]
	      	and  	r3,r3,#8
	      	cmp  	r3,r3,#8
	      	bne  	r3,debugger_204
	      	push 	#3
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_143
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_204:
	      	bra  	debugger_192
debugger_194:
	      	push 	#0
	      	bsr  	dbg_ReadSetDSB
	      	addui	sp,sp,#8
	      	bra  	debugger_192
debugger_195:
	      	push 	#1
	      	bsr  	dbg_ReadSetDSB
	      	addui	sp,sp,#8
	      	bra  	debugger_192
debugger_196:
	      	push 	#2
	      	bsr  	dbg_ReadSetDSB
	      	addui	sp,sp,#8
	      	bra  	debugger_192
debugger_197:
	      	push 	#3
	      	bsr  	dbg_ReadSetDSB
	      	addui	sp,sp,#8
	      	bra  	debugger_192
debugger_192:
debugger_168:
	      	bra  	debugger_147
debugger_147:
	      	bra  	debugger_153
debugger_144:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_153
endpublic

public code dbg_irq:
	      	     	         lea   sp,dbg_stack+4088
         push  r0
         push  r1
         push  r2
         push  r3
         push  r4
         push  r5
         push  r6
         push  r7
         push  r8
         push  r9
         push  r10
         push  r11
         push  r12
         push  r13
         push  r14
         push  r15
         push  r16
         push  r17
         push  r18
         push  r19
         push  r20
         push  r21
         push  r22
         push  r23
         push  r25
         push  r26
         push  r27
         push  r28
         push  r29
         push  r31

         mfspr r1,dbctrl
         push  r1
         mtspr dbctrl,r0
         mfspr r1,dpc
         push  r1
         bsr   debugger
         addui sp,sp,#16
         
         pop   r31
         pop   r29
         pop   r28
         pop   r27
         pop   r26
         pop   r25
         pop   r23
         pop   r22
         pop   r21
         pop   r20
         pop   r19
         pop   r18
         pop   r17
         pop   r16
         pop   r15
         pop   r14
         pop   r13
         pop   r12
         pop   r11
         pop   r10
         pop   r9
         pop   r8
         pop   r7
         pop   r6
         pop   r5
         pop   r4
         pop   r3
         pop   r2
         pop   r1
         pop   r0
         rti
     
endpublic

public code debugger:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_209
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	ldi  	r11,#-3145728
	      	lw   	r3,24[bp]
	      	beq  	r3,debugger_210
	      	push 	24[bp]
	      	push 	24[bp]
	      	bsr  	disassem20
	      	addui	sp,sp,#16
debugger_210:
debugger_212:
	      	ldi  	r3,#1
	      	beq  	r3,debugger_213
	      	push 	#debugger_208
	      	bsr  	printf
	      	addui	sp,sp,#8
debugger_214:
	      	bsr  	getchar
	      	mov  	r3,r1
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#13
	      	bne  	r3,debugger_216
	      	bra  	debugger_215
debugger_216:
	      	lcu  	r3,-2[bp]
	      	push 	r3
	      	bsr  	putch
	      	addui	sp,sp,#8
	      	ldi  	r3,#1
	      	bne  	r3,debugger_214
debugger_215:
	      	bsr  	dbg_GetCursorRow
	      	mov  	r3,r1
	      	sxb  	r3,r3
	      	sw   	r3,-16[bp]
	      	bsr  	dbg_GetCursorCol
	      	mov  	r3,r1
	      	sxb  	r3,r3
	      	sw   	r3,-24[bp]
	      	sw   	r0,-40[bp]
debugger_218:
	      	lw   	r3,-40[bp]
	      	cmp  	r3,r3,#84
	      	bge  	r3,debugger_219
	      	lw   	r3,-16[bp]
	      	mul  	r3,r3,#84
	      	lw   	r4,-40[bp]
	      	addu 	r3,r3,r4
	      	asli 	r3,r3,#2
	      	lhu  	r3,0[r11+r3]
	      	and  	r3,r3,#1023
	      	push 	r3
	      	bsr  	CvtScreenToAscii
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	lw   	r4,-40[bp]
	      	asli 	r4,r4,#1
	      	sc   	r3,linebuf[r4]
debugger_220:
	      	inc  	-40[bp],#1
	      	bra  	debugger_218
debugger_219:
	      	bsr  	dbg_parse_line
	      	mov  	r3,r1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_221
	      	bra  	debugger_213
debugger_221:
	      	bra  	debugger_212
debugger_213:
debugger_223:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_209:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_223
endpublic

public code dbg_init:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_224
	      	mov  	bp,sp
	      	push 	#dbg_irq
	      	push 	#496
	      	bsr  	set_vector
	      	addui	sp,sp,#16
debugger_225:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_224:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_225
endpublic

	rodata
	align	16
	align	8
debugger_208:	; DBG>
	dc	13,10,68,66,71,62,0
debugger_143:	; ds2=%08X
	dc	100,115,50,61,37,48,56,88
	dc	13,10,0
debugger_142:	; ds2=%08X
	dc	100,115,50,61,37,48,56,88
	dc	13,10,0
debugger_141:	; ds1=%08X
	dc	100,115,49,61,37,48,56,88
	dc	13,10,0
debugger_140:	; ds0=%08X
	dc	100,115,48,61,37,48,56,88
	dc	13,10,0
debugger_139:	; db2=%08X
	dc	100,98,50,61,37,48,56,88
	dc	13,10,0
debugger_138:	; db2=%08X
	dc	100,98,50,61,37,48,56,88
	dc	13,10,0
debugger_137:	; db1=%08X
	dc	100,98,49,61,37,48,56,88
	dc	13,10,0
debugger_136:	; db0=%08X
	dc	100,98,48,61,37,48,56,88
	dc	13,10,0
debugger_135:	; d2=%08X
	dc	100,50,61,37,48,56,88,13
	dc	10,0
debugger_134:	; d2=%08X
	dc	100,50,61,37,48,56,88,13
	dc	10,0
debugger_133:	; d1=%08X
	dc	100,49,61,37,48,56,88,13
	dc	10,0
debugger_132:	; d0=%08X
	dc	100,48,61,37,48,56,88,13
	dc	10,0
debugger_131:	; i2=%08X
	dc	105,50,61,37,48,56,88,13
	dc	10,0
debugger_130:	; i2=%08X
	dc	105,50,61,37,48,56,88,13
	dc	10,0
debugger_129:	; i1=%08X
	dc	105,49,61,37,48,56,88,13
	dc	10,0
debugger_128:	; i0=%08X
	dc	105,48,61,37,48,56,88,13
	dc	10,0
debugger_125:	; DBG>
	dc	13,10,68,66,71,62,0
debugger_110:	; DBG>dsb%d <not set>
	dc	13,10,68,66,71,62,100,115
	dc	98,37,100,32,60,110,111,116
	dc	32,115,101,116,62,0
debugger_109:	; DBG>dsb%d=%08X
	dc	13,10,68,66,71,62,100,115
	dc	98,37,100,61,37,48,56,88
	dc	13,10,0
debugger_94:	; DBG>db%d <not set>
	dc	13,10,68,66,71,62,100,98
	dc	37,100,32,60,110,111,116,32
	dc	115,101,116,62,0
debugger_93:	; DBG>db%d=%08X
	dc	13,10,68,66,71,62,100,98
	dc	37,100,61,37,48,56,88,13
	dc	10,0
debugger_78:	; DBG>ib%d <not set>
	dc	13,10,68,66,71,62,105,98
	dc	37,100,32,60,110,111,116,32
	dc	115,101,116,62,0
debugger_77:	; DBG>ib%d=%08X
	dc	13,10,68,66,71,62,105,98
	dc	37,100,61,37,48,56,88,13
	dc	10,0
debugger_14:	; DBG>
	dc	13,10,68,66,71,62,0
debugger_13:	; Type 'q' to quit.
	dc	13,10,84,121,112,101,32,39
	dc	113,39,32,116,111,32,113,117
	dc	105,116,46,0
debugger_12:	; arm debugging mode using the 'a' command.
	dc	13,10,97,114,109,32,100,101
	dc	98,117,103,103,105,110,103,32
	dc	109,111,100,101,32,117,115,105
	dc	110,103,32,116,104,101,32,39
	dc	97,39,32,99,111,109,109,97
	dc	110,100,46,0
debugger_11:	; Once the debug registers are set it is necessary to 
	dc	13,10,79,110,99,101,32,116
	dc	104,101,32,100,101,98,117,103
	dc	32,114,101,103,105,115,116,101
	dc	114,115,32,97,114,101,32,115
	dc	101,116,32,105,116,32,105,115
	dc	32,110,101,99,101,115,115,97
	dc	114,121,32,116,111,32,0
debugger_10:	; Setting a register to zero will clear the breakpoint.
	dc	13,10,83,101,116,116,105,110
	dc	103,32,97,32,114,101,103,105
	dc	115,116,101,114,32,116,111,32
	dc	122,101,114,111,32,119,105,108
	dc	108,32,99,108,101,97,114,32
	dc	116,104,101,32,98,114,101,97
	dc	107,112,111,105,110,116,46,0
debugger_9:	; indicate a data store only breakpoint.
	dc	13,10,105,110,100,105,99,97
	dc	116,101,32,97,32,100,97,116
	dc	97,32,115,116,111,114,101,32
	dc	111,110,108,121,32,98,114,101
	dc	97,107,112,111,105,110,116,46
	dc	0
debugger_8:	; breakpoint. Prefix the register number with 'ds' to
	dc	13,10,98,114,101,97,107,112
	dc	111,105,110,116,46,32,80,114
	dc	101,102,105,120,32,116,104,101
	dc	32,114,101,103,105,115,116,101
	dc	114,32,110,117,109,98,101,114
	dc	32,119,105,116,104,32,39,100
	dc	115,39,32,116,111,0
debugger_7:	; instruction breakpoint or a 'd' to indicate a data
	dc	13,10,105,110,115,116,114,117
	dc	99,116,105,111,110,32,98,114
	dc	101,97,107,112,111,105,110,116
	dc	32,111,114,32,97,32,39,100
	dc	39,32,116,111,32,105,110,100
	dc	105,99,97,116,101,32,97,32
	dc	100,97,116,97,0
debugger_6:	; Prefix the register number with an 'i' to indicate an
	dc	13,10,80,114,101,102,105,120
	dc	32,116,104,101,32,114,101,103
	dc	105,115,116,101,114,32,110,117
	dc	109,98,101,114,32,119,105,116
	dc	104,32,97,110,32,39,105,39
	dc	32,116,111,32,105,110,100,105
	dc	99,97,116,101,32,97,110,0
debugger_5:	; There are a total of four breakpoint registers (0-3).
	dc	13,10,84,104,101,114,101,32
	dc	97,114,101,32,97,32,116,111
	dc	116,97,108,32,111,102,32,102
	dc	111,117,114,32,98,114,101,97
	dc	107,112,111,105,110,116,32,114
	dc	101,103,105,115,116,101,114,115
	dc	32,40,48,45,51,41,46,0
debugger_4:	; DBG>i1=12345678     will assign 12345678 to i1
	dc	13,10,68,66,71,62,105,49
	dc	61,49,50,51,52,53,54,55
	dc	56,32,32,32,32,32,119,105
	dc	108,108,32,97,115,115,105,103
	dc	110,32,49,50,51,52,53,54
	dc	55,56,32,116,111,32,105,49
	dc	0
debugger_3:	; an address to it.
	dc	13,10,97,110,32,97,100,100
	dc	114,101,115,115,32,116,111,32
	dc	105,116,46,0
debugger_2:	; Following a breakpoint register with an '=' assigns 
	dc	13,10,70,111,108,108,111,119
	dc	105,110,103,32,97,32,98,114
	dc	101,97,107,112,111,105,110,116
	dc	32,114,101,103,105,115,116,101
	dc	114,32,119,105,116,104,32,97
	dc	110,32,39,61,39,32,97,115
	dc	115,105,103,110,115,32,0
debugger_1:	; DBG>i2?
	dc	13,10,68,66,71,62,105,50
	dc	63,0
debugger_0:	; '?' queries the status of a breakpoint register as in:
	dc	13,10,39,63,39,32,113,117
	dc	101,114,105,101,115,32,116,104
	dc	101,32,115,116,97,116,117,115
	dc	32,111,102,32,97,32,98,114
	dc	101,97,107,112,111,105,110,116
	dc	32,114,101,103,105,115,116,101
	dc	114,32,97,115,32,105,110,58
	dc	0
;	global	GetVBR
;	global	dbg_ReadSetDSB
	extern	putch
;	global	dbg_prompt
;	global	CvtScreenToAscii
;	global	dbg_GetHexNumber
;	global	set_vector
;	global	dbg_init
;	global	debugger
;	global	dbg_GetCursorCol
;	global	ignore_blanks
;	global	dbg_GetCursorRow
;	global	dbg_nextNonSpace
;	global	dbg_getchar
;	global	dbg_ungetch
;	global	dbctrl
	extern	printf
;	global	dbg_stack
;	global	dbg_parse_line
;	global	dbg_GetDBAD
;	global	dbg_ReadSetDB
	extern	disassem20
;	global	dbg_ReadSetIB
;	global	dbg_SetDBAD
;	global	dbg_arm
;	global	dbg_irq
	extern	getchar
;	global	linebuf
;	global	dbg_DisplayHelp
;	global	linendx
