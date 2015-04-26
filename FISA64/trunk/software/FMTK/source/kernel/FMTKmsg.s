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
	data
	align	8
	code
	align	16
QueueMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_1
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lw   	r11,24[bp]
	      	lea  	r3,nMsgBlk_[gp]
	      	mov  	r12,r3
	      	lea  	r3,freeMSG_[gp]
	      	mov  	r13,r3
	      	sw   	r0,-24[bp]
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_3
	      	inc  	32[r11],#1
	      	lc   	r3,12[r11]
	      	cmp  	r4,r3,#0
	      	beq  	r4,FMTKmsg_6
	      	cmp  	r4,r3,#2
	      	beq  	r4,FMTKmsg_7
	      	cmp  	r4,r3,#1
	      	beq  	r4,FMTKmsg_8
	      	bra  	FMTKmsg_5
FMTKmsg_6:
	      	bra  	FMTKmsg_5
FMTKmsg_7:
FMTKmsg_9:
	      	lw   	r3,32[r11]
	      	lw   	r4,24[r11]
	      	cmpu 	r5,r3,r4
	      	ble  	r5,FMTKmsg_10
	      	lc   	r4,8[r11]
	      	asli 	r3,r4,#5
	      	lea  	r4,message_[gp]
	      	lc   	r3,0[r4+r3]
	      	sc   	r3,-10[bp]
	      	lc   	r5,-10[bp]
	      	asli 	r4,r5,#5
	      	lea  	r5,message_[gp]
	      	addu 	r3,r4,r5
	      	sw   	r3,-8[bp]
	      	lc   	r4,8[r11]
	      	asli 	r3,r4,#5
	      	lea  	r4,message_[gp]
	      	lc   	r5,[r13]
	      	andi 	r5,r5,#65535
	      	sc   	r5,0[r4+r3]
	      	lc   	r3,8[r11]
	      	sc   	r3,[r13]
	      	inc  	[r12],#1
	      	dec  	32[r11],#1
	      	lc   	r3,-10[bp]
	      	sc   	r3,8[r11]
	      	lw   	r3,40[r11]
	      	cmpu 	r4,r3,#-1
	      	bge  	r4,FMTKmsg_11
	      	inc  	40[r11],#1
FMTKmsg_11:
	      	ldi  	r3,#6
	      	sw   	r3,-24[bp]
	      	bra  	FMTKmsg_9
FMTKmsg_10:
	      	bra  	FMTKmsg_5
FMTKmsg_8:
	      	lw   	r3,32[r11]
	      	lw   	r4,24[r11]
	      	cmpu 	r5,r3,r4
	      	ble  	r5,FMTKmsg_13
	      	lw   	r3,32[bp]
	      	lc   	r4,[r13]
	      	andi 	r4,r4,#65535
	      	sc   	r4,[r3]
	      	lw   	r5,32[bp]
	      	lea  	r6,message_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#5
	      	sc   	r3,[r13]
	      	inc  	[r12],#1
	      	lw   	r3,40[r11]
	      	cmpu 	r4,r3,#-1
	      	bge  	r4,FMTKmsg_15
	      	inc  	40[r11],#1
FMTKmsg_15:
	      	ldi  	r3,#6
	      	sw   	r3,-24[bp]
	      	dec  	32[r11],#1
FMTKmsg_13:
FMTKmsg_17:
	      	lw   	r3,32[r11]
	      	lw   	r4,24[r11]
	      	cmpu 	r5,r3,r4
	      	ble  	r5,FMTKmsg_18
	      	lc   	r5,8[r11]
	      	asli 	r4,r5,#5
	      	lea  	r5,message_[gp]
	      	addu 	r3,r4,r5
	      	sw   	r3,-8[bp]
FMTKmsg_19:
	      	lw   	r5,-8[bp]
	      	lea  	r6,message_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#5
	      	lc   	r4,10[r11]
	      	andi 	r4,r4,#65535
	      	cmp  	r5,r3,r4
	      	beq  	r5,FMTKmsg_20
	      	lw   	r3,-8[bp]
	      	sw   	r3,32[bp]
	      	lw   	r5,-8[bp]
	      	lc   	r5,[r5]
	      	asli 	r4,r5,#5
	      	lea  	r5,message_[gp]
	      	addu 	r3,r4,r5
	      	sw   	r3,-8[bp]
	      	bra  	FMTKmsg_19
FMTKmsg_20:
	      	lw   	r5,32[bp]
	      	lea  	r6,message_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#5
	      	sc   	r3,10[r11]
	      	lw   	r3,-8[bp]
	      	lc   	r4,[r13]
	      	andi 	r4,r4,#65535
	      	sc   	r4,[r3]
	      	lw   	r5,-8[bp]
	      	lea  	r6,message_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#5
	      	sc   	r3,[r13]
	      	inc  	[r12],#1
	      	lw   	r3,40[r11]
	      	cmpu 	r4,r3,#-1
	      	bge  	r4,FMTKmsg_21
	      	inc  	40[r11],#1
FMTKmsg_21:
	      	dec  	32[r11],#1
	      	ldi  	r3,#6
	      	sw   	r3,-24[bp]
	      	bra  	FMTKmsg_17
FMTKmsg_18:
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#6
	      	bne  	r4,FMTKmsg_23
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
FMTKmsg_25:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#16
FMTKmsg_23:
	      	bra  	FMTKmsg_5
FMTKmsg_5:
	      	lc   	r3,10[r11]
	      	blt  	r3,FMTKmsg_26
	      	lc   	r4,10[r11]
	      	asli 	r3,r4,#5
	      	lea  	r4,message_[gp]
	      	lw   	r7,32[bp]
	      	lea  	r8,message_[gp]
	      	subu 	r6,r7,r8
	      	lsri 	r5,r6,#5
	      	andi 	r5,r5,#65535
	      	sc   	r5,0[r4+r3]
	      	bra  	FMTKmsg_27
FMTKmsg_26:
	      	lw   	r5,32[bp]
	      	lea  	r6,message_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#5
	      	sc   	r3,8[r11]
FMTKmsg_27:
	      	lw   	r5,32[bp]
	      	lea  	r6,message_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#5
	      	sc   	r3,10[r11]
	      	lw   	r3,32[bp]
	      	ldi  	r4,#-1
	      	andi 	r4,r4,#65535
	      	sc   	r4,[r3]
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_3:
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
	      	bra  	FMTKmsg_25
FMTKmsg_1:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_25
DequeueMsg_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	ldi  	r3,#0
	      	mov  	r12,r3
	      	lw   	r3,32[r11]
	      	beq  	r3,FMTKmsg_31
	      	dec  	32[r11],#1
	      	lc   	r3,8[r11]
	      	sc   	r3,-10[bp]
	      	lc   	r3,-10[bp]
	      	blt  	r3,FMTKmsg_33
	      	lc   	r5,-10[bp]
	      	asli 	r4,r5,#5
	      	lea  	r5,message_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r12,r3
	      	lc   	r3,[r12]
	      	sc   	r3,8[r11]
	      	lc   	r3,8[r11]
	      	bge  	r3,FMTKmsg_35
	      	ldi  	r3,#-1
	      	sc   	r3,10[r11]
FMTKmsg_35:
	      	lc   	r3,-10[bp]
	      	andi 	r3,r3,#65535
	      	sc   	r3,[r12]
FMTKmsg_33:
FMTKmsg_31:
	      	mov  	r1,r12
FMTKmsg_37:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
public code FMTK_AllocMbx_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_38
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lea  	r3,freeMBX_[gp]
	      	mov  	r12,r3
	      	lw   	r13,24[bp]
	      	     	mfspr r1,ivno 
	      	bne  	r13,FMTKmsg_40
	      	ldi  	r1,#4
FMTKmsg_42:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_40:
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_43
	      	lc   	r3,[r12]
	      	blt  	r3,FMTKmsg_47
	      	lc   	r3,[r12]
	      	cmp  	r4,r3,#1024
	      	blt  	r4,FMTKmsg_45
FMTKmsg_47:
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#64
	      	bra  	FMTKmsg_42
FMTKmsg_45:
	      	lc   	r5,[r12]
	      	asli 	r4,r5,#6
	      	lea  	r5,mailbox_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r11,r3
	      	lc   	r3,[r11]
	      	sc   	r3,[r12]
	      	dec  	nMailbox_[gp],#1
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_43:
	      	lea  	r5,mailbox_[gp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#6
	      	sc   	r3,[r13]
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	sb   	r3,2[r11]
	      	ldi  	r3,#-1
	      	sc   	r3,4[r11]
	      	ldi  	r3,#-1
	      	sc   	r3,6[r11]
	      	ldi  	r3,#-1
	      	sc   	r3,8[r11]
	      	ldi  	r3,#-1
	      	sc   	r3,10[r11]
	      	sw   	r0,16[r11]
	      	sw   	r0,32[r11]
	      	sw   	r0,40[r11]
	      	ldi  	r3,#8
	      	sw   	r3,24[r11]
	      	ldi  	r3,#2
	      	andi 	r3,r3,#65535
	      	sc   	r3,12[r11]
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_42
FMTKmsg_38:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_42
endpublic

public code FMTK_FreeMbx_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_48
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lea  	r3,-24[bp]
	      	mov  	r11,r3
	      	     	mfspr r1,ivno 
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#1024
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#6
	      	lea  	r5,mailbox_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r13,r3
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_50
	      	lb   	r3,2[r13]
	      	sxb  	r3,r3
	      	push 	r3
	      	bsr  	GetJCBPtr_
	      	pop  	r3
	      	mov  	r4,r1
	      	cmp  	r5,r3,r4
	      	beq  	r5,FMTKmsg_52
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	lea  	r4,jcbs_[gp]
	      	cmp  	r5,r3,r4
	      	beq  	r5,FMTKmsg_52
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#12
FMTKmsg_54:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_52:
FMTKmsg_55:
	      	push 	r13
	      	bsr  	DequeueMsg_
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	beq  	r12,FMTKmsg_56
	      	ldi  	r3,#1
	      	andi 	r3,r3,#65535
	      	sc   	r3,6[r12]
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,2[r12]
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,4[r12]
	      	lc   	r3,freeMSG_[gp]
	      	andi 	r3,r3,#65535
	      	sc   	r3,[r12]
	      	lea  	r5,message_[gp]
	      	subu 	r4,r12,r5
	      	lsri 	r3,r4,#5
	      	sc   	r3,freeMSG_[gp]
	      	inc  	nMsgBlk_[gp],#1
	      	bra  	FMTKmsg_55
FMTKmsg_56:
FMTKmsg_57:
	      	push 	r11
	      	push 	r13
	      	bsr  	DequeThreadFromMbx_
	      	addui	sp,sp,#16
	      	lw   	r3,[r11]
	      	bne  	r3,FMTKmsg_59
	      	bra  	FMTKmsg_58
FMTKmsg_59:
	      	lw   	r3,[r11]
	      	ldi  	r4,#0
	      	andi 	r4,r4,#65535
	      	sc   	r4,678[r3]
	      	lw   	r4,[r11]
	      	lb   	r4,717[r4]
	      	and  	r3,r4,#1
	      	beq  	r3,FMTKmsg_61
	      	lw   	r5,[r11]
	      	lea  	r6,tcbs_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	RemoveFromTimeoutList_
FMTKmsg_61:
	      	lw   	r5,[r11]
	      	lea  	r6,tcbs_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
	      	bra  	FMTKmsg_57
FMTKmsg_58:
	      	lc   	r3,freeMBX_[gp]
	      	sc   	r3,[r13]
	      	lea  	r5,mailbox_[gp]
	      	subu 	r4,r13,r5
	      	lsri 	r3,r4,#6
	      	sc   	r3,freeMBX_[gp]
	      	inc  	nMailbox_[gp],#1
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_50:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_54
FMTKmsg_48:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_54
endpublic

public code SetMbxMsgQueStrategy_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_63
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	     	mfspr r1,ivno 
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#1024
	      	lw   	r3,32[bp]
	      	cmp  	r4,r3,#2
	      	ble  	r4,FMTKmsg_65
	      	ldi  	r1,#4
FMTKmsg_67:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_65:
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#6
	      	lea  	r5,mailbox_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r11,r3
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_68
	      	lb   	r3,2[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	bsr  	GetJCBPtr_
	      	pop  	r3
	      	mov  	r4,r1
	      	cmp  	r5,r3,r4
	      	beq  	r5,FMTKmsg_70
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	lea  	r4,jcbs_[gp]
	      	cmp  	r5,r3,r4
	      	beq  	r5,FMTKmsg_70
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#12
	      	bra  	FMTKmsg_67
FMTKmsg_70:
	      	lw   	r3,32[bp]
	      	andi 	r3,r3,#65535
	      	sc   	r3,12[r11]
	      	lw   	r3,40[bp]
	      	sw   	r3,24[r11]
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_68:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_67
FMTKmsg_63:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_67
endpublic

public code FMTK_SendMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_72
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	lea  	r3,-24[bp]
	      	mov  	r11,r3
	      	lea  	r3,freeMSG_[gp]
	      	mov  	r14,r3
	      	     	mfspr r1,ivno 
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#1024
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#6
	      	lea  	r5,mailbox_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r13,r3
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_74
	      	lb   	r3,2[r13]
	      	blt  	r3,FMTKmsg_78
	      	lb   	r3,2[r13]
	      	cmp  	r4,r3,#51
	      	blt  	r4,FMTKmsg_76
FMTKmsg_78:
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#8
FMTKmsg_79:
	      	pop  	r14
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_76:
	      	lc   	r3,[r14]
	      	blt  	r3,FMTKmsg_82
	      	lc   	r3,[r14]
	      	cmp  	r4,r3,#16384
	      	blt  	r4,FMTKmsg_80
FMTKmsg_82:
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#65
	      	bra  	FMTKmsg_79
FMTKmsg_80:
	      	lc   	r5,[r14]
	      	asli 	r4,r5,#5
	      	lea  	r5,message_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r12,r3
	      	lc   	r3,[r12]
	      	sc   	r3,[r14]
	      	dec  	nMsgBlk_[gp],#1
	      	push 	r3
	      	push 	r4
	      	bsr  	GetJCBPtr_
	      	pop  	r4
	      	pop  	r3
	      	mov  	r5,r1
	      	lea  	r6,jcbs_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#11
	      	andi 	r3,r3,#65535
	      	sc   	r3,2[r12]
	      	lc   	r3,24[bp]
	      	andi 	r3,r3,#65535
	      	sc   	r3,4[r12]
	      	ldi  	r3,#2
	      	andi 	r3,r3,#65535
	      	sc   	r3,6[r12]
	      	lw   	r3,32[bp]
	      	sw   	r3,8[r12]
	      	lw   	r3,40[bp]
	      	sw   	r3,16[r12]
	      	lw   	r3,48[bp]
	      	sw   	r3,24[r12]
	      	push 	r11
	      	push 	r13
	      	bsr  	DequeThreadFromMbx_
	      	addui	sp,sp,#16
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_74:
	      	lw   	r3,[r11]
	      	bne  	r3,FMTKmsg_83
	      	push 	r12
	      	push 	r13
	      	bsr  	QueueMsg_
	      	mov  	r3,r1
	      	mov  	r1,r3
	      	bra  	FMTKmsg_79
FMTKmsg_83:
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_85
	      	lw   	r3,[r11]
	      	lcu  	r4,2[r12]
	      	sc   	r4,674[r3]
	      	lw   	r3,[r11]
	      	lcu  	r4,4[r12]
	      	sc   	r4,676[r3]
	      	lw   	r3,[r11]
	      	lcu  	r4,6[r12]
	      	sc   	r4,678[r3]
	      	lw   	r3,[r11]
	      	lw   	r4,8[r12]
	      	sw   	r4,680[r3]
	      	lw   	r3,[r11]
	      	lw   	r4,16[r12]
	      	sw   	r4,688[r3]
	      	lw   	r3,[r11]
	      	lw   	r4,24[r12]
	      	sw   	r4,696[r3]
	      	ldi  	r3,#1
	      	andi 	r3,r3,#65535
	      	sc   	r3,6[r12]
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,2[r12]
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,4[r12]
	      	lc   	r3,[r14]
	      	andi 	r3,r3,#65535
	      	sc   	r3,[r12]
	      	lea  	r5,message_[gp]
	      	subu 	r4,r12,r5
	      	lsri 	r3,r4,#5
	      	sc   	r3,[r14]
	      	lw   	r4,[r11]
	      	lb   	r4,717[r4]
	      	and  	r3,r4,#1
	      	beq  	r3,FMTKmsg_87
	      	lw   	r5,[r11]
	      	lea  	r6,tcbs_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	RemoveFromTimeoutList_
FMTKmsg_87:
	      	lw   	r5,[r11]
	      	lea  	r6,tcbs_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_85:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_79
FMTKmsg_72:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_79
endpublic

public code FMTK_PostMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_89
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	lea  	r3,-24[bp]
	      	mov  	r11,r3
	      	lea  	r3,freeMSG_[gp]
	      	mov  	r14,r3
	      	     	mfspr r1,ivno 
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#1024
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#6
	      	lea  	r5,mailbox_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r13,r3
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_91
	      	lb   	r3,2[r13]
	      	blt  	r3,FMTKmsg_95
	      	lb   	r3,2[r13]
	      	cmp  	r4,r3,#51
	      	blt  	r4,FMTKmsg_93
FMTKmsg_95:
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#8
FMTKmsg_96:
	      	pop  	r14
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_93:
	      	lc   	r3,[r14]
	      	blt  	r3,FMTKmsg_99
	      	lc   	r3,[r14]
	      	cmp  	r4,r3,#16384
	      	blt  	r4,FMTKmsg_97
FMTKmsg_99:
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#65
	      	bra  	FMTKmsg_96
FMTKmsg_97:
	      	lc   	r5,[r14]
	      	asli 	r4,r5,#5
	      	lea  	r5,message_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r12,r3
	      	lc   	r3,[r12]
	      	sc   	r3,[r14]
	      	dec  	nMsgBlk_[gp],#1
	      	push 	r3
	      	push 	r4
	      	bsr  	GetJCBPtr_
	      	pop  	r4
	      	pop  	r3
	      	mov  	r5,r1
	      	lea  	r6,jcbs_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#11
	      	andi 	r3,r3,#65535
	      	sc   	r3,2[r12]
	      	lc   	r3,24[bp]
	      	andi 	r3,r3,#65535
	      	sc   	r3,4[r12]
	      	ldi  	r3,#2
	      	andi 	r3,r3,#65535
	      	sc   	r3,6[r12]
	      	lw   	r3,32[bp]
	      	sw   	r3,8[r12]
	      	lw   	r3,40[bp]
	      	sw   	r3,16[r12]
	      	lw   	r3,48[bp]
	      	sw   	r3,24[r12]
	      	push 	r11
	      	push 	r13
	      	bsr  	DequeueThreadFromMbx_
	      	addui	sp,sp,#16
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_91:
	      	lw   	r3,[r11]
	      	bne  	r3,FMTKmsg_100
	      	push 	r12
	      	push 	r13
	      	bsr  	QueueMsg_
	      	mov  	r3,r1
	      	sw   	r3,-32[bp]
	      	lw   	r3,-32[bp]
	      	mov  	r1,r3
	      	bra  	FMTKmsg_96
FMTKmsg_100:
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_102
	      	lw   	r3,[r11]
	      	lcu  	r4,2[r12]
	      	sc   	r4,674[r3]
	      	lw   	r3,[r11]
	      	lcu  	r4,4[r12]
	      	sc   	r4,676[r3]
	      	lw   	r3,[r11]
	      	lcu  	r4,6[r12]
	      	sc   	r4,678[r3]
	      	lw   	r3,[r11]
	      	lw   	r4,8[r12]
	      	sw   	r4,680[r3]
	      	lw   	r3,[r11]
	      	lw   	r4,16[r12]
	      	sw   	r4,688[r3]
	      	lw   	r3,[r11]
	      	lw   	r4,24[r12]
	      	sw   	r4,696[r3]
	      	ldi  	r3,#1
	      	andi 	r3,r3,#65535
	      	sc   	r3,6[r12]
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,2[r12]
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,4[r12]
	      	lc   	r3,[r14]
	      	andi 	r3,r3,#65535
	      	sc   	r3,[r12]
	      	lea  	r5,message_[gp]
	      	subu 	r4,r12,r5
	      	lsri 	r3,r4,#5
	      	sc   	r3,[r14]
	      	lw   	r4,[r11]
	      	lb   	r4,717[r4]
	      	and  	r3,r4,#1
	      	beq  	r3,FMTKmsg_104
	      	lw   	r5,[r11]
	      	lea  	r6,tcbs_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	RemoveFromTimeoutList_
FMTKmsg_104:
	      	lw   	r5,[r11]
	      	lea  	r6,tcbs_[gp]
	      	subu 	r4,r5,r6
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_102:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_96
FMTKmsg_89:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_96
endpublic

public code FMTK_WaitMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_106
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	push 	r15
	      	push 	r16
	      	push 	r17
	      	lw   	r13,48[bp]
	      	lw   	r14,40[bp]
	      	lw   	r15,32[bp]
	      	     	mfspr r1,ivno 
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#1024
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#6
	      	lea  	r5,mailbox_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r12,r3
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_108
	      	lb   	r3,2[r12]
	      	blt  	r3,FMTKmsg_112
	      	lb   	r3,2[r12]
	      	cmp  	r4,r3,#51
	      	blt  	r4,FMTKmsg_110
FMTKmsg_112:
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#8
FMTKmsg_113:
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
FMTKmsg_110:
	      	push 	r12
	      	bsr  	DequeueMsg_
	      	mov  	r3,r1
	      	mov  	r17,r3
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_108:
	      	bne  	r17,FMTKmsg_114
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_116
	      	bsr  	GetRunningTCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lea  	r5,tcbs_[gp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	RemoveFromReadyList_
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_116:
	      	lb   	r3,717[r11]
	      	ori  	r3,r3,#2
	      	sb   	r3,717[r11]
	      	lc   	r3,24[bp]
	      	sc   	r3,712[r11]
	      	ldi  	r3,#-1
	      	sc   	r3,628[r11]
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_118
	      	lc   	r3,4[r12]
	      	bge  	r3,FMTKmsg_120
	      	ldi  	r3,#-1
	      	sc   	r3,630[r11]
	      	lea  	r5,tcbs_[gp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#10
	      	sc   	r3,4[r12]
	      	lea  	r5,tcbs_[gp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#10
	      	sc   	r3,6[r12]
	      	ldi  	r3,#1
	      	sw   	r3,16[r12]
	      	bra  	FMTKmsg_121
FMTKmsg_120:
	      	lc   	r3,6[r12]
	      	sc   	r3,630[r11]
	      	lc   	r5,6[r12]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	lea  	r6,tcbs_[gp]
	      	subu 	r5,r11,r6
	      	lsri 	r4,r5,#10
	      	sc   	r4,628[r3]
	      	lea  	r5,tcbs_[gp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#10
	      	sc   	r3,6[r12]
	      	inc  	16[r12],#1
FMTKmsg_121:
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_118:
	      	lw   	r3,56[bp]
	      	beq  	r3,FMTKmsg_122
	      	     	; Waitmsg here; 
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_124
	      	push 	56[bp]
	      	lea  	r5,tcbs_[gp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	InsertIntoTimeoutList_
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_124:
FMTKmsg_122:
	      	     	int #2 
	      	bsr  	GetRunningTCBPtr_
	      	mov  	r3,r1
	      	mov  	r16,r3
	      	addu 	r3,r16,#672
	      	lc   	r3,6[r3]
	      	bne  	r3,FMTKmsg_126
	      	ldi  	r1,#9
	      	bra  	FMTKmsg_113
FMTKmsg_126:
	      	ldi  	r3,#0
	      	andi 	r3,r3,#65535
	      	sc   	r3,678[r16]
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,676[r16]
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,674[r16]
	      	beq  	r15,FMTKmsg_128
	      	lw   	r3,680[r16]
	      	sw   	r3,[r15]
FMTKmsg_128:
	      	beq  	r14,FMTKmsg_130
	      	lw   	r3,688[r16]
	      	sw   	r3,[r14]
FMTKmsg_130:
	      	beq  	r13,FMTKmsg_132
	      	lw   	r3,696[r16]
	      	sw   	r3,[r13]
FMTKmsg_132:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_113
FMTKmsg_114:
	      	beq  	r15,FMTKmsg_134
	      	lw   	r3,8[r17]
	      	sw   	r3,[r15]
FMTKmsg_134:
	      	beq  	r14,FMTKmsg_136
	      	lw   	r3,16[r17]
	      	sw   	r3,[r14]
FMTKmsg_136:
	      	beq  	r13,FMTKmsg_138
	      	lw   	r3,24[r17]
	      	sw   	r3,[r13]
FMTKmsg_138:
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_140
	      	ldi  	r3,#1
	      	andi 	r3,r3,#65535
	      	sc   	r3,6[r17]
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,2[r17]
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,4[r17]
	      	lc   	r3,freeMSG_[gp]
	      	andi 	r3,r3,#65535
	      	sc   	r3,[r17]
	      	lea  	r5,message_[gp]
	      	subu 	r4,r17,r5
	      	lsri 	r3,r4,#5
	      	sc   	r3,freeMSG_[gp]
	      	inc  	nMsgBlk_[gp],#1
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_140:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_113
FMTKmsg_106:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_113
endpublic

public code FMTK_PeekMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_142
	      	mov  	bp,sp
	      	push 	#0
	      	push 	40[bp]
	      	push 	32[bp]
	      	push 	24[bp]
	      	bsr  	CheckMsg_
	      	addui	sp,sp,#32
	      	mov  	r3,r1
	      	mov  	r1,r3
FMTKmsg_144:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_142:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_144
endpublic

public code FMTK_CheckMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_145
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	push 	r15
	      	lw   	r13,48[bp]
	      	lw   	r14,40[bp]
	      	lw   	r15,32[bp]
	      	     	mfspr r1,ivno 
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#1024
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#6
	      	lea  	r5,mailbox_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r12,r3
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_147
	      	lb   	r3,2[r12]
	      	bne  	r3,FMTKmsg_149
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#8
FMTKmsg_151:
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
FMTKmsg_149:
	      	lw   	r3,56[bp]
	      	cmp  	r4,r3,#1
	      	bne  	r4,FMTKmsg_152
	      	push 	r12
	      	bsr  	DequeueMsg_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	bra  	FMTKmsg_153
FMTKmsg_152:
	      	lc   	r3,8[r12]
	      	andi 	r3,r3,#65535
	      	mov  	r11,r3
FMTKmsg_153:
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_147:
	      	bne  	r11,FMTKmsg_154
	      	ldi  	r1,#9
	      	bra  	FMTKmsg_151
FMTKmsg_154:
	      	beq  	r15,FMTKmsg_156
	      	lw   	r3,8[r11]
	      	sw   	r3,[r15]
FMTKmsg_156:
	      	beq  	r14,FMTKmsg_158
	      	lw   	r3,16[r11]
	      	sw   	r3,[r14]
FMTKmsg_158:
	      	beq  	r13,FMTKmsg_160
	      	lw   	r3,24[r11]
	      	sw   	r3,[r13]
FMTKmsg_160:
	      	lw   	r3,56[bp]
	      	cmp  	r4,r3,#1
	      	bne  	r4,FMTKmsg_162
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_164
	      	ldi  	r3,#1
	      	andi 	r3,r3,#65535
	      	sc   	r3,6[r11]
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,2[r11]
	      	ldi  	r3,#-1
	      	andi 	r3,r3,#65535
	      	sc   	r3,4[r11]
	      	lc   	r3,freeMSG_[gp]
	      	andi 	r3,r3,#65535
	      	sc   	r3,[r11]
	      	lea  	r5,message_[gp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#5
	      	sc   	r3,freeMSG_[gp]
	      	inc  	nMsgBlk_[gp],#1
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKmsg_164:
FMTKmsg_162:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_151
FMTKmsg_145:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_151
endpublic

	rodata
	align	16
	align	8
	extern	jcbs_
;	global	FMTK_AllocMbx_
	extern	tcbs_
	extern	nMsgBlk_
;	global	outb_
	extern	IOFocusTbl_
;	global	outc_
;	global	outh_
	extern	irq_stack_
	extern	IOFocusNdx_
	extern	DumpTaskList_
;	global	outw_
	extern	fmtk_irq_stack_
	extern	GetRunningTCB_
	extern	DequeueThreadFromMbx_
	extern	fmtk_sys_stack_
	extern	message_
;	global	SetRunningTCB_
	extern	mailbox_
	extern	FMTK_Inited_
;	global	SetMbxMsgQueStrategy_
	extern	missed_ticks_
	extern	CheckMsg_
	extern	DequeThreadFromMbx_
;	global	chkTCB_
	extern	GetRunningTCBPtr_
;	global	UnlockSemaphore_
	extern	GetVecno_
	extern	GetJCBPtr_
	extern	video_bufs_
	extern	getCPU_
	extern	hasUltraHighPriorityTasks_
;	global	LockSemaphore_
	extern	iof_switch_
	extern	kbd_sema_
	extern	nMailbox_
;	global	FMTK_FreeMbx_
;	global	FMTK_PeekMsg_
;	global	set_vector_
;	global	FMTK_SendMsg_
	extern	iof_sema_
	extern	sys_stacks_
	extern	BIOS_RespMbx_
;	global	FMTK_WaitMsg_
;	global	FMTK_PostMsg_
	extern	BIOS1_sema_
	extern	sys_sema_
	extern	readyQ_
	extern	sysstack_
	extern	freeTCB_
	extern	TimeoutList_
;	global	RemoveFromTimeoutList_
;	global	SetBound50_
	extern	stacks_
	extern	freeMSG_
	extern	freeMBX_
;	global	SetBound51_
;	global	SetBound48_
;	global	SetBound49_
;	global	InsertIntoTimeoutList_
;	global	RemoveFromReadyList_
	extern	bios_stacks_
;	global	FMTK_CheckMsg_
;	global	InsertIntoReadyList_
