	data
	align	8
	fill.b	1,0x00
	align	8
	fill.b	16,0x00
	align	8
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
    
TCB_1:
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
     
TCB_7:
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
	      	ldi  	r13,#tcbs_
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#256
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r13
	      	mov  	r11,r3
	      	lb   	r3,716[r11]
	      	cmp  	r4,r3,#63
	      	bgt  	r4,TCB_11
	      	lb   	r3,716[r11]
	      	bge  	r3,TCB_9
TCB_11:
	      	ldi  	r1,#2
TCB_12:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
TCB_9:
	      	lb   	r3,716[r11]
	      	cmp  	r4,r3,#3
	      	bge  	r4,TCB_13
	      	ldi  	r4,#1
	      	lb   	r5,716[r11]
	      	sxb  	r5,r5
	      	asl  	r3,r4,r5
	      	lcu  	r4,hasUltraHighPriorityTasks_
	      	or   	r4,r4,r3
	      	sc   	r4,hasUltraHighPriorityTasks_
TCB_13:
	      	ldi  	r3,#16
	      	sb   	r3,717[r11]
	      	lb   	r5,716[r11]
	      	sxb  	r5,r5
	      	asri 	r4,r5,#3
	      	asli 	r3,r4,#1
	      	lc   	r4,readyQ_[r3]
	      	sc   	r4,-2[bp]
	      	lc   	r3,-2[bp]
	      	bge  	r3,TCB_15
	      	lc   	r3,24[bp]
	      	sc   	r3,624[r11]
	      	lc   	r3,24[bp]
	      	sc   	r3,626[r11]
	      	lb   	r5,716[r11]
	      	sxb  	r5,r5
	      	asri 	r4,r5,#3
	      	asli 	r3,r4,#1
	      	lc   	r4,24[bp]
	      	sc   	r4,readyQ_[r3]
	      	ldi  	r1,#0
	      	bra  	TCB_12
TCB_15:
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
	      	bra  	TCB_12
endpublic

public code RemoveFromReadyList_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	ldi  	r12,#readyQ_
	      	ldi  	r13,#tcbs_
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#256
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r13
	      	mov  	r11,r3
	      	lb   	r3,716[r11]
	      	cmp  	r4,r3,#63
	      	bgt  	r4,TCB_20
	      	lb   	r3,716[r11]
	      	bge  	r3,TCB_18
TCB_20:
	      	ldi  	r1,#2
TCB_21:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
TCB_18:
	      	lc   	r3,24[bp]
	      	lb   	r6,716[r11]
	      	sxb  	r6,r6
	      	asri 	r5,r6,#3
	      	asli 	r4,r5,#1
	      	lc   	r4,0[r12+r4]
	      	cmp  	r5,r3,r4
	      	bne  	r5,TCB_22
	      	lb   	r5,716[r11]
	      	sxb  	r5,r5
	      	asri 	r4,r5,#3
	      	asli 	r3,r4,#1
	      	lc   	r4,624[r11]
	      	sc   	r4,0[r12+r3]
TCB_22:
	      	lc   	r3,24[bp]
	      	lb   	r6,716[r11]
	      	sxb  	r6,r6
	      	asri 	r5,r6,#3
	      	asli 	r4,r5,#1
	      	lc   	r4,0[r12+r4]
	      	cmp  	r5,r3,r4
	      	bne  	r5,TCB_24
	      	lb   	r5,716[r11]
	      	sxb  	r5,r5
	      	asri 	r4,r5,#3
	      	asli 	r3,r4,#1
	      	ldi  	r4,#-1
	      	sc   	r4,0[r12+r3]
TCB_24:
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
	      	bra  	TCB_21
endpublic

public code InsertIntoTimeoutList_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	ldi  	r13,#TimeoutList_
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#256
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	mov  	r12,r3
	      	lc   	r3,[r13]
	      	bge  	r3,TCB_27
	      	lw   	r3,32[bp]
	      	sw   	r3,656[r12]
	      	lc   	r3,24[bp]
	      	sc   	r3,[r13]
	      	ldi  	r3,#-1
	      	sc   	r3,624[r12]
	      	ldi  	r3,#-1
	      	sc   	r3,626[r12]
	      	ldi  	r1,#0
TCB_29:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#32
TCB_27:
	      	sw   	r0,-16[bp]
	      	lc   	r5,[r13]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	mov  	r11,r3
TCB_30:
	      	lw   	r3,32[bp]
	      	lw   	r4,656[r11]
	      	cmp  	r5,r3,r4
	      	ble  	r5,TCB_31
	      	lw   	r3,656[r11]
	      	lw   	r4,32[bp]
	      	subu 	r4,r4,r3
	      	sw   	r4,32[bp]
	      	sw   	r11,-16[bp]
	      	lc   	r5,624[r11]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	mov  	r11,r3
	      	bra  	TCB_30
TCB_31:
	      	subu 	r4,r11,#tcbs_
	      	lsri 	r3,r4,#10
	      	sc   	r3,624[r12]
	      	lw   	r5,-16[bp]
	      	subu 	r4,r5,#tcbs_
	      	lsri 	r3,r4,#10
	      	sc   	r3,626[r12]
	      	beq  	r11,TCB_32
	      	lw   	r3,32[bp]
	      	lw   	r4,656[r11]
	      	subu 	r4,r4,r3
	      	sw   	r4,656[r11]
	      	lc   	r3,24[bp]
	      	sc   	r3,626[r11]
TCB_32:
	      	lw   	r3,-16[bp]
	      	beq  	r3,TCB_34
	      	lw   	r3,-16[bp]
	      	lc   	r4,24[bp]
	      	sc   	r4,624[r3]
	      	bra  	TCB_35
TCB_34:
	      	lc   	r3,24[bp]
	      	sc   	r3,[r13]
TCB_35:
	      	lb   	r3,717[r12]
	      	ori  	r3,r3,#1
	      	sb   	r3,717[r12]
	      	ldi  	r1,#0
	      	bra  	TCB_29
endpublic

public code RemoveFromTimeoutList_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	ldi  	r12,#tcbs_
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#256
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r12
	      	mov  	r11,r3
	      	lc   	r3,624[r11]
	      	beq  	r3,TCB_37
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
TCB_37:
	      	lc   	r3,626[r11]
	      	blt  	r3,TCB_39
	      	lc   	r5,626[r11]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r12
	      	lc   	r4,624[r11]
	      	sc   	r4,624[r3]
TCB_39:
	      	sb   	r0,717[r11]
	      	ldi  	r3,#-1
	      	sc   	r3,624[r11]
	      	ldi  	r3,#-1
	      	sc   	r3,626[r11]
TCB_41:
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
	      	ldi  	r11,#TimeoutList_
	      	lc   	r3,[r11]
	      	sc   	r3,-10[bp]
	      	lc   	r3,[r11]
	      	blt  	r3,TCB_43
	      	lc   	r3,[r11]
	      	cmp  	r4,r3,#256
	      	bge  	r4,TCB_43
	      	lc   	r5,[r11]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	lc   	r4,624[r3]
	      	sc   	r4,[r11]
	      	lc   	r3,[r11]
	      	blt  	r3,TCB_45
	      	lc   	r3,[r11]
	      	cmp  	r4,r3,#256
	      	bge  	r4,TCB_45
	      	lc   	r5,[r11]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	ldi  	r4,#-1
	      	sc   	r4,626[r3]
TCB_45:
TCB_43:
	      	lc   	r3,-10[bp]
	      	mov  	r1,r3
TCB_47:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code DumpTaskList_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#TCB_51
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	push 	#TCB_48
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	sw   	r0,-24[bp]
TCB_52:
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#8
	      	bge  	r4,TCB_53
	      	lw   	r4,-24[bp]
	      	asli 	r3,r4,#1
	      	lc   	r4,readyQ_[r3]
	      	sc   	r4,-34[bp]
	      	lc   	r3,-34[bp]
	      	blt  	r3,TCB_55
	      	lc   	r3,-34[bp]
	      	cmp  	r4,r3,#256
	      	bge  	r4,TCB_55
	      	lc   	r5,-34[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	sw   	r3,-16[bp]
	      	lw   	r11,-16[bp]
	      	sw   	r0,-32[bp]
TCB_57:
	      	subu 	r4,r11,#tcbs_
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
	      	push 	#TCB_49
	      	bsr  	printf_
	      	addui	sp,sp,#72
	      	lc   	r3,624[r11]
	      	blt  	r3,TCB_61
	      	lc   	r3,624[r11]
	      	cmp  	r4,r3,#256
	      	blt  	r4,TCB_59
TCB_61:
	      	bra  	TCB_58
TCB_59:
	      	lc   	r5,624[r11]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	mov  	r11,r3
	      	bsr  	getcharNoWait_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#3
	      	bne  	r4,TCB_62
	      	bra  	TCB_50
TCB_62:
	      	lw   	r4,-32[bp]
	      	addu 	r3,r4,#1
	      	sw   	r3,-32[bp]
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r11,r3
	      	beq  	r4,TCB_64
	      	lw   	r3,-32[bp]
	      	cmp  	r4,r3,#10
	      	blt  	r4,TCB_57
TCB_64:
TCB_58:
TCB_55:
TCB_54:
	      	inc  	-24[bp],#1
	      	bra  	TCB_52
TCB_53:
TCB_50:
TCB_65:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
TCB_51:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	TCB_65
endpublic

	rodata
	align	16
	align	8
TCB_49:
	dc	37,51,100,32,37,51,100,32
	dc	32,37,48,50,88,32,32,37
	dc	48,52,88,32,37,48,52,88
	dc	32,37,48,52,88,32,37,48
	dc	56,88,32,37,48,56,88,13
	dc	10,0
TCB_48:
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
;	global	SetBound50_
;	global	SetBound51_
;	global	SetBound48_
;	global	SetBound49_
;	global	InsertIntoTimeoutList_
;	global	RemoveFromReadyList_
	extern	printf_
;	global	InsertIntoReadyList_
