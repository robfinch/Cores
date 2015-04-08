	code
	align	16
public code ForceIOFocus:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_0
	      	mov  	bp,sp
	      	push 	r11
	      	push 	24[bp]
	      	bsr  	RequestIOFocus
	      	addui	sp,sp,#8
	      	bsr  	LockIOF
	      	lw   	r3,IOFocusNdx
	      	cmp  	r11,r11,r3
	      	beq  	r11,IOFocusc_1
	      	bsr  	CopyScreenToVirtualScreen
	      	lw   	r3,1624[r11]
	      	sw   	r3,1616[r11]
	      	sw   	r11,IOFocusNdx
	      	ldi  	r3,#4291821568
	      	sw   	r3,1616[r11]
	      	bsr  	CopyVirtualScreenToScreen
IOFocusc_1:
	      	bsr  	UnlockIOF
IOFocusc_3:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_0:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_3
endpublic

public code SwitchIOFocus:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_4
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	ldi  	r12,#IOFocusNdx
	      	bsr  	LockIOF
	      	lw   	r11,[r12]
	      	beq  	r11,IOFocusc_5
	      	lw   	r3,[r12]
	      	lw   	r4,[r3]
	      	sw   	r4,-16[bp]
	      	lw   	r3,-16[bp]
	      	lw   	r4,[r12]
	      	cmp  	r3,r3,r4
	      	beq  	r3,IOFocusc_7
	      	lw   	r3,-16[bp]
	      	beq  	r3,IOFocusc_9
	      	bsr  	CopyScreenToVirtualScreen
	      	lw   	r3,1624[r11]
	      	sw   	r3,1616[r11]
	      	lw   	r3,-16[bp]
	      	sw   	r3,[r12]
	      	lw   	r3,-16[bp]
	      	ldi  	r4,#4291821568
	      	sw   	r4,1616[r3]
	      	bsr  	CopyVirtualScreenToScreen
IOFocusc_9:
IOFocusc_7:
IOFocusc_5:
	      	bsr  	UnlockIOF
IOFocusc_11:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_4:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_11
endpublic

public code RequestIOFocus:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_12
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	ldi  	r12,#IOFocusNdx
	      	lc   	r3,1678[r11]
	      	sw   	r3,-8[bp]
	      	bsr  	LockIOF
	      	lw   	r3,IOFocusTbl
	      	lw   	r4,-8[bp]
	      	asr  	r3,r3,r4
	      	and  	r3,r3,#1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	bne  	r3,IOFocusc_13
	      	lw   	r3,[r12]
	      	bne  	r3,IOFocusc_15
	      	sw   	r11,[r12]
	      	sw   	r11,[r11]
	      	sw   	r11,8[r11]
	      	bra  	IOFocusc_16
IOFocusc_15:
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
IOFocusc_16:
	      	ldi  	r3,#1
	      	lw   	r4,-8[bp]
	      	asl  	r3,r3,r4
	      	lw   	r4,IOFocusTbl
	      	or   	r4,r4,r3
	      	sw   	r4,IOFocusTbl
IOFocusc_13:
	      	bsr  	UnlockIOF
IOFocusc_17:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_12:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_17
endpublic

public code ReleaseIOFocus:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_18
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	ForceReleaseIOFocus
	      	addui	sp,sp,#8
IOFocusc_19:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_18:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_19
endpublic

public code ForceReleaseIOFocus:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_20
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	lw   	r11,24[bp]
	      	bsr  	LockIOF
	      	lw   	r3,IOFocusTbl
	      	ldi  	r4,#1
	      	lc   	r5,1678[r11]
	      	asl  	r4,r4,r5
	      	and  	r3,r3,r4
	      	beq  	r3,IOFocusc_21
	      	ldi  	r3,#1
	      	lc   	r4,1678[r11]
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,IOFocusTbl
	      	and  	r4,r4,r3
	      	sw   	r4,IOFocusTbl
	      	lw   	r3,IOFocusNdx
	      	cmp  	r11,r11,r3
	      	bne  	r11,IOFocusc_23
	      	bsr  	SwitchIOFocus
IOFocusc_23:
	      	lw   	r3,[r11]
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	beq  	r3,IOFocusc_25
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,r11
	      	beq  	r3,IOFocusc_27
	      	lw   	r3,-8[bp]
	      	lw   	r4,8[r11]
	      	sw   	r4,8[r3]
	      	lw   	r3,8[r11]
	      	lw   	r4,-8[bp]
	      	sw   	r4,[r3]
	      	bra  	IOFocusc_28
IOFocusc_27:
	      	sw   	r0,IOFocusNdx
IOFocusc_28:
	      	sw   	r0,[r11]
	      	sw   	r0,8[r11]
IOFocusc_25:
IOFocusc_21:
	      	bsr  	UnlockIOF
IOFocusc_29:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_20:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_29
endpublic

public code CopyVirtualScreenToScreen:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_30
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lw   	r11,IOFocusNdx
	      	lw   	r13,1616[r11]
	      	lw   	r12,1624[r11]
	      	lcu  	r3,1632[r11]
	      	lcu  	r4,1634[r11]
	      	mulu 	r3,r3,r4
	      	sxc  	r3,r3
	      	sw   	r3,-32[bp]
IOFocusc_31:
	      	lw   	r3,-32[bp]
	      	blt  	r3,IOFocusc_32
	      	lw   	r3,-32[bp]
	      	asli 	r3,r3,#2
	      	lw   	r4,-32[bp]
	      	asli 	r4,r4,#2
	      	lh   	r5,0[r12+r3]
	      	sh   	r5,0[r13+r4]
IOFocusc_33:
	      	dec  	-32[bp],#1
	      	bra  	IOFocusc_31
IOFocusc_32:
	      	lcu  	r3,1636[r11]
	      	lcu  	r4,1634[r11]
	      	mulu 	r3,r3,r4
	      	lcu  	r4,1638[r11]
	      	addu 	r3,r3,r4
	      	sxc  	r3,r3
	      	sw   	r3,-40[bp]
	      	push 	-40[bp]
	      	push 	#11
	      	bsr  	SetVideoReg
	      	addui	sp,sp,#16
IOFocusc_34:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_30:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_34
endpublic

public code CopyScreenToVirtualScreen:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lw   	r11,IOFocusNdx
	      	lw   	r13,1616[r11]
	      	lw   	r12,1624[r11]
	      	lcu  	r3,1632[r11]
	      	lcu  	r4,1634[r11]
	      	mulu 	r3,r3,r4
	      	sxc  	r3,r3
	      	sw   	r3,-32[bp]
IOFocusc_36:
	      	lw   	r3,-32[bp]
	      	blt  	r3,IOFocusc_37
	      	lw   	r3,-32[bp]
	      	asli 	r3,r3,#2
	      	lw   	r4,-32[bp]
	      	asli 	r4,r4,#2
	      	lh   	r5,0[r13+r3]
	      	sh   	r5,0[r12+r4]
IOFocusc_38:
	      	dec  	-32[bp],#1
	      	bra  	IOFocusc_36
IOFocusc_37:
IOFocusc_39:
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
;	global	CopyScreenToVirtualScreen
;	global	CopyVirtualScreenToScreen
;	global	SwitchIOFocus
	extern	GetJCBPtr
;	global	set_vector
	extern	SetVideoReg
;	global	ForceReleaseIOFocus
	extern	UnlockIOF
;	global	ReleaseIOFocus
	extern	LockIOF
;	global	RequestIOFocus
;	global	ForceIOFocus
	extern	IOFocusTbl
	extern	IOFocusNdx
	extern	GetRunningTCB
