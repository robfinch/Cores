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
	bss
	align	8
public bss keybd_irq_stack_:
	fill.b	4096,0x00

endpublic
	code
	align	16
	data
	align	8
	code
	align	16
public code KeybdIRQ_:
	      	     	         lea   sp,keybd_irq_stack_+4088
         sw    r1,8+312[tr]
         sw    r2,16+312[tr]
         sw    r3,24+312[tr]
         sw    r4,32+312[tr]
         sw    r5,40+312[tr]
         sw    r6,48+312[tr]
         sw    r7,56+312[tr]
         sw    r8,64+312[tr]
         sw    r9,72+312[tr]
         sw    r10,80+312[tr]
         sw    r11,88+312[tr]
         sw    r12,96+312[tr]
         sw    r13,104+312[tr]
         sw    r14,112+312[tr]
         sw    r15,120+312[tr]
         sw    r16,128+312[tr]
         sw    r17,136+312[tr]
         sw    r18,144+312[tr]
         sw    r19,152+312[tr]
         sw    r20,160+312[tr]
         sw    r21,168+312[tr]
         sw    r22,176+312[tr]
         sw    r23,184+312[tr]
         sw    r24,192+312[tr]
         sw    r25,200+312[tr]
         sw    r26,208+312[tr]
         sw    r27,216+312[tr]
         sw    r28,224+312[tr]
         sw    r29,232+312[tr]
         sw    r30,240+312[tr]
         sw    r31,248+312[tr]
         mfspr r1,cr0
         sw    r1,304[tr]
     
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#keybd_0
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	bsr  	KeybdGetStatus_
	      	mov  	r3,r1
	      	bge  	r3,keybd_1
	      	bsr  	KeybdGetScancode_
	      	mov  	r3,r1
	      	sb   	r3,-1[bp]
	      	lw   	r11,IOFocusNdx_
	      	beq  	r11,keybd_3
	      	push 	#10000
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,keybd_5
	      	bsr  	KeybdClearRcv_
	      	lb   	r3,1647[r11]
	      	sb   	r3,-2[bp]
	      	lb   	r3,1648[r11]
	      	sb   	r3,-3[bp]
	      	lb   	r3,-2[bp]
	      	addui	r3,r3,#1
	      	sb   	r3,-2[bp]
	      	lb   	r3,-2[bp]
	      	andi 	r3,r3,#15
	      	sb   	r3,-2[bp]
	      	lb   	r3,-2[bp]
	      	lb   	r4,-3[bp]
	      	cmp  	r5,r3,r4
	      	beq  	r5,keybd_7
	      	lb   	r3,-2[bp]
	      	sb   	r3,1647[r11]
	      	lb   	r3,-1[bp]
	      	sxb  	r3,r3
	      	lb   	r6,-2[bp]
	      	sxb  	r6,r6
	      	asli 	r5,r6,#1
	      	addu 	r4,r5,r11
	      	sc   	r3,1650[r4]
keybd_7:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
keybd_5:
	      	lb   	r4,1645[r11]
	      	and  	r3,r4,#2
	      	beq  	r3,keybd_9
	      	lb   	r3,-1[bp]
	      	cmp  	r4,r3,#13
	      	bne  	r4,keybd_9
	      	inc  	iof_switch_,#1
keybd_9:
keybd_3:
keybd_1:
keybd_11:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	     	         lw    r1,304[tr]
         mtspr cr0,r1
         lw    r1,8+312[tr]
         lw    r2,16+312[tr]
         lw    r3,24+312[tr]
         lw    r4,32+312[tr]
         lw    r5,40+312[tr]
         lw    r6,48+312[tr]
         lw    r7,56+312[tr]
         lw    r8,64+312[tr]
         lw    r9,72+312[tr]
         lw    r10,80+312[tr]
         lw    r11,88+312[tr]
         lw    r12,96+312[tr]
         lw    r13,104+312[tr]
         lw    r14,112+312[tr]
         lw    r15,120+312[tr]
         lw    r16,128+312[tr]
         lw    r17,136+312[tr]
         lw    r18,144+312[tr]
         lw    r19,152+312[tr]
         lw    r20,160+312[tr]
         lw    r21,168+312[tr]
         lw    r22,176+312[tr]
         lw    r23,184+312[tr]
         lw    r25,200+312[tr]
         lw    r26,208+312[tr]
         lw    r27,216+312[tr]
         lw    r28,224+312[tr]
         lw    r29,232+312[tr]
         lw    r31,248+312[tr]
         rti
     
keybd_0:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	keybd_11
endpublic

public code KeybdGetBufferStatus_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#keybd_12
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,keybd_13
	      	lb   	r3,1647[r11]
	      	sb   	r3,-9[bp]
	      	lb   	r3,1648[r11]
	      	sb   	r3,-10[bp]
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
keybd_13:
	      	lb   	r3,-9[bp]
	      	lb   	r4,-10[bp]
	      	cmp  	r5,r3,r4
	      	beq  	r5,keybd_15
	      	ldi  	r1,#-1
keybd_17:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
keybd_15:
	      	ldi  	r1,#0
	      	bra  	keybd_17
keybd_12:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	keybd_17
endpublic

public code KeybdGetBufferedScancode_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#keybd_18
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,keybd_19
	      	lb   	r3,1647[r11]
	      	sb   	r3,-9[bp]
	      	lb   	r3,1648[r11]
	      	sb   	r3,-10[bp]
	      	lb   	r3,-9[bp]
	      	lb   	r4,-10[bp]
	      	cmp  	r5,r3,r4
	      	beq  	r5,keybd_21
	      	lb   	r4,-10[bp]
	      	sxb  	r4,r4
	      	asli 	r3,r4,#1
	      	addu 	r4,r11,#1650
	      	lcu  	r3,0[r4+r3]
	      	sxc  	r3,r3
	      	sb   	r3,-11[bp]
	      	lb   	r3,-10[bp]
	      	addui	r3,r3,#1
	      	sb   	r3,-10[bp]
	      	lb   	r3,-10[bp]
	      	andi 	r3,r3,#15
	      	sb   	r3,-10[bp]
	      	lb   	r3,-10[bp]
	      	sb   	r3,1648[r11]
	      	bra  	keybd_22
keybd_21:
	      	sb   	r0,-11[bp]
keybd_22:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
keybd_19:
	      	lb   	r3,-11[bp]
	      	sxb  	r3,r3
	      	mov  	r1,r3
keybd_23:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
keybd_18:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	keybd_23
endpublic

	data
	align	8
	code
	align	16
KeybdGetBufferedChar_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#keybd_25
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
keybd_26:
keybd_28:
	      	bsr  	KeybdGetBufferStatus_
	      	mov  	r3,r1
	      	blt  	r3,keybd_29
	      	lb   	r3,1646[r11]
	      	bne  	r3,keybd_30
	      	ldi  	r1,#-1
keybd_32:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
keybd_30:
	      	bra  	keybd_28
keybd_29:
	      	bsr  	KeybdGetBufferedScancode_
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	cmp  	r3,r12,#240
	      	beq  	r3,keybd_34
	      	cmp  	r3,r12,#224
	      	beq  	r3,keybd_35
	      	cmp  	r3,r12,#20
	      	beq  	r3,keybd_36
	      	cmp  	r3,r12,#89
	      	beq  	r3,keybd_37
	      	cmp  	r3,r12,#119
	      	beq  	r3,keybd_38
	      	cmp  	r3,r12,#88
	      	beq  	r3,keybd_39
	      	cmp  	r3,r12,#126
	      	beq  	r3,keybd_40
	      	cmp  	r3,r12,#17
	      	beq  	r3,keybd_41
	      	bra  	keybd_42
keybd_34:
	      	ldi  	r3,#-1
	      	sb   	r3,1644[r11]
	      	bra  	keybd_33
keybd_35:
	      	lb   	r3,1645[r11]
	      	ori  	r3,r3,#128
	      	sb   	r3,1645[r11]
	      	lb   	r3,1645[r11]
	      	sxb  	r3,r3
	      	bra  	keybd_33
keybd_36:
	      	lb   	r3,1644[r11]
	      	blt  	r3,keybd_43
	      	lb   	r3,1645[r11]
	      	ori  	r3,r3,#4
	      	sb   	r3,1645[r11]
	      	bra  	keybd_44
keybd_43:
	      	lb   	r3,1645[r11]
	      	andi 	r3,r3,#-5
	      	sb   	r3,1645[r11]
keybd_44:
	      	sb   	r0,1644[r11]
	      	bra  	keybd_33
keybd_37:
	      	lb   	r3,1644[r11]
	      	blt  	r3,keybd_45
	      	lb   	r3,1645[r11]
	      	ori  	r3,r3,#1
	      	sb   	r3,1645[r11]
	      	bra  	keybd_46
keybd_45:
	      	lb   	r3,1645[r11]
	      	andi 	r3,r3,#-2
	      	sb   	r3,1645[r11]
keybd_46:
	      	sb   	r0,1644[r11]
	      	bra  	keybd_33
keybd_38:
	      	lw   	r3,-8[bp]
	      	lb   	r4,1645[r3]
	      	xori 	r4,r4,#16
	      	sb   	r4,1645[r3]
	      	bra  	keybd_33
keybd_39:
	      	lw   	r3,-8[bp]
	      	lb   	r4,1645[r3]
	      	xori 	r4,r4,#32
	      	sb   	r4,1645[r3]
	      	bra  	keybd_33
keybd_40:
	      	lw   	r3,-8[bp]
	      	lb   	r4,1645[r3]
	      	xori 	r4,r4,#64
	      	sb   	r4,1645[r3]
	      	bra  	keybd_33
keybd_41:
	      	lb   	r3,1644[r11]
	      	blt  	r3,keybd_47
	      	lb   	r3,1645[r11]
	      	ori  	r3,r3,#2
	      	sb   	r3,1645[r11]
	      	bra  	keybd_48
keybd_47:
	      	lb   	r3,1645[r11]
	      	andi 	r3,r3,#-3
	      	sb   	r3,1645[r11]
keybd_48:
	      	sb   	r0,1644[r11]
	      	bra  	keybd_33
keybd_42:
	      	cmp  	r3,r12,#13
	      	bne  	r3,keybd_49
	      	lb   	r4,1645[r11]
	      	and  	r3,r4,#2
	      	beq  	r3,keybd_49
	      	lb   	r3,1644[r11]
	      	bne  	r3,keybd_49
	      	inc  	iof_switch_,#1
	      	bra  	keybd_33
keybd_49:
	      	lb   	r3,1644[r11]
	      	beq  	r3,keybd_51
	      	sb   	r0,1644[r11]
	      	bra  	keybd_33
keybd_51:
	      	lb   	r4,1645[r11]
	      	sxb  	r4,r4
	      	and  	r3,r4,#128
	      	beq  	r3,keybd_53
	      	lbu  	r3,keybdExtendedCodes_[r12]
	      	sxb  	r3,r3
	      	sc   	r3,-12[bp]
	      	sb   	r0,1644[r11]
	      	lb   	r3,1645[r11]
	      	andi 	r3,r3,#127
	      	sb   	r3,1645[r11]
	      	lcu  	r3,-12[bp]
	      	mov  	r1,r3
	      	bra  	keybd_32
keybd_53:
	      	lb   	r4,1645[r11]
	      	and  	r3,r4,#4
	      	beq  	r3,keybd_55
	      	lbu  	r3,keybdControlCodes_[r12]
	      	sxb  	r3,r3
	      	sc   	r3,-12[bp]
	      	lb   	r3,1645[r11]
	      	andi 	r3,r3,#251
	      	sb   	r3,1645[r11]
	      	lb   	r3,1645[r11]
	      	sxb  	r3,r3
	      	lcu  	r3,-12[bp]
	      	mov  	r1,r3
	      	bra  	keybd_32
keybd_55:
	      	lb   	r4,1645[r11]
	      	and  	r3,r4,#1
	      	beq  	r3,keybd_57
	      	lbu  	r3,shiftedScanCodes_[r12]
	      	sxb  	r3,r3
	      	sc   	r3,-12[bp]
	      	lb   	r3,1645[r11]
	      	andi 	r3,r3,#254
	      	sb   	r3,1645[r11]
	      	lb   	r3,1645[r11]
	      	sxb  	r3,r3
	      	lcu  	r3,-12[bp]
	      	mov  	r1,r3
	      	bra  	keybd_32
keybd_57:
	      	lbu  	r3,unshiftedScanCodes_[r12]
	      	sxb  	r3,r3
	      	sc   	r3,-12[bp]
	      	lcu  	r3,-12[bp]
	      	mov  	r1,r3
	      	bra  	keybd_32
keybd_58:
keybd_56:
keybd_54:
keybd_52:
keybd_50:
keybd_33:
	      	bra  	keybd_26
keybd_27:
	      	bra  	keybd_32
keybd_25:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	keybd_32
public code KeybdGetBufferedCharWait_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#keybd_59
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	ldi  	r3,#1
	      	sb   	r3,1646[r11]
	      	bsr  	KeybdGetBufferedChar_
	      	mov  	r3,r1
	      	mov  	r1,r3
keybd_60:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
keybd_59:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	keybd_60
endpublic

public code KeybdGetBufferedCharNoWait_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#keybd_61
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	sb   	r0,1646[r11]
	      	bsr  	KeybdGetBufferedChar_
	      	mov  	r3,r1
	      	mov  	r1,r3
keybd_62:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
keybd_61:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	keybd_62
endpublic

	rodata
	align	16
	align	8
	extern	jcbs_
	extern	tcbs_
	extern	nMsgBlk_
	extern	IOFocusTbl_
;	global	outb_
;	global	outc_
;	global	outh_
	extern	irq_stack_
	extern	IOFocusNdx_
	extern	DumpTaskList_
;	global	outw_
	extern	fmtk_irq_stack_
	extern	GetRunningTCB_
;	global	KeybdIRQ_
	extern	keybdControlCodes_
	extern	fmtk_sys_stack_
	extern	message_
;	global	SetRunningTCB_
	extern	mailbox_
;	global	KeybdGetBufferStatus_
	extern	FMTK_Inited_
	extern	KeybdClearRcv_
	extern	missed_ticks_
;	global	KeybdGetBufferedCharNoWait_
;	global	chkTCB_
	extern	GetRunningTCBPtr_
;	global	UnlockSemaphore_
	extern	GetVecno_
	extern	GetJCBPtr_
	extern	video_bufs_
	extern	getCPU_
	extern	hasUltraHighPriorityTasks_
;	global	LockSemaphore_
	extern	keybdExtendedCodes_
	extern	iof_switch_
;	global	keybd_irq_stack_
	extern	KeybdGetScancode_
	extern	nMailbox_
	extern	unshiftedScanCodes_
;	global	set_vector_
	extern	iof_sema_
;	global	KeybdGetBufferedCharWait_
	extern	sys_stacks_
	extern	BIOS_RespMbx_
;	global	KeybdGetBufferedScancode_
	extern	shiftedScanCodes_
	extern	BIOS1_sema_
	extern	sys_sema_
	extern	readyQ_
	extern	sysstack_
	extern	freeTCB_
	extern	TimeoutList_
;	global	RemoveFromTimeoutList_
	extern	stacks_
	extern	freeMSG_
	extern	freeMBX_
;	global	SetBound50_
;	global	SetBound51_
;	global	SetBound48_
;	global	SetBound49_
;	global	InsertIntoTimeoutList_
;	global	RemoveFromReadyList_
	extern	KeybdGetStatus_
	extern	bios_stacks_
;	global	InsertIntoReadyList_
