	data
	align	8
	fill.b	1,0x00
	align	8
	fill.b	16,0x00
	align	8
	fill.b	1984,0x00
	align	8
	align	8
	code
	align	16
public code ForceIOFocus_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_0
	      	mov  	bp,sp
	      	push 	r11
	      	push 	24[bp]
	      	bsr  	RequestIOFocus_
	      	addui	sp,sp,#8
	      	push 	#-1
	      	pea  	iof_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,IOFocusc_2
	      	lw   	r3,IOFocusNdx_[gp]
	      	cmp  	r4,r11,r3
	      	beq  	r4,IOFocusc_4
	      	bsr  	CopyScreenToVirtualScreen_
	      	lw   	r3,1624[r11]
	      	sw   	r3,1616[r11]
	      	sw   	r11,IOFocusNdx_[gp]
	      	ldi  	r3,#4291821568
	      	sw   	r3,1616[r11]
	      	bsr  	CopyVirtualScreenToScreen_
IOFocusc_4:
	      	pea  	iof_sema_[gp]
	      	bsr  	UnlockSemaphore_
IOFocusc_2:
IOFocusc_6:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_0:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_6
endpublic

public code SwitchIOFocus_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_7
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	lea  	r3,IOFocusNdx_[gp]
	      	mov  	r12,r3
	      	push 	#-1
	      	pea  	iof_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,IOFocusc_9
	      	lw   	r11,[r12]
	      	beq  	r11,IOFocusc_11
	      	lw   	r3,[r12]
	      	lw   	r4,[r3]
	      	sw   	r4,-16[bp]
	      	lw   	r3,-16[bp]
	      	lw   	r4,[r12]
	      	cmp  	r5,r3,r4
	      	beq  	r5,IOFocusc_13
	      	lw   	r3,-16[bp]
	      	beq  	r3,IOFocusc_15
	      	bsr  	CopyScreenToVirtualScreen_
	      	lw   	r3,1624[r11]
	      	sw   	r3,1616[r11]
	      	lw   	r3,-16[bp]
	      	sw   	r3,[r12]
	      	lw   	r3,-16[bp]
	      	ldi  	r4,#4291821568
	      	sw   	r4,1616[r3]
	      	bsr  	CopyVirtualScreenToScreen_
IOFocusc_15:
IOFocusc_13:
IOFocusc_11:
	      	pea  	iof_sema_[gp]
	      	bsr  	UnlockSemaphore_
IOFocusc_9:
IOFocusc_17:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_7:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_17
endpublic

public code RequestIOFocus_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_18
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	lea  	r3,IOFocusNdx_[gp]
	      	mov  	r12,r3
	      	lb   	r3,1681[r11]
	      	sxb  	r3,r3
	      	sw   	r3,-8[bp]
	      	push 	#-1
	      	pea  	iof_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,IOFocusc_20
	      	lw   	r5,IOFocusTbl_[gp]
	      	lw   	r6,-8[bp]
	      	asr  	r4,r5,r6
	      	and  	r3,r4,#1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	bne  	r3,IOFocusc_22
	      	lw   	r3,[r12]
	      	bne  	r3,IOFocusc_24
	      	sw   	r11,[r12]
	      	sw   	r11,[r11]
	      	sw   	r11,8[r11]
	      	bra  	IOFocusc_25
IOFocusc_24:
	      	lw   	r3,[r12]
	      	lw   	r4,8[r3]
	      	sw   	r4,8[r11]
	      	lw   	r3,[r12]
	      	sw   	r3,[r11]
	      	lw   	r3,[r12]
	      	lw   	r3,8[r3]
	      	sw   	r11,[r3]
	      	lw   	r3,[r12]
	      	sw   	r11,8[r3]
IOFocusc_25:
	      	ldi  	r4,#1
	      	lw   	r5,-8[bp]
	      	asl  	r3,r4,r5
	      	lw   	r4,IOFocusTbl_[gp]
	      	or   	r4,r4,r3
	      	sw   	r4,IOFocusTbl_[gp]
IOFocusc_22:
	      	pea  	iof_sema_[gp]
	      	bsr  	UnlockSemaphore_
IOFocusc_20:
IOFocusc_26:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_18:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_26
endpublic

public code ReleaseIOFocus_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_27
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	ForceReleaseIOFocus_
	      	addui	sp,sp,#8
IOFocusc_29:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_27:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_29
endpublic

public code ForceReleaseIOFocus_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_30
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	24[bp]
	      	pea  	iof_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,IOFocusc_32
	      	lw   	r4,IOFocusTbl_[gp]
	      	ldi  	r6,#1
	      	lb   	r7,1681[r11]
	      	sxb  	r7,r7
	      	asl  	r5,r6,r7
	      	and  	r3,r4,r5
	      	beq  	r3,IOFocusc_34
	      	ldi  	r5,#1
	      	lb   	r6,1681[r11]
	      	sxb  	r6,r6
	      	asl  	r4,r5,r6
	      	com  	r3,r4
	      	lw   	r4,IOFocusTbl_[gp]
	      	and  	r4,r4,r3
	      	sw   	r4,IOFocusTbl_[gp]
	      	lw   	r3,IOFocusNdx_[gp]
	      	cmp  	r4,r11,r3
	      	bne  	r4,IOFocusc_36
	      	bsr  	SwitchIOFocus_
IOFocusc_36:
	      	lw   	r3,[r11]
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	beq  	r3,IOFocusc_38
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,r11
	      	beq  	r4,IOFocusc_40
	      	lw   	r3,-8[bp]
	      	lw   	r4,8[r11]
	      	sw   	r4,8[r3]
	      	lw   	r3,8[r11]
	      	lw   	r4,-8[bp]
	      	sw   	r4,[r3]
	      	bra  	IOFocusc_41
IOFocusc_40:
	      	ldi  	r3,#0
	      	sw   	r3,IOFocusNdx_[gp]
IOFocusc_41:
	      	ldi  	r3,#0
	      	sw   	r3,[r11]
	      	ldi  	r3,#0
	      	sw   	r3,8[r11]
IOFocusc_38:
IOFocusc_34:
	      	pea  	iof_sema_[gp]
	      	bsr  	UnlockSemaphore_
IOFocusc_32:
IOFocusc_42:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_30:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_42
endpublic

public code CopyVirtualScreenToScreen_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_43
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lw   	r11,IOFocusNdx_[gp]
	      	lw   	r13,1616[r11]
	      	lw   	r12,1624[r11]
	      	lc   	r4,1632[r11]
	      	lc   	r5,1634[r11]
	      	mulu 	r3,r4,r5
	      	sxc  	r3,r3
	      	sw   	r3,-32[bp]
IOFocusc_45:
	      	lw   	r3,-32[bp]
	      	blt  	r3,IOFocusc_46
	      	lw   	r4,-32[bp]
	      	asli 	r3,r4,#2
	      	lw   	r5,-32[bp]
	      	asli 	r4,r5,#2
	      	lh   	r5,0[r12+r4]
	      	sh   	r5,0[r13+r3]
IOFocusc_47:
	      	dec  	-32[bp],#1
	      	bra  	IOFocusc_45
IOFocusc_46:
	      	lc   	r5,1636[r11]
	      	lc   	r6,1634[r11]
	      	mulu 	r4,r5,r6
	      	lc   	r5,1638[r11]
	      	addu 	r3,r4,r5
	      	sxc  	r3,r3
	      	sw   	r3,-40[bp]
	      	push 	-40[bp]
	      	push 	#11
	      	bsr  	SetVideoReg_
	      	addui	sp,sp,#16
IOFocusc_48:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_43:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_48
endpublic

public code CopyScreenToVirtualScreen_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lw   	r11,IOFocusNdx_[gp]
	      	lw   	r13,1616[r11]
	      	lw   	r12,1624[r11]
	      	lc   	r4,1632[r11]
	      	lc   	r5,1634[r11]
	      	mulu 	r3,r4,r5
	      	sxc  	r3,r3
	      	sw   	r3,-32[bp]
IOFocusc_51:
	      	lw   	r3,-32[bp]
	      	blt  	r3,IOFocusc_52
	      	lw   	r4,-32[bp]
	      	asli 	r3,r4,#2
	      	lw   	r5,-32[bp]
	      	asli 	r4,r5,#2
	      	lh   	r5,0[r13+r4]
	      	sh   	r5,0[r12+r3]
IOFocusc_53:
	      	dec  	-32[bp],#1
	      	bra  	IOFocusc_51
IOFocusc_52:
IOFocusc_54:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

	rodata
	align	16
	align	8
;	global	outb_
	extern	IOFocusTbl_
;	global	outc_
;	global	outh_
	extern	IOFocusNdx_
	extern	DumpTaskList_
;	global	outw_
	extern	GetRunningTCB_
;	global	SetRunningTCB_
;	global	CopyScreenToVirtualScreen_
;	global	CopyVirtualScreenToScreen_
;	global	SwitchIOFocus_
;	global	chkTCB_
	extern	GetRunningTCBPtr_
;	global	UnlockSemaphore_
	extern	GetVecno_
	extern	GetJCBPtr_
	extern	getCPU_
;	global	LockSemaphore_
;	global	set_vector_
	extern	SetVideoReg_
	extern	iof_sema_
;	global	ForceReleaseIOFocus_
;	global	ReleaseIOFocus_
;	global	RequestIOFocus_
;	global	RemoveFromTimeoutList_
;	global	ForceIOFocus_
;	global	SetBound50_
;	global	SetBound51_
;	global	SetBound48_
;	global	SetBound49_
;	global	InsertIntoTimeoutList_
;	global	RemoveFromReadyList_
;	global	InsertIntoReadyList_
