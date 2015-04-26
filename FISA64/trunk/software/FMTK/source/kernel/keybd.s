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
public data kbd_sema_:
	dw	0
endpublic

	bss
	align	8
public bss keybd_irq_stack_:
	fill.b	2048,0x00

endpublic
	code
	align	16
	data
	align	8
	align	8
	code
	align	16
public code KeybdIRQ_:
	      	     	         lea   sp,keybd_irq_stack_+2040
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
	      	subui	sp,sp,#32
	      	push 	r11
	      	push 	r12
keybd_2:
	      	bsr  	KeybdGetStatus_
	      	mov  	r3,r1
	      	bge  	r3,keybd_3
	      	bsr  	KeybdGetScancode_
	      	mov  	r3,r1
	      	sxb  	r3,r3
	      	sb   	r3,-1[bp]
	      	lw   	r11,IOFocusNdx_[gp]
	      	beq  	r11,keybd_4
	      	push 	#200
	      	pea  	kbd_sema_[gp]
	      	bsr  	ILockSemaphore_
	      	addui	sp,sp,#16
	      	mov  	r3,r1
	      	beq  	r3,keybd_6
	      	bsr  	KeybdClearRcv_
	      	lb   	r3,1647[r11]
	      	sb   	r3,-2[bp]
	      	lb   	r3,1648[r11]
	      	sb   	r3,-3[bp]
	      	lb   	r3,-2[bp]
	      	addui	r3,r3,#1
	      	sb   	r3,-2[bp]
	      	lb   	r3,-2[bp]
	      	andi 	r3,r3,#31
	      	sb   	r3,-2[bp]
	      	lb   	r3,-2[bp]
	      	lb   	r4,-3[bp]
	      	cmp  	r5,r3,r4
	      	beq  	r5,keybd_8
	      	lb   	r3,-2[bp]
	      	sb   	r3,1647[r11]
	      	lb   	r4,-2[bp]
	      	sxb  	r4,r4
	      	addu 	r3,r4,r11
	      	lb   	r4,-1[bp]
	      	andi 	r4,r4,#255
	      	sb   	r4,1649[r3]
keybd_8:
	      	pea  	kbd_sema_[gp]
	      	bsr  	UnlockSemaphore_
keybd_6:
	      	lb   	r4,1645[r11]
	      	and  	r3,r4,#4
	      	beq  	r3,keybd_10
	      	lb   	r3,-1[bp]
	      	cmp  	r4,r3,#33
	      	bne  	r4,keybd_12
	      	sw   	r0,-32[bp]
keybd_14:
	      	lw   	r3,-32[bp]
	      	cmp  	r4,r3,#8
	      	bge  	r4,keybd_15
	      	lw   	r4,-32[bp]
	      	asli 	r3,r4,#1
	      	addu 	r4,r11,#1682
	      	lc   	r3,0[r4+r3]
	      	cmp  	r4,r3,#-1
	      	bne  	r4,keybd_17
	      	bra  	keybd_15
keybd_17:
	      	lw   	r7,-32[bp]
	      	asli 	r6,r7,#1
	      	addu 	r5,r6,r11
	      	lc   	r5,1682[r5]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r12,r3
	      	ldi  	r3,#515
	      	sw   	r3,744[r12]
keybd_16:
	      	inc  	-32[bp],#1
	      	bra  	keybd_14
keybd_15:
	      	bra  	keybd_13
keybd_12:
	      	lb   	r3,-1[bp]
	      	cmp  	r4,r3,#44
	      	beq  	r4,keybd_21
	      	lb   	r3,-1[bp]
	      	cmp  	r4,r3,#26
	      	bne  	r4,keybd_19
keybd_21:
	      	ldi  	r4,#2048
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r12,r3
	      	ldi  	r5,#512
	      	lb   	r6,-1[bp]
	      	cmp  	r7,r6,#44
	      	bne  	r7,keybd_22
	      	ldi  	r6,#20
	      	bra  	keybd_23
keybd_22:
	      	ldi  	r7,#26
	      	mov  	r6,r7
keybd_23:
	      	addu 	r4,r5,r6
	      	push 	r3
	      	push 	r4
	      	push 	r5
	      	bsr  	GetRunningTCB_
	      	pop  	r5
	      	pop  	r4
	      	pop  	r3
	      	mov  	r6,r1
	      	asli 	r5,r6,#32
	      	or   	r3,r4,r5
	      	sw   	r3,744[r12]
keybd_19:
keybd_13:
keybd_10:
	      	lb   	r4,1645[r11]
	      	and  	r3,r4,#2
	      	beq  	r3,keybd_24
	      	lb   	r3,-1[bp]
	      	cmp  	r4,r3,#13
	      	bne  	r4,keybd_24
	      	inc  	iof_switch_[gp],#1
keybd_24:
keybd_4:
	      	bra  	keybd_2
keybd_3:
keybd_26:
	      	pop  	r12
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
	      	bra  	keybd_26
endpublic

public code KeybdGetBufferStatus_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#keybd_27
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	sb   	r0,-10[bp]
	      	lb   	r3,-10[bp]
	      	sb   	r3,-9[bp]
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	push 	#200
	      	pea  	kbd_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,keybd_29
	      	lb   	r3,1647[r11]
	      	sb   	r3,-9[bp]
	      	lb   	r3,1648[r11]
	      	sb   	r3,-10[bp]
	      	pea  	kbd_sema_[gp]
	      	bsr  	UnlockSemaphore_
keybd_29:
	      	lb   	r3,-9[bp]
	      	lb   	r4,-10[bp]
	      	cmp  	r5,r3,r4
	      	beq  	r5,keybd_31
	      	ldi  	r1,#-1
keybd_33:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
keybd_31:
	      	ldi  	r1,#0
	      	bra  	keybd_33
keybd_27:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	keybd_33
endpublic

public code KeybdGetBufferedScancode_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#keybd_34
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	sb   	r0,-11[bp]
	      	push 	#200
	      	pea  	kbd_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,keybd_36
	      	lb   	r3,1647[r11]
	      	sb   	r3,-9[bp]
	      	lb   	r3,1648[r11]
	      	sb   	r3,-10[bp]
	      	lb   	r3,-9[bp]
	      	lb   	r4,-10[bp]
	      	cmp  	r5,r3,r4
	      	beq  	r5,keybd_38
	      	lb   	r3,-10[bp]
	      	sxb  	r3,r3
	      	addu 	r4,r11,#1649
	      	lb   	r3,0[r4+r3]
	      	sxb  	r3,r3
	      	sb   	r3,-11[bp]
	      	lb   	r3,-10[bp]
	      	addui	r3,r3,#1
	      	sb   	r3,-10[bp]
	      	lb   	r3,-10[bp]
	      	andi 	r3,r3,#31
	      	sb   	r3,-10[bp]
	      	lb   	r3,-10[bp]
	      	sb   	r3,1648[r11]
keybd_38:
	      	pea  	kbd_sema_[gp]
	      	bsr  	UnlockSemaphore_
keybd_36:
	      	lb   	r3,-11[bp]
	      	sxb  	r3,r3
	      	mov  	r1,r3
keybd_40:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
keybd_34:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	keybd_40
endpublic

	data
	align	8
	code
	align	16
KeybdGetBufferedChar_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#keybd_42
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
keybd_44:
keybd_46:
	      	bsr  	KeybdGetBufferStatus_
	      	mov  	r3,r1
	      	blt  	r3,keybd_47
	      	lb   	r3,1646[r11]
	      	bne  	r3,keybd_48
	      	ldi  	r1,#-1
keybd_50:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
keybd_48:
	      	bra  	keybd_46
keybd_47:
	      	bsr  	KeybdGetBufferedScancode_
	      	mov  	r3,r1
	      	andi 	r3,r3,#255
	      	andi 	r3,r3,#255
	      	mov  	r12,r3
	      	cmp  	r3,r12,#240
	      	beq  	r3,keybd_52
	      	cmp  	r3,r12,#224
	      	beq  	r3,keybd_53
	      	cmp  	r3,r12,#20
	      	beq  	r3,keybd_54
	      	cmp  	r3,r12,#89
	      	beq  	r3,keybd_55
	      	cmp  	r3,r12,#119
	      	beq  	r3,keybd_56
	      	cmp  	r3,r12,#88
	      	beq  	r3,keybd_57
	      	cmp  	r3,r12,#126
	      	beq  	r3,keybd_58
	      	cmp  	r3,r12,#17
	      	beq  	r3,keybd_59
	      	bra  	keybd_60
keybd_52:
	      	ldi  	r3,#-1
	      	sb   	r3,1644[r11]
	      	bra  	keybd_51
keybd_53:
	      	lb   	r3,1645[r11]
	      	ori  	r3,r3,#128
	      	sb   	r3,1645[r11]
	      	lb   	r3,1645[r11]
	      	sxb  	r3,r3
	      	bra  	keybd_51
keybd_54:
	      	lb   	r3,1644[r11]
	      	blt  	r3,keybd_61
	      	lb   	r3,1645[r11]
	      	ori  	r3,r3,#4
	      	sb   	r3,1645[r11]
	      	bra  	keybd_62
keybd_61:
	      	lb   	r3,1645[r11]
	      	andi 	r3,r3,#-5
	      	sb   	r3,1645[r11]
keybd_62:
	      	sb   	r0,1644[r11]
	      	bra  	keybd_51
keybd_55:
	      	lb   	r3,1644[r11]
	      	blt  	r3,keybd_63
	      	lb   	r3,1645[r11]
	      	ori  	r3,r3,#1
	      	sb   	r3,1645[r11]
	      	bra  	keybd_64
keybd_63:
	      	lb   	r3,1645[r11]
	      	andi 	r3,r3,#-2
	      	sb   	r3,1645[r11]
keybd_64:
	      	sb   	r0,1644[r11]
	      	bra  	keybd_51
keybd_56:
	      	lb   	r3,1645[r11]
	      	xori 	r3,r3,#16
	      	sb   	r3,1645[r11]
	      	bra  	keybd_51
keybd_57:
	      	lb   	r3,1645[r11]
	      	xori 	r3,r3,#32
	      	sb   	r3,1645[r11]
	      	bra  	keybd_51
keybd_58:
	      	lb   	r3,1645[r11]
	      	xori 	r3,r3,#64
	      	sb   	r3,1645[r11]
	      	bra  	keybd_51
keybd_59:
	      	lb   	r3,1644[r11]
	      	blt  	r3,keybd_65
	      	lb   	r3,1645[r11]
	      	ori  	r3,r3,#2
	      	sb   	r3,1645[r11]
	      	bra  	keybd_66
keybd_65:
	      	lb   	r3,1645[r11]
	      	andi 	r3,r3,#-3
	      	sb   	r3,1645[r11]
keybd_66:
	      	sb   	r0,1644[r11]
	      	bra  	keybd_51
keybd_60:
	      	cmp  	r3,r12,#13
	      	bne  	r3,keybd_67
	      	lb   	r4,1645[r11]
	      	and  	r3,r4,#2
	      	beq  	r3,keybd_67
	      	lb   	r3,1644[r11]
	      	bne  	r3,keybd_67
	      	inc  	iof_switch_[gp],#1
	      	bra  	keybd_68
keybd_67:
	      	lb   	r3,1644[r11]
	      	beq  	r3,keybd_69
	      	sb   	r0,1644[r11]
	      	bra  	keybd_70
keybd_69:
	      	lb   	r4,1645[r11]
	      	sxb  	r4,r4
	      	and  	r3,r4,#128
	      	beq  	r3,keybd_71
	      	lea  	r3,keybdExtendedCodes_[gp]
	      	lb   	r3,0[r3+r12]
	      	sxb  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-12[bp]
	      	sb   	r0,1644[r11]
	      	lc   	r3,-12[bp]
	      	mov  	r1,r3
	      	bra  	keybd_50
keybd_71:
	      	lb   	r4,1645[r11]
	      	and  	r3,r4,#4
	      	beq  	r3,keybd_73
	      	lea  	r3,keybdControlCodes_[gp]
	      	lb   	r3,0[r3+r12]
	      	sxb  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-12[bp]
	      	lc   	r3,-12[bp]
	      	mov  	r1,r3
	      	bra  	keybd_50
keybd_73:
	      	lb   	r4,1645[r11]
	      	and  	r3,r4,#1
	      	beq  	r3,keybd_75
	      	lea  	r3,shiftedScanCodes_[gp]
	      	lb   	r3,0[r3+r12]
	      	sxb  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-12[bp]
	      	lc   	r3,-12[bp]
	      	mov  	r1,r3
	      	bra  	keybd_50
keybd_75:
	      	lea  	r3,unshiftedScanCodes_[gp]
	      	lb   	r3,0[r3+r12]
	      	sxb  	r3,r3
	      	andi 	r3,r3,#65535
	      	sc   	r3,-12[bp]
	      	lc   	r3,-12[bp]
	      	mov  	r1,r3
	      	bra  	keybd_50
keybd_76:
keybd_74:
keybd_72:
keybd_70:
keybd_68:
keybd_51:
	      	bra  	keybd_44
keybd_45:
	      	bra  	keybd_50
keybd_42:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	keybd_50
public code KeybdGetBufferedCharWait_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#keybd_77
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
keybd_79:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
keybd_77:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	keybd_79
endpublic

public code KeybdGetBufferedCharNoWait_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#keybd_80
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
keybd_82:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
keybd_80:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	keybd_82
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
	extern	KeybdGetScancode_
;	global	keybd_irq_stack_
	extern	kbd_sema_
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
	extern	ILockSemaphore_
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
