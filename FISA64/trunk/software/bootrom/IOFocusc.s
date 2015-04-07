	code
	align	16
public code ForceIOFocus:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_74
	      	mov  	bp,sp
	      	push 	r11
	      	push 	24[bp]
	      	bsr  	RequestIOFocus
	      	addui	sp,sp,#8
	      	bsr  	LockIOF
	      	lw   	r3,IOFocusNdx
	      	cmp  	r11,r11,r3
	      	beq  	r11,IOFocusc_75
	      	bsr  	CopyScreenToVirtualScreen
	      	lw   	r3,1624[r11]
	      	sw   	r3,1616[r11]
	      	sw   	r11,IOFocusNdx
	      	ldi  	r3,#4291821568
	      	sw   	r3,1616[r11]
	      	bsr  	CopyVirtualScreenToScreen
IOFocusc_75:
	      	bsr  	UnlockIOF
IOFocusc_77:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_74:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_77
endpublic

public code SwitchIOFocus:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_78
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	ldi  	r12,#IOFocusNdx
	      	bsr  	LockIOF
	      	lw   	r11,[r12]
	      	beq  	r11,IOFocusc_79
	      	lw   	r3,[r12]
	      	lw   	r4,[r3]
	      	sw   	r4,-16[bp]
	      	lw   	r3,-16[bp]
	      	lw   	r4,[r12]
	      	cmp  	r3,r3,r4
	      	beq  	r3,IOFocusc_81
	      	lw   	r3,-16[bp]
	      	beq  	r3,IOFocusc_83
	      	bsr  	CopyScreenToVirtualScreen
	      	lw   	r3,1624[r11]
	      	sw   	r3,1616[r11]
	      	lw   	r3,-16[bp]
	      	sw   	r3,[r12]
	      	lw   	r3,-16[bp]
	      	ldi  	r4,#4291821568
	      	sw   	r4,1616[r3]
	      	bsr  	CopyVirtualScreenToScreen
IOFocusc_83:
IOFocusc_81:
IOFocusc_79:
	      	bsr  	UnlockIOF
IOFocusc_85:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_78:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_85
endpublic

public code RequestIOFocus:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_86
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
	      	bne  	r3,IOFocusc_87
	      	lw   	r3,[r12]
	      	bne  	r3,IOFocusc_89
	      	sw   	r11,[r12]
	      	sw   	r11,[r11]
	      	sw   	r11,8[r11]
	      	bra  	IOFocusc_90
IOFocusc_89:
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
IOFocusc_90:
	      	ldi  	r3,#1
	      	lw   	r4,-8[bp]
	      	asl  	r3,r3,r4
	      	lw   	r4,IOFocusTbl
	      	or   	r4,r4,r3
	      	sw   	r4,IOFocusTbl
IOFocusc_87:
	      	bsr  	UnlockIOF
IOFocusc_91:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_86:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_91
endpublic

public code ReleaseIOFocus:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_92
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	ForceReleaseIOFocus
	      	addui	sp,sp,#8
IOFocusc_93:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_92:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_93
endpublic

public code ForceReleaseIOFocus:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_94
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
	      	beq  	r3,IOFocusc_95
	      	ldi  	r3,#1
	      	lc   	r4,1678[r11]
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,IOFocusTbl
	      	and  	r4,r4,r3
	      	sw   	r4,IOFocusTbl
	      	lw   	r3,IOFocusNdx
	      	cmp  	r11,r11,r3
	      	bne  	r11,IOFocusc_97
	      	bsr  	SwitchIOFocus
IOFocusc_97:
	      	lw   	r3,[r11]
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	beq  	r3,IOFocusc_99
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,r11
	      	beq  	r3,IOFocusc_101
	      	lw   	r3,-8[bp]
	      	lw   	r4,8[r11]
	      	sw   	r4,8[r3]
	      	lw   	r3,8[r11]
	      	lw   	r4,-8[bp]
	      	sw   	r4,[r3]
	      	bra  	IOFocusc_102
IOFocusc_101:
	      	sw   	r0,IOFocusNdx
IOFocusc_102:
	      	sw   	r0,[r11]
	      	sw   	r0,8[r11]
IOFocusc_99:
IOFocusc_95:
	      	bsr  	UnlockIOF
IOFocusc_103:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_94:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_103
endpublic

public code CopyVirtualScreenToScreen:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#IOFocusc_104
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
IOFocusc_105:
	      	lw   	r3,-32[bp]
	      	blt  	r3,IOFocusc_106
	      	lw   	r3,-32[bp]
	      	asli 	r3,r3,#2
	      	lw   	r4,-32[bp]
	      	asli 	r4,r4,#2
	      	lh   	r5,0[r12+r3]
	      	sh   	r5,0[r13+r4]
IOFocusc_107:
	      	dec  	-32[bp],#1
	      	bra  	IOFocusc_105
IOFocusc_106:
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
IOFocusc_108:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
IOFocusc_104:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	IOFocusc_108
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
IOFocusc_110:
	      	lw   	r3,-32[bp]
	      	blt  	r3,IOFocusc_111
	      	lw   	r3,-32[bp]
	      	asli 	r3,r3,#2
	      	lw   	r4,-32[bp]
	      	asli 	r4,r4,#2
	      	lh   	r5,0[r13+r3]
	      	sh   	r5,0[r12+r4]
IOFocusc_112:
	      	dec  	-32[bp],#1
	      	bra  	IOFocusc_110
IOFocusc_111:
IOFocusc_113:
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
	extern	SetVideoReg
;	global	ForceReleaseIOFocus
	extern	UnlockIOF
;	global	ReleaseIOFocus
	extern	LockIOF
;	global	RequestIOFocus
;	global	ForceIOFocus
	extern	IOFocusTbl
	extern	IOFocusNdx
