	data
	align	8
	fill.b	24,0x00
	align	8
	fill.b	1984,0x00
	align	8
	code
	align	16
public code chkMBX_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw    r1,24[bp]
        chk   r1,r1,b50
    
FMTKmsg_1:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code chkMSG_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw    r1,24[bp]
        chk   r1,r1,b51
    
FMTKmsg_3:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

QueueMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_5
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lw   	r11,24[bp]
	      	ldi  	r12,#nMsgBlk_
	      	ldi  	r13,#freeMSG_
	      	sw   	r0,-16[bp]
	      	push 	32[bp]
	      	bsr  	chkMSG_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,FMTKmsg_6
	      	ldi  	r1,#0
FMTKmsg_8:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_6:
	      	bsr  	LockSYS_
	      	inc  	56[r11],#1
	      	lcu  	r3,80[r11]
	      	cmp  	r4,r3,#0
	      	beq  	r4,FMTKmsg_10
	      	cmp  	r4,r3,#2
	      	beq  	r4,FMTKmsg_11
	      	cmp  	r4,r3,#1
	      	beq  	r4,FMTKmsg_12
	      	bra  	FMTKmsg_9
FMTKmsg_10:
	      	bra  	FMTKmsg_9
FMTKmsg_11:
FMTKmsg_13:
	      	lw   	r3,56[r11]
	      	lw   	r4,48[r11]
	      	cmpu 	r3,r3,r4
	      	ble  	r3,FMTKmsg_14
	      	lw   	r3,24[r11]
	      	lw   	r4,[r3]
	      	sw   	r4,-8[bp]
	      	lw   	r3,24[r11]
	      	lw   	r4,[r13]
	      	sw   	r4,[r3]
	      	lw   	r3,24[r11]
	      	sw   	r3,[r13]
	      	inc  	[r12],#1
	      	dec  	56[r11],#1
	      	lw   	r3,-8[bp]
	      	sw   	r3,24[r11]
	      	lw   	r3,64[r11]
	      	cmpu 	r3,r3,#-1
	      	bge  	r3,FMTKmsg_15
	      	inc  	64[r11],#1
FMTKmsg_15:
	      	ldi  	r3,#6
	      	sw   	r3,-16[bp]
	      	bra  	FMTKmsg_13
FMTKmsg_14:
	      	bra  	FMTKmsg_9
FMTKmsg_12:
	      	lw   	r3,56[r11]
	      	lw   	r4,48[r11]
	      	cmpu 	r3,r3,r4
	      	ble  	r3,FMTKmsg_17
	      	lw   	r3,32[bp]
	      	lw   	r4,[r13]
	      	sw   	r4,[r3]
	      	lw   	r3,32[bp]
	      	sw   	r3,[r13]
	      	inc  	[r12],#1
	      	lw   	r3,64[r11]
	      	cmpu 	r3,r3,#-1
	      	bge  	r3,FMTKmsg_19
	      	inc  	64[r11],#1
FMTKmsg_19:
	      	ldi  	r3,#6
	      	sw   	r3,-16[bp]
	      	dec  	56[r11],#1
FMTKmsg_17:
FMTKmsg_21:
	      	lw   	r3,56[r11]
	      	lw   	r4,48[r11]
	      	cmpu 	r3,r3,r4
	      	ble  	r3,FMTKmsg_22
	      	lw   	r3,24[r11]
	      	sw   	r3,-8[bp]
FMTKmsg_23:
	      	lw   	r3,-8[bp]
	      	lw   	r4,32[r11]
	      	cmp  	r3,r3,r4
	      	beq  	r3,FMTKmsg_24
	      	lw   	r3,-8[bp]
	      	sw   	r3,32[bp]
	      	lw   	r3,-8[bp]
	      	lw   	r4,[r3]
	      	sw   	r4,-8[bp]
	      	bra  	FMTKmsg_23
FMTKmsg_24:
	      	lw   	r3,32[bp]
	      	sw   	r3,32[r11]
	      	lw   	r3,-8[bp]
	      	lw   	r4,[r13]
	      	sw   	r4,[r3]
	      	lw   	r3,-8[bp]
	      	sw   	r3,[r13]
	      	inc  	[r12],#1
	      	lw   	r3,64[r11]
	      	cmpu 	r3,r3,#-1
	      	bge  	r3,FMTKmsg_25
	      	inc  	64[r11],#1
FMTKmsg_25:
	      	dec  	56[r11],#1
	      	ldi  	r3,#6
	      	sw   	r3,-16[bp]
	      	bra  	FMTKmsg_21
FMTKmsg_22:
	      	lw   	r3,-16[bp]
	      	cmp  	r3,r3,#6
	      	bne  	r3,FMTKmsg_27
	      	bsr  	UnlockSYS_
	      	lw   	r3,-16[bp]
	      	mov  	r1,r3
	      	bra  	FMTKmsg_8
FMTKmsg_27:
	      	bra  	FMTKmsg_9
FMTKmsg_9:
	      	lw   	r3,32[r11]
	      	beq  	r3,FMTKmsg_29
	      	lw   	r3,32[r11]
	      	lw   	r4,32[bp]
	      	sw   	r4,[r3]
	      	bra  	FMTKmsg_30
FMTKmsg_29:
	      	lw   	r3,32[bp]
	      	sw   	r3,24[r11]
FMTKmsg_30:
	      	lw   	r3,32[bp]
	      	sw   	r3,32[r11]
	      	lw   	r3,32[bp]
	      	sw   	r0,[r3]
	      	bsr  	UnlockSYS_
	      	lw   	r3,-16[bp]
	      	mov  	r1,r3
	      	bra  	FMTKmsg_8
FMTKmsg_5:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_8
DequeueMsg_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	lw   	r12,24[bp]
	      	ldi  	r11,#0
	      	lw   	r3,56[r12]
	      	beq  	r3,FMTKmsg_33
	      	dec  	56[r12],#1
	      	lw   	r11,24[r12]
	      	beq  	r11,FMTKmsg_35
	      	lw   	r3,[r11]
	      	sw   	r3,24[r12]
	      	lw   	r3,24[r12]
	      	bne  	r3,FMTKmsg_37
	      	sw   	r0,32[r12]
FMTKmsg_37:
	      	sw   	r11,[r11]
FMTKmsg_35:
FMTKmsg_33:
	      	mov  	r1,r11
FMTKmsg_39:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
public code FMTK_AllocMbx_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_40
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lw   	r12,24[bp]
	      	ldi  	r13,#freeMBX_
	      	bne  	r12,FMTKmsg_41
	      	ldi  	r1,#4
FMTKmsg_43:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_41:
	      	bsr  	LockSYS_
	      	lw   	r3,[r13]
	      	bne  	r3,FMTKmsg_44
	      	bsr  	UnlockSYS_
	      	ldi  	r1,#64
	      	bra  	FMTKmsg_43
FMTKmsg_44:
	      	lw   	r11,[r13]
	      	lw   	r3,[r11]
	      	sw   	r3,[r13]
	      	dec  	nMailbox_,#1
	      	bsr  	UnlockSYS_
	      	ldi  	r3,#mailbox_
	      	asli 	r3,r3,#7
	      	subu 	r11,r11,r3
	      	lsri 	r11,r11,#7
	      	sw   	r11,[r12]
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	sw   	r3,72[r11]
	      	sw   	r0,8[r11]
	      	sw   	r0,16[r11]
	      	sw   	r0,24[r11]
	      	sw   	r0,32[r11]
	      	sw   	r0,40[r11]
	      	sw   	r0,56[r11]
	      	sw   	r0,64[r11]
	      	ldi  	r3,#8
	      	sw   	r3,48[r11]
	      	ldi  	r3,#2
	      	sc   	r3,80[r11]
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_43
FMTKmsg_40:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_43
endpublic

public code FMTK_FreeMbx_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_46
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lea  	r3,-24[bp]
	      	mov  	r12,r3
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#2048
	      	blt  	r3,FMTKmsg_47
	      	ldi  	r1,#5
FMTKmsg_49:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_47:
	      	lw   	r3,24[bp]
	      	asli 	r3,r3,#7
	      	addu 	r3,r3,#mailbox_
	      	mov  	r11,r3
	      	bsr  	LockSYS_
	      	push 	72[r11]
	      	bsr  	GetJCBPtr_
	      	pop  	r3
	      	mov  	r4,r1
	      	cmp  	r3,r3,r4
	      	beq  	r3,FMTKmsg_50
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_50
	      	ldi  	r1,#12
	      	bra  	FMTKmsg_49
FMTKmsg_50:
FMTKmsg_52:
	      	push 	r11
	      	bsr  	DequeueMsg_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	mov  	r13,r3
	      	beq  	r3,FMTKmsg_53
	      	lw   	r3,freeMSG_
	      	sw   	r3,[r13]
	      	sw   	r13,freeMSG_
	      	inc  	nMsgBlk_,#1
	      	bra  	FMTKmsg_52
FMTKmsg_53:
FMTKmsg_54:
	      	push 	r12
	      	push 	r11
	      	bsr  	DequeThreadFromMbx_
	      	addui	sp,sp,#16
	      	lw   	r3,[r12]
	      	bne  	r3,FMTKmsg_56
	      	bra  	FMTKmsg_55
FMTKmsg_56:
	      	lw   	r3,[r12]
	      	sw   	r0,400[r3]
	      	lw   	r3,[r12]
	      	lb   	r3,425[r3]
	      	and  	r3,r3,#1
	      	beq  	r3,FMTKmsg_58
	      	push 	[r12]
	      	bsr  	RemoveFromTimeoutList_
	      	addui	sp,sp,#8
FMTKmsg_58:
	      	push 	[r12]
	      	bsr  	InsertIntoReadyList_
	      	addui	sp,sp,#8
	      	bra  	FMTKmsg_54
FMTKmsg_55:
	      	lw   	r3,freeMBX_
	      	sw   	r3,[r11]
	      	sw   	r11,freeMBX_
	      	inc  	nMailbox_,#1
	      	bsr  	UnlockSYS_
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_49
FMTKmsg_46:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_49
endpublic

public code SetMbxMsgQueStrategy_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_60
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#2048
	      	blt  	r3,FMTKmsg_61
	      	ldi  	r1,#5
FMTKmsg_63:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_61:
	      	lw   	r3,32[bp]
	      	cmp  	r3,r3,#2
	      	ble  	r3,FMTKmsg_64
	      	ldi  	r1,#4
	      	bra  	FMTKmsg_63
FMTKmsg_64:
	      	lw   	r3,24[bp]
	      	asli 	r3,r3,#7
	      	addu 	r3,r3,#mailbox_
	      	mov  	r11,r3
	      	bsr  	LockSYS_
	      	push 	72[r11]
	      	bsr  	GetJCBPtr_
	      	pop  	r3
	      	mov  	r4,r1
	      	cmp  	r3,r3,r4
	      	beq  	r3,FMTKmsg_66
	      	bsr  	GetJCBPtr_
	      	mov  	r3,r1
	      	beq  	r3,FMTKmsg_66
	      	ldi  	r1,#12
	      	bra  	FMTKmsg_63
FMTKmsg_66:
	      	lw   	r3,32[bp]
	      	sc   	r3,80[r11]
	      	lw   	r3,40[bp]
	      	sw   	r3,48[r11]
	      	bsr  	UnlockSYS_
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_63
FMTKmsg_60:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_63
endpublic

public code FMTK_SendMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_68
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	lea  	r3,-24[bp]
	      	mov  	r12,r3
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#2048
	      	blt  	r3,FMTKmsg_69
	      	ldi  	r1,#5
FMTKmsg_71:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_69:
	      	lw   	r3,24[bp]
	      	asli 	r3,r3,#7
	      	addu 	r3,r3,#mailbox_
	      	sw   	r3,-8[bp]
	      	bsr  	LockSYS_
	      	lw   	r3,-8[bp]
	      	lw   	r3,72[r3]
	      	bne  	r3,FMTKmsg_72
	      	bsr  	UnlockSYS_
	      	ldi  	r1,#8
	      	bra  	FMTKmsg_71
FMTKmsg_72:
	      	lw   	r11,freeMSG_
	      	bne  	r11,FMTKmsg_74
	      	bsr  	UnlockSYS_
	      	ldi  	r1,#65
	      	bra  	FMTKmsg_71
FMTKmsg_74:
	      	lw   	r3,[r11]
	      	sw   	r3,freeMSG_
	      	dec  	nMsgBlk_,#1
	      	sw   	r0,24[r11]
	      	lw   	r3,32[bp]
	      	sw   	r3,8[r11]
	      	lw   	r3,40[bp]
	      	sw   	r3,16[r11]
	      	push 	r12
	      	push 	-8[bp]
	      	bsr  	DequeThreadFromMbx_
	      	addui	sp,sp,#16
	      	bsr  	UnlockSYS_
	      	lw   	r3,[r12]
	      	bne  	r3,FMTKmsg_76
	      	push 	r11
	      	push 	-8[bp]
	      	bsr  	QueueMsg_
	      	addui	sp,sp,#16
	      	mov  	r3,r1
	      	mov  	r1,r3
	      	bra  	FMTKmsg_71
FMTKmsg_76:
	      	bsr  	LockSYS_
	      	lw   	r3,[r12]
	      	sw   	r11,400[r3]
	      	lw   	r3,[r12]
	      	lb   	r3,425[r3]
	      	and  	r3,r3,#1
	      	beq  	r3,FMTKmsg_78
	      	push 	[r12]
	      	bsr  	RemoveFromTimeoutList_
	      	addui	sp,sp,#8
FMTKmsg_78:
	      	push 	[r12]
	      	bsr  	InsertIntoReadyList_
	      	addui	sp,sp,#8
	      	bsr  	UnlockSYS_
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_71
FMTKmsg_68:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_71
endpublic

public code FMTK_PostMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_80
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	push 	r12
	      	lea  	r3,-24[bp]
	      	mov  	r12,r3
	      	lw   	r3,24[bp]
	      	cmp  	r3,r3,#2048
	      	blt  	r3,FMTKmsg_81
	      	ldi  	r1,#5
FMTKmsg_83:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_81:
	      	lw   	r3,24[bp]
	      	asli 	r3,r3,#7
	      	addu 	r3,r3,#mailbox_
	      	sw   	r3,-8[bp]
	      	bsr  	LockSYS_
	      	lw   	r3,-8[bp]
	      	lw   	r3,72[r3]
	      	bne  	r3,FMTKmsg_84
	      	bsr  	UnlockSYS_
	      	ldi  	r1,#8
	      	bra  	FMTKmsg_83
FMTKmsg_84:
	      	lw   	r11,freeMSG_
	      	bne  	r11,FMTKmsg_86
	      	bsr  	UnlockSYS_
	      	ldi  	r1,#65
	      	bra  	FMTKmsg_83
FMTKmsg_86:
	      	lw   	r3,[r11]
	      	sw   	r3,freeMSG_
	      	dec  	nMsgBlk_,#1
	      	sw   	r0,24[r11]
	      	lw   	r3,32[bp]
	      	sw   	r3,8[r11]
	      	lw   	r3,40[bp]
	      	sw   	r3,16[r11]
	      	push 	r12
	      	push 	-8[bp]
	      	bsr  	DequeueThreadFromMbx_
	      	addui	sp,sp,#16
	      	bsr  	UnlockSYS_
	      	lw   	r3,[r12]
	      	bne  	r3,FMTKmsg_88
	      	push 	r11
	      	push 	-8[bp]
	      	bsr  	QueueMsg_
	      	addui	sp,sp,#16
	      	mov  	r3,r1
	      	sw   	r3,-32[bp]
	      	lw   	r3,-32[bp]
	      	mov  	r1,r3
	      	bra  	FMTKmsg_83
FMTKmsg_88:
	      	bsr  	LockSYS_
	      	lw   	r3,[r12]
	      	sw   	r11,400[r3]
	      	lw   	r3,[r12]
	      	lb   	r3,425[r3]
	      	and  	r3,r3,#1
	      	beq  	r3,FMTKmsg_90
	      	push 	[r12]
	      	bsr  	RemoveFromTimeoutList_
	      	addui	sp,sp,#8
FMTKmsg_90:
	      	push 	[r12]
	      	bsr  	AddToReadyList_
	      	addui	sp,sp,#8
	      	bsr  	UnlockSYS_
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_83
FMTKmsg_80:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_83
endpublic

public code FMTK_WaitMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_92
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	push 	r15
	      	lw   	r13,40[bp]
	      	lw   	r14,32[bp]
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#2048
	      	blt  	r3,FMTKmsg_93
	      	ldi  	r1,#5
FMTKmsg_95:
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
FMTKmsg_93:
	      	lw   	r3,24[bp]
	      	asli 	r3,r3,#7
	      	addu 	r3,r3,#mailbox_
	      	mov  	r12,r3
	      	bsr  	LockSYS_
	      	lw   	r3,72[r12]
	      	bne  	r3,FMTKmsg_96
	      	bsr  	UnlockSYS_
	      	ldi  	r1,#8
	      	bra  	FMTKmsg_95
FMTKmsg_96:
	      	push 	r12
	      	bsr  	DequeueMsg_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	mov  	r15,r3
	      	bsr  	UnlockSYS_
	      	bne  	r15,FMTKmsg_98
	      	bsr  	LockSYS_
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	push 	r11
	      	bsr  	RemoveFromReadyList_
	      	addui	sp,sp,#8
	      	bsr  	UnlockSYS_
	      	lb   	r3,425[r11]
	      	ori  	r3,r3,#2
	      	sb   	r3,425[r11]
	      	lw   	r3,24[bp]
	      	sw   	r3,408[r11]
	      	sw   	r0,328[r11]
	      	bsr  	LockSYS_
	      	lw   	r3,8[r12]
	      	bne  	r3,FMTKmsg_100
	      	sw   	r0,336[r11]
	      	sw   	r11,8[r12]
	      	sw   	r11,16[r12]
	      	ldi  	r3,#1
	      	sw   	r3,40[r12]
	      	bra  	FMTKmsg_101
FMTKmsg_100:
	      	lw   	r3,16[r12]
	      	sw   	r3,336[r11]
	      	lw   	r3,16[r12]
	      	sw   	r11,328[r3]
	      	sw   	r11,16[r12]
	      	inc  	40[r12],#1
FMTKmsg_101:
	      	bsr  	UnlockSYS_
	      	lw   	r3,48[bp]
	      	beq  	r3,FMTKmsg_102
	      	bsr  	LockSYS_
	      	push 	48[bp]
	      	push 	r11
	      	bsr  	AddToTimeoutList_
	      	addui	sp,sp,#16
	      	bsr  	UnlockSYS_
FMTKmsg_102:
	      	     	int #2 
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	lw   	r15,400[r3]
	      	bne  	r15,FMTKmsg_104
	      	ldi  	r1,#9
	      	bra  	FMTKmsg_95
FMTKmsg_104:
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	sw   	r0,400[r3]
FMTKmsg_98:
	      	beq  	r14,FMTKmsg_106
	      	lw   	r3,8[r15]
	      	sw   	r3,[r14]
FMTKmsg_106:
	      	beq  	r13,FMTKmsg_108
	      	lw   	r3,16[r15]
	      	sw   	r3,[r13]
FMTKmsg_108:
	      	bsr  	LockSYS_
	      	lw   	r3,freeMSG_
	      	sw   	r3,[r15]
	      	sw   	r15,freeMSG_
	      	inc  	nMsgBlk_,#1
	      	bsr  	UnlockSYS_
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_95
FMTKmsg_92:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_95
endpublic

public code FMTK_PeekMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_110
	      	mov  	bp,sp
	      	push 	#0
	      	push 	40[bp]
	      	push 	32[bp]
	      	push 	24[bp]
	      	bsr  	CheckMsg_
	      	addui	sp,sp,#32
	      	mov  	r3,r1
	      	mov  	r1,r3
FMTKmsg_111:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_110:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_111
endpublic

public code FMTK_CheckMsg_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKmsg_112
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	lw   	r13,40[bp]
	      	lw   	r14,32[bp]
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#2048
	      	blt  	r3,FMTKmsg_113
	      	ldi  	r1,#5
FMTKmsg_115:
	      	pop  	r14
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKmsg_113:
	      	lw   	r3,24[bp]
	      	asli 	r3,r3,#7
	      	addu 	r3,r3,#mailbox_
	      	mov  	r12,r3
	      	bsr  	LockSYS_
	      	lw   	r3,72[r12]
	      	bne  	r3,FMTKmsg_116
	      	bsr  	UnlockSYS_
	      	ldi  	r1,#8
	      	bra  	FMTKmsg_115
FMTKmsg_116:
	      	lw   	r3,48[bp]
	      	cmp  	r3,r3,#1
	      	bne  	r3,FMTKmsg_118
	      	push 	r12
	      	bsr  	DequeueMsg_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	bra  	FMTKmsg_119
FMTKmsg_118:
	      	lw   	r11,24[r12]
FMTKmsg_119:
	      	bsr  	UnlockSYS_
	      	bne  	r11,FMTKmsg_120
	      	ldi  	r1,#9
	      	bra  	FMTKmsg_115
FMTKmsg_120:
	      	beq  	r14,FMTKmsg_122
	      	lw   	r3,8[r11]
	      	sw   	r3,[r14]
FMTKmsg_122:
	      	beq  	r13,FMTKmsg_124
	      	lw   	r3,16[r11]
	      	sw   	r3,[r13]
FMTKmsg_124:
	      	lw   	r3,48[bp]
	      	cmp  	r3,r3,#1
	      	bne  	r3,FMTKmsg_126
	      	bsr  	LockSYS_
	      	lw   	r3,freeMSG_
	      	sw   	r3,[r11]
	      	sw   	r11,freeMSG_
	      	inc  	nMsgBlk_,#1
	      	bsr  	UnlockSYS_
FMTKmsg_126:
	      	ldi  	r1,#0
	      	bra  	FMTKmsg_115
FMTKmsg_112:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKmsg_115
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
;	global	outw_
	extern	fmtk_irq_stack_
	extern	GetRunningTCB_
	extern	runningTCB_
	extern	DequeueThreadFromMbx_
	extern	fmtk_sys_stack_
	extern	message_
	extern	mailbox_
	extern	FMTK_Inited_
;	global	SetMbxMsgQueStrategy_
	extern	missed_ticks_
	extern	CheckMsg_
	extern	DequeThreadFromMbx_
;	global	chkMBX_
;	global	chkMSG_
	extern	GetJCBPtr_
	extern	video_bufs_
	extern	getCPU_
	extern	hasUltraHighPriorityTasks_
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
	extern	AddToTimeoutList_
	extern	AddToReadyList_
;	global	FMTK_PostMsg_
	extern	BIOS1_sema_
	extern	sys_sema_
	extern	readyQ_
	extern	UnlockSYS_
	extern	sysstack_
	extern	freeTCB_
	extern	TimeoutList_
	extern	RemoveFromTimeoutList_
	extern	LockSYS_
	extern	stacks_
	extern	freeMSG_
	extern	freeMBX_
	extern	RemoveFromReadyList_
	extern	bios_stacks_
;	global	FMTK_CheckMsg_
	extern	InsertIntoReadyList_
