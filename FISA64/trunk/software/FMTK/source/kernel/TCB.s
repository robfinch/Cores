	data
	align	8
	fill.b	1,0x00
	align	8
	fill.b	16,0x00
	align	8
	fill.b	1984,0x00
	align	8
	align	8
	align	8
	fill.b	896,0x00
	bss
	align	1024
public bss tcbs_:
	fill.b	262144,0x00

endpublic
	align	8
public bss freeTCB_:
	fill.b	2,0x00

endpublic
	align	8
public bss TimeoutList_:
	fill.b	2,0x00

endpublic
	align	8
public bss readyQ_:
	fill.b	16,0x00

endpublic
	code
	align	16
public code chkTCB_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw    r1,24[bp]
        chk   r1,r1,b48
    
TCB_2:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
endpublic

public code GetRunningTCBPtr_:
	      	     	        mov   r1,tr
        rtl
    
endpublic

public code GetRunningTCB_:
	      	     	        subui  r1,tr,#tcbs_
        lsri   r1,r1,#10
        rtl
    
endpublic

public code SetRunningTCB_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw      tr,24[bp]
         asli    tr,tr,#10
         addui   tr,tr,#tcbs_
     
TCB_11:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
endpublic

	data
	align	8
	code
	align	16
public code InsertIntoReadyList_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lea  	r3,tcbs_[gp]
	      	mov  	r13,r3
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#256
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r13
	      	mov  	r11,r3
	      	lb   	r3,716[r11]
	      	cmp  	r4,r3,#63
	      	bgt  	r4,TCB_16
	      	lb   	r3,716[r11]
	      	bge  	r3,TCB_14
TCB_16:
	      	ldi  	r1,#2
TCB_17:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
TCB_14:
	      	lb   	r3,716[r11]
	      	cmp  	r4,r3,#3
	      	bge  	r4,TCB_18
	      	ldi  	r4,#1
	      	lb   	r5,716[r11]
	      	sxb  	r5,r5
	      	asl  	r3,r4,r5
	      	lc   	r4,hasUltraHighPriorityTasks_[gp]
	      	or   	r4,r4,r3
	      	sc   	r4,hasUltraHighPriorityTasks_[gp]
TCB_18:
	      	ldi  	r3,#16
	      	sb   	r3,717[r11]
	      	lb   	r5,716[r11]
	      	sxb  	r5,r5
	      	asri 	r4,r5,#3
	      	asli 	r3,r4,#1
	      	lea  	r4,readyQ_[gp]
	      	lc   	r5,0[r4+r3]
	      	sc   	r5,-2[bp]
	      	lc   	r3,-2[bp]
	      	bge  	r3,TCB_20
	      	lc   	r3,24[bp]
	      	sc   	r3,624[r11]
	      	lc   	r3,24[bp]
	      	sc   	r3,626[r11]
	      	lb   	r5,716[r11]
	      	sxb  	r5,r5
	      	asri 	r4,r5,#3
	      	asli 	r3,r4,#1
	      	lea  	r4,readyQ_[gp]
	      	lc   	r5,24[bp]
	      	sc   	r5,0[r4+r3]
	      	ldi  	r1,#0
	      	bra  	TCB_17
TCB_20:
	      	lc   	r5,-2[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r13
	      	mov  	r12,r3
	      	lc   	r3,-2[bp]
	      	sc   	r3,624[r11]
	      	lc   	r3,626[r12]
	      	sc   	r3,626[r11]
	      	lc   	r5,626[r12]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r13
	      	lc   	r4,24[bp]
	      	sc   	r4,624[r3]
	      	lc   	r3,24[bp]
	      	sc   	r3,626[r12]
	      	ldi  	r1,#0
	      	bra  	TCB_17
endpublic

public code RemoveFromReadyList_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lea  	r3,readyQ_[gp]
	      	mov  	r12,r3
	      	lea  	r3,tcbs_[gp]
	      	mov  	r13,r3
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#256
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r13
	      	mov  	r11,r3
	      	lb   	r3,716[r11]
	      	cmp  	r4,r3,#63
	      	bgt  	r4,TCB_26
	      	lb   	r3,716[r11]
	      	bge  	r3,TCB_24
TCB_26:
	      	ldi  	r1,#2
TCB_27:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
TCB_24:
	      	lc   	r3,24[bp]
	      	lb   	r6,716[r11]
	      	sxb  	r6,r6
	      	asri 	r5,r6,#3
	      	asli 	r4,r5,#1
	      	lc   	r4,0[r12+r4]
	      	cmp  	r5,r3,r4
	      	bne  	r5,TCB_28
	      	lb   	r5,716[r11]
	      	sxb  	r5,r5
	      	asri 	r4,r5,#3
	      	asli 	r3,r4,#1
	      	lc   	r4,624[r11]
	      	sc   	r4,0[r12+r3]
TCB_28:
	      	lc   	r3,24[bp]
	      	lb   	r6,716[r11]
	      	sxb  	r6,r6
	      	asri 	r5,r6,#3
	      	asli 	r4,r5,#1
	      	lc   	r4,0[r12+r4]
	      	cmp  	r5,r3,r4
	      	bne  	r5,TCB_30
	      	lb   	r5,716[r11]
	      	sxb  	r5,r5
	      	asri 	r4,r5,#3
	      	asli 	r3,r4,#1
	      	ldi  	r4,#-1
	      	sc   	r4,0[r12+r3]
TCB_30:
	      	lc   	r5,624[r11]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r13
	      	lc   	r4,626[r11]
	      	sc   	r4,626[r3]
	      	lc   	r5,626[r11]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r13
	      	lc   	r4,624[r11]
	      	sc   	r4,624[r3]
	      	ldi  	r3,#-1
	      	sc   	r3,624[r11]
	      	ldi  	r3,#-1
	      	sc   	r3,626[r11]
	      	sb   	r0,717[r11]
	      	ldi  	r1,#0
	      	bra  	TCB_27
endpublic

public code InsertIntoTimeoutList_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lea  	r3,TimeoutList_[gp]
	      	mov  	r13,r3
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#256
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r12,r3
	      	lc   	r3,[r13]
	      	bge  	r3,TCB_34
	      	lw   	r3,32[bp]
	      	sw   	r3,656[r12]
	      	lc   	r3,24[bp]
	      	sc   	r3,[r13]
	      	ldi  	r3,#-1
	      	sc   	r3,624[r12]
	      	ldi  	r3,#-1
	      	sc   	r3,626[r12]
	      	ldi  	r1,#0
TCB_36:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#32
TCB_34:
	      	ldi  	r3,#0
	      	sw   	r3,-16[bp]
	      	lc   	r5,[r13]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r11,r3
TCB_37:
	      	lw   	r3,32[bp]
	      	lw   	r4,656[r11]
	      	cmp  	r5,r3,r4
	      	ble  	r5,TCB_38
	      	lw   	r3,656[r11]
	      	lw   	r4,32[bp]
	      	subu 	r4,r4,r3
	      	sw   	r4,32[bp]
	      	sw   	r11,-16[bp]
	      	lc   	r5,624[r11]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r11,r3
	      	bra  	TCB_37
TCB_38:
	      	lea  	r5,tcbs_[gp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#10
	      	sc   	r3,624[r12]
	      	lw   	r5,-16[bp]
	      	lea  	r6,tcbs_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#10
	      	sc   	r3,626[r12]
	      	beq  	r11,TCB_39
	      	lw   	r3,32[bp]
	      	lw   	r4,656[r11]
	      	subu 	r4,r4,r3
	      	sw   	r4,656[r11]
	      	lc   	r3,24[bp]
	      	sc   	r3,626[r11]
TCB_39:
	      	lw   	r3,-16[bp]
	      	beq  	r3,TCB_41
	      	lw   	r3,-16[bp]
	      	lc   	r4,24[bp]
	      	sc   	r4,624[r3]
	      	bra  	TCB_42
TCB_41:
	      	lc   	r3,24[bp]
	      	sc   	r3,[r13]
TCB_42:
	      	lb   	r3,717[r12]
	      	ori  	r3,r3,#1
	      	sb   	r3,717[r12]
	      	ldi  	r1,#0
	      	bra  	TCB_36
endpublic

public code RemoveFromTimeoutList_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	lea  	r3,tcbs_[gp]
	      	mov  	r12,r3
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#256
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r12
	      	mov  	r11,r3
	      	lc   	r3,624[r11]
	      	beq  	r3,TCB_45
	      	lc   	r5,624[r11]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r12
	      	lc   	r4,626[r11]
	      	sc   	r4,626[r3]
	      	lc   	r5,624[r11]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r12
	      	lw   	r4,656[r11]
	      	lw   	r5,656[r3]
	      	addu 	r5,r5,r4
	      	sw   	r5,656[r3]
TCB_45:
	      	lc   	r3,626[r11]
	      	blt  	r3,TCB_47
	      	lc   	r5,626[r11]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r12
	      	lc   	r4,624[r11]
	      	sc   	r4,624[r3]
TCB_47:
	      	sb   	r0,717[r11]
	      	ldi  	r3,#-1
	      	sc   	r3,624[r11]
	      	ldi  	r3,#-1
	      	sc   	r3,626[r11]
TCB_49:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
endpublic

public code PopTimeoutList_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	lea  	r3,TimeoutList_[gp]
	      	mov  	r11,r3
	      	lc   	r3,[r11]
	      	sc   	r3,-10[bp]
	      	lc   	r3,[r11]
	      	blt  	r3,TCB_52
	      	lc   	r3,[r11]
	      	cmp  	r4,r3,#256
	      	bge  	r4,TCB_52
	      	lc   	r5,[r11]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	lc   	r4,624[r3]
	      	sc   	r4,[r11]
	      	lc   	r3,[r11]
	      	blt  	r3,TCB_54
	      	lc   	r3,[r11]
	      	cmp  	r4,r3,#256
	      	bge  	r4,TCB_54
	      	lc   	r5,[r11]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	ldi  	r4,#-1
	      	sc   	r4,626[r3]
TCB_54:
TCB_52:
	      	lc   	r3,-10[bp]
	      	mov  	r1,r3
TCB_56:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code DumpTaskList_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#TCB_62
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	pea  	TCB_57[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	sw   	r0,-24[bp]
TCB_64:
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#8
	      	bge  	r4,TCB_65
	      	lw   	r4,-24[bp]
	      	asli 	r3,r4,#1
	      	lea  	r4,readyQ_[gp]
	      	lc   	r5,0[r4+r3]
	      	sc   	r5,-34[bp]
	      	lc   	r3,-34[bp]
	      	blt  	r3,TCB_67
	      	lc   	r3,-34[bp]
	      	cmp  	r4,r3,#256
	      	bge  	r4,TCB_67
	      	lc   	r5,-34[bp]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	sw   	r3,-16[bp]
	      	lw   	r11,-16[bp]
	      	sw   	r0,-32[bp]
TCB_69:
	      	lea  	r5,tcbs_[gp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#10
	      	sc   	r3,-36[bp]
	      	push 	736[r11]
	      	push 	656[r11]
	      	lc   	r3,624[r11]
	      	push 	r3
	      	lc   	r3,626[r11]
	      	push 	r3
	      	lc   	r3,-36[bp]
	      	push 	r3
	      	lb   	r3,717[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	lb   	r3,716[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	lb   	r3,718[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	pea  	TCB_58[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#72
	      	lc   	r3,624[r11]
	      	blt  	r3,TCB_73
	      	lc   	r3,624[r11]
	      	cmp  	r4,r3,#256
	      	blt  	r4,TCB_71
TCB_73:
	      	bra  	TCB_70
TCB_71:
	      	lc   	r5,624[r11]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r11,r3
	      	bsr  	getcharNoWait_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#3
	      	bne  	r4,TCB_74
	      	bra  	TCB_59
TCB_74:
	      	lw   	r4,-32[bp]
	      	addu 	r3,r4,#1
	      	sw   	r3,-32[bp]
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r11,r3
	      	beq  	r4,TCB_76
	      	lw   	r3,-32[bp]
	      	cmp  	r4,r3,#10
	      	blt  	r4,TCB_69
TCB_76:
TCB_70:
TCB_67:
TCB_66:
	      	inc  	-24[bp],#1
	      	bra  	TCB_64
TCB_65:
	      	pea  	TCB_60[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lc   	r3,TimeoutList_[gp]
	      	sc   	r3,-34[bp]
TCB_77:
	      	lc   	r3,-34[bp]
	      	blt  	r3,TCB_78
	      	lc   	r3,-34[bp]
	      	cmp  	r4,r3,#256
	      	bge  	r4,TCB_78
	      	lc   	r5,-34[bp]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r11,r3
	      	push 	736[r11]
	      	push 	656[r11]
	      	lc   	r3,624[r11]
	      	push 	r3
	      	lc   	r3,626[r11]
	      	push 	r3
	      	lc   	r3,-36[bp]
	      	push 	r3
	      	lb   	r3,717[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	lb   	r3,716[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	lb   	r3,718[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	pea  	TCB_61[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#72
	      	lc   	r3,624[r11]
	      	sc   	r3,-34[bp]
	      	bsr  	getcharNoWait_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#3
	      	bne  	r4,TCB_79
	      	bra  	TCB_59
TCB_79:
	      	bra  	TCB_77
TCB_78:
TCB_59:
TCB_81:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
TCB_62:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	TCB_81
endpublic

	rodata
	align	16
	align	8
TCB_61:
	dc	37,51,100,32,37,51,100,32
	dc	32,37,48,50,88,32,32,37
	dc	48,52,88,32,37,48,52,88
	dc	32,37,48,52,88,32,37,48
	dc	56,88,32,37,48,56,88,13
	dc	10,0
TCB_60:
	dc	87,97,105,116,105,110,103,32
	dc	116,97,115,107,115,13,10,0
TCB_58:
	dc	37,51,100,32,37,51,100,32
	dc	32,37,48,50,88,32,32,37
	dc	48,52,88,32,37,48,52,88
	dc	32,37,48,52,88,32,37,48
	dc	56,88,32,37,48,56,88,13
	dc	10,0
TCB_57:
	dc	67,80,85,32,80,114,105,32
	dc	83,116,97,116,32,84,97,115
	dc	107,32,80,114,101,118,32,78
	dc	101,120,116,32,84,105,109,101
	dc	111,117,116,13,10,0
;	global	tcbs_
;	global	PopTimeoutList_
;	global	outb_
;	global	outc_
;	global	outh_
;	global	DumpTaskList_
;	global	outw_
;	global	GetRunningTCB_
;	global	SetRunningTCB_
;	global	chkTCB_
;	global	GetRunningTCBPtr_
;	global	UnlockSemaphore_
	extern	GetVecno_
	extern	GetJCBPtr_
	extern	getCPU_
	extern	hasUltraHighPriorityTasks_
;	global	LockSemaphore_
	extern	getcharNoWait_
;	global	set_vector_
;	global	readyQ_
;	global	freeTCB_
;	global	TimeoutList_
;	global	RemoveFromTimeoutList_
	extern	prtdbl_
;	global	SetBound50_
;	global	SetBound51_
;	global	SetBound48_
;	global	SetBound49_
;	global	InsertIntoTimeoutList_
;	global	RemoveFromReadyList_
	extern	printf_
;	global	InsertIntoReadyList_
