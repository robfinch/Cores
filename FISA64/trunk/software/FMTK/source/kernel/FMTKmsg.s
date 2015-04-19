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
	      	ldi  	r12,#nMsgBlk_
	      	ldi  	r13,#freeMSG_
	      	sw   	r0,-24[bp]
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_2
	      	inc  	32[r11],#1
	      	lcu  	r3,12[r11]
	      	cmp  	r4,r3,#0
	      	beq  	r4,FMTKmsg_5
	      	cmp  	r4,r3,#2
	      	beq  	r4,FMTKmsg_6
	      	cmp  	r4,r3,#1
	      	beq  	r4,FMTKmsg_7
	      	bra  	FMTKmsg_4
FMTKmsg_5:
	      	bra  	FMTKmsg_4
FMTKmsg_6:
FMTKmsg_8:
	      	lw   	r3,32[r11]
	      	lw   	r4,24[r11]
	      	cmpu 	r5,r3,r4
	      	ble  	r5,FMTKmsg_9
	      	lc   	r4,8[r11]
	      	asli 	r3,r4,#5
	      	lcu  	r3,message_[r3]
	      	sxc  	r3,r3
	      	sc   	r3,-10[bp]
	      	lc   	r5,-10[bp]
	      	asli 	r4,r5,#5
	      	addu 	r3,r4,#message_
	      	sw   	r3,-8[bp]
	      	lc   	r3,[r13]
	      	lc   	r5,8[r11]
	      	asli 	r4,r5,#5
	      	sc   	r3,message_[r4]
	      	lc   	r3,8[r11]
	      	sc   	r3,[r13]
	      	inc  	[r12],#1
	      	dec  	32[r11],#1
	      	lc   	r3,-10[bp]
	      	sc   	r3,8[r11]
	      	lw   	r3,40[r11]
	      	cmpu 	r4,r3,#-1
	      	bge  	r4,FMTKmsg_10
	      	inc  	40[r11],#1
FMTKmsg_10:
	      	ldi  	r3,#6
	      	sw   	r3,-24[bp]
	      	bra  	FMTKmsg_8
FMTKmsg_9:
	      	bra  	FMTKmsg_4
FMTKmsg_7:
	      	lw   	r3,32[r11]
	      	lw   	r4,24[r11]
	      	cmpu 	r5,r3,r4
	      	ble  	r5,FMTKmsg_12
	      	lc   	r3,[r13]
	      	lw   	r4,32[bp]
	      	sc   	r3,[r4]
	      	lw   	r5,32[bp]
	      	subu 	r4,r5,#message_
	      	lsri 	r3,r4,#5
	      	sc   	r3,[r13]
	      	inc  	[r12],#1
	      	lw   	r3,40[r11]
	      	cmpu 	r4,r3,#-1
	      	bge  	r4,FMTKmsg_14
	      	inc  	40[r11],#1
FMTKmsg_14:
	      	ldi  	r3,#6
	      	sw   	r3,-24[bp]
	      	dec  	32[r11],#1
FMTKmsg_12:
FMTKmsg_16:
	      	lw   	r3,32[r11]
	      	lw   	r4,24[r11]
	      	cmpu 	r5,r3,r4
	      	ble  	r5,FMTKmsg_17
	      	lc   	r5,8[r11]
	      	asli 	r4,r5,#5
	      	addu 	r3,r4,#message_
	      	sw   	r3,-8[bp]
FMTKmsg_18:
	      	lw   	r5,-8[bp]
	      	subu 	r4,r5,#message_
	      	lsri 	r3,r4,#5
	      	lc   	r4,10[r11]
	      	andi 	r4,r4,#65535
	      	cmp  	r5,r3,r4
	      	beq  	r5,FMTKmsg_19
	      	lw   	r3,-8[bp]
	      	sw   	r3,32[bp]
	      	lw   	r5,-8[bp]
	      	lcu  	r5,[r5]
	      	asli 	r4,r5,#5
	      	addu 	r3,r4,#message_
	      	sw   	r3,-8[bp]
	      	bra  	FMTKmsg_18
FMTKmsg_19:
	      	lw   	r5,32[bp]
	      	subu 	r4,r5,#message_
	      	lsri 	r3,r4,#5
	      	sc   	r3,10[r11]
	      	lc   	r3,[r13]
	      	lw   	r4,-8[bp]
	      	sc   	r3,[r4]
	      	lw   	r5,-8[bp]
	      	subu 	r4,r5,#message_
	      	lsri 	r3,r4,#5
	      	sc   	r3,[r13]
	      	inc  	[r12],#1
	      	lw   	r3,40[r11]
	      	cmpu 	r4,r3,#-1
	      	bge  	r4,FMTKmsg_20
	      	inc  	40[r11],#1
FMTKmsg_20:
	      	dec  	32[r11],#1
	      	ldi  	r3,#6
	      	sw   	r3,-24[bp]
	      	bra  	FMTKmsg_16
FMTKmsg_17:
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#6
	      	bne  	r4,FMTKmsg_22
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
FMTKmsg_24:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#16
FMTKmsg_22:
	      	bra  	FMTKmsg_4
FMTKmsg_4:
	      	lc   	r3,10[r11]
	      	blt  	r3,FMTKmsg_25
	      	lw   	r5,32[bp]
	      	subu 	r4,r5,#message_
	      	lsri 	r3,r4,#5
	      	lc   	r5,10[r11]
	      	asli 	r4,r5,#5
	      	sc   	r3,message_[r4]
	      	bra  	FMTKmsg_26
FMTKmsg_25:
	      	lw   	r5,32[bp]
	      	subu 	r4,r5,#message_
	      	lsri 	r3,r4,#5
	      	sc   	r3,8[r11]
FMTKmsg_26:
	      	lw   	r5,32[bp]
	      	subu 	r4,r5,#message_
	      	lsri 	r3,r4,#5
	      	sc   	r3,10[r11]
	      	lw   	r3,32[bp]
	      	ldi  	r4,#-1
	      	sc   	r4,[r3]
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_2:
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
	      	bra  	FMTKmsg_24
FMTKmsg_1:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_24
DequeueMsg_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	ldi  	r12,#0
	      	lw   	r3,32[r11]
	      	beq  	r3,FMTKmsg_29
	      	dec  	32[r11],#1
	      	lc   	r3,8[r11]
	      	sc   	r3,-10[bp]
	      	lc   	r3,-10[bp]
	      	blt  	r3,FMTKmsg_31
	      	lc   	r5,-10[bp]
	      	asli 	r4,r5,#5
	      	addu 	r3,r4,#message_
	      	mov  	r12,r3
	      	lcu  	r3,[r12]
	      	sxc  	r3,r3
	      	sc   	r3,8[r11]
	      	lc   	r3,8[r11]
	      	bge  	r3,FMTKmsg_33
	      	ldi  	r3,#-1
	      	sc   	r3,10[r11]
FMTKmsg_33:
	      	lc   	r3,-10[bp]
	      	sc   	r3,[r12]
FMTKmsg_31:
FMTKmsg_29:
	      	mov  	r1,r12
FMTKmsg_35:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
public code FMTK_AllocMbx_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_36
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	ldi  	r12,#freeMBX_
	      	lw   	r13,24[bp]
	      	     	mfspr r1,ivno 
	      	bne  	r13,FMTKmsg_37
	      	ldi  	r1,#4
FMTKmsg_39:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_37:
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_40
	      	lc   	r3,[r12]
	      	blt  	r3,FMTKmsg_44
	      	lc   	r3,[r12]
	      	cmp  	r4,r3,#1024
	      	blt  	r4,FMTKmsg_42
FMTKmsg_44:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#64
	      	bra  	FMTKmsg_39
FMTKmsg_42:
	      	lc   	r5,[r12]
	      	asli 	r4,r5,#6
	      	addu 	r3,r4,#mailbox_
	      	mov  	r11,r3
	      	lc   	r3,[r11]
	      	sc   	r3,[r12]
	      	dec  	nMailbox_,#1
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_40:
	      	subu 	r4,r11,#mailbox_
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
	      	sc   	r3,12[r11]
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_39
FMTKmsg_36:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_39
endpublic

public code FMTK_FreeMbx_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_45
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
	      	addu 	r3,r4,#mailbox_
	      	mov  	r13,r3
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_46
	      	lb   	r3,2[r13]
	      	sxb  	r3,r3
	      	push 	r3
	      	bsr  	GetJCBPtr_
	      	pop  	r3
	      	mov  	r4,r1
	      	cmp  	r5,r3,r4
	      	beq  	r5,FMTKmsg_48
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_48
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#12
FMTKmsg_50:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_48:
FMTKmsg_51:
	      	push 	r13
	      	bsr  	DequeueMsg_
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	beq  	r3,FMTKmsg_52
	      	ldi  	r3,#1
	      	sc   	r3,6[r12]
	      	ldi  	r3,#-1
	      	sc   	r3,2[r12]
	      	ldi  	r3,#-1
	      	sc   	r3,4[r12]
	      	lc   	r3,freeMSG_
	      	sc   	r3,[r12]
	      	subu 	r4,r12,#message_
	      	lsri 	r3,r4,#5
	      	sc   	r3,freeMSG_
	      	inc  	nMsgBlk_,#1
	      	bra  	FMTKmsg_51
FMTKmsg_52:
FMTKmsg_53:
	      	push 	r11
	      	push 	r13
	      	bsr  	DequeThreadFromMbx_
	      	addui	sp,sp,#16
	      	lw   	r3,[r11]
	      	bne  	r3,FMTKmsg_55
	      	bra  	FMTKmsg_54
FMTKmsg_55:
	      	lw   	r3,[r11]
	      	sc   	r0,678[r3]
	      	lw   	r4,[r11]
	      	lb   	r4,717[r4]
	      	and  	r3,r4,#1
	      	beq  	r3,FMTKmsg_57
	      	lw   	r5,[r11]
	      	subu 	r4,r5,#tcbs_
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	RemoveFromTimeoutList_
FMTKmsg_57:
	      	lw   	r5,[r11]
	      	subu 	r4,r5,#tcbs_
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
	      	bra  	FMTKmsg_53
FMTKmsg_54:
	      	lc   	r3,freeMBX_
	      	sc   	r3,[r13]
	      	subu 	r4,r13,#mailbox_
	      	lsri 	r3,r4,#6
	      	sc   	r3,freeMBX_
	      	inc  	nMailbox_,#1
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_46:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_50
FMTKmsg_45:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_50
endpublic

public code SetMbxMsgQueStrategy_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_59
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	     	mfspr r1,ivno 
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#1024
	      	lw   	r3,32[bp]
	      	cmp  	r4,r3,#2
	      	ble  	r4,FMTKmsg_60
	      	ldi  	r1,#4
FMTKmsg_62:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_60:
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#6
	      	addu 	r3,r4,#mailbox_
	      	mov  	r11,r3
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_63
	      	lb   	r3,2[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	bsr  	GetJCBPtr_
	      	pop  	r3
	      	mov  	r4,r1
	      	cmp  	r5,r3,r4
	      	beq  	r5,FMTKmsg_65
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_65
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#12
	      	bra  	FMTKmsg_62
FMTKmsg_65:
	      	lw   	r3,32[bp]
	      	sc   	r3,12[r11]
	      	lw   	r3,40[bp]
	      	sw   	r3,24[r11]
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_63:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_62
FMTKmsg_59:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_62
endpublic

public code FMTK_SendMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_67
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	lea  	r3,-24[bp]
	      	mov  	r11,r3
	      	ldi  	r14,#freeMSG_
	      	     	mfspr r1,ivno 
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#1024
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#6
	      	addu 	r3,r4,#mailbox_
	      	mov  	r13,r3
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_68
	      	lb   	r3,2[r13]
	      	blt  	r3,FMTKmsg_72
	      	lb   	r3,2[r13]
	      	cmp  	r4,r3,#51
	      	blt  	r4,FMTKmsg_70
FMTKmsg_72:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#8
FMTKmsg_73:
	      	pop  	r14
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_70:
	      	lc   	r3,[r14]
	      	blt  	r3,FMTKmsg_76
	      	lc   	r3,[r14]
	      	cmp  	r4,r3,#16384
	      	blt  	r4,FMTKmsg_74
FMTKmsg_76:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#65
	      	bra  	FMTKmsg_73
FMTKmsg_74:
	      	lc   	r5,[r14]
	      	asli 	r4,r5,#5
	      	addu 	r3,r4,#message_
	      	mov  	r12,r3
	      	lcu  	r3,[r12]
	      	sxc  	r3,r3
	      	sc   	r3,[r14]
	      	dec  	nMsgBlk_,#1
	      	push 	r3
	      	push 	r4
	      	bsr  	GetJCBPtr_
	      	pop  	r4
	      	pop  	r3
	      	mov  	r5,r1
	      	subu 	r4,r5,#jcbs_
	      	lsri 	r3,r4,#11
	      	sc   	r3,2[r12]
	      	lc   	r3,24[bp]
	      	sc   	r3,4[r12]
	      	ldi  	r3,#2
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
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_68:
	      	lw   	r3,[r11]
	      	bne  	r3,FMTKmsg_77
	      	push 	r12
	      	push 	r13
	      	bsr  	QueueMsg_
	      	mov  	r3,r1
	      	mov  	r1,r3
	      	bra  	FMTKmsg_73
FMTKmsg_77:
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_79
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
	      	sc   	r3,6[r12]
	      	ldi  	r3,#-1
	      	sc   	r3,2[r12]
	      	ldi  	r3,#-1
	      	sc   	r3,4[r12]
	      	lc   	r3,[r14]
	      	sc   	r3,[r12]
	      	subu 	r4,r12,#message_
	      	lsri 	r3,r4,#5
	      	sc   	r3,[r14]
	      	lw   	r4,[r11]
	      	lb   	r4,717[r4]
	      	and  	r3,r4,#1
	      	beq  	r3,FMTKmsg_81
	      	lw   	r5,[r11]
	      	subu 	r4,r5,#tcbs_
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	RemoveFromTimeoutList_
FMTKmsg_81:
	      	lw   	r5,[r11]
	      	subu 	r4,r5,#tcbs_
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_79:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_73
FMTKmsg_67:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_73
endpublic

public code FMTK_PostMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_83
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	lea  	r3,-24[bp]
	      	mov  	r11,r3
	      	ldi  	r14,#freeMSG_
	      	     	mfspr r1,ivno 
	      	lc   	r3,24[bp]
	      	chk  	r3,r0,#1024
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#6
	      	addu 	r3,r4,#mailbox_
	      	mov  	r13,r3
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_84
	      	lb   	r3,2[r13]
	      	blt  	r3,FMTKmsg_88
	      	lb   	r3,2[r13]
	      	cmp  	r4,r3,#51
	      	blt  	r4,FMTKmsg_86
FMTKmsg_88:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#8
FMTKmsg_89:
	      	pop  	r14
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_86:
	      	lc   	r3,[r14]
	      	blt  	r3,FMTKmsg_92
	      	lc   	r3,[r14]
	      	cmp  	r4,r3,#16384
	      	blt  	r4,FMTKmsg_90
FMTKmsg_92:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#65
	      	bra  	FMTKmsg_89
FMTKmsg_90:
	      	lc   	r5,[r14]
	      	asli 	r4,r5,#5
	      	addu 	r3,r4,#message_
	      	mov  	r12,r3
	      	lcu  	r3,[r12]
	      	sxc  	r3,r3
	      	sc   	r3,[r14]
	      	dec  	nMsgBlk_,#1
	      	push 	r3
	      	push 	r4
	      	bsr  	GetJCBPtr_
	      	pop  	r4
	      	pop  	r3
	      	mov  	r5,r1
	      	subu 	r4,r5,#jcbs_
	      	lsri 	r3,r4,#11
	      	sc   	r3,2[r12]
	      	lc   	r3,24[bp]
	      	sc   	r3,4[r12]
	      	ldi  	r3,#2
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
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_84:
	      	lw   	r3,[r11]
	      	bne  	r3,FMTKmsg_93
	      	push 	r12
	      	push 	r13
	      	bsr  	QueueMsg_
	      	mov  	r3,r1
	      	sw   	r3,-32[bp]
	      	lw   	r3,-32[bp]
	      	mov  	r1,r3
	      	bra  	FMTKmsg_89
FMTKmsg_93:
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_95
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
	      	sc   	r3,6[r12]
	      	ldi  	r3,#-1
	      	sc   	r3,2[r12]
	      	ldi  	r3,#-1
	      	sc   	r3,4[r12]
	      	lc   	r3,[r14]
	      	sc   	r3,[r12]
	      	subu 	r4,r12,#message_
	      	lsri 	r3,r4,#5
	      	sc   	r3,[r14]
	      	lw   	r4,[r11]
	      	lb   	r4,717[r4]
	      	and  	r3,r4,#1
	      	beq  	r3,FMTKmsg_97
	      	lw   	r5,[r11]
	      	subu 	r4,r5,#tcbs_
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	RemoveFromTimeoutList_
FMTKmsg_97:
	      	lw   	r5,[r11]
	      	subu 	r4,r5,#tcbs_
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_95:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_89
FMTKmsg_83:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_89
endpublic

public code FMTK_WaitMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_99
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
	      	addu 	r3,r4,#mailbox_
	      	mov  	r12,r3
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_100
	      	lb   	r3,2[r12]
	      	blt  	r3,FMTKmsg_104
	      	lb   	r3,2[r12]
	      	cmp  	r4,r3,#51
	      	blt  	r4,FMTKmsg_102
FMTKmsg_104:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#8
FMTKmsg_105:
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
FMTKmsg_102:
	      	push 	r12
	      	bsr  	DequeueMsg_
	      	mov  	r3,r1
	      	mov  	r17,r3
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_100:
	      	bne  	r17,FMTKmsg_106
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_108
	      	bsr  	GetRunningTCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	subu 	r4,r11,#tcbs_
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	RemoveFromReadyList_
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_108:
	      	lb   	r3,717[r11]
	      	ori  	r3,r3,#2
	      	sb   	r3,717[r11]
	      	lc   	r3,24[bp]
	      	sc   	r3,712[r11]
	      	sc   	r0,628[r11]
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_110
	      	lc   	r3,4[r12]
	      	bge  	r3,FMTKmsg_112
	      	ldi  	r3,#-1
	      	sc   	r3,630[r11]
	      	subu 	r4,r11,#tcbs_
	      	lsri 	r3,r4,#10
	      	sc   	r3,4[r12]
	      	subu 	r4,r11,#tcbs_
	      	lsri 	r3,r4,#10
	      	sc   	r3,6[r12]
	      	ldi  	r3,#1
	      	sw   	r3,16[r12]
	      	bra  	FMTKmsg_113
FMTKmsg_112:
	      	lc   	r3,6[r12]
	      	sc   	r3,630[r11]
	      	subu 	r4,r11,#tcbs_
	      	lsri 	r3,r4,#10
	      	lc   	r6,6[r12]
	      	asli 	r5,r6,#10
	      	addu 	r4,r5,#tcbs_
	      	sc   	r3,628[r4]
	      	subu 	r4,r11,#tcbs_
	      	lsri 	r3,r4,#10
	      	sc   	r3,6[r12]
	      	inc  	16[r12],#1
FMTKmsg_113:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_110:
	      	lw   	r3,56[bp]
	      	beq  	r3,FMTKmsg_114
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_116
	      	push 	56[bp]
	      	subu 	r4,r11,#tcbs_
	      	lsri 	r3,r4,#10
	      	push 	r3
	      	bsr  	InsertIntoTimeoutList_
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_116:
FMTKmsg_114:
	      	     	int #2 
	      	bsr  	GetRunningTCBPtr_
	      	mov  	r3,r1
	      	mov  	r16,r3
	      	addu 	r3,r16,#672
	      	lcu  	r3,6[r3]
	      	bne  	r3,FMTKmsg_118
	      	ldi  	r1,#9
	      	bra  	FMTKmsg_105
FMTKmsg_118:
	      	sc   	r0,678[r16]
	      	ldi  	r3,#-1
	      	sc   	r3,676[r16]
	      	ldi  	r3,#-1
	      	sc   	r3,674[r16]
	      	beq  	r15,FMTKmsg_120
	      	lw   	r3,680[r16]
	      	sw   	r3,[r15]
FMTKmsg_120:
	      	beq  	r14,FMTKmsg_122
	      	lw   	r3,688[r16]
	      	sw   	r3,[r14]
FMTKmsg_122:
	      	beq  	r13,FMTKmsg_124
	      	lw   	r3,696[r16]
	      	sw   	r3,[r13]
FMTKmsg_124:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_105
FMTKmsg_106:
	      	beq  	r15,FMTKmsg_126
	      	lw   	r3,8[r17]
	      	sw   	r3,[r15]
FMTKmsg_126:
	      	beq  	r14,FMTKmsg_128
	      	lw   	r3,16[r17]
	      	sw   	r3,[r14]
FMTKmsg_128:
	      	beq  	r13,FMTKmsg_130
	      	lw   	r3,24[r17]
	      	sw   	r3,[r13]
FMTKmsg_130:
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_132
	      	ldi  	r3,#1
	      	sc   	r3,6[r17]
	      	ldi  	r3,#-1
	      	sc   	r3,2[r17]
	      	ldi  	r3,#-1
	      	sc   	r3,4[r17]
	      	lc   	r3,freeMSG_
	      	sc   	r3,[r17]
	      	subu 	r4,r17,#message_
	      	lsri 	r3,r4,#5
	      	sc   	r3,freeMSG_
	      	inc  	nMsgBlk_,#1
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_132:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_105
FMTKmsg_99:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_105
endpublic

public code FMTK_PeekMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_134
	      	mov  	bp,sp
	      	push 	#0
	      	push 	40[bp]
	      	push 	32[bp]
	      	push 	24[bp]
	      	bsr  	CheckMsg_
	      	addui	sp,sp,#32
	      	mov  	r3,r1
	      	mov  	r1,r3
FMTKmsg_135:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_134:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_135
endpublic

public code FMTK_CheckMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_136
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
	      	addu 	r3,r4,#mailbox_
	      	mov  	r12,r3
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_137
	      	lb   	r3,2[r12]
	      	bne  	r3,FMTKmsg_139
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
	      	ldi  	r1,#8
FMTKmsg_141:
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
FMTKmsg_139:
	      	lw   	r3,56[bp]
	      	cmp  	r4,r3,#1
	      	bne  	r4,FMTKmsg_142
	      	push 	r12
	      	bsr  	DequeueMsg_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	bra  	FMTKmsg_143
FMTKmsg_142:
	      	lc   	r3,8[r12]
	      	andi 	r3,r3,#65535
	      	mov  	r11,r3
FMTKmsg_143:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_137:
	      	bne  	r11,FMTKmsg_144
	      	ldi  	r1,#9
	      	bra  	FMTKmsg_141
FMTKmsg_144:
	      	beq  	r15,FMTKmsg_146
	      	lw   	r3,8[r11]
	      	sw   	r3,[r15]
FMTKmsg_146:
	      	beq  	r14,FMTKmsg_148
	      	lw   	r3,16[r11]
	      	sw   	r3,[r14]
FMTKmsg_148:
	      	beq  	r13,FMTKmsg_150
	      	lw   	r3,24[r11]
	      	sw   	r3,[r13]
FMTKmsg_150:
	      	lw   	r3,56[bp]
	      	cmp  	r4,r3,#1
	      	bne  	r4,FMTKmsg_152
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_154
	      	ldi  	r3,#1
	      	sc   	r3,6[r11]
	      	ldi  	r3,#-1
	      	sc   	r3,2[r11]
	      	ldi  	r3,#-1
	      	sc   	r3,4[r11]
	      	lc   	r3,freeMSG_
	      	sc   	r3,[r11]
	      	subu 	r4,r11,#message_
	      	lsri 	r3,r4,#5
	      	sc   	r3,freeMSG_
	      	inc  	nMsgBlk_,#1
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKmsg_154:
FMTKmsg_152:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_141
FMTKmsg_136:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_141
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
